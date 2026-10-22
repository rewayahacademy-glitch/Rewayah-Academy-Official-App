# Catalogue des écrans : Recrutement (module des candidatures)

Registre des écrans du module des candidatures, type `enseignant` d'abord.
Inscrit le 21 octobre 2026, **avant tout fichier `.dart`**, comme le demande la
section 10 de la spécification consolidée. Même format que les autres catalogues
de `docs/current/` : un registre, puis une fiche par écran. Révisé le même jour
après une relecture critique : les corrections retenues sont intégrées.

**Statut de tout le catalogue : proposé, à valider par le directeur.** Aucune fiche
n'est validée. Aucun écran n'est construit. Les écrans se construisent un par un,
sur son ordre explicite.

**Deux noms changent.** Les autres catalogues ont une colonne « Rôle ». Ici elle
s'appelle « Capacité » : l'écran lit une capacité rendue par le serveur, jamais un
rôle (`/CLAUDE.md:41`, « Un widget lit une capacité, jamais un rôle. » ;
`C/02_ARCHITECTURE_ET_SECURITE.md:7`, « autorisation par capacité et état de
compte »). Dans chaque fiche, le champ qui dit qui voit l'écran s'appelle
« Droits (capacité) », nom de `CONS` section 10 et de la fiche `ADM-PAI`
(`C/CATALOGUE_ECRANS_DIRECTION.md`).

## 1. Sources

| Sigle | Fichier | Ce qu'il donne ici |
| :--- | :--- | :--- |
| `CONS` | `docs/current/CANDIDATURES/SPEC_CONSOLIDEE_CANDIDATURES_2026-10-21.md` | **la référence** : écrans (section 10), règles (sections 2 à 9), lots (section 11), recette (section 12) |
| `DEC` | `docs/current/DECISION-CANDIDATURES-2026-10-21.md` | les 22 réponses du directeur ; `DEC:37` renvoie à la ligne 37 |
| `PORTS` | `docs/current/CANDIDATURES/CONTRAT_PORTS_CANDIDATURES.md` | méthodes de port, erreurs, formes de données (à mettre à jour selon `CONS` 0.1 et selon les méthodes que ce catalogue demande) |
| `REVUE` | `docs/current/CANDIDATURES/REVUE_CRITIQUE_CANDIDATURES_2026-10-21.md`, section 10 | plan d'écrans, composants, états de la spec §11 |
| `ENTREE` | `docs/current/DECISION-ENTREE-2026-10-17.md` | cartes, bento sur grand écran, listes plutôt que saisie, accords |
| `TARIFS` | `docs/current/DECISION-TARIFS-2026-10-18.md` | part de l'enseignant, paie à l'élève présent |
| `GOV` | `docs/current/DESIGN-GOV-2026-09-26.md` | contrats A à E, `UX_REVIEW` |
| `UX` | `docs/current/03_DESIGN_SYSTEM_ET_UX.md` | états, « hors ligne se dit une seule fois », typographie |
| `MOTS` | `.claude/skills/mots-rewayah/SKILL.md` | vocabulaire |
| `LIB` | `lib/CLAUDE.md` | K-54 à K-59, composants partagés, interdits |

Quand une fiche et `CONS` diffèrent, `CONS` s'applique et la fiche se corrige.
`M/` vaut `supabase/migrations/`, `C/` vaut `docs/current/`.

## 2. Comment une fiche se valide

1. Le directeur lit une fiche et répond : validée, corrigée ou refusée. Sa réponse
   ne devient une décision qu'une fois versée ici, avec sa date (règle de `C/08` §1,
   rappelée par `C/CANDIDATURES/LIRE_D_ABORD.md`).
2. La fiche passe alors de « proposée » à « validée le … ». Une correction du
   directeur s'écrit dans la fiche elle-même.
3. Avant le code : `UX_REVIEW_CAND-<code>.md` (règle, source, date, conclusion,
   modification, `GOV` §4.2), puis la maquette et son contrôle (`SPEC §14`).
4. Le code s'écrit sur ordre explicite du directeur, **un écran à la fois**. Les
   mots du module entrent dans `MOTS` dans le commit de l'écran (`DEC:35`).
5. Un écran construit avant son lot serveur rend `CapaciteIndisponible('CAND-BR-nn')`
   en production, et il le dit. Sa route est déclarée dans le routeur unique : une
   adresse tapée montre la phrase de capacité indisponible, jamais une page vide.
   La démonstration (hors production, `PLAYGROUND=true`) porte des données
   fictives (`PORTS` §6). Jamais de donnée fictive en production.
6. La fiche passe à « construit (date) » avec ses tests et ses captures. Un critère
   non mesuré n'est pas coché ; on écrit le chiffre.

## 3. Registre

Colonnes : **Niv.** est le niveau de charge (A public, C adulte qui gère, E
opérateur ; `docs/archive/2026-09-pre-remise-a-plat/design/03-architecture-information.md`
§3). **Prof.** est la profondeur de navigation.

| Code | Écran | Capacité | Niv. | Prof. | Route | Mobile | Desktop | État |
| :--- | :--- | :--- | :-: | :-: | :--- | :--- | :--- | :--- |
| `CAND-04` (étend `TUT-00c`) | Inscription sans code | session sans profil ; ouverture lue au serveur | A puis C | 0 | `/connexion?mode=creer`, puis `/inscription/usage`, `/inscription/invitation`, `/inscription/telephone` (neuve) | Pages courtes (`CoquilleEtape` sur `PageEtape`) | Colonne bornée, cartes de choix en bento | **proposée** |
| `TUT-00b` étendu | Portail de la candidature | titulaire ; état rendu par `etat_dossier()` | C | 0 | `/attente` | Blocs empilés | Grille bento | **proposée** |
| `CAND-01` | Questionnaire de la Salle d'examen | titulaire ; `PortMaCandidature` | C | 1 | `/attente/candidature` (neuve) | Cartes par thème | Colonne bornée, choix en bento | **proposée** |
| `TUT-00c/a+b` étendu | Page d'accords | titulaire ; textes requis rendus par le serveur | C | 1 | `/attente/accords` | Une page qui défile | Colonne bornée | **proposée** |
| `TUT-00c/c` étendu | Dépôt de la pièce | titulaire ; ouverture rendue par `etat_dossier()` | C | 1 | `/attente/piece` | Page existante | Colonne bornée | **proposée** (fiche ajoutée à la révision) |
| `CAND-02` | Mon entretien | titulaire convoqué | C | 1 | `/attente/entretien` (neuve) ; tuile du portail, sans bouton plein | Page | Page bornée | **proposée** |
| `CAND-03` | Retirer ma candidature | titulaire | C | 1 | aucune : confirmation posée sur `/attente` | Feuille basse | Boîte de dialogue | **proposée** |
| `CAND-05` | Écrire à l'académie | titulaire ; fil `candidature` | C | 1 | `/attente/messages` (neuve) | Fil seul | Fil seul, borné | **proposée** |
| `ENS-03` et `ELV-03`, mode entretien | Salle de l'entretien | candidat convoqué ; `entretiens.mener`, intervieweur désigné | C, E | 2 | `/salle` (billet en `extra`) | Salle existante | Salle existante | **proposée** |
| `ADM-20` | Candidatures | `candidatures.lire` | E | 1 | `/admin/personnes/candidatures` (neuve) | Cartes, barre de sélection basse | Tableau dense ; file et détail quand un dossier est ouvert, file seule en mode sélection | **proposée** |
| `ADM-20E` | Entretiens | `candidatures.lire` ; rejoindre : intervieweur désigné | E | 1 | `/admin/personnes/candidatures?vue=entretiens` | Cartes par date | Tableau par date | **proposée** (code ajouté ici) |
| `ADM-21` | Candidature | `candidatures.lire` ; gestes `candidatures.decider` | E | 2 | `/admin/personnes/candidatures/<référence>` | Page, sections empilées | Détail 728 à côté de la file ; deux colonnes seul | **proposée** |
| `ADM-21F` | Fil « Candidature » | `candidatures.messages` | E | 3 | `/admin/personnes/candidatures/<référence>/fil` | Fil seul | Fil seul | **proposée** |
| `ADM-21R` | Compte rendu d'entretien | `entretiens.mener`, intervieweur désigné | E | 3 | `/admin/personnes/candidatures/<référence>/compte-rendu` | Tâche focalisée | Formulaire borné | **proposée** (écran ajouté ici) |
| `ADM-22` | Action groupée | `candidatures.decider` | E | 2 | `/admin/personnes/candidatures/action-groupee` | Page | Page, liste et effet côte à côte | **proposée** |
| `ADM-23` | Import des formulaires | `candidatures.importer` | E | 2 | `/admin/personnes/candidatures/import` | Pas l'un sous l'autre | Rail des pas au début, contenu à la fin | **proposée** |
| `ADM-24` | Compatibilité de paiement par pays (onglet « Versement par pays ») | `paiement.referentiel.ecrire` | E | 1 | `/admin/finance/paiement-pays` (neuve) | Cartes par pays | Tableau dense, fiche en boîte de dialogue | **proposée** |
| `ADM-02` étendu | Dossiers à valider | décision : `candidatures.decider`, sur un dossier que le serveur rend porteur d'une candidature | E | 1 | `/admin/personnes/dossiers` (inchangée) | Inchangé | Inchangé (336, 24, 728) | **proposée** |

**Codes.** Neufs, nommés par `CONS` section 10 : `CAND-01` à `CAND-05`, `ADM-20` à
`ADM-24`, `ADM-21F`. Ajoutés par ce catalogue, à valider : `ADM-20E` (la vue
Entretiens, que `CONS` range dans `ADM-20`) et `ADM-21R` (le compte rendu, que
`CONS` ne nomme pas, point `CAND-F07`). Étendus sans code neuf, avec leur code
existant : `TUT-00b` (`/attente`, `attente_page.dart:26`) ; `TUT-00c` (inscription,
`inscription_page.dart:19`) ; `TUT-00c/a+b` (la page d'accords, qui a réuni
l'accusé `TUT-00c/a` et le contrat `TUT-00c/b` le 17/10) ; `TUT-00c/c` (dépôt de
pièce) ; `ENS-03` et `ELV-03` (la salle, `salle_page.dart:68`) ; `ADM-02`. Codes
`TUT-00c/a`, `/b`, `/c` :
`C/sources-directeur-2026-10/REWAYAH_DOSSIER_MAITRE_SPECS_PRODUIT_COMPLET_2026-10-14.md:3825-3830`.
Vérifié le 21/10 : aucun code neuf n'existe dans `lib/`, `test/` ni `docs/current/`
hors du dossier `CANDIDATURES`. Le préfixe `REC-` est pris (`REVUE` §10).

**Une vue manque.** Aucun écran ne montre les réponses importées, d'où part
« Garder pour suivi » : point `CAND-F13`. Elle n'a ni code ni fiche ; rien ne se
construit avant sa fiche.

**Ordre des routes.** Les chemins statiques (`action-groupee`, `import`) se
déclarent avant `:reference` dans le routeur (contrainte R5, comme
`lib/core/router/routes.dart:182-184`).

## 4. L'existant que le module étend (lu le 21/10/2026)

| Existant | Où | Ce qui change | Fiche |
| :--- | :--- | :--- | :--- |
| Connexion en mode création | `lib/features/connexion/connexion_page.dart:80-88` (`?mode=creer`) | rien : c'est l'adresse du lien du site ; ses textes « Lien envoyé » servent de réponse neutre | `CAND-04` |
| Choix de l'usage | `lib/features/inscription/etapes/usage_etape.dart:63-92` (lien « J'ai un code d'invitation ») ; phrase `inscription.usage.enseignantInvite`, `:71` ; `routes.dart:48` ; `app_router.dart:318-321` | quand l'inscription sans code est ouverte, la phrase est remplacée et une entrée sans code s'ajoute | `CAND-04` |
| Code d'invitation | `lib/features/recrutement/invitation_candidat_page.dart:1-24` ; `routes.dart:59` ; `app_router.dart:322-327` | un lien vers l'entrée sans code | `CAND-04` |
| Étapes identité, genre, récapitulatif | `lib/features/inscription/etapes/` ; `routes.dart:50-67` ; liste unique `etapesInscription`, partagée par tous les usages, `lib/features/inscription/brouillon_inscription.dart:32-37` ; `CoquilleEtape`, `inscription_page.dart:93-140`, posée sur `PageEtape` (`lib/core/widgets/page_etape.dart`) | étape téléphone neuve, langue et confidentialité au récapitulatif, pour le seul parcours candidat ; genre obligatoire | `CAND-04` |
| Porte d'inscription | `lib/core/router/redirection.dart:144-147` | aucune : `/inscription/telephone` est dans le sous-arbre | `CAND-04` |
| Portail d'attente | `lib/features/dossier/attente_page.dart:26-41` (le statut et une prochaine action), `:201` (`_Prochaine`), `:281-380` (`_Statut`) ; `EtapeDossier`, « Les cinq etats du portail d'attente », `lib/core/dossier/etat_dossier.dart:216-233` ; `routes.dart:70` ; `app_router.dart:386-389` | états de la candidature | `TUT-00b` |
| Confinement du portail | `redirection.dart:153-174` : tout le sous-arbre `/attente` est ouvert à tout compte en attente, tuteur et comptable compris | les routes neuves du candidat vivent sous `/attente` ; chacune traite « aucune candidature » (5.1) | `CAND-01`, `CAND-02`, `CAND-05` |
| Dépôt de pièce | `lib/features/dossier/depot_piece_page.dart:33` ; `routes.dart:87` ; `app_router.dart:407-410` ; garde écrite sur le rôle, `redirection.dart:156-162` ; champ `pieceRequise`, `etat_dossier.dart:119` | ouvert en Salle de vérification et d'entretien seulement, garde lue dans `etat_dossier()` (`CAND-F09`) | `TUT-00c/c` |
| Page d'accords | `lib/features/dossier/accords_page.dart:85-104` (règle), `:224-230` (cases requises), `:404-406` (« Suivant ») ; `routes.dart:76` ; `app_router.dart:393-396` | case du cadre religieux ; textes de l'étape | `TUT-00c/a+b` |
| Onglets de Personnes | `lib/core/admin/admin_domaine.dart:269-293`, onglet Invitations `:273-277` | Invitations devient Candidatures | `ADM-20` |
| Page Invitations | `lib/features/admin_invitations/invitations_page.dart:126-129` (code montré), `:156-181` (`_revoquer`, avec `ConfirmDestructive`), `:191-200` (deux ports, enseignant et comptable), `:216` ; `routes.dart:717-718` ; `app_router.dart:1555-1561` | remplacée par `ADM-20` ; l'invitation du comptable et la révocation restent à placer (`CAND-F01`) | `ADM-20` |
| Import des inscriptions | `lib/features/admin_import_inscriptions/import_inscriptions_page.dart:1-25` ; `routes.dart:725` | modèle d'`ADM-23`, sur une route distincte | `ADM-23` |
| Dossiers à valider | `lib/features/admin_dossiers/dossiers_page.dart:32-34` (file et détail 336, 24, 728) ; décision fermée en production, `revue_dossier.dart:33-36` ; boutons `:432-441` | la validation fait entrer en Salle des prêts à enseigner ; deux issues de refus | `ADM-02` |
| Onglets de Finance | `admin_domaine.dart:203-215`, dont « Paiements » (paiements reçus des familles, `ADM-PAI`) `:214` ; `app_router.dart:1683-1724` | sixième onglet, « Versement par pays » | `ADM-24` |
| Messagerie métier | `lib/features/com_messages/fil_contextuel.dart:59` ; `TypeObjetLie`, `lib/core/communications/modeles_communication.dart:112` ; `filPourObjet`, `lib/features/com_messages/port_messages_metier.dart:212` ; précédent `CPT-12F` (`C/CATALOGUE_ECRANS_COMPTABLE.md:37`) | objet `candidature` | `CAND-05`, `ADM-21F` |
| Salle | `lib/features/salle/salle_page.dart:68`, `:99` ; `routes.dart:1093` ; `app_router.dart:2048-2061` ; billet `lib/core/router/billet_salle.dart:3-17` ; garde du billet, compte actif seulement, `redirection.dart:252-255` ; jeton : `supabase/functions/create-room-token`, et refus de tout compte hors `active` et `provisional_active`, `M/20261017110100_af_l2_01_jeton_enseignant_effectif_et_retrait.sql:44-52` ; mention `lib/features/salle_seance/mention_seance.dart:20-24` | mode entretien, sans mention ; entrée depuis `/attente` (`CAND-F10`) ; jeton du candidat convoqué (L4) | Salle |
| Fenêtre d'ouverture | `ctaSeance`, `lib/core/enseignant/cta_seance.dart:73` | même fenêtre pour l'entretien, appliquée par le jeton | `CAND-02` |
| Barre de sélection | `lib/features/comptable/paiements/barre_selection.dart:17` | promue vers `lib/core/widgets/`, jamais recopiée ; entre dans la galerie | `ADM-20` |
| Pays | `lib/core/i18n/pays_iso.dart:12-26` (code, nom français, nom arabe ; aucun indicatif) | pays de résidence et de versement ; table des indicatifs à ajouter (`CAND-F12`) | `CAND-01`, `CAND-04` |
| Textes juridiques | `lib/features/juridique/textes_juridiques.dart:38` (`confidentialite`) ; `VersionsJuridiques`, `:96` ; espace `juridique` de `fr.i18n.json` : 0 occurrence de « candidat », téléphone dit « Facultatif » (`juridique.confidentialite.s2.blocs`), `juridique.valeurs.dureesConservation` limité au compte, aux factures, à la pièce et aux messages | lien vers la politique depuis la case de confidentialité ; texte à compléter pour les candidatures et à faire relire par le juriste avant la mise en ligne | `CAND-04` |

## 5. Règles communes à toutes les fiches

Chaque fiche renvoie ici au lieu de les recopier.

### 5.1 États

- **`loading`** : `Skeleton` dans `BlocAsynchrone`, à la forme du contenu final,
  sans fausse donnée ; rien avant 180 ms ; explication à 8 s ; reprise à 20 s
  (`GOV` §4 bis.5 et §4 bis.6).
- **`content`** : les données rendues par le serveur, jamais recalculées à l'écran.
- **`empty`** : `EmptyState`, qui dit ce qui manque et quoi faire.
- **`error`** : `EtatSysteme`, ce qui n'a pas abouti, puis « Réessayer »
  (`commun.reessayer`). Jamais une cause affirmée côté service (`UX`, États).
- **`offline`** : le bandeau de `PageShell` le dit, **une seule fois**. Ce qui est
  lu reste affiché. Rien ne s'écrit sans réseau. Une note posée près d'une action
  dit quand elle sera possible (« … pourra … quand la connexion reviendra »).
  `EtatSansDonnees` seulement si rien n'a pu être lu ; il dit ce qui manque et ne
  redit jamais « hors ligne », ni en français ni en arabe. La salle garde son
  propre signal (`PageImmersive`, exception de `UX`).
- **`capacité indisponible`** : le port rend `CapaciteIndisponible('CAND-BR-nn')`.
  L'écran pose `EtatSysteme(nature: NatureEtat.indisponible)`, comme
  `invitations_page.dart:222-228`. Côté direction : « Disponible au branchement
  serveur » (`commun.etats.branchementServeur`). Côté candidat : la phrase de la
  fiche, ou rien quand l'entrée n'est pas rendue. Jamais une liste vide, jamais une
  donnée fictive. Le code `CAND-BR-nn` ne s'affiche jamais
  (`lib/core/capacites/capacite_indisponible.dart:10-11`). La route reste déclarée
  (§2, point 5) : on n'écrit jamais « aucune route ».
- **Aucune candidature pour ce compte** : tout le sous-arbre `/attente` est ouvert
  à tout compte en attente, tuteur et comptable compris (`redirection.dart:153-174`).
  Une adresse tapée peut donc ouvrir `CAND-01`, `CAND-02` ou `CAND-05` sans
  candidature. La page lit l'état rendu par `etat_dossier()` ; sans candidature,
  elle revient à `/attente`, sans phrase sur la candidature.
