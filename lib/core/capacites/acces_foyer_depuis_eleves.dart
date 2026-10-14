import '../appairage/service_appairage.dart';
import 'port_acces_foyer.dart';

/// L'acces des eleves du foyer, lu depuis `profils_du_foyer_v` (contrat K6,
/// lot E) : la vue porte deja l'echeance (`access_until`), aucun backend
/// nouveau n'est necessaire.
///
/// **Ce qui n'est pas dit** : le statut detaille (offert, paye hors
/// application, suspendu) et son motif attendent DB-FOY-05 ; ils restent
/// `null` et ne sont jamais devines. « Expire » est un calcul d'affichage
/// ([etatAccesAffiche]), pas un statut serveur.
///
/// Le lot B (fiche eleve) lit le **meme provider de port**, jamais ce fichier.
class AccesFoyerDepuisEleves implements PortAccesFoyer {
  /// Cree l'adaptateur.
  ///
  /// [lireEleves] rend les eleves du foyer (en production :
  /// `ServiceAppairage.eleves`, bornee par la RLS au foyer de l'appelant).
  /// [maintenantUtc] donne l'instant de comparaison : l'horloge de l'appareil
  /// par defaut, ce qui ne sert qu'a l'affichage.
  AccesFoyerDepuisEleves({
    required this.lireEleves,
    DateTime Function()? maintenantUtc,
  }) : _maintenantUtc = maintenantUtc ?? DateTime.now;

  /// La lecture des eleves du foyer.
  final Future<List<EleveDuFoyer>> Function() lireEleves;

  final DateTime Function() _maintenantUtc;

  @override
  Future<List<AccesBeneficiaire>> acces() async {
    final List<EleveDuFoyer> eleves = await lireEleves();
    return accesDepuisEleves(eleves, maintenantUtc: _maintenantUtc().toUtc());
  }
}

/// Un acces par eleve, dans un ordre stable (prenom, puis identifiant) : la
/// vue ne porte aucun `order by`. Pure, testee.
List<AccesBeneficiaire> accesDepuisEleves(
  List<EleveDuFoyer> eleves, {
  required DateTime maintenantUtc,
}) {
  final List<EleveDuFoyer> tries = <EleveDuFoyer>[...eleves]
    ..sort((EleveDuFoyer a, EleveDuFoyer b) {
      final int parPrenom = a.prenom.toLowerCase().compareTo(
        b.prenom.toLowerCase(),
      );
      return parPrenom != 0 ? parPrenom : a.id.compareTo(b.id);
    });
  return <AccesBeneficiaire>[
    for (final EleveDuFoyer eleve in tries)
      AccesBeneficiaire(
        eleveId: eleve.id,
        prenom: eleve.prenom,
        finAcces: eleve.finAcces,
        etatAffiche: etatAccesAffiche(
          finAcces: eleve.finAcces,
          maintenantUtc: maintenantUtc,
        ),
      ),
  ];
}
