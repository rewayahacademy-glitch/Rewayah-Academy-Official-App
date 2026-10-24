// Le port de l'inscription du candidat : `PortInscriptionCandidat` (`CAND-04`,
// `CAND-BR-17`, `docs/current/CANDIDATURES/CONTRAT_PORTS_CANDIDATURES.md`,
// section 3 quater). Il sert les deux portes d'un meme compte : le lien public
// du site (sans code) et l'invitation (avec code). Seule la provenance differe.
//
// Appele par une session **avec adresse et sans profil**. Deux lectures et un
// geste :
//
// - [PortInscriptionCandidat.ouverte] : la cle de mise en ligne de
//   l'inscription sans code et la version de confidentialite que le serveur
//   attend. Jamais l'etat du plafond horaire (CAND-F03) ;
// - [PortInscriptionCandidat.inscrire] : cree le compte et la candidature.
//
// **Reponse neutre (CAND-F03).** Au-dela du plafond horaire, le serveur rend
// exactement `acceptee`, comme pour un succes, sans rien ecrire. Le port ne
// donne donc aucun moyen de les distinguer, et l'ecran n'en cherche pas : il
// ne dit jamais qu'une adresse ou un telephone est deja connu.
//
// Les refus metier sont **des reponses** ([ResultatInscriptionCandidat]), pas
// des pannes : l'ecran dit chacun en mots, avec quoi faire (K-59). Une session
// qui a deja un profil, ou sans session, leve [PermissionInsuffisante]. Un lot
// serveur absent leve `CapaciteIndisponible('CAND-BR-17')`. Une panne de
// reseau est [HorsLigneCandidature] : ce qui a ete envoye est alors non
// confirme (D5).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capacites/capacite_indisponible.dart';
import 'port_ma_candidature.dart';

/// L'identifiant de la dependance serveur, pour la trace et les tests : jamais
/// affiche.
const String dependanceInscriptionCandidat = 'CAND-BR-17';

/// Ce que le serveur dit de l'inscription, lu avant de la proposer.
@immutable
class OuvertureInscriptionCandidat {
  /// Cree la lecture.
  const OuvertureInscriptionCandidat({
    required this.ouverte,
    this.versionConfidentialite,
  });

  /// Vrai quand l'inscription **sans code** est ouverte (cle de mise en ligne,
  /// fausse tant que le directeur ne l'ouvre pas).
  final bool ouverte;

  /// La version de la politique de confidentialite que le serveur attend, ou
  /// `null` quand il n'en publie pas.
  final String? versionConfidentialite;
}

/// Ce que rend `inscrire_candidat`.
sealed class ResultatInscriptionCandidat {
  const ResultatInscriptionCandidat();
}

/// L'inscription est acceptee. **Aussi au-dela du plafond horaire** : le
/// serveur rend alors la meme reponse, sans compte ni candidature. Seule la
/// relecture du profil dit si le compte existe.
final class InscriptionAcceptee extends ResultatInscriptionCandidat {
  /// Cree le resultat.
  const InscriptionAcceptee();
}

/// L'inscription sans code n'est pas ouverte.
final class InscriptionFermee extends ResultatInscriptionCandidat {
  /// Cree le resultat.
  const InscriptionFermee();
}

/// L'adresse n'est pas confirmee : aucune candidature n'est creee.
final class InscriptionCourrielNonConfirme extends ResultatInscriptionCandidat {
  /// Cree le resultat.
  const InscriptionCourrielNonConfirme();
}

/// Le code d'invitation n'est pas reconnu (inconnu, revoque, ou emis pour une
/// autre adresse : le serveur ne les distingue pas).
final class InscriptionCodeInconnu extends ResultatInscriptionCandidat {
  /// Cree le resultat.
  const InscriptionCodeInconnu();
}

/// Le code d'invitation a deja servi.
final class InscriptionCodeDejaUtilise extends ResultatInscriptionCandidat {
  /// Cree le resultat.
  const InscriptionCodeDejaUtilise();
}

/// Le code d'invitation a expire.
final class InscriptionCodeExpire extends ResultatInscriptionCandidat {
  /// Cree le resultat.
  const InscriptionCodeExpire();
}

/// Des champs manquent ou ne sont pas valables : [champs] les nomme
/// (`prenom`, `nom`, `genre`, `langue`, `telephone`).
final class InscriptionInvalide extends ResultatInscriptionCandidat {
  /// Cree le resultat.
  const InscriptionInvalide(this.champs);

  /// Les champs refuses, dans l'ordre du serveur.
  final List<String> champs;
}

/// L'accord de confidentialite n'a pas ete envoye.
final class InscriptionConfidentialiteRequise
    extends ResultatInscriptionCandidat {
  /// Cree le resultat.
  const InscriptionConfidentialiteRequise({this.versionCourante});

  /// La version que le serveur attend.
  final String? versionCourante;
}

