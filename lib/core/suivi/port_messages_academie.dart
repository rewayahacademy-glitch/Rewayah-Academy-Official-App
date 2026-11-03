/// D1-ter (03/11/2026) : les messages de l'academie sur un eleve, ceux que la
/// direction a transmis a la famille (ou a l'eleve adulte) apres le
/// signalement d'un enseignant.
///
/// Le serveur decide de tout (`concern_famille_v`, migration 20261106600000) :
/// seulement ce qui a ete transmis, le resume ecrit pour la famille et jamais
/// la note interne, jamais la securite d'un enfant, et seulement pour un
/// tuteur du foyer, son titulaire ou l'eleve adulte lui-meme ; un mineur ne
/// lit rien. L'ecran ne filtre rien de plus, sauf l'Interface guidee, ou la
/// carte n'est jamais posee.
///
/// Le modele est `ResumeFamilleSignalement` (lot H) : il ne porte aucun champ
/// capable de transporter la note interne.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../tc_parcours/student_concern.dart';

/// Le port.
abstract interface class PortMessagesAcademie {
  /// Les messages transmis sur [eleveId], du plus recent au plus ancien
  /// (20 au plus). Nul : ceux que la personne connectee peut lire, sans
  /// filtre d'eleve (l'eleve adulte : les siens seulement, le serveur le
  /// borne).
  Future<List<ResumeFamilleSignalement>> pourEleve(String? eleveId);
}

/// Le port : absent tant que `main.dart` ne le pose pas ; sans lui, la carte
/// n'est pas posee.
final Provider<PortMessagesAcademie?> portMessagesAcademieProvider =
    Provider<PortMessagesAcademie?>((Ref _) => null);

/// Les messages d'un eleve (nul : les siens) ; `null` sans port.
final FutureProviderFamily<List<ResumeFamilleSignalement>?, String?>
messagesAcademieProvider =
    FutureProvider.family<List<ResumeFamilleSignalement>?, String?>((
      Ref ref,
      String? eleveId,
    ) {
      final PortMessagesAcademie? port = ref.watch(
        portMessagesAcademieProvider,
      );
      if (port == null) return Future<List<ResumeFamilleSignalement>?>.value();
      return port.pourEleve(eleveId);
    }, retry: (int _, Object _) => null);
