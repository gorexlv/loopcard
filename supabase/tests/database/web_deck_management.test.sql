begin;
create extension if not exists pgtap with schema extensions;
set search_path = public, extensions;
select plan(6);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at, confirmation_token, recovery_token,
  email_change_token_new, email_change
) values
  ('00000000-0000-0000-0000-000000000000', '44444444-4444-4444-4444-444444444444', 'authenticated', 'authenticated', 'web-owner@loopcard.test', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '55555555-5555-5555-5555-555555555555', 'authenticated', 'authenticated', 'web-other@loopcard.test', crypt('password123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '');

set local role authenticated;
select set_config('request.jwt.claim.sub', '44444444-4444-4444-4444-444444444444', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select isnt(public.save_owned_deck(null, 'Private web deck', '', 'word', 'private', '[{"prompt":"front","answer":"back"}]'), null, 'owner creates a deck');
select is((select count(*)::integer from public.decks where user_id = auth.uid() and visibility = 'private'), 1, 'new user deck is private');
select is((select count(*)::integer from public.cards where user_id = auth.uid()), 1, 'card is created atomically');
create temporary table saved_deck_id as select id from public.decks where title = 'Private web deck';

select set_config('request.jwt.claim.sub', '55555555-5555-5555-5555-555555555555', true);
select is((select count(*)::integer from public.decks where title = 'Private web deck'), 0, 'other user cannot read private deck');
select throws_ok(
  $$select public.save_owned_deck((select id from saved_deck_id), 'Attack', '', 'word', 'public', '[]')$$,
  'P0002', 'Deck not found', 'other user cannot edit owner deck'
);

select set_config('request.jwt.claim.sub', '44444444-4444-4444-4444-444444444444', true);
select is((select visibility from public.decks where title = 'Private web deck'), 'private', 'failed attack leaves visibility unchanged');
select * from finish();
rollback;
