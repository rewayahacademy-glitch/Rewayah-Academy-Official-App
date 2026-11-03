// COURRIELS-UX (03/11/2026) : rend en HTML deux modeles d'e-mail (eleve_inscrit
// pour la famille, seance_annulee), en francais et en arabe, avec les donnees
// que pose private.notifier_classe (migration 20261108100000). Aucun envoi.
//   deno run --allow-read --allow-write tool/e2e/courriels_ux_rendu.ts <dossier>
import { composer } from '../../supabase/functions/_shared/courriel/gabarit.ts'
import { rendre } from '../../supabase/functions/_shared/courriel/modeles.ts'

const dossier = Deno.args[0] ?? 'docs/current/captures/E2E/courriels-ux'
const commun = { prenom: 'Samira', portee: 'foyer', eleves: ['Lina', 'Yanis'], classe: 'Les bases, lundi 18 h',
  fuseau: 'America/Toronto', groupe_id: 'c0e10000-0000-4000-8000-000000000201',
  destination: '/tuteur/classes/c0e10000-0000-4000-8000-000000000201', jeton_desinscription: 'exemple' }
const cas = [
  { modele: 'eleve_inscrit', donnees: { ...commun, eleves: ['Lina'], prochaine_local: '2026-11-09T12:00:00' } },
  { modele: 'seance_annulee', donnees: { ...commun, debut_local: '2026-11-16T12:00:00',
    destination: '/tuteur/classes/c0e10000-0000-4000-8000-000000000201/planning' } },
]
for (const langue of ['fr', 'ar']) {
  for (const c of cas) {
    const { html, texte } = composer(rendre({ modele: c.modele, categorie: 'classes', essentielle: false, donnees: c.donnees }, langue).contenu)
    await Deno.writeTextFile(`${dossier}/${c.modele}_${langue}.html`, html)
    await Deno.writeTextFile(`${dossier}/${c.modele}_${langue}.txt`, texte)
    console.log(`${c.modele} ${langue}\n${texte}\n`)
  }
}
