// SOCLE-PROGRAMME (lot 1 de la charte, 12/11/2026) : la lecture unique
// `etape_eleve_lecture` branchee dans le Suivi de l'eleve et l'Historique du
// tuteur. Lecture de la reponse serveur, puis les ecrans touches a travers le
// VRAI routeur : contenu (etape, matieres, date d'entree, duree prevue,
// date limite de l'etape, horizon du niveau, chemin), Interface guidee (ni
// date limite, ni horizon, ni rythme, ni durees), et les cinq etats : chargement, contenu, vide, erreur,
// hors ligne.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
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

/// La reponse du serveur pour un eleve a l'etape 2. [masquee] : telle que le
/// serveur la rend a l'enfant de 6 a 9 ans qui lit avec son propre compte
/// (aucune date, aucun nombre de semaines). [voit] : `eleve_voit_dates`.
Map<String, Object?> _reponse({bool masquee = false, bool voit = true}) {
  final bool dateLimite = !masquee;
  int? n(int v) => masquee ? null : v;
  return <String, Object?>{
    'eleve_id': 'p-student',
    'eleve_voit_dates': voit,
    'etape': <String, Object?>{
      'code': 'BASES-2',
      'ordre': 2,
      'nom': 'Lire avec les voyelles',
      'objectifs': <Object?>['Lit le tanwin', 'Lit la chadda'],
      'matiere_principale': 'Le livre de lecture de Rewayah : les voyelles',
      'matiere_secondaire': 'Al-Fatiha dès la première semaine',
      'duree_prevue_semaines': n(11),
      'date_limite_semaines': n(14),
      'entree_le': '2026-10-01',
      'date_limite': dateLimite ? '2027-01-07' : null,
      'semaines_ecoulees': dateLimite ? 6 : null,
      'rythme': dateLimite ? 'dans_les_temps' : null,
    },
    'niveau': <String, Object?>{
      'code': 'bases',
      'nom': 'Les bases',
      'cohorte': 'enfant_10_13',
      'duree_prevue_semaines': n(28),
      'date_limite_semaines': n(36),
      'entree_le': '2026-09-01',
      'horizon': dateLimite ? '2027-05-06' : null,
      'date_limite_visible': dateLimite,
    },
    'chemin': <Object?>[
      <String, Object?>{
        'code': 'BASES-1',
        'ordre': 1,
        'nom': 'Les lettres',
        'objectifs': <Object?>['Distingue les lettres qui se ressemblent'],
        'duree_prevue_semaines': n(6),
        'date_limite_semaines': n(8),
        'statut': 'precedente',
      },
      <String, Object?>{
        'code': 'BASES-2',
        'ordre': 2,
        'nom': 'Lire avec les voyelles',
        'objectifs': <Object?>['Lit le tanwin'],
        'duree_prevue_semaines': n(11),
        'date_limite_semaines': n(14),
        'statut': 'en_cours',
      },
      <String, Object?>{
        'code': 'BASES-3',
        'ordre': 3,
        'nom': 'Lire dans le Coran',
        'objectifs': <Object?>[],
        'duree_prevue_semaines': n(6),
        'date_limite_semaines': n(8),
        'statut': 'a_venir',
      },
      <String, Object?>{
        'code': 'BASES-4',
        'ordre': 4,
        'nom': "Les sourates courtes, d'Al-Masad à Az-Zalzalah",
        'objectifs': <Object?>[],
        'duree_prevue_semaines': n(5),
        'date_limite_semaines': n(6),
        'statut': 'a_venir',
      },
    ],
    'sourates': <String, Object?>{'validees': 3, 'total': 17},
    'page_reprise': 12,
    'version': <String, Object?>{'numero': 1, 'statut': 'publiee'},
  };
}

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

class _FauxPort implements PortSuiviPedagogique {
  _FauxPort({this.brut, this.erreur, this.attente});

  Object? brut;
  Error? erreur;
  Completer<void>? attente;
  final List<String> lus = <String>[];

  @override
  Future<SuiviPedagogique?> pourEleve(String eleveId) async {
    lus.add(eleveId);
    if (attente case final Completer<void> c) await c.future;
    if (erreur case final Error e) throw e;
    // Le meme chemin que l'adaptateur Supabase : la reponse brute, lue par
    // `depuisLecture`.
    return SuiviPedagogique.depuisLecture(brut);
  }
}

