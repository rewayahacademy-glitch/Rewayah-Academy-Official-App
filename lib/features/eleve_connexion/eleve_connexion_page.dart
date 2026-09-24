import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/appairage/code_local.dart';
import '../../core/appairage/profils_locaux.dart';
import '../../core/appairage/service_enfant.dart';
import '../../core/cache/secure/stockage_securise.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/marque_page.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pin_pad.dart';
import '../../core/widgets/pressable.dart';

/// Les moments successifs de `ELV-01`.
enum _Moment {
  /// On regarde ce que cet appareil connait deja.
  chargement,

  /// Aucun profil : il faut un code. La saisie vit sur sa propre route
  /// (`/connexion/eleve/code`, une fonction a un seul endroit) : l'ecran y
  /// renvoie.
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
/// (`docs/archive/2026-09-pre-remise-a-plat/produit/parcours-utilisateurs.md`).
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
  _Moment _moment = _Moment.chargement;
  List<ProfilLocal> _profils = const <ProfilLocal>[];
  ProfilLocal? _choisi;
  String? _premierEssai;
  bool _erreurCode = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    unawaited(_charger());
  }

  /// Le profil que la saisie ou le scanner vient de connecter, passe en
  /// `extra` (jamais dans l'adresse). Absent hors de ce parcours.
  ProfilLocal? _profilQuiArrive() {
    try {
      final Object? extra = GoRouterState.of(context).extra;
      return extra is ProfilLocal ? extra : null;
    } on Object {
      return null;
    }
  }

  /// Sans profil, la saisie du code est sur sa propre route.
  void _versSaisie() {
    final GoRouter? routeur = GoRouter.maybeOf(context);
    if (routeur != null) {
      routeur.go(Routes.connexionEleveCode);
    }
  }

  /// Ce que cet appareil connait deja, quand il sait le dire.
  ///
  /// **Un echec ici ne bloque pas l'entree.** La base locale s'ouvre sur un
  /// moteur propre a la plateforme, et sur le web il lui faut deux fichiers
  /// servis a la racine (`sqlite3.wasm` et `drift_worker.js`). Quand ils
  /// manquaient, l'ouverture echouait, cette methode n'avait pas de `catch`, et
  /// comme elle est lancee en `unawaited` l'echec partait dans le vide :
  /// `setState` n'etait jamais appele et l'ecran restait indefiniment sur son
  /// indicateur de chargement. L'operateur voyait un ecran qui ne chargeait
  /// jamais, sans un message, sans une erreur.
  ///
  /// La memoire des profils est un **confort**, pas une condition d'entree :
  /// sans elle, on demande un code, ce qui est exactement l'etat d'un appareil
  /// qui n'a jamais ete appaire. C'est le pire cas acceptable ; un chargement
  /// sans fin ne l'est pas.
  Future<void> _charger() async {
    List<ProfilLocal> profils = const <ProfilLocal>[];
    try {
      profils = await ref.read(profilsLocauxProvider).lister();
    } on Object {
      profils = const <ProfilLocal>[];
    }
    if (!mounted) {
      return;
    }

    // Arrivee depuis la saisie ou le scanner (`connecterCetAppareil`) : le
    // jeton est deja range, on passe droit au code personnel de ce profil,
    // meme si la base locale n'a pas pu le retenir.
    final ProfilLocal? arrive = _profilQuiArrive();
    if (arrive != null) {
      if (!profils.any((ProfilLocal p) => p.id == arrive.id)) {
        profils = <ProfilLocal>[...profils, arrive];
      }
      setState(() => _profils = profils);
      await _choisirProfil(arrive);
      return;
    }

    setState(() {
      _profils = profils;
      _moment = profils.isEmpty ? _Moment.saisieCode : _Moment.choixProfil;
    });
    if (profils.isEmpty) {
      _versSaisie();
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
        if (_profils.isEmpty) {
          _versSaisie();
        }
      }
      return;
    }

    setState(() => _erreurCode = false);
    try {
      await ref.read(serviceEnfantProvider).ouvrirSession(jeton);
    } on Object {
      if (mounted) {
        setState(() => _message = t.eleveConnexion.codeExpire);
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
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: AppCard(
                child: switch (_moment) {
                  _Moment.chargement => Center(child: Text(t.commun.chargement)),
                  // Le temps que la route de saisie prenne le relais.
                  _Moment.saisieCode => Center(child: Text(t.commun.chargement)),
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
          ),
        ],
      ),
    );
  }

  Widget _choixProfil() {
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
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
