// DEPOT-SIMPLE (13/11/2026) : ajouter un document, le strict necessaire.
//
// Ce que le test prouve : au depart une seule chose a faire (choisir un
// fichier) ; le type se lit dans le CONTENU du fichier, pas dans son
// extension ; un nom arabe passe, le nom est prerempli sans extension ni
// suffixe de copie ; l'envoi part des le fichier choisi ; un seul bouton, rendu
// seulement fichier verifie ; l'acces et le rangement partent au serveur ; un
// lien reste possible par un geste discret ; « Plus de reglages » est replie ;
// plus de vignette dans le formulaire ; CHAQUE cause d'echec a sa phrase, et
// « la connexion a coupe » ne s'affiche que pour une vraie absence de reponse ;
// reprise d'un brouillon ; sans capacite, rien ; 320 px, texte x2, LTR et RTL.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/modeles_bibliotheque_admin.dart';
import 'package:rewayah_academy/core/admin/port_bibliotheque_admin.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/donnees_catalogue.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/theme/app_typography.dart';
import 'package:rewayah_academy/features/admin_pedagogie_bibliotheque/import/import_page.dart';
import 'package:rewayah_academy/features/admin_pedagogie_bibliotheque/import/selecteur_support.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/catalogue_local.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/demo/bibliotheque_admin_demo.dart';
import '../../support/garde_interface.dart';
import '../../support/monter_admin_demo.dart';

class _Selecteur implements SelecteurFichierSupport {
  _Selecteur(this.fichier);

  FichierChoisi? fichier;
  final List<TypeRessource> demandes = <TypeRessource>[];
  int documents = 0;

  @override
  Future<FichierChoisi?> choisir(TypeRessource type) async {
    demandes.add(type);
    return fichier;
  }

  @override
  Future<FichierChoisi?> choisirDocument() async {
    documents++;
    return fichier;
  }
}

Uint8List _octets(List<int> signature, {int taille = 1024}) {
  final Uint8List o = Uint8List(taille);
  o.setRange(0, signature.length, signature);
  return o;
}

const List<int> _sigPdf = <int>[0x25, 0x50, 0x44, 0x46, 0x2d, 0x31, 0x2e, 0x37];
const List<int> _sigPng = <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
const List<int> _sigMp3 = <int>[0x49, 0x44, 0x33, 0x04];
// « ....ftypisom » : un conteneur MP4 de video.
const List<int> _sigMp4 = <int>[
  0, 0, 0, 0x18, 0x66, 0x74, 0x79, 0x70, 0x69, 0x73, 0x6f, 0x6d, //
];

FichierChoisi _fichier(String nom, List<int> signature, {int taille = 1024}) =>
    FichierChoisi(
      nom: nom,
      octets: _octets(signature, taille: taille),
      // Le selecteur ne dit plus le type : l'ecran le lit dans le contenu.
      mime: 'application/octet-stream',
    );

FichierChoisi _pdf([String nom = 'cours-tajwid.pdf']) => _fichier(nom, _sigPdf);

Future<void> _monter(
  WidgetTester tester, {
  BibliothequeAdminDemo? port,
  _Selecteur? selecteur,
  String route = Routes.adminPedagogieBibliothequeNouveau,
  Size taille = const Size(1440, 900),
  double echelle = 1,
  TextDirection? direction,
}) => monterAdminDemo(
  tester,
  route: route,
  bibliotheque: port ?? BibliothequeAdminDemo(),
  taille: taille,
  echelle: echelle,
  direction: direction,
  plus: <Override>[
    // Les rayons viennent du serveur ; le double local rend les deux.
    portCatalogueProvider.overrideWithValue(CatalogueLocal()),
    selecteurFichierSupportProvider.overrideWithValue(
      selecteur ?? _Selecteur(_pdf()),
    ),
  ],
);

Finder _cle(String k) => find.byKey(ValueKey<String>(k));

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await stabiliser(tester, fois: 2);
  if (tester.getCenter(f).dy < 300) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 300));
    await stabiliser(tester, fois: 2);
  }
  await tester.tap(f);
  await stabiliser(tester, fois: 2);
}

