import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/capacites/capacite_indisponible.dart';

/// Un eleve que le serveur a resolu depuis un identifiant d'academie (RA)
/// exact : une liste blanche, rien d'autre que ce qu'il faut pour l'afficher
/// et pour ouvrir sa fiche.
@immutable
class ElevePourRa {
  /// Cree la resolution.
  const ElevePourRa({required this.eleveId, required this.prenom, this.classe});

  /// L'identifiant de profil (jamais le RA, que la personne a deja saisi).
  final String eleveId;

  /// Le prenom affiche.
  final String prenom;

  /// La classe de l'eleve, quand la personne a le droit de la voir.
  final String? classe;
}

/// La resolution d'un identifiant d'academie **exact** (spec RECH-03 §3, §7.2).
///
/// Le RA n'est ni un champ de recherche ni un index : l'application ne
/// l'enumere jamais, n'en garde aucun registre, ne le complete pas. Le
/// serveur (zone ChatGPT, K-68) tire l'identite de la session et rend l'eleve
/// **seulement** s'il appartient au perimetre de l'appelant (son foyer, sa
/// mission, sa competence administrative). Dans tous les autres cas, RA
/// inexistant, eleve d'un autre foyer, droit retire, la reponse est **la
/// meme** : `null`. Rien ne distingue « n'existe pas » de « pas pour vous »
/// (non-enumerabilite, SEC-R01, REC-02). Une panne est une exception, jamais
/// `null`.
// ignore: one_member_abstracts
abstract interface class PortResolutionRa {
  /// L'eleve du RA [identifiantExact] (forme canonique, voir
  /// [identifiantRaExact]), ou `null` s'il n'est pas dans le perimetre.
  Future<ElevePourRa?> resoudre(String identifiantExact);
}

/// Le port de production tant que le contrat serveur n'existe pas.
class ResolutionRaIndisponible implements PortResolutionRa {
  /// Cree le port indisponible.
  const ResolutionRaIndisponible();

  @override
  Future<ElevePourRa?> resoudre(String identifiantExact) =>
      Future<ElevePourRa?>.error(const CapaciteIndisponible('DB-RECH-RA'));
}

/// Le port de resolution d'un RA exact.
final Provider<PortResolutionRa> portResolutionRaProvider =
    Provider<PortResolutionRa>((Ref ref) => const ResolutionRaIndisponible());

/// La forme du matricule, `RA-26-4817` : l'annee a deux chiffres, puis quatre
/// chiffres (cinq au-dela de 4 500 matricules dans l'annee), decision du
/// directeur du 12/10/2026 (`DECISION-IMMATRICULATION-2026-10-12.md` §1). Les
/// tirets et les espaces sont facultatifs a la saisie ; ils sont rendus.
final RegExp _formeRa = RegExp(r'^RA[- ]?(\d{2})[- ]?(\d{4,5})$');

/// La forme canonique (`RA-AA-NNNN`) d'une saisie qui est **un matricule
/// complet**, ou `null`.
///
/// Un debut de matricule (`RA-26`, `RA-26-48`) n'est pas un matricule : il
/// retombe dans la recherche par nom, qui ne trouve rien. Aucune completion,
/// aucune suggestion (spec §7.2). Les anciens codes (`RA-AB0012`) sont
/// abandonnes (decision du 12/10/2026) : ils ne partent jamais au serveur.
String? identifiantRaExact(String saisie) {
  final RegExpMatch? m = _formeRa.firstMatch(saisie.trim().toUpperCase());
  if (m == null) return null;
  return 'RA-${m.group(1)}-${m.group(2)}';
}
