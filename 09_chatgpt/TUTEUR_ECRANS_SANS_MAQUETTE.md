# Rôle Tuteur : écrans et états sans maquette high-fi (faits vérifiés)

Date : 24/09/2026. Destinataire : ChatGPT, pour le document `01_TUTEUR_COMPLEMENTS.md` et ses maquettes.
Statut : relevé en lecture seule, aucun fichier du dépôt modifié.

## 0. Comment lire ce document

**Sources** (toutes lues pour ce relevé) :
- `MANIFESTE` = `pilotage-tuteur-v1/01_visuel/00_MANIFESTE.md` (§1 inventaire des maquettes, §2 écrans sans maquette, §5 erreurs, §6 dérivations).
- `V1` à `V9` = rapports détaillés `pilotage-tuteur-v1/01_visuel/V*.md` (une maquette ou un groupe par rapport).
- `MANDAT` = `docs de lancement/REWAYAH_PROMPT_CLAUDE_FRONTEND_TUTEUR_V1.md` (§4 arbre des routes, §5 contenu, §6 admission, §7 appareils, §8 états) ; `MANDAT-OBS` = sa seconde partie « Prompt étape observation tuteur » (§1 à §10).
- `DÉCISIONS` = `pilotage-tuteur-v1/03_DECISIONS_COORDINATEUR.md` (les §1 bis, §1 ter, §1 ter bis sont des réponses du directeur et priment).
- `MAPPING` = `pilotage-tuteur-v1/02_code/00_MAPPING_ROUTES.md` (numéros de ligne de son §3 : « l.n ») ; `C03` = `02_code/C03_admission.md`.
- `LOTS` = `pilotage-tuteur-v1/05_LOTS_PHASE1.md` ; `BACKLOG` = `pilotage-tuteur-v1/08_BACKLOG_VAGUE_CLASSE_VISIO.md`.
- `CODE` = dépôt `D:\RA_TUTEUR\integration`, branche `ui/tuteur-v1`, commit `cefab7f` (fin de la phase 0 : routeur, thème, composants partagés ; les écrans des lots sont encore des écrans réservés marqués « STUB PHASE 0 » dans 40 fichiers de `lib/`).
- `FINANCE` = `RA -OFFICIAL-APP/docs/current/07_MEMOIRE_PEDAGOGIE_FINANCE.md`.

