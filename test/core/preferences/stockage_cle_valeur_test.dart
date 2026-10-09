// PUB-1 (reprise apres revue adverse) : la persistance de la PWA, hors
// navigateur. Le `localStorage` est remplace par une table qui survit au
// « rechargement » (un nouveau conteneur) ; la logique testee est celle que
// le web emploie (`StockagePreferencesNavigateur` en herite).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/preferences/presentation_vue.dart';
import 'package:rewayah_academy/core/preferences/stockage_cle_valeur.dart';

/// Un `localStorage` de test : une table, ou une panne a chaque appel, ou
/// (PUB-1b) une panne a l'ecriture seulement (quota plein, Safari prive).
class _FauxLocalStorage implements AccesCleValeur {
  _FauxLocalStorage({this.enPanne = false, this.ecritureEnPanne = false});

  final bool enPanne;
  final bool ecritureEnPanne;
  final Map<String, String> table = <String, String>{};

  @override
  String? lire(String clef) {
    if (enPanne) throw StateError('SecurityError');
    return table[clef];
  }

  @override
  void ecrire(String clef, String valeur) {
    if (enPanne || ecritureEnPanne) throw StateError('QuotaExceededError');
    table[clef] = valeur;
  }
}

/// Une visite : un conteneur neuf (comme un onglet recharge), pose sur le
/// meme stockage durable ; rend l'etat lu.
Future<(ProviderContainer, EtatPresentation)> _visite(
  AccesCleValeur? acces,
) async {
  final ProviderContainer c = ProviderContainer(
    overrides: <Override>[
      stockagePresentationProvider.overrideWithValue(
        StockagePreferencesCleValeur(acces),
      ),
    ],
  );
  addTearDown(c.dispose);
  c.read(presentationProvider.notifier).charger();
  await Future<void>.delayed(Duration.zero);
  return (c, c.read(presentationProvider));
}

void main() {
  test(
    'vue une fois : apres la croix, le rechargement mene a la connexion',
    () async {
      final _FauxLocalStorage stockage = _FauxLocalStorage();

      final (ProviderContainer premiere, EtatPresentation avant) =
          await _visite(stockage);
      expect(avant, EtatPresentation.aVoir);
      await premiere.read(presentationProvider.notifier).marquerVue();
      expect(stockage.table[clefPresentationVue], 'oui');

      final (_, EtatPresentation apres) = await _visite(stockage);
      expect(apres, EtatPresentation.vue);
    },
  );

  test('stockage bloque : la presentation s affiche, rien ne casse', () async {
    final _FauxLocalStorage bloque = _FauxLocalStorage(enPanne: true);
    final (ProviderContainer c, EtatPresentation etat) = await _visite(bloque);
    expect(etat, EtatPresentation.aVoir);
    await c.read(presentationProvider.notifier).marquerVue();
    expect(c.read(presentationProvider), EtatPresentation.vue);
    // La valeur reste en memoire pour la session.
    expect(
      await c.read(stockagePresentationProvider).lire(clefPresentationVue),
      'oui',
    );
  });

  test('sans localStorage : comportement de premiere visite', () async {
    final (_, EtatPresentation etat) = await _visite(null);
    expect(etat, EtatPresentation.aVoir);
  });

  // PUB-1b (reserve 2 de la relecture R2) : le stockage se lit mais refuse
  // l'ecriture. La valeur notee reste en memoire pour la session : une
  // nouvelle lecture rend « oui », jamais le `null` du stockage durable.
  test(
    'lecture possible, ecriture en echec : le secours en memoire repond',
    () async {
      final _FauxLocalStorage quotaPlein = _FauxLocalStorage(
        ecritureEnPanne: true,
      );
      final StockagePreferencesCleValeur stockage =
          StockagePreferencesCleValeur(quotaPlein);

      expect(await stockage.lire(clefPresentationVue), isNull);
      await stockage.ecrire(clefPresentationVue, 'oui');
      expect(quotaPlein.table, isEmpty);
      expect(await stockage.lire(clefPresentationVue), 'oui');

      // Par le fournisseur : la croix note la visite, l'etat relu reste
      // « vue » pendant la session.
      final (ProviderContainer c, EtatPresentation etat) = await _visite(
        quotaPlein,
      );
      expect(etat, EtatPresentation.aVoir);
      await c.read(presentationProvider.notifier).marquerVue();
      expect(c.read(presentationProvider), EtatPresentation.vue);
      expect(
        await c.read(stockagePresentationProvider).lire(clefPresentationVue),
        'oui',
      );

      // Au rechargement, rien n'a ete garde : premiere visite, sans blocage.
      final (_, EtatPresentation apres) = await _visite(quotaPlein);
      expect(apres, EtatPresentation.aVoir);
    },
  );
}
