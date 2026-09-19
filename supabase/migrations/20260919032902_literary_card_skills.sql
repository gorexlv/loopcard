-- Extend Skill/preset validation while preserving atomic and idempotent saves.
create or replace function public.create_agent_deck(
  input_session_id uuid, input_title text, input_source_excerpt text, input_cards jsonb
) returns uuid language plpgsql security invoker set search_path = '' as $$
declare
  owner_id uuid := auth.uid();
  saved_deck_id uuid;
  item jsonb;
  config jsonb;
  skill text;
  card_position integer := 0;
begin
  if owner_id is null then raise exception 'Authentication required' using errcode = '42501'; end if;
  if input_session_id is null or input_cards is null or jsonb_typeof(input_cards) <> 'array' then
    raise exception 'Invalid generation session' using errcode = '22023';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(owner_id::text || input_session_id::text, 0));
  select id into saved_deck_id from public.decks
    where user_id = owner_id and generation_session_id = input_session_id;
  if found then return saved_deck_id; end if;
  if jsonb_array_length(input_cards) not between 1 and 30 then
    raise exception 'Invalid cards' using errcode = '22023';
  end if;
  for item in select value from jsonb_array_elements(input_cards) loop
    config := item -> 'presentation';
    if config is null or jsonb_typeof(config) <> 'object'
       or coalesce(config ->> 'skill', '') not in ('word', 'knowledge', 'poetry', 'classical')
       or coalesce(config ->> 'layout', '') not in ('centered', 'stacked')
       or coalesce(config ->> 'session_id', '') <> input_session_id::text
       or char_length(coalesce(config ->> 'front', '')) not between 1 and 800
       or char_length(coalesce(config ->> 'back', '')) not between 1 and 800
       or coalesce(config ->> 'skill_version', '') <> '1'
       or not (
         (config ->> 'skill' = 'word' and coalesce(config ->> 'preset', '') in ('word-simple', 'word-detail'))
         or (config ->> 'skill' = 'knowledge' and coalesce(config ->> 'preset', '') = 'knowledge-qa')
         or (config ->> 'skill' = 'poetry' and coalesce(config ->> 'preset', '') in ('poetry-overview', 'poetry-recall'))
         or (config ->> 'skill' = 'classical' and coalesce(config ->> 'preset', '') in ('classical-translation', 'classical-words'))
       )
       or (skill is not null and skill <> config ->> 'skill')
       or item ->> 'prompt' is null or item -> 'sections' is null then
      raise exception 'Invalid presentation' using errcode = '22023';
    end if;
    skill := config ->> 'skill';
  end loop;
  saved_deck_id := public.create_captured_word_deck(input_title, input_source_excerpt, input_cards);
  update public.decks set generation_session_id = input_session_id,
    kind = case when skill = 'word' then 'word' else 'problem' end
    where id = saved_deck_id and user_id = owner_id;
  for item in select value from jsonb_array_elements(input_cards) loop
    update public.cards set presentation = item -> 'presentation'
      where cards.deck_id = saved_deck_id and cards.position = card_position and user_id = owner_id;
    card_position := card_position + 1;
  end loop;
  return saved_deck_id;
end;
$$;
revoke all on function public.create_agent_deck(uuid, text, text, jsonb) from public, anon;
grant execute on function public.create_agent_deck(uuid, text, text, jsonb) to authenticated;
