// R7-04 (revue FI-VAGUE-R) : les lectures d'argent suivent la personne
// connectee. Sur un appareil partage, le solde, les mouvements, les
// beneficiaires de la recharge ou les revenus lus pour une personne ne
// survivent jamais a sa deconnexion : la personne suivante declenche une
// nouvelle lecture du port, au lieu de recevoir la valeur gardee de la
// precedente. Meme precedent que `monAccesProvider` et
// `identiteTitulaireProvider`.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override, ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_finance_direction.dart';
import 'package:rewayah_academy/core/capacites/port_mes_finances.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_politiques_commerciales.dart';
import 'package:rewayah_academy/core/capacites/port_recharge_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_revenus_enseignant.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/finance/finances_profil.dart';
import 'package:rewayah_academy/core/finance/mouvements_profil.dart';
import 'package:rewayah_academy/core/finance/politique_commerciale.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/features/admin_finance/politiques_commerciales.dart';
import 'package:rewayah_academy/features/admin_finance/vue_globale_finance.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/foyer/fiche/mouvements_page.dart';
import 'package:rewayah_academy/features/foyer/finances_foyer.dart';
import 'package:rewayah_academy/features/foyer/transactions_foyer.dart';
import 'package:rewayah_academy/features/revenus_enseignant/revenus_enseignant_page.dart';

import '../../support/harnais.dart' show sansPersonneConnectee;

/// Les paiements du foyer, lectures comptees.
class _Paiements extends PaiementsFoyerFinanceDemo {
  _Paiements() : super(JeuFoyerFinance.unARegulariser);

  int lectures = 0;

  @override
  Future<FinancesFoyer> finances() {
    lectures++;
    return super.finances();
  }

  @override
  Future<List<MouvementProfil>> mouvements(String profilId) {
    lectures++;
    return super.mouvements(profilId);
  }

  @override
  Future<List<MouvementFoyer>> derniersMouvements({int limite = 3}) {
    lectures++;
    return super.derniersMouvements(limite: limite);
  }
}

/// La recharge, lectures comptees.
class _Recharge extends RechargeFoyerFinanceDemo {
  _Recharge() : super(JeuFoyerFinance.unARegulariser);

  int lectures = 0;

  @override
  Future<List<BeneficiaireRecharge>> beneficiaires() {
    lectures++;
    return super.beneficiaires();
  }
}

/// Mes finances, lectures comptees.
class _MesFinances implements PortMesFinances {
  int lectures = 0;

  @override
  Future<FinancesProfil?> finances() async {
    lectures++;
    return null;
  }

  @override
  Future<List<MouvementProfil>> mouvements() async {
    lectures++;
    return const <MouvementProfil>[];
  }
}

/// Les revenus de l'enseignant, lectures comptees.
class _Revenus extends RevenusEnseignantDemo {
  _Revenus();

  int lectures = 0;

  @override
  Future<RevenusEnseignant> moisEnCours() {
    lectures++;
    return super.moisEnCours();
  }

  @override
  Future<List<LigneReleve>> releve() {
    lectures++;
    return super.releve();
  }
}

/// La vue globale de la direction, lectures comptees.
class _Direction extends FinanceDirectionDemo {
  _Direction();

  int lectures = 0;

  @override
  Future<VueGlobaleFinance> vueGlobale() {
    lectures++;
    return super.vueGlobale();
  }
}

/// Les politiques commerciales, lectures comptees.
class _Politiques extends PolitiquesCommercialesDemo {
  _Politiques();

  int lectures = 0;

  @override
  Future<PolitiqueCommerciale> active() {
    lectures++;
    return super.active();
  }
}

void main() {
  late _Paiements paiements;
  late _Recharge recharge;
  late _MesFinances mesFinances;
  late _Revenus revenus;
  late _Direction direction;
  late _Politiques politiques;

  setUp(() {
    paiements = _Paiements();
    recharge = _Recharge();
    mesFinances = _MesFinances();
    revenus = _Revenus();
    direction = _Direction();
    politiques = _Politiques();
  });

  final List<(String, ProviderListenable<AsyncValue<Object?>>, int Function())>
  cas = <(String, ProviderListenable<AsyncValue<Object?>>, int Function())>[
    ('finances du foyer', financesFoyerProvider, () => paiements.lectures),
    (
      'derniers mouvements du foyer',
      derniersMouvementsFoyerProvider,
      () => paiements.lectures,
    ),
    (
      'mouvements d un profil',
      mouvementsProfilProvider(DonneesFinanceDemo.ibrahimId),
      () => paiements.lectures,
    ),
    (
      'beneficiaires de la recharge',
      beneficiairesRechargeProvider,
      () => recharge.lectures,
    ),
    ('mes finances', mesFinancesProvider, () => mesFinances.lectures),
    ('mes mouvements', mesMouvementsProvider, () => mesFinances.lectures),
    (
      'revenus de l enseignant',
      revenusEnseignantProvider,
      () => revenus.lectures,
    ),
    (
      'releve de l enseignant',
      releveEnseignantProvider,
      () => revenus.lectures,
    ),
    (
      'vue globale de la direction',
      vueGlobaleFinanceProvider,
      () => direction.lectures,
    ),
    (
      'politiques commerciales de la direction',
      politiquesCommercialesProvider,
      () => politiques.lectures,
    ),
  ];

  for (final (
        String nom,
        ProviderListenable<AsyncValue<Object?>> lecture,
        int Function() lectures,
      )
      in cas) {
    test('$nom : relue quand la personne connectee change, jamais gardee '
        'de la precedente', () async {
      final ProviderContainer conteneur = ProviderContainer(
        overrides: <Override>[
          demoAuthActiveProvider.overrideWithValue(true),
          sansPersonneConnectee(),
          portPaiementsFoyerProvider.overrideWithValue(paiements),
          portRechargeFoyerProvider.overrideWithValue(recharge),
          portMesFinancesProvider.overrideWithValue(mesFinances),
          portRevenusEnseignantProvider.overrideWithValue(revenus),
          portFinanceDirectionProvider.overrideWithValue(direction),
          portPolitiquesCommercialesProvider.overrideWithValue(politiques),
        ],
      );
      addTearDown(conteneur.dispose);
      final ProviderSubscription<AsyncValue<Object?>> abonnement = conteneur
          .listen(lecture, (_, _) {});
      addTearDown(abonnement.close);
      Future<void> poser() async {
        // Laisse la lecture en cours aboutir.
        for (int i = 0; i < 5; i++) {
          await Future<void>.delayed(Duration.zero);
        }
      }

      // Premiere personne : le titulaire du foyer.
      final SessionControleur session = conteneur.read(sessionProvider.notifier)
        ..ouvrirDemo((role: AppRole.guardian, mode: InterfaceMode.standard));
      await poser();
      final int premiere = lectures();
      expect(premiere, greaterThan(0));

      // La meme personne relit la page : la lecture est gardee.
      conteneur.read(lecture);
      await poser();
      expect(lectures(), premiere);

      // Deconnexion, puis une autre personne sur le meme appareil.
      session
        ..fermerDemo()
        ..ouvrirDemo((role: AppRole.teacher, mode: InterfaceMode.standard));
      conteneur.read(lecture);
      await poser();
      expect(lectures(), greaterThan(premiere));
    });
  }
}
