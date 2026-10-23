// La langue des e-mails et des messages de la direction (COURRIELS-2,
// migration 20261023140000) : chaque personne choisit la langue dans laquelle
// elle les recoit, la direction ecrit une seule fois et le serveur traduit.
//
// Le serveur decide de tout : quelles langues existent, laquelle est reglee,
// qui a le droit. Flutter lit la liste, envoie le choix et ne dit « enregistre »
// qu'apres la reponse du serveur.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'capacite_indisponible.dart';

/// Une langue proposee, avec son nom dans sa propre langue.
@immutable
class LangueCommunication {
  /// Cree une langue.
  const LangueCommunication({
    required this.code,
    required this.libelle,
    this.droiteAGauche = false,
  });

  /// Le code (`fr`, `ar`, ...).
  final String code;

  /// Le nom de la langue dans cette langue (« Français », « العربية »).
  final String libelle;

  /// Vrai quand la langue s'ecrit de droite a gauche.
  final bool droiteAGauche;

  @override
  bool operator ==(Object other) =>
      other is LangueCommunication &&
      other.code == code &&
      other.libelle == libelle &&
      other.droiteAGauche == droiteAGauche;

  @override
  int get hashCode => Object.hash(code, libelle, droiteAGauche);
}

/// La langue par defaut quand aucune n'est reglee.
const String langueCommunicationParDefaut = 'fr';

/// Les langues et le choix de la personne, lus ensemble.
@immutable
class EtatLanguesCommunication {
  /// Cree l'etat.
  const EtatLanguesCommunication({required this.langues, required this.code});

  /// Les langues proposees, dans l'ordre du serveur.
  final List<LangueCommunication> langues;

  /// La langue reglee, `fr` quand le serveur n'en a pas retenu.
  final String code;
}

/// Le serveur refuse la langue (`22023`) : elle n'existe plus ou est coupee.
class LangueRefusee implements Exception {
  /// Cree l'erreur.
  const LangueRefusee();

  @override
  String toString() => 'LangueRefusee()';
}

/// La langue de communication (contrat de la migration 20261023140000).
abstract interface class PortLanguesCommunication {
  /// Les langues actives (`langues_communication_lister`), lisibles sans
  /// compte.
  Future<List<LangueCommunication>> lister();

  /// La langue de la personne connectee (`ma_langue_communication`), `null`
  /// quand elle n'en a pas choisi : c'est le francais.
  Future<String?> maLangue();

  /// Regle la langue (`ma_langue_communication_regler`), puis la rend aussi
  /// aux e-mails de connexion. [LangueRefusee] si le serveur refuse le code.
  Future<void> regler(String code);
}

/// Tant qu'aucun adaptateur serveur n'est branche : les ecrans disent que la
/// fonction est indisponible.
class LanguesCommunicationIndisponibles implements PortLanguesCommunication {
  /// Cree l'implementation.
  const LanguesCommunicationIndisponibles();

  static const CapaciteIndisponible _absente = CapaciteIndisponible(
    'COURRIELS-2',
  );

  @override
  Future<List<LangueCommunication>> lister() =>
      Future<List<LangueCommunication>>.error(_absente);

  @override
  Future<String?> maLangue() => Future<String?>.error(_absente);

  @override
  Future<void> regler(String code) => Future<void>.error(_absente);
}

/// Le port de la langue de communication.
final Provider<PortLanguesCommunication> portLanguesCommunicationProvider =
    Provider<PortLanguesCommunication>(
      (Ref ref) => const LanguesCommunicationIndisponibles(),
    );

/// Les langues proposees et celle de la personne, lues ensemble au serveur.
/// Relues a chaque ouverture.
final languesCommunicationProvider =
    FutureProvider.autoDispose<EtatLanguesCommunication>((Ref ref) async {
      final PortLanguesCommunication port = ref.watch(
        portLanguesCommunicationProvider,
      );
      final List<LangueCommunication> langues = await port.lister();
      final String? code = await port.maLangue();
      return EtatLanguesCommunication(
        langues: langues,
        code: code ?? langueCommunicationParDefaut,
      );
    }, retry: (int _, Object _) => null);
