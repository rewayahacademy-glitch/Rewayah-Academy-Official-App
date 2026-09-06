# Journal d'exécution — Étape 2

> Ce fichier dit **où en est le code**, ce que valent les mesures, et quels pièges
> ont déjà coûté du temps. `docs/architecture/etape-2-core-flutter.md` reste la
> spécification ; ce journal est son compte rendu.
> Mis à jour à la fin de chaque lot, jamais en bloc.

## État : étape 2 terminée, sauf le scénario 7

Onze lots sur onze. Vérifications au 6 septembre 2026 :

| Contrôle | Résultat |
| :--- | :--- |
| `dart analyze --fatal-infos` | aucun problème |
| `flutter test` | 78 tests, tous verts |
| `dart run tool/verifier_jetons.dart` | 35 fichiers, aucune violation |
| Migrations 0001 à 0003 sur Postgres 17 | appliquées, enum et défaut vérifiés en base |
| `flutter build web` | réussi, galerie totalement élaguée |
| `flutter build web --dart-define=GALERIE=true` | réussi, galerie présente |

## Les sept scénarios d'acceptation

| # | Scénario | État | Où c'est vérifié |
| :-- | :--- | :--- | :--- |
| 1 | Aucun texte blanc sur `surfaceSuccess` ou `surfaceWarning` | vert | `test/theme/contraste_test.dart` mesure le ratio WCAG réel de chaque paire, plus `tool/verifier_jetons.dart` qui refuse toute couleur nue hors de `AppPalette` |
| 2 | `PermanentNotice` sans paramètre de visibilité | vert | `test/widgets/permanent_notice_test.dart` lit la source du constructeur, et le vérificateur applique la même règle en CI |
| 3 | Route protégée refusée à un compte en attente, y compris par URL Web | vert | `test/router/redirection_test.dart`, 17 routes croisées avec `pending_kyc` et `disabled` |
| 4 | Photo supprimée côté serveur, disparue en local sous 24 h | vert | `test/cache/purge_photos_test.dart` |
| 5 | Cahier synchronisé deux fois, une seule ligne | vert | `test/cache/file_rapports_test.dart` |
| 6 | Une seule arborescence de routes pour les deux modes | vert | `test/router/redirection_test.dart` plus le contrôle de fichier unique du vérificateur |
| 7 | Démarrage à froid sous 1,5 s | **non mesuré** | Voir ci-dessous |

**Le scénario 7 n'est pas coché, et il ne doit pas l'être tant qu'il n'est pas
mesuré.** À l'étape 2 il n'y a aucun écran métier à charger : chronométrer un
placeholder ne dirait rien du produit. La mesure appartient à l'étape 3, sur un
appareil d'entrée de gamme, sur `ELV-02` réel. Ce qui est fait dès maintenant :
polices embarquées plutôt que chargées au réseau, élagage d'icônes actif,
langues non basiques chargées en différé par slang.

## Lots

| Lot | Contenu | Fait |
| :-- | :--- | :-: |
| L0 | `flutter create`, pubspec, lints stricts, `dart_define.example.json` | x |
| L1 | Thème : paires, encres, espacement, deux échelles typographiques, 4 polices | x |
| L2 | `AppIcons`, catalogue unique | x |
| L3 | slang, clés en points, français rempli, arabe déclaré | x |
| L4 | `SessionState`, rôle du JWT, statut lu de `profiles`, `PorteAcces` | x |
| L5 | Routeur unique, redirection en fonction pure, salle éphémère | x |
| L6 | Les neuf composants partagés | x |
| L7 | Drift 4 tables, cache média, stockage sécurisé, file idempotente | x |
| L8 | Galerie `/_galerie` derrière `--dart-define=GALERIE=true` | x |
| L9 | Vérificateur de jetons, tests d'acceptation, CI | x |
| L10 | Migrations 0002 et 0003, statut `pending_kyc` | x |
| L11 | Documentation | x |

## Mesures relevées

### Contraste

Le tableau de `design-tokens.md` a été mesuré, pas relu.

Valeurs relevées par `Color.computeLuminance` de Flutter, pas estimées.

