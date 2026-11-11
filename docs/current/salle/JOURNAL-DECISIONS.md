# Journal des décisions de la salle

Tenu par Fable (mission `docs/current/CAHIER-SALLE.md`). Chaque décision donne : ce qui est décidé,
la référence ou la mesure qui la fonde, et ce qui la ferait changer. Une décision d'argent ou une
règle de l'académie reste une **proposition** tant que le directeur ne l'a pas validée.

---

## D-001 (11/11/2026). Faut-il refaire la salle en Rust ? Non. On reste sur Flutter.

**Question du directeur (10/11)** : refaire une partie de la salle, ou toute la salle, dans un autre
langage comme Rust, pour gagner en rapidité et en performance ?

**Réponse : non, et ce serait une erreur coûteuse.** Trois faits.

1. **Le son et l'image ne sont pas traités par Flutter.** L'application est livrée sur le web. Dans
   un navigateur, capter le micro, compresser la voix, rattraper les paquets perdus, supprimer
   l'écho et afficher la vidéo sont faits par le moteur du navigateur lui-même (le même que Google
   Meet), écrit en C++ et déjà optimisé par Google et Apple. Flutter ne fait que lui donner des
   ordres. Réécrire en Rust ne toucherait donc pas un seul échantillon de voix : dans un
   navigateur, du code Rust devrait appeler exactement le même moteur.
2. **Aucun défaut trouvé ne vient de la vitesse du langage.** La voix part sans protection parce
   qu'un réglage est inversé dans une bibliothèque (V-1 du constat) ; les barres de réseau sont
   fausses parce que la valeur est écrite en dur ; l'image ne revient pas à cause d'une règle de
   comptage ; le pointeur est haché parce qu'il n'est pas lissé. Ce sont des erreurs de réglage et
   de logique. Elles existeraient à l'identique en Rust.
3. **Une réécriture répéterait la cause n° 1 de l'échec passé** (constat §1) : repartir de zéro au
   lieu de prouver ce qui existe. Trente mille lignes à refaire, des mois sans progrès visible, et
   les mêmes erreurs de réglage à la fin.

**Là où je contredis l'idée que « Flutter suffit » sans réserve.** Flutter sur le web a un vrai
coût, mesuré le 11/11 : l'application pèse 15,6 Mo (3,6 Mo compressés) plus son moteur d'affichage,
soit 5 à 6 Mo à télécharger à la première visite. Sur un réseau 3G, c'est près de deux minutes
d'attente avant le premier écran (défaut W-1). Et sur un vieux téléphone, dessiner douze vignettes
vidéo peut ramer. Ces deux points se traitent **dans Flutter** :

- charger la salle et les écrans lourds à la demande, au lieu de tout d'un bloc ;
- limiter le nombre de vidéos affichées en même temps (comme Meet et Zoom au téléphone) ;
- garder en mémoire de l'appareil ce qui est déjà téléchargé.

**Ce qui me ferait changer d'avis.** Si, après ces corrections, la mesure sur un téléphone d'entrée
de gamme montre encore une salle à moins de 30 images par seconde avec la page partagée et la voix,
la bonne alternative ne serait toujours pas Rust : ce serait d'écrire **la salle seule** avec les
outils natifs du web (TypeScript et la bibliothèque LiveKit pour le web, celle qu'utilise LiveKit
Meet), en gardant tout le reste de l'application en Flutter. Cette mesure est à faire (essai à 12
élèves, téléphone bridé) ; elle sera dans `MESURES-VOIX.md` et ce journal.

**Références** : architecture WebRTC des navigateurs (W3C WebRTC 1.0 : le navigateur possède la
capture, les codecs et le transport) ; documentation LiveKit (le SDK Rust vise les applications
natives et les serveurs, pas le navigateur) ; mesure du poids du paquet web du 11/11.

---

## D-002 (11/11/2026). On trouve les défauts sur un banc d'essai réel, pas en lisant le code

**Décidé** : toute affirmation sur la voix ou le réseau se prouve sur une vraie séance locale
(`tool/salle/`) : la vraie application, un vrai serveur LiveKit, un navigateur par participant.

- Le réseau est abîmé par un relais écrit pour ce banc (`reseau_degrade.mjs`) : le noyau de la
  machine de test n'a pas l'outil habituel (`netem`). Les pertes arrivent **par rafales** (modèle de
  Gilbert-Elliott), comme sur un vrai réseau mobile, et pas seulement paquet par paquet : un essai à
  pertes indépendantes flatte les mécanismes de protection.
- Ce que l'auditeur entend est enregistré **après** la reconstruction du son par le navigateur,
  donc tel qu'il sort du haut-parleur.
- Trois notes objectives :
  1. le **taux de mots reconnus** par un modèle de reconnaissance entraîné sur la récitation du
     Coran (Whisper affiné par Tarteel), comparé à l'original : c'est la mesure la plus proche de
     « l'élève comprend chaque mot » ;
  2. l'**intelligibilité objective** ESTOI (Jensen et Taal, 2016), de 0 à 1, avec le pire passage
     de 10 secondes ;
  3. la part de **son reconstruit** par le navigateur (échantillons « dissimulés », statistiques
     WebRTC du W3C) : c'est la mesure que l'application pourra lire en direct chez chaque élève.
- La récitation d'essai (Al-Fatiha et Al-Ikhlas, cheikh Al-Husary) n'est **pas** versée au dépôt :
  les enregistrements de preuve sont remis au directeur à part. Pour une preuve durable dans le
  dépôt, il faudra une récitation dont l'académie a les droits (celle du directeur, par exemple).

**Limite dite clairement** : un banc local n'a ni la distance réelle entre pays, ni les vrais
téléphones. Il prouve le comportement de l'application sous un réseau donné ; la preuve finale
reste celle du directeur, en production, avec de vrais élèves.

---

## D-003 (11/11/2026). Le chrono : ce qui reste, puis le dépassement ; le bip chez l'enseignant seul

**Demande du directeur (11/11, sur une capture du banc)** : le chrono est trop bavard, il ne montre
que ce qui reste ; à zéro il sonne et continue en croissant ; les minutes ajoutées sont un réglage
de la direction ; le tout animé, avec des effets visibles et modernes. « En ligne » et « En salle »
font doublon.

**Décidé** (détail et références : `docs/current/UX_REVIEW_CHRONO-ETAT.md`) :

1. Une capsule avec le temps restant seul et un anneau d'avancement. Chiffres qui roulent, capsule
   qui s'étire et « respire » sur un ressort.
2. À la fin prévue, le chrono compte le dépassement en croissant (`+03:12`). Sa borne est le
   réglage serveur qui existe déjà, `grace_after_end_minutes` (15 minutes par défaut) : c'est lui
   qui ferme aussi la porte de la salle. **Aucune valeur n'est écrite dans l'écran.**
3. Un seul mot d'état : « En salle » quand la présence est confirmée, sinon l'état de la connexion.

**Où je contredis la demande, et pourquoi :**

- **Le bip ne sonne que chez l'enseignant.** Chez l'élève, il peut tomber au milieu d'un verset ;
  et tenir l'heure est l'affaire de celui qui conduit la séance. Pour la même raison, la capsule
  de l'élève ne prend aucune teinte d'alerte (référence : conception adaptée à l'âge, Children's
  Code ; règle déjà posée par LIVE-CHRONO-01 : jamais de pression sur l'enfant).
- **Un signal est ajouté cinq minutes avant la fin.** C'est à ce moment qu'il faut conclure ; à
  zéro, il est trop tard (référence : Google Meet prévient cinq minutes avant la coupure).

**À trancher par le directeur (argent) :** le temps de dépassement est-il payé à l'enseignant ?
Aujourd'hui la paie compte par élève présent et par heure prévue (`DECISION-TARIFS-2026-10-18.md`).
Je ne change rien à cette règle ; je signale seulement qu'un dépassement visible à l'écran posera
la question. Ma proposition : le dépassement reste un geste gratuit de l'enseignant, plafonné par
le réglage, et il n'entre pas dans la paie.

**Reste à faire dans ce lot :** un écran de la direction pour régler `grace_after_end_minutes` s'il
n'existe pas ; le chrono visible au repos sur le téléphone de l'enseignant (réduit à son anneau
quand rien ne presse, déplié au toucher et dès que la fin approche).

---

## D-004 (11/11/2026). Le relevé de qualité de connexion : proposition

**Demande (cahier §6)** : la qualité réelle de connexion de chaque participant est enregistrée et
figure dans les rapports de séance, comme preuve en cas de litige ; à moi de décider quoi garder,
combien de temps et qui lit, d'après la loi, sources citées.

**Proposé** (sources et limites : `docs/current/salle/DROIT-RELEVE-QUALITE.md`) :

- **Quoi** : par séance et par participant, à intervalle régulier : heure du serveur, niveau du
  lien, pertes, gigue, part de son reconstruit, débit, coupures. Jamais d'adresse IP, de son ni
  d'image.
- **Combien de temps** : 180 jours par défaut (réglage de la direction), puis suppression ; gel
  des seules séances contestées, jusqu'à la fin du litige.
- **Qui lit** : la direction, en lecture seule, chaque lecture tracée ; l'enseignant voit en direct
  l'état de ses élèves pendant la séance, rien après.
- **Valeur de preuve** : table en ajout seul (ni modification ni suppression possibles hors purge
  planifiée), heure du serveur, et deux regards croisés : chaque appareil relève ce qu'il reçoit,
  et l'appareil de l'enseignant relève la qualité que **le serveur de visio** attribue à chaque
  élève. Une famille ne peut donc pas fabriquer seule un « mauvais réseau de l'enseignant ».
- **Jamais** : noter automatiquement un enfant ou un enseignant à partir de ce relevé.

**Pourquoi passer par le serveur plutôt que d'ouvrir le canal de données aux élèves** : aujourd'hui
un élève ne peut rien émettre vers la classe (`canPublishData = false`), et c'est une bonne règle de
sécurité. Je ne l'affaiblis pas : l'appareil de l'élève écrit son relevé par une fonction serveur
qui vérifie qu'il appartient à la séance, et l'enseignant le lit de là. Le même chemin sert à la
preuve et à l'alerte en direct (« Amina vous entend mal »).

**À valider par le directeur avant le code serveur** : les 180 jours ; la phrase d'information aux
familles et l'accord du parent à l'inscription (obligatoire au Québec pour les moins de 14 ans) ;
le recours à un juriste pour les points listés au §10 du document.

**11/11/2026, la durée : matin, 180 jours ; début d'après-midi, deux ans, sur une question du
directeur mal comprise par le pilote ; fin d'après-midi, retour à 180 jours.** Le besoin du directeur
(retrouver une séance d'il y a un an) portait sur le rapport de la séance (présence, cahier), que
cette purge ne touche pas ; pour la trace technique de connexion, la minimisation (RGPD art. 5(1)(c)
et (e)) commande la durée la plus courte qui sert le but : les 120 jours d'une contestation de
paiement par carte, plus une marge. **Pas de juriste** (directeur, 11/11) : les points de droit sont
tranchés par les textes, lus et cités (`DROIT-RELEVE-QUALITE.md` §10). Codé par le lot RESEAU-PREUVE
(D-024), avec moins de données que proposé ici (trois mots d'état et le micro, aucune mesure, **rien
pour un élève mineur**).

---

## D-005 (11/11/2026). La voix : redondance réelle, 32 kbit/s, plus de coupure dans les silences

**Décidé, sur mesures** (`docs/current/salle/MESURES-VOIX.md`) :

1. **La redondance audio (RED, RFC 2198) est réellement activée.** Le code la demandait depuis le
   25/10, mais `livekit_client` 2.12.0 inverse le réglage (`participant/local.dart`, ligne 190) :
   elle n'a jamais été active. Mesuré : sous 10 et 20 % de pertes isolées, le son reconstruit passe
   de 6 à 7 % à 0,1 à 0,2 %, et l'intelligibilité revient à son niveau sans perte.
2. **32 kbit/s au lieu de 24**, et **plus de DTX** (la coupure de l'émission pendant les silences).
   Une récitation ne doit pas être rognée à la reprise d'un mot. Coût : environ 67 kbit/s par voix
   ouverte, moins que la plus petite couche vidéo (160 kbit/s).
3. **La voix a la priorité haute** sur la vidéo pour le débit.
4. **L'image revient après un mauvais passage** (battement toutes les 5 s, défaut R-3).

**Ce que je n'affirme pas.** Cette correction ne tient pas la règle absolue du cahier (§5) sous des
pertes en rafales : des mots y sont encore perdus. Je le dis au lieu de livrer un « c'est corrigé ».
La suite : un tampon d'avance chez l'auditeur en difficulté (essai en cours), puis l'alerte en
direct (« Amina vous entend mal »).

**Contre mon premier choix.** J'avais d'abord cru que la redondance suffirait. Le premier essai
sérieux (pertes en rafales, 100 ms de latence) a montré que non. Le banc existe pour ça.

**Fragilité connue.** Le réglage repose sur une inversion dans la bibliothèque. Si une version
future la corrige, la redondance se couperait en silence. Garde : la constante `redPourLeSdk`
porte l'explication, un test la fige, et le banc journalise le débit reçu (67 kbit/s avec la
redondance, 23 sans). `pubspec.yaml` est interdit aux agents : la montée de version de la
bibliothèque revient au pilote, qui doit rejouer `tool/salle/mesure_voix.mjs` ce jour-là.

**Références** : RFC 2198 (RTP Payload for Redundant Audio Data) ; RFC 6716 (Opus) ; statistiques
WebRTC du W3C (`concealedSamples`, `totalSamplesReceived`) ; ESTOI, Jensen et Taal, IEEE/ACM
TASLP 2016.

---

## D-006 (11/11/2026). Proposition : cinq places fixes, pas une disposition de plus

**État : proposition.** Rien n'est codé. Elle sera montrée au directeur en images avant toute ligne
de code de disposition, puis prouvée sur le banc à 6 élèves.

**Pourquoi.** Les refontes ont échoué parce que chaque remarque déplaçait quelque chose (constat
§1). L'essai en séance réelle le montre encore (constat §2 bis) : un bouton posé sur une vignette,
un message de réseau dit à deux endroits, l'enseignant qui ne voit plus ses élèves dès qu'il
partage une page. Ce qu'il manque n'est pas un meilleur dessin : c'est **une règle de places** que
plus personne ne rediscute.

**La règle proposée : cinq places, les mêmes pour tous les rôles et tous les appareils.** Seule
leur taille change.

| Place | Où | Ce qu'elle contient, et rien d'autre |
| :-- | :-- | :-- |
| 1. La scène | le centre | **Une seule chose à la fois** : le support partagé s'il y en a un, sinon les personnes |
| 2. Les personnes | une rangée (téléphone : en haut ; ordinateur : sur le côté du début) | Les vignettes. Quand un support occupe la scène, **elles ne disparaissent pas** : l'élève garde l'enseignant, l'enseignant garde ses élèves (celui qui récite en premier) |
| 3. L'île de séance | en haut, au début | Le chrono, l'état en un mot, la mention. **Tous les messages** (réseau, appel, consigne) sortent sous elle, un seul à la fois, le plus urgent d'abord |
| 4. La barre d'appel | en bas, au centre | Micro, caméra, quitter ; le pointeur pour l'enseignant. Sur ordinateur et tablette, les outils de l'enseignant s'y ajoutent |
| 5. Le tiroir des supports | au bord de fin, replié, avec sa languette | L'étagère des supports (cahier §7) : « Afficher » et « Partager » |

Trois interdits qui en découlent : **rien au milieu** de la scène (ni bouton ni menu) ; **aucun
message en bas** ; **aucune deuxième place** pour une chose qui en a déjà une.

**Références.** Google Meet et Zoom : une scène et un bandeau de vignettes (« speaker view » au
téléphone, la personne qui parle en grand) ; barre d'appel en bas au centre (déjà retenue le
24/10). Material 3 : régions fixes d'un écran adaptatif (corps, volet de support). Nielsen 4
(cohérence) et 6 (reconnaître plutôt que se souvenir). Fitts : les commandes d'appel au pouce.

**Ce que ça change pour le cahier §9 (téléphone réduit).** Je suis d'accord avec la décision du
10/11 : au téléphone, seulement rejoindre, voir et entendre, micro, caméra, suivre le support,
pointeur, quitter. Les places 1 à 4 suffisent ; le tiroir (place 5) n'existe que sur tablette et
ordinateur. **Une réserve** : l'enseignant au téléphone doit quand même pouvoir tourner la page (fait,
S-1) et ouvrir un support déjà choisi pour la classe, sinon un enseignant dont l'ordinateur tombe en
panne ne peut plus faire cours. À trancher avec le directeur.

