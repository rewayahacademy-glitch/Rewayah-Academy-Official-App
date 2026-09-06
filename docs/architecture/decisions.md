# Décisions d'architecture validées - Rewayah Academy App
## ADR + périmètre MVP-0

Complément au rapport d'audit. Ce fichier fait foi sur les points tranchés.

---

## ADR-001 - Visioconférence : LiveKit, portable Cloud vers self-host

**Décision** : LiveKit. Démarrage sur LiveKit Cloud, migration prévue vers un serveur auto-hébergé sans modification de code.

### Correction préalable sur le quota gratuit

L'offre gratuite LiveKit Cloud (tier **Build**) est de **5 000 minutes WebRTC par mois** et **50 Go de transfert**, pas 50 000 minutes. La confusion vient probablement des 50 Go.

Les minutes WebRTC se comptent en **minutes-participant**. Un cours de 45 minutes en 1-to-1 consomme donc 90 minutes.

| Charge | Minutes-participant / mois | Verdict tier gratuit |
| :--- | :--- | :--- |
| 4 élèves, 3 cours par semaine de 45 min | 4 680 | Tout juste dans le quota |
| 10 élèves | 11 700 | Dépassement |
| 20 élèves | 23 400 | Dépassement large |
| 1 groupe de 6 (5 élèves + prof), 3 cours par semaine | 3 510 | Consomme 70 % du quota à lui seul |

**Conséquence** : le tier gratuit couvre environ **4 élèves en 1-to-1**. Ce n'est pas un budget de lancement, c'est un budget de prototype. La migration n'est pas un sujet lointain, elle arrive dès les premiers élèves réels. D'où l'importance de la portabilité que vous demandez, qui devient une exigence de conception dès la première ligne, et non une option future.

Ordres de grandeur au-delà : surcoût WebRTC autour de 0,0004 à 0,0005 dollar la minute, transfert de données autour de 0,10 à 0,12 dollar le Go, palier payant Ship à 50 dollars par mois.

### Le levier de coût principal : l'audio d'abord

La vidéo consomme environ **30 fois** plus de bande passante que l'audio. Un cours de 45 minutes coûte environ 11 Mo par participant en Opus 32 kbps, contre environ 170 Mo en vidéo 500 kbps.

Comme l'enseignement des Makharij est un exercice phonétique (voir section 1.4 de l'audit), la priorité audio n'est pas seulement pédagogique : c'est **le levier de coût numéro un** du produit. Politique retenue :

- Audio Opus mono 32 à 48 kbps, FEC activé, jamais dégradé.
- Vidéo en simulcast, profil bas par défaut (180p à 360p côté élève), 480p côté professeur.
- Bascule automatique en audio seul sous seuil de débit.
- Option "économie de données" activable par le tuteur, utile en Guinée comme sur les forfaits mobiles européens.

### Contrat de portabilité (à respecter sans exception)

Règle unique dont tout découle : **le client Flutter ne connaît jamais l'URL du serveur LiveKit.** Elle lui est transmise par le backend, à chaque session, en même temps que le token. Migrer revient alors à changer une variable côté serveur, sans redéploiement d'application, sans passage par les stores.

**Backend (Supabase)**

