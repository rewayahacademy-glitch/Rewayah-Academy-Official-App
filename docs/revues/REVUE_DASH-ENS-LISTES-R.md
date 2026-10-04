# Revue DASH-ENS-LISTES : ACCEPTÉE AVEC RÉSERVES

## Verdict
**Acceptée avec réserves.** Il ne reste que trois défauts mineurs (un libellé orphelin, une limite serveur antérieure qui est consignée, des remplacements passés non filtrés). Aucun n'est bloquant ni majeur.

Ce qui est vérifié :

| Point de la fiche | Ce qui est livré | Ce que j'ai vu |
| :--- | :--- | :--- |
| Remplacements sur la Journée | 3 au plus, triés par date de début | `maximumRemplacements = 3`, `trierRemplacements` |
| « Voir tout » | Sous la 3ᵉ carte, mène à `/enseignant/journee/remplacements` | Route `remplacements` sous la Journée ; libellé `tuteur.accueil.voirTout`, réemploi prévu par DASH_STRATEGIE l.464 ; libellé vocal avec le nombre |
| Alertes sur la Journée | 2 alertes, puis un lien « Voir l'autre alerte » ou « Voir les N autres alertes » vers `/enseignant/journee/alertes` | L'exception D6 b tombe |
| Page « Remplacements confirmés » | États vide, contenu et hors ligne | Bandeau hors ligne fourni par PageShell |
| Page « Alertes utiles », 5 états | Chargement : Skeleton<br>Erreur des séances : K-59 et Réessayer<br>Erreur de présence : jamais « aucune alerte » (J3, D10)<br>Vide<br>Contenu<br>Hors ligne | Comportements confirmés |
| Retour | Revient à la page précédente, ou à la Journée en accès direct | `_retourVersJournee` |
| 7 libellés | Déclarés dans `tool/libelles_sources.json` | Présents |
| Règles de conception | Jetons Ecart, AlignmentDirectional (RTL), aucune couleur ni taille en dur | Respectées |
| Périmètre | Aucun branchement serveur, aucune lecture de rôle | Respecté |

`alertesPresence` est devenue une fonction pure. Sur la Journée, une présence illisible reste silencieuse, comme avant.

## Périmètre et commandes
Périmètre : `origin/corrections/c2-ens-route..origin/corrections/c2-ens-listes`, deux commits (87864bdf, cd0f5988). Diff lu en entier (PNG exclus) :
- `journee_page.dart`
- `app_router.dart`
- `routes.dart`
- `fr.i18n.json`
- `libelles_sources.json`
- `parcours_enseignant_test.dart`
- le script de capture

Résultats :
- **Analyse** : `dart analyze --fatal-infos` ne signale rien.
- **verifier_revue** : 1627 violations sur la tête comme sur la base, et le diff des deux listes est vide.
- **verifier_jetons** : 39 sur la tête comme sur la base.
- **Tests du routeur** : `parcours_enseignant_test.dart` donne +32, tout passe. Les 14 tests du lot sont dedans, tous sur le vrai routeur, dont 3 à 320 px avec texte doublé et vérification `aucun_mot_coupe`.
- **Non-régression** (journee, rtl_echelle, navigation_reelle, demo_enseignant, q01) : +150, tout passe.

## Contre-épreuves (refaites par moi)
1. **Ancien code remis** sur les trois fichiers lib : le test ne compile plus. C'est un échec réel, mais trivial.
2. **Plus de borne ni de tri sur les remplacements** : 2 tests échouent.
3. **Lien « autres alertes » retiré et garde « présence illisible » neutralisée** : 2 tests échouent.

Les tests prouvent donc bien le comportement livré.

## Défauts
- **Mineur.** `assets/i18n/fr.i18n.json:3073` : `enseignant.journee.autresAbsences` n'est plus utilisé dans lib. Ce libellé est orphelin et devrait être retiré.
- **Mineur, serveur (consigné).** `ListeRemplacementsPage` lit `remplacementsConfirmesProvider`, une mémoire de session qui démarre vide (`absence_remplacement.dart:121-136`). Après un rechargement, la page dit « Aucun remplacement confirmé » même si le serveur en a. La limite est antérieure (BR-1 non branché), et le doc-comment le dit honnêtement.
- **Mineur.** Les remplacements déjà passés ne sont pas filtrés : ils restent affichés et comptent dans « Voir tout ». C'était déjà le cas avant et la fiche n'en parle pas.

## Captures vues
- **Journée** à 320 px avec texte doublé (lue en 4 tranches) et à 1440 px clair.
- **Alertes** à 320 px avec texte doublé, en sombre ; état d'erreur à 390 px en sombre.
- **Remplacements** à 1440 px.

