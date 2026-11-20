import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../agent/recharger_adresse.dart';
import '../fraicheur/avis_flottant.dart';
import '../i18n/strings.g.dart';
import '../widgets/action_principale.dart';
import 'nouvelle_version.dart';

/// L'avis « nouvelle version » (lot demarrage, 25/10/2026 ; PE-D9, directeur,
/// 19/11/2026 : la mise a jour se propose, elle ne s'impose plus).
///
/// Un `AvisFlottant` pose par-dessus l'ecran (`CoucheAvis`), jamais un
/// bandeau qui pousse la page : « Mettre a jour » recharge tout de suite,
/// « Plus tard » (ou la croix, ou le glissement vers le haut) le range. Rangé,
/// il ne revient pas ; la mise a jour se fait seule au prochain demarrage, ou
/// au retour au premier plan apres une vraie absence
/// ([absenceAvantMiseAJour]), jamais pendant une seance. Rien tant que la
/// version servie est celle du demarrage.
class BandeauNouvelleVersion extends ConsumerStatefulWidget {
  /// Cree l'avis. [recharger] et [maintenant] se fixent dans les tests ;
  /// [enSeance] dit si la personne est dans la salle (aucune mise a jour
  /// automatique alors).
  const BandeauNouvelleVersion({
    super.key,
    this.recharger = rechargerAdresse,
    this.enSeance = _jamais,
    this.maintenant = DateTime.now,
  });

  /// Le rechargement de la page.
  final VoidCallback recharger;

  /// Vrai quand recharger couperait une seance.
  final bool Function() enSeance;

  /// L'horloge, pour mesurer l'absence.
  final DateTime Function() maintenant;

  static bool _jamais() => false;

  /// La cle de « Mettre a jour ».
  static const Key cleMettre = ValueKey<String>('mise-a-jour-mettre');

  /// La cle de « Plus tard ».
  static const Key clePlusTard = ValueKey<String>('mise-a-jour-plus-tard');

  @override
  ConsumerState<BandeauNouvelleVersion> createState() =>
      _EtatBandeauNouvelleVersion();
}

class _EtatBandeauNouvelleVersion
    extends ConsumerState<BandeauNouvelleVersion> {
  late final AppLifecycleListener _cycle;

  /// L'instant ou l'application a quitte l'ecran, `null` si elle y est.
  DateTime? _cacheeDepuis;

  @override
  void initState() {
    super.initState();
    _cycle = AppLifecycleListener(onHide: _cache, onShow: _revient);
  }

  @override
  void dispose() {
    _cycle.dispose();
    super.dispose();
  }

  void _cache() => _cacheeDepuis ??= widget.maintenant();

  void _revient() {
    final DateTime? depuis = _cacheeDepuis;
    _cacheeDepuis = null;
    if (depuis == null || !mounted) return;
    if (miseAJourAuRetour(
      nouvelle: ref.read(nouvelleVersionProvider),
      remise: ref.read(miseAJourRemiseProvider),
      absence: widget.maintenant().difference(depuis),
      enSeance: widget.enSeance(),
    )) {
      widget.recharger();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool montrer =
        ref.watch(nouvelleVersionProvider) &&
        !ref.watch(miseAJourRemiseProvider);
    final VoidCallback remettre = ref
        .read(miseAJourRemiseProvider.notifier)
        .remettre;
    return PassageAvis(
      child: !montrer
          ? null
          : AvisFlottant(
              key: const ValueKey<String>('avis-nouvelle-version'),
              message: t.miseAJour.prete,
              onFermer: remettre,
              actions: <Widget>[
                ActionPrincipale(
                  key: BandeauNouvelleVersion.cleMettre,
                  libelle: t.racine.miseAJour.mettre,
                  onPress: widget.recharger,
                  niveau: NiveauAction.secondaire,
                  pleineLargeur: false,
                ),
                ActionPrincipale(
                  key: BandeauNouvelleVersion.clePlusTard,
                  libelle: t.racine.miseAJour.plusTard,
                  onPress: remettre,
                  niveau: NiveauAction.tertiaire,
                  pleineLargeur: false,
                ),
              ],
            ),
    );
  }
}
