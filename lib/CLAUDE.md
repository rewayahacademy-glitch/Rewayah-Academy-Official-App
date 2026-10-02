# Front-end — Flutter

Charte active : `docs/current/03_DESIGN_SYSTEM_ET_UX.md` (Material Design 3, adaptation
iOS, palette douce, un titre, une tâche, un CTA par écran). Avant d'ouvrir un écran,
lire la ligne du MVP qui le concerne dans `docs/current/06_SPEC_FONCTIONNELLE_MVP.md`.
Pour retrouver un écran ou un composant déjà construit, le catalogue historique est
dans `docs/archive/2026-09-pre-remise-a-plat/design/` (référence, pas une règle).

Les composants partagés (`Pressable`, `BentoTile`, `AvatarTile`, `AudioLabel`,
`PermanentNotice`, `PinPad`, `EmptyState`, `OfflineBanner`, `ChoiceCardGroup`,
`ActionPrincipale`) sont les seuls points d'entrée de leur fonction : on les améliore, on
n'en recrée pas un qui ferait la même chose.

## 🧊 Règles gelées du directeur, DESIGN-GOV-2026-09-26 (obligatoires avant tout nouveau lot visuel)

Texte intégral et seul faisant foi : `docs/current/DESIGN-GOV-2026-09-26.md` (copie de `projet/ressources:memoire/DESIGN-GOV-2026-09-26.md`). **Règle gelée jusqu'à nouvelle décision datée du directeur** : ne pas la modifier, ne pas la réinterpréter.

- Autorité (§1) : dernière demande explicite du directeur, puis décisions canoniques, puis contrats serveur vérifiés, puis la spec du lot, puis le système de design gelé. Une maquette n'élargit jamais une permission ; aucune donnée absente du contrat n'est inventée.
- Validation UX 2026 (§4) : avant d'implémenter une disposition `PROPOSITION`, la confronter aux référentiels officiels (Flutter adaptive, Material 3, Apple HIG, WCAG 2.2 AA, Nielsen, Fitts / Hick / Gestalt, Baymard ; GOV.UK exclu) et livrer `UX_REVIEW_<lot>.md` (règle, source, date, conclusion, modification). Jamais « conforme » sans règle ni conséquence.
- Contrats A à E (§4 bis) : échelle d'espacement 4 à 64, **objet vers le CTA qui agit dessus : 16**, CTA au bord *trailing* (`start/end`, jamais `left/right`), pas de bouton pleine largeur sur bureau, `ActionPrincipale` / `AppCard` / `GroupeReglages` / `Skeleton` / `AppBottomSheet` jamais forkés, bureau 1440 réel, durées de mouvement gelées, `Skeleton` + `BlocAsynchrone` obligatoires pour tout chargement substantiel.
- Progression (§4 bis.8) : s'applique aux nouveaux lots seulement. **Aucune étape faite n'est rouverte** ; l'harmonisation des écrans déjà faits se fera en une passe (HU-1) après les visuels de tous les rôles.
## Règles vérifiées par `dart run tool/verifier_jetons.dart` (local et CI)

- **Aucun `onTap` nu** : tout passe par `Pressable`.
- **Aucune couleur littérale** hors de `lib/core/theme/app_palette.dart`. Le thème expose
  des paires `AppColorPair`, des encres `AppInkColor` ou l'ombre `AppShadowColor`, jamais
  une couleur seule. `Color(0x...)` dans un widget métier est un défaut.
- **Aucun `IconData` construit** hors de `lib/core/icons/app_icons.dart`, aucun `Icons.`
  Material : une seule iconographie, Phosphor.
- **Aucune valeur d'espacement** hors de l'échelle 4, 8, 12, 16, 20, 24, 32, 40, 48, 64
  (`AppSpacing`, `Ecart`). **Aucun rayon littéral** (`AppRadius`, rayon d'un enfant plus
  petit que celui du parent). **Aucune `BoxShadow`** hors de `app_elevation.dart`.
  **Aucun `letterSpacing`** hors d'`app_typography.dart`. **Aucune `Duration` ni `Curves`**
  hors d'`app_mouvement.dart` (les durées métier en minutes restent libres).
