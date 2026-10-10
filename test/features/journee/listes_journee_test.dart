// DASH-ENS-b (corrections des revues DASH-ENS-ROUTE-R et DASH-ENS-LISTES-R) :
// les trois listes de la Journee (« A terminer », « Remplacements
// confirmes », « Alertes utiles »), montees seules en VRAIES polices, a
// 320 px et texte a 200 %, en LTR comme en RTL, dans chacun de leurs etats.
//
// Ce que la contre-revue de DASH-ENS-ROUTE a trouve : l'etat vide d'« A
// terminer » coupait « transmission » en « tr / ansmission » a 320 px x2.
// Aucun test ne montait la page a cette taille ; celui-ci la monte dans ses
// cinq etats, et ses deux voisines dans les leurs.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/absence_remplacement.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart'
    show cahiersEnFileProvider;
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/features/journee/journee_page.dart';

import '../../capture/outil_capture.dart'
    show capturerVue, chargerPolicesDuDepot, masquerRubanDebug, sautSansCapture;
import '../../support/aucun_mot_coupe.dart';
import '../../support/harnais.dart';
import '../../support/hors_ligne_une_fois.dart';

final DateTime _maintenant = DateTime(2026, 9, 28, 16, 10);

final SeanceEnseignant _enDirect = SeanceEnseignant(
  id: 'live',
  debut: DateTime(2026, 9, 28, 16),
  fin: DateTime(2026, 9, 28, 16, 45),
  statut: StatutSeance.enCours,
  nbParticipants: 6,
  cahierDepose: false,
  groupeId: 'g-live',
  groupeLibelle: 'Al-Badr',
);

CahierEnRetard _cahier(String id, String classe, int jour) => CahierEnRetard(
  seanceId: id,
  debut: DateTime(2026, 9, jour, 17),
  fin: DateTime(2026, 9, jour, 17, 45),
  nbParticipants: 3,
  heuresDeRetard: 30,
  groupeId: 'g-$id',
  groupeLibelle: classe,
);

PresenceParticipant _eleve(String prenom, EtatPresence etat) =>
    PresenceParticipant(
      profilId: 'p-$prenom',
      role: 'student',
      prenom: prenom,
      identifiantImmuable: 'id-$prenom',
      etat: etat,
      consolide: false,
    );

OffreRemplacement _remplacement(String classe, int jour) => OffreRemplacement(
  seanceId: 'r-$classe',
  classe: classe,
  debut: DateTime(2026, 10, jour, 18),
  fin: DateTime(2026, 10, jour, 18, 45),
  nbEleves: 4,
  groupeId: 'g-$classe',
);

class _RemplacementsFixes extends RemplacementsControleur {
  _RemplacementsFixes(this._depart);

  final List<OffreRemplacement> _depart;

  @override
  List<OffreRemplacement> build() => _depart;
}

/// Les etats mesures. `chargement` ne se termine jamais ; `erreur` echoue en
/// ligne ; `horsLigne` echoue sans reseau.
enum _Etat { chargement, contenu, vide, erreur, horsLigne }

List<Override> _surcharges(_Etat etat) {
  Future<T> lire<T>(T valeur) {
    if (etat == _Etat.chargement) return Completer<T>().future;
    if (etat == _Etat.erreur || etat == _Etat.horsLigne) {
      return Future<T>.error(StateError('reseau'));
    }
    return Future<T>.value(valeur);
  }

  final bool vide = etat == _Etat.vide;
  return <Override>[
    sourceSessionProvider.overrideWithValue(
      FausseSourceSession(
        const SessionState(
          resolue: true,
          role: AppRole.teacher,
          profileId: 'ens-1',
          householdId: 'h1',
          accountStatus: AccountStatus.active,
          lectureProfil: LectureProfil.presente,
        ),
      ),
    ),
    serviceReseauProvider.overrideWithValue(
      FauxServiceReseau(horsLigneRendu: etat == _Etat.horsLigne),
    ),
    serviceEnseignantProvider.overrideWithValue(FauxServiceEnseignant()),
    cahiersEnFileProvider.overrideWith((Ref _) async => const <String>{}),
    maintenantJourneeProvider.overrideWithValue(() => _maintenant),
    cahiersEnRetardProvider.overrideWith(
      (Ref _) => lire<List<CahierEnRetard>>(
        vide
            ? const <CahierEnRetard>[]
            : <CahierEnRetard>[
                _cahier('a', 'Al-Badr', 26),
                _cahier('b', 'As-Salam', 25),
                _cahier('c', 'Al-Fatiha', 23),
                _cahier('d', 'Al-Ikhlas', 22),
              ],
      ),
    ),
    seancesEnseignantProvider.overrideWith(
      (Ref _) => lire<List<SeanceEnseignant>>(<SeanceEnseignant>[_enDirect]),
    ),
    remplacementsConfirmesProvider.overrideWith(
      () => _RemplacementsFixes(
        vide
            ? const <OffreRemplacement>[]
            : <OffreRemplacement>[
                _remplacement('An-Nour', 2),
                _remplacement('Al-Fatiha', 1),
                _remplacement('Al-Ikhlas', 4),
                _remplacement('As-Salam', 3),
                _remplacement('Al-Kawthar', 5),
              ],
      ),
    ),
    presenceSeanceProvider('live').overrideWith(
      (Ref _) => Stream<List<PresenceParticipant>?>.value(
        vide
            ? const <PresenceParticipant>[]
            : <PresenceParticipant>[
                _eleve('Yasmine', EtatPresence.absente),
                _eleve('Ilyas', EtatPresence.deconnectee),
                _eleve('Maryam', EtatPresence.absente),
              ],
      ),
    ),
  ];
}

