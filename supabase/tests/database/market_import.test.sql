begin;
create extension if not exists pgtap with schema extensions;
set search_path = public, extensions;
select plan(7);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at, confirmation_token, recovery_token,
  email_change_token_new, email_change
) values (
  '00000000-0000-0000-0000-000000000000', '33333333-3333-3333-3333-333333333333',
  'authenticated', 'authenticated', 'market@loopcard.test', crypt('password123', gen_salt('bf')),
  now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '33333333-3333-3333-3333-333333333333', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

select is((select count(*)::integer from public.decks where visibility = 'public'), 4, 'published market decks are readable');
select is((select status from public.add_market_deck('everyday-english-core')), 'added', 'first add succeeds');
select is((select count(*)::integer from public.deck_library), 1, 'one library entry is created');
select is((select count(*)::integer from public.cards where deck_id = (select id from public.decks where market_slug = 'everyday-english-core')), 3, 'public cards remain on the shared deck');
select is((select count(*)::integer from public.decks where market_slug = 'everyday-english-core'), 1, 'shared deck is not copied');
select is((select status from public.add_market_deck('everyday-english-core')), 'already_added', 'second add is idempotent');
select is((select count(*)::integer from public.deck_library), 1, 'duplicate library entry is not created');

select * from finish();
rollback;
