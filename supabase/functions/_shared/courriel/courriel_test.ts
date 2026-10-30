// deno test --allow-read supabase/functions/_shared/courriel/
import { assert, assertEquals, assertThrows } from 'jsr:@std/assert@1'
import { composer } from './gabarit.ts'
import { contenuPour, modelesConnus } from './modeles.ts'
import { htmlAuth, LANGUES_AUTH, MODELES_AUTH, MODELES_AUTH_LANGUES } from './auth_modeles.ts'
import { FRANCAIS, LANGUES } from './modeles.ts'
import { TRADUITS_A_L_ENVOI } from './modeles_fr.ts'

// Les evenements de la contrainte notifications_evenement_check (etat au
// 27/10/2026 : les treize du 23/10 et les neuf de la fiche « Fraicheur et
// notifications », migration 20261027120000) et les modeles propres a la file.
const EVENEMENTS = ['demande_recue', 'classe_validee', 'enseignant_affecte', 'demande_close',
  'remplacement_propose', 'remplacement_pris', 'demande_presentation', 'controle_mission_attribuee',
  'controle_mission_non_controlee', 'classe_changee', 'paiement_relance', 'acces_suspendu_paiement',
  'acces_retabli_paiement',
  'classe_creee', 'enseignant_change', 'eleve_inscrit', 'eleve_retire', 'creneau_change',
  'seance_annulee', 'seance_deplacee', 'enseignante_absente', 'classe_supprimee']

Deno.test('chaque evenement de notification a son modele', () => {
  for (const e of [...EVENEMENTS, 'invitation_foyer', 'lien_inscription', 'attente_candidat', 'admission_recue',
    'admission_acceptee', 'admission_refusee', 'admission_precisions', 'message_libre', 'nouvelles']) {
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
