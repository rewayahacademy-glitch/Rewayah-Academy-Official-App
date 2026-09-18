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

## ADR-017 - Ce que l'étape 4 a dû trancher

Décisions prises avec l'opérateur le 6 septembre 2026, avant d'écrire la
migration `0005`, parce que chacune décide du schéma. Détail d'exécution dans
`docs/architecture/etape-4-dashboards.md`.

### Le matching est un engagement durable, pas une réservation

« Le matching, c'est un mariage. » Un enseignant qui prend un élève le garde. Ce
que prend `ENS-06` n'est donc pas un créneau, c'est un **élève** ; le créneau
n'est que l'heure du rendez-vous hebdomadaire qui en découle.

La relation ne se rompt que par une **demande de réaffectation**, ouverte à
quatre parties : administration, contrôleur, tuteur ou élève adulte autonome, et
enseignant. Aucune ne se dégage seule, et la décision revient à
l'administration.

Un modèle par réservations successives aurait fait retomber chaque foyer en
« recherche d'enseignant » après chaque cours, ce qui est le contraire du
produit vendu.

### Cinq élèves par enseignant, et la demande qui l'augmente

Valeur d'`app_config`, jamais une constante de code, cohérente avec le groupe de
six de l'ADR-004. Un enseignant qui a du temps demande une augmentation, du même
registre que la réaffectation.

### Une séance de 60 minutes, payable à partir de 45

Les cases de la grille de `TUT-04` et de `ENS-06` durent une heure.

Le minimum payable existe pour que **ni une pause ni une prière ne fasse tomber
une séance sous le seuil de rémunération**. C'est la mécanique de compensation
que `couverture-specs.md` signalait comme non spécifiée, et la question 3 de
l'audit initial trouve ici sa réponse.

### Les prières sont calculées, ajustables, annoncées et consignées

Calcul réel par le paquet `adhan`, contre les deux autres options proposées, la
saisie manuelle et l'approximation par ville.

Quatre exigences l'accompagnent, nées d'un litige réel de l'académie : tout le
monde voit les interruptions **à l'avance**, une alerte prévient de leur
approche, chacune est **consignée**, et l'heure calculée s'ajuste **à la minute
près** quand elle ne correspond pas à la mosquée de référence.

Conséquence de conception : les **réglages** sont en base et le calcul est
déterministe, donc tous les rôles obtiennent la même minute. Un enseignant qui
calculerait chez lui et annoncerait le résultat ne produirait pas de la
transparence, seulement une parole contre une autre.

La durée de l'interruption et le **préavis de son alerte** sont dans cette même
ligne. Un préavis porté par chaque application aurait prévenu l'enseignant dix
minutes avant et l'élève cinq : la pause et son annonce voyagent ensemble.

Le calcul se fait en **instants absolus**, jamais en heures locales : entre
Paris et Conakry, la même prière du même cours ne tombe pas la même heure ni
toujours le même jour civil. Chacun l'affiche dans son fuseau, tous parlent du
même moment.

### Aucune règle n'est figée, et chaque élève peut avoir la sienne

L'administration change ces valeurs **élève par élève, à la volée ou sur demande
d'une des parties**. Un enfant de six ans qui décroche à trente minutes et un
adulte autonome qui veut deux heures ne relèvent pas de la même règle.

Trois étages : le défaut de plateforme dans `app_config`, la surcharge d'un
profil dans `rule_overrides`, et la demande d'une partie dans
`matching_requests`. Une seule fonction de lecture, `regle_effective()` : un
écran qui lirait `app_config` en direct afficherait la règle de la plateforme à
un élève qui n'en relève pas.

**Une surcharge ne se supprime pas, elle se clôt**, avec son auteur et son motif.
Une règle qui a compté pour une séance passée doit rester vérifiable six mois
plus tard, sinon la consignation ci-dessus ne prouve rien.

### Une seule table de disponibilités pour les deux rôles

`TUT-04` et `ENS-06` affichent la même grille : un motif hebdomadaire commun,
`weekly_availability`. Deux tables jumelles divergeraient à la première
évolution. `availability_slots`, en instants absolus, reste pour les exceptions
datées d'une version ultérieure et n'est pas employée en MVP-0.

---

## ADR-018 - Refonte UX/UI : un langage avant les écrans

Décision de l'opérateur du 7 septembre 2026, après que le premier rendu visuel
de l'application ait été jugé daté. Le corpus complet est dans **`docs/design/`**,
neuf fichiers, dont `README.md` fait office de constitution.

### Le problème n'était pas dans les écrans

Chaque écran a été spécifié dans le plan de son étape, puis construit. Ça a
produit des écrans corrects un par un et un ensemble qui ne ressemble pas à un
produit. Le défaut est l'absence de **langage** au dessus des écrans : un agent
qui reçoit « fais `ADM-01` » sans langage invente un rayon, une carte, un bouton,
et l'écran suivant en invente d'autres.

Cinq causes mesurables, corrigées ensemble :

1. **Une seule surface.** Fond de page, carte, champ de saisie et en-tête
   partageaient la même couleur. Sans deux surfaces, pas de hiérarchie possible.
2. **Les couleurs de marque n'existaient qu'en aplats saturés.** Un
   avertissement occupait un pavé `#FFB703` entier.
3. **Le fond était le rose pâle `#F1E3E4`**, teinte 356°, qui vire au beige sale
   ou au mauve selon l'écran.
4. **Un seul jeton de bordure, mesuré à 1,86:1**, donc invisible et pourtant
   employé pour délimiter.
5. **Aucun crénage optique, aucun rayon systématique, aucune ombre**, et une
   police de titre à graisse unique au registre du début des années 2010.

### Ce qui est tranché

**La palette de marque est conservée**, dans ses cinq couleurs. Ce qui change est
le rôle de deux d'entre elles et l'ajout de leurs déclinaisons.

- Le fond général passe au **crème `#F8F4EE`**, teinte 36°, écart entre canaux de
  10. Le témoin jaunâtre auquel il a été comparé, `#FBF3D9`, a un écart de 34 :
  le jaunissement se lit sur la chromaticité, pas sur la teinte.
- Le rose pâle `#F1E3E4` **garde sa valeur** et devient la teinte du domaine
  foyer, au lieu d'être le fond de tout le produit.
- Chaque famille sémantique reçoit un **registre doux** : une teinte pâle et une
  encre foncée de la même famille. L'aplat saturé est réservé à une seule zone
  par écran.
- Trois bordures remplacent l'unique `borderDefault` : deux décoratives et une
  porteuse de sens, `#8F8279`, mesurée à 3,40 sur le crème.
- **Les polices arabes ne changent pas.** Les deux polices françaises sont
  remplacées par Bricolage Grotesque (titres, axe `opsz`) et Instrument Sans
  (corps), toutes deux OFL et variables.

