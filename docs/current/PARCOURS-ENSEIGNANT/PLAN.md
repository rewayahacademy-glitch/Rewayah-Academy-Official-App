# Parcours de l'enseignant : constats, arbitrages et plan (19/11/2026)

Statut : **proposé, non validé par le directeur**. Rien n'est codé. Check-liste : `SUIVI.md`.

Sources de ce document : la demande orale du directeur du 19/11, son manuscrit
(`MANUSCRIT-2026-11-19.md`), le code de `main` (commit `2b4c9d8f`), la base de production lue le
19/11 (lecture seule), 299 messages internes de 113 candidats, 55 fils de courriels de 47
candidats. Aucun nom ni adresse n'est écrit ici.

## 0. D'abord : ce qui est faux, bloqué, inconnu ou non prouvé

- **Rien de ce plan n'est fait.** C'est une recherche et une proposition.
- **Ce chantier sort de la Boucle 1.** Il est lancé parce que la demande explicite la plus récente
  du directeur prévaut. Il répète un risque connu : sept vagues ouvertes d'un coup. La réponse est
  l'ordre du §8 : une vague à la fois, des lots d'une PR.
- **Le blocage « the check did not complete » à la connexion n'est pas diagnostiqué.** C'est le
  message d'échec du contrôle anti-robot (Turnstile). Cause inconnue (réseau, navigateur intégré
  d'une application de messagerie, bloqueur). Un candidat attend sans réponse depuis le 18/11.
- **12 fils de courriels de candidats attendent une réponse de l'académie** (captcha, créneaux,
  versement, « que faire », double compte). Ce n'est pas du code : c'est à traiter aujourd'hui.
- **166 candidats sont invités à choisir un entretien et il n'y a pas de créneau ouvert** pour
  beaucoup d'entre eux (au moins 15 l'écrivent). L'avis automatique à l'ouverture d'un créneau
  (R22) n'est toujours pas construit.
- **Non vérifié** : si la migration `20261129410000_accueil_separe` (qui interdit d'accueillir un
  enseignant sans pièce validée) est installée en production ; si la PR #524 (la marque « je viens
  postuler » dans le lien de connexion) a été fusionnée ; si la production a quitté la machine
  gratuite (R19). Ces trois points sont à lire avant les lots concernés.
- **Le registre des lots et `BUREAU-EQUIPE/SUIVI.md` sont en retard** sur `main` (ex. les lots
  Praxis PX-0 à PX-2 sont livrés, le suivi dit « pas commencé »).
- **La lenteur du bureau n'est pas mesurée.** Les causes du §3.7 sont lues dans le code ; aucune
  n'est chronométrée.
- **« ميثاق المعلم » n'existe nulle part dans l'application.** Le même texte porte aujourd'hui
  trois noms arabes différents (§2.6). Le nom officiel est à choisir par le directeur (§9, Q2).

## 1. Ce que le directeur a demandé (reformulé pour vérifier que c'est compris)

Sept chantiers, dans cet ordre de parole :

1. **Le parcours du candidat**, du courriel reçu jusqu'à la dernière salle : courriel bien
   traduit ; un lien qui « me connaît » et ne me jette pas sur une page de connexion ordinaire ;
   une entrée où l'on sait si l'on crée un compte élève ou enseignant ; un formulaire en langage
   simple (riwayat, juz) ; une vraie page d'accueil du candidat (état du dossier, messages,
   annonces rangées, partage), jolie, avec une navigation en bas ; un retrait qu'on ne fait plus
   par erreur.
2. **Le bureau de la direction pour traiter les dossiers** : un seul dossier, quel que soit le
   chemin ; une synthèse en haut (pièce vérifiée ou non, dernière utilisation de l'application) ;
   pas d'acceptation sans pièce vérifiée ; filtres, tri par date, actions en groupe qui servent ;
   épingler un profil ; un tableau de bord refait à 100 % ; un en-tête qui ouvre des fenêtres
   légères, pas des pages ; deux ou trois pages au plus ; rapide, pour 600 dossiers aujourd'hui et
   plus de 1 000 bientôt, traités par une seule personne.
3. **Les outils de l'échange** : messagerie (copie en échec qui reste, effacer un message,
   sécurité, images, lecteurs, liens, gestes rapides, profil suffisant pour décider) ; annonces
   (écrire simplement, choisir précisément les destinataires, affichage).
4. **Les pages secondaires, partout** : feuilles du bas mal rangées, feuille plein écran qu'on ne
   peut plus fermer, glissement qui rouvre, retour qui ramène toujours à l'accueil, fil d'Ariane
   rare, icône de messagerie qui disparaît.
5. **L'espace de l'enseignant accepté** : un accueil vivant (événements de la direction avec
   miniatures, cartes des cours), cartes des Classes, élèves, bibliothèque ; barre du bas moins
   haute, zones tactiles plus généreuses, dans un composant commun.
6. **Les icônes** : est-ce un grand chantier ? Icônes animées et modernes (useanimations.com).
7. **Praxis commence à travailler** : trier et classer les dossiers pour que le directeur n'ait
   plus qu'à décider (entretien, dispense, autre).

Et par-dessus : lire les messages et les courriels des candidats, consigner leurs problèmes dans le
document qui prépare l'inscription des élèves ; donner les standards ; arbitrer ; tout écrire.

## 2. Constats : le parcours du candidat

### 2.1 Les courriels

