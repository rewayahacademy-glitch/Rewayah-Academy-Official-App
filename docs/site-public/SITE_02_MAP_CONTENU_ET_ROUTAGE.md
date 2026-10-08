# SITE 02 | Carte éditoriale et routage

Date : 8 octobre 2026. Propriétaire du lot : éditorial/SEO. Source de contenu machine : `site-public/content/pages.json`.

## Schéma éditorial

`pages.json` est un JSON UTF-8 directement consommable par le générateur. `schema` décrit le format et `pages` indexe les pages par URL canonique `/fr/...`. Chaque page contient :

- `title` : titre HTML unique;
- `description` : description HTML unique;
- `h1` : titre visible unique;
- `intro` : introduction facultative;
- `sections` : liste ordonnée `{id,title,paragraphs,points?,links?}`;
- `cta` : `{label,href}`;
- `indexable` : éligibilité SEO cible après validation; ne change jamais le noindex imposé à l'aperçu et ne vaut pas autorisation de publication;
- `status` : `ready` (copie préparée pour revue/intégration, sans feu vert de production) ou `blocked` (dépendances non fermées).

La clé `site` contient le crédit d'auteur exact et les deux liens Facebook avec des libellés distincts. Les adresses publiques sont rangées par usage. Les fiches d'articles, de parcours et de poste sont conditionnelles et restent hors de `pages.json` jusqu'à publication réelle. En aperçu, `ready` et `blocked` peuvent être servis avec un indicateur visible de préparation; toutes les réponses d'aperçu portent `noindex`, même si `indexable` vaut `true`. Les entrées `blocked` sont exclues de tout artefact de production. `ready` décrit seulement l'état de la copie et ne donne aucun feu vert de production ou d'indexation.

La branche courante est une branche de travail et n'est pas autorisée à publier en production. Toute publication reste soumise aux portes d'intégration et au feu vert distinct du propriétaire. Le générateur doit appliquer ces règles de mode sans déduire l'autorisation de production depuis `status` ou `indexable`.

**Lecture de la matrice :** `ready` indique une copie préparée pour revue. `indexable: true` indique uniquement une éligibilité SEO cible après validations et autorisation distincte. En aperçu, toutes les routes sont servies comme préparation avec `noindex`. Aucun de ces champs ne permet de publier la branche en production.

## Matrice des routes fixes

