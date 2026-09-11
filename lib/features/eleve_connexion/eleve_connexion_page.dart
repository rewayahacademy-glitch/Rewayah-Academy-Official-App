import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/appairage/code_local.dart';
import '../../core/appairage/profils_locaux.dart';
import '../../core/appairage/service_enfant.dart';
import '../../core/cache/secure/stockage_securise.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/offline_banner.dart';
import '../../core/widgets/pin_pad.dart';
import '../../core/widgets/pressable.dart';

/// Les moments successifs de `ELV-01`.
enum _Moment {
  /// On regarde ce que cet appareil connait deja.
  chargement,

  /// Aucun profil : il faut un code.
  saisieCode,

  /// Des profils existent : l'enfant choisit le sien.
  choixProfil,

  /// Premier usage d'un profil sur cet appareil : il choisit son code.
  creationCode,

  /// Le profil a deja un code : il le saisit.
  saisieCodePersonnel,
}

/// `ELV-01` : la connexion de l'eleve.
///
/// **Sur un appareil deja appaire, l'ecran de code ne reapparait jamais** :
/// l'enfant voit directement le choix de profil
/// (`docs/produit/parcours-utilisateurs.md`).
///
/// Le code personnel se cree ici, sur l'appareil, juste apres l'appairage, en
/// presence du tuteur qui vient de montrer le code. **Il n'est jamais transmis**
/// (ADR-005) : il n'existe aucun champ en base pour le recevoir, et
/// `test/appairage/code_local_test.dart` relit cette source pour le verifier.
class EleveConnexionPage extends ConsumerStatefulWidget {
  /// Cree l'ecran de connexion de l'eleve.
  const EleveConnexionPage({super.key});

  @override
  ConsumerState<EleveConnexionPage> createState() => _EleveConnexionPageState();
}

class _EleveConnexionPageState extends ConsumerState<EleveConnexionPage> {
  final TextEditingController _code = TextEditingController();

