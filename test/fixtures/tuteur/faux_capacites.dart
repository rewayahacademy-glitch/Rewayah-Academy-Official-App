// Doubles des autres ports de capacites du role Tuteur (contrat K6) :
// catalogue, progression, resume, acces, paiements, notifications, support,
// consentements, profil eleve du titulaire, preferences persistantes.
//
// PROPRIETE : coordinateur (`test/fixtures/tuteur/`). Chaque faux rend ce
// qu'on lui donne, en memoire. Aucune ligne de production ne l'importe.

import 'package:rewayah_academy/core/capacites/port_acces_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_catalogue_classes.dart';
import 'package:rewayah_academy/core/capacites/port_consentements.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_preferences_persistantes.dart';
import 'package:rewayah_academy/core/capacites/port_profil_eleve_titulaire.dart';
import 'package:rewayah_academy/core/capacites/port_progression_famille.dart';
import 'package:rewayah_academy/core/capacites/port_resume_seance_famille.dart';
import 'package:rewayah_academy/core/capacites/port_support.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/profil/service_acceptations.dart';

/// Le catalogue de classes, en memoire.
class FauxCatalogueClasses implements PortCatalogueClasses {
  /// Cree le faux.
  FauxCatalogueClasses({
    this.classes = const <ClasseOuverte>[],
    this.resultat = const ResultatInscription(StatutInscription.inscrit),
  });

  /// Les classes proposees.
  List<ClasseOuverte> classes;

  /// Ce que la prochaine inscription rend.
  ResultatInscription resultat;

  /// Les cles d'idempotence recues, dans l'ordre.
  final List<String> cles = <String>[];

  @override
  Future<List<ClasseOuverte>> compatibles({
    required String eleveId,
    required String fuseauIana,
  }) async => classes;

  @override
  Future<ResultatInscription> inscrire({
    required String classeId,
    required String eleveId,
    required String cleIdempotence,
  }) async {
    cles.add(cleIdempotence);
    return resultat;
  }
}

/// La progression, en memoire.
class FauxProgressionFamille implements PortProgressionFamille {
  /// Les progressions, par eleve.
  final Map<String, ProgressionEleve> parEleve = <String, ProgressionEleve>{};

  @override
  Future<ProgressionEleve> progression(String eleveId) async =>
      parEleve[eleveId] ?? ProgressionEleve(eleveId: eleveId);
}

/// Les resumes de seance, en memoire, par (seance, eleve).
class FauxResumeSeanceFamille implements PortResumeSeanceFamille {
  /// Les resumes.
  final Map<(String, String), String> resumes = <(String, String), String>{};

  @override
  Future<String?> resume({
    required String seanceId,
    required String eleveId,
  }) async => resumes[(seanceId, eleveId)];
}

/// L'acces du foyer, en memoire.
class FauxAccesFoyer implements PortAccesFoyer {
  /// Cree le faux.
  FauxAccesFoyer({this.lignes = const <AccesBeneficiaire>[]});

  /// Les acces rendus.
  List<AccesBeneficiaire> lignes;

  @override
  Future<List<AccesBeneficiaire>> acces() async => lignes;
}

/// Les paiements, en memoire.
class FauxPaiementsFoyer implements PortPaiementsFoyer {
  /// Cree le faux.
  FauxPaiementsFoyer({
    this.paiements = const <PaiementFoyer>[],
    this.lesSoldes = const SoldesFoyer(beneficiaires: <SoldeBeneficiaire>[]),
  });

  /// Les paiements rendus.
  List<PaiementFoyer> paiements;

  /// Les soldes rendus (EA-9).
  SoldesFoyer lesSoldes;

  @override
  Future<List<PaiementFoyer>> historique() async => paiements;

  @override
  Future<SoldesFoyer> soldes() async => lesSoldes;

  @override
  Future<PaiementFoyer?> detail(String id) async {
    for (final PaiementFoyer p in paiements) {
      if (p.id == id) {
        return p;
      }
    }
    return null;
  }
}

/// Les notifications, en memoire.
class FauxNotifications implements PortNotifications {
  /// Cree le faux.
  FauxNotifications({this.notifications = const <NotificationTuteur>[]});

  /// Les notifications rendues.
  List<NotificationTuteur> notifications;

  @override
  Future<List<NotificationTuteur>> liste() async => notifications;

  @override
  Future<NotificationTuteur?> detail(String id) async {
    for (final NotificationTuteur n in notifications) {
      if (n.id == id) {
        return n;
      }
    }
    return null;
  }
}

/// Le canal d'aide, en memoire.
class FauxSupport implements PortSupport {
  /// Cree le faux.
  FauxSupport({this.canalRendu});

  /// Le canal rendu. `null` : aucun canal publie.
  CanalSupport? canalRendu;

  @override
  Future<CanalSupport?> canal() async => canalRendu;
}

/// Les consentements, en memoire. Une version signee ne se reecrit jamais.
class FauxConsentements implements PortConsentements {
  /// Cree le faux.
  FauxConsentements({
    List<Acceptation>? signees,
    this.requis = const <ConsentementRequis>[],
  }) : _signees = signees ?? <Acceptation>[];

  final List<Acceptation> _signees;

  /// Ce que [aRenouveler] rend.
  List<ConsentementRequis> requis;

  /// L'instant d'acceptation enregistre par [accepter].
  DateTime instant = DateTime.utc(2026, 9, 21, 16);

  @override
  Future<List<Acceptation>> signees() async =>
      List<Acceptation>.unmodifiable(_signees);

  @override
  Future<List<ConsentementRequis>> aRenouveler() async => requis;

  @override
  Future<void> accepter({
    required SorteContrat sorte,
    required String version,
  }) async {
    final bool dejaSignee = _signees.any(
      (Acceptation a) => a.sorte == sorte && a.version == version,
    );
    if (!dejaSignee) {
      _signees.insert(
        0,
        Acceptation(sorte: sorte, version: version, accepteeLe: instant),
      );
    }
  }
}

/// Le profil eleve du titulaire, en memoire (simulation de DB-FOY-01).
class FauxProfilEleveTitulaire implements PortProfilEleveTitulaire {
  /// Vrai quand le profil existe.
  bool present = false;

  /// Le nombre d'ouvertures de l'espace eleve demandees.
  int ouvertures = 0;

  @override
  Future<bool> existe() async => present;

  @override
  Future<void> creer() async {
    present = true;
  }

  @override
  Future<void> ouvrirEspaceEleve() async {
    ouvertures++;
  }
}

/// Les preferences persistantes, en memoire.
class FauxPreferencesPersistantes implements PortPreferencesPersistantes {
  /// Les preferences enregistrees. `null` : rien d'enregistre.
  PreferencesLocales? enregistrees;

  @override
  Future<PreferencesLocales?> charger() async => enregistrees;

  @override
  Future<void> enregistrer(PreferencesLocales preferences) async {
    enregistrees = preferences;
  }
}
