// La coquille du Comptable en demonstration : /demo/comptable (hors
// production, CPT-F, K-09).
//
// Sans parametre : la liste des ecrans. Avec `ecran` (voir
// [EcranDemoComptable]) et `montants` (`masques` par defaut, `affiches`) :
// la VRAIE coquille (`NavShell`, destinations de
// `destinationsPour(AppRole.accountant)`) sur la VRAIE page de l'ecran, ses
// ports surcharges par les fichiers de demonstration de chaque voie
// (`surchargesDemo...`). Aucun appel serveur, aucun vrai paiement (K-28).
// « Reserve et delegation » passe par la demonstration Finance
// (`/demo/finance?ecran=reserveDelegation`), dans la vraie coquille admin.
//
// **Fichier gele apres CPT-F** (`20_comptable/02_DECOUPAGE.md`, liste A) :
// la liste des ecrans est complete des maintenant ; chaque voie remplit son
// fichier `..._demo.dart`, jamais celui-ci.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';

import '../../core/comptable/visibilite_montants.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/nav_shell.dart';
import '../../core/widgets/page_shell.dart';
import '../admin_finance/finance_page.dart';
import '../comptable/aujourdhui/aujourdhui_page.dart';
import '../comptable/beneficiaires/beneficiaires_page.dart';
import '../comptable/beneficiaires/fil_profil_paiement_page.dart';
import '../comptable/beneficiaires/profil_paiement_page.dart';
import '../comptable/contractuels/contractuels_page.dart';
import '../comptable/contractuels/nouvelle_obligation_page.dart';
import '../comptable/contractuels/obligation_contractuel_page.dart';
import '../comptable/encaissements/detail_encaissement_page.dart';
import '../comptable/encaissements/encaissements_page.dart';
import '../comptable/encaissements/rapprochement_page.dart';
import '../comptable/paiements/detail_paiement_page.dart';
import '../comptable/paiements/paiements_page.dart';
import '../comptable/tresorerie/tresorerie_page.dart';
import '../compte/compte_page.dart';
import '../paiements_recus/recevoir_paiements_page.dart';
import 'comptable/aujourdhui_demo.dart';
import 'comptable/beneficiaires_demo.dart';
import 'comptable/contractuels_demo.dart';
import 'comptable/direction_demo.dart';
import 'comptable/encaissements_demo.dart';
import 'comptable/paiements_demo.dart';
import 'comptable/socle_comptable_demo.dart';
import 'comptable/tresorerie_demo.dart';
import 'comptable/validations_demo.dart';
import 'demo_finance_page.dart' show DemoFinancePage, adresseDemoFinance;
import 'mode_demonstration.dart';
import 'repere_demonstration.dart';

/// Les ecrans de la demonstration Comptable : W01 a W07, M01, M02, les deux
/// surfaces Compte et le delta Direction. Chaque ecran porte la destination
/// de la barre qu'il allume.
enum EcranDemoComptable {
  /// W01 Aujourd'hui.
  aujourdhui(0),

  /// W01, file complete « A traiter » et « Alertes » (`?vue=attention`).
  attention(0),

  /// W02 Paiements a effectuer.
  paiements(1),

  /// W03 Detail d'un paiement.
  detailPaiement(1),

  /// W06 Contractuels.
  contractuels(1),

  /// W06 Detail d'une obligation de contractuel.
  obligationContractuel(1),

  /// W06 Nouvelle obligation (tache focalisee).
  nouvelleObligation(1),

  /// W07 Beneficiaires.
  beneficiaires(1),

  /// W07 Profil de paiement.
  profilPaiement(1),

  /// W07 Fil « Profil de paiement », ouvert par « Relancer » (CPT-COM).
  filProfilPaiement(1),

  /// W04 Tresorerie et coffres.
  tresorerie(2),

  /// W04 ouvert sur « Alimenter la Reserve strategique ».
  alimenter(2),

  /// W05 Encaissements.
  encaissements(2),

  /// W05 Detail d'un encaissement.
  detailEncaissement(2),

  /// Rapprochement.
  rapprochement(2),

  /// Compte du Comptable.
  compte(3),

  /// « Recevoir mes paiements » du Comptable (§20).
  recevoirPaiements(3),

  /// Delta Direction, dans la coquille admin.
  reserveDelegation(null);

  const EcranDemoComptable(this.destination);

  /// L'index de la destination allumee, ou nul hors de la coquille du role.
  final int? destination;
}

/// Valeur de `?montants=` qui revele les montants.
const String montantsAffichesDemo = 'affiches';

