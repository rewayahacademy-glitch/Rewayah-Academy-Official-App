// La salle de seance en demonstration : /demo/salle (hors production).
//
// Sans parametre : la liste des liens par role, deroule (6 etats) puis
// situations de secours CL-7 (9, 8 pour l enseignant), puis situations
// Supports et tableau (TB-1b, `SituationTb`). Avec `role` et `etat` (ou
// `role` et `tb`) : la salle en plein ecran, donnees fictives (seance_demo.dart) et
// etat local (micro, camera, zoom, agrandi, panneaux). Aucun appel serveur
// (consigne K-28). La guidee lit le theme `InterfaceMode.enfant`.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';

import '../../core/appairage/service_avatar.dart' show avatarUrlProvider;
import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/tc_classe/roster_classe_vm.dart';
import '../../core/tc_groupe/group_summary_vm.dart' show TitreEnseignant;
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/page_shell.dart';
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
        // TB-1b : une situation Supports et tableau (`&tb=ped03`).
        situation: _lire(SituationTb.values, etat.uri.queryParameters['tb']),
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

/// L'adresse d'une situation Supports et tableau (TB-1b).
String adresseDemoSalleTb(RoleSeance role, SituationTb situation) => Uri(
  path: Routes.demoSalle,
  queryParameters: <String, String>{'role': role.name, 'tb': situation.name},
).toString();

/// La page : la liste, ou la salle si [role] et [etat] (ou [situation])
/// sont donnes.
class DemoSallePage extends StatelessWidget {
  const DemoSallePage({
    this.role,
    this.etat,
    this.situation,
    this.titre = TitreEnseignant.sayyid,
    super.key,
  });

  final RoleSeance? role;
  final EtatDemoSalle? etat;

  /// TB-1b : la situation Supports et tableau ; elle prime sur [etat]. Une
  /// situation sans objet pour le role ramene a la liste.
  final SituationTb? situation;

  /// Le titre de l'enseignant de la demonstration (E16).
  final TitreEnseignant titre;

  @override
  Widget build(BuildContext context) {
    final RoleSeance? r = role;
    final SituationTb? s = situation;
    if (r != null && s != null) {
      if (!s.concerne(r)) return const _ListeDemo();
      return _themePour(
        context,
        r,
        SalleDemo(
          key: ValueKey<String>('${r.name}-tb-${s.name}'),
          role: r,
          etat: DonneesSeanceDemo.etatBaseTb(s),
          situation: s,
          titre: titre,
          onSortir: () => context.go(Routes.demoSalle),
        ),
      );
    }
    final EtatDemoSalle? e = etat;
    if (r == null || e == null) return const _ListeDemo();
    final Widget salle = SalleDemo(
      key: ValueKey<String>('${r.name}-${e.name}'),
      role: r,
      etat: e,
      titre: titre,
      onSortir: () => context.go(Routes.demoSalle),
    );
    return _themePour(context, r, salle);
  }

  /// La guidee lit le theme `InterfaceMode.enfant`.
  static Widget _themePour(BuildContext context, RoleSeance r, Widget salle) {
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

String _libelleSituation(SituationTb s) => switch (s) {
  SituationTb.sal00 => t.salle.seance.demo.tb.sal00,
  SituationTb.ped01 => t.salle.seance.demo.tb.ped01,
  SituationTb.ped02 => t.salle.seance.demo.tb.ped02,
  SituationTb.ped03 => t.salle.seance.demo.tb.ped03,
  SituationTb.ped04 => t.salle.seance.demo.tb.ped04,
  SituationTb.ui01 => t.salle.seance.demo.tb.ui01,
  SituationTb.ui02 => t.salle.seance.demo.tb.ui02,
  SituationTb.ui03 => t.salle.seance.demo.tb.ui03,
  SituationTb.vis01 => t.salle.seance.demo.tb.vis01,
  SituationTb.ctx01 => t.salle.seance.demo.tb.ctx01,
  SituationTb.ctx02 => t.salle.seance.demo.tb.ctx02,
  SituationTb.cmd01 => t.salle.seance.demo.tb.cmd01,
  SituationTb.cmd02 => t.salle.seance.demo.tb.cmd02,
  SituationTb.cmd03 => t.salle.seance.demo.tb.cmd03,
  SituationTb.lib01 => t.salle.seance.demo.tb.lib01,
  SituationTb.lib02 => t.salle.seance.demo.tb.lib02,
  SituationTb.lib03 => t.salle.seance.demo.tb.lib03,
  SituationTb.lib04 => t.salle.seance.demo.tb.lib04,
  SituationTb.per01 => t.salle.seance.demo.tb.per01,
  SituationTb.dlg01 => t.salle.seance.demo.tb.dlg01,
  SituationTb.err01 => t.salle.seance.demo.tb.err01,
  SituationTb.err02 => t.salle.seance.demo.tb.err02,
  SituationTb.err03 => t.salle.seance.demo.tb.err03,
  SituationTb.end01 => t.salle.seance.demo.tb.end01,
  SituationTb.supportArrive => t.salle.seance.demo.tb.supportArrive,
  SituationTb.ressourceIndisponible =>
    t.salle.seance.demo.tb.ressourceIndisponible,
  SituationTb.autorisationEcrire => t.salle.seance.demo.tb.autorisationEcrire,
  SituationTb.droitRetire => t.salle.seance.demo.tb.droitRetire,
  SituationTb.effacementTableau => t.salle.seance.demo.tb.effacementTableau,
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
    Widget titreGroupe(String titre) => Text(
      titre,
      style: palette.inkMuted.applyTo(
        theme.textTheme.labelLarge ?? const TextStyle(),
      ),
    );
    Widget groupeTb(RoleSeance role) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        titreGroupe(t.salle.seance.demo.groupes.tableau),
        Ecart.vSm,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final SituationTb s in situationsTb(role))
              _Lien(
                key: ValueKey<String>('lien-${role.name}-tb-${s.name}'),
                libelle: _libelleSituation(s),
                onPress: () => context.go(adresseDemoSalleTb(role, s)),
              ),
          ],
        ),
      ],
    );
    Widget groupe(String titre, RoleSeance role, List<EtatDemoSalle> etats) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            titreGroupe(titre),
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
            Ecart.vLg,
            groupeTb(role),
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
  Widget build(BuildContext context) => ActionPrincipale(
    libelle: libelle,
    onPress: onPress,
    niveau: NiveauAction.secondaire,
    fleche: true,
    pleineLargeur: false,
  );
}

