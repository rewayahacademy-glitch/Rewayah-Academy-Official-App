// FI-12 : recette transverse de la voie Finance (guide Finance V4 §10, §13,
// §14), depuis la VRAIE coquille et le VRAI routeur (`routeurProvider`,
// `RewayahApp`) branches sur les demonstrations (`surchargesDemoTuteur`,
// `surchargesDemoAdmin`, `/demo/finance`).
//
// Ce fichier n'ajoute que ce qui manquait. Ce qui est deja tenu ailleurs est
// cite au debut de chaque groupe, avec son fichier et son test, et n'est pas
// rejoue ici.
//
// (a) Un test par bouton ou lien d'action d'un ecran Finance : on appuie,
//     on verifie la destination ou l'effet.
// (b) Un test par refus du guide §13, numerote dans l'ordre du guide (1 a
//     14 ; « bis » et « ter » : le meme refus pour un autre role).
// (c) Les points du §14 que l'on peut mesurer par un test.
//
// Les montages partages sont dans support_recette_fi.dart ; les actions
// restantes et les donnees par role, dans recette_fi_roles_test.dart.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/capacites/port_acces_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_recharge_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/finance/finances_profil.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/finance/mouvements_profil.dart';
import 'package:rewayah_academy/core/finance/politique_commerciale.dart';
import 'package:rewayah_academy/core/finance/suivi_paiement.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/theme/accent_profil.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/avatar_tile.dart';
import 'package:rewayah_academy/core/widgets/bouton_icone.dart';
import 'package:rewayah_academy/core/widgets/carte_groupee.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart'
    show DisqueRetour;
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/identite_profil.dart';
import 'package:rewayah_academy/core/widgets/ligne_moyen_paiement.dart';
import 'package:rewayah_academy/core/widgets/ligne_transaction.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/pastille_financiere.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/features/acces_finance/acces_finance.dart';
import 'package:rewayah_academy/features/accueil_adulte/accueil_adulte_page.dart';
import 'package:rewayah_academy/features/accueil_eleve/accueil_eleve_page.dart';
import 'package:rewayah_academy/features/admin_finance/finance_page.dart';
import 'package:rewayah_academy/features/admin_finance/politiques_commerciales.dart';
import 'package:rewayah_academy/features/admin_finance/vue_globale_finance.dart';
import 'package:rewayah_academy/features/compte/paiements_page.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/demo/demo_finance_page.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/foyer/fiche/acces_page.dart';
import 'package:rewayah_academy/features/foyer/fiche/finances_page.dart';
import 'package:rewayah_academy/features/foyer/fiche/mouvements_page.dart';
import 'package:rewayah_academy/features/foyer/fiche_eleve_page.dart'
    show NoteFiche;
import 'package:rewayah_academy/features/foyer/finances_foyer.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';
import 'package:rewayah_academy/features/foyer/ligne_membre.dart';
import 'package:rewayah_academy/features/foyer/photo_eleve.dart';
import 'package:rewayah_academy/features/foyer/transactions_foyer.dart';
import 'package:rewayah_academy/features/ma_classe_adulte/ma_classe_adulte_page.dart';
import 'package:rewayah_academy/features/mon_espace_adulte/mes_finances_page.dart';
import 'package:rewayah_academy/features/mon_espace_adulte/mon_espace_adulte_page.dart';
import 'package:rewayah_academy/features/suivi_eleve/suivi_eleve_page.dart';
import 'package:rewayah_academy/features/tc_mes_groupes/mes_groupes_page.dart';
import 'package:rewayah_academy/features/tc_mushaf/mushaf_page.dart';

import '../../router/support_routeur.dart' show stabiliser;
import '../../support/selecteur_section.dart';
import 'support_recette_fi.dart';

const String _mariam = DonneesFinanceDemo.mariamId;
const String _ibrahim = DonneesFinanceDemo.ibrahimId;
const String _aicha = DonneesFinanceDemo.aichaId;

/// Les couleurs de profil que le tuteur de la demonstration a choisies
/// (`surchargesDemoTuteur`) : la reference de chaque ecran.
const Map<String, AccentProfil> _accentsAttendus = <String, AccentProfil>{
  'Mariam': AccentProfil.rose,
  'Ibrahim': AccentProfil.ciel,
  'Aïcha': AccentProfil.lavande,
  'Youssef': AccentProfil.peche,
  'Khadija': AccentProfil.sable,
};

/// Le foyer du jeu [jeu], dans l'ordre inverse de la demonstration.
List<EleveDuFoyer> _foyerInverse(JeuFoyerFinance jeu) => <EleveDuFoyer>[
  for (final FinancesProfil p in DonneesFinanceDemo.profils(jeu).reversed)
    EleveDuFoyer(
      id: p.profilId,
      prenom: p.prenom,
      identifiantImmuable: 'STUD-FI-${p.profilId}',
      mode: InterfaceMode.standard,
      camera: CameraPolicy.allowed,
    ),
];

bool _coche(WidgetTester tester, String id) =>
    tester.widget<Checkbox>(find.byKey(RechargeFoyerPage.caseDe(id))).value ??
    false;

/// Les couleurs de profil rendues a l'ecran, par prenom : l'identite d'un
/// profil (`IdentiteProfil`), chaque bandeau d'identite (`BandeauProfil`)
/// autour d'une photo ou d'une vignette d'eleve, et chaque photo ou vignette
/// hors de toute identite, qui se lit sans couleur de profil (`null`).
Map<String, Set<AccentProfil?>> _accentsRendus(WidgetTester tester) {
  final Map<String, Set<AccentProfil?>> vus = <String, Set<AccentProfil?>>{};
  void noter(String prenom, AccentProfil? accent) =>
      vus.putIfAbsent(prenom, () => <AccentProfil?>{}).add(accent);
  for (final IdentiteProfil i in tester.widgetList<IdentiteProfil>(
    find.byType(IdentiteProfil),
  )) {
    noter(i.prenom, i.accent);
  }
  for (final Element e in find.byType(BandeauProfil).evaluate()) {
    final AccentProfil? accent = (e.widget as BandeauProfil).accent;
    final Finder dedans = find.descendant(
      of: find.byWidget(e.widget),
      matching: find.byWidgetPredicate(
        (Widget w) => w is PhotoEleve || w is AvatarTile,
      ),
    );
    for (final Widget w in tester.widgetList(dedans)) {
      noter(switch (w) {
        final PhotoEleve p => p.prenom,
        final AvatarTile a => a.prenom,
        _ => '',
      }, accent);
    }
  }
  for (final Element e
      in find
          .byWidgetPredicate((Widget w) => w is PhotoEleve || w is AvatarTile)
          .evaluate()) {
    bool habille = false;
    e.visitAncestorElements((Element a) {
      habille = a.widget is IdentiteProfil || a.widget is BandeauProfil;
      return !habille;
    });
    if (habille) continue;
    noter(switch (e.widget) {
      final PhotoEleve p => p.prenom,
      final AvatarTile a => a.prenom,
      _ => '',
    }, null);
  }
  return vus;
}

/// Le port de recharge de la demonstration, espion : il garde chaque
/// repartition verifiee et chaque suivi rendu.
class _RechargeEspion extends RechargeFoyerFinanceDemo {
  _RechargeEspion(super.jeu);

  final List<List<MontantRecharge>> verifies = <List<MontantRecharge>>[];
  final List<SuiviPaiement> suivis = <SuiviPaiement>[];

  @override
  Future<RecapitulatifRecharge> verifierMontants(List<MontantRecharge> choix) {
    verifies.add(List<MontantRecharge>.of(choix));
    return super.verifierMontants(choix);
  }

  @override
  Future<SuiviPaiement> suivre(String commandeId) async {
    final SuiviPaiement s = await super.suivre(commandeId);
    suivis.add(s);
    return s;
  }
}

/// Coche Mariam et prend le premier montant propose : le recapitulatif
/// arrive sur la meme page (une seule page, R3-01).
Future<void> _versEtape2(WidgetTester tester) async {
  await toucherFi(tester, find.byKey(RechargeFoyerPage.caseDe(_mariam)));
  await toucherFi(tester, find.byKey(RechargeFoyerPage.plusDe(_mariam)));
  expect(find.byKey(RechargeFoyerPage.recapitulatifKey), findsOneWidget);
}

