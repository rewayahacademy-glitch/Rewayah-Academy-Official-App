# SITE 05 | QA et recette indépendante

Date : 8 octobre 2026. Périmètre : générateur, contenu HTML produit, assets, responsive, thèmes, mouvement, liens internes, SEO de préproduction et garde-fous de déploiement. Cette recette est locale et ne constitue pas une validation de production.

## TESTÉ

### Génération et HTML

- `python site-public/build_site.py --output <répertoire temporaire>` a produit **17 pages publiques HTML**, `404.html`, `robots.txt`, `sitemap.xml`, `vercel.json` et **11 assets**. Le build frais a été placé dans `%TEMP%\rewayah-site-public-qa-final-20261008`.
- Les 17 routes présentes dans le contenu ont chacune un fichier HTML, exactement un H1 correspondant au texte source et une URL canonical propre à cette route. Les liens internes `/fr/...` visent une route générée ; le seul chemin applicatif accepté est `/connexion`.
- En préproduction, les 17 pages ont `noindex,nofollow`, `robots.txt` interdit l’indexation et le sitemap est vide. L’option `--allow-indexing` échoue explicitement sur cette branche.
- Le contrôle de sortie ne trouve ni U+2014, ni adresse e-mail hors des quatre alias autorisés, ni marqueurs de secret testés (`sb_secret_`, `service_role`, `SUPABASE_SERVICE_ROLE_KEY`, `VERCEL_TOKEN`). Le prototype HTML de direction visuelle n’est pas copié dans les assets publics.
- La page 404 statique est générée, porte un seul H1 et reste `noindex,nofollow`. Les destinations de chaque rewrite généré correspondent à un fichier produit. Le fallback configuré exclut le préfixe `/fr`.
- **8 tests QA passent** avec `python -m unittest discover -s site-public/tests -v`. Ils vérifient les sorties consommées par le visiteur, les routes et fichiers, les métadonnées, la confidentialité, l’indexation bloquée, l’inventaire public des assets et la cohérence entre les fontes demandées par le CSS et le garde du bundle CI.

### HTTP local et navigateur

- Un serveur Python statique local a servi le build frais. Les fichiers `fr/index.html`, `fr/familles.html`, `fr/tarifs.html`, `fr/legal/conditions.html`, `fr/assets/site.css`, les deux fontes Latin étendu et `robots.txt` ont répondu HTTP 200. Le fichier `404.html` a aussi répondu 200 lorsqu’il est demandé directement comme un fichier.
- Chrome headless avec DevTools Protocol a rendu `/fr/index.html` aux viewports logiques 390×844, 768×1024 et 1440×900, en clair et en sombre. Les largeurs de document observées étaient respectivement 390/390, 753/768 et 1425/1440 ; l’écart de 15 px sur tablette et bureau correspond à la barre de défilement. Aucun débordement horizontal observé.
- `prefers-reduced-motion: reduce` a remplacé le défilement fluide par `scroll-behavior: auto`. Les fontes servies sont locales ; aucune ressource externe ni erreur console/réseau n’a été observée pendant ces ouvertures.
- Rapports de contraste calculés dans le navigateur pour quatre paires du hero : texte courant 15,36:1 clair et 17,11:1 sombre ; texte secondaire 5,81:1 et 10,62:1 ; libellé eyebrow 7,57:1 et 14,17:1 ; texte du CTA 4,81:1 et 8,92:1.
- Au clavier sur mobile, le focus initial passe au lien « Aller au contenu », puis au logo accessible et au résumé « Menu » ; un contour de focus visible est rendu. L’arbre d’accessibilité expose notamment le H1, la navigation du pied de page et les liens nommés.
- Des captures visuelles responsive et thématiques sont conservées par le lot visuel dans [`site-public/styles/previews/`](../../site-public/styles/previews/). Le hero n’utilise aucune capture de produit inventée.

## NON PROUVÉ

