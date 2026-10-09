// COM-RC tour 7, passe finale (M) des Messages :
//
// - l'enseignante de la Classe An-Nour porte dans les Messages le meme nom
//   que sur la page de la Classe et dans l'annonce (« Sayyida Mariam ») ;
// - les donnees de demonstration des Messages suivent la langue de
//   l'interface : en arabe, aucun texte francais (constat sur
//   com_messages_liste_tuteur_390_rtl_clair : « .semaine prochaine ») ;
// - la ligne compacte du fil garde ce nom plus long entier a 320 en
//   texte x2, sans depasser le sixieme de l'ecran (borne du lot F) ;
// - passe de controle visuel : Studio et Communaute suivent aussi la
//   langue, deux initiales arabes ne forment plus un mot (« سم »), et les
//   guillemets arabes se lisent tournes vers l'exterieur.
//
// Contre-preuve : a 3901f0e6, les fixtures nommaient « Mme Mariam » et
// ecrivaient leurs textes en francais en dur, quelle que soit la langue.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/avatar_tile.dart';
import 'package:rewayah_academy/features/com_communaute/port_communaute.dart';
import 'package:rewayah_academy/features/com_messages/entete_fil_contexte.dart';
import 'package:rewayah_academy/features/com_messages/liste_fils.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:rewayah_academy/features/com_studio/port_activite_studio.dart';
import 'package:rewayah_academy/features/com_studio/port_studio.dart';
import 'package:rewayah_academy/features/demo/communications/com_annonces_demo.dart';
import 'package:rewayah_academy/features/demo/communications/com_communaute_demo.dart';
import 'package:rewayah_academy/features/demo/communications/com_messages_demo.dart';
import 'package:rewayah_academy/features/demo/communications/com_studio_demo.dart';
import 'package:rewayah_academy/features/demo/communications/demo_communications_page.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;

final DateTime _maintenant = DateTime.utc(2026, 10, 4, 12);

/// Une lettre latine : un mot francais laisse dans l'arabe.
final RegExp _latin = RegExp('[A-Za-zÀ-ÿ]');

/// Tous les textes visibles des fixtures de [role] (noms, fonctions,
/// objets, messages, pieces jointes, conversations a ouvrir).
List<String> _textesVisibles(RoleDemoCommunications role) {
  final List<FilMetier> fils = fixturesMessagesDemo(role, _maintenant);
  final List<String> textes = <String>[];
  void participant(Participant p) {
    textes.add(p.nomAffiche);
    if (p.fonction != null) textes.add(p.fonction!);
  }

  for (final FilMetier f in fils) {
    f.participants.forEach(participant);
    for (final ElementContexteFil e in f.contexte) {
      textes.add(e.objet.libelle);
    }
    for (final MessageCommunication m in f.messages) {
      if (m.texte.isNotEmpty) textes.add(m.texte);
      for (final PieceJointe p in m.piecesJointes) {
        // Le nom et le type sont ecrits dans le panneau des fichiers
        // partages (1440) ; l'extension (.pdf, .m4a) et le sigle PDF ne
        // sont pas des mots.
        textes.add(p.nom.replaceAll(RegExp(r'\.[a-z0-9]+$'), ''));
        if (p.typeLisible != 'PDF') textes.add(p.typeLisible);
      }
    }
  }
  for (final List<ConversationPossible> liste in conversationsAOuvrirDemo(
    role,
  ).values) {
    for (final ConversationPossible c in liste) {
      participant(c.interlocuteur);
      textes.add(c.objet.libelle);
    }
  }
  return textes;
}

/// Un texte sans ses adresses (https://...), son code promotionnel
/// (PROF20), l'extension d'un fichier et le sigle PDF : ce qui reste doit
/// etre ecrit dans la langue de l'interface.
String _sansTechnique(String s) => s
    .replaceAll(RegExp(r'https?://\S+'), '')
    .replaceAll('PROF20', '')
    .replaceAll(RegExp(r'\.(pdf|m4a)\b'), '')
    .replaceAll('PDF', '');

