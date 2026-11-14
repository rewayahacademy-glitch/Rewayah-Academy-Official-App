// La position de l'appareil, pour que l'enseignant partage son lieu de priere en
// un geste (PRIERE-2). Sur le web : l'API de geolocalisation du navigateur et le
// fuseau IANA de l'appareil, par `dart:js_interop`, sans paquet ni secret.
// Ailleurs, la lecture n'est pas disponible : l'ecran le dit, la direction pose
// le lieu.
export 'position_appareil_memoire.dart'
    if (dart.library.js_interop) 'position_appareil_web.dart';
