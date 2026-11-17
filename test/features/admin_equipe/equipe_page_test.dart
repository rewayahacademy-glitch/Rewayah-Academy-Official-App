// BE-2b : l'ecran « Equipe ». Chaque etat (indisponible, chargement, contenu,
// vide, erreur, hors ligne), les feuilles qui s'ouvrent, la position du premier
// nom (< 300 points a 360 x 800) et la lecture des reponses du serveur.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/equipe/modeles_equipe.dart';
import 'package:rewayah_academy/core/equipe/port_equipe.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/admin_equipe/equipe_page.dart';

import '../../support/monter_recrutement.dart';
import 'faux_equipe.dart';

Future<void> _monter(
  WidgetTester tester, {
  PortEquipe? port,
  bool horsLigne = false,
  double largeur = 360,
  double hauteur = 800,
}) => monterRecrutement(
  tester,
  chemin: Routes.adminPersonnesEquipe,
  ecran: (_) => const EquipePage(),
  surcharges: <Override>[portEquipeProvider.overrideWithValue(port)],
  horsLigne: horsLigne,
  largeur: largeur,
  hauteur: hauteur,
);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  testWidgets('sans port : une seule phrase, aucun bouton d\'action', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    expect(find.text(t.admin.equipe.indisponibleTitre), findsOneWidget);
    expect(find.byKey(EquipePage.cleAccorder), findsNothing);
  });

  testWidgets('contenu : la personne, sa mission, son menu', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      port: FauxEquipe(
        attributionsRendues: <Attribution>[attributionKarim],
        missionsRendues: const <Mission>[missionLecture],
      ),
    );
    expect(find.text('Karim'), findsOneWidget);
    expect(find.textContaining('Lecture des candidatures'), findsWidgets);
    expect(find.byKey(EquipePage.cleAccorder), findsOneWidget);
    expect(find.byKey(EquipePage.cleMenuCommandes), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'le premier nom de la liste est a moins de 300 points (360 x 800)',
    (WidgetTester tester) async {
      await _monter(
        tester,
        port: FauxEquipe(attributionsRendues: <Attribution>[attributionKarim]),
      );
      final double haut = tester.getTopLeft(find.text('Karim')).dy;
      // ignore: avoid_print
      print('MESURE BE-2b : premier nom a ${haut.toStringAsFixed(1)} points');
      expect(haut, lessThan(300));
    },
  );

  testWidgets('vide : la phrase qui dit quoi faire', (
    WidgetTester tester,
  ) async {
    await _monter(tester, port: FauxEquipe());
    expect(find.text(t.admin.equipe.videTitre), findsOneWidget);
    expect(find.text(t.admin.equipe.videPhrase), findsOneWidget);
  });

  testWidgets('erreur : un etat d\'erreur avec « Reessayer », jamais un vide', (
    WidgetTester tester,
  ) async {
    await _monter(tester, port: FauxEquipe(erreur: Exception('x')));
    expect(find.text(t.admin.equipe.videTitre), findsNothing);
    expect(find.byType(EquipePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hors ligne : les gestes ne sont pas proposes', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      port: FauxEquipe(attributionsRendues: <Attribution>[attributionKarim]),
      horsLigne: true,
    );
    expect(find.text('Karim'), findsOneWidget);
    // Un geste qui ne peut pas aboutir n'est pas rendu, il n'est pas grise.
    expect(find.byKey(EquipePage.cleAccorder), findsNothing);
    expect(find.byKey(EquipePage.cleMenuCommandes), findsNothing);
  });

  testWidgets('invitations : le code et la date, jamais un envoi promis', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      port: FauxEquipe(
        invitationsRendues: <InvitationAssocie>[
          InvitationAssocie(
            id: 'i1',
            code: 'ABC-DEF-GHJ',
            courriel: 'karim@example.org',
            etat: EtatInvitationAssocie.active,
            expireLe: DateTime.utc(2026, 12, 1),
          ),
        ],
      ),
    );
    await tester.ensureVisible(find.textContaining('karim@example.org'));
    expect(find.textContaining('karim@example.org'), findsOneWidget);
    expect(find.textContaining('ABC-DEF-GHJ'), findsOneWidget);
    expect(find.text(t.admin.equipe.aucuneInvitation), findsNothing);
  });

  testWidgets('les missions sont repliees, puis se deplient', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      port: FauxEquipe(missionsRendues: const <Mission>[missionLecture]),
    );
    expect(
      find.byKey(const ValueKey<String>('equipe-mission-m1')),
      findsNothing,
    );
    await tester.ensureVisible(find.text(t.admin.equipe.deplierMissions));
    await tester.tap(find.text(t.admin.equipe.deplierMissions));
    await laisser(tester);
    expect(
      find.byKey(const ValueKey<String>('equipe-mission-m1')),
      findsOneWidget,
    );
  });

  testWidgets('les trois feuilles s\'ouvrent', (WidgetTester tester) async {
    await _monter(
      tester,
      port: FauxEquipe(attributionsRendues: <Attribution>[attributionKarim]),
    );
    await tester.tap(find.byKey(EquipePage.cleMenuCommandes));
    await laisser(tester);
    await tester.tap(find.text(t.admin.equipe.nouvelleMission).last);
    await laisser(tester);
    expect(find.text(t.admin.equipe.feuille.mission.titre), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.tapAt(const Offset(5, 5));
    await laisser(tester);
    await tester.tap(find.byKey(EquipePage.cleAccorder));
    await laisser(tester);
    expect(find.text(t.admin.equipe.feuille.accorder.titre), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  group('lecture des reponses du serveur', () {
    test('une attribution illisible est ecartee, pas devinee', () {
      expect(Attribution.depuisJson(<String, Object?>{'id': 'a'}), isNull);
      expect(Mission.depuisJson('x'), isNull);
      expect(InvitationAssocie.depuisJson(<String, Object?>{}), isNull);
    });

    test('un statut d\'invitation inconnu donne null', () {
      expect(
        ResultatInvitation.depuisJson(<String, Object?>{'statut': 'zzz'}),
        isNull,
      );
      expect(
        ResultatInvitation.depuisJson(<String, Object?>{
          'statut': 'deja_invite',
        })?.statut,
        StatutInvitation.dejaInvite,
      );
    });
  });
}
