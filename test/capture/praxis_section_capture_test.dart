// Captures de la section « Praxis » de « Acces des agents IA » (PX-3, R3) :
// 360 px de large, francais et arabe (de droite a gauche), clair.
//
// Etats : contenu (reglages, cles, journal), cle emise (le secret montre une
// fois), vide (aucune cle, aucun envoi), erreur de lecture, hors ligne,
// double verification manquante. Sur la VRAIE page « Acces des agents IA » :
// la section est posee sous la liste des jetons d'observation.
//
// Les donnees sont fictives (`test/support/faux_service_praxis.dart`) : aucune
// personne reelle, aucune vraie cle. Saute sans CAPTURE_DIR (voir
// `test/capture/LISEZ-MOI.md`).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/agent/questions_praxis.dart';
import 'package:rewayah_academy/core/agent/service_agent.dart';
import 'package:rewayah_academy/core/agent/service_autorisation_praxis.dart';
import 'package:rewayah_academy/core/agent/service_praxis.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/features/admin_acces_agents/acces_agents_page.dart';
import 'package:rewayah_academy/features/admin_acces_agents/section_praxis.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';

import '../support/faux_service_autorisation_praxis.dart';
import '../support/faux_service_praxis.dart';
import '../support/faux_service_questions_praxis.dart';
import 'outil_capture.dart';

/// Les conversations de la direction, fictives (le choix des conversations
/// d'essai les montre comme les Messages).
class _MessagesDirection extends MessagesMetierIndisponibles {
  const _MessagesDirection();

  @override
  Future<List<ResumeFil>> fils() async => <ResumeFil>[
    for (final (String, String, String, String) x
        in <(String, String, String, String)>[
          (
            'f1',
            'Compte de test',
            'Dossier de test',
            'Bonjour, essai de la direction.',
          ),
          (
            'f2',
            'Famille fictive',
            'Dossier fictif',
            'Merci pour votre réponse.',
          ),
          (
            'f3',
            'Autre compte de test',
            'Dossier de test',
            'À quelle heure commence la Classe ?',
          ),
        ])
      ResumeFil(
        id: x.$1,
        objet: ObjetLie(
          type: TypeObjetLie.dossier,
          id: 'o-${x.$1}',
          libelle: x.$3,
        ),
        interlocuteurs: <Participant>[
          Participant(id: 'p-${x.$1}', nomAffiche: x.$2, fonction: 'Parent'),
        ],
        apercu: x.$4,
        dernierMessageLe: DateTime.utc(2026, 11, 16, 18),
      ),
  ];
}

/// Un service d'observation vide : seule la section Praxis est montree.
class _AgentsVide implements ServiceAgent {
  @override
  Future<List<JetonAgent>> lister() async => <JetonAgent>[];

  @override
  Future<List<PersonneObservable>> personnes() async => <PersonneObservable>[];

  @override
  Future<JetonEmis> emettre({
    required String libelle,
    required String profilObserve,
    required int dureeHeures,
    required bool identiteMasquee,
  }) async => throw UnimplementedError();

  @override
  Future<bool> revoquer(String id) async => true;
}

enum _Etat {
  contenu,
  cleEmise,
  vide,
  erreur,
  horsLigne,
  doubleVerification,
  essai,
  pouls,
  poulsAucun,
  questions,
  questionsVide,
  questionsErreur,
  questionsHorsLigne,
  questionsFeuille,
}

FauxServicePraxis _faux(_Etat etat) {
  final List<List<LigneJournalPraxis>> pages = <List<LigneJournalPraxis>>[
    <LigneJournalPraxis>[
      ligneJournalFictive(
        9,
        extrait: 'Bonjour, votre demande est bien reçue. La direction vous répondra.',
      ),
      ligneJournalFictive(8, issue: 'plafond_fil', extrait: null),
      ligneJournalFictive(
        7,
        outil: 'annoncer',
        extrait: 'Rappel : la rentrée des classes aura lieu lundi.',
      ),
    ],
  ];
  return switch (etat) {
    _Etat.vide => FauxServicePraxis(
      etat: const EtatPraxis(
        actif: false,
        autonome: false,
        envoisParHeure: 30,
        cles: <ClePraxis>[],
      ),
    ),
    _Etat.erreur || _Etat.horsLigne => FauxServicePraxis(
      erreurEtat: Exception('panne'),
      erreurJournal: Exception('panne'),
    ),
    _Etat.doubleVerification => FauxServicePraxis(
      pages: pages,
    )..refusDroit = true,
    _ => FauxServicePraxis(
      etat: EtatPraxis(
        actif: true,
        envoisParHeure: 30,
        autonome: etat == _Etat.pouls,
        essaiFils: etat == _Etat.essai
            ? const <String>['f1', 'f2']
            : const <String>[],
        derniereRoutine: etat == _Etat.pouls
            ? TirRoutinePraxis(
                termineLe: DateTime(2026, 11, 17, 9, 14),
                issue: 'ok',
                filsLus: 7,
                messagesEnvoyes: 4,
                passesEquipe: 2,
                refus: 1,
                note: 'Un fil laissé à l\'équipe : demande de remboursement.',
              )
            : null,
        cles: <ClePraxis>[
          clePraxisFictive(derniereUtilisation: DateTime(2026, 11, 15, 18)),
          clePraxisFictive(
            id: 'c2',
            libelle: 'Routine du soir',
            prefixe: 'prx_9f8e7d6c',
            usage: UsageClePraxis.routine,
            etat: EtatClePraxis.revoquee,
          ),
          clePraxisFictive(
            id: 'c3',
            libelle: 'Essai de la semaine dernière',
            prefixe: 'prx_5a4b3c2d',
            etat: EtatClePraxis.expiree,
          ),
        ],
      ),
      pages: pages,
    ),
  };
}

