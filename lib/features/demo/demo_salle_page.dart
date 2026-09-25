// La salle de seance en demonstration : /demo/salle (hors production).
//
// Sans parametre : la liste des liens role x etat (3 x 6). Avec `role` et
// `etat` : la salle en plein ecran, donnees fictives (seance_demo.dart) et
// etat local (micro, camera, zoom, agrandi, panneaux). Aucun appel serveur
// (consigne K-28). La guidee lit le theme `InterfaceMode.enfant`.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pressable.dart';
import '../salle_seance/actions_seance.dart';
import '../salle_seance/resultat_seance.dart';
import '../salle_seance/salle_seance.dart';
import '../salle_seance/vue_seance.dart';
import 'mode_demonstration.dart';
import 'seance_demo.dart';

/// Les routes de la demonstration : AUCUNE quand l'environnement ne
/// l'autorise pas (production).
List<RouteBase> routesDemoSalle(String environnement) {
  if (!environnementAutoriseDemo(environnement)) return const <RouteBase>[];
  return <RouteBase>[
    GoRoute(
      path: Routes.demoSalle,
      builder: (BuildContext _, GoRouterState etat) => DemoSallePage(
        role: _lire(RoleSeance.values, etat.uri.queryParameters['role']),
        etat: _lire(EtatDemoSalle.values, etat.uri.queryParameters['etat']),
      ),
    ),
  ];
}

T? _lire<T extends Enum>(List<T> valeurs, String? nom) {
  for (final T v in valeurs) {
    if (v.name == nom) return v;
  }
  return null;
}

/// L'adresse d'un etat de la demonstration.
String adresseDemoSalle(RoleSeance role, EtatDemoSalle etat) => Uri(
  path: Routes.demoSalle,
  queryParameters: <String, String>{'role': role.name, 'etat': etat.name},
).toString();

/// La page : la liste, ou la salle si [role] et [etat] sont donnes.
class DemoSallePage extends StatelessWidget {
  const DemoSallePage({this.role, this.etat, super.key});

  final RoleSeance? role;
  final EtatDemoSalle? etat;

  @override
  Widget build(BuildContext context) {
    final RoleSeance? r = role;
    final EtatDemoSalle? e = etat;
    if (r == null || e == null) return const _ListeDemo();
    final Widget salle = SalleDemo(
      key: ValueKey<String>('${r.name}-${e.name}'),
      role: r,
      etat: e,
      onSortir: () => context.go(Routes.demoSalle),
    );
    if (r != RoleSeance.guidee) return salle;
    return Theme(
      data: AppTheme.pour(InterfaceMode.enfant, Theme.of(context).brightness),
      child: salle,
    );
  }
}

String _libelleRole(RoleSeance role) => switch (role) {
  RoleSeance.eleve => t.salle.seance.demo.roles.eleve,
  RoleSeance.guidee => t.salle.seance.demo.roles.guidee,
  RoleSeance.enseignant => t.salle.seance.demo.roles.enseignant,
};

String _libelleEtat(EtatDemoSalle etat) => switch (etat) {
  EtatDemoSalle.repos => t.salle.seance.demo.etats.repos,
  EtatDemoSalle.visite => t.salle.seance.demo.etats.visite,
  EtatDemoSalle.rienPartage => t.salle.seance.demo.etats.rienPartage,
  EtatDemoSalle.eleves => t.salle.seance.demo.etats.eleves,
  EtatDemoSalle.supports => t.salle.seance.demo.etats.supports,
  EtatDemoSalle.fin => t.salle.seance.demo.etats.fin,
};

