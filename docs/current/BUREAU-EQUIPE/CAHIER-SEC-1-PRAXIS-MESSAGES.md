# Cahier SEC-1 : Praxis répond aux messages (serveur et connecteur)

Écrit par le pilote le 16/11/2026, à 21 h 30 UTC. Ordre du directeur, le même soir : « finis d'abord l'agent IA,
l'agent qui va travailler avec nous et qui répond aux messages ; c'est prioritaire quand tu finis les tâches déjà
commencées ». Cette décision passe avant BE-2a-2, BE-2b, BE-2c et BE-2d.

Vision : `SECRETAIRE-IA.md` (§3 niveaux d'autonomie, §5 connecteur, §9 et §11 identité et décisions). Ce cahier
tranche ce qu'elle laisse ouvert ; chaque arbitrage est marqué **A-n**. Lot sensible : le serveur interdit
aujourd'hui toute écriture à un agent (`0014_acces_agent.sql`). Chaque refus doit être testé un par un.


> **16/11, 22 h 15 : `PRAXIS/SECURITE-PRAXIS.md` prévaut sur ce cahier.** Il ajoute notamment : plafond par fil
> (3 messages de suite sans réponse), annonces 2 par jour, longueurs maximales, expiration des clés (90 jours au
> plus), **aucun fil ni public avec un mineur (§3)**, Praxis absent de toute liste de personnes (R13), textes tiers
> rendus dans un champ `contenu_tiers`, liste blanche exacte des fonctions (R2). Chaque règle R1 à R15 a son
> scénario, nommé dans la PR.
## 0. La phrase de recette

« Dans mon chat Claude, je dis à Praxis : réponds aux messages qui attendent. Il lit la boîte de l'académie, répond
lui-même dans l'application au nom de *#RA_PRAXIS*, me dit en cinq lignes ce qu'il a envoyé et ce qu'il me laisse.
Je coupe l'interrupteur : il ne peut plus rien envoyer. »

## 1. Arbitrages

- **A-1. Un compte Praxis, unique.** Un profil non humain, marqué « compte officiel » (indicateur de compte, jamais
  dans le nom), sans mot de passe ni connexion possible : on ne peut pas se connecter avec. Les messages sont signés
  par ce profil. Le compte de l'administration reçoit le même indicateur (`#RA_STAFF`, §9).
- **A-2. Le privilège tient à la requête, pas au compte** (règle 1 de `0014`).
  - Le connecteur présente une **clé Praxis** émise par la direction en double authentification (`aal2`). La clé
    est montrée une seule fois, et seule son empreinte sha256 est gardée.
  - À chaque appel, le serveur relit la clé (active, non révoquée, non expirée), l'interrupteur et le plafond.
  - Chaque clé est attachée à la personne qui l'a émise : le journal écrit « secrétaire de <personne> ».
- **A-3. Le transport.** Une fonction Edge `praxis-mcp` sert le protocole MCP en HTTP (« streamable HTTP »).
  - Le directeur l'ajoute comme connecteur personnalisé dans son chat (Claude, ou tout client MCP), avec la clé
    comme jeton `Bearer`.
  - La fonction n'a aucune logique métier : elle valide le format, puis appelle une fonction SQL `praxis_*` par
    outil, avec le rôle `service_role`.
  - Toute la vérification se fait en base, dans les fonctions `praxis_*`, qui sont `SECURITY DEFINER` avec
    `search_path = ''`. `EXECUTE` est donné au seul `service_role`, ni à `anon` ni à `authenticated`.
- **A-4. Où Praxis écrit (niveau A).** Il écrit dans les conversations adressées à l'académie : les fils où la
  direction ou l'administration est participante. Il y écrit avec le profil Praxis, par la même table et les mêmes
  effets que `com_envoyer_message` (notifications, non-lus). Il réutilise la fonction interne si elle existe, il n'en
  écrit pas une seconde ; sinon, il passe par une fonction privée commune aux deux.
  - Il lit et écrit aux deux côtés (décision du directeur, §11).
  - Quand un membre de l'équipe a écrit dans un fil après Praxis, celui-ci se tait dans ce fil. L'outil `ecrire`
    refuse avec la cause `repris_par_equipe`.
- **A-5. Les annonces.** L'outil `annoncer` passe par le circuit des annonces existant (`com_annonce_publier` ou sa
  fonction interne) : même ciblage, même trace, auteur Praxis.
