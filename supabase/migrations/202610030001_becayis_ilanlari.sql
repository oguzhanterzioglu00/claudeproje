create table if not exists public.becayis_ilanlari (
  user_id uuid primary key references auth.users(id) on delete cascade,
  kurum_id text not null check (char_length(kurum_id) between 1 and 120),
  kurum_adi text not null check (char_length(kurum_adi) between 1 and 160),
  sinif text not null check (char_length(sinif) between 1 and 120),
  unvan text not null check (char_length(unvan) between 1 and 120),
  mevcut_il text not null check (char_length(mevcut_il) between 2 and 32),
  hedef_iller text[] not null check (cardinality(hedef_iller) between 1 and 81),
  zincir_izni boolean not null default false,
  mavi_tik boolean not null default false,
  gorunen_ad text not null check (char_length(gorunen_ad) between 1 and 80),
  aktif boolean not null default true,
  olusturma timestamptz not null default now(),
  guncelleme timestamptz not null default now()
);

alter table public.becayis_ilanlari enable row level security;
revoke all on public.becayis_ilanlari from authenticated;
grant select, delete on public.becayis_ilanlari to authenticated;
grant insert (user_id, kurum_id, kurum_adi, sinif, unvan, mevcut_il, hedef_iller, zincir_izni, gorunen_ad, aktif)
  on public.becayis_ilanlari to authenticated;
-- user_id de listede olmalı: istemci `upsert` yapar ve PostgREST, çakışmada user_id dahil tüm yük sütunlarını
-- `DO UPDATE SET` listesine koyar; Postgres her SET sütunu için UPDATE yetkisi ister (yoksa "permission denied").
-- Güvenlik: update politikasının `with check (user_id = auth.uid())` koşulu, satırın başka kullanıcıya
-- devredilmesini zaten engeller (gerçek veritabanında rollback'li testle doğrulandı).
grant update (user_id, kurum_id, kurum_adi, sinif, unvan, mevcut_il, hedef_iller, zincir_izni, gorunen_ad, aktif)
  on public.becayis_ilanlari to authenticated;

drop policy if exists "Aktif becayis ilanlari okunabilir" on public.becayis_ilanlari;
create policy "Aktif becayis ilanlari okunabilir"
on public.becayis_ilanlari for select to authenticated
using (aktif or user_id = auth.uid());

drop policy if exists "Kullanici kendi becayis ilanini ekler" on public.becayis_ilanlari;
create policy "Kullanici kendi becayis ilanini ekler"
on public.becayis_ilanlari for insert to authenticated
with check (user_id = auth.uid() and mavi_tik = false);

drop policy if exists "Kullanici kendi becayis ilanini gunceller" on public.becayis_ilanlari;
create policy "Kullanici kendi becayis ilanini gunceller"
on public.becayis_ilanlari for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "Kullanici kendi becayis ilanini siler" on public.becayis_ilanlari;
create policy "Kullanici kendi becayis ilanini siler"
on public.becayis_ilanlari for delete to authenticated
using (user_id = auth.uid());

create or replace function public.becayis_guncelleme_zamani()
returns trigger language plpgsql security invoker set search_path = '' as $$
begin
  new.guncelleme = now();
  return new;
end;
$$;

drop trigger if exists becayis_guncelleme_zamani on public.becayis_ilanlari;
create trigger becayis_guncelleme_zamani
before update on public.becayis_ilanlari
for each row execute function public.becayis_guncelleme_zamani();