/// La version de confidentialite acceptee n'est plus la version courante.
final class InscriptionConfidentialitePerimee
    extends ResultatInscriptionCandidat {
  /// Cree le resultat.
  const InscriptionConfidentialitePerimee({this.versionCourante});

  /// La version que le serveur attend.
  final String? versionCourante;
}

/// Le serveur ne publie aucune version de confidentialite : rien ne s'accepte.
final class InscriptionConfidentialiteIndisponible
    extends ResultatInscriptionCandidat {
  /// Cree le resultat.
  const InscriptionConfidentialiteIndisponible();
}

/// Le port de l'inscription du candidat.
abstract interface class PortInscriptionCandidat {
  /// Lit l'ouverture de l'inscription sans code. `PermissionInsuffisante` sans
  /// session ; `CapaciteIndisponible('CAND-BR-17')` sans lot serveur.
  Future<OuvertureInscriptionCandidat> ouverte();

  /// Cree le compte et la candidature de la session.
  ///
  /// [code] est nul pour le lien public, ou le code d'invitation (lie a
  /// l'adresse de la session). [genre] vaut `male` ou `female`. [telephone] est
  /// **international** (`+` puis l'indicatif et le numero). [langue] vaut `fr`
  /// ou `ar`, celle de l'ecran, jamais deduite. [versionConfidentialite] est la
  /// version de la politique que la personne a lue et acceptee.
  ///
  /// Rend toujours un [ResultatInscriptionCandidat]. Leve
  /// `PermissionInsuffisante` quand la session a deja un profil (ou n'a pas
  /// d'adresse), [HorsLigneCandidature] en cas de panne reseau.
  Future<ResultatInscriptionCandidat> inscrire({
    required String prenom,
    required String nom,
    required String genre,
    required String telephone,
    required String langue,
    required String versionConfidentialite,
    String? code,
  });
}

/// Le port de l'inscription du candidat : absent avant le branchement serveur.
final Provider<PortInscriptionCandidat?> portInscriptionCandidatProvider =
    Provider<PortInscriptionCandidat?>((Ref _) => null);

/// L'ouverture de l'inscription sans code, lue au serveur.
///
/// Rend `null` quand elle ne peut pas se lire (port absent, lot serveur absent,
/// panne, session sans droit) : **rien n'est alors propose** hors du code
/// d'invitation, qui reste l'entree d'aujourd'hui. Une lecture qui echoue ne
/// ouvre jamais rien.
final FutureProvider<OuvertureInscriptionCandidat?>
ouvertureInscriptionCandidatProvider =
    FutureProvider.autoDispose<OuvertureInscriptionCandidat?>((Ref ref) async {
      final PortInscriptionCandidat? port = ref.watch(
        portInscriptionCandidatProvider,
      );
      if (port == null) {
        return null;
      }
      try {
        return await port.ouverte();
      } on CapaciteIndisponible {
        return null;
        // Une lecture qui echoue (reseau, droit) ne rend jamais « ouverte » :
        // les liens sans code ne sont simplement pas proposes.
      } on Object {
        return null;
      }
    });

/// Decode la reponse de `inscription_candidat_ouverte`.
OuvertureInscriptionCandidat ouvertureInscriptionCandidatJson(Object? brut) {
  if (brut is! Map) {
    throw const FormatException('Objet attendu.');
  }
  final Object? version = brut['versionConfidentialite'];
  return OuvertureInscriptionCandidat(
    ouverte: brut['ouverte'] == true,
    versionConfidentialite: version is String && version.isNotEmpty
        ? version
        : null,
  );
}

/// Decode la reponse de `inscrire_candidat`. Un `resultat` inconnu est une
/// erreur de format : l'ecran ne devine jamais un succes.
ResultatInscriptionCandidat resultatInscriptionCandidatJson(Object? brut) {
  if (brut is! Map) {
    throw const FormatException('Objet attendu.');
  }
  final Object? version = brut['versionCourante'];
  final String? courante = version is String && version.isNotEmpty
      ? version
      : null;
  return switch (brut['resultat']) {
    'acceptee' => const InscriptionAcceptee(),
    'fermee' => const InscriptionFermee(),
    'courriel_non_confirme' => const InscriptionCourrielNonConfirme(),
    'inconnue' => const InscriptionCodeInconnu(),
    'deja_utilisee' => const InscriptionCodeDejaUtilise(),
    'expiree' => const InscriptionCodeExpire(),
    'invalide' => InscriptionInvalide(<String>[
      if (brut['champs'] is List)
        for (final Object? c in brut['champs'] as List)
          if (c is String) c,
    ]),
    'confidentialite_requise' => InscriptionConfidentialiteRequise(
      versionCourante: courante,
    ),
    'confidentialite_perimee' => InscriptionConfidentialitePerimee(
      versionCourante: courante,
    ),
    'confidentialite_indisponible' =>
      const InscriptionConfidentialiteIndisponible(),
    _ => throw const FormatException('Resultat d inscription inconnu.'),
  };
}
