import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/service_auth.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/offline_banner.dart';

/// `TUT-00` : la connexion.
///
/// Un lien recu par courriel, ou Google. **Aucun mot de passe** : ni a creer,
/// ni a retenir, ni a reinitialiser. C'est aussi le seul ecran du produit
/// atteignable sans session.
///
/// L'etat « lien envoye » ne se ferme pas tout seul et ne compte pas a rebours :
/// rien ne se ferme sur minuterie dans ce produit
/// (`docs/produit/parcours-utilisateurs.md`, regles communes).
class ConnexionPage extends ConsumerStatefulWidget {
  /// Cree l'ecran de connexion.
  const ConnexionPage({super.key});

  @override
  ConsumerState<ConnexionPage> createState() => _ConnexionPageState();
}

class _ConnexionPageState extends ConsumerState<ConnexionPage> {
  final TextEditingController _courriel = TextEditingController();
  bool _envoi = false;
  bool _envoye = false;
  String? _erreur;

  @override
  void dispose() {
    _courriel.dispose();
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

  @override
  Widget build(BuildContext context) {
    final AppMetriques metriques = AppMetriques.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const OfflineBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(metriques.marge),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppSpacing.xxxl * 15),
                  child: _envoye ? _LienEnvoye(
                    courriel: _courriel.text.trim(),
                    onChangerAdresse: () => setState(() => _envoye = false),
                  ) : _Saisie(
                    controleur: _courriel,
                    erreur: _erreur,
                    envoi: _envoi,
                    peutEnvoyer: _adressePlausible,
                    onChanged: () => setState(() {}),
                    onEnvoyer: () => unawaited(_envoyerLien()),
                    onGoogle: () => unawaited(_google()),
                    onEleve: () =>
                        GoRouter.of(context).go(Routes.connexionEleve),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Saisie extends StatelessWidget {
  const _Saisie({
    required this.controleur,
    required this.erreur,
    required this.envoi,
    required this.peutEnvoyer,
    required this.onChanged,
    required this.onEnvoyer,
    required this.onGoogle,
    required this.onEleve,
  });

  final TextEditingController controleur;
  final String? erreur;
  final bool envoi;
  final bool peutEnvoyer;
  final VoidCallback onChanged;
  final VoidCallback onEnvoyer;
  final VoidCallback onGoogle;
  final VoidCallback onEleve;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Ecart.vXxxl,
        Text(t.connexion.titre, style: textes.headlineMedium),
        Ecart.vMd,
        Text(t.connexion.intro, style: textes.bodyMedium),
        Ecart.vXxl,
        TextField(
          controller: controleur,
          onChanged: (String _) => onChanged(),
          onSubmitted: (String _) => onEnvoyer(),
          keyboardType: TextInputType.emailAddress,
          autofillHints: const <String>[AutofillHints.email],
          textInputAction: TextInputAction.go,
          decoration: InputDecoration(
            labelText: t.connexion.courriel,
            errorText: erreur,
          ),
        ),
        Ecart.vLg,
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
          surface: palette.surfaceBase,
        ),
        Ecart.vXxxl,
        // L'entree de l'eleve, discrete : c'est un parcours different, pas une
        // autre facon de faire le meme. L'enfant arrive avec un code que son
        // tuteur vient de lui montrer, jamais avec une adresse.
        ActionPrincipale(
          libelle: t.eleveConnexion.entrerCode,
          onPress: onEleve,
          surface: palette.surfaceBase,
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
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Ecart.vXxxl,
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
          surface: palette.surfaceBase,
        ),
      ],
    );
  }
}
