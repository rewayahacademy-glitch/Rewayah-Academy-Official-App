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


## 6. Amendement du 07/11/2026 : le push pour tous les rôles (PUSH-1)

Décision du directeur, le 07/11/2026 : « le vrai user a besoin des notifications. Moi
personnellement j'en ai besoin. Je ne reçois pas de notifications. » Puis, vers 11:25 : « les
notifs sont plus que la liste que tu as citée, les autres rôles en ont tout aussi besoin. »
Traduite par le garde-cap le même jour, avec les arbitrages du pilote. **Elle modifie le §2**
ci-dessus, qui ne vaut plus que pour son historique.

### 6.1 La règle, qui remplace le §2

1. Le push couvre **tous les rôles qui ont un compte** : tuteur, élève adulte, enseignant,
   direction, comptable (et contrôleur). **Jamais un compte enfant** : un élève dont le profil est
   « minor », ou un élève sans profil autonome, ne peut ni s'abonner ni recevoir un push
   (`private.push_compte_autorise`).
2. **Par défaut, toute ligne de `public.notifications` destinée à la personne part aussi en
   push.** Seules restent dans l'application les notifications exclues **nommément**, côté
   serveur, par événement et par portée, dans la même table que le drapeau courriel
   (`private.notification_courriel`, colonne `push`). Exclusions au 07/11 :
   `seance_terminee`, `remplacant_arrive`, `titulaire_en_retard` sauf pour la direction,
   `creneau_personnalise_demande`, `remboursement_demande`.
3. Chaque personne **coupe le push par catégorie** dans ses Réglages (cinq catégories : Classes
   et séances, Remplacements, Paiements, Demandes et dossiers, Suivi des élèves). La catégorie
   d'un événement est décidée par le serveur (`private.push_evenements`).
4. Chaque événement qui attend un geste **crée une notification pour la bonne personne**. Les
   manques relevés le 07/11 sont comblés, en commençant par la direction ; la finance va au
   comptable **en plus** de la direction.
5. **Écran verrouillé** (garde-cap, 07/11) : le texte d'un push ne contient jamais le nom d'un
   mineur, ni un montant, ni un motif de signalement. Le détail se lit dans l'application, après
   connexion. Les candidatures portent une étiquette de regroupement : le téléphone garde une
   seule alerte « N nouvelles candidatures à examiner ».
6. Un échec d'écriture d'une notification ne bloque jamais le geste métier, mais laisse une trace
   (`private.notifications_echecs` : événement, source, SQLSTATE, sans donnée personnelle).

### 6.2 Les notifications nouvelles

