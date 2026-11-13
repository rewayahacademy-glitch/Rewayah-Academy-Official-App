// SUIVI-ATTENTE : le modele et la projection de la lecture serveur.
//
// Ce que le test prouve :
// - cinq etapes, toujours les memes, rangees dans l'ordre ;
// - aucun enseignant avant l'etape 4 (S4), meme si la source le fournit ;
// - un instant UTC est refuse, jamais pris pour une heure du foyer ;
// - la projection de `suivi_attente_foyer()` : etapes, delai, cas, carte de
//   l'enseignant, creneau ; une ligne invalide leve une erreur (jamais un
//   suivi devine) ; un enseignant qui ne montre rien n'a ni photo ni pays.
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/attente_classe/attente_supabase.dart';
import 'package:rewayah_academy/core/attente_classe/modele_attente.dart';

import '../../support/attente_donnees.dart';

Map<String, dynamic> _ligne({
  String cas = 'chemin',
  List<Map<String, dynamic>>? etapes,
  Object? enseignant,
  Object? delai,
}) => <String, dynamic>{
  'demande_id': 'd1',
  'eleve_id': 'e1',
  'prenom': 'Yusuf',
  'type_public': 'enfant',
  'version_simple': false,
  'fuseau_iana': 'Europe/Paris',
  'cas': cas,
  'motif': null,
  'occurrences': <Map<String, dynamic>>[
    <String, dynamic>{'jour_iso': 1, 'heure': 18, 'minute': 0},
    <String, dynamic>{'jour_iso': 3, 'heure': 18, 'minute': 0},
  ],
  'etapes':
      etapes ??
      <Map<String, dynamic>>[
        <String, dynamic>{
          'numero': 1,
          'statut': 'fait',
          'le': '2026-11-09T10:15:00',
        },
        <String, dynamic>{'numero': 2, 'statut': 'en_cours', 'le': null},
        <String, dynamic>{'numero': 3, 'statut': 'a_venir', 'le': null},
        <String, dynamic>{'numero': 4, 'statut': 'a_venir', 'le': null},
        <String, dynamic>{'numero': 5, 'statut': 'a_venir', 'le': null},
      ],
  'delai': delai,
  'classe': null,
  'premier_cours': null,
  'premier_cours_passe': false,
  'creneau_change_le': null,
  'enseignant': enseignant,
  'peut_choisir_autre_creneau': false,
  'visible_accueil': true,
};

List<Map<String, dynamic>> _etapes(List<String> statuts) =>
    <Map<String, dynamic>>[
      for (final (int i, String s) in statuts.indexed)
        <String, dynamic>{
          'numero': i + 1,
          'statut': s,
          'le': s == 'fait' && i != 1 ? '2026-11-1${i}T10:00:00' : null,
        },
    ];