/// La salle de demonstration, avec son etat local.
class SalleDemo extends StatefulWidget {
  const SalleDemo({
    required this.role,
    required this.etat,
    required this.onSortir,
    this.titre = TitreEnseignant.sayyid,
    this.tutoiement,
    this.prenomEleve = DonneesSeanceDemo.eleveCourant,
    this.situation,
    super.key,
  });

  final RoleSeance role;
  final EtatDemoSalle etat;
  final VoidCallback onSortir;

  /// TB-1b : la situation Supports et tableau, ou `null`. Ses donnees
  /// viennent de `DonneesSeanceDemo.vueTb` (une seule source).
  final SituationTb? situation;

  /// Le titre de l'enseignant de la demonstration (E16).
  final TitreEnseignant titre;

  /// MA-5 : tutoiement selon l'age (mineur ou adulte) ; `null` : par le role.
  final bool? tutoiement;

  /// MA-5 : l'eleve courant de la demonstration (Mariam par defaut, Idriss
  /// dans la demonstration du Mode Accessibilite).
  final String prenomEleve;

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

  /// UI-03 (TB-1b) : le focus local part de l'etat local `agrandi` existant.
  late bool _agrandi = widget.situation == SituationTb.ui03;
  double _zoom = 1;

  /// Les donnees de l'etat choisi, ou de la situation TB (une seule source).
  VueSeance _donnees({
    TitreEnseignant titre = TitreEnseignant.sayyid,
    String prenomEleve = DonneesSeanceDemo.eleveCourant,
  }) {
    final SituationTb? s = widget.situation;
    return s == null
        ? DonneesSeanceDemo.vue(
            widget.role,
            widget.etat,
            titre: titre,
            prenomEleve: prenomEleve,
          )
        : DonneesSeanceDemo.vueTb(
            widget.role,
            s,
            titre: titre,
            prenomEleve: prenomEleve,
          );
  }

  /// La file de recitation locale (EN-9) : « Faire reciter » donne la parole
  /// sans serveur, par le modele de `ControleurRecitation`.
  late FileRecitation _recitation = _donnees().recitation;

  late PanneauOuvert _panneau = _donnees().panneau;

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
    final VueSeance etat = _donnees(
      titre: widget.titre,
      prenomEleve: widget.prenomEleve,
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
    final Widget salle = SalleSeance(
      vue: vue,
      local: EtatLocalSeance(
        microOuvert: _micro,
        cameraAllumee: _camera,
        zoom: _zoom,
        agrandi: _agrandi,
      ),
      actions: actions,
    );
    if (widget.situation == null) return salle;
    // TB-1b : les inscrits ont une cle de photo (K-44) mais aucun fichier
    // n'est livre ; la demonstration ne demande aucune URL au stockage
    // (K-28) : les initiales en repli (E5).
    return ProviderScope(
      overrides: <Override>[
        avatarUrlProvider.overrideWith(
          (Ref _, String cle) =>
              Future<String>.error(StateError('demonstration : $cle')),
        ),
      ],
      child: salle,
    );
  }
}
