import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, AuthRetryableFetchException;

import '../../core/auth/service_auth.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/marque_page.dart';
import '../../core/widgets/page_shell.dart';

/// Pourquoi l'usager arrive sur la recuperation d'acces.
///
/// Lu dans le parametre `?motif=` de `/connexion/recuperation`, pose par la
/// connexion quand l'URL de retour du fournisseur porte une erreur
/// (C03 section 9 : le lien expire n'etait pas gere).
enum MotifRecuperation {
  /// Le lien a expire ou a deja servi (`otp_expired`).
  expire,

  /// Le fournisseur a refuse l'ouverture de session pour une autre raison.
  refuse,
}

/// Le motif porte par une URL de retour du fournisseur, ou `null`.
///
/// Supabase renvoie l'erreur dans le fragment (flux implicite,
/// `#error=access_denied&error_code=otp_expired`) ou dans la requete (flux
/// PKCE). Les deux sont lus ; seul `otp_expired` vaut « expire ».
MotifRecuperation? motifDepuisUrlRetour(Uri url) {
  final Map<String, String> champs = <String, String>{
    ...url.queryParameters,
    ..._champsFragment(url.fragment),
  };
  final String? code = champs['error_code'];
  final String? erreur = champs['error'];
  if (code == null && erreur == null) {
    return null;
  }
  return code == 'otp_expired'
      ? MotifRecuperation.expire
      : MotifRecuperation.refuse;
}

Map<String, String> _champsFragment(String fragment) {
  // Un fragment de go_router (`#/connexion`) n'est pas une requete.
  final String brut = fragment.contains('?')
      ? fragment.substring(fragment.indexOf('?') + 1)
      : fragment;
  if (!brut.contains('=')) {
    return const <String, String>{};
  }
  try {
    return Uri.splitQueryString(brut);
  } on FormatException {
    return const <String, String>{};
  }
}

/// Le chemin de la recuperation pour un motif.
String cheminRecuperation(MotifRecuperation? motif) => motif == null
    ? Routes.connexionRecuperation
    : '${Routes.connexionRecuperation}?motif=${motif.name}';

/// L'issue d'un echec de demande de lien, dite a l'ecran.
enum IssueEnvoiLien {
  /// Le serveur limite les envois (429, `over_email_send_rate_limit`).
  tropTot,

  /// Le reseau ne repond pas.
  horsLigne,

  /// Tout autre echec.
  erreur,
}

/// Classe l'exception d'un envoi de lien.
IssueEnvoiLien issueEchecEnvoi(Object erreur) {
  if (erreur is AuthRetryableFetchException) {
    return IssueEnvoiLien.horsLigne;
  }
  if (erreur is AuthException) {
    final String code = erreur.code ?? '';
    if (erreur.statusCode == '429' || code.contains('rate_limit')) {
      return IssueEnvoiLien.tropTot;
    }
    return IssueEnvoiLien.erreur;
  }
  final String texte = erreur.toString();
  if (texte.contains('SocketException') ||
      texte.contains('ClientException') ||
      texte.contains('Failed host lookup')) {
    return IssueEnvoiLien.horsLigne;
  }
  return IssueEnvoiLien.erreur;
}

/// La phrase d'un echec d'envoi.
String phraseEchecEnvoi(IssueEnvoiLien issue) => switch (issue) {
  IssueEnvoiLien.tropTot => t.connexion.erreurTropTot,
  IssueEnvoiLien.horsLigne => t.connexion.horsLigne,
  IssueEnvoiLien.erreur => t.connexion.erreurEnvoi,
};

/// Largeur de la carte, la meme que celle de la connexion.
const double _largeurCarte = 460;

/// La recuperation d'acces : un nouveau lien de connexion, jamais un mot de
/// passe (C03 section 9, aucun mot de passe en production).
///
/// Etats : saisie (avec l'encart du motif quand l'URL de retour portait une
/// erreur), envoi en cours, lien envoye (avec « Renvoyer le lien »), erreur,
/// trop tot, hors ligne. Retour visible vers la connexion a chaque etat.
class RecuperationPage extends ConsumerStatefulWidget {
  /// Cree la page.
  ///
  /// [motif] force le motif ; sans lui, la page lit `?motif=` dans l'URL.
  const RecuperationPage({super.key, this.motif});

