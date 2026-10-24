// ADM-23 : les formes de donnees de l'import des formulaires et le fichier que
// la direction depose.
//
// Ce que le test prouve : la lecture stricte de chaque reponse du serveur (une
// forme inattendue est une erreur, jamais un zero) ; qu'aucune donnee de contact
// n'a de champ ; le mappage des colonnes (une colonne par champ, un mappage vide
// ne part pas) ; les champs manquants ; la deduction du classeur et de l'onglet
// d'un export Google Sheets ; la reference source d'une ligne, telle que le
// serveur la forme.
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/fichier_formulaires.dart';
import 'package:rewayah_academy/core/candidature/modeles_import_candidatures.dart';

import '../../fixtures/candidature/faux_import_candidatures.dart';

Map<String, dynamic> _compteurs() => <String, dynamic>{
  'lignesLues': 7,
  'nouvelles': 4,
  'corrigees': 1,
  'dejaConnues': 1,
  'ignorees': 1,
  'aCorriger': 1,
  'historique': 2,
  'personnes': 5,
};

Map<String, dynamic> _apercuJson() => <String, dynamic>{
  'ecritureEffectuee': false,
  'jeton': 'abc',
  'entetes': <Map<String, dynamic>>[
    <String, dynamic>{'position': 1, 'champ': 'horodatage'},
    <String, dynamic>{'position': 2, 'champ': null},
  ],
  'compteurs': _compteurs(),
  'groupes': <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'g1',
      'nature': 'courriel_et_telephone',
      'taille': 3,
      'lignes': <int>[3, 6],
      'retenueProposee': 6,
      'retenueDansLaBase': false,
      'choisi': true,
      'choix': 'distinctes',
    },
  ],
  'lignes': <Map<String, dynamic>>[
    <String, dynamic>{
      'ligne': 2,
      'issue': 'deja_connue',
      'motifs': <String>['inscription_12_10'],
      'avertissements': <String>[],
      'courrielAObtenir': null,
      'indicatifAConfirmer': true,
      'groupe': null,
      'etatFinal': null,
    },
  ],
};