**Conventions** :
- `#n` = numéro de la zone de maquette dans MANIFESTE §1 (33 zones dans 19 fichiers du dossier `docs de lancement/tutuor image/`). Le tableau du §1 ci-dessous les rappelle.
- `SM-nn` = identifiant d'un écran **sans maquette** dans ce document. ChatGPT peut le reprendre ou le remplacer par `TUT-nn`, à condition de garder la correspondance.
- `DB-xxx` = dépendance serveur manquante, recensée dans `02_code/00_DEPENDANCES_BACKEND.md`. En production, l'écran affiche alors l'état « indisponible » (texte existant : « Pas encore disponible » / « Cette fonction n'est pas encore ouverte. », `CODE assets/i18n/fr.i18n.json:56-59`).
- « À vérifier » = fait que je n'ai pas pu prouver.

**Règles du directeur qui s'appliquent à chaque maquette à produire** (DÉCISIONS §1 ter) :
1. Les maquettes font autorité pour la **disposition** (ordre des sections, colonnes, place exacte de chaque bouton et de la route qu'il ouvre), jamais pour la palette. Couleurs et polices viennent du système gelé : DM Sans pour les titres, Plus Jakarta Sans pour tout le reste, palette ajustée listée en DÉCISIONS §3.1.
2. Une fonction = un seul endroit, aucun doublon. Seul raccourci admis : « Créer mon profil élève » depuis Foyer ET Compte, qui ouvre le même flux.
3. Carte groupée = UN seul rectangle, lignes séparées par un filet fin en retrait. Jamais un rectangle par ligne.
4. Barre de navigation, retour visible sur chaque écran de niveau 2 et chaque tâche focalisée, déconnexion accessible sur tous les formats. Aucune impasse.
5. Web = vraie version ordinateur (rail dès 600 dp, barre latérale dès 1200 dp), jamais le mobile étiré.
6. Captures de recette exigées : **390 × 844 et 1440 × 900, clair ET sombre** pour chaque écran (LOTS §0).
7. Navigation tuteur : **Accueil · Foyer · Historique · Compte**, même ordre partout (DÉCISIONS §3.6).

---

## 1. Rappel : les maquettes qui existent déjà (ne pas les redessiner)

| # | Fichier | Écran réel | Thème | Format | Route retenue (CODE) |
|---|---|---|---|---|---|
| 1 | `acceuil tuteur desktop light.png` | Accueil | Clair | Ordinateur ≈ 1440 | `/tuteur` |
| 2 | `acceuil tuteur desktop dark.png` (moitié gauche) | Accueil, rail replié | Sombre | Tablette ≈ 690 | `/tuteur` |
| 3 | `acceuil tuteur desktop dark.png` (moitié droite) | Accueil, rail déplié | Sombre | Ordinateur étroit ≈ 1100 | `/tuteur` |
| 4 | `mobile/accueil  tuteur mobile light mode.png` | Accueil | Clair | Mobile | `/tuteur` |
| 5 | `mon compte tuteur desktop light mode.png` | Mon compte | Clair | Ordinateur | `/tuteur/compte` |
| 6 | `mobile/mon compte tuteur mobile light mode.png` | Mon compte | Clair | Mobile | `/tuteur/compte` |
| 7 | `mobile/mon compte tuteur desktop dark mode.png` | Mon compte (nom de fichier faux : c'est un MOBILE) | Sombre | Mobile | `/tuteur/compte` |
| 8 | `réglages tutor mobile dark mode.png` (écran 01) | Réglages (hub des préférences du titulaire) | Sombre | Mobile | `/tuteur/compte/preferences` |
| 9 | idem (écran 02) | Apparence | Sombre | Mobile | `/tuteur/compte/preferences/apparence` |
| 10 | `onboarding Mble.png` | Choix d'usage | Sombre | Mobile | `/inscription/usage` |
| 11 | `onboarding Mble d.png` | Genre (« d » ne veut pas dire dark) | Sombre | Mobile | `/inscription/genre` |
| 12 | `onboarding mobile 1.png` E1 | Choix d'usage (autre version) | Sombre | Mobile | `/inscription/usage` |
| 13 | idem E2 | Genre | Sombre | Mobile | `/inscription/genre` |
| 14 | idem E3 | Âge (champ libre) | Sombre | Mobile | questionnaire `/tuteur/parcours/:eleveId` |
| 15 | `Onboarding mobile 2.png` E4 | Langue de l'application | Sombre | Mobile | relève de `/tuteur/compte/preferences`, pas de l'admission |
| 16 | idem E5 | Objectif | Sombre | Mobile | questionnaire `/tuteur/parcours/:eleveId` |
| 17 | idem E6 | Récapitulatif « Tout commence ici. » | Sombre | Mobile | `/inscription/recapitulatif` |
| 18 | `mobile/tuteur observation mobile light.png` M1 | Classe de l'enfant + bloc Observation | Clair | Mobile | `/tuteur/classes/:classeId` |
| 19 | idem M2 | Explication de première utilisation | Clair | Mobile | `/tc/observation/:seanceId` (étape avant « Entrer ») |
| 20 | idem M3 | Salle d'observation, visite 1/2 | **Sombre** | Mobile | `/tc/observation/:seanceId` |
| 21 | idem M4 | Salle d'observation, visite 2/2 | Clair | Mobile | `/tc/observation/:seanceId` |
| 22 | idem M5 | Fin de visite (écran résultat) | Clair | Mobile | retour `/tuteur/classes/:classeId` |
| 23 | idem M6 | Consentement « Les visites des parents » | Clair | Mobile | `/attente/contrat` et `/tuteur/compte/consentements` |
| 24 | `tuteur observation desktop light.png` D1 | Salle d'observation | Clair | Ordinateur | `/tc/observation/:seanceId` |
| 25 | idem D2 | Historique, segment Observations | **Sombre** | **Mobile** | `/tuteur/suivi/observations` |
| 26 | idem D3 | Historique des observations, ADMINISTRATION | Clair | Ordinateur | `/admin/securite-audit/observations` (hors rôle tuteur) |
| 27 | idem D4 | Détail d'une observation | Clair | **Mobile** | `/tuteur/seances/:seanceId/observations?eleve=` |
| 28 | `tutor observation map.png` | Logigramme du parcours Observation | - | - | aucune (planche de direction, aucune valeur visuelle réutilisable) |
| 29 | `mobile/Accueil.png` | ANCIENNE capture de l'Accueil (remplacée par #4) | Sombre | Mobile | contenu seulement |
| 30 | `mobile/Foyer Member.png` | ANCIENNE capture du Foyer | Sombre | Mobile | contenu seulement |
| 31 | `mobile/Historique.png` | ANCIENNE capture de l'Historique des séances | Sombre | Mobile | contenu seulement |
| 32 | `mobile/Classe Details.png` | ANCIENNE capture de la Classe | Sombre | Mobile | contenu seulement |
| 33 | `mobile/Profil.png` | ANCIENNE capture de la FICHE ÉLÈVE (pas le compte) | Sombre | Mobile | contenu seulement |

Sources : MANIFESTE §1 ; routes vérifiées dans `CODE lib/core/router/routes.dart` (lignes citées plus bas) ; route du détail d'observation tranchée en DÉCISIONS §3.9.

Les anciennes captures #29 à #33 ne servent qu'au **contenu et à l'ordre** des informations, jamais au rendu (MANDAT §2).

---

## 2. Écrans du rôle Tuteur sans AUCUNE maquette high-fi

Pour chaque écran : route exacte (constante du CODE), contenu attendu (MANDAT §4-§8 et MANDAT-OBS), états à dessiner, maquette la plus proche à imiter (MANIFESTE §2, MAPPING §7.2). Les états système communs (chargement, hors ligne, échec, etc.) sont détaillés une seule fois au §2.8 et s'appliquent à tous les écrans.

### 2.1 Public et admission

| Id | Route (CODE `routes.dart`) | Écran | Contenu attendu | États à dessiner | Maquette la plus proche |
|---|---|---|---|---|---|
| SM-01 | `/bienvenue` (`:35`) | Bienvenue | Titre, sous-titre, CTA « Commencer », lien secondaire « J'ai déjà un compte ». Les deux mènent à `/connexion` : c'est le lien envoyé par courriel qui crée le compte, pas de double création (MAPPING l.1). Remplace l'écran actuel qui affiche « Écran à construire ». | Nominal ; chargement prolongé | #17 (colonne centrée) + #22 (CTA ancré en bas, lien secondaire) |
| SM-02 | `/` (`app_router.dart:156-159`, `EcranDemarrage`) | Démarrage neutre | Écran affiché le temps de vérifier la session. Aucun texte de chantier. | Attente ; attente prolongée ; hors ligne au démarrage (texte existant : « Rewayah a besoin d'Internet pour vérifier votre compte. Reconnectez cet appareil, puis réessayez. », `fr.i18n.json:61`) | #22 |
| SM-03 | `/connexion` (`:15`) | Connexion | En production : **lien de connexion à usage unique par courriel** et **Google** seulement ; le mot de passe n'existe qu'en démonstration locale (`CODE lib/core/auth/service_auth.dart:12-24`). « Renvoyer le lien », état « lien expiré ou déjà utilisé », lien discret « accès appareil élève » vers `/connexion/eleve` (MAPPING l.2). | Saisie ; envoi en cours ; lien envoyé (attente) ; lien expiré ou déjà utilisé ; erreur sous le champ ; échec Google | #14 (champ encadré à étiquette, erreur sous le champ, CTA ancré) |
| SM-04 | `/connexion/recuperation` (`:32`) | Récupérer mon accès | Récupérer = redemander un lien (pas de mot de passe en production). | Saisie ; attente ; retour ; lien expiré ; erreur | #14 + #22 |
| SM-05 | `/inscription/identite` (`:49`) | Identité du titulaire | Texte existant : « Comment vous appelez-vous ? » ; « Ce nom doit être celui de votre pièce d'identité. » ; champs « Prénom », « Nom » (C03 §3.2). Préremplir ce que Google fournit déjà (MANDAT §6 « ne pas redemander sans raison » ; aujourd'hui rien n'est prérempli). | Vide (CTA désactivé) ; erreur sous chaque champ ; rempli | #14 : deux champs empilés, écart 12 dp |
| SM-06 | `/attente` (`:58`) | Portail du dossier | Quatre états calculés par le serveur : incomplet, en vérification, refusé (avec motif serveur), suspendu (C03 §3.3). Afficher le statut exact et **une seule** prochaine action. « Se déconnecter » accessible. Interdit : cartes empilées et jusqu'à 3 CTA pleins (MAPPING l.7 ; MANDAT §4 : « trop de CTA et trop de rectangles… à bannir »). « Contacter l'académie » reste non actionnable tant que DB-CPT-07 manque. | Incomplet (liste des pièces manquantes dans l'ordre accusé, contrat, pièce) ; en vérification ; refusé ; suspendu | #17 + #22 |
| SM-07 | `/attente/accuse` (`:64`) | À savoir avant de commencer | Deux points : notice d'enregistrement et notice de contrôle. **L'enregistrement audio est réel** : garder mot pour mot les clés `contrat.pointEnregistrement` et `salle.bandeauPermanent` = « Cours enregistré, visite de contrôle possible. » (DÉCISIONS §1 bis-2). Action « J'ai compris ». | Nominal ; envoi ; erreur | #23 (lignes icône + texte, CTA) |
| SM-08 | `/attente/contrat` (`:67`) | Ce que vous signez | Nouvelle version du texte signé = texte existant (notice d'enregistrement comprise) + paragraphe d'observation clair et bienveillant : qui peut observer, ce qu'il entend et voit, ce qu'il ne peut pas faire, pourquoi, limites de visites. Variantes « responsable légal » et « élève adulte ». Case **non précochée** (DÉCISIONS §1 bis-3 ; MANDAT-OBS §6). Seule la partie observation a une maquette (#23), avec un texte à corriger (voir §6). | Case non cochée (CTA désactivé) ; cochée ; envoi ; erreur ; variante responsable légal ; variante élève adulte | #23 |
| SM-09 | `/attente/piece` (`:70`) | Votre pièce d'identité | Choix du type (Carte d'identité, Passeport, Titre de séjour, Autre), « Choisir la photo », aperçu, « Envoyer ma pièce », plafond 8 Mo vérifié avant envoi (C03 §3.3). Jamais confondue avec le portrait de l'élève. | Aucun fichier ; aperçu ; envoi avec progression ; fichier trop lourd ; échec avec reprise ; envoyé | Cartes de choix #12 + champ #14 |
| SM-10 | `/tuteur/parcours/:eleveId` (`:159-165`) | Questionnaire pédagogique, par élève nommé | Sept étapes existantes (C03 §3.5), prénom de l'élève dans chaque question : 1) âge par **tranche** fournie par le serveur ; 2) langue **du cours** (pas celle de l'application) ; 3) lieu, pour l'heure locale ; 4) niveau (« Où en est {prénom} aujourd'hui ? », 5 réponses) ; 5) objectif ; 6) moments de la journée ; 7) horaires ou classes proposés. Branches débutant / non-débutant selon les règles rendues par le serveur, aucun code interne (MANDAT §6). En production le serveur de ce questionnaire n'est pas déployé : état indisponible honnête (MAPPING l.6, DB-ADM-01). | Chaque étape vide / remplie / erreur ; « n sur N » calculé selon la branche ; reprise ; indisponible ; aucune proposition compatible (« Aucun horaire ouvert ne correspond encore », avec « Me prévenir si de nouveaux horaires ouvrent ») | Étapes 1 et 5 : #14 et #16 existent mais sont en conflit (voir §6) ; étapes 2, 3, 4, 6, 7 : lignes de choix #15 / #16 |