- **A-6. Les garde-fous de l'envoi direct.**
  - Un interrupteur de la direction (`praxis.actif`, dans les réglages de l'application) coupe tout d'un coup.
  - Un plafond d'envois par heure (`praxis.envois_par_heure`, 30 par défaut).
  - Jamais deux fois le même envoi : une clé d'idempotence est exigée.
  - Une limite de longueur par message.
- **A-7. Ce que Praxis ne voit jamais** : une pièce d'identité, un contact (courriel, téléphone), une donnée
  financière, un mot de passe ou un jeton. Il ne fait jamais : refuser, accepter, supprimer, changer un droit,
  déplacer de l'argent (niveaux B, C, D). Ses outils ne l'exposent tout simplement pas.
- **A-8. Les données.** Praxis n'est **pas mis en service** (interrupteur coupé à l'installation) avant que la
  politique de confidentialité dise qu'un assistant numérique lit les messages (§11). La phrase est préparée au
  niveau C. **L'allumer est un geste du directeur** dans l'application, pas un geste d'agent.

- **A-9. Réutiliser l'existant** (directeur, 16/11, 21 h 35 : « il y avait déjà une entrée IA presque prête dans la
  console »). L'écran « Accès des agents IA » existe (`lib/features/admin_acces_agents/acces_agents_page.dart`,
  route `/admin/securite-audit/acces-agents`, ADR-025, `0014_acces_agent.sql`, fonction `agent-session`). Il émet
  des jetons `rag_…`, montrés une fois, dont seule l'empreinte est gardée, avec expiration, révocation et signal
  « jamais utilisé ». Aujourd'hui, ces jetons ne servent qu'à **observer en lecture seule** l'application dans un
  navigateur, à la place d'une personne.
  - La clé Praxis reprend ce modèle : même écran (une section « Praxis »), même règle « montré une fois », même
    « Pourra / Ne pourra pas ».
  - L'agent lit d'abord la table des jetons d'agent et ses fonctions :
    - s'il peut les étendre (une colonne `usage` : `observation` ou `praxis`) sans affaiblir les règles 1 à 5 de
      `0014`, il les étend ;
    - sinon, il crée `praxis_cles` à côté et dit pourquoi dans la PR.
  - Aucun jeton `rag_…` d'observation ne doit pouvoir appeler un outil Praxis, et l'inverse non plus (scénario).
