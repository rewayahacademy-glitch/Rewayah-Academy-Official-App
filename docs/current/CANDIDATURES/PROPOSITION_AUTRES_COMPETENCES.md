# Les autres compétences des candidats : en profiter sans les ennuyer

22/10/2026. Demande du directeur, versée dans `DECISION-CANDIDATURES-2026-10-21.md`
(section 1 quater) : « profiter de ce grand nombre pour faire d'autres recrutements. La
plupart de ces candidats maîtrisent d'autres domaines, donc il faut leur demander. Comme
ça, si l'académie a besoin […] d'un candidat pour un autre poste autre que l'enseignement,
on va directement le contacter au lieu de refaire une autre annonce. […] glisser
discrètement ces demandes entre les questionnaires des salles […] sans les ennuyer avec
trop de questions. Et […] être transparent : leur dire pourquoi l'académie pourrait avoir
besoin d'eux sur un autre domaine. » Exemples cités : une assistante pour gérer le groupe
des femmes, des comptables, des social media managers.

Statut : **proposé et lancé** (le directeur a dit « à toi de faire »). Ce qui suit est la
conception retenue ; il la corrige s'il veut autre chose. **Le serveur est écrit** (22/10,
section 7) : `présent dans le code` et `testé localement` sur la base de test, ni staging ni
production ; l'écran, les textes et le port Dart restent à faire.

## 1. Où le demander

**Dans la salle d'attente, après l'envoi de la candidature, pas dans la Salle d'examen.**
La Salle d'examen reste courte et centrée sur l'enseignement : chaque écran de plus avant
« Envoyer ma candidature » fait perdre des candidats. Après l'envoi, la personne attend
plusieurs jours, sans rien à faire : c'est le bon moment. Une tuile du portail ouvre un
petit parcours facultatif, à reprendre ou à modifier quand elle veut.

La direction le revoit à l'entretien (salle 2) : une ligne « Autres compétences » sur la
fiche de la candidature, pour poser une question de vive voix si un besoin existe.

## 2. Ce qu'on dit, en premier

> **Vos autres talents**
> L'académie grandit. Elle aura besoin d'aide pour s'organiser, accompagner les familles,
> tenir ses comptes ou se faire connaître. Si vous savez faire autre chose, dites-le :
> nous vous contacterons d'abord, avant de publier une annonce.
> Facultatif. Cela ne change rien à votre candidature d'enseignant.

## 3. Trois écrans, à cartes, presque sans clavier

1. **Vos compétences** (directeur, 22/10 : « il faut être spécifique dans ce que tu vas
   demander comme compétence »). Des compétences précises, pas des domaines vagues,
   regroupées par famille pour se lire d'un coup d'oeil ; plusieurs choix ; chaque carte
   décrite avec un exemple. La liste vit dans un catalogue en base, que la direction
   complète sans nouvelle version de l'app :
   - **Communication et image** : gestion des réseaux sociaux ; relations publiques et
     partenariats (mosquées, associations, médias) ; design graphique (visuels, affiches,
     cartes) ; montage vidéo et animation ; photographie et prise de vue ; rédaction et
     création de contenus ; publicité en ligne ; traduction (langues précisées ensuite).
   - **Administration et organisation** : assistanat administratif ou de direction ;
     coordination d'un groupe (par exemple le groupe des sœurs, ou celui des parents) ;
     accueil et suivi des familles ; planification et gestion de projet ; ressources
     humaines et recrutement.
   - **Finances et droit** : comptabilité ; gestion financière ; juridique et protection
     des données.
   - **Pédagogie** : conception de programmes et de supports ; formation et
     accompagnement des enseignants ; observation et qualité des cours ; tests de niveau ;
     accompagnement des enfants (psychologie, besoins particuliers).
   - **Technique** : développement web ou mobile ; assistance technique aux familles et
     aux enseignants ; données et tableurs.
   - **Autre compétence** (quelques mots, seul champ au clavier).
2. **Votre niveau, compétence par compétence** : « Je débute », « J'ai de l'expérience »,
   « C'est mon métier ».