- Secrets Supabase uniquement : `LIVEKIT_WS_URL`, `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`. Jamais dans le dépôt, jamais dans Flutter.
- `functions/_shared/livekit.ts` : **seul** fichier autorisé à importer le SDK serveur LiveKit. Expose `mintToken()`, `verifyWebhook()`, `startEgress()`.
- `functions/create-room-token/` renvoie `{ ws_url, token, room_name, capabilities }`. C'est le point de bascule.
- `functions/livekit-webhook/` : endpoint unique, vérification de signature. Sur Cloud il est configuré au dashboard, en self-host dans `livekit.yaml`. Le code est identique.
- Table `video_config` (ligne unique, modifiable par l'admin) : `active_provider`, `ws_url_override`, `canary_percentage`. Permet un déploiement progressif (10 % des sessions sur le nouveau serveur) et un retour arrière **instantané** si le VPS tombe. C'est ce qui rend la migration sans risque.

**Front-end (Flutter)**

- `lib/core/video/video_session_provider.dart` : interface abstraite (`join`, `leave`, `toggleMic`, `toggleCamera`, `participants$`, `connectionQuality$`, `setAudioOnly`).
- `lib/core/video/livekit_session_provider.dart` : **seul** fichier autorisé à importer `livekit_client`.
- Aucune constante d'URL nulle part dans le code. Recherche `livekit.cloud` dans `lib/` doit renvoyer zéro résultat.
- Les écrans `[ELV-03]`, `[ENS-03]`, `[CTR-02]` ne dépendent que de l'interface.

### Ce que la migration coûtera réellement le jour J

Trois points que le "il suffit de changer l'URL" masque, et qu'il faut budgéter :

1. **TURN.** Sur les réseaux mobiles restrictifs, une partie du trafic doit passer par TURN en TCP 443. LiveKit Cloud le fournit. En self-host, il faut le déployer et le maintenir. C'est la première cause d'échec des migrations self-host.
2. **Le maillage global disparaît.** Cloud route par nœud de bordure. Un VPS unique impose un point unique. Avec des élèves en Europe et en Amérique du Nord et des professeurs en Guinée, le barycentre est **l'Europe de l'Ouest** (Paris ou Francfort). L'Amérique du Nord verra une latence plus élevée, acceptable pour de la conversation, à mesurer.
3. **Bande passante sortante du VPS.** C'est le vrai poste de coût, pas le CPU. Choisir un hébergeur avec trafic généreux ou illimité.

Le repli Cloud reste actif via `video_config`, donc l'expérimentation est réversible en une minute.

---

## ADR-002 - Enregistrement des sessions : audio systématique

Vous m'avez laissé trancher. **Décision : enregistrement audio systématique, rétention 30 jours, chiffré, accès journalisé.** Pas de vidéo.

### Pourquoi ce choix et pas un autre

**Contre "aucun enregistrement".** L'argument "on le fait déjà sur Meet sans problème" est le plus fréquent et le plus risqué. L'absence d'incident constaté ne mesure pas le niveau de contrôle : elle mesure l'absence de détection. Sans trace, un incident ne serait ni détecté, ni prouvable, ni défendable. Et une clause dans les conditions d'utilisation ne prévient rien, ne détecte rien et ne prouve rien : elle ne fait qu'informer.

**Contre "sur incident uniquement".** Un enregistrement déclenché après coup n'existe pas. Au moment où l'on sait qu'il y a un problème, la séance est finie.

**Contre "audio et vidéo".** L'image d'un mineur multiplie la charge de conformité, le coût de stockage par 30, et n'apporte presque rien de plus au regard de l'objectif. Une analyse d'impact acceptera bien mieux un dispositif proportionné.

**Pour l'audio.** Trois bénéfices dans un seul dispositif :

1. **Protection de l'enfant.** Le canal privé n'est plus sans témoin.
2. **Protection du professeur.** C'est l'argument qui fait accepter le dispositif par les enseignants, et il est exact : face à une accusation infondée, l'enregistrement est leur seule défense.
3. **Valeur pédagogique.** La récitation enregistrée permet au professeur de réécouter, au tuteur d'entendre les progrès, et au Contrôleur d'auditer une méthode sans infiltration. L'enregistrement devient une fonctionnalité que les familles apprécient, pas une surveillance qu'elles subissent.

### Mise en œuvre

- LiveKit **Egress** en mode `audio_only`, sortie vers **Cloudflare R2** (10 Go gratuits, pas de frais de sortie).
- Volume : environ 11 à 20 Mo par séance. À 20 élèves et 3 séances par semaine, environ 5 Go par mois, stables grâce à la purge glissante.
- Purge automatique à 30 jours via `pg_cron`, sauf litige ouvert qui gèle la pièce.
- Bucket privé, URL signée 60 secondes, génération serveur uniquement, chaque écoute écrite dans `audit_logs` avec l'identité de l'auditeur.
- **Indicateur d'enregistrement visible en permanence** dans la salle, pour les deux parties. Obligation de transparence, et pratique conforme aux conventions d'interface.
- Mention explicite dans le NDA enseignant, dans les conditions d'utilisation et dans le consentement parental, avec la finalité, la durée et les destinataires.

Point à ne pas oublier : cette décision alimente directement la DPIA. Un dispositif audio, proportionné, à rétention courte, avec accès journalisé, est défendable. Le même dispositif en vidéo, sans limite de durée, ne l'est pas.

---

## ADR-003 - Périmètre MVP-0

| Dans le MVP-0 | Reporté en V1 |
| :--- | :--- |
| RBAC complet, 6 rôles, RLS | Module finance : portefeuille, crédits, expiration |
| Auth, KYC, portails d'attente, onboarding en cartes (ADR-013) | Payouts Flutterwave et successeur |
| Appairage enfant (QR, PIN, appareils) | Facturation et reçus automatiques |
| Planning, matching, récurrence, UTC et DST | Espace Comptable et relances groupées |
| Visio LiveKit, salle, tokens, rôles | "Système de création d'objectifs élèves" (portée à préciser, question encore ouverte) |
| Présence automatique par webhooks serveur | |
| Enregistrement audio et rétention | |
| Bibliothèque coranique et mode suivi | |
| Cahier de transmission `[ENS-04]` | |
| Pre-Download Guard et exports `[ADM-03]` | |
| Grille d'audit Contrôleur `[CTR-03]` | |
| Dashboards Élève, Enseignant, Tuteur, Admin | |
| Notifications push | |
| Journal d'audit `audit_logs` | |
| Migration des familles et enseignants existants (ADR-014) | |

**Mise à jour** : le Pre-Download Guard et la grille d'audit du Contrôleur, initialement reportés à tort, reviennent au MVP-0. Seuls la finance et le système d'objectifs élèves attendent la V1, conformément à votre arbitrage.

### Trois conséquences à assumer

1. **Sans portefeuille, l'accès doit se contrôler autrement.** Une colonne `access_until` sur le profil élève, positionnée manuellement par l'admin après réception du paiement hors application, suffit. Une date, pas un module. Le blocage automatique au 1er du mois arrive avec le module finance.

2. **Le schéma financier se crée quand même à l'Étape 1.** Tables `wallets`, `wallet_entries`, `payouts`, sans interface. Créer des tables vides coûte une heure aujourd'hui ; réécrire un ledger sur des données de production en coûte trente. La règle : **le schéma anticipe, l'interface attend.**

3. **Le Contrôleur reste partiellement dans le MVP-0.** L'infiltration invisible `[CTR-02]` est quasiment gratuite une fois le service de tokens écrit (un drapeau `hidden` dans le token). On la garde. C'est la grille d'audit `[CTR-03]` qui attend.

**Le cahier de transmission `[ENS-04]` reste dans le MVP-0** même sans module de paie : il porte la continuité pédagogique et sert de base au calcul manuel des heures. Il alimentera la paie automatique le jour venu, sans reprise de données.

---

## ADR-004 - Modèle de session : groupes jusqu'à 6

Information nouvelle apportée par votre réponse : des cours en petits groupes jusqu'à 6 personnes sont prévus, alors que le cahier des charges décrit un cloisonnement strict 1-to-1 ("l'élève ne voit QUE son professeur").

C'est une décision de schéma, donc elle se prend maintenant.

**Décision** : le modèle est **plusieurs-à-plusieurs dès l'Étape 1**. Pas de colonne `student_id` sur `sessions`, mais une table `session_participants (session_id, profile_id, role, joined_at, left_at)`. Le 1-to-1 devient le cas particulier à deux participants. Coût aujourd'hui : nul. Coût d'une migration ultérieure sur des données réelles avec des policies RLS et des rapports de présence déjà en place : élevé.

Effets à intégrer :
- Les policies RLS passent d'une jointure directe à une jointure via `session_participants`.
- La contrainte anti-chevauchement `EXCLUDE` s'applique désormais à chaque participant, pas seulement au professeur : un élève ne peut pas être dans deux sessions simultanées.
- Le calcul de présence par webhook devient par participant, ce qu'il était déjà nativement.
- Coût LiveKit multiplié par le nombre de participants, mais divisé par élève. Un groupe de 6 revient environ trois fois moins cher par élève qu'un 1-to-1.

### Décisions complémentaires

**Le duo enseignant-élève reste le mode par défaut.** Le multi-participants existe dans le schéma mais reste fermé tant qu'un administrateur ne l'ouvre pas.

Clé de configuration : `allow_multi_participant_sessions`, **désactivée par défaut**. Point d'application obligatoire : **en base**, par un trigger qui plafonne à 2 participants tant que la clé est fausse. Pas dans l'interface. Une règle appliquée seulement à l'écran n'est pas une règle.

**Affichage des co-participants** : prénom seul, suivi de l'identifiant immuable en petits caractères. Le nom de famille n'est jamais exposé à un autre élève.

Mise en œuvre : une **vue dédiée** `session_peers_v` exposant exactement deux colonnes (prénom, identifiant immuable) et rien d'autre. Les élèves n'interrogent jamais la table `profiles`. Ce n'est pas une policy plus permissive sur `profiles`, c'est une surface d'exposition séparée et minimale. Le jour où quelqu'un ajoute une colonne sensible à `profiles`, elle ne fuite pas.

---

## ADR-005 - La salle est un produit Rewayah, pas une salle de réunion

Puisque la salle vous appartient désormais, la question n'est plus "comment reproduire Meet en moins bien" mais "quelles règles Rewayah impose dans sa propre salle". Meet ne pouvait en appliquer aucune.

Le point décisif est **où la règle est appliquée**. Une règle appliquée dans l'interface est un souhait. Une règle inscrite dans le token ou vérifiée par le serveur est une règle.

| Règle Rewayah | Mécanisme | Appliquée par |
| :--- | :--- | :--- |
| Aucun lien partageable, aucune salle permanente | La salle n'existe que pour une session planifiée, le token n'est valide que de T-10 min à T+fin+10 min | Serveur, à l'émission du token |
| Un participant, un appareil, une identité | Identité du token liée au `device_id` appairé, connexion en double refusée | Token |
| Personne d'autre ne rentre | Vérification serveur de l'appartenance à `session_participants` avant émission | Serveur |
| **Cours sans caméra pour l'élève** | Token n'autorisant que la publication du micro | Token |
| Le tuteur peut assister sans intervenir | Token en abonnement seul, publication interdite | Token |
| Le Contrôleur est invisible | Participant masqué, usage journalisé | Token plus audit |
| Le professeur n'entre pas sans pre-flight validé | Le rapport de pre-flight doit exister avant émission du token | Serveur |
| Ni tchat, ni partage d'écran, ni fichier dans la salle | Publication de données et d'écran interdite dans le token | Token |
| Aucun enregistrement par un participant | Aucun bouton d'enregistrement n'existe, seul le serveur enregistre, plus protection écran native | Architecture |
| Filigrane permanent | Rendu dans la couche Flutter au-dessus du flux | Client, valeur forensique |
| Fin de session automatique | Fermeture serveur à la fin de la plage plus délai de grâce | Serveur |

Le point le plus important de ce tableau pour votre public est la ligne caméra. Une famille peut souhaiter que sa fille suive le cours sans image, et vous pouvez désormais le garantir techniquement, par participant, sans dépendre de la bonne volonté de qui que ce soit. Meet ne permettait pas de le promettre.

**Salle en mode enfant** : pour un élève de 6 ans, l'écran de cours ne comporte que deux commandes, le micro et le bouton de sortie. Pas de liste de participants, pas de réglages, pas de menu, pas de bouton rouge de signalement (voir section 1.2 de l'audit).

