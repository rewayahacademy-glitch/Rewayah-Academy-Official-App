// Les doubles des tests de la Tresorerie (CPT-TRES-1, 2) : un port de
// tresorerie et un port de politique reglables, et l'hote de la page.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_politique_reserve.dart';
import 'package:rewayah_academy/core/capacites/port_tresorerie.dart';
import 'package:rewayah_academy/core/comptable/modeles_comptable.dart';
import 'package:rewayah_academy/core/comptable/statuts_comptable.dart';
import 'package:rewayah_academy/core/comptable/visibilite_montants.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/features/comptable/tresorerie/tresorerie_page.dart';

import '../../../support/harnais.dart';

/// Un montant en USD, en unites entieres.
Montant usd(int unites) => Montant(unites * 100, 'USD');

/// Un appel a `transferer`.
typedef AppelTransfert = ({
  Coffre origine,
  Coffre destination,
  Montant montant,
  String cle,
});

/// La tresorerie de test.
class FausseTresorerie implements PortTresorerie {
  /// La synthese rendue.
  SyntheseTresorerie synthese = SyntheseTresorerie(
    detenue: usd(1000),
    libre: usd(300),
    protegee: usd(650),
    enTransit: usd(50),
  );

  /// Les coffres rendus (dans le desordre expres).
  List<SoldeCoffre> soldes = <SoldeCoffre>[
    for (final Coffre c in Coffre.values.reversed)
      SoldeCoffre(coffre: c, montant: usd(10 + c.index), partPourMille: 125),
  ];

  /// L'historique rendu.
  List<EntreeJournal> entrees = <EntreeJournal>[
    EntreeJournal(
      id: 'j1',
      date: DateTime(2026, 10, 1),
      initiateur: 'Amina Sow',
      objet: 'Trésorerie libre → Réserve stratégique',
      montant: usd(20),
      reference: 'MVT-1',
    ),
  ];

  /// La prevision rendue (dans le desordre expres).
  List<LignePrevision> lignes = <LignePrevision>[
    LignePrevision(
      date: DateTime(2026, 10, 20),
      libelle: 'Deuxieme echeance',
      montant: usd(40),
    ),
    LignePrevision(
      date: DateTime(2026, 10, 5),
      libelle: 'Premiere echeance',
      montant: usd(30),
      entree: true,
    ),
  ];

  /// Les couples permis rendus.
  List<MouvementPermis> permis = <MouvementPermis>[
    MouvementPermis(
      origine: Coffre.tresorerieLibre,
      destination: Coffre.reserveStrategique,
      sensible: false,
      montantPropose: usd(600),
    ),
    const MouvementPermis(
      origine: Coffre.tresorerieLibre,
      destination: Coffre.chargesEssentielles,
      sensible: false,
    ),
  ];

  /// Les couples refuses rendus.
  List<MouvementBloque> bloques = const <MouvementBloque>[
    MouvementBloque(
      origine: Coffre.reserveStrategique,
      destination: Coffre.tresorerieLibre,
      raison: RaisonBlocage.capaciteAbsente,
    ),
  ];

  /// Ce que rend `transferer`, ou l'erreur qu'il jette.
  FutureOr<ResultatMouvement> Function(AppelTransfert appel) reponse =
      (AppelTransfert a) => ResultatMouvement(
        mouvementId: 'm-1',
        execute: true,
        journal: EntreeJournal(
          id: 'm-1',
          date: DateTime(2026, 10, 4),
          initiateur: 'Amina Sow',
          objet: 'Mouvement',
          reference: 'MVT-42',
        ),
      );

  /// L'erreur que jettent les lectures, quand on teste un echec.
  Object? erreurLecture;

  /// Une lecture qui ne repond jamais, quand on teste le chargement.
  bool enAttente = false;

  /// Les appels a `transferer`.
  final List<AppelTransfert> appels = <AppelTransfert>[];

  /// Le nombre de lectures de la synthese.
  int lecturesSynthese = 0;

  Future<T> _lire<T>(T valeur) {
    if (enAttente) return Completer<T>().future;
    final Object? e = erreurLecture;
    if (e != null) return Future<T>.error(e);
    return Future<T>.value(valeur);
  }

  @override
  Future<SyntheseTresorerie> resume() {
    lecturesSynthese++;
    return _lire(synthese);
  }

  @override
  Future<List<SoldeCoffre>> coffres() => _lire(soldes);

  @override
  Future<List<EntreeJournal>> historique(FiltreHistoriqueTresorerie filtre) =>
      _lire(entrees);

  @override
  Future<List<LignePrevision>> prevision() => _lire(lignes);

  @override
  Future<List<MouvementPermis>> mouvementsPermis() => _lire(permis);

  @override
  Future<List<MouvementBloque>> mouvementsBloques() => _lire(bloques);