/// PX-SUIVI : les questions de Praxis, selon l'etat montre.
ServiceQuestionsPraxis _questions(_Etat etat) => switch (etat) {
  _Etat.questions || _Etat.questionsFeuille => FauxServiceQuestionsPraxis(
    questions: <QuestionPraxis>[
      questionPraxisFictive(
        id: 'q1',
        filId: 'f1',
        question:
            'Le tuteur demande si le cours du lundi peut passer au mardi : '
            'peut-on le décaler ?',
        poseeLe: DateTime(2026, 11, 17, 8, 40),
      ),
      questionPraxisFictive(
        id: 'q2',
        filId: 'f2',
        question: 'Une famille demande si un frère peut suivre la même Classe.',
        poseeLe: DateTime(2026, 11, 17, 9, 5),
      ),
      questionPraxisFictive(
        id: 'q3',
        filId: 'f3',
        question: 'Que répondre sur les horaires du mois de Ramadan ?',
        poseeLe: DateTime(2026, 11, 16, 18, 20),
        reponse: 'Les horaires du Ramadan seront annoncés vendredi.',
        utiliseeLe: DateTime(2026, 11, 17, 7),
      ),
    ],
  ),
  _Etat.questionsErreur || _Etat.questionsHorsLigne =>
    FauxServiceQuestionsPraxis(erreurLecture: Exception('panne')),
  _ => const QuestionsPraxisVides(),
};

Future<void> _ouvrir(WidgetTester tester, _Etat etat) async {
  final FauxServicePraxis faux = _faux(etat);
  final List<Override> surcharges = <Override>[
    servicePraxisProvider.overrideWithValue(faux),
    serviceAutorisationPraxisProvider.overrideWithValue(
      FauxServiceAutorisationPraxis(),
    ),
    serviceQuestionsPraxisProvider.overrideWithValue(_questions(etat)),
    serviceAgentProvider.overrideWithValue(_AgentsVide()),
    portMessagesMetierProvider.overrideWithValue(const _MessagesDirection()),
    if (etat == _Etat.horsLigne || etat == _Etat.questionsHorsLigne)
      horsLigneProvider.overrideWith((ref) => Stream<bool>.value(true)),
  ];
  await tester.pumpWidget(
    hoteCapture(const AccesAgentsPage(), surcharges: surcharges),
  );
  await stabiliser(tester);

  Future<void> toucher(Finder cible) async {
    await tester.ensureVisible(cible);
    await stabiliser(tester);
    await tester.tap(cible);
    await stabiliser(tester);
  }

  if (etat == _Etat.cleEmise) {
    final Finder champ = find.byType(TextField);
    await tester.ensureVisible(champ.last);
    await tester.enterText(champ.last, 'Conversation du directeur');
    await stabiliser(tester);
    await toucher(find.byKey(ClesPraxis.emettre));
  }
  if (etat == _Etat.doubleVerification) {
    await toucher(find.byKey(ClesPraxis.interrupteur));
  }
  if (etat == _Etat.questionsFeuille) {
    // Le menu de la premiere ligne, puis « Répondre à Praxis » : la feuille.
    await toucher(
      find.bySemanticsLabel(t.admin.praxis.questions.actions).first,
    );
    await toucher(find.text(t.admin.praxis.questions.actionRepondre).first);
  }
  // La section est sous la liste des jetons : on la met a l'ecran (le pouls :
  // le bloc de la routine).
  final Finder titre = find.text(
    etat == _Etat.pouls || etat == _Etat.poulsAucun
        ? t.admin.praxis.routine.titre
        : etat.name.startsWith('questions')
        ? t.admin.praxis.questions.titre
        : t.admin.praxis.titre,
  );
  if (titre.evaluate().isNotEmpty) {
    await tester.ensureVisible(titre.first);
    await stabiliser(tester);
  }
  expect(tester.takeException(), isNull);
}

void main() {
  group('Capture : section Praxis (PX-3)', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final _Etat etat in _Etat.values) {
        final String nom = 'praxis_${etat.name}_${langue.languageCode}_360';
        testWidgets(nom, (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          fixerVueCapture(tester, const Size(360, 2400), 1);
          await _ouvrir(tester, etat);
          debugPrint('PNG ${await capturer(tester, nom)}');
          await tester.pumpWidget(const SizedBox());
          await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.fr));
        });
      }
    }
  });
}
