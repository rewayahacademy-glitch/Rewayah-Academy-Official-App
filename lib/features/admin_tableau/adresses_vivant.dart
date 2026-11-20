// VIVANT : les adresses qu'ouvrent les cases de l'accueil de la direction.
//
// Contrat de navigation §2 : une case qui porte un nombre ouvre la liste deja
// filtree, le filtre dans l'adresse (un rechargement rend le meme ecran).
import '../../core/candidature/modeles_candidature.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/router/routes.dart';
import '../admin_candidatures/adresse_candidatures.dart';

/// L'adresse de la liste des candidatures, deja filtree par [filtre].
String adresseCandidaturesFiltree(FiltreCandidatures filtre) => Uri(
  path: Routes.adminPersonnesCandidatures,
  queryParameters: requeteEnAdresse(RequeteCandidatures(filtre: filtre)),
).toString();

/// Le filtre d'une file par etat : en cours, hors pause, comme la puce de la
/// liste (`files_candidatures.dart`), pour que la liste ouverte ait la
/// longueur du nombre affiche.
FiltreCandidatures filtreEtat(EtatCandidature etat) => FiltreCandidatures(
  etat: etat,
  enPause: false,
  issue: IssueCandidature.enCours,
);

/// La requete de la file d'un etat (meme tri que la liste).
RequeteCandidatures requeteEtat(EtatCandidature etat) =>
    RequeteCandidatures(filtre: filtreEtat(etat));

/// Le filtre « piece a valider » : en cours, hors pause (cle serveur
/// `pieceEnAttente`).
const FiltreCandidatures filtrePieces = FiltreCandidatures(
  pieceEnAttente: true,
  enPause: false,
  issue: IssueCandidature.enCours,
);

/// La requete de la file des pieces a valider (meme tri que la liste).
const RequeteCandidatures requetePieces = RequeteCandidatures(
  filtre: filtrePieces,
);

/// L'adresse du dossier d'une candidature, ouvert dans la file des pieces :
/// le dossier sait dans quelle file il se trouve et propose le suivant.
String adresseDossierDansLesPieces(String reference) =>
    Routes.adminPersonnesCandidaturePour(
      reference,
      fileDeLaListe: requeteEnAdresse(requetePieces),
    );
