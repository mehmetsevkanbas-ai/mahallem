-- =============================================================================
-- Mahallem — belediye sitelerinden otomatik aktarılan etkinlikler
-- 0001_init.sql'den sonra SQL Editor'de çalıştırın.
-- =============================================================================

alter table public.events
  add column if not exists source     text,          -- 'alanya_bel', 'antalya_bb' (kullanıcı etkinliklerinde null)
  add column if not exists source_id  text,          -- kaynaktaki kayıt kimliği
  add column if not exists source_url text,          -- kaynaktaki etkinlik sayfası
  add column if not exists synced_at  timestamptz;   -- son senkronizasyon zamanı

alter table public.events drop constraint if exists events_source_unique;
alter table public.events add constraint events_source_unique unique (source, source_id);

-- Kullanıcılar kaynaklı (resmi) kayıt oluşturamasın.
drop policy if exists "events_insert" on public.events;
create policy "events_insert" on public.events
  for insert to authenticated
  with check (
    created_by = auth.uid()
    and source is null
    and (status = 'pending' or public.is_admin())
  );

-- -----------------------------------------------------------------------------
-- Senkronizasyon aracının çağırdığı fonksiyon (yalnızca service_role).
-- Yeni kayıtları ekler, var olanları günceller; yöneticinin verdiği durum
-- (ör. reddedildi) korunur. Kaynaktan kalkan gelecek etkinlikler silinir.
-- -----------------------------------------------------------------------------
create or replace function public.upsert_synced_events(p_source text, p_events jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_upserted integer;
  v_deleted  integer;
begin
  insert into public.events as ev (
    source, source_id, source_url, title, description, category, kind,
    start_at, end_at, schedule, lat, lng, venue_name, address, image_url,
    price, is_free, organizer, contact, status, created_by, synced_at
  )
  select
    p_source,
    e ->> 'source_id',
    e ->> 'source_url',
    left(e ->> 'title', 120),
    left(coalesce(e ->> 'description', ''), 2000),
    e ->> 'category',
    coalesce(e ->> 'kind', 'event'),
    (e ->> 'start_at')::timestamptz,
    (e ->> 'end_at')::timestamptz,
    e ->> 'schedule',
    (e ->> 'lat')::double precision,
    (e ->> 'lng')::double precision,
    e ->> 'venue_name',
    e ->> 'address',
    e ->> 'image_url',
    e ->> 'price',
    coalesce((e ->> 'is_free')::boolean, true),
    e ->> 'organizer',
    e ->> 'contact',
    'approved',
    null,
    now()
  from jsonb_array_elements(p_events) as e
  on conflict (source, source_id) do update set
    source_url  = excluded.source_url,
    title       = excluded.title,
    description = excluded.description,
    category    = excluded.category,
    kind        = excluded.kind,
    schedule    = excluded.schedule,
    contact     = excluded.contact,
    start_at    = excluded.start_at,
    end_at      = excluded.end_at,
    lat         = excluded.lat,
    lng         = excluded.lng,
    venue_name  = excluded.venue_name,
    address     = excluded.address,
    image_url   = excluded.image_url,
    price       = excluded.price,
    is_free     = excluded.is_free,
    organizer   = excluded.organizer,
    synced_at   = now();
  get diagnostics v_upserted = row_count;

  delete from public.events
  where source = p_source
    and coalesce(end_at, start_at) > now()
    and source_id not in (select e ->> 'source_id' from jsonb_array_elements(p_events) as e);
  get diagnostics v_deleted = row_count;

  return jsonb_build_object('upserted', v_upserted, 'deleted', v_deleted);
end;
$$;

revoke all on function public.upsert_synced_events(text, jsonb) from public, anon, authenticated;
grant execute on function public.upsert_synced_events(text, jsonb) to service_role;

-- -----------------------------------------------------------------------------
-- Realtime: uygulama yeni senkronizasyonları sayfa yenilemeden görsün.
-- -----------------------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'events'
  ) then
    alter publication supabase_realtime add table public.events;
  end if;
end;
$$;
