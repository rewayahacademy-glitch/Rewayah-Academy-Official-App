# SITE 00 | État prouvé et conflits

Date : 8 octobre 2026. Responsable du socle : Codex `gpt-6-astra`.
Statut : audit du dépôt local, sans preuve de déploiement du site public.

## Sources et état Git

- Demande actuelle et chapitre A des spécifications du 8 octobre priment sur le chapitre B du 7 octobre, puis `docs/current/` et le code constaté.
- Dépôt inspecté : `D:\RA _APP\RA -OFFICIAL-APP`, branche `c0/configuration-baseline-2026-09-23`, HEAD `19ec3dce`. Elle a deux commits locaux au-delà de son origine. L'arbre principal ne présente que `.claude/` non suivi. `main` local et `origin/main` pointent sur `4a7aa2be`.
- Un grand nombre de worktrees métier existent, notamment onboarding, Teaching Core, UI tuteur et refonte. Aucun n'est attribué au site public par cet audit. Aucun fichier de ces worktrees n'est à modifier.
- Worktree isolé créé pour le site : `C:\Users\dell\AppData\Local\Programs\WindowsTerminal\rewayah-site-public`, branche `codex/site-public-2026-10-08`, basée sur `19ec3dce`. Ne pas fusionner `main` ni déployer en production.
- PR ouvertes, propriétaires humains/agents encore actifs, état distant des données et statut réel de production : **NON PROUVÉ** par l'inspection locale. Vérifier avant toute PR ou mise en service.

## Existant technique observé

- Flutter/Dart : `pubspec.yaml` annonce Dart `^3.13.2`, Riverpod, `go_router`, Supabase Flutter, Drift, LiveKit et slang. Le routeur est `lib/core/router/app_router.dart` ; ses chemins sont dans `routes.dart`.
- Vercel : `.github/workflows/flutter-deploy.yml` construit `build/web`, copie `web/vercel.json`, puis déploie par CLI. Une PR vers `main` déclenche un aperçu ; un push sur `main` déclenche la production selon le workflow. Le `web/vercel.json` a une réécriture globale `/(.*)` vers `/index.html`.
- Domaine constaté dans le workflow : `https://rewayah-academy.vercel.app`. Domaine commercial principal, DNS et sous-domaines : **NON PROUVÉS**.
- L'application possède `/connexion`, `/inscription` et les routes privées. `/inscription` n'est accessible qu'après session valide sans profil ; un visiteur déconnecté est redirigé vers `/connexion`. Un CTA public d'inscription doit donc ouvrir `/connexion` et expliquer la reprise dans Flutter. La candidature enseignant utilise le choix de rôle dans l'inscription, sans preuve de parcours personnel administratif.
- `web/` ne contient que le shell Flutter, ses icônes et ses fichiers runtime. Aucune page HTML publique par route, aucun article public ni système éditorial public observé.
- La configuration `app_config` est réservée à l'admin ; `get_config` n'est pas une lecture anonyme. Les lectures des offres dans `lib/core/offres/service_offres.dart` sont destinées au parcours authentifié. Projection publique sûre de prix, capacités, parcours, patterns, articles et postes : **NON PROUVÉE**. Aucune table privée ne doit être interrogée directement par le site.
- Le thème Flutter observé utilise `InstrumentSans` et `BricolageGrotesque`, `#8652E6`, toile claire `#F8F7FA` et toile sombre proche de `#1A181F`. Les réglages de thème web/app et la persistance commune restent à inspecter et tester.

## Assets

- Huit SVG réels accessibles dans `C:\Users\dell\Downloads\RA logo 2026\RA logo SVG` : logos horizontal et vertical ; icônes `full color`, `full +outsroke`, `ornement full color`, `ornement outsrok` ; symboles `full color` et `outsroke`. Tous annoncent `#8652E6` et un `viewBox`. Le logo horizontal annonce `1299×340`, le vertical `903×602`. Les variantes destinées aux fonds sombres nécessitent un contrôle visuel de contraste avant sélection. Les copies du site ne doivent pas modifier le dessin.
- Les cinq captures demandées (`Accueil.png`, `Foyer Member.png`, `Classe Details.png`, `Profil.png`, `Historique.png`) n'ont pas été trouvées dans le dépôt ni dans le répertoire Downloads par recherche de noms exacts. Leur présence dans d'autres dossiers ou dans un fichier d'archive reste **NON PROUVÉE**. Aucun écran de substitution ne sera présenté comme une capture de l'app.

## Conflits documentés

| Statut | Sources | Priorité et conséquence |
|---|---|---|
| CONFLIT | Spécifications A4/A6 du 8 octobre : choix de patterns, constitution de classe après intention ; `docs/current/00_LIRE_D_ABORD.md` et `08` : choix d'une classe précréée | La demande du 8 octobre prime pour le texte du site. Le code du parcours courant doit être vérifié à nouveau avant d'affirmer un bout en bout disponible. Le site ne promet ni siège ni réservation immédiate. |
| CONFLIT | Spécifications A7 : DM Sans et Plus Jakarta Sans ; thème Flutter `app_typography.dart` : Bricolage Grotesque et Instrument Sans | La règle explicite du 8 octobre gouverne le site public. Flutter reste inchangé. Le raccord visuel est un point de QA ; aucune police de l'app n'est renommée. |
| RÉSOLU LE 9/10 | Direction validée : fond continu `#1A1A25` ; ancienne observation locale : `#1A181F` sur une autre branche | Le site public applique `#1A1A25` sans bandes ; la capture navigateur locale figure dans `SITE_06`. |
| CONFLIT | Spécifications A4 : capacités 5 enfants/6 adultes ; `docs/current/00` expose un ancien arbitrage ouvert | La décision du 8 octobre prime pour le contenu préparatoire. Sa publication comme offre en vigueur dépend de la projection administrée. |
| NON PROUVÉ | Correctif tarifaire du 9 octobre : rangs 1/2 sans remise, rang 3 moins 5 USD, rangs suivants moins 7 USD ; code local : aucune projection anonyme ni service public de simulation constaté | La grille V3 est périmée. Bloque les chiffres actifs, le simulateur connecté et les exemples mis à jour sans redéploiement. |
| NON PROUVÉ | Spécifications A2 : siège et numéro ; dépôt local : aucune vérification du registre courant | Vérifier Companies House et le droit au siège avant publication finale des mentions. Aucun numéro fiscal privé dans le site. |

## Garde-fous du lot

Ne pas toucher `lib/`, `supabase/`, migrations, auth, RLS, RPC, finances, LiveKit, R2 ni les worktrees concurrents. Un seul intégrateur possède `web/vercel.json`, le workflow et les routes de déploiement. Les agents spécialisés possèdent des fichiers distincts sous `site-public/` et `docs/site-public/`. Aucun texte juridique incertain n'est publié comme clause définitive.
