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

## 12. Réponses et ajouts du directeur (19/11/2026, soir)

### 12.1 Décisions (elles ferment des questions du §9)

- **Q2, fermée.** Le nom arabe est **« عقد معلم »**. Le directeur précise sa demande : quand le
  dossier dit qu'il manque quelque chose (ex. « لم يوقع على عقد معلم »), « Demander un complément »
  s'ouvre avec **tous les éléments manquants déjà cochés** (un ou plusieurs, selon ce que le
  système sait) ; la direction décoche ce qu'elle veut. Aujourd'hui, seule la pièce ou la photo
  s'ouvre préselectionnée. Lot PE-C10. Le lot PE-B2 (un seul nom par élément) reste nécessaire.
- **Q3, fermée.** Riwayat, trois réponses : « عندي إجازة في القراءات العشر » ; « عندي إجازة في
  القراءات السبع » ; « عندي بعض القراءات », qui ouvre le choix des lectures maîtrisées. Lot PE-B1.
  (Juz : pas de réponse nouvelle ; la proposition A10 tient.)
- **Q6, expliquée, sans réponse encore.** « 7 jours » = le candidat qui a retiré sa candidature
  par erreur peut l'annuler seul pendant 7 jours.
- **Méthode.** Ce que le directeur doit lire lui est montré sur **une page lisible, dans la
  conversation**, jamais dans un fichier `.md` : « git c'est pour vous les machines ». Les
  documents du dépôt restent la mémoire des agents.
- **Glitch.** Le directeur ne peut pas le filmer (imprévisible). PE-P2 devient : chercher dans le
  code les deux sorties citées et la correction déjà faite ailleurs pour le même défaut.

### 12.2 Nouveaux constats, lus dans le code le 19/11

| Plainte du directeur | Fait lu | Lot |
| :--- | :--- | :--- |
| Le bandeau jaune (« nouveau message », « messages pas en direct ») décale l'écran et fait rater un toucher ; laid, répétitif. | Tous les bandeaux généraux sont des enfants d'une colonne **au-dessus** de l'écran (`lib/app.dart:121-135`) : ils poussent toute la page. « Nouveau message » disparaît en 3 s ; « Messages pas en direct » ne peut pas se fermer (`bandeau_messages_hors_direct.dart`). Composant : `OfflineBanner.message`. | PE-D8 |
| La mise à jour impose de recharger. | `BandeauNouvelleVersion` : « Recharger » sans « plus tard » ni croix, il reste affiché ; vérification toutes les 15 minutes et au retour au premier plan (`lib/core/version/`). Un écran bloquant existe quand un morceau de l'application ne se charge plus (`page_differee.dart`). | PE-D9 |
| Pas de glissement gauche ou droite. | Aucun `Dismissible`, aucune action par glissement, aucun glissement pour répondre ; sur le web, le retour par glissement n'existe pas (`app_transitions.dart:223-241`). Ce n'est pas une limite du langage : ce n'est pas construit. | PE-D10 |
| « Tout sélectionner » au moindre toucher. | Un `SelectionArea` global entoure toute l'application (`selection_racine.dart`, `app.dart:117`). Le réglage qui ouvre le menu sur un simple toucher n'a pas été trouvé : à reproduire. | PE-D11 |
| L'écran du code d'un membre invité montre un instant l'accueil d'un membre de l'équipe. | L'écran est imposé par la redirection du routeur (`redirection.dart:147-158`) ; l'accueil n'est pas construit dessous, et le serveur réserve ses lectures à la direction active. **Aucune donnée n'est exposée d'après le code** ; l'éclair lui-même reste inexpliqué. | PE-P2 |
| Valider la pièce d'un candidat fige le bouton alors que l'action a réussi ; « ça marchait bien avant ». | Non vérifié : à reproduire, puis chercher la régression. | PE-D12 |
| Il faut un rafraîchissement par « tirer vers le bas », partout. | À faire dans le composant de page commun (`PageShell`), une fois. | PE-D12 |

### 12.3 Le langage de mouvement voulu par le directeur

