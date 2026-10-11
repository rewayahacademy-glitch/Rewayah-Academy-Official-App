# REWAYAH · PED-APRÈS · Restitution du cahier aux familles et pilotage du partage

**Version :** 1.0, 11 octobre 2026  
**Statut :** spécification UX/UI validée sur le principe métier et les trois directions visuelles ; **implémentation et recette non confirmées**  
**Destinataire :** Claude Code, intégrateur frontend  
**Périmètre autorisé :** Flutter frontend Android, iOS, tablette, web/desktop. **Aucun backend, migration SQL, RLS/RPC, serveur, LiveKit ou publication sans commande distincte du directeur.**  
**Nature :** SPEC DELTA, modification minimale de fonctions existantes ; **pas de nouvelle verticale, pas de nouveau cahier, pas de nouvel onglet global**.  
**Décision de référence :** directeur, 11 octobre 2026 : partage familial automatique actif par défaut ; l'administration peut désactiver/activer par Classe ou par élève ; une publication manuelle ciblée reste possible lorsque le partage automatique est désactivé.

> **ORDRE IMPÉRATIF À CLAUDE : AVANT LA MOINDRE LIGNE DE CODE, AUDITER LE DÉPÔT COURANT ET LES BRANCHES EN COURS.** Réutiliser tout écran, service, contrat, route, modèle et composant existant. Si l'expérience demandée existe déjà, **ne rien recréer** : uniquement corriger l'écart prouvé, et fournir sa preuve. Les high-fi guident l'amélioration de l'existant, jamais une refonte ni une seconde implémentation.

## 0. Finalité et critères de réussite

Une fois le cahier **existant** validé et confirmé, les informations pédagogiques **partageables et propres à chaque élève** sont présentées au tuteur automatiquement, si la politique de partage le permet. La direction peut appliquer une politique par Classe, poser une exception pour un élève, consulter le rendu exact côté famille, publier ou révoquer l'accès à **un compte rendu précis**.

**L'enseignant ne fait aucune saisie supplémentaire** : le cahier K-45 est obligatoire et conditionne déjà la validation de la séance et le processus de rémunération. Il porte déjà une appréciation par élève, des faiblesses, un devoir et la reprise ; sa contrainte d'effort reste **moins de 45 secondes**. Les écrans ajoutés ici n'ont aucune incidence sur la validation du cahier ni sur la paie ; une politique de partage désactivée **ne dévalide pas** une séance.

**Critères prioritaires :** (1) aucune duplication des fonctions, (2) zéro geste enseignant ajouté, (3) aucun contenu interne ou concernant un autre élève diffusé, (4) pas de promesse UI si la source est absente, (5) desktop véritable et design existant préservé.

## 1. Faits vérifiés dans le code, non autorisation de réimplémenter

*Contrôle ciblé du dépôt `rewayahacademy-glitch/Rewayah-Academy-Official-App`, branche `ccr-1b1bfa0b-m1kvkk`, consultée le 11/10 ; branches Codex F2 ouvertes. **Ce relevé n'est pas une recette des builds en production.** Claude doit refaire la vérification à son HEAD effectif.*

