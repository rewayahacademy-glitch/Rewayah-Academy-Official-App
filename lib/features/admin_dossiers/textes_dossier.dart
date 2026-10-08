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

/// Le corps de la confirmation de validation : « Le dossier de/d'{nom} sera
/// validé… », elision choisie par la meme fonction que [ouvrirDossier].
String corpsValidation(String nom, {required bool activation}) => activation
    ? (elide(nom)
          ? t.dossiers.validation.corpsActivationElide(nom: nom)
          : t.dossiers.validation.corpsActivation(nom: nom))
    : (elide(nom)
          ? t.dossiers.validation.corpsDocumentaireElide(nom: nom)
          : t.dossiers.validation.corpsDocumentaire(nom: nom));

/// Le nom affiche, ou « Dossier sans nom disponible ».
String nomOuDefaut(String nom) =>
    nom.trim().isEmpty ? t.dossiers.file.sansNom : nom;

String _deux(int n) => n.toString().padLeft(2, '0');

/// « dd/MM/yyyy à HH:mm (UTC) ». Toujours en UTC, et dit : sans paquet de
/// fuseaux (pubspec interdit), convertir vers un fuseau IANA serait faux
/// (AD-BR-19, Q-AD5-1). Espaces insecables, sauf autour de la date : « à
/// HH:mm (UTC) » passe en bloc, la date en un autre, et la ligne se coupe
/// entre les deux plutot qu'au milieu de « 15:18 » (relecture COUPE-MOTS-1,
/// 320 px a 200 %).
/// Sans date (valeur absente), « Date de dépôt indisponible » (AD-11).
String dateRevue(DateTime? utc) {
  if (utc == null) return t.dossiers.revue.dateIndisponible;
  final DateTime u = utc.toUtc();
  final String date = t.dossiers.file.dateChiffres(
    jour: _deux(u.day),
    mois: _deux(u.month),
    annee: '${u.year}',
  );
  final String texte = t.dossiers.file.dateHeure(
    date: date,
    heure: t.dossiers.file.heureChiffres(
      heures: _deux(u.hour),
      minutes: _deux(u.minute),
    ),
    zone: t.dossiers.file.zoneUtc,
  );
  String colle(String s) => s.replaceAll(' ', '\u00a0');
  final int i = texte.indexOf(date);
  if (i < 0) return colle(texte);
  // Les espaces qui touchent la date restent secables.
  String avant = colle(texte.substring(0, i));
  String apres = colle(texte.substring(i + date.length));
  if (avant.endsWith('\u00a0')) {
    avant = '${avant.substring(0, avant.length - 1)} ';
  }
  if (apres.startsWith('\u00a0')) apres = ' ${apres.substring(1)}';
  return '$avant$date$apres';
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
