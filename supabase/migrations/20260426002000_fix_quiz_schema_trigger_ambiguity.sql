create or replace function public.enforce_supported_quiz_schema()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  question_row jsonb;
  raw_type text;
  total_marks numeric;
begin
  for question_row in
    select value from jsonb_array_elements(coalesce(new.question_schema, '[]'::jsonb))
  loop
    raw_type := lower(coalesce(question_row ->> 'type', ''));
    if raw_type not in (
      'mcq',
      'true / false',
      'true/false',
      'short answer',
      'essay',
      'matching',
      'drag and drop',
      'classification'
    ) then
      raise exception 'Unsupported quiz question type: %.', coalesce(question_row ->> 'type', '')
        using errcode = '22023';
    end if;
  end loop;

  new.question_schema := public.sanitize_quiz_question_schema(new.question_schema);

  select coalesce(sum(greatest(coalesce((schema_question ->> 'marks')::numeric, 0), 0)), 0)
  into total_marks
  from jsonb_array_elements(coalesce(new.question_schema, '[]'::jsonb)) as questions(schema_question);

  new.max_points := greatest(ceil(total_marks)::integer, 1);
  return new;
end;
$$;
