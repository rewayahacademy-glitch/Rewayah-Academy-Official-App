// CLOCHE-C : la source de la cloche lit le port du contrat du 21/11 (lot
// ANNONCES-SERVEUR) : pagination, fermeture, traduction.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/com_annonces/port_annonces_direction.dart';
import 'package:rewayah_academy/features/notifications/cloche/annonces_cloche.dart';

class _Port implements PortAnnoncesDirection {
  final List<({int limite, DateTime? avant, bool fermees})> pages =
      <({int limite, DateTime? avant, bool fermees})>[];
  final List<String> fermees = <String>[];
  final List<String> rouvertes = <String>[];
  final List<String> vues = <String>[];

  @override
  Future<PageAnnonces> mesAnnonces({
    int limite = 20,
    DateTime? avant,
    bool fermees = false,
  }) async {
    pages.add((limite: limite, avant: avant, fermees: fermees));
    return PageAnnonces(
      annonces: <AnnonceRecue>[
        AnnonceRecue(
          id: 'a1',
          titre: 'Titre traduit',
          texte: 'Texte traduit',
          titreOriginal: 'عنوان',
          texteOriginal: 'نص',
          langueOriginale: 'ar',
          traduite: true,
          publieeLe: DateTime.utc(2026, 11, 21),
          fermee: true,
        ),
      ],
      suite: DateTime.utc(2026, 11, 20),
    );
  }

  @override
  Future<void> fermer(String id) async => fermees.add(id);

  @override
  Future<void> rouvrir(String id) async => rouvertes.add(id);

  @override
  Future<void> marquerVue(String id) async => vues.add(id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'la page, la suite, la traduction et la fermeture viennent du port',
    () async {
      final _Port port = _Port();
      final SourceAnnoncesDepuisPort source = SourceAnnoncesDepuisPort(port);
      expect(source.fermetureServie, isTrue);
      final DateTime avant = DateTime.utc(2026, 11, 22);
      final PageAnnoncesCloche page = await source.page(
        avant: avant,
        fermees: true,
      );
      expect(port.pages.single, (limite: 20, avant: avant, fermees: true));
      expect(page.suite, DateTime.utc(2026, 11, 20));
      final AnnonceCloche a = page.annonces.single;
      expect(a.titre, 'Titre traduit');
      expect(a.aUnOriginal, isTrue);
      expect(a.texteOriginal, 'نص');
      expect(a.langueOriginale, 'ar');
      expect(a.fermee, isTrue);
      await source.fermer('a1');
      await source.rouvrir('a1');
      await source.marquerVue('a1');
      expect(port.fermees, <String>['a1']);
      expect(port.rouvertes, <String>['a1']);
      expect(port.vues, <String>['a1']);
    },
  );

  test('sans source d annonces, aucune croix', () {
    expect(
      const SourceAnnoncesDepuisPort(AnnoncesDirectionIndisponibles())
          .fermetureServie,
      isFalse,
    );
  });
}
