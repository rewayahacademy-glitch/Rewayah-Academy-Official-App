// Le rechargement de l'adresse courante, jeton d'observation compris.
//
// L'ouverture d'une session d'agent se fait au demarrage (`main()`), avant le
// premier ecran : la relancer, c'est recharger la page. Hors web, il n'y a pas
// de tunnel d'agent (ADR-025) et l'implementation ne fait rien.
export 'recharger_adresse_memoire.dart'
    if (dart.library.js_interop) 'recharger_adresse_web.dart';
