import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/agent/lots_praxis.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/texte_protege.dart';
import '../mfa_controleur/double_verification.dart';

/// Les cles des widgets du bloc, pour les tests.
abstract final class ClesLotsPraxis {
  /// « Afficher les lots a confirmer ».
  static const Key afficher = ValueKey<String>('praxis-lots-afficher');

  /// « Recharger la liste ».
  static const Key recharger = ValueKey<String>('praxis-lots-recharger');

  /// Le code d'un lot (suffixe : l'identifiant du lot).
  static Key code(String id) => ValueKey<String>('praxis-lot-code-$id');

  /// « Annuler ce lot » (suffixe : l'identifiant du lot).
  static Key annuler(String id) => ValueKey<String>('praxis-lot-annuler-$id');
}

/// `PX-BD-0` : « Lots a confirmer », dans la section « Praxis » de « Acces des
/// agents IA ».
///
/// Quand Praxis PREPARE une action sensible dans la conversation de la
/// direction, le serveur genere un code a six chiffres que SEULE la direction
/// lit, ici, en double verification. Elle le dit a Praxis : c'est sa preuve.
///
///   * **les codes ne se montrent qu'a la demande** : rien n'est lu a
///     l'ouverture de l'ecran ; « Afficher » passe par la double verification ;
///   * **le code et son resume sont sur le meme lot** : la direction voit ce
///     qu'elle confirme avant de dire le code ;
///   * **annuler est sensible** : il attend le serveur ; un lot annule ne
///     s'execute jamais, meme avec le bon code ;
///   * **aucun bouton plein** : une seule lecture, des liens ; le resume vient
///     du serveur et se lit comme une donnee (`TexteProtege`).
class LotsPraxisSection extends ConsumerStatefulWidget {
  /// Cree le bloc.
  const LotsPraxisSection({super.key});

  @override
  ConsumerState<LotsPraxisSection> createState() => _LotsPraxisEtat();
}

enum _Phase { ferme, chargement, contenu, erreur }

class _LotsPraxisEtat extends ConsumerState<LotsPraxisSection> {
  _Phase _phase = _Phase.ferme;
  List<LotPraxis> _lots = <LotPraxis>[];
  Object? _erreur;
  bool _refusDroit = false;
  String? _annulation;
  String? _message;

  ServiceLotsPraxis get _service => ref.read(serviceLotsPraxisProvider);

