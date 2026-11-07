// « Recevoir mes paiements », refondu par le lot FINANCE-ENSEIGNANT
// (06/11/2026) : l'enseignant saisit ses coordonnees pour la paie Wise.
// Les champs viennent du serveur ; la relecture est masquee sauf les 4
// derniers caracteres ; retirer se confirme ; « Versements recus » montre les
// versements notes par la direction, etat vide compris ; la rubrique de Compte
// n'apparait que si le port repond (capacite, jamais le role) ; cinq etats ;
// 320 a texte x2, 1440 sombre, RTL. Captures 390 et 1440, FR et AR, avec
// CAPTURE_DIR seulement.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_coordonnees_versement.dart';
import 'package:rewayah_academy/core/capacites/port_versements_paie.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/paiements_recus/feuille_coordonnees.dart';
import 'package:rewayah_academy/features/paiements_recus/recevoir_paiements_page.dart';
import 'package:rewayah_academy/features/paiements_recus/rubrique_recevoir_paiements.dart';

import '../../capture/outil_capture.dart';
import '../../router/support_routeur.dart' show sessionActive;
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';
import '../../support/mots_coupes.dart';
import 'faux_versement.dart';

class _EnEchec extends FauxCoordonnees {
  _EnEchec({this.jamais = false});

  final bool jamais;

  @override
  Future<MesCoordonneesVersement> mesCoordonnees() => jamais
      ? Completer<MesCoordonneesVersement>().future
      : Future<MesCoordonneesVersement>.error(StateError('reseau'));
}

List<Override> _surcharges(
  PortCoordonneesVersement port,
  PortVersementsPaie versements, {
  bool horsLigne = false,
}) => <Override>[
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(sessionActive(AppRole.teacher)),
  ),
  horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(horsLigne)),
  portCoordonneesVersementProvider.overrideWithValue(port),
  portVersementsPaieProvider.overrideWithValue(versements),
];

Future<void> _monter(
  WidgetTester tester,
  Widget page,
  PortCoordonneesVersement port, {
  PortVersementsPaie? versements,
  bool horsLigne = false,
  Size taille = const Size(390, 2400),
  double densite = 1,
  double texte = 1,
  ThemeMode theme = ThemeMode.light,
  TextDirection sens = TextDirection.ltr,
}) async {
  fixerVueCapture(tester, taille, densite);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    hoteCapture(
      Directionality(textDirection: sens, child: page),
      surcharges: _surcharges(
        port,
        versements ?? FauxVersements(),
        horsLigne: horsLigne,
      ),
      echelleTexte: texte,
      themeMode: theme,
    ),
  );
  await stabiliser(tester);
}

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await stabiliser(tester);
}

