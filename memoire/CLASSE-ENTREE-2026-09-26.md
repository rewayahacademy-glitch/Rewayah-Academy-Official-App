# CLASSE-ENTREE-2026-09-26 : règles réutilisables de l'entrée en classe et de la salle

**Source.** Document du directeur `specs/02_classe_et_visio/REWAYAH_CLASSE_ENTREE_PREFLIGHT_CHRONO_V1.md`, reçu le 26/09/2026, et ses consignes orales du même jour. Le directeur a demandé que ses règles réutilisables soient écrites **pour tous les agents**.

**Portée.**
- Ces règles valent pour tout écran qui touche une Classe, sa préparation ou sa salle, quel que soit le rôle.
- Elles s'ajoutent aux règles gelées `DESIGN-GOV-2026-09-26` sans les modifier.
- Elles s'appliquent quand un écran concerné entre en implémentation.
- **Elles ne rouvrent aucune étape terminée** : l'harmonisation se fait en HU-1, sauf ordre explicite du directeur.

**Priorité.** Pour les écrans d'entrée en classe, ce document prime sur la spec 02 quand ils diffèrent : c'est la demande la plus récente du directeur (DESIGN-GOV §1).

## Modèle

- **R1. Un seul produit.** La Classe est l'espace pédagogique permanent ; la Classe Live n'est qu'un état temporaire de cette Classe.
  - Le chemin est unique : Mes classes → carte → Espace Classe → préparation → attente → salle → retour à l'Espace Classe.
  - L'utilisateur ne doit jamais croire ouvrir un autre produit.
- **R2. Une responsabilité par écran.**
  - Espace Classe de l'élève : « mon prochain cours, et ce que je dois faire avant ».
  - Espace Classe de l'enseignant : « quel cours, à qui, et quoi préparer ».
  - Préparation : « mon appareil est-il prêt ».
  - On ne mélange pas ces responsabilités.
- **R3. Pas de barre latérale interne à la Classe, pas de multiplication d'onglets.** La page reste verticale et calme.

## Temps et accès

- **R4. Pas de bouton d'entrée désactivé pendant des jours.** Avant l'ouverture de la fenêtre, on affiche le temps restant. Le bouton n'apparaît qu'à l'ouverture réelle, décidée par le serveur.
- **R5. Le temps se calcule depuis des horodatages qui font foi** (début, fin prévue, heure de référence), jamais depuis un seul `Timer` local.
  - On ne code jamais une durée en dur (« 1 h », « 1 h 30 »).
  - Après une reconnexion ou un retour d'arrière-plan, on recalcule sans reprendre un compteur suspendu.
- **R6. On n'affiche jamais un temps négatif.** À zéro, on écrit « Temps prévu écoulé ». Le temps écoulé peut continuer. Aucune déconnexion automatique n'en découle.
- **R7. Un chrono n'est jamais une preuve de présence ni d'assiduité.**

## Médias, permissions et réseau

- **R8. Micro et caméra sont coupés à l'entrée, pour tous les rôles.**
  - On écrit « Micro détecté · Micro coupé à l'entrée », jamais « Micro activé ».
  - Aucune caméra ne s'ouvre d'elle-même.
- **R9. On demande une permission dans le contexte où elle sert, jamais à l'ouverture de l'application.** On ne la demande pas si une politique interdit l'appareil concerné.
- **R10. Pas de faux contrôle inerte pour la symétrie.** Un sélecteur que la plateforme ne permet pas, comme la sortie audio, n'est pas affiché.
- **R11. Aucune erreur technique brute dans l'interface** (ICE, RTP, SDP, TURN…) : seulement des messages humains. Le détail va dans les journaux.
- **R12. Le réseau se lit dans le moteur LiveKit existant.** Aucun second moteur de mesure, pas de speedtest ni de Mbps comme métrique principale.
  - Les états sont : Connexion bonne, Connexion instable, Reconnexion…, Connexion rétablie, Impossible de se reconnecter.
- **R13. Préparation.**
  - L'enseignant vérifie réseau, micro, sortie audio, caméra si utile, et voit le contexte : Classe, temps avant le début, support, reprise, élèves attendus.
  - L'élève a une préparation **presque silencieuse** : un état minimal « Tout est prêt » ; il n'intervient que sur un vrai blocage.
  - Un seul bouton dominant, « Entrer dans la classe ». Les réglages (changer de micro, tester le son…) restent secondaires ou tertiaires.

## Contenu et données

- **R14. Une seule bibliothèque**, la même hors de la salle et dedans. Aucun système parallèle.
- **R15. L'enseignant connaît l'élève pédagogiquement, pas personnellement.**
  - Il ne voit jamais : téléphone, e-mail, adresse, identité détaillée du foyer, paiements, données des tuteurs, géolocalisation, identifiants d'appareil.
- **R16. « Reprendre le cours » est une action contextuelle, jamais une rubrique permanente.**
- **R17. « Avant le prochain cours » compte au plus 3 actions.** Pas de longue liste, pas de formulaire narratif.
- **R18. Photo publique obligatoire de l'enseignant**, avec le titre Sayyid ou Sayyida. On n'affiche jamais un code technique comme identité.

## Chargement et mise en page

- **R19. Chargement.**
  - Les skeletons existants reproduisent la carte de séance et les blocs attendus. Pas de spinner central.
  - En préparation, chaque vérification évolue seule, sans bloquer la page.
- **R20. Le web n'agrandit jamais le mobile.** Deux colonnes seulement quand elles aident vraiment la lecture. Le bouton reste près du contexte qu'il confirme (16 dp, trailing).

## Orchestration

- **R21. Une directive qui ne peut pas entrer dans l'étape en cours sans casser l'ordre** devient une étape explicite du tableau, marquée « À appliquer lors de la passe correspondante ». On continue ensuite le travail prévu. Pas de marche arrière, pas de reprise opportuniste d'un lot terminé.

## Chrono de séance (décision du directeur, 26/09, reportée)

- **LIVE-CHRONO-01** (tableau) : l'étape reste à faire, et le chrono n'est pas construit maintenant.
- Il affiche le temps écoulé et le temps restant jusqu'à 00:00:00, en respectant R5 à R7.
- **Il reste discret.**
  - Selon le directeur, la maquette l'a raté : il prenait trop de place.
  - Ce n'est pas une course de vitesse. Il sert seulement à connaître la durée de la séance, ce que les outils courants, comme Google Meet, ne proposent pas.
  - Il prend la forme d'une ligne compacte dans l'en-tête de la salle, jamais d'un cadran ou d'un grand compteur.
- **LIVE-PAUSE-01** (tableau, plus tard) : une pause que l'enseignant configure à l'avance. C'est noté pour ne pas l'oublier, et rien n'est conçu avant une décision du directeur.
