// LOT 3 · BIBLIOTHEQUE-UNE, cote direction : le formulaire existant de la
// bibliotheque d'administration, etendu (type, description, rayon, ordre,
// etapes, adresse d'un lien, vignette), par la vraie application.
//
// Ce que le test prouve : les nouveaux types se proposent ; un lien externe
// n'a aucun fichier a deposer et « Poursuivre » n'apparait qu'avec une adresse
// https (et la description) ; une adresse http est refusee a l'ecran ; la
// vignette se depose avec le meme circuit (intention, envoi, verification) ;
// le mot « support » ne s'affiche pas ; arabe et texte x2.
//
// Decisions D1 a D4 et correction C2 de l'architecte : les tranches d'age (le
// lien exclut les 6 a 9 ans d'emblee), la lecture du Coran et l'ecole suivie,
// les etapes cochees (jamais un code tape, une phrase quand rien n'est
// publie), la video par son lien, le depot de fichiers pas encore active.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/modeles_bibliotheque_admin.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/catalogue_local.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/donnees_catalogue.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/etapes_programme.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart'
    show tranchesToutes;
import 'package:rewayah_academy/core/widgets/case_a_cocher.dart';
import 'package:rewayah_academy/features/admin_pedagogie_bibliotheque/classement_document.dart';
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

class _Etapes implements PortEtapesProgramme {
  const _Etapes(this.etapes);
  final List<EtapeProgramme> etapes;

  @override
  Future<List<EtapeProgramme>> publiees() async => etapes;
}

