// Le Studio : la boite d'activite (`ActivityInbox`, COM-STU-2 ; spec
// section 8.1, section 7 regle anti-doublon, R-COM-11).
//
// Un groupe a filets par rubrique d'Aujourd'hui (`GroupeReglages`, une seule
// surface, jamais une carte par ligne). Chaque ligne dit ce qui se passe
// (libelle court du serveur), d'ou cela vient (le module ou le canal), qui
// (si le serveur l'autorise), quand, et son attention par un badge texte et
// icone (`BadgeNonLu`, jamais la couleur seule).
//
// Une ligne avec destination porte un chevron et l'ouvre dans son module
// canonique ; le Studio n'execute rien (R-COM-11). Une ligne sans
// destination (Finance, Planning : aucune page aujourd'hui) est nommee sans
// chevron ni geste, avec la phrase « Se traite dans Finance » : rien n'est
// grise.

import 'package:flutter/material.dart';

import '../../core/communications/lecture_fil_communication.dart'
    show horodatageMessage;
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/widgets/badge_non_lu.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../accueil_famille/bloc_seance.dart' show dateDeLAppareil;
import 'port_activite_studio.dart';

/// Le nom d'un module canonique.
String libelleModule(ModuleCanonique module) {
  final m = t.com.studio.aujourdhui.modules;
  return switch (module) {
    ModuleCanonique.studio => m.studio,
    ModuleCanonique.finance => m.finance,
    ModuleCanonique.planning => m.planning,
    ModuleCanonique.dossiers => m.dossiers,
    ModuleCanonique.classes => m.classes,
    ModuleCanonique.admissions => m.admissions,
    ModuleCanonique.demandes => m.demandes,
    ModuleCanonique.communications => m.communications,
  };
}

/// L'icone d'une ligne d'activite : celle de son module, sauf pour le
/// Studio, ou elle dit le type (mention, reponse, fichier).
AppIcon iconeActivite(ActiviteStudio activite) => switch (activite.module) {
  ModuleCanonique.finance => AppIcons.finance,
  ModuleCanonique.planning => AppIcons.planningGlobal,
  ModuleCanonique.dossiers || ModuleCanonique.admissions => AppIcons.dossiers,
  ModuleCanonique.classes => AppIcons.classes,
  ModuleCanonique.demandes => AppIcons.reaffectation,
  ModuleCanonique.communications => AppIcons.notifications,
  ModuleCanonique.studio => switch (activite.type) {
    TypeActivite.mention || TypeActivite.reponse => AppIcons.envoyerMessage,
    TypeActivite.fichierPartage => AppIcons.fichierPdf,
    TypeActivite.decisionDemandee => AppIcons.flecheAction,
    TypeActivite.annonceImportante => AppIcons.notifications,
    TypeActivite.messageNonLu ||
    TypeActivite.actionStudio ||
    TypeActivite.changementModule => AppIcons.discussion,
  },
};

/// [texte] pose au milieu d'une phrase : sa premiere lettre en minuscule
/// (« Échéance le mardi 6 octobre », jamais « le Mardi » ; revue COM-R,
/// R-14). Sans effet sur une ecriture sans casse (arabe).
String dansPhrase(String texte) => texte.isEmpty
    ? texte
    : texte.substring(0, 1).toLowerCase() + texte.substring(1);

/// La legende d'une ligne : l'echeance s'il y en a une, la source (le canal
/// pour le Studio, le module sinon), l'auteur s'il est autorise, l'instant ;
/// et, sans destination, ou elle se traite.
String legendeActivite(ActiviteStudio activite) {
  final a = t.com.studio.aujourdhui;
  final DateTime? echeance = activite.echeance;
  final String source = activite.module == ModuleCanonique.studio
      ? a.dansCanal(nom: activite.objet.libelle)
      : libelleModule(activite.module);
  final List<String> morceaux = <String>[
    if (echeance != null)
      a.echeance(date: dansPhrase(dateDeLAppareil(echeance.toLocal()))),
    source,
    ?activite.auteur?.nomAffiche,
    horodatageMessage(activite.survenueLe),
  ];
  final String legende = morceaux.join(' · ');
  if (activite.destination != null) return legende;
  return '$legende\n${a.seTraiteDans(module: libelleModule(activite.module))}';
}

/// Une rubrique de la boite d'activite : son titre et ses lignes, ou une
/// ligne calme qui dit qu'il n'y a rien.
class BoiteActivite extends StatelessWidget {
  /// Cree la rubrique.
  const BoiteActivite({
    required this.titre,
    required this.vide,
    required this.activites,
    required this.onOuvrir,
    super.key,
  });

  /// Le titre de la rubrique (« A traiter aujourd'hui »).
  final String titre;

  /// La phrase rendue quand la rubrique n'a aucune ligne.
  final String vide;

  /// Les lignes, deja rangees.
  final List<ActiviteStudio> activites;

  /// Ouvre une ligne dans son module canonique (et la marque lue).
  final void Function(ActiviteStudio activite, DestinationStudio destination)
  onOuvrir;

  /// La cle du badge d'une ligne, pour les tests.
  static ValueKey<String> cleBadge(String id) =>
      ValueKey<String>('studio-activite-badge-$id');

  @override
  Widget build(BuildContext context) => GroupeReglages(
    titre: titre,
    lignes: activites.isEmpty
        ? <LigneRubrique>[LigneRubrique(icone: AppIcons.succes, libelle: vide)]
        : <LigneRubrique>[for (final ActiviteStudio a in activites) _ligne(a)],
  );

  LigneRubrique _ligne(ActiviteStudio activite) {
    final DestinationStudio? destination = activite.destination;
    final Widget marque = BadgeNonLu(
      key: cleBadge(activite.id),
      indicateur: activite.indicateur,
      compact: true,
    );
    if (destination == null) {
      return LigneRubrique(
        icone: iconeActivite(activite),
        libelle: activite.libelle,
        legende: legendeActivite(activite),
        marque: marque,
      );
    }
    return LigneRubrique(
      icone: iconeActivite(activite),
      libelle: activite.libelle,
      legende: legendeActivite(activite),
      marque: marque,
      libelleSemantique: t.com.studio.aujourdhui.ouvrirDans(
        module: libelleModule(destination.module),
        libelle: activite.libelle,
      ),
      onPress: () => onOuvrir(activite, destination),
    );
  }
}