| Route | Objectif et H1 | Sections | CTA | Title / description uniques | État publication |
|---|---|---|---|---|---|
| `/fr/` | Présenter l'Académie et l'offre sans chiffres actifs non vérifiés. H1 : « Des cours de Coran en ligne, un suivi pour toute la famille. » | Foyer; cours; suivi; fonctionnement; tarifs; confiance; FAQ/articles; footer | Commencer mon inscription → `/connexion` | Cours de Coran en ligne / Rewayah Academy : présentation des cours, enseignants, espace familial et suivi | `ready` pour aperçu seulement, noindex; aucun feu vert de production. Offre factuelle bloquée sans projection publique (effectifs, durées, fréquence); prix avant CTA également bloqué |
| `/fr/familles` | Expliquer profils, responsabilités du tuteur et suivi. H1 : « Un espace familial pour accompagner chaque élève » | Profils; tuteur; suivi; organisation; aide | Ouvrir Rewayah → `/connexion` | Espace familial et suivi des élèves  /  Rewayah / rôle du tuteur, profils et suivi | `ready`, indexable |
| `/fr/cours` | Expliquer les objectifs pédagogiques sans prétendre à des cohortes ouvertes. H1 : « Des parcours pour apprendre et pratiquer la lecture du Coran » | Objectifs; adultes/enfants; méthode; groupes | Commencer mon inscription → `/connexion` | Cours de Coran pour enfants et adultes  /  Rewayah / objectifs d'apprentissage pour enfants et adultes | `ready`, indexable; fiches conditionnelles absentes |
| `/fr/cours/[parcours]` | Décrire un parcours réellement publié. H1 déterminé par la fiche validée | Langue; âge; objectif; prérequis; durée/fréquence/effectif issus de la publication active; patterns publiés | Voir les possibilités d'inscription → `/connexion` | Générés depuis le titre et la description de la fiche publiée | Non générée tant qu'aucun parcours n'est publiquement publié; aucune fiche fictive |
| `/fr/comment-ca-marche` | Décrire l'onboarding et la proposition de classe après traitement. H1 : « De l'inscription à la proposition de classe » | Connexion; propositions; traitement; proposition de classe; mineur | Continuer dans Rewayah → `/connexion` | Comment se déroule l'inscription  /  Rewayah Academy / étapes entre ouverture, horaires proposés et classe | `ready`, indexable |
| `/fr/tarifs` | Expliquer les éléments à vérifier avant paiement, sans prix fantôme. H1 : « Les tarifs doivent être confirmés avant tout paiement » | Montant; calcul familial; conditions; assistance | Ouvrir le parcours Rewayah → `/connexion` | Tarifs des cours  /  Rewayah Academy / récapitulatif de commande et vérifications | `blocked`, `noindex`; projection commerciale active et règles territoriales non prouvées |
| `/fr/academie` | Présenter l'histoire et l'approche. H1 : « Une Académie tournée vers l'apprentissage du Coran » | Projet; famille; société exploitante; contact | Découvrir les cours → `/fr/cours` | À propos de Rewayah Academy / projet pédagogique et approche des cours | `ready`, indexable; mentions société finales vérifiées séparément |
| `/fr/articles` | Index éditorial vide honnête, sans fabriquer de billets. H1 : « Articles et repères pour apprendre » | Catalogue vide; orientation | Consulter l'aide → `/fr/aide` | Conseils et articles  /  Rewayah Academy / articles pédagogiques publiés | `ready`, indexable; les fiches n'existent qu'après validation/publication |
| `/fr/articles/[slug]` | Fournir un article complet référencé. H1 issu de l'article | Texte; références; liens pédagogiques; métadonnées d'auteur/date masquées par défaut | Consulter le cours lié → route publiée | Depuis titre et résumé de l'article | Non générée sans article publié; dates et auteur cachés par défaut |
| `/fr/aide` | Répondre aux questions d'inscription, horaires, mineurs, tarifs et contact. H1 : « Aide et questions fréquentes » | Inscription; horaire; mineur; tarif; support; facturation | Contacter l'assistance → mailto support | Aide et questions fréquentes  /  Rewayah Academy / cours, inscription, familles et assistance | `ready`, indexable |
| `/fr/recrutement` | Expliquer la prise de contact sans suggérer un poste ouvert. H1 : « Travailler avec Rewayah Academy » | Postes ouverts; enseignement; demande d’information ou candidature spontanée | Demander une information → mailto recrutement | Recrutement  /  Rewayah Academy / informations sur le recrutement et les candidatures | `ready`, indexable; aucune offre en cours ni parcours candidat affirmés |
| `/fr/recrutement/[poste]` | Décrire uniquement une annonce active. H1 depuis l'annonce | Mission; profil; langue; disponibilité; statut; conditions validés | Commencer ma candidature → parcours de candidature existant, à vérifier | Depuis titre et résumé du poste | Non générée sans poste publié; aucun parcours candidat supposé |
| `/fr/contact` | Router les demandes vers les alias spécialisés. H1 : « Contacter Rewayah Academy » | Général; support; recrutement; facturation; limites des canaux | Écrire pour une question générale → mailto contact | Contacter Rewayah Academy / coordonnées par usage | `ready`, indexable; fonctionnement des boîtes à vérifier avant formulaire ou promesse de suivi |
| `/fr/protection-des-enfants` | Présenter les principes sûrs et signaler les procédures non confirmées. H1 : « La protection des enfants demande des règles claires » | Tuteur; données; procédures à confirmer; signalement | Contacter l'assistance → mailto support | Protection des enfants  /  Rewayah Academy / principes et signalement | `blocked`, `noindex`; responsables et procédures opérationnelles à nommer et confirmer |
| `/fr/legal/mentions` | Exposer l'identité réglementaire complète. H1 : « Mentions légales » | Identité; contacts; hébergement/publication | Contacter l'exploitant → mailto contact | Mentions légales  /  Rewayah Academy / identité de l'exploitant | `blocked`, `noindex`; registre, siège, hébergeur et domaine canonique à confirmer |
| `/fr/legal/conditions` | Publier les conditions de service et vente applicables. H1 : « Conditions de service » | Offre; paiement; accès; durée; territoire; acceptation | Contacter Rewayah Academy → mailto contact | Conditions de service  /  Rewayah Academy / conditions applicables | `blocked`, `noindex`; modalités contractuelles et territoires manquants |
| `/fr/legal/annulation-remboursement` | Expliquer rétractation, pause, absence, annulation et restitution. H1 : « Annulation et remboursement » | Publication bloquée; informations à valider | Question de facture → mailto invoice | Annulation et remboursement  /  Rewayah Academy / règles à valider | `blocked`, `noindex`; règles et mécanisme de demande opérationnel absents |
| `/fr/legal/confidentialite` | Décrire traitements, droits et notices enfant. H1 : « Confidentialité et données personnelles » | Publication bloquée; éléments à documenter; contact | Contacter Rewayah Academy → mailto contact | Confidentialité  /  Rewayah Academy / données personnelles, mineurs et droits | `blocked`, `noindex`; cartographie des traitements, durées, fournisseurs et responsable absents |
| `/fr/legal/cookies` | Lister uniquement les technologies réellement utilisées. H1 : « Cookies et technologies de stockage » | Inventaire requis; vérifications | Contacter Rewayah Academy → mailto contact | Cookies et technologies  /  Rewayah Academy / cookies et technologies utilisées | `blocked`, `noindex`; inventaire technique/consentement non vérifiés |
| `/fr/accessibilite` | Informer sur l'accessibilité et le statut des tests. H1 : « Accessibilité du site Rewayah Academy » | Engagement; état des vérifications; signalement | Signaler une difficulté → mailto support | Accessibilité  /  Rewayah Academy / vérifications et signalement | `ready`, indexable; aucune conformité AA revendiquée |

