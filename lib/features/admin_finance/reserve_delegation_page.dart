// Delta Direction (spec §37, §9.2 a §9.6, §21) : l'onglet « Reserve et
// delegation » du domaine Finance de la direction, troisieme onglet de
// `FinancePage` (`OngletFinance.reserveDelegation`). Pose « en preparation »
// par CPT-F avec son constructeur definitif ; **propriete de la voie CPT-DIR
// ensuite**, qui ecrit dans `lib/features/admin_finance/reserve_delegation/**`
// (`StrategicReservePolicyPanel`, `FinanceDelegationPolicyPanel`) et ici
// (`20_comptable/02_DECOUPAGE.md`). `finance_page.dart`,
// `politiques_commerciales.dart` et `vue_globale_finance.dart` restent geles.
//
// Rendu DANS le `PageShell` de `FinancePage` (comme `VueGlobaleFinanceBloc`),
// jamais une seconde page : pas de second systeme Finance Direction. Les deux
// panneaux se suivent : la politique de la Reserve strategique (CPT-BR-12),
// puis la delegation financiere (CPT-BR-13). Chacun lit son port et porte ses
// cinq etats. L'ecran de validation des operations sensibles attend la
// reponse du directeur a CPT-Q1 : il n'est pas construit ici.

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bascule_montants.dart';
import '../../core/widgets/section_header.dart';
import 'reserve_delegation/finance_delegation_policy_panel.dart';
import 'reserve_delegation/strategic_reserve_policy_panel.dart';

/// Le corps de l'onglet « Reserve et delegation ».
class ReserveDelegationPage extends StatelessWidget {
  /// Cree le corps.
  const ReserveDelegationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final c = t.comptable.direction;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          c.sousTitre,
          style: palette.inkMuted.applyTo(
            textes.bodyLarge ?? const TextStyle(),
          ),
        ),
        Ecart.vMd,
        const Align(
          alignment: AlignmentDirectional.centerEnd,
          child: BasculeMontants(avecEtat: true),
        ),
        Ecart.vXxl,
        SectionHeader(titre: c.reserve),
        const StrategicReservePolicyPanelBloc(),
        Ecart.vSection,
        SectionHeader(titre: c.delegation),
        const FinanceDelegationPolicyPanelBloc(),
      ],
    );
  }
}
