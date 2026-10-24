// FINITIONS-CORR2-1, point (2) : dans la feuille des cartes de la Classe,
// chaque champ (titre, texte, lien) porte son nom pour le lecteur d'ecran,
// et le nom ecrit au-dessus n'est pas lu une seconde fois.
//
// La garde lit l'arbre semantique rendu : le noeud du champ de texte doit
// porter le nom du champ ; un seul noeud porte ce nom.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter/semantics.dart' show SemanticsFlag;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/tc_groupe/cartes_classe.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/cartes_classe_demo.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/feuille_carte_classe.dart';

import '../../support/harnais.dart' show FauxServiceReseau;

Widget _hote({double echelle = 1}) => ProviderScope(
  overrides: <Override>[
    serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
    horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
    portCartesClasseProvider.overrideWith(
      (Ref _) => PortCartesClasseDemo(
        peutModifier: true,
        cartes: const <CarteClasse>[],
      ),
    ),
  ],
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      locale: AppLocale.fr.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (BuildContext c, Widget? app) => MediaQuery(
        data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(echelle)),
        child: app!,
      ),
      home: const Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: FeuilleCarteClasse(groupeId: 'classe-test'),
        ),
      ),
    ),
  ),
);

/// Le noeud semantique du champ de cle [cle] : celui qui porte le drapeau
/// de champ de texte.
SemanticsNode _champ(WidgetTester tester, Key cle) {
  SemanticsNode? n = tester.getSemantics(
    find.descendant(of: find.byKey(cle), matching: find.byType(EditableText)),
  );
  // ignore: deprecated_member_use
  while (n != null && !n.hasFlag(SemanticsFlag.isTextField)) {
    n = n.parent;
  }
  expect(n, isNotNull, reason: 'aucun champ de texte sous $cle');
  return n!;
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  for (final double echelle in <double>[1, 2]) {
    testWidgets('les trois champs portent leur nom, lu une seule fois '
        '(texte x$echelle)', (WidgetTester tester) async {
      final SemanticsHandle poignee = tester.ensureSemantics();
      tester.view.physicalSize = const Size(320, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_hote(echelle: echelle));
      await tester.pumpAndSettle();

      final String titre = t.classe.cartes.feuille.champTitre;
      final String texte = t.classe.cartes.feuille.champTexte;
      final String lien = t.classe.cartes.feuille.champLien;

      expect(
        _champ(tester, FeuilleCarteClasse.titreKey).label,
        contains(titre),
      );
      expect(
        _champ(tester, FeuilleCarteClasse.texteKey).label,
        contains(texte),
      );
      expect(_champ(tester, FeuilleCarteClasse.lienKey).label, contains(lien));

      // Le nom ecrit au-dessus n'est pas un noeud lu a part : un seul noeud
      // le porte, celui du champ.
      for (final String nom in <String>[titre, texte, lien]) {
        expect(
          find.bySemanticsLabel(RegExp(RegExp.escape(nom))),
          findsOneWidget,
          reason: '« $nom » doit etre lu une fois, sur le champ',
        );
      }
      poignee.dispose();
    });
  }
}
