# La liste des personnes : une seule liste par population, pour toute la vie de la personne (16/11/2026)

Demande du directeur, 16/11/2026 : « dans 2 semaines, les entretiens sont finis, qu'est-ce qui se passe avec
une ligne d'un enseignant sur cette liste ? ça doit afficher l'état de l'affectation, la/les classes si
affecté, et tout ce qui se passe au quotidien après l'embauche (les détails dans le dossier) … même avant
l'embauche, l'écran et le serveur doivent tout préparer pour qu'on finisse une fois pour toutes avec cette
partie … sans oublier les imprimables … anticipe … apprends de nos erreurs … planifie pour qu'on suive tous
ensemble … et consigne pour les élèves (surtout la liste). »

Statut : **proposé par le pilote, à valider par le directeur** (§9 : les questions ouvertes). Une fois
validé, ce document prévaut, pour les listes de personnes, sur toute retouche ponctuelle. Il s'appuie sur
`DECISION-LISTES-2026-10-23.md` (forme d'une liste, composants), `DECISION-DEFILEMENT-2026-11-01.md` (la
liste est la page) et `VISION-ECOLE-2026-11-05.md` (le suivi pédagogique est la priorité n° 1). Il remplace
le lot « UNE-LISTE » de `ETAT-ET-PLAN-2026-11-16.md`.

## 0. Ce que nos erreurs nous ont appris (règles, pas des souvenirs)

| Erreur vécue | Règle qui en sort |
| :--- | :--- |
| Les questions de versement retouchées quatre fois ; le candidat ne pouvait pas corriger, la direction ne pouvait pas débloquer (15-16/11) | Chaque état bloquant a **deux sorties écrites avant le code** : ce que la personne peut faire elle-même, et le geste de la direction qui débloque. Pas d'état sans issue. |
| La validation de la pièce rangée sur une autre page, l'étiquette « manquante » fausse (16/11) | **Le geste vit là où l'on voit la chose.** Une ligne ou un dossier ne renvoie jamais vers une autre liste pour agir. Une étiquette lit l'état réel, jamais un contrôle voisin. |
| « Créneaux d'entretien » caché dans « Outils » ; personne ne l'a ouvert, 43 candidats bloqués | Le geste qui débloque une file est **en tête de cette file**, pas dans un menu. |
| Bandeaux jaunes jamais fermables, consigne perdue dans une PR arrêtée | Toute demande a sa ligne dans le plan le jour même ; une PR ouverte plus d'un jour est relancée ou fermée. |
| Cinq pages montrent les mêmes noms ; la fiche charge toute la file des pièces | **Une population, une liste.** Une fiche ne charge que sa personne. Aucune liste entière en mémoire. |
| Un avis en arabe a bloqué tous les déploiements (16/11) | Un déploiement qui échoue est vu **dans l'heure** : le pilote lit chaque déploiement après fusion. |
| L'après-confirmation jamais parcouru | Chaque phase de la vie d'une personne est **parcourue de bout en bout avec un compte de test avant** qu'une vraie personne y arrive. |

## 1. Le principe

- **Quatre populations, quatre listes, une seule grammaire** : Enseignants (candidats compris), Élèves,
  Familles, Équipe (direction, associés, comptable). Même composant, même ligne, mêmes menus, mêmes
  actions groupées, mêmes impressions. Ce qui change : les colonnes et les gestes, servis par le serveur.
- **La ligne suit la vie de la personne.** Une personne n'apparaît qu'une fois ; sa ligne montre sa
  **phase** et ce qui compte **dans cette phase** (un résumé, jamais tout). Le détail est dans le dossier.
- **Le dossier est le même partout** : depuis la liste, la messagerie, une notification, une classe.
- **Les vues enregistrées remplacent les pages** : « Recrutement », « Accueil », « En poste », « Paie »,
  « À traiter aujourd'hui » sont des vues de la même liste (filtres + colonnes + tri), pas des pages.
  Chaque membre de l'équipe peut enregistrer les siennes (vague 3 de la stratégie).
- **Le serveur décide** : la phase, l'état, « qui attend quoi », les gestes permis par ligne et par
  sélection. L'écran n'en déduit rien (règle du dépôt : un widget lit une capacité, jamais un rôle).

## 2. La vie d'un enseignant, phase par phase

Les états entre crochets existent déjà dans le code ; les autres sont **à vérifier ou à créer** (lot L1).

