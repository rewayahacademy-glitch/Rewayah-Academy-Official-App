# Entrée en classe (CL-4) : harmonisation avec le style en place

Rédigé le 26/09/2026 à partir de l'inventaire du code de `ui/classe-v1`.

Principe : **on prolonge les écrans et les composants qui existent, on ne crée pas une deuxième ligne.** Les maquettes donnent la disposition. Les briques, les mesures et les couleurs viennent du dépôt (règle gelée §4 bis : « la valeur existante prouvée prime »).

## 1. Chaque maquette devient un écran qui existe déjà

| Maquette | Écran existant à faire évoluer | Constat |
|---|---|---|
| CLV-01, élève | `EspaceGroupePage` (`lib/features/tc_espace_groupe/espace_groupe_page.dart`), route `/tc/groupes/:groupeId` | L'ordre existe déjà et suit presque celui des images : identité, carte de séance, « Avant le prochain cours », bibliothèque, progression. **Pas de page neuve.** |
| CLV-02, enseignant | `FicheGroupePage` (`lib/features/fiche_groupe/fiche_groupe_page.dart`), route `/enseignant/groupe/:groupeId` | C'est aujourd'hui une fiche en lecture seule (ENS-07), sans carte de séance. On y ajoute la carte « Prochaine séance » et le bouton « Préparer la séance ». La liste des membres devient la section « Élèves ». Le lien « Ouvrir la revue du groupe » est gardé. |
| CLV-03, préparation enseignant | `PreCours` et `DetailPreCours` (`lib/features/tc_classe_live/pre_vol_classe.dart`), en mode `complet` | La logique par rôle existe déjà : enseignant complet, élève silencieux, tuteur sans test (D-14). On refait son rendu selon la maquette, comme surface focalisée devant la salle canonique `/salle` (plan CL-2), sans nouvelle route publique. |
| Couche d'entrée élève | `PreCours` en mode `silencieux`, et la feuille micro de CL-7 (`feuille_micro_bloque.dart`) | Existe déjà. On aligne seulement le texte « Nous vérifions votre appareil… » et l'enchaînement, sans appui supplémentaire. |

## 2. Briques imposées (contrat C)

- Cartes : `AppCard` (rayon 16, filet, padding 20 ou 24). Pas les rayons de 24 des images.
- Listes de vérifications (Réseau, Micro, Caméra), élèves, tâches : `GroupeReglages` et `LigneRubrique` (ligne 48, icône 24).
- Boutons : `ActionPrincipale` (hauteur 52, rayon 12).
- Pastilles (« Dans 3 h 28 », « Séance en direct », « Micro prêt ») : `StatusPill`. Aucune nouvelle pastille.
- Liens « Voir tout », « Voir les élèves » : `LienFleche`.
- En-têtes de section : `SectionHeader`.
- Chargement : `BlocAsynchrone` et `Skeleton`, sans shimmer.
- États : `EtatSysteme`, `EmptyState`, `EcranResultat` et `OfflineBanner`, déjà réglés en CL-7.
- Avatars : `AvatarTile`, qui se replie sur les initiales, et `PhotoEnseignant` côté enseignant. Aucune photo d'élève : les vues serveur n'en portent pas.
- Mesures : `AppSpacing` (4 à 64), `AppPage.largeurMaxContenu = 1200`, `largeurFormulaire = 640` pour CLV-03, `AppRadius`.

## 3. Coques et navigation : celles du dépôt, pas celles des images

`NavShell` (`lib/core/widgets/nav_shell.dart`) propose trois formes :
- barre basse sous 600 ;
- rail de 80 ;
- barre latérale de 256 à partir de 1200.

La barre latérale des images est donc rendue par `NavShell`, à 256, avec les entrées réelles.

| Rôle | Entrées réelles (gelées) | Ce que montrent les images | Écart noté |
|---|---|---|---|
| Élève | Accueil, Coran, Suivi, Compte | Accueil, Mes classes, Bibliothèque, Progression | « Mes classes » n'est pas une destination : l'Espace Classe s'ouvre depuis Accueil (`/tc/groupes`). Rien n'est ajouté. |
| Élève enfant (Interface guidée) | aucune navigation | — | Conforme à la spec §2.2. |
| Enseignant | Journée, Créneaux, Profil (gel `TEACHER_PARALLEL_BASELINE` §3.1) | Accueil, Mes classes, Élèves, Planning, Bibliothèque, Notes | Rien n'est ajouté. Le chantier Enseignant tranchera. |

Les images montrent un pied de barre latérale avec le compte. Aujourd'hui, seul le tuteur en a un. On ne l'ajoute pas pour l'élève ni pour l'enseignant : ce serait une modification de la coque, hors de CL-4. C'est noté pour HU-1.

## 4. Libellés : ce qui existe déjà dans le code

Rectification de `00_MAQUETTES_ENTREE.md` §3, point 4. Le code et les images disent déjà « Avant le prochain cours », « Voir tout » et « Mes classes » (retour). **On garde ces libellés en place**, par cohérence. Les petites différences avec la spec sont notées pour le directeur, sans rien bloquer.

Les libellés qui changent :

| Où | Existant | Devient |
|---|---|---|
| Carte de séance, élève | « Rejoindre » (`tc.groupe.carte.rejoindre`) | « Rejoindre la séance » : action exacte (contrat B.6) et texte de la spec |
| Préparation, enseignant | « Avant d'ouvrir le cours » (`tc.classe.prevol.titre`) | « Préparer la séance », avec l'introduction « Vérifiez le son avant d'entrer. » |
| CTA de préparation | — | « Entrer dans la séance » ; secondaire « Retour à la Classe » |

Les nouvelles clés vont en i18n slang, en fr et en ar. Aucune chaîne n'est écrite en dur.

## 5. Couleurs et thème

Seuls les jetons du thème figé chrome / violet (K-37) sont utilisés, en clair et en sombre (bascule du thème). On ne reprend aucune teinte des images : lavande, vert et ambre libres. La sémantique existante reste : succès, attention et erreur de `StatusPill`.

## 6. Démonstration

On suit le patron de `/demo/salle` :
- une page `/demo/classe`, hors production, garde `environnementAutoriseDemo` ;
- des ports de démonstration à l'image de `CatalogueClassesDemo` ;
- les états : avant ouverture, salle ouverte, en direct, annulée, aucune séance, terminée, hors ligne, accès refusé ;
- la mention « Démonstration » ;
- les noms déjà en démo : Classe An-Nour, Sayyida Amina, Mariam, Yusuf, Aïcha.
