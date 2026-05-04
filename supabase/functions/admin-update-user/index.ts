import { createClient } from "https://esm.sh/@supabase/supabase-js@2.48.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const allowedRoles = new Set(["student", "instructor", "admin"]);
const allowedStatuses = new Set(["active", "inactive", "suspended"]);

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ error: "Method not allowed." }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");

  if (!supabaseUrl || !serviceRoleKey || !anonKey) {
    return json({ error: "User editing is not configured on the server." }, 500);
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.toLowerCase().startsWith("bearer ")) {
    return json({ error: "Admin sign-in required." }, 401);
  }

  const service = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const userClient = createClient(supabaseUrl, anonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { Authorization: authHeader } },
  });

  const {
    data: { user: caller },
    error: callerError,
  } = await userClient.auth.getUser();
  if (callerError || !caller) {
    return json({ error: "Admin sign-in required." }, 401);
  }

  const { data: adminProfile, error: profileError } = await service
    .from("profiles")
    .select("id, role, account_status, deleted_at")
    .eq("id", caller.id)
    .maybeSingle();

  if (
    profileError ||
    !adminProfile ||
    adminProfile.role !== "admin" ||
    adminProfile.account_status !== "active" ||
    adminProfile.deleted_at !== null
  ) {
    return json({ error: "Admin access required." }, 403);
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch (_) {
    return json({ error: "Invalid request body." }, 400);
  }

  const userId = stringValue(body.user_id);
  if (!isUuid(userId)) {
    return json({ error: "User not found." }, 404);
  }

  const { data: current, error: currentError } = await service
    .from("profiles")
    .select("id, email, full_name, role, account_status, phone, deleted_at")
    .eq("id", userId)
    .maybeSingle();

  if (currentError || !current || current.deleted_at !== null) {
    return json({ error: "User not found." }, 404);
  }

  const fullName = stringValue(body.full_name || current.full_name);
  const email = stringValue(body.email || current.email).toLowerCase();
  const role = stringValue(body.role || current.role).toLowerCase();
  const status = stringValue(body.account_status || current.account_status)
    .toLowerCase();
  const phone = body.phone === undefined ? current.phone ?? "" : stringValue(body.phone);

  const validationError = validate({ fullName, email, role, status });
  if (validationError) {
    return json({ error: validationError }, 400);
  }

  if (caller.id === userId && role !== "admin") {
    return json({ error: "You cannot remove your own admin role." }, 403);
  }
  if (caller.id === userId && status !== "active") {
    return json({ error: "You cannot disable your own admin account." }, 403);
  }

  const { data: duplicateProfile } = await service
    .from("profiles")
    .select("id")
    .ilike("email", email)
    .neq("id", userId)
    .is("deleted_at", null)
    .maybeSingle();

  if (duplicateProfile) {
    return json({ error: "A user with this email already exists." }, 409);
  }

  if (email !== String(current.email).toLowerCase()) {
    const existingAuthUser = await findAuthUserByEmail(service, email);
    if (existingAuthUser && existingAuthUser.id !== userId) {
      return json({ error: "A user with this email already exists." }, 409);
    }
  }

  const { error: authUpdateError } = await service.auth.admin.updateUserById(
    userId,
    {
      email,
      email_confirm: true,
      user_metadata: { full_name: fullName, role },
      app_metadata: { role },
    },
  );

  if (authUpdateError) {
    return json({ error: friendlyAuthError(authUpdateError.message) }, 400);
  }

  const { error: profileUpdateError } = await service
    .from("profiles")
    .update({
      email,
      full_name: fullName,
      role,
      account_status: status,
      phone,
      updated_at: new Date().toISOString(),
    })
    .eq("id", userId);

  if (profileUpdateError) {
    return json({ error: "User profile could not be updated." }, 500);
  }

  await service.from("admin_activity_logs").insert({
    actor_id: caller.id,
    target_user_id: userId,
    action: "user_profile_updated",
    summary: `Updated profile for ${fullName}`,
    metadata: {
      old_email: current.email,
      new_email: email,
      old_role: current.role,
      new_role: role,
      old_status: current.account_status,
      new_status: status,
    },
  });

  return json({ ok: true });
});

function stringValue(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function validate(input: {
  fullName: string;
  email: string;
  role: string;
  status: string;
}): string | null {
  if (!input.fullName) return "Full name is required.";
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(input.email)) {
    return "Enter a valid email address.";
  }
  if (!allowedRoles.has(input.role)) return "Select a valid role.";
  if (!allowedStatuses.has(input.status)) return "Select a valid status.";
  return null;
}

function friendlyAuthError(message = ""): string {
  const lower = message.toLowerCase();
  if (lower.includes("already") || lower.includes("registered")) {
    return "A user with this email already exists.";
  }
  if (lower.includes("email")) {
    return "Enter a valid email address.";
  }
  return "User profile could not be updated.";
}

async function findAuthUserByEmail(
  service: ReturnType<typeof createClient>,
  email: string,
) {
  let page = 1;
  const perPage = 1000;

  while (page < 20) {
    const { data, error } = await service.auth.admin.listUsers({
      page,
      perPage,
    });
    if (error || !data?.users?.length) return null;

    const found = data.users.find(
      (user) => user.email?.toLowerCase() === email,
    );
    if (found) return found;
    if (data.users.length < perPage) return null;
    page += 1;
  }

  return null;
}

function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
    .test(value);
}

function json(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
