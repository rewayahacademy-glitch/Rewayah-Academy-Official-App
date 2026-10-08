// COM-RC lot K (08/10) : defauts visuels des Communications, mesures sur
// les vraies pages (Studio de demonstration) et sur le fil nu.
//
// 1. « Envoyer » reste dans la colonne du fil a 768 et 1440 (canal et
//    Focus) : les bulles, le champ et « Envoyer » partagent le bord de fin.
//    Contre-preuve : a 7356160b, la bulle s'arretait a 86 % du fil et
//    « Envoyer » la depassait de ~65 points a 1440.
// 2. A 320 en texte x2, l'icone du micro suit l'echelle du texte (bornee a
//    x2), cible de 48 au moins. Contre-preuve : icone fixe de 24.
// 3. « Mode focus » : son libelle commence au bord du titre du canal (LTR
//    et RTL), cible de 48 gardee. Contre-preuve : retrait de 12.
// 4. A 390, le champ du canal tient sur une ligne au repos, comme celui des
//    Messages metier ; l'aide n'apparait qu'au focus. Contre-preuve : l'aide
//    (« Ecrire dans Organisation generale ») sur deux lignes, invisible,
//    doublait la hauteur du champ.
// 5. La ligne de contexte passe a la ligne (deux lignes au plus) au lieu
//    de se couper a 320 en texte x2, et se lit en entier. Contre-preuve :
//    « Organisation gene... », « Classe An-Nour · Y... ».
// 6. Le moment relatif ne se coupe jamais (« Il y a » / « 2 h »), meme
//    quand la fonction porte son propre « · » ; en arabe, le nombre
//    s'accorde (« منذ ساعتين », « منذ 3 ساعات »).
// Revue du lot K : un message de soi garde 92 % a la fin sur tablette et
// bureau ; l'aide du champ reste posee (lue par les lecteurs d'ecran), sur
// une ligne (`hintMaxLines: 1`), et le champ ne grandit pas au toucher.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/features/com_communaute/flux_publications.dart';
import 'package:rewayah_academy/features/com_messages/entete_fil_contexte.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:rewayah_academy/features/com_studio/canal_page.dart';
import 'package:rewayah_academy/features/com_vocal/composer_vocal.dart';
import 'package:rewayah_academy/features/demo/communications/com_vocal_demo.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/harnais.dart';
import 'support_focus.dart';
import 'support_studio.dart';

/// La hauteur d'un champ rempli a une ligne, libelle compris (Material 3).
const double _hauteurUneLigne = 56;

final String _organisation = Routes.canalStudioPour('organisation');

TextesFilDiscussion _textes(String aide) => TextesFilDiscussion(
  aideChamp: aide,
  libelleChamp: 'Message',
  envoyer: 'Envoyer',
  champVide: 'Ecrivez un message pour l envoyer.',
  enCours: 'En cours',
  envoye: 'Envoye',
  echec: 'Non confirme',
  reessayer: 'Reessayer',
  auteurSoi: 'Vous',
  annonce: (String a, String texte) => '$a : $texte',
);

const MessageFil _soi = MessageFil(
  id: 'k2',
  auteur: 'Vous',
  texte: 'Bonne semaine a toutes et a tous.',
  horodatage: 'Dimanche 4 octobre, 11:45',
  deSoi: true,
);

const MessageFil _recu = MessageFil(
  id: 'k1',
  auteur: 'Samira',
  texte: 'Merci a tous pour la semaine.',
  horodatage: 'Dimanche 4 octobre, 11:40',
  deSoi: false,
);

