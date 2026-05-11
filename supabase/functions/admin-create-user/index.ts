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
    return json({ error: "User creation is not configured on the server." }, 500);
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

  const fullName = stringValue(body.full_name);
  const email = stringValue(body.email).toLowerCase();
  const password = stringValue(body.password);
  const role = stringValue(body.role).toLowerCase();
  const status = stringValue(body.account_status || "active").toLowerCase();
  const phone = stringValue(body.phone);
  const department = stringValue(body.department);

  const validationError = validate({
    fullName,
    email,
    password,
    role,
    status,
  });
  if (validationError) {
    return json({ error: validationError }, 400);
  }

  const { error: platformError } = await userClient.rpc(
    "ensure_admin_user_creation_allowed",
    { p_password: password },
  );
  if (platformError) {
    return json({ error: friendlyPlatformError(platformError.message) }, 403);
  }

  let { data: existingProfile } = await service
    .from("profiles")
    .select("id, deleted_at")
    .ilike("email", email)
    .maybeSingle();
  if (existingProfile && existingProfile.deleted_at === null) {
    return json({ error: "A user with this email already exists." }, 409);
  }

  const existingAuthUser = await findAuthUserByEmail(service, email);
  if (existingProfile && !existingAuthUser) {
    await service
      .from("profiles")
      .update({
        email: `removed-${existingProfile.id}-${email}`,
        updated_at: new Date().toISOString(),
      })
      .eq("id", existingProfile.id);
    existingProfile = null;
  }

  let savedUser: {
    id: string;
    created_at?: string;
    updated_at?: string;
  } | null = null;

  if (existingAuthUser) {
    const { data: updated, error: updateError } =
      await service.auth.admin.updateUserById(existingAuthUser.id, {
        email,
        password,
        email_confirm: true,
        user_metadata: {
          full_name: fullName,
          role,
        },
        app_metadata: {
          role,
        },
      });

    if (updateError || !updated.user) {
      return json({ error: friendlyAuthError(updateError?.message) }, 400);
    }
    savedUser = updated.user;
  } else {
    const { data: created, error: createError } =
      await service.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: {
          full_name: fullName,
          role,
        },
        app_metadata: {
          role,
        },
      });

    if (createError || !created.user) {
      return json({ error: friendlyAuthError(createError?.message) }, 400);
    }
    savedUser = created.user;
  }

  const { error: profileUpsertError } = await service.from("profiles").upsert({
    id: savedUser.id,
    email,
    full_name: fullName,
    role,
    account_status: status,
    phone,
    department,
    deleted_at: null,
    updated_at: new Date().toISOString(),
  });

  if (profileUpsertError) {
    if (!existingAuthUser) {
      await service.auth.admin.deleteUser(savedUser.id);
    }
    return json(
      { error: "User profile could not be created. No account was saved." },
      500,
    );
  }

  await service.from("admin_activity_logs").insert({
    actor_id: caller.id,
    target_user_id: savedUser.id,
    action: existingAuthUser ? "user_restored" : "user_created",
    summary: `${existingAuthUser ? "Restored" : "Created"} ${role} account: ${fullName}`,
    metadata: { role, email },
  });

  return json({
    user: {
      id: savedUser.id,
      name: fullName,
      email,
      role,
      status,
      phone,
      department,
      created_at: savedUser.created_at,
      updated_at: savedUser.updated_at,
    },
  });
});

function stringValue(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function validate(input: {
  fullName: string;
  email: string;
  password: string;
  role: string;
  status: string;
}): string | null {
  if (!input.fullName) return "Full name is required.";
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(input.email)) {
    return "Enter a valid email address.";
  }
  if (input.password.length < 8) {
    return "Temporary password must be at least 8 characters.";
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
  if (lower.includes("password")) {
    return "Temporary password does not meet the required rules.";
  }
  if (lower.includes("email")) {
    return "Enter a valid email address.";
  }
  return "User account could not be created.";
}

function friendlyPlatformError(message = ""): string {
  const lower = message.toLowerCase();
  if (lower.includes("admin user creation")) {
    return "Admin user creation is currently disabled.";
  }
  if (lower.includes("password")) {
    return message;
  }
  if (lower.includes("admin")) {
    return "Admin access required.";
  }
  return "User account could not be created.";
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

function json(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
