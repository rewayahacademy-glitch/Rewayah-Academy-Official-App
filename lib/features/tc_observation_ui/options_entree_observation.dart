import 'package:flutter/foundation.dart';

import '../../core/domain/enums.dart';
import '../../core/tc_observation/guardian_session_visit.dart';
import '../../core/tc_observation/libelles_tc_g.dart';
import '../../core/tc_observation/mode_entree_admin.dart';

/// Ce qu'un compte peut faire devant la porte d'une seance.
///
/// **Fonction pure.** Elle repond a une seule question, et c'est celle qui
/// porte la decision D-16 : qui a le choix de son mode ? Un seul role l'a,
/// l'administration. Le controle qualite ne l'a pas, et la specification 11.6
/// le dit en une ligne -- « ne pas lui donner le choix d'un mode visible dans
/// ce chantier ». Le tuteur ne l'a pas non plus : son mode est fixe par la
/// politique, pas par lui.
///
/// Ecrire cela ici plutot que dans le widget est ce qui rend la regle
/// verifiable : [modes] vide se teste, une carte absente de l'arbre se teste
/// aussi, mais seule la premiere survit a une refonte de l'ecran.
@immutable
class OptionsEntreeObservation {
  const OptionsEntreeObservation._({
    required this.modes,
    required this.intro,
    this.role,
  });

  /// Les options offertes a un role applicatif.
  ///
  /// Un role absent de cette liste n'observe pas : ni l'enseignant, qui est
  /// dans la salle, ni l'eleve, ni la comptabilite. Le repli est le plus ferme,
  /// comme celui de `RoleSalle.depuis`.
  factory OptionsEntreeObservation.pour(AppRole? role) => switch (role) {
    AppRole.guardian => const OptionsEntreeObservation._(
      role: RoleObservateur.tuteur,
      modes: <ModeEntreeAdmin>[],
      intro: LibellesTcG.entreeTuteurIntro,
    ),
    AppRole.admin => const OptionsEntreeObservation._(
      // Le mode discret est le defaut : entrer sans perturber est le geste le
      // plus frequent, et c'est aussi le moins invasif des deux.
      role: RoleObservateur.adminIncognito,
      modes: ModeEntreeAdmin.values,
      intro: LibellesTcG.entreeAdminIntro,
    ),
    AppRole.controller => const OptionsEntreeObservation._(
      role: RoleObservateur.controleur,
      modes: <ModeEntreeAdmin>[],
      intro: LibellesTcG.entreeControleurIntro,
    ),
    AppRole.teacher || AppRole.student || AppRole.accountant || null =>
      const OptionsEntreeObservation._(
        modes: <ModeEntreeAdmin>[],
        intro: LibellesTcG.roleSansObservation,
      ),
  };

  /// Le role d'observation tenu par defaut. `null` quand ce compte n'observe
  /// aucune seance.
  final RoleObservateur? role;

  /// Les modes proposes. **Vide pour tout role sauf l'administration.**
  final List<ModeEntreeAdmin> modes;

  /// Ce que l'ecran explique avant l'entree.
  final String intro;

  /// Vrai quand ce compte peut demander a observer.
  bool get observationPossible => role != null;

  /// Vrai quand l'ecran affiche un choix de mode.
  bool get choisitSonMode => modes.isNotEmpty;

  /// Le role effectivement demande, mode retenu compris.
  ///
  /// Sans choix de mode, le mode retenu est ignore : passer
  /// `ModeEntreeAdmin.rejoindreLaClasse` a un controleur ne lui ouvre rien.
  RoleObservateur? roleDemande(ModeEntreeAdmin? modeRetenu) {
    if (!choisitSonMode || modeRetenu == null) {
      return role;
    }
    return modes.contains(modeRetenu) ? modeRetenu.role : role;
  }
}
