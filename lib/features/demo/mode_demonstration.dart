// Mode demonstration tuteur (P2-07) : socle.
//
// Donnees fictives, aucun appel serveur, jamais en production
// (03_DECISIONS_COORDINATEUR.md, decisions 1 et 6 ; 00_REPRISE.md 5.4).
//
// L'interrupteur se lit a l'execution (`?demo=tuteur` dans l'adresse) parce
// que le deploiement force `PLAYGROUND=false` et qu'on ne touche pas au
// workflow. La garde, elle, est compilee : `ENVIRONNEMENT=production` la
// ferme quelle que soit l'adresse.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../../core/appairage/service_appairage.dart';
import '../../core/capacites/port_acces_foyer.dart';
import '../../core/capacites/port_catalogue_classes.dart';
import '../../core/capacites/port_classes_foyer.dart';
import '../../core/capacites/port_finance_foyer.dart';
import '../../core/capacites/port_notifications.dart';
import '../../core/config/env.dart';
import '../../core/domain/enums.dart';
import '../../core/offres/offre_horaire.dart';
import '../../core/offres/service_offres.dart';
import '../../core/planning/service_planning.dart';
import '../../core/presence/service_presence.dart';
import '../../core/profil/service_acceptations.dart';
import '../../core/seance_famille/port_seances_famille.dart';
import '../../core/seance_famille/seance_famille.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/session/source_session.dart';
import '../../core/suivi/service_suivi.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/tc_groupe/port_groupes.dart';
import '../../core/tc_observation/activation_observation.dart';
import '../../core/tc_observation/port_historique_observations.dart';
import '../../core/tc_observation/port_politique_observation.dart';
import '../../core/tc_observation/port_visite_observation.dart';
import 'catalogue_demo.dart';
import 'finance_demo.dart';
import 'notifications_demo.dart';
import 'observation_demo.dart';
import 'presence_demo.dart';

/// Parametre d'adresse qui demande la demonstration tuteur.
const String parametreDemo = 'demo';

/// Valeur du parametre qui ouvre la demonstration tuteur.
const String valeurDemoTuteur = 'tuteur';

/// Vrai si l'environnement compile autorise la demonstration.
///
/// Tout ce qui ressemble a `production` (casse, espaces) ferme la porte, et un
/// environnement vide aussi : une compilation mal declaree ne l'ouvre jamais.
bool environnementAutoriseDemo(String environnement) {
  final String normalise = environnement.trim().toLowerCase();
  return normalise.isNotEmpty && !normalise.contains('prod');
}

/// Vrai si l'adresse demande la demonstration tuteur.
bool demoTuteurDemandee(Uri adresse) =>
    adresse.queryParameters[parametreDemo]?.trim().toLowerCase() ==
    valeurDemoTuteur;

/// La garde complete, pure pour etre testee sans compilation dediee.
bool demoTuteurActive({required Uri adresse, required String environnement}) =>
    environnementAutoriseDemo(environnement) && demoTuteurDemandee(adresse);

/// La garde appliquee a la compilation courante et a l'adresse d'ouverture.
bool get demoTuteurActiveIci =>
    demoTuteurActive(adresse: Uri.base, environnement: Env.environnement);

/// Les surcharges de la demonstration tuteur.
///
/// Leve une [StateError] si l'environnement ne l'autorise pas : meme appelee
/// par erreur, elle ne produit rien en production.
List<Override> surchargesDemoTuteur({String? environnement}) {
  if (!environnementAutoriseDemo(environnement ?? Env.environnement)) {
    throw StateError('Demonstration interdite en production.');
  }
  return <Override>[
    sourceSessionProvider.overrideWithValue(const SourceSessionDemo()),
    elevesDuFoyerProvider.overrideWith((Ref ref) async => DonneesDemo.eleves),
    portAccesFoyerProvider.overrideWithValue(const AccesFoyerDemo()),
    portClassesFoyerProvider.overrideWithValue(const ClassesFoyerDemo()),
    portSeancesFamilleProvider.overrideWithValue(SeancesFamilleDemo()),
    portCatalogueClassesProvider.overrideWithValue(
      const CatalogueClassesDemo(),
    ),
    // Lectures des ecrans tuteur encore adossees a Supabase : rendues vides
    // ou fictives pour qu'aucune ne parte vers le serveur.
    appareilsDuFoyerProvider.overrideWith(
      (Ref ref) async => const <AppareilAppaire>[],
    ),
    parcoursFoyerProvider.overrideWith(
      (Ref ref) async => const <ParcoursApprenant>[],
    ),
    monFuseauProvider.overrideWith((Ref ref) async => 'Europe/Paris'),
    seancesDuSuiviProvider.overrideWith((Ref ref) async => const <Seance>[]),
    mesGroupesProvider.overrideWith(
      (Ref ref) async => DonneesDemo.classes.values.toList(),
    ),
    // Observation simulee : politique, budget, historique. La salle video
    // demande un jeton au serveur, donc l'observation reelle reste fermee.
    observationTuteurReelleProvider.overrideWithValue(false),
    portPolitiqueObservationProvider.overrideWithValue(
      const PolitiqueObservationDemo(),
    ),
    portVisiteObservationProvider.overrideWithValue(
      const VisiteObservationDemo(),
    ),
    portHistoriqueObservationsProvider.overrideWithValue(
      const HistoriqueObservationsDemo(),
    ),
    // Presence (Accueil, verification prealable) et pieces signees (Compte).
    servicePresenceProvider.overrideWithValue(const PresenceDemo()),
    acceptationsProvider.overrideWith((Ref ref) async => const <Acceptation>[]),
    // Finance fictive (LT-2) : paiement et annulation restent indisponibles.
    portFinanceFoyerProvider.overrideWithValue(const FinanceFoyerDemo()),
    // Notifications fictives (LT-12), dont une a cible retiree.
    portNotificationsProvider.overrideWithValue(const NotificationsDemo()),
  ];
}

