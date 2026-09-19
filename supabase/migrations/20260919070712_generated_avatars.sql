-- Generated portraits are server-owned; clients can only read their own result.
create table public.generated_avatars (
  user_id uuid primary key references auth.users(id) on delete cascade,
  avatar_url text,
  claimed_at timestamptz not null default now(),
  attempts integer not null default 1
);
alter table public.generated_avatars enable row level security;
grant select on public.generated_avatars to authenticated;
grant all on public.generated_avatars to service_role;
revoke insert, update, delete on public.generated_avatars from anon, authenticated;
create policy generated_avatars_select_own on public.generated_avatars
  for select to authenticated using ((select auth.uid()) = user_id);

-- An atomic, server-only lease prevents concurrent requests from generating twice.
create function public.claim_avatar_generation(target_user uuid)
returns boolean language sql security invoker set search_path = '' as $$
  with claimed as (
    insert into public.generated_avatars (user_id) values (target_user)
    on conflict (user_id) do update
      set claimed_at = now(), attempts = public.generated_avatars.attempts + 1
      where public.generated_avatars.avatar_url is null
        and public.generated_avatars.claimed_at < now() - interval '10 minutes'
        and public.generated_avatars.attempts < 3
    returning user_id
  ) select exists(select 1 from claimed);
$$;
revoke all on function public.claim_avatar_generation(uuid) from public, anon, authenticated;
grant execute on function public.claim_avatar_generation(uuid) to service_role;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('generated-avatars', 'generated-avatars', true, 5242880, array['image/webp', 'image/png'])
on conflict (id) do nothing;
-- No client write policies: only the authenticated Edge Function's service role uploads.
