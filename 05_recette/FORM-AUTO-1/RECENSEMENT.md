# FORM-AUTO-1 : recensement des formulaires (règle K-57)

Périmètre : `D:\RA_TUTEUR\c1-adm3\lib` (lecture seule ; `lib/features/_dev` et `lib/features/demo` ignorés).
Règle K-57 : préremplir (déduit) > proposer (liste, sélecteur, puces) > saisir au clavier en dernier recours.

## 1. Méthode, nombres clés

**Méthode.** Recherche par motif de `TextField`, `TextFormField`, `DropdownButton*`, `Switch`, `Checkbox*`, `Radio`, `SegmentedButton`, `ChoiceCardGroup`, `ControleSegmente`, `SelecteurSection`, `FilterPill`, `showDatePicker`, `showTimePicker`, `showModalBottomSheet` dans `lib/`. Lecture du contexte de chaque occurrence. Les sources de données citées (providers, services) ont été retrouvées dans `lib/core` ; ce qui n'a pas pu être vérifié est marqué « à vérifier ».

**Constats de structure.**
- Aucun `showDatePicker`, `showTimePicker`, `DropdownButton`, `TextFormField`, `Form` dans `lib/` hors `_dev` : l'application ne saisit pas de date autrement qu'au clavier (voir A8).
- Le sélecteur commun est `ChoiceCardGroup` (`core/widgets/choice_card_group.dart:80`). Par défaut il ajoute une carte « Autre » et un champ libre (`autoriserSaisieLibre = true`, `choice_card_group.dart:86`, champ en `:220`). Une quinzaine d'usages le désactivent (`false`).
- Les « modifications de valeur » (feuilles préremplies avec la valeur courante) sont comptées comme un champ saisi : la valeur modifiée est tapée.

**Conventions de comptage.**
- « Avant » = nombre de `TextField` de saisie (hors recherches), facultatifs compris.
- « Après » = nombre restant si l'on applique les conversions **sûres** (sources de données déjà dans l'app, pas de décision produit à prendre). Les conversions « potentielles » (qui exigent une décision ou un contrat) ne sont pas décomptées ; elles sont signalées dans la colonne Gain.
- Les recherches (7 champs, section 7) sont une lecture, pas un formulaire : hors total.

**Nombres clés.**
| Mesure | Valeur |
|---|---|
| Formulaires ou feuilles de saisie recensés | 40 (dont 7 sans aucun clavier, déjà conformes) |
| Champs saisis au clavier, avant | **73** |
| Champs saisis au clavier, après conversions sûres | **36** (gain 37, soit -51 %) |
| Idem hors les 13 feuilles de configuration à valeur entière (A14, non converties par prudence) | 60 avant, 23 après (-62 %) |
| Champs de recherche (hors total) | 7 |
| Élève, élève adulte, accessibilité | un seul champ clavier côté élève : le code d'appairage (X4). L'accessibilité et le foyer sont en interrupteurs (conformes). |

**Totaux par rôle.**
| Rôle | Formulaires | Saisis avant | Saisis après |
|---|---|---|---|
| Tuteur, foyer, parent | 8 | 7 | 3 |
| Connexion, inscription, élève | 5 | 6 | 5 |
| Enseignant | 8 | 12 | 5 |
| Contrôleur | 4 | 3 | 3 |
| Admin | 15 | 45 | 20 |
| **Total** | **40** | **73** | **36** |

**Renvois (non refaits ici).**
- **CLASSE-FORM-1** (création de classe) et **DISPO-1** (disponibilités enseignant) : leur conception n'est pas refaite. Je n'ai pas retrouvé les documents de ces étapes dans `pilotage-git` (recherche de la chaîne exacte : seules des mentions de vocabulaire sortent, `D:\RA_TUTEUR\pilotage-git\17_finance\ECARTS_MAQUETTES_08_10.md:25` et `UX_REVIEW_08_FINANCE.md:283`, « le mot groupe devient classe »). Ce recensement ne décrit donc que l'état du code, champ par champ, pour qu'elles s'y rattachent.
- Convention de colonnes : **Type** = déduit / choisi / saisi ; **Gain** = ce que la conversion retire du clavier.

---

## 2. Création de classe et disponibilités (déjà en étapes : CLASSE-FORM-1, DISPO-1)

### A1. Création d'une classe (admin) , renvoi CLASSE-FORM-1
Écran : `lib/features/admin_groupes/groupes_page.dart:386` (`_FeuilleCreation`), route `/admin/operations/groupes` (`core/router/routes.dart:389`). L'écran et ses libellés disent encore « groupe » (`t.admin.groupes.*`).

