# SITE 01 | ADR architecture du site public

Date : 8 octobre 2026. Statut : **proposé pour branche d'aperçu**, sous responsabilité Codex `gpt-6-astra`. Aucune production autorisée.

## Contexte et critères

Le dépôt déploie aujourd'hui un bundle Flutter Web à la racine, avec une réécriture Vercel globale vers `/index.html`. Les routes privées existantes doivent continuer à fonctionner, tandis que `/fr/...` doit fournir du HTML indexable, des titres et des canonical propres. Une nouvelle base, un CMS concurrent ou une seconde authentification sont exclus. L'absence constatée de projection publique sûre interdit de lire `app_config` ou les données de familles depuis le navigateur anonyme.

## Options comparées

| Option | HTML et intégration | Coût/risque | Décision |
|---|---|---|---|
| A. Pages statiques générées depuis `site-public/`, copiées dans `build/web/fr/` après `flutter build web` ; réécritures explicites `/fr/...` avant le repli Flutter | HTML complet par route, même déploiement Vercel, `/connexion` et autres chemins Flutter conservés | Petit générateur et tests de routage à maintenir ; contenu actif bloqué tant qu'une projection publiée sûre n'existe pas | **Retenue** pour l'aperçu isolé |
| B. Application SSR séparée (Next/Jaspr) et réécritures Vercel vers deux services | Rendu dynamique possible ; gestion indépendante des pages | Nouveau runtime, dépendances, build et routage partagé ; risque de double administration et de rupture du workflow Flutter | Écartée pour ce lot |
| C. Pages publiques dans Flutter Web seulement | Aucun second moteur de rendu | Contenu textuel moins fiable à crawler et métadonnées par route difficiles | Écartée pour le contenu institutionnel |

La documentation Vercel permet les réécritures ordonnées et les fichiers HTML statiques ; la documentation Flutter confirme que `flutter build web` produit `build/web` et que les routes de l'app exigent un repli serveur. Vérification locale et en aperçu de l'ordre effectif des routes obligatoire avant toute PR.

## Décision et frontières

1. Les pages publiques `/fr/`, `/fr/familles`, `/fr/cours`, `/fr/cours/[parcours]`, `/fr/comment-ca-marche`, `/fr/tarifs`, `/fr/academie`, `/fr/articles`, `/fr/articles/[slug]`, `/fr/aide`, `/fr/recrutement`, `/fr/recrutement/[poste]`, `/fr/contact`, `/fr/protection-des-enfants`, `/fr/legal/*`, `/fr/accessibilite` appartiennent au générateur HTML public.
2. `/connexion`, `/inscription`, `/attente`, `/tuteur`, `/eleve`, `/enseignant`, `/admin`, `/compte`, `/tc` et les autres routes existantes restent à Flutter. Le CTA public mène à `/connexion`, porte d'entrée réelle pour une session neuve. Aucun état de réservation ou de candidature n'est reproduit dans le site.
3. Le contenu statique institutionnel vérifié peut être rédigé dans le dépôt. Prix, capacité en vigueur, cours ouverts, patterns, articles et postes nécessitent une **projection publique publiée**, versionnée, expurgée et issue de l'admin existante. Contrat proposé : document de publication en lecture seule avec `version`, `published_at`, `currency`, règles tarifaires, formats pédagogiques, parcours ouverts, slugs/articles/postes publiés, sans PII, KYC, enseignant affecté ou stock de places. Tant que le contrat n'existe pas, l'aperçu indique explicitement les informations non confirmées et n'indexe pas les fiches conditionnelles.
4. Pas de session copiée entre HTML et Flutter. Le passage est une navigation de même origine. Préférence de thème : `prefers-color-scheme` par défaut sur le site ; synchronisation avec un réglage Flutter seulement si une clé publique stable est prouvée. La langue initiale est FR ; `/en/` n'est pas publiée sans traduction validée.

## Nomenclature et ownership

