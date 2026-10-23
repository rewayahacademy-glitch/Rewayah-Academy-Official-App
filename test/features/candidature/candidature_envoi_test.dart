// CAND-01 : la relecture, les conditions de remuneration (en pourcentage,
// jamais un montant), le cadre religieux, l'envoi et chacun de ses refus, la
// lecture seule apres l'envoi, l'arabe de droite a gauche.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/port_ma_candidature.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/candidature/recapitulatif_etape.dart';

import '../../fixtures/candidature/faux_ma_candidature.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';
import 'hote_candidature.dart';

/// Un port dont l'envoi reussi change ce que le dossier rend, comme le serveur.
class _PortQuiAvance extends FauxMaCandidature {
  _PortQuiAvance(this.dossier);

  final FauxServiceDossier dossier;

  @override
  Future<CandidatureDossier> envoyerReponses({
    required String versionQuestionnaire,
    required Map<String, Object?> reponses,
    required bool accordRemuneration,
    required String versionConditions,
    required int versionAttendue,
    required String cleIdempotence,
  }) async {
    final CandidatureDossier c = await super.envoyerReponses(
      versionQuestionnaire: versionQuestionnaire,
      reponses: reponses,
      accordRemuneration: accordRemuneration,
      versionConditions: versionConditions,
      versionAttendue: versionAttendue,
      cleIdempotence: cleIdempotence,
    );
    dossier.etatRendu = etatCandidat(candidature: c);
    return c;
  }
}

Finder _texte(String t) => find.text(t);

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

/// Monte le parcours et le mene jusqu'au recapitulatif.
Future<void> _auRecapitulatif(
  WidgetTester tester,
  FauxMaCandidature port, {
  EtatDossier? etat,
  Size taille = const Size(390, 844),
  bool horsLigne = false,
  FauxServiceDossier? dossier,
}) async {
  await monterQuestionnaire(
    tester,
    port: port,
    etat: etat,
    taille: taille,
    horsLigne: horsLigne,
    dossier: dossier,
  );
  await repondreJusqua(tester, parcoursComplet.length);
  expect(_texte(t.recrutement.parcours.recap.titre), findsOneWidget);
}

