import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../journal_sorties/port_journal_sorties.dart';
import '../theme/app_delais.dart';

/// HORS-SALLE-1 (directeur, 12/11/2026 au soir) : le temps laisse a l'eleve
/// hors de l'application avant qu'il sorte de la salle.
///
/// **Un seul endroit le lit** ([GardeHorsApplication], par le controleur de
/// session). HORS-SALLE-2 (meme soir : « le delai doit etre reglable par la
/// direction ») : le reglage du serveur (`salle.sorties.delai_secondes`, lu
/// dans `regles_academie()`) quand il existe, [AppDelais.horsApplicationEleve]
/// sinon (serveur d'avant le lot, lecture en cours ou en echec).
final Provider<Duration> delaiHorsApplicationProvider = Provider<Duration>((
  Ref ref,
) {
  final AsyncValue<ReglagesSorties?> lu = ref.watch(reglagesSortiesProvider);
  return (lu.hasValue && !lu.hasError ? lu.value?.delai : null) ??
      AppDelais.horsApplicationEleve;
});

/// HORS-SALLE-1 : la porte d'une exception future. Un geste « Je m'absente un
/// instant » (autre lot, non construit) suspendra la sortie de l'eleve
/// pendant un retrait annonce. **Dans ce lot, toujours faux** : aucune
/// interface ne le pose.
final Provider<bool> coupureSuspendueProvider = Provider<bool>(
  (Ref ref) => false,
);

/// Ce que la garde fait d'une absence, selon qui tient l'appel.
enum RegleHorsApplication {
  /// Rien n'est jamais coupe (qui modere la seance : l'enseignant).
  jamaisCoupe,

  /// Sortie de la salle apres le delai (l'eleve).
  sortieApresDelai,

  /// Pas concerne : aucun appel tenu, ou un observateur (tuteur, controleur).
  horsRegle,
}

/// Ce que la personne trouve en revenant dans l'application.
enum IssueRetour {
  /// Rien ne s'est passe, rien ne s'affiche.
  rien,

  /// Elle est sortie de la salle pendant son absence.
  sortie,
}

/// La regle de l'appel tenu, lue sur les capacites que le serveur a signees
/// (jamais sur un role) :
///
/// - [peutModerer] : celui qui conduit la seance n'est jamais coupe ;
/// - sinon, qui suit le cours (il parle, ou sa voix attend son enseignant,
///   [publicationDifferee]) et n'est pas invisible sort apres le delai ;
/// - un observateur (tuteur temoin, controleur invisible) n'est pas concerne
///   (`lib/features/tc_observation_ui/` hors de ce lot).
RegleHorsApplication regleHorsApplication({
  required bool appelTenu,
  required bool peutModerer,
  required bool peutPublier,
  required bool publicationDifferee,
  required bool invisible,
}) {
  if (!appelTenu) return RegleHorsApplication.horsRegle;
  if (peutModerer) return RegleHorsApplication.jamaisCoupe;
  if (invisible || !(peutPublier || publicationDifferee)) {
    return RegleHorsApplication.horsRegle;
  }
  return RegleHorsApplication.sortieApresDelai;
}

/// HORS-SALLE-1 : ce qui se passe quand la page est cachee pendant un appel
/// tenu (autre application, autre onglet, ecran verrouille).
///
/// Testable sans widget : l'horloge, la minuterie, la regle et les effets
/// sont injectes. Branchee sur `ControleurSessionPersistante`, qui lui dit
/// quand la page est cachee et quand elle revient.
///
/// - L'eleve ([RegleHorsApplication.sortieApresDelai]) : [delai] sans
///   coupure ; passe ce delai, [sortir] (le meme chemin que « Quitter » :
///   annonce, puis deconnexion). Un navigateur peut geler les minuteries
///   d'une page cachee : au retour, la duree reellement passee cachee est
///   relue sur l'horloge et la meme regle s'applique.
/// - Qui modere ([RegleHorsApplication.jamaisCoupe]) : jamais coupe ; deux
///   traces sans identite ([signaler]) disent ce que le telephone a fait de
///   l'appel pendant l'absence.
/// - [coupureSuspendue] vrai : aucune sortie (porte d'un geste futur).
/// - HORS-SALLE-2 : au retour de l'eleve, qu'il soit sorti de la salle ou non,
///   [noter] recoit la duree mesuree par l'horloge et le drapeau de la sortie
///   de la salle (le journal des sorties, que le serveur n'ecrit qu'avec un
///   accord). Rien pour qui modere, rien pour un observateur. Si l'eleve ne
///   revient pas (page tuee), rien n'est note : limite connue.
class GardeHorsApplication {
  /// Cree la garde.
  GardeHorsApplication({
    required this.regle,
    required this.sortir,
    required this.delai,
    this.coupureSuspendue = _jamais,
    this.signaler = _rienASignaler,
    this.etatConnexion = _inconnu,
    this.reprises = _zero,
    this.sonBloque = _jamais,
    this.noter = _rienANoter,
    DateTime Function()? maintenant,
    Timer Function(Duration, void Function())? minuterie,
  }) : _maintenant = maintenant ?? DateTime.now,
       _minuterie = minuterie ?? Timer.new;

