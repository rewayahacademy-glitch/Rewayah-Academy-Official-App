// CPT-ENC-1 : W05 Encaissements (spec §24, §33, §45 ; M02 ecran 2).
//
// - filtres §33 et leurs compteurs, filtre d'adresse `?filtre=`, recherche ;
// - montants masques par defaut, revelees par la bascule (R-FIN-01, 02) ;
// - 1440 : tableau §24.2 et panneau detail §33 (brut, frais, net, reference,
//   prestataire, foyer, affectation, rapprochement, journal) ;
// - sous 1200 : cartes, la carte ouvre la page detail ;
// - « Confirme » seulement si la source le rend (§24.3) ;
// - cinq etats (chargement, contenu, vide, erreur, hors ligne) et « en
//   preparation » sans source ;
// - 320 texte x2, sombre, RTL : aucun debordement.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_encaissements.dart';
import 'package:rewayah_academy/core/comptable/modeles_comptable.dart';
import 'package:rewayah_academy/core/comptable/statuts_comptable.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/bascule_montants.dart';
import 'package:rewayah_academy/core/widgets/data_collection.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/montant_sensible.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/comptable/encaissements/detail_encaissement_page.dart';
import 'package:rewayah_academy/features/comptable/encaissements/donnees_encaissements.dart';
import 'package:rewayah_academy/features/comptable/encaissements/encaissements_page.dart';
import 'package:rewayah_academy/features/demo/comptable/encaissements_demo.dart';

import '../../../support/rangee_plus.dart';
import 'support_encaissements.dart';

List<Override> _demo() => <Override>[
  portEncaissementsProvider.overrideWithValue(EncaissementsDemo()),
];

/// Un port de test : la liste rendue par [liste], ou l'echec [erreur].
class _Port extends EncaissementsDemo {
  _Port({this.liste_, this.erreur, this.attente});

  final List<Encaissement>? liste_;
  final Object? erreur;
  final Completer<List<Encaissement>>? attente;
  int lectures = 0;

  @override
  Future<List<Encaissement>> liste(FiltreEncaissements filtre) {
    lectures++;
    final Completer<List<Encaissement>>? a = attente;
    if (a != null) return a.future;
    final Object? e = erreur;
    if (e != null) return Future<List<Encaissement>>.error(e);
    return Future<List<Encaissement>>.value(
      liste_ ?? DonneesEncaissementsDemo.encaissements(),
    );
  }
}

Encaissement _enc(String id) => DonneesEncaissementsDemo.encaissements()
    .firstWhere((Encaissement e) => e.id == id);

int _compteur(WidgetTester tester, FiltreListeEncaissements f) {
  final Finder pilule = find.byKey(EncaissementsPage.filtreKey(f));
  expect(pilule, findsOneWidget);
  return tester
      .widgetList<Text>(
        find.descendant(of: pilule, matching: find.byType(Text)),
      )
      .map((Text x) => int.tryParse(x.data ?? ''))
      .whereType<int>()
      .single;
}

