import '../i18n/strings.g.dart';

/// Les lectures (riwayat) que la direction peut preciser sur un document :
/// celles que le module des candidatures propose d'emblee, avec les memes
/// intitules (`recrutement.parcours.q.riwayat`). Un seul vocabulaire.
const List<String> lecturesCoran = <String>['hafs', 'warsh', 'qalun', 'shuba'];

/// Le nom d'une lecture ; un code inconnu est rendu tel quel, jamais devine.
String libelleLectureCoran(String code) {
  final o = t.recrutement.parcours.q.riwayat.options;
  return switch (code) {
    'hafs' => o.hafs.libelle,
    'warsh' => o.warsh.libelle,
    'qalun' => o.qalun.libelle,
    'shuba' => o.shuba.libelle,
    _ => code,
  };
}