Future<void> _deposer(WidgetTester tester) async {
  await _toucher(tester, _cle('import-choisir-support'));
  await stabiliser(tester, fois: 40);
}

void main() {
  final i = t.admin.bibliotheque.import;
  final s = i.simple;

  testWidgets('au depart : une seule chose a faire, choisir un fichier', (
    tester,
  ) async {
    await _monter(tester);
    expect(_cle('import-intro'), findsOneWidget);
    expect(_cle('import-choisir-support'), findsOneWidget);
    expect(_cle('import-lien-a-la-place'), findsOneWidget);
    // Rien d'autre : ni nom, ni type, ni langue, ni categorie, ni vignette, ni
    // droits a remplir avant d'avoir choisi le fichier.
    expect(_cle('import-document'), findsNothing);
    expect(_cle('import-plus'), findsNothing);
    expect(find.text(i.champs.type), findsNothing);
    expect(find.text(i.champs.langue), findsNothing);
    expect(find.text(i.champs.categorie), findsNothing);
    expect(find.text(i.vignette), findsNothing);
    expect(_cle('import-poursuivre'), findsNothing);
    expect(find.text(s.aideFichier), findsOneWidget);
    verifierUnSeulBoutonPlein(tester);
  });

  testWidgets('un PDF au nom arabe : reconnu, nom prerempli, envoi immediat', (
    tester,
  ) async {
    final BibliothequeAdminDemo port = BibliothequeAdminDemo(nombre: 0);
    await _monter(
      tester,
      port: port,
      selecteur: _Selecteur(_pdf('متن الأخضري-1.pdf')),
    );
    // Un seul geste : choisir le fichier. L'envoi part sans autre saisie.
    await _toucher(tester, _cle('import-choisir-support'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(_cle('import-progression-support'), findsOneWidget);
    expect(_cle('import-poursuivre'), findsNothing);
    expect(find.text(s.aideEnvoi), findsOneWidget);
    await stabiliser(tester, fois: 40);
    expect(find.text(i.etats.pret), findsOneWidget);
    // Le type est dit, jamais demande.
    expect(
      find.text(s.reconnu(type: t.admin.bibliotheque.libelles.type.pdf)),
      findsOneWidget,
    );
    // Le nom : sans extension, sans le « -1 » d'une copie.
    final TextField nom = tester.widget<TextField>(
      find
              .descendant(
                of: _cle('import-nom'),
                matching: find.byType(TextField),
              )
              .evaluate()
              .isEmpty
          ? _cle('import-nom')
          : find.descendant(
              of: _cle('import-nom'),
              matching: find.byType(TextField),
            ),
    );
    expect(nom.controller!.text, 'متن الأخضري');
    // Le nom du fichier est du contenu arabe : police du contenu arabe.
    final Text affiche = tester.widget<Text>(_cle('import-nom-support'));
    expect(
      affiche.style?.fontFamily,
      AppTypography.arabeContenu(const TextStyle()).fontFamily,
    );
    // Le brouillon : PDF, en arabe (langue deduite du nom).
    final SupportAdmin cree = (await port.lister()).elements.single;
    expect(cree.type, TypeRessource.pdf);
    expect(cree.langue, 'ar');
    expect(cree.titre, 'متن الأخضري');
    expect(cree.statutVersion, StatutVersionRessource.brouillon);
    expect(_cle('import-poursuivre'), findsOneWidget);
    verifierUnSeulBoutonPlein(tester);
  });

  testWidgets('le type vient du contenu, pas de l\'extension', (tester) async {
    final BibliothequeAdminDemo port = BibliothequeAdminDemo(nombre: 0);
    await _monter(
      tester,
      port: port,
      // Un audio dont le nom ment sur l'extension.
      selecteur: _Selecteur(_fichier('recitation.pdf', _sigMp3)),
    );
    await _deposer(tester);
    expect(
      find.text(s.reconnu(type: t.admin.bibliotheque.libelles.type.audio)),
      findsOneWidget,
    );
    expect((await port.lister()).elements.single.type, TypeRessource.audio);
    expect(find.text(i.etats.pret), findsOneWidget);
  });

  testWidgets('une image est reconnue', (tester) async {
    final BibliothequeAdminDemo port = BibliothequeAdminDemo(nombre: 0);
    await _monter(
      tester,
      port: port,
      selecteur: _Selecteur(_fichier('alphabet.png', _sigPng)),
    );
    await _deposer(tester);
    expect((await port.lister()).elements.single.type, TypeRessource.image);
  });

  group('fichier non pris : la phrase dit pourquoi, rien ne part', () {
    Future<void> refus(
      WidgetTester tester,
      FichierChoisi fichier,
      String phrase,
    ) async {
      final BibliothequeAdminDemo port = BibliothequeAdminDemo(nombre: 0);
      await _monter(tester, port: port, selecteur: _Selecteur(fichier));
      await _deposer(tester);
      expect(find.text(phrase), findsOneWidget);
      expect((await port.lister()).elements, isEmpty);
      expect(_cle('import-poursuivre'), findsNothing);
      // On peut choisir un autre fichier, ou donner un lien.
      expect(_cle('import-choisir-support'), findsOneWidget);
      expect(_cle('import-lien-a-la-place'), findsOneWidget);
    }

    testWidgets('une video : par son lien', (tester) async {
      await refus(tester, _fichier('cours.mp4', _sigMp4), s.refus.video);
    });
    testWidgets('un type inconnu', (tester) async {
      await refus(
        tester,
        _fichier('notes.pdf', <int>[0x50, 0x4b, 0x03, 0x04]),
        s.refus.inconnu,
      );
    });
    testWidgets('un fichier vide', (tester) async {
      await refus(
        tester,
        FichierChoisi(nom: 'vide.pdf', octets: Uint8List(0), mime: ''),
        s.refus.vide,
      );
    });
    testWidgets('une image trop lourde : le plafond est dit', (tester) async {
      await refus(
        tester,
        _fichier('grande.png', _sigPng, taille: 10 * 1024 * 1024 + 1),
        LibellesGroupe.valeurSeule(s.refus.tropLourd(limite: '10')),
      );
    });
  });

  group('une cause, une phrase vraie', () {
    test('toutes les phrases different, « connexion » n\'a qu\'une cause', () {
      final Map<ErreurUpload, String> phrases = <ErreurUpload, String>{
        for (final ErreurUpload e in ErreurUpload.values)
          e: phraseErreurDepot(e),
      };
      expect(phrases.values.toSet().length, ErreurUpload.values.length);
      for (final MapEntry<ErreurUpload, String> e in phrases.entries) {
        if (e.key == ErreurUpload.reseau) continue;
        expect(e.value, isNot(i.erreurs.reseau), reason: e.key.name);
      }
      // Une cause inconnue n'est pas « la connexion ».
      expect(phraseErreurDepot(null), i.erreurs.service);
      // Un reglage du serveur ne se dit jamais « connexion ».
      for (final ErreurUpload e in <ErreurUpload>[
        ErreurUpload.stockage,
        ErreurUpload.envoi,
        ErreurUpload.service,
        ErreurUpload.reglage,
        ErreurUpload.nonActive,
      ]) {
        expect(phrases[e], isNot(contains('connexion s\'est interrompue')));
      }
    });

    test('une exception de la demande garde sa cause', () {
      expect(
        causeDeLaDemande(const DepotImpossible(ErreurUpload.stockage)),
        ErreurUpload.stockage,
      );
      expect(
        causeDeLaDemande(const BibliothequeNonAutorisee()),
        ErreurUpload.refuse,
      );
      expect(
        causeDeLaDemande(const BibliothequeHorsLigne()),
        ErreurUpload.reseau,
      );
      // Une erreur imprevue n'est pas « la connexion ».
      expect(causeDeLaDemande(StateError('x')), ErreurUpload.service);
    });

    for (final ErreurUpload cause in ErreurUpload.values) {
      testWidgets('la demande de depot echoue (${cause.name})', (tester) async {
        final BibliothequeAdminDemo port = BibliothequeAdminDemo(nombre: 0)
          ..echecDemande = cause;
        await _monter(tester, port: port);
        await _deposer(tester);
        // Avant ce lot : toute erreur de la demande disait « la connexion
        // s'est interrompue ».
        expect(find.text(phraseErreurDepot(cause)), findsOneWidget);
        if (cause != ErreurUpload.reseau) {
          expect(find.text(i.erreurs.reseau), findsNothing);
        }
        expect(_cle('import-poursuivre'), findsNothing);
      });
    }

    testWidgets('echec pendant l\'envoi, puis « Reessayer » aboutit', (
      tester,
    ) async {
      final BibliothequeAdminDemo port = BibliothequeAdminDemo(nombre: 0)
        ..echecDepot = ErreurUpload.envoi;
      final _Selecteur sel = _Selecteur(_pdf());
      await _monter(tester, port: port, selecteur: sel);
      await _deposer(tester);
      expect(find.text(i.erreurs.envoi), findsOneWidget);
      expect(find.text(i.erreurs.reseau), findsNothing);
      // Reessayer renvoie le meme fichier, sans le rechoisir, dans le meme
      // brouillon.
      await _toucher(tester, _cle('import-reessayer'));
      await stabiliser(tester, fois: 40);
      expect(find.text(i.etats.pret), findsOneWidget);
      expect(sel.documents, 1);
      expect((await port.lister()).elements, hasLength(1));
    });
  });

  testWidgets('annuler pendant l\'envoi', (tester) async {
    await _monter(
      tester,
      port: BibliothequeAdminDemo(
        nombre: 0,
        pas: const Duration(milliseconds: 1500),
      ),
    );
    await _toucher(tester, _cle('import-choisir-support'));
    await tester.pump(const Duration(milliseconds: 200));
    // Pas de remplacement pendant l'envoi.
    expect(_cle('import-choisir-support'), findsNothing);
    await _toucher(tester, _cle('import-annuler-support'));
    await stabiliser(tester, fois: 40);
    expect(find.text(i.etats.annule), findsOneWidget);
    expect(_cle('import-poursuivre'), findsNothing);
    expect(_cle('import-choisir-support'), findsOneWidget);
  });

  testWidgets('par defaut : lecture dans l\'application, rayon des cours', (
    tester,
  ) async {
    final BibliothequeAdminDemo port = BibliothequeAdminDemo(nombre: 0);
    await _monter(tester, port: port);
    await _deposer(tester);
    await _toucher(tester, _cle('import-poursuivre'));
    await stabiliser(tester, fois: 6);
    final String id = (await port.lister()).elements.single.id;
    final FicheSupport fiche = await port.fiche(id);
    expect(fiche.droits.usages, <UsageDroit>{
      UsageDroit.application,
      UsageDroit.classe,
    });
    expect(fiche.rayon, codeRayonCours);
    expect(fiche.support.titre, 'cours-tajwid');
    // Le bouton mene a la verification avant publication, jamais a « publie ».
    expect(fiche.support.statutVersion, StatutVersionRessource.brouillon);
    expect(_cle('import-contenu'), findsNothing);
  });

  testWidgets('nom corrige, description, telechargement, autre rayon', (
    tester,
  ) async {
    final BibliothequeAdminDemo port = BibliothequeAdminDemo(nombre: 0);
    await _monter(tester, port: port);
    await _deposer(tester);
    await tester.enterText(_cle('import-nom'), 'Cours de tajwid');
    await tester.enterText(_cle('import-description'), 'Les bases.');
    await _toucher(tester, find.text(s.acces.telechargement));
    await _toucher(tester, find.text('Pour aller plus loin'));
    await _toucher(tester, _cle('import-poursuivre'));
    await stabiliser(tester, fois: 6);
    final String id = (await port.lister()).elements.single.id;
    final FicheSupport fiche = await port.fiche(id);
    expect(fiche.support.titre, 'Cours de tajwid');
    expect(fiche.description, 'Les bases.');
    expect(fiche.droits.usages, contains(UsageDroit.telechargement));
    expect(fiche.rayon, codeRayonPlusLoin);
  });

  testWidgets('le rangement : les rayons du serveur, aucun mot d\'argent', (
    tester,
  ) async {
    await _monter(tester);
    await _deposer(tester);
    expect(find.text('Documents des cours'), findsOneWidget);
    expect(find.text('Pour aller plus loin'), findsOneWidget);
    final List<String> textes = <String>[
      for (final Text w in tester.widgetList<Text>(find.byType(Text)))
        if (w.data != null) w.data!,
    ];
    expect(
      textes.where(
        (String x) => RegExp(
          r'prix|tarif|payant|gratuit|acheter|\bécole\b|\bsupports?\b',
          caseSensitive: false,
        ).hasMatch(x),
      ),
      isEmpty,
    );
  });

  testWidgets('« Plus de reglages » est replie, et s\'ouvre', (tester) async {
    await _monter(tester);
    await _deposer(tester);
    expect(_cle('import-plus-aide'), findsOneWidget);
    expect(_cle('classement-tranches'), findsNothing);
    expect(_cle('import-source'), findsNothing);
    await _toucher(tester, _cle('import-plus-bascule'));
    expect(_cle('classement-tranches'), findsOneWidget);
    expect(_cle('import-source'), findsOneWidget);
    expect(_cle('import-langue'), findsOneWidget);
    expect(_cle('import-choisir-preuve'), findsOneWidget);
    verifierUnSeulBoutonPlein(tester);
  });

  testWidgets('la preuve d\'autorisation : un depot distinct, en reglage', (
    tester,
  ) async {
    final BibliothequeAdminDemo port = BibliothequeAdminDemo(nombre: 0);
    final _Selecteur sel = _Selecteur(_pdf());
    await _monter(tester, port: port, selecteur: sel);
    await _deposer(tester);
    await _toucher(tester, _cle('import-plus-bascule'));
    sel.fichier = FichierChoisi(
      nom: 'autorisation.pdf',
      octets: _octets(_sigPdf),
      mime: 'application/pdf',
    );
    await _toucher(tester, _cle('import-choisir-preuve'));
    await stabiliser(tester, fois: 40);
    expect(_cle('import-etat-preuve'), findsOneWidget);
    expect(sel.demandes, <TypeRessource>[TypeRessource.pdf]);
    final String id = (await port.lister()).elements.single.id;
    expect((await port.fiche(id)).droits.preuveFournie, isTrue);
  });

  group('un lien a la place', () {
    testWidgets('adresse https exigee, puis le bouton', (tester) async {
      final BibliothequeAdminDemo port = BibliothequeAdminDemo(nombre: 0);
      await _monter(tester, port: port);
      await _toucher(tester, _cle('import-lien-a-la-place'));
      expect(_cle('import-lien'), findsOneWidget);
      expect(_cle('import-choisir-support'), findsNothing);
      // Un lien ne se telecharge pas : l'acces n'est pas demande.
      expect(_cle('import-acces'), findsNothing);
      expect(find.text(s.aideLien), findsOneWidget);
      await tester.enterText(_cle('import-nom'), 'Un site de reference');
      await tester.enterText(_cle('import-lien'), 'http://exemple.org/a');
      await stabiliser(tester, fois: 2);
      expect(find.text(i.lienInvalide), findsOneWidget);
      expect(_cle('import-poursuivre'), findsNothing);
      await tester.enterText(_cle('import-lien'), 'https://exemple.org/a');
      await stabiliser(tester, fois: 2);
      // Un lien externe demande sa description.
      expect(find.text(s.descriptionLien), findsOneWidget);
      expect(_cle('import-poursuivre'), findsNothing);
      await tester.enterText(_cle('import-description'), 'Un site utile.');
      await stabiliser(tester, fois: 2);
      await _toucher(tester, _cle('import-poursuivre'));
      await stabiliser(tester, fois: 6);
      final SupportAdmin cree = (await port.lister()).elements.single;
      expect(cree.type, TypeRessource.lienExterne);
    });

    testWidgets('une adresse de video connue : une video, sans description', (
      tester,
    ) async {
      final BibliothequeAdminDemo port = BibliothequeAdminDemo(nombre: 0);
      await _monter(tester, port: port);
      await _toucher(tester, _cle('import-lien-a-la-place'));
      await tester.enterText(_cle('import-nom'), 'Une recitation');
      await tester.enterText(
        _cle('import-lien'),
        'https://www.youtube.com/watch?v=abc',
      );
      await stabiliser(tester, fois: 2);
      await _toucher(tester, _cle('import-poursuivre'));
      await stabiliser(tester, fois: 6);
      expect((await port.lister()).elements.single.type, TypeRessource.video);
    });

    testWidgets('une adresse IP n\'est pas un lien accepte', (tester) async {
      await _monter(tester);
      await _toucher(tester, _cle('import-lien-a-la-place'));
      await tester.enterText(_cle('import-lien'), 'https://10.0.0.1/v');
      await stabiliser(tester, fois: 2);
      expect(find.text(i.lienInvalide), findsOneWidget);
    });

    testWidgets('on revient au fichier', (tester) async {
      await _monter(tester);
      await _toucher(tester, _cle('import-lien-a-la-place'));
      await _toucher(tester, _cle('import-fichier-a-la-place'));
      expect(_cle('import-choisir-support'), findsOneWidget);
      expect(_cle('import-lien'), findsNothing);
    });
  });

  testWidgets('depot de fichiers non active : le dit, le lien reste', (
    tester,
  ) async {
    await _monter(
      tester,
      port: BibliothequeAdminDemo(nombre: 0)..depotActifServeur = false,
    );
    expect(_cle('import-depot-inactif'), findsOneWidget);
    expect(_cle('import-choisir-support'), findsNothing);
    expect(_cle('import-lien-a-la-place'), findsOneWidget);
  });

  testWidgets('sans reponse sur le depot : aucun bouton de fichier', (
    tester,
  ) async {
    await _monter(
      tester,
      port: BibliothequeAdminDemo(nombre: 0)..panneDepot = true,
    );
    expect(_cle('import-depot-inconnu'), findsOneWidget);
    expect(_cle('import-choisir-support'), findsNothing);
    expect(_cle('import-lien-a-la-place'), findsOneWidget);
  });

  testWidgets('reprise d\'un brouillon : son nom est la, pas ressaisi', (
    tester,
  ) async {
    await _monter(
      tester,
      route: Routes.adminPedagogieSupportFichier('demo-support-001'),
    );
    expect(find.text('Introduction au Tajwid 1'), findsOneWidget);
    expect(_cle('import-document'), findsOneWidget);
  });

  testWidgets('sans capacite d\'import : rien', (tester) async {
    await _monter(
      tester,
      port: BibliothequeAdminDemo(
        droitsServeur: const CapacitesBibliotheque(peutLire: true),
      ),
    );
    expect(_cle('import-non-autorise'), findsOneWidget);
    expect(_cle('import-contenu'), findsNothing);
  });

  group('gabarits', () {
    setUpAll(chargerPolicesDuDepot);
    for (final TextDirection d in TextDirection.values) {
      testWidgets('320 px, texte x2, ${d.name} : fichier depose', (
        tester,
      ) async {
        await _monter(
          tester,
          taille: const Size(320, 640),
          echelle: 2,
          direction: d,
          selecteur: _Selecteur(_pdf('متن الأخضري-1.pdf')),
        );
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester);
        await _deposer(tester);
        await _toucher(tester, _cle('import-plus-bascule'));
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester);
        verifierUnSeulBoutonPlein(tester);
      });
    }
  });
}
