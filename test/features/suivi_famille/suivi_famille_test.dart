// SUIVI-FAMILLE (R20) : la frise des demandes, cote famille.
//
// Ce que le test prouve :
// - le modele : l'etat de chaque etape se deduit de la seule etape courante,
//   les etapes sont rangees dans l'ordre, un instant UTC est refuse, le motif
//   d'attente n'existe qu'a l'attente ;
// - la liste : l'etape courante de chaque demande, le lien vers le detail ;
//   les cinq etats (chargement, contenu, vide avec bouton, erreur, hors
//   ligne) ; sans port de frise, l'ecran d'OFFRES-FAM-1 reste en place ;
// - le detail : ordre des etapes, etape courante mise en avant, horodatage
//   en heure du foyer, intervalle entre deux etapes, motif d'attente, date
//   de premiere seance seulement si connue, demande introuvable ;
// - aucun rang de file ni autre famille : le serveur simule les connait, le
//   port ne les porte pas ;
// - les notifications de chaque passage d'etape ;
// - 320 px, texte x2, LTR et RTL, lecteur d'ecran.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/port_frise_demande.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/demo/suivi_demandes_demo.dart';
import 'package:rewayah_academy/features/suivi_demandes/suivi_demandes_page.dart';
import 'package:rewayah_academy/features/suivi_famille/libelles_suivi_famille.dart';
import 'package:rewayah_academy/features/suivi_famille/suivi_famille_page.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/monter_recrutement.dart';

class _PortFlux implements PortFriseDemandes {
  _PortFlux(this._flux);

  final Stream<List<FriseDemande>> Function() _flux;

  @override
  Stream<List<FriseDemande>> suivre() => _flux();
}

List<Override> _avec(PortFriseDemandes port) => <Override>[
  portFriseDemandesProvider.overrideWithValue(port),
];

SuiviDemandesDemo _serveur() => SuiviDemandesDemo.frises();

Future<void> _liste(
  WidgetTester tester, {
  List<Override> surcharges = const <Override>[],
  bool horsLigne = false,
  double largeur = 390,
  double echelle = 1,
  TextDirection? direction,
}) => monterRecrutement(
  tester,
  chemin: '/tuteur/demandes',
  ecran: (_) => const SuiviDemandesEntree(),
  autres: <String>['/tuteur/classes/catalogue', '/tuteur/demandes/:id'],
  surcharges: surcharges,
  horsLigne: horsLigne,
  largeur: largeur,
  echelle: echelle,
  direction: direction,
);

Future<void> _detail(
  WidgetTester tester,
  String id, {
  List<Override> surcharges = const <Override>[],
  bool horsLigne = false,
  double largeur = 390,
  double echelle = 1,
  TextDirection? direction,
}) => monterRecrutement(
  tester,
  chemin: '/tuteur/demandes/:demandeId',
  depart: '/tuteur/demandes/$id',
  ecran: (s) => FriseDemandePage(demandeId: s.pathParameters['demandeId']!),
  autres: <String>['/tuteur/demandes'],
  surcharges: surcharges,
  horsLigne: horsLigne,
  largeur: largeur,
  echelle: echelle,
  direction: direction,
);

double _y(WidgetTester tester, String cle) =>
    tester.getTopLeft(find.byKey(ValueKey<String>(cle))).dy;

