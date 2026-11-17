# PX-OAUTH : connecter le chat de claude.ai à Praxis avec le compte du directeur (phase 1 : étude et plan)

Écrit par BE-GESTES le 17/11/2026, sur ordre du Pilote Équipe (« étude et plan seulement, aucun code avant mon accord »).
**Aucun code, aucune migration, aucun réglage de production n'a été écrit ni touché.** Rien n'a été lu sur des personnes
(R14). `SECURITE-PRAXIS.md` prévaut sur ce document.

## 0. En dix lignes

- **Le besoin** : le chat claude.ai du directeur n'offre pas d'en-tête fixe (Nom et URL seulement). Le connecteur doit donc
  parler OAuth : `praxis-mcp` devient une ressource protégée, et le directeur se connecte avec son compte Rewayah.
- **Constat qui décide** : le serveur OAuth de Supabase Auth (bêta) émettrait des **jetons qui sont de vrais jetons
  d'utilisateur Supabase** (`role: authenticated`, `aud: authenticated`, le directeur comme `sub`). Claude en détiendrait un,
  valable contre toute l'API de Supabase. C'est exactement ce que R3 interdit (« Praxis n'a jamais de jeton de personne »).
- **Recommandation** : **option B**, un petit serveur d'autorisation à nous (une fonction Edge mince + des fonctions SQL),
  dont le **jeton d'accès est une clé Praxis ordinaire** (`prx_` + 64 hex, usage `chat`), émise à l'approbation du directeur
  dans l'application. Le jeton ne vaut que sur `praxis-mcp`, jamais sur l'API Supabase. Toute la sécurité existante
  (interrupteur, plafonds, mineurs, côtés, journal, révocation, émetteur toujours direction active) s'applique telle quelle.
- **Ce qui ne bouge pas** : la clé « routine », `praxis_porte`, les outils, le journal, les plafonds.
- **Ce qui est nouveau** : 1 table de clients + 1 de demandes + 1 de connexions (SQL), 1 fonction Edge `praxis-oauth`,
  un `401` correct sur `praxis-mcp`, **une page de consentement dans l'application** (un écran neuf, voir §9), et la
  révocation d'une connexion (la section Praxis la montre déjà comme une clé).
- **Estimation** : environ **5 jours de travail d'un agent** (§10), plus une épreuve avec le directeur dans son navigateur.
- **Le risque principal n'est pas prouvé** : le chemin de découverte que claude.ai essaie pour les métadonnées du serveur
  d'autorisation (§7). Il se teste tôt et à peu de frais (étape 2a).

## 1. Ce que claude.ai exige (sources lues aujourd'hui)

Pages officielles lues le 17/11/2026 : `claude.com/docs/connectors/building/authentication.md` et
`claude.com/docs/connectors/custom/add-unlisted.md`. Ce qui n'y figure pas est dit « non trouvé » : je ne l'invente pas.

| # | Exigence | Source / état |
| :-: | :--- | :--- |
| 1 | Sans jeton, le serveur MCP répond **401** (pas 200) avec `WWW-Authenticate: Bearer resource_metadata="<URL>"`. Claude ne tient pas compte de l'en-tête sur un 200. | page : « The 401 status is required ». |
| 2 | Métadonnées de ressource (RFC 9728) : `resource` **égal à l'URL MCP saisie, chemin compris** ; `authorization_servers` (**seule la première entrée est utilisée**) ; `scopes_supported` utilisé si aucun `scope` dans l'en-tête. `resource_metadata` peut pointer vers un autre hôte HTTPS. | page. |
| 3 | Métadonnées du serveur d'autorisation : RFC 8414 **ou** OpenID Connect Discovery. `registration_endpoint` pour DCR. `code_challenge_methods_supported: ["S256"]`. `offline_access` listé dans `scopes_supported` : ajouté aux scopes demandés. | page. **Chemin exact essayé : non trouvé.** |
| 4 | Client : DCR (RFC 7591) ou CIMD (document de métadonnées de client) ou client pré-enregistré. **Ordre : CIMD si le serveur l'annonce, sinon DCR.** Client DCR enregistré **comme client public**. | page. |
| 5 | PKCE **S256** à chaque demande. Rappel hébergé exact : `https://claude.ai/api/mcp/auth_callback` (claude.ai, Desktop, mobile). `/token` en `application/x-www-form-urlencoded` ; `/register` en JSON. Authentification au `/token` : `none` pour un client public. | page. Autre domaine de rappel (`claude.com`) : non trouvé. |
| 6 | Refresh : rotation attendue pour les clients publics (nouveau jeton rendu dans la même réponse) ; refresh invalide : `invalid_grant` (pas `invalid_request`) ; refresh réactif sur 401, proactif jusqu'à 5 min avant l'expiration. Durée de vie des jetons : non trouvée. | page. |
| 7 | Délais : **10 s** (découverte, enregistrement, token), **30 s** (refresh). | page. |
| 8 | Après l'ajout, les réglages d'authentification ne se modifient pas : il faut retirer le connecteur et le rajouter. | page. |
| 9 | Requêtes sortantes de Claude depuis `160.79.104.0/21` (un pare-feu devant le serveur peut casser le flux). | page. |
| 10 | Paramètre `resource` (RFC 8707) : **non trouvé** ; CORS : non trouvé ; autre URL de rappel : non trouvé. | — |

Aussi lu : un en-tête fixe n'est pas configurable sur une connexion OAuth, ce qui confirme que la clé collée ne remplace pas
OAuth pour le chat. (La page cite un type « `static_headers` (bêta) » pour d'autres usages ; le directeur ne l'a pas dans son
écran.)

## 2. Option A : Supabase Auth comme serveur d'autorisation

Source : documentation Supabase lue aujourd'hui (guides *Getting Started with OAuth 2.1 Server*, *OAuth 2.1 Flows*, *MCP
Authentication*, *Token Security and RLS*).

