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
import '../../core/tc_bibliotheque/content_position.dart';
import '../../core/tc_bibliotheque/donnees_catalogue.dart';
import '../../core/tc_bibliotheque/library_resource.dart';
import '../../core/tc_classe/roster_classe_vm.dart';
import '../../core/tc_groupe/group_summary_vm.dart' show TitreEnseignant;
import '../../core/tc_horloge/chrono_seance.dart' show BornesChrono;
import '../../core/tc_outils/annotation_layer.dart'
    show AnnotationLayer, TraitVectoriel;
import '../../core/tc_outils/etat_outils.dart';
import '../../core/tc_outils/operations_personnelles.dart';
import '../../core/tc_outils/port_annotations.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/status_pill.dart';
import '../salle_seance/actions_seance.dart';
import '../salle_seance/notes_deposees.dart';
import '../salle_seance/panneau_eleves.dart';
import '../salle_seance/portee_outils_salle.dart';
import '../salle_seance/resultat_seance.dart';
import '../salle_seance/salle_seance.dart';
import '../salle_seance/signalement_seance.dart';
import '../salle_seance/surface_page_fixe.dart' show PorteeSupportRecu;
import '../salle_seance/vue_seance.dart';
import 'mode_demonstration.dart';
import 'salle_observateur_demo.dart';
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
        // TB-11a : la salle d'un observateur (`&obs=tuteur`).
        observateur: _lire(
          ObservateurDemo.values,
          etat.uri.queryParameters['obs'],
        ),
        // Le titre de demonstration, comme l'Espace Classe (`&titre=sayyida`).
        titre: etat.uri.queryParameters['titre'] == 'sayyida'
            ? TitreEnseignant.sayyida
            : TitreEnseignant.sayyid,
        // TB-3 : l'enregistrement de demonstration (`&enr=inactif`).
        enregistrement:
            _lire(EtatEnregistrement.values, etat.uri.queryParameters['enr']) ??
            EtatEnregistrement.actif,
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

/// TB-11a : l'adresse de la salle d'un observateur dans une situation.
String adresseDemoSalleObservateur(
  ObservateurDemo observateur,
  SituationTb situation,
) => Uri(
  path: Routes.demoSalle,
  queryParameters: <String, String>{
    'obs': observateur.name,
    'tb': situation.name,
  },
).toString();

/// L'identifiant fictif de la seance observee.
const String _seanceObservee = 'demo-seance';

/// La page : la liste, ou la salle si [role] et [etat] (ou [situation])
/// sont donnes, ou celle d'un [observateur].
class DemoSallePage extends StatelessWidget {
  const DemoSallePage({
    this.role,
    this.etat,
    this.situation,
    this.observateur,
    this.titre = TitreEnseignant.sayyid,
    this.enregistrement = EtatEnregistrement.actif,
    super.key,
  });

  final RoleSeance? role;

  /// L'etat ; avec une [situation], il en remplace l'etat de base (TB-3 :
  /// `&etat=visite` montre la notice de l'enfant pendant le partage).
  final EtatDemoSalle? etat;

  /// TB-3 : l'enregistrement de la situation (actif par defaut).
  final EtatEnregistrement enregistrement;

  /// TB-1b : la situation Supports et tableau ; elle prime sur [etat]. Une
  /// situation sans objet pour le role ramene a la liste.
  final SituationTb? situation;

  /// Le titre de l'enseignant de la demonstration (E16).
  final TitreEnseignant titre;

  /// TB-11a : l'observateur (tuteur, controleur) ; il prime sur [role]. Sa
  /// salle est la VRAIE `SallePage`, la presentation lue celle de
  /// [situation] (une situation sans objet pour lui ramene a la liste).
  final ObservateurDemo? observateur;