---

## ADR-006 - Archives audio : légères et sans effet sur l'application

Votre contrainte est le point d'architecture le plus important de ce module, et la réponse est structurelle.

**L'enregistrement ne se fait pas sur l'appareil.** Il est produit **côté serveur** par la fonction Egress de LiveKit, à partir du flux que le participant envoie déjà. Conséquence directe : **zéro CPU supplémentaire, zéro batterie supplémentaire, zéro octet supplémentaire** sur le téléphone de l'enfant ou du professeur. C'est exactement ce qui rendait cette fonction impossible avec Meet et coûteuse dans une implémentation naïve, où le client encode une seconde fois en local.

**Format retenu** : Opus dans un conteneur OGG, mono, 24 kbps, sans vidéo.

| Élément | Valeur |
| :--- | :--- |
| Poids d'une séance de 45 min | environ 8 Mo |
| 20 élèves, 3 séances par semaine | environ 2 Go par mois, stable grâce à la purge |
| Destination | Cloudflare R2, dépôt direct depuis LiveKit |
| Rétention | 30 jours, règle de cycle de vie sur le bucket, gel en cas de litige ouvert |

L'Opus à 24 kbps mono est transparent pour la voix. Descendre plus bas dégraderait précisément ce qui a de la valeur ici, la précision phonétique.

**Trois règles de conception à respecter :**

1. **Le fichier ne transite jamais par votre backend.** LiveKit dépose directement dans R2. Aucune fonction serveur ne manipule le binaire, donc rien à dimensionner et rien qui puisse saturer.
2. **La base ne stocke que des métadonnées.** Une table `session_recordings` avec la clé d'objet, la durée, la taille, le codec, le statut et la date d'expiration. Jamais le fichier.
3. **La lecture se fait en flux, jamais en téléchargement.** URL signée de 60 secondes plus lecture par plages HTTP. L'application ne charge jamais un fichier entier en mémoire.

**Piste produit à noter pour plus tard** : en enregistrant les pistes séparément plutôt que mixées, on obtient la récitation de l'élève isolée, donc une fonction "réécouter ma récitation de la semaine dernière". Cela double le stockage. Hors périmètre MVP-0, mais la décision de format n'interdit rien.

---

## ADR-007 - Paiements : Flutterwave écarté

Le compte Flutterwave a été refusé, les conditions d'éligibilité n'étant pas remplies à ce stade. Le fournisseur est donc retiré de l'architecture.

Cela ne change rien au calendrier, puisque le module finance est déjà reporté en V1. L'abstraction `PayoutProvider` décrite dans l'audit devient simplement obligatoire plutôt que prudente : aucun code métier ne doit connaître le nom d'un prestataire.

Grille d'évaluation à appliquer à toute alternative, à renseigner quand vous aurez identifié les candidats :