Future<void> _monterEleve(
  WidgetTester tester,
  _FauxPort port, {
  InterfaceMode mode = InterfaceMode.standard,
  bool horsLigne = false,
  bool attendre = true,
}) async {
  await monterRouteur(
    tester,
    Routes.eleveSuivi,
    source: FausseSourceSession(sessionActive(AppRole.student, mode: mode)),
    interface: mode,
    taille: const Size(390, 3200),
    surcharges: <Override>[
      portSuiviPedagogiqueProvider.overrideWithValue(port),
      horsLigneProvider.overrideWith(
        (Ref ref) => Stream<bool>.value(horsLigne),
      ),
    ],
  );
  if (attendre) await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('Lecture de la reponse de etape_eleve_lecture', () {
    test('une reponse complete', () {
      final SuiviPedagogique? s = SuiviPedagogique.depuisLecture(_reponse());
      expect(s, isNotNull);
      expect(s!.etapeNom, 'Lire avec les voyelles');
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
      expect(s.sourates?.validees, 3);
      expect(s.sourates?.total, 17);
      expect(s.chemin.map((EtapeDuChemin e) => e.statut), <StatutEtape>[
        StatutEtape.precedente,
        StatutEtape.enCours,
        StatutEtape.aVenir,
        StatutEtape.aVenir,
      ]);
      expect(s.chemin.first.dureePrevueSemaines, 6);
      expect(s.chemin.first.dateLimiteSemaines, 8);
    });

    test('sans etape, ou reponse illisible : rien, jamais suppose', () {
      expect(SuiviPedagogique.depuisLecture(null), isNull);
      expect(SuiviPedagogique.depuisLecture(<Object?>[]), isNull);
      expect(
        SuiviPedagogique.depuisLecture(<String, Object?>{
          'etape': <String, Object?>{'nom': ' '},
        }),
        isNull,
      );
    });

    test('reponse masquee par le serveur (enfant de 6 a 9 ans) : ni date ni '
        'nombre de semaines, rythme inconnu', () {
      final SuiviPedagogique s = SuiviPedagogique.depuisLecture(
        _reponse(masquee: true, voit: false),
      )!;
      expect(s.dateLimite, isNull);
      expect(s.horizon, isNull);
      expect(s.dureePrevueSemaines, isNull);
      expect(s.dateLimiteSemaines, isNull);
      expect(s.rythme, Rythme.inconnu);
      expect(s.eleveVoitDates, isFalse);
      expect(s.chemin, hasLength(4));
      expect(
        s.chemin.every(
          (EtapeDuChemin e) =>
              e.dureePrevueSemaines == null && e.dateLimiteSemaines == null,
        ),
        isTrue,
      );
    });

    test('attente de l entretien de lecture : un etat a part', () {
      final SuiviPedagogique? s = SuiviPedagogique.depuisLecture(
        <String, Object?>{'eleve_id': 'x', 'attente': 'entretien_de_lecture'},
      );
      expect(s?.enAttenteEntretien, isTrue);
    });

    test('une etape du chemin au statut inconnu est ecartee', () {
      final Map<String, Object?> r = _reponse();
      (r['chemin']! as List<Object?>).add(<String, Object?>{
        'ordre': 5,
        'nom': 'x',
        'statut': 'autre',
      });
      expect(SuiviPedagogique.depuisLecture(r)!.chemin, hasLength(4));
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
      expect(find.text('Lire avec les voyelles'), findsOneWidget);
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
      for (final String nom in <String>[
        'Les lettres',
        'Lire avec les voyelles',
        'Lire dans le Coran',
      ]) {
        expect(
          find.text(
            s.etapeNumero(
              ordre: nom == 'Les lettres'
                  ? '1'
                  : (nom == 'Lire dans le Coran' ? '3' : '2'),
              nom: nom,
            ),
          ),
          findsOneWidget,
        );
      }
      expect(find.textContaining(s.statutEnCours), findsOneWidget);
      expect(find.textContaining(s.statutPrecedente), findsOneWidget);
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

    testWidgets('espace de l eleve, enfant de 6 a 9 ans, reponse NON masquee '
        '(lue avec le jeton du tuteur) : l ecran n affiche toujours aucune '
        'date ni duree, sur eleve_voit_dates', (tester) async {
      await _monterEleve(tester, _FauxPort(brut: _reponse(voit: false)));
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
      await _monterEleve(
        tester,
        _FauxPort(brut: <String, Object?>{'attente': 'entretien_de_lecture'}),
      );
      expect(find.text(t.suiviPedagogique.attenteEntretien), findsOneWidget);
      expect(find.text(t.suiviPedagogique.vide), findsNothing);
    });

    testWidgets('vide : sans etape, une ligne le dit', (tester) async {
      await _monterEleve(tester, _FauxPort());
      expect(
        find.byKey(const ValueKey<String>('suivi-pedagogique-vide')),
        findsOneWidget,
      );
      expect(find.text(t.suiviPedagogique.vide), findsOneWidget);
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
      autres: <Override>[portSuiviPedagogiqueProvider.overrideWithValue(port)],
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
        portSuiviPedagogiqueProvider.overrideWithValue(
          _FauxPort(brut: <String, Object?>{'attente': 'entretien_de_lecture'}),
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
