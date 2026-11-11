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
