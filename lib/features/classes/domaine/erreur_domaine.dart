import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart'
    show FunctionException, PostgrestException;

import '../../../core/i18n/strings.g.dart';

/// Pourquoi une action de Classe n'a pas abouti.
///
/// **Le client ne distingue que ce qu'il peut dire sans rien reveler** : une
/// capacite serveur absente, un refus, un conflit, une Classe complete, un
/// doublon, une panne de reseau. Le message brut de la base ne traverse jamais
/// cette enumeration.
enum MotifEchec {
  /// La base n'a pas encore la fonction ou la colonne que l'action demande.
  capaciteAbsente,

  /// La base refuse cet appelant.
  refuse,

  /// Le creneau chevauche un cours existant.
  conflit,

  /// La Classe est au plafond.
  complet,

  /// La personne est deja inscrite.
  dejaInscrit,

  /// La candidature existe deja.
  dejaCandidat,

  /// Le reseau ou le backend n'a pas repondu.
  reseau,

  /// Tout le reste. Le detail est dans les journaux, pas a l'ecran.
  inconnu,
}

/// L'echec d'une action de Classe, avec un motif que l'ecran sait dire.
///
/// **Jamais une erreur Postgres a l'ecran.** Le detail technique est conserve
/// pour les journaux ([detailTechnique]) et n'est jamais rendu : c'est
/// [messageHumain] qui parle a la personne.
class EchecDomaine implements Exception {
  /// Cree un echec.
  const EchecDomaine(this.motif, {this.detailTechnique});

  /// Traduit n'importe quelle erreur en echec de domaine.
  ///
  /// Les codes viennent de PostgREST et de Postgres : `PGRST202` quand une
  /// fonction n'existe pas sous cette signature, `42883` quand elle n'existe
  /// pas du tout, `42501` pour un refus de droit, `23505` pour un doublon,
  /// `P0001` pour une regle metier levee par `raise exception`. Un message
  /// metier se classe par ses mots, sans jamais etre recopie.
  factory EchecDomaine.depuis(Object erreur) {
    if (erreur is EchecDomaine) {
      return erreur;
    }
    if (erreur is PostgrestException) {
      return EchecDomaine(
        _motifPostgrest(erreur.code ?? '', erreur.message.toLowerCase()),
        detailTechnique: '${erreur.code}: ${erreur.message}',
      );
    }
    if (erreur is FunctionException) {
      final MotifEchec motif = switch (erreur.status) {
        401 || 403 => MotifEchec.refuse,
        404 => MotifEchec.capaciteAbsente,
        409 => MotifEchec.conflit,
        _ => MotifEchec.reseau,
      };
      return EchecDomaine(motif, detailTechnique: 'function ${erreur.status}');
    }
    if (erreur is TimeoutException) {
      return const EchecDomaine(MotifEchec.reseau, detailTechnique: 'timeout');
    }
    // `dart:io` n'entre pas dans un chemin compile pour le Web : une coupure
    // reseau se reconnait a son nom, sans importer son type.
    final String brut = erreur.toString();
    if (brut.contains('SocketException') ||
        brut.contains('ClientException') ||
        brut.contains('Failed host lookup')) {
      return EchecDomaine(MotifEchec.reseau, detailTechnique: brut);
    }
    return EchecDomaine(MotifEchec.inconnu, detailTechnique: brut);
  }

  /// Ce qui a empeche l'action.
  final MotifEchec motif;

  /// Le detail technique, pour les journaux. **Jamais affiche.**
  final String? detailTechnique;

  static MotifEchec _motifPostgrest(String code, String message) {
    if (code == 'PGRST202' ||
        code == 'PGRST200' ||
        code == '42883' ||
        code == '42P01' ||
        code == '42703') {
      return MotifEchec.capaciteAbsente;
    }
    if (code == '42501') {
      return MotifEchec.refuse;
    }
    if (code == '23505') {
      return MotifEchec.dejaInscrit;
    }
    if (code == '23P01' ||
        message.contains('chevauch') ||
        message.contains('overlap') ||
        message.contains('conflit')) {
      return MotifEchec.conflit;
    }
    if (message.contains('plafond') ||
        message.contains('complet') ||
        message.contains('capacit')) {
      return MotifEchec.complet;
    }
    if (message.contains('candidat')) {
      return MotifEchec.dejaCandidat;
    }
    if (message.contains('deja') || message.contains('déjà')) {
      return MotifEchec.dejaInscrit;
    }
    if (message.contains('refus') ||
        message.contains('autoris') ||
        message.contains('interdit')) {
      return MotifEchec.refuse;
    }
    return MotifEchec.inconnu;
  }

  @override
  String toString() => 'EchecDomaine($motif)';
}

/// Une publication en lot qui s'est arretee en chemin.
///
/// Le serveur transactionnel de la vague suivante rendra ce cas impossible ;
/// tant que la publication passe par une RPC par Classe, l'ecran doit pouvoir
/// dire combien ont abouti.
class EchecPublicationPartielle extends EchecDomaine {
  /// Cree un echec partiel.
  const EchecPublicationPartielle({
    required this.faites,
    required this.total,
    required MotifEchec motif,
    String? detailTechnique,
  }) : super(motif, detailTechnique: detailTechnique);

  /// Combien de Classes ont ete publiees avant l'echec.
  final int faites;

  /// Combien etaient demandees.
  final int total;
}

/// Le message a montrer pour un echec, dans la langue de l'application.
///
/// Prend n'importe quelle erreur : ce qui n'est pas deja un [EchecDomaine] est
/// traduit par [EchecDomaine.depuis]. **Aucune chaine technique ne sort
/// d'ici.**
String messageHumain(Object erreur) {
  final EchecDomaine echec = EchecDomaine.depuis(erreur);
  return switch (echec.motif) {
    MotifEchec.capaciteAbsente => t.classes.erreur.capaciteAbsente,
    MotifEchec.refuse => t.classes.erreur.refuse,
    MotifEchec.conflit => t.classes.erreur.conflit,
    MotifEchec.complet => t.classes.erreur.complet,
    MotifEchec.dejaInscrit => t.classes.erreur.dejaInscrit,
    MotifEchec.dejaCandidat => t.classes.erreur.dejaCandidat,
    MotifEchec.reseau => t.classes.erreur.reseau,
    MotifEchec.inconnu => t.classes.erreur.inconnu,
  };
}
