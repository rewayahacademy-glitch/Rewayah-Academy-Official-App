import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/capacites/port_acces_foyer.dart';
import '../../../../core/capacites/port_classes_foyer.dart';
import '../../../../core/recherche/port_recherche.dart';
import 'moteur_personnes.dart';
import 'port_resolution_ra.dart';

/// Les moteurs du domaine « familles, eleves et identifiant RA exact »
/// (RECH-D2), branches sur les ports que l'application lit deja et sur le
/// port de resolution d'un RA exact.
///
/// **A ne poser que dans une demonstration ou une fois le serveur la** :
/// `moteursRechercheProvider` reste vide en production. Aucun registre local
/// d'identifiants n'existe.
List<MoteurRechercheDomaine> moteursFamillesEleves(Ref ref) =>
    <MoteurRechercheDomaine>[
      MoteurPersonnesFoyer(
        foyer: ref.watch(portAccesFoyerProvider),
        classes: ref.watch(portClassesFoyerProvider),
        resolutionRa: ref.watch(portResolutionRaProvider),
      ),
    ];
