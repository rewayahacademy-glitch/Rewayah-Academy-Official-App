import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/coran/vue_lecteur.dart';

/// Al-Fatiha, telle que la page 1 la porte.
List<VersetCoran> _fatiha() => <VersetCoran>[
  for (int n = 1; n <= 7; n++)
    VersetCoran(sourateNumero: 1, numero: n, texte: 'verset $n', pageNumero: 1),
];

/// La page 2 du mushaf : les cinq premiers versets d'Al-Baqara.
List<VersetCoran> _baqaraDebut() => <VersetCoran>[
  for (int n = 1; n <= 5; n++)
    VersetCoran(sourateNumero: 2, numero: n, texte: 'verset $n', pageNumero: 2),
];

/// Une page a cheval : la fin d'une sourate, puis le debut de la suivante.
List<VersetCoran> _aCheval() => <VersetCoran>[
  const VersetCoran(
    sourateNumero: 93,
    numero: 10,
    texte: 'fin de Ad-Duha',
    pageNumero: 596,
  ),
  const VersetCoran(
    sourateNumero: 93,
    numero: 11,
    texte: 'fin de Ad-Duha',
    pageNumero: 596,
  ),
  const VersetCoran(
    sourateNumero: 94,
    numero: 1,
    texte: 'debut d’Ash-Sharh',
    pageNumero: 596,
  ),
  const VersetCoran(
    sourateNumero: 94,
    numero: 2,
    texte: 'suite d’Ash-Sharh',
    pageNumero: 596,
  ),
];

const List<Sourate> _sourates = <Sourate>[
  Sourate(
    numero: 1,
    nomArabe: 'x',
    nomTranslittere: 'Al-Faatiha',
    lieuRevelation: 'mecque',
    nombreVersets: 7,
  ),
  Sourate(
    numero: 2,
    nomArabe: 'x',
    nomTranslittere: 'Al-Baqara',
    lieuRevelation: 'medine',
    nombreVersets: 286,
  ),
  Sourate(
    numero: 93,
    nomArabe: 'x',
    nomTranslittere: 'Ad-Duhaa',
    lieuRevelation: 'mecque',
    nombreVersets: 11,
  ),
  Sourate(
    numero: 94,
    nomArabe: 'x',
    nomTranslittere: 'Ash-Sharh',
    lieuRevelation: 'mecque',
    nombreVersets: 8,
  ),
];

VueLecteur _vue({
  int pageDemandee = 1,
  PageCoran? page,
  bool chargementEnCours = false,
  List<Sourate>? sourates = _sourates,
  PositionLecture? position,
}) => VueLecteur.depuis(
  pageDemandee: pageDemandee,
  page: page,
  chargementEnCours: chargementEnCours,
  sourates: sourates,
  position: position,
);

