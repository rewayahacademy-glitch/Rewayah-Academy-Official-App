# Rewayah - inventaire fonctionnel du MVP et recette
Version : 22 septembre 2026. Cette liste est une cible de livraison, pas un constat d'implémentation. Statuts à renseigner par l'agent sur le dépôt : spécifié / codé / intégré / testé / déployé.

## Frontière de livraison
`MVP opérationnel` signifie pouvoir enregistrer les élèves actuels, leurs foyers et enseignants, les placer dans des classes réelles à enseignant permanent, enseigner, suivre la présence et transmettre un travail. `MVP complet` ajoute tous les modules marqués M ci-dessous. Le premier périmètre ne doit jamais se faire passer pour le second.

| Domaine | Fonction et comportement attendu | Priorité | Recette déterminante |
|---|---|---|---|
| Fondations | Environnements séparés, migrations, RLS, sauvegarde, journaux, CI web et déploiement, contrôle des secrets | M | Installation neuve, accès entre foyers refusé, push main effectivement déployé |
| Identité | Connexion, récupération de compte, rôles admin/comptable/contrôleur/enseignant/tuteur/élève, compte en attente, activation/suspension | M | Routage selon autorisation serveur et état de compte |
| Foyer | Tuteur et plusieurs enfants, adulte autonome en foyer d'une personne, profil par élève, gestion des appareils | M | Deux foyers isolés ; adulte autonome sans faux parent |
| Inscription | Onboarding court, consentements et pièces nécessaires en coffre privé, statut et validation admin ; migration encadrée des élèves/enseignants existants | M | Famille existante intégrée sans perte et accès refusé avant validation requise |
| Diagnostic | Pré-diagnostic déclaratif, diagnostic pédagogique humain, proposition de cycle/groupe, décision tracée | M essentiel | Débutant en F1 ; élève avancé dans groupe compatible ou attente |
| Catalogue classes | Classes créées par admin, enseignant attitré, curriculum/niveau, capacité, jours, heure, durée, fuseau IANA et récurrence | M essentiel | Aucun professeur différent par séance ordinaire ; aucune collision |
| Choix familial | Voir les classes avec toutes leurs séances, horaire local, enseignant, places, liste d'attente si rien ne convient | M essentiel | Dernière place réservée une fois ; DST Europe/USA exact |
| Exceptions planning | Annulation, congés, absence, remplacement temporaire et transfert documentés | M | Séance déplacée sans perdre groupe, enseignant permanent ni historique |
| Accueil par rôle | Tuteur : enfants et prochaines séances ; élève : classe et travail ; enseignant : journée ; admin : exceptions et opérations ; contrôleur : planning | M | Une action principale, états vide/erreur/hors ligne |
| Espace Groupe | Carte et page : identité lisible, photo publique enseignant, capacité réelle, prochaine séance datée, durée, décompte, travail et bibliothèque | M essentiel | `Rejoindre` selon fenêtre serveur ; session prolongée sans timer négatif |
| LiveKit | Salle par séance, token limité serveur, micro/caméra selon politiques, réseau faible, audio prioritaire, reconnexion, aucun lien public | M essentiel | Professeur + élève rejoignent et retrouvent support après coupure |
| Visiteurs | Tuteur observateur borné ; admin visible/incognito ; contrôleur incognito audité, sans micro/caméra | M | Serveur refuse publication et dépassement de durée |
| Présence | Webhooks signés et idempotents, retard, temps connecté distinct du temps de cours, correction administrative auditée | M essentiel | Double webhook ne double pas présence ; incident réseau identifié |
| Bibliothèque | Catalogue hors/en cours ; Coran Hafs structuré de source approuvée, Mushaf fidèle vérifié, texte, leçon, PDF et image versionnés | M essentiel | Prof choisit et affiche un passage natif chez l'élève sans vidéo de l'écran |
| Outils enseignant | Suivi partagé, pointeur, sélection, marqueur, masquage, annotation séparée, reprise, travail court | M | État partagé cohérent après reconnexion ; texte coranique inchangé |
| Après cours | Cahier prérempli, résultat individuel et exceptions, résumé tuteur, préparation du prochain cours | M essentiel | Enseignant valide rapidement ; élève retrouve son travail |
| Pédagogie minimale | Programme/cycle/unité en base versionnable, état actuel de l'élève, progrès basique, compétence à renforcer ; pas d'évaluation automatisée | M essentiel | Continuité enseignant et progression non perdue |
| Communications | Annonces et messages utiles famille/enseignant/admin selon droits ; notification cours, changement et validation ; archivage approprié | M | Pas de coordonnées familiales exposées à l'enseignant |
| Contrôle et administration | Recherche et gestion personnes/classes, anomalies, revue d'accès, journal d'audit, grille de contrôle et exports serveur autorisés | M | Export accessible uniquement au rôle autorisé, journal consultable |
| Paiement transitoire | Encaissement externe saisi/vérifié par admin, état d'accès daté et relance humaine ; aucune fausse intégration paiement | M essentiel | Dossier payé/hors paiement identifiable, accès autorisé ou bloqué correctement |
| Mode hors ligne | Planning et supports autorisés en cache, reprise de file d'attente pour notes conciliables ; entrée visio requiert le réseau | M | Aucun accès à une autre famille via cache |
| Qualité | Modes clair/sombre, `Interface guidée`, mobile/tablette/web, RTL arabe, clavier, lecteur d'écran, grosses cibles | M | Tests visuels, sémantiques et parcours sur petits écrans |

## Enregistrement de cours : arbitrage explicite
ADR-002 ancien inclut audio systématique, stockage R2 et rétention 30 jours ; le Control System V2 plus récent dit « aucun enregistrement audio/vidéo par défaut ». Ne pas activer automatiquement sur de vrais élèves avant décision écrite sur finalité, consentement, politique de rétention, chiffrement, accès et conformité. Le système de salle doit pouvoir porter un état d'enregistrement réel et visible, jamais une indication fictive. Ce seul arbitrage ne bloque pas l'enseignement en direct non enregistré si les règles de protection applicables sont respectées.

## Livrer sans tromper
Un écran maquetté, un service inutilisé ou une migration non appliquée n'est pas une fonctionnalité livrée. Pour chaque ligne M, noter propriétaire du code, preuve, état et blocage. La branche CORE24 déjà auditée « non prête » doit repasser la recette complète avant fusion. Regrouper les lots par parcours vertical, pas par nombre de fichiers.
