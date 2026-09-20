import '../i18n/strings.g.dart';
import 'annotation_layer.dart';
import 'intention_pedagogique.dart';
import 'port_dock_hote.dart';

/// Le libelle d'un outil du Teaching Dock.
String libelleOutilDock(OutilDock outil) => switch (outil) {
  OutilDock.bibliotheque => t.tc.outils.dock.bibliotheque,
  OutilDock.focus => t.tc.outils.dock.focus,
  OutilDock.marquer => t.tc.outils.dock.marquer,
  OutilDock.masquer => t.tc.outils.dock.masquer,
  OutilDock.stylet => t.tc.outils.dock.stylet,
  OutilDock.pointeur => t.tc.outils.dock.pointeur,
  OutilDock.revision => t.tc.outils.dock.revision,
};

/// Le libelle utilisateur d'une intention pedagogique.
///
/// **Les cinq libelles sont fixes par la spec (section 8.2)** : ils ne se
/// reformulent pas au fil des ecrans. Un marqueur porte toujours ce mot, et
/// jamais sa seule couleur.
String libelleIntentionPedagogique(IntentionPedagogique intention) =>
    switch (intention) {
      IntentionPedagogique.aApprendre => t.tc.outils.intention.aApprendre,
      IntentionPedagogique.aRevoir => t.tc.outils.intention.aRevoir,
      IntentionPedagogique.aRenforcer => t.tc.outils.intention.aRenforcer,
      IntentionPedagogique.aEntretenir => t.tc.outils.intention.aEntretenir,
      IntentionPedagogique.pourEvaluation =>
        t.tc.outils.intention.pourEvaluation,
    };

/// Le libelle d'un outil de trace.
String libelleOutilTrait(OutilTrait outil) => switch (outil) {
  OutilTrait.stylet => t.tc.outils.trait.stylet,
  OutilTrait.surligneur => t.tc.outils.trait.surligneur,
  OutilTrait.gomme => t.tc.outils.trait.gomme,
};

/// Le libelle d'une portee d'annotation.
///
/// Trois libelles qui disent **ce qui va se passer**, et non le nom technique
/// de la portee : « temporaire » ne dit rien a personne, « le temps
/// d'expliquer » dit tout.
String libellePorteeAnnotation(PorteeAnnotation portee) => switch (portee) {
  PorteeAnnotation.temporaire => t.tc.outils.portee.temporaire,
  PorteeAnnotation.seance => t.tc.outils.portee.seance,
  PorteeAnnotation.enregistree => t.tc.outils.portee.enregistree,
};
