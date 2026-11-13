// SOCLE-PROGRAMME (lot 1 de la charte, 12/11/2026), sur le hub `ma_progression`
// (13/11/2026) : l'etape de l'eleve, lue par `etape_eleve_lecture` DEDANS, rendue
// par le meme appel que les sourates et le reglage. Lecture de la reponse, puis
// les ecrans touches a travers le VRAI routeur : contenu (etape, matieres,
// date d'entree, duree prevue, date limite de l'etape, horizon du niveau,
// chemin), dates retenues par le serveur pour l'enfant de 6 a 9 ans (et la
// regle d'avant, quand le serveur ne le dit pas), attente de l'entretien de
// lecture, et les etats : chargement, contenu, erreur, hors ligne.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_progression_famille.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/suivi/ma_progression.dart';
import 'package:rewayah_academy/core/suivi/port_suivi_pedagogique.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/suivi_eleve/suivi_eleve_page.dart';
import 'package:rewayah_academy/features/suivi_foyer/suivi_foyer_page.dart';

import '../../fixtures/tuteur/foyers.dart';
import '../../router/support_routeur.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';
import '../historique/support_historique.dart';

/// La reponse de `ma_progression` pour un eleve a l'etape 2. [masquee] : telle
/// que le serveur la rend a l'enfant de 6 a 9 ans qui lit avec son propre
/// compte (aucune date, aucun nombre de semaines). [voit] : `eleve_voit_dates`.
Map<String, Object?> _reponse({bool masquee = false, bool voit = true}) {
  final bool dateLimite = !masquee;
  int? n(int v) => masquee ? null : v;
  Map<String, Object?> etape(
    int ordre,
    String nom,
    int prevue,
    int limite,
    String statut,
    List<Object?> objectifs,
  ) => <String, Object?>{
    'ordre': ordre,
    'nom': nom,
    'statut': statut,
    'atteinte_le': null,
    'objectifs': objectifs,
    'duree_prevue_semaines': n(prevue),
    'date_limite_semaines': n(limite),
  };
  return <String, Object?>{
    'eleve_voit_dates': voit,
    'etape': <String, Object?>{
      'code': 'BASES-2',
      'ordre': 2,
      'nom': 'Lire avec les voyelles',
      'cycle': 'Les bases',
      'objectifs': <Object?>['Lit le tanwin', 'Lit la chadda'],
      'matiere_principale': 'Le livre de lecture de Rewayah : les voyelles',
      'matiere_secondaire': 'Al-Fatiha dès la première semaine',
      'duree_prevue_semaines': n(11),
      'date_limite_semaines': n(14),
      'entree_le': dateLimite ? '2026-10-01' : null,
      'date_limite': dateLimite ? '2027-01-07' : null,
      'semaines_ecoulees': dateLimite ? 6 : null,
      'rythme': dateLimite ? 'dans_les_temps' : null,
      'page_reprise': 12,
    },
    'niveau': <String, Object?>{
      'code': 'bases',
      'nom': 'Les bases',
      'cohorte': 'enfant_10_13',
      'duree_prevue_semaines': n(28),
      'date_limite_semaines': n(36),
      'entree_le': dateLimite ? '2026-09-01' : null,
      'horizon': dateLimite ? '2027-05-06' : null,
      'date_limite_visible': dateLimite,
    },
    'etapes_du_cycle': <Object?>[
      etape(1, 'Les lettres', 6, 8, 'franchie', <Object?>[
        'Distingue les lettres qui se ressemblent',
      ]),
      etape(2, 'Lire avec les voyelles', 11, 14, 'en_cours', <Object?>[
        'Lit le tanwin',
      ]),
      etape(3, 'Lire dans le Coran', 6, 8, 'a_venir', <Object?>[]),
      etape(
        4,
        "Les sourates courtes, d'Al-Masad à Az-Zalzalah",
        5,
        6,
        'a_venir',
        <Object?>[],
      ),
    ],
    'sourates': <String, Object?>{'sourates_validees': 3, 'sourates_total': 17},
    'reglage': null,
  };
}

/// La reponse d'un serveur d'avant le socle : les dates sont rendues, mais
/// `eleve_voit_dates` manque.
Map<String, Object?> _sansDrapeau() => _reponse()..remove('eleve_voit_dates');

/// La reponse de `ma_progression` pour un eleve en classe qui attend
/// l'entretien de lecture : aucune etape, les sourates restent rendues.
Map<String, Object?> _attente() => <String, Object?>{
  'etape': null,
  'etapes_du_cycle': <Object?>[],
  'sourates': <String, Object?>{'sourates_validees': 0, 'sourates_total': 17},
  'reglage': null,
  'attente': 'entretien_de_lecture',
};

