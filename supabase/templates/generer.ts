// Ecrit les modeles HTML de Supabase Auth depuis le gabarit commun.
//   deno run --allow-write=supabase/templates supabase/templates/generer.ts
import { htmlAuth, MODELES_AUTH } from '../functions/_shared/courriel/auth_modeles.ts'

for (const nom of Object.keys(MODELES_AUTH)) {
  Deno.writeTextFileSync(`supabase/templates/${nom}.html`, htmlAuth(nom) + '\n')
}
