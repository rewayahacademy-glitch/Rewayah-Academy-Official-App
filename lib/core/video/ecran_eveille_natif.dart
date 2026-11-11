import 'ecran_eveille.dart';

/// Hors navigateur : aucun verrou d'ecran (ECRAN-EVEILLE, 11/11/2026).
///
/// **Sans effet, et c'est assume.** Garder l'ecran allume dans une
/// application Android ou iOS demande un greffon natif (une nouvelle
/// dependance), et `pubspec.yaml` est hors de portee de ce lot. La production
/// est l'application web (navigateur ou PWA) : c'est elle qui est servie par
/// `ecran_eveille_web.dart`.
VerrouEcranNavigateur? verrouEcranDeLaPlateforme() => null;