3. **Votre disponibilité pour une telle mission** : « Quelques heures par semaine »,
   « Un mi-temps », « Plus », « Pas pour l'instant », puis la case : « J'accepte que
   l'académie me contacte pour une mission dans ces domaines. »

Rien sur le salaire d'une mission : chaque mission aura ses conditions, dites au moment du
contact.

## 4. Côté direction

Un filtre « Autres compétences » dans la liste des candidatures (domaine, niveau,
disponibilité), dans le respect de la séparation femmes et hommes déjà posée en base : une
assistante pour le groupe des sœurs se cherche côté femmes. Aucune note, aucun classement
calculé.

## 5. Données et confiance

Les réponses ne servent qu'à proposer une mission de l'académie. Elles suivent la durée de
conservation de la candidature. La personne peut les modifier ou les retirer à tout moment,
et retirer son accord d'être contactée.

## 6. D'autres façons de bénéficier de ces 500 personnes

À garder en tête, sans rien construire de plus pour l'instant :

- **Remplaçants** : les candidats qualifiés qui n'ont pas encore de Classe sont la réserve
  naturelle des remplacements d'enseignants absents.
- **Relais dans leur ville ou leur pays** : beaucoup connaissent une mosquée, une
  association, un groupe de parents ; ils peuvent y faire connaître l'offre (la carte de
  partage le permet déjà).
- **Testeurs de l'app** : quelques volontaires pour essayer les écrans avant leur
  ouverture et dire ce qui bloque.
- **Contenus** : ceux qui savent filmer ou écrire peuvent préparer de courtes vidéos ou
  textes pour les réseaux de l'académie, relus par la direction.
- **Honnêteté sur l'attente** : avec peu d'élèves au départ, la plupart attendront
  longtemps une Classe. Le leur dire franchement, et leur proposer d'aider autrement, garde
  leur confiance.

## 7. Le serveur (lot `CAND-AUTRES`, 22/10)

`présent dans le code`, `testé localement` sur la base de test ; **ni `testé sur staging`
ni `déployé`**. Migration `supabase/migrations/20261022000500_cand_autres_competences.sql`,
scénario `supabase/tests/scenarios_cand_autres_competences.sql` (302 contrôles verts sur
base neuve ; repris après relecture, puis **passé en catalogue précis le 22/10** sur la précision
du directeur : « il faut être spécifique dans ce que tu vas demander comme compétence : social
media management, relations publiques, design graphique, montage vidéo, administration,
spécialistes en pédagogie, etc. »). Besoin `CAND-BR-19` (`DEPENDANCES_BACKEND.md`) ; contrat des ports :
`CONTRAT_PORTS_CANDIDATURES.md`, sections 3 bis (les réponses) et 3 ter (le catalogue).

