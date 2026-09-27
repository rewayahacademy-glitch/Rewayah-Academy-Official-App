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
/// Sans date (valeur absente), « Date de dépôt indisponible » (AD-11).
String dateRevue(DateTime? utc) {
  if (utc == null) return t.dossiers.revue.dateIndisponible;
  final DateTime u = utc.toUtc();
  final String texte = t.dossiers.file.dateHeure(
    date: t.dossiers.file.dateChiffres(
      jour: _deux(u.day),
      mois: _deux(u.month),
      annee: '${u.year}',
    ),
    heure: t.dossiers.file.heureChiffres(
      heures: _deux(u.hour),
      minutes: _deux(u.minute),
    ),
    zone: t.dossiers.file.zoneUtc,
  );
  return texte.replaceAll(' ', ' ');
}

/// Le titre de la revue : « Dossier de/d'{nom} », ou « Dossier sans nom
/// disponible » seul quand aucun nom n'est lisible.
String titreRevue(String nom) =>
    nom.trim().isEmpty ? t.dossiers.file.sansNom : titreDossier(nom.trim());

/// Le libelle d'un type de piece (cles existantes du depot de piece). Le type
/// « autre » n'a pas de texte propre : le titre de la carte le porte.
String libelleTypePiece(TypePiece type) => switch (type) {
  TypePiece.carteIdentite => t.kyc.carteIdentite,
  TypePiece.passeport => t.kyc.passeport,
  TypePiece.titreSejour => t.kyc.titreSejour,
  TypePiece.autre => t.dossiers.revue.piece,
};

/// Le libelle d'un accord (memes cles que les informations legales).
String libelleAccord(SorteContrat sorte) => switch (sorte) {
  SorteContrat.conditionsTuteur => t.compte.tuteur.pageLegal.conditionsTuteur,
  SorteContrat.contratEnseignant => t.compte.tuteur.pageLegal.contratEnseignant,
  SorteContrat.accuseEnregistrementControle =>
    t.compte.tuteur.pageLegal.accuseEnregistrement,
};

/// Le type de dossier : toujours « Enseignant ». K-47 (HL-A-6) : la piece
/// et la validation ne concernent que l'enseignant, seul present dans la
/// file ADM-02 ; le tuteur n'y entre jamais.
String typeDossier() => t.compte.roles.teacher;
