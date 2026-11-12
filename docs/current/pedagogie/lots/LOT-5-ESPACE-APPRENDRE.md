# Lot 5 · ESPACE-APPRENDRE

> Branche `claude/espace-apprendre`, ouverte le 12/11/2026 sur `claude/socle-programme` (lot 1) fusionnée avec `claude/charte-ecole`.
> Plan : `PLAN-DE-CONSTRUCTION.md`, section « Lot 5 ». Arbitrages de l'architecte E1 à E7 (12/11/2026). Demande du directeur du 12/11/2026 : « Le lien de la barre qui dit Apprendre doit afficher tout ce qui est lié à l'apprentissage, pas seulement le Coran, sinon on dirait Lire. »
> Statut : **présent dans le code, testé localement, NON prouvé en production.** Aucune migration : c'est un lot d'écrans. Ce qui est lu vient de `etape_eleve_lecture` (lot 1, installée par le directeur) et du catalogue existant.

## Ce que le lot réutilise

| Existant | Comment |
|---|---|
| `destinationsPour` (`nav_shell.dart`), branche `/eleve/coran` de la coquille élève | La destination « Apprendre » de l'adulte pointe sur la nouvelle route `/eleve/apprendre` ; celle du mineur, qui s'appelait « Coran », devient « Apprendre » (fr) et « التعلم » (ar). `/eleve/coran` reste dans la même branche et continue de fonctionner. |
| `SelecteurSection` | Les trois onglets. Aucun `TabBar`. |
| `RangeeFiltres`, `FilterPill`, `FiltresActifs` | Le filtre par type. |
| `CouvertureSupport`, `CouvertureRessource` | La vignette d'un document (livre de l'académie ; le Coran garde sa couverture standard). |
| `AppCard`, `SectionHeader`, `EmptyState`, `EtatSysteme`, `EtatSansDonnees`, `Skeleton`, `StatusPill`, `GroupeReglages`, `LocalFeedback`, `AppBottomSheet`, `ActionPrincipale`, `BoutonIcone`, `Pressable` | Les états et les cartes. |
| `ApparitionDouce`, `ElementEchelonne`, `BasculeEtat` (`lib/core/mouvement`) | Les animations : opacité, position, échelle ; mouvement réduit respecté par les briques. |
| `portCatalogueProvider` (`PortCatalogue.tous`) | Lu **sans être modifié** par l'adaptateur de la planche. |
| `suiviPedagogiqueProvider`, `SuiviPedagogique`, `libelleRythme`, textes `suiviPedagogique.*` (lot 1) | L'onglet Programme lit la **même lecture** que la carte de suivi de « Ma classe » et réutilise ses libellés ; rien n'est recalculé. |
| `ouvreurOngletProvider`, `ouvreurLienProvider` | Ouvrir un lien externe : nouvel onglet du navigateur ; sans navigateur, le lien est copié et la phrase le dit. |
| `stockagePreferencesProvider` | Le choix grille ou liste, gardé sur l'appareil. |
| `SurfaceBibliotheque`, `BibliothequePage` (`/tc/bibliotheque`) | **Non modifiées.** Elles restent la Bibliothèque de l'enseignant et du tuteur ; la ligne « Bibliothèque » de « Ma classe » de l'élève mène désormais à l'espace Apprendre (voir écarts). |

## Ce que le lot crée

- `lib/core/apprendre/` : `document_planche.dart` (le petit modèle d'affichage : titre, description facultative, vignette facultative, type, rayon, action d'ouverture), `documents_apprendre.dart` (l'adaptateur sur le catalogue existant, le Coran en premier), `planche_documents.dart` (la planche commune, écrite une fois : grille ou liste, deux rayons, filtre par type, petites cartes de lien, confirmation), `vignette_document.dart`, `affichage_planche.dart` (le choix grille ou liste et le filtre, gardés), `dates_ecole.dart` (le port des dates de l'école).
- `lib/features/apprendre/` : `espace_apprendre_page.dart` (les trois onglets), `onglet_bibliotheque.dart`, `onglet_programme.dart`, `onglet_livret.dart`, `routes_apprendre.dart`.
- La route `/eleve/apprendre` (`Routes.eleveApprendre`), `?onglet=programme|livret` pour ouvrir un autre onglet.
- Les textes `apprendre.*` en français et en arabe (déclarés dans `tool/libelles_sources.json`) ; onze icônes Phosphor ajoutées à `AppIcons` (grille, liste, audio, vidéo, lien externe, document, livret, calendrier, objectifs, chemin, apprendre : mêmes points de code dans les deux polices embarquées, vérifiés).

