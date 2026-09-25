# Demandes du lot C (reprises par le coordinateur, poste B)

Les demandes C-1 à C-16 d'origine sont restées sur le poste A (`D:\RA _APP\pilotage-tuteur-v1\`), éteint. Suite donnée : `05_recette/c/REVUE.md` §5.

## C-14 (ouverte, 25/09) : séances, fuseau et parcours d'une classe ouverte

Le contrat `ClasseOuverte` (K6, `lib/core/capacites/port_catalogue_classes.dart`, gelé) ne porte ni les séances hebdomadaires, ni le fuseau de la classe, ni le parcours (cours, niveau), ni le motif de refus. Le mandat §C.3 les exige. Ressource manquante : décision du directeur pour étendre K6, et source serveur DB-CRS-07. Rien n'est inventé côté client : la carte garde sa phrase honnête.

## C-INT-1 (25/09, INT-C, session B-2026-09-25-coord) : `portClassesFoyerProvider` par defaut casse 3 tests du lot B

- **Fichier** : `lib/core/capacites/port_classes_foyer.dart` (COORD).
- **Constat** : la revue du lot C (M2) a change le provider par defaut de `ClassesFoyerIndisponible()` vers `ClassesFoyerSupabase(Supabase.instance.client)` (branchement reel, demandes C-1/C-12). C'est le bon sens pour la production, mais `test/features/foyer/foyer_page_test.dart` et `fiche_eleve_test.dart` (fichiers du lot B, hors perimetre COORD) ont des scenarios "classes sans service" qui **comptaient sur le defaut** pour simuler l'indisponibilite (pas de surcharge explicite du provider). Avec le vrai adaptateur par defaut, ces widget tests (sans `Supabase.instance` initialise) echouent autrement et le texte honnete attendu ne s'affiche plus.
- **Preuve** : `flutter test` complet (`04_phase0/integration_lotC_tests.log`) et isole (`04_phase0/isole_foyer_test.log`) : memes 3 echecs, reproductibles, pas un flake d'ordre.
- **Deux reparations possibles, a trancher avant de coder** :
  1. Surcharger explicitement `portClassesFoyerProvider` avec `ClassesFoyerIndisponible()` dans les tests foyer concernes (petit changement, mais fichiers hors perimetre COORD : `test/features/foyer/*`).
  2. Revoir l'endroit ou le vrai adaptateur est injecte (par ex. seulement dans `main.dart` / `ProviderScope` de l'app reelle, en laissant le provider partage sur un comportement neutre par defaut) pour que les widget tests ne dependent jamais d'un service reseau implicite.
- **Bloquant pour** : le push de `origin/ui/tuteur-v1` (INT-C). Pas corrige faute de decision et de temps (limite 35 min).
