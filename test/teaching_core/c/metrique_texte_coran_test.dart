import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/tc_coran/metrique_texte_coran.dart';

/// Les largeurs reellement rencontrees, du plus petit telephone au desktop.
const List<double> _largeurs = <double>[320, 360, 390, 430, 600, 834, 1280];

/// Les zooms que la base accepte, bornes compris.
const List<double> _zooms = <double>[0.5, 0.8, 1, 1.5, 2, 3, 4];

void main() {
  group('le reflow ne deborde a aucune largeur', () {
    test('le plus long mot du corpus tient toujours dans la colonne', () {
      for (final double largeur in _largeurs) {
        for (final double zoom in _zooms) {
          final MetriqueTexteCoran m = MetriqueTexteCoran.calculer(
            largeurDisponible: largeur,
            zoom: zoom,
            marge: 16,
          );

          expect(
            m.largeurMotLePlusLong,
            lessThanOrEqualTo(m.largeurColonne + 0.001),
            reason: 'largeur $largeur, zoom $zoom',
          );
        }
      }
    });

    test('la colonne ne depasse jamais la place disponible', () {
      for (final double largeur in _largeurs) {
        for (final double zoom in _zooms) {
          final MetriqueTexteCoran m = MetriqueTexteCoran.calculer(
            largeurDisponible: largeur,
            zoom: zoom,
            marge: 16,
          );

          expect(m.largeurColonne, lessThanOrEqualTo(largeur - 32 + 0.001));
        }
      }
    });

    test('une largeur nulle ne produit ni NaN ni taille negative', () {
      final MetriqueTexteCoran m = MetriqueTexteCoran.calculer(
        largeurDisponible: 0,
        zoom: 4,
        marge: 16,
      );

      expect(m.largeurColonne, 0);
      expect(m.tailleTexte, greaterThanOrEqualTo(0));
      expect(m.tailleTexte.isFinite, isTrue);
      expect(m.interligne.isFinite, isTrue);
    });
  });

  group('le zoom est recalcule, jamais applique en echelle', () {
    test('le zoom fait grandir le texte tant que la colonne le permet', () {
      double precedente = 0;
      for (final double zoom in <double>[0.5, 1, 1.5]) {
        final MetriqueTexteCoran m = MetriqueTexteCoran.calculer(
          largeurDisponible: 1280,
          zoom: zoom,
          largeurMaximaleColonne: 800,
        );
        expect(m.tailleTexte, greaterThan(precedente));
        precedente = m.tailleTexte;
      }
    });

    test('le zoom maximal est bride, et la metrique le dit', () {
      final MetriqueTexteCoran m = MetriqueTexteCoran.calculer(
        largeurDisponible: 390,
        zoom: 4,
        marge: 16,
      );

      expect(m.zoomDemande, 4);
      expect(m.zoomApplique, lessThan(4));
      expect(m.zoomBride, isTrue);
    });

    test('un zoom raisonnable n est pas bride', () {
      final MetriqueTexteCoran m = MetriqueTexteCoran.calculer(
        largeurDisponible: 390,
        zoom: 1,
        marge: 16,
      );

      expect(m.zoomBride, isFalse);
      expect(m.zoomApplique, closeTo(1, 0.01));
    });

    test('le zoom est borne aux valeurs que la base accepte', () {
      final MetriqueTexteCoran bas = MetriqueTexteCoran.calculer(
        largeurDisponible: 390,
        zoom: 0.1,
      );
      final MetriqueTexteCoran haut = MetriqueTexteCoran.calculer(
        largeurDisponible: 390,
        zoom: 40,
      );

      expect(bas.zoomDemande, PositionLecture.zoomMin);
      expect(haut.zoomDemande, PositionLecture.zoomMax);
    });

    test('un ecran large laisse plus de course au zoom qu un telephone', () {
      final MetriqueTexteCoran telephone = MetriqueTexteCoran.calculer(
        largeurDisponible: 390,
        zoom: 4,
        marge: 16,
      );
      final MetriqueTexteCoran desktop = MetriqueTexteCoran.calculer(
        largeurDisponible: 1280,
        zoom: 4,
        marge: 32,
        largeurMaximaleColonne: 800,
      );

      expect(desktop.zoomApplique, greaterThan(telephone.zoomApplique));
    });
  });

  group('la mesure vient de la colonne, pas de l appareil', () {
    test('une colonne deux fois plus large porte un texte plus grand', () {
      final MetriqueTexteCoran etroite = MetriqueTexteCoran.calculer(
        largeurDisponible: 300,
        zoom: 1,
      );
      final MetriqueTexteCoran large = MetriqueTexteCoran.calculer(
        largeurDisponible: 420,
        zoom: 1,
      );

      expect(large.tailleTexte, greaterThan(etroite.tailleTexte));
    });

    test('la taille de reference reste dans ses bornes de lisibilite', () {
      final MetriqueTexteCoran enorme = MetriqueTexteCoran.calculer(
        largeurDisponible: 3000,
        zoom: 1,
      );

      // Sans borne, une colonne de 3000 points donnerait un texte de titre.
      expect(enorme.tailleTexte, lessThanOrEqualTo(34.001));
    });

    test('la rosace suit la taille du texte', () {
      final MetriqueTexteCoran m = MetriqueTexteCoran.calculer(
        largeurDisponible: 390,
        zoom: 2,
        marge: 16,
      );

      expect(m.echelleRosace, closeTo(m.tailleTexte / 26, 0.001));
    });

    test('l interligne se resserre quand la taille monte', () {
      final MetriqueTexteCoran petit = MetriqueTexteCoran.calculer(
        largeurDisponible: 320,
        zoom: 0.5,
      );
      final MetriqueTexteCoran grand = MetriqueTexteCoran.calculer(
        largeurDisponible: 800,
        zoom: 2,
      );

      expect(grand.interligne, lessThan(petit.interligne));
      expect(petit.interligne, lessThanOrEqualTo(2.3));
      expect(grand.interligne, greaterThanOrEqualTo(1.7));
    });
  });

  group('estimation de lignes', () {
    test('un texte vide n occupe aucune ligne', () {
      final MetriqueTexteCoran m = MetriqueTexteCoran.calculer(
        largeurDisponible: 390,
        zoom: 1,
      );

      expect(m.lignesEstimees(0), 0);
      expect(m.hauteurEstimee(0), 0);
    });

    test('un texte plus long occupe plus de lignes', () {
      final MetriqueTexteCoran m = MetriqueTexteCoran.calculer(
        largeurDisponible: 390,
        zoom: 1,
      );

      expect(m.lignesEstimees(200), greaterThan(m.lignesEstimees(20)));
      expect(m.hauteurEstimee(200), greaterThan(m.hauteurEstimee(20)));
    });
  });
}
