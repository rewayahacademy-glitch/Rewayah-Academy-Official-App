// PAGES-FLUIDES (directeur, 12/11/2026, apres une vraie seance) :
// (13) « Tourner une page donne l'impression que ca plante. »
// Ce que ces tests prouvent, en local seulement (la preuve d'une etape reste
// celle du directeur en production) :
// (a) la page lue pour la presenter est celle qui s'affiche : une seule
//     lecture du serveur par page ;
// (b) une page voisine est lue en avance : tourner n'attend aucune lecture ;
// (c) une page pas encore lue : l'ancienne reste a l'ecran (et la barre dit
//     que le geste est compris), puis la nouvelle la remplace ;
// (d) « reduire les animations » : pas de fondu.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/mouvement/passage_salle.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_coran/layout_lignes_indisponible.dart';
import 'package:rewayah_academy/core/tc_coran/layout_madina_15.dart';
import 'package:rewayah_academy/core/tc_coran/moteur_mushaf.dart';
import 'package:rewayah_academy/core/tc_coran/port_layout_mushaf.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/core/widgets/page_immersive.dart';
import 'package:rewayah_academy/features/salle_enseignant/page_coran_salle.dart';
import 'package:rewayah_academy/features/salle_enseignant/panneau_enseignant.dart';
import 'package:rewayah_academy/features/tc_mushaf/page_madina_15.dart';
import 'package:rewayah_academy/features/tc_mushaf/police_mushaf.dart';

import '../support/harnais.dart';

/// Un corpus qui compte ses lectures, page par page, et qui peut retenir une
/// page (le reseau lent d'une vraie seance).
class _CoranCompte implements ServiceCoran {
  /// Les lectures du serveur, par page.
  final Map<int, int> lectures = <int, int>{};

  /// Les pages retenues : elles n'arrivent qu'a la completion.
  final Map<int, Completer<void>> retenues = <int, Completer<void>>{};

  @override
  Future<String?> editionCourante() async => 'edition-de-test';

  @override
  Future<List<Sourate>?> sourates() async => null;

  @override
  Future<PageCoran?> page(int numero) async {
    lectures[numero] = (lectures[numero] ?? 0) + 1;
    final Completer<void>? retenue = retenues[numero];
    if (retenue != null) await retenue.future;
    return PageCoran(
      numero: numero,
      versets: <VersetCoran>[
        VersetCoran(
          sourateNumero: 2,
          numero: numero * 6,
          texte: 'verset de la page $numero',
          pageNumero: numero,
        ),
      ],
    );
  }

  @override
  Future<int?> pageDe(int sourate, int verset) async => null;

  @override
  Future<PositionLecture?> position(String profilId) async => null;

  @override
  Future<bool> enregistrerPosition(
    String profilId,
    PositionLecture position,
  ) async => false;

  @override
  Future<({int sourate, int verset})?> debutDeJuz(int juz) async => null;

  @override
  Future<List<VersetCoran>?> rechercher(
    String requete, {
    int limite = 50,
  }) async => const <VersetCoran>[];
}

/// Une mise en page de Medine dont une page peut etre retenue (cote eleve :
/// la page qui arrive n'est pas encore composee).
class _LayoutRetenu extends LayoutMadina15 {
  final Map<int, Completer<void>> retenues = <int, Completer<void>>{};

  @override
  Future<LayoutPage?> layoutDe(int numeroPage) async {
    final Completer<void>? retenue = retenues[numeroPage];
    if (retenue != null) await retenue.future;
    return depuis(numeroPage);
  }
}

AccesSalle _acces() => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton.signe',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: 'teacher',
  capacites: const CapacitesSalle(
    peutPublier: true,
    peutPublierVideo: true,
    peutPublierDonnees: true,
    peutRecevoir: true,
    invisible: false,
  ),
  expireLe: DateTime.now().add(const Duration(minutes: 10)),
);

ContenuPresente _contenu(int page) => ContenuPresente(
  page: page,
  sourate: 2,
  verset: page * 6,
  presentePar: 'ens-1',
  emisLe: DateTime.now(),
);

List<Override> _surcharges({
  required FauxMoteurSalle moteur,
  required _CoranCompte coran,
  PortLayoutMushaf? layout,
}) => <Override>[
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(
      const SessionState(
        resolue: true,
        role: AppRole.teacher,
        profileId: 'ens-1',
        accountStatus: AccountStatus.active,
        lectureProfil: LectureProfil.presente,
      ),
    ),
  ),
  moteurSalleProvider.overrideWithValue(moteur),
  serviceCoranProvider.overrideWithValue(coran),
  portLayoutMushafProvider.overrideWithValue(layout ?? LayoutMadina15()),
  policeMushafDisponibleProvider.overrideWith((Ref _) async => true),
];

