begin;
create extension if not exists pgtap with schema extensions;
set search_path = public, extensions;
select plan(9);
insert into auth.users(id, aud, role, email) values
 ('88888888-8888-4888-8888-888888888888', 'authenticated','authenticated','agent-owner@loopcard.test'),
 ('99999999-9999-4999-8999-999999999999', 'authenticated','authenticated','agent-other@loopcard.test');
set local role authenticated;
select set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',true);
create temporary table agent_input as select '[{"prompt":"What is evaporation?","hint":"","sections":[{"title":"Answer","heading":"Liquid to gas","body":"Water changes to vapor."}],"presentation":{"session_id":"12345678-1234-4234-8234-123456789abc","skill":"knowledge","skill_version":"1","preset":"knowledge-qa","front":"Question","back":"Answer and explanation","layout":"stacked","source_ids":["photo1"],"revision":1}}]'::jsonb as cards;
create temporary table agent_saved as select public.create_agent_deck('12345678-1234-4234-8234-123456789abc','Science','Water changes to vapor.',(select cards from agent_input)) as id;
select is((select kind from public.decks where id=(select id from agent_saved)), 'problem', 'knowledge deck has correct kind');
select is((select presentation->>'preset' from public.cards where deck_id=(select id from agent_saved)), 'knowledge-qa', 'presentation persists');
select is((select presentation->'source_ids' from public.cards where deck_id=(select id from agent_saved)), '["photo1"]'::jsonb, 'photo provenance persists');
select is(public.create_agent_deck('12345678-1234-4234-8234-123456789abc','Retry','Water changes to vapor.',(select cards from agent_input)),(select id from agent_saved),'retry returns same deck');
select is((select count(*)::integer from public.cards where deck_id=(select id from agent_saved)),1,'retry does not duplicate cards');
select throws_ok($$select public.create_agent_deck(null,'Bad','text',(select cards from agent_input))$$,'22023','Invalid generation session','missing idempotency key is rejected');
select throws_ok($$select public.create_agent_deck('12345678-1234-4234-8234-123456789abd','Bad','text',(select cards from agent_input))$$,'22023','Invalid presentation','session mismatch rejected');
select set_config('request.jwt.claim.sub','99999999-9999-4999-8999-999999999999',true);
select is((select count(*)::integer from public.decks where id=(select id from agent_saved)),0,'another user cannot read saved deck');
select is((select count(*)::integer from public.cards where deck_id=(select id from agent_saved)),0,'another user cannot read card presentation');
select * from finish();
rollback;