| Quoi | Où dans le serveur |
| :--- | :--- |
| Le catalogue | table `competences_catalogue` : **code**, **famille**, **ordre** (rang dans la famille), `libelle` et `exemple` (en français, ceux de la direction), **actif**, version ; son journal en ajout seul `competences_catalogue_journal`. **25 compétences en six familles** (communication : `reseaux_sociaux`, `relations_publiques`, `design_graphique`, `montage_video`, `photographie`, `redaction_contenus`, `publicite_en_ligne`, `traduction` ; administration : `assistanat`, `coordination_groupe`, `accueil_familles`, `gestion_projet`, `ressources_humaines` ; finances_droit : `comptabilite`, `gestion_financiere`, `juridique_donnees` ; pedagogie : `conception_programmes`, `formation_enseignants`, `qualite_cours`, `tests_niveau`, `accompagnement_enfants` ; technique : `developpement`, `assistance_technique`, `donnees_tableurs` ; autre : `autre`). **Ajout seul ou désactivation, jamais de suppression**, par aucune voie ; lecture : le candidat et la direction (`lire_catalogue_competences()`) ; écriture : **la direction seule**, journalisée (`enregistrer_competence_catalogue(...)`, version attendue, clé d'idempotence, plafond de 100 codes) |
| Les réponses | table `candidature_autres_competences`, **une ligne par candidature** : les domaines (**codes du catalogue**) et, pour chacun, le niveau (`debutant`, `experience`, `metier`) ; le texte court de « autre » (1 à 200 caractères, une seule ligne) ; la disponibilité (`quelques_heures`, `mi_temps`, `plus`, `pas_maintenant`) ; l'accord d'être contactée (booléen et date) ; la version propre de la ligne ; la mise à jour. Aucun privilège de table, aucune policy : tout passe par les RPC |
| Le candidat | `lire_autres_competences()` (ouvert ou non et pourquoi, version, réponses, familles, catalogue actif et codes désactivés de sa propre réponse, listes fermées), `enregistrer_autres_competences(...)` (version attendue, clé d'idempotence ; **valide contre le catalogue actif**), `retirer_autres_competences(...)` |
| La direction | `lire_candidature` rend `autresCompetences` (nul sans réponse) ; `lister_candidatures` accepte `competenceDomaine` (**un code du catalogue ou une famille**), `competenceNiveauMin`, `competenceDisponibilite`, `competenceAccord` ; dans la portée femmes et hommes de `CAND-Q07`, le super-admin journalisé ; le catalogue se lit et s'écrit par `lire_catalogue_competences()` et `enregistrer_competence_catalogue(...)` |

**Règles posées par le serveur**
- **Le catalogue (décision du directeur du 22/10).** Des compétences précises, par famille, que la
  direction complète sans nouvelle version de l'app : un code s'ajoute ou se **désactive**, ne se
  supprime jamais (déclencheur : ni `DELETE` ni `TRUNCATE`, quelle que soit la voie), son code et sa
  famille ne changent pas. **Une compétence désactivée** reste lisible (avec son libellé) dans une
  réponse ancienne, n'est plus offerte, **ne peut plus être choisie** (`domaine_desactive`) **sauf par
  qui l'a déjà dans sa réponse enregistrée** (elle la garde, change son niveau ou l'ôte), reste
  cherchable par la direction (code ou famille) et peut être réactivée. Une compétence neuve est
  offerte aussitôt. Chaque changement du catalogue laisse une ligne de journal (avant, après, auteur,
  clé) et une entrée d'audit sans libellé. Les familles sont une liste fermée de six.
- **Qui, quand.** Le titulaire d'une candidature d'enseignant, au compte valide, **après l'envoi
  de la Salle d'examen** (un document de réponses **du candidat** envoyé ; un brouillon ou un document importé n'ouvre rien). Ensuite à
  toute étape, pause comprise, **tant que la candidature est en cours**. Une candidature refusée
  ou retirée ne peut plus enregistrer ; la personne peut encore **lire et retirer** (voir ci-dessous).
- **Ce n'est pas une candidature qui bouge.** Écrire ne change ni la version de la candidature,
  ni sa dernière activité (la liste de la direction ne remonte pas une personne qui complète une
  réponse facultative), ni son journal d'événements. Une écriture effective et un retrait effectif
  laissent une ligne d'audit sans aucune réponse (nombre de domaines, version, accord).
- **Idempotence.** `versionAttendue` vaut 0 tant que rien n'est enregistré. Une clé rejouée rend
  le premier résultat, sans écriture ; une écriture identique à l'état courant ne change rien.
  Le résultat gardé sous la clé ne porte jamais une réponse.
- **Jamais lues pour décider.** Aucun contrôle de passage, ni le paiement, ni `etat_dossier()`
  ne lit ces réponses (prouvé par le texte des fonctions, avec sa contre-épreuve, et par les
  résultats avec et sans réponses).
- **Conservation.** La ligne suit la candidature (supprimée avec elle). Comme pour tout le module,
  `cpt_anonymiser` et `mes_donnees_export` ne la couvrent pas encore : écart connu, le même que
  `CAND-Q21` ; le scénario l'épingle pour qu'il ne s'oublie pas.