| Critère | Pourquoi il est éliminatoire |
| :--- | :--- |
| Payout vers GNF et XOF | Sans cela, vos enseignants ne sont pas payables |
| Aucun seuil de volume à l'entrée | C'est précisément ce qui a bloqué chez Flutterwave |
| Accepte une UK Ltd comme donneur d'ordre | Sinon la jambe sortante est impossible |
| API de transfert, pas seulement un tableau de bord | Sinon aucune automatisation en V1 |
| Webhooks et idempotence | Sinon risque de double paiement |
| Frais et taux de change publiés | Sinon marge non calculable |

Vous disposez déjà d'un compte Stripe pour la collecte et vous aviez exploré CinetPay pour l'Afrique de l'Ouest. La séparation collecte et payout est d'ailleurs la structure la plus probable : un prestataire pour encaisser en Europe et en Amérique du Nord, un autre pour verser en Afrique de l'Ouest. L'abstraction rend cette séparation naturelle.

---

## ADR-008 - Filigrane abandonné, anti-pillage déplacé côté serveur

**Décision** : le composant `WatermarkedView` est retiré du périmètre. Tous les rôles accèdent à tous les types d'appareils, navigateur compris.

C'est une décision saine, et il faut nommer précisément ce qu'elle coûte et ce qu'elle gagne.

**Ce qu'on perd** : la capacité à identifier l'auteur d'une capture d'écran qui circulerait. Rien d'autre. Le filigrane n'a jamais empêché une capture, il permettait seulement de remonter à sa source après coup.

**Ce qu'on gagne** : une cible unique au lieu de deux, la fin des chemins de code spécifiques par plateforme, et un accès sans friction pour les familles qui n'ont qu'un ordinateur partagé.

**Ce qui protège réellement, et qui remplace le filigrane** : quatre contrôles, tous côté serveur, donc indifférents à la plateforme.

| Contrôle | Effet |
| :--- | :--- |
| **Aucune coordonnée de contact visible par l'enseignant** | Le contrôle le plus efficace du dispositif. L'enseignant voit "Amina B. - STI-AB0012/26" et rien de plus : ni nom de famille complet, ni courriel, ni téléphone, ni adresse. Il ne peut pas contacter la famille hors plateforme, même s'il le veut. |
| **Messagerie passant par la plateforme, conservée** | Les échanges enseignant vers tuteur restent internes et archivés. Détection automatique des motifs de numéro de téléphone et d'adresse électronique, avec signalement à l'administrateur. |
| **Journalisation des consultations de profil** | Un enseignant qui consulte anormalement de profils est visible dans le journal. La menace n'est pas le fichier exporté, c'est le comportement. |
| **Archive audio des séances** | C'est désormais le vrai contrôle anti-pillage. Un enseignant qui propose des cours en direct à une famille pendant la séance laisse une trace. Aucun filigrane n'aurait attrapé cela. |

Le point à retenir : votre risque de pillage ne passait jamais par une capture d'écran. Il passe par la voix, pendant la séance, et par la possibilité de recontacter la famille ensuite. Le premier canal est couvert par l'ADR-002, le second par l'occultation des coordonnées. Le filigrane ne couvrait ni l'un ni l'autre.

**Reste appliqué là où c'est gratuit** : le blocage de capture natif sur Android et la détection de capture sur iOS restent activés pour les utilisateurs de l'application mobile. Ce n'est pas une exigence, c'est un réglage sans coût qui couvre la majorité des usages.

---

## ADR-009 - Deux populations d'élèves, et une politique caméra sans friction

Votre remarque corrige une erreur de modélisation de ma part. Le cahier des charges suppose qu'un élève est toujours un mineur rattaché à un tuteur. C'est faux : vous avez aussi des élèves adultes autonomes.

### Modèle retenu

**Tout élève appartient à un foyer.** Un élève adulte autonome constitue un foyer d'une personne, dont il est lui-même le tuteur. Aucune branche conditionnelle dans les policies, aucun cas particulier dans le code : un seul chemin, qui couvre les deux populations.

Un attribut `student_type` distingue `mineur_sous_tutelle` et `autonome`. Il ne pilote pas les droits d'accès, qui découlent du foyer, mais l'interface et les destinataires des notifications.

### Mode d'interface

Deux modes, portés par le profil élève et non par le rôle :

| Mode | Public | Caractéristiques |
| :--- | :--- | :--- |
| `enfant` | Environ 6 à 8 ans | Deux commandes en séance, micro et sortie. Zéro lecture, pictogrammes, audio. Pas de réglages. |
| `standard` | Environ 9 ans et plus, y compris adultes | Commandes complètes : micro, caméra, liste des participants, sortie. |

Le seuil est une clé de configuration, pas une constante. Un troisième mode intermédiaire pourra s'ajouter sans refonte.

### Politique caméra : un réglage unique, jamais une action répétée

Votre objection est décisive : les parents paient parce qu'ils n'ont pas le temps. Exiger une intervention du tuteur à chaque séance rendrait le produit inutilisable.

**La caméra est donc un attribut de profil, fixé une seule fois à l'inscription, jamais une autorisation par séance.**

| Valeur du profil | Ce que reçoit le token | Ce que vit l'utilisateur |
| :--- | :--- | :--- |
| `autorisee` | Droit de publier micro et caméra | L'élève allume et éteint sa caméra librement, en séance, sans jamais solliciter personne |
| `interdite` | Droit de publier le micro seul | Le bouton caméra **n'existe pas**. Ni l'élève, ni l'enseignant, ni une fausse manipulation ne peut l'activer |

**Valeur initiale, décidée à la création du profil selon l'âge :**

| Âge de l'élève | Politique caméra initiale |
| :--- | :--- |
| Plus de 10 ans | Autorisée |
| 10 ans et moins | Interdite |

Ce n'est qu'une proposition de départ. Le tuteur la modifie à tout moment depuis ses propres réglages, **enfant par enfant** : caméra autorisée pour Amina, interdite pour Ibrahim, dans le même foyer et sur le même écran. La valeur vit sur le profil de l'élève, jamais sur le foyer.

Qui fixe la valeur : le tuteur pour un mineur, l'élève lui-même s'il est autonome. Le changement s'applique à la séance suivante, sans aucune action pendant le cours.

