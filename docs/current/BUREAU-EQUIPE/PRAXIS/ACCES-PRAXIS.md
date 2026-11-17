# Praxis : la table des accès (étape 3 de `CHECKLIST-PRAXIS.md`)

Écrit par le pilote le 16/11/2026, à 22 h 40 UTC, d'après un relevé du dépôt (`main`, migrations et fonctions Edge).
Rien n'a été lu en production. `SECURITE-PRAXIS.md` prévaut sur ce document.

Directeur, 16/11 : « n'oublie pas de lui permettre de faire tout ça […] tu n'as pas besoin de tout coder, c'est juste
des accès ».

## 1. Le constat qui décide de l'architecture

- **Toutes les fonctions existantes décident à partir de `auth.uid()`**, c'est-à-dire d'une personne connectée :
  - `com_envoyer_message` passe par `private.com_appelant_msg()` ;
  - les annonces passent par `private.com_annonce_direction_appelante()` ;
  - les candidatures passent par la garde `admin` ou une mission (#565).
  - Il n'existe aucune version « système ».
- Or Praxis **n'a jamais de jeton de personne** (R3). Lui en donner un ferait de lui un administrateur connecté, avec
  tout ce que l'administration peut faire. **C'est refusé.**
- Le jeton `rag_…` existant (rôle `agent_ro`) ne sait que lire, et seulement l'écran de la personne observée. Il ne
  peut pas écrire.
- **Beaucoup de fonctions de la direction rendent des données que Praxis ne doit pas voir** (R5) : le contact, les
  pièces et la photo d'un dossier, les montants, les données des enfants. Les rebrancher telles quelles ferait fuir
  ces données.

## 2. La décision (arbitrage du pilote, 16/11/2026, consigne 22)

1. **Les accès de Praxis sont des missions** (modèle #565, installé ce soir). La direction coche des gestes et un
   périmètre pour le compte Praxis, et peut les retirer. Ajouter une tâche à Praxis revient à cocher un geste, sans
   écrire de code, chaque fois qu'une porte existe.
2. **Une porte par domaine, pas une par fonction.** Le connecteur a un petit nombre d'outils :
   - `lire(vue, filtre)` : la vue est prise dans une **liste fermée côté serveur**. Chaque vue appelle une fonction
     interne existante et ne rend que des champs autorisés (prénom, rôle, côté, étape, dates, compteurs) ;
   - `agir(geste, cible, cle)` : niveau A seulement. Le geste doit être coché dans une mission de Praxis, sinon le
     serveur refuse ;
   - `preparer(geste, cible, proposition)` : niveau B. Praxis écrit une **proposition** qu'un humain valide d'un geste.
     Rien n'est exécuté sans cette validation ;
   - plus les outils des messages de PX-1 (`boite`, `fil`, `ecrire`, `annoncer`, `etat`, `rendre_compte`,
     `alerter_responsable`).
3. **Le code est limité à ceci** :
   - extraire de chaque fonction existante sa logique interne, avec l'auteur passé en paramètre (`private.*_interne`,
     une seule logique pour les humains et pour Praxis, jamais une copie) ;
   - une couche de masquage par vue ;
   - les fonctions qui n'existent pas encore (§3, colonne « Manque »).
4. **Les enfants** : `private.com_est_mineur(uuid)` existe déjà. Faute de preuve, il considère la personne comme
   mineure (`student_profiles.student_type`, valeur par défaut `minor`), ce qui correspond à `SECURITE-PRAXIS.md`
   §3.1. PX-1 l'utilise, il n'en écrit pas un second.
5. **La double authentification** : les fonctions `admin` relevées ne l'exigent pas (seul le contrôleur l'exige
   parfois). C'est sans effet pour Praxis, qui n'a pas de jeton. Mais toute porte qui donne un accès à Praxis (clés,
   missions de Praxis, réglages) exige `aal2` (R10).

## 3. Les 21 domaines : ce qui existe, ce que Praxis en reçoit, ce qui manque

« admin » : `app_role() = 'admin' AND app_account_valid()`. Les noms de fichiers sont ceux de la dernière migration
qui définit la fonction (relevé à vérifier au cas par cas avant chaque lot).

