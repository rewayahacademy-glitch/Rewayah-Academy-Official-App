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

  // FN-028 (01/11/2026) : l'avis de fin de seance.
  group('seance_terminee', () {
    const Map<String, dynamic> base = <String, dynamic>{
      'classe': 'Classe Al-Fajr',
      'debut_local': '2026-11-01T18:00:00',
    };
    String titre(Map<String, dynamic> params) => contenuNotificationPour(
      'seance_terminee',
      <String, dynamic>{...base, ...params},
    ).titre.replaceAll('\u00a0', ' ');

    test(
      'enseignant : presents au pluriel slang, 0, 1 et 2, FR et AR',
      () async {
        final Map<AppLocale, List<String>> attendus = <AppLocale, List<String>>{
          AppLocale.fr: <String>[
            '0 élève présent sur 3.',
            '1 élève présent sur 3.',
            '2 élèves présents sur 3.',
          ],
          AppLocale.ar: <String>[
            'الطلاب الحاضرون: \u20680\u2069 من أصل \u20683\u2069.',
            'الطلاب الحاضرون: \u20681\u2069 من أصل \u20683\u2069.',
            'الطلاب الحاضرون: \u20682\u2069 من أصل \u20683\u2069.',
          ],
        };
        for (final MapEntry<AppLocale, List<String>> e in attendus.entries) {
          await LocaleSettings.setLocale(e.key);
          for (int n = 0; n <= 2; n++) {
            final String texte = titre(<String, dynamic>{
              'portee': 'classe',
              'presents': n,
              'inscrits': 3,
              'cahier_depose': false,
            });
            expect(texte, contains(e.value[n]), reason: '${e.key} $n');
            expect(
              texte,
              contains(t.notifications.evenements.seanceTermineeCahierAttend),
            );
          }
        }
      },
    );

    test('enseignant : cahier deja depose', () {
      final String texte = titre(<String, dynamic>{
        'portee': 'classe',
        'presents': 2,
        'inscrits': 2,
        'cahier_depose': true,
      });
      expect(
        texte,
        'La séance de Classe Al-Fajr du ${quandDepuis(base)!.replaceAll('\u00a0', ' ')} '
        'est terminée. 2 élèves présents sur 2. Cahier déposé, merci.',
      );
    });

    test('eleve et tuteur : le Travail a preparer selon le partage', () {
      for (final String portee in <String>['soi', 'foyer']) {
        final String partage = titre(<String, dynamic>{
          'portee': portee,
          'travail_etat': 'partage',
          'travail': 'Réviser la page 5',
        });
        expect(partage, endsWith('Travail à préparer : Réviser la page 5'));
        final String aucun = titre(<String, dynamic>{
          'portee': portee,
          'travail_etat': 'aucun',
        });
        expect(aucun, endsWith('Aucun travail à préparer.'));
        // Partage ferme : rien n'est dit du travail, jamais « aucun ».
        final String ferme = titre(<String, dynamic>{
          'portee': portee,
          'travail_etat': 'non_partage',
        });
        expect(ferme, endsWith('est terminée.'));
        expect(ferme, isNot(contains('travail')));
        expect(ferme, isNot(contains('Travail')));
      }
    });

    test('la ligne du serveur passe le filtre : nom de la Classe, comptes, '
        'cahier, travail ; jamais un identifiant', () {
      final NotificationTuteur enseignant = notificationDepuis(
        _ligne(
          'seance_terminee',
          destination: '/enseignant/journee',
          params: <String, dynamic>{
            'groupe_id': '00000000-0000-0000-0000-000000000001',
            'session_id': '00000000-0000-0000-0000-000000000002',
            'portee': 'classe',
            'classe': 'Classe Al-Fajr',
            'debut_local': '2026-11-01T18:00:00',
            'presents': 1,
            'inscrits': 1,
            'cahier_depose': true,
          },
        ),
        titrePour: contenuNotificationPour,
      );
      final String titreEnseignant = enseignant.titre.replaceAll('\u00a0', ' ');
      expect(titreEnseignant, contains('Classe Al-Fajr'));
      expect(titreEnseignant, contains('1 élève présent sur 1.'));
      expect(titreEnseignant, endsWith('Cahier déposé, merci.'));
      expect(titreEnseignant, isNot(contains('0000')));

      final NotificationTuteur eleve = notificationDepuis(
        _ligne(
          'seance_terminee',
          params: <String, dynamic>{
            'session_id': '00000000-0000-0000-0000-000000000002',
            'portee': 'soi',
            'classe': 'Classe Al-Fajr',
            'debut_local': '2026-11-01T18:00:00',
            'travail_etat': 'partage',
            'travail': 'Réviser la page 5',
          },
        ),
        titrePour: contenuNotificationPour,
      );
      expect(
        eleve.titre.replaceAll('\u00a0', ' '),
        endsWith('Travail à préparer : Réviser la page 5'),
      );
    });

    test('elision devant un nom de Classe qui commence par une voyelle', () {
      final String texte = contenuNotificationPour(
        'seance_terminee',
        const <String, dynamic>{
          'portee': 'soi',
          'classe': 'Al-Fajr',
          'debut_local': '2026-11-01T18:00:00',
        },
      ).titre;
      expect(texte, startsWith("La séance d'Al-Fajr du "));
    });

    test('sans classe ni heure : la phrase generale, jamais un code', () {
      final String texte = contenuNotificationPour(
        'seance_terminee',
        const <String, dynamic>{'portee': 'soi'},
      ).titre;
      expect(texte, t.notifications.evenements.seanceTerminee);
      expect(texte, isNot(contains('seance_terminee')));
    });
  });

  group('FN-115b : remboursement et contestation', () {
    test('la famille et la direction ne lisent pas la meme phrase', () {
      final e = t.notifications.evenements;
      expect(
        contenuNotificationPour(
          'remboursement_effectue',
          const <String, dynamic>{'portee': 'foyer'},
        ).titre,
        e.remboursementEffectue,
      );
      expect(
        contenuNotificationPour(
          'remboursement_effectue',
          const <String, dynamic>{'portee': 'direction'},
        ).titre,
        e.remboursementEffectueDirection,
      );
      expect(
        contenuNotificationPour('litige_ouvert', const <String, dynamic>{
          'portee': 'foyer',
        }).titre,
        e.litigeOuvert,
      );
      expect(
        contenuNotificationPour('litige_ouvert', const <String, dynamic>{
          'portee': 'direction',
        }).titre,
        e.litigeOuvertDirection,
      );
    });

    test('la cloture dit l issue a la famille', () {
      final e = t.notifications.evenements;
      expect(
        contenuNotificationPour('litige_clos', const <String, dynamic>{
          'portee': 'foyer',
          'issue': 'gagne',
        }).titre,
        e.litigeClosGagne,
      );
      expect(
        contenuNotificationPour('litige_clos', const <String, dynamic>{
          'portee': 'foyer',
          'issue': 'perdu',
        }).titre,
        e.litigeClosPerdu,
      );
      expect(
        contenuNotificationPour('litige_clos', const <String, dynamic>{
          'portee': 'direction',
          'issue': 'perdu',
        }).titre,
        e.litigeClosDirection,
      );
    });

    test(
      'une suspension dit sa cause : remboursement, contestation ou impaye',
      () {
        final e = t.notifications.evenements;
        expect(
          contenuNotificationPour(
            'acces_suspendu_paiement',
            const <String, dynamic>{'cause': 'remboursement'},
          ).titre,
          e.accesSuspenduRemboursement,
        );
        expect(
          contenuNotificationPour(
            'acces_suspendu_paiement',
            const <String, dynamic>{'cause': 'litige'},
          ).titre,
          e.accesSuspenduLitige,
        );
        expect(
          contenuNotificationPour(
            'acces_suspendu_paiement',
            const <String, dynamic>{},
          ).titre,
          e.accesSuspenduPaiement,
        );
      },
    );
  });
}