- **Aucun nom de jeton d'avant la refonte** : `surfaceBase`, `borderDefault`,
  `textOnLightAccent`, `textOnLightAlert`, `NotoSans`, `VarelaRound`.
- **`PermanentNotice` n'accepte aucun paramètre**, pas même `key`.
- **Tout choix proposé à l'utilisateur passe par `ChoiceCardGroup`**, avec sa carte « Autre ».
- **Un seul routeur**, `lib/core/router/app_router.dart`, aucune branche par plateforme.
  L'Interface guidée et l'interface standard partagent la même arborescence : ce qu'un
  écran **affiche** change, jamais la structure.
- **Zéro emoji, zéro M-dash** dans le code et les libellés.
- **Aucune chaîne visible en dur** : slang, clés en points (`eleve.accueil.rejoindre`).
  Un libellé qui doit aussi être parlé passe par `CleAudio`.
- Le mode d'interface est porté par le thème (`AppMetriques.of(context)`), jamais passé en
  paramètre d'écran en écran.
- Tags de conformité, vocabulaire fermé : `[M3-COLOR]`, `[A11Y]`, `[RESPONSIVE]`,
  `[QURAN-STAGE]`. Un tag documente une décision, pas un fait déjà visible.

## Interdits d'interface (revue directeur 01-02/10)

Textes complets : consignes K-54 à K-59 du tableau ; table des preuves : `docs/current/REVUE-DIRECTEUR-2026-10.md`. Ces règles s'ajoutent aux autres et valent pour tous les rôles. Chaque correction se fait dans le **composant partagé**, jamais écran par écran.

- **K-54 Boutons centrés.** Le contenu d'un bouton (libellé, icône) est centré horizontalement et verticalement, ligne à ligne s'il passe à la ligne. Un bouton ne déborde jamais de l'écran ni de sa carte. Jamais de bouton recomposé dans un écran : `ActionPrincipale` (centrage fait une fois). Contrôle : `bouton-recompose`, test `test/core/garde_interface_test.dart` (320 px, texte ×2).
- **K-55 Jamais de cartes collées.** Deux cas seulement : cartes détachées séparées par `Ecart` (contenus indépendants), ou **une seule** grande carte à lignes fines (contenus liés). Contrôle : `cartes-collees`, `verifierEcartCartes`.
- **K-56 Un seul bouton plein par écran**, à la place prévue par la Bible V2 (bas de formulaire ou de feuille, jamais au milieu du contenu). Les actions secondaires sont des boutons discrets ou des liens avec flèche (`LienFleche`). Un bouton qui ne peut pas aboutir n'est pas grisé (`bouton-grise` / `bouton-desactive`).
- **K-57 Formulaires semi-automatiques : déduit > choisi > saisi.** Préremplir (profil, foyer, classe, créneaux, dernière valeur, date du jour), sinon proposer (liste, puces, sélecteur, meilleure option justifiée), sinon seulement saisir (nom, note libre). Chaque fiche de formulaire classe ses champs déduit / choisi / saisi et justifie chaque « saisi ».
- **K-58 Tout choix s'explique.** Chaque option dit quand la choisir et sa conséquence ; une conséquence irréversible se dit avant le choix ; l'écran commence par une phrase de contexte ; quand l'option est une carte, **toute la carte** est cliquable et l'état choisi se voit sur toute la carte.
- **K-59 Tout message d'échec ou de données incomplètes** dit ce qui manque, la cause probable en mots simples, et quoi faire maintenant (D5 : « non confirmé », jamais « non envoyé »). Contrôle : `erreur-sans-action`.

Règles équivalentes, déduites des remarques du directeur :

