import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/appairage/lecteur_qr.dart';
import '../../core/appairage/profils_locaux.dart';
import '../../core/appairage/service_enfant.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/ecran_resultat.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/status_pill.dart';
import 'saisie_code_page.dart';

/// Les etapes du scanner.
enum EtapeScanner {
  /// La camera est demandee (et l'autorisation, la premiere fois).
  demarrage,

  /// La camera tourne : le viseur attend un QR code.
  lecture,

  /// Un code valide a ete lu : camera arretee, le serveur verifie.
  verification,

  /// La camera n'a pas demarre (refus, occupee, absente, non supportee,
  /// erreur) : voir [EtatCamera].
  camera,

  /// Le serveur a refuse le code lu : voir [MotifRefusAppairage].
  refus,
}

/// `/connexion/eleve/scanner` : la lecture du QR code affiche par le tuteur,
/// sur l'appareil de l'eleve (sans session).
///
/// Regles (mandat section 7, C05 section 6) :
/// - la camera est demandee a l'ouverture, par le port [LecteurQr] ;
/// - le contenu lu est valide (`FormatCodeAppairage.normaliser`) : tout autre
///   contenu, adresse web comprise, est refuse **sans etre ouvert** ;
/// - a la premiere lecture valide, la camera s'arrete et les lectures
///   suivantes sont ignorees ; une reponse tardive apres la sortie est
///   ignoree (garde de generation) ;
/// - la camera est rendue a la sortie et arretee en arriere-plan ;
/// - la saisie manuelle reste accessible dans tous les etats.
///
/// Telephone : plein cadre sombre (salle M3, manifeste section 2) dans les
/// deux themes, disque retour 48. Tablette et bureau : panneau centre.
class ScannerPage extends ConsumerStatefulWidget {
  /// Cree la page.
  const ScannerPage({super.key});

