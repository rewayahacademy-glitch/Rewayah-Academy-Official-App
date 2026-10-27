import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/session/deconnexion.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/marque_page.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import 'port_mfa.dart';

/// Ce que l'ecran montre. Cinq etats, et jamais un autre : chargement,
/// contenu (enrolement ou verification), vide (pas d'application
/// d'authentification), erreur, hors ligne.
enum EtapeMfa {
  /// Lecture de la situation du compte.
  chargement,

  /// Premier facteur : QR et code a six chiffres.
  enrolement,

  /// Facteur deja enrole : le code de cette connexion.
  verification,

  /// La personne n'a pas d'application d'authentification.
  vide,

  /// Le serveur a repondu autrement qu'attendu.
  erreur,

  /// Le reseau ne repond pas.
  horsLigne,
}

/// Largeur de la carte, la meme que celle de la connexion.
const double _largeurCarte = 460;

/// Cote du QR, marge de silence comprise.
const double _coteQr = 200;

/// La seconde etape de connexion du controleur (L1-10, decision A-02).
///
/// Elle s'affiche avant toute navigation tant que la capacite `mfaRequise`
/// est vraie : le routeur ne laisse rien d'autre atteignable. Reussir eleve le
/// jeton a `aal2` ; la session se met a jour et le routeur libere le compte.
class MfaControleurPage extends ConsumerStatefulWidget {
  /// Cree la page.
  const MfaControleurPage({super.key});

  /// La cle du champ du code.
  static const Key champCodeKey = ValueKey<String>('mfa-code');

  /// La cle du bouton principal.
  static const Key boutonKey = ValueKey<String>('mfa-valider');

  /// La cle du lien « je n'ai pas d'application ».
  static const Key sansApplicationKey = ValueKey<String>('mfa-sans-appli');

  @override
  ConsumerState<MfaControleurPage> createState() => _MfaControleurPageState();
}

class _MfaControleurPageState extends ConsumerState<MfaControleurPage> {
  final TextEditingController _code = TextEditingController();
  EtapeMfa _etape = EtapeMfa.chargement;
  EnrolementTotp? _enrolement;
  String? _facteurId;
  String? _erreurChamp;
  String? _erreurEnvoi;
  bool _envoi = false;

  @override
  void initState() {
    super.initState();
    unawaited(_charger());
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() {
      _etape = EtapeMfa.chargement;
      _erreurChamp = null;
      _erreurEnvoi = null;
    });
    final PortMfa port = ref.read(portMfaProvider);
    try {
      final SituationMfa situation = await port.situation();
      switch (situation) {
        case MfaAVerifier(:final String facteurId):
          if (mounted) {
            setState(() {
              _facteurId = facteurId;
              _enrolement = null;
              _etape = EtapeMfa.verification;
            });
          }
        case MfaAEnroler():
          final EnrolementTotp enrolement = await port.enroler();
          if (mounted) {
            setState(() {
              _facteurId = enrolement.facteurId;
              _enrolement = enrolement;
              _etape = EtapeMfa.enrolement;
            });
          }
      }
    } on MfaHorsLigne {
      if (mounted) {
        setState(() => _etape = EtapeMfa.horsLigne);
      }
    } on Object {
      if (mounted) {
        setState(() => _etape = EtapeMfa.erreur);
      }
    }
  }

  Future<void> _valider() async {
    final String? facteur = _facteurId;
    if (_envoi || facteur == null) {
      return;
    }
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
    try {
      await ref.read(portMfaProvider).verifier(facteurId: facteur, code: code);
      // Aucune navigation ici : le jeton passe a `aal2`, la session se met a
      // jour et le routeur libere le compte.
    } on MfaCodeRefuse {
      if (mounted) {
        setState(() => _erreurChamp = t.controleur.mfa.codeRefuse);
      }
    } on MfaHorsLigne {
      if (mounted) {
        setState(
          () =>
              _erreurEnvoi = EtatSysteme.textesPar(NatureEtat.horsLigne).phrase,
        );
      }
    } on Object {
      if (mounted) {
        setState(
          () =>
              _erreurEnvoi = EtatSysteme.textesPar(NatureEtat.echecServeur)
                  .phrase,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _envoi = false);
      }
    }
  }

  void _seDeconnecter() => unawaited(ref.read(deconnexionProvider).executer());

  @override
  Widget build(BuildContext context) {
    final Widget respiration = AppGabarit.de(context) == Gabarit.mobile
        ? Ecart.vXxl
        : Ecart.vSection;

    return PageShell(
      defilante: false,
      actionsCoquille: false,
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
                        key: ValueKey<String>('mfa-${_etape.name}'),
                        dominante: true,
                        child: _corps(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _corps() => switch (_etape) {
    EtapeMfa.chargement => _Chargement(),
    EtapeMfa.enrolement || EtapeMfa.verification => _Saisie(
      enrolement: _etape == EtapeMfa.enrolement ? _enrolement : null,
      code: _code,
      erreurChamp: _erreurChamp,
      erreurEnvoi: _erreurEnvoi,
      envoi: _envoi,
      onValider: () => unawaited(_valider()),
      onSansApplication: () => setState(() => _etape = EtapeMfa.vide),
      onSeDeconnecter: _seDeconnecter,
    ),
    EtapeMfa.vide => EtatSysteme(
      nature: NatureEtat.aucunResultat,
      titre: t.controleur.mfa.videTitre,
      phrase: t.controleur.mfa.videPhrase,
      libelleAction: t.controleur.mfa.videRetour,
      onAction: () => unawaited(_charger()),
      libelleSecondaire: t.controleur.mfa.seDeconnecter,
      onSecondaire: _seDeconnecter,
    ),
    EtapeMfa.erreur => EtatSysteme(
      nature: NatureEtat.echecServeur,
      onAction: () => unawaited(_charger()),
      libelleSecondaire: t.controleur.mfa.seDeconnecter,
      onSecondaire: _seDeconnecter,
    ),
    EtapeMfa.horsLigne => EtatSysteme(
      nature: NatureEtat.horsLigne,
      onAction: () => unawaited(_charger()),
      libelleSecondaire: t.controleur.mfa.seDeconnecter,
      onSecondaire: _seDeconnecter,
    ),
  };
}

class _Chargement extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: t.controleur.mfa.chargement,
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[Skeleton(hauteur: 28), Ecart.vLg, Skeleton.texte()],
    ),
  );
}