| Champ | Fichier:ligne | Type actuel | Déductible ou proposable ? | Gain |
|---|---|---|---|---|
| Libellé (`champLibelle`) | `groupes_page.dart:442` | saisi | Généré depuis type + niveau + créneau, modifiable. Potentiel : dépend de la règle de nommage (CLASSE-FORM-1). | potentiel -1 |
| Enseignant (`champEnseignantId`) : un **identifiant** tapé à la main | `groupes_page.dart:448` | saisi (UUID) | Liste d'enseignants. Source : `ServiceComptes.comptes()` (`core/admin/service_comptes.dart:163`, chaque `CompteAdmin` porte `role`, `:58`) filtré enseignant ; ou `enseignantsPourProvider` (`core/matching/service_attribution.dart:286`). | -1 (lot L2) |
| Type de public | `groupes_page.dart:460` (`FilterPill`) | choisi | déjà conforme | 0 |
| Jour (`champJour`, entier 1 à 7) | `groupes_page.dart:471` | saisi (défaut '1', `:389`) | Grille de la semaine `GrilleSemaine` (`disponibilites/grille_semaine.dart:25`), restreinte aux cases posées par l'enseignant choisi (`disponibilitesProvider`, voir DISPO-1) | -1 (L3) |
| Heure (`champHeure`, entier) | `groupes_page.dart:481` | saisi (défaut '16', `:390`) | même grille que le jour : le couple jour-heure est un seul `Creneau` | -1 (L3) |
| Seuil max (`champSeuil`) | `groupes_page.dart:492` | saisi (vide, `:391`) | Prérempli avec la règle de la plateforme `max_participants_per_session` ou `max_students_per_teacher` (`admin_configuration_fonctionnalites/fonctionnalites_page.dart:95`, `admin_configuration_regles/regles_page.dart:107`), pas de ±1 | -1 (L3) |
| Fuseau | `groupes_page.dart:421` | **codé en dur** `'Europe/Paris'` | Déduire du fuseau de l'enseignant (`monFuseauProvider`, `disponibilites_page.dart:32`). Correction de fond, pas un champ. | 0 (correctif) |

Total : saisis avant 5 (libellé, enseignant, jour, heure, seuil), après 1 (libellé ; potentiel 0). Serveur : non (RPC `creer` inchangée, `service_groupes.dart:179`).

### T4. Disponibilités du foyer, par enfant (tuteur) , renvoi DISPO-1
`lib/features/disponibilites/disponibilites_page.dart:22` (`TUT-04`), route `/tuteur/disponibilites` (`routes.dart:168`). Composant `GrilleSemaine` (`grille_semaine.dart:25`), « on tape une case, elle bascule, aucune saisie d'heures » (`grille_semaine.dart:22`).

| Champ | Fichier:ligne | Type | Gain |
|---|---|---|---|
| Cases jour-heure | `grille_semaine.dart:66` | choisi | 0 |
| Fuseau (affiché) | `disponibilites_page.dart:32` | déduit (`monFuseauProvider`) | 0 |

Total : 0 saisi avant, 0 après. Conforme K-57.

### E7. Disponibilités de l'enseignant (ENS-06)
`lib/features/creneaux/creneaux_page.dart:33`, route `/enseignant/creneaux` (`routes.dart:287`). Même `GrilleSemaine` (`creneaux_page.dart:287`), fuseau déduit (`:289`). Le bouton « ajouter un créneau » ouvre la grille (`:277`).

Total : 0 saisi avant, 0 après. Conforme K-57 ; le reste relève de DISPO-1.

---

## 3. Tuteur, foyer, parent