/// Les textes visibles de la demonstration du Studio (canaux, membres,
/// messages, partages, activite d'Aujourd'hui, brouillon).
List<String> _textesStudio() {
  final List<String> textes = <String>[texteBrouillonDemo];
  void personne(Participant p) {
    textes.add(p.nomAffiche);
    if (p.fonction != null) textes.add(p.fonction!);
  }

  for (final (Canal c, PartagesCanal p) in fixturesStudioDemo(_maintenant)) {
    textes
      ..add(c.resume.nom)
      ..add(c.resume.description ?? '');
    c.membres.forEach(personne);
    for (final MessageCommunication m in c.messages) {
      textes.add(m.texte);
      personne(m.auteur);
      for (final PieceJointe pj in m.piecesJointes) {
        textes
          ..add(pj.nom)
          ..add(pj.typeLisible);
      }
    }
    for (final ElementPartage e in <ElementPartage>[
      ...p.epingles,
      ...p.fichiers,
      ...p.liens,
    ]) {
      textes
        ..add(e.titre)
        ..add(e.detail ?? '');
    }
  }
  for (final ActiviteStudio a in fixturesActiviteStudioDemo(_maintenant)) {
    textes
      ..add(a.libelle)
      ..add(a.objet.libelle);
    if (a.auteur != null) personne(a.auteur!);
  }
  return textes;
}

/// Les textes visibles de la demonstration de la Communaute.
List<String> _textesCommunaute() {
  final List<String> textes = <String>[
    for (final CategorieCommunaute c in DonneesCommunauteDemo.categories)
      c.libelle,
    DonneesCommunauteDemo.soi.nomAffiche,
    DonneesCommunauteDemo.soi.fonction!,
    DonneesCommunauteDemo.fichier.nom,
    DonneesCommunauteDemo.reponseAffilie,
    for (final BrouillonMarqueDemo b
        in DonneesCommunauteDemo.brouillonsMarques) ...<String>[
      b.titre,
      b.texte,
    ],
  ];
  for (final PublicationCommunaute p in DonneesCommunauteDemo.publications()) {
    textes.addAll(<String>[
      p.titre,
      p.texte,
      p.auteur.nomAffiche,
      p.auteur.fonction!,
      p.categorie.libelle,
      for (final PieceJointe pj in p.piecesJointes) pj.nom,
    ]);
  }
  for (final List<ReponseCommunaute> liste
      in DonneesCommunauteDemo.reponses().values) {
    for (final ReponseCommunaute r in liste) {
      textes.addAll(<String>[r.texte, r.auteur.nomAffiche]);
    }
  }
  return textes;
}

