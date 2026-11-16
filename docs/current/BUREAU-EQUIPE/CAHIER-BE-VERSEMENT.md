# Cahier BE-VERSEMENT : le moyen de versement se valide seul quand il suit la règle

Décision du directeur (16/11/2026) : « Pourquoi c'est à moi de confirmer un moyen de
paiement qui est pris en charge et en règle ? Tu écris les règles, le candidat choisit ; si
ça respecte les règles, c'est automatique, comme pour les créneaux. Si le pays n'est pas pris
en charge, l'app le lui dit et lui propose une solution. Si le pays n'est pas pris en charge
et n'est pas sous embargo, alors je confirme ou non. »

## Ce qui est vrai aujourd'hui (lu le 16/11)

- `private.paiement_etat` (`20261021220100_cand_l6_referentiel_paiement.sql:715`) ne rend
  `compatible` que si un moyen déclaré croise une ligne `confirme` du référentiel **et** que
  la dernière décision de la direction sur ce candidat le confirme (transition 24). Sinon
  `a_verifier`.
- En production : **125 candidatures en cours sont `a_verifier`, et toutes déclarent un pays
  dont la ligne de virement est déjà `confirme`** (BE, CI, ID, KW, NG, NP, PK, SA, SN). Elles
  n'attendent qu'un clic du directeur, dossier par dossier.
- Référentiel : 191 pays `confirme`, 57 `en_verification`, 1 `indisponible`.

## La règle, désormais

| Ligne du pays de versement | Résultat | Qui agit |
| :--- | :--- | :--- |
| `confirme` | **compatible, sans geste** | personne ; la direction peut encore écarter un cas précis (transition 25, motif obligatoire) |
<<<<<<< HEAD
| `en_verification` (pas pris en charge, pas d'embargo) | `a_verifier` | **la direction, une fois par pays** : elle confirme ou rend indisponible la ligne du pays, et tous les candidats de ce pays suivent (déclencheur existant) |
| `indisponible` (embargo ou impossible) | `incompatible` | personne : le candidat le lit, avec la solution (choisir le pays du compte d'un proche, PR #500) |

Le geste par candidat « Confirmer le moyen de versement » (transition 24) disparaît des
écrans ; il reste au serveur pour les données passées.
=======
| `en_verification` (pas pris en charge, pas d'embargo) | `incompatible`, et la candidature attend en `paiement_non_disponible` (correction du 16/11 : le cahier disait `a_verifier`, le code ne l'a jamais fait) | **la direction, une fois par pays** : elle confirme ou rend indisponible la ligne du pays, et tous les candidats de ce pays suivent (déclencheur existant, transition 9) |
| `indisponible` (embargo ou impossible) | `incompatible` | personne : le candidat le lit, avec la solution (choisir le pays du compte d'un proche, PR #500) |

Le geste par candidat « Confirmer le moyen de versement » (transition 24) disparaît des
écrans ; il reste au serveur pour les données passées. Le calcul ne rend plus jamais `a_verifier`.
>>>>>>> origin/main

## À faire (zone : `supabase/**` seulement, plage `20261128200000` à `20261128200900`)

1. `private.paiement_etat` retouchée par ancre : un moyen qui croise une ligne `confirme`
   rend `compatible`, sauf si la dernière décision de la direction sur ce moyen l'infirme.
   Le reste du calcul ne change pas.
2. Recalcul unique de toutes les candidatures en cours `a_verifier` et `incompatible` par
   `private.paiement_recalculer(id, 'referentiel')`, journalisé comme aujourd'hui. Aucun
   courriel envoyé par ce recalcul. Le nombre recalculé est écrit dans la PR.
3. La capacité qui propose le geste 24 ne le propose plus quand la ligne est `confirme`
   (chercher la source des gestes proposés au dossier).
4. Scénario SQL : pays confirmé (compatible sans geste) ; confirmé puis infirmé par la
   direction (incompatible) ; `en_verification` (a_verifier) puis la ligne passe `confirme`
   (compatible pour tous) ; `indisponible` (incompatible) ; salle 3 : un confirmé n'est
   plus restreint pour le paiement.

Interdit : changer le référentiel lui-même, toucher l'argent ou la paie, écrire en
production. Mots d'effacement : aucun. Avant la PR, passer le fichier dans
`tool/page_migrations/generer.py` (aucun `BEGIN;` ni `COMMIT;` seul sur une ligne).

Phrase à rendre vraie : « Un candidat qui reçoit ses versements dans un pays pris en charge
n'attend plus jamais mon clic ; je ne décide qu'une fois par pays, pour ceux qui ne le sont pas. »
