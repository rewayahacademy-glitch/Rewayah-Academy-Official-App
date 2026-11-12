// SUIVI-ATTENTE : des suivis de test aux cinq etapes et aux cas particuliers,
// et un port en memoire. Partages par les tests et les captures.
import 'dart:async';

import 'package:rewayah_academy/core/attente_classe/modele_attente.dart';

/// Jeudi 12 novembre 2026, 10:00 : l'instant de la demande dans les donnees.
final DateTime _demande = DateTime(2026, 11, 9, 10, 15);

/// Les cinq etapes jusqu'a l'etape [jusque] (franchies), la suivante en cours.
/// [jusque] 0 : seule la demande est recue (l'etape 2 est en cours).
List<EtapeAttente> etapesJusqua(int jusque, {bool tout = false}) {
  EtatEtapeAttente etat(int n) {
    if (tout) return EtatEtapeAttente.fait;
    final int franchies = jusque + 1; // etape 1 toujours faite
    if (n <= franchies) return EtatEtapeAttente.fait;
    if (n == franchies + 1) return EtatEtapeAttente.enCours;
    return EtatEtapeAttente.aVenir;
  }

  return <EtapeAttente>[
    EtapeAttente(numero: 1, etat: etat(1), quand: _demande),
    EtapeAttente(numero: 2, etat: etat(2)),
    EtapeAttente(
      numero: 3,
      etat: etat(3),
      quand: etat(3) == EtatEtapeAttente.fait
          ? DateTime(2026, 11, 11, 17, 0)
          : null,
    ),
    EtapeAttente(
      numero: 4,
      etat: etat(4),
      quand: etat(4) == EtatEtapeAttente.fait
          ? DateTime(2026, 11, 12, 9, 30)
          : null,
    ),
    EtapeAttente(numero: 5, etat: etat(5)),
  ];
}

/// Les etapes d'une demande close : la demande recue, rien d'autre en cours
/// (le serveur ne laisse aucune etape en cours sur une demande close).
List<EtapeAttente> etapesCloses({int jusque = 0}) => <EtapeAttente>[
  for (final EtapeAttente e in etapesJusqua(jusque))
    EtapeAttente(
      numero: e.numero,
      etat: e.etat == EtatEtapeAttente.enCours
          ? EtatEtapeAttente.aVenir
          : e.etat,
      quand: e.quand,
    ),
];

/// Le creneau choisi : lundi et mercredi, 18:00.
CreneauDemande creneauDeTest() => CreneauDemande(
  occurrences: const <OccurrenceCreneau>[
    OccurrenceCreneau(jourIso: 1, heure: 18),
    OccurrenceCreneau(jourIso: 3, heure: 18),
  ],
);

/// La carte d'un enseignant qui montre tout.
const CarteEnseignantAttente enseignantVisible = CarteEnseignantAttente(
  prenom: 'Ibrahim',
  nom: 'Camara',
  titre: 'sayyid',
  langueCours: 'Français',
  montre: true,
  enseignantId: 'ens-1',
  paysOrigine: 'GN',
  paysResidence: 'FR',
  mot: 'Je suis heureux de vous retrouver.',
);

/// La carte d'un enseignant qui ne montre que son nom et la langue du cours.
const CarteEnseignantAttente enseignantDiscret = CarteEnseignantAttente(
  prenom: 'Khadija',
  nom: 'Diallo',
  titre: 'sayyida',
  langueCours: 'Français',
  montre: false,
);

/// Un suivi de test.
SuiviAttente suiviDeTest({
  String id = 'd1',
  String prenom = 'Yusuf',
  List<EtapeAttente>? etapes,
  CasAttente cas = CasAttente.chemin,
  MotifCloture? motif,
  DelaiFormation? delai,
  String? classe,
  DateTime? premierCours,
  bool premierCoursPasse = false,
  DateTime? creneauChangeLe,
  CarteEnseignantAttente? enseignant,
  bool versionSimple = false,
  bool peutChoisirAutreCreneau = false,
  bool visibleAccueil = true,
  String typePublic = 'enfant',
}) => SuiviAttente(
  demandeId: id,
  eleveId: 'e-$id',
  prenom: prenom,
  fuseauIana: 'Europe/Paris',
  cas: cas,
  typePublic: typePublic,
  versionSimple: versionSimple,
  motif: motif,
  creneau: creneauDeTest(),
  etapes:
      etapes ??
      (cas == CasAttente.refusee ||
              cas == CasAttente.retiree ||
              cas == CasAttente.close
          ? etapesCloses()
          : etapesJusqua(0)),
  delai: delai,
  classe: classe,
  premierCours: premierCours,
  premierCoursPasse: premierCoursPasse,
  creneauChangeLe: creneauChangeLe,
  enseignant: enseignant,
  peutChoisirAutreCreneau: peutChoisirAutreCreneau,
  visibleAccueil: visibleAccueil,
);

/// Un delai de formation de 14 jours, avec un point a 7 jours.
DelaiFormation delaiDeTest({bool depasse = false, bool pointPasse = false}) =>
    DelaiFormation(
      jours: 14,
      limite: DateTime(2026, 11, 23, 10, 15),
      point: DateTime(2026, 11, 16, 10, 15),
      pointPasse: pointPasse,
      depasse: depasse,
    );

/// Les cinq etapes franchies, avec enseignant, classe et premier cours.
SuiviAttente suiviToutEstPret({
  CarteEnseignantAttente enseignant = enseignantVisible,
  bool versionSimple = false,
}) => suiviDeTest(
  etapes: etapesJusqua(4, tout: true),
  classe: 'Classe Al-Fatiha',
  premierCours: DateTime(2026, 11, 16, 18, 0),
  enseignant: enseignant,
  versionSimple: versionSimple,
);

/// Un port en memoire : un flux qu'on pousse a la main.
class PortSuiviAttenteFaux implements PortSuiviAttente {
  /// Cree le port, avec ses premiers suivis.
  PortSuiviAttenteFaux([List<SuiviAttente> initiaux = const <SuiviAttente>[]])
    : _courants = initiaux;

  List<SuiviAttente> _courants;
  final StreamController<List<SuiviAttente>> _flux =
      StreamController<List<SuiviAttente>>.broadcast();

  /// Le nombre d'abonnements ouverts depuis le debut.
  int lectures = 0;

  /// Pousse de nouveaux suivis, comme un passage d'etape cote serveur.
  void pousser(List<SuiviAttente> suivis) {
    _courants = suivis;
    _flux.add(suivis);
  }

  @override
  Stream<List<SuiviAttente>> suivre() async* {
    lectures++;
    yield _courants;
    yield* _flux.stream;
  }
}

/// Un port qui n'emet jamais (chargement qui dure).
class PortSuiviAttenteSansFin implements PortSuiviAttente {
  /// Cree le port.
  const PortSuiviAttenteSansFin();

  @override
  Stream<List<SuiviAttente>> suivre() =>
      const Stream<List<SuiviAttente>>.empty();
}

/// Un port qui echoue.
class PortSuiviAttenteEnEchec implements PortSuiviAttente {
  /// Cree le port.
  const PortSuiviAttenteEnEchec();

  @override
  Stream<List<SuiviAttente>> suivre() =>
      Stream<List<SuiviAttente>>.error(StateError('lecture impossible'));
}
