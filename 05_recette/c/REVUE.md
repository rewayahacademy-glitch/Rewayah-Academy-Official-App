# Lot C (Cours) : revue indépendante et adversariale

Date : 25/09/2026. Branche `ui/tuteur-v1-c` (11 commits, `bd373d9..be69282`) contre `ui/tuteur-v1`. Lecture seule ; seule commande lancée : les tests ciblés sous verrou (voir §2).

Lus : `03_DECISIONS_COORDINATEUR.md`, `05_LOTS_PHASE1.md` (§0 et §C), `05_recette/c/RAPPORT.md`, `demandes/C.md`, le diff complet (30 fichiers, +8734 −1297), maquettes `mobile/accueil  tuteur mobile light mode.png`, `acceuil tuteur desktop light.png`, `mobile/tuteur observation mobile light.png` (M1), et les captures `accueil_390x1600@2_page_entiere_light`, `accueil_1440x900@1_light`, `accueil_390x844@3_vide`, `classe_390x1400@2_page_entiere_light`, `classe_1440x900@1_light`, `classe_390x844@3_production_p3`, `catalogue_1440x900@1_light`.

## 1. Verdict

Lot globalement conforme : layout fidèle à V1, V2 et M1, carte groupée unique (`GroupeReglages`), parcours testés en touchant les boutons depuis la barre basse, aucun libellé interdit ajouté, frontière vide, les `.order` écrits précisent leur sens. **Aucun défaut bloquant propre au lot.** Deux points bloquent l'intégration mais dépendent du coordinateur (M1, M2). Le reste est majeur ou mineur.

## 2. Tests relancés (sous verrou, 25/09 05:13)

`flutter test --no-pub -r failures-only test/features/accueil_famille_test.dart test/features/classe_tuteur/classe_tuteur_test.dart test/features/classe_tuteur/catalogue_classes_test.dart test/router/etats_transverses_test.dart` → **`+91 -1`**. Les tests du lot passent. Seul échec : `test/router/etats_transverses_test.dart:81`, qui attend « Ce groupe ne vous est pas ouvert ». C'est le même échec que le rapport (demande C-9).

## 3. Défauts

### Bloquant

Aucun défaut bloquant imputable au lot.

### Majeur

**M1. Branche livrée avec un test rouge** (`etats_transverses_test.dart:81`, fichier du coordinateur, demande C-9). La fin de lot exige des tests verts.
Correction attendue : le coordinateur applique C-9 (attendre `t.classe.indisponiblePhrase`) avant ou pendant l'intégration. Sinon, la suite complète reste rouge.

**M2. En production, la Classe et l'adaptateur réel sont inatteignables** (C-1, C-12). `portClassesFoyerProvider` sert l'indisponible. `classes_foyer_supabase.dart` n'est donc pas atteignable depuis `main.dart`, ce qui manque le critère (a) de la définition de « fait » (registre §5 bis). L'Accueil n'affiche aucun « Voir la classe ». Les captures `classe_*` et `classe_390x844@3_production_p3` montrent un port K6 simulé, pas ce que voit un tuteur en production. Le nom « production_p3 » est trompeur.
Correction attendue : brancher C-1 à l'intégration. Renommer la capture `classe_..._p3_simulation`, ou la refaire avec le port absent.

**M3. Le questionnaire élève a perdu sa seule entrée visible** (C-7). `BlocParcours` est retiré de l'Accueil, et `/tuteur/parcours/:eleveId` n'est plus atteignable que par URL tant que le lot B n'a pas livré Fiche > Inscription. Retirer une entrée avant que la nouvelle existe crée une fonction orpheline.
Correction attendue : l'intégration C et B doit être simultanée. Sinon, garder l'entrée existante jusqu'à la livraison de B.