| Jeton | Mesure | Seuil | Verdict |
| :--- | ---: | ---: | :--- |
| `surfaceBase` | 13,51:1 | 4,5 | passe |
| `surfacePrimary` | 4,81:1 | 4,5 | passe, de peu |
| `surfaceSuccess` | 11,55:1 | 4,5 | passe |
| `surfaceWarning` | 9,64:1 | 4,5 | passe |
| `surfaceAlert` | 6,84:1 | 4,5 | passe |
| `textOnLightAccent` sur `surfaceBase` | 6,48:1 | 4,5 | passe |
| `surfacePrimary` sur `surfaceBase` (focus) | 3,86:1 | 3,0 | passe |
| `surfaceAlert` sur `surfaceBase` (erreur) | 5,49:1 | 3,0 | passe |
| `borderDefault` sur `surfaceBase` | **1,86:1** | 3,0 | **échoue** |
| `#CCBCBC` d'origine sur `surfaceBase` | 1,47:1 | 3,0 | échoue, valeur citée dans les specs, confirmée |

**`borderDefault` (`#B8A6A6`) reste sous le seuil de 3:1 des éléments non
textuels (WCAG 1.4.11).** La correction héritée de l'audit l'a fait passer de
1,47:1 à 1,86:1, ce qui améliore sans résoudre. Conséquence tenue dans le code :
ce jeton est **décoratif**, il ne porte jamais seul le sens d'un contrôle ou
d'un état. Le focus, l'erreur et la sélection passent par `surfacePrimary`,
`surfaceAlert` et `textOnLightAccent`, qui eux passent le seuil.

**Décision en attente de l'opérateur** : si les bordures doivent devenir
porteuses de sens, `#8F8080` mesure 3,03:1 sur `surfaceBase`, valeur vérifiée et
non estimée. Le test `contraste_test.dart` encadre la mesure par le haut et par
le bas, pour qu'un changement de ce jeton soit un choix conscient et non un
glissement.

Un mot sur `surfacePrimary` à 4,81:1 : la marge au-dessus de 4,5 est mince.
Toute retouche du violet `#8652E6` doit être remesurée, pas jugée à l'œil.

### Poids

| Élément | Livré | Après élagage |
| :--- | ---: | ---: |
| Phosphor regular | 489 Ko | 10,6 Ko |
| Phosphor fill | 449 Ko | 8,9 Ko |
| Material Icons | 1 645 Ko | 7,7 Ko |
| Cupertino Icons | 258 Ko | 1,5 Ko |
| **NotoSans-Variable** | **2 001 Ko** | **2 001 Ko** |
| NotoSansArabic-Variable | 825 Ko | 825 Ko |
| UthmanTahaNaskh | 161 Ko | 161 Ko |
| VarelaRound | 130 Ko | 130 Ko |

Les polices de texte ne sont pas sous-ensemblées : l'élagage de Flutter ne
concerne que les polices d'icônes. **NotoSans-Variable pèse 2 Mo pour une
interface française** : c'est le plus gros gain disponible sur le budget de
20 Mo du cahier des charges bibliothèque. Un sous-ensemble latin le ramènerait
autour de 150 Ko. Non fait à l'étape 2, faute d'outil de sous-ensemble dans la
chaîne ; à traiter quand le budget de démarrage sera mesuré pour de vrai.

## Pièges rencontrés, à ne pas repayer

### `phosphor_flutter` ne compile plus, et aucune version ne le corrige

Le paquet 2.1.0, dernière version publiée, fait `class PhosphorIconData extends
IconData`. Sous Flutter 3.47, `IconData` est une classe `final` : la
compilation échoue. **`dart analyze` ne le voit pas**, seul `flutter test` ou un
build le révèle. Ne pas conclure trop vite qu'un `analyze` vert suffit.

Résolu en intégrant les deux graisses utiles en assets (`assets/fonts/Phosphor-Regular.ttf`
et `Phosphor-Fill.ttf`, licence MIT dans `assets/fonts/LICENSE-Phosphor.txt`) et
en déclarant les points de code dans `AppIcons`. Les `IconData` y sont **const**,
sans quoi l'élagage d'icônes échoue et fait tomber le build de production.

### Le stub `auth` de la CI était incomplet

`ci.yml` créait le schéma `auth` et la table `auth.users`, mais ni `auth.jwt()`
ni `auth.uid()`. Postgres valide le corps d'une fonction SQL à sa création :
`public.app_role()` échouait, donc la migration 0001 entière. Le job n'avait
jamais tourné (il ne se déclenche que sur une pull request vers `main`), donc
personne ne l'avait vu. Corrigé.

