// Fiche « Fraicheur et notifications » (27/10/2026), ligne 13 : chaque
// evenement a sa phrase, en francais et en arabe ; la portee (soi, foyer,
// classe) et l'heure locale changent la phrase ; un evenement inconnu a un
// titre de repli lisible et ne fait rien planter.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/notifications_supabase.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/notifications/contenu_notification.dart';

/// Les evenements ajoutes par la fiche du 27/10 (ligne 11).
const List<String> _nouveaux = <String>[
  'classe_creee',
  'enseignant_change',
  'eleve_inscrit',
  'eleve_retire',
  'creneau_change',
  'seance_annulee',
  'seance_deplacee',
  'enseignante_absente',
  'classe_supprimee',
];

Map<String, dynamic> _ligne(
  String evenement, {
  Map<String, dynamic> params = const <String, dynamic>{},
  String destination = '/eleve',
}) => <String, dynamic>{
  'id': 'n-$evenement',
  'evenement': evenement,
  'params': params,
  'destination': destination,
  'cree_le': '2026-10-27T10:00:00Z',
  'lu_le': null,
};

void main() {
  setUp(() => LocaleSettings.setLocale(AppLocale.fr));
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('contenuNotificationPour', () {
    test('chaque evenement connu a une phrase FR et AR, jamais le repli', () {
      for (final AppLocale locale in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
        LocaleSettings.setLocale(locale);
        final String repli = t.notifications.evenements.inconnu;
        for (final String evenement in evenementsNotificationConnus) {
          final String titre = contenuNotificationPour(
            evenement,
            const <String, dynamic>{},
          ).titre;
          expect(titre.trim(), isNotEmpty, reason: '$locale $evenement');
          expect(titre, isNot(repli), reason: '$locale $evenement');
          // Jamais de tiret long ni d'identifiant.
          expect(titre.contains('—'), isFalse, reason: evenement);
        }
      }
    });

    test('les nouveaux evenements sont rendus et menent a leur ecran', () {
      for (final String evenement in _nouveaux) {
        final NotificationTuteur n = notificationDepuis(
          _ligne(evenement),
          titrePour: contenuNotificationPour,
        );
        expect(n.titre, isNotEmpty, reason: evenement);
        expect(n.destination, '/eleve', reason: evenement);
        expect(n.type, isNot(TypeNotification.autre), reason: evenement);
        expect(n.lue, isFalse);
      }
    });

    test('la portee choisit la phrase : l eleve, le tuteur, l enseignante', () {
      final e = t.notifications.evenements;
      String pour(String evenement, String portee) => contenuNotificationPour(
        evenement,
        <String, dynamic>{'portee': portee},
      ).titre;
      expect(pour('classe_creee', 'soi'), e.classeCreeeSoi);
      expect(pour('classe_creee', 'foyer'), e.classeCreeeFoyer);
      expect(pour('classe_creee', 'classe'), e.classeCreeeClasse);
      expect(pour('classe_creee', 'autre'), e.classeCreee);
      expect(pour('eleve_inscrit', 'soi'), e.eleveInscritSoi);
      expect(pour('eleve_inscrit', 'foyer'), e.eleveInscritFoyer);
      expect(pour('eleve_inscrit', 'classe'), e.eleveInscritClasse);
      expect(pour('eleve_retire', 'foyer'), e.eleveRetireFoyer);
      expect(pour('classe_supprimee', 'soi'), e.classeSupprimeeSoi);
      expect(pour('classe_supprimee', 'classe'), e.classeSupprimeeClasse);
      expect(pour('enseignant_affecte', 'classe'), e.enseignantAffecteClasse);
      // La ligne de c11bis, sans portee, garde sa phrase d'avant.
      expect(pour('enseignant_affecte', ''), e.enseignantAffecte);
      expect(
        contenuNotificationPour(
          'enseignant_affecte',
          const <String, dynamic>{},
        ).titre,
        e.enseignantAffecte,
      );
    });

    test(
      'l heure locale de la seance entre dans la phrase quand elle est la',
      () {
        final String avec = contenuNotificationPour(
          'seance_annulee',
          <String, dynamic>{'debut_local': '2026-11-06T18:00:00'},
        ).titre;
        expect(avec, contains('18:00'));
        expect(avec, isNot(t.notifications.evenements.seanceAnnulee));
        expect(
          contenuNotificationPour(
            'seance_annulee',
            const <String, dynamic>{},
          ).titre,
          t.notifications.evenements.seanceAnnulee,
        );
        // Une heure illisible : la phrase sans heure, jamais une erreur.
        expect(
          contenuNotificationPour('seance_deplacee', <String, dynamic>{
            'debut_local': 'pas une date',
          }).titre,
          t.notifications.evenements.seanceDeplacee,
        );
        expect(quandDepuis(const <String, dynamic>{}), isNull);
      },
    );

    test('un evenement inconnu est dit par le repli, jamais perdu', () {
      final NotificationContenu contenu = contenuNotificationPour(
        'evenement_de_demain',
        const <String, dynamic>{},
      );
      expect(contenu.titre, t.notifications.evenements.inconnu);
      final List<NotificationTuteur> liste = notificationsDepuis(<dynamic>[
        _ligne('evenement_de_demain'),
        _ligne('classe_creee'),
      ], titrePour: contenuNotificationPour);
      expect(liste, hasLength(2));
      expect(liste.first.type, TypeNotification.autre);
      expect(liste.first.titre, t.notifications.evenements.inconnu);
    });

    test(
      'la classe d un eleve du foyer est une destination, pas une autre',
      () {
        const String classe =
            '/tuteur/classes/f27b0000-0000-0000-0000-000000000201';
        expect(destinationNotificationAutorisee(classe), isTrue);
        expect(destinationNotificationAutorisee('$classe/planning'), isTrue);
        expect(destinationNotificationAutorisee('$classe/travail'), isFalse);
        expect(
          destinationNotificationAutorisee('/tuteur/classes/pas-un-uuid'),
          isFalse,
        );
        expect(destinationNotificationAutorisee('/eleve'), isTrue);
        expect(destinationNotificationAutorisee('/enseignant/journee'), isTrue);
        expect(
          destinationNotificationAutorisee('https://exemple.org'),
          isFalse,
        );
        expect(destinationNotificationAutorisee(null), isFalse);
      },
    );
  });
}
