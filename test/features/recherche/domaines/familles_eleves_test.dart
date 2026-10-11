// RECH-D2 : familles, eleves et identifiant RA exact, sur les ports du foyer
// et sur le port de resolution d'un RA exact (spec RECH-03 §3, §7.2 ; SEC-R01,
// R07 ; REC-02). Un RA se presente en entier ou pas du tout : aucune
// enumeration, aucun cross-foyer, aucun registre local.

import 'package:flutter_riverpod/flutter_riverpod.dart'
    show Provider, ProviderContainer;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_acces_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/recherche/modeles_recherche.dart';
import 'package:rewayah_academy/core/recherche/port_recherche.dart';
import 'package:rewayah_academy/core/tc_groupe/demonstration_groupes.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/features/recherche/domaines/familles_eleves/moteur_personnes.dart';
import 'package:rewayah_academy/features/recherche/domaines/familles_eleves/moteurs_familles_eleves.dart';
import 'package:rewayah_academy/features/recherche/domaines/familles_eleves/port_resolution_ra.dart';
import 'package:rewayah_academy/features/recherche/domaines/familles_eleves/resolution_ra_demo.dart';

const ContexteRecherche _famille = ContexteRecherche(
  espace: EspaceRecherche.famille,
);
const ContexteRecherche _admin = ContexteRecherche(
  espace: EspaceRecherche.administration,
);

AccesBeneficiaire _profil(String id, String prenom) => AccesBeneficiaire(
  eleveId: id,
  prenom: prenom,
  etatAffiche: EtatAccesAffiche.actif,
);

class _Foyer implements PortAccesFoyer {
  _Foyer(this.profils);
  final List<AccesBeneficiaire> profils;
  int lectures = 0;

  @override
  Future<List<AccesBeneficiaire>> acces() async {
    lectures++;
    return profils;
  }
}

class _FoyerEnPanne implements PortAccesFoyer {
  @override
  Future<List<AccesBeneficiaire>> acces() =>
      Future<List<AccesBeneficiaire>>.error(StateError('reseau'));
}

class _Classes implements PortClassesFoyer {
  _Classes(this.parEleve, {this.enPanne = false});
  final Map<String, GroupSummaryVM> parEleve;
  final bool enPanne;

  @override
  Future<List<ClasseFoyer>> classesDe(String eleveId) async {
    if (enPanne) throw StateError('classes');
    final GroupSummaryVM? c = parEleve[eleveId];
    return c == null
        ? const <ClasseFoyer>[]
        : <ClasseFoyer>[ClasseFoyer(eleveId: eleveId, classe: c)];
  }

  @override
  Future<ClasseFoyer?> classe({
    required String groupeId,
    required String eleveId,
  }) async => null;
}

class _RaEspion implements PortResolutionRa {
  _RaEspion(this.perimetre);
  final Map<String, ElevePourRa> perimetre;
  final List<String> appels = <String>[];

  @override
  Future<ElevePourRa?> resoudre(String identifiantExact) async {
    appels.add(identifiantExact);
    return perimetre[identifiantExact];
  }
}

class _RaEnPanne implements PortResolutionRa {
  @override
  Future<ElevePourRa?> resoudre(String identifiantExact) =>
      Future<ElevePourRa?>.error(StateError('serveur'));
}

const ElevePourRa _mariam = ElevePourRa(
  eleveId: 'e-mariam',
  prenom: 'Mariam',
  classe: 'Coran 1',
);

Future<GroupSummaryVM> _classe(String libelle) async {
  final List<GroupSummaryVM> tous = await GroupesDemonstrationLocale()
      .mesGroupes();
  final GroupSummaryVM base = tous.first;
  return GroupSummaryVM(
    groupeId: 'g-$libelle',
    libelle: libelle,
    couleurJeton: base.couleurJeton,
    enseignant: base.enseignant,
    nombreMembres: 3,
    seuilMax: 8,
    typePublic: base.typePublic,
    actif: true,
  );
}

