// Ecrit les modeles HTML de Supabase Auth depuis le gabarit commun, et leurs
// sujets (un par ligne, a coller dans le tableau de bord : PE-A1, 20/11/2026).
//   deno run --allow-write=supabase/templates supabase/templates/generer.ts
import { htmlAuth, MODELES_AUTH, sujetsAuthTexte } from '../functions/_shared/courriel/auth_modeles.ts'

for (const nom of Object.keys(MODELES_AUTH)) {
  Deno.writeTextFileSync(`supabase/templates/${nom}.html`, htmlAuth(nom) + '\n')
}
Deno.writeTextFileSync('supabase/templates/sujets.txt', sujetsAuthTexte())