**État à l'entrée en séance** : caméra éteinte pour tout le monde, y compris quand elle est autorisée. Allumer est un geste volontaire, sur un bouton unique. Cela évite le moment gênant de l'entrée caméra ouverte, et cela économise de la bande passante quand personne ne l'utilise vraiment.

**La caméra de l'enseignant reste allumée par défaut.** C'est celle qui porte la valeur pédagogique : l'élève doit voir la bouche du professeur pour les Makharij. La caméra de l'élève est utile mais secondaire, la correction passant par l'écoute.

Le résultat : sécurité obtenue par une décision unique à l'inscription, simplicité obtenue par zéro intervention ensuite.

---

## ADR-010 - Deux appareils appairés, un seul en séance

**Décision** : deux appareils appairés simultanément par élève, mais **un seul peut rejoindre une séance à la fois**.

Votre raisonnement est exact : sans cette règle, le second appareil devient une place gratuite prêtée à quelqu'un qui n'est pas inscrit.

Application, en trois niveaux :

1. **À l'émission du token.** Le serveur refuse de délivrer un token de séance si un token actif existe déjà pour ce profil. Message explicite : ce compte est déjà en séance sur un autre appareil. Option de forcer la déconnexion de l'autre appareil, après confirmation, tracée dans le journal.
2. **En base.** La contrainte d'exclusion C2 interdit déjà à un profil d'être présent dans deux séances qui se recouvrent. Les deux niveaux se renforcent.
3. **En détection.** Chaque entrée en séance enregistre l'appareil et l'adresse réseau. Un appareil qui rejoint systématiquement alors que l'autre ne sert jamais, ou une entrée depuis un pays inattendu, remonte en signalement. C'est le motif exact que vous décrivez.

Le second appareil reste utilisable pour consulter le planning et l'historique. Seule l'entrée en séance est exclusive.

---

## ADR-011 - Contrôle invisible : confirmé, encadré, annoncé à tous

**Décision** : tout profil portant le rôle de contrôleur entre dans n'importe quelle séance en cours sans être vu ni entendu. Fonction confirmée dans le MVP-0. Irréalisable avec Google Meet, elle coûte un drapeau dans le token avec LiveKit.

### Le principe

Tout le monde sait que la visite est possible. Personne ne sait qu'elle a lieu.

**La conséquence de conception qui décide de tout : la mention est permanente, jamais conditionnelle.** Un bandeau qui apparaîtrait à l'entrée d'un contrôleur détruirait l'invisibilité en une seconde. La salle affiche donc en continu, pour l'enseignant comme pour l'élève, la même ligne inchangée : cours enregistré, visite de contrôle possible. Elle est là que le contrôleur soit présent ou non.

Cinq points d'information, du plus contraignant au plus visible :

| Où | Quoi |
| :--- | :--- |
| Contrat enseignant | Clause explicite, signée, datée, versionnée. Un enseignant qui découvre le dispositif après coup est un litige |
| Conditions d'utilisation et consentement parental | Même clause en langage clair, présentée comme un contrôle qualité |
| Première connexion | Carte courte à accuser une fois, pour l'enseignant comme pour le tuteur |
| Bandeau permanent dans la salle | La ligne inchangée décrite ci-dessus |
| Page publique de l'académie | Argument de confiance auprès des familles, pas information cachée |

### Ce que le contrôleur peut et ne peut pas

| Peut | Ne peut pas |
| :--- | :--- |
| Voir et entendre toute séance en cours | Publier micro, caméra ou message |
| Entrer et sortir sans annonce | Apparaître dans la liste des participants |
| Consulter le planning global | Enregistrer de son côté, la séance l'étant déjà |
| Signaler un incident à l'administrateur | Observer une séance où il est lui-même participant |

### Qui peut être contrôleur

Deux règles à appliquer en base, pas par convention.

**Exclusion de rôle.** Un même profil ne peut pas être à la fois enseignant et contrôleur. Sans cette règle, un enseignant observe les élèves d'un confrère, et votre outil de contrôle qualité devient un outil de démarchage. C'est exactement le pillage que toute l'architecture cherche à empêcher.

**Même vérification qu'un enseignant.** Un contrôleur voit et entend des enfants. Même dossier d'identité, même contrat, mêmes engagements.

### Qui surveille le surveillant

Chaque entrée écrit dans le journal d'audit : identité, séance, horodatage, durée. Consultable dans `ADM-04`, jamais effaçable.

Trois motifs remontent automatiquement en signalement : un contrôleur qui observe le même enseignant de façon répétée, un volume d'observations anormal sur une journée, et une concentration des visites sur un profil d'élève plutôt qu'un autre. Un dispositif d'observation sans contre-observation devient un risque à son tour.

---

## ADR-012 - Photo réelle de profil, gérée par le parent, strictement confinée

**Décision** : le profil enfant porte une vraie photo, ajoutée et modifiable par le tuteur à tout moment. Pas d'illustration par défaut imposée.

Une photo d'enfant est une donnée plus sensible qu'une illustration. Le produit ne change pas, l'endroit où la photo peut apparaître se réduit au strict nécessaire.

### Où la photo apparaît, et où elle n'apparaît jamais

| Contexte | Photo visible |
| :--- | :--- |
| Choix de profil sur l'appareil de l'enfant | Oui, c'est sa fonction |
| Accueil et réglages du tuteur | Oui |
| `teacher_roster_v`, la liste des élèves d'un enseignant | **Non.** Prénom et identifiant seulement, comme déjà fixé à l'Étape 1 |
| `session_peers_v`, les co-participants en cours de groupe | **Non.** Même règle |
| Espace Admin, Comptable, Contrôleur | **Non**, sauf besoin explicite documenté |

Rien ne change dans les vues déjà spécifiées à l'Étape 1 : leur sobriété d'origine, prénom plus identifiant, protège déjà contre ce risque précis. La photo s'ajoute au produit sans élargir aucune de ces vues.

**Le flux vidéo n'est pas concerné par cette règle.** Un enseignant voit déjà le visage de l'enfant en cours si la caméra est autorisée. La restriction porte sur la photo statique consultable hors séance, qui elle ne doit jamais fuiter vers un rôle qui n'a pas besoin de reconnaître l'enfant en dehors du cours.

### Contraintes techniques

