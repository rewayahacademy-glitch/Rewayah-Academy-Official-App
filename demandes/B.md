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
