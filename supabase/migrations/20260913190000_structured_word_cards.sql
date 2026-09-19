alter table public.cards
  add column word_data jsonb
    check (word_data is null or jsonb_typeof(word_data) = 'object');

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
       or (card ? 'word_data' and jsonb_typeof(card -> 'word_data') <> 'object')
       or jsonb_typeof(card -> 'sections') <> 'array'
       or jsonb_array_length(card -> 'sections') not between 1 and 4 then
      raise exception 'Invalid word card' using errcode = '22023';
    end if;
    insert into public.cards (
      user_id, deck_id, prompt, hint, word_data, position, source_type,
      source_excerpt
    ) values (
      current_user_id, new_deck_id, trim(card ->> 'prompt'),
      trim(coalesce(card ->> 'hint', '')), card -> 'word_data', card_position,
      'capture', input_source_excerpt
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
       or (card ? 'word_data' and jsonb_typeof(card -> 'word_data') <> 'object')
       or jsonb_typeof(card -> 'sections') <> 'array'
       or jsonb_array_length(card -> 'sections') not between 1 and 4
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
      user_id, deck_id, prompt, hint, word_data, position, source_type,
      source_excerpt
    ) values (
      current_user_id, input_deck_id, trim(card ->> 'prompt'),
      trim(coalesce(card ->> 'hint', '')), card -> 'word_data', next_position,
      'ai_extension', trim(card ->> 'reason')
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

revoke all on function public.create_captured_word_deck(text, text, jsonb),
  public.append_generated_cards(uuid, jsonb)
from public, anon;
grant execute on function public.create_captured_word_deck(text, text, jsonb),
  public.append_generated_cards(uuid, jsonb)
to authenticated;
