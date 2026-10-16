// IMM-FRONT-1 (L2-07) : le matricule affiche, le role a cote, la copie.
// Source : DECISION-IMMATRICULATION-2026-10-12 section 1.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/identite/matricule_demo.dart';
import 'package:rewayah_academy/core/identite/matricule_supabase.dart';
import 'package:rewayah_academy/core/identite/port_matricule.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/compte/compte_page.dart';
import 'package:rewayah_academy/features/compte/ligne_matricule.dart';

import '../../support/harnais.dart';

const Matricule _eleve = Matricule(
  valeur: 'RA-26-4817',
  role: RoleAffiche.eleve,
);

Widget _ligne(PortMatricule port) => hote(
  const Material(child: LigneMatricule(profileId: 'p1')),
  surcharges: <Override>[portMatriculeProvider.overrideWithValue(port)],
);

Future<void> _taille(WidgetTester tester, double largeur) async {
  tester.view.physicalSize = Size(largeur, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _langue(WidgetTester tester, AppLocale langue) async {
  LocaleSettings.setLocaleSync(langue);
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
}

void main() {
  // L'arabe se charge hors du temps simule des tests (sinon l'attente pend).
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });

  for (final double largeur in const <double>[390, 1440]) {
    for (final AppLocale langue in const <AppLocale>[
      AppLocale.fr,
      AppLocale.ar,
    ]) {
      testWidgets('${largeur.toInt()} ${langue.languageCode} : valeur, role '
          'a cote, valeur de gauche a droite', (WidgetTester tester) async {
        await _taille(tester, largeur);
        await _langue(tester, langue);
        await tester.pumpWidget(
          _ligne(const MatriculeDemo(<String, Matricule>{'p1': _eleve})),
        );
        await tester.pumpAndSettle();

        expect(find.text('RA-26-4817'), findsOneWidget);
        final Directionality sens = tester.widget<Directionality>(
          find
              .ancestor(
                of: find.byKey(LigneMatricule.valeurKey),
                matching: find.byType(Directionality),
              )
              .first,
        );
        expect(sens.textDirection, TextDirection.ltr);
        final String phrase = t.compte.matricule(valeur: '', role: 'Élève');
        expect(phrase.isNotEmpty, isTrue);
        expect(
          find.textContaining(
            libelleRoleAffiche(RoleAffiche.eleve),
            findRichText: true,
          ),
          findsOneWidget,
        );
        expect(find.text('RA-26-4817-E'), findsNothing);
        expect(find.byKey(LigneMatricule.copierKey), findsOneWidget);
      });
    }
  }

  testWidgets(
    'copie : la valeur entre dans le presse-papiers, puis « Copie »',
    (WidgetTester tester) async {
      await _langue(tester, AppLocale.fr);
      String? copie;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall appel) async {
          if (appel.method == 'Clipboard.setData') {
            copie =
                (appel.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        _ligne(const MatriculeDemo(<String, Matricule>{'p1': _eleve})),
      );
      await tester.pumpAndSettle();
      expect(find.text('Copier'), findsOneWidget);

      await tester.tap(find.byKey(LigneMatricule.copierKey));
      await tester.pumpAndSettle();

      expect(copie, 'RA-26-4817');
      expect(find.text('Copié'), findsOneWidget);
    },
  );

  testWidgets('matricule indisponible : aucune ligne, aucun bouton', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_ligne(const MatriculeDemo()));
    await tester.pumpAndSettle();
    expect(find.byKey(LigneMatricule.valeurKey), findsNothing);
    expect(find.byKey(LigneMatricule.copierKey), findsNothing);
    expect(find.textContaining('Matricule'), findsNothing);
  });

  testWidgets('lecture en erreur : meme chose qu indisponible', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_ligne(_PortEnErreur()));
    await tester.pumpAndSettle();
    expect(find.byKey(LigneMatricule.copierKey), findsNothing);
  });

  testWidgets('Mon compte : la ligne apparait sous le nom (390, arabe)', (
    WidgetTester tester,
  ) async {
    await _taille(tester, 390);
    await _langue(tester, AppLocale.ar);
    await tester.pumpWidget(
      hote(
        const ComptePage(),
        surcharges: <Override>[
          sourceSessionProvider.overrideWithValue(
            FausseSourceSession(
              const SessionState(
                resolue: true,
                role: AppRole.student,
                profileId: 'p1',
                accountStatus: AccountStatus.active,
              ),
            ),
          ),
          portMatriculeProvider.overrideWithValue(
            const MatriculeDemo(<String, Matricule>{'p1': _eleve}),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('RA-26-4817'), findsOneWidget);
    expect(find.byKey(LigneMatricule.copierKey), findsOneWidget);
  });

  testWidgets('fiche de l enfant : le tuteur voit son matricule', (
    WidgetTester tester,
  ) async {
    await _taille(tester, 390);
    await tester.pumpWidget(
      hote(
        const Material(
          child: SingleChildScrollView(child: LigneMatricule(profileId: 'e1')),
        ),
        surcharges: <Override>[
          portMatriculeProvider.overrideWithValue(
            const MatriculeDemo(<String, Matricule>{
              'e1': Matricule(valeur: 'RA-26-0042', role: RoleAffiche.eleve),
            }),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('RA-26-0042'), findsOneWidget);
  });

  group('matriculeDepuisLigne', () {
    test('une ligne valide donne valeur et role', () {
      final Matricule? m = matriculeDepuisLigne(<String, dynamic>{
        'immutable_id': 'RA-26-4817',
        'role': 'guardian',
      });
      expect(m?.valeur, 'RA-26-4817');
      expect(m?.role, RoleAffiche.tuteur);
    });

    test('ancien code, ligne absente ou role inconnu : null', () {
      expect(matriculeDepuisLigne(null), isNull);
      expect(
        matriculeDepuisLigne(<String, dynamic>{
          'immutable_id': 'STUD-FA-000001',
          'role': 'student',
        }),
        isNull,
      );
      expect(
        matriculeDepuisLigne(<String, dynamic>{
          'immutable_id': 'RA-26-4817',
          'role': 'autre',
        }),
        isNull,
      );
    });
  });
}

class _PortEnErreur implements PortMatricule {
  @override
  Future<Matricule?> matriculeDe(String profileId) =>
      Future<Matricule?>.error(StateError('illisible'));
}
