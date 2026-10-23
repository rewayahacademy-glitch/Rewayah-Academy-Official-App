// CLASSES-DUREE (23/10/2026) : les phrases du refus de deplacement d'une classe.
// Une phrase par motif, en francais et en arabe, sans duree en dur (la duree
// d'une classe vient de son offre ou des reglages, jusqu'a 240 minutes), sans
// texte SQL, et une phrase propre a la feuille « Seuil maximal ».
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/affectation_refusee.dart';
import 'package:rewayah_academy/features/admin_groupes/refus_deplacement_libelles.dart';

void main() {
  for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
    test('phrases du refus de deplacement (${langue.languageCode})', () async {
      await LocaleSettings.setLocale(langue);
      addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));

      final Set<String> distinctes = <String>{};
      for (final MotifRefusAffectation motif in <MotifRefusAffectation>[
        MotifRefusAffectation.enseignantIndisponible,
        MotifRefusAffectation.genreIncompatible,
        MotifRefusAffectation.plafond,
        MotifRefusAffectation.nonDisponible,
        MotifRefusAffectation.chevauchementClasse,
        MotifRefusAffectation.chevauchementSeance,
      ]) {
        final String phrase = phraseRefusDeplacement(motif);
        expect(phrase, isNotEmpty);
        distinctes.add(phrase);
        expect(phrase, isNot(contains('90')));
        expect(phrase, isNot(contains('60')));
        expect(phrase, isNot(contains('SQL')));
      }
      expect(distinctes, hasLength(6));

      final String seuil = phraseRefusSeuil();
      expect(seuil, isNotEmpty);
      expect(distinctes, isNot(contains(seuil)));
    });
  }
}
