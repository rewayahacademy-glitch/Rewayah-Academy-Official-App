// Les factures du mois, emises par la direction depuis l'onglet « Paiements »
// (FAC-B-01, `emettre_factures_mois` ; passation du 17/10/2026, point 2).
//
// Deux lignes : le mois courant et le suivant, les seuls que la source
// accepte. Chacune ouvre une fiche qui dit ce que fait l'emission (une
// facture par eleve au tarif publie, les credits deja recus reglent les mois
// qu'ils couvrent) avant le bouton. L'issue est celle que rend la source :
// nombre de factures emises et de mois regles, refus nomme (droits, mois,
// aucun prix publie), ou issue inconnue (D5). Une facture deja emise ne
// l'est jamais deux fois : « Reessayer » est sans risque.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/capacites/port_paiements_saisis.dart';
import '../../../core/i18n/elision.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/bandeau_attention.dart';
import '../../../core/widgets/carte_lignes.dart';
import '../../../core/widgets/selecteur_mois.dart';
import '../../../core/widgets/setting_row.dart';
import '../../../core/widgets/status_pill.dart';

/// Le premier jour du mois de [d] et celui du mois suivant.
(DateTime, DateTime) moisFacturables(DateTime d) =>
    (DateTime(d.year, d.month), DateTime(d.year, d.month + 1));

/// Les deux lignes « Factures de octobre 2026 », « Factures de novembre 2026 ».
class BlocFacturesMois extends StatelessWidget {
  /// Cree le bloc ; [aujourdhui] pour les tests.
  const BlocFacturesMois({super.key, this.aujourdhui, this.onEmises});

  /// La date du jour ; par defaut l'horloge de l'appareil. La source decide
  /// des mois acceptes et refuse les autres.
  final DateTime? aujourdhui;

  /// Appele quand des factures ont ete emises (la liste est a relire).
  final VoidCallback? onEmises;

  /// La cle de la ligne d'un mois.
  static Key cleMois(DateTime mois) =>
      ValueKey<String>('factures-${mois.year}-${mois.month}');

  @override
  Widget build(BuildContext context) {
    final f = t.admin.finance.fac;
    final (DateTime courant, DateTime suivant) = moisFacturables(
      aujourdhui ?? DateTime.now(),
    );
    return CarteLignes(
      lignes: <Widget>[
        for (final DateTime mois in <DateTime>[courant, suivant])
          SettingRow(
            key: cleMois(mois),
            title: f.ligne(deMois: deDevant(SelecteurMois.enMots(mois))),
            description: mois == courant ? f.moisCourant : f.moisSuivant,
            value: f.emettre,
            onPress: () async {
              final bool emises = await ouvrirFacturesMois(context, mois);
              if (emises) onEmises?.call();
            },
          ),
      ],
    );
  }
}

/// Ouvre la fiche d'emission de [mois] ; rend vrai si des factures sont
/// parties (ou si l'issue est inconnue).
Future<bool> ouvrirFacturesMois(BuildContext context, DateTime mois) async {
  final ProviderContainer portee = ProviderScope.containerOf(
    context,
    listen: false,
  );
  final bool? change = await AppBottomSheet.ouvrir<bool>(
    context,
    titre: t.admin.finance.fac.ligne(
      deMois: deDevant(SelecteurMois.enMots(mois)),
    ),
    constructeur: (BuildContext _) => UncontrolledProviderScope(
      container: portee,
      child: FeuilleFacturesMois(mois: mois),
    ),
  );
  return change ?? false;
}

enum _Phase { attente, envoi, faite, refusee, inconnue }

/// Le contenu de la fiche d'emission.
class FeuilleFacturesMois extends ConsumerStatefulWidget {
  /// Cree la fiche.
  const FeuilleFacturesMois({required this.mois, super.key});

  /// Le premier jour du mois a facturer.
  final DateTime mois;

  /// La cle du bouton d'emission.
  static const Key cleEmettre = ValueKey<String>('factures-emettre');

  /// La cle de la ligne des factures emises.
  static const Key cleEmises = ValueKey<String>('factures-emises');

  /// La cle de la ligne des mois regles.
  static const Key cleFinancees = ValueKey<String>('factures-financees');

  @override
  ConsumerState<FeuilleFacturesMois> createState() =>
      _FeuilleFacturesMoisEtat();
}

