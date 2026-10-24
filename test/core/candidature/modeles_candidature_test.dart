// CAND-01 : ce que l'application lit de `etat_dossier().candidature`, de
// `questionnaire_salle_examen()` et de `conditions_remuneration_candidat()`.
// Rien n'est calcule : l'ecran lit ce que le serveur rend, et jamais un montant
// (decision du directeur du 22/10/2026).

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';

import '../../fixtures/candidature/faux_ma_candidature.dart';

Map<String, dynamic> _bloc({
  String etape = 'prequalification',
  String? etat = 'a_completer',
  String issue = 'en_cours',
  bool enPause = false,
}) => <String, dynamic>{
  'candidature': true,
  'reference': 'CAND-26-0001',
  'type': 'enseignant',
  'etape': etape,
  'etat': etat,
  'issue': issue,
  'enPause': enPause,
  'repriseLe': '2026-11-03',
  'version': 4,
  'questionnaire': <String, dynamic>{
    'versionCourante': 'salle-examen-1',
    'versionReponses': null,
    'perime': false,
    'envoyeLe': null,
    'manquants': <String>['langueMaternelle'],
  },
  'cadreReligieux': <String, dynamic>{'versionRequise': 'c1', 'accepte': false},
  'conditionsRemuneration': <String, dynamic>{
    'disponible': true,
    'version': 'v2.0.0',
    'acceptees': false,
  },
  'paiement': 'a_verifier',
  'aCompleter': <String>['questionnaire', 'cadre_religieux'],
  'complementDemande': <String>['langues'],
  'peutEnvoyer': false,
  'envoiBloque': <String>['questionnaire_incomplet'],
};

