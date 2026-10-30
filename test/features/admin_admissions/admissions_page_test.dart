// Admission, lot C : l'ecran « Demandes » de la direction.
//
// Ce que le test prouve : les deux listes separees (familles, eleves
// adultes) et le compteur ; les etats chargement, vide, erreur ; la feuille
// d'une demande a traiter porte un seul bouton plein (accepter) et trois
// liens ; accepter appelle le serveur puis relit la liste et ne propose plus
// rien ; refuser exige un modele et un motif, confirme avant d'envoyer ;
// demander des precisions et ecrire exigent leur texte ; un refus annulable
// propose l'annulation, un refus de plus de sept jours non ; hors ligne, rien
// ne part ; chaque refus du serveur a sa phrase ; 320 px, texte x2, LTR, RTL.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admission/port_admissions_direction.dart';
import 'package:rewayah_academy/core/i18n/elision.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_admissions/admissions_page.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/garde_interface.dart';
import '../../support/monter_recrutement.dart';

class _Port implements PortAdmissionsDirection {
  _Port(this.parPopulation);

  final Map<PopulationAdmission, List<DemandeAdmission>> parPopulation;
  Completer<PageAdmissions>? retenue;
  Object? erreurLecture;
  Object? erreurGeste;
  int lectures = 0;
  final List<String> gestes = <String>[];
  final List<String?> recherches = <String?>[];

  @override
  Future<PageAdmissions> lister(
    PopulationAdmission population, {
    String? recherche,
    int page = 1,
  }) {
    lectures++;
    recherches.add(recherche);
    final Completer<PageAdmissions>? r = retenue;
    if (r != null) return r.future;
    final Object? e = erreurLecture;
    if (e != null) return Future<PageAdmissions>.error(e);
    final List<DemandeAdmission> l = <DemandeAdmission>[
      for (final DemandeAdmission d
          in parPopulation[population] ?? const <DemandeAdmission>[])
        if (recherche == null || d.nom.contains(recherche)) d,
    ];
    return Future<PageAdmissions>.value(
      PageAdmissions(
        lignes: l,
        total: l.length,
        aTraiter: l
            .where(
              (DemandeAdmission d) => d.etat == EtatDemandeAdmission.aTraiter,
            )
            .length,
        page: page,
        parPage: 50,
      ),
    );
  }

  Future<void> _geste(String g) {
    gestes.add(g);
    final Object? e = erreurGeste;
    return e == null ? Future<void>.value() : Future<void>.error(e);
  }

  @override
  Future<void> accepter(DemandeAdmission d, {required String cle}) =>
      _geste('accepter:${d.id}');

  @override
  Future<void> refuser(
    DemandeAdmission d, {
    required String motif,
    required String modele,
    required String cle,
  }) => _geste('refuser:${d.id}:$modele:$motif');

  @override
  Future<void> annulerRefus(
    DemandeAdmission d, {
    required String motif,
    required String cle,
  }) => _geste('annuler:${d.id}:$motif');

  @override
  Future<void> annulerAcceptation(
    DemandeAdmission d, {
    required String motif,
    required String cle,
  }) => _geste('annuler-acceptation:${d.id}:$motif');

  @override
  Future<void> demanderPrecisions(
    DemandeAdmission d, {
    required String message,
    required String cle,
  }) => _geste('precisions:${d.id}:$message');

  @override
  Future<void> contacter(
    DemandeAdmission d, {
    required String sujet,
    required String message,
    required String cle,
  }) => _geste('contacter:${d.id}:$sujet:$message');
}

DemandeAdmission _demande({
  String id = 'c1',
  String nom = 'Awa Bah',
  EtatDemandeAdmission etat = EtatDemandeAdmission.aTraiter,
  DateTime? derniereActivite,
  List<ApprenantAdmission> apprenants = const <ApprenantAdmission>[
    ApprenantAdmission(prenom: 'Yasmine', titulaire: false, age: 9),
  ],
}) => DemandeAdmission(
  id: id,
  reference: 'CAND-2026-0001',
  nom: nom,
  courriel: 'awa@example.org',
  recueLe: DateTime(2026, 10, 28, 10),
  derniereActivite: derniereActivite,
  etat: etat,
  version: 1,
  apprenants: apprenants,
);

_Port _port({
  List<DemandeAdmission>? familles,
  List<DemandeAdmission> adultes = const <DemandeAdmission>[],
}) => _Port(<PopulationAdmission, List<DemandeAdmission>>{
  PopulationAdmission.famille: familles ?? <DemandeAdmission>[_demande()],
  PopulationAdmission.eleveAdulte: adultes,
});