/// Donnees fictives partagees par les doubles.
abstract final class DonneesDemo {
  static const String foyerId = 'demo-foyer';
  static const String tuteurId = 'demo-tuteur';
  static const String aichaId = 'demo-eleve-aicha';
  static const String yusufId = 'demo-eleve-yusuf';
  static const String groupeAicha = 'demo-groupe-coran-1';
  static const String groupeYusuf = 'demo-groupe-arabe-1';

  static final DateTime finAcces = DateTime.utc(2099, 12, 31);

  static final List<EleveDuFoyer> eleves = <EleveDuFoyer>[
    EleveDuFoyer(
      id: aichaId,
      prenom: 'Aïcha',
      identifiantImmuable: 'DEMO-A1',
      mode: InterfaceMode.enfant,
      camera: CameraPolicy.forbidden,
      finAcces: finAcces,
    ),
    EleveDuFoyer(
      id: yusufId,
      prenom: 'Yusuf',
      identifiantImmuable: 'DEMO-Y1',
      mode: InterfaceMode.standard,
      camera: CameraPolicy.allowed,
      finAcces: finAcces,
    ),
  ];

  static const EnseignantVM enseignante = EnseignantVM(
    enseignantId: 'demo-enseignante',
    titre: TitreEnseignant.sayyida,
    nomAffichage: 'Maryam',
  );

  static const EnseignantVM enseignant = EnseignantVM(
    enseignantId: 'demo-enseignant',
    titre: TitreEnseignant.sayyid,
    nomAffichage: 'Ibrahim',
  );

  static const Map<String, GroupSummaryVM> classes = <String, GroupSummaryVM>{
    aichaId: GroupSummaryVM(
      groupeId: groupeAicha,
      libelle: 'Coran, niveau 1',
      couleurJeton: JetonCouleurGroupe(index: 0, codeStable: 'demo-0'),
      enseignant: enseignante,
      nombreMembres: 5,
      seuilMax: 8,
      typePublic: TypePublicGroupeVM.enfant,
      actif: true,
      nomCours: 'Coran',
    ),
    yusufId: GroupSummaryVM(
      groupeId: groupeYusuf,
      libelle: 'Arabe, niveau 2',
      couleurJeton: JetonCouleurGroupe(index: 1, codeStable: 'demo-1'),
      enseignant: enseignant,
      nombreMembres: 6,
      seuilMax: 8,
      typePublic: TypePublicGroupeVM.enfant,
      actif: true,
      nomCours: 'Arabe',
    ),
  };
}

/// Session tuteur fictive, resolue tout de suite, sans Supabase.
class SourceSessionDemo implements SourceSession {
  const SourceSessionDemo();

  static const SessionState etat = SessionState(
    resolue: true,
    role: AppRole.guardian,
    householdId: DonneesDemo.foyerId,
    profileId: DonneesDemo.tuteurId,
    accountStatus: AccountStatus.active,
    lectureProfil: LectureProfil.presente,
  );

  @override
  Stream<SessionState> etats() => Stream<SessionState>.value(etat);

  @override
  Future<void> rafraichir() async {}
}

/// Acces fictifs : les deux eleves sont actifs.
class AccesFoyerDemo implements PortAccesFoyer {
  const AccesFoyerDemo();

