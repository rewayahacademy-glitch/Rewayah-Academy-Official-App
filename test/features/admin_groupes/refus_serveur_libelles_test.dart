// C1 (02/11/2026, UX-019) : un echec venu du serveur dans la page des classes
// se dit en mots, jamais par le texte brut de l'exception ni par un code.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_groupes/refus_serveur_libelles.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

void main() {
  for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
    group('Echec serveur des classes (${langue.name})', () {
      setUp(() => LocaleSettings.setLocale(langue));

      test('eleve deja en classe : la phrase qui dit quoi faire', () {
        final String phrase = phraseEchecServeurClasse(
          const PostgrestException(
            message: 'cet eleve appartient deja a un groupe actif',
            code: 'P0001',
            details: 'Bad Request',
          ),
        );
        expect(phrase, t.admin.groupes.c1.eleveDejaEnClasse);
        for (final String brut in <String>[
          'P0001',
          'groupe',
          'Bad Request',
          'code',
          'eleve',
        ]) {
          expect(phrase, isNot(contains(brut)));
        }
      });

      test('chaque refus connu a sa phrase', () {
        final c1 = t.admin.groupes.c1;
        final Map<String, String> attendus = <String, String>{
          "cet eleve n'existe pas ou son compte n'est pas valide":
              c1.eleveInvalide,
          "cet eleve n'est pas membre actif de ce groupe": c1.eleveNonMembre,
          'groupe introuvable ou deja cloture': c1.classeDejaClose,
          'un motif est requis pour cloturer un groupe': c1.motifManquant,
          "cloture de groupe reservee a l'administration": c1.reservee,
        };
        attendus.forEach((String message, String phrase) {
          expect(
            phraseEchecServeurClasse(
              PostgrestException(message: message, code: 'P0001'),
            ),
            phrase,
          );
        });
      });

      test('refus inconnu : phrase generique, sans le texte du serveur', () {
        final String phrase = phraseEchecServeurClasse(
          const PostgrestException(message: 'xyz interne', code: 'P0001'),
        );
        expect(phrase, t.admin.groupes.c1.refusInconnu);
        expect(phrase, isNot(contains('xyz')));
      });

      test('42501 : action reservee', () {
        expect(
          phraseEchecServeurClasse(
            const PostgrestException(
              message: 'permission denied',
              code: '42501',
            ),
          ),
          t.admin.groupes.c1.reservee,
        );
      });

      test('erreur hors serveur (reseau) : le serveur n\'a pas repondu', () {
        expect(
          phraseEchecServeurClasse(
            Exception('ClientException: Failed to fetch'),
          ),
          t.admin.groupes.c1.connexion,
        );
      });
    });
  }
}
