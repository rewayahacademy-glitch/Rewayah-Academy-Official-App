// ANNONCES-SIMPLES (directeur, 14/11/2026) : le fil des annonces recues, la
// notification d'une annonce de la direction, le titre par defaut, et les
// captures R3 du publieur sur un seul ecran (390 et 1440, fr et ar, clair et
// sombre ; sautees sans CAPTURE_DIR).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/notifications_supabase.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/com_annonces/administration_communications_page.dart';
import 'package:rewayah_academy/features/com_annonces/annonces_recues.dart';
import 'package:rewayah_academy/features/com_annonces/port_annonces_direction.dart';
import 'package:rewayah_academy/features/com_annonces/publieur_annonce.dart';
import 'package:rewayah_academy/features/notifications/contenu_notification.dart';

import '../../capture/outil_capture.dart';
import '../../support/demo/communications/com_annonces_demo.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';
import 'admin_banc.dart';

/// Un fil d'annonces en memoire, qui note les annonces comptees « vues ».
class _FilFaux extends AnnoncesDirectionIndisponibles {
  _FilFaux({this.recues = const <AnnonceRecue>[], this.erreur});

  final List<AnnonceRecue> recues;
  final Exception? erreur;
  final List<String> vues = <String>[];

  @override
  Future<List<AnnonceRecue>> mesAnnonces() async {
    final Exception? e = erreur;
    if (e != null) throw e;
    return recues;
  }

  @override
  Future<void> marquerVue(String id) async => vues.add(id);
}

Future<void> _monterFil(WidgetTester tester, _FilFaux fil) async {
  await tester.pumpWidget(
    hote(
      const Scaffold(body: SingleChildScrollView(child: AnnoncesRecues())),
      surcharges: <Override>[
        portAnnoncesDirectionProvider.overrideWithValue(fil),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

final DateTime _le = DateTime.utc(2026, 11, 14, 9);

void main() {
  group('titre par defaut', () {
    test('la premiere ligne, au plus 80 caracteres', () {
      expect(
        titreParDefaut('Pas de cours lundi.\nBonne semaine.'),
        'Pas de cours lundi.',
      );
      expect(titreParDefaut('a' * 100), 'a' * 80);
    });
  });

  group('notification d une annonce de la direction', () {
    test('son titre et son debut, tels que la direction les a ecrits', () {
      final NotificationContenu c = contenuNotificationPour(
        'annonce_direction',
        <String, dynamic>{
          'titre': 'Pas de cours lundi',
          'extrait': 'Bonne semaine.',
        },
      );
      expect(
        c.titre,
        t.notifications.evenements.annonceDirectionTitre(
          titre: 'Pas de cours lundi',
        ),
      );
      expect(c.texte, 'Bonne semaine.');
    });

    test('la ligne serveur garde le titre et l extrait, type annonce', () {
      final NotificationTuteur n = notificationDepuis(<String, dynamic>{
        'id': 'n1',
        'evenement': 'annonce_direction',
        'params': <String, dynamic>{'titre': 'Reprise', 'extrait': 'Mardi.'},
        'destination': '/tuteur',
        'cree_le': '2026-11-14T09:00:00Z',
        'lu_le': null,
      }, titrePour: contenuNotificationPour);
      expect(n.type, TypeNotification.annonceDirection);
      expect(n.texte, 'Mardi.');
      expect(evenementsNotificationConnus, contains('annonce_direction'));
    });
  });

  group('fil des annonces recues', () {
    testWidgets('les annonces, « Nouvelle » sur celle pas vue, comptee vue', (
      WidgetTester tester,
    ) async {
      final _FilFaux fil = _FilFaux(
        recues: <AnnonceRecue>[
          AnnonceRecue(
            id: 'a1',
            titre: 'Entretiens',
            texte: 'Mardi.',
            publieeLe: _le,
          ),
          AnnonceRecue(
            id: 'a2',
            titre: 'Bienvenue',
            texte: 'Texte.',
            publieeLe: _le,
            vue: true,
          ),
        ],
      );
      await _monterFil(tester, fil);
      expect(find.text(t.com.annonces.fil.titre), findsOneWidget);
      expect(find.text('Entretiens'), findsOneWidget);
      expect(find.text('Bienvenue'), findsOneWidget);
      expect(find.text(t.com.annonces.fil.nouvelle), findsOneWidget);
      expect(fil.vues, <String>['a1']);
    });

    testWidgets('aucune annonce : rien n est rendu', (
      WidgetTester tester,
    ) async {
      await _monterFil(tester, _FilFaux());
      expect(find.byKey(AnnoncesRecues.cle), findsNothing);
    });

    testWidgets('pas de fil (mineur, migration absente) : rien', (
      WidgetTester tester,
    ) async {
      await _monterFil(
        tester,
        _FilFaux(erreur: AnnoncesDirectionIndisponibles.manque),
      );
      expect(find.byKey(AnnoncesRecues.cle), findsNothing);
    });

    testWidgets('echec : la phrase et Reessayer', (WidgetTester tester) async {
      await _monterFil(tester, _FilFaux(erreur: Exception('reseau')));
      expect(find.text(t.com.annonces.fil.echec), findsOneWidget);
      expect(find.text(t.commun.etats.actions.reessayer), findsOneWidget);
      expect(find.byType(CapaciteIndisponible), findsNothing);
    });
  });

  group('captures annonces simples', () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Brightness lum in Brightness.values) {
        for (final Size taille in <Size>[
          const Size(1440, 900),
          const Size(390, 844),
        ]) {
          final String nom =
              'publieur-direction-${taille.width.toInt()}-'
              '${langue.languageCode}-${lum == Brightness.dark ? 'sombre' : 'clair'}';
          testWidgets(nom, (WidgetTester tester) async {
            await monterAdministration(
              tester,
              taille: taille,
              arabe: langue == AppLocale.ar,
              luminosite: lum,
              direction: AnnoncesDirectionDemonstration(annoncesBanc()),
            );
            await taper(
              tester,
              find.byKey(AdministrationCommunicationsPage.cleNouvelle),
            );
            await taper(
              tester,
              find.byKey(PublieurAnnonce.clePublic(CodesPublics.candidats)),
            );
            await tester.enterText(
              find.byKey(PublieurAnnonce.cleTexte),
              langue == AppLocale.ar
                  ? 'تستأنف المقابلات يوم الثلاثاء.'
                  : 'Les entretiens reprennent mardi.',
            );
            await tester.pumpAndSettle();
            verifierUnSeulBoutonPlein(tester);
            // Le haut (A qui, et l'apercu sur ordinateur), puis le bas (le
            // message, les options repliees, le bouton).
            await tester.ensureVisible(
              find.text(t.com.annonces.simple.aQui),
            );
            await stabiliser(tester);
            await capturerVue(tester, 'annonces-simples/$nom-haut');
            await tester.ensureVisible(find.byKey(PublieurAnnonce.cleAction));
            await stabiliser(tester);
            await capturerVue(tester, 'annonces-simples/$nom-bas');
          });
        }
      }
    }
  }, skip: sautSansCapture);
}
