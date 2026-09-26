import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';

const String _voyelles = 'aeiouàâäéèêëîïôöùûüAEIOUÀÂÄÉÈÊËÎÏÔÖÙÛÜ';

/// Vrai quand « de » s'elide devant [nom] : voyelle, accentuee ou non. Ni Y
/// ni H (« de Yusuf », « de Hana »).
bool elide(String nom) => nom.isNotEmpty && _voyelles.contains(nom[0]);

/// « Ouvrir le dossier de/d'{nom} ».
String ouvrirDossier(String nom) => elide(nom)
    ? t.dossiers.file.ouvrirElide(nom: nom)
    : t.dossiers.file.ouvrirDe(nom: nom);

/// « Dossier de/d'{nom} ».
String titreDossier(String nom) => elide(nom)
    ? t.dossiers.detail.titreElide(nom: nom)
    : t.dossiers.detail.titreDe(nom: nom);

/// Le nom affiche, ou « Dossier sans nom disponible ».
String nomOuDefaut(String nom) =>
    nom.trim().isEmpty ? t.dossiers.file.sansNom : nom;

String _deux(int n) => n.toString().padLeft(2, '0');

/// « dd/MM/yyyy à HH:mm (UTC) ». Toujours en UTC, et dit : sans paquet de
/// fuseaux (pubspec interdit), convertir vers un fuseau IANA serait faux
/// (AD-BR-19, Q-AD5-1). Espaces insecables : la date passe en bloc.
String dateRevue(DateTime utc) {
  final DateTime u = utc.toUtc();
  final String texte = t.dossiers.file.dateHeure(
    date: '${_deux(u.day)}/${_deux(u.month)}/${u.year}',
    heure: '${_deux(u.hour)}:${_deux(u.minute)}',
    zone: 'UTC',
  );
  return texte.replaceAll(' ', ' ');
}

/// Le type de dossier : toujours « Enseignant » ou « Tuteur ».
String typeDossier(AppRole role) => switch (role) {
  AppRole.teacher => t.compte.roles.teacher,
  _ => t.compte.roles.guardian,
};