Future<void> _monter(
  WidgetTester tester, {
  BibliothequeAdminDemo? demo,
  String? route,
  List<EtapeProgramme>? etapes,
  _Selecteur? selecteur,
  Size taille = const Size(1440, 900),
  double echelle = 1,
  TextDirection? direction,
}) => monterAdminDemo(
  tester,
  route: route ?? Routes.adminPedagogieBibliothequeNouveau,
  bibliotheque: demo ?? BibliothequeAdminDemo(),
  taille: taille,
  echelle: echelle,
  direction: direction,
  plus: <Override>[
    // Les rayons viennent du serveur ; le double local rend les deux.
    portCatalogueProvider.overrideWithValue(CatalogueLocal()),
    if (etapes != null)
      portEtapesProgrammeProvider.overrideWithValue(_Etapes(etapes)),
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
    expect(_cle('classement-tranches'), findsOneWidget);
    expect(_cle('classement-etapes'), findsOneWidget);
    // Aucune etape a taper : plus de champ de codes.
    expect(_cle('import-etapes'), findsNothing);
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
        (String s) => RegExp(
          r'prix|tarif|acheter|panier',
          caseSensitive: false,
        ).hasMatch(s),
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

  final cl = t.admin.bibliotheque.import.classement;

  bool? coche(WidgetTester tester, String cle) =>
      tester.widget<CaseACocher>(find.byKey(ValueKey<String>(cle))).valeur;

  testWidgets('D1 : un lien externe exclut les 6 a 9 ans, a cocher soi-meme', (
    tester,
  ) async {
    await _monter(tester, taille: const Size(1440, 2600));
    // Sans type choisi : les quatre tranches.
    for (final String c in tranchesTout) {
      expect(coche(tester, 'classement-tranche-$c'), isTrue);
    }
    await _choisirDansMenu(tester, i.champs.type, 'Lien externe');
    expect(coche(tester, 'classement-tranche-enfant_6_9'), isFalse);
    expect(coche(tester, 'classement-tranche-enfant_10_13'), isTrue);
    expect(coche(tester, 'classement-tranche-adulte_18_plus'), isTrue);
    expect(find.text(cl.tranchesAideLien), findsOneWidget);
    // La direction peut l'inclure explicitement.
    await _toucher(tester, _cle('classement-tranche-enfant_6_9'));
    expect(coche(tester, 'classement-tranche-enfant_6_9'), isTrue);
    // Et un type par fichier n'a pas cette phrase.
    await _choisirDansMenu(tester, 'Lien externe', 'PDF');
    expect(find.text(cl.tranchesAideLien), findsNothing);
    expect(find.text(cl.tranchesAide), findsOneWidget);
  });

  testWidgets('D1 : aucune tranche cochee, le document ne se cree pas', (
    tester,
  ) async {
    await _monter(tester, taille: const Size(1440, 2600));
    await tester.enterText(_cle('import-titre'), 'Sans tranche');
    await tester.enterText(_cle('import-categorie'), 'Lecture');
    await _choisirDansMenu(tester, i.champs.type, 'Lien externe');
    await _choisirDansMenu(tester, i.champs.langue, 'Français');
    await tester.enterText(_cle('import-lien'), 'https://exemple.org/a');
    await tester.enterText(_cle('import-description'), 'Un site.');
    await stabiliser(tester, fois: 2);
    expect(_cle('import-poursuivre'), findsOneWidget);
    for (final String c in tranchesLienParDefaut) {
      await _toucher(tester, _cle('classement-tranche-$c'));
    }
    expect(find.text(cl.tranchesAucune), findsOneWidget);
    expect(_cle('import-poursuivre'), findsNothing);
  });

  testWidgets('D3 : phrase quand le programme n\'est pas publie', (
    tester,
  ) async {
    await _monter(tester, taille: const Size(1440, 2600));
    await stabiliser(tester, fois: 3);
    expect(find.text(cl.etapesVide), findsOneWidget);
    expect(_cle('classement-etapes-vide'), findsOneWidget);
  });

  testWidgets('D3 : les etapes du programme publie se cochent', (tester) async {
    await _monter(
      tester,
      taille: const Size(1440, 2600),
      etapes: const <EtapeProgramme>[
        EtapeProgramme(code: 'E-01', nom: 'Lettres et sons', cycle: 'Debut'),
        EtapeProgramme(code: 'E-02', nom: 'Premiers mots', cycle: 'Debut'),
      ],
    );
    await stabiliser(tester, fois: 3);
    expect(find.text(cl.etapesVide), findsNothing);
    expect(find.text('Lettres et sons'), findsOneWidget);
    expect(coche(tester, 'classement-etape-E-01'), isFalse);
    await _toucher(tester, _cle('classement-etape-E-01'));
    expect(coche(tester, 'classement-etape-E-01'), isTrue);
    expect(coche(tester, 'classement-etape-E-02'), isFalse);
  });

  testWidgets('D4 : une video se donne par son lien, la phrase le dit', (
    tester,
  ) async {
    await _monter(tester, taille: const Size(1440, 2600));
    expect(_cle('import-video-lien'), findsNothing);
    await _choisirDansMenu(tester, i.champs.type, 'Vidéo');
    expect(find.text('Pour une vidéo, collez son lien.'), findsOneWidget);
    expect(_cle('import-lien'), findsOneWidget);
    expect(_cle('import-choisir-support'), findsNothing);
  });

  testWidgets('C2 : depot de fichiers non active, le dit et le lien marche', (
    tester,
  ) async {
    final BibliothequeAdminDemo demo = BibliothequeAdminDemo()
      ..depotActifServeur = false;
    await _monter(demo: demo, tester, taille: const Size(1440, 2800));
    await stabiliser(tester, fois: 3);
    await tester.enterText(_cle('import-titre'), 'Un site de reference');
    await tester.enterText(_cle('import-categorie'), 'Lecture');
    await _choisirDansMenu(tester, i.champs.type, 'PDF');
    await _choisirDansMenu(tester, i.champs.langue, 'Français');
    // Une phrase en mots simples, aucun bouton qui echouerait, aucun code.
    expect(find.text(cl.depotInactif), findsOneWidget);
    expect(_cle('import-choisir-support'), findsNothing);
    expect(_cle('import-choisir-vignette'), findsNothing);
    expect(_cle('import-choisir-preuve'), findsNothing);
    expect(_cle('import-poursuivre'), findsNothing);
    // Le lien externe, lui, se depose et se poursuit.
    await _choisirDansMenu(tester, 'PDF', 'Lien externe');
    await tester.enterText(_cle('import-lien'), 'https://exemple.org/a');
    await tester.enterText(_cle('import-description'), 'Un site.');
    await stabiliser(tester, fois: 2);
    expect(find.text(cl.depotInactif), findsOneWidget);
    expect(_cle('import-poursuivre'), findsOneWidget);
  });

  testWidgets('I1 : sans reponse sur le depot, aucun bouton de fichier', (
    tester,
  ) async {
    final BibliothequeAdminDemo demo = BibliothequeAdminDemo()
      ..panneDepot = true;
    await _monter(demo: demo, tester, taille: const Size(1440, 2800));
    await stabiliser(tester, fois: 3);
    await _choisirDansMenu(tester, i.champs.type, 'PDF');
    // L'erreur n'est pas avalee en « active » : ni fichier, ni vignette, ni
    // preuve ; une phrase en mots simples, et le lien reste possible.
    expect(find.text(cl.depotInconnu), findsOneWidget);
    expect(find.text(cl.depotInactif), findsNothing);
    expect(_cle('import-choisir-support'), findsNothing);
    expect(_cle('import-choisir-vignette'), findsNothing);
    expect(_cle('import-choisir-preuve'), findsNothing);
    await tester.enterText(_cle('import-titre'), 'Un site');
    await tester.enterText(_cle('import-categorie'), 'Lecture');
    await _choisirDansMenu(tester, 'PDF', 'Lien externe');
    await _choisirDansMenu(tester, i.champs.langue, 'Français');
    await tester.enterText(_cle('import-lien'), 'https://exemple.org/a');
    await tester.enterText(_cle('import-description'), 'Un site.');
    await stabiliser(tester, fois: 2);
    expect(_cle('import-poursuivre'), findsOneWidget);
  });

  testWidgets('C2 : depot actif, aucune phrase d\'inactivite', (tester) async {
    await _monter(tester, taille: const Size(1440, 2600));
    await stabiliser(tester, fois: 3);
    await _choisirDansMenu(tester, i.champs.type, 'PDF');
    expect(find.text(cl.depotInactif), findsNothing);
    expect(_cle('import-choisir-support'), findsOneWidget);
  });

  testWidgets('D1 D2 D3 : ce qui est saisi part au serveur et se relit', (
    tester,
  ) async {
    final BibliothequeAdminDemo demo = BibliothequeAdminDemo();
    await _monter(
      demo: demo,
      tester,
      taille: const Size(1440, 3200),
      etapes: const <EtapeProgramme>[
        EtapeProgramme(code: 'E-01', nom: 'Lettres et sons'),
      ],
    );
    await stabiliser(tester, fois: 3);
    await tester.enterText(_cle('import-titre'), 'Ablutions du Coran');
    await tester.enterText(_cle('import-categorie'), 'Priere');
    await _choisirDansMenu(tester, i.champs.type, 'Lien externe');
    await _choisirDansMenu(tester, i.champs.langue, 'Français');
    await tester.enterText(_cle('import-lien'), 'https://exemple.org/a');
    await tester.enterText(_cle('import-description'), 'Un site.');
    await _toucher(tester, _cle('classement-tranche-ado_14_17'));
    await _toucher(tester, _cle('classement-etape-E-01'));
    await _choisirDansMenu(tester, cl.lectureTitre, 'Warsh');
    await tester.enterText(_cle('classement-ecole'), 'Malikite');
    await stabiliser(tester, fois: 2);
    await _toucher(tester, _cle('import-poursuivre'));
    await stabiliser(tester, fois: 6);
    final PageSupports page = await demo.lister(
      filtre: const FiltreCatalogue(recherche: 'Ablutions'),
    );
    expect(page.elements, hasLength(1));
    final FicheSupport fiche = await demo.fiche(page.elements.first.id);
    expect(fiche.tranches, <String>['enfant_10_13', 'adulte_18_plus']);
    expect(fiche.etapes, <String>['E-01']);
    expect(fiche.lectureCoran, 'warsh');
    expect(fiche.ecolePriere, 'Malikite');
    // Le filtre de la direction retrouve le document par sa lecture.
    expect(
      (await demo.lister(filtre: const FiltreCatalogue(lectureCoran: 'warsh')))
          .elements
          .map((SupportAdmin s) => s.id),
      contains(page.elements.first.id),
    );
    expect(
      (await demo.lister(filtre: const FiltreCatalogue(lectureCoran: 'qalun')))
          .elements,
      isEmpty,
    );
  });

  testWidgets('la fiche : tranches, etapes, lecture et ecole se modifient', (
    tester,
  ) async {
    final BibliothequeAdminDemo demo = BibliothequeAdminDemo();
    await _monter(
      demo: demo,
      tester,
      route: Routes.adminPedagogieSupport('demo-support-001'),
      taille: const Size(1440, 3600),
      etapes: const <EtapeProgramme>[
        EtapeProgramme(code: 'E-01', nom: 'Lettres et sons'),
      ],
    );
    await stabiliser(tester, fois: 4);
    expect(coche(tester, 'classement-tranche-enfant_6_9'), isTrue);
    await _toucher(tester, _cle('classement-tranche-enfant_6_9'));
    await _toucher(tester, _cle('classement-etape-E-01'));
    await _choisirDansMenu(tester, cl.lectureTitre, 'Hafs');
    await tester.enterText(_cle('classement-ecole'), 'Hanafite');
    await _toucher(tester, _cle('fiche-enregistrer'));
    await stabiliser(tester, fois: 4);
    final FicheSupport f = await demo.fiche('demo-support-001');
    expect(f.tranches, <String>['enfant_10_13', 'ado_14_17', 'adulte_18_plus']);
    expect(f.etapes, <String>['E-01']);
    expect(f.lectureCoran, 'hafs');
    expect(f.ecolePriere, 'Hanafite');
  });

  testWidgets('la fiche : aucune tranche, rien n\'est enregistre', (
    tester,
  ) async {
    final BibliothequeAdminDemo demo = BibliothequeAdminDemo();
    await _monter(
      demo: demo,
      tester,
      route: Routes.adminPedagogieSupport('demo-support-001'),
      taille: const Size(1440, 3600),
    );
    await stabiliser(tester, fois: 4);
    for (final String c in tranchesTout) {
      await _toucher(tester, _cle('classement-tranche-$c'));
    }
    expect(find.text(cl.tranchesAucune), findsOneWidget);
    await _toucher(tester, _cle('fiche-enregistrer'));
    await stabiliser(tester, fois: 3);
    expect((await demo.fiche('demo-support-001')).tranches, tranchesToutes);
  });

  testWidgets('D2 : une ecole trop longue est refusee a l\'ecran', (
    tester,
  ) async {
    await _monter(tester, taille: const Size(1440, 2600));
    await tester.enterText(_cle('classement-ecole'), 'x' * 81);
    await stabiliser(tester, fois: 2);
    expect(find.text(cl.ecoleTrop), findsOneWidget);
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