- **Selon l'écran** : erreur de validation (le champ nommé, ce qui manque, quoi
  faire, K-59) ; hors portée et absente, deux textes distincts ; données partielles
  (le seul bloc qui manque le dit, le reste s'affiche) ; action en cours ; succès
  **seulement après la réponse du serveur** ; issue non confirmée (« Il est possible
  que … ne soit pas parvenu jusqu'à Rewayah », `UX`) avec « Réessayer », qui rejoue
  la même clé d'idempotence.

### 5.2 Un seul bouton plein

- Un seul `ActionPrincipale` plein par écran et par état (K-56, `DEC:37`), vérifié
  par `verifierUnSeulBoutonPlein` (`test/support/garde_interface.dart:261`).
- Le lien d'entretien d'une ligne est secondaire (`CAND-Q14`). Les actions
  secondaires sont des `LienFleche` ou des boutons discrets.
- Deux zones pleines ne s'ouvrent jamais ensemble : une tuile du portail ne porte
  pas le bouton plein de sa page (`CAND-02`) ; en mode sélection, `ADM-20` ferme le
  détail.
- Un bouton qui ne peut pas aboutir n'est pas rendu, il n'est pas grisé ; une
  phrase dit pourquoi. Seule exception : « Suivant » des accords (`ENTREE:31`).
- Une action destructive passe par `ConfirmDestructive`.
- Un état critique porte un texte et une icône, jamais la couleur seule.

### 5.3 Disposition

- Largeurs mesurées : 360, 768, 1440. Clair et sombre. Texte à 200 %. Français et
  arabe (droite à gauche, `start` et `end`, jamais `left` et `right`, `GOV`
  §4 bis.2). Cibles de 48.
- **Mobile** : cartes. **Tablette (768)** : deux volets pour une liste et son
  détail ; pour un formulaire, un fil, une feuille ou un portail, chaque fiche le
  dit dans sa ligne « Tablette (768) ». **Bureau** : file et détail, 336, 24, 728,
  barre latérale 288, marge 32 (`GOV` §4 bis.4, comme `dossiers_page.dart:32-34`).
- **Grand écran** : cartes propres au grand écran, en bento (`GrilleBento`,
  `lib/core/widgets/grille_bento.dart`), jamais les cartes du mobile étirées ;
  jamais plusieurs cartes de même taille et de même style sur une page
  (`ENTREE:18-19`). Deux tuiles ou moins : une colonne sans bento
  (`C/BENTO_RECENSEMENT.md`, D14). Un écran de file (niveau E) garde un tableau
  dense sur bureau et ne le rétrécit pas sur mobile.
- Aperçu de lot et mappage d'import en pages, jamais en modales
  (`tool/verifier_jetons.dart:306-316` : seuls `AppBottomSheet` et
  `ConfirmDestructive` ouvrent un dialogue).
- Espacements de l'échelle seulement ; objet vers son bouton : 16 ; bouton au bord
  de fin (`GOV` §4 bis.1 et §4 bis.2). Deux colonnes se disent « au début
  (start) » et « à la fin (end) », jamais « à gauche » et « à droite ».

### 5.4 Textes

- **Le parcours candidat est en français et en arabe** (`DEC:36`). Côté direction,
  le français fait référence et l'arabe suit le sens (`CONS` §9). Chaque fiche donne
  ses clés proposées, le texte français, et l'arabe « à traduire », sauf clé
  existante réutilisée (`MOTS` §6, point 1 : on réutilise d'abord).
- **Une clé par texte, un libellé par action.** Un même texte n'a pas deux clés ;
  une même action n'a pas deux libellés.
- Dans `assets/i18n/fr.i18n.json`, l'espace avant « ? ! : ; » et dans les guillemets
  est l'espace insécable U+00A0 (`UX`, Typographie ; garde
  `test/core/i18n/typographie_fr_test.dart`). Les tableaux ci-dessous l'écrivent
  avec une espace simple.
- **Pluriels.** Toute clé dont un nom s'accorde avec `{n}` se déclare au pluriel de
  slang, comme `"inscritDepuis(param=jours)": {"one": "Inscrit depuis {jours} jour",
  "other": "Inscrit depuis {jours} jours"}` (`fr.i18n.json:2129-2132`), avec une
  forme `zero` où elle a un sens. Arabe : les six catégories (`zero`, `one`, `two`,
  `few`, `many`, `other`), à traduire (`ar.i18n.json:4721-4728`). Les tableaux
  l'écrivent `cle(param=n)`, puis `one` et `other`.
- **Tournures épicènes.** La séparation femmes et hommes est stricte (`CAND-Q07`) :
  une candidate lit le portail, une directrice lit la file de son côté. Un texte
  visible ne s'accorde pas au masculin par défaut : « la personne », « la personne
  convoquée », « la personne qui mène l'entretien ». Où une tournure épicène ne
  tient pas, la forme se décline par côté, lue au serveur. La question est jointe
  à `CAND-Q12`, qui pose déjà la forme du côté des femmes d'un nom de salle.
- **Aucun code d'état.** Étape, état, issue, pause, restriction, provenance,
  versement, pièce, entretien et courriel s'affichent par leurs libellés de 5.6,
  jamais par leur code (`a_completer`, `paiement_non_disponible`, `lien_public`).
- Chaque libellé neuf est déclaré dans `tool/libelles_sources.json` avec sa source.
- Jamais : « admin » (on dit la direction), un code interne (`CAND-BR`, un lot, un
  état de base, un nom de table), « Viviers », « Rejoindre la salle » ou « Rejoindre
  la visio » pour l'entretien, « Réussi », « Échec » (`MOTS` §4), un tiret long.
- Les noms de salle s'écrivent en entier, jamais sous une forme courte (`CONS` §10).
- La référence `CAND-…` ne se montre qu'à la direction, avec des traits d'union
  insécables U+2011 (comme `TEACHER-AS-000001`, `UX`).
- Un instant (entretien, décision, envoi) voyage en UTC et s'affiche dans le fuseau
  de la personne qui lit. Un créneau garde son heure locale et son fuseau IANA
  (`PORTS`, règles transverses).

### 5.5 Données

- **Jamais dans une liste, un aperçu de lot ou un export** : courriel, téléphone,
  genre, pièce, motif interne, compte rendu, constat, réponse libre (`CONS` 8.3).
- Le contact se lit seulement dans `ADM-21`, par `lireContact`, avec
  `candidatures.contact` ; chaque lecture est journalisée.
- **Jamais au candidat** : un motif interne, un résultat d'entretien, un compte
  rendu, un constat, un autre candidat, un compteur, une liste (`CONS` 8.1).
- La portée femmes et hommes se décide en base, listes et compteurs compris. Un
  masquage à l'écran ne compte pas (`CONS` 8.2).
- **Exception de lecture du super-admin** (`DEC:30`, `CONS` 8.1 et 8.2). Elle est
  lue par `CapacitesCandidatures.peutLireHorsGenre` (`PORTS` l. 64), jamais
  déduite à l'écran. Active, elle se dit : un bandeau en tête d'`ADM-20` ; une
  phrase en tête d'`ADM-21` et d'`ADM-21F` sur une candidature de l'autre côté. Même
  modèle que `dossiers.accesKyc.exceptionTitre`, `.exceptionMessage` et
  `.exceptionPiece` dans `ADM-02`. C'est une exception de lecture : elle ne donne
  pas l'entretien d'une personne de l'autre côté (`CONS` 0.3).

### 5.6 Les mots du module

Clés communes, réutilisées par plusieurs fiches. Elles entrent dans `MOTS` avec le
premier écran construit (`DEC:35`).

| Clé proposée | Français | Arabe |
| :--- | :--- | :--- |
| `recrutement.salles.examen` | Salle d'examen | à traduire |
| `recrutement.salles.verification` | Salle de vérification et d'entretien | à traduire |
| `recrutement.salles.prets` | Salle des prêts à enseigner | à traduire ; forme du côté des femmes en attente (`CAND-Q12`, `CAND-S10`) |
| `recrutement.cadre.titre` | Cadre religieux et pédagogique | à traduire ; sert aussi de titre de section sur la page d'accords |
| `recrutement.entretien.rejoindre` | Rejoindre l'entretien | à traduire |
| `recrutement.portail.ecrire` | Écrire à l'académie | à traduire ; portail, `CAND-02`, `CAND-03`, `CAND-05` |
| `recrutement.paiement.inconnu` | Aucun moyen de versement déclaré | à traduire |
| `recrutement.paiement.aVerifier` | Moyen de versement à vérifier par l'académie | à traduire |
| `recrutement.paiement.compatible` | Moyen de versement confirmé | à traduire ; sert aussi de libellé au contrôle `paiement_compatible` |
| `recrutement.paiement.incompatible` | Aucun moyen de versement possible pour l'instant | à traduire |
| `recrutement.controles.accordsSignes` | Accords acceptés | à traduire |
| `recrutement.controles.profilRenseigne` | Profil renseigné | à traduire |
| `recrutement.controles.entretienConclu` | Entretien conclu | à traduire |
| `recrutement.controles.evaluationValidee` | Constat d'entretien enregistré | à traduire |
| `recrutement.controles.profilUnique` | Aucun autre compte pour cette personne | à traduire |
| `recrutement.controles.aucuneRestriction` | Ni pause ni restriction | à traduire |
| `recrutement.controles.pieceValidee` | Pièce d'identité validée | à traduire |
| `commun.etats.branchementServeur` | Disponible au branchement serveur | existante |
| `commun.reessayer` | Réessayer | existante |

« Paiement » reste dans les noms internes (`paiement_compatible`, `PortReferentielPaiement`).
À l'écran, on dit « versement » : il s'agit d'être payé par Rewayah, et l'onglet
« Paiements » de Finance parle déjà des paiements reçus des familles.

« Salle d'examen » croise « examen de fin des bases », mot du programme (`MOTS` §3) :
la collision est jointe à `CAND-Q12`. Un changement de nom ne touche que ces clés.

**Libellés des états, côté direction** (`CONS` 4.1 et 6.2). La ligne d'`ADM-20`,
l'en-tête d'`ADM-21`, les filtres « Plus », l'historique et `{etat}` de
`admin.candidatures.erreurs.transition` les lisent ici ; jamais un code brut.

| Clé proposée | Français | Arabe |
| :--- | :--- | :--- |
| `admin.candidatures.etats.gardee` | Gardée pour suivi | à traduire ; dépend de `CONS` 0.3 (ligne `recue` de suivi) |
| `admin.candidatures.etats.invitee` | Invitée | à traduire |
| `admin.candidatures.etats.aCompleter` | À compléter | à traduire |
| `admin.candidatures.etats.enExamen` | En examen | à traduire |
| `admin.candidatures.etats.versementImpossible` | Versement pas encore possible | à traduire |
| `admin.candidatures.etats.entretienAPlanifier` | Entretien à planifier | à traduire |
| `admin.candidatures.etats.entretienPlanifie` | Entretien planifié | à traduire |
| `admin.candidatures.etats.decisionEnAttente` | Décision en attente | à traduire |
| `admin.candidatures.etats.refusee` | Refusée | à traduire ; candidature et pièce |
| `admin.candidatures.etats.retiree` | Retirée | à traduire |
| `admin.candidatures.etats.enPause` | En pause | à traduire |
| `admin.candidatures.etats.restreintePiece` | Restreinte : pièce | à traduire |
| `admin.candidatures.etats.restreinteVersement` | Restreinte : versement | à traduire |
| `admin.candidatures.etats.restreinteDirection` | Restreinte : décision de la direction | à traduire |
| `admin.candidatures.etats.indisponible` | Indisponible | à traduire ; aussi l'état d'une ligne d'`ADM-24` |
| `admin.candidatures.etats.provenance.lienPublic` | Lien du site | à traduire |
| `admin.candidatures.etats.provenance.invitation` | Invitation | à traduire |
| `admin.candidatures.etats.provenance.import` | Formulaires importés | à traduire |
| `admin.candidatures.etats.versement.inconnu` | Aucun moyen déclaré | à traduire |
| `admin.candidatures.etats.versement.aVerifier` | À vérifier | à traduire |
| `admin.candidatures.etats.versement.compatible` | Confirmé | à traduire ; aussi l'état d'une ligne d'`ADM-24` |
| `admin.candidatures.etats.versement.incompatible` | Aucun moyen possible | à traduire |
| `admin.candidatures.etats.piece.aDeposer` | À déposer | à traduire |
| `admin.candidatures.etats.piece.deposee` | Déposée | à traduire |
| `admin.candidatures.etats.aCorriger` | À corriger | à traduire ; pièce, et compteur d'`ADM-23` |
| `admin.candidatures.etats.piece.validee` | Validée | à traduire |
| `admin.candidatures.etats.entretien.aPlanifier` | À planifier | à traduire ; aussi la puce d'`ADM-20E` |
| `admin.candidatures.etats.entretien.planifie` | Planifié | à traduire |
| `admin.candidatures.etats.entretien.ouvert` | Ouvert | à traduire |
| `admin.candidatures.etats.entretien.termine` | Terminé | à traduire |
| `etat.annule` | Annulé | existante |
| `admin.candidatures.etats.entretien.manque` | Manqué | à traduire |
| `admin.candidatures.etats.entretien.inaccessible` | Inaccessible | à traduire |

Les trois salles reprennent `recrutement.salles.*` ; l'état d'un courriel, les
clés `admin.candidatures.courriel.*` d'`ADM-20`.

### 5.7 Contrôles communs

Pour chaque écran neuf ou étendu, avant de le dire fait :
- les cinq états, la capacité indisponible et les états propres de la fiche, chacun
  rendu par un test de widget ;
- `verifierUnSeulBoutonPlein` dans chaque état ;
- 360, 768, 1440 ; clair et sombre ; `fr` et `ar` ; texte à 200 % ; clavier et
  focus ; cibles de 48 et contrastes mesurés (`CONS` 12.2) ;
- `dart run tool/verifier_jetons.dart` et `dart run tool/verifier_revue.dart` :
  0 violation nouvelle ; garde hors ligne `test/core/reseau/etat_sans_donnees_test.dart`
  (elle ne lit que `fr.i18n.json` : l'arabe d'une clé hors ligne se relit à la main) ;
- **parcours candidat en arabe** (`DEC:36`) : 0 clé sans traduction arabe sous
  `inscription.*`, `recrutement.*`, `accords.*`, `attente.*` et `kyc.*`, chiffre
  mesuré et écrit (au 21/10, `recrutement` : 17 clés traduites sur 106, `CONS` §9).
  slang retombe en silence sur le français quand une clé arabe manque : seul ce
  chiffre le montre. 0 modèle de 5.8 sans arabe ;
- 0 code d'état brut rendu (5.4) ;
- le chiffre écrit dans la fiche, jamais une appréciation.

### 5.8 Modèles de message et notifications

Le candidat lit mot pour mot le texte d'un modèle : sur le portail, dans une
notification de l'app (`CONS` 7.2), dans un courriel de la file (`CONS` 7.3). Les
textes vivent au serveur (L5), en `fr` et en `ar` ; ce ne sont pas des clés i18n de
l'application. Langue : celle de l'interface choisie, sinon `ar` pour une ligne
importée de A (`CONS` 7.3). Paramètres : dates, liens, `{cause}`, et `{code}` pour le
seul modèle `invitation` ; jamais un texte libre, un motif interne, une réponse ni un
constat (L5-4).

**Ports.** La direction lit les modèles permis pour un geste par
`PortCandidaturesDirection.modelesMessage(geste)`, méthode à ajouter à `PORTS` (L5),
qui rend leur texte dans les deux langues. Le candidat lit le texte de son modèle
dans `etat_dossier()` étendu (`PORTS` §3). Sur le portail, ce texte tient lieu de
phrase d'état pour la pause, le refus et la pièce à corriger : le portail n'a pas de
clé propre pour eux.

Liste fermée, textes français proposés, arabe à traduire. Plusieurs variantes d'un
même modèle (plusieurs motifs de refus, plusieurs causes de correction) se fixent
en L5 avec la direction, chacune avec son arabe.

| Modèle | Quand | Où | Français proposé |
| :--- | :--- | :--- | :--- |
| `invitation` | transition 3 | courriel seulement | L'académie Rewayah vous invite à déposer votre candidature d'enseignement. Ouvrez ce lien pour créer votre compte : {lien}. Votre code d'invitation : {code}, valable jusqu'au {date}. |
| `lien_inscription` | transition 26 | message WhatsApp consigné, jamais un courriel (`CONS` 7.4) | Rewayah ouvre ses candidatures d'enseignement. Si vous n'avez pas d'adresse de courriel, créez-en une, puis ouvrez ce lien : {lien}. |
| `complement` | transitions 7 et 23 | notification, courriel | L'académie vous demande de compléter votre candidature. Ouvrez l'application pour voir ce qui manque. |
| `admission` | transition 10 | notification, courriel | Votre candidature passe en Salle de vérification et d'entretien. Ouvrez l'application pour la suite. |
| `piece_a_corriger` | transition 15 | portail, dépôt de pièce, notification, courriel | Votre pièce d'identité est à corriger : {cause}. Déposez une nouvelle pièce dans l'application. |
| `entretien_planifie` | transition 11 | notification, courriel | Votre entretien est planifié le {date} à {heure} ({fuseau}). Vous le rejoindrez dans l'application. |
| `entretien_annule` | transition 12, issue `annule` | notification, courriel | Votre entretien du {date} est annulé. Une nouvelle date vous sera proposée. |
| `entretien_reprogramme` | transition 11 après la 12 | notification, courriel | Votre entretien est reprogrammé le {date} à {heure} ({fuseau}). |
| `pause` | transition 18, pose | portail, notification, courriel | Votre candidature est en pause. L'académie vous préviendra dans l'application à la reprise. |
| `pause_levee` | transition 18, levée | notification, courriel | Votre candidature reprend. Ouvrez l'application pour la suite. |
| `refus` | transition 16 | portail, notification, courriel | Votre candidature n'a pas été retenue. Merci pour le temps que vous lui avez donné. |
| `retrait` | transition 17 | notification, courriel | Votre retrait est enregistré. Seule l'académie pourra rouvrir votre candidature. |
| `entree_salle_prets` | transition 14 | notification, courriel | Vous entrez en Salle des prêts à enseigner. Votre espace d'enseignement est ouvert. |
| `moyen_possible` | transition 9 | notification, courriel | Rewayah peut désormais vous verser une rémunération dans votre pays. Ouvrez l'application pour déclarer votre moyen de versement. |
| `nouveau_message` | message de l'académie dans le fil | notification, courriel | L'académie vous a écrit. Ouvrez l'application pour lire son message. |

**Contrôles** : L5-3, L5-4 ; 0 modèle sans arabe ; 0 motif interne dans un
paramètre ; texte rendu mot pour mot sur le portail ; 0 « Courriel envoyé le »
avant l'état `envoye`.

---

## 6. Côté candidat

### CAND-04 : Inscription sans code (étend TUT-00c)

- **Statut** : proposée, à valider par le directeur.
- **Tâche** : une personne venue du lien de la page « recrutement » du site crée son
  compte de candidat, sans code d'invitation. L'invité suit le même chemin avec son
  code : même compte, même candidature, seule la provenance diffère (`CONS` 3.3).
- **Route** : **aucune route neuve pour le lien du site.** Le lien est
  `/connexion?mode=creer` (`connexion_page.dart:80-88`). Le lien reçu par courriel
  prouve l'adresse (`lib/core/auth/service_auth.dart:52-53`) ; la porte
  `inscription` mène ensuite à `/inscription/usage` (`redirection.dart:144-147`).
  Une route propre au site ne servirait qu'à sauter le choix de l'usage ; elle ne
  se crée pas sans justification écrite ici (`CONS` §10). Une seule étape neuve :
  `/inscription/telephone`, dans le sous-arbre de la porte.
- **Entrée** : le lien du site. Sur `/inscription/usage`, le bloc enseignant
  (`usage_etape.dart:63-92`) : quand `ouverte` est vrai, la phrase
  `inscription.usage.enseignantInvite` (« Vous êtes enseignant ? L'académie vous
  invite par courriel. », `:71`), qui deviendrait fausse, est remplacée par
  `enseignantPostuler`, suivie des deux liens « Déposer ma candidature » et
  « J'ai un code d'invitation » ; quand `ouverte` est faux, l'étape reste
  inchangée. Sur `/inscription/invitation`, la même phrase et le même lien
  « Déposer ma candidature », rendus seulement quand `ouverte` est vrai.
- **Parcours** : courriel (connexion, existant) ; usage ; identité (prénom et nom,
  existant) ; genre (existant, obligatoire ici) ; téléphone (neuf) ; récapitulatif
  (langue de l'interface, accord de confidentialité, création). **Téléphone, langue
  et case de confidentialité ne valent que pour le parcours candidat** (usage
  enseignant, avec ou sans code). `etapesInscription` est aujourd'hui une liste
  unique, partagée par le tuteur, l'élève adulte et le comptable
  (`brouillon_inscription.dart:32-37`), et le récapitulatif est commun. Les étapes
  se calculent donc selon l'usage choisi, et le rang « n sur N » (`rangEtape`,
  `:40`) aussi. Tuteur, élève adulte et comptable gardent leur parcours et leur
  récapitulatif.
- **Droits (capacité)** : une session valide sans profil. Les liens sans code ne
  sont rendus que si le serveur dit l'inscription ouverte (clé `app_config` de
  `CONS` 3.1, lue par `PortInscriptionCandidat.ouverte`, nom proposé). Aucune
  capacité de la direction.
- **Champs (K-57)** : déduit : le courriel (de la session, non modifiable), la langue
  de l'interface (langue active, modifiable au récapitulatif). Choisi : le genre
  (deux cartes), l'indicatif (liste des pays, recherche par nom en français ou en
  arabe), la langue (deux cartes, `fr` ou `ar`), la case de confidentialité. Saisi :
  prénom et nom (un nom ne se choisit pas), numéro sans indicatif (un numéro ne se
  choisit pas).
- **Contenu du récapitulatif** : les réponses, un « Modifier » par ligne (existant) ;
  la case « J'ai lu et j'accepte la politique de confidentialité. », 16 au-dessus
  du bouton (`GOV` §4 bis.2), avec le lien « Lire la politique de confidentialité »
  vers `/juridique/confidentialite`. La version acceptée (`VersionsJuridiques`,
  `textes_juridiques.dart:96`) est enregistrée avec sa date (`CONS` 3.1,
  condition 5), et c'est celle qui est affichée.
