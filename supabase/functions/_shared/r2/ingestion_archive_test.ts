// Ce que ces tests prouvent : le contrat d'arrivee d'une archive Egress refuse
// ce qu'il doit refuser, et n'ecrit en base que ce qui est verifie.
//
// Aucun reseau, aucune base : le client Supabase est un double qui enregistre
// l'appel RPC recu. C'est tout ce dont on a besoin, puisque ce qui se mesure
// ici est la DECISION prise avant l'appel, pas l'appel lui-meme.

import { assert, assertEquals } from 'jsr:@std/assert@1'
import { entrerArchiveSiEgressTermine } from './ingestion_archive.ts'

const SEANCE = '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d'
const ARCHIVE = 'd4c3b2a1-5f6e-4b7a-9c8d-1e2f3a4b5c6d'
const CHEMIN = `recordings/${SEANCE}/${ARCHIVE}.ogg`

/// Un double du client Supabase qui retient le dernier appel RPC.
function faussClient(erreur: { message: string } | null = null) {
  const appels: { nom: string; args: Record<string, unknown> }[] = []
  return {
    appels,
    // deno-lint-ignore no-explicit-any
    client: {
      rpc(nom: string, args: Record<string, unknown>) {
        appels.push({ nom, args })
        return Promise.resolve({ data: null, error: erreur })
      },
      // deno-lint-ignore no-explicit-any
    } as any,
  }
}

function evenementEgress(surcharge: Record<string, unknown> = {}) {
  return {
    egressInfo: {
      egressId: 'EG_test_0001',
      roomName: 'salle-000000000a',
      status: 'EGRESS_COMPLETE',
      fileResults: [{ filename: CHEMIN, duration: 3_600_000_000_000, size: 15_728_640 }],
      ...surcharge,
    },
  }
}

Deno.test('I1 -- un evenement qui n est pas egress_ended ne fait rien', async () => {
  const { client, appels } = faussClient()
  assertEquals(
    await entrerArchiveSiEgressTermine(client, 'participant_joined', evenementEgress()),
    'sans_objet',
  )
  assertEquals(appels.length, 0)
})

Deno.test('I2 -- un Egress termine entre en base, duree convertie en secondes', async () => {
  const { client, appels } = faussClient()
  assertEquals(await entrerArchiveSiEgressTermine(client, 'egress_ended', evenementEgress()), 'entree')
  assertEquals(appels.length, 1)
  assertEquals(appels[0].nom, 'enregistrer_archive_seance')
  assertEquals(appels[0].args.p_room_name, 'salle-000000000a')
  assertEquals(appels[0].args.p_egress_id, 'EG_test_0001')
  assertEquals(appels[0].args.p_object_key, CHEMIN)
  // LiveKit exprime la duree en nanosecondes : 3600 s attendues.
  assertEquals(appels[0].args.p_duration_seconds, 3600)
  assertEquals(appels[0].args.p_size_bytes, 15_728_640)
  // La seance n est JAMAIS recue : elle est resolue en base depuis la salle.
  assert(!('p_session_id' in appels[0].args))
})

Deno.test('I3 -- un Egress avorte n ecrit rien', async () => {
  for (const etat of ['EGRESS_FAILED', 'EGRESS_ABORTED', '4', '']) {
    const { client, appels } = faussClient()
    assertEquals(
      await entrerArchiveSiEgressTermine(client, 'egress_ended', evenementEgress({ status: etat })),
      'ignoree_egress_echoue',
    )
    assertEquals(appels.length, 0, `l etat ${etat} ne doit rien ecrire`)
  }
})

Deno.test('I4 -- une cle hors convention est REFUSEE, jamais inseree', async () => {
  // Le point qui compte : un webhook est signe, donc authentique, mais une
  // signature atteste l emetteur et non le contenu. Un gabarit Egress qui ne
  // respecte pas le contrat ne doit pas faire entrer n importe quel chemin dans
  // une colonne que la lecture signera plus tard.
  const hostiles = [
    'recordings/../identity/3f2504e0-4f89-41d3-9a0c-0305e82c3301/x.ogg',
    `identity/${SEANCE}/${ARCHIVE}`,
    `recordings/${SEANCE}/${ARCHIVE}.mp4`,
    `recordings/pas-un-uuid/${ARCHIVE}.ogg`,
    'un/chemin/quelconque.ogg',
  ]
  for (const chemin of hostiles) {
    const { client, appels } = faussClient()
    const resultat = await entrerArchiveSiEgressTermine(
      client,
      'egress_ended',
      evenementEgress({ fileResults: [{ filename: chemin, duration: 1, size: 1 }] }),
    )
    assertEquals(resultat, 'refusee_cle_hors_convention', `${chemin} aurait du etre refuse`)
    assertEquals(appels.length, 0)
  }
})

Deno.test('I5 -- le prefixe du seau est retire, sans etre ecrit en dur ici', async () => {
  const { client, appels } = faussClient()
  await entrerArchiveSiEgressTermine(
    client,
    'egress_ended',
    evenementEgress({
      fileResults: [{ filename: `rewayah-session-recordings/${CHEMIN}`, duration: 1, size: 1 }],
    }),
  )
  assertEquals(appels[0].args.p_object_key, CHEMIN)
})

Deno.test('I6 -- un evenement incomplet ne fait rien', async () => {
  const incomplets: Record<string, unknown>[] = [
    {},
    { egressInfo: { status: 'EGRESS_COMPLETE' } },
    { egressInfo: { status: 'EGRESS_COMPLETE', fileResults: [] } },
    { egressInfo: { status: 'EGRESS_COMPLETE', roomName: '', fileResults: [{ filename: CHEMIN }] } },
    { egressInfo: { status: 'EGRESS_COMPLETE', roomName: 'r', egressId: '', fileResults: [{ filename: CHEMIN }] } },
  ]
  for (const e of incomplets) {
    const { client, appels } = faussClient()
    const resultat = await entrerArchiveSiEgressTermine(client, 'egress_ended', e)
    assertEquals(resultat, 'ignoree_sans_fichier')
    assertEquals(appels.length, 0)
  }
})

Deno.test('I7 -- une panne de base est rapportee, jamais levee', async () => {
  // Le webhook doit repondre 200 a LiveKit pour l evenement de presence qu il
  // vient de traiter. Une exception ici provoquerait un renvoi de l evenement
  // ENTIER, donc un doublon de presence pour rattraper une archive.
  const { client } = faussClient({ message: 'panne' })
  assertEquals(
    await entrerArchiveSiEgressTermine(client, 'egress_ended', evenementEgress()),
    'echec_base',
  )
})

Deno.test('I8 -- le codec n est pas invente', async () => {
  // `EgressInfo` ne porte pas de champ `codec` : le format demande vit dans la
  // requete d origine, que l evenement de fin ne reprend pas. La colonne reste
  // nulle plutot que de porter une valeur lue sur un champ inexistant.
  const { client, appels } = faussClient()
  await entrerArchiveSiEgressTermine(client, 'egress_ended', evenementEgress({ codec: 'opus' }))
  assertEquals(appels[0].args.p_codec, null)
})
