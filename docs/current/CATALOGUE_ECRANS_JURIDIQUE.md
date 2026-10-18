# Catalogue des écrans : textes juridiques en lecture (JUR-APP-1, ASSETS-DIR-1)

Registre courant des feuilles de lecture des textes juridiques. Le catalogue
historique `docs/design/08-catalogue-ecrans.md` n'existe plus dans le dépôt
depuis la remise à plat ; les fiches vivent dans `docs/current/`.

Sources : `14_controleur/juridique/POLITIQUE_CONTROLE_ENSEIGNANTS.md` (partie B),
`INFO_ELEVES_PARENTS.md` et `COORDONNEES_LEGALES.md` (pilotage). Restes et
conditions avant fusion : `JUR-APP-1_RESTES.md`.

## Écrans

| Id | Écran | Contenu | Code |
| :--- | :--- | :--- | :--- |
| JUR-1 | Politique de contrôle des enseignants (feuille de lecture) | Les dix sections de la partie B, mot pour mot, listes et passages en gras gardés ; section 10 : coordonnées légales | `lib/features/dossier/politique_controle.dart` (`ouvrirPolitiqueControle`, `TextePolitiqueControle`) |
| JUR-3 | Informations légales (liste des six textes) | Mentions légales, Conditions d'utilisation et de vente, Annulation et remboursement, Confidentialité, Cookies, Protection des enfants ; version et date en tête | `lib/features/juridique/juridique_pages.dart` (`JuridiquePage`, `ListeTextesJuridiques`), route `/juridique` |
| JUR-4 | Un texte juridique | Sections du texte (`t.juridique.*`, fr et ar), lignes de coordonnées, repères « [à compléter par la direction : ...] » tant qu'une valeur manque | `JuridiquePage` : `TexteJuridiquePage`, route `/juridique/<texte>`, contenu `textes_juridiques.dart` |
| JUR-2 | Information sur les visites de contrôle (E-1, E-2) | Lien « En savoir plus » du bandeau de la salle et textes d'information des élèves | `lib/features/salle_seance/information_controle.dart` |

## Place dans la navigation

- JUR-1 : aucune route propre. Ouverte par `AppBottomSheet.ouvrirLecture` depuis
  le lien « Lire la politique de contrôle » sous la clause du contrat
  (`signature_page.dart`) et depuis le profil de l'enseignant, section des
  contrats (`profil_enseignant_page.dart`). Lisible quel que soit l'état de la
  lecture des acceptations ; elle se ferme d'un geste, rien n'est à accepter ici
  (la confirmation de réception est dans le contrat).
- JUR-2 : le lien est refusable (`InformationControle.lienAccepte`) et masqué
  sous 388 de large ; la mention elle-même ouvre alors la même lecture.

JUR-3 et JUR-4 : routes `/juridique` et `/juridique/<texte>`, **publiques**
(`Routes.publiques`, lisibles aussi connecté, en attente ou suspendu).
Entrées : lien « Informations légales » sous la carte de connexion, et la
page « Informations légales » du Compte (sous les documents acceptés).
Version `2026-10-v1`, texte du 18/10/2026 (`VersionsJuridiques`). Ce que seule
la direction peut donner se remplit à un seul endroit,
`CoordonneesJuridiques.renseignes` (hébergeur légal, pays d'hébergement,
durées de conservation, droit applicable, relecture par un conseil,
modalités de remboursement, responsable de la protection des enfants).
Même sens sur le site : `docs/orchestration/site-public/juridique-2026-10-18.json`.
Contrôle : `test/features/juridique/textes_juridiques_test.dart`.

## États

| État | JUR-1 | JUR-2 |
| :--- | :--- | :--- |
| Chargement | sans objet : texte compilé dans l'application, aucune lecture | sans objet |
| Contenu | les dix sections, défilement jusqu'à la dernière phrase à 320 px et texte 200 % | le lien et la lecture |
| Vide | sans objet : le texte existe toujours | sans objet |
| Erreur | sans objet : aucune lecture ne peut échouer | sans objet |
| Hors ligne | sans objet : aucun réseau en jeu, l'écran n'affiche rien de plus qu'en ligne | sans objet |

Si l'un de ces textes venait un jour du serveur, les cinq états deviendraient
nécessaires et cette fiche serait à reprendre.

## Contrôles

`test/features/politique_controle_test.dart` (texte, section 10, 320 et 1440,
texte 100 % et 200 %, clair et sombre, aucun mot coupé, dernière phrase
atteinte), `test/features/dossier_test.dart`,
`test/features/profil_enseignant_test.dart`.