class _ListeDemo extends StatelessWidget {
  const _ListeDemo();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ThemeData theme = Theme.of(context);
    return PageShell(
      titre: t.salle.seance.demo.titre,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            t.salle.seance.demo.intro,
            style: palette.inkMuted.applyTo(
              theme.textTheme.bodyMedium ?? const TextStyle(),
            ),
          ),
          for (final RoleSeance role in RoleSeance.values) ...<Widget>[
            Ecart.vXxl,
            Text(
              _libelleRole(role),
              style: palette.inkStrong.applyTo(
                theme.textTheme.titleMedium ?? const TextStyle(),
              ),
            ),
            Ecart.vMd,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                for (final EtatDemoSalle etat in EtatDemoSalle.values)
                  _Lien(
                    libelle: _libelleEtat(etat),
                    onPress: () => context.go(adresseDemoSalle(role, etat)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Lien extends StatelessWidget {
  const _Lien({required this.libelle, required this.onPress});

  final String libelle;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Pressable(
      onPress: onPress,
      libelleSemantique: libelle,
      arrondiFocus: AppRadius.arrondiFull,
      child: DecoratedBox(
        decoration: palette.surfaceRaised.decoration(
          borderRadius: AppRadius.arrondiFull,
          side: palette.borderHairline.asBorderSide(),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                libelle,
                style: palette.inkStrong.applyTo(
                  Theme.of(context).textTheme.labelLarge ?? const TextStyle(),
                ),
              ),
              Ecart.hSm,
              IconTheme(
                data: palette.inkMuted.asIconTheme(size: AppSpacing.lg),
                child: Icon(AppIcons.chevron.repos),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La salle de demonstration, avec son etat local.
class SalleDemo extends StatefulWidget {
  const SalleDemo({
    required this.role,
    required this.etat,
    required this.onSortir,
    super.key,
  });

  final RoleSeance role;
  final EtatDemoSalle etat;
  final VoidCallback onSortir;

  @override
  State<SalleDemo> createState() => _SalleDemoState();
}

class _SalleDemoState extends State<SalleDemo> {
  static const double _pasZoom = 0.1;
  static const double _zoomMin = 0.5;
  static const double _zoomMax = 2;

  bool _micro = true;
  bool _camera = true;

  /// L'eleve a quitte la salle avant la fin (apres confirmation).
  bool _quittee = false;
  bool _agrandi = false;
  double _zoom = 1;
  late PanneauOuvert _panneau = DonneesSeanceDemo.vue(
    widget.role,
    widget.etat,
  ).panneau;

  // Les commandes sans effet en demonstration (cloche, reglages, compte,
  // outils) : rendues pour montrer l'ecran des images, elles ne font rien.
  void _inerte() {}

  void _zoomer(double pas) => setState(() {
    _zoom = ((_zoom + pas).clamp(_zoomMin, _zoomMax) * 10).round() / 10;
  });

  void _basculerPanneau(PanneauOuvert panneau) => setState(() {
    _panneau = _panneau == panneau ? PanneauOuvert.aucun : panneau;
  });

  @override
  Widget build(BuildContext context) {
    final VueSeance vue = DonneesSeanceDemo.vue(
      widget.role,
      widget.etat,
    ).copyWith(panneau: _panneau);
    final bool enseignant = widget.role == RoleSeance.enseignant;
    // Fin de seance ou sortie volontaire de l'eleve : CLV-09. La fin de
    // l'enseignant (CLV-10) vient avec T7.
    if (!enseignant && (vue.estFinie || _quittee)) {
      return ResultatSeance(
        issue: _quittee ? IssueSeance.quittee : IssueSeance.terminee,
        onRetour: widget.onSortir,
      );
    }
    return SalleSeance(
      vue: vue,
      local: EtatLocalSeance(
        microOuvert: _micro,
        cameraAllumee: _camera,
        zoom: _zoom,
        agrandi: _agrandi,
      ),
      actions: ActionsSeance(
        onRetour: widget.onSortir,
        onQuitter: enseignant
            ? widget.onSortir
            : () => setState(() => _quittee = true),
        onMicro: () => setState(() => _micro = !_micro),
        onCamera: () => setState(() => _camera = !_camera),
        onAgrandir: () => setState(() => _agrandi = !_agrandi),
        onZoomMoins: () => _zoomer(-_pasZoom),
        onZoomPlus: () => _zoomer(_pasZoom),
        onNotifications: _inerte,
        onReglages: _inerte,
        onCompte: _inerte,
        onReseau: enseignant ? _inerte : null,
        onEleves: enseignant
            ? () => _basculerPanneau(PanneauOuvert.eleves)
            : null,
        onSupports: enseignant
            ? () => _basculerPanneau(PanneauOuvert.supports)
            : null,
        onOutil: enseignant ? (OutilEnseignement _) => _inerte() : null,
        onPagePrecedente: enseignant ? _inerte : null,
        onPageSuivante: enseignant ? _inerte : null,
      ),
    );
  }
}
