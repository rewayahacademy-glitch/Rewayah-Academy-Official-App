# Plan d'exécution - Étape 2
## Core Flutter, thème, cache local et routeur

Spécification à destination de l'agent de code, sans implémentation. S'appuie sur les tokens de couleur et les composants déjà validés dans les maquettes de `docs/produit/parcours-utilisateurs.md`. **Références complètes : `docs/produit/design-tokens.md`** (palette, polices, icônes, éthique, copywriting).

---

## 1. Système de thème

### Correction des paires de couleurs

> ⚠ **Le tableau de jetons qui figurait ici est périmé depuis l'ADR-018,
> 7 septembre 2026.** Il donnait `surfaceBase` à `#F1E3E4`, un seul
> `borderDefault` et quatre polices dont deux ont été remplacées. La liste
> vivante est dans **`docs/produit/design-tokens.md`**, source unique, et les
> règles d'emploi dans **`docs/design/01-systeme-visuel.md`**.
>
> Ce qui reste vrai de cette section, et qui compte : le principe des paires.

Le thème n'expose jamais une couleur seule : il expose des **paires**
`(fond, texte)`, pour que l'erreur de contraste devienne structurellement
impossible plutôt que dépendante de la vigilance de qui écrit l'écran.

**Règle d'API** : le thème n'expose pas `AppColors.success` en couleur nue. Il expose un objet `AppColorPair` avec `.background` et `.onBackground`, consommé ensemble. Un widget qui prend une seule des deux valeurs sans l'autre est un signal de revue de code à corriger avant fusion.

Les jetons sans fond, encres et bordures, passent par `AppInkColor`, qui n'expose aucune couleur brute et ne peut donc pas servir de fond.

### Typographie et espacement

Référence complète : `docs/produit/design-tokens.md` (§2 Polices, §7 Espacement, §8 Rayons, §9 Élévation, §10 Crénage).

Quatre polices, pas plus : deux pour l'arabe, inchangées depuis l'étape 2, et deux pour le français, **remplacées par l'ADR-018**. Le tableau des familles, de leurs axes variables et de leurs licences est dans `design-tokens.md` §2 ; il n'est pas recopié ici, il divergerait.

Échelle d'espacement fixe, étendue par l'ADR-018 : 4, 8, 12, 16, 20, 24, 32, 40, 48, 64. Aucune valeur ponctuelle en dehors de cette échelle.

Deux échelles typographiques, pas une seule modulée par `fontSize` libre : une échelle standard pour les rôles adultes, une échelle agrandie d'environ 20% pour le mode enfant, appliquée par un `TextTheme` distinct et non par des multiplicateurs dispersés dans les écrans.

## 2. Composants partagés

Ces composants sont à écrire une fois, dans `lib/core/widgets/`, et deviennent obligatoires partout où leur usage s'applique. Aucun écran ne réimplémente son propre bouton ou sa propre carte.

| Composant | Rôle | Exigence |
| :--- | :--- | :--- |
| `Pressable` | Seul point d'entrée du retour tactile | Échelle 0.96, 120 ms, haptique `mediumImpact`, aucun `onTap` nu ailleurs dans le code |
| `BentoTile` | Bloc de grille, variantes full, half, third, quarter | Cible tactile 72pt minimum en mode enfant, 44pt en mode standard |
| `AvatarTile` | Photo de profil enfant avec repli sur initiales | Charge l'image via URL signée, jamais une URL stockée en dur. Repli visuel identique en cas d'échec de chargement, jamais une icône d'erreur brute |
| `AudioLabel` | Bouton haut-parleur qui rejoue un libellé audio | Utilisé partout où le zéro-lecture s'applique, voir section 1.2 de l'audit |
| `PermanentNotice` | Le bandeau "cours enregistré, visite de contrôle possible" | Un seul composant partagé entre `ELV-03` et `ENS-03`, pour garantir qu'il ne peut jamais afficher un texte différent selon l'écran, ce qui casserait l'ADR-011 |
| `PinPad` | Pavé numérique géant | Ne transmet jamais sa valeur au-delà de la vérification locale, voir ADR relatif à l'authentification enfant |
| `EmptyState` | État vide illustré avec message d'invitation | Obligatoire dès qu'une liste peut être vide, jamais un simple texte "aucune donnée" |
| `OfflineBanner` | Bandeau de dégradation réseau | Un seul composant, calibré une fois, jamais réécrit par écran |
| `ChoiceCardGroup` | Sélection par cartes avec repli "Autre" en saisie libre | Seul point d'entrée pour tout choix proposé à l'utilisateur, dans l'onboarding et ailleurs (ADR-013) |