MoteurPersonnesFoyer _moteur({
  PortAccesFoyer? foyer,
  PortClassesFoyer? classes,
  PortResolutionRa? ra,
}) => MoteurPersonnesFoyer(
  foyer:
      foyer ??
      _Foyer(<AccesBeneficiaire>[
        _profil('e-mariam', 'Mariam'),
        _profil('e-omar', 'Omar'),
      ]),
  classes: classes ?? _Classes(const <String, GroupSummaryVM>{}),
  resolutionRa: ra ?? _RaEspion(const <String, ElevePourRa>{}),
);

void main() {
  group('identifiantRaExact : un RA complet ou rien', () {
    test('forme canonique, majuscules, tirets et espaces tolerés', () {
      expect(identifiantRaExact('RA-AB0012'), 'RA-AB0012');
      expect(identifiantRaExact('  ra ab0012 '), 'RA-AB0012');
      expect(identifiantRaExact('raab0012'), 'RA-AB0012');
    });

    test('un debut d\'identifiant n\'en est pas un (aucune completion)', () {
      for (final String saisie in <String>[
        'RA',
        'RA-',
        'RA-A',
        'RA-AB0',
        'RA-AB1',
      ]) {
        expect(identifiantRaExact(saisie), isNull, reason: saisie);
      }
    });

    test('un mot de la langue sans chiffre n\'est pas un RA', () {
      expect(identifiantRaExact('RAMADAN'), isNull);
      expect(identifiantRaExact('rahma'), isNull);
    });

    test('une saisie hostile ne devient jamais un RA', () {
      for (final String saisie in <String>[
        'RA-AB0012; drop table',
        'RA-%',
        'RA-AB0012/../x',
        '<b>RA-AB0012</b>',
        'RA-AB0012 RA-CD0034',
      ]) {
        expect(identifiantRaExact(saisie), isNull, reason: saisie);
      }
    });
  });

  group('recherche par nom dans le foyer', () {
    test('trouve un profil du foyer par son prenom, sans accent', () async {
      final MoteurPersonnesFoyer m = _moteur(
        foyer: _Foyer(<AccesBeneficiaire>[_profil('e1', 'Aïcha')]),
      );
      final ReponseOk r =
          await m.rechercher(requete: 'aicha', contexte: _famille) as ReponseOk;
      expect(r.elements.single.titre, 'Aïcha');
      expect(r.elements.single.cible.kind, KindCible.eleve);
      expect(r.elements.single.cible.reference, 'e1');
    });

    test(
      'deux homonymes restent deux resultats, departages par classe',
      () async {
        final MoteurPersonnesFoyer m = _moteur(
          foyer: _Foyer(<AccesBeneficiaire>[
            _profil('e1', 'Yusuf'),
            _profil('e2', 'Yusuf'),
          ]),
          classes: _Classes(<String, GroupSummaryVM>{
            'e1': await _classe('Coran 1'),
            'e2': await _classe('Arabe 2'),
          }),
        );
        final ReponseOk r = await m.rechercher(
          requete: 'yusuf',
          contexte: _famille,
        ) as ReponseOk;
        expect(r.elements, hasLength(2));
        expect(r.elements.map((ResultatRecherche e) => e.reference), <String>[
          'e1',
          'e2',
        ]);
        expect(r.elements[0].contexte, isNot(r.elements[1].contexte));
        expect(r.elements[0].contexte, contains('Coran 1'));
      },
    );

    test(
      'une classe illisible ne fait ni disparaitre ni echouer le profil',
      () async {
        final MoteurPersonnesFoyer m = _moteur(
          classes: _Classes(const <String, GroupSummaryVM>{}, enPanne: true),
        );
        final ReponseOk r = await m.rechercher(
          requete: 'omar',
          contexte: _famille,
        ) as ReponseOk;
        expect(r.elements.single.titre, 'Omar');
      },
    );

    test(
      'le second adulte lit le meme foyer, donc les memes profils',
      () async {
        final _Foyer foyer = _Foyer(<AccesBeneficiaire>[
          _profil('e1', 'Mariam'),
        ]);
        final MoteurPersonnesFoyer premier = _moteur(foyer: foyer);
        final MoteurPersonnesFoyer second = _moteur(foyer: foyer);
        final ReponseOk a = await premier.rechercher(
          requete: 'mariam',
          contexte: _famille,
        ) as ReponseOk;
        final ReponseOk b = await second.rechercher(
          requete: 'mariam',
          contexte: _famille,
        ) as ReponseOk;
        expect(
          a.elements.map((ResultatRecherche e) => e.reference),
          b.elements.map((ResultatRecherche e) => e.reference),
        );
      },
    );

    test(
      'un mot absent du prenom ne remonte rien (aucun autre champ)',
      () async {
        final ReponseOk r = await _moteur().rechercher(
          requete: 'foyer',
          contexte: _famille,
        ) as ReponseOk;
        expect(r.elements, isEmpty);
      },
    );

    test('une panne du foyer est un echec, jamais un vide', () async {
      final PortRecherche port = PortRechercheParMoteurs(
        <MoteurRechercheDomaine>[_moteur(foyer: _FoyerEnPanne())],
      );
      final ReponseDomaine r = await port.rechercher(
        domaine: DomaineRecherche.personnes,
        requete: 'omar',
        contexte: _famille,
      );
      expect(r, isA<ReponseEchec>());
    });
  });

  group('identifiant RA exact : non enumerable', () {
    test('un RA exact du foyer rend l\'eleve, un seul', () async {
      final _RaEspion ra = _RaEspion(<String, ElevePourRa>{
        'RA-AB0012': _mariam,
      });
      final ReponseOk r = await _moteur(
        ra: ra,
      ).rechercher(requete: 'ra-ab0012', contexte: _famille) as ReponseOk;
      expect(r.elements.single.titre, 'Mariam');
      expect(r.elements.single.cible.reference, 'e-mariam');
      expect(ra.appels, <String>['RA-AB0012']);
    });

    test('RA inconnu, d\'un autre foyer ou retire : exactement la meme '
        'reponse', () async {
      // Le faux serveur ne connait que RA-AB0012 pour cet appelant : RA-ZZ9999
      // existerait ailleurs, rien ne le distingue d'un RA qui n'existe pas.
      final _RaEspion ra = _RaEspion(<String, ElevePourRa>{
        'RA-AB0012': _mariam,
      });
      final MoteurPersonnesFoyer m = _moteur(ra: ra);
      final ReponseOk autreFoyer = await m.rechercher(
        requete: 'RA-ZZ9999',
        contexte: _famille,
      ) as ReponseOk;
      final ReponseOk inexistant = await m.rechercher(
        requete: 'RA-QQ0000',
        contexte: _famille,
      ) as ReponseOk;
      expect(autreFoyer.elements, isEmpty);
      expect(inexistant.elements, isEmpty);
      expect(autreFoyer.curseurSuivant, inexistant.curseurSuivant);
      expect(autreFoyer.aPlus, inexistant.aPlus);
    });

    test(
      'un debut de RA n\'interroge jamais le serveur ni ne complete',
      () async {
        final _RaEspion ra = _RaEspion(<String, ElevePourRa>{
          'RA-AB0012': _mariam,
        });
        final MoteurPersonnesFoyer m = _moteur(ra: ra);
        for (final String saisie in <String>['RA-AB', 'RA-AB0', 'RA-A']) {
          final ReponseOk r = await m.rechercher(
            requete: saisie,
            contexte: _famille,
          ) as ReponseOk;
          expect(r.elements, isEmpty, reason: saisie);
        }
        expect(ra.appels, isEmpty);
      },
    );

    test(
      'l\'administration ne cherche pas par nom, elle presente un RA',
      () async {
        final _RaEspion ra = _RaEspion(<String, ElevePourRa>{
          'RA-AB0012': _mariam,
        });
        final MoteurPersonnesFoyer m = _moteur(ra: ra);
        final ReponseOk parNom = await m.rechercher(
          requete: 'mariam',
          contexte: _admin,
        ) as ReponseOk;
        expect(parNom.elements, isEmpty);
        final ReponseOk parRa = await m.rechercher(
          requete: 'RA-AB0012',
          contexte: _admin,
        ) as ReponseOk;
        expect(parRa.elements.single.titre, 'Mariam');
      },
    );

    test('le titre et le contexte ne repetent pas l\'identifiant', () async {
      final ReponseOk r = await _moteur(
        ra: _RaEspion(<String, ElevePourRa>{'RA-AB0012': _mariam}),
      ).rechercher(requete: 'RA-AB0012', contexte: _famille) as ReponseOk;
      final ResultatRecherche e = r.elements.single;
      expect(e.titre, isNot(contains('AB0012')));
      expect(e.contexte ?? '', isNot(contains('AB0012')));
      expect(e.reference, isNot(contains('AB0012')));
    });

    test('une panne du serveur est un echec, jamais un vide', () async {
      final PortRecherche port = PortRechercheParMoteurs(
        <MoteurRechercheDomaine>[_moteur(ra: _RaEnPanne())],
      );
      final ReponseDomaine r = await port.rechercher(
        domaine: DomaineRecherche.personnes,
        requete: 'RA-AB0012',
        contexte: _famille,
      );
      expect(r, isA<ReponseEchec>());
    });
  });

  group('capacite par espace, curseur, production', () {
    test('espaces sans domaine : absent, pas desactive', () async {
      final MoteurPersonnesFoyer m = _moteur();
      for (final EspaceRecherche e in <EspaceRecherche>[
        EspaceRecherche.eleve,
        EspaceRecherche.eleveGuide,
        EspaceRecherche.enseignant,
        EspaceRecherche.controleur,
        EspaceRecherche.comptable,
      ]) {
        final ContexteRecherche c = ContexteRecherche(espace: e);
        expect(await m.disponiblePour(c), isFalse, reason: e.name);
        expect(
          await m.rechercher(requete: 'mariam', contexte: c),
          isA<ReponseEchec>(),
          reason: e.name,
        );
      }
      expect(await m.disponiblePour(_famille), isTrue);
      expect(await m.disponiblePour(_admin), isTrue);
    });

    test('un curseur falsifie ou d\'un autre espace est refuse', () async {
      final MoteurPersonnesFoyer m = _moteur(
        foyer: _Foyer(<AccesBeneficiaire>[
          for (int i = 0; i < 8; i++) _profil('e$i', 'Sara $i'),
        ]),
      );
      final ReponseOk page = await m.rechercher(
        requete: 'sara',
        contexte: _famille,
        limite: 3,
      ) as ReponseOk;
      expect(page.elements, hasLength(3));
      expect(page.curseurSuivant, isNotNull);
      final ReponseDomaine autreEspace = await m.rechercher(
        requete: 'RA-AB0012',
        contexte: _admin,
        curseur: page.curseurSuivant,
      );
      expect(autreEspace, isA<ReponseEchec>());
      final ReponseDomaine falsifie = await m.rechercher(
        requete: 'sara',
        contexte: _famille,
        curseur: 'c1.0.999',
      );
      expect((falsifie as ReponseEchec).statut, StatutRecherche.curseurPerime);
    });

    test(
      'en production le port de RA est indisponible, jamais un vide',
      () async {
        final ProviderContainer c = ProviderContainer();
        addTearDown(c.dispose);
        await expectLater(
          c.read(portResolutionRaProvider).resoudre('RA-AB0012'),
          throwsA(anything),
        );
        // Sans moteur raccorde, aucun domaine n'est servi.
        expect(c.read(moteursRechercheProvider), isEmpty);
      },
    );

    test('le double de demonstration ne connait que son perimetre', () async {
      const ResolutionRaDemo demo = ResolutionRaDemo(<String, ElevePourRa>{
        'RA-AB0012': _mariam,
      });
      expect(await demo.resoudre('RA-AB0012'), _mariam);
      expect(await demo.resoudre('RA-AB0013'), isNull);
    });
  });

  test('le fournisseur de moteurs branche le domaine des personnes', () async {
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);
    final List<MoteurRechercheDomaine> moteurs = c.read(_fournisseur);
    expect(moteurs.single.domaine, DomaineRecherche.personnes);
  });
}

final _fournisseur = Provider<List<MoteurRechercheDomaine>>(
  moteursFamillesEleves,
);
