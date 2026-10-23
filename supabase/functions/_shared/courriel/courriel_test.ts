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
  for (const e of [...EVENEMENTS, 'invitation_foyer', 'message_libre', 'nouvelles']) {
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
