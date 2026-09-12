# Système UX/UI Rewayah — la constitution

> Version 1.1, 11 septembre 2026. Version 1.0 écrite le 7 septembre, avant
> l'étape 5, après que le premier rendu visuel de l'application ait été jugé
> daté. Le rendu mobile déployé après le lot R3 a ensuite été jugé « plus nul
> que du générique » : l'opérateur a remis une deuxième Bible, plus stricte et
> plus complète (`00-bible-frontend-v2.md`), adoptée par **ADR-019** et lue en
> premier, avant ce fichier. **Aucun écran ne se construit plus sans passer par
> ces documents.**

## 1. Pourquoi ce corpus existe

Jusqu'ici, chaque écran a été spécifié dans le plan de son étape, puis construit.
Ça a produit des écrans corrects un par un et un ensemble qui ne ressemble pas à
un produit : un seul fond plat partout, des couleurs de marque posées en aplats
saturés, aucune échelle d'élévation, aucune règle de mouvement, et une
typographie française qui date le produit d'une décennie.

Le défaut n'est pas dans les écrans. Il est dans l'absence de **langage** au
dessus d'eux. Un agent qui reçoit « fais l'écran ADM-01 » et n'a pas de langage
invente : un rayon de 20, une carte, un bouton, et l'écran suivant en invente
d'autres. C'est exactement ce que produit le vibe coding, et c'est réparable une
seule fois : maintenant, tant que le produit est jeune.

**Règle qui gouverne tout le reste : aucun écran ne s'implémente s'il n'est pas
inscrit dans `08-catalogue-ecrans.md`.** Si un écran manque au catalogue, on
l'ajoute au catalogue d'abord, et on discute de sa fiche avant d'ouvrir un
fichier `.dart`.

## 2. Le principe directeur

> **Même langage visuel, charge cognitive différente.**

Un enfant de six ans et un comptable emploient le même produit, les mêmes
couleurs, les mêmes composants, le même mouvement. Ils ne voient pas la même
densité d'information. La différence se joue sur la quantité de décisions
offertes, jamais sur l'ADN visuel.

Corollaire, déjà tenu par le code : **le mode d'interface ne duplique pas
l'arborescence** (`etape-2-core-flutter.md` section 3). Une deuxième
arborescence finit toujours par diverger en silence.

## 3. La hiérarchie des sources de vérité

Le design ne décide jamais du métier. Le parcours utilisateur ne contredit
jamais la règle métier. Quand deux documents divergent, c'est celui du haut qui
gagne, et l'autre se corrige.

```
        RÈGLES MÉTIER            decisions.md, ADR-001 à ADR-018
               │
               ▼
        MODÈLE DE DONNÉES        etape-0-1-fondations.md, supabase/migrations/
               │
      ┌────────┴────────┐
      ▼                 ▼
 PARCOURS          MODÈLE DE SÉCURITÉ    parcours-utilisateurs.md / RLS
      │                 │
      └────────┬────────┘
               ▼
        SYSTÈME UX/UI            docs/design/  (ce dossier)
               │
               ▼
        FICHE D'ÉCRAN            08-catalogue-ecrans.md
               │
               ▼
        IMPLÉMENTATION FLUTTER   lib/
```

Un défaut visuel se corrige dans `docs/design/`. Un défaut de règle se corrige
dans `decisions.md`, jamais dans l'écran qui l'a révélé.

## 4. Les neuf documents

