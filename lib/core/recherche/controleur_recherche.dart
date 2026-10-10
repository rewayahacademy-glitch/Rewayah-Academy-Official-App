import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/enums.dart';
import '../reseau/service_reseau.dart';
import '../session/session_controleur.dart';
import '../session/session_state.dart';
import 'budgets_recherche.dart';
import 'etat_recherche.dart';
import 'modeles_recherche.dart';
import 'port_recherche.dart';

/// L'espace de recherche d'une session, ou `null` quand la session n'en a pas.
///
/// L'espace est un **choix d'interface** (spec §7.1) que le serveur intersecte
/// avec les droits reels. [demande] n'a d'effet que pour un compte tuteur
/// dont la capacite « eleve autonome » est servie (C-24) : l'adulte autonome
/// choisit entre son espace de famille et son espace d'eleve ; tout autre
/// espace demande est ignore.
EspaceRecherche? espaceRecherchePour(
  SessionState session, {
  EspaceRecherche? demande,
}) {
  final AppRole? role = session.role;
  // Une session d'observation d'agent n'a aucune recherche : elle ne
  // herite jamais de celle de la personne observee (SEC-R16).
  if (role == null || session.observation != null) return null;
  final bool guide = session.interfaceMode == InterfaceMode.enfant;
  return switch (role) {
    AppRole.admin => EspaceRecherche.administration,
    AppRole.accountant => EspaceRecherche.comptable,
    AppRole.controller => EspaceRecherche.controleur,
    AppRole.teacher => EspaceRecherche.enseignant,
    AppRole.student =>
      guide ? EspaceRecherche.eleveGuide : EspaceRecherche.eleve,
    AppRole.guardian =>
      session.eleveAutonome &&
              (demande == EspaceRecherche.eleve ||
                  demande == EspaceRecherche.eleveGuide)
          ? (guide ? EspaceRecherche.eleveGuide : EspaceRecherche.eleve)
          : EspaceRecherche.famille,
  };
}

/// Ce qui identifie la personne et son espace, pour purger au changement.
///
/// Un changement de compte, de role, de mode ou de capacite vide la
/// recherche : requete, resultats, curseurs et demandes en cours (SEC-R07,
/// R08). Aucune valeur n'est conservee entre deux identites.
final Provider<String> cleSessionRechercheProvider = Provider<String>(
  (Ref ref) => ref.watch(
    sessionProvider.select(
      (SessionState s) =>
          '${s.profileId}|${s.role?.name}|${s.householdId}|'
          '${s.interfaceMode.name}|${s.eleveAutonome}',
    ),
  ),
);

/// Le controleur de la surface de recherche, pour un contexte.
///
/// **La machine d'etats de la spec §5** : `inactif → saisie → attente →
/// chargement → resultats | partiels | vide | erreur | delai`, avec un jeton
/// de generation : toute saisie, tout changement de contexte ou de session
/// invalide les demandes en cours, et une reponse tardive est ignoree
/// (SEC-R05). Rien ne part pour un champ vide ou trop court, et rien ne
/// persiste : ni historique, ni cache, ni requete dans l'adresse (spec §7.3).
class RechercheControleur extends Notifier<EtatRecherche> {
  /// Cree le controleur d'un [contexte].
  RechercheControleur(this.contexte);

  /// Le contexte (espace actif et domaine d'ouverture).
  final ContexteRecherche contexte;

  Timer? _attente;
  Timer? _lenteur;
  int _generation = 0;
  bool _ferme = false;

  @override
  EtatRecherche build() {
    // Une autre identite : cette instance se reconstruit vide. L'instance
    // survit a la reconstruction : le drapeau de fermeture se rearme ici.
    _ferme = false;
    ref.watch(cleSessionRechercheProvider);
    // L'etat du reseau est ecoute (pour etre connu a la premiere recherche)
    // sans reconstruire : un changement de reseau ne vide pas la saisie.
    ref.listen<AsyncValue<bool>>(
      horsLigneProvider,
      (AsyncValue<bool>? _, AsyncValue<bool> _) {},
    );
    ref.onDispose(() {
      _ferme = true;
      _generation++;
      _attente?.cancel();
      _lenteur?.cancel();
    });
    return const EtatRecherche();
  }

  /// Le texte a change : nettoie, juge, puis lance apres le delai de saisie.
  void ecrire(String brut) {
    _arreter();
    final RequeteNormalisee requete = RequeteNormalisee.de(brut, contexte);
    switch (requete.validite) {
      case ValiditeRequete.vide:
        state = const EtatRecherche();
      case ValiditeRequete.tropCourte:
        state = EtatRecherche(
          texte: requete.texte,
          phase: PhaseRecherche.saisie,
        );
      case ValiditeRequete.valide:
        state = EtatRecherche(
          texte: requete.texte,
          phase: PhaseRecherche.attente,
        );
        final int generation = _generation;
        _attente = Timer(BudgetsRecherche.delaiSaisie, () {
          unawaited(_lancer(requete.texte, generation));
        });
    }
  }

