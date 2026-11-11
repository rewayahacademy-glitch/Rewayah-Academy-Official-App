// Banc de la salle : le passage de la tache planifiee de FERMETURE-SALLE
// (journal D-018), lance a la main sur la pile LOCALE.
//
// En production, `observation-coupure` fait ce passage a chaque appel de la
// tache planifiee, derriere son secret partage ; au 11/11/2026 cette tache ne
// l'appelle que lorsqu'un tuteur observe une seance (lot FERMETURE-CRON a
// venir). La pile locale n'a pas ce secret : ce script execute le
// MEME code (`sallesASurveiller` puis `surveillerSalles`, les deux fonctions
// que la fonction Edge appelle), contre la base locale et le LiveKit local.
// Seule la porte HTTP de la fonction n'est pas essayee ici.
//
// Le passage est restreint a la salle donnee en argument : d'autres bancs
// tournent sur la meme pile, on ne touche pas a leurs salles.
//
//   deno run -A tool/salle/fermeture_passage.ts <nom de la salle LiveKit>
//
// Variables attendues (posees par `fermeture.mjs`) : SUPABASE_URL,
// SUPABASE_SERVICE_ROLE_KEY, LIVEKIT_CLOUD_API_KEY, LIVEKIT_CLOUD_API_SECRET.
import { createClient } from 'jsr:@supabase/supabase-js@2'
import { surveillerSalles } from '../../supabase/functions/_shared/livekit.ts'
import { sallesASurveiller } from '../../supabase/functions/_shared/seance_salle.ts'

const salle = Deno.args[0]
const url = Deno.env.get('SUPABASE_URL') ?? ''
if (!salle || !/^http:\/\/127\.0\.0\.1:/.test(url)) {
  console.error('refus : salle non donnee, ou pile non locale')
  Deno.exit(2)
}
const db = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '', {
  auth: { persistSession: false },
})
const toutes = await sallesASurveiller(db)
const lasalle = toutes.filter((s) => s.room_name === salle)
const bilan = await surveillerSalles(lasalle)
console.log(JSON.stringify({ connues: toutes.length, retenues: lasalle.length, ...bilan }))
