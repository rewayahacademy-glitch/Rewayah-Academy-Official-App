import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, AuthRetryableFetchException;

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/auth/service_auth.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import 'coquille_entree.dart';

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
  const RecuperationPage({super.key, this.motif, this.courrielInitial});

  /// Le motif d'arrivee, pour les tests et la galerie.
  final MotifRecuperation? motif;

  /// Le courriel deja saisi sur l'ecran de connexion (FORM-L10), pre-rempli
  /// ici pour ne pas le faire retaper. Transmis par le routeur (`extra`), pas
  /// par l'URL : une adresse n'a rien a faire dans un lien.
  final String? courrielInitial;

  @override
  ConsumerState<RecuperationPage> createState() => _RecuperationPageState();
}

class _RecuperationPageState extends ConsumerState<RecuperationPage> {
  late final TextEditingController _courriel = TextEditingController(
    text: widget.courrielInitial?.trim() ?? '',
  );
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
    final String? brut = GoRouter.maybeOf(context)
        ?.routeInformationProvider
        .value
        .uri
        .queryParameters['motif'];
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
    final MotifRecuperation? motif = _motif(context);

    // Meme habillage que la connexion (parcours d'entree, 25/10/2026, §3 D) ;
    // le retour vers la connexion reste visible a chaque etat.
    return CoquilleEntree(
      onRetour: _revenir,
      formulaire: (bool bureau) => _envoye
          ? _Envoye(
              bureau: bureau,
              courriel: _courriel.text.trim(),
              renvoye: _renvoye,
              envoi: _envoi,
              erreur: _erreurEnvoi,
              onRenvoyer: () => unawaited(_envoyer(renvoi: true)),
              onAutreAdresse: () => setState(() {
                _envoye = false;
                _renvoye = false;
                _erreurEnvoi = null;
              }),
              onRevenir: _revenir,
            )
          : _Saisie(
              bureau: bureau,
              motif: motif,
              courriel: _courriel,
              erreurChamp: _erreurChamp,
              erreurEnvoi: _erreurEnvoi,
              envoi: _envoi,
              onEnvoyer: () => unawaited(_envoyer()),
              onRevenir: _revenir,
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
      // L'encre d'alerte de la surface : blanche sur la marque, d'alerte sur
      // le parchemin.
      style: AppPalette.of(context).inkAlert
          .applyTo(Theme.of(context).textTheme.bodyMedium!),
    ),
  );
}

class _Saisie extends StatelessWidget {
  const _Saisie({
    required this.bureau,
    required this.motif,
    required this.courriel,
    required this.erreurChamp,
    required this.erreurEnvoi,
    required this.envoi,
    required this.onEnvoyer,
    required this.onRevenir,
  });

  final bool bureau;
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
        TexteSansCoupure(
          t.connexion.recuperation.titre,
          style: textes.headlineMedium,
        ),
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
        ChampEntree(
          cle: 'recuperation-courriel',
          etiquette: t.connexion.courriel,
          indice: t.connexion.courrielIndice,
          controleur: courriel,
          erreur: erreurChamp,
          onSoumettre: onEnvoyer,
          clavier: TextInputType.emailAddress,
          autofill: const <String>[AutofillHints.email],
        ),
        if (erreurEnvoi != null) ...<Widget>[
          Ecart.vMd,
          _PhraseErreur(erreurEnvoi!),
        ],
        Ecart.vLg,
        BoutonEntree(
          bureau: bureau,
          child: ActionPrincipale(
            libelle: t.connexion.recuperation.envoyer,
            onPress: onEnvoyer,
            enCours: envoi,
            affirmee: true,
            pleineLargeur: !bureau,
          ),
        ),
        Ecart.vXxl,
        LienEntree(
          libelle: t.connexion.recuperation.revenirConnexion,
          onPress: onRevenir,
        ),
      ],
    );
  }
}

class _Envoye extends StatelessWidget {
  const _Envoye({
    required this.bureau,
    required this.courriel,
    required this.renvoye,
    required this.envoi,
    required this.erreur,
    required this.onRenvoyer,
    required this.onAutreAdresse,
    required this.onRevenir,
  });

  final bool bureau;
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
        TexteSansCoupure(
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
        Ecart.vXxl,
        BoutonEntree(
          bureau: bureau,
          child: ActionPrincipale(
            libelle: t.connexion.renvoyer,
            onPress: onRenvoyer,
            enCours: envoi,
            niveau: NiveauAction.secondaire,
            pleineLargeur: !bureau,
          ),
        ),
        Ecart.vLg,
        LienEntree(
          libelle: t.connexion.recuperation.autreAdresse,
          onPress: onAutreAdresse,
        ),
        LienEntree(
          libelle: t.connexion.recuperation.revenirConnexion,
          onPress: onRevenir,
        ),
      ],
    );
  }
}
