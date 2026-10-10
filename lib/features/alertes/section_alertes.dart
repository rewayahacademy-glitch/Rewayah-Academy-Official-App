import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/alertes/alerte.dart';
import '../../core/alertes/port_alertes.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import 'ligne_alerte.dart';

/// Combien de lignes d'alerte le Centre de commande montre au plus, hors
/// alertes urgentes (DASH_STRATEGIE D6 : trois lignes, puis « Voir tout »).
const int lignesAlertesTableau = 3;

/// Les alertes que montre un tableau de bord : TOUTES les urgentes (une
/// alerte urgente reste en tete jusqu'a son traitement, jamais cachee
/// derriere « Voir tout »), puis les suivantes jusqu'a [lignesAlertesTableau]
/// lignes. [triees] est deja dans l'ordre de lecture.
List<Alerte> alertesDuTableau(List<Alerte> triees) {
  final int urgentes = triees.where((Alerte a) => a.urgente).length;
  final int lignes = urgentes > lignesAlertesTableau
      ? urgentes
      : lignesAlertesTableau;
  return triees.take(lignes).toList();
}

/// L'etat de la lecture des alertes, partage par la section et la page.
///
/// Cinq etats : chargement (squelette de lignes), contenu, vide, erreur
/// (« Reessayer »), et hors ligne. Hors ligne se dit UNE fois (K-42,
/// EA-HL-DOUBLE-1) : le bandeau de `PageShell` le dit ; une liste deja lue
/// reste affichee, et sans elle le bloc dit ce qui manque, jamais « hors
/// ligne ». Une source absente se dit « indisponible », sans « Reessayer ».
class LectureAlertes extends ConsumerWidget {
  /// Cree le bloc.
  const LectureAlertes({
    required this.construire,
    required this.vide,
    this.lignesSquelette = 2,
    super.key,
  });

  /// Le contenu, une fois les alertes lues et non vides.
  final Widget Function(List<Alerte> alertes) construire;

  /// Ce qui s'affiche quand aucune alerte n'est ouverte.
  final Widget vide;

  /// Le nombre de lignes du squelette.
  final int lignesSquelette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final AsyncValue<List<Alerte>> alertes = lectureHorsLigne(
      ref.watch(alertesProvider),
      horsLigne: horsLigne,
    );
    void relire() => ref.invalidate(alertesProvider);
    if (sansDonneesHorsLigne(alertes, horsLigne: horsLigne)) {
      return EtatSansDonnees(quoi: t.alertes.sansDonnees, onAction: relire);
    }
    return BlocAsynchrone<List<Alerte>>(
      valeur: alertes,
      squelette: Skeleton.liste(lignes: lignesSquelette),
      onReessayer: relire,
      titreEchec: t.alertes.erreurTitre,
      erreurVersEtat: (Object erreur, VoidCallback? _) =>
          erreur is CapaciteIndisponible
          ? EtatSysteme(
              nature: NatureEtat.indisponible,
              titre: t.alertes.indisponibleTitre,
              phrase: t.alertes.indisponiblePhrase,
              dependance: erreur.dependance,
            )
          : null,
      vide: vide,
      construire: construire,
    );
  }
}

/// La section « Alertes » du Centre de commande (`ADM-01`, ALERTE-1).
///
/// Toutes les alertes urgentes, puis les suivantes jusqu'a trois lignes, et
/// « Voir toutes les alertes » quand il en reste. Sa place sur la page se
/// decide dans le Centre de commande : en tete quand une alerte urgente est
/// ouverte, sinon apres les compteurs. Le titre reste pose dans tous les
/// etats : un chargement, un echec ou une source absente disent de quoi ils
/// parlent.
class SectionAlertes extends ConsumerWidget {
  /// Cree la section.
  const SectionAlertes({
    required this.onOuvrir,
    required this.onVoirTout,
    super.key,
  });

  /// Ouvre la page ou une alerte se traite.
  final void Function(String chemin) onOuvrir;

  /// Ouvre la page des alertes.
  final VoidCallback onVoirTout;

  /// Cle stable, pour mesurer sa place sur la page.
  static const Key cle = ValueKey<String>('section-alertes');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Le chiffre et le lien ne se posent que sur une liste lue : jamais un
    // 0 pour une source absente ou en echec (D10).
    final List<Alerte>? lues = ref.watch(alertesProvider).value;
    final bool reste =
        lues != null && alertesDuTableau(lues).length < lues.length;
    return Column(
      key: cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SectionHeader(
          titre: t.alertes.titre,
          compteur: lues?.length,
          libelleAction: reste ? t.alertes.voirTout : null,
          onAction: reste ? onVoirTout : null,
        ),
        Ecart.vMd,
        LectureAlertes(
          vide: Text(
            t.alertes.vide,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          construire: (List<Alerte> alertes) => ListeAlertes(
            alertes: alertesDuTableau(alertes),
            onOuvrir: onOuvrir,
          ),
        ),
      ],
    );
  }
}