| Événement | Source | Destinataires | Destination | Geste |
|---|---|---|---|---|
| `admission_recue` | `candidatures` famille ou élève adulte « à traiter » (au COMMIT) | direction | `/admin/personnes/demandes` | oui |
| `candidature_enseignant_a_examiner` | `candidatures` enseignant, réponses envoyées | direction | `/admin/personnes/candidatures` | oui |
| `demande_horaire_recue` | `demandes_horaires_famille` envoyée | direction | `/admin/operations/demandes` | oui |
| `creneau_personnalise_demande` | `demandes_creneau_personnalise` | direction | `/admin/operations/demandes` | non |
| `piece_identite_deposee` | `kyc_documents` en attente | direction | `/admin/personnes/dossiers` | oui |
| `signalement_eleve_recu` | `student_concern` ouvert | direction | `/admin/alertes` | oui |
| `suppression_compte_demandee` | `demandes_suppression_compte` | direction | `/admin/personnes/suppressions` | oui |
| `remplacement_personne_en_salle` | `private.remplacement_auto_passer`, à côté du courriel | direction | `/admin/operations/planning` | oui |
| `paiement_echoue` | `commandes_recharge` échouée | foyer (jamais l'enfant), direction, comptable | `/tuteur/foyer/recharge`, `/admin/finance`, `/comptable/tresorerie/paiements-familles` | oui |
| `versement_coordonnees_a_valider` | `versement_coordonnees` | direction, comptable | `/admin/finance/paiements`, `/comptable/paiements/beneficiaires` | oui |
| `versement_coordonnees_validees` | `versement_coordonnees` validées | l'enseignant | `/compte/paiements-recus` | non |
| `remboursement_demande` | `remboursements_demandes` | direction, comptable | `/admin/finance`, `/comptable/tresorerie/paiements-familles` | non |
| `remboursement_echec` | `remboursements_demandes` en échec | direction, comptable | idem | oui |
| `cahier_en_retard` | aucune dans ce lot (lot C3) | | | oui |

En plus : le comptable reçoit `litige_ouvert`, `litige_clos` et `remboursement_effectue` de la
direction ; `titulaire_en_retard` (direction) et `remplacement_avertissement` (enseignant)
demandent un geste.

Dettes nommées : aucun refus des coordonnées de versement n'existe dans le schéma ; le cahier en
retard n'a pas d'émetteur ; `private.c29_clore_mission_controle` n'applique pas `access_until` ;
`paiement_echoue` n'a pas de courriel.

### 6.3 Les textes de l'application

| Clé | Texte (français) |
|---|---|
| `push1.evenements.admissionRecue` | Une nouvelle demande d'admission est à examiner. |
| `push1.evenements.candidatureEnseignant` | Une candidature d'enseignant est à examiner. |
| `push1.evenements.demandeHoraireRecue` | Une nouvelle demande d'horaire est à examiner. |
| `push1.evenements.creneauPersonnalise` | Un horaire personnalisé est demandé. |
| `push1.evenements.pieceIdentite` | Une pièce d'identité est à vérifier. |
| `push1.evenements.signalementEleve` | Un signalement attend votre décision. |
| `push1.evenements.suppressionCompte` | Une suppression de compte est demandée. |
| `push1.evenements.personneEnSalle` | Personne n'est dans la salle d'une classe : trouvez un remplaçant. |
| `push1.evenements.paiementEchoue` | Votre paiement n'a pas abouti. Il se règle dans Paiements. |
| `push1.evenements.paiementEchoueDirection` | Un paiement a échoué. |
| `push1.evenements.coordonneesAValider` | Des coordonnées de versement sont à valider. |
| `push1.evenements.coordonneesValidees` | Vos coordonnées de versement sont validées. |
| `push1.evenements.remboursementDemande` | Un remboursement est demandé. |
| `push1.evenements.remboursementEchec` | Un remboursement n'a pas abouti. |
| `push1.evenements.cahierEnRetard` | Le cahier de transmission d'une séance attend vos informations. |
| `push1.gestes.examiner` | Examiner |
| `push1.gestes.verifierPiece` | Vérifier la pièce |
| `push1.gestes.traiterSignalement` | Traiter le signalement |
| `push1.gestes.traiterDemande` | Traiter la demande |
| `push1.gestes.trouverRemplacant` | Trouver un remplaçant |
| `push1.gestes.voirPaiement` | Voir le paiement |
| `push1.gestes.validerCoordonnees` | Valider les coordonnées |
| `push1.gestes.voirRemboursement` | Voir le remboursement |
| `push1.gestes.remplirCahier` | Remplir le cahier de transmission |
| `push1.gestes.rejoindreSalle` | Rejoindre la salle |
| `push1.reglages.lien` | Notifications sur cet appareil |
| `push1.reglages.titre` | Notifications sur cet appareil |
| `push1.reglages.contexte` | Recevez une alerte sur ce téléphone ou cet ordinateur, même quand l'application est fermée. L'alerte ne dit aucun nom : le détail se lit dans l'application. |
| `push1.reglages.categoriesTitre` | Ce que vous recevez |
| `push1.reglages.categoriesContexte` | Coupez une catégorie pour ne plus la recevoir sur vos appareils. Elle reste dans la page Notifications. |
| `push1.reglages.classes` | Classes et séances |
| `push1.reglages.classesDetail` | Séance annulée, déplacée ou reportée, enseignant absent, horaire changé. |
| `push1.reglages.remplacements` | Remplacements |
| `push1.reglages.remplacementsDetail` | Séance à prendre, enseignant pas encore dans sa salle. |
| `push1.reglages.paiements` | Paiements |
| `push1.reglages.paiementsDetail` | Paiement à régler ou échoué, remboursement, contestation, coordonnées de versement. |
| `push1.reglages.admissions` | Demandes et dossiers |
| `push1.reglages.admissionsDetail` | Demandes d'admission, candidatures, demandes d'horaire, pièces d'identité. |
| `push1.reglages.suivi` | Suivi des élèves |
| `push1.reglages.suiviDetail` | Signalements, messages de la direction, missions de contrôle. |
| `push1.reglages.appareilActif` | Cet appareil reçoit vos notifications. |
| `push1.reglages.appareilInactif` | Cet appareil ne reçoit pas encore vos notifications. Votre navigateur vous demandera votre accord. |
| `push1.reglages.activer` | Recevoir les notifications sur cet appareil |
| `push1.reglages.desactiver` | Ne plus les recevoir sur cet appareil |
| `push1.reglages.active` | C'est fait : cet appareil recevra vos notifications. |
| `push1.reglages.desactive` | Cet appareil ne recevra plus vos notifications. Elles restent dans la page Notifications. |
| `push1.reglages.nonPrisEnCharge` | Ce navigateur ne reçoit pas les notifications. Ouvrez Rewayah dans un navigateur récent (Chrome, Edge, Firefox ou Safari) pour les recevoir. |
| `push1.reglages.iosEcranAccueil` | Sur iPhone et iPad, ajoutez d'abord Rewayah à l'écran d'accueil (Partager, puis Sur l'écran d'accueil), ouvrez l'application depuis cette icône, puis revenez ici. |
| `push1.reglages.refuse` | Votre navigateur bloque les notifications de Rewayah. Autorisez-les dans les réglages du navigateur pour ce site, puis revenez ici. |
| `push1.reglages.ignore` | Vous n'avez pas encore répondu à la demande du navigateur. Touchez de nouveau le bouton pour la revoir. |
| `push1.reglages.echecActivation` | L'inscription de cet appareil n'est pas confirmée : la connexion a peut-être été coupée. Vérifiez votre connexion, puis réessayez. |
| `push1.reglages.compteNonAutoriseTitre` | Pas de notification sur l'appareil pour ce compte |
| `push1.reglages.compteNonAutorise` | Les notifications sur l'appareil sont réservées aux comptes adultes actifs. Toutes vos notifications restent dans la page Notifications. |
| `push1.reglages.erreurTitre` | Les réglages n'ont pas pu être lus |
| `push1.reglages.erreur` | Vos réglages n'ont pas pu être lus : la connexion a peut-être été coupée. Réessayez dans un instant. |
| `push1.reglages.horsLigne` | Vous êtes hors ligne. Les réglages se changent une fois la connexion revenue. |
| `push1.reglages.changementNonConfirme` | Le changement n'est pas encore confirmé : la connexion a peut-être été coupée. Réessayez dans un instant. |

### 6.4 Statut au 07/11/2026

| | Statut |
|---|---|
| Règle | spécifiée (07/11/2026) |
| Migrations 20261112000000 (page collée), 20261112000100, 20261112000200 | testées localement (Postgres 17 nu, tous les scénarios de la CI et `scenarios_push1.sql`) |
| Fonctions Edge `push-envoi`, `push-cle` | testées localement (Deno, fetch simulé) |
| Client (Réglages depuis la page Notifications, `web/push_worker.js`, `web/push_client.js`) | testé localement |
| Push réel reçu sur un téléphone | non prouvé : preuve du directeur, en production |