  @override
  Future<List<AccesBeneficiaire>> acces() async => <AccesBeneficiaire>[
    for (final EleveDuFoyer e in DonneesDemo.eleves)
      AccesBeneficiaire(
        eleveId: e.id,
        prenom: e.prenom,
        finAcces: e.finAcces,
        etatAffiche: EtatAccesAffiche.actif,
      ),
  ];
}

/// Une classe fictive par eleve.
class ClassesFoyerDemo implements PortClassesFoyer {
  const ClassesFoyerDemo();

  @override
  Future<List<ClasseFoyer>> classesDe(String eleveId) async {
    final GroupSummaryVM? c = DonneesDemo.classes[eleveId];
    return c == null
        ? const <ClasseFoyer>[]
        : <ClasseFoyer>[ClasseFoyer(eleveId: eleveId, classe: c)];
  }

  @override
  Future<ClasseFoyer?> classe({
    required String groupeId,
    required String eleveId,
  }) async {
    final GroupSummaryVM? c = DonneesDemo.classes[eleveId];
    return c != null && c.groupeId == groupeId
        ? ClasseFoyer(eleveId: eleveId, classe: c)
        : null;
  }
}

/// Seances fictives : chaque eleve a trois seances passees (historique) et
/// une a venir, calculees a partir de l'instant d'ouverture.
class SeancesFamilleDemo implements PortSeancesFamille {
  SeancesFamilleDemo({DateTime? maintenant})
    : _seances = _fabriquer((maintenant ?? DateTime.now()).toUtc());

  final List<SeanceFamille> _seances;

  static List<SeanceFamille> _fabriquer(DateTime maintenant) {
    final DateTime base = DateTime.utc(
      maintenant.year,
      maintenant.month,
      maintenant.day,
      16,
    );
    return <SeanceFamille>[
      for (final EleveDuFoyer e in DonneesDemo.eleves)
        for (final int jours in <int>[-14, -7, -2, 2])
          SeanceFamille(
            seanceId: 'demo-seance-${e.id}-$jours',
            eleveId: e.id,
            groupeId: DonneesDemo.classes[e.id]!.groupeId,
            debutUtc: base.add(Duration(days: jours)),
            finPrevueUtc: base.add(Duration(days: jours, minutes: 45)),
            enseignant: EnseignantSeance(
              prenom: DonneesDemo.classes[e.id]!.enseignant.nomAffichage,
              titre: DonneesDemo.classes[e.id]!.enseignant.titre,
            ),
          ),
    ];
  }

  DateTime get _maintenant => DateTime.now().toUtc();

  Iterable<SeanceFamille> _de(String? eleveId) => _seances.where(
    (SeanceFamille s) => eleveId == null || s.eleveId == eleveId,
  );

  @override
  Future<SeanceFamille?> prochaine(String eleveId) async {
    final List<SeanceFamille> a = _de(eleveId)
        .where((SeanceFamille s) => s.debutUtc.isAfter(_maintenant))
        .toList();
    return a.isEmpty ? null : a.first;
  }

  @override
  Future<SeanceFamille?> derniere(String eleveId) async {
    final List<SeanceFamille> p = _de(eleveId)
        .where((SeanceFamille s) => !s.debutUtc.isAfter(_maintenant))
        .toList();
    return p.isEmpty ? null : p.last;
  }

  @override
  Future<List<SeanceFamille>> historique({
    String? eleveId,
    DateTimeRange? periode,
  }) async => _de(eleveId)
      .where(
        (SeanceFamille s) =>
            !s.debutUtc.isAfter(_maintenant) &&
            (periode == null ||
                (!s.debutUtc.isBefore(periode.start.toUtc()) &&
                    s.debutUtc.isBefore(periode.end.toUtc()))),
      )
      .toList()
      .reversed
      .toList();

  @override
  Future<SeanceFamille?> seance(String seanceId, {String? eleveId}) async {
    for (final SeanceFamille s in _de(eleveId)) {
      if (s.seanceId == seanceId) {
        return s;
      }
    }
    return null;
  }

  @override
  Future<List<SeanceFamille>> planning({
    required String groupeId,
    required String eleveId,
    required DateTimeRange periode,
  }) async => _de(eleveId)
      .where(
        (SeanceFamille s) =>
            s.groupeId == groupeId &&
            !s.debutUtc.isBefore(periode.start.toUtc()) &&
            s.debutUtc.isBefore(periode.end.toUtc()),
      )
      .toList();

  @override
  Future<DateTime> maintenantServeurUtc() async => _maintenant;

  @override
  Stream<SeanceFamille> suivre(String seanceId, {String? eleveId}) async* {
    final SeanceFamille? s = await seance(seanceId, eleveId: eleveId);
    if (s == null) {
      throw SeanceIntrouvable(seanceId);
    }
    yield s;
  }
}
