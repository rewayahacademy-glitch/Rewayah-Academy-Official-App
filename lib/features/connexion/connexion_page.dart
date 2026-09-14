import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/service_auth.dart';
import '../../core/config/env.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/marque_page.dart';
import '../../core/widgets/page_shell.dart';

/// `TUT-00` : la connexion.
///
/// En production, un lien recu par courriel ou Google reste le parcours
/// public. Une compilation locale peut ajouter un mot de passe pour faciliter
/// les essais d'interfaces, sans changer la source de session ni les droits.
/// C'est aussi le seul ecran du produit atteignable sans session.
///
/// L'etat « lien envoye » ne se ferme pas tout seul et ne compte pas a rebours :
/// rien ne se ferme sur minuterie dans ce produit
/// (`docs/produit/parcours-utilisateurs.md`, regles communes).
class ConnexionPage extends ConsumerStatefulWidget {
  /// Cree l'ecran de connexion.
  const ConnexionPage({super.key, this.demoAuth});

  /// Permet de tester le parcours sans modifier les defines de compilation.
  ///
  /// L'appel de production ne renseigne pas cette valeur et suit donc
  /// [Env.authParMotDePasseActive], faux par defaut.
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

  bool get _modeDemo => widget.demoAuth ?? Env.authParMotDePasseActive;

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
      await ref
          .read(serviceAuthProvider)
          .connexionMotDePasse(_courriel.text, _motDePasse.text);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const MarquePage(),
          Ecart.vXxxl,
          Align(
            alignment: AlignmentDirectional.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppPage.largeurFormulaire,
              ),
              child: AppCard(
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
          Semantics(
            liveRegion: true,
            child: Text(
              t.connexion.demoTitre,
              style: palette.inkWarning.applyTo(
                textes.labelLarge ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vSm,
          Text(t.connexion.demoDetail, style: textes.bodyMedium),
          Ecart.vXxl,
        ],
        Text(t.connexion.titre, style: textes.headlineMedium),
        Ecart.vMd,
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
          decoration: InputDecoration(
            labelText: t.connexion.courriel,
            errorText: erreur,
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
            decoration: InputDecoration(
              labelText: t.connexion.motDePasse,
              errorText: erreurConnexion,
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
          Ecart.vLg,
          ActionPrincipale(
            libelle: t.connexion.envoyerLien,
            onPress: peutEnvoyer ? onEnvoyer : null,
            niveau: NiveauAction.tertiaire,
            enCours: envoi,
          ),
        ] else
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
        Ecart.vXxxl,
        // L'entree de l'eleve, discrete : c'est un parcours different, pas une
        // autre facon de faire le meme. L'enfant arrive avec un code que son
        // tuteur vient de lui montrer, jamais avec une adresse.
        ActionPrincipale(
          libelle: t.eleveConnexion.entrerCode,
          onPress: onEleve,
          niveau: NiveauAction.secondaire,
        ),
      ],
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
