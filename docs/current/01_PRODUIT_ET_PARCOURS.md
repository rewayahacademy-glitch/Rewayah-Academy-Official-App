# Rewayah - produit, rôles et parcours
Version : 22 septembre 2026. La première cohorte réelle sert de priorité de livraison ; la vision complète demeure modulaire.

## Objectif
Une famille choisit une classe compatible avec son fuseau et son parcours. L'élève suit durablement le même enseignant, assiste aux séances et poursuit son travail entre les cours. Les équipes administrent, enseignent, contrôlent et suivent ce cycle dans une application simple.

## Rôles et vues
| Rôle | Accueil et actions majeures | Restrictions |
|---|---|---|
| Élève enfant ou adulte | Prochain cours, groupe, rejoindre, bibliothèque, travail, progression lisible | Données des autres familles interdites |
| Tuteur | Foyer, inscription/choix de classe, horaires, présence, progression, appareils, paiements quand disponibles | Accès limité à ses élèves ; observation bornée |
| Enseignant | Journée, groupes, cours, supports, cahier de transmission, progrès, disponibilité | Aucun contact privé des familles ni documents d'identité |
| Admin | Centre opérationnel, personnes, classes, admissions, affectations, sécurité, paramètres, finance autorisée | Journaliser les actions sensibles |
| Contrôleur | Planning, observation discrète autorisée, compte rendu | Aucun micro ni caméra ; entrée auditée |
| Comptable | Encaissements, rapprochement, rémunération et exports selon modules livrés | Aucun accès au contenu pédagogique privé par défaut |

## Admission et classes
- Admin définit un catalogue limité de classes stables : parcours, niveau, public, enseignant attitré, jours et heures récurrents, durée, fuseau de référence, capacité, état et date de début. Construire les plages autour des populations Europe, Amérique du Nord et autres régions servies ; ne pas inventer les horaires exacts sans calendrier et disponibilités des enseignants.
- Diagnostic pédagogique à l'entrée. Débutant : parcours de base. Élève avancé : placer au groupe existant le plus proche du niveau évalué ; exception documentée si aucun groupe approprié. Respecter les décisions humaines du référentiel académique.
- Exposer à la famille les classes réellement ouvertes, horaires locaux avec dates et changements d'heure, fréquence, niveau, enseignant, places disponibles. Montrer les séances de la même classe avant validation.
- Une inscription atomique réserve ou place en attente suivant capacité et prérequis. Protection contre doubles inscriptions, places fantômes et collisions d'enseignant. L'admin valide affectation et exceptions. Un changement de professeur est un événement exceptionnel avec historique et information de la famille ; aucune rotation automatique selon la séance.
- Enseignant responsable d'un groupe sur toutes ses séances récurrentes, sauf remplacement temporaire tracé. Annulations, reports, jours fériés, DST et remplacements modifient des occurrences, pas silencieusement le contrat de classe.

## Espace Groupe
Carte : nom courant, cours/niveau, photo publique de l'enseignant, `Sayyid`/`Sayyida`, places X/Y réelles, prochaine séance (jour, date, heure locale, durée), timer. Une page de groupe rassemble séance, travail, bibliothèque et progression utile. À environ T-20 configurable, `Rejoindre` devient disponible ; présence académique à partir du début et selon événements serveur. Si séance prolongée, afficher « Cours toujours en cours », jamais un temps négatif. Montrer les deux fuseaux utiles à l'enseignant ; avertir en amont des changements d'heure.

## Classe et supports
LiveKit transporte audio/vidéo et événements temps réel ; Supabase décide droits, affectations et présence. Micro/caméra initialement coupés selon politique de session ; qualité audio prioritaire, bascule sur réseau faible, reconnexion avec continuité de salle. Support partagé natif et synchronisé, pas un partage vidéo de PDF. Bibliothèque hors et dans la classe : Coran structuré Hafs de source validée, rendu Mushaf fidèle si prouvé, lecture agrandie, texte structuré, leçons, PDF et images. Version publiée immuable, source et licence vérifiées. Enseignant choisit, pointe, marque, masque, annote sur couche distincte et fixe le travail. L'élève suit l'enseignant pendant la présentation tout en gardant ses préférences personnelles sans modifier la vue commune. Session persistante lors de la navigation.

Roster limité aux données pédagogiques nécessaires, sans coordonnées familiales. Tuteur observateur silencieux : politique serveur par groupe, défaut hérité de la dernière décision documentée (activé, une visite, 120 secondes cumulées par séance), configurable et audité ; vérifier la compatibilité avec les protections des mineurs avant ouverture réelle. Admin peut observer en mode visible ou incognito, contrôleur incognito seulement, avec journalisation et information générale des usagers. Aucun déclenchement distant de microphone.

Après séance : cahier de transmission court prérempli, présence avec corrections auditables, travail à préparer, position de reprise, exception ou signalement. Le retour élève ne nécessite pas de formulaire obligatoire. Enregistrement audio et rétention contrôlés seulement une fois consentement, infrastructure, accès audités et règle de conservation opérationnels ; ne pas feindre la conformité par un simple drapeau UI.

## Académie et pilotage
Parcours de base lecture de l'arabe et Coran, salat et invocations essentielles, puis orientation lecture autonome ou hifz selon objectif. Diagnostic, progression individuelle dans une cohorte, évaluations et délivrance de certificats restent soumis à approbation académique. Codes de compétences invisibles dans l'interface.

Tarifs, salaire enseignant de référence (4 USD/h dans la spécification économique), capacités, durée, exceptions, bourses et politiques de crédits : données configurables, versionnées et décidées humainement. La finance complète, prévision, paie, payouts et conseiller IA sont des chantiers séparés ; premier onboarding doit pouvoir fonctionner avec paiement hors application consigné par l'admin et accès daté. Ne jamais afficher une facture ou un paiement simulé comme réglé. Objectif de résultat de 2 000 USD/mois dans l'ancien document : cible de scénario, jamais garantie ni formule codée en dur.

## Recette de première cohorte
Créer tuteur et élève réels, diagnostiquer et choisir une classe réellement disponible, confirmer le même enseignant sur plusieurs jours, ouvrir une séance, vérifier accès et absence de fuite entre foyers, rejoindre en tuteur/élève/enseignant, partager une page du Coran, perdre et retrouver le réseau, enregistrer présence et travail, retrouver le cours suivant. Exécuter sur mobile et web avec fuseaux Europe et Amérique du Nord et changement DST. Sans parcours complet raccordé et constaté, statut : non prêt.
