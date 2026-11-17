// PX-BD-SUPPORT : l'analyseur du Markdown ferme (cote serveur). Les memes vecteurs sont rejoues par le lecteur de l'application
// (test/core/tc_bibliotheque/markdown_ferme_test.dart) : les deux analyseurs donnent le meme resultat, ou un des deux est rouge.

import { assert, assertEquals } from 'jsr:@std/assert@1'
import { analyser } from './markdown_ferme.ts'
import vecteursJson from './vecteurs.json' with { type: 'json' }

interface Vecteur {
  nom: string
  source: string
  attendu: { ok: true; blocs: unknown[] } | { ok: false; code: string }
}

const vecteurs = vecteursJson as unknown as Vecteur[]

for (const v of vecteurs) {
  Deno.test(`vecteur : ${v.nom}`, () => {
    const r = analyser(v.source)
    if (v.attendu.ok) {
      assert(r.ok, `refuse (${r.ok ? '' : r.code}) alors qu'il devait passer`)
      assertEquals(r.blocs, v.attendu.blocs)
    } else {
      assert(!r.ok, 'accepte alors qu\'il devait etre refuse')
      assertEquals(r.code, v.attendu.code)
    }
  })
}

Deno.test('le jeu de vecteurs couvre chaque code de refus', () => {
  const codes = new Set(vecteurs.flatMap((v) => (v.attendu.ok ? [] : [v.attendu.code])))
  for (const c of ['vide', 'trop_long', 'ligne_trop_longue', 'trop_de_blocs', 'caractere_interdit', 'html', 'lien', 'image', 'tableau', 'code',
    'barre', 'marque_non_fermee', 'imbrication', 'liste_imbriquee', 'titre_trop_profond']) {
    assert(codes.has(c), `aucun vecteur pour le refus ${c}`)
  }
})

Deno.test('un refus donne la ligne du defaut', () => {
  const r = analyser('Un.\n\nDeux <b>x</b>.')
  assert(!r.ok)
  assertEquals(r.ligne, 3)
})
