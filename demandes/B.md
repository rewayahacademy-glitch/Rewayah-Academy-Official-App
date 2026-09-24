# Demandes du lot B (Foyer et fiche élève) au coordinateur

## B-1 (24/09, LB-1) : avatar en tête de ligne dans `GroupeReglages`

- **Fichier** : `lib/core/widgets/groupe_reglages.dart` (COORD, composant partagé de la carte groupée).
- **Besoin** : le Foyer (`05_LOTS_PHASE1.md` section B-1, manifeste §2 ligne `/tuteur/foyer`) veut, pour chaque membre, « avatar ou initiale, prénom, classe ou inscription en cours, statut d'accès, chevron » dans UN groupe à filets. `LigneRubrique` n'accepte qu'une `AppIcon` en tête (`groupe_reglages.dart:16-24`, rendue `:143-146`) : impossible d'y poser `AvatarTile` sans recréer le motif hors du composant partagé (interdit, `03` §1 ter-3).
- **Signature voulue** : un champ facultatif `final Widget? meneur;` dans `LigneRubrique` (constructeur `this.meneur`), rendu à la place de l'icône quand il est présent (même retrait de filet, largeur libre, `ExcludeSemantics` non requis : l'avatar n'a pas de sémantique propre). `icone` resterait requis ou deviendrait facultatif avec l'assertion `icone != null || meneur != null`.
- **Contournement en place** (LB-1, branche `ui/tuteur-v1-b`) : chaque membre est une `LigneRubrique` avec l'icône `AppIcons.profil` ; la photo ou l'initiale sera posée par le lot B dès que le champ existe (un seul appel à changer : `lib/features/foyer/ligne_membre.dart`).

## B-2 (24/09, LB-1) : `.order('paired_at')` sans sens explicite

- **Fichier** : `lib/core/appairage/service_appairage.dart:212` (COORD, source partagée B et D).
- **Constat** : `mes_appareils_v` est lu avec `.order('paired_at')` sans `ascending:` ; PostgREST trie alors en décroissant (`03` §1 ter bis-2). LB-1 ne consomme pas cette lecture (le Foyer mène à `/tuteur/foyer/appareils`, écran du lot D) ; signalé pour le lot D et le coordinateur.
- **Signature voulue** : `.order('paired_at', ascending: true)` (ou `false` si l'ordre voulu est « plus récent d'abord »), avec un test d'ordre.

## B-3 (24/09, LB-2) : gabarit d'etape partage (ajout de profil, admission)

- **Fichiers** : `lib/core/widgets/page_shell.dart`, `lib/core/widgets/choice_card_group.dart`, `lib/core/widgets/page_parcours.dart` (COORD).
- **Constat 1** : sur `/tuteur/foyer/ajouter`, `PageShell` sans titre rend quand meme une ligne avec les actions de la coquille (cloche, bascule) au-dessus de la rangee d'etape (`page_shell.dart`, branche `titre == null && enteteRiche`) : la planche V6 (#12, #14) met la rangee d'etape (disque retour, progression, « n sur N ») en premiere ligne, parcours plein ecran. Ecart visible sur `05_recette/B/captures/ajout_pour_qui_contre_E1.png` et `ajout_identite_contre_E3.png`.
- **Signature voulue** : `PageShell({... bool actionsCoquille = true})` (faux = pas de cloche ni bascule pour une tache focalisee) ; ou un gabarit `PageEtape({required int numero, required int total, required VoidCallback onRetour, ...})` qui pose la rangee d'etape V6 en tete. Le lot A (inscription par etapes, sous-paquet A-2) a le meme besoin : un seul composant.
- **Constat 2** : `ChoiceCardGroup` n'a ni description sous le libelle, ni option desactivee expliquee, ni radio (V5 §6 « style liste avec description », V6 §6 E1) ; K3 exige des choix visibles mais indisponibles.
- **Signature voulue** : `OptionChoix({..., String? description, bool disponible = true, String? raisonIndisponible})` et un radio dessine (anneau >= 3:1).
- **Contournement en place** (LB-2, `ui/tuteur-v1-b` @ 2ccb990) : rangee d'etape et carte de choix locales et privees dans `lib/features/foyer/formulaire_profil_eleve.dart` (`_RangeeEtape`, `_CarteChoix`, `_Radio`) ; a remplacer par le composant partage des qu'il existe.

## B-4 (24/09, LB-3) : rediriger `/tuteur/reglages` vers le Foyer (C6)

- **Fichier** : `lib/core/router/app_router.dart` (COORD), route `Routes.tuteurReglages` qui rend encore `ReglagesEnfantPage`.
- **Constat** : depuis LB-3 (`ui/tuteur-v1-b` @ d7b006f), la fiche eleve porte la photo (`.../informations`), la camera (`.../camera`) et l'interface (`.../interface`). `/tuteur/reglages` offre les memes reglages ailleurs : une fonction a deux endroits (`03` §1 ter-1), et libelles « Grand affichage / Affichage courant » non conformes.
- **Besoin** : redirection `/tuteur/reglages` -> `/tuteur/foyer` (mapping C6), comme deja fait pour `/compte/profils/:id` -> fiche. Le lot B n'importe ni ne modifie `reglages_enfant_page.dart` d'ici la.