- **Données jamais montrées** : aucune réponse importée ; aucun signe qu'un courriel
  ou un téléphone est déjà connu ; le rattachement par téléphone reste invisible du
  candidat (`CONS` 3.4).
- **Bouton plein** : « Continuer » à chaque étape (existant) ; « Créer mon compte »
  au récapitulatif.
- **Disposition** : `CoquilleEtape` (`inscription_page.dart:93-140`), posée sur
  `PageEtape` (`lib/core/widgets/page_etape.dart`). Mobile : une colonne, bouton en
  bas. Tablette (768) : colonne bornée ; cartes de choix en deux colonnes. Bureau :
  colonne bornée ; les cartes de choix (genre, langue) passent en bento
  (`colonneLarge`, `inscription_page.dart:115-117`).
- **États** :
  - `loading` : lecture de l'ouverture, création du compte (indicateur dans le
    bouton) ;
  - `content` ; `empty` : sans objet, c'est un formulaire ;
  - `error` : « Votre compte n'a pas pu être créé. » et « Réessayer » ; issue non
    confirmée selon 5.1 ;
  - `offline` : note sous le bouton, « Le compte pourra être créé quand la connexion
    reviendra. » ;
  - capacité indisponible : les liens sans code ne sont pas rendus ; le bloc
    enseignant reste celui d'aujourd'hui ;
  - **courriel à confirmer** (refus `CourrielNonConfirme`) : « Confirmez d'abord
    votre adresse : ouvrez le lien reçu par courriel. » ;
  - **réponse neutre** (`CONS` 3.1, ligne 2 ; `CONS` §10) : une seule réponse pour un
    succès, un courriel déjà utilisé et un plafond horaire atteint. Courriel déjà
    utilisé : l'étape de connexion joue déjà `connexion.lienEnvoye` et
    `connexion.lienEnvoyeDetail` (existantes, arabe compris) pour toute adresse ; le
    lien part vraiment, rien ne dit que l'adresse est connue. Plafond horaire : si
    `CAND-F03` le place avant l'envoi du lien, ces deux clés seraient fausses
    (`MOTS` §1) ; la clé neuve `inscription.candidat.reponseNeutre` sert alors aux
    trois cas sur l'entrée sans code, pour que la réponse reste la même. S'il est
    placé après le lien, L3 écrit le texte avec `CAND-F03` ;
  - **code invalide ou expiré** : textes existants de `InvitationCandidatPage`, plus
    « Déposer ma candidature » quand l'inscription est ouverte ;
  - **inscription sans code pas encore ouverte** (clé fausse au moment de créer) :
    « Les candidatures sans code ne sont pas encore ouvertes. Si la direction vous a
    remis un code, saisissez-le. » et un lien vers le code ;
  - **genre ou téléphone manquant** : refusé en base comme à l'écran ; le champ est
    nommé.
- **Textes** :

| Clé proposée | Français | Arabe |
| :--- | :--- | :--- |
| `inscription.usage.enseignantInvite` | Vous êtes enseignant ? L'académie vous invite par courriel. | existante ; rendue seulement quand `ouverte` est faux |
| `inscription.usage.enseignantPostuler` | Vous souhaitez enseigner à Rewayah ? | à traduire |
| `inscription.usage.deposerCandidature` | Déposer ma candidature | à traduire ; usage et code d'invitation |
| `inscription.usage.enseignant` | J'ai un code d'invitation | existante |
| `inscription.telephone.question` | Votre numéro de téléphone | à traduire |
| `inscription.telephone.explication` | Il sert à reconnaître vos réponses aux anciens formulaires et à éviter les doublons. L'académie vous écrit dans l'application. Il n'est jamais montré aux autres personnes qui postulent. | à traduire |
| `inscription.telephone.indicatif` | Indicatif du pays | à traduire |
| `inscription.telephone.numero` | Numéro, sans l'indicatif | à traduire |
| `inscription.telephone.indicatifManquant` | Choisissez l'indicatif de votre pays. | à traduire |
| `inscription.telephone.numeroManquant` | Saisissez votre numéro de téléphone. | à traduire |
| `inscription.langue.question` | Dans quelle langue voulez-vous lire l'application ? | à traduire |
| `inscription.confidentialite.case` | J'ai lu et j'accepte la politique de confidentialité. | à traduire |
| `inscription.confidentialite.lire` | Lire la politique de confidentialité | à traduire |
| `inscription.creer` | Créer mon compte | existante |
| `inscription.candidat.creationEchec` | Votre compte n'a pas pu être créé. | à traduire |
| `inscription.candidat.horsLigne` | Le compte pourra être créé quand la connexion reviendra. | à traduire |
| `inscription.candidat.courrielAConfirmer` | Confirmez d'abord votre adresse : ouvrez le lien reçu par courriel. | à traduire |
| `inscription.candidat.nonOuverte` | Les candidatures sans code ne sont pas encore ouvertes. Si la direction vous a remis un code, saisissez-le. | à traduire |
| `connexion.lienEnvoye` | Lien envoyé | existante |
| `connexion.lienEnvoyeDetail` | Ouvrez le message envoyé à {courriel}, puis suivez le lien. Vous pouvez laisser cette page ouverte. | existante |
| `inscription.candidat.reponseNeutre` | Si cette adresse peut servir, un lien vous a été envoyé. Ouvrez-le pour continuer. | à traduire ; seulement si `CAND-F03` place le plafond avant le lien |

- **Contrat serveur** : lot L3 (`CAND-BR-17`, part de `CAND-BR-04`). Port proposé
  `PortInscriptionCandidat` (`ouverte`, `inscrire`), à porter dans `PORTS` par L3
  (`CONS` 0.1). La RPC suit `inscrire_enseignant_invite`
  (`M/20261017150200_af_l1_11_inscription_enseignant_sur_invitation.sql:110-178`) ;
  L1 fixe d'abord la forme du compte, la même pour les deux portes (`CONS` 3.1).
  L'accord de confidentialité est enregistré avec sa version et sa date
  (`CONS` 3.1, condition 5). **Mise en ligne** : clé vraie seulement après L1 à
  L3, le SMTP d'authentification, `enable_confirmations = true`, **le texte de
  confidentialité complété pour les candidatures** (données demandées, téléphone
  obligatoire, réponses importées, conservation selon `CAND-Q21`, `CONS` 8.4) et
  relu par le juriste, et le feu vert du directeur (`CONS` 3.1, ligne 6).
  Aujourd'hui ce texte ne parle pas de candidature et dit le téléphone facultatif
  (section 4).
- **Contrôles d'acceptation** : scénarios L3-1, L3-2, L3-3, L3-13, L3-17, L3-18 ;
  widget : 0 lien sans code quand `ouverte` est faux ; 0 « L'académie vous invite
  par courriel » quand `ouverte` est vrai ; le parcours tuteur garde 4 étapes, et
  « n sur N » le dit ; 0 réponse importée rendue ; même texte rendu pour un succès,
  un courriel connu et un plafond atteint ; la version de confidentialité
  enregistrée est celle affichée ; création refusée à l'écran sans genre ni
  indicatif ; 5.7.

### TUT-00b étendu : Portail de la candidature (`/attente`)

- **Statut** : proposée, à valider par le directeur.
- **Tâche** : dire où en est la candidature, et la prochaine action. Une seule.
- **Route** : `/attente`, inchangée (`routes.dart:70`, `app_router.dart:386-389`).
- **Entrée** : la porte `attente` y mène tout compte en attente
  (`redirection.dart:153-174`). Le portail se relit au retour dans l'application
  (`attente_page.dart:50-70`).
- **Droits (capacité)** : le titulaire seul. L'état vient de `etat_dossier()` étendu
  (`CAND-BR-10`), jamais d'un rôle ni d'un calcul à l'écran.
- **Contenu, dans l'ordre** :
  1. la salle, en entier : « Vous êtes en Salle d'examen » ;
  2. l'état, et la prochaine action (bouton plein) ;
  3. « À compléter » : une carte groupée, sans bouton par ligne, comme aujourd'hui
     (`attente_page.dart:26-31`). En Salle d'examen : « Le cadre religieux et
     pédagogique », seulement quand sa version requise est publiée (`CAND-BR-11`),
     puis « Votre candidature » (l'envoi exige le cadre, transition 6). En Salle de
     vérification et d'entretien : les accords, la pièce, les compléments demandés.
     **Complément demandé** (transitions 7 et 23) : la phrase `complementDemande`,
     puis la liste rendue par le serveur, `complementListe`. C'est la liste que la
     direction a choisie (`ADM-21`, feuille « Demander un complément »), jamais un
     texte libre ;
  4. en Salle de vérification et d'entretien : la tuile « Mon entretien »
     (`CAND-02`), **sans bouton plein** : l'état, la date, et le lien `LienFleche`
     « Voir les détails » ;
  5. le lien « Écrire à l'académie » (`CAND-05`) ; après un retrait ou un refus,
     rendu seulement si le serveur ouvre le fil (`CAND-F14`) ;
  6. le lien discret « Retirer ma candidature » (`CAND-03`) ;
  7. « Se déconnecter », en action discrète (existant, `attente_page.dart:116-117`).
- **Prochaine action, selon l'état** (rendue par le serveur) : cadre à accepter :
  « Lire et accepter nos conditions », seulement quand une case est à cocher (aucune
  avant `CAND-BR-11`) ; questionnaire : « Compléter ma candidature » ; complément
  demandé : « Compléter ma candidature » ; pièce à déposer : « Déposer ma pièce » ;
  pièce à corriger : « Déposer une nouvelle pièce » ; entretien ouvert : « Rejoindre
  l'entretien ». **Entretien ouvert, c'est la seule action pleine du portail** ; le
  bouton plein de `CAND-02` vit seulement sur `/attente/entretien`. En examen, en
  pause, versement pas encore possible, pièce déjà déposée, refusée, retirée : aucune
  action du candidat, donc aucun bouton plein de plus ; « Actualiser » reste comme
  aujourd'hui (`attente_page.dart:160-178`, niveau tertiaire).
- **Données jamais montrées** : 5.5. Le texte d'une pause, d'un refus ou d'une pièce
  à corriger est celui du modèle (5.8), rendu mot pour mot, jamais le motif interne.
- **Bouton plein** : la prochaine action, une seule.
- **Disposition** : mobile : blocs empilés (`PileCartes`, 16). Tablette (768) :
  bento à deux colonnes. Bureau : `GrilleBento` : « Où en est ma candidature »
  grande (2 × 2) avec la prochaine action ; « Mon entretien » large (2 × 1), sans
  bouton plein ; « À compléter » haute (1 × 2) ; « Écrire à l'académie » petite
  (1 × 1). Deux tuiles ou moins : une colonne (D14).
- **États** :
  - `loading` : `Skeleton` (existant) ; `content` ;
  - `empty` : sans objet, le portail a toujours un état ;
  - `error` : texte existant `attente.illisible` et « Réessayer » ;
  - `offline` : bandeau ; si rien n'a pu être lu, `recrutement.portail.nonCharge`
    et « Réessayer ». La clé existante `attente.horsLigne` n'est pas reprise : son
    français redit le réseau (« … dès le retour du réseau ») et son arabe dit « vous
    êtes hors ligne » (`أنت غير متصل`), contre `UX` (« Hors ligne se dit une seule
    fois ») ; la garde ne lit que le français ;
  - capacité indisponible : tant que `CAND-BR-10` manque, le portail garde ses cinq
    états d'aujourd'hui (`etat_dossier.dart:216-233`) et n'affiche aucun état de
    candidature ;
  - **à compléter** (liste) ; **en examen** ; **versement pas encore possible** ;
    **pièce à corriger** (texte du modèle) ; **pièce déjà déposée** (reprise,
    `CONS` 3.3) ; **en pause** (texte du modèle, reprise si connue) ; **refusée**
    (texte du modèle) ; **retirée** ; **complément demandé** (liste) ; **texte à
    ré-accepter** (nouvelle version) ; **entretien ouvert** (un seul bouton plein).
  - À l'entrée en Salle des prêts à enseigner, le portail ne retient plus le compte :
    la garde existante mène à l'espace enseignant.
- **Textes** :

| Clé proposée | Français | Arabe |
| :--- | :--- | :--- |
| `recrutement.portail.vousEtesEn` | Vous êtes en {salle} | à traduire |
| `recrutement.portail.aCompleterTitre` | Votre candidature est à compléter | à traduire |
| `recrutement.portail.elementCadre` | Le cadre religieux et pédagogique | à traduire |
| `recrutement.questionnaire.titre` | Votre candidature | voir `CAND-01` ; ligne de « À compléter » |
| `recrutement.portail.completer` | Compléter ma candidature | à traduire |
| `attente.lireEtAccepter` | Lire et accepter nos conditions | existante |
| `attente.deposerLaPiece` | Déposer ma pièce | existante |
| `recrutement.portail.deposerNouvellePiece` | Déposer une nouvelle pièce | à traduire |
| `recrutement.portail.enExamen` | Votre candidature est en examen. L'académie lit vos réponses et vous préviendra ici. | à traduire |
| `recrutement.portail.versementImpossible` | Rewayah ne peut pas encore vous verser une rémunération par les moyens déclarés dans votre pays. Votre candidature est gardée en Salle d'examen. L'académie vous préviendra dès qu'un moyen sera possible. | à traduire |
| `recrutement.portail.libreDePartir` | Vous restez libre de retirer votre candidature. | à traduire |
| `recrutement.portail.repriseLe` | Reprise prévue le {date}. | à traduire |
| `recrutement.portail.retiree` | Vous avez retiré votre candidature. Seule l'académie peut la rouvrir. | à traduire |
| `recrutement.portail.complementDemande` | L'académie vous demande un complément. | à traduire |
| `recrutement.portail.complementListe` | À compléter : {elements}. | à traduire |
| `recrutement.piece.dejaDeposee` | Votre pièce est déjà déposée. | voir `TUT-00c/c` |
| `recrutement.portail.aReaccepter` | Un texte a changé. Lisez la nouvelle version, puis acceptez-la. | à traduire |
| `recrutement.portail.nonCharge` | L'état de votre candidature n'a pas pu être chargé. | à traduire |
| `recrutement.portail.ecrire` | Écrire à l'académie | voir 5.6 |
| `recrutement.entretien.voirDetails` | Voir les détails | voir `CAND-02` |

- **Contrat serveur** : L2 (`CAND-BR-10`) : `etat_dossier()` étendu, lu par
  `lib/core/dossier/service_dossier.dart` ; `EtapeDossier` gagne les états de la
  candidature, la liste du complément et le texte du modèle (`PORTS` §3).
  Modèles et notifications : L5, 5.8. Accès au fil après un retrait ou un refus :
  `CAND-F14`.
- **Contrôles d'acceptation** : widget : 0 motif interne, 0 compte rendu, 0 constat
  (`CONS` 12.2) ; chaque état rend un seul bouton plein ou aucun ;
  `verifierUnSeulBoutonPlein` sur `/attente`, entretien ouvert : 1 ; texte du modèle
  rendu mot pour mot ; complément : la liste rendue est celle choisie par la
  direction, 0 texte libre ; en Salle d'examen, 0 lien de dépôt de pièce ; 0
  « Lire et accepter nos conditions » sans case à cocher ; 0 « hors ligne » dans
  le texte rendu en `ar` ; 5.7.

### CAND-01 : Questionnaire de la Salle d'examen

- **Statut** : proposée, à valider par le directeur.
- **Tâche** : lire les conditions de rémunération, puis répondre et envoyer sa
  candidature.
- **Route** : `/attente/candidature` (neuve), dans le sous-arbre ouvert au compte en
  attente (`redirection.dart:172-174`).
- **Entrée** : la prochaine action du portail ; la ligne « Votre candidature » de « À
  compléter ».
- **Droits (capacité)** : le titulaire. Lectures :
  `PortMaCandidature.conditionsRemuneration` et `.questionnaire` (options lues au
  serveur, opérateurs confirmés seulement) ; écriture : `.envoyerReponses`.
- **Libellés** : les libellés des questions et des options viennent du
  questionnaire versionné, en `fr` et en `ar`, rendus par
  `PortMaCandidature.questionnaire` (à préciser dans `PORTS` par L2) ; les pays
  viennent de `pays_iso.dart`, les langues de la table des libellés ISO 639 du
  mappage (`CONS` §9). Aucun libellé de question ni d'option en dur ; un libellé
  absent dans la langue lue se signale, jamais un code brut.
- **Contenu, une carte par thème** :
  1. **Conditions de rémunération**, lues au serveur, jamais écrites en dur
     (`CAND-BR-12`) : la part de l'enseignant, « {part} du prix public, pour chaque
     élève présent » (47 % au 19/10, `TARIFS:13`) ; puis une ligne par public,
     rendue par le serveur, avec son montant par élève présent et par heure (deux
     publics au 19/10, enfant et adulte, `TARIFS:14`). Aucun public ni montant en
     dur. La règle de l'élève absent, la période de versement et les frais ne
     s'affichent qu'une fois posés en base. Une phrase dit que les coordonnées
     financières ne seront demandées qu'au premier versement (`CONS` 2.1) ;
  2. **Langues** : langue maternelle, langues d'explication (noms lus dans le
     référentiel ; une langue hors référentiel est marquée comme telle, jamais un
     code brut, `CONS` §9) ;
  3. **Récitation** : niveau de mémorisation, niveau de lecture et de tajwid,
     riwaya, ijaza présentable (oui, non), expérience avec les débutants ;
  4. **Disponibilités** : plages par jour en heures entières (une grille jour par heure, jamais de demi-heure), fuseau (le seul de la grille), classes souhaitées, date de début ; deux plages d'un même jour ne se recouvrent pas (cause nommée `plages_qui_se_chevauchent`) ;
  5. **Publics** que vous pouvez enseigner ;
  6. **Pays et versement** : pays de résidence, pays de versement, compte bancaire
     (oui, non), opérateurs parmi les seules lignes confirmées du pays de versement ;
     sans ligne confirmée, une phrase à la place, jamais une liste vide ; la case
     « J'accepte de recevoir ma rémunération par au moins un moyen validé par
     Rewayah. » (`SPEC §4.2`).
- **Complément demandé** (transitions 7 et 23) : en tête, `complementDemande` et
  `complementListe` (voir `TUT-00b`) ; les questions nommées sont signalées dans
  leur carte et seules modifiables en Salle de vérification et d'entretien (envoi à
  préciser dans `PORTS` pour la salle 2, L2).
- **Champs (K-57)** : déduit : réponses pré-remplies depuis l'ancien formulaire
  (colonnes C et E à L de A, `CONS` 3.4), marquées « à relire ». Choisi : tout le
  reste, dans des listes (`ENTREE:26`) ; pays par `lib/core/i18n/pays_iso.dart`, le
  serveur ne reçoit que le code. **Le fuseau est choisi, jamais déduit** : la liste
  IANA propose en tête le fuseau de l'appareil, que le candidat confirme par un
  geste explicite ; rien n'est envoyé sans ce choix (`PORTS`, Heures : un fuseau
  « ne se devine pas » ; `CONS` 3.4). Le fuseau d'un appareil en voyage serait faux,
  et il commande la planification de l'entretien (transition 11). Le pays de
  versement proposé égal au pays de résidence reste une proposition, modifiable
  (`CAND-F16`). Saisi : rien.
- **Jamais demandé** : numéro de compte, IBAN, numéro de portefeuille, identifiant,
  code ; pays d'origine (`CONS` 0.2) ; contrat ; pièce (`CONS` 12.2 : 0 case de
  contrat, 0 dépôt de pièce). Le numéro de contact n'est jamais proposé comme numéro
  de portefeuille.
- **Après l'envoi** : `/attente/candidature` se lit sans champ ni bouton, et porte
  l'état du versement (inconnu, à vérifier, confirmé, aucun moyen possible, clés de
  5.6). Le portail n'en montre que `versementImpossible`. Un complément demandé
  rouvre les seules questions nommées.
- **Brouillon** : L2A1 (22/10) a posé un brouillon au serveur
  (`enregistrerBrouillon` dans `PORTS`, `enregistrer_reponses_salle_examen`),
  proposé et non décidé (`CAND-F15`, `CONS` 0.2 bis). Tant que le directeur n'a
  pas répondu, l'écran n'en dépend pas : quitter la page sans envoyer l'annonce
  avant (`ConfirmDestructive`).
- **Bouton plein** : « Envoyer ma candidature », en bas, après la case de
  rémunération (16). **Rendu seulement quand le cadre religieux et pédagogique est
  publié et accepté.** Sans `CAND-BR-11`, ou tant que la version requise du cadre
  n'est pas publiée, il n'est pas rendu : la phrase `accords.cadreNonPublie` le
  remplace, les réponses restent à l'écran. Publié mais pas encore accepté : la
  phrase `cadreManquant` et le lien « Lire et accepter nos conditions ».
- **Disposition** : mobile : cartes empilées (`PileCartes`, 16). Tablette (768) :
  colonne bornée ; les cartes de choix en deux colonnes. Bureau : colonne de
  formulaire bornée (`PageParcours`) ; à l'intérieur d'une question, les cartes de
  choix passent en bento, de tailles variées ; la carte des conditions est la plus
  large. Jamais une carte de téléphone étirée.
