begin;
create extension if not exists pgtap with schema extensions;
set search_path = public, extensions;
select plan(19);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at, confirmation_token, recovery_token,
  email_change_token_new, email_change
) values
  ('00000000-0000-0000-0000-000000000000', '66666666-6666-6666-6666-666666666666',
   'authenticated', 'authenticated', 'loop-owner@loopcard.test', crypt('password123', gen_salt('bf')),
   now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '77777777-7777-7777-7777-777777777777',
   'authenticated', 'authenticated', 'loop-other@loopcard.test', crypt('password123', gen_salt('bf')),
   now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '');

set local role authenticated;
select set_config('request.jwt.claim.sub', '66666666-6666-6666-6666-666666666666', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

create temporary table captured_deck as
select public.create_captured_word_deck(
  'Captured vocabulary',
  'borrow lend retain',
  '[{"prompt":"borrow","hint":"Starts with b","sections":[{"title":"Meaning","heading":"take temporarily","body":"Return it later."},{"title":"Example & collocation","heading":"borrow a book","body":"May I borrow this book?"},{"title":"Common confusion","heading":"borrow vs lend","body":"Borrow receives; lend gives."}]}]'::jsonb
) as id;

select is((select count(*)::integer from public.cards where source_type = 'capture'), 1, 'captured card is stored');
select is((select count(*)::integer from public.card_sections where card_id = (select id from public.cards where prompt = 'borrow' and deck_id = (select id from captured_deck))), 3, 'sections remain readable');
select is((select count(*)::integer from public.card_sections where card_id = (select id from public.cards where prompt = 'borrow' and deck_id = (select id from captured_deck))), 3, 'all three back sections are preserved');
select is((select source_excerpt from public.cards where prompt = 'borrow' and deck_id = (select id from captured_deck)), 'borrow lend retain', 'capture provenance is stored');
select is((select hint from public.cards where prompt = 'borrow' and deck_id = (select id from captured_deck)), 'Starts with b', 'retrieval hint is stored');

select is(
  (select interval_days from public.record_practice_attempts(
    (select id from captured_deck),
    jsonb_build_array(jsonb_build_object('card_id', (select id from public.cards where prompt = 'borrow' and deck_id = (select id from captured_deck)), 'familiarity', 'mastered', 'assistance_used', false))
  )),
  3,
  'first mastered rating schedules three days'
);
select is((select review_count from public.card_memory_states), 1, 'memory state records first review');
select is((select count(*)::integer from public.practice_attempts), 1, 'practice event is append-only');
select is((select assistance_used from public.practice_attempts order by id desc limit 1), false, 'practice event records unassisted recall');

select is(
  (select interval_days from public.record_practice_attempts(
    (select id from captured_deck),
    jsonb_build_array(jsonb_build_object('card_id', (select id from public.cards where prompt = 'borrow' and deck_id = (select id from captured_deck)), 'familiarity', 'mastered'))
  )),
  6,
  'second mastered rating doubles interval'
);
select is((select review_count from public.card_memory_states), 2, 'upsert increments review count');

select is(
  public.append_generated_cards(
    (select id from captured_deck),
    jsonb_build_array(jsonb_build_object(
      'parent_card_id', (select id from public.cards where prompt = 'borrow' and deck_id = (select id from captured_deck)),
      'prompt', 'lend',
      'hint', 'The other direction of borrow',
      'relation_type', 'contrast',
      'reason', 'Often confused with borrow',
      'sections', jsonb_build_array(jsonb_build_object('title', 'Meaning', 'heading', 'give temporarily', 'body', 'Expect it back.'))
    ))
  ),
  1,
  'one approved extension is appended'
);
select is((select count(*)::integer from public.card_relations), 1, 'extension relation is stored');
select is((select source_type from public.cards where prompt = 'lend' and deck_id = (select id from captured_deck)), 'ai_extension', 'extension provenance is explicit');
select throws_ok(
  $$select public.append_generated_cards(
    (select id from captured_deck),
    jsonb_build_array(jsonb_build_object(
      'parent_card_id', (select id from public.cards where prompt = 'borrow' and deck_id = (select id from captured_deck)),
      'prompt', 'lend',
      'relation_type', 'contrast',
      'reason', 'Duplicate suggestion',
      'sections', jsonb_build_array(jsonb_build_object('title', 'Meaning', 'heading', 'give temporarily', 'body', 'Expect it back.'))
    ))
  )$$,
  '22023', 'Invalid generated card', 'duplicate extension prompts are rejected'
);

select set_config('request.jwt.claim.sub', '77777777-7777-7777-7777-777777777777', true);
select is((select count(*)::integer from public.card_memory_states), 0, 'other user cannot read memory state');
select is((select count(*)::integer from public.card_relations), 0, 'other user cannot read relations');
select throws_ok(
  $$select public.record_practice_attempts(
    (select id from captured_deck),
    jsonb_build_array(jsonb_build_object('card_id', '00000000-0000-0000-0000-000000000000', 'familiarity', 'mastered'))
  )$$,
  'P0002', 'Deck not found', 'other user cannot schedule owner cards'
);
select throws_ok(
  $$select public.append_generated_cards((select id from captured_deck), '[]'::jsonb)$$,
  '22023', 'Invalid extension batch', 'empty extension batches are rejected'
);

select * from finish();
rollback;