class _Saisie extends StatelessWidget {
  const _Saisie({
    required this.enrolement,
    required this.code,
    required this.erreurChamp,
    required this.erreurEnvoi,
    required this.envoi,
    required this.onValider,
    required this.onSansApplication,
    required this.onSeDeconnecter,
  });

  /// Nul : verification d'un facteur deja enrole.
  final EnrolementTotp? enrolement;
  final TextEditingController code;
  final String? erreurChamp;
  final String? erreurEnvoi;
  final bool envoi;
  final VoidCallback onValider;
  final VoidCallback onSansApplication;
  final VoidCallback onSeDeconnecter;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle discret = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final bool enrole = enrolement != null;
    final mfa = t.controleur.mfa;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TexteSansCoupure(
          enrole ? mfa.titreEnrolement : mfa.titreVerification,
          style: textes.headlineMedium,
        ),
        Ecart.vMd,
        Text(
          enrole ? mfa.introEnrolement : mfa.introVerification,
          style: discret,
        ),
        if (enrolement != null) ...<Widget>[
          Ecart.vXl,
          Text(mfa.etapeScanner, style: textes.labelLarge),
          Ecart.vMd,
          Center(child: _Qr(donnees: enrolement!.uri)),
          Ecart.vMd,
          Text(mfa.cleManuelle, style: discret),
          Ecart.vSm,
          SelectableText(
            enrolement!.secret,
            key: const ValueKey<String>('mfa-cle'),
            textDirection: TextDirection.ltr,
            style: textes.bodyLarge,
          ),
          Ecart.vXl,
          Text(mfa.etapeCode, style: textes.labelLarge),
          Ecart.vSm,
        ] else
          Ecart.vXl,
        Text(mfa.champCode, style: textes.labelLarge),
        Ecart.vSm,
        TextField(
          key: MfaControleurPage.champCodeKey,
          controller: code,
          onSubmitted: (String _) => onValider(),
          keyboardType: TextInputType.number,
          textDirection: TextDirection.ltr,
          autofillHints: const <String>[AutofillHints.oneTimeCode],
          textInputAction: TextInputAction.go,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: InputDecoration(errorText: erreurChamp),
        ),
        if (erreurEnvoi != null) ...<Widget>[
          Ecart.vMd,
          Semantics(
            liveRegion: true,
            child: Text(
              erreurEnvoi!,
              key: const ValueKey<String>('mfa-erreur'),
              style: textes.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
        Ecart.vXl,
        ActionPrincipale(
          key: MfaControleurPage.boutonKey,
          libelle: enrole ? mfa.activer : mfa.confirmer,
          onPress: onValider,
          enCours: envoi,
        ),
        if (enrole) ...<Widget>[
          Ecart.vLg,
          Align(
            child: ActionPrincipale(
              key: MfaControleurPage.sansApplicationKey,
              libelle: mfa.sansApplication,
              onPress: onSansApplication,
              niveau: NiveauAction.tertiaire,
              pleineLargeur: false,
            ),
          ),
        ],
        Ecart.vSm,
        Align(
          child: ActionPrincipale(
            libelle: mfa.seDeconnecter,
            onPress: onSeDeconnecter,
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
          ),
        ),
      ],
    );
  }
}

/// Le QR de l'enrolement : noir sur blanc dans les deux themes (la paire
/// `contenuQr`), comme celui de l'appairage. Il porte l'adresse `otpauth://`
/// du facteur et rien d'autre.
class _Qr extends StatelessWidget {
  const _Qr({required this.donnees});

  final String donnees;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final couleurs = palette.contenuQr;
    return Semantics(
      image: true,
      label: t.controleur.mfa.libelleQr,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: _coteQr,
          child: DecoratedBox(
            decoration: couleurs.decoration(
              borderRadius: AppRadius.arrondiSm,
              side: palette.borderHairline.asBorderSide(),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: QrImageView(
                data: donnees,
                padding: EdgeInsets.zero,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
                backgroundColor: couleurs.background,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: couleurs.onBackground,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: couleurs.onBackground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
