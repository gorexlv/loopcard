create extension if not exists pgcrypto with schema extensions;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.decks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(trim(title)) between 1 and 120),
  subtitle text not null default '',
  kind text not null default 'generic'
    check (kind in ('generic', 'word', 'formula', 'idiom', 'concept', 'equation')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, user_id)
);

create table public.cards (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  deck_id uuid not null,
  prompt text not null check (char_length(trim(prompt)) between 1 and 1000),
  position integer not null default 0 check (position >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, user_id),
  unique (deck_id, position),
  constraint cards_owned_deck_fk foreign key (deck_id, user_id)
    references public.decks(id, user_id) on delete cascade
);

create table public.card_sections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  card_id uuid not null,
  title text not null check (char_length(trim(title)) between 1 and 80),
  heading text not null default '',
  body text not null default '',
  position integer not null default 0 check (position >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (card_id, position),
  constraint sections_owned_card_fk foreign key (card_id, user_id)
    references public.cards(id, user_id) on delete cascade
);

create table public.practice_attempts (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  deck_id uuid not null,
  card_id uuid not null,
  familiarity text not null check (familiarity in ('mastered', 'fuzzy', 'forgotten')),
  practiced_at timestamptz not null default now(),
  constraint attempts_owned_deck_fk foreign key (deck_id, user_id)
    references public.decks(id, user_id) on delete cascade,
  constraint attempts_owned_card_fk foreign key (card_id, user_id)
    references public.cards(id, user_id) on delete cascade
);

create index decks_user_updated_idx on public.decks (user_id, updated_at desc);
create index cards_user_id_idx on public.cards (user_id);
create index cards_deck_position_idx on public.cards (deck_id, position);
create index sections_user_id_idx on public.card_sections (user_id);
create index sections_card_position_idx on public.card_sections (card_id, position);
create index attempts_user_practiced_idx on public.practice_attempts (user_id, practiced_at desc);
create index attempts_deck_id_idx on public.practice_attempts (deck_id);
create index attempts_card_id_idx on public.practice_attempts (card_id);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at before update on public.profiles
for each row execute function public.set_updated_at();
create trigger decks_set_updated_at before update on public.decks
for each row execute function public.set_updated_at();
create trigger cards_set_updated_at before update on public.cards
for each row execute function public.set_updated_at();
create trigger sections_set_updated_at before update on public.card_sections
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1)),
    new.raw_user_meta_data ->> 'avatar_url'
  );
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.decks enable row level security;
alter table public.cards enable row level security;
alter table public.card_sections enable row level security;
alter table public.practice_attempts enable row level security;

alter table public.profiles force row level security;
alter table public.decks force row level security;
alter table public.cards force row level security;
alter table public.card_sections force row level security;
alter table public.practice_attempts force row level security;

create policy profiles_select_own on public.profiles
for select to authenticated using ((select auth.uid()) = id);
create policy profiles_update_own on public.profiles
for update to authenticated using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

create policy decks_select_own on public.decks
for select to authenticated using ((select auth.uid()) = user_id);
create policy decks_insert_own on public.decks
for insert to authenticated with check ((select auth.uid()) = user_id);
create policy decks_update_own on public.decks
for update to authenticated using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);
create policy decks_delete_own on public.decks
for delete to authenticated using ((select auth.uid()) = user_id);

create policy cards_select_own on public.cards
for select to authenticated using ((select auth.uid()) = user_id);
create policy cards_insert_own on public.cards
for insert to authenticated with check ((select auth.uid()) = user_id);
create policy cards_update_own on public.cards
for update to authenticated using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);
create policy cards_delete_own on public.cards
for delete to authenticated using ((select auth.uid()) = user_id);

create policy sections_select_own on public.card_sections
for select to authenticated using ((select auth.uid()) = user_id);
create policy sections_insert_own on public.card_sections
for insert to authenticated with check ((select auth.uid()) = user_id);
create policy sections_update_own on public.card_sections
for update to authenticated using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);
create policy sections_delete_own on public.card_sections
for delete to authenticated using ((select auth.uid()) = user_id);

create policy attempts_select_own on public.practice_attempts
for select to authenticated using ((select auth.uid()) = user_id);
create policy attempts_insert_own on public.practice_attempts
for insert to authenticated with check ((select auth.uid()) = user_id);

revoke all on table public.profiles, public.decks, public.cards,
  public.card_sections, public.practice_attempts from anon;
grant select, update on table public.profiles to authenticated;
grant select, insert, update, delete on table public.decks, public.cards,
  public.card_sections to authenticated;
grant select, insert on table public.practice_attempts to authenticated;
grant usage, select on sequence public.practice_attempts_id_seq to authenticated;
