import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart'
    show ProviderFamily, StreamProviderFamily;

import 'echec_observation.dart';
import 'guardian_session_visit.dart';
import 'port_politique_observation.dart';
import 'port_visite_observation.dart';
import 'vue_budget_observation.dart';

/// Ou en est une visite d'observation.
enum PhaseVisite {
  /// Rien n'est demande.
  horsVisite,

  /// L'entree est demandee au serveur.
  demande,

  /// La visite a lieu.
  enVisite,

  /// La visite est terminee, et l'ecran le dit.
  terminee,

  /// Le serveur a refuse l'entree, et il a dit pourquoi.
  refusee,

  /// La question n'a pas pu etre posee.
  indisponible,
}

/// Ce que l'ecran d'observation montre, a un instant donne.
@immutable
class EtatVisiteObservation {
  /// Cree un etat.
  const EtatVisiteObservation({
    required this.phase,
    this.visite,
    this.budget,
    this.budgetRecuA,
    this.vueBudget,
    this.motifRefus,
    this.echec,
    this.fin,
    this.budgetIncertain = false,
    this.sortieConfirmee = true,
  });

  /// L'etat au repos.
  static const EtatVisiteObservation horsVisite = EtatVisiteObservation(
    phase: PhaseVisite.horsVisite,
  );

  /// Ou en est la visite.
  final PhaseVisite phase;

  /// L'intervalle ouvert par le serveur.
  final GuardianSessionVisit? visite;

  /// Le dernier budget rendu par le serveur.
  final BudgetObservation? budget;

  /// L'instant local auquel [budget] est arrive.
  final DateTime? budgetRecuA;

  /// Le compte a rebours, tel qu'il s'affiche.
  final VueBudgetObservation? vueBudget;

  /// Pourquoi le serveur a refuse.
  final MotifRefusObservation? motifRefus;

  /// Pourquoi la question n'a pas pu etre posee.
  final EchecObservation? echec;

  /// Pourquoi la visite s'est terminee.
  final FinDeVisite? fin;

  /// Vrai quand la derniere lecture de budget a echoue.
  ///
  /// La visite continue : le compte a rebours local, lui, ne fait que
  /// **raccourcir** le temps affiche, jamais l'allonger, et le jeton expire de
  /// son cote. L'ecran le dit quand meme, parce qu'un chiffre qui n'est plus
  /// confirme n'est pas la meme chose qu'un chiffre confirme.
  final bool budgetIncertain;

  /// Vrai quand le serveur a confirme la fermeture de l'intervalle.
  ///
  /// Faux est un etat **affiche**, pas ignore : le precedent nomme par le
  /// contrat est `ServiceVideo.annoncerSortie`, qui avale volontairement son
  /// echec. Acceptable pour une trace, inacceptable quand c'est ce geste qui
  /// doit fermer un quota.
  final bool sortieConfirmee;

  /// Le meme etat, avec quelques champs changes.
  EtatVisiteObservation copieAvec({
    PhaseVisite? phase,
    GuardianSessionVisit? visite,
    BudgetObservation? budget,
    DateTime? budgetRecuA,
    VueBudgetObservation? vueBudget,
    MotifRefusObservation? motifRefus,
    EchecObservation? echec,
    FinDeVisite? fin,
    bool? budgetIncertain,
    bool? sortieConfirmee,
  }) => EtatVisiteObservation(
    phase: phase ?? this.phase,
    visite: visite ?? this.visite,
    budget: budget ?? this.budget,
    budgetRecuA: budgetRecuA ?? this.budgetRecuA,
    vueBudget: vueBudget ?? this.vueBudget,
    motifRefus: motifRefus ?? this.motifRefus,
    echec: echec ?? this.echec,
    fin: fin ?? this.fin,
    budgetIncertain: budgetIncertain ?? this.budgetIncertain,
    sortieConfirmee: sortieConfirmee ?? this.sortieConfirmee,
  );
}

/// A quelle cadence le compte a rebours se repeint.
///
/// Une seconde, et c'est un rythme d'**affichage** : il ne decide de rien, il
/// rafraichit un nombre. La cadence qui compte, celle de la verite, est
/// [cadenceBudgetObservation], et elle interroge le serveur.
const Duration cadenceAffichageObservation = Duration(seconds: 1);

/// Le deroule d'une visite d'observation, de la demande a la fermeture.
///
/// **Deux sources de temps, une seule autorite.** Le flux de budget vient du
/// serveur et peut mettre fin a la visite a tout instant ; le battement local
/// ne fait que repeindre un compte a rebours **borne par la derniere valeur
/// serveur** (voir [VueBudgetObservation]). Il en decoule l'asymetrie voulue
/// par la specification 11.4 :
///
/// - une horloge locale avancee, ou un battement force, **raccourcit** la
///   visite : le client sort plus tot, ce qui est permis ;
/// - une horloge locale reculee, ou un battement supprime, **ne la rallonge
///   pas** : le serveur annonce le budget epuise, et la visite se ferme.
///
/// Le client ne peut donc pas prolonger sa visite en modifiant un timer.
class MoteurVisiteObservation {
  /// Cree un moteur.
  ///
  /// [horloge] et [battement] sont injectables pour le test : une visite de
  /// cent vingt secondes ne se verifie pas en attendant cent vingt secondes.
  MoteurVisiteObservation(
    this._visites,
    this._politique, {
    DateTime Function()? horloge,
    Stream<void>? battement,
  }) : _horloge = horloge ?? _horlogeSysteme,
       _battement =
           battement ??
           Stream<int>.periodic(
             cadenceAffichageObservation,
             (int battement) => battement,
           );

