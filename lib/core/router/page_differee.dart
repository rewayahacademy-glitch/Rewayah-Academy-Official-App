import 'dart:async';

import 'package:flutter/widgets.dart';

import '../i18n/strings.g.dart';
import '../observabilite/journal_dev.dart';
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
/// connexion prend plus de temps que prevu » ; en cas d'echec (reseau
/// coupe), une phrase et « Reessayer ».
///
/// [cle] nomme l'import differe (un par prefixe : dart2js verifie le
/// chargement prefixe par prefixe) ; une fois charge, l'ecran se construit
/// des la premiere image, sans repasser par l'etat vide.
class PageDifferee extends StatefulWidget {
  /// Cree l'ecran differe.
  const PageDifferee({
    required this.cle,
    required this.charger,
    required this.construire,
    super.key,
  });

  /// Le nom du morceau (celui du prefixe d'import).
  final String cle;

  /// `prefixe.loadLibrary`.
  final Future<void> Function() charger;

  /// L'ecran, construit une fois le morceau charge.
  final Widget Function() construire;

  static final Set<String> _charges = <String>{};

  /// Vrai si le morceau [cle] est deja charge (tests).
  @visibleForTesting
  static bool estCharge(String cle) => _charges.contains(cle);

  @override
  State<PageDifferee> createState() => _PageDiffereeState();
}

class _PageDiffereeState extends State<PageDifferee> {
  bool _echec = false;
  bool _prolonge = false;
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
      _echec = true;
    }
    _minuterie?.cancel();
    if (mounted) {
      setState(() {});
    }
  }

  void _reessayer() {
    setState(() {
      _echec = false;
      _prolonge = false;
    });
    unawaited(_charger());
  }

  @override
  Widget build(BuildContext context) {
    if (PageDifferee._charges.contains(widget.cle)) {
      return widget.construire();
    }
    if (_echec) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: EtatSysteme(
            nature: NatureEtat.horsLigne,
            portee: PorteeEtat.page,
            libelleAction: t.commun.etats.actions.reessayer,
            onAction: _reessayer,
          ),
        ),
      );
    }
    if (_prolonge) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: EtatSysteme(
            nature: NatureEtat.chargementProlonge,
            portee: PorteeEtat.page,
            onAction: _reessayer,
          ),
        ),
      );
    }
    return const SizedBox.expand();
  }
}
