// Apple ile açılmış hesap silinirken Apple'ın jetonunu iptal eder (App Store Kural 5.1.1(v)).
//
// Akış: uygulama silmeden önce Apple'dan taze bir `authorizationCode` alır ve bu işleve gönderir.
// Biz de kodu Apple'a verip refresh_token alırız, ardından o jetonu iptal ederiz (revoke).
// Hesabın kendisi bu işlevde SİLİNMEZ; uygulama başarılı yanıttan sonra `hesabi_sil()` RPC'sini çağırır.
//
// Gerekli Supabase Secrets (`supabase secrets set ...`; .p8 içeriği asla depoya girmez):
//   APPLE_TEAM_ID      Apple Developer → Membership → Team ID
//   APPLE_KEY_ID       Sign in with Apple anahtarının Key ID'si
//   APPLE_PRIVATE_KEY  .p8 dosyasının TAM içeriği (-----BEGIN PRIVATE KEY----- satırlarıyla)
//   APPLE_BUNDLE_ID    tr.com.ayasyazilim.pusula  (yerel iOS girişinde client_id = bundle kimliği)
// SUPABASE_URL ve SUPABASE_ANON_KEY Supabase tarafından otomatik verilir.

import { createClient } from "npm:@supabase/supabase-js@2";
import { importPKCS8, SignJWT } from "npm:jose@5";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function yanit(durum: number, govde: Record<string, unknown>) {
  return new Response(JSON.stringify(govde), {
    status: durum,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

async function istemciSirri(): Promise<string> {
  const anahtar = await importPKCS8(
    // Secret'ta satır sonları "\n" metni olarak saklandıysa gerçek satır sonuna çevrilir.
    Deno.env.get("APPLE_PRIVATE_KEY")!.replace(/\\n/g, "\n"),
    "ES256",
  );
  return await new SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid: Deno.env.get("APPLE_KEY_ID")! })
    .setIssuer(Deno.env.get("APPLE_TEAM_ID")!)
    .setIssuedAt()
    .setExpirationTime("5m")
    .setAudience("https://appleid.apple.com")
    .setSubject(Deno.env.get("APPLE_BUNDLE_ID")!)
    .sign(anahtar);
}

Deno.serve(async (istek) => {
  if (istek.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (istek.method !== "POST") return yanit(405, { hata: "yalnizca_post" });

  for (const ad of ["APPLE_TEAM_ID", "APPLE_KEY_ID", "APPLE_PRIVATE_KEY", "APPLE_BUNDLE_ID"]) {
    if (!Deno.env.get(ad)) return yanit(500, { hata: "yapilandirma_eksik", ad });
  }

  // Çağıran gerçekten oturum açmış bir kullanıcı mı?
  const yetki = istek.headers.get("Authorization") ?? "";
  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: yetki } },
  });
  const { data, error } = await supabase.auth.getUser();
  if (error || !data.user) return yanit(401, { hata: "oturum_gerekli" });

  let kod: unknown;
  try {
    kod = (await istek.json()).authorizationCode;
  } catch {
    return yanit(400, { hata: "gecersiz_govde" });
  }
  if (typeof kod !== "string" || kod.length === 0) return yanit(400, { hata: "kod_gerekli" });

  try {
    const clientId = Deno.env.get("APPLE_BUNDLE_ID")!;
    const clientSecret = await istemciSirri();

    // 1) authorizationCode -> refresh_token
    const jeton = await fetch("https://appleid.apple.com/auth/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        client_id: clientId,
        client_secret: clientSecret,
        code: kod,
        grant_type: "authorization_code",
      }),
    });
    const jetonGovde = await jeton.json().catch(() => ({}));
    if (!jeton.ok || !jetonGovde.refresh_token) {
      console.error("Apple token hatası", jeton.status, jetonGovde?.error);
      return yanit(502, { hata: "apple_token_hatasi", apple: jetonGovde?.error ?? null });
    }

    // 2) refresh_token'ı iptal et
    const iptal = await fetch("https://appleid.apple.com/auth/revoke", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        client_id: clientId,
        client_secret: clientSecret,
        token: jetonGovde.refresh_token,
        token_type_hint: "refresh_token",
      }),
    });
    if (!iptal.ok) {
      console.error("Apple revoke hatası", iptal.status);
      return yanit(502, { hata: "apple_revoke_hatasi" });
    }
    return yanit(200, { tamam: true });
  } catch (e) {
    console.error("apple-hesap-sil beklenmeyen hata", e);
    return yanit(500, { hata: "beklenmeyen" });
  }
});
