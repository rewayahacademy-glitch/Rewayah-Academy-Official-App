// Decision du directeur (11/10/2026) : le partage automatique est ACTIVE par
// defaut. La demonstration le montre : un passage a `false` fait tomber ce test.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/partage_pedagogique_demonstration.dart';
import 'package:rewayah_academy/core/capacites/port_partage_pedagogique.dart';

void main() {
  test('la demonstration part avec le partage de classe ACTIF', () async {
    final PartagePedagogiqueDemonstration d = PartagePedagogiqueDemonstration();
    final PartageClasse p = await d.partageClasse(classeId: 'c');
    expect(p.actif, isTrue);
    // Un eleve sans exception suit la classe : visible.
    final PartageEleve suit = p.eleves.firstWhere(
      (PartageEleve e) => e.regle == ReglePartageEleve.regleClasse,
    );
    expect(suit.visible, isTrue);
    expect(suit.source, SourceRegle.classe);
    // Et son compte rendu est lisible de la famille, par defaut.
    final CompteRenduFamille c = await d.compteRenduFamille(
      seanceId: 'demo-seance-1',
      eleveId: suit.eleveId,
    );
    expect(c.etat, EtatCompteRendu.partage);
  });
}
