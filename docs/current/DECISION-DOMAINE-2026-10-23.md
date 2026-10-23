# Domaine, référencement et anti-spam (directeur, 23/10/2026)

Demandes du directeur, 23/10/2026 : « les derniers réglages qui permettront au site de bien fonctionner et
être référencé sur les moteurs de recherche », « ajouter le nom de domaine maintenant », « il doit y avoir une
PWA, et le site public, donc les gens iront vers quoi ? à toi de voir avec logique / standard reconnu des
spécialistes », « tout faire pour empêcher les spams : beaucoup de nos adresses sont publiquement visibles, et
nos noms aussi ». Le choix d'architecture ci-dessous lui a été délégué.

## 1. Qui va où (décidé)

| Adresse | Sert | Indexée |
| :--- | :--- | :--- |
| `rewayahacademy.com` | le site public ; la racine mène à l'accueil `/fr/` | oui |
| `app.rewayahacademy.com` | l'application et sa PWA (on l'installe depuis ici) | non |
| `www.rewayahacademy.com` | renvoie à `rewayahacademy.com` | non |
| `rewayah-academy.vercel.app` | reste servi (contrôles du workflow, anciens liens, PWA déjà installées) | non |

C'est l'usage courant des académies et des logiciels en ligne : le site, qu'on trouve sur Google, à la racine
du domaine ; l'application, qu'on utilise une fois inscrit, sur un sous-domaine. Les moteurs ne voient que des
pages lisibles, jamais l'écran de connexion ; la PWA a son propre périmètre ; le site et l'application gardent
leurs réglages séparés.

Le parcours : une famille qui découvre l'académie arrive sur `rewayahacademy.com` (par Google ou un lien) ;
« Commencer mon inscription » et « Se connecter » l'emmènent sur `app.rewayahacademy.com`. Un inscrit ouvre
l'icône de la PWA ou `app.rewayahacademy.com`. Un lien de l'application tapé sur le domaine du site
(`rewayahacademy.com/connexion`) est renvoyé vers `app.`.

Hors de ce dépôt et à ne pas toucher : le projet Vercel « app » (PISI, `pisi.rewayahacademy.com`, et
`rewayah.academy`, qui ne répond plus en DNS). PISI est un autre projet.

## 2. Ce qui est dans le code (présent dans le code, testé localement ; ni staging ni production)

