alter table public.cards
  add column hint text not null default ''
    check (char_length(hint) <= 160);

alter table public.practice_attempts
  add column assistance_used boolean not null default false;

create or replace function public.record_practice_attempts(
  input_deck_id uuid,
  input_attempts jsonb
) returns table (
  card_id uuid,
  due_at timestamptz,
  interval_days integer
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  attempt jsonb;
  attempt_card_id uuid;
  attempt_familiarity text;
  attempt_assistance_used boolean;
  previous_interval integer;
  next_interval integer;
  next_due_at timestamptz;
begin
  if current_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if input_deck_id is null
     or jsonb_typeof(input_attempts) <> 'array'
     or jsonb_array_length(input_attempts) not between 1 and 500 then
    raise exception 'Invalid practice batch' using errcode = '22023';
  end if;
  if not exists (
    select 1 from public.decks d
    where d.id = input_deck_id
      and (
        d.user_id = current_user_id
        or exists (
          select 1 from public.deck_library dl
          where dl.user_id = current_user_id and dl.deck_id = d.id
        )
      )
  ) then
    raise exception 'Deck not found' using errcode = 'P0002';
  end if;

  for attempt in select value from jsonb_array_elements(input_attempts) loop
    begin
      attempt_card_id := (attempt ->> 'card_id')::uuid;
    exception when invalid_text_representation then
      raise exception 'Invalid card id' using errcode = '22023';
    end;
    attempt_familiarity := attempt ->> 'familiarity';
    attempt_assistance_used := case
      when jsonb_typeof(attempt -> 'assistance_used') = 'boolean'
        then (attempt ->> 'assistance_used')::boolean
      else false
    end;
    if attempt_familiarity not in ('mastered', 'fuzzy', 'forgotten')
       or (attempt_familiarity = 'mastered' and attempt_assistance_used)
       or not exists (
         select 1 from public.cards c
         where c.id = attempt_card_id and c.deck_id = input_deck_id
       ) then
      raise exception 'Invalid practice attempt' using errcode = '22023';
    end if;

    select cms.interval_days into previous_interval
    from public.card_memory_states cms
    where cms.user_id = current_user_id and cms.card_id = attempt_card_id;

    if attempt_familiarity = 'mastered' then
      next_interval := case
        when coalesce(previous_interval, 0) <= 0 then 3
        else least(90, greatest(3, previous_interval * 2))
      end;
      next_due_at := now() + make_interval(days => next_interval);
    elsif attempt_familiarity = 'fuzzy' then
      next_interval := case
        when coalesce(previous_interval, 0) <= 0 then 1
        else least(30, greatest(1, ceil(previous_interval * 1.25)::integer))
      end;
      next_due_at := now() + make_interval(days => next_interval);
    else
      next_interval := 0;
      next_due_at := now() + interval '10 minutes';
    end if;

    insert into public.practice_attempts (
      user_id, deck_id, card_id, familiarity, assistance_used
    ) values (
      current_user_id, input_deck_id, attempt_card_id, attempt_familiarity,
      attempt_assistance_used
    );

    insert into public.card_memory_states (
      user_id, deck_id, card_id, due_at, interval_days, review_count,
      lapse_count, mastery_streak, last_familiarity, last_reviewed_at
    ) values (
      current_user_id, input_deck_id, attempt_card_id, next_due_at,
      next_interval, 1,
      case when attempt_familiarity = 'forgotten' then 1 else 0 end,
      case when attempt_familiarity = 'mastered' then 1 else 0 end,
      attempt_familiarity, now()
    )
    on conflict on constraint card_memory_states_pkey do update set
      deck_id = excluded.deck_id,
      due_at = excluded.due_at,
      interval_days = excluded.interval_days,
      review_count = public.card_memory_states.review_count + 1,
      lapse_count = public.card_memory_states.lapse_count
        + case when excluded.last_familiarity = 'forgotten' then 1 else 0 end,
      mastery_streak = case
        when excluded.last_familiarity = 'mastered'
          then public.card_memory_states.mastery_streak + 1
        else 0
      end,
      last_familiarity = excluded.last_familiarity,
      last_reviewed_at = excluded.last_reviewed_at;

    card_id := attempt_card_id;
    due_at := next_due_at;
    interval_days := next_interval;
    return next;
  end loop;
end;
$$;

create or replace function public.create_captured_word_deck(
  input_title text,
  input_source_excerpt text,
  input_cards jsonb
) returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  new_deck_id uuid;
  new_card_id uuid;
  card jsonb;
  section jsonb;
  card_position integer := 0;
  section_position integer;
begin
  if current_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  input_title := trim(coalesce(input_title, ''));
  input_source_excerpt := trim(coalesce(input_source_excerpt, ''));
  if char_length(input_title) not between 1 and 120
     or char_length(input_source_excerpt) > 4000
     or jsonb_typeof(input_cards) <> 'array'
     or jsonb_array_length(input_cards) not between 1 and 30 then
    raise exception 'Invalid captured deck' using errcode = '22023';
  end if;

  insert into public.decks (user_id, title, subtitle, kind)
  values (
    current_user_id,
    input_title,
    jsonb_array_length(input_cards)::text || ' AI-reviewed cards',
    'word'
  ) returning id into new_deck_id;

  for card in select value from jsonb_array_elements(input_cards) loop
    if char_length(trim(coalesce(card ->> 'prompt', ''))) not between 1 and 100
       or char_length(trim(coalesce(card ->> 'hint', ''))) > 160
       or jsonb_typeof(card -> 'sections') <> 'array'
       or jsonb_array_length(card -> 'sections') not between 1 and 3 then
      raise exception 'Invalid word card' using errcode = '22023';
    end if;
    insert into public.cards (
      user_id, deck_id, prompt, hint, position, source_type, source_excerpt
    ) values (
      current_user_id, new_deck_id, trim(card ->> 'prompt'),
      trim(coalesce(card ->> 'hint', '')), card_position, 'capture',
      input_source_excerpt
    ) returning id into new_card_id;

    section_position := 0;
    for section in select value from jsonb_array_elements(card -> 'sections') loop
      if char_length(trim(coalesce(section ->> 'title', ''))) not between 1 and 80
         or char_length(coalesce(section ->> 'heading', '')) > 1000
         or char_length(coalesce(section ->> 'body', '')) > 10000 then
        raise exception 'Invalid word card section' using errcode = '22023';
      end if;
      insert into public.card_sections (
        user_id, card_id, title, heading, body, position
      ) values (
        current_user_id, new_card_id, trim(section ->> 'title'),
        trim(coalesce(section ->> 'heading', '')),
        trim(coalesce(section ->> 'body', '')), section_position
      );
      section_position := section_position + 1;
    end loop;
    card_position := card_position + 1;
  end loop;
  return new_deck_id;
end;
$$;

create or replace function public.append_generated_cards(
  input_deck_id uuid,
  input_cards jsonb
) returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  next_position integer;
  new_card_id uuid;
  parent_id uuid;
  card jsonb;
  section jsonb;
  section_position integer;
  inserted_count integer := 0;
begin
  if current_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if input_deck_id is null
     or jsonb_typeof(input_cards) <> 'array'
     or jsonb_array_length(input_cards) not between 1 and 3 then
    raise exception 'Invalid extension batch' using errcode = '22023';
  end if;

  perform 1 from public.decks
  where id = input_deck_id and user_id = current_user_id
  for update;
  if not found then
    raise exception 'Owned deck not found' using errcode = 'P0002';
  end if;
  select coalesce(max(position), -1) + 1 into next_position
  from public.cards where deck_id = input_deck_id;

  for card in select value from jsonb_array_elements(input_cards) loop
    begin
      parent_id := (card ->> 'parent_card_id')::uuid;
    exception when invalid_text_representation then
      raise exception 'Invalid parent card id' using errcode = '22023';
    end;
    if char_length(trim(coalesce(card ->> 'prompt', ''))) not between 1 and 100
       or char_length(trim(coalesce(card ->> 'hint', ''))) > 160
       or coalesce(card ->> 'relation_type', '') not in (
         'prerequisite', 'contrast', 'application', 'collocation', 'synonym'
       )
       or char_length(trim(coalesce(card ->> 'reason', ''))) not between 1 and 240
       or jsonb_typeof(card -> 'sections') <> 'array'
       or jsonb_array_length(card -> 'sections') not between 1 and 3
       or exists (
         select 1 from public.cards c
         where c.deck_id = input_deck_id
           and lower(c.prompt) = lower(trim(card ->> 'prompt'))
       )
       or not exists (
         select 1 from public.cards c
         where c.id = parent_id and c.deck_id = input_deck_id
       ) then
      raise exception 'Invalid generated card' using errcode = '22023';
    end if;

    insert into public.cards (
      user_id, deck_id, prompt, hint, position, source_type, source_excerpt
    ) values (
      current_user_id, input_deck_id, trim(card ->> 'prompt'),
      trim(coalesce(card ->> 'hint', '')), next_position, 'ai_extension',
      trim(card ->> 'reason')
    ) returning id into new_card_id;

    section_position := 0;
    for section in select value from jsonb_array_elements(card -> 'sections') loop
      if char_length(trim(coalesce(section ->> 'title', ''))) not between 1 and 80
         or char_length(coalesce(section ->> 'heading', '')) > 1000
         or char_length(coalesce(section ->> 'body', '')) > 10000 then
        raise exception 'Invalid generated section' using errcode = '22023';
      end if;
      insert into public.card_sections (
        user_id, card_id, title, heading, body, position
      ) values (
        current_user_id, new_card_id, trim(section ->> 'title'),
        trim(coalesce(section ->> 'heading', '')),
        trim(coalesce(section ->> 'body', '')), section_position
      );
      section_position := section_position + 1;
    end loop;

    insert into public.card_relations (
      user_id, deck_id, source_card_id, related_card_id, relation_type, reason
    ) values (
      current_user_id, input_deck_id, parent_id, new_card_id,
      card ->> 'relation_type', trim(card ->> 'reason')
    );
    next_position := next_position + 1;
    inserted_count := inserted_count + 1;
  end loop;
  return inserted_count;
end;
$$;

revoke all on function public.record_practice_attempts(uuid, jsonb),
  public.create_captured_word_deck(text, text, jsonb),
  public.append_generated_cards(uuid, jsonb)
from public, anon;
grant execute on function public.record_practice_attempts(uuid, jsonb),
  public.create_captured_word_deck(text, text, jsonb),
  public.append_generated_cards(uuid, jsonb)
to authenticated;