void main() {
  group('CandidatureDossier.depuisJson', () {
    test(
      'une cle absente, nulle ou {candidature: false} : aucune candidature',
      () {
        expect(CandidatureDossier.depuisJson(null), CandidatureDossier.aucune);
        expect(
          CandidatureDossier.depuisJson(const <String, dynamic>{
            'candidature': false,
          }),
          CandidatureDossier.aucune,
        );
        expect(CandidatureDossier.depuisJson('x'), CandidatureDossier.aucune);
        expect(CandidatureDossier.aucune.existe, isFalse);
      },
    );

    test('la Salle d examen, a completer : le questionnaire s ouvre', () {
      final CandidatureDossier c = CandidatureDossier.depuisJson(_bloc());
      expect(c.existe, isTrue);
      expect(c.etape, EtapeCandidature.prequalification);
      expect(c.etat, EtatCandidature.aCompleter);
      expect(c.enSalleExamen, isTrue);
      expect(c.questionnaireOuvert, isTrue);
      expect(c.peutRetirer, isTrue);
      expect(c.version, 4);
      expect(c.cadre.publie, isTrue);
      expect(c.cadre.accepte, isFalse);
      expect(c.versionConditions, 'v2.0.0');
      expect(c.paiement, EtatVersement.aVerifier);
      expect(c.aCompleter, <String>['questionnaire', 'cadre_religieux']);
      expect(c.complementDemande, <String>['langues']);
      expect(c.repriseLe, DateTime(2026, 11, 3));
    });

    test('en pause, le questionnaire est ferme et le retrait reste permis', () {
      final CandidatureDossier c = CandidatureDossier.depuisJson(
        _bloc(enPause: true),
      );
      expect(c.questionnaireOuvert, isFalse);
      expect(c.peutRetirer, isTrue);
    });

    test('refusee ou retiree : plus de questionnaire, plus de retrait', () {
      for (final String issue in <String>['refusee', 'retiree']) {
        final CandidatureDossier c = CandidatureDossier.depuisJson(
          _bloc(issue: issue),
        );
        expect(c.questionnaireOuvert, isFalse, reason: issue);
        expect(c.peutRetirer, isFalse, reason: issue);
      }
    });

    test('en Salle des prets a enseigner, plus de retrait', () {
      final CandidatureDossier c = CandidatureDossier.depuisJson(
        _bloc(etape: 'confirmee', etat: null),
      );
      expect(c.peutRetirer, isFalse);
      expect(c.questionnaireOuvert, isFalse);
    });

    test('une valeur inconnue ne devient jamais une issue inventee', () {
      final CandidatureDossier c = CandidatureDossier.depuisJson(
        _bloc(issue: 'inconnue', etape: 'autre'),
      );
      expect(c.issue, IssueCandidature.enCours);
      expect(c.etape, isNull);
    });

    test(
      'versement pas encore possible : l etat que le serveur rend se lit',
      () {
        // `paiement_non_disponible` est une valeur de `candidatures.etat`
        // (transition 8 de L6) : lue comme telle, jamais ignoree en `null`.
        final CandidatureDossier c = CandidatureDossier.depuisJson(
          _bloc(etat: 'paiement_non_disponible')..['paiement'] = 'incompatible',
        );
        expect(c.etat, EtatCandidature.paiementNonDisponible);
        expect(c.enSalleExamen, isTrue);
        expect(c.questionnaireOuvert, isFalse);
        expect(c.peutRetirer, isTrue);
      },
    );

    test(
      'le serveur rend la cle du modele, pas son texte (lot L5 a venir)',
      () {
        // `etat_dossier()` rend `pauseModele` et `refusModele` (cles) : aucun
        // texte, donc rien a afficher, et jamais la cle elle-meme.
        final Map<String, dynamic> brut = _bloc(enPause: true)
          ..['pauseModele'] = 'pause_attente_besoin'
          ..['refusModele'] = null;
        final CandidatureDossier c = CandidatureDossier.depuisJson(brut);
        expect(c.pauseTexte, isNull);
        expect(c.refusTexte, isNull);
      },
    );

    test('le texte d un modele se lit mot pour mot, jamais un motif', () {
      final Map<String, dynamic> brut = _bloc(enPause: true)
        ..['pauseTexte'] = 'Votre candidature est en pause.'
        ..['refusTexte'] = '   '
        ..['motifInterne'] = 'ne jamais montrer';
      final CandidatureDossier c = CandidatureDossier.depuisJson(brut);
      expect(c.pauseTexte, 'Votre candidature est en pause.');
      expect(c.refusTexte, isNull);
    });

    test(
      'etat_dossier porte la candidature, et un serveur d avant ce lot non',
      () {
        final EtatDossier avec = EtatDossier.depuisJson(<String, dynamic>{
          'profil': true,
          'role': 'teacher',
          'statut': 'pending_kyc',
          'candidature': _bloc(),
        });
        expect(avec.candidature.existe, isTrue);
        final EtatDossier sans = EtatDossier.depuisJson(const <String, dynamic>{
          'profil': true,
          'role': 'teacher',
          'statut': 'pending_kyc',
        });
        expect(sans.candidature, CandidatureDossier.aucune);
      },
    );
  });

  group('ConditionsRemuneration.depuisJson', () {
    test('la part vient du serveur, par public, en pour mille', () {
      final ConditionsRemuneration c = ConditionsRemuneration.depuisJson(
        const <String, dynamic>{
          'disponible': true,
          'version': 'v2.0.0',
          'dateEffet': '2026-11-01',
          'enVigueur': false,
          'publics': <Map<String, Object>>[
            <String, Object>{'public': 'enfant', 'partPourMille': 470},
            <String, Object>{'public': 'adulte', 'partPourMille': 470},
          ],
        },
      );
      expect(c.version, 'v2.0.0');
      expect(c.dateEffet, DateTime(2026, 11, 1));
      expect(c.enVigueur, isFalse);
      expect(c.publics.length, 2);
      expect(c.partUnique, isTrue);
    });

    test('aucun montant n est lu, meme si le serveur en rendait encore', () {
      final ConditionsRemuneration c = ConditionsRemuneration.depuisJson(
        const <String, dynamic>{
          'version': 'v2.0.0',
          'devise': 'USD',
          'publics': <Map<String, Object>>[
            <String, Object>{
              'public': 'enfant',
              'partPourMille': 470,
              'parElevePresentEtParHeure': 1.99,
            },
          ],
        },
      );
      expect(c.publics.single.partPourMille, 470);
      // Le modele ne porte aucun champ de montant ni de devise.
      expect(c.toString(), isNot(contains('1.99')));
      expect(c.toString(), isNot(contains('USD')));
    });

    test('deux parts differentes : une ligne par public', () {
      final ConditionsRemuneration c = ConditionsRemuneration.depuisJson(
        const <String, dynamic>{
          'version': 'v3',
          'publics': <Map<String, Object>>[
            <String, Object>{'public': 'enfant', 'partPourMille': 470},
            <String, Object>{'public': 'adulte', 'partPourMille': 500},
          ],
        },
      );
      expect(c.partUnique, isFalse);
    });
  });

  group('Questionnaire.depuisJson', () {
    test('les champs, leurs types, leurs bornes et leurs listes', () {
      final Questionnaire q = Questionnaire.depuisJson(
        questionnaireJsonDeTest(
          versionBrouillon: 2,
          dernieresReponses: <String, Object?>{'langueMaternelle': 'poular'},
        ),
      );
      expect(q.version, 'salle-examen-1');
      expect(q.candidatureVersion, 3);
      expect(q.versionBrouillon, 2);
      expect(q.champs.length, 17);
      expect(q.champ('languesExplication')!.type, TypeChamp.choixMultiple);
      // Aucun plafond de langues d'explication (decision du directeur, 22/10).
      expect(q.champ('languesExplication')!.max, isNull);
      expect(q.champ('langueMaternelle')!.requis, isFalse);
      expect(q.champ('publics')!.max, 4);
      expect(q.champ('moyensAccessibles')!.requis, isFalse);
      expect(q.champ('operateurs')!.dependDe, 'paysVersement');
      expect(q.champ('operateurs')!.requis, isFalse);
      expect(q.champ('compteBancaire')!.type, TypeChamp.booleen);
      expect(q.champ('disponibilitesDeclarees')!.type, TypeChamp.creneaux);
      expect(q.cartes, <String>[
        'langues',
        'recitation',
        'disponibilites',
        'publics',
        'versement',
      ]);
      expect(q.dernieresReponses!.brouillon, isTrue);
      expect(q.dernieresReponses!.reponses['langueMaternelle'], 'poular');
    });

    test('une langue hors referentiel est marquee, une du referentiel non', () {
      final Questionnaire q = Questionnaire.depuisJson(
        questionnaireJsonDeTest(),
      );
      final List<OptionQuestionnaire> langues = q
          .champ('langueMaternelle')!
          .options;
      expect(
        langues
            .firstWhere((OptionQuestionnaire o) => o.code == 'poular')
            .horsReferentiel,
        isFalse,
      );
      expect(
        langues
            .firstWhere((OptionQuestionnaire o) => o.code == 'wo')
            .horsReferentiel,
        isTrue,
      );
    });

    test(
      'les moyens de paiement connus portent leur nom propre et leur methode',
      () {
        final Questionnaire q = Questionnaire.depuisJson(
          questionnaireJsonDeTest(),
        );
        final List<OptionQuestionnaire> moyens = q
            .champ('moyensAccessibles')!
            .options;
        expect(moyens.map((OptionQuestionnaire o) => o.code), <String>[
          'wave',
          'orange_money',
          'moov_money',
        ]);
        expect(moyens.first.nom, 'Wave');
        expect(moyens.first.methode, 'mobile_money');
        // Une option de langue n'a ni nom ni methode : son texte vient de i18n.
        expect(q.champ('languesExplication')!.options.first.nom, isNull);
      },
    );

    test('le nombre de Classes propose va de 1 au maximum de la direction', () {
      for (final int max in <int>[1, 3, 5]) {
        final Questionnaire q = Questionnaire.depuisJson(
          questionnaireJsonDeTest(classesMax: max),
        );
        expect(
          q
              .champ('classesSouhaitees')!
              .options
              .map((OptionQuestionnaire o) => o.code)
              .toList(),
          <String>[for (int n = 1; n <= max; n++) '$n'],
        );
      }
    });

    test('un champ de type inconnu est ecarte, jamais devine', () {
      final Map<String, dynamic> json = questionnaireJsonDeTest();
      (json['champs'] as List<Map<String, dynamic>>).add(<String, dynamic>{
        'code': 'photo',
        'carte': 'x',
        'type': 'fichier',
        'requis': true,
      });
      expect(Questionnaire.depuisJson(json).champ('photo'), isNull);
    });
  });
}
