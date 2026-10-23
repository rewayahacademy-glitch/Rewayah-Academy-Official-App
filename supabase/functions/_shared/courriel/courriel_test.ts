// deno test --allow-read supabase/functions/_shared/courriel/
import { assert, assertEquals, assertThrows } from 'jsr:@std/assert@1'
import { composer } from './gabarit.ts'
import { contenuPour, modelesConnus } from './modeles.ts'
import { htmlAuth, MODELES_AUTH } from './auth_modeles.ts'

// Les evenements de la contrainte notifications_evenement_check (etat au
// 23/10/2026) et les deux modeles propres a la file.
const EVENEMENTS = ['demande_recue', 'classe_validee', 'enseignant_affecte', 'demande_close',
  'remplacement_propose', 'remplacement_pris', 'demande_presentation', 'controle_mission_attribuee',
  'controle_mission_non_controlee', 'classe_changee', 'paiement_relance', 'acces_suspendu_paiement',
  'acces_retabli_paiement']

Deno.test('chaque evenement de notification a son modele', () => {
  for (const e of [...EVENEMENTS, 'invitation_foyer', 'lien_inscription', 'message_libre', 'nouvelles']) {
    assert(modelesConnus.includes(e), e)
  }
})

Deno.test('chaque e-mail reste leger : moins de 15 Ko, sans script ni police web', () => {
  for (const m of modelesConnus) {
    const c = contenuPour({ modele: m, categorie: 'classes', essentielle: true,
      donnees: { prenom: 'Khadija', sujet: 'S', corps: 'Corps', jours_avant: 3, invite_par: 'Amine',
                 expire_le: '2026-10-30T10:00:00Z' } })
    const { html, texte } = composer(c)
    const ko = new TextEncoder().encode(html).length / 1024
    assert(ko < 15, `${m} : ${ko.toFixed(1)} Ko`)
    assert(!/<script|@font-face|fonts\.googleapis|<link /i.test(html), m)
    assert(!/#F8F4EE|creme|crème/i.test(html), `${m} : couleur perimee`)
    assert(html.includes('/fr/assets/courriel-logo-violet.png') && html.includes('/fr/assets/courriel-ornement-violet.png'), m)
    assert(texte.length > 20 && !texte.includes('<'), `${m} : version texte`)
  }
})

Deno.test('un message de la direction est echappe, paragraphes conserves', () => {
  const c = contenuPour({ modele: 'message_libre', categorie: 'direction', essentielle: true,
    donnees: { sujet: 'Classe <b>du jeudi</b>', corps: 'Ligne 1\n<script>x</script>\n\nParagraphe 2' } })
  const { html } = composer(c)
  assert(!html.includes('<script>x'))
  assert(html.includes('&lt;b&gt;du jeudi&lt;/b&gt;'))
  assertEquals((html.match(/<p style="margin:0 0 16px;font:400 15px/g) ?? []).length, 2)
})

Deno.test('lien de desinscription seulement hors categorie essentielle', () => {
  const d = { sujet: 'S', corps: 'C', jeton_desinscription: 'abc-def_ghi' }
  assertEquals(contenuPour({ modele: 'nouvelles', categorie: 'nouvelles', essentielle: true, donnees: d }).desinscription,
    undefined)
  assertEquals(contenuPour({ modele: 'nouvelles', categorie: 'nouvelles', essentielle: false, donnees: d }).desinscription,
    'https://rewayahacademy.com/fr/courriels/desinscription?jeton=abc-def_ghi')
})

Deno.test('le lien d’un e-mail mene a l’application, jamais ailleurs', () => {
  const c = contenuPour({ modele: 'classe_validee', categorie: 'inscription', essentielle: true,
    donnees: { destination: '//evil.example/x' } })
  assert(composer(c).html.includes('https://app.rewayahacademy.com/tuteur/demandes'))
})

Deno.test('modele inconnu : refus', () => {
  assertThrows(() => contenuPour({ modele: 'inconnu', categorie: 'compte', essentielle: true, donnees: {} }))
})

Deno.test('modeles Auth : a jour et porteurs des variables Supabase', () => {
  for (const nom of Object.keys(MODELES_AUTH)) {
    const fichier = Deno.readTextFileSync(new URL(`../../../templates/${nom}.html`, import.meta.url))
    assertEquals(fichier, htmlAuth(nom) + '\n', `${nom} : relancer supabase/templates/generer.ts`)
    assert(fichier.includes(nom === 'reauthentication' ? '{{ .Token }}' : '{{ .ConfirmationURL }}'), nom)
  }
})

Deno.test('lien_inscription : date en toutes lettres, meme adresse, rien a payer, aucune reponse du formulaire', () => {
  const c = contenuPour({ modele: 'lien_inscription', categorie: 'recrutement', essentielle: true,
    donnees: { date_reponse: '2026-10-14T09:12:00Z', formulaire: 'Enseignants 2026', telephone: '+33 6 00 00 00 00' } })
  const { html, texte } = composer(c)
  assert(texte.includes('Le 14 octobre 2026, vous avez répondu à notre formulaire « Enseignants 2026 ».'))
  assert(texte.includes('même adresse e-mail') && texte.includes('Rien à payer') && texte.includes('ignorez ce message'))
  assert(texte.startsWith('Votre candidature') && texte.includes('Bonjour,'))
  assert(!html.includes('+33') && html.includes('https://app.rewayahacademy.com/inscription'))
  const sansDate = composer(contenuPour({ modele: 'lien_inscription', categorie: 'recrutement', essentielle: true,
    donnees: { prenom: 'Aïcha' } })).texte
  assert(sansDate.includes('Bonjour Aïcha,') && sansDate.includes('Vous avez répondu à notre formulaire.'))
})

// COURRIELS-2 : la langue du destinataire.
import { rendre } from './modeles.ts'
import { traduireContenu, type Traducteur } from './traduction.ts'

const fauxTraducteur: Traducteur = (textes, _source, cible) => Promise.resolve(textes.map((t) => `[${cible}] ${t}`))

Deno.test('une langue non ecrite part traduite du francais, liens intacts, note de traduction', async () => {
  const r = rendre({ modele: 'classe_validee', categorie: 'inscription', essentielle: true, donnees: { prenom: 'Awa' } }, 'ff')
  assertEquals(r.traduireDepuis, 'fr')
  const c = await traduireContenu(r.contenu, 'fr', 'ff', fauxTraducteur)
  const { html } = composer(c)
  assert(c.sujet.startsWith('[ff] ') && c.noteTraduction === '[ff] Ce message a été traduit automatiquement.')
  assert(html.includes('lang="ff"') && html.includes('https://app.rewayahacademy.com/tuteur/demandes'))
})

Deno.test('le francais ne se traduit pas ; un message de la direction part de sa langue d ecriture', () => {
  assertEquals(rendre({ modele: 'demande_recue', categorie: 'inscription', essentielle: true, donnees: {} }, 'fr').traduireDepuis, undefined)
  const r = rendre({ modele: 'message_libre', categorie: 'direction', essentielle: true,
    donnees: { sujet: 'S', corps: 'C', langue_source: 'fr' } }, 'pt')
  assertEquals(r.traduireDepuis, 'fr')
})

Deno.test('l arabe s ecrit de droite a gauche dans tout le gabarit', () => {
  const { html } = composer({ sujet: 'س', apercu: 'س', titre: 'عنوان', raison: 'سبب', langue: 'ar', droiteAGauche: true,
    blocs: [{ type: 'texte', texte: 'نص' }, { type: 'bouton', libelle: 'افتح', href: 'https://app.rewayahacademy.com/' }] })
  assert(html.includes('lang="ar" dir="rtl"') && html.includes('align="right"') && html.includes('text-align:right'))
  assert(!html.includes('&nbsp;'), 'la typographie francaise ne s applique pas a l arabe')
})

Deno.test('un passage arabe (verset, invocation) est marque pour ne jamais etre traduit', async () => {
  const { versHtml, depuisHtml } = await import('./traduction.ts')
  const h = versHtml('Récitez بِسْمِ اللَّهِ chaque jour.\n<b>', true)
  assert(h.includes('<span translate="no" class="notranslate">بِسْمِ اللَّهِ </span>'))
  assert(h.includes('&lt;b&gt;') && h.includes('<br>'))
  assertEquals(depuisHtml(h), 'Récitez بِسْمِ اللَّهِ chaque jour.\n<b>')
  assert(!versHtml('نص عربي', false).includes('notranslate'), 'vers l arabe : rien a proteger')
})
