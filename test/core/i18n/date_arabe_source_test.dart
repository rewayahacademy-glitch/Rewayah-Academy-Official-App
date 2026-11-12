// DATE-ARABE-SOURCE (garde-cap, 12/11/2026) : la date arabe se lit dans
// l'ordre de l'interface, corrigee A LA SOURCE par une seule fonction,
// enTeteArabe (lib/core/i18n/isolat_bidi.dart, la fonction d'A).
//
// Ce que le test prouve :
// (1) enTeteArabe : U+061C en tete en arabe, jamais en francais ; un texte
//     vide reste vide ;
// (2) les formateurs publics commencent par U+061C en arabe et jamais en
//     francais ; un garde lit le code : TOUT appel d'un gabarit de date nu
//     passe par enTeteArabe (les formateurs prives compris), sauf les
//     exceptions nommees ;
// (3) rendu par positions x, avec la contre-preuve (la meme phrase sans la
//     marque se lit a l'envers) : la date courte dans le titre du detail de
//     seance, la date de l'appareil dans le titre d'un fil des Echanges ;
// (4) l'heure arabe : « من 5:00 إلى 5:45 », dans l'ordre.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/port_planning_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/dates_appareil.dart';
import 'package:rewayah_academy/core/i18n/isolat_bidi.dart'
    show enTeteArabe, marqueLettreArabe;
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_horloge/horloge_supabase.dart';
import 'package:rewayah_academy/core/tc_horloge/mon_horloge.dart';
import 'package:rewayah_academy/features/admin_planning/planning_libelles.dart';
import 'package:rewayah_academy/features/admin_regroupements/regroupements_libelles.dart';
import 'package:rewayah_academy/features/compte/donnees_compte.dart';
import 'package:rewayah_academy/features/controleur/echanges_controleur.dart';
import 'package:rewayah_academy/features/controleur/echanges_controleur_page.dart';
import 'package:rewayah_academy/features/foyer/ligne_membre.dart';
import 'package:rewayah_academy/features/journee/journee_page.dart';
import 'package:rewayah_academy/features/suivi_demandes/libelles_suivi_demandes.dart';
import 'package:rewayah_academy/features/suivi_foyer/filtres_historique.dart';

/// Les gabarits arabes de date « nus » : chaque morceau isole, aucune lettre
/// hors des isolats. Tout appel dans lib/ doit passer par enTeteArabe.
const List<String> _gabaritsNus = <String>[
  'historique.dateCourte',
  'historique.dateCourteSansAnnee',
  'historique.dateLongue',
  'commun.dates.jourDate',
  'compte.tuteur.dateLongue',
  'foyer.membre.date',
  'enseignant.journee.date',
  'enseignant.revenus.jourMois',
  'enseignant.classes.quand',
  'admin.pilotage.horaire',
  'admin.groupes.c1.jourDate',
  'suiviDemandes.jourHeure',
  'tuteur.accueil.dateEtDuree',
];

/// Les appels qui n'en ont pas besoin, avec la raison.
const Map<String, String> _exceptions = <String, String>{
  // Le fichier genere : la definition des gabarits, pas un appel.
  'lib/core/i18n/strings': 'fichiers generes',
  // dateLongue (fichier d'A) passe par une variable puis enTeteArabe(texte) ;
  // le test (2) « dateLongue » prouve la marque.
  'lib/features/compte/donnees_compte.dart':
      'enTeteArabe(texte), ligne suivante',
};

final DateTime _instant = DateTime.utc(2026, 10, 22, 12);

