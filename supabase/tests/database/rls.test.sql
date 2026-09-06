begin;
create extension if not exists pgtap with schema extensions;
set search_path = public, extensions;
select plan(8);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at, confirmation_token, recovery_token,
  email_change_token_new, email_change
) values
  ('00000000-0000-0000-0000-000000000000', '11111111-1111-1111-1111-111111111111',
   'authenticated', 'authenticated', 'owner@loopcard.test', crypt('password123', gen_salt('bf')),
   now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '22222222-2222-2222-2222-222222222222',
   'authenticated', 'authenticated', 'other@loopcard.test', crypt('password123', gen_salt('bf')),
   now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '');

set local role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

insert into public.decks (id, user_id, title, kind)
values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', auth.uid(), 'Owner deck', 'generic');

select is((select count(*)::integer from public.decks where title = 'Owner deck'), 1, 'owner sees own deck');
select lives_ok(
  $$insert into public.cards (user_id, deck_id, prompt, position)
    values (auth.uid(), 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Front', 0)$$,
  'owner can create a card'
);
select is((select count(*)::integer from public.cards where prompt = 'Front'), 1, 'owner sees own card');

select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', true);
select is((select count(*)::integer from public.decks where title = 'Owner deck'), 0, 'other user cannot see owner deck');
select is((select count(*)::integer from public.cards where prompt = 'Front'), 0, 'other user cannot see owner card');
select throws_ok(
  $$insert into public.cards (user_id, deck_id, prompt, position)
    values (auth.uid(), 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Attack', 1)$$,
  '23503', null, 'other user cannot attach a card to owner deck'
);
select lives_ok(
  $$update public.decks set title = 'Hijacked'
    where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'$$,
  'cross-user update silently affects no hidden rows'
);
select is(
  (select count(*)::integer from public.profiles),
  1,
  'other user sees only own profile'
);

select * from finish();
rollback;