void main() {
  group('lecture stricte du serveur', () {
    test('un apercu complet se lit tel que le serveur le rend', () {
      final ApercuImport a = ApercuImport.depuisJson(_apercuJson());
      expect(a.jeton, 'abc');
      expect(a.colonnes.length, 2);
      expect(a.colonnes.first.champ, ChampFormulaire.horodatage);
      expect(a.colonnes.last.champ, isNull);
      expect(a.colonnesReconnues, 1);
      expect(a.compteurs.lignesLues, 7);
      expect(a.compteurs.corrigees, 1);
      expect(a.compteurs.historique, 2);
      final GroupeDoublons g = a.groupes.single;
      expect(g.nature, NatureCle.courrielEtTelephone);
      expect(g.lignes, <int>[3, 6]);
      expect(g.retenueProposee, 6);
      expect(g.choisi, isTrue);
      expect(g.choix, retenueDistinctes);
      final LigneApercu l = a.lignes.single;
      expect(l.issue, IssueLigne.dejaConnue);
      expect(l.courrielAObtenir, isFalse, reason: 'nul vaut faux, jamais vrai');
      expect(l.indicatifAConfirmer, isTrue);
      expect(l.etatFinal, isNull);
      expect(l.motifs, <String>['inscription_12_10']);
    });

    test('un apercu qui ecrirait quelque chose est refuse', () {
      final Map<String, dynamic> j = _apercuJson()
        ..['ecritureEffectuee'] = true;
      expect(() => ApercuImport.depuisJson(j), throwsFormatException);
    });

    test('chaque forme inattendue est une erreur, jamais un zero', () {
      for (final MapEntry<String, Object?> e in <String, Object?>{
        'jeton': null,
        'entetes': 'x',
        'groupes': <String, dynamic>{},
        'lignes': 3,
        'compteurs': <String, dynamic>{'lignesLues': 'sept'},
      }.entries) {
        final Map<String, dynamic> j = _apercuJson()..[e.key] = e.value;
        expect(
          () => ApercuImport.depuisJson(j),
          throwsFormatException,
          reason: e.key,
        );
      }
      expect(
        () => ApercuImport.depuisJson(const <String, dynamic>{'x': 1}),
        throwsFormatException,
      );
      expect(() => ApercuImport.depuisJson(null), throwsFormatException);
    });

    test('une issue, une nature ou un champ inconnus sont refuses', () {
      expect(() => IssueLigne.depuisCode('autre'), throwsFormatException);
      expect(() => NatureCle.depuisCode('nom'), throwsFormatException);
      expect(
        () => ColonneLue.depuisJson(const <String, dynamic>{
          'position': 1,
          'champ': 'inconnu',
        }),
        throwsFormatException,
      );
      expect(
        () => LigneApercu.depuisJson(const <String, dynamic>{
          'ligne': 2,
          'issue': 'nouvelle',
          'etatFinal': 'perdu',
        }),
        throwsFormatException,
      );
    });

    test('le rapport suit une ecriture et nomme des references', () {
      final RapportImport r = RapportImport.depuisJson(<String, dynamic>{
        'ecritureEffectuee': true,
        'lot': 'lot-1',
        'compteurs': _compteurs(),
        'choix': const <Map<String, String>>[
          <String, String>{'groupe': 'g1', 'retenue': 'distinctes'},
        ],
        'lignes': const <Map<String, dynamic>>[
          <String, dynamic>{
            'ligne': 2,
            'reference': 'Classeur|Onglet|21/10/2026 09:15:00',
            'issue': 'nouvelle',
            'etatFinal': 'historique',
            'motifs': <String>[],
            'avertissements': <String>['format_national'],
          },
          // strip_nulls : une ligne ignoree n'a ni reference ni etat final.
          <String, dynamic>{
            'ligne': 5,
            'issue': 'ignoree',
            'motifs': <String>['ligne_vide'],
          },
        ],
        'rejoue': true,
      });
      expect(r.rejoue, isTrue);
      expect(
        r.choix.single,
        const ChoixDoublon(groupe: 'g1', retenue: 'distinctes'),
      );
      expect(r.lignes.first.reference, contains('Classeur|Onglet|'));
      expect(r.lignes.first.etatFinal, EtatFinalLigne.historique);
      expect(r.lignes.last.reference, isNull);
      expect(r.lignes.last.etatFinal, isNull);
      expect(
        () => RapportImport.depuisJson(<String, dynamic>{
          'ecritureEffectuee': false,
          'lot': 'l',
          'lignes': const <Object?>[],
          'choix': const <Object?>[],
          'compteurs': _compteurs(),
        }),
        throwsFormatException,
        reason: 'un rapport qui n\'a rien ecrit n\'en est pas un',
      );
    });

    test('les capacites : une cle absente vaut faux', () {
      final CapacitesImportCandidatures c =
          CapacitesImportCandidatures.depuisJson(const <String, dynamic>{
            'doubleVerificationRequise': true,
          });
      expect(c.peutImporter, isFalse);
      expect(c.doubleVerificationRequise, isTrue);
      expect(
        () => CapacitesImportCandidatures.depuisJson('x'),
        throwsFormatException,
      );
    });

    test('aucune classe de ce module ne porte un contact ou un nom', () {
      // Les champs de LigneApercu, LigneRapport et GroupeDoublons sont fermes :
      // ni courriel, ni telephone, ni nom. La nature d'une cle est un mot, pas
      // une valeur.
      const GroupeDoublons g = GroupeDoublons(
        id: 'g',
        nature: NatureCle.telephone,
        taille: 2,
        lignes: <int>[2, 3],
      );
      expect(g.nature.code, 'telephone');
      expect(NatureCle.values.map((NatureCle n) => n.code), <String>[
        'courriel',
        'telephone',
        'courriel_et_telephone',
      ]);
    });
  });

  group('mappage des colonnes', () {
    test('sans correction, rien ne part (null, jamais un objet vide)', () {
      expect(MappageColonnes.aucun.versJson(), isNull);
      expect(MappageColonnes.aucun.estVide, isTrue);
    });

    test('une correction part en position vers code ; null : non lue', () {
      final MappageColonnes m = MappageColonnes.aucun
          .avec(3, ChampFormulaire.nom)
          .avec(5, null);
      expect(m.versJson(), <String, String?>{'3': 'nom', '5': null});
    });

    test(
      'un champ n\'a qu\'une colonne : l\'attribuer ailleurs retire l\'autre',
      () {
        final MappageColonnes m = MappageColonnes.aucun
            .avec(3, ChampFormulaire.nom)
            .avec(8, ChampFormulaire.nom);
        expect(m.versJson(), <String, String?>{'8': 'nom'});
      },
    );

    test(
      'appliquerA : la position corrigee, et le champ quitte sa colonne',
      () {
        final List<ColonneLue> lues = colonnesTest();
        final List<ColonneLue> apres = MappageColonnes.aucun
            .avec(5, ChampFormulaire.nom)
            .appliquerA(lues);
        expect(
          apres[2].champ,
          isNull,
          reason: 'la colonne 3 n\'est plus le nom',
        );
        expect(apres[4].champ, ChampFormulaire.nom);
        expect(apres.length, lues.length);
        // Idempotent : la reponse du serveur porte deja la correction.
        expect(
          MappageColonnes.aucun.avec(5, ChampFormulaire.nom).appliquerA(apres),
          apres,
        );
      },
    );

    test('deux mappages egaux le sont, deux differents non', () {
      expect(
        MappageColonnes.aucun.avec(1, ChampFormulaire.nom),
        MappageColonnes.aucun.avec(1, ChampFormulaire.nom),
      );
      expect(
        MappageColonnes.aucun.avec(1, ChampFormulaire.nom) ==
            MappageColonnes.aucun.avec(2, ChampFormulaire.nom),
        isFalse,
      );
    });

    test('champsManquants : les trois obligatoires, puis un contact', () {
      expect(champsManquants(colonnesTest()), isEmpty);
      expect(
        champsManquants(
          colonnesTest(
            sauf: <ChampFormulaire>{
              ChampFormulaire.nom,
              ChampFormulaire.horodatage,
            },
          ),
        ),
        <ChampManquant>[ChampManquant.horodatage, ChampManquant.nom],
      );
      // Un seul des deux contacts suffit.
      expect(
        champsManquants(
          colonnesTest(sauf: <ChampFormulaire>{ChampFormulaire.courriel}),
        ),
        isEmpty,
      );
      expect(
        champsManquants(
          colonnesTest(
            sauf: <ChampFormulaire>{
              ChampFormulaire.courriel,
              ChampFormulaire.telephone,
            },
          ),
        ),
        <ChampManquant>[ChampManquant.contact],
      );
    });

    test('les champs obligatoires sont ceux du serveur', () {
      expect(
        ChampFormulaire.values
            .where((ChampFormulaire c) => c.obligatoire)
            .map((ChampFormulaire c) => c.code),
        <String>['horodatage', 'genre', 'nom'],
      );
      expect(
        ChampFormulaire.values
            .where((ChampFormulaire c) => c.contact)
            .map((ChampFormulaire c) => c.code),
        <String>['telephone', 'courriel'],
      );
    });
  });

  group('le fichier', () {
    test('un export Google Sheets dit son classeur et son onglet', () {
      expect(
        deduireNoms('Formulaire enseignants - Réponses.csv'),
        const NomsClasseur(
          classeur: 'Formulaire enseignants',
          onglet: 'Réponses',
        ),
      );
      // Le dernier « - » separe l'onglet ; un numero de copie est ignore.
      expect(
        deduireNoms('Classeur - 2026 - Réponses (1).CSV'),
        const NomsClasseur(classeur: 'Classeur - 2026', onglet: 'Réponses'),
      );
    });

    test('sans « - », l\'onglet reste vide : rien ne se devine', () {
      final NomsClasseur n = deduireNoms('export.csv');
      expect(n.classeur, 'export');
      expect(n.onglet, isEmpty);
      expect(n.valides, isFalse);
    });

    test(
      'une barre verticale du nom est remplacee, un nom vide est refuse',
      () {
        expect(deduireNoms('A|B - C.csv').classeur, 'A-B');
        expect(nomValide(''), isFalse);
        expect(nomValide('  '), isFalse);
        expect(nomValide('a|b'), isFalse);
        expect(nomValide('x' * 201), isFalse);
        expect(nomValide('x' * 200), isTrue);
      },
    );

    test('lire : le CSV part en virgules, les colonnes se lisent', () {
      final FichierFormulaires f = FichierFormulaires.lire(
        nom: 'Formulaire - Reponses.csv',
        texte: csvFormulaires,
      );
      expect(f.nombreColonnes, 14);
      expect(f.nombreLignes, 7);
      expect(f.sansLigne, isFalse);
      expect(f.titreDeColonne(1), 'Horodateur');
      expect(f.titreDeColonne(3), 'الاسم الكامل');
      expect(f.titreDeColonne(99), isEmpty);
      expect(f.csv.contains(';'), isFalse);
      expect(f.tropVolumineux, isFalse);
    });

    test('un export a point-virgule repart en virgules', () {
      final FichierFormulaires f = FichierFormulaires.lire(
        nom: 'a - b.csv',
        texte: 'Horodateur;Nom\n21/10/2026 09:15:00;Personne Test 01\n',
      );
      expect(f.nombreColonnes, 2);
      expect(f.csv, startsWith('Horodateur,Nom\r\n'));
    });

    test('l\'en-tete seul ne porte aucune ligne', () {
      final FichierFormulaires f = FichierFormulaires.lire(
        nom: 'a - b.csv',
        texte: 'Horodateur,Nom\n',
      );
      expect(f.sansLigne, isTrue);
      expect(f.nombreLignes, 0);
    });

    test('un guillemet jamais referme se voit', () {
      final FichierFormulaires f = FichierFormulaires.lire(
        nom: 'a - b.csv',
        texte: 'A,B\n1,"2\n3,4\n',
      );
      expect(f.guillemetNonFerme, isTrue);
    });

    test('la reference source : classeur, onglet, horodatage ecrit', () {
      expect(
        referenceSource(
          classeur: ' Classeur ',
          onglet: 'Onglet',
          horodatage: '21/10/2026 09:15:00 ',
        ),
        'Classeur|Onglet|21/10/2026 09:15:00',
      );
    });

    test(
      'l\'horodatage d\'une ligne se lit dans la colonne de l\'horodateur',
      () {
        final FichierFormulaires f = FichierFormulaires.lire(
          nom: 'a - b.csv',
          texte: csvFormulaires,
        );
        final List<ColonneLue> cols = colonnesTest();
        expect(f.horodatageDeLigne(3, cols), '21/10/2026 09:40:00');
        expect(f.horodatageDeLigne(6, cols), '22/10/2026 08:00:00');
        expect(f.horodatageDeLigne(99, cols), isNull);
        expect(
          f.horodatageDeLigne(
            3,
            colonnesTest(sauf: <ChampFormulaire>{ChampFormulaire.horodatage}),
          ),
          isNull,
        );
      },
    );
  });
}