  /// Le motif d'arrivee, pour les tests et la galerie.
  final MotifRecuperation? motif;

  @override
  ConsumerState<RecuperationPage> createState() => _RecuperationPageState();
}

class _RecuperationPageState extends ConsumerState<RecuperationPage> {
  final TextEditingController _courriel = TextEditingController();
  bool _envoi = false;
  bool _envoye = false;
  bool _renvoye = false;
  String? _erreurChamp;
  String? _erreurEnvoi;

  @override
  void dispose() {
    _courriel.dispose();
    super.dispose();
  }

  MotifRecuperation? _motif(BuildContext context) {
    if (widget.motif != null) {
      return widget.motif;
    }
    final String? brut = GoRouter.maybeOf(
      context,
    )?.routeInformationProvider.value.uri.queryParameters['motif'];
    for (final MotifRecuperation m in MotifRecuperation.values) {
      if (m.name == brut) {
        return m;
      }
    }
    return null;
  }

  Future<void> _envoyer({bool renvoi = false}) async {
    if (_envoi) {
      return;
    }
    if (!courrielPlausible(_courriel.text)) {
      setState(() => _erreurChamp = t.connexion.erreurCourriel);
      return;
    }
    setState(() {
      _envoi = true;
      _erreurChamp = null;
      _erreurEnvoi = null;
    });
    try {
      await ref.read(serviceAuthProvider).envoyerLienCourriel(_courriel.text);
      if (mounted) {
        setState(() {
          _envoye = true;
          _renvoye = renvoi;
        });
      }
    } on Object catch (erreur) {
      if (mounted) {
        setState(
          () => _erreurEnvoi = phraseEchecEnvoi(issueEchecEnvoi(erreur)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _envoi = false);
      }
    }
  }

  void _revenir() => GoRouter.of(context).go(Routes.connexion);

  @override
  Widget build(BuildContext context) {
    final Widget respiration = AppGabarit.de(context) == Gabarit.mobile
        ? Ecart.vXxl
        : Ecart.vSection;
    final MotifRecuperation? motif = _motif(context);

    return PageShell(
      onRetour: _revenir,
      defilante: false,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints contraintes) =>
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: contraintes.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const MarquePage(),
                    respiration,
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _largeurCarte,
                      ),
                      child: AppCard(
                        key: const ValueKey<String>('recuperation-carte'),
                        dominante: true,
                        child: _envoye
                            ? _Envoye(
                                courriel: _courriel.text.trim(),
                                renvoye: _renvoye,
                                envoi: _envoi,
                                erreur: _erreurEnvoi,
                                onRenvoyer: () =>
                                    unawaited(_envoyer(renvoi: true)),
                                onAutreAdresse: () => setState(() {
                                  _envoye = false;
                                  _renvoye = false;
                                  _erreurEnvoi = null;
                                }),
                                onRevenir: _revenir,
                              )
                            : _Saisie(
                                motif: motif,
                                courriel: _courriel,
                                erreurChamp: _erreurChamp,
                                erreurEnvoi: _erreurEnvoi,
                                envoi: _envoi,
                                onEnvoyer: () => unawaited(_envoyer()),
                                onRevenir: _revenir,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}

/// Une phrase d'echec d'envoi, annoncee aux lecteurs d'ecran.
class _PhraseErreur extends StatelessWidget {
  const _PhraseErreur(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      texte,
      key: const ValueKey<String>('recuperation-erreur'),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.error,
      ),
    ),
  );
}

class _Saisie extends StatelessWidget {
  const _Saisie({
    required this.motif,
    required this.courriel,
    required this.erreurChamp,
    required this.erreurEnvoi,
    required this.envoi,
    required this.onEnvoyer,
    required this.onRevenir,
  });

