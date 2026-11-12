// HORS-SALLE-1 (directeur, 12/11/2026 au soir) : ce qui se dit hors de
// l'ecran de la salle quand l'appel continue (salle reduite) ou vient d'etre
// rendu par une absence de l'eleve hors de l'application.
//
// Deux pieces poses par `app.dart`, au-dessus de toutes les routes, sans
// toucher a l'ile « Seance toujours en direct » (`BarreSeanceEnDirect`, autre
// lot) :
// - [BandeauSonBloqueHorsSalle] : le son recu est bloque par le navigateur
//   alors que la salle est reduite ; « Activer le son » d'un geste.
// - [RetourHorsApplication] : l'eleve est sorti de la salle pendant son
//   absence ; la salle s'ouvre sur l'ecran du retour, ou qu'il soit.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/billet_salle.dart';
import '../../core/router/routes.dart';
import '../../core/tc_classe/port_session_persistante.dart';
import '../../core/tc_classe/session_persistante.dart';
import '../../core/theme/app_palette.dart';
import '../../core/video/livekit_session_provider.dart';
import '../../core/video/video_session_provider.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/offline_banner.dart';

/// La page affichee est-elle la salle ? Lue sur la route du dessus de la
/// pile (le tuteur entre par `push`), comme l'ile de la seance.
bool estSurLaSalle(GoRouter routeur) {
  final RouteMatchList pile = routeur.routerDelegate.currentConfiguration;
  final String chemin = pile.lastOrNull?.matchedLocation ?? pile.uri.path;
  return Uri.parse(chemin).path == Routes.salle ||
      pile.uri.path == Routes.salle;
}

/// Le son recu bloque par le navigateur, salle reduite.
///
/// La salle dit deja « Le son est coupe par le navigateur » en tete de son
/// ecran (ENTREE-ROBUSTE) ; hors de l'ecran, l'ile ne le disait pas. Ce
/// bandeau, au registre du bandeau hors ligne ([OfflineBanner.message],
/// jamais recompose), le dit sur tous les autres ecrans tant qu'un appel est
/// tenu, avec le meme geste. Rien sinon.
class BandeauSonBloqueHorsSalle extends ConsumerStatefulWidget {
  /// Cree le bandeau.
  const BandeauSonBloqueHorsSalle({required this.routeur, super.key});

  /// Le routeur : le bandeau se tait sur la salle, qui le dit elle-meme.
  final GoRouter routeur;

  /// Le bandeau (tests, captures).
  static const Key cle = ValueKey<String>('hors-salle-son-bloque');

  /// Son lien « Activer le son ».
  static const Key cleActiver = ValueKey<String>('hors-salle-activer-son');

  @override
  ConsumerState<BandeauSonBloqueHorsSalle> createState() =>
      _BandeauSonBloqueEtat();
}

class _BandeauSonBloqueEtat extends ConsumerState<BandeauSonBloqueHorsSalle> {
  late final VideoSessionProvider _moteur = ref.read(moteurSalleProvider);
  StreamSubscription<bool>? _suivi;
  bool _bloque = false;

  @override
  void initState() {
    super.initState();
    if (_moteur case final SonRecuBloque son) {
      _bloque = son.sonBloque;
      _suivi = son.sonBloqueChange.listen((bool b) {
        if (mounted) setState(() => _bloque = b);
      });
    }
    widget.routeur.routerDelegate.addListener(_routeChangee);
  }

  @override
  void didUpdateWidget(BandeauSonBloqueHorsSalle ancien) {
    super.didUpdateWidget(ancien);
    if (!identical(ancien.routeur, widget.routeur)) {
      ancien.routeur.routerDelegate.removeListener(_routeChangee);
      widget.routeur.routerDelegate.addListener(_routeChangee);
    }
  }

  @override
  void dispose() {
    widget.routeur.routerDelegate.removeListener(_routeChangee);
    unawaited(_suivi?.cancel());
    super.dispose();
  }

  /// Le routeur notifie aussi pendant son premier rendu : la reconstruction
  /// attend alors la fin de l'image.
  void _routeChangee() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted) setState(() {});
      });
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final SessionEnCours? cours = ref.watch(etatSessionProvider).value?.cours;
    if (!_bloque || cours == null || estSurLaSalle(widget.routeur)) {
      return const SizedBox.shrink();
    }
    return OfflineBanner.message(
      key: BandeauSonBloqueHorsSalle.cle,
      message: t.salle.sonBloque,
      icone: AppIcons.avertissement.repos,
      action: LienFleche(
        key: BandeauSonBloqueHorsSalle.cleActiver,
        libelle: t.salle.activerSon,
        fleche: false,
        encre: AppPalette.of(context).washWarning.applyTo,
        // Le navigateur ne relance la lecture que sur un geste.
        onPress: () {
          if (_moteur case final SonRecuBloque son) {
            unawaited(son.activerSon());
          }
        },
      ),
    );
  }
}

/// L'eleve sorti de la salle pendant son absence hors de l'application.
///
/// Quand l'ecran de la salle est monte, il lit lui-meme la sortie et montre
/// l'ecran du retour. Quand l'eleve avait reduit la salle, cette piece rouvre
/// la salle (le meme billet que l'ile), qui montre alors cet ecran : un seul
/// ecran du retour, celui de la salle. Ne rend rien.
class RetourHorsApplication extends ConsumerStatefulWidget {
  /// Cree la piece.
  const RetourHorsApplication({required this.routeur, super.key});

  /// Le routeur de l'application.
  final GoRouter routeur;

  @override
  ConsumerState<RetourHorsApplication> createState() =>
      _RetourHorsApplicationEtat();
}

class _RetourHorsApplicationEtat extends ConsumerState<RetourHorsApplication> {
  StreamSubscription<EtatSessionPersistante>? _suivi;

  @override
  void initState() {
    super.initState();
    final ControleurSessionPersistante controleur = ref.read(
      controleurSessionProvider,
    );
    _suivi = controleur.etats.listen(_lire);
  }

  @override
  void dispose() {
    unawaited(_suivi?.cancel());
    super.dispose();
  }

  void _lire(EtatSessionPersistante etat) {
    final SessionEnCours? quittee = etat.sortieHorsApplication;
    if (quittee == null || !mounted) return;
    // Apres l'image : la salle montee lit la sortie dans le meme tour.
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted || estSurLaSalle(widget.routeur)) return;
      final ControleurSessionPersistante controleur = ref.read(
        controleurSessionProvider,
      );
      if (controleur.etatCourant.sortieHorsApplication?.sessionId !=
          quittee.sessionId) {
        return;
      }
      widget.routeur.go(
        Routes.salle,
        extra: BilletSalle(
          sessionId: quittee.sessionId,
          emisA: DateTime.now(),
          groupeId: quittee.groupeId.isEmpty ? null : quittee.groupeId,
          eleveId: quittee.eleveId,
          interfaceGuidee: quittee.interfaceGuidee,
        ),
      );
    });
    // Une image est demandee : une page cachee n'en produit peut-etre pas,
    // la navigation se fera au retour.
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
