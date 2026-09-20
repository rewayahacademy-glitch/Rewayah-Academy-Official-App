import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_position.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_range.dart';
import 'package:rewayah_academy/core/tc_coran/etat_lecture_coran.dart';
import 'package:rewayah_academy/core/tc_coran/page_mushaf_vm.dart';
import 'package:rewayah_academy/core/tc_coran/port_navigation_coran.dart';
import 'package:rewayah_academy/core/tc_coran/ports_externes/marqueur_semantique.dart';
import 'package:rewayah_academy/core/tc_coran/ports_externes/port_etat_partage.dart';

SharedContentState _partage({
  required int revision,
  ModeAffichagePartage mode = ModeAffichagePartage.page,
  int sourate = 2,
  int ayah = 1,
}) => SharedContentState(
  sessionId: 'seance-1',
  resourceId: identifiantRessourceCoran,
  contentPosition: ContentPosition.ayah(
    resourceId: identifiantRessourceCoran,
    sourate: sourate,
    ayah: ayah,
  ),
  displayMode: mode,
  hiddenRanges: const <ContentRange>[],
  semanticMarkers: const <MarqueurSemantique>[],
  revision: revision,
  updatedBy: 'profil-enseignant',
  updatedAtUtc: DateTime.utc(2026, 9, 20, 10),
);

void main() {
  group('etat d ouverture', () {
    test('le lecteur ouvre page 1, en mode mushaf, sans rien ecrire', () {
      const EtatLectureCoran etat = EtatLectureCoran.ouverture();

      expect(etat.page, 1);
      expect(etat.mode, ModeRenduCoran.mushaf);
      expect(etat.zoomLocal, 1);
      // L'origine « ouverture » est ce qui empeche d'ecraser le marque-page
      // par la page d'accueil.
      expect(etat.origine, OrigineNavigation.ouverture);
    });
  });

  group('le zoom est local et le reste', () {
    test('il est borne comme student_reading_position le veut', () {
      const EtatLectureCoran etat = EtatLectureCoran.ouverture();

      expect(etat.versZoom(40).zoomLocal, PositionLecture.zoomMax);
      expect(etat.versZoom(0.01).zoomLocal, PositionLecture.zoomMin);
    });

    test('une revision d etat partage ne le touche pas', () {
      final EtatLectureCoran etat = const EtatLectureCoran.ouverture()
          .versZoom(2.5);

      final EtatLectureCoran apres = etat.fusionnerPartage(
        _partage(revision: 1),
        pagePartagee: 42,
      );

      expect(apres.page, 42);
      expect(apres.zoomLocal, 2.5);
    });
  });

  group('suivi automatique de la classe', () {
    test('l eleve suit sans avoir a appuyer sur quoi que ce soit', () {
      const EtatLectureCoran etat = EtatLectureCoran.ouverture();

      final EtatLectureCoran apres = etat.fusionnerPartage(
        _partage(revision: 3, mode: ModeAffichagePartage.focus),
        pagePartagee: 100,
      );

      expect(apres.page, 100);
      expect(apres.mode, ModeRenduCoran.focus);
      expect(apres.origine, OrigineNavigation.groupe);
      expect(apres.revisionPartageeSuivie, 3);
    });

    test('les trois modes partages se traduisent en trois rendus', () {
      const EtatLectureCoran etat = EtatLectureCoran.ouverture();

      expect(
        etat
            .fusionnerPartage(
              _partage(revision: 1, mode: ModeAffichagePartage.page),
              pagePartagee: 2,
            )
            .mode,
        ModeRenduCoran.mushaf,
      );
      expect(
        etat
            .fusionnerPartage(
              _partage(revision: 1, mode: ModeAffichagePartage.verse),
              pagePartagee: 2,
            )
            .mode,
        ModeRenduCoran.versetAgrandi,
      );
      expect(
        etat
            .fusionnerPartage(
              _partage(revision: 1, mode: ModeAffichagePartage.focus),
              pagePartagee: 2,
            )
            .mode,
        ModeRenduCoran.focus,
      );
    });

    test('un paquet duplique est ignore', () {
      final EtatLectureCoran apres = const EtatLectureCoran.ouverture()
          .fusionnerPartage(_partage(revision: 5), pagePartagee: 50);

      final EtatLectureCoran rejoue = apres.fusionnerPartage(
        _partage(revision: 5),
        pagePartagee: 999,
      );

      expect(rejoue.page, 50);
      expect(rejoue.revisionPartageeSuivie, 5);
    });

    test('un paquet arrive en desordre est ignore', () {
      final EtatLectureCoran apres = const EtatLectureCoran.ouverture()
          .fusionnerPartage(_partage(revision: 5), pagePartagee: 50);

      final EtatLectureCoran vieux = apres.fusionnerPartage(
        _partage(revision: 4),
        pagePartagee: 999,
      );

      expect(vieux.page, 50);
      expect(vieux.revisionPartageeSuivie, 5);
    });

    test('une revision plus recente est prise', () {
      final EtatLectureCoran apres = const EtatLectureCoran.ouverture()
          .fusionnerPartage(_partage(revision: 5), pagePartagee: 50);

      final EtatLectureCoran suivant = apres.fusionnerPartage(
        _partage(revision: 6),
        pagePartagee: 60,
      );

      expect(suivant.page, 60);
      expect(suivant.revisionPartageeSuivie, 6);
    });

    test('aucun etat partage laisse le lecteur ou il est', () {
      final EtatLectureCoran etat = const EtatLectureCoran.ouverture()
          .versPage(12, origine: OrigineNavigation.personnelle);

      expect(etat.fusionnerPartage(null, pagePartagee: 99).page, 12);
    });

    test('une page partagee irresoluble ne deplace pas le lecteur', () {
      // Le cas reel : la position partagee designe une autre ressource, ou un
      // ancrage que le mushaf ne sait pas lire. Mieux vaut rester en place que
      // sauter a la page 1.
      final EtatLectureCoran etat = const EtatLectureCoran.ouverture()
          .versPage(12, origine: OrigineNavigation.personnelle);

      final EtatLectureCoran apres = etat.fusionnerPartage(
        _partage(revision: 1),
        pagePartagee: null,
      );

      expect(apres.page, 12);
      expect(apres.origine, OrigineNavigation.groupe);
    });
  });

  group('origine de navigation', () {
    test('une navigation personnelle porte son origine', () {
      final EtatLectureCoran etat = const EtatLectureCoran.ouverture()
          .versPage(3, origine: OrigineNavigation.personnelle);

      expect(etat.origine, OrigineNavigation.personnelle);
    });

    test('changer de mode ne change pas l origine ni la page', () {
      final EtatLectureCoran etat = const EtatLectureCoran.ouverture()
          .versPage(3, origine: OrigineNavigation.personnelle)
          .versMode(ModeRenduCoran.focus);

      expect(etat.page, 3);
      expect(etat.mode, ModeRenduCoran.focus);
      expect(etat.origine, OrigineNavigation.personnelle);
    });
  });
}
