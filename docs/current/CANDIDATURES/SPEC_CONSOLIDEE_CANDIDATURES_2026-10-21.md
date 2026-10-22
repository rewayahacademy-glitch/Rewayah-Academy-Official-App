# Spécification verticale consolidée du module des candidatures (enseignant d'abord)

## 0. Statut, sources, ce que ce document remplace

**Statut :** `spécifié` seulement. Aucune ligne de code, aucune migration, aucun
port n'est écrit par ce document. Rédigé le 21/10/2026, après les 22 réponses du
directeur, puis révisé le même jour après une relecture critique : les corrections
retenues sont intégrées, et ce qui reste à soumettre est en 0.2 bis et 0.3. C'est
le pas 4 de l'ordre de la spécification : arbitrage, puis cette spécification
consolidée, puis maquettes et leur contrôle, handoff, implémentation, recette
(`SPEC §14`).

**À qui il sert.** C'est le seul document à partir duquel le développeur et le
designer construisent. Quand il contredit le contrat proposé (`PORTS`, `BR`), il
s'applique, et le lot qui écrit les ports met le contrat à jour.

| Sigle | Fichier |
| :--- | :--- |
| `SPEC` | `docs/current/CANDIDATURES/REWAYAH_CANDIDATURES_SPEC_V1_2026-10-21.md` (spec du directeur, v1.0) |
| `REVUE` | `docs/current/CANDIDATURES/REVUE_CRITIQUE_CANDIDATURES_2026-10-21.md` |
| `DEC` | `docs/current/DECISION-CANDIDATURES-2026-10-21.md` (les 22 réponses) |
| `PORTS` | `docs/current/CANDIDATURES/CONTRAT_PORTS_CANDIDATURES.md` |
| `BR` | `docs/current/CANDIDATURES/DEPENDANCES_BACKEND.md` (`CAND-BR-01` à `CAND-BR-18`) |
| `MAP` | `docs/current/CANDIDATURES/MAPPAGE_IMPORT_FORMULAIRES.md` |
| `CORR` | `docs/current/CANDIDATURES/CORRECTIFS_HORS_MODULE_PROPOSES.md` |
| `M/`, `C/` | `supabase/migrations/`, `docs/current/` |

`DEC:24` renvoie à la ligne 24 du fichier ; `REVUE §8` à sa section.

### 0.1 Ce que ce document remplace

| Document | Ce qu'il devient |
| :--- | :--- |
| `SPEC` | reste la référence du directeur, intacte ; là où elle diffère d'une décision datée du 21/10, ce document applique la décision (0.2) |
| `REVUE` | reste la cartographie de l'existant et des preuves ; ses recommandations d'origine (`§9`) cèdent là où `DEC` répond autrement : plus de WhatsApp sauf l'envoi du lien d'inscription (`DEC:29`), plus de voie 1 pour l'entretien (`§6.3`), plus de « prévenu le » comme canal ordinaire |
| `PORTS`, `BR` | contrat proposé, à mettre à jour par le lot qui écrit les ports, selon la liste ci-dessous |
| `MAP` | §1 : l'import écrit des réponses importées, pas des lignes `recue` (3.2) ; les règles de §4 normalisent aussi le téléphone donné à l'inscription (2.1) |

**Changements à porter dans `PORTS` et `BR` :**
- `geste(confirmer)` disparaît : l'entrée en salle 3 est la validation de la pièce
  dans `ADM-02`, donc plus de confirmation en lot.
- `Geste` gagne `garderPourSuivi` (transition 2) et `rattacher` (rattachement par
  téléphone, transition 27) ; `demanderComplement` vaut aussi en salle 2
  (transition 23).
- `consignerPrevenu` ne constate plus qu'un lien envoyé par WhatsApp (7.4).
- `consignerRetrait` : demande reçue par la conversation ou par courriel, et non
  plus « hors de l'application » (transition 17).
- `inviter` : le code part dans le courriel `invitation` (3.3) ; il ne s'affiche à
  la direction que si le directeur nomme un canal pour l'intervalle (0.3).
- `LigneCandidature`, `Candidature`, `FiltreCandidatures` : état
  `paiement_non_disponible` ; dimensions provenance, cause de restriction et
  affectation (4.1) ; filtre « sans activité depuis N jours » (section 10).
- `EtatEntretien` : `sessionDisponible` et `enCours` fusionnés ;
  `lienIndisponible` devient « inaccessible » (6.2). `EntretienCandidat.mode`
  perd `whatsapp`.
- `CapacitesCandidatures` : `peutImporter` au super-admin seul (3.2) ;
  `peutMenerEntretien` du même côté que le candidat (6.1) ; capacité neuve
  `candidatures.messages` (8.1).
- Un port pour `CAND-04` (inscription sans code) ; la lecture de l'état d'un
  courriel (`a_envoyer`, `envoye`, `echec`, 7.3).
- `CAND-BR-11` : insertion ouverte au compte candidat de la forme fixée en L1,
  invité ou non (3.1).
- `CAND-BR-13` est déclaratif.
- `CAND-BR-15` : six fichiers de scénarios (`scenarios_cand_l1.sql` à
  `scenarios_cand_l6.sql`), et non un seul.
- `CAND-BR-16` devient la file des courriels (7.3).
- `CAND-BR-17` : genre et téléphone avec indicatif obligatoires à l'inscription ;
  clé de mise en ligne (3.1).
- L'import écrit des réponses importées, pas des candidatures (3.2) ; les
  Garanties de `PORTS §2` changent en conséquence.
- Depuis L2A2 (22/10, 4.2) : `geste` rend l'état relu de la candidature
  (dimensions et version), le dossier complet se relit par `lire` ;
  `demanderComplement` nomme ses éléments dans une liste fermée par salle ;
  `consignerRetrait` prend le canal (`conversation` ou `courriel`) et la date de
  la demande ; `executerLot` reprend le geste et les identifiants de l'aperçu
  avec le jeton, empreinte de l'aperçu ; `CapacitesCandidatures` gagne une
  capacité par geste et les listes fermées.

### 0.2 Où ce document s'écarte de la spec v1

| Spec v1 | Ce document | Source |
| :--- | :--- | :--- |
| Salle 3 : décision finale distincte ; la pièce est un prérequis parmi d'autres (`SPEC §3`) | valider la pièce **est** le geste d'entrée en salle 3 ; le serveur le refuse tant que la salle 2 n'est pas terminée | `DEC:24` |
| Paiement compatible exigé avant la salle 3 (`SPEC §4.1`) | exigé dès l'entrée en salle 2 ; sans moyen, la candidature reste en salle 1, jamais refusée | `DEC:28` |
| Matrice pawaPay, corridors à vérifier (`SPEC §4.4`) | référentiel déclaratif ; hors d'Afrique, Arabie saoudite comprise : virement bancaire ; aucune intégration | `DEC:28` |
| « Rejoindre la visio » (`SPEC §6`) | « Rejoindre l'entretien », dans la salle vidéo de l'app ; lien secondaire sur une ligne | `DEC:29`, `:35`, `:37` |
| Mention de séance non traitée | aucune mention à l'écran pendant l'entretien | `DEC:32` |
| Texte qui nomme les Compagnons, « Je certifie » (`SPEC §5`) | doctrine écrite : « voie d'Ahl as-Sunna », « à la lumière des salafs » ; « Je confirme » | `DEC:34` |
| Import de quelque 400 candidatures (`SPEC §9`) | import ponctuel qui reconnaît et pré-remplit ; la candidature naît à l'inscription par le lien | `DEC:26`, `:40`, `:57-62` |
| Frontend seul (`SPEC §1.2`) | lot serveur borné, base de test seulement | `DEC:25` |
| Ordre obligatoire (`SPEC §14`) | les lots serveur avancent en parallèle des maquettes, sur la base de test seulement | `DEC:25`, `SPEC §12.3`, `C/CANDIDATURES/LIRE_D_ABORD.md:30-32` |
| « Viviers » | mot non affiché ; « Salle des prêts à enseigner » | `DEC:35`, `REVUE §0` point 7 |
| Tri par adéquation et priorité (`SPEC §8.1`) | clés en clair, jamais un score | `DEC:43` |
| Confirmation groupée encadrée (`SPEC §8.2`) | aucune : une pièce se valide une à une | `DEC:24` (conséquence) |
| « Pays d'origine si utile » (`SPEC §3`, salle 1) | non demandé : aucune règle ne le lit, c'est une donnée personnelle de plus sans usage | à soumettre au directeur |
| « Sauvegarde des filtres si une capacité équivalente existe » (`SPEC §8.1`) | non construite | aucune capacité équivalente (`REVUE §3.4`) ; à soumettre au directeur |

### 0.2 bis Où ce document précise ou s'écarte d'une décision, à soumettre au directeur