| Fichier | Répond à |
| :--- | :--- |
| `00-bible-frontend-v2.md` | Le contrat lui-même : 61 chapitres, copie intégrale et inchangée, adopté par ADR-019. Se lit **avant** les huit autres |
| `01-systeme-visuel.md` | À quoi ça ressemble : surfaces, élévation, rayons, densité, rythme, usage des couleurs, échelle typographique |
| `02-regles-ux.md` | Comment ça se comporte : une fonction par écran, dévoilement progressif, hiérarchie des actions, états, erreurs, destructif, notifications, matrice de conteneur |
| `03-architecture-information.md` | Qui voit quoi et par où : rôles et capacités, cinq niveaux de charge, zones, navigation, profondeur, classification état métier / UI / préférence |
| `04-systeme-mouvement.md` | Comment ça bouge : durées, courbes, les six motifs, réduction du mouvement |
| `05-regles-responsive.md` | Comment ça s'adapte : trois gabarits, un seul système de composants, tableaux, RTL, zoning physique |
| `06-accessibilite.md` | Utilisable par qui : contraste mesuré, cibles, échelle dynamique, lecteur d'écran, mode accessibilité |
| `07-catalogue-composants.md` | Avec quoi : les composants existants, ceux à construire, et les dix états obligatoires |
| `08-catalogue-ecrans.md` | Le registre des écrans, leur fiche, et la règle qui interdit d'en inventer un |

Les valeurs de jetons (hex, noms de police, icônes, règles islamiques,
copywriting) restent dans **`docs/produit/design-tokens.md`**, source unique. Les
documents de ce dossier nomment les jetons, ils ne recopient jamais leurs valeurs :
deux tableaux d'hex finiraient par diverger, et le mauvais serait recopié.

## 4 BIS. La Bible Frontend V2, et sa table de correspondance

`00-bible-frontend-v2.md` est le texte remis par l'opérateur le 11 septembre
2026, adopté sans modification par ADR-019. Il ne se réécrit jamais : c'est la
table ci-dessous qui évolue, lot après lot, jamais le contrat.

Trois colonnes : ce que le chapitre demande, où c'est déjà tenu dans ce dépôt
(souvent mieux qu'exigé, parce qu'outillé par `tool/verifier_jetons.dart` plutôt
que laissé à la relecture), et l'écart réel s'il en reste un, avec le lot qui le
ferme.

