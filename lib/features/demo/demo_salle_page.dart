// La salle de seance en demonstration : /demo/salle (hors production).
//
// Sans parametre : la liste des liens par role, deroule (6 etats) puis
// situations de secours CL-7 (9, 8 pour l enseignant). Avec `role` et
// `etat` : la salle en plein ecran, donnees fictives (seance_demo.dart) et
// etat local (micro, camera, zoom, agrandi, panneaux). Aucun appel serveur
// (consigne K-28). La guidee lit le theme `InterfaceMode.enfant`.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/tc_classe/roster_classe_vm.dart';
import '../../core/tc_groupe/group_summary_vm.dart' show TitreEnseignant;
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pressable.dart';
import '../salle_seance/actions_seance.dart';
import '../salle_seance/outils_dock_salle.dart';
import '../salle_seance/panneau_eleves.dart';
import '../salle_seance/resultat_seance.dart';
import '../salle_seance/salle_seance.dart';
import '../salle_seance/signalement_seance.dart';
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
        // Le titre de demonstration, comme l'Espace Classe (`&titre=sayyida`).
        titre: etat.uri.queryParameters['titre'] == 'sayyida'
            ? TitreEnseignant.sayyida
            : TitreEnseignant.sayyid,
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
  const DemoSallePage({
    this.role,
    this.etat,
    this.titre = TitreEnseignant.sayyid,
    super.key,
  });

  final RoleSeance? role;
  final EtatDemoSalle? etat;

  /// Le titre de l'enseignant de la demonstration (E16).
  final TitreEnseignant titre;

  @override
  Widget build(BuildContext context) {
    final RoleSeance? r = role;
    final EtatDemoSalle? e = etat;
    if (r == null || e == null) return const _ListeDemo();
    final Widget salle = SalleDemo(
      key: ValueKey<String>('${r.name}-${e.name}'),
      role: r,
      etat: e,
      titre: titre,
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
  EtatDemoSalle.appel => t.salle.seance.demo.etats.appel,
  EtatDemoSalle.supports => t.salle.seance.demo.etats.supports,
  EtatDemoSalle.fin => t.salle.seance.demo.etats.fin,
  EtatDemoSalle.reseauFaible => t.salle.seance.demo.etats.reseauFaible,
  EtatDemoSalle.reconnexion => t.salle.seance.demo.etats.reconnexion,
  EtatDemoSalle.retablie => t.salle.seance.demo.etats.retablie,
  EtatDemoSalle.echec => t.salle.seance.demo.etats.echec,
  EtatDemoSalle.horsLigne => t.salle.seance.demo.etats.horsLigne,
  EtatDemoSalle.microBloque => t.salle.seance.demo.etats.microBloque,
  EtatDemoSalle.cameraInterdite => t.salle.seance.demo.etats.cameraInterdite,
  EtatDemoSalle.prolongee => t.salle.seance.demo.etats.prolongee,
  EtatDemoSalle.accesRetire => t.salle.seance.demo.etats.accesRetire,
};

/// Les etats du deroule ordinaire de la seance (lots CL-1 a CL-6).
const List<EtatDemoSalle> etatsDemoSeance = <EtatDemoSalle>[
  EtatDemoSalle.repos,
  EtatDemoSalle.visite,
  EtatDemoSalle.rienPartage,
  EtatDemoSalle.eleves,
  EtatDemoSalle.appel,
  EtatDemoSalle.supports,
  EtatDemoSalle.fin,
];

/// Les situations de secours (lot CL-7) proposees pour [role], dans l'ordre
/// de la spec (P06, P05, P09, P10, P11, P12). Une situation sans objet pour
/// un role n'est pas listee : la camera est toujours permise a l'enseignant
/// (matrice des roles), donc pas de « Camera interdite » pour lui.
List<EtatDemoSalle> etatsDemoSecours(RoleSeance role) => <EtatDemoSalle>[
  for (final EtatDemoSalle etat in EtatDemoSalle.values)
    if (!etatsDemoSeance.contains(etat) &&
        !(role == RoleSeance.enseignant &&
            etat == EtatDemoSalle.cameraInterdite))
      etat,
];

class _ListeDemo extends StatelessWidget {
  const _ListeDemo();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ThemeData theme = Theme.of(context);
    Widget groupe(String titre, RoleSeance role, List<EtatDemoSalle> etats) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              titre,
              style: palette.inkMuted.applyTo(
                theme.textTheme.labelLarge ?? const TextStyle(),
              ),
            ),
            Ecart.vSm,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                for (final EtatDemoSalle etat in etats)
                  _Lien(
                    key: ValueKey<String>('lien-${role.name}-${etat.name}'),
                    libelle: _libelleEtat(etat),
                    onPress: () => context.go(adresseDemoSalle(role, etat)),
                  ),
              ],
            ),
          ],
        );
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
            Semantics(
              header: true,
              child: Text(
                _libelleRole(role),
                style: palette.inkStrong.applyTo(
                  theme.textTheme.titleMedium ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vMd,
            groupe(t.salle.seance.demo.groupes.seance, role, etatsDemoSeance),
            Ecart.vLg,
            groupe(
              t.salle.seance.demo.groupes.secours,
              role,
              etatsDemoSecours(role),
            ),
          ],
        ],
      ),
    );
  }
}

class _Lien extends StatelessWidget {
  const _Lien({required this.libelle, required this.onPress, super.key});

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
              // Reflow 320 et texte 200 % (T-S6) : le libelle passe a la ligne.
              Flexible(
                child: Text(
                  libelle,
                  style: palette.inkStrong.applyTo(
                    Theme.of(context).textTheme.labelLarge ?? const TextStyle(),
                  ),
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
    this.titre = TitreEnseignant.sayyid,
    this.tutoiement,
    super.key,
  });