void main() {
  // L'arabe est une bibliotheque differee : chargee une fois avant les
  // bascules synchrones.
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
  tearDown(() {
    LocaleSettings.setLocaleSync(AppLocale.fr);
    poserMonHorlogePourTest(null);
  });

  group('(1) enTeteArabe', () {
    test('U+061C en tete en arabe ; rien en francais', () {
      LocaleSettings.setLocaleSync(AppLocale.ar);
      expect(
        enTeteArabe('22 أكتوبر'),
        '$marqueLettreArabe'
        '22 أكتوبر',
      );
      expect(enTeteArabe(''), '');
      LocaleSettings.setLocaleSync(AppLocale.fr);
      expect(enTeteArabe('22 octobre'), '22 octobre');
    });
  });

  group('(2) les formateurs', () {
    final Map<String, String Function()> formateurs =
        <String, String Function()>{
          'dateCourte': () => dateCourte(_instant),
          'dateCompacte (meme annee)': () =>
              dateCompacte(_instant, DateTime(2026, 12, 1)),
          'dateCompacte (autre annee)': () =>
              dateCompacte(_instant, DateTime(2027, 1, 1)),
          'dateLongueHistorique': () => dateLongueHistorique(_instant),
          'dateDeLAppareil': () => dateDeLAppareil(_instant),
          'dateRendue': () => dateRendue(jourIso: 4, dateIso: '2026-10-22'),
          'dateLongue': () => dateLongue(_instant),
          'dateEcheance': () => dateEcheance(_instant),
          'dateLisible (journee)': () => dateLisible(_instant),
          'jourDateDemande': () => jourDateDemande(_instant),
        };

    for (final MapEntry<String, String Function()> f in formateurs.entries) {
      test('${f.key} : U+061C en arabe, jamais en francais', () {
        LocaleSettings.setLocaleSync(AppLocale.ar);
        expect(f.value().startsWith(marqueLettreArabe), isTrue);
        LocaleSettings.setLocaleSync(AppLocale.fr);
        expect(f.value().contains(marqueLettreArabe), isFalse);
      });
    }

    test(
      'garde : tout appel d un gabarit de date nu passe par enTeteArabe',
      () {
        final List<String> fautes = <String>[];
        final List<File> fichiers = Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((File f) => f.path.endsWith('.dart'))
            .toList();
        int appels = 0;
        for (final File f in fichiers) {
          final String chemin = f.path.replaceAll(r'\', '/');
          if (_exceptions.keys.any(chemin.startsWith)) continue;
          final String source = f.readAsStringSync();
          for (final String cle in _gabaritsNus) {
            final RegExp appel = RegExp(r't\.' + RegExp.escape(cle) + r'\(');
            for (final RegExpMatch m in appel.allMatches(source)) {
              appels++;
              final String avant = source.substring(0, m.start).trimRight();
              if (!avant.endsWith('enTeteArabe(')) {
                final int ligne =
                    '\n'.allMatches(source.substring(0, m.start)).length + 1;
                fautes.add('$chemin:$ligne ($cle)');
              }
            }
          }
        }
        expect(appels, greaterThan(20), reason: 'le garde a bien lu le code');
        expect(fautes, isEmpty, reason: fautes.join('\n'));
      },
    );

    test(
      'les gabarits nommes sont bien nus en arabe (sinon le garde ment)',
      () {
        final Map<String, dynamic> ar = jsonDecode(
          File('assets/i18n/ar.i18n.json').readAsStringSync(),
        ) as Map<String, dynamic>;
        final RegExp lettreArabe = RegExp('[؀-ۿ]');
        for (final String cle in _gabaritsNus) {
          Object? v = ar;
          for (final String p in cle.split('.')) {
            v = (v! as Map<String, dynamic>)[p];
          }
          final String gabarit = v! as String;
          final String horsIsolats = gabarit.replaceAll(
            RegExp('\u2068[^\u2069]*\u2069'),
            '',
          );
          expect(
            lettreArabe.hasMatch(horsIsolats),
            isFalse,
            reason: '$cle a une lettre arabe hors isolat : il n est pas nu',
          );
        }
      },
    );
  });

  group('(3) rendu par positions x', () {
    testWidgets('detail de seance : « حصة 22 أكتوبر 2026 » se lit le mot, '
        'le jour, puis l annee ; sans la marque, a l envers', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      // Le titre de DetailSeancePage sans nom de Classe (detail_seance_page,
      // titreSansClasse(date: dateCourte(...))).
      final String date = dateCourte(_instant);
      final String titre = t.historique.seance.titreSansClasse(date: date);
      final String sansMarque = t.historique.seance.titreSansClasse(
        date: date.replaceFirst(marqueLettreArabe, ''),
      );
      await _peindre(tester, <String>[titre, sansMarque]);
      final _Positions avec = _Positions(tester, 0);
      final _Positions contre = _Positions(tester, 1);
      expect(avec.x('حصة'), greaterThan(avec.x('22')));
      expect(avec.x('22'), greaterThan(avec.x('2026')));
      // Contre-preuve : sans la marque, l'annee passe a droite du jour.
      expect(contre.x('22'), lessThan(contre.x('2026')));
    });

    testWidgets('fil des Echanges : « … · الخميس 22 أكتوبر » se lit le jour '
        'de la semaine, puis le numero ; sans la marque, a l envers', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      final FilEchange fil = FilEchange(
        id: 'fil-1',
        missionId: 'mission-1',
        classe: 'Classe A1',
        debutMission: _instant,
        etat: EtatFilEchange.reponseRecue,
        messages: const <MessageEchange>[],
      );
      final String titre = titreFilEchange(fil);
      final String date = dateDeLAppareil(chezMoi(_instant));
      final String sansMarque = t.controleur.echanges.titreFil(
        classe: fil.classe,
        date: date.replaceFirst(marqueLettreArabe, ''),
      );
      expect(titre, contains(date));
      await _peindre(tester, <String>[titre, sansMarque]);
      final String jourSemaine = t.commun.dates.jours[_instant.weekday - 1];
      final _Positions avec = _Positions(tester, 0);
      final _Positions contre = _Positions(tester, 1);
      expect(avec.x(jourSemaine), greaterThan(avec.x('22')));
      expect(contre.x(jourSemaine), lessThan(contre.x('22')));
    });
  });

  group('(4) l heure arabe', () {
    test('« 5:45 » et « 5:00 » en arabe, « 5 h 45 » en francais', () {
      LocaleSettings.setLocaleSync(AppLocale.ar);
      expect(libelleHeureMinute(5, 45), '5:45');
      expect(libelleHeureMinute(5, 0), '5:00');
      LocaleSettings.setLocaleSync(AppLocale.fr);
      expect(libelleHeureMinute(5, 45), '5 h 45');
    });

    testWidgets('planning : « من 5:00 إلى 5:45 » dans l ordre de lecture', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      poserMonHorlogePourTest(
        MonHorloge.lire(const <String, Object?>{
          'maintenant': '2026-11-12T12:00:00Z',
          'moi': <String, Object?>{
            'fuseau': 'Asia/Kolkata',
            'decalage_secondes': 19800,
          },
        }),
      );
      final String horaire = libelleHorairePlanning(
        SeancePlanning(
          id: 's',
          classe: 'Classe A1',
          debut: DateTime.utc(2026, 11, 15, 23, 30),
          dureeMinutes: 45,
          statut: StatutSeance.planifiee,
        ),
      );
      expect(horaire, contains('5:00'));
      expect(horaire, contains('5:45'));
      await _peindre(tester, <String>[horaire]);
      final _Positions p = _Positions(tester, 0);
      expect(p.x('من'), greaterThan(p.x('5:00')));
      expect(p.x('5:00'), greaterThan(p.x('إلى')));
      expect(p.x('إلى'), greaterThan(p.x('5:45')));
    });
  });
}

/// Peint chaque texte sur sa ligne, dans une interface de droite a gauche,
/// assez large pour une seule ligne.
Future<void> _peindre(WidgetTester tester, List<String> textes) async {
  tester.view.physicalSize = const Size(1440, 400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: <Widget>[
          for (final String s in textes)
            Text(s, key: ValueKey<String>(s), softWrap: false),
        ],
      ),
    ),
  );
}

/// Les positions horizontales des morceaux d'une ligne peinte.
class _Positions {
  _Positions(WidgetTester tester, int rang)
    : _p = tester.renderObject<RenderParagraph>(find.byType(RichText).at(rang));

  final RenderParagraph _p;

  double x(String morceau) {
    final String s = _p.text.toPlainText();
    final int i = s.indexOf(morceau);
    expect(i, isNonNegative, reason: '« $morceau » dans « $s »');
    return _p
        .getBoxesForSelection(
          TextSelection(baseOffset: i, extentOffset: i + morceau.length),
        )
        .first
        .left;
  }
}
