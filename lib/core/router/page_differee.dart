import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../agent/recharger_adresse.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../observabilite/journal_dev.dart';
import '../reseau/service_reseau.dart';
import '../theme/app_delais.dart';
import '../theme/app_spacing.dart';
import '../widgets/etat_systeme.dart';

/// Un ecran dont le code arrive a la demande (`import ... deferred as`).
///
/// Lot ouverture rapide (29/10/2026) : la salle, le Coran, les ecrans de la
/// direction, de la comptabilite, des candidatures, de la recherche et des
/// communications ne sont plus dans `main.dart.js` ; leur morceau se
/// telecharge a la premiere visite, puis reste en memoire. Pendant ce temps,
/// la coquille de l'ecran (navigation) reste a sa place et la zone du contenu
/// reste vide ; passe [AppDelais.chargementProlonge], la phrase « La
/// connexion prend plus de temps que prevu ».
///
/// Lot RECHARGE-1 (03/11/2026) : un echec se classe ([classerEchecMorceau]),
/// il ne se dit plus « hors ligne » quand le reseau marche. Prouve sur le
/// banc (docs/current/captures/E2E/recharge-1/avant/) : apres un deploiement,
/// la page ouverte demande ses anciens morceaux et recoit ceux de la nouvelle
/// version (ou `index.html`, par la reecriture de Vercel) ; dart2js les
/// refuse (« ... not loaded ») et chaque « Reessayer » rejouait le meme
/// refus, jusqu'a la deconnexion. Seul un rechargement de la page le resout.
///
/// [cle] nomme l'import differe (un par prefixe : dart2js verifie le
/// chargement prefixe par prefixe) ; une fois charge, l'ecran se construit
/// des la premiere image, sans repasser par l'etat vide.
/// Un import differe : son nom (la [PageDifferee.cle]) et son chargement.
typedef MorceauDiffere = (String cle, Future<void> Function() charger);

/// Pourquoi le morceau d'un ecran n'est pas arrive.
enum EchecMorceau {
  /// L'appareil est hors ligne : « Reessayer », et l'ecran revient seul au
  /// retour du reseau.
  horsLigne,

  /// En ligne, un premier chargement interrompu : « Reessayer ».
  ouverture,

  /// En ligne, interrompu de nouveau apres « Reessayer » : seul le
  /// rechargement de la page peut aider.
  repete,

  /// Le serveur a servi le morceau d'une autre version (deploiement) : seul
  /// le rechargement de la page l'ouvre.
  versionChangee,
}

/// Classe un echec de chargement de morceau. **Pure.**
///
/// [horsLigne] est l'etat du reseau lu au moment de l'echec ; [echecsEnLigne]
/// compte les echecs en ligne de cet ecran, celui-ci compris. dart2js dit
/// « ... not loaded » quand le fichier recu ne porte pas le code attendu
/// (`js_helper.dart`, `_loadAllHunks` et `_loadHunk`) : c'est la signature
/// d'un deploiement, ou d'une page `index.html` servie a la place du morceau.
EchecMorceau classerEchecMorceau(
  Object erreur, {
  required bool horsLigne,
  required int echecsEnLigne,
}) {
  if (horsLigne) return EchecMorceau.horsLigne;
  if (erreur.toString().contains('not loaded')) {
    return EchecMorceau.versionChangee;
  }
  return echecsEnLigne >= 2 ? EchecMorceau.repete : EchecMorceau.ouverture;
}

class PageDifferee extends ConsumerStatefulWidget {
  /// Cree l'ecran differe.
  const PageDifferee({
    required this.cle,
    required this.charger,
    required this.construire,
    this.recharger = rechargerAdresse,
    super.key,
  });

  /// Le nom du morceau (celui du prefixe d'import).
  final String cle;

  /// `prefixe.loadLibrary`.
  final Future<void> Function() charger;

  /// L'ecran, construit une fois le morceau charge.
  final Widget Function() construire;

  /// Le rechargement de la page entiere (fixe dans les tests).
  final VoidCallback recharger;

  static final Set<String> _charges = <String>{};

  /// Vrai si le morceau [cle] est deja charge (tests).
  @visibleForTesting
  static bool estCharge(String cle) => _charges.contains(cle);

  /// Charge le morceau [cle] d'avance : l'ecran se construira alors des sa
  /// premiere image. Sert aux tests, qui pompent une image apres la
  /// navigation et attendent l'ecran.
  static Future<void> precharger(
    String cle,
    Future<void> Function() charger,
  ) async {
    await charger();
    _charges.add(cle);
  }

