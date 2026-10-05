# Bilan du matin, 05/10/2026 (orchestrateur de nuit, session 01B8we8b)

Tout ce qui suit est sur GitHub et coché dans le tableau Suivi Rewayah avec sa preuve. Aucune PR, aucune fusion vers main (K-19). Chaque étape « vérifiée » l'a été par un agent qui n'en avait écrit aucune ligne, avec tests rejoués, contre-épreuve sur l'ancien code et captures ouvertes.

## 1. Où regarder

| Quoi | Branche | Contenu |
| :--- | :--- | :--- |
| **Toutes les corrections de la nuit réunies** | `ccr-1b1bfa0b-m1kvkk` | Branche commune `corrections/revue-directeur-2026-10` à jour (29a4fc83) + les 14 branches de corrections vérifiées. Rapport : `docs/orchestration/INTEG-NUIT-2026-10-05.md` |
| **Comptable V1** | `ui/comptable-v1` | Socle + 6 voies + corrections de la vague Finance (FI-VAGUE-CORR), fusionnées (CPT-FUS), recette visuelle (CPT-CAPT), revue croisée (CPT-R), corrections (CPT-RC, voir §3) |
| Pilotage | `pilotage/tuteur-v1` | `20_comptable/CARTE_FONCTIONS.md`, `20_comptable/REVUE_CPT-R.md`, fiches AD alignées |
| Ressources | `projet/ressources` | `LISEZ-MOI.md` ligne 10 (DOC-RESSOURCES-1) |

Mesures sur `ccr-1b1bfa0b-m1kvkk` : analyse 0 problème ; 6566 tests réussis, 1 échec (question Q-6 ci-dessous) ; jetons 39 → 31 (8 retirés, aucun ajouté).

## 2. Étapes vérifiées cette nuit

| Étape | Ce qui change pour l'utilisateur |
| :--- | :--- |
| **ENS-PAYS-1** (votre demande) | Le pays de l'enseignant s'affiche sous son nom sur toutes ses cartes : tuteur (accueil, groupes, catalogue « Choisir une classe », classe, classe en direct, suivi), élève enfant et adulte, Mode Accessibilité, contrôleur (mission, historique, rapports), admin (Attribution, Groupes, Comptes). Drapeau devant le nom là où l'appareil sait le dessiner (Android, iPhone, Mac) ; nom seul sous Windows, jamais deux lettres orphelines. Caché quand l'identité est masquée. 108 captures |
| CLASSE-LIVE-ENCRE-1 | Classe en direct : « Vous êtes seul dans la salle », les messages et le bandeau « Cours enregistré » redeviennent lisibles (contraste 1,0–2,6 → ≥ 4,5) |
| JUR-APP-1 | Textes juridiques signés le 02/10 mot pour mot ; feuille E-1 qui défile ; lien « En savoir plus » discret qui ne vole aucune touche ; **garde-fou** : les vrais enseignants signent la version 2026-09 tant que la politique de contrôle n'est pas publiée |
| SALLE-ENCRE-1, SALLE-CORR-4 (m10), SALLE-ERR-320-1 | Salle : textes du support et bandeau lisibles sur le fond de la salle ; message d'erreur avec « Réessayer » toujours visible à 320 px texte ×2 ; réparation de l'écran Journée cassé par une fusion |
| FORM-L8-9 (+ champ Verset) | Profil enseignant : pays et langues choisis dans des listes ; cahier : reprise par sourate puis verset, recherche sur une ligne, saisie du verset contrôlée |
| FORM-CORR-1, FORM-MINEURS | Calendrier lisible à 320 ×2, étiquettes au-dessus des champs, sélecteur de personne (identifiant sur sa ligne), page Programmes qui défile |
| AD-NETTOYAGE-2, AD-M2-CAPT | Admin : mineurs de la revue AD ; captures de la planche HL-A-5 refaites et probantes |
| CTRL-MSG-2, COUPE-MOTS-CTRL-1, MA-APRES-1b, COUPE-MOTS-1b, LIB-ERR-2, EN-7c-MINEURS, CAPT-L1-2, ONGLETS-COUPE-1 | Contrôleur, Mode Accessibilité, mots coupés, libellés d'erreur, onglets (détail dans le tableau) |
| CPT-F, CPT-0 | Socle du rôle Comptable (vérifié après correction à 320 ×2) |
| DOC-RESSOURCES-1 | Résumé des règles DESIGN-GOV dans les ressources |

Comptable : CPT-JOUR, CPT-PAY-1/2, CPT-TRES-1/2, CPT-ENC-1/2, CPT-BEN-1/2, CPT-CTR-1, CPT-DIR-1 faits ; vérifiés ensemble par la revue CPT-R (sécurité §47 tenue, 27 recettes R-FIN sur 29 prouvées), qui a refusé pour 3 défauts corrigés dans CPT-RC.

## 3. Comptable : fermeture de la vague

