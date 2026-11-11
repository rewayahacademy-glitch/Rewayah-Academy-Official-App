import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'reprise_salle_natif.dart'
    if (dart.library.js_interop) 'reprise_salle_web.dart'
    as onglet;
import 'routes.dart';

/// Le droit d'entrer dans une salle, valable une fois.
///
/// L'ADR-005 exige qu'aucune route de salle ne soit partageable ni memorisable
/// en favori : l'URL de la salle est ephemere et regeneree a chaque entree.
///
/// Ce billet transite par le champ `extra` de go_router, qui n'est **pas**
/// serialise dans l'URL et ne survit pas a un rechargement de page. Une adresse
/// copiee, collee dans un autre onglet ou rouverte le lendemain arrive donc
/// sans billet, et la redirection renvoie a la racine du role. La proprete de
/// ce comportement ne tient a aucune verification supplementaire : elle tient a
/// la nature du transport choisi.
///
/// La vraie barriere reste serveur : le jeton LiveKit n'est emis que dans la
/// fenetre que la base regle (20 minutes avant, jusqu'a la fin plus 15 minutes
/// par defaut), apres verification de l'appartenance a la seance.
///
/// SITUATIONS-GRAVES (11/11/2026) : un rechargement de la page pendant la
/// seance retrouve la salle par [RepriseSalle], qui ne garde jamais de droit.
@immutable
class BilletSalle {
  /// Cree un billet pour une seance.
  const BilletSalle({
    required this.sessionId,
    required this.emisA,
    this.preparation = false,
    this.groupeId,
    this.eleveId,
    this.interfaceGuidee = false,
  });

  /// L'eleve qui rejoint la salle depuis l'appareil de son tuteur (D6), ou
  /// `null` quand la personne connectee entre pour elle-meme. Le jeton est
  /// alors celui de l'eleve, et le serveur seul en decide.
  final String? eleveId;

  /// Vrai quand la salle s'ouvre dans l'Interface guidee de l'eleve [eleveId].
  final bool interfaceGuidee;

  /// Ouvrir d'abord la preparation de l'enseignant (CLV-03, CL-4.5).
  final bool preparation;

  /// La classe d'origine, pour « Retour a la Classe ».
  final String? groupeId;

  /// La seance visee.
  final String sessionId;

  /// Instant d'emission cote client. Sert uniquement a purger un billet reste
  /// en memoire trop longtemps, jamais a autoriser quoi que ce soit.
  final DateTime emisA;

  /// Duree au-dela de laquelle un billet garde en memoire n'est plus presente.
  static const Duration duree = Duration(minutes: 20);

  /// Vrai quand le billet est encore presentable.
  bool valideA(DateTime maintenant) =>
      maintenant.difference(emisA) < duree && !maintenant.isBefore(emisA);
}

/// SITUATIONS-GRAVES (directeur, 11/11/2026, defaut n° 4 du releve) : de quoi
/// redemander l'entree apres un rechargement de la page ou un plantage du
/// navigateur, dans le MEME onglet.
///
/// **Aucun droit n'est garde** : ni jeton, ni capacite, ni role. Seulement
/// la seance, la classe et l'eleve, ce que portait deja le billet. La salle
/// redemande un jeton neuf a `create-room-token`, qui reverifie tout (heure,
/// inscription, acces) ; micro et camera fermes, comme a toute entree.
///
/// Le stockage est celui de l'onglet (`sessionStorage`) : il meurt avec lui
/// et ne passe a aucun autre onglet. Une adresse copiee dans un autre onglet
/// ou rouverte le lendemain arrive toujours sans billet (ADR-005 tenu).
abstract final class RepriseSalle {
  /// La cle du stockage de l'onglet.
  static const String cle = 'rewayah.reprise_salle';

  /// Au-dela, la reprise est oubliee : aucune seance ne dure autant.
  static const Duration duree = Duration(hours: 4);

  /// Retient [billet] a l'entree en salle.
  static void retenir(BilletSalle billet, {DateTime? maintenant}) {
    onglet.ecrireDansOnglet(
      cle,
      jsonEncode(<String, Object?>{
        'seance': billet.sessionId,
        'classe': billet.groupeId,
        'eleve': billet.eleveId,
        'guidee': billet.interfaceGuidee,
        'le': (maintenant ?? DateTime.now()).toUtc().toIso8601String(),
      }),
    );
  }

  /// Oublie la reprise (sortie volontaire, seance finie).
  static void oublier() => onglet.ecrireDansOnglet(cle, null);

  /// Le billet a presenter apres un rechargement, ou `null`. Il ouvre la
  /// salle directement (jamais la preparation) ; le serveur reste seul juge.
  static BilletSalle? lire(DateTime maintenant) {
    final String? brut = onglet.lireDansOnglet(cle);
    if (brut == null) return null;
    try {
      final Object? lu = jsonDecode(brut);
      if (lu is! Map) throw const FormatException();
      final Object? seance = lu['seance'];
      final DateTime? le = DateTime.tryParse('${lu['le']}');
      if (seance is! String || seance.isEmpty || le == null) {
        throw const FormatException();
      }
      final Duration age = maintenant.difference(le);
      if (age.isNegative || age > duree) {
        oublier();
        return null;
      }
      final Object? classe = lu['classe'];
      final Object? eleve = lu['eleve'];
      return BilletSalle(
        sessionId: seance,
        emisA: maintenant,
        groupeId: classe is String ? classe : null,
        eleveId: eleve is String ? eleve : null,
        interfaceGuidee: lu['guidee'] == true,
      );
    } on Object {
      oublier();
      return null;
    }
  }
}

/// Le billet d'une navigation : celui de `extra`, sinon, pour la salle
/// seulement, la reprise de l'onglet ([RepriseSalle]).
BilletSalle? billetDe(
  Object? extra, {
  required String chemin,
  DateTime? maintenant,
}) {
  if (extra is BilletSalle) return extra;
  if (chemin != Routes.salle) return null;
  return RepriseSalle.lire(maintenant ?? DateTime.now());
}