| Bible | État dans ce dépôt |
| :--- | :--- |
| §0.1-0.3 hiérarchie des sources, interdits, dérogations | Ce fichier §3 et §6, même schéma |
| §7.1 aucun hardcoding visuel | **Outillé** : `tool/verifier_jetons.dart`, 26+ règles, échoue en CI |
| §7.2 couleurs via `ColorScheme` | **Tranché autrement, par écrit (ADR-019)** : `AppPalette` (ThemeExtension) est la source, `ColorScheme` en dérive dans `app_theme.dart`. L'inverse casserait le lot T. Conforme à la fin de §7.2 (« exposées via un ThemeExtension ») |
| §7.3 lightTheme ET darkTheme | **Fait au lot T3.** `AppTheme.pour(mode, brightness)` choisit entre `AppPalette.claire()` et `AppPalette.sombre()` ; `app.dart` expose `theme`, `darkTheme` et `ThemeMode.system`. Aucun composant en aval ne connaît directement l'une ou l'autre palette |
| §8 typographie par `TextTheme` | Fait, crénage outillé (`app_typography.dart`) |
| §9 échelle de spacing 4→64 | Fait (`AppSpacing`, règle `espacement-hors-echelle`) |
| §10 shape system | Fait (`app_radius.dart`, `AppRadius.enfantDe`) |
| §11 BIS composants partagés nommés | Tous existent dans `lib/core/widgets/`, plus dix-neuf autres |
| §12 dix états d'interaction | Fait, galerie `lib/features/_dev/galerie/` |
| §12, §52 ombres et bordures trop faibles | **Écart, fermé au lot T2** (cause n°3 mesurée du rejet du 11/09 : ombres à 5 %, trois surfaces dans 4 % de clarté) |
| §5.1, §6, §52 tunnel d'entrée | **Écart, fermé au lot R0** (cause n°1 : `connexion_page.dart` monte un `Scaffold` nu, hors de tout lot de reprise) |
| §14 RTL | **Fait au lot A1.** Outillé depuis B0 (`direction-non-geree`) ; testé en comportement depuis A1, pas seulement au niveau composant (galerie, depuis le lot C) : `test/icons/app_icons_rtl_test.dart` (miroir des icônes) et `test/accessibilite/rtl_echelle_texte_ecrans_test.dart` (dix-neuf écrans réels) |
| §13.2, §13.4 text scaling et clavier | **Fait au lot A1 pour §13.2, au lot de remise au vert pour §13.4.** `test/accessibilite/rtl_echelle_texte_ecrans_test.dart` (200 % sur les dix-neuf écrans réels) et `test/accessibilite/clavier_test.dart` (ordre de focus, focus visible, Échap). A1 a écrit le test d'Échap et l'a laissé rouge, faute de pouvoir lancer `flutter test` sur le poste : la touche ne fermait rien. Cause mesurée le 11/09 — `AppBottomSheet.ouvrir` fournissait son propre `transitionAnimationController`, ce qui en transférait la propriété, et le détruisait au pop au lieu du retrait ; la feuille restait affichée sur une route déjà dépopée. Voir la doc de `ouvrir` |
| §15 responsive par l'espace | Fait, `app_gabarit.dart` seul fichier autorisé à comparer une largeur |
| §16 motion | Fait, `app_mouvement.dart` |
| §18 empty/loading/error/offline | **Écart, mesuré le 11/09 au lot de remise au vert** — la ligne disait « Fait » sans que rien ne l'ait vérifié. Vide, erreur et hors ligne : faits (`EmptyState`, `OfflineBanner` porté par `PageShell`). **Chargement : `Skeleton` n'est employé que par `ADM-05`.** Né au lot C, il n'a servi qu'à la galerie jusqu'au 12/09, où `ADM-05` en a fait le premier usage réel, sur ses deux colonnes, tenu par un test. Les dix-neuf autres écrans affichent toujours un `Text` « Chargement… », parfois un `EmptyState` détourné en attente (`creneaux_page.dart`). **L'écart reste ouvert, mais il a désormais un motif à copier** : `attribution_page.dart`, `Skeleton.liste` dans la branche par défaut du `switch` sur `AsyncValue` |
| §19-32 salle, Coran structuré, présence | **Spécifié documentairement au lot N0** (ADR-020) : `docs/architecture/etape-5-salle-coran-presence.md`. Riwaya Hafs/Roi Fahd tranchée, modèle Coran structuré et machine à états de présence posés. Non codé — construction à l'étape 5 |
| §40-41 état métier / UI / préférence | Ajouté à `03-architecture-information.md` au lot B0 |
| §44 protocole avant codage | La fiche d'écran de `08-catalogue-ecrans.md` §3 |
| §45 tags de conformité | Vocabulaire fermé posé dans `lib/CLAUDE.md` au lot B0 |
| §5, §6 matrice de conteneur, zoning physique | Ajoutés à `02-regles-ux.md` et `05-regles-responsive.md` §3 au lot B0 |
| §43 anti-hallucination | ADR-001 à ADR-020, registre des questions ouvertes |
| §7, points repris de la note de refonte V1 | Section 7 ci-dessous : dix points déjà tranchés autrement, restent tranchés |

Un chapitre marqué « fait » ici et dont le code régresse plus tard est une
régression au sens de la Bible §51, pas une réouverture de discussion.

## 5. Le comité, avant d'ouvrir un fichier

Cinq questions, dans cet ordre, sur toute nouvelle fonctionnalité. Une réponse
« je ne sais pas » arrête le travail au lieu de le lancer.

1. **UX** : est-ce compréhensible sans explication ?
2. **UI** : est-ce cohérent avec ce qui existe déjà, ou est-ce que j'invente ?
3. **Produit** : est-ce réellement utile à ce rôle, à cette fréquence ?
4. **Accessibilité** : utilisable au doigt, au clavier, au lecteur d'écran, en
   arabe, à 200 % de taille de texte ?
