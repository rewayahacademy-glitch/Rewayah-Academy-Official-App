import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_position.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/port_catalogue.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/vue_catalogue.dart';
import 'package:rewayah_academy/core/tc_telechargement/port_etat_offline.dart';

import 'faux/faux_ports_b.dart';

VueCatalogue vue({
  ContexteDecouverte contexte = ContexteDecouverte.horsClasse,
  List<LibraryResource> tous = const <LibraryResource>[],
  List<LibraryResource> recents = const <LibraryResource>[],
  List<LibraryResource> pourGroupe = const <LibraryResource>[],
  Map<String, EtatOffline> etats = const <String, EtatOffline>{},
  bool horsLigne = false,
  ReprisLecture? reprise,
  String requete = '',
  FiltreCatalogue? filtre,
  bool chargement = false,
  bool echec = false,
}) => VueCatalogue.depuis(
  contexte: contexte,
  tous: tous,
  recents: recents,
  pourGroupe: pourGroupe,
  etatsOffline: etats,
  horsLigne: horsLigne,
  reprise: reprise,
  requete: requete,
  filtre: filtre,
  chargement: chargement,
  echec: echec,
);

void main() {
  group('Etats : vide, sans resultat, indisponible ne se confondent pas', () {
    test('un catalogue vide est un vide subi', () {
      expect(vue().etat, EtatCatalogue.vide);
    });

    test('un filtre sans resultat n est pas un catalogue vide', () {
      final VueCatalogue v = vue(
        tous: <LibraryResource>[ressource(id: 'r1')],
        requete: 'introuvable',
      );

      // Les deux ouvrent un ecran sans carte, et ils ne disent pas la meme
      // chose : l'un se subit, l'autre se relache.
      expect(v.etat, EtatCatalogue.aucunResultat);
      expect(v.rechercheActive, isTrue);
    });

    test('un echec de lecture n est pas une absence', () {
      expect(vue(echec: true).etat, EtatCatalogue.indisponible);
      expect(
        vue(tous: <LibraryResource>[ressource(id: 'r1')], echec: true).etat,
        EtatCatalogue.indisponible,
      );
    });

    test('le chargement precede tout le reste', () {
      expect(vue(chargement: true).etat, EtatCatalogue.chargement);
    });
  });

  group('Sections : l ordre de decouverte change avec le contexte', () {
    final List<LibraryResource> trois = <LibraryResource>[
      ressource(id: 'r1'),
      ressource(id: 'r2'),
      ressource(id: 'r3'),
    ];

    test('hors classe : ce groupe, recents, tous les supports', () {
      final VueCatalogue v = vue(
        tous: trois,
        recents: <LibraryResource>[trois[1]],
        pourGroupe: <LibraryResource>[trois[0]],
      );

      expect(
        v.sections.map((SectionCatalogue s) => s.id),
        <IdSectionCatalogue>[
          IdSectionCatalogue.pourCeGroupe,
          IdSectionCatalogue.recents,
          IdSectionCatalogue.tousLesSupports,
        ],
      );
    });

    test('en classe : recents d abord (spec section 6.2)', () {
      final VueCatalogue v = vue(
        contexte: ContexteDecouverte.enClasse,
        tous: trois,
        recents: <LibraryResource>[trois[1]],
        pourGroupe: <LibraryResource>[trois[0]],
      );

      expect(
        v.sections.map((SectionCatalogue s) => s.id),
        <IdSectionCatalogue>[
          IdSectionCatalogue.recents,
          IdSectionCatalogue.pourCeGroupe,
          IdSectionCatalogue.tousLesSupports,
        ],
      );
    });

    test('une section vide ne s affiche pas', () {
      final VueCatalogue v = vue(tous: trois);

      expect(v.sections.length, 1);
      expect(v.sections.single.id, IdSectionCatalogue.tousLesSupports);
    });

    test('une recherche remplace les sections par une seule', () {
      final VueCatalogue v = vue(
        tous: trois,
        recents: <LibraryResource>[trois[1]],
        requete: 'Support r2',
      );

      expect(v.sections.single.id, IdSectionCatalogue.resultats);
      expect(v.sections.single.ressources.single.id, 'r2');
    });
  });

  group('Continuer : contextuel, jamais permanent', () {
    final LibraryResource r = ressource(id: 'r1');
    final ReprisLecture reprise = ReprisLecture(
      ressource: r,
      position: const ContentPosition.page(resourceId: 'r1', page: 12),
      vueLeUtc: DateTime.utc(2026, 9, 19, 18),
    );

    test('sans reprise, aucune section Continuer', () {
      expect(vue(tous: <LibraryResource>[r]).reprise, isNull);
    });

    test('une reprise seule suffit a sortir du vide', () {
      final VueCatalogue v = vue(reprise: reprise);

      expect(v.etat, EtatCatalogue.contenu);
      expect(v.reprise?.position.page, 12);
    });

    test('la reprise disparait pendant une recherche', () {
      final VueCatalogue v = vue(
        tous: <LibraryResource>[r],
        reprise: reprise,
        requete: 'Support',
      );

      expect(v.reprise, isNull);
      expect(v.rechercheActive, isTrue);
    });
  });

  group('Hors ligne : ce qui reste ouvrable', () {
    final LibraryResource r = ressource(id: 'r1');

    test('en ligne, tout ce qui est publie est ouvrable', () {
      expect(vue(tous: <LibraryResource>[r]).ouvrable(r), isTrue);
    });

    test('une ressource sans version publiee n est jamais ouvrable', () {
      final LibraryResource brouillon = ressource(
        id: 'r2',
        versionCourante: null,
      );

      expect(vue(tous: <LibraryResource>[brouillon]).ouvrable(brouillon),
          isFalse);
    });

    test('hors ligne, seules les ressources locales s ouvrent', () {
      VueCatalogue avec(EtatOffline etat) => vue(
        tous: <LibraryResource>[r],
        horsLigne: true,
        etats: <String, EtatOffline>{'r1': etat},
      );

      expect(avec(EtatOffline.telecharge).ouvrable(r), isTrue);
      expect(avec(EtatOffline.enCache).ouvrable(r), isTrue);
      expect(avec(EtatOffline.aTelecharger).ouvrable(r), isFalse);
      expect(avec(EtatOffline.indisponible).ouvrable(r), isFalse);
    });

    test('hors ligne, la carte reste listee : elle n est pas retiree', () {
      final VueCatalogue v = vue(
        tous: <LibraryResource>[r],
        horsLigne: true,
        etats: const <String, EtatOffline>{'r1': EtatOffline.aTelecharger},
      );

      // La retirer ferait croire a une perte de droit ; elle reste visible et
      // porte sa raison.
      expect(v.sections.single.ressources.single.id, 'r1');
      expect(v.ouvrable(r), isFalse);
    });

    test('un etat non mesure vaut indisponible, jamais disponible', () {
      expect(vue().etatOffline('inconnue'), EtatOffline.indisponible);
    });
  });

  group('Volume : plusieurs centaines de ressources', () {
    test('la composition reste lineaire et ne perd rien', () {
      final List<LibraryResource> beaucoup = List<LibraryResource>.generate(
        500,
        (int i) => ressource(id: 'r$i', titre: 'Support numero $i'),
      );

      final Stopwatch chrono = Stopwatch()..start();
      final VueCatalogue v = vue(tous: beaucoup);
      chrono.stop();

      expect(v.sections.single.ressources.length, 500);
      // Borne large et volontairement grossiere : elle n'existe pas pour
      // mesurer une machine, mais pour attraper une composition quadratique.
      expect(chrono.elapsedMilliseconds, lessThan(500));
    });

    test('une recherche sur 500 ressources rend exactement les bonnes', () {
      final List<LibraryResource> beaucoup = List<LibraryResource>.generate(
        500,
        (int i) => ressource(id: 'r$i', titre: 'Support numero $i'),
      );

      final VueCatalogue v = vue(tous: beaucoup, requete: 'numero 499');

      expect(v.sections.single.ressources.single.id, 'r499');
    });
  });

  group('Une seule ressource', () {
    test('un catalogue d une ressource affiche une section et une carte', () {
      final VueCatalogue v = vue(tous: <LibraryResource>[ressource(id: 'r1')]);

      expect(v.etat, EtatCatalogue.contenu);
      expect(v.sections.single.ressources.length, 1);
    });
  });
}
