// D1-bis (03/11/2026) : la direction traite un signalement depuis ses
// alertes. L'adaptateur (capacites lues, gestes envoyes, refus), puis la
// feuille sur la vraie page des alertes, avec un serveur simule qui tient
// l'ordre des etapes comme la migration 20261106200000.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/alertes/alerte.dart';
import 'package:rewayah_academy/core/alertes/alertes_supabase.dart';
import 'package:rewayah_academy/core/alertes/port_alertes.dart';
import 'package:rewayah_academy/core/alertes/traitement_signalement.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/alertes/alertes_page.dart';
import 'package:rewayah_academy/features/alertes/feuille_signalement.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/harnais.dart';

final DateTime _recu = DateTime.utc(2026, 11, 3, 9, 30);

/// Une ligne de la file, telle que la migration la rend.
Map<String, dynamic> _ligne({
  String id = '11111111-1111-1111-1111-111111111111',
  String categorie = 'pedagogique',
  String statut = 'ouvert',
  String? resume,
  String? cible = 'tuteur_du_mineur',
  bool? motifRequis = false,
}) {
  final bool securite = categorie == 'securite_enfant';
  final bool avant = statut == 'ouvert' || statut == 'en_examen';
  return <String, dynamic>{
    'id': id,
    'categorie': categorie,
    'prioritaire': securite,
    'academy_id': 'RA-26-4817',
    'internal_details': 'Il ne suit plus la lecture depuis deux séances.',
    'statut': statut,
    'cree_le': _recu.toIso8601String(),
    'family_summary': resume,
    'cible': securite ? null : cible,
    'peut_examiner': statut == 'ouvert',
    'peut_rediger': !securite && avant,
    'peut_transmettre':
        !securite && avant && (resume ?? '').trim().isNotEmpty && cible != null,
    'peut_clore': true,
    'motif_cloture_requis': ?motifRequis,
  };
}

/// Un serveur simule : la file, et les gestes qui la changent dans l'ordre
/// de la migration (rien apres clos, transmission une fois).
class _Serveur implements PortAlertes, PortTraitementSignalement {
  _Serveur(List<Map<String, dynamic>> lignes)
    : lignes = <Map<String, dynamic>>[...lignes];

  final List<Map<String, dynamic>> lignes;
  final List<String> appels = <String>[];
  Exception? erreurProchaine;

  Map<String, dynamic> _trouver(String id) =>
      lignes.firstWhere((Map<String, dynamic> l) => l['id'] == id);

  void _maj(String id, Map<String, dynamic> nouvelle) {
    final int i = lignes.indexWhere((Map<String, dynamic> l) => l['id'] == id);
    lignes[i] = nouvelle;
  }

  Future<void> _geste(String nom, void Function() effet) async {
    appels.add(nom);
    if (erreurProchaine case final Exception e) {
      erreurProchaine = null;
      throw e;
    }
    effet();
  }

  @override
  Stream<List<Alerte>> suivre() => Stream<List<Alerte>>.value(<Alerte>[
    for (final Map<String, dynamic> l in lignes) alerteSignalementJson(l),
  ]);

  @override
  Future<void> examiner(String id) => _geste('examiner', () {
    final Map<String, dynamic> l = _trouver(id);
    _maj(
      id,
      _ligne(
        id: id,
        categorie: l['categorie'] as String,
        statut: 'en_examen',
        resume: l['family_summary'] as String?,
        motifRequis: l['motif_cloture_requis'] as bool?,
      ),
    );
  });

  @override
  Future<void> rediger(String id, String resume) =>
      _geste('rediger:$resume', () {
        final Map<String, dynamic> l = _trouver(id);
        _maj(
          id,
          _ligne(
            id: id,
            categorie: l['categorie'] as String,
            statut: l['statut'] as String,
            resume: resume,
            motifRequis: l['motif_cloture_requis'] as bool?,
          ),
        );
      });

  @override
  Future<void> transmettre(String id, CibleTransmission cible) =>
      _geste('transmettre:${cible.name}', () {
        final Map<String, dynamic> l = _trouver(id);
        _maj(
          id,
          _ligne(
            id: id,
            categorie: l['categorie'] as String,
            statut: 'transmis',
            resume: l['family_summary'] as String?,
            motifRequis: l['motif_cloture_requis'] as bool?,
          ),
        );
      });

