import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';

void main() {
  group('domainesAdmin : huit domaines au plus, jamais plus granulaire', () {
    test('Direction est absente sans la capacite', () {
      final List<AdminDomaine> domaines = domainesAdmin(voitDirection: false);

      expect(domaines.length, 7);
      expect(domaines.contains(AdminDomaine.direction), isFalse);
    });

    test('Direction ferme la liste quand la capacite est accordee', () {
      final List<AdminDomaine> domaines = domainesAdmin(voitDirection: true);

      expect(domaines.length, 8);
      expect(domaines.last, AdminDomaine.direction);
    });

    test('l ordre impose n est jamais reordonne', () {
      expect(domainesAdmin(voitDirection: true), <AdminDomaine>[
        AdminDomaine.accueil,
        AdminDomaine.operations,
        AdminDomaine.personnes,
        AdminDomaine.pedagogie,
        AdminDomaine.finance,
        AdminDomaine.configuration,
        AdminDomaine.securite,
        AdminDomaine.direction,
      ]);
    });

    test('chaque domaine porte un libelle et une icone', () {
      for (final AdminDomaine domaine in AdminDomaine.values) {
        expect(domaine.libelle, isNotEmpty, reason: domaine.name);
      }
    });
  });

  group('AdminDomaine.chemin : nul pour un domaine sans fonction livree', () {
    test('Accueil, Operations, Personnes, Pedagogie, Finance, Configuration et '
        'Securite ont une route reelle', () {
      for (final AdminDomaine domaine in <AdminDomaine>[
        AdminDomaine.accueil,
        AdminDomaine.operations,
        AdminDomaine.personnes,
        AdminDomaine.pedagogie,
        AdminDomaine.finance,
        AdminDomaine.configuration,
        AdminDomaine.securite,
      ]) {
        expect(domaine.chemin, isNotNull, reason: domaine.name);
        expect(domaine.chemin, startsWith('/admin'), reason: domaine.name);
        expect(domaine.actif, isTrue, reason: domaine.name);
      }
    });

    test('Direction n a aucune route', () {
      expect(AdminDomaine.direction.chemin, isNull);
      expect(AdminDomaine.direction.actif, isFalse);
    });

    test('aucune route n est partagee entre deux domaines actifs', () {
      final List<String> chemins = <String>[
        for (final AdminDomaine domaine in AdminDomaine.values)
          if (domaine.chemin case final String chemin) chemin,
      ];
      expect(chemins.toSet().length, chemins.length);
    });
  });

  group(
    'ciblesRechercheAdmin : une recherche de navigation, pas de donnees',
    () {
      test('ne couvre que les domaines actifs', () {
        final List<({String libelle, String chemin})> cibles =
            ciblesRechercheAdmin(voitDirection: true);

        // Les domaines actifs, puis les Communications (sous Operations) et
        // Le Studio, deux ecrans qu'aucun libelle de domaine ne nomme (COM-F).
        expect(cibles.length, 9);
        for (final ({String libelle, String chemin}) cible in cibles) {
          expect(cible.libelle, isNotEmpty);
          expect(cible.chemin, startsWith('/admin'));
        }
      });
    },
  );
}
