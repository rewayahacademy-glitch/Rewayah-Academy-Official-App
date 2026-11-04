// Textes juridiques (lot « levee des blocages », 18/10/2026) : les six textes
// se lisent sans erreur a 320 et 1440, texte 100 et 200 %, en francais et en
// arabe (sens droite a gauche), avec leur version et leur date ; rien n'est
// invente (un champ non donne reste un repere), aucun montant, aucun mot interdit.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/conformite/representant_ue.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/protection_enfants/responsable_protection.dart';
import 'package:rewayah_academy/features/dossier/politique_controle.dart'
    show SectionPolitique, textePlatBloc;
import 'package:rewayah_academy/features/juridique/juridique_pages.dart';
import 'package:rewayah_academy/features/juridique/textes_juridiques.dart';

import '../../capture/outil_capture.dart';
import '../../support/aucun_mot_coupe.dart';

String _tout(TexteJuridique x) =>
    sectionsJuridiques(x)
        .expand((SectionPolitique s) => <String>[s.titre, ...s.blocs])
        .join('\n');

class _PortResponsable implements PortResponsableProtection {
  _PortResponsable(this.valeur, {this.erreur});

  final ResponsableProtection valeur;
  final Exception? erreur;

  @override
  Future<ResponsableProtection> lire() async {
    if (erreur != null) throw erreur!;
    return valeur;
  }
}

class _PortRepresentant implements PortRepresentantUe {
  _PortRepresentant(this.nom, {this.erreur});

  final String nom;
  final Exception? erreur;

