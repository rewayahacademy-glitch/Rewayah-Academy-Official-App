import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/service_auth.dart';
import '../../core/config/env.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/page_shell.dart';

/// `TUT-00` : la connexion.
///
/// Dans un build `DEMO_AUTH`, une adresse fictive choisit localement le role et
/// ne contacte pas Supabase. Le lien recu par courriel et Google restent
/// disponibles. C'est aussi le seul ecran du produit atteignable sans session.
///
/// L'etat « lien envoye » ne se ferme pas tout seul et ne compte pas a rebours :
/// rien ne se ferme sur minuterie dans ce produit
/// (`docs/produit/parcours-utilisateurs.md`, regles communes).
class ConnexionPage extends ConsumerStatefulWidget {
  /// Cree l'ecran de connexion.
  const ConnexionPage({super.key, this.demoAuth});

  /// Permet de tester le parcours sans modifier les defines de compilation.
  ///
  /// L'appel du routeur ne renseigne pas cette valeur et suit donc
  /// [Env.authParMotDePasseActive].
  final bool? demoAuth;

  @override
  ConsumerState<ConnexionPage> createState() => _ConnexionPageState();
}

class _ConnexionPageState extends ConsumerState<ConnexionPage> {
  final TextEditingController _courriel = TextEditingController();
  final TextEditingController _motDePasse = TextEditingController();
  bool _envoi = false;
  bool _connexionEnCours = false;
  bool _envoye = false;
  String? _erreur;
  String? _erreurConnexion;

  bool get _modeDemo => widget.demoAuth ?? ref.read(demoAuthActiveProvider);

  @override
  void dispose() {
    _courriel.dispose();
    _motDePasse.dispose();
    super.dispose();
  }

  bool get _adressePlausible => courrielPlausible(_courriel.text);

  Future<void> _envoyerLien() async {
    if (!_adressePlausible) {
      setState(() => _erreur = t.connexion.erreurCourriel);
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref.read(serviceAuthProvider).envoyerLienCourriel(_courriel.text);
      if (mounted) {
        setState(() => _envoye = true);
      }
    } on Object {
      if (mounted) {
        setState(() => _erreur = t.connexion.erreurEnvoi);
      }
    } finally {
      if (mounted) {
        setState(() => _envoi = false);
      }
    }
  }

  Future<void> _google() async {
    setState(() => _erreur = null);
    try {
      await ref.read(serviceAuthProvider).connexionGoogle();
    } on Object {
      if (mounted) {
        setState(() => _erreur = t.connexion.erreurEnvoi);
      }
    }
  }