/// Coche la case des conditions, puis envoie.
Future<void> _cocherEtEnvoyer(WidgetTester tester) async {
  await toucherCle(tester, 'recap-accord');
  await continuer(tester);
}

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('le recapitulatif', () {
    testWidgets('chaque reponse est une carte touchable, dans son theme', (
      WidgetTester tester,
    ) async {
      await _auRecapitulatif(tester, FauxMaCandidature());
      for (final String code in <String>[
        'langueMaternelle',
        'languesExplication',
        'niveauMemorisationDeclare',
        'riwayat',
        'ijazaPresentable',
        'disponibilitesDeclarees',
        'classesSouhaitees',
        'publics',
        'paysResidence',
        'paysVersement',
        'compteBancaire',
        'operateurs',
        'moyensAccessibles',
      ]) {
        expect(
          find.byKey(CartesRecapitulatif.ligneKey(code)),
          findsOneWidget,
          reason: code,
        );
      }
      expect(_texte(t.recrutement.questionnaire.langues), findsOneWidget);
      expect(_texte(t.recrutement.questionnaire.versement), findsOneWidget);
      // Aucun code brut n'est lu a l'ecran.
      expect(find.text('de_10_a_29_juz'), findsNothing);
      expect(find.text('6_9'), findsNothing);
      expect(find.text('wave'), findsNothing);
      expect(find.text('orange_money'), findsNothing);
      expect(find.text('GN'), findsNothing);
    });

    testWidgets(
      'toucher une reponse la rouvre, puis revient au recapitulatif',
      (WidgetTester tester) async {
        await _auRecapitulatif(tester, FauxMaCandidature());
        await toucherCle(tester, 'recap-publics');
        expect(_texte(t.recrutement.parcours.q.publics.titre), findsOneWidget);
        // La reponse deja donnee est retenue.
        await toucherCle(tester, 'option-publics-adultes');
        await continuer(tester);
        expect(_texte(t.recrutement.parcours.recap.titre), findsOneWidget);
      },
    );

    testWidgets(
      'les disponibilites se relisent par jour, en heures de debut',
      (WidgetTester tester) async {
        await _auRecapitulatif(tester, FauxMaCandidature());
        final Finder ligne = _cle('recap-disponibilitesDeclarees');
        expect(ligne, findsOneWidget);
        expect(
          find.descendant(
            of: ligne,
            matching: find.text(t.recrutement.parcours.recap.jours(n: 3)),
          ),
          findsOneWidget,
        );
        // Trois jours, les memes heures de debut : un seul groupe, une ligne.
        final Finder groupe = _cle('recap-disponibilitesDeclarees-0');
        expect(groupe, findsOneWidget);
        expect(_cle('recap-disponibilitesDeclarees-1'), findsNothing);
        expect(
          find.descendant(
            of: groupe,
            matching: find.text('Lundi, mercredi et vendredi'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: groupe,
            matching: find.text(
              t.recrutement.parcours.creneaux.debutsDuJour(
                heures: '18\u00a0h, 19\u00a0h',
              ),
            ),
          ),
          findsOneWidget,
        );
        // Toucher la ligne mene aux ecrans des disponibilites.
        await toucherCle(tester, 'recap-disponibilitesDeclarees-0');
        expect(
          _texte(t.recrutement.parcours.q.disponibilitesDeclarees.titre),
          findsOneWidget,
        );
      },
    );

    testWidgets('« Retour » du recapitulatif revient a la derniere question', (
      WidgetTester tester,
    ) async {
      await _auRecapitulatif(tester, FauxMaCandidature());
      await toucherCle(tester, 'parcours-retour');
      expect(
        _texte(t.recrutement.parcours.q.moyensAccessibles.titre),
        findsOneWidget,
      );
    });

    testWidgets('un seul bouton plein, a 390 comme a 1440', (
      WidgetTester tester,
    ) async {
      await _auRecapitulatif(tester, FauxMaCandidature());
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('a 1440 le recapitulatif est une grille, sans carte etiree', (
      WidgetTester tester,
    ) async {
      await _auRecapitulatif(
        tester,
        FauxMaCandidature(),
        taille: const Size(1440, 900),
      );
      final Rect a = tester.getRect(
        find.byKey(CartesRecapitulatif.ligneKey('langueMaternelle')),
      );
      final Rect b = tester.getRect(
        find.byKey(CartesRecapitulatif.ligneKey('publics')),
      );
      expect(a.width, lessThan(1000));
      expect(b.width, lessThan(1000));
      verifierUnSeulBoutonPlein(tester);
    });
  });

  group('les conditions de remuneration', () {
    testWidgets('en pourcentage, par public, sans aucun montant', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature(
        conditions: const ConditionsRemuneration(
          version: 'v2.0.0',
          enVigueur: true,
          publics: <PublicRemuneration>[
            PublicRemuneration(code: 'enfant', partPourMille: 470),
            PublicRemuneration(code: 'adulte', partPourMille: 500),
          ],
        ),
      );
      await _auRecapitulatif(tester, port);
      await tester.ensureVisible(_cle('conditions-carte'));
      await tester.pump();
      expect(_cle('conditions-carte'), findsOneWidget);
      expect(
        _texte(
          t.recrutement.questionnaire.partPublic(
            public: t.recrutement.questionnaire.publicEnfant,
            part: '47 %',
          ),
        ),
        findsOneWidget,
      );
      expect(
        _texte(
          t.recrutement.questionnaire.partPublic(
            public: t.recrutement.questionnaire.publicAdulte,
            part: '50 %',
          ),
        ),
        findsOneWidget,
      );
      // Aucun montant, aucune devise, aucun taux par heure.
      expect(find.textContaining(r'$'), findsNothing);
      expect(find.textContaining('USD'), findsNothing);
      expect(find.textContaining('1,99'), findsNothing);
      expect(find.textContaining('1,57'), findsNothing);
      expect(find.textContaining('par heure'), findsNothing);
      expect(
        _texte(t.recrutement.questionnaire.montantsSurDemande),
        findsOneWidget,
      );
      expect(
        _texte(t.recrutement.questionnaire.coordonneesPlusTard),
        findsOneWidget,
      );
    });

    testWidgets(
      'la clause de continuite est dans la carte des conditions acceptees',
      (WidgetTester tester) async {
        await _auRecapitulatif(tester, FauxMaCandidature());
        await tester.ensureVisible(_cle('conditions-carte'));
        await tester.pump();
        final Finder clause = find.descendant(
          of: _cle('conditions-carte'),
          matching: _cle('conditions-continuite'),
        );
        expect(clause, findsOneWidget);
        expect(
          _texte(t.recrutement.questionnaire.continuite),
          findsOneWidget,
        );
        // Les jours et les heures de la Classe, chaque semaine : l'engagement
        // decide par le directeur le 22/10, dit avant la case a cocher.
        expect(
          t.recrutement.questionnaire.continuite,
          allOf(contains('mêmes jours'), contains('mêmes heures')),
        );
        expect(
          tester.getTopLeft(clause).dy,
          lessThan(tester.getTopLeft(_cle('recap-accord')).dy),
        );
      },
    );

    testWidgets(
      'la carte dit par quel moyen la personne est payee, avant la case',
      (WidgetTester tester) async {
        await _auRecapitulatif(tester, FauxMaCandidature());
        await tester.ensureVisible(_cle('conditions-carte'));
        await tester.pump();
        // SPEC 4.2 : la case ne porte plus que sur les conditions ; le moyen
        // de versement valide par Rewayah s'y lit donc.
        final Finder phrase = find.descendant(
          of: _cle('conditions-carte'),
          matching: _cle('conditions-moyen-valide'),
        );
        expect(phrase, findsOneWidget);
        expect(
          _texte(t.recrutement.questionnaire.moyenValide),
          findsOneWidget,
        );
        expect(
          tester.getTopLeft(phrase).dy,
          lessThan(tester.getTopLeft(_cle('recap-accord')).dy),
        );
      },
    );

    testWidgets('une seule part pour tous : une seule phrase', (
      WidgetTester tester,
    ) async {
      await _auRecapitulatif(tester, FauxMaCandidature());
      await tester.ensureVisible(_cle('conditions-carte'));
      await tester.pump();
      expect(_cle('conditions-part-tous'), findsOneWidget);
      expect(
        _texte(t.recrutement.questionnaire.part(part: '47 %')),
        findsOneWidget,
      );
    });

    testWidgets('des conditions pas encore en vigueur disent leur date', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature(
        conditions: ConditionsRemuneration(
          version: 'v3.0.0',
          enVigueur: false,
          dateEffet: DateTime(2026, 12, 1),
          publics: const <PublicRemuneration>[
            PublicRemuneration(code: 'enfant', partPourMille: 470),
          ],
        ),
      );
      await _auRecapitulatif(tester, port);
      await tester.ensureVisible(_cle('conditions-carte'));
      await tester.pump();
      expect(find.textContaining('01/12/2026'), findsOneWidget);
    });

    testWidgets('sans la case, « Envoyer » dit quoi faire et n envoie rien', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature();
      await _auRecapitulatif(tester, port);
      // Le bouton n'est jamais grise : il dit ce qui manque.
      expect(_texte(t.recrutement.questionnaire.envoyer), findsOneWidget);
      await continuer(tester);
      expect(
        _texte(t.recrutement.questionnaire.accordManquant),
        findsOneWidget,
      );
      expect(port.envois, isEmpty);
    });

    testWidgets(
      'des conditions illisibles : la phrase et « Reessayer », pas d envoi',
      (WidgetTester tester) async {
        final FauxMaCandidature casse = FauxMaCandidature()
          ..erreurConditions = Exception('boum');
        await monterQuestionnaire(tester, port: casse);
        await repondreJusqua(tester, parcoursComplet.length);
        expect(
          _texte(t.recrutement.questionnaire.conditionsNonCharge),
          findsOneWidget,
        );
        expect(_texte(t.commun.reessayer), findsOneWidget);
        expect(_texte(t.recrutement.questionnaire.envoyer), findsNothing);
        casse.erreurConditions = null;
        await tester.ensureVisible(_texte(t.commun.reessayer));
        await tester.pump();
        await tester.tap(_texte(t.commun.reessayer));
        await tester.pumpAndSettle();
        expect(_cle('conditions-carte'), findsOneWidget);
        expect(_texte(t.recrutement.questionnaire.envoyer), findsOneWidget);
      },
    );
  });

  group('le cadre religieux et pedagogique', () {
    testWidgets('accepte : l envoi est possible', (WidgetTester tester) async {
      await _auRecapitulatif(tester, FauxMaCandidature());
      await tester.ensureVisible(_cle('cadre-carte'));
      await tester.pump();
      expect(_texte(t.recrutement.questionnaire.cadreAccepte), findsOneWidget);
      expect(_texte(t.recrutement.questionnaire.envoyer), findsOneWidget);
    });

    testWidgets(
      'publie mais pas accepte : le lien vers les accords, pas d envoi',
      (WidgetTester tester) async {
        await _auRecapitulatif(
          tester,
          FauxMaCandidature(),
          etat: etatCandidat(
            candidature: candidatureAFaire(cadreAccepte: false),
          ),
        );
        await tester.ensureVisible(_cle('cadre-carte'));
        await tester.pump();
        expect(_cle('cadre-lien'), findsOneWidget);
        expect(_texte(t.recrutement.questionnaire.envoyer), findsNothing);
        await toucherCle(tester, 'cadre-lien');
        expect(_texte('PAGE DES ACCORDS'), findsOneWidget);
      },
    );

    testWidgets('pas encore publie : le recapitulatif le dit, pas d envoi', (
      WidgetTester tester,
    ) async {
      await _auRecapitulatif(
        tester,
        FauxMaCandidature(),
        etat: etatCandidat(
          candidature: candidatureAFaire(
            cadrePublie: false,
            cadreAccepte: false,
          ),
        ),
      );
      await tester.ensureVisible(_cle('cadre-carte'));
      await tester.pump();
      expect(_texte(t.accords.cadreNonPublie), findsWidgets);
      expect(_texte(t.recrutement.questionnaire.envoyer), findsNothing);
    });
  });

  group('l envoi', () {
    testWidgets(
      'envoie les reponses, la version des conditions, la cle ; puis le portail',
      (WidgetTester tester) async {
        final FauxServiceDossier dossier = FauxServiceDossier()
          ..etatRendu = etatCandidat(candidature: candidatureAFaire());
        final _PortQuiAvance port = _PortQuiAvance(dossier);
        await _auRecapitulatif(tester, port, dossier: dossier);
        await _cocherEtEnvoyer(tester);
        expect(port.envois, hasLength(1));
        final EnvoiVu envoi = port.envois.single;
        expect(envoi.versionQuestionnaire, 'salle-examen-1');
        expect(envoi.accordRemuneration, isTrue);
        expect(envoi.versionConditions, 'v2.0.0');
        expect(envoi.versionAttendue, 3);
        expect(envoi.cleIdempotence, startsWith('cand-'));
        expect(envoi.reponses['langueMaternelle'], 'poular');
        expect(envoi.reponses['paysVersement'], 'GN');
        expect(envoi.reponses['compteBancaire'], false);
        expect(envoi.reponses['operateurs'], <String>['orange_money']);
        // Les disponibilites partent dans la forme du serveur : des plages
        // d'heures entieres, sans fuseau (le fuseau est celui de fuseauIana).
        expect(envoi.reponses['fuseauIana'], isNotNull);
        expect(
          envoi.reponses['disponibilitesDeclarees'],
          <Map<String, Object?>>[
            <String, Object?>{'jour': 1, 'debut': '18:00', 'fin': '20:00'},
            <String, Object?>{'jour': 3, 'debut': '18:00', 'fin': '20:00'},
            <String, Object?>{'jour': 5, 'debut': '18:00', 'fin': '20:00'},
          ],
        );
        expect(envoi.reponses['classesSouhaitees'], '1');
        expect(envoi.reponses['publics'], <String>['6_9']);
        expect(envoi.reponses['ijazaPresentable'], 'non');
        expect(envoi.reponses['moyensAccessibles'], <String>['wave']);
        // Le portail dit la suite, apres la reponse du serveur.
        expect(_texte(t.recrutement.portail.enExamenTitre), findsOneWidget);
      },
    );

    testWidgets(
      'pendant l envoi le bouton est en cours et la case ne bouge plus',
      (WidgetTester tester) async {
        final FauxMaCandidature port = FauxMaCandidature();
        final Completer<void> attente = Completer<void>();
        port.attenteEnvoi = attente;
        await _auRecapitulatif(tester, port);
        await toucherCle(tester, 'recap-accord');
        await tester.ensureVisible(_cle('parcours-action'));
        await tester.tap(_cle('parcours-action'));
        await tester.pump();
        expect(port.envois, hasLength(1));
        // Un second geste n'envoie pas deux fois.
        await tester.tap(_cle('parcours-action'), warnIfMissed: false);
        await tester.pump();
        expect(port.envois, hasLength(1));
        attente.complete();
        await tester.pumpAndSettle();
      },
    );

    for (final (String nom, Object erreur, String message)
        in <(String, Object, String)>[
          ('questionnaire perime', const QuestionnairePerime(null), 'perime'),
          ('conflit de version', const ConflitCandidature(5), 'conflit'),
          ('transition interdite', const TransitionInterdite(), 'interdit'),
          (
            'permission insuffisante',
            const PermissionInsuffisante('envoyer'),
            'interdit',
          ),
          (
            'capacite indisponible',
            const CapaciteIndisponible(dependanceCandidature),
            'nonOuverte',
          ),
          ('accord requis', const AccordRemunerationRequis(), 'accordManquant'),
          (
            'conditions perimees',
            const ConditionsPerimees(null),
            'conditionsPerimees',
          ),
          (
            'cadre non accepte',
            const EngagementNonAccepte(publie: true),
            'cadreManquant',
          ),
        ]) {
      testWidgets(
        'refus « $nom » : une phrase, jamais un code, rien de perdu',
        (WidgetTester tester) async {
          final FauxMaCandidature port = FauxMaCandidature()
            ..erreurEnvoi = erreur;
          await _auRecapitulatif(tester, port);
          await _cocherEtEnvoyer(tester);
          final r = t.recrutement.questionnaire;
          final String attendu = switch (message) {
            'perime' => r.perime,
            'conflit' => r.conflit,
            'interdit' => r.interdit,
            'nonOuverte' => r.nonOuverte,
            'accordManquant' => r.accordManquant,
            'conditionsPerimees' => r.conditionsPerimees,
            'cadreManquant' => r.cadreManquant,
            _ => throw StateError(message),
          };
          expect(find.byKey(RecapitulatifEtape.messageKey), findsOneWidget);
          expect(_texte(attendu), findsOneWidget);
          // On reste sur le recapitulatif, les reponses gardees.
          expect(_texte(t.recrutement.parcours.recap.titre), findsOneWidget);
          expect(find.textContaining('Exception'), findsNothing);
          expect(find.textContaining('P0001'), findsNothing);
        },
      );
    }

    testWidgets(
      'des conditions perimees decochent la case et relisent les conditions',
      (WidgetTester tester) async {
        final FauxMaCandidature port = FauxMaCandidature()
          ..erreurEnvoi = const ConditionsPerimees(null);
        await _auRecapitulatif(tester, port);
        // Le serveur a publie de nouvelles conditions entre-temps.
        port.conditions = const ConditionsRemuneration(
          version: 'v3.0.0',
          enVigueur: true,
          publics: <PublicRemuneration>[
            PublicRemuneration(code: 'enfant', partPourMille: 470),
          ],
        );
        await _cocherEtEnvoyer(tester);
        expect(
          _texte(t.recrutement.questionnaire.conditionsPerimees),
          findsOneWidget,
        );
        // La case est decochee : « Envoyer » demande de la recocher.
        await continuer(tester);
        expect(port.envois, hasLength(1));
        expect(
          _texte(t.recrutement.questionnaire.accordManquant),
          findsOneWidget,
        );
        await toucherCle(tester, 'recap-accord');
        await continuer(tester);
        expect(port.envois, hasLength(2));
        expect(port.envois.last.versionConditions, 'v3.0.0');
      },
    );

    testWidgets('des reponses incompletes ramenent a la question nommee', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature()
        ..erreurEnvoi = const ReponsesIncompletes(<String>['publics']);
      await _auRecapitulatif(tester, port);
      await _cocherEtEnvoyer(tester);
      expect(_texte(t.recrutement.parcours.q.publics.titre), findsOneWidget);
      // Ce que le serveur reclame se lit sur la question rouverte.
      expect(
        _texte(
          t.recrutement.questionnaire.incomplet(
            question: t.recrutement.parcours.q.publics.court,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('une reponse invalide ramene a la question nommee', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature()
        ..erreurEnvoi = const ReponsesInvalides(<String>['classesSouhaitees']);
      await _auRecapitulatif(tester, port);
      await _cocherEtEnvoyer(tester);
      expect(
        _texte(t.recrutement.parcours.q.classesSouhaitees.titre),
        findsOneWidget,
      );
    });

    testWidgets(
      'des plages qui se chevauchent : la cause est dite sur les '
      'disponibilites rouvertes',
      (WidgetTester tester) async {
        final FauxMaCandidature port = FauxMaCandidature()
          ..erreurEnvoi = const ReponsesInvalides(
            <String>['disponibilitesDeclarees'],
            motifs: <String, String>{
              'disponibilitesDeclarees': 'plages_qui_se_chevauchent',
            },
          );
        await _auRecapitulatif(tester, port);
        await _cocherEtEnvoyer(tester);
        expect(
          _texte(t.recrutement.parcours.q.disponibilitesDeclarees.titre),
          findsOneWidget,
        );
        expect(
          _texte(t.recrutement.questionnaire.plagesChevauchent),
          findsOneWidget,
        );
        // Un geste de la personne efface la phrase.
        await continuer(tester);
        expect(
          _texte(t.recrutement.questionnaire.plagesChevauchent),
          findsNothing,
        );
      },
    );

    testWidgets('hors ligne au moment d envoyer : meme cle au second essai', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature()
        ..erreurEnvoi = const HorsLigneCandidature();
      await _auRecapitulatif(tester, port);
      await _cocherEtEnvoyer(tester);
      expect(_texte(t.recrutement.questionnaire.incertain), findsOneWidget);
      await continuer(tester);
      expect(port.envois, hasLength(2));
      expect(port.envois.last.cleIdempotence, port.envois.first.cleIdempotence);
    });

    testWidgets('un refus net change la cle du prochain essai', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature()
        ..erreurEnvoi = const ConflitCandidature(5);
      await _auRecapitulatif(tester, port);
      await _cocherEtEnvoyer(tester);
      await continuer(tester);
      expect(port.envois, hasLength(2));
      expect(
        port.envois.last.cleIdempotence,
        isNot(port.envois.first.cleIdempotence),
      );
    });

    testWidgets('une erreur inconnue ne dit pas que l envoi a echoue', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature()
        ..erreurEnvoi = StateError('boum');
      await _auRecapitulatif(tester, port);
      await _cocherEtEnvoyer(tester);
      expect(_texte(t.recrutement.questionnaire.incertain), findsOneWidget);
    });
  });

  group('hors ligne', () {
    testWidgets('au recapitulatif : pas de bouton d envoi, une note', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature();
      await _auRecapitulatif(tester, port, horsLigne: true);
      expect(_texte(t.reseau.horsLigne), findsOneWidget);
      expect(_texte(t.recrutement.questionnaire.envoyer), findsNothing);
      expect(_cle('recap-hors-ligne'), findsOneWidget);
      expect(port.envois, isEmpty);
    });
  });

  group('lecture seule apres l envoi', () {
    testWidgets('les reponses, la date, l etat du versement, un retour', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature(
        questionnaireJson: questionnaireJsonDeTest(
          dernieresReponses: reponsesCompletesDeTest(),
          brouillon: false,
        ),
      );
      await monterQuestionnaire(
        tester,
        port: port,
        etat: etatCandidat(
          candidature: CandidatureDossier(
            existe: true,
            etape: EtapeCandidature.prequalification,
            etat: EtatCandidature.enExamen,
            version: 4,
            paiement: EtatVersement.aVerifier,
            questionnaire: EtatQuestionnaire(envoyeLe: DateTime(2026, 10, 22)),
          ),
        ),
      );
      expect(_cle('lecture-envoyee'), findsOneWidget);
      expect(_texte(t.recrutement.questionnaire.envoyee), findsOneWidget);
      expect(_cle('lecture-versement'), findsOneWidget);
      expect(_cle('recap-publics'), findsOneWidget);
      // Rien ne se modifie ni ne s'envoie.
      expect(_cle('parcours-action'), findsNothing);
      expect(_cle('recap-accord'), findsNothing);
      await toucherCle(tester, 'lecture-retour');
      expect(_texte(t.recrutement.portail.enExamenTitre), findsOneWidget);
    });
  });

  group('l arabe, de droite a gauche', () {
    for (final Size taille in const <Size>[Size(390, 844), Size(320, 640)]) {
      testWidgets(
        'du parcours au recapitulatif a ${taille.width.toInt()} sans exception',
        (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
          final FauxMaCandidature port = FauxMaCandidature();
          await monterQuestionnaire(
            tester,
            port: port,
            taille: taille,
            echelle: 2,
            direction: TextDirection.rtl,
          );
          await repondreJusqua(tester, parcoursComplet.length);
          expect(tester.takeException(), isNull);
          expect(find.text(t.recrutement.parcours.recap.titre), findsOneWidget);
          // Le pourcentage reste lisible : le signe suit le nombre.
          await tester.ensureVisible(_cle('conditions-carte'));
          await tester.pump();
          expect(find.textContaining('47'), findsWidgets);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
