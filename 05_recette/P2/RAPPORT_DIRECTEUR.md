# Rapport au directeur — Rôle Tuteur, version 1

Écrit pour vous, sans jargon technique. 25 septembre 2026.

## En une phrase

L'espace du tuteur (le parent) est terminé côté application : tous les
écrans existent, un bouton mène à chacun, et un test automatique appuie sur
ce bouton pour vérifier qu'il fonctionne. Ce qui manque encore ne dépend
plus de nous : cela dépend du serveur (pas encore branché sur toutes les
fonctions) et de deux décisions qui vous appartiennent.

## Ce que le tuteur peut faire, écran par écran

**Bienvenue** — Premier écran vu par une personne qui n'a pas encore de
compte. Elle peut créer un compte, se connecter si elle en a déjà un, ou
essayer la démonstration (voir plus bas).

**Inscription** — Un parcours en plusieurs petites étapes : à qui sert le
compte (moi-même ou mon enfant), prénom et nom, genre, puis un résumé avant
de valider. Chaque étape a un bouton « Continuer » et un bouton retour.

**Accueil** — La page qui s'ouvre après connexion. Elle montre la classe du
jour de l'enfant sélectionné, la prochaine séance, et un raccourci vers la
dernière séance passée. Un sélecteur permet de changer d'enfant si le foyer
en a plusieurs.

**Classe** — La fiche d'une classe : son planning, le travail donné, les
ressources mises à disposition et la progression de l'enfant. On y arrive
en touchant une classe depuis l'Accueil.

**Catalogue** — La liste des classes proposées, avec le jour, l'heure, le
fuseau horaire et le niveau de chacune. Permet de choisir une classe pour
un enfant.

**Foyer** — La liste des enfants rattachés au compte, avec un bouton pour
en ajouter un, et l'accès aux appareils partagés du foyer.

**Fiche d'un enfant** — En touchant un enfant depuis le Foyer : ses
informations, son inscription, l'interface qui lui est adaptée, sa caméra,
ses accès et ses appareils.

**Appareils** — Comment relier un appareil (tablette, téléphone) à un
enfant : par caméra (scanner un code affiché) ou en tapant un code à la
main. La liste des appareils déjà reliés est aussi visible.

**Historique** — Les séances passées et les observations passées, avec le
détail de chacune.

**Observation** — La salle où le parent peut regarder une séance en
direct, avec un compteur du nombre de visites restantes et un écran de fin
de visite.

**Compte** — Les informations du parent, la sécurité, les accès, les
paiements, les préférences, l'apparence, l'aide, les informations légales
et les consentements donnés.

**Notifications** — La liste des messages envoyés au parent (rappels,
alertes), accessible depuis une cloche en haut de l'écran.

**Mode démonstration** — Un bouton « Essayer la démonstration », visible
sur l'écran Bienvenue et sur l'écran de connexion, qui montre l'application
remplie de données inventées (un foyer avec deux enfants, des séances,
des observations), sans toucher au vrai serveur. Un bandeau
« Démonstration » reste affiché en haut de chaque écran pendant cette
visite, pour qu'on ne confonde jamais avec de vraies données. Ce bouton
n'apparaît que dans la version d'essai (dite « de recette »), jamais dans
la version que les familles utiliseront : c'est volontaire, pour qu'une
vraie famille ne voie jamais de données inventées.

## Ce qui est « indisponible » en attendant le serveur, et pourquoi

Certains boutons ou certaines pages affichent aujourd'hui un message
« indisponible » plutôt qu'un vrai contenu. Ce n'est pas une erreur : c'est
l'application qui dit honnêtement qu'elle attend une pièce qui n'existe
pas encore côté serveur, plutôt que d'inventer un résultat. Exemples :

- **Créer mon propre profil d'élève** (quand le parent veut suivre les
  cours lui-même) : le formulaire existe mais le serveur ne sait pas
  encore enregistrer ce cas précis.
- **Consentements, identité, notifications, paiements, progression,
  résumé, aide** : certains de ces écrans montrent encore un message
  d'attente tant que le serveur correspondant n'est pas branché.