/// Ce qui ne doit jamais s'afficher quand l'eleve ne voit pas ses dates.
void _aucuneDate(WidgetTester tester) {
  final s = t.suiviPedagogique;
  expect(find.text(s.aFinirAvant), findsNothing);
  expect(find.text(s.horizonNiveau(niveau: 'Les bases')), findsNothing);
  expect(find.text(s.rythme), findsNothing);
  expect(find.text(s.dureePrevue), findsNothing);
  expect(find.text(s.depuis), findsNothing);
  expect(find.textContaining('semaines'), findsNothing);
  // Aucune date, quel que soit l'an : ni annee a quatre chiffres, ni mois.
  expect(find.textContaining(RegExp(r'\b(19|20)\d\d\b')), findsNothing);
  for (final String mois in t.commun.dates.mois) {
    expect(
      find.textContaining(RegExp('\\d{1,2}[\\s\u00a0]+$mois')),
      findsNothing,
    );
  }
}

class _FauxPort implements PortMaProgression {
  _FauxPort({this.brut, this.erreur, this.attente});

  Object? brut;
  Error? erreur;
  Completer<void>? attente;
  final List<String> lus = <String>[];

  @override
  Future<MaProgression?> pourEleve(String eleveId) async {
    lus.add(eleveId);
    if (attente case final Completer<void> c) await c.future;
    if (erreur case final Error e) throw e;
    // Le meme chemin que l'adaptateur Supabase : la reponse brute, lue par
    // `MaProgression.depuisJson`.
    return MaProgression.depuisJson(brut);
  }
}

