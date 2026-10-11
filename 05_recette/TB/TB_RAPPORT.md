# TB-12 : rapport de recette du chantier « Supports et tableau »

## a. En-tête

- Date : 10/10/2026.
- Branche : `claude/wizardly-babbage-lmhkog`.
- Base : tests et captures sur la tête de `claude/wizardly-babbage-lmhkog` après `2d38362e`, soit `a5393f82` (code, tests et captures ; le commit du rapport ne change que ces deux documents).
  Les lots TB-12 y sont réunis : `8da71533` (écriture), `3d0b90f9` (synchro), `e698b2af` (accès),
  `44ca9f74` (coquille), `252ba88c` (captures), `a5393f82` (correction du test UX-22).
- Qui : session cloud `01KZyXbi`. Elle n'a écrit aucun code TB avant la vérification. Les quatre lots de
  tests et le lot de captures ont chacun été relus par un relecteur distinct, avec une contre-épreuve
  (mutation temporaire du code ou du test, puis retour à l'état propre).
- Sources : plan V2 §15, §22, §23 ; `02_DECOUPAGE.md` (TB-12) ; cartographie des tests avant TB-12
  (42 scénarios, lue sur `35fd3490`) ; vérification et corrections de TB-5 à TB-11b, AR-SALLE-1, AR-TC-1 ;
  `docs/current/captures/TB-12/LISEZMOI.md`.
- Statuts utilisés, pris dans la liste du §22 (spécifié, présent dans le code, testé localement, testé sur
  staging, déployé, bloqué, non vérifié) :
  - **testé localement** : un test vert, sur cette branche, prouve le scénario avec la démonstration ;
  - **partiel (testé localement en partie)** : une partie est testée localement, le reste demande le
    serveur (BR-1) ou un appareil ;
  - **non vérifié : demande BR-1** : rien ne peut le prouver sans réseau réel, serveur ou appareil.
  - Aucun scénario n'est « testé sur staging » ni « déployé ». Rien n'a été poussé ni déployé.
- Rappel : une capture ne prouve pas le réseau. Un test local ne prouve pas la production. La
  démonstration `/demo/salle` joue le rôle du serveur : tout ce qui passe entre deux appareils y est
  simulé.

## b. Matrice de preuve

Abréviations : `TB/` = `test/features/tb_recette/` ; `TC/` = `test/teaching_core/`. « Coquille oui » :
le test monte le vrai routeur (`monterRouteur`, `/demo/salle`), tape le lien `lien-<rôle>-tb-<situation>`,
puis passe par les vrais boutons. « Coquille non » : écran monté seul, deux salles côte à côte, ou flux
monté par le test.

### Scénarios du §15

| ID | Scénario en mots simples | Statut | Tests | Coquille | Ce qui manque |
| :--- | :--- | :--- | :--- | :--- | :--- |
| R-01 | Un cercle reste autour du même mot, de l'iPad au téléphone et au Web, à plusieurs zooms | non vérifié : demande BR-1 | `TB/calque_page_test.dart:301` (6 écrans × zoom, même point normalisé), `:498`, `:549`, `:747` | non | Trois appareils réels reliés par le réseau |
| R-02 | Trois affichages : un clic par changement, aucune note perdue | testé localement | `TB/recette_coquille_test.dart` « R-02 : un clic par affichage… » (390, 1440) ; `TB/surface_test.dart:271` | oui | Rien en local |
| R-03 | Masquer le support, écrire, réafficher : les traits se superposent à la même page | testé localement | `TB/recette_ecriture_test.dart` « R-03 : en Support (calque cache), Ecrire puis tracer… » | oui | Pas de preuve en pixels : la peinture commune est prouvée par la liste des traits de la couche et le calque visible |
| R-04 | Ranger puis représenter : page et notes reviennent ; tableau libre à part | testé localement | `TB/rangement_test.dart:391` (coquille), `:125`, `:200`, `:238` ; `TB/calque_page_test.dart:1026` | oui | Reprise entre séances : contrat durable (BR-1) |
| R-05 | Un support qui ne s'ouvre pas ne remplace jamais l'ancien ; erreur ciblée | testé localement | `TB/recette_coquille_test.dart` « R-05 : … Commandes > Bibliotheque > echec, puis Page suivante » (390, 1440) | oui | Rien en local |
| R-06 | Changer de page pendant un trait : rien sur la mauvaise page | partiel (testé localement en partie) | `TB/recette_ecriture_test.dart` « R-06 : trait en cours, Page suivante touchee d un second doigt… » | oui | « Aucun fragment envoyé » par le réseau : BR-1 |
| R-07 | Revenir à une page effacée : aucun paquet retardé ne rend les anciennes notes | partiel (testé localement en partie) | `TB/recette_synchro_test.dart` « R-07 : la moitie des paquets du geste perdue… » | non | Aucun récepteur d'encre chez l'élève (preuve sur ce qu'il reçoit, pas sur son écran) ; ordre et perte du canal fiable LiveKit |
| R-08 | Deux élèves autorisés : traits distincts, chacun n'annule que les siens | partiel (testé localement en partie) | `TB/recette_ecriture_test.dart` « R-08 : deux eleves autorises sur un meme depot… » | non | Deux salles côte à côte sur un dépôt commun, sans réseau ; l'auteur du trait n'est porté que par l'appareil (TB-BR-34) |
| R-09 | Retrait du droit d'écrire : aucun trait non autorisé appliqué | partiel (testé localement en partie) | `TB/recette_ecriture_test.dart` « UX-20 / R-09 : … aucun point apres le retrait… » | non | Diffusion du retrait jouée par le test ; refus serveur des commits postérieurs (TB-BR-51) |
| R-10 | Pertes et désordre des paquets : résultat final identique | partiel (testé localement en partie) | `TB/recette_synchro_test.dart` « R-10 : apres le retrait du trait, son paquet fiable retarde… » et « R-10 (limite ecrite)… » | non | Un aperçu éphémère retardé passe le protocole ; « Effacer les notes » de la démonstration n'émet rien ; garanties LiveKit |
| R-11 | Arrivée tardive ou reconnexion : état actuel reçu seul, sans bouton Suivre | partiel (testé localement en partie) | `TB/recette_synchro_test.dart` « R-11 : … service : la page ET l'affichage publies… » et « … Classe Live eleve : arrivee tardive… » | non | `/demo/salle` n'est pas branchée sur ce flux ; arrivée sur un autre appareil (TB-BR-46) |
| R-12 | Coupure de l'enseignant : état honnête, aucun nouveau maître | partiel (testé localement en partie) | `TB/recette_synchro_test.dart` « R-12 : … coquille /demo/salle : eleve et guidee en ERR-01… » et « … service : l'eleve n'obtient aucun droit de pilotage… » ; `TB/synchronisation_test.dart:1076` | oui (écran) | La revue l'a ramené à partiel : « l'état partagé ne change pas d'émetteur » n'est pas prouvé. `ServiceEtatPartage.publier` écrit avant d'émettre, et la mémoire accepte tout écrivain (TB-BR-44) |
| R-13 | Fermeture totale puis reprise : notes retrouvées seulement si la conservation durable existe | non vérifié : demande BR-1 | Texte honnête prouvé : `TB/synchronisation_test.dart:439`, `:970`, `:986`, `:1076` | oui (texte) | Contrat durable absent : rien n'est conservé hors séance |
| R-14 | Téléphone modeste : ni blocage audio ni mémoire en dessin prolongé | non vérifié : demande BR-1 | Bornes locales seulement : `TB/ecriture_test.dart:902`, `TB/synchronisation_test.dart:916`, `TC/d/compaction_trait_test.dart:48` | non | Mesures sur appareils (TB-BR-27) |
| R-15 | Clavier et lecteur d'écran : choix, menus et fermeture accessibles | testé localement | `TB/recette_acces_test.dart` « UX-09 / R-15 : lecteur d'ecran et texte x2, au clavier… » | oui | Rien en local ; doublon de lecture de la carte du catalogue (défaut mineur, partie d) |
| R-16 | Mouvement réduit : rangement complet sans vol animé | testé localement | `TB/recette_acces_test.dart` groupe « UX-22 / R-16 : mouvement reduit… » (5 tests, dont « eleve, visite : point d'enregistrement fixe… », assertion corrigée en `a5393f82`, contre-épreuve : 1 échec) | oui | Rien en local |
| R-17 | Observateur : aucune commande de dessin, page ou rangement | testé localement | `TB/observateurs_test.dart:159` (coquille), `:217`, `:343` ; `TB/recette_acces_test.dart` groupe UX-21 | oui | Rien en local |
| R-18 | Support arabe : sens RTL juste, signes lisibles, version inchangée | partiel (testé localement en partie) | `TB/recette_coquille_test.dart` groupe « R-18 : support arabe, interface arabe » (390, 1440) ; `TB/ar_salle_rtl_test.dart` ; `TC/q/q06_annotation_source_immuable_test.dart:45` | oui | Élève distant qui reçoit le support arabe annoté (TB-BR-57) |

### Scénarios du §23

| ID | Scénario en mots simples | Statut | Tests | Coquille | Ce qui manque |
| :--- | :--- | :--- | :--- | :--- | :--- |
| UX-01 | Téléphone, barre masquée : toucher le contenu révèle Micro, Caméra, Quitter sans rien déclencher | testé localement | `TB/visio_revelee_test.dart:102` | oui | Rien en local |
| UX-02 | Web en focus : bouger la souris révèle la barre sans ouvrir les Commandes | testé localement | `TB/recette_coquille_test.dart` groupe « UX-02 : la souris revele la barre sans monter les Commandes » (élève, guidée, enseignant) | oui | Contre-épreuve indirecte (par l'assertion de masquage) |
| UX-03 | Trait commencé avant la barre : il continue, Quitter ne s'active pas | testé localement | `TB/recette_ecriture_test.dart` « UX-03 : Ecrire arme, un trait commence sur la page glisse… » | oui | Rien en local |
| UX-04 | Activer Micro : coupé une fois, aucune note créée | testé localement | `TB/visio_revelee_test.dart:185` | oui | Micro réel (moteur) |
| UX-05 | Barre survolée ou focalisée : elle reste visible | testé localement | `TB/visio_revelee_test.dart:202` | oui | Rien en local |
| UX-06 | 4 secondes sans geste : la barre se masque, rien d'autre ne bouge | testé localement | `TB/visio_revelee_test.dart:254`, `:283` | oui | Rien en local |
| UX-07 | Panneau ouvert : Quitter accessible, sortie personnelle qui aboutit | testé localement | `TB/recette_acces_test.dart` groupe « UX-07 : panneau pedagogique ouvert, la sortie personnelle aboutit » (4 tests) | oui | Que la séance continue pour les autres (TB-BR-61) |
| UX-08 | Tab depuis la surface en focus : barre révélée, focus visible | testé localement | `TB/visio_revelee_test.dart:435`, `:555` | oui | Rien en local |
| UX-09 | Lecteur d'écran et texte à 200 % : Commandes nommées et atteignables | testé localement | `TB/recette_acces_test.dart` « UX-09 / R-15 : … » | oui | Doublon de lecture de la carte du catalogue (mineur) |
| UX-10 | Partage compact : avatar fixe, indicateurs réels, ni nom ni réseau permanent | testé localement | `TB/capsule_contexte_test.dart:92`, `:130` | oui | Rien en local |
| UX-11 | Toucher l'avatar ou l'œil : contexte lisible, aucun contrôle activé | testé localement | `TB/capsule_contexte_test.dart:157`, `:248`, `:288` | oui | Rien en local |
| UX-12 | Enregistrement inactif ou inconnu : aucun voyant rouge | partiel (testé localement en partie) | `TB/capsule_contexte_test.dart:421`, `:441`, `:478` (capsule et contexte) | oui | La capsule respecte UX-12. La mention d'en-tête (`PermanentNotice`, sans paramètre) montre toujours le point rouge : divergence portée à TB-R (partie d, classe 2) |
| UX-13 | Bureau développé : Participants à gauche, contenu au centre, Commandes à droite | testé localement | `TB/recette_coquille_test.dart` « UX-13 : bureau 1440, Participants a gauche… » | oui | Rien en local |
| UX-14 | Entrer en focus : les panneaux se replient, le contenu grandit | testé localement | `TB/composition_test.dart` groupe « UX-14 : la page grandit en focus » (1440, 1024, 768, 1440 ×2 ; correction `00548b28`), `:333` ; `TB/commandes_test.dart:424` | non | Hors focus, fermer les Commandes rapetisse encore la page à 1440 (partie d) |
| UX-15 | Commandes ouvertes en focus puis Réduire : la gauche ne revient pas | testé localement | `TB/recette_coquille_test.dart` « UX-15 : Commandes en focus puis Reduire… » | oui | Rien en local |
| UX-16 | Sortir du focus après redimensionnement : composition rétablie si possible | testé localement | `TB/composition_test.dart:194`, `:365`, `:376`, `:387` | non | Rien en local |
| UX-17 | Aperçu de la Bibliothèque : la classe garde sa page jusqu'à Présenter | partiel (testé localement en partie) | `TB/recette_synchro_test.dart` « UX-17 cote eleve… » ; `TB/bibliotheque_test.dart:159`, `:187` ; `TC/q/q07_bibliotheque_sans_disconnect_test.dart:106` | non | Aperçu et Présenter de la démonstration ne sont reliés à aucune publication (TB-BR-48) |
| UX-18 | Mode Tableau puis Avec notes : même page, mêmes traits, un clic | testé localement | `TB/recette_coquille_test.dart` « UX-18 : Tableau, puis Avec notes… » | oui | Rien en local |
| UX-19 | Ranger puis retrouver le support : tableau libre à part, reprise en séance | testé localement | `TB/rangement_test.dart:391` (coquille), `:125`, `:200`, `:238` | oui | L'élève après rangement : projection seulement (TB-BR-49) |
| UX-20 | Retirer le droit pendant un trait : rien sur un autre contexte, outils retirés | partiel (testé localement en partie) | `TB/recette_ecriture_test.dart` « UX-20 / R-09 : … » ; `TB/autorisation_ecrire_test.dart:446`, `:526`, `:566` | non | Diffusion réelle du retrait et refus serveur (TB-BR-51) |
| UX-21 | Observateur : droits inchangés, notices du rôle gardées | partiel (testé localement en partie) | `TB/recette_acces_test.dart` groupe « UX-21 : observateur, droits inchanges, notices du role » (tuteur et contrôleur, 390 et 1440) | oui | L'observateur n'a pas d'Agrandir : « en focus » n'est pas atteignable (TB-BR-59) |
| UX-22 | Mouvement réduit : ni vol animé ni clignotement, mêmes fonctions | testé localement | `TB/recette_acces_test.dart` groupe « UX-22 / R-16 » et « UX-22 temoin : sans mouvement reduit, le halo de « En direct » bat » | oui | La couleur de la bordure du point n'est pas mesurée |
| UX-23 | Permission micro ou caméra refusée : état réel, chemin de récupération | partiel (testé localement en partie) | `TB/recette_acces_test.dart` groupe « UX-23 : permission micro refusee… » (élève, guidée, enseignant) ; `test/features/salle_seance/salle_micro_bloque_test.dart`, `salle_secours_t_s5_test.dart` | oui | Caméra bloquée par le navigateur : aucun état ; vraie permission du navigateur (TB-BR-58) |
| UX-24 | Quitter le focus, ouvrir un panneau, tourner l'écran : ni reconnexion ni perte d'état | testé localement | `TB/recette_synchro_test.dart` « UX-24 etendu (Classe Live) : focus, panneau, rotation… » ; `TB/composition_test.dart:546` ; `TC/e/classe_live_page_test.dart:174` | non | Le compteur de remontage du support n'est lu par aucune assertion (remarque de revue, non bloquante) |

## c. Compte

| Statut | §15 (18) | §23 (24) | Total (42) |
| :--- | :--- | :--- | :--- |
| testé localement | 7 (R-02, R-03, R-04, R-05, R-15, R-16, R-17) | 19 | **26** |
| partiel (testé localement en partie) | 8 (R-06 à R-12, R-18) | 5 (UX-12, UX-17, UX-20, UX-21, UX-23) | **13** |
| non vérifié : demande BR-1 | 3 (R-01, R-13, R-14) | 0 | **3** |
| testé sur staging, déployé | 0 | 0 | **0** |

Avant TB-12, la cartographie donnait 19 prouvés, 16 partiels et 7 non vérifiables sans BR-1 (et
R-05, UX-13, UX-15, UX-18 n'étaient prouvés que sur l'écran monté seul). TB-12 fait passer à « testé
localement » R-03, R-15, R-16, UX-03, UX-07, UX-09, UX-22, UX-24 (8), et rejoue en coquille R-02, R-05,
UX-02, UX-13, UX-15, UX-18. R-07, R-10, R-11 et R-12 passent de « non vérifié » à « partiel ». UX-12
descend de « prouvé » à « partiel » : le test ne regarde que la capsule, et la mention d'en-tête garde
son point rouge. Compte : 19 + 8 - 1 = 26 ; 16 - 8 + 4 + 1 = 13 ; 7 - 4 = 3.

## d. Les 5 profils et les captures

### Où elles sont

- Matrice TB-12 : `docs/current/captures/TB-12/` (212 PNG et `LISEZMOI.md`). Commande :
  `CAPTURE_DIR=docs/current/captures/TB-12 flutter test test/features/tb_recette/captures_tb_test.dart --name tb12_`.
  5 profils (`enseignant`, `eleve`, `guidee`, `tuteur`, `controleur`) × 3 états (`libre`, `notes`, puis
  `commandes` ou `lecture` pour les observateurs) × 14 cadrages (390, 768, 1440, 320 ; ×1 et ×2 ; clair et
  sombre ; arabe RTL à 390 et 1440), plus 2 captures de mouvement (rangement, réduit et ordinaire).
  `768_x2_sombre` et `1440_x2_sombre` sont omis. Chaque test vérifie l'état nommé avant de capturer.
- Cadrages ajoutés aux étapes, dans leurs dossiers `docs/current/captures/TB-5` à `TB-11b` : TB-5 (focus au
  téléphone, développé Commandes fermées, 320 ×1) ; TB-6 (768, 320 ×1, 1440 ×2, guidée, RTL) ; TB-7a (768,
  RTL) ; TB-7b (palette avant le premier trait, tête du panneau Écrire à ×2) ; TB-8 (recherche vide LIB-04,
  768, 320 ×2 sombre, RTL) ; TB-9 (768, 390 ×2, RTL, élève après rangement) ; TB-10 (Mariam et « Peut
  écrire » visibles) ; TB-11a (768, RTL) ; TB-11b (768, ×2 à 390 et 1440, 320 ×1, RTL).
- Toutes les captures du chantier ont été régénérées (TB-2 à TB-11b, AR-SALLE-1, AR-TC-1 : 199 nouvelles,
  440 mises à jour). Une nouvelle régénération tourne au moment de ce rapport ; les noms cités ci-dessous
  restent valables.
- Non régénérés : le groupe `tb_` (SAL-00) et TB-F (référence « avant » figée). Dans AR-TC-1, quatre PNG
  `ar_salle_enseignant_{sal00,lib01}_{390,1440}_x1_clair` sont des doublons d'AR-SALLE-1.

### Ce que la lecture a couvert

Cinq lectures, une par profil : enseignant 40 captures, élève 42 (tout le profil), guidée 39, tuteur 33,
contrôleur 35, plus 48 ouvertes par l'auteur du lot. Aucune lecture n'a trouvé : commande d'enseignant chez
un autre rôle, faux « Sauvegardé », bouton plein en double (hors la pastille du contrôleur, voir plus bas),
sens RTL faux. Personne n'a pu vérifier le mouvement réduit de la guidée, du tuteur et du contrôleur : la
matrice n'en a pas.

### Classe 1 : déjà arbitré ou écart écrit

| Vu | Captures | Règle qui le couvre |
| :--- | :--- | :--- |
| Le volet Commandes recouvre le bord de la page à 768 et 1440 ×2 | `tb12_enseignant_commandes_768_x1_clair`, `…_768_x2_clair`, `…_1440_x2_clair` ; même volet chez l'élève et la guidée (`tb12_eleve_commandes_768_x2_clair`, `tb12_guidee_commandes_768_x2_clair`) | Écart voulu n° 2 de TB-5, étendu le 09/10 à 768 (×1, ×2) et 1440 ×2 : volet temporaire, fermé par Réduire ou Échap. L'écart parle de l'enseignant ; TB-R doit dire s'il couvre aussi l'élève et la guidée |
| Les mots « Micro ouvert », « Caméra allumée », « Quitter » passent en infobulle au-delà de 130 % de texte | `tb12_eleve_libre_390_x2_clair`, `tb12_guidee_libre_390_x2_clair`, `tb12_enseignant_libre_768_x2_clair` | Règle EN-12 / ETATS-BTN-1 de `lib/CLAUDE.md` (« seul un texte agrandi à plus de 130 % dans une rangée compacte »). Deux questions pour TB-R : la règle s'applique-t-elle à 768, où la place ne manque pas, et en Interface guidée ? Chez les observateurs, la sortie en icône seule relève de l'écart 11 de TB-11a, à étendre à 768 ×2 et 390 ×2 |
| Bandeau « Visite de contrôle » chez le contrôleur | toutes les `tb12_controleur_*` | C'est son propre rappel, permis par `lib/CLAUDE.md` ; ce n'est pas la mention de visite des participants (UX-21 le teste : pas de `PermanentNotice` chez le contrôleur) |
| Scène claire en thème sombre (salle de séance) ; registre inversé des observateurs ; mention grise peu contrastée chez le tuteur | `tb12_eleve_libre_390_x1_sombre`, `tb12_enseignant_libre_1440_x1_sombre`, `tb12_tuteur_libre_390_x1_clair`, `tb12_controleur_notes_768_x1_sombre` | CONTRASTE-SUPPORT-1 et PT-B « lisibilité de la salle » (HU-1) ; couleurs gelées K-37 ; monochrome en réserve TH-2. La page du support reste blanche exprès (TB-6) |
| Français dans l'interface arabe : noms (Mariam, Aïcha, Yusuf), titre « Les bonnes manières », « Classe An-Nour », « Pages 24 à 26 », « 3 séances cette semaine », « Chapitre 1 », « Écoute de la récitation » | `tb12_enseignant_notes_1440_x1_clair_ar`, `tb12_eleve_notes_390_x1_clair_ar`, `tb12_tuteur_notes_390_x1_clair_ar` | Données de démonstration, pas des libellés (écart voulu 1 d'AR-SALLE-1 ; liste `_donneesDeDemonstration` du test de rendu arabe) |
| « Élèves 2/4 » chez l'enseignant alors qu'un commentaire parle de 1/3 | `tb12_enseignant_libre_320_x2_clair` | Donnée de démonstration |
| Observateurs en « lecture » : page blanche, sans trait | `tb12_controleur_lecture_*`, `tb12_tuteur_lecture_*` | Donnée de démonstration : les observateurs lisent la page 3, le cercle est sur la page 1 (LISEZMOI). À vérifier sur staging (TB-BR-60) |
| « 32 min restantes » à moitié visible à 320 ×2 | `tb12_enseignant_libre_320_x2_clair` | Fondu voulu de la tête défilante (TB-11b) |
| La guidée n'a pas de zoom dans ses Commandes | `tb12_guidee_commandes_*` | Voulu (`voitZoomLocal`) |

### Classe 2 : divergence §22 à trancher en TB-R

- **Point rouge et « Cours enregistré, visite de contrôle possible. » sans enregistrement réel.** Vu sur toutes
  les captures de l'enseignant, de l'élève, de la guidée et du tuteur (par exemple
  `tb12_eleve_notes_390_x1_clair`, `tb12_guidee_notes_390_x1_clair`, `tb12_tuteur_libre_390_x1_clair`,
  `tb12_enseignant_notes_390_x1_clair_ar`). `PermanentNotice` est rendue sans paramètre au repos
  (`mention_seance.dart:30`) : rien côté client ne dit qu'un enregistrement tourne. C'est le cas que le §22
  demande de relever (« point rouge sans état réel »), contre ADR-011, l'invariant I-1 et l'arbitrage encore
  ouvert du document 06.
- La capsule, elle, respecte UX-12 : son point ne s'affiche que si `vue.voitPointEnregistrement`
  (`capsule_seance.dart:113-116`). Dans les captures, son second point rouge (« SI • ») vient de l'état de la
  démonstration, enregistrement `actif` par défaut (`seance_demo.dart:632`) ; avec `&enr=inactif`, il
  disparaît. Le composant est juste, la source reste à brancher (TB-BR-23).
- Réserve TB-3 : décidé par délégation le 10/10 de ne pas toucher `PermanentNotice`, composant gelé, et de
  porter la divergence à TB-R. UX-12 reste donc « partiel » dans la matrice.

### Classe 3 : défauts réels à corriger en TB-RC

Triés par gêne pour l'élève et l'enseignant. Chaque ligne a été retrouvée dans les lectures des captures ;
quatre ont été revues à l'œil pour ce rapport (marquées « revu »).

**Graves (on ne voit plus ce qu'on enseigne ou ce qu'on suit)**

1. **320 ×2 : la tête de salle prend environ 55 % de l'écran.** La page PED-03 n'a plus qu'un tiers de la
   largeur, le titre est illisible ; la feuille Commandes ne montre que le titre et les onglets ; la phrase
   de conservation est coupée. Captures : `tb12_eleve_notes_320_x2_clair`, `tb12_enseignant_notes_320_x2_clair`,
   `tb12_enseignant_commandes_320_x2_clair`, `TB-11b/tb11b_enseignant_conservation_320_x2_clair`. Cause :
   `_PlaceTelephone`, `TeteSalleBornee.part` (`salle_seance.dart`). Demande un arbitrage du directeur (pas
   une petite correction).
2. **Feuille Commandes coupée en bas, sans indice vu, chez l'élève et la guidée.** À 320 ×1, « Ajuster à
   l'écran » est tranché et Focus invisible ou coupé ; à 390 ×2 et 320 ×2, Focus est caché. Captures :
   `tb12_eleve_commandes_320_x1_clair`, `tb12_eleve_commandes_390_x2_clair`, `tb12_guidee_commandes_320_x1_clair`,
   `tb12_guidee_commandes_390_x2_clair`. Chez l'enseignant à 320 ×1, la rangée Support / Avec notes / Tableau
   est tranchée (`tb12_enseignant_commandes_320_x1_clair`). Le fondu bas ajouté en `b28136ec` n'a été remarqué
   par aucun lecteur : sa visibilité est à vérifier.
3. **La vignette de l'enseignant recouvre le coin de la feuille du tableau libre**, à 320, 390 et 768, pas
   seulement à 320 ×2 comme le dit le LISEZMOI ; elle déborde du bord de la feuille. Captures :
   `tb12_eleve_libre_390_x1_clair` (revu), `tb12_guidee_libre_390_x1_clair`, `tb12_eleve_libre_768_x1_clair`,
   `tb12_enseignant_libre_390_x1_clair`, `tb12_guidee_libre_390_x1_clair_ar` (à gauche en RTL).
4. **À ×2, la page devient petite au bureau.** Environ 220 px de large dans une scène de 1 370 px.
   Captures : `tb12_eleve_notes_1440_x2_clair`, `tb12_enseignant_notes_1440_x2_clair`.
5. **Observateurs à 320 ×2 : le bandeau chevauche la scène, les vignettes disparaissent, les noms sont
   coupés.** Captures : `tb12_tuteur_libre_320_x2_clair`, `tb12_controleur_libre_320_x2_clair`.
6. **Le bandeau d'écoute perd sa seconde phrase à ×2, même à 768 et 1440.** Tuteur : « Vous n'êtes pas
   entendu. » disparaît (`tb12_tuteur_libre_390_x2_clair`, `tb12_tuteur_libre_768_x2_clair`,
   `tb12_tuteur_libre_1440_x2_clair`). Contrôleur : il ne reste que « Visite de contrôle. », sans « ni vu ni
   entendu… inscrit au journal » (`tb12_controleur_notes_390_x2_clair`, `tb12_controleur_notes_1440_x2_clair`).

**Moyens (gêne nette, mais l'action reste possible)**

7. **Phrase vide du tableau libre qui déborde de la page à ×2** (« Choisissez un support ou écrivez au
   tableau. » sur le fond gris). Captures : `tb12_enseignant_libre_320_x2_clair`,
   `tb12_enseignant_libre_390_x2_sombre`, `tb12_enseignant_libre_768_x2_clair`, `tb12_enseignant_libre_1440_x2_clair`.
8. **« Autoriser à écrire » coupé au bas du panneau Élèves à 1440**, réduit à un trait en arabe. Captures :
   `tb12_enseignant_commandes_1440_x1_clair`, `tb12_enseignant_notes_1440_x1_sombre`,
   `tb12_enseignant_commandes_1440_x1_clair_ar`.
9. **« Page 1 sur 12 » sur deux lignes à 768 ×2, et le bouton suivant dépasse la pilule** (aussi à 390 ×1,
   768 ×1, 1440 ×1). Captures : `tb12_enseignant_commandes_768_x2_clair` (revu),
   `tb12_enseignant_commandes_390_x1_clair`, `tb12_enseignant_commandes_1440_x1_clair`.
10. **Volet Commandes à 1440 ×2 coupé en bas** : segments Support / Avec notes / Tableau à moitié visibles
    (`tb12_enseignant_commandes_1440_x2_clair`) ; Focus tronqué et « Ajuster à l'écran » collé au bord chez
    la guidée (`tb12_guidee_commandes_1440_x2_clair`).
11. **Vignettes tranchées par le bandeau d'écoute** : seconde rangée coupée, sans nom ni indice
    (`tb12_tuteur_libre_390_x1_clair`, `tb12_tuteur_libre_768_x1_clair`).
12. **Hors focus, fermer les Commandes rapetisse la page à 1440** (648 à 586 px) : mineur de TB-5 non corrigé
    par `00548b28` (reste a du lot B1).

**Mineurs**

13. **« Support illustratif » reste en français en arabe.** C'est la mention de la page de démonstration,
    écrite dans `seance_demo.dart:417` et `:596` (nulle en production) mais affichée comme une étiquette
    d'interface. Captures : `tb12_eleve_notes_390_x1_clair_ar`, `tb12_guidee_notes_1440_x1_clair_ar`.
14. **Ruban « Démonstration » qui chevauche Quitter** chez le contrôleur ; il reste en français en arabe
    (`commun.demonstration.repere` sans arabe). Captures : `tb12_controleur_libre_1440_x1_clair` (revu),
    `tb12_controleur_notes_768_x1_sombre`, `tb12_tuteur_libre_390_x1_clair_ar`.
15. **Date en français dans l'interface arabe** (« 21 sept. 2026 », fiche élève) : `historique.dateCourte`,
    `moisCourts` et `commun.dates.*` n'ont pas d'arabe (reste a et b du lot A-i18n). Capture :
    `tb12_enseignant_notes_1440_x1_clair_ar`.
16. **Nom de l'enseignant mi-arabe mi-latin en arabe**, dans le mauvais ordre (« Ibrahim سيد », initiales
    « اس »). Captures : `tb12_tuteur_libre_390_x1_clair_ar`, `tb12_controleur_libre_1440_x1_clair_ar`.
17. **Menu de rangement resté ouvert par-dessus « Support rangé » pendant le vol** (80 ms ; propre en
    mouvement réduit). Capture : `tb12_enseignant_rangement_en_cours_mouvement_ordinaire_390_x1_clair`.
18. **Pastille « 3 / 12 » du contrôleur au style de bouton plein**, à côté de Quitter, alors qu'elle ne
    commande rien. Captures : `tb12_controleur_notes_390_x1_clair`, `tb12_controleur_notes_1440_x1_clair`.
19. **Quitter de la guidée non aligné à 1440 ×2** (`tb12_guidee_libre_1440_x2_clair`) ; vignette du
    contrôleur décalée à ×2 (`tb12_controleur_notes_390_x2_clair`).
20. **Texte d'environ 12 px en Interface guidée à 1440 ×1** (bandeau, « En ligne », barre d'appel), petit pour
    un enfant : échelle typographique à arbitrer. Capture : `tb12_guidee_libre_1440_x1_clair`.
21. **Chevron de défilement dans le volet de l'élève à 768 sombre alors que le contenu tient** (non mesuré,
    à vérifier). Capture : `tb12_eleve_commandes_768_x1_sombre`.
22. Relevés par les tests TB-12, sans capture : la carte du catalogue est lue deux fois au lecteur d'écran
    (`surface_bibliotheque.dart`) ; le Quitter du tuteur est lu « Quitter le cours / Quitter » ; la capsule
    garde la diapositive précédente quand on présente le support arabe (`diapositiveDe`, non testé).
23. Hérités de la vérification, non corrigés : tuiles d'action de la fiche élève tronquées au milieu d'un mot
    (TB-10, défaut 5) ; à 320 ×2, « Revenir aux supports » ne montre que son haut pendant l'ouverture (TB-8) ;
    page du tuteur réduite à une vignette d'environ 140 px sur tablette en paysage 1100 × 700 (TB-11a).

## e. Dossiers de tests

- `test/features/tb_recette/` (tout le dossier) : `ar_salle_rtl_test.dart`, `autorisation_ecrire_test.dart`,
  `bibliotheque_test.dart`, `calque_page_test.dart`, `capsule_classe_live_test.dart`,
  `capsule_contexte_test.dart`, `captures_tb_test.dart` (en saut sans `CAPTURE_DIR`), `commandes_test.dart`,
  `composition_test.dart`, `consigne_libre_test.dart`, `ecriture_test.dart`, `observateurs_test.dart`,
  `palette_courte_test.dart`, `rangement_test.dart`, `situations_tb_test.dart`, `surface_test.dart`,
  `synchronisation_test.dart`, `visio_revelee_test.dart`, `zoom_local_libelle_test.dart` (nouveau, lot
  captures), et les quatre fichiers de TB-12 :
  - `recette_ecriture_test.dart` (5 tests : UX-20/R-09, R-03, R-08, R-06, UX-03) ;
  - `recette_synchro_test.dart` (9 tests : R-11, R-07, R-10, R-12, UX-24, UX-17) ;
  - `recette_acces_test.dart` (17 tests : UX-07, UX-23, UX-09/R-15, UX-22/R-16, UX-21) ;
  - `recette_coquille_test.dart` (12 tests : R-05, R-02, UX-18, UX-13, UX-15, UX-02, R-18).
- `test/features/salle_seance/` (salle de séance, dont `salle_micro_bloque_test.dart`,
  `salle_secours_test.dart`, `salle_secours_t_s5_test.dart`, `etats_agrandir_test.dart`, `vue_seance_test.dart`).
- `test/teaching_core/e/` (dont `classe_live_page_test.dart`) ; `test/teaching_core/a/ar_tc_rtl_test.dart` ;
  `test/teaching_core/d/` (`annotations_test.dart`, `compaction_trait_test.dart`) ; `test/teaching_core/f/`
  (`protocole_canaux_test.dart`, `etat_partage_seance_test.dart`) ; `test/teaching_core/g/salle_observation_test.dart` ;
  `test/teaching_core/q/` (`q05`, `q06`, `q07`).
- `test/i18n/` : `ar_domaines_test.dart`, `ar_donnees_isolees_test.dart`, `fr_ponctuation_test.dart`
  (nouveau en `4917671d`), `cle_audio_test.dart`.
- `test/features/demo/` (dont `demo_salle_page_test.dart`, `repere_demonstration_test.dart`) ;
  `test/mouvement/mouvement_test.dart` ; `test/widgets/composants_test.dart` ;
  `test/capture/tb_f_reference_capture_test.dart` ; outils `test/router/support_routeur.dart` et
  `test/support/aucun_mot_coupe.dart`.
- Suite complète sur `a5393f82` (poussé) : +6941 ~3884, 0 échec (15 min 29) ; slang et build_runner sans diff ; `dart analyze --fatal-infos` 0 ; `verifier_jetons` 39 ; `verifier_revue` 1609 (base 1611). Base 35fd3490 : +6681 ~3474, 0 échec.

## f. Corrections faites pendant la vérification et la recette

Vérification de TB-5 à TB-11b, AR-SALLE-1, AR-TC-1 (chaque correction a un test qui échoue sans elle) :

| Commit | Étapes | Correction |
| :--- | :--- | :--- |
| `4917671d` | TB-8, TB-9, AR-SALLE-1, AR-TC-1 | Salle arabe sans libellé français : `commun.reessayer`, `commun.annuler`, `destructif.irreversible`, bloc `presence` (28 clés) en arabe ; fraction de page isolée de gauche à droite ; vocabulaire « الفصل » et « حالات الاحتياط » ; espaces insécables avant ? ! : ; (39 valeurs) ; carte de Mes classes : capacité sous le nom à 320 ×2 |
| `00548b28` | TB-5 | En focus, le déclencheur Commandes monte dans la tête, la page grandit (UX-14 mesuré sur la hauteur et la largeur) |
| `b28136ec` | TB-8, TB-10, TB-11b | Message d'ouverture lu entier dans le pied ; retrait sans crayon ; mentions de la ligne élève entières (`Wrap`) ; indice de défilement des Commandes et tuile qui garde son mot ; zoom unique et volet dans le cadre chez l'élève ; conservation signalée à 320 ×2 (corrigé en partie) |
| `980b51e6` | TB-7a, TB-7b | Annuler verrouillé (plus de double annulation) ; palette stable à 320 ×1 ; bouton focalisé qui ne rétrécit plus (`Pressable`, `StackFit.passthrough`) |
| `3f110455` | TB-6, TB-11b | Test « masquer puis réafficher » qui porte vraiment un trait ; page fixe dans le sens de son document ; garde « Sauvegardé » sur les valeurs et les chaînes entières |
| `2d38362e` | AR-TC-1 | La mesure de largeur de la carte de classe libère ses `TextPainter` |

Pendant TB-12 :

- `lib/features/demo/repere_demonstration.dart` : `explicitChildNodes: true` (UX-21). Avant, la salle des
  observateurs entière était lue comme un seul bouton ; Quitter n'avait pas de cible propre. Contre-épreuve :
  4 échecs sans la correction.
- `lib/features/salle_seance/surface_page_fixe.dart:563` : sens du document décidé sur `[titre, mention]` et
  non plus `[mention, titre]` (R-18). Un support arabe se mettait de gauche à droite à cause de la mention
  française de démonstration. Contre-épreuve : les deux tests R-18 échouent (ltr).
- `lib/features/demo/seance_demo.dart` : données de démonstration arabes (R-18) : support
  `demo-adab-talib`, titre vocalisé non coranique « آدَابُ طَالِبِ العِلْمِ », 3 pages, langue « ar », sans
  image ni page de Coran.
- `lib/features/salle_seance/barre_support.dart` (`ZoomLocal`) : `maxLines: 2` au lieu de 1. À 1440 ×2, la
  phrase du zoom local n'est plus coupée. Contre-épreuve : `zoom_local_libelle_test.dart` échoue à 1440 ×2 et
  1280 ×2.
- `test/features/tb_recette/recette_acces_test.dart` (UX-22, `a5393f82`) : l'assertion du point
  d'enregistrement cherchait le fondu chez un ancêtre et passait toujours ; elle le cherche maintenant parmi
  les descendants. Contre-épreuve : mouvement réduit ignoré, 1 échec.
- Harnais de captures : assertion Mariam durcie (zone visible de la liste) ; commentaire faux sur la phrase
  de conservation à 320 ×2 corrigé. Aucune assertion retirée.

## g. Limites et auto-contrôle (§22, « après chaque lot »)

- **Exigences couvertes** : les 42 scénarios ont une ligne, un statut et un test nommé ; aucun n'est déclaré
  au-delà de « testé localement ».
- **Fichiers réellement modifiés par TB-12** : les quatre `recette_*_test.dart`, `captures_tb_test.dart`,
  `zoom_local_libelle_test.dart`, `repere_demonstration.dart`, `surface_page_fixe.dart`, `seance_demo.dart`,
  `barre_support.dart`, `docs/current/captures/TB-12/` et les dossiers régénérés ; ce rapport et `TB-BR.md`.
- **Ce que rien ici ne prouve** : le réseau LiveKit (perte, ordre, jeton), l'arrivée sur un autre appareil,
  la conservation hors séance, la mémoire et la fluidité sur appareil, la vraie permission du navigateur,
  l'encre reçue à l'écran de l'élève. La démonstration simule le serveur : `ValueNotifier` pour le droit
  d'écrire, dépôt `AnnotationsMemoire` partagé, `TransportMemoire`.
- **Faiblesses connues des tests** (relevées par les relecteurs, non bloquantes) : R-18 contient une
  assertion creuse (`didExceedMaxLines` sans `maxLines`) et une relecture de constante ; UX-24 déclare un
  compteur de remontage jamais lu ; UX-17 modélise l'aperçu par une simple lecture ; la contre-épreuve d'UX-02
  passe par l'assertion de masquage ; la contre-épreuve de déduplication de R-10 dans `lib/core/tc_realtime`
  n'a pas été faite (refusée par le garde de permissions), un témoin brut du transport la remplace.
- **Captures** : elles montrent un rendu, pas un comportement. Il manque le mouvement réduit pour la guidée,
  le tuteur et le contrôleur, et `768_x2_sombre`, `1440_x2_sombre`. Les relecteurs ont ouvert 189 captures
  sur 212 ; aucune ne remplace un test.
- **Vérificateurs** : `dart run tool/verifier_jetons.dart` et `tool/verifier_revue.dart` sortent en code 1
  avec leur socle existant (39 et 1611) ; aucune violation ne vise un fichier modifié par TB-12.
- **À trancher en TB-R** : la divergence du point rouge (classe 2) ; l'écart n° 2 de TB-5 appliqué à l'élève
  et à la guidée ; la règle des mots d'état à 768 et en Interface guidée ; la place de la tête de salle à
  320 ×2.
- **Ce rapport n'autorise aucun déploiement.** Pousser sur `main` met en production.