  @override
  Future<void> clore(String id, {String? motif}) => _geste(
    'clore:${motif ?? '-'}',
    () => lignes.removeWhere((Map<String, dynamic> l) => l['id'] == id),
  );
}

List<Override> _surcharges(PortAlertes port, {bool horsLigne = false}) =>
    <Override>[
      portAlertesProvider.overrideWithValue(port),
      horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(horsLigne)),
      serviceAdminProvider.overrideWithValue(FauxServiceAdmin()),
      serviceValidationProvider.overrideWithValue(FauxServiceValidation()),
    ];

Future<void> _monter(
  WidgetTester tester,
  List<Override> surcharges, {
  double largeur = 390,
  TextDirection sens = TextDirection.ltr,
}) async {
  tester.view.physicalSize = Size(largeur, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: surcharges,
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          builder: (BuildContext c, Widget? app) =>
              Directionality(textDirection: sens, child: app!),
          home: const AlertesPage(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _attendre(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _ouvrir(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(ValueKey<String>('alerte-signalement-$id')));
  await _attendre(tester);
}

Future<void> _appuyer(WidgetTester tester, Key cle) async {
  await tester.ensureVisible(find.byKey(cle));
  await tester.tap(find.byKey(cle));
  await _attendre(tester);
}

/// Repond a la seconde confirmation.
Future<void> _confirmer(WidgetTester tester, String oui) async {
  await tester.tap(find.text(oui));
  await _attendre(tester);
}

Future<Object?> Function(String, Map<String, dynamic>) _appel(
  List<String> appels, {
  Exception? erreur,
}) => (String fonction, Map<String, dynamic> params) async {
  appels.add(
    '$fonction ${params.entries.map((e) => '${e.key}=${e.value}').join(' ')}',
  );
  if (erreur != null) throw erreur;
  return null;
};

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('adaptateur', () {
    test('lit les capacites et le statut rendus par le serveur', () {
      final Alerte a = alerteSignalementJson(
        _ligne(statut: 'en_examen', resume: 'Bonjour', motifRequis: true),
      );
      final SignalementATraiter s = a.signalement!;
      expect(a.destination, Routes.adminAlertes);
      expect(s.statut, StatutSignalement.enExamen);
      expect(s.cible, CibleTransmission.tuteurDuMineur);
      expect(s.peutExaminer, isFalse);
      expect(s.peutRediger, isTrue);
      expect(s.peutTransmettre, isTrue);
      expect(s.peutClore, isTrue);
      expect(s.motifRequis, isTrue);
      expect(s.resume, 'Bonjour');
    });

    test('un serveur sans la capacite du motif : le motif est exige', () {
      final SignalementATraiter s = alerteSignalementJson(
        _ligne(motifRequis: null),
      ).signalement!;
      expect(s.motifRequis, isTrue);
    });

    test('chaque geste appelle sa fonction avec ses parametres', () async {
      final List<String> appels = <String>[];
      final AlertesSupabase port = AlertesSupabase(_appel(appels));
      await port.examiner('x');
      await port.rediger('x', 'Un mot');
      await port.transmettre('x', CibleTransmission.eleveAdulte);
      await port.clore('x', motif: 'Réglé avec la famille');
      await port.clore('y');
      expect(appels, <String>[
        'examiner_student_concern p_concern_id=x',
        'rediger_resume_student_concern p_concern_id=x p_resume=Un mot',
        'transmettre_student_concern p_concern_id=x p_cible=eleve_adulte',
        'clore_student_concern p_concern_id=x p_motif=Réglé avec la famille',
        'clore_student_concern p_concern_id=y p_motif=null',
      ]);
    });

    test('une garde du serveur (P0001) est une transition refusee', () async {
      final AlertesSupabase port = AlertesSupabase(
        _appel(
          <String>[],
          erreur: const PostgrestException(
            message: 'seul un signalement ouvert passe en examen',
            code: 'P0001',
          ),
        ),
      );
      await expectLater(port.examiner('x'), throwsA(isA<TransitionRefusee>()));
    });

    test('un refus de droit (42501) est l indisponibilite', () async {
      final AlertesSupabase port = AlertesSupabase(
        _appel(
          <String>[],
          erreur: const PostgrestException(message: 'refus', code: '42501'),
        ),
      );
      await expectLater(port.clore('x'), throwsA(isA<CapaciteIndisponible>()));
    });

    test('le traitement suit l adaptateur des alertes, sinon indisponible', () {
      final ProviderContainer avec = ProviderContainer(
        overrides: <Override>[
          portAlertesProvider.overrideWithValue(
            AlertesSupabase(_appel(<String>[])),
          ),
        ],
      );
      addTearDown(avec.dispose);
      expect(
        avec.read(portTraitementSignalementProvider),
        isA<AlertesSupabase>(),
      );
      final ProviderContainer sans = ProviderContainer();
      addTearDown(sans.dispose);
      expect(
        sans.read(portTraitementSignalementProvider),
        isA<TraitementSignalementIndisponible>(),
      );
    });
  });

  test(
    'chaque geste a un nom distinct de « Fermer », en fr et en ar',
    () async {
      for (final AppLocale l in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
        final Traductions tr = await l.build();
        final List<String> noms = <String>[
          tr.commun.fermer,
          tr.alertes.traitement.examiner,
          tr.alertes.traitement.transmettre,
          tr.alertes.traitement.clore,
        ];
        expect(noms.toSet(), hasLength(noms.length), reason: l.languageCode);
      }
    },
  );

  group('feuille sur la page des alertes', () {
    testWidgets('examiner, ecrire le message, transmettre, clore : il sort', (
      WidgetTester tester,
    ) async {
      final tr = t.alertes.traitement;
      final _Serveur serveur = _Serveur(<Map<String, dynamic>>[_ligne()]);
      await _monter(tester, _surcharges(serveur));
      await _ouvrir(tester, '11111111-1111-1111-1111-111111111111');

      expect(find.text(tr.titre), findsOneWidget);
      expect(
        find.text('Il ne suit plus la lecture depuis deux séances.'),
        findsOneWidget,
      );
      expect(find.text(tr.statutValeur.aExaminer), findsOneWidget);
      expect(find.text(tr.pasEncoreAffiche), findsOneWidget);
      // Le message n'est jamais pre-rempli depuis la note interne.
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: find.byKey(FeuilleSignalement.cleMessage),
                matching: find.byType(EditableText),
              ),
            )
            .controller
            .text,
        isEmpty,
      );

      await _appuyer(tester, FeuilleSignalement.cleExaminer);
      expect(serveur.appels, <String>['examiner']);
      expect(find.text(tr.faitExamenTitre), findsOneWidget);
      // Le statut du serveur, sur la feuille et sur la ligne derriere.
      expect(find.text(tr.statutValeur.enExamen), findsWidgets);
      expect(find.byKey(FeuilleSignalement.cleExaminer), findsNothing);

      // Transmettre sans message : on le dit, rien ne part.
      await _appuyer(tester, FeuilleSignalement.cleTransmettre);
      expect(find.text(tr.messageManque), findsWidgets);
      expect(serveur.appels, <String>['examiner']);

      await tester.enterText(
        find.byKey(FeuilleSignalement.cleMessage),
        'Nous en parlons avec vous cette semaine.',
      );
      await _appuyer(tester, FeuilleSignalement.cleTransmettre);
      expect(find.text(tr.transmettreQuestionTuteur), findsOneWidget);
      await _confirmer(tester, tr.transmettreOui);
      expect(serveur.appels, <String>[
        'examiner',
        'rediger:Nous en parlons avec vous cette semaine.',
        'transmettre:tuteurDuMineur',
      ]);
      expect(find.text(tr.faitTransmisTitre), findsOneWidget);
      expect(find.byKey(FeuilleSignalement.cleTransmettre), findsNothing);

      // Clore : motif facultatif ici ; la confirmation, puis il sort.
      await _appuyer(tester, FeuilleSignalement.cleClore);
      expect(find.text(tr.cloreQuestion), findsOneWidget);
      await _confirmer(tester, tr.cloreOui);
      expect(serveur.appels.last, 'clore:-');
      expect(find.text(tr.faitClosTitre), findsOneWidget);
      expect(serveur.lignes, isEmpty);

      await tester.tap(find.text(t.commun.fermer));
      await _attendre(tester);
      expect(
        find.byKey(
          const ValueKey<String>(
            'alerte-signalement-11111111-1111-1111-1111-111111111111',
          ),
        ),
        findsNothing,
      );
      expect(find.text(t.alertes.videTitre), findsOneWidget);
    });

    testWidgets('securite d un enfant : sans message, motif exige', (
      WidgetTester tester,
    ) async {
      final tr = t.alertes.traitement;
      final _Serveur serveur = _Serveur(<Map<String, dynamic>>[
        _ligne(categorie: 'securite_enfant', motifRequis: true),
      ]);
      await _monter(tester, _surcharges(serveur));
      await _ouvrir(tester, '11111111-1111-1111-1111-111111111111');

      expect(find.text(tr.securitePhrase), findsOneWidget);
      expect(find.byKey(FeuilleSignalement.cleMessage), findsNothing);
      expect(find.byKey(FeuilleSignalement.cleTransmettre), findsNothing);
      expect(find.text(tr.motifRequisAide), findsOneWidget);

      await _appuyer(tester, FeuilleSignalement.cleClore);
      expect(find.text(tr.motifManque), findsWidgets);
      expect(serveur.appels, isEmpty);

      await tester.enterText(
        find.byKey(FeuilleSignalement.cleMotif),
        'Pris en charge par la direction avec la famille.',
      );
      await _appuyer(tester, FeuilleSignalement.cleClore);
      // « Annuler » renonce : rien ne part.
      await _confirmer(tester, t.commun.annuler);
      expect(serveur.appels, isEmpty);

      await _appuyer(tester, FeuilleSignalement.cleClore);
      await _confirmer(tester, tr.cloreOui);
      expect(serveur.appels, <String>[
        'clore:Pris en charge par la direction avec la famille.',
      ]);
    });

    testWidgets('un refus du serveur le dit et relit la file', (
      WidgetTester tester,
    ) async {
      final tr = t.alertes.traitement;
      final _Serveur serveur = _Serveur(<Map<String, dynamic>>[_ligne()])
        ..erreurProchaine = const TransitionRefusee('deja en examen');
      await _monter(tester, _surcharges(serveur));
      await _ouvrir(tester, '11111111-1111-1111-1111-111111111111');
      await _appuyer(tester, FeuilleSignalement.cleExaminer);
      expect(find.text(tr.refuseTitre), findsOneWidget);
    });

    testWidgets('une panne le dit, sans faux succes', (
      WidgetTester tester,
    ) async {
      final tr = t.alertes.traitement;
      final _Serveur serveur = _Serveur(<Map<String, dynamic>>[_ligne()])
        ..erreurProchaine = Exception('reseau');
      await _monter(tester, _surcharges(serveur));
      await _ouvrir(tester, '11111111-1111-1111-1111-111111111111');
      await _appuyer(tester, FeuilleSignalement.cleExaminer);
      expect(find.text(tr.erreurTitre), findsOneWidget);
      expect(find.text(tr.faitExamenTitre), findsNothing);
    });

    testWidgets('hors ligne : la phrase, aucun geste', (
      WidgetTester tester,
    ) async {
      final _Serveur serveur = _Serveur(<Map<String, dynamic>>[_ligne()]);
      await _monter(tester, _surcharges(serveur, horsLigne: true));
      await _ouvrir(tester, '11111111-1111-1111-1111-111111111111');
      expect(find.text(t.alertes.traitement.horsLigne), findsOneWidget);
      expect(find.byKey(FeuilleSignalement.cleExaminer), findsNothing);
      expect(find.byKey(FeuilleSignalement.cleClore), findsNothing);
      expect(find.byKey(FeuilleSignalement.cleTransmettre), findsNothing);
    });

    testWidgets(
      '1440, de droite a gauche : la feuille s ouvre, rien ne deborde',
      (WidgetTester tester) async {
        final _Serveur serveur = _Serveur(<Map<String, dynamic>>[_ligne()]);
        await _monter(
          tester,
          _surcharges(serveur),
          largeur: 1440,
          sens: TextDirection.rtl,
        );
        await _ouvrir(tester, '11111111-1111-1111-1111-111111111111');
        expect(find.byKey(FeuilleSignalement.cleExaminer), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
