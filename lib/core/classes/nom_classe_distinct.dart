/// R16 (`DECISION-CLASSES-SIMULTANEES-2026-10-10.md`) : nommer une classe
/// sans ambiguite quand plusieurs classes paralleles partagent la meme
/// categorie, les memes jours et la meme heure (30 classes « Garcons
/// debutants, lundi 18 h »).
///
/// Le discriminant vient du serveur, jamais d'un calcul de l'ecran : le
/// numero de la classe dans sa famille de classes paralleles, sinon son code
/// court, sinon le titre de son enseignant. Sans aucun des trois, le nom
/// reste tel quel : l'ecran n'invente pas de numero (un rang calcule sur une
/// page ou un filtre changerait d'une lecture a l'autre).
///
/// **Ecrans de la direction, de l'enseignant et du controleur seulement.**
/// La famille ne voit que sa classe et le titre de son enseignant (C-05,
/// R16) : jamais le nombre de classes paralleles. Aucun ecran de famille
/// n'appelle cette fonction.
library;

import '../i18n/strings.g.dart';

/// « Garcons, lundi 18 h · n° 4 », « ... · B7 », « ... · avec Sayyid
/// Ibrahim », ou le [libelle] seul quand le serveur ne rend aucun
/// discriminant.
String nomClasseDistinct(
  String libelle, {
  int? numero,
  String? code,
  String? enseignant,
}) {
  final c = t.commun.classeDistincte;
  if (numero != null) {
    return c.numero(libelle: libelle, numero: '$numero');
  }
  final String? codeLu = code?.trim();
  if (codeLu != null && codeLu.isNotEmpty) {
    return c.code(libelle: libelle, code: codeLu);
  }
  final String? enseignantLu = enseignant?.trim();
  if (enseignantLu != null && enseignantLu.isNotEmpty) {
    return c.enseignant(libelle: libelle, enseignant: enseignantLu);
  }
  return libelle;
}