  /// La validation explicite (touche Entree) : sans attendre le delai.
  void valider() {
    if (state.phase != PhaseRecherche.attente) return;
    _attente?.cancel();
    unawaited(_lancer(state.texte, _generation));
  }

  /// Efface la recherche et tout ce qu'elle a recu.
  void effacer() {
    _arreter();
    state = const EtatRecherche();
  }

  /// Relance toute la recherche, apres une erreur, un delai ou le retour du
  /// reseau.
  void reessayer() {
    if (state.texte.isEmpty) return;
    _arreter();
    state = EtatRecherche(texte: state.texte, phase: PhaseRecherche.attente);
    unawaited(_lancer(state.texte, _generation));
  }

  /// Relance **un seul** domaine en panne (§5 « Domaine indisponible »).
  void reessayerDomaine(DomaineRecherche domaine) {
    final int generation = _generation;
    final String texte = state.texte;
    if (texte.isEmpty) return;
    _remplacer(
      domaine,
      (EtatDomaine d) =>
          d.copier(avancement: AvancementDomaine.enCours, effacerEchec: true),
    );
    unawaited(_interroger(domaine, texte, generation, premiere: true));
  }

  /// Charge la page suivante d'un domaine : « Voir davantage », curseur
  /// opaque. Les lignes deja recues restent ; un echec ne les retire pas.
  void plusDeResultats(DomaineRecherche domaine) {
    final EtatDomaine? courant = _domaine(domaine);
    if (courant == null ||
        !courant.aPlus ||
        courant.curseur == null ||
        courant.pageEnCours) {
      return;
    }
    _remplacer(
      domaine,
      (EtatDomaine d) => d.copier(pageEnCours: true, pageEnEchec: false),
    );
    unawaited(
      _interroger(
        domaine,
        state.texte,
        _generation,
        premiere: false,
        curseur: courant.curseur,
      ),
    );
  }

  // --- interne -------------------------------------------------------------

  void _arreter() {
    _generation++;
    _attente?.cancel();
    _lenteur?.cancel();
  }

  EtatDomaine? _domaine(DomaineRecherche domaine) {
    for (final EtatDomaine d in state.domaines) {
      if (d.domaine == domaine) return d;
    }
    return null;
  }

  void _remplacer(
    DomaineRecherche domaine,
    EtatDomaine Function(EtatDomaine) changer,
  ) {
    final List<EtatDomaine> domaines = <EtatDomaine>[
      for (final EtatDomaine d in state.domaines)
        d.domaine == domaine ? changer(d) : d,
    ];
    state = state.copier(domaines: domaines, phase: phaseDesDomaines(domaines));
  }

  Future<void> _lancer(String texte, int generation) async {
    if (_ferme || generation != _generation) return;
    // Hors ligne : aucune demande ne part (SEC-R18) ; la phase le dit et
    // « Reessayer » relance au retour du reseau. Reseau inconnu : en ligne.
    final bool horsLigne = ref.read(horsLigneProvider).value ?? false;
    if (horsLigne) {
      state = EtatRecherche(texte: texte, phase: PhaseRecherche.horsLigne);
      return;
    }
    state = EtatRecherche(texte: texte, phase: PhaseRecherche.chargement);
    _lenteur?.cancel();
    _lenteur = Timer(BudgetsRecherche.seuilLenteur, () {
      if (_ferme || generation != _generation) return;
      if (state.domaines.any((EtatDomaine d) => !d.fini) ||
          state.domaines.isEmpty) {
        state = state.copier(lent: true);
      }
    });

    List<DomaineRecherche> portees;
    try {
      portees = await ref
          .read(portRechercheProvider)
          .portees(contexte)
          .timeout(BudgetsRecherche.delaiDemande);
    } on TimeoutException {
      if (_ferme || generation != _generation) return;
      _lenteur?.cancel();
      state = EtatRecherche(texte: texte, phase: PhaseRecherche.delai);
      return;
    } on Object {
      if (_ferme || generation != _generation) return;
      _lenteur?.cancel();
      state = EtatRecherche(texte: texte, phase: PhaseRecherche.erreur);
      return;
    }
    if (_ferme || generation != _generation) return;
    if (portees.isEmpty) {
      _lenteur?.cancel();
      state = EtatRecherche(texte: texte, phase: PhaseRecherche.nonAutorise);
      return;
    }
    final List<DomaineRecherche> ordre = <DomaineRecherche>[
      if (contexte.domaineCible != null &&
          portees.contains(contexte.domaineCible))
        contexte.domaineCible!,
      ...portees.where((DomaineRecherche d) => d != contexte.domaineCible),
    ];
    state = EtatRecherche(
      texte: texte,
      phase: PhaseRecherche.chargement,
      domaines: <EtatDomaine>[
        for (final DomaineRecherche d in _dansLOrdreDAffichage(ordre))
          EtatDomaine(domaine: d),
      ],
    );

    // Les demandes partent par groupes de trois au plus : un fan-out borne,
    // et un domaine lent ne retient pas les autres (§6.1, §8.3).
    final Queue<DomaineRecherche> file = Queue<DomaineRecherche>.of(ordre);
    Future<void> travailleur() async {
      while (file.isNotEmpty) {
        final DomaineRecherche suivant = file.removeFirst();
        if (_ferme || generation != _generation) return;
        _remplacer(
          suivant,
          (EtatDomaine d) => d.copier(avancement: AvancementDomaine.enCours),
        );
        await _interroger(suivant, texte, generation, premiere: true);
      }
    }

    await Future.wait(<Future<void>>[
      for (int i = 0; i < BudgetsRecherche.domainesSimultanes; i++)
        travailleur(),
    ]);
    if (_ferme || generation != _generation) return;
    _lenteur?.cancel();
    state = state.copier(lent: false);
  }

