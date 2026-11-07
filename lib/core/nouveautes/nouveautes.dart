/// NOUVEAUTES (demande du directeur du 07/11/2026, conception du garde-cap) :
/// « un systeme de badge qui va montrer les nouvelles fonctionnalites...
/// discret ».
///
/// Le serveur (migration 20261114000000) rend les cles a signaler a la
/// personne connectee (`mes_nouveautes()`) : son role, sortie depuis moins de
/// 14 jours, pas encore ouverte. Ouvrir la fonctionnalite la marque vue
/// (`marquer_nouveaute_vue`), PAR COMPTE : le badge ne revient sur aucun
/// appareil. Sans lecture du serveur, aucun badge : jamais un faux « Nouveau ».
///
/// Regle du lot : tout lot qui ajoute une fonctionnalite visible declare sa
/// cle (migration du lot) et pose [BadgeNouveau] sur son point d'entree
/// (onglet, ligne, bouton d'acces), jamais sur un contenu ni dans un parcours.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../i18n/strings.g.dart';
import '../widgets/status_pill.dart';

/// Les cles declarees par les lots (une par point d'entree).
abstract final class CleNouveaute {
  /// Fiche eleve : « Couleur du profil ».
  static const String couleurProfil = 'couleur_profil';

  /// Fiche eleve : « Recharger » (choix du moyen de paiement).
  static const String moyenPaiement = 'moyen_paiement';

  /// Onglet « Historique » du tuteur.
  static const String historiqueClasse = 'historique_classe';

  /// Profil de l'enseignant : « Mes coordonnees de versement ».
  static const String recevoirPaiements = 'recevoir_paiements';

  /// Paie de la direction : « Preparer le fichier Wise du mois ».
  static const String exportWise = 'export_wise';
}

/// La lecture et le marquage.
abstract interface class PortNouveautes {
  /// Les cles a signaler a la personne connectee.
  Future<Set<String>> mes();

  /// La personne a ouvert la fonctionnalite [cle].
  Future<void> marquerVue(String cle);
}

class _Aucune implements PortNouveautes {
  const _Aucune();

  @override
  Future<Set<String>> mes() async => const <String>{};

  @override
  Future<void> marquerVue(String cle) async {}
}

/// L'adaptateur Supabase.
class NouveautesSupabase implements PortNouveautes {
  /// Cree l'adaptateur.
  const NouveautesSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<Set<String>> mes() async {
    final Object? brut = await _client.rpc<Object?>('mes_nouveautes');
    return brut is List ? brut.whereType<String>().toSet() : const <String>{};
  }

  @override
  Future<void> marquerVue(String cle) async {
    await _client.rpc<Object?>(
      'marquer_nouveaute_vue',
      params: <String, dynamic>{'p_cle': cle},
    );
  }
}

/// Le port ; l'application le surcharge avec l'adaptateur Supabase.
final Provider<PortNouveautes> portNouveautesProvider =
    Provider<PortNouveautes>((Ref _) => const _Aucune());

/// Les nouveautes de la personne connectee.
class Nouveautes extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() => ref.watch(portNouveautesProvider).mes();

  /// La fonctionnalite [cle] est ouverte : le badge part tout de suite, et le
  /// serveur le retient pour tous les appareils. Une coupure ne fait pas
  /// revenir le badge sur cet ecran ; il reviendra a la prochaine lecture.
  Future<void> vue(String cle) async {
    final Set<String>? actuelles = state.value;
    if (actuelles == null || !actuelles.contains(cle)) return;
    state = AsyncData<Set<String>>(<String>{...actuelles}..remove(cle));
    try {
      await ref.read(portNouveautesProvider).marquerVue(cle);
    } on Object {
      // Rien a dire a la personne : ce n'est qu'un signal discret.
    }
  }
}

/// Le fournisseur des nouveautes.
final AsyncNotifierProvider<Nouveautes, Set<String>> nouveautesProvider =
    AsyncNotifierProvider<Nouveautes, Set<String>>(Nouveautes.new);

/// Marque la nouveaute [cle] vue (a appeler a l'ouverture de la
/// fonctionnalite).
void marquerNouveauteVue(WidgetRef ref, String cle) =>
    ref.read(nouveautesProvider.notifier).vue(cle);

/// LE badge « Nouveau », unique composant partage : une pastille discrete a
/// cote du libelle d'un point d'entree, lue « nouveau » par le lecteur
/// d'ecran. Rien tant que le serveur ne l'a pas dit.
class BadgeNouveau extends ConsumerWidget {
  /// Cree le badge de la nouveaute [cle].
  const BadgeNouveau({required this.cle, super.key});

  /// La cle declaree par le lot.
  final String cle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool montre =
        ref.watch(nouveautesProvider).value?.contains(cle) ?? false;
    if (!montre) return const SizedBox.shrink();
    return Semantics(
      label: t.nouveautes.lu,
      child: ExcludeSemantics(
        child: StatusPill(libelle: t.nouveautes.badge, ton: TonEtat.accent),
      ),
    );
  }
}

/// NOUVEAUTES : le point d'entree porte-t-il une nouveaute que le serveur signale ?
bool estNouveau(WidgetRef ref, String? cle) =>
    cle != null &&
    (ref.watch(nouveautesProvider).value?.contains(cle) ?? false);

/// Le libelle lu d'un point d'entree, avec « nouveau » quand il l'est.
String libelleAvecNouveaute(String libelle, bool nouveau) =>
    nouveau ? '$libelle, ${t.nouveautes.lu}' : libelle;