**Ce que Supabase fournit** : bêta gratuite ; points `/auth/v1/oauth/authorize`, `/oauth/token`, JWKS, découverte
`https://<ref>.supabase.co/.well-known/oauth-authorization-server/auth/v1` ; code d'autorisation + PKCE et refresh ; **DCR
optionnel** (« Allow dynamic registration », désactivé par défaut) ; page de consentement **à écrire côté application**
(`getAuthorizationDetails`, `approveAuthorization`, `denyAuthorization`) ; réglage « Authorization Path » dans le tableau de
bord.

**Pourquoi je la déconseille** :

1. **Le jeton est un jeton d'utilisateur Supabase complet.** La documentation le dit : les jetons OAuth « contiennent toutes
   les claims standard de Supabase » (`role: authenticated`, `aud: authenticated`, `session_id`, `aal`, plus `client_id`). Le
   chat de claude.ai garderait donc un jeton qui, présenté à l'API REST de Supabase, agit **comme le directeur** (une
   administration) partout où une politique ou une fonction ne teste pas `client_id`. La documentation propose d'ajouter
   `client_id IS NULL` dans les politiques « sensibles » : il faudrait l'ajouter à **toutes** les politiques et fonctions
   `SECURITY DEFINER` de la base. Ce n'est ni faisable ni prouvable. **R3 est violée par construction.**
2. **Pas de `resource` (RFC 8707)** dans la documentation lue : le jeton n'est pas lié à `praxis-mcp`. Un jeton volé chez Claude
   vaut contre toute la base. (Un « Custom Access Token Hook » pourrait changer `aud`, mais je n'ai **pas de preuve** que
   PostgREST refuserait alors le jeton ; je ne bâtirais pas une sécurité là-dessus.)
3. **Praxis cesserait d'être une clé** : `praxis_porte` n'accepte que `prx_…` ; il faudrait une seconde porte, fondée sur un
   JWT, avec son propre contrôle d'émetteur, de côtés, de révocation, de journal. Deux portes = deux surfaces à auditer.
4. **Réglages de production hors de notre contrôle** : activer « OAuth Server », le chemin d'autorisation, le DCR, éventuellement
   migrer vers des clés de signature asymétriques : des réglages du tableau de bord (directeur ou pilote), en bêta. Et
   `supabase_flutter` doit offrir `auth.oauth.*` : **non vérifié** (`pubspec.yaml` est hors de mes zones).
5. Le **DCR de Supabase est ouvert à « tout client MCP »** (la documentation recommande elle-même de surveiller les clients
   enregistrés) : on n'y bornerait pas les rappels à celui de Claude.

