import '../fichiers/formats_admis.dart';
import '../i18n/strings.g.dart';
import 'echec_depot.dart';

/// La phrase d'un depot qui n'a pas abouti (PE-B10, K-59) : la cause vraie,
/// et ce que la personne peut faire maintenant. Une seule source pour la
/// piece d'identite et la photo du candidat. Jamais « connexion » pour un
/// refus de Rewayah, jamais « reessayez » pour une cause qu'un nouvel essai
/// ne leve pas (format, taille, contenu, session, refus).
String phraseEchecDepot(Object erreur, {required SorteFichier sorte}) {
  final f = t.fichiers;
  return switch (causeEchecDepot(erreur)) {
    CauseEchecDepot.format => switch (sorte) {
      SorteFichier.piece => t.kyc.erreurFormat,
      SorteFichier.photo => f.photoFormat,
    },
    CauseEchecDepot.taille => f.tropLourd(taille: '${sorte.tailleMaxMo}'),
    CauseEchecDepot.contenu => t.kyc.contenuNonConforme,
    CauseEchecDepot.reseau => f.echecReseau,
    CauseEchecDepot.indisponible => f.echecIndisponible,
    CauseEchecDepot.session => f.echecSession,
    CauseEchecDepot.refuse => f.echecRefus,
    CauseEchecDepot.autre => f.echecAutre,
  };
}