- Stockage dans le bucket privé déjà prévu pour les médias, jamais dans une colonne exposée directement.
- Accès exclusivement par URL signée de courte durée, générée à la demande, jamais une URL publique stable.
- Compression et redimensionnement **côté serveur** à l'envoi, format léger, une seule taille d'affichage suffisant pour une tuile de profil. Le tuteur envoie une photo de téléphone, l'application ne doit jamais transporter ni afficher le fichier original.
- Remplacement et suppression immédiats à la demande du tuteur, y compris la version en cache sur les appareils appairés.
- Ajoutée au même consentement que la pièce d'identité et l'enregistrement audio (ADR-002, ADR-011) : le tuteur sait, en un seul endroit, ce que l'académie conserve sur son enfant.

### Mise à jour des écrans déjà maquettés

`ELV-01` et `TUT-02` remplacent la tuile illustrée par la photo réelle, avec un repli sur les initiales de l'enfant si aucune photo n'a encore été ajoutée. `TUT-05` reçoit une action supplémentaire, changer la photo, au même endroit que le réglage caméra, puisque les deux relèvent du même geste parental de gestion à distance.

---

## ADR-013 - Réinscription complète, en cartes, jamais un formulaire long

**Décision sur la migration** : les familles et enseignants déjà actifs sur WhatsApp et systeme.io se réinscrivent intégralement via le nouveau parcours. Aucune reprise manuelle de compte par l'administration. Cela ferme l'angle mort de bascule identifié précédemment.

**Décision sur la forme de l'inscription** : à chaque fois qu'un choix est proposé, l'utilisateur voit des **cartes cliquables** représentant les réponses les plus courantes. Si aucune ne convient, une carte "Autre" ouvre un champ de saisie libre. Le parcours entier se découpe en **plusieurs pages courtes**, jamais une page unique qui empile tous les champs.

C'est la réponse à la question 3 restée ouverte, au moins pour tout le parcours d'inscription : le moteur de formulaires dynamiques à cartes cliquables décrit dans vos specs d'origine est confirmé pour l'onboarding. `ENS-04`, le cahier de transmission, utilisait déjà ce principe de sélection par pastilles sans qu'on l'ait nommé ainsi : le motif existe donc déjà ailleurs dans le produit, cette décision le généralise et le rend explicite.

### Ce que cela change concrètement

Le déroulé en trois grandes étapes déjà maquetté pour `TUT-00c`, identité puis contrat puis confirmation, reste la structure de haut niveau. Chaque étape se décompose à son tour en pages courtes, une question par page ou presque, plutôt qu'un formulaire qui les regroupe.

Pour la partie enfant, qui suit immédiatement l'identité du tuteur, chaque champ à choix devient une page de cartes : le niveau de l'enfant, la langue de préférence entre français et poular si elle existe, sa disponibilité générale avant le détail fin de `TUT-04`. Une personne qui s'est déjà inscrite une fois par le passé retrouve un rythme familier de tap en tap, jamais un champ vide à remplir de tête.

### Composant partagé

Un seul composant, `ChoiceCardGroup`, à ajouter à la liste de l'Étape 2 : un ensemble de cartes avec sélection unique ou multiple selon le champ, plus une carte "Autre" systématique qui révèle un champ de texte quand aucune option ne convient. Toutes les pages de choix de l'onboarding consomment ce même composant, jamais une réimplémentation par écran.

---

## ADR-014 - Migration des familles et enseignants existants : grandfathering encadré

**Décision** : les personnes déjà actives sur WhatsApp et systeme.io ne repassent pas par l'onboarding complet. Elles reçoivent un **onboarding de confirmation**, plus court : les informations déjà connues leur sont présentées pré-remplies, avec le même motif de cartes (ADR-013), et elles confirment plutôt que de ressaisir. Ce qui manque est complété ensuite, sans bloquer l'accès.

**Elles peuvent reprendre les cours immédiatement**, sans attendre la validation KYC habituelle, puisque l'académie les connaît déjà depuis parfois deux ans. **Elles ont 30 jours pour compléter leur profil.**

### Un état de compte qui n'existe que pour cette population

C'est le point qui rend la décision sûre plutôt que risquée : "accès immédiat sans KYC validé" ne doit jamais devenir une porte que n'importe qui peut emprunter en se prétendant ancien élève.

**Le statut de compte se découpe en quatre valeurs, pas deux.**

| Statut | Qui l'obtient | Accès aux cours |
| :--- | :--- | :--- |
| `en_attente_kyc` | Toute nouvelle inscription, jamais vue auparavant | Aucun, portail d'attente, comme déjà spécifié à l'Étape 1 |
| `provisoire_actif` | **Uniquement** un profil créé par import depuis les données que vous fournissez, jamais par auto-inscription | Complet, identique à un compte validé |
| `actif` | Un profil validé, que ce soit après KYC complet ou après complétion du profil provisoire | Complet |
| `suspendu` | Décision admin, y compris à l'expiration du délai si nécessaire | Aucun |

**`provisoire_actif` ne peut jamais être atteint par le parcours d'inscription publique.** Il n'existe que comme résultat d'un import que vous déclenchez, à partir des données que vous fournirez. Un nouvel enseignant ou une nouvelle famille qui s'inscrit de zéro passe obligatoirement par `en_attente_kyc`, sans exception et sans raccourci déclaratif du type "je suis déjà client".

### Le délai de 30 jours

Une colonne `kyc_completion_deadline` est posée à la date d'import plus 30 jours. Proposition par défaut, à corriger si elle ne convient pas :

- Rappel à J-7 et à J-1 avant l'échéance, dans l'application et par notification.
- **À l'échéance, le compte n'est pas automatiquement bloqué.** Une coupure automatique risquerait d'interrompre un cours en cours de route pour une famille par ailleurs légitime. Le dossier remonte plutôt en tête de `ADM-01`, comme un cas à traiter, avec la mention explicite du dépassement. C'est vous qui décidez au cas par cas si une suspension est nécessaire.

### L'onboarding de confirmation

Reprend la structure de cartes de l'ADR-013, avec une différence : chaque page affiche la valeur déjà connue, pré-cochée, et une seule action, confirmer ou corriger. Les champs absents des données fournies suivent le parcours normal en cartes. Un bandeau permanent mais discret rappelle la date limite tant que le profil n'est pas complet, visible sur `TUT-01` ou `ENS-02` selon le rôle, dans le même esprit que le rappel de rapport en retard déjà prévu sur `ENS-02`.

