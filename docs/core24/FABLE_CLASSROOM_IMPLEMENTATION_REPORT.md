# FABLE_CLASSROOM_IMPLEMENTATION_REPORT — lot 2 « Classroom Experience »

Agent Fable · 22/09/2026 · branche **`core24/fable-frontend`** (départ `ae59cd7`, arbre propre). `main` (`ae61eb6`) n'a pas été touché.
Commit de ce lot : celui qui porte ce fichier (`git log -1 --format=%h -- docs/core24/FABLE_CLASSROOM_IMPLEMENTATION_REPORT.md`) ; le SHA est aussi donné dans le rapport final à l'opérateur.

Documents liés : `FABLE_CLASSROOM_AUDIT.md` (25 constats), `FABLE_CLASSROOM_UX_DECISIONS.md` (D-L2-01..10), `FABLE_CLASSROOM_TEST_MATRIX.md`, `CONTRACT_REQUEST_FABLE_CLASSROOM.md` (7 demandes Astra).

## 1. Ce qui a changé, en une phrase par décision

1. **Une seule salle.** `/salle` rend désormais `ClasseLivePage` par `EntreeSalle` (billet → contexte). `SallePage` et `PanneauEnseignantSalle` sont supprimés. Élève, tuteur, contrôleur, admin et enseignant voient la même coque ; le jeton signé (`VueSalle`) décide des capacités, rien d'autre.
2. **Le protocole `SharedContentState` circule vraiment.** `AdaptateurTransportLiveKit` se déclare `complet` et pose ses paquets sur la primitive existante du socle (`publierDonnees`/`donneesRecues`), sujet nu pour le fiable, suffixe `-l` pour l'éphémère. Aucun second provider, aucun second protocole : `ContenuPresente` reste en place mais n'est plus alimenté par la salle.
3. **Le Coran est la surface.** `SupportCoranClasse` applique l'état partagé au lecteur (page résolue par `PortNavigationCoran`, mode, plage de focus), l'élève suit avec une bande « revenir au professeur » quand il a décroché, le pilote publie page/mode/focus par le même flux avec un debounce.
4. **Sélection d'un verset par tap**, seulement sous `PorteeSelectionVerset` (donc seulement dans la classe, pour qui peut présenter) ; le lecteur hors classe ne change pas.
5. **Dock hébergé, Bibliothèque en place.** `HoteDockClasse` ne déclare que ce qu'il rend (pas d'annotation, de nudge ni de pilotage du support). La Bibliothèque s'ouvre en panneau latéral (bureau, Échap ferme) ou en feuille (mobile) avec la carte « Présenter le Coran » puis le `ClassLibraryPicker` existant.
6. **Commandes rondes avec états de périphérique** (fermé, ouvert, absent, permission refusée, en cours, erreur) ; la pastille réseau ne parle que si le lien est médiocre ou perdu.
7. **Composition par gabarit et par hauteur.** Un écran de moins de 500 pt de haut se compose comme un téléphone (roster en feuille, vidéo en vignette latérale) ; portrait : vignette sous le support.
8. **Présence et rappels reportés dans la coque** : l'élève lit sa présence, chaque rôle d'observation lit son rappel (contrôleur, admin incognito, tuteur).
9. **Sortie décidée par la route** : l'enseignant qui a tenu le cours sort vers le cahier de séance, les autres vers leur racine ; l'Espace Groupe garde sa propre sortie.
10. **Republication à l'arrivée d'un participant** (1 s après), pour l'arrivant tardif et pour l'élève qui recharge.

## 2. Fichiers