| Capacité / point d'entrée actuel | Fichiers ou contrat existants | Consigne |
|---|---|---|
| Cahier de séance après cours | `lib/features/cahier/cahier_page.dart`, `vue_cahier.dart`, `lib/core/enseignant/{service_enseignant,modeles_enseignant}.dart` | **GELÉ** : ni second rapport, ni formulaire mensuel, ni modification K-45 dans ce lot. |
| Historique et détail d'une séance du tuteur | `lib/features/suivi_foyer/{suivi_foyer_page,detail_seance_page}.dart` | **AMÉLIORER SUR PLACE** le détail, sans copie de l'Historique et sans nouvelle route si celle-ci existe. |
| Classe du tuteur | `lib/features/classe_tuteur/{classe_tuteur_page,travail_classe_page,progression_classe_page}.dart` | Conserver la rubrique **Travail à préparer** et **Progression** ; le résumé de séance appartient à **Historique → Détail**. |
| Élève, espace Groupe | `lib/features/tc_espace_groupe/espace_groupe_page.dart`, `port_travail_a_venir.dart` | Ne pas inventer un nouveau dashboard ou travail pédagogique ; vérifier les sources et renvois existants. |
| Admin, liste/inspecteur des Classes | `lib/features/admin_groupes/groupes_page.dart`, `_Inspecteur` | **AJOUTER UNIQUEMENT** un groupe compact de réglages de partage dans l'inspecteur / fiche existante, si absent. |
| Admin, progression et contrôle qualité | `lib/features/admin_pedagogie_progression/progression_page.dart`, `admin_pedagogie_qualite/qualite_page.dart` | Préserver les files d'exceptions et leurs actions : ne pas créer un second tableau « Rapports » concurrent. |
| Contrat résumé familial déclaré | `lib/core/capacites/port_resume_seance_famille.dart` | Port déjà défini, actuellement source indisponible sur la branche `ccr` examinée ; ne pas lire directement `lesson_reports` depuis l'écran familial. |
| Contrat progression familiale | `lib/core/capacites/port_progression_famille.dart` | Port existant ; progression et appréciation de séance sont deux choses différentes. |
| Codex F2, source familiale proposée | `lib/core/capacites/{resume_seance_famille_supabase,progression_famille_supabase}.dart`, migration `0054_seance_resumes_famille.sql`, **PR #21** | **NE PAS REDÉVELOPPER.** Vérifier la situation d'intégration avec Codex ; les capacités de **publication automatique**, de **réglage classe/élève**, de **partage/révocation admin** ne sont pas prouvées de bout en bout par cette seule migration. |
| Réglages applicatifs généraux | `lib/features/admin_configuration_fonctionnalites/fonctionnalites_page.dart` | Écran existant de configuration globale ; ne pas y placer l'exception élève : une fonction = un endroit. |

**Attention :** la migration F2 `0054` exposée lors de la revue permet à l'enseignant d'enregistrer un **texte familial explicitement rédigé/publié**. Ce n'est **pas** la preuve d'une génération automatique depuis le cahier K-45. Ne jamais ajouter ce texte comme obligation enseignante. Tant que le contrat réel n'assure pas une restitution approuvée et sûre, utiliser l'état « Compte rendu non disponible », déclarer la dépendance à Codex, et **ne pas simuler un succès en production**.

## 2. Contrat métier canonique : confidentialité, contrôle et vérité

### 2.1 Trois périmètres de contenu distincts

1. **Informations générales de séance** : date, horaire, Classe, enseignant, sort du cours, présence de l'élève ; restent régies par leurs autorisations propres, même si le partage pédagogique est désactivé.
2. **Informations pédagogiques partageables** : contenu effectivement travaillé pour l'élève, appréciation/échelle réellement enregistrée, points à renforcer, travail à préparer, éventuel commentaire **déclaré partageable**. N'afficher que les champs réellement disponibles. Une performance instantanée ne devient jamais « compétence stable », « examen réussi » ou « certification ».
3. **Informations internes** : notes confidentielles, signalements internes, données d'autres membres, justificatifs de rémunération, commentaires privés, brouillons. **Jamais** dans une projection familiale, même avec partage automatique actif ; le rendu familial ne reprend jamais le cahier brut de la Classe.

**Règle du Teaching Core :** `internal_details` et `family_summary` doivent être séparés. Le fait qu'un texte existe dans le cahier ne suffit pas à l'autoriser pour le foyer. Les messages de l'enseignant affichés dans les planches sont **fictifs**, non un mandat de publier des notes privées.

### 2.2 Politique de partage et ordre de priorité

**Valeur générale par défaut : ACTIVÉ** pour les observations pédagogiques familiales, sous réserve de l'accès autorisé au bon élève.

- **Classe** : `Partage automatique [Activé / Désactivé]`.
- **Élève** : `Utiliser la règle de la Classe / Toujours partager automatiquement / Ne pas partager automatiquement`.
- **Compte rendu précis** : une décision explicite de la direction `Partager manuellement / Révoquer ce partage` ; elle ne change **ni** la Classe **ni** l'élève.

**Priorité :** décision explicite sur un compte rendu précis > exception individuelle > politique de la Classe > valeur générale activée par défaut. **Exception élève** signifie règle appliquée à cet élève dans le contexte autorisé, et non transmission des données des autres membres.

