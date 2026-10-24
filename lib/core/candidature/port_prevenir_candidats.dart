// Le port du message qui previent par e-mail les personnes des formulaires
// importes : `PortPrevenirCandidats`, pour le geste « Prevenir par e-mail » de
// la direction (CAND-PREVENIR, directeur, 24/10/2026, `CAND-BR-16`).
//
// Deux RPC, reservees a la direction de son cote
// (`20261024010000_cand_prevenir_par_courriel.sql`) :
//
// - `apercu_prevenir_par_courriel` : trois comptes par adresse (a prevenir,
//   deja prevenus, deja inscrits) et l'etat de l'inscription en ligne. Aucune
//   adresse n'est rendue ;
// - `prevenir_par_courriel` : met le message en file pour chaque personne a
//   prevenir, au plus [limite] par appel. Une adresse deja en file n'est jamais
//   reprise : rejouer apres une coupure du reseau n'envoie rien en double.
//
// Le refus metier arrive **dans la reponse** (`{erreur: 'inscription_fermee'}`),
// sans ecriture : il devient une [ErreurPrevenirCandidats] typee. Les messages
// partent par la file des courriels dans les minutes qui suivent : « mis en
// file » n'est pas « recu ».
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capacites/capacite_indisponible.dart';

/// La dependance serveur du message qui previent les candidats (`CAND-BR-16`),
/// pour la trace et les tests : jamais affichee.
const String dependancePrevenirCandidats = 'CAND-BR-16';

/// La taille d'un envoi par defaut (le serveur accepte de 1 a 500).
const int limitePrevenirParDefaut = 200;

/// Ce que l'apercu dit, sans aucune adresse.
class ApercuPrevenir {
  /// Cree l'apercu.
  const ApercuPrevenir({
    required this.aPrevenir,
    required this.dejaPrevenus,
    required this.dejaInscrits,
    required this.inscriptionOuverte,
  });

  /// Lit la reponse du serveur. Une forme inattendue est une [FormatException].
  factory ApercuPrevenir.depuisJson(Map<String, dynamic> j) {
    int compte(String cle) {
      final Object? v = j[cle];
      if (v is int && v >= 0) return v;
      throw FormatException('compte attendu : $cle');
    }

    final Object? ouverte = j['inscriptionOuverte'];
    if (ouverte is! bool) {
      throw const FormatException('booleen attendu : inscriptionOuverte');
    }
    return ApercuPrevenir(
      aPrevenir: compte('aPrevenir'),
      dejaPrevenus: compte('dejaPrevenus'),
      dejaInscrits: compte('dejaInscrits'),
      inscriptionOuverte: ouverte,
    );
  }

  /// Les personnes qui recevraient le message maintenant.
  final int aPrevenir;

  /// Les personnes deja prevenues (par e-mail ou par WhatsApp).
  final int dejaPrevenus;

  /// Les personnes qui ont deja un compte.
  final int dejaInscrits;

  /// Vrai quand l'inscription en ligne est ouverte : sinon rien ne part.
  final bool inscriptionOuverte;
}

/// Ce qu'un envoi a fait.
class ResultatPrevenir {
  /// Cree le resultat.
  const ResultatPrevenir({required this.misEnFile, required this.restants});

  /// Lit la reponse du serveur. Une forme inattendue est une [FormatException].
  factory ResultatPrevenir.depuisJson(Map<String, dynamic> j) {
    final Object? mis = j['misEnFile'];
    final Object? restants = j['restants'];
    if (mis is! int || restants is! int || mis < 0 || restants < 0) {
      throw const FormatException('comptes attendus : misEnFile, restants');
    }
    return ResultatPrevenir(misEnFile: mis, restants: restants);
  }

  /// Les messages mis en file par cet envoi.
  final int misEnFile;

  /// Les personnes encore a prevenir apres cet envoi.
  final int restants;
}

/// Pourquoi un envoi ou un apercu n'a pas abouti. Hors [PrevenirHorsLigne]
/// pendant un envoi, aucune de ces erreurs n'a ecrit quoi que ce soit.
sealed class ErreurPrevenirCandidats implements Exception {
  const ErreurPrevenirCandidats();
}

/// L'inscription en ligne est fermee : le lien menerait a une page fermee, rien
/// n'est parti.
final class InscriptionFermee extends ErreurPrevenirCandidats {
  /// Cree l'erreur.
  const InscriptionFermee();
}

/// La connexion a coupe. Pour un envoi, c'est **non confirme** : des messages
/// ont pu etre mis en file. Rejouer l'envoi n'en renvoie aucun en double.
final class PrevenirHorsLigne extends ErreurPrevenirCandidats {
  /// Cree l'erreur.
  const PrevenirHorsLigne();
}

/// Le serveur a refuse les arguments (`22023`) : limite hors bornes. [message]
/// est celui du serveur : il ne s'affiche pas tel quel.
final class PrevenirInvalide extends ErreurPrevenirCandidats {
  /// Cree l'erreur.
  const PrevenirInvalide(this.message);

  /// Le message du serveur.
  final String message;
}

/// Le serveur a repondu une erreur que ce client ne connait pas.
final class PrevenirRefuseInconnu extends ErreurPrevenirCandidats {
  /// Cree l'erreur.
  const PrevenirRefuseInconnu(this.code);

  /// Le code rendu (trace et tests, jamais affiche).
  final String code;
}

/// Le port du message qui previent les candidats par e-mail.
abstract interface class PortPrevenirCandidats {
  /// Combien de personnes recevraient le message, combien sont deja prevenues
  /// ou inscrites, et si l'inscription en ligne est ouverte. Aucune ecriture.
  ///
  /// Les erreurs sont des [ErreurPrevenirCandidats]. `CapaciteIndisponible`
  /// quand le lot serveur n'est pas encore verse, `PermissionInsuffisante` pour
  /// un lecteur qui n'est pas la direction (ou dont le genre est inconnu).
  Future<ApercuPrevenir> apercu();

  /// Met le message en file pour au plus [limite] personnes (1 a 500), sans
  /// jamais reprendre une adresse deja en file. Lance [InscriptionFermee] tant
  /// que l'inscription en ligne est fermee.
  Future<ResultatPrevenir> prevenir({int limite = limitePrevenirParDefaut});
}

/// Le port : absent avant le branchement serveur.
final Provider<PortPrevenirCandidats?> portPrevenirCandidatsProvider =
    Provider<PortPrevenirCandidats?>((Ref _) => null);

/// L'apercu du message. Sans port : [CapaciteIndisponible]. Relu a chaque
/// ouverture de la feuille, sans retentative automatique.
final FutureProvider<ApercuPrevenir> apercuPrevenirCandidatsProvider =
    FutureProvider.autoDispose<ApercuPrevenir>((Ref ref) {
      final PortPrevenirCandidats? port = ref.watch(
        portPrevenirCandidatsProvider,
      );
      if (port == null) {
        return Future<ApercuPrevenir>.error(
          const CapaciteIndisponible(dependancePrevenirCandidats),
        );
      }
      return port.apercu();
    }, retry: (int _, Object _) => null);
