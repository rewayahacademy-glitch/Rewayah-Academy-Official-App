// CPT-BEN-2 (FIN-L4b) : « Recevoir mes paiements ». R-FIN-13 (le
// beneficiaire lui-meme ajoute, remplace, supprime, choisit la preferee),
// R-FIN-19 (notice « Informations de paiement a completer » et « Configurer
// mes paiements »), aucune coordonnee : seul le jeton de la saisie securisee
// part au port ; la rubrique de Compte et la ligne du Profil n'apparaissent
// que si le port repond (capacite, jamais le role) ; cinq etats ; 320 a
// texte x2, 1440 sombre, RTL.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_mes_moyens_paiement.dart';
import 'package:rewayah_academy/core/comptable/statuts_comptable.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/demo/comptable/beneficiaires_demo.dart';
import 'package:rewayah_academy/features/paiements_recus/feuille_ajout_moyen.dart';
import 'package:rewayah_academy/features/paiements_recus/recevoir_paiements_page.dart';
import 'package:rewayah_academy/features/paiements_recus/rubrique_recevoir_paiements.dart';

import '../../capture/outil_capture.dart';
import '../../router/support_routeur.dart' show sessionActive;
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';
import '../../support/mots_coupes.dart';

/// La demo, qui retient chaque brouillon recu (aucun numero ne doit y etre).
class _Espion extends MesMoyensPaiementDemo {
  _Espion({super.depart});

  final List<BrouillonMoyenPaiement> brouillons = <BrouillonMoyenPaiement>[];

  @override
  Future<EtatMesMoyensPaiement> ajouter(BrouillonMoyenPaiement b) {
    brouillons.add(b);
    return super.ajouter(b);
  }

  @override
  Future<EtatMesMoyensPaiement> remplacer({
    required String moyenId,
    required BrouillonMoyenPaiement brouillon,
  }) {
    brouillons.add(brouillon);
    return super.remplacer(moyenId: moyenId, brouillon: brouillon);
  }
}

class _EnEchec extends MesMoyensPaiementDemo {
  _EnEchec({this.jamais = false});

  final bool jamais;

  @override
  Future<EtatMesMoyensPaiement> etat() => jamais
      ? Completer<EtatMesMoyensPaiement>().future
      : Future<EtatMesMoyensPaiement>.error(StateError('reseau'));
}

List<Override> _surcharges(
  PortMesMoyensPaiement port, {
  bool horsLigne = false,
}) => <Override>[
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(sessionActive(AppRole.accountant)),
  ),
  horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(horsLigne)),
  portMesMoyensPaiementProvider.overrideWithValue(port),
];

Future<void> _monter(
  WidgetTester tester,
  Widget page,
  PortMesMoyensPaiement port, {
  bool horsLigne = false,
  Size taille = const Size(390, 2000),
  double texte = 1,
  ThemeMode theme = ThemeMode.light,
  TextDirection sens = TextDirection.ltr,
}) async {
  fixerVueCapture(tester, taille, 1);
  // Un nouveau conteneur a chaque montage : un ProviderScope garde sinon
  // les surcharges du montage precedent (hors ligne, source).
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    hoteCapture(
      Directionality(textDirection: sens, child: page),
      surcharges: _surcharges(port, horsLigne: horsLigne),
      echelleTexte: texte,
      themeMode: theme,
    ),
  );
  await stabiliser(tester);
}

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await stabiliser(tester);
}