**Ce qui est bien dans A** (et que B doit égaler) : cryptographie, rotation des refresh, découverte, DCR sont déjà faits.
**Non prouvé** : l'état réel de la fonction chez nous (activée ou non) : je n'ai rien lu en production.

## 3. Option B : un petit serveur d'autorisation à nous (recommandée)

**Idée** : le seul rôle du serveur d'autorisation est d'obtenir, une fois, l'accord du directeur dans l'application (déjà
connecté, `aal2`), puis de remettre à Claude **une clé Praxis** et un jeton de renouvellement. Aucun jeton Supabase n'est
jamais émis.

### 3.1 Les pièces

**A. Fonction Edge `praxis-oauth`** (neuve, `verify_jwt = false` dans `config.toml`, comme `praxis-mcp`) : **aucune logique
métier**, elle valide le format puis appelle une fonction SQL (`service_role`), exactement comme `praxis-mcp`. Chemins :

| Chemin | Rôle |
| :--- | :--- |
| `GET /resource` | métadonnées de ressource (RFC 9728) : `resource` = URL exacte de `praxis-mcp`, `authorization_servers` = [cette fonction], `scopes_supported` = [`praxis`, `offline_access`] |
| `GET /.well-known/openid-configuration` et `GET /.well-known/oauth-authorization-server` | métadonnées du serveur : `issuer`, `authorization_endpoint`, `token_endpoint`, `registration_endpoint`, `response_types_supported: [code]`, `grant_types_supported: [authorization_code, refresh_token]`, `code_challenge_methods_supported: [S256]`, `token_endpoint_auth_methods_supported: [none]` |
| `POST /register` | DCR (JSON). Refuse tout rappel autre que `https://claude.ai/api/mcp/auth_callback` ; client public ; plafond de clients et débit borné en base |
| `GET /authorize` | valide `client_id`, `redirect_uri` (égalité exacte), `code_challenge` S256, `state` ; crée une **demande** (identifiant imprévisible, 10 min) ; redirige (302) vers la page de consentement de l'application |
| `POST /token` | `application/x-www-form-urlencoded` : `authorization_code` (PKCE) ou `refresh_token` (rotation) |

