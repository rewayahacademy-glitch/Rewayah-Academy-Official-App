# Rewayah — baseline frontend Codex

Relevé du 13 septembre 2026, avant modification Dart. Lot demandé : **R1, design system adaptatif et galerie interne**. Les anciens lots également nommés R1 dans le journal ne désignent pas ce lot.

## Source et isolation

- Dépôt actif : `D:\RA _APP\RA -OFFICIAL-APP`, branche `main`, HEAD initial `6d06d3947059c80b2c021123f15befadc05f6f32`.
- Worktree Codex : `C:\Users\dell\AppData\Local\Programs\WindowsTerminal\rewayah-r1`, branche `codex/r1-adaptive-design-system`, même commit de départ.
- Les worktrees `D:\ra-pwa-build`, `D:\ra-pwa-ctr`, `D:\ra-pwa-fix` sont des checkouts détachés de lots antérieurs ; aucun ne constitue une branche UI actuelle à reprendre.
- `AGENTS.md` et `REFONTE_CONTEXT.md` ne sont pas présents à la racine du dépôt actif lors du relevé. Leurs copies persistantes `C:\Users\dell\.codex\rewayah\` ont été lues intégralement via la skill `rewayah-context`. La demande actuelle prime sur les clauses historiques contradictoires.
- Instructions locales lues : `D:\RA _APP\CLAUDE.md`, `CLAUDE.md`, `lib/CLAUDE.md`, `CODEX.md`. Recherche récursive : aucune autre instruction frontend AGENTS/CLAUDE ; `supabase/CLAUDE.md` est hors du périmètre d'écriture.
- Références inspectées selon leur pertinence : brief du parent, HANDOFF, DÉMARRER ICI de PROGRESS, ADR frontend, Bible V2, constitution design, journal et spécification core Flutter, tokens existants. Ces documents historiques ne prouvent ni le rendu actuel ni les résultats actuels des tests.

## Stack vérifiée

| Élément | État réel |
| --- | --- |
| Flutter local | 3.47.2 stable, révision `d3b14c8769` |
| Dart local | 3.13.2 ; contrainte du manifeste `^3.13.2` |
| Application | `rewayah_academy`, version `0.2.0+1` |
| État | `flutter_riverpod` 3.4.3, `NotifierProvider`, `FutureProvider`, familles et services injectés |
| Routeur | `go_router` 18.0.1 ; unique `routeurProvider` dans `lib/core/router/app_router.dart` |
| Autres contrats | Supabase Flutter 2.17.2, LiveKit 2.12.0, Drift 2.34.4, slang 4.19.1 |
| Travail concurrent | Ajout Sentry Flutter 8.14.2 dans manifeste/verrou non validés ; non repris par Codex |

`pubspec.yaml` et les dépendances/verrou SDK de `pubspec.lock` ont été inspectés. Aucune mise à niveau prévue.

## Thèmes et composants existants

`AppTheme.pour(InterfaceMode, Brightness)` fournit déjà Material 3, clair/sombre et mode enfant. `AppPalette` et `AppMetriques` sont des ThemeExtension ; ColorScheme dérive des paires `AppColorPair`. Les surfaces actuelles sont crème `#F8F4EE`, blanc et beige en clair ; charbon `#1C1D21`, brun `#302E29` et noir chaud en sombre. Le primaire réel est bien `#8652E6`, y compris en sombre.

Tokens existants : `app_palette.dart`, `app_color_pair.dart`, `app_typography.dart`, `app_spacing.dart`, `app_radius.dart`, `app_elevation.dart`, `app_mouvement.dart`, `app_gabarit.dart`, `app_metriques.dart`, `app_theme.dart` sous `lib/core/theme/`.

Polices embarquées : Instrument Sans (corps), Bricolage Grotesque (titres), Noto Sans Arabic (UI arabe), Uthman Taha Naskh (documents/Coran). Icônes Phosphor locales. Aucun téléchargement runtime à ajouter ; la police documentaire reste protégée.