/// Les fichiers Dart de [dossier], hors code genere.
Iterable<File> _sources(String dossier) => Directory(dossier)
    .listSync(recursive: true)
    .whereType<File>()
    .where((File f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'));

/// Les lignes de code de [f] (commentaires exclus), avec leur numero.
Iterable<(int, String)> _lignesDeCode(File f) sync* {
  final List<String> lignes = f.readAsLinesSync();
  for (int i = 0; i < lignes.length; i++) {
    if (lignes[i].trimLeft().startsWith('//')) continue;
    yield (i + 1, lignes[i]);
  }
}

/// Un tarif, un montant ou une devise ecrit en dur dans un ecran : un
/// `Montant` construit avec un nombre non nul, `usd(...)`, « 50 USD »,
/// « 50 $ » (ecrit `\$` en Dart).
final RegExp _tarifEnDur = RegExp(
  r'Montant\(\s*-?[1-9][0-9]*\s*[,*)]'
  r'|\busd\('
  r'|\b[0-9]+(\s|\\u00A0)?(USD|EUR|GBP|XOF|GNF)\b'
  r'|[0-9](\s|\\u00A0)?\\\$',
);

/// Les anciens montants du guide (§1.4, §2, §12) : la paie 20/26 USD par
/// eleve, le bonus 10/20, les remises 5/10 sur tous les membres. Une date
/// « 5/10/2026 » n'est pas un montant.
final RegExp _ancienMontant = RegExp(
  r'(?<![\d/])(20|26)(\s|\\u00A0)?(USD|\\?\$)'
  r'|(?<![\d/])(20\s*/\s*26|10\s*/\s*20|5\s*/\s*10)(?![\d/])'
  r'|\busd\(\s*(20|26)\s*\)'
  r'|Montant\(\s*(2000|2600)\s*,',
);

/// La base de la voie Finance (branche `ui/finance-v1`).
const String _baseFinance = 'aebd21a5';

/// La reference du refus 14 : la base de la voie si le clone la connait ;
/// sinon le point ou la branche quitte `corrections/revue-directeur-2026-10`
/// (la branche commune d'avant la voie), puis celui ou elle quitte
/// `ui/finance-v1`. Jamais un saut : `null` fait echouer le test, avec ce
/// qui a ete essaye.
({String? reference, List<String> essais}) _referenceBackend() {
  final List<String> essais = <String>[];
  String? commit(List<String> arguments) {
    final ProcessResult r = Process.runSync('git', arguments);
    essais.add('git ${arguments.join(' ')} -> ${r.exitCode}');
    if (r.exitCode != 0) return null;
    final String sortie = (r.stdout as String).trim();
    return sortie.isEmpty ? null : sortie;
  }

  if (commit(<String>['rev-parse', '--verify', '$_baseFinance^{commit}'])
      case final String base) {
    return (reference: base, essais: essais);
  }
  for (final String branche in <String>[
    'origin/corrections/revue-directeur-2026-10',
    'corrections/revue-directeur-2026-10',
    'origin/ui/finance-v1',
    'ui/finance-v1',
  ]) {
    if (commit(<String>['merge-base', 'HEAD', branche]) case final String mb) {
      return (reference: mb, essais: essais);
    }
  }
  return (reference: null, essais: essais);
}

/// Le cours en direct de l'eleve [eleveId], autour de l'heure reelle :
/// l'Accueil de la vraie coquille lit l'horloge du systeme.
Seance _coursEnDirect(String eleveId) {
  final DateTime maintenant = DateTime.now();
  return Seance(
    id: 'fi12-direct',
    debut: maintenant.subtract(const Duration(minutes: 10)),
    fin: maintenant.add(const Duration(minutes: 50)),
    statut: StatutSeance.enCours,
    eleveId: eleveId,
    elevePrenom: 'Ibrahim',
    eleveIdentifiant: 'STUD-FI-$eleveId',
    enseignantId: 't1',
    enseignantPrenom: 'Aminata',
    enseignantIdentifiant: 'TEACH-FI-000001',
  );
}

/// Aucun mot d'argent ni montant dans les textes rendus a l'enfant (guide
/// §1.7, lecon 15). Les heures et capacites des cartes sont des chiffres :
/// seuls les mots et les devises sont cherches.
void _sansCauseFinanciere(WidgetTester tester, String ecran) {
  final RegExp interdit = RegExp(
    r'pay|manque|usd|\$|€|solde|régularis|financ|recharg',
    caseSensitive: false,
  );
  for (final Text texte in tester.widgetList<Text>(find.byType(Text))) {
    final String valeur = texte.data ?? texte.textSpan?.toPlainText() ?? '';
    expect(interdit.hasMatch(valeur), isFalse, reason: '$ecran : $valeur');
  }
}

/// Le telephone de reference et l'ordinateur du guide §6 et §10.
const Size _telephone = Size(390, 844);
const Size _bureau = Size(1440, 900);

/// Un ecran Finance, son montage par la vraie coquille et ses blocs.
typedef _EcranComposition = ({
  String nom,
  Future<void> Function(WidgetTester tester, Size taille) monter,
  List<Finder> Function() blocs,
  bool tacheFocalisee,
});

/// Les blocs de plus haut niveau : cartes et cartes groupees non imbriquees
/// dans une autre.
Finder _cartes() => find.byWidgetPredicate((Widget w) {
  return w is AppCard || w is CarteGroupee;
});

Future<void> Function(WidgetTester, Size) _tuteur(String chemin) =>
    (WidgetTester tester, Size taille) async {
      await monterTuteurFi(tester, depart: chemin, taille: taille);
    };

/// Les dix ecrans de la voie Finance (FI-12), chacun avec les blocs qui
/// portent sa composition.
final List<_EcranComposition> _ecransComposition = <_EcranComposition>[
  (
    nom: 'Foyer',
    monter: _tuteur(Routes.tuteurFoyer),
    blocs: () => <Finder>[
      find.byType(CarteMembre),
      find.byKey(SyntheseSoldesFoyer.cle),
      find.byKey(DernieresTransactionsFoyer.cle),
    ],
    tacheFocalisee: false,
  ),
  (
    nom: 'Fiche > Finances',
    monter: _tuteur(Routes.ficheEleveSousPage(_ibrahim, 'finances')),
    // R2-01 : sur bureau, trois colonnes (identite et parametres, vue
    // financiere et actions, historique) ; sur telephone, une pile.
    blocs: () {
      final Finder colonne = find.byKey(FinancesElevePage.colonneIdentiteKey);
      return <Finder>[
        if (colonne.evaluate().isNotEmpty)
          colonne
        else
          find.byKey(FinancesElevePage.identiteKey),
        find.byKey(FinancesElevePage.vueKey),
        find.byKey(FinancesElevePage.historiqueKey),
      ];
    },
    tacheFocalisee: false,
  ),
  (
    nom: 'Mouvements',
    monter: _tuteur(Routes.ficheEleveSousPage(_ibrahim, 'mouvements')),
    blocs: () {
      final colonne = t.ficheEleve.mouvements.colonne;
      return <Finder>[
        find.byType(LigneTransaction),
        for (final String titre in <String>[
          colonne.date,
          colonne.libelle,
          colonne.montant,
          colonne.statut,
          colonne.recu,
        ])
          find.text(titre),
      ];
    },
    tacheFocalisee: false,
  ),
  (
    nom: 'Fiche > Acces',
    monter: _tuteur(Routes.ficheEleveSousPage(_ibrahim, 'acces')),
    blocs: () => <Finder>[
      find.byKey(AccesElevePage.bandeauKey),
      find.byKey(AccesElevePage.carteKey),
      find.byType(NoteFiche),
    ],
    tacheFocalisee: false,
  ),
  (
    nom: 'Recharge',
    monter: _tuteur(Routes.tuteurFoyerRecharge),
    blocs: () => <Finder>[
      find.byKey(RechargeFoyerPage.caseDe(_mariam)),
      find.byKey(RechargeFoyerPage.montantDe(_mariam)),
    ],
    tacheFocalisee: false,
  ),
  (
    // Le resultat d'un paiement est une tache focalisee (FI-8) : une
    // colonne bornee sur bureau. Le guide §6 refuse « une colonne mobile
    // centree dans 1440 px » : question au directeur dans le rapport.
    nom: 'Resultat',
    monter: _tuteur(
      Routes.resultatRechargePour(
        DonneesFinanceDemo.commandeDemo(EtatPaiement.termine),
      ),
    ),
    blocs: () => <Finder>[
      find.byKey(ResultatRechargePage.etatKey(EtatPaiement.termine)),
      find.byKey(ResultatRechargePage.detailsKey),
      find.byKey(ResultatRechargePage.repartitionKey),
    ],
    tacheFocalisee: true,
  ),
  (
    nom: 'Mes finances (adulte)',
    monter: (WidgetTester tester, Size taille) async {
      await monterAdulteFi(
        tester,
        adresseDemoAdulte(
          EcranDemoAdulte.paiements,
          etat: EtatDemoAdulte.adulteSeul,
        ),
        taille: taille,
      );
    },
    // R2-01 : sur bureau, trois colonnes (identite et parametres, vue
    // financiere et actions, historique) ; sur telephone, une pile.
    blocs: () {
      final Finder colonne = find.byKey(FinancesElevePage.colonneIdentiteKey);
      return <Finder>[
        if (colonne.evaluate().isNotEmpty)
          colonne
        else
          find.byKey(FinancesElevePage.identiteKey),
        find.byKey(FinancesElevePage.vueKey),
        find.byKey(FinancesElevePage.historiqueKey),
      ];
    },
    tacheFocalisee: false,
  ),
  (
    nom: 'Revenus (enseignant)',
    monter: (WidgetTester tester, Size taille) async {
      await monterEnseignantFi(tester, taille: taille);
    },
    blocs: () => <Finder>[_cartes()],
    tacheFocalisee: false,
  ),
  (
    nom: 'Vue globale',
    monter: (WidgetTester tester, Size taille) async {
      await monterAdminFi(tester, depart: Routes.adminFinance, taille: taille);
    },
    blocs: () => <Finder>[_cartes()],
    tacheFocalisee: false,
  ),
  (
    nom: 'Politiques',
    monter: (WidgetTester tester, Size taille) async {
      await monterAdminFi(tester, taille: taille);
    },
    blocs: () => <Finder>[_cartes()],
    tacheFocalisee: false,
  ),
];

void main() {
  // ---------------------------------------------------------------------
  // (a) Les actions de chaque ecran Finance
  // ---------------------------------------------------------------------

  // Deja tenu, sur le vrai routeur :
  // - Foyer, « Recharger plusieurs profils » et « Recharger Ibrahim » :
  //   test/features/foyer/foyer_finances_test.dart (« Recharger Ibrahim »
  //   ouvre la recharge..., « Recharger plusieurs profils » ouvre la meme
  //   recharge...) ;
  // - Foyer 1440, « Voir tout » des transactions :
  //   test/features/foyer/foyer_bureau_test.dart (1440 : trois dernieres
  //   transactions...) ;
  // - Foyer, carte d'un enfant -> fiche -> Finances, et le retour :
  //   test/features/foyer/fiche_eleve_finances_test.dart (Foyer -> fiche de
  //   Mariam -> Finances...).
  group('(a) Foyer', () {
    testWidgets('synthese en echec : « Reessayer » relit les finances', (
      WidgetTester tester,
    ) async {
      bool panne = true;
      int lectures = 0;
      await monterTuteurFi(
        tester,
        sansRetentative: true,
        surcharges: <Override>[
          financesFoyerProvider.overrideWith((Ref _) async {
            lectures++;
            if (panne) throw StateError('lecture refusee');
            return DonneesFinanceDemo.finances(JeuFoyerFinance.unARegulariser);
          }),
        ],
      );
      final Finder synthese = find.byKey(SyntheseSoldesFoyer.cle);
      expect(dansFi(synthese, etatFi(NatureEtat.echecServeur)), findsOneWidget);
      expect(find.byKey(SyntheseSoldesFoyer.rechargerKey), findsNothing);
      panne = false;
      await stabiliser(tester);
      // Sans geste, rien ne relit en silence.
      expect(dansFi(synthese, etatFi(NatureEtat.echecServeur)), findsOneWidget);
      final int avant = lectures;
      await toucherFi(
        tester,
        dansFi(
          synthese,
          find.text(EtatSysteme.libelleActionPar(NatureEtat.echecServeur)),
        ),
      );
      expect(lectures, avant + 1);
      expect(find.byKey(SyntheseSoldesFoyer.rechargerKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1440, transactions en echec : « Reessayer » les relit', (
      WidgetTester tester,
    ) async {
      bool panne = true;
      await monterTuteurFi(
        tester,
        taille: const Size(1440, 2400),
        sansRetentative: true,
        surcharges: <Override>[
          derniersMouvementsFoyerProvider.overrideWith((Ref _) async {
            if (panne) throw StateError('lecture refusee');
            return DonneesFinanceDemo.derniersMouvements(
              JeuFoyerFinance.unARegulariser,
              limite: nombreDernieresTransactions,
            );
          }),
        ],
      );
      final Finder bloc = find.byKey(DernieresTransactionsFoyer.cle);
      expect(dansFi(bloc, etatFi(NatureEtat.echecServeur)), findsOneWidget);
      expect(find.byKey(DernieresTransactionsFoyer.voirToutKey), findsNothing);
      panne = false;
      await toucherFi(
        tester,
        dansFi(
          bloc,
          find.text(EtatSysteme.libelleActionPar(NatureEtat.echecServeur)),
        ),
      );
      expect(
        find.byKey(DernieresTransactionsFoyer.voirToutKey),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  // Deja tenu, sur le vrai routeur :
  // - Fiche > Finances, « Recharger Mariam », « Mouvements », retour,
  //   « Reessayer » : test/features/foyer/fiche_eleve_finances_test.dart ;
  // - Mouvements, retour, filtre par personne, « Voir le recu » et sa
  //   fermeture, « Reessayer » :
  //   test/features/foyer/fiche_eleve_mouvements_test.dart.

  // Deja tenu, sur le vrai routeur (test/features/foyer/
  // recharge_multi_profils_test.dart) : cases, plus et moins, « Tout
  // selectionner », « Verifier », « Modifier », l'abandon vers le Foyer ou
  // vers Compte > Paiements ; (resultat_recharge_test.dart) « Payer »,
  // « Suivre le paiement », « Revenir aux paiements » d'un paiement
  // indisponible (recharge_foyer_adulte_test.dart).
  group('(a) Recharge', () {
    testWidgets('une seule page : decocher retire la ligne du recapitulatif, '
        'les autres choix gardes ; le retour ramene au Foyer', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterTuteurFi(
        tester,
        depart: Routes.tuteurFoyerRecharge,
      );
      await _versEtape2(tester);
      await toucherFi(tester, find.byKey(RechargeFoyerPage.caseDe(_mariam)));
      expect(cheminFi(routeur), Routes.tuteurFoyerRecharge);
      expect(find.byKey(RechargeFoyerPage.recapitulatifKey), findsNothing);
      expect(find.byKey(RechargeFoyerPage.payerKey), findsOneWidget);
      expect(_coche(tester, _mariam), isFalse);
      expect(_coche(tester, _ibrahim), isFalse);
      await toucherFi(
        tester,
        dansFi(find.byType(RechargeFoyerPage), find.byType(DisqueRetour)),
      );
      expect(cheminFi(routeur), Routes.tuteurFoyer);
      expect(tester.takeException(), isNull);
    });

    testWidgets('etape 2 : le moyen de paiement se choisit, sans payer ni '
        'quitter la page', (WidgetTester tester) async {
      final GoRouter routeur = await monterTuteurFi(
        tester,
        depart: Routes.tuteurFoyerRecharge,
      );
      await _versEtape2(tester);
      final Finder ligne = find.byType(LigneMoyenPaiement);
      expect(ligne, findsOneWidget);
      await toucherFi(tester, ligne);
      final LigneMoyenPaiement lue = tester.widget<LigneMoyenPaiement>(ligne);
      expect(lue.rail, RailPaiement.webStripe);
      expect(lue.retenu, isTrue);
      expect(cheminFi(routeur), Routes.tuteurFoyerRecharge);
      expect(find.byKey(RechargeFoyerPage.payerKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // Deja tenu, sur le vrai routeur (test/features/foyer/
  // resultat_recharge_test.dart) : « Actualiser » jusqu'a termine, « Retour
  // aux soldes » vers le Foyer, « Reessayer » et « Recommencer » vers
  // l'etape 1, « Changer de moyen » et « Verifier » vers l'etape 2,
  // « Revenir aux paiements » d'une adresse sans commande, « Reessayer »
  // d'une lecture en echec.
  //
  // Deja tenu, acces enfant, tuteur et adulte : « Rejoindre » present et
  // actif selon la periode financee
  // (test/features/acces_finance/acces_finance_test.dart, vrai routeur au
  // groupe tuteur).
  //
  // Deja tenu, Mes finances de l'adulte depuis la VRAIE coquille adulte
  // (/demo/adulte) : « Recharger », « Mouvements », retours, « Reessayer »
  // (test/features/mon_espace_adulte/mes_finances_test.dart).
  //
  // Deja tenu, Revenus enseignant depuis la vraie coquille et la
  // demonstration : la ligne « Mes revenus » du Profil, le retour,
  // « Reessayer » (test/features/revenus_enseignant/revenus_enseignant_test
  // .dart).
  //
  // Deja tenu, Admin : « Finance » dans la barre et le tiroir, l'onglet
  // Politiques commerciales (test/features/admin_finance/finance_domaine
  // _test.dart).
  group('(a) Admin Finance, vraie application', () {
    testWidgets('Vue globale en echec : « Reessayer » relit', (
      WidgetTester tester,
    ) async {
      int lectures = 0;
      await monterAdminFi(
        tester,
        depart: Routes.adminFinance,
        surcharges: <Override>[
          vueGlobaleFinanceProvider.overrideWith((Ref _) async {
            lectures++;
            throw StateError('panne');
          }),
        ],
      );
      expect(find.byType(FinancePage), findsOneWidget);
      expect(etatFi(NatureEtat.echecServeur), findsOneWidget);
      await toucherFi(
        tester,
        find.text(EtatSysteme.libelleActionPar(NatureEtat.echecServeur)),
      );
      expect(lectures, 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Politiques : le nombre d enfants relit l apercu sur le port', (
      WidgetTester tester,
    ) async {
      await monterAdminFi(tester);
      expect(find.byType(PolitiquesCommercialesContenu), findsOneWidget);
      final pol = t.admin.finance.pol;
      final Finder total = find.byKey(
        PolitiquesCommercialesContenu.apercuTotalKey,
      );
      await toucherFi(tester, find.text(pol.apercuEnfants(n: 5)));
      final ApercuFamille cinq = DonneesFinanceDemo.apercuFamille(
        DonneesFinanceDemo.politiqueBrouillon,
        5,
      );
      expect(dansFi(total, find.text(formaterMontant(cinq.total))), findsOne);
      expect(
        find.byKey(PolitiquesCommercialesContenu.apercuEnfantKey(5)),
        findsOneWidget,
      );
      await toucherFi(tester, find.text(pol.apercuEnfants(n: 1)));
      expect(
        find.byKey(PolitiquesCommercialesContenu.apercuEnfantKey(2)),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Politiques : « un siege de moins » et le type de classe '
        'relisent le taux', (WidgetTester tester) async {
      await monterAdminFi(tester);
      final pol = t.admin.finance.pol;
      final Finder taux = find.byKey(
        PolitiquesCommercialesContenu.apercuTauxKey,
      );
      String parHeure(ApercuEnseignant a) =>
          pol.parHeure(montant: formaterMontant(a.tauxHoraire));
      final PolitiqueCommerciale b = DonneesFinanceDemo.politiqueBrouillon;
      await toucherFi(
        tester,
        find.byWidgetPredicate(
          (Widget w) =>
              w is BoutonIcone && w.libelle == pol.apercuEligiblesMoins,
        ),
      );
      expect(
        dansFi(
          taux,
          find.text(
            parHeure(
              DonneesFinanceDemo.apercuEnseignant(
                b,
                capacite: b.capaciteEnfant,
                eligibles: b.capaciteEnfant - 1,
              ),
            ),
          ),
        ),
        findsOneWidget,
      );
      await toucherFi(tester, find.text(pol.apercuClasseAdultes));
      expect(
        dansFi(
          taux,
          find.text(
            parHeure(
              DonneesFinanceDemo.apercuEnseignant(
                b,
                capacite: b.capaciteAdulte,
                eligibles: b.capaciteAdulte,
              ),
            ),
          ),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Politiques : « Publier » dit l etat honnete, rien n est '
        'publie', (WidgetTester tester) async {
      final GoRouter routeur = await monterAdminFi(tester);
      final pol = t.admin.finance.pol;
      await toucherFi(tester, find.text(pol.publier));
      expect(find.text(pol.publicationIndisponible), findsOneWidget);
      // Aucun succes, la meme page, la version active toujours en place.
      expect(cheminFi(routeur), Routes.adminFinancePolitiques);
      expect(
        find.text(
          pol.versionActive(
            version: DonneesFinanceDemo.politiqueLancement.version,
          ),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('(a) /demo/finance', () {
    testWidgets('Politiques -> « Vue globale », puis « Finance » de la barre : '
        'la demonstration ne la quitte jamais', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final GoRouter routeur = GoRouter(
        initialLocation: adresseDemoFinance(OngletFinance.politiques),
        routes: routesDemoFinance('staging'),
      );
      addTearDown(routeur.dispose);
      await tester.pumpWidget(
        ProviderScope(
          child: TranslationProvider(
            child: MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: AppLocale.fr.flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PolitiquesCommercialesContenu), findsOneWidget);
      await choisirSection(tester, t.admin.finance.vueGlobale);
      await tester.pumpAndSettle();
      expect(adresseFi(routeur).path, Routes.demoFinance);
      expect(
        adresseFi(routeur).queryParameters['ecran'],
        OngletFinance.vueGlobale.name,
      );
      expect(find.byType(VueGlobaleFinanceContenu), findsOneWidget);

      routeur.go(adresseDemoFinance(OngletFinance.politiques));
      await tester.pumpAndSettle();
      await tester.tap(
        dansFi(
          find.byKey(AdminShell.barreLateraleKey),
          find.text(t.nav.admin.finance),
        ),
      );
      await tester.pumpAndSettle();
      expect(adresseFi(routeur).path, Routes.demoFinance);
      expect(
        adresseFi(routeur).queryParameters['ecran'],
        OngletFinance.vueGlobale.name,
      );
      expect(tester.takeException(), isNull);
    });
  });

  // ---------------------------------------------------------------------
  // (b) Les refus du guide §13
  // ---------------------------------------------------------------------
  group('(b) refus §13', () {
    testWidgets('1. une action a deux endroits : toute recharge ouvre LE '
        'meme moteur, sur la meme route', (WidgetTester tester) async {
      final GoRouter routeur = await monterTuteurFi(tester);
      Future<void> depuis(
        String depart,
        Finder bouton,
        Set<String> coches,
      ) async {
        routeur.go(depart);
        await stabiliser(tester);
        await toucherFi(tester, bouton);
        expect(cheminFi(routeur), Routes.tuteurFoyerRecharge, reason: depart);
        expect(find.byType(RechargeFoyerPage), findsOneWidget, reason: depart);
        expect(
          tester
              .widget<RechargeFoyerPage>(find.byType(RechargeFoyerPage))
              .preselection,
          coches,
          reason: depart,
        );
      }

      await depuis(
        Routes.tuteurFoyer,
        find.byKey(SyntheseSoldesFoyer.rechargerKey),
        <String>{},
      );
      await depuis(
        Routes.tuteurFoyer,
        find.byKey(FoyerPage.rechargerPourKey(_ibrahim)),
        <String>{_ibrahim},
      );
      await depuis(
        Routes.ficheEleveSousPage(_ibrahim, 'finances'),
        find.byKey(FinancesElevePage.rechargerKey),
        <String>{_ibrahim},
      );
      await depuis(
        Routes.compteTuteurSousPage('paiements'),
        find.byKey(PaiementsComptePage.rechargerKey),
        <String>{},
      );

      // Dans les sources : un seul ecran de recharge, construit par le
      // routeur et par la demonstration adulte (la meme page), et un seul
      // appel au paiement.
      final List<String> constructions = <String>[];
      final List<String> paiements = <String>[];
      final List<String> pagesRecharge = <String>[];
      for (final File f in _sources('lib')) {
        for (final (int n, String l) in _lignesDeCode(f)) {
          if (l.contains('RechargeFoyerPage(') && !l.contains('const ')) {
            constructions.add(f.path);
          }
          if (RegExp(r'\.payer\(\s*$|\.payer\(recapitulatifId').hasMatch(l)) {
            paiements.add('${f.path}:$n');
          }
          if (RegExp(r'^class \w*Recharge\w*Page\b').hasMatch(l)) {
            pagesRecharge.add(l.split(' ')[1]);
          }
        }
      }
      expect(constructions.toSet(), <String>{
        'lib/core/router/app_router.dart',
        'lib/features/demo/demo_adulte_page.dart',
      });
      expect(paiements, hasLength(1));
      expect(paiements.single, startsWith('lib/features/foyer/recharge_foyer'));
      expect(pagesRecharge.toSet(), <String>{
        'RechargeFoyerPage',
        'ResultatRechargePage',
      });
    });

    testWidgets('2. un enfant ne consomme pas le solde d un autre : Ibrahim '
        'reste a regulariser malgre le solde d Aicha ; chaque debit ne touche '
        'que son profil ; sa recharge ne credite que lui', (
      WidgetTester tester,
    ) async {
      final FinancesFoyer foyer = DonneesFinanceDemo.finances(
        JeuFoyerFinance.unARegulariser,
      );
      final FinancesProfil ibrahim = foyer.profils.firstWhere(
        (FinancesProfil p) => p.profilId == _ibrahim,
      );
      // Le cas du refus : un autre profil a de quoi couvrir le manque.
      expect(
        foyer.profils.any(
          (FinancesProfil p) =>
              p.profilId != _ibrahim &&
              p.solde.mineur >= ibrahim.manque!.mineur,
        ),
        isTrue,
      );
      await monterTuteurFi(tester);
      final Finder carte = find.ancestor(
        of: find.text('Ibrahim').first,
        matching: find.byType(CarteMembre),
      );
      expect(
        dansFi(
          carte,
          find.text(PastilleFinanciere.libelleDe(EtatFinancier.aRegulariser)),
        ),
        findsOneWidget,
      );
      // Le manque pour le mois que le debit attendu finance (R1-05).
      expect(
        find.text(
          t.ficheEleve.finances.manquePourMois(
            montant: formaterMontant(ibrahim.manque!),
            mois: t.commun.dates.mois[ibrahim.prochainDebit!.date.month - 1],
          ),
        ),
        findsOneWidget,
      );
      expect(find.byKey(FoyerPage.rechargerPourKey(_ibrahim)), findsOneWidget);
      // Les mouvements de chaque profil ne citent que lui : aucun transfert.
      for (final FinancesProfil p in foyer.profils) {
        for (final MouvementProfil m in DonneesFinanceDemo.mouvements(
          JeuFoyerFinance.unARegulariser,
          p.profilId,
        )) {
          for (final FinancesProfil autre in foyer.profils) {
            if (autre.profilId == p.profilId) continue;
            expect(m.id.contains(autre.profilId), isFalse, reason: m.id);
          }
        }
      }

      // Chaque debit ne puise que dans SON solde : dans chaque jeu, le solde
      // rendu d'un profil est la somme de SES seuls mouvements, un recu ne
      // lui compte que SA part, et le fil du foyer range chaque mouvement
      // sous le profil qui le porte.
      for (final JeuFoyerFinance jeu in JeuFoyerFinance.values) {
        for (final FinancesProfil p in DonneesFinanceDemo.profils(jeu)) {
          final List<MouvementProfil> siens = DonneesFinanceDemo.mouvements(
            jeu,
            p.profilId,
          );
          expect(
            siens.fold<int>(
              0,
              (int s, MouvementProfil m) => s + m.montant.mineur,
            ),
            p.solde.mineur,
            reason: '${jeu.name} ${p.prenom}',
          );
          for (final MouvementProfil m in siens) {
            final RecuPaiement? recu = m.recu;
            if (recu == null) continue;
            expect(
              recu.allocations
                  .where((AllocationProfil a) => a.profilId == p.profilId)
                  .single
                  .montant,
              m.montant,
              reason: '${jeu.name} ${m.id}',
            );
          }
        }
        for (final MouvementFoyer f in DonneesFinanceDemo.derniersMouvements(
          jeu,
          limite: 100,
        )) {
          expect(
            DonneesFinanceDemo.mouvements(
              jeu,
              f.profilId,
            ).map((MouvementProfil m) => m.id),
            contains(f.mouvement.id),
            reason: '${jeu.name} ${f.mouvement.id}',
          );
        }
      }

      // La recharge d'Ibrahim de bout en bout, sur le vrai routeur : la
      // repartition verifiee, le recapitulatif et le resultat ne creditent
      // que lui ; ni Aicha ni Mariam n'y paraissent.
      final _RechargeEspion espion = _RechargeEspion(
        JeuFoyerFinance.unARegulariser,
      );
      final GoRouter routeur = await monterTuteurFi(
        tester,
        surcharges: <Override>[
          portRechargeFoyerProvider.overrideWithValue(espion),
        ],
      );
      await toucherFi(tester, find.byKey(FoyerPage.rechargerPourKey(_ibrahim)));
      expect(_coche(tester, _ibrahim), isTrue);
      for (final String autre in <String>[_mariam, _aicha]) {
        expect(_coche(tester, autre), isFalse, reason: autre);
      }
      await toucherFi(tester, find.byKey(RechargeFoyerPage.plusDe(_ibrahim)));
      expect(
        espion.verifies.last.map((MontantRecharge c) => c.beneficiaireId),
        <String>[_ibrahim],
      );
      final Montant part = espion.verifies.last.single.montant;
      expect(find.byKey(RechargeFoyerPage.ligneDe(_ibrahim)), findsOneWidget);
      for (final String autre in <String>[_mariam, _aicha]) {
        expect(
          find.byKey(RechargeFoyerPage.ligneDe(autre)),
          findsNothing,
          reason: autre,
        );
      }
      await toucherFi(tester, find.byKey(RechargeFoyerPage.payerKey));
      expect(cheminFi(routeur), Routes.tuteurFoyerRechargeResultat);
      while (find
          .byKey(ResultatRechargePage.etatKey(EtatPaiement.termine))
          .evaluate()
          .isEmpty) {
        expect(espion.suivis.length, lessThan(8), reason: 'jamais termine');
        await toucherFi(tester, find.byKey(ResultatRechargePage.actualiserKey));
      }
      final SuiviPaiement fin = espion.suivis.last;
      expect(fin.etat, EtatPaiement.termine);
      expect(fin.allocations.map((AllocationProfil a) => a.profilId), <String>[
        _ibrahim,
      ]);
      expect(fin.allocations.single.montant, part);
      expect(
        fin.allocations.single.nouveauSolde,
        Montant(ibrahim.solde.mineur + part.mineur, part.devise),
      );
      expect(
        find.byKey(ResultatRechargePage.allocationDe(_ibrahim)),
        findsOneWidget,
      );
      for (final String autre in <String>[_mariam, _aicha]) {
        expect(
          find.byKey(ResultatRechargePage.allocationDe(autre)),
          findsNothing,
          reason: autre,
        );
      }
    });

    testWidgets('3. le total foyer n est pas un wallet : une lecture, aucun '
        'moyen « solde du foyer » a la recharge', (WidgetTester tester) async {
      final GoRouter routeur = await monterTuteurFi(tester);
      final SyntheseFoyer s = DonneesFinanceDemo.finances(
        JeuFoyerFinance.unARegulariser,
      ).synthese;
      final Finder total = find.text(formaterMontant(s.totalSoldes));
      expect(total, findsOneWidget);
      // Le total ne se touche pas et dit qu'il est une somme.
      expect(
        find.ancestor(of: total, matching: find.byType(Pressable)),
        findsNothing,
      );
      expect(find.text(t.argent.soldes.totalDetail), findsOneWidget);
      // La recharge : un seul paiement reparti, chaque part au solde de son
      // profil ; le seul moyen est le paiement web.
      routeur.go(Routes.tuteurFoyerRecharge);
      await stabiliser(tester);
      expect(find.byKey(RechargeFoyerPage.repartitionKey), findsOneWidget);
      await _versEtape2(tester);
      expect(
        tester
            .widgetList<LigneMoyenPaiement>(find.byType(LigneMoyenPaiement))
            .map((LigneMoyenPaiement l) => l.rail),
        <RailPaiement>[RailPaiement.webStripe],
      );
      expect(RailPaiement.values, hasLength(3));
      expect(find.text(formaterMontant(s.totalSoldes)), findsNothing);
    });

    testWidgets('4. un avatar garde sa couleur d un ecran a l autre', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterTuteurFi(tester);
      final Map<String, Set<AccentProfil?>> vus =
          <String, Set<AccentProfil?>>{};
      final Map<String, int> ecrans = <String, int>{};
      void relever(String ecran) {
        final Map<String, Set<AccentProfil?>> ici = _accentsRendus(tester);
        expect(ici, isNotEmpty, reason: ecran);
        for (final MapEntry<String, Set<AccentProfil?>> e in ici.entries) {
          vus.putIfAbsent(e.key, () => {}).addAll(e.value);
          ecrans[e.key] = (ecrans[e.key] ?? 0) + 1;
        }
      }

      relever('Foyer');
      for (final String chemin in <String>[
        Routes.ficheEleveSousPage(_ibrahim, 'finances'),
        Routes.ficheEleveSousPage(_ibrahim, 'mouvements'),
        Routes.tuteurFoyerRecharge,
      ]) {
        routeur.go(chemin);
        await stabiliser(tester);
        if (chemin.endsWith('mouvements')) {
          // L'historique n'a pas d'avatar : le recu ouvert montre la
          // repartition, profil par profil.
          await toucherFi(
            tester,
            find
                .byWidgetPredicate(
                  (Widget w) =>
                      w.key is ValueKey<String> &&
                      (w.key! as ValueKey<String>).value.startsWith(
                        'ficheEleve.mouvements.recu.',
                      ),
                )
                .first,
          );
          relever(chemin);
          await toucherFi(tester, find.byType(DisqueRetour).last);
          continue;
        }
        relever(chemin);
      }
      await _versEtape2(tester);
      relever('recapitulatif');
      // Le resultat d'un paiement termine : la repartition, profil par
      // profil.
      routeur.go(
        Routes.resultatRechargePour(
          DonneesFinanceDemo.commandeDemo(EtatPaiement.termine),
        ),
      );
      await stabiliser(tester);
      relever('resultat');
      // Fiche > Acces et Compte > Paiements ne posent aucun avatar : aucune
      // couleur ne peut y changer (releve vide, dit ici pour ne pas le
      // supposer).
      for (final String chemin in <String>[
        Routes.ficheEleveSousPage(_ibrahim, 'acces'),
        Routes.compteTuteurSousPage('paiements'),
      ]) {
        routeur.go(chemin);
        await stabiliser(tester);
        expect(_accentsRendus(tester), isEmpty, reason: chemin);
      }
      for (final MapEntry<String, Set<AccentProfil?>> e in vus.entries) {
        expect(e.value, <AccentProfil?>{
          _accentsAttendus[e.key],
        }, reason: e.key);
      }
      expect(ecrans['Ibrahim'], greaterThanOrEqualTo(5));
      expect(ecrans['Mariam'], greaterThanOrEqualTo(4));
    });

    testWidgets('4 bis. l eleve adulte : un avatar garde sa couleur de Ma '
        'famille a la recharge ; l adulte autonome, '
        'de Mes finances a sa recharge', (WidgetTester tester) async {
      Future<Map<String, Set<AccentProfil?>>> releve(
        List<String> adresses,
      ) async {
        final Map<String, Set<AccentProfil?>> vus =
            <String, Set<AccentProfil?>>{};
        final Map<String, int> ecrans = <String, int>{};
        for (final String adresse in adresses) {
          await monterAdulteFi(tester, adresse);
          final Map<String, Set<AccentProfil?>> ici = _accentsRendus(tester);
          expect(ici, isNotEmpty, reason: adresse);
          for (final MapEntry<String, Set<AccentProfil?>> e in ici.entries) {
            vus.putIfAbsent(e.key, () => <AccentProfil?>{}).addAll(e.value);
            ecrans[e.key] = (ecrans[e.key] ?? 0) + 1;
          }
        }
        // Un prenom, une seule couleur (ou aucune) sur tous les ecrans.
        for (final MapEntry<String, Set<AccentProfil?>> e in vus.entries) {
          expect(e.value, hasLength(1), reason: '${e.key} : ${e.value}');
        }
        return vus;
      }

      final Map<String, Set<AccentProfil?>> famille = await releve(<String>[
        adresseDemoAdulte(EcranDemoAdulte.maFamille),
        adresseDemoAdulte(EcranDemoAdulte.recharge),
      ]);
      expect(famille.keys, containsAll(<String>['Aïcha', 'Oumar']));
      // Paiements du foyer ne pose plus aucun avatar : ses soldes sont
      // portes par Ma famille (E-11, revue FI-VAGUE-R R1-06), comme Compte
      // > Paiements du tuteur. Aucune couleur ne peut y changer (releve
      // vide, dit ici pour ne pas le supposer).
      await monterAdulteFi(
        tester,
        adresseDemoAdulte(EcranDemoAdulte.paiementsFoyer),
      );
      expect(_accentsRendus(tester), isEmpty);
      final Map<String, Set<AccentProfil?>> seul = await releve(<String>[
        adresseDemoAdulte(
          EcranDemoAdulte.paiements,
          etat: EtatDemoAdulte.adulteSeul,
        ),
        adresseDemoAdulte(
          EcranDemoAdulte.maRecharge,
          etat: EtatDemoAdulte.adulteSeul,
        ),
      ]);
      expect(seul.keys, <String>['Mamadou']);
    });

    testWidgets('5. la couleur de profil ne depend pas de la place dans la '
        'liste : a l envers ou en partie, chaque profil garde sa couleur', (
      WidgetTester tester,
    ) async {
      const JeuFoyerFinance jeu = JeuFoyerFinance.cinqProfils;
      final List<EleveDuFoyer> inverse = _foyerInverse(jeu);
      final Set<int> placesKhadija = <int>{};
      for (final List<EleveDuFoyer>? eleves in <List<EleveDuFoyer>?>[
        null,
        inverse,
        // Youssef et Khadija seuls : ils changent de place a l'ecran.
        inverse.take(2).toList(),
      ]) {
        await monterTuteurFi(
          tester,
          jeu: jeu,
          eleves: eleves,
          taille: const Size(390, 6000),
        );
        final List<CarteMembre> cartes = tester
            .widgetList<CarteMembre>(find.byType(CarteMembre))
            .toList();
        expect(
          cartes,
          hasLength(eleves?.length ?? DonneesFinanceDemo.profils(jeu).length),
        );
        for (final (int i, CarteMembre c) in cartes.indexed) {
          if (c.profil.prenom == 'Khadija') placesKhadija.add(i);
          expect(
            c.accent,
            _accentsAttendus[c.profil.prenom],
            reason: c.profil.prenom,
          );
        }
        for (final MapEntry<String, Set<AccentProfil?>> e in _accentsRendus(
          tester,
        ).entries) {
          expect(e.value, <AccentProfil?>{
            _accentsAttendus[e.key],
          }, reason: e.key);
        }
      }
      expect(placesKhadija.length, greaterThan(1));
    });

    testWidgets('6. aucun statut financier par la couleur seule : chaque '
        'pastille porte son mot, deux etats d un meme ton ont deux mots', (
      WidgetTester tester,
    ) async {
      // Deux etats qui partagent un ton se distinguent par leur mot.
      final Map<Object, Set<String>> parTon = <Object, Set<String>>{};
      for (final EtatFinancier e in EtatFinancier.values) {
        final String mot = PastilleFinanciere.libelleDe(e);
        expect(mot.trim(), isNotEmpty, reason: e.name);
        parTon.putIfAbsent(PastilleFinanciere.tonDe(e), () => <String>{});
        expect(parTon[PastilleFinanciere.tonDe(e)]!.add(mot), isTrue);
      }
      expect(
        EtatFinancier.values.map(PastilleFinanciere.libelleDe).toSet(),
        hasLength(EtatFinancier.values.length),
      );
      // A l'ecran, chaque pastille de chaque jeu se lit en mots.
      for (final JeuFoyerFinance jeu in JeuFoyerFinance.values) {
        await monterTuteurFi(tester, jeu: jeu, taille: const Size(390, 6000));
        final Iterable<PastilleFinanciere> pastilles = tester
            .widgetList<PastilleFinanciere>(find.byType(PastilleFinanciere));
        expect(
          pastilles,
          hasLength(DonneesFinanceDemo.profils(jeu).length),
          reason: jeu.name,
        );
        for (final Element e in find.byType(PastilleFinanciere).evaluate()) {
          final Iterable<Text> textes = tester.widgetList<Text>(
            find.descendant(
              of: find.byWidget(e.widget),
              matching: find.byType(Text),
            ),
          );
          expect(
            textes.any((Text x) => (x.data ?? '').trim().isNotEmpty),
            isTrue,
            reason: '${jeu.name} ${(e.widget as PastilleFinanciere).etat}',
          );
        }
      }
    });

    test('7. aucun tarif code dans un ecran (garde de source sur '
        'lib/features)', () {
      // Contre-epreuve : le garde voit chaque ecriture d'un tarif.
      for (final String ligne in <String>[
        "const Montant(5000, 'USD')",
        'Montant(50 * 100, devise)',
        'tarif: usd(50),',
        "Text('50 USD')",
        "Text('50 \\\$')",
      ]) {
        expect(_tarifEnDur.hasMatch(ligne), isTrue, reason: ligne);
      }
      for (final String ligne in <String>[
        'formaterMontant(finance.solde)',
        'Montant(0, devise)',
        'Montant(-l.montant.mineur, devise)',
        "'\${a.prenom}'",
      ]) {
        expect(_tarifEnDur.hasMatch(ligne), isFalse, reason: ligne);
      }
      // Hors demonstration (K-09) et galerie de developpement.
      final List<String> fautes = <String>[
        for (final File f in _sources('lib/features'))
          if (!f.path.startsWith('lib/features/demo/') &&
              !f.path.startsWith('lib/features/_dev/'))
            for (final (int n, String l) in _lignesDeCode(f))
              if (_tarifEnDur.hasMatch(l)) '${f.path}:$n',
      ];
      expect(fautes, isEmpty);
    });

    testWidgets('8. le mobile n est pas etire sur bureau : a 1440 x 900, '
        'chaque ecran Finance pose ses blocs en colonnes, ou borne sa tache '
        'a la colonne de dialogue, sous la barre laterale', (
      WidgetTester tester,
    ) async {
      final List<String> mesures = <String>[];
      for (final _EcranComposition e in _ecransComposition) {
        await e.monter(tester, _bureau);
        final CompositionFi c = mesurerFi(tester, e.blocs());
        mesures.add('${e.nom} : $c');
        expect(c.blocs, greaterThan(0), reason: '${e.nom} : $c');
        expect(c.navigation, NavigationFi.laterale, reason: '${e.nom} : $c');
        if (e.tacheFocalisee) {
          // Une tache focalisee (resultat d'un paiement) : une colonne
          // bornee, jamais etiree a la page.
          expect(
            c.largeurMax,
            lessThanOrEqualTo(AppPage.largeurDialogue + 0.5),
            reason: '${e.nom} : $c',
          );
        } else {
          expect(c.colonnes, greaterThanOrEqualTo(2), reason: '${e.nom} : $c');
        }
        expect(tester.takeException(), isNull, reason: e.nom);
      }
      // Mouvements : a 1440, le tableau remplace les lignes du telephone.
      await monterTuteurFi(
        tester,
        depart: Routes.ficheEleveSousPage(_ibrahim, 'mouvements'),
        taille: _bureau,
      );
      expect(find.byKey(MouvementsElevePage.tableauKey), findsOneWidget);
      expect(find.byType(LigneTransaction), findsNothing);
      // La recharge : la liste des profils dans sa colonne, jamais a la page.
      await monterTuteurFi(
        tester,
        depart: Routes.tuteurFoyerRecharge,
        taille: _bureau,
      );
      expect(
        tester.getSize(find.byKey(RechargeFoyerPage.profilsKey)).width,
        lessThanOrEqualTo(AppPage.largeurDialogue + 0.5),
      );
      // Les boutons d'action ne s'etirent pas a la colonne.
      for (final (String chemin, Key bouton) in <(String, Key)>[
        (Routes.tuteurFoyerRecharge, RechargeFoyerPage.payerKey),
        (
          Routes.resultatRechargePour(
            DonneesFinanceDemo.commandeDemo(EtatPaiement.termine),
          ),
          ResultatRechargePage.revenirKey,
        ),
        (
          Routes.ficheEleveSousPage(_ibrahim, 'finances'),
          FinancesElevePage.rechargerKey,
        ),
      ]) {
        await monterTuteurFi(tester, depart: chemin, taille: _bureau);
        expect(
          tester.getSize(find.byKey(bouton)).width,
          lessThan(AppPage.largeurDialogue),
          reason: chemin,
        );
      }
      // La mesure, ecran par ecran, pour le rapport.
      debugPrint(mesures.join('\n'));
    });

    testWidgets('9. une maquette bureau n est pas compressee en mobile : a '
        '390, chaque ecran Finance a une seule colonne, la barre basse, des '
        'blocs dans la largeur ; sa composition differe de celle de 1440', (
      WidgetTester tester,
    ) async {
      final List<String> mesures = <String>[];
      for (final _EcranComposition e in _ecransComposition) {
        await e.monter(tester, _telephone);
        final CompositionFi mobile = mesurerFi(tester, e.blocs());
        expect(tester.takeException(), isNull, reason: e.nom);
        await e.monter(tester, _bureau);
        final CompositionFi bureau = mesurerFi(tester, e.blocs());
        mesures.add('${e.nom} : 390 [$mobile] / 1440 [$bureau]');
        final String raison = '${e.nom} : 390 [$mobile] / 1440 [$bureau]';
        expect(mobile.blocs, greaterThan(0), reason: raison);
        // Rien de cote a cote, rien de plus large que la page moins ses
        // gouttieres : aucune colonne de bureau serree dans 390.
        expect(mobile.colonnes, 1, reason: raison);
        expect(
          mobile.largeurMax,
          lessThanOrEqualTo(
            _telephone.width - 2 * AppPage.gouttiereMobile + 0.5,
          ),
          reason: raison,
        );
        // La navigation du telephone : la barre basse (le tiroir ferme pour
        // la direction), jamais la barre laterale.
        expect(
          mobile.navigation,
          isIn(<NavigationFi>[NavigationFi.basse, NavigationFi.aucune]),
          reason: raison,
        );
        expect(bureau.navigation, NavigationFi.laterale, reason: raison);
        if (e.tacheFocalisee) {
          // La tache focalisee garde une colonne, bornee sur bureau.
          expect(
            bureau.largeurMax,
            lessThanOrEqualTo(AppPage.largeurDialogue + 0.5),
            reason: raison,
          );
          expect(bureau.largeurMax, greaterThan(mobile.largeurMax));
        } else {
          expect(bureau.colonnes, greaterThan(mobile.colonnes), reason: raison);
        }
      }
      // Mouvements : la liste du telephone, jamais le tableau de cinq
      // colonnes ; la recharge : le montant sous la ligne du profil.
      await monterTuteurFi(
        tester,
        depart: Routes.ficheEleveSousPage(_ibrahim, 'mouvements'),
        taille: _telephone,
      );
      expect(find.byKey(MouvementsElevePage.tableauKey), findsNothing);
      expect(find.byKey(MouvementsElevePage.listeKey), findsOneWidget);
      await monterTuteurFi(
        tester,
        depart: Routes.tuteurFoyerRecharge,
        taille: _telephone,
      );
      expect(
        tester.getTopLeft(find.byKey(RechargeFoyerPage.montantDe(_mariam))).dy,
        greaterThanOrEqualTo(
          tester
              .getBottomLeft(find.byKey(RechargeFoyerPage.caseDe(_mariam)))
              .dy,
        ),
      );
      debugPrint(mesures.join('\n'));
    });

    testWidgets('10. un impaye ne ferme pas le compte : chaque espace du '
        'tuteur reste ouvert, l acces a regulariser se dit', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterTuteurFi(tester);
      for (final String chemin in <String>[
        Routes.tuteurAccueil,
        Routes.tuteurFoyer,
        Routes.tuteurClasses,
        Routes.tuteurCompte,
        Routes.ficheElevePour(_ibrahim),
        Routes.ficheEleveSousPage(_ibrahim, 'finances'),
        Routes.ficheEleveSousPage(_ibrahim, 'mouvements'),
        Routes.ficheEleveSousPage(_ibrahim, 'acces'),
        Routes.compteTuteurSousPage('paiements'),
      ]) {
        routeur.go(chemin);
        await stabiliser(tester);
        expect(cheminFi(routeur), chemin, reason: chemin);
        expect(tester.takeException(), isNull, reason: chemin);
      }
      // La fiche Finances d'Ibrahim le dit, et propose la recharge.
      routeur.go(Routes.ficheEleveSousPage(_ibrahim, 'finances'));
      await stabiliser(tester);
      expect(find.byKey(FinancesElevePage.bandeauKey), findsOneWidget);
      expect(find.byKey(FinancesElevePage.rechargerKey), findsOneWidget);
    });

    testWidgets('10 bis. un impaye ne ferme pas le compte de l enfant : sur '
        'la vraie coquille de l eleve, Accueil, Ma classe, Coran et Mes '
        'groupes restent ouverts ; la seule copie neutre, aucune finance lue', (
      WidgetTester tester,
    ) async {
      final PaiementsEspionFi espion = PaiementsEspionFi(
        JeuFoyerFinance.unARegulariser,
      );
      final GoRouter routeur = await monterEleveFi(
        tester,
        Routes.eleve,
        profilId: _ibrahim,
        seances: <Seance>[_coursEnDirect(_ibrahim)],
        surcharges: <Override>[
          // L'acces de l'enfant, borne a sa session (FI-BR-08, R4-02).
          portMonAccesProvider.overrideWithValue(
            const MonAccesFinanceDemo(JeuFoyerFinance.unARegulariser, _ibrahim),
          ),
          portPaiementsFoyerProvider.overrideWithValue(espion),
        ],
      );
      // Le cas : Ibrahim n'a pas de periode financee, ses seances sont
      // fermees.
      expect(
        ouvertureSeances(
          DonneesFinanceDemo.acces(JeuFoyerFinance.unARegulariser)
              .firstWhere((AccesBeneficiaire a) => a.eleveId == _ibrahim),
        ),
        OuvertureSeances.fermees,
      );
      for (final (String chemin, Type page) in <(String, Type)>[
        (Routes.eleve, AccueilElevePage),
        (Routes.eleveSuivi, SuiviElevePage),
        (Routes.eleveCoran, MushafPage),
        (Routes.tcGroupes, MesGroupesPage),
      ]) {
        routeur.go(chemin);
        await stabiliser(tester);
        expect(cheminFi(routeur), chemin, reason: chemin);
        expect(find.byType(page), findsOneWidget, reason: chemin);
        // Les trois destinations de la coquille gardent leur navigation ;
        // Mes groupes est une route du Teaching Core, hors coquille.
        if (page != MesGroupesPage) {
          expect(find.byType(NavShell), findsOneWidget, reason: chemin);
        }
        expect(tester.takeException(), isNull, reason: chemin);
        if (page == AccueilElevePage || page == MesGroupesPage) {
          expect(
            find.byKey(BandeauAccesEnfant.cle),
            findsOneWidget,
            reason: chemin,
          );
        }
        _sansCauseFinanciere(tester, chemin);
      }
      expect(espion.lectures, isEmpty);
    });

    testWidgets('10 ter. un impaye ne ferme pas le compte de l adulte '
        'autonome : dans sa coquille, chaque destination reste ouverte ; '
        'Mon espace et Paiements disent le manque et proposent la recharge', (
      WidgetTester tester,
    ) async {
      String adresse(EcranDemoAdulte ecran) => adresseDemoAdulte(
        ecran,
        etat: EtatDemoAdulte.adulteSeul,
        financeARegulariser: true,
      );
      final FinancesProfil impaye = DonneesFinanceDemo.financesAdulte(
        profilId: DonneesAdulteDemo.mamadouId,
        prenom: 'Mamadou',
        aRegulariser: true,
      );
      expect(impaye.etat, EtatFinancier.aRegulariser);
      final String manque = messageRegularisation(impaye);
      for (final (EcranDemoAdulte ecran, Finder page)
          in <(EcranDemoAdulte, Finder)>[
            (EcranDemoAdulte.accueil, find.byType(AccueilAdultePage)),
            (EcranDemoAdulte.maClasse, find.byType(MaClasseAdultePage)),
            (EcranDemoAdulte.coran, find.text(t.adulte.provisoire.coran)),
            (EcranDemoAdulte.monEspace, find.byType(MonEspaceAdultePage)),
            (EcranDemoAdulte.paiements, find.byType(MesFinancesPage)),
            (EcranDemoAdulte.mesMouvements, find.byType(MesMouvementsPage)),
            (EcranDemoAdulte.maRecharge, find.byType(RechargeFoyerPage)),
          ]) {
        await monterAdulteFi(tester, adresse(ecran));
        expect(page, findsOneWidget, reason: ecran.name);
        expect(find.byType(NavShell), findsOneWidget, reason: ecran.name);
        expect(tester.takeException(), isNull, reason: ecran.name);
        switch (ecran) {
          case EcranDemoAdulte.monEspace:
            expect(find.byKey(BandeauRegularisation.cle), findsOneWidget);
            expect(find.text(manque), findsOneWidget);
          case EcranDemoAdulte.paiements:
            expect(find.byKey(FinancesElevePage.bandeauKey), findsOneWidget);
            expect(find.byKey(FinancesElevePage.rechargerKey), findsOneWidget);
          case EcranDemoAdulte.maRecharge:
            expect(
              tester
                  .widget<RechargeFoyerPage>(find.byType(RechargeFoyerPage))
                  .preselection,
              <String>{DonneesAdulteDemo.mamadouId},
            );
          default:
        }
      }
    });

    test('11. Rejoindre ne depend pas du solde (garde de source durcie ; le '
        'comportement depuis la vraie coquille : 11 bis)', () {
      final File acces = File('lib/features/acces_finance/acces_finance.dart');
      final List<String> lectures = <String>[
        for (final (int n, String l) in _lignesDeCode(acces))
          if (RegExp(r'\bsolde|balance', caseSensitive: false).hasMatch(l))
            '${acces.path}:$n',
      ];
      expect(lectures, isEmpty);
      // Toute comparaison d'un solde a zero, dans un sens ou dans l'autre,
      // par un operateur, une methode ou un `Montant(0...)`.
      final RegExp comparaison = RegExp(
        r'(solde|balance)\w*(\.mineur)?\s*(>|>=|<|<=|!=|==)\s*'
        r'(-?0\b|Montant\(\s*0\b|const\s+Montant\(\s*0\b)'
        r'|(-?\b0|Montant\(\s*0[^)]*\))\s*(<|<=|>|>=|!=|==)\s*[\w.]*'
        r'(solde|balance)'
        r'|(solde|balance)\w*(\.mineur)?\.(isPositive|isNegative|sign\b|'
        r'compareTo\()',
        caseSensitive: false,
      );
      // Contre-epreuve : la garde voit chaque ecriture.
      for (final String ligne in <String>[
        'if (solde > 0)',
        'p.solde.mineur >= 0',
        'finance.solde.mineur != 0',
        'solde > Montant(0, devise)',
        'solde > const Montant(0, devise)',
        '0 < p.solde.mineur',
        '0 <= solde',
        'Montant(0, d) < finance.solde',
        'solde.mineur.isNegative',
        'p.solde.isPositive',
        'solde.compareTo(zero) > 0',
        'balance > 0',
      ]) {
        expect(comparaison.hasMatch(ligne), isTrue, reason: ligne);
      }
      for (final String ligne in <String>[
        'formaterMontant(p.solde)',
        'solde: usd(0)',
        'Montant(solde.mineur + part.mineur, devise)',
        'soldeAttribue: texte',
        'seancesPayantesOuvertes ?? false',
      ]) {
        expect(comparaison.hasMatch(ligne), isFalse, reason: ligne);
      }
      final List<String> fautes = <String>[
        for (final File f in _sources('lib'))
          for (final (int n, String l) in _lignesDeCode(f))
            if (comparaison.hasMatch(l)) '${f.path}:$n',
      ];
      expect(fautes, isEmpty);
    });

    testWidgets('11 bis. Rejoindre depuis la vraie coquille de l eleve : '
        'Ibrahim a 0 et son mois finance, Rejoindre actif ; Ibrahim a 42 et '
        'son mois non finance, Rejoindre ferme ; le solde n est jamais lu', (
      WidgetTester tester,
    ) async {
      for (final (JeuFoyerFinance jeu, int solde, bool ouvert)
          in <(JeuFoyerFinance, int, bool)>[
            (JeuFoyerFinance.tousFinances, 0, true),
            (JeuFoyerFinance.unARegulariser, 4200, false),
          ]) {
        final FinancesProfil ibrahim = DonneesFinanceDemo.profils(jeu)
            .firstWhere((FinancesProfil p) => p.profilId == _ibrahim);
        // Le cas du refus : le solde et la periode vont en sens contraire.
        expect(ibrahim.solde.mineur, solde, reason: jeu.name);
        expect(ibrahim.periode != null, ouvert, reason: jeu.name);
        final PaiementsEspionFi espion = PaiementsEspionFi(jeu);
        final GoRouter routeur = await monterEleveFi(
          tester,
          Routes.eleve,
          profilId: _ibrahim,
          seances: <Seance>[_coursEnDirect(_ibrahim)],
          surcharges: <Override>[
            // L'acces de l'enfant, borne a sa session (FI-BR-08, R4-02).
            portMonAccesProvider.overrideWithValue(
              MonAccesFinanceDemo(jeu, _ibrahim),
            ),
            portPaiementsFoyerProvider.overrideWithValue(espion),
          ],
        );
        // Accueil : le cours en direct.
        final Finder rejoindre = find.byWidgetPredicate(
          (Widget w) =>
              w is ActionPrincipale && w.libelle == t.eleve.accueil.rejoindre,
        );
        if (ouvert) {
          expect(rejoindre, findsOneWidget, reason: jeu.name);
          expect(
            tester.widget<ActionPrincipale>(rejoindre).onPress,
            isNotNull,
            reason: jeu.name,
          );
          expect(find.byKey(BandeauAccesEnfant.cle), findsNothing);
        } else {
          expect(rejoindre, findsNothing, reason: jeu.name);
          expect(find.byKey(BandeauAccesEnfant.cle), findsOneWidget);
        }
        // Mes groupes : Rejoindre sur chaque carte ouverte, retire sinon.
        // (La route ne branche pas encore l'entree en salle, `BilletSalle` :
        // le bouton y est present et inerte quel que soit l'acces.)
        routeur.go(Routes.tcGroupes);
        await stabiliser(tester);
        final Finder rejoindreGroupe = find.widgetWithText(
          ActionPrincipale,
          LibellesGroupe.rejoindre,
        );
        expect(
          rejoindreGroupe,
          ouvert ? findsWidgets : findsNothing,
          reason: jeu.name,
        );
        expect(
          find.byKey(BandeauAccesEnfant.cle),
          ouvert ? findsNothing : findsOneWidget,
          reason: jeu.name,
        );
        expect(espion.lectures, isEmpty, reason: jeu.name);
      }
    });

    test('12. aucune confirmation de paiement simulee (garde de source ; le '
        'parcours : resultat_recharge_test.dart, « parcours de '
        'demonstration... le succes vient du port »)', () {
      final List<String> suivis = <String>[];
      for (final File f in _sources('lib')) {
        for (final (int n, String l) in _lignesDeCode(f)) {
          if (l.contains('SuiviPaiement(') &&
              !l.contains('const SuiviPaiement({')) {
            suivis.add('${f.path}:$n');
          }
        }
      }
      // Seule la demonstration rend un suivi ; aucun ecran n'en fabrique.
      expect(
        suivis.where((String s) => !s.startsWith('lib/features/demo/')),
        isEmpty,
      );
      // La recharge ne conclut rien : elle ne lit ni n'ecrit un etat final.
      final String recharge = <String>[
        for (final (int _, String l) in _lignesDeCode(
          File('lib/features/foyer/recharge_foyer.dart'),
        ))
          l,
      ].join('\n');
      expect(recharge.contains('EtatPaiement.'), isFalse);
      expect(recharge.contains('termine'), isFalse);
    });

    test('13. aucun ancien montant 20/26, 10/20 ou 5/10 (garde de source)', () {
      for (final String ligne in <String>[
        "Text('20 USD')",
        "'26 \\\$'",
        "'paie 20/26'",
        "'bonus 10/20'",
        "'remise 5/10'",
        'usd(26)',
        "Montant(2000, 'USD')",
      ]) {
        expect(_ancienMontant.hasMatch(ligne), isTrue, reason: ligne);
      }
      for (final String ligne in <String>[
        "'le 5/10/2026'",
        "'120 USD'",
        "'20,00 € (démonstration)'",
        'usd(-5)',
      ]) {
        expect(_ancienMontant.hasMatch(ligne), isFalse, reason: ligne);
      }
      final List<String> fautes = <String>[
        for (final File f in _sources('lib'))
          for (final (int n, String l) in _lignesDeCode(f))
            if (_ancienMontant.hasMatch(l)) '${f.path}:$n',
        for (final File f in Directory(
          'assets/i18n',
        ).listSync().whereType<File>())
          for (final (int n, String l) in _lignesDeCode(f))
            if (_ancienMontant.hasMatch(l)) '${f.path}:$n',
      ];
      expect(fautes, isEmpty);
    });

    test('14. FRONTEND ONLY : aucun fichier sous supabase/ modifie depuis la '
        'base de la voie (aebd21a5, a defaut le depart de la branche commune '
        'ou de ui/finance-v1), aucun nouveau, aucun en cours', () {
      final ({String? reference, List<String> essais}) base =
          _referenceBackend();
      final String? reference = base.reference;
      if (reference == null) {
        fail(
          'Aucune reference pour comparer supabase/ : ni $_baseFinance, ni '
          'une branche commune connue du clone. Recuperer l historique '
          '(git fetch --unshallow) ou la branche, puis relancer. Essais : '
          '${base.essais.join(' ; ')}',
        );
      }
      // Les commits de la voie, puis le travail en cours (index et arbre).
      for (final List<String> arguments in <List<String>>[
        <String>['diff', '--name-only', reference, 'HEAD', '--', 'supabase/'],
        <String>['diff', '--name-only', 'HEAD', '--', 'supabase/'],
        <String>['diff', '--name-only', '--cached', '--', 'supabase/'],
        <String>[
          'ls-files',
          '--others',
          '--exclude-standard',
          '--',
          'supabase/',
        ],
      ]) {
        final ProcessResult r = Process.runSync('git', arguments);
        expect(r.exitCode, 0, reason: '${arguments.join(' ')} : ${r.stderr}');
        expect(
          (r.stdout as String).trim(),
          isEmpty,
          reason: 'git ${arguments.join(' ')} (reference $reference)',
        );
      }
      // La reference precede bien la voie : aebd21a5 descend d'elle, ou
      // c'est elle.
      expect(
        Process.runSync('git', <String>[
          'merge-base',
          '--is-ancestor',
          reference,
          'HEAD',
        ]).exitCode,
        0,
        reason: reference,
      );
    });
  });

  // ---------------------------------------------------------------------
  // (c) La definition of done, §14, quand un test peut la mesurer
  // ---------------------------------------------------------------------
  //
  // Deja tenu ailleurs :
  // - recharge de un ou plusieurs profils dans le meme flux :
  //   recharge_multi_profils_test.dart (un profil, plusieurs, tous) ;
  // - resultat et etats intermediaires : resultat_recharge_test.dart (les
  //   huit etats) ;
  // - essai visible : foyer_finances_test.dart (« Essai : n/2 »),
  //   acces_finance_test.dart ;
  // - Revenus enseignant : revenus_enseignant_test.dart ; Admin Finance et
  //   Politiques : finance_domaine_test.dart, vue_globale_finance_test.dart,
  //   politiques_commerciales_test.dart ;
  // - responsive : refus 8 et 9 (dix ecrans mesures a 390 x 844 et
  //   1440 x 900 : colonnes, largeurs, navigation) ; clair et sombre, LTR et
  //   RTL, texte 200 % : les balayages de chaque fichier d'ecran ci-dessus ;
  // - « acces impaye visible sans desactiver le compte » : refus 10, 10 bis
  //   (enfant) et 10 ter (adulte autonome) ;
  // - « aucune valeur critique dans les widgets » : refus 7 et 13, et
  //   test/features/finance/finance_demo_test.dart (aucune valeur
  //   commerciale de la politique hors finance_demo.dart) ;
  // - « aucune fonction dupliquee » : refus 1.
  group('(c) definition of done §14', () {
    testWidgets('chaque ecran Finance du tuteur a sa route dans le routeur '
        'unique', (WidgetTester tester) async {
      final GoRouter routeur = await monterTuteurFi(tester);
      for (final (String chemin, Type ecran) in <(String, Type)>[
        (Routes.tuteurFoyer, FoyerPage),
        (Routes.ficheEleveSousPage(_mariam, 'finances'), FinancesElevePage),
        (Routes.tuteurFoyerRecharge, RechargeFoyerPage),
        (
          Routes.resultatRechargePour(
            DonneesFinanceDemo.commandeDemo(EtatPaiement.attenteConfirmation),
          ),
          ResultatRechargePage,
        ),
      ]) {
        routeur.go(chemin);
        await stabiliser(tester);
        expect(find.byType(ecran), findsOneWidget, reason: chemin);
      }
    });

    testWidgets('parametres commerciaux injectables : une politique a trois '
        'essais se lit « Essai : 1/3 » sans toucher a l ecran', (
      WidgetTester tester,
    ) async {
      final PolitiqueCommerciale l = DonneesFinanceDemo.politiqueLancement;
      final PolitiqueCommerciale troisEssais = PolitiqueCommerciale(
        version: 'recette-3-essais',
        statut: l.statut,
        dateEffet: l.dateEffet,
        tarifEnfant: l.tarifEnfant,
        tarifAdulte: l.tarifAdulte,
        essaisMax: 3,
        essaiActif: l.essaiActif,
        remisesParRang: l.remisesParRang,
        baseHoraire: l.baseHoraire,
        plafondHoraire: l.plafondHoraire,
        capaciteEnfant: l.capaciteEnfant,
        capaciteAdulte: l.capaciteAdulte,
        capaciteDebutant: l.capaciteDebutant,
        minimumOuverture: l.minimumOuverture,
        classesObjectif: l.classesObjectif,
        classesMax: l.classesMax,
        joursConservationPlace: l.joursConservationPlace,
        margeReferencePourMille: l.margeReferencePourMille,
        railsActifs: l.railsActifs,
        allocationInternet: l.allocationInternet,
      );
      await monterTuteurFi(
        tester,
        jeu: JeuFoyerFinance.unEnEssai,
        surcharges: <Override>[
          politiqueActiveProvider.overrideWith((Ref _) async => troisEssais),
        ],
      );
      final FinancesProfil essai = DonneesFinanceDemo.profils(
        JeuFoyerFinance.unEnEssai,
      ).firstWhere((FinancesProfil p) => p.etat == EtatFinancier.essai);
      expect(
        find.text(t.argent.etat.essaiCompte(n: essai.essaisUtilises!, max: 3)),
        findsOneWidget,
      );
      expect(
        find.text(
          t.argent.etat.essaiCompte(n: essai.essaisUtilises!, max: l.essaisMax),
        ),
        findsNothing,
      );
    });
  });
}
