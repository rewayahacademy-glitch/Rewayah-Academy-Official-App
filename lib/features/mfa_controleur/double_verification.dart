// MFA-DIRECTION (garde-cap G12, pilote, 03/11/2026) : la montee en `aal2` au
// moment d'un geste qui l'exige, jamais a l'entree.
//
// Un geste de la direction refuse par le serveur (42501, rendu en
// [PermissionInsuffisante]) alors que la session est en `aal1` ouvre une
// feuille « Code de vérification » : sans facteur enrole, elle dit d'activer
// la double verification dans Compte > Securite ; avec un facteur, elle
// demande le code. Un code accepte eleve le jeton a `aal2` (le serveur
// d'authentification le pose ; rien ici ne l'accorde) et le geste est rejoue
// une fois. La base re-verifie toujours (`app_aal()`).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../core/capacites/permission_insuffisante.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/skeleton.dart';
import 'port_mfa.dart';

/// Les cles de la feuille, pour les tests.
abstract final class CleDoubleVerification {
  /// Le champ du code.
  static const Key champ = ValueKey<String>('dv-code');

  /// « Confirmer le code et continuer ».
  static const Key confirmer = ValueKey<String>('dv-confirmer');

  /// Le lien vers Compte > Securite.
  static const Key ouvrirSecurite = ValueKey<String>('dv-ouvrir-securite');
}

/// Vrai quand la session peut monter en `aal2` sur demande : la direction,
/// pas encore en `aal2`.
bool peutMonterEnDoubleVerification(SessionState session) =>
    session.peutActiverDoubleVerification && !session.doubleVerificationFaite;

/// [peutMonterEnDoubleVerification] pour la session lue par [ref]. Une
/// session illisible (aucune, ou source en echec) ne monte pas : le refus du
/// serveur est alors dit tel quel.
bool peutMonterIci(WidgetRef ref) {
  try {
    return peutMonterEnDoubleVerification(ref.read(sessionProvider));
  } on Object {
    return false;
  }
}

/// Vrai pour un refus de droit du serveur : [PermissionInsuffisante] (port
/// qui le traduit) ou un `42501` brut.
bool estRefusDeDroit(Object e) =>
    e is PermissionInsuffisante ||
    (e is PostgrestException && e.code == '42501');

/// Joue [geste] ; s'il est refuse faute de double verification ([refus], par
/// defaut [estRefusDeDroit]), demande le code puis le rejoue une fois. Un
/// second refus remonte tel quel, comme tout refus quand la session ne peut
/// pas monter (autre compte, deja `aal2`), et une feuille fermee sans code.
Future<T> avecDoubleVerification<T>(
  BuildContext context,
  WidgetRef ref,
  Future<T> Function() geste, {
  bool Function(Object erreur) refus = estRefusDeDroit,
}) async {
  try {
    return await geste();
  } on Object catch (e) {
    if (!refus(e) || !context.mounted || !peutMonterIci(ref)) {
      rethrow;
    }
    final bool verifiee = await demanderDoubleVerification(context);
    if (!verifiee) rethrow;
    return geste();
  }
}

/// Ouvre la feuille du code ; rend `true` si le code est accepte (le jeton
/// est alors en `aal2`).
Future<bool> demanderDoubleVerification(BuildContext context) async {
  final bool? ok = await AppBottomSheet.ouvrir<bool>(
    context,
    titre: t.compte.doubleVerification.feuille.titre,
    constructeur: (BuildContext contexte) => _FeuilleCode(
      onVerifiee: () => Navigator.of(contexte).pop(true),
      onOuvrirSecurite: () {
        Navigator.of(contexte).pop(false);
        GoRouter.of(context).push(Routes.compteSecurite);
      },
    ),
  );
  return ok ?? false;
}

class _FeuilleCode extends ConsumerStatefulWidget {
  const _FeuilleCode({
    required this.onVerifiee,
    required this.onOuvrirSecurite,
  });

  final VoidCallback onVerifiee;
  final VoidCallback onOuvrirSecurite;

  @override
  ConsumerState<_FeuilleCode> createState() => _FeuilleCodeState();
}

class _FeuilleCodeState extends ConsumerState<_FeuilleCode> {
  final TextEditingController _code = TextEditingController();
  late final Future<SituationMfa> _situation = ref
      .read(portMfaProvider)
      .situation();
  String? _erreurChamp;
  String? _erreurEnvoi;
  bool _envoi = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _valider(String facteurId) async {
    if (_envoi) return;
    final String code = _code.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _erreurChamp = t.controleur.mfa.codeIncomplet);
      return;
    }
    setState(() {
      _envoi = true;
      _erreurChamp = null;
      _erreurEnvoi = null;
    });
    final f = t.compte.doubleVerification.feuille;
    try {
      await ref
          .read(portMfaProvider)
          .verifier(facteurId: facteurId, code: code);
      widget.onVerifiee();
      return;
    } on MfaCodeRefuse {
      if (mounted) setState(() => _erreurChamp = t.controleur.mfa.codeRefuse);
    } on MfaHorsLigne {
      if (mounted) setState(() => _erreurEnvoi = f.horsLigne);
    } on Object {
      if (mounted) setState(() => _erreurEnvoi = f.erreur);
    }
    if (mounted) setState(() => _envoi = false);
  }

  @override
  Widget build(BuildContext context) {
    final f = t.compte.doubleVerification.feuille;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle corps = palette.surfaceRaised.applyTo(
      textes.bodyLarge ?? const TextStyle(),
    );
    return FutureBuilder<SituationMfa>(
      future: _situation,
      builder: (BuildContext _, AsyncSnapshot<SituationMfa> lu) {
        if (lu.hasError) {
          return Text(
            lu.error is MfaHorsLigne ? f.horsLigne : f.erreur,
            style: palette.inkAlert.applyTo(corps),
          );
        }
        final SituationMfa? s = lu.data;
        if (s == null) return const Skeleton.liste(lignes: 2);
        return switch (s) {
          MfaAEnroler() => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(f.aActiverTitre, style: textes.titleMedium),
              Ecart.vSm,
              Text(f.aActiverPhrase, style: corps),
              Ecart.vLg,
              LienFleche(
                key: CleDoubleVerification.ouvrirSecurite,
                libelle: f.ouvrirSecurite,
                onPress: widget.onOuvrirSecurite,
              ),
            ],
          ),
          MfaAVerifier(:final String facteurId) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(f.intro, style: corps),
              Ecart.vLg,
              Text(t.controleur.mfa.champCode, style: textes.labelLarge),
              Ecart.vSm,
              TextField(
                key: CleDoubleVerification.champ,
                controller: _code,
                autofocus: true,
                onSubmitted: (String _) => unawaited(_valider(facteurId)),
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                autofillHints: const <String>[AutofillHints.oneTimeCode],
                textInputAction: TextInputAction.go,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(errorText: _erreurChamp),
              ),
              if (_erreurEnvoi case final String erreur) ...<Widget>[
                Ecart.vMd,
                Semantics(
                  liveRegion: true,
                  child: Text(erreur, style: palette.inkAlert.applyTo(corps)),
                ),
              ],
              Ecart.vXl,
              ActionPrincipale(
                key: CleDoubleVerification.confirmer,
                libelle: f.confirmer,
                enCours: _envoi,
                onPress: () => unawaited(_valider(facteurId)),
              ),
            ],
          ),
        };
      },
    );
  }
}
