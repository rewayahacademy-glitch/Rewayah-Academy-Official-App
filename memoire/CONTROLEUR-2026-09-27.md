# CONTROLEUR-2026-09-27 : règles réutilisables du rôle Contrôleur (C1 à C21)

**Sources.**
- Décisions du directeur du 27/09/2026 : `specs/08_controleur/00_DECISIONS_DIRECTEUR.md` (mot pour mot).
- Document du directeur : `specs/08_controleur/08_CONTROLEUR_V1_UX_SECURITE.md` (V1, 27/09/2026, 1 072 lignes). Ne le relire que par section, à la demande de l'étape.
- Cinq planches : pilotage `14_controleur/V/PLANCHE-1..5.png`.
- Rectifications : pilotage `14_controleur/V/00_MAQUETTES_CONTROLEUR.md`.

**Ordre d'autorité.**
1. La demande la plus récente du directeur (ici : `00_DECISIONS_DIRECTEUR.md`, 27/09).
2. DESIGN-GOV (gelé).
3. K-42, le style CL-4.
4. CLASSE-ENTREE (R1 à R21) : le contrôleur entre dans la salle, elles s'appliquent toutes.
5. Le présent fichier.
6. Le document 08.
7. Les planches, qui sont des exemples de composition et jamais une règle métier.

## Métier

- **C1. La visite a lieu pendant le cours, jamais quand le contrôleur le veut** (directeur, 27/09 : « sinon ça ne sert absolument à rien »).
  - Une mission n'est actionnable que lorsque la séance est **en direct**, ouverture décidée par le serveur (R4, E6).
  - Avant : aucune mission ou une ligne d'état calme, jamais un bouton grisé. Après la fin de la séance, la mission devient « Cette mission n'est plus disponible. »
  - Pas de « Plus tard » pour la visite, pas de revisionnage d'un enregistrement (doc §8.2), pas de visite hors séance.
  - Seul le compte rendu peut être terminé après la sortie (bloc « Compte rendu à terminer », doc CTR-01).
- **C2. Le rapport part automatiquement à l'administration** (directeur, 27/09).
  - Aucun interrupteur, aucune case, aucune option « Partager avec l'administration » ou « Canal direct admin » dans le compte rendu.
  - À la sortie de la salle, la visite et ses faits automatiques sont transmis ; l'observation humaine rejoint le même rapport à l'envoi.
  - Le bouton « Écrire à l'administration » ouvre une **discussion directe** (CTR-04). Il n'est jamais une condition de transmission.
- **C3. Rewayah choisit, le contrôleur observe** (doc §3.2, §3.3, §5).
  - Pas de planning, pas de liste de visites à venir, pas de « Voir le planning », pas de catalogue des séances.
  - Aucune recherche de classe, d'élève, d'enseignant ou de personne.
  - Le client ne tire jamais une séance au sort : il affiche la mission reçue.
- **C4. Le système calcule les faits, le contrôleur ne les ressaisit jamais** (doc §1.1).
  - Heure prévue, entrée réelle, retard, durée, reconnexions, participants, classe, enseignant : lecture seule.
  - Un écart s'écrit avec un mot (« 8 min de retard »), jamais par la couleur seule.
  - Seuls les faits de la liste du doc §1.1 s'affichent ; rien d'ajouté (pas de ligne « Enregistrement » inventée).
- **C5. Observation muette et invisible, dans la salle unique.**
  - `/salle` en rôle `RoleSalle.controleur` (`masked_controller`) ; aucun second moteur, aucune seconde salle, aucune copie du mode Tuteur (doc §2.2).
  - `/tc/observation/:seanceId` reste la porte du tuteur et ne devient pas un second système contrôleur.
  - Commandes permises : Son reçu, Agrandir le support, Quitter. Tout le reste est interdit (doc CTR-02).
- **C6. Contrôleur est une capacité, pas une identité** (doc §1.2, §4.2, §9.3).
  - Enseignant ou Admin passent en Contrôle par `Compte > Espaces`, avec le même compte ; un raccourci d'en-tête ouvre ce même sélecteur.
  - En contrôle, aucune action de l'autre rôle ne reste active ; revenir exige de quitter la mission.
  - Le tuteur n'est jamais contrôleur. On ne contrôle jamais sa propre Classe ni une séance où l'on remplace (doc §9.4).
- **C7. Refus par défaut** (doc §9.5).
  - Autorisation perdue ou incertaine : rien du contenu précédent ne reste affiché.
  - Messages génériques du document : « Votre accès au contrôle n'est plus actif. » avec « Revenir à mon espace » ; « Cette mission n'est plus disponible. » avec « Revenir au contrôle ».
- **C8. Minimisation** (doc §8, §14.7).
  - Visible : nom de la Classe, enseignant (nom professionnel et photo publique, R18), objectif ou cycle, support actif, prénoms des élèves présents, flux en direct, faits automatiques.
  - Jamais : e-mail, téléphone, adresse, identité légale complète d'un mineur, paiements, appareils, notes administratives, rémunération, exports, téléchargements.
  - Un élève se choisit dans le roster autorisé (prénom et identifiant pédagogique), jamais par saisie libre ni recherche.