- **États** :
  - `loading` (`Skeleton` des cartes) ; `content` ;
  - `empty` : sans objet ;
  - `error` : « Le questionnaire n'a pas pu être chargé. » et « Réessayer » ;
  - `offline` : les réponses restent à l'écran ; note sous le bouton, « Votre
    candidature pourra être envoyée quand la connexion reviendra. » ;
  - capacité indisponible : sans `CAND-BR-10` ou `CAND-BR-12`, la page dit « Cette
    étape n'est pas encore ouverte. Votre compte est gardé. » ; sans `CAND-BR-13`,
    la carte des opérateurs le dit seule (données partielles) ; sans `CAND-BR-11`,
    le bouton n'est pas rendu (voir Bouton plein) ;
  - **aucune candidature pour ce compte** : retour à `/attente` (5.1) ;
  - **pré-rempli à relire** ; **questionnaire périmé** (`QuestionnairePerime`) ;
    **aucun moyen confirmé dans le pays** ; **réponses incomplètes nommées**
    (`ReponsesIncompletes`, chaque champ nommé dans sa carte) ; **fuseau non
    confirmé** (champ nommé) ; **accord de rémunération manquant**
    (`AccordRemunerationRequis`) ; **cadre non publié** ; **cadre non accepté**
    (`EngagementNonAccepte`, par exemple une version publiée pendant la saisie :
    lien vers la page d'accords) ; **conflit** (`ConflitCandidature`) ;
  - **complément demandé** : la liste en tête, les questions nommées ;
  - **lecture seule après l'envoi**, avec l'état du versement ;
  - **départ sans envoi** : « Quitter sans envoyer votre candidature ? » ;
  - succès seulement après la réponse : retour au portail, « en examen ».
- **Textes** :

| Clé proposée | Français | Arabe |
| :--- | :--- | :--- |
| `recrutement.questionnaire.titre` | Votre candidature | à traduire |
| `recrutement.questionnaire.conditionsTitre` | Conditions de rémunération | à traduire |
| `recrutement.questionnaire.part` | Votre part : {part} du prix public, pour chaque élève présent. | à traduire |
| `recrutement.questionnaire.montantPublic` | {public} : {montant} par élève présent et par heure. | à traduire ; une ligne par public rendu par le serveur |
| `recrutement.questionnaire.coordonneesPlusTard` | Vos coordonnées financières ne vous seront demandées qu'avant votre premier versement. | à traduire |
| `recrutement.questionnaire.langues` | Vos langues | à traduire |
| `recrutement.questionnaire.recitation` | Votre récitation | à traduire |
| `recrutement.questionnaire.disponibilites` | Vos disponibilités | à traduire |
| `recrutement.questionnaire.fuseau` | Votre fuseau horaire | à traduire |
| `recrutement.questionnaire.fuseauPropose` | Proposé d'après votre appareil : {fuseau}. Confirmez-le ou choisissez-en un autre. | à traduire |
| `recrutement.questionnaire.fuseauManquant` | Choisissez votre fuseau horaire. | à traduire |
| `recrutement.questionnaire.publics` | Les publics que vous pouvez enseigner | à traduire |
| `recrutement.questionnaire.versement` | Votre pays et votre versement | à traduire |
| `recrutement.questionnaire.horsReferentiel` | Langue pas encore proposée par Rewayah | à traduire |
| `recrutement.questionnaire.aucunMoyen` | Rewayah ne verse pas encore de rémunération dans ce pays. Vous pouvez envoyer votre candidature : elle restera en Salle d'examen jusqu'à ce qu'un moyen soit possible. | à traduire |
| `recrutement.questionnaire.accordRemuneration` | J'accepte de recevoir ma rémunération par au moins un moyen validé par Rewayah. | à traduire |
| `recrutement.questionnaire.envoyer` | Envoyer ma candidature | à traduire |
| `recrutement.questionnaire.preRempli` | Certaines réponses viennent de votre ancien formulaire. Relisez-les avant d'envoyer. | à traduire |
| `recrutement.questionnaire.perime` | Le questionnaire a changé depuis votre dernière visite. Relisez les questions signalées. | à traduire |
| `recrutement.questionnaire.incomplet` | Il manque une réponse : {question}. | à traduire |
| `recrutement.questionnaire.accordManquant` | Cochez la case de rémunération pour envoyer votre candidature. | à traduire |
| `recrutement.questionnaire.cadreManquant` | Acceptez d'abord le cadre religieux et pédagogique. | à traduire |
| `accords.cadreNonPublie` | L'envoi de votre candidature sera possible quand le cadre religieux et pédagogique sera publié. | voir `TUT-00c/a+b` |
| `attente.lireEtAccepter` | Lire et accepter nos conditions | existante |
| `recrutement.questionnaire.conflit` | Votre candidature a changé depuis l'ouverture de cette page. Relisez-la, puis envoyez-la. | à traduire |
| `recrutement.questionnaire.horsLigne` | Votre candidature pourra être envoyée quand la connexion reviendra. | à traduire |
| `recrutement.questionnaire.nonOuverte` | Cette étape n'est pas encore ouverte. Votre compte est gardé. | à traduire |
| `recrutement.questionnaire.envoyee` | Votre candidature est envoyée. L'académie vous préviendra ici s'il faut la compléter. | à traduire |
| `recrutement.questionnaire.quitterQuestion` | Quitter sans envoyer votre candidature ? | à traduire |
| `recrutement.questionnaire.quitterConsequence` | Vos réponses ne sont pas gardées. | à traduire |
| `recrutement.questionnaire.quitter` | Quitter sans envoyer | à traduire |
| `recrutement.portail.complementDemande` | L'académie vous demande un complément. | voir `TUT-00b` |
| `recrutement.portail.complementListe` | À compléter : {elements}. | voir `TUT-00b` |
| `recrutement.paiement.*` | les quatre états du versement | voir 5.6 |

- **Contrat serveur** : L2 (`CAND-BR-10`, `CAND-BR-12`) ; libellés `fr` et `ar` dans
  `Questionnaire` et envoi d'un complément en salle 2, à préciser dans `PORTS`
  (L2) ; publics et montants rendus par `conditionsRemuneration` ; opérateurs L6
  (`CAND-BR-13`, `PortReferentielPaiement.optionsConfirmees`) ; pré-remplissage L3
  (`CAND-BR-17`). **Chemin critique** : aucun envoi avant le lot `conduite`, le texte
  du cadre validé, puis `CAND-BR-11` (`CONS` §11).
- **Contrôles d'acceptation** : 0 case de contrat, 0 dépôt de pièce (`CONS` 12.2) ;
  0 champ de compte ou de portefeuille ; 0 liste d'opérateurs vide ; 0 code de langue
  rendu tel quel ; 0 libellé de question ou d'option en dur ; une ligne de montant
  par public rendu, montants identiques à ceux du serveur de démonstration ; 0
  « Envoyer ma candidature » quand le cadre n'est pas publié ou pas accepté ; 0
  envoi sans fuseau confirmé ; après l'envoi, 0 champ modifiable hors complément ;
  L6-1 à L6-3 côté widget ; 5.7.

### TUT-00c/a+b étendu : Page d'accords (`/attente/accords`)

- **Statut** : proposée, à valider par le directeur.
- **Tâche** : accepter les textes requis **à l'étape courante**.
- **Route** : `/attente/accords`, inchangée (`routes.dart:76`, `app_router.dart:393-396`).
- **Entrée** : la prochaine action du portail ; la redirection de ré-acceptation
  (`redirection.dart:163-171`).
- **Droits (capacité)** : le titulaire. Les textes requis viennent de
  `contract_required_versions`.
- **Contenu** : la règle d'aujourd'hui ne change pas : une page qui défile, une case
  par texte, un seul « Suivant » (`ENTREE:30-31`, `accords_page.dart:85-104`). En
  Salle d'examen : le cadre religieux et pédagogique. En Salle de vérification et
  d'entretien : le contrat (`teacher_nda`) et l'avis
  (`recording_and_control_notice`) ; le code de conduite après le lot `conduite`.
  Une nouvelle version se ré-accepte avant la Salle des prêts à enseigner.
- **Écart** : trois moments au lieu de la page unique du 17/10 (`ENTREE:32`). Proposé
  par `CONS` 0.2 bis, ouvert en `CONS` 0.3.
- **Données jamais montrées** : 5.5.
- **Bouton plein** : « Suivant » (`accords.suivant`), inactif tant qu'une case manque
  (`ENTREE:31`).
- **Disposition** : inchangée. Mobile : une page qui défile. Tablette (768) :
  colonne de lecture bornée. Bureau : colonne de lecture bornée.
- **États** : ceux de la page aujourd'hui, plus **nouvelle version à ré-accepter**.
  Capacité indisponible : sans `CAND-BR-11`, la case du cadre n'est pas rendue ; en
  Salle d'examen il ne reste alors aucune case, et le portail ne propose pas « Lire
  et accepter nos conditions » ; `CAND-01` dit `accords.cadreNonPublie` à la place
  de son bouton.
- **Textes** :

| Clé proposée | Français | Arabe |
| :--- | :--- | :--- |
| `recrutement.cadre.titre` | Cadre religieux et pédagogique | voir 5.6 ; titre de la section |
| `accords.caseCadre` | Je confirme suivre le cadre religieux et pédagogique de Rewayah. | à traduire |
| `accords.cadreNouvelleVersion` | Le cadre religieux et pédagogique a changé. Lisez la nouvelle version, puis cochez la case. | à traduire |
| `accords.cadreNonPublie` | L'envoi de votre candidature sera possible quand le cadre religieux et pédagogique sera publié. | à traduire |
| `accords.caseContrat` | J'ai lu et j'accepte mon contrat, visites de contrôle comprises. | existante |
| `accords.suivant` | Suivant | existante |

  Le texte du cadre lui-même, en français et en arabe, est validé par le juriste puis
  soumis au directeur avant que L2 publie sa version requise (`CONS` §9, `DEC:34`).
- **Contrat serveur** : L2 (`CAND-BR-11`) ; mécanisme existant
  (`contract_acceptances`, `contract_required_versions`), aucun port neuf.
- **Contrôles d'acceptation** : en Salle d'examen, 0 case de contrat ; en Salle de
  vérification et d'entretien, 0 case du cadre déjà accepté ; « Suivant » inactif
  jusqu'à la dernière case ; point `CAND-F04` tranché avant le code ; 5.7.

### TUT-00c/c étendu : Dépôt de la pièce (`/attente/piece`)

- **Statut** : proposée, à valider par le directeur. Fiche ajoutée à la révision :
  le dépôt change de règle d'ouverture et gagne « à corriger ».
- **Tâche** : déposer sa pièce d'identité en Salle de vérification et d'entretien,
  ou une nouvelle quand la direction l'a dite à corriger.
- **Route** : `/attente/piece`, inchangée (`routes.dart:87`,
  `app_router.dart:407-410`) ; `DepotPiecePage` (`depot_piece_page.dart:33`).
- **Entrée** : la prochaine action du portail (« Déposer ma pièce », « Déposer une
  nouvelle pièce ») ; la ligne de la pièce dans « À compléter ».
- **Droits (capacité)** : le titulaire. **Quand il s'ouvre** : selon un champ rendu
  par `etat_dossier()` (l'existant `pieceRequise`, `etat_dossier.dart:119`, ou
  l'étape de la candidature), jamais `session.role` ; aujourd'hui la garde teste le
  rôle (`redirection.dart:156-162`, `CAND-F09`). En Salle d'examen, fermé : une
  adresse tapée revient à `/attente`. En base, le dépôt est réservé au rôle
  `teacher` (policy `kyc_staff_self_insert`,
  `M/0004_inscription_kyc_appairage.sql:169-174`) : L1 fixe la forme du compte
  candidat (`CONS` 3.1).
- **Contenu** : la page d'aujourd'hui (le type de pièce en cartes, la photo,
  « Envoyer ma pièce »). Quand la pièce est à corriger : en tête, le texte du modèle
  `piece_a_corriger` (5.8), mot pour mot, avec ce qui est à corriger.
- **Reprise** (`CONS` 3.3) : un compte né d'une invitation qui a déjà déposé une
  pièce la garde. En Salle d'examen, rien n'en est dit (0 lien de dépôt). En Salle
  de vérification et d'entretien, la pièce n'est pas redemandée : le portail et la
  page disent « Votre pièce est déjà déposée. », avec son état.
- **Données jamais montrées** : 5.5 ; le motif interne d'une correction.
- **Bouton plein** : « Envoyer ma pièce » (`kyc.envoyer`, existant).
- **Disposition** : inchangée. Mobile : la page d'aujourd'hui. Tablette (768) :
  colonne bornée. Bureau : colonne bornée.
- **États** :
  - `loading` : envoi en cours (indicateur dans le bouton) ; `content` ;
  - `empty` : sans objet ;
  - `error` : texte existant `kyc.erreur` et « Réessayer » ;
  - `offline` : la photo choisie reste ; note, « Votre pièce pourra être envoyée
    quand la connexion reviendra. » ; le bouton n'est pas rendu ;
  - capacité indisponible : tant que `CAND-BR-10` manque, la page et sa garde
    restent celles d'aujourd'hui ; aucun état de candidature n'est lu, aucune phrase
    n'en parle ;
  - **à déposer** ; **déposée** (en vérification) ; **à corriger** (texte du
    modèle) ; **validée** (le compte passe en Salle des prêts à enseigner, le
    portail ne le retient plus) ; **refusée définitivement** (la candidature est
    refusée, le portail dit le texte du modèle `refus`) ; **déjà déposée**
    (reprise).
- **Textes** :

| Clé proposée | Français | Arabe |
| :--- | :--- | :--- |
| `kyc.titre` | Votre pièce d'identité | existante |
| `kyc.envoyer` | Envoyer ma pièce | existante |
| `kyc.erreur` | L'envoi n'a pas abouti. Réessayez dans un instant. | existante |
| `recrutement.piece.dejaDeposee` | Votre pièce est déjà déposée. | à traduire |
| `recrutement.piece.horsLigne` | Votre pièce pourra être envoyée quand la connexion reviendra. | à traduire |
| `recrutement.portail.deposerNouvellePiece` | Déposer une nouvelle pièce | voir `TUT-00b` |

- **Contrat serveur** : L1 (forme du compte, dépôt admis au compte candidat) ; L2
  (`CAND-BR-05`, transition 15 ; `CAND-BR-10`, ouverture lue dans
  `etat_dossier()`) ; dépôt existant `supabase/functions/piece-identite-depot/index.ts` ;
  modèle `piece_a_corriger` en L5 (5.8).
- **Contrôles d'acceptation** : L2-5 ; widget : en Salle d'examen, 0 lien et route
  fermée ; la garde ne lit pas `session.role` ; à corriger : texte du modèle rendu
  mot pour mot, 0 motif interne ; reprise : 0 second dépôt demandé ; 5.7.

### CAND-02 : Mon entretien

- **Statut** : proposée, à valider par le directeur.
- **Tâche** : savoir quand a lieu l'entretien, puis le rejoindre.
- **Route** : `/attente/entretien` (neuve, déclarée dans le routeur unique), ouverte
  par « Voir les détails ». Sur le portail, une tuile **sans bouton plein**.
- **Entrée** : la tuile du portail, en Salle de vérification et d'entretien ; la
  notification d'un entretien planifié, annulé ou reprogrammé.
- **Droits (capacité)** : le candidat convoqué. L'état vient de `EntretienCandidat`,
  dans `etat_dossier()` étendu (`PORTS` §3).
- **Contenu, selon l'état** (`CONS` 6.2) : à planifier ; planifié (date, heure,
  fuseau de la personne et de l'académie) ; ouvert ; terminé (jamais le résultat) ;
  annulé ; manqué, selon l'issue (de la personne, ou de l'académie) ; inaccessible.
  Le nom de la personne qui mène l'entretien n'est pas montré : `EntretienCandidat`
  ne le porte pas. La durée non plus : `EntretienCandidat` ne la porte pas
  (`PORTS` l. 188-190), et `CONS` 6.2 ne la liste pas ; l'ajouter est une demande à
  L4 (`CONS` 0.1), et sa clé s'écrira alors. Aucune donnée absente du contrat n'est
  inventée (`GOV` §1).
- **Données jamais montrées** : résultat, compte rendu, constat, avis (5.5).
- **Bouton plein** : « Rejoindre l'entretien », seulement sur `/attente/entretien`,
  seulement à l'ouverture. La fenêtre est celle de la salle (`ctaSeance`,
  `cta_seance.dart:73`), appliquée par le jeton. Dans les autres états, aucun. La
  tuile du portail porte l'état, la date et le lien `LienFleche` « Voir les
  détails », jamais ce bouton : entretien ouvert, le portail a sa propre action
  pleine (`TUT-00b`).
- **Disposition** : tuile large du portail (2 × 1) ; détail : mobile, cartes ;
  tablette (768), page bornée, cartes en une colonne ; bureau, page bornée.
- **États** :
  - `loading` ; `content` ; `empty` : sans objet ;
  - `error` : « L'entretien n'a pas pu être chargé. » et « Réessayer » ;
  - `offline` : note, « L'entretien pourra être rejoint quand la connexion
    reviendra. » ; le bouton n'est pas rendu ;
  - capacité indisponible : avant L4, la tuile n'est pas rendue ; la route existe,
    et une adresse tapée montre « Les entretiens ne sont pas encore ouverts. » ;
  - **aucune candidature pour ce compte** : retour à `/attente` (5.1) ;
  - les sept états de `CONS` 6.2. **Manqué** : deux textes selon l'issue rendue
    par le serveur (l'issue est à ajouter à `EntretienCandidat` par L4, `CONS` 0.1).
    **Inaccessible** : la phrase et le lien « Écrire à l'académie », aucun bouton
    qui ne peut pas aboutir. Cette phrase dit un fait que le serveur connaît : elle
    est permise clé par clé dans la garde hors ligne (`UX`, États ; point
    `CAND-F11`).
- **Textes** :

| Clé proposée | Français | Arabe |
| :--- | :--- | :--- |
| `recrutement.entretien.titre` | Mon entretien | à traduire |
| `recrutement.entretien.aPlanifier` | Votre entretien sera planifié prochainement. | à traduire |
| `recrutement.entretien.planifie` | Votre entretien : {date} à {heure} ({fuseau}). | à traduire |
| `recrutement.entretien.heureIntervieweur` | Pour l'académie : {heure} ({fuseau}). | à traduire |
| `recrutement.entretien.voirDetails` | Voir les détails | à traduire |
| `recrutement.entretien.rejoindre` | Rejoindre l'entretien | voir 5.6 |
| `recrutement.entretien.termine` | Entretien terminé. L'académie vous répondra. | à traduire |
| `recrutement.entretien.annule` | Votre entretien a été annulé. Une nouvelle date vous sera proposée. | à traduire |
| `recrutement.entretien.manqueCandidat` | Vous n'avez pas rejoint l'entretien. L'académie vous dira la suite ici. | à traduire |
| `recrutement.entretien.manqueIntervieweur` | L'académie n'a pas pu mener l'entretien. Une nouvelle date vous sera proposée. | à traduire |
| `recrutement.entretien.inaccessible` | L'entretien n'est pas accessible pour le moment. | à traduire |
| `recrutement.entretien.chargementEchec` | L'entretien n'a pas pu être chargé. | à traduire |
| `recrutement.entretien.horsLigne` | L'entretien pourra être rejoint quand la connexion reviendra. | à traduire |
| `recrutement.entretien.nonOuvert` | Les entretiens ne sont pas encore ouverts. | à traduire |
| `recrutement.portail.ecrire` | Écrire à l'académie | voir 5.6 |

- **Contrat serveur** : L4 (`CAND-BR-08`) : séance `entretien`, jeton du candidat
  convoqué ; état par `CAND-BR-10`. À ajouter à `EntretienCandidat` par L4 :
  l'issue d'un entretien manqué, et l'identifiant de séance que porte le billet de
  salle (voir la fiche Salle).
- **Contrôles d'acceptation** : L4-1 (accepté à l'ouverture, refusé avant, refusé à un
  autre candidat) ; widget : un seul bouton plein à l'ouverture, sur
  `/attente/entretien` seulement ; 0 bouton plein dans la tuile du portail ; 0
  « Rejoindre la salle » ; 0 résultat rendu ; 0 durée rendue tant que le serveur ne
  la donne pas ; manqué par la personne : 0 promesse de nouvelle date ; 5.7.

### CAND-03 : Retirer ma candidature

- **Statut** : proposée, à valider par le directeur.
- **Tâche** : retirer sa candidature, en sachant l'effet avant.
- **Route** : aucune. Confirmation posée sur `/attente` (feuille sur mobile, boîte de
  dialogue sur tablette et bureau, `ConfirmDestructive`).
- **Entrée** : le lien discret « Retirer ma candidature », en bas du portail, rendu
  seulement tant que la candidature est en cours.
- **Droits (capacité)** : le titulaire.
- **Contenu** : la question ; l'effet, selon l'état rendu par le serveur
  (`EntretienCandidat`) : avec un entretien planifié, `consequenceAvecEntretien` ;
  sans entretien planifié, et toujours en Salle d'examen, `consequence`, qui ne
  parle d'aucun entretien (`MOTS` §1 : ne jamais dire ce qui n'est pas vrai).
- **Données jamais montrées** : 5.5.
- **Bouton plein** : aucun. Le geste est au niveau destructif de `ConfirmDestructive`.
- **Disposition** : celle de `ConfirmDestructive`. Mobile : feuille basse. Tablette
  (768) : boîte de dialogue. Bureau : boîte de dialogue.
