// Ouvrir une adresse dans un nouvel onglet (PIECE-DANS-DOSSIER, directeur,
// 16/11/2026 : une piece deposee en PDF s'ouvre d'un toucher, comme avant la
// refonte). Sur le web, un nouvel onglet ; ailleurs, l'adresse est copiee et le
// retour le dit (`false`). L'adresse d'une piece est signee et courte : elle ne
// se journalise jamais.
export 'ouvrir_onglet_memoire.dart'
    if (dart.library.js_interop) 'ouvrir_onglet_web.dart';
