// SOCLE-PROGRAMME (lot 1 de la charte, 12/11/2026) : le Suivi de l'eleve et
// l'Historique du tuteur, branches sur la lecture unique `etape_eleve_lecture`,
// montes par le VRAI routeur, en clair et en sombre, a 390 et 1440 points.
// Eleve adulte (interface standard), enfant (Interface guidee, sans date
// limite), tuteur. Donnees de test seulement (la reponse du serveur est
// simulee ; rien ne vient de la production).
//
// Saute sans CAPTURE_DIR. Usage :
//   CAPTURE_DIR=docs/current/captures/E2E/socle-programme flutter test --no-pub \
//     test/capture/socle_programme_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/suivi/port_suivi_pedagogique.dart';

import '../features/historique/support_historique.dart';
import '../router/support_routeur.dart';
import '../support/harnais.dart';
import 'outil_capture.dart'
    show capturerVue, chargerPolicesDuDepot, masquerRubanDebug, sautSansCapture;

Map<String, Object?> _etape(
  int ordre,
  String nom,
  String statut,
  int prevue,
  int limite,
) => <String, Object?>{
  'code': 'BASES-$ordre',
  'ordre': ordre,
  'nom': nom,
  'objectifs': <Object?>[],
  'duree_prevue_semaines': prevue,
  'date_limite_semaines': limite,
  'statut': statut,
};

Map<String, Object?> _reponse({required bool dateLimite}) => <String, Object?>{
  'eleve_voit_dates': dateLimite,
  'etape': <String, Object?>{
    'code': 'BASES-1',
    'ordre': 1,
    'nom': 'Les lettres',
    'objectifs': <Object?>[
      'Reconnaît chaque lettre dans le désordre',
      'Prononce chaque lettre depuis son point de sortie',
      'Distingue les lettres qui se ressemblent',
      "Reconnaît une lettre au début, au milieu et à la fin d'un mot",
    ],
    'matiere_principale': 'Le livre de lecture de Rewayah : les lettres',
    'matiere_secondaire': dateLimite
        ? 'Al-Fatiha dès la première semaine, puis An-Nâs, Al-Falaq et '
              'Al-Ikhlâs, puis les paroles de la prière et les ablutions, puis '
              'les autres invocations'
        : null,
    'duree_prevue_semaines': dateLimite ? 3 : 8,
    'date_limite_semaines': dateLimite ? 4 : 10,
    'entree_le': '2026-10-22',
    'date_limite': dateLimite ? '2026-11-19' : null,
    'semaines_ecoulees': dateLimite ? 3 : null,
    'rythme': dateLimite ? 'dans_les_temps' : null,
  },
  'niveau': <String, Object?>{
    'nom': 'Les bases',
    'horizon': dateLimite ? '2027-03-11' : null,
    'date_limite_visible': dateLimite,
  },
  'chemin': <Object?>[
    _etape(
      1,
      'Les lettres',
      'en_cours',
      dateLimite ? 3 : 8,
      dateLimite ? 4 : 10,
    ),
    _etape(
      2,
      'Lire avec les voyelles',
      'a_venir',
      dateLimite ? 6 : 14,
      dateLimite ? 8 : 19,
    ),
    _etape(
      3,
      'Lire dans le Coran',
      'a_venir',
      dateLimite ? 3 : 8,
      dateLimite ? 4 : 10,
    ),
    _etape(
      4,
      "Les sourates courtes, d'Al-Masad à Az-Zalzalah",
      'a_venir',
      dateLimite ? 3 : 7,
      dateLimite ? 4 : 9,
    ),
  ],
  'sourates': <String, Object?>{'validees': 0, 'total': 17},
  'page_reprise': 3,
};

class _Port implements PortSuiviPedagogique {
  const _Port(this.brut);

  final Object? brut;

  @override
  Future<SuiviPedagogique?> pourEleve(String eleveId) async =>
      SuiviPedagogique.depuisLecture(brut);
}

void main() {
  group('Capture SOCLE-PROGRAMME', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final ThemeMode theme in <ThemeMode>[
      ThemeMode.light,
      ThemeMode.dark,
    ]) {
      final String nomTheme = theme == ThemeMode.light ? 'clair' : 'sombre';
      for (final double largeur in <double>[390, 1440]) {
        final String l = '${largeur.toInt()}';
        testWidgets('eleve adulte $l $nomTheme', (WidgetTester tester) async {
          await monterRouteur(
            tester,
            Routes.eleveSuivi,
            source: FausseSourceSession(sessionActive(AppRole.student)),
            taille: Size(largeur, 2000),
            themeMode: theme,
            surcharges: <Override>[
              portSuiviPedagogiqueProvider.overrideWithValue(
                _Port(_reponse(dateLimite: true)),
              ),
              horsLigneProvider.overrideWith(
                (Ref ref) => Stream<bool>.value(false),
              ),
            ],
          );
          await tester.pump(const Duration(milliseconds: 600));
          debugPrint('PNG ${await capturerVue(tester, 'eleve-$l-$nomTheme')}');
        });
        testWidgets('enfant guide $l $nomTheme', (WidgetTester tester) async {
          await monterRouteur(
            tester,
            Routes.eleveSuivi,
            source: FausseSourceSession(
              sessionActive(AppRole.student, mode: InterfaceMode.enfant),
            ),
            interface: InterfaceMode.enfant,
            taille: Size(largeur, 2400),
            themeMode: theme,
            surcharges: <Override>[
              portSuiviPedagogiqueProvider.overrideWithValue(
                _Port(_reponse(dateLimite: false)),
              ),
              horsLigneProvider.overrideWith(
                (Ref ref) => Stream<bool>.value(false),
              ),
            ],
          );
          await tester.pump(const Duration(milliseconds: 600));
          debugPrint('PNG ${await capturerVue(tester, 'enfant-$l-$nomTheme')}');
        });
        testWidgets('tuteur $l $nomTheme', (WidgetTester tester) async {
          await monterHistorique(
            tester,
            depart: Routes.tuteurSuivi,
            taille: Size(largeur, 2400),
            mode: theme,
            autres: <Override>[
              portSuiviPedagogiqueProvider.overrideWithValue(
                _Port(_reponse(dateLimite: true)),
              ),
            ],
          );
          await tester.pump(const Duration(milliseconds: 600));
          debugPrint('PNG ${await capturerVue(tester, 'tuteur-$l-$nomTheme')}');
        });
      }
    }
  });
}