/// Les routes de la demonstration Comptable : AUCUNE en production.
List<RouteBase> routesDemoComptable(String environnement) {
  if (!environnementAutoriseDemo(environnement)) return const <RouteBase>[];
  return <RouteBase>[
    GoRoute(
      path: Routes.demoComptable,
      builder: (BuildContext _, GoRouterState etat) => DemoComptablePage(
        ecran: _lire(
          EcranDemoComptable.values,
          etat.uri.queryParameters['ecran'],
        ),
        montantsAffiches:
            etat.uri.queryParameters['montants'] == montantsAffichesDemo,
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

/// L'adresse d'un ecran de la demonstration.
String adresseDemoComptable(
  EcranDemoComptable ecran, {
  bool montantsAffiches = false,
}) => Uri(
  path: Routes.demoComptable,
  queryParameters: <String, String>{
    'ecran': ecran.name,
    if (montantsAffiches) 'montants': montantsAffichesDemo,
  },
).toString();

/// Le libelle d'un ecran.
String libelleEcranDemoComptable(EcranDemoComptable ecran) => switch (ecran) {
  EcranDemoComptable.aujourdhui => t.comptable.aujourdhui.titre,
  EcranDemoComptable.attention => t.comptable.aujourdhui.attention,
  EcranDemoComptable.paiements => t.comptable.paiements.titre,
  EcranDemoComptable.detailPaiement => t.comptable.paiements.detailTitre,
  EcranDemoComptable.contractuels => t.comptable.contractuels.titre,
  EcranDemoComptable.obligationContractuel =>
    t.comptable.contractuels.detailTitre,
  EcranDemoComptable.nouvelleObligation => t.comptable.contractuels.nouvelle,
  EcranDemoComptable.beneficiaires => t.comptable.beneficiaires.titre,
  EcranDemoComptable.profilPaiement => t.comptable.beneficiaires.profilTitre,
  EcranDemoComptable.filProfilPaiement =>
    t.comptable.beneficiaires.profil.filTitre,
  EcranDemoComptable.tresorerie => t.comptable.tresorerie.titre,
  EcranDemoComptable.alimenter => t.comptable.tresorerie.alimenter,
  EcranDemoComptable.encaissements => t.comptable.encaissements.titre,
  EcranDemoComptable.detailEncaissement =>
    t.comptable.encaissements.detailTitre,
  EcranDemoComptable.rapprochement =>
    t.comptable.encaissements.rapprochementTitre,
  EcranDemoComptable.compte => t.comptable.nav.compte,
  EcranDemoComptable.recevoirPaiements =>
    t.comptable.beneficiaires.recevoir.titre,
  EcranDemoComptable.reserveDelegation => t.comptable.direction.titre,
};

/// La session de demonstration : un Comptable resolu, sans source serveur.
class _SessionComptableDemo extends SessionControleur {
  @override
  SessionState build() => const SessionState(
    resolue: true,
    role: AppRole.accountant,
    profileId: SocleComptableDemo.comptableId,
    accountStatus: AccountStatus.active,
    lectureProfil: LectureProfil.presente,
  );
}

/// La visibilite de depart de la demonstration : masques (R-FIN-01), ou
/// affiches pour la variante `?montants=affiches` des captures.
class _VisibiliteDemo extends VisibiliteMontants {
  _VisibiliteDemo(this._initiale);

  final bool _initiale;

  @override
  bool build() => _initiale;
}

/// Les surcharges de la coquille Comptable : la session, le reseau, les
/// ports de chaque voie et la visibilite de depart. Aucun port reseau reel.
List<Override> surchargesCoquilleComptableDemo({
  bool montantsAffiches = false,
}) => <Override>[
  sessionProvider.overrideWith(_SessionComptableDemo.new),
  horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
  visibiliteMontantsProvider.overrideWith(
    () => _VisibiliteDemo(montantsAffiches),
  ),
  ...surchargesDemoAujourdhui(),
  ...surchargesDemoPaiements(),
  ...surchargesDemoTresorerie(),
  ...surchargesDemoEncaissements(),
  ...surchargesDemoBeneficiaires(),
  // CPT-COM : « Relancer » ouvre le fil dans la coquille de demonstration,
  // jamais la route de production (la demonstration n'a qu'un profil).
  cheminFilProfilPaiementProvider.overrideWithValue(
    (String _) => adresseDemoComptable(
      EcranDemoComptable.filProfilPaiement,
      montantsAffiches: montantsAffiches,
    ),
  ),
  ...surchargesDemoContractuels(),
  // Le Comptable lit ses propres demandes de validation (CPT-VAL-1) : la
  // source lui rend « approuver » bloquee sur chacune (autoPaiement).
  ...surchargesDemoDirection(
    validations: ValidationsFinanceDemo(
      lecteurId: SocleComptableDemo.comptableId,
      lecteurNom: SocleComptableDemo.leComptable.nom,
    ),
  ),
];

/// La page : la liste des ecrans, ou la coquille sur l'ecran choisi.
class DemoComptablePage extends StatelessWidget {
  /// Cree la page.
  const DemoComptablePage({
    this.ecran,
    this.montantsAffiches = false,
    super.key,
  });

  /// L'ecran choisi, ou nul pour la liste.
  final EcranDemoComptable? ecran;

  /// Vrai pour partir montants affiches.
  final bool montantsAffiches;

  @override
  Widget build(BuildContext context) {
    final EcranDemoComptable? e = ecran;
    if (e == EcranDemoComptable.reserveDelegation) {
      return const DemoFinancePage(onglet: OngletFinance.reserveDelegation);
    }
    if (e != null) {
      return CoquilleComptableDemo(
        ecran: e,
        montantsAffiches: montantsAffiches,
      );
    }
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final d = t.comptable.demo;
    Text texte(String valeur, {bool fort = false}) => Text(
      valeur,
      style: (fort ? palette.inkStrong : palette.inkMuted).applyTo(
        (fort ? textes.titleMedium : textes.bodyMedium) ?? const TextStyle(),
      ),
    );
    return PageShell(
      titre: d.titre,
      sousTitre: d.mention,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          texte(d.intro),
          for (final EcranDemoComptable ecran
              in EcranDemoComptable.values) ...<Widget>[
            Ecart.vXxl,
            Semantics(
              header: true,
              child: texte(libelleEcranDemoComptable(ecran), fort: true),
            ),
            Ecart.vMd,
            LienFleche(
              key: ValueKey<String>('lien-${ecran.name}-masques'),
              libelle: d.montantsMasques,
              onPress: () => context.go(adresseDemoComptable(ecran)),
            ),
            LienFleche(
              key: ValueKey<String>('lien-${ecran.name}-affiches'),
              libelle: d.montantsAffiches,
              onPress: () => context.go(
                adresseDemoComptable(ecran, montantsAffiches: true),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// La VRAIE coquille Comptable, sur la VRAIE page de [ecran], ses ports
/// surcharges par les fichiers de demonstration des voies.
class CoquilleComptableDemo extends StatelessWidget {
  /// Cree la coquille.
  const CoquilleComptableDemo({
    required this.ecran,
    this.montantsAffiches = false,
    super.key,
  });

  /// L'ecran affiche.
  final EcranDemoComptable ecran;

  /// Vrai pour partir montants affiches.
  final bool montantsAffiches;

  @override
  Widget build(BuildContext context) {
    final List<Destination> destinations = destinationsPour(
      role: AppRole.accountant,
      mode: InterfaceMode.standard,
    );
    return ProviderScope(
      key: ValueKey<String>('${ecran.name}-$montantsAffiches'),
      overrides: surchargesCoquilleComptableDemo(
        montantsAffiches: montantsAffiches,
      ),
      child: RepereDemonstration(
        child: NavShell(
          destinations: destinations,
          indexActif: ecran.destination,
          masquerBarreBasse: ecran == EcranDemoComptable.nouvelleObligation,
          libellesDansLeRail: true,
          onAller: (String chemin) {
            final int i = destinations.indexWhere(
              (Destination d) => d.chemin == chemin,
            );
            if (i == -1) return;
            final EcranDemoComptable cible = switch (i) {
              0 => EcranDemoComptable.aujourdhui,
              1 => EcranDemoComptable.paiements,
              2 => EcranDemoComptable.tresorerie,
              _ => EcranDemoComptable.compte,
            };
            context.go(
              adresseDemoComptable(cible, montantsAffiches: montantsAffiches),
            );
          },
          child: switch (ecran) {
            EcranDemoComptable.aujourdhui => const AujourdhuiComptablePage(),
            EcranDemoComptable.attention => const AujourdhuiComptablePage(
              vue: Routes.vueAttentionComptable,
            ),
            EcranDemoComptable.paiements => const PaiementsAEffectuerPage(),
            EcranDemoComptable.detailPaiement => const DetailPaiementPage(
              obligationId: SocleComptableDemo.obligationDiallo,
            ),
            EcranDemoComptable.contractuels => const ContractuelsPage(),
            EcranDemoComptable.obligationContractuel =>
              const ObligationContractuelPage(
                obligationId: SocleComptableDemo.obligationFacture024,
              ),
            EcranDemoComptable.nouvelleObligation =>
              const NouvelleObligationPage(),
            EcranDemoComptable.beneficiaires => const BeneficiairesPage(),
            EcranDemoComptable.profilPaiement => ProfilPaiementPage(
              beneficiaireId: SocleComptableDemo.enseignants.first.id,
            ),
            EcranDemoComptable.filProfilPaiement => FilProfilPaiementPage(
              beneficiaireId: SocleComptableDemo.enseignants.first.id,
            ),
            EcranDemoComptable.tresorerie => const TresoreriePage(),
            EcranDemoComptable.alimenter => const TresoreriePage(
              action: Routes.actionAlimenterReserve,
            ),
            EcranDemoComptable.encaissements => const EncaissementsPage(),
            EcranDemoComptable.detailEncaissement =>
              const DetailEncaissementPage(encaissementId: 'enc-01'),
            EcranDemoComptable.rapprochement => const RapprochementPage(),
            EcranDemoComptable.compte => const ComptePage(),
            EcranDemoComptable.recevoirPaiements =>
              const RecevoirPaiementsPage(),
            // Rendu plus haut, dans la coquille admin.
            EcranDemoComptable.reserveDelegation => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }
}

/// L'adresse du delta Direction dans la demonstration Finance.
String adresseDemoReserveDelegation() =>
    adresseDemoFinance(OngletFinance.reserveDelegation);
