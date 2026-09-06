alter table public.decks alter column user_id drop not null;
alter table public.cards alter column user_id drop not null;
alter table public.card_sections alter column user_id drop not null;

alter table public.decks
  add column visibility text not null default 'private'
    check (visibility in ('private', 'public')),
  add column market_slug text unique
    check (market_slug is null or market_slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  add constraint platform_deck_is_public
    check (user_id is not null or visibility = 'public');

create table public.deck_library (
  user_id uuid not null references auth.users(id) on delete cascade,
  deck_id uuid not null references public.decks(id) on delete cascade,
  added_at timestamptz not null default now(),
  primary key (user_id, deck_id)
);
create index deck_library_user_added_idx on public.deck_library (user_id, added_at desc);

alter table public.deck_library enable row level security;
alter table public.deck_library force row level security;
create policy deck_library_select_own on public.deck_library
for select to authenticated using ((select auth.uid()) = user_id);
create policy deck_library_insert_own on public.deck_library
for insert to authenticated with check (
  (select auth.uid()) = user_id and exists (
    select 1 from public.decks where id = deck_id and visibility = 'public'
  )
);
create policy deck_library_delete_own on public.deck_library
for delete to authenticated using ((select auth.uid()) = user_id);

create policy decks_select_public on public.decks
for select to anon, authenticated using (visibility = 'public');
create policy cards_select_public_deck on public.cards
for select to anon, authenticated using (
  exists (select 1 from public.decks where decks.id = cards.deck_id and decks.visibility = 'public')
);
create policy sections_select_public_deck on public.card_sections
for select to anon, authenticated using (
  exists (
    select 1 from public.cards
    join public.decks on decks.id = cards.deck_id
    where cards.id = card_sections.card_id and decks.visibility = 'public'
  )
);

grant select on table public.decks, public.cards, public.card_sections to anon;
grant select, insert, delete on table public.deck_library to authenticated;

create or replace function public.seed_platform_deck(
  deck_slug text, deck_title text, deck_subtitle text, deck_kind text, deck_cards jsonb
) returns void language plpgsql security definer set search_path = '' as $$
declare
  new_deck_id uuid;
  new_card_id uuid;
  card jsonb;
  section jsonb;
  card_position integer := 0;
  section_position integer;
begin
  insert into public.decks (user_id, title, subtitle, kind, visibility, market_slug)
  values (null, deck_title, deck_subtitle, deck_kind, 'public', deck_slug)
  returning id into new_deck_id;
  for card in select value from jsonb_array_elements(deck_cards) loop
    insert into public.cards (user_id, deck_id, prompt, position)
    values (null, new_deck_id, card ->> 'prompt', card_position)
    returning id into new_card_id;
    section_position := 0;
    for section in select value from jsonb_array_elements(coalesce(card -> 'sections', '[]'::jsonb)) loop
      insert into public.card_sections (user_id, card_id, title, heading, body, position)
      values (null, new_card_id, section ->> 'title', coalesce(section ->> 'heading', ''), coalesce(section ->> 'body', ''), section_position);
      section_position := section_position + 1;
    end loop;
    card_position := card_position + 1;
  end loop;
end;
$$;

select public.seed_platform_deck('chinese-zodiac-origins', '十二生肖的来历', '12 张卡 · 民间文化', 'concept',
  '[{"prompt":"子鼠","sections":[{"title":"来历","heading":"机敏居首","body":"鼠借牛渡河，在抵岸前跃下，抢先到达。"}]},{"prompt":"丑牛","sections":[{"title":"来历","heading":"勤恳第二","body":"牛凭耐力最早接近终点，又载鼠过河。"}]},{"prompt":"寅虎","sections":[{"title":"来历","heading":"勇猛第三","body":"虎凭力量穿过激流，但被水势阻慢。"}]},{"prompt":"卯兔","sections":[{"title":"来历","heading":"灵巧第四","body":"兔借石跳跃，又攀上漂木渡河。"}]},{"prompt":"辰龙","sections":[{"title":"来历","heading":"行善第五","body":"龙途中降雨救助百姓，又帮助兔子。"}]},{"prompt":"巳蛇","sections":[{"title":"来历","heading":"小龙第六","body":"蛇随马渡河，在终点前先行一步。"}]},{"prompt":"午马","sections":[{"title":"来历","heading":"奔腾第七","body":"马一路疾驰，在终点前被蛇抢先。"}]},{"prompt":"未羊","sections":[{"title":"来历","heading":"和善第八","body":"羊与猴、鸡合作乘木筏渡河。"}]},{"prompt":"申猴","sections":[{"title":"来历","heading":"聪慧第九","body":"猴与羊、鸡合力清除障碍、驾筏过河。"}]},{"prompt":"酉鸡","sections":[{"title":"来历","heading":"协作第十","body":"鸡发现木筏并召集羊、猴共同渡河。"}]},{"prompt":"戌狗","sections":[{"title":"来历","heading":"忠诚第十一","body":"狗擅长游水，却因途中贪玩而耽搁。"}]},{"prompt":"亥猪","sections":[{"title":"来历","heading":"安逸第十二","body":"猪途中进食睡觉，醒来后最后到达。"}]}]'::jsonb);
select public.seed_platform_deck('everyday-english-core', 'Everyday English', '3 cards · Language', 'word',
  '[{"prompt":"borrow","sections":[{"title":"Meaning","heading":"take and use temporarily","body":"Borrow focuses on receiving something with the intention of returning it."},{"title":"Example","heading":"borrow a book","body":"May I borrow this book for the weekend?"},{"title":"Distinction","heading":"borrow vs. lend","body":"You borrow from someone; they lend something to you."}]},{"prompt":"serene","sections":[{"title":"Meaning","heading":"calm and peaceful","body":"A quiet state without disturbance or anxiety."},{"title":"Example","heading":"a serene morning","body":"The lake looked serene before sunrise."}]},{"prompt":"retain","sections":[{"title":"Meaning","heading":"continue to have","body":"To keep possession, memory, or control of something."},{"title":"Example","heading":"retain information","body":"Short review sessions help you retain information."}]}]'::jsonb);
select public.seed_platform_deck('chemistry-formulas', 'Common Chemical Formulas', '3 cards · Science', 'formula',
  '[{"prompt":"H₂O","sections":[{"title":"Name","heading":"Water","body":"Two hydrogen atoms bonded to one oxygen atom."},{"title":"Structure","heading":"Bent molecule","body":"Its polar geometry enables hydrogen bonding."}]},{"prompt":"CO₂","sections":[{"title":"Name","heading":"Carbon dioxide","body":"One carbon atom double-bonded to two oxygen atoms."},{"title":"Context","heading":"Carbon cycle","body":"Produced by respiration and used by plants during photosynthesis."}]},{"prompt":"NaCl","sections":[{"title":"Name","heading":"Sodium chloride","body":"An ionic compound commonly known as table salt."}]}]'::jsonb);
select public.seed_platform_deck('design-principles', 'Principles of Good Design', '2 cards · Design', 'concept',
  '[{"prompt":"Hierarchy","sections":[{"title":"Definition","heading":"Order attention","body":"Visual hierarchy tells the eye where to begin and what matters next."}]},{"prompt":"Rhythm","sections":[{"title":"Definition","heading":"Repeat with intent","body":"Spacing, type, and shape create a predictable visual cadence."}]}]'::jsonb);
drop function public.seed_platform_deck(text, text, text, text, jsonb);

create or replace function public.add_market_deck(deck_slug text)
returns table (deck_id uuid, status text)
language plpgsql security definer set search_path = '' as $$
declare
  current_user_id uuid := auth.uid();
  selected_deck_id uuid;
  inserted_count integer;
begin
  if current_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  select id into selected_deck_id from public.decks
  where (market_slug = deck_slug or id::text = deck_slug) and visibility = 'public';
  if not found then raise exception 'Market deck not found' using errcode = 'P0002'; end if;
  insert into public.deck_library (user_id, deck_id)
  values (current_user_id, selected_deck_id) on conflict do nothing;
  get diagnostics inserted_count = row_count;
  return query select selected_deck_id, case when inserted_count = 1 then 'added' else 'already_added' end;
end;
$$;
revoke all on function public.add_market_deck(text) from public, anon;
grant execute on function public.add_market_deck(text) to authenticated;