**`PermanentNotice` mérite un soin particulier.** Puisque l'ADR-011 repose sur le fait que ce bandeau ne change jamais, le composant ne doit accepter aucun paramètre qui permettrait de le masquer ou de le modifier selon la présence d'un contrôleur. Si un tel paramètre existe dans l'API du composant, quelqu'un finira par s'en servir.

## 3. Routeur

Un seul routeur, pour toutes les plateformes, puisque le Web est ouvert à tous les rôles (ADR-008). Aucune branche de navigation par plateforme.

### Principes

- Redirection décidée par l'état du compte et le rôle lus depuis la session, jamais par une simple vérification de présence de jeton.
- Un compte en portail d'attente ne peut atteindre aucune route protégée, quelle que soit l'URL tapée directement dans un navigateur. La protection réelle reste la RLS de l'Étape 1 ; le routeur n'est qu'une commodité d'expérience, jamais la barrière de sécurité elle-même.
- Aucune route de salle de session n'est partageable ou mémorisable en favori. Conformément à l'ADR-005, l'URL de la salle est éphémère et régénérée à chaque entrée, jamais une adresse stable qu'on pourrait rouvrir plus tard.
- Le mode d'interface, enfant ou standard, ne crée pas deux arborescences de routes distinctes. Il change ce qu'un même écran affiche, pas la structure de navigation elle-même. Deux arborescences dupliquées finissent toujours par diverger silencieusement.

### Carte des sections, reprise du modèle de navigation déjà fixé

| Rôle | Route racine | Profondeur |
| :--- | :--- | :--- |
| Élève, mode enfant | Écran unique, pas de barre de navigation | 0 |
| Élève, mode standard | Trois sections | 1 |
| Tuteur | Quatre sections | 1 à 2 |
| Enseignant | Trois sections | 1 à 2 |
| Contrôleur | Une liste | 1 |
| Admin | Quatre sections | 1 à 2 |

## 4. Cache local et mode hors ligne

Reprend les choix de l'audit (section 2.1), affinés pour l'Étape 2.

### Moteur

Drift pour toute donnée interrogeable : profils, planning, cahiers de transmission en file d'attente. `flutter_cache_manager` pour les médias : pages du mushaf, photos de profil. `flutter_secure_storage` pour les secrets : jeton d'appareil, hash du PIN.

### Schéma Drift, en miroir partiel du schéma Supabase

Pas de duplication complète. Seules les tables consultées hors ligne existent en local : profils du foyer, sessions à venir sur sept jours glissants, pages du mushaf déjà consultées, et une table de file d'attente locale pour les cahiers de transmission non encore synchronisés.

### Photos de profil en cache

Puisque l'ADR-012 impose des photos réelles, leur mise en cache local demande une règle explicite : l'image est mise en cache **après** son passage par la compression serveur, jamais l'original. Le cache local ne conserve donc jamais un fichier plus lourd que celui déjà réduit côté serveur, ce qui borne l'espace disque consommé sans effort supplémentaire côté client.

Suppression du cache local obligatoire dans les 24 heures suivant un remplacement ou une suppression de photo côté serveur, déclenchée par un événement de synchronisation plutôt que par une simple expiration de durée, pour qu'un parent qui retire une photo ne la retrouve pas encore affichée trois jours plus tard sur l'appareil de l'enfant.

### File de synchronisation du cahier de transmission