## Choix et justifications

1. **Le rayon du haut s'appelle « Documents des cours »** (وثائق الدروس), pas « Documents de l'académie » : c'est le nom arbitré (`ARBITRAGES.md` n° 7, 8 et 67, `mots-rewayah`). « Documents de l'académie » était la formule du directeur dans sa demande ; le nom arbitré la reprend en mots d'école. À corriger d'un mot si le directeur préfère sa formule.
2. **Aujourd'hui tout document publié est du premier rayon.** Le catalogue ne distingue pas encore les rayons (lot 3). Rien n'est vendu : tout ce que la direction publie est fourni par l'académie. Le second rayon, « Pour aller plus loin », est vide et le dit : « D'autres documents arriveront ici », sans prix ni mot d'argent (test qui lit tous les textes de l'écran).
3. **Tous les types du catalogue sont des « documents »** (Coran, texte, PDF, image, leçon). Audio, vidéo et lien externe existent dans le modèle et la planche (testés avec des documents de test) et apparaîtront quand le lot 3 les ajoutera. Une ressource sans version publiée n'est pas listée (il n'y a rien à ouvrir).
4. **Le Coran est une carte posée en tête** par l'adaptateur (pas encore une fiche du catalogue : 0 document en production). Elle ouvre le lecteur existant (`/eleve/coran`) : un raccourci, pas une copie. Quand le lot 3 inscrira le Coran au catalogue, sa fiche remplacera cette carte ; la ressource de type Coran du catalogue est déjà écartée pour qu'il n'y ait jamais deux Corans. Sa description est « Édition de Médine » (c'est l'édition du lecteur), rien d'inventé.
5. **Un filtre par type n'est offert que s'il y a deux types au moins**, et une puce n'existe que pour un type qui a un document. Un seul type : pas de puce qui ne filtrerait rien. Un filtre qui ne laisse rien le dit (« Aucun document de ce type pour le moment ») et propose « Tout effacer ». Un rayon vidé par le filtre n'est pas montré (pas de rayon vide trompeur).
6. **Liens externes** : petites cartes avec leur description et l'hôte de l'adresse ; en grille elles forment leur propre bloc (1, 2, 3 colonnes), en liste ce sont des lignes. Toucher une carte ouvre une feuille : « Ce lien est publié par l'académie. Il s'ouvre hors de l'application. » (tutoiement pour l'enfant), puis « Ouvrir le lien » ou « Annuler ». Aucun type de document ne permet à un tiers de poser un lien : tous sont publiés par l'académie, donc la règle des moins de 10 ans tient pour tous, et l'écran le dit d'un mot. Dans un navigateur : nouvel onglet ; ailleurs, **`url_launcher` n'est pas une dépendance et `pubspec.yaml` est interdit à ce lot : le lien est copié** (« Lien copié : collez-le dans votre navigateur »).
7. **La grille n'est pas un `GridView`** : des rangées de cellules égales (2 colonnes sous 600, 3 de 600 à 1199, 4 à partir de 1200, bornées par la largeur disponible), chaque cellule à la hauteur de son contenu, donc rien ne déborde à 200 % de texte et la page reste le seul défilement.
8. **Les lectures des trois onglets partent à l'ouverture de l'espace** : changer d'onglet est local et ne fait rien attendre.
9. **Programme** : niveau et étape en cours mis en avant (carte lavande, segments du chemin), puis une carte par étape (statut en mots : « Étape précédente », « Étape en cours », « À venir » ; objectifs ; durée si l'élève voit ses dates), puis « Dates de l'école ». Libellés d'étape du serveur ; jamais « Étape validée ». Dates, durées, rythme et section « Dates de l'école » seulement si `eleve_voit_dates` (le mode d'interface ne décide rien). Un enfant de 6 à 9 ans n'en voit aucune (y compris la date d'entrée, que la carte de suivi du lot 1 affiche encore : voir écarts).
10. **Pas de composant d'onglets, de bouton ni de carte recréé.** Composants créés : la planche et sa vignette. Aucun composant existant ne couvre « des documents en grille ou en liste, deux rayons, filtre par type, lien externe » : `SurfaceBibliotheque` est une liste de cartes `CarteRessource` à une disposition, liée aux cinq types du catalogue (`TypeRessource`), à une recherche et à l'état hors ligne des téléchargements, et vit dans `features/` ; la planche doit servir plus tard à la salle depuis `lib/core`. `VignetteRessource` ne connaît ni audio, ni vidéo, ni lien. Quand le lot 3 étendra les types, la vignette rejoindra la couverture de livre.

## Ce qui attend les autres lots

| Lot | Ce qui se branche |
|---|---|
| 2 CALENDRIER-ET-PAUSES | Remplacer `portDatesEcoleProvider` (`lib/core/apprendre/dates_ecole.dart`) : la section « Dates de l'école » se remplit seule ; l'état vide disparaît. Aujourd'hui l'implémentation de production rend « rien de publié ». |
| 3 BIBLIOTHEQUE-UNE | Remplir le modèle d'affichage depuis les nouveaux champs : rayon, type audio / vidéo / lien externe, vignette, description. Un seul fichier à changer : `documents_apprendre.dart` (`documentsDepuisCatalogue`). Le Coran, inscrit au catalogue, remplace la carte posée en tête. |
| 4 LECTEUR | Ouvrir un document passe par les écrans existants (fiche d'un document, lecteur du Coran). Quand le lecteur unique existera, les routes d'ouverture de `OuvrirDansLApplication` pointent sur lui ; la planche ne change pas. |
| 6 SUIVI-UNIQUE | La fiche complète de suivi vient dans l'onglet Programme ; la carte de suivi de « Ma classe » devient un raccourci. D'ici là, les deux lisent la même lecture et ne se contredisent pas, mais le chemin des étapes s'affiche aux deux endroits. |
| 8 EVALUATIONS-ET-LIVRET | Remplir « Mon livret » (résultats, bilans, attestations). Aujourd'hui : l'état vide honnête, sans faux résultat. |

## Écarts et ce qui n'est pas fait

1. **Raccourci « Apprendre » de l'accueil : non remplacé.** L'accueil de l'élève porte un bloc « Le Coran, à lire quand tu veux » (et l'accueil guidé un bouton Coran) qui mènent au lecteur. Le texte de ce bloc est prononcé par un enregistrement lié à sa clé (`eleve.accueil.coran`, `CleAudio`) : changer le mot sans réenregistrer ferait dire à la voix autre chose que l'écran. Le bloc reste donc un raccourci direct vers le Coran (un document de la Bibliothèque, pas un second objet) ; le remplacer par « Apprendre » demande un enregistrement.
2. **Ma classe → « Bibliothèque »** mène maintenant à l'espace Apprendre (un raccourci, pas une seconde Bibliothèque) ; l'ancienne adresse `/tc/bibliotheque` n'est pas supprimée (l'enseignant et le tuteur l'utilisent ; `redirection.dart` et la page sont hors de ce lot).
3. **La carte de suivi du lot 1 n'est pas modifiée** (fichier du lot 1) : elle affiche toujours la date d'entrée de l'enfant de 6 à 9 ans que l'onglet Programme masque. À aligner au lot 6.
4. **Le tuteur n'a pas encore l'espace depuis le profil de l'enfant** (le plan le prévoit ; la demande du directeur ne parle que des profils élève).
5. **Pas de recherche** dans la planche (non demandée).
6. **Aucun lien externe ne peut apparaître avant le lot 3** : le catalogue ne porte pas ce type ; la planche est prête et testée avec des documents de test.
7. **Vignettes déposées** : le catalogue n'en rend aucune ; la vignette est donc toujours celle par défaut du type.

## Preuve (ce qui est vérifié, et par quoi)

À remplir à la fin du lot : résultats exacts des six vérifications, captures dans `docs/current/captures/E2E/espace-apprendre/`.