  final RoleSeance role;
  final EtatDemoSalle etat;
  final VoidCallback onSortir;

  /// Le titre de l'enseignant de la demonstration (E16).
  final TitreEnseignant titre;

  /// MA-5 : tutoiement selon l'age (mineur ou adulte) ; `null` : par le role.
  final bool? tutoiement;

  @override
  State<SalleDemo> createState() => _SalleDemoState();
}

class _SalleDemoState extends State<SalleDemo> {
  static const double _pasZoom = 0.1;
  static const double _zoomMin = 0.5;
  static const double _zoomMax = 2;

  bool _micro = true;

  /// EN-10 : la camera de l'enseignant ne s'allume jamais sans son geste.
  late bool _camera = widget.role != RoleSeance.enseignant;

  /// La connexion apres « Reessayer » ; `null` : celle de l'etat choisi.
  ConnexionSeance? _connexion;

  /// L'eleve a quitte la salle avant la fin (apres confirmation).
  bool _quittee = false;
  bool _agrandi = false;
  double _zoom = 1;

  /// La file de recitation locale (EN-9) : « Faire reciter » donne la parole
  /// sans serveur, par le modele de `ControleurRecitation`.
  late FileRecitation _recitation = DonneesSeanceDemo.vue(
    widget.role,
    widget.etat,
  ).recitation;

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

  /// Le support ouvert depuis le panneau Supports ; `null` : celui de l'etat.
  SupportSeance? _support;

  /// « Ouvrir » (CLV-08) : le support affiche change, le panneau se ferme.
  void _ouvrirSupport(SupportDisponible choisi) => setState(() {
    _support = choisi.contenu ?? _support;
    _panneau = PanneauOuvert.aucun;
  });

  @override
  Widget build(BuildContext context) {
    final VueSeance etat = DonneesSeanceDemo.vue(
      widget.role,
      widget.etat,
      titre: widget.titre,
    );
    final VueSeance vue = etat.copyWith(
      panneau: _panneau,
      support: etat.support == null ? null : _support,
      connexion: _connexion,
      recitation: _recitation,
      tutoiement: widget.tutoiement,
    );
    final bool enseignant = widget.role == RoleSeance.enseignant;
    // Fin de seance de l'enseignant : CLV-10 (le cahier n'existe pas en
    // demonstration : « Ouvrir le cahier » ramene a la liste des etats).
    if (enseignant && vue.estFinie) {
      return FinSeanceEnseignant(
        vue: vue,
        actions: ActionsSeance(
          onRetour: widget.onSortir,
          onNotifications: _inerte,
          onReglages: _inerte,
          onCompte: _inerte,
          onNaviguer: (String _) => widget.onSortir(),
        ),
        onOuvrirCahier: widget.onSortir,
        onRevenirJournee: widget.onSortir,
      );
    }
    // Fin de seance ou sortie volontaire de l'eleve : CLV-09.
    final IssueSeance? issue = _quittee
        ? IssueSeance.quittee
        : DonneesSeanceDemo.issueEleve(widget.etat);
    if (!enseignant && issue != null) {
      return ResultatSeance(issue: issue, onRetour: widget.onSortir);
    }
    late final ActionsSeance actions;
    actions = ActionsSeance(
      // EN-10 : « Partager » (etat partage publie a BR-1, K-28 : rien ici)
      // et « Ouvrir les outils d'enseignement » (Teaching Dock en feuille).
      onPartager: enseignant ? _inerte : null,
      onOutilsEnseignement: enseignant
          ? () => unawaited(ouvrirOutilsEnseignement(context, actions: actions))
          : null,
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
      // Le rail sort de la salle (apres confirmation) : en demonstration,
      // retour a la liste des etats.
      onNaviguer: enseignant ? (String _) => widget.onSortir() : null,
      // Les quatre actions de la fiche (panneau Eleves) : sans serveur en
      // demonstration. Le rappel reussi ne produit rien (spec 10.2).
      onRappeler: enseignant ? (EleveSeance _) => _inerte() : null,
      onChoisirPourReciter: enseignant
          ? (EleveSeance e) => setState(
              () =>
                  _recitation = _recitation.donnerLaParoleA(cleEleveSeance(e)),
            )
          : null,
      onNoter: enseignant ? (EleveSeance _) => _inerte() : null,
      // EN-9b : la feuille « Signaler un besoin » d'EN-4, sans envoi.
      onSignaler: enseignant
          ? (EleveSeance e) => unawaited(signalerDepuisSeance(context, e, vue))
          : null,
      // Le panneau Supports : « Ouvrir » agit. EN-10 : « Voir toute la
      // bibliotheque » ouvre le selecteur de ressources (donnees de la
      // demonstration ; catalogue cable a BR-1).
      onOuvrirSupport: enseignant ? _ouvrirSupport : null,
      onBibliotheque: enseignant
          ? () => _basculerPanneau(PanneauOuvert.ressources)
          : null,
      // Secours (CL-7), sans serveur : « Reessayer » simule le retour de la
      // connexion (« Connexion retablie. ») ; « Continuer sans micro »
      // laisse le micro coupe. Ouvrir les reglages : BR-1 (non rendu).
      onReessayerConnexion: () =>
          setState(() => _connexion = ConnexionSeance.retablie),
      onContinuerSansMicro: () => setState(() => _micro = false),
    );
    return SalleSeance(
      vue: vue,
      local: EtatLocalSeance(
        microOuvert: _micro,
        cameraAllumee: _camera,
        zoom: _zoom,
        agrandi: _agrandi,
      ),
      actions: actions,
    );
  }
}
