// Ce que ces tests prouvent, et pourquoi ce ne sont pas des tests de
// connectivite.
//
// Les quatre connexions Cloudflare ont deja ete mesurees au vert le 21
// septembre 2026, cycle complet compris. Refaire cette preuve n'apprendrait
// rien. Ce qui n'a jamais ete prouve, en revanche, c'est que LE CODE de cette
// application envoie chaque responsabilite metier vers le bon seau, et
// seulement vers le sien. C'est cela qui est teste ici.
//
// Aucun de ces tests ne touche le reseau, ne lit une variable d'environnement
// reelle, ni ne detient un secret : la configuration est injectee, et les
// valeurs employees sont fabriquees a la bonne forme.

import { assert, assertEquals, assertThrows } from 'jsr:@std/assert@1'
import {
  configurationDe,
  DOMAINES,
  type DomaineStockage,
  ErreurConfigurationR2,
  type LecteurEnvironnement,
  prefixeSecrets,
  seauAttendu,
  stockageConfigure,
} from './domaines.ts'

const HEX32 = 'a'.repeat(32)
const HEX64 = 'b'.repeat(64)

/// Un trousseau complet et valide pour les quatre domaines.
function environnementComplet(
  ajustements: Record<string, string | undefined> = {},
): LecteurEnvironnement {
  const table: Record<string, string> = {}
  for (const domaine of DOMAINES) {
    const p = prefixeSecrets(domaine)
    table[`${p}_ACCOUNT_ID`] = HEX32
    table[`${p}_ACCESS_KEY_ID`] = HEX32
    table[`${p}_SECRET_ACCESS_KEY`] = HEX64
    table[`${p}_BUCKET_NAME`] = seauAttendu(domaine)
    table[`${p}_ENDPOINT`] = `https://${HEX32}.eu.r2.cloudflarestorage.com`
  }
  return (nom) => (nom in ajustements ? ajustements[nom] : table[nom])
}

// ============================================================
// A. Configuration
// ============================================================

Deno.test('A1 -- chaque domaine resout son propre groupe de secrets', () => {
  const attendus: Record<DomaineStockage, string> = {
    pieceIdentite: 'R2_IDENTITY_VAULT',
    archiveSeance: 'R2_RECORDINGS',
    pieceJointeMessage: 'R2_MESSAGING',
    priveApplicatif: 'R2_APP_PRIVATE',
  }
  for (const domaine of DOMAINES) {
    assertEquals(prefixeSecrets(domaine), attendus[domaine])
  }
  // Les quatre groupes sont distincts : un prefixe partage ferait lire le meme
  // trousseau pour deux responsabilites.
  assertEquals(new Set(DOMAINES.map(prefixeSecrets)).size, 4)
})

Deno.test('A2 -- aucun domaine ne partage le seau d un autre', () => {
  const seaux = DOMAINES.map(seauAttendu)
  assertEquals(new Set(seaux).size, 4)

  // Le controle porte sur la valeur reellement lue, pas sur la table interne :
  // un trousseau qui designe le seau d un autre domaine doit echouer.
  const croise = environnementComplet({
    'R2_IDENTITY_VAULT_BUCKET_NAME': 'rewayah-message-attachments',
  })
  const e = assertThrows(
    () => configurationDe('pieceIdentite', croise),
    ErreurConfigurationR2,
  ) as ErreurConfigurationR2
  assertEquals(e.secret, 'R2_IDENTITY_VAULT_BUCKET_NAME')
  // Le nom errone ne doit pas repartir dans le message : ce serait publier la
  // carte des seaux dans un journal.
  assert(!e.message.includes('rewayah-message-attachments'))
})

Deno.test('A3 -- un secret absent echoue explicitement, sans exposer de valeur', () => {
  for (const suffixe of ['ACCOUNT_ID', 'ACCESS_KEY_ID', 'SECRET_ACCESS_KEY', 'BUCKET_NAME', 'ENDPOINT']) {
    const nom = `R2_RECORDINGS_${suffixe}`
    const env = environnementComplet({ [nom]: undefined })
    const e = assertThrows(
      () => configurationDe('archiveSeance', env),
      ErreurConfigurationR2,
    ) as ErreurConfigurationR2
    assertEquals(e.secret, nom)
    assertEquals(e.motif, 'secret absent')
    // Le NOM du secret circule, sa VALEUR jamais.
    assert(!e.message.includes(HEX32))
    assert(!e.message.includes(HEX64))
  }
})

Deno.test('A4 -- aucun repli silencieux vers un autre seau', () => {
  // Le coffre d identite n est pas configure ; les trois autres le sont.
  const env = environnementComplet({ 'R2_IDENTITY_VAULT_SECRET_ACCESS_KEY': undefined })
  assertEquals(stockageConfigure('pieceIdentite', env), false)
  assertEquals(stockageConfigure('archiveSeance', env), true)
  // Et la resolution echoue au lieu de rendre la configuration d un voisin.
  assertThrows(() => configurationDe('pieceIdentite', env), ErreurConfigurationR2)
})

Deno.test('A5 -- une valeur mal collee est refusee sur sa forme', () => {
  // Les trois fautes reellement rencontrees le 21 septembre en posant les
  // quatre trousseaux : une affectation collee entiere, une valeur etrangere a
  // la forme attendue, et un secret de la mauvaise longueur.
  const cas: [string, string][] = [
    ['R2_MESSAGING_ENDPOINT', 'NOM = https://x.eu.r2.cloudflarestorage.com'],
    ['R2_MESSAGING_ACCOUNT_ID', 'pas-du-tout-hexadecimal-32-caracteres'],
    ['R2_MESSAGING_SECRET_ACCESS_KEY', HEX32],
  ]
  for (const [nom, valeur] of cas) {
    const env = environnementComplet({ [nom]: valeur })
    const e = assertThrows(
      () => configurationDe('pieceJointeMessage', env),
      ErreurConfigurationR2,
    ) as ErreurConfigurationR2
    assertEquals(e.secret, nom)
    assert(!e.message.includes(valeur))
  }
})