### Import des données

Quand vous fournirez le fichier, l'import associera chaque ligne à un foyer ou un profil enseignant en `provisoire_actif`, avec la date d'échéance posée automatiquement. Le mappage exact des colonnes se précisera à réception du fichier, pas avant.

---

## ADR-015 - Socle technique du front, et retrait du poular

Quatre points tranchés avec l'opérateur le 6 septembre 2026, au démarrage de
l'étape 2. Aucun ADR ne les couvrait, et chacun est coûteux à changer ensuite.

### Gestion d'état : Riverpod

`flutter_riverpod` avec son générateur. C'est lui qui porte `SessionState` et
qui alimente le `refreshListenable` du routeur. Retenu pour une raison précise :
la redirection doit pouvoir décider **sans `BuildContext` et sans attendre**, et
l'état de session doit se tester sans monter d'application. Bloc aurait imposé
plus de cérémonie sur chaque écran pour le même résultat.

### Internationalisation : slang

La spécification de l'étape 2 impose des clés en points, `eleve.accueil.rejoindre`,
et exige que `AudioLabel` consomme **la même clé** pour retrouver un fichier son.
L'outil officiel de Flutter, `gen_l10n`, n'accepte pas les points dans les clés :
il aurait fallu aplatir la convention et corriger la spécification. `slang` la
respecte à la lettre et vérifie les clés à la compilation.

Le lien texte-son passe par le type `CleAudio` et la carte plate de slang, avec
un test qui refuse toute clé audio sans texte correspondant. Texte et audio
restent ainsi dans un seul système, pas deux qui divergent.

### Langues : français et arabe, pas de poular

**Décision de l'opérateur : le poular n'existe pas dans l'application**, malgré
ce qu'écrivaient `etape-2-core-flutter.md` section 5 et la dernière section de
`parcours-utilisateurs.md`. Les deux documents sont corrigés.

Restent le français, rempli, et l'arabe, déclaré et vide. L'arabe est conservé
parce que `design-tokens.md` pose l'application comme bilingue arabe-français
avec une police d'interface arabe dédiée : le retirer contredirait la charte
typographique. Il se remplit en déposant un fichier, sans reprise de code.

Cela clôt la question ouverte numéro 6.

### Statut de compte : la base rattrape l'ADR-014

L'ADR-014 définit quatre statuts de compte. La migration 0001 n'en portait que
trois : `en_attente_kyc` manquait, et toute nouvelle inscription naissait
`active`, c'est-à-dire avec un accès complet. L'écart n'était pas visible parce
qu'aucun parcours d'inscription n'existait encore.

Les migrations `0002` et `0003` ajoutent `pending_kyc` et le posent en valeur
par défaut. `app_account_valid()` n'a pas changé : elle n'accepte toujours que
`active` et `provisional_active`, donc un compte en attente ne lit rien, dans
aucune table, quel que soit son rôle. La redirection du routeur Flutter n'est
qu'une commodité d'expérience par-dessus cette règle.

### Une conséquence de méthode

Ces quatre points partagent la même origine : ils n'étaient écrits nulle part,
et chacun aurait été décidé implicitement par la première ligne de code qui
l'aurait touché. Toute décision de ce genre s'ajoute désormais à ce fichier au
moment où elle se prend, pas après.

---

## ADR-016 - Ce que l'étape 3 a dû trancher

Dix points décidés en construisant l'auth, le KYC et l'appairage. Aucun n'était
écrit, et chacun aurait été décidé implicitement par la première ligne de code
qui l'aurait touché.

### Aucun mot de passe, nulle part

Un lien reçu par courriel, ou Google. Un mot de passe qu'on ne demande jamais
est un mot de passe qu'on ne peut ni perdre, ni voler, ni réutiliser ailleurs,
et il n'y a aucun parcours de réinitialisation à protéger. Aucun écran du
produit n'a de champ masqué.

### Le rôle déclaré à l'inscription est borné par la base

Une inscription publique ne produit que `guardian` ou `teacher`, et toujours en
`pending_kyc`. Ce n'est pas une règle d'écran : `creer_profil_inscription()`
refuse tout le reste et écrit le statut en dur. Un rôle reçu du client n'est
jamais un rôle accordé, et `provisional_active` reste inatteignable autrement
que par un import déclenché par l'administration (ADR-014).

L'élève adulte autonome n'est pas un rôle de plus : il est **son propre
tuteur**, un foyer d'une personne (ADR-009). Deux libellés à l'écran, un seul
chemin en base.

### Le personnel n'a pas de foyer

`profiles.household_id` devient facultatif, avec une contrainte qui l'exige pour
un élève et un tuteur et l'interdit de fait au personnel. L'alternative était un
foyer fantôme par enseignant, qui polluerait la table servant d'unité de
facturation et les compteurs de `ADM-01`.

### Le genre d'un dossier vient du profil, jamais du client

Ce champ décide quel membre du personnel pourra ouvrir la pièce (audit 1.3). Le
laisser arriver du client reviendrait à confier au déposant le choix de qui le
regarde. Un déclencheur l'écrase par celui du profil concerné, et refuse le
dépôt quand ce genre est inconnu. Le paramètre n'existe pas dans l'interface
Dart : ce qui ne peut pas être envoyé ne peut pas être forgé.

Symétriquement, le genre du **lecteur** vient de son profil et non de ses
propres documents, et son absence est un refus explicite plutôt qu'un filtrage
silencieux à moitié.

### Le code personnel de l'enfant est local, et ne se réinitialise pas à distance

Il est créé sur l'appareil juste après l'appairage, en présence du tuteur qui
vient de montrer le code à six caractères. Il n'est jamais transmis : aucun
service ne déclare de paramètre pour le recevoir. Conséquence assumée : il n'y a
pas de « code oublié ». Le tuteur révoque l'appareil et le réappaire.

Ce que ce code protège est nommé précisément dans le journal de l'étape 3 : un
frère ou une sœur, pas un attaquant qui aurait le coffre du système.

### L'accusé de l'ADR-011 précède le contrat

