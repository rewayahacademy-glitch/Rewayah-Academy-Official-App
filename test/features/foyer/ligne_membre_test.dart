// La legende d'un membre du Foyer : classe connue ou non, statut d'acces en
// texte, echeance passee jamais dite valide.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/finance/finances_profil.dart';
import 'package:rewayah_academy/core/foyer/selection_eleve.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/offre_horaire.dart';
import 'package:rewayah_academy/core/widgets/badge_periode_financee.dart';
import 'package:rewayah_academy/features/admin_finance/politiques_commerciales.dart'
    show dateEffetEnTexte;
import 'package:rewayah_academy/features/foyer/ligne_membre.dart';

import '../../fixtures/tuteur/faux_classes_foyer.dart';

ProfilEleveFoyer _profil({DateTime? finAcces}) => ProfilEleveFoyer.depuis(
  EleveDuFoyer(
    id: 'foyer-a-eleve-1',
    prenom: 'Élève A1',
    identifiantImmuable: 'STUD-FA-000001',
    mode: InterfaceMode.standard,
    camera: CameraPolicy.forbidden,
    finAcces: finAcces,
  ),
);

void main() {
  final DateTime maintenant = DateTime(2026, 9, 24, 12);

  group('statutAcces', () {
    test('sans echeance', () {
      expect(
        statutAcces(_profil(), maintenant),
        t.foyer.membre.accesSansEcheance,
      );
    });

    test('echeance a venir : date en toutes lettres', () {
      expect(
        statutAcces(_profil(finAcces: DateTime(2026, 10, 30, 9)), maintenant),
        t.foyer.membre.accesJusquau(date: '30 octobre 2026'),
      );
    });

    test('echeance atteinte a l instant meme : expiree, jamais valide', () {
      expect(
        statutAcces(_profil(finAcces: maintenant), maintenant),
        t.foyer.membre.accesExpire(date: '24 septembre 2026'),
      );
    });
  });

  group('R8-05 : « 1er » pour le premier du mois', () {
    test('dateEcheance : « 1er novembre 2026 », puis « 2 novembre 2026 »', () {
      expect(dateEcheance(DateTime(2026, 11, 1, 12)), '1er novembre 2026');
      expect(dateEcheance(DateTime(2026, 11, 2, 12)), '2 novembre 2026');
      expect(dateEcheance(DateTime(2026, 10, 31, 12)), '31 octobre 2026');
    });

    test('la periode financee et la date d effet suivent la meme regle', () {
      expect(
        BadgePeriodeFinancee.phraseDe(
          PeriodeFinancee(
            debut: DateTime(2026, 10, 1, 12),
            fin: DateTime(2026, 12, 1, 12),
          ),
        ),
        t.argent.periode.jusquau(date: '1er décembre 2026'),
      );
      expect(dateEffetEnTexte(DateTime(2027)), '1er janvier 2027');
      expect(dateEffetEnTexte(DateTime(2027, 1, 15)), '15 janvier 2027');
    });
  });

  group('legendeMembre', () {
    test('classe inconnue ou indisponible : rien n est dit de la classe', () {
      for (final ClasseMembre classe in <ClasseMembre>[
        ClasseMembre.inconnue,
        ClasseMembre.indisponible,
      ]) {
        expect(
          legendeMembre(
            profil: _profil(),
            classe: classe,
            maintenant: maintenant,
          ),
          t.foyer.membre.accesSansEcheance,
        );
      }
    });

    test('aucune classe rendue : « Pas encore de classe »', () {
      expect(
        legendeMembre(
          profil: _profil(),
          classe: ClasseMembre.depuis(const <ClasseFoyer>[]),
          maintenant: maintenant,
        ),
        '${t.foyer.membre.sansClasse} · ${t.foyer.membre.accesSansEcheance}',
      );
    });

    test('classes rendues : leurs noms, dans l ordre du port', () {
      expect(
        legendeMembre(
          profil: _profil(),
          classe: ClasseMembre.depuis(<ClasseFoyer>[
            ClasseFoyer(
              eleveId: 'foyer-a-eleve-1',
              classe: classeFictive(libelle: 'Classe B'),
            ),
            ClasseFoyer(
              eleveId: 'foyer-a-eleve-1',
              classe: classeFictive(groupeId: 'classe-c', libelle: 'Classe C'),
            ),
          ]),
          maintenant: maintenant,
        ),
        'Classe B, Classe C · ${t.foyer.membre.accesSansEcheance}',
      );
    });

    test('lecture en echec : « Classe non lue », jamais « pas encore »', () {
      expect(
        legendeMembre(
          profil: _profil(),
          classe: ClasseMembre.echec,
          maintenant: maintenant,
        ),
        '${t.foyer.membre.classeEchec} · ${t.foyer.membre.accesSansEcheance}',
      );
      expect(classeEnEchec(ClasseMembre.echec), isTrue);
      expect(classeIndisponible(ClasseMembre.echec), isFalse);
    });

    test('sans classe, inscription connue : l etape de l inscription', () {
      expect(
        legendeMembre(
          profil: _profil(),
          classe: ClasseMembre.depuis(const <ClasseFoyer>[]),
          maintenant: maintenant,
          inscription: EtapeParcours.groupeEnFormation,
        ),
        '${t.ficheEleve.inscription.classeEnConstitution} · '
        '${t.foyer.membre.accesSansEcheance}',
      );
    });

    test('classe connue : la classe prime sur l inscription', () {
      expect(
        legendeMembre(
          profil: _profil(),
          classe: ClasseMembre.depuis(<ClasseFoyer>[
            ClasseFoyer(
              eleveId: 'foyer-a-eleve-1',
              classe: classeFictive(libelle: 'Classe B'),
            ),
          ]),
          maintenant: maintenant,
          inscription: EtapeParcours.groupeConfirme,
        ),
        'Classe B · ${t.foyer.membre.accesSansEcheance}',
      );
    });
  });

  group('memeEcheance (R1-11)', () {
    test('meme jour, heures differentes : une seule echeance', () {
      expect(
        memeEcheance(DateTime(2026, 10, 31), DateTime(2026, 10, 31, 23, 59)),
        isTrue,
      );
    });

    test('jours differents : deux echeances', () {
      expect(
        memeEcheance(DateTime(2026, 10, 31), DateTime(2026, 11, 1)),
        isFalse,
      );
      expect(
        memeEcheance(DateTime(2026, 10, 31), DateTime(2026, 11, 30)),
        isFalse,
      );
    });

    test('une date absente : jamais la meme echeance', () {
      expect(memeEcheance(null, DateTime(2026, 10, 31)), isFalse);
      expect(memeEcheance(DateTime(2026, 10, 31), null), isFalse);
      expect(memeEcheance(null, null), isFalse);
    });
  });

  group('legendeMembre sans acces (R1-11)', () {
    final DateTime fin = DateTime(2026, 10, 31);

    test('la classe seule, la date d acces n est pas repetee', () {
      final String legende = legendeMembre(
        profil: _profil(finAcces: fin),
        classe: ClasseMembre.depuis(<ClasseFoyer>[
          ClasseFoyer(
            eleveId: 'foyer-a-eleve-1',
            classe: classeFictive(libelle: 'Classe B'),
          ),
        ]),
        maintenant: maintenant,
        avecAcces: false,
      );
      expect(legende, 'Classe B');
      expect(legende, isNot(contains(dateEcheance(fin))));
    });

    test('avec acces, la meme legende dit la date', () {
      expect(
        legendeMembre(
          profil: _profil(finAcces: fin),
          classe: ClasseMembre.depuis(<ClasseFoyer>[
            ClasseFoyer(
              eleveId: 'foyer-a-eleve-1',
              classe: classeFictive(libelle: 'Classe B'),
            ),
          ]),
          maintenant: maintenant,
        ),
        'Classe B · ${t.foyer.membre.accesJusquau(date: dateEcheance(fin))}',
      );
    });

    test('classe inconnue, sans acces : une legende vide', () {
      expect(
        legendeMembre(
          profil: _profil(finAcces: fin),
          classe: ClasseMembre.inconnue,
          maintenant: maintenant,
          avecAcces: false,
        ),
        isEmpty,
      );
    });
  });
}