  _Moment _moment = _Moment.chargement;
  List<ProfilLocal> _profils = const <ProfilLocal>[];
  ProfilLocal? _choisi;
  String? _premierEssai;
  bool _enCours = false;
  bool _erreurCode = false;
  String? _message;

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
    final List<ProfilLocal> profils = await ref
        .read(profilsLocauxProvider)
        .lister();
    if (!mounted) {
      return;
    }
    setState(() {
      _profils = profils;
      _moment = profils.isEmpty ? _Moment.saisieCode : _Moment.choixProfil;
    });
  }

  Future<void> _appairer() async {
    setState(() {
      _enCours = true;
      _message = null;
    });
    try {
      final StockageSecurise coffre = ref.read(stockageSecuriseProvider);
      final AppairageReussi resultat = await ref
          .read(serviceEnfantProvider)
          .appairer(
            code: _code.text.trim().toUpperCase(),
            empreinteAppareil: await coffre.empreinteAppareil(),
            plateforme: _plateforme(),
          );

      // Le jeton n'est rendu qu'une fois : il est ecrit avant toute autre
      // chose, sinon l'appairage serait a refaire.
      await coffre.enregistrerJetonAppareil(
        resultat.profilId,
        resultat.jetonAppareil,
      );
      final ProfilLocal profil = ProfilLocal(
        id: resultat.profilId,
        prenom: resultat.prenom,
        identifiantImmuable: '',
      );
      await ref.read(profilsLocauxProvider).enregistrer(profil);

      if (mounted) {
        setState(() {
          _profils = <ProfilLocal>[..._profils, profil];
          _choisi = profil;
          _code.clear();
          _moment = _Moment.creationCode;
        });
      }
    } on Object {
      if (mounted) {
        setState(() => _message = t.eleveConnexion.codeErreur);
      }
    } finally {
      if (mounted) {
        setState(() => _enCours = false);
      }
    }
  }

  Future<void> _choisirProfil(ProfilLocal profil) async {
    final String? empreinte = await ref
        .read(stockageSecuriseProvider)
        .empreintePin(profil.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _choisi = profil;
      _erreurCode = false;
      _premierEssai = null;
      _moment = empreinte == null
          ? _Moment.creationCode
          : _Moment.saisieCodePersonnel;
    });
  }

  Future<void> _creerCode(String saisie) async {
    final ProfilLocal? profil = _choisi;
    if (profil == null) {
      return;
    }
    if (_premierEssai == null) {
      setState(() {
        _premierEssai = saisie;
        _erreurCode = false;
      });
      return;
    }
    if (_premierEssai != saisie) {
      setState(() {
        _premierEssai = null;
        _erreurCode = true;
        _message = t.eleveConnexion.codeDifferent;
      });
      return;
    }

    // `sceller` produit un sel et une empreinte : le code lui-meme n'est ecrit
    // nulle part, pas meme dans le coffre.
    await ref
        .read(stockageSecuriseProvider)
        .enregistrerEmpreintePin(profil.id, CodeLocal.sceller(saisie));
    if (mounted) {
      setState(() {
        _premierEssai = null;
        _message = null;
        _moment = _Moment.saisieCodePersonnel;
      });
    }
  }

  Future<void> _verifierCode(String saisie) async {
    final ProfilLocal? profil = _choisi;
    if (profil == null) {
      return;
    }
    final StockageSecurise coffre = ref.read(stockageSecuriseProvider);
    final String? scelle = await coffre.empreintePin(profil.id);

    // La comparaison est LOCALE : aucun appel reseau ne recoit la saisie.
    if (!CodeLocal.correspond(saisie, scelle)) {
      if (mounted) {
        setState(() => _erreurCode = true);
      }
      return;
    }

    final String? jeton = await coffre.jetonAppareil(profil.id);
    if (jeton == null) {
      // Le tuteur a revoque cet appareil : le profil reste affiche tant qu'on
      // ne le sait pas, il disparait des qu'on l'apprend.
      await ref.read(profilsLocauxProvider).oublier(profil.id);
      if (mounted) {
        setState(() {
          _profils = _profils
              .where((ProfilLocal p) => p.id != profil.id)
              .toList();
          _moment = _profils.isEmpty ? _Moment.saisieCode : _Moment.choixProfil;
          _message = t.eleveConnexion.codeExpire;
        });
      }
      return;
    }

    setState(() {
      _enCours = true;
      _erreurCode = false;
    });
    try {
      await ref.read(serviceEnfantProvider).ouvrirSession(jeton);
    } on Object {
      if (mounted) {
        setState(() => _message = t.eleveConnexion.codeExpire);
      }
    } finally {
      if (mounted) {
        setState(() => _enCours = false);
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
                child: switch (_moment) {
                  _Moment.chargement => Center(
                    child: Text(t.commun.chargement),
                  ),
                  _Moment.saisieCode => _saisieCode(),
                  _Moment.choixProfil => _choixProfil(),
                  _Moment.creationCode => _pave(
                    titre: _premierEssai == null
                        ? t.eleveConnexion.nouveauCode
                        : t.eleveConnexion.nouveauCodeConfirmer,
                    onComplet: (String code) => unawaited(_creerCode(code)),
                  ),
                  _Moment.saisieCodePersonnel => _pave(
                    titre: t.pin.titre,
                    onComplet: (String code) => unawaited(_verifierCode(code)),
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _saisieCode() {
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Ecart.vXxl,
        Text(t.eleveConnexion.entrerCode, style: textes.headlineSmall),
        Ecart.vMd,
        Text(t.eleveConnexion.codeInvite, style: textes.bodyLarge),
        Ecart.vXxl,
        TextField(
          controller: _code,
          onChanged: (String _) => setState(() {}),
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: textes.headlineMedium,
          inputFormatters: <TextInputFormatter>[
            const UpperCaseTextFormatter(),
            FilteringTextInputFormatter.allow(RegExp('[A-Z2-9]')),
          ],
          decoration: InputDecoration(errorText: _message),
        ),
        Ecart.vXl,
        ActionPrincipale(
          libelle: t.commun.valider,
          enCours: _enCours,
          onPress: _code.text.trim().length == 6
              ? () => unawaited(_appairer())
              : null,
        ),
        // Le bloc « scanner le carre » n'apparait pas : aucun lecteur de code
        // n'est disponible sur cette version. Un bouton qui echoue apres le
        // geste coute plus cher qu'un bouton absent, exactement comme le bouton
        // d'ajout d'appareil de TUT-02.
      ],
    );
  }

  Widget _choixProfil() {
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Ecart.vXxl,
        Text(
          t.eleveConnexion.choisirProfil,
          textAlign: TextAlign.center,
          style: textes.headlineSmall,
        ),
        Ecart.vXxxl,
        // Composition volontairement asymetrique, en leger decalage d'une tuile
        // a l'autre : l'ecran doit ressembler a une invitation, pas a un menu
        // de reglages.
        for (int i = 0; i < _profils.length; i++)
          Padding(
            padding: EdgeInsetsDirectional.only(
              bottom: AppSpacing.xxl,
              start: i.isEven ? 0 : AppSpacing.xxxl,
              end: i.isEven ? AppSpacing.xxxl : 0,
            ),
            child: _TuileProfil(
              profil: _profils[i],
              onPress: () => unawaited(_choisirProfil(_profils[i])),
            ),
          ),
        if (_message != null)
          Text(
            _message!,
            textAlign: TextAlign.center,
            style: AppPalette.of(context).inkAlert
                .applyTo(textes.bodyMedium ?? const TextStyle()),
          ),
      ],
    );
  }

  Widget _pave({
    required String titre,
    required void Function(String code) onComplet,
  }) {
    return Column(
      children: <Widget>[
        Ecart.vXl,
        Text(titre, style: Theme.of(context).textTheme.titleLarge),
        Ecart.vXl,
        PinPad(
          onCodeComplet: onComplet,
          enErreur: _erreurCode,
          longueur: CodeLocal.longueur,
        ),
      ],
    );
  }
}

/// La tuile d'un profil : une photo, un prenom, une grande cible.
class _TuileProfil extends StatelessWidget {
  const _TuileProfil({required this.profil, required this.onPress});

  final ProfilLocal profil;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppMetriques metriques = AppMetriques.of(context);

    return Pressable(
      onPress: onPress,
      libelleSemantique: profil.prenom,
      respecterCibleTactile: false,
      child: Column(
        children: <Widget>[
          AvatarTile(
            prenom: profil.prenom,
            diametre: metriques.cibleTactile * 2,
          ),
          Ecart.vMd,
          Text(profil.prenom, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

/// Met la saisie en majuscules : le code est affiche en majuscules chez le
/// tuteur, et la base le compare en majuscules.
class UpperCaseTextFormatter extends TextInputFormatter {
  /// Cree le formateur.
  const UpperCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue _,
    TextEditingValue apres,
  ) => TextEditingValue(
    text: apres.text.toUpperCase(),
    selection: apres.selection,
  );
}

String _plateforme() {
  if (kIsWeb) {
    return 'web';
  }
  if (Platform.isAndroid) {
    return 'android';
  }
  if (Platform.isIOS) {
    return 'ios';
  }
  return 'windows';
}
