// deno test --allow-read supabase/functions/_shared/courriel/
import { assert, assertEquals, assertThrows } from 'jsr:@std/assert@1'
import { composer } from './gabarit.ts'
import { contenuPour, modelesConnus } from './modeles.ts'
import { htmlAuth, LANGUES_AUTH, MODELES_AUTH, MODELES_AUTH_LANGUES } from './auth_modeles.ts'
import { FRANCAIS, LANGUES } from './modeles.ts'
import { TRADUITS_A_L_ENVOI } from './modeles_fr.ts'
import { VILLES_FUSEAU_AR, VILLES_FUSEAU_FR, villeDuFuseau } from './villes_fuseau.ts'

// Les evenements de la contrainte notifications_evenement_check (etat au
// 27/10/2026 : les treize du 23/10 et les neuf de la fiche « Fraicheur et
// notifications », migration 20261027120000) et les modeles propres a la file.
const EVENEMENTS = ['demande_recue', 'classe_validee', 'enseignant_affecte', 'tout_est_pret', 'demande_close',
  'remplacement_propose', 'remplacement_pris', 'demande_presentation', 'controle_mission_attribuee',
  'controle_mission_non_controlee', 'classe_changee', 'paiement_relance', 'acces_suspendu_paiement',
  'acces_retabli_paiement',
  'classe_creee', 'enseignant_change', 'eleve_inscrit', 'eleve_retire', 'creneau_change',
  'seance_annulee', 'seance_deplacee', 'enseignante_absente', 'classe_supprimee',
  // A3 (31/10/2026, migration 20261102500000).
  'remplacement_avertissement', 'remplacement_pre_alerte', 'remplacement_inutile',
  'titulaire_en_retard', 'remplacant_arrive',
  // Parcours 7 (03/11/2026, migration 20261103400000).
  'paiement_recu',
  // FN-115b (02/11/2026, migration 20261104300000).
  'remboursement_effectue', 'litige_ouvert', 'litige_clos',
  // SNT (03/11/2026, migration 20261106500001).
  'seance_reportee']

Deno.test('paiement recu : le montant est ecrit dans la devise de la commande, ou tu quand il manque', () => {
  const avec = contenuPour({ modele: 'paiement_recu', categorie: 'facturation', essentielle: true,
    donnees: { prenom: 'Amina', montant_mineur: 16500, devise: 'USD' } })
  const texte = avec.blocs.map((b) => b.type === 'texte' ? b.texte : '').join(' ')
  assert(/165,00/.test(texte) && /\$/.test(texte), texte)
  assert(!/confirmé/i.test(texte), texte)
  const anglais = contenuPour({ modele: 'paiement_recu', categorie: 'facturation', essentielle: true,
    donnees: { montant_mineur: 16500, devise: 'USD' } }, 'en')
  assert(anglais.blocs.some((b) => b.type === 'texte' && b.texte.includes('$165.00')), JSON.stringify(anglais.blocs))
  for (const donnees of [{}, { montant_mineur: 'abc', devise: 'USD' }, { montant_mineur: 100, devise: 'nope' }]) {
    const sans = contenuPour({ modele: 'paiement_recu', categorie: 'facturation', essentielle: true, donnees })
    assert(sans.blocs.some((b) => b.type === 'texte' && b.texte.startsWith('Le paiement est reçu.')), JSON.stringify(donnees))
  }
})