void main() {
  group('le modele', () {
    test('cinq etapes, rangees dans l\'ordre, la courante nommee', () {
      final SuiviAttente s = suiviDeTest(
        etapes: etapesJusqua(2).reversed.toList(),
      );
      expect(s.etapes.map((EtapeAttente e) => e.numero), <int>[1, 2, 3, 4, 5]);
      expect(s.courante?.numero, 4);
      expect(s.toutEstPret, isFalse);
      expect(s.close, isFalse);
    });

    test('tout est pret quand les cinq etapes sont franchies', () {
      final SuiviAttente s = suiviToutEstPret();
      expect(s.toutEstPret, isTrue);
      expect(s.courante, isNull);
    });

    test('aucun enseignant avant l\'etape 4, meme fourni par la source', () {
      for (final int jusque in <int>[0, 1, 2]) {
        final SuiviAttente s = suiviDeTest(
          etapes: etapesJusqua(jusque),
          enseignant: enseignantVisible,
        );
        expect(
          s.enseignant,
          isNull,
          reason: 'etape ${jusque + 1} franchie : pas de nom d\'enseignant',
        );
      }
      expect(
        suiviDeTest(
          etapes: etapesJusqua(3),
          enseignant: enseignantVisible,
        ).enseignant,
        isNotNull,
      );
    });

    test('un instant UTC est refuse, aucune heure plutot qu\'une fausse', () {
      expect(
        () => EtapeAttente(
          numero: 1,
          etat: EtatEtapeAttente.fait,
          quand: DateTime.utc(2026, 11, 9, 10),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('un suivi sans cinq etapes est refuse', () {
      expect(
        () => SuiviAttente(
          demandeId: 'd',
          eleveId: 'e',
          prenom: 'Yusuf',
          fuseauIana: 'Europe/Paris',
          cas: CasAttente.chemin,
          etapes: etapesJusqua(0).take(4),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('la projection de suivi_attente_foyer()', () {
    test('l\'etape 1 : la demande recue, la formation en cours', () {
      final SuiviAttente s = suivisAttenteDepuisDonnees(<dynamic>[
        _ligne(
          delai: <String, dynamic>{
            'jours': 14,
            'limite': '2026-11-23T10:15:00',
            'point': '2026-11-16T10:15:00',
            'point_passe': false,
            'depasse': false,
          },
        ),
      ]).single;
      expect(s.prenom, 'Yusuf');
      expect(s.cas, CasAttente.chemin);
      expect(s.etape(1).etat, EtatEtapeAttente.fait);
      expect(s.etape(1).quand, DateTime(2026, 11, 9, 10, 15));
      expect(s.etape(2).etat, EtatEtapeAttente.enCours);
      expect(s.etape(2).quand, isNull, reason: 'l\'etape 2 n\'a pas de date');
      expect(s.delai?.jours, 14);
      expect(s.delai?.limite, DateTime(2026, 11, 23, 10, 15));
      expect(s.delai?.depasse, isFalse);
      expect(s.creneau?.joursIso, <int>[1, 3]);
      expect(s.enseignant, isNull);
    });

    test('un delai absent reste absent : l\'ecran ne promet rien', () {
      expect(
        suivisAttenteDepuisDonnees(<dynamic>[_ligne()]).single.delai,
        isNull,
      );
    });

    test('les cas hors du chemin droit', () {
      for (final (String code, CasAttente cas) in <(String, CasAttente)>[
        ('en_attente_enseignant', CasAttente.enAttenteEnseignant),
        ('liste_attente', CasAttente.listeAttente),
        ('refusee', CasAttente.refusee),
        ('retiree', CasAttente.retiree),
        ('close', CasAttente.close),
      ]) {
        expect(
          suivisAttenteDepuisDonnees(<dynamic>[_ligne(cas: code)]).single.cas,
          cas,
        );
      }
      expect(
        () => suivisAttenteDepuisDonnees(<dynamic>[_ligne(cas: 'inconnu')]),
        throwsFormatException,
      );
    });

    test('la carte de l\'enseignant : tout, ou seulement nom et langue', () {
      final List<Map<String, dynamic>> pret = _etapes(<String>[
        'fait',
        'fait',
        'fait',
        'fait',
        'fait',
      ]);
      final SuiviAttente visible = suivisAttenteDepuisDonnees(<dynamic>[
        _ligne(
          etapes: pret,
          enseignant: <String, dynamic>{
            'prenom': 'Ibrahim',
            'titre': 'sayyid',
            'langue_cours': 'Français',
            'montre': true,
            'teacher_id': 'ens-1',
            'pays_origine': 'GN',
            'pays_residence': 'FR',
            'mot': 'Bonjour',
          },
        ),
      ]).single;
      expect(visible.enseignant?.enseignantId, 'ens-1');
      expect(visible.enseignant?.paysOrigine, 'GN');
      expect(visible.enseignant?.paysResidence, 'FR');
      expect(visible.enseignant?.mot, 'Bonjour');

      final SuiviAttente discret = suivisAttenteDepuisDonnees(<dynamic>[
        _ligne(
          etapes: pret,
          enseignant: <String, dynamic>{
            'prenom': 'Khadija',
            'titre': 'sayyida',
            'langue_cours': 'Français',
            'montre': false,
            'teacher_id': 'ens-2',
            'pays_origine': null,
            'pays_residence': null,
            'mot': null,
          },
        ),
      ]).single;
      expect(discret.enseignant?.montre, isFalse);
      // Le reglage ne masque pas la photo : l'identifiant est toujours rendu.
      expect(discret.enseignant?.enseignantId, 'ens-2');
      expect(discret.enseignant?.paysOrigine, isNull);
      expect(discret.enseignant?.mot, isNull);
    });

    test('une heure avec decalage (instant) est ecartee, pas affichee', () {
      final SuiviAttente s = suivisAttenteDepuisDonnees(<dynamic>[
        _ligne(
          etapes: <Map<String, dynamic>>[
            <String, dynamic>{
              'numero': 1,
              'statut': 'fait',
              'le': '2026-11-09T10:15:00+00:00',
            },
            <String, dynamic>{'numero': 2, 'statut': 'en_cours', 'le': null},
            <String, dynamic>{'numero': 3, 'statut': 'a_venir', 'le': null},
            <String, dynamic>{'numero': 4, 'statut': 'a_venir', 'le': null},
            <String, dynamic>{'numero': 5, 'statut': 'a_venir', 'le': null},
          ],
        ),
      ]).single;
      expect(s.etape(1).quand, isNull);
    });

    test('une ligne invalide leve une erreur, jamais un suivi devine', () {
      expect(
        () => suivisAttenteDepuisDonnees(<dynamic>['pas une ligne']),
        throwsFormatException,
      );
      expect(
        () => suivisAttenteDepuisDonnees(<dynamic>[
          _ligne(etapes: <Map<String, dynamic>>[]),
        ]),
        throwsFormatException,
      );
      expect(
        () => suivisAttenteDepuisDonnees(<dynamic>[
          _ligne(
            etapes: _etapes(<String>[
              'fait',
              'bizarre',
              'a_venir',
              'a_venir',
              'a_venir',
            ]),
          ),
        ]),
        throwsFormatException,
      );
    });
  });
}
