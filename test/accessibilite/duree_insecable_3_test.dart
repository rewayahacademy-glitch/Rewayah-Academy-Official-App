// DUREE-INSECABLE-3 : reserves de la relecture de DUREE-INSECABLE-2.
//
// 1. La garde de source juge chaque appel seul (test/support/garde_durees.dart) :
//    l'appel qui entoure immediatement un libelle a unite doit etre
//    `insecable` ou `valeurSeule`. La liste des libelles se deduit de
//    `assets/i18n/fr.i18n.json` : tout parametre suivi d'une unite.
// 2. Les valeurs rendues du silence et de l'attente de `LignePresence` sont
//    verifiees, pas seulement leur source.
// 3. L'ancre de sens (U+200E) n'est posee que la ou la valeur commence le
//    libelle. « Duree 45 min » (carte de groupe) et « Lundi 21 septembre ·
//    45 min » (derniere seance) commencent par un mot : aucune ancre au
//    milieu du texte.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/presence/vue_presence.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/tc_observation/guardian_observation_policy.dart';
import 'package:rewayah_academy/core/widgets/ligne_presence.dart';
import 'package:rewayah_academy/features/accueil_famille/bloc_seance.dart';
import 'package:rewayah_academy/features/admin_configuration_regles/regles_page.dart'
    show uniteMinutesRegle;
import 'package:rewayah_academy/features/consentements/explication_observation.dart';

import '../fixtures/tuteur/faux_seances_famille.dart';
import '../support/garde_durees.dart';

const String _nbsp = ' ';
const String _lrm = '‎';

PresenceParticipant _ligne(
  EtatPresence etat, {
  DateTime? entreLe,
  DateTime? debutSeance,
  DateTime? derniereTraceLe,
}) => PresenceParticipant(
  seanceId: 's1',
  profilId: 'enf-1',
  role: 'student',
  prenom: 'Sofia',
  identifiantImmuable: 'STUD-000001',
  etat: etat,
  consolide: false,
  entreLe: entreLe,
  debutSeance: debutSeance,
  derniereTraceLe: derniereTraceLe,
);

