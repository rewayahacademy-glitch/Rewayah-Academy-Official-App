# LANGUES-1, étape 2 : anglais du chemin des candidats et des familles

Captures lues une à une (13/11/2026) : `en-connexion-*` et `en-recuperation-*` (390 clair, 1440 sombre),
`langue-compte-fr` et `langue-compte-en` (le choix de la langue du compte à trois langues).

Spécifié : anglais pour la création de compte et la connexion, la candidature d'enseignant, l'inscription et le
parcours de la famille, les messages d'erreur communs. Présent dans le code : `assets/i18n/en.i18n.json`
(1591 clés), sélecteur de langue du compte, pays en anglais. Testé localement : tests de langue, rendu des
captures. Testé sur staging, déployé : non.

Pas traduit en anglais (retombe sur le français) : le corps des textes juridiques (mentions, conditions,
annulation, confidentialité, cookies, protection des enfants), le contrat et la politique de contrôle
des enseignants, tout le reste de l'application hors du chemin demandé.

Poids du premier chargement (build web release, mêmes options, base 435f27b9 contre cette branche) : main.dart.js 16 281 653 -> 16 313 255 octets (+31 602, +0,19 %) ; compressé gzip 3 829 423 -> 3 835 207 (+5 784). Part différée arabe : 3 874 386 -> 4 216 282 (+341 896 ; gzip +48 615), chargée seulement en arabe. Part différée anglaise (nouvelle) : 248 242 octets (gzip 57 421), chargée seulement en anglais.

## Anglais complet (14/11/2026, claude/langues-2)

Étendue : 12 730 clés sur 12 984 traduites en anglais. Restent en français, par décision du pilote : les textes juridiques (`juridique`, 174 clés) et le contrat (`contrat`, 80 clés). Le contenu coranique reste en arabe.

Poids (build web release, mêmes options qu'au-dessus, base 435f27b9 contre cette branche) : `main.dart.js` 16 281 653 -> 16 314 766 octets (+33 113, +0,20 %) ; gzip 3 829 423 -> 3 835 615 (+6 192). Part différée anglaise : 2 008 551 octets (gzip 442 450), chargée seulement en anglais ; le build contient zéro chaîne anglaise dans le premier chargement.

Preuves : suite Flutter complète sur cette branche avant la fusion de main, 21 577 tests verts, 0 échec (8 643 ignorés comme d'habitude) ; après la fusion de main, analyse propre et 913 tests de `test/i18n`, `inscription_test`, `coupe_mots_3_test` verts. Non prouvé : la CI de la pull request, et la relecture d'un anglophone (vocabulaire choisi par l'agent, listé dans le rapport).
