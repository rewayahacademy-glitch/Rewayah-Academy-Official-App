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
   la caméra doit-elle rester ?
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
