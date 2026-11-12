-- =============================================================================
-- Mahallem — kişiselleştirme tercihleri
-- Kayıt sırasında sorulan kısa soruların yanıtları (zaman, bütçe, bölge...).
-- =============================================================================

alter table public.profiles
  add column if not exists prefs jsonb not null default '{}'::jsonb;

-- Kullanıcı kendi tercihlerini güncelleyebilsin (rol hâlâ güncellenemez).
grant update (display_name, interests, onboarded, prefs) on public.profiles to authenticated;