- **C9. Diffusion différée** (doc §3.4, §11.2).
  - L'enseignant n'est jamais prévenu en temps réel ; aucun compteur « dernière visite » ; le tuteur ne reçoit aucun rapport brut.
  - Le bandeau permanent (`PermanentNotice`, « Cours enregistré, visite de contrôle possible ») reste identique pour tous les rôles.
- **C10. Un rapport envoyé n'est jamais réécrit.** Seul « Ajouter un complément » existe (auteur, date, heure, rapport parent, contenu, motif facultatif). Le journal d'audit est un objet distinct, jamais modifiable.
- **C11. Pas de score.**
  - Pas d'anneau de couverture, pas de « 1/4 · 25 % », pas de « Visites restantes », pas de compteurs Conformes, Remarques, À suivre.
  - Au plus une ligne « Cette semaine : N contrôles réalisés », si la donnée est fiable.
- **C12. Pas de cache durable.** Le brouillon reste en mémoire pendant la tâche ; toute persistance hors ligne attend une décision de sécurité (doc §8.3).

## Écran et style (en plus de K-42 et R1 à R21)

- **C13. Navigation à 4 destinations, dans cet ordre** : Contrôle, Historique, Échanges, Compte (doc §4.1).
  - Barre en bas sur mobile, rail sur tablette, barre latérale sur ordinateur (`NavShell`).
  - Pas de « Accueil », « Mes visites », « Rapports », de cloche ni de bascule de thème dans l'en-tête.
  - Aucune navigation dans la salle ni dans le compte rendu : ce sont des tâches focalisées.
  - Cette règle remplace l'ancien choix « une seule destination, sans barre » de `nav_shell.dart` (document du directeur plus récent).
- **C14. CTR-01 a un seul emplacement de mission** (R4, E11).
  - La carte montre : Classe, heure, durée prévue, enseignant, nombre d'élèves, statut de salle.
  - Séance pas encore en direct : ligne calme. En direct : un seul bouton, « Commencer le contrôle ».
  - Pas d'écran de détail intermédiaire (« Détails de la visite », « Rappels avant la visite ») : on entre pendant le cours, chaque minute compte. Le rappel d'invisibilité tient en une ligne sur la carte.
- **C15. Compte rendu en parcours** (`PageParcours`), une question par page.
  - Aucune valeur présélectionnée ; « Rien à signaler » s'envoie en une action.
  - Pas de grille de critères, pas de liste déroulante pour la nature ou le domaine : des cartes de choix.
  - Pas de compteur de caractères tant qu'aucune limite serveur n'est fixée (E6).
- **C16. Libellés : ceux du document, tels quels.**
  - Contrôle, Votre prochaine mission, Commencer le contrôle, Compte rendu, Avez-vous quelque chose à signaler ?, Rien à signaler, Ajouter une observation, Signaler un point important.
  - Natures : Point positif, À suivre, Intervention Admin souhaitée. Domaines : Pédagogie, Interaction avec les élèves, Gestion de la classe, Respect du cadre, Comportement / climat, Autre. Personne : Enseignant, Classe entière, Élève précis, Aucun participant précis.
  - Envoyer le compte rendu, Écrire à l'administration, Ajouter un complément ; statuts Envoyé, Complément ajouté, À terminer ; fils Réponse reçue, En attente.
  - Jamais : Inspection, Surveillance, Espion, Note, Score, Conforme, Terminé, Remarque (comme statut), Qualité pédagogique (comme type), groupe, Session.
  - Un libellé absent du document est une question au directeur, pas une invention.
- **C17. Échanges : un fil par mission ou par sujet** (doc CTR-04).
  - Le contexte de la visite est épinglé en haut du fil, joint automatiquement.
  - Pas d'onglets « Tous, Non lus, Mes demandes », pas de pièce jointe, pas de fil titré par le nom d'un enseignant ou d'un élève.
  - Aucun participant de la Classe n'a accès à ce canal.
- **C18. Historique sur le modèle `Historique.png`** (doc CTR-05).
  - Filtres Période, Classe, État. Pas de filtre Enseignant.
  - Lignes groupées : date, Classe, enseignant, durée observée, statut. Pas de tableau à sept colonnes, pas de pastille Niveau colorée, pas de menu « … ».
- **C19. Données de démonstration réalistes, datées de 2026 et cohérentes d'un écran à l'autre** (E20).
  - Les planches mélangent les rôles (Karim Belkacem y est à la fois enseignant et contrôleur) : ne rien recopier.
  - L'enseignant est un homme par défaut (Sayyid) ; la taille des Classes vient des données de démonstration, jamais d'une constante.
- **C20. Contrôleur invité : hors lot.** La planche 5 est gardée en réserve. L'architecture (capacité datée, périmètre, expiration) ne doit rien empêcher de ce futur modèle.
- **C21. Légal : démonstration seulement.** Aucune ouverture réelle sans DPIA, base légale, durée de conservation et politique de monitoring validées (doc §14, §15). Ne jamais coder « consentement = base légale ». Ne jamais promettre « capture impossible ».
