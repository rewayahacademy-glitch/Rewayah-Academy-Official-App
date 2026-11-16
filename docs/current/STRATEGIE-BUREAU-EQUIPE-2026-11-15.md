# Stratégie « Bureau de l'équipe » — 15/11/2026

**Statut : vagues 0 et 1 ordonnées par le directeur le 16/11/2026 ; vagues 2 à 5 proposées, sans ordre. Suivi : `BUREAU-EQUIPE/SUIVI.md`.**

Demande du directeur (15/11) : la gestion du personnel « fait tourner en rond », « ne permet
pas de gérer beaucoup de personnes rapidement » ; il veut inviter des associés par e-mail et
leur confier des dossiers et des tâches choisies, sans leur « coller » un rôle ; retrouver le
Studio comme lieu de travail de l'équipe ; donner à un agent IA le droit de trier et de
préparer des listes. « Je veux une stratégie. Il ne faut pas créer du code. »

Ce document s'appuie sur `CANDIDATURES/VISION_RECRUTEMENT_2026-11-14.md` et
`CANDIDATURES/REVUE_PARCOURS_DIRECTION_2026-11-14.md` : il ne les refait pas.

## 1. Ce qui est vrai aujourd'hui (lu dans le code de `main`, tête `9bac234b`, le 15/11)

| Sujet | Fait vérifié | Preuve |
| :--- | :--- | :--- |
| Studio | Jamais servi par le serveur : aucune table, port `StudioIndisponible`. Masqué exprès le 11/11 (commit `878d21af`, PR #435) parce qu'il n'affichait que « indisponible » | `lib/features/com_studio/port_studio.dart:343-389` |
| Studio | Ni membres, ni tâches, ni objectifs, ni conversation privée entre deux membres de l'équipe | même fichier ; aucune migration |
| Dossier suivant | Absent. La fiche reste sur place après un geste ; ni suivant, ni précédent | `admin_candidature/candidature_page.dart:141-188` |
| Retours | Traitement, Accueil et Comptes ouvrent Dossiers par `go` : la pile est perdue. La liste part vers Invitations et Créneaux par `go` : filtres perdus | `traitement_page.dart:88,90` ; `tableau_de_bord_page.dart:94` ; `comptes_page.dart:1553,1564` ; `candidatures_page.dart:994,1019` ; `file_dossiers.dart:56` |
| Position | Filtre, tri et page dans l'état du widget, pas dans l'adresse ; aucune mémoire du défilement | `candidatures_page.dart:141-148` |
| Doublons | La pièce se valide dans la fiche et dans « Dossiers à valider » ; « Traitement » et « Dossiers » mènent aux mêmes dossiers ; deux surfaces d'invitation | `piece_sur_place.dart`, `revue_dossier.dart`, `invitations_personnelles.dart` |
| Suspendre, bloquer | Aucun geste sur un compte. Côté candidature, `restreindre` et `lever_restriction` existent au serveur mais pas à l'écran | `comptes_page.dart:1540-1590` ; `gestes_candidature.dart:27-64` |
| Rôles | Un seul rôle par personne (six valeurs). Aucune invitation d'admin ni de contrôleur : seulement enseignant, comptable, famille | `0001_fondations.sql:26,74` ; `invitations_page.dart:80-90` |
| Droit à la carte | Un seul modèle existe : `private.controle_capacites` (portée, début, fin, retrait, motif). Non branché à un écran | `20261011121039_c29_control_capabilities.sql:6-40` |
| Responsable | Colonne et geste présents ; 0 dossier sur 72 en a un ; le nom n'est pas affiché ; pas de filtre | `blocs_candidature.dart:880-911` |
| Contact masqué | Droit donné seulement à la main dans la base ; aucun écran pour l'accorder | `cand_l1_socle…:284,833` |
| « Contrôle modifié » | Le détail existe en base ; la lecture de l'historique ne le renvoie pas | `cand_l1_socle…:934-947` |
| Filtres | Ijaza, langues, riwayat, disponibilités, créneaux : collectés, **non filtrables** au serveur | `modele_questions.dart:124-212` |
| Listes | Aucune liste enregistrée, étiquette ni segment | aucune table |
| Agent IA | Existe en lecture seule : un jeton de 24 h, **une seule personne observée**, aucune écriture | `0014_acces_agent.sql` ; `admin_acces_agents` |
| Message en double | La bulle locale n'est retirée que si son texte est identique à celui du serveur | `core/widgets/fil_discussion.dart:1092-1134` |
| Textes anglais | Les textes français existent ; l'application de l'appareil était en anglais | `textes_fil_communication.dart:17-28` |

Non vérifié : l'état en production des lots du 14/11 notés « À LIVRER » dans le registre
(la carte « Qui attend quoi » est dans `main` ; le registre est donc à remettre à jour par le
pilote avant tout lancement).

## 2. L'idée : trois briques, un lieu

Le directeur ne manque pas d'écrans. Il manque trois choses, et tout le reste en découle.

1. **La file.** Le travail vient à la personne. On ouvre une file (« pièces à valider »,
   « mes dossiers »), le premier dossier s'affiche, on décide, le suivant arrive seul. La
   liste ne sert plus qu'à choisir la file. Référence : le tri d'une boîte de réception et
   les outils de recrutement (un dossier, une décision, le suivant).
2. **La mission.** Une personne garde ce qu'elle est (enseignant, comptable, personne
   extérieure). On lui confie une ou plusieurs missions. Une mission = des gestes cochés un
   par un + un périmètre (côté hommes ou femmes, langue, liste, dossiers confiés) + une date
   de fin facultative. Elle se retire d'un geste, sans toucher au compte. Plusieurs
   personnes peuvent porter la même mission. Référence : l'attribution « personne + droits +
   périmètre » des consoles d'administration ; le modèle existe déjà ici
   (`controle_capacites`), on le généralise au lieu d'en inventer un.