class _FeuilleFacturesMoisEtat extends ConsumerState<FeuilleFacturesMois> {
  _Phase _phase = _Phase.attente;
  FacturesEmises? _resultat;
  MotifRefusPaiement? _refus;
  bool _change = false;

  Future<void> _emettre() async {
    if (_phase == _Phase.envoi) return;
    setState(() => _phase = _Phase.envoi);
    try {
      final FacturesEmises r = await ref
          .read(portPaiementsSaisisProvider)
          .emettreFactures(widget.mois);
      if (!mounted) return;
      setState(() {
        _resultat = r;
        _change = true;
        _phase = _Phase.faite;
      });
    } on RefusPaiement catch (refus) {
      if (!mounted) return;
      setState(() {
        _refus = refus.motif;
        _phase = _Phase.refusee;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _change = true;
        _phase = _Phase.inconnue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = t.admin.finance.fac;
    final TextTheme textes = Theme.of(context).textTheme;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final String mois = SelecteurMois.enMots(widget.mois);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          f.explication,
          style: AppPalette.of(context).inkMuted
              .applyTo(textes.bodyMedium ?? const TextStyle()),
        ),
        Ecart.vLg,
        ..._issue(),
        Ecart.vXl,
        _actions(context, mois: mois, horsLigne: horsLigne),
      ],
    );
  }

  List<Widget> _issue() {
    final f = t.admin.finance.fac;
    switch (_phase) {
      case _Phase.faite:
        final FacturesEmises r = _resultat!;
        return <Widget>[
          BandeauAttention(
            titre: f.faitTitre,
            message: r.emises == 0 ? f.dejaEmises : f.faitPhrase,
            ton: TonEtat.succes,
          ),
          Ecart.vMd,
          CarteLignes(
            lignes: <Widget>[
              SettingRow(
                key: FeuilleFacturesMois.cleEmises,
                title: f.emises,
                value: '${r.emises}',
              ),
              SettingRow(
                key: FeuilleFacturesMois.cleFinancees,
                title: f.financees,
                value: '${r.financees}',
              ),
            ],
          ),
        ];
      case _Phase.refusee:
        return <Widget>[
          BandeauAttention(
            titre: f.refusTitre,
            message: switch (_refus) {
              MotifRefusPaiement.droits => f.refusDroits,
              MotifRefusPaiement.sansPolitique => f.refusSansPrix,
              _ => f.refusMois,
            },
            ton: TonEtat.alerte,
          ),
        ];
      case _Phase.inconnue:
        return <Widget>[
          BandeauAttention(
            titre: f.inconnuTitre,
            message: f.inconnuPhrase,
            ton: TonEtat.alerte,
          ),
        ];
      case _Phase.attente:
      case _Phase.envoi:
        return const <Widget>[];
    }
  }

  Widget _actions(
    BuildContext context, {
    required String mois,
    required bool horsLigne,
  }) {
    final f = t.admin.finance.fac;
    final bool envoi = _phase == _Phase.envoi;
    final bool peutEnvoyer =
        _phase == _Phase.attente || envoi || _phase == _Phase.inconnue;
    final ActionPrincipale fermer = ActionPrincipale(
      libelle: t.admin.finance.pai.fermer,
      niveau: NiveauAction.tertiaire,
      onPress: envoi ? null : () => Navigator.of(context).pop(_change),
    );
    final List<Widget> boutons = <Widget>[fermer];
    Widget? phrase;
    if (peutEnvoyer && horsLigne) {
      // Hors ligne : rien ne part ; une phrase, pas de bouton grise.
      phrase = Text(
        t.admin.finance.pai.horsLigne,
        style: AppPalette.of(context).inkMuted.applyTo(
          Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
        ),
      );
    } else if (peutEnvoyer) {
      boutons.add(
        ActionPrincipale(
          key: FeuilleFacturesMois.cleEmettre,
          libelle: _phase == _Phase.inconnue
              ? t.admin.finance.pai.reessayer
              : f.emettreMois(deMois: deDevant(mois)),
          enCours: envoi,
          onPress: _emettre,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (phrase != null) ...<Widget>[phrase, Ecart.vMd],
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.end,
          children: boutons,
        ),
      ],
    );
  }
}