Les neuf composants demandés sont réellement présents dans `lib/core/widgets/` : **Pressable, BentoTile, AvatarTile, AudioLabel, PermanentNotice, PinPad, EmptyState, OfflineBanner, ChoiceCardGroup**. Leurs signatures et implémentations ont été inspectées. Autres équivalents : `ActionPrincipale` (quatre niveaux d'action), `AppCard`, `FilterPill`, `StatusPill`, `Skeleton`, `SignalRow`, `DataCollection`, `PageShell`, `NavShell`, `PageImmersive`, `AppBottomSheet`.

Galerie existante : `lib/features/_dev/galerie/{galerie_page,catalogue_galerie}.dart`. Liste extérieure paresseuse ; conditions largeur, RTL, 200 %, mouvement réduit et enfant. **Le thème des aperçus est explicitement forcé en clair.** Le catalogue comprend aussi des composants métier (présence, semaine, journée) : ne pas réimplémenter leur logique dans R1.

## Routes connectées et contrats

Le routeur relie effectivement connexion adulte/enfant, inscription, attente/accusé/contrat/pièce, accueil élève, lecteur Coran, accueil famille, disponibilités famille, réglages enfant, appareils/ajout/appairage, journée enseignant, créneaux enseignant, planning contrôleur, tableau admin/dossiers/attribution/journal/demandes, salle et galerie conditionnelle. Au HEAD initial, suivi élève, suivi tuteur, profil enseignant et comptable rendent encore `EcranAConstruire` ; la racine a aussi un écran transitoire. Cela décrit le raccord de code, pas une validation fonctionnelle de ces parcours.

- `sessionProvider` : `SessionState` synchrone (`porte`, profil, rôle, mode) depuis `SourceSession.etats()`. Le routeur écoute les changements via `refreshListenable` ; `_CoquilleNavigation` sélectionne seulement `interfaceMode`. `RewayahApp` observe encore la session entière.
- `ServicePlanning` : `monFuseau`, `disponibilites(profilId)`, `poser`, `retirer`, `seances`, `affectations` ; providers typés et `AsyncValue`. Lectures `weekly_availability`, `mes_seances_v`, `mes_affectations_v`.
- `ServiceMatching.prendre(eleveId, creneau)` appelle `prendre_eleve`. L'interface des propositions administratives versionnées/idempotentes n'est pas fournie par ce contrat.
- `OfflineBanner` observe `horsLigneProvider` ; une galerie autonome doit remplacer cette lecture par un état local sans service réseau.
- Les services de présence, vidéo, auth, cache et Coran sont consommés uniquement pour comprendre leurs contrats ; aucun changement prévu.

## Cohabitation : fichiers protégés

Git ne prouve pas l'identité de l'auteur d'un changement non validé. Tous les changements présents sont attribués conservativement à l'autre travail, jamais à Codex.

Au premier relevé : `dart_define.example.json`, `lib/app.dart`, `lib/main.dart`, `lib/core/config/env.dart`, `pubspec.yaml`, `pubspec.lock`, `lib/core/cache/db/app_database.g.dart`, `windows/flutter/generated_plugin_registrant.cc`, `windows/flutter/generated_plugins.cmake` ; non suivis : `CODEX.md`, `lib/core/observabilite/`, `lib/features/_dev/playground/`, `test/observabilite/`.

Pendant l'audit, de nouveaux changements sont apparus : `docs/design/08-catalogue-ecrans.md` (TUT-06), `assets/i18n/fr.i18n.json`, `lib/core/presence/service_presence.dart`, `lib/core/suivi/`, `lib/features/suivi_foyer/`. **Le dépôt est activement modifié.** Le routeur peut devenir un point d'intégration du suivi et reste donc hors du lot Codex.

Protection permanente : Supabase et tous ses SQL/RLS/Edge Functions, repositories, entités et providers métier, finances/paiements, présence, LiveKit, Coran, synchronisation et auth, quels que soient leurs dossiers. `main.dart`, `app.dart`, `env.dart`, routeur, manifestes, traductions générées, catalogue d'écrans et fichiers ci-dessus restent intacts dans le checkout partagé.

Fichiers candidats R1, propres aux relevés Git : les tokens existants de `lib/core/theme/` ; `pressable.dart`, `app_card.dart`, `bento_tile.dart`, `action_principale.dart`, `choice_card_group.dart`, `filter_pill.dart`, `status_pill.dart`, `empty_state.dart`, `offline_banner.dart`, `avatar_tile.dart`, `pin_pad.dart` ; la galerie versionnée ; leurs tests sous `test/theme/` et `test/widgets/`. Modifications exclusivement dans le worktree ; signatures publiques préservées ou enrichies par paramètres facultatifs.

## Écarts constatés dans le code

| Sujet | Constat statique actuel | Cible R1 / lot ultérieur |
| --- | --- | --- |
| Seuils | `<600`, `600..1024`, `>1024` ; rail 88, latéral 240 | Tokens 600/840/1200, rail 80, drawer 256 ; nouveau chrome réel réservé à R2 |
| Marges | 20 / 32 / 48 | 16 / 24 / 32 |
| Navigation | Widgets personnalisés, quatre destinations max, colonne latérale non défilante | Risque de manque de hauteur/texte 200 % ; raccord adaptatif R2 |
| Surface/typo | Palette chaude et deux familles françaises par écran ; tailles différentes de §6 | Paires §6, famille UI réutilisée, échelles exactes |
| Contrôles | Adulte min 44, rayon bouton/champ 12 | Min 48, bouton 52, rayon 16 |
| Ombres | AppCard/BentoTile niveau1 par défaut, choix sélectionné niveau2, ombres aussi en sombre | E0 standard/liste, E1 unique dominante, aucune ombre sombre |
| Pressable | Scale 0,96, 120 ms, haptique moyen systématique ; réduction du mouvement non consultée | Scale 0,98/100 ms sur choix, focus externe, réduction respectée |
| Choix | Carte « Autre » toujours ajoutée, saisie libre | Choix fermés sans saisie libre ; contrat existant à préserver avec option explicite |
| Puces | FilterPill impose une ligne avec ellipsis | Libellés complets et reflow |
| Galerie | Aperçus en clair seulement ; `GALERIE` suffit à ouvrir la route même dans un build release | Accès de démonstration verrouillé en production, sans modifier l'auth ni Env concurrents |
| PIN enfant | Touches de 100,8 et marges horizontales : rangée >348 avant padding de page | Vérifier à 360/390 et 200 % ; présentation seulement |

Ce sont des écarts de source et des risques de layout calculés. Aucune capture actuelle n'a encore validé leur rendu ; les anciennes captures ne sont pas employées comme preuve.

## Pivot des horaires : points à ne pas reproduire

`DisponibilitesPage._basculer` (`lib/features/disponibilites/disponibilites_page.dart`) appelle `ServicePlanning.poser/retirer`, donc écrit/supprime `weekly_availability`. `CreneauxPage._prendre` (`lib/features/creneaux/creneaux_page.dart`) appelle la prise libre d'élève ; la journée enseignant observe aussi le feed. La grille de semaine est réutilisée par l'ancienne galerie. Ces fichiers mixtes restent protégés : aucune correction backend ni réécriture d'écran R1. Les nouveaux exemples d'horaires représentent uniquement des propositions administratives synthétiques, sélection locale et confirmation distinctes, sans date libre ni promesse de réservation.

## Performance : faits et hypothèses

- Aucun benchmark profile obtenu à ce stade ; aucune cause du lag confirmée.
- Hypothèses à mesurer : ombres multiples des cartes/lignes ; cartes créées avidement dans des `Column` sous `PageShell` ; minuteurs de page chaque minute dans les accueils et journée ; tri de la file administrative et `VuePlanning.depuis` depuis `build()` ; `Image.network` d'AvatarTile sans taille de décodage ; pulsation récurrente du cours imminent élève.
- Nuances vérifiées : `DataCollection` et la liste de galerie utilisent `ListView.builder` ; minuteurs et contrôleurs examinés disposent de leur annulation/libération. Le scan ciblé n'a pas trouvé de BackdropFilter, `shrinkWrap: true`, IntrinsicHeight ou `antiAliasWithSaveLayer` dans les écrans/widgets inspectés. Cela ne prouve pas l'absence de toute fuite.
- Windows, Chrome 152 et Edge 151 sont détectés par Flutter. Aucun mobile physique connecté. Disponibilité d'un device ne signifie pas exécution réussie ni plateforme testée.
- Une tentative profile isolée et synthétique doit précéder tout travail qualifié d'optimisation. Aucun changement média, base ou moteur Coran prévu.

## Vérification initiale et plan exact R1

`C:\flutter\bin\flutter.bat --version` : 3.47.2 / Dart 3.13.2. `flutter analyze --no-pub` dans le dépôt actif : **No issues found**, 240,2 s. Analyse exécutée avec autorisation hors sandbox après absence de sortie de la tentative confinée ; celle-ci a été arrêtée. Ce résultat porte sur l'état observé pendant cette analyse, pas sur les fichiers ajoutés ensuite par l'autre session.

Tests déjà présents : contraste clair/sombre, typographie, élévation, mouvement, composants/catalogue, clavier, RTL/200 %, routeur et écrans. Aucun test golden ni `matchesGoldenFile` trouvé par recherche ciblée ; pas d'installation d'un nouveau système golden prévue.

1. Isoler le commit actuel, consigner les changements concurrents, résoudre les dépendances sans mise à niveau et analyser le worktree avant toute modification Dart. Si cette analyse échoue, arrêter au document de baseline conformément à la demande.
2. Adapter **les tokens et ThemeExtension existants** à §6 ; conserver la marque, les API et le rendu documentaire Coran. Ajouter les contraintes de largeur et quatre classes de largeur dans le système existant, sans modifier NavShell/routeur.
3. Adapter les primitives existantes, les états clavier/hover/pressed/disabled/selected et le mouvement réduit. Réutiliser ActionPrincipale/FilterPill/StatusPill ; ajouter seulement les responsabilités absentes nécessaires (ligne de réglage et option d'horaire de présentation).
4. Adapter la galerie existante, avec un point d'entrée de développement autonome sans initialisation Supabase, états réseau locaux et verrou de production. Conserver un seul design system et aucune navigation métier nouvelle. Les libellés de la démonstration restent locaux, afin de ne pas toucher les traductions concurrentes.
5. Formater seulement les fichiers touchés avec `dart format` (commande de formatage Dart), analyser, rejouer les tests pertinents et vérifier 360/390/768/1024/1440, seuils 599/600, 839/840, 1199/1200, clair/sombre, 200 %, clavier, RTL et mouvement réduit. Rapporter séparément rendus de test, plateformes exécutées et mesures profile.
6. Comparer les diffs et les fichiers protégés ; livrer R1 sans merge ni déploiement ni début de R2.

La présence d'un worktree ne vaut pas intégration : un raccord ultérieur doit comparer le nouveau HEAD et les changements de Claude, notamment les consommateurs de composants du suivi du foyer.