  @override
  Future<String> lire() async {
    if (erreur != null) throw erreur!;
    return nom;
  }
}

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('Le contenu', () {
    for (final AppLocale langue in AppLocale.values) {
      test(
        '${langue.languageCode} : six textes, ni montant ni mot interdit',
        () {
          LocaleSettings.setLocaleSync(langue);
          final RegExp interdit = RegExp(
            r'garanti|certifi|100\s?%|\$|\bgroupes?\b|ضمان|مضمون',
          );
          for (final TexteJuridique x in TexteJuridique.values) {
            final String texte = _tout(x);
            expect(x.titre, isNotEmpty);
            expect(sectionsJuridiques(x), isNotEmpty);
            expect(
              interdit.hasMatch(texte),
              isFalse,
              reason: '${x.slug} : ${interdit.firstMatch(texte)?.group(0)}',
            );
            // Aucun chiffre de prix : pas de montant ecrit.
            expect(
              RegExp(r'\d+[,.]\d{2}').hasMatch(texte),
              isFalse,
              reason: x.slug,
            );
          }
        },
      );
    }

    test('FN-115 : remboursement sauf seances suivies, litige, pas paye = '
        'ni seances ni ressources, en fr et en ar', () {
      for (final AppLocale langue in AppLocale.values) {
        LocaleSettings.setLocaleSync(langue);
        final List<SectionPolitique> annulation = sectionsJuridiques(
          TexteJuridique.annulation,
          renseignes: const <ChampJuridique, String>{},
        );
        final String conditions = sectionsJuridiques(
          TexteJuridique.conditions,
          renseignes: const <ChampJuridique, String>{},
        ).expand((SectionPolitique s) => s.blocs).join('\n');
        // La contestation aupres de la banque a sa section, avant
        // « Faire une demande », qui reste la derniere.
        final List<String> titres = <String>[
          for (final SectionPolitique s in annulation) s.titre,
        ];
        expect(
          titres.indexOf(t.juridique.annulation.litige.titre),
          titres.length - 2,
          reason: langue.languageCode,
        );
        expect(
          conditions,
          contains(t.juridique.conditions.s4.blocs[4]),
          reason: langue.languageCode,
        );
      }
      LocaleSettings.setLocaleSync(AppLocale.fr);
      expect(
        t.juridique.annulation.litige.blocs.join(' '),
        allOf(contains('suspendu'), contains('frais'), contains('foyer')),
      );
      expect(t.juridique.annulation.s1.blocs[1], contains('sauf les séances'));
      expect(t.juridique.annulation.s1.blocs[1], isNot(contains('en entier')));
      expect(
        t.juridique.conditions.s4.blocs[4],
        allOf(contains('ressources'), contains('payer')),
      );
    });

    test('annulation et conditions : aucun delai ni date de paiement en dur', () {
      for (final AppLocale langue in AppLocale.values) {
        LocaleSettings.setLocaleSync(langue);
        for (final TexteJuridique x in <TexteJuridique>[
          TexteJuridique.annulation,
          TexteJuridique.conditions,
        ]) {
          // Les ages des formules (programme) sont permis. Aucun autre
          // chiffre dans les blocs : ni delai, ni jour du mois.
          final String blocs =
              sectionsJuridiques(
                    x,
                    // Sans les valeurs du directeur (qui portent des delais) :
                    // seuls les textes de base sont controles.
                    renseignes: const <ChampJuridique, String>{},
                  )
                  .expand((SectionPolitique s) => s.blocs)
                  .join('\n')
                  .replaceAll(RegExp(r'[0-9٠-٩]+ à [0-9٠-٩]+ ans'), '')
                  .replaceAll(RegExp(r'من [0-9٠-٩]+ إلى [0-9٠-٩]+ سنة'), '')
                  .replaceAll(RegExp(r'[0-9٠-٩]+ (ans|سنة)'), '');
          expect(
            RegExp(r'[0-9٠-٩]').hasMatch(blocs),
            isFalse,
            reason: '${langue.languageCode} ${x.slug}',
          );
        }
      }
    });

    test('un champ non donne reste un repere, liste une fois', () {
      final String enfants = sectionsJuridiques(
        TexteJuridique.enfants,
        renseignes: const <ChampJuridique, String>{},
      ).expand((SectionPolitique s) => s.blocs).map(textePlatBloc).join('\n');
      expect(enfants, contains('[à compléter par la direction'));
      expect(enfants, contains('responsable de la protection des enfants'));
      expect(
        CoordonneesJuridiques.aCompleter(const <ChampJuridique, String>{}),
        ChampJuridique.values,
      );
    });

    test('les sept valeurs du directeur sont donnees, en fr et en ar', () {
      for (final AppLocale langue in AppLocale.values) {
        LocaleSettings.setLocaleSync(langue);
        expect(CoordonneesJuridiques.aCompleter(), isEmpty);
        for (final TexteJuridique x in TexteJuridique.values) {
          final String texte = _tout(x);
          expect(
            texte,
            isNot(contains('à compléter')),
            reason: '${langue.languageCode} ${x.slug}',
          );
          expect(
            texte,
            isNot(contains('تستكمله')),
            reason: '${langue.languageCode} ${x.slug}',
          );
        }
        expect(
          _tout(TexteJuridique.enfants),
          contains('support@rewayahacademy.com'),
        );
      }
    });

    test('un champ renseigne remplace son repere', () {
      final String texte = sectionsJuridiques(
        TexteJuridique.mentions,
        renseignes: const <ChampJuridique, String>{
          ChampJuridique.hebergeur: 'Hebergeur Exemple',
        },
      ).expand((SectionPolitique s) => s.blocs).map(textePlatBloc).join('\n');
      expect(texte, contains('Hebergeur Exemple'));
      expect(texte, isNot(contains('hébergeur légal et ses coordonnées]')));
    });

    test('la societe vient de JUR-APP-1 et le contact de la constante', () {
      final String m = _tout(TexteJuridique.mentions);
      expect(m, contains('16624644'));
      expect(m, contains('support@rewayahacademy.com'));
    });

    test('adresses et version', () {
      expect(TexteJuridique.depuisSlug('cookies'), TexteJuridique.cookies);
      expect(TexteJuridique.depuisSlug('inconnu'), isNull);
      expect(
        TexteJuridique.annulation.chemin,
        '/juridique/annulation-remboursement',
      );
      expect(ligneVersionJuridique(), contains(VersionsJuridiques.version));
      expect(ligneVersionJuridique(), contains('2 novembre 2026'));
    });
  });

  group('Le responsable de la protection des enfants', () {
    const String defaut =
        'Rewayah Academy, joignable à support@rewayahacademy.com.';

    // Les adresses portent des points de coupure invisibles : on les retire.
    Finder phrase(String texte) => find.byWidgetPredicate(
      (Widget w) =>
          w is RichText &&
          w.text
              .toPlainText()
              .replaceAll(RegExp('[\u200b\u2060\u00ad\u200c\u200d]'), '')
              .contains(texte),
    );

    Future<void> ouvrir(
      WidgetTester tester,
      PortResponsableProtection port,
    ) async {
      LocaleSettings.setLocaleSync(AppLocale.fr);
      fixerVueCapture(tester, const Size(390, 1600), 1);
      await tester.pumpWidget(
        hoteCapture(
          const TexteJuridiquePage(texte: TexteJuridique.enfants),
          surcharges: <Override>[
            portResponsableProtectionProvider.overrideWithValue(port),
          ],
        ),
      );
      await stabiliser(tester);
      await tester.drag(
        find.byType(Scrollable).first,
        const Offset(0, -100000),
      );
      await stabiliser(tester);
      expect(tester.takeException(), isNull);
      expect(find.textContaining('à compléter'), findsNothing);
    }

    testWidgets('reglage rempli : le nom et le courriel de la direction', (
      WidgetTester tester,
    ) async {
      await ouvrir(
        tester,
        _PortResponsable(
          const ResponsableProtection(
            nom: 'Sayyida Amina',
            courriel: 'amina@exemple.org',
          ),
        ),
      );
      expect(
        phrase('Sayyida Amina, joignable à amina@exemple.org.'),
        findsOneWidget,
      );
    });

    testWidgets('reglage vide : le nom de l\'academie et le contact existant', (
      WidgetTester tester,
    ) async {
      await ouvrir(tester, _PortResponsable(ResponsableProtection.aucun));
      expect(phrase(defaut), findsWidgets);
    });

    testWidgets('lecture en erreur : le defaut, sans ecran d\'erreur', (
      WidgetTester tester,
    ) async {
      await ouvrir(
        tester,
        _PortResponsable(
          ResponsableProtection.aucun,
          erreur: Exception('hors ligne'),
        ),
      );
      expect(phrase(defaut), findsWidgets);
    });

    testWidgets('non connecte (lecture refusee) : le defaut', (
      WidgetTester tester,
    ) async {
      await ouvrir(
        tester,
        _PortResponsable(
          ResponsableProtection.aucun,
          erreur: Exception('JWT absent : compte non connecte'),
        ),
      );
      expect(phrase(defaut), findsWidgets);
    });

    test('sans lecture : le defaut, en fr et en ar', () {
      for (final AppLocale langue in AppLocale.values) {
        LocaleSettings.setLocaleSync(langue);
        final String texte = _tout(TexteJuridique.enfants);
        expect(texte, contains('support@rewayahacademy.com'));
        expect(texte, contains(t.juridique.valeurs.responsableDefaut));
      }
    });
  });

  group('Le representant dans l\'Union europeenne', () {
    String confidentialite({String? nom}) => sectionsJuridiques(
      TexteJuridique.confidentialite,
      representantUe: nom,
    ).first.blocs.join('\n');

    test('vide ou absent : Rewayah Academy, en fr et en ar', () {
      for (final AppLocale langue in AppLocale.values) {
        LocaleSettings.setLocaleSync(langue);
        for (final String? nom in <String?>[null, '', '   ']) {
          final String texte = confidentialite(nom: nom);
          expect(
            texte,
            contains(
              t.juridique.confidentialite.s1.representant(
                nom: t.juridique.valeurs.representantUeDefaut,
              ),
            ),
          );
          expect(texte, isNot(contains('pas encore')));
          expect(texte, isNot(contains('{')));
        }
      }
    });

    test('un nom saisi remplace le defaut, en fr et en ar', () {
      for (final AppLocale langue in AppLocale.values) {
        LocaleSettings.setLocaleSync(langue);
        final String texte = confidentialite(nom: '  Cabinet Exemple ');
        expect(texte, contains('Cabinet Exemple'));
        expect(
          texte,
          isNot(
            contains(
              t.juridique.confidentialite.s1.representant(
                nom: t.juridique.valeurs.representantUeDefaut,
              ),
            ),
          ),
        );
      }
      LocaleSettings.setLocaleSync(AppLocale.fr);
      expect(
        confidentialite(nom: 'Cabinet Exemple'),
        contains(
          'Représentant dans l\'Union européenne\u00a0: Cabinet Exemple.',
        ),
      );
    });

    Future<void> ouvrir(WidgetTester tester, PortRepresentantUe port) async {
      LocaleSettings.setLocaleSync(AppLocale.fr);
      fixerVueCapture(tester, const Size(390, 1600), 1);
      await tester.pumpWidget(
        hoteCapture(
          const TexteJuridiquePage(texte: TexteJuridique.confidentialite),
          surcharges: <Override>[
            portRepresentantUeProvider.overrideWithValue(port),
            portResponsableProtectionProvider.overrideWithValue(
              _PortResponsable(ResponsableProtection.aucun),
            ),
          ],
        ),
      );
      await stabiliser(tester);
      expect(tester.takeException(), isNull);
    }

    testWidgets('la page affiche le nom regle par la direction', (
      WidgetTester tester,
    ) async {
      await ouvrir(tester, _PortRepresentant('Cabinet Exemple'));
      expect(
        find.textContaining('Union européenne\u00a0: Cabinet Exemple.'),
        findsOneWidget,
      );
    });

    testWidgets('lecture en erreur : Rewayah Academy, sans ecran d\'erreur', (
      WidgetTester tester,
    ) async {
      await ouvrir(
        tester,
        _PortRepresentant('', erreur: Exception('hors ligne')),
      );
      expect(
        find.textContaining('Union européenne\u00a0: Rewayah Academy.'),
        findsOneWidget,
      );
    });
  });

  group('Le rendu', () {
    for (final (AppLocale langue, Size taille, double echelle)
        in <(AppLocale, Size, double)>[
          (AppLocale.fr, const Size(320, 690), 1),
          (AppLocale.fr, const Size(320, 690), 2),
          (AppLocale.fr, const Size(1440, 900), 1),
          (AppLocale.ar, const Size(320, 690), 1),
          (AppLocale.ar, const Size(320, 690), 2),
          (AppLocale.ar, const Size(1440, 900), 1),
        ]) {
      testWidgets('${langue.languageCode} ${taille.width.toInt()} x$echelle : '
          'les six textes et la liste, sans erreur ni mot coupe', (
        WidgetTester tester,
      ) async {
        LocaleSettings.setLocaleSync(langue);
        fixerVueCapture(tester, taille, 1);
        final List<Widget> pages = <Widget>[
          const JuridiquePage(),
          for (final TexteJuridique x in TexteJuridique.values)
            TexteJuridiquePage(texte: x),
        ];
        for (final Widget page in pages) {
          await tester.pumpWidget(hoteCapture(page, echelleTexte: echelle));
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
          expect(
            find.textContaining(VersionsJuridiques.version),
            findsOneWidget,
          );
          final TextDirection sens = Directionality.of(
            tester.element(find.byType(Scaffold).first),
          );
          expect(
            sens,
            langue == AppLocale.ar ? TextDirection.rtl : TextDirection.ltr,
          );
          // Un mot compose peut passer a la ligne apres son trait d'union
          // (« écrivez-nous ») ; aucune autre coupure.
          expect(
            motsCoupes(tester, find.byWidget(page), traitDUnionPermis: true),
            isEmpty,
            reason: 'Un mot coupe ou tronque',
          );
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -100000),
          );
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
        }
      });
    }

    testWidgets('la liste montre les six textes', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 1600), 1);
      await tester.pumpWidget(hoteCapture(const JuridiquePage()));
      await stabiliser(tester);
      for (final TexteJuridique x in TexteJuridique.values) {
        expect(find.text(x.titre), findsOneWidget);
      }
    });
  });
}
