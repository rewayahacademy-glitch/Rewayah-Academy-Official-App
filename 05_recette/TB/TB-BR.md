> Copie complétée par TB-12 le 10/10 ; l'original vit sur `pilotage/tuteur-v1`, branche interdite à cette session : l'orchestrateur reporte ces ajouts. Les 28 lignes TB-BR-01 à TB-BR-28 ci-dessous sont reprises telles quelles ; les ajouts sont dans la dernière section.

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

## Ajouts de TB-7a à TB-12

Relevés le 10/10/2026 dans les fiches d'étapes (TB-7a, TB-7b, TB-9, TB-10, TB-11b : champs « reste » et « preuve »), la vérification et les corrections de TB-5 à TB-11b (champs « reste », besoins serveur seulement) et les lots de recette TB-12 (champ « br » : T1 écriture, T2 synchro, T3 accès, T4 coquille, captures). Même règle qu'en tête : rien de ceci n'autorise un travail serveur avant BR-1. « Précise » renvoie à la ligne existante que le besoin détaille. La fiche TB-11b numérote ses besoins « TB-BR-16 à 19 » dans un autre sens que ce fichier : ils sont repris ici sous de nouveaux numéros.

### Annotations : dépôt, auteur, effacement

- **TB-BR-29 Relecture à l'abonnement** : `PortAnnotations.suivre` doit rejouer l'état courant au premier abonnement. Aujourd'hui c'est un broadcast sans relecture : `notesDeposeesProvider` ne voit que les couches publiées après son abonnement, un dépôt déjà rempli n'est pas relu (TB-7a). Précise TB-BR-06 et TB-BR-17.
- **TB-BR-30 Filtrage des traits relus** : par portée et par séance (`sessionId`) ; aujourd'hui le suivi part d'un `sessionId` nul (TB-7a). Précise TB-BR-15.
- **TB-BR-31 Dépôt branché** : un dépôt d'annotations réel dans la salle de production ; hors démonstration, le provider lève `UnimplementedError`, capté (TB-7a). Précise TB-BR-15.
- **TB-BR-32 Notes de la vue** : `VueSeance.notesSurface` alimentée par l'état partagé, et non par la démonstration (TB-7a). Précise TB-BR-01 et TB-BR-16.
- **TB-BR-33 Implémentation serveur de `PortAnnotations`** : couche par ressource, séance et portée ; `ajouterTrait` et `retirerTrait` sous RLS (l'élève ne retire que ses traits, l'enseignant gère toute la surface) ; diffusion en temps réel (TB-7b). Précise TB-BR-15 et TB-BR-04.
- **TB-BR-34 Auteur porté par chaque trait** : `TraitVectoriel` ne porte pas d'auteur ; la propriété d'un trait ne vit que dans l'historique de l'appareil (`historiquePersonnelProvider.mesTraits`), et `AnnotationsMemoire` crée une couche partagée au nom du dépôt. Le serveur doit porter l'auteur par trait et refuser qu'un élève retire le trait d'un autre (TB-12, R-08). Précise TB-BR-05 et TB-BR-04.
- **TB-BR-35 Refus distinct « non confirmé »** : un statut de refus séparé quand le dépôt refuse un trait ou un retrait, pour que l'écran dise « non confirmé » (K-59) au lieu de faire disparaître le trait sans phrase (TB-7a, TB-7b ; maintenu par la vérification de TB-7b). Précise TB-BR-18.
- **TB-BR-36 Effacement serveur des notes d'une surface** : supprimer les traits d'une page ou du tableau libre par ancrage, diffusé, appelé par `onEffacerNotes` (aujourd'hui seulement en démonstration) (TB-7b, TB-9). Précise TB-BR-04.
- **TB-BR-37 Encre du dépôt dans les capacités d'effacement** : `voitEffacerNotes` et `notesDuSupport` doivent compter l'encre du dépôt (`notesDeposeesProvider`), pas seulement les notes de la vue (TB-9). Précise TB-BR-36.
- **TB-BR-38 « Effacer les notes » émis sur le canal fiable** : dans la démonstration, `_effacerNotes` appelle seulement `depot.retirerTrait` et n'émet rien. Il faut un `trait_retire` par trait ou un événement d'effacement de surface avec révision (TB-12, R-10). Précise TB-BR-04.

### Encre en temps réel

- **TB-BR-39 Récepteur d'encre chez l'élève** : les événements `tc.outils.*` sont émis mais rien ne les applique chez l'élève. Le récepteur doit appliquer `trait_termine` et `trait_retire`, tenir des pierres tombales des traits retirés ou effacés, et ignorer un aperçu éphémère retardé d'un trait terminé ou retiré (le protocole le laisse passer par contrat) (TB-12, R-07, R-10). Précise TB-BR-02, TB-BR-03 et TB-BR-04.
- **TB-BR-40 Ordre et perte du canal fiable** : un `trait_termine` perdu puis retardé après le retrait (et non un doublon) serait livré ; la garde repose sur l'ordre du canal fiable LiveKit. À vérifier sur staging : canal fiable sans perte et ordonné par émetteur (TB-12, R-10). Précise TB-BR-09 et TB-BR-05.
- **TB-BR-41 Aucun fragment sur la mauvaise page** : seul le dépôt local est prouvé (R-06) ; vérifier par le réseau qu'aucun fragment n'est envoyé ou appliqué sur la page d'arrivée (TB-12). Précise TB-BR-05 et TB-BR-28.
- **TB-BR-42 Accusé par trait** : état de synchronisation serveur du tableau par salle, avec accusé par trait (fiche TB-11b, son « TB-BR-16 »). Précise TB-BR-03 et TB-BR-18.
- **TB-BR-43 Retour de coupure** : `EtatTransport.retabli` émis par l'adaptateur LiveKit réel au retour de coupure ; R-11 en dépend (TB-12). Précise TB-BR-09 et TB-BR-06.

### État partagé et pilotage

- **TB-BR-44 Seul l'enseignant écrit l'état partagé** : table `session_shared_content` sous RLS, écrite seulement par l'identité qui porte `can_publish_data` pour la séance, révision strictement croissante imposée en base. Aujourd'hui `ServiceEtatPartage.publier` écrit le backend AVANT d'émettre, et `EtatPartageMemoire` accepte tout écrivain : la RLS de `session_shared_content` sera la seule barrière d'émetteur (TB-12, R-12 ramené à partiel). Précise TB-BR-07 et TB-BR-11.
- **TB-BR-45 Jeton signé** : `can_publish_data` refusé aux élèves par le jeton signé (`create-room-token`), à vérifier sur staging (TB-12). Précise TB-BR-10 et TB-BR-11.
- **TB-BR-46 Arrivée sur un autre appareil** : lecture de l'état courant par un arrivant (`restaurer` lit le backend) ; seule dépendance manquante de R-11 ; instantané puis traits suivants (TB-12 ; fiche TB-11b, son « TB-BR-17 »). Précise TB-BR-06.
- **TB-BR-47 Salle branchée sur l'état partagé** : `/demo/salle`, la salle réelle et `ClasseLivePage` doivent passer par `portEtatPartageProvider` ; page, affichage, Présenter et Ranger publient une révision. Aujourd'hui `_changerPage`, `_presenter` et `_effacerNotes` de la démonstration restent locaux, et `ClasseLivePage` ne lit pas ce provider (TB-12). Précise TB-BR-01.
- **TB-BR-48 Aperçu et Présenter reliés à une publication** : dans la Bibliothèque, l'Aperçu ne publie rien et Présenter publie une révision. Aujourd'hui `_presenter` dit « Rien n'est diffusé (BR-1) » (TB-12, UX-17). Précise TB-BR-01.
- **TB-BR-49 Supports rangés de la séance** : état partagé « supports rangés » (ressource, version, page de reprise), diffusé à l'enseignant seul ; Ranger = `supportPresente` nul pour la classe, sans notification aux élèves. L'élève après rangement ne se prouve qu'avec cet état réel : la démonstration ne montre que la projection PED-01 (TB-9 ; captures TB-12). Précise TB-BR-17.
- **TB-BR-50 Classe Live sans commandes** : `ClasseLivePage` ne fournit ni `onCommandes` ni `onOutil` pour l'élève, ni `onAutoriserEcrire`, ni `onRanger`, ni `onEffacerNotes` ; à brancher avec le vrai état (TB-9, TB-10). Précise TB-BR-10 et TB-BR-11.

### Droit d'écrire

- **TB-BR-51 Retrait diffusé et commits refusés** : le serveur diffuse le retrait du droit à l'appareil de l'élève (`ecritureRetiree`, `peutEcrire` dans la vue) et refuse tout commit de trait postérieur au retrait. Aujourd'hui seul le client cesse d'ajouter des points ; la diffusion est jouée par un `ValueNotifier` dans le test (TB-10 ; TB-12, UX-20/R-09). Précise TB-BR-10.
- **TB-BR-52 Champ « droit d'écrire »** : un champ par élève dans `EleveSeance`, posé côté serveur sous RLS (TB-10). Précise TB-BR-10.
- **TB-BR-53 RPC autoriser et retirer** : réservées à l'enseignant de la séance (TB-10). Précise TB-BR-10.

### Conservation

- **TB-BR-54 Texte de conservation** : « Les notes sont conservées dans cette séance uniquement. » doit passer à une autre clé quand la sauvegarde durable existe (TB-9). Précise TB-BR-17. Le « TB-BR-18 » de la fiche TB-11b (contrat durable, ni « Réessayer » ni état sauvegardé d'ici là) est la ligne TB-BR-18 existante, confirmée.
- **TB-BR-55 Audio et tableau séparés** : séparation de l'audio et du tableau garantie côté serveur ; une erreur du tableau ne coupe jamais l'audio (fiche TB-11b, son « TB-BR-19 »). Nouveau ; voisin de TB-BR-08 (priorités).

### Supports et langue

- **TB-BR-56 Langue de la ressource** : la ressource porte sa langue ou son sens côté serveur. Aujourd'hui `sensDuDocument` le devine d'après le texte (titre, puis mention), ce qui reste fragile (TB-12, R-18). Précise TB-BR-20.
- **TB-BR-57 Support arabe chez l'élève distant** : diffusion du support arabe annoté vers un élève distant, avec `resource_version` inchangée côté serveur (TB-12, R-18). Précise TB-BR-20 et TB-BR-28.

### Média, observateurs, sortie

- **TB-BR-58 Permission refusée par le navigateur** : le signal réel vient du moteur, pour le micro ET la caméra. `VueSeance.microBloque` existe ; rien d'équivalent pour la caméra (la démonstration n'a que `cameraInterdite`, refus de profil P10). Il faut un état « caméra bloquée par l'appareil » et sa feuille, ou une décision écrite qu'il n'en faut pas (TB-12, UX-23). Nouveau.
- **TB-BR-59 Observateur en focus** : `PresentationObservee` ne porte pas le focus de l'enseignant (voulu) et l'observateur n'a pas d'Agrandir (CTRL-AGRANDIR-1). « Observateur en focus » ne se teste qu'avec Agrandir et le rendu partagé de BR-1 (TB-12, UX-21). Précise TB-BR-11.
- **TB-BR-60 Page et traits lus par l'observateur** : la page lue par l'observateur et les traits ancrés sur cette page sont à vérifier sur staging ; la démonstration lui montre la page 3, sans trait (captures TB-12). Précise TB-BR-11 et TB-BR-28.
- **TB-BR-61 Sortie de l'enseignant** : vérifier que la sortie personnelle de l'enseignant n'arrête pas la séance des autres (aucune RPC de fin appelée) (TB-12, UX-07). Précise TB-BR-12.

Déjà couverts, sans ligne nouvelle : titre Sayyid ou Sayyida et âge de l'élève (TB-10) = TB-BR-25 ; état d'enregistrement réel pour le point rouge (captures TB-12, divergence portée à TB-R) = TB-BR-23.
