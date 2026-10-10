# RECETTE-NUIT-A (11/10/2026) : eleve, eleve adulte, tuteur/famille, enseignant

Branche `claude/recette-nuit-a`, depuis `origin/ccr-1b1bfa0b-m1kvkk` (f3a0680a). Jetons : 18 (ccr seul). Aucune PR.

## Methode

1. Lecture statique de chaque dossier `lib/features/**` des quatre roles : couleur litterale, texte en dur, taille tactile litterale sous 48, test de role. Resultat : 0 couleur, 0 texte, 0 taille ; les tests de role sont au tableau ci-dessous.
2. Balayage rendu (`test/accessibilite/recette_nuit_a_test.dart`, garde permanente) : 40 routes sans parametre ou a identifiant inconnu, atteintes par le vrai routeur avec la session de chaque role, a 360 px, en francais et en arabe (RTL), texte x1 et x1,6, clair et sombre, Interface guidee de l'eleve. Mesure : aucune exception de mise en page, aucun mot coupe ou tronque, aucune cible tactile (`Pressable` actif) sous 48. 276 cas verts.
3. Etat hors ligne : les memes routes avec `horsLigneProvider` a vrai montrent le bandeau hors ligne, sans exception.
4. Etat « introuvable » : seance, parcours, classe, fiche eleve, Classe de l'enseignant, cahier, revue avec un identifiant inconnu dit ce qui manque et propose le retour (lu au rendu).

Le balayage a d'abord rendu des faux positifs, ecartes : polices de test (Ahem) au lieu des vraies, nœud de semantique plus petit que la cible reelle (`LienFleche` 225x31 pour une cible mesuree a 48).

## Releve

| Ecran | Defaut | Gravite | Corrige |
| :--- | :--- | :--- | :--- |
| `/compte` (eleve, enseignant) | Ligne « Confidentialite / Bientot disponible » toujours inerte, rendue (une action qui ne peut pas aboutir ne se rend pas) ; decision deja prise par MA-GR-1 | basse | non : decision produit |
| `salle_page.dart` | La preparation d'entree se choisit sur `session.role` (eleve / enseignant / autre), pas sur une capacite | moyenne | non : refonte du flux d'entree, hors « petit et local » |
| `compte_page.dart` (l.276, 713) | `foyerDisponible` et le resume lisent le role de session | moyenne | non : meme motif |
| `entree_observation_page.dart`, `options_entree_observation.dart` | Options et pre-requis par role tuteur / admin | moyenne | non |
| `/enseignant/seance/:id/cahier` | Un identifiant inconnu ouvre le formulaire (le serveur refuse au depot) | basse | non |
| `/enseignant/groupe/:id/revue` | Classe inconnue : « Rien ne demande votre attention » au lieu de « pas l'une des votres » | basse | non |
| `/eleve/coran` | Non balaye : ouvre `Supabase.instance` au montage (hors rendu du Coran, zone interdite) | info | sans objet |

Aucun defaut petit et local avec un test rouge avant correction n'a ete trouve dans le perimetre balaye : pas de commit de correction. La garde ajoutee empeche la regression.

## Non couvert (a faire avec des donnees)

Les cinq etats avec contenu reel (liste pleine, liste vide, erreur serveur) de chaque ecran a parametres : les tests de chaque feature les portent deja un a un ; ce lot n'en a pas ajoute.
