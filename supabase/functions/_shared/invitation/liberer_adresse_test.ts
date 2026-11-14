import { assertEquals } from 'jsr:@std/assert@1'
import { type PorteLiberation, preparerAdresseInvitee } from './liberer_adresse.ts'

const ANCIEN = '3e596c03-0000-4000-8000-000000000001'

function porte(opts: {
  ancien?: string | null
  liberation?: boolean
  autorise?: boolean
  creation?: 'cree' | 'existe' | 'echec'
  consomme?: boolean
} = {}) {
  const { ancien = null, liberation = true, autorise = true, creation = 'cree', consomme = true } = opts
  const appels: string[] = []
  const p: PorteLiberation = {
    ancienCompte: (type) => {
      appels.push(`ancien:${type}`)
      return Promise.resolve(ancien)
    },
    liberer: (id) => {
      appels.push(`liberer:${id}`)
      return Promise.resolve(liberation)
    },
    autoriser: (type) => {
      appels.push(`autoriser:${type}`)
      return Promise.resolve(autorise)
    },
    creerCompte: (a) => {
      appels.push(`creer:${a}`)
      return Promise.resolve(creation)
    },
    consommer: (type) => {
      appels.push(`consommer:${type}`)
      return Promise.resolve(consomme)
    },
  }
  return { p, appels }
}

const donnees = { code: 'ABCD-EFGH-JKMN' }
const prof = 'prof@example.com'

Deno.test('ancien compte supprime : adresse liberee, puis compte neuf, puis code consomme, dans cet ordre', async () => {
  const { p, appels } = porte({ ancien: ANCIEN })
  assertEquals(await preparerAdresseInvitee('invitation_enseignant', donnees, prof, p), 'preparee')
  assertEquals(appels, ['ancien:equipe', `liberer:${ANCIEN}`, 'autoriser:equipe', `creer:${prof}`, 'consommer:equipe'])
})

Deno.test('invite tout neuf (aucun ancien compte) : le compte neuf est cree a l\'envoi', async () => {
  const { p, appels } = porte()
  assertEquals(await preparerAdresseInvitee('invitation_enseignant', donnees, prof, p), 'preparee')
  assertEquals(appels, ['ancien:equipe', 'autoriser:equipe', `creer:${prof}`, 'consommer:equipe'])
})

Deno.test('invitation non valide ou compte deja la : rien, aucun compte cree', async () => {
  const { p, appels } = porte({ autorise: false })
  assertEquals(await preparerAdresseInvitee('invitation_enseignant', donnees, prof, p), 'rien')
  assertEquals(appels, ['ancien:equipe', 'autoriser:equipe'])
})

Deno.test('candidat importe : equipe puis candidat, le premier qui reconnait le code', async () => {
  const appels: string[] = []
  const p: PorteLiberation = {
    ancienCompte: () => Promise.resolve(null),
    liberer: () => Promise.resolve(true),
    autoriser: (type) => {
      appels.push(`autoriser:${type}`)
      return Promise.resolve(type === 'candidat')
    },
    creerCompte: () => Promise.resolve('cree'),
    consommer: (type) => {
      appels.push(`consommer:${type}`)
      return Promise.resolve(true)
    },
  }
  assertEquals(await preparerAdresseInvitee('invitation_candidat_importe', donnees, 'c@example.com', p), 'preparee')
  assertEquals(appels, ['autoriser:equipe', 'autoriser:candidat', 'consommer:candidat'])
})

Deno.test('liberation en echec : le courriel ne part pas, aucun compte cree', async () => {
  const { p, appels } = porte({ ancien: ANCIEN, liberation: false })
  assertEquals(await preparerAdresseInvitee('invitation_enseignant', donnees, prof, p), 'echec')
  assertEquals(appels, ['ancien:equipe', `liberer:${ANCIEN}`])
})

Deno.test('ancien compte libere mais invitation non autorisee ensuite : echec, pas de rien silencieux', async () => {
  const { p } = porte({ ancien: ANCIEN, autorise: false })
  assertEquals(await preparerAdresseInvitee('invitation_enseignant', donnees, prof, p), 'echec')
})

Deno.test('compte neuf en echec : echec ; compte deja la : preparee sans consommer', async () => {
  assertEquals(await preparerAdresseInvitee('invitation_enseignant', donnees, prof, porte({ creation: 'echec' }).p), 'echec')
  const { p, appels } = porte({ creation: 'existe' })
  assertEquals(await preparerAdresseInvitee('invitation_enseignant', donnees, prof, p), 'preparee')
  assertEquals(appels.includes('consommer:equipe'), false)
})

Deno.test('code non consomme apres creation : le compte reste prepare', async () => {
  assertEquals(await preparerAdresseInvitee('invitation_enseignant', donnees, prof, porte({ consomme: false }).p), 'preparee')
})

Deno.test('autres modeles (foyer, rappels...) ou sans code : jamais de recherche ni de compte', async () => {
  for (const modele of ['invitation_foyer', 'lien_inscription', 'invitation_famille_importee']) {
    const { p, appels } = porte({ ancien: ANCIEN })
    assertEquals(await preparerAdresseInvitee(modele, donnees, 'x@example.com', p), 'rien')
    assertEquals(appels, [])
  }
  const { p, appels } = porte({ ancien: ANCIEN })
  assertEquals(await preparerAdresseInvitee('invitation_enseignant', {}, 'x@example.com', p), 'rien')
  assertEquals(appels, [])
})
