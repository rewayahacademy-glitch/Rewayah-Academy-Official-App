import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../tc_bibliotheque/content_position.dart';
import '../tc_bibliotheque/content_range.dart';
import 'annotation_layer.dart';
import 'intention_pedagogique.dart';
import 'masquage.dart';
import 'port_dock_hote.dart';

/// Ou le dock est pose.
///
/// Trois positions, celles de la spec (section 8) : bas, gauche, droite. Il n'y
/// a pas de « haut » -- c'est la ou vivent le titre de l'ecran et l'etat de la
/// seance.
enum PositionDock {
  /// Bord bas. Le defaut : c'est la que le pouce arrive sur un telephone.
  bas('bas'),

  /// Bord de debut de lecture.
  gauche('gauche'),

  /// Bord de fin de lecture.
  droite('droite');

  const PositionDock(this.valeur);

  /// La valeur memorisee localement.
  final String valeur;

  /// Lit une position depuis sa valeur memorisee. `null` sur valeur inconnue :
  /// on retombe alors sur le defaut, ce qui est sans consequence.
  static PositionDock? depuisValeur(String? valeur) {
    for (final PositionDock position in PositionDock.values) {
      if (position.valeur == valeur) {
        return position;
      }
    }
    return null;
  }
}

/// La memorisation **locale** de la position du dock.
///
/// « Position memorisee localement » (spec section 8) : elle suit l'appareil,
/// pas le compte. Un enseignant gaucher sur sa tablette n'impose rien a
/// personne.
///
/// **Aucun stockage durable n'existe aujourd'hui dans le depot pour cela** :
/// `PreferencesLocales` est declaree en memoire seule, et la base Drift
/// (`AppDatabase`) exige une justification de spec et une migration 1->2 pour
/// une table de plus. L'implementation livree est donc en memoire, et la
/// demande de persistance est ecrite dans `TC_CONTRACT_REQUEST_D.md` section 4.
abstract class PortPositionDock {
  /// La position memorisee, ou `null` si rien n'a jamais ete memorise.
  PositionDock? lire();

  /// Memorise une position.
  void ecrire(PositionDock position);
}

/// La memorisation en memoire, le temps de la session applicative.
class PositionDockMemoire implements PortPositionDock {
  /// Cree une memorisation vide.
  PositionDockMemoire([this._position]);

  PositionDock? _position;

  @override
  PositionDock? lire() => _position;

  @override
  void ecrire(PositionDock position) => _position = position;
}

/// La memorisation employee par l'application.
final Provider<PortPositionDock> portPositionDockProvider =
    Provider<PortPositionDock>((Ref ref) => PositionDockMemoire());

/// L'etat des outils pedagogiques, a un instant donne.
///
/// **C'est le seul canal par lequel le dock parle a son hote.** L'hote observe
/// cet etat et applique ce qu'il decrit : mettre une plage au centre, cacher un
/// passage, laisser passer le stylet. Le dock n'appelle jamais une methode de
/// rendu de l'hote.
@immutable
class EtatOutils {
  /// Cree un etat d'outils.
  const EtatOutils({
    this.outilActif,
    this.position = PositionDock.bas,
    this.focus,
    this.masquage = PlanMasquage.aucun,
    this.outilTrait = OutilTrait.stylet,
    this.intention = IntentionPedagogique.aRevoir,
    this.portee = PorteeAnnotation.temporaire,
    this.pointeur,
  });

  /// L'outil retenu. `null` = aucun, le support se lit normalement.
  final OutilDock? outilActif;

  /// Ou le dock est pose.
  final PositionDock position;

  /// La plage mise au centre. `null` = pas de focus.
  final ContentRange? focus;

  /// Ce qui est masque, et ce qui a ete revele.
  final PlanMasquage masquage;

  /// L'outil de trace courant.
  final OutilTrait outilTrait;

  /// L'intention courante.
  ///
  /// « A revoir » par defaut : c'est le cas le plus frequent d'une seance, et
  /// un defaut sur « A renforcer » ferait passer une revision ordinaire pour
  /// une faiblesse.
  final IntentionPedagogique intention;

  /// La portee des annotations posees.
  ///
  /// « Temporaire » par defaut : **rien ne se conserve tant que personne ne
  /// l'a demande**. Un trait d'explication qui se retrouverait enregistre sur
  /// le Coran d'un eleve serait une surprise, jamais un service.
  final PorteeAnnotation portee;

  /// L'indication ephemere en cours. **Jamais persistee** : elle vit dans cet
  /// etat le temps du geste, et ne produit aucune couche d'annotation.
  final ContentPosition? pointeur;