Participant _enseignanteNour() {
  for (final FilMetier f in fixturesMessagesDemo(
    RoleDemoCommunications.tuteur,
    _maintenant,
  )) {
    for (final Participant p in f.participants) {
      if (p.id == 'p-mariam') return p;
    }
  }
  throw StateError('enseignante absente');
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('Le nom de l enseignante An-Nour', () {
    test('fr : « Sayyida Mariam », celui de la Classe et de l annonce', () {
      LocaleSettings.setLocaleSync(AppLocale.fr);
      final Participant p = _enseignanteNour();
      expect(p.nomAffiche, 'Sayyida Mariam');
      expect(p.nomAffiche, ClassesDemoAnnonces.enseignanteNourNommee);
      for (final RoleDemoCommunications r in RoleDemoCommunications.values) {
        expect(
          _textesVisibles(r).where((String s) => s.contains('Mme ')),
          isEmpty,
          reason: '${r.name} : plus de « Mme Mariam »',
        );
      }
      expect(t.com.vocal.demo.auteurEnseignante, startsWith('Sayyida Mariam'));
    });

    test('ar : « سيدة مريم », comme la page de la Classe', () async {
      await LocaleSettings.setLocale(AppLocale.ar);
      final Participant p = _enseignanteNour();
      expect(p.nomAffiche, 'سيدة مريم');
      expect(p.nomAffiche, ClassesDemoAnnonces.enseignanteNourNommee);
      expect(t.com.vocal.demo.auteurEnseignante, startsWith('سيدة مريم'));
    });
  });

  group('Les donnees de demonstration suivent la langue', () {
    test('fr : les textes francais d origine', () {
      LocaleSettings.setLocaleSync(AppLocale.fr);
      final List<String> textes = _textesVisibles(
        RoleDemoCommunications.tuteur,
      );
      expect(textes, contains('Voici le devoir de la semaine prochaine.'));
      expect(textes, contains('Classe An-Nour'));
      expect(textes, contains("Parent d'Adam"));
    });

    test('ar : aucun mot francais, pour chaque role', () async {
      await LocaleSettings.setLocale(AppLocale.ar);
      for (final RoleDemoCommunications r in RoleDemoCommunications.values) {
        for (final String s in _textesVisibles(r)) {
          expect(
            _latin.hasMatch(s),
            isFalse,
            reason: '${r.name} : « $s » est en francais dans l arabe',
          );
        }
      }
      expect(
        _textesVisibles(RoleDemoCommunications.tuteur),
        contains('إليكم واجب الأسبوع القادم.'),
      );
    });

    test('ar : l apercu de la liste est en arabe', () async {
      await LocaleSettings.setLocale(AppLocale.ar);
      final List<ResumeFil> fils = await MessagesMetierDemo(
        role: RoleDemoCommunications.tuteur,
        maintenant: _maintenant,
      ).fils();
      for (final ResumeFil f in fils) {
        expect(_latin.hasMatch(f.apercu ?? ''), isFalse, reason: f.apercu);
      }
    });
  });

  group('Ligne compacte du fil, nom long', () {
    Future<void> monter(WidgetTester tester, double echelle) async {
      tester.view.physicalSize = const Size(176, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      LocaleSettings.setLocaleSync(AppLocale.fr);
      final FilMetier fil = fixturesMessagesDemo(
        RoleDemoCommunications.tuteur,
        _maintenant,
      ).firstWhere((FilMetier f) => f.id == 'fil-adam');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(176, 400),
              textScaler: TextScaler.linear(echelle),
            ),
            child: Material(
              child: Align(
                alignment: Alignment.topLeft,
                child: EnteteFilContexte.duFil(fil, compacte: true),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('texte x1,5 (plafond de la ligne) : un paragraphe entier', (
      WidgetTester tester,
    ) async {
      // 176 : la largeur de la ligne a 320, entre retour et (i).
      await monter(tester, 1.5);
      final Finder fluide = find.byKey(
        EnteteFilContexte.cleLigneCompacteFluide,
      );
      expect(fluide, findsOneWidget);
      final RenderParagraph p = tester.renderObject(
        find.descendant(of: fluide, matching: find.byType(RichText)),
      );
      expect(p.didExceedMaxLines, isFalse, reason: 'aucune ellipse');
      expect(p.text.toPlainText(), contains('Sayyida Mariam'));
      expect(p.text.toPlainText(), contains('Adam'));
      // Sous le sixieme d'un ecran de 640, marge de la ligne (8) comprise.
      expect(
        tester.getRect(find.byKey(EnteteFilContexte.cle)).height + 8,
        lessThanOrEqualTo(640 / 6),
      );
    });

    testWidgets('texte x1 : noms puis objets, en deux blocs', (
      WidgetTester tester,
    ) async {
      await monter(tester, 1);
      expect(
        find.byKey(EnteteFilContexte.cleLigneCompacteFluide),
        findsNothing,
      );
      expect(find.text('Sayyida Mariam'), findsOneWidget);
    });
  });

  group('Studio et Communaute suivent la langue (captures 390_rtl_clair)', () {
    test('fr : les textes francais d origine', () {
      LocaleSettings.setLocaleSync(AppLocale.fr);
      expect(_textesStudio(), contains('Organisation générale'));
      expect(_textesStudio(), contains('Merci à tous pour la semaine.'));
      expect(_textesStudio(), contains('Budget confidentiel du trimestre'));
      expect(_textesCommunaute(), contains('Idées pour la mémorisation ?'));
      expect(_textesCommunaute(), contains('Samira Belkacem'));
      expect(DonneesCommunauteDemo.soi.nomAffiche, 'Sayyid Ibrahim');
      expect(
        DonneesCommunauteDemo.brouillonAffilie.texte,
        endsWith(DonneesCommunauteDemo.lienAffilieDemo),
      );
    });

    test('ar : aucun mot francais dans le Studio', () async {
      await LocaleSettings.setLocale(AppLocale.ar);
      for (final String s in _textesStudio()) {
        expect(
          _latin.hasMatch(_sansTechnique(s)),
          isFalse,
          reason: '« $s » est en francais dans l arabe',
        );
      }
      expect(_textesStudio(), contains('التنظيم العام'));
    });

    test('ar : aucun mot francais dans la Communaute', () async {
      await LocaleSettings.setLocale(AppLocale.ar);
      for (final String s in _textesCommunaute()) {
        expect(
          _latin.hasMatch(_sansTechnique(s)),
          isFalse,
          reason: '« $s » est en francais dans l arabe',
        );
      }
      // Le garde reconnait ses brouillons marques dans la langue courante.
      final BrouillonMarqueDemo b = DonneesCommunauteDemo.brouillonAffilie;
      expect(b.texte, contains(DonneesCommunauteDemo.lienAffilieDemo));
      expect(DonneesCommunauteDemo.soi.nomAffiche, 'سيد إبراهيم');
    });
  });

  group('Initiales arabes', () {
    Future<void> monter(WidgetTester tester, String prenom) =>
        tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            home: Material(child: AvatarTile(prenom: prenom)),
          ),
        );

    testWidgets('deux initiales arabes restent isolees (pas « سم »)', (
      WidgetTester tester,
    ) async {
      await monter(tester, 'سيدة مريم');
      expect(find.text('س\u200Cم'), findsOneWidget);
      expect(find.text('سم'), findsNothing);
    });

    testWidgets('en francais, inchange', (WidgetTester tester) async {
      await monter(tester, 'Sayyida Mariam');
      expect(find.text('SM'), findsOneWidget);
    });
  });

  group('ar : les guillemets se lisent tournes vers l exterieur', () {
    // Les chaines arabes stockent les guillemets dans l'ORDRE LOGIQUE
    // (« ouvre, » ferme), comme tout texte Unicode : c'est ce que recoivent
    // le lecteur d'ecran, le copier-coller et la recherche. Au rendu, dans
    // une ligne droite-a-gauche, U+00AB et U+00BB (Bidi_Mirrored) prennent
    // le niveau du texte arabe qui les entoure et le moteur (HarfBuzz) les
    // dessine en miroir : l'ouvrant, a droite du titre, pointe a droite,
    // le fermant, a gauche, pointe a gauche.
    //
    // Contre-preuve : a 5c0bffa3, les chaines etaient stockees dans l'ordre
    // VISUEL (»titre«). Mesure faite sur com_admin_moderation_390_rtl_clair
    // de 5c0bffa3, pixels lus : le glyphe a droite de « بطاقات » pointait a
    // gauche, vers le titre ; le contournement inversait le rendu qu'il
    // pretendait corriger, et le texte lu etait faux.
    //
    // Le parametre {texte} (saisie de l'utilisateur, latine ou arabe) est
    // isole (U+2068 FSI ... U+2069 PDI) : vu de dehors, il compte comme un
    // seul neutre, donc les guillemets prennent toujours le sens de la
    // phrase arabe, quel que soit ce qu'on cherche. Les marques sont des
    // caracteres de format, sans glyphe, que les lecteurs d'ecran taisent.

    Map<String, Object?> lireAr() =>
        jsonDecode(File('assets/i18n/ar.i18n.json').readAsStringSync())
            as Map<String, Object?>;

    test('ordre logique stocke, aucun ordre visuel', () {
      final List<String> visuels = <String>[];
      final List<String> cites = <String>[];
      void parcourir(Object? v) {
        if (v is Map<String, Object?>) {
          v.values.forEach(parcourir);
        } else if (v is String) {
          if (RegExp('»[^«»]*«').hasMatch(v)) visuels.add(v);
          if (RegExp('«[^«»]+»').hasMatch(v)) cites.add(v);
        }
      }

      parcourir(lireAr());
      expect(visuels, isEmpty);
      // Six chaines citantes sur la ligne Communications ; la jonction
      // (JONCTION-LIGNES-1) en ajoute d'autres (Comptable, cartes de la
      // classe) : toutes en ordre logique, aucune ne doit manquer.
      expect(cites.length, greaterThanOrEqualTo(6));
      // Pas d'espace a l'interieur des guillemets arabes.
      expect(
        cites.where((String c) => RegExp(r'«\s|\s»').hasMatch(c)),
        isEmpty,
      );
      LocaleSettings.setLocaleSync(AppLocale.ar);
      expect(
        t.com.annonces.demoPublication.signalementAffilie,
        'منشور «بطاقات تجويد للطباعة»',
      );
      expect(
        t.com.studio.recherche.aucun(texte: 'abc'),
        'لا شيء يطابق «\u2068abc\u2069» في قنواتك. جرّب كلمة أخرى.',
      );
    });

    // Chaque chaine citante, avec des parametres latins, arabes et mixtes.
    List<String> citations() {
      LocaleSettings.setLocaleSync(AppLocale.ar);
      final List<String> saisies = <String>[
        'فاطمة',
        'Fatima',
        'An-Nour 3',
        '(abc',
        '12',
      ];
      return <String>[
        t.notifications.filtreVidePhrase,
        t.com.annonces.demoPublication.signalementAffilie,
        t.com.annonces.demoPublication.signalementVente,
        t.com.annonces.demoPublication.signalementHorsSujet,
        for (final String s in saisies) ...<String>[
          t.com.messages.recherche.aucun(texte: s),
          t.com.studio.recherche.aucun(texte: s),
        ],
      ];
    }

    testWidgets('rendu mesure : l ouvrant a droite pointe a droite, le '
        'fermant a gauche pointe a gauche', (WidgetTester tester) async {
      final List<String> textes = citations();
      tester.view.physicalSize = const Size(1600, 200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final String texte in textes) {
        final ((Rect, bool) ouvrant, (Rect, bool) fermant) =
            await _mesurerGuillemets(tester, texte);
        expect(
          ouvrant.$1.left,
          greaterThan(fermant.$1.right),
          reason: '« doit etre a droite de » dans une ligne arabe : $texte',
        );
        expect(
          ouvrant.$2,
          isFalse,
          reason: '« a droite du titre doit pointer a droite : $texte',
        );
        expect(
          fermant.$2,
          isTrue,
          reason: '» a gauche du titre doit pointer a gauche : $texte',
        );
      }
    });

    testWidgets('contre-preuve : l ordre visuel est dessine vers l interieur', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final (
        (Rect, bool) droite,
        (Rect, bool) gauche,
      ) = await _mesurerGuillemets(
        tester,
        'منشور »بطاقات تجويد للطباعة«',
        ouvrant: '»',
        fermant: '«',
      );
      expect(droite.$1.left, greaterThan(gauche.$1.right));
      expect(droite.$2, isTrue, reason: 'vers l interieur, a droite');
      expect(gauche.$2, isFalse, reason: 'vers l interieur, a gauche');
    });
  });

  testWidgets('liste des fils : « Classe An-Nour » ne se coupe plus au '
      'trait d union (capture com_admin_messages_1440)', (
    WidgetTester tester,
  ) async {
    LocaleSettings.setLocaleSync(AppLocale.fr);
    // 326 : la colonne de la liste a 1440, ou la ligne de la mission se
    // coupait en « Classe An- » / « Nour ».
    tester.view.physicalSize = const Size(326, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final List<ResumeFil> fils = await MessagesMetierDemo(
      role: RoleDemoCommunications.admin,
      maintenant: _maintenant,
    ).fils();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
        home: Material(
          child: ListeFils(
            fils: fils,
            onOuvrir: (String _) {},
            horloge: () => _maintenant,
          ),
        ),
      ),
    );
    final Finder legende = find.byWidgetPredicate(
      (Widget w) =>
          w is RichText &&
          w.text.toPlainText().startsWith('Visite de contrôle, Classe An'),
    );
    expect(legende, findsOneWidget);
    final RenderParagraph p = tester.renderObject(legende);
    final String texte = p.text.toPlainText();
    final int nour = texte.indexOf('Nour');
    double ligneDe(int offset) =>
        p.getOffsetForCaret(TextPosition(offset: offset), Rect.zero).dy;
    expect(
      ligneDe(nour - 3),
      ligneDe(nour + 1),
      reason: '« An- » et « Nour » sur la meme ligne',
    );
    expect(texte, contains('An\u2011Nour'));
  });
}