void main() {
  final r = t.comptable.beneficiaires.recevoir;

  group('Recevoir mes paiements', () {
    testWidgets('R-FIN-19 : aucun moyen, notice et « Configurer mes '
        'paiements »', (WidgetTester tester) async {
      await _monter(
        tester,
        const RecevoirPaiementsPage(),
        MesMoyensPaiementDemo(depart: MesMoyensPaiementDemo.aucun),
      );
      expect(find.byKey(RecevoirPaiementsPage.noticeKey), findsOneWidget);
      expect(find.text(r.notice), findsOneWidget);
      expect(find.text(r.phraseAucunMoyen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(RecevoirPaiementsPage.actionKey),
          matching: find.text(r.configurer),
        ),
        findsOneWidget,
      );
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('R-FIN-13 : j ajoute moi-meme, par la saisie securisee ; '
        'seul un jeton part au port', (WidgetTester tester) async {
      final _Espion port = _Espion(depart: MesMoyensPaiementDemo.aucun);
      await _monter(tester, const RecevoirPaiementsPage(), port);
      await _toucher(tester, find.byKey(RecevoirPaiementsPage.actionKey));
      expect(find.byType(CorpsAjoutMoyen), findsOneWidget);
      // Sans type : la feuille le dit.
      await _toucher(tester, find.byKey(CorpsAjoutMoyen.continuerKey));
      expect(find.text(r.typeRequis), findsOneWidget);
      await _toucher(
        tester,
        find.byKey(const ValueKey<String>('recevoir-type-Compte bancaire')),
      );
      await _toucher(tester, find.byKey(CorpsAjoutMoyen.continuerKey));
      expect(find.byType(CorpsAjoutMoyen), findsNothing);
      expect(port.brouillons, hasLength(1));
      final BrouillonMoyenPaiement b = port.brouillons.single;
      expect(b.type, 'Compte bancaire');
      expect(b.jetonSaisie, startsWith('jeton-demo-'));
      expect(find.text(r.ajoutee), findsOneWidget);
      expect(find.byKey(RecevoirPaiementsPage.noticeKey), findsNothing);
      expect(find.text(r.suspenduTemporairement), findsOneWidget);
      expect(find.text(r.phraseEnVerification), findsOneWidget);
      expect(find.text(r.preferee), findsOneWidget);
    });

    testWidgets('R-FIN-13 : remplacer garde l ancienne inactive, choisir la '
        'preferee, supprimer apres confirmation', (WidgetTester tester) async {
      final _Espion port = _Espion();
      await _monter(tester, const RecevoirPaiementsPage(), port);
      // Etat de depart : action requise, notice visible (R-FIN-19).
      expect(find.byKey(RecevoirPaiementsPage.noticeKey), findsOneWidget);
      await _toucher(
        tester,
        find.byKey(const ValueKey<String>('recevoir-remplacer-moy-1')),
      );
      await _toucher(
        tester,
        find.byKey(const ValueKey<String>('recevoir-type-Mobile money')),
      );
      await _toucher(tester, find.byKey(CorpsAjoutMoyen.continuerKey));
      expect(port.brouillons, hasLength(1));
      expect(find.text(r.remplacee), findsOneWidget);
      expect(find.text(r.inactive), findsOneWidget);
      // L'ancienne, inactive, ne se remplace plus ; elle se supprime.
      expect(
        find.byKey(const ValueKey<String>('recevoir-remplacer-moy-1')),
        findsNothing,
      );
      await _toucher(
        tester,
        find.byKey(const ValueKey<String>('recevoir-supprimer-moy-1')),
      );
      await _toucher(
        tester,
        find
            .text(r.supprimer(methode: 'Mobile money · Operateur A •••• 2718'))
            .last,
      );
      expect(find.text(r.supprimee), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('recevoir-moyen-moy-1')),
        findsNothing,
      );
    });

    testWidgets('choisir la methode preferee', (WidgetTester tester) async {
      final _Espion port = _Espion(depart: MesMoyensPaiementDemo.aucun);
      await _monter(tester, const RecevoirPaiementsPage(), port);
      for (final String type in <String>['Mobile money', 'Compte bancaire']) {
        await _toucher(tester, find.byKey(RecevoirPaiementsPage.actionKey));
        await _toucher(
          tester,
          find.byKey(ValueKey<String>('recevoir-type-$type')),
        );
        await _toucher(tester, find.byKey(CorpsAjoutMoyen.continuerKey));
      }
      final Finder lien = find.byWidgetPredicate(
        (Widget w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('recevoir-preferee-'),
      );
      expect(lien, findsOneWidget);
      await _toucher(tester, lien);
      expect(find.text(r.prefereeChoisie), findsOneWidget);
    });

    testWidgets('un changement indisponible le dit, avec quoi faire', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const RecevoirPaiementsPage(),
        _AjoutIndisponible(),
      );
      await _toucher(tester, find.byKey(RecevoirPaiementsPage.actionKey));
      await _toucher(
        tester,
        find.byKey(const ValueKey<String>('recevoir-type-Mobile money')),
      );
      await _toucher(tester, find.byKey(CorpsAjoutMoyen.continuerKey));
      expect(find.text(r.erreurIndisponible), findsOneWidget);
    });

    testWidgets('chargement, erreur, hors ligne, source absente', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const RecevoirPaiementsPage(),
        _EnEchec(jamais: true),
      );
      expect(find.byType(Skeleton), findsOneWidget);
      await _monter(tester, const RecevoirPaiementsPage(), _EnEchec());
      expect(
        tester.widget<EtatSysteme>(find.byType(EtatSysteme)).nature,
        NatureEtat.echecServeur,
      );
      await _monter(
        tester,
        const RecevoirPaiementsPage(),
        _EnEchec(),
        horsLigne: true,
      );
      expect(
        tester.widget<EtatSysteme>(find.byType(EtatSysteme)).nature,
        NatureEtat.horsLigne,
      );
      await _monter(
        tester,
        const RecevoirPaiementsPage(),
        const MesMoyensPaiementIndisponibles(),
      );
      expect(
        tester.widget<EtatSysteme>(find.byType(EtatSysteme)).nature,
        NatureEtat.indisponible,
      );
      expect(find.byKey(RecevoirPaiementsPage.actionKey), findsNothing);
    });

    testWidgets('les six etats §38 ont chacun leur phrase', (
      WidgetTester tester,
    ) async {
      for (final EtatProfilPaiement e in <EtatProfilPaiement>[
        EtatProfilPaiement.aucunMoyen,
        EtatProfilPaiement.incomplet,
        EtatProfilPaiement.enVerification,
        EtatProfilPaiement.verifie,
        EtatProfilPaiement.suspendu,
        EtatProfilPaiement.actionRequise,
      ]) {
        await _monter(
          tester,
          const RecevoirPaiementsPage(),
          MesMoyensPaiementDemo(
            depart: EtatMesMoyensPaiement(
              etat: e,
              corridorsProposes: MesMoyensPaiementDemo.types,
            ),
          ),
        );
        expect(find.byType(EtatSysteme), findsNothing, reason: e.name);
        expect(
          find.byKey(RecevoirPaiementsPage.noticeKey),
          <EtatProfilPaiement>{
                EtatProfilPaiement.aucunMoyen,
                EtatProfilPaiement.incomplet,
                EtatProfilPaiement.actionRequise,
              }.contains(e)
              ? findsOneWidget
              : findsNothing,
          reason: e.name,
        );
      }
    });
  });

  group('Rubrique de Compte et du Profil (capacite du port)', () {
    Widget page() => const Scaffold(
      body: SingleChildScrollView(child: RubriqueRecevoirPaiements()),
    );

    testWidgets('source absente : rien, aucun lien mort', (
      WidgetTester tester,
    ) async {
      await _monter(tester, page(), const MesMoyensPaiementIndisponibles());
      expect(find.byKey(RubriqueRecevoirPaiements.ligneKey), findsNothing);
      expect(find.text(r.titre), findsNothing);
    });

    testWidgets('source presente : la ligne, et la notice §27.1 quand il '
        'manque des informations', (WidgetTester tester) async {
      await _monter(
        tester,
        page(),
        MesMoyensPaiementDemo(depart: MesMoyensPaiementDemo.aucun),
      );
      expect(find.byKey(RubriqueRecevoirPaiements.ligneKey), findsOneWidget);
      expect(find.byKey(RubriqueRecevoirPaiements.noticeKey), findsOneWidget);
      expect(find.text(r.configurer), findsOneWidget);

      await _monter(
        tester,
        page(),
        MesMoyensPaiementDemo(
          depart: const EtatMesMoyensPaiement(etat: EtatProfilPaiement.verifie),
        ),
      );
      expect(find.byKey(RubriqueRecevoirPaiements.ligneKey), findsOneWidget);
      expect(find.byKey(RubriqueRecevoirPaiements.noticeKey), findsNothing);
    });
  });

  group('Garde d interface', () {
    // Les mesures de texte n'ont de sens qu'avec les vraies polices.
    setUpAll(chargerPolicesDuDepot);

    for (final ThemeMode theme in <ThemeMode>[
      ThemeMode.light,
      ThemeMode.dark,
    ]) {
      testWidgets('320 a texte x2, ${theme.name}', (WidgetTester tester) async {
        await _monter(
          tester,
          const RecevoirPaiementsPage(),
          MesMoyensPaiementDemo(),
          taille: const Size(320, 4000),
          texte: 2,
          theme: theme,
        );
        expect(tester.takeException(), isNull);
        expect(motsCoupes(tester, find.byType(RecevoirPaiementsPage)), isEmpty);
        verifierUnSeulBoutonPlein(tester);
        expect(
          verifierAucuneCarteCollee(
            tester,
            estCarte: (Widget w) => w is AppCard,
          ),
          greaterThan(1),
        );
      });
    }

    testWidgets('1440 sombre et RTL', (WidgetTester tester) async {
      await _monter(
        tester,
        const RecevoirPaiementsPage(),
        MesMoyensPaiementDemo(),
        taille: const Size(1440, 1200),
        theme: ThemeMode.dark,
      );
      expect(tester.takeException(), isNull);
      await _monter(
        tester,
        const RecevoirPaiementsPage(),
        MesMoyensPaiementDemo(),
        sens: TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
    });
  });
}

class _AjoutIndisponible extends MesMoyensPaiementDemo {
  _AjoutIndisponible() : super(depart: MesMoyensPaiementDemo.aucun);

  @override
  Future<EtatMesMoyensPaiement> ajouter(BrouillonMoyenPaiement b) =>
      Future<EtatMesMoyensPaiement>.error(
        const CapaciteIndisponible('CPT-BR-16'),
      );
}
