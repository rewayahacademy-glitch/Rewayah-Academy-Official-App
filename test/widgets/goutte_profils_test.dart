// GOUTTE D'HUILE DES PROFILS (directeur, 11/11/2026) : entre deux profils, et
// entre un profil et son contenu. Regles : mouvement reduit = immediat, sans
// goutte ; aucun retard au toucher ; une seule goutte a la fois ; dans les deux
// sens ; en miroir en arabe.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/goutte_profils.dart';
import 'package:rewayah_academy/core/widgets/selecteur_profils.dart';

const List<ProfilSelectionnable> _profils = <ProfilSelectionnable>[
  ProfilSelectionnable(id: 'a', prenom: 'Amina', etat: 'Dans 3 h'),
  ProfilSelectionnable(id: 'b', prenom: 'Bilal', etat: 'Aucune seance'),
  ProfilSelectionnable(id: 'c', prenom: 'Chaima', etat: 'Aucune seance'),
];

/// L'hote : la selection (au toucher) et le profil dont le contenu s'affiche
/// (quand ses donnees sont la) sont deux valeurs, comme sur l'Accueil.
class _Hote {
  final ValueNotifier<String> selection = ValueNotifier<String>('a');
  final ValueNotifier<String> affiche = ValueNotifier<String>('a');
  BuildContext? contexteContenu;

  Widget monter({
    bool reduit = false,
    TextDirection direction = TextDirection.ltr,
  }) => TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      builder: (BuildContext c, Widget? app) => MediaQuery(
        data: MediaQuery.of(c).copyWith(disableAnimations: reduit),
        child: Directionality(textDirection: direction, child: app!),
      ),
      home: Scaffold(
        body: ListenableBuilder(
          listenable: Listenable.merge(<Listenable>[selection, affiche]),
          builder: (BuildContext context, Widget? _) => GoutteProfils(
            selectionId: selection.value,
            matiere: const Color(0xFF6B3FD0),
            matiereContenu: const Color(0xFFFFFFFF),
            rayonContenu: 16,
            child: Builder(
              builder: (BuildContext ctx) {
                contexteContenu = ctx;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SelecteurProfils(
                      profils: _profils,
                      selectionId: selection.value,
                      onSelection: (String id) => selection.value = id,
                    ),
                    const SizedBox(height: 24),
                    ContenuGoutte(
                      profilId: affiche.value,
                      child: SizedBox(
                        height: 200,
                        child: Center(child: Text('contenu ${affiche.value}')),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );

  ({double avancement, bool rompu, String de, String vers})? get goutte =>
      GoutteProfils.goutteDe(contexteContenu!);
  ({double avancement})? get chute => GoutteProfils.chuteDe(contexteContenu!);
}

Future<void> _avancer(WidgetTester tester, int ms) async {
  for (int i = 0; i < ms ~/ 16; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  // GOUTTE-COUPEE (directeur, 11/11/2026) : la goutte ne peint plus rien,
  // dans aucun mode ; la selection et le contenu changent tout de suite.
  group('goutte coupee', () {
    test('le drapeau du core est eteint', () => expect(goutteActive, isFalse));

    for (final bool reduit in <bool>[false, true]) {
      for (final TextDirection direction in TextDirection.values) {
        testWidgets(
          'aucune goutte, aucune chute, changement immediat '
          '(${reduit ? 'mouvement reduit' : 'standard'}, ${direction.name})',
          (WidgetTester tester) async {
            final _Hote h = _Hote();
            await tester.pumpWidget(
              h.monter(reduit: reduit, direction: direction),
            );
            await _avancer(tester, 700);
            for (final String prenom in <String>['Chaima', 'Amina', 'Bilal']) {
              await tester.tap(find.text(prenom));
              await tester.pump();
              final String id = prenom.substring(0, 1).toLowerCase();
              expect(h.selection.value, id);
              h.affiche.value = id;
              await tester.pump();
              expect(find.text('contenu $id'), findsOneWidget);
              for (int i = 0; i < 40; i++) {
                await tester.pump(const Duration(milliseconds: 16));
                expect(h.goutte, isNull);
                expect(h.chute, isNull);
              }
            }
          },
        );
      }
    }
  });

  group('d un profil a l autre', () {
    testWidgets('mouvement reduit : changement immediat, aucune goutte', (
      WidgetTester tester,
    ) async {
      final _Hote h = _Hote();
      await tester.pumpWidget(h.monter(reduit: true));
      await tester.pump();
      await tester.tap(find.text('Bilal'));
      await tester.pump();
      await tester.pump();
      expect(h.selection.value, 'b');
      expect(h.goutte, isNull);
      expect(h.chute, isNull);
    });

    testWidgets('sans portee : le selecteur ne change pas', (
      WidgetTester tester,
    ) async {
      String choisi = 'a';
      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (BuildContext _, StateSetter set) => SelecteurProfils(
                  profils: _profils,
                  selectionId: choisi,
                  onSelection: (String id) => set(() => choisi = id),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Bilal'));
      await _avancer(tester, 700);
      expect(choisi, 'b');
      expect(tester.takeException(), isNull);
    });
  });

  group('du profil a son contenu', () {
    testWidgets('la premiere apparition : le contenu est la tout de suite, '
        'sans chute', (WidgetTester tester) async {
      final _Hote h = _Hote();
      await tester.pumpWidget(h.monter());
      await tester.pump();
      expect(h.chute, isNull);
      expect(find.text('contenu a'), findsOneWidget);
    });

    testWidgets('tant que les donnees ne sont pas la, l affichage precedent '
        'reste, sans etat vide', (WidgetTester tester) async {
      final _Hote h = _Hote();
      await tester.pumpWidget(h.monter());
      await _avancer(tester, 900);
      h.selection.value = 'b'; // le toucher ; `affiche` ne bouge pas encore.
      await _avancer(tester, 1500);
      expect(h.chute, isNull);
      expect(find.text('contenu a'), findsOneWidget);
    });

    testWidgets('mouvement reduit : le contenu change aussitot', (
      WidgetTester tester,
    ) async {
      final _Hote h = _Hote();
      await tester.pumpWidget(h.monter(reduit: true));
      await tester.pump();
      h.selection.value = 'b';
      h.affiche.value = 'b';
      await tester.pump();
      await tester.pump();
      expect(h.chute, isNull);
      expect(find.text('contenu b'), findsOneWidget);
    });
  });

  // GARDE-CAP (11/11/2026) : le cou du contenu ne croise JAMAIS le libelle du
  // rond (defaut visible, bloque la fusion) : il part du bas de l'item.
  testWidgets('le cou du contenu part sous le libelle, jamais au travers', (
    WidgetTester tester,
  ) async {
    final _Hote h = _Hote();
    await tester.pumpWidget(h.monter());
    await tester.pump(const Duration(seconds: 1));
    for (final String id in <String>['a', 'b', 'c']) {
      final ({double hautDuDepart, double basDeLItem})? d =
          GoutteProfils.departContenuDe(h.contexteContenu!, id);
      expect(d, isNotNull);
      expect(
        d!.hautDuDepart,
        greaterThanOrEqualTo(d.basDeLItem - 0.001),
        reason: 'le cou de $id part au-dessus du bas de son libelle',
      );
    }
  });
}