| Décision | Ce document | Raison |
| :--- | :--- | :--- |
| Les anciennes réponses servent à reconnaître, « même courriel ou même téléphone » (`DEC:58-59`) | téléphone seul : rattachement proposé à la direction, appliqué par un geste journalisé (transition 27) ; rien n'est montré au candidat | aucun canal ne vérifie un téléphone (SMS désactivé, `REVUE §3.6`) ; montrer d'anciennes réponses sur un numéro tapé exposerait les données d'une autre personne |
| Les anciennes réponses servent à pré-remplir (`DEC:58`) | personnes de B : reconnues par courriel confirmé, sans pré-remplissage (3.4) | l'import du 12/10 ne garde que prénom, nom et courriel (`REVUE §3.5`) |
| « Le super admin doit voir les deux côtés » (`DEC:30`) | le super-admin lit les deux côtés ; il ne mène un entretien que du même côté que le candidat | `DEC:30` ne parle que de lecture ; un entretien face à face avec une personne de l'autre genre n'est pas décidé (0.3) |
| Les anciennes réponses « ne créent pas de candidature à leur place » (`DEC:60`) | la direction peut garder une ligne `recue` de suivi (transition 2) | porter l'invitation (`DEC:27`) ou consigner l'envoi du lien par WhatsApp (`DEC:26`) ; choix de mise en oeuvre (3.2) |
| Une seule page d'accords ; l'app « ne renvoie jamais en arrière pour cocher après coup » (`C/DECISION-ENTREE-2026-10-17.md:30-32`) | accords en trois moments : confidentialité à l'inscription, cadre religieux en salle d'examen, contrat et avis en salle 2 ; une version neuve se ré-accepte (4.3) | ne pas demander trop tôt (`SPEC §2.1`) ; contrat et pièce après la salle d'examen : proposition de `REVUE §6.2`, pas une décision |
| Salles 2 et 3 « qu'aux personnes que l'académie peut payer » (`DEC:28`) | en salle 3, « garder une autre ligne `confirme` » veut dire garder un moyen déclaré **confirmé par la direction** qui croise une ligne `confirme` (contrôle de la section 5) ; qui n'a plus qu'un moyen déclaré non encore confirmé passe aussi en restriction « paiement à revérifier » ; la transition 24 s'ouvre alors en salle 3 sous restriction de cause `paiement`, puis la direction lève la restriction (21) | sûr par défaut : l'académie n'a pas vérifié qu'elle peut payer ce moyen ; sans la 24 en salle 3, la personne resterait bloquée (L6, relecture du 21/10) |
| Séparation femmes et hommes, « compteurs » compris (`DEC:30`, 8.2) | l'impact d'un changement du référentiel et ses alertes : une direction lit les restrictions de son côté, le super-admin les deux côtés (journalisé), la comptabilité le total ; aucun autre compteur ne sort ; une direction au genre inconnu est refusée | 8.2 range les compteurs dans la portée ; 8.1 donne l'impact à la comptabilité, qui n'a pas de côté. À trancher : la direction doit-elle lire le total des deux côtés, et la comptabilité le garder ? |
| Le questionnaire de la Salle d'examen (2.1, fiche `CAND-01`) | **décidé le 22/10** (`C/DECISION-CANDIDATURES-2026-10-21.md`, section 1 ter ; `M/20261022000000_cand_l2a1_moteur_salle_examen.sql:600-638`, C17) : `languesExplication` sans aucun plafond, sans l'arabe (qui n'est pas une langue de cours), poular, peul et fulfulde réunis sous `poular` (plus de `ff`), avec les langues du public visé et « autre langue » (`autre`) ; `langueMaternelle` facultative (l'arabe y reste) ; mémorisation (`aucune`, `moins_10_juz`, `de_10_a_29_juz`, `coran_entier`) et ijaza (`oui`, `pret_test`, `non`) en deux questions ; `publics` par tranches d'âge (`6_9`, `10_13`, `14_17`, `adultes`, au moins une) ; `disponibilitesDeclarees` en **plages par jour ISO à bornes en heures entières**, dans le fuseau unique de `fuseauIana`, sans chevauchement (demandé par le directeur le 22/10, C18, 2.1 bis) ; `classesSouhaitees` (de `1` au nombre maximal de Classes par enseignant, `3` par défaut : réglage `enseignant.classes_max`, `M/20261022000200_classes_plafond_par_enseignant.sql` et `M/20261022000300_cand_classes_souhaitees_suit_le_plafond.sql`) à la place des heures par semaine ; `moyensAccessibles`, nouveau champ facultatif et informatif (5.1) ; la continuité est une clause des conditions acceptées (2.1). **Encore proposé** (listes fermées de L2A1) : `riwayat` (choix multiple parmi les vingt riwayat des dix lectures) ; `niveauLectureTajwid` (`lecture_sans_regles_tajwid`, `tajwid_applique`, `tajwid_enseigne`) ; `experienceDebutants` (`oui`, `non`) ; la date de début par la liste du mappage (`debutPossible`, `MAP §3.6`), pas une date ; les langues hors référentiel, des codes ISO 639 de `MAP §3.2` (`man`, `sus`, `sw`, `ha`, `wo`, `bm`, `snk`, `mnk`, `ar`… 24 codes, plus `autre`). Les libellés ne sont pas en base : le serveur rend des codes, l'écran les affiche par des clés i18n `fr` et `ar`, alors que la fiche `CAND-01` les voulait rendus par le questionnaire | le directeur a tranché les langues, la mémorisation, l'ijaza, les publics et les classes ; ni `SPEC` ni une décision ne fixent les autres listes ; des codes fermés évitent toute saisie libre (2.1) ; une liste change en publiant une version du questionnaire (ici, `salle-examen-1` n'étant appliquée nulle part, elle a été corrigée sur place). À trancher : les listes encore proposées, des libellés en base plutôt qu'en clés i18n, le code du malinké (`man`, la macrolangue ISO 639-3, ou un code plus précis) et le fait que les codes d'un questionnaire puissent commencer par un chiffre (`6_9`, `1`) |
| Refus et retrait pendant une pause (4.2, lignes 16 à 18 ; 4.3) | le refus (16) et le retrait (17) lèvent la pause : une issue terminale n'est pas en pause ; l'événement le dit (`pauseLevee`) | sans cela, une candidature rouverte (19) le serait en pause sans que personne l'ait décidé |
| Candidat maintenu faute de moyen de paiement (`DEC:28`, transition 8) | en `paiement_non_disponible`, le candidat ne modifie ni ne renvoie ses réponses : aucune transition de 4.2 ne le lui ouvre ; il reste libre de partir (17) ; seule la transition 9 (une ligne passe `confirme`) le rend à `a_completer` | lecture stricte de 4.2. À trancher : un candidat qui ouvre un compte bancaire corrige-t-il sa déclaration (transition neuve) ? |
| Conditions de rémunération avant le 1er novembre 2026 (`C/DECISION-TARIFS-2026-10-18.md:13-16`) ; répartition du paiement montrée en pourcentages seulement (décision du directeur du 22/10 : `C/DECISION-TARIFS-2026-10-18.md`, section du 22/10, et `C/CANDIDATURES/PROPOSITION_REPARTITION_PAIEMENT.md` section 2.2 point 1, tous deux sur la branche principale et pas encore dans cet arbre) | le candidat lit la politique en vigueur si elle paie par élève présent, sinon la prochaine publiée qui le fait, avec sa date d'effet et **la part de l'enseignant en pour mille, par public** : aujourd'hui la v2.0.0 (47 %, en vigueur le 1er novembre) ; **aucun montant n'est rendu, ni le taux par élève présent et par heure, ni la devise** : qui veut les montants les demande à l'administration ; le taux ne sert plus qu'à reconnaître la politique qui paie par élève présent ; la v1.0.0, encore en vigueur et caduque, n'est jamais montrée ; une politique sans sa ligne de part de l'enseignant n'est pas montrée du tout, et l'envoi est refusé (`conditions_indisponibles`, `M/20261022000000_cand_l2a1_moteur_salle_examen.sql:938-976`) | la décision du 19/10 rend caduques les valeurs de la v1.0.0 ; la décision du 22/10 retire les montants de ce que le candidat lit (1,99 $ et 1,57 $ n'y figurent plus) ; montrer une politique pas encore en vigueur reste un choix |
| Brouillon du questionnaire et questions rouvertes après un complément (`CAND-F15`, `C/CATALOGUE_ECRANS_RECRUTEMENT.md:2006` ; fiche `CAND-01`, `:700`) | brouillon gardé **au serveur** (L2A1) : un document de réponses marqué brouillon, qui porte sa propre version, attendue par l'enregistrement suivant (`conflit_brouillon` sinon) et qui ne change jamais la version de la candidature (`M/20261022000000_cand_l2a1_moteur_salle_examen.sql:1315-1365`, `:2006-2069`) ; après un complément demandé (transitions 7, 9, 23), **toutes** les questions se rouvrent, alors que la fiche `CAND-01` ne rouvrirait que les questions nommées | `CAND-F15` laissait le choix entre un brouillon local et un brouillon au serveur ; un brouillon local se perd d'un appareil à l'autre. Les codes demandés (`aCompleter`) ne nomment pas encore des champs du questionnaire, mais des cartes : la transition 9 de L6 nommait `moyen_paiement`, qui n'est pas une carte du questionnaire ; depuis la relecture de L2A2 (22/10) elle nomme `versement`, la carte de la liste fermée des lignes 7 et 23 (`private.paiement_recalculer`, recopié de L6). À trancher : brouillon au serveur ou sur l'appareil ; questions nommées seules ou toutes rouvertes |
| Modèle de message du refus et de la pause (4.2, lignes 16 et 18 ; `PORTS §1`) | liste fermée proposée par L2A2 (`M/20261022000100_cand_l2a2_gestes_direction.sql:235-250`) : refus `refus_general`, `refus_niveau`, `refus_besoins`, `refus_sans_reponse` ; pause `pause_attente_besoin`, `pause_attente_informations`, `pause_demande_candidat`, `pause_general` ; un modèle hors de la liste est refusé (`modele_inconnu`) ; le serveur garde la clé, les textes `fr` et `ar` s'écrivent avec les écrans, selon `mots-rewayah` | ni `SPEC` ni une décision ne fixent ces modèles ; le contrat de la file veut la clé d'un modèle d'une liste fermée (`C/CANDIDATURES/CONTRAT_FILE_COURRIELS.md:79-81`), jamais un texte libre. À trancher : la liste et ses textes |
| Éléments manquants nommés au candidat (4.2, lignes 7 et 23) | liste fermée par salle (`M/20261022000100_cand_l2a2_gestes_direction.sql:333-357`) : en Salle d'examen, les cartes du questionnaire courant (`langues`, `recitation`, `disponibilites`, `publics`, `versement`) et `cadre_religieux` ; en Salle de vérification et d'entretien, `piece_identite`, `cadre_religieux`, `contrat`, `avis`, et non les réponses du questionnaire. **La fin d'un complément de salle 2** (relecture du 22/10) : aucun envoi ne remplace la demande en salle 2 (la transition 6 ne vaut qu'en salle 1), et la plupart des éléments (pièce, contrat, avis) n'ont pas de fin calculable avant L2B ; `complementDemande` et le compteur « informations manquantes » lisent le dernier événement qui porte une liste, si bien qu'une demande ne finissait jamais. Retenu : la direction clôture le complément par la transition 23 avec le seul code `complement_clos` (même état, événement à liste vide, aucun marqueur de notification ; `aucun_complement` quand rien ne court), et peut en demander un neuf ensuite | une demande ne nomme que ce que le candidat peut faire dans sa salle : aucune transition de 4.2 ne lui rouvre ses réponses en salle 2 ; un élément libre serait un texte libre. À trancher : la liste ; si un candidat de salle 2 corrige ses réponses (transition neuve) ; et la fin d'un complément de salle 2 : clôture par la direction (retenue), ou fin calculée par élément (cadre accepté à la version requise, pièce déposée, contrat et avis acceptés), qui demande la pièce de L2B |
| Rouvrir (4.2, ligne 19 : « contrôles de l'étape revérifiés, questionnaire à la version courante ») | lecture stricte (`M/20261022000100_cand_l2a2_gestes_direction.sql:438-504`, `:1085-1128`) : compte conforme (règle de CAND-L1B, nommée au lieu d'être levée) ; pour un état qui suit un envoi (en examen, `paiement_non_disponible`, salle 2), dernier questionnaire envoyé complet à la version courante ; **en salle 2 seulement**, `paiement_compatible` et cadre religieux à la version requise (section 5 : le cadre est exigé pour la salle 2, et rouvrir une candidature de salle 2 est une rentrée en salle 2). Une candidature dont le questionnaire ou, en salle 2, le cadre a changé de version pendant qu'elle était refusée ou retirée ne se rouvre donc pas, et ce blocage ne se lève pas de lui-même : elle ne peut pas ré-accepter un texte avant d'être en cours (policy de `contract_acceptances`, `M/20261022000000_cand_l2a1_moteur_salle_examen.sql:872-906`, `:2006-2069`), et la direction ne peut pas la rouvrir. À l'inverse, une candidature en examen se rouvre sans le cadre ni les conditions de rémunération que la transition 6 exige : seul son questionnaire est contrôlé | la lecture stricte de « contrôles de l'étape revérifiés » (section 5) ; ce n'est pas la règle du candidat qui bloque la salle 2 (rouverte, il peut accepter la version neuve, 4.3), c'est le contrôle d'entrée. À trancher : garder la lecture stricte ; ou retirer le cadre des contrôles de la réouverture en salle 2, le candidat le ré-acceptant ensuite (4.3 : avant la salle 3 ; `etat_dossier()` le nomme déjà dans `aCompleter`), ce qui supprime le blocage ; ou rouvrir alors en `a_completer` |
| Rouvrir une candidature refusée ou retirée en entretien planifié (4.2, lignes 12, 16, 17, 19) | le refus et le retrait notent `entretienPlanifie` dans l'événement (L4 annulera la séance, lignes 16 et 17) ; la réouverture rend l'étape et l'état d'origine, donc `entretien_planifie`, alors que la séance annulée n'existera plus ; la ligne 12 ramène l'état à `entretien_a_planifier` quand un entretien est annulé. Figé par le scénario de L2A2 pour que L4 le voie ; rien ne l'exerce avant L4, aucune séance n'étant planifiable | 4.2 ne dit pas si l'état d'origine après un entretien annulé est `entretien_planifie` ou `entretien_a_planifier`. À trancher avec L4 : rouvrir en `entretien_a_planifier` quand le refus ou le retrait a noté `entretienPlanifie` (une règle neuve de la table du moteur, `rouvrir` variante 2) |
| Séparation femmes et hommes, journal compris (`DEC:30`, 8.2, 8.3) | une ligne d'`audit_logs` qui vise une candidature, ou dont l'auteur porte une candidature avant la salle 3, ne se lit que du côté de cette candidature (`journal_audit()`, `journal_audit_filtres()`, lecture directe) ; l'auteur porteur de candidature est rendu par la référence `CAND-` ; la trace d'une tentative hors portée vise l'autre côté : son auteur ne la relit pas ; la lecture directe d'`audit_logs` n'a pas l'exception du super-admin, qui lit les deux côtés par `journal_audit()`, journalisé ; une trace de l'exception qui ne vise aucune candidature n'est lue que sous l'exception (`M/20261022000000_cand_l2a1_moteur_salle_examen.sql:2346-2640`) | 8.2 range l'historique et les compteurs dans la portée ; 8.3 veut la référence, jamais le nom ; une lecture directe ne se journalise pas. À trancher : une direction relit-elle ses propres tentatives hors portée, et la direction de son côté relit-elle les traces de l'exception du super-admin ? |
| Les autres compétences des candidats (décision du directeur du 22/10 : leur demander discrètement, sans les ennuyer, en disant pourquoi ; `PROPOSITION_AUTRES_COMPETENCES.md`) | **catalogue de compétences précises en base** (25 compétences en six familles ; ajout seul ou désactivation, jamais de suppression ; écrit par la direction seule, journalisé), table à une ligne par candidature et trois RPC du titulaire (`M/20261022000500_cand_autres_competences.sql`) ; ouvert **après l'envoi de la Salle d'examen** (un brouillon n'ouvre rien) et tant que la candidature est en cours, pause comprise ; **retirer ses réponses et son accord reste permis après un refus ou un retrait** de la candidature ; écrire ne change ni la version de la candidature, ni sa dernière activité, ni son journal d'événements ; la validation lit le catalogue actif (une compétence désactivée reste lisible dans une réponse ancienne et ne peut plus être choisie, sauf par qui l'a déjà) ; la direction les lit dans le dossier (`autresCompetences`) et filtre la liste par code ou famille de compétence, niveau minimum, disponibilité exacte et accord, dans la portée femmes et hommes ; **pas d'accord, pas de mission** (règle d'écran : la recherche d'une mission envoie `competenceAccord: true`) ; jamais lues par un contrôle, le paiement ni `etat_dossier()` | la proposition dit « à tout moment » et ne ferme rien ; le reste est la lecture la plus sûre. À trancher : le droit de retirer après un refus (sinon, une personne refusée n'enlève plus son accord), les langues de la compétence `traduction` (aucune n'est portée par le serveur), les libellés du catalogue en arabe (le catalogue ne porte que le français), les familles (liste fermée de six), si le juriste veut la version du texte de l'accord (une colonne de plus), et si une candidature retirée garde son accord d'être contactée (aujourd'hui oui, jusqu'à `retirer_autres_competences`) |

### 0.3 Ce qui reste ouvert

| Question | Ce qui manque | Qui tranche | Effet tant que c'est ouvert |
| :--- | :--- | :--- | :--- |
| `CAND-Q05` | pays et moyens qui fonctionnent en Afrique (par exemple le mobile money par pawaPay) ; sort d'un candidat qui vit en Afrique et a un compte bancaire (`DEC:80-83`) | directeur | toutes les lignes d'Afrique du référentiel restent `en_verification` : aucun candidat dont le pays de versement est en Afrique n'entre en salle 2 |
| Liste des pays d'Afrique | la liste du référentiel ; c'est elle qui décide qui entre en salle 2 (`DEC:28`) | proposée en L6 le 21/10 (60 pays ou territoires, ONU M49 région 002, 5.1), soumise au directeur avec `CAND-Q05` | même effet que `CAND-Q05` |
| `CAND-Q12` | accord sur les trois noms de salle (`DEC:87-88`) ; forme du côté des femmes pour « Salle des prêts à enseigner », en français et en arabe ; « Salle d'examen » croise « examen de fin des bases », mot du programme (`mots-rewayah` §3) | directeur | les noms proposés sont les valeurs des clés i18n ; un changement ne touche que les textes |
| `CAND-Q21` | durée de conservation, avis du juriste (`DEC:90`) ; base des courriels envoyés avant l'inscription et conservation des réponses importées de qui ne s'inscrit pas (8.4) | directeur, après le juriste | aucune purge automatique des candidatures ; `CAND-BR-14` n'est pas commencé ; il couvrira aussi les deux tables d'idempotence de L2A1 (8.4) |
| Super-admin intervieweur | le super-admin peut-il mener l'entretien d'une personne de l'autre côté ? | directeur | refus : l'intervieweur est du même côté que le candidat, super-admin compris |
| Ligne `recue` de suivi | confirmation du choix de mise en oeuvre (3.2) | directeur | le geste « garder pour suivi » s'écrit en L3 sur la base de test ; il ne s'ouvre pas en production sans réponse |
| Canal du code d'invitation | tant que l'envoi de la file manque (7.3), par où la direction transmet-elle un code ? WhatsApp est exclu hors lien d'inscription (`DEC:29`) | directeur | aucune invitation n'est émise en production |
| Accords en trois moments | l'écart à la page unique (0.2 bis) | directeur | L2 suit ce document sur la base de test ; rien en production. Le dépôt de pièce suit déjà 2.1 en base (CAND-L1B : salle 2 en cours ou salle 3, toute voie) ; si le directeur garde la page unique, un lot rouvre le dépôt en salle d'examen |
| Pays de la carte publique | recopier le pays de résidence déclaré dans `teacher_profiles.country`, public sur la carte (`C/ENS-PAYS-1_BR.md:3`) ? | directeur | non recopié ; l'enseignant le pose dans son profil, comme aujourd'hui (2.2) |
| Personne de B sans courriel | 1 personne (`REVUE §2.4`), sans réponse importée ni ligne : où consigner l'envoi du lien par WhatsApp ? | L3, puis directeur si un geste neuf est nécessaire | l'envoi n'est pas consigné dans l'app |
| Durée de conservation des pièces | point de départ : dépôt (aujourd'hui) ou décision (4.1) | directeur | `purge_at` vaut dépôt plus 90 jours ; aucune purge programmée |
| Forme de `teacher_id` pour la séance d'entretien | `teacher_id` est obligatoire aujourd'hui (6.1) | L4 | L4 n'écrit pas ses scénarios sans elle |
| `ff` et `poular` | **tranchée** le 22/10 (`C/DECISION-CANDIDATURES-2026-10-21.md`, section 1 ter) : poular, peul et fulfulde sont une seule langue, le code `poular` ; il n'y a plus de `ff` (section 9, `MAP §3.2`) | directeur, 22/10 | plus aucun : l'import convertit `ff`, peul et fulfulde en `poular` |
| Forme en base du compte candidat | **tranchée** par le complément CAND-L1B (21/10, repris après relecture) : rôle `teacher`, `account_status` `pending_kyc`, fiche `teacher_profiles` vide, la même pour les deux portes ; règle et preuve en 3.1, condition 1 (`supabase/tests/scenarios_cand_l1b_forme_compte.sql`, `supabase/tests/scenarios_cand_l1b_concurrence.sql`) | L1, complément CAND-L1B, sans question au directeur | plus aucun pour la forme : L2 s'écrit sur elle ; `testé localement` seulement, rien sur staging ni en production |
| Un membre de la direction change son propre genre | `guard_profile_privileged_columns` laisse tout compte de la direction active changer le genre de n'importe quel profil, le sien compris (`C/CANDIDATURES/CORRECTIFS_HORS_MODULE_PROPOSES.md` section 0 ter) ; or le genre du lecteur décide de la portée de toutes les lectures (8.2) et, depuis L2A2, de tous les **gestes** (4.2 ; D13 du lot) ; aucun journal ne garde le changement | directeur (correctif proposé, non écrit : refuser le changement de son propre genre, ne l'autoriser qu'à `service_role` ou au super-admin de `0088`, le journaliser, scénario) | tant que c'est ouvert, une direction peut se mettre de l'autre côté, puis lire **et**, depuis L2A2, refuser, mettre en pause, rouvrir ou confirmer un moyen pour l'autre côté, sans trace ; à corriger avant tout passage sur staging |
| Portée par genre des comptes candidats hors module | la forme `teacher` + `pending_kyc` met chaque candidat dans les surfaces de la direction qui listent des comptes ; `DEC:30` et 8.2 bornent la direction à son côté. CAND-L1B borne `comptes_admin()` (`ADM-08`), `dossiers_en_attente()` (`ADM-02`), le compteur d'`indicateurs_admin()` (`ADM-01`) et la table `profiles` (3.1). L2A1 (22/10, repris après relecture) borne aussi le journal d'audit et les accords, puisqu'il est le premier lot à écrire des lignes d'audit dont l'auteur est un candidat : `journal_audit()`, `journal_audit_filtres()`, la lecture directe d'`audit_logs` et celle de `contract_acceptances` (8.2, `M/20261022000000_cand_l2a1_moteur_salle_examen.sql:919-925`, `:2346-2640`). Restent non bornés : `demandes_suppression_lister()`, `jetons_agent_actifs()` ; et le refus d'une écriture directe d'affectation (`compte_candidat_non_affectable`), qui dit à la direction de l'autre côté qu'un identifiant déjà connu d'elle porte une candidature | L2B, qui étend `ADM-02` et `decider_dossier()` | ces surfaces nomment un compte candidat à toute la direction, sur la base de test seulement ; aucune production (`DEC:25`) |

L'écran du référentiel va dans Finance, sauf avis contraire (`DEC:85`).

Les points à trancher par le directeur (sections 0.2, 0.2 bis et 0.3) lui sont
posés dans la page d'arbitrage comme questions de suivi `CAND-S01` à `CAND-S11`.
Ses réponses s'y enregistrent comme les 22 premières. Restent à y poser comme
questions de suivi : les deux lignes de 0.2 bis ajoutées par L6 le 21/10
(paiement en salle 3, compteurs du référentiel) et les six ajoutées par L2A1 le
22/10 (listes fermées du questionnaire, refus et retrait qui lèvent la pause,
candidat maintenu faute de moyen de paiement, conditions de rémunération avant le
1er novembre, brouillon et questions rouvertes après un complément, journal
borné par genre), puis les quatre ajoutées par L2A2 le 22/10 (modèles de message
du refus et de la pause, éléments d'un complément et sa fin, réouverture,
réouverture en entretien planifié), la ligne des conditions de rémunération
corrigée le 22/10 par la décision du directeur (pourcentages seulement). D'ici sa
réponse, le serveur applique la lecture la plus sûre décrite dans ces lignes.

---

## 1. Périmètre et principes

1. **Moteur générique, option C** (`REVUE §6.1`) : une candidature porte un
   **type** ; le type désigne un jeu d'étapes **fermé** et une liste de
   **contrôles nommés**, calculés en base ; les réponses sont un document versionné
   par questionnaire. Ni constructeur de formulaires, ni pipeline codé pour le
   seul enseignant.
2. **Le type `enseignant` d'abord.** Aucun autre type sans décision ; une fixture
   `comptable` prouve en SQL qu'un type ne touche pas l'autre (`SPEC §2.2`, `§13`).
3. **Une candidature ne crée jamais un compte actif par elle-même.** Seule la
   validation de la pièce, en fin de salle 2 et sous la garde du serveur, fait
   d'un candidat un enseignant actif (`DEC:24`, `:50-51`). Elle ne valide jamais une
   pièce et ne signe jamais un accord au nom de la personne.
4. **Tout droit se décide en base.** L'écran lit des capacités et l'état rendu par
   le serveur, ne recalcule rien, ne lit jamais un rôle
   (`C/02_ARCHITECTURE_ET_SECURITE.md:19`).
5. **Pas de seconde source de vérité** (`REVUE §5.1`). Sont réutilisés :
   invitation et parcours d'inscription (`/inscription`, `UsageEtape`,
   `InvitationCandidatPage`) ; accords ; pièce et `ADM-02` ; `/attente` et
   `etat_dossier()` ; messagerie métier ; `notifications` ; `audit_logs` ; motif
   d'import du 12/10 et réclamation après preuve du courriel
   (`reclamer_preinscription_apres_preuve()`) ; table des pays
   `lib/core/i18n/pays_iso.dart` ; `BarreSelection` (promue) ; salle vidéo
   `/salle`.
6. **Hors périmètre** : intégration d'un prestataire de paiement (`DEC:28`), envoi
   de courriels (`DEC:33`), refonte LiveKit, production sans feu vert (`DEC:25`),
   les cinq défauts hors module (section 13).

---

## 2. Le parcours en salles

Les salles sont des **étapes de recrutement**, jamais des communautés : aucun
candidat ne voit un autre candidat (`SPEC §15` point 2). Les codes restent
internes ; seuls les noms s'affichent, toujours en entier (noms proposés,
`CAND-Q12`). Dans ce document, « salle 1 », « salle 2 » et « salle 3 » sont des
raccourcis internes, jamais affichés.

| Code d'étape | Nom affiché | Objet |
| :--- | :--- | :--- |
| `recue` | aucun (vue de la direction) | ligne gardée par la direction pour suivre une personne des formulaires ; pas encore de compte (choix à confirmer, 0.2 bis) |
| `invitee` | aucun (vue de la direction) | invitation émise, pas encore consommée |
| `prequalification` | **Salle d'examen** | savoir si la candidature mérite les vérifications, et si l'académie peut payer |
| `verifications` | **Salle de vérification et d'entretien** | vérifier, rencontrer, réunir les accords et la pièce |
| `confirmee` | **Salle des prêts à enseigner** | compte actif, affectable |

### 2.1 Ce qui se demande, à quel moment

Mise à jour de `REVUE §6.2` par `DEC:28`, `:34`, `:45`, `:63-64`.

| Moment | Demandé | Jamais avant |
| :--- | :--- | :--- |
| Inscription (lien public ou code) | courriel confirmé, nom affiché, genre (obligatoire en base, 3.4), téléphone avec indicatif (indicatif choisi dans une liste, normalisé selon `MAP §4`), langue de l'interface (`fr` ou `ar`), accord de confidentialité | - |
| Salle d'examen | langues d'explication (codes, **autant que la personne veut**, sans l'arabe : « le programme est international », la langue de cours est celle que l'élève ou le parent choisit et pour laquelle l'académie affecte un enseignant qui la parle) et langue maternelle (**facultative**) ; niveau de mémorisation déclaré (aucune, moins de 10 juz', de 10 à 29, Coran entier) **et** ijaza présentable (oui, prêt à un test, non), deux questions ; niveau de lecture et de tajwid déclaré ; riwaya ; expérience avec les débutants ; disponibilités déclarées (**plages par jour ISO, en heures entières**, dans le fuseau IANA déclaré, 2.1 bis) ; **classes souhaitées** (1, 2 ou 3) ; date de début ; **publics enseignables par tranche d'âge** (6-9, 10-13, 14-17 ans, adultes, au moins une) ; pays de résidence ; pays de versement ; fuseau IANA ; compte bancaire oui ou non ; opérateurs accessibles ; **moyens accessibles** (facultatif, informatif, 5.1) ; accord de rémunération ; cadre religieux et pédagogique | - |
| Salle de vérification et d'entretien | contrat `teacher_nda`, avis `recording_and_control_notice`, pièce d'identité ; à l'entretien : constat (niveau observé, riwaya, ijaza présentée), compte rendu, avis | salle d'examen terminée et paiement compatible |
| Après l'envoi de la Salle d'examen, **facultatif** (décision du 22/10, `C/DECISION-CANDIDATURES-2026-10-21.md` section 1 quater ; `PROPOSITION_AUTRES_COMPETENCES.md`) | **autres compétences** : compétences précises du catalogue en base (25 au départ, six familles, que la direction complète), niveau de chacune (`debutant`, `experience`, `metier`), texte court de « autre », disponibilité pour une mission (`quelques_heures`, `mi_temps`, `plus`, `pas_maintenant`), accord d'être contactée ; la raison est dite en premier ; rien sur le salaire d'une mission | l'envoi de la Salle d'examen (jamais dans la salle elle-même : elle reste courte) ; jamais lues par un contrôle, le paiement ni l'état du dossier |
| Après l'entrée en salle 3 | photo, titre, pays de la carte, `weekly_availability` ; code de conduite tant que le lot `conduite` n'est pas passé (section 13) | l'entrée en salle 3 |
| Premier versement | coordonnées financières, par `CPT-13` | salle 3 et début des cours |

Le téléphone n'est lu que par `candidatures.contact`, jamais dans une liste (8.3).
Il sert au rattachement (3.4) et à `profil_unique` (section 5). Sans lui, une
personne des formulaires qui crée un courriel neuf (`DEC:54-56`) ne serait jamais
reconnue, et un candidat refusé reviendrait sous un autre courriel sans être vu.

Ijaza, diplôme et attestation se **présentent à l'entretien** et se constatent
dans le compte rendu ; aucun dépôt dans l'app pour l'instant (`DEC:45`).

**La continuité** (directeur, 22/10 : tenir sa Classe aux mêmes jours et heures) est une
**clause du texte des conditions que le candidat accepte**, pas une question du
questionnaire : sa preuve est l'acceptation enregistrée dans `contract_acceptances`, à la
version lue. **Rien à faire côté serveur** : aucun champ, aucune colonne, aucune RPC. Le
texte précis (les conditions de rémunération, le cadre pédagogique ou le contrat) s'écrit
avec les écrans, selon `mots-rewayah` et `programme-rewayah`, et passe par le directeur.
De même, le contrôle de paiement reste la condition d'entrée en salle 2 : le directeur
veut s'assurer que les personnes qui s'engagent pourront être payées (5.1).

La page d'accords existante montre les textes requis **à l'étape courante** : le
cadre religieux en salle d'examen, le contrat et l'avis en salle 2. Elle garde
la règle « une case par texte, un seul bouton Suivant »
(`C/DECISION-ENTREE-2026-10-17.md:30-31`). Le découpage en trois moments s'écarte
de la page unique de cette décision ; il vient de `SPEC §2.1` et d'une proposition
de `REVUE §6.2`, pas d'une décision (0.2 bis).

### 2.1 bis Les disponibilités déclarées et `weekly_availability`

Demandé par le directeur le 22/10 : « les formulaires de base ne sont pas des
références […] la grille horaire […] est-ce qu'elle peut couvrir tout ce que
l'académie a besoin pour déterminer réellement les créneaux de l'enseignant et les
faire matcher avec ceux de l'élève ? ». Statut : `présent dans le code`, `testé
localement` (ni staging ni production) ; migration
`M/20261022000000_cand_l2a1_moteur_salle_examen.sql`, C18 ; non appliquée.

**Ce que lit l'affectation.** Une Classe, ce sont trois séances par semaine aux
mêmes jours, à une **heure de début entière** (`offres_horaires.heure_locale`,
`groupe_creneaux.hour_local`), de 60 minutes (enfants) ou 90 minutes (adultes)
(`offres_horaires.duree_minutes`). Le prédicat d'affectation compare la Classe aux
lignes de `weekly_availability` : un jour ISO (1 à 7), une heure entière (0 à 23), un
fuseau IANA, une ligne par heure et par personne (clé unique `profile_id`, `weekday`,
`hour_local`). La demi-heure de la première version ne pouvait pas y entrer sans
deviner, et le second fuseau de la grille pouvait contredire `fuseauIana`.

**Le champ `disponibilitesDeclarees`** est donc une liste de plages :
`[{"jour": 1, "debut": "18:00", "fin": "21:00"}, …]`.

| Règle | Détail |
| :--- | :--- |
| Jour | ISO 8601, 1 (lundi) à 7 (dimanche) |
| Bornes | `debut` au format `HH:00`, `fin` au format `HH:00` ou `24:00` : des heures entières, jamais de minutes |
| Durée | `fin` strictement après `debut` : au moins une heure par plage ; au moins une plage (champ requis) ; au plus 168 (7 jours de 24 plages d'une heure) |
| Chevauchement | deux plages d'un même jour ne se recouvrent pas ; une plage identique à une autre se recouvre ; deux plages qui se touchent (18 h-19 h puis 19 h-21 h) ne se recouvrent pas. Le refus est nommé : `reponses_invalides`, champ `disponibilitesDeclarees`, avec `motifs` `{disponibilitesDeclarees: plages_qui_se_chevauchent}` (la clé `motifs` n'est rendue que si une cause est nommée) |
| Fuseau | aucun dans la grille : les heures sont celles de `fuseauIana`, le seul fuseau du questionnaire, jamais converties |
| Minuit | une plage ne passe pas minuit : de 22 h à 1 h, deux plages (jour D de `22:00` à `24:00`, jour D + 1 de `00:00` à `01:00`) |
| Ancienne forme | `{fuseau, creneaux}` et les demi-heures sont refusés (la version `salle-examen-1` n'étant appliquée nulle part, elle est corrigée sur place) |

**Comment les plages deviennent des lignes de `weekly_availability`** à l'entrée en
salle 3. Cette copie **n'est pas écrite** (aucune fonction n'écrit `weekly_availability`
pour un candidat ; la ligne « Après l'entrée en salle 3 » de 2.1 la demande après
l'entrée) ; elle est du lot L2B, que ce soit une copie directe ou un brouillon que
l'enseignant confirme. La règle, elle, est posée et testée : **une ligne par heure
couverte**. Pour chaque plage, chaque heure `h` de `debut` à `fin - 1` donne
`(profile_id du compte enseignant, weekday = jour, hour_local = h, timezone_iana =
fuseauIana)`.

| Plage déclarée | Lignes de `weekly_availability` |
| :--- | :--- |
| lundi 18:00-21:00 | jour 1, heures 18, 19 et 20 (3 lignes) |
| mercredi 22:00-24:00 | jour 3, heures 22 et 23 (2 lignes) |
| jeudi 22:00-24:00 puis vendredi 00:00-01:00 | jour 4, heures 22 et 23 ; jour 5, heure 0 |

- La clé unique ne connaît pas le fuseau : `fuseauIana` étant unique, une personne n'a
  qu'un fuseau dans la table ; c'est aussi celui que l'entrée recopie dans
  `teacher_profiles.timezone_iana` (2.2, `mon_fuseau()`).
- L'absence de chevauchement garantit qu'aucune heure n'est produite deux fois : le
  scénario le prouve contre la vraie table (l'expansion de plages qui se chevauchent
  viole la clé unique).
- `weekly_availability` n'a aucun droit de modification (une case se pose ou se retire).
- Le scénario de L2A1 prouve que les lignes ainsi produites sont lues par le vrai
  prédicat d'affectation, heure par heure (lundi 18 h-21 h : les Classes **d'enfants**, de
  60 minutes, de 18 h, 19 h et 20 h sont couvertes, celles de 17 h et de 21 h ne le sont
  pas ; une Classe d'adultes, de 90 minutes, demande deux heures consécutives : voir
  ci-dessous), y compris entre deux fuseaux (plage de Riyad, Classe de Conakry, comparées
  en instants).

**Ce que l'import ne fait pas.** Les formulaires d'origine (colonne J) donnent des
tranches horaires **sans aucun jour** (« de 8 h à 10 h du soir ») : rien ne peut
pré-remplir ce champ sans deviner des jours (`MAP §3.5`).

**Comment l'affectation compare un cours de 90 minutes** (corrigé le 22/10, lot
`CLASSES-DUREE` : `présent dans le code`, `testé localement`, ni staging ni production ;
`M/20261022000400_classes_affectation_couvre_toute_la_duree.sql`, scénario
`supabase/tests/scenarios_classes_duree_affectation.sql`). Le défaut constaté le 22/10 sur
`app_private.verifier_affectation_enseignant_base` (une durée unique de 60 minutes pour
toutes les Classes ; une seule ligne d'une heure qui devait contenir toute la séance, si
bien que les lignes 18 et 19 ne couvraient jamais un cours de 18 h à 19 h 30 et que la
seule ligne 18 couvrait à tort un cours d'adultes ; collisions et plafond horaire comptés
avec la même durée pour les deux Classes en présence) **n'est plus ouvert** :
1. **La durée est celle de la Classe.** `app_private.duree_seance_minutes(offre_id,
   type_public)` la lit : d'abord la durée de l'**offre** dont la Classe est née
   (`groupes.offre_id`, `offres_horaires.duree_minutes`), parce que c'est ce que l'académie
   a publié aux familles et que la Classe le tient jusqu'à sa clôture, même si un réglage
   change ensuite ; sinon le réglage de son **public** (`groupes.type_public`, jamais nul :
   `seance.duree_minutes_adulte` 90, `seance.duree_minutes_enfant` 60, que la direction
   règle), qui est le cas d'une Classe créée par « Créer la classe » (elle n'a pas d'offre).
   `session_duration_minutes` ne sert plus qu'aux affectations individuelles récurrentes,
   qui n'ont ni offre ni public. Un public inconnu ou une durée hors de 15 à 240 minutes
   (la borne de `offres_horaires`) **refuse** (garde positive) : jamais de repli silencieux
   sur 60.
2. **Chaque heure entière touchée est couverte.** Une séance de `d` minutes qui commence à
   l'instant `D` occupe `[D, D + d)` ; elle est couverte quand l'**union** des heures
   déclarées de l'enseignant (une ligne de `weekly_availability` = une heure, `[instant de
   la ligne, + 1 h)`) contient tout l'intervalle, sans trou : lignes 18 et 19 pour 18 h-19 h 30,
   lignes 23 puis (jour suivant) 0 pour 23 h-0 h 30, lignes du dimanche 23 puis du lundi 0
   pour une séance qui franchit la semaine. Le compte se fait en instants, comme avant : la
   conversion de fuseau (`instant_creneau`, fuseau de la ligne et fuseau de la Classe), les
   52 semaines (les deux saisons) et les semaines voisines sont ceux de la définition
   précédente, avec une semaine de plus avant : les lignes déclarées sont prises de la semaine
   −1 à la semaine 52, parce que `instant_creneau` rend la **prochaine** occurrence après
   maintenant et que la ligne qui couvre le début de la prochaine séance, sur une grille
   décalée d'une demi-heure (Calcutta), a pu commencer il y a moins d'une heure (relecture du
   22/10 : sans la semaine −1, un enseignant couvert était refusé pendant cette demi-heure de
   la semaine ; les anciens tests n'y tombaient que par hasard de l'horloge). Conséquence voulue : un enseignant qui déclare dans un autre fuseau est
   comparé en instants, même quand les deux grilles ne tombent pas sur les mêmes heures
   (Calcutta, UTC+5:30 : un cours d'enfants de 18 h à Paris est couvert par l'union des
   lignes 21 et 22 en été, 22 et 23 en hiver ; l'ancien test d'une seule ligne le refusait
   toujours). Les lignes 19 et 20 de Riyad (UTC+3 toute l'année) ne couvrent que l'été un
   cours d'adultes de 18 h à Paris : il faut 19, 20 et 21 pour couvrir l'année. Le refus
   garde son message (`enseignant non disponible: jour, heure, fuseau, semaine, instant`) ;
   son `DETAIL` donne maintenant la durée retenue et le premier instant non couvert.
3. **Plafond horaire et collisions, avec la durée propre à chaque Classe** : le plafond
   horaire additionne la durée de chaque créneau (trois séances d'adultes = 4 h 30, trois
   séances d'enfants = 3 h) ; une collision compare l'intervalle de la Classe visée à celui
   de chaque Classe déjà tenue (une Classe d'adultes de 18 h à 19 h 30 chevauche une Classe
   d'enfants de 19 h ; une Classe d'enfants de 18 h à 19 h et une Classe de 19 h se touchent
   sans se chevaucher). Pour des Classes de 60 minutes, rien ne change.

Le verrou par enseignant, tous les autres refus nommés (compte, pièce, accès, langue, genre,
plafond horaire, collisions) dans le même ordre, le drapeau `p_exiger_disponibilites` (faux
pour `creer_groupe`, D4), l'enveloppe et le plafond de Classes
(`plafond_classes_atteint`, `M/20261022000200_classes_plafond_par_enseignant.sql`) ne
changent pas. `enseignants_pour_classe` appelle le prédicat : sa proposition suit la
nouvelle durée sans autre écriture.

Les scénarios qui posaient une Classe d'**adultes** avec une seule heure déclarée ont reçu
la seconde heure (`scenarios_classes_plafond_par_enseignant.sql`,
`scenarios_creer_groupe_predicat.sql`, `scenarios_offres_personnalisees.sql`) : ils
éprouvaient le plafond, la création et le suivi, pas la durée, et la durée d'un cours
d'adultes est maintenant celle de l'offre.

**Reste ouvert, hors de ce lot** (le point 4 du constat du 22/10, et un constat neuf) :
- le **côté élève** (son motif est aussi heure par heure) ;
- les **créneaux libres** de `enseignants_pour_classe` et `enseignants_pour_public`, qui
  comptent encore `session_duration_minutes` (60) : pour une Classe de 90 minutes, l'heure
  `H` n'est utilisable que si `H` et `H + 1` sont libres ; la proposition d'enseignants,
  elle, passe par le prédicat et est exacte ;
- **la durée des séances matérialisées** : `materialiser_seances_groupe`
  (`M/0055_classes_en_attente_enseignant.sql:67`) fixe la fin de chaque séance par
  `session_duration_minutes` (60) pour toutes les Classes, adultes comprises. Le calendrier
  réel d'une Classe d'adultes est donc de 60 minutes alors que l'affectation la compare
  désormais à 90 : à corriger dans un lot à part, qui change les séances créées (et
  `session_participants`, jetons, présence), à décider avec le directeur ;
- une Classe née d'une offre dont la durée diffère du réglage de son public : à la création
  par `creer_groupe` (appelée par `publier_groupe_depuis_offre` avant de poser `offre_id`),
  le prédicat compte encore la durée du public pour les collisions ; l'affectation
  suivante lit l'offre. `publier_groupe_depuis_offre` n'est exécutable par aucun rôle
  connecté (`proacl = {postgres=X/postgres}`) : aucun client n'y passe aujourd'hui ;
- **changer l'horaire d'une Classe déjà affectée** (constat de la relecture du 22/10,
  vérifié) : `modifier_groupe` (sept arguments, exécutable par `authenticated`, garde
  direction) change `weekday`, `hour_local` et `timezone_iana` d'une Classe qui a son
  enseignant **sans repasser par le prédicat** (ni couverture, ni collisions, ni plafond
  horaire) ; la direction écrit aussi `groupe_creneaux` directement (policy
  `groupe_creneaux_admin`). Seule la contrainte d'exclusion `sessions_no_teacher_overlap`
  retient un déplacement sur le même instant ; comme les séances matérialisées durent 60
  minutes (point précédent), elle ne voit pas le chevauchement d'une Classe d'adultes de 90
  minutes. À décider avec le directeur : repasser le prédicat (avec ou sans exigence de
  disponibilités) quand on déplace une Classe qui a un enseignant. Non corrigé, hors de ce
  lot (fonction `SECURITY DEFINER` sous F86).

### 2.2 Les trois salles

| | Salle d'examen (`prequalification`) | Salle de vérification et d'entretien (`verifications`) | Salle des prêts à enseigner (`confirmee`) |
| :--- | :--- | :--- | :--- |
| **Qui entre** | toute personne inscrite par le lien public ou une invitation consommée, de tout pays (`DEC:28`) | la candidature admise par la direction, cadre religieux accepté et paiement compatible (4.2, ligne 10) | seule la validation de la pièce dans `ADM-02`, acceptée quand les sept autres contrôles sont vrais (section 5) : « affectable à 100 % » (`DEC:24`), une fois les lots `langue` et `c11bis` passés (section 11) |
| **Le candidat voit** | `/attente` étendu et `CAND-01` : d'abord les conditions de rémunération, lues au serveur, jamais écrites en dur (`CAND-BR-12`) ; le questionnaire en cartes, choix dans des listes ; la case du cadre religieux ; son état ; sa conversation | la page d'accords (contrat, avis) ; le dépôt de pièce existant (`supabase/functions/piece-identite-depot/index.ts`) et son état (« à corriger » avec quoi) ; « Mon entretien » (`CAND-02`) ; ce qui lui est demandé en complément ; sa conversation | son espace enseignant ; `/attente` ne le retient plus ; les prérequis de travail existants (`M/20261016100500_contrats_travail_prerequis.sql:49-74`) |
| **La direction voit** | `ADM-20` filtré sur la salle ; `ADM-21` : réponses, déclaration de paiement, contrôle `paiement_compatible` | la vue Entretiens d'`ADM-20` ; dans `ADM-21`, les huit contrôles (vrai ou faux, cause) et le lien vers `ADM-02` | le filtre de la salle, affectée ou non ; les alertes « bloquées » et « confirmées indisponibles », jamais confondues |
| **Gestes** | demander un complément ; confirmer ou infirmer le moyen de paiement ; admettre en Salle de vérification et d'entretien ; pause ; refus | demander un complément ; planifier, consigner, reprogrammer l'entretien ; pièce à corriger ; valider la pièce ; pause ; refus | restreindre, lever la restriction ; noter ou lever une indisponibilité |
| **Sorties** | salle 2 ; à compléter ; maintenue faute de moyen de paiement (jamais un refus, libre de partir) ; refusée ; retirée ; pause | salle 3 ; à compléter (transition 23) ; entretien à replanifier ; pièce à corriger ; refus (dont refus définitif de pièce) ; retrait ; pause | jamais de retour d'étape ; restriction (manuelle, ou automatique quand un contrôle tombe) ; indisponibilité ; l'historique reste |

**Entrée en salle 3, dans une seule transaction :**
- pièce `approved` et `teacher_profiles.kyc_status = 'approved'` (déjà posé par
  `decider_dossier()`,
  `M/20261017100500_af_l1_05_decider_dossier_une_seule_fois.sql:63-65`) ;
- langues (codes) et fuseau IANA copiés des réponses vers
  `teacher_profiles.languages` et `teacher_profiles.timezone_iana` ;
- genre non nul vérifié ;
- compte `active` sous la garde d'activation étendue (4.3) ;
- candidature `confirmee` ; profil enseignant unique.

L'affectation exige une pièce approuvée, la langue de la classe dans
`teacher_profiles.languages` et un genre connu (`M/0082_teachers_for_class.sql:54-66`).
Une fiche vide, comme celle que crée l'inscription aujourd'hui
(`M/20261017150200_af_l1_11_inscription_enseignant_sur_invitation.sql:110-178`),
n'est affectable à aucune classe dont la langue est renseignée. Les langues ne se
recopient en codes qu'après le lot `langue` (section 13).

Le pays de résidence n'est pas recopié dans `teacher_profiles.country`.
L'affectation ne le lit pas ; cette colonne est publique sur la carte de
l'enseignant (`C/ENS-PAYS-1_BR.md:3`) et porte un nom, pas un code (`:9`).
L'enseignant le pose dans son profil avec les prérequis de travail
(`M/20261016100500_contrats_travail_prerequis.sql:70`) ; question en 0.3.

Le refus d'une nouvelle pièce d'une enseignante déjà active **ne change pas** :
`disabled` sans autre pièce approuvée
(`M/20261017100500_af_l1_05_decider_dossier_une_seule_fois.sql:51-60`, `DEC:24`) ;
la candidature trace une restriction « pièce », levée par la transition 21.

---

## 3. Entrées

### 3.1 Le lien public (`CAND-Q03`, `CAND-Q17`)

Un lien partageable, sur la page « recrutement » du site public, ouvre le
parcours d'inscription existant, étendu d'une entrée sans code (`CAND-04`). C'est
l'entrée ordinaire après l'import ; plus d'imports périodiques (`DEC:26`, `:40`).
Il rouvre une entrée publique fermée depuis le 17/10
(`C/DECISION-ENTREE-2026-10-17.md`) : les six conditions de `DEC:49-66` deviennent
des règles.

| # | Condition (`DEC`) | Règle | Lot |
| :-- | :--- | :--- | :--- |
| 1 | Compte candidat seulement (`:50-51`) | l'inscription crée un compte candidat confiné à `/attente` et une candidature `prequalification/a_completer` de type `enseignant`. **Forme en base, fixée par CAND-L1B le 21/10** : rôle `teacher`, `account_status` `pending_kyc`, fiche `teacher_profiles` vide, sans foyer, la même pour le lien public et l'invitation. Une seule fabrique : `private.creer_profil_inscription_interne('teacher', ...)` (`M/20261017150200_af_l1_11_inscription_enseignant_sur_invitation.sql:61-64`, `:80`), appelée par `inscrire_enseignant_invite` (`:169`) et, en L3, par le lien public. Pourquoi ce rôle et ce statut : le confinement repose déjà sur `app_account_valid()` (`M/0001_fondations.sql:412-422`), et les portes que le candidat doit franchir sont déjà ouvertes au rôle `teacher` en attente (pièce, `M/0004_inscription_kyc_appairage.sql:169-174` puis `M/20261017120100_af_l1_08_reprise_gardes_vues.sql:168` ; contrat et avis, `M/20261017100800_af_l1_08_policies_compte_valide.sql:234` ; code de conduite, `M/20261021210400_pe_code_conduite_avant_activation.sql:54-70` ; garde `0089` à l'activation) ; un rôle ou un statut neuf les rouvrirait toutes. **Lien en base** : le type porte le rôle du compte (`candidature_types.role_compte`, `M/20261021220000_cand_l1b_forme_compte_candidat.sql:147-149`) ; deux déclencheurs de contrainte, côté candidature et côté compte (`:199-309`, différables pour la transaction d'entrée en salle 3 de L2), refusent : un compte d'un autre rôle tant que la candidature est en cours avant `confirmee` ; un compte du rôle du type `active` ou `provisional_active` avant `confirmee`, quelle que soit l'issue ; un engagement d'enseignant en cours avant `confirmee` (classe non close, séance de cours à venir ou en cours, affectation ouverte, remplacement d'une telle séance, `:161-186`), un historique n'empêchant pas une ancienne enseignante de candidater. La règle ne tient plus après la salle 3 : une enseignante confirmée, ou une personne dont la candidature est refusée ou retirée, change de rôle comme tout compte (`C/DECISION-IMMATRICULATION-2026-10-12.md:23`) ; rouvrir la candidature rejoue la règle du rôle. Les deux côtés se sérialisent sur la ligne du compte (verrou `FOR NO KEY UPDATE` côté candidature, `FOR SHARE` côté affectation) : deux transactions qui se croisent ne valident pas un compte candidat actif ou enseignant. Une seule candidature par type et par compte (`M/20261021200000_cand_l1_socle_candidatures.sql:185`). **Refusé** : jeton de cours (`M/20261017110100_af_l2_01_jeton_enseignant_effectif_et_retrait.sql:44-52`) ; affectation par toute RPC (`M/20261021210200_creer_groupe_predicat_affectation.sql:105` et `:338`, `c11bis`, `attribuer_eleve`, `prendre_eleve`, remplacements) et par écriture directe, à la création comme à la modification (classe, séance de cours, affectation, remplacement, `M/20261021220000_cand_l1b_forme_compte_candidat.sql:319-373`) ; prérequis de travail (`prerequis_enseignant`, disponibilités, photo, et `maj_profil_enseignant`, ouverte au compte en attente jusqu'à CAND-L1B, `:533-572`) ; présence dans une liste d'enseignants (`enseignants_pour`, `enseignants_pour_classe`, `enseignants_pour_public`, tirage du contrôle, pilotage, personnes observables, remplacements, carte et recherche de la famille) ; activation avant la salle 3, `decider_dossier()` compris (refus brut `compte_candidat_actif_avant_salle_3`, que L2 précède de ses contrôles nommés). **Cloisonnement par genre** (`DEC:30`, 8.2) : la direction de l'autre côté, ou au genre inconnu, ne lit pas un compte qui porte une candidature avant la salle 3, ni dans `comptes_admin()` (`ADM-08`, registre des comptes), ni dans `dossiers_en_attente()` (`ADM-02`, file des dossiers), ni dans le compteur d'`indicateurs_admin()` (`ADM-01`), ni dans la table `profiles` (policy restrictive `profiles_compte_candidat_portee`, agent compris, `:385-429`) ; son écriture sur ce profil touche 0 ligne, sans message qui révèle la candidature ; le super-admin lit les deux côtés (exception de `0088`). La file d'`ADM-02` ne montre un compte candidat qu'en Salle de vérification et d'entretien en cours ou après (`:681-750`) : la salle d'examen se suit dans `ADM-20` et `ADM-21` (2.2). Les surfaces encore non bornées sont en 0.3. **Permis** : contrat, avis et code de conduite ; dépôt de pièce par la policy et par le coffre R2 (porte `peut_deposer_piece_identite` alignée sur la policy, `:582-612`), seulement en Salle de vérification et d'entretien (candidature en cours) ou après, par toute voie (déclencheur `kyc_documents_depot_etape`, `:439-474`, selon 2.1), jamais avec une décision (`:482-508`) ; `etat_dossier()`. Le fil `candidature` vient en L5 ; l'étape où chaque accord s'ouvre, en L2 (4.3). Preuve : `supabase/tests/scenarios_cand_l1b_forme_compte.sql`, 132 contrôles verts sur base neuve, 54 rouges sans la migration ; `supabase/tests/scenarios_cand_l1b_concurrence.sql` (deux sessions, quatre croisements dans les deux ordres), 9 contrôles verts, 9 rouges sans la migration ou sans les verrous (`testé localement`) | L1 (forme : CAND-L1B, `testé localement`), L3 |
| 2 | Contre les robots (`:52-53`) | la candidature n'existe qu'après confirmation du courriel (aujourd'hui `enable_confirmations = false`, `supabase/config.toml:229`) ; plafond d'inscriptions par heure dans `app_config`, refus neutre au-delà : la réponse est la même qu'en cas de succès (`CAND-04`) ; la limite par adresse IP reste (`sign_in_sign_ups = 30` par 5 minutes, `config.toml:210`) ; captcha possible (`config.toml:216-219`) | L3 |
| 3 | Courriel obligatoire (`:54-56`) | l'app se connecte par courriel (`lib/core/auth/service_auth.dart:52-56`) : pas de courriel, pas d'inscription ; le message WhatsApp aux personnes sans courriel leur dit d'en créer un | L3 |
| 4 | Personnes des formulaires (`:57-62`) | reconnues et pré-remplies (3.4) ; aucune candidature créée à leur place ; tout le monde complète pays, paiement et cadre religieux | L3 |
| 5 | Confidentialité (`:63-64`) | accord de confidentialité versionné, accepté à l'inscription, enregistré avec version et date | L3 |
| 6 | Mise en ligne (`:65-66`) | une clé `app_config` (nom fixé en L3), fausse par défaut : tant qu'elle est fausse, l'inscription sans code est refusée en base. Le lien ne va sur le site, et la clé ne passe à vrai, qu'une fois L1 à L3 livrés, le SMTP d'authentification en production avec `enable_confirmations = true` (7.3, dépendance 1), et le feu vert du directeur | L3 (clé) |

### 3.2 L'import ponctuel des formulaires Google

**Ponctuel** (`DEC:40`) : pour les seules personnes des formulaires, jamais
périodique. Un fichier corrigé se rejoue ; l'import reste idempotent et la
correction s'inscrit sur la même référence source (`REVUE §7` point 6,
`PORTS §2`, `SPEC §8.3`). Même motif serveur que l'import du 12/10 : analyse au
serveur, essai à blanc, confirmation idempotente, aal2 exigée **en base**, journal
portant la référence source (classeur, onglet, horodatage), jamais le nom
(`REVUE §7`).

**Réservé au super-admin.** Le fichier A mêle les deux côtés (351 hommes et
89 femmes, `REVUE §2.3`) ; l'aperçu, les doublons et le rapport ligne par ligne
montrent noms et réponses. Une directrice qui importerait lirait les lignes des
hommes, contre la portée de 8.2. Le super-admin lit déjà les deux côtés
(`DEC:30`).

| Source | Traitement |
| :--- | :--- |
| A1 et A2 (questionnaire arabe, 14 colonnes) | importées : 440 lignes, 409 personnes après rapprochement des doublons de A (`MAP §6`) |
| B (« Enseignants (Réponses) », 11 lignes) | `dejaConnue`, rien n'est écrit : déjà dans l'import du 12/10 (`MAP §1`) ; reconnue à l'inscription par 3.4 |
| Liens Drive vers des photos d'identité | jamais importés |

**Ce que l'import écrit** : des **réponses importées**, une par référence source,
qui servent à reconnaître et à pré-remplir (3.4). Ni compte, ni invitation, ni
pièce, ni accord, ni candidature à la place de la personne (`DEC:60`).
**Choix de mise en oeuvre, à confirmer par le directeur** : pour porter
l'invitation (`DEC:27`) ou consigner l'envoi du lien par WhatsApp (`DEC:26`), la
direction peut garder une ligne `recue` (transition 2). C'est une ligne de suivi,
pas une candidature déposée : elle n'entre en salle d'examen que quand la personne
s'inscrit et y est rattachée (0.2 bis, 0.3).

**Les huit pas d'`ADM-23`** (`SPEC §9`, `REVUE §7`) : (1) dépôt d'un export CSV,
sans connexion à l'API Google ; (2) aperçu, contacts masqués ; (3) association des
colonnes sur en-têtes normalisés, avec la table des libellés (`MAP §2`, `§3`) ;
(4) doublons probables et lignes incomplètes ; (5) erreurs et avertissements ligne
par ligne ; (6) quatre compteurs (nouvelles, déjà connues, ignorées, à corriger),
un écart avec les comptes de référence se lit avant de confirmer ;
(7) confirmation idempotente ; (8) rapport final ligne par ligne, sans nom.

| Donnée (`MAP §4`, `§5`) | Règle |
| :--- | :--- |
| Doublon | clé courriel **ou** téléphone normalisés, jamais le nom ; la ligne la plus récente est proposée, les autres restent en historique (`DEC:39`) ; le super-admin choisit par groupe, un groupe sans choix reste « à corriger » |
| Téléphone, courriel | téléphone jamais complété ni deviné, sinon « indicatif à confirmer » ; courriel absent ou mal formé : « courriel à obtenir », ni clé ni adresse d'invitation |
| Créneaux (colonne J) | **aucun pré-remplissage** de `disponibilitesDeclarees` : les formulaires donnent des tranches horaires sans jour, et le champ est une grille de plages par jour (2.1 bis). Le libellé d'origine (heure de La Mecque, `Asia/Riyadh`) est gardé tel quel dans la réponse importée, jamais converti en heure absolue, jamais recopié dans `weekly_availability` (`C/02_ARCHITECTURE_ET_SECURITE.md:23`, `MAP §3.5`) |
| Réponses contradictoires (24 lignes) | importées telles quelles, avec avertissement |
| Ligne « à corriger » | corrigée dans le classeur, puis fichier rejoué : 0 réponse nouvelle, la correction tracée sur la même référence source |

### 3.3 L'invitation, une étape (`CAND-Q04`)

L'onglet Invitations de Personnes devient « Candidatures » (`ADM-20`) : pas de
septième onglet, une seule liste par personne (`DEC:27`,
`lib/core/admin/admin_domaine.dart:266-293`).

| Cas | Règle |
| :--- | :--- |
| Ligne `recue` au courriel valide | le serveur émet l'invitation existante (`inviter_enseignant`, code lié au courriel, 14 jours, `M/20261016100300_contrats_invitations_enseignant.sql:111-161`) et écrit un courriel à envoyer (modèle `invitation`, 7.3). Le code est un paramètre de ce seul modèle, lu par la seule fonction d'envoi. Le lien mène au parcours d'inscription existant et peut porter le code, comme aujourd'hui (`lib/core/router/app_router.dart:323-326`) |
| Tant que l'envoi n'existe pas | **aucune invitation n'est émise en production**, sauf canal nommé par le directeur pour l'intervalle (0.3). Dans ce cas seulement, la direction voit le code comme aujourd'hui (`lib/features/admin_invitations/invitations_page.dart:128-129`), et l'écran dit « Courriel pas encore envoyé » |
| Sans courriel valide | `courrielAbsent` ; la direction envoie le lien public par WhatsApp, hors de l'app, et le consigne (7.4, transition 26) |
| Expiration à 14 jours | retour en `recue`, trace gardée, réinvitation possible |
| Invitation consommée ou lien public | **même compte et même candidature** ; seule la provenance diffère |
| Reprise (L3) | invitations déjà émises : lignes `invitee` ; comptes `pending_kyc` nés d'une invitation : candidature en `prequalification/a_completer`, accords signés et pièce déposée gardés |

Le modèle `lien_inscription` ne part jamais par courriel : c'est le modèle du
message WhatsApp consigné (7.4). Une personne des formulaires qui a un courriel
valide reçoit une invitation.

### 3.4 Reconnaissance et pré-remplissage

| Correspondance | Effet |
| :--- | :--- |
| même courriel qu'une réponse importée, **confirmé** à l'inscription | rattachement automatique ; pré-remplissage du questionnaire, à relire ; une ligne `recue` éventuelle devient cette candidature |
| même téléphone qu'une réponse importée, seulement (téléphone donné à l'inscription, 2.1) | rien n'est montré à la personne ; rattachement **proposé à la direction**, appliqué par un geste journalisé (transition 27), puis pré-remplissage |
| personne de B (déjà dans l'import du 12/10) | courriel confirmé égal à `private.preinscription_households.email_normalise` d'une personne `teacher` (`PORTS §2`), sur le modèle de `reclamer_preinscription_apres_preuve()` (`M/20261012185327_imm_accueil_reclamation_apres_preuve_email.sql`) : reconnue et rattachée, sans pré-remplissage (l'import du 12/10 ne garde que prénom, nom et courriel, `REVUE §3.5`) |
| nom seul | jamais |

Le téléphone ne suffit pas : aucun canal ne le vérifie (SMS désactivé,
`REVUE §3.6`). Montrer d'anciennes réponses sur un numéro tapé exposerait les
données d'une autre personne. C'est un écart à `DEC:58-59`, porté en 0.2 bis.

La personne de B sans courriel (`REVUE §2.4`) n'a ni réponse importée ni ligne :
l'envoi du lien par WhatsApp n'a pas où se consigner (0.3).

Pré-remplis : colonnes C, E à I, K et L de A (`MAP §2`). La colonne J (créneaux) ne
pré-remplit rien : aucun jour (2.1 bis). Jamais pré-remplis : disponibilités, pays,
fuseau, publics, paiement, cadre religieux, riwaya, niveau de lecture et de
tajwid.

**Le genre.** Le genre déclaré à l'inscription est écrit dans `profiles.gender` à
la création du profil, par le même chemin qu'aujourd'hui
(`M/20261017150200_af_l1_11_inscription_enseignant_sur_invitation.sql:169`).
Ensuite seule la direction le change (`af_l1_07`,
`M/20261017100700_af_l1_07_genre_colonne_privilegiee.sql:27`, déclencheur
`before update`, `M/0001_fondations.sql:558-560`). Pour la porte candidat, il est
obligatoire en base : sans lui, l'inscription est refusée, sinon le dépôt de
pièce échoue (`M/0004_inscription_kyc_appairage.sql:145-147`). Aujourd'hui
`p_gender` vaut `NULL` par défaut (`af_l1_11:134`). Le genre fixe la portée de
lecture dès la première ligne.

---

## 4. États, transitions et règles de blocage

### 4.1 Dimensions

| Dimension | Valeurs | Porté par |
| :--- | :--- | :--- |
| Étape | `recue`, `invitee`, `prequalification`, `verifications`, `confirmee` | candidature |
| État dans l'étape | salle 1 : `a_completer`, `en_examen`, `paiement_non_disponible` ; salle 2 : `entretien_a_planifier`, `entretien_planifie`, `decision_en_attente` | candidature |
| Issue | `en_cours`, `refusee`, `retiree` (terminales, réouvrables par geste motivé) | candidature |
| Pause | drapeau, motif interne, modèle de message, reprise facultative | candidature |
| Restriction | drapeau, cause (`piece`, `paiement`, `manuelle`), motif ; après la salle 3 | candidature |
| Indisponibilité | drapeau, « jusqu'au » facultatif ; après la salle 3 | candidature |
| Provenance | `lien_public`, `invitation`, `import` | candidature |
| Responsable | membre de la direction, du même côté, facultatif, changé par geste journalisé (transition 28) | candidature |
| Pièce | lue dans `kyc_documents`, jamais recopiée ; deux issues de refus : `a_corriger`, refus définitif (`DEC:41`) | existant, étendu |
| Paiement | `inconnu`, `a_verifier`, `compatible`, `incompatible`, calculé (5.1) | réponses et référentiel |
| Entretien | état (6.2) ; issue `tenu`, `annule`, `manque_candidat`, `manque_intervieweur` | entretien |
| Affectation | lue dans les classes (`groupes.teacher_id`), jamais recopiée ; « déjà affectée » reste distinct de « confirmée », « active » et « disponible » (`SPEC §2.3`) | existant |
| Courriel | `a_envoyer`, `envoye`, `echec` | file des courriels |
| Coordonnées financières | `absentes`, `enregistrees` ; jamais exigées avant le premier versement | `CPT-13` |

Une pièce n'expire pas tant qu'aucune date de validité n'est saisie (`DEC:41`).
`purge_at` vaut dépôt plus `kyc_retention_days` (90 jours,
`M/0004_inscription_kyc_appairage.sql:117`, `:136-139`) ; aucune purge n'est
programmée aujourd'hui. Quand elle le sera, elle efface le fichier et garde la
décision (`status`), que lit `piece_validee`. Sinon, une pièce déposée tôt en
salle 2 atteindrait `purge_at` avant la fin de l'entretien, et chaque enseignant
passerait en restriction. Le point de départ de la durée (dépôt ou décision) est
en 0.3.

### 4.2 Transitions

Chaque transition passe par une RPC qui vérifie la règle en base, exige le motif
quand la colonne le dit, prend `versionAttendue` et `cleIdempotence`, rend
`TransitionInterdite` depuis un état qui ne le permet pas, et journalise ancien
état, nouvel état, auteur, horodatage et motif. « Direction » veut dire la
capacité `candidatures.decider`, dans la portée de genre (section 8). Les
numéros 1 à 22 ne changent pas ; les lignes 23 à 28 sont ajoutées à la révision.

| # | De | Vers | Qui | Vérifié en base | Motif |
| :-- | :--- | :--- | :--- | :--- | :--- |
| 1 | import confirmé | réponses importées | super-admin (`candidatures.importer`) | aal2 ; référence source unique ; rien d'autre n'est écrit | non |
| 2 | réponses importées | `recue` | direction (« garder pour suivi », choix à confirmer, 0.2 bis) | une ligne par référence ; aucun compte | non |
| 3 | `recue` | `invitee` | direction, ligne ou lot | courriel valide ; aucun compte existant ; `inviter_enseignant` ; un courriel `a_envoyer` (modèle `invitation`, code en paramètre) ; en production, fermé tant que l'envoi manque (3.3) | non |
| 4 | `invitee` expirée | `recue` | automatique | la trace de l'invitation reste | non |
| 5 | rien, `recue` ou `invitee` | `prequalification/a_completer` | la personne, en s'inscrivant | courriel confirmé ; accord de confidentialité à la version courante ; genre non nul ; téléphone avec indicatif ; plafond horaire ; sans code : clé de mise en ligne vraie (3.1) ; aucune autre candidature en cours du même type pour ce compte ; rattachement selon 3.4 | non |
| 6 | `a_completer` | `en_examen` | le candidat (envoi) | questionnaire complet à la version courante ; accord de rémunération ; cadre religieux à la version requise | non |
| 7 | `en_examen` | `a_completer` | direction | éléments manquants nommés au candidat | **oui** |
| 8 | `en_examen` | `paiement_non_disponible` | automatique | aucun moyen déclaré ne croise une ligne `confirme` du pays de versement ; ou moyen infirmé par la direction (25) ; ou ligne qui quitte `confirme` (5.1) ; cause tracée | non |
| 9 | `paiement_non_disponible` | `a_completer` | automatique | une ligne du pays passe `confirme` ; « moyen de paiement à déclarer » nommé ; notification et courriel | non |
| 10 | `en_examen` | `verifications/entretien_a_planifier` | direction (« admettre en Salle de vérification et d'entretien ») | `paiement_compatible` vrai ; cadre religieux à la version requise ; questionnaire complet | non |
| 11 | `entretien_a_planifier` | `entretien_planifie` | direction | début UTC futur, durée ; intervieweur de la direction, du même côté que le candidat, super-admin compris (0.3) ; fuseau du candidat connu ; séance `entretien` créée ; notification et courriel | non |
| 12 | `entretien_planifie` | `entretien_a_planifier` | direction | issue `annule`, `manque_candidat` ou `manque_intervieweur` gardée ; séance annulée | **oui** |
| 13 | `entretien_planifie` | `decision_en_attente` | l'intervieweur désigné | issue `tenu` ; compte rendu ; constat (niveau observé, riwaya, ijaza présentée) ; avis | non |
| 14 | `decision_en_attente` | `confirmee` | direction, en **validant la pièce** dans `ADM-02` | les sept autres contrôles vrais (section 5), sinon `ControlesNonSatisfaits` nommés et rien n'est écrit ; validation, activation sous la garde et entrée en salle 3 en une transaction (2.2). La règle ne vaut que pour un profil porteur d'une candidature `enseignant` ; les autres profils, tuteur compris, gardent l'approbation actuelle (`af_l1_05:47-50`) | non |
| 15 | `verifications`, tout état | même état, pièce `a_corriger` | direction (`ADM-02`) | ce qui est à corriger dit par modèle ; le candidat redépose | **oui** |
| 16 | toute étape en cours | `refusee` | direction | motif interne et modèle de message ; le refus définitif de pièce (pièce fausse, identité discordante) y mène ; entretien planifié annulé | **oui** |
| 17 | toute étape en cours | `retiree` | le candidat (`CAND-03`) ; ou la direction, pour une demande reçue par la conversation ou par courriel | entretien planifié annulé, son issue reste ; canal et date tracés | **oui** si direction |
| 18 | tout état | pause posée ou levée | direction | l'étape ne change pas ; modèle de message à la pose | **oui** à la pose |
| 19 | `refusee`, `retiree` | étape et état d'origine | direction (« rouvrir ») | contrôles de l'étape revérifiés, sinon `ControlesNonSatisfaits` ; questionnaire à la version courante | **oui** |
| 20 | `confirmee` | `confirmee` + restriction | direction, ou automatique quand un contrôle tombe (ligne du référentiel, nouvelle pièce refusée) | sort de l'affectabilité : le prédicat d'affectation la lit (4.3) ; étape et historique gardés | **oui** |
| 21 | `confirmee` + restriction | `confirmee` | direction | contrôles revérifiés. Lever une restriction `piece` exige une nouvelle pièce `approved` et remet le compte de `disabled` à `active` sous la garde étendue, dans la même transaction | **oui** |
| 22 | `confirmee` | indisponibilité notée ou levée | direction | étape inchangée ; le prédicat d'affectation la refuse (4.3) ; comptée à part | non |
| 23 | `verifications`, tout état | même état, complément demandé | direction (`demanderComplement`) | éléments manquants nommés au candidat ; la candidature compte dans « informations manquantes » | **oui** |
| 24 | `en_examen`, paiement `a_verifier` ; ou `confirmee` en restriction de cause `paiement`, paiement `a_verifier` (proposé en L6, 0.2 bis) | paiement `compatible` | direction (`confirmerMoyenPaiement`) | méthode et opérateur déclarés croisent une ligne `confirme` du pays de versement ; une ligne `en_verification` ne se confirme jamais | non |
| 25 | `en_examen`, paiement `a_verifier` ou `compatible` | paiement `incompatible` | direction (`infirmerMoyenPaiement`) | moyen nommé ; la transition 8 suit | **oui** |
| 26 | `recue` sans courriel valide | même étape, lien envoyé consigné | direction (`consignerPrevenu`), ligne ou lot | canal `whatsapp`, modèle `lien_inscription`, date ; jamais un texte libre (7.4) | non |
| 27 | `prequalification/a_completer` et réponses importées proposées | réponses rattachées | direction (`rattacher`) | proposition existante (même téléphone normalisé, 3.4) ; réponses rattachées à aucune autre candidature ; pré-remplissage ensuite | non |
| 28 | toute étape en cours | responsable posé ou retiré | direction (`definirResponsable`) | membre de la direction, du même côté que le candidat | non |

Une sortie décidée par la direction sans demande du candidat est un **refus
motivé**, jamais un retrait. Le candidat ne voit jamais le motif interne, seulement
le texte du modèle (`PORTS §5` point 4). **Gestes groupables** (`ADM-22`) :
inviter, mettre en pause, lever la pause, refuser, consigner le lien envoyé par
WhatsApp. Tout autre geste rend `GesteNonGroupable`.

**Le moteur, posé par L2A1 le 22/10, repris après relecture le même jour**
(`présent dans le code`, `testé localement`). Chaque RPC de geste passe par trois
aides privées, dans cet ordre (`M/20261022000000_cand_l2a1_moteur_salle_examen.sql:1484-1759`) :
- `private.candidature_geste_ouvrir` vérifie tout avant d'écrire : arguments
  (22023), auteur égal à la session et, pour la direction, active et de genre
  connu (42501), candidature absente, portée par genre, rejeu de la clé, version
  attendue, puis la règle du geste (étape, état, issue, pause, condition), le
  motif et le modèle exigés. Un motif est normalisé d'abord : les blancs de tête
  et de queue (espace, tabulation, fin de ligne, espaces Unicode) sont retirés,
  et un motif fait de blancs vaut absent (L2-10, `M/20261022000000_cand_l2a1_moteur_salle_examen.sql:1370-1380`). Les refus sont
  **rendus** sans écriture : `absente`, `hors_portee`,
  `cle_idempotence_reutilisee`, `conflit_candidature` (`ConflitCandidature`,
  version courante rendue), `transition_interdite` (étape, état, issue et pause
  nommés, raison `pause` ou `etat`), `motif_requis`, `modele_requis`. Seule une
  tentative hors portée écrit, sa trace, comme une lecture hors portée de L1
  (`private.cand_hors_portee`) ;
- `private.candidature_geste_appliquer` écrit le nouvel état, la version, la
  dernière activité, une ligne `candidature_evenements` (étape, état et issue
  avant et après, auteur et sa catégorie, instant, motif interne gardé au
  serveur, changements de l'appelant avant et après) et une ligne `audit_logs`
  sans motif, lue du seul côté de la candidature (8.2). Chaque règle nomme les
  colonnes que l'appelant peut poser : la date de reprise pour la pause, le
  « jusqu'au » pour l'indisponibilité, le responsable pour la transition 28, le
  pays de résidence et le fuseau pour l'envoi ; tout autre changement est refusé
  (22023). Un responsable posé est un membre actif de la direction du même côté
  que la candidature, sinon 42501 (`M/20261022000000_cand_l2a1_moteur_salle_examen.sql:1600-1733`) ;
- `private.candidature_geste_conclure` garde le premier résultat sous la clé :
  la même clé rejouée le rend (`rejoue` vrai) sans aucune écriture, même à
  l'ancienne version ; une clé reprise pour un autre geste, une autre
  candidature ou un autre auteur est refusée ; seules les réussites sont gardées
  (table `candidature_gestes`, en ajout seul, `M/20261022000000_cand_l2a1_moteur_salle_examen.sql:766-777`). Aucun résultat
  gardé ne porte une réponse du candidat.

Le brouillon du questionnaire n'est pas une transition : il ne change jamais la
version de la candidature, si bien qu'un enregistrement entre la lecture de la
direction et son geste ne refuse pas ce geste ; sa version attendue est celle du
brouillon (0.2 bis, 10). Il ne garde que sa dernière clé, une ligne par
candidature (`candidature_brouillon_cles`, `M/20261022000000_cand_l2a1_moteur_salle_examen.sql:785-795`) : une clé de brouillon
plus ancienne rejouée est une clé neuve, refusée par la version du brouillon
(`conflit_brouillon`), sans écriture.

La source de chaque geste vit dans une table privée, écrite par migration
(`private.candidature_gestes_regles`, `M/20261022000000_cand_l2a1_moteur_salle_examen.sql:662-758`) : toutes les lignes de 4.2 à
geste (3, 6, 7, 10 à 28), plus le brouillon du questionnaire. Les gestes des
entrées (L3), des entretiens (L4) et de la salle 3 (L2B) n'ont pas encore de RPC :
leurs lignes servent déjà au moteur, et chaque lot y ajoute ses prédicats propres
dans sa RPC. Un geste de la direction ne vaut que de son côté (8.1,
`candidatures.decider`) : l'exception du super-admin reste une exception de
lecture, et un geste de l'autre côté, super-admin compris, est rendu
`hors_portee` et tracé. Le retrait (17) vaut de toute étape en cours avant la
salle 3, pause comprise ; il n'existe pas en salle 3, dont les sorties sont la
restriction et l'indisponibilité (2.2).

**Les gestes de la direction, posés par L2A2 le 22/10, repris après relecture le
même jour** (`présent dans le code`, `testé localement`). Une RPC par geste, chacune par les trois aides du moteur, du
côté de la direction seulement (`M/20261022000100_cand_l2a2_gestes_direction.sql`) :
`demander_complement_candidat` (7 et 23, `:837-910`),
`admettre_salle_verification` (10, `:915-955`), `refuser_candidat` (16,
`:959-979`), `mettre_en_pause_candidat` et `lever_pause_candidat` (18,
`:983-1026`), `consigner_retrait_candidat` (17 par la direction, `:1031-1080`),
`rouvrir_candidat` (19, `:1085-1128`), `definir_responsable_candidat` (28,
`:1132-1174`), `confirmer_moyen_paiement_candidat` et
`infirmer_moyen_paiement_candidat` (24 et 25, `:1180-1306`). Aucun nom ne contient
« candidature » : `etat_dossier()` reste la seule lecture de l'état du candidat.
- Après les refus du moteur viennent ceux du geste, rendus sans écriture :
  `elements_requis`, `elements_invalides` (avec la liste permise),
  `controles_non_satisfaits` (`ControlesNonSatisfaits` : chaque contrôle faux
  nommé avec sa cause), `aucun_complement` (clôture sans complément en cours),
  `modele_inconnu`, `date_reprise_invalide`,
  `date_demande_invalide`, `responsable_invalide`, `moyen_non_confirmable` (cause
  `non_declare` ou `ligne_non_confirmee`, avec l'état de la ligne),
  `moyen_non_declare`. Un argument mal formé (canal hors liste, moyen incohérent,
  élément nul) lève 22023 avant le moteur.
- Chaque geste rend l'état relu après l'écriture (étape, état, issue, pause et
  son modèle, refus et son modèle, restriction et sa cause, indisponibilité,
  paiement, responsable, version, `:300-327`), gardé sous la clé ; jamais une
  réponse, un motif ni un nom. Le dossier complet se relit par
  `lire_candidature`, qui rend aussi, depuis la relecture, `pauseModele`,
  `refusModele` et `restrictionCause` : l'écran relit le même état que celui que
  le geste vient de rendre.
- Le complément (7, 23) écrit ses éléments dans l'événement (`aCompleter`), que
  lit `complementDemande` d'`etat_dossier()` ; en salle 2, la candidature compte
  dans les informations manquantes de `lister_candidatures` tant que le
  complément court, selon la même règle (`:364-393`, `:1850-1855`). **Rien ne ferme
  un complément de salle 2 tout seul** : la direction le clôture par la
  transition 23 avec le seul code `complement_clos` (même état, événement à
  liste vide, aucun marqueur `aNotifier` ; `aucun_complement` s'il n'y en a pas),
  et `complementDemande`, comme le compteur, retombent à `[]` (0.2 bis). L'admission
  (10) vérifie `paiement_compatible`, le cadre religieux à la version requise et le
  dernier questionnaire envoyé, complet à la version courante (`:398-504`). Le
  retrait par la direction (17) trace le canal (`conversation` ou `courriel`) et
  la date de la demande, ni future ni antérieure à la réception de la
  candidature. La pause (18) prend une reprise facultative, postérieure au jour
  UTC courant ; sa levée n'exige ni motif ni modèle. Le responsable (28) est un
  membre actif de la direction du même côté, ou aucun.
- Les gestes 24 et 25 s'appliquent avant la décision, que la règle du moteur lit
  en direct, puis écrivent `candidature_paiement_decisions` et appellent
  `private.paiement_recalculer` (`:1233-1240`, `:1294-1301`) : une infirmation qui
  ne laisse aucun moyen mène à la transition 8, motif tracé ; une ligne
  `en_verification` ne se confirme jamais ; en salle 3 sous restriction de cause
  `paiement`, la confirmation rend le paiement compatible et la restriction reste,
  levée par la transition 21 (L2B). Après une réouverture (19), le paiement est
  recalculé (cause `reouverture`) : la transition 8 (en examen) ou la transition
  9 (`paiement_non_disponible` dont le paiement n'est plus incompatible : une
  ligne est passée `confirme` pendant le refus ou le retrait, que le
  déclencheur de L6 ne voit pas, car il ne recalcule que les candidatures en
  cours) peut suivre ; la transition 9 nomme la carte `versement`.
- Chaque événement porte le marqueur `aNotifier`, le code du modèle de la file
  (`complement_demande`, `admis_salle_verification`, `refus`,
  `retrait_enregistre`, `pause_posee`, `pause_levee`,
  `C/CANDIDATURES/CONTRAT_FILE_COURRIELS.md:63-82`), que L5 lira ; rien pour 19
  et 25 (écart 6 de ce contrat), ni pour 24 et 28, absents de la liste de 7.2. Les listes fermées (modèles, éléments), la fin
  d'un complément, la lecture stricte de la réouverture et son état d'origine
  après un entretien annulé sont à soumettre (0.2 bis).

**L'action groupée (`ADM-22`), posée par L2A2 le 22/10, reprise après relecture le
même jour** (`testé localement`). `apercu_lot_candidats(geste, ids)` (`:1318-1374`)
rend les éligibles (référence, nom, étape, état, version), les exclus avec leur
raison (`absente` ; `hors_portee`, sans aucune donnée ; `transition_interdite`,
avec `pause` ou `etat`), l'effet, le nombre et un jeton : une empreinte
HMAC-SHA256 de l'auteur, du geste, des éligibles avec leur version et des exclus,
sous une clé secrète du serveur (`private.candidature_lot_secret`, engendrée par
la migration, jamais dans le dépôt, jamais rendue). Un client ne peut donc pas
calculer un jeton : il ne l'obtient que de l'aperçu. Comme une lecture de liste,
l'aperçu écrit une ligne `audit_logs` (`candidatures_apercu_lot` : côté du
lecteur, geste, nombres, jamais un nom ni un identifiant, 8.2). Le geste s'écrit
avec le code du moteur (`mettre_en_pause`, `lever_pause`, `refuser`) ou celui de
`gestesGroupables` (`mettreEnPause`, `leverPause`, `refuser`) ; le rapport rend
le code du moteur.
- **Traces.** Chaque identifiant de l'autre côté laisse sa trace (événement
  `lecture_hors_portee` et ligne d'audit, comme une lecture hors portée de L1) dès
  l'entrée dans l'aperçu ou l'exécution, **avant** tout refus rendu : geste non
  groupable, motif, modèle, date, clé reprise, jeton, nombre. Seuls les refus
  levés (22023), qui ne portent que sur la forme des arguments, la précèdent.
  Aucune réponse ne dit si un identifiant existe de l'autre côté sans l'avoir
  tracé : un jeton qui n'est pas celui de l'aperçu rend `jeton_perime`, que
  l'identifiant soit de l'autre côté, inconnu ou du côté du lecteur.
- **Rejeu.** La même clé rejouée retrace ces identifiants (chaque appel est une
  tentative, comme pour un geste seul) et rend `hors_portee` si un identifiant du
  rapport gardé est désormais de l'autre côté (le moteur vérifie la portée avant le
  rejeu) ; sinon le premier rapport, sans écriture.
`executer_lot_candidats(geste, ids, jeton, nombre, clé, motif?, modèle?, reprise?)`
(`:1381-1544`) n'écrit rien quand le jeton diffère (`jeton_perime` : le lot a
changé depuis l'aperçu, ou l'aperçu est d'un autre auteur), quand le nombre saisi
diffère (`nombre_discordant`), sans éligible (`aucun_eligible`), ou quand le motif
ou le modèle manquent ou sortent de la liste ; puis chaque ligne passe seule par
le moteur, sous une clé dérivée de celle du lot, dans un sous-bloc : un refus ou
une erreur n'annule jamais une réussite voisine, et chaque ligne est `reussie`,
`exclue` (inchangée) ou `refusee`, avec sa raison. Le rapport, sans nom, se garde
sous la clé du lot (`public.candidature_lots`, en ajout seul, `:256-268`) : la
même clé le rend sans écriture ; reprise pour d'autres identifiants ou par un
autre auteur, elle est refusée. Groupables dans ce lot : mettre en pause, lever
la pause, refuser ; `inviter` et `consigner_prevenu` (L3), comme tout autre
geste, rendent `geste_non_groupable`. L'issue `inconnue` de `PORTS §1` reste un
état de l'écran, quand la réponse du serveur ne lui parvient pas : le serveur
connaît l'issue de chaque ligne. Au plus 200 candidatures par lot.

### 4.3 Règles de blocage

**Refusés en base :**
- entrer en salle 2 sans `paiement_compatible` ou sans cadre religieux ;
- entrer en salle 3 avec un contrôle faux. La garde
  `guard_teacher_activation_signatures()`
  (`M/0089_teacher_contract_activation_guard.sql:24-82`), étendue aux contrôles,
  joue vers `active` **et** vers `provisional_active` : sa condition (`:38-41`) et
  sa clause `WHEN` (`:81`) sont élargies. Aujourd'hui elle ne joue que vers
  `active`, alors que l'affectation accepte `provisional_active`
  (`M/0082_teachers_for_class.sql:60`) ; `CORR §7` le note déjà pour le contrat.
  Elle joue sur toute activation, `decider_dossier()` compris ;
- affecter une personne en restriction ou indisponible : le prédicat d'affectation
  la refuse, sans changer son étape ; un enseignant sans candidature n'est pas
  touché. Ce prédicat est celui que centralise le lot `creer_groupe`
  (`app_private.verifier_affectation_enseignant`, `CORR §0 bis`), lu par
  `tc_verifier_affectation_enseignant` et `creer_groupe` ;
- s'inscrire sans genre, sans téléphone, ou sans code quand la clé de mise en
  ligne est fausse (3.1) ;
- inviter une ligne sans courriel valide ; importer sans être super-admin, ou
  ailleurs qu'en réponses importées ; exposer une pièce, un contact ou un genre
  dans une liste ;
- planifier sans fuseau connu ou avec un intervieweur hors portée (de l'autre
  côté, super-admin compris) ; donner un jeton d'entretien à un autre que le
  candidat convoqué et l'intervieweur ;
- pendant une pause, tout geste autre que lever la pause, refuser ou retirer ;
- déposer la pièce d'un compte candidat hors de la Salle de vérification et
  d'entretien (en cours) ou de la salle 3, par toute voie : posé par CAND-L1B
  (3.1) ; accepter le contrat ou l'avis hors de leur étape (2.1) : L2, une fois
  tranchés les accords en trois moments (0.3).

**Ne rétrograde jamais** : une indisponibilité, une pause, un critère ou une
version de questionnaire changés après une décision, un contrôle qui tombe après la
salle 3 (il pose une restriction, `PORTS §5` point 2). En salle 2, un contrôle qui
tombe bloque l'entrée en salle 3 et compte dans « bloquées », sans retour en
salle 1 ; si `profil_renseigne` devient faux, la direction demande le complément
(transition 23). **Nouvelle version d'un texte** : les candidatures en cours la
ré-acceptent avant la salle 3 ; les personnes en salle 3 gardent la leur
(`REVUE §11`).

---

## 5. Les huit contrôles nommés

Une seule fonction en base (nom indicatif `private.candidature_controles`) les
calcule. Elle est lue par `ADM-21`, par la validation de pièce et par la garde
d'activation. Chaque bascule est journalisée avec sa cause (décision `ADM-02`,
ligne du référentiel, entretien consigné). Un autre type porte sa propre liste.

| Contrôle | Vrai quand | Lu dans | Exigé pour |
| :--- | :--- | :--- | :--- |
| `paiement_compatible` | un moyen déclaré, confirmé par la direction, croise une ligne `confirme` du pays de versement | réponses et référentiel (L6) | salle 2 et salle 3 |
| `accords_signes` | contrat `teacher_nda`, avis `recording_and_control_notice` et cadre religieux acceptés aux versions requises ; plus `teacher_conduct_code` dès le lot `conduite` (section 13) | `contract_acceptances`, `contract_required_versions` | cadre : salle 2 ; tous : salle 3 |
| `profil_renseigne` | langues d'explication (codes ; la langue maternelle, facultative, n'y entre pas), niveau de mémorisation déclaré, publics (au moins une tranche d'âge), fuseau IANA, disponibilités déclarées (au moins une plage, dans ce fuseau), pays de résidence et de versement ; ni les classes souhaitées ni les moyens accessibles | réponses ; jamais `weekly_availability`, écrit par un enseignant actif seulement | salle 3 |
| `entretien_conclu` | un entretien `tenu`, compte rendu enregistré, avis favorable, mené par un intervieweur autorisé de ce côté | entretiens (L4) | salle 3 |
| `evaluation_validee` | constat structuré présent : niveau observé, riwaya, ijaza présentée ou non (`DEC:31`, `:45`) | constat de l'entretien | salle 3 |
| `profil_unique` | aucun autre compte ni candidature en cours du même type pour la même personne (courriel confirmé, téléphone normalisé donné à l'inscription) sans décision de la direction ; aucun profil enseignant déjà actif | profils, candidatures | salle 3 |
| `aucune_restriction` | ni restriction ni pause active | candidature | salle 3 |
| `piece_validee` | pièce `approved` | `kyc_documents` | c'est le geste d'entrée en salle 3 ; refusé tant qu'un des sept autres est faux (`DEC:24`) |

La décision finale humaine de la spec (`SPEC §3`) est cette validation, prise après
l'entretien. Un avis défavorable laisse `entretien_conclu` faux ; la direction
refuse alors avec motif.

### 5.1 Compatibilité de paiement (`CAND-Q05`)

**Un référentiel déclaratif** : il dit, pays par pays, quel moyen fonctionne, sans
rien verser ni appeler aucun prestataire (`DEC:28`). Une ligne : pays (ISO 3166),
méthode (`virement_bancaire`, `mobile_money`), opérateur, prestataire (une
colonne, `lib/core/capacites/port_capacite_payout.dart:5-8`), devise, type de
décaissement (`SPEC §4.4`, `PORTS §4`), état (`confirme`, `en_verification`,
`indisponible`), vérifié le, par, notes ; `confirme` exige une date et un
responsable (`PORTS §4`, `REVUE §5.2` R8).

**État initial, déduit de `DEC:28`** : chaque pays **hors d'Afrique**, Arabie
saoudite comprise, a `virement_bancaire` à `confirme`. La note dit « décision du
directeur du 21/10, `DEC:28` » ; « vérifié par » est le compte qui enregistre la
ligne. Le directeur a décidé une règle, il n'a pas vérifié chaque pays : un pays
où l'académie ne peut pas verser se signale au directeur. Chaque pays
**d'Afrique** a toutes ses lignes à `en_verification`, compte bancaire compris,
jusqu'à la réponse ouverte de `CAND-Q05` ; la liste de ces pays est proposée en L6
avec sa source (0.3).

**Liste des pays d'Afrique proposée par L6, à soumettre au directeur avec
`CAND-Q05`.** Source nommée : Division de statistique des Nations unies, norme M49
(« Standard country or area codes for statistical use »), région 002 Afrique,
<https://unstats.un.org/unsd/methodology/m49/overview/>, lue le 21/10/2026 :
60 pays ou territoires.

| Région M49 | Codes ISO 3166-1 |
| :--- | :--- |
| 015 Afrique du Nord (7) | DZ EG LY MA SD TN EH |
| 014 Afrique orientale (22) | IO BI KM DJ ER ET TF KE MG MW MU YT MZ RE RW SC SO SS UG TZ ZM ZW |
| 017 Afrique centrale (9) | AO CM CF TD CG CD GQ GA ST |
| 018 Afrique australe (5) | BW SZ LS NA ZA |
| 011 Afrique de l'Ouest (17) | BJ BF CV CI GM GH GN GW LR ML MR NE NG SH SN SL TG |

L'Arabie saoudite et le Yémen sont en Asie de l'Ouest pour la même norme. Les
territoires d'outre-mer français de la région (La Réunion, Mayotte, Terres
australes) y figurent : la norme les range en Afrique orientale. L'état initial
porte une ligne de virement par code de `lib/core/i18n/pays_iso.dart` (249) :
189 à `confirme`, 60 à `en_verification`. Les 189 comprennent des territoires sans
population (AQ, BV, HM, GS, UM) et des pays où un virement peut être impossible
(sanctions internationales : par exemple KP, IR, SY, CU) : ils sont à signaler au
directeur, qui a décidé une règle et non vérifié chaque pays. Tant que la clé
`app_config` `paiement.afrique_ouverte` ne vaut pas `true`, aucune ligne d'un pays
de cette liste ne quitte `en_verification` (ni `confirme`, ni `indisponible`) : la
RPC le refuse (`afrique_en_verification`) et une garde de table le refuse pour
toute autre voie. La clé passe à `true` sur décision datée du directeur, et par
elle seule : elle recopie la dernière ligne de
`public.referentiel_paiement_afrique_decisions` (ajout seul : ouverte ou fermée,
référence de la décision, date), qu'aucun compte n'écrit, direction, comptabilité
et `service_role` compris ; seul le propriétaire de la base l'écrit, par migration
ou par l'éditeur SQL. Une garde sur `app_config` refuse toute écriture directe de
la clé (sur le modèle du quota C-29), son effacement et son renommage. Refermer
l'Afrique est refusé tant qu'une de ses lignes n'est pas revenue à
`en_verification`.

**Clés des réponses déclarées, fixées par L6** (`candidature_reponses.reponses`,
document de source `candidat` le plus récent ; jamais une réponse importée) :
`paysVersement` (code ISO 3166-1 alpha-2 en majuscules), `compteBancaire`
(booléen), `operateurs` (tableau de codes du catalogue des opérateurs de mobile
money). Une déclaration existe quand `paysVersement` est un code valide et
`compteBancaire` un booléen ; sinon le paiement vaut `inconnu`. `paysResidence` et
`accordRemuneration` (booléen, lu par L2 à l'envoi) ne sont pas lus par le calcul.
L2A1 écrit `accordRemuneration` dans le document envoyé, et l'accord lui-même
comme une acceptation `teacher_pay_conditions` à la version de la politique que
le candidat a lue et qu'il renvoie avec l'envoi (`conditions_perimees` si elle a
changé depuis, `M/20261022000000_cand_l2a1_moteur_salle_examen.sql:2140-2155`), qu'aucun compte n'insère directement ; puis il
recalcule le paiement (`private.paiement_recalculer(id, 'reponses')`, `:2064`),
qui peut enchaîner la transition 8. Un brouillon n'est jamais une déclaration :
« le document de source `candidat` le plus récent » se lit depuis L2A1 parmi les
seuls documents qui ne sont pas des brouillons (`private.paiement_declaration`,
corps de L6 recopié, `M/20261022000000_cand_l2a1_moteur_salle_examen.sql:2310-2335`) ; la colonne `paiement` et le calcul en
direct ne divergent donc jamais après un brouillon. Un document écrit sans la
marque (L6, import à venir) reste une déclaration.
Un moyen déclaré croise une ligne `confirme` du pays de versement de même méthode
(et du même opérateur pour le mobile money ; pour le virement, toute ligne de
virement du pays).

**Les moyens accessibles, champ informatif** (recommandation de l'audit du 22/10, retenue ; `moyensAccessibles`,
facultatif, carte `versement`). La réponse du directeur (« il faut s'assurer que les gens qui vont s'engager
avec nous vont pouvoir être payés ») ne parle pas de ce champ : **à confirmer**, et retirable en une ligne
avant toute publication de la version. Le candidat peut cocher, parmi **tous les moyens connus**
du catalogue de L6 (`referentiel_paiement_operateurs`, les opérateurs actifs : code,
méthode, nom de marque), ceux qu'il peut utiliser **même si aucun pays ne les
confirme**. Il sert à la direction à choisir les pays à vérifier en Afrique, et à rien
d'autre. Ce que le serveur garantit, preuve par le scénario de L2A1 :
- **il n'entre jamais dans le calcul du paiement** : `private.paiement_declaration` ne
  lit que `paysVersement`, `compteBancaire` et `operateurs` ; mêmes réponses avec et sans
  `moyensAccessibles`, même déclaration, même dimension ; un opérateur confirmé dans le
  pays rend le paiement `a_verifier` s'il est déclaré dans `operateurs`, et le laisse
  `incompatible` s'il n'est que dans `moyensAccessibles` ;
- **aucun contrôle ne le lit** : le contrôle `questionnaire_complet` (L2A2) l'écarte du
  document comme `operateurs` et `accordRemuneration` ; un moyen devenu invalide (opérateur
  retiré du catalogue) ne bloque ni l'admission ni la réouverture ; la seule fonction du
  schéma qui nomme la clé est cette exclusion ;
- **le contrôle de paiement reste la condition d'entrée en salle 2** : cocher tous les
  moyens connus ne rend compatible aucune personne sans compte bancaire ni opérateur
  confirmé dans son pays ;
- **il déroge à « le candidat ne voit que les options confirmées »** (`V1:317-318`, 5.1 :
  `options_paiement_confirmees`, qui reste la seule lecture des lignes confirmées) : la
  liste ne dit rien de ce qui est confirmé, ni pays ni état ni note. À soumettre au
  directeur (0.2 bis).
Les opérateurs du catalogue sont aujourd'hui Wave, Orange Money et Moov Money (spec v1,
4.2) ; MTN et YAS (audit du 22/10, section 3) n'y sont pas : ils s'ajoutent par
migration, sur décision, et paraissent alors dans cette liste.

**Ce que le candidat déclare** (`CAND-01`) : pays de résidence ; pays de
versement ; compte bancaire oui ou non ; opérateurs, parmi les seules lignes
`confirme` de son pays de versement ; la case « J'accepte de recevoir ma
rémunération par au moins un moyen validé par Rewayah » (`SPEC §4.2`). Les deux
pays se choisissent dans la table existante `lib/core/i18n/pays_iso.dart` :
249 pays ISO 3166-1, noms en français et en arabe, Arabie saoudite et Yémen
compris (`REVUE §4` E8). Le serveur ne reçoit que le code à deux lettres. Sans
ligne confirmée dans son pays, le candidat lit une phrase à la place des
opérateurs, jamais une liste vide. Jamais demandé : numéro de compte, IBAN, numéro
de portefeuille, identifiant, code ; le numéro WhatsApp n'est jamais réutilisé
comme numéro de portefeuille.

| État | Quand |
| :--- | :--- |
| `inconnu` | aucune déclaration |
| `a_verifier` | la déclaration croise une ligne `confirme` ; la direction ne l'a pas encore confirmée |
| `compatible` | la direction a confirmé le moyen (`confirmerMoyenPaiement`, transition 24) |
| `incompatible` | moyen infirmé (transition 25), ou aucune ligne `confirme` croisée |

- Hors d'Afrique sans compte bancaire : `incompatible` ; la candidature reste en
  salle d'examen (`paiement_non_disponible`), issue `en_cours`.
- En Afrique, tant que `CAND-Q05` est ouvert : `incompatible`, même avec un compte
  bancaire. Une ligne `en_verification` ne rend jamais `compatible`.
- **Ligne qui quitte `confirme`** (`ADM-24`) : restriction automatique « paiement
  à revérifier » pour les personnes en salle 3 qui n'avaient qu'elle ; en salle 2,
  le contrôle passe faux et la candidature compte dans « bloquées » ; en salle
  d'examen, la transition 8 s'applique ; les personnes qui gardent un autre moyen
  déclaré, confirmé par la direction, sur une ligne `confirme` ne bougent pas. Qui
  n'a plus qu'un moyen déclaré non encore confirmé (paiement `a_verifier`) passe
  aussi en restriction en salle 3 (0.2 bis). `enregistrer` rend l'`impact`
  (nombre de restrictions, dans la portée du lecteur, 0.2 bis) ; alerte à la
  direction et à la comptabilité.
- **Ligne qui passe `confirme`** : les candidatures `paiement_non_disponible` du
  pays passent `a_completer` (transition 9).

Écrivent : la direction et la comptabilité (`paiement.referentiel.ecrire`). Le
référentiel devient la source de compatibilité par corridor de `CPT-BR-10`, sans
remplacer `PortCapacitePayout` (`PORTS §4`).

**Statut L6 au 21/10** : `présent dans le code` et `testé localement` ; ni testé
sur staging, ni déployé. Migration
`supabase/migrations/20261021220100_cand_l6_referentiel_paiement.sql`, scénario
`supabase/tests/scenarios_cand_l6_referentiel_paiement.sql` (cas L6-1 à L6-10,
droits, journal, genre sans effet), rejoué sur base neuve. Ce que L6 pose :

| Objet | Rôle |
| :--- | :--- |
| `public.referentiel_paiement` | une ligne par pays, méthode et opérateur ; prestataire, devise, type de décaissement (liste proposée : `virement_international`, `virement_local`, `payout_portefeuille`, vide tant qu'il n'est pas précisé), état, source (`decision_directeur` ou `verification`), vérifié le, par, notes, version |
| `public.referentiel_paiement_afrique` | les 60 codes ci-dessus et leur région M49 |
| `public.referentiel_paiement_afrique_decisions` | décisions datées du directeur sur l'Afrique, en ajout seul ; la dernière fait foi et la clé `paiement.afrique_ouverte` la recopie ; écrite par le seul propriétaire de la base ; la première, fermée, renvoie à `DEC:80-83` |
| `public.referentiel_paiement_operateurs` | catalogue fermé des opérateurs (Wave, Orange Money, Moov Money, nommés par `SPEC §4.2`), étendu par migration ; aucune disponibilité supposée |
| `public.referentiel_paiement_journal` | chaque changement en ajout seul, par quelque voie que ce soit (déclencheur de la table) : avant, après, auteur et clé d'idempotence (vides hors de la RPC), effets comptés au total et par genre ; plus une entrée `audit_logs` |
| `public.candidature_paiement_decisions` | décisions de la direction sur un moyen déclaré (transitions 24 et 25), en ajout seul ; une confirmation exige un moyen déclaré qui croise une ligne `confirme` ; une infirmation exige un motif. **Aucun geste de L6 ne l'écrit** : L2 y écrit, puis appelle `private.paiement_recalculer` |
| `candidatures.restriction_cause` | `piece`, `paiement` ou `manuelle`, présente si et seulement si la candidature est en restriction (4.1) ; l'état `paiement_non_disponible` entre dans les contraintes |
| `capacites_referentiel_paiement()` | `peutLire`, `peutEcrire` : comptabilité active ; direction active de genre connu, ou sous l'exception super-admin |
| `lire_referentiel_paiement(pays?)` | `PortReferentielPaiement.lister` : lignes (avec `capacitePayout` : `confirme` donne `prisEnCharge`, `en_verification` `verificationRequise`, `indisponible` `nonPrisEnCharge`), liste des pays d'Afrique, sa source et la dernière décision, listes de la fiche `ADM-24` (méthodes, états, types, opérateurs), alertes : les changements qui ont posé des restrictions dans la portée du lecteur, chacun avec ce nombre seul ; direction au genre inconnu refusée ; une lecture de l'autre côté par l'exception super-admin se journalise |
| `enregistrer_ligne_referentiel_paiement(...)` | `PortReferentielPaiement.enregistrer` : version attendue et clé d'idempotence ; refus rendus `confirmation_sans_verification`, `afrique_en_verification`, `conflit_referentiel` (ligne relue jointe), `absente`, `cle_idempotence_reutilisee` ; direction au genre inconnu refusée avant tout effet ; rend la ligne relue et l'`impact` (restrictions posées, dans la portée du lecteur), rien d'autre |
| `options_paiement_confirmees(pays)` | `PortReferentielPaiement.optionsConfirmees` : pour le titulaire d'une candidature en cours au compte valide (en attente, provisoire ou actif, non expiré, comme L1-08), les seules lignes `confirme` du pays (méthode, opérateur, nom, devise), sans note, prestataire, source ni nom |
| `private.paiement_etat`, `private.paiement_compatible` | la dimension paiement et le contrôle `paiement_compatible`, lus par L2 (section 5, transition 10) |

Effets d'une ligne qui passe ou quitte `confirme`, portés par un déclencheur de
la table, donc par toute voie d'écriture (la RPC, l'éditeur SQL, une migration
qui appliquerait la réponse à `CAND-Q05`), pour les candidatures en cours dont le
pays de versement déclaré est celui de la ligne, journalisés dans
`candidature_evenements` avec la cause (`referentiel`) et la ligne : transition 8
(en examen), transition 9 (`paiement_non_disponible` vers `a_completer`,
carte `versement` nommée (jusqu'à la relecture de L2A2 du 22/10, `moyen_paiement`, qui n'est pas une carte du questionnaire), marqueur `aNotifier` = `paiement_possible`, le modèle de
la liste fermée de `CONTRAT_FILE_COURRIELS.md` section 3, pour L5), contrôle qui
tombe en salle 2 (« bloquée », sans retour), restriction automatique en salle 3
(transition 20, cause `paiement`, motif « paiement à revérifier » ; décidée par
le calcul en direct, jamais par la colonne `paiement`, qu'une écriture oubliée
laisserait périmée ; une candidature déjà en restriction garde sa cause), un
événement `controle` à chaque changement de la dimension. Auteur : système.
Aucune levée automatique (transition 21). Le pays, la méthode et l'opérateur
d'une ligne ne changent pas, aucune ligne ne s'efface, et la version augmente à
chaque modification, par toute voie (gardes de table). Les lignes du référentiel
ne sont pas cloisonnées par genre et un changement agit sur les deux côtés ; ce
qui sort vers un compte l'est (0.2 bis) : une direction lit les restrictions de
son côté, le super-admin les deux côtés (journalisé, comme C13 de L1), la
comptabilité le total ; les autres compteurs (bloquées, transitions 8 et 9,
candidatures recalculées, partage par genre) restent dans le journal. L'alerte à
la direction et à la comptabilité est le journal des changements qui ont posé
des restrictions dans la portée du lecteur, rendu par `lire_referentiel_paiement`
en nombres ; notifications et courriels : L5. Depuis L2A2 (22/10) :
`capacites_candidatures` rend `peutEcrireReferentiel` lu dans
`private.paiement_gestionnaire()` (`M/20261022000100_cand_l2a2_gestes_direction.sql:1556-1637`) ; le filtre `etat` de
`lister_candidatures` accepte `paiement_non_disponible` (`:1709-1882`) ; les
gestes 24 (Salle d'examen, et salle 3 sous restriction de cause `paiement`) et 25
écrivent `candidature_paiement_decisions` puis recalculent (4.2). Depuis la relecture de L2A2 (22/10), la transition 9 vaut aussi pour une
candidature refusée ou retirée en `paiement_non_disponible`, au moment de sa
réouverture (19). Reste ouvert :
`lister_candidatures` ne rend pas `restriction_cause` (seulement `restreinte`) ;
`lire_candidature` la rend, avec `pauseModele` et `refusModele` ; l'entrée `audit_logs` de chaque effet porte l'identifiant de la candidature,
comme les entrées de L1 : depuis L2A1, elle ne se lit que du côté de la
candidature (8.2), et son compte ne sort plus vers l'autre côté ; qui ajoute un
opérateur au catalogue (aujourd'hui par migration).

### 5.2 Tri : des clés en clair (`CAND-Q20`)

Clés affichées sur la ligne, dans cet ordre, jamais un score (`DEC:43`,
`SPEC §4.3`) : (1) besoin ouvert, genre et langue que la direction cherche, posés
en filtre ; (2) niveau constaté à l'entretien, ou déclaré avant ; (3) disponibilité
(classes souhaitées, date de début) ; (4) compte bancaire, **seulement** à égalité
des trois premières. Aucune élimination automatique. Autres tris : date de
réception, dernière activité, date d'entretien. Le tri se fait au serveur ; un
scénario SQL le prouve (L1-9).

---

## 6. L'entretien dans l'app (`CAND-Q06`, `Q08`, `Q09`, `Q19`, `Q22`)

### 6.1 La séance d'entretien (L4, `CAND-BR-08`)

| Règle | Aujourd'hui | Ce que L4 pose |
| :--- | :--- | :--- |
| Type | `session_type` n'admet que `standard` et `child` (`M/0001_fondations.sql:170`) | type `entretien` |
| Qui entre | jeton refusé à un compte `pending_kyc` (`M/20261017110100_af_l2_01_jeton_enseignant_effectif_et_retrait.sql:44-52`) | le seul candidat convoqué, `pending_kyc` admis pour cette séance ; l'intervieweur ; personne d'autre |
| Intervieweur | `entretiens.mener` sans titulaire | un membre de la direction (`DEC:42`), du même côté que le candidat, super-admin compris. Le super-admin lit les deux côtés (`DEC:30`) ; il ne mène que du sien tant que la question est ouverte (0.3) |
| Paie | une séance close déclenche la paie (`M/20261012120101_x2_17_treasury_triggers.sql:400-407`) | **jamais payée** : exclue du déclencheur |
| Effets de bord | clôture automatique (`M/20261018180000_ses_cloture_auto.sql:67-97`), chevauchement sur `teacher_id` (`M/0005_dashboards_affectation_regles.sql:640-645`), `mes_seances_v` (`M/20261017100400_af_l1_04_mes_seances_v_par_role.sql:28-43`), observation par le contrôleur | exclue de chacun ; la forme de `teacher_id`, obligatoire aujourd'hui, est fixée par L4 (0.3) |
| Enregistrement | supprimé pour l'instant (`C/DECISION-ENTREE-2026-10-17.md:33`) | aucun enregistrement, aucune visite de contrôle |
| Mention | « Visite de contrôle possible. » en permanence (`lib/features/salle_seance/mention_seance.dart:20-24`) | **aucune mention** : ni celle-ci, ni « Entretien non enregistré » (`DEC:32`) |
| Données | - | ni genre, ni pièce, ni téléphone, ni réponses dans la salle |
| Écran | salle unique `/salle` | même salle, aucune refonte LiveKit ; chemin du routeur depuis `/attente`, un seul routeur |

Il ne reste de l'entretien que le compte rendu, le constat et les données de la
personne : « c'est éphémère » (`DEC:32`).

### 6.2 États, des deux côtés

Mise à jour de `REVUE §6.3 bis` : la voie WhatsApp disparaît, le secours passe par
la conversation.

| État | Candidat (`CAND-02`) | Direction (vue Entretiens d'`ADM-20`, `ADM-21`) |
| :--- | :--- | :--- |
| À planifier | « Votre entretien sera planifié prochainement. » | lien « Planifier un entretien » |
| Planifié | date, heure, fuseau du candidat et de l'intervieweur ; « Voir les détails » | date, heure, fuseaux, intervieweur ; « Voir les détails » |
| Ouvert, en cours | « Rejoindre l'entretien », bouton plein de l'écran | « Rejoindre l'entretien » : lien secondaire sur la ligne (`DEC:37`), action principale dans `ADM-21` |
| Terminé | « Entretien terminé. L'académie vous répondra. » Jamais le résultat | résultat, compte rendu, constat, durée si connue, action suivante |
| Annulé | état dit ; « Une nouvelle date vous sera proposée. » | « Annulé le … par … » ; « Reprogrammer » |
| Manqué | état dit, et la suite | « Manqué » (candidat ou intervieweur) ; « Reprogrammer » |
| Inaccessible (jeton ou salle) | « L'entretien n'est pas accessible pour le moment. » et un lien vers la conversation ; aucun bouton qui ne peut pas aboutir | même phrase ; « Reprogrammer » |

### 6.3 Règles

- Sur une ligne, le nom ouvre le dossier, le lien d'entretien est une cible à part
  (`SPEC §6`, `DEC:37`) ; la carte entière reste cliquable. L'ouverture suit la
  fenêtre de la salle existante (`ctaSeance`), appliquée par le jeton.
- L'issue reste au retour à `entretien_a_planifier`. `tenu` : compte rendu
  obligatoire, écrit par l'intervieweur désigné seul ; `annule`, `manque_*` : motif
  obligatoire. Fuseau du candidat inconnu : planification refusée.
- Alerte « entretiens en retard » : date passée sans compte rendu depuis plus de
  24 h, ou « à planifier » depuis plus de N jours (N dans `app_config`). Sans
  intervieweur de son côté, la candidature attend et compte dans l'alerte ; jamais
  d'intervieweur de l'autre côté, super-admin compris (0.3).
- **À régler par L4** (relecture de L2A2, 22/10). Le refus (16) et le retrait (17)
  d'une candidature en `entretien_planifie` ne notent aujourd'hui que
  `entretienPlanifie` dans l'événement : L4 annule la séance dans la même
  transaction (son issue reste). L'état d'origine d'une réouverture (19) après un
  entretien annulé, `entretien_planifie` comme aujourd'hui ou `entretien_a_planifier`
  comme la ligne 12, est une question de 0.2 bis ; le scénario de L2A2 fige le
  comportement actuel pour que L4 le voie.

---

## 7. Contact et messages

### 7.1 La conversation dans l'app (L5, `CAND-BR-18`)

Le contact entre la direction et un candidat passe par **la messagerie métier
existante** : un fil toujours lié à un objet, entre une personne et l'équipe
(`M/20261016090000_com_back_1_messages_metier.sql`, `DEC:72-75`).

| Point | Aujourd'hui | Ajout |
| :--- | :--- | :--- |
| Objet | `com_fils.type_objet` : `classe`, `eleve`, `dossier`, `remplacement`, `profilPaiement` (`:61-62`) ; `TypeObjetLie` (`lib/core/communications/modeles_communication.dart:112`) | objet `candidature` |
| Paire | profil ou foyer, face à l'équipe | profil du candidat, face à l'équipe |
| Compte admis | `com_appelant()` exige `app_account_valid()` (`:155-165`) | compte `pending_kyc` admis **pour ce seul objet** |
| Lecture par la direction | équipe d'administration | bornée par genre ; le super-admin lit les deux côtés |
| Écran | `FilContextuel` (`lib/features/com_messages/fil_contextuel.dart:59`) ; précédent « fil seul » `CPT-12F` (`C/CATALOGUE_ECRANS_COMPTABLE.md:37`) | `CAND-05` côté candidat, `ADM-21F` côté direction |

Un fil par candidature. Jamais de fil entre candidats, de liste de destinataires
ni de message groupé visible (`SPEC §7`, `REVUE §5.2` R12). Le fil sert aux
questions et aux compléments ; une décision (refus, pause) reste un geste à modèle,
et un motif interne ne s'y écrit pas.

### 7.2 Notifications dans l'app

Table existante `public.notifications` (`M/0063_notifications_privatives.sql:4`) ;
un compte `pending_kyc` y est admis pour les seuls événements de sa candidature
(aujourd'hui, rien pour un compte en attente, `REVUE §3.6`). Liste fermée :
complément demandé (Salle d'examen ou Salle de vérification et d'entretien) ;
admise en Salle de vérification et d'entretien ; pièce à corriger ; entretien
planifié, annulé ou reprogrammé ; pause posée ou levée ; refus ; retrait
enregistré ; entrée en Salle des prêts à enseigner ; moyen de paiement désormais
possible ; nouveau message. Texte tiré d'un modèle validé, en `fr` ou `ar`.

### 7.3 La file des courriels (`CAND-Q10`, `CAND-BR-16` révisé)

Ce module **n'envoie aucun courriel**. Il écrit la liste des courriels à envoyer ;
l'envoi, construit par la session du site public, la lit (`DEC:33`).

| Champ | Règle |
| :--- | :--- |
| destinataire | le profil ; pour une ligne sans compte, le courriel importé valide |
| modèle | liste fermée : `invitation` et les événements de 7.2 ; `lien_inscription` est le modèle du message WhatsApp consigné (7.4), jamais un courriel |
| langue | `fr` ou `ar` : celle de l'interface choisie, sinon `ar` pour une ligne importée de A |
| paramètres | dates, liens ; pour le seul modèle `invitation`, le code d'invitation, lu par la seule fonction d'envoi ; jamais un texte libre, un motif interne, une réponse ni un constat |
| état | `a_envoyer` (écrit par ce module), puis `envoye` avec la date ou `echec` avec la cause (écrits par l'envoi seul) |
| droits | ce module écrit par RPC, l'envoi par sa fonction serveur ; aucun candidat ne lit la file ; la direction ne change jamais un état |
| à l'écran | « Courriel pas encore envoyé » tant que `a_envoyer` ; « Courriel envoyé le … » seulement sur `envoye` ; « Courriel non parti » sur `echec` ; jamais « reçu », jamais « lu » |

Ce tableau est le **contrat à remettre à la session du site public**. Deux
dépendances distinctes :
1. **L'envoi de Supabase Auth** : SMTP d'authentification en production et
   `enable_confirmations = true` (`supabase/config.toml:229`, `[auth.email.smtp]`
   commenté en `:239-247`). C'est l'envoi qui part déjà pour le lien de connexion
   (`signInWithOtp`, `lib/core/auth/service_auth.dart:52`). Il confirme le courriel
   à l'inscription : condition de mise en ligne du lien (3.1, condition 6).
2. **L'envoi de la file**, construit par la session du site public (`DEC:33`) :
   condition du seul état « Courriel envoyé le … », et de l'émission des
   invitations en production (3.3).

### 7.4 La seule exception WhatsApp

Le directeur n'admet WhatsApp que pour **envoyer le lien d'inscription aux
personnes des formulaires sans courriel** (`DEC:26`, `:29`) : un message par
personne, jamais un groupe ni une liste de diffusion ; le message dit de créer un
courriel (`DEC:56`) ; la direction le consigne par `consignerPrevenu` (canal
`whatsapp`, modèle `lien_inscription`, date, transition 26), jamais un texte libre.
L'accord de contact donné dans A (colonne M) ne vaut que pour ce contact
(`MAP §2`).

### 7.5 Ce que le module ne prétend jamais

« Envoyé » avant que l'envoi l'ait écrit ; « lu » ; une décision avant la réponse
du serveur ; un entretien « enregistré » ; un message au candidat qui contient un
motif interne, un compte rendu ou un constat.

---

## 8. Confidentialité et droits

### 8.1 Capacités

Mise à jour de `REVUE §5.4` par `DEC:30`, `:42`.

| Capacité | Qui | Accède à | N'accède jamais à |
| :--- | :--- | :--- | :--- |
| `candidatures.lire` | direction, de son côté ; super-admin les deux côtés, journalisé | réponses, contrôles, étape, historique, réponses importées, **autres compétences** (dossier et filtre de la liste, par code ou par famille) | pièce hors `ADM-02` |
| `competences.catalogue.lire` | direction active (sans condition de genre) ; le titulaire d'une candidature d'enseignant (les compétences actives et celles de sa propre réponse) | le catalogue des compétences : code, famille, ordre, libellé, exemple, actif (et la version, pour la direction) | rien d'autre |
| `competences.catalogue.ecrire` | direction active seule, sans condition de genre | ajouter une compétence ou la modifier (libellé, exemple, ordre, actif) ; **jamais de suppression, ni de changement de code ou de famille** ; journalisé | le candidat, la comptabilité, le tuteur |
| `candidatures.contact` | direction nommée, de son côté | courriel, téléphone, recherche par téléphone ; chaque lecture journalisée | - |
| `candidatures.importer` | super-admin seul, aal2 exigée en base (3.2) | import, essai à blanc, rapport | - |
| `candidatures.decider` | direction, de son côté | transitions, pièce dans `ADM-02`, lots | - |
| `entretiens.mener` | direction (`DEC:42`), du même côté que le candidat, super-admin compris | réponses utiles à l'entretien, date, fuseaux, constat, compte rendu | téléphone, pièce, autres candidatures |
| `candidatures.messages` | direction, de son côté | le fil `candidature` | les fils de l'autre côté |
| `paiement.referentiel.ecrire` | direction, comptabilité | référentiel, impact d'un changement | réponses, identité |
| candidat | le titulaire | sa candidature, son fil, son entretien, ses notifications, **ses autres compétences** (lire, enregistrer, retirer) | tout autre candidat ; listes ; compteurs ; motifs internes ; compte rendu ; constat |
| contrôleur, enseignant, tuteur, élève | - | rien | tout |

L'exception du super-admin (`DEC:30`) est une exception **de lecture** : listes,
dossier, compte rendu. Elle ne lui donne pas l'entretien d'une personne de l'autre
côté (0.3).

### 8.2 Séparation femmes et hommes, en base (`CAND-Q07`)

La RLS et chaque RPC du module bornent la direction à son côté, sur le modèle de
`read_kyc_documents()` : filtre par genre du lecteur, refus si ce genre est
inconnu, journal de chaque lecture de liste. Le super-admin lit les deux côtés,
par l'exception journalisée de `M/0088_kyc_super_admin_gender_exception.sql`
(`DEC:30`). Portée : candidatures, réponses, réponses importées, contacts,
entretiens, conversation, historique **et compteurs**. « Hors portée » et
« absente » sont deux erreurs distinctes. Un masquage à l'écran ne compte pas
(`SPEC §7`). L'import, dont le fichier mêle les deux côtés, est réservé au
super-admin (3.2).

**Le journal d'audit, borné par L2A1 le 22/10** (`testé localement`). Une ligne
d'`audit_logs` a le côté de la candidature qu'elle vise (tables `candidatures`
et `candidature_contacts`, ligne = identifiant) ; sinon celui de la candidature
avant la salle 3 que porte son auteur (règle de CAND-L1B) ; sinon, pour une
lecture de liste de L1, celui du lecteur ; une trace de l'exception du
super-admin qui ne vise aucune candidature compte des lignes de l'autre côté et
n'a que le côté de l'exception. Une ligne sans côté reste lisible par toute la
direction. `journal_audit()` et `journal_audit_filtres()` ne rendent et ne
comptent que les lignes du côté du lecteur ; un lecteur au genre inconnu n'en lit
aucune qui ait un côté ; le super-admin lit les deux côtés, et chaque appel qui
lui en rend de l'autre côté laisse une trace (`candidature_exception_super_admin`,
motif `exception_super_admin_kyc`, nombre de lignes). La lecture directe
d'`audit_logs` est bornée par une policy restrictive, sans l'exception, qui ne
s'y journaliserait pas. Les accords (`contract_acceptances`) d'un compte qui
porte une candidature avant la salle 3 ne se lisent que de son côté, comme son
profil (`M/20261022000000_cand_l2a1_moteur_salle_examen.sql:919-925`, `:2346-2640`). `verifier_chaine_audit()` reste sans
portée : elle ne rend que des comptes de maillons. Choix à soumettre : 0.2 bis.

### 8.3 Ce que les listes ne montrent jamais

Ni courriel, ni téléphone, ni genre, ni pièce, ni motif interne, ni compte rendu,
ni constat, ni réponse libre, dans une liste, un aperçu de lot ou un export
(`PORTS §1`, `LigneCandidature`). Le contact se lit par `lireContact`, journalisé.
Le journal porte la référence `CAND-` et un numéro, jamais le nom ; chaque lecture
hors portée et chaque lecture du contact y laissent une entrée. Dans
`journal_audit()` et `journal_audit_filtres()`, l'auteur porteur d'une
candidature avant la salle 3 est rendu par sa référence `CAND-`, jamais par son
nom (L2A1).

### 8.4 Conservation, anonymisation, effacement (`CAND-Q21`)

- Durée réglable dans `app_config`, **valeur en attente du juriste** : aucune
  purge automatique avant la décision datée.
- Anonymisation sur le modèle de `traiter_demande_suppression`
  (`M/20261018150000_cpt_suppression_export.sql:587`) ; réponses dans
  `mes_donnees_export()` (`:174`), motifs internes exclus. Effacement demandé
  depuis l'app (`demander_suppression_compte`, `:385`), ou reçu par courriel et
  noté par la direction pour une personne sans compte.
- Deux tables de L2A1 entrent dans le lot de conservation (`CAND-BR-14`) :
  `candidature_gestes`, en ajout seul, qu'aucun compte n'efface, pas même le
  propriétaire, garde le premier résultat des envois, retraits et gestes de la
  direction (l'état relu, des codes et des versions, jamais une réponse ni un
  motif) ; `candidature_brouillon_cles` garde une ligne par candidature, la
  dernière clé de brouillon et son résultat sans réponse, effacée avec elle. Le
  document de réponses, brouillon compris, reste effaçable (CAND-L1).
- Une table de L2A2 y entre aussi : `candidature_lots`, en ajout seul, garde le
  rapport de chaque action groupée sous sa clé (identifiants, références, issues
  et raisons, état relu ; jamais un nom, une réponse ni un motif,
  `M/20261022000100_cand_l2a2_gestes_direction.sql:256-268`). Les décisions sur un moyen de paiement
  (`candidature_paiement_decisions`, L6) portent un motif interne quand elles
  infirment : le lot de conservation les nomme avec le journal des événements.
- Une table de `CAND-AUTRES` (22/10) y entre aussi : `candidature_autres_competences`, une ligne par
  candidature (domaines = codes du catalogue des compétences, niveaux, texte de « autre », disponibilité, accord d'être contactée),
  effacée avec elle (`ON DELETE CASCADE`) ; la personne peut la retirer à tout moment, même après
  un refus (`retirer_autres_competences`). **Écart connu, épinglé par le scénario** :
  `cpt_anonymiser` et `mes_donnees_export` ne la couvrent pas encore, comme les autres tables du
  module. Le lot de conservation l'ajoute avec elles, texte de « autre » et accord compris.
- Le **catalogue des compétences** (`competences_catalogue`, `CAND-AUTRES`) ne porte aucune donnée de
  candidat et ne s'efface jamais. Son journal (`competences_catalogue_journal`) garde en ajout seul
  l'identifiant du compte de la direction qui a écrit : une donnée du personnel, à suivre par la
  conservation des comptes (`CPT`), pas par celle des candidatures.
- **À soumettre au juriste avec `CAND-Q21`** : la base des courriels envoyés aux
  personnes des formulaires avant leur inscription, et la conservation des
  réponses importées de qui ne s'inscrit pas. B n'a recueilli aucun consentement,
  A un accord de contact par WhatsApp seulement (`REVUE §2.2`, `MAP §2`
  colonne M). Rien n'est affirmé sur leur couverture avant l'avis.

---

## 9. Langues

**Le parcours candidat est livré en français et en arabe** (`DEC:36`) :
inscription, questionnaire, page d'accords, états de `/attente`, « Mon
entretien », retrait, conversation, notifications, modèles de courriel. Le texte
du cadre religieux et pédagogique, dans les deux langues, est **validé
juridiquement** (`SPEC §5`) **et soumis au directeur** (`DEC:34`) ; L2 ne publie sa
version requise qu'après les deux. La sorte d'accord existe depuis L2A1
(`teacher_religious_framework`, `M/20261022000000_cand_l2a1_moteur_salle_examen.sql:801-810`) ; **aucune version requise n'est
publiée** : `cadre_religieux_version_requise()` rend nul, et la transition 6 est
impossible en base (`engagement_non_accepte`, `publie` faux). Une fois publiée, la
version requise s'accepte par la page d'accords, par le titulaire d'une candidature
enseignant en cours en Salle d'examen ou en Salle de vérification et d'entretien,
au compte valide d'un candidat (policy restrictive
`contract_acceptances_cadre_religieux_candidat`, `M/20261022000000_cand_l2a1_moteur_salle_examen.sql:899-906`). Aujourd'hui l'espace `recrutement` n'a que
17 clés traduites sur 106 (`REVUE §3.6`). Les écrans de la direction suivent la
règle générale : le français fait référence, les autres langues suivent le sens.

**Codes de langue** (`CORR §3`, `MAP §3.2` ; décisions du directeur du 22/10,
`C/DECISION-CANDIDATURES-2026-10-21.md` section 1 ter) :
- on **enregistre le code**, on affiche le nom lu dans le référentiel ; les codes
  de `langues_cours` ne changent pas : `poular`, `francais`, `english`
  (`M/0043_offres_horaires_et_intentions.sql:75-78`) ;
- **poular, peul et fulfulde sont une seule langue, le code `poular`** (une entrée du
  référentiel). Il n'y a plus de code `ff` ; l'import convertit `ff`, peul et fulfulde
  en `poular`. L'écran nomme l'entrée de façon que les trois s'y reconnaissent
  (texte soumis au directeur, `mots-rewayah`) ;
- **l'arabe n'est pas une langue de cours** : il reste un choix de langue maternelle
  (`langueMaternelle`, facultative), jamais de langue d'explication. Le questionnaire
  l'exclut de `languesExplication` par la clé `exclure` du champ (`M/…l2a1…`, C17) ;
  l'offre l'a retiré de ses langues le 22/10 (`tarifs-2026-10-18.json`) ;
- **aucun plafond** au nombre de langues d'explication : l'élève ou le parent choisit
  sa langue parmi celles qui sont disponibles, l'académie affecte un enseignant qui la
  parle ;
- hors référentiel : code ISO 639, marqué « hors référentiel », qui nourrit la décision
  d'ouvrir une langue sans l'ouvrir ; une langue ajoutée à `langues_cours` prend le
  code du mappage. La liste du questionnaire donne d'abord les langues du public
  principal (la diaspora africaine) : malinké (maninka) `man`, soussou `sus`, swahili
  `sw`, haoussa `ha`, wolof `wo`, bambara `bm`, soninké `snk`, mandinka `mnk`, avec le
  français et l'anglais du référentiel, puis les autres codes du mappage, et se
  ferme par **`autre`**, la sortie « autre langue » : un code, jamais un texte libre
  (`autre_a_preciser` n'est pas un code). `autre` ne se recopie pas dans
  `teacher_profiles.languages` à l'entrée en salle 3 (L2B) ; les codes qui ne sont pas
  dans `langues_cours` s'y recopient comme des saisies libres que l'affectation ne
  reconnaît pas (`ENS-L8`), sans effet jusqu'à l'ouverture de la langue ;
- **un code ne s'affiche jamais tel quel** : le module porte la table des libellés
  ISO 639 du mappage, en français et en arabe ; en chargement ou en erreur, la
  ligne montre son état, jamais « francais » ;
- le code du malinké (`man`, macrolangue ISO 639-3 « mandingue ») est un choix à
  confirmer ; changer un code avant toute publication est une correction de la
  définition, après publication une version suivante du questionnaire.

Les réponses du module sont en codes dès le premier jour ; `teacher_profiles`
reste en noms jusqu'au lot `langue` (section 13).

---

## 10. Écrans à inscrire au catalogue

À inscrire dans `docs/current/CATALOGUE_ECRANS_RECRUTEMENT.md` (prochain document),
chacun avec sa fiche (Tâche, Contenu, Entrée, États, Droits, Contrat serveur)
**avant tout fichier `.dart`**, puis une `UX_REVIEW_CAND-<n>.md` (`DESIGN-GOV`).
Codes libres : `ADM-20` et au-delà, préfixe `CAND-` (`REVUE §10`).

**Les mots du module** (noms de salle, « Rejoindre l'entretien », « Cadre
religieux et pédagogique ») entrent dans `.claude/skills/mots-rewayah/SKILL.md`
dans le commit des écrans (`DEC:35`). Les noms de salle s'écrivent en entier,
jamais sous une forme courte ; la forme du côté des femmes et la collision avec
« examen de fin des bases » sont jointes à `CAND-Q12` (0.3).

**Règles communes :**
- cinq états obligatoires : `loading` (`Skeleton`), `content`, `empty`
  (`EmptyState`), `error` (avec reprise), `offline` (bandeau, rien d'écrit sans
  réseau) ; selon l'écran : erreur de validation (le champ nommé, ce qui manque,
  quoi faire), hors portée, données partielles (« Disponible au branchement
  serveur »), action en cours, succès seulement après la réponse du serveur ;
- **un seul bouton plein par écran** (`K-56`, `C/REVUE-DIRECTEUR-2026-10.md:12`,
  `DEC:37`), vérifié par `verifierUnSeulBoutonPlein` ; le lien d'entretien d'une
  ligne est secondaire ; un état critique porte texte et icône, jamais la couleur
  seule ;
- cibles de 48 et contrastes conformes, mesurés (`SPEC §10`) ;
- bureau : file et détail ; tablette : deux volets ; mobile : cartes ; 360, 768,
  1440 ; clair et sombre ; aperçu de lot et mappage d'import en pages, pas en
  modales (`tool/verifier_jetons.dart:306-316`).

**Côté candidat :**

| Code | Écran | But | Bouton plein | États propres | Lot |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `CAND-04` | Inscription sans code : extension du parcours d'inscription existant (`/inscription`, `UsageEtape`, `InvitationCandidatPage`, `lib/core/router/routes.dart:44`, `:59`), une entrée sans code à côté du code d'invitation. Une route neuve pour le lien du site ne se crée que justifiée dans la fiche, et mène au même écran (`SPEC §1.3`) | créer le compte candidat | créer le compte | courriel à confirmer ; réponse unique et neutre, la même qu'en cas de succès, pour un courriel déjà utilisé ou un plafond atteint (un lien de confirmation part si l'adresse peut servir ; texte dans la fiche, selon `mots-rewayah`) ; code d'invitation invalide ou expiré ; inscription sans code pas encore ouverte (clé de 3.1) | L3 |
| `/attente` (existant, étendu) | portail de la candidature | dire où en est la candidature et la prochaine action | la prochaine action | à compléter (liste) ; en examen ; versement pas encore possible ; pièce à corriger ; en pause (modèle, reprise) ; refusée (modèle) ; retirée | L2 |
| `CAND-01` | Questionnaire de la salle d'examen | conditions de rémunération, puis réponses | « Envoyer ma candidature » | pré-rempli à relire ; questionnaire périmé ; aucun moyen confirmé dans le pays ; réponses incomplètes nommées ; paiement inconnu, à vérifier, compatible, incompatible | L2 ; opérateurs L6 ; pré-remplissage L3 |
| Page d'accords (existante) | une case « Cadre religieux et pédagogique » de plus | accepter les textes de l'étape | « Suivant » existant | nouvelle version à ré-accepter | L2 |
| `CAND-02` | Mon entretien | voir et rejoindre | « Rejoindre l'entretien » à l'ouverture | les sept états de 6.2 | L4 |
| `CAND-03` | Retirer ma candidature | retrait, effet dit avant (entretien annulé, réouverture par l'académie seulement) | aucun (`ConfirmDestructive`) | retrait en cours ; déjà retirée | L2 |
| `CAND-05` | Écrire à l'académie (fil « Ma candidature ») | conversation | envoyer | fil vide ; message non parti (hors ligne) | L5 |
| `/salle` (existante, mode entretien) | l'entretien | - | celui de la salle | aucune mention ; jeton refusé ; fin de séance | L4 |

**Contrat serveur côté candidat, posé par L2A1 le 22/10, repris après relecture**
(`testé localement`) : `etat_dossier()` gagne la clé `candidature` (étape, état,
issue, pause par son modèle et sa reprise, modèle du refus, version,
questionnaire : versions, périmé, champs manquants ; cadre religieux ;
conditions ; `paiement`, la dimension de 5.1 en direct, ses quatre codes
seulement, qui sert les états de paiement de `CAND-01` ; `aCompleter` : en Salle
d'examen le questionnaire et le cadre religieux, en Salle de vérification et
d'entretien le cadre religieux à une version requise neuve (4.3) ;
`complementDemande` : les codes demandés par la dernière transition qui en porte
(7, 9, 23), tant que l'étape n'a pas changé et qu'aucun envoi ne l'a suivi ;
`peutEnvoyer`, `envoiBloque`), jamais un motif interne, toutes les clés d'avant
gardées (`M/20261022000000_cand_l2a1_moteur_salle_examen.sql:1763-1905`, `:2214-2301`) ; `PortMaCandidature` :
`conditions_remuneration_candidat()`, `questionnaire_salle_examen()` (champs,
listes fermées, dernières réponses, version du brouillon ouvert),
`enregistrer_reponses_salle_examen(...)` (brouillon : `versionAttendue` est la
version du brouillon, 0 sans brouillon ; refus `conflit_brouillon` ; rend la
version du brouillon, les champs manquants et `complet`, jamais les réponses,
relues par le questionnaire), `envoyer_reponses_salle_examen(...)` (transition 6 ;
porte la version des conditions affichées, refus `conditions_perimees` si elle a
changé, `conditions_indisponibles` sans politique complète),
`retrait_candidat(...)` (transition 17), chacune sous `versionAttendue` et
`cleIdempotence` (`M/20261022000000_cand_l2a1_moteur_salle_examen.sql:1914-2208`). Aucun nom de RPC ne contient « candidature » :
`etat_dossier()` reste la seule lecture de l'état du candidat (scénario de L1).
Le brouillon au serveur et les questions rouvertes après un complément sont des
choix à soumettre (0.2 bis, `CAND-F15`).

**Côté direction (Personnes, sauf `ADM-24`) :**

| Code | Écran | But | Bouton plein | États propres | Lot |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `ADM-20` | Candidatures (remplace l'onglet Invitations) | file dense : recherche, puces des salles avec compteur, autres axes sous « Plus » (dont responsable ; affectée ou non, en salle 3 ; sans activité depuis N jours, N dans `app_config`), tri au serveur, pagination, sélection multiple, quatre alertes, vue Entretiens | aucun ; « Agir sur la sélection » quand une sélection existe | recherche sans résultat (filtres rappelés) ; hors portée ; alertes à zéro | L1 ; gestes L2 |
| `ADM-21` | Candidature | dans l'ordre : étape et issue, blocages, prochaine action, réponses, contrôles nommés, pièce (lien `ADM-02`), entretien, responsable, affectation (lue dans les classes), historique | la prochaine action, une seule | bloquée (contrôle nommé) ; contact masqué ; hors portée ou absente ; paiement inconnu, à vérifier, compatible, incompatible | L1 ; gestes L2 ; entretien L4 |
| `ADM-21F` | Fil « Candidature » | conversation côté direction | envoyer | fil vide | L5 |
| `ADM-22` | Action groupée | liste ciblée (nom, étape, aucun contact), effet exact, exclus avec raison, saisie du nombre, rapport ligne par ligne | confirmer | jeton périmé ; nombre discordant ; lot partiellement refusé ; issue inconnue | L2 ; inviter L3 |
| `ADM-23` | Import des formulaires | réservé au super-admin (3.2) ; les huit pas de 3.2 ; route distincte de `/admin/personnes/import` | importer, au pas 7 | fichier illisible ; mappage incomplet ; doublons à choisir ; écart des compteurs ; double vérification requise | L3 |
| `ADM-24` | Compatibilité de paiement par pays (Finance, `DEC:85`) | référentiel | enregistrer | confirmation sans date ni responsable refusée ; impact (N restrictions) | L6 |
| `ADM-02` (existant, étendu) | revue de pièce | valider (entrée en salle 3), « à corriger », refus définitif | valider | contrôles manquants nommés ; validation refusée par le serveur | L2 |

**Contrat serveur côté direction, posé par L2A2 le 22/10** (`testé localement`) :
les gestes d'`ADM-21` sans entretien ni contrôles nommés (7, 10, 16 à 19, 23 à
25, 28) et l'action groupée d'`ADM-22` (aperçu, puis exécution sous jeton et
nombre saisi), décrits en 4.2. `capacites_candidatures()` gagne `peutDecider`
(direction active de genre connu), une capacité par geste, vraie pour les seuls
gestes que le serveur sait faire (`inviter`, `consignerPrevenu`, `rattacher`,
entretiens, pièce, restriction et indisponibilité restent faux), les gestes
groupables, et les listes fermées que l'écran propose (modèles du refus et de la
pause, éléments d'un complément par salle, canaux du retrait,
`M/20261022000100_cand_l2a2_gestes_direction.sql:1556-1637`) ; `lister_candidatures()` filtre
`paiement_non_disponible` et compte en informations manquantes le complément en
cours de salle 2 (`:1709-1882`) ; `lire_candidature()` rend aussi `pauseModele`, `refusModele` et `restrictionCause` ; l'aperçu de l'action groupée écrit une ligne d'audit comme une liste, sans nom. Le motif interne ne sort vers aucun compte :
ni dans le résultat d'un geste, ni dans un rapport de lot, ni dans
`etat_dossier()`.

**Quatre alertes d'`ADM-20`, jamais confondues** (`REVUE §10.2`) : bloquées
(contrôle faux nommé ou restriction) ; entretiens en retard ; informations
manquantes (`a_completer`, complément demandé en salle 2 jusqu'à sa clôture par la direction, « courriel à obtenir »,
« indicatif à confirmer ») ; confirmées indisponibles. Une pause n'entre dans
aucune. Le candidat qui ne répond pas (`SPEC §12.2`) se lit par le filtre « sans
activité depuis N jours », pas par une cinquième alerte. **Composants** :
`BarreSelection` à promouvoir du Comptable vers `lib/core/widgets/`, jamais
recopiée ; ligne d'historique neuve ; le reste réutilisé tel quel (`REVUE §10.3`).

---

## 11. Lots serveur

Tous sur la **base de test** ; aucune application en production sans le feu vert
du directeur (`DEC:25`). Chaque lot livre son fichier de scénarios, rejoué sur
Postgres nu. L'ajout à `.github/workflows/ci.yml` demande un ordre du directeur
(`.claude/hooks/garde.py:22-27`) ; d'ici là, `tool/rejouer_scenarios.sh`.

La décision d'`ADM-02` est fermée en production côté Flutter (`AD-M3-PROD`,
`lib/features/admin_dossiers/revue_dossier.dart:33-36`, `REVUE §0` point 2). Sa
réouverture en production fait partie du feu vert du directeur, après L2 et les
lots `langue` et `c11bis`.

| Lot | Contenu | `CAND-BR` | Questions | Statut au 21/10 | Prérequis |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **L1** socle | tables (type, candidature, questionnaire versionné, réponses, réponses importées) ; **forme en base du compte candidat** (rôle `teacher`, `pending_kyc`, la même pour le lien public et l'invitation, 3.1 ; complément CAND-L1B) ; lectures cloisonnées par genre (RLS, liste paginée et triée au serveur, détail, contact journalisé) ; historique sans nom | `01`, `02`, `03`, `07` | `Q02`, `Q04`, `Q07`, `Q20` | socle `présent dans le code` et `testé localement` (`M/20261021200000_cand_l1_socle_candidatures.sql`, `supabase/tests/scenarios_cand_l1_socle.sql`) ; forme du compte fixée par le complément CAND-L1B, repris après relecture (`M/20261021220000_cand_l1b_forme_compte_candidat.sql`, `supabase/tests/scenarios_cand_l1b_forme_compte.sql`, `supabase/tests/scenarios_cand_l1b_concurrence.sql`), `testé localement` ; ni staging ni production | - |
| **L2** transitions et contrôles | une RPC par geste ; les huit contrôles ; `decider_dossier()` : pour un profil porteur d'une candidature `enseignant`, validation acceptée seulement salle 2 terminée, les autres profils gardent l'approbation actuelle ; transaction d'entrée en salle 3 (2.2) ; garde `0089` étendue, vers `active` et `provisional_active` ; deux issues de pièce et levée de la restriction `piece` (transition 21) ; prédicat d'affectation qui refuse restriction et indisponibilité (4.3) ; lots ; `etat_dossier()` étendu, questionnaire, envoi, retrait ; sorte d'accord du cadre religieux, version requise publiée seulement après validation juridique et accord du directeur (section 9) ; conditions de rémunération lisibles en attente ; étape des accords en base (contrat et avis en salle 2, 2.1, après la réponse sur les accords en trois moments, 0.3) ; portée par genre des surfaces de la direction encore non bornées (0.3) | `04`, `05`, `06`, `10`, `11`, `12` | `Q01`, `Q08`, `Q11`, `Q18` | **L2A1** (moteur des gestes, questionnaire versionné et brouillon, transitions 6 et 17 par le candidat, sorte d'accord du cadre religieux sans version publiée, conditions de rémunération lisibles et leur accord, `etat_dossier()` étendu ; repris après relecture le 22/10 : journal d'audit et accords bornés par genre, brouillon sans effet sur la version de la candidature ni sur la déclaration de paiement, changements admis par geste, motif normalisé, accord lié aux conditions affichées, dimension paiement rendue au candidat, complément de salle 2 ; conditions de rémunération en pourcentages seulement, par la décision du directeur du 22/10, aucun montant ni devise rendu au candidat) : `présent dans le code` et `testé localement` le 22/10 (`M/20261022000000_cand_l2a1_moteur_salle_examen.sql`, `supabase/tests/scenarios_cand_l2a1_moteur_salle_examen.sql`), ni staging ni production. **L2A2** (gestes de la direction sans entretien ni contrôles nommés : transitions 7, 10, 16 à 19, 23 à 25, 28, chacune par le moteur, du côté de la direction ; action groupée d'`ADM-22` pour la pause, sa levée et le refus ; `capacites_candidatures()`, `lister_candidatures()` et `lire_candidature()` redéfinies, 4.2 et 10 ; repris après relecture le 22/10 : traces de l'action groupée avant tout refus rendu, jeton sous une clé du serveur, ligne d'audit de l'aperçu, rejeu après un changement de genre, réouverture d'une candidature en `paiement_non_disponible`, fin d'un complément de salle 2, un seul vocabulaire des gestes groupables, une seule carte `versement`, dossier relu avec les modèles et la cause de restriction) : `présent dans le code` et `testé localement` le 22/10 (`M/20261022000100_cand_l2a2_gestes_direction.sql`, `supabase/tests/scenarios_cand_l2a2_gestes_direction.sql`), ni staging ni production ; reste ouvert : l'état d'origine d'une réouverture après un entretien annulé (0.2 bis, avec L4) et le défaut hors module qui laisse une direction changer son propre genre (0.3) ; reste à écrire : contrôles nommés, salle 3, `decider_dossier()`, garde `0089` étendue, prédicat d'affectation, transitions 14, 15, 20 à 22, refus définitif de pièce, étape du contrat et de l'avis, portée des surfaces encore non bornées (`demandes_suppression_lister()`, `jetons_agent_actifs()`, message d'affectation refusée : L2B) ; `inviter`, `consignerPrevenu` et `rattacher`, groupables ou non (L3) | L1 (forme du compte) ; `CAND-BR-11` : L1 et lot `conduite` (`CORR §7`) ; prédicat d'affectation : lot `creer_groupe` |
| **L3** inscription publique et import | compte candidat ; courriel confirmé ; genre et téléphone obligatoires ; plafond horaire et réponse neutre ; clé de mise en ligne ; accord de confidentialité ; rattachement (courriel, téléphone, B) ; alignement de `inscrire_enseignant_invite` ; geste `inviter` ; reprise des invitations ; import ponctuel, rejouable, réservé au super-admin | `17`, `09`, part de `04` | `Q03`, `Q04`, `Q16`, `Q17` | à écrire | L1, L2 ; mise en ligne : SMTP d'authentification, `enable_confirmations`, feu vert (3.1, condition 6) |
| **L4** entretiens dans l'app | type `entretien`, forme de `teacher_id`, rôles, jeton du candidat convoqué, exclusions (paie, clôture, chevauchement, vues, contrôleur), mode sans mention, planification, constat, compte rendu | `08` | `Q06`, `Q07`, `Q08`, `Q09`, `Q19`, `Q22` | à écrire | L2 ; revue de sécurité (jeton, déclencheur de paie) |
| **L5** conversation, notifications, file des courriels | objet `candidature` dans la messagerie ; compte en attente admis pour cet objet ; notifications ; file `a_envoyer` | `18`, `16` | `Q06`, `Q07`, `Q10` | à écrire | L1 ; contrat de la file remis à la session du site public |
| **L6** référentiel de paiement | lignes (avec type de décaissement), droits, état initial déduit de `DEC:28`, liste des pays d'Afrique proposée avec sa source, déclencheur de restriction, transitions 8 et 9, alerte, part de `CPT-BR-10` | `13` | `Q05` | présent dans le code et testé localement le 21/10 (5.1), ni staging ni production ; lignes d'Afrique `en_verification` tant que `Q05` est ouvert ; gestes 24 et 25 en L2, notifications en L5 | L1 |
| Hors module | **PLAFOND** nombre maximal de Classes par enseignant, réglable par la direction (décision du 22/10) | réglage `enseignant.classes_max` (3 par défaut, 1 à 80, journalisé), vérifié par le prédicat d'affectation (`plafond_classes_atteint`), `classesSouhaitees` qui le suit | - | présent dans le code et testé localement le 22/10 (`M/20261022000200` et `M/20261022000300`), ni staging ni production ; reste l'écran du réglage et les phrases de refus du client | L2A1, prédicat de `creer_groupe` |
| Hors module | **AUTRES COMPÉTENCES** des candidats (« Vos autres talents », décision du 22/10) | `19` : catalogue `competences_catalogue` (25 compétences en six familles, journal en ajout seul, écrit par la direction seule) et table `candidature_autres_competences` (une ligne par candidature, RLS sans policy) ; `lire_autres_competences`, `enregistrer_autres_competences` (après l'envoi de la Salle d'examen, candidature en cours, version attendue, clé d'idempotence), `retirer_autres_competences` (à toute issue) ; `lire_catalogue_competences`, `enregistrer_competence_catalogue` ; `autresCompetences` dans `lire_candidature` et quatre filtres de `lister_candidatures` (domaine = code ou famille), dans la portée femmes et hommes | - (décision du 22/10) | présent dans le code et testé localement le 22/10 (`M/20261022000500_cand_autres_competences.sql`, `supabase/tests/scenarios_cand_autres_competences.sql`), ni staging ni production ; restent l'écran, les textes, le port Dart, la conservation (`Q21`) | L1, L2A1 (envoi, moteur d'idempotence), L2A2 (lectures redéfinies) |
| Transverse | conservation et anonymisation | `14` | `Q21` | en attente du juriste | - |
| Transverse | scénarios du module | `15` | - | un fichier par lot | ordre du directeur pour la CI |

**Ordre et parallèle.**
- Avant L6, `paiement_compatible` est faux pour tous : aucune candidature n'entre
  en salle 2. L6 est court ; il peut avancer en parallèle de L2 et doit être livré
  avant la première admission en salle 2.
- **Chemin critique.** La transition 6 (envoi du questionnaire) exige le cadre
  religieux à la version requise. Il faut donc, dans l'ordre : le lot `conduite`,
  le texte validé (section 9), puis `CAND-BR-11`, avant le premier envoi de
  questionnaire. Aucun candidat ne peut envoyer sa candidature avant.
- **Salle 3.** Aucune validation en salle 3 avant les lots `langue` et `c11bis`
  (puis `creer_groupe`) : sinon « affectable à 100 % » (`DEC:24`) est faux.

---

## 12. Recette

Un contrôle qui n'a pas tourné n'est pas vert. Chaque chiffre se mesure sur base
neuve et s'écrit. Fichiers proposés : `supabase/tests/scenarios_cand_l1.sql` à
`scenarios_cand_l6.sql`.

### 12.1 Scénarios SQL

| # | Cas | Attendu, mesuré |
| :-- | :--- | :--- |
| L1-1 | un candidat lit les candidatures | 1 (la sienne), 0 autre |
| L1-2 | une directrice, un directeur, le super-admin lisent la liste | 0 candidature d'homme pour elle, 0 de femme pour lui ; les deux côtés pour le super-admin ; 1 ligne `audit_logs` par lecture de liste |
| L1-3 | lecteur de genre inconnu | refus, 0 ligne |
| L1-4 | candidature hors portée, puis inconnue | deux erreurs distinctes, 0 donnée |
| L1-5 | colonnes de la RPC de liste ; appel de `lireContact` | 0 colonne courriel, téléphone, genre ou pièce ; 1 ligne de journal par appel |
| L1-6 | historique | 0 nom ; référence `CAND-` seulement |
| L1-7 | fixture `comptable` | 0 contrôle enseignant appliqué, et inversement |
| L1-8 | compteurs d'une directrice | son côté seulement |
| L1-9 | tri de la liste : clés égales sauf le compte bancaire ; puis clés différentes | compte bancaire devant ; puis ordre des clés, le compte bancaire sans effet |
| L2-1 | validation de pièce, un des sept contrôles faux | 7 refus, chacun nommé ; après chacun : pièce en attente, compte `pending_kyc`, étape inchangée |
| L2-2 | validation, les sept vrais, sans photo, sans `weekly_availability`, sans coordonnées financières | pièce `approved`, compte `active`, étape `confirmee`, langues et fuseau copiés dans `teacher_profiles`, en 1 transaction |
| L2-3 | activation par une autre voie (mise à jour de `account_status`), sans contrôles ; puis sans contrat ; puis passage manuel en `provisional_active` sans contrôles | 3 refus de la garde |
| L2-4 | entrée en salle 2 sans `paiement_compatible`, puis sans cadre religieux | 2 refus nommés |
| L2-5 | pièce « à corriger » ; refus définitif | étape inchangée ; issue `refusee`, 0 motif interne dans `etat_dossier()` |
| L2-6 | nouvelle pièce refusée d'une enseignante active, sans autre pièce approuvée | `disabled` (inchangé) et 1 restriction `piece` |
| L2-7 | lot de 10 pauses dont 3 sur des candidatures `refusee` | 7 réussies, 3 exclues avec raison, 3 inchangées |
| L2-8 | même clé d'idempotence rejouée ; version périmée | 1 effet ; 0 écriture |
| L2-9 | geste en pause autre que lever, refuser, retirer | refus |
| L2-10 | chaque geste marqué « oui » en 4.2, sans motif | refus, 0 écriture |
| L2-11 | chaque transition | 1 ligne `audit_logs` ; chaîne vérifiable |
| L2-12 | après L2-2, `tc_verifier_affectation_enseignant` pour une classe de la langue et du genre de la personne | aucune erreur levée |
| L2-13 | approbation d'une pièce de tuteur `pending_kyc` | compte `active`, comme avant |
| L2-14 | confirmée indisponible ; puis enseignant actif sans candidature | affectation refusée, étape inchangée ; affectation acceptée |
| L2-15 | confirmée en restriction ; puis restriction levée | affectation refusée ; puis acceptée |
| L2-16 | après L2-6 : nouvelle pièce déposée par le compte `disabled`, approuvée, restriction levée | compte `active` et affectable, en 1 transaction ; 1 ligne de journal |
| L2-17 | rouvrir une candidature refusée, un contrôle de l'étape faux | `ControlesNonSatisfaits` nommé ; 0 écriture |
| L2-18 | complément demandé en salle 2 | même état ; comptée dans « informations manquantes » ; 1 notification |
| L2-19 | contrat `teacher_nda` ou avis accepté par un candidat en salle d'examen | refus ; 0 ligne `contract_acceptances` |
| L2-20 | une directrice et un directeur lisent le journal d'audit, les demandes de suppression et les jetons d'agent, avec un candidat de chaque côté | 0 nom de candidat de l'autre côté ; les deux côtés pour le super-admin |
| L2-21 | aperçu ou exécution d'un lot dont un identifiant est de l'autre côté, quel que soit le refus rendu (geste non groupable, motif, modèle, date de reprise, jeton, nombre, clé reprise), super-admin compris | 1 événement `lecture_hors_portee` et 1 ligne d'audit par identifiant et par appel ; 0 écriture sur la candidature ; un identifiant inconnu rend la même réponse |
| L2-22 | jeton calculé par le client (ancienne empreinte md5), jeton d'un autre auteur ; aperçu relu | `jeton_perime`, 0 écriture ; jeton stable pour un même auteur et un même lot, jamais la clé du serveur ; 1 ligne d'audit par aperçu, sans nom |
| L2-23 | lot et geste seul rejoués après un changement de genre de leur auteur ; puis le genre rendu | `hors_portee` et une trace par identifiant ; puis le premier rapport |
| L2-24 | candidature refusée en `paiement_non_disponible`, une ligne passe `confirme`, puis réouverture (19) | transition 9 : `a_completer`, carte `versement`, marqueur `paiement_possible` ; sans ligne confirmée, elle reste en `paiement_non_disponible` |
| L2-25 | complément de salle 2 clôturé (`complement_clos`), clôturé de nouveau, puis un complément neuf | `complementDemande` à `[]` et compteur diminué de 1 ; `aucun_complement` ; compteur augmenté de 1 |
| L2-26 | chaque valeur de `gestesGroupables` donnée à l'aperçu et à l'exécution ; `lire_candidature` après une pause, un refus, une restriction | le code du moteur rendu ; `pauseModele`, `refusModele`, `restrictionCause` rendus comme le geste les a rendus |
| L2-27 | questionnaire du 22/10 : plus de dix langues d'explication, sans l'arabe ni `ff`, avec `autre` ; langue maternelle absente ; mémorisation (4 valeurs) et ijaza (3) séparées ; une à quatre tranches d'âge ; 1, 2 ou 3 classes ; anciens codes (`pret_a_un_test`, `enfant`, `adulte`, `heuresParSemaine`) | acceptés ou refusés, champ nommé, 0 écriture ; `questionnaire_complet` complet / incomplet en conséquence |
| L2-28 | `moyensAccessibles` : mêmes réponses avec et sans ; une ligne mobile money confirmée ; un opérateur retiré du catalogue | paiement identique ; l'opérateur seul dans `moyensAccessibles` ne rend pas `a_verifier` ; admission non bloquée ; une seule fonction nomme la clé |
| L3-1 | inscription sans courriel confirmé | 0 candidature |
| L3-2 | inscription au-delà du plafond horaire de `app_config` | refus |
| L3-3 | inscription par le lien | 1 compte `pending_kyc` ; 0 capacité enseignant ; jeton de cours refusé ; 0 apparition dans une liste d'enseignants |
| L3-4 | essai à blanc sur A, par le super-admin | 0 écriture ; compteurs rendus ; écart avec 440 lignes et 409 personnes lu avant de confirmer |
| L3-5 | confirmation de l'import, puis second import identique | 0 ligne dans `profiles`, `invitations_enseignant`, `kyc_documents`, `contract_acceptances` ; 0 ligne de candidature, `recue` comprise ; N réponses importées ; puis 0 ajout |
| L3-6 | B | 11 lignes `dejaConnue`, 0 écriture |
| L3-7 | rattachement par courriel confirmé, par téléphone seul, par nom | pré-remplissage ; 0 donnée montrée et 1 proposition à la direction ; 0 |
| L3-8 | lot de 10 invitations dont 3 sans courriel valide | 7 codes émis, 7 courriels `a_envoyer`, 3 exclues, 3 inchangées |
| L3-9 | invitation expirée | retour en `recue`, trace gardée |
| L3-10 | colonne J (créneaux) importée | aucun champ `disponibilitesDeclarees` pré-rempli (aucun jour) ; libellé d'origine gardé tel quel dans la réponse importée ; 0 ligne `weekly_availability` |
| L3-11 | groupe de doublons sans choix | reste « à corriger » ; 0 fusion |
| L3-12 | inscription avec un courriel neuf et le téléphone d'une réponse importée | 1 proposition à la direction ; 0 donnée montrée au candidat |
| L3-13 | inscription sans genre | refus ; 0 profil |
| L3-14 | seconde candidature du même compte, même type | refus |
| L3-15 | une directrice lance l'essai à blanc sur A | refus ; 0 nom ni réponse d'homme rendu |
| L3-16 | réimport d'une ligne corrigée | 0 réponse nouvelle ; 1 correction tracée sur la même référence source |
| L3-17 | inscription avec un courriel existant ; puis au-delà du plafond | même réponse que le succès, deux fois |
| L3-18 | inscription sans code, clé de mise en ligne fausse ; puis vraie | refus ; acceptée |
| L3-19 | personne de B, courriel confirmé | reconnue ; 0 champ pré-rempli |
| L4-1 | jeton d'entretien : candidat convoqué à l'ouverture, avant l'ouverture, autre candidat | accepté, refusé, refusé |
| L4-2 | séance d'entretien close | 0 ligne `tresorerie_mouvements` ; 0 clôture automatique ; 0 ligne `mes_seances_v` ; 0 conflit de chevauchement ; 0 observation du contrôleur |
| L4-3 | intervieweur de la direction de l'autre côté ; super-admin de l'autre côté ; super-admin du même côté | refus ; refus ; accepté, 1 ligne de journal |
| L4-4 | fuseau du candidat inconnu | planification refusée |
| L4-5 | `tenu` sans compte rendu ; `annule` sans motif ; retour à `entretien_a_planifier` | refus ; refus ; issue gardée |
| L5-1 | candidat `pending_kyc` et son fil `candidature` ; autres objets | lecture et écriture ; 0 accès |
| L5-2 | une directrice et le fil d'un candidat homme | 0 accès |
| L5-3 | planification d'un entretien | 1 notification et 1 courriel `a_envoyer` |
| L5-4 | paramètres des courriels de refus et de pause | 0 motif interne |
| L5-5 | un candidat lit la file des courriels | 0 ligne |
| L5-6 | la direction tente de passer un courriel à `envoye` | refus |
| L5-7 | un candidat lit les notifications | 0 notification hors de sa candidature |
| L6-1 | Arabie saoudite, compte bancaire oui, moyen confirmé | `compatible` ; admission en salle 2 acceptée |
| L6-2 | hors d'Afrique, compte bancaire non | `incompatible`, `paiement_non_disponible`, issue `en_cours` |
| L6-3 | Afrique, compte bancaire oui, `Q05` ouvert | `incompatible` |
| L6-4 | ligne `en_verification` | 0 cas `compatible` |
| L6-5 | `confirme` sans date ni responsable | refus |
| L6-6 | ligne passée `indisponible` | K restrictions pour les K personnes en salle 3 qui n'avaient qu'elle ; 0 changement pour qui garde un autre moyen confirmé par la direction sur une ligne `confirme` (0.2 bis) ; `impact` = K, dans la portée du lecteur |
| L6-7 | un candidat lit le référentiel | 0 ligne non confirmée, 0 note interne |
| L6-8 | pays de fixture, compte bancaire non, ligne `mobile_money` `confirme`, moyen confirmé | `compatible` ; admission en salle 2 acceptée |
| L6-9 | ligne passée `confirme` | candidatures `paiement_non_disponible` du pays en `a_completer` ; 1 notification et 1 courriel chacune |
| L6-10 | candidat `en_examen` dont la seule ligne quitte `confirme` ; puis moyen infirmé par la direction | `paiement_non_disponible` ; puis `paiement_non_disponible` avec motif tracé |

Mesure L6 du 21/10, reprise après relecture
(`scenarios_cand_l6_referentiel_paiement.sql`, base neuve) : 146 contrôles verts,
L6-1 à L6-10 compris. L6-1 et L6-8 mesurent le contrôle `paiement_compatible` que
lira l'admission (transition 10, geste de L2). L6-6 mesure K = 4 au journal, dont
une personne à colonne `paiement` périmée et une qui n'a plus qu'un moyen non
confirmé ; l'impact rendu vaut 2 pour chaque direction (son côté), 4 pour la
comptabilité et pour l'exception super-admin (journalisée). L6-9 mesure un
événement de transition 9 par candidature, marqué `aNotifier` = `paiement_possible` ;
la notification et le courriel sont de L5. L6-10, second temps : la décision
d'infirmation est écrite comme le fera le geste 25 de L2, puis recalculée. Le
scénario mesure aussi : une écriture directe dans la table (mêmes effets, journal
sans auteur), la clé de l'Afrique (refusée à une direction et au propriétaire par
`app_config`, ouverte et refermée par la table des décisions, refermeture refusée
tant qu'une ligne d'Afrique est `confirme`), la direction au genre inconnu
refusée, le compte candidat désactivé ou expiré refusé (L1-08).

Mesure L2A1 du 22/10, reprise après relecture (`supabase/tests/scenarios_cand_l2a1_moteur_salle_examen.sql`, base neuve) : 245 contrôles verts (243 avant la décision du directeur du 22/10 sur les conditions de rémunération : les contrôles des montants et de la devise sont devenus des contrôles qu'aucune clé de montant n'est rendue, et la partie « un taux ou une part changés » en compte deux) ; joué sur la migration d'avant cette décision, il rend 3 contrôles rouges (la forme des publics, l'absence de tout montant et de toute devise, un taux changé en base qui ne change plus la réponse) ; 0 sans la
migration (le scénario s'arrête à sa préparation : `relation
"public.candidature_gestes" does not exist`), et 0 non plus avec la version
d'avant relecture (`relation "public.candidature_brouillon_cles" does not
exist`). L2-8 : la même clé rejouée rend le premier résultat avec 0 écriture
(brouillon, envoi, retrait, geste de la direction) ; une version périmée rend
`conflit_candidature` (ou `conflit_brouillon` pour un brouillon) et 0 écriture.
L2-9 : les vingt-six variantes de la table des règles, chacune depuis sa source et
en pause ; vingt-trois refusées (`transition_interdite`, raison `pause`, 0
écriture), lever la pause, refuser et retirer ouverts. L2-10 : les onze variantes
à motif, depuis leur source, sans motif, avec un motif fait d'espaces, de
tabulations et de fins de ligne, ou d'espaces Unicode (insécable, largeur nulle,
idéographique) : refus, 0 écriture ; sans modèle pour refuser et mettre en pause :
`modele_requis` ; un motif entouré de blancs est gardé sans eux. L2-11 : une ligne
`audit_logs` par transition (6, 7, 8 de L6, 16, 17, 18, 23, 28), candidature par
candidature, et `verifier_chaine_audit` ne trouve aucun maillon rompu. L2-5 en
partie : refus par le moteur, motif interne dans l'événement seulement ;
`etat_dossier()` du candidat rend le modèle du refus, 0 motif. Le scénario mesure
aussi, depuis la relecture : une candidate qui envoie puis se retire n'a aucune
ligne lue par la direction des hommes (`journal_audit`, `journal_audit_filtres`,
lecture directe d'`audit_logs`, `contract_acceptances`), ni par une direction au
genre inconnu ; la direction des femmes la lit sous sa référence `CAND-`, jamais
son nom ; le super-admin la lit par le journal, journalisé, jamais par la lecture
directe ; la forme ensembliste du côté d'une ligne et sa forme ligne à ligne
concordent sur tout le journal ; vingt-cinq brouillons ne changent pas la version
de la candidature, ne gardent qu'une clé, aucune réponse sous une clé, ne
déclarent aucun paiement, et une pause posée à la version lue avant eux passe ; la
transition 7 nomme le complément, que le renvoi lève ; la transition 23 le nomme en
salle 2, où un cadre à une version requise non acceptée est à compléter ; un
changement non admis par le geste (22023) et un responsable hors de la direction
active du même côté (42501) sont refusés, un responsable du même côté est tracé
avant et après ; un envoi aux conditions périmées et un envoi sans part de
l'enseignant en base sont refusés ; la dimension paiement est rendue au candidat.
Contre-épreuve par mutation : chaque correction de la relecture, défaite une à
une dans une copie de la migration (dix-huit mutations), fait tomber le scénario
sur le contrôle qui la vise. Il mesure toujours : les listes fermées
(dix-huit valeurs hors liste refusées, champ nommé, 0 écriture), la transition 6
impossible sans cadre publié puis sans cadre accepté, le recalcul du paiement
(Arabie saoudite : `a_verifier` ; Nigeria : transition 8), le retrait depuis
`paiement_non_disponible`, la portée par genre des gestes (direction de l'autre
côté et super-admin : `hors_portee` tracé ; genre inconnu : 42501), et des
conditions de rémunération lues en base (une part changée en base change la
réponse ; un taux changé ne la change plus, aucun montant n'étant rendu). Coût mesuré sur 100 000 lignes d'audit : une page de
`journal_audit()` en quelques millisecondes ; `journal_audit_filtres()` en
environ 0,3 s, contre 0,1 s avant le lot. Rejeu complet du 22/10 à 02:51 UTC :
118 scénarios verts sur 119 (`af_liste_blanche_volatiles` rouge connu, antérieur :
les quatre fonctions `avis_*` seulement).

Reprise du 22/10 selon les réponses du directeur sur le questionnaire (section 1 ter de
`C/DECISION-CANDIDATURES-2026-10-21.md` ; `présent dans le code`, `testé localement`, ni
staging ni production ; `salle-examen-1` n'étant appliquée nulle part, la définition est
corrigée sur place). **L2A1 : 334 contrôles verts** (245 avant : 89 de plus) sur base
neuve ; **L2A2 : 236** (232 avant : 4 de plus, ses fixtures suivent le nouveau
questionnaire ; 358 et 244 avec le lot CLASSES-PLAFOND relu, L2-29) ; les quatre autres scénarios du module (L1, L1B, L1B concurrence, L6)
sont inchangés et verts. **Rejeu complet : 119 scénarios verts sur 120**
(`af_liste_blanche_volatiles` rouge connu et antérieur à ce lot, les quatre fonctions
`avis_*` seulement ; même résultat avant le lot). Les deux scénarios joués sur les
migrations d'avant la reprise rendent un premier rouge net (L2A1 : « 17 champs » ; L2A2 :
l'admission, ses fixtures n'étant plus des réponses complètes). **Contre-épreuve par
mutation**, huit altérations de copies des migrations, base neuve : la lecture de
`exclure` retirée (le scénario refuse que l'arabe soit accepté comme langue de cours) ; un
plafond de dix langues rétabli (les deux jeux de réponses complètes tombent) ; le paiement
qui lit `moyensAccessibles` comme des opérateurs (la contre-épreuve « mêmes réponses avec
et sans » tombe) ; l'exclusion de `moyensAccessibles` retirée du contrôle
`questionnaire_complet` (L2A2 : `complet` devient `incomplet`) ; `ff` remis dans la liste
(les options des langues) ; l'ijaza privée de `pret_test` (le scénario) ; et, pour la
langue maternelle obligatoire et pour l'ijaza sans `pret_test`, le garde de fin de
migration, qui refuse la migration avant tout scénario (« le questionnaire courant
diffère des réponses du directeur »). Les gardes F86, les droits et l'inventaire des
policies sont inchangés : la reprise ne touche que des aides privées et la définition.

Reprise du 22/10, disponibilités heure par heure (C18, 2.1 bis ; `présent dans le code`,
`testé localement`, ni staging ni production ; `salle-examen-1` corrigée sur place).
**L2A1 : 417 contrôles verts** (358 avant : 59 de plus) sur base neuve ; **L2A2 : 244**
(inchangé, ses fixtures suivent la nouvelle forme du champ) ; les autres scénarios du
module sont inchangés et verts. **Rejeu complet : 120 scénarios verts sur 121**
(`af_liste_blanche_volatiles` rouge connu et antérieur à ce lot, les quatre fonctions
`avis_*` seulement). **Contre-épreuve par mutation**, sept altérations d'une copie de la
base du rejeu, chacune fait tomber le scénario de L2A1 sur une ligne nommée : l'ancien
validateur rétabli (il accepte l'ancienne forme à second fuseau) ; le contrôle de
chevauchement retiré ; les demi-heures de nouveau admises ; l'examen privé de la cause
nommée (`motifs`, l'ancien examen) ; deux plages qui se touchent traitées comme un
chevauchement ; le chevauchement calculé sans comparer les jours ; la vérification « fin
après début » retirée. Le constat du cours de 90 minutes (2.1 bis) était une expérience
jetable sur le prédicat ; il est corrigé et gardé comme scénario par le lot `CLASSES-DUREE`
(`supabase/tests/scenarios_classes_duree_affectation.sql`, 2.1 bis).

Mesure L2A2 du 22/10, reprise après relecture (`supabase/tests/scenarios_cand_l2a2_gestes_direction.sql`,
base neuve) : 232 contrôles verts (193 avant la relecture : la section (o) en ajoute 39 et en
corrige deux). Joué sur la migration d'avant la reprise (copie des deux
migrations de la validation précédente, base neuve), le scénario rend 32
contrôles rouges, 3 erreurs et un décompte final faux (191 contrôles sur 232), le
bloc des droits (F86) mis à part, rouge lui aussi (`lire_candidature`, neuf aides
internes, clé des jetons). Sans la migration, le scénario s'arrête après
son premier contrôle (les fixtures) : `function
"public.demander_complement_candidat(uuid,text[],text,integer,text)" does not
exist`. Contre-épreuve par mutation : dix-neuf défauts introduits un à un dans une
copie de la migration (liste des modèles, compteur de salle 2, jeton, nombre,
contrôles de l'admission et de la réouverture, cadre en salle 2, version du
questionnaire, ligne `en_verification`, isolement des lignes d'un lot, trace hors
portée d'un lot, éléments du complément, responsable, date du retrait, geste non
groupable, rejeu d'un lot, capacité du référentiel, filtre `etat`, recalcul à la
réouverture) : chacun fait tomber le scénario. Ce qu'il mesure :
- L2-4 : sans paiement compatible ni cadre publié, deux contrôles nommés ; puis
  paiement confirmé (24), cadre publié non accepté : `cadre_religieux`
  `non_accepte` ; questionnaire envoyé à une version périmée : nommé ; après un
  envoi réel (transition 6), refus tant que le moyen n'est pas confirmé, puis
  admission, 0 écriture à chaque refus.
- L2-7 : un lot de 10 pauses dont 3 sur des candidatures `refusee` : 7 réussies, 3
  exclues avec leur raison (`transition_interdite`, `etat`), 3 inchangées ; un
  aperçu suivi d'un geste sur une candidature du lot rend `jeton_perime` ; nombre
  discordant, jeton inventé ou d'un autre auteur, motif ou modèle absents ou hors
  liste : rien n'est écrit ; une levée en lot exclut sans donnée une candidate de
  l'autre côté (trace à l'aperçu et à l'exécution) et un identifiant inconnu ; un
  refus en lot dont une ligne bute sur une clé déjà prise et une autre sur une
  erreur garde la réussite voisine ; `inviter`, `consigner_prevenu` et cinq
  autres gestes rendent `geste_non_groupable`.
- L2-8 : chaque geste rejoué avec sa clé rend le premier résultat, même à
  l'ancienne version, sans écriture ; un lot aussi ; une clé de lot reprise pour
  d'autres candidatures ou par un autre auteur est refusée ; une version périmée
  rend `conflit_candidature`.
- L2-9 : pendant une pause, le complément, l'admission, la confirmation et
  l'infirmation d'un moyen, le responsable et une seconde pause sont refusés
  (raison `pause`, 0 écriture) ; le refus et le retrait par la direction restent
  ouverts et lèvent la pause.
- L2-10 : sept gestes à motif (7, 23, 16, 17, 18, 19, 25), chacun sans motif puis
  avec des espaces, des tabulations et fins de ligne, ou des espaces Unicode :
  `motif_requis`, 0 écriture ; un motif entouré de blancs est gardé sans eux.
- L2-11 : une ligne `audit_logs` par transition du moteur, candidature par
  candidature (50 gestes de ce lot), chaîne vérifiée sans maillon rompu ; ces
  lignes ne se lisent que du côté de la candidature (C15 de L2A1).
- L2-17 : rouvrir en salle 2 sans paiement, sans cadre, sans questionnaire envoyé :
  trois contrôles nommés ; un compte désactivé : `compte_conforme` `statut` ; un
  questionnaire périmé : nommé ; 0 écriture ; rouverte, la candidature retrouve
  son étape et son état, et une candidature d'Afrique repasse par la transition 8.
- L2-18 : un complément en salle 2 laisse l'état, compte dans les informations
  manquantes (le compteur et `etat_dossier()` lisent le même complément) ; une
  pause l'en retire, la levée l'y remet. La notification est de L5.
- L2-21 (relecture du 22/10) : un lot dont un identifiant est de l'autre côté
  laisse une trace (un événement `lecture_hors_portee`, une ligne d'audit) par
  identifiant et par appel, quel que soit le refus rendu : geste non groupable à
  l'aperçu et à l'exécution, motif, modèle absent ou hors liste, date de reprise
  passée, jeton inventé, jeton calculé par le client, identifiant inconnu à côté,
  super-admin, geste mal formé, nombre discordant et aucun éligible (avec un
  jeton valide), clé reprise pour d'autres identifiants ; la trace nomme la
  lecture (`lot:inviter`, `lot:inconnu`), jamais le texte reçu ; la candidate
  reste intacte, aucun rapport n'est gardé. L'exécution avec le jeton d'un autre
  auteur, depuis l'autre côté, rend `jeton_perime` et trace chaque candidature.
- L2-22 : l'ancienne empreinte md5 de l'auteur, du geste et des versions est
  refusée (`jeton_perime`, 0 écriture, 0 rapport) ; le jeton est stable pour un
  même auteur et un même lot, autre pour une autre direction, et la clé du
  serveur n'apparaît pas dans la réponse de l'aperçu ; un aperçu écrit une ligne d'audit
  (`reader_gender`, `geste`, `nombre`, `exclus`, `hors_portee`), sans nom, aucune
  pour un geste non groupable.
- L2-23 : le lot et le geste seul d'une direction, rejoués après le changement
  de son genre, rendent `hors_portee` (le lot retrace chaque identifiant) ; le
  genre rendu, le même lot rend son premier rapport.
- L2-24 : une candidature refusée en `paiement_non_disponible` pendant qu'une
  ligne passe `confirme` (le déclencheur de L6 ne la voit pas, la candidature
  voisine en cours passe `a_completer`) est rouverte en `a_completer`, paiement
  `a_verifier`, carte `versement` nommée, marqueur `paiement_possible`, et le
  candidat peut de nouveau répondre ; sans ligne confirmée, elle reste en
  `paiement_non_disponible`, ni transition 8 ni 9.
- L2-25 : un complément de salle 2 clôturé par `complement_clos` (transition 23,
  liste vide, sans marqueur de notification) : `complementDemande` à `[]`, la
  candidature sort des informations manquantes ; clôturé de nouveau :
  `aucun_complement` ; mêlé à un autre code, en Salle d'examen ou sans motif :
  refusé, 0 écriture ; un complément neuf se demande ensuite.
- L2-26 : chacune des trois valeurs de `gestesGroupables` est acceptée par
  l'aperçu, et `mettreEnPause` et `leverPause` par l'exécution, qui rend le code
  du moteur ; `lire_candidature` rend `pauseModele`, `refusModele` et
  `restrictionCause` comme le geste les a rendus, et l'autre côté reste
  `hors_portee` ; la transition 9 ne nomme que des cartes de la liste fermée ;
  le refus puis la réouverture d'une candidature en entretien planifié notent
  `entretienPlanifie` puis rendent `entretien_planifie` (comportement figé pour L4, 0.2 bis).
- L2-27 (reprise du 22/10, réponses du directeur, `salle-examen-1` corrigée sur place) :
  `languesExplication` sans `max` (27 options choisies ensemble, treize à l'envoi
  du Nigeria), ni `ar`, ni `ff`, ni `peul` ; `langueMaternelle` facultative, avec `ar`
  (28 options) ; poular une seule fois, en tête, `autre` en dernier une seule fois ;
  mémorisation `aucune`, `moins_10_juz`, `de_10_a_29_juz`, `coran_entier` et ijaza
  `oui`, `pret_test`, `non`, tous acceptés, les anciens codes refusés ; `publics`
  `6_9`, `10_13`, `14_17`, `adultes` (une à quatre, sans doublon, aucun ancien code) ;
  `classesSouhaitees` `1`, `2`, `3` proposés au maximum de trois (`0`, `81`, un nombre ou une liste
  refusés ; l'écran suit ensuite le réglage de la direction, L2-29) ;
  `heuresParSemaine` refusé comme clé inconnue ; trente-neuf valeurs invalides au total,
  chacune refusée avec son champ nommé, 0 écriture ; la forme de la définition (clé
  `exclure` réservée aux listes de langues, codes de langue ISO 639 ou `autre`, codes de
  valeurs pouvant ouvrir par un chiffre, listes nommées) est vérifiée par sa contrainte.
  Le contrôle `questionnaire_complet` de L2A2 rend `complet` sans langue maternelle et avec
  treize langues, `incomplet` pour un ancien code d'ijaza, l'arabe pour seule langue, des
  heures à la place des classes, un ancien code de public.
- L2-28 : memes réponses avec et sans `moyensAccessibles` (Arabie saoudite et Nigeria) :
  même déclaration (trois clés), même dimension ; sans compte bancaire ni opérateur
  déclaré, cocher les trois moyens connus laisse `incompatible` ; avec une ligne
  `confirme` posée puis annulée (Turquie, Wave), Wave dans `operateurs` rend `a_verifier`,
  dans `moyensAccessibles` il laisse `incompatible` comme sans rien ; un opérateur
  désactivé du catalogue n'est plus proposé ni accepté ; un moyen accessible invalide
  n'empêche ni `questionnaire_complet` ni l'admission de bout en bout (candidature 32 de
  L2A2) ; la seule fonction qui nomme la clé est l'exclusion du contrôle.
- L2-29 (22/10, lot CLASSES-PLAFOND, `M/20261022000300_cand_classes_souhaitees_suit_le_plafond.sql`,
  repris après relecture) : l'**écran** de `classesSouhaitees` suit le nombre maximal de Classes par
  enseignant sans nouvelle version (maximum 5 : `1` à `5` ; maximum 2 : `1` et `2` ; maximum 1 : `1` ;
  maximum 80 : quatre-vingts options) ; l'**examen** n'en dépend pas : il accepte tout entier de `1` à
  `80`, la borne du réglage, quel que soit le maximum en vigueur (`1`, `3`, `4`, `5` et `80` acceptés,
  `0` et `81` refusés aux maximums 3, 5, 2, 1 et 80), et refuse `00`, `01`, `+3`, `3.0`, ` 3`, `trois`,
  `-1`, `100`, `1e1` et le vide. Raison : le même examen relit les réponses déjà envoyées
  (`etat_dossier()`, contrôle `questionnaire_complet` de L2A2) ; une réponse valide le jour de l'envoi ne
  doit jamais devenir invalide par un réglage de la direction. La première version de ce lot acceptait
  les valeurs de la définition et `1..maximum` : `5`, valide au maximum de 5, redevenait invalide à 4 et
  bloquait l'admission (reproduit à la relecture). Le contrôle `questionnaire_complet` rend `complet` pour
  `3`, `5` et `80` et `incomplet` pour `81` aux maximums 3, 5, 4, 3, 2, 1, 80 et 4 ; aucun autre champ à
  valeurs fermées n'accepte `4`. Le souhait est une indication : le serveur ne refuse qu'à l'affectation
  (24 contrôles de plus dans L2A1, 8 dans L2A2).
- PLAFOND (22/10, lot CLASSES-PLAFOND, `testé localement`, `M/20261022000200_classes_plafond_par_enseignant.sql`,
  `supabase/tests/scenarios_classes_plafond_par_enseignant.sql`, 78 contrôles) : le réglage
  `enseignant.classes_max` vaut 3 par défaut ; trois Classes de suite passent par `creer_groupe`, la
  quatrième est refusée `plafond_classes_atteint` (P0001, détail « classes actives : 3 ; maximum : 3 »)
  sans classe ni séance en reste ; l'affectation d'une classe en attente (c11bis) et les deux
  prédicats refusent de la même façon, la classe reste en attente ; un enseignant au-dessus du maximum
  (quatre Classes de données antérieures) se voit refuser la suivante et garde les siennes ;
  revalider la Classe qu'il tient déjà ne la compte pas deux fois ; la proposition d'enseignants
  d'une classe en attente écarte ceux qui sont au maximum ; la direction monte (4), baisse (2) puis
  rend (3) le maximum et le serveur suit à chaque fois, le journal des réglages gardant 3 vers 4,
  4 vers 2, 2 vers 3 avec l'auteur ; zéro, 81, un négatif, un décimal, un texte, un booléen, un null,
  une liste et un objet sont refusés (22023) sans trace, 3.0 s'écrit 3 et 4.0 s'écrit 4 dans le
  journal, les bornes 1 et 80 passent ; la clé ne se renomme ni ne s'efface ; une Classe close ne
  compte pas ; un remplacement ponctuel ne compte pas et n'est pas refusé au maximum ; les refus
  existants gardent leur message et leur priorité (collision, plafond horaire, enseignant inconnu) ;
  ni un enseignant, un tuteur, un comptable, un élève, une direction désactivée, l'agent en lecture
  seule, ni un visiteur ne change le réglage (0 ligne ou refus de droit), et un enseignant ne le lit pas ; trois fonctions
  seulement écrivent `groupes.teacher_id` et toutes passent par le prédicat ; la surcharge à six
  arguments de `creer_groupe`, `attribuer_eleve` et `prendre_eleve` restent fermées aux comptes
  connectés ; la direction n'écrit pas `groupes` directement. Contre-épreuve de simultanéité, faite à la
  main et hors suite : deux directions qui donnent chacune une Classe au même enseignant (deux
  sessions) sont refusées l'une après l'autre (trois Classes au final) ; avec le contrôle placé avant
  le verrou par enseignant, la seconde passe (quatre).
- DUREE (22/10, lot CLASSES-DUREE, `testé localement`, `M/20261022000400_classes_affectation_couvre_toute_la_duree.sql`,
  `supabase/tests/scenarios_classes_duree_affectation.sql`, 108 contrôles après la relecture ; 2.1 bis) : un cours
  d'enfants de 60 minutes est couvert par une heure ; un cours d'adultes de 90 minutes est
  **refusé** avec la seule heure 18, avec la seule heure 19, avec les heures 18 et 20 (un trou),
  **accepté** avec 18 et 19 (le cas constaté : un enseignant disponible de 18 h à 20 h) et avec
  18, 19 et 20 ; la séance qui passe minuit demande l'heure 0 du **jour suivant** (mercredi
  23 h : jeudi 0 h ; refusé avec l'heure 0 du mercredi ou la seule heure 0 du jeudi) et, le
  dimanche, l'heure 0 du **lundi** (refusé avec l'heure 0 du dimanche) ; un cours d'enfants de
  23 h à minuit pile ne touche pas le jour suivant ; autre fuseau que la Classe, les deux
  saisons : Riyad (UTC+3 sans changement d'heure) pour une Classe d'adultes de 18 h à Paris veut
  les heures 19, 20 **et** 21 (19-20 ne couvre que l'été, 20-21 que l'hiver), pour une Classe
  d'enfants 19 et 20 ; Calcutta (UTC+5:30, grille à la demi-heure des heures de Paris) veut
  21, 22 et 23, et l'ancien test d'une seule ligne le refusait toujours ; la durée vient de
  l'offre quand la Classe en a une (Classe d'enfants née d'une offre de 90 minutes : deux
  heures ; Classe d'adultes née d'une offre de 60 minutes : une heure) et suit le réglage du
  public sinon (la direction passe les adultes à 120 puis 150 minutes, le serveur suit à chaque
  fois, la Classe née d'une offre de 60 minutes garde 60 ; un réglage à 0 refuse, sans repli sur
  60, sans toucher une Classe d'enfants) ; les refus de compte, de langue et de genre gardent la
  parole avant la durée ; collisions avec la durée de chaque Classe (une Classe d'adultes de 18 h
  chevauche un cours d'enfants de 19 h, une Classe d'enfants de 18 h ne chevauche pas un cours
  d'adultes de 19 h, un cours d'adultes de 17 h chevauche la Classe d'enfants de 18 h ; une
  séance ponctuelle qui commence à 19 h 10 chevauche un cours d'adultes de 18 h, pas un cours
  d'enfants) ; plafond horaire avec la durée de chaque Classe (trois séances d'adultes, 4 h 30,
  dépassent 3 heures, trois séances d'enfants tiennent ; les deux séances d'adultes déjà tenues
  comptent 3 heures, celles d'enfants 2 heures) ; le plafond de Classes `plafond_classes_atteint`
  parle après la base (l'enseignant à trois Classes sans disponibilité reçoit d'abord
  `enseignant non disponible`) et le verrou « teacher-schedule » est pris ; par les vraies RPC :
  `enseignants_pour_classe` propose l'enseignant des heures 18 et 19 pour une Classe d'adultes de
  18 h et pas celui de la seule heure 18 ni celui du trou, `affecter_enseignant_classe_c11bis`
  refuse l'un et l'autre (la Classe attend toujours, sans séance) et accepte le premier,
  `creer_groupe` crée sans disponibilité déclarée (D4) et refuse ensuite une collision de durée.
  **Contre-épreuve** : sur la base du rejeu avec la seule fonction de durée (le prédicat d'avant),
  le scénario est rouge sur 23 contrôles avant de s'arrêter sur l'affectation par
  `affecter_enseignant_classe_c11bis` (acceptée à tort avec la seule heure 18) ; sans la
  migration il s'arrête dès la fonction de durée, absente. **Mutation** : seize altérations de la migration, chacune fait tomber le
  scénario sur une ligne nommée (durée fixe de 60 minutes ; offre ignorée ; collisions avec la
  durée de la Classe visée seulement ; plafond horaire avec la durée de la Classe visée
  seulement ; couverture du seul début ; heures qui se touchent non fusionnées ; trou d'une heure
  comblé ; une seule semaine ; drapeau de disponibilités ignoré ; public inconnu sans garde ;
  durée absurde sans garde ; verrou retiré ; `DETAIL` retiré ; message de refus changé ; réglage
  des adultes et des enfants échangés ; séance ponctuelle comptée 60 minutes) ; le contrôle final
  de la migration refuse six d'entre elles à lui seul. **Trois scénarios existants** voient la
  seconde heure d'une Classe d'adultes (`classes_plafond_par_enseignant`, `creer_groupe_predicat`,
  `offres_personnalisees` : leurs fixtures déclaraient une seule heure). **Rejeu complet du
  22/10** : 121 scénarios verts sur 122 (`af_liste_blanche_volatiles` rouge connu et antérieur à
  ce lot, les quatre fonctions `avis_*` seulement). **Mesure** : le prédicat de base, une Classe de
  trois séances, 30 heures déclarées : 0,2 s (0,7 s avant) ; 168 heures : 1,0 s (2,8 s avant).
  **Reprise après relecture (22/10)** : (1) la **semaine −1** : les lignes déclarées sont prises
  de la semaine −1 à la semaine 52 (`generate_series(-1, 52)`), car `instant_creneau` rend la
  prochaine occurrence après maintenant ; sur une grille décalée d'une demi-heure (Calcutta) la
  ligne qui couvre le début de la prochaine séance a pu commencer il y a moins d'une heure, et
  l'enseignant couvert était refusé pendant cette demi-heure de la semaine (reproduit : mercredi
  15 h 45 UTC, cours d'enfants de 18 h à Paris, Calcutta 21, 22 et 23 : refusé à la semaine 0) ;
  (2) section (l) du scénario, **horloge fixée** (`instant_creneau` lit `test.now` dans la
  transaction du scénario, annulé avec elle) : Calcutta couvert à vingt instants du mercredi,
  et refusé à ces mêmes instants avec les heures 21 et 22 ou 22 et 23 seulement ; la dernière
  semaine examinée (la ligne de 19 h de la semaine 52 compte) ; le dimanche 23 h vers le lundi
  0 h à seize instants autour de minuit ; les deux saisons examinées au 1er avril (refus à la
  semaine 30) ; (3) des contrôles manquaient pour des altérations qui survivaient : la durée
  des affectations individuelles (collision et plafond : `ti1`, `ti2`), le drapeau NULL qui vaut
  vrai, les bornes 15 et 240 minutes (14, 15, 240, 241), et la proposition d'enseignants pour une
  Classe d'enfants (les trois enseignants, pas l'un des deux). La voie `modifier_groupe` est un
  constat neuf (2.1 bis). Aucune autre voie d'affectation : seules `creer_groupe`
  (huit arguments) et `affecter_enseignant_classe_c11bis` donnent un enseignant à une Classe
  et sont exécutables par un client, et toutes deux passent par le prédicat.
  À noter, hors de ce lot et non corrigé : `scenarios_cpt_suppression_export.sql` est instable sur
  la base du rejeu **sans** ce lot (4 rouges sur 80 rejeux) ; cause probable, non vérifiée : ses
  filtres courts (`f02`, `-7.6`) rencontrent parfois des identifiants aléatoires de l'export.
- L6-10, second temps, par le geste réel : le seul moyen infirmé mène à
  `paiement_non_disponible`, décision et motif tracés, jamais dans `audit_logs`
  ni dans `etat_dossier()` ; le filtre `etat` le liste.
- Aussi : une ligne `en_verification` ne se confirme jamais, un moyen non déclaré
  non plus ; la confirmation en salle 3 sous restriction de cause `paiement` garde
  la restriction ; les vingt gestes de l'autre côté, super-admin compris, rendent
  `hors_portee`, chacun tracé, la candidature intacte ; la direction au genre
  inconnu est refusée (42501) ; chaque RPC refuse le tuteur, la comptabilité, un
  enseignant et un candidat (quarante-huit refus) ; aucun résultat gardé (gestes,
  lots) ne porte une réponse, un nom ni un motif ; les capacités par compte. Le
  scénario de L1 suit les capacités ouvertes par L2A2 (`peutDecider`,
  `peutEcrireReferentiel`), le nombre de ses contrôles inchangé (174). Rejeu
  complet du 22/10 avant la relecture, de 03:40 à 03:42 UTC : 119 scénarios verts
  sur 120 ; **après la relecture, de 04:44 à 04:46 UTC : 119 verts sur 120**
  (`af_liste_blanche_volatiles` rouge connu, antérieur : les quatre fonctions
  `avis_*` seulement ; les douze RPC de L2A2 y sont inscrites, `lire_candidature`
  l'était depuis L1).

- **`CAND-AUTRES`** (autres compétences des candidats, 22/10, **passé en catalogue précis le 22/10** sur la
  précision du directeur ; `supabase/tests/scenarios_cand_autres_competences.sql`, **302 contrôles verts sur
  base neuve**, `testé localement`) :
  - droits : les sept RPC (trois du candidat, deux du catalogue, deux lectures redéfinies) DEFINER à
    `search_path` vide, empreinte F86 à jour, `authenticated` seul, garde positive (candidature du titulaire
    pour le candidat, direction active pour l'écriture du catalogue, jamais un rôle négatif) ; quatorze aides
    `competences_` fermées à tout compte, neuf aides `cand_` inchangées ; les trois tables (réponses,
    catalogue, journal du catalogue) fermées à `anon`, `authenticated`, `service_role` et `agent_ro`
    (ordres directs refusés), sans policy, séquence du journal fermée ; aucune RPC du lot ne contient
    « candidature » ; **seules** six fonctions citent la table des réponses (les trois RPC du candidat, la
    lecture du catalogue pour la propre réponse du titulaire, les deux lectures de la direction) et **seules**
    trois citent le catalogue en dehors des aides (lecture, écriture, filtre de la liste), par balayage du texte
    des fonctions de `public`, `private` et `app_private`, avec sa contre-épreuve ; refus (`42501`) du tuteur, de
    la direction, de la comptabilité, d'un enseignant sans candidature, d'un compte désactivé, d'un accès
    expiré, d'une candidature d'un autre type, de la session sans compte et d'`anon`, pour chacune des trois RPC
    du candidat ; le titulaire d'abord (`42501`), les arguments ensuite (`22023`) ;
  - avant l'envoi : « pas ouvert » avec sa raison, `enregistrer` refusé sans écriture ni clé
    gardée, un brouillon complet n'ouvre rien, un document sans date d'envoi non plus, une
    candidature refusée avant l'envoi dit `candidature_close` ; l'envoi **réel** (`envoyer_reponses_salle_examen`, cadre de test accepté)
    ouvre, et la première écriture passe de bout en bout ;
  - écritures : création (version 1, texte « autre » sans blancs, accord et date, instants en UTC), rejeu
    de la clé (premier résultat, `rejoue = true`, même avec un autre contenu, 0 écriture), clé
    réutilisée par une autre candidature, un autre geste, l'envoi ou le brouillon de la Salle d'examen,
    version périmée par le bas et par le haut,
    écriture identique sans effet, changement, accord retiré sans effacer les réponses, treize arguments
    absents ou mal formés (`22023`), forme des réponses (domaines vides, inconnus, niveau inconnu, non
    texte, nul ; disponibilité inconnue ou vide ; « autre » sans texte, texte seul, 201 caractères,
    deux lignes, tabulation, NEL ; trois champs fautifs à la fois, nommés dans l'ordre), bornes qui passent (neuf domaines, 200
    caractères) ; la ligne de la candidature (version, dernière activité), ses réponses et son journal
    d'événements ne bougent pas, aucune réponse sous la clé ni dans l'audit, et rien d'autre que la ligne
    du titulaire ne bouge (les autres lignes d'autres compétences, les autres candidatures et les clés des
    autres, pour une écriture comme pour un retrait) ;
  - étapes : en pause en Salle de vérification, confirmée (Salle des prêts à enseigner), une femme en
    Salle d'examen ; refusée : la personne voit ses réponses, `enregistrer` refusé, `retirer` permis ;
    retirée : `enregistrer` refusé, `retirer` sans objet ; le rejeu d'une clé réussie passe avant la
    clôture (premier résultat rendu après un refus, clé neuve refusée) ; une confirmée écrit puis retire ;
    `retirer` (version, rejeu, recréation à la version 1) ;
  - direction : `autresCompetences` dans le dossier (six clés, nul sans réponse, lu avec `accord =
    faux`) ; hors portée rendu et tracé sans aucune donnée dans les deux sens ; super-admin journalisé
    seulement de l'autre côté ; genre inconnu, candidat et comptabilité refusés ; liste à dix-neuf
    clés, sans réponse ; filtre : domaine (**un code du catalogue ou une famille**), niveau minimum (avec et
    sans domaine), disponibilité exacte, accord vrai et faux, les quatre ensemble, combinaison vide, clés à
    `null`, avec les filtres de la liste, compteurs hors filtre, valeurs ou types invalides (`22023`, dont un
    code ou une famille inconnus), audit de la liste (`competences` vrai ou faux, jamais le domaine
    cherché) ; l'assistante pour le groupe des sœurs ne se trouve que côté femmes ; **chaque candidature lue
    par chaque direction** (les réponses ne sortent que du côté du lecteur, l'autre côté rend `hors_portee` et
    rien d'autre) ; **le total d'une liste filtrée ne compte que le côté du lecteur** et aucune liste filtrée
    n'a rendu de ligne de l'autre côté ; **le journal d'audit** (`journal_audit`, lecture directe
    d'`audit_logs`, totaux de `journal_audit_filtres`) ne rend que les écritures des candidatures de son côté,
    la direction au genre inconnu n'en lit aucune, le super-admin lit les deux et est journalisé, l'auteur y est
    la référence `CAND-` avant la salle des prêts à enseigner, aucune réponse n'y figure ;
  - **catalogue** : état initial (25 compétences en six familles de 8, 5, 3, 5, 3 et 1, toutes actives à la
    version 1, ordre 1 à n par famille, les compétences nommées par le directeur dans la bonne famille, une
    ligne de journal `etat_initial` par compétence, aucune entrée d'audit) ; lecture (la direction lit tout,
    avec les versions et `peutModifier`, quel que soit son genre ; le candidat lit les actives sans version ;
    refus `42501` du tuteur, de la comptabilité, d'un enseignant sans candidature, d'un compte désactivé,
    d'un autre type de candidature, de la session sans compte et d'`anon`) ; écriture (refus `42501` de
    chacun d'eux **et du candidat titulaire**, avant toute validation ; vingt-sept jeux d'arguments invalides
    et les textes trop longs, sur plusieurs lignes ou à séparateur Unicode, `22023`, sans rien écrire) ;
    ajout (à la fin de la famille, ordre explicite, ordre de fin plafonné à 999, ajout directement
    désactivé, libellé sans blancs, journal avec auteur, clé et empreinte, audit sans libellé) ; rejeu,
    clé réutilisée par une autre demande (libellé ou version attendue), par un autre compte ; ajout d'un code
    déjà là (`conflit_catalogue`, clé non gardée) ; version périmée, code absent, famille changée ;
    modification, modification identique (`inchange`, rien de gardé), désactivation et réactivation (audit
    `actifAvant` et `actifApres`) ; **par toute voie** : ni `DELETE`, ni `TRUNCATE`, ni changement de code,
    de famille ou de date de création (`55000`), journal en ajout seul, `UPDATE` sans changement ignoré,
    version et date posées par le serveur quoi qu'on écrive, changement direct journalisé sans auteur
    (`voie` directe), contraintes de la table (code, famille, code qui porte le nom d'une famille, `autre`
    seul dans sa famille, ordre, libellé, exemple, doublon) ; **code désactivé** : lisible avec son libellé
    dans la réponse ancienne (`actif = faux`), absent de la liste d'un autre candidat, non choisissable
    (`domaine_desactive`, même parmi des codes actifs ; `domaine_inconnu` prime), gardé par qui l'avait déjà
    (enregistrement identique, autre disponibilité, autre niveau), retiré puis non repris, lu dans le dossier
    par la direction, cherchable par code et par famille, réactivé puis choisissable ; un code ajouté est offert
    et choisissable aussitôt ; déclencheur de la table des réponses (domaine hors catalogue `23503` par toute
    voie, ne lit pas l'état actif, forme du code et cent domaines au plus par la contrainte, aussi sans le
    déclencheur) ; audit du catalogue lu par toute direction active, sans libellé ni exemple, sans trace
    d'exception pour le super-admin ; plafond de 100 codes (le 100e passe, le 101e est refusé sans rien
    écrire, modifier reste permis) ; `etat_dossier()` et paiement inchangés ;
  - indépendance : `etat_dossier()`, paiement, contrôles d'admission, questionnaire envoyé et dossier
    identiques avec et sans réponses, avec et sans accord ; contre-épreuve : la déclaration de paiement
    les fait bouger ;
  - table : insertions et mises à jour refusées (domaine hors catalogue `23503` par le déclencheur, code mal
    formé et plus de cent domaines `23514` sans lui, niveau, tableau, texte, accord sans date, version 0,
    doublon, candidature inconnue) et les bornes qui passent ; suppression avec la candidature ; l'écart
    d'anonymisation et d'export épinglé (`CAND-Q21`).
  - **Contre-épreuve** : 137 altérations de la migration, une à la fois (catalogue : garde de la direction,
    ouverture au candidat, lecture ouverte à tous, tout ou actif seulement, version ou clé dans la lecture,
    ordre d'affichage, réponse propre du candidat ; validation : code désactivé accepté ou toujours refusé,
    code inconnu accepté, réponse enregistrée ignorée ; déclencheurs et journal : suppression, vidage,
    changement de code ou de famille, `UPDATE` vide compté, version libre, audit retiré ou chargé du
    libellé, auteur ou avant perdus, réglage non consommé, déclencheur de domaine retiré ou lisant l'état
    actif ; écriture : rejeu retiré ou sans empreinte, sans auteur ou sans version, conflit, plafond trop
    haut ou trop bas, absente, famille libre, version attendue, écriture identique, ordre, normalisation,
    bornes de texte, nom de famille ou `autre` hors de sa famille, clé courte ; filtre : sans famille, famille
    aux actifs seulement, code actif seulement, validation ouverte, niveau minimum devenu égalité, accord,
    disponibilité, lien à la candidature, portée ; graines : code renommé, famille changée, journal initial
    retiré ; tables, droits et contrôle final ; et, hérités du premier jet du lot, le contrôle d'envoi, le
    document sans date d'envoi, l'issue, les gardes du titulaire de chaque RPC, la version attendue, le
    rejeu et la clé réutilisée de chacune, la réponse dans la clé ou l'audit, l'écriture identique non
    détectée, l'audit retiré ou posé hors du côté de la candidature, la dernière activité touchée, la
    normalisation du texte, la date d'accord, `DELETE` ou `UPDATE` sans `WHERE`, le retrait fermé après une
    clôture, les bornes et séparateurs du texte, la disponibilité et le niveau non vérifiés, le dossier sans
    portée, le genre inconnu accepté, le filtre sans lien, sans disponibilité, inactif ou sans note d'audit,
    le type de l'accord, une clé de filtre inconnue acceptée, la table ouverte à `authenticated`,
    `ON DELETE CASCADE` retiré…) : **135 rendent le scénario ou la migration (son contrôle final) rouges** ;
    les deux survivantes : le `NOT brouillon` de l'ouverture (garde redondante, déjà impliquée par `envoye_le` non nul) et le `REVOKE` des aides internes à `authenticated` (redondant ici : aucune aide de `private` n'y reçoit ce droit par défaut ; le contrôle final de la migration et le scénario vérifient `has_function_privilege`) ; le verrou de la ligne de la candidature, que seul un essai à deux sessions éprouve, a été refait à la main avec le catalogue (deux écritures simultanées à la version 0 : l'une passe, l'autre rend `conflit_autres_competences` sans erreur de clé ; la même clé en même temps rend `rejoue = true`)
    La liste blanche des volatiles (`scenarios_af_liste_blanche_volatiles.sql`) reçoit les trois RPC
    volatiles (contre-épreuve : sans elles, le scénario les nomme). Essai à la main à deux sessions réelles
    (écritures simultanées du catalogue) : deux ajouts du même code avec des clés différentes, l'un passe,
    l'autre rend `conflit_catalogue` sans erreur de clé unique ; la même clé en même temps, la seconde rend
    `rejoue = true` ; deux modifications à la même version, la seconde rend `conflit_catalogue` avec la ligne
    de la première.
  - **Rejeu complet du 22/10 après ce lot** (`tool/rejouer_scenarios.sh`, base neuve, toutes les
    migrations puis les 123 scénarios) : **122 verts sur 123** (`af_liste_blanche_volatiles` rouge connu et antérieur : les quatre fonctions `avis_*` seulement ; les trois RPC volatiles de `CAND-AUTRES` y sont inscrites) sur un serveur dont l'horloge est décalée à 01 h 30 heure de Paris ; à l'horloge réelle du poste (22 h 20 UTC, soit 00 h 20 à Paris), `etape4` (A793, qui pose ses créneaux à 00 h heure de Paris) est en plus rouge, **avec ou sans ce lot** (même base sans la migration) : 121 verts sur 123 entre 00 h et 01 h heure de Paris, défaut de l'horloge du scénario, pas de ce lot ; les scénarios de L1, L2A1 et L2A2, qui contrôlent les empreintes F86 de `lire_candidature` et de `lister_candidatures` redéfinies ici, restent verts.

### 12.2 Flutter

- Chaque écran neuf ou étendu : cinq états, erreur de validation et états
  propres ; clair et sombre ; 360, 768, 1440 ; `fr` et `ar` (droite à gauche) ;
  texte à 200 % ; clavier, focus ; cibles de 48 et contrastes mesurés.
- `verifierUnSeulBoutonPlein` dans chaque état ; la ligne d'`ADM-20` a 2 cibles.
- `ADM-20` à 1 000 lignes, sur le modèle de
  `test/features/admin_regroupements/echelle_listes_test.dart`.
- Salle d'examen : 0 case de contrat, 0 dépôt de pièce.
- Mode entretien de `/salle` : 0 mention de séance, 0 donnée sensible. `/attente` :
  0 motif interne, 0 compte rendu, 0 constat. Courriel `a_envoyer` : « Courriel
  pas encore envoyé », 0 « envoyé le ». Composants promus dans la galerie
  (`test/widgets/catalogue_galerie_test.dart`).
- Commandes : `dart run slang`, `dart run build_runner build
  --delete-conflicting-outputs`, `dart analyze --fatal-infos` (0 problème),
  `flutter test`, `dart run tool/verifier_jetons.dart` (0 violation nouvelle).

### 12.3 Non-régression

- Référence remesurée sur la branche avant chaque lot, chiffre écrit. Dernières
  mesures écrites : 108 scénarios SQL sur 109 le 19/10
  (`af_liste_blanche_volatiles` rouge connu, antérieur), 15 218 tests Flutter
  le 18/10 (`REVUE §12`).
- Restent verts : invitations, inscription sur invitation, accords, `ADM-02`,
  import du 12/10, Comptable (`CPT-02`), affectation par `tc_verifier`,
  approbation de la pièce d'un tuteur (L2-13).
- **Garde étendue** : 28 fichiers de scénarios signent puis activent un enseignant
  (`CORR §7`, recette), dont `scenarios_etape3.sql`, premier de la CI. Chacun
  reçoit les fixtures des nouveaux contrôles dans le même lot ; le nombre de
  fichiers touchés s'écrit.

### 12.4 Critères de la spec

| `SPEC §13` | Preuve |
| :--- | :--- |
| Autre type sans copier le pipeline ; critères étanches | L1-7 |
| Champs au bon moment ; rien de postérieur exigé (coordonnées, photo, `weekly_availability`) | test de widget de la salle d'examen (12.2 : 0 case de contrat, 0 dépôt de pièce) ; L2-2 (sans photo, sans `weekly_availability`, sans coordonnées) ; L3-10 |
| Salle 3 impossible sans pièce, contrôles, paiement | L2-1, L2-3 |
| Sans compte bancaire mais moyen compatible confirmé : admis | L6-8 |
| Préférence bancaire à égalité seulement | L1-9 |
| Coordonnées financières pas exigées avant les cours | L2-2 |
| Confirmé indisponible distinct de prêt à être affecté | L2-14 ; widget `ADM-20` |
| Nom et entretien : deux cibles ; état réel ; lien absent sans bouton | 12.2, L4-1 |
| Compte rendu et décision traçables | L2-11, L4-5 |
| Un candidat ne lit pas les autres ; pièces hors des listes | L1-1, L1-5 |
| Lots : portée et erreurs partielles | L2-7, L3-8 |
| Décisions sensibles traçables | L2-11, L1-5, L4-3 |
| Import sans compte ni contrôle validé | L3-5 |
| Cohérence avec la Bible et les jetons | `tool/verifier_jetons.dart` (0 violation nouvelle), 12.2 |
| États loading, empty, error, offline, accès refusé définis | 12.2 |
| Clair et sombre, largeurs, clavier | 12.2 |
| Non-régression | 12.3 |

---

## 13. Hors module (`CAND-Q15`)

Les cinq défauts trouvés hors du module sont confiés à des agents (`DEC:38`).
**Recherche du 21/10** sur 584 branches distantes et 34 PR ouvertes : **aucun des
cinq n'est corrigé, sur aucune branche** (`CORR §0 bis`). Les correctifs
s'écrivent d'après `CORR`, chacun sur sa branche, jamais par `main`, avec son
scénario et un horodatage de migration propre.

| Lot | Défaut | Lien avec ce module |
| :--- | :--- | :--- |
| `langue` | la langue de l'enseignant est enregistrée par son nom et comparée à un code (`CORR §3`) | sans lui, une personne en salle 3 n'est affectable à aucune classe dont la langue est renseignée ; aucune validation en salle 3 avant lui (section 11) |
| `c11bis` | `affecter_enseignant_classe_c11bis` lève toujours : aucune classe en attente ne reçoit d'enseignant (`CORR §4`) | sans lui, « affectable » n'a pas de chemin serveur ; aucune validation en salle 3 avant lui (section 11) |
| `creer_groupe` | pose un enseignant sans vérifier pièce, genre, langue, plafond ni collisions (`CORR §5`) | une personne hors salle 3 pourrait recevoir une classe ; le prédicat qu'il centralise refuse aussi restriction et indisponibilité (4.3) |
| `conduite` | le code de conduite n'est exigé par aucune garde (`CORR §7`) | entre dans `accords_signes` ; `CAND-BR-11` s'écrit après, sur la garde redéfinie ; sur le chemin critique du premier envoi (section 11) |
| `gnf` | 0 décimale côté client, 2 côté serveur (`CORR §6`) | aucun direct ; paie et versements en GNF |

**Ordre** (`CORR §2`) : `langue`, puis `c11bis`, puis `creer_groupe`. `conduite`
passe à part, après les migrations `20261018160000` et `20261019100000` ; `gnf` est
indépendant. Ajustements relevés par la recherche : le seed de staging de la PR
#40 écrit `array['fr','ar']`, à corriger avant sa fusion ; `creer_groupe` retient
la variante `app_private.verifier_affectation_enseignant(uuid, uuid, boolean)`
(`CORR §0 bis`).
