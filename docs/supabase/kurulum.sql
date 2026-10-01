-- Kamu Pusulası — Supabase kurulum betiği.
-- Supabase paneli > SQL Editor'e yapıştırıp bir kez çalıştırın. Tekrar çalıştırmak zararsızdır.

-- Hesap silme: oturum açmış kullanıcı yalnızca KENDİ hesabını silebilir (mağaza kuralları ve KVKK silme hakkı).
-- auth.users satırı silinince ona bağlı tüm veri (ileride eklenecek tablolar "on delete cascade" ile) de silinir.
create or replace function public.hesabi_sil()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if auth.uid() is null then
    raise exception 'Oturum gerekli' using errcode = '28000';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

-- Yalnızca oturum açmış kullanıcılar çağırabilir (anonim çağrı kapalı).
revoke all on function public.hesabi_sil() from public, anon;
grant execute on function public.hesabi_sil() to authenticated;