Deno.test('A5 bis -- une variable qui contient son propre nom est refusee', () => {
  // Quatrieme faute du 21 septembre : `BUCKET_NAME` portait le nom de la
  // variable au lieu du nom du seau. Ce cas ne peut pas etre teste par
  // l absence de la valeur dans le message -- la valeur EST le nom du secret,
  // que le message cite legitimement. C est donc le motif qui est verifie.
  for (const suffixe of ['ACCOUNT_ID', 'ACCESS_KEY_ID', 'SECRET_ACCESS_KEY', 'BUCKET_NAME']) {
    const nom = `R2_APP_PRIVATE_${suffixe}`
    const env = environnementComplet({ [nom]: nom })
    const e = assertThrows(
      () => configurationDe('priveApplicatif', env),
      ErreurConfigurationR2,
    ) as ErreurConfigurationR2
    assertEquals(e.secret, nom)
    assert(e.motif !== 'secret absent')
  }
})

Deno.test('A6 -- le point d acces est lu, jamais fabrique', () => {
  // La juridiction europeenne est PORTEE PAR LE SECRET. Le code ne reconstruit
  // rien : il accepte ce que l exploitation a pose, des lors que la forme tient.
  const europeen = environnementComplet()
  assertEquals(
    configurationDe('archiveSeance', europeen).pointAcces.hostname,
    `${HEX32}.eu.r2.cloudflarestorage.com`,
  )

  const refuses: [string, string][] = [
    [`http://${HEX32}.eu.r2.cloudflarestorage.com`, 'protocole autre que https'],
    ['https://exemple.test', 'hote hors de r2.cloudflarestorage.com'],
    [`https://${HEX32}.eu.r2.cloudflarestorage.com/un-seau`, 'le point d acces porte un chemin ou des parametres'],
    ['pas-une-url', 'ce n est pas une URL absolue'],
  ]
  for (const [valeur, motif] of refuses) {
    const env = environnementComplet({ 'R2_RECORDINGS_ENDPOINT': valeur })
    const e = assertThrows(
      () => configurationDe('archiveSeance', env),
      ErreurConfigurationR2,
    ) as ErreurConfigurationR2
    assertEquals(e.motif, motif)
  }
})

Deno.test('A7 -- un point d acces qui vise un autre compte est refuse', () => {
  // Les quatre domaines vivent sur quatre comptes Cloudflare DISTINCTS. Un
  // endpoint recopie d un domaine a l autre signerait vers le compte du voisin,
  // et R2 rendrait 403 sans jamais dire pourquoi. La forme seule ne suffit donc
  // pas : l hote doit porter l identifiant de compte de CE domaine.
  const autreCompte = 'c'.repeat(32)
  const env = environnementComplet({
    'R2_IDENTITY_VAULT_ENDPOINT': `https://${autreCompte}.eu.r2.cloudflarestorage.com`,
  })
  const e = assertThrows(
    () => configurationDe('pieceIdentite', env),
    ErreurConfigurationR2,
  ) as ErreurConfigurationR2
  assertEquals(e.secret, 'R2_IDENTITY_VAULT_ENDPOINT')
  assertEquals(e.motif, 'ne designe pas le compte de ce domaine')
  assert(!e.message.includes(autreCompte))
})

// ============================================================
// B. Routage -- les quatre correspondances, une par test
// ============================================================

Deno.test('B5 -- pieceIdentite va dans rewayah-identity-vault', () => {
  assertEquals(seauAttendu('pieceIdentite'), 'rewayah-identity-vault')
  assertEquals(configurationDe('pieceIdentite', environnementComplet()).seau, 'rewayah-identity-vault')
})

Deno.test('B6 -- archiveSeance va dans rewayah-session-recordings', () => {
  assertEquals(seauAttendu('archiveSeance'), 'rewayah-session-recordings')
  assertEquals(configurationDe('archiveSeance', environnementComplet()).seau, 'rewayah-session-recordings')
})

Deno.test('B7 -- pieceJointeMessage va dans rewayah-message-attachments', () => {
  assertEquals(seauAttendu('pieceJointeMessage'), 'rewayah-message-attachments')
  assertEquals(
    configurationDe('pieceJointeMessage', environnementComplet()).seau,
    'rewayah-message-attachments',
  )
})

Deno.test('B8 -- priveApplicatif va dans rewayah-app-private-storage', () => {
  assertEquals(seauAttendu('priveApplicatif'), 'rewayah-app-private-storage')
  assertEquals(
    configurationDe('priveApplicatif', environnementComplet()).seau,
    'rewayah-app-private-storage',
  )
})

Deno.test('B9 -- la configuration ne transporte aucun identifiant de compte', () => {
  const config = configurationDe('pieceIdentite', environnementComplet())
  // `accountId` n a d emploi que pour fabriquer un point d acces, et le point
  // d acces est lu. Le transporter serait une valeur sensible promenee sans
  // raison.
  assert(!('accountId' in config))
  assertEquals(Object.keys(config).sort(), [
    'cleAcces',
    'domaine',
    'pointAcces',
    'seau',
    'secretAcces',
  ])
})
