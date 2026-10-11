import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/capacites/port_encaissements.dart';
import '../../../../core/recherche/port_recherche.dart';
import '../../../com_messages/port_messages_metier.dart';
import '../../../com_studio/port_studio.dart';
import 'moteur_fils.dart';
import 'moteur_finances.dart';

/// Les moteurs du domaine « finance et communications » (RECH-D4), branches
/// sur les ports de FI/CPT et de Communications que l'application lit deja.
///
/// **A ne poser que dans une demonstration ou une fois le serveur la** :
/// `moteursRechercheProvider` reste vide en production.
List<MoteurRechercheDomaine> moteursFinanceCommunications(Ref ref) =>
    <MoteurRechercheDomaine>[
      MoteurEncaissements(ref.watch(portEncaissementsProvider)),
      MoteurFils(
        messages: ref.watch(portMessagesMetierProvider),
        studio: ref.watch(portStudioProvider),
      ),
    ];