void main() {
  final r = t.comptable.beneficiaires.recevoir;
  final w = r.wise;

  group('Recevoir mes paiements (Wise)', () {
    testWidgets(
      'aucune coordonnee : notice, « Renseigner », versements vides',
      (WidgetTester tester) async {
        await _monter(tester, const RecevoirPaiementsPage(), FauxCoordonnees());
        expect(find.byKey(RecevoirPaiementsPage.noticeKey), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(RecevoirPaiementsPage.actionKey),
            matching: find.text(w.renseigner),
          ),
          findsOneWidget,
        );
        expect(find.text(w.versementsVide), findsOneWidget);
        expect(find.byKey(RecevoirPaiementsPage.retirerKey), findsNothing);
        verifierUnSeulBoutonPlein(tester);
      },
    );

    testWidgets('je saisis les champs requis ; un champ vide ou une virgule '
        'est signale avant l envoi', (WidgetTester tester) async {
      final FauxCoordonnees port = FauxCoordonnees();
      await _monter(tester, const RecevoirPaiementsPage(), port);
      await _toucher(tester, find.byKey(RecevoirPaiementsPage.actionKey));
      // Les champs du modele pour la Guinee, ni plus ni moins : pas d'Etat
      // (Etats-Unis et Canada seulement), pas d'IBAN a part ; le pays est
      // preremplie depuis le profil et se lit par son nom.
      for (final ChampDemande d in champsUsd) {
        expect(
          find.byKey(FeuilleCoordonnees.cleChamp(d.champ)),
          d.demandePour('GN') ? findsOneWidget : findsNothing,
        );
      }
      expect(
        find.byKey(FeuilleCoordonnees.cleChamp(ChampVersement.iban)),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(
            FeuilleCoordonnees.cleChamp(ChampVersement.adressePays),
          ),
          matching: find.text('Guinée'),
        ),
        findsOneWidget,
      );
      await _toucher(tester, find.byKey(FeuilleCoordonnees.cleEnregistrer));
      expect(port.envois, isEmpty);
      expect(find.text(w.champRequis), findsWidgets);

      Future<void> saisir(ChampVersement c, String v) async {
        final Finder champ = find.descendant(
          of: find.byKey(FeuilleCoordonnees.cleChamp(c)),
          matching: find.byType(EditableText),
        );
        await tester.ensureVisible(champ);
        await tester.enterText(champ, v);
        await tester.pump();
      }

      await saisir(ChampVersement.titulaire, 'Diallo, Mamadou');
      for (final ChampVersement c in champsRequisGuinee) {
        if (c == ChampVersement.titulaire || c == ChampVersement.adressePays) {
          continue;
        }
        await saisir(c, coordonneesDemo[c]!);
      }
      await _toucher(tester, find.byKey(FeuilleCoordonnees.cleEnregistrer));
      expect(port.envois, isEmpty);
      expect(find.text(w.caracteresInterdits), findsOneWidget);

      await saisir(ChampVersement.titulaire, 'Mamadou Diallo');
      await _toucher(tester, find.byKey(FeuilleCoordonnees.cleEnregistrer));
      expect(port.envois, hasLength(1));
      expect(port.envois.single[ChampVersement.adressePays], 'GN');
      // La relecture masque les numeros sauf les 4 derniers caracteres.
      expect(find.text(w.enregistrees), findsOneWidget);
      expect(find.text('••••8901'), findsOneWidget);
      expect(find.text('0012345678901'), findsNothing);
      expect(find.byKey(RecevoirPaiementsPage.noticeKey), findsNothing);
    });

    testWidgets('compte d un proche : lien et accord exiges, puis en attente '
        'de validation', (WidgetTester tester) async {
      final FauxCoordonnees port = FauxCoordonnees();
      await _monter(tester, const RecevoirPaiementsPage(), port);
      await _toucher(tester, find.byKey(RecevoirPaiementsPage.actionKey));
      for (final ChampVersement c in champsRequisGuinee) {
        if (c == ChampVersement.adressePays) continue;
        final Finder champ = find.descendant(
          of: find.byKey(FeuilleCoordonnees.cleChamp(c)),
          matching: find.byType(EditableText),
        );
        await tester.ensureVisible(champ);
        await tester.enterText(
          champ,
          c == ChampVersement.titulaire ? 'Moussa Diallo' : coordonneesDemo[c]!,
        );
        await tester.pump();
      }
      await _toucher(
        tester,
        find.byKey(FeuilleCoordonnees.cleAMonNom(oui: false)),
      );
      await _toucher(tester, find.byKey(FeuilleCoordonnees.cleEnregistrer));
      expect(port.envois, isEmpty);
      expect(find.text(w.lienRequis), findsOneWidget);
      expect(find.text(w.autorisationRequise), findsOneWidget);
      // L'accord nomme le titulaire saisi.
      expect(
        find.text(w.autorisation(titulaire: 'Moussa Diallo')),
        findsOneWidget,
      );
      await _toucher(
        tester,
        find.byKey(FeuilleCoordonnees.cleLien(LienTitulaire.parent)),
      );
      await _toucher(tester, find.byKey(FeuilleCoordonnees.cleAccord));
      await _toucher(tester, find.byKey(FeuilleCoordonnees.cleEnregistrer));
      expect(port.accords.single.aMonNom, isFalse);
      expect(port.accords.single.lien, LienTitulaire.parent);
      expect(port.accords.single.autorisation, isTrue);
      expect(
        tester
            .widget<Text>(find.byKey(RecevoirPaiementsPage.validationKey))
            .data,
        w.enAttenteValidation,
      );
      expect(find.text(w.lien.parent), findsOneWidget);
    });

    testWidgets('pays du compte ou Wise ne verse pas : refuse, le message le '
        'dit sur le pays', (WidgetTester tester) async {
      final FauxCoordonnees port = FauxCoordonnees(paysRefuses: <String>{'GN'});
      await _monter(tester, const RecevoirPaiementsPage(), port);
      await _toucher(tester, find.byKey(RecevoirPaiementsPage.actionKey));
      for (final ChampVersement c in champsRequisGuinee) {
        if (c == ChampVersement.adressePays) continue;
        final Finder champ = find.descendant(
          of: find.byKey(FeuilleCoordonnees.cleChamp(c)),
          matching: find.byType(EditableText),
        );
        await tester.ensureVisible(champ);
        await tester.enterText(champ, coordonneesDemo[c]!);
        await tester.pump();
      }
      await _toucher(tester, find.byKey(FeuilleCoordonnees.cleEnregistrer));
      expect(port.envois, isEmpty);
      expect(find.text(w.paysIndisponible(pays: 'Guinée')), findsOneWidget);
    });

    testWidgets('retirer se confirme, puis la notice revient', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const RecevoirPaiementsPage(),
        FauxCoordonnees(depart: Map.of(coordonneesDemo)),
      );
      expect(find.byKey(RecevoirPaiementsPage.noticeKey), findsNothing);
      await _toucher(tester, find.byKey(RecevoirPaiementsPage.retirerKey));
      expect(find.text(w.retirerQuestion), findsOneWidget);
      await _toucher(tester, find.text(w.retirer).last);
      expect(find.text(w.retirees), findsOneWidget);
      expect(find.byKey(RecevoirPaiementsPage.noticeKey), findsOneWidget);
    });

    testWidgets('versements recus : montant, mois, moyen ; annule dit', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const RecevoirPaiementsPage(),
        FauxCoordonnees(depart: Map.of(coordonneesDemo)),
        versements: FauxVersements(
          depart: <VersementPaie>[versementDemo(), versementDemo(annule: true)],
        ),
      );
      expect(
        find.byKey(const ValueKey<String>('recevoir-versement-v-1')),
        findsOneWidget,
      );
      expect(find.text(w.versementAnnule), findsOneWidget);
    });

    testWidgets('chargement, erreur, hors ligne, source absente', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const RecevoirPaiementsPage(),
        _EnEchec(jamais: true),
      );
      expect(find.byType(Skeleton), findsWidgets);
      await _monter(tester, const RecevoirPaiementsPage(), _EnEchec());
      expect(find.byType(EtatSysteme), findsOneWidget);
      await _monter(
        tester,
        const RecevoirPaiementsPage(),
        _EnEchec(),
        horsLigne: true,
      );
      expect(find.byType(EtatSysteme), findsOneWidget);
      await _monter(
        tester,
        const RecevoirPaiementsPage(),
        const CoordonneesVersementIndisponibles(),
      );
      expect(find.byType(EtatSysteme), findsOneWidget);
      expect(find.byKey(RecevoirPaiementsPage.actionKey), findsNothing);
    });
  });

  group('Rubrique de Compte et du Profil (capacite du port)', () {
    Widget page() => const Scaffold(
      body: SingleChildScrollView(child: RubriqueRecevoirPaiements()),
    );

    testWidgets('source absente : rien, aucun lien mort', (
      WidgetTester tester,
    ) async {
      await _monter(tester, page(), const CoordonneesVersementIndisponibles());
      expect(find.byKey(RubriqueRecevoirPaiements.ligneKey), findsNothing);
    });

    testWidgets('source presente : la ligne, et la notice quand il manque '
        'les coordonnees', (WidgetTester tester) async {
      await _monter(tester, page(), FauxCoordonnees());
      expect(find.byKey(RubriqueRecevoirPaiements.ligneKey), findsOneWidget);
      expect(find.byKey(RubriqueRecevoirPaiements.noticeKey), findsOneWidget);
      await _monter(
        tester,
        page(),
        FauxCoordonnees(depart: Map.of(coordonneesDemo)),
      );
      expect(find.byKey(RubriqueRecevoirPaiements.ligneKey), findsOneWidget);
      expect(find.byKey(RubriqueRecevoirPaiements.noticeKey), findsNothing);
    });
  });

  group('Garde d interface', () {
    setUpAll(chargerPolicesDuDepot);

    for (final ThemeMode theme in <ThemeMode>[
      ThemeMode.light,
      ThemeMode.dark,
    ]) {
      testWidgets('320 a texte x2, ${theme.name}', (WidgetTester tester) async {
        await _monter(
          tester,
          const RecevoirPaiementsPage(),
          FauxCoordonnees(depart: Map.of(coordonneesDemo)),
          versements: FauxVersements(depart: <VersementPaie>[versementDemo()]),
          taille: const Size(320, 4000),
          texte: 2,
          theme: theme,
        );
        expect(tester.takeException(), isNull);
        expect(motsCoupes(tester, find.byType(RecevoirPaiementsPage)), isEmpty);
        verifierUnSeulBoutonPlein(tester);
        expect(
          verifierAucuneCarteCollee(
            tester,
            estCarte: (Widget w) => w is AppCard,
          ),
          greaterThan(0),
        );
      });
    }

    testWidgets('1440 sombre et RTL', (WidgetTester tester) async {
      await _monter(
        tester,
        const RecevoirPaiementsPage(),
        FauxCoordonnees(depart: Map.of(coordonneesDemo)),
        taille: const Size(1440, 1200),
        theme: ThemeMode.dark,
      );
      expect(tester.takeException(), isNull);
      await _monter(
        tester,
        const RecevoirPaiementsPage(),
        FauxCoordonnees(),
        sens: TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Captures (CAPTURE_DIR seulement)', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final (String, Size, double) vue in <(String, Size, double)>[
        ('390', const Size(390, 1400), 2),
        ('1440', const Size(1440, 1100), 1),
      ]) {
        for (final bool rempli in <bool>[false, true]) {
          final String nom =
              'recevoir_${rempli ? 'rempli' : 'vide'}_${vue.$1}_${langue.languageCode}';
          testWidgets(nom, (WidgetTester tester) async {
            await tester.runAsync(() => LocaleSettings.setLocale(langue));
            await _monter(
              tester,
              const RecevoirPaiementsPage(),
              FauxCoordonnees(depart: rempli ? Map.of(coordonneesDemo) : null),
              versements: FauxVersements(
                depart: rempli ? <VersementPaie>[versementDemo()] : null,
              ),
              taille: vue.$2,
              densite: vue.$3,
              sens: langue == AppLocale.ar
                  ? TextDirection.rtl
                  : TextDirection.ltr,
            );
            debugPrint('PNG ${await capturer(tester, nom)}');
          });
        }
        final String nomFeuille =
            'recevoir_feuille_${vue.$1}_${langue.languageCode}';
        testWidgets(nomFeuille, (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await _monter(
            tester,
            const RecevoirPaiementsPage(),
            FauxCoordonnees(),
            taille: vue.$2,
            densite: vue.$3,
            sens: langue == AppLocale.ar
                ? TextDirection.rtl
                : TextDirection.ltr,
          );
          await _toucher(tester, find.byKey(RecevoirPaiementsPage.actionKey));
          // Le compte d'un proche : la question, le lien et l'accord visibles.
          await _toucher(
            tester,
            find.byKey(FeuilleCoordonnees.cleAMonNom(oui: false)),
          );
          debugPrint('PNG ${await capturer(tester, nomFeuille)}');
        });
      }
    }
  });
}