5. **Flutter** : implémentable avec les composants existants, ou faut-il en
   ajouter un au catalogue d'abord ?

## 6. Les interdits

Repris de la note de refonte, à l'exception de ceux qui sont déjà des ADR et qui
sont listés en section 7 comme acquis.

- Ne pas inventer un écran absent du catalogue.
- Ne pas déduire une règle métier d'un choix de design.
- Ne pas transformer un rôle en application séparée.
- Ne pas écrire `if (role == ...)` dans un widget : la lecture passe par une
  capacité, jamais par un rôle en dur (`03-architecture-information.md` §2).
- Ne pas traiter le mode d'interface comme un rôle.
- Ne pas faire confiance au client pour une restriction : le routeur est une
  commodité, la RLS est la barrière (`etape-2-core-flutter.md` §3).
- Ne pas afficher une donnée brute d'erreur à l'utilisateur.
- Ne pas ajouter une couleur, une police, un rayon ou une durée hors des jetons.
- Ne pas animer une interaction fréquente au delà de 200 ms.
- Ne pas construire un écran sans ses états vide, chargement, erreur et hors ligne.

## 7. Ce que la note de refonte demandait, et qui existe déjà

À lire avant de « corriger » quoi que ce soit : plusieurs recommandations de la
note sont déjà tranchées dans ce dépôt, parfois dans l'autre sens, et pour des
raisons écrites.

| Recommandation de la note | État réel | Où |
| :--- | :--- | :--- |
| « Contradiction majeure : qui pose les créneaux, la famille ou l'enseignant ? » | **Tranchée, et ce n'est ni l'un ni l'autre exactement.** Une seule table `weekly_availability` pour les deux rôles ; la famille pose ses créneaux, l'enseignant prend **un élève**, pas un créneau, et le garde. Le créneau n'est que l'heure du rendez-vous qui en découle | ADR-017 |
| « Le mot niveau est trop restrictif » | Retenu, sans dette : le MVP-0 n'a pas d'entité niveau. Le groupe existe par `session_participants` en plusieurs-à-plusieurs, jamais par `session.student_id` | ADR-004 |
| « Une séance doit porter participants, observateurs, contenu, présence, audit » | Fait : `session_participants` M:N, contrôleur `hidden`, journal d'audit | ADR-004, ADR-011 |
| « Le mode enfant doit être un mode d'accessibilité, pas un rôle » | Fait, sous le nom **mode d'interface**, porté par le profil et pas par le rôle, seuil dans `app_config` | ADR-009, ADR-016 |
| « Les appareils sont un objet métier de premier ordre » | Fait : deux appareils par foyer, un seul en séance, garanti en base | ADR-010 |
| « Les disponibilités portent un fuseau, la base travaille en UTC » | Fait, et le piège a déjà coûté cher : `instant_creneau()` datait sa semaine par fuseau, sept jours d'écart pour le même rendez-vous | ADR-017, `etape-4-journal.md` L8 |
| « Le dashboard admin est un centre d'intervention, pas un tableau analytique » | Fait : cinq signaux, chacun mène directement à son écran d'action | `ADM-01`, `parcours-utilisateurs.md` |
| « Pas de Text-to-SQL pour l'agent IA » | Sans objet en MVP-0 : il n'y a pas d'agent IA dans le périmètre | ADR-003 |
| « Messagerie contextuelle, pas un chat générique » | **Pas encore construit, et pas encore spécifié.** Inscrit au registre des questions ouvertes pour que le premier écran de messagerie ne parte pas en chat générique | `decisions.md`, question 18 |
| « Modèle d'événements explicite » | Partiel : `audit_logs` existe et est alimenté, la liste nommée des événements n'est pas figée | `decisions.md`, question 19 |

## 8. Ce que la refonte change vraiment

Trois choses, et elles sont toutes dans `01-systeme-visuel.md` :