Toutes les valeurs et leurs mesures sont dans `docs/produit/design-tokens.md`,
qui reste la source unique. Les documents de `docs/design/` disent comment les
employer et ne recopient aucune valeur.

### La règle qui compte le plus

> **Aucun écran ne s'implémente s'il n'est pas inscrit dans
> `docs/design/08-catalogue-ecrans.md`.**

Si un écran manque au catalogue, on l'ajoute au catalogue d'abord, avec sa fiche,
et on discute de la fiche avant d'ouvrir un fichier `.dart`. C'est cette règle,
et pas le goût de qui construit, qui tient la cohérence.

### Ce que la refonte ne change pas

Plusieurs recommandations de la note de refonte étaient déjà tranchées ici,
parfois dans l'autre sens. Le tableau complet est en section 7 du
`docs/design/README.md`. Les trois à retenir :

- **La contradiction « qui pose les créneaux »** n'existe pas dans ce dépôt :
  une seule table `weekly_availability`, la famille pose ses créneaux,
  l'enseignant prend **un élève** et le garde (ADR-017). Ne pas la « corriger ».
- **Le mode enfant est déjà un mode d'interface**, porté par le profil, pas un
  rôle (ADR-009, ADR-016).
- **La séance porte déjà des participants en plusieurs-à-plusieurs**, avec
  observateurs masqués (ADR-004, ADR-011).

### Conséquence sur l'ordre de travail

L'étape 5 attend. Trois lots passent avant : **T** les jetons et le thème, **C**
les douze composants de priorité P0, **R** la reprise des quatre écrans déjà
construits. Reprendre un écran avant les jetons obligerait à le reprendre deux
fois.

## ADR-019 - Adoption de la Bible Frontend V2, deuxième refonte

Décision de l'opérateur du 11 septembre 2026. Le rendu mobile déployé après le
lot R3 (`ELV-02`, `TUT-01`, `ENS-02`, `ADM-01` repris, `NavShell` câblé) a été
jugé « plus nul que du générique ». L'opérateur a remis une deuxième Bible,
`REWAYAH_FRONTEND_UIUX_BIBLE_V2.clauderules.md`, plus stricte et plus complète
que la note du 7 septembre, avec l'instruction explicite qu'elle ne se
redonnera pas une troisième fois : elle doit être **permanente**.

### Ce qui est adopté

Le texte intégral, copié sans modification dans
`docs/design/00-bible-frontend-v2.md`, devient le document 0 du corpus design,
lu avant `README.md`. Ce texte ne se réécrit jamais : c'est la table de
correspondance de `README.md` §4 BIS qui absorbe l'évolution, chapitre par
chapitre.

### Ce que l'audit a mesuré avant d'exécuter

Le dépôt couvrait déjà environ soixante pour cent du contrat au moment de son
adoption, et plusieurs fois mieux qu'exigé : `tool/verifier_jetons.dart`
applique en CI des règles que la Bible se contente d'écrire (aucun hardcoding
visuel, échelle de spacing, shape system, RTL à partir de ce lot). Les écarts
réels, mesurés et non supposés, sont les trois causes du rejet du 11 septembre
— le tunnel d'entrée jamais repris, le bouton d'action principale désactivé qui
ressemble à une panne, les ombres et bordures trop faibles pour porter une
hiérarchie — plus l'absence totale de mode sombre (§7.3), le RTL non outillé et
non testé (§14), et les exigences neuves de la Bible sur une étape 5 pas encore
construite (§19-32 : la salle, le Coran comme contenu structuré et non comme
PDF, la séparation état partagé/état personnel, la machine à états de
présence).

### Deux dérogations écrites (§0.3 de la Bible elle-même)

1. **§7.2, couleurs par `ColorScheme`.** La Bible demande d'utiliser
   prioritairement `Theme.of(context).colorScheme`. Ce dépôt fait l'inverse :
   `AppPalette` (une `ThemeExtension`, voir `lib/core/theme/app_palette.dart`)
   est la source de vérité, et le `ColorScheme` Material en est **dérivé** dans
   `app_theme.dart`, pour qu'aucun widget Material non enrobé ne puisse
   ressortir une couleur hors palette. Impact : aucun, c'est la construction
   déjà en place depuis le lot T. Alternative écartée : inverser le sens de
   dérivation, ce qui aurait cassé la garantie « aucune couleur littérale hors
   d'un seul fichier » que porte `verifier_jetons.dart`. Portée : tout le
   thème, définitivement, sauf changement d'architecture explicite. Conforme à
   la fin de la même section 7.2, qui autorise l'exposition via un
   `ThemeExtension`.
2. **§7.3, mode sombre.** Non traité comme une dérogation permanente : planifié
   et fermé au lot **T3** de la feuille de route ci-dessous, pas laissé ouvert.

### La règle des trois couches d'ancrage

Pour que cette Bible n'ait pas besoin d'être redonnée une troisième fois, elle
est portée par trois couches, de la plus faible à la plus forte :

1. **Mémoire d'agent** : survit aux sessions Claude Code, pas au changement
   d'outil.
2. **Documents versionnés** (ce fichier, `docs/design/`, `CLAUDE.md`,
   `lib/CLAUDE.md`, `docs/AGENT_HANDOFF.md`) : survivent au changement d'agent,
   lus aussi par OpenCode et Hermes.
3. **Règles machine** (`tool/verifier_jetons.dart`, suites de tests) :
   survivent à l'inattention, la seule couche qui empêche au lieu de demander.

Chaque chapitre de la Bible est porté par la couche la plus forte qui peut le
tenir. Un chapitre outillable resté seulement documenté est considéré comme un
chapitre qui finira par être violé, pas comme un chapitre tenu.

### Ordre de travail