- **Le bouton principal d'une séance change de sens, il ne se grise jamais (CTA-FIN-1).** Avant l'ouverture de la salle : « Préparer la séance ». Salle ouverte, et tant qu'elle l'est (un cours qui déborde garde son bouton) : « Rejoindre la salle », avec la pastille « En direct » dès l'heure de début. Temps écoulé et cahier non déposé : « Remplir le cahier de transmission », avec le rappel qu'il est obligatoire. Cahier déposé : « Voir le cahier », en lien discret (`LienFleche`). Séance annulée : « Voir la Classe ». La logique est pure et testée (`ctaSeance`, `seanceDeLaCarte` dans `lib/core/enseignant/cta_seance.dart`) ; l'écran ne décide rien. Contrôle : `test/core/enseignant/cta_seance_test.dart`, et le groupe « CTA-FIN-1 » de `test/features/journee_test.dart` (320 px et 1440 px, texte ×1 et ×2, clair et sombre).
- **Aucun élément ne recouvre un contenu à lire** (bouton flottant, bandeau, pastille). Test : `verifierSansChevauchement`, à 320 px et en texte ×2.
- **Hiérarchie de titres stricte** : un titre d'écran, des titres de section, jamais deux niveaux au même rang ni un saut de niveau.
- **Un état ne se signale jamais par la couleur seule** (en direct, annulée, actif / inactif) : texte ou icône en plus de la couleur.
- **Une alerte urgente va toujours en tête** de l'écran, avant tout autre bloc.
- **Aucun libellé ambigu** : il dit « qui » et « quoi » (« Cahier de séance de Yasmine », pas « Cahier » ; « Déclarer l'absence de… », pas « Déclarer une absence »). Contrôle : `libelle-ambigu`.
- **Un client ne voit jamais un mot technique ou interne** : « admin » (on dit la direction), « foyer » chez la direction. Contrôle : `mot-interne`.
- **« Classe », jamais « groupe »** dans un texte visible.
- Tout nouveau libellé est déclaré dans `tool/libelles_sources.json` avec le commentaire du directeur comme source.

Les contrôles tournent dans `dart run tool/verifier_revue.dart` et dans la CI ; leur socle (`tool/revue_socle.txt`) fige l'existant et ne peut que diminuer.

## Pièges déjà payés

- Une paire dit sur quoi elle s'écrit : `surfaceAlert.applyTo(...)` écrit en blanc ; un
  message d'erreur sur la page passe par l'encre `inkAlert`. `inkFaint` est interdit sur
  `surfaceSunken` (contraste 4,48).
- Ne jamais filtrer un `AsyncValue` par son type : Riverpod 3 relance un provider en
  échec, l'état repasse par `AsyncLoading` en gardant `hasError`. Lire `hasValue`,
  `hasError`, `isLoading`.
- Une absence n'est pas un échec : lecture vide ouvre l'inscription, lecture en erreur
  ferme sur le portail d'attente (`LectureProfil`).
- Un bouton qui ne peut pas aboutir n'est pas rendu, il n'est pas grisé ; une phrase
  explique la limite.
- Le code personnel de l'élève ne quitte jamais l'appareil
  (`test/appairage/code_local_test.dart` le vérifie).
- Ce qui décide d'un droit se pose en base, pas à l'écran. Le routeur est une commodité ;
  la barrière est la RLS.
- Une police variable a une valeur par défaut par axe : Bricolage Grotesque sort à
  `wght` 800 si un style ne déclare que `fontSize`.
- Le mouvement réduit ne supprime pas l'information : une pulsation devient une bordure
  `borderStrong` fixe (`AppMouvement.duree`, `AppMouvement.translation`).
- Une seule zone pleine par écran : l'action principale. Alertes et badges prennent le
  registre doux (`washX` fond, `inkX` encre).
- Un écran sans navigation qui l'expose n'existe pas : brancher l'entrée, pas seulement
  la route.

## Génération de code

Dans cet ordre, sinon slang échoue :

```
dart run slang
dart run build_runner build --delete-conflicting-outputs
```

Le code généré est versionné : `dart analyze` doit passer sans étape préalable, et la CI
refuse tout diff après régénération.
