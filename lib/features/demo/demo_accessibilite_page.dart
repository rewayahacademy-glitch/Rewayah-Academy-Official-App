// Le Mode Accessibilite en demonstration : /demo/accessibilite (hors
// production, MA-1b).
//
// Sans parametre : les liens eleve x moment de la seance. Avec `eleve`
// (mariam, idriss) et `moment` (avant, pendant, apres) : la presentation est
// surchargee en Mode Accessibilite (`surchargePresentationProvider`) autour
// du VRAI Espace Classe eleve de la demonstration de Classe (CL-4). Les
// ecrans propres au mode arrivent de MA-2 a MA-8. Aucun port reseau n'est
// modifie : aucun appel serveur (K-28).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/mode_accessibilite.dart';
import '../../core/accessibilite/port_demande_presentation.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/preferences/preferences_locales.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/video/pre_vol.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/nav_shell.dart';
import '../../core/widgets/page_shell.dart';
import '../accueil_eleve/accueil_accessibilite.dart';
import '../accueil_eleve/apres_seance_accessibilite.dart';
import '../accueil_eleve/coran_accessibilite.dart';
import '../accueil_eleve/mon_espace_accessibilite.dart';
import '../salle/preparation_eleve.dart';
import '../salle/preparation_enseignant.dart' show ReseauPreparation;
import '../salle_seance/vue_seance.dart' show RoleSeance;
import 'accessibilite_demo.dart';
import 'classe_demo.dart' show EtatDemoClasse;
import 'coran_demo_accessibilite.dart';
import 'demo_classe_page.dart' show EcranEleveDemo;
import 'demo_salle_page.dart' show SalleDemo;
import 'mode_demonstration.dart';
import 'repere_demonstration.dart';
import 'seance_demo.dart' show EtatDemoSalle;

