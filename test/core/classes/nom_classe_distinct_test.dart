// ECHELLE-CORR-ECRANS-1, R16 : une classe se nomme sans ambiguite parmi ses
// classes paralleles, cote direction, enseignant (remplacements) et
// controleur (mission). Le discriminant vient du serveur : numero dans la
// famille de classes, sinon code court, sinon titre de l'enseignant.
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/classes/nom_classe_distinct.dart';
import 'package:rewayah_academy/core/enseignant/absence_remplacement.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/controleur/mission_controle.dart';

const String _nom = 'Garçons débutants, lundi 18 h';

void main() {
  test('numero, sinon code, sinon enseignant, sinon le nom seul', () {
    expect(nomClasseDistinct(_nom, numero: 4), '$_nom · n°\u00a04');
    expect(nomClasseDistinct(_nom, code: 'B7'), '$_nom · B7');
    expect(
      nomClasseDistinct(_nom, enseignant: 'Sayyid Ibrahim'),
      '$_nom · avec Sayyid Ibrahim',
    );
    expect(
      nomClasseDistinct(_nom, numero: 4, code: 'B7', enseignant: 'X'),
      '$_nom · n°\u00a04',
    );
    expect(nomClasseDistinct(_nom, code: '  ', enseignant: ''), _nom);
  });

  test('30 classes de meme nom : 30 noms distincts', () {
    expect(<String>{
      for (int n = 1; n <= 30; n++) nomClasseDistinct(_nom, numero: n),
    }, hasLength(30));
  });

  test('arabe : chaque morceau isole (U+2068 / U+2069)', () async {
    await LocaleSettings.setLocale(AppLocale.ar);
    addTearDown(() => LocaleSettings.setLocale(AppLocale.fr));
    final String nom = nomClasseDistinct(_nom, numero: 4);
    expect(nom, contains('\u2068$_nom\u2069'));
    expect(nom, contains('\u20684\u2069'));
  });

  test('remplacement : le nom de la Classe porte son numero', () {
    final DateTime debut = DateTime(2026, 10, 12, 18);
    final List<String> noms = <String>[
      for (int n = 1; n <= 30; n++)
        OffreRemplacement(
          seanceId: 's$n',
          classe: _nom,
          debut: debut,
          fin: debut.add(const Duration(hours: 1)),
          nbEleves: 5,
          numeroDansFamille: n,
        ).classeDistincte,
    ];
    expect(noms.toSet(), hasLength(30));
    // Sans numero rendu : le nom seul, rien d'invente.
    expect(
      OffreRemplacement(
        seanceId: 's',
        classe: _nom,
        debut: debut,
        fin: debut,
        nbEleves: 5,
      ).classeDistincte,
      _nom,
    );
  });

  test('mission du controleur : le nom de la Classe porte son numero', () {
    final DateTime debut = DateTime(2026, 10, 12, 18);
    MissionControle mission(int? n, {String? code}) => MissionControle(
      seanceId: 's',
      classe: _nom,
      enseignant: 'Sayyid Ibrahim',
      nombreEleves: 5,
      debut: debut,
      finPrevue: debut.add(const Duration(hours: 1)),
      etat: EtatMissionControle.enDirect,
      numeroDansFamille: n,
      codeCourt: code,
    );
    expect(mission(12).classeDistincte, '$_nom · n°\u00a012');
    expect(mission(null, code: 'C3').classeDistincte, '$_nom · C3');
    expect(mission(null).classeDistincte, _nom);
  });
}
