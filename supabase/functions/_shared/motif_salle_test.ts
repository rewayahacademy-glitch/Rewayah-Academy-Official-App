import { assertEquals } from 'jsr:@std/assert@1'
import { estPanne, lireMotifSalle, motifHorsSeance, motifPersonnel } from './motif_salle.ts'

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

Deno.test('acces_perdu (A3, PR 124) passe : le titulaire ecarte lit la vraie raison', () => {
  assertEquals(
    lireMotifSalle({
      motif: 'acces_perdu',
      fin_utc: '2026-11-01T19:00:00+00:00',
      ouverture_utc: null,
      grace_minutes: 15,
    }),
    {
      motif: 'acces_perdu',
      fin_utc: '2026-11-01T19:00:00+00:00',
      ouverture_utc: null,
      grace_minutes: 15,
    },
  )
})

Deno.test('titulaire_entre et remplacant_entre (A3-bis) passent : l autre enseignant lit qui est entre', () => {
  for (const motif of ['titulaire_entre', 'remplacant_entre'] as const) {
    assertEquals(
      lireMotifSalle({ motif, fin_utc: '2026-11-03T19:00:00+00:00', ouverture_utc: null, grace_minutes: 15 }),
      { motif, fin_utc: '2026-11-03T19:00:00+00:00', ouverture_utc: null, grace_minutes: 15 },
    )
  }
})

Deno.test('seance_reportee (SNT) passe : la salle d une seance reportee dit pourquoi elle ne s ouvre plus', () => {
  assertEquals(
    lireMotifSalle({ motif: 'seance_reportee', fin_utc: '2026-11-03T19:00:00+00:00', ouverture_utc: null, grace_minutes: 15 }),
    { motif: 'seance_reportee', fin_utc: '2026-11-03T19:00:00+00:00', ouverture_utc: null, grace_minutes: 15 },
  )
})

// SITUATIONS-GRAVES (11/11/2026) : chaque refus dit sa vraie raison.
Deno.test('les refus qui ne concernent que l\'appelant ont leur motif', () => {
  const vide = { fin_utc: null, ouverture_utc: null, grace_minutes: null }
  assertEquals(motifPersonnel('compte non valide'), { motif: 'compte_invalide', ...vide })
  assertEquals(motifPersonnel('acces suspendu pour paiement'), { motif: 'acces_suspendu', ...vide })
  assertEquals(motifPersonnel("sorti de la seance par l'enseignant"), { motif: 'sorti', ...vide })
  assertEquals(motifPersonnel("quota d'observation atteint : duree"), { motif: 'observation_terminee', ...vide })
  for (const r of [null, undefined, '', 'non inscrit a cette seance', 'salle pas encore ouverte']) {
    assertEquals(motifPersonnel(r), null)
  }
})

Deno.test('une seance qui n\'est pas la sienne : la meme reponse, qu\'elle existe ou non', () => {
  const attendu = { motif: 'non_inscrit', fin_utc: null, ouverture_utc: null, grace_minutes: null }
  for (const r of ['non inscrit a cette seance', 'seance introuvable', 'seance close', 'eleve hors du foyer']) {
    assertEquals(motifHorsSeance(r), attendu)
  }
  assertEquals(motifHorsSeance('salle pas encore ouverte'), null)
})

Deno.test('une panne n\'est pas un refus', () => {
  assertEquals(estPanne(null), true)
  assertEquals(estPanne({ code: 'PGRST301' }), true)
  assertEquals(estPanne({ code: '42501' }), false)
  assertEquals(estPanne({ code: '23514' }), false)
})

Deno.test('les nouveaux motifs passent aussi par lireMotifSalle', () => {
  assertEquals(lireMotifSalle({ motif: 'sorti' })?.motif, 'sorti')
})
