<!-- verdict : REFUSEE -->
## Relecture adverse COUPE-MOTS-4 : branche `corrections/c2-coupe-mots-4` (2ae14169)

**Verdict : REFUSÉE.** Le travail est solide et il était indispensable, mais deux défauts majeurs sont prouvés sur des écrans que la demande cite ou que le lot dit couvrir. Le premier va directement contre l'objectif du point (4).

### 1. Ce qui est conforme (vérifié sur pièces)
- **Périmètre.** Le diff entre 5a52ff30 et HEAD ne touche à aucun fichier interdit : page_shell, admin_shell, rangee_filtres, supabase/, .github/, vercel.json, pubspec, thème, Coran, dart_define. 5a52ff30 est bien un ancêtre de la branche.
- **Analyse statique et outils du dépôt.** `dart analyze --fatal-infos` ne signale aucun problème. Après `dart run slang`, le diff est vide. `verifier_jetons` compte 37 sur la base comme sur la branche, et aucune violation n'est ajoutée dans les fichiers touchés. `verifier_revue` passe de 1533 sur la base à 1414 sur la branche, sans nouvelle violation dans les fichiers touchés.
- **Suite complète** (tous les dossiers de `test/` sauf capture, fixtures et support, lancée avec `--concurrency=2`) : 6737 tests verts, 2365 sautés (captures, déjà sautés avant le lot), 0 échec.
- **Tests du lot** : 122 tests verts.
- **Mutations.** J'ai annulé chaque correction une par une ; à chaque fois, les tests échouent :
  - `choice_card_group.dart` revenu à la base : des dizaines d'échecs (test du composant et appelants, en fr, en ar, en standard et en guidée).
  - `nav_shell.dart` revenu à la base : 8 échecs (barre guidée du Contrôleur, du tuteur et de l'enseignant, à 320 x2 et à 390 x2).
  - `identifiantInsecable` rendu sans effet : 8 échecs (Comptes à 320, 390 et 1440, en fr et en ar).
  - `data_collection.dart` revenu à la base : 6 échecs.
  - `zone_saisie.dart` revenu à la base : 4 échecs (« Pourquoi ce changement ? » et la feuille d'une règle en guidée).
  - `fr.i18n.json` revenu à la base, puis slang relancé : la garde typographique échoue, et la feuille de réglages de l'enfant aussi.
- **Point (4), contenu du fichier.** 275 valeurs ont changé, et seuls des espaces ont changé : une fois U+00A0 remplacé par un espace ordinaire, les valeurs sont identiques à l'ancien fichier. Toutes les espaces ajoutées sont placées avant « ? ! : ; » ou à l'intérieur de « ». Il ne reste aucun « mot: » ni « mot? » collé. Les 275 clés sont déclarées dans `tool/libelles_sources.json` avec la mention « validé par délégation le 09/10 (DIR-REP-1) ». La fiche porte bien « décidé par délégation le 09/10 », dans REVUE-DIRECTEUR-2026-10 et dans le doc 03.
- **Captures.** J'ai ouvert les captures du lot : compte rendu en fr à 320 x2 avant et après, compte rendu à 390, barre guidée du Contrôleur en fr, barre guidée de l'enseignant en fr et en ar, Comptes en fr à 320 x2, motif en guidée. J'ai aussi fait mes propres captures en sombre. Constats :
  - « nor malement » et « obser vation » ont disparu. L'icône et le radio passent bien au-dessus du texte.
  - La barre guidée passe sur deux rangées avec des mots entiers, et elle est bien miroitée en RTL.
  - TEACHER‑AS‑000001 reste entier.
  - « changement ? » reste lié.
  - À 390 et à 1440, la mise en page est inchangée : les PNG avant et après sont identiques.
  - Les trois appelants de ChoiceCardGroup sans test propre (cahier avec son emplacement d'évaluation, recharge, galerie) sont couverts : les deux premiers par le test du cahier et celui de la recharge, la galerie par le test du composant.
  - La barre guidée est un enfant de Column : rien ne passe sous elle.

### 2. Défauts qui motivent le refus
1. **[majeur] Point (4) : un « : » seul en début de ligne sur la feuille des règles** (`FeuilleRegles`, admin_demandes). On le voit à 320 x2 en standard, en fr comme en ar : « Plateforme / : 60 min ». Le U+00A0 est bien dans le JSON, mais « Plateforme : » est plus large que sa demi-colonne, et le moteur de texte coupe quand même là. C'est exactement le mécanisme que le lot a corrigé pour ZoneSaisie, sans le chercher ailleurs. Le test « feuille d une regle » du lot monte précisément cet écran, mais il ne vérifie `ponctuationsIsolees` que sous le `BottomSheet`. Preuve : une sonde sur `find.byType(Scaffold)` renvoie `[Plateforme : 60 min : :, … 45 min : :, … 30 min : :]`, et la capture est ouverte. Le défaut existait déjà sur 5a52ff30 et le lot le laisse en place.
2. **[majeur] Point (1) : les « tests d'écran » ne mesurent que l'intérieur du composant.** Des mots restent coupés à 320 x2 sur des écrans appelants, dont le compte rendu du Contrôleur que la demande cite :
   - compte rendu en guidée : « automatique » et « l'administration. » ;
   - feuille des règles en guidée : « Plateforme » et « Appliquée » ;
   - dépôt de pièce : « d'identité » en standard et en guidée, « réglementation » en guidée ;
   - inscription (usage) en guidée : « souhaitez-/vous ».

   Ces coupures existaient toutes avant le lot (je l'ai vérifié sur 5a52ff30), mais la règle « aucun mot coupé à 320 px texte x2 » vaut pour l'écran, et la demande parlait de tests d'écran.

### 3. Réserves mineures
- Le lot ne contient aucune capture en sombre. J'en ai fait moi-même : rien d'anormal, et aucune couleur n'est touchée.
- Problème antérieur au lot : `ar.i18n.json` est presque vide (138 lignes). Les tests « ar » vérifient donc du français en RTL.
- La barre de filtres de Comptes coupe « En attent » à son bord. C'est dans `rangee_filtres.dart`, qui était interdit au lot, et le rédacteur l'a bien relevé.

### 4. Ce qu'il faut pour accepter
- Dans `FeuilleRegles`, faire passer « Plateforme : … » et « Appliquée : … » par `TexteSansCoupure`, ou les empiler. Même chose pour les textes coupés du compte rendu en guidée et du dépôt de pièce.
- Dans `support_coupe_mots_4.dart`, étendre `verifierCartesDeChoixEntieres` à tout l'écran : `motsCoupes` et `ponctuationsIsolees` sur `find.byType(Scaffold)`, avec des exceptions écrites et justifiées s'il le faut (traits d'union). Faire de même pour l'assertion de la feuille d'une règle.
- Montrer que ces nouveaux tests échouent quand on annule la correction, et fournir les captures après, en clair et en sombre.

Statut : présent dans le code et testé localement ; pas testé sur staging ; pas déployé. Je n'ai rien poussé. Les worktrees jetables (rv-COUPE-MOTS-4-12, rv-probe, base5a) ont été retirés.