Huit lots, un par session, chacun se terminant par les cinq contrôles de
`docs/HANDOFF.md` §5 et un commit-push : **B0** (ce lot, ancrage) → **T2**
(durcir le langage) → **R0** (tunnel d'entrée) → **T3** (mode sombre) → **R4**
(reste de l'existant) → **A1** (accessibilité, RTL et clavier prouvés par des
tests) → **N0** (specs de l'étape 5, documentaire) → **L10** (clôture de
l'étape 4, dette indépendante). Détail complet dans `README.md` §9.

---

## ADR-020 - Spécification de l'étape 5 : salle, Coran structuré (Hafs, Roi Fahd), présence

Décision de l'opérateur du 11 septembre 2026, lot **N0** de l'ordre de travail
de l'ADR-019 (documentaire, aucun écran ni migration codés ici). Détail complet
dans `docs/architecture/etape-5-salle-coran-presence.md`, qui tient pour
l'étape 5 le rôle que `etape-4-dashboards.md` tient pour l'étape 4.

### Ce qui est tranché

1. **Riwaya et édition du Coran** : Hafs ʿan ʿĀṣim, édition Mushaf
   Al-Madinah An-Nabawiyyah du Complexe du Roi Fahd, pagination standard (604
   pages, 15 lignes par page). Ferme la question 3 du registre ci-dessous. Ce
   choix confirme un défaut déjà présent en base depuis l'étape 1 :
   `student_profiles.riwaya` vaut `'hafs'` par défaut, jamais écrit autrement.
   **Non tranché par la même décision** : la source technique des données
   (jeu de données ou API, police, licence), qui reste un choix de fournisseur
   à faire au codage.
2. **Modèle du Coran comme contenu structuré**, adapté des §23-24 de la Bible
   V2 : `mushaf` → `sourate` → `page_mushaf` → `verset` (`mot` en option,
   reporté tant que le focus mot-à-mot n'est pas un P0 confirmé), plus
   `student_reading_position` pour l'état personnel de lecture, distinct de
   l'état partagé de séance (règle critique §24.3 : une action de l'enseignant
   n'écrase jamais silencieusement la position personnelle d'un élève).
3. **Machine à états de présence**, par participant (distincte de
   `StatutSeance`, qui reste l'état de la séance entière) : les 14 états de la
   Bible V2 §29.1, traduits et adossés à `session_events`/`session_event_type`
   déjà existants (`joined`, `left`, `track_subscribed`, `track_unsubscribed`,
   `record_started`, `record_ended`) et à leur colonne `source`. C'est une
   dérivation (vue ou calcul), pas une nouvelle table d'événements bruts.
4. **Aucune dérogation à la Bible V2** n'est nécessaire sur ce périmètre : les
   §19-32 sont un modèle UX abstrait, sans prescription de jetons ou de
   composants en conflit avec ce que le dépôt a déjà posé.

### Ce qui reste explicitement ouvert, non inventé par ce lot

Source technique des données Coran, seuil de retard et fenêtre de reconnexion
de la présence, vocabulaire exact de `session_events.source`, écran et policy
pour marquer un participant excusé, canal de diffusion de l'état partagé de
séance, granularité mot-à-mot. Détail et raison de chaque point :
`etape-5-salle-coran-presence.md` §10.

---

## ADR-021 - L'administration peut attribuer hors des disponibilités d'un enseignant, jamais en silence

Décision prise le 12 septembre 2026, au lot `ADM-05`, et **prise par l'agent
faute de pouvoir attendre** : elle est réversible, et le paragraphe « comment la
défaire » ci-dessous dit exactement à quel prix.

### Le problème

`parcours-utilisateurs.md` §5 définit `ADM-05` comme « l'écran de secours quand
le matching inversé ne produit rien ». Or le matching inversé ne produit rien
pour deux raisons distinctes :

1. des enseignants partagent une heure avec la famille, mais aucun n'a pris
   l'enfant dans `ENS-06` ;
2. **aucun enseignant ne partage d'heure avec elle.**

Un `ADM-05` qui n'accepterait qu'un créneau commun ne traite que le premier cas.
Dans le second, c'est-à-dire précisément le jour où l'on ouvre cet écran, il
afficherait une colonne de droite vide. Un écran de secours qui ne secourt pas
le cas pour lequel il existe n'en est pas un.

### Ce qui est tranché

- **L'administration peut attribuer un enseignant sur une heure qu'il n'a pas
  posée.** Le geste existe, il n'est pas caché derrière un réglage.
- **Il exige un motif, vérifié en base et non seulement à l'écran.**
  `attribuer_eleve()` refuse un motif vide ou fait d'espaces. Ce qui ne se
  vérifie qu'au clavier finit par ne plus se vérifier du tout.
- **Il est journalisé avec le fait lui-même** : la ligne `audit_logs` porte
  `hors_disponibilite: true` et le motif. Six mois plus tard, « pourquoi cet
  enseignant a-t-il ce cours le mardi » se relit.
- **L'heure reste celle de la famille.** C'est la seule limite qui ne bouge
  pas : `attribuer_eleve()` refuse tout créneau absent de
  `weekly_availability` de l'élève, exactement comme `prendre_eleve()`. Une
  administration ne choisit pas l'heure du cours d'un enfant à la place de ses
  parents, et un enfant indisponible ne devient pas disponible parce qu'un
  adulte l'a décidé.
- **Le plafond ne se contourne pas.** Le déclencheur `assignments_cap` de
  `0005` tourne pour cette porte comme pour l'autre. Dépasser un plafond se
  fait en le changeant, depuis `ADM-06`, et cela laisse sa propre trace.

### Ce que cela ne dit pas

Rien sur le droit du travail ni sur l'accord de l'enseignant. Le produit
enregistre une décision humaine et son motif ; il ne prétend pas que la
décision était fondée. L'accord se prend hors de l'application, et le champ
motif est l'endroit où l'on écrit qu'il a été pris.

### Comment la défaire, si l'opérateur la refuse

Retirer le calcul `v_hors` et la branche qui l'accompagne dans
`attribuer_eleve()` (migration `0008`), et remplacer par un refus sec quand le
créneau ne figure pas dans les disponibilités de l'enseignant. Côté écran,
`_ColonneEnseignants.offerts` rendrait alors toujours `creneauxCommuns`, et la
carte d'un enseignant sans heure commune deviendrait non sélectionnable, comme
celle d'un enseignant au plafond. Le contrôle A6 de
`supabase/tests/scenarios_adm05.sql` s'inverse. Coût : une heure, et l'écran
redevient vide dans le cas 2 ci-dessus.

---

## ADR-022 - Le journal d'audit prouve son intégrité, et ne journalise pas sa propre lecture

**Statut** : acceptée, 12 septembre 2026, lot `ADM-04`.
**Contexte** : `audit_logs` porte `prev_hash` et `hash` depuis l'étape 1, et
`log_sensitive_access()` prend un `lock table ... share row exclusive` à chaque
écriture pour les tenir cohérents. Jusqu'à ce lot, **personne ne les relisait** :
le coût était payé à chaque geste du produit, et la garantie n'avait jamais été
constatée une seule fois.

### Décision 1 : la chaîne est vérifiable, et l'écran la vérifie

`verifier_chaine_audit(p_limite)` recalcule, pour chaque entrée de la fenêtre,
les deux quantités que l'écriture avait posées :

```
condensat = sha256(acteur || role || action || table || ligne || payload)
hash      = sha256(prev_hash || condensat)
```

C'est possible parce que **les six morceaux sont tous stockés en colonnes** :
`auth.uid()` dans `actor`, `app_role()` dans `actor_role`, le reste tel quel. Et
parce que `payload` est une colonne `jsonb`, dont le rendu texte est canonique :
avec une colonne `json`, l'espacement d'origine aurait survécu et la comparaison
aurait échoué sur des entrées pourtant saines.

**Deux contrôles par entrée, et il faut les deux.** Le condensat dit que la
ligne n'a pas été modifiée. Le maillon (`prev_hash` = `hash` de l'entrée
précédente) dit qu'aucune ligne n'a été **retirée** entre les deux — une
suppression laisse tous les condensats valides et ne se voit que là. Les
scénarios `J5` et `J6` de `supabase/tests/scenarios_adm04.sql` falsifient
délibérément le journal, l'un par `update` et l'autre par `delete`, désarment le
déclencheur pour y parvenir, vérifient que chacun se voit **à un endroit
différent**, puis réparent et reverifient.

Mesuré sur la base réelle avant d'écrire la migration : **34 entrées sur 34 se
recalculent, 34 maillons sur 34 se chaînent.**

### Décision 2 : la vérification ne voyage pas avec la liste

Elle a sa propre fonction, et l'écran son propre provider. Un `lag()` posé sur
une liste **filtrée** comparerait chaque entrée à la précédente *du filtre* et
non à celle de la chaîne : le journal se déclarerait rompu dès le premier filtre
posé. Et calculer un condensat par ligne à chaque page coûterait un sha256 par
entrée affichée, pour une information qui ne dépend pas du filtre.

### Décision 3 : les trois lectures sont réservées à `admin`

La policy `audit_logs_read` de `0001` autorise pourtant aussi `controller`, et
**elle n'est pas touchée** : un contrôleur lit `audit_logs` exactement comme
avant, par la table. Mais les trois fonctions sont `security definer`, donc
au-dessus de la RLS, et elles résolvent l'identité de l'acteur par `profiles` —
or `profiles_family_select` ne laisse un contrôleur voir que les profils de
**son** foyer. Les ouvrir au contrôleur lui donnerait les noms de tout le
personnel. Le scénario `J1` mesure les deux moitiés : les fonctions refusées, la
policy intacte.

### Décision 4 : la consultation du journal ne s'inscrit PAS au journal

C'est le point le plus discutable, et il est ouvert en **question 27**.

Deux raisons de ne pas le faire aujourd'hui. `log_sensitive_access()` prend un
verrou de table : journaliser une lecture paginée et filtrée ferait prendre ce
verrou à chaque page, sérialisant les lectures du journal contre **toutes** les
écritures du produit. Et une consultation produirait autant d'entrées que de
pages parcourues, noyant les événements métier sous les traces de leur propre
consultation.

**Comment la défaire, si l'opérateur veut une trace de consultation** : un
`perform public.log_sensitive_access('journal_lu', 'audit_logs', null, ...)`
dans `journal_audit()`, conditionné au **premier appel sans curseur** — c'est-à-dire
une entrée par consultation et non par page. Coût : une heure, plus un scénario
qui vérifie qu'une pagination de trois pages n'écrit qu'une ligne.

---

## ADR-023 - Les deux fournisseurs vidéo coexistent, et la route est ancrée par séance

**Décision de l'opérateur, 12 septembre 2026**, prise à l'ouverture du lot N2 :
« si tu penses que tu peux ajouter les deux, fais-le : Cloud pour tester l'app,
self-hosted pour le scaling. Mais jamais Cloud tout seul, car c'est cher. »

### Ce que cela change par rapport à l'ADR-001

L'ADR-001 prévoyait LiveKit Cloud d'abord, avec une portabilité conçue pour une
migration **future**. La spécification d'intégration, elle, penchait en §8 pour
un déploiement self-hosted. Les deux avaient raison sur un point et tort sur
l'autre : le Cloud seul devient cher dès les premiers élèves réels — le tier
gratuit plafonne vers quatre élèves en un-à-un — et le self-hosted seul oblige à
déployer TURN en TCP 443 avant d'avoir prouvé quoi que ce soit, faute de quoi
les élèves sur réseaux mobiles restrictifs ne se connectent pas du tout.

`video_config` cesse donc d'être un filet de migration pour devenir
**l'aiguillage permanent** du produit : `active_provider` désigne le fournisseur
courant, `canary_provider` et `canary_percentage` en routent une fraction vers
l'autre, `ws_url_override` pointe un serveur précis sans redéployer quoi que ce
soit. Les secrets Supabase sont doublés en conséquence :
`LIVEKIT_CLOUD_*` et `LIVEKIT_SELFHOST_*`.

### Le piège que cette décision crée, et comment il est fermé

Faire coexister deux serveurs ouvre une faute qui ne se voit pas en relecture :
**si le fournisseur était tiré à chaque émission de jeton, un enseignant et son
élève pourraient atterrir sur deux serveurs différents et ne jamais se voir.**
Le cours serait perdu sans qu'aucune erreur ne s'affiche nulle part — les deux
seraient « connectés », chacun dans une salle vide.

`session_video_route` ferme cela : la **première** émission de jeton d'une
séance fige le fournisseur, l'URL et le nom de salle ; toutes les suivantes les
relisent. Trois conséquences, toutes voulues :

1. Un changement de `canary_percentage` en cours de séance ne peut plus couper
   une salle en deux. Il ne s'applique qu'aux séances qui n'ont pas commencé.
2. Le tirage du canari est **déterministe**, dérivé du `session_id` par `md5` et
   non d'un hasard : deux appels concurrents choisissent la même chose avant
   même que l'unicité de la clé primaire ne tranche.
3. Un participant qui arrive en retard, après un changement de configuration,
   rejoint le serveur de ses camarades et non le nouveau.

### Ce que le client Flutter ne sait toujours pas

Le contrat de portabilité de l'ADR-001 est **renforcé**, pas assoupli :
`grep -ri 'livekit.cloud\|wss://' lib/` doit rendre zéro résultat. L'URL arrive
du backend à chaque session, avec le jeton. `lib/core/video/livekit_session_provider.dart`
reste le seul fichier autorisé à importer `livekit_client`, et
`supabase/functions/_shared/livekit.ts` le seul à importer le SDK serveur.

### Ce que cette décision ne tranche pas

Elle ne dit pas **quand** basculer sur le self-hosted, ni sur quel hébergeur.
Ce sont des décisions d'exploitation, à prendre sur des chiffres de charge
réels — pas avant. L'aiguillage existe pour que ce jour-là coûte une ligne de
`video_config`, pas un lot de développement.

### Comment défaire

Revenir au Cloud seul : `update video_config set canary_provider = null,
canary_percentage = 0, active_provider = 'cloud'`. Aucun code ne change, aucun
déploiement n'est nécessaire. C'est la propriété qui justifie toute la
construction.

---

## ADR-024 - Le corpus coranique est importé, pas appelé

**Décision de l'opérateur, 13 septembre 2026**, prise à l'ouverture du lot N5
sur un critère explicite : « je veux la version qui propose le plus de
flexibilité/adaptation ». Elle ferme la question `a` du §10 de
`etape-5-salle-coran-presence.md`, ouverte depuis N0 : l'ADR-020 avait tranché
la **riwaya** (Hafs, Mushaf de Médine), jamais la **source technique**.

### Ce qui est décidé

Le texte, la pagination, les sourates et les juz viennent du **Tanzil Project**
(`quran-uthmani`, version 1.1, et `quran-data.xml`), sous **Creative Commons
Attribution 3.0**, et ils sont **importés une fois pour toutes** dans la base
par la migration `0013`. Le rendu est **Unicode**, avec la police
`UthmanTahaNaskh` déjà embarquée depuis le lot T.

### L'alternative examinée, et pourquoi elle est écartée

L'API Quran Foundation (quran.com v4) sert les mêmes données, avec un layout
mushaf plus riche. Ses conditions pour développeurs l'excluent :

- **« Cache or store QF Content longer than 1 week »** est interdit, sauf par
  les Content Sync APIs resynchronisées au moins tous les sept jours. Le Coran
  est le contenu du produit : le rendre périssable, et le hors-ligne
  impossible, coûte plus que l'import ne coûte ;
- toute redistribution du contenu ou des données brutes exige une **licence
  commerciale signée** ;
- les accès sont révocables **« immediately and without liability »**. Un tiers
  pourrait fermer le lecteur de Coran du produit du jour au lendemain.

Une licence CC BY 3.0 sur un fichier qu'on possède ne peut rien faire de tout
cela. C'est en ce sens précis qu'elle est « la plus flexible ».

### Les trois obligations que cette licence crée, et où elles sont tenues

1. **Le texte ne se modifie jamais** (« CHANGING IT IS NOT ALLOWED »). Aucune
   policy n'ouvre l'écriture de `verset` hors administration, et le contrôle
   `C4` de `scenarios_n5.sql` le mesure.
2. **La notice de copyright est reproduite** dans tout fichier dérivé : elle
   est en tête de `0013`, mot pour mot.
3. **La source est clairement indiquée, avec un lien vers tanzil.net.** Elle
   est au pied de **chaque page** du lecteur, dans le flux, pas dans un écran
   « à propos » que personne n'ouvre. ⚠ Le lien n'est pas encore **cliquable** :
   `url_launcher` n'est pas au `pubspec.yaml`, et l'y ajouter demandait de
   toucher un fichier qu'une autre session modifie. L'URL est affichée en
   clair ; la rendre cliquable est une ligne, le jour où le `pubspec` est libre.

### Ce que cette décision ne tranche pas, et le piège qu'elle documente

Elle ne donne **pas** le découpage en quinze lignes par page. Le layout QPC v2
du Quranic Universal Library le porte, mais il **compte les mots autrement que
le texte Tanzil** : 83 668 contre 77 881, mesuré le 13 septembre, pas supposé.
Faire coïncider les deux demanderait de deviner une correspondance sur un texte
sacré. La colonne `verset.ligne` reste donc **nulle** — `0007` l'autorise — et
rien dans l'application n'en dépend. Le jour où une source unique porte le
texte **et** ses lignes, elle se remplit sans qu'aucun écran ne change.

### Comment défaire

Le contrat de l'invariant **J6** est ce qui rend ce choix réversible : aucune
couche d'affichage ne dépend d'un identifiant de fichier, et `VersetCoran` ne
porte que sa place et son texte. Passer aux glyphes d'une édition, ou à une
API, se fait en changeant `ServiceCoran` — une classe — sans toucher à l'écran.

---

## ADR-025 - Un agent IA observe l'application par les yeux d'une personne, et ne peut rien écrire

**Décision de l'opérateur, 18 septembre 2026.** Elle ouvre un besoin neuf :
faire entrer des agents IA dans l'application **déployée**, en temps réel,
après que l'opérateur a lui-même remis un jeton et choisi un parcours.

Quatre choix ont été tranchés à l'ouverture du lot :

| Question | Choix de l'opérateur |
| :--- | :--- |
| Par quelle porte l'agent entre-t-il | **L'application dans un navigateur**, pas une API ni un serveur MCP |
| Que voit un parcours | **Le point de vue d'une personne désignée**, pas le rôle sur toute l'académie |
| Les données personnelles | **Masquées par défaut**, avec un jeton nominatif possible |
| Où s'émet un jeton | **Un écran d'administration**, « plus simple que celui de PISI » |

### Le problème que ce canal pose, et qui commande toute l'architecture

Rewayah **n'a pas de serveur applicatif**. Flutter parle directement à
PostgREST ; la RLS est la barrière, le routeur n'est qu'une commodité. Un agent
qui pilote l'application déployée détient donc une vraie session Supabase, et
tout ce que cette session peut faire, il peut le faire — en cliquant, ou en
rejouant la requête à la main. « Lecture seule » ne peut donc pas être une
propriété de l'interface : masquer un bouton n'a jamais empêché d'appeler
l'action.

Ce constat exclut d'emblée la solution qui vient à l'esprit — ouvrir une session
sur le compte de la personne, ou sur un compte de service dédié. C'est
exactement la faute payée sur l'autre produit de l'opérateur le 5 août 2026 :
dès qu'on remet une session complète à un tiers, **tout privilège attaché au
compte devient un privilège attaché au porteur, hors de l'application**.

### Ce qui est décidé

Le jeton d'observation est échangé contre une session signée dont **trois
claims** portent toute l'architecture :

1. **`sub` = la personne observée.** Les 105 policies et les dix vues de ce
   dépôt se bornent déjà par `auth.uid()`, `app_household_id()` et
   `app_role()`. En signant avec l'identifiant de la personne observée, l'agent
   hérite de son écran — exactement, ni plus ni moins — **sans qu'une seule
   règle de sécurité soit réécrite pour lui**. C'est le point central : une
   deuxième règle serait une règle à maintenir, donc une règle qui finirait par
   diverger de la première.

2. **`role` = `agent_ro`**, un rôle Postgres créé par `0014` qui ne détient
   **aucun** droit d'écriture. La lecture seule est un défaut de privilège du
   moteur, pas une politesse de l'interface.

3. **`app_metadata.agent_token_id` = un identifiant opaque**, jamais des
   droits. La portée — qui est observé, sous quel parcours, avec ou sans
   identité — se relit **en base à chaque requête**, par le garde
   `agent_pre_request()` branché sur `pgrst.db_pre_request`. Révoquer la ligne
   coupe l'accès à la requête suivante, sans attendre l'expiration de la
   signature.

La session signée vit **quinze minutes** et il n'existe **aucun jeton de
rafraîchissement** : pour continuer, le porteur repasse par la fonction Edge,
donc par la base, donc par la vérification de vivacité. Le jeton lui-même est
plafonné à **24 heures côté serveur**, et sa portée est **figée à l'émission** —
un déclencheur refuse toute écriture de `parcours`, `profil_observe`,
`identite_masquee` ou `expire_le`. Pour changer de portée, on émet un autre
jeton.

### Ce que la migration a mesuré, et qui n'était pas su avant

- **Les 105 policies du dépôt sont toutes `to authenticated`.** Elles ne
  s'appliquent donc pas à `agent_ro` : le défaut d'un agent est de **ne rien
  voir**, et chaque table lui est ouverte explicitement. Un oubli fait échouer
  une lecture ; il ne peut pas ouvrir une écriture. **C'est le bon sens de
  panne**, et c'est ce qui rend cette architecture tenable dans la durée.
- **L'écriture est barrée par deux couches indépendantes**, vérifié par test de
  mutation : il faut à la fois accorder le privilège **et** écrire une policy
  nommant `agent_ro` pour qu'une écriture passe. Ouvrir une seule des deux ne
  suffit pas.
- **Les dix vues portent `security_barrier`, jamais `security_invoker`** : elles
  appartiennent à `postgres` et ignorent la RLS des tables qu'elles lisent. Leur
  seule borne est le `where ... = auth.uid()` écrit dans leur corps — la leçon
  que `0011` a payée pour `presence_seance_v`. Toutes les dix ont été
  auditées : **toutes sont bornées relativement à l'appelant**. C'est ce qui
  rend le choix du `sub` sûr, et ce qui aurait rendu n'importe quel autre choix
  dangereux.
- **Le vrai trou était ailleurs, et il était invisible** : en PostgreSQL,
  `EXECUTE` sur une fonction est accordé à `PUBLIC` **par défaut**. `agent_ro`,
  membre de `PUBLIC` comme tout le monde, aurait hérité du droit d'appeler
  toute fonction dont personne n'a retiré ce défaut — dont des fonctions
  `security definer` qui écrivent. `0014` retire ce défaut en préservant
  l'existant, puis n'ouvre à l'agent que l'intersection de deux critères
  **mécaniques** : la fonction est `stable` ou `immutable` (PostgreSQL interdit
  au moteur toute modification de données dans une fonction non `volatile`) et
  elle est déjà appelable par `authenticated`. Jamais une liste tenue à la
  main : une liste s'oublie.

### Le masquage, et la limite que ce canal ne peut pas franchir

Une RLS borne les **lignes**, jamais les **colonnes**. Le masquage ne pouvait
donc pas s'y loger. Il est appliqué là où il est **dur** — dans les huit vues
qui portent un prénom, où l'identifiant immuable le remplace — et la table
`profiles` ne rend à un agent masquant qu'**une seule ligne** : celle de la
personne observée, dont l'application a besoin pour savoir qui elle est.

Reste la limite propre au canal choisi, et elle doit être dite : **ce que
l'écran de la personne observée affiche légitimement voyage dans la charge
réseau**. Un agent ne voit jamais plus que la personne qu'il observe — c'est le
plafond, et il est net — mais il voit tout ce qu'elle voit. Le masquage dur
au-delà de ce plafond exigerait le canal écarté (serveur MCP ou couche de vues
dédiée), où les données ne quittent jamais la base.

Trois tables ne sont ouvertes **à aucun agent, jamais** : `kyc_documents` (des
pièces d'identité de mineurs), `devices` (des empreintes d'appareil) et
`audit_logs` (la trace des autres). La table des jetons elle-même non plus : un
agent n'inventorie pas les accès de la maison.

### Les alternatives examinées, et pourquoi elles sont écartées

- **Un serveur MCP en lecture** aurait donné le masquage dur complet et une
  surface choisie outil par outil. Écarté par l'opérateur : il ne montre pas
  l'application, or c'est l'application qu'il s'agit de faire observer. Reste
  la bonne réponse le jour où le besoin devient « analyser », et non « voir ».
- **Un compte de service partagé** aurait été le plus rapide. Écarté : c'est la
  faute du 5 août 2026, et `auth.uid()` rendrait alors le compte de service, pas
  la personne — les dix vues ne renverraient rien.
- **Interdire l'écriture par une condition ajoutée à chaque policy d'écriture**
  a été écarté au profit des privilèges : durcir un garde en laisse deux
  ouverts, et surtout un oubli, dans ce sens-là, **échoue ouvert**.

### Ce qui reste à la main de l'opérateur

`SUPABASE_JWT_SECRET` doit être posé dans les secrets des fonctions Edge : la
fonction `agent-session` signe avec le secret JWT hérité du projet (encore
actif, les clés `legacy` du projet sont en HS256). **Aucun repli n'est prévu**
si le secret manque — un repli sur une valeur publique ne dégrade pas un sceau,
il le publie.

### Comment défaire

`revoke agent_ro from authenticator` suffit à fermer la porte sans toucher à
quoi que ce soit d'autre : aucune session d'agent ne peut plus être ouverte, et
l'application humaine ne s'en aperçoit pas. Le masquage dans les vues est inerte
hors session d'agent — `agent_identite_masquee()` rend `false` — et le garde
central rend la main immédiatement pour toute session humaine.

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
| 2 | Un enseignant a-t-il une photo publique visible par les familles avant le premier cours | Étape 3, 4 | **Résolue par la négative pour l'étape 4** : `TUT-01` et `mon_enseignant_v` donnent prénom et identifiant immuable, jamais de photo ni de nom complet (ADR-008). À rouvrir si le produit veut une vitrine d'enseignants |
| 3 | Riwaya du mushaf, Warsh ou Hafs | Étape 5 | **Résolue par ADR-020** : Hafs ʿan ʿĀṣim, édition Mushaf Al-Madinah An-Nabawiyyah du Complexe du Roi Fahd, pagination standard (604 pages, 15 lignes par page). Confirme le défaut déjà présent en base depuis l'étape 1 (`student_profiles.riwaya = 'hafs'`). La source technique des données (jeu de données ou API, police, licence) reste ouverte, à trancher au codage |
| 4 | Identité visuelle, violet de l'application ou vert et or de Rewayah | Étape 2, 4 | **Résolue par ADR-018** : la palette de l'application est conservée, le violet reste l'accent unique. Le vert et l'or restent des accents religieux réservés aux illustrations (`design-tokens.md` §5), jamais des couleurs d'interface |
| 5 | Seuil d'âge exact séparant le mode enfant du mode standard | Étape 3 | **Résolue par défaut, pas par décision** : `child_ui_mode_max_age` vaut 8 dans `app_config` et l'étape 3 s'en sert. Modifiable en une ligne, sans redéploiement. À confirmer par l'opérateur (ADR-016) |
| 6 | Poular dans l'interface élève dès le MVP-0 ou plus tard | Étape 3 | **Résolue par la négative** : pas de poular dans l'application (ADR-015) |
| 7 | Format de compression des photos | Étape 2 | Résolue par défaut, WebP |
| 8 | Prestataire de payout de remplacement | V1 | Non bloquant |
| 9 | Coupure automatique ou non à l'échéance des 30 jours de migration | Étape 7, plus tard | Résolue par défaut, pas de coupure automatique (ADR-014) |
| 10 | `borderDefault` mesure 1,86:1, sous le seuil de 3:1 des éléments non textuels. Jeton décoratif seulement, ou passage à `#8F8080` (3,03:1) pour qu'il puisse porter du sens | Étape 3, 4 | **Résolue par ADR-018, et autrement que par le choix proposé** : le jeton unique est remplacé par trois. `borderHairline` et `borderResting` sont décoratifs et assumés tels ; `borderStrong` `#8F8279` porte le sens et mesure 3,40 sur le crème, 3,73 sur une carte blanche. Un seul jeton ne pouvait pas faire les deux |
| 11 | `NotoSans-Variable` pèse 2 Mo pour une interface française. Sous-ensembler la police, et avec quel outil dans la chaîne de build | Étape 4, lot T | **Mesurée au lot T, et réduite à une seule question.** Le remplacement seul rend 1 544 Ko sur 2 131, soit 72 %, sans rien découper : les deux nouvelles polices pèsent 587 Ko ensemble. Un sous-ensemble latin rendrait 244 Ko de plus (42 %), vérifié avec `pyftsubset` hors du dépôt, axes variables et `tnum` préservés. **Non livré, et c'est la question qui reste** : le sous-ensemble latin retire tout ce qui sort de Latin-1, or l'application affiche des prénoms saisis par les familles. Un nom en cyrillique ou en vietnamien deviendrait un carré vide. À trancher par l'opérateur, et si c'est oui, avec un script en CI, pas un binaire découpé à la main |
| 12 | `0001` fait `create extension if not exists pgcrypto` sans schéma et appelle `public.digest`. Sur un projet Supabase où pgcrypto vit déjà dans le schéma `extensions`, la migration échouerait à sa première application réelle | Étape D, premier `db push` | **Corrigée en code** : `0001` crée le schéma `extensions`, y installe l'extension, et les appels de `0001` et `0004` sont qualifiés `extensions.`. Les deux formes valent des deux côtés, sur Supabase comme sur un Postgres nu, et les 73 contrôles SQL restent verts. **Reste à confirmer au premier `db push`**, qui dépend de l'étape D |
| 13 | Lecture du QR par la caméra sur l'appareil de l'enfant | Étape 4 ou plus tard | Reportée (ADR-016). Le chemin par le code fonctionne partout ; l'interface est posée pour recevoir un lecteur |
| 14 | Limitation de débit sur l'échange d'un code d'appairage | Si la durée de validité s'allonge | Non traitée, arithmétique consignée dans `supabase/functions/session-enfant/index.ts` : 32^6 combinaisons pour une fenêtre de dix minutes |
| 15 | Méthode de calcul des prières et lieu de référence : qui les pose | Étape 4 | **Résolue par configuration** : `prayer_settings` porte le lieu, la méthode et les ajustements à la minute, par enseignant, lisibles par ses élèves (ADR-017) |
| 16 | Un litige sur le temps effectif se tranche-t-il sur le minimum payable de l'élève, ou sur la présence mesurée en salle | Étape 5 | Ouverte. L'étape 4 pose la règle et sa trace, l'étape 5 mesurera la présence. Les deux doivent se rejoindre avant la première paie |
| 17 | La photo de profil d'un élève passe-t-elle par une compression serveur avant le stockage | Étape 4, `TUT-05` | Ouverte. L'ADR-012 et `etape-2-core-flutter.md` section 4 supposent une compression serveur qui n'existe pas encore : sans elle, le cache local borne mal sa taille |
| 18 | La messagerie est-elle un chat générique ou une conversation **contextuelle** attachée à une séance, au personnel, au support ou à la facturation, avec une politique par contexte | V1 | **Ouverte, et à trancher avant le premier écran de messagerie.** Soulevée par la note de refonte du 7 septembre : un chat générique construit puis sécurisé après coup est plus cher qu'une conversation contextuelle dès le départ. Aucun écran de messagerie n'existe en MVP-0, la question n'est donc pas encore bloquante |
| 19 | Le journal d'audit doit-il porter une **liste nommée d'événements** (`MATCH_ACCEPTED`, `SESSION_JOINED`, `REPORT_SUBMITTED`…) plutôt que des libellés libres | Étape 5, 6 | **Partiellement posée par ADR-020, pour le seul domaine présence** : les 14 états de la machine à états de présence (`etape-5-salle-coran-presence.md` §6.2) donnent une première brique fermée. La nomenclature complète (matching, séance, contenu) reste ouverte ; `ADM-04` ne pourra filtrer au-delà de la présence tant qu'elle ne l'est pas |
| 20 | Faut-il modéliser une entité **groupe, cohorte ou parcours** distincte de la séance | V1 | Ouverte, **sans dette pour l'instant** : le MVP-0 n'a pas d'entité niveau, et `session_participants` est déjà en plusieurs-à-plusieurs (ADR-004). La question se rouvrira quand les cours de groupe deviendront sérieux. Ne pas la préempter par une énumération rigide de types |
| 21 | Instrument Sans et Noto Sans Arabic s'accordent-ils en hauteur d'x et en graisse dans un texte mixte français-arabe | Lot C | **Ouverte, et elle ne se ferme pas par une mesure.** `design-tokens.md` §2.2 pose l'accord comme une intention de conception ; il se vérifie à l'œil, sur un écran, sur un échantillon mixte. La galerie `/_galerie` affiche désormais cet échantillon. Si l'accord ne tient pas, l'ajustement se fait par l'axe `wdth` ou par un décalage de taille déclaré **une seule fois** dans `app_typography.dart`, jamais écran par écran |
| 22 | L'interligne des grands corps est resserré de combien exactement | Lot C | **Tranchée par défaut au lot T, à confirmer.** `01-systeme-visuel.md` §5 demande de resserrer l'interligne des grands corps sans donner de valeur. Le lot T a posé 1,05, 1,08 et 1,10 pour les trois rôles d'affichage, contre 1,12, 1,15 et 1,18 avant, et n'a pas touché aux titres. C'est un choix, pas une mesure : il se juge sur le rendu de `ELV-02` au lot R |
| 23 | Aucun mode sombre n'existe (Bible V2 §7.3) : `AppPalette.claire()` est la seule palette, `Brightness.light` codé en dur | Lot T3 | **Fermée au lot T3** (ADR-019). `AppPalette.sombre()` ajoutée, toutes les mesures de contraste refaites indépendamment (aucune transposée depuis le clair, `design-tokens.md` §12, `test/theme/contraste_sombre_test.dart`). `AppTheme.pour(mode, brightness)` choisit la palette, `app.dart` suit `ThemeMode.system`. Non traité par ce lot : une bascule manuelle dans un écran de réglages, faute d'entrée au catalogue `08-catalogue-ecrans.md` |
| 24 | Le RTL n'est ni outillé ni testé (Bible V2 §14) : deux `EdgeInsets.only(left:)` / `Alignment.centerLeft` restent dans le code, aucun test de rendu arabe | Lot B0 pour l'outillage, lot A1 pour les tests | **Fermée au lot A1** (ADR-019). **Correction d'un constat inexact de cette ligne, ecrit au lot B0** : `test/widgets/catalogue_galerie_test.dart` testait deja le RTL et le 200 % depuis le lot C (7 septembre), sur les composants isoles de la galerie — ce n'etait donc pas « aucun test », seulement une couverture incomplete. L'ecart reel ferme par A1 : (1) `test/icons/app_icons_rtl_test.dart` prouve le miroir RTL par son comportement (`AppIcons.chevron` porte `matchTextDirection`, `AppIcons.suivant`, meme dessin, ne le porte pas), pas seulement l'absence d'exception ; (2) `test/accessibilite/rtl_echelle_texte_ecrans_test.dart` rejoue les dix-neuf ecrans reels du catalogue (pas seulement les composants isoles) en RTL et a 200 %, decouvrant au passage qu'`ELV-01` (`EleveConnexionPage`) n'avait aucun test de widget — trois faux ajoutes a `harnais.dart` pour le monter ; (3) `test/accessibilite/clavier_test.dart` prouve l'ordre de focus au clavier (Tab avance dans l'ordre visuel, `TUT-00c`), que `focusedBorder` est bien cable sur `borderStrong` (§13.2/§13.4), et qu'Echap ferme `AppBottomSheet.ouvrir` (donc `ConfirmDestructive` et toute feuille modale qui en herite) sans jamais se lire comme une confirmation. Aucun de ces trois fichiers n'a pu etre confirme par `flutter test` sur ce poste (blocage TLS, voir HANDOFF.md) : `dart analyze --fatal-infos` est la seule preuve automatique obtenue |
| 25 | L'administration a-t-elle le droit d'attribuer un élève à un enseignant sur une heure que celui-ci n'a pas posée | Lot `ADM-05` | **Tranchée par l'agent, à confirmer par l'opérateur** (ADR-021, 12 septembre 2026). Oui, avec motif obligatoire vérifié en base et journalisation portant `hors_disponibilite: true`. Raison : sans ce droit, `ADM-05` afficherait une colonne de droite vide exactement dans le cas pour lequel il existe. L'heure de la famille, elle, ne se contourne jamais, et le plafond non plus. **Comment défaire** : ADR-021, dernier paragraphe, une heure de travail, le contrôle A6 de `scenarios_adm05.sql` s'inverse |
| 26 | Un enseignant doit-il être averti quand l'administration lui attribue un élève, et surtout quand elle le fait hors de ses disponibilités | Lot `ADM-05`, étape D | **Ouverte, et sans dette immédiate** : le canal de notification n'existe pas (`device_tokens` vide, étape D ouverte), donc la question ne se pose pas encore en code. Aujourd'hui l'enseignant découvre l'élève dans `ENS-02` à la prochaine séance matérialisée. Dès qu'un canal existe, c'est la première notification à écrire |

| 27 | La consultation du journal d'audit doit-elle elle-même s'inscrire au journal | Lot `ADM-04` | **Tranchée par l'agent, à confirmer par l'opérateur** (ADR-022, décision 4, 12 septembre 2026). Non, pour l'instant. Deux raisons : `log_sensitive_access()` prend un `lock table`, donc journaliser une lecture paginée sérialiserait les lectures du journal contre toutes les écritures du produit ; et une consultation produirait autant d'entrées que de pages parcourues, noyant les événements métier sous les traces de leur propre consultation. **Ce que ça laisse ouvert** : un administrateur peut aujourd'hui lire l'intégralité du journal sans qu'il en reste trace, ce qui est exactement le genre d'angle mort qu'un audit sert à fermer. **Comment défaire** : une entrée par consultation et non par page, en conditionnant l'écriture au premier appel sans curseur. ADR-022, dernier paragraphe, une heure de travail |
| 28 | L'en-tête de colonnes de `DataCollection` est collée en haut parce que le composant porte sa propre zone défilante, ce qui oblige la page à passer `defilante: false` à `PageShell`. Est-ce la bonne répartition | Lot `ADM-04`, à revoir au prochain écran qui emploie `DataCollection` | **Ouverte, sans dette immédiate** : `ADM-04` est aujourd'hui le seul écran du produit à l'employer, donc la question ne coûte rien tant qu'elle n'a qu'un cas. Elle se tranchera au deuxième, quand on saura si un écran voudra un tableau qui défile AVEC sa page plutôt qu'à l'intérieur d'elle. Le jour où cela arrive, l'alternative est un `CustomScrollView` et un en-tête en sliver épinglé, ce qui déplace la complexité dans le composant au lieu de la poser sur la page |

| 29 | Quand faut-il basculer une part réelle du trafic sur le serveur auto-hébergé, et sur quel hébergeur | Lot N2, à trancher sur des chiffres de charge | **Ouverte, et volontairement non préemptée** (ADR-023, 12 septembre 2026). L'aiguillage est construit et testé, les deux trousseaux de secrets sont prévus, mais aucun serveur auto-hébergé n'existe encore. La bascule est une décision d'exploitation qui demande trois chiffres qu'on n'a pas : le nombre d'élèves réels, la consommation mensuelle en minutes-participant, et le coût de la bande passante sortante chez l'hébergeur retenu. **Ce qu'il ne faut surtout pas oublier le jour venu** : TURN en TCP 443. LiveKit Cloud le fournit, un VPS nu non — et c'est la première cause d'échec des migrations self-host, parce qu'elle ne se voit qu'en production, chez les élèves derrière un réseau restrictif, jamais sur le poste de développement |
| 30 | Le heartbeat applicatif de la section 28 de la spécification d'intégration n'est pas construit | Lot N4 | **Ouverte, et sans dette tant que N4 n'est pas fait.** N2 pose les deux sources serveur (émission de jeton, webhooks) qui suffisent à dériver treize des quatorze états. Le heartbeat sert un cas qu'elles ne couvrent pas : une application tuée par le système sans que LiveKit n'émette `participant_left`, laissant un participant « présent » jusqu'à l'expiration côté serveur. Le seuil `presence.fenetre_reconnexion_secondes` le masque aujourd'hui. À mesurer contre le comportement réel avant d'ajouter un mécanisme de plus |

Toute nouvelle décision prise en cours de développement s'ajoute à ce même tableau, jamais dans un nouveau document séparé.