C'est le seul besoin d'écriture hors ligne réel du produit (audit 2.1). Chaque rapport rédigé sans réseau reçoit une clé d'idempotence générée localement, écrite dans Drift avec un statut `en_attente`, puis rejouée dès le retour du réseau. La contrainte d'unicité C9 de l'Étape 1 protège contre un double envoi si la synchronisation se déclenche deux fois par accident.

## 5. Internationalisation

Chaînes externalisées dès l'Étape 2, français par défaut. Convention de clé stable dès le départ, par exemple `eleve.accueil.rejoindre`, pour qu'ajouter une langue plus tard ne demande aucune reprise de code, seulement le remplissage des fichiers.

**Correction du 6 septembre 2026 (ADR-015).** Cette section demandait à l'origine des fichiers poular préparés mais vides. L'opérateur a tranché : **pas de poular dans l'application**. Les langues déclarées sont le français, rempli, et l'arabe, vide, l'application étant bilingue arabe-français d'après `design-tokens.md` section 2.

Moteur retenu : `slang`. L'outil officiel `gen_l10n` n'accepte pas les points dans les clés et aurait forcé à abandonner la convention ci-dessus.

**Les libellés audio suivent la même logique que les chaînes textuelles**, avec une clé identique pointant vers un fichier son plutôt qu'une chaîne. Le composant `AudioLabel` de la section 2 consomme cette même clé, pour que texte et audio restent synchronisés dans un seul système plutôt que deux.

## 6. Performance

Budget de démarrage à froid sous 1,5 seconde. `--split-debug-info` activé. Polices en sous-ensembles, réduites aux glyphes réellement utilisés par le français et par les libellés d'interface.

## 7. Scénarios de test d'acceptation

1. Un texte rendu avec `surfaceSuccess` ou `surfaceWarning` en fond n'utilise jamais de texte blanc, vérifié par une règle d'analyse statique et non par une relecture manuelle.
2. `PermanentNotice` n'accepte aucun paramètre de visibilité conditionnelle dans son API publique.
3. Une route protégée demandée directement par URL sur un compte en portail d'attente redirige systématiquement, y compris sur Web.
4. Une photo de profil supprimée côté serveur disparaît du cache local de tout appareil appairé dans les 24 heures.
5. Un cahier de transmission rédigé hors ligne, puis synchronisé deux fois par accident au retour du réseau, ne produit qu'une seule ligne en base.
6. Le mode enfant et le mode standard partagent la même arborescence de routes, vérifiable par l'absence de tout fichier de routes dupliqué entre les deux modes.
7. Démarrage à froid mesuré sous 1,5 seconde sur un appareil d'entrée de gamme.

## 8. Définition de fin d'étape

- Le thème n'expose aucune couleur nue, uniquement des paires.
- Les **dix** composants partagés existent et sont les seuls points d'entrée de leur fonction respective dans le code. Cette ligne disait « huit », puis « neuf » : la section 2 en listait bien neuf depuis que l'ADR-013 y a ajouté `ChoiceCardGroup`, et l'étape 3 a sorti `ActionPrincipale` de l'intérieur d'`EmptyState`, ou le seul bouton du produit vivait cache (ADR-016).
- Le routeur est unique, sans branche par plateforme.
- Le schéma Drift correspond exactement à la liste de la section 4, ni plus ni moins.
- Les sept scénarios de test passent.

**État réel : voir `docs/architecture/etape-2-journal.md`.** Six scénarios sur sept sont verts. Le septième, le démarrage à froid sous 1,5 seconde, n'est toujours pas mesuré et n'est donc pas coché : ni l'étape 2 ni l'étape 3 n'ont d'écran métier à charger, un portail d'attente ne dit rien du produit. Le premier candidat honnête est `ELV-02`, à l'étape 4.

---

## Ce qu'il me faut avant de spécifier l'Étape 3

Rien de bloquant. Une seule chose à confirmer : le format de compression des photos de profil, WebP étant le choix par défaut cohérent avec le reste du produit (déjà retenu pour les images ailleurs dans vos specs), sauf préférence contraire de votre part.
