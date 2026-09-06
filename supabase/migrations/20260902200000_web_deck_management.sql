create or replace function public.save_owned_deck(
  input_deck_id uuid,
  input_title text,
  input_subtitle text,
  input_kind text,
  input_visibility text,
  input_cards jsonb
) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  current_user_id uuid := auth.uid();
  saved_deck_id uuid;
  card jsonb;
  new_card_id uuid;
  card_position integer := 0;
begin
  if current_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  input_title := trim(input_title);
  input_subtitle := trim(coalesce(input_subtitle, ''));
  if char_length(input_title) not between 1 and 120 then
    raise exception 'Invalid title' using errcode = '22023';
  end if;
  if char_length(input_subtitle) > 240 or input_kind not in ('generic', 'word', 'formula', 'idiom', 'concept', 'equation') or input_visibility not in ('private', 'public') then
    raise exception 'Invalid deck fields' using errcode = '22023';
  end if;
  if jsonb_typeof(input_cards) <> 'array' or jsonb_array_length(input_cards) > 500 then
    raise exception 'Invalid cards' using errcode = '22023';
  end if;

  if input_deck_id is null then
    insert into public.decks (user_id, title, subtitle, kind, visibility)
    values (current_user_id, input_title, input_subtitle, input_kind, input_visibility)
    returning id into saved_deck_id;
  else
    update public.decks set title = input_title, subtitle = input_subtitle,
      kind = input_kind, visibility = input_visibility
    where id = input_deck_id and user_id = current_user_id
    returning id into saved_deck_id;
    if saved_deck_id is null then
      raise exception 'Deck not found' using errcode = 'P0002';
    end if;
    delete from public.practice_attempts where deck_id = saved_deck_id and user_id = current_user_id;
    delete from public.cards where deck_id = saved_deck_id and user_id = current_user_id;
  end if;

  for card in select value from jsonb_array_elements(input_cards) loop
    if char_length(trim(coalesce(card ->> 'prompt', ''))) not between 1 and 1000
       or char_length(coalesce(card ->> 'answer', '')) > 10000 then
      raise exception 'Invalid card' using errcode = '22023';
    end if;
    insert into public.cards (user_id, deck_id, prompt, position)
    values (current_user_id, saved_deck_id, trim(card ->> 'prompt'), card_position)
    returning id into new_card_id;
    insert into public.card_sections (user_id, card_id, title, heading, body, position)
    values (current_user_id, new_card_id, 'Answer', '', trim(coalesce(card ->> 'answer', '')), 0);
    card_position := card_position + 1;
  end loop;
  return saved_deck_id;
end;
$$;

revoke all on function public.save_owned_deck(uuid, text, text, text, text, jsonb) from public, anon;
grant execute on function public.save_owned_deck(uuid, text, text, text, text, jsonb) to authenticated;