Future<void> _monterEleve(
  WidgetTester tester,
  _FauxPort port, {
  InterfaceMode mode = InterfaceMode.standard,
  bool horsLigne = false,
  bool attendre = true,
  List<Override> surcharges = const <Override>[],
}) async {
  await monterRouteur(
    tester,
    Routes.eleveSuivi,
    source: FausseSourceSession(sessionActive(AppRole.student, mode: mode)),
    interface: mode,
    taille: const Size(390, 3200),
    surcharges: <Override>[
      portMaProgressionProvider.overrideWithValue(port),
      ...surcharges,
      horsLigneProvider.overrideWith(
        (Ref ref) => Stream<bool>.value(horsLigne),
      ),
    ],
  );
  if (attendre) await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('Lecture de la reponse de ma_progression', () {
    test('une reponse complete', () {
      final MaProgression? p = MaProgression.depuisJson(_reponse());
      expect(p, isNotNull);
      final SuiviPedagogique s = p!.suivi!;
      expect(s.etapeNom, 'Lire avec les voyelles');
      expect(s.etapeOrdre, 2);
      expect(s.niveauNom, 'Les bases');
      expect(s.matiereSecondaire, 'Al-Fatiha dès la première semaine');
      expect(s.entreeLe, DateTime(2026, 10));
      expect(s.dureePrevueSemaines, 11);
      expect(s.dateLimiteSemaines, 14);
      expect(s.dateLimite, DateTime(2027, 1, 7));
      expect(s.horizon, DateTime(2027, 5, 6));
      expect(s.rythme, Rythme.dansLesTemps);
      expect(s.pageReprise, 12);
      expect(s.eleveVoitDates, isTrue);
      expect(p.sourates?.validees, 3);
      expect(p.sourates?.total, 17);
      expect(p.cycle.map((EtapeDuCycle e) => e.statut), <StatutEtape>[
        StatutEtape.franchie,
        StatutEtape.enCours,
        StatutEtape.aVenir,
        StatutEtape.aVenir,
      ]);
      expect(p.cycle.first.dureePrevueSemaines, 6);
      expect(p.cycle.first.dateLimiteSemaines, 8);
      expect(p.cycle.first.objectifs, <String>[
        'Distingue les lettres qui se ressemblent',
      ]);
    });

    test('sans etape ni sourates, ou reponse illisible : rien', () {
      expect(MaProgression.depuisJson(null), isNull);
      expect(MaProgression.depuisJson(<Object?>[]), isNull);
      expect(
        MaProgression.depuisJson(<String, Object?>{
          'etape': <String, Object?>{'nom': ' '},
        }),
        isNull,
      );
      expect(SuiviPedagogique.depuisLecture(null), isNull);
      expect(SuiviPedagogique.depuisLecture(<Object?>[]), isNull);
    });

    test('reponse masquee par le serveur (enfant de 6 a 9 ans) : ni date ni '
        'nombre de semaines, rythme inconnu', () {
      final MaProgression p = MaProgression.depuisJson(
        _reponse(masquee: true, voit: false),
      )!;
      final SuiviPedagogique s = p.suivi!;
      expect(s.dateLimite, isNull);
      expect(s.entreeLe, isNull);
      expect(s.horizon, isNull);
      expect(s.dureePrevueSemaines, isNull);
      expect(s.dateLimiteSemaines, isNull);
      expect(s.rythme, Rythme.inconnu);
      expect(s.eleveVoitDates, isFalse);
      expect(p.cycle, hasLength(4));
      expect(
        p.cycle.every(
          (EtapeDuCycle e) =>
              e.atteinteLe == null &&
              e.dureePrevueSemaines == null &&
              e.dateLimiteSemaines == null,
        ),
        isTrue,
      );
    });

    test('reponse d avant le socle (sans niveau ni eleve_voit_dates) : '
        'lisible, la regle de dates reste celle d avant', () {
      final Map<String, Object?> r = _reponse()
        ..remove('niveau')
        ..remove('eleve_voit_dates');
      final MaProgression p = MaProgression.depuisJson(r)!;
      expect(p.suivi!.etapeNom, 'Lire avec les voyelles');
      expect(p.suivi!.eleveVoitDates, isNull);
      expect(p.suivi!.niveauNom, isNull);
    });

    test('attente de l entretien de lecture : un etat a part, les sourates '
        'restent rendues', () {
      final MaProgression? p = MaProgression.depuisJson(<String, Object?>{
        'etape': null,
        'etapes_du_cycle': <Object?>[],
        'sourates': <String, Object?>{
          'sourates_validees': 2,
          'sourates_total': 17,
        },
        'reglage': null,
        'attente': 'entretien_de_lecture',
      });
      expect(p?.suivi?.enAttenteEntretien, isTrue);
      expect(p?.sourates?.validees, 2);
      expect(
        SuiviPedagogique.depuisLecture(<String, Object?>{
          'eleve_id': 'x',
          'attente': 'entretien_de_lecture',
        })?.enAttenteEntretien,
        isTrue,
      );
    });

    test('une etape du cycle au statut inconnu est ecartee', () {
      final Map<String, Object?> r = _reponse();
      (r['etapes_du_cycle']! as List<Object?>).add(<String, Object?>{
        'ordre': 5,
        'nom': 'x',
        'statut': 'autre',
      });
      expect(MaProgression.depuisJson(r)!.cycle, hasLength(4));
    });
  });

  group('Suivi de l eleve, vrai routeur', () {
    testWidgets('contenu : etape, matieres, entree, durees de l etape, date '
        'limite de l etape, horizon du niveau, chemin', (tester) async {
      final _FauxPort port = _FauxPort(brut: _reponse());
      await _monterEleve(tester, port);

      expect(find.byType(SuiviElevePage), findsOneWidget);
      expect(port.lus, <String>['p-student']);
      final s = t.suiviPedagogique;
      expect(find.text(s.titreSoi), findsOneWidget);
      // La ligne de l'etape en cours et son nom dans le chemin des etapes.
      expect(find.text('Lire avec les voyelles'), findsNWidgets(2));
      expect(find.text(s.matierePrincipale), findsOneWidget);
      expect(find.text(s.matiereSecondaire), findsOneWidget);
      expect(find.text(s.depuis), findsOneWidget);
      expect(
        find.text(
          LibellesGroupe.insecable(s.dureesEtape(prevue: '11', limite: '14')),
        ),
        findsOneWidget,
      );
      expect(find.text(s.aFinirAvant), findsOneWidget);
      expect(find.text(s.horizonNiveau(niveau: 'Les bases')), findsOneWidget);
      expect(find.text(s.chemin(niveau: 'Les bases')), findsOneWidget);
      for (final String nom in <String>['Les lettres', 'Lire dans le Coran']) {
        expect(find.text(nom), findsOneWidget);
      }
      expect(find.textContaining(s.etapeEnCours), findsOneWidget);
      expect(find.textContaining(s.etapeFranchie), findsOneWidget);
      // Les sourates validees au cahier, du meme appel.
      expect(find.text(s.souratesDe(validees: 3, total: 17)), findsOneWidget);
      // « Etape validee » est reserve au resultat d'une evaluation (lot 8).
      expect(find.textContaining('Étape validée'), findsNothing);
      // La ligne de l'etape en cours et sa ligne dans le chemin.
      expect(
        find.textContaining(
          LibellesGroupe.insecable(s.dureesEtape(prevue: '11', limite: '14')),
        ),
        findsNWidgets(2),
      );
      verifierUnSeulBoutonPlein(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('enfant de 6 a 9 ans en interface standard, reponse masquee '
        'par le serveur : etape, matieres et chemin, aucune date ni duree', (
      tester,
    ) async {
      await _monterEleve(
        tester,
        _FauxPort(brut: _reponse(masquee: true, voit: false)),
      );
      expect(find.text('Lire avec les voyelles'), findsWidgets);
      expect(find.text(t.suiviPedagogique.matierePrincipale), findsOneWidget);
      expect(
        find.text(t.suiviPedagogique.chemin(niveau: 'Les bases')),
        findsOneWidget,
      );
      _aucuneDate(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('enfant de 6 a 9 ans : meme si le niveau declare et le dernier '
        'jalon (avec sa date) sont rendus, aucune date nulle part dans la '
        'carte, la ligne du jalon comprise', (tester) async {
      await _monterEleve(
        tester,
        _FauxPort(brut: _reponse(masquee: true, voit: false)),
        surcharges: <Override>[
          portProgressionFamilleProvider.overrideWithValue(_FamilleAvecJalon()),
        ],
      );
      expect(find.text(t.suiviPedagogique.dernierJalon), findsOneWidget);
      expect(find.text('Lire avec les voyelles'), findsWidgets);
      _aucuneDate(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('son tuteur, reponse SANS le drapeau, presentation standard : '
        'il voit toujours les dates', (tester) async {
      await monterHistorique(
        tester,
        depart: Routes.tuteurSuivi,
        taille: const Size(390, 3200),
        autres: <Override>[
          portMaProgressionProvider.overrideWithValue(
            _FauxPort(brut: _sansDrapeau()),
          ),
        ],
      );
      final s = t.suiviPedagogique;
      expect(find.text(s.aFinirAvant), findsOneWidget);
      expect(find.text(s.horizonNiveau(niveau: 'Les bases')), findsOneWidget);
      expect(find.text(s.dureePrevue), findsOneWidget);
      expect(find.text(s.rythme), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('son tuteur, lui, lit la date du jalon', (tester) async {
      await monterHistorique(
        tester,
        depart: Routes.tuteurSuivi,
        taille: const Size(390, 3200),
        autres: <Override>[
          portMaProgressionProvider.overrideWithValue(
            _FauxPort(brut: _reponse(voit: false)),
          ),
          portProgressionFamilleProvider.overrideWithValue(_FamilleAvecJalon()),
        ],
      );
      expect(find.text(t.suiviPedagogique.dernierJalon), findsOneWidget);
      expect(find.textContaining('2026'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('espace de l eleve, enfant de 6 a 9 ans, reponse NON masquee '
        '(lue avec le jeton du tuteur) : l ecran n affiche toujours aucune '
        'date ni duree, sur eleve_voit_dates', (tester) async {
      await _monterEleve(tester, _FauxPort(brut: _reponse(voit: false)));
      expect(find.text('Lire avec les voyelles'), findsWidgets);
      _aucuneDate(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('espace de l eleve, presentation standard, reponse SANS le '
        'drapeau eleve_voit_dates (serveur d avant le socle) : aucune date, '
        'refus par defaut', (tester) async {
      await _monterEleve(tester, _FauxPort(brut: _sansDrapeau()));
      expect(find.text('Lire avec les voyelles'), findsWidgets);
      expect(find.text(t.suiviPedagogique.matierePrincipale), findsOneWidget);
      _aucuneDate(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('espace de l eleve, Interface guidee, reponse sans le drapeau '
        ': aucune date non plus', (tester) async {
      await _monterEleve(
        tester,
        _FauxPort(brut: _sansDrapeau()),
        mode: InterfaceMode.enfant,
      );
      expect(find.text('Lire avec les voyelles'), findsWidgets);
      _aucuneDate(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('adulte en Interface guidee : ses dates et ses durees restent '
        'affichees (le mode ne decide rien)', (tester) async {
      await _monterEleve(
        tester,
        _FauxPort(brut: _reponse()),
        mode: InterfaceMode.enfant,
      );
      final s = t.suiviPedagogique;
      expect(find.text(s.aFinirAvant), findsOneWidget);
      expect(find.text(s.horizonNiveau(niveau: 'Les bases')), findsOneWidget);
      expect(find.text(s.dureePrevue), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('attente de l entretien de lecture : un texte vrai', (
      tester,
    ) async {
      await _monterEleve(tester, _FauxPort(brut: _attente()));
      expect(find.text(t.suiviPedagogique.attenteEntretien), findsOneWidget);
      expect(find.text(t.suiviPedagogique.matierePrincipale), findsNothing);
    });

    testWidgets('sans etape, sans sourates, sans jalon : le bloc n est pas '
        'pose (le contrat de MA-PROGRESSION-ECRAN)', (tester) async {
      await _monterEleve(tester, _FauxPort());
      expect(
        find.byKey(const ValueKey<String>('suivi-pedagogique')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('chargement : un squelette, puis le contenu', (tester) async {
      final _FauxPort port = _FauxPort(
        brut: _reponse(),
        attente: Completer<void>(),
      );
      await _monterEleve(tester, port, attendre: false);
      expect(
        find.byKey(const ValueKey<String>('suivi-pedagogique-chargement')),
        findsOneWidget,
      );
      expect(find.byType(Skeleton), findsWidgets);
      port.attente!.complete();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.byKey(const ValueKey<String>('suivi-pedagogique')),
        findsOneWidget,
      );
    });

    testWidgets('erreur : la phrase et Reessayer, qui relit', (tester) async {
      final _FauxPort port = _FauxPort(erreur: StateError('reseau'));
      await _monterEleve(tester, port);
      final Finder bloc = find.byKey(
        const ValueKey<String>('suivi-pedagogique-erreur'),
      );
      expect(bloc, findsOneWidget);
      expect(tester.widget<EtatSysteme>(bloc).nature, NatureEtat.echecServeur);
      port
        ..erreur = null
        ..brut = _reponse();
      await tester.tap(
        find.descendant(of: bloc, matching: find.text(t.commun.reessayer)),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.byKey(const ValueKey<String>('suivi-pedagogique')),
        findsOneWidget,
      );
    });

    testWidgets('hors ligne : l etat hors ligne du bloc', (tester) async {
      await _monterEleve(
        tester,
        _FauxPort(erreur: StateError('reseau')),
        horsLigne: true,
      );
      expect(
        find.byKey(const ValueKey<String>('suivi-pedagogique-erreur')),
        findsOneWidget,
      );
      expect(find.text(t.suiviPedagogique.erreur), findsWidgets);
    });
  });

  testWidgets('Historique du tuteur, vrai routeur : l etape, le chemin et la '
      'date limite de l enfant choisi, meme quand l enfant ne voit pas ses '
      'dates', (tester) async {
    final _FauxPort port = _FauxPort(brut: _reponse(voit: false));
    await monterHistorique(
      tester,
      depart: Routes.tuteurSuivi,
      taille: const Size(390, 3200),
      autres: <Override>[portMaProgressionProvider.overrideWithValue(port)],
    );
    expect(find.byType(SuiviFoyerPage), findsOneWidget);
    expect(port.lus, contains(FoyersFictifs.a1.id));
    final s = t.suiviPedagogique;
    expect(find.text(s.titre(prenom: FoyersFictifs.a1.prenom)), findsOneWidget);
    expect(find.text(s.aFinirAvant), findsOneWidget);
    expect(find.text(s.horizonNiveau(niveau: 'Les bases')), findsOneWidget);
    expect(find.text(s.chemin(niveau: 'Les bases')), findsOneWidget);
    expect(find.text(s.dureePrevue), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Historique du tuteur : attente de l entretien de lecture, au '
      'nom de l enfant', (tester) async {
    await monterHistorique(
      tester,
      depart: Routes.tuteurSuivi,
      taille: const Size(390, 3200),
      autres: <Override>[
        portMaProgressionProvider.overrideWithValue(
          _FauxPort(brut: _attente()),
        ),
      ],
    );
    expect(
      find.text(
        t.suiviPedagogique.attenteEntretienPour(
          prenom: FoyersFictifs.a1.prenom,
        ),
      ),
      findsOneWidget,
    );
  });
}

/// Le niveau declare et le dernier jalon, avec sa date (ce qu'un adaptateur rendrait a un tuteur).
class _FamilleAvecJalon implements PortProgressionFamille {
  @override
  Future<ProgressionEleve> progression(String eleveId) async =>
      ProgressionEleve(
        eleveId: eleveId,
        niveauHumain: 'Les lettres',
        jalons: const <String>['Lit chaque lettre'],
        dernierJalonLe: DateTime(2026, 10, 14),
      );
}