1. **Le fond général passe du rose poussiéreux au crème**, et cesse d'être la
   seule surface du produit. Trois surfaces au lieu d'une, avec une échelle
   d'élévation.
2. **Les couleurs de marque cessent d'être posées en aplats saturés.** Chaque
   famille reçoit une teinte douce et une encre foncée, de la même teinte. Un
   avertissement devient un fond ambre pâle avec du texte brun, pas un pavé
   `#FFB703`.
3. **La typographie française change**, l'arabe ne change pas.

La palette de marque, elle, est **conservée** : les cinq couleurs d'origine sont
toutes encore là, avec leurs rôles précisés. Aucune teinte nouvelle n'est
introduite.

## 9. Ordre de travail

La note de refonte V1 proposait dix étapes. Six d'entre elles sont ce dossier, et
elles sont faites. Le rendu mobile déployé après le lot R3 a ensuite été jugé
« plus nul que du générique » (11 septembre 2026) : la Bible Frontend V2 est la
réponse à ce jugement, et son adoption (ADR-019) rouvre l'ordre de travail avec
les lots B0, T2, R0, T3, A1 et N0 insérés avant la suite. L'ordre complet :

```
[fait] Audit du code et des specs existantes
[fait] Architecture des rôles et de l'information   03
[fait] Système visuel                                01
[fait] Système de composants                         07
[fait] Système de mouvement                          04
[fait] Système responsive et web                     05
[fait] Catalogue d'écrans                             08
[fait] Lot T : jetons, thème, typographie             → lib/core/theme/
[fait] Lot C : composants du catalogue                → lib/core/widgets/
[fait] Lot R1-R3 : ELV-02, TUT-01, ENS-02, ADM-01     → lib/features/
[fait] Lot B0 : ancrage de la Bible V2 (ADR-019)      → ce dossier, decisions.md, verifier_jetons.dart
[fait] Lot T2 : durcir le langage (ombres, bordures, bouton désactivé)
[fait] Lot R0 : tunnel d'entrée (zone Accès du catalogue 08)
[fait] Lot T3 : mode sombre (§7.3)                    → app_palette.dart, app_theme.dart, app.dart
[fait] Lot R4 : reste de l'existant (TUT-02, TUT-04, TUT-05, ENS-06, ADM-02, ADM-06)
[fait] Lot A1 : accessibilité, RTL et clavier prouvés par des tests
[fait] Lot N0 : specs de l'étape 5 (ADR-020, Coran structuré, machine à états de présence)
[dette indépendante] Lot L10 : clôture de l'étape 4 (0006, PROGRESS.md, 17 scénarios)
```

Le lot T se fait en premier et se fait **entièrement** : reprendre les écrans
avant les jetons obligerait à les reprendre deux fois. Même logique pour B0 :
poser le vocabulaire et les règles machine de la Bible avant de reprendre un
écran de plus évite de reprendre ce même écran une deuxième fois.

### Ce que le lot T a livré, et ce qu'il n'a délibérément pas touché

Livré, le 7 septembre 2026 : la palette entière en trois registres, les trois
bordures, les quatre encres, l'échelle d'espacement étendue, les cinq rayons,
les quatre élévations, le budget de mouvement, la typographie française
remplacée avec son crénage et ses axes variables, et sept règles de
vérification. Compte rendu dans `docs/architecture/etape-2-journal.md`.

**Non touché, et c'est le lot C qui s'en charge** : les onze composants
partagés emploient les nouveaux noms de jetons mais gardent leurs usages
d'avant. Une tuile Bento est toujours posée sur `surfaceCanvas` et non sur
`surfaceRaised`, une case vide de grille n'a toujours pas son fond enfoncé,
aucun composant ne porte encore d'ombre. Le produit a donc le bon vocabulaire
et pas encore la bonne profondeur : c'est voulu, un renommage et une reprise
d'usage ne se relisent pas ensemble.
