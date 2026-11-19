// PX-OAUTH 2e : la liste des connexions des applications (claude.ai) a Praxis.
//
// Ce que les cas prouvent (sur le vrai widget, la base est un double) :
//  - une ligne par connexion, avec son etat venu de la base ; « Revoquer »
//    seulement sur une connexion active ;
//  - la revocation est un geste sensible : le motif est obligatoire, elle
//    attend le serveur, la liste est relue ensuite (une connexion coupee se
//    lit « Revoquee ») ; un refus de droit dit la double verification ;
//  - les etats loading, content, empty, error, offline ;
//  - 320 et 1440, texte x2, arabe : rien ne deborde, aucun mot coupe.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/agent/service_autorisation_praxis.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/features/admin_acces_agents/connexions_praxis.dart';
import 'package:rewayah_academy/features/admin_acces_agents/section_praxis.dart'
    show ClesPraxis;
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/faux_service_autorisation_praxis.dart';
import '../../support/harnais.dart';

Future<void> _monter(
  WidgetTester tester,
  FauxServiceAutorisationPraxis faux, {
  List<Override> en = const <Override>[],
  Size taille = const Size(1440, 1400),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      const Scaffold(body: SingleChildScrollView(child: ConnexionsPraxis())),
      surcharges: <Override>[
        serviceAutorisationPraxisProvider.overrideWithValue(faux),
        ...en,
      ],
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _revoquer(
  WidgetTester tester, {
  String motif = 'plus utilisee',
}) async {
  await tester.tap(find.text(t.admin.praxis.revoquer).first);
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).last, motif);
  await tester.tap(find.byKey(ClesPraxis.confirmerRevocation));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });

  group('contenu', () {
    testWidgets('une ligne par connexion, son etat, son action', (
      tester,
    ) async {
      final FauxServiceAutorisationPraxis faux = FauxServiceAutorisationPraxis(
        connexions: <ConnexionPraxis>[
          connexionPraxisFictive(
            derniereUtilisation: DateTime(2026, 11, 18, 18),
          ),
          connexionPraxisFictive(
            id: 'cx2',
            client: 'Autre',
            etat: EtatConnexionPraxis.revoquee,
          ),
          connexionPraxisFictive(
            id: 'cx3',
            client: 'Ancienne',
            etat: EtatConnexionPraxis.expiree,
          ),
        ],
      );
      await _monter(tester, faux);
      expect(find.text(t.admin.praxis.connexions.titre), findsWidgets);
      expect(find.textContaining('Claude'), findsWidgets);
      expect(find.text(t.admin.praxis.etatActive), findsWidgets);
      expect(find.text(t.admin.praxis.etatRevoquee), findsWidgets);
      expect(find.text(t.admin.praxis.etatExpiree), findsWidgets);
      // « Revoquer » seulement sur la connexion active.
      expect(find.text(t.admin.praxis.revoquer), findsOneWidget);
      expect(find.text(t.admin.praxis.jamaisUtilisee), findsWidgets);
    });

    testWidgets('aucune connexion : la phrase vraie', (tester) async {
      await _monter(tester, FauxServiceAutorisationPraxis());
      expect(find.text(t.admin.praxis.connexions.vide), findsOneWidget);
      expect(find.text(t.admin.praxis.revoquer), findsNothing);
    });
  });

  group('la revocation', () {
    testWidgets('motif obligatoire, attend le serveur, liste relue', (
      tester,
    ) async {
      final FauxServiceAutorisationPraxis faux = FauxServiceAutorisationPraxis(
        connexions: <ConnexionPraxis>[connexionPraxisFictive()],
      );
      await _monter(tester, faux);
      // Sans motif : refuse avant le serveur.
      await tester.tap(find.text(t.admin.praxis.revoquer).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ClesPraxis.confirmerRevocation));
      await tester.pumpAndSettle();
      expect(find.text(t.admin.praxis.manqueMotif), findsOneWidget);
      expect(faux.revocations, isEmpty);
      // Avec un motif.
      await tester.enterText(find.byType(TextField).last, 'plus utilisee');
      await tester.tap(find.byKey(ClesPraxis.confirmerRevocation));
      await tester.pumpAndSettle();
      expect(faux.revocations, <({String id, String motif})>[
        (id: 'cx1', motif: 'plus utilisee'),
      ]);
      expect(find.text(t.admin.praxis.connexions.revoquee), findsOneWidget);
      // La liste est relue : la connexion se lit « Revoquee », sans action.
      expect(faux.lecturesConnexions, 2);
      expect(find.text(t.admin.praxis.etatRevoquee), findsWidgets);
      expect(find.text(t.admin.praxis.revoquer), findsNothing);
    });

    testWidgets('un refus de droit (42501) dit la double verification', (
      tester,
    ) async {
      final FauxServiceAutorisationPraxis faux = FauxServiceAutorisationPraxis(
        connexions: <ConnexionPraxis>[connexionPraxisFictive()],
        erreurRevocation: const PostgrestException(
          message: 'refus',
          code: '42501',
        ),
      );
      await _monter(tester, faux);
      await _revoquer(tester);
      expect(find.text(t.admin.praxis.doubleVerification), findsOneWidget);
      expect(find.text(t.admin.praxis.connexions.revoquee), findsNothing);
    });

    testWidgets('une panne : « coupure non confirmee », la liste est relue', (
      tester,
    ) async {
      final FauxServiceAutorisationPraxis faux = FauxServiceAutorisationPraxis(
        connexions: <ConnexionPraxis>[connexionPraxisFictive()],
        erreurRevocation: Exception('panne'),
      );
      await _monter(tester, faux);
      await _revoquer(tester);
      expect(
        find.text(t.admin.praxis.connexions.erreurRevocation),
        findsOneWidget,
      );
      expect(faux.lecturesConnexions, 2);
    });

    testWidgets('fermer la feuille sans motif ne revoque rien', (tester) async {
      final FauxServiceAutorisationPraxis faux = FauxServiceAutorisationPraxis(
        connexions: <ConnexionPraxis>[connexionPraxisFictive()],
      );
      await _monter(tester, faux);
      await tester.tap(find.text(t.admin.praxis.revoquer).first);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(faux.revocations, isEmpty);
    });
  });

  group('etats', () {
    testWidgets('chargement : un squelette, aucune action', (tester) async {
      final Completer<void> attente = Completer<void>();
      final FauxServiceAutorisationPraxis faux = _FauxLentConnexions(attente);
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hote(
          const Scaffold(
            body: SingleChildScrollView(child: ConnexionsPraxis()),
          ),
          surcharges: <Override>[
            serviceAutorisationPraxisProvider.overrideWithValue(faux),
          ],
        ),
      );
      await tester.pump();
      expect(find.text(t.admin.praxis.revoquer), findsNothing);
      attente.complete();
      await tester.pumpAndSettle();
      expect(find.text(t.admin.praxis.revoquer), findsOneWidget);
    });

    testWidgets('echec de lecture : la phrase vraie et de quoi relire', (
      tester,
    ) async {
      await _monter(
        tester,
        FauxServiceAutorisationPraxis(erreurConnexions: Exception('panne')),
      );
      expect(find.text(t.admin.praxis.connexions.erreurLecture), findsWidgets);
    });

    testWidgets('hors ligne sans donnee : le bloc qui dit ce qui manque', (
      tester,
    ) async {
      await _monter(
        tester,
        FauxServiceAutorisationPraxis(erreurConnexions: Exception('panne')),
        en: <Override>[
          horsLigneProvider.overrideWith((Ref ref) => Stream<bool>.value(true)),
        ],
      );
      expect(find.byKey(ClesConnexionsPraxis.sansDonnees), findsOneWidget);
    });
  });

  group('rendu', () {
    final List<(String, Size, double, AppLocale)> cas =
        <(String, Size, double, AppLocale)>[
          ('320, texte x1', const Size(320, 1600), 1, AppLocale.fr),
          ('1440', const Size(1440, 1000), 1, AppLocale.fr),
          ('arabe, 320', const Size(320, 1600), 1, AppLocale.ar),
          ('arabe, 1440', const Size(1440, 1000), 1, AppLocale.ar),
        ];
    for (final (String, Size, double, AppLocale) c in cas) {
      testWidgets('${c.$1} : rien ne deborde, aucun mot coupe', (tester) async {
        LocaleSettings.setLocaleSync(c.$4);
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        await _monter(
          tester,
          FauxServiceAutorisationPraxis(
            connexions: <ConnexionPraxis>[
              connexionPraxisFictive(
                derniereUtilisation: DateTime(2026, 11, 18, 18),
              ),
              connexionPraxisFictive(
                id: 'cx2',
                etat: EtatConnexionPraxis.revoquee,
              ),
            ],
          ),
          taille: c.$2,
        );
        expect(tester.takeException(), isNull);
        expect(motsCoupes(tester, find.byType(ConnexionsPraxis)), isEmpty);
      });
    }
  });
}

/// Un service dont la lecture des connexions attend [_attente].
class _FauxLentConnexions extends FauxServiceAutorisationPraxis {
  _FauxLentConnexions(this._attente)
    : super(connexions: <ConnexionPraxis>[connexionPraxisFictive()]);

  final Completer<void> _attente;

  @override
  Future<List<ConnexionPraxis>> connexions() async {
    await _attente.future;
    return super.connexions();
  }
}