Future<void> _monter(
  WidgetTester tester,
  Widget page,
  _Etat etat, {
  required TextDirection direction,
  double largeur = 320,
  double echelle = 2,
  ThemeMode mode = ThemeMode.light,
  InterfaceMode interface = InterfaceMode.standard,
}) async {
  tester.view.physicalSize = Size(largeur, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: _surcharges(etat),
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(interface, Brightness.light),
          darkTheme: AppTheme.pour(interface, Brightness.dark),
          themeMode: mode,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (BuildContext contexte, Widget? app) => Directionality(
            textDirection: direction,
            child: MediaQuery(
              data: MediaQuery.of(contexte)
                  .copyWith(textScaler: TextScaler.linear(echelle)),
              child: app!,
            ),
          ),
          home: page,
        ),
      ),
    ),
  );
  // Pas de pumpAndSettle : le squelette pulse sans fin.
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  final Map<String, (Widget, List<_Etat>)> pages =
      <String, (Widget, List<_Etat>)>{
        'A terminer': (const ListeATerminerPage(), _Etat.values),
        // Une memoire synchrone : ni chargement, ni echec de lecture.
        'Remplacements': (
          const ListeRemplacementsPage(),
          <_Etat>[_Etat.contenu, _Etat.vide],
        ),
        'Alertes': (const ListeAlertesPage(), _Etat.values),
      };

  group(
    'Les listes de la Journee a 320 px, texte a 200 % : aucun mot coupe',
    () {
      for (final MapEntry<String, (Widget, List<_Etat>)> page
          in pages.entries) {
        for (final TextDirection direction in TextDirection.values) {
          for (final _Etat etat in page.value.$2) {
            testWidgets('${page.key} ${direction.name} ${etat.name}', (
              WidgetTester tester,
            ) async {
              await _monter(tester, page.value.$1, etat, direction: direction);
              expect(tester.takeException(), isNull);
              expect(motsCoupes(tester, find.byType(Scaffold)), isEmpty);
            });
          }
        }
      }
    },
  );

  // DASH-ENS-ROUTE-R, mineur 1 : sans reseau et sans valeur, la page dit
  // « hors ligne », pas « le serveur n'a pas repondu ».
  group('Sans reseau, une lecture ratee se dit hors ligne', () {
    for (final (String, Widget, String, String) cas
        in <(String, Widget, String, String)>[
          (
            'A terminer',
            const ListeATerminerPage(),
            t.enseignant.journee.aTerminerErreur,
            t.enseignant.journee.aTerminerSansDonnees,
          ),
          (
            'Alertes',
            const ListeAlertesPage(),
            t.enseignant.journee.alertesErreur,
            t.enseignant.journee.alertesSansDonnees,
          ),
        ]) {
      testWidgets('${cas.$1} : hors ligne', (WidgetTester tester) async {
        await _monter(
          tester,
          cas.$2,
          _Etat.horsLigne,
          direction: TextDirection.ltr,
          largeur: 390,
          echelle: 1,
        );
        final EtatSysteme etat = tester.widget<EtatSysteme>(
          find.byType(EtatSysteme),
        );
        expect(etat.nature, NatureEtat.horsLigne);
        expect(find.text(cas.$3), findsNothing);
        expect(etat.onAction, isNotNull);
        // EA-HL-DOUBLE-1 : le bloc dit ce qui manque, sans redire le reseau.
        expect(find.text(cas.$4), findsOneWidget);
        expectHorsLigneUneFois();
      });

      testWidgets('${cas.$1} : en ligne, l echec reste un echec serveur', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          cas.$2,
          _Etat.erreur,
          direction: TextDirection.ltr,
          largeur: 390,
          echelle: 1,
        );
        expect(
          tester.widget<EtatSysteme>(find.byType(EtatSysteme)).nature,
          NatureEtat.echecServeur,
        );
        expect(find.text(cas.$3), findsOneWidget);
      });
    }
  });

  // DASH-ENS-LISTES-R (contre-revue) : les nouvelles pages suivent le sens de
  // lecture. A 1440 px, la colonne bornee part du bord de debut : a gauche en
  // LTR, et a l'exact miroir, a droite, en RTL.
  group('En RTL, la colonne des listes est le miroir de LTR', () {
    final Finder colonne = find.byWidgetPredicate(
      (Widget w) =>
          w is ConstrainedBox &&
          w.constraints.maxWidth == AppPage.largeurReglages,
    );
    for (final MapEntry<String, (Widget, List<_Etat>)> page in pages.entries) {
      testWidgets(page.key, (WidgetTester tester) async {
        Future<Rect> rectangle(TextDirection direction) async {
          await _monter(
            tester,
            page.value.$1,
            _Etat.contenu,
            direction: direction,
            largeur: 1440,
            echelle: 1,
          );
          return tester.getRect(colonne);
        }

        final Rect ltr = await rectangle(TextDirection.ltr);
        final Rect rtl = await rectangle(TextDirection.rtl);
        expect(ltr.left, lessThan(1440 / 2));
        expect(rtl.right, greaterThan(1440 / 2));
        expect(rtl.right, moreOrLessEquals(1440 - ltr.left));
        expect(rtl.width, moreOrLessEquals(ltr.width));
      });
    }
  });

  // EA-HL-DOUBLE-1c : sombre, Interface guidee et 1440 des listes de la
  // Journee hors ligne (revue EA-HL-DOUBLE-1-R, m4). Sautees sans
  // CAPTURE_DIR.
  group('Capture EA-HL-DOUBLE-1c', skip: sautSansCapture, () {
    setUp(masquerRubanDebug);
    for (final (String, Widget) page in <(String, Widget)>[
      ('a_terminer', const ListeATerminerPage()),
      ('alertes', const ListeAlertesPage()),
    ]) {
      for (final (String, double, ThemeMode, InterfaceMode) cas
          in <(String, double, ThemeMode, InterfaceMode)>[
            ('390_sombre', 390, ThemeMode.dark, InterfaceMode.standard),
            ('390_guidee', 390, ThemeMode.light, InterfaceMode.enfant),
            ('1440_clair', 1440, ThemeMode.light, InterfaceMode.standard),
          ]) {
        testWidgets('${page.$1} ${cas.$1}', (WidgetTester tester) async {
          await _monter(
            tester,
            page.$2,
            _Etat.horsLigne,
            direction: TextDirection.ltr,
            largeur: cas.$2,
            echelle: 1,
            mode: cas.$3,
            interface: cas.$4,
          );
          tester.view.physicalSize = Size(cas.$2, 900);
          await tester.pump();
          expect(tester.takeException(), isNull);
          expectHorsLigneUneFois();
          debugPrint(
            'PNG ${await capturerVue(tester, 'ea_hl_double1_journee_${page.$1}_sans_donnees_${cas.$1}')}',
          );
        });
      }
    }
  });

  // EA-HL-DOUBLE-1 (reprise) : captures de preuve des listes de la Journee
  // hors ligne sans donnees, LTR et RTL, texte x2. Sautees sans CAPTURE_DIR.
  group('Capture EA-HL-DOUBLE-1', skip: sautSansCapture, () {
    setUp(masquerRubanDebug);
    for (final (String, Widget) page in <(String, Widget)>[
      ('a_terminer', const ListeATerminerPage()),
      ('alertes', const ListeAlertesPage()),
    ]) {
      for (final (String, double, double, TextDirection) cas
          in <(String, double, double, TextDirection)>[
            ('390', 390, 1, TextDirection.ltr),
            ('320x2', 320, 2, TextDirection.ltr),
            ('320x2_rtl', 320, 2, TextDirection.rtl),
          ]) {
        testWidgets('${page.$1} ${cas.$1}', (WidgetTester tester) async {
          await _monter(
            tester,
            page.$2,
            _Etat.horsLigne,
            direction: cas.$4,
            largeur: cas.$2,
            echelle: cas.$3,
          );
          tester.view.physicalSize = Size(cas.$2, 900);
          await tester.pump();
          expect(tester.takeException(), isNull);
          expectHorsLigneUneFois();
          debugPrint(
            'PNG ${await capturerVue(tester, 'ea_hl_double1_journee_${page.$1}_sans_donnees_${cas.$1}_clair')}',
          );
        });
      }
    }
  });
}
