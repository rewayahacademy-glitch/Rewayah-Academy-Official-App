// PAIEMENT-FAMILLE-ACCES (D7, 23/11/2026) : la dette de la famille, dite en tete
// du Foyer. Montant, motif, date et blocage viennent de `ma_dette_famille()` ;
// chargement, vide (rien), erreur, hors ligne et source absente (rien).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_dette_famille.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/finance/dette_famille.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/foyer/port_creation_profil_eleve.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_observation/libelles_observation.dart';
import 'package:rewayah_academy/core/tc_observation/port_politique_observation.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/foyer/carte_dette_famille.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;

class _Connecte extends SessionControleur {
  @override
  SessionState build() => const SessionState(
    resolue: true,
    role: AppRole.guardian,
    profileId: 'p-tuteur',
    accountStatus: AccountStatus.active,
    lectureProfil: LectureProfil.presente,
  );
}

class _Port implements PortDetteFamille {
  _Port(this._lecture);
  final Future<DetteFamille> Function() _lecture;
  @override
  Future<DetteFamille> lire() => _lecture();
}

void main() {
  const Map<String, Object?> reponse = <String, Object?>{
    'ouverte': true,
    'total_mineur': 1500,
    'lignes': <Object?>[
      <String, Object?>{
        'id': 'd1',
        'montant_mineur': 1500,
        'devise': 'USD',
        'motif': 'frais_contestation_perdue',
        'cree_le': '2026-11-24T10:00:00Z',
      },
    ],
  };

  Future<void> monter(
    WidgetTester tester,
    Future<DetteFamille> Function() lecture, {
    bool horsLigne = false,
    Size taille = const Size(390, 844),
  }) async {
    tester.view.physicalSize = taille;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sessionProvider.overrideWith(_Connecte.new),
          portDetteFamilleProvider.overrideWithValue(_Port(lecture)),
          horsLigneProvider.overrideWith(
            (Ref ref) => Stream<bool>.value(horsLigne),
          ),
        ],
        child: TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: AppLocale.fr.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const Scaffold(
              body: SingleChildScrollView(child: CarteDetteFamille()),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('une dette ouverte : montant, motif, date et blocage dits', (
    WidgetTester tester,
  ) async {
    await monter(tester, () async => DetteFamille.depuisJson(reponse));
    await tester.pumpAndSettle();
    expect(find.byKey(CarteDetteFamille.cle), findsOneWidget);
    expect(find.textContaining('15'), findsWidgets);
    expect(find.textContaining('contestation bancaire perdue'), findsOneWidget);
    expect(find.textContaining('2026'), findsOneWidget);
    expect(find.textContaining('Contactez la direction'), findsOneWidget);
    expect(find.textContaining('frais_contestation'), findsNothing);
  });

  testWidgets('sur ordinateur, le bandeau garde une largeur de lecture', (
    WidgetTester tester,
  ) async {
    await monter(
      tester,
      () async => DetteFamille.depuisJson(reponse),
      taille: const Size(1440, 900),
    );
    await tester.pumpAndSettle();
    final double largeur = tester
        .getSize(find.byKey(CarteDetteFamille.cle))
        .width;
    expect(largeur, lessThanOrEqualTo(840));
  });

  testWidgets('aucune dette : rien du tout', (WidgetTester tester) async {
    await monter(
      tester,
      () async => DetteFamille.depuisJson(<String, Object?>{
        'ouverte': false,
        'total_mineur': 0,
        'lignes': <Object?>[],
      }),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(CarteDetteFamille.cle), findsNothing);
    expect(find.textContaining('Dette'), findsNothing);
  });

  testWidgets('source absente : rien (ni echec ni dette)', (
    WidgetTester tester,
  ) async {
    await monter(
      tester,
      () => Future<DetteFamille>.error(const CapaciteIndisponible('D7')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(CarteDetteFamille.cle), findsNothing);
    expect(find.textContaining('pas pu être lue'), findsNothing);
  });

  testWidgets('erreur serveur : le dit, avec un moyen de reessayer', (
    WidgetTester tester,
  ) async {
    await monter(tester, () => Future<DetteFamille>.error(StateError('panne')));
    await tester.pumpAndSettle();
    expect(find.text(t.foyer.dette.indisponibleTitre), findsWidgets);
  });

  testWidgets('hors ligne : le dit, sans inventer une dette', (
    WidgetTester tester,
  ) async {
    await monter(
      tester,
      () => Future<DetteFamille>.error(StateError('reseau')),
      horsLigne: true,
    );
    await tester.pumpAndSettle();
    expect(find.text(t.foyer.dette.sansDonnees), findsWidgets);
    expect(find.byKey(CarteDetteFamille.cle), findsNothing);
  });

  testWidgets('chargement : un squelette, pas de dette', (
    WidgetTester tester,
  ) async {
    final Completer<DetteFamille> attente = Completer<DetteFamille>();
    await monter(tester, () => attente.future);
    await tester.pump();
    expect(find.byKey(CarteDetteFamille.cle), findsNothing);
    attente.complete(DetteFamille.aucune);
    await tester.pumpAndSettle();
  });

  test('un motif inconnu se dit sans code technique', () {
    expect(MotifDetteFamille.depuisSql('autre_chose'), MotifDetteFamille.autre);
    expect(libelleMotifDette(MotifDetteFamille.autre), isNot(contains('_')));
    expect(const Montant(1500, 'USD').mineur, 1500);
  });

  test('les refus du serveur ont leur phrase (jamais le repli « inconnu »)', () {
    final ResultatCreationProfil r = resultatDepuisRefus(
      const FunctionException(
        status: 403,
        details: <String, Object?>{
          'error':
              'DETTE_FAMILLE : une dette de la famille bloque ce nouvel achat',
        },
      ),
    );
    expect(
      r,
      isA<CreationRefusee>().having(
        (CreationRefusee c) => c.motif,
        'motif',
        MotifRefusCreation.detteFamille,
      ),
    );
    expect(
      MotifRefusObservation.depuisSql('place_eleve'),
      MotifRefusObservation.placeEleve,
    );
    expect(
      MotifRefusObservation.depuisSql('acces_suspendu'),
      MotifRefusObservation.accesSuspendu,
    );
    expect(
      libelleRefusObservation(MotifRefusObservation.placeEleve),
      t.tc.observation.refus.placeEleve,
    );
    expect(
      libelleRefusObservation(MotifRefusObservation.accesSuspendu),
      contains('paiement'),
    );
    expect(t.foyer.dette.achatBloque, contains('Contactez la direction'));
  });
}