/// Un fil nu, vrai theme, [taille], texte x[echelle].
Future<void> _monterFil(
  WidgetTester tester,
  Widget fil, {
  Size taille = const Size(390, 844),
  double echelle = 1,
  List<Override> surcharges = const <Override>[],
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = echelle;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        ...surcharges,
      ],
      child: TranslationProvider(
        child: Builder(
          builder: (BuildContext context) => MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: TranslationProvider.of(context).flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: fil,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Le cadre peint d'une bulle visible (le premier `Container` sous sa
/// fraction de largeur).
Rect _bulle(WidgetTester tester, String id) => tester.getRect(
  find
      .descendant(
        of: find.descendant(
          of: find.byKey(ValueKey<String>('message-$id')),
          matching: find.byType(FractionallySizedBox),
        ),
        matching: find.byType(Container),
      )
      .first,
);

/// Le texte peint d'un [Text] (sa boite de paragraphe).
RenderParagraph _paragraphe(WidgetTester tester, Finder texte) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(of: texte, matching: find.byType(RichText)).first,
    );

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('lot K, point 1 : « Envoyer » dans la colonne du fil', () {
    for (final (String nom, Size taille, bool focus) in <(String, Size, bool)>[
      ('canal a 1440', const Size(1440, 900), false),
      ('Focus a 1440', const Size(1440, 900), true),
      ('canal a 768', const Size(768, 1024), false),
    ]) {
      testWidgets('$nom : la bulle et « Envoyer » finissent au meme bord', (
        WidgetTester tester,
      ) async {
        await monterStudio(
          tester,
          port: portDemo(),
          depart: _organisation,
          taille: taille,
        );
        if (focus) await entrer(tester);
        final Rect envoyer = tester.getRect(
          find.byKey(FilDiscussion.envoyerKey),
        );
        final Rect champ = tester.getRect(find.byKey(FilDiscussion.champKey));
        // La derniere bulle recue (Samira), toujours a l'ecran au-dessus du
        // champ.
        final Finder messages = find.byWidgetPredicate(
          (Widget w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('message-'),
        );
        final List<Element> visibles = messages.evaluate().toList();
        expect(visibles, isNotEmpty);
        final String id = (visibles.last.widget.key! as ValueKey<String>).value
            .substring('message-'.length);
        final Rect bulle = _bulle(tester, id);
        expect(
          envoyer.right,
          lessThanOrEqualTo(bulle.right + 1),
          reason: '« Envoyer » ne depasse pas la colonne des bulles',
        );
        expect(
          bulle.right,
          moreOrLessEquals(envoyer.right, epsilon: 1),
          reason: 'les bulles et « Envoyer » partagent le bord de fin',
        );
        expect(
          bulle.left,
          moreOrLessEquals(champ.left, epsilon: 1),
          reason: 'et le bord de debut, avec le champ',
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('telephone (390) : la bulle garde son retrait de '
        'conversation (86 %)', (WidgetTester tester) async {
      await _monterFil(
        tester,
        FilDiscussion(
          messages: const <MessageFil>[_recu],
          textes: _textes('Message'),
          onEnvoyer: (String _) async {},
        ),
      );
      final Rect bulle = _bulle(tester, 'k1');
      final double fil = tester.getSize(find.byType(FilDiscussion)).width;
      expect(
        bulle.width,
        moreOrLessEquals(fil * FilDiscussion.partBulleTelephone, epsilon: 1),
      );
    });
  });

  group('lot K, point 1 : ses propres messages gardent leur place', () {
    for (final Size taille in const <Size>[Size(1440, 900), Size(768, 1024)]) {
      testWidgets('${taille.width.toInt()} : recu sur toute la colonne, '
          'message de soi a 92 % pose au bord d « Envoyer »', (
        WidgetTester tester,
      ) async {
        await _monterFil(
          tester,
          FilDiscussion(
            messages: const <MessageFil>[_recu, _soi],
            textes: _textes('Message'),
            onEnvoyer: (String _) async {},
          ),
          taille: taille,
        );
        final Rect recu = _bulle(tester, 'k1');
        final Rect soi = _bulle(tester, 'k2');
        final Rect champ = tester.getRect(find.byKey(FilDiscussion.champKey));
        final Rect envoyer = tester.getRect(
          find.byKey(FilDiscussion.envoyerKey),
        );
        final double colonne = envoyer.right - champ.left;
        expect(recu.left, moreOrLessEquals(champ.left, epsilon: 1));
        expect(recu.right, moreOrLessEquals(envoyer.right, epsilon: 1));
        expect(
          soi.width,
          moreOrLessEquals(
            colonne * FilDiscussion.partBulleSoiColonne,
            epsilon: 1,
          ),
          reason: 'un leger retrait au debut distingue le message de soi',
        );
        expect(soi.right, moreOrLessEquals(envoyer.right, epsilon: 1));
        expect(soi.left, greaterThan(recu.left + 8));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('390 : le message de soi a 86 %, a la fin', (
      WidgetTester tester,
    ) async {
      await _monterFil(
        tester,
        FilDiscussion(
          messages: const <MessageFil>[_recu, _soi],
          textes: _textes('Message'),
          onEnvoyer: (String _) async {},
        ),
      );
      final Rect fil = tester.getRect(find.byType(FilDiscussion));
      final Rect soi = _bulle(tester, 'k2');
      expect(
        soi.width,
        moreOrLessEquals(
          fil.width * FilDiscussion.partBulleTelephone,
          epsilon: 1,
        ),
      );
      expect(soi.right, moreOrLessEquals(fil.right, epsilon: 1));
    });
  });

  group('lot K, point 2 : le micro suit l echelle du texte', () {
    Widget filVocal() => FilDiscussion(
      messages: const <MessageFil>[_recu],
      textes: _textes('Message'),
      onEnvoyer: (String _) async {},
      emplacementVocal: ComposerVocal(onEnvoyer: (_) async {}),
    );

    Size icone(WidgetTester tester) => tester.getSize(
      find.descendant(
        of: find.byKey(FilDiscussion.cleMicro),
        matching: find.byType(Icon),
      ),
    );

    testWidgets('320, texte x2 : icone x2 (48), cible de 64, aussi haute '
        'que la ligne d « Envoyer » a peu pres', (WidgetTester tester) async {
      await _monterFil(
        tester,
        filVocal(),
        taille: const Size(320, 800),
        echelle: 2,
        surcharges: surchargesVocalDemo(),
      );
      expect(icone(tester).width, 48);
      final Size micro = tester.getSize(find.byKey(FilDiscussion.cleMicro));
      expect(micro.width, 64);
      expect(micro.height, 64);
      final Size envoyer = tester.getSize(find.byKey(FilDiscussion.envoyerKey));
      expect(
        (micro.height - envoyer.height).abs(),
        lessThanOrEqualTo(16),
        reason: 'le micro n est plus minuscule a cote d « Envoyer »',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('texte x1 : inchange (icone 24, cible 48)', (
      WidgetTester tester,
    ) async {
      await _monterFil(tester, filVocal(), surcharges: surchargesVocalDemo());
      expect(icone(tester).width, 24);
      expect(tester.getSize(find.byKey(FilDiscussion.cleMicro)).height, 48);
    });

    testWidgets('texte x3 : bornee a x2', (WidgetTester tester) async {
      await _monterFil(
        tester,
        filVocal(),
        taille: const Size(320, 800),
        echelle: 3,
        surcharges: surchargesVocalDemo(),
      );
      expect(icone(tester).width, 48);
    });
  });

  group('lot K, point 3 : « Mode focus » au bord du titre', () {
    for (final (String nom, AppLocale langue) in <(String, AppLocale)>[
      ('390', AppLocale.fr),
      ('390, arabe', AppLocale.ar),
    ]) {
      testWidgets('$nom : le libelle commence au bord du titre du canal', (
        WidgetTester tester,
      ) async {
        await monterStudio(
          tester,
          port: portDemo(),
          depart: _organisation,
          taille: const Size(390, 844),
          langue: langue,
        );
        final bool rtl = langue == AppLocale.ar;
        final Rect titre = tester.getRect(
          find
              .descendant(
                of: find.byKey(EnteteCanal.cle),
                matching: find.byType(RichText),
              )
              .first,
        );
        final Rect libelle = tester.getRect(
          find
              .descendant(of: entrerFocus, matching: find.byType(RichText))
              .first,
        );
        expect(
          libelle.top,
          greaterThan(titre.bottom),
          reason: 'a 390, « Mode focus » est sous le titre',
        );
        if (rtl) {
          expect(libelle.right, moreOrLessEquals(titre.right, epsilon: 1));
        } else {
          expect(libelle.left, moreOrLessEquals(titre.left, epsilon: 1));
        }
        // La cible reste pleine, et se touche.
        final Rect cible = tester.getRect(
          find
              .descendant(of: entrerFocus, matching: find.byType(Semantics))
              .first,
        );
        expect(cible.height, greaterThanOrEqualTo(48));
        await tester.tap(entrerFocus);
        await tester.pumpAndSettle();
        expect(quitterFocus, findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('lot K, point 4 : le champ tient sur une ligne au repos', () {
    // La hauteur du cadre du champ : du haut du champ au haut de son aide
    // ecrite dessous (« Ecrivez un message... »).
    double cadre(WidgetTester tester) {
      final Rect champ = tester.getRect(find.byKey(FilDiscussion.champKey));
      final Rect aide = tester.getRect(
        find.text('Ecrivez un message pour l envoyer.'),
      );
      return aide.top - champ.top;
    }

    const String longue =
        'Ecrire dans Organisation generale, puis envoyer a l equipe';
    Widget fil(String aide) => FilDiscussion(
      key: ValueKey<String>(aide),
      messages: const <MessageFil>[_recu],
      textes: _textes(aide),
      onEnvoyer: (String _) async {},
    );
    InputDecoration deco(WidgetTester tester) => tester
        .widget<TextField>(find.byKey(FilDiscussion.champKey))
        .decoration!;

    testWidgets('390 : une aide trop longue pour une ligne ne grandit le '
        'champ ni au repos ni au toucher, ne se coupe pas, et reste lue', (
      WidgetTester tester,
    ) async {
      await _monterFil(tester, fil('Message'));
      final double court = cadre(tester);
      await _monterFil(tester, fil(longue));
      expect(cadre(tester), moreOrLessEquals(court, epsilon: 0.5));
      expect(
        deco(tester).hintText,
        isNull,
        reason: 'pas d aide coupee (« Ecrire dans Organi... »)',
      );
      final SemanticsHandle sem = tester.ensureSemantics();
      // Les lecteurs d'ecran lisent l'aide entiere, sans focus de saisie.
      expect(
        tester.getSemantics(find.byKey(FilDiscussion.champKey)),
        matchesSemantics(
          label: 'Message',
          hint: longue,
          isTextField: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
          isMultiline: true,
        ),
      );
      // Au toucher, avant toute frappe : meme hauteur, aide toujours dite.
      await tester.tap(find.byKey(FilDiscussion.champKey));
      await tester.pumpAndSettle();
      expect(cadre(tester), moreOrLessEquals(court, epsilon: 0.5));
      expect(
        tester.getSemantics(find.byKey(FilDiscussion.champKey)).hint,
        longue,
      );
      // A la saisie, le champ grandit avec son texte.
      final double avant = tester
          .getRect(find.byKey(FilDiscussion.champKey))
          .height;
      await tester.enterText(
        find.byKey(FilDiscussion.champKey),
        'Une ligne\nune deuxieme\nune troisieme',
      );
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(FilDiscussion.champKey)).height,
        greaterThan(avant),
      );
      sem.dispose();
    });

    testWidgets('1440 : l aide qui tient sur une ligne se peint au toucher, '
        'sans grandir le champ, et se lit une seule fois', (
      WidgetTester tester,
    ) async {
      await _monterFil(tester, fil('Message'), taille: const Size(1440, 900));
      final double court = cadre(tester);
      await _monterFil(tester, fil(longue), taille: const Size(1440, 900));
      expect(deco(tester).hintText, longue);
      expect(deco(tester).hintMaxLines, 1);
      final SemanticsHandle sem = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byKey(FilDiscussion.champKey)).hint,
        longue,
      );
      await tester.tap(find.byKey(FilDiscussion.champKey));
      await tester.pumpAndSettle();
      expect(cadre(tester), moreOrLessEquals(court, epsilon: 0.5));
      final SemanticsNode noeud = tester.getSemantics(
        find.byKey(FilDiscussion.champKey),
      );
      expect(noeud.label, 'Message\n$longue');
      expect(noeud.hint, isEmpty, reason: 'pas lue deux fois');
      sem.dispose();
    });

    testWidgets('Studio a 390 : le champ du canal tient sur une ligne au '
        'repos (56, la hauteur d un champ a une ligne)', (
      WidgetTester tester,
    ) async {
      await monterStudio(
        tester,
        port: portDemo(),
        depart: _organisation,
        taille: const Size(390, 844),
      );
      final double canal = tester
          .getSize(
            find.descendant(
              of: find.byKey(FilDiscussion.champKey),
              matching: find.byType(InputDecorator),
            ),
          )
          .height;
      final double aide = tester
          .getSize(find.text(t.com.socle.composants.composer.champVide))
          .height;
      // Le decorateur porte le champ et son aide ecrite dessous.
      expect(canal - aide, moreOrLessEquals(_hauteurUneLigne, epsilon: 8));
      // Au toucher, avant toute frappe, toujours une ligne.
      await tester.tap(find.byKey(FilDiscussion.champKey));
      await tester.pumpAndSettle();
      final double touche = tester
          .getSize(
            find.descendant(
              of: find.byKey(FilDiscussion.champKey),
              matching: find.byType(InputDecorator),
            ),
          )
          .height;
      expect(touche, moreOrLessEquals(canal, epsilon: 0.5));
      expect(tester.takeException(), isNull);
    });
  });

  group('lot K, point 5 : la ligne de contexte passe a la ligne', () {
    testWidgets('Studio a 320, texte x2 : « Organisation generale » entier, '
        'sur deux lignes, lu en entier', (WidgetTester tester) async {
      await monterStudio(
        tester,
        port: portDemo(),
        depart: _organisation,
        taille: const Size(320, 800),
        echelleTexte: 2,
      );
      final Finder compacte = find.descendant(
        of: find.byKey(FilDiscussion.cleEnteteCompacte),
        matching: find.byKey(EnteteCanal.cle),
      );
      expect(compacte, findsOneWidget);
      final RenderParagraph p = _paragraphe(tester, compacte);
      expect(p.didExceedMaxLines, isFalse, reason: 'aucune coupure');
      final SemanticsHandle s = tester.ensureSemantics();
      // Le nom entier, puis l'action (i) de la meme rangee.
      expect(
        tester.getSemantics(compacte).label,
        startsWith('Organisation générale\n'),
      );
      s.dispose();
      expect(tester.takeException(), isNull);
    });

    testWidgets('fil metier, 320 texte x2 : les objets entiers sur deux '
        'lignes au plus', (WidgetTester tester) async {
      const Participant fatima = Participant(
        id: 'p-fatima',
        nomAffiche: 'Fatima',
        fonction: 'Parent de Yasmine',
      );
      // La largeur de la ligne compacte a 320 : retour et (i) de chaque
      // cote, gouttieres comprises ; texte x2 borne a 150 %.
      await _monterFil(
        tester,
        Center(
          child: SizedBox(
            width: 176,
            child: EnteteFilContexte(
              compacte: true,
              interlocuteurs: const <Participant>[fatima],
              objets: <ObjetLie>[
                ObjetLie(
                  type: TypeObjetLie.classe,
                  id: 'c',
                  libelle: 'Classe An-Nour',
                ),
                ObjetLie(type: TypeObjetLie.eleve, id: 'y', libelle: 'Yasmine'),
              ],
            ),
          ),
        ),
        taille: const Size(320, 800),
        echelle: 1.5,
      );
      final Finder objets = find.text('Classe An-Nour · Yasmine');
      expect(objets, findsOneWidget);
      final RenderParagraph p = tester.renderObject<RenderParagraph>(objets);
      expect(p.didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);
    });
  });

  group('lot K, point 6 : le moment relatif ne se coupe pas', () {
    test('espaces insecables dans le moment et avant « · »', () {
      final String ligne = ligneAuteurCommunaute(
        'Enseignante, Classe An-Nour',
        'Il y a 2 h',
      );
      expect(ligne, 'Enseignante, Classe An-Nour · Il y a 2 h');
      expect(ligneAuteurCommunaute(null, 'Il y a 2 h'), 'Il y a 2 h');
    });

    test('une fonction qui porte son propre « · » reste secable ; '
        'l espace insecable precede le dernier separateur', () {
      final String ligne = ligneAuteurCommunaute(
        'Enseignante · Classe An-Nour',
        'Il y a 2 h',
      );
      expect(
        ligne,
        'Enseignante · Classe An-Nour\u00A0· Il\u00A0y\u00A0a\u00A02\u00A0h',
      );
    });

    test('arabe : le nombre s accorde (minutes, heures, jours)', () {
      LocaleSettings.setLocaleSync(AppLocale.ar);
      addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
      final DateTime maintenant = DateTime(2026, 10, 8, 12);
      String il(Duration d) =>
          momentCommunaute(maintenant.subtract(d), maintenant);
      expect(il(const Duration(minutes: 1)), 'منذ دقيقة');
      expect(il(const Duration(minutes: 2)), 'منذ دقيقتين');
      expect(il(const Duration(minutes: 5)), 'منذ 5 دقائق');
      expect(il(const Duration(minutes: 12)), 'منذ 12 دقيقة');
      expect(il(const Duration(hours: 1)), 'منذ ساعة');
      expect(il(const Duration(hours: 2)), 'منذ ساعتين');
      expect(il(const Duration(hours: 3)), 'منذ 3 ساعات');
      expect(il(const Duration(hours: 11)), 'منذ 11 ساعة');
      expect(il(const Duration(days: 1)), 'منذ يوم');
      expect(il(const Duration(days: 2)), 'منذ يومين');
      expect(il(const Duration(days: 3)), 'منذ 3 أيام');
      LocaleSettings.setLocaleSync(AppLocale.fr);
      expect(il(const Duration(hours: 2)), 'Il y a 2 h');
      expect(il(const Duration(minutes: 1)), 'Il y a 1 min');
    });

    testWidgets('390 : « Il y a 2 h » sur une seule ligne', (
      WidgetTester tester,
    ) async {
      final String ligne = ligneAuteurCommunaute(
        'Enseignante, Classe An-Nour',
        'Il y a 2 h',
      );
      // La colonne du nom de l'auteur a 390, entre l'avatar et (i) / menu.
      await _monterFil(
        tester,
        Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(width: 200, child: Text(ligne)),
        ),
      );
      final RenderParagraph p = tester.renderObject<RenderParagraph>(
        find.text(ligne),
      );
      const String moment = 'Il y a 2 h';
      final int debut = ligne.indexOf(moment);
      final List<TextBox> boites = p.getBoxesForSelection(
        TextSelection(baseOffset: debut, extentOffset: debut + moment.length),
      );
      final Set<double> lignes = <double>{
        for (final TextBox b in boites) b.top,
      };
      expect(lignes, hasLength(1), reason: 'le moment tient sur une ligne');
    });
  });
  group('lot K : « An-Nour » jamais coupe a son trait d union', () {
    testWidgets('en-tete d un fil metier a 1440 : « Classe An-Nour » entier', (
      WidgetTester tester,
    ) async {
      const Participant mariam = Participant(
        id: 'p-mariam',
        nomAffiche: 'Mme Mariam',
        fonction: 'Enseignante de la Classe An-Nour',
      );
      // Toutes les largeurs de la colonne du nom, de 300 a 520 : a l'une
      // d'elles (1440, colonne du fil de 464), « An- » tenait en fin de
      // ligne et « Nour » passait seul a la suivante.
      for (double largeur = 300; largeur <= 520; largeur += 2) {
        await _monterFil(
          tester,
          Align(
            alignment: AlignmentDirectional.topStart,
            child: SizedBox(
              width: largeur,
              child: EnteteFilContexte(
                interlocuteurs: const <Participant>[mariam],
                objets: <ObjetLie>[
                  ObjetLie(
                    type: TypeObjetLie.classe,
                    id: 'c',
                    libelle: 'Classe An-Nour',
                  ),
                ],
              ),
            ),
          ),
          taille: const Size(1440, 900),
        );
        final RenderParagraph p = tester.renderObject<RenderParagraph>(
          find.textContaining('Mme Mariam,'),
        );
        final String texte = p.text.toPlainText();
        final int debut = texte.indexOf('Nour') - 3;
        final List<TextBox> boites = p.getBoxesForSelection(
          TextSelection(baseOffset: debut, extentOffset: debut + 7),
        );
        // Une seule ligne : toutes les boites se chevauchent en hauteur (le
        // glyphe U+2011 peut avoir sa propre boite).
        final double hautMax = boites
            .map((TextBox b) => b.top)
            .reduce((double a, double b) => a > b ? a : b);
        final double basMin = boites
            .map((TextBox b) => b.bottom)
            .reduce((double a, double b) => a < b ? a : b);
        expect(
          hautMax,
          lessThan(basMin),
          reason: '« An-Nour » sur une seule ligne a $largeur',
        );
      }
      expect(tester.takeException(), isNull);
    });
  });
}