  Future<void> _charger() async {
    if (_phase == _Phase.chargement) {
      return;
    }
    setState(() {
      _phase = _Phase.chargement;
      _erreur = null;
      _refusDroit = false;
      _message = null;
    });
    try {
      final List<LotPraxis> lots =
          await avecDoubleVerification<List<LotPraxis>>(
            context,
            ref,
            _service.enAttente,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _lots = lots;
        _phase = _Phase.contenu;
      });
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _erreur = e;
        _refusDroit = estRefusDeDroit(e);
        _phase = _lots.isEmpty ? _Phase.erreur : _Phase.contenu;
      });
    }
  }

  Future<void> _annuler(LotPraxis lot) async {
    if (_annulation != null) {
      return;
    }
    setState(() {
      _annulation = lot.id;
      _message = null;
    });
    String? message;
    try {
      final bool fait = await avecDoubleVerification<bool>(
        context,
        ref,
        () => _service.annuler(lot.id),
      );
      message = fait ? t.admin.praxis.lots.annule : t.admin.praxis.lots.rien;
    } on Object catch (e) {
      message = estRefusDeDroit(e)
          ? t.admin.praxis.lots.doubleVerification
          : t.admin.praxis.lots.erreurAnnuler;
    }
    if (!mounted) {
      return;
    }
    setState(() => _annulation = null);
    // Dans tous les cas la liste est relue : l'ecran ne dit jamais autre chose
    // que la base (D5, « non confirme »).
    await _charger();
    if (!mounted) {
      return;
    }
    setState(() => _message = message);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(monHorlogeProvider);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(
          titre: t.admin.praxis.lots.titre,
          compteur: _phase == _Phase.contenu ? _lots.length : null,
        ),
        Ecart.vSm,
        Text(t.admin.praxis.lots.intro, style: textes.bodyMedium),
        Ecart.vLg,
        LocalFeedback(message: _message),
        _corps(context),
      ],
    );
  }

  Widget _corps(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    switch (_phase) {
      case _Phase.ferme:
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(t.admin.praxis.lots.ferme, style: textes.bodyMedium),
              Ecart.vLg,
              LienFleche(
                key: ClesLotsPraxis.afficher,
                libelle: t.admin.praxis.lots.afficher,
                alignerEnDebut: true,
                onPress: () => unawaited(_charger()),
              ),
            ],
          ),
        );
      case _Phase.chargement:
        return const Skeleton.liste();
      case _Phase.erreur:
        if (_refusDroit) {
          return EmptyState(
            message: t.admin.praxis.lots.doubleVerification,
            icone: AppIcons.avertissement,
            libelleAction: t.commun.reessayer,
            onAction: () => unawaited(_charger()),
          );
        }
        if (ref.watch(horsLigneProvider).value ?? false) {
          return EtatSansDonnees(
            quoi: t.admin.praxis.lots.horsLigne,
            onAction: () => unawaited(_charger()),
          );
        }
        return EmptyState(
          message: t.admin.praxis.lots.erreur,
          icone: AppIcons.avertissement,
          libelleAction: t.commun.reessayer,
          onAction: () => unawaited(_charger()),
        );
      case _Phase.contenu:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (_erreur != null) ...<Widget>[
              Semantics(
                liveRegion: true,
                child: Text(
                  _refusDroit
                      ? t.admin.praxis.lots.doubleVerification
                      : t.admin.praxis.lots.erreur,
                  style: textes.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
              Ecart.vLg,
            ],
            if (_lots.isEmpty)
              EmptyState(
                message: t.admin.praxis.lots.vide,
                invitation: t.admin.praxis.lots.videDetail,
                icone: AppIcons.rienAAfficher,
                registre: RegistreVide.bonneNouvelle,
              )
            else
              for (int i = 0; i < _lots.length; i++) ...<Widget>[
                if (i > 0) Ecart.vLg,
                _CarteLot(
                  lot: _lots[i],
                  annulationEnCours: _annulation == _lots[i].id,
                  onAnnuler: () => unawaited(_annuler(_lots[i])),
                ),
              ],
            Ecart.vLg,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: LienFleche(
                key: ClesLotsPraxis.recharger,
                libelle: t.admin.praxis.lots.recharger,
                alignerEnDebut: true,
                onPress: () => unawaited(_charger()),
              ),
            ),
          ],
        );
    }
  }
}

/// Un lot : son code (le seul endroit ou il se lit), ce qu'il fait, son
/// expiration, et « Annuler ce lot ».
class _CarteLot extends StatelessWidget {
  const _CarteLot({
    required this.lot,
    required this.annulationEnCours,
    required this.onAnnuler,
  });

  final LotPraxis lot;
  final bool annulationEnCours;
  final VoidCallback onAnnuler;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(t.admin.praxis.lots.code, style: textes.titleSmall),
          Ecart.vXs,
          // Le code se lit de gauche a droite en arabe aussi.
          Semantics(
            label: lot.code.split('').join(' '),
            excludeSemantics: true,
            child: TexteProtege(
              child: Text(
                lot.codeLisible,
                key: ClesLotsPraxis.code(lot.id),
                style: textes.headlineSmall,
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
          Ecart.vSm,
          Text(t.admin.praxis.lots.dire, style: textes.bodySmall),
          Ecart.vLg,
          Text(t.admin.praxis.lots.lignes(n: lot.nb), style: textes.titleSmall),
          Ecart.vXs,
          for (final String ligne in lot.resume)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: TexteProtege(child: Text(ligne, style: textes.bodyMedium)),
            ),
          Ecart.vSm,
          Text(
            t.admin.praxis.lots.valable(heure: heureChezMoi(lot.expireLe)),
            style: textes.bodySmall,
          ),
          Ecart.vLg,
          annulationEnCours
              ? Semantics(
                  liveRegion: true,
                  child: Text(
                    t.admin.praxis.lots.annulation,
                    style: textes.bodySmall,
                  ),
                )
              : LienFleche(
                  key: ClesLotsPraxis.annuler(lot.id),
                  libelle: t.admin.praxis.lots.annuler,
                  alignerEnDebut: true,
                  onPress: onAnnuler,
                ),
        ],
      ),
    );
  }
}
