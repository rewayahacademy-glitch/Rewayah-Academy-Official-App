// PUSH-1 (07/11/2026, DECISION-PUSH-2026-11-01 amendee le 07/11) : les
// Reglages des notifications sur l'appareil, ouverts depuis la page
// Notifications, que tous les roles atteignent (le routeur n'a pas de route
// nouvelle). Cinq etats : chargement, contenu, vide (compte sans push : un
// enfant ou un compte inactif), erreur, hors ligne.
//
// Regles tenues ici :
//   - l'autorisation du navigateur n'est demandee qu'apres le geste de la
//     personne (« Recevoir les notifications sur cet appareil »), jamais a
//     l'ouverture ; la cle publique est lue d'avance pour que la demande suive
//     le geste sans attente ;
//   - le serveur decide qui peut s'abonner et ce qui part ; la feuille ne fait
//     qu'afficher et transmettre ;
//   - un seul bouton plein (K-56), au pied de la feuille ; un bouton qui ne peut pas aboutir
//     n'est pas rendu, une phrase dit pourquoi et quoi faire (K-59).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/push/port_push.dart';
import '../../core/push/reglages_push.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/skeleton.dart';

/// Ouvre les Reglages des notifications sur l'appareil. Le bouton de
/// l'appareil est dans la zone d'actions, collee au pied de la feuille :
/// visible sans faire defiler les categories (390, texte agrandi).
Future<void> ouvrirReglagesPush(BuildContext context) =>
    AppBottomSheet.ouvrir<void>(
      context,
      titre: t.push1.reglages.titre,
      constructeur: (BuildContext _) => const ReglagesPushVue(),
      actions: (BuildContext _) => const ActionReglagesPush(),
    );

/// Ce que font les gestes de la feuille : en cours, et le dernier retour.
@immutable
class GestePush {
  /// Cree l'etat.
  const GestePush({this.enCours = false, this.retour, this.essai = 0});

  /// Un geste attend la reponse.
  final bool enCours;

  /// Le dernier retour, a dire a la personne.
  final String? retour;

  /// Change a chaque retour, pour le redire meme identique.
  final int essai;
}

/// Les trois gestes : activer (apres le toucher), retirer, regler.
class GestesPush extends Notifier<GestePush> {
  @override
  GestePush build() => const GestePush();

  void _fin(String? message) {
    state = GestePush(retour: message, essai: state.essai + 1);
    ref.invalidate(reglagesPushProvider);
  }

  /// « Recevoir les notifications sur cet appareil ». L'appel au navigateur
  /// part avant toute attente : la demande d'autorisation suit le toucher.
  Future<void> activer(String cle) async {
    final PortPush? port = ref.read(portPushProvider);
    if (port == null || state.enCours) return;
    final Future<void> geste = activerPush(
      ref.read(navigateurPushProvider),
      port,
      cle,
    );
    state = GestePush(enCours: true, essai: state.essai);
    String message;
    try {
      await geste;
      message = t.push1.reglages.active;
    } on ActivationRefusee catch (e) {
      message = switch (e.raison) {
        RefusActivation.refuse => t.push1.reglages.refuse,
        RefusActivation.ignore => t.push1.reglages.ignore,
        RefusActivation.nonPrisEnCharge => t.push1.reglages.nonPrisEnCharge,
        RefusActivation.echec => t.push1.reglages.echecActivation,
      };
    } on Object {
      message = t.push1.reglages.echecActivation;
    }
    _fin(message);
  }

  /// « Ne plus les recevoir sur cet appareil ».
  Future<void> desactiver() async {
    final PortPush? port = ref.read(portPushProvider);
    if (port == null || state.enCours) return;
    state = GestePush(enCours: true, essai: state.essai);
    String message;
    try {
      await desactiverPush(ref.read(navigateurPushProvider), port);
      message = t.push1.reglages.desactive;
    } on Object {
      message = t.push1.reglages.changementNonConfirme;
    }
    _fin(message);
  }

  /// Coupe ou garde une categorie.
  Future<void> regler(CategoriePush c, {required bool actif}) async {
    final PortPush? port = ref.read(portPushProvider);
    if (port == null || state.enCours) return;
    state = GestePush(enCours: true, essai: state.essai);
    String? message;
    try {
      await port.reglerCategorie(c, actif: actif);
    } on Object {
      message = t.push1.reglages.changementNonConfirme;
    }
    _fin(message);
  }
}

/// Les gestes de la feuille, partages par le corps et le pied.
final NotifierProvider<GestesPush, GestePush> gestesPushProvider =
    NotifierProvider.autoDispose<GestesPush, GestePush>(GestesPush.new);

/// Le corps de la feuille (rendu seul dans les tests et la galerie).
class ReglagesPushVue extends ConsumerWidget {
  /// Cree le corps.
  const ReglagesPushVue({super.key});

  /// La cle du bouton d'activation, pour les tests.
  static const ValueKey<String> cleActiver = ValueKey<String>('push-activer');

  /// La cle du bouton de retrait, pour les tests.
  static const ValueKey<String> cleDesactiver = ValueKey<String>(
    'push-desactiver',
  );