/// Rend [texte] dans une ligne droite-a-gauche, avec la vraie police
/// arabe de l'interface, et rend pour [ouvrant] puis [fermant] sa boite et
/// le sens de sa pointe, lu sur les pixels (`true` : pointe a gauche).
///
/// Seuls les guillemets sont peints (le reste du texte est transparent,
/// meme police et meme mise en page) : l'encre d'une lettre voisine ne
/// fausse pas la lecture. Un chevron pointe a gauche quand, a mi-hauteur,
/// son encre va plus a gauche qu'en haut de son dessin.
Future<((Rect, bool), (Rect, bool))> _mesurerGuillemets(
  WidgetTester tester,
  String texte, {
  String ouvrant = '«',
  String fermant = '»',
}) async {
  const Key cadre = ValueKey<String>('guillemets');
  final List<TextSpan> morceaux = <TextSpan>[
    for (final Match m in RegExp('[«»]|[^«»]+').allMatches(texte))
      TextSpan(
        text: m[0],
        style: TextStyle(
          color: '«»'.contains(m[0]!) ? Colors.black : Colors.transparent,
        ),
      ),
  ];
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Material(
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: RepaintBoundary(
              key: cadre,
              child: ColoredBox(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text.rich(
                    TextSpan(children: morceaux),
                    style: const TextStyle(fontSize: 40),
                    softWrap: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  final RenderParagraph p = tester.renderObject(
    find.descendant(of: find.byKey(cadre), matching: find.byType(RichText)),
  );
  final RenderRepaintBoundary boite = tester.renderObject(find.byKey(cadre));
  // La largeur en pixels de l'image (arrondie au-dessus), pas celle du
  // cadre : c'est le pas d'une ligne d'octets.
  final (ByteData, int) image = (await tester.runAsync<(ByteData, int)>(
    () async {
      final ui.Image image = await boite.toImage();
      final ByteData brut = (await image.toByteData())!;
      final int largeur = image.width;
      image.dispose();
      return (brut, largeur);
    },
  ))!;
  final (ByteData octets, int largeur) = image;
  bool encre(int x, int y) => octets.getUint8((y * largeur + x) * 4) < 128;

  (Rect, bool) lire(String guillemet) {
    final int i = texte.indexOf(guillemet);
    expect(i, isNot(-1), reason: '$guillemet absent de $texte');
    final TextBox b = p
        .getBoxesForSelection(TextSelection(baseOffset: i, extentOffset: i + 1))
        .single;
    final Rect r = Rect.fromPoints(
      p.localToGlobal(Offset(b.left, b.top)) - boite.localToGlobal(Offset.zero),
      p.localToGlobal(Offset(b.right, b.bottom)) -
          boite.localToGlobal(Offset.zero),
    );
    final List<(int, int)> lignes = <(int, int)>[];
    for (int y = r.top.floor(); y < r.bottom.ceil(); y++) {
      int? gauche;
      for (int x = r.left.floor(); x < r.right.ceil(); x++) {
        if (encre(x, y)) {
          gauche = x;
          break;
        }
      }
      if (gauche != null) lignes.add((y, gauche));
    }
    expect(lignes.length, greaterThan(6), reason: '$guillemet sans encre');
    final int haut = lignes.first.$2;
    final (int, int) milieu = lignes[lignes.length ~/ 2];
    return (r, milieu.$2 < haut);
  }

  return (lire(ouvrant), lire(fermant));
}
