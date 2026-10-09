// COUPE-MOTS-4 (1), appelants Controleur de `ChoiceCardGroup` : compte rendu
// (« nor / malement », « administ / ration » dans les descriptions),
// observation (nature, domaine, personne, eleve ; « obser / vation ») et
// complement d'un rapport. 320 px, texte x2, francais (LTR) et arabe (RTL),
// Interface standard et guidee.
// Contre-epreuve : sur l'ancien code (5a52ff30), le compte rendu et
// l'observation echouent en nommant les mots coupes.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/controleur/complement_rapport_page.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle_page.dart';
import 'package:rewayah_academy/features/controleur/historique_controleur.dart';
import 'package:rewayah_academy/features/controleur/observation_controle.dart';
import 'package:rewayah_academy/features/controleur/observation_controle_page.dart';

import 'support_coupe_mots_4.dart';

final CompteRenduEnSuspens _visite = CompteRenduEnSuspens(
  seanceId: 'seance-A',
  classe: 'Classe Al-Fajr',
  debut: DateTime(2026, 9, 28, 16),
  missionId: 'mission-A',
);

class _Envoi implements EnvoiCompteRendu {
  @override
  Future<void> transmettreVisite(String seanceId) async {}

  @override
  Future<void> envoyer(String seanceId, ChoixCompteRendu choix) async {}

  @override
  Future<void> envoyerObservation(
    String seanceId,
    ObservationControle observation,
  ) async {}
}

class _Historique implements PortHistorique {
  @override
  Future<List<RapportControle>> rapports() async => <RapportControle>[];

  @override
  Future<ComplementRapport> ajouterComplement(
    String rapportId, {
    required String texte,
    String? motif,
  }) async => ComplementRapport(date: DateTime(2026, 9, 25, 9), texte: texte);
}

List<Override> _surcharges() => <Override>[
  visitesObserveesProvider.overrideWith(
    () => VisitesObservees(<String, CompteRenduEnSuspens>{
      _visite.seanceId: _visite,
    }),
  ),
  envoiCompteRenduProvider.overrideWithValue(_Envoi()),
  rosterControleProvider.overrideWith(
    (Ref _) async => const <EleveRoster>[
      EleveRoster(id: 'e1', prenom: 'Mariam', initialeNom: 'S'),
      EleveRoster(id: 'e2', prenom: 'Abd al-Rahman', initialeNom: 'B'),
    ],
  ),
  portHistoriqueProvider.overrideWithValue(_Historique()),
];

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  preparerCoupeMots4();

  for (final AppLocale langue in languesCoupeMots4) {
    for (final InterfaceMode interface in interfacesCoupeMots4) {
      final String cas = '${langue.name} ${nomInterface(interface)} 320 x2';

      testWidgets('$cas : compte rendu', (WidgetTester tester) async {
        await monterCoupeMots4(
          tester,
          () => CompteRenduControlePage(seanceId: _visite.seanceId),
          langue: langue,
          interface: interface,
          surcharges: _surcharges(),
        );
        await tester.pumpAndSettle();
        verifierCartesDeChoixEntieres(tester);
      });

      testWidgets('$cas : observation, chaque etape a cartes', (
        WidgetTester tester,
      ) async {
        await monterCoupeMots4(
          tester,
          () => ObservationControlePage(seanceId: _visite.seanceId),
          langue: langue,
          interface: interface,
          surcharges: _surcharges(),
        );
        await tester.pumpAndSettle();
        // Etape 1 : nature.
        verifierCartesDeChoixEntieres(tester);
        await _toucher(
          tester,
          find.byKey(
            ObservationControlePage.cleNature(NatureObservation.aSuivre),
          ),
        );
        await _toucher(tester, find.text(t.commun.continuer).last);
        // Etape 2 : domaine.
        verifierCartesDeChoixEntieres(tester);
        await _toucher(
          tester,
          find.byKey(
            ObservationControlePage.cleDomaine(DomaineObservation.pedagogie),
          ),
        );
        await _toucher(tester, find.text(t.commun.continuer).last);
        // Etape 3 : personne concernee, puis la liste des eleves.
        verifierCartesDeChoixEntieres(tester);
        await _toucher(
          tester,
          find.byKey(
            ObservationControlePage.clePersonne(PersonneConcernee.elevePrecis),
          ),
        );
        verifierCartesDeChoixEntieres(tester);
      });

      testWidgets('$cas : complement d un rapport', (
        WidgetTester tester,
      ) async {
        await monterCoupeMots4(
          tester,
          () => ComplementRapportPage(
            rapport: RapportControle(
              id: 'r1',
              missionId: 'm1',
              classe: 'Al-Badr',
              enseignant: 'Sayyid Karim',
              debut: DateTime(2026, 9, 24, 10),
              dureeObservee: const Duration(minutes: 20),
              statut: StatutRapport.envoye,
              choix: ChoixCompteRendu.rienASignaler,
            ),
            onRetour: () {},
            onTermine: (RapportControle _) {},
          ),
          langue: langue,
          interface: interface,
          surcharges: _surcharges(),
        );
        await tester.pumpAndSettle();
        verifierCartesDeChoixEntieres(tester);
      });
    }
  }
}
