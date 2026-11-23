// REGRESSION (directeur, 22/11/2026, telephone, arabe, sombre) : l'apercu d'un
// compte (feuille du bas) ne s'affichait qu'a moitie, le reste etait hors
// ecran. Ce test ouvre l'apercu a 390 x 844 (texte x1 et x2, fr et ar) et
// verifie que chaque libelle est a l'ecran (apres defilement de la feuille si
// le texte est agrandi), sans exception.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/contact_compte.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/admin_comptes/apercu_compte.dart';
import 'package:rewayah_academy/features/admin_comptes/liste_comptes.dart';
import 'package:rewayah_academy/features/admin_personnes/personnes_page.dart';

import '../../capture/outil_capture.dart'
    show capturerVue, chargerPolicesDuDepot, dossierCapture;
import '../../support/harnais.dart';

const String _courriel = 'apercu-famille@example.test';

class _Contact implements PortContactCompte {
  const _Contact();

  @override
  Future<String?> courriel(String profilId) async => _courriel;
}

CompteAdmin _famille() => CompteAdmin(
  profilId: 'p1',
  identifiant: 'RA-26-4817',
  prenom: 'Amina',
  nom: 'Essai',
  role: AppRole.guardian,
  etat: AccountStatus.active,
  inscritLe: DateTime.now().subtract(const Duration(days: 12)),
  accesJusquAu: null,
  foyerId: null,
  piece: EtatPiece.aucune,
  contrats: 0,
  aEnseignant: false,
  enfantsDuFoyer: 2,
  detailsServis: true,
);

/// Vrai tant qu'un champ de saisie a le focus (le clavier est ouvert).
bool _champAuFocus() {
  final FocusNode? n = FocusManager.instance.primaryFocus;
  return n != null && n is! FocusScopeNode;
}

Future<void> _ouvrir(
  WidgetTester tester, {
  required AppLocale langue,
  required double echelle,
  Size taille = const Size(390, 844),
}) async {
  await tester.runAsync(() => LocaleSettings.setLocale(langue));
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = taille;
  addTearDown(tester.view.reset);
  addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
  // Le clavier se comporte comme sur un telephone : il est ouvert tant qu'un
  // champ (la recherche de la page) a le focus.
  void clavier() {
    tester.view.viewInsets = FakeViewPadding(bottom: _champAuFocus() ? 340 : 0);
  }

  FocusManager.instance.addListener(clavier);
  addTearDown(() => FocusManager.instance.removeListener(clavier));
  final CompteAdmin c = _famille();
  await tester.pumpWidget(
    hoteRoutant(
      depart: '/',
      echelle: echelle,
      surcharges: <Override>[
        portContactCompteProvider.overrideWithValue(const _Contact()),
      ],
      themeMode: ThemeMode.dark,
      direction: langue == AppLocale.ar ? TextDirection.rtl : null,
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext _, GoRouterState _) => NavShell(
            destinations: destinationsPour(
              role: AppRole.admin,
              mode: InterfaceMode.standard,
            ),
            indexActif: 0,
            onAller: (String _) {},
            child: Scaffold(
              body: Builder(
                builder: (BuildContext contexte) => Column(
                  children: <Widget>[
                    const TextField(key: Key('recherche'), autofocus: true),
                    TextButton(
                      onPressed: () => ouvrirApercuCompte(
                        contexte,
                        nom: 'Amina Essai',
                        profilId: c.profilId,
                        informations: informationsDuCompte(
                          c,
                          VueComptes.familles,
                        ),
                        gestes: <EntreeAction>[
                          EntreeAction(libelle: 'Geste un', onChoix: () {}),
                          EntreeAction(libelle: 'Geste deux', onChoix: () {}),
                        ],
                      ),
                      child: const Text('ouvrir'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
  // Le clavier est ouvert, comme apres une recherche.
  expect(tester.view.viewInsets.bottom, 340);
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
  // L'apercu n'a aucun champ : le clavier s'est ferme.
  expect(_champAuFocus(), isFalse);
  expect(tester.view.viewInsets.bottom, 0);
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
    for (final double echelle in <double>[1, 2]) {
      testWidgets('apercu de compte lisible a 390 x 844, '
          '${langue.languageCode}, texte x${echelle.toInt()}', (
        WidgetTester tester,
      ) async {
        await _ouvrir(tester, langue: langue, echelle: echelle);
        final CompteAdmin c = _famille();
        final List<InformationCompte> infos = informationsDuCompte(
          c,
          VueComptes.familles,
        ).where((InformationCompte i) => i.valeur.trim().isNotEmpty).toList();
        expect(infos.length, greaterThanOrEqualTo(4));
        final Rect ecran = Offset.zero & const Size(390, 844);

        for (final InformationCompte i in infos) {
          final Finder cle = find.textContaining(i.titre, findRichText: true);
          expect(cle, findsWidgets, reason: i.titre);
          await tester.ensureVisible(cle.first);
          await tester.pumpAndSettle();
          final Rect r = tester.getRect(cle.first);
          expect(
            ecran.contains(r.topLeft) && ecran.contains(r.bottomRight),
            isTrue,
            reason: '${i.titre} hors ecran : $r',
          );
        }
        // Le courriel (a l'ecran, pas seulement dans l'arbre) et le libelle.
        final Finder courriel = find.textContaining(_courriel);
        expect(courriel, findsOneWidget);
        await tester.ensureVisible(courriel);
        await tester.pumpAndSettle();
        final Rect rc = tester.getRect(courriel);
        expect(
          ecran.contains(rc.topLeft) && ecran.contains(rc.bottomRight),
          isTrue,
          reason: 'courriel hors ecran : $rc',
        );
        expect(find.text(t.admin.comptes.colonneCourriel), findsOneWidget);
        for (final String geste in <String>['Geste un', 'Geste deux']) {
          await tester.ensureVisible(find.text(geste));
          await tester.pumpAndSettle();
          final Rect r = tester.getRect(find.text(geste));
          expect(ecran.contains(r.center), isTrue, reason: '$geste hors ecran');
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('a texte x1 la feuille monte a la hauteur de son contenu', (
    WidgetTester tester,
  ) async {
    await _ouvrir(tester, langue: AppLocale.fr, echelle: 1);
    final Rect corps = tester.getRect(find.byKey(cleApercuCompte));
    final Rect feuille = tester.getRect(find.byType(BottomSheet));
    // Le corps est entierement dans l'ecran.
    expect(corps.bottom, lessThanOrEqualTo(844));
    // La feuille enveloppe son contenu (et non la moitie de l'ecran).
    expect(feuille.top, lessThanOrEqualTo(corps.top));
    expect(feuille.bottom, greaterThanOrEqualTo(corps.bottom));
    expect(tester.takeException(), isNull);
  });

  // Captures R3 (CAPTURE_DIR) : l'apercu a 390 et a 1440, clair et sombre.
  for (final (String, Size) v in <(String, Size)>[
    ('390', const Size(390, 844)),
    ('1440', const Size(1440, 900)),
  ]) {
    testWidgets(
      'capture apercu de compte ${v.$1}',
      skip: dossierCapture == null,
      (WidgetTester tester) async {
        await _ouvrir(tester, langue: AppLocale.ar, echelle: 1, taille: v.$2);
        await capturerVue(tester, 'apercu-compte-${v.$1}-ar-sombre');
      },
    );
  }
}