| Couloir | Modèle réellement disponible | Fichiers exclusifs | Entrée, sortie et contrôle |
|---|---|---|---|
| Astra / socle | `gpt-6-astra` | `docs/site-public/SITE_00_*`, `SITE_01_*`, arbitrages | État Git, ADR, contrats et ordre d'intégration ; revue finale indépendante des lots |
| UX/UI et assets | `gpt-6-sol` | `site-public/assets/`, `site-public/styles/`, `docs/site-public/SITE_03_*` | Tokens, logo, maquette responsive et motion ; revue Astra et QA |
| Éditorial/SEO | `gpt-6-luna` | `site-public/content/`, `docs/site-public/SITE_02_*` | Copy par route, métadonnées, états de publication ; revue conformité puis Astra |
| Conformité/fact-check | `gpt-6-sol` | `docs/site-public/SITE_04_*` | Faits sourcés, lacunes et garde de publication ; revue croisée éditoriale |
| Frontend/génération | `gpt-6-astra` | `site-public/build_site.py` | HTML des routes ; revue UX et QA ; aucun changement Flutter |
| Intégration | `gpt-6-astra` | `web/vercel.json`, `.github/workflows/flutter-deploy.yml`, script de copie | Un seul propriétaire des routes, build et rollback |
| QA/accessibilité | `gpt-6-luna` | `docs/site-public/SITE_05_*`, scripts de recette dédiés | Tests route, clavier, thèmes, SEO, secrets et captures ; revue finale Astra |

Les identifiants `6.1` demandés dans la spec ne sont pas sélectionnables dans cette session. Les identifiants accessibles sont `gpt-6-astra`, `gpt-6-sol` et `gpt-6-luna` (ainsi que des modèles 5.6). Aucun agent ne sera décrit comme `6.1`.

## Séquence et portes

1. **Jalon 1** : présent audit et ADR, puis revue des contrats et ownership ; aucune implémentation structurelle avant ce point.
2. **Jalon 2** : direction visuelle sur vrais logos ; captures de produit seulement si localisées et vérifiées anonymes. Contenu FR et matrice juridique en parallèle dans des fichiers exclusifs.
3. **Jalon 3** : générateur HTML et toutes routes fixes ; intégration Vercel par l'intégrateur unique ; lien `/connexion` testé ; aucune fiche fictive.
4. **Jalon 4** : aperçu de branche si possible, tests à 390/768/1440, clair/sombre/mouvement réduit, route directe, actualisation, navigation, 404, SEO et performance. Rapport `FAIT / TESTÉ / NON PROUVÉ / BLOQUÉ`.

Chaque lot fournit diff ciblé, capture si visuel, commande et résultat de test, risques et statut. Aucune fusion `main` : elle déclencherait la production. Une PR d'aperçu n'est ouverte qu'après contrôle des diff et absence de clauses non vérifiées.

## Risques et retour arrière

- Réécriture `/fr/...` capturée par le repli Flutter : vérifier le HTML servi avec `curl` sur chaque famille de route et conserver le `web/vercel.json` initial comme référence Git. Retour arrière : retirer l'étape de copie du site et les seules règles `/fr` sur la branche, sans toucher au routeur Flutter.
- Données commerciales obsolètes : ne jamais embarquer un second tarif actif codé en dur. Publier les valeurs uniquement depuis un export/publication administrée prouvée ; sinon bloquer le feu vert.
- Capture contenant données de famille : aucune capture n'est intégrée avant inspection et anonymisation validées.
- Le domaine commercial canonique, la disponibilité des contacts et le registre restent à prouver ; `rewayah-academy.vercel.app` est seulement le domaine constaté dans le workflow.

## Références techniques

- Vercel, configuration et réécritures : https://vercel.com/docs/project-configuration/vercel-json et https://vercel.com/docs/routing/rewrites
- Flutter, déploiement Web et stratégie d'URL : https://docs.flutter.dev/deployment/web et https://docs.flutter.dev/ui/navigation/url-strategies
