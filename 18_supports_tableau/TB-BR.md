# Supports et tableau : besoins serveur et temps réel (branchement BR-1)

Une ligne par besoin. Démonstration seulement jusqu'à BR-1 (K-28) : rien de ceci n'autorise un travail serveur dans le chantier TB (plan §14, §21). Relevé à TB-0 (02/10/2026) sur `corrections/revue-directeur-2026-10` @ `0796f75`, `supabase/` lu sans écrire. À compléter par chaque étape TB et par TB-12.

## Temps réel (LiveKit Data Channels, plan §10)

- **TB-BR-01 Présentation** (support, version, page, affichage) : message fiable, état complet à une révision, appliqué d'un bloc. Réutiliser `typeRevisionEtatPartage`, `ServiceEtatPartage`, `ReducteurEtatPartage` et `sujetProtocolePedagogique` ; aucun second sujet ni second client.
- **TB-BR-02 Aperçu de trait et pointeur** : canal non fiable (lossy), lots au plus toutes les 40 ms pendant le geste, environ 1 200 octets (sous 1 300), numéros de lot. Vérifier que `TraitEnCours.pointsParPaquetParDefaut` (3 points) respecte la cadence.
- **TB-BR-03 Trait terminé** : message fiable, tracé compact (`simplifierTrait`), au plus 15 Kio de charge, découpage et assemblage bornés ; remplace l'aperçu.
- **TB-BR-04 Retirer, annuler, effacer** : messages fiables ciblés par identifiant, révision et déduplication ; jamais un remplacement global (annuler ne touche pas le trait d'autrui).
- **TB-BR-05 Enveloppe minimale** : version de protocole, séance, contexte de présentation, support/version/page ou tableau libre, identifiant d'opération, **auteur lu de l'identité de connexion** (jamais du message), révision, données. Le contexte empêche un vieux paquet de repeindre une autre page ou une page revisitée après effacement.
- **TB-BR-06 Demande d'état et snapshot** : réponse ciblée au participant (arrivée tardive, reconnexion), snapshot avec sa révision puis opérations postérieures ; écriture suspendue jusqu'à récupération ; trou détecté = demande d'état.
- **TB-BR-07 Arbitrage** : l'enseignant attribue la révision commune ; s'il est absent, aucun nouveau maître choisi en silence (contrat de remplacement existant ou indisponibilité).
- **TB-BR-08 Bornes** : taille de trait, nombre de traits, fréquence, données entrantes validées (un client autorisé peut envoyer un message malformé) ; files bornées, priorité aux changements pédagogiques sur aperçus et snapshots.
- **TB-BR-09 Adaptateur** : `AdaptateurTransportLiveKit` mappé sur `publishData` de la version du dépôt (`livekit_client ^2.12.0`), vérifié dans la documentation de cette version ; parler fiable / non fiable, jamais TCP / UDP.

## Droits et identité

- **TB-BR-10 Autorisation d'écrire** : droit effectif côté serveur (capacité signée du jeton ou RPC), annoncé par message mais jamais créé par lui ; retrait immédiat ; aucun commit non autorisé appliqué (UX-20).
- **TB-BR-11 Rôles** : présenter, changer de page, ranger, effacer pour tous = enseignant seulement ; tuteur observateur et contrôleur en lecture seule de l'état partagé.
- **TB-BR-12 Quitter / Terminer** : distinguer sortie personnelle et fin pour tous si la capacité existe ; aucune confirmation ajoutée à une simple sortie.

## État partagé et conservation

- **TB-BR-13 Affichage Support / Avec notes / Tableau** : `session_shared_content.display_mode` n'accepte que `page`, `verse`, `focus` (`0032_tc_catalogue.sql:404`, `ModeAffichagePartage`). L'affichage du plan est un **autre axe** (fond visible, calque visible) : champ ou valeur à ajouter au contrat par une migration autorisée à BR-1, jamais dans TB.
- **TB-BR-14 Tableau libre** : `annotation_layer` est rattachée à une ressource (`resource_id`) ; il faut un contexte « tableau libre de la séance » sans ressource, ou une ressource technique, à décider à BR-1.
- **TB-BR-15 Couches** : `annotation_layer` est par auteur (`auteur_profile_id`, index uniques) et `annotation_trait` une ligne par trait (gomme ciblée) : conforme au plan. Vérifier la politique de partage des couches des élèves autorisés (une couche par élève ou couche de séance de l'enseignant).
- **TB-BR-16 Snapshot durable** : instantané compact après opérations stabilisées, au changement de support ou au rangement, et en fin de séance ; écritures regroupées ; jamais un point par écriture ; jamais seulement à la fermeture d'onglet. Portée `temporaire` jamais écrite (règle de la base).
- **TB-BR-17 Point de reprise par support** : page et couches retrouvées en séance ; entre séances seulement si le contrat durable est branché. Sans lui, l'écran dit « Les notes sont conservées dans cette séance uniquement. ».
- **TB-BR-18 Statut de sauvegarde réel** : « Les notes de cette séance ne sont pas sauvegardées. » et « Réessayer » branchés sur le vrai résultat d'écriture durable, jamais sur `publishData`.

## Fichiers, catalogue, cache

- **TB-BR-19 Fournisseur des pages** : relever le fournisseur réellement branché (R2 selon les sources canoniques, « Supabase Storage » dans un prompt ; `catalogue_local.dart:15` : aucun bucket de supports aujourd'hui). Un seul adaptateur de fichiers, aucun second stockage.
- **TB-BR-20 Pages immuables et versionnées** : dimensions canoniques et ratio fournis par le serveur ; source et licence vérifiées ; édition Hafs conforme pour toute page coranique ; aucune image générée.
- **TB-BR-21 Cache** : page courante et voisines, borné en mémoire et sur disque ; résolution selon l'écran et le zoom, même cadrage ; cache Web configuré, CORS, URL signées (`cached_network_image` seul ne suffit pas sur le Web) ; purge au retrait d'accès.
- **TB-BR-22 Catalogue de la classe** : ressources autorisées, couvertures, recherche, versions, rubrique Récents avec point de reprise (port catalogue réel).

## Contexte de la salle

- **TB-BR-23 Enregistrement** : état effectif pour le témoin rouge ; inconnu = pas de témoin.
- **TB-BR-24 Contrôle** : « Contrôle possible » et « Contrôle actif » lus du contrat d'observation (`VisiteSeance`) ; un seul contrôle à la fois (BR-CT-18).
- **TB-BR-25 Profil** : titre Sayyid/Sayyida et âge (tutoiement A4) lus du profil réel.

## Dépendances et mesures

- **TB-BR-26 perfect_freehand** (plan §9.5) : demande un ajout à `pubspec.yaml` (accord écrit, K-19). En démonstration, rendu par `_PeintreAnnotations` existant. Si le paquet est accepté, la même version sur tous les clients ; sinon, documenter l'algorithme commun.
- **TB-BR-27 Mesures sur appareils** : fluidité du trait, délai de page, délai du trait final, mémoire et trafic, sur smartphone modeste, iPad et Web, avec coupure et réordre de paquets (§15) ; jamais « zéro latence ».
- **TB-BR-28 Recette réseau réelle** : iPad vers smartphone et Web (cercle sur le même mot), deux élèves autorisés, reconnexion, coupure de l'enseignant, fermeture totale puis reprise (§15).