Future<void> _monter(
  WidgetTester tester,
  _Port port, {
  bool horsLigne = false,
  double largeur = 390,
  double echelle = 1,
  TextDirection? direction,
}) => monterRecrutement(
  tester,
  chemin: '/admin/personnes/demandes',
  ecran: (_) => const AdmissionsPage(),
  autres: <String>[
    '/admin/personnes/dossiers',
    '/admin/personnes/comptes',
    '/admin/personnes/candidatures',
    '/admin/personnes/reprises',
    '/admin/personnes/import',
    '/admin/personnes/suppressions',
  ],
  surcharges: <Override>[
    portAdmissionsDirectionProvider.overrideWithValue(port),
  ],
  horsLigne: horsLigne,
  largeur: largeur,
  echelle: echelle,
  direction: direction,
);

Future<void> _ouvrir(WidgetTester tester, [String id = 'c1']) async {
  await tester.tap(find.byKey(AdmissionsPage.cleCarte(id)));
  await laisser(tester);
}

Future<void> _toucher(WidgetTester tester, String cle) async {
  final Finder f = find.byKey(ValueKey<String>(cle));
  await tester.ensureVisible(f);
  await tester.tap(f);
  await laisser(tester);
}

Finder _champ(String libelle) => find.descendant(
  of: find
      .ancestor(
        of: find.text(libelle),
        matching: find.byWidgetPredicate((Widget w) => w is Column),
      )
      .first,
  matching: find.byType(TextField),
);

