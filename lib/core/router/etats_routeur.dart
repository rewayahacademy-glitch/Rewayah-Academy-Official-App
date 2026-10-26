import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/connexion/coquille_entree.dart';
import '../../features/connexion/raccord_entree.dart';
import '../domain/enums.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../observabilite/journal_dev.dart';
import '../reseau/service_reseau.dart';
import '../session/session_controleur.dart';
import '../session/session_state.dart';
import '../theme/app_delais.dart';
import '../theme/app_metriques.dart';
import '../theme/app_mouvement.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/etat_systeme.dart';
import '../widgets/page_shell.dart';
import '../widgets/porte_lumiere.dart';
import 'page_etat.dart';
import 'routes.dart';

// Les ecrans transverses du routeur (mandat Tuteur V1 section 8 ; contrat K5 ;
// mapping des routes, ligne 42). Aucun ne montre une donnee, aucun n'est une
// impasse : chacun ramene a une destination que la session autorise.

/// La destination autorisee de [session] : la racine du role d'un compte
/// actif, la connexion d'un visiteur, la racine sinon (que la redirection
/// renvoie a l'inscription, au portail d'attente ou a la page hors ligne).
///
/// Le visiteur va a la connexion : l'action de ces pages s'intitule « Se
/// connecter », et la racine `/` sans session y mene aussi.
String destinationAutorisee(SessionState session) {
  final AppRole? role = session.role;
  return switch (session.porte) {
    PorteAcces.actif when role != null => Routes.racinePour(role),
    PorteAcces.deconnecte => Routes.connexion,
    _ => Routes.racine,
  };
}

/// La page introuvable : un chemin qu'aucune route ne sert (`errorBuilder`),
/// ou un lien profond perime. Jamais l'exception brute de go_router.
class PageIntrouvable extends ConsumerWidget {
  /// Cree la page.
  const PageIntrouvable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SessionState session = ref.watch(sessionProvider);
    final bool visiteur = session.porte == PorteAcces.deconnecte;
    return PageEtat(
      nature: NatureEtat.introuvable,
      illustration: const PorteLumiere(),
      libelleAction: visiteur
          ? t.commun.etats.actions.seConnecter
          : t.commun.etats.actions.retourAccueil,
      onAction: () => GoRouter.of(context).go(destinationAutorisee(session)),
    );
  }
}

/// La page « acces refuse » : une route connue d'un autre role, demandee par
/// URL. Elle ne dit pas ce qu'il y a derriere ; elle ramene a la racine du
/// role.
class PageAccesRefuse extends ConsumerWidget {
  /// Cree la page.
  const PageAccesRefuse({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SessionState session = ref.watch(sessionProvider);
    return PageEtat(
      nature: NatureEtat.accesRefuse,
      onAction: () => GoRouter.of(context).go(destinationAutorisee(session)),
    );
  }
}

/// La page hors ligne du demarrage : la session existe, mais le serveur n'a
/// pas repondu a la lecture du profil. **Rien n'est ouvert** tant qu'il n'a
/// pas repondu (X21) ; la lecture est relancee a la demande, et d'elle-meme
/// au retour du reseau.
class PageHorsLigne extends ConsumerStatefulWidget {
  /// Cree la page.
  const PageHorsLigne({super.key});

  @override
  ConsumerState<PageHorsLigne> createState() => _PageHorsLigneState();
}

class _PageHorsLigneState extends ConsumerState<PageHorsLigne> {
  bool _enCours = false;

