// LP-2 : l'adaptateur de `lister_enseignants` envoie exactement les cles que le
// serveur connait, lit la page telle qu'il la rend, et traduit ses refus.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/enseignants/enseignants_supabase.dart';
import 'package:rewayah_academy/core/enseignants/modeles_enseignants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, Object?> _ligne(String id, String phase) => <String, Object?>{
  'id': id,
  'reference': 'CAND-$id',
  'nomComplet': 'Personne $id',
  'type': 'enseignant',
  'etape': 'confirmee',
  'etat': null,
  'issue': 'en_cours',
  'enPause': false,
  'restreinte': false,
  'indisponible': false,
  'paiement': 'compatible',
  'courrielAObtenir': false,
  'indicatifAConfirmer': false,
  'derniereActivite': '2026-11-16T09:00:00Z',
  'nouveau': true,
  'phase': phase,
  'manque': <String>['photo_absente', 'cle_inconnue'],
  'quiAttend': 'enseignant',
  'classes': <String, Object>{'nombre': 2, 'heuresSemaine': 3.5},
  'prochaineSeance': '2026-11-20T18:00:00Z',
  'remplacements30j': <String, Object>{'donnes': 1, 'recus': 2},
  'coordonneesVersement': true,
  'gestes': <String>['refuser'],
  'gestesGroupables': <String>['refuser'],
  'actionsPhase': <String>['affecter_classe'],
};

Map<String, Object?> _page() => <String, Object?>{
  'lignes': <Object?>[_ligne('a', 'en_poste'), _ligne('b', 'phase_future')],
  'total': 51,
  'page': 1,
  'taillePage': 50,
  'compteursPhases': <String, Object>{
    'en_poste': 1,
    'accueil': 2,
    'nouveaux': 3,
    'sansDossier': 4,
  },
};

void main() {
  test('le filtre part avec les seules cles posees', () {
    expect(const FiltreEnseignants().enJson(), isEmpty);
    expect(
      const FiltreEnseignants(
        recherche: ' Amina ',
        phase: PhaseEnseignant.enPoste,
        nouveau: true,
        partis: true,
      ).enJson(),
      <String, Object>{
        'recherche': 'Amina',
        'phase': 'en_poste',
        'nouveau': true,
        'partis': true,
      },
    );
  });

  test('la page lue : lignes, phases, gestes, compteurs ; une phase inconnue n\'est pas devinee', () async {
    final List<String> appels = <String>[];
    final EnseignantsSupabase port = EnseignantsSupabase.avecAppel((
      String f,
      Map<String, dynamic> p,
    ) async {
      appels.add('$f $p');
      return _page();
    });
    final PageEnseignants page = await port.lister(
      filtre: const FiltreEnseignants(phase: PhaseEnseignant.enPoste),
      tri: TriEnseignants.nom,
      page: 2,
    );
    expect(
      appels.single,
      'lister_enseignants {p_filtre: {phase: en_poste}, p_tri: nom, p_page: 2}',
    );
    // La ligne de phase inconnue n'est pas inventee.
    expect(page.lignes, hasLength(1));
    final LigneEnseignant l = page.lignes.single;
    expect(l.phase, PhaseEnseignant.enPoste);
    expect(l.dossier.nouveau, isTrue);
    expect(l.manque, <String>['photo_absente', 'cle_inconnue']);
    expect(l.quiAttend, 'enseignant');
    expect(l.classes.nombre, 2);
    expect(l.classes.heuresSemaine, 3.5);
    expect(l.remplacements.donnes, 1);
    expect(l.remplacements.recus, 2);
    expect(l.prochaineSeance, isNotNull);
    expect(l.coordonneesVersement, isTrue);
    expect(l.gestes, <String>['refuser']);
    expect(l.gestesGroupables, <String>['refuser']);
    expect(l.actionsPhase, <String>['affecter_classe']);
    expect(page.total, 51);
    expect(page.pages, 2);
    expect(page.compteurs.de(PhaseEnseignant.enPoste), 1);
    expect(page.compteurs.de(PhaseEnseignant.parti), 0);
    expect(page.compteurs.nouveaux, 3);
    expect(page.compteurs.sansDossier, 4);
  });

  test('une reponse sans total n\'est pas une page', () async {
    final EnseignantsSupabase port = EnseignantsSupabase.avecAppel(
      (String _, Map<String, dynamic> _) async => <String, Object>{},
    );
    await expectLater(
      port.lister(
        filtre: const FiltreEnseignants(),
        tri: TriEnseignants.activite,
        page: 1,
      ),
      throwsFormatException,
    );
  });

  test('les refus du serveur sont traduits', () async {
    Future<void> avec(PostgrestException e) =>
        EnseignantsSupabase.avecAppel(
          (String _, Map<String, dynamic> _) async => throw e,
        ).lister(
          filtre: const FiltreEnseignants(),
          tri: TriEnseignants.activite,
          page: 1,
        );
    await expectLater(
      avec(const PostgrestException(message: 'x', code: 'PGRST202')),
      throwsA(isA<CapaciteIndisponible>()),
    );
    await expectLater(
      avec(
        const PostgrestException(
          message: 'genre du lecteur inconnu : ...',
          code: '42501',
        ),
      ),
      throwsA(isA<GenreLecteurInconnu>()),
    );
    await expectLater(
      avec(const PostgrestException(message: 'reserve', code: '42501')),
      throwsA(isA<PermissionInsuffisante>()),
    );
  });
}