  @override
  Future<ResultatMouvement> transferer({
    required Coffre origine,
    required Coffre destination,
    required Montant montant,
    required String cleIdempotence,
  }) async {
    final AppelTransfert appel = (
      origine: origine,
      destination: destination,
      montant: montant,
      cle: cleIdempotence,
    );
    appels.add(appel);
    return reponse(appel);
  }

  @override
  Future<List<EntreeJournal>> journal(String mouvementId) async =>
      const <EntreeJournal>[];
}

/// La politique de test.
class FaussePolitique implements PortPolitiqueReserve {
  /// Cree la politique.
  FaussePolitique({PolitiqueReserve? politique, IndicateursReserve? indic})
    : politiqueRendue = politique ?? politiqueFixe(),
      indicateursRendus = indic ?? indicateursFixes();

  /// La politique rendue.
  PolitiqueReserve politiqueRendue;

  /// Les indicateurs rendus.
  IndicateursReserve indicateursRendus;

  @override
  Future<PolitiqueReserve> politique() async => politiqueRendue;

  @override
  Future<IndicateursReserve> indicateurs() async => indicateursRendus;

  @override
  Future<PolitiqueReserve> enregistrer({
    required BrouillonPolitiqueReserve brouillon,
    required String cleIdempotence,
  }) async => politiqueRendue;

  @override
  Future<List<EntreeJournal>> journal() async => const <EntreeJournal>[];
}

/// Une politique a montant cible fixe, alimentation automatique fixe de
/// [auto] (10 USD par defaut).
PolitiqueReserve politiqueFixe({Montant? cible, Montant? auto}) =>
    PolitiqueReserve(
      version: 'v3',
      modeObjectif: ModeObjectifReserve.montantFixe,
      montantCible: cible ?? usd(5000),
      regleAlimentation: RegleAlimentation.montantFixe,
      montantAuto: auto ?? usd(10),
      cadence: CadenceAlimentation.mensuelle,
      retraitSoumisValidation: true,
      dateEffet: DateTime(2026, 9, 1),
    );

/// Une politique en couverture de [mois] mois.
PolitiqueReserve politiqueMois(int mois) => PolitiqueReserve(
  version: 'v4',
  modeObjectif: ModeObjectifReserve.couvertureMois,
  nombreMois: mois,
  regleAlimentation: RegleAlimentation.jusquAObjectif,
  cadence: CadenceAlimentation.clotureCycle,
  retraitSoumisValidation: true,
);

/// Des indicateurs en montant fixe, sous l'objectif.
IndicateursReserve indicateursFixes({Montant? objectif}) => IndicateursReserve(
  mode: ModeObjectifReserve.montantFixe,
  objectif: objectif ?? usd(5000),
  actuel: usd(3000),
  manque: usd(2000),
  atteintPourMille: 600,
  etat: EtatReserve.sousObjectif,
  derniereAllocation: DateTime(2026, 10, 1),
);

/// Des indicateurs en couverture de [mois] mois.
IndicateursReserve indicateursMois(int mois) => IndicateursReserve(
  mode: ModeObjectifReserve.couvertureMois,
  nombreMois: mois,
  objectif: usd(12000),
  actuel: usd(12000),
  manque: usd(0),
  atteintPourMille: 1000,
  etat: EtatReserve.atteint,
);

class _Visibilite extends VisibiliteMontants {
  _Visibilite(this._initiale);

  final bool _initiale;

  @override
  bool build() => _initiale;
}

/// Les surcharges de la page.
List<Override> surchargesTresorerie({
  required PortTresorerie tresorerie,
  FaussePolitique? politique,
  bool horsLigne = false,
  bool montantsAffiches = false,
}) => <Override>[
  portTresorerieProvider.overrideWithValue(tresorerie),
  portPolitiqueReserveProvider.overrideWithValue(
    politique ?? FaussePolitique(),
  ),
  horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(horsLigne)),
  visibiliteMontantsProvider.overrideWith(() => _Visibilite(montantsAffiches)),
];

/// Monte la page a [taille] et laisse les lectures aboutir.
Future<void> monterTresorerie(
  WidgetTester tester, {
  required FausseTresorerie tresorerie,
  FaussePolitique? politique,
  bool horsLigne = false,
  bool montantsAffiches = false,
  String? action,
  Size taille = const Size(390, 2400),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // Un nouvel hote a chaque montage : un ProviderScope deja monte garde ses
  // premieres surcharges.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    hote(
      TresoreriePage(action: action),
      surcharges: surchargesTresorerie(
        tresorerie: tresorerie,
        politique: politique,
        horsLigne: horsLigne,
        montantsAffiches: montantsAffiches,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// L'hote de la page sur un port quelconque (le port de production compris),
/// politique de production comprise.
Widget hotePage(PortTresorerie port) => hote(
  const TresoreriePage(),
  surcharges: <Override>[
    portTresorerieProvider.overrideWithValue(port),
    horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
    visibiliteMontantsProvider.overrideWith(() => _Visibilite(false)),
  ],
);