**M4. Le catalogue ne montre ni les séances, ni le fuseau, ni le parcours, même en simulation.** Capture `catalogue_1440x900@1_light` : « Les jours et heures de cette classe ne sont pas encore affichés ici. » (`fr.i18n.json:1644`). Le mandat §C.3 exige de vraies classes avec l'enseignant, toutes les séances, le fuseau et les places. Le contrat `ClasseOuverte` ne porte pas ces champs (C-14). Par ailleurs, `fuseauCatalogueProvider` vaut toujours `null` (`catalogue_classes_page.dart:43-45`). Le catalogue restera donc « pas encore ouvert » même dans le futur mode démonstration du directeur (décisions §1 bis-1 et §1 ter-6).
Correction attendue : le coordinateur tranche C-14 et C-15. Le mode démonstration doit surcharger `fuseauCatalogueProvider` et `portCatalogueClassesProvider`. Sans cela, le directeur ne verra jamais le catalogue sur l'aperçu.

**M5. Texte x2 et contraste non prouvés pour la Classe, ses 4 sous-pages et le Catalogue.** `test/accessibilite/rtl_echelle_texte_ecrans_test.dart` ne couvre que `AccueilFamillePage` (l. 254-259). Aucun test du lot n'utilise `textScaler` ou `textContrastGuideline` : la recherche dans `test/features/classe_tuteur/*` ne trouve rien.
Correction attendue : un test à 200 % de texte, sans débordement, sur Classe, Planning, Travail, Bibliothèque, Progression, Catalogue et Confirmation, à 390 et à 1440.

### Mineur

**m1. La ligne de parcours de l'Accueil n'est ni prouvée ni capturée.** V1 et V2 montrent « Règles de lecture • Niveau 1 » sous l'enseignant. Le code l'affiche seulement si la donnée existe (`carte_classe_seance.dart:217-256`), mais aucune fixture de l'Accueil ne fournit `niveauHumain`. Les captures `accueil_*` n'ont donc pas cette ligne, alors que la Classe l'a.
Correction : ajouter cours et niveau à la fixture de l'Accueil, et vérifier la ligne dans un test et une capture.

**m2. Écarts de placement par rapport à V1.** « Connecter un appareil » est un bouton pleine largeur sous le texte au lieu d'être à droite (V1 #17). Le libellé visible du « + » est « Ajouter » au lieu de « Ajouter un profil élève » (clé partagée `fr.i18n.json:80`, sélecteur du coordinateur).
Correction : demande au coordinateur pour le libellé. Remettre le bouton à droite au-dessus de 360 dp, en gardant le repli sous le texte pour le texte x2.

**m3. Libellés de la Classe différents de M1.** « Planning » au lieu de « Planning habituel ». Pour la même fonction, la Classe dit « Travail à préparer » et l'Accueil « Avant le prochain cours » (`fr.i18n.json:1437`, `1558`). « Temps restant » pendant le direct est remplacé par « Durée » (écart assumé, V8).
Correction : un seul nom pour cette fonction sur les deux écrans, ou un écart signé par le directeur.

**m4. Icône info absente devant « Comment ça marche ? », et sablier au lieu d'une horloge** (C-13, C-5). Écart visuel mineur, en attente du coordinateur.

