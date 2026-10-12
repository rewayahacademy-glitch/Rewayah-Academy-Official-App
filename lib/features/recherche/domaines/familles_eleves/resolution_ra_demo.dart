import 'port_resolution_ra.dart';

/// Le double de demonstration de la resolution d'un RA exact : il joue le
/// serveur, qui ne rend un eleve que dans le perimetre de l'appelant.
///
/// [perimetre] est **deja le perimetre de l'appelant** (son foyer) : tout RA
/// qui n'y est pas, inconnu ou d'un autre foyer, recoit `null`, la meme
/// reponse. Ce n'est pas un registre de l'application : il n'existe qu'en
/// demonstration (hors production, `portResolutionRaProvider` rend
/// `ResolutionRaIndisponible`).
class ResolutionRaDemo implements PortResolutionRa {
  /// Cree le double sur le [perimetre] de l'appelant, par RA canonique.
  const ResolutionRaDemo(this.perimetre);

  /// Les eleves que l'appelant peut resoudre, par RA canonique (`RA-XXXX`).
  final Map<String, ElevePourRa> perimetre;

  @override
  Future<ElevePourRa?> resoudre(String identifiantExact) async =>
      perimetre[identifiantExact];
}