**À soumettre au directeur** (sept points ; le serveur applique la lecture la plus sûre d'ici sa réponse)
1. **Retirer à tout moment.** La proposition (section 5) dit « à tout moment » : le serveur laisse
   donc retirer ses réponses et son accord **même après un refus ou un retrait de la candidature
   d'enseignant**. Un refusé d'enseignant peut pourtant garder son accord et redevenir utile pour
   une autre mission : la direction filtre alors sur l'issue qu'elle veut.
2. **Pas d'accord, pas de mission.** Cocher ou non la case n'efface rien : la direction lit les
   réponses avec `accord = faux` (à l'entretien, par exemple) et **ne propose aucune mission** à
   cette personne ; la recherche d'une personne pour une mission envoie toujours
   `competenceAccord: true`. Le texte exact de l'accord n'est pas versionné (booléen et date,
   comme demandé) ; si le juriste veut la version du texte lue, c'est une colonne de plus.
3. **« Traduction » : les langues à préciser.** La proposition (section 3, écran 1) renvoie les
   langues à l'écran suivant ; le serveur ne porte **aucune** langue pour la compétence `traduction`
   (famille `communication`), et le texte de « autre » n'y répond pas. À trancher avec l'écran : une
   liste fermée de langues (les codes du questionnaire, portugais compris) pour `traduction`, ou une
   phrase libre.
4. **La disponibilité se filtre par valeur exacte** (elle n'est pas classée : « mi-temps » ne
   contient pas « quelques heures »), le niveau par minimum (`metier` contient `experience`).
5. **Une candidature retirée garde ses réponses et son accord.** Retirer sa candidature
   d'enseignant n'efface rien de ces réponses (le geste de retrait est celui du moteur des
   candidatures, que ce lot ne touche pas) : tant que la personne n'appelle pas
   `retirer_autres_competences`, la recherche `competenceAccord: true` la trouve encore, avec
   `issue = retiree` sur sa ligne. Une personne qui retire sa candidature pour ne plus être
   sollicitée pourrait s'en étonner. À trancher : l'écran de retrait propose-t-il de retirer aussi
   « Vos autres talents » (le plus simple), la recherche d'une mission écarte-t-elle les
   candidatures retirées, ou le retrait de la candidature efface-t-il la ligne (une règle de plus
   dans le moteur) ? D'ici sa réponse, l'écran de la direction affiche l'issue de chaque ligne.

6. **Les textes du catalogue.** `libelle` et `exemple` sont en **français** : ceux de la direction. Les
   textes semés par la migration reprennent les mots de la proposition (section 3) et passent par
   `mots-rewayah` avant d'être montrés ; l'app garde ses propres textes (`fr`, `ar`) pour les codes
   qu'elle connaît. Une compétence que la direction **ajoute** n'aura donc, tant qu'on n'ajoute pas une
   colonne par langue, que son libellé français, y compris pour un candidat qui lit en arabe. À
   trancher : accepter cette limite (le plus simple), ou ajouter l'arabe au catalogue.
7. **Les familles ne s'ajoutent pas depuis l'écran.** La direction ajoute et désactive des
   compétences ; les six familles (`communication`, `administration`, `finances_droit`, `pedagogie`,
   `technique`, `autre`) sont une liste fermée, parce qu'une famille s'affiche avec un titre traduit
   dans l'app. Une septième famille passe par une migration et un libellé, pas par l'écran du catalogue.

**Construit côté app le 23/10/2026** (`présent dans le code`, `testé localement` ; ni `testé sur
staging` ni `déployé`) : l'écran de quatre pages (`CAND-07`, fiche dans
`CATALOGUE_ECRANS_RECRUTEMENT.md`), ses textes en français et en arabe, le port Dart et son
adaptateur (`autres_competences_supabase.dart`), la tuile du portail, la ligne « Autres
compétences » de la fiche (`ADM-21`) et quatre filtres de la liste (`ADM-20` : domaine par famille ou
par compétence, niveau minimum, disponibilité, accord). **Les sept points ci-dessus attendent le
directeur** ; la fiche `CAND-07` reprend ceux que l'écran rend visibles.

**Ce qui reste** : **l'écran du catalogue de la direction** (ajouter, modifier, désactiver ; port
`PortCatalogueCompetences`, `CONTRAT_PORTS_CANDIDATURES.md` section 3 ter : seule la lecture est
construite), la file de contact (`L5`), la conservation (`CAND-Q21`), et tout essai contre un
serveur réel (staging).