## Routes d'aperçu, publication et liens

- Le CTA d'inscription va toujours à `/connexion`; Flutter reprend vers `/inscription` si le compte n'a pas encore de profil.
- Aucune fiche conditionnelle n'est générée sans enregistrement publié : parcours, article et poste sont absents plutôt que remplis avec du contenu d'exemple.
- Les pages `blocked` restent non indexables et ne peuvent pas être publiées en production. Un avertissement d'aperçu peut les identifier comme indisponibles, sans présenter cet avertissement comme une clause.
- La page tarifs reste bloquée pour l'indexation et l'offre active tant que les prix publiés, la devise, les taxes et les conditions territoriales n'ont pas été rapprochés.
- Les dates commerciales de référence et les chiffres de capacité ne sont pas exportés dans le JSON comme paramètres d'offre active.
- Le footer utilise deux libellés sociaux distincts et le crédit exact « Site conçu par Abdoulaye Mouhidine Sow. » Les liens fournis sont conservés; leur fonctionnement réseau n'a pas été vérifié dans ce lot.
- Aucun H1 secondaire n'est prévu. Les éléments de section sont des titres de niveau inférieur au H1; le générateur doit préserver cette hiérarchie.
- Les titres/descriptions sont distincts pour chaque route fixe. Les métadonnées des routes dynamiques se construisent depuis les fiches publiées et doivent être vérifiées contre les doublons avant génération.

## État des preuves

| Fait / décision | Preuve ou limite | Conséquence éditoriale |
|---|---|---|
| CTA `/connexion` | SITE_00 : route Flutter; `/inscription` reprend après connexion sans profil | Aucun CTA public direct vers `/inscription` |
| Parcours horaires | Chapitre A et SITE_00 : intention sur patterns publiés, traitement admin, proposition ultérieure de classe | Aucun siège, enseignant, disponibilité ou réservation instantanée annoncés |
| Contacts | Quatre alias publics confirmés dans les spécifications; fonctionnement actuel non contrôlé | Affichage par usage; aucune promesse de délai ni formulaire simulé |
| Tarifs et capacité | Pas de projection publique sûre prouvée dans le dépôt | Pas de chiffre actif dans la copie; `/fr/tarifs` bloquée |
| Histoire | Académie lancée le 1er mai 2024; LTD immatriculée le 4 août 2025 | Dates distinctes; détails du registre bloqués |
| Mentions et politiques | Siège, registre, traitements, cookies, responsabilités et règles territoriales à vérifier | Pages contractuelles présentes comme routes bloquées, sans clauses inventées |
| Articles/postes/cours | Pas de preuve de contenus actuellement publiés | Pages d'index honnêtes; fiches conditionnelles absentes |
| Facebook et crédit | URL et libellés fixés par le propriétaire | Deux liens distincts; auteur du site séparé de l'auteur des articles |
| U+2014 | Contrôle statique prévu sur les deux fichiers | Aucun tiret cadratin utilisé dans la copie |
