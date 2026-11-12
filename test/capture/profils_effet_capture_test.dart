// Captures R3 de PROFILS-EFFET : la rangee de profils et son contenu, avant,
// pendant et apres le changement de profil (fondu court du contenu, anneau
// d'accent du profil selectionne) ; clair et sombre ; francais et arabe ;
// et le mouvement reduit (instantane). Saute sans CAPTURE_DIR. Donnees d'essai.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/fondu_contenu_profil.dart';
import 'package:rewayah_academy/core/widgets/selecteur_profils.dart';

import 'outil_capture.dart';

const List<ProfilSelectionnable> _profils = <ProfilSelectionnable>[
  ProfilSelectionnable(id: 'a', prenom: 'Amina', etat: 'Dans 3 h'),
  ProfilSelectionnable(id: 'b', prenom: 'Bilal', etat: 'Aucune séance'),
  ProfilSelectionnable(id: 'c', prenom: 'Chaima', etat: 'Demain'),
];

const Map<String, String> _contenus = <String, String>{
  'a': 'Contenu d\'Amina : sa classe, sa prochaine séance, son travail.',
  'b': 'Contenu de Bilal : aucune séance prévue pour le moment.',
  'c': 'Contenu de Chaima : sa séance de demain et son travail.',
};

class _Page extends StatefulWidget {
  const _Page();

  @override
  State<_Page> createState() => _EtatPage();
}

class _EtatPage extends State<_Page> {
  String _choisi = 'a';

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SelecteurProfils(
          profils: _profils,
          selectionId: _choisi,
          onSelection: (String id) => setState(() => _choisi = id),
        ),
        Ecart.vXl,
        FonduContenuProfil(
          profilId: _choisi,
          child: AppCard(child: Text(_contenus[_choisi]!)),
        ),
      ],
    ),
  );
}

/// L'hote du mouvement reduit : la page sous `disableAnimations`.
class _HoteReduit extends StatelessWidget {
  const _HoteReduit();

  @override
  Widget build(BuildContext context) => hoteCapture(
    const MediaQuery(
      data: MediaQueryData(disableAnimations: true),
      child: Scaffold(body: _Page()),
    ),
  );
}

void main() {
  tearDown(() async => LocaleSettings.setLocale(AppLocale.fr));

  group('Capture : PROFILS-EFFET', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final (String nomMode, ThemeMode mode) in <(String, ThemeMode)>[
      ('clair', ThemeMode.light),
      ('sombre', ThemeMode.dark),
    ]) {
      for (final String langue in <String>['fr', 'ar']) {
        final String base = 'profils_effet_${nomMode}_$langue';
        testWidgets('${base}_avant_pendant_apres', (WidgetTester tester) async {
          if (langue == 'ar') {
            await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
          }
          fixerVueCapture(tester, const Size(390, 420), 1);
          await tester.pumpWidget(
            hoteCapture(const Scaffold(body: _Page()), themeMode: mode),
          );
          await tester.pumpAndSettle();
          debugPrint('PNG ${await capturerVue(tester, '${base}_1_avant')}');
          await tester.tap(find.text('Bilal'));
          await tester.pump();
          await tester.pump(AppMouvement.fonduContenuProfil ~/ 2);
          debugPrint('PNG ${await capturerVue(tester, '${base}_2_pendant')}');
          await tester.pumpAndSettle();
          debugPrint('PNG ${await capturerVue(tester, '${base}_3_apres')}');
        });
      }
    }
    testWidgets('profils_effet_mouvement_reduit_clair_fr', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 420), 1);
      await tester.pumpWidget(const _HoteReduit());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bilal'));
      await tester.pump();
      debugPrint(
        'PNG ${await capturerVue(tester, 'profils_effet_mouvement_reduit_une_image_apres_le_toucher')}',
      );
    });
  });
}