  @override
  Widget build(BuildContext context) {
    final ObservateurDemo? o = observateur;
    if (o != null) {
      final SituationTb s = situation ?? SituationTb.sal00;
      if (!situationsObservateur.contains(s)) return const _ListeDemo();
      return SalleObservateurDemo(
        key: ValueKey<String>('obs-${o.name}-tb-${s.name}'),
        observateur: o,
        seanceId: _seanceObservee,
        presentation: presentationObserveeDemo(s),
      );
    }
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
          etat: etat ?? DonneesSeanceDemo.etatBaseTb(s),
          situation: s,
          titre: titre,
          enregistrement: enregistrement,
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

String _libelleObservateur(ObservateurDemo o) => switch (o) {
  ObservateurDemo.tuteur => t.salle.seance.demo.roles.tuteur,
  ObservateurDemo.controleur => t.salle.seance.demo.roles.controleur,
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
          // TB-11a : les observateurs, la presentation en lecture seule.
          for (final ObservateurDemo o in ObservateurDemo.values) ...<Widget>[
            Ecart.vXxl,
            Semantics(
              header: true,
              child: Text(
                _libelleObservateur(o),
                style: palette.inkStrong.applyTo(
                  theme.textTheme.titleMedium ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vMd,
            titreGroupe(t.salle.seance.demo.groupes.tableau),
            Ecart.vSm,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                for (final SituationTb s in situationsObservateur)
                  _Lien(
                    key: ValueKey<String>('lien-obs-${o.name}-tb-${s.name}'),
                    libelle: _libelleSituation(s),
                    onPress: () =>
                        context.go(adresseDemoSalleObservateur(o, s)),
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
    this.enregistrement = EtatEnregistrement.actif,
    super.key,
  });

  final RoleSeance role;
  final EtatDemoSalle etat;
  final VoidCallback onSortir;

  /// TB-3 : l'enregistrement de la situation (actif par defaut).
  final EtatEnregistrement enregistrement;

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

  /// TB-7b : le depot d'annotations de la demonstration, en memoire (le
  /// « double local assume » de `AnnotationsMemoire`) : les notes vivent le
  /// temps de la salle ouverte, rien n'est envoye ni enregistre (TB-BR).
  /// `null` quand l'hote en fournit deja un (tests, Classe Live).
  late final AnnotationsMemoire? _depot = _depotDemonstration();

  AnnotationsMemoire? _depotDemonstration() {
    try {
      final PortAnnotations hote = ProviderScope.containerOf(
        context,
        listen: false,
      ).read(portAnnotationsProvider);
      // Le defaut de production (`AnnotationsIndisponibles`) n'est pas un
      // depot fourni par l'hote : la demonstration prend alors le sien.
      if (hote is! AnnotationsIndisponibles) return null;
    } on Object {
      // Aucun depot fourni.
    }
    return AnnotationsMemoire(DonneesSeanceDemo.groupeDemo);
  }

  @override
  void dispose() {
    unawaited(_depot?.liberer());
    super.dispose();
  }

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
    final VueSeance vue = s == null
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
            etat: widget.etat,
            enregistrement: widget.enregistrement,
          );
    // LIVE-CHRONO-01 : la demonstration porte les bornes d'une vraie seance,
    // fixees une fois a l'ouverture de l'ecran. Les situations de la recette
    // TB gardent leur en-tete d'origine (leurs mesures en dependent).
    if (s != null) {
      return vue;
    }
    return vue.copyWith(
      chrono: vue.horloge is HorlogeDepassee ? _chronoDepasse : _chronoEnCours,
    );
  }

  late final BornesChrono _chronoEnCours = DonneesSeanceDemo.chronoDemo(
    DateTime.now(),
  );
  late final BornesChrono _chronoDepasse = DonneesSeanceDemo.chronoDemo(
    DateTime.now(),
    depasse: true,
  );

  /// La file de recitation locale (EN-9) : « Faire reciter » donne la parole
  /// sans serveur, par le modele de `ControleurRecitation`.
  late FileRecitation _recitation = _donnees().recitation;

  late PanneauOuvert _panneau = _donnees().panneau;

  /// TB-3 : le contexte deplie depuis la capsule (etat local d'interface).
  late ContexteOuvert _contexte = _donnees().contexte;

  // Les commandes sans effet en demonstration (cloche, reglages, compte,
  // outils) : rendues pour montrer l'ecran des images, elles ne font rien.
  void _inerte() {}

  void _zoomer(double pas) => setState(() {
    _zoom = ((_zoom + pas).clamp(_zoomMin, _zoomMax) * 10).round() / 10;
  });

  void _basculerPanneau(PanneauOuvert panneau) => setState(() {
    _panneau = _panneau == panneau ? PanneauOuvert.aucun : panneau;
    // TB-4 (plan V2 §18.3) : un seul panneau secondaire a la fois ; les
    // Commandes remplacent le contexte deplie.
    if (_panneau == PanneauOuvert.commandes) _contexte = ContexteOuvert.aucun;
  });

  /// TB-4 : l'affichage choisi dans les Commandes ; `null` : celui de la
  /// situation. Demonstration : rien n'est diffuse (TB-BR-13).
  AffichagePartage? _affichage;

  /// TB-4 : la page choisie dans les Commandes ; `null` : celle de la
  /// situation. Demonstration : rien n'est diffuse (BR-1).
  int? _page;

  void _changerPage(VueSeance vue, int pas) {
    final ({int page, int total})? actuelle = vue.pageCommandes;
    if (actuelle == null) return;
    setState(() {
      _page = (actuelle.page + pas).clamp(1, actuelle.total);
    });
  }

  /// La diapositive a une autre page (demonstration).
  static SupportSeance _diapositiveALaPage(SupportSeance s, int page) =>
      SupportSeance(
        chapitre: s.chapitre,
        titre: s.titre,
        encadre: s.encadre,
        points: s.points,
        page: page.clamp(1, s.pages),
        pages: s.pages,
        ressourceId: s.ressourceId,
      );

  /// Le support ouvert depuis le panneau Supports ; `null` : celui de l'etat.
  SupportSeance? _support;

  /// TB-8 : le support presente depuis la Bibliotheque ; `null` : celui de
  /// la situation.
  SupportPageFixe? _presente;

  /// TB-9 : le support a ete range ; la surface revient au tableau libre
  /// (aucun support presente, aucune diapositive) jusqu'au prochain
  /// « Presenter ».
  bool _range = false;

  /// TB-9 : les supports ranges pendant la seance, a leur page.
  final List<SupportPageFixe> _ranges = <SupportPageFixe>[];

  /// TB-7a, TB-9 : les notes de la seance ; `null` : celles de la
  /// situation. Ranger n'y touche pas ; « Effacer les notes » retire celles
  /// de la surface montree. Rien n'est diffuse (TB-BR).
  List<TraitVectoriel>? _notes;

  /// TB-10 : les autorisations d'ecrire donnees ou retirees dans la
  /// demonstration, par prenom ; absentes : celles de la situation.
  final Map<String, bool> _ecriture = <String, bool>{};

  /// TB-9 : le tableau libre a ete efface (« … du tableau ? »).
  bool _tableauEfface = false;

  /// TB-RC (revue TB-R, M1 ; plan V2 §12) : le support recu apres
  /// « Reessayer » ; `null` : celui de la situation. Demonstration : le
  /// support revient (aucun chargement reel avant BR-1).
  EtatSupportRecu? _supportRecu;

  /// TB-9 (plan V2 §3 « Ranger reellement », §19.2 points 4 et 5) : le
  /// support presente rejoint les supports ranges, a sa page ; le tableau
  /// libre revient, sans copie des notes du support. Aucune confirmation.
  void _ranger(VueSeance vue) {
    final SupportPageFixe? presente = vue.supportPresente;
    if (presente == null) return;
    setState(() {
      _ranges
        ..removeWhere((SupportPageFixe s) => s.id == presente.id)
        ..add(presente);
      _range = true;
      _presente = null;
      _page = null;
    });
  }

  /// TB-9 (plan V2 §12) : apres confirmation, les notes de la surface
  /// montree (la page, ou le tableau libre) sont retirees.
  void _effacerNotes(VueSeance vue) {
    final ContentPosition? ancrage = vue.ancrageSurface;
    if (ancrage == null) return;
    setState(() {
      _notes = <TraitVectoriel>[
        for (final TraitVectoriel trait in vue.notesSurface)
          if (trait.ancrage != ancrage) trait,
      ];
      if (vue.effacementDuTableau) _tableauEfface = true;
    });
    // TB-7b : les notes ecrites dans la demonstration (depot en memoire)
    // de cette surface s'effacent aussi.
    final AnnotationsMemoire? depot = _depot;
    if (depot == null) return;
    for (final AnnotationLayer couche in depot.couches.toList()) {
      for (final TraitVectoriel trait in couche.traits.toList()) {
        if (trait.ancrage == ancrage) {
          unawaited(depot.retirerTrait(couche.id, trait.id));
        }
      }
    }
  }

  /// TB-8 (LIB-02, LIB-03) : « Presenter ». Le chargement se verifie avant
  /// tout changement ; en demonstration, le cahier sans fichier echoue et la
  /// classe garde le support d'avant. Le futur rend l'activation, que la
  /// Bibliotheque n'appelle que si l'enseignant n'a pas renonce pendant le
  /// chargement. Le support s'active a la page de sa position (ancrage page),
  /// sinon a la premiere. Rien n'est diffuse (BR-1).
  Future<VoidCallback> _presenter(
    LibraryResource ressource,
    ContentPosition? position,
  ) async {
    // Le chargement : un tour de boucle, le temps que « Ouverture du
    // support... » se montre.
    await Future<void>(() {});
    if (ressource.id == DonneesSeanceDemo.idSupportIndisponible) {
      throw StateError('demonstration : fichier absent');
    }
    final int? page = position?.typeAncrage == TypeAncrage.page
        ? position?.page
        : null;
    return () {
      if (!mounted) return;
      setState(() {
        // TB-9 : reprendre un support range le retire des ranges ; ses
        // notes de la seance l'attendent a sa page.
        _range = false;
        _ranges.removeWhere((SupportPageFixe s) => s.id == ressource.id);
        final SupportPageFixe presente = DonneesSeanceDemo.pagePresentee(
          ressource,
          page: page,
        );
        _presente = presente;
        // TB-RC (n. 22) : la diapositive suit le support presente, meme
        // sans diapositive propre (support arabe).
        _support =
            DonneesSeanceDemo.diapositiveDe(ressource.id, page: presente) ??
            _support;
        _page = page;
        _affichage = AffichagePartage.avecNotes;
        _panneau = PanneauOuvert.aucun;
      });
    };
  }

  /// « Ouvrir » (CLV-08) : le support affiche change, le panneau se ferme.
  void _ouvrirSupport(SupportDisponible choisi) => setState(() {
    _support = choisi.contenu ?? _support;
    _page = null;
    _panneau = PanneauOuvert.aucun;
  });

  @override
  Widget build(BuildContext context) {
    final VueSeance etat = _donnees(
      titre: widget.titre,
      prenomEleve: widget.prenomEleve,
    );
    final int? page = _page;
    // Comme avant : sans support dans l'etat, rien n'est montre.
    final SupportSeance? diapositive = etat.support == null || _range
        ? null
        : _support ?? etat.support;
    final TableauLibre? tableau = etat.tableauLibre;
    final VueSeance vue = etat.copyWith(
      panneau: _panneau,
      sansSupport: diapositive == null,
      support: diapositive == null
          ? null
          : page == null
          ? _support
          : _diapositiveALaPage(diapositive, page),
      connexion: _connexion,
      recitation: _recitation,
      tutoiement: widget.tutoiement,
      contexte: _contexte,
      affichage: _affichage,
      supportPresente: switch (_presente ?? etat.supportPresente) {
        final SupportPageFixe fixe when page != null => fixe.aLaPage(
          page.clamp(1, fixe.total),
        ),
        _ => _presente,
      },
      // TB-9 : range, plus aucun support presente.
      sansSupportPresente: _range,
      supportsRanges: List<SupportPageFixe>.unmodifiable(_ranges),
      eleves: _ecriture.isEmpty
          ? null
          : <EleveSeance>[
              for (final EleveSeance e in etat.eleves)
                EleveSeance(
                  prenom: e.prenom,
                  statut: e.statut,
                  fiche: e.fiche,
                  id: e.id,
                  cleAvatar: e.cleAvatar,
                  peutEcrire: _ecriture[e.prenom] ?? e.peutEcrire,
                ),
            ],
      notesSurface: _notes,
      supportRecu: _supportRecu,
      tableauLibre: tableau != null && _tableauEfface
          ? TableauLibre(
              largeurCanonique: tableau.largeurCanonique,
              hauteurCanonique: tableau.hauteurCanonique,
            )
          : null,
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
      // TB-4 (CMD-01) : « Commandes » ouvre et reduit le panneau ; les trois
      // affichages, un clic chacun ; « Ajuster a l'ecran » remet le zoom
      // local a 100 %. Etat local, rien n'est diffuse.
      // TB-10 : l'eleve et la guidee ont leurs Commandes dans les
      // situations Supports et tableau (lecture, focus, ecriture accordee).
      onCommandes: enseignant || widget.situation != null
          ? () => _basculerPanneau(PanneauOuvert.commandes)
          : null,
      onAffichage: enseignant
          ? (AffichagePartage a) => setState(() => _affichage = a)
          : null,
      onAjusterEcran: enseignant || widget.situation != null
          ? () => setState(() => _zoom = 1)
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
      // TB-3 : « Detail du reseau » du contexte enseignant ouvre la feuille
      // du reseau, comme en Classe Live (sans mesure : l'etat de la
      // connexion de demonstration).
      onReseau: enseignant
          ? () => unawaited(
              AppBottomSheet.ouvrir<void>(
                context,
                titre: t.salle.seance.reseau,
                constructeur: (BuildContext _) => Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: StatusPill(
                    libelle: vue.texteConnexion,
                    ton: vue.connexion.etablie
                        ? TonEtat.succes
                        : TonEtat.avertissement,
                  ),
                ),
              ),
            )
          : null,
      onEleves: enseignant
          ? () => _basculerPanneau(PanneauOuvert.eleves)
          : null,
      onSupports: enseignant
          ? () => _basculerPanneau(PanneauOuvert.supports)
          : null,
      // TB-10 : « Ecrire » de l'eleve autorise, dans les situations
      // Supports et tableau (depot en memoire, rien n'est diffuse).
      onOutil: enseignant || widget.situation != null
          ? (OutilEnseignement _) => _inerte()
          : null,
      // TB-10 (UX-20) : « Autoriser a ecrire » et « Retirer l'autorisation
      // d'ecrire » sur la fiche ; etat local de la demonstration, rien
      // n'est diffuse (TB-BR-10).
      onAutoriserEcrire: enseignant && widget.situation != null
          ? (EleveSeance e) =>
                setState(() => _ecriture[e.prenom] = !e.peutEcrire)
          : null,
      // TB-4 : la page change dans la demonstration (diffusion a BR-1).
      onPagePrecedente: enseignant ? () => _changerPage(vue, -1) : null,
      onPageSuivante: enseignant ? () => _changerPage(vue, 1) : null,
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
      // TB-8 : la Bibliotheque unique dans les situations Supports et
      // tableau (catalogue de demonstration par le port, ci-dessous).
      onPresenter: enseignant && widget.situation != null ? _presenter : null,
      // TB-9 : ranger et effacer les notes, dans les situations Supports et
      // tableau (Bibliotheque unique) ; rien n'est diffuse (TB-BR).
      onRanger: enseignant && widget.situation != null
          ? () => _ranger(vue)
          : null,
      onEffacerNotes: enseignant && widget.situation != null
          ? () => _effacerNotes(vue)
          : null,
      // Secours (CL-7), sans serveur : « Reessayer » simule le retour de la
      // connexion (« Connexion retablie. ») ; « Continuer sans micro »
      // laisse le micro coupe. Ouvrir les reglages : BR-1 (non rendu).
      onReessayerConnexion: () =>
          setState(() => _connexion = ConnexionSeance.retablie),
      onContinuerSansMicro: () => setState(() => _micro = false),
      // TB-3 : l'avatar et l'oeil de la capsule deplient le contexte,
      // « Reduire » le replie ; etat local, rien n'est diffuse.
      // TB-4 (plan V2 §18.3) : le contexte deplie remplace les Commandes
      // (un seul panneau secondaire), qui ne reviennent pas a sa fermeture.
      onContexte: (ContexteOuvert c) => setState(() {
        _contexte = c;
        if (c != ContexteOuvert.aucun && _panneau == PanneauOuvert.commandes) {
          _panneau = PanneauOuvert.aucun;
        }
      }),
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
    if (widget.situation == null) return PorteeOutilsSalle(child: salle);
    // TB-1b : les inscrits ont une cle de photo (K-44) mais aucun fichier
    // n'est livre ; la demonstration ne demande aucune URL au stockage
    // (K-28) : les initiales en repli (E5).
    return ProviderScope(
      overrides: <Override>[
        // TB-8 : la Bibliotheque unique, alimentee par le port du catalogue
        // avec les supports de la demonstration (aucun serveur, K-28).
        donneesCatalogueProvider(DonneesSeanceDemo.groupeDemo).overrideWith(
          (Ref _) => lireDonneesCatalogue(
            catalogue: DonneesSeanceDemo.catalogueTb,
            offline: DonneesSeanceDemo.etatOfflineTb,
            groupeId: DonneesSeanceDemo.groupeDemo,
          ),
        ),
        avatarUrlProvider.overrideWith(
          (Ref _, String cle) =>
              Future<String>.error(StateError('demonstration : $cle')),
        ),
        // TB-7b : ecrire, gommer et annuler dans la demonstration ; la
        // relecture du depot suit ce depot-ci (famille reprise dans ce
        // perimetre).
        // TB-11b (tour 2) : les traits poses pendant l'interruption
        // appartiennent a cette salle, jamais a la suivante.
        traitsNonPartagesProvider.overrideWith(TraitsNonPartages.new),
        // TB-RC (m21) : l'outil Ecrire et l'historique d'Annuler sont ceux de
        // CETTE salle, jamais ceux de la precedente.
        etatOutilsProvider.overrideWith(ControleurOutils.new),
        historiquePersonnelProvider.overrideWith(ControleurHistorique.new),
        if (_depot case final AnnotationsMemoire depot) ...<Override>[
          portAnnotationsProvider.overrideWithValue(depot),
          notesDeposeesProvider.overrideWith2(NotesDeposees.new),
        ],
      ],
      // TB-RC (M1) : « Reessayer » de l'eleve, sans quitter la seance.
      child: PorteeSupportRecu(onReessayer: _reessayerSupport, child: salle),
    );
  }

  /// TB-RC (M1) : le support redemande revient (demonstration).
  void _reessayerSupport() =>
      setState(() => _supportRecu = EtatSupportRecu.pret);
}
