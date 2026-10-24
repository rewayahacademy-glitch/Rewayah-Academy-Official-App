import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'lecteur_qr.dart';

/// L'adaptateur `mobile_scanner` du port [LecteurQr] (Android, iOS, macOS,
/// web).
///
/// - Demarrage manuel (`autoStart: false`) et cycle de vie tenu par l'ecran
///   (`useAppLifecycleState: false`) : c'est l'ecran qui arrete la camera en
///   arriere-plan et la rend a la sortie.
/// - QR code seulement : un code-barres de produit n'est meme pas lu.
/// - Aucun message du paquet n'est montre (ils sont en anglais) : les erreurs
///   deviennent un [EtatCamera], que l'ecran dit en francais.
class LecteurQrMobileScanner implements LecteurQr {
  /// Cree l'adaptateur (camera non demarree).
  LecteurQrMobileScanner()
    : _controleur = MobileScannerController(
        autoStart: false,
        formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
      );

  final MobileScannerController _controleur;
  final StreamController<String> _lectures =
      StreamController<String>.broadcast();
  StreamSubscription<BarcodeCapture>? _abonnement;
  bool _libere = false;

  /// Les refus d'autorisation deja recus pendant cette visite de l'ecran.
  ///
  /// Sans `permission_handler` (non retenu, C05 section 6), le paquet ne dit
  /// pas si un refus est definitif. Or une nouvelle demande apres un refus ne
  /// rouvre plus la fenetre du systeme sur iOS, macOS et le web (commentaire
  /// de `MobileScannerController.start`). Un deuxieme refus dans la meme
  /// visite est donc traite comme durable : l'ecran renvoie vers les reglages
  /// au lieu de proposer un bouton qui ne peut plus aboutir.
  int _refus = 0;

  @override
  Stream<String> get lectures => _lectures.stream;

  @override
  Widget apercu() => MobileScanner(
    controller: _controleur,
    useAppLifecycleState: false,
    errorBuilder: (BuildContext _, MobileScannerException _) =>
        const SizedBox.expand(),
    placeholderBuilder: (BuildContext _) => const SizedBox.expand(),
  );

  @override
  Future<EtatCamera> demarrer() async {
    if (_libere) {
      return EtatCamera.erreur;
    }
    _abonnement ??= _controleur.barcodes.listen(_surCapture);
    try {
      await _controleur.start();
      return EtatCamera.pret;
    } on MobileScannerException catch (erreur) {
      return _etatDepuis(erreur);
    } on Object {
      return EtatCamera.erreur;
    }
  }

  void _surCapture(BarcodeCapture capture) {
    for (final Barcode code in capture.barcodes) {
      final String? brut = code.rawValue;
      if (brut != null && !_lectures.isClosed) {
        _lectures.add(brut);
      }
    }
  }

  EtatCamera _etatDepuis(MobileScannerException erreur) {
    final String detail =
        '${erreur.errorDetails?.code ?? ''} ${erreur.errorDetails?.message ?? ''}';
    switch (erreur.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        _refus++;
        return _refus > 1 ? EtatCamera.refuseeDurablement : EtatCamera.refusee;
      case MobileScannerErrorCode.unsupported:
        // Android et iOS : `MOBILE_SCANNER_NO_CAMERA_ERROR` ; web :
        // `NotFoundError` (aucun peripherique video).
        return detail.contains('NO_CAMERA') || detail.contains('NotFoundError')
            ? EtatCamera.absente
            : EtatCamera.nonSupportee;
      case MobileScannerErrorCode.genericError:
        // Web : `NotReadableError` quand une autre application tient la
        // camera. Les plateformes natives ne distinguent pas ce cas.
        return detail.contains('NotReadableError') ||
                detail.contains('TrackStartError')
            ? EtatCamera.occupee
            : EtatCamera.erreur;
      case MobileScannerErrorCode.controllerAlreadyInitialized:
        return EtatCamera.pret;
      case MobileScannerErrorCode.controllerDisposed:
      case MobileScannerErrorCode.controllerUninitialized:
      case MobileScannerErrorCode.controllerInitializing:
      case MobileScannerErrorCode.controllerNotAttached:
        return EtatCamera.erreur;
    }
  }

  @override
  Future<void> arreter() async {
    if (_libere) {
      return;
    }
    try {
      await _controleur.stop();
    } on Object {
      // Une camera deja arretee n'est pas une erreur a montrer.
    }
  }

  @override
  Future<void> liberer() async {
    if (_libere) {
      return;
    }
    _libere = true;
    await _abonnement?.cancel();
    await _lectures.close();
    try {
      await _controleur.dispose();
    } on Object {
      // Deja rendue.
    }
  }
}