  static DateTime _horlogeSysteme() => DateTime.now().toUtc();

  final PortVisiteObservation _visites;
  final PortPolitiqueObservation _politique;
  final DateTime Function() _horloge;
  final Stream<void> _battement;

  final StreamController<EtatVisiteObservation> _sortie =
      StreamController<EtatVisiteObservation>.broadcast();

  StreamSubscription<BudgetObservation>? _abonnementBudget;
  StreamSubscription<void>? _abonnementBattement;

  EtatVisiteObservation _etat = EtatVisiteObservation.horsVisite;
  String? _sessionId;

  /// L'etat courant.
  EtatVisiteObservation get etat => _etat;

  /// Les etats successifs. Le premier n'est pas rejoue : l'appelant lit [etat].
  Stream<EtatVisiteObservation> get etats => _sortie.stream;

  /// Demande l'entree en observation.
  ///
  /// **Le serveur verifie tout avant d'ouvrir quoi que ce soit** : lien
  /// tuteur-enfant, seance active, groupe, politique et quota. Le moteur ne
  /// verifie rien de cela : il n'en a pas les moyens, et croire qu'il les a
  /// serait precisement l'erreur que la specification interdit.
  Future<void> entrer({
    required String sessionId,
    required RoleObservateur role,
  }) async {
    if (_etat.phase == PhaseVisite.demande ||
        _etat.phase == PhaseVisite.enVisite) {
      return;
    }
    _sessionId = sessionId;
    _publier(const EtatVisiteObservation(phase: PhaseVisite.demande));

    final ResultatEntreeObservation resultat;
    try {
      resultat = await _visites.entrer(sessionId: sessionId, role: role);
    } on EchecObservation catch (e) {
      _publier(
        EtatVisiteObservation(phase: PhaseVisite.indisponible, echec: e),
      );
      return;
    }

    if (!resultat.autorise) {
      _publier(
        EtatVisiteObservation(
          phase: PhaseVisite.refusee,
          motifRefus: resultat.motifRefus,
          budget: resultat.budget,
        ),
      );
      return;
    }

    final DateTime recuA = _horloge();
    final BudgetObservation? budget = resultat.budget;
    _publier(
      EtatVisiteObservation(
        phase: PhaseVisite.enVisite,
        visite: resultat.visite,
        budget: budget,
        budgetRecuA: recuA,
        vueBudget: budget == null
            ? null
            : VueBudgetObservation.depuis(
                budget: budget,
                recuA: recuA,
                maintenant: recuA,
              ),
      ),
    );

    _abonnementBudget = _politique
        .suivreBudget(sessionId: sessionId)
        .listen(_recevoirBudget, onError: _budgetIllisible);
    _abonnementBattement = _battement.listen(_battre);
  }

  /// Sortie volontaire.
  Future<void> sortir() => _terminer(FinDeVisite.sortieVolontaire);

  /// Fin subie, quand la salle video est perdue pour de bon (reconnexion
  /// echouee) : l'intervalle est referme aupres du serveur comme pour une
  /// sortie, mais la fin dit ce qui s'est passe. Sans effet hors visite.
  Future<void> interrompre() => _terminer(FinDeVisite.deconnexion);

  /// Ferme le moteur. A appeler quand l'ecran disparait.
  ///
  /// **Ne ferme pas l'intervalle cote serveur** : une page demontee n'est pas
  /// une sortie. Et **aucun code serveur ne le referme a l'expiration du
  /// jeton** (cartographie C07, fait 8) : un intervalle laisse ouvert compte
  /// comme une visite et bloque la suivante jusqu'a `temps_epuise`
  /// (dependances DB-OBS-03 et DB-OBS-06).
  Future<void> dispose() async {
    await _arreterEcoutes();
    await _sortie.close();
  }

  void _recevoirBudget(BudgetObservation budget) {
    if (_etat.phase != PhaseVisite.enVisite) {
      return;
    }
    final DateTime recuA = _horloge();
    _publier(
      _etat.copieAvec(
        budget: budget,
        budgetRecuA: recuA,
        budgetIncertain: false,
        vueBudget: VueBudgetObservation.depuis(
          budget: budget,
          recuA: recuA,
          maintenant: recuA,
        ),
      ),
    );
    // **La borne serveur, appliquee sans egard pour l'horloge locale.** Que le
    // battement ait tourne ou non, qu'il reste une heure au chronometre de la
    // machine ou non : le serveur dit qu'il ne reste rien, la visite s'arrete.
    final FinDeVisite? finServeur = _finAnnoncee(budget.motifRefus);
    if (finServeur != null) {
      unawaited(_terminer(finServeur));
    } else if (budget.epuise) {
      unawaited(_terminer(FinDeVisite.quotaAtteint));
    }
  }