« Des animations et effets élastiques, ressorts, huilé ou liquide […] des rebonds, des choses qui
s'étirent comme de l'élastique, des effets de lumière liquide ». Noms du métier : animation à
ressort (*spring*), rebond avec écrasement et étirement (*squash and stretch*), élastique
(*rubber band*), effet liquide (*gooey*, *metaball*, *liquid*), forme qui se transforme
(*morphing*), reflet (*shimmer*), halo (*glow*). Cela **amende** `DECISION-MOUVEMENT-2026-11-11`
et `DECISION-FLUIDITE` (« on n'anime que l'opacité, la position et l'échelle ») : à écrire comme
décision datée avant tout lot d'animation, avec la contrainte de la fluidité (§10). Lot PE-F3.

### 12.4 Application Android et iPhone : ce que cela veut dire (réponse donnée au directeur)

Pas de migration : même compte, mêmes données, même code ; la version web continue. La personne
installe l'application une fois ; les mises à jour suivent par la boutique. Ordre de grandeur :
quelques semaines pour Android, davantage pour iPhone (compte développeur, validation). Reste une
décision du directeur (Q9).

## 13. Vision « objet vivant » et réponses du directeur sur la page des références (19/11/2026, nuit)

Maquette qui marche, remise au directeur pour confirmation : `maquettes/maquette-vivante.html`
(trois vues : Bureau, Candidat, Atelier ; clair et sombre ; français et arabe). **Non confirmée à
l'heure où ces lignes sont écrites.** Elle est le critère d'acceptation des lots visuels une fois
confirmée. La page des noms à chercher : `maquettes/references-a-chercher.html`.

### 13.1 La vision (citation)

« Une app qui n'est pas un document PDF qu'on feuillette : une app vivante qui interagit avec
nous, au doigt, à la tape, à l'arrivée, au retour, à la sortie, qui marche comme les jeux mais
sans les effets maximalistes. […] comme un objet vivant, réel, qu'on tient dans la main : comment
ça va bouger, interagir, se secouer, se reposer, se réveiller, s'éteindre, tourner. »

Règles tirées de cette vision, appliquées dans la maquette :
1. Tout mouvement part du doigt, dépasse un peu, se pose, puis se tait. Rien ne tourne en boucle.
2. Un élément touché s'enfonce ; relâché, il revient en ressort.
3. Ce qui arrive vient de quelque part (du bouton touché, du bord, du haut) et y retourne.
4. Un changement d'état se voit sur l'objet lui-même (le chiffre tressaute, la ligne s'en va, la
   capsule coule), jamais par un bandeau qui pousse la page.
5. Au repos, l'écran est immobile. Praxis s'endort après vingt secondes sans geste.
6. Mêmes mouvements en clair, en sombre, de gauche à droite et de droite à gauche.

### 13.2 Décisions et précisions du directeur

- **Application dans les boutiques : non pour l'instant** (commission de 15 à 30 % sur chaque
  paiement, non rentable). On essaie la construction WebAssembly de l'application web ; sinon on
  améliore l'existant. PE-P5 est fermé ; PE-P4 passe devant.
- **Retrait : 7 jours d'accord (Q6 fermée)**, à condition que le candidat comprenne par l'écran
  ce qui lui arrive ; jamais de silence.