  /// La cle d'une bascule de categorie, pour les tests.
  static ValueKey<String> cleCategorie(CategoriePush c) =>
      ValueKey<String>('push-categorie-${c.name}');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    if (horsLigne) {
      return EtatSysteme(
        nature: NatureEtat.horsLigne,
        phrase: t.push1.reglages.horsLigne,
      );
    }
    final AsyncValue<EtatReglagesPush> valeur = ref.watch(reglagesPushProvider);
    if (valeur.hasError && valeur.error is CapaciteIndisponible) {
      return EtatSysteme(
        nature: NatureEtat.indisponible,
        titre: t.push1.reglages.compteNonAutoriseTitre,
        phrase: t.push1.reglages.compteNonAutorise,
      );
    }
    return BlocAsynchrone<EtatReglagesPush>(
      valeur: valeur,
      squelette: const Skeleton.liste(),
      titreEchec: t.push1.reglages.erreurTitre,
      onReessayer: () => ref.invalidate(reglagesPushProvider),
      erreurVersEtat: (Object _, VoidCallback? reessayer) => EtatSysteme(
        nature: NatureEtat.echecServeur,
        titre: t.push1.reglages.erreurTitre,
        phrase: t.push1.reglages.erreur,
        onAction: reessayer,
      ),
      estVide: (EtatReglagesPush e) => !e.serveur.autorise,
      vide: EtatSysteme(
        nature: NatureEtat.accesRefuse,
        titre: t.push1.reglages.compteNonAutoriseTitre,
        phrase: t.push1.reglages.compteNonAutorise,
      ),
      construire: (EtatReglagesPush e) => _contenu(context, ref, e),
    );
  }

  Widget _contenu(BuildContext context, WidgetRef ref, EtatReglagesPush e) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final reglages = t.push1.reglages;
    final GestePush geste = ref.watch(gestesPushProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(reglages.contexte, style: textes.bodyMedium),
        Ecart.vMd,
        // L'etat de cet appareil d'abord : c'est ce que la personne vient
        // regler ; le bouton est au pied de la feuille.
        Text(phraseAppareil(e), style: textes.titleSmall),
        LocalFeedback(key: ValueKey<int>(geste.essai), message: geste.retour),
        Ecart.vLg,
        GroupeReglages(
          titre: reglages.categoriesTitre,
          lignes: <LigneRubrique>[
            for (final CategoriePush c in CategoriePush.values)
              if (e.serveur.categories.containsKey(c))
                LigneRubrique(
                  libelle: _libelle(c),
                  legende: _legende(c),
                  controle: Switch.adaptive(
                    key: cleCategorie(c),
                    value: e.serveur.categories[c] ?? true,
                    onChanged: geste.enCours
                        ? null
                        : (bool v) => unawaited(
                            ref
                                .read(gestesPushProvider.notifier)
                                .regler(c, actif: v),
                          ),
                  ),
                ),
          ],
        ),
        Ecart.vSm,
        Text(
          reglages.categoriesContexte,
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
      ],
    );
  }

  String _libelle(CategoriePush c) => switch (c) {
    CategoriePush.classes => t.push1.reglages.classes,
    CategoriePush.remplacements => t.push1.reglages.remplacements,
    CategoriePush.paiements => t.push1.reglages.paiements,
    CategoriePush.admissions => t.push1.reglages.admissions,
    CategoriePush.suivi => t.push1.reglages.suivi,
  };

  String _legende(CategoriePush c) => switch (c) {
    CategoriePush.classes => t.push1.reglages.classesDetail,
    CategoriePush.remplacements => t.push1.reglages.remplacementsDetail,
    CategoriePush.paiements => t.push1.reglages.paiementsDetail,
    CategoriePush.admissions => t.push1.reglages.admissionsDetail,
    CategoriePush.suivi => t.push1.reglages.suiviDetail,
  };
}

/// La phrase de l'etat de cet appareil : ce qu'il recoit, ou pourquoi il ne
/// peut pas encore recevoir et quoi faire (K-59).
String phraseAppareil(EtatReglagesPush e) {
  final reglages = t.push1.reglages;
  if (e.actif) return reglages.appareilActif;
  return switch (e.appareil) {
    EtatAppareilPush.nonPrisEnCharge => reglages.nonPrisEnCharge,
    EtatAppareilPush.iosEcranAccueil => reglages.iosEcranAccueil,
    EtatAppareilPush.refuse => reglages.refuse,
    EtatAppareilPush.inactif || EtatAppareilPush.actif =>
      e.clePublique != null
          ? reglages.appareilInactif
          : reglages.echecActivation,
  };
}

/// Le pied de la feuille : le seul bouton de l'appareil, ou rien quand il ne
/// peut pas aboutir (la phrase du corps dit pourquoi).
class ActionReglagesPush extends ConsumerWidget {
  /// Cree le pied.
  const ActionReglagesPush({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final EtatReglagesPush? e = ref.watch(reglagesPushProvider).value;
    final GestePush geste = ref.watch(gestesPushProvider);
    if (horsLigne || e == null || !e.serveur.autorise) {
      return const SizedBox.shrink();
    }
    final String? cle = e.clePublique;
    if (e.actif) {
      return ActionPrincipale(
        key: ReglagesPushVue.cleDesactiver,
        libelle: t.push1.reglages.desactiver,
        niveau: NiveauAction.secondaire,
        enCours: geste.enCours,
        onPress: () =>
            unawaited(ref.read(gestesPushProvider.notifier).desactiver()),
      );
    }
    if (cle == null) return const SizedBox.shrink();
    return ActionPrincipale(
      key: ReglagesPushVue.cleActiver,
      libelle: t.push1.reglages.activer,
      enCours: geste.enCours,
      onPress: () =>
          unawaited(ref.read(gestesPushProvider.notifier).activer(cle)),
    );
  }
}