void main() {
  final List<Encaissement> demo = DonneesEncaissementsDemo.encaissements();

  group('W05 a 1440 : tableau, filtres, recherche', () {
    testWidgets('tableau §24.2 : les six familles, montants masques', (
      WidgetTester tester,
    ) async {
      await monterEncaissements(
        tester,
        Routes.comptableEncaissements,
        surcharges: _demo(),
        // Le tableau ne construit que les lignes visibles : assez haut
        // pour les six.
        taille: const Size(1440, 1600),
      );
      expect(find.byType(DataCollection<Encaissement>), findsOneWidget);
      final e = t.comptable.encaissements;
      for (final String colonne in <String>[
        e.colDate,
        e.colFamille,
        e.colReference,
        e.colBrut,
        e.colFrais,
        e.colNet,
        e.colMoyen,
        e.colEtat,
      ]) {
        expect(find.text(colonne), findsOneWidget, reason: colonne);
      }
      for (final Encaissement x in demo) {
        expect(find.text(x.famille), findsOneWidget, reason: x.famille);
        expect(find.text(x.reference), findsOneWidget);
        // Masques : aucun chiffre de montant (R-FIN-01).
        expect(find.text(formaterMontant(x.brut)), findsNothing);
      }
      expect(find.byType(MontantSensible), findsNWidgets(demo.length * 3));
      expect(find.text(MontantSensible.masquePour('USD')), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('la bascule revele les montants exacts (R-FIN-02)', (
      WidgetTester tester,
    ) async {
      await monterEncaissements(
        tester,
        Routes.comptableEncaissements,
        surcharges: _demo(),
      );
      await tester.tap(find.byKey(BasculeMontants.cleBouton));
      await tester.pumpAndSettle();
      final Encaissement bah = _enc(DonneesEncaissementsDemo.encConfirme);
      expect(find.text(formaterMontant(bah.brut)), findsWidgets);
      expect(find.text(formaterMontant(bah.frais)), findsWidgets);
      expect(find.text(formaterMontant(bah.net)), findsWidgets);
      expect(find.text(MontantSensible.masquePour('USD')), findsNothing);
    });

    testWidgets('filtres §33 : compteurs de lignes, jamais de montant', (
      WidgetTester tester,
    ) async {
      await monterEncaissements(
        tester,
        Routes.comptableEncaissements,
        surcharges: _demo(),
      );
      expect(_compteur(tester, FiltreListeEncaissements.tous), 6);
      expect(_compteur(tester, FiltreListeEncaissements.confirmes), 2);
      expect(_compteur(tester, FiltreListeEncaissements.enAttente), 1);
      expect(_compteur(tester, FiltreListeEncaissements.echoues), 1);
      expect(_compteur(tester, FiltreListeEncaissements.rembourses), 1);
      expect(_compteur(tester, FiltreListeEncaissements.contestes), 1);
      expect(_compteur(tester, FiltreListeEncaissements.aRapprocher), 1);

      // L4-07 : « Echoues » est rangee sous « Plus ».
      await toucherFiltre(
        tester,
        find.byKey(
          EncaissementsPage.filtreKey(FiltreListeEncaissements.echoues),
        ),
      );
      expect(find.text('Famille Camara'), findsOneWidget);
      expect(find.text('Famille Bah'), findsNothing);
    });

    test('filtre d adresse : valeur brute, inconnue = Tous', () {
      expect(
        FiltreListeEncaissements.depuis('attente'),
        FiltreListeEncaissements.enAttente,
      );
      expect(
        FiltreListeEncaissements.depuis('n-importe'),
        FiltreListeEncaissements.tous,
      );
      expect(
        FiltreListeEncaissements.depuis(null),
        FiltreListeEncaissements.tous,
      );
      // « Rembourses » couvre le total et le partiel, « Contestes » le
      // chargeback ; « Confirmes » tout ce que le prestataire a confirme.
      expect(
        FiltreListeEncaissements.rembourses.retient(
          EtatEncaissement.partiellementRembourse,
        ),
        isTrue,
      );
      expect(
        FiltreListeEncaissements.contestes.retient(EtatEncaissement.chargeback),
        isTrue,
      );
      expect(
        FiltreListeEncaissements.confirmes.retient(EtatEncaissement.enAttente),
        isFalse,
      );
      for (final FiltreListeEncaissements f
          in FiltreListeEncaissements.values) {
        expect(
          Routes.comptableEncaissementsFiltres(filtre: f.valeur),
          f.valeur == null
              ? Routes.comptableEncaissements
              : '${Routes.comptableEncaissements}?filtre=${f.valeur}',
        );
      }
    });

    testWidgets('?filtre=attente ouvre la liste deja filtree', (
      WidgetTester tester,
    ) async {
      await monterEncaissements(
        tester,
        Routes.comptableEncaissementsFiltres(filtre: 'attente'),
        surcharges: _demo(),
      );
      expect(find.text('Famille Sylla'), findsOneWidget);
      expect(find.text('Famille Bah'), findsNothing);
    });

    testWidgets('recherche famille ou reference ; aucun resultat : la phrase '
        'et « Voir tous les encaissements »', (WidgetTester tester) async {
      await monterEncaissements(
        tester,
        Routes.comptableEncaissements,
        surcharges: _demo(),
        // Le tableau ne construit que les lignes visibles : assez haut
        // pour les six.
        taille: const Size(1440, 1600),
      );
      await tester.enterText(
        find.byKey(EncaissementsPage.rechercheKey),
        '7955',
      );
      await tester.pumpAndSettle();
      expect(find.text('Famille Keita'), findsOneWidget);
      expect(find.text('Famille Bah'), findsNothing);
      await tester.enterText(
        find.byKey(EncaissementsPage.rechercheKey),
        'touré',
      );
      await tester.pumpAndSettle();
      expect(find.text('Famille Touré'), findsOneWidget);
      await tester.enterText(find.byKey(EncaissementsPage.rechercheKey), 'zzz');
      await tester.pumpAndSettle();
      final e = t.comptable.encaissements;
      expect(find.text(e.videFiltreTitre), findsOneWidget);
      await tester.tap(find.text(e.voirTous));
      await tester.pumpAndSettle();
      expect(find.text('Famille Bah'), findsOneWidget);
      expect(find.text('Famille Touré'), findsOneWidget);
    });
  });

  group('W05 a 1440 : panneau detail §33', () {
    testWidgets('une ligne ouvre le panneau : brut, frais, net, reference, '
        'prestataire, foyer, affectation, rapprochement, journal', (
      WidgetTester tester,
    ) async {
      await monterEncaissements(
        tester,
        Routes.comptableEncaissements,
        surcharges: _demo(),
        taille: const Size(1440, 1600),
      );
      expect(find.byKey(EncaissementsPage.panneauKey), findsNothing);
      await tester.tap(
        find.byKey(
          EncaissementsPage.ligneKey(DonneesEncaissementsDemo.encConfirme),
        ),
      );
      await tester.pumpAndSettle();
      final Finder panneau = find.byKey(EncaissementsPage.panneauKey);
      expect(panneau, findsOneWidget);
      final e = t.comptable.encaissements;
      Finder dans(String texte) =>
          find.descendant(of: panneau, matching: find.text(texte));
      for (final String libelle in <String>[
        e.brut,
        e.frais,
        e.net,
        e.reference,
        e.prestataire,
        e.foyer,
        e.affectation,
        e.rapprochement,
        e.journal,
        e.confirmeNote,
      ]) {
        expect(dans(libelle), findsOneWidget, reason: libelle);
      }
      final Encaissement bah = _enc(DonneesEncaissementsDemo.encConfirme);
      expect(dans(bah.reference), findsOneWidget);
      expect(dans(bah.prestataire), findsOneWidget);
      expect(dans('Amina'), findsOneWidget);
      expect(dans('Ibrahim'), findsOneWidget);
      // Le journal rendu par la source (§48), jamais invente.
      expect(dans('Paiement reçu de la Famille Bah'), findsOneWidget);
      // Le tableau garde ses colonnes essentielles.
      expect(find.text(e.colBrut), findsNothing);
      expect(find.text(e.colNet), findsOneWidget);
      // Aucun « Voir le recu » (UX_REVIEW §5.5).
      expect(find.textContaining('Voir le reçu'), findsNothing);
      // Fermer.
      await tester.tap(find.bySemanticsLabel(e.fermerDetail));
      await tester.pumpAndSettle();
      expect(panneau, findsNothing);
      expect(find.text(e.colBrut), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('« Confirme » seulement sur retour de la source (§24.3)', (
      WidgetTester tester,
    ) async {
      await monterEncaissements(
        tester,
        Routes.comptableEncaissements,
        surcharges: _demo(),
        taille: const Size(1440, 1600),
      );
      await tester.tap(
        find.byKey(
          EncaissementsPage.ligneKey(DonneesEncaissementsDemo.encEnAttente),
        ),
      );
      await tester.pumpAndSettle();
      final e = t.comptable.encaissements;
      expect(find.text(e.enAttenteNote), findsOneWidget);
      expect(find.text(e.confirmeNote), findsNothing);
      expect(
        find.text(t.comptable.statuts.encaissement.enAttente),
        findsWidgets,
      );
    });

    testWidgets('a rapprocher : le lien ouvre l espace de rapprochement', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterEncaissements(
        tester,
        Routes.comptableEncaissementPour(
          DonneesEncaissementsDemo.encARapprocher,
        ),
        surcharges: <Override>[
          ..._demo(),
          // Le rapprochement n'est pas l'objet de ce test : sans source.
        ],
        taille: const Size(390, 1600),
      );
      await tester.tap(
        find.text(t.comptable.encaissements.ouvrirRapprochement),
      );
      await tester.pumpAndSettle();
      expect(
        routeur.routerDelegate.currentConfiguration.uri.path,
        Routes.comptableRapprochement,
      );
    });
  });

  group('W05 sous 1200 : cartes et page detail (M02 ecran 2)', () {
    testWidgets('390 : des cartes, la carte ouvre la page detail, le retour '
        'ramene a la liste', (WidgetTester tester) async {
      final GoRouter routeur = await monterEncaissements(
        tester,
        Routes.comptableEncaissements,
        surcharges: _demo(),
        taille: const Size(390, 844),
      );
      expect(find.byType(DataCollection<Encaissement>), findsNothing);
      expect(find.text('Famille Bah'), findsOneWidget);
      await tester.tap(
        find.byKey(
          EncaissementsPage.ligneKey(DonneesEncaissementsDemo.encConfirme),
        ),
      );
      await tester.pumpAndSettle();
      // Empilee (`push`) : la page detail de l'encaissement choisi.
      final DetailEncaissementPage page = tester.widget(
        find.byType(DetailEncaissementPage),
      );
      expect(page.encaissementId, DonneesEncaissementsDemo.encConfirme);
      expect(routeur.canPop(), isTrue);
      await tester.tap(find.bySemanticsLabel(t.commun.entete.retour).first);
      await tester.pumpAndSettle();
      expect(find.byType(EncaissementsPage), findsOneWidget);
    });

    testWidgets('page detail : masquee par defaut, journal, aucune exception', (
      WidgetTester tester,
    ) async {
      await monterEncaissements(
        tester,
        Routes.comptableEncaissementPour(DonneesEncaissementsDemo.encConfirme),
        surcharges: _demo(),
        taille: const Size(390, 2400),
      );
      final Encaissement bah = _enc(DonneesEncaissementsDemo.encConfirme);
      expect(find.text(t.comptable.encaissements.detailTitre), findsOneWidget);
      expect(find.text(formaterMontant(bah.net)), findsNothing);
      expect(find.text('Relié à la mensualité d’octobre'), findsOneWidget);
      expect(find.byType(BasculeMontants), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('etats', () {
    testWidgets('chargement : le squelette, aucune ligne', (
      WidgetTester tester,
    ) async {
      final _Port port = _Port(attente: Completer<List<Encaissement>>());
      await monterEncaissements(
        tester,
        Routes.comptableEncaissements,
        surcharges: <Override>[
          portEncaissementsProvider.overrideWithValue(port),
        ],
        attendre: false,
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(Skeleton), findsWidgets);
      expect(find.text('Famille Bah'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('vide : l invitation, aucun filtre', (
      WidgetTester tester,
    ) async {
      await monterEncaissements(
        tester,
        Routes.comptableEncaissements,
        surcharges: <Override>[
          portEncaissementsProvider.overrideWithValue(
            _Port(liste_: const <Encaissement>[]),
          ),
        ],
      );
      expect(find.text(t.comptable.encaissements.videTitre), findsOneWidget);
      expect(find.byKey(EncaissementsPage.rechercheKey), findsNothing);
    });

    testWidgets('erreur : Reessayer relit', (WidgetTester tester) async {
      final _Port port = _Port(erreur: StateError('panne'));
      await monterEncaissements(
        tester,
        Routes.comptableEncaissements,
        surcharges: <Override>[
          portEncaissementsProvider.overrideWithValue(port),
        ],
      );
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is EtatSysteme && w.nature == NatureEtat.echecServeur,
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.text(EtatSysteme.libelleActionPar(NatureEtat.echecServeur)),
      );
      await tester.pumpAndSettle();
      expect(port.lectures, 2);
    });

    testWidgets('hors ligne : l echec se dit hors ligne', (
      WidgetTester tester,
    ) async {
      await monterEncaissements(
        tester,
        Routes.comptableEncaissements,
        surcharges: <Override>[
          portEncaissementsProvider.overrideWithValue(
            _Port(erreur: StateError('reseau')),
          ),
        ],
        horsLigne: true,
      );
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is EtatSysteme && w.nature == NatureEtat.horsLigne,
        ),
        findsOneWidget,
      );
    });

    testWidgets('production sans source : « en preparation », aucun chiffre', (
      WidgetTester tester,
    ) async {
      await monterEncaissements(tester, Routes.comptableEncaissements);
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(t.comptable.commun.enPreparationTitre), findsOneWidget);
      expect(find.byType(MontantSensible), findsNothing);
      await monterEncaissements(tester, Routes.comptableEncaissementPour('e1'));
      expect(find.text(t.comptable.commun.enPreparationTitre), findsOneWidget);
    });
  });

  group('320 texte x2, sombre, RTL', () {
    for (final (
          String nom,
          Size taille,
          double echelle,
          Brightness l,
          TextDirection s,
        )
        cas
        in <(String, Size, double, Brightness, TextDirection)>[
          (
            '320 x2',
            const Size(320, 900),
            2,
            Brightness.light,
            TextDirection.ltr,
          ),
          (
            '390 sombre RTL',
            const Size(390, 844),
            1,
            Brightness.dark,
            TextDirection.rtl,
          ),
          (
            '1440 x2',
            const Size(1440, 900),
            2,
            Brightness.light,
            TextDirection.ltr,
          ),
          (
            '1440 sombre RTL',
            const Size(1440, 900),
            1,
            Brightness.dark,
            TextDirection.rtl,
          ),
        ]) {
      testWidgets('liste et detail sans debordement : ${cas.$1}', (
        WidgetTester tester,
      ) async {
        await monterEncaissements(
          tester,
          Routes.comptableEncaissements,
          surcharges: _demo(),
          taille: cas.$2,
          echelle: cas.$3,
          luminosite: cas.$4,
          sens: cas.$5,
        );
        expect(tester.takeException(), isNull);
        await monterEncaissements(
          tester,
          Routes.comptableEncaissementPour(
            DonneesEncaissementsDemo.encConfirme,
          ),
          surcharges: _demo(),
          taille: cas.$2,
          echelle: cas.$3,
          luminosite: cas.$4,
          sens: cas.$5,
          montantsAffiches: true,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  test('la demonstration tient la spec §44 (3 encaissements au moins)', () {
    expect(demo.length, greaterThanOrEqualTo(3));
    // Un etat par filtre au moins, pour que chaque pilule mene quelque part.
    for (final FiltreListeEncaissements f in FiltreListeEncaissements.values) {
      expect(demo.where((Encaissement e) => f.retient(e.etat)), isNotEmpty);
    }
    // Le net arrive calcule par la source : aucun float, des entiers.
    for (final Encaissement e in demo) {
      expect(e.net.mineur, isA<int>());
      for (final AffectationProfil p in e.profils) {
        expect(p.montant.devise, e.brut.devise);
      }
    }
    expect(
      DonneesEncaissementsDemo.journal(DonneesEncaissementsDemo.encConfirme),
      isA<List<EntreeJournal>>(),
    );
  });
}
