import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";

export interface AppelantRecherche {
  readonly id: string;
  readonly sql: SupabaseClient;
}

export async function appelantRecherche(
  requete: Request,
): Promise<AppelantRecherche | null> {
  const authorization = requete.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) return null;
  const url = Deno.env.get("SUPABASE_URL");
  const clePublique = Deno.env.get("SUPABASE_ANON_KEY");
  if (!url || !clePublique) throw new Error("configuration Supabase absente");

  const sql = createClient(url, clePublique, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false },
  });
  const { data, error } = await sql.auth.getUser();
  if (error || !data.user) return null;
  return { id: data.user.id, sql };
}