- **Liquide** : une seule masse abstraite, de forme libre mais bornée, jamais coupée en deux.
- **Coins** : « l'arrondi des rectangles est raté partout dans l'app », pire quand un rectangle
  en contient un autre (barre d'outils de la salle, capsule de la barre du bas). Deux règles à
  appliquer : courbe continue (superellipse), et **rayon intérieur = rayon extérieur − marge**.
  Fait lu : `AppRadius.enfantDe` (`lib/core/theme/app_radius.dart:60-76`) rend « le cran
  inférieur de l'échelle », pas « parent − marge » : c'est la cause des deux arrondis
  incohérents. Lot PE-F4.
- **Sélection de texte** : chez les autres, un appui long et voulu ; chez nous, le moindre
  toucher ouvre « Tout sélectionner », la vraie sélection saute par blocs, et le sens (droite à
  gauche) est inversé, curseur des champs compris. Cause en cours de recherche dans le code.
- **L'éclair** : parfois vert, bleu ou violet, du bas vers le haut, parfois incliné ; vu dans la
  salle sur iPad. L'écran qui s'affiche avant le code d'un membre invité : après la page de
  connexion. Causes en cours de recherche dans le code.
- **Pages secondaires oubliées**, à inclure : le jumelage d'un second appareil pour une famille
  (depuis la connexion et depuis le profil du parent), restée à l'état de téléphone étiré ; le
  code à scanner animé, avec le logo au centre.
- **Animations demandées** : cartes d'action (Classes, en direct), profils des élèves, minutes
  et secondes ; file d'avatars où l'arrivant tape les autres, qui réagissent puis se calment ;
  barres de chargement et jauges à effet d'eau avec leur chiffre.
- **Praxis devient la mascotte de la marque** : il tombe, rebondit, roule ; ses yeux portent les
  émotions (heureux, soucieux, excité, en colère, pleure, rit, honte) ; il suit des yeux le texte
  ou le curseur dans les conversations où il participe. À décider : quand il est visible, quand
  il est déjà là, quand il arrive. **Cela amende `assets/brand/praxis/README.md`** (« ne pas la
  redessiner ») : la version animée est un dessin vectoriel d'après l'image du directeur, à
  valider par lui. Lot PE-F5.
- **Une compétence (skill)** décrira ces animations pour toute l'application et hors d'elle
  (Claude, autres modèles). Lot PE-F6, après confirmation de la maquette.
- **Thèmes** : tout mouvement et toute forme sont décidés pour les thèmes de l'application.
- **Le tableau de bord juge le design** (directeur) : il est la première vue de la maquette.

### 13.3 Qui fait quoi (directeur, 19/11)

Le grand modèle garde : les animations, les effets, la cohérence et la coordination entre
éléments et pages, sous forme de **composants réutilisables dans `lib/core/`**, et tout
l'arbitrage. Les tâches légères vont à un modèle moins coûteux (Opus ou Sonnet). Le champ
d'aujourd'hui reste le parcours de départ ; les composants pour toute l'application viennent
ensuite.

### 13.4 Ce que la maquette ne prouve pas

Elle est écrite en HTML. Rien ne prouve encore que les mêmes mouvements tiendront dans Flutter
web sans coût. Règles pour y arriver : n'animer que des transformations et l'opacité, des
ressorts courts qui s'arrêtent, aucun flou animé, aucune boucle, un seul élément en mouvement
long par écran ; mesurer chaque composant avant de le poser partout (PE-P1).

## 14. Causes trouvées dans le code (19/11/2026, nuit)

### 14.1 Sélection de texte (cause prouvée, Flutter 3.47.9 lu) : lot PE-D11

- **Le menu au moindre toucher.** Le `SelectionArea` posé à la racine de l'application
  (`lib/core/widgets/selection_racine.dart`, `lib/app.dart:117`) ajoute une reconnaissance
  d'appui long (500 ms) à **chaque** toucher, boutons compris. Un doigt posé une demi-seconde
  sur un bouton ou avant de défiler ouvre le menu ; sous un texte protégé rien n'est
  sélectionné, donc il ne reste que « Tout sélectionner ». De plus, le nœud de focus est créé
  avec `canRequestFocus: false` (`selection_racine.dart:29-33`) : la zone ne perd jamais le
  focus, donc **une sélection ne s'efface jamais** et suit d'écran en écran ; sur iOS un simple
  toucher sur son emplacement rouvre le menu, sur Android deux touchers rapprochés aussi.
- **La sélection par blocs.** Au doigt, Flutter n'autorise que l'appui long puis le glissement,
  mot par mot, sur une seule zone qui couvre toute l'application ; et tout ce qui se touche est
  exclu de la sélection (`pressable.dart:409`). La sélection saute donc par-dessus les cartes.
- **Le sens inversé.** Dans le SDK, l'ordre des textes d'une ligne est toujours de gauche à
  droite et les poignées sont créées en `TextDirection.ltr`. Pour les champs (très probable) :
  le champ du chat (`fil_discussion.dart:3002`) et la recherche (`champ_recherche.dart:131`) ne
  reçoivent aucun sens ; ils prennent celui de l'interface, pas celui du texte tapé.
- **Correctif** : retirer le `SelectionArea` global et ne le poser qu'autour de ce qui se lit
  (bulles, documents, textes longs) ; donner aux champs le sens du texte tapé
  (`sensDeLaSaisie` existe déjà dans `feuille_carte_classe.dart:50`).

### 14.2 Bouton figé après la validation d'une pièce (hypothèse forte, non prouvée) : lot PE-D12

Les trois chemins de validation relâchent bien leur état. Le plus probable : `DecisionPiece`
(`piece_decision.dart:112`, ajouté par #574 le 17/11) appelle `decider_dossier` **sans délai
maximal** ; si la réponse ne revient pas alors que le serveur a validé, le bouton tourne sans
fin. Avant #574, la pièce passait par `RevueDossier`, qui a un délai et dit « résultat
inconnu » : cela colle avec « ça marchait bien avant ». Correctif : même délai et même phrase
dans `piece_decision.dart` ; remettre `_enCours` à faux dans `feuille_geste.dart:477`.

### 14.3 L'éclair d'une ligne colorée (composant prouvé, mécanisme très probable) : lot PE-P2

- **Qui dessine du vert, du bleu, du violet** : un seul composant, `HaloLumiere`
  (`lib/core/widgets/halo_lumiere.dart`), un dégradé circulaire qui tourne, avec un flou. Vert =
  salle ouverte, bleu et violet = nouveauté, lilas et violet = parole dans la salle
  (`app_palette.dart:1037-1125`). La rotation explique « un peu inclinée ».
- **Quand** : il repart à chaque construction. Dans le bureau, chaque route construit sa propre
  coquille ; en quittant la messagerie ou un dossier, la page d'arrivée naît avec ses lumières
  (tuiles de l'accueil, carte verte des entretiens du jour), qui tournent pendant la transition.
  Dans la salle, le halo de parole se pose sur la vidéo à chaque prise de parole
  (`cadre_visage.dart:251`).
- **Le point commun des trois lieux** : des éléments HTML insérés dans la page. La salle a la
  vidéo ; la messagerie et le dossier ont les images des bulles, rendues en balises `<img>`
  faute d'en-tête CORS sur le stockage (`image_bulle.dart:237`). Le moteur de rendu web doit
  alors découper son dessin en plusieurs toiles superposées, qu'il crée ou redimensionne quand
  ces éléments apparaissent ou partent : pendant une image, on voit l'ancien contenu étiré, un
  trait du halo. Cette dernière étape est une hypothèse sur le moteur, non vérifiée dans le
  moteur lui-même.
- **Correctif** : autoriser CORS sur les lectures du stockage puis retirer le repli en `<img>` ;
  remplacer le halo flou de parole par une bordure fixe sur une tuile vidéo ; ne lancer la
  rotation du halo qu'après la fin de la transition de page. Correction antérieure du même
  défaut : non retrouvée (historique local de 52 commits).

### 14.4 L'écran qui s'affiche avant le code d'un membre invité (prouvé) : lot PE-A9

- Après la connexion d'un compte sans profil, `/inscription` montre deux squelettes, puis
  **construit « Pour qui créez-vous ce compte ? »** (`UsageEtape`, `inscription_page.dart:137`)
  avant de partir vers l'écran du code (`_ouvrirParcours`, l.78-128). C'est l'écran aperçu.
- **Second défaut, plus grave** : l'écran qui s'impose est celui du code **des enseignants**
  (`InvitationCandidatPage`), choisi par la marque gardée dans le navigateur ; l'écran de
  l'associé (`AssociePage`) ne s'ouvre que par un bouton. Le serveur ne connaît pas le rôle
  « associé » dans `mon_invitation_accueil` (`20261122600000_invitation_accueil.sql:263-289`).
  Un code d'associé y est probablement refusé : cela expliquerait « il la passe avec difficulté ».
- Aucune donnée personnelle n'est lue pendant ce laps de temps.
- **Correctif** : garder le squelette jusqu'au choix de la destination ; ajouter le rôle
  « associé » à `mon_invitation_accueil`, avec sa destination ; ne plus envoyer un code
  d'associé vers l'écran des enseignants.

## 15. Flutter sait-il le faire ? Preuve compilée, et retours du directeur sur la maquette (20/11/2026)

Question du directeur : « est-ce que ces effets et styles sont possibles avec Flutter, car je
pense que tu es juste en train de me donner de faux espoirs ».

### 15.1 Ce qui est prouvé, et ce qui ne l'est pas

- **Prouvé** : les mouvements de la maquette existent maintenant en vrai Flutter 3.47.9
  (la version de la CI), compilés pour le web avec le même moteur que l'application (CanvasKit) :
  ressort au toucher, Praxis (dix humeurs, regard, tête qui suit, corde du bonnet, chute et
  écrasement, « non » de la tête, larmes qui éclaboussent, gêne en halo), jauge d'eau en boucle,
  bulle d'une seule masse, file d'avatars qui s'entrechoque, capsule liquide, avis flottant,
  coins à courbe continue (`RoundedSuperellipseBorder`, présent dans le SDK). Source :
  `preuve-flutter/preuve_vivante.dart.txt` (un seul fichier, aucun paquet ajouté). Analyse
  Flutter sans erreur ; lancé dans un navigateur ici, sans erreur.
- **Non prouvé** : la fluidité sur les appareils du directeur. La machine de la session n'a pas
  de carte graphique (33 à 39 images par seconde en rendu logiciel) : ce chiffre ne vaut rien.
  La preuve porte un compteur d'images par seconde pour que le directeur lise le vrai chiffre.
- **Non vérifié** : que la page publiée pour le directeur lance bien le moteur (le lecteur de
  pages peut le bloquer) ; une vidéo du programme en marche l'accompagne.
- **Non prouvé** : la page qui sort d'une icône et y rentre ; le code à scanner avec logo
  réellement lisible ; le redimensionnement des blocs au pincement ; le coût de ces composants
  dans la grande application.
- **Fait utile** : Flutter est maintenant installable dans une session (adresses
  `storage.googleapis.com`, `pub.dev`, `pub.dartlang.org` autorisées par le directeur le 20/11
  dans l'environnement `praxis-routine`). Un agent peut donc compiler et vérifier un lot.

### 15.2 Retours du directeur sur la maquette (28 commentaires, 19/11 au soir)

**Règles générales**
- Aucun émoji dans les interfaces : seulement des icônes ou des images.
- Le violet est interdit directement sur un fond sombre : la lavande le remplace (logo compris).
- La règle des coins (courbe continue, rayon intérieur = rayon extérieur − marge) : « inscris
  cette règle partout ».
- Les signes « + » et « − » mal centrés dans leurs cercles : défaut réel de l'application aussi.
- Chaque élément dit ce qu'il fait au défilement, à l'appui et au survol.

**Tableau de bord** : « l'accueil le plus nul que j'ai connu ». Pas de rectangles uniformes :
des formes différentes, la bulle déformable, parfois une image dans un bloc, « de la vie, pas
que des chiffres qui bougent ». Blocs redimensionnables au pincement et au glisser. Les
interactions avec le panneau latéral manquent. **Le tableau de bord est à refaire.**

**En-tête** : dire comment la recherche se comporte au clic, après un résultat, et quand
d'autres icônes rejoignent l'en-tête ; comment le chiffre d'une icône remue quand un message
tombe ; ce que fait la petite fenêtre des notifications si un événement arrive pendant qu'elle
est ouverte ; avatars dans la liste des messages ; flèche d'envoi au lieu du mot « Envoyer »
(à arbitrer) ; « Ouvrir la messagerie » : la page doit sortir de l'icône et y rentrer à la
fermeture, partout où cela s'applique.

**Candidat**
- L'accueil s'adresse à des gens « pas encore convaincus », venus d'un code scanné sur un mur
  d'université, qui s'attendent à une liste Excel et à des groupes WhatsApp. La barre d'étapes
  est « très ordinaire » : la meilleure interface et une logique qui ne cache rien font « 80 %
  de la confiance ».
- Une ligne du dossier (pièce, contrat) se déplie au toucher : description, exemple si possible.
- Onglet Académie : « Langue » et « Retirer ma candidature » vont dans un réglage. La place sert
  aux informations que les candidats n'ont pas (salaire, détail des cours, organisation des
  entretiens), avec un état d'attente : « s'affichera ici quand la direction le rendra public ».
- Partage : un objet qui dépasse vers le haut, comme posé dans un panier, et qui ressort au
  toucher.
- Messages : en tête de conversation, l'icône de l'académie, pas Praxis ; si Praxis participe,
  il apparaît en premier dans la file ; l'animation du cœur, vue des deux côtés ; l'animation
  quand c'est Praxis qui rédige.

**Praxis**
- « Bienvenue » : ses yeux doivent être contents. La tête bouge à gauche et à droite, la corde
  du bonnet suit, il se contracte avant de rebondir, un œil peut bouger sans l'autre.
- Rire : pas de bouche, donc étirer les joues. Larmes : elles tombent hors du visage et
  éclaboussent. Gêne : un halo dégradé rose, pas des ronds. « Non » : toute la tête, yeux
  compris, quand quelque chose manque (formulaire incomplet). Tous les scénarios sont à proposer.
  Ces points sont repris dans la preuve Flutter.

**Atelier**
- Eau : plus réaliste, couleur de la marque, en boucle. Bulle : aimée, mais où la mettre « pour
  qu'elle fasse vraiment bon effet » ? Code à scanner : l'application doit le générer avec le
  logo et il doit vraiment se lire ; à généraliser aux imprimables et aux factures.

## 16. Le tableau de bord en vrai Flutter (20/11/2026)

Ordre du directeur : « refais le tableau de bord directement en Flutter […] ne fais pas du banal,
surprends-moi ». Puis, en cours de travail : « je n'aime pas les bulles utilisées comme ça sur le
dashboard, je préfère le style familier, mais que tu dois perfectionner et rendre plus
intéressant ; n'ajoute pas de couleurs nouvelles à part celles de l'app ».

**Remis au directeur, non confirmé.** Source : `preuve-flutter/bureau/` (trois fichiers Dart en
`.txt`, sans paquet ajouté ; analyse Flutter sans erreur ; gestes essayés dans un navigateur).
Fluidité sur ses appareils : non prouvée, le compteur d'images par seconde est dans la page.

### 16.1 Ce que contient la maquette

- **Praxis parle** : sa phrase s'écrit, dit le seul blocage du moment, propose la suite en
  pilules ; il change d'humeur à chaque décision.
- **La pile de pièces** : on valide en glissant la carte à droite, on redemande en la glissant à
  gauche ; un tampon apparaît pendant le geste ; « Annuler » la remet sur la pile.
- **Le parcours** : quatre tuiles larges comme leur groupe, remplies comme un niveau d'eau, avec
  les visages des plus anciens ; des points passent d'une tuile à l'autre ; un cadenas marque le
  blocage (aucun créneau). L'ouvrir fait passer les chiffres d'une tuile à l'autre.
- **Les messages** : des bulles de conversation ; la réponse s'ouvre sur place, envoi par flèche.
- **L'en-tête** : la recherche s'élargit ; le chiffre d'une icône roule et l'icône remue quand un
  message tombe ; **la page des messages sort de l'icône et y rentre**.
- **Le volet** d'une tuile (panneau sur ordinateur, feuille au téléphone), la barre latérale qui
  s'ouvre au survol avec sa capsule liquide, la barre du bas au téléphone, clair et sombre.
- Une version « fleuve de bulles » a été écrite puis retirée sur l'avis du directeur.

### 16.2 Règles de style ajoutées par le directeur

- Pas de bulles comme structure d'un tableau de bord : le style familier (tuiles, cartes),
  perfectionné et vivant.
- Aucune couleur hors de la palette de l'application (visages, larmes et illustrations compris).

### 16.3 Installer l'application hors des boutiques (réponse donnée au directeur)

- **Android** : oui. Flutter produit un fichier d'installation (APK) ; on le propose en
  téléchargement sur le site ; la personne autorise une fois « installer des applications
  inconnues ». Vraie application native (pas un site emballé). Pas de commission.
  Mises à jour : pas de boutique, donc l'application doit vérifier elle-même sa version et
  proposer le nouveau fichier ; la personne confirme l'installation à chaque fois.
- **Windows** : oui. Flutter produit une application Windows ; sans certificat de signature
  (payant, annuel), Windows affiche un avertissement à l'installation. Mises à jour : possibles
  automatiquement avec le format d'installation de Windows, à mettre en place.
- **iPhone** : non, hors de l'Union européenne ; l'application web reste la voie.
- **Sans rien construire** : l'application web s'installe déjà depuis Chrome ou Edge (« Installer
  l'application »), sur Android et Windows : icône, fenêtre à elle, mises à jour toutes seules.
- Non fait, non essayé : aucune de ces constructions n'a été lancée. La construction Windows
  demande une machine Windows ; l'Android se construit dans la CI.

### 16.4 Tableau de bord, version 2 : la grille en bento (20/11/2026)

Avis du directeur sur la première version : « il manque toujours l'effet wow. Ici ce ne sont pas
les animations les plus importantes, mais le layout ; j'aime bien des layouts un peu en bento,
mais bien pensés, et non comme mon app actuelle. Les choses swipables sont jolies si tu penses
que ça va marcher. »

Version 2 remise, non confirmée (même source, `preuve-flutter/bureau/`) :
- quatre colonnes sur grand écran, deux sur tablette, une au téléphone ;
- une grande case sombre pour Praxis, assis sur le bord de sa case, avec sa phrase, la semaine
  des entretiens (sept jours vides qui se remplissent quand on ouvre des créneaux) et les gestes ;
- une case haute pour la pile de pièces à glisser ; deux petites cases (messages sans réponse,
  en couleur d'accent ; courriels du jour, case-réservoir) ;
- le parcours : quatre cases larges comme leur groupe, et le versement accroché dessous ;
- deux cases-chiffres (vus en 24 h ; retraits à rouvrir, 13 lus en production) et une case large
  « Ce qui a changé » ;
- règle des cases : coin continu de 34, marge de 18, un enfant arrondi prend 16.

### 16.5 Application Android installable : ce que cela demande (lu dans le dépôt, non essayé)

- Les dossiers `android/`, `ios/`, `windows/` existent déjà dans le dépôt.
- 22 fichiers de `lib/` emploient des fonctions propres au navigateur : à doubler d'une version
  pour téléphone avant qu'une construction Android passe.
- À faire ensuite : autorisations caméra et micro pour la salle, retour du lien de connexion
  vers l'application, notifications, clé de signature, vérification de version et proposition
  du nouveau fichier, page de téléchargement.
- Ordre de grandeur, non prouvé : un premier fichier installable d'essai en quelques jours ; une
  version au niveau de l'application web en deux à trois semaines. Aucune construction lancée.

## 17. Praxis au travail (ordre du directeur, 20/11/2026)

Ordre : « c'est toi le pilote, fais tout pour débloquer et avancer vite ; si c'est possible de
lancer des choses complémentaires en parallèle tu peux le faire. Surtout la stratégie de Praxis,
écrite mais pas appliquée, pour qu'il commence à bosser dans 2 h. Je suis seul dans la direction,
pas d'associé, et des centaines de dossiers. Il doit répondre aux gens, classer les dossiers,
définir des objectifs journaliers ou hebdomadaires, relancer les gens. Quand je valide un dossier
j'écris dans le privé : il doit le faire aussi, avec son profil. »

### 17.1 Ce qui est vrai en production (lu le 20/11 à 01 h 40 UTC)

- Praxis est **allumé et autonome** ; sa routine tourne toutes les heures (tâche planifiée
  « Praxis : routine autonome », minute 24) ; le dernier passage a réussi.
- Il est **enfermé en mode essai** : `essai_fils` = 2 conversations, `donnees_reelles` = faux,
  `envois_par_heure` = 5. Sa boîte ne lui rend que 2 conversations ; `lire` répond « essai ».
  Il ne travaille donc sur aucun vrai dossier.
- La clé « routine » expire le 24/11.

### 17.2 Ce qui a été fait le 20/11

- **Consigne de la routine horaire complétée** (tâche `trig_01BzuKA9RuwF76Z6AwPtDExs`) : une
  étape « les dossiers » : lire les candidatures les plus anciennes et préparer des propositions
  (8 au plus par passage) que la direction valide à l'écran ; lire la liste des outils à chaque
  passage et employer les outils nouveaux d'après leur description. Tous les verrous sont gardés.
- **Point du jour créé** (tâche `trig_01R3KnkfmigCDHNSTkQcJ9he`, chaque jour à 05 h 17 UTC,
  notification sur le téléphone) : lecture seule ; ce que Praxis a fait en 24 h, ce qui attend le
  directeur, les dossiers par étape, trois objectifs du jour, et le lundi l'objectif de la semaine.
- **Chantier serveur PRAXIS-TRAVAIL lancé** (`claude/praxis-travail`, cinquième agent, autorisé
  par l'ordre ci-dessus) : lire ce qui manque à un dossier, ranger en piles, proposer la dispense
  d'entretien, objectifs, relances plafonnées, mot privé après une décision positive. Rien
  d'installé : le pilote relit la migration et l'installe seulement si elle est testée.

### 17.3 Ce qui reste au directeur (trois interrupteurs, à son doigt par construction)

Écran : Sécurité et audit › Accès des agents IA › Praxis (double authentification).
1. Mettre fin à l'essai (vider la liste des conversations d'essai).
2. Ouvrir les données réelles.
3. Monter le plafond de 5 à 30 messages par heure.
Le pilote ne les change pas à sa place : ces réglages sont la clé du directeur sur l'accès d'une
IA aux conversations de vraies personnes, et chaque changement doit porter son nom au journal.

### 17.4 Décisions du directeur enregistrées

- Praxis peut écrire **une fois, en privé**, à un candidat après une décision positive de la
  direction, dans sa conversation existante (amende la règle qui ferme la conversation après la
  confirmation ; il ne crée toujours aucune conversation).
- Praxis relance les candidats sans nouvelles, dans des limites fixées par le serveur.
- Le « chat de la direction » : aujourd'hui, c'est la notification du point du jour et l'écran
  « Questions de Praxis ». Une conversation de direction dans l'application n'existe pas encore.

### 17.5 Praxis doit être un vrai assistant, pas un filtre (directeur, 20/11/2026)

Citation : « s'il se base seulement sur les données basiques, ce n'est pas la peine, car les
filtres savent déjà faire tout ça. Il doit être une vraie IA, poussée à fond, pour trouver les
pépites parmi les pépites ; s'il le faut, ouvrir le dialogue avec eux pour avoir plus de
contexte, sans harceler ni mettre la pression. Il doit se fixer des objectifs lui-même, dans
l'intérêt de la direction : les meilleurs enseignants, les meilleurs programmes, les meilleurs
comportements, les meilleures visions (surtout), les meilleures stratégies. »

Vérité : le lot PX-3 (`claude/praxis-travail`, PR 640) ne donne à Praxis que des codes et des
états, ce que les filtres font déjà. Il ne lit pas les réponses d'un dossier.

Lot lancé : **PX-4 PRAXIS-DOSSIER-COMPLET** (`claude/praxis-dossier-complet`, bâti sur PX-3) :
1. outil `dossier` : toutes les réponses du questionnaire, l'historique, l'état de l'entretien ;
   jamais de contact, de pièce, de photo, de coordonnées de versement, de notes d'entretien ;
2. outil `noter_impression` : étiquette (pépite, solide, à creuser, réserve), cinq critères
   notés (maîtrise, pédagogie, vision, comportement, disponibilité), les faits qui fondent
   l'avis ; jamais une décision ;
3. Praxis peut écrire le premier (question, relance, félicitations après une décision
   positive), dans la conversation de candidature, que le serveur ouvre si elle n'existe pas ;
   limites dans le serveur : une ouverture par personne tous les 7 jours, deux messages de suite
   sans réponse au plus, 25 ouvertures par jour, jamais la nuit, jamais dans les 48 heures qui
   suivent un message de la direction ;
4. `lire` pour chercher les meilleurs (par étiquette, ijaza, riwaya, langue, public).

Décisions du directeur que ce lot applique : Praxis lit les réponses des dossiers ; Praxis
ouvre le dialogue ; Praxis peut ouvrir la conversation de candidature d'une personne qui n'en a
pas. À vérifier avant la mise en service : que le texte publié aux candidats sur l'assistant IA
le permet (sinon le modifier d'abord). Question ouverte : les notes d'entretien restent fermées
à Praxis tant que le directeur n'a pas dit le contraire.

### 17.6 Fin de l'essai et premier passage réel (20/11/2026)

- Le directeur a vidé la liste d'essai et ordonné : « vérifie et lance praxis ». Lu en production
  à 02:13 UTC : données réelles, 35 conversations en attente (34 de candidature, la plus ancienne
  102 h), 50 candidatures lisibles. Routine déclenchée à 02:14 UTC.
- Relevé à 02:16 UTC, passage encore en cours : 19 messages envoyés, 0 refus, 16 conversations
  encore en attente. 6 des 19 réponses disent « je vois avec l'équipe et je reviens ici » : ce sont
  des promesses, à suivre (questions passées à la direction).
- **Non prouvé** : la qualité de ces réponses n'a pas été relue par le directeur. Praxis travaille
  avec ses outils de base ; PX-3 (PR 640) et PX-4 ne sont ni relus ni installés.

### 17.7 Empathie mesurée (directeur, 20/11/2026)

« Il doit avoir une empathie, mesurée mais existante. » À dossier égal, Praxis peut éclairer la
direction avec le contexte de la personne : besoin du travail, risque de connexion, difficulté à
recevoir un versement, nombre de créneaux offerts. Règle retenue : **le contexte éclaire, il ne
juge pas** ; aucun pays n'écarte quelqu'un, aucune accusation, jamais ; la décision reste à la
direction. Porté par le lot PX-4 (champs `besoin`, `risque_connexion`, `risque_versement`).

### 17.8 Empathie élargie, entretien écrit, modèles moins coûteux (directeur, 20/11/2026)

- **Empathie** : les exemples du directeur n'étaient que des exemples (« c'est toi l'IA, creuse les
  scénarios »). Le contexte d'un dossier est une liste ouverte d'éléments (thème, constat, source,
  effet : atout, risque, à vérifier). Thèmes suggérés : besoin du travail, connexion et électricité,
  moyen de recevoir un versement, disponibilité et fuseau, charge de famille ou autre emploi,
  expérience avec les enfants ou les débutants, langues réellement parlées, matériel, constance
  dans les échanges, ton et patience à l'écrit, motivation, ancienneté, ce qu'il apporte de rare.
  Jamais : religion pratiquée, ethnie, santé, opinion, accusation ; le pays n'est qu'un fait de
  contexte, jamais un motif.
- **Entretien écrit** : trop de candidats pour les voir tous en vidéo. Praxis les en dispense et
  leur pose quelques questions simples par écrit, adaptées au dossier, pour dire s'ils peuvent être
  utiles, dans quelle mesure et dans quelle situation. Cinq questions au plus par envoi, une seule
  série ouverte, une seule relance. La dispense et toute décision restent une proposition validée
  par la direction. Porté par PX-4. **Limite à dire** : l'écrit ne prouve ni la récitation ni la
  voix ; la vidéo ou un enregistrement reste à prévoir pour ceux que l'écrit retient.
- **Modèles** : les sous-agents et les routines de Praxis tournent sur un modèle moins coûteux.
  Fait le 20/11 à 02:25 UTC pour les deux routines de Praxis. Les six agents déjà lancés finissent
  sur leur modèle ; tout nouvel agent part sur le modèle moins coûteux.
- Cause du premier passage arrêté à 19 conversations : la consigne lit 20 conversations par
  passage. Les suivantes sont prises au passage horaire suivant.

### 17.9 Praxis décide et prend l'initiative (directeur, 20/11/2026)

« En fait il ne prend pas de décision ni initiative ; donc on ne va pas avancer vite. » Constat
lu en production : en deux passages, 34 réponses dont 13 renvois à la direction, alors que la
plupart de ces 13 questions ont une réponse connue (compétence `repondre-rewayah`).

- **Fait le 20/11 à 02:39 UTC** : consigne de la routine réécrite. Praxis répond seul sur le fond
  (suite de la candidature, entretien, canal, disponibilités, documents, pays et moyen de
  versement, lien de connexion, double candidature) ; il ne passe à la direction que : accepter ou
  refuser une personne, un montant, une banque ou un pays que le serveur ne confirme pas, un nom ou
  un compte, une pièce d'identité, une plainte, une question religieuse ou juridique, un enfant, et
  il joint alors sa proposition de réponse. Il lit 50 conversations par passage, parcourt tous les
  dossiers, et « déjà proposée » n'arrête plus le classement (20 propositions par passage).
- **Pas encore possible, il faut le serveur (lot PX-4)** : appliquer un geste sans attendre la
  direction (réglage `gestes_autonomes`, vide par défaut : admettre aux vérifications, demander un
  complément, entretien écrit, relances ; jamais refuser, accepter définitivement, argent, compte,
  droit) ; relire et fermer ses propres questions ; écrire le premier.
- **Non prouvé** : la nouvelle consigne tourne pour la première fois à 03:24 UTC, sur le modèle
  moins coûteux.