**Comment éviter une huitième refonte.**

1. Les cinq places sont écrites **une fois** dans le code (un seul fichier de composition), et
   chaque écran les remplit ; plus de disposition par rôle et par largeur.
2. Les trois dispositions mortes et leurs 35 fichiers de tests sont retirés d'abord (avec l'accord
   du directeur, règle du dépôt).
3. Chaque étape est essayée sur le banc à 6 élèves **avant** d'être proposée, captures à l'appui.
4. Une remarque du directeur change ce qu'une place contient, jamais la liste des places, sauf
   décision écrite ici.

---

## D-007 (11/11/2026). Proposition : quatre familles de messages, une seule place

**État : proposition.** Demande du directeur du 11/11 : tout message de la salle (témoin
d'enregistrement, visite d'un parent, enseignant absent, notifications) doit avoir une place
naturelle, sans gêner le cours. Texte complet : `docs/current/salle/MESSAGES-DE-LA-SALLE.md`.

- **Quatre familles** : les témoins (permanents, petits, dans l'île), les situations (une ligne
  sous l'île, tant que c'est vrai), les passages (4 à 6 secondes), les appels (jusqu'au geste,
  seuls à sonner).
- **Une seule place, en haut ; un message à la fois ; rien sur ce qu'on lit.**
- **Ce qui se tait** : les notifications du reste de l'application, les entrées et sorties chez les
  élèves, tout ce qui n'exige ni la loi, ni un geste, ni d'éviter une erreur. Ce qu'on rate va au
  journal de la séance.
- **Ce qui manque et qui trompe aujourd'hui**, à créer d'abord : « Vous parlez, mais votre micro
  est coupé » ; « Votre enseignant a coupé votre micro » ; un appel de l'enseignant qui se voit et
  qui rend compte.

**Où je décide contre l'existant** : la phrase « Visite de contrôle possible. » ne reste pas entière
toute la séance (elle prend un tiers de la pilule) ; elle se réduit à deux mots après 10 secondes.
C'est une décision du directeur du 11/10 : je la lui soumets, je ne la change pas seul.