| Constat | Preuve |
| :--- | :--- |
| Le courriel « lien de connexion » part avec un **sujet en anglais** (« Your sign-in link ») et un **corps en français** à un candidat arabophone. | Courriel lu le 19/11. Le sujet est fixe ; le corps suit `user_metadata.langue`, que la création de compte n'écrit pas (`service_auth.dart:83`, `signInWithOtp` sans donnée). |
| Son lien ramène à la **racine** de l'application, sans rien qui dise « candidat ». | `redirect_to=https://app.rewayahacademy.com` ; `service_auth.dart:85`. |
| L'invitation personnelle part **en français** quand la personne n'a pas de profil. | `envoyer_invitations_candidats_importes` ne passe pas `langue` ; le déclencheur retombe sur `fr`. |
| « Votre candidature est retenue pour un entretien » est parti en français à au moins 4 personnes qui répondent en arabe ou en anglais. | Courriels lus le 19/11. |
| L'invitation arabe garde le nom du formulaire en français et un lien de désinscription `/fr/`. | Courriel lu le 19/11. |
| Environ 114 avis de non-distribution en 21 jours (boîte pleine, adresse mal saisie). | Boîte lue le 19/11 ; déjà R25. |

### 2.2 L'arrivée par le lien

| Constat | Preuve |
| :--- | :--- |
| Le lien d'invitation ouvre la **page de connexion ordinaire**, en mode création, sans l'adresse préremplie. | `connexion_page.dart:242-276` : aucune affectation du champ ; le lien ne porte que le code. |
| La marque « je viens postuler » ne vit que dans la **mémoire du navigateur**, deux jours. | `invitation_en_cours.dart:45`. Lien ouvert dans un autre navigateur, ou après deux jours : la personne tombe sur les deux cartes « pour moi » / « mon enfant ». |
| Le lien `invitation=1` est lu comme une invitation d'**équipe**, pas de candidat. | `invitation_compte.dart:54-69`. |
| Un nouveau compte ne choisit jamais « enseigner » par une carte : seulement par un lien. | `usage_etape.dart:208-270`. |
| `/connexion` sans paramètre sur un appareil inconnu envoie vers le questionnaire des **familles**. | `ordre_entree.dart:70-79`. |
| **20 candidatures sont portées par un compte au rôle famille**, 600 par un compte enseignant. Il existe 20 demandes de type élève adulte (18) ou famille (2). On ne sait pas lesquelles sont de vrais élèves. | Production, 19/11. |
| Un candidat a reçu 9 liens de connexion en 80 minutes. | Courriels lus le 19/11. |

### 2.3 Le formulaire

- **Juz** : question à choix unique, quatre réponses : rien, moins de 10, de 10 à 29, tout le Coran
  (`modele_questions.dart:131-141`). On ne peut pas donner un nombre exact.
- **Riwayat** : choix multiple de 1 à 20 ; six proposées d'emblée, « toutes », puis « une autre »
  avec recherche (`question_etape.dart:480-530`).
- 4 personnes écrivent pour une question du formulaire : pays absent de la liste des indicatifs
  téléphoniques, « qu'entendez-vous par ijaza ? », mauvaise case cochée sur la mémorisation.

### 2.4 La page d'accueil du candidat (`/attente`)

