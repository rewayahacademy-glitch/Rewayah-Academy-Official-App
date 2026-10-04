import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../core/appairage/service_appairage.dart';
import '../../core/appairage/statut_code_appairage.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/chemin_retour.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/ecran_resultat.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import 'emetteur_qr.dart';

/// L'horloge de l'emetteur, injectable pour les tests (expiration, compte a
/// rebours) sans attendre dix minutes reelles.
final Provider<DateTime Function()> horlogeEmetteurProvider =
    Provider<DateTime Function()>((Ref ref) => DateTime.now);

/// Les etapes de l'ecran emetteur (mandat section 7, C05 section 4).
///
/// « Validation » designe ici la **verification** que fait cet ecran avant de
/// reafficher un code (retour d'arriere-plan, retour du reseau) : le serveur
/// ne signale jamais qu'un appareil est en train de saisir le code, et cet
/// ecran ne le simule pas.
enum EtapeEmetteur {
  /// Le code est demande ; aucun faux QR n'est montre.
  preparation,

  /// Un code vivant existe deja pour l'eleve, mais il ne peut pas etre
  /// reaffiche (la base n'en garde que l'empreinte).
  dejaActif,

  /// QR et code affiches, validite qui s'ecoule.
  actif,

  /// Code masque le temps de reverifier son statut.
  verification,

  /// Un appareil a consomme le code : QR et code retires.
  confirme,

  /// Delai passe.
  expire,

  /// Perime par une nouvelle demande.
  remplace,

  /// La demande a echoue.
  erreur,

  /// Plus de reseau : code masque jusqu'a son retour.
  horsLigne,
}

/// Pourquoi la demande de code a echoue, lu dans le message du serveur.
///
/// Le serveur ne rend pas de code d'erreur stable (DB-APP-06) : la
/// correspondance se fait sur les textes connus de `creer_code_appairage`
/// (`0004_inscription_kyc_appairage.sql`, section 13). Un texte inconnu donne
/// le message general ; le texte brut n'est jamais affiche.
enum MotifErreurEmetteur {
  /// `plafond d'appareils atteint`.
  plafond,

  /// `cet eleve n'appartient pas a votre foyer`.
  horsFoyer,

  /// `seul un tuteur au compte valide appaire un appareil`.
  compte,

  /// Tout le reste.
  generique;

  /// Le motif d'une erreur levee par `creerCode`.
  static MotifErreurEmetteur depuis(Object erreur) {
    final String texte =
        (erreur is PostgrestException ? erreur.message : erreur.toString())
            .toLowerCase();
    if (texte.contains('plafond')) {
      return plafond;
    }
    if (texte.contains('foyer')) {
      return horsFoyer;
    }
    if (texte.contains('compte valide') || texte.contains('seul un tuteur')) {
      return compte;
    }
    return generique;
  }
}

/// L'emetteur QR : le telephone du tuteur AFFICHE le code, l'appareil de
/// l'eleve le LIT ou le saisit (C05 section 1).
///
/// Le code n'existe qu'ici : la base n'en garde que l'empreinte et aucune
/// requete ne peut le relire. D'ou trois regles :
///
/// - a l'entree, si un code est deja valable pour l'eleve, l'ecran le dit au
///   lieu d'en creer un nouveau en silence (qui perimerait l'ancien) ;
/// - des qu'un appareil l'a consomme, le QR et le code quittent l'etat, l'ecran
///   et l'arbre semantique, puis « Appareil connecte » ;
/// - quitter l'ecran ne l'annule pas (aucune RPC d'annulation, DB-APP-01) :
///   l'heure de fin est dite, sans promesse.
class AppairagePage extends ConsumerStatefulWidget {
  /// Cree l'ecran d'appairage pour un eleve.
  const AppairagePage({required this.eleveId, super.key});

  /// L'eleve dont on connecte un appareil.
  final String eleveId;

  /// Intervalle de scrutation du statut du code : court et borne par
  /// l'expiration (pas de temps reel sur une vue).
  static const Duration intervalleScrutation = Duration(seconds: 3);

  @override
  ConsumerState<AppairagePage> createState() => _AppairagePageState();
}