- **Catalogue des classes réellement ouvertes** : le catalogue sait
  afficher jour, heure et fuseau horaire, mais tant que le serveur ne
  fournit pas la vraie liste des classes disponibles, l'écran dit
  honnêtement « pas encore ouvert » plutôt que d'inventer des classes.

Rien de tout cela n'est caché : chaque cas a été listé et expliqué, pour
qu'on sache exactement ce qui reste à brancher côté serveur, dans une
prochaine étape du chantier.

## Les décisions qui vous attendent

1. **Le texte de consentement à l'observation.** Le parent doit
   accepter un texte avant qu'une observation puisse avoir lieu. Ce texte
   doit être écrit et validé par vous avant de pouvoir considérer cette
   partie comme terminée.

2. **La « pull request » brouillon et l'aperçu à autoriser.** Pour que
   vous (et d'autres) puissiez voir et essayer l'application dans un
   navigateur, sans passer par un ordinateur de développeur, il faut créer
   une proposition de mise à jour du dépôt principal (« pull request »,
   encore à l'état de brouillon, rien n'est fusionné sans votre accord) et
   une adresse d'aperçu en ligne. Cette étape touche des services en
   dehors de l'ordinateur de travail (GitHub, Vercel) : elle attend votre
   feu vert avant d'être faite.

## Où en est le tableau de suivi

Toutes les lignes du rôle Tuteur (préparation, quatre lots d'écrans,
observation, mode démonstration, intégration, revues, corrections,
vérification finale) sont marquées terminées. Les lignes qui attendent
encore vous sont marquées clairement « à faire », avec le motif écrit à
côté : le texte de consentement et l'autorisation de la proposition/aperçu
en ligne.

---

## Annexe — Matrice de recette (pour vérification technique)

Pour chaque écran : la route (l'adresse interne de l'écran), le bouton qui
y mène, le test automatique qui appuie sur ce bouton, l'emplacement des
images de preuve, et le statut.

Toutes les images de preuve sont dans `05_recette\<lettre>\captures`
(voir `05_recette\OU_TROUVER_LES_CAPTURES.md` pour le détail dossier par
dossier), au format téléphone et ordinateur, thème clair et sombre.

| Écran | Route (`Routes.…`) | Test qui appuie sur le bouton | Captures | Statut |
|---|---|---|---|---|
| Bienvenue | `bienvenue` | `test/router/navigation_test.dart` + `test/features/inscription_test.dart` | `05_recette/A/captures` | fait |
| Connexion | `connexion` | `test/router/navigation_test.dart`, `test/features/inscription_test.dart` | `05_recette/A/captures` | fait |
| Récupération d'accès | `connexionRecuperation` | `test/features/inscription_test.dart` | `05_recette/A/captures` | fait |
| Inscription — étapes (usage, identité, genre, récapitulatif) | `inscription` (parcours par étapes) | `test/features/inscription_test.dart`, `test/accessibilite/clavier_test.dart` | `05_recette/A/captures` | fait |
| Accueil | `tuteurAccueil` | `test/router/navigation_test.dart`, `test/features/classe_tuteur` | `05_recette/c/captures` | fait |
| Notifications | `tuteurNotifications` | `test/router/navigation_test.dart` | `05_recette/e/captures` | fait |
| Catalogue des classes | `tuteurClassesCatalogue` | `test/features/classe_tuteur/catalogue_classes_test.dart` | `05_recette/c/captures` | fait |
| Classe (et planning, travail, ressources, progression) | `classePour`, `classeSousPage` | `test/features/classe_tuteur` | `05_recette/c/captures` | fait |
| Foyer | `tuteurFoyer` | `test/features/foyer/foyer_page_test.dart` | `05_recette/B/captures` | fait |
| Ajouter un enfant | `tuteurAjouterEnfant` | `test/features/foyer` | `05_recette/B/captures` | fait |
| Créer mon propre profil (indisponible) | `tuteurAjouterPourMoi` | `test/router/navigation_test.dart` | `05_recette/B/captures` | indisponible (attend le serveur, DB-FOY-01) |
| Appareils du foyer | `tuteurFoyerAppareils` | `test/features/appareils` | `05_recette/D/captures` | fait |
| Appairer un appareil (scanner / code) | `appairerPour` | `test/features/appareils` | `05_recette/D/captures` | fait |
| Fiche d'un enfant (informations, inscription, interface, caméra, accès, appareils) | `ficheElevePour`, `ficheEleveSousPage` | `test/features/foyer` (fiche_eleve) | `05_recette/B/captures` | fait |
| Choix d'une classe pour un enfant | `parcoursPour` | `test/parcours/parcours_offres_test.dart` | `05_recette/c/captures` | fait |
| Historique des séances | `tuteurSuivi` | `test/features/historique` | `05_recette/e/captures` | fait |
| Historique des observations | `tuteurSuiviObservations` | `test/features/historique` | `05_recette/e/captures` | fait |
| Détail d'une séance | `seancePour` | `test/features/historique` | `05_recette/e/captures` | fait |
| Détail d'une observation | `observationsSeancePour` | `test/features/historique` | `05_recette/e/captures` | fait |
| Salle d'observation en direct | (entrée depuis Classe → « observer ») | `test/teaching_core`, `test/features/classe_tuteur` | `05_recette/o/captures` | fait |
| Fin de visite d'observation | (écran de sortie de la salle) | `test/features/demo` (`fin_visite_test.dart`) | `05_recette/o/captures` | fait |
| Compte | `tuteurCompte` | `test/features/compte/compte_tuteur_test.dart` | `05_recette/e/captures` | fait |
| Compte — informations | `compteTuteurSousPage('informations')` | `test/features/compte` | `05_recette/e/captures` | fait |
| Compte — sécurité | `compteTuteurSousPage('securite')` | `test/features/compte` | `05_recette/e/captures` | fait |
| Compte — accès | `compteTuteurSousPage('acces')` | `test/features/compte` | `05_recette/e/captures` | fait |
| Compte — paiements | `compteTuteurSousPage('paiements')` | `test/features/compte` | `05_recette/e/captures` | indisponible en partie (attend le serveur des paiements) |
| Compte — préférences | `tuteurComptePreferences` | `test/features/compte` | `05_recette/e/captures` | fait |
| Compte — apparence | `tuteurCompteApparence` | `test/features/compte` | `05_recette/e/captures` | fait |
| Compte — aide | `compteTuteurSousPage('aide')` | `test/features/compte` | `05_recette/e/captures` | fait |
| Compte — informations légales | `compteTuteurSousPage('informations-legales')` | `test/features/compte` | `05_recette/e/captures` | fait |
| Compte — consentements | `tuteurCompteConsentements` | `test/features/compte`, `test/features/consentements` | `05_recette/e/captures` | fait, texte à valider par le directeur (voir décisions) |
| Mode démonstration (entrée) | (bouton « Essayer la démonstration » sur Bienvenue et Connexion) | `test/features/demo/entree_demonstration_test.dart` | `05_recette/demo/captures` | fait |
| Mode démonstration (contenu simulé) | (foyer, classes, séances, observation, présence fictifs) | `test/features/demo/mode_demonstration_test.dart` | `05_recette/demo/captures` | fait |

Constats de la revue des routes et parcours (P2-09) : aucun blocage.
Un test transversal (`navigation_test.dart`) relie désormais chacune des
34 routes du rôle Tuteur au fichier de test qui appuie réellement sur son
bouton, pour que cette preuve ne soit plus dispersée. Détail complet :
`05_recette/P2/P2-09.md`, `05_recette/P2/P2-10.md` (accessibilité),
`05_recette/P2/P2-08.md` (fidélité aux maquettes), `05_recette/P2/P2-11.md`
(sécurité et honnêteté).

---
Rapport écrit par le poste B (coordinateur et exécutant), session
B-2026-09-25-coord.
