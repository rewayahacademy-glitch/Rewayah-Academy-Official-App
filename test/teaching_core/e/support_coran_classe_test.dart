import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_position.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_range.dart';
import 'package:rewayah_academy/core/tc_coran/corpus_service_coran.dart';
import 'package:rewayah_academy/core/tc_coran/etat_lecture_coran.dart';
import 'package:rewayah_academy/core/tc_coran/layout_lignes_indisponible.dart';
import 'package:rewayah_academy/core/tc_coran/navigation_coran.dart';
import 'package:rewayah_academy/core/tc_coran/page_mushaf_vm.dart';
import 'package:rewayah_academy/core/tc_coran/port_navigation_coran.dart';
import 'package:rewayah_academy/core/tc_etat_partage/etat_partage_memoire.dart';
import 'package:rewayah_academy/core/tc_etat_partage/providers_tc_etat_partage.dart';
import 'package:rewayah_academy/core/tc_etat_partage/shared_content_state.dart';
import 'package:rewayah_academy/core/tc_realtime/port_transport_donnees.dart';
import 'package:rewayah_academy/core/tc_realtime/providers_tc_realtime.dart';
import 'package:rewayah_academy/core/tc_realtime/transport_memoire.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/tc_classe_live/etat_partage_classe.dart';
import 'package:rewayah_academy/features/tc_classe_live/support_coran_classe.dart';
import 'package:rewayah_academy/features/tc_mushaf/vue_focus_classe.dart';

import '../c/faux/faux_corpus_coran.dart';
import '../c/goldens/corpus_reference.dart';