void main() {
  group('les deux facons de ne rien montrer ne se confondent pas', () {
    test('rien recu et chargement en cours : on charge', () {
      final VueLecteur vue = _vue(chargementEnCours: true);

      expect(vue.etat, EtatLecteur.chargement);
      expect(vue.aDuTexte, isFalse);
      expect(vue.sections, isEmpty);
    });

    test('rien recu et chargement fini : la lecture a echoue', () {
      final VueLecteur vue = _vue();

      expect(vue.etat, EtatLecteur.indisponible);
      // Surtout pas « corpus absent » : le reseau revient, une migration non.
      expect(vue.etat, isNot(EtatLecteur.corpusAbsent));
    });

    test('page recue mais vide : le corpus n’est pas importe', () {
      final VueLecteur vue = _vue(
        page: const PageCoran(numero: 1, versets: <VersetCoran>[]),
      );

      expect(vue.etat, EtatLecteur.corpusAbsent);
      expect(vue.etat, isNot(EtatLecteur.indisponible));
      expect(vue.aDuTexte, isFalse);
    });

    test('page recue avec des versets : on lit', () {
      final VueLecteur vue = _vue(
        page: PageCoran(numero: 1, versets: _fatiha(), juzNumero: 1),
      );

      expect(vue.etat, EtatLecteur.lecture);
      expect(vue.aDuTexte, isTrue);
      expect(vue.juzNumero, 1);
    });
  });

  group('une page se decoupe par sourate, pas par verset', () {
    test('une seule sourate donne une seule section', () {
      final VueLecteur vue = _vue(
        page: PageCoran(numero: 1, versets: _fatiha()),
      );

      expect(vue.sections, hasLength(1));
      expect(vue.sections.single.sourateNumero, 1);
      expect(vue.sections.single.versets, hasLength(7));
      expect(vue.souratesPresentes, <int>[1]);
    });

    test('une page a cheval donne DEUX sections, dans l’ordre du texte', () {
      // Le defaut que ce decoupage empeche : un seul titre en haut de page,
      // qui mentirait sur la seconde sourate. Un lecteur de Coran le voit
      // immediatement.
      final VueLecteur vue = _vue(
        pageDemandee: 596,
        page: PageCoran(numero: 596, versets: _aCheval()),
      );

      expect(vue.sections, hasLength(2));
      expect(vue.souratesPresentes, <int>[93, 94]);
      expect(vue.sections.first.versets, hasLength(2));
      expect(vue.sections.last.versets, hasLength(2));
    });

    test('seule la sourate qui COMMENCE ici porte son titre', () {
      final VueLecteur vue = _vue(
        pageDemandee: 596,
        page: PageCoran(numero: 596, versets: _aCheval()),
      );

      // Ad-Duha continue : elle ne se reintroduit pas au milieu.
      expect(vue.sections.first.commenceLaSourate, isFalse);
      // Ash-Sharh commence : nom et basmala ont leur place ici.
      expect(vue.sections.last.commenceLaSourate, isTrue);
    });

    test('une page qui continue une sourate ne porte aucun titre', () {
      final VueLecteur vue = _vue(
        pageDemandee: 2,
        page: PageCoran(numero: 2, versets: _baqaraDebut()),
      );

      // Al-Baqara commence bien au verset 1 sur cette page.
      expect(vue.sections.single.commenceLaSourate, isTrue);

      final VueLecteur suite = _vue(
        pageDemandee: 3,
        page: const PageCoran(
          numero: 3,
          versets: <VersetCoran>[
            VersetCoran(
              sourateNumero: 2,
              numero: 6,
              texte: 'suite',
              pageNumero: 3,
            ),
          ],
        ),
      );
      expect(suite.sections.single.commenceLaSourate, isFalse);
    });

    test('les sourates non chargees n’empechent pas de lire', () {
      // Le texte s'affiche sans son titre plutot que pas du tout.
      final VueLecteur vue = _vue(
        page: PageCoran(numero: 1, versets: _fatiha()),
        sourates: null,
      );

      expect(vue.etat, EtatLecteur.lecture);
      expect(vue.sections.single.sourate, isNull);
      expect(vue.sections.single.versets, hasLength(7));
    });

    test('la fiche de sourate est rattachee quand elle est connue', () {
      final VueLecteur vue = _vue(
        page: PageCoran(numero: 1, versets: _fatiha()),
      );

      expect(vue.sections.single.sourate?.nomTranslittere, 'Al-Faatiha');
      expect(vue.sections.single.sourate?.mecquoise, isTrue);
    });
  });

  group('la reprise ne se propose que si elle mene ailleurs', () {
    test('aucune position enregistree : rien a proposer', () {
      final VueLecteur vue = _vue(
        page: PageCoran(numero: 1, versets: _fatiha()),
      );

      expect(vue.repriseProposee, isFalse);
      expect(vue.position, isNull);
    });

    test('une position sur une AUTRE page : on la propose', () {
      final VueLecteur vue = _vue(
        page: PageCoran(numero: 1, versets: _fatiha()),
        position: const PositionLecture(page: 42, sourate: 2, verset: 255),
      );

      expect(vue.repriseProposee, isTrue);
      expect(vue.position?.page, 42);
    });

    test('une position sur la page DEJA ouverte : on ne propose rien', () {
      // Un bouton « Reprendre » qui ramene ou l'on est deja est une promesse
      // vide, et il occuperait la place la plus visible de l'ecran pour rien.
      final VueLecteur vue = _vue(
        pageDemandee: 42,
        page: PageCoran(numero: 42, versets: _fatiha()),
        position: const PositionLecture(page: 42, sourate: 2, verset: 255),
      );

      expect(vue.repriseProposee, isFalse);
      // Elle reste lisible pour autant : c'est l'offre qui disparait, pas le
      // fait.
      expect(vue.position, isNotNull);
    });
  });

  group('la navigation est bornee au mushaf', () {
    test('la premiere page n’a pas de precedente', () {
      final VueLecteur vue = _vue(
        page: PageCoran(numero: 1, versets: _fatiha()),
      );

      expect(vue.pagePrecedente, isNull);
      expect(vue.pageSuivante, 2);
    });

    test('la derniere page n’a pas de suivante', () {
      final VueLecteur vue = _vue(
        pageDemandee: 604,
        page: PageCoran(numero: 604, versets: _fatiha()),
      );

      expect(vue.pageAffichee, 604);
      expect(vue.pageSuivante, isNull);
      expect(vue.pagePrecedente, 603);
    });

    test('une page hors bornes est ramenee dans le mushaf', () {
      expect(_vue(pageDemandee: 0).pageAffichee, 1);
      expect(_vue(pageDemandee: -12).pageAffichee, 1);
      expect(_vue(pageDemandee: 900).pageAffichee, 604);
    });

    test('le mushaf de reference compte 604 pages', () {
      expect(_vue().nombrePages, 604);
      expect(pagesMushafMedine, 604);
    });
  });

  group('la position de lecture reste dans ce que la base accepte', () {
    test('le grossissement est borne comme la colonne le veut', () {
      const PositionLecture position = PositionLecture(
        page: 1,
        sourate: 1,
        verset: 1,
      );

      expect(position.zoom, 1);
      expect(position.avecZoom(12).zoom, PositionLecture.zoomMax);
      expect(position.avecZoom(0.01).zoom, PositionLecture.zoomMin);
      // La borne est celle de `student_reading_position` depuis 0007 : envoyer
      // au-dela ferait echouer l'ecriture, pas seulement mal afficher.
      expect(PositionLecture.zoomMin, 0.5);
      expect(PositionLecture.zoomMax, 4);
    });

    test('changer de page garde le grossissement choisi', () {
      const PositionLecture position = PositionLecture(
        page: 1,
        sourate: 1,
        verset: 1,
        zoom: 1.6,
      );

      expect(position.versPage(42, 2, 255).zoom, 1.6);
      expect(position.versPage(42, 2, 255).page, 42);
      expect(position.versPage(42, 2, 255).verset, 255);
    });

    test('une ligne de base illisible ne casse pas la lecture', () {
      final PositionLecture position = PositionLecture.depuisJson(
        const <String, dynamic>{},
      );

      expect(position.page, 1);
      expect(position.sourate, 1);
      expect(position.verset, 1);
      expect(position.zoom, 1);
    });
  });

  group('J6 : rien ici ne designe un fichier', () {
    test('un verset ne porte que sa place et son texte', () {
      const VersetCoran verset = VersetCoran(
        sourateNumero: 2,
        numero: 255,
        texte: 'x',
        pageNumero: 42,
      );

      // Le jour ou le rendu passerait aux glyphes d'une edition, il gagnerait
      // une colonne de plus ici, jamais un chemin de fichier : c'est ce qui
      // rend l'invariant J6 verifiable plutot que declaratif.
      expect(verset.reference, '2:255');
      expect(verset.pageNumero, 42);
    });

    test('le code de l’edition est un code, pas un identifiant genere', () {
      // Un uuid en dur marcherait en production et nulle part ailleurs : la
      // ligne `mushaf` est creee avec `gen_random_uuid()` par 0007.
      expect(codeMushafReference, 'madina-hafs-604');
    });
  });
}