**Règles temporelles de restitution retenues pour la recette :**
- Une désactivation masque immédiatement à la famille les comptes rendus visibles au titre du partage automatique, **sans effacer** le cahier ni la preuve de séance.
- Une publication manuelle explicite conserve son effet même si le partage automatique de Classe est désactivé, jusqu'à révocation ciblée.
- Réactivation : les comptes rendus qui avaient déjà été partagés automatiquement peuvent redevenir lisibles ; **ne pas publier rétroactivement en masse** les rapports retenus pendant la période désactivée.
- Un compte rendu révoqué **individuellement** reste masqué, même si la politique globale est « Activé », jusqu'à action expresse autorisée.
- Changement de Classe : historique rattaché à la Classe et aux droits de l'élève à la date de séance ; ne jamais transférer automatiquement les rapports d'une famille à une autre ; le paramètre individuel doit être explicite et lisible lorsqu'il s'applique à la nouvelle Classe.
- Après correction du cahier : afficher la version confirmée et l'indication « Corrigé le… ». Si une transmission manuelle a déjà eu lieu, une modification significative du contenu doit passer par une nouvelle validation de diffusion ou rester sur la dernière version familiale approuvée ; **pas d'envoi silencieux d'une nouvelle note interne**.

Les détails de persistance, traçabilité et autorisation en base sont **des dépendances contractuelles à faire valider**, non une mission backend. L'interface ne doit déduire aucune permission de simples boutons ou flags locaux.

### 2.3 Tableau de vérité pour l'interface

| Cahier confirmé | Règle effective / événement | Famille voit le pédagogique ? | Ce que l'admin peut faire |
|---|---|---|---|
| Non, ou en file hors ligne | N'importe quelle règle | **Non** | Voir l'état en attente ; ne pas publier |
| Oui | Partage automatique actif à validation et encore autorisé | **Oui**, partie partageable seulement | Consulter, révoquer un compte rendu si nécessaire |
| Oui | Classe désactivée, aucune exception | **Non**, informations générales conservées | Publier ce compte rendu manuellement |
| Oui | Élève forcé actif, Classe désactivée | **Oui** si compte rendu éligible à la diffusion automatique | Voir la règle effective et sa source |
| Oui | Élève forcé inactif, Classe activée | **Non** hors publication manuelle | Publier manuellement ce compte rendu |
| Oui | Publication manuelle expresse malgré désactivation | **Oui** pour le seul compte rendu ciblé | Révoquer uniquement ce partage |
| Oui | Révocation explicite du compte rendu | **Non** pour ce compte rendu | Réexaminer et republier si autorisé |
| Oui | Données pédagogiques partageables absentes | **Non : aucun jugement inventé** | Lire l'état et l'origine du manque |

### 2.4 Rôles et accès

| Rôle | Lire les observations partageables | Modifier règles de Classe/élève | Publier/révoquer manuellement | Cahier enseignant |
|---|---|---|---|---|
| Tuteur autorisé de l'élève mineur | Selon politique de partage | Non | Non | **Jamais brut** |
| Élève enfant, Interface guidée | Seulement les consignes qui lui sont destinées via ses vues existantes | Non | Non | Non |
| Élève adulte autonome | Visibilité de ses propres informations selon son droit existant ; ne pas lui appliquer aveuglément le rôle « tuteur » | Non | Non | Non |
| Enseignant de la Classe | Son cahier et ses informations de reprise selon permissions existantes | Non | Non | Oui, K-45 inchangé |
| Administration autorisée et active | Oui, dans les seules limites de son accès | **Oui** | **Oui** | Lecture existante, selon droits réels |
| Contrôleur | Uniquement sa mission et ses habilitations existantes | Non | Non | Aucune nouvelle permission |

L'état partagé avec une famille et l'état visible pour un adulte autonome ne doivent jamais être supposés identiques : vérifier les décisions/règles actuelles ; ne pas divulguer à un foyer un dossier adulte privé par simple similarité d'écran.

## 3. Navigation, trois écrans delta et **aucune nouvelle destination globale**

**TUT-PED-APR-01** : `Historique → séance sélectionnée → Détail de séance`. Conserver la barre basse Tuteur approuvée (`Accueil`, `Foyer`, `Historique`, `Compte`) ainsi que le retour, le sélecteur d'élève et les filtres existants. La rubrique `Progression` de la Classe reste la destination du suivi de longue période, et `Travail à préparer` reste la destination du devoir. Le détail de séance **résume**, il ne remplace pas ces vues.

**ADM-PED-APR-02** : `Administration → Opérations → Classes → Classe sélectionnée → Inspecteur/fiche existante`. Le réglage de partage et les exceptions individuelles sont ajoutés **ici**, dans la zone des paramètres de cette Classe ; ne pas créer un deuxième `Paramètres` ou une route `Partage pédagogique` au niveau 1.

