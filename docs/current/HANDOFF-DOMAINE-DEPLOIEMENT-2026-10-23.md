# Passation : mise en production du site public et branchement du domaine (23/10/2026)

Pour une session Claude que le directeur charge du déploiement, avec les autorisations et les jetons nécessaires.
Lire d'abord `CLAUDE.md` (racine), puis `docs/current/DECISION-DOMAINE-2026-10-23.md` (le pourquoi, les choix). Ce
document dit le comment, dans l'ordre. Ne rien sauter : chaque étape a sa vérification.

## 0. État au 23/10/2026

- Code prêt sur la branche `claude/youthful-davinci-raugwe` (PR #44, base `claude/dazzling-edison-s8m5mf`), CI verte.
  Dernier commit au moment de la passation : `b06314e7` (plus ce document).
- `main` (production) date du 22/09/2026 : il ne contient **ni** `site-public/` **ni** l'étape `build_site` de
  `.github/workflows/flutter-deploy.yml`. Aujourd'hui `https://rewayah-academy.vercel.app/fr/` rend l'application.
- Le site public est construit par `site-public/build_site.py` dans `build/web` (l'application Flutter à `/`, le site
  sous `/fr/`). Sur `main`, la construction s'indexe d'elle-même (`production_github`) ; ailleurs, `noindex`.
- `build/web/vercel.json` (écrit par le générateur) porte l'aiguillage par nom : `rewayahacademy.com` → site
  (racine vers `/fr/`), `app.rewayahacademy.com` → application, `www` → domaine nu, `noindex` sur `app.` et
  `rewayah-academy.vercel.app`. Vérifié contre le schéma Vercel et path-to-regexp 6.1.0 en mode strict.
- Domaine `rewayahacademy.com` chez Cloudflare (serveurs `meera`/`roman.ns.cloudflare.com`). La racine répond
  aujourd'hui « erreur 526 » (rien d'utile servi). E-mails Google Workspace (MX, SPF) et `pisi.rewayahacademy.com`
  (autre projet, PISI) à ne pas toucher.
- Vercel : projet `rewayah-academy`, id `prj_xDldWMLNH726BpwEVUlIAJUOSzPe`, équipe `team_VfPE1KP6vCKUyTeeG6AtAV8B`.
  Ne pas toucher au projet « app » (`prj_R7u9FzAIPGVDLeIPmJ30hQkXD78n`, PISI et `rewayah.academy`).

## 1. Garde-fou : ce qu'il faut savoir avant de commencer

`.claude/hooks/garde.py` refuse, pour tout agent : push vers `main`, PR vers `main`, fusion de PR, écriture sur
Vercel (`mcp__Vercel__*` hors lecture), écriture Supabase sur la production, toute écriture dans `.github/` et
`vercel.json`. Il ne se modifie que sur ordre explicite du directeur. Deux façons de faire :

- le directeur fait lui-même les gestes bloqués (fusion, ajout des domaines dans Vercel) et Claude fait le reste ;
- ou le directeur ordonne, par écrit et pour cette session, la levée précise des blocages nécessaires (lister
  lesquels), et Claude les rétablit à la fin.

Ne jamais contourner le garde-fou (pas de commande détournée, pas de script qui fait l'écriture interdite).

## 2. Mettre le site en production (choix du directeur, à demander s'il n'est pas écrit)

1. **Toute la branche dans `main`** : mise en production de l'application, du backend (Edge Functions par
   `deploy.yml`) et des workflows. Soumise aux contrôles CI, migrations et sécurité (`CLAUDE.md`, `04_EXECUTION…`).
   Chaîne : PR #44 → `claude/dazzling-edison-s8m5mf` → `main`.
2. **Le site seul** : branche depuis `main`, y apporter `site-public/` et l'étape « Teste et construit le site
   public » de `flutter-deploy.yml` (modification de `.github/`), puis PR vers `main`. Plus petit, plus sûr.

