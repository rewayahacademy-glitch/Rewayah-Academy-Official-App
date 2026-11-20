// PE-A1 et PE-A7 (lot COURRIELS-CANDIDAT, 20/11/2026) : rend en HTML les courriels du candidat enseignant de la
// file, en francais, en arabe et en anglais, avec des donnees fictives. Aucun envoi, aucun service distant.
//   deno run --allow-read --allow-write supabase/tests/courriels_candidat_rendu.ts docs/current/captures/E2E/pe-courriels-candidat
// Les courriels de Supabase Auth (lien de connexion, confirmation...) sont rendus a part, par le moteur de
// modeles Go (voir la PR) : fichiers auth_<message>_<langue>.html du meme dossier.
import { composer } from '../functions/_shared/courriel/gabarit.ts'
import { rendre } from '../functions/_shared/courriel/modeles.ts'

const dossier = Deno.args[0] ?? 'docs/current/captures/E2E/pe-courriels-candidat'
const commun = { prenom: 'Awa', jeton_desinscription: 'JETON-FICTIF' }
const cas = [
  { nom: 'retenu_entretien_sans_moment', modele: 'retenu_entretien', donnees: { ...commun, creneauxOuverts: false } },
  { nom: 'retenu_entretien_moment_ouvert', modele: 'retenu_entretien', donnees: { ...commun, creneauxOuverts: true } },
  { nom: 'entretien_creneau_ouvert', modele: 'entretien_creneau_ouvert', donnees: commun },
  { nom: 'invitation_candidat_importe', modele: 'invitation_candidat_importe',
    donnees: { jeton_desinscription: 'JETON-FICTIF', code: 'ABCD-EFGH-JKMN', expire_le: '2026-12-04T10:00:00Z', variante: 'A' } },
  { nom: 'invitation_enseignant', modele: 'invitation_enseignant',
    donnees: { code: 'ABCD-EFGH-JKMN', expire_le: '2026-12-04T10:00:00Z' } },
  { nom: 'lien_inscription', modele: 'lien_inscription',
    donnees: { ...commun, date_reponse: '2026-10-14T09:12:00Z', formulaire: 'Candidatures enseignants 2026' } },
]
const lignes: string[] = []
for (const c of cas) {
  for (const langue of ['fr', 'ar', 'en']) {
    const r = rendre({ modele: c.modele, categorie: 'recrutement', essentielle: c.modele === 'invitation_enseignant', donnees: c.donnees }, langue)
    if (r.traduireDepuis) throw new Error(`${c.nom} ${langue} : partirait traduit automatiquement`)
    const { html, texte } = composer(r.contenu)
    await Deno.writeTextFile(`${dossier}/${c.nom}_${langue}.html`, html)
    await Deno.writeTextFile(`${dossier}/${c.nom}_${langue}.txt`, `Sujet : ${r.contenu.sujet}\n\n${texte}`)
    lignes.push(`<tr><td>${c.nom}</td><td>${langue}</td><td dir="auto">${r.contenu.sujet}</td>` +
      `<td><a href="${c.nom}_${langue}.html">HTML</a> · <a href="${c.nom}_${langue}.txt">texte</a></td></tr>`)
    console.log(`${c.nom} ${langue} : ${r.contenu.sujet}`)
  }
}
await Deno.writeTextFile(`${dossier}/file.html`, '<!doctype html><meta charset="utf-8"><title>Courriels du candidat (file)</title>' +
  '<table border="1" cellpadding="4"><tr><th>Courriel</th><th>Langue</th><th>Sujet</th><th>Rendu</th></tr>' +
  lignes.join('') + '</table>\n')
