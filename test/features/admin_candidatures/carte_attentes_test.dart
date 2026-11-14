// VISION-RECRUTEMENT (directeur, 14/11/2026) : « Qui attend quoi » au-dessus
// de la file des candidatures.
//
// Prouve : la lecture serveur est rangee sans recalcul (trois attentes, zero
// masque) ; toucher une ligne pose le filtre qui compte exactement ce qu'elle
// annonce ; sans lecture serveur, la carte ne s'affiche pas et la page reste ;
// ordinateur : trois cartes cote a cote ; telephone : empilees ; un seul bouton
// plein ; arabe.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/attentes_recrutement.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_candidatures/carte_attentes.dart';

import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/garde_interface.dart';
import 'hote_candidatures.dart';

class _FauxAttentes implements PortAttentesRecrutement {
  _FauxAttentes(this.rendu, {this.erreur});

  final AttentesRecrutement rendu;
  final Object? erreur;
  int appels = 0;

  @override
  Future<AttentesRecrutement> lire() async {
    appels++;
    final Object? e = erreur;
    if (e != null) throw e;
    return rendu;
  }
}

final DateTime _maintenant = DateTime.now();

AttentesRecrutement _attentes({bool deuxCotes = false}) =>
    AttentesRecrutement.depuisJson(<String, Object?>{
      'etats': <String, Object?>{
        'en_examen': <String, Object?>{
          'nombre': 41,
          'plusAncien': _maintenant
              .subtract(const Duration(hours: 6))
              .toUtc()
              .toIso8601String(),
        },
        'a_completer': <String, Object?>{'nombre': 18},
        'paiement_non_disponible': <String, Object?>{'nombre': 11},
        'entretien_a_planifier': <String, Object?>{'nombre': 1},
        'decision_en_attente': <String, Object?>{'nombre': 0},
        'etat_inconnu_du_client': <String, Object?>{'nombre': 3},
      },
      'pieceAValider': <String, Object?>{'nombre': 13},
      'enPause': 0,
      'creneauxOuverts': 0,
      'entretiensSansIssue': 0,
      'deuxCotes': deuxCotes,
    });

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

Future<void> _monter(
  WidgetTester tester, {
  required FauxCandidaturesDirection port,
  PortAttentesRecrutement? attentes,
  double largeur = 390,
  TextDirection? direction,
}) => monterCandidatures(
  tester,
  port: port,
  largeur: largeur,
  direction: direction,
  surcharges: [portAttentesRecrutementProvider.overrideWithValue(attentes)],
);