- Une seule page, **sans barre de navigation** (`app_router.dart:675-760`). Dans l'ordre : entretien
  proche, **annonces (jusqu'à 5, jamais masquables)**, en-tête, état, prochaine action, relire,
  actualiser, partage, autres talents, messages ; en pied : versement, **retrait**, déconnexion
  (`attente_page.dart:190-334`).
- 20 personnes demandent « où en est mon dossier » ; 13 veulent **corriger une réponse après
  l'envoi** (horaires, ville, résidence, nom) et ne le peuvent pas.

### 2.5 Le retrait

- Lien en pied de page, une confirmation, puis **seule la direction peut rouvrir**
  (`portail_candidature.dart:523-697`).
- **20 retraits par les candidats eux-mêmes** ; 7 rouverts par l'équipe (de 2 à 94 heures
  d'attente) ; 13 toujours retirés. 4 personnes ont écrit par courriel « je me suis trompé » ; une
  a créé un second compte avec une autre adresse et reste bloquée. Aucune n'a pu écrire dans
  l'application après son retrait.

### 2.6 Les noms ne correspondent pas (note en arabe du manuscrit)

| Élément | Page des accords | Feuille de complément (direction) | Portail du candidat | Dossier (direction) |
| :--- | :--- | :--- | :--- | :--- |
| Code de conduite | مدونة سلوك المعلم | ميثاق السلوك | ميثاق السلوك | rubrique « الاتفاقات » |
| Contrat | عقدك | عقد المعلم | عقد المعلم, et la ligne « العقد واتفاقاتنا » | « الاتفاقيات موقّعة » |
| Récitation, langues | | تلاوتك / لغاتك | | التلاوة / اللغات |
| Pays de versement | | absent de la liste | بلد الصرف والحساب | |

### 2.7 Saisies du candidat sans sortie dans le dossier

Les 17 réponses du questionnaire s'affichent. Trois saisies manquent au dossier : **le nom en
lettres latines**, **la ville**, et **le téléphone** (caché derrière une feuille de contact).

### 2.8 Ce que les candidats écrivent le plus (messagerie interne, 113 personnes)

1. Versement impossible dans leur pays : 28 personnes (59 messages).
2. Entretien sans créneau : 21 personnes.
3. « Où en est mon dossier » : 20 personnes.
4. Modifier après l'envoi : 13 personnes.
5. Combien gagne un enseignant : 9 personnes.

Fait grave : **des données sensibles sont collées dans le chat** (numéro de compte bancaire, code
de connexion, passeports en image), parce que le chat sert de dépôt de secours quand le dépôt de
pièce échoue.

## 3. Constats : le bureau de la direction

### 3.1 Deux dossiers pour une seule personne

- **Écran A**, le dossier complet avec tous les gestes : `/admin/personnes/candidatures/:reference`.
- **Écran B**, « Fichiers à valider », qui ne sait que valider ou refuser la pièce :
  `/admin/personnes/dossiers`. Aucun lien de B vers A.

| D'où l'on vient | Où l'on arrive |
| :--- | :--- |
| Tableau de bord (un nom, ou le chiffre) | B |
| Comptes, « Ouvrir le dossier » | B |
| Espace de traitement | B |
| Studio, « Aujourd'hui » | B |
| Notification « pièce déposée » | B (la file) |
| Notification « candidature à examiner » | la liste, pas le dossier |
| Recherche de l'en-tête | ne trouve aucune personne (seulement des noms de rubriques) |
| Messagerie, profil | un aperçu **sans aucun geste**, puis A sans « précédent / suivant » |
| Liste des enseignants | A sans « précédent / suivant » |
| Liste des candidatures | A complet |
| Entretiens du jour | A |

C'est la cause exacte de « chaque lien mène à une page différente ».

### 3.2 Le dossier

- **La pièce d'identité s'affiche de deux façons** : la revue complète si la personne est dans la
  file « dossiers en attente », une simple vignette à toucher sinon (`piece_sur_place.dart:117-200`).
  Voilà le « parfois oui, parfois non ».
- **« Admettre » (vers l'entretien) ne vérifie pas la pièce.** « Accueillir » l'exige depuis la
  migration `accueil_separe`, dont l'installation en production n'est pas notée.
- **La dernière utilisation de l'application n'est affichée nulle part.** La donnée existe déjà
  côté serveur (dernière connexion du compte). Lu le 19/11 : 33 candidats se sont connectés dans
  les dernières 24 heures.

### 3.3 La liste

- Filtres nombreux et servis par le serveur, pages de 50. **Pas de tri de l'ancien au récent.**
- Sélection multiple : quatre gestes seulement (pause, lever la pause, refuser, dispenser
  d'entretien), plafond 200. **Ni accepter, ni admettre, ni demander un complément, ni écrire à la
  sélection.**
- Aucun filtre « dossier complet ». Aucun épinglage (rien dans le code).

### 3.4 Le tableau de bord

Cinq tuiles, une section d'alertes, une colonne d'activité, onze raccourcis. La tuile « Dossiers »
mène à l'écran B. Il charge toute la file des dossiers à l'ouverture.

### 3.5 L'en-tête

Six boutons : recherche, Studio, thème, messages, alertes, notifications. **Tous ouvrent une page
entière**, sauf la recherche. **L'icône des messages est retirée quand il n'y a aucun message non
lu** (`app_router.dart:3910-3911`).

### 3.6 La navigation

- **41 entrées** : 7 rubriques et leurs sous-liens (Opérations 9, Personnes 10, Pédagogie 7,
  Finance 6, Configuration 4 ou 5, Sécurité 4).
- Les personnes sont réparties sur **neuf écrans** : Fichiers à valider, Comptes, Candidatures,
  Enseignants, Invitations, Équipe, Demandes d'admission, Import, Espace de traitement.
- **Dans le bureau, le retour mène toujours à l'accueil**, par construction
  (`app_router.dart:3452`, `3890-3893`).
- Un fil d'Ariane existe et se pose seul sur tablette et ordinateur ; il ne compense pas le retour.

### 3.7 La lenteur (causes lues dans le code, non chronométrées)

- La liste des comptes charge **tous les comptes**, sans page.
- La file des dossiers à valider est chargée **en entier**, et **relue en entier pour chaque fiche**.
- **Toutes les conversations** sont lues deux fois, et relues à chaque signal de la messagerie.
- La liste des candidatures numérote tout le résultat filtré et écrit une ligne d'audit à chaque
  lecture.
- La production tournait sur la machine gratuite le 15/11 (R19) : à vérifier.

## 4. Constats : messagerie, annonces, pages secondaires

### 4.1 Messagerie

- **La copie en échec qui reste** : le rapprochement entre la bulle locale et le message du
  serveur se fait **sur le texte**, pas sur la clé d'envoi, et une bulle en échec est toujours
  gardée (`fil_discussion.dart:1797-1822`). Si l'essai « raté » était en réalité arrivé, ou si la
  personne retape son message, les deux restent. Le serveur possède la clé mais ne la rend pas.
- Il n'y a **pas de réessai automatique** : seulement le bouton « Réessayer ».
- **Aucune suppression d'un message envoyé** : un déclencheur du serveur l'interdit.
- **Aucune pagination** : une conversation charge tous ses messages.
- Sécurité déjà en place : stockage privé, liens signés d'une heure, tables fermées, accès par
  fonctions du serveur seulement, mineurs refusés. **Le trou est ailleurs** : des pièces et des
  codes déposés dans le chat y restent, sans rangement ni avertissement.
- Pas d'aperçu de lien, pas de PDF ni de vidéo ; le message vocal est fermé en production.
- **Le profil ouvert depuis une conversation** : nom, pays, situation, pièce, dernier entretien ;
  une seule action, « Voir tout le dossier ». Au téléphone, c'est une feuille qui passe en plein
  écran dès que le contenu déborde.

### 4.2 Annonces

- Composition : un écran, neuf publics (tous, enseignants, candidats, candidats admis, familles,
  élèves, élèves adultes, femmes, hommes). **Ni personnes précises, ni date d'inscription, ni état
  du dossier.**
- Lecture : cinq annonces au plus, marquées vues à l'affichage, **jamais masquables**, gardées 90
  jours. 4 annonces existent en production.

### 4.3 Pages secondaires et navigation

- Un seul composant ouvre toutes les feuilles (`AppBottomSheet`, 157 usages dans 114 fichiers ;
  aucun appel direct ailleurs). **Une correction de ce composant corrige toute l'application.**
- Il **n'a pas de hauteur maximale** : il passe en plein écran quand le contenu déborde. La poignée
  (32 × 4) se retrouve alors sous la barre d'état.
- La navigation emploie « aller » (remplace l'historique) 387 fois, et « pousser » (empile) 66
  fois. C'est la cause probable de « tout ramène à l'accueil » et des allers-retours du glissement.
  À confirmer écran par écran.

## 5. Constats : espace de l'enseignant, icônes, Praxis

- **Accueil de l'enseignant** : quatre blocs fixes (prochaine séance, ma journée, à terminer,
  alertes). **Aucun bloc pour les événements ou annonces de la direction** : ils ne sont visibles
  que derrière la cloche. La règle « quatre blocs, pas un de plus » est écrite en tête du fichier :
  la lever demande une décision du directeur (la voici).
- **Barre du bas** : un seul composant pour tous les rôles (`NavShell`). Hauteur 64, capsule 48,
  cible tactile 48 sans marge autour.
- **Icônes : ce n'est pas un grand chantier.** Toute l'application passe par un seul fichier
  (`lib/core/icons/app_icons.dart`, 165 icônes, 1 380 emplois dans 362 fichiers) et un contrôle
  automatique interdit d'en employer ailleurs. Changer de famille d'icônes, c'est changer ce
  fichier et deux polices. **Les animer est un chantier moyen** : aucun moteur d'animation
  d'icônes n'est installé (ni Lottie ni Rive).
- **Praxis** : le connecteur existe, 14 outils. Il lit la file des candidatures (sans contact,
  pièce ni réponses), prépare trois gestes (demander un complément, planifier l'entretien, admettre)
  que la direction valide à l'écran. **Il ne peut ni étiqueter, ni ranger, ni lire les réponses du
  questionnaire, ni proposer la dispense d'entretien.** Et tout est fermé tant que le réglage
  « données réelles » est faux : la mise en service attend le directeur.

## 6. Les standards retenus (un par problème, pas un de plus)

| Problème | Standard retenu | Ce qu'on en prend |
| :--- | :--- | :--- |
| Lien qui « me connaît » | Lien magique des applications sans mot de passe (Slack, Notion, Linear) | Un toucher : la personne arrive connectée, sur son étape, avec son adresse déjà connue. Jamais de formulaire de connexion après un lien. |
| Choix du type de compte | Écran à deux portes (Airbnb « voyageur / hôte », Uber « passager / chauffeur ») | Première question, deux grandes cartes : « Apprendre » ou « Enseigner ». L'espace porte ensuite son nom en permanence. |
| Formulaire | Une question par écran, langage parlé (Typeform, formulaires GOV.UK) | Trois ou quatre réponses simples d'abord ; le détail seulement si la réponse l'exige. |
| Accueil du candidat | Suivi de dossier (suivi de commande, suivi de demande de visa) | Une ligne d'étapes, un seul « à faire maintenant », le reste rangé derrière une barre de trois onglets. |
| Retrait par erreur | Délai d'annulation (Gmail « Annuler l'envoi », corbeille de 30 jours) | Le retrait se défait seul pendant un délai ; on ne détruit rien tout de suite. |
| Traiter 1 000 dossiers seul | File de tri (Linear Triage, Superhuman) et suivi de candidats (Ashby, Greenhouse) | Une file, un dossier à la fois, le suivant arrive seul après la décision, raccourcis clavier, synthèse en tête, gestes groupés. |
| Un seul dossier | Fiche unique et aperçu latéral (Linear, Notion « aperçu latéral », Stripe) | Une seule fiche par personne ; partout ailleurs, la même carte d'aperçu, qui mène à la fiche. |
| Tableau de bord | Boîte de travail (« ce qui m'attend », pas des statistiques) | Chaque chiffre est une file ; chaque file mène à la liste déjà filtrée. Trois zones, pas plus. |
| En-tête | Fenêtres légères (GitHub, Linear : cloche et boîte en panneau) et palette de commandes (Ctrl+K) | Messages, notifications, annonces : un panneau ancré avec réponse rapide. La recherche trouve des personnes. |
| Sélection en nombre | Gmail (« sélectionner les N résultats »), Airtable | Sélectionner tout le résultat d'un filtre, barre d'actions collée en bas, aperçu avant d'exécuter. |
| Feuilles du bas | Material 3 (feuille à paliers) et Apple HIG (détentes moyenne et grande) | Jamais plus de 90 % de la hauteur, poignée toujours visible, fermeture par glissement, panneau latéral sur ordinateur. |
| Retour et glissement | Navigation en pile (iOS, Android « retour prédictif ») | Un détail s'empile ; le retour revient exactement d'où l'on vient. |
| Messagerie | WhatsApp, Telegram, Signal | Rapprochement par identifiant d'envoi, réessai automatique, « supprimer pour moi / pour tous », chargement par pages, aperçu de lien. |
| Barre du bas | Material 3 « barre de navigation », cibles de 48 points | Barre plus basse, zone tactile qui remplit toute la colonne de l'onglet, sans chevauchement. |
| Icônes animées | Animations courtes au toucher (Lottie, Rive) | Animer une quinzaine d'icônes clés, pas les 165. |

Ces standards sont cités de mémoire ; les recherches web du 19/11 n'ont rendu que des articles
généraux. Ils s'appliquent **sous** les règles déjà gelées du projet : `DESIGN-GOV`,
`DECISION-LISTES`, `DECISION-DEFILEMENT` (la page défile, rien dans un cadre fixe),
`DECISION-FLUIDITE`, `DECISION-MOUVEMENT`.

## 7. Les arbitrages (ce que je tranche, et pourquoi)

**A1. Un seul dossier par personne.** L'écran A reste. L'écran B devient une file de l'écran A
(« Pièces à vérifier »), pas une autre page. Toutes les entrées du §3.1 mènent à A.

**A2. Une seule carte d'aperçu.** Le même composant partout (liste, messagerie, tableau de bord,
notification, recherche) : photo, nom, étape, ce qui manque, pièce vérifiée ou non, dernière
connexion, ancienneté, et les deux ou trois gestes que le serveur ouvre. Un bouton « Ouvrir le
dossier ». Panneau latéral sur ordinateur, feuille à 90 % au téléphone.

**A3. Le bureau tient en trois pages** : **Accueil** (la boîte de travail), **Personnes** (une
seule liste, avec des vues : candidats, enseignants, élèves, familles, équipe, épinglés),
**Messages**. Tout le reste (pédagogie, finance, configuration, sécurité) va dans « Plus ». Rien
n'est supprimé du code sans l'accord du directeur : on retire des entrées du menu, pas des écrans.

**A4. Familles et enfants** : une ligne « famille » qui se déplie sur ses enfants ; chaque
personne (parent ou enfant) garde sa propre fiche, et un parent qui est aussi élève porte les deux
marques sur la même ligne. Détail à écrire avec la liste des élèves (LP-5 à LP-7) ; pas avant la
fin des enseignants.

**A5. Le tableau de bord devient une boîte de travail en trois zones** : « À faire » (files avec
leur nombre : nouveaux, dossiers complets à décider, pièces à vérifier, messages sans réponse,
entretiens du jour, propositions de Praxis) ; « Ce qui a changé » (dix lignes) ; « Santé » (trois
chiffres). Aucun chiffre sans lien ; chaque lien ouvre la liste déjà filtrée.

**A6. L'en-tête** : icônes fixes, jamais retirées (un zéro ne cache rien). Messages,
notifications et annonces s'ouvrent en panneau léger avec réponse rapide ; « Tout voir » mène à la
page. La recherche trouve les personnes (Ctrl+K sur ordinateur).

**A7. Accepter exige une pièce vérifiée**, côté serveur. Admettre à l'entretien ne l'exige pas,
mais la synthèse le dit en clair. À confirmer par le directeur (Q4).

**A8. Le retrait se défait seul pendant 7 jours** (« Reprendre ma candidature »), sans la
direction. Le lien de retrait quitte le pied de la page d'accueil pour la page « Compte ». Après 7
jours, seule la direction rouvre, comme aujourd'hui.

**A9. Le candidat a trois onglets en bas** : **Dossier** (étapes, « à faire maintenant », état),
**Messages** (sa conversation, et les annonces rangées dans un second volet), **Académie**
(partager, autres talents, compte). Une annonce nouvelle apparaît en une ligne fermable en haut de
« Dossier » ; une fois lue ou fermée, elle n'existe plus que dans son volet.

**A10. Juz** : « Tout le Coran », « Rien pour l'instant », ou « Un nombre de juz » avec un
compteur de 1 à 29 et des raccourcis 5, 10, 15, 20. **Riwayat** : « Une seule » (on choisit
laquelle), « Toutes » (les dix lectures), « Les sept lectures », « Quelques-unes » (une grille de
puces rangée par lecteur, deux riwayat par lecteur, avec une recherche). Les anciennes réponses
restent lisibles telles quelles. Les libellés exacts sont à valider (Q3).

**A11. Un seul nom par élément.** Une table unique « code vers nom », lue par le dossier, la
feuille de complément, le portail et la page des accords. Le nom s'écrit de la même façon des deux
côtés ; seul le possessif change, par une règle de la table, pas à la main.

**A12. Modifier après l'envoi** : le candidat corrige seul ce qui ne change pas la décision
(horaires, ville, téléphone), avec une trace visible de la direction ; le reste passe par une
demande. C'est le lot BE-1e (« panier de demandes »), déjà prévu et pas commencé.

**A13. Le chat n'est pas un coffre.** Une image envoyée par un candidat peut être rangée par la
direction en un geste comme « pièce d'identité » (elle part au stockage des pièces et sort du
chat) ; le champ de saisie avertit de ne coller ni code ni numéro de compte ; et le dépôt de pièce
est réparé d'abord, puisque c'est son échec qui pousse les gens vers le chat.

**A14. Supprimer un message** : « pour moi » toujours ; « pour tous » dans l'heure. Le message
supprimé laisse « message supprimé » et reste lisible par la direction dans l'historique du
dossier. Cela demande de lever l'interdiction du serveur par une suppression logique : décision du
directeur (Q5).

**A15. Annonces ciblées = « écrire à cette liste ».** On ne construit pas un second système de
ciblage : on filtre la liste des personnes (date d'inscription, état, complet ou non, épinglés,
sélection à la main), puis « Annoncer à ces N personnes ». Les neuf publics restent comme
raccourcis.

**A16. Icônes** : garder la couche unique. Changer la famille est un lot d'un fichier (à faire
quand le directeur a choisi la famille). Animer : ajouter Lottie, une quinzaine d'icônes (barre du
bas, cloche, envoyer, succès, épingler, recherche). useanimations.com convient ; d'après les
sources lues, ses fichiers gratuits sont sous licence Creative Commons avec mention obligatoire :
à vérifier sur le site avant d'en embarquer un. Autres sources possibles : Lordicon (Lottie,
payant pour l'usage sans mention), Rive (plus léger, mais icônes à dessiner). Ajouter un paquet
touche `pubspec.yaml`, zone protégée : il faut l'ordre du directeur.