Aucun mot coupé, aucun chevauchement, aucun texte trop petit, aucun élément collé. Deux remarques cosmétiques, toutes deux antérieures au lot : la flèche de LienFleche ne grandit pas avec le texte, et « Yasmine n'est pas entré » garde son accord connu.

## Pour accepter sans réserve
1. Retirer `enseignant.journee.autresAbsences` de `fr.i18n.json`, puis régénérer avec slang.
2. Côté serveur, plus tard : brancher une vraie source des remplacements confirmés (BR-1). Il faudra alors un état de chargement et d'erreur sur `ListeRemplacementsPage`, et décider s'il faut masquer les remplacements passés.

## Contre-revue adverse

Verdict confirmé : oui. Verdict final retenu : **ACCEPTEE_AVEC_RESERVES**.

Je confirme le verdict ACCEPTEE_AVEC_RESERVES : je n'ai trouvé aucun défaut bloquant ni majeur.

Diff relu en entier (lib, router, i18n, tool) :
- Les 7 libellés nouveaux sont déclarés dans tool/libelles_sources.json, et je ne vois aucune valeur en dur.
- Je ne vois aucun branchement serveur : les deux pages lisent les providers déjà en place.
- D6 est respecté (DASH_STRATEGIE sur origin/corrections/c2-dash1, l.66 et 216) : 3 cartes au plus, triées par début, puis un lien « Voir tout ». L'exception D6 b tombe parce que la page des alertes existe désormais (ligne DASH-ENS-ALERTES).
- Le « Voir tout » est placé hors de la carte, donc pas de bouton dans un bouton. Sa cible fait 48 par Pressable (lien_fleche.dart).
- Page des alertes : une présence `null` y devient une erreur et non « aucune alerte ». C'est juste, puisque service_presence.dart:215-217 définit `null` comme « indisponible ». Ce choix est cohérent avec J3 et D10.
- La Journée garde son comportement : une présence illisible n'y produit aucune alerte.

Régression hors du lot :
- La démo enseignant ne peut atteindre aucun des deux liens. Elle n'a qu'une offre de remplacement, sa présence vaut `null` pour toutes les séances, et ses séances sont à venir à 16 h.
- journee_test.dart ne dépend pas du texte retiré « et N autres élèves ».

Tests : j'ai relancé test/router/parcours_enseignant_test.dart avec --concurrency=2 et obtenu +32, tout passe. Les contre-épreuves sémantiques du premier relecteur visent bien les gardes du lot.

Captures : j'en ai ouvert d'autres que lui, et je n'y vois ni chevauchement, ni mot coupé, ni état manquant :
- journee_contenu_390_sombre
- journee_contenu_1440_clair
- alertes_contenu_1440_clair
- alertes_vide_390_clair
- remplacements_vide_390_clair

Ses trois réserves mineures sont réelles. L'une relève du serveur et elle est consignée : remplacementsConfirmesProvider n'est qu'une mémoire de session. J'ajoute deux mineurs :
1. Le nom accessible de « Voir tout » ne contient pas le texte visible (WCAG 2.5.3).
2. Aucun test ne couvre le singulier « Voir l'autre alerte » ni le RTL des nouvelles pages.

Le worktree cr-7 est retiré.

- Défaut manqué (mineur) — lib/features/journee/journee_page.dart (_AvecVoirTousRemplacements, ~l.388-396) : Le lien affiche « Voir tout », mais son nom pour le lecteur d'écran est « Voir les {nombre} remplacements confirmés » (libelleSemantique), qui ne contient pas le texte visible. Cela enfreint le critère WCAG 2.5.3 (libellé visible inclus dans le nom accessible) : une personne qui pilote à la voix et dit « Voir tout » ne déclenche pas le lien. La règle n'est pas écrite dans docs/current, d'où la gravité mineure.
  Preuve : diff 87864bdf : libelle: t.tuteur.accueil.voirTout ; libelleSemantique: t.enseignant.journee.voirTousRemplacements(nombre: ...). LienFleche passe libelleSemantique ?? libelle à Pressable et exclut le texte visible de l'arbre sémantique (ExcludeSemantics), lib/core/widgets/lien_fleche.dart.
- Défaut manqué (mineur) — test/router/parcours_enseignant_test.dart (groupe DASH-ENS-LISTES) : Aucun test ne couvre le cas d'une seule alerte cachée (libellé singulier « Voir l'autre alerte », autres == 1), ni les deux nouvelles pages en RTL. Le code emploie bien des alignements directionnels, mais aucun test ne le prouve.
  Preuve : Les 12 testWidgets du groupe (lignes 156 à 371 du diff) portent sur 5 alertes (3 autres), sur 2 ou moins, et sur 320 px à 200 %. Aucun ne vérifie voirAutreAlerte ni Directionality RTL.
