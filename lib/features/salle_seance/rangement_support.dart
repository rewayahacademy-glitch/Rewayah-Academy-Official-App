// TB-9 (plan V2 §3 « Ranger reellement », §19.2 point 4) : les deux reperes
// de la copie visuelle du rangement, la feuille de la surface (depart) et
// l'entree « Bibliotheque » des Commandes (arrivee).
//
// La salle de l'enseignant pose la portee ; la surface et les Commandes y
// accrochent leurs cles. Ranger lit les deux rectangles AVANT de changer
// l'etat, lance la copie (lib/core/mouvement), puis change l'etat sans
// l'attendre : l'animation ne decide de rien.

import 'package:flutter/material.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/mouvement/envol_vers_cible.dart';
import '../../core/tc_bibliotheque/content_position.dart';
import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_theme.dart';
import '../tc_catalogue/surface_bibliotheque.dart' show RepriseEnSeance;
import 'vue_seance.dart';

/// TB-9 (plan V2 §3, §19.2 point 6) : les points de reprise des supports
/// ranges pendant la seance, pour la Bibliotheque : la page du rangement, et
/// la conservation des notes quand il y en a. Le plus recent en tete.
List<RepriseEnSeance> reprisesDe(VueSeance vue) => <RepriseEnSeance>[
  for (final SupportPageFixe range in vue.supportsRanges.reversed)
    RepriseEnSeance(
      resourceId: range.id,
      position: ContentPosition.page(
        resourceId: range.id,
        resourceVersionId: range.version,
        page: range.page,
      ),
      libelle: <String>[
        t.salle.seance.rangement.reprise(page: range.page, total: range.total),
        if (vue.notesDuSupport(range) > 0)
          t.salle.seance.rangement.notesConservees,
      ].join(' '),
    ),
];

/// La portee du rangement : les cles du depart et de l'arrivee.
class PorteeRangement extends StatefulWidget {
  const PorteeRangement({required this.child, super.key});

  final Widget child;

  /// La portee la plus proche, ou `null` (eleve, guidee : rien a ranger).
  static ReperesRangement? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Portee>()?.reperes;

  @override
  State<PorteeRangement> createState() => _PorteeRangementState();
}

class _PorteeRangementState extends State<PorteeRangement> {
  final ReperesRangement _reperes = ReperesRangement._();

  @override
  Widget build(BuildContext context) =>
      _Portee(reperes: _reperes, child: widget.child);
}

class _Portee extends InheritedWidget {
  const _Portee({required this.reperes, required super.child});

  final ReperesRangement reperes;

  @override
  bool updateShouldNotify(_Portee ancien) => ancien.reperes != reperes;
}

/// Les deux reperes, stables pour la vie de la salle.
class ReperesRangement {
  ReperesRangement._();

  /// La feuille de la surface (page du support ou feuille du tableau).
  final GlobalKey feuille = GlobalKey(debugLabel: 'rangement-feuille');

  /// L'entree « Bibliotheque » des Commandes.
  final GlobalKey bibliotheque = GlobalKey(debugLabel: 'rangement-cible');

  /// Lance la copie de la feuille vers la Bibliotheque ; rend `false` si
  /// rien n'est monte (mouvement reduit, repere absent).
  bool envoler(BuildContext context) => EnvolVersCible.lancer(
    context,
    depart: feuille,
    arrivee: bibliotheque,
    copie: const _CopieFeuille(),
  );
}

/// La copie : le bord de la page (surface claire, filet, ombre de niveau 1),
/// toujours en theme clair comme la surface qu'elle quitte.
class _CopieFeuille extends StatelessWidget {
  const _CopieFeuille();

  @override
  Widget build(BuildContext context) => Theme(
    data: AppTheme.pour(InterfaceMode.standard, Brightness.light),
    child: Builder(
      builder: (BuildContext clair) {
        final AppPalette palette = AppPalette.of(clair);
        return DecoratedBox(
          decoration: palette.surfaceRaised
              .decoration(
                borderRadius: AppRadius.arrondiSm,
                side: palette.borderHairline.asBorderSide(),
              )
              .copyWith(boxShadow: AppElevation.niveau1(palette.ombre)),
        );
      },
    ),
  );
}
