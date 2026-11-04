import '../../core/domain/enums.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';

/// Vrai quand « de » s'elide devant [nom] : la regle unique de
/// `core/i18n/elision.dart` (voyelle, accentuee ou non ; jamais devant h,
/// « de Hana » ; « y » devant une voyelle est une consonne, « de Yusuf »).
bool elide(String nom) => commenceParVoyelle(nom);

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

/// L'heure locale d'un instant : « 14:05 », en chiffres seuls, comme
/// `heureMinute` ailleurs dans l'application. Isoler heures et minutes
/// chacune de son cote (l'ancien texte arabe `heureChiffres`) les faisait
/// permuter dans une phrase arabe : « 56:06 » pour 06:56 (capture L5).
String _heure(DateTime local) => '${_deux(local.hour)}:${_deux(local.minute)}';

/// « dd/MM/yyyy à HH:mm », a l'heure de l'appareil.
///
/// L5 des listes (pilote, 02/11/2026) : **une seule source d'heure**. La
/// revue disait l'heure UTC (« 02:39 (UTC) ») quand l'Espace de traitement
/// et le reste de l'application disent l'heure de l'appareil (« 03:39 ») :
/// le meme depot lisait deux heures. L'heure de l'appareil partout, sans
/// suffixe : `DateTime.toLocal` n'a besoin d'aucun paquet de fuseaux (la
/// reserve AD-BR-19 visait la conversion vers un fuseau IANA nomme, qui n'a
/// pas lieu ici). Espaces insecables, sauf autour de la date : « à HH:mm »
/// passe en bloc, la date en un autre, et la ligne se coupe entre les deux
/// plutot qu'au milieu de « 15:18 » (relecture COUPE-MOTS-1, 320 px a 200 %).
/// Sans date (valeur absente), « Date de dépôt indisponible » (AD-11).
String dateRevue(DateTime? instant) {
  if (instant == null) return t.dossiers.revue.dateIndisponible;
  final DateTime l = instant.toLocal();
  final String date = t.dossiers.file.dateChiffres(
    jour: _deux(l.day),
    mois: _deux(l.month),
    annee: '${l.year}',
  );
  final String texte = t.commun.formats.dateHeure(date: date, heure: _heure(l));
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

/// Depuis quand un dossier ou une demande attend, dans une liste :
/// « Aujourd'hui · 14:05 », « Hier · 09:12 », sinon « 31 oct. · 22:32 »
/// (« 31 oct. 2025 · 22:32 » une autre annee). A l'heure de l'appareil,
/// comme [dateRevue] : la liste et le dossier disent la meme heure (L5).
String quandDepuis(DateTime instant, DateTime maintenant) {
  final DateTime l = instant.toLocal();
  final DateTime m = maintenant.toLocal();
  // Des jours de calendrier, comptes en UTC : un passage a l'heure d'ete
  // (une journee de 23 heures) ne fait pas d'« Hier » un « Aujourd'hui ».
  final int ecart = DateTime.utc(
    m.year,
    m.month,
    m.day,
  ).difference(DateTime.utc(l.year, l.month, l.day)).inDays;
  final String mois = t.historique.moisCourts[l.month - 1];
  final String jour = switch (ecart) {
    <= 0 => t.admin.traitement.groupeAujourdhui,
    1 => t.admin.traitement.groupeHier,
    _ when l.year == m.year => t.historique.dateCourteSansAnnee(
      jour: l.day,
      mois: mois,
    ),
    _ => t.historique.dateCourte(jour: l.day, mois: mois, annee: l.year),
  };
  return '$jour · ${_heure(l)}';
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
  SorteContrat.codeConduiteEnseignant => t.codeConduite.titre,
};

/// Le type de dossier : toujours « Enseignant ». K-47 (HL-A-6) : la piece
/// et la validation ne concernent que l'enseignant, seul present dans la
/// file ADM-02 ; le tuteur n'y entre jamais.
String typeDossier() => t.compte.roles.teacher;