Après la fusion, vérifier (la production sert sur l'alias) :

```
curl -sI https://rewayah-academy.vercel.app/fr/          # 200, x-robots-tag: noindex
curl -s  https://rewayah-academy.vercel.app/robots.txt   # « Sitemap: https://rewayahacademy.com/sitemap.xml »
curl -s  https://rewayah-academy.vercel.app/sitemap.xml  # 16 URL en https://rewayahacademy.com/fr/...
```

Ne passer au §3 que si ces trois réponses sont bonnes.

## 3. Vercel : ajouter les domaines au projet `rewayah-academy`

Outils : `mcp__Vercel__add_project_domain` (écriture, voir §1), lecture par `list_project_domains`,
`get_domain_config`. Ou tableau de bord Vercel, Settings, Domains.

1. `rewayahacademy.com`, production, **domaine principal**. Si Vercel propose `www`, prendre l'option où `www`
   redirige vers `rewayahacademy.com` ; jamais l'option où `www` devient principal (boucle de redirections).
2. `www.rewayahacademy.com`, redirection 308 vers `rewayahacademy.com` (si pas créé à l'étape 1).
3. `app.rewayahacademy.com`, production.
4. Relire `get_domain_config` : noter les valeurs DNS recommandées (au 23/10 : A `216.198.79.1` et `64.29.17.1` ;
   CNAME `2fb4e585278fb72c.vercel-dns-017.com`). Si elles diffèrent, ce sont celles de Vercel qui comptent.

## 4. Cloudflare : DNS

Jeton attendu dans l'environnement : `CLOUDFLARE_API_TOKEN`, jeton personnalisé, permissions **Zone · DNS · Edit**
et **Zone · Zone · Read**, ressource **Specific zone : rewayahacademy.com**, durée 7 jours. Ne jamais l'afficher ni
le demander dans la conversation. API : `https://api.cloudflare.com/client/v4/` (joignable depuis le cloud).

1. Trouver l'identifiant de zone : `GET /zones?name=rewayahacademy.com`.
2. **Sauvegarde** : `GET /zones/{id}/dns_records/export` → fichier gardé dans le scratchpad, chemin donné au
   directeur. Lister aussi `GET /zones/{id}/dns_records`.
3. Montrer au directeur la **liste exacte** des changements et attendre son feu vert sur cette liste (`CLAUDE.md`) :
   - supprimer les A et AAAA de `rewayahacademy.com` (proxy orange, aujourd'hui en erreur 526) ;
   - créer A `@` `216.198.79.1` et A `@` `64.29.17.1`, **proxied: false** (nuage gris) ;
   - créer CNAME `www` et CNAME `app` vers `2fb4e585278fb72c.vercel-dns-017.com`, **proxied: false** ;
   - ne pas toucher : MX (5, Google), TXT (SPF `v=spf1 include:_spf.google.com -all`, `google-site-verification`),
     A `pisi` (`76.76.21.21`, PISI).
4. Appliquer, puis vérifier par DNS public (`https://cloudflare-dns.com/dns-query?name=…&type=A`, en-tête
   `accept: application/dns-json`) et par `get_domain_config` (champ `misconfigured: false`).
5. Le directeur révoque le jeton à la fin.

## 5. Contrôles après le domaine (attendre le certificat Vercel, quelques minutes)

```
curl -sI https://www.rewayahacademy.com/        # 308 → https://rewayahacademy.com/
curl -sI https://rewayahacademy.com/            # 307 → /fr/   (et non vers www)
curl -sI https://rewayahacademy.com/fr/         # 200, pas de x-robots-tag noindex, robots meta index,follow
curl -sI https://rewayahacademy.com/connexion   # 307 → https://app.rewayahacademy.com/connexion
curl -sI https://app.rewayahacademy.com/        # 200, x-robots-tag: noindex
curl -sI https://app.rewayahacademy.com/fr/     # 307 → https://rewayahacademy.com/fr/
```

## 6. Supabase (projet de production), Authentication, URL Configuration

L'application envoie comme retour l'origine **sans barre finale** (`lib/core/auth/service_auth.dart:48`).

1. Redirect URLs, ajouter : `https://app.rewayahacademy.com`, `https://app.rewayahacademy.com/**`,
   `https://rewayah-academy.vercel.app` (exacte) ; garder `https://rewayah-academy.vercel.app/**`.
   Jamais un nom suivi de `**` sans barre.
2. Tester sur `https://app.rewayahacademy.com/connexion` **et** `https://rewayah-academy.vercel.app/connexion` :
   lien de connexion reçu et ouvert ; connexion Google.
3. Seulement ensuite : Site URL `https://app.rewayahacademy.com`.
4. Google Cloud, écran de consentement OAuth : domaine autorisé `rewayahacademy.com`, accueil
   `https://rewayahacademy.com/fr/`, confidentialité `https://rewayahacademy.com/fr/legal/confidentialite`.

Ce sont des réglages de tableau de bord, hors migrations ; s'ils passent par un outil d'écriture Supabase, voir §1.

## 7. Moteurs de recherche (compte Google du directeur)

- Search Console : propriété « domaine » sans doute déjà vérifiée (TXT présent). Ajouter
  `https://rewayahacademy.com/sitemap.xml`, demander l'indexation de `https://rewayahacademy.com/fr/`.
- Bing Webmaster Tools : importer depuis Search Console.

## 8. E-mails : protection contre l'usurpation (console Google Workspace du directeur, puis DNS)

1. DKIM : Applications, Google Workspace, Gmail, Authentifier les e-mails ; générer (2048 bits, préfixe `google`) ;
   poser le TXT `google._domainkey` dans Cloudflare ; « Démarrer l'authentification ».
2. DMARC (après DKIM) : TXT `_dmarc` = `v=DMARC1; p=quarantine; rua=mailto:dmarc@rewayahacademy.com` (créer
   d'abord l'alias `dmarc@`). `p=reject` après un mois sans rejet légitime.
3. Gmail, Sécurité : protection contre l'usurpation des noms d'employés et des domaines ressemblants.

## 9. Après la bascule

- `lib/features/admin_avis/lien_avis.dart` : origine par défaut encore `https://rewayah-academy.vercel.app` ;
  passer à `https://app.rewayahacademy.com`.
- Paiement : quand `recharge-payer` sera déployée, son secret `APP_ORIGINES` doit contenir
  `https://app.rewayahacademy.com`.
- `.github/workflows/flutter-deploy.yml` : `SITE` vise encore l'alias vercel.app ; le laisser tant que l'alias sert
  l'application (les contrôles du workflow y lisent racine, SPA, wasm).
- Rendre compte au directeur avec les statuts de `CLAUDE.md` (présent dans le code / testé / déployé), sans PASS
  inventé.
