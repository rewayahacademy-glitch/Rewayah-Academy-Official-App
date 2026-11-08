import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/recherche/modeles_recherche.dart';
import '../../../../core/recherche/port_recherche.dart';
import '../../../com_messages/port_messages_metier.dart';
import 'moteur_fils.dart';

/// Les fils que le comptable cherche, en PRODUCTION (RECHERCHE D4, partie
/// « fils », 08/11/2026).
///
/// Un seul moteur, sur les Messages metier que l'application lit deja
/// (`com_lister_fils`, le serveur ne rend que les fils dont le comptable est
/// partie) : jamais le Studio, jamais les encaissements (`CPT-BR-07` : aucune
/// source serveur, une loupe y mene a « indisponible »).
List<MoteurRechercheDomaine> moteursFilsComptable(Ref ref) =>
    <MoteurRechercheDomaine>[
      MoteurFils(
        messages: ref.watch(portMessagesMetierProvider),
        espaces: const <EspaceRecherche>{EspaceRecherche.comptable},
      ),
    ];
