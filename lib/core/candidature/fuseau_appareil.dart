// Le fuseau IANA de l'appareil, quand la plateforme le dit.
//
// Sur le web, le navigateur le donne exactement (`Intl.DateTimeFormat`) ; ailleurs,
// la bibliotheque standard de Dart ne donne qu'un decalage, qui ne designe pas
// un fuseau (heure d'ete comprise), et l'implementation rend `null`. Dans les
// deux cas, le fuseau n'est jamais envoye sans que la personne le confirme
// (CAND-01 : « le fuseau ne se devine pas »). Meme motif que
// `recharger_adresse.dart`.
export 'fuseau_appareil_memoire.dart'
    if (dart.library.js_interop) 'fuseau_appareil_web.dart';