  /// La cle du viseur, pour les tests et les captures.
  static const Key viseurKey = ValueKey<String>('scanner-viseur');

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage>
    with WidgetsBindingObserver {
  late final LecteurQr _lecteur;
  StreamSubscription<String>? _abonnement;
  EtapeScanner _etape = EtapeScanner.demarrage;
  EtatCamera _etatCamera = EtatCamera.erreur;
  MotifRefusAppairage _motif = MotifRefusAppairage.generique;
  bool _contenuInvalide = false;
  bool _enVol = false;
  bool _enPause = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lecteur = ref.read(fabriqueLecteurQrProvider)();
    _abonnement = _lecteur.lectures.listen(_surLecture);
    if (!ref.read(lecteurQrDisponibleProvider)) {
      _etape = EtapeScanner.camera;
      _etatCamera = EtatCamera.nonSupportee;
    } else {
      // Le viseur doit etre dans l'arbre avant le demarrage de la camera.
      WidgetsBinding.instance.addPostFrameCallback(
        (Duration _) => unawaited(_demarrer()),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _generation++;
    unawaited(_abonnement?.cancel());
    // La camera est rendue a la sortie, quelle que soit l'etape.
    unawaited(_lecteur.liberer());
    super.dispose();
  }

  void _poser(VoidCallback changement) {
    if (mounted) {
      setState(changement);
    }
  }

  Future<void> _demarrer() async {
    if (!mounted) {
      return;
    }
    final int generation = ++_generation;
    _poser(() {
      _etape = EtapeScanner.demarrage;
      _contenuInvalide = false;
    });
    final EtatCamera etat = await _lecteur.demarrer();
    if (!mounted || generation != _generation) {
      return;
    }
    if (_enPause) {
      await _lecteur.arreter();
      return;
    }
    _poser(() {
      if (etat == EtatCamera.pret) {
        _etape = EtapeScanner.lecture;
      } else {
        _etape = EtapeScanner.camera;
        _etatCamera = etat;
      }
    });
  }

  void _surLecture(String brut) {
    if (!mounted || _etape != EtapeScanner.lecture || _enVol) {
      return;
    }
    final String? code = FormatCodeAppairage.normaliser(brut);
    if (code == null) {
      // Un QR d'autre chose (une adresse, un menu...) : dit, jamais ouvert.
      if (!_contenuInvalide) {
        _poser(() => _contenuInvalide = true);
      }
      return;
    }
    unawaited(_verifier(code));
  }

  Future<void> _verifier(String code) async {
    _enVol = true;
    final int generation = ++_generation;
    // Les lectures sont suspendues des la premiere detection valide.
    unawaited(_lecteur.arreter());
    _poser(() {
      _etape = EtapeScanner.verification;
      _contenuInvalide = false;
    });
    try {
      final ProfilLocal profil = await connecterDepuisEcran(ref, code);
      if (!mounted || generation != _generation) {
        return;
      }
      GoRouter.of(context).go(Routes.connexionEleve, extra: profil);
    } on AppairageRefuse catch (refus) {
      if (!mounted || generation != _generation) {
        return;
      }
      _poser(() {
        _etape = EtapeScanner.refus;
        _motif = refus.motif;
      });
    } finally {
      _enVol = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState etat) {
    switch (etat) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // `inactive` est volontairement ignore : la fenetre d'autorisation du
        // systeme le declenche, et arreter la camera a ce moment ferait
        // compter un refus qui n'a pas eu lieu.
        if (_etape == EtapeScanner.lecture ||
            _etape == EtapeScanner.demarrage) {
          _enPause = true;
          _generation++;
          unawaited(_lecteur.arreter());
        }
      case AppLifecycleState.resumed:
        if (_enPause) {
          _enPause = false;
          unawaited(_demarrer());
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  void _versSaisie() => GoRouter.of(context).go(Routes.connexionEleveCode);

  @override
  Widget build(BuildContext context) {
    final bool mobile = AppGabarit.de(context) == Gabarit.mobile;
    final AsyncValue<bool> reseau = ref.watch(horsLigneProvider);
    final bool horsLigne = reseau.hasValue && reseau.requireValue;
    final bool viseurVisible =
        _etape == EtapeScanner.demarrage || _etape == EtapeScanner.lecture;

    final Widget viseur = _Viseur(
      apercu: _lecteur.apercu(),
      etape: _etape,
      contenuInvalide: _contenuInvalide,
      horsLigne: horsLigne,
      mobile: mobile,
    );
    final Widget etat = _etatHorsViseur();

    // Le viseur reste monte (hors scene) dans tous les etats : la camera
    // s'attache a lui avant chaque demarrage, relance comprise.
    final Widget contenu = Stack(
      fit: mobile ? StackFit.expand : StackFit.loose,
      children: <Widget>[
        Offstage(offstage: !viseurVisible, child: viseur),
        if (!viseurVisible) etat,
      ],
    );

    final Widget saisir = ActionPrincipale(
      libelle: t.eleveConnexion.lecteur.saisir,
      niveau: NiveauAction.secondaire,
      onPress: _versSaisie,
    );

    if (mobile) {
      final AppMetriques metriques = AppMetriques.of(context);
      return Theme(
        data: AppTheme.pour(metriques.mode, Brightness.dark),
        child: PageShell(
          titre: t.eleveConnexion.lecteur.titre,
          onRetour: _versSaisie,
          defilante: false,
          actions: saisir,
          child: contenu,
        ),
      );
    }

    return PageShell(
      titre: t.eleveConnexion.lecteur.titre,
      onRetour: _versSaisie,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurDialogue),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[contenu, Ecart.vXl, saisir],
            ),
          ),
        ),
      ),
    );
  }

  Widget _etatHorsViseur() {
    final l = t.eleveConnexion.lecteur;
    switch (_etape) {
      case EtapeScanner.demarrage:
      case EtapeScanner.lecture:
        return const SizedBox.shrink();
      case EtapeScanner.verification:
        return _Etat(
          icone: AppIcons.attente,
          titre: l.verificationTitre,
          phrase: l.verificationPhrase,
          enCours: true,
        );
      case EtapeScanner.refus:
        final ({String titre, String phrase}) libelles = libellesRefusAppairage(
          _motif,
        );
        return _Etat(
          icone: _motif == MotifRefusAppairage.horsLigne
              ? AppIcons.horsLigne
              : AppIcons.avertissement,
          ton: _motif == MotifRefusAppairage.horsLigne
              ? TonEtat.neutre
              : TonEtat.avertissement,
          titre: libelles.titre,
          phrase: libelles.phrase,
          libelleAction: l.scannerANouveau,
          onAction: () => unawaited(_demarrer()),
        );
      case EtapeScanner.camera:
        return _etatCameraWidget();
    }
  }

