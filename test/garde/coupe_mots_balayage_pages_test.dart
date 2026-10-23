// COUPE-MOTS-FOND-1 : la garde du rendu sur les pages a collection et a
// filtres, chacune sur ses doubles : Comptes, Journal, Observations,
// Progression, Evaluations, Qualite, Programmes, Classes, Historique du
// controleur, Bibliotheque. Trois gabarits (320 x 568 texte x2, 390 x 844,
// 1440 x 900 texte x2), francais et arabe, standard et Interface guidee,
// page defilee de haut en bas (`test/support/balayage_ecrans.dart`).
//
// Les jeux de donnees portent ce que la fiche a vu couper : des dates
// (« 23/09/2026 »), des heures (« 18:12:00 »), des identifiants longs
// (« TEACHER-AS-000001 »), des etats longs (« Sortie non enregistree »).

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/journal/service_journal.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/features/admin_comptes/comptes_page.dart';
import 'package:rewayah_academy/features/admin_journal/journal_page.dart';
import 'package:rewayah_academy/features/tc_catalogue/bibliotheque_page.dart';

import '../features/filtres1_rangee_unique_test.dart'
    show CasFiltres1, casFiltres1;
import '../support/balayage_ecrans.dart';
import '../support/doubles_balayage.dart';
import '../teaching_core/b/faux/faux_ports_b.dart'
    show ressource, surchargesCatalogue;

/// Les pages balayees.
List<EcranBalayage> ecransPages() => <EcranBalayage>[
  (
    nom: 'Comptes',
    page: () => const ComptesPage(),
    routeur: null,
    depart: null,
    surcharges: () => <Override>[
      reseauBalayage(),
      serviceComptesProvider.overrideWithValue(ComptesBalayage()),
    ],
  ),
  (
    nom: 'Journal',
    page: () => const JournalPage(),
    routeur: null,
    depart: null,
    surcharges: () => <Override>[
      reseauBalayage(),
      serviceJournalProvider.overrideWithValue(journalBalayage()),
    ],
  ),
  (
    nom: 'Bibliotheque',
    page: () => const BibliothequePage(),
    routeur: null,
    depart: null,
    surcharges: () => surchargesCatalogue(
      ressources: <LibraryResource>[
        ressource(id: 'r1', titre: 'Alphabet'),
        ressource(id: 'r2', titre: 'Les regles du Tajwid'),
      ],
    ),
  ),
  // Les autres pages de FILTRES-1, sur les memes doubles.
  for (final CasFiltres1 c in casFiltres1().where(
    (CasFiltres1 c) =>
        !c.nom.startsWith('Comptes') &&
        !c.nom.startsWith('Journal') &&
        !c.nom.startsWith('Bibliotheque') &&
        !c.nom.startsWith('Historique du foyer'),
  ))
    (
      nom: c.nom,
      page: () =>
          casFiltres1().firstWhere((CasFiltres1 x) => x.nom == c.nom).ecran,
      routeur: null,
      depart: null,
      surcharges: () => casFiltres1()
          .firstWhere((CasFiltres1 x) => x.nom == c.nom)
          .surcharges,
    ),
];

void main() {
  balayer(ecransPages());
}