**B. SQL** (migrations additives, ancrées sur l'existant, scénario rouge puis vert, mutation) :

- `private.praxis_oauth_clients` (client_id, nom, rappels, créé le) ; `private.praxis_oauth_demandes` (authorization_id,
  client, rappel, `code_challenge`, `state`, expire) ; `private.praxis_oauth_connexions` (id de connexion, client, `emise_par`,
  empreinte du refresh, expire, révoquée). RLS active, aucune politique, `REVOKE` à tous, comme les tables Praxis.
- `public.direction_praxis_oauth_decider(p_demande uuid, p_accepter boolean)` : porte `authenticated`, **garde positive
  administrateur valide + `aal2`** (comme `direction_praxis_emettre_cle`). Si accord : fabrique le **code** (aléa de 32
  octets, seule son empreinte est gardée, 10 min, usage unique) et rend l'URL de retour vers Claude (`code`, `state`).
- Fonctions `praxis_oauth_*` pour `service_role` seul : enregistrer un client, créer une demande, échanger un code, renouveler
  un refresh. L'échange d'un code **crée la connexion et une clé `chat`** dans `praxis_cles` (même format, même empreinte), de
  durée courte (voir §6), libellée « Connexion claude.ai du … », `emise_par` = le directeur.
- `praxis_cles` : **une colonne nullable `connexion_id`** (additive) ; `direction_praxis_revoquer_cle` est retouchée **par
  ancrage** : révoquer une clé liée à une connexion **révoque la connexion** (sinon le refresh en referait une).

**C. `praxis-mcp`** (retouche, sans changer sa logique métier) :

1. Sans `Authorization`, ou clé mal formée : **401 + `WWW-Authenticate: Bearer resource_metadata="…"`** (aujourd'hui : 401 sans
   cet en-tête).
2. **Clé refusée en base** (révoquée, expirée, émetteur plus direction) : aujourd'hui, la réponse est une erreur JSON-RPC dans
   un **HTTP 200**. Claude ne rafraîchit **que sur 401** : il faut donc renvoyer **401** pour ces causes (une vérification
   légère `praxis_cle_valide(p_cle)` avant `initialize` et `tools/list`, et le même traitement des causes `cle_refusee` des
   outils). Les causes « éteint », « plafond » restent des erreurs d'outil (200) : ce ne sont pas des problèmes de jeton.

**D. L'application** : une page de consentement (§9), la liste des connexions dans la section Praxis (§8).

### 3.2 Pourquoi B respecte les règles

- **R3** : aucun jeton de personne n'existe. Le jeton d'accès est une clé Praxis ; il ne passe que par `praxis-mcp`.
- **Le jeton ne s'expose jamais** : la page de consentement ne montre aucun secret ; le code, la clé et le refresh ne sont
  ni journalisés ni stockés en clair (empreintes seulement) ; le journal Praxis et `log_sensitive_access` notent
  l'émission et la révocation sans secret.
- **Émetteur toujours une direction active** (AR-7 I5, déjà dans `praxis_porte`) : si le directeur perd son accès, la
  connexion s'arrête au prochain appel.
- **Côtés** : `private.praxis_cotes(emise_par)`, inchangés : la connexion hérite du côté du directeur qui l'a approuvée.
- **Mode** : une connexion OAuth est toujours `chat` (mode dirigé). Elle **ne peut jamais** devenir une clé `routine`.
- **Interrupteur** `praxis.actif` : inchangé, il coupe aussi la connexion OAuth au prochain appel.

## 4. Comment un jeton OAuth se rattache à une clé « conversation » existante

| Moment | Ce qui se passe | Où |
| :--- | :--- | :--- |
| Approbation | le directeur (aal2) accepte ; un code d'usage unique est remis à Claude | `direction_praxis_oauth_decider` |
| Échange du code | contrôle PKCE, client, rappel, expiration ; création de la **connexion** et d'**une clé `chat`** (jeton d'accès) + un **refresh** | `praxis_oauth_echanger_code` (service_role) |
| Chaque appel MCP | la clé est présentée comme toute clé : `praxis_porte` la relit (révoquée, expirée, émetteur, interrupteur) | inchangé |
| Renouvellement | un refresh valide donne **une nouvelle clé** et un **nouveau refresh** ; l'ancien refresh meurt ; **la réutilisation d'un refresh déjà consommé révoque toute la connexion** | `praxis_oauth_renouveler` |
| Révocation | révoquer la clé (ou la connexion) dans la section Praxis révoque la connexion et toutes ses clés | `direction_praxis_revoquer_cle` retouchée |

Aucun secret n'est exposé : l'application ne voit jamais la clé ; Claude ne voit jamais l'identifiant d'utilisateur ni de jeton
Supabase.

## 5. Ce qui reste inchangé

La clé « routine » (collée en en-tête par la tâche planifiée), son émission (`direction_praxis_emettre_cle`), `praxis_porte`
(sauf l'ajout d'une lecture de `connexion_id` dans le journal si on le veut), les outils `boite/fil/ecrire/annoncer/…`, les
plafonds, le journal, les mineurs, le mode essai, les données réelles fermées.

## 6. Durées proposées (à confirmer)

| Objet | Durée | Pourquoi |
| :--- | :-: | :--- |
| code d'autorisation | 10 min, usage unique | habituel ; cohérent avec les 10 s de délai de Claude |
| jeton d'accès (clé `chat`) | 1 h | une clé volée vaut peu ; le refresh est proactif 5 min avant |
| refresh | 30 jours glissants, **90 jours au plus** au total | `praxis_cles` borne déjà une clé à 90 jours ; la connexion se reprend alors par un nouveau consentement |
| clients DCR | 20 au plus, débit borné | évite l'encombrement par enregistrements répétés |

## 7. Ce qui n'est pas prouvé (dit en premier, comme la règle l'exige)

