// HORLOGE-ET-LIEU (revue du 13/11/2026) : la ligne de repli de la classe (quand
// ni l'identifiant de la classe ni l'heure de l'enseignant ne sont connus) dit
// « Heure de La Mecque : 21:00 », jamais « Heure de la classe : 21:00 Riyadh ».

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_horloge/session_clock_vm.dart';
import 'package:rewayah_academy/features/accueil_famille/bloc_seance.dart';

import '../../fixtures/tuteur/faux_seances_famille.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  final DateTime debut = DateTime.utc(2026, 10, 31, 18);

  String? repli(HorlogeAffichee classe) => AffichageSeance.depuis(
    seanceFictive(debutUtc: debut, heureGroupe: classe),
    maintenantServeurUtc: debut.subtract(const Duration(hours: 2)),
  ).heureClasse;

  test('la classe a l\'heure de La Mecque : « Heure de La Mecque »', () {
    final String? texte = repli(
      const HorlogeAffichee(
        fuseauIana: 'Asia/Riyadh',
        libelleVille: 'Riyadh',
        heureLocaleRendue: '21:00',
        dateLocaleRendue: 'Samedi 31 octobre',
      ),
    );
    expect(texte, 'Heure de La Mecque : 21:00');
    expect(texte, isNot(contains('Riyad')));
    expect(texte, isNot(contains('de la classe')));
  });

  test(
    'une classe restee dans un autre fuseau garde « Heure de la classe »',
    () {
      final String? texte = repli(
        const HorlogeAffichee(
          fuseauIana: 'Europe/Paris',
          libelleVille: 'Paris',
          heureLocaleRendue: '19:00',
          dateLocaleRendue: 'Samedi 31 octobre',
        ),
      );
      expect(texte, 'Heure de la classe : 19:00 Paris');
    },
  );
}
