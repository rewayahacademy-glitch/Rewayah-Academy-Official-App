## Revue adverse EA-HL-DOUBLE-1 : branche `corrections/c2-hl-double` (ec7b7aeb)

**Verdict : REFUSÉE.** Trois écrans sous PageShell disent encore « hors ligne » deux fois (preuve ci-dessous). La demande portait sur **tous** les écrans qui doublent le signal. Ces trois écrans enfreignent aussi la règle que la branche écrit elle-même dans `03_DESIGN_SYSTEM_ET_UX.md`.

### Méthode
Travail en lecture seule, dans un worktree jetable détaché sur `origin/corrections/c2-hl-double`, retiré à la fin. Rien n'a été poussé.
- J'ai comparé la branche à sa base `3df81930` : 52 fichiers.
- J'ai lu le nouveau `lib/core/reseau/etat_sans_donnees.dart`, les pages modifiées, `fr.i18n.json` et la section « États » de 03.
- J'ai passé `lib/features` au grep : `NatureEtat.horsLigne`, `OfflineBanner`, `t.reseau`, et tous les libellés qui contiennent « réseau », « connexion » ou « hors ligne ».

### Ce qui est conforme
- `lib/core/widgets/page_shell.dart` n'a pas été touché.
- Accueil, Ma classe, Historique et Mon espace adultes, soldes, recharge, Foyer, fiche élève, ajout de profil, appareils, listes de la Journée, page de démarrage du routeur et observation : le bloc `EtatSansDonnees` dit ce qui manque, sans « hors ligne ».
- Les notes d'action ont perdu leur « Vous êtes hors ligne. » de tête.
- La règle est écrite dans 03, section « États », comme décision du 04/10 déléguée par le directeur (K-42).
- `dart run slang` ne produit aucun écart.
- `dart analyze --fatal-infos` : aucun problème.
- `verifier_revue` : 1575 violations, autant que le rédacteur annonce, contre 1606 avant son travail.
- `verifier_jetons` s'exécute.
- Tests des 15 fichiers touchés, `--concurrency=2` : +369, 0 échec.
- **Première mutation** : `EtatSansDonnees` ramené au titre et à la phrase par défaut (« Vous êtes hors ligne »). Douze tests ou plus échouent, la contre-épreuve sans données tient.
- Captures ouvertes :
  - Accueil sans données en 320 à 200 %, LTR et RTL : aucun mot coupé, un seul signal textuel ;
  - Accueil en 390 sombre ;
  - Ma classe avec données en 390.

### Défauts

1. **MAJEUR : la demande n'est pas remplie, trois écrans doublent encore le signal.**
   - `appairage_page.dart:542` : une carte avec icône wifi barré et le titre « Connexion interrompue », sous le bandeau.
   - `creneaux_page.dart:304` : « Sans réseau, vos heures restent consultables… ».
   - `bienvenue_page.dart:363` : « Sans réseau, vos créneaux ne pourront pas être enregistrés. »

   Preuve : j'ai ajouté une sonde temporaire, `expect(find.text(t.reseau.horsLigne), findsOneWidget)`, dans `emetteur_qr_test`, `creneaux_test` et `bienvenue_enseignant_test`, juste après les assertions de ces textes. Tout passe (+61) : le bandeau et le second signal sont donc à l'écran en même temps. Les trois routes sont actives (`app_router.dart` lignes 228, 576 et 815).

2. **MAJEUR : la raison donnée pour ne pas toucher ces textes est fausse.** Le rédacteur dit que les textes « Sans réseau, … » des enseignants sont dictés par le directeur. Or `tool/libelles_sources.json` ne source comme « commentaire du directeur » que les textes du cahier (LIB-CAHIER-1). `enseignant.creneaux.*`, `enseignant.bienvenue.*` et `appareils.emetteur.*` n'y ont aucune entrée ; ces libellés viennent de commits d'agent. Par ailleurs, la garde du catalogue (`etat_sans_donnees_test.dart`) ne cherche que « hors ligne | pas de réseau | pas de connexion ». « Sans réseau » et « Connexion interrompue » passent donc au travers, sans que personne ne le voie.

3. **Mineur : le cas « avec données » n'est pas prouvé au niveau des pages.** J'ai neutralisé `lectureHorsLigne` (`false && …`) et relancé les tests des écrans touchés : +362, tout passe. Seul le test unitaire couvre cette fonction. Le test de page « déjà lu puis relu en échec » ne passe probablement jamais par l'état « erreur avec valeur », à cause de la relance automatique de Riverpod.

4. **Mineur : les captures ne couvrent qu'une partie des écrans.**
   - Trois écrans sont capturés : Accueil, Ma classe, Mon espace.
   - Le sombre et le 1440 n'existent que pour l'Accueil.
   - Il n'y a aucune capture en Interface guidée.
   - Aucune capture pour Foyer, fiche élève, appareils, Journée, Historique, la page de démarrage du routeur et l'observation.

5. **Mineur : l'icône wifi barré est répétée.** Dans le bloc et dans la note d'entrée en séance, elle s'ajoute à celle du bandeau. Visuellement, c'est un second signal.

Hors périmètre, défaut déjà présent avant cette branche : en RTL, le texte du bandeau s'affiche « .reste consultable ». C'est un problème de sens d'écriture dans `OfflineBanner`, qui appartient à `page_shell` et à une autre équipe.

### Pour lever le refus
- Réécrire `appareils.emetteur.horsLigne.titre` pour qu'il dise ce qui manque (par exemple « Code en attente »), sans icône wifi barré.
- Réécrire `enseignant.creneaux.horsLigneGrille` et `enseignant.bienvenue.horsLigne` pour qu'ils disent ce qui ne peut pas se faire, sans « Sans réseau ».
- Élargir la regex de la garde : « sans réseau », « connexion interrompue », « réseau coupé », « internet ».
- Ajouter une assertion `expectHorsLigneUneFois` sur ces trois écrans.
- Écrire un test de page où `lectureHorsLigne` est vraiment nécessaire.
- Compléter les captures des écrans modifiés.

### Statut
Présent dans le code et testé localement. Ni testé sur staging, ni déployé. Pas de fusion.