1. **Le chemin de découverte du serveur d'autorisation.** Une fonction Edge ne sert que sous `/functions/v1/<nom>/…`. Si
   l'émetteur est `https://<ref>.supabase.co/functions/v1/praxis-oauth`, la découverte RFC 8414 « avec insertion du chemin »
   tombe sur `/.well-known/oauth-authorization-server/functions/v1/praxis-oauth`, que nous ne pouvons pas servir. Il reste la
   découverte OpenID « par ajout » (`<émetteur>/.well-known/openid-configuration`), que je sers. **Je n'ai aucune preuve que
   claude.ai l'essaie** (la page ne donne pas l'ordre des chemins). **Test peu coûteux, à faire en premier (étape 2a)** : ne
   déployer que `/resource`, les métadonnées et le 401, puis demander au directeur d'ajouter le connecteur : si Claude parvient à
   l'écran d'autorisation, la découverte marche.
   **Plan de repli** : servir les métadonnées sur le domaine de l'application (`app.rewayahacademy.com/.well-known/...`, une
   réécriture dans `vercel.json`, **zone du pilote et du directeur**, pas la mienne), avec un émetteur sans chemin.
2. **Le comportement de Claude à l'expiration** : la page dit qu'il rafraîchit sur 401 puis reçoit `invalid_grant`. Je n'ai pas
   vu ce que l'interface montre alors au directeur : à constater lors de l'épreuve.
3. **Le paramètre `resource`** : non trouvé ; je l'accepte et l'ignore (le jeton ne vaut de toute façon que sur `praxis-mcp`).
4. **Le rappel unique** `https://claude.ai/api/mcp/auth_callback` : suffisant pour le chat web d'après la page ; Claude Code ou
   d'autres clients auraient d'autres rappels (non demandés ici).
5. **L'état de production** : rien n'a été lu (fonctions, réglages, journaux).

## 8. Révocation et section Praxis

La section Praxis (`lib/features/admin_acces_agents/section_praxis.dart`) montre déjà les clés et leur révocation. Une connexion
OAuth y apparaît comme une clé libellée « Connexion claude.ai du … », avec son expiration. Révoquer cette clé **révoque la
connexion** (colonne `connexion_id`, retouche ancrée de `direction_praxis_revoquer_cle`). Le renouvellement crée une nouvelle clé
de même libellé : la section ne doit pas se remplir de clés d'une heure. **À décider** : afficher une ligne par **connexion**
(la clé courante en dessous), pas une ligne par clé. Une petite retouche de `direction_praxis_etat` ou d'une lecture dédiée.

## 9. La page de consentement (écran neuf dans l'application)

- Route neuve (par exemple `/admin/praxis/autoriser?demande=…`), réservée à la direction. Elle **exige `aal2`** : sans lui, la
  feuille de double vérification existante (`avecDoubleVerification`, `lib/features/mfa_controleur/double_verification.dart`) la
  demande avant tout appel.
