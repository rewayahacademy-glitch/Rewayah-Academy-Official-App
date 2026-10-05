// COM-RC tour 4, lot G (contre-verification COM-R-2, section 6) : annonces
// et finitions.
//
// - N-5 : le cas « capacite presente, aucune audience » (`aucuneCibleTitre`)
//   est de nouveau teste, sur l'adresse reelle du publieur de l'enseignant ;
// - N-10 : la date d'une notification tient sur une ligne a texte x1 (sans
//   l'annee en cours) ; une pastille de motif longue garde la largeur de
//   son texte ; aucune virgule arabe « ، » collee a un texte francais dans
//   l'interface arabe (date d'un message, nom et fonction).
//
// Chaque test dit sa contre-preuve : ce qui echouait a `022cc31e`.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/communications/lecture_fil_communication.dart';
import 'package:rewayah_academy/core/communications/modeles_communication.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/com_annonces/administration_communications_page.dart';
import 'package:rewayah_academy/features/com_annonces/port_annonces.dart';
import 'package:rewayah_academy/features/com_annonces/publieur_annonce.dart';
import 'package:rewayah_academy/features/com_messages/entete_fil_contexte.dart';
import 'package:rewayah_academy/features/notifications/notifications_page.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import 'admin_banc.dart';

Future<void> _monterNu(
  WidgetTester tester,
  Widget enfant, {
  Size taille = const Size(390, 844),
  AppLocale langue = AppLocale.fr,
}) async {
  fixerTaille(tester, taille);
  await tester.runAsync(() => LocaleSettings.setLocale(langue));
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          locale: langue.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(body: enfant),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    // Les vraies polices : la largeur d'une date se mesure comme a l'ecran.
    await chargerPolicesDuDepot();
    // La bibliotheque arabe est differee : chargee hors du `FakeAsync`.
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });

  group('N-5 : capacite presente, aucune audience', () {
    testWidgets('390 : le publieur de l Administration dit qu aucune '
        'audience n est ouverte, sans publieur', (WidgetTester tester) async {
      // Contre-preuve : a 022cc31e, ce cas n'avait plus aucun test.
      final p = t.com.annonces.publieur;
      await monterAdministration(
        tester,
        taille: const Size(390, 844),
        annonces: annoncesBanc(cibles: const <CibleAnnonce>[]),
      );
      await taper(
        tester,
        find.byKey(AdministrationCommunicationsPage.cleNouvelle),
      );
      expect(find.text(p.aucuneCibleTitre), findsOneWidget);
      expect(find.text(p.aucuneCible), findsOneWidget);
      expect(find.byType(PublieurAnnonce), findsNothing);
      expect(tester.takeException(), isNull);
      await demonter(tester);
    });
  });

  group('N-10 : finitions', () {
    final DateTime maintenant = DateTime(2026, 10, 5, 10);

    testWidgets('390, texte x1 : la date d une notification de l annee '
        'tient sur une ligne, sans l annee', (WidgetTester tester) async {
      // Contre-preuve : a 022cc31e, « 4 oct. 2026 » passait sur deux lignes
      // (« 4 oct. / 2026 »).
      await _monterNu(
        tester,
        SingleChildScrollView(
          child: LigneNotification(
            notification: NotificationTuteur(
              id: 'n1',
              titre: 'Message de la famille de Yasmine, Classe An-Nour',
              date: DateTime(2026, 10, 4, 11),
            ),
            maintenant: maintenant,
            onPress: () {},
          ),
        ),
      );
      final Finder date = find.text('4 oct.');
      expect(date, findsOneWidget);
      expect(find.textContaining('2026'), findsNothing);
      final Text texte = tester.widget<Text>(date);
      final double taille = texte.style!.fontSize!;
      final double interligne = texte.style!.height ?? 1.5;
      // Une seule ligne : moins d'une ligne et demie de haut.
      expect(tester.getSize(date).height, lessThan(taille * interligne * 1.5));
    });

    testWidgets('une notification d une autre annee garde son annee', (
      WidgetTester tester,
    ) async {
      await _monterNu(
        tester,
        SingleChildScrollView(
          child: LigneNotification(
            notification: NotificationTuteur(
              id: 'n2',
              titre: 'Annonce de la direction',
              date: DateTime(2025, 12, 20, 9),
            ),
            maintenant: maintenant,
            onPress: () {},
          ),
        ),
      );
      expect(find.text('20 déc. 2025'), findsOneWidget);
    });

    testWidgets('une pastille de motif longue garde la largeur de son '
        'texte', (WidgetTester tester) async {
      // Contre-preuve : a 022cc31e, passee a la ligne, la pastille prenait
      // toute la largeur offerte (« Contenu sans rapport avec la
      // communauté », file de moderation a 1440).
      const double offerte = 180;
      await _monterNu(
        tester,
        Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(
            width: offerte,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                StatusPill(
                  libelle: t.com.socle.motifs.horsSujet,
                  ton: TonEtat.neutre,
                ),
              ],
            ),
          ),
        ),
      );
      final Finder texte = find.text(t.com.socle.motifs.horsSujet);
      // Le libelle passe bien a la ligne a cette largeur.
      expect(
        tester.getSize(texte).height,
        greaterThan(tester.widget<Text>(texte).style!.fontSize! * 1.5),
      );
      expect(
        tester.getSize(find.byType(StatusPill)).width,
        lessThan(offerte - 1),
      );
    });

    testWidgets('interface arabe : aucune virgule arabe dans la date d un '
        'message ni entre un nom et sa fonction', (WidgetTester tester) async {
      // Contre-preuve : a 022cc31e, « Dimanche 4 octobre، 09:52 » et « Mme
      // Mariam، Enseignante de la Classe An-Nour ».
      await _monterNu(
        tester,
        // Les textes se composent au rendu, dans la langue montee.
        Builder(
          builder: (BuildContext _) => Column(
            children: <Widget>[
              Text(horodatageMessage(DateTime(2026, 10, 4, 9, 52))),
              Text(
                nomParticipant(
                  const Participant(
                    id: 'p1',
                    nomAffiche: 'Mme Mariam',
                    fonction: 'Enseignante de la Classe An-Nour',
                  ),
                ),
              ),
            ],
          ),
        ),
        langue: AppLocale.ar,
      );
      expect(find.textContaining('،'), findsNothing);
      expect(
        find.text('Mme Mariam · Enseignante de la Classe An-Nour'),
        findsOneWidget,
      );
      expect(find.textContaining(' · 09:52'), findsOneWidget);
    });
  });
}