/// Les routes de la demonstration du Mode Accessibilite : AUCUNE en
/// production.
List<RouteBase> routesDemoAccessibilite(String environnement) {
  if (!environnementAutoriseDemo(environnement)) return const <RouteBase>[];
  return <RouteBase>[
    GoRoute(
      path: Routes.demoAccessibilite,
      builder: (BuildContext _, GoRouterState etat) => DemoAccessibilitePage(
        eleve: _lire(
          EleveDemoAccessibilite.values,
          etat.uri.queryParameters['eleve'],
        ),
        moment:
            _lire(
              MomentDemoAccessibilite.values,
              etat.uri.queryParameters['moment'],
            ) ??
            MomentDemoAccessibilite.avant,
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

/// L'adresse d'une situation de la demonstration.
String adresseDemoAccessibilite(
  EleveDemoAccessibilite eleve, {
  MomentDemoAccessibilite moment = MomentDemoAccessibilite.avant,
}) => Uri(
  path: Routes.demoAccessibilite,
  queryParameters: <String, String>{'eleve': eleve.name, 'moment': moment.name},
).toString();

/// Le libelle d'un eleve de la demonstration.
String libelleEleveDemoAccessibilite(EleveDemoAccessibilite eleve) =>
    switch (eleve) {
      EleveDemoAccessibilite.mariam => t.accessibilite.demo.eleveMineure,
      EleveDemoAccessibilite.idriss => t.accessibilite.demo.eleveAdulte,
    };

/// Le libelle d'un moment de la seance.
String libelleMomentDemoAccessibilite(MomentDemoAccessibilite moment) =>
    switch (moment) {
      MomentDemoAccessibilite.avant => t.accessibilite.demo.etatAvant,
      MomentDemoAccessibilite.fenetre => t.accessibilite.demo.etatFenetre,
      MomentDemoAccessibilite.pendant => t.accessibilite.demo.etatPendant,
      MomentDemoAccessibilite.apres => t.accessibilite.demo.etatApres,
    };

/// Les surcharges du Mode Accessibilite en demonstration.
List<Override> surchargesAccessibiliteDemo({
  InterfaceMode presentation = DonneesAccessibiliteDemo.presentation,
}) => <Override>[
  surchargePresentationProvider.overrideWithValue(presentation),
  // MA-8 : la page commune des reglages lit la session ; en demonstration,
  // une session eleve fictive, resolue tout de suite, sans serveur.
  sessionProvider.overrideWith(_SessionEleveDemo.new),
];

/// La session eleve fictive de la demonstration (aucun serveur).
class _SessionEleveDemo extends SessionControleur {
  @override
  SessionState build() => const SessionState(
    resolue: true,
    role: AppRole.student,
    accountStatus: AccountStatus.active,
    lectureProfil: LectureProfil.presente,
  );
}

/// La page : la liste des situations, ou l'ecran de la situation choisie.
class DemoAccessibilitePage extends StatelessWidget {
  /// Cree la page.
  const DemoAccessibilitePage({
    this.eleve,
    this.moment = MomentDemoAccessibilite.avant,
    super.key,
  });

  /// L'eleve choisi, ou nul pour la liste.
  final EleveDemoAccessibilite? eleve;

  /// Le moment de la seance.
  final MomentDemoAccessibilite moment;

  @override
  Widget build(BuildContext context) {
    final EleveDemoAccessibilite? e = eleve;
    if (e != null) return EcranAccessibiliteDemo(eleve: e, moment: moment);

    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    Text texte(String valeur, {bool fort = false}) => Text(
      valeur,
      style: (fort ? palette.inkStrong : palette.inkMuted).applyTo(
        (fort ? textes.titleMedium : textes.bodyMedium) ?? const TextStyle(),
      ),
    );
    return PageShell(
      titre: t.accessibilite.demo.titre,
      sousTitre: t.accessibilite.demo.mention,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          texte(t.accessibilite.demo.intro),
          for (final EleveDemoAccessibilite eleve
              in EleveDemoAccessibilite.values) ...<Widget>[
            Ecart.vXxl,
            Semantics(
              header: true,
              child: texte(libelleEleveDemoAccessibilite(eleve), fort: true),
            ),
            Ecart.vMd,
            for (final MomentDemoAccessibilite moment
                in MomentDemoAccessibilite.values)
              LienFleche(
                key: ValueKey<String>('lien-${eleve.name}-${moment.name}'),
                libelle: libelleMomentDemoAccessibilite(moment),
                onPress: () =>
                    context.go(adresseDemoAccessibilite(eleve, moment: moment)),
              ),
          ],
        ],
      ),
    );
  }
}

/// L'ecran d'une situation, en Mode Accessibilite.
///
/// MA-2 : hors de la salle, l'ecran est pose dans la VRAIE coquille
/// (`NavShell`, destinations de `destinationsPour` pour l'eleve), sur Ma
/// classe. Les autres destinations restent dans la demonstration (aucune
/// route reelle, aucun serveur). MA-3 : l'Accueil du mode
/// (`AccueilAccessibilite`) ; MA-7 : le Coran (`CoranAccessibilite`) ;
/// MA-8 : Mon espace (`MonEspaceAccessibilite`). Pendant la seance, aucune
/// navigation d'app (MA17, MA20).
class EcranAccessibiliteDemo extends StatefulWidget {
  /// Cree l'ecran.
  const EcranAccessibiliteDemo({
    required this.eleve,
    this.moment = MomentDemoAccessibilite.avant,
    this.destinationInitiale = indexMaClasse,
    this.etapeInitiale = EtapeDemoAccessibilite.classe,
    this.surchargesCoran,
    this.portDemande = const PortDemandePresentationDemo(),
    super.key,
  });

  /// MA-8 : le port de la demande de presentation standard du mineur ; en
  /// demonstration, le port neutre (aucun serveur). Les tests y posent un
  /// envoi non confirme.
  final PortDemandePresentation portDemande;

  /// MA-7 : le corpus et la navigation du Coran ; nul en demonstration
  /// (aucun serveur, lecteur dans son etat « indisponible »). Les tests et
  /// les captures y posent le corpus de reference des tests.
  final List<Override>? surchargesCoran;

  /// L'eleve.
  final EleveDemoAccessibilite eleve;

  /// Le moment de la seance.
  final MomentDemoAccessibilite moment;

  /// La destination ouverte a l'arrivee (captures de MA-3 : l'Accueil).
  final int destinationInitiale;

  /// L'etape ouverte a l'arrivee (captures de MA-5 : preparation, salle).
  final EtapeDemoAccessibilite etapeInitiale;

  /// L'index de Ma classe dans les destinations de l'eleve.
  static const int indexMaClasse = 1;

  /// L'index de l'Accueil (MA-3).
  static const int indexAccueil = 0;

  /// L'index du Coran.
  static const int indexCoran = 2;

  /// L'index de Mon espace.
  static const int indexMonEspace = 3;

  @override
  State<EcranAccessibiliteDemo> createState() => _EcranAccessibiliteDemoEtat();
}

class _EcranAccessibiliteDemoEtat extends State<EcranAccessibiliteDemo> {
  late int _index = widget.destinationInitiale;

  /// MA-8 : la presentation de la demonstration. L'adulte la bascule depuis
  /// Mon espace (MA24) ; rien n'est envoye (BR-1).
  InterfaceMode _presentation = DonneesAccessibiliteDemo.presentation;

  /// Vrai quand le Suivi est ouvert depuis Ma classe (MA-4).
  bool _suivi = false;

  /// MA14 : la page d'aide honnete. Aucun canal n'est publie : elle le dit,
  /// avec les textes existants de l'aide du compte, sans bouton qui ne
  /// menerait nulle part. Le retour ramene a Mon espace.
  Future<void> _ouvrirAide(BuildContext context) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext contexte) => PageShell(
            key: const ValueKey<String>('demo-aide'),
            titre: t.compte.tuteur.pageAide.titre,
            onRetour: () => Navigator.of(contexte).pop(),
            child: EtatSysteme(
              nature: NatureEtat.aucunResultat,
              titre: t.compte.tuteur.pageAide.indisponibleTitre,
              phrase: t.compte.tuteur.pageAide.aucunCanal,
            ),
          ),
        ),
      );

  void _aller(int index) => setState(() {
    _index = index;
    _suivi = false;
    _apres = false;
  });

  /// MA-6 : au moment « apres », l'ecran « apres la seance » s'ouvre
  /// d'abord (a la place de Ma classe) ; toute navigation le referme.
  late bool _apres =
      widget.moment == MomentDemoAccessibilite.apres &&
      widget.destinationInitiale == EcranAccessibiliteDemo.indexMaClasse;

  /// MA-5 : « Rejoindre » ouvre la preparation guidee, « Entrer dans la
  /// classe » la salle ; la sortie de la salle ramene a la Classe.
  late EtapeDemoAccessibilite _etape = widget.etapeInitiale;

  /// MA-7 : le Coran vit dans un conteneur ISOLE (corpus et navigation de
  /// la demonstration ou des tests) : aucun fournisseur du moteur ne remonte
  /// jusqu'au service serveur de la racine.
  late final ProviderContainer _coran = ProviderContainer(
    overrides: widget.surchargesCoran ?? surchargesCoranDemoAccessibilite(),
  );

  @override
  void dispose() {
    _coran.dispose();
    super.dispose();
  }

  void _etapeSuivante(EtapeDemoAccessibilite etape) =>
      setState(() => _etape = etape);

  /// La preparation guidee (CL-4.6) du Mode Accessibilite : la VRAIE
  /// `PreparationEleve`, tout pret, sans micro ni serveur. Elle defile :
  /// a 200 %, le bouton de l'etape reste atteignable (aucun pied collant).
  Widget _preparation() => RepereDemonstration(
    child: Scaffold(
      body: SafeArea(
        child: PreparationEleve(
          key: const ValueKey<String>('demo-accessibilite-preparation'),
          guidee: true,
          resultat: const ResultatPreVol(
            microDisponible: true,
            cameraDisponible: true,
            sortieAudioDisponible: true,
            permissionRefusee: false,
          ),
          reseau: ReseauPreparation.bonne,
          onEntrer: () => _etapeSuivante(EtapeDemoAccessibilite.salle),
          onContinuerSansMicro: () =>
              _etapeSuivante(EtapeDemoAccessibilite.salle),
          onReessayer: () {},
          onRetour: () => _etapeSuivante(EtapeDemoAccessibilite.classe),
        ),
      ),
    ),
  );

  /// La salle en Mode Accessibilite : la VRAIE salle de l'eleve guide
  /// (`SalleSeance`, role `guidee`), sans navigation d'app. L'observation
  /// par le tuteur ne concerne que la mineure (MA4) ; tutoiement selon
  /// l'age.
  Widget _salle() {
    final bool mineur = DonneesAccessibiliteDemo.mineur(widget.eleve);
    return SalleDemo(
      key: const ValueKey<String>('demo-accessibilite-salle'),
      role: RoleSeance.guidee,
      etat: mineur ? EtatDemoSalle.visite : EtatDemoSalle.repos,
      titre: DonneesAccessibiliteDemo.titre,
      tutoiement: mineur,
      prenomEleve: DonneesAccessibiliteDemo.prenom(widget.eleve),
      onSortir: () => _etapeSuivante(EtapeDemoAccessibilite.classe),
    );
  }

  @override
  Widget build(BuildContext context) {
    final EtatDemoClasse etatClasse = DonneesAccessibiliteDemo.etatClasse(
      widget.moment,
    );
    void entrer() => _etapeSuivante(EtapeDemoAccessibilite.preparation);
    // MA-4 : Ma classe avant la seance. Le VRAI Espace Classe (carte CL-4,
    // un seul emplacement d'entree), titre « Ma classe », tutoiement selon
    // l'age ; le Suivi reste atteignable, puis l'aide en dernier (MA14).
    final Widget maClasse = EcranEleveDemo(
      etat: etatClasse,
      titre: DonneesAccessibiliteDemo.titre,
      titreDestination: t.accessibilite.maClasse.titre,
      tutoiement: DonneesAccessibiliteDemo.mineur(widget.eleve),
      onRejoindre: entrer,
      pied: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          GroupeReglages(
            lignes: <LigneRubrique>[
              LigneRubrique(
                libelle: t.accessibilite.maClasse.suivi,
                legende: t.accessibilite.maClasse.suiviDetail,
                icone: AppIcons.historique,
                onPress: () => setState(() => _suivi = true),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          GroupeReglages(
            lignes: <LigneRubrique>[
              LigneRubrique(
                libelle: t.accessibilite.accueil.aide,
                icone: AppIcons.info,
                onPress: () => _aller(EcranAccessibiliteDemo.indexMonEspace),
              ),
            ],
          ),
        ],
      ),
    );
    final Widget classe = EcranEleveDemo(
      etat: etatClasse,
      titre: DonneesAccessibiliteDemo.titre,
      tutoiement: DonneesAccessibiliteDemo.mineur(widget.eleve),
      onRejoindre: entrer,
    );
    // MA-NAV-1 : la barre montre les destinations du Mode Accessibilite ;
    // les index de la demonstration restent ceux de la liste complete.
    final List<Destination> destinations = destinationsPour(
      role: AppRole.student,
      mode: InterfaceMode.standard,
    );
    // MA-8 : la presentation suit la bascule de demonstration.
    final List<Destination> visibles = destinationsPour(
      role: AppRole.student,
      mode: _presentation,
    );
    final Widget contenu = _etape == EtapeDemoAccessibilite.salle
        ? _salle()
        : _etape == EtapeDemoAccessibilite.preparation
        ? _preparation()
        : widget.moment == MomentDemoAccessibilite.pendant
        ? classe
        : NavShell(
            destinations: visibles,
            indexActif: indexDansBarre(
              visibles: visibles,
              completes: destinations,
              indexComplet: _index,
            ),
            libellesDansLeRail: true,
            onAller: (String chemin) {
              final int i = destinations.indexWhere(
                (Destination d) => d.chemin == chemin,
              );
              if (i != -1) _aller(i);
            },
            child: _apres
                ? ApresSeanceAccessibilite(
                    key: const ValueKey<String>('demo-apres'),
                    espace: DonneesAccessibiliteDemo.espaceAccueil(
                      widget.moment,
                    ),
                    prochaineSeance: DonneesAccessibiliteDemo.seances[1],
                    tutoiement: DonneesAccessibiliteDemo.mineur(widget.eleve),
                    onRetourClasse: () =>
                        _aller(EcranAccessibiliteDemo.indexMaClasse),
                    onTache: () => _aller(EcranAccessibiliteDemo.indexMaClasse),
                    onSupport: () =>
                        _aller(EcranAccessibiliteDemo.indexMaClasse),
                    onAide: () => _aller(EcranAccessibiliteDemo.indexMonEspace),
                  )
                : _index == EcranAccessibiliteDemo.indexMaClasse && _suivi
                ? PageShell(
                    key: const ValueKey<String>('demo-suivi'),
                    titre: t.accessibilite.maClasse.suivi,
                    sousTitre: t.accessibilite.demo.mention,
                    child: const SizedBox.shrink(),
                  )
                : _index == EcranAccessibiliteDemo.indexMaClasse
                ? maClasse
                : _index == EcranAccessibiliteDemo.indexAccueil
                ? AccueilAccessibilite(
                    key: const ValueKey<String>('demo-accueil'),
                    prenom: DonneesAccessibiliteDemo.prenom(widget.eleve),
                    tutoiement: DonneesAccessibiliteDemo.mineur(widget.eleve),
                    espace: DonneesAccessibiliteDemo.espaceAccueil(
                      widget.moment,
                    ),
                    onRejoindre: entrer,
                    onVoirClasse: () =>
                        _aller(EcranAccessibiliteDemo.indexMaClasse),
                    onTache: () => _aller(EcranAccessibiliteDemo.indexMaClasse),
                    onCoran: () => _aller(EcranAccessibiliteDemo.indexCoran),
                    // L'aide vit dans Mon espace en demonstration (MA14,
                    // MA-8) : aucune route reelle hors de la demonstration.
                    onAide: () => _aller(EcranAccessibiliteDemo.indexMonEspace),
                  )
                : _index == EcranAccessibiliteDemo.indexCoran
                ? Consumer(
                    builder: (BuildContext _, WidgetRef ref, Widget? _) {
                      // La preference de l'appareil, lue ici, voyage vers le
                      // conteneur isole du Coran.
                      final bool grande = ref.watch(
                        preferencesLocalesProvider.select(
                          (PreferencesLocales p) => p.lectureGrande,
                        ),
                      );
                      return UncontrolledProviderScope(
                        container: _coran,
                        child: CoranAccessibilite(
                          key: const ValueKey<String>('demo-coran'),
                          tutoiement: DonneesAccessibiliteDemo.mineur(
                            widget.eleve,
                          ),
                          lectureGrande: grande,
                          // Sans surcharge, aucun texte du Coran n'est
                          // charge : l'ecran le dit (revue MA-7, K-59).
                          demonstration: widget.surchargesCoran == null,
                          onAide: () =>
                              _aller(EcranAccessibiliteDemo.indexMonEspace),
                        ),
                      );
                    },
                  )
                : _index == EcranAccessibiliteDemo.indexMonEspace
                ? MonEspaceAccessibilite(
                    key: const ValueKey<String>('demo-mon-espace'),
                    prenom: DonneesAccessibiliteDemo.prenom(widget.eleve),
                    modeActif: _presentation == InterfaceMode.enfant,
                    onAide: () => unawaited(_ouvrirAide(context)),
                    // Le mineur lit l'etat et peut demander la presentation
                    // standard a son tuteur (S7 = b, port neutre) ; l'adulte
                    // bascule (demonstration).
                    portDemande: DonneesAccessibiliteDemo.mineur(widget.eleve)
                        ? widget.portDemande
                        : null,
                    onBasculer: DonneesAccessibiliteDemo.mineur(widget.eleve)
                        ? null
                        : (bool actif) => setState(
                            () => _presentation = actif
                                ? InterfaceMode.enfant
                                : InterfaceMode.standard,
                          ),
                  )
                : PageShell(
                    key: ValueKey<String>('demo-destination-$_index'),
                    titre: destinations[_index].libelle,
                    sousTitre: t.accessibilite.demo.mention,
                    child: const SizedBox.shrink(),
                  ),
          );
    // Sous la racine, le theme suit la session (standard en demonstration) :
    // la presentation du Mode Accessibilite y est reprise telle quelle,
    // `AppTheme.pour` existant, sans aucune couleur nouvelle (K-37).
    return ProviderScope(
      key: ValueKey<String>('${widget.eleve.name}-${widget.moment.name}'),
      overrides: surchargesAccessibiliteDemo(presentation: _presentation),
      child: Theme(
        data: AppTheme.pour(_presentation, Theme.of(context).brightness),
        child: contenu,
      ),
    );
  }
}
