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
import 'package:rewayah_academy/core/tc_bibliotheque/catalogue_local.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/donnees_catalogue.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/theme/app_typography.dart';
import 'package:rewayah_academy/core/widgets/bandeau_attention.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart' show TonEtat;
import 'package:rewayah_academy/features/admin_pedagogie_bibliotheque/import/import_page.dart';
import 'package:rewayah_academy/features/admin_pedagogie_bibliotheque/import/selecteur_support.dart';
import 'package:rewayah_academy/features/admin_pedagogie_bibliotheque/libelles_bibliotheque.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/demo/bibliotheque_admin_demo.dart';
import '../../support/garde_interface.dart';
import '../../support/monter_admin_demo.dart';

class _Selecteur implements SelecteurFichierSupport {
  _Selecteur(this.fichier, {this.image});

  FichierChoisi? fichier;

  /// Ce que rend le choix d'une image (la vignette) ; par defaut un PNG.
  FichierChoisi? image;
  final List<TypeRessource> demandes = <TypeRessource>[];
  int documents = 0;

  @override
  Future<FichierChoisi?> choisir(TypeRessource type) async {
    demandes.add(type);
    if (type == TypeRessource.image) {
      return image ?? _fichier('couverture.png', _sigPng, taille: 4096);
    }
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

BandeauAttention _bandeau(WidgetTester tester, String cle) =>
    tester.widget<BandeauAttention>(_cle(cle));

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
    // Rien d'autre : ni nom, ni type, ni langue, ni categorie, ni droits a
    // remplir avant d'avoir choisi le fichier.
    expect(_cle('import-document'), findsNothing);
    expect(_cle('import-plus'), findsNothing);
    expect(find.text(i.champs.type), findsNothing);
    expect(find.text(i.champs.langue), findsNothing);
    expect(find.text(i.champs.categorie), findsNothing);
    // Un bouton qui ne peut pas aboutir n'est pas rendu : la phrase dit ce
    // qui manque.
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
    // Etat « en cours » : la barre, le pourcentage, le type et la taille.
    expect(_cle('import-progression-support'), findsOneWidget);
    expect(find.textContaining('%'), findsWidgets);
    expect(
      tester.widget<Text>(_cle('import-reconnu')).data,
      contains(t.admin.bibliotheque.libelles.type.pdf),
    );
    expect(_cle('import-poursuivre'), findsNothing);
    expect(find.text(s.aideEnvoi), findsOneWidget);
    await stabiliser(tester, fois: 40);
    // Etat « reussi » : coche et ton de succes, « Fichier ajoute », le type et
    // la taille. Jamais « Fichier verifie », jamais « Passez aux droits ».
    final BandeauAttention reussi = _bandeau(tester, 'import-reussi-support');
    expect(reussi.ton, TonEtat.succes);
    expect(reussi.titre, s.fichierAjoute);
    expect(reussi.message, contains(t.admin.bibliotheque.libelles.type.pdf));
    expect(reussi.message, contains('Ko'));
    expect(find.textContaining('vérifié'), findsNothing);
    expect(find.textContaining('droits'), findsNothing);
    // Le nom : sans extension, sans le « -1 » d'une copie.
    final Finder champ = find.descendant(
      of: _cle('import-nom'),
      matching: find.byType(EditableText),
    );
    final EditableText nom = tester.widget<EditableText>(
      champ.evaluate().isEmpty
          ? find.byWidgetPredicate(
              (Widget w) =>
                  w is EditableText && w.controller.text == 'متن الأخضري',
            )
          : champ,
    );
    expect(nom.controller.text, 'متن الأخضري');
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

  testWidgets('un fichier et un nom suffisent : enregistre ET visible', (
    tester,
  ) async {
    final BibliothequeAdminDemo port = BibliothequeAdminDemo(nombre: 0);
    await _monter(tester, port: port);
    await _deposer(tester);
    // Le bouton dit ce qu'il fait.
    expect(find.text(s.enregistrer), findsOneWidget);
    await _toucher(tester, _cle('import-poursuivre'));
    await stabiliser(tester, fois: 6);
    // L'ecran le dit, avec un lien pour ouvrir le document.
    final BandeauAttention fait = _bandeau(tester, 'import-enregistre');
    expect(fait.ton, TonEtat.succes);
    expect(fait.titre, s.enregistreTitre);
    expect(fait.message, s.enregistreTous);
    expect(_cle('import-ouvrir'), findsOneWidget);
    expect(_cle('import-autre'), findsOneWidget);
    // Et c'est vrai : publie, ouvert aux inscrits, droits par defaut.
    final String id = (await port.lister()).elements.single.id;
    final FicheSupport fiche = await port.fiche(id);
    expect(fiche.support.statutVersion, StatutVersionRessource.publiee);
    expect(fiche.support.visibilite, PolitiqueAcces.inscrits);
    expect(fiche.droits.usages, <UsageDroit>{
      UsageDroit.application,
      UsageDroit.classe,
    });
    expect(fiche.rayon, codeRayonCours);
    expect(fiche.support.titre, 'cours-tajwid');
    expect(port.depotsDirects, <(String, AccesDocument, bool)>[
      (id, AccesDocument.lecture, false),
    ]);
    // Aucune vignette n'a ete demandee : la creation sans vignette aboutit.
    expect(fiche.aVignette, isFalse);
    // Le lien ouvre la fiche du document.
    await _toucher(tester, _cle('import-ouvrir'));
    await stabiliser(tester, fois: 6);
    expect(_cle('import-reussite'), findsNothing);
  });

  testWidgets('« Ajouter un autre document » repart d\'un formulaire vide', (
    tester,
  ) async {
    final BibliothequeAdminDemo port = BibliothequeAdminDemo(nombre: 0);
    await _monter(tester, port: port);
    await _deposer(tester);
    await _toucher(tester, _cle('import-poursuivre'));
    await stabiliser(tester, fois: 6);
    await _toucher(tester, _cle('import-autre'));
    expect(_cle('import-intro'), findsOneWidget);
    expect(_cle('import-document'), findsNothing);
    await _deposer(tester);
    expect((await port.lister()).elements, hasLength(2));
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
      _bandeau(tester, 'import-reussi-support').message,
      contains(t.admin.bibliotheque.libelles.type.audio),
    );
    expect((await port.lister()).elements.single.type, TypeRessource.audio);
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

  test('la taille se lit en octets, Ko ou Mo', () {
    expect(tailleLisible(512), contains('512'));
    expect(tailleLisible(2048), contains('2'));
    expect(tailleLisible(2048), contains('Ko'));
    expect(tailleLisible(1536 * 1024), contains('1,5'));
    expect(tailleLisible(1536 * 1024), contains('Mo'));
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
      final BandeauAttention b = _bandeau(tester, 'import-refus');
      expect(b.ton, TonEtat.alerte);
      expect(b.titre, s.fichierEchec);
      expect(b.message, phrase);
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
        LibellesGroupe.insecable(s.refus.tropLourd(limite: '10')),
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
      // Plus aucun mot de machine dans une phrase.
      for (final String phrase in phrases.values) {
        expect(
          RegExp(
            r'empreinte|intention|HMAC|CORS|hash',
            caseSensitive: false,
          ).hasMatch(phrase),
          isFalse,
          reason: phrase,
        );
      }
    });

    test('une exception de la demande garde sa cause et son reglage', () {
      const DepotImpossible e = DepotImpossible(
        ErreurUpload.stockage,
        reglage: 'R2_BUCKET_SUPPORTS',
      );
      expect(causeDeLaDemande(e), ErreurUpload.stockage);
      expect(reglageDeLaDemande(e), 'R2_BUCKET_SUPPORTS');
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
      // Le reglage se dit a la suite de la phrase, par son nom.
      expect(
        phraseEchecDepot(ErreurUpload.stockage, 'R2_BUCKET_SUPPORTS'),
        '${i.erreurs.stockage} ${s.reglageNomme(nom: 'R2_BUCKET_SUPPORTS')}',
      );
    });

    for (final ErreurUpload cause in ErreurUpload.values) {
      testWidgets('la demande de depot echoue (${cause.name})', (tester) async {
        final BibliothequeAdminDemo port = BibliothequeAdminDemo(nombre: 0)
          ..echecDemande = cause;
        await _monter(tester, port: port);
        await _deposer(tester);
        // Etat « echoue » : alerte, ton d'alerte, la phrase vraie, Reessayer.
        final BandeauAttention b = _bandeau(tester, 'import-echec-support');
        expect(b.ton, TonEtat.alerte);
        expect(b.titre, s.fichierEchec);
        // Deux lignes au plus : la phrase courte. Le detail est replie.
        expect(b.message, phraseCourteDepot(cause));
        if (cause != ErreurUpload.reseau) {
          expect(b.message, isNot(s.court.reseau));
        }
        expect(_cle('import-detail-texte-support'), findsNothing);
        if (phraseErreurDepot(cause) != phraseCourteDepot(cause)) {
          await _toucher(tester, _cle('import-detail-support'));
          expect(find.text(phraseErreurDepot(cause)), findsOneWidget);
        } else {
          expect(_cle('import-detail-support'), findsNothing);
        }
        expect(_cle('import-reessayer-support'), findsOneWidget);
        expect(_cle('import-poursuivre'), findsNothing);
      });
    }

    testWidgets('un reglage du serveur manque : son nom est dit', (
      tester,
    ) async {
      final BibliothequeAdminDemo port = BibliothequeAdminDemo(nombre: 0)
        ..echecDemande = ErreurUpload.stockage
        ..reglageEchec = 'R2_BUCKET_SUPPORTS';
      await _monter(tester, port: port);
      await _deposer(tester);
      // Le nom du reglage n'encombre pas l'alerte : il est sous « Detail ».
      expect(
        _bandeau(tester, 'import-echec-support').message,
        isNot(contains('R2_BUCKET_SUPPORTS')),
      );
      await _toucher(tester, _cle('import-detail-support'));
      expect(find.textContaining('R2_BUCKET_SUPPORTS'), findsOneWidget);
      // Et il se replie.
      await _toucher(tester, _cle('import-detail-support'));
      expect(find.textContaining('R2_BUCKET_SUPPORTS'), findsNothing);
    });

    testWidgets('echec pendant l\'envoi, puis « Reessayer » aboutit', (
      tester,
    ) async {
      final BibliothequeAdminDemo port = BibliothequeAdminDemo(nombre: 0)
        ..echecDepot = ErreurUpload.envoi;
      final _Selecteur sel = _Selecteur(_pdf());
      await _monter(tester, port: port, selecteur: sel);
      await _deposer(tester);
      expect(_bandeau(tester, 'import-echec-support').message, s.court.envoi);
      // Reessayer renvoie le meme fichier, sans le rechoisir, dans le meme
      // brouillon.
      await _toucher(tester, _cle('import-reessayer-support'));
      await stabiliser(tester, fois: 40);
      expect(_cle('import-reussi-support'), findsOneWidget);
      expect(sel.documents, 1);
      expect((await port.lister()).elements, hasLength(1));
    });
  });