**A17. Praxis d'abord en lecture et en rangement.** Avant de lui confier des décisions : il lit
les réponses, range chaque dossier dans une de quatre piles (« complet, prêt à décider », « il
manque quelque chose », « à regarder de près », « sans nouvelles ») avec une phrase de raison, et
propose entretien ou dispense. Le directeur valide par pile, en groupe.

**A18. Performance : mesurer avant de corriger.** Un relevé chronométré des cinq écrans du bureau,
puis les corrections du §3.7 dans l'ordre du gain mesuré.

## 8. L'ordre (une vague à la fois)

| Vague | Contenu | Pourquoi dans cet ordre |
| :--- | :--- | :--- |
| **A. Les blocages d'aujourd'hui** | Courriels dans la langue ; lien qui me connaît ; porte « apprendre / enseigner » ; captcha ; retrait qui se défait ; avis d'ouverture de créneau | Des personnes réelles sont bloquées ou perdues chaque jour. Petits lots. |
| **B. Le parcours du candidat** | Juz et riwayat ; un seul nom ; saisies sans sortie ; accueil à trois onglets ; modifier après l'envoi ; partage | Avant la prochaine vague de 1 000 invitations. |
| **C. Le bureau** | Un seul dossier et la carte d'aperçu ; synthèse ; pièce ; liste (tri, complet, groupé) ; épingler ; tableau de bord ; en-tête ; trois pages ; performance | C'est l'outil du directeur pour 600 dossiers. C1 à C4 d'abord. |
| **D. Les outils** | Messagerie ; annonces ; feuilles ; retour et glissement | D3 et D4 se font tôt : ils corrigent toute l'application d'un coup. |
| **E. L'espace de l'enseignant** | Accueil vivant ; Classes ; barre du bas | Après les références visuelles du directeur. |
| **F. Les icônes** | Famille ; animation | Après le choix du directeur. |
| **G. Praxis** | Lire, ranger, proposer | Après C4 (les files et les gestes groupés qu'il alimente). |

Deux lots transverses passent en premier dans leur vague parce qu'ils corrigent tout d'un coup :
**PE-D3** (le composant des feuilles) et **PE-E3** (la barre du bas).

## 9. Questions au directeur (un lot qui en dépend ne démarre pas sans réponse)

- **Q1.** Les 20 comptes au rôle famille qui portent une candidature d'enseignant, et les 20
  demandes « élève adulte / famille » : voulez-vous un geste « Ce compte est un candidat
  enseignant » dans le bureau, pour les basculer un par un après vérification ?
- **Q2.** Le nom officiel en arabe du code de conduite : « ميثاق المعلم » (votre manuscrit),
  « مدونة سلوك المعلم » (page des accords) ou « ميثاق السلوك » (listes) ? Et le contrat : « عقد
  المعلم » ?
- **Q3.** Riwayat : « Toutes » veut-il dire les dix lectures (vingt riwayat), et faut-il aussi la
  réponse « Les sept lectures » ? Juz : un nombre exact de 1 à 29, cela vous convient-il ?
- **Q4.** Accepter sans pièce vérifiée : interdit pour « Accueillir » seulement, ou aussi pour
  « Admettre à l'entretien » ?
- **Q5.** Supprimer un message : « pour tous » pendant une heure, avec une trace gardée pour la
  direction : d'accord ?
- **Q6.** Retrait : 7 jours pour se rétracter seul, cela vous convient-il ?
- **Q7.** Icônes : quelle famille pour les icônes fixes, et m'autorisez-vous à ajouter le paquet
  Lottie (`pubspec.yaml`) ?
- **Q8.** Les références visuelles annoncées : cartes de partage, cartes des Classes, accueil de
  l'enseignant, tableau de bord. Les lots PE-B6, PE-E1, PE-E2 les attendent.
- **Q9.** Fluidité (§10) : m'autorisez-vous à essayer la construction « WebAssembly » de
  l'application sur un aperçu, et voulez-vous, pour les téléphones, une vraie application Android
  (puis iPhone) faite du même code ?

## 10. Fluidité et éclairs visuels (ajout du directeur, 19/11, même jour)

Demande : « la performance est nulle » ; « qu'est-ce qui empêche mon app d'avoir de la fluidité
comme WhatsApp ? » ; « des glitchs qui s'affichent en moins de 20 ms […] une ligne qui se déforme,
ultra rapide », en quittant la messagerie ou un dossier dans le bureau, et plusieurs fois pendant
un cours. Et : **ne pas retravailler l'espace de l'élève maintenant** ; il viendra après.

### 10.1 Ce qui est prouvé, et ce qui ne l'est pas

**Rien n'est mesuré.** Depuis cette session, l'adresse de production n'est pas joignable : ni le
poids des fichiers servis, ni le temps de chargement, ni le nombre d'images par seconde ne sont
lus. Ce qui suit est lu dans le code.

| Fait lu dans le code | Conséquence |
| :--- | :--- |
| L'application est une **application Flutter construite pour le navigateur**, dessinée par le moteur CanvasKit (`web/flutter_bootstrap.js`, `flutter build web --release` sans option). | Chaque écran est **peint image par image dans une toile**, par un moteur graphique téléchargé avec la page. Le navigateur ne fait ni le défilement, ni le texte, ni les images à sa façon rapide. WhatsApp est une application **native** : le téléphone dessine lui-même, avec ses composants. **C'est la première cause de l'écart, et aucun réglage ne la supprime entièrement.** |
| La construction est en JavaScript, pas en WebAssembly (pas d'option `--wasm`). | Le mode WebAssembly de Flutter est plus rapide à l'exécution et dessine sur un fil séparé. Non essayé ici. |
| **1 700 fichiers de code, 4 seulement chargés à la demande.** | Presque toute l'application (les quatre rôles, le bureau, la salle) est téléchargée et démarrée d'un bloc, même pour un candidat qui ne verra que trois écrans. |
| 2,8 Mo de polices, dont deux polices d'icônes de près de 0,5 Mo chacune et la police arabe de 0,8 Mo. | Poids du premier chargement. |
| Les textes des trois langues font 53 000 lignes. | À vérifier : une seule langue doit être chargée à la fois (`A-FAIRE-LANGUES.md`). |
| 64 emplois d'un canal en temps réel et 27 minuteries répétées dans le code. | Des écrans se redessinent sans que l'utilisateur ait rien fait. À mesurer. |
| Des listes entières sont lues d'un coup (§3.7) et toutes les conversations sont relues à chaque signal. | L'écran attend le réseau, puis reconstruit tout : c'est le « ça bloque, puis plusieurs blocs passent d'un coup ». |
| Une conversation charge tous ses messages (§4.1). | Lenteur qui grandit avec l'usage. |

### 10.2 L'éclair d'une ligne déformée

**Cause inconnue.** Trois pistes, à départager par un enregistrement d'écran image par image :

1. Une image intermédiaire pendant le changement de page : l'ancienne page se retire pendant que
   la nouvelle n'a pas encore sa mise en page (fréquent quand on « remplace » une page au lieu de
   l'empiler, §4.3).
2. Un panneau (liste et détail côte à côte) dont la largeur passe par zéro pendant une image.
3. Une image de la toile graphique non terminée, propre au moteur dans le navigateur ; elle
   toucherait alors aussi la salle de cours, ce que le directeur a vu le 19/11.

### 10.3 Ce que je propose, dans l'ordre

1. **PE-P1, mesurer.** Sur le téléphone, la tablette et l'ordinateur du directeur : temps jusqu'au
   premier écran, temps d'ouverture de cinq écrans, images par seconde au défilement d'une liste,
   poids téléchargé. Un tableau, une page. Sans cela, on corrige à l'aveugle.
2. **PE-P2, filmer l'éclair.** Enregistrement à 60 images par seconde des deux gestes cités
   (quitter la messagerie, quitter un dossier), puis lecture image par image.
3. **PE-P3, les gains sans risque.** Pages et lectures uniques côté bureau (PE-C9), conversation
   par pages (PE-D1), chargement à la demande par rôle (un candidat ne télécharge pas le bureau),
   polices d'icônes réduites aux 165 icônes employées.
4. **PE-P4, essayer WebAssembly** sur un aperçu, et comparer avec la mesure de PE-P1.
5. **PE-P5, la vraie application pour téléphone (décision du directeur).** Le même code Flutter
   peut produire une application Android et iPhone installée, dessinée par le téléphone, bien plus
   fluide que la version navigateur. C'est le seul chemin vers une fluidité « comme WhatsApp » sur
   téléphone. C'est une décision d'architecture et de distribution (boutiques, comptes
   développeur, mises à jour) : à trancher par le directeur, pas à lancer par un agent.

## 11. Les noms des éléments, pour chercher des références

Demande du directeur (19/11) : « je veux toute la liste dans les standards UX/UI, pour que je
puisse chercher des références ». Chaque ligne donne le nom français, le nom à taper en anglais
(c'est en anglais que les sites de références répondent le mieux), et où l'élément sert chez nous.

Où chercher : **Mobbin** (captures d'applications réelles, par élément), **Page Flows** (parcours
filmés), **Refero**, **Dribbble** et **Behance** (maquettes), **Material Design 3** et **Apple
Human Interface Guidelines** (les règles), **Godly** et **Land-book** (sites).
Formule de recherche : `<nom anglais> mobile app UI 2026`, ou `<nom anglais> dashboard UI`.

### 11.1 Entrée et parcours du candidat

| Français | À chercher en anglais | Chez nous |
| :--- | :--- | :--- |
| Courriel de service | transactional email design, magic link email | L'invitation, le lien de connexion |
| Arrivée par un lien personnel | magic link sign in, passwordless login, invite landing page | L'écran après le toucher du lien |
| Choix du type de compte | role selection screen, account type picker, onboarding fork | « Apprendre » ou « Enseigner » |
| Accueil de bienvenue | welcome screen, onboarding flow | Première visite |
| Formulaire en étapes | multi-step form, wizard, stepper, one question per screen (Typeform style) | La candidature |
| Barre d'avancement | progress bar, step indicator, progress stepper | « Étape 2 sur 3 » |
| Cartes de choix | choice cards, selectable cards, radio cards | Juz, riwayat (réponse simple) |
| Puces à cocher | chips, filter chips, multi-select chips, tag picker | Grille des riwayat |
| Compteur | number stepper, quantity picker, wheel picker | Nombre de juz |
| Dépôt de fichier | file upload UI, document upload, ID verification flow (KYC) | La pièce d'identité |
| Signature d'un accord | terms acceptance screen, e-signature flow, consent screen | Contrat, code de conduite |
| Suivi de dossier | application status tracker, order tracking timeline, status timeline | L'état du dossier |
| Carte « à faire maintenant » | next best action card, task card, call to action card | La prochaine action |
| État vide | empty state | « Rien à faire pour l'instant » |
| Carte à partager | share card, referral card, invite friends screen, share sheet | Partager l'académie |
| Confirmation d'un geste grave | destructive action confirmation, confirm dialog, undo snackbar | Le retrait |

### 11.2 Navigation

| Français | À chercher en anglais | Chez nous |
| :--- | :--- | :--- |
| Barre du bas | bottom navigation bar, tab bar, floating tab bar, pill navigation | Candidat, enseignant |
| Capsule de l'onglet actif | active indicator, pill indicator, navigation indicator | La goutte de la barre |
| Menu latéral | sidebar navigation, navigation rail, collapsible sidebar | Le bureau sur ordinateur |
| Menu « hamburger » et tiroir | hamburger menu, navigation drawer | Le bureau au téléphone |
| En-tête | top app bar, header, toolbar | Les boutons du haut |
| Fil d'Ariane | breadcrumbs | Ordinateur et tablette |
| Onglets | tabs, segmented control | Vues d'une liste |
| Palette de commandes | command palette, command menu (Cmd+K), spotlight search | La recherche du bureau |
| Retour par glissement | swipe back gesture, predictive back | Tout le téléphone |
| Liste et détail côte à côte | list-detail layout, master-detail, split view | Messages, dossiers |

### 11.3 Fenêtres et pages secondaires

| Français | À chercher en anglais | Chez nous |
| :--- | :--- | :--- |
| Feuille du bas | bottom sheet, modal bottom sheet, sheet with detents | Filtres, gestes, profil |
| Poignée de la feuille | drag handle, grabber | Fermer en glissant |
| Fenêtre modale | modal dialog, dialog | Confirmations |
| Panneau latéral | side panel, side sheet, drawer panel, slide-over | Un geste sur ordinateur |
| Aperçu latéral | side peek, preview panel, quick view | La carte d'aperçu d'un candidat |
| Fenêtre contextuelle ancrée | popover, dropdown panel, flyout | Messages et notifications de l'en-tête |
| Menu contextuel | context menu, overflow menu, kebab menu, action menu | Le « … » d'une ligne |
| Liste d'actions | action sheet | Gestes au téléphone |
| Infobulle | tooltip | Ordinateur |
| Message bref en bas | snackbar, toast | « Envoyé », « Annuler » |
| Bandeau | banner, inline alert, announcement bar | Annonce en une ligne |
| Visionneuse | lightbox, image viewer, document viewer | La pièce d'identité |

### 11.4 Le bureau de la direction

| Français | À chercher en anglais | Chez nous |
| :--- | :--- | :--- |
| Tableau de bord | admin dashboard, home dashboard, bento grid dashboard | L'accueil du bureau |
| Boîte de travail | inbox, triage inbox, work queue, task inbox | « À faire » |
| Tuile de chiffre | KPI card, stat card, metric tile | Les compteurs |
| Fil d'activité | activity feed, audit log timeline | « Ce qui a changé » |
| Liste de données | data table, data grid, list view | Les personnes |
| Barre de filtres | filter bar, filter chips, faceted filters, filter panel | Les filtres |
| Tri | sort menu, sort dropdown | Ancien vers récent |
| Vues enregistrées | saved views, saved filters, segments | « Dossiers complets » |
| Sélection en nombre | bulk actions, multi-select, bulk action bar, select all | Agir sur plusieurs |
| Fiche d'une personne | profile page, record page, detail page, candidate profile | Le dossier |
| Bandeau de synthèse | summary header, profile header, record header | La synthèse en haut |
| Liste de contrôle | checklist, completeness checklist, progress checklist | Ce qui manque au dossier |
| Pastille d'état | status badge, status pill, tag | « Complet », « À vérifier » |
| Ligne du temps | timeline, activity history | L'historique du dossier |
| Suivi de candidats | applicant tracking system (ATS), candidate pipeline, kanban board | Le recrutement entier |
| File de revue | review queue, approval queue, moderation queue | Un dossier après l'autre |
| Précédent et suivant | record pagination, next/previous record | Passer au dossier suivant |
| Épingler | pin, favorite, bookmark, starred, shortlist | Les profils épinglés |
| Ligne qui se déplie | expandable row, nested table, tree table, accordion | Famille et enfants |
| Avatars groupés | avatar group, avatar stack | Une famille |
| Raccourcis clavier | keyboard shortcuts overlay | Ordinateur |

### 11.5 Messagerie et annonces

| Français | À chercher en anglais | Chez nous |
| :--- | :--- | :--- |
| Liste des conversations | chat list, conversation list, inbox list | Messages |
| Conversation | chat screen, message thread, chat bubbles | Le fil |
| Zone de saisie | message composer, chat input bar | Écrire |
| Réponse rapide | quick reply, inline reply, reply from notification | Répondre sans ouvrir la page |
| Modèles de réponse | canned responses, saved replies, message templates | Réponses types |
| État d'un message | message status, delivery receipts, failed message retry | Envoyé, lu, en échec |
| Actions sur un message | message actions, long press menu, reactions | Supprimer, copier |
| Aperçu de lien | link preview, rich link, unfurl | Les liens |
| Pièces jointes | attachment picker, media gallery, file message | Images, documents |
| Lecteur audio | voice message player, audio waveform | Messages vocaux |
| Profil dans la conversation | contact info sheet, chat details, profile sheet | Le « i » |
| Centre de notifications | notification center, notification panel, notification dropdown | La cloche |
| Annonces | announcements feed, in-app announcement, changelog, news feed | Les annonces |
| Écrire une annonce | broadcast composer, campaign composer, audience builder | Publier |
| Choix des destinataires | recipient picker, audience segmentation, segment builder | Cibler |
| Carte d'événement | event card, announcement card with thumbnail, story card | Accueil de l'enseignant |

### 11.6 Espace de l'enseignant

| Français | À chercher en anglais | Chez nous |
| :--- | :--- | :--- |
| Accueil vivant | home feed, today screen, dashboard home, bento home | « Aujourd'hui » |
| Carte de cours | class card, session card, upcoming event card, schedule card | La prochaine séance |
| Carrousel | carousel, horizontal card list | Événements |
| Liste des élèves | roster, member list, student list, attendance list | Les élèves d'une Classe |
| Page d'une Classe | class detail page, course page, group page | La fiche de la Classe |
| Bibliothèque | resource library, file library, media library | Les documents |
| Agenda | calendar view, agenda view, week view | L'emploi du temps |

### 11.7 Mouvement, attente, icônes

| Français | À chercher en anglais | Chez nous |
| :--- | :--- | :--- |
| Squelette de chargement | skeleton screen, shimmer loading | L'attente d'un écran |
| Affichage immédiat | optimistic UI | Une action affichée tout de suite |
| Transition de page | page transition, shared element transition, hero animation | Changer de page |
| Petites animations | micro-interactions | Un bouton, un succès |
| Icônes animées | animated icons, Lottie icons, Rive icons, animated tab bar icons | Barre du bas, cloche |
| Familles d'icônes | icon set (Phosphor, Lucide, Tabler, Heroicons, Iconsax, Hugeicons, Solar) | Toutes les icônes |
| Retour tactile | haptic feedback | Le toucher |
| Tirer pour actualiser | pull to refresh | Les listes |
| Défilement sans fin | infinite scroll, pagination | Les longues listes |
| Zone tactile | touch target, hit area | La barre du bas |