- **États** :
  - `loading` : retrait en cours (indicateur dans le bouton) ; `content` ;
  - `empty` : sans objet ;
  - `error` : « Le retrait n'a pas abouti. » et « Réessayer » ; issue non confirmée
    selon 5.1 ;
  - `offline` : le lien n'est pas rendu ; note, « Le retrait pourra être fait quand
    la connexion reviendra. » ;
  - capacité indisponible : sans `PortMaCandidature.retirer`, le lien n'est pas rendu ;
  - **déjà retirée** : pas de lien, le portail dit « retirée » ;
  - **transition interdite** (`TransitionInterdite`) : « Votre candidature ne peut
    plus être retirée depuis cette page. » ; le lien « Écrire à l'académie » suit
    seulement si le serveur ouvre le fil (`CAND-F14`).
- **Textes** :

| Clé proposée | Français | Arabe |
| :--- | :--- | :--- |
| `recrutement.retrait.lien` | Retirer ma candidature | à traduire |
| `recrutement.retrait.question` | Retirer votre candidature ? | à traduire |
| `recrutement.retrait.consequenceAvecEntretien` | Votre entretien du {date} sera annulé. Seule l'académie pourra rouvrir votre candidature. | à traduire |
| `recrutement.retrait.consequence` | Seule l'académie pourra rouvrir votre candidature. | à traduire |
| `recrutement.retrait.confirmer` | Retirer ma candidature | à traduire |
| `recrutement.retrait.echec` | Le retrait n'a pas abouti. | à traduire |
| `recrutement.retrait.horsLigne` | Le retrait pourra être fait quand la connexion reviendra. | à traduire |
| `recrutement.retrait.interdit` | Votre candidature ne peut plus être retirée depuis cette page. | à traduire |
| `commun.annuler` | Annuler | existante |

- **Contrat serveur** : L2 (`CAND-BR-10`), `PortMaCandidature.retirer` ; transition 17.
- **Contrôles d'acceptation** : effet dit avant la confirmation ; en Salle d'examen,
  0 mention d'entretien ; retrait affiché seulement après la réponse ; 0 lien sur une
  candidature retirée ou refusée ; 5.7.

### CAND-05 : Écrire à l'académie (fil « Ma candidature »)

- **Statut** : proposée, à valider par le directeur.
- **Tâche** : poser une question, envoyer un complément, lire les réponses.
- **Route** : `/attente/messages` (neuve, déclarée), dans le sous-arbre du portail.
- **Entrée** : le lien « Écrire à l'académie » du portail ; le lien de l'état
  « inaccessible » de `CAND-02` ; la notification d'un nouveau message.
- **Droits (capacité)** : le titulaire ; un compte en attente est admis **pour ce
  seul objet** (`CONS` 7.1). Après un retrait ou un refus : `CAND-F14`.
- **Contenu** : un fil seul, sans liste de conversations, comme `CPT-12F` ; `FilContextuel`
  (`fil_contextuel.dart:59`) ouvert par
  `PortMessagesMetier.filPourObjet(TypeObjetLie.candidature, id)`. En-tête : « Ma
  candidature ». Un fil par candidature ; jamais de fil entre candidats.
- **Données jamais montrées** : 5.5 ; aucune liste de destinataires.
- **Bouton plein** : « Envoyer » (composant existant).
- **Disposition** : fil seul. Mobile : plein écran. Tablette (768) : fil seul,
  borné. Bureau : colonne bornée.
- **États** :
  - `loading` ; `content` ;
  - `empty` : « Aucun message pour le moment » (existante) ;
  - `error` : « La conversation n'a pas pu être chargée. » et « Réessayer » ;
  - `offline` : note du composant, le message reste dans le champ ;
  - capacité indisponible : sans L5, le lien du portail n'est pas rendu ; une adresse
    tapée montre « La conversation avec l'académie n'est pas encore ouverte. » ;
  - **aucune candidature pour ce compte** : retour à `/attente` (5.1) ;
  - **fil fermé par le serveur** (après un retrait ou un refus, si `CAND-F14` le
    décide ainsi) : le lien n'est pas rendu, une adresse tapée revient à `/attente` ;
  - **message non confirmé** : « Message non confirmé. Il est possible qu'il ne soit
    pas parvenu jusqu'à Rewayah. » et « Réessayer ».
- **Textes** :

| Clé proposée | Français | Arabe |
| :--- | :--- | :--- |
| `recrutement.portail.ecrire` | Écrire à l'académie | voir 5.6 |
| `recrutement.fil.entete` | Ma candidature | à traduire |
| `com.socle.composants.composer.aucunMessageTitre` | Aucun message pour le moment | existante |
| `com.socle.composants.composer.envoyer` | Envoyer | existante |
| `recrutement.fil.chargementEchec` | La conversation n'a pas pu être chargée. | à traduire |
| `recrutement.fil.nonOuverte` | La conversation avec l'académie n'est pas encore ouverte. | à traduire |
| `recrutement.fil.nonConfirme` | Message non confirmé. Il est possible qu'il ne soit pas parvenu jusqu'à Rewayah. | à traduire |

- **Contrat serveur** : L5 (`CAND-BR-18`) : objet `candidature` dans `com_fils.type_objet`
  et dans `TypeObjetLie` (`modeles_communication.dart:112`) ; compte en attente admis ;
  portée de genre ; accès au fil après un retrait ou un refus (`CAND-F14`).
- **Contrôles d'acceptation** : L5-1, L5-2 ; widget : 0 liste de conversations ; envoi
  dit seulement après la réponse ; 5.7.

### ENS-03 et ELV-03, mode entretien : Salle (`/salle`)

- **Statut** : proposée, à valider par le directeur.
- **Tâche** : mener l'entretien, la personne convoquée et la personne qui le mène
  face à face.
- **Route** : `/salle`, inchangée ; le billet passe par `extra`, jamais par l'adresse
  (`routes.dart:1093`, `billet_salle.dart:3-17`). L'identifiant de séance du billet
  vient de `EntretienCandidat`, qui doit le porter (`PORTS`, à ajouter par L4).
- **Entrée** : candidat : « Rejoindre l'entretien » de `CAND-02`. Intervieweur : la
  prochaine action d'`ADM-21`, ou le lien de sa ligne dans `ADM-20E`. Aujourd'hui la
  garde du billet ne joue que pour un compte actif (`redirection.dart:252-255`) et un
  compte en attente est ramené à `/attente` (`:172-174`) : point `CAND-F10`.
- **Droits (capacité)** : le seul candidat convoqué, compte en attente admis pour
  cette séance ; l'intervieweur désigné (`entretiens.mener`, même côté que le
  candidat, super-admin compris). Personne d'autre : ni contrôleur, ni observateur.
- **Contenu** : la même salle, aucune refonte LiveKit. **Aucune mention** : ni
  « Visite de contrôle possible. » (`mention_seance.dart:20-24`), ni « Entretien non
  enregistré » (`DEC:32`). Aucun enregistrement. Les blocs qui lisent une classe
  (élèves, présence, cahier de transmission) ne s'affichent pas : l'entretien n'en a
  pas (à confirmer en L4). **Noms** : en mode entretien, chaque personne est nommée
  par son nom, sans honorifique (« Sayyid », « Sayyida », `MOTS` §2, propres à la
  classe) ni rôle de classe (enseignant, élève).
- **Données jamais montrées** : genre, pièce, téléphone, réponses (`CONS` 6.1).
- **Bouton plein** : celui de la salle ; « Quitter l'entretien » passe par
  `ConfirmDestructive` (`confirmerQuitterSeance`).
- **Disposition** : celle de la salle, aux trois largeurs. Mobile, tablette (768)
  et bureau : `PageImmersive` existante, sans changement de grille.
- **Sortie** : candidat vers `/attente` ; intervieweur vers `ADM-21R`.
- **États** :
  - `loading` : ouverture de la salle ; `content` ;
  - `empty` : l'autre personne n'est pas encore là : « En attente de l'autre
    personne. » ;
  - `error` : « L'entretien n'a pas pu s'ouvrir. » et « Réessayer » ;
  - `offline` : signal propre de la salle (`PageImmersive`) ;
  - capacité indisponible : avant L4, aucune entrée n'est rendue ; un billet
    d'entretien est refusé par le jeton ;
  - **jeton refusé** : « L'entretien n'est pas accessible pour le moment. » et retour ;
  - **fin de séance** : « Entretien terminé. » et retour.
- **Textes** :

| Clé proposée | Français | Arabe |
| :--- | :--- | :--- |
| `salle.entretien.titre` | Entretien | à traduire |
| `salle.entretien.attente` | En attente de l'autre personne. | à traduire |
| `salle.entretien.quitter` | Quitter l'entretien | à traduire |
| `salle.entretien.quitterQuestion` | Quitter l'entretien ? | à traduire |
| `salle.entretien.ouvertureEchec` | L'entretien n'a pas pu s'ouvrir. | à traduire |
| `salle.entretien.termine` | Entretien terminé. | à traduire |
| `recrutement.entretien.inaccessible` | L'entretien n'est pas accessible pour le moment. | voir `CAND-02` |

