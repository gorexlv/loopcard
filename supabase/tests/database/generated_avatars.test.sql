begin;
create extension if not exists pgtap with schema extensions;
set search_path = public, extensions;
select plan(8);
insert into auth.users(id, email) values
 ('aa000000-0000-0000-0000-000000000001', 'avatar-test-1@example.test'),
 ('aa000000-0000-0000-0000-000000000002', 'avatar-test-2@example.test');
set local role service_role;
select ok(public.claim_avatar_generation('aa000000-0000-0000-0000-000000000001'), 'first request claims generation');
select ok(not public.claim_avatar_generation('aa000000-0000-0000-0000-000000000001'), 'concurrent request cannot claim generation');
reset role;
update public.generated_avatars set claimed_at = now() - interval '11 minutes';
set local role service_role;
select ok(public.claim_avatar_generation('aa000000-0000-0000-0000-000000000001'), 'expired request can retry');
update public.generated_avatars set avatar_url = 'https://example.test/avatar.png';
select ok(not public.claim_avatar_generation('aa000000-0000-0000-0000-000000000001'), 'saved avatar cannot regenerate');
reset role;
select set_config('request.jwt.claim.sub', 'aa000000-0000-0000-0000-000000000002', true);
set local role authenticated;
select is((select count(*)::integer from public.generated_avatars), 0, 'other account cannot read avatar record');
select throws_ok($$select public.claim_avatar_generation('aa000000-0000-0000-0000-000000000002')$$, '42501', null, 'client cannot invoke generation lease directly');
select throws_ok($$update public.generated_avatars set avatar_url = 'https://evil.test'$$, '42501', null, 'client cannot replace generated results');
reset role;
select set_config('request.jwt.claim.sub', 'aa000000-0000-0000-0000-000000000001', true);
set local role authenticated;
select is((select count(*)::integer from public.generated_avatars), 1, 'owner can read generated result');
reset role;
select * from finish();
rollback;
