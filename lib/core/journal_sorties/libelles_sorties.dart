import '../i18n/strings.g.dart';
import '../tc_groupe/libelles_tc_groupe.dart';
import '../tc_horloge/mon_horloge.dart';
import 'port_journal_sorties.dart';

/// HORS-SALLE-2 : les mises en mots du journal des sorties, pour le rapport
/// du parent et la ligne de l'enseignant. Heures dans le fuseau de la
/// personne ([heureChezMoi]), durees insecables (DUREE-INSECABLE-1).
abstract final class LibellesSorties {
  /// « 45 s », « 4 min », « 1 min 30 s » : exact a la seconde, pour qu'une
  /// duree ne contredise jamais les heures « De 18:20 a 18:21 ».
  static String duree(int secondes) => LibellesGroupe.insecable(
    secondes < 60
        ? t.journalSorties.rapport.secondes(n: '$secondes')
        : secondes % 60 == 0
        ? t.journalSorties.rapport.minutes(n: '${secondes ~/ 60}')
        : t.journalSorties.rapport.minutesSecondes(
            m: '${secondes ~/ 60}',
            s: '${secondes % 60}',
          ),
  );

  /// La meme duree, affichee seule (ancree en interface de droite a gauche).
  static String dureeSeule(int secondes) =>
      LibellesGroupe.ancreSens(duree(secondes));

  /// « 3 sorties ».
  static String nombre(int n) =>
      LibellesGroupe.insecable(t.journalSorties.rapport.nombre(n: n));

  /// La ligne de l'enseignant : « 3 sorties, 4 min ».
  static String resume(ResumeSorties r) => t.journalSorties.rapport.resume(
    nombre: nombre(r.nombre),
    duree: duree(r.totalSecondes),
  );

  /// « De 20:12 à 20:13 ».
  static String plage(SortieApp s) => t.journalSorties.rapport.plage(
    debut: heureChezMoi(s.sortieLe),
    fin: heureChezMoi(s.retourLe),
  );
}
