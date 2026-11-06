// CAND-PHOTO (06/11/2026) : la carte de l'accord de publication et son
// adaptateur. Ce que le test prouve : la case donne l'accord a la version
// affichee ; l'accord donne se lit signe du nom rendu par le serveur ; le
// retrait passe par une confirmation qui dit l'effet, et n'est offert qu'au
// Profil ; sans lot serveur, rien n'est rendu ; un refus se dit sans code ;
// l'adaptateur envoie la version et traduit les refus.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/port_accord_publication.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/candidature/accord_publication.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../support/harnais.dart';

class _FauxPort implements PortAccordPublication {
  _FauxPort({this.enCours = false, this.panne = false});

  bool enCours;
  bool panne;
  final List<String> gestes = <String>[];

  AccordPublication get _etat => AccordPublication(
    versionCourante: 'publication-2026-11-v1',
    enCours: enCours,
    version: enCours ? 'publication-2026-11-v1' : null,
    nomSigne: enCours ? 'Ibrahima Keita' : null,
    accepteLe: enCours ? DateTime(2026, 11, 6) : null,
  );

  @override
  Future<AccordPublication> lire() async => _etat;

  @override
  Future<AccordPublication> accepter(String version) async {
    gestes.add('accepter:$version');
    if (panne) throw const AccordPublicationRefuse('version_perimee');
    enCours = true;
    return _etat;
  }

  @override
  Future<AccordPublication> retirer() async {
    gestes.add('retirer');
    enCours = false;
    return _etat;
  }
}

Future<void> _monter(
  WidgetTester tester,
  PortAccordPublication? port, {
  bool retirable = false,
}) async {
  await tester.pumpWidget(
    hote(
      Scaffold(
        body: SingleChildScrollView(
          child: CarteAccordPublication(retirable: retirable),
        ),
      ),
      surcharges: <Override>[
        portAccordPublicationProvider.overrideWithValue(port),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('la carte', () {
    testWidgets('sans accord : la case donne l accord a la version affichee', (
      WidgetTester tester,
    ) async {
      final _FauxPort port = _FauxPort();
      await _monter(tester, port);
      expect(find.text(t.candidatsFlux.publication.texte), findsOneWidget);
      expect(find.byKey(CarteAccordPublication.signatureKey), findsNothing);
      await tester.tap(find.byKey(CarteAccordPublication.caseKey));
      await tester.pumpAndSettle();
      expect(port.gestes, <String>['accepter:publication-2026-11-v1']);
      expect(find.byKey(CarteAccordPublication.signatureKey), findsOneWidget);
      expect(find.textContaining('Ibrahima Keita'), findsOneWidget);
      // Au recapitulatif, pas de retrait.
      expect(find.byKey(CarteAccordPublication.retirerKey), findsNothing);
    });

    testWidgets(
      'au Profil : retirer passe par une confirmation qui dit l effet',
      (WidgetTester tester) async {
        final _FauxPort port = _FauxPort(enCours: true);
        await _monter(tester, port, retirable: true);
        await tester.tap(find.byKey(CarteAccordPublication.retirerKey));
        await tester.pumpAndSettle();
        expect(
          find.text(t.candidatsFlux.publication.retirerConsequence),
          findsOneWidget,
        );
        expect(port.gestes, isEmpty);
        await tester.tap(find.text(t.candidatsFlux.publication.retirer).last);
        await tester.pumpAndSettle();
        expect(port.gestes, <String>['retirer']);
        expect(find.byKey(CarteAccordPublication.caseKey), findsOneWidget);
      },
    );

    testWidgets('un refus se dit sans code, rien n est coche', (
      WidgetTester tester,
    ) async {
      final _FauxPort port = _FauxPort(panne: true);
      await _monter(tester, port);
      await tester.tap(find.byKey(CarteAccordPublication.caseKey));
      await tester.pumpAndSettle();
      expect(find.text(t.candidatsFlux.publication.echec), findsOneWidget);
      expect(find.byKey(CarteAccordPublication.signatureKey), findsNothing);
      expect(find.textContaining('version_perimee'), findsNothing);
    });

    testWidgets('sans lot serveur : la carte n est pas rendue', (
      WidgetTester tester,
    ) async {
      await _monter(tester, null);
      expect(
        find.byKey(const ValueKey<String>('accord-publication')),
        findsNothing,
      );
    });
  });

  group('l adaptateur', () {
    late List<(String, Map<String, dynamic>?)> appels;
    late Object? reponse;
    Exception? erreur;

    AccordPublicationSupabase adaptateur() =>
        AccordPublicationSupabase.avecAppel((
          String nom, [
          Map<String, dynamic>? params,
        ]) async {
          appels.add((nom, params));
          if (erreur != null) throw erreur!;
          return reponse;
        });

    setUp(() {
      appels = <(String, Map<String, dynamic>?)>[];
      reponse = null;
      erreur = null;
    });

    test('accepter envoie la version ; l etat est lu', () async {
      reponse = <String, dynamic>{
        'versionCourante': 'publication-2026-11-v1',
        'enCours': true,
        'version': 'publication-2026-11-v1',
        'nomSigne': 'Ibrahima Keita',
        'accepteLe': '2026-11-06T23:00:00Z',
      };
      final AccordPublication a = await adaptateur().accepter(
        'publication-2026-11-v1',
      );
      expect(appels.single.$1, 'accepter_accord_publication');
      expect(appels.single.$2, <String, dynamic>{
        'p_version': 'publication-2026-11-v1',
      });
      expect(a.enCours, isTrue);
      expect(a.nomSigne, 'Ibrahima Keita');
    });

    test('un refus rendu devient un refus type', () async {
      reponse = <String, dynamic>{'erreur': 'version_perimee'};
      expect(
        adaptateur().accepter('x'),
        throwsA(
          isA<AccordPublicationRefuse>().having(
            (AccordPublicationRefuse e) => e.code,
            'code',
            'version_perimee',
          ),
        ),
      );
    });

    test('42501 : permission insuffisante', () async {
      erreur = const PostgrestException(message: 'refus', code: '42501');
      expect(adaptateur().lire(), throwsA(isA<PermissionInsuffisante>()));
    });
  });
}