**ADM-PED-APR-03** : depuis le **point réel de consultation administrative d'un cahier/compte rendu confirmé** (à retrouver avant codage) → « Aperçu familial / partage manuel ». **Préférence** : feuille ou inspecteur attaché au rapport existant ; si aucune lecture administrative n'existe, consigner cette dépendance et soumettre un point d'entrée minimal, sans créer un nouveau module `Rapports` en parallèle de Pédagogie/Qualité.

### TUT-PED-APR-01 · Détail de séance mobile, tableau de contenu

**Objectif** : « Que s'est-il passé pour mon enfant et que préparer pour la suite ? ». **Lecture seule ; aucun bouton de modification**.

Ordre vertical (conserver les composants réels du détail existant) :
1. Retour vers l'Historique, titre « Détail de séance », enfant et Classe, enseignant, date/heure locale, statut réel du cours ; **ne pas afficher une séance comme validée tant que ce n'est pas confirmé**.
2. Carte actuelle « Séance » puis carte actuelle « Présence » (sort du cours avant état individuel). Si cours non tenu, ne jamais déduire une absence de l'enfant.
3. **Bloc nouveau ou complété uniquement si absent :** « Compte rendu pédagogique ». Si visible, afficher dans cet ordre les champs partageables disponibles : `Ce qui a été travaillé`, `Appréciation de la séance` (uniquement si existante), `À renforcer` (si existant), `À préparer pour la prochaine séance` (si existant), `Commentaire partagé` (uniquement si réellement publié).
4. Liens secondaires **uniquement si existants et autorisés** : `Voir le travail à préparer`, `Voir la progression`, supports réellement accessibles. **Pas** de faux bouton « Réécouter » : un enregistrement n'apparaît que si son accès est autorisé et actif.
5. Même barre basse, exactement comme la référence d'Historique validée.

**États et textes exacts** :

| État fourni par une source autorisée | Texte à afficher | Action |
|---|---|---|
| Partageable, contenu présent | « Compte rendu pédagogique » | Lecture ; éventuellement liens vers Travail/Progression existants |
| Partage désactivé pour cet élève | « Compte rendu pédagogique non disponible » ; « Les observations de cette séance ne sont pas partagées avec votre famille pour le moment. » | Aucune demande d'accès artificielle |
| Cahier en attente | « Le compte rendu n'est pas encore disponible. » | Conserver Séance et Présence |
| Séance annulée ou non tenue | Conserver le libellé actuel du sort du cours ; aucune appréciation nouvelle | Aucun bloc trompeur |
| Source autorisée indisponible | « Le compte rendu ne peut pas être affiché. » | `Réessayer` seulement si pertinent |
| Hors ligne, dernière version non vérifiable | « Connexion nécessaire pour consulter le compte rendu. » | Ne pas afficher un cache familial après révocation |
| Aucun champ partageable confirmé | « Aucun compte rendu pédagogique n'est disponible pour cette séance. » | Pas de pourcentage ou commentaire généré |
| Rapport corrigé | « Corrigé le {date locale} » | Texte de la version familiale autorisée |

**Interdits :** nom/présence/rapport d'un autre élève de la Classe ; jugement automatique « stable/acquis » sans évaluation académique ; compétences créées depuis un pourcentage décoratif ; statut de paie du professeur ; rang ou leaderboard.

### ADM-PED-APR-02 · Inspecteur de Classe sur desktop

**Objectif** : choisir une politique en un geste, comprendre sa portée et identifier les exceptions.

Conserver la navigation latérale, le tableau de Classes et l'inspecteur existants. Sur vrai desktop, le contexte de Classe reste identifiable (nom, enseignant, public, membres, créneau) ; **ajouter dans la fiche** un bloc `Partage des comptes rendus pédagogiques` avec :