- **A-10. Dirigé ou autonome, au choix du directeur.**
  - Il y a deux sortes de clés Praxis :
    - **« chat »** : le directeur dirige Praxis depuis son chat (Claude, Codex) ;
    - **« routine »** : une tâche planifiée fait travailler Praxis seul.
  - Un réglage `praxis.autonome` (faux à l'installation), basculé par le directeur sur l'écran, en double
    authentification (`aal2`) :
    - **faux** : toute clé « routine » est refusée par le serveur, et Praxis n'agit que quand le directeur le dirige ;
    - **vrai** : les clés « routine » travaillent.
  - `praxis.actif` reste l'arrêt général : faux coupe les deux sortes de clés.
  - Un outil `etat` rend à Praxis son mode (dirigé ou autonome), son plafond restant et ce qu'il n'a pas le droit de
    faire. Il le lit au début de chaque séance.
  - Scénarios : une clé « routine » est refusée avec `autonome` à faux et acceptée à vrai ; une clé « chat » est
    acceptée dans les deux cas ; `actif` à faux refuse les deux.
  - La tâche planifiée elle-même (la routine qui appelle le connecteur) se crée après l'installation, quand le
    directeur allume le mode autonome. Ce n'est pas du code du dépôt.

- **A-11. Le compte Praxis est créé directement en base** (directeur, 16/11 : « passer par Supabase directement, pour
  qu'il évite les parcours »). La migration crée l'utilisateur d'authentification sans mot de passe ni identité de
  connexion, son profil et l'indicateur de compte officiel. Elle ne passe par aucun parcours : ni inscription, ni
  invitation, ni candidature, ni accueil. Le compte n'apparaît dans aucune liste de personnes, et aucun courriel ne
  lui est envoyé.
  - L'agent vérifie d'abord, en lecture seule, comment `auth.users`, `auth.identities` et `public.profiles` sont liés
    en production (contraintes, déclencheurs qui réagissent à une création de profil : courriels, notifications,
    matricule), pour qu'aucun effet de bord ne parte.
  - Scénario : aucune identité de connexion, aucun mot de passe, aucune ligne dans les files d'envoi après la
    création.

## 2. Les outils de SEC-1 (réponses courtes, déjà triées)

| Outil | Entrée | Rend | Écrit |
| :--- | :--- | :--- | :--- |
| `boite` | filtre (attend une réponse, non lu, tout), limite ≤ 50 | par fil : id, interlocuteur (prénom, rôle), dernier message (300 signes), attente en heures, nombre de non-lus | rien |
| `fil` | id du fil, limite ≤ 50 | les derniers messages (auteur, rôle, date, texte), qui a écrit en dernier, si l'équipe a repris le fil | rien |
| `ecrire` | id du fil, texte, clé | ok, id du message, ou la cause du refus | un message (auteur Praxis) et sa trace |
| `annoncer` | public (selon `com_annonce_publics`), titre, texte, langue, clé | ok, nombre de destinataires | une annonce et sa trace |
| `calendrier_annonces` | période | les sujets connus d'avance (table nouvelle, remplie par la direction et par Praxis) | `ajouter` : une ligne |
| `alerter_responsable` | personne de l'équipe, sujet, texte, urgence | ok | une notification (circuit push et notification existant) |
| `etat` | rien | mode (dirigé ou autonome), actif, plafond restant, interdits | rien |
| `rendre_compte` | période | ce que Praxis a envoyé (fil, extrait, heure) et ce qu'il a laissé | rien |

## 3. Tables (schéma `private`, RLS activée, aucun droit pour les rôles de l'API)

- `praxis_cles` : `id`, empreinte, émise par, émise le, expire le, révoquée le, motif.
- `praxis_journal` : ajout seul. Chaque appel d'outil avec la clé, l'outil, le résultat (ok ou cause) et les
  identifiants touchés ; jamais le texte d'un message tiers.
- `praxis_calendrier` : sujet, public, date, récurrence, statut.
- Réglages : `praxis.actif` (faux à l'installation) et `praxis.envois_par_heure`, dans la table de réglages
  existante (A5).

## 4. Portes de la direction (pour l'écran, lot suivant)

- `praxis_emettre_cle(expire_le, cle)` : rend la clé une seule fois. `praxis_revoquer_cle(id, motif, cle)`.
- `praxis_regler(actif, envois_par_heure)`.
- Ces trois portes sont réservées à la direction en double authentification (`aal2`), avec une ligne d'audit.

## 5. Scénarios obligatoires (`supabase/tests/scenarios_sec1_praxis.sql`)

Chacun vérifie l'état de la base après l'appel :

1. Clé absente, fausse, révoquée ou expirée : refus, rien d'écrit.
2. Interrupteur coupé : `ecrire` et `annoncer` refusés ; `boite` et `fil` aussi (Praxis éteint ne lit pas).
3. Plafond par heure atteint : refus avec la cause `plafond`.
4. Même clé d'idempotence : un seul message.
5. Fil sans la direction ni l'administration : refus.
6. Fil repris par un membre de l'équipe après Praxis : refus `repris_par_equipe`.
7. Aucun outil ne rend un courriel, un téléphone, une pièce d'identité ou un montant (recherche des champs dans les
   réponses).
8. `anon` et `authenticated` n'exécutent aucune fonction `praxis_*` ; seul `service_role` le peut
   (`has_function_privilege`).
9. Le compte Praxis ne peut pas se connecter (aucune identité de connexion).
10. Les portes de la direction refusent sans `aal2`.

La garde AF-LB (liste blanche des fonctions qui écrivent) est mise à jour avec une justification pour chaque
fonction.

## 6. Fonction Edge `praxis-mcp`

- Ouverte sans vérification du JWT de Supabase, dans `config.toml`, pour cette seule fonction : le contrôle se fait
  par la clé Praxis en base. Elle refuse toute requête sans `Authorization: Bearer`.
- Elle est servie en HTTP « streamable », sans état. Elle décrit les outils du §2 avec leur schéma.
- Tests Deno : appel sans clé, appel avec une clé refusée par la base, et appel nominal simulé.
- Le déploiement suit le circuit normal (fusion, puis déploiement automatique des fonctions).

## 7. Ce que SEC-1 ne fait pas

- **L'écran** : interrupteur, clés, plafond (lot SEC-1-ECRAN, après) ; affichage *#RA_PRAXIS*, « Assistant de
  l'académie · IA », « Parler à l'équipe » dans les conversations (domaine du Pilote Messagerie, demandé).
- **Les compétences** (`voix-directeur`, `repondre-rewayah`, `annoncer-rewayah`, `savoir-rewayah`, `agir-rewayah`) :
  un lot à part, sans code, **avant toute mise en service**.
- SEC-2 à SEC-5.

## 8. Livraison

Une PR en brouillon, `claude/sec1-praxis`. Le pilote réserve la plage de migrations au registre avant le premier
fichier : **202611296…**, réservée pour Praxis le 16/11 par le pilote équipe (la plage 202611295… est celle de la
messagerie). La PR contient les scénarios du §5, la mise à jour d'AF-LB, la ligne de `REGISTRE-LOTS.md` et la liste
de ce qui n'est pas prouvé. Le pilote relit, fusionne et installe ; l'interrupteur reste coupé.
