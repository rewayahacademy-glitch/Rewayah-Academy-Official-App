// CALENDRIER-ET-PAUSES (lot 2, 12/11/2026) : Pedagogie > Calendrier.
//
// UNE entree du domaine Pedagogie (le domaine tient a sept fonctions au plus,
// ONGLETS-1), deux sections : les dates de l'ecole (fermetures, rencontres de
// recitation, dates d'evaluation, autres dates : saisies et publiees par la
// direction, jamais calculees) et les pauses (les demandes que la direction
// doit decider, les decisions recentes, la pause d'exception). Le serveur
// decide de tout ; la page dit ce qu'il a lu.

import 'package:flutter/material.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/controle_segmente.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/selecteur_section.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import 'section_dates.dart';
import 'section_pauses.dart';

enum _Section { dates, pauses }

/// Pedagogie > Calendrier.
class CalendrierPage extends StatefulWidget {
  /// Cree la page.
  const CalendrierPage({super.key});

  @override
  State<CalendrierPage> createState() => _CalendrierPageEtat();
}

class _CalendrierPageEtat extends State<CalendrierPage> {
  _Section _section = _Section.dates;

  @override
  Widget build(BuildContext context) {
    return PageShell(
      titre: t.calendrier.titre,
      entete: SousNavigationDomaine(onglets: ongletsPedagogie(), indexActif: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SelecteurSection<_Section>(
            libelle: t.calendrier.sections.libelle,
            sections: <Segment<_Section>>[
              Segment<_Section>(
                valeur: _Section.dates,
                libelle: t.calendrier.sections.dates,
              ),
              Segment<_Section>(
                valeur: _Section.pauses,
                libelle: t.calendrier.sections.pauses,
              ),
            ],
            valeur: _section,
            onChange: (_Section s) => setState(() => _section = s),
          ),
          Ecart.vLg,
          if (_section == _Section.dates)
            const SectionDates()
          else
            const SectionPauses(),
        ],
      ),
    );
  }
}
