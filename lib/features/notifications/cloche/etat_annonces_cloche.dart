// Les pages d'annonces lues par la cloche, et les fermetures faites sur cet
// appareil (CLOCHE-C, decision du 21/11/2026, regles 4 et 5).

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show NotifierProviderFamily;

import '../../../core/capacites/capacite_indisponible.dart';
import 'annonces_cloche.dart';

/// Les annonces lues pour un mode (ouvertes seulement, ou toutes).
@immutable
class EtatAnnoncesCloche {
  /// Cree l'etat.
  const EtatAnnoncesCloche({
    this.annonces = const <AnnonceCloche>[],
    this.suite,
    this.chargement = true,
    this.erreur,
    this.chargePlus = false,
    this.erreurPlus = false,
  });

  /// Les annonces deja lues, page apres page.
  final List<AnnonceCloche> annonces;

  /// Le curseur de la page suivante, ou nul a la fin.
  final DateTime? suite;

  /// La premiere page est en cours de lecture.
  final bool chargement;

  /// L'echec de la premiere page, ou nul.
  final Object? erreur;

  /// Une page suivante est en cours de lecture.
  final bool chargePlus;

  /// La derniere page suivante a echoue.
  final bool erreurPlus;

  /// Vrai quand aucune source d'annonces n'existe (mineur, migration
  /// absente) : la cloche montre les notifications seules, sans erreur.
  bool get indisponible => erreur is CapaciteIndisponible;

  /// Vrai quand la premiere page a echoue pour une autre raison.
  bool get echec => erreur != null && !indisponible;

  /// Les annonces, ou rien tant qu'elles ne sont pas lues.
  List<AnnonceCloche> get lues =>
      chargement || erreur != null ? const <AnnonceCloche>[] : annonces;

  EtatAnnoncesCloche _copie({
    List<AnnonceCloche>? annonces,
    DateTime? Function()? suite,
    bool? chargement,
    Object? Function()? erreur,
    bool? chargePlus,
    bool? erreurPlus,
  }) => EtatAnnoncesCloche(
    annonces: annonces ?? this.annonces,
    suite: suite == null ? this.suite : suite(),
    chargement: chargement ?? this.chargement,
    erreur: erreur == null ? this.erreur : erreur(),
    chargePlus: chargePlus ?? this.chargePlus,
    erreurPlus: erreurPlus ?? this.erreurPlus,
  );
}

/// Les annonces d'un mode : `false` les seules ouvertes (onglet « Tout » et
/// accueil), `true` toutes (onglet « Annonces »).
class AnnoncesCloche extends Notifier<EtatAnnoncesCloche> {
  /// Cree le notifier pour [fermees].
  AnnoncesCloche(this.fermees);

  /// Le mode lu.
  final bool fermees;

  @override
  EtatAnnoncesCloche build() {
    final SourceAnnoncesCloche source = ref.watch(sourceAnnoncesClocheProvider);
    unawaited(_premiere(source));
    return const EtatAnnoncesCloche();
  }

  Future<void> _premiere(SourceAnnoncesCloche source) async {
    try {
      final PageAnnoncesCloche page = await source.page(fermees: fermees);
      if (!ref.mounted) return;
      state = EtatAnnoncesCloche(
        annonces: page.annonces,
        suite: page.suite,
        chargement: false,
      );
    } on Object catch (e) {
      if (!ref.mounted) return;
      state = EtatAnnoncesCloche(chargement: false, erreur: e);
    }
  }

  /// Relit la premiere page (« Reessayer »).
  Future<void> relire() async {
    state = const EtatAnnoncesCloche();
    await _premiere(ref.read(sourceAnnoncesClocheProvider));
  }

  /// Lit la page suivante, s'il y en a une ; un echec le dit et garde ce qui
  /// est deja lu.
  Future<void> suivante() async {
    final DateTime? avant = state.suite;
    if (avant == null || state.chargePlus) return;
    state = state._copie(chargePlus: true, erreurPlus: false);
    try {
      final PageAnnoncesCloche page = await ref
          .read(sourceAnnoncesClocheProvider)
          .page(avant: avant, fermees: fermees);
      if (!ref.mounted) return;
      final Set<String> deja = <String>{
        for (final AnnonceCloche a in state.annonces) a.id,
      };
      state = state._copie(
        annonces: <AnnonceCloche>[
          ...state.annonces,
          ...page.annonces.where((AnnonceCloche a) => !deja.contains(a.id)),
        ],
        suite: () => page.suite,
        chargePlus: false,
      );
    } on Object {
      if (!ref.mounted) return;
      state = state._copie(chargePlus: false, erreurPlus: true);
    }
  }

  /// Marque l'annonce [id] vue, ici seulement (le serveur l'a deja su).
  void vue(String id) {
    state = state._copie(
      annonces: <AnnonceCloche>[
        for (final AnnonceCloche a in state.annonces)
          a.id == id ? a.vueOui() : a,
      ],
    );
  }
}

/// Les annonces de la cloche, par mode.
final NotifierProviderFamily<AnnoncesCloche, EtatAnnoncesCloche, bool>
annoncesClocheProvider =
    NotifierProvider.family<AnnoncesCloche, EtatAnnoncesCloche, bool>(
      AnnoncesCloche.new,
    );

/// Les fermetures faites sur cet appareil, pas encore relues du serveur : id
/// vers fermee. Une fermeture se voit tout de suite (DECISION-FLUIDITE) ; un
/// echec la retire et le dit.
class FermeturesCloche extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => const <String, bool>{};

  /// Pose l'etat de [id].
  void poser(String id, {required bool fermee}) =>
      state = <String, bool>{...state, id: fermee};

  /// Retire l'etat local de [id] (echec : le serveur reste juge).
  void retirer(String id) => state = <String, bool>{...state}..remove(id);
}

/// Les fermetures locales, partagees par le panneau, la feuille et la page.
final NotifierProvider<FermeturesCloche, Map<String, bool>>
fermeturesClocheProvider =
    NotifierProvider<FermeturesCloche, Map<String, bool>>(FermeturesCloche.new);