Remarques admission :
- CONFLIT à ne pas trancher en silence : le high-fi #14 demande un âge exact (« 28 ans ») alors que le code propose des tranches serveur et que MANDAT §6 parle de cohortes 6-9, 10-13, 14-17, 18+ et de date de naissance (C03 §3.5, V6 E3, MANIFESTE §5 C13).
- CONFLIT : étape 7, classe réelle ou « offre horaire » (DÉCISIONS §2 P1 : défaut retenu « vraies classes », à confirmer par le directeur).
- La langue de l'application (#15) n'est pas une étape d'admission : elle relève des préférences (MANIFESTE §5 C14).

### 2.2 Accueil et Classe

| Id | Route (CODE) | Écran | Contenu attendu | États à dessiner | Maquette la plus proche |
|---|---|---|---|---|---|
| SM-11 | `/tuteur/notifications` (`:260`) | Notifications | Liste, détail, destination liée (MANDAT §4). Aucune source de notifications n'existe : en production, écran indisponible et **cloche sans pastille** (MAPPING l.9, DB-CPT-04). Pas de route de détail tant que la source manque (MAPPING §7.1). | Indisponible ; vide ; liste (non lues / lues) ; chargement ; erreur | Lignes de #25 + en-tête de #1 / #4 |
| SM-12 | `/tuteur/classes/catalogue?eleve=` (`:204`) | Choisir une classe | Une carte par classe : parcours, public ou niveau, langue, enseignant avec photo et Sayyid / Sayyida, **toutes** les séances de la semaine, durée, fuseau, places réelles. Confirmer la même classe et le même enseignant sur toute la semaine. Aucune réservation locale (MANDAT §5 Classe). En production : « le choix de classe en ligne n'est pas encore ouvert » (DÉCISIONS §2 P1). | Liste ; aucune classe compatible ; liste d'attente ; dernière place perdue ; confirmation refusée ; confirmation en cours ; confirmée ; indisponible | Carte classe de #1 (colonne gauche) + cartes de choix #12 |
| SM-13 | `/tuteur/classes/:classeId/planning` (`routes.dart:216-225`) | Planning | Tous les jours récurrents de la classe, même enseignant, heure locale, durée, **fuseau explicite** ; exceptions datées (annulée, reportée, absence d'enseignant, remplacement) jamais présentées comme un cours normal. Aucun décalage UTC fixe (MANDAT §5 Classe). Le service du planning complet n'existe pas : le créneau connu s'affiche dans le fuseau de la classe avec un libellé explicite (MAPPING l.27, DB-CRS-03 à 06). | Planning ; exception annulée ; reportée ; remplacement ; indisponible ; vide | Lignes de #25 |
| SM-14 | `/tuteur/classes/:classeId/travail` | Travail à préparer | Consignes, détails, supports, statuts. « Marquer fait » n'atteste aucune maîtrise (FINANCE l.12) et n'existe pas côté serveur (DB-CRS-10) : aucune coche locale. | Liste complète (sans la limite de 3 de l'Accueil) ; vide ; indisponible | Liste de tâches à cercles de #1 / #4 |
| SM-15 | `/tuteur/classes/:classeId/ressources` | Bibliothèque | Ressources autorisées, ouverture dans le lecteur existant `/tc/bibliotheque/:resourceId`. Aucun lecteur PDF (MAPPING l.29). | Liste ; vide ; ressource retirée ; erreur | Lignes de #6 + carte du support de #20 / #24 |
| SM-16 | `/tuteur/classes/:classeId/progression` | Progression | Séances et présences réelles, observations partageables. Jamais les comptes rendus internes des enseignants (MAPPING l.30, DB-CRS-11, DB-TRV-02). | Contenu ; vide ; indisponible | Ligne « Dernière séance » de #1 + lignes de #6 |

La Classe elle-même (`/tuteur/classes/:classeId`) a une maquette mobile claire (#18) : ses variantes manquantes sont au §3, ses états d'observation au §4.

### 2.3 Foyer et fiche élève (aucune maquette high-fi : seulement les anciennes captures #30 et #33 pour le contenu)

| Id | Route (CODE) | Écran | Contenu attendu | États à dessiner | Maquette la plus proche |
|---|---|---|---|---|---|
| SM-17 | `/tuteur/foyer` (`:102`) | Foyer | Titre « Foyer », description courte si utile, action « Ajouter un profil élève » (vers `/tuteur/foyer/ajouter`), une carte groupée des membres (avatar ou initiale, prénom, classe ou « inscription en cours », statut d'accès en texte, chevron vers la fiche), section « Appareils partagés » (ligne vers `/tuteur/foyer/appareils`), option discrète « Créer mon profil élève » tant que ce profil n'existe pas. Pas de compteurs décoratifs, pas de CTA doublon (MANDAT §5 Foyer ; LOTS B-1). | Foyer vide (aucun profil) ; un profil ; plusieurs profils ; profil du titulaire présent ; chargement ; erreur | Contenu #30 ; rendu : lignes de #5 / #6 + avatars du sélecteur de #1 / #4 |
| SM-18 | `/tuteur/foyer/ajouter` (`:110`), `?pour=moi` (`:119`) | Ajouter un profil élève | Parcours plein écran sans barre de navigation, retour 48 dp. Même flux depuis Accueil, Foyer et Compte. Choix « pour un enfant ou mineur » disponible ; « proche adulte » et « moi-même » visibles mais indisponibles et expliqués (DB-FOY-01, DB-FOY-02). Champs existants : prénom, nom, âge entier de 3 à 18 ans (constante du client ; C03 §3.4). Enchaînement vers la fiche puis le questionnaire. Refusé tant que le dossier du titulaire n'est pas validé (DB-ADM-04). **Le directeur annonce une refonte de ce parcours** (voir §5). | Formulaire vide ; erreurs sous les champs ; envoi ; création incertaine (réponse perdue) ; succès ; option indisponible expliquée ; dossier non validé | Gabarit d'étape de #12 / #14 |
| SM-19 | `/tuteur/foyer/:eleveId` (`:126`) | Fiche élève | En-tête : photo, prénom, âge si disponible, classe ou état d'inscription. Puis une carte groupée de six lignes, dans l'ordre du CODE (`routes.dart:134-141`) : Informations, Parcours et inscription, Interface, Caméra en cours, Accès Rewayah, Appareils. Onglet actif : **Foyer**. **Place réservée à un futur solde par élève** (DÉCISIONS §1 ter-9). | Nominal ; élève sans classe ; accès expiré ; identifiant inconnu (« introuvable ») ; chargement | Contenu #33 ; rendu : carte d'identité + groupes de lignes de #5 / #6 |
| SM-20 | `.../informations` | Informations de l'élève | Prénom et nom affichés, non modifiables (DB-FOY-07) ; date de naissance absente du serveur (DB-ADM-05) ; photo : choisir, aperçu, envoi, progression, échec avec reprise. Portrait jamais mélangé avec une pièce d'identité. | Sans photo ; aperçu ; envoi ; échec ; photo enregistrée | Lignes de #6 + champs #14 |
| SM-21 | `.../inscription` | Parcours et inscription | Synthèse : questionnaire, dossier, choix de classe, attente ; liens vers `/tuteur/parcours/:eleveId` et le catalogue. | Questionnaire à faire ; en attente ; inscrit ; indisponible | Récapitulatif #17 + lignes de #6 |
| SM-22 | `.../interface` | Interface | « Interface guidée » ou interface standard selon la politique réelle ; demande d'interface standard par l'élève à partir de 10 ans seulement si confirmée (DB-FOY-04). Aucune bascule qui élève les droits (MANDAT §5 Fiche). | Guidée active ; standard active ; demande en attente ; indisponible | Cartes d'option à radio de #9 |
| SM-23 | `.../camera` | Caméra en cours | Autorisation métier de la caméra de l'élève pendant les séances ; l'effet s'applique à la séance suivante ; confirmation avant changement. Distincte de la permission caméra du scanner QR (MAPPING l.16). | Autorisée ; non autorisée ; confirmation ; enregistrement ; erreur | Lignes à interrupteur de #9 |
| SM-24 | `.../acces` | Accès Rewayah | Statut, dates réelles, « expiré » si la date est passée, motif seulement s'il est fourni (DB-FOY-05). | Actif ; expiré ; sans date ; indisponible | Carte « Abonnement et accès » de #5 / #6 |
| SM-25 | `.../appareils` | Appareils de l'élève | Appareils associés, action « Connecter un appareil » (vers l'émetteur QR), retrait avec confirmation et réponse du service. Dire que le retrait ne ferme pas une session déjà ouverte (DB-APP-03). Aucune limite d'appareils codée en dur. | Liste ; vide ; confirmation de retrait ; retrait en cours ; retiré ; échec | Contenu #33 ; rendu : lignes de #6 + pastille |
| SM-26 | `/tuteur/foyer/appareils` (`:123`) | Appareils du foyer | Nom de l'appareil, profils autorisés, gestion. Un appareil partagé n'est pas encore représentable côté serveur (DB-APP-05). Aucun « 1/2 » ni « un seul en cours à la fois » (MAPPING l.19). | Liste ; vide ; indisponible | Lignes de #6 |
| SM-27 | `/tuteur/foyer/ajouter?pour=moi` | Créer mon profil élève (indisponible) | Écran honnête : la création du profil élève du titulaire n'existe pas encore (DB-FOY-01). Même écran depuis Foyer et Compte. | Indisponible | #22 |

### 2.4 Appareils (parcours des deux côtés, MANDAT §7)

Sens existant, vérifié : **le téléphone du tuteur AFFICHE le QR, l'appareil de l'élève, sans session, le LIT** (LOTS D ; MAPPING §2).

| Id | Route (CODE) | Écran | Contenu attendu | États à dessiner | Maquette la plus proche |
|---|---|---|---|---|---|
| SM-28 | `/tuteur/foyer/appairer/:eleveId` (`:147-150`) | Connecter un appareil (émetteur) | Grand QR **noir sur fond blanc dans les deux thèmes**, marges libres, code manuel lisible, consigne « Sur l'autre appareil », durée de validité réelle. Dès la confirmation du serveur, QR ET code retirés de l'écran, puis « Appareil connecté ». Aucune décoration sur les modules du QR (MANDAT §7). | Préparation ; actif ; validation en cours ; association confirmée ; expiré ; remplacé ou révoqué ; erreur ; réseau interrompu | #22 (colonne centrée) |
| SM-29 | `/connexion/eleve/scanner` (`:26`) | Scanner le QR code (appareil élève) | Mobile : viseur plein écran, retour 48 dp, « Saisir le code ». Ordinateur et tablette : panneau centré, jamais une feuille mobile étirée. Jamais ouvrir une URL contenue dans un QR. Sur Windows et Linux : pas de bouton scanner (MAPPING l.21). | Demande d'autorisation ; refus ; refus durable ; caméra occupée ; caméra absente ; navigateur sans caméra ; erreur de démarrage ; lecture en cours ; succès ; QR inconnu ; expiré ; déjà utilisé ; révoqué | #20 (plein cadre sombre) ; #24 (version ordinateur centrée) |
| SM-30 | `/connexion/eleve/code` (`:29`) | Saisir le code | Champ unique de 6 caractères (format serveur `^[2-9A-HJ-NP-Z]{6}$`, MAPPING l.21), chiffres tabulaires. Refus différenciés : inconnu, expiré, déjà utilisé, révoqué (DB-APP-06). | Vide ; saisie ; erreur sous le champ ; validation ; succès | #14 |
| SM-31 | `/connexion/eleve` (`:21`), état « choix du profil » | Choisir mon profil (appareil partagé) | Grille à deux colonnes d'avatars des profils autorisés, repli en une colonne à 200 % de texte ; « J'ai un nouveau code ». Aucun accès au compte du tuteur. | Un profil ; plusieurs profils ; aucun profil | Grille de #11 / #13 + avatars du sélecteur |
| SM-32 | `/connexion/eleve`, états « code personnel » | Créer / entrer mon code PIN | Création puis saisie du code personnel ; le code ne quitte jamais l'appareil ; erreurs du pavé visibles ; récupération = le tuteur retire l'appareil et le reconnecte (MAPPING l.24). | Création ; confirmation ; saisie ; erreur ; trop d'essais (à vérifier : règle non relevée) | #14 |

À vérifier : le registre de langue des écrans SM-29 à SM-32, vus par l'élève (tutoiement de l'Interface guidée pour un enfant, vouvoiement pour un adulte) n'est tranché dans aucune source lue.

### 2.5 Historique

| Id | Route (CODE) | Écran | Contenu attendu | États à dessiner | Maquette la plus proche |
|---|---|---|---|---|---|
| SM-33 | `/tuteur/seances/:seanceId` (`:185-188`) | Détail de la séance | Identité de la séance (classe, date, heure avec fuseau, enseignant), présence et durée, résumé destiné à la famille (DB-CRS-12), travail et ressources autorisés. Distinguer durée du cours et temps connecté si les deux existent (DB-HIS-03). « En cours de vérification » pour une présence incertaine. Réseau seulement si mesuré. Jamais de notes internes, coordonnées privées ou télémétrie brute (MANDAT §5 Historique). | Présent ; absent validé ; retard validé ; en cours de vérification ; séance annulée ; identifiant inconnu ; résumé indisponible | #27 (détail d'observation) |

### 2.6 Mon compte : sous-pages

| Id | Route (CODE `routes.dart:233-257`) | Écran | Contenu attendu | États à dessiner | Maquette la plus proche |
|---|---|---|---|---|---|
| SM-34 | `/tuteur/compte/informations` | Informations personnelles | Identité et coordonnées du titulaire. Modification impossible côté serveur (DB-CPT-01) : lecture seule honnête. Le fuseau lu par le serveur retombe sur Europe/Paris par défaut : ne pas le présenter comme un choix (MAPPING l.35). | Lecture ; donnée absente ; indisponible pour modification | Carte d'identité et lignes de #5 / #6 + champs #14 |
| SM-35 | `/tuteur/compte/securite` | Connexion et sécurité | Méthodes réelles du compte (lien à usage unique, Google), adresse courriel, sessions actives (DB-CPT-02), déconnexion. Aucun écran de mot de passe en production. | Nominal ; sessions indisponibles ; confirmation de déconnexion | Carte « Sécurité et connexion » de #5 / #6 (titre à corriger) |
| SM-36 | `/tuteur/compte/acces` | Accès (titre à trancher) | Bénéficiaires, accès et échéances réels. Accès offert, accès daté et paiement externe validé ne sont pas un abonnement récurrent (MANDAT §5 Mon compte). CONFLIT de titre : MANDAT §4 « Abonnement et accès » contre MAPPING l.37 « jamais « abonnement » ». | Actif ; expiré ; suspendu ; offert ; en attente ; indisponible | Carte « Abonnement et accès » de #5 / #6 |
| SM-37 | `/tuteur/compte/paiements` | Paiements | Historique réel, détail, justificatif disponible ; montants, devises, statuts et dates fournis seulement. Aucun service en production (DB-CPT-03) : indisponible. « Moyen de paiement » masqué ou indisponible ; une seule entrée vers cette page. **Place réservée à la recharge et au solde par élève** (DÉCISIONS §1 ter-9). | Indisponible ; vide ; liste ; détail | Liste de #25 + détail de #27 |
| SM-38 | sous-page de `/tuteur/compte/preferences` (route à créer, à vérifier) | Langue et région | Langue de l'interface : seul le français est traduit (l'arabe compte 32 lignes contre 2 208), donc « Français » en lecture seule (MAPPING §7.1 l.39, DB-CPT-10). Fuseau en libellé humain (ville), jamais un identifiant technique brut ni un décalage fixe (V4 fiche 01). | Nominal ; fuseau indisponible | Lignes à radio de #9 |
| SM-39 | sous-page de `/tuteur/compte/preferences` (route à créer, à vérifier) | Notifications | Seulement les réglages qui ont un effet réel ; les interrupteurs sans effet sont retirés ou câblés (MAPPING l.39). | Nominal ; indisponible | Lignes à interrupteur de #9 |
| SM-40 | sous-page de `/tuteur/compte/preferences` (à créer ou ligne informative) | Taille du texte ; Cours et données | « Taille du texte » suit le réglage du système (pas d'impasse derrière un chevron). Les réglages existants « Cours et données » (économie de données, lecture agrandie du Coran) sont à préserver (V4 fiche 01). | Nominal | Lignes de #9 |
| SM-41 | `/tuteur/compte/aide` | Aide et support | Aide, contact disponible, suivi si existant. Canal de contact à fournir par le directeur (DB-CPT-07) : indisponible sinon. | Indisponible ; contenu | Lignes de #5 / #6 |
| SM-42 | `/tuteur/compte/informations-legales` | Informations légales | Documents réellement disponibles ; acceptations déjà signées lisibles ; « Document non disponible » sinon (DB-CPT-08). | Liste ; document indisponible | Lignes de #5 / #6 |
| SM-43 | `/tuteur/compte/consentements` (`:256-257`) | Consentement aux visites d'observation (comptes existants) | Lit les acceptations, propose la nouvelle version ; aucun compte considéré comme ayant accepté (DÉCISIONS §2 P2 ; MAPPING §4 C2). | Non accepté ; accepté ; envoi ; erreur | #23 |
| SM-44 | dialogue depuis `/tuteur/compte` | Confirmation de déconnexion | Déconnexion clairement séparée des autres rubriques, avec confirmation (LOTS E-1). | Ouvert ; déconnexion en cours | Aucune ; surface modale de bureau du CODE (commit `42feded`) |

### 2.7 Pages transversales

| Id | Route (CODE) | Écran | Contenu attendu | Maquette la plus proche |
|---|---|---|---|---|
| SM-45 | `errorBuilder` (`app_router.dart:154`) | Page introuvable | Titre humain, phrase utile, action principale, lien secondaire. Texte existant : « Cette page est introuvable » / « Le lien est peut-être incomplet, ou la page n'existe plus. » (`fr.i18n.json:28-31`) | #22 |
| SM-46 | redirection + notice | Accès refusé | « Vous n'avez pas accès à cette page » / « Ce contenu n'est pas ouvert à votre compte. » (`:32-35`) ; retour sûr, sans fuite de données | #22 |
| SM-47 | `/connexion?retour=<chemin validé>` | Session expirée | « Votre session a expiré » / « Reconnectez-vous pour continuer. » (`:36-39`) ; retour vers la destination autorisée, sans boucle | #22 |
| SM-48 | aucune (hors production seulement) | Mode démonstration | Repère discret « Démonstration » et sélecteur de rôle ; données fictives, aucun appel serveur ; impossible en production (DÉCISIONS §1 bis-1, §1 ter-6, §1 quater). À vérifier : aucun fichier dédié trouvé dans le CODE à `cefab7f`. | Aucune |

### 2.8 États système communs à tous les écrans

Composant du CODE : `lib/core/widgets/etat_systeme.dart:19-66`, deux portées : **bloc** (le reste de la page reste en place) ou **page** (grammaire de l'écran résultat #22). Textes existants (`fr.i18n.json:11-70`) :

| État | Titre existant | Phrase existante | À dessiner |
|---|---|---|---|
| Chargement initial | - | - | Squelette de la carte, mêmes dimensions (MANIFESTE §6.3) |
| Chargement prolongé | « La connexion prend plus de temps que prévu » | « Vous pouvez patienter encore un peu ou réessayer. » | bloc et page |
| Hors ligne | « Vous êtes hors ligne » | « Vérifiez votre connexion. Ce qui est déjà affiché reste consultable. » | bandeau et page |
| Reconnexion | « Reconnexion en cours » | « Une nouvelle tentative de connexion est en cours. » | bandeau discret |
| Échec serveur | « Impossible de charger ces informations » | « Le chargement n'a pas abouti. Réessayez dans un instant. » | bloc (la carte garde son cadre + « Réessayer ») et page |
| Dossier en attente | « Votre dossier est en attente » | « Une étape reste à franchir avant d'ouvrir cet espace. » | page |
| Aucun résultat | « Aucun résultat » | « Rien ne correspond pour le moment. » | bloc, avec « Réinitialiser les filtres » |
| Autorisation refusée | « Autorisation refusée » | « Sans cette autorisation, cette fonction ne peut pas s'ouvrir. Vous pouvez la modifier dans les réglages de votre appareil. » | page, avec alternative (code manuel) |
| Ressource expirée | « Ce contenu n'est plus disponible » | « Il a été retiré, ou son accès a pris fin. » | page |
| Indisponible | « Pas encore disponible » | « Cette fonction n'est pas encore ouverte. » | bloc et page, sans « Réessayer » |

ChatGPT peut proposer de meilleurs textes (marqués PROPOSITION), en gardant un seul texte par état pour toute l'application.

---

## 3. Écrans qui ont une maquette, mais seulement dans un thème ou un format

Formats exigés en recette : 390 × 844 et 1440 × 900, clair et sombre (LOTS §0) ; tablette 768 dans le prompt ChatGPT. Source : MANIFESTE §6.1, complété par V3, V4, V8.

| Écran | Route | Existe | Manque | Règle de composition du manquant |
|---|---|---|---|---|
| Accueil | `/tuteur` | Mobile clair #4 ; ordinateur clair #1 ; tablette sombre #2 ; ordinateur étroit sombre #3 | **Mobile sombre** ; tablette claire | Composition de #4, couleurs de #3 (MANIFESTE §6.3) |
| Mon compte | `/tuteur/compte` | Ordinateur clair #5 ; mobile clair #6 ; mobile sombre #7 | **Ordinateur sombre** ; tablette | Composition de #5, couleurs de #7 |
| Réglages (hub des préférences) | `/tuteur/compte/preferences` | Mobile sombre #8 | **Clair** ; ordinateur ; tablette (colonne de 760 dp) | Un seul groupe à filets au lieu de quatre cartes (V4) |
| Apparence | `/tuteur/compte/preferences/apparence` | Mobile sombre #9 | **Clair** ; ordinateur ; tablette | Composition de #9 ; indice de rendu clair dans ses miniatures |
| Admission : usage, genre, âge, langue, objectif, récapitulatif | `/inscription/*`, `/tuteur/parcours/:eleveId` | Mobile sombre #10 à #17 | **Clair** ; ordinateur et tablette (colonne centrée de 480 à 560 dp, CTA en bas de colonne) | Gabarit d'étape de V6 ; CTA en pilule réservé à l'admission (DÉCISIONS §3.2) |
| Classe + bloc Observation | `/tuteur/classes/:classeId` | Mobile clair #18 | Sombre ; **ordinateur et tablette** | Deux colonnes de #1 : carte séance à gauche (enseignant avec photo, prochaine séance, « Observer la séance », visites disponibles, « Comment ça marche ? »), lignes Planning, Travail, Bibliothèque, Progression, Historique à droite |
| Explication de première utilisation | étape de `/tc/observation/:seanceId` | Mobile clair #19 | Sombre ; ordinateur (colonne centrée ou dialogue) | Pas de feuille étirée |
| Fin de visite | retour classe | Mobile clair #22 | Sombre ; ordinateur ; variantes de fin (voir §4) | Écran résultat |
| Consentement observation | `/attente/contrat`, `/tuteur/compte/consentements` | Mobile clair #23 | Sombre ; ordinateur | Colonne centrée |
| Salle d'observation | `/tc/observation/:seanceId` | Mobile sombre #20 ; mobile clair #21 ; ordinateur clair #24 | Ordinateur sombre ; **mobile paysage** ; tablette ; **et refonte de l'en-tête pour tous les formats** (voir §4.3) | Un seul style de barre de commandes par format |
| Historique | `/tuteur/suivi` et `/tuteur/suivi/observations` | Mobile sombre #25 (segment Observations seulement) | **Clair** ; **ordinateur** ; **segment Séances** (contenu de #31) ; vide ; filtré sans résultat | Composition de #25 ; ordinateur : liste limitée à la largeur de lecture, rail de #1 |
| Détail d'une observation | `/tuteur/seances/:seanceId/observations?eleve=` | Mobile clair #27 | Sombre ; ordinateur ; motifs « Fin de séance » et « Interrompue » | Même ligne de visite que #27 |
| Historique des observations, administration | `/admin/securite-audit/observations` | Ordinateur clair #26 | Sombre (rôle administration, hors tuteur) | Navigation admin existante, pas la barre latérale de #26 |

États absents des maquettes existantes, à dessiner avec les mêmes compositions (V1 §6, V2 §8, V3 n°22, V6) :
- **Accueil** : vide (première inscription ou ajout de profil, jamais une fausse classe) ; chargement ; erreur de bloc ; hors ligne ; avant ouverture de la salle ; salle ouverte (fenêtre donnée par le serveur, en général 20 minutes avant) ; séance en direct ; séance prolongée « Séance toujours en direct » sans compteur négatif (DÉCISIONS §3.7) ; terminée ; annulée ; reportée ; changement d'heure ; horaire incertain sans horloge serveur (état `horaireIncertain` du contrat K2, MAPPING §7.1) ; présence « En cours de vérification » ; profil du titulaire dans le sélecteur (jamais appelé « enfant ») ; photo de l'enseignant (absente de #1 à #4).
- **Mon compte** : rubriques absentes de #5 à #7 : Préférences (engrenage muet), Informations légales, « Créer mon profil élève », ligne Foyer, déconnexion séparée avec confirmation (V3 n°9 ; MAPPING §7.1) ; place pour le futur solde ; chargement, erreur, hors ligne.
- **Admission** : état initial vide sur chaque étape (CTA désactivé ou erreur sous le groupe) ; lien discret « Je suis enseignant » sous les cartes d'usage (DÉCISIONS §3.8) ; raison de la question du genre en sous-titre ; correction par ligne au récapitulatif ; double soumission bloquée.

---

## 4. Planche 3 manquante : « États particuliers et notices de présence »

Fait : MANDAT-OBS §2 annonce trois planches ; la planche 3 est **introuvable** dans le dossier des maquettes (MANIFESTE §1 l.79-80 ; V8 §5 ; DÉCISIONS §2 P10, demandée au directeur). À produire par ChatGPT.

### 4.1 Règles d'observation qui fixent le contenu (priment sur toutes les maquettes)

- Par défaut : 2 visites maximum par séance, 120 secondes maximum par visite, 240 secondes au total, jamais une visite unique de 4 minutes ; valeurs configurables par l'administration, l'écran lit la politique effective (MANDAT-OBS §4).
- Quota **par parent** (par compte observateur), 2 visites par séance quel que soit le nombre de ses enfants dans la salle ; **une visite écourtée est consommée** (DÉCISIONS §1 bis-4).
- Observation possible seulement si l'enfant est présent. Ne pas confondre caméra désactivée, coupure temporaire et absence. Présence incertaine = vérification, jamais une absence inventée (MANDAT-OBS §4).
- Le tuteur entend l'enseignant et les élèves dont le micro est actif, voit le support partagé, l'enseignant et son propre enfant ; il n'a ni micro, ni caméra, ni chat, ni réactions, ni annotations, ni liste des autres élèves (MANDAT-OBS §4).
- Le compteur ne démarre qu'à l'entrée confirmée, jamais pendant l'explication ou la vérification (MANDAT-OBS §5). Une reconnexion ne simule pas du direct et ne remet pas le compteur à zéro (MANDAT-OBS §7).
- En production, l'observation réelle reste fermée (interrupteur `OBSERVATION_TUTEUR_REELLE` à faux, DÉCISIONS §2 P3) : le bloc affiche un motif « pas encore ouverte ». Le parcours complet se montre en démonstration.

### 4.2 États à dessiner, par emplacement (MANIFESTE §6.3 ; V7 §4 et §6 ; LOTS O-3)

| Emplacement | État | Texte existant dans le CODE (`fr.i18n.json`) | Remarque |
|---|---|---|---|
| Bloc Observation de la Classe (#18) | 2 visites disponibles | aucun (« 2 visites disponibles • 2 min par visite » sur #18, valeurs illustratives) | Nombre et durée lus dans la politique |
| idem | 1 visite restante | aucun | Accord au singulier |
| idem | Visites épuisées | `refus.quotaVisites` « Vous avez déjà utilisé vos visites pour cette séance. » (`:2221`) ; `refus.tempsEpuise` (`:2222`) | CTA retiré ou désactivé avec motif |
| idem | Enfant absent | aucun texte dédié | Seulement sur présence validée |
| idem | Présence en cours de vérification | aucun | Troisième issue absente du logigramme #28 (V7 §6) |
| idem | Séance non commencée | `refus.seanceNonActive` « La séance n'est pas en cours. » (`:2224`) ; `refus.horsFenetre` (`:2225`) | |
| idem | Séance terminée | aucun texte de refus dédié | |
| idem | Observation désactivée pour cette classe | `refus.politiqueDesactivee` « L'observation est désactivée pour ce groupe. » (`:2220`) | Texte à corriger : « classe », jamais « groupe » à l'écran (BACKLOG, réponses du directeur) |
| idem | Tuteur non rattaché à un élève de la séance | `refus.lienTuteur` (`:2223`) | |
| idem | Observation pas encore activée (production) | `refus.capaciteAbsente` (`:2227`) | |
| idem | Lien « Comment ça marche ? » toujours visible | - | Même après la première utilisation (V7 §6) |
| Avant la salle (#19 et suivant) | Explication de première utilisation | `entree.tuteurIntro` (`:2207`), à remplacer par le texte de MANDAT-OBS §6 complété par la règle « visite écourtée consommée » | Compteur arrêté ; « Pas maintenant » ramène à la classe |
| idem | Connexion et vérification | aucun | Compteur arrêté |
| idem | Connexion prolongée | texte commun « La connexion prend plus de temps que prévu » | Absent du logigramme (V7 §6) |
| idem | Connexion impossible | `refus.indisponible` (`:2226`) | « Réessayer » ; ne décrémente rien localement |
| idem | Annuler pendant l'explication ou la vérification | aucun | Retour sans consommer de visite (V7 §6) |
| Dans la salle (#20, #21, #24) | Reconnexion | `visite.budgetIncertain` « Temps restant non confirmé par le serveur. » (`:2237`) | Surimpression discrète, pas de faux direct |
| idem | Caméra de l'enfant désactivée | `visite.enfantAbsent` « Votre enfant n'a pas d'image ouverte. » (`:2236`) | Le nom de clé mélange absence et caméra (V7 §7.4) : le texte doit dire « caméra », pas « absent » |
| idem | Aucun support partagé | `visite.supportIndisponible` (`:2233`) | |
| idem | Vidéo de la séance non ouverte | `visite.videoIndisponible` (`:2238`) | |
| idem | Son reçu coupé / rétabli | - | Jamais par la couleur seule |
| idem | Sortie non confirmée | `visite.sortieNonConfirmee` (`:2239`) | |
| Fin de visite (variantes de #22) | Sortie volontaire | `fin.sortieVolontaire` (`:2244`) | Avec visites restantes réelles |
| idem | Durée de visite atteinte | `fin.quotaAtteint` « Votre temps d'observation est écoulé. » (`:2245`) | |
| idem | Fin de séance | `fin.seanceTerminee` (`:2246`) | |
| idem | Observation interrompue | `fin.revocationServeur` (`:2247`) ; `fin.deconnexion` (`:2248`) | |
| idem | Plus aucune visite | « Aucune visite restante pour cette séance » (DÉCISIONS §1 bis-5) | Lien « Voir mes observations » vers `/tuteur/suivi/observations` |

Les lignes `:22xx` renvoient à `CODE assets/i18n/fr.i18n.json` au commit `cefab7f`, dans le bloc `observation` (lignes 2204 à 2255).

### 4.3 Salle d'observation : décision du directeur qui change les maquettes existantes

DÉCISIONS §1 bis-5 : « visio moderne, épurée, très peu de boutons » ; **en haut, un bandeau pleine largeur** qui affiche le **décompte du temps restant seconde par seconde** et le **nombre de visites restantes** (« 1/2 visite restante pour cette séance », accord au pluriel, « Aucune visite restante pour cette séance » à 0) ; commandes : son reçu, agrandir le support, quitter.

Or #20, #21 et #24 placent « Visite 1/2 · 01:42 » dans une pastille de l'en-tête, sans bandeau, et montrent trois styles différents de barre de commandes et deux icônes « Quitter » (V8 M4). Conséquence : **la salle doit être redessinée** (en-tête et barre de commandes) en mobile portrait, mobile paysage, tablette et ordinateur, clair et sombre. Le reste de la composition (support dominant, deux vignettes secondaires qui ne couvrent jamais le support) est conservé. Le décompte tranche l'ambiguïté « décompte ou temps écoulé » relevée en MANIFESTE §5 C9.

### 4.4 Notices de présence (côté enseignant et côté enfant)

- Règle : l'enseignant et l'enfant concerné voient une notice discrète ; les autres élèves ne reçoivent rien ; « Votre maman… » seulement si le lien familial est connu, sinon « Votre parent… » (MANDAT-OBS §4).
- **Hors périmètre du chantier Tuteur** : à concevoir avec les rôles enseignant et élève (DÉCISIONS §1 bis-6). Elles relèvent donc de `02_CLASSE_ET_VISIO.md`, pas des écrans du tuteur.
- Textes existants à corriger (CODE `fr.i18n.json:2250-2255`) : côté enfant « Ton tuteur regarde le cours » (contredit la règle ci-dessus) ; côté enseignant « Tuteur de {prenomEnfant} observe », « {nombre} tuteurs observent ».

---

## 5. Fonctions du tuteur annoncées pour plus tard (DÉCISIONS §1 ter-9)

Texte exact de la décision : « À venir côté tuteur (ne pas construire, laisser la place) : recharge de solde, chaque enfant consomme son propre solde, parcours d'ajout d'un nouvel enfant revu. Les visuels viendront plus tard. Compte > Paiements et Foyer > fiche élève doivent pouvoir accueillir un solde par enfant sans refonte. »

| Fonction | Emplacement décidé | Faits qui encadrent la spec | État dans le CODE |
|---|---|---|---|
| Recharge de solde | Compte > Paiements (`/tuteur/compte/paiements`) | Paiement initial hors application, enregistré et validé manuellement ; pas de débit ni de versement inventé ; aucun prestataire unique imposé ; pas de dépendance permanente à un seul prestataire pour la diaspora (FINANCE §Finance l.20). Prix jamais écrits dans l'application ; valeurs anciennes 50 USD par mois, 90 USD pour deux, 40 USD par personne à partir de trois, **à confirmer** (FINANCE l.23). | Aucun écran, aucun contrat serveur (DB-CPT-03 pour les paiements) : CONTRAT À CRÉER |
| Solde par élève (« chaque enfant consomme son propre solde ») | Foyer > fiche élève (`/tuteur/foyer/:eleveId`) ; résumé possible dans Paiements (une seule fonction par endroit : la recharge dans Paiements, le solde de chaque élève dans sa fiche) | Registre de crédits immuable (attribution, réserve, consommation, libération, expiration, compensation, annulation) ; aucun solde corrigé par écrasement ; équivalence prix / temps à valider avant activation (ancien scénario 50 USD, 30 unités, 12 séances, non universel) ; absence de l'élève et cours assuré selon une politique versionnée ; absence d'enseignant sans remplacement = compensation (FINANCE l.25). | Aucun |
| Parcours d'ajout d'un nouvel enfant revu | `/tuteur/foyer/ajouter` (même flux depuis Accueil, Foyer, Compte) | Actuel : un écran, prénom, nom, âge 3 à 18 ans (C03 §3.4) ; serveur : création d'un profil mineur, âge 3 à 99, mode d'interface et caméra déduits de l'âge (C03 §3.4). Contraintes : cohortes 6-9, 10-13, 14-17, 18+ et date de naissance si confirmées (MANDAT §6 ; DB-ADM-05) ; proche adulte et profil du titulaire à prévoir (DB-FOY-01, DB-FOY-02) ; ajout seulement après validation du dossier (DB-ADM-04) ; idempotence (DB-FOY-06) ; enchaîner vers le questionnaire puis le choix de classe. | Écran réservé au lot B (STUB) |

Ces trois fonctions n'ont ni maquette ni visuel annoncé : ChatGPT les spécifie et les dessine en PROPOSITION, marquées « à venir, ne pas construire avant accord du directeur ».

---

## 6. Erreurs à ne pas reproduire, maquette par maquette

Une ligne par maquette (MANIFESTE §5 ; V1 à V9). Valable pour toutes : prénoms, dates, heures, durées, quotas, compteurs et noms de classe sont illustratifs et ne deviennent jamais des constantes (MANIFESTE §5 B) ; ne pas dessiner la barre d'état iOS ni les étiquettes de planche (MANIFESTE §5 G) ; cibles d'au moins 48 dp et contraste AA (MANIFESTE §5 E).

| # | Erreurs à ne pas reproduire |
|---|---|
| 1 | « Ajouter enfant » ; « Session 18:00 » ; « Adam / Absente » (accord faux, absence par la seule couleur) ; « Dernière séance 1 h » ambigu ; initiale de l'élève à la place de la photo de l'enseignant ; « Détails et connexion » (dire « Détails de la séance ») ; « Avant / Après la séance » (dire « Avant le prochain cours ») ; « Salle ouverte » à T-13 figé ; bascule de thème sans mode Système ; cadre arrondi sur fond lavande (mise en scène). |
| 2 | Mêmes erreurs de texte que #1 ; « 1 tâche + 2 autres activités » (afficher 3 tâches partout) ; « + » en pointillé (contour plein) ; rail replié sans infobulle ni étiquette pour le lecteur d'écran. |
| 3 | Mêmes erreurs de texte que #1 ; colonne droite en trait vertical au lieu d'une carte : un seul arbre d'écran, seul le format change la composition, jamais le thème (MANIFESTE §5 F). |
| 4 | Barre à 3 onglets (4 exigés) ; « Ajouter enfant » ; « Session dans 13 min » ; Mariam « En séance » dans le sélecteur mais « dans 13 min » dans la carte ; deux blocages simultanés (photo et appareil) ; « Réseau élève / enseignant Bon » ; dates incohérentes (lundi 21 et jeudi 18 septembre) ; carte « Dernière séance » cachée sous la barre ; accent lavande pâle illisible (2,8:1) ; bouton « Connecter un appareil » coupé sur deux lignes. |
| 5 | CTA dominant « Gérer les paiements » et doublons vers Paiements ; « Moyen de paiement » ; « Compte vérifié » sans statut serveur ; « Sécurité et connexion » (dire « Connexion et sécurité ») ; « Appareils connectés · 2 appareils » ; « disponibilités » ; téléphone affiché deux fois ; « Email et mot de passe » (méthodes réelles seulement) ; Préférences, Informations légales, « Créer mon profil élève » absents ; lignes d'« Aide et support » indentées ; contenu étiré sur 1096 dp. |
| 6 | Mêmes erreurs de contenu que #5 ; bande « Se déconnecter » trop basse (moins de 48 dp) ; légendes et textes verts sous AA. |
| 7 | Mêmes erreurs de contenu que #5 ; le nom du fichier dit « desktop » mais c'est un mobile ; apostrophes mélangées. |
| 8 | Quatre cartes séparées (un seul groupe à filets) ; « Français · Asia/Riyadh » en dur et identifiant de fuseau brut ; ligne « Sécurité » qui doublonne `.../securite` ; titre « Réglages » contre « Préférences » du mandat (à trancher, sans collision avec les réglages de l'élève) ; rubrique « Cours et données » supprimée. |
| 9 | « Appliqué sur cet appareil. » alors que le choix est perdu au rechargement sur le web ; « Taille du texte » avec chevron sans destination ; piste d'interrupteur désactivé à 1,77:1 ; légende rétrécie pour tenir sur une ligne ; marges de 8 dp au lieu de 16 dp. |
| 10 | Titre « Quel type de compte souhaitez-vous créer ? » (dire « Pour qui souhaitez-vous utiliser Rewayah ? ») ; « Moi et les membres de ma famille » (dire « Moi et ma famille ») ; descriptions à remplacer par celles du directeur ; promesse « les paiements » ; option présélectionnée ; « 2 sur 5 » en dur ; pas de lien enseignant ; artefact « per sonne ». |
| 11 | « Homme » présélectionné ; « Sélectionnez une option. » à la place de la raison de la question ; « 3 sur 5 » et barre à 54 % pour 3/5 ; pictogramme féminin à faire arbitrer par le directeur. |
| 12 | « Pour qui créez-vous ce compte ? » ; descriptions différentes du texte imposé ; promesse « les paiements de la famille » ; aucune entrée enseignant ; option présélectionnée ; « 1 sur 6 » figé. |
| 13 | Pas de sous-titre expliquant la question ; pictogrammes genrés stéréotypés ; présélection ; étape « prénom, nom » absente mais obligatoire. |
| 14 | Âge exact libre « 28 ans » (CONFLIT avec les tranches serveur) ; aide « Pour adapter votre parcours. » plus vague que la raison réelle ; question au « vous » au lieu du prénom de l'élève. |
| 15 | Langue de l'application demandée dans l'admission (elle remplace à tort la langue du cours) ; English et العربية proposés alors qu'ils ne sont pas traduits ; icône « personne » pour une langue. |
| 16 | Options différentes du code (« Je ne sais pas encore » supprimée, « Apprendre les bases de l'islam » ajoutée sans parcours réel) ; question de niveau absente ; pastille sélectionnée d'une autre teinte que #12 et #15. |
| 17 | « Vos préférences sont prêtes. » (faux succès) ; un seul lien « Modifier mes réponses » au lieu d'une correction par ligne ; état du dossier et prochaine action réelle absents ; « 6 sur 6 » figé. |
| 18 | « Temps restant » ambigu (séance ou visite) ; « Avant / Après la séance » ; Bibliothèque, Progression et Historique absents de la liste ; « Niveau 1 » qui ressemble à un code interne ; CTA de 40 dp. |
| 19 | Coquille « quii » ; « 2 visites de 2 minutes » en dur ; texte du mandat incomplet (et règle « visite écourtée consommée » absente) ; « son enseignant » sans Sayyid / Sayyida. |
| 20 | Pastilles d'en-tête au lieu du bandeau pleine largeur décidé (§4.3) ; « 01:42 » ambigu ; kasra manquante sous ب ; chevron retour qui ne passe pas par « Quitter » ; barre de commandes verticale propre à cet écran. |
| 21 | Même en-tête que #20 ; barre de commandes horizontale différente de #20 et #24 ; même erreur d'arabe. |
| 22 | « une visite de 2 minutes » en dur ; seule la variante « première visite terminée » existe (les autres fins sont au §4.2). |
| 23 | Texte différent de celui exigé par MANDAT-OBS §6 ; seulement « pour mon enfant » (variantes responsable légal et élève adulte absentes) ; case et CTA de moins de 48 dp ; CTA désactivé trop peu contrasté. |
| 24 | ث remplacée par ت dans le support ; avatar générique à la place du portrait de l'enfant ; effet « elle parle » sans signal réel ; icône « Quitter » en combiné téléphonique (une seule icône partout) ; pas de bandeau pleine largeur. |
| 25 | « Ajouter enfant » ; « Session 18:00 » ; « Dernière séance 1 h » ; « Terminées » contre « Terminée » ; fuseau absent de la liste ; barre de navigation gris neutre `#4B4B4B` hors palette. |
| 26 | Barre latérale admin inventée (réutiliser la navigation admin existante) ; filtre « Statut » sans colonne correspondante ; filtres tuteur et élève seulement par la recherche ; ligne du 18/09 absente (jeu de démonstration incohérent avec #25). |
| 27 | Horaire « 18:35 – 18:36:42 » au format incohérent ; « Heure de Paris » ici contre « Europe/Paris » en #26 ; lien retour de 29 dp ; deux motifs de fin seulement ; libellé du CTA en violet au lieu de l'encre foncée. |
| 28 | Styles du logigramme (crème, brun, Segoe UI, pointillés) à ne jamais transformer en jetons ; « Deux minutes écoulées » en dur ; décision « disponible ? » binaire sans « présence en vérification » ; reconnexion qui revient au direct ; accès direct à la salle sans vérification. |
| 29 | Ancienne capture : barre à 3 onglets grise ; mêmes erreurs que #4 ; libellés d'onglets sous AA. |
| 30 | Ancienne capture : « Ajouter un enfant », « Enfants », « Gérer tous les enfants » ; compteurs décoratifs « 3 enfants / 1 appareil / 2 alertes » ; « 1/2 appareils » ; « Diagnostic à terminer » ; « Configure un appareil » ; « iPhone de Mariam » comme appareil familial ; « Disponibilités du foyer » ; rubans colorés ; « Créer mon profil élève » absent. |
| 31 | Ancienne capture : pas de bascule Séances / Observations ; dates et année 2024 fausses ; « Sayda », « Ustadh » ; trois classes et trois enseignants pour une élève ; réseau au premier plan ; « Absente » avec « Réseau Bon ». |
| 32 | Ancienne capture : « Observer la session » proposé avant le début et sans quota ; photo de l'enseignant absente ; décalage fixe Paris / Abidjan ; « 13 : 45 » avec espaces ; ressources, progression, historique et exceptions absents. |
| 33 | Ancienne capture : onglet actif « Compte » (c'est la fiche élève : Foyer) ; « Accés » ; « Paramètres de l'enfant » (dire « Réglages de {prénom} ») ; « Indisponible pendant la séance » sans politique établie ; « Appareil actuel » non confirmé ; Informations et Parcours absents. |

---

## 7. Synthèse : nouvelles images à produire pour le rôle Tuteur

PROPOSITION de volume et d'ordre (mon estimation, à valider par le directeur) : pour chaque écran du §2, une maquette mobile 390 × 844 clair et une ordinateur 1440 × 900 clair ; le sombre est dérivé par les règles de MANIFESTE §6.2, sauf pour les écrans où le sombre change la lecture (salle d'observation, émetteur QR).

| Ordre | Groupe | Écrans | Pourquoi d'abord |
|---|---|---|---|
| 1 | Foyer et fiche élève | SM-17 à SM-27 | Aucune maquette high-fi, seulement d'anciennes captures |
| 2 | Appareils | SM-28 à SM-32 | Aucune maquette ; parcours sur deux appareils |
| 3 | Planche 3 et salle redessinée | §4.2, §4.3 | Planche manquante ; décision du directeur contraire aux maquettes |
| 4 | Admission sans image | SM-01 à SM-10 | Écrans publics, premier contact |
| 5 | Classe (sous-pages, catalogue), Historique (détail de séance), Compte (sous-pages), Notifications | SM-11 à SM-16, SM-33 à SM-44 | Dérivations simples de maquettes proches |
| 6 | Variantes de thème et de format | §3 | Règles de dérivation déjà écrites |
| 7 | Fonctions à venir | §5 | Visuels annoncés « plus tard » par le directeur |

Points encore ouverts à signaler à ChatGPT comme CONFLIT, sans les trancher : âge exact ou tranches (§2.1) ; classe réelle ou offre horaire à l'étape 7 (§2.1) ; titre « Abonnement et accès » (SM-36) ; « Réglages » ou « Préférences » (#8) ; pictogramme féminin (#11) ; barre de progression continue ou segmentée et carte « Autre » de l'admission (MANIFESTE §6.4-8) ; registre de langue des écrans de l'appareil élève (§2.4).
