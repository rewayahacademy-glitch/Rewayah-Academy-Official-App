// LUMIERE-ACCUEILS 1 : les lumieres de l'Accueil de la famille viennent
// seulement d'etats que le serveur rend, avec l'instant du serveur ; un etat
// absent ou illisible ne fait jamais de lumiere.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accueil/signaux_accueils.dart';
import 'package:rewayah_academy/core/accueil/signaux_famille.dart';
import 'package:rewayah_academy/core/capacites/port_partage_pedagogique.dart'
    show EtatCompteRendu;
import 'package:rewayah_academy/core/widgets/halo_lumiere.dart';

final DateTime _now = DateTime.utc(2026, 11, 11, 12);

List<SignalAccueil<MotifFamille>> _s({
  bool acces = false,
  bool salle = false,
  DateTime? now,
  DateTime? prochain,
  bool travail = false,
  EtatCompteRendu? cahier,
  DateTime? derniere,
}) => signauxFamille(
  accesBloque: acces,
  salleRejoignable: salle,
  maintenantServeurUtc: now ?? _now,
  debutProchaineUtc: prochain,
  travailAPreparer: travail,
  etatCahier: cahier,
  debutDerniereUtc: derniere,
);

void main() {
  test('rien a signaler : aucune lumiere', () {
    expect(_s(), isEmpty);
  });

  test('acces bloque : rouge', () {
    expect(_s(acces: true).single.nature, NatureHalo.urgent);
  });

  group('orange : seance dans moins d une heure avec du travail', () {
    test('dans 59 min avec travail : orange', () {
      final s = _s(
        prochain: _now.add(const Duration(minutes: 59)),
        travail: true,
      );
      expect(s.single.nature, NatureHalo.aPreparer);
    });
    test('dans 61 min : rien', () {
      expect(
        _s(prochain: _now.add(const Duration(minutes: 61)), travail: true),
        isEmpty,
      );
    });
    test('dans 30 min sans travail : rien', () {
      expect(_s(prochain: _now.add(const Duration(minutes: 30))), isEmpty);
    });
    test('seance deja commencee : rien', () {
      expect(
        _s(prochain: _now.subtract(const Duration(minutes: 1)), travail: true),
        isEmpty,
      );
    });
    test('sans instant serveur : rien', () {
      expect(
        signauxFamille(
          accesBloque: false,
          salleRejoignable: false,
          maintenantServeurUtc: null,
          debutProchaineUtc: _now.add(const Duration(minutes: 10)),
          travailAPreparer: true,
          etatCahier: null,
          debutDerniereUtc: null,
        ),
        isEmpty,
      );
    });
  });

  group('bleu : cahier partage, 24 h apres la date de la seance', () {
    test('partage, hier : bleu', () {
      final s = _s(
        cahier: EtatCompteRendu.partage,
        derniere: _now.subtract(const Duration(hours: 23)),
      );
      expect(s.single.nature, NatureHalo.nouveau);
    });
    test('partage, il y a 25 h : plus de lumiere', () {
      expect(
        _s(
          cahier: EtatCompteRendu.partage,
          derniere: _now.subtract(const Duration(hours: 25)),
        ),
        isEmpty,
      );
    });
    test('en attente, non partage, sans champ : jamais de bleu', () {
      for (final EtatCompteRendu e in <EtatCompteRendu>[
        EtatCompteRendu.enAttente,
        EtatCompteRendu.nonPartage,
        EtatCompteRendu.aucunChamp,
      ]) {
        expect(
          _s(cahier: e, derniere: _now.subtract(const Duration(hours: 1))),
          isEmpty,
          reason: e.name,
        );
      }
    });
    test('lecture absente : rien', () {
      expect(_s(derniere: _now.subtract(const Duration(hours: 1))), isEmpty);
    });
  });

  test('salle rejoignable : vert', () {
    expect(_s(salle: true).single.nature, NatureHalo.salle);
  });

  test('ordre de priorite : rouge, vert, orange, bleu', () {
    final s = _s(
      acces: true,
      salle: true,
      prochain: _now.add(const Duration(minutes: 20)),
      travail: true,
      cahier: EtatCompteRendu.partage,
      derniere: _now.subtract(const Duration(hours: 2)),
    );
    expect(s.map((x) => x.nature).toList(), <NatureHalo>[
      NatureHalo.urgent,
      NatureHalo.salle,
      NatureHalo.aPreparer,
      NatureHalo.nouveau,
    ]);
    expect(signalDominant(s)!.motif, MotifFamille.acces);
    expect(lumierePourFamille(s, MotifFamille.cahier), NatureHalo.nouveau);
  });
}
