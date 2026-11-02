/// I1 (02/11/2026) : l'invitation des familles importees par la direction
/// (DECISION-IMMATRICULATION-2026-10-12.md §5).
///
/// Une famille deja inscrite, importee puis confirmee, recoit un e-mail qui
/// l'invite a se connecter avec son adresse : elle y retrouve son foyer sans
/// rien ressaisir. **Rien ne part tout seul** : chaque envoi est un geste de
/// la direction, un foyer a la fois ou tous apres confirmation du nombre
/// (`envoyer_invitations_familles_importees(p_attendu)` refuse si le nombre a
/// change entre-temps). L'etat de chaque foyer vient de la file d'e-mails du
/// serveur, jamais de l'horloge de l'appareil.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';

/// L'etat de l'invitation d'un foyer importe.
enum EtatInvitationFamille {
  /// Jamais envoyee (ou le dernier envoi annule).
  aEnvoyer,

  /// Dans la file d'envoi.
  enFile,

  /// Partie.
  envoyee,

  /// L'envoi a echoue : on peut renvoyer.
  echec,

  /// La famille s'est connectee et a retrouve son foyer.
  compteCree,
}

/// Un foyer importe et confirme.
class FoyerImporte {
  /// Cree le foyer.
  const FoyerImporte({
    required this.id,
    required this.email,
    required this.personnes,
    required this.etat,
    this.envoyeeLe,
  });

  /// L'identifiant de la pre-inscription (jamais affiche).
  final String id;

  /// L'adresse de la famille, telle qu'importee.
  final String email;

  /// Le nombre de personnes du foyer (tuteurs, adultes, eleves).
  final int personnes;

  /// L'etat de l'invitation.
  final EtatInvitationFamille etat;

  /// Le moment de l'envoi, quand il est parti.
  final DateTime? envoyeeLe;

  /// Vrai quand la direction peut (r)envoyer l'invitation.
  bool get envoyable =>
      etat == EtatInvitationFamille.aEnvoyer ||
      etat == EtatInvitationFamille.echec;
}

/// La liste lue par la direction.
class FamillesImportees {
  /// Cree la liste.
  const FamillesImportees({required this.foyers, required this.aEnvoyer});

  /// Les foyers, du plus ancien au plus recent.
  final List<FoyerImporte> foyers;

  /// Le nombre de foyers a envoyer, compte par le serveur.
  final int aEnvoyer;
}

/// L'issue de l'envoi a un foyer.
enum ResultatEnvoiFoyer {
  /// L'e-mail est dans la file.
  enFile,

  /// Un e-mail etait deja en file ou parti : rien de plus.
  dejaEnFile,

  /// La famille a deja son compte : rien ne part.
  compteCree,

  /// Le foyer n'est plus a inviter (non confirme, ou retire).
  introuvable,
}

/// L'issue de l'envoi a tous.
sealed class ResultatEnvoiTous {
  const ResultatEnvoiTous();
}

/// Les e-mails sont dans la file.
final class EnvoiTousEnFile extends ResultatEnvoiTous {
  /// Cree le resultat.
  const EnvoiTousEnFile(this.envoyees);

  /// Le nombre de foyers mis en file.
  final int envoyees;
}

/// Le nombre a change depuis la confirmation : rien n'est parti.
final class EnvoiTousNombreChange extends ResultatEnvoiTous {
  /// Cree le resultat.
  const EnvoiTousNombreChange(this.aEnvoyer);

  /// Le nombre a jour de foyers a envoyer.
  final int aEnvoyer;
}

/// Le port de la direction.
abstract interface class PortFamillesImportees {
  /// Les foyers importes et confirmes.
  Future<FamillesImportees> lister();

  /// Envoie l'invitation d'un foyer.
  Future<ResultatEnvoiFoyer> envoyer(String foyer);

  /// Envoie l'invitation de tous les foyers a envoyer ; [attendu] est le
  /// nombre que la direction a vu et confirme.
  Future<ResultatEnvoiTous> envoyerATous(int attendu);
}

/// L'identifiant de la dependance serveur, pour la trace et les tests.
const String dependanceFamillesImportees = 'I1-FAMILLES-IMPORTEES';

/// Le port : absent avant le branchement serveur.
final Provider<PortFamillesImportees?> portFamillesImporteesProvider =
    Provider<PortFamillesImportees?>((Ref _) => null);

/// La liste des foyers importes. Sans port : [CapaciteIndisponible].
final FutureProvider<FamillesImportees> famillesImporteesProvider =
    FutureProvider<FamillesImportees>((Ref ref) {
      final PortFamillesImportees? port = ref.watch(
        portFamillesImporteesProvider,
      );
      if (port == null) {
        return Future<FamillesImportees>.error(
          const CapaciteIndisponible(dependanceFamillesImportees),
        );
      }
      return port.lister();
    }, retry: (int _, Object _) => null);