Les deux dispositifs qu'il nomme figurent aussi dans le contrat. Mais une clause
signée au milieu d'un texte long n'informe personne, et c'est exactement le
litige que l'ADR-011 cherche à éviter. La carte courte vient donc d'abord, le
contrat la formalise ensuite.

### Le seuil du mode enfant est employé à 8

`child_ui_mode_max_age` valait déjà 8 dans `app_config` depuis la migration
0001, avec la mention « à trancher ». L'étape 3 s'en sert pour dériver le mode
d'interface et la politique caméra à la création d'un profil enfant. La valeur
reste administrable en une ligne, sans redéploiement : ce n'est pas une
constante d'application. **À confirmer ou corriger par l'opérateur**, ce qui
clôt la question 5 par défaut et non par décision.

### La lecture du QR par la caméra est reportée

Le paquet nécessaire réclame une configuration de permissions par plateforme et
un build Android que le poste de développement ne peut pas produire aujourd'hui.
Le chemin par le code à six caractères fonctionne partout, Web et Windows
compris. Le bloc « scanner » n'est donc **pas rendu** plutôt que rendu inerte :
un bouton qui échoue après le geste coûte plus cher qu'un bouton absent, la même
règle que le bouton d'ajout d'appareil à la limite de deux.

### Le dixième composant partagé

`ActionPrincipale`. L'étape 2 n'avait aucun formulaire : le seul bouton du
produit vivait à l'intérieur d'`EmptyState`, qui le redessinait pour son compte.
Le sortir est une déduplication, pas un ajout. La liste des composants partagés
passe donc de neuf à dix.

### La validation des dossiers se construit sur la lecture, pas à côté

`dossiers_en_attente()` et `decider_dossier()` passent toutes deux par
`read_kyc_documents()`. Le cloisonnement de genre et la journalisation sont donc
tenus par une seule porte, et connaître un identifiant ne permet pas de la
contourner.

---

## Impacts sur la roadmap

| Étape | Changement |
| :--- | :--- |
| 1 - Fondations DB | `session_participants` plusieurs-à-plusieurs. Tables finance créées sans interface. `access_until` sur le profil élève. `video_config`. Statut de compte à quatre valeurs incluant `provisoire_actif`, colonne `kyc_completion_deadline` (ADR-014). |
| 2 - Core Flutter | `VideoSessionProvider` abstrait et implémentation LiveKit isolée. Règle de recherche à zéro résultat sur l'URL. |
| 5 - Visio | Egress audio, bandeau permanent inchangé, `hidden` pour le Contrôleur, exclusion de rôle enseignant et contrôleur, purge à 30 jours, politique audio d'abord. |
| 6 - Pédagogie | Réduite au cahier de transmission. Évaluations et objectifs sortis. |
| 7 - Finances | Entièrement reportée en V1. |
| 8 - Guard et exports | Reporté en V1. |

Le MVP-0 tient donc en : Étape 0, 1, 2, 3, 4, 5 et une Étape 6 allégée.

---

## Registre unique des questions ouvertes

Ce tableau est la seule liste à consulter. Il remplace les listes qui figuraient dans `docs/historique/couverture-specs.md` et `docs/historique/etat-des-lieux.md`, tous deux archivés, leur travail étant fait.

| # | Question | Bloque | Statut |
| :-- | :--- | :--- | :--- |
| 1 | Le "système de création d'objectifs élèves" reporté en V1 : est-ce la grille d'examen anonyme et l'imputabilité des specs d'origine, ou autre chose | Étape 6 | Ouverte |
| 2 | Un enseignant a-t-il une photo publique visible par les familles avant le premier cours | Étape 3, 4 | Ouverte |
| 3 | Riwaya du mushaf, Warsh ou Hafs | Étape 5 | Ouverte |
| 4 | Identité visuelle, violet de l'application ou vert et or de Rewayah | Étape 2, 4 | Non bloquant, jetons de couleur abstraits |
| 5 | Seuil d'âge exact séparant le mode enfant du mode standard | Étape 3 | **Résolue par défaut, pas par décision** : `child_ui_mode_max_age` vaut 8 dans `app_config` et l'étape 3 s'en sert. Modifiable en une ligne, sans redéploiement. À confirmer par l'opérateur (ADR-016) |
| 6 | Poular dans l'interface élève dès le MVP-0 ou plus tard | Étape 3 | **Résolue par la négative** : pas de poular dans l'application (ADR-015) |
| 7 | Format de compression des photos | Étape 2 | Résolue par défaut, WebP |
| 8 | Prestataire de payout de remplacement | V1 | Non bloquant |
| 9 | Coupure automatique ou non à l'échéance des 30 jours de migration | Étape 7, plus tard | Résolue par défaut, pas de coupure automatique (ADR-014) |
| 10 | `borderDefault` mesure 1,86:1, sous le seuil de 3:1 des éléments non textuels. Jeton décoratif seulement, ou passage à `#8F8080` (3,03:1) pour qu'il puisse porter du sens | Étape 3, 4 | Ouverte. Traité comme décoratif en attendant : le focus et l'erreur passent par `surfacePrimary` et `surfaceAlert` |
| 11 | `NotoSans-Variable` pèse 2 Mo pour une interface française. Sous-ensembler la police, et avec quel outil dans la chaîne de build | Étape 4 | Ouverte, mesurée dans `etape-2-journal.md` |
| 12 | `0001` fait `create extension if not exists pgcrypto` sans schéma et appelle `public.digest`. Sur un projet Supabase où pgcrypto vit déjà dans le schéma `extensions`, la migration échouerait à sa première application réelle | Étape D, premier `db push` | Ouverte. `0004` suit volontairement la même convention : un seul problème, une seule correction. Voir `etape-3-journal.md` |
| 13 | Lecture du QR par la caméra sur l'appareil de l'enfant | Étape 4 ou plus tard | Reportée (ADR-016). Le chemin par le code fonctionne partout ; l'interface est posée pour recevoir un lecteur |
| 14 | Limitation de débit sur l'échange d'un code d'appairage | Si la durée de validité s'allonge | Non traitée, arithmétique consignée dans `supabase/functions/session-enfant/index.ts` : 32^6 combinaisons pour une fenêtre de dix minutes |

Toute nouvelle décision prise en cours de développement s'ajoute à ce même tableau, jamais dans un nouveau document séparé.