**Références** : Material 3 (barres de message, 4 à 10 s) ; WCAG 2.2 (2.2.1, 2.3.1, 2.3.3, 1.4.1,
4.1.3) ; Apple HIG (Dynamic Island : minimal, compact, déplié) ; Meet, Zoom, Teams (témoin
d'enregistrement toujours visible, « vous parlez, micro coupé ») ; Nielsen 1, 6 et 8.

---

## D-008 (11/11/2026). Pas de micro d'élève sans l'enseignant : c'est le serveur qui tient la règle

**État : codé, pas déployé, pas prouvé en production.** Défaut SEC-1 du constat, première moitié.

**Décision du directeur (11/11/2026).** Les élèves peuvent toujours entrer dans la salle en avance
(jusqu'à 20 minutes avant). Mais tant que l'enseignant n'est pas entré, un élève ne peut ouvrir ni
son micro ni sa caméra : des enfants ne se parlent pas, micro ouvert, sans adulte.

**La règle absolue de la salle passe avant** : l'élève et l'enseignant s'entendent. Un élève resté
muet devant son enseignant parce qu'un message s'est perdu serait pire que le défaut. Chaque choix
ci-dessous en découle.

**Ce que fait le serveur** (aucune migration, aucune écriture nouvelle en base) :

1. **Au jeton** (`create-room-token`). Pour un élève qui aurait le droit de publier, le serveur
   demande à LiveKit qui est dans la salle. Si l'enseignant de la séance n'y est pas (rôle `teacher`
   du jeton : l'attitré ou le remplaçant désigné, posé par la base et signé par le serveur), le
   jeton est signé **sans droit de publier**. Les droits que l'élève retrouvera voyagent dans les
   métadonnées signées du jeton. La réponse dit `publication_differee: true`.
2. **À chaque entrée dans la salle** (`livekit-webhook`, `participant_joined`). Si l'enseignant est
   dans la salle, le serveur rend aussitôt leur droit à tous les élèves différés (API serveur de
   LiveKit). À **chaque** entrée, pas seulement celle de l'enseignant : un élève qui a pris son jeton
   juste avant l'enseignant et entre juste après lui est rétabli par sa propre entrée. Le serveur lit
   l'état de la salle, jamais l'ordre des messages : un webhook en double ou en retard ne change
   rien. Un échec ici ne touche pas l'enregistrement de la présence.
3. **Le filet** (`create-room-token`, `action: retablir_publication`). L'application qui voit
   l'enseignant dans la salle alors que son droit est encore fermé le redemande au serveur : après
   2 secondes (le temps du webhook), puis 4, 8, puis toutes les 15 secondes, sans jamais abandonner.
   **Le client ne décide rien** : le serveur revérifie par la base que l'appelant a droit à cette
   séance (la même fonction que pour un jeton) et relit chez LiveKit que l'enseignant est bien là.
4. **Dans le doute, la classe parle.** Si LiveKit ne répond pas en 3 secondes au moment du jeton, le
   jeton part avec ses droits ordinaires (et le journal du serveur le dit). La règle n'est alors pas
   tenue pour cet élève, comme avant ce lot ; mais une panne de l'API de LiveKit ne rend jamais une
   classe muette.

**Ce que fait l'application.** Elle lit ce que LiveKit accorde (événement de changement de
permissions) et met à jour les capacités que lisent les écrans. À la place du bouton du micro, que
le serveur refuserait, une phrase : « Votre micro s'ouvrira quand votre enseignant sera là. »
(« Ton micro attend ton enseignant. » en Interface guidée). Quand le droit arrive, le bouton
apparaît ; **le micro reste fermé** tant que l'élève ne l'ouvre pas lui-même (rien ne s'ouvre seul,
règle inchangée).

**Décidé ici, à confirmer par le directeur.**

- **Les élèves adultes attendent aussi.** La décision parle des enfants ; appliquer la règle à tous
  les élèves est plus simple et plus sûr. Si le directeur veut l'exception, c'est une ligne côté
  serveur, mais il faut alors que la base dise au serveur que la classe est une classe d'adultes.
- **Seul l'enseignant de la séance ouvre les micros.** L'administration entrée en visible ne les
  ouvre pas.
- **La place de la phrase** : au-dessus des commandes, là où le bouton manque. Si la proposition
  D-007 est validée (tous les messages en haut), elle y montera.

**Ce qui reste.**

- **Après le départ de l'enseignant : rien n'est retiré.** Volontaire pendant la séance (une coupure
  de réseau de l'enseignant ne doit pas rendre la classe muette). Après la fin prévue, il faudrait
  retirer le droit, mais pas tel quel : quand l'enseignant se reconnecte, LiveKit annonce son départ
  puis son retour, et retirer au premier message couperait les micros de toute la classe à chaque
  reconnexion. Il faut un délai de grâce hors du webhook (LiveKit livre ses webhooks un par un :
  attendre dedans retarderait le retour). Non codé. La seconde moitié de SEC-1 reste ouverte, avec
  la fermeture de la salle par le serveur.
- **La barre « Séance toujours en direct »** lit l'accès confié à l'entrée : si le droit arrive
  pendant que l'élève est sur un autre écran, la barre ne montre le micro qu'à son retour dans la
  salle. Le moteur, lui, est à jour.
- **Une application pas encore mise à jour** garde son bouton de micro : avant l'enseignant, l'appui
  échoue (le serveur refuse) ; après, il marche. La règle tient, l'explication manque.
- **Journal** : chaque appel du filet écrit une ligne « jeton émis » alors qu'aucun jeton n'est
  signé (il réutilise la fonction d'autorisation existante). Une fonction dédiée demanderait une
  migration.
- **Essais** : les deux fonctions Edge sur la pile locale (`node tool/salle/micro_avant_enseignant.mjs`),
  la vraie application dans un navigateur, puis la preuve du directeur en production. Les tests
  Deno de `supabase/functions/_shared/` ne sont pas lancés par la CI (elle ne lance que `r2/` et
  `creer-profil-enfant/`).
- **Arabe** : les trois phrases sont à relire par un locuteur natif.

## D-009 (11/11/2026). L'écran ne coupe plus la séance (lot ECRAN-EVEILLE)

**Demande du directeur** : l'écran qui s'éteint ne doit couper ni le réseau, ni la voix, ni le micro ;
au retour, on ne doit pas attendre.

**Ce qui a été trouvé.** Rien dans l'application ne demandait à l'écran de rester allumé. Quand la
connexion tombait pendant la veille, l'application abandonnait après environ 45 secondes, et
« Réessayer » ouvrait une salle neuve, donc micro et caméra fermés. Détail :
`docs/current/salle/ECRAN-ET-VEILLE.md`.

**Ce qui est codé.** L'écran est tenu allumé pendant toute la séance (salle réduite comprise) ; si la
connexion tombe, l'appel reprend sans geste ; le micro et la caméra retrouvent l'état que la personne
leur avait donné, jamais plus.

**Mesure sur le banc** (`tool/salle/veille.mjs --coupe`, élève au téléphone, page gelée et réseau
coupé 75 secondes, journaux dans `docs/current/captures/E2E/salle-banc/veille-*`) :

| | Avant | Après |
| :--- | :--- | :--- |
| Demande de garder l'écran allumé | aucune | faite (le navigateur sans écran du banc la refuse : à prouver sur un vrai téléphone) |
| Voix de l'enseignant au réveil | perdue, bouton « Réessayer » | revenue seule en 3,7 s |
| Micro de l'élève au réveil | fermé, salle à rouvrir | ouvert et qui émet, seul, en 3,7 s |

**Limites dites.** Le banc gèle une page ; ce n'est pas un vrai téléphone. Le web ne peut pas
empêcher une personne d'éteindre l'écran elle-même, ni un iPhone verrouillé de suspendre la page :
seule une application installée du magasin le garantirait (décision à prendre plus tard). Le délai
avant le message « connexion perdue » passe d'environ 45 s à environ 1 min 15.

## D-010 (11/11/2026). Sortir de l'écran de la salle sans couper (lot SORTIE-SALLE)

Deux gestes nommés, jamais confondus : **« Réduire la salle »** (la séance continue, on entend
toujours la classe, on revient d'un appui) et **« Quitter la séance »**. La question de sortie dit la
conséquence avant le choix (« vos élèves restent dans la salle sans vous ») et propose de réduire
d'abord. Le geste Retour du téléphone réduit la salle au lieu de fermer l'appel. Fermer ou recharger
l'onglet pendant une séance demande confirmation au navigateur. Détail, tableau avant/après et six
questions ouvertes : `docs/current/salle/SORTIES-DE-LA-SALLE.md`.

Reste : au téléphone de l'enseignant, « Réduire » n'a pas de bouton visible (il passe par la question
de Quitter et par le geste Retour) ; l'Interface guidée garde la question simple.

## D-011 (11/11/2026). La pilule devient une île qui se replie (lot ILE-SALLE)

**Question du directeur** : la phrase écrite sur la pilule reste-t-elle ouverte, ou se cache-t-elle
pour ne laisser que le chrono et le cercle ? Elle restait ouverte et recouvrait le texte du Coran au
téléphone (défaut C6-3).

**Règle codée** (elle applique la proposition D-007, approuvée par le directeur le 11/11) :

- au repos, l'île ne montre que le cercle qui se remplit, le temps restant et un point d'état ;
- une phrase qui arrive déplie l'île, qui se replie seule après **6 secondes**
  (`AppMouvement.ilePassage`) ; la mention de contrôle reste dépliée **10 secondes** à l'entrée
  (`AppMouvement.ileMention`), puis garde son point neutre permanent ;
- un appui sur l'île la redéplie ; le lecteur d'écran lit toujours tout ;
- ce qui empêche d'entendre (lien perdu, reconnexion) reste déplié tant que ça dure ;
- hors de la salle (salle réduite), l'île a deux formes, compacte et dépliée, sur le modèle de la
  Dynamic Island ;
- le mouvement est l'effet liquide de la barre de navigation, réadapté : la capsule s'étire puis se
  reforme, sans rebond, et seulement quand quelque chose change (jamais pendant qu'un élève récite
  sans raison). `docs/current/UX_REVIEW_ILE-SALLE.md`.

Reste : hors de la salle, le nom de la Classe manque chez l'élève ; l'île n'est pas atteinte par la
touche Tab depuis la page ; « plus de son » n'est pas détecté comme tel.

## D-012 (11/11/2026). L'attente a un visage (lot ATTENTE-SALLE)

**Demande du directeur** : l'écran nu avant l'arrivée des autres est laid ; y mettre le logo des pages
de chargement, sans passer au fond violet, avec une animation qui aide à attendre.

**Contradiction dite** : le 25/10, le directeur avait interdit que la lumière de la page de connexion
respire sans fin (« jamais en boucle »). Ici il demande une animation qui dure toute l'attente. La
demande la plus récente prévaut, **pour l'attente de la salle seulement** : le symbole de la marque au
centre d'ondes très lentes (une onde met huit secondes à s'éloigner), sans clignotement, immobiles si
la personne a demandé de réduire les animations. La page de connexion ne change pas.
Composant : `SceneAttente` (core). Captures réelles : `docs/current/captures/E2E/salle-banc/attente/`.

## D-013 (11/11/2026). Au téléphone, plus de bouton de zoom sur la page

**Demande du directeur** : « ça ne sert à rien car on peut pincer, en plus ça bloque la vue ».
Vérifié dans le code : le pincement et le double toucher existent. Le bouton flottant est retiré sous
600 points ; le tiroir des Commandes de l'enseignant garde plus et moins. L'ordinateur garde ses
boutons (pas de pincement à la souris).

## D-014 (11/11/2026). Le pointeur, « Faire réciter », « Appeler », la vidéo en double (lot GESTES-POINTEUR)

**État, vérité d'abord** : tout est codé sur une branche, rien n'est fusionné ni déployé, rien n'est
prouvé en production. La récitation est prouvée sur la pile locale (vraies fonctions, vrai LiveKit) ;
le pointeur et l'appel ne le sont que par des tests.

**Demande du directeur** (cahier §8) : un pointeur quasi instantané, très visible, avec un sillage ;
une vraie stratégie pour « Faire réciter », ou sa suppression ; décider du sort de « Faire sonner » ;
la vidéo de l'enseignant ne doit plus apparaître deux fois.

### Le pointeur

Cause du retard, lue dans le code : une position toutes les 50 ms au plus, et toute position tombée
dans cet intervalle était jetée, **la dernière comprise**. Le point de l'élève s'arrêtait donc avant
celui de l'enseignant. Rien ne lissait le mouvement. Le lever partait sans garantie : perdu, le
pointeur restait figé. Le canal, lui, était déjà le bon (sans retransmission).

Décidé et codé :
- 30 positions par seconde au plus, la dernière d'un geste toujours envoyée, aucune file ;
- tant que le point reste posé, sa position est redite quatre fois par seconde (le canal ne
  retransmet rien) ; le lever part sur les deux canaux ; chez l'élève, sans nouvelle pendant une
  seconde, le pointeur s'efface seul ;
- un point de 32 points (anneau clair, cœur du violet de marque) et un sillage de 350 ms ; en
  « Réduire les animations », le point seul ;
- le centre du point est sur la position montrée (l'ancien pointeur reçu dérivait d'un demi-diamètre
  vers les bords) ;
- à la souris, le pointeur suit le curseur sans appuyer et s'efface après deux secondes d'immobilité.
  **Ajout du lot, à confirmer par le directeur.**
- Au téléphone : rien à changer, l'enseignant arme le pointeur dans l'onglet Outils et l'élève le
  voit sur la page (même surface). Lu dans le code, pas rejoué au banc.
- L'élève ne peut toujours pas envoyer de pointeur (droits du jeton inchangés).

### « Faire réciter »

**En une phrase** : pendant qu'un élève récite, le serveur ferme le micro de ses camarades, pour
qu'on n'entende que lui.

**Depuis le 11/11 (décision du directeur, lot RECITATION-MICRO-SEUL, D-022) : micro seul.** La
caméra des camarades reste. Ce qui suit disait « le droit de publier » d'un bloc (micro et caméra) :
lire « le micro » ; le détail et les preuves sont dans D-022.

- « Faire réciter Yasmine » : le serveur retire aux autres élèves le droit de publier (LiveKit
  dépublie leur micro et refuse de le rouvrir). Ce n'est jamais seulement à l'écran.
- Le micro de Yasmine n'est jamais ouvert de force. Elle lit « C'est à vous de réciter. Votre
  enseignant vous demande de réciter : ouvrez votre micro. », avec un son court.
- Ses camarades lisent « Yasmine récite. Votre micro est fermé le temps de sa récitation. Il vous
  sera rendu ensuite. », et la même raison à la place du bouton du micro.
- « Terminer la récitation » rend son droit à chacun, micros fermés.
- **La récitation ne tient que tant que l'enseignant et le récitant sont dans la salle.** Dès que
  l'un des deux n'y est plus, elle se termine seule et les droits reviennent. Trois chemins le
  garantissent : le webhook de sortie de LiveKit, la demande que l'application de chaque élève refait
  seule (au plus toutes les quinze secondes), et l'application de l'enseignant.
- Seul l'enseignant effectif de la séance peut le faire : vérifié en base, comme les autres gestes.
- L'application de l'enseignant n'annonce la récitation à la classe qu'après la réponse du serveur.
- Où vit l'état : dans les métadonnées de la salle LiveKit, écrites par le serveur seul. **Aucune
  migration.**

Preuve : `node tool/salle/gestes.mjs` sur la pile locale, 28 contrôles sur 28
(`docs/current/captures/E2E/gestes-pointeur/journal-pile.txt`). `micro_avant_enseignant.mjs` rejoué
ensuite : 15 sur 15, la règle D-008 tient toujours.

### « Appeler »

Il reste, renommé « Appeler » (« Appeler Ilyes » dans le menu d'un cadre). À quoi il sert : attirer
l'attention d'un élève présent qui ne répond pas. Qui : celui qui conduit la séance. Sur qui : un
élève dans la salle ; pour un absent, le bouton n'est pas rendu (les notifications et le remplacement
existent, pas de second circuit). Une fois toutes les quelques secondes par élève (limite existante,
tenue par l'application). Chez l'élève : deux notes et « Votre enseignant vous appelle », en tête de la
salle, sur tous les écrans. Chez l'enseignant : « Appel envoyé à Ilyes » ou « L'appel n'est pas parti
vers Ilyes », avec la raison.

### La vidéo en double

Règle : une personne, un cadre. Chez l'enseignant, sur ordinateur comme au téléphone, la scène
répétait son image dans un cadre flottant alors qu'elle est déjà sa vignette : le cadre flottant est
retiré. Cas relevés :

| Cas | État |
| :-- | :-- |
| Enseignant, ordinateur : vignette en tête du panneau des élèves et cadre flottant dans la scène | corrigé |
| Enseignant, téléphone : capsule en haut et cadre flottant en bas | corrigé |
| Élève, téléphone : capsule de l'enseignant en haut et enseignant en grand dans la scène | **ouvert** (`telephone_plein_ecran.dart`, zone d'un autre lot ; lu, pas vérifié à l'écran) |
| Élève, scène au premier plan pendant qu'un camarade récite : le récitant en vignette et dans la scène | **ouvert**, même fichier |

### Ce qui reste

- **Journal d'accès** : la récitation passe par la porte existante (`autoriser_geste_salle`), qui ne
  connaît que trois gestes ; elle y est notée `salle_geste_couper_micro`, avec le récitant pour cible.
  Lui donner son nom demande une migration additive. Non écrite.
- **« Appeler » n'a pas de limite au serveur** : la limite est tenue par l'application de
  l'enseignant. Et le retour dit que l'appel est parti, pas que l'élève l'a vu.
- **Pas essayé** : la récitation dans la vraie application sur deux navigateurs ; le webhook coupé
  (`SANS_WEBHOOK=1 node tool/salle/gestes.mjs`) ; le retard réel du pointeur entre deux appareils ; le
  son de l'appel dans un vrai navigateur ; la production.
- **Mode focus de l'ordinateur** : panneaux retirés, l'enseignant ne voit plus sa propre image.
- **Une application pas encore mise à jour** chez un camarade garde son bouton de micro pendant la
  récitation : l'appui échoue (le serveur refuse), sans explication.
- **Arabe** : les phrases nouvelles sont à relire par un locuteur natif.
- Deux tests de `test/features/salle_ordinateur_test.dart` échouent déjà sur le commit de base
  (`4e6e63f48`), sans rapport avec ce lot (barre du bas : 10 tuiles au lieu de 9).

### Ce que le directeur doit trancher

1. **Quand l'enseignant perd sa connexion pendant une récitation**, les camarades retrouvent leur
   micro alors qu'aucun adulte n'est dans la salle. C'est la consigne « jamais une classe bloquée
   muette » ; elle va contre l'esprit de D-008 (pas de micro d'élève sans l'enseignant). Aujourd'hui,
   hors récitation, rien n'est retiré non plus quand l'enseignant sort (SEC-1, moitié ouverte). À
   décider ensemble.
2. **La caméra des camarades** est fermée avec leur micro pendant la récitation (LiveKit retire le
   droit de publier d'un bloc ; garder la caméra demande un réglage par source, faisable). Voulu, ou
   la caméra doit-elle rester ? **Tranché le 11/11 : la caméra reste, le micro seul est fermé
   (D-022).**
3. **Le pointeur qui suit la souris sans appuyer** : gardé ou retiré ?
4. **« Appeler »** : le mot convient-il, et faut-il une limite tenue par le serveur ?

## D-015 (11/11/2026). La barre d'outils du bas sur ordinateur (lot BARRE-ORDINATEUR)

**Demande du directeur** : harmoniser la barre du bas, simplifier, atteindre les outils principaux
en moins de clics, pour les enseignants les moins à l'aise avec la technique.

**Ce qui a été trouvé** (`docs/current/UX_REVIEW_BARRE-ORDINATEUR.md`) : « Plus » n'ouvrait que des
doublons ; « Tableau » était violet quand il était fermé, donc lu « allumé » ; « Écrire »
disparaissait sans page et faisait glisser ses voisins ; la palette d'écriture prenait de la hauteur
à la page ; le même lilas disait à la fois « panneau ouvert » et « outil en main ».

**Ce qui est codé.** Cinq groupes séparés d'un filet, toujours à la même place : ma voix et mon image
(Micro, Caméra), ma classe (Élèves), sur la page (Pointeur, Écrire), le support (Bibliothèque,
Tableau), sortir (Réduire, Quitter). Plus de « Plus ». Un panneau ouvert se lit par un trait sous sa
tuile, un outil en main par l'aplat ; la palette d'écriture se pose à côté de la page, sans la
réduire ; touches M, V, P, E, T, B, F et Échap, dites dans l'infobulle.

**Dit franchement** : le gain en nombre de clics est faible (les gestes courants étaient déjà à un
ou deux clics) ; le gain est dans la lisibilité et la stabilité. « Les outils ne marchent pas » n'est
pas traité par ce lot (le pointeur l'est par D-014 ; le tracé reste à vérifier chez l'élève).
`lib/CLAUDE.md` décrit encore la barre du 26/10 : à mettre à jour sur décision du directeur.

## D-016 (11/11/2026). L'étagère des supports et leurs couvertures (lot SUPPORTS-ETAGERE)

**Demandes du directeur** : travailler les vignettes des supports ; couvertures aux styles et aux
couleurs de l'académie ; pour le Coran, une couverture standard, en arabe, familière à tous.

**Ce qui est codé.** Une étagère de livres dans le panneau des supports (ordinateur) et dans l'onglet
Support (téléphone de l'enseignant). Toucher un livre ouvre sa fiche : « Partager » (la classe le
voit maintenant, seul bouton plein) ou « Afficher » (je le regarde seul). Les supports de l'académie
forment une même collection aux violets de la marque, avec l'ornement. Le Coran a sa couverture à
part : « القرآن الكريم » et « مصحف المدينة », toujours en arabe.

**Sources et limites.** Le Complexe du Roi Fahd ne publie aucune couverture réutilisable (site lu le
11/11 : droits réservés, aucune licence d'image) : rien n'est copié, la couverture est dessinée. Le
titre est composé en KFGQPC Uthman Taha Naskh, dont la licence du dépôt autorise l'usage gratuit.
**Couleurs nouvelles, à valider par le directeur** : bleu nuit et or pour la seule couverture du
Coran (le vert et or est écarté, la marque le classe comme une identité périmée de l'académie).

**Ce qui n'est pas fait.** L'alphabet ne peut toujours pas se partager : le partage en direct reste
codé pour le Coran (relevé dans `docs/current/UX_REVIEW_SUPPORTS-ETAGERE.md` §1 ; un lot à part).
Les supports « à valider » n'existent que dans la galerie et les tests ; leur liste proposée est dans
`docs/current/salle/SUPPORTS-A-VALIDER.md`, sans aucun contenu inventé. La languette au bord de
l'écran n'est pas posée : le titre du panneau porte la couleur de la marque ; une vraie languette
devrait remplacer la tuile de la barre, pas s'y ajouter (au directeur de trancher).

## D-017 (11/11/2026). Le réseau de chaque élève, et « on vous entend peut-être mal » (lot RESEAU-ELEVES)

**Demande du directeur** (cahier §5 et §6) : l'élève comprend chaque mot de l'enseignant, et
l'inverse ; personne n'entend une voix déformée sans le savoir ; l'indicateur de réseau lit l'état
réel de chaque participant.

**Ce qui est codé.** La note de lien que LiveKit donne pour chaque participant (déjà lue par la
salle, jamais montrée pour les élèves) passe par un filtre (`lib/core/video/seuils_reseau.dart`) :
une qualité n'est montrée qu'après 3 s tenues ; une phrase n'arrive qu'après 8 s de mauvais lien.
L'enseignant voit dans la carte de chaque élève les barres de `SignalVideo` (aucune sans mesure) et,
quand le lien dure mauvais, « On entend peut-être mal Yasmine » (micro ouvert) ou « Yasmine entend
peut-être mal » (micro fermé). Chacun, micro ouvert et lien mauvais depuis 8 s, lit dans l'île
« Votre connexion est faible : on vous entend peut-être mal. Rapprochez-vous du Wi-Fi ou fermez les
autres applications. », puis un signe court tant que ça dure. Une situation de réseau n'est dite
qu'une fois, dans l'île (défaut C6-4) : plus de bandeau ni de pastille « Reconnexion » en double.

**Le seuil** est celui du repli audio, `mediocre` ou `perdue` : `MESURES-VOIX.md` montre une voix
intacte sous la 3G et les pertes isolées, et des mots perdus sous les pertes en rafales, qui sont le
moment où LiveKit passe la note à « médiocre ».

**Dit franchement.** La note de LiveKit est un indice, pas une mesure de ce qu'on entend : les
phrases disent « peut-être ». « Coupez votre caméra » n'est pas proposé : le repli audio la coupe
déjà. Rien n'est conservé (le relevé comme preuve, défaut R-2, attend la décision du directeur sur
la durée de conservation). Non prouvé en production. Revue : `docs/current/UX_REVIEW_RESEAU-ELEVES.md`.

## D-018 (11/11/2026). Après le départ de l'enseignant, et à la fin : le serveur ferme les micros, puis la salle (lot FERMETURE-SALLE)

**État : codé, pas déployé, pas prouvé en production.** Défaut SEC-1 du constat, seconde moitié
(situations F1, F2, F11). Aucune migration.

**Décision du directeur (11/11/2026).** Des enfants ne se parlent pas, micro ouvert, sans adulte.
**La règle absolue de la salle passe avant** : pendant le cours, l'élève et l'enseignant
s'entendent ; on ne coupe jamais une classe par erreur. Chaque choix ci-dessous en découle.

### La règle retenue

1. **L'enseignant sort : rien n'est retiré sur le moment.** Le serveur note seulement l'instant,
   dans la salle LiveKit (métadonnées de la salle, qu'aucun participant ne peut écrire ; même
   endroit que la récitation de D-014, aucune table).
2. **Deux minutes plus tard, s'il n'est pas revenu**, le serveur retire aux élèves le droit de
   publier (micro et caméra). LiveKit dépublie lui-même leurs pistes et refuse toute nouvelle
   piste. La salle reste ouverte : ils attendent, ils ne se parlent pas.
3. **Il revient** : la marque est levée et le droit est rendu par le mécanisme de D-008 (comme à
   une entrée). Un micro que l'élève avait fermé reste fermé. Un micro qu'il avait ouvert lui-même
   avant le départ de l'enseignant est rouvert par l'application au retour du droit, comme après
   une coupure de réseau (moteur de D-009 : lu dans le code, **non essayé** dans la vraie
   application ; question 5 plus bas).
4. **La séance est finie et l'enseignant n'est plus là : la salle est fermée pour tous**
   (`deleteRoom`). « Finie » veut dire : la fin prévue et le dépassement autorisé
   (`grace_after_end_minutes`, 15 minutes, le réglage qui ferme déjà la porte d'entrée) sont
   passés, ou la base a clos la séance (clôture automatique à la fin + 30 minutes, annulation,
   séance non tenue). Après le dépassement, l'enseignant doit être absent depuis deux minutes (une
   coupure de son réseau ne ferme pas la salle à la seconde) ; séance close en base, la salle
   ferme sans attendre.
5. **Un cours qui se tient encore avec son enseignant n'est jamais coupé**, même après le
   dépassement, même après la clôture en base. D-003 borne le chrono et ferme la porte d'entrée ;
   aucune règle écrite ne dit de couper un cours en train de se tenir. **Question posée au
   directeur** (plus bas) ; l'interrupteur est une constante
   (`FERMER_A_LA_CLOTURE_MEME_AVEC_ENSEIGNANT`, à faux).
6. **Dans le doute, rien n'est fermé** : séance illisible ou retirée en base, LiveKit muet. Les
   entretiens de recrutement et les réunions passent par les mêmes salles sans aucun enseignant :
   la règle ne les touche pas (`session_type`).

**Pourquoi deux minutes.** Après une coupure, l'application de l'enseignant reprend seule l'appel
pendant environ 75 secondes (les essais du SDK, puis ceux du moteur : D-009). Fermer avant
couperait les micros d'une classe dont l'enseignant est en train de revenir, et chaque élève
devrait rouvrir le sien. Au-delà, c'est du temps où des enfants peuvent se parler sans adulte. La
valeur est une constante nommée du serveur (`DELAI_SANS_ENSEIGNANT_S`).

### Qui applique l'échéance (le délai ne vit pas dans le webhook)

LiveKit livre ses webhooks un par un : attendre dedans retarderait le retour de l'enseignant.
L'échéance est une date écrite dans la salle ; elle est appliquée par le prochain passage qui lit
la salle. La décision lit toujours l'état chez LiveKit et la séance en base, jamais l'ordre des
messages ni la parole d'un client. Trois voies, toutes sans migration :

- **La tâche planifiée `observation-coupure`** (chaque minute, déjà installée pour les visites des
  tuteurs) fait aussi le passage sur toutes les salles ouvertes. C'est la voie qui ne dépend de la
  bonne foi d'aucun client. Vérifié en lecture seule en production le 11/11 à 09:47 UTC : la tâche
  est planifiée chaque minute, active, ses deux secrets sont posés, son dernier passage est
  « succeeded » (cela dit que l'appel est parti, pas ce que la fonction a répondu : non vérifié).
- **L'application d'un participant** (`create-room-token`, action `verifier_salle`) : cinq
  secondes après avoir vu partir l'enseignant, puis à l'échéance que le serveur annonce ; et à la
  fin du dépassement. Le serveur applique à **toute** la salle : un seul client honnête suffit, et
  un client modifié ne garde pas son micro (le droit est retiré chez LiveKit). Aucun client ne
  peut avancer ni retarder l'échéance.
- **Le webhook** (entrées et sorties) : pose la marque au départ de l'enseignant (le délai repart
  alors de zéro, même si une vieille marque traînait), la lève à son retour, et ferme la salle
  quand il sort d'une séance déjà close.

Au pire (webhook perdu et aucun client honnête) : la marque est posée par la tâche planifiée dans
la minute, les micros fermés trois à quatre minutes après le départ. Au mieux : deux minutes.

### Ce que lit chacun

- L'élève dont le micro vient d'être fermé, en tête de la salle (annonce, jamais sur la page) :
  « Votre enseignant n'est plus dans la salle. Votre micro est fermé jusqu'à son retour. »
  (tutoiement en Interface guidée). La phrase de D-008 reste ensuite à la place du bouton.
- Salle fermée : l'élève arrive sur « Séance terminée » (« La séance est terminée. » en Interface
  guidée) avec son retour à l'accueil ; l'enseignant sur l'écran de fin puis le cahier de
  transmission ; le tuteur, le contrôle et la direction lisent « La séance est terminée. La salle
  est fermée. Vous pouvez revenir à l'accueil. ». Plus de « La connexion au cours est perdue » ni
  de « Votre enseignant vous a fait sortir du cours » pour ce cas : la fermeture par le serveur a
  son propre motif (salle supprimée), distinct de l'exclusion.

### Sources LiveKit

- `DeleteRoom` : « forcibly disconnect all participants currently in the room » (documentation de
  l'API RoomService, lue le 11/11). Vérifié sur la pile locale : chaque participant est déconnecté
  avec la raison `ROOM_DELETED`. Côté Flutter, la raison s'appelle `roomDeleted` (lue dans le SDK
  du dépôt) ; **non essayé** dans la vraie application.
- `RemoveParticipant` : le participant « can still re-join » (commentaire du SDK serveur). Non
  employé ici : c'est lui qui fait dire « votre enseignant vous a fait sortir ».
- Webhooks : `participant_left` part « when a participant leaves a room and all cleanup processes
  are complete » (documentation). **Non vérifié** : le temps que met LiveKit à annoncer le départ
  d'un enseignant dont le réseau tombe (sur le banc, un départ voulu est annoncé en moins de trois
  secondes).
- `departure_timeout`, `empty_timeout` : la fermeture d'une salle vide par LiveKit lui-même
  (définitions lues dans le SDK serveur). **Non vérifié** : leurs valeurs en production. La règle
  n'en dépend pas : une salle vide ne met personne en danger.
- Une salle supprimée renaît si quelqu'un y entre avec un jeton encore valable (LiveKit crée la
  salle à l'entrée). L'application ne le fait pas (elle ne reprend jamais seule après une salle
  supprimée) ; un client modifié le pourrait jusqu'à l'expiration de son jeton, et la base n'en
  signe plus. Le passage suivant referme.

### Preuves

- Décisions en fonctions pures : 29 tests Deno (`_shared/fermeture_salle_test.ts`).
- Application : 16 tests Dart (`test/core/video/fermeture_salle_test.dart`), 5 tests d'écran
  (`test/features/salle_test.dart`).
- Pile locale, vraies fonctions Edge et vrai LiveKit : `node tool/salle/fermeture.mjs`, 32
  vérifications sur 32 (départ court sans effet ; délai ; fermeture à la demande d'un seul élève ;
  micro dépublié et refusé ; retour de l'enseignant ; passage planifié sans aucun client ; salle
  fermée à la fin ; cours qui déborde non coupé). `micro_avant_enseignant.mjs` et `gestes.mjs`
  rejoués ensuite.

### Ce qui reste

- **La vraie application dans un navigateur, puis la preuve du directeur en production.**
- La porte HTTP de `observation-coupure` n'est pas essayée sur la pile (elle n'y a pas son
  secret) ; son code l'est.
- L'écran de fin de l'enseignant après une salle fermée passe par le même code que FN-024, sans
  test d'écran à lui. La barre « Séance toujours en direct » après une salle fermée : non regardée.
- Le contrôleur lit l'impasse générale, pas son compte rendu.
- **Autre confusion, non corrigée ici** : un tuteur coupé à la fin de son quota d'observation lit
  toujours « Votre enseignant vous a fait sortir du cours » (la coupure emploie
  `removeParticipant`, comme l'exclusion). À traiter avec les refus d'entrée.
- Journal : la fermeture d'une salle n'écrit que dans le journal des fonctions, pas dans
  `audit_logs` ; chaque `verifier_salle` d'un participant dont la porte est ouverte écrit une ligne
  « jeton émis » (même dette que le filet de D-008). Une migration additive donnerait une fonction
  dédiée et une ligne `salle_fermee`.
- Deux écritures simultanées dans les métadonnées de la salle (récitation et marque) peuvent se
  marcher dessus : la marque perdue repousse l'échéance d'un passage, jamais l'inverse.
- Une application pas encore mise à jour : la règle tient (micro fermé, salle fermée par le
  serveur), l'explication manque (elle lit « connexion perdue », puis « Séance terminée » par
  FN-024).
- Les tests Deno de `_shared/` ne sont pas lancés par la CI. Arabe à relire par un locuteur natif.
- Captures : `docs/current/captures/E2E/fermeture-salle/` (captures de test ; le décor de
  démonstration montre encore l'enseignant, et en arabe l'annonce, plus courte, laisse dépasser le
  haut de la salle : composant existant).

### Ce que le directeur doit trancher

1. **Un cours qui déborde, enseignant présent : le coupe-t-on, et quand ?** Aujourd'hui : jamais.
   Recommandation : oui, à la clôture en base (fin + 30 minutes), pour tous, avec un avertissement
   à l'enseignant cinq minutes avant. Après ce moment, la base ne signe plus aucun jeton : un
   enseignant qui perd son réseau ne peut plus revenir. C'est une ligne côté serveur.
2. **Deux minutes de grâce** : confirmer. Faut-il un délai plus court (30 secondes) quand
   l'enseignant a touché « Quitter » ? La base le sait (`quitter_salle`). Recommandation : garder
   deux minutes partout tant que la vraie application n'a pas été essayée, puis raccourcir le seul
   départ voulu.
3. **Après la fermeture des micros, les élèves restent-ils dans la salle** (l'enseignant peut
   revenir) ou sont-ils renvoyés à l'accueil ? Aujourd'hui : ils restent jusqu'à la fin du
   dépassement. Recommandation : ils restent.
4. Comme pour D-008 : la règle vaut aussi pour les élèves adultes, et la direction entrée en
   visible ne compte pas comme l'enseignant. À confirmer.
5. **Au retour de l'enseignant, le micro qu'un élève avait ouvert se rouvre-t-il seul ?** C'est ce
   que fait le moteur aujourd'hui (il rend ce que la personne avait ouvert, D-009). Pour : la
   classe retrouve son enseignant sans que personne ait rien à toucher. Contre : D-008 dit que
   rien ne s'ouvre seul. Recommandation : le garder (l'élève l'avait ouvert, devant son
   enseignant), mais le vérifier d'abord dans la vraie application.

## DÉCISIONS DU DIRECTEUR du 11/11 (fin de matinée) : « il faut partir avec tes recommandations, sauf pour la couleur de la couverture »

Le directeur a répondu aux huit questions du bilan (`BILAN-CAHIER-2026-11-11.md`). Ses mots : « pour
tes questions, il faut partir avec tes recommandations, sauf pour la couleur de la couverture, qui
doit être la couleur de la marque, la couleur de l'académie, pas autre chose. Et aussi, il faut que
ça soit joli et compréhensible, facile à reconnaître. »

| N° | Question | Décision | Suite |
| :--- | :--- | :--- | :--- |
| 1 | Les élèves adultes attendent-ils l'enseignant pour ouvrir leur micro ? | **Oui**, même règle pour tous les élèves | déjà codé (D-008) |
| 2 | Pendant une récitation, fermer aussi la caméra des camarades ? | **Non : le micro seul** | **corrigé dans le code le 11/11** (lot RECITATION-MICRO-SEUL, D-022) ; pas déployé, pas prouvé en production |
| 3 | Couverture du Coran en bleu nuit et or ? | **Non. La couleur de l'académie**, jolie, compréhensible, facile à reconnaître | **fait le jour même** : violet profond de la marque (`#4E2983`), réservé au Coran ; titre arabe « القرآن الكريم » en blanc ; cadre en lavande de la marque (`#E8D8FF`). Le bleu nuit et l'or sont retirés de la palette : plus aucune couleur nouvelle. Les supports de l'académie gardent les deux autres violets |
| 4 | Une languette au bord de l'écran pour les supports ? | **Non**, un seul endroit par chose | rien à faire |
| 5 | Coran plus grand chez l'enseignant sur ordinateur | **La barre sur un côté d'abord** | à coder |
| 6 | Durée de conservation du relevé de qualité | **180 jours** | lot RESEAU-PREUVE débloqué (migration à préparer, installée par le pilote) |
| 7 | Paiement du temps de dépassement | **Non payé** | règle d'argent validée par le directeur ; à vérifier dans le calcul de la paie avant d'écrire une ligne (`DECISION-TARIFS-2026-10-18.md`), jamais codée en dur |
| 8 | L'écran où la table des sourates semblait dans le désordre | reste une question au directeur (ce n'était pas une recommandation) | |

Autres réponses du même message :

- **Vignette vidéo** : sur ordinateur, rangée dans le panneau des élèves, c'est bon. La demande de
  la déplacer ou de la cacher concerne **le téléphone**. Retenu (recommandation du pilote) : glisser
  la vignette vers un bord la range, une petite languette la rappelle ; cela ne change que
  l'affichage chez soi, jamais la caméra de l'autre.
- **« Reprendre la lecture » dans le lecteur du Coran** (capture du directeur : un grand panneau en
  haut qui ne se ferme jamais) : « normalement, ça devait être une petite languette qui dit revenir à
  l'ancienne page, numéro tel, qu'on peut fermer facilement ». Codé le jour même : une languette
  d'une ligne (« Revenir page 30 ») avec une croix, posée par-dessus le haut de la page sans la
  pousser, qui s'efface seule après 6 secondes et se retrouve par le signet. Vaut pour l'élève et
  pour l'enseignant (même lecteur).

## D-020 (11/11/2026). Le téléphone de l'enseignant réduit, « Réduire la salle » visible, le chrono au repos (lot TELEPHONE-REDUIT)

**Demandes** : cahier §9 (« Le téléphone réduit », discutable avec preuves) ; Q1 de
`SORTIES-DE-LA-SALLE.md` (aucun « Réduire » visible au téléphone de l'enseignant) ; cahier §8 (le
chrono caché dans une carte dépliable au téléphone).

**Désaccord dit au directeur** : le §9 est juste pour l'élève, pas pour l'enseignant qui n'a qu'un
téléphone (l'académie dit aux familles « Le téléphone reste pris en charge »). Il doit garder ouvrir
et partager un support (sinon personne ne le partage), voir ses élèves et « Faire réciter », et
réduire la salle. Rien de cela n'est retiré. Le reste du §9 est appliqué.

**Ce qui est codé, sous 600 points seulement** (tablette et ordinateur inchangés) :
- l'île (chrono, état) posée en haut au repos, à la place de la capsule (qui revient au toucher ;
  son profil garde la ligne d'état) ; aussi sur iPad en portrait ;
- « Réduire la salle » au début de la capsule du haut (la place du retour d'un téléphone, le même
  geste que le retour du téléphone), seulement si l'appel est tenu, jamais en Interface guidée ; la
  pilule Micro, Caméra, Élèves, Quitter ne change pas (un cinquième disque la mettait sur deux
  rangées à 390) ; aussi sur iPad en portrait ;
- le Pointeur, qui **n'existait pas** au téléphone (D-014 disait le contraire, c'était faux), à côté
  de « Commandes » ; tenu, il reste visible au repos et se repose d'un appui ;
- le tiroir n'a plus d'onglets : la Bibliothèque seule (ouvrir, partager, ranger) ; ni écriture ni
  ouverture du tableau ; une phrase dit « Pour écrire sur la page ou ouvrir le tableau, utilisez une
  tablette ou un ordinateur » ; un tableau ouvert ailleurs garde sa ligne pour le fermer.

**Preuves** : tests locaux `test/features/salle_seance/telephone_reduit_test.dart` (390 x 844 clair
et sombre, français et arabe ; 360 x 640 en texte x2 ; 834 inchangé) ; captures **de test** avant /
après dans `docs/current/captures/E2E/telephone-reduit/`. Pas essayé sur le banc ni en production.
Revue : `docs/current/UX_REVIEW_TELEPHONE-REDUIT.md` (questions T1 à T5).

## D-019 (11/11/2026). Les situations graves de la salle (lot SITUATIONS-GRAVES)

**Demande du directeur** : « gérer tout ce qui entoure la salle, toutes les situations avant d'entrer
à la salle et pendant et après la fin du cours et après qu'on ait coupé, après qu'on ait pris une
pause. Tout. » Ce lot corrige six défauts du relevé `SITUATIONS-DE-LA-SALLE.md` (§5). Tout est
**codé et testé localement, rien n'est prouvé en production.**

1. **Micro refusé, pris ou absent (défaut n° 3).** Avant l'entrée, le pré-vol lit la permission du
   micro sans rien demander ni ouvrir (`navigator.permissions`, `pre_vol.dart`) : un refus déjà
   donné arrête l'entrée sur « Le micro ne s'ouvre pas » et dit comment l'autoriser. Au geste, un
   échec n'est plus muet : la cause (refusé, pris, absent, autre) est lue dans la phrase du
   navigateur, dite tout de suite en tête de la salle, et la feuille « micro bloqué » existante la
   reprend avec « Réessayer le micro ». Le micro reste fermé à l'entrée (règle du 25/10). Limite :
   un micro pris par une autre application ne se voit qu'au geste (le détecter avant demanderait
   d'ouvrir le micro). La caméra avait déjà ce traitement (D14), rien n'y change.
2. **Rechargement ou plantage (défaut n° 4).** À l'entrée, l'onglet retient la séance, la classe et
   l'élève (`sessionStorage`, `RepriseSalle` dans `billet_salle.dart`), **jamais un jeton ni un
   droit**. Après un rechargement sur `/salle`, la personne revient directement dans sa salle : un
   jeton neuf est demandé à `create-room-token`, qui revérifie tout ; micro et caméra fermés. La
   reprise meurt avec l'onglet, s'oublie à la sortie volontaire et à tout refus du serveur, et ne
   dure pas plus de 4 heures. Un autre onglet ou une adresse copiée n'ouvrent toujours rien
   (ADR-005). **Non fait** : la page présentée, le tableau, les traits et la parole de l'enseignant
   restent perdus au rechargement (en mémoire seulement : `livekit_session_provider.dart`,
   `synchro_salle.dart`) ; les rétablir demande une source au serveur, ce n'est ni petit ni sûr.
   L'enseignant retrouve sa page par « Reprendre page N » (lu au serveur), comme avant.
3. **Refus d'entrée vrais (défaut n° 8).** `create-room-token` lit la raison levée par la base :
   compte invalide, accès suspendu, sorti par l'enseignant, temps d'observation épuisé (levées
   seulement après que la base a reconnu l'appelant, ou ne parlant que de lui) ; puis
   `motif_refus_salle` ; puis, sans motif, « Ce cours n'est pas dans vos cours », la même réponse
   que la séance existe ou non. Une panne (code inattendu) n'est plus un refus : statut 500, « La
   salle n'a pas pu s'ouvrir, Réessayer ». Aucune migration : tout se lit dans les raisons
   existantes. Aucun mot d'argent : « Accès à cette classe temporairement indisponible » (règle des
   mots : à l'enfant, on ne parle jamais d'argent).
4. **Tuteur coupé en fin d'observation (défaut n° 7).** LiveKit ne dit que « participant retiré ».
   Chez un observateur (sans voix), l'écran redemande l'entrée au serveur, qui refuse avec le motif
   « observation_terminee » ; l'écran dit alors « Votre temps d'observation est terminé ». Aucun
   jeton rendu n'est employé. L'élève sorti par l'enseignant garde son écran.
5. **Enseignant absent ou parti (défaut n° 2).** Chez l'élève, une annonce de tête, une fois par
   changement : « Votre professeur n'est pas encore arrivé » quand il entre sans lui, « Votre
   enseignant n'est plus dans la salle » quand il part, avec ou sans camarades. La fermeture de la
   salle et le retrait des micros restent à l'agent de la fermeture (serveur).
6. **La pause (défaut n° 6).** Ce qu'elle est, d'après `port_pause_seance.dart` et ses appelants :
   une pause programmée par l'enseignant sur sa classe (moment et durée), qu'il démarre et termine
   lui-même depuis le chrono ; le serveur horodate et ne laisse lire l'état qu'à l'enseignant de la
   séance et à la direction (`pause_seance_etat`). Désormais le poste de l'enseignant relaie l'état
   servi à la classe sur le canal fiable de la salle (à chaque changement et à chaque arrivant) :
   élève et tuteur voient la pause dans l'île (le même chrono) et lisent « Pause : la séance reprend
   dans un instant » en tête. Seul un paquet venu de qui conduit la séance est lu. Rien d'autre ne
   change : aucun micro n'est touché, la fin prévue ne recule pas.

**Questions au directeur (non tranchées, rien n'est codé) :**

- **La pause repousse-t-elle la fin prévue ?** Recommandation : oui, de la durée réelle de la
  pause, décidé au serveur (sinon une pause de 10 minutes vole 10 minutes de cours et le dépassement
  permis se consomme pendant la prière).
- **La pause ferme-t-elle les micros ?** Recommandation : oui pour les élèves (fermés par le serveur
  au début, rouvrables par eux à la reprise), jamais pour l'enseignant.
- **La pause se termine-t-elle seule à l'heure de reprise ?** Recommandation : non ; une note douce
  à l'enseignant à l'heure de reprise, et c'est lui qui reprend.

**Limites connues.** Le relais de pause dépend du poste de l'enseignant (s'il n'est pas là, rien
n'est relayé ; un remplaçant ne lit pas la pause : `pause_seance_etat` ne connaît que
`sessions.teacher_id`). Les tests de la fonction Edge (`motif_salle_test.ts`) sont écrits mais n'ont
pas tourné ici (Deno absent de la machine).

## D-022 (11/11/2026). Pendant une récitation, le micro seul est fermé : la caméra des camarades reste (lot RECITATION-MICRO-SEUL)

**État, vérité d'abord** : codé sur une branche, pas fusionné, pas déployé, pas prouvé en
production. Prouvé sur la pile locale (vraies fonctions Edge, vrai serveur LiveKit 1.13.11) et par
des tests. **Pas essayé dans la vraie application** (deux navigateurs), ni avec le webhook coupé.
Aucune migration, aucun texte nouveau.

**Décision du directeur (11/11/2026, sur la recommandation du pilote).** Pendant « Faire réciter »,
seul le micro des autres élèves est fermé ; leur caméra reste. Le lot GESTES-POINTEUR (D-014)
retirait le droit de publier d'un bloc : micro et caméra se fermaient.

### Ce que fait le serveur

- **Un camarade garde le droit de publier, borné à la caméra** (`canPublish` vrai,
  `canPublishSources` = caméra seule). LiveKit dépublie alors lui-même son micro et refuse toute
  nouvelle piste de micro ; sa caméra n'est pas touchée (la même piste reste publiée).
- **La caméra n'est laissée que si le propre jeton de l'élève la lui donne** (`pub.camera`, signé
  par le serveur, où `camera_policy` est déjà appliquée). Un élève dont le profil interdit la caméra
  n'en gagne jamais une par ce biais : pendant la récitation il n'a ni micro ni caméra (droit de
  publier retiré tout entier). Un jeton sans droits lisibles : rien non plus.
- **Jamais « publier » avec une liste de sources vide** : LiveKit la lit comme « toutes les
  sources ». Sans micro ni caméra, le droit est retiré tout entier (`permissionDePublication`).
- **À la fin, chacun retrouve exactement les droits de son propre jeton** : le micro, et la caméra
  seulement s'il l'avait. Micros fermés : rien n'est rouvert à la place des élèves.
- Les décisions restent des fonctions pures (`_shared/recitation.ts` : `droitsPendantRecitation`,
  `camaradesARegler`, `elevesARendre` ; `_shared/publication_differee.ts` : `droitsEnVigueur`,
  `permissionDePublication`) ; un seul endroit écrit une permission chez LiveKit
  (`poserPublication`, dans `_shared/livekit.ts`).

### Les trois règles qui lisent « le droit est fermé »

Avant ce lot, « fermé » se lisait sur un seul booléen (`canPublish`). Il ne suffit plus : un
camarade en récitation a `canPublish` vrai et pas de micro. Chaque règle lit maintenant ce qu'elle
protège.

| Règle | Ce qu'elle ferme | Ce qu'elle lit | Changé ? |
| :-- | :-- | :-- | :-- |
| MICRO-AVANT-ENSEIGNANT (D-008) : avant l'enseignant | micro et caméra (jeton signé sans droit) | pour rendre : « le micro est fermé » | la fermeture, non ; la lecture, oui (micro au lieu de `canPublish`) |
| Récitation (D-014, D-022) | le micro seul (tout, si la caméra est interdite) | pour rendre : « le micro est fermé » | oui |
| FERMETURE-SALLE (D-018) : deux minutes sans enseignant | micro et caméra | pour fermer : « il reste un droit de publier » (`canPublish`) | non : un camarade resté à la caméra seule est fermé comme les autres |

Conséquence voulue de la première ligne : un élève resté à la caméra seule après une fin de
récitation mal passée (LiveKit muet au moment de rendre) est rétabli par la règle ordinaire, au
prochain événement ou par le filet de son application. Il ne reste jamais sans micro devant son
enseignant.

### Ce que fait l'application

- Elle lit le droit **source par source** (`droitsAccordes`, `lib/core/video/publication_differee.dart`).
  Ajouté, sans rien renommer : un paramètre facultatif `micro` à `accesApresPermissions`,
  `AccesSalle.avecPublication` et `CapacitesSalle.avecPublication`. `capacites.peutPublier` reste
  « peut publier sa voix » ; `peutPublierVideo` reste la caméra ; `publicationDifferee` dit que le
  micro attend.
- Le camarade n'a pas de bouton de micro, lit « Votre micro est fermé pendant que Yasmine récite. »
  (phrase existante) et **garde son bouton de caméra, qui marche**. Aucun écran n'a été modifié : la
  vue lisait déjà le micro et la caméra séparément.
- **Le micro ne se rouvre pas seul à la fin.** Le moteur retient le micro que la personne avait
  ouvert, pour le rendre après une veille ou une coupure de réseau (D-009). Sans précaution, il
  l'aurait rouvert au retour du droit. Quand le serveur ferme le micro **alors que l'enseignant est
  dans la salle** (c'est la récitation, seule règle qui ferme un micro devant lui), le moteur oublie
  ce souhait (`microFermeDevantEnseignant`) : à la fin, le bouton revient, micro fermé, et l'élève
  le rouvre lui-même. La reprise après une veille n'est pas touchée : le serveur n'y ferme aucun
  droit, le micro voulu est rouvert comme avant. **Le retour de l'enseignant après FERMETURE-SALLE
  n'est pas changé non plus** (le micro ouvert avant son départ est rouvert : question 5 de D-018,
  toujours posée au directeur).

### Sources LiveKit

- `canPublishSources` : « Only sources explicitly set here can be published » (commentaire du SDK
  serveur employé, `livekit-server-sdk` 2.13.1, lu le 11/11). Liste vide = toutes les sources : lu
  dans le code de la bibliothèque web de LiveKit (2.23.0), pas essayé sur le serveur (le code ne
  pose jamais « publier » avec une liste vide).
- **La dépublication de la seule piste dont la source n'est plus permise n'a pas été relue dans la
  documentation de LiveKit : elle est établie par l'essai**, sur le serveur 1.13.11 de la pile
  locale. **Non vérifié** : la version du serveur LiveKit de production.
- La bibliothèque web de LiveKit refuse d'elle-même de publier sans le droit. Le banc retire ce
  contrôle local, comme le ferait un client modifié, et regarde ce que l'enseignant reçoit : le
  serveur ne répond pas à la demande de piste et ne relaie rien.

### Preuves

- Décisions pures : 74 tests Deno sur les trois règles (`recitation_test.ts`,
  `publication_differee_test.ts`, `fermeture_salle_test.ts`), dont 20 nouveaux (2 anciens
  remplacés).
- Application : tests Dart de `test/core/video/publication_differee_test.dart`,
  `ecran_eveille_test.dart` et `test/features/salle_seance/recitation_micro_seul_test.dart` (390,
  1440, 320 en texte ×2, Interface guidée, caméra interdite).
- Pile locale, `node tool/salle/gestes.mjs` : **44 contrôles sur 44**. Pendant la récitation,
  LiveKit dépublie le micro du camarade, garde sa caméra (même piste), refuse un micro forcé par un
  client modifié (l'enseignant ne reçoit rien), accepte une caméra neuve ; l'élève à la caméra
  interdite n'obtient ni micro ni caméra, même forcés ; un élève entré pendant la récitation perd
  son micro et garde sa caméra ; à la fin, chacun retrouve les droits de son jeton, micros fermés.
- Rejoués ensuite, l'un après l'autre : `micro_avant_enseignant.mjs` (15 sur 15) et
  `fermeture.mjs` (32 sur 32, passage planifié compris) : les deux autres règles tiennent
  toujours. Journaux :
  `docs/current/captures/E2E/recitation-micro-seul/`.
- Captures de test (la salle montée seule, données de démonstration ; pas la vraie application) :
  même dossier, 390 et 1440, clair et sombre, une en arabe, une sans caméra.

### Ce qui reste

- **La vraie application dans deux navigateurs, puis la preuve du directeur en production.** En
  particulier : la façon dont le SDK Flutter réagit quand le serveur dépublie le micro, et l'oubli
  du micro voulu, qui n'est testé que par sa fonction pure (son branchement dans le moteur est lu,
  pas essayé).
- **Une fenêtre d'une fraction de seconde, qui existait déjà en D-014** : un camarade qui entre ou
  revient pendant la récitation reçoit un jeton aux droits ordinaires (l'enseignant est là) et
  n'est fermé qu'au webhook de son entrée (425 ms sur la pile). S'il avait ouvert son micro avant
  une veille, son application peut le rouvrir pendant cet instant. Pour la fermer : signer le jeton
  sans micro quand une récitation tient (`create-room-token`). Non fait dans ce lot.
- **Déployer les fonctions et l'application ensemble.** Avec le nouveau serveur, une application
  pas encore mise à jour lit « droit de publier » chez un camarade et garde son bouton de micro
  pendant la récitation : l'appui échoue (le serveur refuse), sans explication. Avant ce lot, elle
  n'avait pas de bouton.
- Le webhook coupé (`SANS_WEBHOOK=1 node tool/salle/gestes.mjs`) : pas rejoué.
- Les tests Deno de `supabase/functions/_shared/` ne sont toujours pas lancés par la CI.
- Sans le prénom du récitant (message de la récitation non reçu par l'application), le camarade lit
  la phrase de l'attente de l'enseignant, fausse dans ce cas. Existant, non corrigé ici.

## D-021 (11/11/2026). Le Coran grand chez l'enseignant sur ordinateur : la barre passe sur un côté (lot CORAN-GRAND)

- **Demande** : « Sur PC, il faut que le Coran soit grand » ; décision du directeur sur la
  recommandation du pilote : « la barre sur un côté d'abord » (question 5 ci-dessus).
- **Décidé et codé** (`salle_ordinateur.dart`) : la barre des commandes devient une colonne sur le
  bord de début (mêmes cinq groupes, même ordre de haut en bas, mêmes tuiles, états, raccourcis et
  infobulles ; Quitter seul rouge, tout en bas). La rangée du haut disparaît : la Classe, le titre
  du support et l'île en tête de la colonne ; zoom, ranger et focus dans les marges de la page,
  au-dessus de ses flèches. La page prend toute la hauteur de l'écran. Repli de la colonne quand la
  hauteur manque : le titre, puis la Classe, puis les noms des tuiles (icônes et infobulles) ; elle
  ne défile jamais. Focus : les panneaux partent, la colonne reste en icônes, l'île reste. Quand
  l'enseignant écrit, la palette prend la place du panneau des Élèves.
- **Mesures** (texte de la page, vraies polices) : 1440 x 900, de 371 x 614 à 448 x 742 panneaux
  ouverts (+ 21 %) et 462 x 765 fermés (+ 25 %) ; 1280 x 720, de 275 x 455 à 295 x 488 ouverts
  (+ 7 %, la largeur borne) et 366 x 607 fermés (+ 33 %).
- **Écarts datés** à la composition du 26/10 et à D-015 : barre sur toute la largeur devenue
  colonne ; « une tuile du côté du panneau qu'elle ouvre » abandonnée (tout est du même côté) ;
  le focus retire aussi les noms de la colonne au lieu du haut.
- **Non prouvé** : rien vu sur la vraie application ; captures de test seulement
  (`docs/current/captures/E2E/coran-grand/`). Détail, sources et questions :
  `docs/current/UX_REVIEW_CORAN-GRAND.md`.
- **Questions au directeur** : Bibliothèque ouverte d'office seulement à 1600 et plus (recommandé) ;
  colonne collée au bord (recommandé, lot suivant) ; palette qui cache les Élèves pendant
  l'écriture (recommandé) ; icônes de 24 dans la colonne pour garder les noms à 720 (à essayer).

## D-027 (11/11/2026). La grille des commandes : une seule règle au téléphone, sur tablette et sur ordinateur (lot GRILLE-COMMANDES)

- **Retour du directeur** (11/11, sur deux captures) : « C'est nul comme layout, aucun patterne, pas
  bien aligné, ni coordonné… En plus "Commandes" veut dire quoi sur mobile si le pointeur est déjà
  dehors ? Il faut bien aligner les icônes partout, c'est l'une des raisons pour la refonte. »
- **Constat, sur ses captures** : au téléphone, trois objets posés à trois endroits (le Pointeur
  flottant, le bouton « Commandes », la pilule à disques), des noms qui changeaient avec l'état et
  dépassaient (« icro coupé », « Quitte ») ; sur ordinateur, le nom et l'icône des tuiles
  « ouvertes » (Élèves, Bibliothèque) collés au bord au lieu d'être centrés, l'état de la séance
  plié sur quatre lignes dans 110 points, le zoom dans une pilule blanche à moitié vide d'un côté de
  la page et les autres outils de l'autre, les groupes de la colonne coupés par un vide.
- **La règle, écrite une fois** :
  1. **Une tuile, la même partout** (`TuileCommandeSalle`) : l'icône, et dessous un nom **fixe**
     sur une ligne. L'état ne change jamais le mot (« Micro », jamais « Micro coupé ») : il se lit
     par l'icône barrée, l'aplat et le lecteur d'écran.
  2. **Des cases égales** (`SurfaceTuilesSalle.egale`) : dans une barre, toutes les cases ont la
     même largeur et la même hauteur ; les icônes sont sur une ligne, à pas régulier.
  3. **Tous les noms, ou aucun** (`TuileCommandeSalle.nomsTiennent`) : si un seul nom ne tient pas
     dans sa case (écran étroit, texte agrandi, arabe), toute la rangée passe en icônes seules ;
     le nom reste dans l'infobulle et pour le lecteur d'écran. Jamais un nom coupé.
  4. **Le même ordre partout** : ma voix (Micro, Caméra), ma classe (Élèves), les documents
     (Bibliothèque, Tableau), la page (Pointeur, Écrire), sortir (Réduire, Quitter). Ce qui ne
     tient pas au téléphone va derrière « Plus », toujours l'avant-dernière case, à côté de
     Quitter (le Pointeur y passe donc avant « Plus » : seul écart d'ordre, dit ici).
     *Corrigé le 11/11 après l'essai dans la vraie application* : la page venait avant les
     documents ; sans document ouvert, la place vide de Pointeur et Écrire faisait un trou au
     milieu de la colonne. Elle est maintenant le dernier groupe du haut : la place reste, rien
     ne glisse, et le trou a disparu.
  5. **Un seul endroit par chose** : les outils de la page (ranger, plein écran, zoom) ensemble, au
     même coin de la page, mêmes boutons ronds ; plus rien de flottant à côté de la barre.
- **Codé, téléphone et tablette de l'enseignant** (sous 840 points, `BarreCommandesTelephone`) :
  une barre, six cases : Micro, Caméra, Élèves, Pointeur, Plus, Quitter. Le mot « Commandes »
  disparaît : la case s'appelle « Plus » ; le tiroir porte le nom de son contenu (« Bibliothèque »
  au téléphone, « Bibliothèque et outils » sur tablette). Au repos, plus de bouton posé sur la
  page ; le Pointeur tenu reste seul, à sa place dans la rangée. À 320 points, les écarts se
  resserrent pour garder six cases de 48.
- **Codé, ordinateur** : le contenu des tuiles « ouvertes » est centré ; quatre groupes en haut
  (voix, classe, documents, page), « sortir » seul en bas ; la tête de la colonne ne porte plus le
  nom de la Classe (deux lignes coupées dans 110 points), seulement « Coran · Page 42 » sur une
  ligne et l'île ; l'île a une place fixe d'une ligne et, dépliée, passe par-dessus le panneau des
  Élèves au lieu de se plier (elle ne pousse plus la barre) ; ranger, plein écran et zoom sont une
  seule pile au coin de fin de la page.
- **Écarts datés** : à la fiche 1 du téléphone (26/10 : pilule à disques, « Commandes » au-dessus,
  noms d'état) et à D-020 (Pointeur à côté de « Commandes ») ; à D-021 (Classe en tête de colonne,
  zoom du côté début). Gardé tel quel : micro ou caméra coupés en violet de marque (directeur,
  25/10), Quitter seul rouge.
- **Ce que cela coûte, dit** : au téléphone, au repos, il n'y a plus de bouton visible en bas ; il
  faut toucher la page pour revoir la barre (comme chez l'élève), puis « Plus » : deux gestes pour
  la Bibliothèque, comme avant depuis l'état « au toucher », un de plus depuis le repos.
- **Non prouvé** : captures de test seulement (`docs/current/captures/E2E/grille-commandes/`), rien
  vu dans la vraie application ni sur un vrai téléphone. En arabe à 390 points, « الميكروفون » ne
  tient pas dans une case : la rangée est en icônes seules (un mot plus court serait à choisir).
- **Reste à ranger selon la même règle** (pas fait dans ce lot) : la capsule du haut au téléphone
  (retour, vidéo, point d'état, œil, barres de réseau) ; les en-têtes des deux panneaux de
  l'ordinateur (Élèves sans titre ni croix, Bibliothèque avec une pastille et une croix) ; la
  phrase « Choisissez un support… » de la Bibliothèque, qui emploie un mot écarté le 30/10.

## D-023 (11/11/2026). Au téléphone, ranger la vidéo de l'enseignant au bord et la rappeler (lot VIGNETTE-TELEPHONE)

**Demande** : « Est-ce qu'on peut bouger les vignettes de vidéo ou les cacher comme on le veut, ou
bien c'est toujours figé ? », puis « je parlais du mobile, téléphone » (directeur, 11/11/2026). Il a
retenu la recommandation du pilote : glisser vers le bord range, une languette reste, la toucher ou
la tirer remontre la vidéo ; les quatre coins ne changent pas ; rien n'est envoyé.

**Ce qui est codé** (`VignetteAimantee`, `rangeable` ; composant partagé `LanguetteBord`) :
- chez l'élève, le tuteur et le contrôleur devant une page, au téléphone et à la tablette en
  portrait : la vignette lâchée à moitié au-delà du bord gauche ou droit (ou lancée vers lui après
  le quart) se range ; une languette de 24 de large (cible de 48), icône caméra, reste sur ce bord à
  la hauteur du rangement ; un appui ou un tirage la ramène au coin le plus proche de ce bord ;
  un glissement court ne range jamais ; un appui sur la vignette la met toujours en grand ;
- une poignée (chevron vers le bord) à côté de la vignette posée la range d'un appui (WCAG 2.5.7) ;
  lecteur d'écran « Ranger la vidéo de … », « Montrer la vidéo de … » ; clavier ;
- la languette suit les commandes : visible au toucher, masquée à 3 s ; état rangé gardé pendant la
  séance ; caméra éteinte puis rallumée : la languette revient au prochain toucher, sans forcer
  l'affichage (pas de signe en plus) ;
- sur ordinateur et en paysage chez l'élève : le même geste, la languette au bord de la fenêtre,
  dans la bande de côté ; pas en Interface guidée (l'enfant garde le visage de son enseignant) ;
- rien ne change chez l'enseignant (sa capsule n'apparaît déjà qu'au toucher ; la galerie en grand
  se ferme par « Revenir à la page », un appui).

**Sécurité** : seulement l'affichage chez soi ; ni paquet, ni demande au serveur, ni caméra, ni
micro (mesuré par le test).

**Preuves** : tests locaux `test/features/salle_vignette_telephone_test.dart` (vrai `/salle` de
l'élève ; 320, 390, 820, 1440 ; clair et sombre ; texte x2 ; arabe) ; captures **de test** dans
`docs/current/captures/E2E/vignette-telephone/`. Pas essayé sur un vrai téléphone, ni sur le banc,
ni en production. Revue : `docs/current/UX_REVIEW_VIGNETTE-TELEPHONE.md`.

## D-025 (11/11/2026). Les transitions de la salle, dans le langage de l'application (lot TRANSITIONS-SALLE)

- **Demande** : traiter les transitions de la salle (entrer, sortir, panneaux, tiroir, supports,
  chrono) ; règles arbitrées par le garde-cap sur l'avis du pilote.
- **Décidé et codé** : jetons nommés par leur rôle dans `app_mouvement.dart` (déplacement entrée /
  sortie, version ordinateur, fondu entrée / sortie, arche, passage, sortie de salle ;
  `ressortDeplacement`, ressort sans rebond ; `courbeFondu`). Composants du cœur :
  `EntreeArche` (le moment de l'arche), `PassageSalle` et `FonduAuChangement`
  (`lib/core/mouvement/passage_salle.dart`), `PanneauGlissant` et `MonteeDuBas`
  (`lib/core/mouvement/panneau_glissant.dart`). L'arche habille l'attente réelle d'entrée dans la
  carte de la salle et seulement elle ; la salle prête la remplace à la même image (mesuré), un
  voile de 150 ms qui ne prend aucun geste s'efface par-dessus. Ni au retour depuis l'île, ni après
  un rechargement, ni à une reconnexion. Sortie : fondu de 150 ms, aucun moment de marque. Panneaux
  de l'ordinateur : glissement depuis leur bord, la page suit sur le même ressort sans saut.
  Tiroir et feuille du téléphone : montée du bas dans leur place, jamais sur la pilule. Support :
  fondu court au changement de support, jamais au tour de page. Annonces : par le haut, sortie en
  fondu.
- **Version sobre** pour « réduire la salle » : l'île arrive en se resserrant, la salle se
  redéplie depuis le haut ; pas de morphose de page (le routeur n'est pas touché).
- **Non fait** : sortie animée du tiroir et de la feuille (retirés par `telephone_plein_ecran.dart`,
  zone d'un autre agent) ; respiration d'arrivée du chrono rejouée au retour depuis l'île
  (`chrono_vivant.dart`, hors zone).
- **Non prouvé** : rien vu sur la vraie application ; captures de test
  (`docs/current/captures/E2E/transitions-salle/`). Détail et sources :
  `docs/current/UX_REVIEW_TRANSITIONS-SALLE.md`.
- **Question au directeur** : l'arche vit dans la carte de la salle (l'en-tête « Connexion au
  cours », la mention et « Quitter » restent visibles). Une arche plein écran serait plus forte,
  mais cacherait « Quitter » pendant une connexion longue : recommandé de garder la carte.

## D-026 (11/11/2026). Le partage en direct devient commun à tout support (lot PARTAGE-GENERIQUE)

**État, vérité d'abord** : codé sur une branche, rien n'est fusionné ni déployé, rien n'est prouvé en
production. La migration est un **brouillon non appliqué**. Aucun support réel n'existe : seul un support
de démonstration factice se partage, et seulement sous `PLAYGROUND` et dans les tests. Les traits
(écriture) ne sont pas prouvés par un test sur ce support ; le pointeur l'est.

- **Demande** (cahier §7) : « Le partage en direct (afficher, partager, suivre la page, pointer, écrire)
  doit être un mécanisme commun à tout support, jamais codé en dur pour le Coran. »
- **Décidé et codé** :
  - le message de présentation dit quel support est ouvert : identifiant, version, page, nombre de pages
    (`ContenuPresente`). Sans identifiant, c'est le Coran ;
  - un lecteur par support (`lib/features/salle_seance/lecteur_support.dart`) : le Coran garde le sien ;
    un support à pages d'images a un lecteur simple (`PageImageSupport`) ; un support que l'application ne
    connaît pas dit « Ce support ne peut pas encore s'afficher ici. », avec la raison et quoi faire ;
  - la page d'un support aux proportions fixes garde ses proportions, centrée, jamais étirée : le pointeur
    et les traits tombent au même endroit de la page sur tous les appareils ;
  - tourner la page, glisser, « la page suit celle de l'enseignant », le pointeur et l'écriture ne
    savent rien du support (ils ne le savaient déjà pas : relevé dans
    `docs/current/UX_REVIEW_SUPPORTS-ETAGERE.md` §1) ;
  - la reprise : la page d'un autre support n'est plus jamais écrite comme une page du Coran (c'était le
    cas de toute page présentée) ; elle a sa mémoire, par Classe et par support.
- **Compatibilité entre versions de l'application** : une application nouvelle lit un message ancien
  comme le Coran. Une application ancienne lit un message nouveau du Coran comme avant. Devant un autre
  support, une application ancienne lit « rien n'est présenté » : l'élève garde la vidéo de l'enseignant
  et entend le cours, il ne voit pas le support, et il ne voit jamais la page du Coran de même numéro.
- **Base, écart à la consigne du lot** : la consigne proposait d'élargir la contrainte
  `support = 'mushaf'`. Non retenu : `classe_position_reprise` a une seule ligne par Classe, donc ouvrir le
  livre des lettres aurait effacé la page du Coran de la Classe. Le brouillon
  `20261123000000_partage_generique_position_support.sql` crée une table neuve (une ligne par Classe et
  par support) et deux fonctions, avec les gardes de CAHIER-C1. Aucune instruction d'effacement : pas de
  page à coller. Sans cette migration, la salle marche ; l'enseignant lit « La page de ce support n'est
  pas encore retenue d'une séance à l'autre. À la prochaine séance, choisissez de nouveau la page. »
- **Droits** : inchangés. Seul le jeton qui porte le droit de présenter partage ; l'élève ne publie rien
  (testé).
- **Le support de démonstration** : « Les lettres », 4 pages qui ne portent que le titre, « N / 4 » et
  « À valider ». Aucun contenu religieux ni pédagogique. Jamais dans les données de production.
- **Reste, dit franchement** : sur ordinateur, le titre en tête de colonne dit encore « Coran · Page N »
  pour tout support (`salle_ordinateur.dart:454`, fichier d'un autre lot ; le texte générique est prêt) ;
  « Ouvrir le Coran » sur la scène vide et la feuille du raccourci B n'ouvrent que le Coran ; le cahier de
  transmission ne propose que la page du Coran ; le tuteur et le contrôleur ne suivent pas la présentation
  (déjà le cas pour le Coran) ; les flèches et le glissement supposent un livre qui se lit de droite à
  gauche ; la Bibliothèque de la salle ne lit pas encore le catalogue ; aucun lecteur de PDF (un PDF doit
  être déposé en images, une par page).
- **Preuves** : `test/features/salle_partage_generique_test.dart` (compatibilité dans les deux sens,
  support inconnu, partage de bout en bout dans la vraie `SallePage`, reprise, lecteur d'images) ;
  captures de test, pas de la vraie application : `docs/current/captures/E2E/partage-generique/`.
  Base : sur un Postgres nu local, le stub, les 422 migrations (le brouillon compris), puis
  `supabase/tests/scenarios_partage_generique_position_support.sql`, 22 contrôles sur 22 (une page par
  support, le Coran intact, étranger et élève refusés, remplaçant, direction en lecture seule). Ce
  scénario n'est pas inscrit dans `ci.yml` (zone interdite aux agents).
- **Questions au directeur** : le format d'un support réel (une image par page, proposé dans
  `SUPPORTS-A-VALIDER.md`) ; installer ou non la migration avant le premier support réel ; le nom et le
  nombre de pages du livre des lettres.

## DÉCISIONS DU DIRECTEUR du 11/11 (après-midi) : « Je te laisse décider toi-même »

Le directeur a répondu aux questions du bilan par : « Je te laisse décider toi-même. » Le pilote
applique donc ses recommandations, écrites ici pour qu'elles se retrouvent et se contestent :

| Question | Décidé par le pilote, sur délégation |
| :--- | :--- |
| Phrase d'information du relevé de qualité | adoptée, puis relecture d'un juriste avant toute installation (voir ci-dessous) |
| Au téléphone, plus aucun bouton en bas au repos | oui, comme chez l'élève |
| Le téléphone de l'enseignant garde Élèves et Bibliothèque | oui (écart au §9 du cahier, dit) |
| Un document réel entre en images, une par page | oui pour commencer |
| Cours qui déborde avec l'enseignant présent | on ne coupe pas à l'heure |
| Le micro d'un élève se rouvre seul au retour de l'enseignant | non, jamais sans son geste |
| La pause | elle ne repousse pas la fin ; les micros restent au choix de chacun |

**Une délégation ne couvre ni l'argent ni la loi** : « dépassement non payé » reste à vérifier dans
le calcul de la paie avant toute ligne de code, et tout ce qui touche des données sur des
personnes reste soumis à la relecture d'un juriste.

### Le relevé de qualité : la durée revue (180 jours le matin, deux ans l'après-midi)

- **Le directeur** : « Pour la suppression est-ce nécessaire, je pensais qu'il fallait permettre à
  un parent ou un admin de chercher le rapport d'il y a 1 an pour un élève un jour précis, et voir
  exactement ce qui s'était passé ce jour. »
- **Ce qui est vrai** :
  - L'effacement à terme est exigé par la loi : une donnée sur une personne se garde « une durée
    n'excédant pas celle nécessaire » (RGPD, art. 5(1)(e)) ; au Québec, il faut ensuite la détruire
    ou l'anonymiser (Loi 25, art. 23). Sources et liens : `DROIT-RELEVE-QUALITE.md` §4. Garder
    sans fin n'est pas permis.
  - Mais la loi n'impose pas 180 jours : c'était la proposition du pilote (les 120 jours d'une
    contestation de paiement par carte, plus une marge). Elle ne permet pas ce que le directeur
    veut : retrouver une séance d'il y a un an.
  - Deux choses différentes portent le mot « rapport ». **Le relevé de qualité** est une trace
    technique (connexion bonne, faible ou perdue, micro ouvert ou non). **Le rapport de la
    séance** (présence, cahier de transmission, ce qui a été récité) est une autre donnée : aucun
    effacement automatique ne la vise dans le dépôt (vérifié le 11/11 : les tâches planifiées de
    la base n'effacent que des journaux techniques et anonymisent les comptes supprimés).
- **Décidé** : le relevé de qualité est gardé **deux ans (730 jours)**, puis effacé. Source de la
  durée : la plus courte des prescriptions relevées au §4 (Code de la consommation, art. L218-2,
  deux ans), et la doctrine de la CNIL sur la preuve gardée en archive à accès restreint, lectures
  tracées. À confirmer par un juriste.
- **Qui lit** : la direction (codé). **Un parent** : le droit d'accès aux données de son enfant
  existe déjà ; la lecture directe dans l'application est étudiée par le lot (jusqu'où un parent
  peut voir la connexion de l'enseignant, qui est une donnée de l'enseignant) et n'a pas d'écran.
- **Ce qui ne change pas** : rien n'est installé ; la migration reste un brouillon avec un
  effacement (la purge), donc une page à coller par le directeur ; à ne pas installer avant la
  phrase d'information affichée et la relecture du juriste.

## D-029 (11/11/2026). Les textes visibles de la salle suivent la règle des mots du 30/10 (lot MOTS-SALLE)

- **Règle** (directeur, 30/10/2026, `DECISION-BIBLIOTHEQUE-ET-RESTES-2026-10-30.md`) : « Bibliothèque » pour le
  conteneur, « document » pour une pièce ouverte ou affichée, « Support » écarté des textes visibles. Les
  lots du 11/11 avaient écrit « support » dans `salle.support.*`, `salle.etagere.*` et `salle.barre.groupes.support`.
- **Corrigé, seulement les valeurs** (les noms de clés ne changent pas). En arabe : « المادة » devient
  « المستند », le mot déjà employé pour « document » dans `salle.seance.*` ; « المكتبة » reste la Bibliothèque ;
  le genre et le verbe suivent (« يُفتح هذا المستند »).
  - `salle.support.inconnuTitre` : « Ce support ne peut pas encore s'afficher ici » devient « Ce document ne peut pas encore s'afficher ici »
  - `salle.support.inconnuDetail` : « un support que cette version… » devient « un document que cette version… »
  - `salle.support.inconnuNom` : « Support partagé » devient « Document partagé »
  - `salle.support.demoDetail` : « Support de démonstration. » devient « Document de démonstration. »
  - `salle.support.repriseNonRetenue` : « La page de ce support… » devient « La page de ce document… »
  - `salle.etagere.intro` : « Choisissez un support, puis… » devient « Choisissez un document, puis… »
  - `salle.etagere.revenirFiche` : « …fiche du support » devient « …fiche du document »
  - `salle.etagere.nonPartageable` et `nonOuvrable` : « Ce support… » devient « Ce document… »
  - `salle.etagere.aValiderDetail` : « Support de démonstration, à valider… » devient « Document de démonstration, à valider… »
  - `salle.etagere.rechercher` : « Rechercher un support » devient « Rechercher un document »
  - `salle.etagere.vide` : « Aucun support dans la bibliothèque » devient « Aucun document dans la bibliothèque »
  - `salle.etagere.videDetail` : « …aucun support. » devient « …aucun document. »
  - `salle.barre.groupes.support` : « Le support » devient « Le document »
- **Vu ailleurs avec le même défaut, non corrigé (hors du bloc `salle`)** : `accessibilite.apres.revoirSupport*`,
  `admin.bibliotheque.*`, `classe.pageRessources.aucuneDetail`, `classe.cartes.*`, `enseignant.ficheGroupe.support*`,
  `tc.bibliotheque.*`, `tc.realtime.*`, `tc.observation.visite.supportIndisponible`, `tc.parcours.plage.ressource`,
  `recherche.*`, `com.studio.*`, `recrutement.talents.c.conception_programmes.*`, `controleur.observation.pedagogieAide`.
  « Aide et support » (`compte.tuteur.*`) est le service d'aide, pas le document : à laisser.

## DÉCISIONS DU DIRECTEUR du 11/11 (fin d'après-midi) : pas de juriste, 180 jours, tailles des vidéos au pilote

Le directeur, mot à mot : « D'abord il n'y a pas de juriste, c'est toi qui joue ce rôle car ces
lois sont publiques et accessibles, on ne cherche pas à les contourner donc on applique ce qui est
là. En plus pour la suppression j'avais pas compris, si tu sais que la suppression ne fait rien
aux rapports alors tu peux supprimer même en 180 jours, à toi de voir. Pour les vidéos je ne
t'impose que les meilleures pratiques alors à toi de voir ce qui est meilleur pour les tailles. »

- **Relevé de qualité : retour à 180 jours.** Historique dit sans détour : 180 jours le matin ;
  deux ans en début d'après-midi, parce que le pilote avait lu la question du directeur comme un
  besoin de retrouver la trace technique d'il y a un an, alors qu'il parlait du rapport de la
  séance (présence, cahier), que cette purge ne touche pas ; retour à 180 jours. Raison de fond :
  pour une donnée sur une personne, la durée la plus courte qui sert le but (RGPD, art. 5(1)(c) et
  (e) ; sources au dossier `DROIT-RELEVE-QUALITE.md` §4).
- **Pas de juriste.** Les points de droit ne sont plus « à faire valider » : ils se tranchent par
  le texte officiel, lu et cité avec son lien, dans le dossier. Trois règles que le pilote
  s'impose : ne rien citer qu'il n'a pas lu ; quand un texte laisse une marge, prendre l'option la
  plus protectrice pour les personnes ; quand un texte ne permet pas de conclure, l'écrire et dire
  ce que cela bloque. **Limite dite au directeur** : c'est la lecture attentive d'un texte public,
  pas l'avis d'un avocat ; la responsabilité reste à l'académie.
- **Vidéos** : les tailles et la forme des cadres sont laissées au pilote, selon les meilleures
  pratiques. Le modèle écrit (`MODES-AFFICHAGE.md` §3) tient : carré au téléphone en portrait,
  4:3 sur écran large, taille bornée, grille centrée.

## D-024 (11/11/2026). Le relevé de qualité de connexion, gardé 180 jours comme preuve (lot RESEAU-PREUVE)

- **Demande** : cahier §6 (un relevé conservé comme preuve, lisible par la direction).
- **La durée : 180 jours.** Matin : 180 jours ; début d'après-midi : deux ans, sur une question du
  directeur mal comprise par le pilote ; fin d'après-midi : retour à 180 jours. Le directeur : « si
  tu sais que la suppression ne fait rien aux rapports alors tu peux supprimer même en 180 jours, à
  toi de voir. » Raison : pour la trace technique de connexion, la minimisation (RGPD art. 5(1)(c)
  et (e)) commande la durée la plus courte qui sert le but, les 120 jours d'une contestation de
  paiement par carte, plus une marge. Le rapport de la séance (présence, cahier) n'est pas touché.
- **Pas de juriste.** Le directeur : « il n'y a pas de juriste, c'est toi qui joue ce rôle car ces
  lois sont publiques et accessibles, on ne cherche pas à les contourner donc on applique ce qui est
  là. » Onze points de droit sont tranchés par les textes, lus le 11/11 et cités avec leur lien
  (`DROIT-RELEVE-QUALITE.md` §10). Limite dite en tête du dossier : la lecture attentive d'un texte
  public n'est pas l'avis d'un avocat ; la responsabilité reste à l'académie.
- **Ce que les textes ont changé dans le code** :
  - **Rien n'est gardé pour un élève mineur.** Au Québec, on ne recueille rien auprès d'un enfant de
    moins de 14 ans sans l'accord du parent (loi P-39.1, art. 4.1) ; le code britannique des enfants
    ne laisse garder que le minimum du service auquel l'enfant prend part (norme 8). La base ne
    connaît ni l'âge ni le pays d'un élève, seulement « mineur » ou « autonome » : la garde est donc
    « aucun élève mineur », dans la fonction d'écriture. Le relevé garde l'enseignant et les élèves
    adultes, ce qui répond à l'accusation du cahier (la connexion de l'académie et de ses
    enseignants).
  - **Le droit de s'opposer a un effet** (RGPD art. 21) : une table des oppositions acceptées, que la
    fonction d'écriture respecte. Pas d'écran.
  - **Les mentions de l'article 13** sont dans la politique de confidentialité de l'application
    (point 5), le droit de s'opposer à part.
  - **L'analyse d'impact et la mise en balance** sont écrites dans le dossier (§11.7, §11.11).
- **Décidé et codé** (détail champ par champ : `DROIT-RELEVE-QUALITE.md` §11) :
  - **Ce qu'on garde** : une ligne quand l'état du lien d'un participant change : la séance, la
    personne, un mot (bon, faible, perdu), micro ouvert ou non, l'heure du serveur. Rien d'autre :
    ni son, ni image, ni adresse IP, ni appareil, ni pertes, gigue ou débit (écart à D-004). Le
    résumé (durée dans chaque état, coupures) n'est pas gardé : la lecture le calcule.
  - **Qui écrit** : l'application de chaque participant, sa ligne seulement
    (`noter_qualite_lien`). Le serveur de visio ne donne la qualité d'un lien qu'aux applications :
    elle n'est ni dans ses webhooks ni dans la liste des participants (vérifié dans les définitions
    du protocole, version 1.53.4 ; pas observé sur un webhook réel). Le serveur vérifie le compte, le
    jeton d'enseignant ou d'élève délivré pour la séance, l'absence d'opposition, que l'élève est
    adulte, la fenêtre de la séance, les trois mots, le rythme (8 s), le doublon et un plafond
    (400 lignes). Les observateurs n'ont pas de ligne.
  - **Écart à D-004** : « l'appareil de l'enseignant relève la qualité de chaque élève » (deux
    regards croisés) n'est pas codé. Le regard croisé qui existe : les entrées et sorties annoncées
    par le serveur de visio, déjà en base, que la lecture place dans la même frise.
  - **Qui lit** : la direction seule (`releve_qualite_seance`), chaque lecture écrite au journal
    d'audit. Une personne ou un parent demande ses données à la direction (droit d'accès, RGPD
    art. 15) : aucune lecture directe, aucun écran pour une famille.
  - **180 jours** : purge chaque jour à 03:41 UTC (`private.purger_releve_qualite`, pg_cron) ; le
    relevé d'une séance part en entier quand sa dernière ligne a plus de 180 jours.
  - **Non modifiable** : ajout seul, un déclencheur refuse toute modification.
  - **L'information** : dans la salle (« En savoir plus » du bandeau, trois versions pour les
    élèves) et dans la politique de confidentialité. Textes écrits par le lot, à confirmer par le
    directeur (`docs/current/TEXTES-VALIDES/INFORMATION-RELEVE-QUALITE.md`).
- **Dit franchement.**
  - La migration `20261123000100_releve_qualite_lien.sql` est un **brouillon, installé nulle
    part**. **Ne pas l'installer avant : (a) l'information affichée, les mentions dans la politique
    de confidentialité et l'avis de sa modification diffusé ; (b) chaque point de droit tranché, sa
    conséquence codée ; (c) la page à coller par le directeur (un mot d'effacement, dans la purge).**
    De (a), il manque l'avis de modification (une annonce de la direction) et le site public.
  - **L'interrupteur, c'est la migration.** L'application déployée essaie d'écrire à chaque entrée
    en salle ; sans la migration, le serveur répond « fonction absente », rien n'est gardé, et
    l'appareil se tait jusqu'à la prochaine entrée. Installer la migration, c'est commencer la
    collecte le jour même.
  - Le relevé est **déclaré par l'appareil de chacun**. Une application modifiée peut mentir sur sa
    propre ligne, jamais sur celle d'un autre. C'est un indice daté, pas une mesure du son entendu.
  - **Pas d'écran pour la direction** : la lecture existe et est testée, l'écran est décrit, pas
    fait. Aujourd'hui personne ne peut rien lire sans un développeur.
  - **Les enseignants ne lisent pas l'information dans la salle** (ils n'ont pas « En savoir plus ») :
    pour eux, la politique de confidentialité seulement.
  - **Ce qui n'a pas pu être lu** : le texte consolidé du Québec (le site officiel refuse la lecture
    automatique ; les articles sont lus dans la loi de 2021 qui les a écrits) ; le droit du travail
    des enseignants ; la suite de l'article 21 sur les lignes déjà écrites.
  - Le gel des séances contestées (D-004) n'est pas codé : à 180 jours, tout part.
  - La version des textes juridiques n'est pas montée, alors que la politique de confidentialité a
    trois blocs de plus : la monter demande de changer le réglage du serveur le même jour, sinon
    l'inscription des candidats se bloque (erreur déjà payée le 06/11).
  - Rien n'est prouvé en production ni sur un vrai appel.
- **Questions au directeur** : confirmer les textes d'information ; ouvrir ou non « En savoir plus »
  aux enseignants dans la salle ; vérifier que le représentant dans l'Union est désigné et saisi ;
  faire l'écran de la direction (lot suivant) ; garder un jour le relevé d'un élève mineur, avec
  l'accord de son parent (oui ou non).

## D-028 (11/11/2026). La grille des visages, un seul cadre, un seul état de la scène (lot SCENE-CLASSE, première moitié du modèle)

- **Demande** (directeur, 11/11/2026) : « il faut juste des carrés comme sur Zoom [...] tout doit être
  bien coordonné ». Règle : `MODES-AFFICHAGE.md`. Revue : `docs/current/UX_REVIEW_SCENE-CLASSE.md`.
- **Codé** :
  - `CadreVisage` (`lib/core/widgets/cadre_visage.dart`) : LE cadre d'une personne. Forme donnée par
    l'appelant, image qui couvre (jamais étirée), nom en bas au début sur une pastille sombre
    translucide, micro fermé en icône et lu, anneau de parole en fondu (et lu : « en train de parler »),
    « Récite » et contour franc, emplacement des gestes au milieu du bord de fin, photo ou initiale
    caméra éteinte (`TuileSansImage`) en fondu. De 64 à 480 : sous 112 le nom part (lu, en infobulle),
    sous 160 la marque « Récite » part (contour et mot lu restent), sous 96 l'emplacement des gestes
    part. Ne connaît ni LiveKit ni Riverpod.
  - `GrilleVisages` et `calculerGrille` / `rectsGrille` (`lib/core/widgets/grille_visages.dart`) : le
    plus grand cadre pour N (1 à N colonnes essayées), carré au téléphone en portrait, 4/3 ailleurs
    (`rapportCadre(Gabarit, Orientation)`), borne 480 de large, plancher 96 (au-delà : pages entières et
    barre précédent / suivant), grille et dernière rangée centrées, écart 16. Arrivée : grandit en fondu ;
    départ : rétrécit en fondu puis les autres glissent sur le ressort sans rebond ; fenêtre qui change :
    sans animation ; mouvement réduit : fondu seul. **Reconnexion** : un visage parti garde sa place,
    atténué, 3 s (`AppMouvement.graceDepartVisage`, seul jeton ajouté) ; revenu à temps, rien ne bouge ;
    sa propre image (caméra coupée) part aussitôt.
  - La scène en mode Classe sort de `salle_page.dart` vers `lib/features/salle/scene_classe.dart`
    (`SceneClasse`, l'ancien `_Scene`) : chez tous les rôles et tous les appareils, `_Galerie` et `_Cadre`
    sont remplacés par la grille et le cadre ; sa propre image est le **dernier cadre** (caméra allumée,
    et jamais si elle a déjà un cadre ailleurs : `moiDejaEnCadre`) ; l'ordre reste celui de la vue
    (enseignant d'abord chez l'élève, récitant en premier). La parole est écoutée par chaque cadre
    seulement (la page ne se reconstruit toujours pas à chaque changement d'orateur, audit réseau e).
  - **Rien ne passe sur un visage** : élève (téléphone et ordinateur) : la scène s'arrête au-dessus de la
    barre (`CommandesMasquables(margeLecture:)` quand aucune page n'est montrée) ; enseignant au
    téléphone : la grille commence sous la capsule et s'arrête au-dessus de la barre mesurée.
    **« Ouvrir le Coran »** est posé par la scène **sous la grille, centré** (ou sous la phrase
    d'attente), au téléphone comme sur ordinateur : un seul endroit (`ActionSousLaScene`).
  - **Un seul état** : `ModeScene { classe, document, tableau }` et `calculerModeScene` (pur, testé),
    `voirLaClasse` (la demande « voir la classe », avant `!tableau && (_scenePremierPlan ?? presentee
    == null)`) dans `media_salle.dart` ; `modeSceneDe(context, vue)` dans `zone_support.dart`. Branché :
    `salle_page.dart` (calcul de la demande), `telephone_plein_ecran.dart` (`scene`),
    `salle_ordinateur.dart` (`_sceneAuPremierPlan`). Aucun comportement visible changé par ce socle.
- **Drapeaux restants, pour le second lot** : `_scenePremierPlan` (`salle_page.dart`, c'est l'entrée
  « voir la classe » de la personne, elle reste) ; `PorteeMediaSalle.scenePremierPlan` (le transport de
  cette demande) ; `ZoneSupport._zone` et `identiteSupport` (`zone_support.dart`) testent encore
  `media.scenePremierPlan && media.scene != null` (condition plus stricte que le mode : laissée telle
  quelle pour ne rien changer) ; `sceneDevant` (`telephone_plein_ecran.dart`, dérivé du mode) ; `tableau`
  et `presentee` (`salle_page.dart`, ce sont des entrées, pas des drapeaux d'affichage).
- **Reste pour le second lot** : le ruban du §4 (cartes du panneau, bande de côté de l'élève, vignette
  du téléphone et capsule servies par `CadreVisage` ; il leur faudra : une forme imposée par leur place,
  `menu: null` sous 96, la photo de la vignette par `personneId`, et pour la capsule le nom masqué) ; les
  passages du §5 entre modes (grille vers ruban et retour) ; « Revenir à la page » (`BoutonIcone` posé au
  coin haut de début de la scène, `zone_support.dart`) peut encore toucher le coin du premier cadre.
- **À trancher par le directeur** : seul dans la salle, sa propre image n'est plus montrée (la règle dit
  « scène d'attente inchangée » et « jamais un objet flottant ») ; la borne de 480 et le plancher de 96 ;
  au plus petit téléphone (320 x 568), sept personnes passent en deux pages (trois colonnes de 96 n'y
  entrent pas).
- **Preuves** : `test/core/widgets/grille_visages_test.dart` (calcul : 1 à 12 personnes sur six écrans,
  widget : arrivée, départ, reconnexion, mouvement réduit, fenêtre, 12 en pages),
  `test/core/widgets/cadre_visage_test.dart`, `test/features/salle_seance/mode_scene_test.dart` ; tests de
  la salle verts. Captures de test : `docs/current/captures/E2E/scene-classe/` ; vraie application :
  `docs/current/captures/E2E/salle-banc/scene-classe-3/` et `scene-classe-6/`.

## D-031 (11/11/2026). Le ruban au téléphone et chez l'élève, et les passages entre modes (lot RUBAN-TELEPHONE, seconde moitié du modèle)

- **Demande** (directeur, 11/11) : « il faut que tout soit bien coordonné et ne pas agir comme des
  entités différentes. Pense aussi aux transitions si nécessaire. » Règle : `MODES-AFFICHAGE.md` §2 à §5.
  Revue : `docs/current/UX_REVIEW_RUBAN-TELEPHONE.md`.
- **Un seul cadre** : la vignette de l'enseignant chez l'élève, la capsule de l'enseignant au téléphone
  et la bande de côté passent par `CadreVisage`. `VignetteVideo` devient une enveloppe (largeur, rapport,
  clé `vignette-video`, toucher « voir en grand », barres du réseau dans le cadre). Dans `/salle`, le cadre
  est servi par la portée (`PorteeMediaSalle.cadre`, ajout) : c'est le cadre de la grille
  (`SceneClasse.cadreHorsGrille`), avec la parole écoutée sur le moteur. Ajouts compatibles au core :
  `CadreVisage.coin`, `libelleNom`, `detache` (filet du cadre posé seul sur la page, WCAG 1.4.11).
- **Le ruban** : élève au téléphone, toujours l'enseignant (le « Point 2 » du 30/10, vignette du camarade
  qui récite chez l'élève, est **remplacé** : `identiteVignetteRecitant` retiré de `salle_page.dart`) ;
  élève sur écran large, l'enseignant (bande de fin) puis le récitant (milieu de la bande de début), même
  taille, hors de la page ; enseignant au téléphone, la capsule montre le récitant en Document ou
  Tableau (`PorteeMediaSalle.identiteRecitant`, ajout), lui-même en Classe.
- **La capsule** (« reste à ranger » de D-027) : Réduire la salle · le cadre · Voir la classe (ou
  Revenir à la page), marge 8, écart 8, cibles 48. Le point vert ne se pose plus (il ne pouvait être que
  vert, A-01) ; rouge, il se poserait dans le cadre. Le profil déplié garde point et réseau.
- **Seul dans la salle** : caméra allumée, son propre cadre sous l'attente, 240 au plus, dans la colonne
  (tranche le point laissé ouvert par D-028, comme précisé le 11/11).
- **Passages** : `PassageVisages` (`lib/core/mouvement/passage_visages.dart`, nouveau) : grille qui part
  vers la place du ruban, vignette qui arrive en grandissant, page en fondu ; retour plus vite ; Document
  vers Tableau en fondu court. Version coordonnée, pas un vol (raison dans la revue). Ne se joue qu'à
  l'image où le mode change.
- **Phrases d'état** : « Caméra désactivée pour ce profil. » et le micro en attente passent en haut, sous
  l'île, avec le fond des pilules (`FondStatutSalle`), le temps des commandes, devant une page qui garde
  l'écran ; en Interface guidée et sur la scène elles restent au-dessus de la pilule (place réservée).
- **Flux** : un flux reçu de plus chez l'enseignant au téléphone pendant une récitation, deux au lieu
  d'un chez l'élève sur grand écran ; le repli réseau coupe les vidéos avant la voix.
- **À trancher par le directeur** : sur grand écran, la bande (enseignant et récitant) se masque avec les
  commandes à 3 s, comme la vignette depuis CORAN-ELEVE ; elle ne recouvre rien, elle pourrait rester.
  La feuille « Élèves » du téléphone garde des cartes sans image vivante (zone de l'autre lot).
- **Preuves** : `test/features/salle_ruban_telephone_test.dart` (40 tests : une personne un cadre, quatre
  rôles, 390, 820, 1440, Classe et Document ; ruban de l'élève ; capsule FR et AR, cibles, récitant ;
  seul avec et sans caméra ; passages : départ, arrivée, interrompu, mouvement réduit, masquage,
  reconnexion ; phrases en haut). Captures de test : `docs/current/captures/E2E/ruban-telephone/`. Pas
  de preuve dans la vraie application.

## D-030 (11/11/2026). Le ruban de l'enseignant sur ordinateur et les passages d'un mode à l'autre (lot RUBAN-ORDINATEUR, seconde moitié du modèle, ordinateur)

- **Demande** (directeur, 11/11/2026) : « il faut que tout soit bien coordonné et ne pas agir comme des
  entités différentes. Pense aussi aux transitions ». Règle : `MODES-AFFICHAGE.md` §4 et §5. Revue :
  `docs/current/UX_REVIEW_RUBAN-ORDINATEUR.md`.
- **Codé** :
  - **Le ruban** (`panneau_eleves.dart`) : en mode Document ou Tableau, chaque carte d'un élève dans la
    salle porte son cadre vivant (`CadreVivant`, qui sert `CadreVisage` et écoute seul la parole de sa
    personne), 96 x 72 en 4/3 ; l'élève qui récite passe en premier et son cadre prend la largeur de la
    carte. En mode Classe, les cartes gardent la photo ou l'initiale (les visages sont dans la grille).
    Tous les gestes restent (nom, état, réseau, dépliage, « Faire réciter », « Appeler », autorisation
    d'écrire). Le panneau ne connaît pas LiveKit : `VisagesPanneau` (image et parole par identité),
    construit par `salle_ordinateur.dart` depuis `PorteeMediaSalle.video` et le nouveau
    `PorteeMediaSalle.parle` (posé par `salle_page.dart`).
  - **L'enseignant** en tête du panneau : un `CadreVivant` (4/3, au plus le sixième de l'écran, centré :
    `tailleCadreEnseignant`) à la place de `VignetteVideo` ; le toucher garde son geste (changer de
    mode) et dit ce qu'il fait : « Voir la classe » (texte nouveau, `salle.ruban.voirLaClasse`) ou
    « Revenir à la page ».
  - **Les passages** : `PassageScene` (`lib/core/mouvement/passage_scene.dart`) autour du centre de
    l'ordinateur. Classe vers Document ou Tableau : la grille rétrécit (vers 90 %) et glisse vers le
    panneau en s'effaçant pendant que la page arrive en fondu, 240 ms ; dans le même temps, les cartes
    passent de l'initiale au cadre en grandissant en fondu (`_PassageCadre`). Retour : 160 ms. Document et
    Tableau : fondu court, jamais deux pages l'une sur l'autre. Interruptible (la grille revient de sa
    place sans être reconstruite), rien au montage ni à la reconnexion, fondu seul en mouvement réduit.
    **Ce n'est pas le vol des cadres de la grille vers leur carte** : version coordonnée (raisons dans la
    revue).
  - **« Revenir à la page »** vit sous la grille, au même endroit qu'« Ouvrir le Coran »
    (`ActionSousLaScene`), sur ordinateur et partout où `ZoneSupport` pose la scène.
  - **État unique** : `ZoneSupport._zone` et `identiteSupport` lisent `modeSceneDe` ; plus aucun test de
    `scenePremierPlan && scene != null` dans l'affichage. Écart visible, voulu : quand un tableau ou une
    page est demandé mais pas encore connu de la vue (un instant), la scène montre la classe au lieu de
    « rien de partagé » (l'ordinateur montrait déjà la classe au centre et `ZoneSupport` l'inverse :
    les deux disent la même chose maintenant).
  - **L'île dans la colonne** : le temps du chrono était mesuré au mauvais style et les signes
    n'étaient pas comptés (l'île débordait déjà sans signe). Élargir la colonne coûtait 66 points de
    hauteur à la page à 1440 x 900 : refusé. Repliée, l'île est bornée à la colonne
    (`PiluleEtatSalle.largeurRepliee`) et ses signes passent sous le chrono, place de deux lignes
    réservée (`largeurIleColonne`, `largeurChronoColonne`).
  - **Même tête pour les deux panneaux** : `TetePanneau` (core) ; la Bibliothèque garde la couleur de la
    marque (D-016), les Élèves la même pastille en surface neutre (« Élèves 6/6 », leur icône, la croix).
  - **Défaut trouvé en route** : `salle_page.dart` (`_avecFiches`) refaisait chaque élève sans son réseau
    ni son micro : les barres de réseau du panneau (RESEAU-ELEVES, D-017) ne s'affichaient jamais dès que
    la fiche était lue. Corrigé ; visible sur le banc (barres vertes dans les cartes).
- **Abonnement vidéo, mesuré au banc** : le moteur s'abonne à toutes les caméras dès l'entrée
  (abonnement automatique de LiveKit) ; `adaptiveStream` met en pause une piste sans rendu et choisit la
  couche selon la taille rendue. Page partagée, panneau fermé : 0 kbit/s de vidéo reçue (6 pistes en
  pause). Panneau ouvert (ruban) : 546 kbit/s à 6 élèves, 415 à 3, toutes à la plus petite couche
  (320 x 180, 10 à 16 images par seconde). La voix : aucune perte, aucune dissimulation avant comme après
  (tampon de gigue de 480-540 ms à 690-760 ms à 6 élèves sur la machine du banc chargée, 310 à 430 ms à
  3 : à surveiller, pas une perte). Les images sont déjà petites : rien de plus à demander au moteur.
- **Preuves** : `test/features/salle_seance/ruban_ordinateur_test.dart` (16 tests),
  `test/core/mouvement/passage_scene_test.dart` (5), tests voisins verts. Vraie application :
  `docs/current/captures/E2E/salle-banc/ruban-ordinateur-6/` et `ruban-ordinateur-3/` (02 classe, 07 page
  panneau fermé, 11 page avec le ruban). Captures de test : `docs/current/captures/E2E/ruban-ordinateur/`.
- **À trancher par le directeur** : panneau fermé en mode Document, aucun moyen de « Voir la classe »
  sur ordinateur (inchangé) ; faut-il le vrai vol des cadres ; la taille 96 x 72 des cadres du ruban.