| Id | Formulaire | Écran (fichier:ligne, route) | Champs | Avant | Après |
|---|---|---|---|---|---|
| T1 | Ajout d'un enfant | `foyer/formulaire_profil_eleve.dart:444` (`/tuteur/foyer/ajouter`, `routes.dart:110`) | voir ci-dessous | 3 | 1 |
| T2 | Inviter le conjoint ou la conjointe | `foyer/invitation_conjoint.dart:428` | voir ci-dessous | 3 | 2 |
| T3 | Demande de réglage d'un enfant | `reglages_enfant/reglages_enfant_page.dart:378` (`/tuteur/reglages`, `routes.dart:171`) | voir ci-dessous | 1 | 0 |
| T4 | Disponibilités | `disponibilites/disponibilites_page.dart:22` | section 2 | 0 | 0 |
| T5 | Recharge du foyer | `foyer/recharge_foyer.dart:397` (case par bénéficiaire), `:483` (offre, `autoriserSaisieLibre: false`) | choisi | 0 | 0 |
| T6 | Parcours d'offres (6 questions) | `parcours_offres/parcours_offres_page.dart:413, 452, 504, 533, 563, 600` (`/tuteur/parcours`, `routes.dart:159`) | tout en cartes, sans champ libre ; le fuseau est suggéré depuis l'appareil (`:477`) ; le « pour qui » vient de l'apprenant | 0 | 0 |
| T7 | Compte, préférences, fiche enfant, accessibilité | `compte/compte_page.dart:297, 307, 319, 374, 384, 400, 409` (Switch), `compte/apparence_page.dart:60` (`SelecteurTheme`), `foyer/fiche/camera_page.dart:114`, `foyer/fiche/interface_page.dart:116`, `accueil_eleve/mon_espace_accessibilite.dart:172` | interrupteurs et cartes | 0 | 0 |
| T8 | Consentement d'observation | `consentements/texte_observation.dart:97` (`CheckboxListTile`, jamais précochée par choix assumé, `:93`) | choisi | 0 | 0 |

