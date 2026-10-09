<!-- verdict : ACCEPTEE_AVEC_RESERVES -->
# Relecture adverse RTL-ISOL-1, branche `corrections/c2-rtl-isol`, commit 122daf4b

**Verdict : ACCEPTÉE AVEC RÉSERVES.** Aucun défaut majeur prouvé. Les quatre points demandés sont faits, testés, et chaque correction est vérifiée par mutation. Les trois réserves restantes sont mineures et portent sur les captures.

J'ai relu dans un worktree jetable détaché sur `origin/corrections/c2-rtl-isol`, retiré à la fin. Je n'ai rien poussé. La branche contient bien 5a52ff30.

## Périmètre du diff (5a52ff30 vers 122daf4b)

Fichiers de code modifiés :
- `lib/core/i18n/isolat_bidi.dart` : nouvelle fonction `phraseAvecValeur` ;
- `lib/core/tc_horloge/emplacement_entree.dart` : durées « Cours dans », « Attente » et « Salle ouverte » ;
- `lib/core/widgets/empty_state.dart` : un `Directionality` par texte, sans isolat dans la chaîne ;
- `accueil_famille/bloc_seance.dart` : conseil d'appareil ;
- `admin_comptes/comptes_page.dart` : introduction ;
- `fiche_groupe/fiche_groupe_page.dart` : ligne des élèves ;
- `ma_classe_adulte/ma_classe_adulte_page.dart` : « À propos » et ligne de progression.

S'y ajoutent les tests `test/features/rtl_isol_1_test.dart`, le script de capture, 30 captures et la section de décisions dans `REVUE-DIRECTEUR-2026-10.md`.

Fichiers interdits : `feuille_carte_classe.dart`, `bloc_cartes_classe.dart`, `page_shell.dart`, `supabase/`, `.github/`, `pubspec.yaml`, le thème et le Coran ne sont pas touchés.

La pastille « 3 élèves sur 6 places » et la progression « Chapitre 1 · 60 % » étaient déjà isolées par COUPE-MOTS-3b dans 5a52ff30 (`espace_groupe_page.dart:619`, `fiche_groupe_page.dart:696`, `fiche_groupe_page.dart:857`, `emplacements_groupe.dart:320`). Je l'ai vérifié par mutation, voir plus bas.

## Vérifications refaites (testé localement)

- `dart analyze --fatal-infos` : aucun problème.
- `verifier_jetons` : 37 violations, autant que sur 5a52ff30.
- `verifier_revue` : 1533 violations, autant que sur 5a52ff30.
- `dart format` sur les 9 fichiers Dart touchés : aucun écart.
- Tests ciblés : 160 réussis, 12 sautés (captures), 0 échec. Fichiers : rtl_isol_1, coupe_mots_3b, `test/core/widgets/empty_state_sans_coupure_test`, fiche_groupe, accueil_eleve (ELV-02), comptes, `emplacement_entree_test`, espace_classe_enseignant.
- Suite complète avec `--concurrency=2` sur test/core, widgets, features, accessibilite, teaching_core et router : **6169 réussis, 2365 sautés, 0 échec**.

## Mutations (on annule la correction, les tests doivent échouer)

| Fichier remis à l'état de 5a52ff30 ou isolat retiré | Tests qui échouent (ar) |
|---|---|
| `emplacement_entree.dart` | Salle ouverte ; Attente ; Espace Classe élève (durée) |
| `empty_state.dart` | EmptyState (constat et invitation) ; EmptyState de la fiche de séance |
| `bloc_seance.dart` | Conseil d'appareil |
| `comptes_page.dart` | Introduction de Comptes |
| `fiche_groupe_page.dart` | Ligne des élèves de l'Espace Classe enseignant |
| `ma_classe_adulte_page.dart` | Ligne de progression ; « À propos » |
| Observation, explication (l. 374) | Observation : explication |
| Observation, Nature (l. 577) | Observation : valeurs Nature et Domaine |
| Observation, Domaine (l. 583) | Observation : valeurs Nature et Domaine |
| Observation, échec (l. 638) | Observation : message d'échec |
| Pastille de capacité (espace_groupe et fiche_groupe) | coupe_mots_3b : Espace Classe élève et enseignant (ar) |

Toutes les corrections sont gardées par au moins un test. Le point 4 (tests de l'Observation) est rempli : chaque valeur visée a son propre cas qui échoue quand on retire son isolat.

## Régressions sur les autres appelants

`EmptyState` a 120 appelants. Le texte passé par l'appelant n'est plus modifié. La direction propre se calcule sur la première lettre forte, comme `isolerSiAutreSens` ailleurs dans le code. Les anciens tests au rouge (`empty_state_sans_coupure_test`, ELV-02) repassent et la suite complète est verte. Je n'ai trouvé aucun appelant dont le texte arabe commence par du latin.

## Captures ouvertes

Captures livrées, en fr et en ar : 320 x2 clair et 390 sombre. Les avant/après en ar existent pour cinq écrans : Espace Classe enseignant, Espace Classe élève, Ma classe, Comptes et fiche de séance vide.

- **Espace Classe élève, ar 320 x2 :** avant « الدرس بعد / h 28 3 », après « 3 h 28 ». La pastille « 3 élèves sur 6 places » et le conseil d'appareil (point final) sont dans le cadre et corrects. La réserve 1 de COUPE-MOTS-3b est levée.
- **Espace Classe enseignant, ar 320 x2 :** la ligne des élèves se lit « Niveau 1 · الاستئناف: Page 24 » dans l'ordre RTL, et « Chapitre 1 · 60 % » est correct.
- **Fiche de séance vide, ar :** avant « .l'enseignant », après « l'enseignant. ».
- **Comptes, ar :** avant « .endroit qui le montre », après « endroit qui le montre. ».
- **Ma classe, ar :** avant « .tajwid » et « h 28 3 », après « tajwid. » et « 3 h 28 ».
- **Captures supplémentaires produites par moi,** à 1440 sombre et 320 x2 sombre, en fr et en ar. Elles sont correctes, aucun mot n'est coupé.

## Réserves (mineures)

1. Il manque des captures dans le lot : aucune à 1440, aucune à 320 x2 sombre, aucune de l'Observation. Je les ai produites et vérifiées, mais elles ne sont pas versionnées.
2. Les captures « avant » de la pastille et du conseil d'appareil ne montrent pas le défaut, puisqu'il était déjà corrigé dans 5a52ff30. Elles valent preuve de rendu correct à 320 x2, pas preuve avant/après.
3. Dans le harnais de capture de la fiche de séance, les boutons touchent le bord. Le défaut était déjà là avant, il vient du harnais et pas du lot.

## Décisions consignées

La section RTL-ISOL-1 de `docs/current/REVUE-DIRECTEUR-2026-10.md` consigne trois décisions, chacune « décidé par délégation le 09/10 (DIR-REP-1) » :
- l'ordre de la ligne des élèves, niveau d'abord ;
- EmptyState sans isolat dans son texte ;
- le tutoiement laissé sans traduction.

Le statut indiqué est juste : présent dans le code, testé localement, ni staging ni déploiement.

## Serveur

Aucun besoin serveur.