  /// Vrai quand le chrome doit s'effacer : c'est le propre du focus.
  bool get chromeReduit => focus != null;

  /// Vrai quand le stylet est arme.
  bool get styletArme => outilActif == OutilDock.stylet;

  /// Copie l'etat en changeant ce qui est donne.
  ///
  /// Les quatre champs annulables ont leur propre drapeau : sans lui, on ne
  /// saurait pas distinguer « ne change pas le focus » de « retire le focus ».
  EtatOutils copier({
    OutilDock? outilActif,
    bool retirerOutil = false,
    PositionDock? position,
    ContentRange? focus,
    bool retirerFocus = false,
    PlanMasquage? masquage,
    OutilTrait? outilTrait,
    IntentionPedagogique? intention,
    PorteeAnnotation? portee,
    ContentPosition? pointeur,
    bool retirerPointeur = false,
  }) => EtatOutils(
    outilActif: retirerOutil ? null : (outilActif ?? this.outilActif),
    position: position ?? this.position,
    focus: retirerFocus ? null : (focus ?? this.focus),
    masquage: masquage ?? this.masquage,
    outilTrait: outilTrait ?? this.outilTrait,
    intention: intention ?? this.intention,
    portee: portee ?? this.portee,
    pointeur: retirerPointeur ? null : (pointeur ?? this.pointeur),
  );

  @override
  bool operator ==(Object other) =>
      other is EtatOutils &&
      other.outilActif == outilActif &&
      other.position == position &&
      other.focus == focus &&
      other.masquage == masquage &&
      other.outilTrait == outilTrait &&
      other.intention == intention &&
      other.portee == portee &&
      other.pointeur == pointeur;

  @override
  int get hashCode => Object.hash(
    outilActif,
    position,
    focus,
    masquage,
    outilTrait,
    intention,
    portee,
    pointeur,
  );
}

/// L'etat courant des outils pedagogiques.
final NotifierProvider<ControleurOutils, EtatOutils> etatOutilsProvider =
    NotifierProvider<ControleurOutils, EtatOutils>(ControleurOutils.new);

/// Porte les gestes du Teaching Dock.
class ControleurOutils extends Notifier<EtatOutils> {
  @override
  EtatOutils build() => EtatOutils(
    position: ref.read(portPositionDockProvider).lire() ?? PositionDock.bas,
  );

  /// Retient un outil, ou le relache s'il l'etait deja.
  ///
  /// Un deuxieme appui sur l'outil actif le repose : c'est le geste attendu
  /// d'une barre d'outils, et cela evite un bouton « arreter » de plus.
  void choisirOutil(OutilDock outil) => state = state.outilActif == outil
      ? state.copier(retirerOutil: true)
      : state.copier(outilActif: outil);

  /// Relache l'outil courant.
  void relacherOutil() => state = state.copier(retirerOutil: true);

  /// Deplace le dock et memorise sa position.
  void deplacerDock(PositionDock position) {
    ref.read(portPositionDockProvider).ecrire(position);
    state = state.copier(position: position);
  }

  /// Met une plage au centre et reduit le chrome.
  void mettreAuFocus(ContentRange plage) => state = state.copier(focus: plage);

  /// Quitte le focus et rend le chrome.
  void quitterFocus() => state = state.copier(retirerFocus: true);

  /// Masque une plage.
  void masquer(ContentRange plage) =>
      state = state.copier(masquage: state.masquage.masquer(plage));

  /// Revele une plage masquee.
  void reveler(ContentRange plage) =>
      state = state.copier(masquage: state.masquage.reveler(plage));

  /// Retire une plage du masquage.
  void demasquer(ContentRange plage) =>
      state = state.copier(masquage: state.masquage.demasquer(plage));

  /// Referme toutes les revelations.
  void toutRefermer() =>
      state = state.copier(masquage: state.masquage.toutRefermer());

  /// Retire tout masquage.
  void viderMasquage() => state = state.copier(masquage: PlanMasquage.aucun);

  /// Change l'outil de trace.
  void choisirOutilTrait(OutilTrait outil) =>
      state = state.copier(outilTrait: outil);

  /// Change l'intention courante.
  void choisirIntention(IntentionPedagogique intention) =>
      state = state.copier(intention: intention);

  /// Change la portee des annotations posees.
  void choisirPortee(PorteeAnnotation portee) =>
      state = state.copier(portee: portee);

  /// Deplace l'indication ephemere. `null` la retire.
  void pointer(ContentPosition? position) => state = position == null
      ? state.copier(retirerPointeur: true)
      : state.copier(pointeur: position);
}