- Le serveur local utilisé pour le navigateur est un serveur statique de fichiers, pas Vercel. Il ne teste pas les rewrites : une URL propre comme `/fr/familles` et une URL Flutter comme `/connexion` ne peuvent donc pas être jugées à partir de son résultat. Le HTTP 200 d’un fichier `404.html` ne prouve pas le statut HTTP 404 d’une route inconnue.
- La grammaire de rewrite négative a été comparée à la [documentation officielle Vercel sur les rewrites et les groupes de capture](https://vercel.com/docs/project-configuration/vercel-json#negative-lookahead), mais la table de routage n’a pas été exercée sur un déploiement Vercel. Les routes `/fr/`, `/fr/familles`, l’entrée Flutter, les rechargements directs, `/fr/...` inconnu et le 404 réel restent à valider sur un aperçu.
- Le workflow contient maintenant des contrôles HTTP post-déploiement pour la racine, le fallback Flutter, `/fr/`, `/fr/familles`, le logo, les fontes et le statut 404. Ces contrôles n’ont pas encore tourné. `flutter build web` n’a pas été exécuté dans cette recette ; l’intégrateur a rapporté que la commande Flutter est restée silencieuse plus de 40 secondes puis a été interrompue.
- L’accessibilité n’est pas certifiée WCAG 2.2 AA : le lecteur d’écran, le zoom texte à 200 %, le clavier complet, tous les états de focus/hover, l’ensemble des composants et des pages, ainsi que les contrastes hors hero ne sont pas couverts ici.
- Les Core Web Vitals de terrain, les performances sur réseau 4G ou appareil modeste, les destinations Facebook, la réception des quatre alias e-mail et le parcours d’inscription jusqu’à l’application ne sont pas mesurés.
- L’origine canonical par défaut est `https://rewayah-academy.vercel.app`. Le domaine commercial canonique et la configuration de production ne sont pas confirmés par cette recette.
- La présence de vrais écrans anonymisés de l’application n’a pas été prouvée dans les sources inspectées. Aucune image de remplacement n’a été assimilée à une capture réelle.

## BLOQUÉ

- **Recette end-to-end sur aperçu Vercel : BLOQUÉE**, faute d’un aperçu déployé et accessible durant ce lot. `vercel dev` n’a pas démarré localement : Windows a refusé le lancement de sous-processus (`spawn EPERM`) et l’écriture de son fichier d’authentification. Le serveur statique local ne remplace pas cette preuve.
- **Publication : BLOQUÉE.** Le site demeure en mode aperçu sans indexation. Les contenus prix, mentions, conditions, protection des enfants et autres éléments signalés `blocked` dans `pages.json` ne reçoivent pas de feu vert de publication de cette QA.

## Matrice synthétique

| Surface | TESTÉ | NON PROUVÉ / BLOQUÉ |
|---|---|---|
| Générateur et 17 pages fixes | Build local et 8 tests QA passés | Build Flutter complet non exécuté |
| SEO / indexation | H1, canonical, noindex, robots et sitemap local | Crawl et domaine canonique de production |
| Liens | Cibles `/fr/...` résolues contre les pages produites | Navigation réelle, `/connexion`, Facebook et boîtes e-mail |
| Route inconnue | Fichier 404 produit et rewrite configuré | Statut HTTP 404 sur l’aperçu Vercel |
| Responsive / thèmes / motion | 390, ~768, 1440 ; clair, sombre et mouvement réduit | Zoom texte 200 %, appareils et navigateurs supplémentaires |
| Accessibilité / performance | Focus initial, noms accessibles et quatre contrastes du hero | Audit complet WCAG, lecteur d’écran et Web Vitals de terrain |
| Sécurité éditoriale | Scan des sorties HTML pour U+2014, e-mails et marqueurs de secrets | Audit complet de l’hébergement et des réponses servies |

**Conclusion de recette :** générateur et sorties locales vérifiés pour un aperçu non indexable. Les routes propres, le fallback Flutter, le statut 404 et le parcours intégré restent à prouver par les contrôles post-déploiement sur l’aperçu Vercel. Aucun résultat ici n’atteste une mise en production.
