import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Un cahier de transmission en attente d'envoi.
@immutable
class RapportEnAttente {
  /// Cree un rapport en attente.
  const RapportEnAttente({
    required this.cleIdempotence,
    required this.sessionId,
    required this.contenuJson,
    required this.redigeA,
    this.tentatives = 0,
  });

  /// Cle generee localement, jamais reattribuee, jamais regeneree au rejeu.
  final String cleIdempotence;

  /// Seance concernee.
  final String sessionId;

  /// Contenu serialise du rapport.
  final String contenuJson;

  /// Date de redaction.
  final DateTime redigeA;

  /// Nombre de tentatives d'envoi deja effectuees.
  final int tentatives;

  /// Copie avec un compteur de tentatives incremente.
  RapportEnAttente avecTentativeSupplementaire() => RapportEnAttente(
    cleIdempotence: cleIdempotence,
    sessionId: sessionId,
    contenuJson: contenuJson,
    redigeA: redigeA,
    tentatives: tentatives + 1,
  );
}

/// Ou vivent les rapports en attente.
///
/// Une interface, et non un appel direct a Drift : la regle d'idempotence se
/// verifie alors sans base de donnees, donc sans dependance native dans les
/// tests.
abstract interface class DepotRapports {
  /// Les rapports restant a envoyer, du plus ancien au plus recent.
  Future<List<RapportEnAttente>> enAttente();

  /// Ecrit un rapport. Un rapport deja present sous la meme cle n'est pas
  /// duplique.
  Future<void> deposer(RapportEnAttente rapport);

  /// Retire un rapport confirme par le serveur.
  Future<void> retirer(String cleIdempotence);

  /// Met a jour un rapport dont l'envoi a echoue.
  Future<void> majApresEchec(RapportEnAttente rapport);
}

/// Ce que fait l'envoi d'un rapport au serveur.
typedef EnvoiRapport = Future<void> Function(RapportEnAttente rapport);

/// La file de synchronisation des cahiers de transmission.
///
/// Seul besoin d'ecriture hors ligne reel du produit. Hors ligne, la validation
/// enregistre localement et affiche « sera envoye des le retour du reseau »,
/// sans bloquer l'enseignant sur son cours suivant.
///
/// **Deux garanties, et elles ne reposent pas sur la meme chose :**
///
/// 1. La cle d'idempotence est generee **une seule fois**, a la redaction, et
///    ne change jamais au rejeu. C'est ce qui permet a la contrainte C9 de
///    l'etape 1 de refuser un doublon en base.
/// 2. Un verrou local empeche deux vidages concurrents de partir en meme temps.
///    Ce verrou est une commodite : meme s'il sautait, la base trancherait.
class FileRapports {
  /// Cree la file.
  FileRapports(this._depot, {Uuid? generateur})
    : _generateur = generateur ?? const Uuid();

  final DepotRapports _depot;
  final Uuid _generateur;
  bool _vidageEnCours = false;

  /// Enregistre un rapport, avec ou sans reseau.
  ///
  /// La cle est generee ici, au moment de la redaction, pas au moment de
  /// l'envoi : une cle generee a l'envoi serait differente a chaque tentative
  /// et l'idempotence ne servirait plus a rien.
  Future<RapportEnAttente> enregistrer({
    required String sessionId,
    required String contenuJson,
    DateTime? maintenant,
  }) async {
    final RapportEnAttente rapport = RapportEnAttente(
      cleIdempotence: _generateur.v4(),
      sessionId: sessionId,
      contenuJson: contenuJson,
      redigeA: maintenant ?? DateTime.now().toUtc(),
    );
    await _depot.deposer(rapport);
    return rapport;
  }

  /// Rejoue la file. Retourne le nombre de rapports effectivement envoyes.
  ///
  /// Un second appel declenche pendant qu'un premier tourne ne renvoie rien :
  /// il retourne zero sans toucher au depot.
  Future<int> vider(EnvoiRapport envoyer) async {
    if (_vidageEnCours) {
      return 0;
    }
    _vidageEnCours = true;
    try {
      int envoyes = 0;
      for (final RapportEnAttente rapport in await _depot.enAttente()) {
        try {
          await envoyer(rapport);
          await _depot.retirer(rapport.cleIdempotence);
          envoyes++;
        } on Exception {
          // L'echec d'un rapport ne bloque pas les suivants : chacun porte sa
          // propre cle, donc son propre sort.
          await _depot.majApresEchec(rapport.avecTentativeSupplementaire());
        }
      }
      return envoyes;
    } finally {
      _vidageEnCours = false;
    }
  }
}