  final MotifRecuperation? motif;
  final TextEditingController courriel;
  final String? erreurChamp;
  final String? erreurEnvoi;
  final bool envoi;
  final VoidCallback onEnvoyer;
  final VoidCallback onRevenir;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle discret = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final bool expire = motif == MotifRecuperation.expire;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(t.connexion.recuperation.titre, style: textes.headlineMedium),
        Ecart.vMd,
        if (motif != null) ...<Widget>[
          Semantics(
            container: true,
            liveRegion: true,
            child: Column(
              key: const ValueKey<String>('recuperation-motif'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  expire
                      ? t.connexion.recuperation.lienExpireTitre
                      : t.connexion.recuperation.lienRefuseTitre,
                  style: textes.titleMedium,
                ),
                Ecart.vSm,
                Text(
                  expire
                      ? t.connexion.recuperation.lienExpire
                      : t.connexion.recuperation.lienRefuse,
                  style: discret,
                ),
              ],
            ),
          ),
          Ecart.vLg,
        ],
        Text(t.connexion.recuperation.intro, style: discret),
        Ecart.vXxl,
        Text(t.connexion.courriel, style: textes.labelLarge),
        Ecart.vSm,
        TextField(
          key: const ValueKey<String>('recuperation-courriel'),
          controller: courriel,
          onSubmitted: (String _) => onEnvoyer(),
          keyboardType: TextInputType.emailAddress,
          autofillHints: const <String>[AutofillHints.email],
          textInputAction: TextInputAction.go,
          decoration: InputDecoration(
            hintText: t.connexion.courrielIndice,
            errorText: erreurChamp,
          ),
        ),
        if (erreurEnvoi != null) ...<Widget>[
          Ecart.vMd,
          _PhraseErreur(erreurEnvoi!),
        ],
        Ecart.vXl,
        ActionPrincipale(
          libelle: t.connexion.recuperation.envoyer,
          onPress: onEnvoyer,
          enCours: envoi,
        ),
        Ecart.vLg,
        Align(
          child: ActionPrincipale(
            libelle: t.connexion.recuperation.revenirConnexion,
            onPress: onRevenir,
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
          ),
        ),
      ],
    );
  }
}

class _Envoye extends StatelessWidget {
  const _Envoye({
    required this.courriel,
    required this.renvoye,
    required this.envoi,
    required this.erreur,
    required this.onRenvoyer,
    required this.onAutreAdresse,
    required this.onRevenir,
  });

  final String courriel;
  final bool renvoye;
  final bool envoi;
  final String? erreur;
  final VoidCallback onRenvoyer;
  final VoidCallback onAutreAdresse;
  final VoidCallback onRevenir;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle discret = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          t.connexion.recuperation.envoyeTitre,
          style: textes.headlineMedium,
        ),
        Ecart.vMd,
        Semantics(
          liveRegion: true,
          child: Text(
            renvoye
                ? t.connexion.renvoye(courriel: courriel)
                : t.connexion.recuperation.envoye(courriel: courriel),
            key: const ValueKey<String>('recuperation-envoye'),
            style: discret,
          ),
        ),
        Ecart.vMd,
        Text(t.connexion.recuperation.envoyeEncart, style: discret),
        if (erreur != null) ...<Widget>[Ecart.vMd, _PhraseErreur(erreur!)],
        Ecart.vXl,
        ActionPrincipale(
          libelle: t.connexion.renvoyer,
          onPress: onRenvoyer,
          enCours: envoi,
          niveau: NiveauAction.secondaire,
        ),
        Ecart.vLg,
        Align(
          child: ActionPrincipale(
            libelle: t.connexion.recuperation.autreAdresse,
            onPress: onAutreAdresse,
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
          ),
        ),
        Align(
          child: ActionPrincipale(
            libelle: t.connexion.recuperation.revenirConnexion,
            onPress: onRevenir,
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
          ),
        ),
      ],
    );
  }
}