  group('les reglages de production', () {
    testWidgets(
      'un reglage manque : nomme d\'emblee, aucun bouton de fichier',
      (tester) async {
        await _monter(
          tester,
          port: BibliothequeAdminDemo(nombre: 0)
            ..reglagesManquantsServeur = <String>[
              'R2_BUCKET_SUPPORTS',
              'LIBRARY_UPLOAD_CONFIRMATION_HMAC_KEY',
            ],
        );
        final BandeauAttention b = _bandeau(tester, 'import-reglages');
        expect(b.titre, s.reglagesTitre);
        expect(b.message, contains('R2_BUCKET_SUPPORTS'));
        expect(b.message, contains('LIBRARY_UPLOAD_CONFIRMATION_HMAC_KEY'));
        // Aucun bouton qui echouerait ; le lien reste possible.
        expect(_cle('import-choisir-support'), findsNothing);
        expect(_cle('import-lien-a-la-place'), findsOneWidget);
      },
    );

    testWidgets('la fonction ne sait pas encore dire ses reglages : la base '
        'dit au moins si son secret est pose', (tester) async {
      await _monter(
        tester,
        port: BibliothequeAdminDemo(nombre: 0)..reglagesInconnus = true,
      );
      expect(_cle('import-reglages'), findsNothing);
      expect(_cle('import-choisir-support'), findsOneWidget);
    });

    testWidgets('sans aucune reponse : aucun bouton de fichier', (
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

  testWidgets('nom corrige, description, telechargement permis', (
    tester,
  ) async {
    final BibliothequeAdminDemo port = BibliothequeAdminDemo(nombre: 0);
    await _monter(tester, port: port);
    await _deposer(tester);
    await tester.enterText(_cle('import-nom'), 'Cours de tajwid');
    await tester.enterText(_cle('import-description'), 'Les bases.');
    await _toucher(tester, find.text(s.acces.telechargement));
    await _toucher(tester, _cle('import-poursuivre'));
    await stabiliser(tester, fois: 6);
    final String id = (await port.lister()).elements.single.id;
    final FicheSupport fiche = await port.fiche(id);
    expect(fiche.support.titre, 'Cours de tajwid');
    expect(fiche.description, 'Les bases.');
    expect(fiche.droits.usages, contains(UsageDroit.telechargement));
    expect(port.depotsDirects.single.$2, AccesDocument.telechargement);
  });

  testWidgets('sans nom : la phrase le dit, pas de bouton', (tester) async {
    await _monter(tester);
    await _deposer(tester);
    await tester.enterText(_cle('import-nom'), '  ');
    await stabiliser(tester, fois: 2);
    expect(_cle('import-poursuivre'), findsNothing);
    expect(find.text(s.aideNom), findsOneWidget);
  });

  group('le rayon', () {
    testWidgets('les rayons du serveur, aucun mot d\'argent ni « support »', (
      tester,
    ) async {
      await _monter(tester);
      await _deposer(tester);
      expect(find.text(s.rangement.titre), findsOneWidget);
      expect(find.text('Documents des cours'), findsOneWidget);
      expect(find.text('Pour aller plus loin'), findsOneWidget);
      // Dans le rayon des cours, aucune declaration n'est demandee.
      expect(_cle('import-droit-tiers'), findsNothing);
      final List<String> textes = <String>[
        for (final Text w in tester.widgetList<Text>(find.byType(Text)))
          if (w.data != null) w.data!,
      ];
      expect(
        textes.where(
          (String x) => RegExp(
            r'prix|tarif|payant|gratuit|acheter|\bécole\b|\bsupports?\b|\bdroits\b',
            caseSensitive: false,
          ).hasMatch(x),
        ),
        isEmpty,
      );
    });

    testWidgets('un document d\'un tiers : une seule case, obligatoire', (
      tester,
    ) async {
      final BibliothequeAdminDemo port = BibliothequeAdminDemo(nombre: 0);
      await _monter(tester, port: port);
      await _deposer(tester);
      await _toucher(tester, find.text('Pour aller plus loin'));
      // Sans la declaration : pas de bouton, la phrase dit pourquoi.
      expect(_cle('import-droit-tiers'), findsOneWidget);
      expect(_cle('import-poursuivre'), findsNothing);
      expect(find.text(s.aideDroit), findsOneWidget);
      await _toucher(tester, _cle('import-droit-tiers'));
      await _toucher(tester, _cle('import-poursuivre'));
      await stabiliser(tester, fois: 6);
      expect(_cle('import-enregistre'), findsOneWidget);
      final String id = (await port.lister()).elements.single.id;
      final FicheSupport fiche = await port.fiche(id);
      expect(fiche.rayon, codeRayonPlusLoin);
      expect(fiche.support.statutVersion, StatutVersionRessource.publiee);
      expect(port.depotsDirects.single, (id, AccesDocument.lecture, true));
    });
  });

  group('la vignette : facultative, visible, modifiable, jamais bloquante', () {
    testWidgets('elle n\'est proposee qu\'une fois le fichier choisi', (
      tester,
    ) async {
      await _monter(tester);
      expect(_cle('import-vignette'), findsNothing);
      await _deposer(tester);
      expect(_cle('import-vignette'), findsOneWidget);
      expect(find.text(s.vignette.titre), findsOneWidget);
      // Sans elle, le bouton est deja la.
      expect(_cle('import-poursuivre'), findsOneWidget);
    });

    testWidgets('avec vignette : « Vignette ajoutee », sa miniature', (
      tester,
    ) async {
      final BibliothequeAdminDemo port = BibliothequeAdminDemo(nombre: 0);
      final _Selecteur sel = _Selecteur(_pdf());
      await _monter(tester, port: port, selecteur: sel);
      await _deposer(tester);
      await _toucher(tester, _cle('import-choisir-vignette'));
      await stabiliser(tester, fois: 40);
      // La vignette demande une image, jamais le type du document.
      expect(sel.demandes, <TypeRessource>[TypeRessource.image]);
      final BandeauAttention b = _bandeau(tester, 'import-reussi-vignette');
      expect(b.ton, TonEtat.succes);
      expect(b.titre, s.vignette.ajoutee);
      expect(_cle('import-vignette-miniature'), findsOneWidget);
      final String id = (await port.lister()).elements.single.id;
      expect((await port.fiche(id)).aVignette, isTrue);
      // Elle se remplace et se retire.
      expect(
        find.text(t.admin.bibliotheque.fiche.remplacerVignette),
        findsOneWidget,
      );
      expect(_cle('import-retirer-vignette'), findsOneWidget);
      await _toucher(tester, _cle('import-poursuivre'));
      await stabiliser(tester, fois: 6);
      expect(_cle('import-enregistre'), findsOneWidget);
      expect((await port.fiche(id)).aVignette, isTrue);
    });

    testWidgets('remplacement, puis retrait', (tester) async {
      final BibliothequeAdminDemo port = BibliothequeAdminDemo(nombre: 0);
      final _Selecteur sel = _Selecteur(_pdf());
      await _monter(tester, port: port, selecteur: sel);
      await _deposer(tester);
      await _toucher(tester, _cle('import-choisir-vignette'));
      await stabiliser(tester, fois: 40);
      await _toucher(tester, _cle('import-choisir-vignette'));
      await stabiliser(tester, fois: 40);
      expect(sel.demandes, hasLength(2));
      expect(_cle('import-reussi-vignette'), findsOneWidget);
      final String id = (await port.lister()).elements.single.id;
      await _toucher(tester, _cle('import-retirer-vignette'));
      await stabiliser(tester, fois: 6);
      expect((await port.fiche(id)).aVignette, isFalse);
      expect(find.text(s.vignette.retiree), findsOneWidget);
      expect(_cle('import-vignette-miniature'), findsNothing);
      expect(_cle('import-retirer-vignette'), findsNothing);
    });

    testWidgets('echec de la vignette seule : le document s\'enregistre', (
      tester,
    ) async {
      final BibliothequeAdminDemo port = BibliothequeAdminDemo(nombre: 0);
      await _monter(tester, port: port);
      await _deposer(tester);
      port.echecDemande = ErreurUpload.stockage;
      await _toucher(tester, _cle('import-choisir-vignette'));
      await stabiliser(tester, fois: 40);
      final BandeauAttention b = _bandeau(tester, 'import-echec-vignette');
      expect(b.ton, TonEtat.alerte);
      expect(b.titre, s.vignette.echec);
      expect(b.message, contains(s.court.stockage));
      // La phrase dit que le document peut s'enregistrer sans elle.
      expect(b.message, contains(s.vignette.echecSuite));
      expect(_cle('import-reessayer-vignette'), findsOneWidget);
      // Le bouton reste, et l'enregistrement aboutit.
      await _toucher(tester, _cle('import-poursuivre'));
      await stabiliser(tester, fois: 6);
      expect(_cle('import-enregistre'), findsOneWidget);
      final String id = (await port.lister()).elements.single.id;
      final FicheSupport fiche = await port.fiche(id);
      expect(fiche.support.statutVersion, StatutVersionRessource.publiee);
      expect(fiche.aVignette, isFalse);
    });

    testWidgets('une image trop lourde ou qui n\'en est pas une', (
      tester,
    ) async {
      final _Selecteur sel = _Selecteur(
        _pdf(),
        image: _fichier('lourde.png', _sigPng, taille: 2 * 1024 * 1024 + 1),
      );
      await _monter(tester, selecteur: sel);
      await _deposer(tester);
      await _toucher(tester, _cle('import-choisir-vignette'));
      await stabiliser(tester, fois: 6);
      expect(
        _bandeau(tester, 'import-refus-vignette').message,
        contains(s.vignette.tropLourde),
      );
      sel.image = _fichier('faux.png', _sigPdf);
      await _toucher(tester, _cle('import-choisir-vignette'));
      await stabiliser(tester, fois: 6);
      expect(
        _bandeau(tester, 'import-refus-vignette').message,
        contains(s.vignette.pasUneImage),
      );
      expect(_cle('import-poursuivre'), findsOneWidget);
    });
  });

  testWidgets('« Plus de reglages » est replie, sans rien d\'obligatoire', (
    tester,
  ) async {
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
    // Aucun asterisque, et le bouton reste rendu sans rien saisir.
    expect(find.textContaining('*'), findsNothing);
    expect(_cle('import-poursuivre'), findsOneWidget);
    verifierUnSeulBoutonPlein(tester);
  });

  testWidgets('ce qui est precise dans « Plus de reglages » est garde', (
    tester,
  ) async {
    final BibliothequeAdminDemo port = BibliothequeAdminDemo(nombre: 0);
    final _Selecteur sel = _Selecteur(_pdf());
    await _monter(tester, port: port, selecteur: sel);
    await _deposer(tester);
    await _toucher(tester, _cle('import-plus-bascule'));
    await tester.enterText(_cle('import-titulaire'), 'Un editeur');
    sel.fichier = FichierChoisi(
      nom: 'autorisation.pdf',
      octets: _octets(_sigPdf),
      mime: 'application/pdf',
    );
    await _toucher(tester, _cle('import-choisir-preuve'));
    await stabiliser(tester, fois: 40);
    expect(_cle('import-reussi-preuve'), findsOneWidget);
    expect(sel.demandes, <TypeRessource>[TypeRessource.pdf]);
    await _toucher(tester, _cle('import-poursuivre'));
    await stabiliser(tester, fois: 6);
    final String id = (await port.lister()).elements.single.id;
    final FicheSupport fiche = await port.fiche(id);
    expect(fiche.droits.titulaire, 'Un editeur');
    expect(fiche.droits.preuveFournie, isTrue);
    expect(fiche.support.statutVersion, StatutVersionRessource.publiee);
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
      expect(find.text(s.descriptionLien), findsWidgets);
      expect(_cle('import-poursuivre'), findsNothing);
      await tester.enterText(_cle('import-description'), 'Un site utile.');
      await stabiliser(tester, fois: 2);
      await _toucher(tester, _cle('import-poursuivre'));
      await stabiliser(tester, fois: 6);
      expect(_cle('import-enregistre'), findsOneWidget);
      final SupportAdmin cree = (await port.lister()).elements.single;
      expect(cree.type, TypeRessource.lienExterne);
      expect(cree.statutVersion, StatutVersionRessource.publiee);
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

  testWidgets('le serveur garde le document en brouillon : l\'ecran le dit', (
    tester,
  ) async {
    final BibliothequeAdminDemo port = BibliothequeAdminDemo(nombre: 0);
    await _monter(tester, port: port);
    await _deposer(tester);
    port.panneEcriture = true;
    await _toucher(tester, _cle('import-poursuivre'));
    await stabiliser(tester, fois: 6);
    // Rien n'est annonce a tort : pas de « Document enregistre ».
    expect(_cle('import-enregistre'), findsNothing);
    final BandeauAttention b = _bandeau(tester, 'import-erreur');
    expect(b.ton, TonEtat.alerte);
    expect(b.message, s.enregistrementEchec);
    // Le fichier reste ajoute : on peut reessayer.
    port.panneEcriture = false;
    await _toucher(tester, _cle('import-poursuivre'));
    await stabiliser(tester, fois: 6);
    expect(_cle('import-enregistre'), findsOneWidget);
  });

  group('pour qui (B1)', () {
    testWidgets('par defaut : tous les inscrits, et l\'ecran le dit', (
      tester,
    ) async {
      final BibliothequeAdminDemo port = BibliothequeAdminDemo(nombre: 0);
      await _monter(tester, port: port);
      await _deposer(tester);
      expect(find.text(s.pourQui.tous), findsOneWidget);
      expect(find.text(s.pourQui.adultes), findsOneWidget);
      await _toucher(tester, _cle('import-poursuivre'));
      await stabiliser(tester, fois: 6);
      expect(port.publicsRecus.single, PublicDocument.tous);
      expect(_bandeau(tester, 'import-enregistre').message, s.enregistreTous);
    });

    testWidgets('adultes seulement : le serveur le recoit, l\'ecran le dit', (
      tester,
    ) async {
      final BibliothequeAdminDemo port = BibliothequeAdminDemo(nombre: 0);
      await _monter(tester, port: port);
      await _deposer(tester);
      await _toucher(tester, find.text(s.pourQui.adultes));
      await _toucher(tester, _cle('import-poursuivre'));
      await stabiliser(tester, fois: 6);
      expect(port.publicsRecus.single, PublicDocument.adultes);
      expect(
        _bandeau(tester, 'import-enregistre').message,
        s.enregistreAdultes,
      );
    });
  });

  testWidgets('blocage du serveur : rien n\'est ecrit, la cause est nommee', (
    tester,
  ) async {
    final BibliothequeAdminDemo port = BibliothequeAdminDemo(nombre: 0)
      ..depotDirectBloque = <CleCritere>[CleCritere.source];
    await _monter(tester, port: port);
    await _deposer(tester);
    await _toucher(tester, _cle('import-poursuivre'));
    await stabiliser(tester, fois: 6);
    expect(_cle('import-enregistre'), findsNothing);
    final BandeauAttention b = _bandeau(tester, 'import-erreur');
    expect(b.ton, TonEtat.alerte);
    expect(b.message, s.bloque(criteres: libelleCritere(CleCritere.source)));
    // Tout ou rien : le document n'est pas publie.
    final String id = (await port.lister()).elements.single.id;
    expect(
      (await port.fiche(id)).support.statutVersion,
      isNot(StatutVersionRessource.publiee),
    );
  });

  testWidgets('le serveur n\'a pas encore la fonction (I5) : nomme, sans '
      'bouton pour reessayer', (tester) async {
    final BibliothequeAdminDemo port = BibliothequeAdminDemo(nombre: 0)
      ..depotDirectAbsent = true;
    await _monter(tester, port: port);
    await _deposer(tester);
    await _toucher(tester, _cle('import-poursuivre'));
    await stabiliser(tester, fois: 6);
    final BandeauAttention b = _bandeau(tester, 'import-inactif');
    expect(b.titre, s.inactifTitre);
    expect(b.message, contains(DepotDirectAbsent.reglage));
    expect(_cle('import-poursuivre'), findsNothing);
    expect(_cle('import-enregistre'), findsNothing);
    expect(find.text(t.commun.reessayer), findsNothing);
  });

  testWidgets('le nom affiche est celui que l\'on saisit, pas le nom brut', (
    tester,
  ) async {
    await _monter(tester, selecteur: _Selecteur(_pdf('scan_0042-final.pdf')));
    await _deposer(tester);
    expect(find.text('scan_0042-final.pdf'), findsNothing);
    await tester.enterText(_cle('import-nom'), 'متن الأخضري');
    await tester.pump();
    final Text nom = tester.widget<Text>(_cle('import-nom-support'));
    expect(nom.data, 'متن الأخضري');
    // Contenu arabe : la police du contenu, et son sens isole.
    expect(nom.style?.fontFamily, AppTypography.arabeContenu().fontFamily);
    expect(nom.textDirection, TextDirection.rtl);
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
      testWidgets('320 px, texte x2, ${d.name} : fichier, vignette, reglages', (
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
        await _toucher(tester, _cle('import-choisir-vignette'));
        await stabiliser(tester, fois: 40);
        await _toucher(tester, _cle('import-plus-bascule'));
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester);
        verifierUnSeulBoutonPlein(tester);
      });
    }
  });
}
