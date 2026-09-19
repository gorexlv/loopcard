alter table public.decks drop constraint decks_kind_check;
alter table public.decks add constraint decks_kind_check
  check (kind in ('generic', 'word', 'formula', 'idiom', 'concept', 'equation', 'problem'));

-- Presentation is rendered by both chat previews and the study screen.
alter table public.cards add column presentation jsonb not null default '{}'::jsonb
  check (jsonb_typeof(presentation) = 'object');
alter table public.decks add column generation_session_id uuid;
create unique index decks_generation_session_unique
  on public.decks(user_id, generation_session_id) where generation_session_id is not null;

-- One transaction covers the existing validated card insert, presentation, and
-- idempotency key. The advisory lock serializes retries for the same user/session.
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
       or coalesce(config ->> 'skill', '') not in ('word', 'knowledge')
       or coalesce(config ->> 'layout', '') not in ('centered', 'stacked')
       or coalesce(config ->> 'session_id', '') <> input_session_id::text
       or char_length(coalesce(config ->> 'front', '')) not between 1 and 800
       or char_length(coalesce(config ->> 'back', '')) not between 1 and 800
       or coalesce(config ->> 'skill_version', '') <> '1'
       or coalesce(config ->> 'preset', '') not in ('word-simple', 'word-detail', 'knowledge-qa')
       or ((config ->> 'skill' = 'knowledge') <> (config ->> 'preset' = 'knowledge-qa'))
       or (skill is not null and skill <> config ->> 'skill')
       or item ->> 'prompt' is null or item -> 'sections' is null then
      raise exception 'Invalid presentation' using errcode = '22023';
    end if;
    skill := config ->> 'skill';
  end loop;
  saved_deck_id := public.create_captured_word_deck(input_title, input_source_excerpt, input_cards);
  update public.decks set generation_session_id = input_session_id,
    kind = case when skill = 'knowledge' then 'problem' else 'word' end
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
