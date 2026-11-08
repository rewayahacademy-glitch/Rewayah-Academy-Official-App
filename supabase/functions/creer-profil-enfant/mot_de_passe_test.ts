// Le mot de passe d'un profil enfant respecte la politique d'Auth de
// production : une minuscule, une majuscule, un chiffre, un symbole.

import { assert, assertEquals, assertNotEquals } from 'jsr:@std/assert@1'
import { LONGUEUR_MOT_DE_PASSE, motDePasseAleatoire } from './mot_de_passe.ts'

Deno.test('1 000 tirages : 32 caracteres au moins et les quatre classes, toujours', () => {
  const vus = new Set<string>()
  for (let i = 0; i < 1000; i++) {
    const m = motDePasseAleatoire()
    assert(m.length >= 32, `trop court : ${m.length}`)
    assertEquals(m.length, LONGUEUR_MOT_DE_PASSE)
    assert(/[a-z]/.test(m), 'minuscule absente')
    assert(/[A-Z]/.test(m), 'majuscule absente')
    assert(/[0-9]/.test(m), 'chiffre absent')
    assert(/[!@#$%^&*()_+\-=\[\]{};:,.?]/.test(m), 'symbole absent')
    assert(/^[A-Za-z0-9!@#$%^&*()_+\-=\[\]{};:,.?]+$/.test(m), 'caractere hors politique')
    vus.add(m)
  }
  assertEquals(vus.size, 1000)
})

Deno.test('deux tirages different', () => {
  assertNotEquals(motDePasseAleatoire(), motDePasseAleatoire())
})
