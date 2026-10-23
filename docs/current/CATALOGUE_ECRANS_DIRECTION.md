# Catalogue des écrans : Direction (Opérations, Sécurité et audit)

Registre des écrans de la direction ajoutés après la remise à plat, au format du
registre général (Code, Écran, Rôle, niveau de charge, profondeur, route, mobile,
bureau, état). Inscrit le 11 octobre 2026 **avant le code** (lot ECRANS-ADMIN-FIN,
étapes DASH-ADM-PLANNING et DASH-ADM-INC, `DASH_STRATEGIE.md` §5, décidé par
délégation le 05/10, DIR-REP-1 et D9).

**État** : présent dans le code et testé localement (`flutter test`, 320 px, texte ×2,
LTR et RTL), frontend seulement. Ni staging ni déploiement. En production chaque port
vaut `null` : la page dit « Disponible au branchement serveur », sans rien inventer ;
la démonstration (hors production) porte les données.

| Code | Écran | Rôle | Niv. | Prof. | Route | Mobile | Desktop | État |
| :--- | :--- | :--- | :-: | :-: | :--- | :--- | :--- | :--- |
| `ADM-PLAN` | Planning de la semaine | Direction | E | 1 | `/admin/operations/planning` | Barre semaine précédente / suivante, un jour par section, lignes fines | Idem, colonne bornée | **construit (11/10)**, port `PortPlanningDirection` (`lib/core/admin/port_planning_direction.dart`), démo `planning_incidents_demo.dart` |
| `ADM-INC` | Incidents des 24 dernières heures | Direction | E | 1 | `/admin/securite-audit/incidents` | Une carte à lignes fines | Idem, colonne bornée | **construit (11/10)**, port `PortIncidentsSeances`, lecture serveur au BR-1 |
| `ADM-PAI` | Paiements reçus | Direction | E | 1 | `/admin/finance/paiements` | Deux sections à lignes fines, fiche en feuille | Idem, fiche en boîte de dialogue | **construit (17/10)**, port `PortPaiementsSaisis`, adaptateur `PaiementsSaisisSupabase` (RPC de FAC-C-01, testées sur la base de test) |
| `ADM-COUR` | E-mails | Direction | E | 1 | `/admin/operations/courriels` | Trois sections (Écrire, Envois, Adresses d'envoi), cartes détachées | Idem, colonne bornée | **construit (23/10)**, port `PortCourriels`, adaptateur `CourrielsSupabase` (RPC de la migration `20261023120000`), démo `CourrielsDemonstration` |

## ADM-PLAN : Planning

- **Tâche** : voir d'un coup d'œil les séances de la semaine, toutes classes confondues.
- **Contenu** : barre `BarrePrecedentSuivant` (« Semaine du lundi 12 octobre 2026 ») et
  lien « Revenir à cette semaine » hors de la semaine en cours ; par jour qui a des
  séances, un `SectionHeader` (date, nombre de séances) et une `CarteLignes` ; chaque
  ligne dit la classe (nom distinct, R16), l'horaire, l'enseignant ou « Sans
  enseignant », et l'état en pastille (jamais la couleur seule ; « En direct » et
  « Annulée » par `PastilleEtatSeance`).
- **Aucune action** : un rapport, aucun bouton grisé, aucun bouton plein.
- **Entrée** : ligne « Planning de la semaine » des raccourcis de l'Accueil (domaine
  Opérations conservé).
