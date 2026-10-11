// BACK-FRONT-REPRISE-1 : la file des reprises de foyer (administration), la
// date de redepot apres un refus et le foyer personnel a la sortie.
//
// Ce que le test prouve : les cinq etats et le port absent ; valider et
// refuser passent par une confirmation, et la liste est relue ; une demande
// non decidable n'a pas de bouton, sa raison la remplace ; une demande deja
// traitee n'est pas une panne ; une coupure laisse la decision « non
// confirmee » et la meme cle sert a la nouvelle tentative ; la date de redepot
// n'est dite que si le serveur la rend ; le foyer personnel n'est dit que si le
// serveur l'a cree ; 320 px, texte x2, LTR et RTL.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/foyer/port_reprises_admin.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_reprises/reprises_page.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/garde_interface.dart';
import '../../support/monter_recrutement.dart';

class _Port implements PortReprisesAdmin {
  _Port(
    this.reprises, {
    this.resultat = const RepriseDecidee(),
    this.coupures = 0,
  });

  final List<RepriseAdmin> reprises;
  ResultatDecisionReprise resultat;
  int coupures;
  final List<(String, bool, String)> appels = <(String, bool, String)>[];
  Completer<List<RepriseAdmin>>? retenue;
  bool echecLecture = false;
  final Set<String> decidees = <String>{};

  @override
  Future<List<RepriseAdmin>> lister() {
    if (retenue != null) return retenue!.future;
    if (echecLecture) return Future<List<RepriseAdmin>>.error('x');
    return Future<List<RepriseAdmin>>.value(
      reprises.where((RepriseAdmin r) => !decidees.contains(r.id)).toList(),
    );
  }

  @override
  Future<ResultatDecisionReprise> decider({
    required String repriseId,
    required bool approuver,
    required String cle,
  }) async {
    appels.add((repriseId, approuver, cle));
    if (coupures > 0) {
      coupures--;
      return const RepriseDecisionEchecReseau();
    }
    if (resultat is RepriseDecidee) decidees.add(repriseId);
    return resultat;
  }
}

final List<RepriseAdmin> _deux = <RepriseAdmin>[
  RepriseAdmin(
    id: 'r1',
    demandeurPrenom: 'Mariama',
    demandeurNom: 'Diallo',
    foyerNom: 'Foyer Diallo',
    etat: EtatRepriseAdmin.aExaminer,
    decidable: true,
    deposeeLe: DateTime(2026, 9, 29, 10),
  ),
  RepriseAdmin(
    id: 'r2',
    demandeurPrenom: 'Omar',
    demandeurNom: 'Haddad',
    foyerNom: 'Foyer Haddad',
    etat: EtatRepriseAdmin.refuseeParTitulaire,
    decidable: false,
    deposeeLe: DateTime(2026, 10, 1, 8),
  ),
];

Future<void> _monter(
  WidgetTester tester,
  PortReprisesAdmin? port, {
  bool horsLigne = false,
  double largeur = 390,
  double echelle = 1,
  TextDirection? direction,
}) => monterRecrutement(
  tester,
  chemin: '/admin/personnes/reprises',
  ecran: (_) => const ReprisesPage(),
  autres: <String>[
    '/admin/personnes/dossiers',
    '/admin/personnes/comptes',
    '/admin/personnes/invitations',
  ],
  surcharges: <Override>[
    if (port != null) portReprisesAdminProvider.overrideWithValue(port),
  ],
  horsLigne: horsLigne,
  largeur: largeur,
  echelle: echelle,
  direction: direction,
);

Finder _confirmer(String libelle) => find.text(libelle).last;

