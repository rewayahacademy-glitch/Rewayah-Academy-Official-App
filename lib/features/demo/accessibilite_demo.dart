// Donnees de demonstration du Mode Accessibilite (MA-1b, 00_MAQUETTES §4).
//
// Fictives, jamais une vraie identite, aucun age affiche, aucun appel
// serveur (K-28). La Classe, l'enseignant, les seances et le travail sont
// ceux de la demonstration de Classe (CL-4), reutilises et jamais recopies.

import '../../core/domain/enums.dart';
import '../../core/tc_groupe/group_home_vm.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import 'classe_demo.dart';

/// L'eleve de la demonstration.
enum EleveDemoAccessibilite {
  /// Mariam, mineure : le mode est fixe par le tuteur (DB-FOY-04).
  mariam,

  /// Idriss, adulte fictif : il pourra basculer lui-meme (MA24, en
  /// demonstration seulement ; serveur a BR-1).
  idriss,
}

/// Le moment de la seance.
enum MomentDemoAccessibilite {
  /// Avant la seance.
  avant,

  /// Pendant la seance.
  pendant,

  /// Apres la seance.
  apres,
}

/// Les donnees fictives du Mode Accessibilite.
abstract final class DonneesAccessibiliteDemo {
  /// Identifiant existant de Mariam (00_MAQUETTES §4).
  static const String mariamId = 'demo-eleve-mariam';

  /// Identifiant de l'adulte fictif.
  static const String idrissId = 'demo-eleve-idriss';

  /// L'identifiant de l'eleve.
  static String identifiant(EleveDemoAccessibilite eleve) => switch (eleve) {
    EleveDemoAccessibilite.mariam => mariamId,
    EleveDemoAccessibilite.idriss => idrissId,
  };

  /// Le prenom de l'eleve.
  static String prenom(EleveDemoAccessibilite eleve) => switch (eleve) {
    EleveDemoAccessibilite.mariam => 'Mariam',
    EleveDemoAccessibilite.idriss => 'Idriss',
  };

  /// Vrai pour l'eleve mineur.
  static bool mineur(EleveDemoAccessibilite eleve) =>
      eleve == EleveDemoAccessibilite.mariam;

  /// Les deux eleves sont en Mode Accessibilite (`InterfaceMode.enfant`,
  /// valeur SQL `child`).
  static const InterfaceMode presentation = InterfaceMode.enfant;

  /// La Classe : celle de la demonstration de Classe.
  static const String classe = DonneesClasseDemo.classe;

  /// L'identifiant de la Classe.
  static const String groupeId = DonneesClasseDemo.groupeId;

  /// L'enseignant par defaut, Sayyid Ibrahim (variante Sayyida).
  static const TitreEnseignant titre = TitreEnseignant.sayyid;

  /// Les seances de septembre et octobre 2026 (UTC).
  static final List<DateTime> seances = <DateTime>[
    DonneesClasseDemo.debutUtc,
    DateTime.utc(2026, 10, 5, 16),
    DateTime.utc(2026, 10, 12, 16),
  ];

  /// Le travail avant la seance : trois actions au plus.
  static int get nombreTravaux => DonneesClasseDemo.actions.length;

  /// La situation de Classe qui montre un moment.
  static EtatDemoClasse etatClasse(MomentDemoAccessibilite moment) =>
      switch (moment) {
        MomentDemoAccessibilite.avant => EtatDemoClasse.aVenir,
        MomentDemoAccessibilite.pendant => EtatDemoClasse.enDirect,
        MomentDemoAccessibilite.apres => EtatDemoClasse.terminee,
      };

  /// La Classe telle que l'Accueil de l'eleve la lit (MA-3) : la carte de
  /// seance CL-4 sans conseil d'appareil (peu d'elements ; il vit dans Ma
  /// classe), et les trois actions de la demonstration de Classe.
  static GroupHomeVM espaceAccueil(MomentDemoAccessibilite moment) {
    final GroupSummaryVM identite = DonneesClasseDemo.groupe(
      etatClasse(moment),
      titre: titre,
    );
    return GroupHomeVM(
      identite: identite,
      role: RoleEspaceGroupe.eleve,
      horloge: identite.horloge,
      avantProchainCours: DonneesClasseDemo.actions,
      bibliotheque: SlotBibliotheque(groupeId: identite.groupeId),
      afficheConseilAppareil: false,
    );
  }

  /// L'observation par le tuteur : active pendant la seance de Mariam
  /// seulement (jamais pour un adulte).
  static bool observationActive(
    EleveDemoAccessibilite eleve,
    MomentDemoAccessibilite moment,
  ) => mineur(eleve) && moment == MomentDemoAccessibilite.pendant;
}
