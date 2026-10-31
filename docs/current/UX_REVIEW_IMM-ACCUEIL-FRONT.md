# UX_REVIEW_IMM-ACCUEIL-FRONT : accueil d'une famille déjà inscrite

Date : 31/10/2026. Lot : IMM-ACCUEIL-FRONT (mission du pilote du 31/10).
Source : `DECISION-IMMATRICULATION-2026-10-12.md` §5, points 2 à 5. Contrat serveur :
`reclamer_preinscription_apres_preuve()` (migrations 20261012185327 et 20261101000000, B2.1).

## Ce que fait l'écran

- **Preuve d'abord (§5.2).** La connexion par lien à usage unique ou par Google prouve
  l'adresse. L'app n'appelle la reprise qu'avec une session valide et sans profil ; le
  serveur revérifie la preuve. Avant, l'écran est le même pour tout le monde.
- **Un seul appel par compte.** Le résultat reste en mémoire le temps de l'accueil ; un
  échec ne repart que sur « Réessayer ».
- **Accueil (§5.3, §5.4, §5.5).** Titre « Nous vous connaissons déjà », phrase « Votre
  inscription a été reprise. Vous n'avez pas à tout ressaisir. », puis le mot de la
  direction tel quel (mot de patience s'il existe, sinon mot de bienvenue), puis « Vos
  enfants déjà inscrits » : une ligne par élève importé, « À compléter » (elle ouvre
  l'ajout du profil élève, prénom prérempli et choix « pour qui » déduit) ou « À jour ».
  Une seule action pleine : « Continuer », vers l'accueil du tuteur, ou l'accueil de
  l'élève adulte quand la capacité « élève autonome » est servie.
- **Sans pré-inscription** : le parcours d'inscription habituel, inchangé.

## Libellés ajoutés (`accueilInscrits`)

Titre, phrase, « Un mot de la direction », « Vos enfants déjà inscrits », « Leur prénom
est déjà rempli. Il reste à indiquer leur âge. », « À jour », « À compléter » (mots de la
décision §5.5), « Ajouter le profil élève de {prenom} » (mot de `mots-rewayah` : « Ajouter
un profil élève »), « Vous pourrez aussi le faire plus tard, depuis le Foyer. », vide,
échec (K-59 : cause et geste), hors ligne (EA-HL-DOUBLE-1 : ce qui manque).

## Contrôle UX

| Règle | Source | Conclusion | Modification |
| :--- | :--- | :--- | :--- |
| Un titre, une tâche, un CTA | `03_DESIGN_SYSTEM_ET_UX.md`, K-56 | Un seul `ActionPrincipale` plein, en bas (`PageShell.actions`) | Les élèves sont des lignes de lien, jamais des boutons |
| Contenus liés dans une carte à lignes | K-55 | Les élèves dans une seule `CarteLignes` ; le mot dans sa carte ; `PileCartes` entre les deux | Aucune |
| Formulaire semi-automatique | K-57 | Prénom déduit de l'import, nom déduit du compte, « pour qui » déduit ; seul l'âge est saisi | Prénom prérempli et modifiable |
| États d'un écran | `lib/CLAUDE.md` | Vérification en cours (squelette), contenu, vide, échec, hors ligne | Aucune |
| Données personnelles hors de l'adresse | ADR-005 (esprit), WCAG 2.2 sans objet | Le prénom passe en `extra`, jamais dans l'URL | Aucune |
| Ne pas révéler une adresse connue | Décision §5.2 | Rien n'est demandé au serveur avant la session ; le serveur répond la même forme à une adresse non prouvée | Aucune |

## Limites connues

- Le mot d'accueil n'est rendu par le serveur qu'à la première reprise. Un rechargement
  de la page entre la reprise et l'affichage le perd (le serveur ne le redonne pas).
- La reprise ne donne que le prénom des élèves : le nom vient du compte du tuteur.