- **Contrat serveur** : L4 (`CAND-BR-08`) : type `entretien`, forme de `teacher_id`
  (`CONS` 0.3), exclusions (paie, clôture automatique, chevauchement,
  `mes_seances_v`, contrôleur) ; revue de sécurité. **Jeton** : L4 étend la fonction
  existante `supabase/functions/create-room-token` et la règle `af_l2_01`
  (`M/20261017110100_af_l2_01_jeton_enseignant_effectif_et_retrait.sql:44-52`, qui
  refuse aujourd'hui tout compte hors `active` et `provisional_active`) au seul
  candidat convoqué d'une séance `entretien`. `EntretienCandidat` gagne
  l'identifiant de séance (`PORTS`). Le nom de chaque personne est celui que pose
  le jeton, sans honorifique.
- **Contrôles d'acceptation** : 0 mention de séance, 0 donnée sensible (`CONS` 12.2) ;
  L4-1, L4-2, L4-3 ; 0 « Rejoindre la salle » ; 0 « Sayyid » ni « Sayyida » en mode
  entretien ; 5.7.

---

## 7. Côté direction

### ADM-20 : Candidatures

- **Statut** : proposée, à valider par le directeur.
- **Tâche** : trouver une candidature, voir ce qui bloque, agir seul ou en lot.
- **Route** : `/admin/personnes/candidatures` (neuve). L'onglet « Candidatures »
  remplace « Invitations » à son rang (`admin_domaine.dart:273-277`) : pas de
  septième onglet (`DEC:27`). L'ancienne adresse, l'invitation du comptable et la
  révocation d'une invitation : point `CAND-F01`.
- **Entrée** : l'onglet de Personnes ; les alertes de l'Accueil, si le directeur les
  y veut (non décidé).
- **Droits (capacité)** : `candidatures.lire` (`CapacitesCandidatures.peutLire`).
  Gestes : `peutDecider`. Recherche par téléphone : `peutVoirContact`, journalisée.
  Lien d'import : `peutImporter`. Portée femmes et hommes en base. Exception de
  lecture du super-admin : `peutLireHorsGenre` (5.5), chaque lecture journalisée.
- **Contenu, de haut en bas** :
  1. **exception du super-admin active** (`peutLireHorsGenre`) : un bandeau, en tête ;
  2. `SelecteurSection` : « Candidatures » et « Entretiens » (`ADM-20E`), contrôle
     segmenté (ONGLETS-1). Une troisième section « Formulaires » seulement si
     `CAND-F13` est tranché ainsi, avec sa fiche ;
  3. **une** carte « À traiter » : les quatre alertes, jamais confondues, chacune avec
     son mot, son icône et son nombre ; toucher une alerte pose le filtre. Une pause
     n'entre dans aucune (`CONS` §10) ;
  4. recherche (`ChampRecherche`) : nom partiel, arabe et latin normalisés ; référence
     `CAND-` exacte ; courriel exact ; téléphone exact avec `peutVoirContact` ;
  5. une seule `RangeeFiltres` : « Toutes », « Gardées pour suivi », « Invitées »,
     puis les trois salles en entier, chacune avec son compteur rendu par le
     serveur. **« Gardées pour suivi » dépend de `CONS` 0.3 (ligne `recue` de
     suivi), à confirmer par le directeur ; en production, sans sa réponse, ni ce
     filtre, ni le geste, ni la prochaine action ne sont rendus** (réponse lue au
     serveur, capacité ou clé `app_config` nommée en L3). « Plus » (`MenuFiltre`) :
     responsable ; affectée ou non (Salle des prêts à enseigner) ; sans activité
     depuis N jours (N lu dans `app_config`) ; état ; refusées, retirées ; pause ;
     versement ; pièce ; entretien ; pays de résidence ; langues d'explication ;
     niveau déclaré ; heures par semaine ; date de début ; besoin ouvert (genre et
     langue de la classe à pourvoir) ; provenance ; date de réception ; dernière
     activité ;
  6. tri, au serveur : « Besoin, niveau, disponibilité » (par défaut, clés en clair,
     jamais un score, `DEC:43`), « Date de réception », « Dernière activité »,
     « Date d'entretien » ;
  7. la liste, paginée au serveur, total réel du filtre. **Une ligne** : nom ;
     référence ; salle ; état (`StatusPill`, mot et icône, libellés de 5.6) ; clés de
     tri en clair (niveau constaté ou déclaré, heures par semaine, date de début,
     compte bancaire oui ou non) ; pays de résidence ; versement ; entretien et son
     lien ; responsable ; dernière activité ; marques « Courriel à obtenir » et
     « Indicatif à confirmer » ; état du courriel ; lien envoyé par WhatsApp, avec sa
     date ;
  8. liens : « Sélectionner » ; « Importer les formulaires » (`peutImporter`) ;
     « Inviter un comptable » (`CAND-F01`).
- **Deux cibles par ligne** (`CONS` 12.2) : la ligne entière ouvre `ADM-21` ; le lien
  d'entretien est une cible à part. En mode sélection, la case remplace l'ouverture :
  toujours deux cibles.
- **Données jamais montrées** : courriel, téléphone, genre, pièce, motif interne,
  compte rendu, constat, réponse libre (`CONS` 8.3). Une candidature hors portée
  n'apparaît ni dans la liste ni dans un compteur.
- **Bouton plein** : aucun sans sélection. Quand une sélection existe, « Agir sur la
  sélection » dans `BarreSelection` promue (`barre_selection.dart:17`), qui mène à
  `ADM-22`. **En mode sélection, le détail se ferme** : la file reste seule, sur la
  largeur utile, et toucher une ligne coche sa case au lieu d'ouvrir `ADM-21`. La
  prochaine action d'`ADM-21` et « Agir sur la sélection » ne sont donc jamais
  rendues ensemble. « Tout relâcher » rend la file et le détail.
- **Disposition** : mobile 360 : une carte par candidature (nom, salle, état, lien
  d'entretien, puis deux lignes de clés) ; la barre de sélection collée en bas ;
  les quatre alertes en quatre lignes d'une même carte. Tablette (768) : liste et
  `ADM-21` en deux volets ; en mode sélection, liste seule. Bureau 1440 : sans
  dossier ouvert ou en mode sélection, tableau dense sur la largeur utile (1088) ;
  dossier ouvert, file 336, écart 24, détail 728. Les quatre alertes côte à côte
  dans **une** carte : pas quatre cartes égales (`ENTREE:19`). Pas de bento : c'est
  une file.
- **États** :
  - `loading` : `Skeleton.liste` à la forme des lignes ; `content` ;
  - `empty` : « Aucune candidature pour le moment » ;
  - **recherche sans résultat** : les filtres sont rappelés, « Effacer les filtres » ;
  - `error` : « Les candidatures n'ont pas pu être lues. » et « Réessayer » ;
  - `offline` : la dernière lecture reste ; aucune action proposée ; dans la barre de
    sélection, une phrase à la place d'« Agir sur la sélection » ;
  - capacité indisponible : `EtatSysteme` indisponible, « Disponible au branchement
    serveur » ;
  - **données partielles** : un compteur non servi le dit seul ;
  - **accès refusé** (`PermissionInsuffisante`) : « Vous n'avez pas accès aux
    candidatures. » ;
  - **genre du lecteur inconnu** (refus en base) : « Les candidatures ne s'affichent
    pas : votre fiche ne dit pas de quel côté vous travaillez. Demandez à la
    direction de la compléter. » ;
  - **exception du super-admin active** : le bandeau en tête ;
  - **mode sélection** : file seule, « Agir sur la sélection » ;
  - **alertes à zéro** : chaque compteur dit 0, « Rien à traiter ».
- **Textes** :

| Clé proposée | Français | Arabe |
| :--- | :--- | :--- |
| `admin.candidatures.titre` | Candidatures | à traduire ; onglet, titre de page et section |
| `admin.candidatures.sousTitre` | Les candidatures d'enseignement, de l'invitation à la Salle des prêts à enseigner. | à traduire |
| `admin.candidatures.sectionEntretiens` | Entretiens | à traduire |
| `admin.candidatures.exception.titre` | Lecture des deux côtés | à traduire |
| `admin.candidatures.exception.message` | Vous lisez les candidatures des femmes et des hommes. Chaque lecture est inscrite au journal. | à traduire |
| `admin.candidatures.aTraiter` | À traiter | à traduire |
| `admin.candidatures.alertes.bloquees` | Bloquées | à traduire |
| `admin.candidatures.alertes.entretiensEnRetard` | Entretiens en retard | à traduire |
| `admin.candidatures.alertes.informationsManquantes` | Informations manquantes | à traduire |
| `admin.candidatures.alertes.confirmeesIndisponibles` | Confirmées indisponibles | à traduire |
| `admin.candidatures.alertes.rien` | Rien à traiter | à traduire |
| `admin.candidatures.recherche` | Rechercher un nom, une référence ou un courriel | à traduire |
| `admin.candidatures.rechercheTelephone` | La recherche par téléphone est inscrite au journal. | à traduire |
| `admin.candidatures.filtres.toutes` | Toutes | à traduire |
| `admin.candidatures.filtres.gardees` | Gardées pour suivi | à traduire ; dépend de `CONS` 0.3 |
| `admin.candidatures.filtres.invitees` | Invitées | à traduire |
| `commun.filtres.plus` | Plus | existante |
| `admin.candidatures.filtres.sansActivite(param=n)` | `one` : Sans activité depuis {n} jour ; `other` : Sans activité depuis {n} jours | à traduire, six formes |
| `admin.candidatures.filtres.affectee` | Affectée à une classe | à traduire |
| `admin.candidatures.filtres.nonAffectee` | Pas encore affectée | à traduire |
| `admin.candidatures.filtres.besoin` | Besoin ouvert | à traduire |
| `admin.candidatures.filtres.provenance` | Provenance | à traduire |
| `admin.candidatures.filtres.versement` | Versement | à traduire |
| `admin.candidatures.tri.cles` | Besoin, niveau, disponibilité | à traduire |
| `admin.candidatures.tri.reception` | Date de réception | à traduire |
| `admin.candidatures.tri.activite` | Dernière activité | à traduire |
| `admin.candidatures.tri.entretien` | Date d'entretien | à traduire |
| `admin.candidatures.ligne.niveauConstate` | Niveau constaté : {niveau} | à traduire |
| `admin.candidatures.ligne.niveauDeclare` | Niveau déclaré : {niveau} | à traduire |
| `admin.candidatures.ligne.heures` | {n} h par semaine | à traduire ; « h » ne s'accorde pas |
| `admin.candidatures.ligne.debut` | À partir du {date} | à traduire |
| `admin.candidatures.ligne.compteBancaireOui` | Compte bancaire : oui | à traduire |
| `admin.candidatures.ligne.compteBancaireNon` | Compte bancaire : non | à traduire |
| `admin.candidatures.ligne.courrielAObtenir` | Courriel à obtenir | à traduire |
| `admin.candidatures.ligne.indicatifAConfirmer` | Indicatif à confirmer | à traduire |
| `admin.candidatures.ligne.lienWhatsapp` | Lien envoyé par WhatsApp le {date} | à traduire |
| `admin.candidatures.courriel.aEnvoyer` | Courriel pas encore envoyé | à traduire |
| `admin.candidatures.courriel.envoye` | Courriel envoyé le {date} | à traduire |
| `admin.candidatures.courriel.echec` | Courriel non parti | à traduire |
| `admin.candidatures.gestes.planifier` | Planifier un entretien | voir `ADM-21` |
| `recrutement.entretien.rejoindre` | Rejoindre l'entretien | voir 5.6 |
| `admin.candidatures.selection.selectionner` | Sélectionner | à traduire |
| `admin.candidatures.selection.retenues(param=n)` | `one` : {n} candidature retenue ; `other` : {n} candidatures retenues | à traduire, six formes |
| `admin.candidatures.selection.agir` | Agir sur la sélection | à traduire |
| `admin.candidatures.selection.relacher` | Tout relâcher | à traduire |
| `admin.candidatures.selection.horsLigne` | Les actions pourront être lancées quand la connexion reviendra. | à traduire |
| `admin.candidatures.importer` | Importer les formulaires | à traduire |
| `admin.candidatures.inviterComptable` | Inviter un comptable | à traduire |
| `admin.candidatures.vide` | Aucune candidature pour le moment | à traduire |
| `admin.candidatures.aucunResultat` | Aucune candidature ne correspond à ces filtres. | à traduire |
| `admin.journal.effacerFiltres` | Effacer les filtres | existante |
| `admin.candidatures.lectureEchec` | Les candidatures n'ont pas pu être lues. | à traduire |
| `admin.candidatures.accesRefuse` | Vous n'avez pas accès aux candidatures. | à traduire |
| `admin.candidatures.genreInconnu` | Les candidatures ne s'affichent pas : votre fiche ne dit pas de quel côté vous travaillez. Demandez à la direction de la compléter. | à traduire |
| `admin.candidatures.etats.*` | libellés des états | voir 5.6 |

- **Contrat serveur** : L1 (`CAND-BR-01`, `CAND-BR-02`) :
  `PortCandidaturesDirection.capacites` (dont `peutLireHorsGenre`), `.lister` (filtre,
  tri, page, compteurs d'étapes). **À ajouter à `LigneCandidature`** (`PORTS`
  l. 116-121, `CONS` 0.1) : les clés de tri de `CONS` 5.2 (niveau constaté ou
  déclaré, heures par semaine, date de début, compte bancaire), l'état du courriel
  (L5, lecture à nommer, `CONS` 0.1), la provenance, l'affectation, et pour la vue
  Entretiens la date, les fuseaux et la personne qui mène l'entretien (L4). **À
  ajouter à `FiltreCandidatures`** : besoin ouvert, affectée ou non, provenance,
  sans activité depuis N jours, état `paiement_non_disponible`. **Compteurs
  d'alertes** : « informations manquantes » en L1, complété par L2 (complément en
  salle 2) et L3 (marques de l'import) ; « bloquées » et « confirmées
  indisponibles » en L2 (contrôles, indisponibilité) ; « entretiens en retard » en
  L4. Un compteur non servi le dit seul. Gestes L2. Réponse à `CONS` 0.3 sur la
  ligne `recue` : lue au serveur (L3).
- **Contrôles d'acceptation** : L1-2, L1-5, L1-8, L1-9 ; widget à 1 000 lignes, sur le
  modèle de `test/features/admin_regroupements/echelle_listes_test.dart` ; deux cibles
  par ligne ; 0 courriel, téléphone, genre ou pièce dans le rendu ; 0 bouton plein
  sans sélection, 1 avec ; `verifierUnSeulBoutonPlein` à 1440 avec un dossier ouvert
  puis une sélection : 1 ; production sans réponse de `CONS` 0.3 : 0 « Gardées pour
  suivi » rendu ; courriel `a_envoyer` : « Courriel pas encore envoyé », 0 « envoyé
  le » (`CONS` 12.2) ; 0 code d'état brut ; bandeau d'exception rendu seulement avec
  `peutLireHorsGenre` ; `BarreSelection` promue présente dans la galerie
  (`test/widgets/catalogue_galerie_test.dart`) ; confirmée indisponible distincte de
  prête à affecter (L2-14) ; 5.7.

### ADM-20E : Entretiens

- **Statut** : proposée, à valider par le directeur. Code ajouté par ce catalogue
  (`CAND-F08`).
- **Tâche** : voir les entretiens à planifier, à venir, en retard et terminés, et agir
  sur chacun.
- **Route** : `/admin/personnes/candidatures?vue=entretiens`, comme
  `/comptable?vue=attention` (`C/CATALOGUE_ECRANS_COMPTABLE.md:25`).
- **Entrée** : la section « Entretiens » d'`ADM-20` ; l'alerte « Entretiens en retard ».
- **Droits (capacité)** : `candidatures.lire`. « Mes entretiens » :
  `PortCandidaturesDirection.mesEntretiens`. « Rejoindre l'entretien » n'est rendu
  que pour l'intervieweur désigné : le serveur refuse le jeton à tout autre
  (`CONS` 4.3).
- **Contenu** : en tête, les entretiens en retard (date passée sans compte rendu
  depuis plus de 24 h, ou « à planifier » depuis plus de N jours) ; puces : « À
  planifier », « À venir », « En retard », « Terminés », « Mes entretiens ». Une ligne :
  date et heure dans le fuseau du lecteur, heure de la personne convoquée avec son
  fuseau ; nom (ouvre `ADM-21`) ; « Mené par » ; état (libellés de 5.6) ; le lien de
  l'état (`CONS` 6.2) : « Planifier un entretien », « Voir les détails »,
  « Rejoindre l'entretien », « Écrire le compte rendu », « Reprogrammer ».
- **Données jamais montrées** : 5.5 ; ni téléphone, ni pièce.
- **Bouton plein** : aucun. Les liens d'une ligne sont secondaires (`CAND-Q14`).
- **Disposition** : mobile : cartes regroupées par date. Tablette (768) : liste et
  `ADM-21` en deux volets. Bureau : tableau trié par date ; file et détail quand un
  dossier est ouvert.
- **États** :
  - `loading` ; `content` ;
  - `empty` : « Aucun entretien pour le moment » ;
  - `error` : « Les entretiens n'ont pas pu être lus. » et « Réessayer » ;
  - `offline` : la dernière lecture reste ; aucun lien d'action ;
  - capacité indisponible : avant L4, la section dit « Disponible au branchement
    serveur » ;
  - **personne de ce côté pour le mener** : la ligne attend et compte dans l'alerte ;
  - **annulé** : « Annulé le {date} par {nom} » ; **manqué** : « Manqué par la
    personne convoquée » ou « Manqué par la personne qui devait le mener » ;
    **inaccessible** : la phrase de `CONS` 6.2 et « Reprogrammer ».
- **Textes** :

| Clé proposée | Français | Arabe |
| :--- | :--- | :--- |
| `admin.candidatures.etats.entretien.aPlanifier` | À planifier | voir 5.6 ; puce |
| `admin.candidatures.entretiens.aVenir` | À venir | à traduire |
| `admin.candidatures.entretiens.enRetard` | En retard | à traduire |
| `admin.candidatures.entretiens.termines` | Terminés | à traduire |
| `admin.candidatures.entretiens.mesEntretiens` | Mes entretiens | à traduire |
| `admin.candidatures.entretiens.heurePersonne` | Pour la personne : {heure} ({fuseau}) | à traduire |
| `admin.candidatures.planifier.menePar` | Mené par | voir `ADM-21` |
| `admin.candidatures.gestes.planifier` | Planifier un entretien | voir `ADM-21` |
| `recrutement.entretien.voirDetails` | Voir les détails | voir `CAND-02` |
| `admin.candidatures.entretiens.ecrireCompteRendu` | Écrire le compte rendu | à traduire |
| `admin.candidatures.entretiens.reprogrammer` | Reprogrammer | à traduire |
| `admin.candidatures.entretiens.annuleLe` | Annulé le {date} par {nom} | à traduire |
| `admin.candidatures.entretiens.manquePersonne` | Manqué par la personne convoquée | à traduire |
| `admin.candidatures.entretiens.manqueDirection` | Manqué par la personne qui devait le mener | à traduire |
| `admin.candidatures.entretiens.sansIntervieweur` | Personne de ce côté ne peut encore mener cet entretien | à traduire |
| `admin.candidatures.entretiens.vide` | Aucun entretien pour le moment | à traduire |
| `admin.candidatures.entretiens.lectureEchec` | Les entretiens n'ont pas pu être lus. | à traduire |

- **Contrat serveur** : L4 (`CAND-BR-08`) : `.lister` filtré sur la Salle de
  vérification et d'entretien et trié par date d'entretien, avec la date, les
  fuseaux et la personne qui mène l'entretien sur la ligne (à ajouter à
  `LigneCandidature`, voir `ADM-20`) ; `.mesEntretiens` ; seuil N dans `app_config`.
- **Contrôles d'acceptation** : L4-3 ; widget : « Rejoindre l'entretien » rendu pour
  l'intervieweur désigné seulement ; 0 bouton plein ; alerte « en retard » en tête ;
  5.7.

### ADM-21 : Candidature

- **Statut** : proposée, à valider par le directeur.
- **Tâche** : comprendre une candidature d'un coup d'oeil et faire la prochaine
  action.
- **Route** : `/admin/personnes/candidatures/<référence>`. La référence est `CAND-…`,
  jamais l'identifiant du profil ni un nom : point `CAND-F02`.
- **Entrée** : une ligne d'`ADM-20` ou d'`ADM-20E` ; une notification ; `ADM-02`
  (lien « Voir la candidature »).
- **Droits (capacité)** : `candidatures.lire`. Gestes : `candidatures.decider`.
  Contact : `candidatures.contact`. Entretien : `entretiens.mener`, intervieweur
  désigné. Conversation : `candidatures.messages`. Exception de lecture :
  `peutLireHorsGenre` (5.5). Hors portée et absente : deux erreurs.
- **Contenu, dans cet ordre** (`CONS` §10). En tête, sur une candidature de l'autre
  côté lue par l'exception du super-admin : la phrase
  `admin.candidatures.exception.candidature`. Puis :
  1. étape et issue : la salle en entier, l'état, la pause, la restriction et sa
     cause, l'indisponibilité, par leurs libellés de 5.6 ;
  2. **blocages** : chaque contrôle faux, nommé, avec sa cause ;
  3. **la prochaine action**, rendue par le serveur ;
  4. réponses, avec la version du questionnaire ; les réponses pré-remplies marquées ;
     un rattachement proposé par téléphone, avec « Rattacher les anciennes réponses » ;
  5. les huit contrôles : vrai ou faux, cause ;
  6. pièce : son état seulement, et le lien « Ouvrir dans Dossiers à valider »
     (`ADM-02`) ;
  7. entretien : état, date, fuseaux, personne qui le mène, issue, compte rendu,
     constat, avis ;
  8. responsable ;
  9. affectation, lue dans les classes : « Affectée à {n} classes » ou « Pas encore
     affectée », jamais confondue avec confirmée, active ou disponible ;
     coordonnées financières après la Salle des prêts à enseigner (absentes ou
     enregistrées, lues dans `CPT-13`) ;
  10. contact : masqué, lien « Voir le contact » ;
  11. courriels : état de chacun (`CONS` 7.3) ; lien envoyé par WhatsApp ;
  12. historique : une ligne par événement (date, ancien et nouvel état par leurs
      libellés, auteur, motif), du plus récent au plus ancien, paginé ; composant
      neuf (`REVUE` §10.3). **L'auteur se dit par sa qualité, jamais par son nom** :
      « Vous », « La direction », « La personne », « Automatique » (`CAND-BR-07` :
      « sans aucun nom » ; L1-6 : 0 nom).
  Liens : « Écrire à {nom} » (`ADM-21F`) ; menu des autres gestes (`MenuActions`).
- **Prochaine action, selon l'état** : ligne gardée pour suivi : « Inviter » (fermé en
  production tant que l'envoi de la file manque, `CONS` 3.3) ou, sans courriel
  valide, « Consigner le lien envoyé par WhatsApp ». **Cette ligne dépend de `CONS`
  0.3 (ligne `recue` de suivi), à confirmer par le directeur ; en production, sans sa
  réponse, ni le filtre, ni le geste, ni la prochaine action ne sont rendus.** En
  examen, versement à vérifier : « Confirmer le moyen de versement » ; versement
  confirmé : « Admettre en Salle de vérification et d'entretien » ; entretien à
  planifier : « Planifier un entretien » ; entretien ouvert, pour l'intervieweur
  désigné : « Rejoindre l'entretien » ; entretien passé sans compte rendu : « Écrire
  le compte rendu » ; décision en attente, sept contrôles vrais : « Revoir la pièce
  d'identité » (`ADM-02`) ; en pause : « Lever la pause ». Ailleurs, aucune ; la
  raison est écrite (« En attente de la personne »).
- **Gestes du menu** (rendus seulement s'ils sont permis depuis l'état) : demander un
  complément ; écarter un moyen de versement ; mettre en pause ; refuser ; enregistrer
  un retrait demandé ; rouvrir ; restreindre ; lever la restriction ; noter ou lever
  une indisponibilité ; choisir le responsable. « Garder pour suivi » ne se fait pas
  ici : il part d'une réponse importée (transition 2), que seule la vue proposée en
  `CAND-F13` montrerait.
- **Feuilles d'`ADM-21`** (`AppBottomSheet` : feuille sur mobile, boîte de dialogue
  sur tablette et bureau ; un bouton plein chacune). Chaque feuille dont une liste
  n'est pas servie dit « Disponible au branchement serveur » à la place du choix :
  - **Planifier un entretien** : date (`ChampDate`) ; heure et durée choisies dans
    les listes de `optionsPlanification` ; la personne qui mène l'entretien,
    choisie parmi `intervieweursAutorises(candidatureId)` (`SelecteurPersonne`) ;
    deux méthodes à ajouter à `PORTS` (L4). L'heure de la personne convoquée et
    celle du lecteur s'affichent avec leur fuseau. Bouton : « Planifier un
    entretien ». « Reprogrammer » ouvre d'abord l'issue de l'entretien manqué ou
    annulé, avec son motif ; « Planifier un entretien » redevient ensuite la
    prochaine action ;
  - **Demander un complément** (transitions 7 et 23) : feuille propre, hors du geste
    motivé. Les éléments manquants se **choisissent** dans la liste fermée des
    questions du questionnaire, à la version de la candidature (K-57 : choisi,
    jamais saisi), rendue avec `.lire` (forme à préciser dans `PORTS`, L2). La
    phrase « La personne lira cette liste. ». Aucun motif interne, aucun texte
    libre : la liste nommée est le motif exigé, rendu au candidat (`PORTS`
    l. 84-85 ; `CONS` transitions 7 et 23). Bouton : « Demander un complément ».
    Ouverte depuis le refus `FuseauInconnu`, la question du fuseau est déjà cochée ;
  - **Geste motivé** (pause, refus, écart d'un moyen, rouvrir, restreindre, lever
    la restriction, retrait demandé) : motif interne saisi, seul champ libre (la
    direction seule le connaît). Quand le geste l'exige (`ModeleRequis` : refus,
    pause), le modèle se choisit parmi `modelesMessage(geste)` (L5, à ajouter à
    `PORTS`, 5.8) ; sous le choix, son texte mot pour mot, et la phrase « La
    personne lira ce message. ». Bouton : le verbe du geste ;
  - **Contact** : courriel et téléphone ; la phrase « Cette ouverture est inscrite au
    journal. » ; aucun bouton plein ;
  - **Responsable** : un membre de la direction de ce côté, choisi parmi
    `responsablesPossibles(candidatureId)` (L2, à ajouter à `PORTS`), ou personne.
    Bouton : « Enregistrer ».
- **Données jamais montrées** : la pièce elle-même (seulement son état) ; le genre ;
  le contact hors de sa feuille ; un nom dans l'historique.
- **Bouton plein** : la prochaine action, une seule ; aucune quand l'action attend la
  personne. En mode sélection d'`ADM-20`, le détail est fermé (fiche `ADM-20`).
- **Disposition** : mobile : page, sections empilées, la prochaine action en haut
  sous les blocages. Tablette (768) : volet de détail à côté de la liste ; ouvert
  seul, une colonne. Bureau : détail 728 à côté de la file ; ouvert seul à 1440,
  deux colonnes : au début (start), étape, blocages, prochaine action, contrôles ;
  à la fin (end), dans l'ordre de `CONS` §10, réponses, pièce, entretien,
  responsable, affectation, contact, courriels, historique.
- **États** :
  - `loading` ; `content` ;
  - `empty` : sans objet ; historique vide : « Aucun événement pour le moment » ;
  - `error` : « La candidature n'a pas pu être lue. » et « Réessayer » ;
  - `offline` : la dernière lecture reste ; aucun geste rendu ; une note le dit ;
  - capacité indisponible : sans `CAND-BR-03`, la page le dit ; sans un bloc (entretien
    L4, historique `CAND-BR-07`), ce bloc seul le dit ; sans une liste d'une feuille,
    cette feuille seule le dit ;
  - **bloquée** (contrôle nommé) ; **contact masqué** ; **hors portée** ; **absente** ;
  - **exception du super-admin** : la phrase en tête, sur une candidature de l'autre
    côté ;
  - **versement** inconnu, à vérifier, confirmé, aucun moyen possible ;
  - **geste refusé** : `ControlesNonSatisfaits` (contrôles nommés),
    `TransitionInterdite` (état courant nommé par son libellé de 5.6),
    `MotifRequis`, `ModeleRequis`, `FuseauInconnu` (avec le lien « Demander un
    complément »), `IntervieweurNonAutorise` ; **conflit** (`ConflitCandidature`) :
    « Cette candidature a changé depuis son ouverture. Relisez-la avant d'agir. » ;
  - succès seulement après la réponse ; la candidature est relue.
- **Textes** :

| Clé proposée | Français | Arabe |
| :--- | :--- | :--- |
| `admin.candidatures.exception.candidature` | Cette candidature est de l'autre côté : sa lecture est inscrite au journal. | à traduire |
| `admin.candidatures.detail.blocages` | Ce qui bloque | à traduire |
| `admin.candidatures.detail.prochaineAction` | Prochaine action | à traduire |
| `admin.candidatures.detail.enAttentePersonne` | En attente de la personne | à traduire |
| `admin.candidatures.detail.reponses` | Réponses | à traduire |
| `admin.candidatures.detail.preRempli` | Venu de l'ancien formulaire | à traduire |
| `admin.candidatures.detail.controles` | Contrôles | à traduire |
| `dossiers.revue.piece` | Pièce d'identité | existante |
| `admin.candidatures.detail.ouvrirDossier` | Ouvrir dans Dossiers à valider | à traduire |
| `admin.candidatures.detail.entretien` | Entretien | à traduire |
| `admin.candidatures.detail.responsable` | Responsable | à traduire |
| `admin.candidatures.detail.affectee(param=n)` | `one` : Affectée à {n} classe ; `other` : Affectée à {n} classes | à traduire, six formes |
| `admin.candidatures.detail.nonAffectee` | Pas encore affectée | à traduire |
| `admin.candidatures.detail.coordonneesAbsentes` | Coordonnées financières : pas encore enregistrées | à traduire |
| `admin.candidatures.detail.coordonneesEnregistrees` | Coordonnées financières : enregistrées | à traduire |
| `admin.candidatures.detail.contactMasque` | Contact masqué | à traduire |
| `admin.candidatures.detail.voirContact` | Voir le contact | à traduire |
| `admin.candidatures.detail.contactJournal` | Cette ouverture est inscrite au journal. | à traduire |
| `historique.titre` | Historique | existante |
| `admin.candidatures.detail.historiqueVide` | Aucun événement pour le moment | à traduire |
| `admin.candidatures.historique.auteur.vous` | Vous | à traduire |
| `admin.candidatures.historique.auteur.direction` | La direction | à traduire |
| `admin.candidatures.historique.auteur.personne` | La personne | à traduire |
| `admin.candidatures.historique.auteur.automatique` | Automatique | à traduire |
| `com.messages.entree.ecrireA` | Écrire à {nom} | existante |
| `admin.candidatures.gestes.inviter` | Inviter | à traduire |
| `admin.candidatures.gestes.consignerLien` | Consigner le lien envoyé par WhatsApp | à traduire |
| `admin.candidatures.gestes.confirmerMoyen` | Confirmer le moyen de versement | à traduire |
| `admin.candidatures.gestes.ecarterMoyen` | Écarter ce moyen de versement | à traduire |
| `admin.candidatures.gestes.admettre` | Admettre en Salle de vérification et d'entretien | à traduire |
| `admin.candidatures.gestes.planifier` | Planifier un entretien | à traduire ; prochaine action, lien de ligne et bouton de la feuille |
| `admin.candidatures.gestes.revoirPiece` | Revoir la pièce d'identité | à traduire |
| `admin.candidatures.gestes.demanderComplement` | Demander un complément | à traduire |
| `admin.candidatures.gestes.mettreEnPause` | Mettre en pause | à traduire |
| `admin.candidatures.gestes.leverPause` | Lever la pause | à traduire |
| `admin.candidatures.gestes.refuser` | Refuser la candidature | à traduire |
| `admin.candidatures.gestes.retrait` | Enregistrer un retrait demandé | à traduire |
| `admin.candidatures.gestes.rouvrir` | Rouvrir la candidature | à traduire |
| `admin.candidatures.gestes.restreindre` | Restreindre | à traduire |
| `admin.candidatures.gestes.leverRestriction` | Lever la restriction | à traduire |
| `admin.candidatures.gestes.noterIndisponibilite` | Noter une indisponibilité | à traduire |
| `admin.candidatures.gestes.leverIndisponibilite` | Lever l'indisponibilité | à traduire |
| `admin.candidatures.gestes.rattacher` | Rattacher les anciennes réponses | à traduire |
| `admin.candidatures.gestes.responsable` | Choisir le responsable | à traduire |
| `admin.candidatures.complement.elements` | Ce qui manque | à traduire |
| `admin.candidatures.complement.aide` | La personne lira cette liste. | à traduire |
| `admin.candidatures.complement.manquant` | Choisissez au moins un élément. | à traduire |
| `admin.candidatures.feuille.motif` | Motif interne | à traduire |
| `admin.candidatures.feuille.motifAide` | La personne ne le lira pas. Elle lira seulement le message choisi. | à traduire |
| `admin.candidatures.feuille.modele` | Message pour la personne | à traduire |
| `admin.candidatures.feuille.modeleLu` | La personne lira ce message. | à traduire |
| `admin.candidatures.feuille.motifManquant` | Indiquez le motif. | à traduire |
| `admin.candidatures.feuille.modeleManquant` | Choisissez le message que la personne lira. | à traduire |
| `admin.candidatures.planifier.date` | Date | à traduire |
| `admin.candidatures.planifier.heure` | Heure | à traduire |
| `admin.candidatures.planifier.duree` | Durée | à traduire |
| `admin.candidatures.planifier.menePar` | Mené par | à traduire |
| `admin.candidatures.planifier.heureLecteur` | Votre heure : {heure} ({fuseau}) | à traduire |
| `admin.candidatures.entretiens.heurePersonne` | Pour la personne : {heure} ({fuseau}) | voir `ADM-20E` |
| `admin.candidatures.planifier.fuseauInconnu` | Le fuseau de la personne n'est pas connu. Rien n'a été planifié. Demandez un complément sur son fuseau. | à traduire ; suivi du lien « Demander un complément » |
| `admin.candidatures.planifier.intervieweurRefuse` | Cette personne ne peut pas mener cet entretien. Choisissez-en une autre. | à traduire |
| `com.socle.lexique.enregistrer` | Enregistrer | existante |
| `admin.candidatures.erreurs.controles` | Rien n'a été fait. Il manque : {controles}. | à traduire |
| `admin.candidatures.erreurs.transition` | Ce geste n'est pas possible depuis l'état « {etat} ». Rien n'a été fait. | à traduire ; `{etat}` : libellé de 5.6 |
| `admin.candidatures.erreurs.conflit` | Cette candidature a changé depuis son ouverture. Relisez-la avant d'agir. | à traduire |
| `admin.candidatures.erreurs.horsPortee` | Vous n'avez pas accès à cette candidature. | à traduire |
| `admin.candidatures.erreurs.absente` | Cette candidature n'existe pas, ou plus. | à traduire |
| `admin.candidatures.erreurs.lecture` | La candidature n'a pas pu être lue. | à traduire |
| `admin.candidatures.erreurs.horsLigne` | Les gestes pourront être faits quand la connexion reviendra. | à traduire |