- **CPT-RC** fait et **vérifié** sur `ui/comptable-v1` @ c07aead7 (rapport `docs/current/CPT-RC.md`) :
  - la vraie démo `/demo/comptable` montre ses 16 écrans avec données (8 étaient vides) ;
  - les 4 composants du socle sont au catalogue et à la galerie ;
  - l'en-tête des pages de détail ne s'écrit plus un mot par ligne à 320 ×2 ;
  - suite complète par dossiers : 6367 réussis, 0 échec ; analyse 0 ; jetons 39.
  - Reportés (design) : liste de bénéficiaires plus dense, gabarit de la Direction, vide en haut de la coquille admin à 390, une pastille de tableau.

## 4. Ce qui attend votre décision

Juridique et contrat
- **Q-1** Politique de contrôle, partie B, §10 : numéro de société, adresse du siège, contact confidentialité, représentant dans l'UE. Sans eux, la politique n'est pas publiée, les vrais enseignants signent la version 2026-09, et l'information E-2 (13–17 ans) reste cachée.
- **Q-2** Les enseignants qui signent 2026-09 en attendant devront-ils signer 2026-10-jur ensuite ?
- **Q-3** Lien « En savoir plus » à 320 px : il décale le cours de 16 dp et fait passer l'en-tête au-dessus de 30 % à texte ×1,5 et ×2. Accepter, le cacher sous ~385 px, ou rouvrir l'ADR-011 ?
- Pièces toujours attendues : P-1, A0, charte contrôleur, « Je m'oppose », écran A7.

Pays de l'enseignant
- **Q-4** Le pays aussi dans la salle pendant le cours (tuiles vidéo, ligne d'état) ?
- **Q-5** Drapeau sous Windows : demande un jeu d'images libres en assets, donc une ligne dans `pubspec.yaml` (interdit sans vous).
- Backend (BR-1) : rien ne s'affiche en production tant que le serveur n'expose pas `teacher_country` (liste exacte dans `docs/current/ENS-PAYS-1_BR.md`).

Textes
- **Q-6** « À terminer » des enseignants : DASH-ENS-b a retiré « transmission » (mot coupé à 320 ×2), LIB-CAHIER-1 exige « cahier de transmission » partout. Lequel l'emporte ? (le seul test rouge de l'intégration)
- **Q-7** Libellés à valider : « Entre 1 et {n} » (saisie du verset), les 6 textes du sélecteur de personne « observable » (accès agents).

Comptable
- **Q-8** (CPT-Q1) Où la Direction valide-t-elle les demandes du Comptable ? (l'onglet « À valider » n'est pas construit)
- **Q-9** Masquer aussi les pourcentages quand les montants sont masqués (« 82 % atteint ») ?
- **Q-10** Traduire l'espace Comptable en arabe ? (aujourd'hui le RTL montre du français)
- **Q-11** `UX_REVIEW_FINANCE_COMPTABLE_L0.md` tient-il lieu de registre des écrans, ou faut-il les inscrire dans `08-catalogue-ecrans.md` ?
- **Q-12** Pilule « Remboursements et avoirs » : libellé plus court ?
- **Q-13** Libellé « À traiter, hors paiements » (Aujourd'hui du Comptable) : il passe sur 2 lignes à 1440 ; une formulation plus courte ?

Questions des étapes plus anciennes (dans le tableau) : ETATS-MA-1, FORM-L1-7-13, DR-14, phrase neutre de MA-APRES-1b, pastille « En attente » et m4/m5/n4/m13 de l'admin, translittération Hâ/Ḥâ et paires de lettres arabes inversées (EN-7c), « Ouvrir le Coran » sans couleur d'accent dans la salle, démo sans corpus du Coran, liste des pays au-delà de 19.

## 5. Volontairement non lancé

- Attente de votre décision : DIR-REP-1, LOGO-1, PAQ-*, CI-D2, TB-4, FILTRES-1, SUPERPOS-1, PUB-1, DASH-LIB, DASH-ADM-PLANNING, CORAN-320-1, MA-CORAN-X2-1, MUSHAF-DIR-1, AD-X.
- Attente du backend (BR-1) : EA-ROLE-1, KYC-LECTURE-1, DASH-ADM-INC, LIVE-PAUSE-01, ALERTE-1, CARTES-PERSO-1, CLASSE-FORM-1, DISPO-1, REMPL-1, HU-1, TH-2, LG-1.
- Voies tenues par d'autres sessions : COM-*, FI-*, TB-*. CPT-COM attend COM-FUS.
- Artefact public de la planche HL-A-5 : encore à 15 écrans (l'écran 16 est dans les fichiers, pas publié).

## 6. Incidents de la nuit

- Redémarrage du conteneur vers 22 h 45 UTC : 13 agents coupés, tous repris depuis leur disque sans perte. Cause probable : mémoire saturée par les analyses en parallèle ; règle ajoutée (toute analyse et tout test sous un verrou unique).
- `git stash` partagé entre dossiers de travail : une remise d'un agent récupérée par deux autres ; interdit depuis.
- Trois messages de commit portent un nom de modèle d'IA autre que la ligne imposée (déjà poussés, non réécrits).