**Leçon générale : un job de CI qui n'a jamais tourné n'est pas un job vert.**

### slang lisait sa configuration deux fois

`slang.yaml` d'un côté, `build_runner` de l'autre, qui cherchait un `build.yaml`
et se rabattait sur une locale de base `en` inexistante. `build.yaml` désactive
désormais le builder slang. Deux commandes, dans cet ordre :

```
dart run slang
dart run build_runner build --delete-conflicting-outputs
```

### Le poste de travail ne fait pas confiance à `github.com`

Le magasin de racines de cette machine valide `raw.githubusercontent.com` mais
pas `github.com` (`SEC_E_UNTRUSTED_ROOT`), et bloque la vérification de
révocation sur `release-assets.githubusercontent.com`. Conséquence : le hook de
build de `package:sqlite3` ne peut pas télécharger sa bibliothèque native, et
**tout `dart run` ou `flutter test` du projet échoue** tant que ce n'est pas
réglé.

Contournement appliqué : bibliothèque récupérée par un autre chemin, empreinte
SHA-256 vérifiée contre celle publiée dans le paquet
(`2bf39f2a...`), puis déposée dans
`.dart_tool/hooks_runner/shared/sqlite3/build/download-2bf39f2a/sqlite3.dll`.
Le hook réutilise un fichier dont l'empreinte correspond.

**C'est un contournement local, pas un correctif.** Il disparaît à chaque
nettoyage de `.dart_tool`. Le vrai correctif est côté poste : installer la
racine manquante ou lever l'interception TLS. La CI n'est pas concernée.

Le mode développeur Windows est également désactivé, ce que Flutter réclame
pour les liens symboliques des greffons. À activer par `start ms-settings:developers`.

### `Get-Content` de PowerShell 5.1 détruit l'UTF-8

Un fichier parfaitement valide s'affiche en mojibake. Ne pas « corriger » un
accent sur la foi d'un affichage PowerShell : relire avec un outil qui respecte
l'encodage.

### Le chemin du dépôt contient des espaces

`D:\RA _APP\RA -OFFICIAL-APP`. Les builds Web et l'analyse passent. Si
`flutter build apk` ou `flutter build windows` échoue localement sur Gradle,
regarder ce point avant tout le reste. La CI compile dans un chemin propre.

## Écarts assumés par rapport à la spécification

| Point | Spécification | Ce qui est fait | Raison |
| :--- | :--- | :--- | :--- |
| Langues | « fichiers poular préparés mais vides » | Français rempli, arabe déclaré, **aucun poular** | Décision de l'opérateur du 6 septembre 2026, ADR-015 |
| Composants | « les huit composants partagés » (section 8) | Neuf | La section 2 en liste bien neuf : `ChoiceCardGroup` est arrivé avec l'ADR-013 et la section 8 n'a pas suivi |
| Sous-ensembles de polices | « réduites aux glyphes réellement utilisés » | Icônes élaguées, polices de texte entières | Aucun outil de sous-ensemble dans la chaîne ; mesure et gain consignés plus haut |
| Scénario 7 | Démarrage sous 1,5 s | Non mesuré | Aucun écran réel à charger avant l'étape 3 |

## Ce qui reste ouvert, hors périmètre de l'étape 2

- **Étape D de l'onboarding, les secrets.** Toujours non faite. Elle demande
  `supabase login`, `supabase link --project-ref gggmtelinlpseweouyav`, puis les
  secrets GitHub `SUPABASE_ACCESS_TOKEN` et `SUPABASE_DB_URL`. Le code n'en a
  pas besoin pour compiler : il lit sa configuration par `String.fromEnvironment`,
  voir `dart_define.example.json`.
- **Étape G, variantes `dev` / `staging` / `prod`.** L'identifiant est
  `com.rewayahacademy.app` pour les trois. Trois identifiants distincts
  restent à poser.
- **Étape F, Sentry.** Non faite.
- **Étape M, PWA.** Le build Web fonctionne ; le manifest, le service worker et
  l'URL déployée restent à faire.
- **`borderDefault`**, voir la décision en attente plus haut.
- **`child_ui_mode_max_age`** est toujours « à trancher » dans `app_config`.
  L'étape 2 n'en dépend pas : elle fournit les deux échelles, le seuil est lu à
  la création du profil, à l'étape 3.
