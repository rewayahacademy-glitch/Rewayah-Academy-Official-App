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
                        key: const ValueKey<String>('carte-1'),
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

  group('d un profil a l autre', () {
    testWidgets('la selection est prise tout de suite, la goutte suit, se '
        'rompt, puis s acheve', (WidgetTester tester) async {
      final _Hote h = _Hote();
      await tester.pumpWidget(h.monter());
      await _avancer(tester, 700);
      expect(h.goutte, isNull, reason: 'au repos : aucune goutte');

      await tester.tap(find.text('Bilal'));
      // Aucun retard : la selection est deja celle de Bilal, au premier pas.
      await tester.pump();
      expect(h.selection.value, 'b');
      await tester.pump();
      expect(h.goutte, isNotNull);
      expect(h.goutte!.de, 'a');
      expect(h.goutte!.vers, 'b');
      expect(h.goutte!.rompu, isFalse);

      // Le cou se rompt, puis la goutte s'acheve.
      bool rompu = false;
      for (int i = 0; i < 80 && !rompu; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        rompu = h.goutte?.rompu ?? true;
      }
      expect(rompu, isTrue);
      await _avancer(tester, 1500);
      expect(h.goutte, isNull);
    });

    for (final TextDirection direction in TextDirection.values) {
      testWidgets('le cou entre deux ronds ne descend jamais sous le tiers du '
          'diametre de la goutte, jusqu a la rupture (${direction.name})', (
        WidgetTester tester,
      ) async {
        final _Hote h = _Hote();
        await tester.pumpWidget(h.monter(direction: direction));
        await _avancer(tester, 700);
        int mesures = 0;
        for (final String prenom in <String>['Chaima', 'Amina']) {
          await tester.tap(find.text(prenom));
          await tester.pump();
          for (int i = 0; i < 80; i++) {
            await tester.pump(const Duration(milliseconds: 4));
            final ({double largeurCou, double diametreGoutte})? cou =
                GoutteProfils.couRondsDe(h.contexteContenu!);
            if (cou == null) continue;
            mesures++;
            expect(
              cou.largeurCou,
              greaterThanOrEqualTo(cou.diametreGoutte / 3 - 1e-9),
              reason: 'un fil plus fin que le tiers du diametre',
            );
          }
          await _avancer(tester, 1500);
        }
        expect(mesures, greaterThan(10), reason: 'le cou a ete mesure');
      });
    }

    testWidgets('dans les deux sens : le detachement part toujours du profil '
        'qu on quitte', (WidgetTester tester) async {
      final _Hote h = _Hote();
      await tester.pumpWidget(h.monter());
      await _avancer(tester, 700);
      await tester.tap(find.text('Bilal'));
      await _avancer(tester, 1500);
      await tester.tap(find.text('Amina'));
      await tester.pump();
      await tester.pump();
      expect(h.goutte!.de, 'b');
      expect(h.goutte!.vers, 'a');
      await _avancer(tester, 1500);
      expect(h.goutte, isNull);
    });

    testWidgets('une seule goutte a la fois : un second toucher acheve la '
        'premiere', (WidgetTester tester) async {
      final _Hote h = _Hote();
      await tester.pumpWidget(h.monter());
      await _avancer(tester, 700);
      await tester.tap(find.text('Bilal'));
      await _avancer(tester, 80);
      expect(h.goutte!.vers, 'b');
      await tester.tap(find.text('Chaima'));
      await tester.pump();
      await tester.pump();
      // Une seule goutte, et c'est celle de Bilal vers Chaima.
      expect(h.goutte!.de, 'b');
      expect(h.goutte!.vers, 'c');
      await _avancer(tester, 1500);
      expect(h.goutte, isNull);
    });

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

    testWidgets(
      'en miroir (arabe) : meme goutte, dans l autre sens de lecture',
      (WidgetTester tester) async {
        final _Hote h = _Hote();
        await tester.pumpWidget(h.monter(direction: TextDirection.rtl));
        await _avancer(tester, 700);
        // En arabe, Amina est a droite de Bilal.
        expect(
          tester.getCenter(find.text('Amina')).dx,
          greaterThan(tester.getCenter(find.text('Bilal')).dx),
        );
        await tester.tap(find.text('Bilal'));
        await tester.pump();
        await tester.pump();
        expect(h.goutte!.de, 'a');
        expect(h.goutte!.vers, 'b');
        await _avancer(tester, 1500);
        expect(h.goutte, isNull);
      },
    );

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

    testWidgets('changement de profil : le nouveau contenu est la dans la '
        'meme image que ses donnees, la chute se joue sur lui', (
      WidgetTester tester,
    ) async {
      final _Hote h = _Hote();
      await tester.pumpWidget(h.monter());
      await _avancer(tester, 900);
      expect(h.chute, isNull);

      h.selection.value = 'b';
      await _avancer(tester, 1200);
      // Les donnees du nouveau profil arrivent : le contenu change, tout de
      // suite, sans attendre ni cou ni aspiration.
      h.affiche.value = 'b';
      await tester.pump();
      expect(find.text('contenu b'), findsOneWidget);
      expect(find.text('contenu a'), findsNothing);
      await tester.pump();
      expect(h.chute, isNotNull);
      await _avancer(tester, 700);
      expect(h.chute, isNull);
      expect(find.text('contenu b'), findsOneWidget);
    });

    for (final TextDirection direction in TextDirection.values) {
      testWidgets('la nappe : son haut est celui de la premiere carte, le cou '
          'du contenu ne descend jamais sous le tiers du diametre, puis la '
          'nappe s efface (${direction.name})', (WidgetTester tester) async {
        final _Hote h = _Hote();
        await tester.pumpWidget(h.monter(direction: direction));
        await _avancer(tester, 900);
        h.selection.value = 'b';
        h.affiche.value = 'b';
        await tester.pump();
        final double hautCarte =
            tester
                .getTopLeft(find.byKey(const ValueKey<String>('carte-1')))
                .dy -
            tester.getTopLeft(find.byType(GoutteProfils)).dy;
        int nappes = 0;
        int cous = 0;
        for (int i = 0; i < 120 && h.chute != null || i == 0; i++) {
          await tester.pump(const Duration(milliseconds: 4));
          final ({Rect? nappe, double? largeurCou, double? diametreGoutte})?
          peint = GoutteProfils.peintContenuDe(h.contexteContenu!);
          if (peint == null) continue;
          final Rect? nappe = peint.nappe;
          if (nappe != null) {
            nappes++;
            expect(nappe.top, closeTo(hautCarte, 0.01));
          }
          final double? largeur = peint.largeurCou;
          if (largeur != null) {
            cous++;
            expect(
              largeur,
              greaterThanOrEqualTo(peint.diametreGoutte! / 3 - 1e-9),
              reason: 'un fil plus fin que le tiers du diametre',
            );
          }
        }
        expect(nappes, greaterThan(10));
        expect(cous, greaterThan(10));
        await _avancer(tester, 700);
        expect(GoutteProfils.peintContenuDe(h.contexteContenu!), isNull);
      });
    }

    testWidgets('mouvement reduit : aucune nappe, aucun cou', (
      WidgetTester tester,
    ) async {
      final _Hote h = _Hote();
      await tester.pumpWidget(h.monter(reduit: true));
      await _avancer(tester, 900);
      h.selection.value = 'b';
      h.affiche.value = 'b';
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(GoutteProfils.peintContenuDe(h.contexteContenu!), isNull);
        expect(GoutteProfils.couRondsDe(h.contexteContenu!), isNull);
      }
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

    testWidgets('le contenu n attend JAMAIS le cou entre les ronds '
        '(DECISION-FLUIDITE) : visible des l image du toucher', (
      WidgetTester tester,
    ) async {
      final _Hote h = _Hote();
      await tester.pumpWidget(h.monter());
      await _avancer(tester, 900);
      // Selection ET donnees dans la meme image (donnees deja en memoire).
      h.selection.value = 'b';
      h.affiche.value = 'b';
      await tester.pump();
      expect(find.text('contenu b'), findsOneWidget);
      expect(find.text('contenu a'), findsNothing);
      await tester.pump();
      // Le cou entre les ronds tient encore, et le contenu est deja la.
      expect(h.goutte, isNotNull);
      expect(h.chute, isNotNull);
      await _avancer(tester, 1500);
      expect(h.goutte, isNull);
      expect(h.chute, isNull);
      expect(find.text('contenu b'), findsOneWidget);
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