  /// L'ordre d'affichage est celui des domaines (stable) ; le domaine
  /// d'ouverture n'est que prioritaire pour les demandes.
  List<DomaineRecherche> _dansLOrdreDAffichage(List<DomaineRecherche> ordre) =>
      <DomaineRecherche>[...ordre]..sort(
        (DomaineRecherche a, DomaineRecherche b) => a.index.compareTo(b.index),
      );

  Future<void> _interroger(
    DomaineRecherche domaine,
    String texte,
    int generation, {
    required bool premiere,
    String? curseur,
  }) async {
    final int limite = premiere && contexte.domaineCible == null
        ? BudgetsRecherche.limiteCommune
        : BudgetsRecherche.limitePage;
    ReponseDomaine reponse;
    try {
      reponse = await ref
          .read(portRechercheProvider)
          .rechercher(
            domaine: domaine,
            requete: texte,
            contexte: contexte,
            curseur: curseur,
            limite: limite,
          )
          .timeout(BudgetsRecherche.delaiDemande);
    } on TimeoutException {
      reponse = ReponseEchec(domaine, StatutRecherche.delai);
    } on Object {
      reponse = ReponseEchec(domaine, StatutRecherche.indisponible);
    }
    // Une reponse d'une saisie passee n'est jamais montree comme la reponse
    // a la saisie courante (SEC-R05).
    if (_ferme || generation != _generation) return;
    switch (reponse) {
      case final ReponseOk ok:
        _remplacer(domaine, (EtatDomaine d) {
          final List<ResultatRecherche> tous = premiere
              ? ok.elements
              : _sansDoublon(d.elements, ok.elements);
          return d.copier(
            avancement: AvancementDomaine.termine,
            elements: tous,
            curseur: ok.curseurSuivant,
            effacerCurseur: ok.curseurSuivant == null,
            aPlus: ok.aPlus,
            pageEnCours: false,
            pageEnEchec: false,
            effacerEchec: true,
          );
        });
      case ReponseEchec(:final StatutRecherche statut):
        if (premiere) {
          _remplacer(
            domaine,
            (EtatDomaine d) => d.copier(
              avancement: AvancementDomaine.enEchec,
              echec: statut,
              elements: const <ResultatRecherche>[],
              aPlus: false,
              effacerCurseur: true,
              pageEnCours: false,
            ),
          );
        } else {
          // Page suivante en echec : les lignes recues restent, le curseur
          // perime est abandonne.
          _remplacer(
            domaine,
            (EtatDomaine d) => d.copier(
              pageEnCours: false,
              pageEnEchec: true,
              aPlus: statut != StatutRecherche.curseurPerime && d.aPlus,
            ),
          );
        }
    }
  }

  List<ResultatRecherche> _sansDoublon(
    List<ResultatRecherche> actuels,
    List<ResultatRecherche> nouveaux,
  ) {
    final Set<String> vus = <String>{
      for (final ResultatRecherche r in actuels) r.reference,
    };
    return <ResultatRecherche>[
      ...actuels,
      for (final ResultatRecherche r in nouveaux)
        if (vus.add(r.reference)) r,
    ];
  }
}

/// Le controleur de recherche d'un [ContexteRecherche].
///
/// Libere des que la surface se ferme : ni requete, ni resultat ne survit.
final rechercheControleurProvider = NotifierProvider.autoDispose
    .family<RechercheControleur, EtatRecherche, ContexteRecherche>(
      RechercheControleur.new,
    );