class _AppairagePageState extends ConsumerState<AppairagePage>
    with WidgetsBindingObserver {
  EtapeEmetteur _etape = EtapeEmetteur.preparation;
  MotifErreurEmetteur _motif = MotifErreurEmetteur.generique;
  CodeAppairage? _code;
  DateTime? _expireA;
  bool _suiviIndisponible = false;
  bool _enCours = false;
  bool _verificationEnVol = false;
  bool _horsLigne = false;
  bool _enArrierePlan = false;
  int _generation = 0;
  late DateTime _maintenant;
  Timer? _horloge;
  Timer? _scrutation;
  ProviderSubscription<AsyncValue<bool>>? _abonnementReseau;

  DateTime _lireHorloge() => ref.read(horlogeEmetteurProvider)();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _maintenant = _lireHorloge();
    _horloge = Timer.periodic(const Duration(seconds: 1), (Timer _) => _tic());
    _abonnementReseau = ref.listenManual<AsyncValue<bool>>(
      horsLigneProvider,
      (AsyncValue<bool>? _, AsyncValue<bool> suivant) =>
          _surReseau(suivant.hasValue && suivant.requireValue),
      fireImmediately: true,
    );
    unawaited(_demarrer());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _horloge?.cancel();
    _scrutation?.cancel();
    _abonnementReseau?.close();
    // Le code quitte la memoire avec l'ecran.
    _code = null;
    super.dispose();
  }

  void _poser(VoidCallback changement) {
    if (mounted) {
      setState(changement);
    }
  }

  /// Entree : un code deja valable ne se recree pas en silence.
  Future<void> _demarrer() async {
    final int generation = ++_generation;
    _poser(() => _etape = EtapeEmetteur.preparation);
    CodeVivant? vivant;
    try {
      vivant = await ref
          .read(portStatutCodeAppairageProvider)
          .codeVivant(widget.eleveId);
    } on CapaciteIndisponible {
      // DB-APP-02 : impossible de savoir. On demande un code, et l'ecran dira
      // qu'il ne peut pas confirmer la connexion.
      _suiviIndisponible = true;
    } on Object {
      // Lecture en echec (serveur, delai, reseau) : impossible de savoir si un
      // code est deja valable. En creer un en silence perimerait celui qui est
      // peut-etre en train d'etre saisi sur l'autre appareil : l'ecran le dit
      // et propose de reessayer la lecture (« Reessayer » relance `_demarrer`).
      if (!mounted || generation != _generation) {
        return;
      }
      _poser(() {
        if (_horsLigne) {
          _etape = EtapeEmetteur.horsLigne;
        } else {
          _motif = MotifErreurEmetteur.generique;
          _etape = EtapeEmetteur.erreur;
        }
      });
      return;
    }
    if (!mounted || generation != _generation) {
      return;
    }
    if (vivant != null) {
      final CodeVivant dejaLa = vivant;
      _poser(() {
        _expireA = dejaLa.expireA;
        _etape = EtapeEmetteur.dejaActif;
      });
      return;
    }
    await _creer();
  }

  /// Demande un nouveau code (et perime le precedent, en base).
  Future<void> _creer() async {
    if (_enCours) {
      return;
    }
    final int generation = ++_generation;
    _scrutation?.cancel();
    _poser(() {
      _enCours = true;
      _code = null;
      _etape = EtapeEmetteur.preparation;
    });
    try {
      final CodeAppairage code = await ref
          .read(serviceAppairageProvider)
          .creerCode(widget.eleveId);
      if (!mounted || generation != _generation) {
        return;
      }
      _poser(() {
        _code = code;
        _expireA = code.expireA;
        _maintenant = _lireHorloge();
        _etape = _horsLigne
            ? EtapeEmetteur.horsLigne
            : code.restantA(_maintenant) == Duration.zero
            ? EtapeEmetteur.expire
            : EtapeEmetteur.actif;
        if (_etape == EtapeEmetteur.expire) {
          _code = null;
        }
      });
      _lancerScrutation();
    } on Object catch (erreur) {
      if (!mounted || generation != _generation) {
        return;
      }
      _poser(() {
        if (_horsLigne) {
          _etape = EtapeEmetteur.horsLigne;
        } else {
          _motif = MotifErreurEmetteur.depuis(erreur);
          _etape = EtapeEmetteur.erreur;
        }
      });
    } finally {
      _poser(() => _enCours = false);
    }
  }

  void _lancerScrutation() {
    _scrutation?.cancel();
    if (_suiviIndisponible || _code == null) {
      return;
    }
    _scrutation = Timer.periodic(
      AppairagePage.intervalleScrutation,
      (Timer _) => unawaited(_verifier()),
    );
  }

  void _tic() {
    if (!mounted) {
      return;
    }
    final DateTime maintenant = _lireHorloge();
    final CodeAppairage? code = _code;
    setState(() {
      _maintenant = maintenant;
      if (code != null && code.restantA(maintenant) == Duration.zero) {
        _expirer();
      }
    });
  }

  void _expirer() {
    _scrutation?.cancel();
    _code = null;
    _etape = EtapeEmetteur.expire;
  }

  /// Relit le statut du code. [masquer] retire le code de l'ecran pendant la
  /// lecture (retour d'arriere-plan, retour du reseau).
  Future<void> _verifier({bool masquer = false}) async {
    final CodeAppairage? code = _code;
    if (code == null || _verificationEnVol) {
      return;
    }
    if (_suiviIndisponible) {
      // Rien a relire : seule l'horloge decide.
      _poser(() {
        _maintenant = _lireHorloge();
        if (code.restantA(_maintenant) == Duration.zero) {
          _expirer();
        } else {
          _etape = EtapeEmetteur.actif;
        }
      });
      return;
    }
    final int generation = _generation;
    _verificationEnVol = true;
    if (masquer) {
      _poser(() => _etape = EtapeEmetteur.verification);
    }
    try {
      final StatutCode statut = await ref
          .read(portStatutCodeAppairageProvider)
          .statut(
            eleveId: widget.eleveId,
            expireA: code.expireA,
            maintenant: _lireHorloge(),
          );
      if (!mounted || generation != _generation || _code == null) {
        return;
      }
      _poser(() {
        switch (statut) {
          case StatutCode.actif:
            _etape = _horsLigne
                ? EtapeEmetteur.horsLigne
                : _enArrierePlan
                ? EtapeEmetteur.verification
                : EtapeEmetteur.actif;
          case StatutCode.consomme:
            _confirmer();
          case StatutCode.remplace:
            _scrutation?.cancel();
            _code = null;
            _etape = EtapeEmetteur.remplace;
          case StatutCode.expire:
            _expirer();
        }
      });
    } on CapaciteIndisponible {
      _scrutation?.cancel();
      _poser(() {
        _suiviIndisponible = true;
        if (_etape == EtapeEmetteur.verification) {
          _etape = EtapeEmetteur.actif;
        }
      });
    } on Object {
      // Panne passagere : le code reste valable, la scrutation reessaie.
      _poser(() {
        if (_etape == EtapeEmetteur.verification) {
          _etape = _horsLigne ? EtapeEmetteur.horsLigne : EtapeEmetteur.actif;
        }
      });
    } finally {
      _verificationEnVol = false;
    }
  }

  void _confirmer() {
    _scrutation?.cancel();
    _code = null;
    _etape = EtapeEmetteur.confirme;
    ref.invalidate(appareilsDuFoyerProvider);
  }

  void _surReseau(bool horsLigne) {
    final bool retour = _horsLigne && !horsLigne;
    _horsLigne = horsLigne;
    if (horsLigne) {
      if (_etape == EtapeEmetteur.actif ||
          _etape == EtapeEmetteur.verification) {
        _poser(() => _etape = EtapeEmetteur.horsLigne);
      }
      return;
    }
    if (retour && _etape == EtapeEmetteur.horsLigne) {
      if (_code != null) {
        unawaited(_verifier(masquer: true));
      } else {
        unawaited(_demarrer());
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState etat) {
    switch (etat) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // Rien ne reste a l'ecran d'un appareil en arriere-plan (apercu des
        // applications recentes compris), et rien ne le reaffiche avant la
        // reprise.
        if (_code != null &&
            (_etape == EtapeEmetteur.actif ||
                _etape == EtapeEmetteur.verification)) {
          _enArrierePlan = true;
          _scrutation?.cancel();
          _poser(() => _etape = EtapeEmetteur.verification);
        }
      case AppLifecycleState.resumed:
        if (_enArrierePlan) {
          _enArrierePlan = false;
          unawaited(_reprendre());
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  /// Retour de l'arriere-plan : le code n'est reaffiche qu'apres relecture de
  /// son statut, puis la scrutation reprend.
  Future<void> _reprendre() async {
    if (_code == null) {
      return;
    }
    await _verifier(masquer: true);
    if (mounted && _code != null) {
      _lancerScrutation();
    }
  }

  String _cheminRetour() {
    String? demande;
    try {
      demande = GoRouterState.of(context).uri.queryParameters['retour'];
    } on GoError {
      demande = null;
    }
    return cheminRetourValide(demande) ?? Routes.tuteurFoyerAppareils;
  }

  void _retour() => GoRouter.of(context).go(_cheminRetour());

  @override
  Widget build(BuildContext context) {
    final String? prenom = ref
        .watch(elevesDuFoyerProvider)
        .value
        ?.where((EleveDuFoyer e) => e.id == widget.eleveId)
        .firstOrNull
        ?.prenom;

    return PageShell(
      titre: t.appareils.emetteur.titre,
      sousTitre: prenom == null || prenom.isEmpty
          ? null
          : t.appareils.emetteur.pourEleve(prenom: prenom),
      onRetour: _retour,
      child: _Apparition(
        key: ValueKey<EtapeEmetteur>(_etape),
        child: _corps(prenom),
      ),
    );
  }

  Widget _corps(String? prenom) {
    final String heure = _heure(_expireA);
    switch (_etape) {
      case EtapeEmetteur.preparation:
        return const _Preparation();
      case EtapeEmetteur.actif:
        final CodeAppairage? code = _code;
        if (code == null) {
          return const _Preparation();
        }
        return _VueActive(
          code: code.code,
          heure: _heure(code.expireA),
          restant: _mmss(code.restantA(_maintenant)),
          suiviIndisponible: _suiviIndisponible,
        );
      case EtapeEmetteur.verification:
        return _Resultat(
          icone: AppIcons.attente,
          titre: t.appareils.emetteur.verification.titre,
          phrase: t.appareils.emetteur.verification.phrase,
        );
      case EtapeEmetteur.confirme:
        return _Resultat(
          icone: AppIcons.succes,
          ton: TonEtat.succes,
          titre: t.appareils.emetteur.confirme.titre,
          phrase: prenom == null || prenom.isEmpty
              ? t.appareils.emetteur.confirme.phraseSansPrenom
              : t.appareils.emetteur.confirme.phrase(prenom: prenom),
          libelleAction: t.appareils.emetteur.confirme.action,
          onAction: _retour,
        );
      case EtapeEmetteur.expire:
        return _Resultat(
          icone: AppIcons.attente,
          ton: TonEtat.avertissement,
          titre: t.appareils.emetteur.expire.titre,
          phrase: t.appareils.emetteur.expire.phrase,
          libelleAction: t.appareils.regenerer,
          onAction: () => unawaited(_creer()),
          enCours: _enCours,
        );
      case EtapeEmetteur.remplace:
        return _Resultat(
          icone: AppIcons.reconnexion,
          ton: TonEtat.neutre,
          titre: t.appareils.emetteur.remplace.titre,
          phrase: t.appareils.emetteur.remplace.phrase,
          libelleAction: t.appareils.regenerer,
          onAction: () => unawaited(_creer()),
          enCours: _enCours,
        );
      case EtapeEmetteur.dejaActif:
        return _Resultat(
          icone: AppIcons.qr,
          titre: t.appareils.emetteur.dejaActif.titre,
          phrase: t.appareils.emetteur.dejaActif.phrase(heure: heure),
          libelleAction: t.appareils.regenerer,
          onAction: () => unawaited(_creer()),
          enCours: _enCours,
        );
      case EtapeEmetteur.horsLigne:
        // Hors ligne se dit une fois (EA-HL-DOUBLE-1) : le bandeau de
        // `PageShell` le dit, en mots et en icone ; la carte dit ce qui
        // manque, le code, et quand il reviendra.
        return _Resultat(
          icone: AppIcons.attente,
          ton: TonEtat.neutre,
          titre: _code == null
              ? t.appareils.emetteur.horsLigne.titreSansCode
              : t.appareils.emetteur.horsLigne.titreAvecCode,
          phrase: _code == null
              ? t.appareils.emetteur.horsLigne.phraseSansCode
              : t.appareils.emetteur.horsLigne.phraseAvecCode(heure: heure),
        );
      case EtapeEmetteur.erreur:
        return _erreur();
    }
  }

  Widget _erreur() {
    switch (_motif) {
      case MotifErreurEmetteur.plafond:
        return _Resultat(
          icone: AppIcons.appareil,
          ton: TonEtat.avertissement,
          titre: t.appareils.emetteur.erreur.plafondTitre,
          phrase: t.appareils.emetteur.erreur.plafondPhrase,
          libelleAction: t.appareils.emetteur.erreur.plafondAction,
          // Le retrait vit sur la page des appareils de cet eleve (LD-3).
          onAction: () =>
              GoRouter.of(context)
                  .go(Routes.ficheEleveSousPage(widget.eleveId, 'appareils')),
        );
      case MotifErreurEmetteur.horsFoyer:
        return _Resultat(
          icone: AppIcons.interdit,
          ton: TonEtat.alerte,
          titre: t.appareils.emetteur.erreur.horsFoyerTitre,
          phrase: t.appareils.emetteur.erreur.horsFoyerPhrase,
        );
      case MotifErreurEmetteur.compte:
        return _Resultat(
          icone: AppIcons.verrou,
          ton: TonEtat.neutre,
          titre: t.appareils.emetteur.erreur.compteTitre,
          phrase: t.appareils.emetteur.erreur.comptePhrase,
        );
      case MotifErreurEmetteur.generique:
        return _Resultat(
          icone: AppIcons.avertissement,
          ton: TonEtat.alerte,
          titre: t.appareils.emetteur.erreur.generiqueTitre,
          phrase: t.appareils.emetteur.erreur.generiquePhrase,
          libelleAction: t.commun.reessayer,
          onAction: () => unawaited(_demarrer()),
          enCours: _enCours,
        );
    }
  }
}

/// Un fondu d'entree, nul sous mouvement reduit.
///
/// Seul le NOUVEAU contenu apparait en fondu : l'ancien est retire tout de
/// suite, pour qu'un code confirme ne reste pas une frame de plus a l'ecran ni
/// dans l'arbre semantique.
class _Apparition extends StatelessWidget {
  const _Apparition({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: AppMouvement.duree(context, AppMouvement.apparition),
      curve: AppMouvement.entree,
      builder: (BuildContext _, double opacite, Widget? enfant) =>
          Opacity(opacity: opacite, child: enfant),
      child: child,
    );
  }
}

class _Preparation extends StatelessWidget {
  const _Preparation();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppPage.largeurEtatVide),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Un squelette carre, jamais un faux QR.
            const Center(
              child: Skeleton(hauteur: _Mesures.qrMin, largeur: _Mesures.qrMin),
            ),
            Ecart.vXl,
            Semantics(
              liveRegion: true,
              child: Text(
                t.appareils.emetteur.preparation,
                textAlign: TextAlign.center,
                style: palette.inkMuted.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Resultat extends StatelessWidget {
  const _Resultat({
    required this.icone,
    required this.titre,
    required this.phrase,
    this.ton = TonEtat.accent,
    this.libelleAction,
    this.onAction,
    this.enCours = false,
  });

  final AppIcon icone;
  final String titre;
  final String phrase;
  final TonEtat ton;
  final String? libelleAction;
  final VoidCallback? onAction;
  final bool enCours;

  @override
  Widget build(BuildContext context) {
    // Le changement d'etat est annonce une fois, par son titre ; jamais le
    // compte a rebours.
    return Semantics(
      liveRegion: true,
      child: EcranResultat(
        icone: icone,
        ton: ton,
        titre: titre,
        phrase: phrase,
        libelleAction: libelleAction,
        onAction: onAction,
        actionEnCours: enCours,
      ),
    );
  }
}

abstract final class _Mesures {
  /// Cote minimal du carre blanc : lisible a bout de bras.
  static const double qrMin = 200;

  /// Cote maximal : au-dela, le lecteur doit reculer.
  static const double qrMax = 320;

  /// Cote maximal sur telephone : le code et l'heure de fin restent visibles
  /// sous le QR sans defiler.
  static const double qrMaxTelephone = 256;

  /// Largeur de la colonne sur telephone et tablette.
  static const double colonne = 520;

  /// Largeur de la composition en deux colonnes sur bureau.
  static const double bureau = 960;
}

/// Le code actif : consigne, QR, code manuel, validite.
///
/// Telephone et tablette : une colonne centree (ecran resultat M5, manifeste
/// section 2). Bureau (a partir de 1200) : deux colonnes, le QR dans sa carte
/// a gauche, la consigne et le code a droite.
class _VueActive extends StatelessWidget {
  const _VueActive({
    required this.code,
    required this.heure,
    required this.restant,
    required this.suiviIndisponible,
  });

  final String code;
  final String heure;
  final String restant;
  final bool suiviIndisponible;

  @override
  Widget build(BuildContext context) {
    final bool bureau = AppGabarit.de(context) == Gabarit.desktop;
    final Widget consigne = _Consigne(bureau: bureau);
    final Widget details = _Details(
      code: code,
      heure: heure,
      restant: restant,
      suiviIndisponible: suiviIndisponible,
      bureau: bureau,
    );

    if (bureau) {
      // Un seul cadre : le carre blanc du QR (pas de carte autour d'une
      // carte).
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _Mesures.bureau),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              EmetteurQr(code: code, cote: _Mesures.qrMax),
              const SizedBox(width: AppSpacing.section),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[consigne, Ecart.vXxl, details],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _Mesures.colonne),
        child: LayoutBuilder(
          builder: (BuildContext _, BoxConstraints contraintes) {
            final double cote = contraintes.maxWidth.clamp(
              _Mesures.qrMin,
              AppGabarit.de(context) == Gabarit.mobile
                  ? _Mesures.qrMaxTelephone
                  : _Mesures.qrMax,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                consigne,
                Ecart.vXxl,
                Center(
                  child: EmetteurQr(code: code, cote: cote),
                ),
                Ecart.vXl,
                details,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Consigne extends StatelessWidget {
  const _Consigne({required this.bureau});

  final bool bureau;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextAlign alignement = bureau ? TextAlign.start : TextAlign.center;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            t.appareils.emetteur.consigneTitre,
            textAlign: alignement,
            style: palette.inkStrong.applyTo(
              textes.titleMedium ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vSm,
        Text(
          t.appareils.emetteur.consigne,
          textAlign: alignement,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
      ],
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({
    required this.code,
    required this.heure,
    required this.restant,
    required this.suiviIndisponible,
    required this.bureau,
  });

  final String code;
  final String heure;
  final String restant;
  final bool suiviIndisponible;
  final bool bureau;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextAlign alignement = bureau ? TextAlign.start : TextAlign.center;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          t.appareils.emetteur.codeManuel,
          textAlign: alignement,
          style: palette.inkMuted.applyTo(
            textes.labelLarge ?? const TextStyle(),
          ),
        ),
        Ecart.vXs,
        Align(
          alignment: bureau
              ? AlignmentDirectional.centerStart
              : Alignment.center,
          child: CodeEnClair(code: code),
        ),
        Ecart.vLg,
        Text(
          t.appareils.emetteur.valableJusqua(heure: heure),
          textAlign: alignement,
          style: palette.inkStrong.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        // Le compte a rebours se lit, il ne s'annonce pas a chaque seconde.
        Text(
          t.appareils.emetteur.restant(temps: restant),
          textAlign: alignement,
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
        Ecart.vXl,
        DecoratedBox(
          decoration:
              (suiviIndisponible ? palette.washWarning : palette.washAccent)
                  .decoration(borderRadius: AppRadius.arrondiSm),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              suiviIndisponible
                  ? '${t.appareils.emetteur.suiviIndisponible} '
                        '${t.appareils.emetteur.sortie(heure: heure)}'
                  : t.appareils.emetteur.sortie(heure: heure),
              style:
                  (suiviIndisponible ? palette.washWarning : palette.washAccent)
                      .applyTo(textes.bodySmall ?? const TextStyle()),
            ),
          ),
        ),
      ],
    );
  }
}

String _heure(DateTime? quand) {
  if (quand == null) {
    return '';
  }
  final DateTime local = quand.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

String _mmss(Duration duree) {
  final int minutes = duree.inMinutes;
  final int secondes = duree.inSeconds % 60;
  return '$minutes:${secondes.toString().padLeft(2, '0')}';
}
