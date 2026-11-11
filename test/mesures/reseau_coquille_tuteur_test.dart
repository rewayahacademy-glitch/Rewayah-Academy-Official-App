// Mesure demandee par le pilote (11/11/2026, PR 410, HALO 2b) : combien de
// lectures reseau la coquille du tuteur fait-elle, au repos sur l'Accueil,
// avec 1 et 3 profils ? Chaque appel a un port (seances, classes, horloge de
// Classe, foyer) est une requete. Le vrai routeur, le vrai Accueil, la vraie
// coquille et son halo ; seuls les ports sont faux, et comptent.
//
// Le temps avance de 5 minutes par pas de 30 s (le battement du halo et de
// l'Accueil). La regle verifiee : au repos, aucune lecture ne se repete toutes
// les 30 s (le battement relit l'horloge locale, jamais le reseau).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/seance_famille/port_seances_famille.dart';
import 'package:rewayah_academy/core/seance_famille/seance_famille.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/accueil_famille/accueil_famille_page.dart';

import '../fixtures/tuteur/faux_classes_foyer.dart';
import '../fixtures/tuteur/faux_seances_famille.dart';
import '../fixtures/tuteur/foyers.dart';
import '../router/support_routeur.dart';
import '../support/harnais.dart';
import '../support/port_horloge_simule.dart';

/// Le troisieme profil fictif du foyer A, pour la mesure a trois profils.
const EleveDuFoyer _a3 = EleveDuFoyer(
  id: 'foyer-a-eleve-3',
  prenom: 'Élève A3',
  identifiantImmuable: 'STUD-FA-000003',
  mode: InterfaceMode.standard,
  camera: CameraPolicy.allowed,
);

class _SeancesComptees extends FauxSeancesFamille {
  _SeancesComptees({required super.seances, required super.maintenant});

  int appels = 0;

  @override
  Future<SeanceFamille?> prochaine(String eleveId) {
    appels++;
    return super.prochaine(eleveId);
  }

  @override
  Future<SeanceFamille?> derniere(String eleveId) {
    appels++;
    return super.derniere(eleveId);
  }

  @override
  Future<DateTime> maintenantServeurUtc() {
    appels++;
    return super.maintenantServeurUtc();
  }
}

class _ClassesComptees extends FauxClassesFoyer {
  _ClassesComptees({required super.classes});

  int appels = 0;

  @override
  Future<List<ClasseFoyer>> classesDe(String eleveId) {
    appels++;
    return super.classesDe(eleveId);
  }
}

class _AppairageCompte extends FauxServiceAppairage {
  int appels = 0;

  @override
  Future<List<EleveDuFoyer>> eleves() {
    appels++;
    return super.eleves();
  }

  @override
  Future<List<AppareilAppaire>> appareils() {
    appels++;
    return super.appareils();
  }
}

typedef _Mesure = ({int depart, int parMinute, String detail});

Future<_Mesure> _mesurer(WidgetTester tester, List<EleveDuFoyer> foyer) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final DateTime maintenant = DateTime.utc(2026, 11, 11, 15);
  // Au repos : chaque cours commence dans trois heures, aucune salle ouverte.
  final DateTime debut = maintenant.add(const Duration(hours: 3));
  final _SeancesComptees seances = _SeancesComptees(
    seances: <SeanceFamille>[
      for (final EleveDuFoyer e in foyer)
        seanceFictive(seanceId: 's-${e.id}', eleveId: e.id, debutUtc: debut),
    ],
    maintenant: maintenant,
  );
  final _ClassesComptees classes = _ClassesComptees(
    classes: <ClasseFoyer>[
      for (final EleveDuFoyer e in foyer)
        ClasseFoyer(
          eleveId: e.id,
          classe: classeFictive(groupeId: 'classe-${e.id}'),
        ),
    ],
  );
  final PortHorlogeSimule horloges = PortHorlogeSimule(
    debutUtc: debut,
    maintenant: () => maintenant,
  );
  final _AppairageCompte appairage = _AppairageCompte()..elevesRendus = foyer;
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
          appairage: appairage,
          horloges: horloges,
        ),
        portSeancesFamilleProvider.overrideWithValue(seances),
        portClassesFoyerProvider.overrideWithValue(classes),
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(Routes.tuteurAccueil);
  await stabiliser(tester);
  expect(find.byType(AccueilFamillePage), findsOneWidget);

  int total() =>
      seances.appels + classes.appels + horloges.lectures + appairage.appels;
  final int depart = total();
  final ({int s, int c, int h, int a}) avant = (
    s: seances.appels,
    c: classes.appels,
    h: horloges.lectures,
    a: appairage.appels,
  );
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(seconds: 30));
  }
  final int apres = total() - depart;
  return (
    depart: depart,
    parMinute: (apres / 5).ceil(),
    detail:
        'depart : seances ${avant.s}, classes ${avant.c}, '
        'horloges ${avant.h}, foyer ${avant.a} ; en 5 min : seances '
        '${seances.appels - avant.s}, classes ${classes.appels - avant.c}, '
        'horloges ${horloges.lectures - avant.h}, foyer '
        '${appairage.appels - avant.a}',
  );
}

void main() {
  for (final (String nom, List<EleveDuFoyer> foyer)
      in <(String, List<EleveDuFoyer>)>[
        ('1 profil', <EleveDuFoyer>[FoyersFictifs.a1]),
        ('3 profils', <EleveDuFoyer>[FoyersFictifs.a1, FoyersFictifs.a2, _a3]),
      ]) {
    testWidgets(
      'au repos sur l Accueil, $nom : aucune lecture toutes les 30 s',
      (WidgetTester tester) async {
        final _Mesure m = await _mesurer(tester, foyer);
        debugPrint(
          'MESURE $nom : ${m.depart} lectures a l ouverture, '
          '${m.parMinute} par minute ensuite (${m.detail})',
        );
        expect(m.parMinute, 0);
      },
    );
  }
}
