// LOT 3 · BIBLIOTHEQUE-UNE, cote direction : le formulaire existant de la
// bibliotheque d'administration, etendu (type, description, rayon, ordre,
// etapes, adresse d'un lien, vignette), par la vraie application.
//
// Ce que le test prouve : les nouveaux types se proposent ; un lien externe
// n'a aucun fichier a deposer et « Poursuivre » n'apparait qu'avec une adresse
// https (et la description) ; une adresse http est refusee a l'ecran ; la
// vignette se depose avec le meme circuit (intention, envoi, verification) ;
// le mot « support » ne s'affiche pas ; arabe et texte x2.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/modeles_bibliotheque_admin.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/catalogue_local.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/donnees_catalogue.dart';
import 'package:rewayah_academy/features/admin_pedagogie_bibliotheque/import/selecteur_support.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/demo/bibliotheque_admin_demo.dart';
import '../../support/monter_admin_demo.dart';

class _Selecteur implements SelecteurFichierSupport {
  final List<TypeRessource> demandes = <TypeRessource>[];

  @override
  Future<FichierChoisi?> choisir(TypeRessource type) async {
    demandes.add(type);
    return FichierChoisi(
      nom: 'vignette.png',
      octets: Uint8List(2048),
      mime: 'image/png',
    );
  }
}

Future<void> _monter(
  WidgetTester tester, {
  _Selecteur? selecteur,
  Size taille = const Size(1440, 900),
  double echelle = 1,
  TextDirection? direction,
}) => monterAdminDemo(
  tester,
  route: Routes.adminPedagogieBibliothequeNouveau,
  bibliotheque: BibliothequeAdminDemo(),
  taille: taille,
  echelle: echelle,
  direction: direction,
  plus: <Override>[
    // Les rayons viennent du serveur ; le double local rend les deux.
    portCatalogueProvider.overrideWithValue(CatalogueLocal()),
    selecteurFichierSupportProvider.overrideWithValue(
      selecteur ?? _Selecteur(),
    ),
  ],
);

Finder _cle(String k) => find.byKey(ValueKey<String>(k));

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await stabiliser(tester, fois: 2);
  await tester.tap(f);
  await stabiliser(tester, fois: 2);
}

Future<void> _choisirDansMenu(
  WidgetTester tester,
  String menu,
  String entree,
) async {
  await _toucher(tester, find.text(menu).first);
  await stabiliser(tester, fois: 3);
  await tester.tap(find.text(entree).last);
  await stabiliser(tester, fois: 3);
}

final RegExp _motSupport = RegExp(r'\bsupports?\b', caseSensitive: false);

List<String> _textes(WidgetTester tester) => <String>[
  for (final Text w in tester.widgetList<Text>(find.byType(Text)))
    if (w.data != null) w.data!,
];

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  final i = t.admin.bibliotheque.import;

  testWidgets('le formulaire porte description, rayon, ordre, etapes', (
    tester,
  ) async {
    await _monter(tester);
    expect(_cle('import-description'), findsOneWidget);
    expect(_cle('import-ordre'), findsOneWidget);
    expect(_cle('import-etapes'), findsOneWidget);
    // Le rayon se choisit parmi ceux du serveur : celui des cours d'abord, et
    // le second s'offre au choix (sans prix ni mot d'argent).
    expect(find.text('Documents des cours'), findsWidgets);
    await _toucher(tester, find.text('Documents des cours').first);
    await stabiliser(tester, fois: 3);
    expect(find.text('Pour aller plus loin'), findsWidgets);
    // Aucun mot d'argent, aucun mot « support ».
    final List<String> textes = _textes(tester);
    expect(textes.where(_motSupport.hasMatch), isEmpty);
    expect(
      textes.where(
        (String s) => RegExp(r'prix|tarif|acheter|panier', caseSensitive: false)
            .hasMatch(s),
      ),
      isEmpty,
    );
  });

  testWidgets('un lien externe : aucun fichier, adresse https exigee', (
    tester,
  ) async {
    await _monter(tester, taille: const Size(1440, 2200));
    await tester.enterText(_cle('import-titre'), 'Un site de reference');
    await tester.enterText(_cle('import-categorie'), 'Lecture');
    await _choisirDansMenu(tester, i.champs.type, 'Lien externe');
    await _choisirDansMenu(tester, i.champs.langue, 'Français');
    // Pas de bouton de fichier qui ne pourrait pas aboutir ; la phrase le dit.
    expect(_cle('import-choisir-support'), findsNothing);
    expect(find.text(i.formats.lien), findsOneWidget);
    expect(_cle('import-lien'), findsOneWidget);
    // Sans adresse ni description : pas de « Poursuivre ».
    expect(_cle('import-poursuivre'), findsNothing);
    expect(find.text(i.completerLien), findsWidgets);
    // Une adresse http est refusee a l'ecran.
    await tester.enterText(_cle('import-lien'), 'http://exemple.org/a');
    await stabiliser(tester, fois: 2);
    expect(find.text(i.lienInvalide), findsOneWidget);
    expect(_cle('import-poursuivre'), findsNothing);
    // Une adresse https, sans description : toujours pas.
    await tester.enterText(_cle('import-lien'), 'https://exemple.org/a');
    await stabiliser(tester, fois: 2);
    expect(find.text(i.lienInvalide), findsNothing);
    expect(_cle('import-poursuivre'), findsNothing);
    // Avec la description : on peut poursuivre.
    await tester.enterText(
      _cle('import-description'),
      'Un site pour aller plus loin.',
    );
    await stabiliser(tester, fois: 2);
    expect(_cle('import-poursuivre'), findsOneWidget);
  });

  testWidgets('une adresse IP n\'est pas un lien accepte', (tester) async {
    await _monter(tester, taille: const Size(1440, 2200));
    await _choisirDansMenu(tester, i.champs.type, 'Vidéo');
    await tester.enterText(_cle('import-lien'), 'https://10.0.0.1/v');
    await stabiliser(tester, fois: 2);
    expect(find.text(i.lienInvalide), findsOneWidget);
  });

  testWidgets('la vignette se depose par le meme circuit, en image', (
    tester,
  ) async {
    final _Selecteur selecteur = _Selecteur();
    await _monter(tester, selecteur: selecteur, taille: const Size(1440, 2400));
    await tester.enterText(_cle('import-titre'), 'Le livre');
    await tester.enterText(_cle('import-categorie'), 'Lecture');
    await _choisirDansMenu(tester, i.champs.type, 'PDF');
    await _choisirDansMenu(tester, i.champs.langue, 'Français');
    expect(find.text(i.vignetteAide), findsOneWidget);
    await _toucher(tester, _cle('import-choisir-vignette'));
    await stabiliser(tester, fois: 8);
    // La vignette demande une image, jamais le type du document.
    expect(selecteur.demandes, <TypeRessource>[TypeRessource.image]);
    expect(_cle('import-nom-vignette'), findsOneWidget);
    expect(find.text(i.etats.pret), findsWidgets);
  });

  testWidgets('en arabe, a 320 px et texte x2 : aucun mot coupe', (
    tester,
  ) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
    await _monter(
      tester,
      taille: const Size(320, 3200),
      echelle: 2,
      direction: TextDirection.rtl,
    );
    expect(_cle('import-description'), findsOneWidget);
    expect(_textes(tester).where(_motSupport.hasMatch), isEmpty);
    expect(motsCoupes(tester, find.byType(Scaffold).first), isEmpty);
  });
}