/// Le panneau de l'enseignant, dans la coquille de la salle, a 390 x 844.
Future<void> _monterPanneau(
  WidgetTester tester,
  List<Override> surcharges,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    hote(
      const PageImmersive(
        registre: RegistreImmersif.salle,
        child: PanneauEnseignantSalle(seanceId: 's1'),
      ),
      surcharges: surcharges,
    ),
  );
  await tester.pumpAndSettle();
}

/// Le numero de la page composee a l'ecran (celle que l'on lit).
int? _pageLue(WidgetTester tester) {
  final Finder page = find.byType(PageMadina15);
  return page.evaluate().isEmpty
      ? null
      : tester.widget<PageMadina15>(page).vue.numero;
}

Finder get _suivant => find.byKey(const ValueKey<String>('nav-suivant'));

void main() {
  test('les pages voisines sont la precedente et la suivante, bornees', () {
    expect(pagesVoisines(42), <int>[41, 43]);
    expect(pagesVoisines(1), <int>[2]);
    expect(pagesVoisines(pagesMushafMedine), <int>[pagesMushafMedine - 1]);
  });

  group('PAGES-FLUIDES : tourner la page chez l enseignant', () {
    testWidgets('(a) la page presentee n est lue qu une fois au serveur', (
      WidgetTester tester,
    ) async {
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await moteur.rejoindre(_acces());
      final _CoranCompte coran = _CoranCompte();
      await _monterPanneau(
        tester,
        _surcharges(moteur: moteur, coran: coran),
      );
      moteur.publierContenu(_contenu(42));
      await tester.pumpAndSettle();
      expect(_pageLue(tester), 42);

      await tester.tap(_suivant);
      await tester.pumpAndSettle();

      expect(moteur.dernierContenuPresente?.page, 43);
      expect(_pageLue(tester), 43);
      // Une lecture pour presenter ET afficher la page 43 (avant : une
      // lecture par `pageCoranProvider`, puis une seconde par le rendu).
      expect(coran.lectures[43], 1);
      expect(coran.lectures[42], 1);
      // Le prechargement ne va pas plus loin que les voisines.
      expect(coran.lectures.keys.toSet(), <int>{41, 42, 43, 44});
    });

    testWidgets('(b) une page voisine prechargee part sans attendre', (
      WidgetTester tester,
    ) async {
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await moteur.rejoindre(_acces());
      final _CoranCompte coran = _CoranCompte();
      await _monterPanneau(
        tester,
        _surcharges(moteur: moteur, coran: coran),
      );
      moteur.publierContenu(_contenu(42));
      await tester.pumpAndSettle();
      // La page 43 a ete lue en avance, a l'affichage de la 42.
      expect(coran.lectures[43], 1);

      // Plus aucune page ne repond : un tour qui attendrait une lecture ne
      // partirait pas.
      for (int p = 1; p <= pagesMushafMedine; p++) {
        coran.retenues[p] = Completer<void>();
      }
      await tester.tap(_suivant);
      // Aucune image, aucun temps ecoule : le pointeur est deja parti.
      expect(moteur.contenusPresentesDemandes.single.page, 43);
      await tester.pump();
      expect(_pageLue(tester), 43);
      expect(coran.lectures[43], 1);
      for (final Completer<void> c in coran.retenues.values) {
        c.complete();
      }
      await tester.pumpAndSettle();
    });

    testWidgets(
      '(c) page pas encore lue : l ancienne reste, puis la nouvelle arrive',
      (WidgetTester tester) async {
        final FauxMoteurSalle moteur = FauxMoteurSalle();
        await moteur.rejoindre(_acces());
        final _CoranCompte coran = _CoranCompte();
        final Completer<void> page44 = Completer<void>();
        coran.retenues[44] = page44;
        await _monterPanneau(
          tester,
          _surcharges(moteur: moteur, coran: coran),
        );
        moteur.publierContenu(_contenu(42));
        await tester.pumpAndSettle();
        await tester.tap(_suivant);
        await tester.pumpAndSettle();
        expect(_pageLue(tester), 43);

        // La 44 se lit encore (lecture lente) : rien ne part a la classe,
        // la page 43 reste lisible, la barre dit que le geste est compris.
        await tester.tap(_suivant);
        await tester.pump();
        expect(moteur.dernierContenuPresente?.page, 43);
        expect(_pageLue(tester), 43);
        expect(find.byKey(PageCoranSalle.clePreparation), findsOneWidget);
        expect(find.byKey(PageCoranSalle.cleSquelette), findsNothing);

        page44.complete();
        await tester.pump();
        await tester.pump();
        expect(moteur.dernierContenuPresente?.page, 44);
        expect(_pageLue(tester), 44);
        await tester.pumpAndSettle();
        expect(find.byKey(PageCoranSalle.clePreparation), findsNothing);
        expect(coran.lectures[44], 1);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('PAGES-FLUIDES : la page recue (eleve) et le fondu', () {
    Future<ValueNotifier<int>> monterPage(
      WidgetTester tester,
      _LayoutRetenu layout, {
      bool reduit = false,
    }) async {
      final ValueNotifier<int> numero = ValueNotifier<int>(42);
      addTearDown(numero.dispose);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        hote(
          Builder(
            builder: (BuildContext context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: reduit),
              child: Scaffold(
                body: ValueListenableBuilder<int>(
                  valueListenable: numero,
                  builder: (BuildContext _, int n, Widget? _) =>
                      PageCoranSalle(numero: n),
                ),
              ),
            ),
          ),
          surcharges: <Override>[
            serviceCoranProvider.overrideWithValue(_CoranCompte()),
            portLayoutMushafProvider.overrideWithValue(layout),
            policeMushafDisponibleProvider.overrideWith((Ref _) async => true),
          ],
        ),
      );
      await tester.pumpAndSettle();
      return numero;
    }

    double opacite(WidgetTester tester) => tester
        .widget<FadeTransition>(
          find.descendant(
            of: find.byType(FonduAuChangement),
            matching: find.byType(FadeTransition),
          ),
        )
        .opacity
        .value;

    testWidgets('(c) l ancienne page reste, puis la nouvelle entre en fondu', (
      WidgetTester tester,
    ) async {
      final _LayoutRetenu layout = _LayoutRetenu();
      final Completer<void> page50 = Completer<void>();
      layout.retenues[50] = page50;
      final ValueNotifier<int> numero = await monterPage(tester, layout);
      expect(_pageLue(tester), 42);

      numero.value = 50;
      await tester.pump();
      await tester.pump(AppMouvement.plafond);
      // Ni squelette ni ecran vide : la page 42 reste lisible.
      expect(_pageLue(tester), 42);
      expect(find.byKey(PageCoranSalle.cleSquelette), findsNothing);
      expect(opacite(tester), 1);

      page50.complete();
      await tester.pump();
      await tester.pump();
      expect(_pageLue(tester), 50);
      // Le fondu court est en cours (jeton `fonduEntree`).
      await tester.pump(AppMouvement.fonduEntree ~/ 2);
      expect(opacite(tester), lessThan(1));
      await tester.pumpAndSettle();
      expect(opacite(tester), 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(d) reduire les animations : changement immediat', (
      WidgetTester tester,
    ) async {
      final _LayoutRetenu layout = _LayoutRetenu();
      final ValueNotifier<int> numero = await monterPage(
        tester,
        layout,
        reduit: true,
      );
      numero.value = 43;
      await tester.pump();
      await tester.pump();
      expect(_pageLue(tester), 43);
      expect(opacite(tester), 1);
      await tester.pump(AppMouvement.fonduEntree ~/ 2);
      expect(opacite(tester), 1);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('premier affichage : un squelette a la forme d une page', (
      WidgetTester tester,
    ) async {
      final _LayoutRetenu layout = _LayoutRetenu();
      final Completer<void> page42 = Completer<void>();
      layout.retenues[42] = page42;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        hote(
          const Scaffold(body: PageCoranSalle(numero: 42)),
          surcharges: <Override>[
            serviceCoranProvider.overrideWithValue(_CoranCompte()),
            portLayoutMushafProvider.overrideWithValue(layout),
            policeMushafDisponibleProvider.overrideWith((Ref _) async => true),
          ],
        ),
      );
      await tester.pump(AppMouvement.plafond);
      final Finder squelette = find.byKey(PageCoranSalle.cleSquelette);
      expect(squelette, findsOneWidget);
      // La forme d'une page entiere, pas six lignes en haut de l'ecran.
      final Size taille = tester.getSize(
        find.descendant(of: squelette, matching: find.byType(SizedBox)).first,
      );
      expect(taille.height, greaterThan(taille.width));
      page42.complete();
      await tester.pumpAndSettle();
      expect(_pageLue(tester), 42);
    });

    testWidgets('sans mise en page, l etat Reessayer reste', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        hote(
          const Scaffold(body: PageCoranSalle(numero: 42)),
          surcharges: <Override>[
            serviceCoranProvider.overrideWithValue(_CoranCompte()),
            portLayoutMushafProvider.overrideWithValue(
              const LayoutLignesIndisponible(),
            ),
            policeMushafDisponibleProvider.overrideWith((Ref _) async => true),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(PageCoranSalle.cleIndisponible), findsOneWidget);
    });
  });
}