FauxCandidaturesDirection _port() => FauxCandidaturesDirection(
  lignes: <LigneCandidature>[
    ligneTest(id: 'a1', etat: EtatCandidature.enExamen),
    ligneTest(id: 'b2', nom: 'Bilal Haddad', etat: EtatCandidature.aCompleter),
  ],
);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('lecture', () {
    test('les etats rendus, un etat inconnu ignore, jamais un nombre invente', () {
      final AttentesRecrutement a = _attentes(deuxCotes: true);
      expect(a.etat(EtatCandidature.enExamen).nombre, 41);
      expect(a.etat(EtatCandidature.enExamen).plusAncien, isNotNull);
      expect(a.etat(EtatCandidature.entretienPlanifie).nombre, 0);
      expect(a.parEtat.length, 5);
      expect(a.pieceAValider.nombre, 13);
      expect(a.deuxCotes, isTrue);
      expect(
        () => AttentesRecrutement.depuisJson('x'),
        throwsA(isA<FormatException>()),
      );
    });

    test('depuis quand : minutes, heures, jours', () {
      final DateTime m = DateTime.utc(2026, 11, 14, 12);
      expect(depuisQuand(null, m), isNull);
      expect(
        depuisQuand(m.subtract(const Duration(seconds: 20)), m),
        t.admin.candidatures.attentes.depuisMinutes(n: 1),
      );
      expect(
        depuisQuand(m.subtract(const Duration(hours: 6, minutes: 5)), m),
        t.admin.candidatures.attentes.depuisHeures(n: 6),
      );
      expect(
        depuisQuand(m.subtract(const Duration(days: 3)), m),
        t.admin.candidatures.attentes.depuisJours(n: 3),
      );
    });
  });

  group('page', () {
    testWidgets('trois attentes, zero masque, la piece sans filtre', (
      tester,
    ) async {
      await _monter(
        tester,
        port: _port(),
        attentes: _FauxAttentes(_attentes()),
      );
      final a = t.admin.candidatures.attentes;
      expect(find.byKey(CarteAttentes.cleSection), findsOneWidget);
      expect(find.text(a.titre), findsOneWidget);
      expect(find.text(a.academie), findsOneWidget);
      expect(find.text(a.personne), findsOneWidget);
      expect(find.text(a.versement), findsOneWidget);
      expect(
        find.byKey(CarteAttentes.cleLigne(EtatCandidature.enExamen)),
        findsOneWidget,
      );
      expect(find.text('41'), findsOneWidget);
      expect(find.textContaining(a.depuisHeures(n: 6)), findsOneWidget);
      // Zero : pas de ligne.
      expect(
        find.byKey(CarteAttentes.cleLigne(EtatCandidature.decisionEnAttente)),
        findsNothing,
      );
      expect(find.byKey(CarteAttentes.clePause), findsNothing);
      // L'entretien a planifier dit qu'aucun creneau n'est ouvert.
      expect(find.textContaining(a.aucunCreneau), findsOneWidget);
      expect(find.byKey(CarteAttentes.clePiece), findsOneWidget);
      expect(find.textContaining(a.pieceAide), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets(
      'toucher une ligne pose le filtre qui compte ce qu elle annonce',
      (tester) async {
        final FauxCandidaturesDirection port = _port();
        await _monter(
          tester,
          port: port,
          attentes: _FauxAttentes(_attentes()),
        );
        final Finder ligne = find.byKey(
          CarteAttentes.cleLigne(EtatCandidature.aCompleter),
        );
        await tester.ensureVisible(ligne);
        await tester.tap(ligne);
        await tester.pumpAndSettle();
        final filtre = port.appels.last.filtre;
        expect(filtre.etat, EtatCandidature.aCompleter);
        expect(filtre.issue, IssueCandidature.enCours);
        expect(filtre.enPause, isFalse);
        expect(filtre.recherche, isEmpty);
        expect(filtre.etape, isNull);
        expect(filtre.genre, isNull);
      },
    );

    testWidgets('sans lecture serveur : pas de carte, la page reste', (
      tester,
    ) async {
      await _monter(
        tester,
        port: _port(),
        attentes: _FauxAttentes(
          const AttentesRecrutement(),
          erreur: const CapaciteIndisponible(dependanceAttentesRecrutement),
        ),
      );
      expect(find.byKey(CarteAttentes.cleSection), findsNothing);
      expect(_cle('candidatures-recherche'), findsOneWidget);
    });

    testWidgets('sans port : pas de carte', (tester) async {
      await _monter(tester, port: _port());
      expect(find.byKey(CarteAttentes.cleSection), findsNothing);
      expect(_cle('candidatures-recherche'), findsOneWidget);
    });

    testWidgets('ordinateur 1440 : trois cartes cote a cote', (tester) async {
      await _monter(
        tester,
        port: _port(),
        attentes: _FauxAttentes(_attentes(deuxCotes: true)),
        largeur: 1440,
      );
      final a = t.admin.candidatures.attentes;
      final Offset g1 = tester.getTopLeft(find.text(a.academie));
      final Offset g2 = tester.getTopLeft(find.text(a.personne));
      final Offset g3 = tester.getTopLeft(find.text(a.versement));
      expect(g1.dy, g2.dy);
      expect(g2.dy, g3.dy);
      expect(g1.dx < g2.dx && g2.dx < g3.dx, isTrue);
      expect(find.textContaining(a.deuxCotes), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('telephone 390 : empilees', (tester) async {
      await _monter(
        tester,
        port: _port(),
        attentes: _FauxAttentes(_attentes()),
      );
      final a = t.admin.candidatures.attentes;
      final Offset g1 = tester.getTopLeft(find.text(a.academie));
      final Offset g2 = tester.getTopLeft(find.text(a.personne));
      expect(g2.dy > g1.dy, isTrue);
      expect(g1.dx, g2.dx);
    });

    testWidgets('arabe : les mots arabes, sans debordement', (tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _monter(
        tester,
        port: _port(),
        attentes: _FauxAttentes(_attentes()),
        largeur: 1440,
        direction: TextDirection.rtl,
      );
      final a = t.admin.candidatures.attentes;
      expect(find.text(a.titre), findsOneWidget);
      expect(find.text(a.academie), findsOneWidget);
      // En arabe, la premiere carte est a droite.
      expect(
        tester.getTopLeft(find.text(a.academie)).dx >
            tester.getTopLeft(find.text(a.personne)).dx,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
