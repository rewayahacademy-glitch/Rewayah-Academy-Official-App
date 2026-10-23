// LIVE-PAUSE-01 : le reglage de la pause dans la fiche de la classe.
//
// Les cinq etats (chargement, contenu, vide, erreur, hors ligne), l'etat
// « indisponible » de la production, la capacite lue (jamais le role), aucun
// bouton grise, la version perimee, 320 px texte x2, fr et ar, clair et sombre.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/pause_seance/pause_seance_demonstration.dart';
import 'package:rewayah_academy/core/pause_seance/port_pause_seance.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart'
    show horsLigneProvider;
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/bloc_asynchrone.dart';
import 'package:rewayah_academy/features/fiche_groupe/bloc_pause_classe.dart';

/// Un port dont le reglage est choisi par le test.
class _Port extends PauseSeanceDemonstration {
  _Port({this.lecture, this.ecriture});

  Future<ReglagePause> Function()? lecture;
  Object? ecriture;
  int ecritures = 0;
  ReglagePause? derniere;

  @override
  Future<ReglagePause> reglage(String groupeId) =>
      lecture != null ? lecture!() : super.reglage(groupeId);

  @override
  Future<ReglagePause> enregistrerReglage({
    required String groupeId,
    required bool actif,
    required int apresMinutes,
    required int dureeMinutes,
    required String versionAttendue,
    required String cleIdempotence,
  }) {
    ecritures++;
    if (ecriture != null) {
      return Future<ReglagePause>.error(ecriture!);
    }
    return super.enregistrerReglage(
      groupeId: groupeId,
      actif: actif,
      apresMinutes: apresMinutes,
      dureeMinutes: dureeMinutes,
      versionAttendue: versionAttendue,
      cleIdempotence: cleIdempotence,
    );
  }
}

