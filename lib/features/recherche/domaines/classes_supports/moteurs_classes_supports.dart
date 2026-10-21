import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/recherche/port_recherche.dart';
import '../../../../core/tc_bibliotheque/donnees_catalogue.dart';
import '../../../../core/tc_groupe/port_groupes.dart';
import 'moteur_classes_groupes.dart';
import 'moteur_supports_catalogue.dart';

/// Les moteurs du domaine « classes et supports » (RECH-D1), branches sur les
/// ports que l'application lit deja (`PortGroupes`, `PortCatalogue`).
///
/// **A ne poser que dans une demonstration ou une fois le serveur la** :
/// `moteursRechercheProvider` reste vide en production (un port local vide
/// ferait passer une panne pour un vide confirme).
List<MoteurRechercheDomaine> moteursClassesSupports(Ref ref) =>
    <MoteurRechercheDomaine>[
      MoteurClassesGroupes(ref.watch(portGroupesProvider)),
      MoteurSupportsCatalogue(ref.watch(portCatalogueProvider)),
    ];