  @override
  ConsumerState<PageDifferee> createState() => _PageDiffereeState();
}

class _PageDiffereeState extends ConsumerState<PageDifferee> {
  EchecMorceau? _echec;
  int _echecsEnLigne = 0;
  bool _prolonge = false;
  bool _enCours = false;
  Timer? _minuterie;

  @override
  void initState() {
    super.initState();
    if (!PageDifferee._charges.contains(widget.cle)) {
      unawaited(_charger());
    }
  }

  @override
  void dispose() {
    _minuterie?.cancel();
    super.dispose();
  }

  Future<void> _charger() async {
    if (_enCours) return;
    _enCours = true;
    _minuterie?.cancel();
    _minuterie = Timer(AppDelais.chargementProlonge, () {
      if (mounted) {
        setState(() => _prolonge = true);
      }
    });
    try {
      await widget.charger();
      PageDifferee._charges.add(widget.cle);
    } on Object catch (erreur) {
      journalDev('Chargement du morceau ${widget.cle} impossible : $erreur');
      final bool horsLigne = ref.read(horsLigneProvider).value ?? false;
      if (!horsLigne) _echecsEnLigne++;
      _echec = classerEchecMorceau(
        erreur,
        horsLigne: horsLigne,
        echecsEnLigne: _echecsEnLigne,
      );
    }
    _enCours = false;
    _minuterie?.cancel();
    if (mounted) {
      setState(() {});
    }
  }

  void _reessayer() {
    setState(() {
      _echec = null;
      _prolonge = false;
    });
    unawaited(_charger());
  }

  Widget _etat(EtatSysteme etat) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: etat,
    ),
  );

  @override
  Widget build(BuildContext context) {
    // Le retour du reseau relance seul un ecran en echec.
    ref.listen<AsyncValue<bool>>(horsLigneProvider, (
      AsyncValue<bool>? avant,
      AsyncValue<bool> maintenant,
    ) {
      final bool etaitHorsLigne = avant?.value ?? false;
      final bool horsLigne = maintenant.value ?? false;
      if (etaitHorsLigne && !horsLigne && _echec != null) {
        _reessayer();
      } else if (horsLigne &&
          _echec != null &&
          _echec != EchecMorceau.horsLigne) {
        // Un echec lu avant que l'etat du reseau soit connu : il se dit hors
        // ligne des que le reseau le dit.
        setState(() => _echec = EchecMorceau.horsLigne);
      }
    });
    if (PageDifferee._charges.contains(widget.cle)) {
      return widget.construire();
    }
    final textes = t.commun.etats.recharge1;
    switch (_echec) {
      case EchecMorceau.horsLigne:
        return _etat(
          EtatSysteme(
            nature: NatureEtat.horsLigne,
            portee: PorteeEtat.page,
            libelleAction: t.commun.etats.actions.reessayer,
            onAction: _reessayer,
          ),
        );
      case EchecMorceau.ouverture:
        return _etat(
          EtatSysteme(
            nature: NatureEtat.echecServeur,
            portee: PorteeEtat.page,
            titre: textes.ouvertureTitre,
            phrase: textes.ouverturePhrase,
            libelleAction: t.commun.etats.actions.reessayer,
            onAction: _reessayer,
          ),
        );
      case EchecMorceau.repete:
        return _etat(
          EtatSysteme(
            nature: NatureEtat.echecServeur,
            portee: PorteeEtat.page,
            titre: textes.ouvertureTitre,
            phrase: textes.repetePhrase,
            libelleAction: t.miseAJour.recharger,
            onAction: widget.recharger,
          ),
        );
      case EchecMorceau.versionChangee:
        return _etat(
          EtatSysteme(
            nature: NatureEtat.indisponible,
            portee: PorteeEtat.page,
            titre: t.miseAJour.prete,
            phrase: textes.versionPhrase,
            libelleAction: t.miseAJour.recharger,
            onAction: widget.recharger,
            icone: AppIcons.info,
          ),
        );
      case null:
        break;
    }
    if (_prolonge) {
      return _etat(
        EtatSysteme(
          nature: NatureEtat.chargementProlonge,
          portee: PorteeEtat.page,
          onAction: _reessayer,
        ),
      );
    }
    return const SizedBox.expand();
  }
}