void main() {
  final f = t.suiviFamille;

  group('modele', () {
    FriseDemande frise(TypeEtapeFrise? courante, {MotifAttente? motif}) =>
        FriseDemande(
          demandeId: 'd',
          eleveId: 'e',
          prenom: 'Yusuf',
          fuseauIana: 'Europe/Paris',
          courante: courante,
          motifAttente: motif,
          etapes: <EtapeFrise>[
            EtapeFrise(type: TypeEtapeFrise.premiereSeance),
            EtapeFrise(type: TypeEtapeFrise.envoyee),
            EtapeFrise(type: TypeEtapeFrise.classeCreee),
            EtapeFrise(type: TypeEtapeFrise.classeCreee),
          ],
        );

    test('etapes rangees dans l\'ordre et dedoublonnees', () {
      expect(frise(null).etapes.map((EtapeFrise e) => e.type), <TypeEtapeFrise>[
        TypeEtapeFrise.envoyee,
        TypeEtapeFrise.classeCreee,
        TypeEtapeFrise.premiereSeance,
      ]);
    });

    test('l\'etat se deduit de l\'etape courante', () {
      final FriseDemande x = frise(TypeEtapeFrise.classeCreee);
      expect(x.etatDe(TypeEtapeFrise.envoyee), EtatEtapeFrise.fait);
      expect(x.etatDe(TypeEtapeFrise.classeCreee), EtatEtapeFrise.enCours);
      expect(x.etatDe(TypeEtapeFrise.premiereSeance), EtatEtapeFrise.aVenir);
      expect(
        frise(null).etatDe(TypeEtapeFrise.premiereSeance),
        EtatEtapeFrise.fait,
      );
    });

    test('le motif n\'existe qu\'a l\'attente', () {
      expect(
        frise(
          TypeEtapeFrise.enAttente,
          motif: MotifAttente.classesPleines,
        ).motifAttente,
        MotifAttente.classesPleines,
      );
      expect(
        frise(TypeEtapeFrise.enAttente).motifAttente,
        MotifAttente.inconnu,
      );
      expect(
        frise(
          TypeEtapeFrise.classeCreee,
          motif: MotifAttente.classesPleines,
        ).motifAttente,
        isNull,
      );
    });

    test('un instant UTC est refuse', () {
      expect(
        () => EtapeFrise(
          type: TypeEtapeFrise.envoyee,
          quand: DateTime.utc(2026, 10, 1, 18),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('liste', () {
    testWidgets('contenu : l\'etape courante de chaque demande', (
      tester,
    ) async {
      await _liste(tester, surcharges: _avec(FriseDemandesDemo(_serveur())));
      expect(
        find.byKey(const ValueKey<String>('suivi-famille-contenu')),
        findsOne,
      );
      expect(
        find.text(f.etapeCourante(etape: f.etapes.enAttente)),
        findsOneWidget,
      );
      expect(
        find.text(f.etapeCourante(etape: f.etapes.eleveIntegre)),
        findsOneWidget,
      );
      expect(
        find.text(f.etapeCourante(etape: f.etapes.premiereSeance)),
        findsOneWidget,
      );
      expect(find.text(f.voirSuivi), findsNWidgets(5));
      verifierEcranSansMotCoupe(tester);
    });

    testWidgets('sans port de frise : l\'ecran existant reste en place', (
      tester,
    ) async {
      await _liste(tester);
      expect(find.byType(SuiviDemandesPage), findsOneWidget);
      expect(find.byType(SuiviFamillePage), findsNothing);
    });

    testWidgets('chargement', (tester) async {
      await _liste(
        tester,
        surcharges: _avec(
          _PortFlux(() => const Stream<List<FriseDemande>>.empty()),
        ),
      );
      expect(find.byType(Skeleton), findsWidgets);
    });

    testWidgets('vide : un bouton mene a la demande', (tester) async {
      await _liste(
        tester,
        surcharges: _avec(
          _PortFlux(() => Stream<List<FriseDemande>>.value(const [])),
        ),
      );
      expect(find.byType(EmptyState), findsOneWidget);
      await tester.tap(find.text(f.faireDemande));
      await laisser(tester);
      expect(find.text('temoin:/tuteur/classes/catalogue'), findsOneWidget);
    });

    testWidgets('erreur : reessayer', (tester) async {
      await _liste(
        tester,
        surcharges: _avec(
          _PortFlux(() => Stream<List<FriseDemande>>.error(StateError('x'))),
        ),
      );
      expect(find.byType(EtatSysteme), findsOneWidget);
      expect(find.text(f.erreur), findsOneWidget);
    });

    testWidgets('hors ligne sans donnees', (tester) async {
      await _liste(
        tester,
        horsLigne: true,
        surcharges: _avec(
          _PortFlux(() => Stream<List<FriseDemande>>.error(StateError('x'))),
        ),
      );
      expect(find.text(f.erreur), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('suivi-famille-sans-donnees')),
        findsOneWidget,
      );
    });

    testWidgets('le lien ouvre le detail', (tester) async {
      await _liste(tester, surcharges: _avec(FriseDemandesDemo(_serveur())));
      await tester.tap(
        find.byKey(const ValueKey<String>('frise-voir-demo-demande-yusuf')),
      );
      await laisser(tester);
      expect(find.text('temoin:/tuteur/demandes/:id'), findsOneWidget);
    });
  });

  group('detail', () {
    testWidgets('ordre, etape courante, horodatage et intervalles', (
      tester,
    ) async {
      await _detail(
        tester,
        'demo-demande-aicha',
        surcharges: _avec(FriseDemandesDemo(_serveur())),
      );
      const List<String> ordre = <String>[
        'envoyee',
        'classeCreee',
        'enseignantAffecte',
        'eleveIntegre',
        'premiereSeance',
      ];
      expect(
        find.byKey(const ValueKey<String>('frise-etape-enAttente')),
        findsNothing,
      );
      for (int i = 1; i < ordre.length; i++) {
        expect(
          _y(tester, 'frise-etape-${ordre[i]}'),
          greaterThan(_y(tester, 'frise-etape-${ordre[i - 1]}')),
        );
      }
      // Fait / en cours / a venir, par le mot.
      expect(find.text(f.etats.fait), findsNWidgets(3));
      expect(find.text(f.etats.enCours), findsOneWidget);
      expect(find.text(f.etats.aVenir), findsOneWidget);
      // Horodatage en heure du foyer, tel que le serveur le donne.
      expect(
        find.text(horodatage(DateTime(2026, 9, 30, 18, 2))),
        findsOneWidget,
      );
      // Intervalles : 1 jour (39 h 58), puis 3 jours.
      expect(find.text(f.intervalle.jour), findsOneWidget);
      expect(find.text(f.intervalle.jours(n: 3)), findsOneWidget);
      // Aucune date de seance inventee.
      expect(
        find.byKey(const ValueKey<String>('frise-quand-premiereSeance')),
        findsNothing,
      );
      expect(find.textContaining('heure de Paris'), findsOneWidget);
      verifierEcranSansMotCoupe(tester);
    });

    testWidgets('attente : motif en clair, sans rang ni autre famille', (
      tester,
    ) async {
      final SuiviDemandesDemo serveur = _serveur();
      await _detail(
        tester,
        'demo-demande-yusuf',
        surcharges: _avec(FriseDemandesDemo(serveur)),
      );
      expect(
        find.byKey(const ValueKey<String>('frise-etape-enAttente')),
        findsOneWidget,
      );
      expect(find.text(f.motif.classesPleines), findsOneWidget);
      // Le serveur simule connait 3 autres demandeurs : rien n'en sort.
      expect(serveur.demandes.first.autresDemandeurs, 3);
      expect(find.textContaining('rang'), findsNothing);
      expect(find.textContaining('3 autres'), findsNothing);
      expect(find.textContaining('position'), findsNothing);
    });

    testWidgets('premiere seance : date prevue seulement si connue', (
      tester,
    ) async {
      await _detail(
        tester,
        'demo-demande-ines',
        surcharges: _avec(FriseDemandesDemo(_serveur())),
      );
      expect(find.text(datePrevue(DateTime(2026, 10, 17, 10))), findsOneWidget);
    });

    testWidgets('introuvable', (tester) async {
      await _detail(
        tester,
        'autre-foyer',
        surcharges: _avec(FriseDemandesDemo(_serveur())),
      );
      expect(find.text(f.introuvable), findsOneWidget);
    });

    testWidgets('mise a jour en direct a chaque passage', (tester) async {
      final SuiviDemandesDemo serveur = _serveur();
      await _detail(
        tester,
        'demo-demande-aicha',
        surcharges: _avec(FriseDemandesDemo(serveur)),
      );
      expect(find.text(f.etats.enCours), findsOneWidget);
      serveur.demandes[1].integreLe = DateTime(2026, 10, 6, 18);
      serveur.notifier();
      await laisser(tester);
      expect(find.text(horodatage(DateTime(2026, 10, 6, 18))), findsOneWidget);
    });

    testWidgets('lecteur d\'ecran : une etape = un libelle', (tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await _detail(
        tester,
        'demo-demande-aicha',
        surcharges: _avec(FriseDemandesDemo(_serveur())),
      );
      expect(
        find.bySemanticsLabel(
          RegExp(
            '${f.etapeSurTotal(n: 2, total: 5, etape: f.etapes.classeCreee)}, ${f.etats.fait}, ',
          ),
        ),
        findsOneWidget,
      );
      h.dispose();
    });

    setUpAll(chargerPolicesDuDepot);
    for (final TextDirection d in <TextDirection>[
      TextDirection.ltr,
      TextDirection.rtl,
    ]) {
      testWidgets('320 px, texte x2, $d', (tester) async {
        await _detail(
          tester,
          'demo-demande-yusuf',
          surcharges: _avec(FriseDemandesDemo(_serveur())),
          largeur: 320,
          echelle: 2,
          direction: d,
        );
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester);
      });
    }
  });

  group('demande close (BACK-FRONT-SUIVI-1)', () {
    setUpAll(chargerPolicesDuDepot);

    testWidgets('la liste dit le motif en clair', (tester) async {
      await _liste(tester, surcharges: _avec(FriseDemandesDemo(_serveur())));
      expect(find.text(f.close.motif.offreRetiree), findsOneWidget);
      expect(
        find.text(f.close.motif.dejaEnClasse(prenom: 'Hana')),
        findsOneWidget,
      );
    });

    testWidgets('retiree : motif, suite possible et lien', (tester) async {
      await _detail(
        tester,
        'demo-demande-bilal',
        surcharges: _avec(FriseDemandesDemo(_serveur())),
      );
      expect(find.byKey(const ValueKey<String>('frise-cloture')), findsOne);
      expect(find.text(f.close.motif.offreRetiree), findsOneWidget);
      expect(find.text(f.close.suite(prenom: 'Bilal')), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('frise-cloture-rechoisir')),
        findsOneWidget,
      );
      // Aucune etape en cours sur une demande close.
      expect(find.text(f.etats.enCours), findsNothing);
      expect(find.text(f.etats.aVenir), findsNothing);
      verifierEcranSansMotCoupe(tester);
    });

    testWidgets('deja en classe : message dedie, ni erreur ni piste', (
      tester,
    ) async {
      await _detail(
        tester,
        'demo-demande-hana',
        surcharges: _avec(FriseDemandesDemo(_serveur())),
      );
      expect(
        find.text(f.close.motif.dejaEnClasse(prenom: 'Hana')),
        findsOneWidget,
      );
      expect(find.text(f.close.suiteSansChoix), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('frise-cloture-rechoisir')),
        findsNothing,
      );
      expect(find.byType(EtatSysteme), findsNothing);
      expect(find.text(f.erreur), findsNothing);
    });

    testWidgets('320 px, texte x2, RTL', (tester) async {
      await _detail(
        tester,
        'demo-demande-hana',
        surcharges: _avec(FriseDemandesDemo(_serveur())),
        largeur: 320,
        echelle: 2,
        direction: TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
      verifierEcranSansMotCoupe(tester);
    });

    test('notification de cloture, « deja en classe » comprise', () async {
      final List<NotificationTuteur> toutes =
          await NotificationsSuiviDemandesDemo(_serveur()).liste();
      expect(
        toutes.where(
          (NotificationTuteur n) => n.id == 'demo-demande-hana-close',
        ),
        hasLength(1),
      );
      expect(
        toutes.firstWhere((n) => n.id == 'demo-demande-hana-close').titre,
        titreNotificationCloture(MotifClotureFrise.dejaEnClasse, 'Hana'),
      );
    });
  });

  group('eleve adulte autonome', () {
    testWidgets('voit lui-meme sa frise, sur ses routes', (tester) async {
      await monterRecrutement(
        tester,
        chemin: '/eleve/adulte/demandes',
        ecran: (_) => const SuiviFamillePage(chemins: CheminsSuivi.adulte),
        autres: <String>['/eleve/adulte/demandes/:id', '/eleve/adulte'],
        surcharges: _avec(FriseDemandesDemo(_serveur())),
      );
      expect(
        find.byKey(const ValueKey<String>('suivi-famille-contenu')),
        findsOne,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('frise-voir-demo-demande-yusuf')),
      );
      await laisser(tester);
      expect(find.text('temoin:/eleve/adulte/demandes/:id'), findsOneWidget);
    });

    testWidgets('vide : pas de bouton sans parcours de demande', (
      tester,
    ) async {
      await monterRecrutement(
        tester,
        chemin: '/eleve/adulte/demandes',
        ecran: (_) => const SuiviFamillePage(chemins: CheminsSuivi.adulte),
        surcharges: _avec(
          _PortFlux(() => Stream<List<FriseDemande>>.value(const [])),
        ),
      );
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(f.faireDemande), findsNothing);
    });
  });

  group('notifications', () {
    test('une entree par passage, vers le detail', () async {
      final SuiviDemandesDemo serveur = _serveur();
      final PortNotifications port = NotificationsSuiviDemandesDemo(serveur);
      final List<NotificationTuteur> toutes = await port.liste();
      NotificationTuteur de(String id) =>
          toutes.firstWhere((NotificationTuteur n) => n.id == id);
      expect(
        de('demo-demande-yusuf-enAttente').titre,
        titreNotificationFrise(TypeEtapeFrise.enAttente, 'Yusuf'),
      );
      expect(
        de('demo-demande-ines-eleveIntegre').destination,
        '/tuteur/demandes/demo-demande-ines',
      );
      // La premiere seance prevue n'est pas encore un passage.
      expect(
        toutes.any((NotificationTuteur n) => n.id.endsWith('premiereSeance')),
        isFalse,
      );
    });
  });
}