| Phase | États | Ce que la ligne montre | Geste qui débloque, en tête de file |
| :--- | :--- | :--- | :--- |
| **Candidat** | préqualification [en_examen, a_completer, paiement_non_disponible], vérifications [entretien_a_planifier], entretien planifié, entretien passé, confirmé, refusé, retiré, en pause | étape, état, « qui attend quoi », pièce, versement, langues, côté, pays, depuis quand | Accepter · Demander une précision · Ouvrir des créneaux |
| **Accueil** (salle 3) | contrat à signer, coordonnées de versement à valider, profil à compléter, formation à suivre, prêt à enseigner | ce qui manque encore (une pastille par élément) | Envoyer le contrat · Valider les coordonnées |
| **Disponible** | prêt, sans classe | disponibilités (jours, heures, fuseau), langues, publics | Affecter à une classe · Proposer des classes |
| **En poste** | une ou plusieurs classes | classes (nombre, heures par semaine), prochaine séance, présence de l'enseignant sur 30 jours, remplacements reçus et donnés, avancement de ses classes sur le programme (en retard, à l'heure) | Voir l'emploi du temps · Remplacer |
| **Absent** | absence déclarée, remplacé | dates, remplaçant | Désigner un remplaçant |
| **En pause / suspendu** | pause demandée, suspendu par la direction | motif court, date de reprise | Rétablir |
| **Parti** | fin de collaboration (à sa demande, par la direction) | date, motif court ; masqué par défaut | Réintégrer (si permis) |

À toutes les phases : **messagerie** (bouton sur la carte du dossier et dans le menu de la ligne),
**responsable** (qui suit la personne), **dernière activité**, **alertes** (document expiré, versement en
échec, plainte, retard répété) en pastille, jamais en bandeau.

### 2.1 Colonnes (ordinateur) et ligne (téléphone)

- **Toujours** : photo et nom (matricule dessous), phase · état en pastille, « qui attend quoi »,
  prochaine échéance (entretien, contrat, prochaine séance, reprise), responsable, menu « … ».
- **Selon la vue** (choisies par la vue, jamais toutes à la fois) : pays et fuseau, langues, côté,
  pièce, versement, classes et heures, présence, remplacements, avancement des classes, dernier versement.
- **Téléphone** : nom, pastille, une seule ligne de résumé propre à la phase, menu « … ».

### 2.2 Gestes par ligne (menu « … »), servis par le serveur selon la phase

Ouvrir le dossier · Écrire · Assigner un responsable · Accepter · Refuser (motif) · Demander une précision ·
Mettre en pause / Reprendre · Planifier ou dispenser d'entretien · Envoyer le contrat · Valider les
coordonnées de versement · Débloquer le versement · Affecter à une classe / Retirer d'une classe ·
Déclarer une absence · Désigner un remplaçant · Suspendre / Rétablir · Terminer la collaboration ·
Imprimer la fiche.

### 2.3 Actions groupées (sélection), chacune avec un rapport ligne par ligne

Écrire à la sélection (application ou courriel, dans la langue de chacun) · Accepter · Demander la même
précision · Refuser (même motif) · Mettre en pause / Reprendre · Assigner un responsable · Inviter à
choisir un créneau · Envoyer le contrat · Exporter ou imprimer la sélection · Ajouter à une liste
enregistrée. Règles : seulement si le serveur a l'opération groupée ; chaque ligne réussit ou échoue
seule, avec la raison (« 47 acceptées, 3 refusées : pièce manquante ») ; rien d'irréversible sans
confirmation qui dit le nombre.

### 2.4 Filtres

Phase, état, « qui attend quoi », côté, langues, pays, pièce, versement, responsable, classe, disponibilité
(jours, soirées, nombre de jours), ijaza, publics, alerte, période. Les filtres des réponses de candidature
(BE-1a, déjà dans main) restent.

## 3. Ce que le serveur doit préparer (avant tout écran)

