// TRANSPARENCE (30/10/2026) : l'adaptateur de `politique_commerciale_famille`.
// Le JSON de reference est celui que rend reellement la fonction sur une base
// rejouee (migration 20261031100000), lue par un tuteur le 30/10 : v1.0.0 en
// vigueur, repartition de la v2.0.0 a venir.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/politiques_commerciales_supabase.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/finance/politique_commerciale.dart';
import 'package:rewayah_academy/core/finance/politique_famille.dart';

const String _serveur =
    '{"version": "v1.0.0", "dateEffet": "2026-10-01", "essaisMax": 2, '
    '"essaiActif": true, "railsActifs": ["webStripe"], "repartition": '
    '{"postes": [{"poste": "enseignant", "pourMille": 470}, {"poste": '
    '"frais_carte_change", "pourMille": 50}, {"poste": "frais_envoi_paie", '
    '"pourMille": 11}, {"poste": "visioconference", "pourMille": 25}, '
    '{"poste": "application_hebergement", "pourMille": 48}, {"poste": '
    '"emails", "pourMille": 3}, {"poste": "stockage", "pourMille": 1}, '
    '{"poste": "comptabilite", "pourMille": 25}, {"poste": "developpement", '
    '"pourMille": 100}, {"poste": "administration", "pourMille": 83}, '
    '{"poste": "impot_societes", "pourMille": 35}, {"poste": "benefice", '
    '"pourMille": 149}], "dateEffet": "2026-11-01", "politiqueVersion": '
    '"v2.0.0", "baseElevesAdultes": 50, "baseElevesEnfants": 50}, '
    '"tarifAdulte": {"devise": "USD", "mineur": 6000}, "tarifEnfant": '
    '{"devise": "USD", "mineur": 5000}, "remisesParRang": [{"remise": '
    '{"devise": "USD", "mineur": -500}, "aPartirDuRang": 3}, {"remise": '
    '{"devise": "USD", "mineur": -700}, "aPartirDuRang": 4}]}';

Map<String, dynamic> _brut() => jsonDecode(_serveur) as Map<String, dynamic>;

void main() {
  test('la fonction appelee est celle de la famille, jamais celle de la '
      'direction', () async {
    final List<String> appels = <String>[];
    final PolitiqueFamille p = await PolitiqueFamilleSupabase.avecAppel((
      f,
      _,
    ) async {
      appels.add(f);
      return _brut();
    }).lire();
    expect(appels, <String>['politique_commerciale_famille']);
    expect(p.version, 'v1.0.0');
  });

  test('decodage du JSON reel : tarifs, essai, remises, moyens, repartition '
      'dans l ordre du serveur', () {
    final PolitiqueFamille p = politiqueFamilleJson(_brut());
    expect(p.dateEffet, DateTime(2026, 10));
    expect(p.tarifEnfant, const Montant(5000, 'USD'));
    expect(p.tarifAdulte, const Montant(6000, 'USD'));
    expect(p.essaiActif, isTrue);
    expect(p.essaisMax, 2);
    expect(p.remisesParRang, hasLength(2));
    expect(p.railsActifs, <RailPaiement>{RailPaiement.webStripe});
    final RepartitionPaiement r = p.repartition!;
    expect(r.politiqueVersion, 'v2.0.0');
    expect(r.dateEffet, DateTime(2026, 11));
    expect((r.baseElevesEnfants, r.baseElevesAdultes), (50, 50));
    expect(r.postes.first, (
      poste: PosteRepartition.enseignant,
      pourMille: 470,
    ));
    expect(r.postes.last.poste, PosteRepartition.benefice);
    expect(r.postes.map((PartPoste x) => x.poste).toSet(), hasLength(12));
    expect(
      r.postes.fold<int>(0, (int s, PartPoste x) => s + x.pourMille),
      1000,
    );
  });

  test('sans repartition publiee : null, pas une erreur', () {
    final Map<String, dynamic> j = _brut()..['repartition'] = null;
    expect(politiqueFamilleJson(j).repartition, isNull);
  });

  test('une somme qui ne fait pas 1000 ou un poste inconnu sont refuses', () {
    final Map<String, dynamic> somme = _brut();
    ((somme['repartition'] as Map<String, dynamic>)['postes'] as List<dynamic>)
        .removeLast();
    expect(() => politiqueFamilleJson(somme), throwsFormatException);
    final Map<String, dynamic> inconnu = _brut();
    (((inconnu['repartition'] as Map<String, dynamic>)['postes']
                    as List<dynamic>)
                .first
            as Map<String, dynamic>)['poste'] =
        'loyer';
    expect(() => politiqueFamilleJson(inconnu), throwsFormatException);
  });
}
