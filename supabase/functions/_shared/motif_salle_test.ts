import { assertEquals } from 'jsr:@std/assert@1'
import { lireMotifSalle } from './motif_salle.ts'

Deno.test('un motif connu passe, avec les bornes du serveur', () => {
  assertEquals(
    lireMotifSalle({
      motif: 'terminee',
      fin_utc: '2026-11-01T18:00:00+00:00',
      ouverture_utc: '2026-11-01T16:40:00+00:00',
      grace_minutes: 15,
    }),
    {
      motif: 'terminee',
      fin_utc: '2026-11-01T18:00:00+00:00',
      ouverture_utc: '2026-11-01T16:40:00+00:00',
      grace_minutes: 15,
    },
  )
})

Deno.test('NULL, forme inattendue ou motif inconnu : aucun motif', () => {
  for (const v of [null, undefined, 'terminee', [], {}, { motif: 'salle fermee' }, { motif: 3 }]) {
    assertEquals(lireMotifSalle(v), null)
  }
})

Deno.test('une borne illisible est tue, le motif reste', () => {
  assertEquals(lireMotifSalle({ motif: 'annulee', fin_utc: 'hier', grace_minutes: -2 }), {
    motif: 'annulee',
    fin_utc: null,
    ouverture_utc: null,
    grace_minutes: null,
  })
})