- Switch de Classe : `Partager automatiquement avec les familles` ; état lu depuis la source autoritative, pas un interrupteur local optimiste non confirmé.
- Aide fixe : `Les familles voient les observations partageables après validation du cahier. Les notes internes restent privées.`
- Action secondaire : `Gérer les exceptions individuelles` qui ouvre **une feuille/panneau dans le contexte**, jamais un niveau 1 de navigation.
- Liste des seuls élèves de la Classe : prénom/nom selon permissions admin, `Règle appliquée` (Classe / Exception individuelle), `Visible` ou `Non visible` pour les rapports éligibles, `Dernière modification` si disponible, menu contextuel accessible pour modifier **un seul** élève. Affichage paginé/virtualisé si effectif important, pas de compteur fictif.
- Réglage individuel : choix unique parmi `Utiliser la règle de la Classe`, `Toujours partager automatiquement`, `Ne pas partager automatiquement`. Confirmation précisant le périmètre et la conséquence de masquage immédiat.
- Priorité expliquée en une ligne : `Exception élève → Classe → Réglage par défaut`.
- En cas de conflit de modifications : rafraîchir et informer plutôt que écraser silencieusement un autre administrateur.

**États** : chargement, Classe vide, action confirmée, sauvegarde en cours, échec, autorisation refusée, élève retiré/transféré, donnée partielle, politique non encore servie. Si API manquante : message honnête `Le réglage de partage n'est pas encore disponible.` et **pas de fausse bascule**.

### ADM-PED-APR-03 · Aperçu familial et partage manuel sur desktop

**Objectif** : la direction vérifie **exactement** ce que la famille recevra et décide pour **un seul élève, une seule séance**.