Future<void> _poser(
  WidgetTester tester,
  PortPauseSeance port, {
  bool horsLigne = false,
  Size taille = const Size(390, 844),
  double echelle = 1,
  Brightness luminosite = Brightness.light,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        portPauseSeanceProvider.overrideWithValue(port),
        horsLigneProvider.overrideWith(
          (Ref _) => Stream<bool>.value(horsLigne),
        ),
      ],
      child: TranslationProvider(
        child: MediaQuery(
          data: MediaQueryData(
            size: taille,
            textScaler: TextScaler.linear(echelle),
          ),
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, luminosite),
            home: const Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: BlocPauseClasse(groupeId: 'g1'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Un texte a l'ecran, sans les isolats bidi ni les espaces insecables.
Finder _t(String attendu) => find.byWidgetPredicate((Widget w) {
  if (w is! Text || w.data == null) return false;
  final String brut = w.data!
      .replaceAll(RegExp('[\u2066-\u2069\u200e\u200f]'), '')
      .replaceAll('\u00a0', ' ');
  return brut == attendu;
});

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  testWidgets('chargement : un squelette, aucune commande', (
    WidgetTester tester,
  ) async {
    final Completer<ReglagePause> attente = Completer<ReglagePause>();
    await _poser(tester, _Port(lecture: () => attente.future));
    expect(find.text('Pause de la séance'), findsOneWidget);
    expect(find.byKey(BlocPauseClasse.cleInterrupteur), findsNothing);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('production : « pas encore disponible », aucune fausse bascule', (
    WidgetTester tester,
  ) async {
    await _poser(tester, const PauseSeanceIndisponible());
    expect(find.byKey(BlocPauseClasse.cleIndisponible), findsOneWidget);
    expect(
      find.text('La pause programmée n\'est pas encore disponible'),
      findsOneWidget,
    );
    expect(find.byType(Switch), findsNothing);
    expect(find.byKey(BlocPauseClasse.cleEnregistrer), findsNothing);
    // Aucun code technique a l'ecran.
    expect(find.textContaining('PAUSE-BR'), findsNothing);
  });

  testWidgets('contenu : le reglage servi, moment et duree choisis', (
    WidgetTester tester,
  ) async {
    await _poser(tester, _Port());
    expect(find.byType(Switch), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(find.byKey(BlocPauseClasse.cleMoment), findsOneWidget);
    expect(find.byKey(BlocPauseClasse.cleDuree), findsOneWidget);
    expect(_t('30 min'), findsWidgets);
    // Rien a enregistrer : le bouton n'existe pas (jamais grise).
    expect(find.byKey(BlocPauseClasse.cleEnregistrer), findsNothing);
  });

  testWidgets('modifier la duree, enregistrer, relire le reglage du serveur', (
    WidgetTester tester,
  ) async {
    final _Port port = _Port();
    await _poser(tester, port);
    await tester.tap(
      find.descendant(
        of: find.byKey(BlocPauseClasse.cleDuree),
        matching: _t('20 min'),
      ),
    );
    await tester.pump();
    expect(find.byKey(BlocPauseClasse.cleEnregistrer), findsOneWidget);
    await tester.tap(find.byKey(BlocPauseClasse.cleEnregistrer));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(port.ecritures, 1);
    expect((await port.reglage('g1')).dureeMinutes, 20);
    expect(find.text('Pause enregistrée.'), findsOneWidget);
    // Relu : plus rien a enregistrer.
    expect(find.byKey(BlocPauseClasse.cleEnregistrer), findsNothing);
  });

  testWidgets('vide : aucune pause programmee, ni moment ni duree', (
    WidgetTester tester,
  ) async {
    await _poser(
      tester,
      _Port(
        lecture: () async => const ReglagePause(
          actif: false,
          apresMinutes: 30,
          dureeMinutes: 10,
          version: 'v',
          peutModifier: true,
        ),
      ),
    );
    expect(find.text('Aucune pause'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(find.byKey(BlocPauseClasse.cleMoment), findsNothing);
    expect(find.byKey(BlocPauseClasse.cleDuree), findsNothing);
  });

  testWidgets('desactiver puis enregistrer envoie actif = faux', (
    WidgetTester tester,
  ) async {
    final _Port port = _Port();
    await _poser(tester, port);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(find.byKey(BlocPauseClasse.cleMoment), findsNothing);
    await tester.tap(find.byKey(BlocPauseClasse.cleEnregistrer));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect((await port.reglage('g1')).actif, isFalse);
  });

  testWidgets('erreur de lecture : un message et « Reessayer »', (
    WidgetTester tester,
  ) async {
    await _poser(
      tester,
      _Port(lecture: () => Future<ReglagePause>.error(StateError('x'))),
    );
    expect(find.byType(BlocAsynchrone<ReglagePause>), findsOneWidget);
    expect(find.text('Réessayer'), findsWidgets);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('sans la capacite de modifier : lecture seule, sans commande', (
    WidgetTester tester,
  ) async {
    await _poser(
      tester,
      _Port(
        lecture: () async => const ReglagePause(
          actif: true,
          apresMinutes: 45,
          dureeMinutes: 15,
          version: 'v',
          peutModifier: false,
        ),
      ),
    );
    expect(find.byType(Switch), findsNothing);
    expect(find.byKey(BlocPauseClasse.cleMoment), findsNothing);
    expect(find.byKey(BlocPauseClasse.cleEnregistrer), findsNothing);
    expect(
      _t('Seul l\'enseignant de la Classe règle la pause.'),
      findsOneWidget,
    );
    expect(find.textContaining('15'), findsWidgets);
  });

  testWidgets('version perimee : le dit, relit, n\'ecrase rien', (
    WidgetTester tester,
  ) async {
    final _Port port = _Port(ecriture: const ReglagePauseObsolete());
    await _poser(tester, port);
    await tester.tap(
      find.descendant(
        of: find.byKey(BlocPauseClasse.cleDuree),
        matching: _t('15 min'),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(BlocPauseClasse.cleEnregistrer));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('a changé entre-temps'), findsOneWidget);
    expect((await port.reglage('g1')).dureeMinutes, 10);
  });

  testWidgets('echec d\'ecriture : « non confirme », jamais un faux succes', (
    WidgetTester tester,
  ) async {
    final _Port port = _Port(ecriture: StateError('reseau'));
    await _poser(tester, port);
    await tester.tap(
      find.descendant(
        of: find.byKey(BlocPauseClasse.cleDuree),
        matching: _t('15 min'),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(BlocPauseClasse.cleEnregistrer));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('n\'est pas confirmé'), findsOneWidget);
    expect(find.text('Pause enregistrée.'), findsNothing);
  });

  for (final Size taille in <Size>[
    const Size(320, 700),
    const Size(1440, 900),
  ]) {
    for (final double echelle in <double>[1, 2]) {
      for (final Brightness lum in Brightness.values) {
        for (final AppLocale langue in <AppLocale>[
          AppLocale.fr,
          AppLocale.ar,
        ]) {
          testWidgets(
            '${taille.width.toInt()} px, x${echelle.toInt()}, ${lum.name}, '
            '${langue.languageCode} : sans debordement',
            (WidgetTester tester) async {
              await tester.runAsync(() => LocaleSettings.setLocale(langue));
              await _poser(
                tester,
                _Port(),
                taille: taille,
                echelle: echelle,
                luminosite: lum,
              );
              // Une duree modifiee : « Enregistrer » est rendu.
              await tester.tap(
                find.descendant(
                  of: find.byKey(BlocPauseClasse.cleDuree),
                  matching: find.byType(Text).last,
                ),
              );
              await tester.pump();
              expect(tester.takeException(), isNull);
              final Rect r = tester.getRect(
                find.byKey(BlocPauseClasse.cleDuree),
              );
              expect(r.right, lessThanOrEqualTo(taille.width + 0.5));
              expect(r.left, greaterThanOrEqualTo(-0.5));
            },
          );
        }
      }
    }
  }
}