void main() {
  final a = t.admissions;

  group('listes', () {
    testWidgets('familles par defaut, compteur, carte et apprenant', (
      tester,
    ) async {
      await _monter(tester, _port());
      expect(find.text('Awa Bah'), findsOneWidget);
      expect(find.text(a.aTraiter(n: 1)), findsOneWidget);
      expect(find.text(a.etat.aTraiter), findsOneWidget);
      expect(find.textContaining('Yasmine'), findsOneWidget);
    });

    testWidgets('eleves adultes : une autre liste', (tester) async {
      final _Port p = _port(
        adultes: <DemandeAdmission>[
          _demande(
            id: 'c2',
            nom: 'Karim Diallo',
            apprenants: const <ApprenantAdmission>[
              ApprenantAdmission(prenom: 'Karim', titulaire: true),
            ],
          ),
        ],
      );
      await _monter(tester, p);
      await tester.tap(find.text(a.elevesAdultes));
      await laisser(tester);
      expect(find.text('Karim Diallo'), findsOneWidget);
      expect(find.text('Awa Bah'), findsNothing);
      expect(find.text(a.titulaire(prenom: 'Karim')), findsOneWidget);
    });

    testWidgets('recherche : transmise au serveur, vide dit', (tester) async {
      final _Port p = _port();
      await _monter(tester, p);
      await tester.enterText(find.byType(TextField).first, 'Zzz');
      await laisser(tester);
      expect(p.recherches.last, 'Zzz');
      expect(find.text(a.videRecherche), findsOneWidget);
    });
  });

  group('etats', () {
    testWidgets('chargement', (tester) async {
      final _Port p = _port()..retenue = Completer<PageAdmissions>();
      await _monter(tester, p);
      expect(find.byType(Skeleton), findsWidgets);
    });

    testWidgets('vide', (tester) async {
      await _monter(tester, _port(familles: <DemandeAdmission>[]));
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(a.vide), findsOneWidget);
      expect(find.text(a.aTraiter(n: 0)), findsOneWidget);
    });

    testWidgets('erreur : un Reessayer relit', (tester) async {
      final _Port p = _port()..erreurLecture = Exception('panne');
      await _monter(tester, p);
      expect(find.byType(EtatSysteme), findsOneWidget);
      expect(find.text(a.lectureErreur), findsOneWidget);
      final int avant = p.lectures;
      p.erreurLecture = null;
      await tester.tap(find.text(t.commun.etats.actions.reessayer));
      await laisser(tester);
      expect(p.lectures, greaterThan(avant));
      expect(find.text('Awa Bah'), findsOneWidget);
    });
  });

  group('feuille', () {
    testWidgets('a traiter : un bouton plein, trois liens', (tester) async {
      await _monter(tester, _port());
      await _ouvrir(tester);
      expect(
        find.byKey(const ValueKey<String>('admission-accepter')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('admission-precisions')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('admission-contacter')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('admission-refuser')),
        findsOneWidget,
      );
      expect(find.text('awa@example.org'), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('accepter : le serveur, la liste relue, plus de geste', (
      tester,
    ) async {
      final _Port p = _port();
      await _monter(tester, p);
      await _ouvrir(tester);
      final int avant = p.lectures;
      await _toucher(tester, 'admission-accepter');
      expect(p.gestes, <String>['accepter:c1']);
      expect(p.lectures, greaterThan(avant));
      expect(
        find.text(a.faitAcceptee(deNom: deDevant('Awa Bah'))),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('admission-accepter')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('admission-refuser')),
        findsNothing,
      );
    });

    testWidgets('refuser : modele et motif exiges, puis confirmation', (
      tester,
    ) async {
      final _Port p = _port();
      await _monter(tester, p);
      await _ouvrir(tester);
      await _toucher(tester, 'admission-refuser');
      await _toucher(tester, 'admission-refuser-envoyer');
      expect(find.text(a.manqueModele), findsOneWidget);
      await tester.tap(find.text(a.modeles.niveau));
      await laisser(tester);
      await _toucher(tester, 'admission-refuser-envoyer');
      expect(find.text(a.manqueMotif), findsOneWidget);
      await tester.enterText(_champ(a.motifInterne), 'Niveau avancé');
      await laisser(tester);
      await _toucher(tester, 'admission-refuser-envoyer');
      // La confirmation, avant tout envoi.
      expect(
        find.text(a.refuserQuestion(deNom: deDevant('Awa Bah'))),
        findsOneWidget,
      );
      expect(p.gestes, isEmpty);
      await tester.tap(find.text(a.refuser).last);
      await laisser(tester);
      expect(p.gestes, <String>['refuser:c1:refus_niveau:Niveau avancé']);
      expect(
        find.text(a.faitRefusee(deNom: deDevant('Awa Bah'))),
        findsOneWidget,
      );
    });

    testWidgets('precisions : le message est exige puis envoye', (
      tester,
    ) async {
      final _Port p = _port();
      await _monter(tester, p);
      await _ouvrir(tester);
      await _toucher(tester, 'admission-precisions');
      await _toucher(tester, 'admission-precisions-envoyer');
      expect(find.text(a.manqueMessage), findsOneWidget);
      await tester.enterText(_champ(a.precisionsMessage), 'L’âge exact');
      await laisser(tester);
      await _toucher(tester, 'admission-precisions-envoyer');
      expect(p.gestes, <String>['precisions:c1:L’âge exact']);
      expect(find.text(a.faitPrecisions(nom: 'Awa Bah')), findsOneWidget);
    });

    testWidgets('ecrire : sujet et message exiges, les gestes restent', (
      tester,
    ) async {
      final _Port p = _port();
      await _monter(tester, p);
      await _ouvrir(tester);
      await _toucher(tester, 'admission-contacter');
      await _toucher(tester, 'admission-contact-envoyer');
      expect(find.text(a.manqueContact), findsOneWidget);
      await tester.enterText(_champ(a.contactSujet), 'Bonjour');
      await tester.enterText(_champ(a.contactMessage), 'Une question');
      await laisser(tester);
      await _toucher(tester, 'admission-contact-envoyer');
      expect(p.gestes, <String>['contacter:c1:Bonjour:Une question']);
      expect(find.text(a.faitContact(nom: 'Awa Bah')), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('admission-accepter')),
        findsOneWidget,
      );
    });

    testWidgets('refus recent : l annulation, avec motif', (tester) async {
      final _Port p = _port(
        familles: <DemandeAdmission>[
          _demande(
            etat: EtatDemandeAdmission.refusee,
            derniereActivite: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ],
      );
      await _monter(tester, p);
      await _ouvrir(tester);
      expect(
        find.byKey(const ValueKey<String>('admission-accepter')),
        findsNothing,
      );
      await _toucher(tester, 'admission-annuler-refus');
      await tester.enterText(_champ(a.motifInterne), 'Erreur de lecture');
      await laisser(tester);
      await _toucher(tester, 'admission-annuler-envoyer');
      expect(p.gestes, <String>['annuler:c1:Erreur de lecture']);
      expect(
        find.text(a.faitRefusAnnule(deNom: deDevant('Awa Bah'))),
        findsOneWidget,
      );
    });

    testWidgets('acceptation recente : l annulation, motif et confirmation', (
      tester,
    ) async {
      final _Port p = _port(
        familles: <DemandeAdmission>[
          _demande(
            etat: EtatDemandeAdmission.acceptee,
            derniereActivite: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ],
      );
      await _monter(tester, p);
      await _ouvrir(tester);
      expect(
        find.byKey(const ValueKey<String>('admission-accepter')),
        findsNothing,
      );
      await _toucher(tester, 'admission-annuler-acceptation');
      await _toucher(tester, 'admission-annuler-acceptation-envoyer');
      expect(find.text(a.manqueMotif), findsOneWidget);
      await tester.enterText(_champ(a.motifInterne), 'Erreur de famille');
      await laisser(tester);
      await _toucher(tester, 'admission-annuler-acceptation-envoyer');
      expect(
        find.text(a.annulerAcceptationQuestion(deNom: deDevant('Awa Bah'))),
        findsOneWidget,
      );
      expect(p.gestes, isEmpty);
      await tester.tap(find.text(a.annulerAcceptation).last);
      await laisser(tester);
      expect(p.gestes, <String>['annuler-acceptation:c1:Erreur de famille']);
      expect(
        find.text(a.faitAcceptationAnnulee(deNom: deDevant('Awa Bah'))),
        findsOneWidget,
      );
    });

    testWidgets('acceptation de plus de sept jours : pas d annulation', (
      tester,
    ) async {
      await _monter(
        tester,
        _port(
          familles: <DemandeAdmission>[
            _demande(
              etat: EtatDemandeAdmission.acceptee,
              derniereActivite: DateTime.now().subtract(
                const Duration(days: 8),
              ),
            ),
          ],
        ),
      );
      await _ouvrir(tester);
      expect(
        find.byKey(const ValueKey<String>('admission-annuler-acceptation')),
        findsNothing,
      );
    });

    testWidgets('refus de plus de sept jours : seulement ecrire', (
      tester,
    ) async {
      await _monter(
        tester,
        _port(
          familles: <DemandeAdmission>[
            _demande(
              etat: EtatDemandeAdmission.refusee,
              derniereActivite: DateTime.now().subtract(
                const Duration(days: 8),
              ),
            ),
          ],
        ),
      );
      await _ouvrir(tester);
      expect(
        find.byKey(const ValueKey<String>('admission-annuler-refus')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('admission-contacter')),
        findsOneWidget,
      );
    });

    testWidgets('hors ligne : rien ne part', (tester) async {
      final _Port p = _port();
      await _monter(tester, p, horsLigne: true);
      await _ouvrir(tester);
      await _toucher(tester, 'admission-accepter');
      expect(p.gestes, isEmpty);
      expect(find.text(a.horsLigne), findsOneWidget);
    });

    final Map<RefusGesteAdmission, String> refus =
        <RefusGesteAdmission, String>{
          RefusGesteAdmission.dejaTraitee: a.refus.dejaTraitee,
          RefusGesteAdmission.transitionInterdite: a.refus.transitionInterdite,
          RefusGesteAdmission.motifRequis: a.refus.motifRequis,
          RefusGesteAdmission.adresseInconnue: a.refus.adresseInconnue,
          RefusGesteAdmission.enfantEnClasse: a.refus.enfantEnClasse,
          RefusGesteAdmission.autre: a.refus.autre,
        };
    refus.forEach((RefusGesteAdmission r, String phrase) {
      testWidgets('refus du serveur ${r.name} : sa phrase, liste relue', (
        tester,
      ) async {
        final _Port p = _port()..erreurGeste = GesteAdmissionRefuse(r);
        await _monter(tester, p);
        await _ouvrir(tester);
        final int avant = p.lectures;
        await _toucher(tester, 'admission-accepter');
        expect(find.text(phrase), findsOneWidget);
        expect(p.lectures, greaterThan(avant));
      });
    });

    testWidgets('coupure : une phrase, rien de pretendu', (tester) async {
      final _Port p = _port()..erreurGeste = Exception('coupure');
      await _monter(tester, p);
      await _ouvrir(tester);
      await _toucher(tester, 'admission-accepter');
      expect(find.text(a.erreur), findsOneWidget);
      expect(
        find.text(a.faitAcceptee(deNom: deDevant('Awa Bah'))),
        findsNothing,
      );
    });
  });

  group('gabarits', () {
    setUpAll(chargerPolicesDuDepot);
    for (final TextDirection d in TextDirection.values) {
      testWidgets('320 px, texte x2, ${d.name}', (tester) async {
        await _monter(
          tester,
          _port(
            familles: <DemandeAdmission>[
              _demande(
                apprenants: const <ApprenantAdmission>[
                  ApprenantAdmission(
                    prenom: 'Yasmine',
                    titulaire: false,
                    age: 9,
                    niveau: 'debutant',
                  ),
                  ApprenantAdmission(
                    prenom: 'Ilyas',
                    titulaire: false,
                    age: 12,
                  ),
                ],
              ),
              _demande(id: 'c2', etat: EtatDemandeAdmission.aCompleter),
            ],
          ),
          largeur: 320,
          echelle: 2,
          direction: d,
        );
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester);
        await _ouvrir(tester);
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester);
      });
    }
  });
}