| § | Domaine | Niveau | Existe déjà | Ce que Praxis en reçoit | Manque | Lot |
| :-: | :--- | :-: | :--- | :--- | :--- | :-: |
| 4.1 | Messages | A | `com_lister_fils`, `com_lire_fil`, `com_envoyer_message`, `com_marquer_lu` (logique `private.com_appelant_msg`, 20261119400100) | `boite`, `fil`, `ecrire`, sans les fils avec un mineur | Une fonction interne d'envoi avec un auteur explicite ; l'indication « secrétaire » dans la trace | PX-1 |
| 4.11 | Annonces et calendrier | A | `com_annonce_envoyer`, `com_annonce_publics`, `com_annonce_audience`, `private.com_annonce_distribuer` (20261126900000) ; `calendrier_ecole_*` (20261123910000) | `annoncer` (publics sans mineurs), `calendrier_annonces` | Table du calendrier des annonces ; rappels de paiement ciblés (montants jamais rendus) | PX-1 |
| 4.21 | Rapports | A | `indicateurs_admin()`, `com_annonces_direction()` | `rendre_compte` | Le point du matin, le rapport « secrétaire » | PX-1 puis PX-5 |
| 4.2 | Recrutement | B | `lister_candidatures`, `lire_candidature`, gestes de candidature ouverts aux missions (#565) | `lire('candidatures')` sans contact, pièce ni photo ; `preparer` pour un complément ou un créneau | Masquage par vue ; table des propositions | PX-2 |
| 4.13 | Accueil, liste d'attente | A | `lister_demandes_admission`, `suivi_attente_foyer` (famille) | `lire('demandes')` sans contact | La liste « qui prévenir quand une place s'ouvre » | PX-2 |
| 4.3 | Classes, matching | B | `enseignants_pour_classe`, `eleves_proposables_classe`, `eleves_sans_enseignant`, `creer_classe_creneaux_admin` | `lire('places')` en compteurs ; `preparer('creer_classe')` | Le moteur qui rapproche les besoins et les ressources | PX-4 |
| 4.4 | Élèves et familles | A/B | `indicateurs_admin`, `eleves_sans_etape` | Compteurs seulement (enfants : `SECURITE-PRAXIS` §3.6) | La détection du décrochage ; la règle écrite pour les données d'enfant | PX-5, après décision écrite |
| 4.5 | Séances | A/C | `lister_incidents_seances`, `lister_planning_direction`, `remplacements_direction`, `etat_presence` | `lire('incidents')`, `lire('remplacements')` | Le rapport par enseignant | PX-5 |
| 4.6 | Objectifs, check-listes (Studio) | A | Rien | — | Tout : tables, portes, écran | PX-3 avec le Studio |
| 4.7 | Anticiper | C | `etat_file_courriels`, `lister_creneaux_entretien`, `eleves_sans_enseignant` | `lire('risques')` | La vue des risques en un seul endroit | PX-5 |
| 4.8 | Technique | C | Rien en SQL | — | La lecture des journaux (hors base) | Plus tard |
| 4.9 | Argent | C | `releve_paie_mensuel`, `versements_paie_direction`, `finance_validations_lister` | **Rien en PX-1 à PX-4.** Plus tard, des totaux seulement, jamais par personne | La lecture seule des impayés en totaux | Après décision du directeur |
| 4.10 | Marketing | C/B | `indicateurs_admin`, `pilotage_admin_page` | Compteurs | Les chiffres de provenance et d'abandon par étape | PX-5 |
| 4.12 | Produit | C | Rien | — | — | Plus tard |
| 4.14 | Aide aux personnes | A | Rien (les guides n'existent pas) | — | Les guides, comme données de `savoir-rewayah` | PX-0 (compétences) |
| 4.15 | Qualité des données | A/B | `library_mineurs_sans_cohorte`, `eleves_sans_etape`, `lister_rapprochements_candidats` | Compteurs et identifiants, jamais de contact | La détection des doublons | PX-5 |
| 4.16 | Droit, conformité | C | `demandes_suppression_lister`, `traiter_demande_suppression` | **Rien** (une suppression est de niveau D) | Le suivi des échéances (rétractation, consentements) | Plus tard |
| 4.17 | Équipe, formation | A | `personnel_entretiens`, `demandes_formation_depassees` | Compteurs, rappels | Le suivi de la charge | PX-3 |
| 4.18 | Avis | C | `avis_lister_admin`, `avis_lien_creer` | Lecture des avis publiés seulement | — | PX-5 |
| 4.19 | Coûts, limites | C | `etat_file_courriels` | `lire('limites')` | La base, l'hébergement, la visio | Plus tard |
| 4.20 | Mémoire, pilotage | A | `journal_audit` | Son propre journal seulement (`rendre_compte`) | Le registre des décisions | PX-3 |

## 4. Ce que ce relevé change dans PX-1 (transmis à BE-PIECE le 16/11, 22 h 40)

- Écrire par une **fonction interne commune** (`private.com_envoyer_message_interne(auteur, fil, texte, cle)`, ou le
  nom en usage), appelée par `com_envoyer_message`, qui reste inchangé pour les humains, et par `praxis_ecrire`. La
  logique des paires (`private.com_paires`) et les effets (non-lus, notifications) restent les mêmes. Aucune copie.
- Même chose pour les annonces : `private.com_annonce_distribuer` existe ; la publication se fait par une fonction
  interne avec un auteur explicite.
- Les mineurs : `private.com_est_mineur(uuid)`, tel quel.
- Aucune vue `lire`, ni `agir`, ni `preparer` en PX-1 : elles viennent avec PX-2.
