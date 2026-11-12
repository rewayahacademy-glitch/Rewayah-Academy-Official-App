import 'package:flutter_riverpod/flutter_riverpod.dart';
// Comme partout ailleurs : le type d'une famille de providers n'est pas
// exporte par l'entree principale de Riverpod 3, il vit dans `misc.dart`.
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import 'corpus_service_coran.dart';
import 'layout_lignes_indisponible.dart';
import 'page_mushaf_vm.dart';
import 'port_corpus_coran.dart';
import 'port_layout_mushaf.dart';

/// Les 114 sourates, chargees une fois.
final FutureProvider<List<SourateVM>> souratesCoranProvider =
    FutureProvider<List<SourateVM>>(
      (Ref ref) => ref.watch(portCorpusCoranProvider).sourates(),
    );

/// Ce que la source de layout peut promettre, resolu une fois.
final FutureProvider<DisponibiliteLayout> disponibiliteLayoutProvider =
    FutureProvider<DisponibiliteLayout>(
      (Ref ref) => ref.watch(portLayoutMushafProvider).disponibilite(),
    );

/// Une page du corpus.
///
/// **Une famille par numero de page, et rien de plus gourmand** : un lecteur
/// ouvre une page a la fois, et charger les 604 d'avance ferait transiter tout
/// le corpus pour lire une ligne. Meme choix que `pageCoranProvider`, dont
/// celui-ci est l'equivalent au niveau du moteur.
final FutureProviderFamily<PageCorpus?, int> pageCorpusProvider =
    FutureProvider.family<PageCorpus?, int>(
      (Ref ref, int numero) => ref.watch(portCorpusCoranProvider).page(numero),
    );

/// La mise en page d'une page, quand une source la fournit.
final FutureProviderFamily<LayoutPage?, int> layoutPageProvider =
    FutureProvider.family<LayoutPage?, int>(
      (Ref ref, int numero) =>
          ref.watch(portLayoutMushafProvider).layoutDe(numero),
    );

/// Une page du mushaf, prete a rendre.
///
/// C'est le seul point ou corpus, sourates et layout se rencontrent. Un ecran
/// n'assemble jamais ces trois sources lui-meme : il en resterait toujours un
/// qui oublierait d'interroger la disponibilite du layout, et afficherait une
/// page approximee sans le dire.
final FutureProviderFamily<PageMushafVM, int> pageMushafProvider =
    FutureProvider.family<PageMushafVM, int>((Ref ref, int numero) async {
      final AsyncValue<PageCorpus?> page = ref.watch(pageCorpusProvider(numero));
      final AsyncValue<List<SourateVM>> sourates = ref.watch(
        souratesCoranProvider,
      );
      final AsyncValue<DisponibiliteLayout> disponibilite = ref.watch(
        disponibiliteLayoutProvider,
      );
      final AsyncValue<LayoutPage?> layout = ref.watch(
        layoutPageProvider(numero),
      );

      return PageMushafVM.depuis(
        pageDemandee: numero,
        // `hasValue` et non le type d'execution : Riverpod 3 relance un
        // provider en echec tout seul, et l'etat repasse par `AsyncLoading` en
        // conservant `hasError` (piege deja paye, `lib/CLAUDE.md`).
        page: page.hasValue ? page.value : null,
        chargementEnCours: page.isLoading && !page.hasError,
        sourates: sourates.hasValue ? sourates.value : null,
        fidelite: disponibilite.hasValue
            ? disponibilite.value ?? DisponibiliteLayout.indisponible
            : DisponibiliteLayout.indisponible,
        layout: layout.hasValue ? layout.value : null,
      );
    });