3. **La liste.** Un groupe de personnes qu'on garde : soit un filtre enregistré (toujours à
   jour), soit des personnes ajoutées à la main. Une liste sert à affecter, à écrire, à
   confier.

**Le Studio** n'est pas une quatrième brique : c'est la porte d'entrée de l'équipe. Il
montre à chacun ses files, ses dossiers confiés, les messages sans réponse, l'objectif
commun, et le fil de l'équipe.

**L'agent IA** n'est pas un cas à part : c'est un membre de l'équipe avec une mission.

## 3. Règles tranchées (réversibles, à amender par décision datée)

- R1. **Les tâches ne se saisissent pas.** Un dossier confié est une tâche ; elle se coche
  quand le dossier avance. Une seule saisie libre : une note « à faire » sur un dossier.
  (Vision du 05/11 : une donnée saisie doit servir, pas de corvée.)
- R2. **Les objectifs se comptent seuls** : une file, un nombre visé, une date (« les 41
  dossiers en examen à 0 avant vendredi »). Le compteur vient du serveur.
- R3. **Amendée le 16/11/2026 par `BUREAU-EQUIPE/SECRETAIRE-IA.md` §3 (quatre niveaux d'autonomie) ; le texte qui suit ne vaut plus que pour le niveau B.** L'agent IA propose, l'humain décide. L'agent peut : lire les dossiers de son
  périmètre, ranger dans une liste, écrire une proposition motivée. Il ne peut pas :
  accepter, refuser, valider une pièce, écrire à un candidat, voir une pièce d'identité ni
  un contact. La personne confirme les propositions en lot. Le journal écrit « agent ».
- R4. **Les deux côtés restent** (A15) : une mission ne fait jamais sortir de son côté ; le
  directeur reste le seul à voir les deux.
- R5. **Un seul endroit par geste** : la pièce se valide dans le dossier. « Dossiers à
  valider » et « Traitement » deviennent des files, pas des pages. Aucune suppression de
  module sans accord du directeur ; les anciennes adresses redirigent.
- R6. **Suspendre et rétablir** : deux mots, un motif, une trace. « Bloquer » n'est pas un
  troisième état.
- R7. **Le Studio réutilise la messagerie existante** (`com_fils`, `com_messages`,
  `com_signaux`) : pas de second moteur de messages, pas de charge nouvelle sur la base
  (panne du 15/11, `STRATEGIE-BASE-ECONOME`).
- R8. Un titre (« représentant dans l'Union européenne ») est une mention affichée, pas un
  droit. Le mandat écrit se règle hors de l'application.

## 4. Les lots, dans l'ordre

Chaque lot : une PR, une phrase que le directeur vérifie en production.

### Vague 0 — Réparations (aucune décision, petits)
| Lot | Contenu | Zone |
| :--- | :--- | :--- |
| BE-0a | Message en double : rapprocher par la clé d'envoi, plus par le texte | `core/widgets/fil_discussion.dart` |
| BE-0b | Historique lisible : la lecture renvoie le détail et le nom du responsable ; le dossier affiche le nom | serveur + `admin_candidature/blocs_candidature.dart` |
| BE-0c | Retours : les `go` listés au §1 deviennent des `push` ; filtres, tri et page de la liste dans l'adresse (comme Comptes) | `admin_candidatures`, `admin_traitement`, `admin_tableau`, `admin_comptes` |

Phrase : « J'ouvre un dossier depuis n'importe où, "retour" me ramène d'où je viens, avec
mes filtres. »

### Vague 1 — La file
| Lot | Contenu | Zone |
| :--- | :--- | :--- |
| BE-1a | Serveur : la liste filtrée rend l'ordre des dossiers ; filtres sur les réponses (ijaza, langues, riwayat, jours et créneaux disponibles, public) ; filtre « pièce en attente » et « mes dossiers » | `supabase/**` |
| BE-1b | Dossier : « Précédent / Suivant », compteur « 3 sur 41 », passage au suivant après une décision (annulable quelques secondes), raccourcis clavier sur ordinateur | `admin_candidature` |
| BE-1c | Une seule file : « Dossiers à valider » et « Traitement » deviennent des entrées de la carte « Qui attend quoi » ; redirections | `admin_candidatures`, routeur |

Phrase : « Je traite les 13 pièces à valider sans revenir une seule fois à la liste. »

### Vague 2 — La mission
| Lot | Contenu | Zone |
| :--- | :--- | :--- |
| BE-2a | Serveur : missions (gestes cochés), attributions (personne, périmètre, début, fin, retrait, motif), une fonction unique « cette personne a-t-elle ce geste sur ce dossier », lue par les fonctions de candidature et par les capacités ; invitation par e-mail d'un associé (personne extérieure ou compte existant) | `supabase/**` |
| BE-2b | Écran « Équipe » : inviter, cocher les gestes, choisir le périmètre et la fin, retirer ; voir qui a quoi | nouveau dossier `features/admin_equipe` |
| BE-2c | Confier : responsable posé en lot depuis la liste, file « Mes dossiers », droit « voir le contact » accordé depuis l'écran | `admin_candidatures` |
| BE-2d | Compte : suspendre, rétablir (serveur + menu de Comptes), `restreindre` exposé dans le dossier | serveur + `admin_comptes` |

Phrase : « J'invite un ami par e-mail, je coche cinq gestes sur les candidatures en anglais ;
il ne voit que cela ; je retire la mission, il ne voit plus rien et son compte n'a pas changé. »

BE-2a est le seul lot sensible : cahier écrit par le pilote avant codage, scénarios SQL des
refus obligatoires (mauvais côté, mission expirée, mission retirée, geste non coché).

### Vague 3 — La liste
| Lot | Contenu | Zone |
| :--- | :--- | :--- |
| BE-3a | Serveur : listes (filtre enregistré ou membres ajoutés), partage à l'équipe | `supabase/**` |
| BE-3b | Écran : « Enregistrer ce filtre », « Ajouter à une liste », ouvrir une liste comme une file, « Écrire à la liste » par le circuit `prevenir_candidats` existant (jamais deux fois, S3) | `admin_candidatures` |

Phrase : « Les enseignants avec ijaza, libres le soir quatre jours : une liste gardée, à qui
j'écris en un geste. »

### Vague 4 — Le Studio
| Lot | Contenu | Zone |
| :--- | :--- | :--- |
| BE-4a | Serveur : fil de l'équipe et conversation privée entre deux membres, sur les tables de la messagerie ; objectifs (file, nombre, date) | `supabase/**` |
| BE-4b | Studio allégé : « Aujourd'hui » (mes files, mes dossiers, messages sans réponse, objectif), « Équipe » (le fil), « Privé ». Les huit sections et les vues sans serveur ne sont pas montrées. Le fil emploie la page de conversation plein écran déjà livrée (#501) | `com_studio` |

Phrase : « Mon associé et moi nous écrivons dans le fil de l'équipe ; chacun voit ses
dossiers du jour et où en est l'objectif. »

### Vague 5 — L'agent IA
| Lot | Contenu | Zone |
| :--- | :--- | :--- |
| BE-5a | Serveur : le jeton d'agent porte une mission (règle R3) au lieu d'une personne observée ; propositions ; auteur « agent » au journal | `supabase/**` |
| BE-5b | Écran : « Propositions » dans le dossier et en lot dans la file ; l'accès d'un agent se donne depuis « Équipe » | `admin_candidature`, `admin_equipe` |

Phrase : « Je donne un accès de 24 h à un agent ; il me rend une liste et trente
propositions ; j'en confirme trente d'un geste ; le journal dit qui a proposé et qui a décidé. »

## 5. Répartition (quatre agents au plus, zones séparées, petits modèles)

| Agent | Zone exclusive | Lots |
| :--- | :--- | :--- |
| Serveur | `supabase/**`, adaptateurs `*_supabase.dart` | 0b (serveur), 1a, 2a, 2d (serveur), 3a, 4a, 5a |
| File | `features/admin_candidature`, `admin_candidatures`, `admin_traitement`, `admin_dossiers` | 0b (écran), 0c, 1b, 1c, 2c, 3b, 5b |
| Équipe | `features/admin_equipe`, `admin_comptes`, `admin_invitations` | 2b, 2d (écran) |
| Studio | `features/com_studio`, `com_messages`, `core/widgets/fil_discussion.dart` | 0a, 4b |

Un seul relecteur, le pilote : il écrit le cahier de chaque lot, relit, vérifie la
cohérence entre agents, fusionne, installe les migrations.

## 6. Conseils pour que de petits modèles réussissent

1. **Le contrat d'abord.** Avant chaque vague, le pilote écrit le port Dart et la signature
   de la fonction serveur (noms, champs, refus). L'agent Serveur et l'agent d'écran codent
   alors en parallèle contre le même contrat, l'écran avec un faux port de test.
2. **Un cahier d'une page par lot** : les fichiers à lire (cinq au plus), les fichiers à
   toucher, ce qu'il est interdit de toucher, la phrase à rendre vraie, les cas de refus.
3. **Réutiliser, nommé dans le cahier** : `feuille_geste.dart`, `lot_candidatures.dart`,
   `carte_attentes.dart`, `prevenir_candidats.dart`, `volet_conversation.dart`,
   `controle_capacites` (modèle), la page de conversation plein écran, DECISION-LISTES,
   DECISION-DEFILEMENT, DECISION-FLUIDITE (décider = geste sensible attendu ; passer au
   suivant = immédiat).
4. **PR courtes** (une idée, moins de 400 lignes hors tests), captures R3, ligne au registre
   le jour même.
5. **Migrations** : compter `DROP`, `DELETE`, `TRUNCATE` ; au-dessus de 0, page à coller
   pour le directeur (`tool/page_migrations/generer.py`).
6. **Aucun écran sans son serveur** : une vague ne montre rien tant que sa fonction serveur
   n'est pas en production (règle du 11/11, plus aucun « indisponible »).

## 6 bis. Le dossier repensé (ajout du 16/11/2026, après la vidéo du directeur)

Demande du directeur (16/11) : « la lourdeur, la longueur » de la page du dossier ; « des
boutons d'actions qui manquent » ; « pourquoi ne pas mettre chaque bouton d'action à côté de
sa rubrique ? » ; les heures « sous forme de tableau » qui s'adapte à l'arabe ; « marquer
notre impression » ; dispenser d'entretien, d'abord ses associés fondateurs.

### Vu dans la vidéo (98 s, téléphone, production)

| Constat | Détail |
| :--- | :--- |
| Entrée | « Personnes » reste vide environ cinq secondes, puis ouvre « Dossiers à valider » (173), pas « Candidatures » (324) ; il faut un menu déroulant de huit lignes pour y aller |
| Avant le premier nom | Texte d'introduction, bandeau « Lecture des deux côtés », cinq liens, les cartes, « À traiter », la recherche, les filtres : plusieurs écrans à faire défiler |
| Ordre du dossier | Identité, photo, « Ce qui bloque », « Prochaine action », pièce et entretien, bandeau, « Échanger », réponses, autres compétences, « Contrôles », responsable, contact, historique : environ dix écrans |
| Redite | « Contrôles » répète « Ce qui bloque » ; la pièce apparaît trois fois |
| Un seul geste à la fois | Tant que le moyen de versement n'est pas confirmé, « Prochaine action » ne montre que ce bouton |
| Complément | La feuille ne propose que des documents (contrat, code, pièce, photo, accord…). Après l'envoi : « En attente de la personne », plus aucun geste |
| Photo | Petite, non ouvrable : un appui sélectionne le texte du titre |
| Pièce déposée | « Ouvrir dans Dossiers à valider » fait quitter le dossier vers une liste de 173 noms |
| Disponibilités | Une phrase : « Vendredi, samedi et dimanche : 21 h » |
| Texte technique | « Version du questionnaire : salle-examen-2 » ; bandeau « Messages pas en direct » dans chaque dossier |
| Dossier suivant | Retour à la liste, puis défilement |

### Vérifié au serveur

- `demander_complement` en salle d'examen n'est permis que dans l'état `en_examen` et fait
  passer à `a_completer` : **une seconde demande est impossible** tant que la personne n'a
  pas renvoyé (`20261022000000_cand_l2a1_moteur_salle_examen.sql`, table des règles).
- Le serveur ne lie pas le complément au moyen de versement : c'est l'écran qui ne montre
  qu'un geste. Non vérifié : le contenu du menu « ⋯ ».
- **Aucune dispense d'entretien** : le seul chemin vers « confirmée » passe par planifier,
  tenir l'entretien, puis valider la pièce. `personnel_fondateurs` n'est qu'une coche.

### Règles du dossier

- D1. **Trois étages.** En haut, fixe : nom, photo, situation en une phrase, « précédent /
  suivant ». Au milieu : un résumé de cinq lignes pour juger en dix secondes (langues,
  niveau, ijaza, disponibilités, pays et versement). En dessous : les rubriques, **repliées**,
  chacune avec sa pastille (bon, à voir, manque).
- D2. **Chaque rubrique porte ses gestes** : Photo (elle s'affiche quand on la touche, sans bouton « voir en grand », décision du 16/11 ; en demander une autre),
  Pièce (voir, valider, en demander une autre, sur place), Versement (confirmer, écarter),
  chaque groupe de réponses (demander une précision), Entretien, Messages. « Contrôles »
  disparaît : la pastille de la rubrique le remplace.
- D3. **Le panier de demandes.** Chaque « demander » s'ajoute à un panier ; un seul envoi.
  On peut en ajouter tant que la personne n'a pas répondu, quel que soit l'état du versement.
- D4. **Ce que la personne reçoit se voit avant l'envoi** : un message dans sa langue, la
  liste exacte de ce qu'on attend, un bouton par point qui mène au bon endroit, et rien
  d'autre de rouvert. (M14, M15.)
- D5. **La décision reste sous le pouce** : barre fixe en bas (Accepter, Demander, Refuser,
  ⋯). Un bouton grisé dit pourquoi.
- D6. **Disponibilités en grille** jours × heures, dans le fuseau du candidat et dans celui
  du lecteur ; en arabe la grille se retourne, les heures restent en chiffres latins de
  gauche à droite.
- D7. **L'impression** : trois niveaux et une note privée, jamais montrés au candidat ;
  visibles et filtrables dans la liste. Elle sert à trier, pas à décider seule.
- D8. **La voie directe** : « Dispenser d'entretien », avec un motif, réservée au directeur
  ou à une mission qui la porte, écrite au journal. Pour un fondateur : « Accueillir comme
  fondateur » saute l'examen et l'entretien. La pièce d'identité, les accords signés et le
  moyen de versement restent exigés (droit et paie).
- D9. Aucun mot technique à l'écran ; l'état de la connexion des messages ne s'affiche que
  dans la conversation.

### Lots (ils entrent dans la vague 1)

| Lot | Contenu | Zone |
| :--- | :--- | :--- |
| BE-1d | Dossier en trois étages, rubriques repliées avec leurs gestes, photo qui s'affiche au toucher, pièce sur place, barre de décision fixe, entrée de « Personnes » sur Candidatures, en-tête de liste réduit | `admin_candidature`, `admin_candidatures` |
| BE-1e | Panier de demandes : serveur (demander à tout moment, plusieurs fois, sur une réponse précise) ; écran (panier, aperçu du message) ; côté candidat (liste claire, un bouton par point) | serveur + `admin_candidature` + `features/candidature` |
| BE-1f | Grille des disponibilités, deux fuseaux, sens arabe | `admin_candidature`, composant dans `lib/core/widgets` |
| BE-1g | Impression (serveur, dossier, liste, filtre) ; dispense d'entretien et accueil d'un fondateur (serveur + geste) | serveur + `admin_candidature` |

Phrases : « Je juge un dossier sans faire défiler plus d'un écran. » « Je demande une autre
photo et une précision sur les créneaux en un seul envoi, et j'en ajoute une le lendemain. »
« J'accueille mes associés fondateurs sans entretien. »

## 7. Ce qui écarte de la Boucle 1, dit avant d'obéir

Les vagues 0 et 1 servent directement la validation des enseignants (K1) à grande échelle.
Les vagues 2 à 5 sont des lots nouveaux hors boucle : elles ne se lancent que sur ordre
daté du directeur, après les lots du 14/11 encore notés « À LIVRER » (D5).