  /// La fin qu'un motif de refus annonce PENDANT une visite, quand il en
  /// annonce une : la seance n'est plus active, ou l'acces n'est plus
  /// accorde (observation desactivee, lien tuteur retire). Les motifs de
  /// quota ne ferment rien ici : pendant une visite, c'est le temps restant
  /// ([BudgetObservation.epuise]) qui decide, et le serveur peut refuser une
  /// NOUVELLE entree (quota de visites) sans que la visite en cours cesse.
  static FinDeVisite? _finAnnoncee(MotifRefusObservation? motif) =>
      switch (motif) {
        MotifRefusObservation.seanceNonActive ||
        MotifRefusObservation.horsFenetre => FinDeVisite.seanceTerminee,
        MotifRefusObservation.policyDesactivee ||
        MotifRefusObservation.lienTuteurAbsent => FinDeVisite.revocationServeur,
        MotifRefusObservation.quotaVisitesAtteint ||
        MotifRefusObservation.tempsEpuise ||
        null => null,
      };

  void _budgetIllisible(Object erreur, StackTrace trace) {
    if (_etat.phase != PhaseVisite.enVisite) {
      return;
    }
    // Une lecture ratee n'interrompt pas la visite : le compte a rebours local
    // ne sait que raccourcir, et le jeton expire de son cote. Mais le chiffre
    // cesse d'etre confirme, et l'ecran doit pouvoir le dire.
    _publier(_etat.copieAvec(budgetIncertain: true));
  }

  void _battre(void _) {
    final BudgetObservation? budget = _etat.budget;
    final DateTime? recuA = _etat.budgetRecuA;
    if (_etat.phase != PhaseVisite.enVisite ||
        budget == null ||
        recuA == null) {
      return;
    }
    final VueBudgetObservation vue = VueBudgetObservation.depuis(
      budget: budget,
      recuA: recuA,
      maintenant: _horloge(),
    );
    _publier(_etat.copieAvec(vueBudget: vue));
    if (vue.epuise) {
      // Le client sort de lui-meme quand son propre decompte tombe a zero.
      // C'est une sortie **plus stricte** que la borne serveur, jamais plus
      // permissive : au pire elle abrege une visite d'une fraction de seconde,
      // au mieux elle evite a l'observateur de voir une salle dont le jeton
      // vient d'expirer.
      unawaited(_terminer(FinDeVisite.quotaAtteint));
    }
  }

  Future<void> _terminer(FinDeVisite fin) async {
    if (_etat.phase != PhaseVisite.enVisite) {
      return;
    }
    final String? sessionId = _sessionId;
    _publier(_etat.copieAvec(phase: PhaseVisite.terminee, fin: fin));
    await _arreterEcoutes();
    if (sessionId == null) {
      return;
    }
    try {
      await _visites.sortir(sessionId: sessionId);
    } on EchecObservation catch (e) {
      _publier(_etat.copieAvec(sortieConfirmee: false, echec: e));
    }
  }

  Future<void> _arreterEcoutes() async {
    await _abonnementBudget?.cancel();
    await _abonnementBattement?.cancel();
    _abonnementBudget = null;
    _abonnementBattement = null;
  }

  void _publier(EtatVisiteObservation etat) {
    _etat = etat;
    if (!_sortie.isClosed) {
      _sortie.add(etat);
    }
  }
}

/// Le moteur de visite d'une seance.
///
/// `isAutoDispose` est une exigence, pas une optimisation : un moteur qui
/// survivrait a la sortie de l'ecran garderait un abonnement de budget ouvert
/// sur une seance que personne ne regarde plus.
final ProviderFamily<MoteurVisiteObservation, String>
moteurVisiteObservationProvider =
    Provider.family<MoteurVisiteObservation, String>((
      Ref ref,
      String sessionId,
    ) {
      final MoteurVisiteObservation moteur = MoteurVisiteObservation(
        ref.watch(portVisiteObservationProvider),
        ref.watch(portPolitiqueObservationProvider),
      );
      ref.onDispose(() => unawaited(moteur.dispose()));
      return moteur;
    }, isAutoDispose: true);

/// L'etat courant d'une visite, puis les suivants.
///
/// Le premier evenement est l'etat courant du moteur : un ecran remonte apres
/// une rotation n'attend pas le prochain battement pour savoir qu'une visite
/// est en cours. Meme motif que `etatLienSalleProvider`.
final StreamProviderFamily<EtatVisiteObservation, String>
etatVisiteObservationProvider =
    StreamProvider.family<EtatVisiteObservation, String>(
      (Ref ref, String sessionId) => _etatsAvecCourant(
        ref.watch(moteurVisiteObservationProvider(sessionId)),
      ),
      isAutoDispose: true,
    );

Stream<EtatVisiteObservation> _etatsAvecCourant(
  MoteurVisiteObservation moteur,
) async* {
  yield moteur.etat;
  yield* moteur.etats;
}
