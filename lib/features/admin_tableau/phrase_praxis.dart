// VIVANT (20/11/2026) : ce que Praxis dit sur l'accueil de la direction.
//
// Regles, simples et ecrites, sur les seuls compteurs lus au serveur :
//
// 1. Des candidats attendent un entretien et **aucun creneau n'est ouvert** :
//    c'est le blocage du moment, quel que soit le reste (personne ne peut
//    avancer sans la direction).
// 2. Sinon, la plus grande file parmi : pieces d'identite a valider, dossiers
//    d'identite a valider, demandes a trancher, conversations non lues. A
//    egalite, cet ordre.
// 3. Sinon, si rien n'attend de decision (la meme regle que la phrase calme
//    d'avant : quatre files vides, aucune alerte urgente ou importante), il
//    le dit.
// 4. Sinon (des eleves sans enseignant, des cahiers manquants ou une alerte,
//    que les tuiles et la section des alertes montrent deja), il se tait :
//    jamais « rien n'attend » quand quelque chose attend.
//
// Une lecture absente (capacite indisponible, echec) ne compte pas : `null`
// n'est jamais lu comme un zero qui parlerait.
import 'package:flutter/foundation.dart' show immutable;

import '../../core/i18n/strings.g.dart';
import '../../core/vivant/praxis_vivant.dart';

/// Ce qui bloque, du point de vue de Praxis.
enum SujetPraxis {
  /// Des entretiens a planifier, aucun creneau ouvert.
  creneaux,

  /// Des pieces d'identite de candidats a valider.
  pieces,

  /// Des dossiers d'identite a valider.
  dossiers,

  /// Des demandes a trancher.
  demandes,

  /// Des conversations non lues.
  messages,

  /// Rien n'attend de decision.
  calme,

  /// Quelque chose attend, que d'autres cases montrent : il se tait.
  silence,
}

/// La phrase de Praxis : son sujet et le nombre qu'elle porte.
@immutable
class PhrasePraxis {
  /// Cree la phrase.
  const PhrasePraxis(this.sujet, [this.nombre = 0]);

  /// Calcule la phrase depuis les compteurs lus ([null] : non lu).
  factory PhrasePraxis.depuis({
    required bool calme,
    int? entretiensAPlanifier,
    int? creneauxOuverts,
    int? pieces,
    int? dossiers,
    int? demandes,
    int? messages,
  }) {
    if ((entretiensAPlanifier ?? 0) > 0 && creneauxOuverts == 0) {
      return PhrasePraxis(SujetPraxis.creneaux, entretiensAPlanifier!);
    }
    PhrasePraxis meilleure = const PhrasePraxis(SujetPraxis.silence);
    void candidat(SujetPraxis sujet, int? n) {
      if (n != null && n > meilleure.nombre) {
        meilleure = PhrasePraxis(sujet, n);
      }
    }

    candidat(SujetPraxis.pieces, pieces);
    candidat(SujetPraxis.dossiers, dossiers);
    candidat(SujetPraxis.demandes, demandes);
    candidat(SujetPraxis.messages, messages);
    if (meilleure.nombre > 0) return meilleure;
    return PhrasePraxis(calme ? SujetPraxis.calme : SujetPraxis.silence);
  }

  /// Le sujet.
  final SujetPraxis sujet;

  /// Le nombre de personnes ou de lignes concernees.
  final int nombre;

  /// Le texte, ou rien quand il se tait.
  String? get texte {
    final v = t.admin.tableau.vivant;
    return switch (sujet) {
      SujetPraxis.creneaux => v.praxisCreneaux(n: nombre),
      SujetPraxis.pieces => v.praxisPieces(n: nombre),
      SujetPraxis.dossiers => v.praxisDossiers(n: nombre),
      SujetPraxis.demandes => v.praxisDemandes(n: nombre),
      SujetPraxis.messages => v.praxisMessages(n: nombre),
      SujetPraxis.calme => t.admin.tableau.calme,
      SujetPraxis.silence => null,
    };
  }

  /// L'humeur qui va avec.
  HumeurPraxis get humeur => switch (sujet) {
    SujetPraxis.creneaux => HumeurPraxis.soucieux,
    SujetPraxis.calme => HumeurPraxis.heureux,
    SujetPraxis.silence => HumeurPraxis.calme,
    _ => HumeurPraxis.curieux,
  };

  @override
  bool operator ==(Object other) =>
      other is PhrasePraxis && other.sujet == sujet && other.nombre == nombre;

  @override
  int get hashCode => Object.hash(sujet, nombre);
}