/// Les scenarios A et B du lot 2, sur un fil en memoire.
///
/// **Deux appareils, un bus, un backend.** L'enseignant et l'eleve ont chacun
/// leur conteneur Riverpod, donc leur propre lecteur, leur propre transport
/// et leur propre `ServiceEtatPartage` ; ils partagent le `BusMemoire` (le
/// canal de donnees) et l'`EtatPartageMemoire` (la persistance). Rien ici ne
/// simule LiveKit : le transport memoire est celui contre lequel le lot F
/// est prouve.
void main() {
  const String seance = 's1';
  const CapacitesTransport prof = CapacitesTransport(
    identiteLocale: 'prof-1',
    peutPublier: true,
    peutPublierDonnees: true,
    invisible: false,
  );
  const CapacitesTransport eleve = CapacitesTransport(
    identiteLocale: 'eleve-1',
    peutPublier: true,
    peutPublierDonnees: false,
    invisible: false,
  );

  late CorpusReference reference;
  late BusMemoire bus;
  late EtatPartageMemoire backend;
  late ProviderContainer chezLeProf;
  late ProviderContainer chezLEleve;

  setUpAll(() => reference = CorpusReference.charger());

  ProviderContainer conteneur(CapacitesTransport capacites) {
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        portTransportDonneesProvider.overrideWithValue(
          TransportMemoire(bus: bus, capacites: capacites),
        ),
        portEtatPartagePersistantProvider.overrideWithValue(backend),
        portCorpusCoranProvider.overrideWithValue(FauxCorpusCoran(reference)),
        portLayoutMushafProvider.overrideWithValue(
          const LayoutLignesIndisponible(),
        ),
        portNavigationCoranProvider.overrideWithValue(FauxNavigationCoran()),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    bus = BusMemoire();
    backend = EtatPartageMemoire();
    chezLeProf = conteneur(prof);
    chezLEleve = conteneur(eleve);
  });

  Future<void> monter(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          home: Scaffold(
            body: Row(
              children: <Widget>[
                Expanded(
                  child: UncontrolledProviderScope(
                    container: chezLeProf,
                    child: const SupportCoranClasse(
                      sessionId: seance,
                      peutPiloter: true,
                    ),
                  ),
                ),
                Expanded(
                  child: UncontrolledProviderScope(
                    container: chezLEleve,
                    child: const SupportCoranClasse(
                      sessionId: seance,
                      peutPiloter: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await poser(tester);
  }

  PresentateurClasse presentateur() =>
      chezLeProf.read(presentateurClasseProvider)(seance);

  ContentPosition ayah(int sourate, int ayah) => ContentPosition.ayah(
    resourceId: identifiantRessourceCoran,
    sourate: sourate,
    ayah: ayah,
  );

  EtatLectureCoran lecteur(ProviderContainer c) => c.read(lectureCoranProvider);

  testWidgets(
    'B : sans support, l eleve le lit ; A : le Coran presente arrive chez les deux',
    (WidgetTester tester) async {
      await monter(tester);
      // Les deux surfaces sont montees a nu ici : sans support, chacune le dit.
      // Dans la coque, celle du pilote n'est pas montee (la video prend la place).
      expect(find.text(t.tc.classe.support.aucun), findsNWidgets(2));

      await presentateur().presenter(
        resourceId: identifiantRessourceCoran,
        position: ayah(1, 1),
      );
      await poser(tester);

      expect(find.text(t.tc.classe.support.aucun), findsNothing);
      expect(lecteur(chezLeProf).page, 1);
      expect(lecteur(chezLEleve).page, 1);
      expect(lecteur(chezLEleve).origine, OrigineNavigation.groupe);
      expect((await backend.lire(seance))?.revision, 0);
    },
  );

  testWidgets('A : aller a un verset deplace la classe ; B : l eleve suit', (
    WidgetTester tester,
  ) async {
    await monter(tester);
    await presentateur().presenter(
      resourceId: identifiantRessourceCoran,
      position: ayah(1, 1),
    );
    await poser(tester);

    await presentateur().deplacer(ayah(2, 1));
    await poser(tester);

    expect(lecteur(chezLeProf).page, 2);
    expect(lecteur(chezLEleve).page, 2);
    expect((await backend.lire(seance))?.revision, 1);
  });

  testWidgets(
    'B : l eleve qui feuillette ailleurs se voit proposer de revenir, jamais avant',
    (WidgetTester tester) async {
      await monter(tester);
      await presentateur().presenter(
        resourceId: identifiantRessourceCoran,
        position: ayah(2, 1),
      );
      await poser(tester);
      expect(find.text(t.tc.classe.support.revenirProfesseur), findsNothing);

      chezLEleve
          .read(lectureCoranProvider.notifier)
          .allerA(1, origine: OrigineNavigation.personnelle);
      await poser(tester);
      expect(find.text(t.tc.classe.support.revenirProfesseur), findsOneWidget);
      // Un eleve qui feuillette ne publie rien : la classe ne bouge pas.
      expect((await backend.lire(seance))?.revision, 0);
      expect(lecteur(chezLeProf).page, 2);

      await tester.tap(find.text(t.tc.classe.support.revenirProfesseur));
      await poser(tester);
      expect(lecteur(chezLEleve).page, 2);
      expect(find.text(t.tc.classe.support.revenirProfesseur), findsNothing);
    },
  );

  testWidgets(
    'A : le pilote qui feuillette au doigt publie, une fois, apres l arret',
    (WidgetTester tester) async {
      await monter(tester);
      await presentateur().presenter(
        resourceId: identifiantRessourceCoran,
        position: ayah(1, 1),
      );
      await poser(tester);

      chezLeProf
          .read(lectureCoranProvider.notifier)
          .allerA(2, origine: OrigineNavigation.personnelle);
      await tester.pump();
      // Avant le debounce : rien ne part.
      expect((await backend.lire(seance))?.revision, 0);

      await tester.pump(const Duration(seconds: 1));
      await poser(tester);
      final SharedContentState? etat = await backend.lire(seance);
      expect(etat?.revision, 1);
      expect(
        etat?.contentPosition.sourate,
        reference.page(2).versets.first.sourate,
      );
      expect(lecteur(chezLEleve).page, 2);
    },
  );

  testWidgets('A : un focus devient une revision, et l eleve passe en focus', (
    WidgetTester tester,
  ) async {
    await monter(tester);
    await presentateur().presenter(
      resourceId: identifiantRessourceCoran,
      position: ayah(1, 1),
    );
    await poser(tester);

    final ContentRange plage = ContentRange(
      resourceId: identifiantRessourceCoran,
      debut: ayah(1, 2),
      fin: ayah(1, 2),
    );
    await presentateur().focaliser(plage);
    await poser(tester);

    expect(lecteur(chezLEleve).mode, ModeRenduCoran.focus);
    expect(lecteur(chezLEleve).plageFocus, plage);
    expect(find.byType(VueFocusClasse), findsNWidgets(2));

    await presentateur().focaliser(null);
    await poser(tester);
    expect(lecteur(chezLEleve).mode, ModeRenduCoran.mushaf);
  });

  testWidgets('le zoom de l eleve survit a une page tournee par la classe', (
    WidgetTester tester,
  ) async {
    await monter(tester);
    await presentateur().presenter(
      resourceId: identifiantRessourceCoran,
      position: ayah(1, 1),
      mode: ModeAffichagePartage.verse,
    );
    await poser(tester);
    chezLEleve.read(lectureCoranProvider.notifier).zoomer(0.6);

    await presentateur().deplacer(ayah(2, 1));
    await poser(tester);

    expect(lecteur(chezLEleve).page, 2);
    expect(lecteur(chezLEleve).zoomLocal, closeTo(1.6, 0.001));
  });

  testWidgets('un arrivant tardif recoit la republication de l enseignant', (
    WidgetTester tester,
  ) async {
    await monter(tester);
    await presentateur().presenter(
      resourceId: identifiantRessourceCoran,
      position: ayah(2, 1),
    );
    await poser(tester);

    // Un troisieme appareil arrive apres coup, sans rien en memoire.
    final ProviderContainer tardif = conteneur(
      const CapacitesTransport(
        identiteLocale: 'eleve-2',
        peutPublier: true,
        peutPublierDonnees: false,
        invisible: false,
      ),
    );
    final List<SharedContentState?> recus = <SharedContentState?>[];
    tardif.listen<AsyncValue<SharedContentState?>>(
      etatPartageClasseProvider(seance),
      (_, AsyncValue<SharedContentState?> v) => recus.add(v.value),
      fireImmediately: true,
    );
    await presentateur().republier();
    await poser(tester);

    expect(
      recus.whereType<SharedContentState>().last.contentPosition.sourate,
      2,
    );
  });
}

/// Laisse les `FutureProvider` se resoudre sans `pumpAndSettle`.
Future<void> poser(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump();
  }
}
