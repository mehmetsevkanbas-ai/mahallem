-- =============================================================================
-- Mahallem — Supabase veritabanı şeması
-- Supabase panelinde: SQL Editor > New query > bu dosyayı yapıştır > Run
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Profiller (auth.users ile 1-1)
-- -----------------------------------------------------------------------------
create table if not exists public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  interests    text[] not null default '{}',
  role         text not null default 'user' check (role in ('user', 'admin')),
  onboarded    boolean not null default false,
  created_at   timestamptz not null default now()
);

-- Yeni kullanıcı kaydolduğunda otomatik profil oluştur.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1))
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Oturumdaki kullanıcı yönetici mi?
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles where id = auth.uid() and role = 'admin'
  );
$$;

-- -----------------------------------------------------------------------------
-- Etkinlikler ve kurslar
-- -----------------------------------------------------------------------------
create table if not exists public.events (
  id          uuid primary key default gen_random_uuid(),
  title       text not null check (char_length(title) between 3 and 120),
  description text not null default '' check (char_length(description) <= 2000),
  category    text not null check (category in (
                'music', 'theatre', 'art', 'dance', 'cinema',
                'literature', 'festival', 'outdoor', 'workshop')),
  kind        text not null default 'event' check (kind in ('event', 'course')),
  start_at    timestamptz,
  end_at      timestamptz,
  schedule    text,
  lat         double precision not null check (lat between -90 and 90),
  lng         double precision not null check (lng between -180 and 180),
  venue_name  text,
  address     text,
  image_url   text,
  price       text,
  is_free     boolean not null default true,
  organizer   text,
  contact     text,
  status      text not null default 'pending'
                check (status in ('pending', 'approved', 'rejected')),
  created_by  uuid references auth.users (id) on delete set null default auth.uid(),
  created_at  timestamptz not null default now(),
  constraint event_needs_start check (kind = 'course' or start_at is not null),
  constraint end_after_start check (end_at is null or start_at is null or end_at >= start_at)
);

create index if not exists events_status_start_idx on public.events (status, start_at);
create index if not exists events_created_by_idx on public.events (created_by);

-- -----------------------------------------------------------------------------
-- Favoriler
-- -----------------------------------------------------------------------------
create table if not exists public.favorites (
  user_id    uuid not null references auth.users (id) on delete cascade,
  event_id   uuid not null references public.events (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, event_id)
);

-- -----------------------------------------------------------------------------
-- Yetkiler (Data API erişimi)
-- -----------------------------------------------------------------------------
grant usage on schema public to anon, authenticated;

grant select on public.events to anon, authenticated;
grant insert, update, delete on public.events to authenticated;

grant select on public.profiles to authenticated;
-- Kullanıcı kendi rolünü değiştiremesin: yalnızca bu sütunlar güncellenebilir.
revoke update on public.profiles from anon, authenticated;
grant update (display_name, interests, onboarded) on public.profiles to authenticated;

grant select, insert, delete on public.favorites to authenticated;

-- -----------------------------------------------------------------------------
-- Satır düzeyi güvenlik (RLS)
-- -----------------------------------------------------------------------------
alter table public.profiles  enable row level security;
alter table public.events    enable row level security;
alter table public.favorites enable row level security;

-- Profiller: herkes yalnızca kendi profilini görür ve günceller (yönetici hepsini görür).
drop policy if exists "profiles_select" on public.profiles;
create policy "profiles_select" on public.profiles
  for select to authenticated
  using (id = auth.uid() or public.is_admin());

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles
  for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- Etkinlikler: onaylılar herkese açık; sahibi ve yönetici diğerlerini de görür.
drop policy if exists "events_select" on public.events;
create policy "events_select" on public.events
  for select to anon, authenticated
  using (
    status = 'approved'
    or created_by = auth.uid()
    or public.is_admin()
  );

-- Giriş yapan kullanıcı etkinlik ekleyebilir; yönetici değilse "pending" olmak zorunda.
drop policy if exists "events_insert" on public.events;
create policy "events_insert" on public.events
  for insert to authenticated
  with check (
    created_by = auth.uid()
    and (status = 'pending' or public.is_admin())
  );

-- Yalnızca yönetici güncelleyebilir (onay / ret).
drop policy if exists "events_update_admin" on public.events;
create policy "events_update_admin" on public.events
  for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- Sahibi veya yönetici silebilir.
drop policy if exists "events_delete" on public.events;
create policy "events_delete" on public.events
  for delete to authenticated
  using (created_by = auth.uid() or public.is_admin());

-- Favoriler: herkes yalnızca kendi kayıtlarını yönetir.
drop policy if exists "favorites_own" on public.favorites;
create policy "favorites_own" on public.favorites
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- -----------------------------------------------------------------------------
-- Görsel depolama (Storage)
-- -----------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'event-images', 'event-images', true, 5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
on conflict (id) do nothing;

-- Kullanıcılar yalnızca kendi klasörlerine (kullanıcı-id/...) yükleyebilir.
drop policy if exists "event_images_insert_own" on storage.objects;
create policy "event_images_insert_own" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'event-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "event_images_delete_own" on storage.objects;
create policy "event_images_delete_own" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'event-images'
    and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin())
  );
