import 'package:flutter/material.dart';

import '../../core/tc_classe/libelles_tc_classe.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/video/pre_vol.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/status_pill.dart';
import '../salle/vue_salle.dart';

/// Ce que le pre-cours montre, selon le role.
///
/// **Trois comportements, et la spec section 9.5 les nomme** :
///
/// - **enseignant** : preflight complet -- micro, camera, et ce qu'il faut
///   faire si quelque chose manque. C'est lui qui ouvre la salle et accueille ;
/// - **eleve** : verifications **silencieuses**. Rien ne s'affiche tant que
///   rien ne bloque. Un enfant de sept ans n'a pas a lire un bilan materiel ;
/// - **tuteur** : **aucun test micro ni camera**. Il n'en publiera aucun -- sa
///   politique d'observation les interdit (decision D-14) -- donc les tester
///   serait au mieux inutile, au pire une demande de permission injustifiee.
enum DetailPreCours {
  /// Rien n'est teste, rien n'est montre.
  aucun,

  /// Teste, mais montre seulement en cas de blocage.
  silencieux,

  /// Teste et montre.
  complet,
}

/// Pourquoi l'entree est bloquee.
enum MotifPreCours {
  /// Le materiel ne rend aucune entree audio.
  ///
  /// **Le micro est la seule impasse bloquante** : pour une academie de Coran,
  /// l'audio prime sur la video. C'est la regle de `ResultatPreVol.peutEntrer`,
  /// elle existe deja, et elle n'est pas recalculee ici.
  microAbsent,

  /// L'acces au materiel a ete refuse. **La seule cause qui se repare ici.**
  permissionRefusee,
}

/// Le pre-cours, mis en forme.
///
/// **Fonction pure**, comme `VueSalle.depuis` : les trois roles et les deux
/// motifs se verifient sans monter d'ecran et sans materiel.
@immutable
class VuePreCours {
  const VuePreCours._({
    required this.detail,
    required this.bloque,
    required this.microPresent,
    required this.cameraPresente,
    this.motif,
  });

  /// Calcule le pre-cours.
  ///
  /// [resultat] vaut `null` tant que l'inspection n'a pas rendu : on ne bloque
  /// pas sur une absence de reponse, on attend. Confondre « pas encore mesure »
  /// et « aucun micro » refuserait l'entree a qui en a un.
  factory VuePreCours.depuis({
    required RoleSalle role,
    required ResultatPreVol? resultat,
  }) {
    final DetailPreCours detail = switch (role) {
      RoleSalle.enseignant => DetailPreCours.complet,
      RoleSalle.eleve => DetailPreCours.silencieux,
      // Le tuteur observateur et le controleur n'ouvrent ni micro ni camera :
      // leur jeton le leur interdit. Le controleur, en plus, est invisible.
      RoleSalle.tuteurObservateur ||
      RoleSalle.controleur ||
      RoleSalle.inconnu => DetailPreCours.aucun,
    };

    if (resultat == null || detail == DetailPreCours.aucun) {
      return VuePreCours._(
        detail: detail,
        bloque: false,
        microPresent: resultat?.microDisponible ?? false,
        cameraPresente: resultat?.cameraDisponible ?? false,
      );
    }

    final bool bloque = !resultat.peutEntrer;
    return VuePreCours._(
      detail: detail,
      bloque: bloque,
      microPresent: resultat.microDisponible,
      cameraPresente: resultat.cameraDisponible,
      motif: !bloque
          ? null
          : resultat.permissionRefusee
          ? MotifPreCours.permissionRefusee
          : MotifPreCours.microAbsent,
    );
  }

  /// Ce que ce role voit.
  final DetailPreCours detail;

  /// Vrai quand l'entree est empechee.
  final bool bloque;

  /// Une entree audio est utilisable.
  final bool microPresent;

  /// Une camera est utilisable. **Jamais bloquant.**
  final bool cameraPresente;

  /// La cause du blocage, quand il y en a un.
  final MotifPreCours? motif;

  /// Y a-t-il quelque chose a afficher ?
  ///
  /// Un eleve dont tout va bien ne voit rien : c'est exactement ce que dit la
  /// spec -- « verifications silencieuses, action uniquement si un probleme
  /// bloque ».
  bool get visible =>
      bloque || detail == DetailPreCours.complet;
}

/// Le pre-cours a l'ecran.
class PreCours extends StatelessWidget {
  /// Cree le pre-cours.
  const PreCours({required this.vue, required this.onReessayer, super.key});

  /// Ce qu'il y a a montrer.
  final VuePreCours vue;

  /// Remesure le materiel. Un casque branche entre deux essais doit compter.
  final VoidCallback onReessayer;

  @override
  Widget build(BuildContext context) {
    if (!vue.visible) {
      return const SizedBox.shrink();
    }
    final TextTheme textes = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              LibellesClasse.prevolTitre,
              textAlign: TextAlign.center,
              style: textes.titleMedium ?? const TextStyle(),
            ),
            Ecart.vLg,
            if (vue.detail == DetailPreCours.complet) ...<Widget>[
              StatusPill(
                libelle: vue.microPresent
                    ? LibellesClasse.prevolMicroOk
                    : LibellesClasse.prevolMicroAbsent,
                ton: vue.microPresent ? TonEtat.succes : TonEtat.alerte,
              ),
              Ecart.vSm,
              // La camera n'est **jamais** bloquante : un cours de Coran se suit
              // a la voix. Son absence est donc un avertissement, pas une
              // alerte.
              StatusPill(
                libelle: vue.cameraPresente
                    ? LibellesClasse.prevolCameraOk
                    : LibellesClasse.prevolCameraAbsente,
                ton: vue.cameraPresente
                    ? TonEtat.succes
                    : TonEtat.avertissement,
              ),
              Ecart.vLg,
            ],
            if (vue.motif case final MotifPreCours motif) ...<Widget>[
              Text(
                switch (motif) {
                  MotifPreCours.permissionRefusee =>
                    LibellesClasse.prevolPermissionRefusee,
                  MotifPreCours.microAbsent =>
                    LibellesClasse.prevolMicroAbsent,
                },
                textAlign: TextAlign.center,
                style: textes.bodyMedium ?? const TextStyle(),
              ),
              Ecart.vLg,
              ActionPrincipale(
                libelle: LibellesClasse.prevolReessayer,
                onPress: onReessayer,
                niveau: NiveauAction.secondaire,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