- **États** : chargement (`Skeleton.liste`), contenu, vide (« Aucune séance cette
  semaine »), erreur (`EtatSysteme`, « Réessayer »), hors ligne (bandeau de `PageShell` ;
  `EtatSansDonnees` si rien n'a pu être lu), port absent (`CapaciteIndisponible`).
- **Contrat serveur à demander** : lecture des séances dont le début tombe dans une
  semaine (lundi 00 h au lundi suivant), avec nom de la classe, enseignant éventuel,
  début, durée, statut.

## ADM-INC : Incidents des 24 dernières heures

- **Pourquoi pas le Journal** : la tuile « Incidents (24 h) » compte des **séances** au
  statut incident technique, enseignant absent ou élève absent mises à jour depuis 24 h
  (migration 0015), pas des entrées du journal d'audit. Un lien vers le Journal ne
  montrerait pas le chiffre de la tuile (D9). La page liste donc ces séances.
- **Contenu** : une `CarteLignes`, plus récent d'abord ; chaque ligne dit la classe, quand
  l'incident est survenu, l'enseignant ou « Sans enseignant », et sa nature en pastille.
- **Entrée** : le chiffre « Incidents (24 h) » de la tuile double devient un lien ; « Accès
  échus » reste un lien vers Comptes (DASH-ADM-ECHUS).
- **États** : les mêmes cinq que ADM-PLAN.
- **Contrat serveur à demander (BR-1)** : lecture de ces séances sur 24 h, même critère
  que le compteur.

## ADM-PAI : Paiements reçus

Inscrite le 17 octobre 2026 avant le code (passation du 17/10, point 3 ; FAC-C-01,
migration `20261017172000`). Revue d'ergonomie : `UX_REVIEW_ADM-PAI.md`.

- **Tâche** : enregistrer un paiement reçu hors de l'application (virement, espèces),
  attribué à un élève, pour que son mois soit facturé puis réglé.
- **Entrée** : cinquième onglet « Paiements » du domaine Finance.
- **Contenu** : une phrase de contexte ; « À régulariser » (élèves qui doivent quelque
  chose, le plus dû d'abord, montant rendu par le serveur) puis « À jour » ; une
  `CarteLignes` par section, une ligne par élève (nom, matricule, reste à payer ou
  « À jour »). Toucher une ligne ouvre la fiche.
- **Fiche** (K-57) : élève et devise **déduits** de la ligne ; montant **prérempli** avec
  le reste à payer (corrigeable si la famille a payé une autre somme) ; référence
  **saisie**, facultative (seule la personne qui a reçu le virement connaît son numéro).
  Une seule action pleine : « Enregistrer le paiement de {prénom} » ; « Annuler » discret.
- **Issue** (D5, K-59) : celle que rend le serveur, jamais déduite à l'écran. « Le mois de
  {prénom} est réglé », « Il manque encore {montant} », « déjà enregistré : rien n'a été
  ajouté », refus (droits ou valeurs, « rien n'a été enregistré »), ou « Paiement non
  confirmé » avec « Réessayer », qui rejoue la même clé : un paiement n'est jamais compté
  deux fois.
- **États** : chargement (`Skeleton`), contenu, vide (« Aucun élève pour l'instant »),
  erreur (« Réessayer »), hors ligne (la fiche ne propose aucun envoi), source absente
  (« Pas encore disponible »).
- **Droits** (serveur) : direction et comptabilité, compte valide ; lecture de la table
  des saisies réservée aux mêmes.
- **Hors fiche** : l'émission des factures du mois (`emettre_factures_mois`) n'a pas encore
  d'écran ; un paiement saisi facture déjà le mois de l'élève concerné.

## ADM-COUR : E-mails

Inscrite le 23 octobre 2026 avant le code (COURRIELS-1, migration `20261023120000`).
**Placement** : domaine Opérations, atteint depuis l'Accueil comme Avis et Offres ; écrire à une
famille et suivre ce qui part est un geste de pilotage quotidien, pas une règle globale du système
(Configuration ne le porterait que pour le réglage des alias, qui reste en lecture seule ici).

- **Tâche** : écrire un e-mail à une personne, puis vérifier qu'il est bien parti.
- **Entrée** : « E-mails » dans les outils de l'Accueil de la direction.
- **Écrire** : adresse du destinataire, catégorie (cartes de choix fermées, sans « Autre » ; chaque
  carte dit l'adresse d'où part l'e-mail), sujet (1 à 120), message en texte simple (1 à 5000, une
  ligne vide fait un paragraphe). Une seule action pleine : « Envoyer l'e-mail ».
- **Langue** (COURRIELS-2, 23/10) : la direction écrit une seule fois, dans sa langue. Une ligne sous
  l'introduction le dit : « Chaque destinataire le reçoit dans sa langue : le message est traduit
  automatiquement à l'envoi. » La langue de chaque e-mail est fixée par le serveur à la mise en file
  (profil du destinataire, sinon français).
- **Issue** (D5, K-59) : le serveur met l'e-mail en file, la file part dans la minute. L'écran dit
  « Envoi dans la minute » et **jamais « envoyé »** avant que la ligne soit `envoye` dans « Envois ».
  Refus nommés par le serveur (adresse, catégorie, sujet, message, destinataire exclu : compte
  d'enfant ou désinscription), droits, réseau absent (rien ne part), mise en file non confirmée.
  Une clé d'idempotence est tirée par contenu : un double appui ou un nouvel essai ne met jamais deux
  e-mails en file ; elle change dès que le contenu change.
- **Envois** : la file, la plus récente d'abord, filtrée par statut (En file, En cours d'envoi,
  Envoyés, Non envoyés, Annulés), « Actualiser ». Une carte par e-mail (sujet pour un message libre,
  « Message automatique » sinon ; destinataire, catégorie, langue (nom de la langue, ou son code si la
  liste n'est pas lue), origine, dates, essais, dernière erreur).
  « Remettre en file » seulement sur un e-mail non envoyé ou annulé.
- **Adresses d'envoi** : les catégories en lecture seule (adresse d'envoi, nom affiché, adresse des
  réponses, type, active ou coupée). Le réglage (`admin_courriel_categorie_regler`) n'a pas
  d'écran : un alias mal saisi coupe les réponses des familles, il passe par la migration.
- **États** : chargement (`Skeleton`), contenu, vide, erreur (« Réessayer »), hors ligne
  (`EtatSansDonnees`, aucun envoi ne part), source absente (« E-mails indisponibles »).
- **Droits** (serveur) : direction, compte valide. Le destinataire est une adresse libre ; l'envoi à
  un compte par identifiant (`p_profil`) existe côté serveur, sans sélecteur de personne ici.
