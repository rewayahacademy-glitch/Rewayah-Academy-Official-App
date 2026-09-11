import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/appairage/service_appairage.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/page_shell.dart';

/// L'ajout d'un appareil : un QR grand format, le code en dessous, et le delai
/// de validite qui s'ecoule.
///
/// Le code n'existe qu'ici : la base n'en garde que l'empreinte, aucune requete
/// ne peut le relire, et en demander un nouveau perime le precedent. Quitter
/// l'ecran le perd, ce qui est le comportement attendu d'un code a duree de vie
/// courte.
class AppairagePage extends ConsumerStatefulWidget {
  /// Cree l'ecran d'appairage pour un eleve.
  const AppairagePage({required this.eleveId, super.key});

  /// L'eleve dont on appaire un appareil.
  final String eleveId;

  @override
  ConsumerState<AppairagePage> createState() => _AppairagePageState();
}

class _AppairagePageState extends ConsumerState<AppairagePage> {
  CodeAppairage? _code;
  Timer? _horloge;
  DateTime _maintenant = DateTime.now();
  bool _enCours = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    unawaited(_demander());
    _horloge = Timer.periodic(
      const Duration(seconds: 1),
      (Timer _) => setState(() => _maintenant = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _horloge?.cancel();
    super.dispose();
  }

  Future<void> _demander() async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final CodeAppairage code = await ref
          .read(serviceAppairageProvider)
          .creerCode(widget.eleveId);
      if (mounted) {
        setState(() => _code = code);
      }
    } on Object {
      if (mounted) {
        setState(() => _erreur = t.appareils.erreur);
      }
    } finally {
      if (mounted) {
        setState(() => _enCours = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final CodeAppairage? code = _code;
    final Duration restant = code?.restantA(_maintenant) ?? Duration.zero;
    final bool expire = code != null && restant == Duration.zero;

    return PageShell(
      titre: t.appareils.codeTitre,
      // Reprise au lot R4 : le bouton de retour, jusque-la colle en bas a la
      // main dans un `Padding` hors `Scaffold`, passe par la prise `actions:`
      // de `PageShell` -- meme correction que les feuilles d'accueil du lot
      // R0.
      actions: ActionPrincipale(
        libelle: t.commun.retour,
        onPress: () => GoRouter.of(context).go(Routes.tuteurFoyer),
        niveau: NiveauAction.secondaire,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(t.appareils.codeInstruction, style: textes.bodyMedium),
          Ecart.vXxl,
          if (code != null && !expire) ...<Widget>[
            _Qr(code: code.code, paire: palette.surfaceCanvas),
            Ecart.vXl,
            _CodeEnClair(code: code.code),
            Ecart.vLg,
            Semantics(
              liveRegion: true,
              child: Text(
                t.appareils.expireDans(temps: _mmss(restant)),
                textAlign: TextAlign.center,
                style: textes.bodyMedium,
              ),
            ),
          ] else if (expire) ...<Widget>[
            Text(
              t.appareils.expire,
              textAlign: TextAlign.center,
              style: palette.inkAlert.applyTo(
                textes.titleMedium ?? const TextStyle(),
              ),
            ),
            Ecart.vXl,
            ActionPrincipale(
              libelle: t.appareils.regenerer,
              onPress: () => unawaited(_demander()),
              enCours: _enCours,
            ),
          ] else if (_erreur != null) ...<Widget>[
            Text(
              _erreur!,
              textAlign: TextAlign.center,
              style: palette.inkAlert.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
            Ecart.vXl,
            ActionPrincipale(
              libelle: t.commun.reessayer,
              onPress: () => unawaited(_demander()),
              enCours: _enCours,
            ),
          ] else
            Center(child: Text(t.commun.chargement)),
        ],
      ),
    );
  }
}

/// Le QR, qui ne porte que le code : ni identifiant de foyer, ni adresse.
///
/// Ce qui est photographie par un tiers ne doit rien apprendre de plus que ce
/// qui est deja lisible en dessous.
class _Qr extends StatelessWidget {
  const _Qr({required this.code, required this.paire});

  final String code;
  final AppColorPair paire;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: QrImageView(
        data: code,
        size: AppSpacing.xxxl * 7,
        backgroundColor: paire.background,
        eyeStyle: QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: paire.onBackground,
        ),
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: paire.onBackground,
        ),
      ),
    );
  }
}

/// Le code en clair, espace pour etre lu a voix haute sans se tromper.
class _CodeEnClair extends StatelessWidget {
  const _CodeEnClair({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Semantics(
      label: code.split('').join(' '),
      excludeSemantics: true,
      child: Text(
        code.split('').join(' '),
        textAlign: TextAlign.center,
        style: palette.inkAccent.applyTo(
          textes.headlineMedium ?? const TextStyle(),
        ),
      ),
    );
  }
}

String _mmss(Duration duree) {
  final int minutes = duree.inMinutes;
  final int secondes = duree.inSeconds % 60;
  return '$minutes:${secondes.toString().padLeft(2, '0')}';
}