- Fil d'Ariane réel vers Classe et séance ; en-tête : élève, Classe, date de séance, enseignant, statut de confirmation du cahier, statut de partage automatique effectif.
- Colonne principale : `Aperçu du compte rendu visible par la famille`, même ordre, intitulés, valeurs et exclusions que **TUT-PED-APR-01** ; n'afficher que les contenus shareables confirmés. Les notes internes peuvent exister dans une zone admin distincte déjà autorisée mais **jamais dans l'aperçu familial**.
- Colonne secondaire : `Diffusion vers la famille` ; rappeler la règle effective et l'état de diffusion de **ce rapport** ; choisir la seule action cohérente avec cet état : `Publier pour la famille` **ou** `Révoquer l'accès`, **jamais les deux CTA destructifs actifs simultanément**.
- Confirmation `Publier ce compte rendu pour la famille de {prénom} ?` avec rappel que le partage est limité à ce compte rendu et n'active pas l'automatisation de la Classe. Après succès : `Ce compte rendu est désormais visible par la famille.`
- Révocation : confirmation `Révoquer l'accès de la famille à ce compte rendu ?` ; après succès : `L'accès à ce compte rendu a été révoqué.` Le cahier et la séance restent validés.
- Historique des actions si la source existe et l'autorise : auteur, date, type de changement, sans inventer une piste d'audit si elle n'est pas disponible.
- Un **aperçu non publiable** doit apparaître clairement quand aucune donnée pédagogique autorisée n'existe ; publication désactivée côté interface avec explication et impossibilité de contournement serveur.

**États** : non validé, confirmé non partagé, partagé auto, partagé manuellement, révoqué, corrigé après partage manuel, chargement, erreur réseau, refus d'autorisation, double clic, autre admin ayant modifié l'état, expiration de session ; chaque état produit un feedback. Si contrats absents, fournir le **composant de lecture non interactif** seulement et livrer la dépendance au lot autorisé, pas une action factice.

## 4. Règles visuelles et high-fi de référence, 1 écran par planche

**Les visuels sont des références de hiérarchie et de placement, PAS un contrat de données, de nombres, de nouvelles routes ni de textes fictifs. Le code courant et les spécifications prévalent.**

| Planche | Fichier joint au paquet | Usage |
|---|---|---|
| `IMG-PED-APR-01` | `references/IMG-PED-APR-01_tuteur_mobile_sombre.png` | **Une seule référence mobile retenue**, la troisième de la première série (tuteur, détail de séance) ; les autres variantes générées sont abandonnées. |
| `IMG-PED-APR-02` | `references/IMG-PED-APR-02_admin_classe_partage_web.png` | **Un écran desktop 16:9** : inspecteur de Classe et politique/exception. |
| `IMG-PED-APR-03` | `references/IMG-PED-APR-03_admin_publication_manuelle_web.png` | **Un écran desktop 16:9** : aperçu exact du rapport ciblé et diffusion/révocation. |

**Corrections obligatoires avant de recopier une planche :**
- Les **valeurs démo** (dates, noms, compteurs, durée, niveau et surtout les « 12 élèves » du web) ne sont pas des règles métier : prendre les données réelles et quotas administrables. Aucun faux chiffre de progression.
- Les menus latéraux et barres basses dessinés par génération ne remplacent **jamais** les shells validés. Sur mobile Tuteur, conserver les destinations de la capture validée, pas les nouveaux onglets dessinés.
- Les deux actions `Publier` et `Révoquer` ne doivent pas être proposées actives en même temps dans un même état. La planche 3 illustre leurs emplacements, pas leur coactivation.
- Une « Appréciation » ou « Commentaire » ne paraît que si la source comporte cet élément et s'il est **partageable** ; aucune invention générative ni duplication de description.
- Si le contenu de la séance est un élément du compte rendu pédagogique privé, **ne pas** le laisser visible hors du bloc masqué : conserver seulement les informations générales autorisées et les supports accessibles indépendamment.
- Garder le **mode sombre validé** (fond anthracite, cartes gris violacé, lavande mesurée), les tokens gelés du projet ; titres français **DM Sans**, reste **Plus Jakarta Sans**, arabe selon police déjà installée. Pas de nouvelles couleurs/HEX, ni de nouvelle marque/logotype.
- Page mobile intégrée au shell actuel, tablette adaptative, **vrai desktop** avec navigation latérale et largeur disponible, accessibilité et mode clair fonctionnel même si références sombres.

## 5. États transversaux, contenu et performance

- Toute action admin doit avoir un état de chargement et empêcher le double envoi, ne jamais annoncer le succès avant confirmation du contrat ; en cas d'échec garder la valeur antérieure.
- État d'accès refusé = ne pas masquer simplement le panneau tout en laissant transiter des données non autorisées. Un deeplink ou retour arrière ne doit pas contourner une révocation.
- Déconnexion/changement de compte, de foyer ou d'élève : vider les projections famille déjà affichées ; éviter le flash de données d'un autre élève.
- Hors ligne : ne pas afficher de rapports désormais potentiellement révoqués comme « autorisés » sur la foi d'un ancien cache ; afficher un état de vérification.
- Pas de notifications systématiques à chaque appréciation ; réutiliser le catalogue de notifications existant si une notification de partage manuel a déjà été prévue et autorisée. Ne pas en inventer ici.
- Cohérence entre `Historique`, `Progression`, `Travail à préparer` : même élève sélectionné, mêmes libellés sémantiques, un seul point canonique pour chaque donnée. Une absence ou un travail « fait » ne prouve pas une compétence acquise.
- Pas de nouveau **bilan hebdomadaire/mensuel à rédiger** ; un bilan dérivé pourrait relever d'un lot ultérieur **sans saisie** et sans pourcentages inventés, mais il n'est **pas** à développer ici.

## 6. Responsabilités et dépendances NON comprises dans l'autorisation actuelle

### FRONTEND SEUL — possible après audit des écarts

- Composer ou perfectionner le bloc pédagogique du `DetailSeancePage` avec le port et les composants déjà existants ; aucun accès direct à une table brute de rapports.
- Rendre des états de partage et la politique effective dans l'inspecteur de Classe ; réutiliser le panneau/liste de membres existants.
- Afficher l'aperçu familial et les états de publication/révocation au point de lecture administratif existant.
- Tester les adaptations responsive, i18n, focus, clavier, lecteurs d'écran, contrastes, états et non-régression.

### DÉPENDANCES D'INTÉGRATION — ne pas coder côté backend dans ce lot

- Source familiale **par élève et par séance** approuvée, indépendante du cahier brut, à partir des évaluations déjà enregistrées dans K-45, sans nouvelle saisie.
- Politique persistante de Classe, exception élève, statut de publication ciblé, historique d'actions, politique effective exposée sans fuite de données.
- Publication automatique dès confirmation du cahier et révocation avec effet réel sur toutes les lectures, tout en préservant la preuve de séance et la rémunération.
- Gestion cohérente des comptes adultes autonomes et des changements de foyer/Classe, selon contrats actuels.

**Claude doit noter ces besoins et les rapprocher des tâches Codex/branches actives, mais ne doit ni introduire une migration ni changer une RPC sans instruction explicite.** Si la capacité n'existe pas : `BLOQUÉ PAR CONTRAT`, démonstration frontend clairement identifiée uniquement en environnement de démo, aucun faux accès en production.

## 7. Procédure d'implémentation atomique — à respecter dans cet ordre

**Étape 0 — Lire et prouver l'existant : obligatoire.**
1. Vérifier HEAD, branches concurrentes, PR en cours, arbre réel et journal des décisions récentes (ne pas se baser seulement sur l'état Git de ce document).
2. Cartographier **fichier → route → écran → provider → modèle → contrat → état test**, pour `TUT-PED-APR-01`, `ADM-PED-APR-02`, `ADM-PED-APR-03` et K-45.
3. Pour chaque capacité, attribuer un seul statut avec preuve : `EXISTE ET FONCTIONNE`, `EXISTE MAIS NON ROUTÉ`, `EXISTE MAIS NON RACCORDÉ`, `ÉCART UX`, `ABSENT`, `NON VÉRIFIABLE`.
4. Comparer les trois références high-fi avec les captures **actuelles et validées** ; relever chaque écart et les éléments du visuel qui doivent être ignorés.
5. Écrire un mini-plan limité à **fichiers existants modifiés**, fichiers réellement manquants, tests impactés, contrats indisponibles. **Pas de code avant cette carte.**

**Étape 1 — Restitution famille.** Perfectionner uniquement `DetailSeancePage` et les composants déjà appelés ; ne pas toucher à l'architecture de l'Historique. Si le port est non branché, préparer la composition avec états honnêtes et consigner le raccordement différé.

**Étape 2 — Administration, réglage.** Ajouter l'UX de politique et des exceptions dans l'inspecteur de Classe existant, **uniquement si absente** ; aucun nouvel écran de réglages administratifs.

**Étape 3 — Administration, publication ciblée.** Rechercher d'abord la vraie lecture admin des cahiers/rapports ; y réutiliser une feuille/inspecteur pour aperçu et partage/révocation. Si aucune destination autorisée n'existe, ne pas créer de route globale par défaut : soumettre l'écart au directeur et arrêter la partie concernée.

**Étape 4 — Recette.** Vérifier parcours multi-rôles, routes réelles, sécurité visible, états, clavier, accessibilité, tailles et non-régression ; capturer 1 écran mobile, 1 écran web de politique et 1 écran web d'aperçu (plus variantes d'états si nécessaires), comparer aux références validées. **Ne pas déclencher déploiement ni changer PROD**.

## 8. Tests d'acceptation minimaux (au moins un test réel par ligne)

| ID | Étant donné | Quand | Alors |
|---|---|---|---|
| A01 | Tuteur autorisé, séance tenue, cahier validé, partage actif | Ouvre Historique → Détail | Lit uniquement le compte rendu partageable de son enfant |
| A02 | Même séance, règle Classe passée à « Désactivé » | Recharge, revient, suit un lien direct | Aucun ancien rapport automatiquement partagé n'est visible ; présences générales restent lisibles |
| A03 | Classe désactivée, élève forcé actif | Ouvre le détail | Seul cet élève peut bénéficier de l'exception |
| A04 | Classe activée, élève forcé inactif | Ouvre le détail | Bloc pédagogique masqué sans bloquer Historique ni le Travail autorisé indépendamment |
| A05 | Partage global désactivé, cahier confirmé | Admin ouvre aperçu et publie **un** rapport | Seul ce rapport devient lisible, aucune règle de Classe/élève modifiée |
| A06 | Rapport publié manuellement | Admin révoque après confirmation | Accès révoqué pour toute lecture famille, y compris deeplink et cache |
| A07 | Rapport explicitement révoqué, Classe activée | Tuteur consulte | Rapport masqué malgré l'activation automatique |
| A08 | Cahier non confirmé/en file/échec | Tuteur ou admin consulte | Pas de compte rendu présenté comme validé ; pas de publication possible |
| A09 | Cours annulé / enseignant absent / panne | Tuteur consulte | Aucun faux constat d'absence élève ni d'apprentissage |
| A10 | Rapport partiellement renseigné | Tuteur consulte | Seulement les champs présents et autorisés, sans rubriques vides trompeuses |
| A11 | Cahier contient notes internes et évaluations d'autres élèves | Tuteur ouvre son détail | Aucune note interne, aucun autre élève, aucune donnée financière |
| A12 | Cahier corrigé après partage | Tuteur consulte | Version autorisée, marqueur de correction si donné ; aucune republication sensible silencieuse |
| A13 | Tuteur change d'élève / de foyer / se déconnecte | Navigue ou rétablit la connexion | Pas de flash ni de cache de l'ancien élève |
| A14 | Élève quitte la Classe | Ouvre une ancienne séance autorisée | Historique de la vraie Classe, accès réévalué selon politique et autorisation de foyer |
| A15 | Deux admins changent simultanément un réglage | L'un confirme sur valeur périmée | Conflit visible, relecture et aucune écriture silencieuse |
| A16 | Serveur refuse une modification | Admin actionne switch / publication | État UI restauré, erreur actionnable, pas de confirmation fictive |
| A17 | Aucun contrat autorisé ne fournit le compte rendu | Tuteur ou admin consulte | État « indisponible », aucun mock trompeur en production |
| A18 | Texte x2, 320/390 mobile, 768 tablette, 1440+ web | Parcourt toutes les actions | Rien coupé, focus accessible, 48dp, ordres de lecture et RTL cohérents |
| A19 | Accès d'un contrôleur ou professeur hors permission | Ouvre un lien de rapport familial | Aucune extension de permission créée par l'UI |
| A20 | Cahier validé, politique de partage ensuite modifiée | Direction vérifie la paie | Validation du cahier et situation de paie restent inchangées |
| A21 | Classe grande et nombreux élèves | Ouvre ses exceptions | Filtres/listes efficaces, aucune double copie des élèves, aucune navigation superflue |
| A22 | Suite de séances pendant partage désactivé, puis réactivation | Tuteur consulte l'historique | Aucun rattrapage rétroactif massif ; les rapports anciennement publiés suivent les règles arrêtées |

## 9. Auto-contrôle et livrable que Claude doit rendre

**Écrans existants à compléter : 3 maximum.** **Nouvelles destinations globales : 0.** **Nouveaux formulaires enseignants : 0.** **Nouveaux moteurs pédagogiques : 0.** **Planches faisant autorité : 3, une par rôle/état principal, dont 1 mobile et 2 web distinctes.** **Scénarios minimaux : 22.**

Rendre :
1. **Table anti-doublon** avec chemins réels, preuves et statut de chaque fonction avant/après ; joindre les captures existantes utilisées.
2. **Diff minimal** avec justification de chaque fichier modifié ; signaler les conflits des PR concurrentes.
3. **Tests et captures de recette** (mobile/tablette/web, clair/sombre, permission, hors-ligne, correction, partage activé/désactivé/manuellement publié/révoqué).
4. **Liste séparée des dépendances Codex/backend** non traitées et des états de démonstration éventuels, sans annoncer comme livrées les capacités non intégrées.
5. **Vérification du parcours CAP-19** déjà confiée à Claude : publication d'offres → demandes → regroupements → classe → enseignant → activation → séance, **uniquement comme garde de recette** ; ne pas recommencer ses écrans.

### Arrêts obligatoires

- **Si la fonction demandée existe et est conforme :** conserver, prouver, ne pas réécrire.
- **Si la source fiable manque :** rendre l'état indisponible et consigner la dépendance, ne pas contourner la confidentialité avec une lecture brute.
- **Si une nouvelle route, table, RPC ou politique produit est réellement nécessaire :** documenter et demander validation ; **aucune initiative hors frontend**.
- **Si le visuel contredit le produit ou le code validé :** préserver le produit et noter la divergence ; ne pas copier les erreurs de la génération d'images.

---

## Annexes : sources locales et pointeurs utiles

- `REWAYAH_FRONTEND_UIUX_BIBLE_V2.clauderules.md` (norme frontend) ; `03_DESIGN_SYSTEM_ET_UX.md` ; captures validées `Accueil.png`, `Foyer Member.png`, `Historique.png`, `Classe Details.png`, `Profil.png`.
- `REWAYAH_TEACHING_CORE_MULTI_AGENTS_V1(2).docx` (séparation notes internes / résumé familial) ; `REWAYAH_REFERENTIEL_ACADEMIQUE_V1(1).docx` (évaluation et charge enseignante) ; `REWAYAH_PED_00_CADRAGE_PARCours_MULTI_ROLES_2026-10-10.md` (garde CAP-19).
- GitHub `ccr-1b1bfa0b-m1kvkk`, `lib/features/suivi_foyer/detail_seance_page.dart`, `lib/features/admin_groupes/groupes_page.dart`, `lib/core/capacites/port_resume_seance_famille.dart` ; PR #21 branche `codex/backend-f2-after-c` et sa migration `0054_seance_resumes_famille.sql`.
- **La présente spécification reste frontend-only.** Les citations du backend constituent des preuves de dépendance, pas des tâches à exécuter.