**m5. La Bibliothèque peut être une impasse.** `detail_ressource_page.dart` n'affiche aucun disque retour sans `?retour=` et sans `canPop` (le diff le dit : « Sans l'un ni l'autre : pas de disque »). C'est le cas d'un lien profond ou d'un rechargement ouvert hors de la classe.
Correction : se replier sur `/tc/bibliotheque` (ou sur l'Accueil du rôle) au lieu de n'afficher aucun retour.

**m6. Tri : aucun test ne vérifie l'argument de sens.** Le mandat §1 ter bis-2 demande un test d'ordre ; `classesDepuisLignes` n'est testée que comme fonction pure. `ClassesFoyerSupabase` (`classes_foyer_supabase.dart:57, 69`) est correct. Le tri sans sens consommé (`service_appairage.dart:212`) est bien signalé (C-6).

**m7. Vocabulaire dans l'espace de noms du lot.** `tc.groupe.*` garde « Heure du groupe », « Mes groupes », « Élèves du groupe » et « Ce groupe ne vous est pas ouvert » (`fr.i18n.json:2040, 2053-2061`). Ces libellés ne sont pas affichés par les écrans tuteur livrés : `bloc_seance.dart:61-66` utilise `heureClasse`. Ils restent servis par `tc_espace_groupe`.
Correction : les renommer en « Classe », ou confirmer par écrit qu'ils ne sont joignables par aucun écran tuteur.

**m8. STUB du lot restant dans un fichier du coordinateur** : le commentaire « STUB PHASE 0 : propriété du lot C-obs » dans `app_router.dart:376-391` (C-11). À retirer à l'intégration.

## 4. Points vérifiés conformes (preuves)

- **Layout.** À 1440, l'Accueil suit V2 A : sélecteur, carte classe à gauche (Prochaine séance, heure, fuseau, durée, compte, « Voir la classe », conseil appareil) ; à droite UNE carte à filets (appareil / Avant le prochain cours / Dernière séance). La Classe à 390 suit l'ordre de M1 : en-tête avec retour, carte enseignant, bandeau d'état, date et durée, « Observer la séance », visites, « Comment ça marche ? », puis rubriques en carte groupée. Aucun « Rejoindre » (test `classe_tuteur_test.dart:180`).
- **Carte des fonctions.** Aucun doublon d'écran. « Voir tout », la rubrique Travail, « Voir l'historique » et la rubrique Historique ouvrent la même route. « Ajouter » ouvre le même flux que le Foyer (`accueil_famille_page.dart:124, 199`).
- **Carte groupée.** `GroupeReglages` sur la Classe (test `_rubrique`, l. 140-143). Un seul rectangle dans `classe_1440x900@1_light` et `accueil_1440x900@1_light`.
- **Navigation.** Les tests partent de la barre basse et touchent les boutons (`classe_tuteur_test.dart:120-136`). Le `routeur.go(depart)` initial sert seulement à monter l'écran de départ. Retour visible sur la Classe, les sous-pages et le Catalogue. L'onglet Accueil reste actif (l. 182). La déconnexion reste dans Compte, présent dans la barre et la barre latérale.
- **Desktop.** 1440 en barre latérale avec compositions 62/38, 1024 en rail. Aucune vue mobile étirée dans les captures lues.
- **Honnêteté.** Aucune fixture dans `lib/`. Travail, Bibliothèque et Progression disent « pas encore relié(e) » (`ressources_classe_page.dart:36-39`, `assignationsFamilleProvider` à `null`). Catalogue : « pas encore ouvert » en production, aucune réservation locale, clé d'idempotence gardée. DB-CRS-03, 07, 08, 09, 10, 11 et DB-TRV-07 sont cités.
- **Frontière.** `git diff --stat` sur `supabase .github vercel.json web/vercel.json pubspec.yaml pubspec.lock assets/fonts lib/core/theme lib/core/router lib/core/widgets lib/core/coran lib/core/tc_coran lib/features/tc_mushaf lib/core/capacites/port_*` : vide. Les fichiers `lib/core/tc_groupe/libelles_tc_groupe.dart`, `tc_parcours/port_travail_a_venir.dart`, `tc_catalogue/detail_ressource_page.dart` et `capacites/classes_foyer_supabase.dart` appartiennent tous au lot C (`00_OWNERSHIP.md` l. 78-79). Seuls les `windows/flutter/generated_*` restent non commités (hors diff).
- **Vocabulaire ajouté.** Aucune occurrence de « Session », « Cours en cours », « Ajouter enfant » ou « groupe » dans les clés ajoutées. « Sayyid / Sayyida » ; prénom seul quand le titre manque (`catalogue_classes_page.dart:68-75`).

## 5. Suite donnée (coordinateur, poste B, 25/09 07:45, commit `6cc903f` sur `ui/tuteur-v1-c`)

- **wip `4d37dc9` gardé** : cohérent avec la revue (m2 bouton à droite ≥ 360 dp, m3 « Avant le prochain cours », m5 retour de repli, m6 test de tri, m7 `tc.groupe.*` renommés en « classe », M5 test texte x2 et contraste). Ses tests ont été corrigés (tri `.asc.nullslast` de postgrest ; texte x2 du bandeau testé sur le bandeau seul).
- **M1 (C-9)** : `etats_transverses_test` attend un `EtatSysteme` (introuvable ou pas encore relié), plus le libellé « groupe ». Vert.
- **M2 (C-1, C-12)** : `portClassesFoyerProvider` sert `ClassesFoyerSupabase` (lectures RLS `0019`). La Classe est atteignable en production depuis « Voir la classe ». Le routeur de test garde `ClassesFoyerIndisponible`. Capture renommée `classe_390x844@3_p3_simulation`.
- **M3 (C-7)** : `BlocParcours` remis sur l'Accueil (état sans classe) jusqu'à l'intégration de Fiche > Inscription du lot B, qui porte l'entrée durable.
- **M4 (C-15)** : `fuseauCatalogueProvider` lit `monFuseauProvider` (fuseau du foyer). **C-14 reste ouvert** : `ClasseOuverte` (contrat K6, gelé) ne porte ni séances ni parcours ; demande écrite dans `demandes/C.md`. Le catalogue reste « pas encore ouvert » en production tant que DB-CRS-07 manque.
- Base `origin/ui/tuteur-v1` @ `1cbc760` fusionnée ; aucun lien `Routes.tuteurReglages` dans `accueil_famille_page.dart` (seul reste : `compte_page.dart`, hors lot C).
- Tests : suite complète `+2347 ~297`, 0 échec ; `flutter analyze` sans problème.
- Reste ouvert : m1 (ligne de parcours de l'Accueil non capturée), m4, m8 (STUB dans `app_router.dart`), captures à refaire après M2/M3.

## 6. Suite donnée (coordinateur, poste B, 25/09, commit `faa0a22` sur `ui/tuteur-v1-c`)

- **M4 (C-14, C-15)** : le fuseau était déjà branché sur `monFuseauProvider` (§5). Les séances, le fuseau et le parcours d'une classe ouverte restent hors de portée : le contrat `ClasseOuverte` (K6) est gelé et ne les porte pas. C-14 reste ouverte dans `demandes/C.md`, en attente d'une décision du directeur pour étendre K6 et d'une source serveur DB-CRS-07. Aucun contrat gelé n'a été touché ici.
- **M5** : déjà couvert par le wip intégré — `test/features/classe_tuteur/classe_echelle_texte_test.dart` teste les 7 écrans (Classe, Planning, Travail, Bibliothèque, Progression, Catalogue, Confirmation) à 390 et 1440, texte à 200 % sans débordement, et `textContrastGuideline` en clair et sombre. Vérifié vert sous verrou.
- **m1** : déjà couvert — `test/features/accueil_famille_test.dart` fournit `niveauHumain` à la fixture et vérifie la ligne « Cours fictif • Niveau fictif » sous l'enseignant.
- **m8** : corrigé — le commentaire « STUB PHASE 0 » de l'alias `/classes/:id/observer` dans `app_router.dart` est retiré ; la route reste un alias d'intégration documenté, propriété du lot C-obs, jusqu'à ce qu'`EspaceGroupePage` porte un bloc d'observation.
- **m4** (icône info, sablier) : non traité, reporté (arbitrage visuel non trivial dans le temps imparti d'un agent).
- `flutter analyze --fatal-infos` : aucun problème. Suite complète sous verrou : `+2347 ~297 skipped`, 0 échec.
- Captures régénérées dans `05_recette/c/captures/` (Accueil, Classe, Catalogue).
- **LC-R** : revue faite par le poste A, suites contrôlées ici → `verifie`. **LC-F** : faite, preuve ci-dessus.