1. **Une lecture paginée par population** (`lister_personnes(population, vue, filtres, tri, page)` ou
   l'extension de `lister_candidatures`), qui rend pour chaque ligne la phase, l'état, « qui attend quoi »,
   l'échéance, les colonnes de la vue et **les gestes permis**. Jamais la liste entière.
2. **Une machine à états par population**, comme celle des candidatures (`candidature_gestes_regles`) :
   chaque geste a sa règle (qui, dans quelle phase, motif requis), sa trace et son effet. Les phases après
   l'embauche s'y ajoutent au lieu de vivre dans des écrans séparés.
3. **Des gestes groupés** qui appellent le même geste unitaire ligne par ligne, avec idempotence et rapport.
4. **Des compteurs par file** (« 212 à examiner », « 43 attendent un créneau ») servis par une seule lecture.
5. **Une exportation côté serveur** (fichier CSV et PDF) qui respecte les droits et les filtres : jamais
   un export fabriqué par l'écran à partir de ce qu'il a chargé.
6. **La fiche ne lit que sa personne** (corrige la lenteur relevée le 16/11 : chaque fiche chargeait toute
   la file des pièces ; `comptesProvider` charge jusqu'à 1 000 comptes et les garde en mémoire).

## 4. Les imprimables (catalogue, livrés après les listes, préparés dès L1)

| Pour | Document |
| :--- | :--- |
| Une liste | la sélection ou la vue en PDF (tableau) et en CSV |
| Un enseignant | fiche du dossier ; contrat signé ; attestation d'enseignement ; emploi du temps ; relevé des séances et des versements |
| Une classe | liste des élèves ; feuille de présence ; avancement sur le programme |
| Un élève | certificat de scolarité ; relevé de progression (étape, vitesse, évaluations) ; facture et reçu ; bulletin |
| La direction | état du recrutement ; état des classes ; état de la paie du mois |

Règle : un imprimable est généré par le serveur, daté, avec le matricule ; il ne contient que ce que la
personne qui l'imprime a le droit de voir.

## 5. Les élèves (consigné aussi dans `RETOURS-TERRAIN-INSCRIPTIONS.md`)

Même grammaire. Les élèves sont la population qui aura **le plus besoin de listes**.

| Phase | Ce que la ligne montre |
| :--- | :--- |
| **Demande** | qui (élève, famille), âge et catégorie, horaire voulu, langue, depuis quand, « vraiment élève ? » (cf. R23-R24) |
| **Placement** | niveau évalué, classe proposée, place libre |
| **En attente de classe** | regroupement, nombre d'élèves en attente sur le même horaire |
| **Inscrit** | classe, enseignant, horaire |
| **Actif** | **étape du programme, vitesse comparée à la durée prévue, prochaine évaluation** (priorité n° 1), présence sur 30 jours, paiement (à jour, en retard, montant), prochaine échéance |
| **Arrêt temporaire / parti** | dates, motif, règles d'argent (`A-HARMONISER-REGLES-ARGENT-ET-ARRET.md`) |

Gestes : écrire à la famille, placer, changer de classe, relancer le paiement, déclarer un arrêt, imprimer
le certificat ou le relevé. Vues : « À placer », « En retard sur le programme », « Paiement en retard »,
« Absences répétées », « Par classe ». Le dossier de demande d'un élève doit être lisible par la direction
(constat du 16/11 : seuls le nom et la date sont visibles, R24).

## 6. Les lots, dans l'ordre (remplace UNE-LISTE dans le plan)

| Lot | Contenu | Condition |
| :--- | :--- | :--- |
| **LP-0** | Validation de ce document par le directeur (§9) | — |
| **LP-1 serveur** | Phases et gestes de la vie de l'enseignant (relevé de l'existant : `teacher_profiles`, `teacher_student_assignments`, `groupes`, `remplacements_*`, `versements_paie`…), lecture paginée unique avec gestes par ligne, compteurs, gestes groupés de base | après LP-0 ; grand modèle pour le cahier |
| **LP-2 écran** | La liste des enseignants remplace Candidatures : vues enregistrées par défaut, colonnes par vue, menu par ligne, sélection ; « Fichiers à valider » retiré du menu (devient un filtre) ; fiche qui ne charge que sa personne ; providers en autoDispose | après #515 et LP-1 |
| **LP-3** | Actions groupées avec rapport ; écrire à une sélection | après LP-2 |
| **LP-4** | Phases après l'embauche à l'écran (accueil, disponible, en poste, absent), **parcourues avec un compte de test** (étape E du plan) | après LP-2 |
| **LP-5** | Imprimables et exports (§4), d'abord liste et dossier enseignant | après LP-2 |
| **LP-6** | Liste des élèves (et des familles) avec la même grammaire, suivi pédagogique en colonne | après LP-4 ; lot élèves |
| **LP-7** | Liste de l'équipe (droits à la carte, vague 2 « la mission ») | avec la vague 2 |

Chaque lot : une PR, captures 360 et 1440 en français et en arabe, mesures de la première ligne, et une
ligne dans `SUIVI.md` le jour même.

## 7. Ce qui ne change pas

Le dossier en trois étages (BE-1d), précédent / suivant (#516), la messagerie sur la carte du dossier,
les règles de défilement, les composants de `DECISION-LISTES` §4.

## 8. Comment on suit

`ETAT-ET-PLAN-2026-11-16.md` (l'ordre) → ce document (le quoi) → `SUIVI.md` (le statut de chaque lot). Le
pilote met à jour les trois le jour même de chaque changement.

## 9. Questions au directeur (à trancher avant LP-1)

1. Les phases du §2 sont-elles les bonnes ? En manque-t-il (formation, période d'essai, évaluation
   annuelle de l'enseignant) ?
2. Après le départ d'un enseignant, sa ligne reste-t-elle visible (filtre « Partis ») ou disparaît-elle ?
3. Les actions groupées du §2.3 : toutes, ou d'abord Écrire, Accepter, Demander une précision, Refuser ?
4. Les imprimables du §4 : lesquels en premier ?
5. Les élèves (LP-6) : même ordre de priorité, ou avant les phases après l'embauche des enseignants ?
