# HANDOFF — à lire en premier, avant toute action

> 👪 **13 septembre 2026, neuvième session — `TUT-06` est fait, et un cours
> annulé ne dit plus rien de l'enfant.** Le tuteur ouvre `/tuteur/suivi` et lit
> les cours de ses enfants, du plus récent au plus ancien : la date, l'enfant,
> l'enseignant, et l'état de présence que `TUT-01` n'affiche jamais.
> **Il ne reste que TROIS écrans, DEUX dans le MVP-0** — le suivi élève,
> `ENS-05`, et `CPT-01` qui est hors MVP-0.
> 🔑 **Ce lot a d'abord dû trancher entre deux sources qui se contredisaient.**
> `parcours-utilisateurs.md` fait de `TUT-06` l'historique des **cahiers de
> transmission** — « ce qui a été travaillé, les points de phonétique » — et le
> cahier est `ENS-04`, étape 6, sans table ni format ; mais `0011`, en bornant
> `presence_seance_v`, écrit dans son propre corps que le tuteur y voit les
> participants de son foyer et que **c'est ce qui permettra à `TUT-06`
> d'exister**. Décision : construire ce que la base sait nourrir, et **ne rien
> poser pour le reste** — pas de colonne de contenu pédagogique remplie de
> tirets, pas de panneau de détail vide. ⚠ **Un espace réservé à un contenu
> absent se lit comme une panne**, et il se lirait ainsi à chaque ligne, tous
> les jours, jusqu'à l'étape 6.
> 🔍 **Ce que le lot a trouvé, et que rien ne signalait** : `etat_presence()` ne
> lit que les événements de salle. Un cours **annulé**, un cours où
> **l'enseignant** ne s'est pas présenté, un cours tombé en **panne** n'en ont
> produit aucun — la fonction en déduit une absence, ce qui est exact au sens de
> la base. Affiché tel quel au parent, cela lui dit que **son enfant était
> absent d'un cours que l'académie n'a pas donné**. ⚠ **La donnée n'était pas
> fausse ; la phrase, elle, l'aurait été.** Le sort du cours prime donc sur
> l'état de la personne. Un élève absent, lui, reste un cours tenu : c'est bien
> **sa** présence.
> ✅ **Aucune migration, et c'est le premier lot d'écran de l'étape 5 dans ce
> cas** : `0005` et `0011` avaient déjà tout ouvert, `scenarios_n4.sql` P5
> prouvait déjà la borne du foyer (2 enfants lus, 0 ligne hors foyer), et les
> **144 contrôles SQL sur neuf fichiers ne bougent pas**. Mesuré : **733/733**
> tests — dont **32 de ce lot**, le reste de l'écart venant du travail non
> commité d'OpenCode (section 5) —, `dart analyze --fatal-infos` propre,
> **124 fichiers de jetons** sans violation, `TUT-06` ajouté aux écrans vérifiés
> en RTL et à 200 % de taille de texte (19 → 20). ⚠ **Rien n'est déployé par ce lot** : la
> production porte toujours `6d06d39`. ⚠ **`Env.configuree` n'est toujours pas
> durci** — et `lib/core/config/env.dart` porte en ce moment le travail non
> commité d'OpenCode (Sentry) : ne pas le stager par mégarde. Commit `122b8e8`,
> poussé.
>
> ✅ **13 septembre 2026, tout à la fin de la huitième session — C'EST RÉPARÉ, ET
> LA CONNEXION EST PROUVÉE.** Reconstruit depuis `D:\ra-pwa-fix` et déployé : le
> `main.dart.js` servi fait **4 401 919** octets, ne contient **plus**
> `cle-factice` ni `_galerie`, contient la vraie clé `anon`, l'URL du projet,
> `madina-hafs-604` (`N5`) et `rejoindre_observation` (`CTR-01`). ⚠ **Et cette
> fois la connexion a été faite pour de vrai** : lien magique demandé depuis
> l'écran de production, reçu, suivi — l'espace tuteur s'ouvre avec les **données
> réelles de la base** (le foyer « Dynah », demande du 12/09). ⚠ **Un piège de
> déploiement en plus** : un worktree neuf n'a pas de lien Vercel, et
> `vercel deploy --prod` y **crée un projet nouveau** (`web`) au lieu de viser
> `rewayah-academy` — copier `.vercel\project.json` depuis
> `D:\ra-pwa-build\build\web` **avant** de déployer. Un projet parasite `web`
> traîne sur le compte Vercel, à supprimer. ⚠ Reste à faire : **durcir
> `Env.configuree`** (section 8). Le paragraphe ci-dessous décrit le défaut tel
> qu'il a été trouvé — conservé parce que sa leçon, elle, ne périme pas.
>
> 🔴 **Le défaut, tel qu'il a été trouvé — LA PRODUCTION NE POUVAIT PAS
> AUTHENTIFIER.** Elle était
> compilée avec une **clé Supabase factice**. Mesuré, pas supposé : le
> `main.dart.js` servi contient `cle-factice-playground-ne-jamais-utilisee` ;
> cette clé rend **401** sur l'API du projet quand la vraie clé `anon` rend
> **200**. `Env.configuree` ne teste que `isNotEmpty`, donc **une clé fausse mais
> non vide passe le garde-fou** : l'application démarre, affiche l'écran de
> connexion, console muette — c'est exactement ce que sept sessions ont
> « vérifié ». La cause est le fichier de compilation, pas le code :
> `D:\ra-pwa-build\dart_define.json` est la copie exacte du `dart_define.json` de
> **debug** du dépôt (clé factice, `GALERIE: true`, `PLAYGROUND: true`), et tout
> ce qui est compilé depuis ce worktree depuis le **11 septembre** porte cette
> clé **et expose `/_galerie`**. ⚠ **Cela réécrit une phrase qui traînait depuis
> six sessions** : « ce qui sépare la salle d'un vrai cours n'est plus qu'une
> mesure » était faux — la mesure était **impossible**. Correctif, contrôles et
> durcissement du garde-fou : **section 8**, et le prompt de reprise **§9.5**
> commence par là. Un worktree propre sur `090ae6f` est prêt en `D:\ra-pwa-fix`,
> dépendances résolues et `dart_define.json` correct déjà écrit ; **il ne
> manquait que la permission de lancer `flutter build`.**
>
> 📖 **13 septembre 2026, huitième session — `N5` est fait. Le Coran est dans le
> produit, et c'est un texte, pas un fichier.** Lot mené **en parallèle de
> `CTR-01`**, sur le même dépôt et en accord avec l'autre session.
> `/eleve/coran` ne rend plus `EcranAConstruire` : l'élève ouvre les **604 pages**
> du Mushaf de Médine, tourne les pages au doigt comme au bouton, retrouve sa
> place, et règle la taille du texte.
> 🔑 **Ce que ce lot a surtout fait, c'est trancher.** La question `a` du §10 de
> la spécification d'étape était ouverte depuis `N0` : l'ADR-020 avait fixé la
> **riwaya**, jamais la **source**. C'est l'**ADR-024**, et le critère est venu de
> l'opérateur : « la version qui propose le plus de flexibilité ». Cela désigne
> l'**import** et non l'API — l'API Quran Foundation interdit de conserver le
> contenu **plus de sept jours** (« Cache or store QF Content longer than
> 1 week »), exige une licence commerciale signée pour toute redistribution, et
> reste révocable « immediately and without liability ». Le Coran est le contenu
> du produit : le rendre périssable et révocable coûtait plus cher que l'import.
> Le corpus vient donc du **Tanzil Project** (CC BY 3.0), et il est en base.
> ✅ **Mesuré, pas supposé** : `flutter test` **692/692** (22 nouveaux),
> `dart analyze --fatal-infos` **propre sur tout le dépôt**, jetons **120
> fichiers** sans violation, **134 contrôles SQL** (125 + 9) rejoués ensemble sur
> `0001`→`0013` dans une base neuve, et la migration `0013` **appliquée en
> production**, qui porte **114 sourates, 30 juz, 604 pages, 6236 versets**.
> 🔍 **La production n'a pas reçu le fichier, elle a reçu le même corpus, et
> l'identité est prouvée par deux empreintes.** Faire transiter 1,48 Mo de SQL
> par un appel d'outil était hors de question ; la base a donc lu le corpus à sa
> source, et le résultat a été comparé au fichier versionné **avant** toute
> écriture : `md5` du texte `04b9f93c…a49d` et `md5` de la pagination
> `c43df346…c973`, **identiques des deux côtés**. Les deux empreintes sont
> réinscrites dans les contrôles de la migration appliquée : un import complet
> mais d'une **autre édition** passerait tous les comptages sans que rien ne le
> signale. ⚠ L'extension `http`, créée pour cet import, a été **retirée** :
> laissée en place, elle donne à tout ce qui peut exécuter du SQL le droit
> d'émettre des requêtes sortantes depuis la base.
> ⚠ **DEUX ÉCARTS ASSUMÉS, écrits plutôt que masqués.**
> **Un. `verset.ligne` reste NULLE, et ce n'est pas un oubli.** Le découpage en
> quinze lignes par page existe (layout QPC v2 du Quranic Universal Library),
> mais il **compte les mots autrement que le texte Tanzil** : **83 668 contre
> 77 881**, mesuré et non supposé. Les faire coïncider demanderait de deviner une
> correspondance sur un texte sacré. `0007` autorise la colonne nulle, rien à
> l'écran n'en dépend, et elle se remplira le jour où une source portera le texte
> **et** ses lignes.
> **Deux. Le lien vers tanzil.net n'est pas cliquable.** La licence exige que la
> source soit clairement indiquée et jointe ; elle l'est, au pied de **chaque
> page**, dans le flux — mais `url_launcher` n'est pas au `pubspec.yaml`, et
> l'y ajouter demandait de toucher un fichier qu'OpenCode modifie. C'est une
> ligne, le jour où le `pubspec` est libre.
> 🧭 **Une décision de conception à ne pas rouvrir** : la navigation de page
> **n'est pas un contrôle secondaire**. §5.3 demande de masquer les contrôles
> secondaires derrière un tap, et c'est fait — pour la taille du texte. Masquer
> aussi « page suivante » laisserait le clavier et les lecteurs d'écran sans
> aucun moyen d'avancer, le balayage étant le seul recours.
> 🔴 **CE QUI N'EST TOUJOURS PAS PROUVÉ : un vrai cours.** Inchangé par ce lot.
>
> 🕵️ **13 septembre 2026, huitième session — `CTR-01` est fait, et le contrôle
> invisible était impossible.** Lot mené **en parallèle du lot N5**, sur le même
> dépôt et en accord avec l'autre session : elle a livré `ELV-04`, celui-ci
> `CTR-01`. Le planning global du contrôle qualité existe : `/controleur` ne rend
> plus `EcranAConstruire` mais la liste des séances en cours et à venir, heure
> locale **et** heure UTC, filtres par état et par enseignant, et un bouton
> d'entrée invisible sur les seules lignes qui ont lieu maintenant.
> 🔴 **Le lot a trouvé trois défauts, aucun visible, et le premier rendait
> `CTR-02` inatteignable depuis sa construction.**
> **Un.** Rien, nulle part, n'inscrivait jamais de ligne `masked_controller` dans
> `session_participants` : l'enum l'a depuis `0001`, `autoriser_jeton_video()` en
> déduit `hidden` depuis `0010`, `presence_seance_v` la cache depuis `0011` —
> mais aucune fonction ne l'écrivait. Un contrôleur qui pressait « Observer »
> aurait reçu « non inscrit a cette seance ». **La plomberie de N2 et l'écran de
> N3 attendaient une porte que personne n'avait posée.**
> **Deux.** Le plafond de participants du MVP-0 — deux — **comptait les témoins
> comme des élèves**. Un cours 1-to-1 est donc plein : le contrôleur ET le tuteur
> observateur étaient refusés par le déclencheur avant même d'atteindre le jeton.
> Conséquence non théorique : **le bouton « Assister » de `TUT-01` est en
> production depuis l'étape 4 et échouait silencieusement** — le parent arrivait
> dans l'impasse d'accès de la salle. La spécification d'étape 5 §9 écrivait
> pourtant la règle : « le 1-to-1, **le contrôleur en plus** ». Le plafond borne
> le **groupe pédagogique**, pas l'assistance.
> **Trois.** L'invisibilité s'arrêtait à la vidéo et à la présence. Restaient
> `session_peers_v`, la table `session_participants` (policies enseignant et
> foyer) et `session_events` : trois surfaces lisibles depuis un navigateur
> authentifié, où la visite s'écrivait en toutes lettres. ⚠ **Une invisibilité se
> vérifie sur CHAQUE surface** — la leçon de N4, une seconde fois.
> Livré : la migration **`0012`** (le plafond, C2, `session_peers_v`, six
> policies, `est_observateur_masque()`, `rejoindre_observation()` et
> `assister_seance()`), `lib/core/controle/`, `lib/features/controleur/`
> (`VuePlanning.depuis`, fonction pure comme `VueSalle.depuis`), les deux portes
> d'inscription sur `ServiceVideo`, et **le bouton « Assister » de `TUT-01`
> enfin câblé**.
> ⚠ **DEUX PIÈGES À NE PAS ROUVRIR, tous deux mesurés pendant le lot, pas
> devinés.**
> **Un `create or replace` part du corps COURANT de l'objet, jamais de la
> migration qui l'a créé.** La première écriture de `0012` est repartie de `0001`
> pour `guard_session_overlap()` et a donc effacé le correctif 3.9 de `0005`
> (bornes `'[)'`) : `scenarios_etape4.sql` est passé de vert à « S3 ECHEC : 3
> prises au lieu de 4 », une prise sur deux refusée. **C'est l'autre session qui
> l'a détecté**, en rejouant la chaîne complète.
> **Une policy RLS qui interroge une table protégée par RLS ne voit que ce que
> l'appelant voit.** Le `not exists (select ... from session_participants ...)`
> écrit directement dans les policies de `session_events` ne trouvait jamais rien
> — les policies de `session_participants` venaient de fermer ces lignes — donc
> l'enseignant lisait quand même les événements de la visite. Le pont doit être
> une fonction `security definer`, exactement comme `session_belongs_to_teacher`
> en `0001`.
> Mesuré, pas supposé : **`dart analyze --fatal-infos` propre**, `verifier_jetons`
> **120 fichiers** sans violation, **24 tests neufs verts** (13 unitaires sur la
> vue pure, 11 d'écran), et **les neuf fichiers de scénarios SQL rejoués ensemble
> sur une base neuve `0001`→`0013`, tous verts**, dont les **10 contrôles** de
> `scenarios_ctr01.sql`.
> 🔴 **CE QUI N'EST TOUJOURS PAS PROUVÉ : un vrai cours.** Toujours aucune séance
> en base. Mais depuis ce lot, **les trois portes d'entrée de la salle existent
> enfin toutes les trois** : l'enseignant (`ENS-02`, lot N3), le tuteur
> (`TUT-01`, réparé ici) et le contrôleur (`CTR-01`).
>
> 🧭 **13 septembre 2026, septième session — `N4` est fait. La présence
> s'affiche.**
> Le calcul des quatorze états était en base depuis `N1`, et le quatorzième
> depuis `N2` ; il n'avait **aucun écran**. Il en a un : l'élève lit son propre
> état, en permanence et en mots, sous la pastille de connexion ; l'enseignant
> et le contrôleur lisent le tableau des **inscrits** — en colonne sur tablette,
> en feuille sur téléphone. Livré : `lib/core/presence/` (`EtatPresence` à
> quatorze valeurs plus l'inconnu, `PresenceParticipant`, le service, et
> `VuePresence.depuis` — fonction pure comme `VueSalle.depuis`), le composant
> `LignePresence` au catalogue et à la galerie, et la migration **`0011`**.
> 🔴 **Le lot a trouvé deux défauts, et aucun des deux ne se voyait.**
> **Le premier : `presence_seance_v` n'avait aucun filtre d'appelant.** Les
> trois vues d'exposition de `0001` en portent toutes un, et ce n'est pas
> décoratif — une vue appartenant à `postgres` sans `security_invoker` ne voit
> pas la RLS des tables qu'elle lit. Chiffré, pas supposé : sur les fixtures de
> `scenarios_n4.sql`, un élève inscrit à **aucune** des deux séances y lisait
> **6 lignes sur 6** ; il en lit **0** après `0011`. Rien n'a fuité (zéro séance
> en base), et le défaut n'avait jamais été exercé **parce qu'aucun écran ne
> lisait la vue**. C'est la leçon de `N3` une seconde fois : **une vue sans
> écran est une vue non testée.**
> **Le second : l'invisibilité du contrôleur s'arrêtait à la vidéo.** Le jeton
> porte `hidden`, LiveKit masque la personne, et `N3` la retire même de sa
> propre liste — mais la présence l'écrivait en toutes lettres : l'enseignant y
> aurait lu une quatrième ligne, « masked_controller, présente ». Seule
> l'administration la lit désormais, pas même l'intéressé.
> 🔵 **Et un troisième, mesuré par les tests :** le flux de présence, écrit en
> `async*` avec un `Future.delayed`, laissait une attente en vie après la sortie
> de la salle — rien ne pouvait l'interrompre. `flutter test` l'a dit d'un arbre
> démonté (« A Timer is still pending ») ; c'est vrai d'un élève qui a quitté le
> cours. Remplacé par une minuterie annulée à `ref.onDispose`.
> Mesuré, pas supposé : **`flutter test` 646/646** (25 nouveaux),
> `dart analyze --fatal-infos` propre, jetons **113 fichiers** sans violation,
> **125 contrôles SQL** verts (116 + **9**) rejoués ensemble sur `0001`→`0011`
> dans une base neuve, migration `0011` **appliquée en production**, et la
> **production ouverte, console lue** : zéro erreur, session admin restaurée,
> `/#/salle` tapée à la main redirige toujours vers la racine du rôle (ADR-005).
> La vue elle-même interrogée depuis le navigateur authentifié : **`200` avec
> ses treize colonnes**, ce qui écarte le piège `42703` qui traverse la RLS.
> Bundle : 4 312 086 → **4 325 111** octets (+0,3 %).
> ⚠ **Deux écarts assumés, écrits plutôt que masqués** : le **geste** de
> correction manuelle (`corrigee_manuel`) et le marquage `excusee` ne sont pas
> construits — la table et ses policies existent depuis `0007`, mais l'écran qui
> les déclenche demande confirmation, motif obligatoire et entrée de journal :
> c'est un lot, pas une ligne, et §6.5 laisse ce mécanisme explicitement ouvert.
> Et le **tuteur observateur ne lit ni sa présence ni la liste** : il assiste, il
> n'est pas noté, et le suivi d'un enfant est `TUT-06`, à l'étape 6.
> 🔴 **CE QUI N'EST TOUJOURS PAS PROUVÉ : un vrai cours.** Personne n'a encore
> ouvert deux navigateurs sur une même séance. Il n'existe **aucune séance en
> base** — c'est ce qui rend la mesure possible aussi vite qu'on le décide, et
> c'est la seule qui vaille maintenant.
>
> 🏫 **12 septembre 2026, sixième session — `N3` est fait. La salle existe.**
> Le plus gros `EcranAConstruire` du routeur est remplacé : `/salle` rend
> désormais un écran, et c'est **un seul écran pour trois codes**
> (`ELV-03`/`ENS-03`/`CTR-02`) **et quatre rôles**. Ce qui les distingue ne vient
> pas de la session, que le client porte, mais du **jeton** : son `role` et ses
> capacités signées. Le quatrième rôle manquait au catalogue :
> `guardian_observer`, le tuteur qui presse « Assister » depuis `TUT-01`, entre
> muet et **visible**, là où le contrôleur entre invisible.
> Livré : `lib/features/salle/` (la vue pure `VueSalle` et l'écran),
> `PageImmersive` dans `lib/core/widgets/` — la coquille des écrans sans page,
> qui servira aussi à `ELV-04` —, le contrat `renduVideo()` sur
> `VideoSessionProvider` (l'écran reçoit un widget déjà monté, jamais une piste :
> c'est ainsi que l'ADR-001 survit au rendu), le `moteurSalleProvider`, et le
> **bouton de lancement de `ENS-02`**, sans lequel l'enseignant n'aurait jamais
> pu entrer.
> Mesuré, pas supposé : **`flutter test` 621/621** (45 nouveaux),
> `dart analyze --fatal-infos` propre, jetons **110 fichiers** sans violation,
> **production ouverte et console lue** — session admin restaurée, tableau de
> bord rendu, zéro erreur, et `/#/salle` tapée à la main redirige bien vers la
> racine du rôle (ADR-005 tient en production).
> 🔴 **Un défaut de `N2` est corrigé, et il ne se voyait pas** :
> `rejoindre()` ouvrait le micro dès l'entrée — « la voix d'abord ». C'était
> contraire à l'invariant écrit deux fois dans la fiche produit et au catalogue
> depuis la refonte : **à l'entrée, rien ne publie, pour aucun rôle**. Aucun
> écran n'existait alors pour l'exercer, donc rien ne l'avait signalé. Leçon :
> **une plomberie sans écran est une plomberie non testée.**
> 📈 **Le vrai coût de `flutter_webrtc` est mesuré** : le module vidéo n'est plus
> élagué, le bundle passe de 3 833 921 à **4 312 086 octets** (+12,5 %).
> ✅ **LiveKit est branché, et ce lot l'a re-vérifié lui-même.**
> `create-room-token`, interrogée par HTTP avec la clé anon, répond
> **`401 authentification requise`** et non plus `503 video non configuree` : la
> fonction testant `videoConfiguree()` **avant** l'authentification, les trois
> secrets sont donc bien posés sur Supabase. La salle ne tombera plus sur
> « La salle n'est pas encore disponible ».
> 🔴 **CE QUI N'EST TOUJOURS PAS PROUVÉ : un vrai cours.** Personne n'a encore
> ouvert deux navigateurs sur une même séance. Restent en angle mort l'URL
> `LIVEKIT_CLOUD_WS_URL`, que rien ne valide, et la clé qui signe le webhook.
> **La première vraie mesure de bout en bout est un cours — et depuis ce lot,
> elle est possible.**
> ⚠ **Deux écarts assumés, écrits plutôt que masqués** : la sortie de `ENS-03`
> mène à `ENS-02` et non à `ENS-04`, qui est l'étape 6 et n'a aucune route ; et
> le **document partagé n'est pas construit**, faute de contenu à paginer (le
> Coran est `N5`) et de canal de diffusion tranché (question `e` du §10 de la
> spécification d'étape). Le bouton « Ouvrir le Coran » **n'existe pas** plutôt
> que d'être grisé.
>
> 🎥 **12 septembre 2026, cinquième session — `N2` est fait. La vidéo a son
> squelette complet, et il ne lui manque qu'un compte.**
> L'opérateur a débloqué le lot et tranché la question que ni l'ADR-001 ni la
> spécification d'intégration ne tranchaient de la même façon : **les deux
> fournisseurs coexistent** — LiveKit Cloud pour éprouver, auto-hébergé pour
> encaisser la charge, **jamais Cloud seul, parce que c'est cher**. C'est
> l'**ADR-023**, et il renforce le contrat de portabilité de l'ADR-001 au lieu
> de l'assouplir.
> Livré : migration **`0010`** (quatre tables, cinq fonctions, aucune policy
> d'écriture ouverte au client), les fonctions Edge **`create-room-token`** et
> **`livekit-webhook`** — **déployées, `ACTIVE`, et appelées en production pour
> le vérifier** —, et le module Flutter `lib/core/video/` : interface
> `VideoSessionProvider`, implémentation `LiveKitSessionProvider`, service
> d'accès, pré-vol.
> Mesuré, pas supposé : **`flutter test` 576/576** (13 nouveaux),
> `dart analyze --fatal-infos` propre, jetons **107 fichiers** sans violation,
> **116 contrôles SQL** verts (34 + 39 + 15 + 9 + **10** + 9) rejoués ensemble
> sur `0001`→`0010` dans un conteneur neuf, et les deux fonctions Edge
> interrogées par HTTP : `401 signature invalide` pour le webhook,
> `503 video non configuree` pour l'émission.
> 🔑 **Ce que le lot a vraiment débloqué** : `etat_presence()` ne dérivait que
> treize des quatorze états. `en_connexion` manquait, et N1 avait refusé de
> l'inventer faute de trace en base. `video_token_grants` est cette trace : le
> quatorzième état se dérive désormais, et c'est la première brique de présence
> **non falsifiable par le client**.
> 🔴 **CE QUI N'EST PAS PROUVÉ, et il faut le dire tel quel : la connexion
> réelle à une salle.** Aucun compte LiveKit n'existe. Tout le reste est mesuré,
> mais le premier vrai cours reste la première vraie mesure de bout en bout.
> **Trois secrets à poser et un webhook à déclarer, recette complète en
> `MISE-EN-SERVICE.md` §8** — aucun redéploiement d'application ne sera
> nécessaire, le client n'a aucune URL en dur.
> ⚠ **Une affirmation de cette page était fausse et elle est corrigée** : le
> commit `c2e52d2` annonçait « OpenCode a déjà commencé N2 ». Non. Les fichiers
> qu'il décrivait (`0010`, `scenarios_n2.sql`, `livekit_client`, `ci.yml`)
> étaient le travail **non encore commité de cette session-ci**, observé depuis
> une autre session. Aucun code vidéo n'a jamais été suivi par git avant ce
> lot. **Leçon générale : des fichiers non commités dans un dépôt partagé ne
> disent pas qui les a écrits.**
>
> 🔴 **12 septembre 2026, quatrième session — la production était cassée depuis
> la nuit, elle est réparée, et la cause de fond est corrigée.** L'opérateur :
> « l'app ne marche plus depuis la nuit. » Écran gris, `LateInitializationError`
> levé dans un provider. **Cause mesurée : le bundle en ligne ne contenait
> aucune configuration Supabase** — zéro occurrence de `gggmtelinlpseweouyav`.
> Il avait été compilé par `flutter build web --release` **sans
> `--dart-define-from-file=dart_define.json`** : `Env.supabaseUrl` et
> `Env.supabaseAnonKey` sont des `String.fromEnvironment`, ils valaient donc la
> chaîne vide, et `Supabase.initialize` n'était jamais appelé. **Trois
> déploiements de suite étaient partis ainsi** (06:08, 13:26, 14:32), tous par
> des agents.
> ✅ **Réparé et vérifié à l'écran, pas déduit** : la production sert un bundle
> configuré, la session admin se restaure, `/admin/tableau-de-bord` rend ses
> chiffres lus en base, zéro erreur console.
> 🔴 **Le défaut qui a rendu la panne muette est corrigé (`6404843`)** : le
> garde-fou de `main.dart` était un `assert`, **inexistant en release**, si bien
> qu'une compilation sans clés démarrait normalement pour mourir plus loin.
> `!Env.configuree` affiche désormais `EcranConfigurationAbsente`, qui nomme ce
> qui manque et donne la commande qui répare. Prouvé sur **deux** builds
> release : avec clés l'écran est tree-shaké (aucune graisse en production),
> sans clés il apparaît et le bundle tombe à 2,4 Mo contre 3,8.
> `flutter test` **563/563**, jetons **103 fichiers**, `dart analyze` propre.
> ⚠ **Un `assert` n'est pas un garde-fou**, et une suite de tests ne prouve rien
> d'un comportement de release : elle tourne en VM debug, où l'`assert` existe
> encore. ⚠ **Chercher une chaîne du dernier lot dans le bundle servi ne suffit
> pas** : le bundle mort du 14:32 contenait bien `Journal intact`. Le seul
> contrôle qui vaut est d'**ouvrir l'application et de lire la console**.
> 🎥 **N2 est débloqué.** L'opérateur a demandé le prompt d'implémentation du
> fournisseur vidéo : **c'est le prochain lot**, et le seul qui justifie
> d'ouvrir `D:\RA _APP\docs de lancement\architecture live kit..md`.
> ⚠ OpenCode a déjà ajouté `livekit_client: ^2.12.0` à son `pubspec.yaml` non
> commité, en même temps qu'un Playground : **se concerter avant de coder N2.**
>
> 🟢 **12 septembre 2026, troisième session — `ADM-04`, le journal d'audit,
> est construit. L'espace admin n'a plus un seul écran manquant.** L'opérateur
> a de nouveau demandé de laisser la vidéo de côté : N2 reste non commencé, et
> `ADM-04` était le premier lot libre par valeur décroissante (section 9.5 de
> la passation précédente). **Il reste neuf destinations en
> `EcranAConstruire`** — élève (Coran, Suivi), tuteur (Suivi), enseignant
> (Profil), contrôleur (Planning), espace comptable, et `ELV-03`/`ENS-03`/`CTR-02`,
> la salle.
> ✅ **Les trois migrations en attente sont posées, et la quatrième aussi.**
> L'opérateur a appliqué `0006`, `0007` et `0008` lui-même, puis a repointé le
> MCP `supabase` sur Rewayah (`gggmtelinlpseweouyav`) et donné mandat
> d'appliquer les suivantes directement. **`0009` a donc été appliquée par
> l'agent, et vérifiée sur la base réelle.** Plus aucune migration n'attend une
> main humaine. ⚠ Le réflexe `get_project_url` avant toute écriture reste.
> Livré : migration `0009` (trois fonctions de lecture, aucune table),
> `lib/core/journal/service_journal.dart`, `lib/features/admin_journal/`,
> **`DataCollection`** (P1 du catalogue, jamais construit jusqu'ici),
> **`FilterPill`**, **ADR-022**, fiche `ADM-04` au catalogue.
> Mesuré, pas supposé : **`flutter test` 559/559** (542 avant le lot),
> `dart analyze --fatal-infos` propre, jetons **102 fichiers** sans violation,
> et **106 contrôles SQL** verts (34 + 39 + 15 + 9 + 9) rejoués ensemble sur
> `0001`→`0009` dans un conteneur neuf.
> 🔑 **Ce que ce lot a vraiment débloqué, au-delà d'un écran** : `audit_logs`
> portait `prev_hash`/`hash` depuis l'étape 1, et chaque écriture du produit
> payait un `lock table` pour les tenir — **sans que personne ne les relise
> jamais**. Le prix était payé, la garantie jamais constatée. Elle l'est
> maintenant : 34 entrées sur 34 se recalculent sur la base réelle, et deux
> scénarios SQL falsifient délibérément le journal (un `update`, un `delete`)
> pour vérifier que chacun se voit **à un endroit différent** — le condensat
> pour la modification, le maillon pour la suppression.
> ⚠ **Deux décisions ont été prises sans l'opérateur, toutes deux réversibles**,
> questions **27** et **28** du registre : la consultation du journal ne
> s'inscrit pas au journal (ADR-022, décision 4 — recette pour l'inverser en
> une heure), et `DataCollection` porte sa propre zone défilante.
>
> 🟡 **12 septembre 2026, deuxième session — `ADM-05`, l'attribution manuelle,
> est construite.** L'opérateur a demandé de **laisser le fournisseur vidéo de
> côté** et d'avancer ailleurs en attendant : le lot N2 reste donc non
> commencé, et `ADM-05` a été fait hors série. Ce n'est pas un écran de plus :
> **c'était le chaînon manquant du produit.** Sans lui, une affectation ne
> pouvait naître que si un enseignant la demandait dans `ENS-06` ; sans
> affectation, `materialiser_seances()` n'est jamais appelée ; sans séance,
> `ENS-02`, `ELV-02` et `TUT-01` restent vides quoi qu'ait construit l'étape 4.
> Le compteur « Foyers sans enseignant » d'`ADM-01`, qui ne menait nulle part,
> mène maintenant à son geste.
> Livré : migration `0008` (trois fonctions, aucune table, aucune policy
> d'écriture ouverte), `lib/core/matching/service_attribution.dart`,
> `lib/features/admin_attribution/`, **ADR-021**, fiche `ADM-05` au catalogue.
> Mesuré, pas supposé : **`flutter test` 542/542**, `dart analyze` propre,
> jetons **98 fichiers** sans violation, et **97 contrôles SQL** verts
> (34 + 39 + 15 + 9) rejoués ensemble sur `0001`→`0008`.
> ⚠ **Une décision a été prise sans l'opérateur, et elle est réversible** :
> l'administration peut attribuer hors des disponibilités déclarées d'un
> enseignant, **avec motif obligatoire vérifié en base** et journalisation.
> Raison, et la recette pour la défaire en une heure : **ADR-021**, plus les
> questions 25 et 26 du registre.
> ⚠ ~~**`0008` doit être collée à la base réelle**~~ — **fait par l'opérateur,
> vérifié par PostgREST le 12/09 en troisième session.** `0006`, `0007` et
> `0008` sont toutes les trois en base. Cet avertissement est clos.
>
> 🔴 **12 septembre 2026, première session — le verdict de l'opérateur est
> vérifié, chiffré, et il avait raison.** « L'app est loin d'être fonctionnelle » : mesuré en
> ouvrant la production en session admin, pas déduit. **Onze destinations du
> routeur sur trente rendent `EcranAConstruire`** — dont `ELV-03 / ENS-03`,
> c'est-à-dire la salle de cours elle-même, le produit. Côté admin, deux des
> quatre entrées de navigation (Attribution, Journal) affichent « Cet écran
> arrive à l'étape 3 », et les deux autres sont vides. **Ce n'est pas une
> régression : c'est que l'étape 5 n'était pas commencée.** Le détail écran par
> écran est en section 9.
> ✅ **Le lot N1 est fait le même jour** (`a736a43`) : migration `0007`, le
> Coran structuré, la position de lecture personnelle, la présence dérivée à
> quatorze états. Quinze contrôles verts, non-régression des étapes 3 (34) et
> 4 (39) vérifiée. **Le découpage N0→N7 est confirmé** par l'opérateur.
> ⚠ **Deux actions restent à sa main, et rien n'avance sans elles** : coller
> `0006` **et** `0007` dans l'éditeur SQL du projet `gggmtelinlpseweouyav`
> (`MISE-EN-SERVICE.md` §5, §5.1, §5.2), et promouvoir la build prête en
> production (section 9). `0006` est toujours absente de la base réelle,
> mesuré ce jour par PostgREST.
> ⚠ ~~**Le serveur MCP `supabase` de ce poste pointe sur la base PISI**~~ —
> **corrigé le 12/09.** Il vise désormais Rewayah (`gggmtelinlpseweouyav`),
> vérifié par `get_project_url`, et l'opérateur a donné mandat d'appliquer les
> migrations directement. Garder le réflexe : `get_project_url` **avant** toute
> écriture, la bascule s'est déjà produite une fois.

> Dernière passation : **11 septembre 2026, huitième session — la dette de
> vérification est soldée.** Le lot **L10** (clôture de l'étape 4) est fait :
> section 0 decies. **L'ordre de travail de l'ADR-019 est entièrement épuisé** —
> B0, T2, R0, T3, R4, A1 (les six lots de code) et N0 (documentaire) sont
> poussés.
> ✅ **`flutter test` a enfin tourné, pour la première fois en neuf sessions.**
> Le blocage TLS de `github.com` (hook `package:sqlite3`,
> `CERTIFICATE_VERIFY_FAILED`) **est toujours là et n'a pas été réparé** : il a
> été **contourné** par le `user_define` `source: system` que le paquet
> documente lui-même, posé uniquement dans le worktree détaché
> `D:\ra-pwa-build`, jamais commité, retiré après la mesure. Méthode et
> précautions : **section 0 undecies**.
> **Ce que la mesure a trouvé : aucune régression de production.** 515 verts,
> 19 rouges au départ ; sept tests périmés, neuf mesurés sur une fenêtre
> 800 × 600 (gabarit tablette, plus court que tout téléphone) et trois vrais
> défauts, dont `Échap` qui ne fermait aucune modale. Tout est corrigé :
> **534 verts, 1 rouge**, `dart analyze --fatal-infos` propre,
> `verifier_jetons.dart` 96 fichiers sans violation. Le rouge restant est une
> bombe à retardement horaire sans rapport avec la refonte, décrite en fin de
> section 0 undecies.
> **Découverte de cette session, sans rapport avec L10 lui-même, et déjà
> résolue** : la production servait `a9127fd` (lot R3, déployé le
> 8 septembre), onze commits de retard sur `main` — pas `c5a511f`/L8 comme
> l'affirmait à tort cette page depuis plusieurs sessions. **Comblé dans la
> même session, sur autorisation explicite de l'opérateur** : la production
> sert désormais `ad21990`, confirmé par l'API Vercel. Détail section
> 0 decies et `PROGRESS.md` ligne M.
> Dernier commit **poussé** de `main` avant cette session : `39aec71`.
> `git log --oneline -5` doit correspondre exactement à `origin/main`.
> Détail du lot R4 : section 0 septies. Deux écarts de conception restent
> ouverts et non tranchés, sur `ADM-01`/`ADM-06` (six compteurs contre cinq
> annoncés, ordre signaux/chiffres) — pas des écrans de R4, voir fiche `ADM-01`
> section 6 de `08-catalogue-ecrans.md`. Détail du lot A1 : section 0 octies.
> Détail du lot N0 : section 0 novies. Détail du lot L10 : section 0 decies.

## 0. Ce qui a changé le 7 septembre au soir : la refonte UX/UI

L'opérateur a jugé le premier rendu visuel daté, et a demandé qu'on **arrête
d'ajouter des écrans pour poser d'abord un langage**. C'est fait, en
documentation : **`docs/design/`**, neuf fichiers, plus l'**ADR-018** dans
`decisions.md` et une réécriture de `docs/produit/design-tokens.md`.

Trois conséquences immédiates pour vous :

1. **`docs/design/README.md` se lit avant d'ouvrir un fichier d'écran.** C'est la
   constitution : hiérarchie des sources de vérité, les huit documents, les
   interdits, et surtout la liste de ce que la note de refonte demandait **et qui
   existe déjà** — plusieurs points y sont tranchés dans l'autre sens, ne les
   « corrigez » pas.
2. **Aucun écran ne s'implémente s'il n'est pas dans
   `docs/design/08-catalogue-ecrans.md`.**
3. **Le tableau de jetons d'`etape-2-core-flutter.md` §1 est périmé.** La source
   unique des valeurs est `docs/produit/design-tokens.md`.

### 0 bis. Le lot T est fait : le code porte les nouveaux jetons

Le thème a été remplacé le 7 septembre. Compte rendu complet dans
`docs/architecture/etape-2-journal.md`, section « Refonte UX/UI, lot T ».

Ce que ça change pour vous, en quatre points :

1. **Le vocabulaire des jetons a changé, et l'ancien est refusé par l'outil.**
   `surfaceBase`, `borderDefault`, `textOnLightAccent`, `textOnLightAlert`,
   `NotoSans` et `VarelaRound` font échouer `verifier_jetons.dart`. La
   correspondance est dans `design-tokens.md` §1.8.
2. **Trois nouveaux fichiers de thème** : `app_radius.dart`,
   `app_elevation.dart`, `app_mouvement.dart`. Un rayon, une ombre, une durée
   d'animation ou une courbe posés ailleurs sont refusés.
3. **Le produit a le bon vocabulaire, pas encore la bonne profondeur.** Les
   composants ont été renommés, pas repris : une tuile Bento est toujours posée
   sur `surfaceCanvas` au lieu de `surfaceRaised`, et rien ne porte encore
   d'ombre. C'est le **lot C** qui reprend les usages, et c'est voulu.
4. **Deux chiffres de `design-tokens.md` étaient faux** et ont été corrigés par
   la mesure : blanc sur le fond général vaut 1,10 et non 1,19, et l'axe `opsz`
   de Bricolage Grotesque a pour défaut 96 et non 14. Les valeurs sont
   désormais rejouées par les tests : le document ne peut plus dériver seul.

### 0 ter. Le rendu déployé jugé « plus nul que du générique » : la Bible V2 et le lot B0

Le 11 septembre 2026, l'opérateur a vu le rendu mobile déployé (build de `main`
post-lot R3 poussé sur `rewayah-academy.vercel.app`) et l'a jugé pire que le
générique habituel. Il a remis une **deuxième** Bible frontend, plus stricte et
plus complète que la note du 7 septembre, avec l'instruction explicite qu'elle
ne se redonnera pas une troisième fois.

**Trois causes mesurées dans le code** (pas seulement une impression) :

1. **Le tunnel d'entrée n'a jamais été repris.** `connexion_page.dart` montait
   (avant B0, toujours vrai après B0 : B0 ne touche à aucun écran) un
   `Scaffold` nu — pas de `PageShell`, pas de carte, pas d'ombre, pas de marque.
   C'est le seul écran visible sans compte : tout ce que l'opérateur a vu.
2. **Le bouton `ActionPrincipale` désactivé ressemblait à une panne** : peint
   `surfaceSunken` + `inkMuted`, il pesait moins que les boutons secondaires à
   contour. Toujours vrai après B0.
3. **Le langage visuel était trop timide** : ombres à 5 % d'opacité,
   `borderHairline` à 1,20:1, les trois surfaces dans 4 % de clarté. Toujours
   vrai après B0.

**Ce que B0 a fait, le 11 septembre : rendre la Bible permanente, sans toucher
à un seul pixel d'écran.** Trois couches, pour qu'elle survive au changement de
session ET au changement d'outil (OpenCode, Hermes) :

1. **`docs/design/00-bible-frontend-v2.md`** — le texte intégral, copié sans
   modification, adopté par **ADR-019**. `docs/design/README.md` §4 BIS porte
   la table de correspondance chapitre par chapitre : ce qui est déjà tenu
   (souvent mieux qu'exigé, via `verifier_jetons.dart`), ce qui est tranché
   autrement pour une raison écrite (deux dérogations dans ADR-019), ce qui
   reste un écart et son lot.
2. **Trois chapitres absents du corpus, ajoutés** : la matrice de décision de
   conteneur dans `02-regles-ux.md` §11, le zoning physique en cinq zones dans
   `05-regles-responsive.md` §9, la classification état métier/UI/préférence
   dans `03-architecture-information.md` §8.
3. **Trois règles neuves dans `tool/verifier_jetons.dart`**, chacune prouvée en
   la faisant échouer sur un fichier piège avant d'être acquise (95 fichiers
   vérifiés, méthode déjà utilisée pour les 26 règles précédentes) :
   - `direction-non-geree` — a trouvé et fait corriger **six** occurrences
     réelles de `left`/`right` codés en dur (pas seulement les deux repérées à
     l'audit initial) : `grille_semaine.dart`, `creneaux_page.dart` (deux
     endroits différents), `admin_demandes/demandes_page.dart`,
     `eleve_connexion_page.dart`, `reglages_enfant_page.dart`. Trois d'entre
     elles partagent le même motif de padding de feuille de bas d'écran copié
     trois fois — une dette de duplication notée mais pas traitée ici, hors
     scope Bible ;
   - `page-sans-coquille` — retient une liste **nominative et temporaire** de
     douze écrans encore à l'état brut (cinq pour le lot R0, sept pour R4),
     documentée dans le fichier lui-même. Chaque entrée doit se retirer au lot
     qui reprend vraiment l'écran, jamais avant ;
   - `tag-conformite` — vérifie que tout tag `[XXX]` en début de ligne de
     commentaire appartient au vocabulaire fermé de `lib/CLAUDE.md`
     (`[M3-COLOR]`, `[A11Y]`, `[RESPONSIVE]`, `[QURAN-STAGE]`). Anchré sur la
     ligne entière pour ne pas confondre un tag avec une classe de caractères
     de `RegExp` telle que `'[A-Z2-9]'`, qui l'aurait fait échouer sur du code
     parfaitement sain sans cette précaution.
4. **`docs/AGENT_HANDOFF.md`** créé : le même point d'entrée pour OpenCode et
   Hermes, avec le gabarit de prompt de reprise, pour que la Bible s'applique
   aux trois outils de l'écosystème et pas seulement à Claude Code.

⚠ **Un écart neuf, découvert pendant B0, pas dans l'audit initial** : le lot
`journee_page.dart` (ENS-02, déjà « repris » au lot R3) contenait encore un
`Scaffold` nu pour son état de chargement initial (`monId == null`). Corrigé
dans ce même lot (`PageShell` partout), sans quoi la règle `page-sans-coquille`
aurait dû l'exempter à tort. Un écran marqué « repris » qui régresse plus tard
sur cette règle est une régression au sens de la Bible §51, pas une réouverture
de discussion sur l'exemption.

### 0 quater. Le lot T2 : durcir le langage, poussé sans vérification par les tests

Cause n3 mesurée du rejet du 11 septembre (ombres à 5 %, bordures décoratives
à 1,20:1 et 1,45:1) et cause n2 (bouton `ActionPrincipale` désactivé qui pesait
moins qu'un secondaire). Les deux sont corrigées dans le code. Ce lot **n'a
jamais pu être vérifié par `flutter test`** sur ce poste, et a été **poussé
sur `main` malgré cela, sur demande explicite de l'opérateur** — voir
l'avertissement en tête de fichier.

**Ce qui a changé, et pourquoi ces valeurs précises :**

1. **Ombres** (`app_elevation.dart`) : niveau1 0,05/0,05 → 0,10/0,09, niveau2
   0,05/0,08 → 0,08/0,14, niveau3 0,14 → 0,22. La teinte de l'ombre (`#3A302A`)
   ne change pas.
2. **Bordures décoratives** (`app_palette.dart`) : `borderHairline`
   `#E7DFD8` → `#DCD2C8` (1,20:1 → 1,36:1 sur le crème), `borderResting`
   `#D6CBC3` → `#C9BCB1` (1,45:1 → 1,69:1). **Les trois surfaces neutres ne
   bougent pas** — décision mesurée, pas oubliée : le moindre assombrissement
   de `surfaceSunken` fait chuter `borderStrong` sous 3:1 sur cette surface
   (2,96 dès `#ECE4DA`, un cran à peine plus sombre), qui n'avait déjà que
   3,21 de marge, la plus fine des trois. Chiffré avant d'être écarté.
3. **Focus des champs** (`app_theme.dart`) : passait par `surfacePrimary`
   (violet) à 2px, passe par `borderStrong` à 3px. `borderStrong` est déjà
   documenté dans `app_palette.dart` comme *« la seule bordure porteuse de
   sens : sélection, focus, bord de tableau »* — l'implémentation ne suivait
   pas encore sa propre documentation. `focusedErrorBorder` passe aussi à 3px,
   par cohérence. `disabledBorder` ajouté (`borderHairline`), absent avant :
   un champ désactivé et un champ au repos étaient indiscernables.
4. **`ActionPrincipale` désactivée** (`action_principale.dart`) : peignait
   `surfaceSunken` + `inkMuted` + `borderResting` (2px), donc un fond presque
   invisible sur le fond général (1,06:1 d'écart) et le filet le plus faible
   de la rampe — plus léger qu'un bouton secondaire au repos. Peint
   maintenant `surfaceRaised` (blanc) + `inkMuted` + `borderStrong` (3px,
   plus épais que le contour 2px d'un secondaire) : la forme reste visible et
   pèse plus, seule l'encre dit que l'action attend une condition. Ce
   traitement s'applique aux quatre niveaux d'action quand ils sont
   désactivés, pas seulement au principal — c'était déjà le cas avant ce lot.
5. **Tests mis à jour en conséquence**, dans `test/theme/contraste_test.dart`
   (nouvelles valeurs de bordures, le test de focus vérifie `borderStrong` et
   non plus `surfacePrimary`, un groupe neuf vérifie `inkMuted` sur
   `surfaceRaised` et que le filet du désactivé dépasse celui du repos) et
   `test/theme/elevation_test.dart` (plafond d'opacité remonté de 0,2 à 0,3
   pour laisser passer le niveau3 à 0,22). **Ces fichiers n'ont pas pu tourner
   pour confirmer qu'ils passent réellement** — voir l'avertissement en tête.
6. `docs/produit/design-tokens.md` sections 1.3 et 9 mises à jour avec les
   nouvelles valeurs et leur justification.

**Non fait dans ce lot**, contrairement à l'intention initiale, et pour la
raison ci-dessus : élargir l'écart de clarté entre les trois surfaces. La
route `/_galerie` était déjà correctement gardée par `Env.galerieActive`
(faux par défaut), rien à faire de ce côté.

### 0 quinquies. Le lot R0 : le tunnel d'entrée, poussé sans vérification par les tests

Causes n1 et n2 mesurées du rejet du 11 septembre (`connexion_page.dart`
montait un `Scaffold` nu, seul écran visible sans compte ; le bouton
`ActionPrincipale` désactivé du lot T2 corrige déjà la cause n2 par ailleurs).
Six écrans de la zone Accès reprennent le même défaut, et sont tous corrigés
dans le même lot, commit **`5f96b84`** (« Lot R0 : le tunnel d'entree »),
au-dessus du commit de T2. **Poussé sur `main` malgré l'absence de
confirmation par `flutter test`**, sur demande explicite de l'opérateur —
même raison que T2, voir l'avertissement en tête de fichier. Une vérification
visuelle de substitution a été faite (voir plus bas) : elle confirme le rendu
de `TUT-00`, pas les autres écrans, et ne remplace pas `flutter test`.

**Ce qui a changé :**

1. **Nouveau composant partagé `MarquePage`**
   (`lib/core/widgets/marque_page.dart`) : le nom du produit seul, en
   `inkAccent`, sur le fond général. **Aucun asset de logo n'existe dans le
   dépôt** (`assets/` vérifié) : la marque est un texte, via la clé slang
   `commun.marque`, en attendant qu'un logo existe. Précède la carte sur les
   six écrans repris.
2. **Six écrans passent de `Scaffold` nu à `PageShell`, contenu posé sur
   `AppCard`** : `connexion_page.dart` (`TUT-00`), `eleve_connexion_page.dart`
   (`ELV-01`), `attente_page.dart` (`TUT-00b`), `signature_page.dart`
   (`AccusePage` = `TUT-00c/a`, `ContratPage` = `TUT-00c/b`),
   `depot_piece_page.dart` (`TUT-00c/c`). Les trois derniers avaient une zone
   d'action réimplémentée à la main (`Padding` + `Column` + message d'erreur
   sous un `ListView`) : elle passe par la prise `actions:` de `PageShell`,
   exactement son rôle.
3. **`tool/verifier_jetons.dart`** : les cinq entrées R0 de
   `_ecransEnAttenteDeCoquille` retirées (règle `page-sans-coquille`), les
   sept entrées R4 restent.
4. **Sept fiches manquantes écrites** dans `docs/design/08-catalogue-ecrans.md`
   section 6 : `TUT-00`, `ELV-01`, `TUT-00c`, `TUT-00b`, `TUT-00c/a`,
   `TUT-00c/b`, `TUT-00c/c`, à partir du code existant. `TUT-00c`
   (`inscription_page.dart`) n'a pas changé de code : il passait déjà par
   `PageParcours`, seule sa fiche manquait.
5. **`assets/i18n/fr.i18n.json`** : clé `commun.marque` ajoutée. **Ajoutée à
   la main aussi dans `lib/core/i18n/strings.g.dart` et
   `strings_fr.g.dart`** (getter et entrée de la flat map) : `dart run slang`
   est bloqué par le même TLS que `flutter test` (tout `dart run` résout les
   hooks natifs de tout le graphe de dépendances, `sqlite3` y compris, même
   pour un script qui n'y touche pas). `dart analyze --fatal-infos` reste
   propre après l'édition manuelle ; non rejoué par `dart run slang` faute de
   pouvoir le lancer.

**Dette assumée, quatrième occurrence** : le tirage-pour-rafraîchir de
`attente_page.dart` (`RefreshIndicator` sur `etatDossierProvider`) disparaît,
même sort et même raison que sur `TUT-01`, `ENS-02` et `ADM-01` (fiches
`08-catalogue-ecrans.md`) — un `RefreshIndicator` autour d'un `ListView` a
besoin d'être l'enfant direct d'un `Expanded` pour ne pas planter en hauteur
non bornée, et `PageShell` ne donne pas cette garantie à son `child`. Le
bouton « réessayer » de l'état d'erreur reste le seul moyen de relire le
dossier avant le prochain démarrage.

**Vérification tentée, pas obtenue** : `flutter test` et
`dart run tool/verifier_jetons.dart` bloquent avec le même
`CERTIFICATE_VERIFY_FAILED` que la session précédente. `curl.exe`, sans
rapport avec Dart, échoue aussi sur la même URL GitHub avec
`SEC_E_UNTRUSTED_ROOT` : confirmation indépendante que c'est le magasin de
certificats racine du poste, pas un blocage propre à l'outillage Flutter ni
un incident réseau ponctuel. **Vérification visuelle de substitution** :
`flutter build web --release` compile (le hook natif `sqlite3` ne s'exécute
pas pour la cible web), servi en local et ouvert dans Chrome avec une
configuration `dart_define.json` de test jetable (jamais commitée, `git
status` le confirme) — `TUT-00` s'affiche exactement comme conçu : marque
violette, carte blanche à filet et ombre visibles, boutons contournés. Capture
prise à la résolution native de l'outil de capture de cette session (l'outil
n'a pas honoré les demandes de redimensionnement à 390×844), pas une preuve
au format demandé mais une preuve réelle d'exécution, au-delà de
`dart analyze`.

### 0 sexies. Le lot T3 : mode sombre, poussé sans vérification par les tests

Écart 23 du registre de `decisions.md` (Bible V2 §7.3, ADR-019). Avant ce
lot, `AppPalette.claire()` était la seule palette et `Brightness.light`
était codé en dur dans `_schemaDepuisPalette`.

Résumé factuel :

1. `AppPalette.sombre()` ajoutée (`lib/core/theme/app_palette.dart`), toutes
   valeurs neuves et mesurées independamment du clair. Détail complet dans
   `docs/produit/design-tokens.md` §12. Les quatre paires pleines et `ombre`
   sont réutilisées telles quelles (couleurs de marque, documenté comme un
   choix) ; `surfaceInverse` s'inverse (crème+noir au lieu de noir+crème).
2. `AppElevation` prend désormais l'ombre en paramètre au lieu de tirer
   silencieusement `AppPalette.claire().ombre` (`app_elevation.dart`). Neuf
   fichiers appelants mis à jour.
3. `AppTheme.pour(mode, brightness)` choisit entre les deux palettes ;
   `lib/app.dart` expose `theme`, `darkTheme`, `ThemeMode.system`. Pas de
   bascule manuelle dans un écran : aucune entrée au catalogue
   `08-catalogue-ecrans.md` pour ça, ce lot ferme le mécanisme, pas une
   préférence utilisateur.
4. `test/theme/contraste_sombre_test.dart` créé, même méthode que
   `contraste_test.dart`. Deux constats notables : `inkFaint` n'a aucune
   surface interdite en sombre (le trou du clair, sur `surfaceSunken`, se
   serait déplacé vers `surfaceRaised` ; fermé par le choix de valeur) ; le
   piège du texte blanc de `surfaceAlert` posé sur la page ne se reproduit
   pas en sombre (16,84 contre 1,10 côté clair).
5. La galerie de composants reste clair seulement : le catalogue
   (`07-catalogue-composants.md` §5) ne liste que cinq axes de vérification,
   pas la luminosité.

Non fait : bascule manuelle clair/sombre dans un écran de réglages ;
vérification visuelle du rendu sombre lui-même (voir plus bas).

Vérification tentée, pas obtenue : `flutter test` et
`dart run tool/verifier_jetons.dart` bloquent avec le même
`CERTIFICATE_VERIFY_FAILED` que les sessions précédentes — quatrième
confirmation du même blocage, voir l'en-tête. Vérification visuelle de
substitution : `flutter build web --release` compile, servi en local et
ouvert dans Chrome — `TUT-00` s'affiche en clair comme au lot R0, sans
régression visible du refactor `AppElevation`. Le rendu sombre lui-même n'a
pas été vérifié visuellement : `prefers-color-scheme` ne se force pas depuis
le JS d'une page, et changer le thème du système d'exploitation du poste
pour ce seul test a été jugé disproportionné. Preuve disponible pour le
sombre : `dart analyze` propre, et les mesures de contraste calculées à la
main hors Dart avant d'être écrites dans le code (même formule WCAG que
`Color.computeLuminance`).

**Poussé sur `main` (`1eb0d30`) malgré l'absence de confirmation par
`flutter test`, sur décision explicite de l'opérateur** — même raison que
T2 et R0, voir l'avertissement en tête de fichier. Le rendu sombre en
production reste donc à vérifier visuellement dès que possible.

### 0 septies. Le lot R4 : le reste de l'existant, reprise de coquille

Dernier sous-lot du lot **R** (`08-catalogue-ecrans.md` section 5) : les six
derniers écrans construits mais pas encore repris par le langage T/C, plus
leurs deux sous-écrans. Le lot **R** est désormais complet. Fiches complètes
dans `08-catalogue-ecrans.md` section 6.

**Ce qui a changé, écran par écran :**

1. **`TUT-02`** (`appareils_page.dart`) : `Scaffold` + `OfflineBanner` +
   `RefreshIndicator` + `ListView` → `PageShell`. Dette assumée : le
   tirage-pour-rafraîchir disparaît, cinquième occurrence après `TUT-00b`,
   `TUT-01`, `ENS-02` et `ADM-01`, même raison à chaque fois (`RefreshIndicator`
   a besoin d'un `Expanded` direct, `PageShell` ne le garantit pas à son
   `child`).
2. **`TUT-02/a`** (`ajouter_enfant_page.dart`) : aucun changement de code, il
   passait déjà par `PageParcours`. Seule sa fiche manquait (même cas que
   `TUT-00c` au lot R0).
3. **`TUT-02/b`** (`appairage_page.dart`) : `Scaffold` + `ListView` →
   `PageShell` ; le bouton de retour, collé en bas à la main dans un `Padding`
   hors `Scaffold`, passe par la prise `actions:` de `PageShell` — même
   correction que les feuilles d'accueil du lot R0.
4. **`TUT-04`** (`disponibilites_page.dart`) : `Scaffold` + `ListView` →
   `PageShell`. Pas de tirage-pour-rafraîchir à perdre ici, il n'y en avait
   pas.
5. **`TUT-05`** (`reglages_enfant_page.dart`) : `Scaffold` + `ListView` →
   `PageShell`. `FeuilleDemandeTuteur` (feuille de bas d'écran) garde son
   `Padding` manuel dupliqué — dette déjà connue depuis le lot B0 (section
   0 ter, point 3), pas traitée ici, hors scope.
6. **`ENS-06`** (`creneaux_page.dart`) : **l'écart mesuré au registre est
   corrigé.** L'écran montait un `DefaultTabController` + `Scaffold` propres,
   `TabBar`/`TabBarView` fixes quel que soit le gabarit. Désormais : sur
   mobile, deux onglets restent (`TabBar` dans `PageShell.entete`) mais
   **sans `TabBarView`** — un `TabBarView` s'appuie sur un `PageView`, qui
   exige une hauteur bornée, et `PageShell` ne borne jamais la hauteur de son
   `child` (c'est la page entière qui défile). Le panneau bascule donc
   directement sur l'index du `TabController`, au prix du balayage au doigt
   entre onglets. Sur tablette, les deux panneaux s'empilent sans onglet ;
   sur desktop, ils sont côte à côte dans une `Row`. `CreneauxPage` passe de
   `ConsumerWidget` à `StatelessWidget`. Les deux onglets internes passent de
   `ListView` à `Column`, même transformation que les autres écrans de ce
   lot.
7. **`ADM-02`** (`dossiers_page.dart`) : `Scaffold` + `switch(AsyncValue)` →
   `PageShell` enveloppant le même `switch`. La zone de verdict (checklist
   puis approuver/refuser) reste délibérément dans le corps défilant, **pas**
   dans `PageShell.actions` : la séquence constat→checklist→verdict doit
   rester lisible de haut en bas en une seule colonne (invariant déjà noté
   `08-catalogue-ecrans.md` section 4, « Constat et jugement séparés »),
   contrairement aux écrans à action unique du lot R0.
8. **`ADM-06`** (`demandes_page.dart`) : même transformation et même raison
   qu'`ADM-02` pour garder le verdict dans le corps. `FeuilleRegle` (feuille
   de bas d'écran) garde aussi son `Padding` manuel dupliqué, même dette que
   `TUT-05`.

`tool/verifier_jetons.dart` : les sept entrées R4 de
`_ecransEnAttenteDeCoquille` (règle `page-sans-coquille`) sont retirées, le
set est désormais vide — le lot R est complet, plus aucun écran de
`lib/features/` n'est exempté de cette règle.

`docs/design/07-catalogue-composants.md` section 1 : la ligne `GrilleSemaine`
disait à tort « sélection en `surfacePrimary` » ; corrigée pour décrire les
vrais états du code (case vide `surfaceSunken`, posée `washAccent`,
survol/pression filet `borderStrong`, jamais d'aplat plein).

**Deux écarts restent ouverts, non traités par ce lot** : les six compteurs
contre cinq annoncés et l'ordre signaux/chiffres d'`ADM-01`/`ADM-06`
(`08-catalogue-ecrans.md` section 6, fiche `ADM-01`, lignes ~608-620). Ce
sont des questions de conception sur un écran déjà repris au lot R3, pas des
écrans de R4 : elles restent à trancher, aucune décision n'a été prise ici.

**Vérification tentée, pas obtenue** — cinquième confirmation consécutive du
même blocage : `flutter test` et `dart run tool/verifier_jetons.dart`
échouent toujours avec `CERTIFICATE_VERIFY_FAILED` sur le hook natif de
`package:sqlite3`. Retenté une fois cette session, comme prescrit, pas plus —
la cause est établie. `dart analyze --fatal-infos` est vert sur l'ensemble du
dépôt après ce lot.

**Commit et push** : poussé sur `main` (`76867a7`), sur décision explicite de
l'opérateur — même raison que T2/R0/T3, voir l'avertissement en tête de
fichier. Confirmé par `git fetch origin main` : `origin/main` correspond.

### 0 octies. Le lot A1 : accessibilité, RTL et clavier prouvés par des tests

Dernier lot de la liste ADR-019 avant N0 (specs étape 5). Écart 24 du
registre de `decisions.md`, fermé.

**Constat inexact corrigé, avant de dire ce qui a été fait** :
`decisions.md` écart 24 (écrit au lot B0) affirmait « aucun test de rendu
arabe ». C'est faux : `test/widgets/catalogue_galerie_test.dart` teste déjà le
RTL et le 200 % depuis le lot C (7 septembre), sur les composants isolés de la
galerie. L'écart réel n'était donc pas « rien n'existe », mais une couverture
incomplète : la galerie ne vérifie que l'absence d'exception (pas que le
miroir RTL est *comportementalement* correct), et ne porte que sur les
composants isolés, jamais sur un écran métier réel avec sa propre mise en
page.

**Ce que ce lot ajoute, trois fichiers neufs plus une extension du
harnais :**

1. **`test/icons/app_icons_rtl_test.dart`** : preuve comportementale, pas
   seulement « ne lève pas ». `AppIcons.chevron` porte `matchTextDirection`
   sur ses deux graisses ; `AppIcons.suivant`, même dessin, ne le porte pas
   (c'est la progression du temps, pas une ligne qui mène ailleurs,
   `06-accessibilite.md` section 5) ; les icônes de média (micro, caméra,
   lecture/pause) ne se miroitent jamais. Une régression qui retirerait
   `matchTextDirection` de `chevron` ne lèverait toujours aucune exception :
   sans ce test, elle serait passée inaperçue indéfiniment.
2. **`test/accessibilite/rtl_echelle_texte_ecrans_test.dart`** : les
   **dix-neuf écrans réels** du catalogue (dix-huit fichiers,
   `signature_page.dart` en portant deux : `AccusePage` et `ContratPage`),
   montés avec leurs propres services factices, rejoués en RTL puis à 200 %
   de taille de texte, sans qu'aucune exception ne soit levée. Les cinq
   écrans marqués « à construire » ou « hors MVP-0 » au catalogue n'existent
   pas encore dans le code : rien à monter avant qu'ils soient écrits.
   **Découverte au passage** : `ELV-01` (`EleveConnexionPage`) n'avait
   **aucun test de widget** dans tout le dépôt, ni ici ni ailleurs. Trois faux
   ajoutés à `harnais.dart` pour le rendre montable en test :
   `FauxProfilsLocaux`, `FauxStockageSecurise`, `FauxServiceEnfant`.
3. **`test/accessibilite/clavier_test.dart`** : trois preuves distinctes.
   - **Ordre de focus** : `Tab` fait passer le focus du champ prénom au champ
     nom sur la page identité de `TUT-00c`, dans l'ordre visuel — pas un ordre
     qui daterait de la construction.
   - **Focus visible** : `app_theme.dart` câble bien `focusedBorder` sur
     `borderStrong` à 3px (lot T2), distinct du repos et du désactivé. C'est
     une vérification du câblage du thème, pas du rendu pixel : creuser plus
     loin (l'`InputDecorator` réellement peint) exigerait d'inspecter des
     objets de rendu internes à Flutter, jugé disproportionné pour la preuve
     recherchée ici.
   - **Échap ferme une surface modale** : `lib/core/widgets/app_bottom_sheet.dart`
     documentait déjà ce comportement comme automatique (« rien à câbler »),
     mais rien ne le rejouait. `AppBottomSheet.ouvrir` est le seul point
     d'entrée des surfaces modales du produit : le prouver une fois à ce
     niveau couvre transitivement `ConfirmDestructive`, `FeuilleDemandeTuteur`
     et `FeuilleRegle`, qui n'en sont que des contenus. Un test dédié confirme
     en plus que `ConfirmDestructive.demander` rend bien `false` sur Échap,
     jamais `true`.

**Non fait, et pourquoi** : les cinq écrans « à construire »/« hors MVP-0 »
(`ADM-05`, `CTR-01`, `ELV-03`/`ENS-03`/`CTR-02`, `ELV-04`, `ENS-04`, `TUT-06`,
`ADM-04`, `ENS-05`, `CPT-01`) ne sont pas testés : ils n'existent pas encore
dans le code, rien n'aurait pu être monté. Le rendu pixel du focus (au-delà du
câblage du thème) n'est pas vérifié : inspecter l'`InputDecorator` peint
exigerait de creuser des objets de rendu internes, jugé disproportionné ici.

**Vérification tentée, pas obtenue** — sixième confirmation consécutive du
même blocage : `flutter test` et `dart run tool/verifier_jetons.dart`
échouent toujours avec `CERTIFICATE_VERIFY_FAILED` sur le hook natif de
`package:sqlite3`. Retenté une fois cette session, comme prescrit, pas plus.
`dart analyze --fatal-infos` est vert sur l'ensemble du dépôt après ce lot.
`tool/verifier_jetons.dart` ne scanne que `lib/` (vérifié en lisant son code,
`Directory('${racine.path}/lib')` dans `main()`) : les fichiers de ce lot,
tous sous `test/`, ne peuvent de toute façon déclencher aucune de ses règles.

**Commit et push** : poussé sur `main` (`761db39`), sur décision explicite de
l'opérateur — même raison que T2/R0/T3/R4, voir l'avertissement en tête de
fichier. Confirmé par `git fetch origin main` : `origin/main` correspond.

### 0 novies. Le lot N0 : spécification de l'étape 5, ADR-020

Dernier lot de la liste ADR-019 avant **L10** (dette indépendante de
l'étape 4). Lot documentaire : aucun écran, aucune migration, aucun test.

**Étape 1 de ce prompt de reprise, avant N0** : `git log --oneline -5` et
`git status` confirmés contre `origin/main` (`1748c06`, aucune divergence,
seuls des fichiers Windows générés — `generated_plugin_registrant.*` —
modifiés, sans rapport). `dart analyze --fatal-infos` vert. `flutter test`
puis `dart run tool/verifier_jetons.dart` retentés une fois chacun, comme
prescrit : même échec identique, `CERTIFICATE_VERIFY_FAILED` sur le hook natif
de `package:sqlite3`, **septième confirmation consécutive**. Pas de nouvelle
tentative au-delà de celle prescrite.

**Ce que N0 a produit**, après recherche du périmètre dans
`docs/design/08-catalogue-ecrans.md` (écrans `ELV-03`, `ENS-03`, `CTR-02`,
`ELV-04`, tous « à construire, étape 5 », plus leurs invariants déjà notés) et
`docs/design/README.md` §4 BIS (qui pointait vers les §19-32 de la Bible V2,
déjà adoptée en entier par l'ADR-019 et lue en entier pour ce lot) :

1. **`docs/architecture/etape-5-salle-coran-presence.md`**, nouveau, sur le
   modèle de `etape-4-dashboards.md` : ce que l'étape 5 doit rendre possible,
   ce qui est déjà tranché par dix ADR d'architecture antérieurs (001, 002,
   004-006, 008-012) et n'est pas rouvert, le Coran comme contenu structuré
   (`mushaf`/`sourate`/`page_mushaf`/`verset`, état personnel de lecture
   distinct de l'état partagé de séance), la salle en cinq sous-systèmes à
   dégradation indépendante, la machine à états de présence par participant
   (14 états de la Bible §29.1, aucun ajouté ni retiré, dérivée de
   `session_events`/`StatutSeance` déjà existants, pas une nouvelle table
   d'événements bruts), les quatre écrans en prose, huit invariants, ce que
   l'étape 5 ne fait pas, six questions explicitement laissées ouvertes
   (§10 : source technique des données Coran, seuils de retard/reconnexion,
   vocabulaire de `session_events.source`, écran pour marquer un participant
   excusé, canal de diffusion de l'état partagé, granularité mot-à-mot), un
   découpage en huit lots proposé (N0 à N7, à confirmer au premier lot de
   code) et une proposition de migration non écrite.
2. **`decisions.md`** : **ADR-020** ajouté, qui pointe vers ce document.
   **Question 3 du registre fermée** : Hafs ʿan ʿĀṣim, édition Mushaf
   Al-Madinah An-Nabawiyyah du Complexe du Roi Fahd — décision explicite de
   l'opérateur (« c'est hafs, le package du roi fahd avec tout ce qui va
   avec »), qui confirme un défaut déjà présent en base depuis l'étape 1
   (`student_profiles.riwaya = 'hafs'`, jamais écrit autrement). La source
   technique des données (jeu de données ou API, police, licence) reste
   ouverte, ce n'est pas une décision de riwaya. **Question 19 mise à jour** :
   posée pour le seul domaine présence par les 14 états ci-dessus, reste
   ouverte pour les autres domaines (matching, séance, contenu).
3. **`docs/design/README.md`** §4 BIS (ligne « §19-32 salle, Coran structuré,
   présence ») et §9 (liste `[à faire] Lot N0` → `[fait]`) mis à jour.
4. **`docs/PROGRESS.md`** ligne 5 (étape 5) mise à jour : spécifiée, code non
   touché, attend son premier lot de code (N1).

**Deux points ont été posés à l'opérateur avant d'écrire quoi que ce soit**,
conformément à la consigne « ne pas inventer » du prompt de reprise : le
format du livrable (spec complète façon L0, retenu) et la riwaya (Hafs/Roi
Fahd, retenu, voir ci-dessus). Sans ces deux réponses, ce lot n'aurait pas pu
avancer sans deviner à la place de l'opérateur.

**Ce qui n'a pas été fait, volontairement** : aucun code, aucune fiche
d'écran remplie dans `08-catalogue-ecrans.md` (les fiches complètes se
remplissent au lot qui construit vraiment l'écran, comme le dit déjà §3 de ce
fichier — pas avant), aucune migration écrite (la proposition §13 du nouveau
document n'est pas `0006` ni une nouvelle migration, elle sera affinée au lot
N1).

**Commit et push** : à faire sur ce lot, docs uniquement, aucun code touché
— cohérent avec la règle déjà appliquée depuis plusieurs lots (build vert →
commit et push sans redemander), et sans le risque des lots précédents
puisque rien en `lib/` ni `test/` n'a changé.

### 0 decies. Le lot L10 : clôture de l'étape 4

Dernier lot du découpage en onze de l'étape 4 (section 2), dette indépendante
de la refonte, redevenue la priorité après que N0 a épuisé l'ordre de travail
de l'ADR-019. N'ajoute aucun écran : vérifie et consigne, comme prescrit.

**Étape 1 de ce prompt de reprise, avant L10** : `git log --oneline -5` et
`git status` confirmés contre `origin/main` (`39aec71`, aucune divergence,
seuls les fichiers Windows générés modifiés, sans rapport). `dart analyze
--fatal-infos` vert. `flutter test` puis `dart run tool/verifier_jetons.dart`
retentés une fois chacun, comme prescrit : même échec identique,
`CERTIFICATE_VERIFY_FAILED` sur le hook natif de `package:sqlite3`,
**huitième confirmation consécutive**. Pas de nouvelle tentative au-delà de
celle prescrite.

**Ce que L10 a fait, dans l'ordre de la section 4 :**

1. **Les cinq contrôles rejoués sur un conteneur Docker neuf.** Trois obtenus,
   deux non (même blocage TLS que l'étape 1, ce sont les mêmes commandes) :
   `dart analyze --fatal-infos` vert, `scenarios_etape3.sql` 34 contrôles
   verts, `scenarios_etape4.sql` 39 contrôles verts — identiques aux comptes
   de L9, aucune régression. Chiffres et détail consignés dans
   `etape-4-journal.md`, nouvelle section « Mesures du lot L10 ».
2. **`docs/PROGRESS.md` mis à jour** : étapes 4 et 4 bis passées à `[x]`, ligne
   M de l'onboarding corrigée, ligne « Promotion en production » corrigée,
   section « DÉMARRER ICI » réécrite pour pointer vers N1 plutôt que L10. La
   ligne « Plateforme Android 37 » avait déjà été retirée lors d'une session
   antérieure (remplacée par « Magasin de certificats du poste ») : rien à
   faire de ce côté, contrairement à ce que disait le prompt de reprise.
3. **Les dix-sept scénarios relus** (`etape-4-journal.md` section « Les
   dix-sept scénarios d'acceptation ») : déjà exacts, seize verts, le
   quatorzième (démarrage à froid) toujours marqué non mesurable sur ce
   poste, ni coché ni refait. Rien à corriger.

⚠ **Découverte non prévue par le prompt de reprise, en vérifiant la ligne M** :
`docs/HANDOFF.md` affirmait depuis plusieurs sessions que la production
servait `c5a511f` (L8). C'était faux. Vérifié par l'API Vercel
(`get_deployment` sur `rewayah-academy.vercel.app`, en lecture seule, aucun
déploiement déclenché) : la production sert en réalité **`a9127fd`**, le
commit qui a suivi la clôture du lot R3 (déployé le 8 septembre au soir, déjà
noté dans `PROGRESS.md` mais avec le mauvais SHA, `09527ec`). Conséquence :
**onze commits séparent la production de `main`** — B0, T2, R0, T3, R4, A1 et
N0 sont codés et poussés mais **aucun n'est en ligne**. Corrigé dans les deux
fichiers (`HANDOFF.md` section 4 bis, `PROGRESS.md` lignes M et « Promotion en
production »). La ligne de promotion reste à l'opérateur, comme toujours —
ce lot n'a rien déployé, seulement lu l'état réel.

**Ce que L10 n'a pas fait, volontairement** : ouvrir l'étape 5 (N1 reste un
autre lot, un autre jour) ; toucher au SQL de la base réelle.

**Mise à jour, plus tard dans la même session** : sur autorisation explicite
de l'opérateur, le retard de production a été comblé. Reconstruction dans le
worktree `D:\ra-pwa-build` depuis `ad21990` (`flutter pub get`, `flutter
build web --release` — pas besoin de `dart run slang`/`build_runner`, les
fichiers générés sont commités dans le dépôt, donc déjà corrects après le
`git checkout`), puis `vercel deploy --prod --yes` depuis `build/web`. **Passé
sans refus cette fois.** Confirmé par l'API Vercel : l'alias
`rewayah-academy.vercel.app` porte `gitCommitSha: ad21990...`. La production
est maintenant à jour avec `main`.

**Commit et push** : à faire sur ce lot, `docs/` et `PROGRESS.md` seulement,
cohérent avec la règle déjà appliquée (build vert → commit et push sans
redemander) et sans le risque des lots de code précédents, puisque rien en
`lib/` ni `test/` n'a changé.

### 0 undecies. Le lot de remise au vert : le blocage TLS contourné, et ce que la mesure a trouvé

**Neuf sessions durant, `flutter test` n'a jamais tourné sur ce poste.** Le hook
de build de `package:sqlite3` télécharge une DLL depuis `github.com`, que le
magasin de racines du poste refuse. Six lots de code ont donc été poussés, puis
déployés, sans qu'aucune suite ne les ait jamais confirmés.

**Le contournement était documenté depuis le début, dans le paquet lui-même.**
`sqlite3/doc/hook.md` décrit un `user_define` qui lie le SQLite **du système**
au lieu d'en télécharger un :

```yaml
hooks:
  user_defines:
    sqlite3:
      source: system
      name_windows: winsqlite3
      name: sqlite3
```

⚠ **Il n'est ni commité ni laissé en place.** Il change le SQLite d'un build de
production. Il a été posé dans le worktree détaché `D:\ra-pwa-build`, le temps
de la mesure, puis retiré par `git checkout -- pubspec.yaml`. La méthode :
éditer dans le dépôt de travail, copier les fichiers touchés vers le worktree,
mesurer là-bas. Le dépôt de travail n'est jamais modifié par la mesure.

**Première mesure réelle : 515 verts, 19 rouges.** Aucune régression de
production : les dix-neuf se rangent en trois familles, et aucune n'était un
écran cassé.

| Famille | Nb | Ce que c'était vraiment |
| :--- | :-: | :--- |
| Tests périmés | 7 | `composants_test.dart` comparait `d.boxShadow` à `AppElevation.niveau2`, c'est-à-dire à un **tear-off de fonction** : le lot T3 a fait des trois niveaux des fonctions de `AppShadowColor`, les tests ne l'ont pas suivi. Plus une assertion restée sur la paire d'avant T2 |
| Surface de mesure fausse | 9 | `flutter_test` monte tout sur **800 × 600**, c'est-à-dire au gabarit **tablette**, plus court que n'importe quel téléphone. `ENS-06` n'a d'onglets qu'en mobile depuis R4 : six tests cherchaient un onglet inexistant à cette largeur. `TUT-00c/c` : trois `tap` tombaient sous la ligne de flottaison de cette fenêtre-là. **Le produit tenait, la fenêtre mentait** — les neuf passent en 390 × 844 sans toucher un écran |
| Vrais défauts | 3 | `Échap` ne fermait aucune modale (2), `MarquePage` absente du catalogue (1) |

**Le défaut d'`AppBottomSheet` mérite d'être lu, il ne se devine pas.** La
méthode `ouvrir` fournissait son propre `transitionAnimationController`. Or
`ModalBottomSheetRoute` pose alors `willDisposeAnimationController = false` :
le contrôleur appartient à l'appelant. Et l'appelant le détruisait par
`.whenComplete(animation.dispose)` — c'est-à-dire **au pop, pas au retrait**.
Le contrôleur mourait au milieu de l'animation de sortie, la route
n'atteignait jamais l'état qui la retire de l'overlay, et **la feuille restait
affichée sur une route déjà dépopée**. `Échap` faisait exactement ce qu'il
fallait ; rien ne bougeait. Le commentaire du fichier affirmait au contraire
qu'« il n'y a rien à câbler ».

Le remède **supprime** du code : `AnimationStyle` porte les durées autant que
les courbes, donc `showModalBottomSheet` construit le contrôleur lui-même — et
le détruit lui-même, au bon moment. **Ne jamais repasser de
`transitionAnimationController` ici.**

Diagnostic obtenu par élimination, et la méthode vaut d'être notée : une
feuille Material **nue** se ferme sur `Échap` ; on lui rajoute un ingrédient à
la fois (contrôleur, style, `isScrollControlled`) jusqu'à ce qu'elle cesse. Le
premier suffit.

**Un vrai défaut de rendu trouvé au passage, corrigé.** Le lot R4 a rendu
`ENS-06` responsive et a laissé les deux libellés d'onglet dans le seul
`TabBar` mobile : au-delà de 600 px, la grille gardait sa question en tête mais
**le feed d'élèves n'avait plus aucun titre**. Les deux panneaux portent
désormais un `SectionHeader` avec le libellé de leur onglet, et un test le tient
à 768 comme à 1440.

**Deux lignes du tableau de correspondance de `docs/design/README.md` étaient
fausses**, et disaient « Fait » sans que rien ne l'ait vérifié :

- **§13.4 clavier** — le lot A1 avait écrit le test d'`Échap` et l'avait laissé
  rouge, faute de pouvoir le lancer. Fermé pour de bon ici.
- **§18 chargement** — `Skeleton` est né au lot C et **aucun écran ne
  l'emploie** : zéro usage dans `lib/features/` hors `_dev/`. Les écrans qui
  disent quelque chose affichent un `Text` « Chargement… », parfois un
  `EmptyState` détourné en attente (`creneaux_page.dart`). La ligne dit
  maintenant « Écart ». **C'est le premier chantier de rendu qui reste.**

**Résultat : 534 verts, 1 rouge, `dart analyze --fatal-infos` propre,
`verifier_jetons.dart` 96 fichiers sans violation** (il en comptait une avant :
un tiret cadratin dans `appareils_page.dart`).

⚠ **Le rouge restant n'a rien à voir avec ce lot : c'est une bombe à
retardement.** `test/features/journee_test.dart`, « `ENS-02` : le bloc
dominant », place son cours à `DateTime.now() + 25 min 30 s` et attend
« Dans 25 min ». Passé **23 h 34**, cet instant tombe le lendemain, et `ENS-02`
affiche la journée d'aujourd'hui : le cours n'y est pas. Le test échoue donc
tous les soirs entre 23 h 34 et minuit, et il a effectivement basculé du vert au
rouge entre deux exécutions de cette session, à 23 h 42. **Le scénario est
inexprimable près de minuit sans horloge injectable** : le vrai remède est de
faire lire l'heure au code de planning via une horloge qu'un test puisse figer
(`package:clock` et `withClock`), ce qui touche la couche planning — une
décision, pas un correctif de test. À trancher avec l'opérateur.

## 1. Le projet actif est celui-ci

**Dépôt de travail : `D:\RA _APP\RA -OFFICIAL-APP`** — Rewayah Academy,
application Flutter de cours de Coran en visio, Supabase en dos.

**Ne pas travailler sur PISI.** Les projets PISI (`PISI CERVEAU`, console de
production vidéo, Next.js) sont **en pause** : ils occupent la plus grosse part
de l'historique et de la mémoire, et une session qui suit ses pointeurs par
habitude se branche dessus par erreur. C'est arrivé au début de la session du
6 septembre. Si le répertoire de travail ouvert n'est pas celui ci-dessus,
changer de répertoire avant toute chose.

`Glob` ne trouve pas ce dépôt : le répertoire de session pointe ailleurs. Passer
les chemins en absolu, et préfixer les commandes par
`cd "D:\RA _APP\RA -OFFICIAL-APP"`.

## 2. Où en est le travail

Étape 4, **dashboards Bento Grid, affectation durable, disponibilités et
prières**. Découpage en onze lots, un lot par commit.

| Lot | Contenu | État |
| :-- | :--- | :-: |
| L0 | Spécification, ADR-017, journal | fait |
| L1 | Migration `0005` et `scenarios_etape4.sql` | fait |
| L2 | Services Dart : règles, planning, matching, admin | fait |
| L3 | Grille de semaine partagée, `TUT-04` | fait |
| L4 | `ENS-06`, prise atomique, plafond | fait |
| L5 | Prières : réglages, calcul, ajustements, journée | fait |
| L6 | `ENS-02` la journée en une colonne | fait |
| L7 | `ELV-02` et ses six états | fait |
| L8 | `TUT-01`, `TUT-05`, demandes du tuteur | fait |
| L9 | `ADM-01`, `ADM-06` | fait |
| **L10** | **Vérifications de fin d'étape, documentation, `PROGRESS.md`** | **fait le 11 septembre 2026** |

**L'étape 4 est désormais close.** Détail du lot L10 : section 0 decies.

Le démarrage à froid, scénario 14, **n'est pas mesurable sur ce poste** : aucune
cible ne se construit ni ne se lance. Ce n'est pas du travail en retard, c'est
une question d'équipement, détaillée dans le journal et dans `PROGRESS.md`.

## 3. Quoi lire, dans cet ordre, et rien d'autre

Si vous reprenez **L10** (vérifications de fin d'étape 4) :

1. `docs/architecture/etape-4-journal.md` — où en est le code, ce que valent les
   mesures, et les pièges déjà payés. **Le plus important des trois.**
2. `docs/architecture/etape-4-dashboards.md` — la spécification : ADR-017, les
   neuf défauts corrigés, les douze invariants, les écrans, les 17 scénarios.
3. `lib/CLAUDE.md` — les règles du code, qui font échouer la CI quand on les
   ignore.

Si vous attaquez la **refonte** (lots C puis R) :

1. `docs/design/README.md` — la constitution, sa section 7, qui dit ce qui est
   déjà tranché, et sa section 9, qui dit ce que le lot T a laissé au lot C.
2. `docs/produit/design-tokens.md` — toutes les valeurs, toutes mesurées, toutes
   rejouées par les tests.
3. `docs/architecture/etape-2-journal.md`, section « Refonte UX/UI, lot T » — ce
   que le thème contient maintenant, et les pièges déjà payés.
4. `docs/design/01-systeme-visuel.md` puis `07-catalogue-composants.md` puis
   `08-catalogue-ecrans.md`.
5. `lib/CLAUDE.md`.

Ne pas rouvrir l'historique des étapes 1 à 3 : leurs journaux ne servent qu'en
cas de doute sur un point précis.

## 4. Le lot L10 est fait

Clôture de l'étape 4, détail complet en section 0 decies. Les cinq contrôles
de la section 5 sont rejoués (chiffres dans `etape-4-journal.md`),
`docs/PROGRESS.md` est à jour, les dix-sept scénarios sont relus (seize
verts, le quatorzième toujours non mesurable sur ce poste, non coché). Ce
n'est plus le point de reprise.

L'étape 5 (salle, pre-flight, `ELV-03`/`ENS-03`) reste une autre étape : elle
est désormais **spécifiée** (lot N0, ADR-020,
`docs/architecture/etape-5-salle-coran-presence.md`), mais son premier lot de
code, **N1**, n'a pas été ouvert par L10 — c'est volontaire, voir section
0 decies.

## 4 bis. Puis la refonte, avant l'étape 5

L'ordre est décidé (ADR-018) : l'étape 5 attend, trois lots passent avant. Un lot
par commit, comme toujours.

| Lot | Contenu | Écrans touchés | État |
| :-- | :--- | :--- | :-: |
| **T** | Jetons, thème, typographie, mouvement. Palette crème et rampes, trois bordures, rayons, ombres, crénage, durées et courbes, échelle d'espacement étendue, et les nouvelles règles de `verifier_jetons.dart` | aucun repris, 29 renommés | **fait** |
| **C** | Les douze composants P0 de `07-catalogue-composants.md`, plus la reprise des onze existants, plus la galerie qui montre tous leurs états. Audit de fin de lot en six tranches, 8 constats corrigés. Compte rendu : `etape-2-journal.md`, « Refonte UX/UI, lot C » | aucun | **fait** |
| **R** | Reprise dans cet ordre : `ELV-02`, puis `TUT-01`, puis `ENS-02` et `ADM-01`, puis le reste | quatre d'abord | **fait le 11 septembre 2026** (R1 à R4, y compris R0 hors ordre initial) |

**Le lot T se faisait en premier et entièrement**, puis le lot C : reprendre un
écran avant les jetons puis avant les composants aurait obligé à le reprendre
trois fois.

Les deux polices sont désormais **dans le dépôt**, avec leur licence OFL :
`assets/fonts/BricolageGrotesque-Variable.ttf` et `InstrumentSans-Variable.ttf`.
Il n'y a plus rien à récupérer. Si un jour il faut y revenir, l'adresse qui
marche est `fonts.google.com/download/list?family=...` : les deux autres pistes
évidentes sont des impasses, détaillées dans `etape-2-journal.md`.

Ce que le sous-lot R4 trouvera en arrivant :

- les quatre premiers écrans et la coquille de navigation portent le langage
  des lots T/C : `PageShell`, `TimelineRow`, `StatTile`, `SignalRow`,
  `ChildCard`, `StatusPill`, et les `BentoTile` posés sur `surfaceRaised` ;
- le routeur tient quatre `StatefulShellRoute` (élève, tuteur, enseignant,
  admin) et une fonction pure `destinationsPour(role, mode)` testée — le mode
  enfant ne propose aucune barre (ADR-009), le contrôleur et le comptable non
  plus ;
- deux écarts à trancher sont consignés dans les fiches `ENS-02` / `ADM-01`
  (six compteurs contre cinq annoncés, ordre « chiffres d'abord »), et deux
  imprécisions de `07-catalogue-composants.md` sont documentées (`GrilleSemaine`
  §1, famille « composant d'état » §4) — les trier avec la reprise de R4 ;
- les écrans restants portent encore l'ancien rendu (`Scaffold` + bandeau, ou
  liste sans coquille) : c'est exactement ce que la rangée R4 reprend.

Deux dettes restent ouvertes et n'appartiennent à aucun lot :

- **`0006` n'est toujours pas jouée sur la base réelle.** Elle est écrite,
  commitée, et le harnais la rejoue à la suite de `0005` sans rien casser. Elle
  porte le correctif de la semaine UTC et la colonne de `profils_du_foyer_v`.
  Tant qu'elle n'est pas passée, `ENS-06` reste faux deux heures par semaine en
  production, et `TUT-01` lit une vue sans sa colonne. Le SQL à coller est dans
  `MISE-EN-SERVICE.md` section 5.
- **La production sert la build de `a9127fd`** (lot R3, déployée le 8 septembre
  au soir), pas `c5a511f`/L8 comme l'affichait cette ligne — corrigé au lot L10
  après vérification par l'API Vercel (`docs/PROGRESS.md` ligne M). Les deux
  écrans d'administration de L9 (`ADM-01`, `ADM-06`) y sont, L9 étant antérieur
  à ce déploiement ; ce qui n'y est pas, c'est tout ce qui a suivi le 8
  septembre : B0, T2, R0, T3, R4, A1, N0, soit onze commits de retard sur
  `main`. La ligne de promotion est à l'opérateur, `MISE-EN-SERVICE.md`
  section 7.1.

## 5. Mesures de référence, à ne pas faire régresser

Relevées le **12 septembre 2026**, au lot `ADM-05`. La colonne du milieu est
celle du 11 septembre, lot de remise au vert — **les premières vraies depuis le
lot T**, les colonnes intermédiaires n'ayant jamais pu être mesurées sur ce
poste (section 0 undecies).

| Contrôle | Valeur (13/09, lot `TUT-06`) | Aux lots `N5` + `CTR-01` (13/09) |
| :--- | :--- | :--- |
| `dart analyze --fatal-infos` | aucun problème | aucun problème |
| `flutter test` | **733 tests, tous verts** | 692, tous verts |
| `dart run tool/verifier_jetons.dart` | **124 fichiers**, aucune violation | 120 fichiers |
| `scenarios_etape3.sql` | **34 contrôles** verts | 34 |
| `scenarios_etape4.sql` | **39 contrôles** verts | 39 |
| `scenarios_etape5.sql` | **15 contrôles** verts | 15 |
| `scenarios_adm05.sql` | **9 contrôles** verts | 9 |
| `scenarios_n2.sql` | **10 contrôles** verts | 10 |
| `scenarios_n4.sql` | **9 contrôles** verts | 9 |
| `scenarios_ctr01.sql` | **10 contrôles** verts | — |
| `scenarios_n5.sql` | **9 contrôles** verts | — |
| `scenarios_adm04.sql` | **9 contrôles** verts, **toujours en dernier** | 9 |
| **Total SQL** | **144 contrôles**, neuf fichiers, base neuve `0001`→`0013` | 125, sept fichiers |
| `main.dart.js` servi | **4 401 919** octets (`6d06d39`, sans `TUT-06`) | 4 442 280 |

⚠ **Le total SQL ne bouge pas au lot `TUT-06`, et ce n'est pas un oubli** :
l'écran n'ajoute aucune migration, et la borne du foyer sur laquelle il repose
est déjà mesurée par `scenarios_n4.sql` **P5** — deux enfants lus, zéro ligne
hors foyer.

⚠ **Les 733 tests comptent aussi ceux d'OpenCode**, dont le travail n'était pas
commité au moment de la mesure : **7** viennent de `test/observabilite/`
(mesurés), les autres d'ailleurs dans son arbre. `TUT-06` en apporte **32** :
16 sur la vue pure, 14 sur l'écran, et 2 de plus dans le test d'accessibilité,
qui passe de 19 à 20 écrans. **Le chiffre du seul arbre commité n'a pas été
isolé** — le mesurer demanderait un worktree neuf, donc un `pub get`, donc le
blocage TLS.

⚠ Le `flutter test` à **692** a été relevé par la session `N5` sur l'arbre
complet des deux lots ; la session `CTR-01` mesurait 690 avant que les deux
entrées de galerie de `rosace_verset` ne soient ajoutées au catalogue. Les deux
mesures décrivent le même arbre à deux instants, pas un désaccord.

⚠ Le 535e test, rouge le 11 septembre, est la **bombe horaire** de
`journee_test.dart` : il ne tombe qu'entre 23 h 34 et minuit. Le voir vert ne
prouve pas qu'il soit réparé, seulement qu'il n'est pas cette heure-là. Détail
en fin de section 0 undecies.

⚠ `flutter test` ne tourne toujours pas tel quel sur ce poste : il faut le
contournement du hook `sqlite3`, dans le worktree de build **et nulle part
ailleurs**. Recette complète en section 0 undecies. `dart run` est logé à la
même enseigne : `verifier_jetons.dart` se lance depuis le worktree lui aussi.

Un lot se termine par ces contrôles, la mise à jour de la documentation d'étape,
un commit et un push. Jamais l'inverse.

## 6. Commandes vérifiées sur ce poste

```
cd "D:\RA _APP\RA -OFFICIAL-APP"
flutter pub get
dart run slang                                          # AVANT build_runner
dart run build_runner build --delete-conflicting-outputs
dart analyze --fatal-infos
flutter test
dart run tool/verifier_jetons.dart
```

Le harnais SQL. Les noms de migration sont ceux du dépôt, pas ceux qu'on devine.
**Attendre `pg_isready` dans une boucle** : sept secondes ne suffisent pas
toujours, et `psql` répond alors « No such file or directory » sur la socket,
ce qui ressemble à une panne et n'en est pas une.

```powershell
docker rm -f ra_e5
docker run -d --name ra_e5 -e POSTGRES_HOST_AUTH_METHOD=trust `
  -v "D:\RA _APP\RA -OFFICIAL-APP\supabase:/sql" postgres:17-alpine
# boucler sur pg_isready, puis :
docker exec ra_e5 psql -U postgres -v ON_ERROR_STOP=1 -q -f /sql/tests/stub_auth.sql
# puis les TREIZE migrations, dans l'ordre du numero : 0001_fondations,
# 0002_statut_attente_kyc, 0003_profil_defaut_attente,
# 0004_inscription_kyc_appairage, 0005_dashboards_affectation_regles,
# 0006_rattrapage_semaine_utc_et_foyer,
# 0007_coran_structure_position_presence, 0008_attribution_manuelle,
# 0009_journal_audit, 0010_video_jeton_presence, 0011_presence_bornee,
# 0012_observation_controleur, 0013_corpus_coranique
docker exec ra_e5 psql -U postgres -v ON_ERROR_STOP=1 -q -f /sql/migrations/0001_fondations.sql
# puis les NEUF fichiers de scenarios, dans cet ordre : ils tiennent sur la
# meme base et chacun borne ses assertions a ses propres fixtures.
# scenarios_adm04.sql se joue TOUJOURS EN DERNIER : il relit la chaine de
# hachage d'audit_logs, que toute emission de jeton ou visite de controle
# allonge.
docker exec ra_e5 psql -U postgres -v ON_ERROR_STOP=1 -f /sql/tests/scenarios_etape3.sql
docker exec ra_e5 psql -U postgres -v ON_ERROR_STOP=1 -f /sql/tests/scenarios_etape4.sql
docker exec ra_e5 psql -U postgres -v ON_ERROR_STOP=1 -f /sql/tests/scenarios_etape5.sql
docker exec ra_e5 psql -U postgres -v ON_ERROR_STOP=1 -f /sql/tests/scenarios_adm05.sql
docker exec ra_e5 psql -U postgres -v ON_ERROR_STOP=1 -f /sql/tests/scenarios_n2.sql
docker exec ra_e5 psql -U postgres -v ON_ERROR_STOP=1 -f /sql/tests/scenarios_n4.sql
docker exec ra_e5 psql -U postgres -v ON_ERROR_STOP=1 -f /sql/tests/scenarios_ctr01.sql
docker exec ra_e5 psql -U postgres -v ON_ERROR_STOP=1 -f /sql/tests/scenarios_n5.sql
docker exec ra_e5 psql -U postgres -v ON_ERROR_STOP=1 -f /sql/tests/scenarios_adm04.sql
```

⚠ **Un fichier de scénarios ne compte jamais en global.** Les neuf tournent
sur la même base : `select count(*) from eleves_sans_enseignant()` y voit les
élèves des trois autres fichiers. Une assertion se borne à ses propres fixtures
(par `household_id` ou par identifiant), et l'ordre se vérifie en **rang
relatif**, jamais par `limit 1`. Le lot `ADM-05` s'est fait prendre une fois :
vert seul, rouge à la suite.

⚠ **Aucune heure locale ne s'écrit en dur dans un scénario qui croise deux
fuseaux.** Conakry ne change pas d'heure, Paris si : « 16 h Conakry = 17 h
Paris » est vrai d'octobre à mars et faux le reste de l'année. Le fixture
d'`ADM-05` calcule l'heure par
`extract(hour from (instant_creneau(...) at time zone '...'))`. Même piège que
la bombe horaire de `journee_test.dart`, en version saisonnière.

Un fichier de scénarios **ne se rejoue pas deux fois sur la même base** : il
insère ses fixtures. Repartir d'un conteneur neuf à chaque mesure.

Le compte de contrôles se lit en comptant les `NOTICE`. Un `docker rm -f` dont la
ligne contient aussi le chemin du volume peut être refusé par la protection de
chemins : le passer sur sa propre ligne.

⚠ **La convention « `0005` se corrige sur place » est morte.** Elle valait tant
que la migration n'était appliquée nulle part ; depuis le 7 septembre, `0001` à
`0005` sont inscrites dans `supabase_migrations` du projet réel, qui ne les
rejouera jamais. Toute correction posée dans `0005` y resterait donc invisible.
Tout changement structurel passe désormais par `0006` et suivantes, et `0006`
existe déjà : le harnais la rejoue à la suite de `0005`, sans effet sur une base
neuve puisqu'elle n'est faite que de `create or replace`.

## 7. Ce qui casse sur ce poste, et n'est pas de votre fait

- Le magasin de racines ne fait pas confiance à `github.com` : le hook de
  `package:sqlite3` échoue, donc `dart run` et `flutter test` peuvent échouer
  au premier appel. Voir `etape-2-journal.md`. **Contournable sans réparer le
  poste** depuis le 11 septembre : le `user_define` `source: system` documenté
  par le paquet, posé dans le seul worktree `D:\ra-pwa-build` et retiré après
  la mesure — **jamais commité**, il changerait le SQLite d'un build de
  production. Recette en section 0 undecies. La vraie réparation (ajouter la
  racine au magasin du poste) reste à faire et vaudrait mieux.
- Composant **ATL absent** de Visual Studio : `flutter build windows` échoue sur
  `atlstr.h`. Revérifié le 6 septembre, en `--profile` : l'échec vient du
  plugin `flutter_secure_storage_windows`, après 222 secondes de compilation.
- Build APK : **ce n'est pas la plateforme du SDK**, contrairement à ce qui
  était écrit ici. `sdkmanager "platforms;android-37"` répond `Failed to find
  package` — ce paquet n'existe pas, Google publie `android-37.0`, déjà
  installé. L'échec réel vient du magasin de certificats : le hook de
  `package:sqlite3` ne peut pas télécharger sa bibliothèque depuis `github.com`
  (`CERTIFICATE_VERIFY_FAILED`), et `Invoke-WebRequest` échoue pareillement sur
  la même adresse. **C'est le poste entier qui ne fait pas confiance à
  `github.com`**, pas l'outillage Flutter. Détail dans `MISE-EN-SERVICE.md`,
  section 4.1.
- **Aucun appareil ni AVD** Android : `flutter devices` ne propose que Windows,
  Chrome et Edge. Mais la cible web, elle, se construit et **tourne en ligne**
  depuis le 7 septembre : le démarrage à froid du scénario 14 peut désormais se
  mesurer en installant la PWA sur un vrai téléphone d'entrée de gamme. La
  mesure sera pessimiste — un bundle web pèse plus qu'un APK — donc un échec ne
  condamnerait pas le produit, mais une réussite compterait.
- PowerShell 5.1 : `2>&1` sur un exécutable natif fabrique un `NativeCommandError`
  même quand la commande a réussi. Lire la sortie, pas le code de retour.

## 7 bis. Le produit est en service, et ça change trois choses

Le 7 septembre 2026, en parallèle du lot L8, l'application a été **mise en
service pour de vrai**. Tout est consigné dans **`docs/MISE-EN-SERVICE.md`**, à
lire avant de toucher au SQL ou au déploiement.

Le travail PWA non commité que cette section signalait était la moitié de cette
mise en service : il est désormais vérifié par un `flutter build web`, déployé
et commité.

Ce qui change pour vous :

1. **Les migrations `0001` à `0005` sont appliquées au projet réel**
   `gggmtelinlpseweouyav`, et inscrites dans `supabase_migrations`. La
   convention « `0005` se corrige sur place » est morte : tout changement
   structurel passe désormais par une migration `0006` et suivantes. Les deux
   objets que L8 a modifiés dans `0005` **ne sont toujours pas sur la base
   réelle** : ils vivent dans `supabase/migrations/0006_rattrapage_semaine_utc_et_foyer.sql`,
   qui reste à jouer. Le même bloc SQL est dans `MISE-EN-SERVICE.md`, section 5.
2. **L'application tourne sur <https://rewayah-academy.vercel.app>**, construite
   depuis un commit vert, jamais depuis l'arbre de travail.
3. **Deux commandes restent à la main de l'opérateur** (hook de jeton et
   `STUDENT_EMAIL_DOMAIN`) : sans la première, toutes les RLS refusent et
   l'application n'affiche que des écrans vides, sans la moindre erreur.

Et la leçon de méthode qui valait déjà : **vérifier `git status` en arrivant**.
La correction `pgcrypto` de `0001` et `0004` attendait dans l'arbre, et a été
commitée à part au début du lot L8.

## 8. Ce qui reste ouvert, et ne dépend pas du code

- **Étape D, les secrets.** Aux trois quarts fermée le 7 septembre : le projet
  est lié, `dart_define.json` est écrit, et les deux fonctions Edge sont
  déployées et `ACTIVE`. Il reste **deux commandes**, listées dans
  `docs/MISE-EN-SERVICE.md` section 3 : le hook de jeton et
  `STUDENT_EMAIL_DOMAIN`. Sans la seconde, aucun enfant ne peut être créé.
- **Compression serveur des photos.** Devenue concrète au lot L8 : `TUT-05`
  dépose désormais vraiment une photo dans le seau `avatars`, avec un refus
  au-delà de 4 Mo côté client et rien de plus. C'est l'original du téléphone qui
  est servi aux appareils du foyer.
- 🔴 **La production est compilée avec une clé Supabase FACTICE, et personne ne
  peut donc s'y connecter.** Trouvé le 13 septembre 2026, en fin de huitième
  session, et **mesuré, pas supposé** :
  - le `main.dart.js` servi par `rewayah-academy.vercel.app` (4 442 280 octets,
    celui des deux lots du jour) contient la chaîne
    `cle-factice-playground-ne-jamais-utilisee` ;
  - cette clé rend **HTTP 401** sur
    `https://gggmtelinlpseweouyav.supabase.co/auth/v1/settings`, là où la vraie
    clé `anon` du projet rend **200** ;
  - `Env.configuree` ne vérifie que `isNotEmpty` : une clé fausse mais non vide
    **passe le garde-fou**. L'application démarre, rend l'écran de connexion,
    **et la console reste muette** — c'est exactement ce que sept sessions ont
    « vérifié ».
  ⚠ **La cause est le fichier de compilation, pas le code.**
  `D:\ra-pwa-build\dart_define.json` est l'**exacte copie** du
  `dart_define.json` de debug du dépôt (384 octets, identique, écrit le
  11 septembre) : clé factice, `GALERIE: true`, `PLAYGROUND: true`. Toute
  version compilée depuis ce worktree depuis le 11 septembre porte donc la
  fausse clé **et expose `/_galerie`** (la chaîne `_galerie` est bien dans le
  bundle servi).
  **Le correctif**, une fois la permission de compiler accordée : écrire dans le
  `dart_define.json` du worktree la vraie clé `anon` (elle se lit par le MCP
  Supabase, `get_publishable_keys`, et elle est publiable par nature — c'est la
  RLS qui protège), passer `GALERIE` et `PLAYGROUND` à `false`, recompiler,
  redéployer. Un worktree propre sur `090ae6f` est prêt en `D:\ra-pwa-fix`,
  dépendances résolues, `dart_define.json` correct déjà écrit.
  ⚠ **Ce qu'il faut ajouter au garde-fou** : `Env.configuree` doit refuser une
  clé qui n'a pas la forme d'une clé Supabase (un JWT `eyJ…` ou un
  `sb_publishable_…`), sinon le prochain `dart_define.json` de debug repartira
  en production sans que rien ne le signale. **Un garde-fou qui teste la
  présence ne teste pas la validité.**
- Les questions en attente de l'opérateur sont listées dans `PROGRESS.md`, et
  les questions de conception dans `decisions.md`, registre en fin de fichier.


## 9. Prompt de reprise — `TUT-06` est fait, il ne reste que deux écrans au MVP-0

À copier tel quel pour démarrer la prochaine session. Le prompt lui-même est en
**§9.5**.

### 9.1 Ce qui a été mesuré le 12 septembre, et non supposé

**Première session.** Le verdict « l'app est loin d'être fonctionnelle » est
**vérifié** : onze destinations du routeur rendaient `EcranAConstruire`, dont
`ELV-03`/`ENS-03`, la salle de cours. Zéro erreur console : rien n'était cassé,
l'étape 5 n'était pas commencée. **Ne pas refaire ce diagnostic.**

**Deuxième et troisième sessions.** `ADM-05` puis `ADM-04`, hors série,
pendant que N2 attendait la décision vidéo. L'espace admin est complet.

**Quatrième session.** La production réparée, et le garde-fou `assert` remplacé
par un écran d'erreur réel.

**Cinquième session.** **N2 fait** : la plomberie vidéo, sans écran.

**Sixième session.** **N3 fait** : la salle. Il reste **six** écrans à
construire — `ELV-04` le Coran, le suivi élève, `TUT-06`, `ENS-05`, `CTR-01`, et
`CPT-01` qui est hors MVP-0. Mesuré : sept `EcranAConstruire` dans le routeur,
dont un qui n'est pas un écran manquant mais l'état de chargement de la racine.
Le compte se lit dans `lib/core/router/app_router.dart`, jamais en parcourant
les écrans.

**Septième session.** **N4 fait** : la présence s'affiche. Aucun écran neuf —
N4 étend la salle — donc **le compte d'écrans manquants ne bouge pas : six.**

**Huitième session, DEUX LOTS EN PARALLÈLE** — deux sessions sur le même dépôt,
coordonnées par messages, une seule compilation et **un seul déploiement, fait
par celle qui a fini en dernier**. `N5` (`ELV-04`, le Coran) et `CTR-01` (le
planning du contrôle) sont faits. **Deux écrans de moins : il en reste quatre.**
Mesuré dans `lib/core/router/app_router.dart` : **cinq `EcranAConstruire`**,
dont un qui n'est pas un écran manquant mais l'état de chargement de la racine.
Les quatre sont le **suivi élève** (`t.nav.eleve.suivi`), **`TUT-06`**
(`t.nav.tuteur.suivi`), **`ENS-05`** (`t.nav.enseignant.profil`) et **`CPT-01`**
(l'espace comptable, **hors MVP-0**). **Dans le MVP-0, il n'en reste donc que
trois.**

**Neuvième session.** **`TUT-06` fait** : le suivi du foyer. **Un écran de
moins : il en reste trois**, dont **deux dans le MVP-0** — le suivi élève et
`ENS-05` ; `CPT-01` est hors MVP-0. Mesuré dans
`lib/core/router/app_router.dart` : **quatre `EcranAConstruire`**, dont un qui
n'est pas un écran manquant mais l'état de chargement de la racine. ⚠ **Rien
n'a été déployé par cette session** : la production porte toujours `6d06d39`,
c'est-à-dire `N5` et `CTR-01`, jamais `TUT-06`.

### 9.2 Les causes non-code

1. ~~Migrations en attente~~ — **close depuis la troisième session.** N3 n'en
   ajoute aucune : il ne touche pas à la base.
2. ~~La production ne sert pas N2~~ — **close.** Elle sert N3, compilée avec ses
   clés, ouverte et vérifiée console à l'appui.
3. ~~Les secrets LiveKit manquent~~ — **close, et vérifiée par HTTP** :
   `create-room-token` répond `401 authentification requise` là où elle
   répondait `503 video non configuree`, et la configuration est testée avant
   l'authentification.
4. 🔴 **OUVERTE, et c'est la plus grave : la production est compilée avec une
   clé Supabase factice.** Le bundle servi contient
   `cle-factice-playground-ne-jamais-utilisee`, qui rend **401** sur l'API du
   projet quand la vraie clé `anon` rend **200**. **Personne ne peut se
   connecter à la production**, et rien ne le dit : l'application démarre,
   affiche l'écran de connexion, console muette. Détail complet, mesures et
   correctif en **section 8**.
   ⚠ **Cela réécrit la phrase qui traînait depuis six sessions.** « Ce qui
   sépare encore la salle d'un vrai cours n'est plus une action, c'est une
   mesure » était **faux** : la mesure — ouvrir deux navigateurs sur une même
   séance — n'a jamais été *possible* en production, puisque l'authentification
   n'y fonctionne pas. Ce n'était pas une négligence de mesure, c'était un
   empêchement que personne n'avait vu.

### 9.2 zero Ce que la neuvième session a livré — `TUT-06`, le suivi du foyer

**`TUT-06` — le suivi du foyer** (commit `122b8e8`, poussé, **non déployé**) :

- `lib/core/suivi/service_suivi.dart` : deux lectures bornées **en base**, et
  **aucune vue neuve** — `mes_seances_v` pour les cours du foyer (`0005`),
  `presence_seance_v` pour la présence de ses membres (`0011`). Le client ne
  filtre **rien** par foyer : un `select()` nu rend le foyer et rien d'autre.
- `lib/features/suivi_foyer/vue_suivi_foyer.dart` : `VueSuiviFoyer.depuis` est
  **pure**, comme `VuePlanning.depuis`, `VueSalle.depuis` et
  `VuePresence.depuis`.
- `lib/features/suivi_foyer/suivi_foyer_page.dart`, branché au routeur, plus la
  fiche §6 du catalogue et 30 tests.
- `PresenceParticipant` gagne `seanceId` : la vue l'exposait déjà
  (`session_id`), la salle n'en avait pas besoin — elle demande **une** séance —
  mais sans lui, rapprocher un état de son cours demanderait une requête par
  ligne de liste.

**Ce que ce lot a trouvé, et que rien ne signalait.** `etat_presence()` ne lit
que les événements de salle. Un cours **annulé**, un cours où **l'enseignant**
ne s'est pas présenté, un cours tombé en **panne** n'en ont produit aucun : la
fonction en déduit une absence, et c'est exact au sens de la base. Affiché tel
quel au parent, cela lui dit que **son enfant était absent d'un cours que
l'académie n'a pas donné**. ⚠ **La donnée n'était pas fausse ; la phrase,
elle, l'aurait été.** Le sort du cours prime donc sur l'état de la personne :
annulé, non tenu, ou l'état de l'enfant, dans cet ordre. Un **élève** absent,
lui, reste un cours tenu : c'est bien **sa** présence, et elle se dit.

**Et la contradiction entre deux sources, tranchée plutôt que contournée.**
`parcours-utilisateurs.md` décrit `TUT-06` comme l'historique des **cahiers de
transmission**, qui sont `ENS-04`, étape 6, sans table ni format ; `0011` écrit
dans son propre corps que la borne du foyer est là **pour que `TUT-06` existe**.
Les deux parlent du même écran à deux moments de sa vie. L'écran construit est
celui que la base sait nourrir — la date, l'enseignant, l'assiduité — et **rien
n'est posé pour le reste** : ⚠ **un espace réservé à un contenu absent se lit
comme une panne**, et il se lirait ainsi à chaque ligne jusqu'à l'étape 6.

### 9.2 bis Ce que la huitième session a livré — deux lots en parallèle

**`N5` — `ELV-04`, le Coran** (session `windowsterminal-de`, commit `090ae6f`) :

- **ADR-024** : la question `a` du §10 de la spécification d'étape, ouverte
  depuis `N0`, est tranchée. L'ADR-020 avait fixé la **riwaya**, jamais la
  **source**. Le critère vient de l'opérateur — « la version qui propose le plus
  de flexibilité » — et il désigne l'**import**, pas l'API : l'API Quran
  Foundation interdit de conserver le contenu plus de sept jours, exige une
  licence commerciale signée pour toute redistribution et reste révocable
  « immediately and without liability ». Le corpus vient du **Tanzil Project**
  (CC BY 3.0).
- `supabase/migrations/0013_corpus_coranique.sql` : **114 sourates, 30 juz,
  604 pages, 6236 versets**, appliquée en production.
- `lib/core/coran/`, `lib/features/coran/`, `lib/core/widgets/rosace_verset.dart`
  et `scenarios_n5.sql` (9 contrôles).

**`CTR-01` — le planning du contrôle** (session `windowsterminal-vs`, commit
`5641348`) :

- `supabase/migrations/0012_observation_controleur.sql` : le plafond de
  participants borné au **groupe pédagogique**, `session_peers_v` et six
  policies resserrées, `est_observateur_masque()`, et **les deux portes
  d'inscription qui n'existaient pas** — `rejoindre_observation()` pour le
  contrôleur (invisible et journalisée nommément) et `assister_seance()` pour le
  tuteur (visible et muet, sans entrée d'audit : un parent qui regarde son
  enfant n'est pas un accès sensible). **Appliquée en production.**
- `lib/core/controle/service_controle.dart` et `lib/features/controleur/` —
  `VuePlanning.depuis` est **pure**, comme `VueSalle.depuis` et
  `VuePresence.depuis`.
- `supabase/tests/scenarios_ctr01.sql` : 10 contrôles, **avant**
  `scenarios_adm04.sql` dans `ci.yml`. `C1` est celui du lot : un cours 1-to-1
  **plein** accepte une visite.
- **Le bouton « Assister » de `TUT-01` enfin câblé** : il était en production
  depuis l'étape 4 et échouait silencieusement.

**Ce que ce lot a trouvé, et que rien ne signalait.** `CTR-02` — l'observation
invisible de l'ADR-011, confirmée pour le MVP-0 — était **inatteignable depuis
sa construction** : rien, nulle part, n'inscrivait jamais de ligne
`masked_controller`. L'enum l'a depuis `0001`, `autoriser_jeton_video()` en
déduit `hidden` depuis `0010`, `presence_seance_v` la cache depuis `0011` — mais
aucune fonction ne l'écrivait, et cette fonction refuse tout appelant absent de
`session_participants`. **N2 a posé le jeton, N3 l'écran, et personne n'avait
posé la porte.**

### 9.2 ter Les pièges fermés par la huitième session, à ne pas rouvrir

1. ⚠ **Un `create or replace` part du corps COURANT de l'objet, jamais de la
   migration qui l'a créé.** `0012` a d'abord réécrit `guard_session_overlap()`
   depuis `0001` et a donc effacé le correctif 3.9 de `0005` (bornes `'[)'` au
   lieu de `'[]'`). Mesure : `scenarios_etape4.sql` est passé de vert à
   « S3 ECHEC : 3 prises au lieu de 4 » — une prise sur deux refusée, ce qui a
   l'air d'un plafond et n'en est pas un. **C'est l'autre session qui l'a
   détecté**, en rejouant la chaîne complète.
2. ⚠ **Une policy RLS qui interroge une table protégée par RLS ne voit que ce
   que l'appelant voit.** Le `not exists (select ... from session_participants)`
   écrit directement dans les policies de `session_events` ne trouvait jamais
   rien — les policies de `session_participants` venaient de fermer ces lignes —
   donc l'enseignant lisait quand même les événements de la visite. **Le pont
   doit être une fonction `security definer`**, exactement comme
   `session_belongs_to_teacher` en `0001`.
3. ⚠ **Un plafond de participants borne le groupe pédagogique, pas
   l'assistance.** Compter les témoins comme des élèves ferme un cours 1-to-1 à
   toute visite. La spécification d'étape 5 §9 l'écrivait : « le 1-to-1, **le
   contrôleur en plus** ».
4. ⚠ **« En cours » se mesure sur les heures, jamais sur `sessions.status`.**
   Rien dans le produit ne fait passer une séance à `in_progress` : le webhook
   LiveKit écrit des **événements**, pas un statut. Un bouton conditionné à ce
   statut ne s'afficherait jamais. Le statut ne sert qu'à dire qu'une séance a
   mal tourné.
5. ⚠ **Un import de 1,48 Mo ne transite pas par un appel d'outil.** `0013` a
   fait lire le corpus à la base, à sa source, et l'identité avec le fichier
   versionné a été prouvée **avant toute écriture** par deux empreintes (`md5`
   du texte et `md5` de la pagination), réinscrites dans les contrôles de la
   migration : **un import complet mais d'une autre édition passerait tous les
   comptages sans que rien ne le signale.** L'extension `http`, créée pour cet
   import, a été **retirée** — laissée en place, elle donne à tout ce qui peut
   exécuter du SQL le droit d'émettre des requêtes sortantes depuis la base.
6. ⚠ **Deux sessions sur un même dépôt, ce qui l'a fait marcher** : réserver par
   message **avant** de commencer (numéro de migration, worktree de build, liste
   de fichiers), ne toucher aux fichiers partagés que par **édition ciblée**,
   relire le fichier juste avant d'éditer, et **créer son propre worktree de
   mesure** — deux `flutter build` dans le même dossier se détruisent. Un
   fichier partagé qui porte les deux travaux ne peut pas être commité par le
   premier sans casser la compilation : **celui dont le code est importé par
   l'autre pousse en premier**, et l'autre commite sa seule version du fichier
   par `git hash-object -w` + `git update-index --cacheinfo`.

### 9.2 quater Ce que la septième session a livré

- `supabase/migrations/0011_presence_bornee.sql` : `presence_seance_v`
  reconstruite. Elle gagne une **borne d'appelant** — admin et contrôleur voient
  les séances, l'enseignant les siennes, le tuteur son foyer, l'élève **sa seule
  ligne** (§6.6) —, le **prénom** et l'identifiant immuable (ADR-008 : jamais de
  nom de famille), et un booléen `consolide` qui dit qu'une décision humaine a
  figé l'état **sans jamais dire pourquoi** : le motif reste en base et au
  journal. Un `masked_controller` n'y est visible que par l'administration.
  **Appliquée en production.**
- `supabase/tests/scenarios_n4.sql` : neuf contrôles, **avant**
  `scenarios_adm04.sql` dans `ci.yml`. `P3` est celui du lot : un élève inscrit
  à rien lisait 6 lignes sur 6, il en lit 0.
- `lib/core/presence/service_presence.dart` : `EtatPresence` (quatorze valeurs
  plus `inconnu`), `PresenceParticipant`, le service, et le flux relu toutes les
  **20 secondes** — un sixième de la plus courte fenêtre qui bascule toute
  seule, celle de `en_reconnexion`.
- `lib/core/presence/vue_presence.dart` : `VuePresence.depuis`, **fonction
  pure**, et `RepereTemps` — parce qu'une durée sans son repère ne veut rien
  dire : « 3 minutes » n'est pas la même chose selon qu'il s'agit du temps passé
  en salle, du retard à l'entrée ou du silence depuis la dernière trace.
- `lib/core/widgets/ligne_presence.dart` : le composant, au catalogue et à la
  galerie. Il porte J3 et J7 par construction.
- `salle_page.dart` : l'en-tête gagne la présence personnelle de l'élève et le
  bouton « Présence » de l'enseignant sur petit écran ; la colonne latérale
  passe des **connectés** aux **inscrits**.

### 9.3 Ce que la sixième session a livré

- `lib/features/salle/vue_salle.dart` : `RoleSalle` (quatre valeurs, pas trois),
  `PhaseSalle`, `CauseImpasse`, et `VueSalle.depuis(...)` — **fonction pure**,
  comme `deciderRedirection` : les quatre rôles, les six phases et les quatre
  impasses se vérifient sans monter d'écran, sans SDK et sans compte LiveKit.
- `lib/features/salle/salle_page.dart` : l'écran. Plein cadre, bandeau permanent
  entre la scène et les commandes, vignettes, colonne de participants dès la
  tablette pour l'enseignant et le contrôleur, quatre écrans d'impasse.
- `lib/core/widgets/page_immersive.dart` : la coquille des écrans **sans page**,
  deux registres (`salle`, `lecture`). Elle rejoint le catalogue des composants
  et la galerie. `ELV-04` s'appuiera dessus au lot N5.
- `VideoSessionProvider.renduVideo(identite)` et son implémentation LiveKit :
  l'écran reçoit un **widget déjà monté**, jamais une piste. Aucun écran
  n'importe `livekit_client`, et le `grep` de l'ADR-001 le prouve toujours.
- `moteurSalleProvider` : un seul moteur pour le produit, libéré à la sortie.
- `ENS-02` gagne son **bouton de lancement**, dans la fenêtre où il peut aboutir
  (T-10 min jusqu'à la fin, le même seuil que `autoriser_jeton_video()`).
- La fiche d'écran au catalogue, et le registre passé à six écrans manquants.

**Ce que le lot a corrigé au-delà de l'écran.** `rejoindre()` ouvrait le micro
dès l'entrée. L'invariant dit l'inverse depuis la refonte, et la fiche produit
l'écrit deux fois : **à l'entrée, rien ne publie, pour aucun rôle.** Le défaut
était invisible faute d'écran pour l'exercer ; il est tenu par un test qui
rejoue les quatre rôles.

### 9.3 bis Ce que la cinquième session avait livré

- `supabase/migrations/0010_video_jeton_presence.sql` : `video_config`,
  `session_video_route`, `video_token_grants`, `livekit_webhook_deliveries`,
  et cinq fonctions. **Aucune policy d'écriture ouverte au client** : le jeton
  vidéo EST le contrôle d'accès à la salle.
- `supabase/tests/scenarios_n2.sql` : dix contrôles, **avant** `scenarios_adm04.sql`
  dans `ci.yml` (l'émission de jeton écrit dans `audit_logs`, et J4 relit la chaîne).
- `supabase/functions/_shared/livekit.ts`, `create-room-token/`,
  `livekit-webhook/` : **déployées et `ACTIVE`**.
- `lib/core/video/` : `video_session_provider.dart` (le contrat),
  `livekit_session_provider.dart` (seul fichier autorisé à importer
  `livekit_client`), `service_video.dart`, `pre_vol.dart`.
- **ADR-023**, questions **29** et **30** du registre.

**Ce que le lot a débloqué au-delà de la plomberie.** `etat_presence()` ne
dérivait que treize des quatorze états : `en_connexion` manquait, et N1 avait
refusé de l'inventer faute de trace en base. `video_token_grants` est cette
trace. Le quatorzième état se dérive, et il est **non falsifiable par le
client** — comme les treize autres.

### 9.3 ter Les pièges fermés par `N4`, à ne pas rouvrir

1. **Une vue sans `where` d'appelant n'est pas protégée par la RLS.** Une vue
   appartenant à `postgres` sans `security_invoker` s'exécute avec les droits de
   son propriétaire. Les trois vues de `0001` se bornent elles-mêmes ; celle de
   la présence ne le faisait pas. **Toute vue `grant`ée à `authenticated` doit
   porter sa propre borne dans son corps.**
2. **L'invisibilité se vérifie partout où la personne peut apparaître.** Le
   jeton LiveKit ne masque que la vidéo. La présence est une seconde surface, et
   elle disait la visite en toutes lettres.
3. **La liste de présence se bâtit sur les inscrits, jamais sur les connectés.**
   Celui qui n'est jamais arrivé n'a aucune piste, donc aucune ligne côté
   moteur — et c'est de lui qu'il faut savoir quelque chose.
4. **`inconnu` n'est pas `absente`.** L'un ne compte pour rien, l'autre compte
   pour le suivi et pour la paie. Les trois cas qui rendent `null` — pas encore
   chargé, lecture refusée, réseau coupé — se disent tous « inconnu » (J3).
5. **Un `async*` avec un `Future.delayed` ne s'annule pas.** Écrit ainsi, le
   flux de présence continuait d'attendre après la sortie de la salle. Une
   minuterie plus `ref.onDispose` s'annule ; la boucle, non.
6. ⚠ **`AsyncValue` n'a pas de `valueOrNull` sous Riverpod 3** : c'est `.value`,
   comme partout ailleurs dans ce dépôt.
7. ⚠ **`''` n'échappe pas une apostrophe en Dart** — c'est du SQL. Deux
   littéraux adjacents sont concaténés, donc `'qu''une'` compile en `'quune'`
   sans rien signaler.

### 9.4 Les pièges fermés par `N3`, à ne pas rouvrir

1. **La vue de la salle se décide sur le jeton, jamais sur la session.** Le
   `role` du compte est lu par le client ; celui du jeton est signé par le
   backend et c'est lui que le serveur LiveKit fera respecter. Un écran qui se
   fierait au premier promettrait des commandes que le second refuse.
2. **Le contrôleur ne figure pas dans sa propre liste.** LiveKit le cache des
   autres, pas de lui-même. Sans ce retrait, il verrait trois personnes là où
   l'enseignant en voit deux, et le test visuel de l'invisibilité ne voudrait
   plus rien dire.
3. **La sortie s'annonce AVANT de se déconnecter.** `left` arrive dans les deux
   cas ; seule l'écriture de `quitter_salle` distingue `sortie` de
   `deconnectee`. Annoncer après laisserait le webhook arriver le premier.
4. **Le nombre de commandes découle du jeton, pas du mode d'interface.** « Deux
   commandes en mode enfant » est un résultat, pas une règle : un mineur a
   `camera_policy = forbidden`, donc pas de bouton caméra. Coder le mode
   priverait de sa caméra l'enfant dont le tuteur l'a justement autorisée.
5. **Une plomberie sans écran est une plomberie non testée.** Le micro ouvert à
   l'entrée a traversé tout le lot N2, ses 13 tests et sa relecture.

### 9.4 bis Les trois pièges fermés par `N2`

1. **Deux fournisseurs, une seule salle.** Tirer le fournisseur à chaque
   émission enverrait l'enseignant et l'élève sur deux serveurs différents, sans
   aucune erreur visible : les deux seraient « connectés », chacun seul.
   `session_video_route` fige la route à la première émission.
2. **Le webhook ne doit pas écraser une sortie volontaire.** `left` arrive dans
   les deux cas ; seule `source` distingue `sortie` de `deconnectee`. Une
   fenêtre de trente secondes protège le geste de l'usager.
3. **Les capacités se calculent en base, jamais dans le client ni dans le
   TypeScript.** Un élève dont `camera_policy` vaut `forbidden` — le défaut
   pour un mineur — reçoit un jeton qui ne *peut* pas publier d'image.

### 9.5 Le prompt

```
Rewayah Academy -- depot D:\RA _APP\RA -OFFICIAL-APP, branche main.
Chemins en absolu : Glob ne trouve pas ce depot.

NE RELIS PAS TOUT LE CODE. Lis exactement ceci, dans cet ordre :
  1. docs/HANDOFF.md -- l'en-tete, la SECTION 8 et la section 9.
  2. docs/design/08-catalogue-ecrans.md -- les fiches "ELV-04 Le Coran"
     et "CTR-01 Planning global", en fin de section 6.
  3. docs/architecture/etape-5-salle-coran-presence.md -- sections 4, 6, 12.
N'OUVRE PAS "D:\RA _APP\docs de lancement\architecture live kit..md" :
son contenu utile est dans l'ADR-023 et les commentaires de 0010.

+++ CE QUI ATTEND, AVANT OU APRES LE PROCHAIN LOT +++
1. TUT-06 N'EST PAS DEPLOYE. La production porte 6d06d39 (N5 et CTR-01)
   et rien de plus. Le deploiement se fait depuis un worktree, avec la
   commande exacte des PIEGES ci-dessous, et LIRE le dart_define.json
   AVANT de construire.
2. DURCIR Env.configuree, toujours pas fait. Elle ne teste que
   isNotEmpty : une cle fausse mais NON VIDE passe le garde-fou, et
   c'est exactement ce qui a mis une cle factice en production du 11 au
   13 septembre sans qu'aucune console ne dise rien. Elle doit refuser
   une cle qui n'a pas la FORME d'une cle Supabase (JWT "eyJ..." ou
   "sb_publishable_").
   UN GARDE-FOU QUI TESTE LA PRESENCE NE TESTE PAS LA VALIDITE.
   ATTENTION : lib/core/config/env.dart porte en ce moment le travail
   NON COMMITE d'OpenCode (Sentry). Relire le fichier juste avant de
   l'editer, et ne jamais stager ses lignes avec les siennes.
3. GALERIE=true en production reste a trancher : /_galerie serait alors
   expose sur le site public, alors que le commentaire d'Env dit
   l'inverse. Le build du 13/09 au soir, lui, ne contient plus _galerie.

OU ON EN EST, MESURE ET NON SUPPOSE.
Le verdict "l'app est loin d'etre fonctionnelle" est VERIFIE depuis le
12/09. Ne REFAIS PAS ce diagnostic. Il reste TROIS ecrans a construire :
le suivi eleve, ENS-05, et CPT-01 qui est HORS MVP-0 -- donc DEUX dans
le MVP-0. L'ESPACE ADMIN EST COMPLET, LA SALLE EXISTE, LE CORAN EST DANS
LE PRODUIT, LES TROIS PORTES D'ENTREE DE LA SALLE EXISTENT (enseignant
ENS-02, tuteur TUT-01, controleur CTR-01), ET LE FOYER A SON SUIVI.
Le compte se lit dans lib/core/router/app_router.dart : quatre
EcranAConstruire, dont un qui est l'etat de chargement de la racine.

FAIT :
  N0 = spec etape 5 + ADR-020 (39aec71)
  N1 = migration 0007 : Coran structure, presence a 14 etats (a736a43)
  ADM-05 = attribution manuelle, HORS SERIE (1eddc9c)
  ADM-04 = journal d'audit, HORS SERIE (1c60089)
  N2 = LA VIDEO. Migration 0010, fonctions Edge create-room-token et
       livekit-webhook (DEPLOYEES ET ACTIVE), module lib/core/video/,
       ADR-023 (e76a14e).
  N3 = LA SALLE. Un seul ecran pour ELV-03/ENS-03/CTR-02 et QUATRE
       roles (le 4e est guardian_observer, le tuteur qui "assiste").
       PageImmersive au catalogue, renduVideo() sur le contrat video,
       bouton de lancement de ENS-02 (61a0ba8).
  N4 = LA PRESENCE S'AFFICHE. lib/core/presence/ (EtatPresence a 14
       valeurs + inconnu, VuePresence.depuis qui est PURE), le
       composant LignePresence au catalogue, et la migration 0011 qui
       BORNE presence_seance_v -- N1 l'avait laissee sans filtre
       d'appelant : un eleve inscrit a rien y lisait 6 lignes sur 6,
       il en lit 0 (f1855de).
  CTR-01 = LE PLANNING DU CONTROLE, et l'observation invisible etait
       IMPOSSIBLE : rien n'inscrivait jamais de ligne masked_controller,
       et le plafond de 2 comptait les temoins comme des eleves -- donc
       un cours 1-to-1 etait "plein", et le bouton "Assister" de TUT-01
       echouait silencieusement en prod DEPUIS L'ETAPE 4. Migration
       0012, deux portes (rejoindre_observation, assister_seance),
       VuePlanning.depuis qui est PURE, TUT-01 repare (5641348).
  N5 = LE CORAN EST DANS LE PRODUIT. ADR-024 : corpus Tanzil (CC BY 3.0)
       IMPORTE plutot qu'API -- la Quran Foundation interdit de
       conserver le contenu plus de 7 jours et reste revocable sans
       preavis. Migration 0013 : 114 sourates, 30 juz, 604 pages,
       6236 versets (090ae6f).
  TUT-06 = LE SUIVI DU FOYER, et un cours ANNULE ne dit rien de
       l'enfant. AUCUNE MIGRATION : 0005 et 0011 avaient deja tout
       ouvert au tuteur, et 0011 le nomme dans son propre corps. Le
       sort du cours prime sur l'etat de la personne -- annule, non
       tenu, ou l'etat de l'enfant -- parce qu'etat_presence() ne lit
       que les evenements de salle et deduit une absence d'un cours que
       l'academie n'a pas donne. L'ecran ne porte AUCUNE action : le
       geste de correction appartient a l'enseignant et a
       l'administration (122b8e8).
  -> 733/733 tests (32 de TUT-06 ; le reste de l'ecart avec 692 vient du
     travail NON COMMITE d'OpenCode, voir section 5), 124 fichiers de
     jetons, 144 controles SQL sur NEUF fichiers (INCHANGES : TUT-06
     n'ajoute aucune migration et scenarios_n4.sql P5 prouve deja la
     borne du foyer), 0012 ET 0013 APPLIQUEES EN PROD.

LE PROCHAIN LOT : au choix, et il n'en reste que deux dans le MVP-0 --
  - le suivi eleve (/eleve/suivi), le jumeau de TUT-06 vu par l'enfant.
    C'EST LE MOINS CHER : ServiceSuivi sert les deux roles SANS UNE
    LIGNE DE PLUS -- les memes vues rendent alors sa seule seance et sa
    seule ligne de presence, c'est la BORNE qui change d'appelant, pas
    la requete. Attention, la section 6.6 de la spec d'etape interdit
    tout detail administratif a l'eleve : il lit SON etat, jamais celui
    d'un autre, et jamais un motif.
  - ENS-05, le profil enseignant. Le catalogue le dit REPORTE AVEC LE
    MODULE FINANCE (ADR-003) : verifier ce que la fiche peut porter sans
    argent avant de l'ouvrir.
N6 (mode suivi enseignant) vient AVEC le document partage : le Coran est
desormais en base, mais le canal de diffusion (question `e`) n'est
toujours pas tranche.

CE QUI N'EST PAS PROUVE, ET QU'IL NE FAUT PAS PRETENDRE AVOIR PROUVE :
un vrai cours. Personne n'a encore ouvert deux navigateurs sur une meme
seance. L'empechement, lui, est leve : l'authentification fonctionne en
production depuis le 13/09 au soir, prouvee par une vraie connexion.
Ce qui manque maintenant, c'est une SEANCE : IL N'EN EXISTE AUCUNE EN
BASE (verifie le 13/09 : 0 seance, 0 participant, 0 evenement, 7
profils). NI l'ecran du Coran NI le planning du controle NI le suivi du
foyer n'ont ete VUS avec des donnees : le premier et le deuxieme sont en
production sans seance a montrer, le troisieme n'y est meme pas deploye.

CE QUE LA NEUVIEME SESSION N'A PAS CONSTRUIT, ET CE N'EST PAS UN OUBLI :
  - le contenu pedagogique de TUT-06 : ce qui a ete travaille, les
    points de phonetique. C'est ENS-04, etape 6. Tant qu'aucun
    enseignant ne peut l'ecrire, aucun parent ne peut le lire, et une
    colonne vide ne comble pas un cahier absent.
  - la notification de fin de seance, que la fiche produit decrit
    pourtant comme ce qui justifie l'abonnement aux yeux du parent qui
    paie. Elle demande un canal : device_tokens est vide et l'etape D de
    l'onboarding reste ouverte. Ce serait un message sans destinataire.
  - le panneau de detail que le registre annoncait sur desktop : il n'a
    rien a porter de plus que sa ligne tant que le cahier n'existe pas.
    La fiche le remplace par le tableau dense, et le DIT.

CE QUE LA HUITIEME SESSION N'A PAS CONSTRUIT, ET CE N'EST PAS UN OUBLI :
  - les trois signalements automatiques de l'ADR-011 : leur place est
    l'espace admin, pas l'ecran du controleur. Ni CTR-03, ni le
    signalement d'incident a l'administrateur (aucune table, aucun
    canal).
  - verset.ligne reste NULLE. Le layout QPC v2 porte le decoupage en
    quinze lignes, mais il compte les mots autrement que le texte
    Tanzil : 83 668 contre 77 881, mesure. Les faire coincider
    demanderait de DEVINER une correspondance sur un texte sacre. 0007
    autorise la colonne nulle et rien a l'ecran n'en depend.
  - le lien vers tanzil.net n'est pas cliquable : url_launcher n'est pas
    au pubspec, et l'y ajouter demandait de toucher un fichier
    qu'OpenCode modifie. La source est bien citee au pied de chaque
    page, comme la licence l'exige.
  - le GESTE de correction manuelle (corrigee_manuel) et le marquage
    excusee. La table session_presence_override et ses policies
    existent depuis 0007, mais l'ecran demande confirmation, motif
    obligatoire et entree de journal : c'est un lot. La section 6.5 de
    la spec laisse d'ailleurs ce mecanisme explicitement ouvert.
  - le tuteur observateur ne lit ni sa presence ni la liste : il
    assiste, il n'est pas note. Le suivi d'un enfant est TUT-06.

LIVEKIT EST BRANCHE, ET C'EST VERIFIE, PAS SUPPOSE :
  create-room-token interrogee par HTTP avec la cle anon repond
  "401 authentification requise" et non plus "503 video non configuree".
  La fonction teste videoConfiguree() AVANT l'authentification : les
  trois secrets sont donc bien poses sur Supabase.
  Restent en angle mort LIVEKIT_CLOUD_WS_URL, que rien ne valide, et la
  cle qui signe le webhook -- les deux ne se prouvent qu'en salle.

LA PREMIERE MESURE QUI VAUT, DES QUE LA PROD SAIT AUTHENTIFIER :
  creer une seance a l'instant present entre un enseignant et un eleve
  (ADM-05 attribue, la seance nait du creneau), ouvrir deux navigateurs,
  et regarder. C'est le premier vrai cours, et la premiere preuve de
  bout en bout depuis le debut de l'etape 5. Elle exerce d'un coup N2,
  N3, N4, N5 et CTR-01. TANT QUE LA CLE EST FAUSSE, ELLE EST
  IMPOSSIBLE -- ce n'est pas un choix de priorite, c'est un prerequis.

DEUX ECARTS ASSUMES, ECRITS PLUTOT QUE MASQUES :
  - la sortie de ENS-03 mene a ENS-02, pas a ENS-04 : le cahier de
    transmission est l'etape 6 et n'a aucune route. Ne pas "reparer"
    par une route vide.
  - le document partage n'est pas construit : ni contenu a paginer (le
    Coran est N5) ni canal de diffusion tranche (question `e`). Le
    bouton "Ouvrir le Coran" N'EXISTE PAS plutot que d'etre grise.
    Les controles enseignant de niveau 1 viennent AVEC le document.

A LUI SOUMETTRE, PAS BLOQUANT (decisions prises par l'agent) :
  - ADR-021 : attribution hors disponibilites, avec motif.
  - ADR-022 decision 4 : la consultation du journal ne se journalise pas.
  - ADR-023 : deux fournisseurs video, route ancree par seance.
  - N3 : le bandeau permanent est EN BAS (fiche produit) et non en haut
    (spec d'etape section 7) -- les deux sources se contredisaient.
  - N4 : un masked_controller ne laisse AUCUNE ligne de presence lisible,
    pas meme a lui-meme ; seule l'administration la voit. L'ADR-011 ne
    tranchait que la video, et la trace d'une observation vit deja dans
    audit_logs.
  - N4 : la vue dit QU'UNE decision humaine a fige un etat, jamais
    POURQUOI. Le motif reste en base et au journal (section 6.6 interdit
    tout detail administratif a l'eleve).
  - ADR-024 : corpus coranique Tanzil, importe et non appele par API.
  - CTR-01 : le tuteur qui "assiste" entre VISIBLE et MUET, sans entree
    d'audit -- un parent qui regarde son enfant n'est pas un acces
    sensible ; le controleur entre INVISIBLE et journalise nommement.
  - CTR-01 : seule l'ADMINISTRATION voit une visite de controle. Ni le
    controleur lui-meme, ni ses collegues (regle de 0011 etendue a
    toutes les surfaces).
  - GALERIE=true en production : /_galerie est expose sur le site
    public. Le commentaire d'Env dit pourtant "une version de production
    ne contient pas la galerie". A trancher avec la reparation de la
    cle.
  - TUT-06 : entre parcours-utilisateurs.md (le cahier de transmission,
    etape 6) et 0011 (qui nomme TUT-06 dans son propre corps), l'ecran
    construit est celui que la base sait nourrir. Rien n'est pose pour
    le cahier, pas meme une colonne vide.
  - TUT-06 : un cours annule ou non tenu ne dit RIEN de l'enfant, meme
    quand etat_presence() calcule une absence. Le sort du cours prime
    sur l'etat de la personne.
  - TUT-06 : l'ecran ne porte AUCUNE action. Corriger un etat ou excuser
    une absence appartient a l'enseignant et a l'administration, avec
    motif et entree de journal (section 6.5). Un bouton chez le tuteur
    lui donnerait le droit de corriger ce qui compte pour la paie.
  - TUT-06 : la pastille sans phrase de contexte. La duree que porte
    LignePresence se compte depuis maintenant et n'a de sens que pendant
    le cours ; le libelle, lui, vient quand meme de
    LignePresence.libelle, pour que la salle et le suivi ne nomment
    jamais un etat autrement.

MIGRATIONS : plus aucune en attente. GARDER LE REFLEXE get_project_url
AVANT toute ecriture : le MCP a deja vise PISI (riaqzfhdynmtshvbgdvt)
au lieu de Rewayah (gggmtelinlpseweouyav) pendant des sessions entieres.

POUR MESURER :
  - SQL : docker, base neuve, stub_auth puis migrations 0001 a 0013,
    puis les NEUF fichiers de scenarios a la suite, dans cet ordre :
    etape3, etape4, etape5, adm05, n2, n4, ctr01, n5, adm04 -- adm04 EN
    DERNIER, toujours : il relit la chaine de hachage d'audit_logs, que
    toute emission de jeton ou visite de controle allonge.
    Reference 144 controles (125 + 10 pour CTR-01 + 9 pour N5).
    Astuce si le conteneur existe deja : creer une base neuve dedans
    (createdb) plutot que de le recreer -- stub_auth.sql echoue alors
    sur les roles deja presents, sans consequence : lancer le stub SANS
    ON_ERROR_STOP.
  - Flutter : blocage TLS de github.com toujours la (hook package:sqlite3).
    Contournement, dans le pubspec du worktree D:\ra-pwa-build UNIQUEMENT,
    jamais commite, retire apres :
       hooks:
         user_defines:
           sqlite3:
             source: system
    Methode : editer dans le depot, copier vers le worktree, mesurer
    la-bas. Reference 733/733 et 124 fichiers de jetons.
    ++ MESURE DU 13/09, NEUVIEME SESSION : `flutter test` a tourne DANS
    LE DEPOT PRINCIPAL, 733/733, SANS aucun contournement, et
    `dart run slang` aussi. Le blocage TLS ne les atteint plus. NE PAS
    EN CONCLURE qu'il a disparu pour `flutter build web` : cela n'a pas
    ete mesure, et c'est la commande qui avait ete refusee. Essayer
    d'abord dans le depot, garder le worktree comme repli. ++
    `dart analyze` fonctionne dans le depot principal, lui.
    Le playground d'OpenCode fait echouer verifier_jetons.dart (6
    violations qui ne sont pas les notres) : le deplacer hors de `lib/`
    le temps de la mesure, PUIS LE REMETTRE.
    ATTENTION en copiant vers le worktree : lib/main.dart, lib/app.dart
    et lib/core/config/env.dart y arrivent dans la version NON COMMITEE
    d'OpenCode, qui importe son playground. La compilation casse. Les
    restaurer depuis le commit avant de construire :
       git checkout <commit> -- lib/main.dart lib/app.dart lib/core/config/env.dart

PIEGES :
- OpenCode travaille EN PARALLELE sur le meme depot (lib/app.dart,
  lib/core/config/env.dart, lib/main.dart, lib/features/_dev/playground/).
  git status avant tout commit, ne jamais stager ses fichiers.
  ATTENTION : lib/features/_dev/galerie/ est SUIVI et c'est le notre ;
  seul _dev/playground/ est a OpenCode.
- DES FICHIERS NON COMMITES NE DISENT PAS QUI LES A ECRITS.
  Verifier par `git ls-files` avant de conclure a un travail concurrent.
- TOUT nouveau composant de lib/core/widgets/ doit avoir son entree de
  galerie ET sa ligne dans composantsDuCatalogue de
  catalogue_galerie_test.dart, ET sa ligne au catalogue de composants.
- DataCollection REND DEUX ARBRES DIFFERENTS. En tableau (desktop), chaque
  colonne est son propre Text ; en carte (mobile, tablette), les colonnes
  `secondaire` sont JOINTES en une seule chaine separee par un point
  median. Un `find.text('Rachid - TEACH-000001')` qui passe a 1400 trouve
  zero widget a 390 : il faut `find.textContaining`. Mesure, pas
  supposition : deux tests de TUT-06 sont tombes la-dessus.
- ET UN PRENOM D'ENFANT EST AUSSI UN LIBELLE DE PILULE. Sur un ecran qui
  filtre par personne, `find.text('Sofia')` trouve la pilule, pas la
  ligne. Prendre un temoin qui n'existe qu'une fois -- l'enseignant.
- Un libelle semantique de Pressable se FOND dans le noeud semantique
  avec le texte affiche dessous : find.bySemanticsLabel avec une chaine
  exacte ne trouve rien, il faut une RegExp. Et tester.ensureSemantics()
  fait ECHOUER le test si la poignee est liberee par addTearDown : la
  verification passe avant le teardown.
- Un provider Riverpod jamais observe n'est pas initialise : un
  ref.read(sessionProvider) au moment du clic trouve l'etat de
  chargement. La page l'observe donc dans build().
- verifier_jetons.dart refuse le tiret cadratin dans le code Dart, et
  tout Scaffold dans lib/features/ (passer par PageShell, PageParcours
  ou PageImmersive).
- journee_test.dart / "ENS-02 : le bloc dominant" est rouge entre 23h34
  et minuit seulement. Vert ne prouve pas repare.
- Un nouveau fichier de scenarios SQL ne s'ajoute PAS tout seul a ci.yml.
- DEPLOIEMENT, la commande exacte, depuis un worktree :
     cd "D:\ra-pwa-fix"; flutter build web --release --dart-define-from-file=dart_define.json
     cd "D:\ra-pwa-fix\build\web"; vercel deploy --prod --yes
  SANS --dart-define-from-file, Supabase n'est jamais initialise.
  vercel deploy NE CONSTRUIT RIEN : il televerse le disque.
  Puis OUVRIR L'APP ET LIRE LA CONSOLE. Reference : main.dart.js fait
  4 442 280 octets avec le Coran et le planning du controle.
  ++ LIRE LE dart_define.json AVANT DE CONSTRUIRE ++ celui de
  D:\ra-pwa-build porte une CLE FACTICE et GALERIE/PLAYGROUND a true.
  Trois controles sur le bundle servi, pas un seul :
     gggmtelinlpseweouyav PRESENT (l'app est configuree),
     "cle-factice" ABSENT (la cle est vraie),
     une chaine du dernier lot PRESENTE (c'est bien le bon bundle).
  Et un quatrieme qui vaut les trois autres : SE CONNECTER.
- DEUX SESSIONS SUR LE MEME DEPOT, ca marche : reserver par message
  AVANT de commencer (numero de migration, worktree, liste de fichiers),
  n'editer les fichiers partages que de facon ciblee, et relire le
  fichier juste avant de l'editer. Chacun son worktree de mesure : deux
  flutter build dans le meme dossier se detruisent. Celui dont le code
  est IMPORTE par l'autre pousse EN PREMIER. UN SEUL DEPLOIEMENT, par
  celui qui finit en dernier, depuis main a jour : il deploie son
  travail ET celui de l'autre.

Un lot par session. Ignore la branche refactor-ui-lavender.
FIN DE SESSION : livrer un prompt de reprise et mettre a jour cette
section 9. Consigne permanente de l'operateur.
```

### 9.6 Ce que la dixieme session a livre — le suivi eleve

Le lot R3 a branche `/eleve/suivi` sur la route existante, sans dupliquer
l'arbre de routes et sans toucher au backend. La page reutilise
`ServiceSuivi`, `VueSuiviFoyer`, `PageShell`, `DataCollection`, `Skeleton`,
`EmptyState` et `LignePresence`. Elle lit donc les projections deja bornees par
RLS, ne filtre aucun eleve cote client, reste limitee a l'etat du compte
connecte, et n'expose ni autre eleve, ni motif, ni action de correction, ni
detail administratif. Le marqueur de consolidation de `LignePresence` est
desactive pour cette vue, sans changer le comportement des appelants existants.

Fichiers du lot :

- `lib/features/suivi_eleve/suivi_eleve_page.dart`
- `test/features/suivi_eleve_test.dart`
- `lib/core/router/app_router.dart`
- `lib/core/widgets/ligne_presence.dart`
- `assets/i18n/fr.i18n.json`, `assets/i18n/ar.i18n.json`
- `lib/core/i18n/strings.g.dart`, `strings_fr.g.dart`, `strings_ar.g.dart`

La page couvre les etats chargement, contenu, vide, erreur/reprise, inconnu,
RTL et texte a 200 pour cent. Les lignes sont rendues du plus recent au plus
ancien par la vue partagee. Le modele `Seance` ne porte pas de matiere ou de
nom de cours : la colonne affiche donc le libelle exact et honestement borne
`Cours de Coran`, a revoir seulement si le domaine introduit un champ de cours.

Controles executes :

- `flutter analyze --no-pub` : vert, `No issues found!` (168,8 s).
- `flutter test --no-pub test/features/suivi_eleve_test.dart` : vert, 7 tests.
- `flutter test --no-pub test/accessibilite/clavier_test.dart test/accessibilite/rtl_echelle_texte_ecrans_test.dart` : vert, 46 tests.
- `flutter test --no-pub test/router/navigation_test.dart test/router/redirection_test.dart` : vert, 68 tests.
- `dart run tool/verifier_jetons.dart` : rouge sur 6 violations deja presentes dans `lib/features/_dev/playground/playground_racine.dart`, fichier concurrent protege, aucune violation dans les fichiers du lot.
- `git diff --check` : vert sur le diff inspecte ; les avertissements CRLF de Git ne sont pas des erreurs.

Les fichiers proteges `lib/app.dart`, `lib/main.dart`, `lib/core/config/env.dart`,
`lib/features/_dev/playground/` et les fichiers Windows Flutter generes ont ete
preserves. Aucun commit n'a ete fait avant revue. Prochaine reprise : revue
finale du diff cible, puis decider si le lot R3 peut etre committe sans inclure
les changements concurrents ; ne pas refaire le diagnostic global ni le SQL.

### 9.7 Recette bout-en-bout MVP-0 - 14 septembre 2026

La recette demandee a ete executee dans son perimetre QA, sans ajout de fonctionnalite ni migration.

Preuves mesurees : `SQL_RECIPE_OK` apres 23 commandes SQL (stub, migrations 0001 a 0013, puis les neuf scenarios dans l'ordre) ; `dart analyze --fatal-infos` termine par `No issues found!` ; `flutter test --no-pub` termine par `743/743` en environ 4 min 20 s. Chrome et Edge headless ont rendu le shell HTML public.

Le verificateur de jetons reste rouge sur six violations du playground OpenCode concurrent. Cette mesure n'est pas attribuee au lot R3.

Ecart bloquant : aucune seance reelle n'a ete creee ou rejointe. Les comptes de test autorises et acces aux boites de reception des quatre roles ne sont pas fournis, et la mise en service documente qu'aucun compte LiveKit n'est pose. Il n'y a donc aucune preuve runtime des parcours enseignant, eleve, tuteur et controleur, ni de salle, presence, Coran, suivis, observation invisible, non-fuite, retour, 390/768/1440, RTL, clavier, texte a 200 pour cent, hors-ligne ou doublons d'abonnement. Les tests Flutter ne remplacent pas cette recette navigateur.

Le deploiement n'a pas ete relance : `vercel inspect` a repondu que le jeton manquait et la tentative HTTP PowerShell a ete interrompue par TLS. Aucun secret n'a ete imprime ni modifie.

Prompt suivant : fournir les quatre comptes de test autorises et leurs acces OTP/lien, confirmer LiveKit et la version de production cible ; executer ensuite uniquement la recette navigateur MVP-0 et completer ce journal. Ne pas coder, migrer, creer de compte non autorise ni deployer le travail concurrent non valide.

### 9.8 Durcissement ENS-05 : securite, configuration et deploiement — 14 septembre 2026

Ce lot est limite a `lib/core/config/env.dart`, au test de configuration et a
la preparation du build/deploiement. Aucun ecran ENS-05, migration SQL, API ou
changement de domaine n'a ete ajoute.

`Env.configuree` refuse maintenant une URL Supabase autre que HTTPS ou
placeholder, une valeur vide, une valeur factice, une cle mal formee, un JWT
invalide ou une cle publishable trop courte. Les cles legacy sont verifiees par
leur forme JWT et leurs claims `HS256`/`supabase`/`anon`; les cles
`sb_publishable_` sont verifiees par leur prefixe et leur alphabet. La methode
ne fait aucun appel reseau et n'affiche jamais la valeur recue. Le fichier
`env.dart` du checkout principal conserve les ajouts concurrents Sentry et
Playground d'OpenCode ; ils n'ont pas ete stages ni ecrases.

La decision de production est tranchee : `GALERIE=false` et `PLAYGROUND=false`.
Le build a ete fait dans le worktree detache `D:\ra-pwa-secure-deploy`, sur
`cbc4ff8`, avec la definition locale de production deja existante. Controle
non secret de cette definition : reference Supabase
`gggmtelinlpseweouyav`, cle JWT de 208 caracteres, `GALERIE=false`,
`PLAYGROUND=false`.

Controles mesures dans ce worktree :

- `flutter analyze --no-pub` : vert, `No issues found!`.
- test cible `test/config/supabase_key_validation_test.dart` : vert, 3 tests.
- `flutter test --no-pub` : vert, 729 tests.
- `dart run tool/verifier_jetons.dart` : vert, 123 fichiers, aucune violation.
- `flutter build web --release --dart-define-from-file=dart_define.json` : vert,
  bundle `build/web` de 4 418 221 octets.
- inspection locale du bundle : reference Supabase presente, cles factices
  absentes, `_galerie` absent, `PLAYGROUND` absent, route `eleve/suivi`
  presente.

La promotion n'est pas encore une preuve de mise en ligne : `vercel deploy
--prod --yes` a cible le `project.json` existant `rewayah-academy`, puis Vercel
a demande une authentification locale (`No existing credentials found`). La
tentative a ete arretee apres l'attente du flux appareil. Aucun nouveau projet
n'a ete cree. En consequence, le bundle servi, la console distante et une
connexion reelle Supabase ne sont pas encore verifies dans ce lot. Reprendre
apres authentification Vercel, avec la meme commande depuis
`D:\ra-pwa-secure-deploy\build\web`, puis mesurer le bundle servi et la
connexion reelle sans imprimer de cle.

### 9.9 Reprise de promotion — 14 septembre 2026

L'authentification appareil Vercel a ete acceptee par l'operateur. La
promotion a ensuite cible le projet existant `rewayah-academy`, deployment
`dpl_3MY9XhoivMp3BpwEVUlIAJUOSzPe`, et s'est terminee en `READY` avec alias
stable `https://rewayah-academy.vercel.app`. Aucun nouveau projet n'a ete cree.

Controles du bundle effectivement servi par l'alias stable :

- racine HTTP `200` ; `main.dart.js` HTTP `200`, 4 418 221 octets ;
- reference Supabase `gggmtelinlpseweouyav` presente ;
- cle factice absente ;
- `_galerie` absent, donc galerie non livree ;
- `PLAYGROUND` absent ;
- marqueur de route `eleve/suivi` present.

Connexion reelle mesuree hors navigateur : lecture HTTPS de
`/auth/v1/settings` avec la definition de production locale et la cle non
affichee : `200 OK`, `application/json`, projet
`gggmtelinlpseweouyav`. Cela prouve la connectivite Supabase et l'acceptation
de la configuration client par l'API. Cela ne constitue pas une preuve de
session utilisateur ou de parcours magic-link, qui reste une recette
authentifiee distincte. Le controle PowerShell/curl direct a rencontre
`CRYPT_E_REVOCATION_OFFLINE`; la verification Node HTTPS a reussi sans
desactiver TLS.
### 9.8 Reprise apres reconnexion Vercel - 14 septembre 2026

Vercel est maintenant authentifie sous `rewayahacademy-3863`. La lecture seule
de la production confirme : alias `https://rewayah-academy.vercel.app`, etat
`READY`, sous-etat `PROMOTED`, deployment `dpl_3MY9XhoivMp9eSjCN52sgS86GEu2`,
et commit metadata `cbc4ff8dca794762a57ce25ae44ddebd48c4cf56`.

Point important : l'API Vercel signale `gitDirty=1`, `source=cli` et un build
direct. Cette livraison ne peut donc pas etre presentee comme le seul commit
`cbc4ff8` ; elle contient potentiellement le travail non commite de l'autre
agent Codex. Aucun nettoyage, reset ou redeploiement n'a ete fait.

`version.json` servi par le deployment a ete lu via l'API Vercel : version
`0.2.0`, build `1`. Edge headless a rendu le shell Flutter HTML de l'alias
production. La protection de deployment et le probleme TLS de curl ont empeche
une lecture HTTP CLI complete du bundle ; aucun secret n'a ete extrait.

La recette authentifiee reste donc non executee : aucune identite de test
autorisee avec acces OTP/lien n'est disponible dans le contexte courant, et le
compte LiveKit reste non confirme. Ne pas qualifier les quatre roles, la salle,
la presence, les suivis, l'observation invisible, les controles responsive,
hors-ligne ou abonnements avant cette session reelle.

## 10. Handoff de clôture — inventaire complet et prompts actifs

### 10.1 Statut de lecture

Ce plan consolide les spécifications d'origine (`D:\RA _APP\docs de lancement`),
les décisions ADR, la refonte UX/UI (`docs/design/`) et l'état mesuré du
checkout au 14 septembre 2026. Une mention « documentée » n'est pas une preuve
de fonctionnement : chaque lot doit apporter son code, ses tests et, lorsque
nécessaire, une mesure réelle.

**OpenCode est mort et hors plan.** Ses modifications concurrentes sont
préservées comme état existant, mais aucun prompt ne lui est destiné, aucun de
ses fichiers ne doit être intégré par accident et aucun build issu d'un
worktree sale ne doit être attribué à un commit propre.

### 10.2 Ce qui reste à implémenter pour fermer le MVP-0

| Priorité | Lot restant | Périmètre concret | État actuel / preuve attendue |
| :--- | :--- | :--- | :--- |
| P0 | Finaliser R3 — suivi élève | Relire le diff local de `lib/features/suivi_eleve/`, ses tests, le routeur, les chaînes et `LignePresence`; séparer les fichiers concurrents; mettre à jour le catalogue et le handoff; commit propre | Le code est présent dans le worktree, mais le lot est non committé. Les tests ciblés ont été verts; refaire la revue ciblée avant commit |
| P0 | Refonte loading | Remplacer les textes « Chargement… » et les `EmptyState` détournés par `Skeleton` sur les écrans restants; conserver les cinq états `loading/content/empty/error/offline`; couvrir les écrans réels, pas seulement la galerie | La Bible §18 et `docs/design/08-catalogue-ecrans.md` signalent encore cet écart; `ADM-05`, `ADM-04`, `TUT-06` et le suivi élève fournissent les motifs existants |
| P0 | `ENS-04` — cahier de transmission | Écran enseignant depuis la sortie de salle, saisie en une main en moins de 45 s, constats Makharij, états offline/error/reprise, lecture par `TUT-06` et suivi élève; aucun objectif inventé | Absent du catalogue comme écran construit et absent des migrations dédiées `lesson_reports`/`makharij_findings` au-delà du socle initial |
| P0 | Synchronisation du cahier | File locale Drift, écriture locale hors ligne, clé d'idempotence, rejeu après reconnexion, Edge Function `submit-lesson-report`, policies/RLS et scénarios SQL | Le socle et les tables de base existent, mais la fonction, le parcours complet et la preuve de rejeu restent à livrer |
| P0 | `ENS-05` — profil enseignant | Construire `/enseignant/profil` selon la fiche de la refonte, avec données réellement disponibles, états et accessibilité; ne pas y glisser le portefeuille/payout | La route rend encore `EcranAConstruire`. La spécification d'origine nommait `ENS-05` le payout V1; la refonte l'a renommé profil enseignant. Décision retenue ici : profil en MVP, finance en V1, à confirmer par l'opérateur |
| P0 | N6 — Coran partagé | Mode suivi enseignant, page/verset partagé, séparation état partagé / position personnelle, retour vers l'enseignant, contrôles niveau 1; choisir et documenter le canal de diffusion avant le code | Le lecteur personnel N5 existe. Le bouton partagé est volontairement absent; le canal LiveKit data / Realtime n'est pas tranché |
| P0 | Présence corrigeable | Geste enseignant/admin pour `corrigee_manuel` et `excusee`, motif obligatoire, confirmation, journalisation et policies; définir l'écran propriétaire | N4 affiche les états mais ne permet pas la décision humaine; la fiche d'étape laisse ce mécanisme ouvert |
| P0 | Chaîne LiveKit réelle | Fournisseur confirmé, secrets `LIVEKIT_CLOUD_WS_URL`, `LIVEKIT_CLOUD_API_KEY`, `LIVEKIT_CLOUD_API_SECRET`, webhook fournisseur, puis séance réelle enseignant/élève/tuteur/contrôleur | Le code N2 et les Edge Functions sont documentés comme posés; aucun compte LiveKit ni parcours de salle autorisé n'est prouvé |
| P0 | Enregistrement safeguarding | Egress audio-only systématique, chiffrement, rétention 30 jours, stockage privé R2 et accès journalisé; vérifier le contrat d'information | ADR-002 le rend obligatoire, mais aucun Egress/R2 opérationnel n'est présent dans le périmètre livré |
| P0 | Recette navigateur authentifiée | Quatre comptes de test autorisés avec OTP/lien; tester login, rôles, salle, présence, Coran, suivi, observation invisible, non-fuite, retour, offline/reconnexion, 390/768/1440, RTL, clavier, 200 %, doublons d'abonnements | La recette headless publique et les tests Flutter ne remplacent pas cette preuve; Chrome DevTools MCP n'est pas disponible dans ce contexte |

### 10.3 Compléments d'implémentation et d'exploitation encore ouverts

- **Notifications** : enregistrer les appareils et fournir un canal réel pour la
  validation KYC, l'attribution et la fin de séance; `device_tokens` existe au
  niveau du modèle, mais le canal push et ses secrets ne sont pas livrés.
- **Audio enfant** : enregistrer les libellés français attendus par
  `AudioLabel`; `assets/audio/fr/` ne contient encore que `.gitkeep`.
- **Arabe** : remplir la traduction arabe de l'interface ou documenter
  explicitement sa non-livraison; le fichier et les clés existent mais la
  traduction est vide. Le poular, lui, a été explicitement écarté.
- **Sentry, variantes et mémoire graphify** : onboarding F non fait, trois
  identifiants `dev/staging/prod` non séparés, étape K encore ouverte.
- **Authentification production** : SMTP externe pour les liens destinés aux
  vrais usagers, OAuth Google si ce parcours est conservé, réglages Auth
  écrasés par `config push` à revalider avant ouverture publique.
- **Média et déploiement natifs** : compte Cloudflare/R2; réparation TLS du
  magasin de certificats pour l'APK; ATL Visual Studio pour Windows; Mac/Xcode
  et compte Apple pour iOS. La PWA reste le chemin réel tant que le natif n'est
  pas publié.
- **PWA et exploitation** : décider d'un hébergement compatible avec l'usage
  commercial; mesurer le démarrage à froid sous 1,5 s sur un appareil réel;
  confirmer le deployment propre, car le dernier build signalait `gitDirty=1`.
- **Hygiène frontend issue de la refonte** : les variantes desktop pleine
  largeur / multi-colonnes et certains panneaux de détail sont reportés dans
  les fiches; le rafraîchissement par geste demande une décision sur
  `PageShell.onRafraichir`; le lien tanzil.net reste affiché mais non
  cliquable; le découpage exact en quinze lignes du mushaf reste volontairement
  reporté faute de correspondance fiable.
- **Mesures accessibilité réelles** : test lecteur d'écran sur un appareil,
  clavier et zoom sur les navigateurs cibles, en complément des tests Flutter.

### 10.4 Ce qui est explicitement V1 — ne pas le coder pour fermer le MVP-0

- espace comptable `CPT-01`, portefeuille, collecte, payout, webhooks de
  paiement et abstraction `PayoutProvider`;
- système d'objectifs/évaluations si la question ouverte confirme qu'il est
  distinct du cahier de transmission;
- messagerie contextuelle, groupes/cohortes et montée en charge
  auto-hébergée;
- écran `CTR-03` et séquestre/exports `ADM-03` **tant que leur contradiction
  de périmètre n'est pas tranchée**. Les sources d'origine les ont réintroduits
  au MVP-0, tandis que le parcours et les décisions ultérieures les reportent;
  aucune implémentation ne doit choisir une version en silence.

### 10.5 Décisions opérateur avant les lots concernés

1. Confirmer le découpage `ENS-05 = profil enseignant MVP` et `CPT-01 = finance
   V1`, malgré le nom historique de `ENS-05` dans les specs d'origine.
2. Trancher le périmètre de `ADM-03` et `CTR-03` : MVP-0 ou V1.
3. Choisir le canal du document Coran partagé (N6).
4. Définir qui peut corriger/excuser une présence, avec le motif et le délai.
5. Confirmer `child_ui_mode_max_age = 8` et la politique de compression serveur
   des photos.
6. Trancher la règle de paiement en cas de litige entre minimum payable et
   présence mesurée, puis nommer les événements d'audit métier manquants.
7. Confirmer la source/licence technique du corpus Coran, même si Hafs/Madina
   et les 604 pages sont déjà tranchés.

### 10.6 Séquence de prompts actifs — Claude Code uniquement

Les prompts ci-dessous sont indépendants et doivent être exécutés dans l'ordre.
Un prompt = un lot, un diff relisible, contrôles, mise à jour du handoff et
commit. Aucun prompt OpenCode n'est fourni.

#### Prompt 1 — reprise sûre et fermeture de R3

```text
Tu es Claude Code. Dépôt: D:\RA _APP\RA -OFFICIAL-APP, branche main.
Lis d'abord docs/HANDOFF.md, docs/PROGRESS.md, docs/design/00-bible-frontend-v2.md,
docs/design/README.md, docs/architecture/decisions.md, lib/CLAUDE.md et
supabase/CLAUDE.md si nécessaire. Charge aussi le contexte Rewayah persistant.

Objectif unique: auditer puis fermer le lot R3 suivi élève déjà présent dans le
worktree. Ne touche pas à lib/app.dart, lib/main.dart, lib/core/config/env.dart,
lib/features/_dev/playground/ ni aux fichiers Windows générés: ces changements
sont concurrents et OpenCode est abandonné. Commence par git status, le diff
ciblé et la liste des fichiers non suivis.

Vérifie la fiche de /eleve/suivi, la borne RLS, l'absence de filtrage client,
loading/content/empty/error/offline, inconnu, RTL, 200 %, navigation et
accessibilité. Corrige seulement les blockers du lot R3, sans ajouter de
fonctionnalité. Lance les tests ciblés puis analyze, verifier_jetons et
git diff --check. Stage uniquement les fichiers R3 autorisés, mets à jour
docs/HANDOFF.md et docs/PROGRESS.md avec les sorties réelles, puis commit le
lot. Si un contrôle échoue, corrige avant de déclarer le lot terminé.
```

#### Prompt 2 — fermer l'écart Skeleton de la refonte

```text
Tu es Claude Code. Travaille dans D:\RA _APP\RA -OFFICIAL-APP.
Lis le handoff actif section 10, la Bible Frontend V2, docs/design/07-catalogue-
composants.md et docs/design/08-catalogue-ecrans.md.

Objectif unique: remplacer les chargements textuels ou EmptyState détournés
encore présents par Skeleton cohérent, écran par écran, sur les écrans du
catalogue qui lisent un AsyncValue ou une pagination. Ne change aucune règle
métier, aucune source de données et aucun fichier concurrent OpenCode.

Conserve séparément loading avec données précédentes, content, empty réel,
error avec reprise et offline. Ajoute/actualise les tests widget de chaque
écran touché, vérifie RTL, 200 %, clavier et responsive. N'invente aucun jeton:
réutilise les composants et mesures existants. Termine par verifier_jetons,
dart analyze --fatal-infos, flutter test et git diff --check; mets à jour le
catalogue/handoff avec les écarts réellement fermés et commit ce seul lot.
```

#### Prompt 3 — construire le profil enseignant MVP

```text
Tu es Claude Code. Dépôt D:\RA _APP\RA -OFFICIAL-APP.
Avant de coder, relis la fiche ENS-05 de docs/design/08-catalogue-ecrans.md,
docs/design/00-bible-frontend-v2.md, docs/design/02-regles-ux.md,
docs/design/05-regles-responsive.md, docs/design/06-accessibilite.md et les
services de profil existants. N'implémente pas CPT-01 ni le payout V1.

Construis /enseignant/profil avec la donnée réellement disponible: identité
autorisée, identifiant immuable, statut et éléments de profil prévus par la
fiche, sans inventer de photo publique, de finance ou de capacité. Utilise les
composants partagés, le routeur unique et les états loading/content/empty/error/
offline. Ajoute tests widget/navigation/accessibilité et une preuve de non-
exposition des champs interdits. Préserve tous les changements concurrents,
puis analyze, tests, verifier_jetons, diff check, handoff et commit du seul lot.
```

#### Prompt 4 — N6 transmission, offline et suivi

```text
Tu es Claude Code. Dépôt D:\RA _APP\RA -OFFICIAL-APP.
Lis la spécification de l'étape 5, les décisions ADR, les fiches ENS-04,
TUT-06 et suivi élève, l'architecture de cache Drift, lib/CLAUDE.md et
supabase/CLAUDE.md. Ne commence pas si les décisions N6 sur le canal Coran
partagé et la correction de présence ne sont pas explicitement fournies dans
le handoff; signale le blocage sans inventer.

Quand les décisions sont présentes, implémente un lot vertical: migration(s)
nécessaire(s) et RLS, Edge Function idempotente submit-lesson-report, file
locale Drift avec rejeu offline, écran ENS-04 en moins de 45 secondes, route de
sortie de salle, lecture honnête par TUT-06/suivi élève, et éventuellement le
mode Coran partagé seulement si le canal est tranché. Ajoute scénarios SQL,
tests Dart/widget et tests de doublon/reconnexion. Aucun filtrage client et
aucune règle métier inventée. Contrôles complets, mise à jour HANDOFF/PROGRESS,
commit atomique du lot; aucun fichier OpenCode.
```

#### Prompt 5 — LiveKit, Egress et production après autorisation

```text
Tu es Claude Code en mode implémentation contrôlée. Travaille dans
D:\RA _APP\RA -OFFICIAL-APP. Ne crée aucun compte et ne déploie rien sans
autorisation explicite et secrets fournis localement.

À partir de docs/HANDOFF.md section 10 et docs/MISE-EN-SERVICE.md, vérifie
d'abord l'état réel read-only de 0006+ et des Edge Functions; la documentation
contient des historiques contradictoires, donc ne rejoue aucune migration à
l'aveugle. Si le compte LiveKit et R2 sont confirmés, ferme le lot d'intégration:
secrets locaux, webhook signé, pre-flight, audio prioritaire, caméra/micro
éteints à l'entrée, Egress audio-only chiffré/rétention 30 jours et accès
journalisé. Sinon produis seulement le diagnostic et la liste exacte des
prérequis.

Après code autorisé: scénarios SQL, tests d'idempotence/RLS, analyze, tests,
verifier_jetons, build release depuis un commit propre, puis recette navigateur
avec comptes autorisés. Ne divulgue aucun secret, ne touche pas au playground
OpenCode et ne qualifie aucun parcours sans preuve runtime.
```

#### Prompt 6 — clôture QA et documentation

```text
Tu es Claude Code. Aucun code nouveau sans blocker démontré.
Relis docs/HANDOFF.md section 10 et exécute uniquement la recette de clôture
autorisée: build depuis un commit propre, analyse, tests, verifier_jetons,
contrôles SQL contre une base identifiée, puis navigateur réel avec les quatre
comptes de test et le compte LiveKit fournis par l'opérateur. Mesure les quatre
rôles, la salle, présence, Coran, suivi, observation invisible/non-fuite,
retour, 390/768/1440, RTL, clavier, 200 %, offline/reconnexion et absence de
doubles abonnements. Capture les erreurs console/réseau et les preuves sans
afficher de secret.

Ne transforme jamais un test Flutter ou la documentation en preuve navigateur.
Ne corrige que les blockers reproduits, puis consigne chaque résultat dans
docs/HANDOFF.md et docs/PROGRESS.md, avec deployment/commit exact et statut
READY seulement s'il est vérifiable. OpenCode reste abandonné.
```

#### Prompt 7 — ADM-03 / CTR-03, seulement si le MVP-0 est confirmé

```text
Tu es Claude Code. N'exécute ce prompt que si l'opérateur a écrit dans le
handoff que ADM-03 et CTR-03 restent dans le MVP-0. Les documents se
contredisent actuellement; sans cette décision, arrête-toi après le diagnostic.

Lis l'audit d'origine, ADR-003, ADR-011, les fiches ADM-03/CTR-03 et
supabase/CLAUDE.md. Implémente ADM-03 côté serveur, jamais comme export natif
de données déjà téléchargées: demande, approbation, génération XLSX/PDF,
bucket privé, URL signée courte à usage unique, audit et rétention. Implémente
CTR-03 comme lecture/évaluation conforme à la politique d'anonymat retenue,
avec RLS et journalisation; ne révèle pas les identités interdites.

Ajoute migrations versionnées, Edge Functions, tests RLS/idempotence, scénarios
de sécurité et écrans catalogués avec tous leurs états. Pagination et limites
de débit doivent rester côté serveur. Contrôles complets, handoff et commit
isolé. Aucun export de données réelles pendant les tests, aucun changement
OpenCode.
```

#### Prompt 8 — V1 finance et modules différés

```text
Tu es Claude Code. N'ouvre ce lot qu'après clôture documentée du MVP-0 et
arbitrage produit séparé. Relis l'audit d'origine, ADR-003/007/014, les
questions ouvertes et les fiches écran concernées.

Implémente par lots verticaux séparés, jamais en bloc: finance (ledger,
access_until/credits si encore nécessaire, topup-intent, payment-webhook,
PayoutProvider multi-fournisseurs, verrou 48 h, invoice serveur, CPT-01/TUT-03
et la partie payout d'ENS-05), puis objectifs/évaluations si l'opérateur
confirme leur définition, puis messagerie contextuelle et cohortes si elles
sont spécifiées. Chaque lot doit avoir son contrat de données, sa migration,
RLS, idempotence, audit, tests et fiche d'écran dans le catalogue.

Ne choisis aucun prestataire ou seuil financier sans décision écrite; ne
réintroduis pas Flutterwave sans vérification de couverture GNF/XOF; ne mets
aucune donnée sensible dans le client. Termine chaque sous-lot par les
contrôles, la documentation et un commit séparé. OpenCode reste abandonné.
```

### 10.7 Sortie attendue de chaque lot

Un lot n'est clos que si le diff est isolé, les contrôles sont réellement
exécutés, les décisions nécessaires sont écrites, `docs/HANDOFF.md` et
`docs/PROGRESS.md` sont cohérents, et le commit exact est indiqué. Les preuves
de production et les secrets restent séparés du code et ne sont jamais copiés
dans le dépôt.

## 11. Réparation de la compilation web et du déploiement — 18 septembre 2026

Entre le 14 septembre et aujourd'hui, un agent externe (« Antigravity »,
worktree `C:\Users\dell\.gemini\antigravity\worktrees\...`) a fusionné dans
`main` la quasi-totalité des branches `codex/*` restées ouvertes (login
courriel/mot de passe, correction de présence, système de design R1/R2,
intégration Vague 5, refonte lavande) via une série de merges puis un commit
`chore: sync all local changes` (`99c7b6a`), et a ajouté un workflow GitHub
Actions `Flutter Web → Vercel` (`.github/workflows/flutter-deploy.yml`) plus
un `vercel.json`. Il s'est arrêté là, faute de jetons — **sans jamais vérifier
que `main` compilait**.

**Ce que ça cassait, mesuré et non supposé :** `main` ne compilait plus du
tout. `flutter build web` échouait sur trois trous d'intégration laissés par
la fusion — `nav.eleve.compte` / `nav.enseignant.compte`, la page `/compte`
entière (`lib/features/compte/compte_page.dart`, ~90 clés i18n), et
`enseignant.profil` (`ENS-05`) — plus `Env.authParMotDePasseActive`, absent
alors que `SessionControleur.ouvrirDemo` le lit déjà pour fermer son propre
raccourci de démonstration. `dart analyze` ne voit pas ces trous tant que le
fichier qui les déclenche n'est pas dans le graphe compilé ; seul
`flutter build web` les a révélés.

**Effet en production, vérifié par API Vercel avant correction :** le
déploiement automatique Git de Vercel (le projet n'a pas de framework
déclaré : zéro-config, aucun `flutter build`) s'est déclenché sur chaque push
vers `main`, a produit un build vide en 292 ms (« Skipping cache upload
because no files were prepared ») et l'a promu en production — silencieusement,
puisqu'un déploiement Vercel « READY » ne dit pas s'il contient une
application. `rewayah-academy.vercel.app` rendait **404 sur toutes les
routes**, y compris l'URL unique du déploiement. Le workflow GitHub Actions,
lui, échouait probablement à la même étape de compilation (aucune trace de
déploiement `source:"cli"` correspondant dans l'historique Vercel).

### Correctifs, commit `fdf5168`

- `assets/i18n/fr.i18n.json` (+ `strings.g.dart`/`strings_fr.g.dart`
  régénérés par `dart run slang`) : ajoute `nav.eleve.compte`,
  `nav.enseignant.compte`, la section `compte` complète et
  `enseignant.profil`. Aucune traduction existante touchée ; `ar.i18n.json`
  n'avait pas besoin de ces clés (il ne porte pas de section `nav`, la
  génération retombe sur le français).
- `lib/core/config/env.dart` : ajoute `authParMotDePasseActive`
  (`bool.fromEnvironment('AUTH_PAR_MOT_DE_PASSE')`, faux par défaut, même
  patron que `GALERIE`/`PLAYGROUND`). Le gate dans `session_controleur.dart`
  existait déjà et jette une `StateError` si le flag est faux — seule la
  déclaration manquait.
- `lib/features/_dev/playground/faux.dart` (fichier Playground OpenCode,
  édité au strict minimum) : implémente `connexionMotDePasse` sur
  `FauxServiceAuth`, méthode manquante de l'interface `ServiceAuth` qui
  bloquait la compilation même avec `PLAYGROUND=false` (Dart type-check tout
  le graphe importé, indépendamment des `if` runtime).
- `vercel.json` : `git.deploymentEnabled.main = false`. Arrête le
  déploiement automatique zéro-config de Vercel sur push vers `main` — la
  cause du remplacement silencieux de la production par un build vide.
  Le déploiement reste possible par le workflow GitHub Actions (`vercel
  deploy build/web --prod`, un déploiement CLI, non concerné par ce
  réglage) ou par un `vercel deploy` manuel.

**Décision de sécurité, pas seulement de compilation :** `AUTH_PAR_MOT_DE_PASSE`
reste absent du build de production (comme `GALERIE` et `PLAYGROUND`) — sans
ce flag, quiconque tape `admin@n'importe-quoi` obtiendrait une session admin
sans jamais toucher Supabase. Ce raccourci reste réservé à une compilation
locale explicite.

### Déploiement vérifié

Build fait dans un worktree détaché `D:\ra-pwa-deploy-20260918` sur `main`
(commit `99c7b6a` puis correctifs), avec la vraie clé `anon` Supabase (projet
`gggmtelinlpseweouyav`, lue via l'outil MCP `get_publishable_keys`, jamais
tapée à la main) et `GALERIE=false`, `PLAYGROUND=false`,
`AUTH_PAR_MOT_DE_PASSE` omis.

- `flutter analyze --no-pub lib` : `No issues found!`. (`test/` porte encore
  trois clés `connexion.seConnecter`/`connexion.erreurConnexion` obsolètes,
  sans effet sur le build — voir « Reste ouvert ».)
- `flutter build web --release` : succès, `build/web/main.dart.js` = 4 645 882
  octets.
- Bundle inspecté : réf. Supabase présente, clé factice absente, `_galerie`
  absent (recherche sensible à la casse), route `/compte` présente, route
  `eleve/suivi` présente.
- Déployé sur le projet Vercel `rewayah-academy`
  (`prj_xDldWMLNH726BpwEVUlIAJUOSzPe`) : `dpl_6dmPw77rvMCQ94RH6jDXcGiS6f2p`,
  `READY`, `target: production`, aliasé sur `rewayah-academy.vercel.app`.
- Vérifié après coup : `GET /` → 200, `GET /main.dart.js` → 200 (même
  taille), `GET https://gggmtelinlpseweouyav.supabase.co/auth/v1/settings`
  avec la clé réelle → 200 (Google et courriel/OTP activés côté Supabase).

Poussé sur `origin/main` (`99c7b6a..fdf5168`) **après** vérification que le
build/déploiement fonctionnait, conformément à la règle « build vert →
commit et push sans redemander ».

### Piège de déploiement payé ce jour-là, à ne pas rouvrir

⚠ **`vercel deploy <dossier>` cherche `.vercel/project.json` DANS
`<dossier>`, pas dans le répertoire courant.** Un premier essai avec
`.vercel/project.json` posé à la racine du worktree et
`vercel deploy build\web --prod` a donc ignoré ce lien et **créé un nouveau
projet Vercel nommé `web`** (`prj_6MlTdLfO4xBnHNm6K5tDX3At6is3`, dans la
même équipe) au lieu de viser `rewayah-academy`. Ce projet orphelin
(un seul déploiement, aucun trafic) n'a pas pu être supprimé : aucun outil
MCP Vercel connecté n'expose de suppression de projet. **À supprimer
manuellement depuis le tableau de bord Vercel si l'opérateur le souhaite** —
Project Settings → `web` → Advanced → Delete. Le correctif : placer (ou
`vercel link` pour écrire) `.vercel/project.json` DANS le dossier passé à
`vercel deploy`, ou lancer la commande depuis l'intérieur de ce dossier.

### Reste ouvert

- **Le workflow GitHub Actions `flutter-deploy.yml` n'a pas été vérifié** :
  ses secrets (`VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`,
  `SUPABASE_URL`, `SUPABASE_ANON_KEY`) ne sont pas lisibles depuis cet
  environnement. Avec `git.deploymentEnabled.main=false`, le déploiement
  Vercel zéro-config ne peut plus écraser la production, mais si ces secrets
  manquent ou sont faux, le workflow échoue simplement sans y toucher —
  aucun risque, mais aucun déploiement continu non plus tant que ce n'est
  pas vérifié.
- **Trois clés de test obsolètes** : `test/features/connexion_test.dart`
  référence `t.connexion.seConnecter` et `t.connexion.erreurConnexion`, qui
  n'existent dans aucun des deux fichiers i18n — signe que l'écran de
  connexion a été renommé sans mettre les tests à jour. Sans effet sur le
  build web ; `flutter test` échouera sur ce fichier tant que ce n'est pas
  corrigé.
- **`Env.configuree` reste durci depuis le 14 septembre**, non retouché ici.
- Le projet Vercel orphelin `web` (ci-dessus).

## 12. Lot `AGT-01` — l'accès des agents IA — 18 septembre 2026

Demande de l'opérateur : *« créer un scope d'accès pour permettre aux agents IA
d'accéder à l'app en temps réel, après que moi-même j'ai fourni le token et
choisi le/les parcours ; pour l'instant tout en lecture seule. »* Quatre choix
tranchés à l'ouverture, consignés dans **ADR-025** : canal = l'application dans
un navigateur ; périmètre = le point de vue d'**une personne désignée** ;
identités = **masquées par défaut** ; émission = un écran d'administration.

### 12.1 Ce qui a été livré

| Couche | Fichier |
| :--- | :--- |
| Décision | `docs/architecture/decisions.md`, **ADR-025** |
| Base | `supabase/migrations/0014_acces_agent.sql` |
| Preuve | `supabase/tests/scenarios_agt01.sql` (13 contrôles), inscrit dans `ci.yml` **avant** `ADM-04` |
| Session | `supabase/functions/agent-session/index.ts` |
| Client | `lib/core/agent/` (3 fichiers), `lib/core/session/source_session_agent.dart` |
| Écrans | `ADM-07` `/admin/acces-agents`, `AGT-00` `/agent`, fiches au catalogue §6 |
| Composant | `BandeauObservation`, déclaré aux **trois** endroits (document, liste du test, galerie) |
| Tests | `test/agent/acces_agent_test.dart`, 18 contrôles |

### 12.2 L'idée qui tient tout, et pourquoi elle est bon marché

Le jeton est échangé contre une session signée dont **`sub` est la personne
observée** et dont le claim `role` vaut **`agent_ro`**, un rôle Postgres sans
aucun droit d'écriture. Conséquence : les 105 policies et les dix vues du dépôt,
qui se bornent déjà par `auth.uid()`, `app_household_id()` et `app_role()`,
s'appliquent **telles quelles**. Aucune règle de sécurité n'a été réécrite pour
l'occasion — c'est ce qui évite d'en maintenir une deuxième, qui divergerait.

### 12.3 Ce que la migration a mesuré, et qu'il ne faut pas réapprendre

- **Les 105 policies sont toutes `to authenticated`.** Elles ne s'appliquent
  donc pas à `agent_ro` : le défaut d'un agent est de **ne rien voir**. Une
  table ajoutée plus tard lui sera invisible jusqu'à décision explicite. **Un
  oubli fait échouer une lecture, jamais fuir une écriture.**
- **L'écriture est barrée par deux couches indépendantes**, prouvé par test de
  mutation : il faut accorder le privilège **et** écrire une policy nommant
  `agent_ro` pour qu'une écriture passe. Ouvrir une seule des deux ne suffit
  pas.
- ⚠ **Les dix vues portent `security_barrier`, jamais `security_invoker`** :
  elles appartiennent à `postgres` et **ignorent la RLS**. Leur seule borne est
  le `where ... = auth.uid()` écrit dans leur corps. Les dix ont été auditées,
  les dix sont bornées relativement à l'appelant — c'est ce qui rend le choix du
  `sub` sûr, et ce qui aurait rendu tout autre choix dangereux.
- ⚠ **Le vrai trou était invisible** : en PostgreSQL, `EXECUTE` est accordé à
  `PUBLIC` **par défaut**. `agent_ro` aurait hérité du droit d'appeler toute
  fonction dont personne n'a retiré ce défaut, `security definer` qui écrit
  comprise. `0014` retire ce défaut en préservant l'existant, puis n'ouvre à
  l'agent que l'intersection de deux critères **mécaniques** : fonction `stable`
  ou `immutable` (le moteur y interdit toute écriture) **et** déjà appelable par
  `authenticated`. Jamais une liste tenue à la main.
- ⚠ **Rien n'écrit pendant une lecture.** PostgREST sert les `GET` dans une
  transaction **READ ONLY** : un compteur d'usage incrémenté dans
  `db_pre_request` aurait cassé *toutes* les lectures de l'application, pour
  tout le monde. L'usage se compte à la remise du jeton, pas au coup par coup.

### 12.4 La limite du canal choisi, écrite plutôt que tue

Le masquage est **dur** là où il peut l'être : substitué dans les huit vues qui
portent un prénom, et `profiles` ne rend qu'**une ligne** à un agent masquant.
Mais avec le canal navigateur, **ce que l'écran de la personne observée affiche
légitimement voyage dans la charge réseau**. Le plafond est net — un agent ne
voit jamais plus que la personne qu'il observe — mais il voit tout ce qu'elle
voit. Aller au-delà exigerait le canal écarté (serveur MCP ou couche de vues
dédiée), où la donnée ne quitte pas la base.

Trois tables ne sont ouvertes **à aucun agent** : `kyc_documents`, `devices`,
`audit_logs`. La table des jetons non plus.

### 12.5 Mesures réelles de la session

```
dart analyze --fatal-infos     0 issue
flutter test                   645 passent, 11 echouent (voir 12.6)
test/agent/acces_agent_test    18/18
dart run tool/verifier_jetons  6 violations, TOUTES preexistantes
SQL, chaine CI complete        10/10 fichiers, scenarios_adm04 compris
```

La chaîne SQL a été rejouée **dans l'ordre exact de `ci.yml`, sur une base
neuve**, migrations `0001` à `0014` : `scenarios_adm04` passe, donc la chaîne de
hachage du journal reste intacte après les écritures de `AGT-01`.

### 12.6 Ce qui était déjà rouge sur `main`, et qui l'est resté

Vérifié en remisant les modifications et en rejouant les fichiers sur `main` nu :
**les mêmes échecs, aux mêmes noms.**

- 7 échecs préexistants : `dossiers_admin_test` (1), `dossier_test` (3),
  `inscription_test` (2), `salle_test` (1).
- 4 échecs de `connexion_test.dart` **rendus visibles par ce lot** : le fichier
  ne compilait pas (les clés obsolètes signalées en §11). Les clés ont été
  alignées sur celles de l'écran (`envoyerLien`, `erreurEnvoi`) ; les quatre
  tests qui restent rouges portent sur un **« mode démo »** que l'écran de
  connexion actuel n'implémente pas. C'est une divergence de produit, pas un
  défaut de ce lot : la trancher demande de décider si ce mode doit exister.
- 6 violations de jetons dans `lib/features/_dev/playground/playground_racine.dart`
  (tiret cadratin, couleur nue, icônes hors catalogue, `onTap` nu). Fichier de
  développement, non compilé en production. Correctifs mécaniques, non faits ici
  pour ne pas mêler deux sujets dans un même lot.

### 12.7 Les deux pièges de production, trouvés avant d'appliquer

Aucun des deux n'était visible dans le harnais Docker. Les deux auraient cassé
la production. Ils sont écrits ici parce qu'ils se reproduiront.

**1. ⚠ PostgREST appelle `db_pre_request` APRÈS avoir basculé de rôle.**
La fonction s'exécute donc sous `anon` / `authenticated` / `agent_ro`, **jamais
sous `authenticator`**. La première version de `0014` leur retirait justement ce
droit : appliquée telle quelle, **chaque requête de l'application aurait
échoué, pour tout le monde**. Aucun harnais Postgres nu ne peut voir ce défaut,
il n'y a pas de PostgREST dedans. L'invariant **I5** le vérifie désormais, et il
a été prouvé en le faisant échouer sur la base qui portait l'ancienne version
(`has_function_privilege('authenticated', …)` rendait `f`).

**2. ⚠ `btree_gist` est installé dans `public`** (par `0005`, sans schéma). Ses
**188** fonctions de support d'index y sont ouvertes à `PUBLIC` comme toutes les
fonctions d'extension. La section 8 les aurait refermées : la machinerie
d'index, dont la contrainte d'exclusion qui empêche deux séances de se
chevaucher, pour un bénéfice nul. Les fonctions d'extension sont maintenant
exclues par `pg_depend.deptype = 'e'`. Mesuré avant/après sur base neuve :
**188 → 188** intactes, et **0** fonction du projet encore ouverte à `PUBLIC`.

### 12.8 État de la production au 18 septembre 2026

| Geste | État |
| :--- | :--- |
| Migration `0014` | **APPLIQUÉE**, les cinq invariants `I1`–`I5` passés |
| `pgrst.db_pre_request` | **posé**, `= public.agent_pre_request` |
| Fonction Edge `agent-session` | **DÉPLOYÉE**, version 4, `ACTIVE`, `verify_jwt: true` |
| `ISSUPABASE_JWT_SECRET` | ✅ **POSÉ** le 18/09 — nom volontaire, voir §12.9 |
| Code web | poussé (`bc8638f`) et **déployé à la main** — voir §12.8 bis |

Routes vérifiées en ligne sur `rewayah-academy.vercel.app`, toutes en 200 et
servant bien l'application : `/`, `/connexion`, `/agent`,
`/agent?jeton=rag_test`, `/admin/acces-agents`. Bundle **4 577 Ko**, contenant
`acces-agents`, `agent-session` et « Observation, lecture seule ».

### 12.8 bis 🔴 Le déploiement continu ne marche pas, et il faut le savoir

**Un push sur `main` ne déploie RIEN.** Vérifié : douze minutes après
`bc8638f`, le bundle en ligne était inchangé, et Vercel ne montrait aucun
déploiement nouveau. Deux causes se cumulent :

1. `vercel.json` porte `"git": { "deploymentEnabled": { "main": false } }` :
   l'intégration Vercel↔GitHub est **volontairement coupée** ;
2. le seul chemin restant est `.github/workflows/flutter-deploy.yml`, qui a
   besoin de `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`,
   `SUPABASE_URL` et `SUPABASE_ANON_KEY` en secrets GitHub. Le §11 signalait
   déjà qu'ils **n'avaient jamais été vérifiés**. Ils ne fonctionnent pas.

Les deux derniers commits d'avant ce lot (`fdf5168`, `f879912`) n'ont eux non
plus **jamais été déployés** : la production tournait encore sur `99c7b6a`.
C'est la même leçon que le 11 septembre, sous une autre forme : **la prod peut
être très en retard sur `main` sans que rien ne le signale.**

**Le déploiement manuel qui marche, mesuré ce jour** (aucune de ces étapes n'est
facultative) :

```powershell
# 1. NE JAMAIS construire depuis dart_define.json : il porte encore
#    `cle-factice-playground-ne-jamais-utilisee` ET `PLAYGROUND=True`.
cd "D:\RA _APP\RA -OFFICIAL-APP"
flutter build web --release `
  --dart-define=SUPABASE_URL=https://gggmtelinlpseweouyav.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<la vraie cle anon> `
  --dart-define=ENVIRONNEMENT=production

# 2. CONTROLER LE BUNDLE, pas la commande. Quatre deploiements casses viennent
#    de l'avoir sauté.
#    build\web\main.dart.js doit contenir la vraie cle, et ne contenir
#    ni « cle-factice » ni « Playground - choisir une personne ».

# 3. Le depot n'a PAS de .vercel/project.json : sans ces deux variables,
#    `vercel deploy --prod` cree un projet NEUF en disant « ready », et le
#    site ne bouge pas.
$env:VERCEL_ORG_ID="team_VfPE1KP6vCKUyTeeG6AtAV8B"
$env:VERCEL_PROJECT_ID="prj_xDldWMLNH726BpwEVUlIAJUOSzPe"
cd build\web ; vercel deploy --prod --yes

# 4. VERIFIER L'URL PUBLIQUE, jamais le message du CLI.
#    https://rewayah-academy.vercel.app/main.dart.js doit contenir « acces-agents ».
```

⚠ `build/web` contient déjà son propre `vercel.json` avec la réécriture SPA.
**Sans elle, `/agent?jeton=...` rendrait 404** et tout le tunnel d'entrée serait
mort. C'est la première chose à vérifier si un déploiement futur part de
`build/web` reconstruit de zéro.

### 12.8 ter Un reste ouvert du §11 qui est en fait fermé

**`Env.configuree` EST durci** (commit `01edc81`) : `cleSupabaseValide()` valide
la structure du JWT — `alg: HS256`, `iss: supabase`, `role: anon` — accepte les
clés `sb_publishable_*` et rejette tout ce qui contient `factice`, `playground`,
`dummy`, `fake`, `placeholder`, `example`. Le défaut qui a laissé une clé morte
en production du 11 au 13 septembre **ne peut plus se reproduire en silence**.
Les mémoires et le §11 qui le listent encore comme ouvert sont en retard.

Mesures prises **sur la production réelle**, avant et après la migration :

```
AVANT  /rest/v1/sourate     200      APRES (x3)  200
AVANT  /auth/v1/health      200      APRES (x3)  200
policies ouvertes a agent_ro                      75
fonctions DU PROJET encore ouvertes a PUBLIC       0
fonctions d'extension intactes                   188
```

Les conseillers de sécurité Supabase ne signalent **rien de neuf** : les dix
vues `SECURITY DEFINER`, `btree_gist` dans `public` et les fonctions
`security definer` exposées sont des constats antérieurs à ce lot.

### 12.9 Le sceau — et pourquoi son nom n'est pas une faute de frappe

⚠ **Le secret s'appelle `ISSUPABASE_JWT_SECRET`, et ce nom est volontaire.**
La plateforme **refuse** d'enregistrer un secret de fonction Edge dont le nom
commence par `SUPABASE_` : ce préfixe lui est réservé pour les variables qu'elle
injecte elle-même (`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`…). Quiconque
« corrigera » ce nom vers `SUPABASE_JWT_SECRET` rendra la variable impossible à
enregistrer, et la fonction retombera **silencieusement** sur « non configuré ».

**Où le prendre** : tableau de bord → Project Settings → **JWT Keys** →
*Legacy JWT Secret*. Surtout **pas** l'onglet *API Keys*, qui ne contient que les
clés d'entrée. ⚠ Ne jamais révoquer ce secret hérité depuis cette page : la clé
`anon` de l'application est signée avec lui et mourrait du même coup.

**Où le déposer** : tableau de bord → Edge Functions → **Secrets**. Pas besoin de
CLI, et la valeur ne passe alors ni par un historique de commandes ni par un
fichier.

**Aucun repli n'est prévu** si le secret manque : un repli sur une valeur
publique ne dégrade pas un sceau, il le publie. Tant qu'il est absent, un jeton
peut être émis mais **aucune session ne peut s'ouvrir**.

**Comment le vérifier à tout moment, sans jamais révéler la valeur** — la
fonction le dit elle-même, sur le modèle de `videoConfiguree()` (ADR-001) :

```
GET  /functions/v1/agent-session   -> {"configure":true,
                                       "detail":"Le sceau est en place ..."}
POST /functions/v1/agent-session   -> {"error":"jeton refuse"}   (faux jeton)
     {"jeton":"rag_ceci_nexiste_pas"}
```

Mesuré le 18 septembre 2026, après dépôt : **`configure: true`**, et le `POST`
d'un faux jeton rend bien `401` — donc l'aller-retour vers
`remettre_session_agent()` s'exécute. Ce garde-fou existe parce que le défaut
inverse a déjà coûté cher : une clé factice est restée en production du 11 au
13 septembre **sans un bruit**, faute d'un endroit qui dise si la configuration
tient.

**⚠ Ce que dit la plateforme sur l'avenir de ce sceau.** Le projet signe
désormais ses jetons en **ES256** (clé asymétrique ; le JWKS de
`/auth/v1/.well-known/jwks.json` en publie une, `kid`
`191eeb40-a620-476a-abe6-c923007a99a5`). L'ancien secret HS256 reste **accepté en
vérification** — mesuré : un `GET /rest/v1/profiles` portant la clé `anon`
héritée rend `42501 permission denied`, une erreur **Postgres** et non une erreur
de signature, donc le jeton a bien été décodé. Le jour où Supabase retirera la
vérification HS256, **deux choses tomberont ensemble** : la clé `anon` de
l'application et les sessions d'agent. Il n'existe pas de remplacement
immédiat — la partie privée de la clé ES256 n'est pas exposée, donc rien ne peut
signer à sa place côté projet.

**⚠ Ce qu'il ne faut PAS faire**, malgré ce qu'on lit en ligne : déployer cette
fonction avec `--no-verify-jwt`. Ce conseil vise les fonctions qui **vérifient**
un jeton entrant ; celle-ci en **fabrique** un. Elle est déployée avec
`verify_jwt: true`, la passerelle exige donc une clé pour l'atteindre. La passer
à `--no-verify-jwt` la rendrait **appelable par n'importe qui sans aucune clé**.
Pour la même raison, `auth.getClaims()` ne remplace pas ce code : cette méthode
valide une signature, elle n'en produit pas.

**Comment défaire tout le lot, si le doute s'installe** : `revoke agent_ro from
authenticator` ferme la porte sans rien toucher d'autre. Aucune session d'agent
ne peut plus s'ouvrir, et l'application humaine ne s'en aperçoit pas.

### 12.10 Ce que la production contient réellement, au 18 septembre

Relevé en passant, et il éclaire la raison d'être du lot : **six profils**.

| Parcours | Nombre | État |
| :--- | :-: | :--- |
| Enseignant | 3 | **tous `pending_kyc`** |
| Administration | 1 | `active` (l'opérateur) |
| Tuteur | 1 | `active` |
| Élève | 1 | `active` |

Aucune séance, aucune affectation n'a été comptée ici. C'est précisément ce que
les jetons d'observation doivent permettre de constater écran par écran, plutôt
que de le déduire d'un tableau.

---

## 13. 🔴 AGT-01 EST BLOQUÉ — LA TÂCHE DE LA PROCHAINE SESSION

> **À lire en premier.** HEAD = `583494b`. L'opérateur a dit, mot pour mot :
> **« ça marche pas »** et **« je ne peux rien créer jusqu'à présent »**.
> Il n'a pas réussi à émettre un seul jeton. `public.jetons_agent` contenait
> **0 ligne**. **Le livrable de la prochaine session est qu'il y arrive, lui.**

### 13.1 Ce qui EST fait et vérifié — ne pas le refaire

| Élément | État | Preuve |
| :--- | :--- | :--- |
| Migration `0014` | appliquée | invariants `I1`–`I5` passés |
| Rôle `agent_ro` | en place | 75 policies ouvertes |
| Fonction `agent-session` | **v4, `ACTIVE`, `verify_jwt: true`** | déployée |
| Sceau `ISSUPABASE_JWT_SECRET` | **posé** | `GET` → `{"configure":true}` |
| Refus d'un faux jeton | correct | `POST` → `401 jeton refuse` |
| Écran `ADM-07` en ligne | oui | bundle public contient `Ouvrir un acc…` |
| Entrée de navigation | **ajoutée** (`e1b3008`) | Centre de commande → *Outils* |

⚠ Le sceau ne s'appelle **pas** `SUPABASE_JWT_SECRET` mais
**`ISSUPABASE_JWT_SECRET`** : la plateforme refuse ce préfixe. Voir §12.9.

### 13.2 Le symptôme n'est PAS qualifié — le trancher AVANT de coder

« Ça marche pas » recouvre trois pannes distinctes. **Ne rien modifier avant
d'avoir mesuré laquelle.**

1. **L'opérateur n'a jamais vu la nouvelle version.** L'app est une PWA, le
   service worker ressert l'ancien bundle. L'entrée de navigation a été déployée
   en toute fin de session et rien ne prouve qu'il ait rechargé de force
   (`Ctrl+Shift+R`). **Hypothèse la plus probable, à éliminer en premier.**
2. **L'écran s'ouvre mais ne lit pas** : `jetons_agent_actifs()` refusée, ou la
   liste des personnes observables reste vide.
3. **L'écran s'ouvre mais l'émission échoue** : `creer_jeton_agent()` lève
   `42501 emission reservee a l administration`. Elle exige
   `app_role() = 'admin'` **ET** `app_account_valid()` — vérifier **les deux**,
   la seconde est facile à oublier.

**La requête qui tranche**, puisque les trois fonctions du lot journalisent :

```sql
select action, created_at, meta
from public.audit_logs
where action like 'agent_%'
order by created_at desc limit 20;
-- agent_token_issued present -> l'emission a REUSSI, le blocage est en aval
-- rien                       -> l'emission n'a jamais ete atteinte (cas 1 ou 2)
```

Puis `select count(*) from public.jetons_agent;`.

**Demander à l'opérateur ce qu'il voit exactement** — écran blanc, message
d'erreur, bouton sans effet, ou section *Outils* absente — coûte une phrase et
élimine deux hypothèses sur trois.

### 13.3 Émettre le premier jeton

La voie normale et la seule qui prouve quelque chose : **l'opérateur ouvre
`/admin/acces-agents` et émet.** C'est cela qu'il faut faire marcher ; un jeton
fabriqué autrement démarre l'inventaire mais laisse `ADM-07` cassé, donc ne
clôt pas le lot.

La fonction officielle, à préférer à toute écriture directe — elle applique le
contrôle d'administration **et** écrit la ligne de journal :

```sql
select * from public.creer_jeton_agent(
  p_libelle          => 'inventaire ecran par ecran',
  p_profil_observe   => '<un id du §13.4>',
  p_duree_heures     => 8,      -- borne : 1 a 24
  p_identite_masquee => true
);
-- rend : jeton (le secret, affiche UNE fois), jeton_id, expire_le
```

⚠ Appelée hors d'une session d'administration, elle refuse — c'est voulu.
**Si un contournement par la base devient nécessaire pour débloquer
l'inventaire, en parler à l'opérateur d'abord** : il a lui-même désigné l'accès
`postgres` du MCP comme « la pire vulnérabilité », tolérée provisoirement. Ne
pas l'employer en silence, et ne pas perdre la ligne de journal.

**Vérifier ensuite la chaîne complète :**

```
POST https://gggmtelinlpseweouyav.supabase.co/functions/v1/agent-session
     apikey: <cle anon>   Authorization: Bearer <cle anon>
     corps : {"jeton":"<le secret>"}
-> access_token, parcours, identite_masquee, jeton_expire_le
```

Puis ouvrir `https://rewayah-academy.vercel.app/agent?jeton=<le secret>`.

⚠ Un jeton vit de 1 à 24 h (8 par défaut), la session signée **15 minutes**,
renouvelée en repassant par la fonction. Révocation immédiate :
`select public.revoquer_jeton_agent('<jeton_id>');`

### 13.4 Les six profils de production, pour choisir qui observer

| Parcours | `profiles.id` | État |
| :--- | :--- | :--- |
| **Administration** | `06a05adc-e580-4909-a688-17b5071a2def` | `active` |
| **Tuteur** | `a024035f-7eea-4d0a-b329-dd24a51c26e2` | `active` |
| **Élève** | `c7bac8a8-49ce-4115-b1e5-4a66c7b19b6e` | `active` |
| Enseignant | `ffad1edb-bc6f-4087-b95e-f247b980aefc` | ⚠ `pending_kyc` |
| Enseignant | `ae6f4cbe-409d-4fe5-b507-8c94649e9b60` | ⚠ `pending_kyc` |
| Enseignant | `8fda19ad-db75-45cb-bfe1-0ba31922b323` | ⚠ `pending_kyc` |

⚠ **Les trois enseignants seront refusés par l'émission** : elle n'accepte que
`account_status in ('active','provisional_active')`. Inventorier le parcours
enseignant suppose donc de valider un dossier d'abord — ou de consigner ce
blocage, qui est en soi un résultat d'inventaire.

Ordre conseillé : **administration**, puis tuteur, puis élève.

### 13.5 Deux affirmations de la session à corriger

1. 🔴 **« L'émission d'un jeton n'est pas journalisée » est FAUX.** Les trois
   fonctions appellent `log_sensitive_access` : `creer_jeton_agent` →
   `agent_token_issued`, `revoquer_jeton_agent` → `agent_token_revoked`,
   `remettre_session_agent` → `agent_session_opened`. L'erreur venait d'un test
   grossier (`ilike '%audit%'`) sur un corps qui nomme `log_sensitive_access`,
   pas « audit ». **Ne pas conclure d'un `ilike` sur du source.**
2. **Le balayage des routes ne trouve QU'UN orphelin, pas cinq.** Sur 38 routes,
   le test brut en signalait 5 ; 4 étaient des faux positifs, atteints par une
   fonction intermédiaire (`appairerPour`, `compteProfilEnfantPour`) ou par
   `Routes.racinePour(role)` — qui vit dans `routes.dart`, le fichier exclu du
   balayage. Seul `adminAccesAgents` l'était vraiment ; il est branché depuis
   `e1b3008`.

### 13.6 Ce qui reste ouvert, dans l'ordre

1. **Que l'opérateur puisse émettre depuis l'écran.** Tant que non, `ADM-07`
   n'est pas livré, quoi qu'en disent les tests.
2. **Restreindre ou débrancher le MCP Supabase** (rôle `postgres` sur la
   production) — la vulnérabilité que l'opérateur a nommée et acceptée de
   reporter, pas de classer.
3. Le déploiement continu, toujours cassé — §12.8 bis.
4. Les 11 tests rouges préexistants (7 véritables ; 4 sur un « mode démo » que
   l'écran de connexion n'implémente pas — question produit, pas défaut).

### 13.7 Ce qu'il ne faut pas refaire

- ⚠ **Ne pas conclure « livré » de « déployé ».** `ADM-07` a passé une semaine
  en production sans qu'aucune navigation n'y mène : tests verts, bundle
  correct, URL en 200, écran inexistant pour l'utilisateur. Compter les
  références à la route **hors** `routes.dart` et `app_router.dart`.
- ⚠ **Ne pas déployer `agent-session` avec `--no-verify-jwt`** : elle *fabrique*
  un jeton, elle n'en vérifie pas. Voir §12.9.
- ⚠ **Ne pas construire depuis `dart_define.json`** : clé factice + `PLAYGROUND`.
- ⚠ **Ne pas lire ce fichier avec `Get-Content`** : PowerShell 5.1 en détruit
  l'UTF-8, et son comptage de lignes diverge de celui des outils d'édition.

## 14. 🔴 Le défaut qui rendait cinq écrans vides — 18 septembre 2026

Session déclenchée par un constat de l'opérateur, et il avait raison sur toute
la ligne : **« presque rien n'apparaît sur la vraie app malgré que les agents
disent qu'ils ont tout développé »**. Le relevé complet specs / réalité est dans
`docs/ECART-SPEC-REALITE.md`.

### 14.1 La cause racine : `PageShell` dé-bornait la hauteur de son contenu

`PageShell` enveloppait le contenu de **chaque** écran dans son propre `Column`,
pour lui ajouter une respiration de bas de page. Or un `Column` donne à ses
enfants non flexibles une hauteur **non bornée**. Tout écran en
`defilante: false` avec un `Expanded` échouait donc à se mesurer.

**Ce qui rendait le défaut invisible** : en build release, les assertions de
layout sont retirées. Le corps disparaissait donc **sans une ligne d'erreur en
console, sans un seul appel réseau en échec, et sans qu'aucun test ne le voie** —
aucun test ne montait un écran non défilant à travers `PageShell`. L'écran
rendait son titre, puis du vide.

**Cinq écrans de production, quatre rôles** : `ADM-07`, `ADM-04`, `CTR-01`, le
suivi élève et `TUT-06`. La dette était déjà écrite dans la fiche `TUT-00b` du
catalogue (« `PageShell` en mode `defilante: false` ne donne pas cette garantie
à son `child` ») sans avoir jamais été payée.

Verrouillé par `test/widgets/page_shell_test.dart`, **prouvé rouge avant le
correctif et vert après** — un test qui n'a jamais été rouge ne prouve rien.

### 14.2 Le chiffre exact et le mensonge humain

`dossiers_en_attente()` lisait `kyc_documents where status = 'pending'` : elle
comptait des **documents**. Trois enseignants inscrits les 11 et 15 septembre,
contrats signés, sans pièce déposée, n'existaient donc pour aucun écran. Le
centre de commande affichait « 0 dossiers à valider » pendant qu'un foyer
attendait un enseignant et que trois enseignants attendaient leur validation.

Migration `0015` : `dossiers_en_attente()` rend une ligne par **personne**,
`comptes_admin()` est créée (`ADM-08`), `indicateurs_admin()` compte des
personnes, et `journal_audit_filtres()` respecte enfin le masquage d'identité.

### 14.3 Les autres défauts trouvés et corrigés

- **Aucune déconnexion dans toute l'application authentifiée.** Le mot
  n'existait que dans le portail d'attente — donc *avant* validation — et dans
  la salle. Un admin ou un tuteur validé n'avait pour seule sortie que vider le
  cache du navigateur. Corrigé par un **pied de coquille** dans `NavShell`
  (`secondairesPour`), qui porte aussi `ADM-06`, `ADM-07` et `ADM-08` sans
  toucher à la règle des quatre destinations. ⚠ **Limite assumée** : ce pied
  n'existe qu'à partir de 600 px ; sous 600, ces entrées passent par les tuiles
  « Outils » du tableau de bord.
- **`EmptyState` ne rend son bouton que dans le registre `actionnable`.** Deux
  états d'erreur le déclaraient en registre `subi` **avec** un « Réessayer » :
  le bouton n'a donc jamais existé à l'écran, et l'écran devenait un cul-de-sac.
- **Le journal affichait des clés brutes de base de données.** Les lots
  `AGT-01`, `CTR-01` et `N2` ont ajouté cinq événements sans ajouter leur
  libellé : `agent_session_opened` s'affichait à côté de « Dossier d'identité
  consulté ». La liste de référence est la base elle-même — les littéraux
  passés à `log_sensitive_access()` — et il y en a **19**, pas 14.
- **`ADM-01` étirait deux colonnes à toutes les largeurs.** Le diviseur était
  `2` en dur ; `05-regles-responsive.md` §3 exige quatre chiffres sur desktop,
  et §2 interdit explicitement d'agrandir le mobile.
- **`read_kyc_documents()` journalise chaque appel**, même sans pièce à lire :
  52 entrées « dossier consulté » pour zéro lecture réelle, qui noyaient le
  journal. `dossiers_en_attente()` ne l'appelle plus que s'il y a à lire.
- **`GRANT EXECUTE` manquant pour `agent_ro`** sur dix fonctions de lecture
  (oubli de la migration `0014`) : toute session d'observation recevait `403`.

### 14.4 Ce que l'audit git a évité de recoder

Dix branches jamais fusionnées, dont `codex/vague5-integration` (7 commits :
design adaptatif, coquille de navigation, profil enseignant, correction de
présence). **Rien n'était à en tirer** : `main` porte déjà ce travail par le
commit de synchronisation `99c7b6a` — seuils et coquille identiques au bit
près. La branche n'avait jamais été fusionnée parce que sa propre session avait
écrit `dart analyze : BLOCKED`, `flutter test : BLOCKED`, scénarios SQL
`BLOCKED`. **Vérifier git avant de recoder a économisé la session.**

### 14.5 Ce qui reste ouvert sur l'admin

- ⚠ `ADM-02` ne rend pas encore la file à gauche / dossier à droite du
  desktop, et son modèle Dart doit suivre la nouvelle forme de
  `dossiers_en_attente()` (une ligne par personne, `etat_piece`).
- ⚠ `ADM-03` (séquestre) et `CTR-03` : contradiction de périmètre jamais
  tranchée entre `couverture-specs.md` (MVP-0) et le handoff §10.4 (V1).
- ⚠ La contradiction « cinq indicateurs » / « quatre chiffres » / six dans le
  code n'est toujours pas arbitrée.
- ⚠ Sous 600 px, l'admin n'a pas de déconnexion dans la coquille (§14.3).
- ⚠ **« Mon compte » affiche l'UUID d'authentification** sous le rôle, libellé
  « Identifiant ». Ce n'est pas l'identité d'une personne : c'est
  `immutable_id` (`GUARDIAN-AS-000001`) qu'il faut, et la page enfant le fait
  déjà. La session ne le porte pas ; le moins cher est d'ajouter
  `immutable_id` au `select` que `source_session.dart` et
  `source_session_agent.dart` font **déjà** sur `profiles` — un champ, zéro
  aller-retour de plus. Repéré à l'écran le 18/09, non corrigé : ces deux
  fichiers décident de la session entière, et ils ne se touchent pas la veille
  d'un déploiement.

---

## 15. 🔴 Le masquage ne tenait que dans deux fonctions sur sept — 18 septembre

### 15.1 Le défaut

Sous la bannière « Observation, lecture seule . **Prénoms masqués** », l'écran
`ADM-08` rendait bien `TEACHER-AS-000001` ; mais `ADM-02` affichait « Abdallah
Sow » en titre de fiche, `ADM-01` « Dossier d'identité de Abdallah » dans sa
file, `ADM-05` la carte « Salam », et `ADM-07` la pilule « Abdoulaye Sow ».

**La cause n'est pas un oubli, c'est une forme.** Le masquage était un motif
recopié à la main —
`case when public.agent_identite_masquee() then null else p.first_name end` —
donc présent uniquement dans les deux fonctions écrites **après** la bascule en
mode observation (`comptes_admin`, `journal_audit_filtres`). Les cinq autres
lectures lui sont antérieures et rendaient `first_name` tel quel.

**Pourquoi aucun test ne pouvait le voir**, et c'est la leçon à garder : la
fonction rend la bonne colonne, la RLS borne les bonnes lignes, et c'est la
**colonne** qui trahit. C'est la même limite déjà payée ailleurs dans ce
dépôt : *une RLS borne les LIGNES, pas les COLONNES.*

### 15.2 Le cas d'`ADM-07`, qui n'était pas du tout le même défaut

`ADM-07` ne passait par **aucune** fonction. Il lisait la table en direct :

```dart
_client.from('profiles').select('id, immutable_id, first_name, last_name, role')
```

Il n'existait donc aucun endroit où appliquer le masquage, et la borne d'admin
était déléguée à une policy RLS écrite pour un autre usage. D'où la fonction
**nouvelle** `personnes_observables()` : le masquage a un endroit, la borne
d'admin est explicite, et le tri reste fait en base — deux rendus successifs ne
doivent pas proposer deux ordres.

⚠ **Le tri aussi.** `eleves_sans_enseignant` et `enseignants_pour` triaient par
`first_name` : trier une liste par un prénom qu'on ne montre pas laisse lire
l'ordre alphabétique des prénoms, ce qui est déjà plus que rien. Le tri passe
sur `immutable_id` quand l'identité est masquée.

⚠ **Côté Dart, un masquage sans repli fabrique un écran vide.** Chaque modèle
gagne un `libelle` qui retombe sur l'identifiant immuable, sinon la fiche rend
un titre vide au-dessus de l'identifiant, et `ADM-07` affichait « (IDENT) » :
une parenthèse ouverte sur rien. Deux libellés là où le nom de famille a un
sens : `libelle` (complet) sur la fiche `ADM-02`, où l'un des trois constats
porte justement sur le nom, et `libelleCourt` (prénom seul) dans les phrases
(ADR-008).

### 15.3 Le piège de mesure qui a failli me faire inventer trois défauts

Dans un navigateur piloté, **le canevas Flutter ne repeint que sur une
entrée**. Une capture prise sans bouger la souris rend une image figée à
mi-animation. Trois faux défauts en une heure :

- l'indicateur du tiroir figé **en vol** entre deux destinations, donc la
  pastille sur « Journal » et l'encre d'accent sur « Tableau de bord » ;
- un menu de filtre qui a l'air de se rouvrir après chaque choix ;
- `ADM-05` et `ADM-01` qui ont l'air **vides** alors qu'ils chargent.

**Il faut provoquer un mouvement de souris avant chaque capture.** Une capture
n'est une preuve que si le rendu est **établi**. Et un clic posé d'après une
capture périmée tombe à côté : c'est ce qui m'a fait croire que les entrées de
menu ne répondaient pas.

### 15.4 La police d'icônes se sonde, elle ne se devine pas

Le chevron du `MenuFiltre` pointait à droite alors que le menu s'ouvre en
dessous. Il fallait un caret vers le bas, dont le point de code n'est écrit
nulle part : la police Phosphor embarquée n'a **pas** de noms de glyphes
(table `post` version 3.0), et la police **livrée dans `build/web` est élaguée**
aux seuls points de code cités dans `app_icons.dart`. La méthode qui marche :
copier la police **source** dans le dossier servi, injecter une grille de
points de code dans la page par `javascript_tool`, et lire à l'écran. Relevé
ainsi : `0xe136` = caret bas, `0xe134` = sa variante barrée, `0xe13a` = celui
déjà utilisé, vers la droite.

⚠ `AppIcons.menuDeroulant` **ne porte pas** `matchTextDirection` : le bas est
le même dans les deux sens de lecture, alors qu'un chevron « qui mène ailleurs »
se miroite.
