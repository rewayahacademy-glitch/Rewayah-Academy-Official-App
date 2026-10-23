// L'envoi d'un message vocal dans un fil des Messages metier ou un canal du
// Studio (COM-FUS ; spec Communications V1, section 11 ; contrat serveur
// COM-BR-03 pour le transport, COM-BR-16 pour la capacite, COM-BR-02 pour
// l'idempotence).
//
// Le composer vocal (`ComposerVocal`) ne sait pas OU part le vocal : l'ecran
// qui le pose (fil contextuel, canal) donne la destination et passe par ce
// port. Regles :
//
// - **capacite d'abord** : le composer n'est rendu que si
//   `CapaciteCommunication.envoyerVocal` est ouverte
//   ([vocalOuvert]). En production, le port des capacites est
//   neutre : elle est fermee, et AUCUN composer vocal n'est rendu ;
// - **port neutre** : en production, [EnvoiVocalIndisponible] leve
//   `CapaciteIndisponible('COM-BR-03')`, jamais un faux accuse ;
// - **jamais d'envoi automatique** : seul « Envoyer » du composer appelle
//   l'envoi ([ClesVocales.envoyer], puis [PortEnvoiVocal.envoyer]) ;
// - **idempotence** : une cle par vocal, gardee d'un essai a l'autre du MEME
//   vocal ([ClesVocales]) : le serveur ne compte pas deux fois un vocal
//   renvoye apres un accuse perdu.
//
// La demonstration (sous `environnementAutoriseDemo` seulement) surcharge le
// port et la capacite ; jamais `main.dart`.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/communications/capacites_communication.dart';
import '../../core/widgets/fil_discussion.dart';
import 'port_enregistreur_vocal.dart';

/// Ou part un message vocal.
enum NatureDestinationVocal {
  /// Un fil des Messages metier (COM-BR-01).
  filMessages,

  /// Un canal du Studio (COM-BR-08).
  canalStudio,
}

/// La destination d'un message vocal : un fil ou un canal, par son
/// identifiant. Jamais une adresse de stockage.
@immutable
class DestinationVocal {
  /// Cree la destination.
  const DestinationVocal({required this.nature, required this.id});

  /// Un fil des Messages metier.
  const DestinationVocal.fil(this.id)
    : nature = NatureDestinationVocal.filMessages;

  /// Un canal du Studio.
  const DestinationVocal.canal(this.id)
    : nature = NatureDestinationVocal.canalStudio;

  /// La nature de la destination.
  final NatureDestinationVocal nature;

  /// L'identifiant du fil ou du canal.
  final String id;

  @override
  bool operator ==(Object other) =>
      other is DestinationVocal && other.nature == nature && other.id == id;

  @override
  int get hashCode => Object.hash(nature, id);
}

/// L'envoi des messages vocaux au serveur.
abstract interface class PortEnvoiVocal {
  /// Envoie [vocal] dans [destination] sous [cleIdempotence]. Le futur se
  /// termine sur l'accuse du serveur, et echoue sinon (le vocal est garde
  /// par le composer, « Reessayer » rejoue la meme cle).
  Future<void> envoyer({
    required DestinationVocal destination,
    required EnregistrementVocal vocal,
    required String cleIdempotence,
  });
}

/// L'envoi tant qu'aucun contrat serveur n'existe (COM-BR-03) : il leve
/// [CapaciteIndisponible], jamais un faux accuse.
class EnvoiVocalIndisponible implements PortEnvoiVocal {
  /// Cree l'implementation.
  const EnvoiVocalIndisponible();

  @override
  Future<void> envoyer({
    required DestinationVocal destination,
    required EnregistrementVocal vocal,
    required String cleIdempotence,
  }) => Future<void>.error(const CapaciteIndisponible(dependanceVocal));
}

/// L'envoi employe par l'application : neutre en production.
final Provider<PortEnvoiVocal> portEnvoiVocalProvider =
    Provider<PortEnvoiVocal>((Ref ref) => const EnvoiVocalIndisponible());

/// Vrai si la personne connectee peut enregistrer et envoyer un vocal
/// (`CapaciteCommunication.envoyerVocal`, COM-BR-16), lu dans la source
/// unique des capacites. Faux tant que la capacite n'est pas lue, en echec,
/// ou fermee (production).
bool vocalOuvert(WidgetRef ref) =>
    ref
        .watch(capacitesCommunicationProvider)
        .value
        ?.peut(CapaciteCommunication.envoyerVocal) ??
    false;

/// Les cles d'idempotence des vocaux d'une destination : une cle par vocal,
/// la meme a chaque essai de ce vocal (COM-BR-02).
class ClesVocales {
  /// Cree la reserve de cles de [destination].
  ClesVocales(this.destination);

  /// La destination des vocaux.
  final DestinationVocal destination;

  final Map<EnregistrementVocal, String> _cles =
      <EnregistrementVocal, String>{};
  static int _compteur = 0;

  /// La cle de [vocal] : neuve au premier essai, la meme ensuite.
  String cle(EnregistrementVocal vocal) => _cles.putIfAbsent(
    vocal,
    () =>
        '${destination.id}-vocal-'
        '${DateTime.now().microsecondsSinceEpoch}-${_compteur++}',
  );

  /// Oublie la cle de [vocal], apres son accuse.
  void oublier(EnregistrementVocal vocal) => _cles.remove(vocal);

  /// Envoie [vocal] par [envoi] sous sa cle ; la cle est oubliee apres
  /// l'accuse, gardee pour le nouvel essai sinon. Rend la cle confirmee :
  /// l'ecran en fait l'identifiant de la bulle du vocal confirme
  /// ([bulleVocalConfirme]).
  Future<String> envoyer(
    EnregistrementVocal vocal,
    Future<void> Function(String cleIdempotence) envoi,
  ) async {
    final String confirmee = cle(vocal);
    await envoi(confirmee);
    oublier(vocal);
    return confirmee;
  }
}

/// Un vocal confirme par le serveur pendant que le fil ou le canal est
/// ouvert : sa cle d'idempotence et sa duree. Rien d'autre (ni chemin, ni
/// adresse).
typedef VocalConfirme = ({String cle, Duration duree});

/// La bulle d'un vocal confirme (COM-FUS, revue) : le fil ouvert montre le
/// vocal envoye sans attendre sa relecture. Tant que le serveur n'a pas rendu
/// le message (COM-BR-03), la bulle n'a pas de lecteur : elle dit le vocal
/// par sa duree ([ligneVocal], « Message vocal de 0:06 ») et son etat
/// [envoye] (« Envoye »), annonce comme toute bulle arrivee.
MessageFil bulleVocalConfirme(
  VocalConfirme vocal, {
  required String auteurSoi,
  required String Function(Duration duree) ligneVocal,
  required String envoye,
}) => MessageFil(
  id: 'vocal-confirme-${vocal.cle}',
  auteur: auteurSoi,
  texte: ligneVocal(vocal.duree),
  horodatage: envoye,
  deSoi: true,
);
