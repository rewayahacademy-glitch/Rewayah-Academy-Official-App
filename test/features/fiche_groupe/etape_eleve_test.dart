// CAHIER-C2 (06/11/2026) : l'etape du programme dans la fiche de l'eleve.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/suivi/port_suivi_pedagogique.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/widgets/groupe_reglages.dart';
import 'package:rewayah_academy/features/fiche_groupe/etape_eleve.dart';
import 'package:rewayah_academy/features/fiche_groupe/etape_eleve_supabase.dart';
import 'package:rewayah_academy/features/fiche_groupe/fiche_eleve_enseignant.dart';

import '../../support/harnais.dart';

class _Port implements PortEtapesEleves {
  _Port(this.reponse);

  final Map<String, EtapeEleve> reponse;
  final List<String> lues = <String>[];

  @override
  Future<Map<String, EtapeEleve>> etapesDeLaClasse(String groupeId) async {
    lues.add(groupeId);
    return reponse;
  }
}

Future<void> _fiche(
  WidgetTester tester, {
  required List<Override> surcharges,
  String? groupeId = 'c2',
}) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      Scaffold(
        body: SingleChildScrollView(
          child: FicheEleveEnseignant(
            eleve: EleveFiche(
              membre: const MembreSeance(
                studentId: 'e1',
                identifiantImmuable: 'RA-26-0001',
                prenom: 'Mariam',
              ),
              classe: 'An-Nour',
              groupeId: groupeId,
            ),
            onSignaler: () {},
          ),
        ),
      ),
      surcharges: surcharges,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  test('lecture : ligne complete, ligne illisible ecartee', () {
    final Map<String, EtapeEleve> etapes = etapesDepuisReponse(<Object?>[
      <String, Object?>{
        'student_id': 'e1',
        'etape_nom': 'Lire avec les voyelles',
        'objectifs': <Object?>['Lit le tanwin', '  ', null, 'Lit la chadda'],
        'duree_prevue_semaines': 14,
        'date_limite_semaines': 18,
        'date_limite': '2027-03-12',
      },
      <String, Object?>{'student_id': 'e2', 'etape_nom': ''},
      'pas une ligne',
    ]);
    expect(etapes.keys, <String>['e1']);
    final EtapeEleve e = etapes['e1']!;
    expect(e.objectifs, <String>['Lit le tanwin', 'Lit la chadda']);
    expect(e.dureePrevueSemaines, 14);
    expect(e.dateLimite, DateTime(2027, 3, 12));
    expect(etapesDepuisReponse(null), isEmpty);
  });

  testWidgets('la fiche montre l etape, ses objectifs et la date limite', (
    WidgetTester tester,
  ) async {
    final _Port port = _Port(<String, EtapeEleve>{
      'e1': EtapeEleve(
        studentId: 'e1',
        nom: 'Lire avec les voyelles',
        objectifs: const <String>['Lit le tanwin', 'Lit la chadda'],
        dureePrevueSemaines: 14,
        dateLimiteSemaines: 18,
        dateLimite: DateTime(2027, 3, 12),
      ),
    });
    await _fiche(
      tester,
      surcharges: <Override>[portEtapesElevesProvider.overrideWithValue(port)],
    );
    expect(port.lues, <String>['c2']);
    expect(find.text(t.enseignant.eleve.etape), findsOneWidget);
    expect(find.text('Lire avec les voyelles'), findsOneWidget);
    expect(find.text('Lit le tanwin\nLit la chadda'), findsOneWidget);
    expect(
      find.text(
        LibellesGroupe.insecable(
          t.enseignant.eleve.aFinirAvantDate(
            numero: '12',
            mois: t.commun.dates.mois[2],
            annee: '2027',
            prevue: '14',
          ),
        ),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('sans date de depart connue : la duree au plus, sans date '
      'supposee', (WidgetTester tester) async {
    await _fiche(
      tester,
      surcharges: <Override>[
        portEtapesElevesProvider.overrideWithValue(
          _Port(<String, EtapeEleve>{
            'e1': const EtapeEleve(
              studentId: 'e1',
              nom: 'Les lettres',
              objectifs: <String>[],
              dureePrevueSemaines: 8,
              dateLimiteSemaines: 10,
            ),
          }),
        ),
      ],
    );
    expect(find.text('Les lettres'), findsOneWidget);
    expect(
      find.text(
        LibellesGroupe.insecable(
          t.enseignant.eleve.aFinirEnSemaines(limite: '10'),
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(t.enseignant.eleve.objectifsEtape), findsNothing);
  });

  testWidgets('aucune etape publiee : la fiche le dit, sans etape supposee', (
    WidgetTester tester,
  ) async {
    await _fiche(tester, surcharges: const <Override>[]);
    expect(find.text(t.enseignant.eleve.etapeNonPubliee), findsOneWidget);
  });

  testWidgets('eleve qui a declare savoir lire : « en attente de l entretien '
      'de lecture », la meme reponse que la lecture unique (SOCLE-PROGRAMME)', (
    WidgetTester tester,
  ) async {
    await _fiche(
      tester,
      surcharges: <Override>[
        portSuiviPedagogiqueProvider.overrideWithValue(const _SuiviAttente()),
      ],
    );
    expect(find.text(t.enseignant.eleve.etapeAttenteEntretien), findsOneWidget);
    expect(find.text(t.enseignant.eleve.etapeNonPubliee), findsNothing);
  });

  testWidgets('lecture de l etape en echec (fonction absente pendant le '
      'deploiement) : etat d erreur honnete, pas « pas encore d etape '
      'publiee »', (WidgetTester tester) async {
    await _fiche(
      tester,
      surcharges: <Override>[
        portSuiviPedagogiqueProvider.overrideWithValue(const _SuiviEchec()),
      ],
    );
    // « Non renseigne » se lit deja sur d'autres lignes de la fiche : on le cherche dans le
    // groupe qui porte la ligne de l'etape.
    final Finder groupeEtape = find.ancestor(
      of: find.text(t.enseignant.eleve.etape),
      matching: find.byType(GroupeReglages),
    );
    expect(
      find.descendant(
        of: groupeEtape,
        matching: find.text(t.enseignant.eleve.nonRenseigne),
      ),
      findsOneWidget,
    );
    expect(find.text(t.enseignant.eleve.etapeNonPubliee), findsNothing);
    expect(find.text(t.enseignant.eleve.etapeAttenteEntretien), findsNothing);
  });

  testWidgets('sans Classe connue : aucune lecture, aucun bloc', (
    WidgetTester tester,
  ) async {
    final _Port port = _Port(const <String, EtapeEleve>{});
    await _fiche(
      tester,
      groupeId: null,
      surcharges: <Override>[portEtapesElevesProvider.overrideWithValue(port)],
    );
    expect(port.lues, isEmpty);
    expect(find.text(t.enseignant.eleve.etape), findsNothing);
  });
}

class _SuiviAttente implements PortSuiviPedagogique {
  const _SuiviAttente();

  @override
  Future<SuiviPedagogique?> pourEleve(String eleveId) async =>
      const SuiviPedagogique.attenteEntretien();
}

class _SuiviEchec implements PortSuiviPedagogique {
  const _SuiviEchec();

  @override
  Future<SuiviPedagogique?> pourEleve(String eleveId) async =>
      throw StateError('etape_eleve_lecture absente');
}