- `site-public/build_site.py` : l'indexation s'ouvre seulement dans la construction de `main` (même règle que
  l'étape « cible » de `.github/workflows/flutter-deploy.yml` : `main`, hors pull request) ; un aperçu reste
  `noindex`. Adresses canoniques, `sitemap.xml` et `robots.txt` sur `https://rewayahacademy.com`.
- Pages indexées : les 16 pages prêtes, dont Tarifs. Articles (« à venir ») et Avis (tant qu'aucun avis n'est
  publié) restent hors de l'index : une page vide nuit au référencement du site entier.
- `build/web/vercel.json` (écrit par le générateur) aiguille selon le nom demandé (tableau du §1),
  `X-Robots-Tag: noindex` sur `app.` et sur l'ancien alias, en-têtes de sécurité sur `/fr`. Ces règles ne jouent
  que sur les trois noms du domaine : un aperçu et l'alias `vercel.app` servent tout comme avant.
- Données structurées de l'accueil : organisation éducative et site, sans adresse e-mail.
- Anti-spam : aucune adresse ni lien `mailto:` lisible dans les pages ; `site.js` les recompose, la feuille de
  style dessine l'arobase quand le script manque. Test : `site-public/tests/test_build_site_qa.py`.

## 3. Ce que le directeur fait, dans cet ordre

### 3.1 Vercel, projet `rewayah-academy` (Settings, Domains)

1. Ajouter `rewayahacademy.com` (Production).
2. Ajouter `www.rewayahacademy.com`, avec « Redirect to rewayahacademy.com » (308).
3. Ajouter `app.rewayahacademy.com` (Production).

Le garde-fou réserve ces écritures au directeur.

### 3.2 Cloudflare, zone `rewayahacademy.com` (DNS, Records)

Avant tout : exporter la zone (DNS, Records, Export) et garder le fichier.

Inventaire public lu le 23/10/2026 (requêtes DNS publiques et lecture Vercel) :

| Nom | Type | Aujourd'hui | Action |
| :--- | :--- | :--- | :--- |
| `@` | A et AAAA | adresses Cloudflare (proxy orange) ; le domaine répond « erreur 526 » (certificat de l'origine refusé) : il ne sert rien aujourd'hui | remplacer |
| `www` | aucun | n'existe pas | créer |
| `app` | aucun | n'existe pas | créer |
| `pisi` | A `76.76.21.21` | PISI | **ne pas toucher** |
| `@` | MX (5) | Google Workspace | **ne pas toucher** |
| `@` | TXT | SPF `v=spf1 include:_spf.google.com -all`, `google-site-verification` | **ne pas toucher** |

À poser (valeurs recommandées par Vercel pour ce projet, lues le 23/10 ; Vercel les redonne à l'ajout des
domaines), toutes en **DNS seul (nuage gris)** : Vercel délivre lui-même le certificat.

| Nom | Type | Valeur |
| :--- | :--- | :--- |
| `@` | A | `216.198.79.1` |
| `@` | A | `64.29.17.1` |
| `www` | CNAME | `2fb4e585278fb72c.vercel-dns-017.com` |
| `app` | CNAME | `2fb4e585278fb72c.vercel-dns-017.com` |

Supprimer les anciens A et AAAA de `@`. Aucun autre enregistrement ne change.

### 3.3 Supabase, projet de production (Authentication, URL Configuration)

- Site URL : `https://app.rewayahacademy.com`.
- Redirect URLs : ajouter `https://app.rewayahacademy.com/**`, garder `https://rewayah-academy.vercel.app/**`
  (PWA déjà installées, aperçus).
- Google Cloud (écran de consentement OAuth) : domaine autorisé `rewayahacademy.com`, page d'accueil
  `https://rewayahacademy.com/fr/`, politique de confidentialité `https://rewayahacademy.com/fr/legal/confidentialite`.

Vérifier ensuite : `https://app.rewayahacademy.com/connexion`, recevoir le lien de connexion, l'ouvrir.

### 3.4 Fusion dans `main`

La fusion publie le site indexé. Fusionner avant 3.1 à 3.3 ne casse rien : le site reste servi sur
`rewayah-academy.vercel.app`, marqué `noindex`, et le domaine ne sert encore rien.

### 3.5 Google Search Console et Bing

- La zone porte déjà un TXT `google-site-verification` : la propriété « domaine » est sans doute vérifiée.
- Ajouter le plan du site `https://rewayahacademy.com/sitemap.xml`, puis demander l'indexation de
  `https://rewayahacademy.com/fr/` (Inspection de l'URL).
- Bing Webmaster Tools : importer depuis Search Console (couvre aussi DuckDuckGo et Yahoo).

## 4. Anti-spam et usurpation

| Mesure | Où | Statut |
| :--- | :--- | :--- |
| Adresses illisibles pour les robots sur le site | `site-public` | présent dans le code, testé localement |
| Aucune adresse dans les données structurées | `site-public` | présent dans le code, testé localement |
| Signature DKIM des e-mails | console Google Workspace : Applications, Google Workspace, Gmail, Authentifier les e-mails ; générer (2048 bits, préfixe `google`), poser le TXT `google._domainkey` dans Cloudflare, puis « Démarrer l'authentification » | à faire (directeur) |
| DMARC | TXT `_dmarc` : `v=DMARC1; p=quarantine; rua=mailto:dmarc@rewayahacademy.com` (créer d'abord l'alias `dmarc@`), après DKIM ; `p=reject` après un mois sans rejet légitime dans les rapports. Le SPF actuel dit déjà que seul Google envoie au nom du domaine | à faire (directeur) |
| Protection des noms | console Google Workspace : Gmail, Sécurité, Protection contre l'usurpation : noms des employés, domaines ressemblants, domaine des destinataires ; protection renforcée des pièces jointes et des liens | à faire (directeur) |

Les noms des fondateurs restent publics : ils portent la confiance (M-21). Aucun nom n'a d'adresse personnelle
publiée ; seules les quatre adresses de service le sont. Le risque qui vient avec les noms est l'usurpation (un
faux « directeur » qui écrit aux familles) : DKIM, DMARC et la protection des noms de Gmail y répondent.

Déjà fermé : le formulaire d'avis ne s'ouvre que par un lien créé par la direction et rien n'est publié sans
lecture (`DECISION-AVIS-2026-10-19.md`). Ouvert, pour plus tard : un CAPTCHA (Cloudflare Turnstile) à
l'inscription dans l'application, réglage Supabase et lot Flutter.

## 5. Jeton Cloudflare, si Claude pose le DNS

Le directeur peut poser les quatre enregistrements lui-même (cinq minutes). S'il préfère que Claude le fasse :

- Cloudflare, My Profile, API Tokens, Create Token, **Create Custom Token** ;
- permissions : **Zone, DNS, Edit** et **Zone, Zone, Read** ; rien d'autre (ni SSL, ni Page Rules, ni
  Workers, ni droits de compte) ;
- Zone Resources : **Include, Specific zone, rewayahacademy.com** ;
- Client IP Address Filtering : vide (l'adresse de sortie de la session change) ; TTL : 7 jours ;
- le ranger dans les réglages de l'environnement cloud (Network secrets, sinon variable d'environnement)
  sous le nom `CLOUDFLARE_API_TOKEN`, **jamais dans la conversation** ; une nouvelle session le lit ;
- avec lui, Claude exporte la zone (sauvegarde), montre la liste exacte, attend le feu vert sur cette liste,
  l'applique, vérifie, puis le directeur révoque le jeton.

`api.cloudflare.com` est joignable depuis l'environnement cloud (vérifié le 23/10).

## 6. Après la bascule

- `lib/features/admin_avis/lien_avis.dart` : l'origine par défaut (hors Web) est encore
  `https://rewayah-academy.vercel.app` ; à passer sur `app.rewayahacademy.com` quand le domaine répond.
- `.github/workflows/flutter-deploy.yml` contrôle `SITE=https://rewayah-academy.vercel.app` : à garder tant que
  l'alias sert l'application ; changer `SITE` est une modification de `.github/` (directeur).