void main() {
  final a = t.reprisesAdmin;

  testWidgets('contenu : qui, quel foyer, boutons seulement si decidable', (
    tester,
  ) async {
    await _monter(tester, _Port(_deux));
    expect(find.text('Mariama Diallo'), findsOneWidget);
    expect(find.text('Omar Haddad'), findsOneWidget);
    expect(find.text(a.valider), findsOneWidget);
    expect(find.text(a.refuser), findsOneWidget);
    // La demande refusee par le titulaire : la raison, pas de bouton.
    expect(
      find.byKey(const ValueKey<String>('reprise-raison-r2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('reprise-valider-r2')),
      findsNothing,
    );
    verifierUnSeulBoutonPlein(tester);
  });

  testWidgets('chargement', (tester) async {
    final _Port p = _Port(_deux)..retenue = Completer<List<RepriseAdmin>>();
    await _monter(tester, p);
    expect(find.byType(Skeleton), findsWidgets);
  });

  testWidgets('vide', (tester) async {
    await _monter(tester, _Port(const <RepriseAdmin>[]));
    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('port absent : disponible au branchement serveur', (
    tester,
  ) async {
    await _monter(tester, null);
    expect(
      find.byKey(const ValueKey<String>('reprises-indisponible')),
      findsOneWidget,
    );
    expect(find.text(a.indisponiblePhrase), findsOneWidget);
  });

  testWidgets('erreur et hors ligne', (tester) async {
    await _monter(tester, _Port(_deux)..echecLecture = true);
    expect(find.byType(EtatSysteme), findsOneWidget);
    expect(find.text(a.erreur), findsOneWidget);
  });

  testWidgets('hors ligne sans donnees', (tester) async {
    await _monter(tester, _Port(_deux)..echecLecture = true, horsLigne: true);
    expect(
      find.byKey(const ValueKey<String>('reprises-sans-donnees')),
      findsOneWidget,
    );
  });

  testWidgets('valider : confirmation, puis liste relue', (tester) async {
    final _Port p = _Port(_deux);
    await _monter(tester, p);
    await tester.tap(find.text(a.valider));
    await laisser(tester);
    expect(find.text(a.validerConsequence), findsOneWidget);
    expect(p.appels, isEmpty);
    await tester.tap(_confirmer(a.valider));
    await laisser(tester);
    expect(p.appels.single.$1, 'r1');
    expect(p.appels.single.$2, isTrue);
    expect(find.text(a.validee), findsOneWidget);
    expect(find.text('Mariama Diallo'), findsNothing);
  });

  testWidgets('refuser : confirmation, puis liste relue', (tester) async {
    final _Port p = _Port(_deux);
    await _monter(tester, p);
    await tester.tap(find.text(a.refuser));
    await laisser(tester);
    expect(find.text(a.refuserConsequence), findsOneWidget);
    await tester.tap(_confirmer(a.refuser));
    await laisser(tester);
    expect(p.appels.single.$2, isFalse);
    expect(find.text(a.refusee), findsOneWidget);
  });

  testWidgets('renoncer a la confirmation : rien ne part', (tester) async {
    final _Port p = _Port(_deux);
    await _monter(tester, p);
    await tester.tap(find.text(a.valider));
    await laisser(tester);
    await tester.tap(find.text(t.commun.annuler).last);
    await laisser(tester);
    expect(p.appels, isEmpty);
  });

  testWidgets('deja traitee : ni panne ni erreur', (tester) async {
    final _Port p = _Port(_deux, resultat: const RepriseDejaTraitee());
    await _monter(tester, p);
    await tester.tap(find.text(a.valider));
    await laisser(tester);
    await tester.tap(_confirmer(a.valider));
    await laisser(tester);
    expect(find.text(a.dejaTraitee), findsOneWidget);
    expect(find.text(a.echecReseau), findsNothing);
  });

  testWidgets('coupure : non confirmee, meme cle a la nouvelle tentative', (
    tester,
  ) async {
    final _Port p = _Port(_deux, coupures: 1);
    await _monter(tester, p);
    await tester.tap(find.text(a.valider));
    await laisser(tester);
    await tester.tap(_confirmer(a.valider));
    await laisser(tester);
    expect(find.byKey(const ValueKey<String>('reprises-echec')), findsOne);
    expect(find.text(a.echecReseau), findsOneWidget);
    // Nouvelle tentative : la meme cle repart.
    await tester.tap(find.text(a.valider));
    await laisser(tester);
    await tester.tap(_confirmer(a.valider));
    await laisser(tester);
    expect(p.appels, hasLength(2));
    expect(p.appels[0].$3, p.appels[1].$3);
  });

  group('gabarits', () {
    setUpAll(chargerPolicesDuDepot);
    for (final TextDirection d in TextDirection.values) {
      testWidgets('320 px, texte x2, ${d.name}', (tester) async {
        await _monter(
          tester,
          _Port(_deux),
          largeur: 320,
          echelle: 2,
          direction: d,
        );
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester);
      });
    }
  });

  group('redepot et foyer personnel', () {
    for (final DateTime? redepot in <DateTime?>[DateTime(2026, 11, 15), null]) {
      testWidgets(
        'refus : date de redepot ${redepot == null ? "absente" : "rendue"}',
        (tester) async {
          await monterRecrutement(
            tester,
            chemin: '/reprise',
            ecran: (_) => RepriseFoyerPage(onRetour: () {}, onDeposee: () {}),
            surcharges: <Override>[
              repriseFoyerProvider.overrideWith(
                (Ref _) async => RepriseDemande(
                  statut: StatutReprise.refuseeParTitulaire,
                  deposeeLe: DateTime(2026, 9, 29, 10),
                  redepotPossibleLe: redepot,
                ),
              ),
            ],
          );
          expect(
            find.byKey(const ValueKey<String>('reprise-redepot')),
            redepot == null ? findsNothing : findsOneWidget,
          );
          expect(find.byKey(RepriseFoyerPage.deposerKey), findsNothing);
        },
      );
    }

    for (final bool cree in <bool>[true, false]) {
      testWidgets('sortie : foyer personnel dit seulement s\'il est cree '
          '($cree)', (tester) async {
        await monterRecrutement(
          tester,
          chemin: '/sortie',
          ecran: (_) => PlaceConjointPage(
            placeFeminine: true,
            prenom: 'Mariama',
            onRetour: () {},
            onCompris: () {},
          ),
          surcharges: <Override>[
            portSortieForfaitProvider.overrideWithValue(_Sortie(cree)),
          ],
        );
        await tester.tap(find.byKey(PlaceConjointPage.retirerKey));
        await laisser(tester);
        await tester.tap(find.text(t.adulte.sortie.retirerElle).last);
        await laisser(tester);
        expect(find.byKey(sortieResultatKey), findsOneWidget);
        expect(
          find.textContaining(t.adulte.sortie.foyerPersonnel),
          cree ? findsOneWidget : findsNothing,
        );
      });
    }
  });
}

class _Sortie implements PortSortieForfait {
  _Sortie(this.cree);

  final bool cree;

  @override
  Future<ResultatSortie> retirerSecondAdulte({required String cle}) async =>
      SortieFaite(foyerPersonnelCree: cree);

  @override
  Future<ResultatSortie> quitterForfait({required String cle}) async =>
      SortieFaite(foyerPersonnelCree: cree);
}
