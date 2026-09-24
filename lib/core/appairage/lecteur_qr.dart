import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lecteur_qr_mobile_scanner.dart';

/// Ce que la camera a repondu a la demande de demarrage (contrat K6).
enum EtatCamera {
  /// La camera tourne, les lectures arrivent.
  pret,

  /// L'autorisation vient d'etre refusee : on peut la redemander.
  refusee,

  /// L'autorisation reste refusee : seul le reglage de l'appareil ou du
  /// navigateur peut la rendre.
  refuseeDurablement,

  /// Une autre application tient la camera.
  occupee,

  /// L'appareil n'a pas de camera.
  absente,

  /// Le navigateur ou la plateforme ne sait pas lire un QR code.
  nonSupportee,

  /// La camera n'a pas demarre, sans cause connue.
  erreur,
}

/// Le port `LecteurQr` (contrat K6, lot D) : la camera qui lit le QR code
/// affiche par le tuteur.
///
/// Un lecteur par visite de l'ecran : il est cree a l'ouverture, arrete en
/// arriere-plan, et [liberer] rend la camera a la sortie. Les lectures sont
/// le texte BRUT du QR : c'est a l'ecran de le valider
/// (`FormatCodeAppairage.normaliser`), jamais de l'ouvrir.
abstract interface class LecteurQr {
  /// Demande la camera (et donc l'autorisation, a la premiere fois).
  Future<EtatCamera> demarrer();

  /// Arrete la camera ; les lectures cessent.
  Future<void> arreter();

  /// Les contenus lus, un evenement par QR detecte.
  Stream<String> get lectures;

  /// La vue de la camera. Elle doit etre dans l'arbre AVANT [demarrer].
  Widget apercu();

  /// Rend la camera pour de bon.
  Future<void> liberer();
}

/// La plateforme sait-elle lire un QR code ? `mobile_scanner` couvre
/// Android, iOS, macOS et le web ; ni Windows ni Linux (C05 section 6).
bool lecteurQrPossibleSur({
  required bool web,
  required TargetPlatform plateforme,
}) {
  if (web) {
    return true;
  }
  switch (plateforme) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return true;
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      return false;
  }
}

/// Le lecteur des plateformes sans camera lisible (Windows, Linux) : il ne
/// demarre jamais et le dit.
class LecteurQrIndisponible implements LecteurQr {
  /// Cree le lecteur indisponible.
  const LecteurQrIndisponible();

  @override
  Future<EtatCamera> demarrer() async => EtatCamera.nonSupportee;

  @override
  Future<void> arreter() async {}

  @override
  Stream<String> get lectures => const Stream<String>.empty();

  @override
  Widget apercu() => const SizedBox.expand();

  @override
  Future<void> liberer() async {}
}

/// La fabrique d'un lecteur, un par visite de l'ecran du scanner.
typedef FabriqueLecteurQr = LecteurQr Function();

/// Vrai quand cette plateforme sait lire un QR code. Faux : aucun bouton
/// « Scanner » n'est rendu (un bouton qui ne peut pas aboutir n'est pas
/// rendu, `lib/CLAUDE.md`).
final Provider<bool> lecteurQrDisponibleProvider = Provider<bool>(
  (Ref ref) =>
      lecteurQrPossibleSur(web: kIsWeb, plateforme: defaultTargetPlatform),
);

/// La fabrique de production : l'adaptateur `mobile_scanner` la ou il
/// existe, le lecteur indisponible ailleurs. Jamais une fixture.
final Provider<FabriqueLecteurQr> fabriqueLecteurQrProvider =
    Provider<FabriqueLecteurQr>(
      (Ref ref) => ref.watch(lecteurQrDisponibleProvider)
          ? LecteurQrMobileScanner.new
          : LecteurQrIndisponible.new,
    );