Nouveaux (lib) : `features/tc_classe_live/{entree_salle,etat_partage_classe,support_coran_classe,commandes_classe,hote_dock_classe,bibliotheque_en_classe}.dart`, `features/tc_mushaf/selection_verset.dart`.
Modifiés (lib) : `core/router/{app_router,billet_salle}.dart`, `core/tc_classe/{port_session_persistante,session_live_vm}.dart`, `core/tc_realtime/{adaptateur_transport_livekit,providers_tc_realtime}.dart`, `features/tc_classe_live/{classe_live_page,vue_classe_live,entete_classe,slots_tc_classe}.dart`, `features/tc_mushaf/{vue_page_mushaf,vue_verset_agrandi}.dart`, `features/tc_catalogue/class_library_picker.dart`, `features/tc_mes_groupes/routes_tc_a.dart`, points d'entrée `features/{journee,controleur,accueil_eleve,accueil_famille}/*_page.dart`, `assets/i18n/fr.i18n.json` + `core/i18n/strings*.g.dart`.
Supprimés : `features/salle/salle_page.dart`, `features/salle_enseignant/{panneau_enseignant,presentation_coran,vue_presentation}.dart`, `test/features/{salle,salle_enseignant}_test.dart`.
Tests nouveaux : `test/teaching_core/e/{lot2_classe,support_coran_classe}_test.dart`, `test/teaching_core/c/selection_verset_test.dart` ; réécrits : `test/teaching_core/f/adaptateur_transport_livekit_test.dart`, `test/teaching_core/f/faux/faux_moteur_salle.dart` ; ajusté : `test/teaching_core/e/classe_live_page_test.dart`.

## 3. Fonctions réellement testées

Voir la matrice §2 : transport (12), support Coran deux appareils (7), sélection (3), lot 2 coque (14 déclarations), page classe (20), routeur et points d'entrée. Chaque test est exécuté sur ce poste ; les résultats de la suite complète sont dans la matrice.

## 4. Plateformes

Testé : tests widget sur VM Flutter (gabarits téléphone 390×844, paysage 844×390, bureau), `flutter build web --release`.
Non testé : Chrome réel sur une séance vivante, Android (aucun appareil), Windows desktop run.
Bloqué : iOS et iPad (aucun macOS). **iOS n'est pas annoncé validé.**

## 5. Limites connues

- Persistance serveur de l'état partagé impossible aujourd'hui (`library_resource` vide, `resource_id` uuid) : mémoire seulement, compensée par la republication. Demande 1 du contrat.
- Masquage et pointeur du protocole ne sont pas rendus par la surface Coran (demande 6) ; annotation et nudge ne sont pas déclarés par le dock (rien à rendre côté serveur).
- Le catalogue et les groupes du Teaching Core restent des doubles locaux (demandes 3 et 4) ; la Bibliothèque montre donc un catalogue vide en prod hormis la carte Coran.
- Aucun paquet n'a traversé LiveKit pendant ce lot ; la primitive du socle est appelée telle quelle, prouvée contre un faux moteur.
- `ContenuPresente` (socle vidéo) n'est plus alimenté par la salle ; il n'a pas été retiré du socle (hors frontière).

## 6. Blockers backend (pour Astra)

Les 7 demandes sont dans `CONTRACT_REQUEST_FABLE_CLASSROOM.md` : ligne `library_resource` pour le Coran avec code stable ; RPC `effacer_etat_partage` ; catalogue et groupes servis par Supabase ; séance → groupe dans `mes_seances_v` ; rendu masquage/pointeur ; route d'observation `/tc/observation`. Rien de tout cela n'a été implémenté côté frontend au-delà du contrat.

## 7. Auto-revue (§23)

- UX pédagogique : l'enseignant entre, présente le Coran en deux gestes, feuillette, focalise, sort ; aucune capacité ne demande de configurer quoi que ce soit.
- Quran : le Coran occupe la surface, la vidéo devient vignette dès qu'un support est présenté.
- Cross-platform : trois compositions (mobile portrait, écran court, tablette/bureau) ; pas de pattern mobile sur bureau (panneau latéral, Échap).
- Accessibilité : étiquettes sémantiques sur les commandes et le verset sélectionné ; clavier partiel (Échap) ; lecteur d'écran et contraste non mesurés.
- Sobriété : `PanneauEnseignantSalle` (55 Ko de coque) supprimé ; le dock ne déclare que ce qu'il rend ; la pastille réseau se tait quand tout va bien.