  Widget _etatCameraWidget() {
    final l = t.eleveConnexion.lecteur;
    switch (_etatCamera) {
      case EtatCamera.pret:
        return const SizedBox.shrink();
      case EtatCamera.refusee:
        return _Etat(
          icone: AppIcons.cameraCoupee,
          titre: l.refuseeTitre,
          phrase: l.refuseePhrase,
          libelleAction: l.refuseeAction,
          onAction: () => unawaited(_demarrer()),
        );
      case EtatCamera.refuseeDurablement:
        // Aucun bouton « Reessayer » : il ne rouvrirait pas la fenetre du
        // systeme. La saisie reste dans la zone d'action.
        return _Etat(
          icone: AppIcons.verrou,
          ton: TonEtat.neutre,
          titre: l.refuseeDurablementTitre,
          phrase: l.refuseeDurablementPhrase,
        );
      case EtatCamera.occupee:
        return _Etat(
          icone: AppIcons.camera,
          ton: TonEtat.neutre,
          titre: l.occupeeTitre,
          phrase: l.occupeePhrase,
          libelleAction: t.commun.reessayer,
          onAction: () => unawaited(_demarrer()),
        );
      case EtatCamera.absente:
        return _Etat(
          icone: AppIcons.cameraCoupee,
          ton: TonEtat.neutre,
          titre: l.absenteTitre,
          phrase: l.absentePhrase,
        );
      case EtatCamera.nonSupportee:
        return _Etat(
          icone: AppIcons.qr,
          ton: TonEtat.neutre,
          titre: l.nonSupporteeTitre,
          phrase: l.nonSupporteePhrase,
        );
      case EtatCamera.erreur:
        return _Etat(
          icone: AppIcons.avertissement,
          ton: TonEtat.alerte,
          titre: l.erreurTitre,
          phrase: l.erreurPhrase,
          libelleAction: t.commun.reessayer,
          onAction: () => unawaited(_demarrer()),
        );
    }
  }
}

/// Un etat hors viseur : ecran resultat, annonce une fois par son titre.
class _Etat extends StatelessWidget {
  const _Etat({
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
    final Widget resultat = Semantics(
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
    // Telephone : le plein cadre a une hauteur bornee, l'etat y defile. Sur
    // tablette et bureau, c'est la page qui defile.
    return AppGabarit.de(context) == Gabarit.mobile
        ? SingleChildScrollView(child: resultat)
        : resultat;
  }
}

/// Le viseur : la camera dans un cadre arrondi, un carre de visee, la
/// consigne et, s'il y a lieu, le refus d'un QR qui n'est pas un code.
class _Viseur extends StatelessWidget {
  const _Viseur({
    required this.apercu,
    required this.etape,
    required this.contenuInvalide,
    required this.horsLigne,
    required this.mobile,
  });

  final Widget apercu;
  final EtapeScanner etape;
  final bool contenuInvalide;
  final bool horsLigne;
  final bool mobile;

  /// Hauteur du viseur sur tablette et bureau (panneau centre).
  static const double hauteurPanneau = 360;

  /// Part du plus petit cote du viseur occupee par le carre de visee.
  static const double proportionVisee = 0.62;

  /// Cote maximal du carre de visee.
  static const double coteViseeMax = 280;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final l = t.eleveConnexion.lecteur;

    final Widget cadre = ClipRRect(
      borderRadius: AppRadius.arrondiLg,
      child: DecoratedBox(
        decoration: palette.surfaceSunken.decoration(),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Semantics(
              key: ScannerPage.viseurKey,
              label: l.libelleApercu,
              image: true,
              child: ExcludeSemantics(child: apercu),
            ),
            // Le carre de visee : un filet, rien sur l'image elle-meme.
            LayoutBuilder(
              builder: (BuildContext _, BoxConstraints contraintes) {
                final double cote =
                    (contraintes.biggest.shortestSide * proportionVisee)
                        .clamp(0, coteViseeMax)
                        .toDouble();
                return Center(
                  child: SizedBox.square(
                    dimension: cote,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.arrondiMd,
                        border: Border.fromBorderSide(
                          palette.borderStrong.asBorderSide(width: 2),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );

    final List<Widget> textesSous = <Widget>[
      Semantics(
        liveRegion: true,
        child: Text(
          etape == EtapeScanner.demarrage ? l.demarrage : l.consigne,
          textAlign: TextAlign.center,
          style: palette.inkStrong.applyTo(
            textes.bodyLarge ?? const TextStyle(),
          ),
        ),
      ),
      if (contenuInvalide) ...<Widget>[
        Ecart.vMd,
        Semantics(
          liveRegion: true,
          child: DecoratedBox(
            decoration: palette.washWarning.decoration(
              borderRadius: AppRadius.arrondiSm,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                l.contenuInvalide,
                textAlign: TextAlign.center,
                style: palette.washWarning.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
          ),
        ),
      ],
      if (horsLigne) ...<Widget>[
        Ecart.vSm,
        Text(
          t.eleveConnexion.saisie.horsLigne,
          textAlign: TextAlign.center,
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
      ],
    ];

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(child: cadre),
          Ecart.vLg,
          ...textesSous,
          Ecart.vLg,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(height: hauteurPanneau, child: cadre),
        Ecart.vLg,
        ...textesSous,
      ],
    );
  }
}