void main() {
  group('Garde de source, appel par appel', () {
    final List<String> cles = libellesAUnite();

    test('les libelles a unite sont deduits du francais', () {
      // Ceux que la relecture de DUREE-INSECABLE-2 a nommes en font partie.
      expect(
        cles,
        containsAll(<String>[
          'presence.silenceMinutes',
          'presence.attenteMinutes',
          'tc.observation.reglages.uniteSecondes',
          'commun.formats.minutes',
          'admin.regles.uniteMinutes',
          'consentement.comment.visites',
        ]),
      );
      // Un libelle ou « s » n'est pas une unite n'en fait pas partie.
      expect(cles, isNot(contains('historique.seances.videPhrase')));
    });

    test('chaque appel est enveloppe par insecable ou valeurSeule', () {
      final List<AppelLibelle> appels = appelsDe(cles, sourcesDartHorsCoran());
      expect(appels.length, greaterThan(50));
      final List<String> nus = <String>[
        for (final AppelLibelle a in appels)
          if (!estInsecable(a.enveloppe))
            '${a.fichier}:${a.ligne} ${a.cle} <${a.enveloppe}>',
      ];
      expect(nus, isEmpty, reason: 'Durees secables :\n${nus.join('\n')}');
    });

    test('DUREE-FOND-1 : une unite liee en francais l\'est aussi en arabe', () {
      // L'unite arabe (« كيلوبايت ») echappe au motif des unites : la garde
      // compare donc les deux langues, parametre par parametre.
      final List<String> fautes = unitesSecablesEnArabe();
      expect(
        fautes,
        isEmpty,
        reason: 'Unites secables en arabe :\n${fautes.join('\n')}',
      );
    });

    test('DUREE-FOND-1 : la parite de l\'arabe releve une espace ordinaire', () {
      final Directory dossier = Directory.systemTemp.createTempSync('parite');
      addTearDown(() => dossier.deleteSync(recursive: true));
      final File fr = File('${dossier.path}/fr.json')
        ..writeAsStringSync('{"p":{"ko":"{taille}\u00A0Ko","n":"{n} min"}}');
      final File ar = File('${dossier.path}/ar.json')
        ..writeAsStringSync(
          '{"p":{"ko":"{taille} كيلوبايت","n":"{n} دقيقة"}}',
        );
      expect(unitesSecablesEnArabe(francais: fr.path, arabe: ar.path), <String>[
        'p.ko {taille} : {taille} كيلوبايت',
      ]);
      ar.writeAsStringSync(
        '{"p":{"ko":"{taille}\u00A0كيلوبايت","n":"{n} دقيقة"}}',
      );
      expect(unitesSecablesEnArabe(francais: fr.path, arabe: ar.path), isEmpty);
    });

    test('la garde suit les alias (final h = t.controleur.historique)', () {
      final Directory dossier = Directory.systemTemp.createTempSync('garde');
      addTearDown(() => dossier.deleteSync(recursive: true));
      final File f = File('${dossier.path}/x.dart')
        ..writeAsStringSync('''
String a() {
  final h = t.controleur.historique;
  return LibellesGroupe.insecable(h.duree(minutes: 4));
}
String b() {
  final h = t.controleur.historique;
  return Text(h.duree(minutes: 4)) + LibellesGroupe.insecable('x');
}
''');
      final List<AppelLibelle> appels = appelsDe(
        <String>['controleur.historique.duree'],
        <File>[f],
      );
      expect(appels.map((AppelLibelle a) => estInsecable(a.enveloppe)), <bool>[
        true,
        false,
      ]);
    });
  });

  group('LignePresence : valeurs rendues', () {
    final DateTime debut = DateTime.utc(2026, 10, 5, 18);

    test('silence : « sans nouvelles depuis 12 min » insecable', () {
      final String? silence = LignePresence.contexte(
        VuePresence.depuis(
          ligne: _ligne(
            EtatPresence.deconnectee,
            entreLe: debut,
            derniereTraceLe: debut,
          ),
          maintenant: debut.add(const Duration(minutes: 12)),
        ),
      );
      expect(silence, 'sans nouvelles depuis 12${_nbsp}min');
    });

    test('attente : « le cours a commence il y a 12 min » insecable', () {
      final String? attente = LignePresence.contexte(
        VuePresence.depuis(
          ligne: _ligne(EtatPresence.enAttente, debutSeance: debut),
          maintenant: debut.add(const Duration(minutes: 12)),
        ),
      );
      expect(attente, 'le cours a commencé il y a 12${_nbsp}min');
    });
  });

  group('Durees et unites restantes : valeurs rendues', () {
    // DUREE-INSECABLE-4 : le rappel se verifiait sur la fiche de seance de
    // l'ancienne Classe Live, supprimee le 17/10/2026 (DECISION-ENTREE).

    test('regles de l academie : « 45 min » insecable et ancree', () {
      expect(uniteMinutesRegle(45), '${_lrm}45${_nbsp}min');
    });

    test('consentement : « 2 visites de 2 min par seance » insecable', () {
      final List<String> lignes = phrasesExplication(
        const GuardianObservationPolicy.defautsNormatifs(policyVersion: 'v1'),
      );
      expect(lignes.first, contains('2${_nbsp}min'));
      expect(lignes.first, isNot(contains('2 min')));
    });
  });

  group('Ancre de sens : seulement en tete de libelle', () {
    test('carte de groupe : « Duree 45 min », sans ancre au milieu', () {
      final String carte = LibellesGroupe.dureeCarte(
        const Duration(minutes: 45),
      );
      expect(carte, 'Durée 45${_nbsp}min');
      expect(carte, isNot(contains(_lrm)));
    });

    test('valeur qui commence le libelle : ancree', () {
      expect(
        LibellesGroupe.dureeSeule(const Duration(minutes: 45)),
        '${_lrm}45${_nbsp}min',
      );
      expect(LibellesGroupe.valeurSeule('45 min'), '${_lrm}45${_nbsp}min');
    });

    test('derniere seance : date puis duree, sans ancre au milieu', () {
      final AffichageSeance affichage = AffichageSeance.depuis(
        seanceFictive(
          debutUtc: instantServeurFige.subtract(const Duration(days: 2)),
          statut: StatutSeance.terminee,
          heureFoyer: heureRendue('Europe/Paris', 'Paris', '18:00'),
        ),
        maintenantServeurUtc: instantServeurFige,
      );
      expect(affichage.dateEtDuree, 'Lundi 21 septembre · 45${_nbsp}min');
      expect(affichage.dateEtDuree, isNot(contains(_lrm)));
      // La duree affichee seule, elle, reste ancree.
      expect(affichage.duree, '${_lrm}45${_nbsp}min');
    });

    test('aucune duree ancree glissee dans un autre libelle (source)', () {
      final List<String> fautes = <String>[];
      final RegExp ancree = RegExp(
        r'(?<![\w.])(?:LibellesGroupe\.)?(dureeSeule|valeurSeule|ancreSens)\(',
      );
      for (final File f in sourcesDart()) {
        final String source = f.readAsStringSync();
        for (final RegExpMatch m in ancree.allMatches(source)) {
          final String autour = enveloppe(source, m.start);
          if (autour.startsWith('t.') || autour == 'LibellesGroupe.duree') {
            final int ligne =
                '\n'.allMatches(source.substring(0, m.start)).length + 1;
            fautes.add('${f.path}:$ligne <$autour>');
          }
        }
      }
      expect(fautes, isEmpty, reason: fautes.join('\n'));
    });
  });
}
