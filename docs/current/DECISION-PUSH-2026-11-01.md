# Notifications push (Web Push), décision du 01/11/2026

Décision écrite par le pilote. Le directeur a délégué la stratégie (« c'est toi qui l'as
mentionné… en discuter avec le grand pilote ») ; validée par le garde-cap le 01/11/2026 à 03:50
UTC, avec ses quatre ajustements. Elle prolonge `DECISION-NOTIFICATIONS-COURRIEL-2026-11-01.md`.

## 1. Ce qui est fait, ce qui ne l'est pas

- Fait par le directeur le 01/11 : trois secrets de fonctions Edge en production,
  `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, `VAPID_SUBJECT`. Non vérifiable par le pilote : aucun
  outil ne liste les noms des secrets, et les valeurs ne sont jamais lues.
- Rien du push n'existe dans le code au 01/11 (vérifié sur `main` : `lib/`, `web/`, `supabase/`).
  Seule la ligne DASH-BR-05 de `DASH_STRATEGIE.md` en parle.

## 2. La règle

Le push est un troisième débouché de la même notification, pas un nouveau canal. Chaque ligne de
`public.notifications` est dans l'application. Un courriel part si son drapeau le dit. Un push
part si le drapeau `push` le dit. Le serveur décide, par événement et par portée ; aucune règle
dans Flutter.

### Push : oui (urgent seulement)

Règle de tri : une notification est urgente quand elle sert à quelqu'un qui doit agir dans la
minute. Urgente, elle part en push ; sinon, elle reste dans l'application.

| Événement | Portée | Raison |
|---|---|---|
| `seance_annulee` | toutes | la famille ne doit pas se connecter pour rien |
| `seance_deplacee` | toutes | la famille doit changer d'heure |
| `enseignante_absente` | toutes | la famille doit savoir avant de se connecter |
| `remplacement_propose`, `remplacement_pris` | toutes | un enseignant doit prendre la séance |
| `remplacement_designe_admin` | l'enseignant désigné, le foyer | l'enseignant désigné doit se préparer ; même logique que pour le courriel |
| `creneau_change` | toutes | la famille doit changer d'heure |
| `titulaire_en_retard` | `direction` seulement | la direction doit trouver un remplaçant dans la minute ; la classe, déjà dans la salle, le lit dans l'application |

Pas de push pour :
- `remplacant_arrive` : les présents sont déjà dans la salle et n'ont rien à faire ;
- `seance_terminee` : ni courriel ni push ;
- tout le reste.

## 3. Comment (le lot)

1. **Une file, pas un déclencheur synchrone.** Une table `push_sortants`, sur le modèle de
   `courriels_sortants` (`20261023120000_courriels_sortants.sql`), vidée par la même mécanique,
   avec reprise et compteur d'échecs. Un push qui échoue ne bloque jamais l'écriture de la
   notification ni le courriel.
2. **Abonnements.** Une table `abonnements_push`, une ligne par appareil, sous RLS : chacun ne
   voit que les siens. RPC d'inscription et de désinscription. Un abonnement mort (410) est
   retiré. Aucun compte enfant ne s'abonne.
3. **Contenu.** Un titre court, un texte sans aucun nom d'enfant ni d'enseignant, et la
   `destination` à ouvrir. Le détail reste dans l'application. Textes en FR et en AR, compétence
   `mots-rewayah`.
4. **Envoi.** Une fonction Edge signe en VAPID côté serveur, avec les secrets ci-dessus. La clé
   publique est servie par le serveur, jamais écrite dans Flutter.
5. **PWA.** Un worker séparé gère `push` et `notificationclick` (le clic ouvre la
   `destination`). Il est enregistré par `web/index.html` ou par `importScripts`. Il ne touche
   jamais `flutter_service_worker.js`, que le build régénère. L'autorisation est demandée une seule
   fois, après un geste de la personne, jamais au démarrage. `.github/`, `vercel.json` et
   `pubspec.yaml` restent au directeur : le lot dit avant d'ouvrir s'il en a besoin.

## 4. Preuve

- **R3, sur la pile locale**, avec des clés VAPID locales (la pile ne lit jamais celles de la
  production) : une séance annulée fait apparaître la notification sur un deuxième navigateur
  abonné, avec une capture et le texte attendu vérifié par le robot.
- **Preuve finale, par le directeur** : un push reçu sur son téléphone Android, application
  fermée. Sur iPhone, le push ne marche que si l'application est ajoutée à l'écran d'accueil.

## 5. Quand

Hors Boucle 1 : c'est un lot nouveau. Il vient après la fusion de la PR FN-028 du lot « fin de
séance », qui crée `seance_terminee` et le drapeau `courriel`. Il prend la place de construction
libérée par ce lot : jamais un troisième constructeur. Rien n'est ouvert avant.

| | Statut |
|---|---|
| Règle et table | spécifié (01/11/2026) |
| Secrets VAPID en production | posés par le directeur, non vérifiés par le pilote |
| Code | rien |