Deno.test('chaque evenement de notification a son modele', () => {
  for (const e of [...EVENEMENTS, 'invitation_foyer', 'lien_inscription', 'attente_candidat', 'admission_recue',
    'admission_acceptee', 'admission_refusee', 'admission_precisions', 'compte_enseignant_valide', 'retenu_entretien',
    'invitation_enseignant', 'invitation_famille_importee', 'invitation_candidat_importe', 'message_libre', 'nouvelles',
    'message_candidat_recu']) {
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
    // Une lettre personnelle (pilote, 25/10/2026) n'a aucune image ; les
    // autres portent le logo et l'ornement.
    if (c.lettre === true) assert(!/<img/i.test(html), `${m} : lettre sans image`)
    else assert(html.includes('/fr/assets/courriel-logo-violet.png') && html.includes('/fr/assets/courriel-ornement-violet.png'), m)
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
  assert(composer(c).html.includes('https://app.rewayahacademy.com/#/tuteur/demandes'))
})

Deno.test('modele inconnu : refus', () => {
  assertThrows(() => contenuPour({ modele: 'inconnu', categorie: 'compte', essentielle: true, donnees: {} }))
})

Deno.test('modeles Auth : a jour et porteurs des variables Supabase', () => {
  for (const nom of Object.keys(MODELES_AUTH)) {
    const fichier = Deno.readTextFileSync(new URL(`../../../templates/${nom}.html`, import.meta.url))
    assertEquals(fichier, htmlAuth(nom) + '\n', `${nom} : relancer supabase/templates/generer.ts`)
    assert(fichier.includes(nom === 'reauthentication' ? '{{ .Token }}' : '{{ .ConfirmationURL }}'), nom)
    // Une branche par langue ecrite, le francais en repli, fichier raisonnable.
    for (const l of LANGUES_AUTH) assert(fichier.includes(`eq $l "${l}"`) && fichier.includes(`lang="${l}"`), `${nom} ${l}`)
    assert(fichier.includes('{{ else }}<!doctype html><html lang="fr"') && fichier.endsWith('{{ end }}\n'), nom)
    assert(fichier.includes('<html lang="ar" dir="rtl">'), `${nom} : arabe de droite a gauche`)
    assert(new TextEncoder().encode(fichier).length < 25 * 1024, `${nom} : trop gros`)
    // Les balises Go sont equilibrees : autant de if que de end.
    assertEquals((fichier.match(/\{\{ if /g) ?? []).length, (fichier.match(/\{\{ end \}\}/g) ?? []).length, nom)
  }
})

Deno.test('modeles Auth : chaque langue a les six messages, sans francais restant', () => {
  for (const l of LANGUES_AUTH) {
    assertEquals(Object.keys(MODELES_AUTH_LANGUES[l]).sort(), Object.keys(MODELES_AUTH).sort(), l)
    for (const [nom, c] of Object.entries(MODELES_AUTH_LANGUES[l])) {
      const { html, texte } = composer(c)
      assert(html.includes(`lang="${l}"`) && html.includes(l === 'ar' ? 'dir="rtl"' : 'dir="ltr"'), `${nom} ${l}`)
      assert(texte.includes(nom === 'reauthentication' ? '{{ .Token }}' : '{{ .ConfirmationURL }}'), `${nom} ${l}`)
      if (l !== 'ar') assert(!/Bonjour|Vous recevez|Copiez|valable/.test(texte), `${nom} ${l} : du francais reste`)
    }
  }
})

Deno.test('lien_inscription : date en toutes lettres, meme adresse, rien a payer, aucune reponse du formulaire', () => {
  const c = contenuPour({ modele: 'lien_inscription', categorie: 'recrutement', essentielle: true,
    donnees: { date_reponse: '2026-10-14T09:12:00Z', formulaire: 'Enseignants 2026', telephone: '+33 6 00 00 00 00' } })
  const { html, texte } = composer(c)
  assert(texte.includes('Le 14 octobre 2026, vous avez répondu à notre formulaire « Enseignants 2026 ».'))
  assert(texte.includes('même adresse e-mail') && texte.includes('Rien à payer') && texte.includes('ignorez ce message'))
  assert(texte.startsWith('Votre candidature') && texte.includes('Bonjour,'))
  // CAND-04 (06/11/2026) : le lien direct du candidat, sans l'entree des
  // familles ; meme lien dans les cinq langues.
  assert(!html.includes('+33') && html.includes('https://app.rewayahacademy.com/#/connexion?mode=creer&amp;candidature=1'))
  for (const langue of ['fr', 'ar', 'en', 'es', 'pt']) {
    const h = composer(contenuPour({ modele: 'lien_inscription', categorie: 'recrutement', essentielle: true,
      donnees: {} }, langue)).html
    assert(h.includes('https://app.rewayahacademy.com/#/connexion?mode=creer&amp;candidature=1'), langue)
  }
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
  assert(html.includes('lang="ff"') && html.includes('https://app.rewayahacademy.com/#/tuteur/demandes'))
})

// SALLE-1 (07/11/2026, double lecture du garde-cap) : retenu_entretien n'est
// ecrit qu'en francais et en arabe. Vers l'anglais, l'espagnol et le
// portugais, il part du francais, traduit a l'envoi : jamais vide, jamais en
// erreur de modele ; si la traduction echoue, rien ne part (rejoue plus tard),
// jamais un courriel vide ni dans une autre langue.
Deno.test('retenu_entretien vers en, es, pt : le francais traduit a l envoi, jamais vide', async () => {
  const ligne = { modele: 'retenu_entretien', categorie: 'recrutement', essentielle: false,
    donnees: { prenom: 'Awa', jeton_desinscription: 'abc' } }
  const fr = composer(rendre(ligne, 'fr').contenu)
  assert(fr.texte.includes('Choisissez dans l’application le créneau qui vous convient.'), fr.texte)
  for (const cible of ['en', 'es', 'pt']) {
    const r = rendre(ligne, cible)
    assertEquals(r.traduireDepuis, 'fr', cible)
    assertEquals(r.contenu.langue, 'fr', cible)
    assert(r.contenu.sujet.length > 0 && r.contenu.blocs.length > 0, `${cible} : vide`)
    const c = await traduireContenu(r.contenu, 'fr', cible, fauxTraducteur)
    const { html, texte } = composer(c)
    assert(c.sujet === `[${cible}] Votre candidature est retenue pour un entretien`, `${cible} : ${c.sujet}`)
    assert(texte.includes(`[${cible}] La direction a lu votre candidature`), `${cible} : corps`)
    assert(html.includes(`lang="${cible}"`) && html.includes('https://app.rewayahacademy.com/#/attente'), `${cible} : lien`)
    let echec = false
    try {
      await traduireContenu(r.contenu, 'fr', cible, () => Promise.reject(new Error('traduction indisponible')))
    } catch (_) {
      echec = true
    }
    assert(echec, `${cible} : un echec de traduction remonte (rien ne part)`)
  }
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

// Langues ecrites a la main (en, ar, es, pt).
const ECRITES = ['fr', 'en', 'ar', 'es', 'pt']
const CATEGORIES = Object.keys(FRANCAIS.raisons)
const DONNEES = { prenom: 'Khadija', sujet: 'S', corps: 'Corps', jours_avant: 3, invite_par: 'Amine',
  expire_le: '2026-10-30T10:00:00Z', date_reponse: '2026-10-14T09:12:00Z', formulaire: 'Enseignants 2026' }

Deno.test('chaque langue ecrite a tous les modeles et toutes les raisons', () => {
  for (const l of ECRITES) {
    const L = LANGUES[l]
    assert(L, l)
    for (const m of modelesConnus) {
      // Traduit a l'envoi vers les langues qui ne l'ecrivent pas : verifie plus bas.
      if (l !== 'fr' && l !== 'ar' && TRADUITS_A_L_ENVOI.includes(m)) continue
      assert(typeof L.modeles[m] === 'function', `${l} : modele ${m}`)
    }
    for (const c of CATEGORIES) assert(L.raisons[c] && L.raisons[c].length > 20, `${l} : raison ${c}`)
    assert(L.desinscription.length > 5, l)
    assertEquals(L.droiteAGauche === true, l === 'ar', l)
  }
})

Deno.test('chaque modele dans chaque langue : leger, bonne langue, bonne direction, memes liens', () => {
  for (const l of ECRITES) {
    for (const m of modelesConnus) {
      const base = { modele: m, categorie: 'classes', essentielle: false, donnees: { ...DONNEES, jeton_desinscription: 'abc', langue_source: l } }
      const r = rendre(base, l)
      if (l !== 'fr' && l !== 'ar' && TRADUITS_A_L_ENVOI.includes(m)) {
        assertEquals(r.traduireDepuis, 'fr', `${l} ${m} : traduit a l envoi`)
        continue
      }
      assertEquals(r.traduireDepuis, undefined, `${l} ${m}`)
      const { html, texte } = composer(r.contenu)
      assert(new TextEncoder().encode(html).length / 1024 < 15, `${l} ${m} : trop gros`)
      assert(html.includes(`<html lang="${l}" dir="${l === 'ar' ? 'rtl' : 'ltr'}">`), `${l} ${m}`)
      assert(html.includes(l === 'ar' ? 'text-align:right' : 'text-align:left'), `${l} ${m}`)
      assert(html.includes(LANGUES[l].desinscription), `${l} ${m} : desinscription`)
      // Les liens sont ceux du francais.
      const liens = (h: string) => [...h.matchAll(/href="([^"]+)"/g)].map((x) => x[1]).sort()
      assertEquals(liens(html), liens(composer(rendre(base, 'fr').contenu).html), `${l} ${m} : liens`)
      if (l === 'en' || l === 'es' || l === 'pt') {
        assert(!/Bonjour|Vous recevez|Ne plus recevoir|l’application|votre /.test(texte + html), `${l} ${m} : du francais reste`)
      }
    }
  }
})

Deno.test('jours_avant, dates et message libre suivent la langue', () => {
  const j = (l: string, n: number) => composer(rendre({ modele: 'paiement_relance', categorie: 'facturation',
    essentielle: true, donnees: { jours_avant: n } }, l).contenu).texte
  assert(j('en', 3).includes('in 3 days') && j('en', 1).includes('tomorrow'))
  assert(j('es', 0).includes('hoy') && j('pt', 3).includes('dentro de 3 dias') && j('ar', 0).includes('اليوم'))
  const ins = (l: string) => composer(rendre({ modele: 'lien_inscription', categorie: 'recrutement', essentielle: true,
    donnees: DONNEES }, l).contenu).texte
  assert(ins('en').includes('14 October 2026') && ins('es').includes('14 de octubre de 2026')
    && ins('pt').includes('14 de outubro de 2026') && ins('ar').includes('14') && !/[٠-٩]/.test(ins('ar')))
  const libre = rendre({ modele: 'nouvelles', categorie: 'nouvelles', essentielle: true,
    donnees: { sujet: 'Hi', corps: 'A\n\nB', langue_source: 'en' } }, 'en')
  assertEquals(libre.traduireDepuis, undefined)
  assertEquals(libre.contenu.langue, 'en')
  assertEquals(libre.contenu.blocs.length, 2)
})

Deno.test('langue non ecrite : traduite du francais ; francais inchange', () => {
  const l = { modele: 'classe_validee', categorie: 'inscription', essentielle: true, donnees: { prenom: 'Awa' } }
  assertEquals(rendre(l, 'ff').traduireDepuis, 'fr')
  assertEquals(rendre(l, 'en').traduireDepuis, undefined)
  const fr = rendre(l, 'fr').contenu
  assertEquals(fr.sujet, 'Votre classe est prête')
  assertEquals(fr.blocs[0], { type: 'texte', texte: 'Bonjour Awa,' })
  assertEquals(fr.blocs[3], { type: 'note', texte: 'Le détail se trouve dans l’application, une fois connecté.' })
  assertEquals(fr.raison, 'Vous recevez cet e-mail parce qu’il concerne une demande faite sur Rewayah Academy.')
})

// B3.1 : le courriel d'attente des candidats, texte du directeur mot pour mot,
// ecrit en francais seul et traduit a l'envoi.
const ATTENTE = { modele: 'attente_candidat', categorie: 'recrutement', essentielle: false,
  donnees: { jeton_desinscription: 'jeton-1' } }

Deno.test('attente_candidat : le texte valide par le directeur, mot pour mot', async () => {
  const doc = await Deno.readTextFile(new URL('../../../../docs/current/CANDIDATURES/COURRIEL_ATTENTE_2026-10-24.md', import.meta.url))
  const section = (titre: string) => doc.split(`## ${titre}`)[1].split('\n## ')[0]
  const norme = (t: string) => t.replace(/[’']/g, "'").replace(/\s+/g, ' ').trim()
  const c = rendre(ATTENTE, 'fr').contenu
  assertEquals(c.sujet, norme(section('Objet')))
  const corps = c.blocs.map((b) => (b.type === 'texte' ? b.texte : '')).join('\n\n')
  assertEquals(norme(corps), norme(section('Corps (texte source, français)')))
  const { html, texte } = composer(c)
  assert(texte.includes('rien à payer') && texte.includes('Assalamou alaykoum wa rahmatoullah,'))
  assert(!/<script|@font-face/i.test(html) && new TextEncoder().encode(html).length / 1024 < 15)
  // Non essentiel : desinscription en un clic, raison du recrutement.
  assert(html.includes('/fr/courriels/desinscription?jeton=jeton-1'))
  assertEquals(c.raison, FRANCAIS.raisons.recrutement)
  // Aucun bouton : rien a faire aujourd'hui.
  assert(!c.blocs.some((b) => b.type === 'bouton'))
})

Deno.test('attente_candidat : rendu en anglais et en peul par le faux traducteur, une langue par message', async () => {
  for (const cible of ['en', 'ff']) {
    const r = rendre(ATTENTE, cible)
    assertEquals(r.traduireDepuis, 'fr', cible)
    const envoyes: string[][] = []
    // Comme le vrai : les passages en ecriture arabe sont proteges sauf vers l'arabe.
    const capture: Traducteur = async (textes, source, vers) => {
      const { versHtml, depuisHtml } = await import('./traduction.ts')
      envoyes.push(textes)
      assertEquals(source, 'fr')
      return textes.map((t) => `[${vers}] ${depuisHtml(versHtml(t, vers !== 'ar'))}`)
    }
    const c = await traduireContenu(r.contenu, 'fr', cible, capture)
    assertEquals(envoyes.length, 1, `${cible} : un seul appel`)
    assert(c.sujet.startsWith(`[${cible}] Votre candidature`), cible)
    assert(c.blocs.every((b) => b.type !== 'texte' || b.texte.startsWith(`[${cible}] `)), cible)
    assertEquals(c.noteTraduction, `[${cible}] Ce message a été traduit automatiquement.`)
    const { html } = composer({ ...c, droiteAGauche: cible === 'ar' })
    assert(html.includes(`lang="${cible}" dir="${cible === 'ar' ? 'rtl' : 'ltr'}"`), cible)
    assert(html.includes('/fr/courriels/desinscription?jeton=jeton-1'), `${cible} : desinscription`)
  }
  const { versHtml } = await import('./traduction.ts')
  // Un passage arabe dans un texte traduit vers l'anglais n'est jamais traduit.
  assert(versHtml('Qu’Allah vous récompense, جزاكم الله خيرا.', true).includes('<span translate="no" class="notranslate">جزاكم الله خيرا</span>'))
})

Deno.test('le nom de la marque n est jamais traduit, vers aucune langue', async () => {
  const { versHtml, depuisHtml } = await import('./traduction.ts')
  // Faux traducteur : transforme tout ce qui n'est pas protege par translate="no".
  const brouiller = (h: string) => h.split(/(<span translate="no" class="notranslate">.*?<\/span>)/s)
    .map((x) => (x.startsWith('<span translate="no"') ? x : x.toUpperCase().replace(/REWAYAH/g, 'روايا')))
    .join('')
  for (const arabeProtege of [true, false]) {
    const sortie = depuisHtml(brouiller(versHtml('Enseigner à Rewayah Academy, dans l’application Rewayah.', arabeProtege)))
    assertEquals(sortie, 'ENSEIGNER À Rewayah Academy, DANS L’APPLICATION Rewayah.', `arabe protege : ${arabeProtege}`)
  }
  // Le sujet du courriel d'attente traduit garde le nom en latin.
  const r = rendre({ ...ATTENTE }, 'en')
  const c = await traduireContenu(r.contenu, 'fr', 'en', async (textes, _s, vers) =>
    textes.map((t) => depuisHtml(brouiller(versHtml(t, vers !== 'ar')))))
  assert(c.sujet.includes('Rewayah Academy') && !c.sujet.includes('روايا'), c.sujet)
})

Deno.test('attente_candidat en arabe : ecrit a la main, jamais traduit, de droite a gauche', () => {
  const r = rendre(ATTENTE, 'ar')
  assertEquals(r.traduireDepuis, undefined)
  const c = r.contenu
  assertEquals(c.langue, 'ar')
  assertEquals(c.droiteAGauche, true)
  assertEquals(c.sujet, 'ترشحكم للتدريس في أكاديمية الرواية: ما وصلنا إليه')
  assertEquals(c.noteTraduction, undefined)
  const { html, texte } = composer(c)
  assert(html.includes('<html lang="ar" dir="rtl">'))
  assert(!texte.includes('traduit automatiquement') && !html.includes('traduit automatiquement'))
  assert(texte.includes('السلام عليكم ورحمة الله،') && texte.includes('طلبكم') && texte.includes('رسوم تدريب'))
  // Aucun mot francais ; dans le corps, le nom ecrit selon M-27, jamais une
  // autre forme (le pied commun du gabarit, hors de ce modele, reste en latin).
  const corps = c.sujet + c.blocs.map((b) => (b.type === 'texte' ? b.texte : '')).join('\n')
  assert(!/Bonjour|Vous |votre |Assalamou/.test(texte), texte)
  assert(!corps.includes('Rewayah Academy'), corps)
  assert(!/روايا|روية|أكاديمية رواية/.test(texte))
  assert(texte.includes('الإدارة\nأكاديمية الرواية') && texte.includes('تطبيق Rewayah'))
  assert(html.includes('/fr/courriels/desinscription?jeton=jeton-1'))
  assert(!c.blocs.some((b) => b.type === 'bouton'))
  // Meme forme que le francais : memes blocs, meme liste en trois points.
  const fr = rendre(ATTENTE, 'fr').contenu
  assertEquals(c.blocs.length, fr.blocs.length)
  assertEquals((c.blocs[4] as { texte: string }).texte.split('\n').length, 3)
})

// Pilote, 25/10/2026 : la copie de test du courriel d'attente arrivait dans
// « Promotions » de Gmail (logo, ornement, carte, en-tetes de liste). Le
// courriel d'attente part en lettre personnelle.
Deno.test('lettre personnelle : attente_candidat sans image ni en-tete de liste, lien de desinscription en corps', async () => {
  const { entetes, lienUnClic } = await import('./entetes.ts')
  for (const langue of ['fr', 'ar']) {
    const c = rendre(ATTENTE, langue).contenu
    assertEquals(c.lettre, true, langue)
    const { html, texte } = composer(c)
    assert(!/<img/i.test(html), `${langue} : aucune image`)
    assert(!/border-radius|border:1px/.test(html), `${langue} : ni carte ni bordure`)
    assert(!/<h1/i.test(html), `${langue} : pas de titre`)
    assert(html.includes('background:#FFFFFF'), `${langue} : fond blanc`)
    assert(html.includes('Rewayah Academy · rewayahacademy.com'), `${langue} : pied en une ligne`)
    assert(html.includes('/fr/courriels/desinscription?jeton=jeton-1'), `${langue} : lien en corps`)
    assert(texte.includes('/fr/courriels/desinscription?jeton=jeton-1'), `${langue} : lien dans le texte brut`)
    assert(html.includes(`dir="${langue === 'ar' ? 'rtl' : 'ltr'}"`), langue)
    // Aucun en-tete de liste a l'envoi.
    const lien = lienUnClic({ lettre: c.lettre, essentielle: false, jeton: 'jeton-1', base: 'https://x/fn' })
    assertEquals(lien, undefined, langue)
    const h = entetes({ de: 'a@b', deNom: 'A', repondreA: 'a@b', a: 'c@d', sujet: c.sujet, html, texte,
      idMessage: 'id-1', desinscriptionUnClic: lien })
    assert(!('List-Unsubscribe' in h) && !('List-Unsubscribe-Post' in h), `${langue} : en-tetes`)
    assert(!Object.keys(h).some((k) => /^List-/i.test(k)), `${langue} : aucun en-tete de liste`)
  }
  // Le texte arabe ecrit a la main est inchange.
  const ar = rendre(ATTENTE, 'ar').contenu
  assertEquals(ar.sujet, 'ترشحكم للتدريس في أكاديمية الرواية: ما وصلنا إليه')
  assert(composer(ar).texte.includes('الإدارة\nأكاديمية الرواية'))
})

Deno.test('lettre personnelle : traduite a l envoi, elle reste une lettre', async () => {
  const r = rendre(ATTENTE, 'en')
  const c = await traduireContenu(r.contenu, 'fr', 'en', (t) => Promise.resolve(t))
  assertEquals(c.lettre, true)
  assert(!/<img/i.test(composer(c).html))
})

Deno.test('les autres modeles gardent le gabarit de marque et leurs en-tetes de liste', async () => {
  const { entetes, lienUnClic } = await import('./entetes.ts')
  const c = rendre({ modele: 'classe_validee', categorie: 'inscription', essentielle: false,
    donnees: { prenom: 'Awa', jeton_desinscription: 'j2' } }, 'fr').contenu
  assertEquals(c.lettre, undefined)
  const { html } = composer(c)
  assert(html.includes('courriel-logo-violet.png') && html.includes('courriel-ornement-violet.png'))
  const lien = lienUnClic({ lettre: c.lettre, essentielle: false, jeton: 'j2', base: 'https://x/fn' })
  assertEquals(lien, 'https://x/fn?jeton=j2')
  const h = entetes({ de: 'a@b', deNom: 'A', repondreA: 'a@b', a: 'c@d', sujet: c.sujet, html, texte: '',
    idMessage: 'id-2', desinscriptionUnClic: lien })
  assertEquals(h['List-Unsubscribe'], '<https://x/fn?jeton=j2>')
  assertEquals(h['List-Unsubscribe-Post'], 'List-Unsubscribe=One-Click')
  // Essentiel : jamais de lien en un clic.
  assertEquals(lienUnClic({ essentielle: true, jeton: 'j2', base: 'https://x/fn' }), undefined)
})

Deno.test('FN-115b : remboursement et contestation, montants et frais dans la devise, issue dite', () => {
  const texte = (m: string, donnees: Record<string, unknown>, langue?: string) =>
    contenuPour({ modele: m, categorie: 'facturation', essentielle: true, donnees }, langue as never)
      .blocs.map((b) => b.type === 'texte' ? b.texte : '').join(' ')
  assert(/30,00/.test(texte('remboursement_effectue', { montant_mineur: 3000, devise: 'USD' })))
  assert(/suspendu/.test(texte('litige_ouvert', { montant_mineur: 5500, devise: 'USD' })))
  const perdu = texte('litige_clos', { issue: 'perdu', frais_mineur: 1500, devise: 'USD' })
  assert(/15,00/.test(perdu) && /solde du foyer/.test(perdu), perdu)
  const gagne = texte('litige_clos', { issue: 'gagne', devise: 'USD' })
  assert(/raison à l’académie/.test(gagne) && !/frais/.test(gagne), gagne)
  assert(/\$15\.00/.test(texte('litige_clos', { issue: 'perdu', frais_mineur: 1500, devise: 'USD' }, 'en')))
  for (const l of ['en', 'es', 'pt', 'ar']) {
    for (const m of ['remboursement_effectue', 'litige_ouvert', 'litige_clos']) {
      assert(texte(m, { montant_mineur: 100, devise: 'USD', issue: 'perdu' }, l).length > 20, `${m} ${l}`)
    }
  }
})

// I1 (02/11/2026) : l'invitation d'un enseignant et celle d'une famille importee.
Deno.test('invitation_enseignant : code, lien qui garde invitation=1 et le code, echeance', () => {
  const c = contenuPour({ modele: 'invitation_enseignant', categorie: 'recrutement', essentielle: true,
    donnees: { code: 'ABCD-EFGH-JKMN', expire_le: '2026-11-16T10:00:00Z' } })
  const { html, texte } = composer(c)
  assert(texte.includes('ABCD-EFGH-JKMN'), texte)
  assert(html.includes('https://app.rewayahacademy.com/#/connexion?mode=creer&amp;invitation=1&amp;code=ABCD-EFGH-JKMN')
    || html.includes('https://app.rewayahacademy.com/#/connexion?mode=creer&invitation=1&code=ABCD-EFGH-JKMN'), html)
  assert(texte.includes('16 novembre 2026') && texte.includes('ne sert qu’une fois') && texte.includes('Rien à payer'), texte)
  assert(!/envoyé automatiquement/.test(texte), texte)
  // Un code mal forme n'entre ni dans le texte ni dans le lien.
  const mauvais = composer(contenuPour({ modele: 'invitation_enseignant', categorie: 'recrutement', essentielle: true,
    donnees: { code: '"><script>' } }))
  assert(!mauvais.html.includes('<script>') && !mauvais.html.includes('code=%22'), mauvais.html)
  assert(mauvais.html.includes('invitation=1'), mauvais.html)
})

Deno.test('invitation_famille_importee : connexion avec la meme adresse, aucune donnee de la famille', () => {
  const c = contenuPour({ modele: 'invitation_famille_importee', categorie: 'inscription', essentielle: true,
    donnees: {} })
  const { html, texte } = composer(c)
  assert(html.includes('https://app.rewayahacademy.com/#/connexion'), html)
  assert(texte.includes('cette adresse e-mail') && texte.includes('sans rien ressaisir'), texte)
  assert(texte.includes('Bonjour,'), texte)
})

// COURRIELS-UX (UX-026, FN-108, 03/11/2026) : ce que pose notifier_classe
// (migration 20261108100000) arrive dans le texte de chaque langue.
const CLASSE_UX = { classe: 'Les bases, lundi 18 h', fuseau: 'Europe/Paris',
  debut_local: '2026-11-22T10:00:00', prochaine_local: '2026-11-09T18:00:00' }
// UX-030 : la ville du fuseau, la meme que dans l'application.
const ZONE: Record<string, string> = {
  fr: 'heure de Paris', en: 'Paris time', ar: 'بتوقيت باريس', es: 'hora de Paris', pt: 'hora de Paris' }
const ux = (modele: string, langue: string, donnees: Record<string, unknown>) =>
  composer(rendre({ modele, categorie: 'classes', essentielle: false, donnees: { prenom: 'Samira', ...CLASSE_UX, ...donnees } }, langue).contenu)

Deno.test('UX-026 : chaque avis de classe nomme la classe, l enfant et l heure avec son fuseau, dans les cinq langues', () => {
  for (const l of ECRITES) {
    const foyer = { portee: 'foyer', eleves: ['Lina', 'Yanis'] }
    for (const m of ['classe_creee', 'eleve_inscrit', 'seance_annulee', 'classe_supprimee']) {
      const { texte } = ux(m, l, foyer)
      assert(texte.includes('Les bases, lundi 18 h'), `${l} ${m} : classe\n${texte}`)
      assert(texte.includes('Lina') && texte.includes('Yanis'), `${l} ${m} : enfants\n${texte}`)
    }
    // L'heure est dite avec le nom de son fuseau, dans la langue.
    assert(ux('seance_annulee', l, foyer).texte.includes(`10:00 (${ZONE[l]})`), `${l} : seance annulee, fuseau`)
    assert(ux('classe_creee', l, foyer).texte.includes(`18:00 (${ZONE[l]})`), `${l} : classe creee, premiere seance`)
    assert(ux('eleve_inscrit', l, foyer).texte.includes(`18:00 (${ZONE[l]})`), `${l} : eleve inscrit, premiere seance`)
    // Sans fuseau connu, l'heure reste, sans parenthese inventee.
    const sans = ux('seance_annulee', l, { portee: 'foyer', fuseau: undefined }).texte
    assert(sans.includes('10:00') && !sans.includes('10:00 ('), `${l} : sans fuseau`)
  }
})

Deno.test('FN-108 : eleve_inscrit, un texte par public ; la famille ne recoit jamais celui de l enseignant', () => {
  const enseignant: Record<string, string> = { fr: 'Un élève rejoint votre classe', en: 'A student joins your class',
    ar: 'ينضم طالب إلى فصلك', es: 'Un alumno se une a su clase', pt: 'Um aluno junta-se à sua turma' }
  for (const l of ECRITES) {
    const f = ux('eleve_inscrit', l, { portee: 'foyer', eleves: ['Lina'],
      destination: '/tuteur/classes/f27b0000-0000-0000-0000-000000000202' })
    assert(!f.texte.includes(enseignant[l]), `${l} : famille, texte de l enseignant\n${f.texte}`)
    assert(!f.html.includes('/enseignant/'), `${l} : famille, lien de l enseignant`)
    assert(f.html.includes('https://app.rewayahacademy.com/#/tuteur/classes/f27b0000-0000-0000-0000-000000000202'), `${l} : famille, lien`)
    const s = ux('eleve_inscrit', l, { portee: 'soi' })
    assert(!s.texte.includes(enseignant[l]) && s.html.includes('https://app.rewayahacademy.com/#/eleve'), `${l} : eleve`)
    const e = ux('eleve_inscrit', l, { portee: 'classe' })
    assert(e.texte.includes(enseignant[l]) && e.html.includes('/enseignant/classes'), `${l} : enseignant`)
    // L'enseignant ne recoit aucun prenom d'enfant par e-mail.
    assert(!ux('classe_creee', l, { portee: 'classe', eleves: ['Lina'] }).texte.includes('Lina'), `${l} : classe creee, enseignant`)
    assert(!e.texte.includes('Lina'), `${l} : eleve inscrit, enseignant`)
  }
})

Deno.test('UX-026 : un avis sans les nouvelles donnees garde son texte d avant, sans trou', () => {
  for (const l of ECRITES) {
    for (const m of ['classe_creee', 'eleve_inscrit', 'seance_annulee', 'classe_supprimee']) {
      const { texte } = composer(rendre({ modele: m, categorie: 'classes', essentielle: false, donnees: {} }, l).contenu)
      assert(!/undefined|null|«\s*»|“”|\(\)/.test(texte), `${l} ${m}\n${texte}`)
    }
  }
})

Deno.test('UX-026 : en arabe, le nom latin de la classe et les prenoms sont isoles pour l ordre de lecture', () => {
  const { texte } = ux('seance_annulee', 'ar', { portee: 'foyer', eleves: ['Lina'] })
  assert(texte.includes('«\u2068Les bases, lundi 18 h\u2069»'), texte)
  assert(texte.includes('\u2068Lina\u2069'), texte)
})

Deno.test('UX-030 : les villes des fuseaux sont celles de l application (commun.fuseaux, fr et ar)', async () => {
  const cle = (iana: string) => iana.split(/[/_]/).filter(Boolean)
    .map((m, i) => i === 0 ? m.toLowerCase() : m[0].toUpperCase() + m.slice(1).toLowerCase()).join('')
  for (const [langue, table] of [['fr', VILLES_FUSEAU_FR], ['ar', VILLES_FUSEAU_AR]] as const) {
    const json = JSON.parse(await Deno.readTextFile(new URL(`../../../../assets/i18n/${langue}.i18n.json`, import.meta.url)))
    const app: Record<string, string> = json.commun.fuseaux
    const serveur = Object.fromEntries(Object.entries(table).map(([iana, ville]) => [cle(iana), ville]))
    assertEquals(serveur, app, `${langue} : la table du serveur s ecarte de celle de l application`)
  }
  // Hors de la table, comme dans l'application : le dernier segment, isole en arabe.
  assertEquals(villeDuFuseau('America/St_Johns', 'fr'), 'St Johns')
  assertEquals(villeDuFuseau('America/St_Johns', 'ar'), '\u2068St Johns\u2069')
  assertEquals(villeDuFuseau('pas un fuseau', 'fr'), null)
  assert(ux('seance_annulee', 'fr', { portee: 'foyer', fuseau: 'America/Toronto' }).texte.includes('10:00 (heure de Toronto)'))
  assert(ux('seance_annulee', 'ar', { portee: 'foyer', fuseau: 'Africa/Casablanca' }).texte.includes('10:00 (بتوقيت الدار البيضاء)'))
})

// CAND-04 (06/11/2026) : l'application route sur le fragment. Un lien vers une
// route sans « /#/ » ouvre la racine, puis l'entree des familles. Chaque lien
// de chaque modele, dans chaque langue, vers l'application porte « /#/ ».
Deno.test('chaque lien vers l application passe par le fragment /#/', () => {
  const donnees = { prenom: 'Khadija', sujet: 'S', corps: 'Corps', jours_avant: 3, invite_par: 'Amine',
    expire_le: '2026-10-30T10:00:00Z', code: 'ABCD-EFGH-JKMN', destination: '/tuteur/demandes' }
  let vus = 0
  for (const langue of ['fr', 'ar', 'en', 'es', 'pt']) {
    for (const m of modelesConnus) {
      const { html, texte } = composer(contenuPour({ modele: m, categorie: 'classes', essentielle: true, donnees }, langue))
      for (const lien of `${html} ${texte}`.match(/https:\/\/app\.rewayahacademy\.com[^\s"'<>)]*/g) ?? []) {
        vus += 1
        assert(lien.startsWith('https://app.rewayahacademy.com/#/'), `${langue} ${m} : ${lien}`)
      }
    }
  }
  assert(vus > 0)
})

// INVITATIONS-PERSONNELLES (lot 7, 07/11/2026) : le courriel personnel des
// candidats importes, deux variantes choisies par le serveur.
const INV_CAND = (variante: string) => ({ modele: 'invitation_candidat_importe', categorie: 'recrutement',
  essentielle: false,
  donnees: { code: 'ABCD-EFGH-JKMN', expire_le: '2026-11-29T10:00:00Z', variante, jeton_desinscription: 'jeton-7' } })

Deno.test('invitation_candidat_importe : variante A (promesse tenue), code, lien, echeance, desinscription', () => {
  const c = contenuPour(INV_CAND('A'))
  const { html, texte } = composer(c)
  assertEquals(c.sujet, 'Votre invitation personnelle à rejoindre Rewayah Academy')
  assert(texte.includes('Fin octobre, nous vous avions promis un courriel personnel. Le voici.'), texte)
  assert(texte.includes('pour votre patience'), texte)
  assert(texte.includes('ABCD-EFGH-JKMN') && texte.includes('29 novembre 2026') && texte.includes('ne sert qu’une fois'), texte)
  assert(html.includes('invitation=1&amp;code=ABCD-EFGH-JKMN') || html.includes('invitation=1&code=ABCD-EFGH-JKMN'), html)
  assert(texte.includes('Poursuivre ma candidature') && texte.includes('« Faisons connaissance »'), texte)
  assert(html.includes('/fr/courriels/desinscription?jeton=jeton-7'), html)
  // La phrase « repondez simplement a ce message » attend la confirmation du directeur.
  assert(!/répondez simplement/.test(texte), texte)
  assert(!/salle|examen|vérification/i.test(texte), texte)
})

Deno.test('invitation_candidat_importe : variante B, sans la phrase de promesse', () => {
  const { texte } = composer(contenuPour(INV_CAND('B')))
  assert(!texte.includes('nous vous avions promis'), texte)
  assert(texte.includes('Merci d’avoir rempli notre formulaire') && texte.includes('pour votre démarche'), texte)
  // Sans variante connue : B (jamais une promesse qui n'a pas ete faite).
  const { texte: inconnue } = composer(contenuPour(INV_CAND('')))
  assert(!inconnue.includes('nous vous avions promis'), inconnue)
})

Deno.test('invitation_candidat_importe en arabe : ecrit a la main, jamais traduit', () => {
  const r = rendre(INV_CAND('A'), 'ar')
  assertEquals(r.traduireDepuis, undefined)
  const { texte } = composer(r.contenu)
  assert(texte.includes('في أواخر أكتوبر، وعدناكم برسالة شخصية. وها هي.') && texte.includes('«لنتعارف»'), texte)
  assert(texte.includes('ABCD-EFGH-JKMN') && texte.includes('متابعة ترشحي'), texte)
  assert(!/Bonjour|Assalamou|Poursuivre/.test(texte), texte)
  const b = composer(rendre(INV_CAND('B'), 'ar').contenu).texte
  assert(!b.includes('وعدناكم') && b.includes('جزاكم الله خيرًا على مبادرتكم.'), b)
  assert(TRADUITS_A_L_ENVOI.includes('invitation_candidat_importe'))
})

// SALLE-2-ENTRETIEN (07/11/2026) : les avis de l'entretien disent l'heure
// locale du candidat avec son fuseau, distinguent la veille des 15 minutes,
// et ne parlent jamais d'avis, de compte rendu ni de salle.
Deno.test('SALLE-2 : avis de l entretien, heure locale, veille ou 15 minutes, fr et ar', () => {
  const ent = (modele: string, langue: string, donnees: Record<string, unknown>) =>
    composer(rendre({ modele, categorie: 'recrutement', essentielle: false,
      donnees: { prenom: 'Candidat', ...donnees } }, langue).contenu).texte
  const heure = { debut_local: '2026-11-12T10:00', fuseau: 'Europe/Paris' }
  assert(ent('entretien_reserve', 'fr', heure).includes('10:00 (heure de Paris)'), ent('entretien_reserve', 'fr', heure))
  assert(ent('entretien_reserve', 'ar', heure).includes('10:00 (بتوقيت باريس)'), ent('entretien_reserve', 'ar', heure))
  assert(ent('entretien_rappel', 'fr', { ...heure, sorte: 'veille' }).includes('demain'))
  assert(ent('entretien_rappel', 'fr', { ...heure, sorte: 'quinze' }).includes('15 minutes'))
  assert(ent('entretien_rappel', 'ar', { ...heure, sorte: 'quinze' }).includes('15 دقيقة'))
  for (const l of ['fr', 'ar']) {
    for (const m of ['entretien_reserve', 'entretien_rappel', 'entretien_rappel_direction', 'entretien_tenu', 'entretien_a_replanifier']) {
      const sans = ent(m, l, {})
      assert(!/undefined|null|\(\)/.test(sans), `${l} ${m} sans heure\n${sans}`)
      assert(!/salle|examen|compte rendu|favorable/i.test(ent(m, l, heure)), `${l} ${m} : mot interdit au candidat`)
    }
  }
})

// INVITATION-SECOND-ADULTE (07/11/2026) : l'invitation d'un adulte au foyer
// porte son code et ouvre la creation du compte, dans les cinq langues.
Deno.test('invitation_foyer : code et lien de creation du compte, cinq langues', () => {
  for (const langue of ['fr', 'ar', 'en', 'es', 'pt']) {
    const { html, texte } = composer(contenuPour({ modele: 'invitation_foyer', categorie: 'compte', essentielle: true,
      donnees: { invite_par: 'Nour', code: 'ABCD-EFGH-JKMN', expire_le: '2026-11-14T10:00:00Z' } }, langue))
    assert(texte.includes('ABCD-EFGH-JKMN'), `${langue} ${texte}`)
    assert(html.includes('https://app.rewayahacademy.com/#/connexion?mode=creer&amp;foyer=1&amp;code=ABCD-EFGH-JKMN')
      || html.includes('https://app.rewayahacademy.com/#/connexion?mode=creer&foyer=1&code=ABCD-EFGH-JKMN'), `${langue} ${html}`)
  }
  // Sans code (ancienne ligne de la file) : la connexion simple, comme avant.
  const ancien = composer(contenuPour({ modele: 'invitation_foyer', categorie: 'compte', essentielle: true,
    donnees: { invite_par: 'Nour', code: '"><script>' } }))
  assert(!ancien.html.includes('<script>') && !ancien.html.includes('foyer=1'), ancien.html)
  assert(ancien.html.includes('https://app.rewayahacademy.com/#/connexion'), ancien.html)
})

// INVITATION-COMPTE (07/11/2026) : le lien du candidat porte son code.
Deno.test('lien_inscription : le lien porte le code du candidat, cinq langues', () => {
  for (const langue of ['fr', 'ar', 'en', 'es', 'pt']) {
    const h = composer(contenuPour({ modele: 'lien_inscription', categorie: 'recrutement', essentielle: true,
      donnees: { code: 'ABCD-EFGH-JKMN' } }, langue)).html
    assert(h.includes('https://app.rewayahacademy.com/#/connexion?mode=creer&amp;candidature=1&amp;code=ABCD-EFGH-JKMN'), langue)
  }
  const sansCode = composer(contenuPour({ modele: 'lien_inscription', categorie: 'recrutement', essentielle: true,
    donnees: { code: '"><b>' } })).html
  assert(!sansCode.includes('code=') && !sansCode.includes('<b>'), sansCode)
})

// HORLOGE-ET-LIEU (12/11/2026, H3) : l'annonce du changement d'heure dit l'heure
// exacte avant et apres, le jour du changement, dans chaque langue, sans prenom
// d'eleve ; un autre changement de creneau garde la phrase generale.
Deno.test('creneau_change : l annonce du changement d heure, cinq langues', () => {
  const donnees = { motif: 'changement_heure', portee: 'soi', date_changement: '2027-03-28',
    changements: [{ jour_avant: 3, avant: '19:00', jour_apres: 3, apres: '20:00' }] }
  for (const langue of ['fr', 'en', 'es', 'pt', 'ar'] as const) {
    const c = contenuPour({ modele: 'creneau_change', categorie: 'classes', essentielle: true, donnees }, langue)
    const texte = c.blocs.map((b) => b.type === 'texte' ? b.texte : '').join(' ')
    assert(texte.includes('19:00') && texte.includes('20:00'), `${langue} : ${texte}`)
    assert(!texte.includes('undefined') && !texte.includes('${'), `${langue} : ${texte}`)
  }
  const fr = contenuPour({ modele: 'creneau_change', categorie: 'classes', essentielle: true, donnees })
  assert(fr.blocs.some((b) => b.type === 'texte' && b.texte.startsWith('À partir du dimanche 28 mars 2027, votre cours du mercredi passe de 19:00 à 20:00.')),
    JSON.stringify(fr.blocs))
  const ordinaire = contenuPour({ modele: 'creneau_change', categorie: 'classes', essentielle: true, donnees: { portee: 'foyer' } })
  assert(ordinaire.blocs.some((b) => b.type === 'texte' && b.texte.startsWith('L’horaire de la classe change.')),
    JSON.stringify(ordinaire.blocs))
})

// HORLOGE-ET-LIEU (13/11/2026, I2 et I3) : le jour d'arrivee est dit quand le jour
// change ; la phrase sur La Mecque n'est dite que si la classe y est.
Deno.test('creneau_change : le jour d arrivee, avec le jour inchange, avance ou recule', () => {
  const texteDe = (donnees: Record<string, unknown>, langue: 'fr' | 'en' | 'es' | 'pt' | 'ar' = 'fr') =>
    contenuPour({ modele: 'creneau_change', categorie: 'classes', essentielle: true, donnees }, langue)
      .blocs.map((b) => b.type === 'texte' ? b.texte : '').join(' ')
  const commun = { motif: 'changement_heure', portee: 'soi', date_changement: '2027-03-28' }
  // Jour inchange : « du mercredi », pas de « au ».
  const inchange = texteDe({ ...commun, changements: [{ jour_avant: 3, avant: '19:00', jour_apres: 3, apres: '20:00' }] })
  assert(inchange.includes('du mercredi passe de 19:00 à 20:00'), inchange)
  // Le jour avance : dimanche 23:00 puis lundi 00:00.
  const avance = texteDe({ ...commun, changements: [{ jour_avant: 7, avant: '23:00', jour_apres: 1, apres: '00:00' }] })
  assert(avance.includes('passe du dimanche 23:00 au lundi 00:00'), avance)
  // Le jour recule : lundi 00:00 puis dimanche 23:00.
  const recule = texteDe({ ...commun, changements: [{ jour_avant: 1, avant: '00:00', jour_apres: 7, apres: '23:00' }] })
  assert(recule.includes('passe du lundi 00:00 au dimanche 23:00'), recule)
  // Plusieurs creneaux dont un change de jour.
  const plusieurs = texteDe({ ...commun, changements: [
    { jour_avant: 3, avant: '19:00', jour_apres: 3, apres: '20:00' },
    { jour_avant: 7, avant: '23:00', jour_apres: 1, apres: '00:00' }] })
  assert(plusieurs.includes('le mercredi de 19:00 à 20:00') && plusieurs.includes('du dimanche 23:00 au lundi 00:00'), plusieurs)
  // Les cinq langues disent le jour d'arrivee.
  for (const langue of ['fr', 'en', 'es', 'pt', 'ar'] as const) {
    const t = texteDe({ ...commun, changements: [{ jour_avant: 7, avant: '23:00', jour_apres: 1, apres: '00:00' }] }, langue)
    assert(t.includes('23:00') && t.includes('00:00') && !t.includes('undefined'), `${langue} : ${t}`)
  }
  // La Mecque : dite seulement quand la classe y est (academie vrai).
  const mecque = texteDe({ ...commun, academie: true, changements: [{ jour_avant: 3, avant: '19:00', jour_apres: 3, apres: '20:00' }] })
  assert(mecque.includes('Le cours reste à la même heure à La Mecque : c’est l’heure de votre ville qui change.'), mecque)
  const sans = texteDe({ ...commun, academie: false, changements: [{ jour_avant: 3, avant: '19:00', jour_apres: 3, apres: '20:00' }] })
  assert(!sans.includes('La Mecque'), sans)
  const ancien = texteDe({ ...commun, changements: [{ jour_avant: 3, avant: '19:00', apres: '20:00' }] })
  assert(!ancien.includes('La Mecque') && ancien.includes('19:00'), ancien)
})

// HORLOGE-ET-LIEU (13/11/2026, I5) : le courriel que la direction recoit quand la
// tache de nuit refuse de convertir une classe n'est PAS celui d'une famille :
// phrase propre, lien vers le planning de la direction, jamais de texte SQL ni
// d'identifiant, dans les cinq langues.
Deno.test('creneau_change : refus de conversion, avis propre a la direction', () => {
  const donnees = {
    motif: 'conversion_refusee', cause: 'proche', classe: 'Classe des lionceaux',
    groupe_id: 'd5000000-0000-4000-8000-0000000000a3', destination: '/admin/operations/planning',
    // Une ancienne notification portait encore le texte brut : il ne doit jamais sortir.
    raison: 'HORLOGE-ET-LIEU : la classe d5000000-0000-4000-8000-0000000000a3 est a moins de 28 jours',
  }
  for (const langue of ['fr', 'en', 'es', 'pt', 'ar'] as const) {
    const c = contenuPour({ modele: 'creneau_change', categorie: 'classes', essentielle: true, donnees }, langue)
    const tout = JSON.stringify(c)
    assert(tout.includes('Classe des lionceaux'), `${langue} : ${tout}`)
    assert(!tout.includes('HORLOGE') && !tout.includes('d5000000') && !tout.includes('undefined'), `${langue} : ${tout}`)
    assert(tout.includes('/admin/operations/planning'), `${langue} : ${tout}`)
    assert(!tout.includes('/#/tuteur'), `${langue} : lien de famille : ${tout}`)
  }
  const fr = contenuPour({ modele: 'creneau_change', categorie: 'classes', essentielle: true, donnees })
  assert(fr.sujet === 'Une classe n’a pas pu passer à l’heure de La Mecque', fr.sujet)
  assert(fr.blocs.some((b) => b.type === 'texte' && b.texte.includes('un changement d’heure approche (moins de 28 jours)')),
    JSON.stringify(fr.blocs))
  // Une cause inconnue devient « autre » : jamais un texte brut.
  const inconnue = contenuPour({ modele: 'creneau_change', categorie: 'classes', essentielle: true,
    donnees: { ...donnees, cause: 'n importe quoi' } })
  assert(JSON.stringify(inconnue).includes('une vérification a échoué'), JSON.stringify(inconnue))
})
