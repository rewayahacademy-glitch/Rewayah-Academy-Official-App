// MINEUR-FANTOME (07/11/2026) : ce que creer-profil-enfant decide avant de
// creer quoi que ce soit (demande.ts). Sans reseau ni cle de service.

import { assertEquals } from 'jsr:@std/assert@1'
import { lireDemande, metadonneesApp, REFUS_ADULTE } from './demande.ts'

const base = { first_name: 'Yanis', last_name: 'Diallo' }

Deno.test('18 ans et plus : refuse, avec le refus de la RPC mot pour mot', () => {
  for (const age of [18, 19, 35, 99]) {
    assertEquals(lireDemande({ ...base, age, gender: 'male' }), { ok: false, erreur: REFUS_ADULTE })
  }
  assertEquals(REFUS_ADULTE.startsWith('age adulte'), true)
})

Deno.test('17 ans : accepte', () => {
  const d = lireDemande({ ...base, age: 17, gender: 'female' })
  assertEquals(d.ok, true)
})

Deno.test('genre hors de public.gender : refuse (genre_requis)', () => {
  for (const gender of ['autre', 'garcon', 'MALE', '', 0, true]) {
    assertEquals(lireDemande({ ...base, age: 9, gender }), { ok: false, erreur: 'genre_requis' })
  }
})

Deno.test('genre absent : accepte, genre nul (chemin d admission, regle B6)', () => {
  assertEquals(lireDemande({ ...base, age: 9 }), {
    ok: true, prenom: 'Yanis', nom: 'Diallo', age: 9, niveau: null, genre: null,
  })
  assertEquals(lireDemande({ ...base, age: 9, gender: null }).ok, true)
})

Deno.test('genre male ou female : garde', () => {
  const d = lireDemande({ ...base, age: 9, gender: 'male' })
  assertEquals(d.ok && d.genre, 'male')
})

Deno.test('le genre va dans app_metadata seulement, a cote de child_of', () => {
  assertEquals(metadonneesApp('t1', 'female'), { child_of: 't1', gender: 'female' })
  assertEquals(metadonneesApp('t1', null), { child_of: 't1' })
})

Deno.test('prenom, nom et age restent requis', () => {
  assertEquals(lireDemande({ last_name: 'D', age: 9 }).ok, false)
  assertEquals(lireDemande({ ...base, age: 'neuf' }).ok, false)
})