- **Contrat serveur** : L1 (`CAND-BR-03`, `CAND-BR-07`) : `.lire`, `.lireContact`,
  `.historique` (auteur rendu par sa qualité, jamais par son nom ; forme à préciser
  dans `PORTS`) ; gestes L2 (`CAND-BR-04`) : `.geste`, `.definirResponsable` ;
  entretien L4 (`CAND-BR-08`) : `.planifierEntretien`, `.consignerEntretien`,
  `.lireEntretien` ; `Geste` selon `CONS` 0.1 (sans `confirmer`, avec
  `garderPourSuivi` et `rattacher`). **Méthodes à ajouter à `PORTS`** : L2
  `responsablesPossibles(candidatureId)` et la liste des questions du complément ;
  L4 `intervieweursAutorises(candidatureId)` et `optionsPlanification` ; L5
  `modelesMessage(geste)`.
- **Contrôles d'acceptation** : L1-4, L1-5, L1-6, L2-1, L2-10, L2-17, L3-7, L4-4 ;
  widget : ordre des sections ; un seul bouton plein par état ; 0 contact avant
  « Voir le contact » ; 0 genre ; motif interne jamais dans le texte « ce que la
  personne lira » ; complément : la liste rendue au candidat est celle choisie, 0
  texte libre ; historique : 0 nom de personne ; 0 code d'état brut, `{etat}`
  compris ; courriel `a_envoyer` : 0 « envoyé le » ; production sans réponse de
  `CONS` 0.3 : 0 « Inviter » ni « Consigner le lien » sur une ligne gardée ;
  phrase d'exception rendue seulement sur une candidature de l'autre côté ; 5.7.

### ADM-21F : Fil « Candidature »

- **Statut** : proposée, à valider par le directeur.
- **Tâche** : répondre au candidat, demander une précision.
- **Route** : `/admin/personnes/candidatures/<référence>/fil` (précédent `CPT-12F`,
  `/comptable/paiements/beneficiaires/<id>/fil`).
- **Entrée** : « Écrire à {nom} » d'`ADM-21` ; la notification d'un nouveau message.
- **Droits (capacité)** : `candidatures.messages`, de son côté. Le super-admin lit
  les deux côtés (`peutLireHorsGenre`) ; c'est une exception de lecture (`CONS`
  8.1) : sur un fil de l'autre côté, la phrase d'exception en tête, et le champ
  d'envoi n'est rendu que si le serveur permet d'y écrire.
- **Contenu** : fil seul, sans liste de conversations ; `FilContextuel` ; en-tête de
  contexte : nom, salle, lien de retour vers `ADM-21`. Une aide sous le champ rappelle
  que le fil est lu par la personne.
- **Données jamais montrées** : 5.5. Une décision reste un geste à modèle ; un motif
  interne ne s'écrit pas dans le fil (`CONS` 7.1).
- **Bouton plein** : « Envoyer ».
- **Disposition** : fil seul. Mobile : plein écran. Tablette (768) : fil seul,
  borné. Bureau : colonne bornée.
- **États** :
  - `loading` ; `content` ;
  - `empty` : « Aucun message pour le moment » (existante) ;
  - `error` : « La conversation n'a pas pu être chargée. » et « Réessayer » ;
  - `offline` : note du composant ;
  - capacité indisponible : avant L5, « Disponible au branchement serveur » ;
  - **hors portée**, **absente** : textes d'`ADM-21` ;
  - **exception du super-admin** : la phrase en tête ; lecture seule si le serveur
    le dit ;
  - **message non confirmé** : texte de `CAND-05`.
- **Textes** :

| Clé proposée | Français | Arabe |
| :--- | :--- | :--- |
| `admin.candidatures.fil.titre` | Conversation avec {nom} | à traduire |
| `admin.candidatures.fil.aide` | Ce fil est lu par la personne. N'y écrivez ni motif interne ni compte rendu. | à traduire |
| `admin.candidatures.exception.candidature` | Cette candidature est de l'autre côté : sa lecture est inscrite au journal. | voir `ADM-21` |
| `admin.candidatures.fil.lectureSeule` | Vous lisez ce fil sans pouvoir y écrire. | à traduire |
| `com.socle.composants.composer.envoyer` | Envoyer | existante |
| `com.socle.composants.composer.aucunMessageTitre` | Aucun message pour le moment | existante |

- **Contrat serveur** : L5 (`CAND-BR-18`) : `PortMessagesMetier.filPourObjet(TypeObjetLie.candidature, id)` ;
  écriture refusée de l'autre côté, super-admin compris.
- **Contrôles d'acceptation** : L5-2 (une directrice et le fil d'un candidat : 0 accès) ;
  widget : 0 liste de conversations ; 5.7.

### ADM-21R : Compte rendu d'entretien

- **Statut** : proposée, à valider par le directeur. **Écran ajouté par ce
  catalogue** : `CONS` section 10 ne le nomme pas, mais la transition 13 exige un
  formulaire (`CAND-F07`).
- **Tâche** : consigner l'entretien juste après l'avoir mené.
- **Route** : `/admin/personnes/candidatures/<référence>/compte-rendu`, déclarée dans
  le routeur unique. Tâche focalisée, comme la sortie de la salle du contrôleur
  (`CTR-03`, `app_router.dart:2062-2072`).
- **Entrée** : la sortie de `/salle` en mode entretien, pour l'intervieweur ; la
  prochaine action d'`ADM-21` ; le lien « Écrire le compte rendu » d'`ADM-20E`.
- **Droits (capacité)** : l'intervieweur désigné (`entretiens.mener`) pour l'issue
  « tenu ». Les issues annulé et manqué relèvent de `candidatures.decider` ; elles ne
  sont rendues qu'avec cette capacité.
- **Contenu** : l'issue (« L'entretien a eu lieu », « La personne n'est pas venue »,
  « Je n'ai pas pu le mener », « Annulé ») ; pour « a eu lieu » : niveau observé,
  riwaya, ijaza présentée (oui, non), avis (favorable, défavorable), compte rendu ;
  pour les autres : motif. Durée : lue au serveur si connue, jamais saisie. À côté,
  sur bureau : les réponses utiles à l'entretien (`lireEntretien`).
- **Champs (K-57)** : déduit : la durée, la date. Choisi : issue, niveau, riwaya,
  ijaza, avis (listes rendues par le serveur, mêmes échelles que la déclaration).
  Saisi : compte rendu et motif (seule la personne qui a mené l'entretien les
  connaît).
- **Données jamais montrées** : téléphone, pièce et son état, autres candidatures
  (`CONS` 8.1). Les mots « Réussi » et « Échec » ne s'affichent pas (`MOTS` §4).
- **Bouton plein** : « Enregistrer le compte rendu ».
- **Disposition** : mobile : formulaire seul. Tablette (768) : formulaire borné ;
  les réponses utiles dessous, repliées. Bureau : formulaire borné au début
  (start), réponses utiles à la fin (end).
- **États** :
  - `loading` ; `content` ; `empty` : sans objet ;
  - `error` : « Le compte rendu n'a pas pu être enregistré. » et « Réessayer » ;
    issue non confirmée selon 5.1 ;
  - `offline` : les champs restent ; note, « Le compte rendu pourra être enregistré
    quand la connexion reviendra. » ;
  - capacité indisponible : avant L4, aucune entrée n'est rendue ; une adresse tapée
    montre `EtatSysteme` indisponible, « Disponible au branchement serveur » ;
  - **compte rendu requis** (`CompteRenduRequis`) ; **motif requis** ; **constat
    incomplet** (champ nommé) ; **pas la personne désignée** : « Seule la personne
    qui a mené cet entretien peut écrire son compte rendu. » ; **conflit**.
  - Succès après la réponse : « Compte rendu enregistré. », retour à `ADM-21`.
- **Textes** :

| Clé proposée | Français | Arabe |
| :--- | :--- | :--- |
| `admin.candidatures.compteRendu.titre` | Compte rendu de l'entretien de {nom} | à traduire |
| `admin.candidatures.compteRendu.issue` | Comment s'est passé l'entretien ? | à traduire |
| `admin.candidatures.compteRendu.tenu` | L'entretien a eu lieu | à traduire |
| `admin.candidatures.compteRendu.manquePersonne` | La personne n'est pas venue | à traduire |
| `admin.candidatures.compteRendu.manqueIntervieweur` | Je n'ai pas pu le mener | à traduire |
| `etat.annule` | Annulé | existante |
| `admin.candidatures.compteRendu.niveau` | Niveau observé | à traduire |
| `admin.candidatures.compteRendu.riwaya` | Riwaya | à traduire |
| `admin.candidatures.compteRendu.ijaza` | Ijaza présentée | à traduire |
| `admin.candidatures.compteRendu.avis` | Votre avis | à traduire |
| `admin.candidatures.compteRendu.favorable` | Favorable | à traduire |
| `admin.candidatures.compteRendu.defavorable` | Défavorable | à traduire |
| `admin.candidatures.compteRendu.texte` | Compte rendu | à traduire |
| `admin.candidatures.compteRendu.enregistrer` | Enregistrer le compte rendu | à traduire |
| `admin.candidatures.compteRendu.requis` | Écrivez le compte rendu de l'entretien. | à traduire |
| `admin.candidatures.compteRendu.pasDesigne` | Seule la personne qui a mené cet entretien peut écrire son compte rendu. | à traduire |
| `admin.candidatures.compteRendu.echec` | Le compte rendu n'a pas pu être enregistré. | à traduire |
| `admin.candidatures.compteRendu.horsLigne` | Le compte rendu pourra être enregistré quand la connexion reviendra. | à traduire |
| `admin.candidatures.compteRendu.succes` | Compte rendu enregistré. | à traduire |

- **Contrat serveur** : L4 (`CAND-BR-08`) : `.consignerEntretien` (issue, compte
  rendu, constat, motif), `.lireEntretien` ; transitions 12 et 13.
- **Contrôles d'acceptation** : L4-5 ; widget : issues annulé et manqué absentes sans
  `peutDecider` ; 0 téléphone, 0 pièce ; 5.7.

### ADM-22 : Action groupée

- **Statut** : proposée, à valider par le directeur.
- **Tâche** : faire un même geste sur plusieurs candidatures, en voyant l'effet exact
  avant.
- **Route** : `/admin/personnes/candidatures/action-groupee`. La sélection passe par
  `extra` ; une page rechargée revient à `ADM-20` avec une phrase. Une page, jamais
  une modale (5.3).
- **Entrée** : « Agir sur la sélection » d'`ADM-20`.
- **Droits (capacité)** : `candidatures.decider`. Gestes groupables seulement
  (`CONS` 4.2) : inviter, mettre en pause, lever la pause, refuser, consigner le lien
  envoyé par WhatsApp. Tout autre geste rend `GesteNonGroupable`.
- **Contenu** :
  1. le geste, en cartes de choix (K-58 : quand le choisir, sa conséquence) ;
     « Inviter » n'est pas rendu tant que les invitations sont fermées en production ;
     « Inviter » et « Consigner le lien » dépendent aussi de `CONS` 0.3 (ligne
     `recue`) ;
  2. l'aperçu (`preparerLot`) : chaque candidature ciblée (nom, salle, aucun contact),
     l'effet exact rendu par le serveur, les exclues avec leur raison (« Exclue :
     {raison} »), le nombre ;
  3. pour refuser et mettre en pause : motif interne commun et modèle choisi parmi
     `modelesMessage(geste)` (5.8), son texte mot pour mot ;
  4. la saisie du nombre d'éligibles ;
  5. le rapport ligne par ligne : « Fait », « Exclue : {raison} », « Non fait :
     {raison} », « Issue non confirmée » ; une réussite n'est jamais annulée par un
     refus voisin.
- **Données jamais montrées** : 5.5 ; aucun contact dans l'aperçu ni le rapport.
- **Bouton plein** : « Confirmer pour {n} candidatures », seulement quand le nombre
  saisi est entré. Au rapport, aucun ; lien « Revenir aux candidatures ».
- **Disposition** : mobile : sections empilées. Tablette (768) : sections empilées,
  liste ciblée repliable. Bureau : liste ciblée au début (start) ; geste, effet et
  confirmation à la fin (end).
- **États** :
  - `loading` : aperçu en cours ; `content` ;
  - `empty` : **aucune éligible** : « Aucune candidature retenue ne peut recevoir ce
    geste. » et les raisons ;
  - `error` : « L'aperçu n'a pas pu être préparé. » et « Réessayer » ;
  - `offline` : l'aperçu reste ; la confirmation n'est pas rendue ; une note le dit ;
  - capacité indisponible : sans `CAND-BR-06`, « Disponible au branchement serveur » ;
    sans `modelesMessage`, refuser et mettre en pause le disent seuls ;
  - **jeton périmé** (`JetonPerime`) ; **nombre discordant** (`NombreDiscordant`) ;
    **lot partiellement refusé** ; **issue inconnue** (jamais « réussie » par défaut).
- **Textes** :

| Clé proposée | Français | Arabe |
| :--- | :--- | :--- |
| `admin.candidatures.lot.titre(param=n)` | `one` : Agir sur {n} candidature ; `other` : Agir sur {n} candidatures | à traduire, six formes |
| `admin.candidatures.lot.choixGeste` | Que voulez-vous faire ? | à traduire |
| `admin.candidatures.lot.effet` | Ce qui va se passer | à traduire |
| `admin.candidatures.lot.exclues` | Exclues, avec leur raison | à traduire |
| `admin.candidatures.lot.saisirNombre` | Pour confirmer, saisissez le nombre de candidatures concernées : {n}. | à traduire ; aucun nom ne s'accorde avec `{n}` |
| `admin.candidatures.lot.confirmer(param=n)` | `one` : Confirmer pour {n} candidature ; `other` : Confirmer pour {n} candidatures | à traduire, six formes |
| `admin.candidatures.lot.aucuneEligible` | Aucune candidature retenue ne peut recevoir ce geste. | à traduire |
| `admin.candidatures.lot.jetonPerime` | La sélection a changé depuis l'aperçu. Rien n'a été fait. Relisez l'aperçu. | à traduire |
| `admin.candidatures.lot.nombreDiscordant(param=n)` | `one` : Le nombre saisi ne correspond pas : {n} candidature est concernée. Rien n'a été fait. ; `other` : Le nombre saisi ne correspond pas : {n} candidatures sont concernées. Rien n'a été fait. | à traduire, six formes |
| `admin.candidatures.lot.reussie` | Fait | à traduire |
| `admin.candidatures.lot.exclue` | Exclue : {raison} | à traduire |
| `admin.candidatures.lot.nonFait` | Non fait : {raison} | à traduire |
| `admin.candidatures.lot.inconnue` | Issue non confirmée | à traduire |
| `admin.candidatures.lot.apercuEchec` | L'aperçu n'a pas pu être préparé. | à traduire |
| `admin.candidatures.lot.selectionPerdue` | La sélection n'a pas été gardée. Sélectionnez de nouveau les candidatures. | à traduire |
| `admin.candidatures.lot.horsLigne` | La confirmation pourra être faite quand la connexion reviendra. | à traduire |
| `admin.candidatures.lot.retour` | Revenir aux candidatures | à traduire |

- **Contrat serveur** : L2 (`CAND-BR-06`) : `.preparerLot`, `.executerLot` ;
  modèles L5 (`modelesMessage`). **Inviter** : geste L3 (part de `CAND-BR-04`) et
  file des courriels L5 (`CAND-BR-16`, devenu la file des courriels, `CONS` 0.1) ;
  fermé en production tant que l'envoi de la file manque (`CONS` 3.3).
- **Contrôles d'acceptation** : L2-7, L3-8 ; widget : 0 contact ; bouton plein absent
  tant que le nombre n'est pas saisi ; rapport rendu ligne par ligne, 0 « Refusé par
  le serveur » ; 5.7.

### ADM-23 : Import des formulaires

- **Statut** : proposée, à valider par le directeur.
- **Tâche** : importer une fois les réponses des formulaires Google, pour reconnaître
  et pré-remplir, sans créer de compte ni de candidature.
- **Route** : `/admin/personnes/candidatures/import`, distincte de
  `/admin/personnes/import` (`routes.dart:725`).
- **Entrée** : le lien « Importer les formulaires » d'`ADM-20`, rendu seulement avec
  `peutImporter`.
- **Droits (capacité)** : `candidatures.importer`, **super-admin seul**, aal2 exigée
  en base (`CONS` 3.2).
- **Contenu, les huit pas** (`CONS` 3.2) : (1) dépôt d'un export CSV ; (2) aperçu,
  contacts masqués ; (3) association des colonnes, avec la table des libellés ;
  (4) doublons probables et lignes incomplètes, un choix par groupe ; un groupe dit
  la **nature** de sa clé (« Même courriel », « Même téléphone »), jamais sa valeur ;
  (5) erreurs et avertissements ligne par ligne ; (6) quatre compteurs (nouvelles,
  déjà connues, ignorées, à corriger) et l'écart avec les comptes attendus ;
  (7) confirmation ; (8) rapport final ligne par ligne, sans nom. Le rapport sans nom
  ne permet pas de garder une ligne pour suivi : `CAND-F13`.
- **Données jamais montrées** : courriel et téléphone aux pas 2 à 8, ni en clair ni
  comme valeur d'une clé de doublon ; nom dans le rapport final ; liens Drive vers
  des photos d'identité (jamais importés). L'aperçu suit 5.5 (ni genre, ni réponse
  libre), sauf les réponses non libres nécessaires au mappage (pas 3).
- **Bouton plein** : un par pas : « Analyser le fichier » (1) ; « Continuer » (2 à 6) ;
  « Importer les réponses » (7) ; aucun au rapport (8), lien « Revenir aux
  candidatures ».
- **Disposition** : pages, jamais modales. Mobile : les pas l'un après l'autre.
  Tablette (768) : les pas en haut, le contenu du pas dessous. Bureau : rail des
  huit pas au début (start), contenu du pas à la fin (end).
- **États** :
  - `loading` : analyse, essai à blanc, import ; `content` ;
  - `empty` : « Ce fichier ne contient aucune ligne à importer. » ;
  - `error` : « L'analyse n'a pas abouti. » et « Réessayer » ;
  - `offline` : l'aperçu reste ; la confirmation n'est pas rendue ;
  - capacité indisponible : sans `CAND-BR-09`, « Disponible au branchement serveur » ;
  - **fichier illisible** (ligne et cause) ; **mappage incomplet** (champs nommés) ;
    **doublons à choisir** (un groupe sans choix reste « à corriger ») ; **écart des
    compteurs** ; **double vérification requise** ; **jeton périmé**.
- **Textes** :