  Future<void> _reessayer() async {
    if (_enCours) {
      return;
    }
    setState(() => _enCours = true);
    try {
      // Redemande un jeton : la source relit alors le profil.
      await ref.read(sourceSessionProvider).rafraichir();
    } on Object catch (erreur) {
      journalDev('Relecture de session impossible, reste hors ligne : $erreur');
    } finally {
      if (mounted) {
        setState(() => _enCours = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool>>(horsLigneProvider, (
      AsyncValue<bool>? avant,
      AsyncValue<bool> apres,
    ) {
      if (avant?.value == true && apres.value == false) {
        unawaited(_reessayer());
      }
    });
    // Le bandeau de `PageShell` dit l'absence de reseau ; le titre dit ce qui
    // manque, sans le redire (EA-HL-DOUBLE-1).
    return PageEtat(
      nature: NatureEtat.horsLigne,
      icone: AppIcons.attente,
      titre: t.commun.etats.horsLigneDemarrageTitre,
      phrase: t.commun.etats.horsLigneDemarrage,
      libelleAction: t.commun.etats.actions.reessayer,
      onAction: () => unawaited(_reessayer()),
      actionEnCours: _enCours,
    );
  }
}

/// L'ecran de `/`, pendant la resolution de la session (PR 2 du parcours
/// d'entree, `docs/current/PARCOURS-ENTREE-2026-10-25.md` §3 A) : la surface
/// de marque, le logo horizontal blanc en haut par un fondu net, et la porte
/// qui joue une fois ([AppMouvement.entreeIllustration]) ; aucune roue. Passe
/// [AppDelais.chargementProlonge], la phrase « La connexion prend plus de
/// temps que prevu » et une relance arrivent sous la porte, qui reste.
///
/// Session deja lue active : la version courte (fondus, [AppMouvement.plafond]),
/// puis la redirection habituelle ; lue active pendant l'entree, celle-ci
/// finit sur la duree courte. Sinon, l'avancement de la porte est inscrit au
/// [RaccordEntree] : la connexion qui suit la reprend sans la rejouer.
class EcranDemarrage extends ConsumerStatefulWidget {
  /// Cree l'ecran.
  const EcranDemarrage({super.key});

  @override
  ConsumerState<EcranDemarrage> createState() => _EcranDemarrageState();
}

class _EcranDemarrageState extends ConsumerState<EcranDemarrage> {
  Timer? _minuterie;
  bool _prolonge = false;
  late bool _courte = _sessionActive(ref.read(sessionProvider));

  static bool _sessionActive(SessionState s) => s.resolue && s.connecte;

  @override
  void initState() {
    super.initState();
    _minuterie = Timer(AppDelais.chargementProlonge, () {
      if (mounted) {
        setState(() => _prolonge = true);
      }
    });
  }

  @override
  void dispose() {
    _minuterie?.cancel();
    super.dispose();
  }

  Future<void> _relancer() async {
    try {
      await ref.read(sourceSessionProvider).rafraichir();
    } on Object catch (erreur) {
      journalDev('Relance de session impossible : $erreur');
    }
  }

  void _suivre(double avancement) {
    if (!_courte) {
      ref.read(raccordEntreeProvider).suivre(avancement);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SessionState>(sessionProvider, (
      SessionState? _,
      SessionState s,
    ) {
      if (_sessionActive(s) && !_courte) {
        ref.read(raccordEntreeProvider).oublier();
        setState(() => _courte = true);
      }
    });
    final InterfaceMode mode = AppMetriques.of(context).mode;
    final ThemeData marque = AppTheme.depuis(
      AppPalette.surMarque(),
      mode,
      Brightness.dark,
    );
    // Theme unique, comme la connexion qui suit (decision du 25/10/2026).
    return Theme(
      data: AppTheme.pour(mode, Brightness.light),
      child: Builder(
        builder: (BuildContext context) => PageShell(
          fond: AppPalette.of(context).surfaceMarque,
          bordABord: true,
          defilante: false,
          child: SurMarque(
            theme: marque,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const LogoEntree(),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Semantics(
                              label: t.commun.demarrage.ouverture,
                              child: PorteLumiere.surMarque(
                                courte: _courte,
                                onProgres: _suivre,
                              ),
                            ),
                            if (_prolonge) ...<Widget>[
                              Ecart.vXxl,
                              EtatSysteme(
                                nature: NatureEtat.chargementProlonge,
                                onAction: () => unawaited(_relancer()),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