  Future<void> _connecterMotDePasse() async {
    if (!_adressePlausible) {
      setState(() => _erreur = t.connexion.erreurCourriel);
      return;
    }
    if (_motDePasse.text.isEmpty) {
      setState(() => _erreurConnexion = t.connexion.erreurMotDePasse);
      return;
    }

    setState(() {
      _connexionEnCours = true;
      _erreur = null;
      _erreurConnexion = null;
    });
    try {
      if (ref.read(demoAuthActiveProvider)) {
        final AccesDemo? acces = accesDemoDepuisCourriel(_courriel.text);
        if (acces == null) {
          throw const FormatException('role demo inconnu');
        }
        ref.read(sessionProvider.notifier).ouvrirDemo(acces);
      } else {
        await ref
            .read(serviceAuthProvider)
            .connexionMotDePasse(_courriel.text, _motDePasse.text);
      }
    } on Object {
      if (mounted) {
        setState(() => _erreurConnexion = t.connexion.erreurConnexion);
      }
    } finally {
      if (mounted) {
        setState(() => _connexionEnCours = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppPage.largeurEtatVide + AppSpacing.respiration,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _MarqueConnexion(),
              Ecart.vXxxl,
              AppCard(
                key: const ValueKey<String>('connexion-carte'),
                dominante: true,
                child: _envoye
                    ? _LienEnvoye(
                        courriel: _courriel.text.trim(),
                        onChangerAdresse: () => setState(() => _envoye = false),
                      )
                    : _Saisie(
                        controleur: _courriel,
                        motDePasse: _motDePasse,
                        erreur: _erreur,
                        erreurConnexion: _erreurConnexion,
                        envoi: _envoi,
                        connexionEnCours: _connexionEnCours,
                        modeDemo: _modeDemo,
                        peutEnvoyer: _adressePlausible,
                        onChanged: () => setState(() {
                          _erreur = null;
                          _erreurConnexion = null;
                        }),
                        onMotDePasseChanged: () => setState(() {
                          _erreurConnexion = null;
                        }),
                        onEnvoyer: () => unawaited(_envoyerLien()),
                        onConnexion: () => unawaited(_connecterMotDePasse()),
                        onGoogle: () => unawaited(_google()),
                        onEleve: () =>
                            GoRouter.of(context).go(Routes.connexionEleve),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarqueConnexion extends StatelessWidget {
  const _MarqueConnexion();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Semantics(
      header: true,
      child: Column(
        children: <Widget>[
          ExcludeSemantics(
            child: SizedBox.square(
              dimension: AppSpacing.respiration,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.washAccent.background,
                  borderRadius: AppRadius.arrondiFull,
                  border: Border.fromBorderSide(
                    palette.borderHairline.asBorderSide(),
                  ),
                ),
                child: Center(
                  child: Text(
                    'R',
                    style: palette.inkAccent.applyTo(
                      textes.headlineMedium ?? const TextStyle(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Ecart.vMd,
          Text(
            t.commun.marque,
            textAlign: TextAlign.center,
            style: palette.inkAccent.applyTo(
              textes.displaySmall ?? const TextStyle(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Saisie extends StatelessWidget {
  const _Saisie({
    required this.controleur,
    required this.motDePasse,
    required this.erreur,
    required this.erreurConnexion,
    required this.envoi,
    required this.connexionEnCours,
    required this.modeDemo,
    required this.peutEnvoyer,
    required this.onChanged,
    required this.onMotDePasseChanged,
    required this.onEnvoyer,
    required this.onConnexion,
    required this.onGoogle,
    required this.onEleve,
  });

  final TextEditingController controleur;
  final TextEditingController motDePasse;
  final String? erreur;
  final String? erreurConnexion;
  final bool envoi;
  final bool connexionEnCours;
  final bool modeDemo;
  final bool peutEnvoyer;
  final VoidCallback onChanged;
  final VoidCallback onMotDePasseChanged;
  final VoidCallback onEnvoyer;
  final VoidCallback onConnexion;
  final VoidCallback onGoogle;
  final VoidCallback onEleve;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (modeDemo) ...<Widget>[
          Text(
            t.connexion.demoTitre,
            style: palette.inkAccent.applyTo(
              textes.labelLarge ?? const TextStyle(),
            ),
          ),
          Ecart.vMd,
        ],
        Text(t.connexion.titre, style: textes.headlineMedium),
        Ecart.vSm,
        Text(
          modeDemo ? t.connexion.introDemo : t.connexion.intro,
          style: textes.bodyMedium,
        ),
        Ecart.vXxl,
        TextField(
          key: const ValueKey<String>('connexion-courriel'),
          controller: controleur,
          onChanged: (String _) => onChanged(),
          onSubmitted: (String _) =>
              modeDemo ? FocusScope.of(context).nextFocus() : onEnvoyer(),
          keyboardType: TextInputType.emailAddress,
          autofillHints: const <String>[AutofillHints.email],
          textInputAction: TextInputAction.go,
          decoration: _decorationChamp(
            context,
            libelle: t.connexion.courriel,
            erreur: erreur,
          ),
        ),
        Ecart.vLg,
        if (modeDemo) ...<Widget>[
          TextField(
            key: const ValueKey<String>('connexion-mot-de-passe'),
            controller: motDePasse,
            onChanged: (String _) => onMotDePasseChanged(),
            onSubmitted: (String _) => onConnexion(),
            obscureText: true,
            autofillHints: const <String>[AutofillHints.password],
            textInputAction: TextInputAction.done,
            decoration: _decorationChamp(
              context,
              libelle: t.connexion.motDePasse,
              erreur: erreurConnexion,
            ),
          ),
          Ecart.vLg,
          ActionPrincipale(
            libelle: t.connexion.seConnecter,
            onPress: peutEnvoyer && motDePasse.text.isNotEmpty
                ? onConnexion
                : null,
            enCours: connexionEnCours,
          ),
        ] else ...<Widget>[
          ActionPrincipale(
            libelle: t.connexion.envoyerLien,
            onPress: peutEnvoyer ? onEnvoyer : null,
            enCours: envoi,
          ),
          Ecart.vXl,
          Row(
            children: <Widget>[
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(t.connexion.ou, style: textes.bodySmall),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          Ecart.vXl,
          ActionPrincipale(
            libelle: t.connexion.avecGoogle,
            onPress: onGoogle,
            niveau: NiveauAction.secondaire,
          ),
          Ecart.vXxl,
          ActionPrincipale(
            libelle: t.eleveConnexion.entrerCode,
            onPress: onEleve,
            niveau: NiveauAction.tertiaire,
          ),
        ],
      ],
    );
  }

  InputDecoration _decorationChamp(
    BuildContext context, {
    required String libelle,
    String? erreur,
  }) {
    final AppPalette palette = AppPalette.of(context);
    return InputDecoration(
      labelText: libelle,
      errorText: erreur,
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.arrondiMd,
        borderSide: palette.borderHairline.asBorderSide(),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.arrondiMd,
        borderSide: palette.inkAccent.asBorderSide(width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.arrondiMd,
        borderSide: palette.inkAlert.asBorderSide(width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.arrondiMd,
        borderSide: palette.inkAlert.asBorderSide(width: 2),
      ),
    );
  }
}

class _LienEnvoye extends StatelessWidget {
  const _LienEnvoye({required this.courriel, required this.onChangerAdresse});

  final String courriel;
  final VoidCallback onChangerAdresse;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(t.connexion.lienEnvoye, style: textes.headlineMedium),
        Ecart.vMd,
        Text(
          t.connexion.lienEnvoyeDetail(courriel: courriel),
          style: textes.bodyMedium,
        ),
        Ecart.vXxl,
        ActionPrincipale(
          libelle: t.connexion.changerAdresse,
          onPress: onChangerAdresse,
          niveau: NiveauAction.secondaire,
        ),
      ],
    );
  }
}