| Clé proposée | Français | Arabe |
| :--- | :--- | :--- |
| `admin.candidatures.import.titre` | Importer les formulaires de candidature | à traduire |
| `admin.candidatures.import.intro` | L'import sert à reconnaître les personnes et à pré-remplir leur candidature. Il ne crée aucun compte. | à traduire |
| `admin.candidatures.import.pas.depot` | Déposer le fichier | à traduire |
| `admin.candidatures.import.pas.apercu` | Aperçu | à traduire |
| `admin.candidatures.import.pas.colonnes` | Colonnes | à traduire |
| `admin.candidatures.import.pas.doublons` | Doublons | à traduire |
| `admin.candidatures.import.pas.erreurs` | Erreurs | à traduire |
| `admin.candidatures.import.pas.comptes` | Comptes | à traduire |
| `admin.candidatures.import.pas.confirmation` | Confirmation | à traduire |
| `admin.candidatures.import.pas.rapport` | Rapport | à traduire |
| `admin.candidatures.import.analyser` | Analyser le fichier | à traduire |
| `commun.continuer` | Continuer | existante |
| `admin.candidatures.import.importer` | Importer les réponses | à traduire |
| `admin.candidatures.import.nouvelles` | Nouvelles | à traduire |
| `admin.candidatures.import.dejaConnues` | Déjà connues | à traduire |
| `admin.candidatures.import.ignorees` | Ignorées | à traduire |
| `admin.candidatures.etats.aCorriger` | À corriger | voir 5.6 |
| `admin.candidatures.import.ecart` | Écart avec les comptes attendus : attendu {attendu}, lu {lu}. Vérifiez avant de confirmer. | à traduire |
| `admin.candidatures.import.contactsMasques` | Les contacts sont masqués dans l'aperçu. | à traduire |
| `admin.candidatures.import.cleCourriel` | Même courriel | à traduire |
| `admin.candidatures.import.cleTelephone` | Même téléphone | à traduire |
| `admin.candidatures.import.choisirLigne` | Choisissez la ligne à garder, ou indiquez qu'il s'agit de personnes distinctes. | à traduire |
| `admin.candidatures.import.personnesDistinctes` | Personnes distinctes | à traduire |
| `admin.candidatures.import.illisible` | Ce fichier n'a pas pu être lu, ligne {ligne} : {cause}. | à traduire |
| `admin.candidatures.import.mappageIncomplet` | Associez d'abord ces colonnes : {champs}. | à traduire |
| `admin.importInscriptions.acces.doubleTitre` | Double vérification requise | existante |
| `admin.candidatures.import.doublePhrase` | Connectez-vous avec votre second facteur, puis revenez ici pour importer les formulaires. | à traduire |
| `admin.candidatures.import.vide` | Ce fichier ne contient aucune ligne à importer. | à traduire |
| `admin.candidatures.import.analyseEchec` | L'analyse n'a pas abouti. | à traduire |
| `admin.candidatures.import.horsLigne` | L'import pourra être confirmé quand la connexion reviendra. | à traduire |

- **Contrat serveur** : L3 (`CAND-BR-09`) : `PortImportCandidatures.analyser`,
  `.essaiABlanc` (doublons : lignes et nature de la clé), `.confirmer`. L'import
  écrit des réponses importées, pas des candidatures (`CONS` 0.1 et 3.2).
- **Contrôles d'acceptation** : L3-4, L3-5, L3-6, L3-10, L3-11, L3-15, L3-16 ;
  widget : 0 courriel et 0 téléphone rendus aux pas 2 à 8, clés de doublon
  comprises ; 0 nom au rapport ; lien absent sans `peutImporter` ; 5.7.

### ADM-24 : Compatibilité de paiement par pays

- **Statut** : proposée, à valider par le directeur.
- **Tâche** : dire, pays par pays, quel moyen permet à Rewayah de verser une
  rémunération. Un référentiel déclaratif : rien n'est versé, aucun prestataire
  n'est appelé (`DEC:28`).
- **Route** : `/admin/finance/paiement-pays` (neuve), sixième onglet de Finance
  (`admin_domaine.dart:203-215` ; sept au plus en ligne, ONGLETS-1). Finance sauf
  avis contraire (`DEC:85`). L'onglet se dit « Versement par pays » : à côté de
  « Paiements » (paiements reçus des familles, `ADM-PAI`), « Paiement par pays » se
  lirait comme des paiements reçus. Le nom de l'écran dans `CONS` reste celui du
  registre.
- **Entrée** : l'onglet ; l'alerte d'un changement qui pose des restrictions.
- **Droits (capacité)** : `paiement.referentiel.ecrire` (direction et
  comptabilité). L'entrée de la comptabilité : point `CAND-F06`.
- **Contenu** : recherche par pays (nom en français ou en arabe) ; une ligne par
  moyen : pays, moyen (virement bancaire, mobile money), opérateur, prestataire,
  devise, type de versement, état (confirmé, en vérification, indisponible : mot et
  icône), vérifié le, par, notes. Lien « Ajouter une ligne ». Toucher une ligne ouvre
  sa fiche. Les pays d'Afrique restent « en vérification » tant que `CAND-Q05` est
  ouvert ; une phrase le dit en tête.
- **Fiche d'une ligne** (`AppBottomSheet`) : pays, moyen, opérateur, prestataire,
  devise, type, état choisis ; date de vérification choisie ; « vérifié par » déduit
  du compte ; notes saisies (seul champ libre). Opérateurs et devises viennent de
  listes rendues par le serveur, à ajouter à `PORTS` (L6) ; tant qu'elles manquent,
  la fiche dit « Disponible au branchement serveur ». Bouton : « Enregistrer ».
  Retirer la confirmation d'une ligne passe d'abord par `ConfirmDestructive`, qui
  dit l'effet.
- **Données jamais montrées** : réponses et identité des candidats (`CONS` 8.1).
  L'impact est un nombre, jamais une liste de personnes.
- **Bouton plein** : aucun sur la page ; « Enregistrer » dans la fiche.
- **Disposition** : mobile : une carte par pays, ses moyens en lignes fines.
  Tablette (768) : tableau dense ; fiche en boîte de dialogue. Bureau : tableau
  dense ; fiche en boîte de dialogue.
- **États** :
  - `loading` ; `content` ;
  - `empty` : « Aucune ligne pour le moment » ;
  - `error` : « Le référentiel n'a pas pu être lu. » et « Réessayer » ;
  - `offline` : la lecture reste ; la fiche n'offre aucun envoi ;
  - capacité indisponible : sans `CAND-BR-13`, « Disponible au branchement serveur » ;
    sans les listes d'opérateurs et de devises, la fiche seule le dit ;
  - **confirmation sans date ni responsable refusée** (`ConfirmationSansVerification`) ;
  - **impact** : après la réponse, le nombre de restrictions posées, rendu par le
    serveur (`impact`) ;
  - **conflit** (`ConflitReferentiel`) ; **accès refusé**.
- **Textes** :

| Clé proposée | Français | Arabe |
| :--- | :--- | :--- |
| `admin.finance.versementPays` | Versement par pays | à traduire |
| `admin.referentielPaiement.titre` | Moyens de versement par pays | à traduire |
| `admin.referentielPaiement.intro` | Ce tableau dit par quel moyen Rewayah peut verser une rémunération dans chaque pays. Il ne verse rien. | à traduire |
| `admin.referentielPaiement.afrique` | Les pays d'Afrique restent en vérification jusqu'à la décision du directeur. | à traduire |
| `avis.form.pays.rechercheLibelle` | Rechercher un pays | existante |
| `admin.referentielPaiement.ajouter` | Ajouter une ligne | à traduire |
| `admin.referentielPaiement.virement` | Virement bancaire | à traduire |
| `admin.referentielPaiement.mobileMoney` | Mobile money | à traduire |
| `admin.candidatures.etats.versement.compatible` | Confirmé | voir 5.6 |
| `admin.referentielPaiement.etat.enVerification` | En vérification | à traduire |
| `admin.candidatures.etats.indisponible` | Indisponible | voir 5.6 |
| `admin.referentielPaiement.verifieLe` | Vérifié le {date} par {nom} | à traduire |
| `com.socle.lexique.enregistrer` | Enregistrer | existante |
| `admin.referentielPaiement.sansVerification` | Pour confirmer cette ligne, indiquez la date de vérification. | à traduire |
| `admin.referentielPaiement.retirerQuestion` | Retirer la confirmation de cette ligne ? | à traduire |
| `admin.referentielPaiement.retirerConsequence` | Les personnes en Salle des prêts à enseigner qui n'ont que ce moyen passeront en restriction. Les candidatures de ce pays en vérification seront bloquées, celles en examen attendront un moyen possible. | à traduire |
| `admin.referentielPaiement.impact(param=n)` | `zero` : Enregistré. Aucune restriction posée. ; `one` : Enregistré. {n} restriction posée : versement à revérifier. ; `other` : Enregistré. {n} restrictions posées : versement à revérifier. | à traduire, six formes |
| `admin.referentielPaiement.vide` | Aucune ligne pour le moment | à traduire |
| `admin.referentielPaiement.lectureEchec` | Le référentiel n'a pas pu être lu. | à traduire |
| `admin.referentielPaiement.conflit` | Cette ligne a changé depuis son ouverture. Relisez-la avant d'enregistrer. | à traduire |

- **Contrat serveur** : L6 (`CAND-BR-13`) : `PortReferentielPaiement.lister`,
  `.enregistrer` (rend l'`impact`) ; options d'opérateurs et de devises, méthode à
  ajouter à `PORTS` (L6) ; transitions 8 et 9 ; effets de `CONS` 5.1 (restriction en
  Salle des prêts à enseigner, candidature « bloquée » en vérification, transition 8
  en examen) ; alerte à la direction et à la comptabilité ; part de `CPT-BR-10`, sans
  remplacer `PortCapacitePayout` (`lib/core/capacites/port_capacite_payout.dart`).
- **Contrôles d'acceptation** : L6-5, L6-6, L6-9, L6-10 ; widget : impact rendu
  seulement après la réponse, au pluriel juste (0, 1, plusieurs) ; 0 nom de
  personne ; le prestataire est une donnée, jamais un libellé en dur ; 5.7.

### ADM-02 étendu : Dossiers à valider

- **Statut** : proposée, à valider par le directeur.
- **Tâche** : valider la pièce d'un candidat, ce qui le fait entrer en Salle des prêts
  à enseigner ; ou dire qu'elle est à corriger ; ou la refuser définitivement.
- **Route** : `/admin/personnes/dossiers`, inchangée (`routes.dart:736`) ; file et
  détail existants (`dossiers_page.dart:32-34`).
- **Entrée** : l'onglet ; « Revoir la pièce d'identité » et « Ouvrir dans Dossiers à
  valider » d'`ADM-21`.
- **Droits (capacité)** : décision : `candidatures.decider`, pour un dossier que le
  serveur rend porteur d'une candidature `enseignant`. **Le dossier porte
  `candidatureId` et les sept contrôles**, rendus par le port de revue (méthode à
  nommer dans `PORTS`, L2) ; l'écran ne lit pas le rôle. Les autres profils, tuteur
  compris, gardent l'approbation actuelle (`CONS` transition 14). L'exception du
  super-admin reste celle d'aujourd'hui (`dossiers.accesKyc.*`).
- **Contenu ajouté à la revue d'aujourd'hui** : une phrase de tête dit l'effet :
  « Valider la pièce fait entrer {nom} en Salle des prêts à enseigner. » ; les sept
  autres contrôles, vrai ou faux (libellés de 5.6) ; le lien « Voir la candidature »
  (`ADM-21`).
- **Bouton plein** : « Valider la pièce », rendu seulement quand le serveur dit les
  sept autres contrôles vrais. Sinon, aucun bouton de validation : la phrase nomme ce
  qui manque. « Pièce à corriger » en action secondaire ; « Refuser définitivement »
  au niveau destructif, avec `ConfirmDestructive`.
- **Données jamais montrées** : rien de plus qu'aujourd'hui ; la pièce reste dans sa
  visionneuse.
- **Disposition** : inchangée pour les autres profils. Pour un dossier porteur d'une
  candidature : mobile : page ; tablette (768) : détail seul ; bureau : file 336,
  écart 24, détail 728 (`dossiers_page.dart:32-34`). Dans le détail : la phrase de
  tête, puis les sept contrôles en `CarteLignes`, au-dessus des boutons.
- **États** : ceux d'aujourd'hui, plus **contrôles manquants nommés** et **validation
  refusée par le serveur** (`ControlesNonSatisfaits`). Capacité indisponible : sans
  `CAND-BR-05`, la revue reste celle d'aujourd'hui ; ni phrase de tête, ni contrôles.
  En production, la décision reste fermée (`AD-M3-PROD`, `revue_dossier.dart:33-36`)
  jusqu'au feu vert du directeur, après L2 et les lots `langue` et `c11bis`
  (`CONS` §11).
- **Textes** :

| Clé proposée | Français | Arabe |
| :--- | :--- | :--- |
| `dossiers.candidature.effet` | Valider la pièce fait entrer {nom} en Salle des prêts à enseigner. | à traduire |
| `admin.candidatures.detail.controles` | Contrôles | voir `ADM-21` |
| `dossiers.candidature.valider` | Valider la pièce | à traduire |
| `dossiers.candidature.manque` | La pièce ne peut pas encore être validée. Il manque : {controles}. | à traduire |
| `dossiers.candidature.aCorriger` | Pièce à corriger | à traduire |
| `dossiers.candidature.refuserDefinitivement` | Refuser définitivement | à traduire |
| `dossiers.candidature.refusQuestion` | Refuser définitivement la pièce de {nom} ? | à traduire |
| `dossiers.candidature.refusConsequence` | La candidature sera refusée. La personne lira le message choisi, jamais le motif. | à traduire |
| `dossiers.candidature.voir` | Voir la candidature | à traduire |
| `dossiers.approuver` | Valider le dossier | existante, inchangée pour les autres profils |

- **Contrat serveur** : L2 (`CAND-BR-05`) : `decider_dossier()` modifié pour un profil
  porteur d'une candidature ; garde `0089` étendue vers `active` et
  `provisional_active` ; deux issues de refus (`DEC:41`). **Contrôles** : rendus avec
  le dossier par le port de revue (méthode à nommer dans `PORTS`) ; à défaut,
  `PortCandidaturesDirection.lire(candidatureId)` rend `controles`. Modèles de refus
  et de correction : L5 (5.8).
- **Contrôles d'acceptation** : L2-1, L2-2, L2-5, L2-13 ; widget : « Valider la
  pièce » absent quand un contrôle est faux ; profil de tuteur inchangé ; sans
  `CAND-BR-05`, 0 phrase de tête et 0 contrôle ; l'écran ne lit pas le rôle ; 5.7.

---

## 8. Points de fiche à trancher

Propres à ce catalogue. Ils s'ajoutent aux questions ouvertes de `CONS` 0.3 et aux
questions de suivi `CAND-S01` à `CAND-S11`, sans les remplacer.

| Point | Constat | Proposition | Qui tranche |
| :--- | :--- | :--- | :--- |
| `CAND-F01` | La page Invitations invite aussi le comptable (`invitations_page.dart:191-200`) et révoque une invitation d'enseignant en cours (`_revoquer`, `:156-181`, avec `ConfirmDestructive`). L'onglet devient Candidatures ; aucun `Geste` ni aucune fiche ne reprend la révocation. | Garder `/admin/personnes/invitations` sans onglet, pour le comptable et, tant que ce n'est pas tranché, pour la révocation ; lien « Inviter un comptable » sur `ADM-20`, rendu seulement si son port est servi. À trancher : la révocation d'une invitation d'enseignant disparaît-elle (l'expiration à 14 jours suffit, transition 4), ou devient-elle un geste `revoquerInvitation` d'`ADM-21`, à ajouter à `Geste` dans `PORTS` ? | directeur |
| `CAND-F02` | Aujourd'hui l'identifiant d'un dossier passe par `extra`, jamais par l'adresse (`app_router.dart:1569-1571`). | La référence `CAND-…` dans l'adresse d'`ADM-21` : elle ne nomme personne et survit au rechargement (`GOV` §4 bis.4). Sinon, `extra` comme `ADM-02`. | directeur |
| `CAND-F03` | La réponse neutre au plafond horaire doit être « la même que le succès » (`CONS` 3.1). Le lien de connexion est neutre par construction ; la création du profil ne l'est pas, son succès mène à `/attente`. | Jouer le plafond avant l'entrée sans code (lu par `ouverte`) ; L3 tranche où il se joue. Texte : fiche `CAND-04` (`connexion.lienEnvoye`, ou `inscription.candidat.reponseNeutre` si le plafond précède le lien). | L3, puis directeur |
| `CAND-F04` | La page d'accords a déjà une case « article 9 » du contrat enseignant (`accords_page.dart:65-66`, `:229`). | L2 dit si l'article 9 reste dans le contrat, pour ne pas montrer deux engagements religieux. | L2, puis directeur |
| `CAND-F05` | `CONS` 7.2 ouvre les notifications au compte en attente ; `CONS` §10 ne nomme aucun écran pour les lire. | Aucun écran neuf : le portail porte l'événement et se relit au retour. Textes des modèles et des notifications : 5.8. | directeur |
| `CAND-F06` | La comptabilité écrit le référentiel ; l'espace `/comptable` n'atteint pas `/admin/finance`. | Même écran, une entrée de plus sous `/comptable`, sans branche par rôle. | directeur |
| `CAND-F07` | `ADM-21R` n'est pas dans `CONS` §10. | Page, comme `CTR-03` ; ou feuille d'`ADM-21`. | directeur |
| `CAND-F08` | `CONS` §10 range la vue Entretiens dans `ADM-20`. | Code `ADM-20E` pour sa fiche ; même route, `?vue=entretiens`. | directeur |
| `CAND-F09` | La garde du dépôt de pièce est écrite sur le rôle `teacher` (`redirection.dart:156-162`). | La garde lit un champ rendu par `etat_dossier()` : l'existant `pieceRequise` (`etat_dossier.dart:119`) ou l'étape de la candidature, jamais `session.role`. Le dépôt s'ouvre en Salle de vérification et d'entretien seulement (fiche `TUT-00c/c`). | L1, L2 |
| `CAND-F10` | La garde du billet de salle ne joue que pour un compte actif (`redirection.dart:252-255`) ; un compte en attente est ramené à `/attente` (`:172-174`). | L4 ouvre `/salle` à un billet d'entretien depuis la porte `attente` ; un seul routeur, aucune branche par plateforme. | L4 |
| `CAND-F11` | « L'entretien n'est pas accessible pour le moment. » (`CONS` 6.2) ressemble aux formes que la garde hors ligne refuse (`UX`, États). | Permise clé par clé : c'est un fait connu du serveur (jeton refusé), pas une cause supposée. | directeur |
| `CAND-F12` | `PaysIso` n'a pas d'indicatif (`pays_iso.dart:12-26`). | Ajouter une table des indicatifs à côté, données et non libellés ; normalisation au serveur selon `MAP` §4. | L3 |
| `CAND-F13` | **Où la direction voit-elle les réponses importées ?** `lister` ne rend que des candidatures, et le rapport d'`ADM-23` est sans nom ; après l'import, 0 ligne de candidature (L3-5). « Garder pour suivi » (transition 2) part d'une réponse importée : la direction ne peut ni garder une ligne, ni ensuite consigner l'envoi du lien par WhatsApp (transition 26, sur la ligne `recue`), que le directeur a décidé pour les 32 personnes sans courriel (`DEC:26`, `:29`, `:56`). | Une vue `?vue=formulaires` d'`ADM-20` (`candidatures.lire`, portée de genre en base) : nom, date de réponse, marques « Courriel à obtenir » et « Indicatif à confirmer » ; aucun contact, aucune réponse libre (5.5). Lecture par une méthode à nommer dans `PORTS` (par exemple `listerReponsesImportees`, L3). « Garder pour suivi » (`admin.candidatures.gestes.garder`, à traduire) vit sur ses lignes ; « Consigner le lien envoyé par WhatsApp » sur la ligne `recue` qui en naît, ici comme dans `ADM-20`. Les deux sous réserve de `CONS` 0.3 (ligne `recue` de suivi). Fiche complète avant tout code. | directeur, puis L3 |
| `CAND-F14` | **Le fil `candidature` reste-t-il ouvert après un retrait ou un refus ?** `CONS` 7.1 admet le compte en attente pour cet objet sans le dire. | Tant que L5 ne l'a pas fixé, aucun texte ne renvoie au fil après un retrait ou un refus, et le lien « Écrire à l'académie » n'est rendu que si le serveur ouvre le fil. | L5, puis directeur |
| `CAND-F15` | **Brouillon du questionnaire.** `PORTS` n'avait qu'`envoyerReponses`, sans brouillon : des réponses partielles n'étaient gardées nulle part. | Brouillon local à l'appareil (cache borné et effaçable, `C/02_ARCHITECTURE_ET_SECURITE.md`, règle 7) ou au serveur (méthode à ajouter à `PORTS`) ? **Réponse proposée par L2A1 le 22/10, en attente du directeur** : brouillon au serveur (`enregistrerBrouillon`, sa propre version, sans effet sur la version de la candidature), et toutes les questions rouvertes après un complément, quand cette fiche n'en rouvrirait que les nommées (`CONS` 0.2 bis). D'ici sa réponse, quitter `CAND-01` sans envoyer l'annonce avant (`ConfirmDestructive`). | L2 (fait, proposé), puis directeur |
| `CAND-F16` | `CAND-01` propose le pays de versement égal au pays de résidence (K-57, déduit). `CONS` 3.4 interdit de pré-remplir le pays depuis l'import ; ici la valeur viendrait de la réponse que la personne vient de donner. | Proposer, jamais imposer : la valeur reste modifiable, et rien n'est envoyé sans un pays de versement choisi. | directeur |