- Contenu : « Claude demande à se connecter à Praxis » ; ce que cela permet **en mots simples** (lire et écrire des messages
  de l'académie dans les limites de Praxis, jamais les enfants, jamais l'argent ; vous pouvez couper à tout moment par
  l'interrupteur ou la révocation) ; le nom du client **et l'hôte du rappel** (contre l'hameçonnage : tout client DCR peut se
  nommer « Claude ») ; deux gestes : **Autoriser** / **Refuser**.
- États obligatoires : chargement, contenu, vide (demande inconnue ou expirée : une phrase vraie), erreur, hors ligne ;
  textes fr / en / ar par la compétence `mots-rewayah` ; captures R3 ; tests 320 et 1440, texte ×2.
- **Attention à la règle de la mission** (« aucun nouvel écran ») : cet écran est **nécessaire** (sans lui, aucun OAuth) ; il
  faut l'accord écrit du pilote ou du directeur avant de l'écrire. C'est la seule entorse.

## 10. Lots, ordre, fichiers, estimation

Estimation en jours de travail d'un agent, avec le même soin qu'ailleurs (scénario rouge puis vert, mutation, tests, captures).
**Ce sont des estimations, pas des mesures.**

| Étape | Contenu | Zone | Jours |
| :-: | :--- | :--- | :-: |
| **2a** | **Découverte seule** : `praxis-oauth` avec `/resource` et les métadonnées ; `praxis-mcp` rend 401 + `WWW-Authenticate` ; `config.toml` ; tests Deno. **Épreuve avec le directeur** : ajouter le connecteur et constater que Claude atteint l'autorisation. | `supabase/functions/**`, `config.toml` | 0,5 |
| 2b | SQL : tables, `direction_praxis_oauth_decider`, fonctions `praxis_oauth_*`, colonne `connexion_id`, retouche ancrée de `direction_praxis_revoquer_cle`, `praxis_cle_valide` ; empreintes de production lues avant ; scénarios rouge puis vert ; mutations ; liste blanche des fonctions (tests `af_*`, R4) | `supabase/migrations/**`, `supabase/tests/**` | 1,5 |
| 2c | Fonction Edge : `/register`, `/authorize`, `/token` (code, refresh, rotation, `invalid_grant`), CORS minimal, plafonds ; tests Deno (PKCE faux, rappel étranger, code rejoué, refresh rejoué) | `supabase/functions/**` | 1 |
| 2d | Page de consentement : route, service, états, textes fr/en/ar, tests, captures R3 (**décision requise, §9**) | `lib/features/**`, `assets/i18n/**`, `lib/core/router/**` | 1 |
| 2e | Section Praxis : une ligne par connexion, révocation, textes | `lib/features/admin_acces_agents/**` | 0,5 |
| 2f | Intégration : revue du pilote (R15), installation par le pilote, épreuve complète avec le directeur (connexion, un message lu, révocation, reconnexion) | pilote, directeur | 0,5 |
| | **Total** | | **≈ 5** |

Parallélisme : 2b et 2c se préparent ensemble (2c s'appuie sur les signatures de 2b) ; 2d dépend du seul contrat de
`direction_praxis_oauth_decider`. Une PR par étape ; l'étape 2a n'a **aucune migration** et peut partir seule.

## 11. Menaces et parades

| Menace | Parade prévue |
| :--- | :--- |
| Enregistrement massif de faux clients (DCR ouvert) | rappel unique en liste blanche ; 20 clients au plus ; débit borné en base ; client inutilisé purgé |
| Redirection ouverte | `redirect_uri` en **égalité exacte** avec un rappel enregistré, jamais de motif |
| Interception du code | PKCE **S256 obligatoire** ; code d'usage unique, 10 min, empreinte seule ; échange refusé si client ou rappel diffèrent |
| Rejeu d'un refresh volé | rotation ; **réutilisation d'un refresh consommé = révocation de la connexion entière** |
| Faux consentement (CSRF, hameçonnage) | `authorization_id` imprévisible, lié au client et au rappel ; la page montre le nom du client **et l'hôte du rappel** ; `aal2` exigé ; la décision se refait côté SQL |
| Jeton volé chez Claude | il ne vaut que sur `praxis-mcp` ; 1 h ; révocation immédiate ; interrupteur général ; émetteur contrôlé à chaque appel |
| Un compte non-direction approuve | garde positive `admin` valide + `aal2` en SQL (comme `direction_praxis_emettre_cle`) |
| Secrets dans les journaux | aucun secret journalisé ; empreintes seulement ; test qui échoue si un journal contient `prx_` ou un code |
| Abus de `/token` | débit borné par client en base ; erreurs `invalid_grant` constantes (pas d'oracle) |
| SSRF | pas de CIMD (aucun document de client à aller chercher) : l'AS **n'annonce pas** `client_id_metadata_document_supported`, donc Claude passe au DCR |

## 12. Décisions à prendre

1. **Option B** (recommandée) plutôt que A : oui / non.
2. L'écran de consentement (§9) : accord pour un écran neuf ?
3. Durées (§6) : 1 h / 30 jours / 90 jours au plus, ou autres.
4. Découverte : tenter d'abord **sans** `vercel.json` (étape 2a), et ne demander la réécriture de domaine que si l'épreuve échoue ?
5. Une ligne par connexion dans la section Praxis (§8) ?
6. Hors périmètre à confirmer : Claude Code et autres clients (rappels locaux) ne sont **pas** autorisés.

## 13. Ce que je n'ai pas fait

- Aucune ligne de code, aucune migration, aucune écriture en production, aucun réglage de tableau de bord.
- Je n'ai pas lu l'état de production (fonctions Edge déployées, réglages d'authentification, clés existantes).
- Je n'ai pas essayé de connecter claude.ai : l'épreuve est l'étape 2a.
- Je n'ai pas vérifié que `supabase_flutter` offre `auth.oauth.*` (inutile pour l'option B, qui n'emploie pas le serveur OAuth de Supabase).