  /// La regle de l'appel tenu, lue a l'instant ([regleHorsApplication]).
  final RegleHorsApplication Function() regle;

  /// Fait sortir l'eleve de la salle (annonce, puis deconnexion).
  final Future<void> Function() sortir;

  /// Le delai, lu a chaque absence ([delaiHorsApplicationProvider]).
  final Duration Function() delai;

  /// Un retrait annonce suspend la sortie ([coupureSuspendueProvider]).
  final bool Function() coupureSuspendue;

  /// Une trace de supervision sans identite (`signalerTransport`).
  final void Function(String evenement, Map<String, Object?> donnees) signaler;

  /// L'etat de la connexion, en un mot technique, pour les traces.
  final String Function() etatConnexion;

  /// Le nombre de reprises de la connexion depuis l'entree.
  final int Function() reprises;

  /// Le son recu est-il bloque par le navigateur ?
  final bool Function() sonBloque;

  /// HORS-SALLE-2 : une absence de l'eleve, au retour (duree mesuree par
  /// l'horloge, et vrai quand elle l'a fait sortir de la salle).
  final void Function(Duration absence, bool sortieSalle) noter;

  final DateTime Function() _maintenant;
  final Timer Function(Duration, void Function()) _minuterie;

  DateTime? _cacheeA;
  RegleHorsApplication _regleAuDepart = RegleHorsApplication.horsRegle;
  int _reprisesAuDepart = 0;
  Timer? _attente;
  bool _sortieFaite = false;

  /// Vrai pendant une absence suivie.
  bool get absente => _cacheeA != null;

  /// La page vient d'etre cachee.
  void cachee() {
    if (_cacheeA != null) return;
    final RegleHorsApplication r = regle();
    if (r == RegleHorsApplication.horsRegle) return;
    _cacheeA = _maintenant();
    _regleAuDepart = r;
    _sortieFaite = false;
    if (r == RegleHorsApplication.jamaisCoupe) {
      _reprisesAuDepart = reprises();
      signaler('page_cachee', <String, Object?>{'connexion': etatConnexion()});
      return;
    }
    _attente?.cancel();
    _attente = _minuterie(delai(), () => unawaited(_couper()));
  }

  /// La page est de nouveau visible. Dit ce que la personne trouve.
  Future<IssueRetour> revenue() async {
    final DateTime? depuis = _cacheeA;
    _cacheeA = null;
    _attente?.cancel();
    _attente = null;
    if (depuis == null) {
      return IssueRetour.rien;
    }
    final Duration absence = _maintenant().difference(depuis);
    // La regle du depart : un appel tombe pendant l'absence de l'enseignant
    // doit encore etre dit au retour.
    if (_regleAuDepart == RegleHorsApplication.jamaisCoupe) {
      signaler('page_revenue', <String, Object?>{
        'secondes': absence.inSeconds,
        'connexion': etatConnexion(),
        'reprises': reprises() - _reprisesAuDepart,
        'son_bloque': sonBloque(),
      });
      return IssueRetour.rien;
    }
    // La minuterie a pu etre gelee par le navigateur : l'horloge tranche.
    if (!_sortieFaite && absence >= delai()) {
      await _couper();
    }
    final bool sortie = _sortieFaite;
    _sortieFaite = false;
    // HORS-SALLE-2 : seulement pour l'eleve (la regle du depart), jamais pour
    // qui modere ni pour un observateur.
    if (_regleAuDepart == RegleHorsApplication.sortieApresDelai) {
      noter(absence, sortie);
    }
    return sortie ? IssueRetour.sortie : IssueRetour.rien;
  }

  /// Une sortie voulue (« Quitter ») ou la fin de l'appel : plus rien a
  /// couper.
  void annuler() {
    _attente?.cancel();
    _attente = null;
    _cacheeA = null;
  }

  Future<void> _couper() async {
    _attente = null;
    if (_sortieFaite ||
        coupureSuspendue() ||
        regle() != RegleHorsApplication.sortieApresDelai) {
      return;
    }
    _sortieFaite = true;
    await sortir();
  }

  /// Libere la minuterie.
  void liberer() => annuler();

  static bool _jamais() => false;
  static String _inconnu() => 'inconnu';
  static int _zero() => 0;
  static void _rienASignaler(String _, Map<String, Object?> _) {}
  static void _rienANoter(Duration _, bool _) {}
}