### T1. Ajout d'un enfant
| Champ | Fichier:ligne | Type | Déductible ou proposable ? | Gain |
|---|---|---|---|---|
| Pour qui (enfant ou moi-même) | `formulaire_profil_eleve.dart:400` | choisi | déjà conforme | 0 |
| Prénom (`foyer.ajout.identite.prenom`) | `:488` | saisi | Inévitable pour un enfant. Si « moi-même » : prénom déjà connu du compte (inscription, `inscription/etapes/identite_etape.dart:55`) : à vérifier que le profil adulte est lisible ici. | 0 (potentiel -1 pour « moi-même ») |
| Nom (`identite.nom`) | `:504` | saisi | Préremplir avec le nom de famille du tuteur : le libellé d'aide `nomAide` (`:514`) montre que la question « même nom ? » se pose déjà. Source : nom saisi à l'inscription (`identite_etape.dart:55`). | -1 |
| Âge (`identite.age`, chiffres, 3 max) | `:523` | saisi | Choix borné : puces ou sélecteur de pas entre `_bornes.min` et `_bornes.max` (`:456`, bornes déjà connues de l'écran). Les tranches d'âge existent côté serveur (`cohortes`, `parcours_offres_page.dart:422`). Le refus `ageHorsBornes` (`:386`) reste la garde finale. | -1 |

### T2. Invitation du conjoint
| Champ | Fichier:ligne | Type | Déductible ou proposable ? | Gain |
|---|---|---|---|---|
| Prénom (`adulte.invitation.prenom`) | `invitation_conjoint.dart:428` | saisi | inévitable | 0 |
| Nom (facultatif, `nomAide`) | `:442` | saisi | Puce « même nom que moi » (nom du tuteur connu) | -1 |
| Courriel | `:455` (`autofillHints.email`, `:463`) | saisi | inévitable (adresse d'une autre personne) | 0 |

### T3. Demande de réglage (durée de séance, par exemple)
| Champ | Fichier:ligne | Type | Déductible ou proposable ? | Gain |
|---|---|---|---|---|
| Valeur (minutes) | `reglages_enfant_page.dart:378`, options `dureesProposees = 30, 45, 60, 90` (`:298`) | choisi, mais la carte « Autre » ouvre un champ libre (défaut `true`, `:388` lit `saisieLibre`) | Garder les propositions ; le libre reste un dernier recours | 0 |
| Motif (`tuteur.reglages.demandeMotif`, requis, `:405`) | `:398` | saisi | Puces de motifs courants + « Autre » (lot L1) | -1 |

---

## 4. Connexion, inscription, élève

| Id | Formulaire | Écran (fichier:ligne, route) | Champs | Avant | Après |
|---|---|---|---|---|---|
| X1 | Inscription, identité | `inscription/etapes/identite_etape.dart:83, 96` (`/inscription/identite`, `routes.dart:49`) | prénom, nom | 2 | 2 (potentiel 0) |
| X1b | Inscription, usage et genre | `inscription/etapes/usage_etape.dart:55`, `genre_etape.dart:43` (`autoriserSaisieLibre: false`) | choisi | 0 | 0 |
| X2 | Connexion par courriel | `connexion/connexion_page.dart:352` (`/connexion`, `routes.dart:15`) | courriel ; mot de passe seulement en démo (`:365`, ignoré) | 1 | 1 (potentiel 0) |
| X3 | Récupération d'accès | `connexion/recuperation_page.dart:345` (`/connexion/recuperation`, `routes.dart:32`) | courriel | 1 | 0 |
| X4 | Connexion de l'élève par code | `eleve_connexion/saisie_code_page.dart:312` (`/connexion/eleve/code`, `routes.dart:29`) | code d'appairage | 1 | 1 (potentiel 0) |
| X5 | Entrée d'un agent | `agent_entree/agent_entree_page.dart:68` (`/agent`, `routes.dart:477`) | jeton | 1 | 1 |

| Champ | Fichier:ligne | Type | Déductible ou proposable ? | Gain |
|---|---|---|---|---|
| X1 prénom, nom | `identite_etape.dart:83, 96` | saisi | La page lit déjà un brouillon (`:34-35`). Avec la connexion Google (`connexion_page.dart:406`), prénom et nom peuvent venir du fournisseur : **à vérifier** (métadonnées OAuth disponibles dans la session ?). Avec le lien courriel, rien à déduire. | potentiel -2 (Google) |
| X2 courriel | `connexion_page.dart:352` | saisi (`autofillHints` déjà posés, `:361`) | Mémoriser le dernier courriel utilisé sur l'appareil, en puce. Réserve : appareil partagé. | potentiel -1 |
| X3 courriel | `recuperation_page.dart:345` | saisi, alors que l'usager vient de l'écran de connexion qui l'a déjà | Passer le courriel déjà tapé (paramètre de navigation) | -1 |
| X4 code | `saisie_code_page.dart:312`, formateurs `:322`, **un `scanner` existe déjà** (`:295`) | saisi | Faire du scan (ou du lien profond) le chemin d'abord proposé ; la saisie reste le dernier recours. Déjà proche de K-57. | potentiel -1 |
| X5 jeton | `agent_entree_page.dart:68` | saisi | Secret à coller : exempt. | 0 |

---

## 5. Enseignant

| Id | Formulaire | Écran (fichier:ligne, route) | Avant | Après |
|---|---|---|---|---|
| E1 | Cahier de séance, ajustement | `cahier/cahier_page.dart:301` (reprise), `:1106` (objectif), `:1149` (devoir) | 3 | 2 |
| E2 | Correction de présence | `presence_correction/presence_correction_page.dart:297` | 1 | 0 |
| E3 | Signalement d'un besoin d'élève | `fiche_groupe/fiche_eleve_enseignant.dart:557, 576` | 2 | 1 |
| E4 | Post-cours | `tc_flux_academique/panneau_post_cours.dart:118` | 1 | 1 |
| E5 | Signalement de séance | `tc_flux_academique/feuille_signalement.dart:133, 152` | 2 | 1 |
| E6 | Profil enseignant (pays, langues) | `profil_enseignant/profil_enseignant_page.dart:557` via `_editer` (`:469`, `:487`), route `/enseignant/profil` (`routes.dart:290`) | 2 | 0 |
| E7 | Disponibilités | section 2 | 0 | 0 |
| E8 | Dépôt de pièce d'identité (K-47 : seul l'enseignant en dépose une, `identite_etape.dart:69`) | `dossier/depot_piece_page.dart:168` (`/attente/piece`, `routes.dart:70`) | 1 | 0 |

| Champ | Fichier:ligne | Type | Déductible ou proposable ? | Gain |
|---|---|---|---|---|
| E1 Position de reprise (`enseignant.cahier.reprise`) | `cahier_page.dart:301` | **déduit en partie** : prérempli par `repriseProposee` (`:174-185`) si une proposition existe, sinon saisi | Sélecteur sourate + verset (`PositionLecture`, `:179`), réutilisant la feuille Coran `tc_mushaf/navigation_coran_feuille.dart` | -1 |
| E1 Objectif personnel | `cahier_page.dart:1106` | prérempli par la décision existante (`:882`), sinon saisi | Puces d'objectifs : **aucun catalogue n'existe** (commentaire `cahier_page.dart:1088-1092`), donc décision préalable | potentiel -1 |
| E1 Devoir à la maison | `cahier_page.dart:1149` | prérempli par suggestion (`:1129`, `:885`) | Alimenter la suggestion avec `travailPropose` (déjà calculé pour le post-cours, `panneau_post_cours.dart:114`) | potentiel -1 |
| E1 Faiblesses, suite, phonétique, performance | `cahier_page.dart:998, 1016, 1075` ; `emplacement_evaluation.dart:53` | choisi (la phonétique garde « Autre » libre, `:1075`) | conforme | 0 |
| E2 Motif (requis, `:311`) | `presence_correction_page.dart:297` | saisi | Puces de motifs + « Autre » (L1) | -1 |
| E3 Catégorie | `fiche_eleve_enseignant.dart:523` (radio) | choisi | conforme | 0 |
| E3 Détails (requis, `_validerDetails`, `:528`) | `:557` | saisi | Texte sensible : reste saisi | 0 |
| E3 Résumé (`signalement.resume`) | `:576` | saisi | Prérempli depuis catégorie + prénom + classe (`:502-505` montrent que le contexte est déjà connu), modifiable | -1 |
| E4 Notes d'exception (facultatives) | `panneau_post_cours.dart:118` | saisi, en dernier, facultatif | **Écran modèle** : « ce que le système sait » (`:100`), « propose » (`:111`), « ajoute » (`:117`). Aucun changement. | 0 |
| E5 Catégorie | `feuille_signalement.dart:116` | choisi | conforme | 0 |
| E5 Note interne (requise, `:138`) | `:133` | saisi | Reste saisi (jugement) | 0 |
| E5 Message à la famille | `:152` | saisi | Phrase-type bienveillante par catégorie (`libelleCategorieSignalement`, `:126`), à valider par le directeur | -1 |
| E5 Retour de séance (`carte_feedback_seance.dart:74`) | | choisi, sans champ libre | conforme | 0 |
| E6 Pays | `profil_enseignant_page.dart:469` (valeur en texte libre) | saisi | Liste de pays, présélectionnée depuis le fuseau (`monFuseauProvider`, `:445`) | -1 |
| E6 Langues (texte séparé par des virgules, `:522`) | `:487` | saisi | Choix multiple sur `languesCoursProvider` (`core/offres/service_offres.dart:227`). **Attention** : le profil stocke aujourd'hui du texte libre ; passer à des codes changerait le contrat `declarer(langues:)` (`:492`), donc possiblement serveur. | -1 (serveur possible) |
| E8 Type de pièce (carte « Autre ») | `depot_piece_page.dart:168` | choisi, **mais** `autoriserSaisieLibre` reste à `true` : la carte « Autre » ouvre un champ (`choice_card_group.dart:216`) dont le contenu n'est jamais lu (`depot_piece_page.dart:183-193` ne regarde que `valeurs`) | Passer `autoriserSaisieLibre: false` et ajouter une option explicite `TypePiece.autre`. **À confirmer à l'exécution** (lecture statique). | -1 |

---

## 6. Contrôleur

| Id | Formulaire | Écran (fichier:ligne, route) | Champs | Avant | Après |
|---|---|---|---|---|---|
| C1 | Observation de contrôle | `controleur/observation_controle_page.dart:517` (`/controleur`, `routes.dart:337`) | texte (requis, 4 à 8 lignes). Personne concernée (`:385, :422`), élève du roster (`:489`, liste déjà chargée) : choisis. | 1 | 1 |
| C2 | Complément de rapport | `controleur/complement_rapport_page.dart:273` | texte ; motif choisi (`:244`) | 1 | 1 |
| C3 | Compte rendu de contrôle | `controleur/compte_rendu_controle_page.dart:257` (`/controleur/compte-rendu`, `routes.dart:361`) | choisi ; faits automatiques déjà en tête (`:238`) | 0 | 0 |
| C4 | Échanges | `controleur/echanges_controleur_page.dart:144`, champ `core/widgets/fil_discussion.dart:391` | message libre | 1 | 1 |

Ce sont des jugements humains : le texte reste le dernier recours. Le modèle est déjà respecté (faits automatiques, puis cartes, puis texte). Piste sans décompte : préremplir C1 et C2 avec les faits automatiques (`_FaitsAutomatiques`).

---

## 7. Admin

| Id | Formulaire | Écran (fichier:ligne, route) | Avant | Après |
|---|---|---|---|---|
| A1 | Créer une classe | section 2 | 5 | 1 |
| A2 | Ajouter un élève à une classe | `admin_groupes/groupes_page.dart:627, 635` | 2 | 0 |
| A3 | Modifier le seuil d'une classe | `groupes_page.dart:720` | 1 | 0 |
| A4 | Retirer un élève, clore une classe (même `_FeuilleMotif`) | `groupes_page.dart:804` (usages `:312`, `:365`) | 2 | 0 |
| A5 | Attribution élève-enseignant, motif | `admin_attribution/attribution_page.dart:730` | 1 | 0 |
| A6 | Demandes : refus, poser une règle | `admin_demandes/demandes_page.dart:226` (refus), `:636` (valeur, **libre autorisé**), `:654` (motif) | 2 | 0 |
| A7a | Programme : ajouter un niveau | `admin_pedagogie_programmes/programmes_page.dart:598-626` (usage `:387`) | 5 | 2 |
| A7b | Programme : modifier un niveau | même composant (usage `:425`, `cycleInitial` `:427`, `ordreInitial` `:428`) | 4 | 2 |
| A8 | Évaluations : planifier, résultat, annuler | `admin_pedagogie_evaluations/evaluations_page.dart:390, 428` (planifier), `:553` (résultat), `:630` (annuler) | 4 | 1 |
| A9 | Progression : promouvoir, poser une exception | `admin_pedagogie_progression/progression_page.dart:405, 515` | 2 | 0 |
| A10 | Qualité : traiter une anomalie | `admin_pedagogie_qualite/qualite_page.dart:326` | 1 | 1 |
| A11 | Diagnostic : décider un placement | `admin_pedagogie_diagnostics/diagnostics_page.dart:269` | 1 | 0 |
| A12 | Dossiers : refuser | `admin_dossiers/surfaces_decision.dart:256` | 1 | 0 |
| A13 | Accès agents : créer un jeton | `admin_acces_agents/acces_agents_page.dart:257` | 1 | 0 |
| A14 | Configuration : valeurs entières (13 lignes) | `core/admin/config_edition.dart:158` ; 10 règles `regles_page.dart:159`, 2 conservation `conservation_donnees_page.dart:86, 98`, 1 fonctionnalité `fonctionnalites_page.dart:92` | 13 | 13 |

Routes admin connues : classes `/admin/operations/groupes`, demandes `/admin/operations/demandes` (`routes.dart:396`), programmes `/admin/pedagogie/programmes` (`:423`), qualité `/admin/pedagogie/qualite` (`:426`), règles `/admin/configuration/regles` (`:434`), dossiers `/admin/personnes/dossiers` (`:402`). Les autres écrans admin (attribution, évaluations, progression, diagnostics, accès agents, conservation, fonctionnalités) : route non retrouvée dans `routes.dart` par ma recherche.

| Champ | Fichier:ligne | Type | Déductible ou proposable ? | Gain |
|---|---|---|---|---|
| A2 Élève (`champEleveId`) : un **identifiant** tapé | `groupes_page.dart:627` | saisi (UUID) | Liste d'élèves : `elevesEnAttenteProvider` (`core/matching/service_matching.dart:246`), `ServiceProgression.tous()` (`core/admin/service_progression.dart:122`) ou comptes filtrés par rôle | -1 (L2) |
| A2, A4, A5, A6 (×2), A8 (annuler), A9 (×2), A11, A12 : **motif** requis | `groupes_page.dart:635, 804` ; `attribution_page.dart:730` ; `demandes_page.dart:226, 654` ; `evaluations_page.dart:630` ; `progression_page.dart:405, 515` ; `diagnostics_page.dart:269` ; `surfaces_decision.dart:256` | saisi, chacun avec son bouton inerte tant que vide | Puces de motifs par écran + « Autre » : 11 champs aujourd'hui, un même composant (L1). | -11 |
| A3 Seuil (prérempli avec la valeur courante, `:676`) | `groupes_page.dart:720` | saisi | Pas ±1 borné par l'effectif actuel | -1 (L3) |
| A6 Valeur de la règle | `demandes_page.dart:636`, propositions `FeuilleRegle.proposees` (`:537`) | choisi, « Autre » libre autorisé (défaut) | conforme (libre = dernier recours) | 0 |
| A7a Code technique | `programmes_page.dart:598` | saisi | Généré depuis le nom humain (identifiant technique jamais lu par l'usager) ; unicité contrôlée par `ajouterNiveau` (`service_programme.dart:178`) | -1 |
| A7a/b Nom humain | `:607` | saisi (modif : prérempli) | inévitable | 0 |
| A7a/b Cycle | `:613` | saisi (modif : prérempli, `:538`) | Puces des cycles déjà présents (`NiveauProgramme.cycle`, `service_programme.dart:156`, via `niveaux(versionId)`, `:171`) + « Nouveau cycle » | -1 par écran |
| A7a/b Ordre (entier) | `:619` | saisi (modif : prérempli, `:541`) | Déduit : dernier ordre du cycle + 1, ou pas ±1 | -1 par écran |
| A7a/b Description (facultative) | `:626` | saisi | reste | 0 |
| A8 Élève (planifier) | `evaluations_page.dart:390` | saisi (UUID) | Liste d'élèves (idem A2) | -1 (L2) |
| A8 Type, niveau | `:402`, `:416` (`_NiveauxVersion`) | choisi | conforme | 0 |
| A8 Date prévue : **JJ/MM/AAAA tapé** (`_lireDate`, `:266`) | `:428` | saisi | `showDatePicker` natif (aucun picker de date n'existe dans l'app) | -1 (L4) |
| A8 Résultat | `:545` (pastilles) | choisi | conforme | 0 |
| A8 Notes (facultatives) | `:553` | saisi | reste | 0 |
| A9 Niveau cible | `progression_page.dart:389` (`_NiveauxVersion`) | choisi | Présélectionner le niveau suivant (ordre + 1) : à vérifier que l'élève porte son niveau courant (`EleveProgression`, `service_progression.dart:33`) | 0 (confort) |
| A10 Note (facultative) | `qualite_page.dart:326` | saisi | reste facultative | 0 |
| A11 Niveau | `diagnostics_page.dart:254` (`SelecteurNiveauProgramme`) | choisi | Présélection depuis le niveau auto-déclaré à l'inscription (`NiveauDeclare`, `parcours_offres_page.dart:539`) : table de correspondance à fixer par la direction pédagogique | 0 (potentiel) |
| A13 Libellé du jeton (`admin.agents.libelle`, indice d'exemple `:264`) | `acces_agents_page.dart:257` | saisi | Généré : « Observation de <prénom>, <date> » depuis la personne choisie (`:285`) et la durée (`:296-318`) | -1 |
| A13 Recherche de personne | `:273` | saisi (filtre) | recherche, voir plus bas | n/a |
| A14 Valeur entière (13 lignes) | `config_edition.dart:158` | saisi, prérempli avec la valeur courante (`:120`) | Pas ± et puces. Les propositions n'existent que pour 4 clés (`demandes_page.dart:537`) ; pour les autres les valeurs sont à fixer par le directeur. **Non décompté.** | potentiel |

Interrupteurs admin conformes : `ConfigLigneBooleenne` (`config_edition.dart:249`, utilisé `fonctionnalites_page.dart:84`), `politique_revue_kyc_page.dart:136`.

### Recherches (7 champs, hors total)
`core/widgets/admin_shell.dart:674` et `:774` (même fonction, deux dispositions), `admin_observations/observations_admin_page.dart:565`, `admin_acces_agents/acces_agents_page.dart:273`, `tc_catalogue/surface_bibliotheque.dart:149`, `salle_seance/selecteur_ressources.dart:107`, `tc_mushaf/navigation_coran_feuille.dart:84`. Ce sont des lectures ; la seule piste utile est la navigation du Coran (sélecteur de sourate, voir L9), les autres sont déjà accompagnées de filtres en pastilles.

---

## 8. Conversions proposées, en lots de code

Effort : S = moins d'une demi-journée, M = une journée, L = plus. « Serveur » : si oui, démonstration seulement jusqu'à BR-1.

| Lot | Contenu | Champs retirés | Fichiers touchés | Effort | Serveur |
|---|---|---|---|---|---|
| **L1** | **Motifs en puces** : un composant `SelecteurMotif` (cartes i18n + « Autre » en dernier recours) qui remplace les champs motif. Écrans : T3, E2, A2, A4 (×2), A5, A6 (×2), A8 annuler, A9 (×2), A11, A12. | 13 | nouveau composant `core/widgets` ; `reglages_enfant_page.dart`, `presence_correction_page.dart`, `groupes_page.dart`, `attribution_page.dart`, `demandes_page.dart`, `evaluations_page.dart`, `progression_page.dart`, `diagnostics_page.dart`, `surfaces_decision.dart` ; i18n | M | Non : le motif reste une chaîne envoyée comme aujourd'hui. Réserve : le journal d'audit recevra des phrases-types dans la langue de l'écran (à confirmer avec le directeur). |
| **L2** | **Sélecteurs de personnes** (élève, enseignant) à la place des identifiants tapés : un composant de liste cherchable, nourri par `ServiceComptes.comptes()` filtré par `role`, `elevesEnAttenteProvider`, `ServiceProgression.tous()`. | 3 (A1 enseignant, A2 élève, A8 élève) | composant `core/widgets` ; `groupes_page.dart`, `evaluations_page.dart` | M | Non (lectures existantes). À vérifier : que les lectures admin rendent bien le rôle et le nom. |
| **L3** | **Création de classe : créneau et seuil** (renvoi CLASSE-FORM-1, DISPO-1). Grille `GrilleSemaine` pour jour et heure, restreinte aux cases de l'enseignant ; seuil prérempli par la règle de la plateforme ; fuseau pris de l'enseignant au lieu de `'Europe/Paris'` ; pas ±1 pour le seuil de A3 ; vocabulaire « classe » (A6 de `ECARTS_MAQUETTES_08_10`). | 4 (jour, heure, seuil de A1, seuil de A3) | `groupes_page.dart`, `grille_semaine.dart` (paramètre de restriction), i18n | M à L | Non (RPC `creer` et `modifier` inchangées). Dépend de L2. |
| **L5** | **Programme : cycle, ordre, code** (A7a, A7b). Cycle en puces des cycles existants, ordre = suivant, code généré du nom. | 5 | `programmes_page.dart` | S à M | Non (RPC `ajouterNiveau` inchangée ; l'unicité du code reste vérifiée côté serveur). |
| **L6** | **Foyer : nom et âge** (T1, T2). Nom prérempli avec le nom du tuteur (T1, T2) ; âge en puces ou sélecteur borné (T1) ; mêmes écrans, même famille de composants. | 3 | `formulaire_profil_eleve.dart`, `invitation_conjoint.dart` | S | Non (bornes déjà connues de l'écran ; le refus serveur reste la garde). |
| L4 | Date d'évaluation par `showDatePicker` (A8). | 1 | `evaluations_page.dart` | S | Non |
| L7 | Signalements enseignant : résumé prérempli (E3), message à la famille par catégorie (E5). | 2 | `fiche_eleve_enseignant.dart`, `feuille_signalement.dart`, i18n | M | Non ; les phrases-types sont à valider par le directeur. |
| L8 | Profil enseignant : pays en liste, langues en choix multiple (E6). | 2 | `profil_enseignant_page.dart` | S à M | **Possible** si les langues deviennent des codes (contrat `declarer`). Démonstration seulement jusqu'à BR-1 dans ce cas. |
| L9 | Cahier : reprise par sélecteur sourate-verset (E1), réutilise la feuille Coran. | 1 | `cahier_page.dart`, `navigation_coran_feuille.dart` | M | Non |
| L10 | Connexion et récupération : courriel transmis à l'écran de récupération (X3). Potentiels : prénom et nom du fournisseur Google (X1), dernier courriel (X2), scan d'abord (X4). | 1 sûr, 4 potentiels | `recuperation_page.dart`, `connexion_page.dart`, `identite_etape.dart`, `saisie_code_page.dart` | S | Non (X1 : vérifier les métadonnées OAuth) |
| L11 | Dépôt de pièce : supprimer la carte « Autre » à champ libre ignoré (E8). | 1 | `depot_piece_page.dart` | S (une ligne) | Non |
| L12 | Accès agents : libellé du jeton généré (A13). | 1 | `acces_agents_page.dart` | S | Non |
| L13 | Configuration : pas et puces pour les 13 valeurs entières (A14). | 0 (potentiel 13) | `config_edition.dart` + 3 pages | M | Non ; valeurs à fixer par le directeur. À traiter en dernier. |

**Ordre recommandé.** L1, L2, L3, L5, L6 (en tête, 28 champs sur 37), puis L4, L11, L12, L10, L7, L9, L8, L13.

**Vérification du compte.** Gains : L1 13 + L2 3 + L3 4 + L4 1 + L5 5 + L6 3 + L7 2 + L8 2 + L9 1 + L10 1 + L11 1 + L12 1 = 37, soit les 73 moins 36 du tableau de la section 1.

## 9. Réserves

- Lecture statique : aucun écran n'a été lancé. Les points marqués « à vérifier » ou « à confirmer » exigent un passage à l'exécution (carte « Autre » du dépôt de pièce, rôle rendu par `comptes_admin()`, métadonnées OAuth).
- Les routes de certains écrans admin n'ont pas été retrouvées ; elles ne sont pas inventées.
- Les phrases-types et listes de motifs, de valeurs et de niveaux proposées ici sont à fournir ou valider par le directeur : le code ne contient pas ces listes aujourd'hui.
