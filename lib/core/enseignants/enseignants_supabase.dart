// LP-2 : l'adaptateur Supabase de la liste des enseignants
// (`lister_enseignants(p_filtre, p_tri, p_page)`, migration 20261129400000).
//
// Le serveur decide : portee de genre, phase, gestes, compteurs, pagination de
// 50, journal de chaque lecture. L'adaptateur ne filtre rien et ne recalcule
// rien ; il traduit. Memes refus que la file des candidatures : `42501` dit
// « non autorise » (« genre du lecteur inconnu » devient [GenreLecteurInconnu]),
// `PGRST202` / `42883` dit « pas encore verse » ([CapaciteIndisponible]).
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../candidature/modeles_candidature_detail.dart' show VoisinsCandidature;
import '../candidature/port_candidatures_direction.dart'
    show GenreLecteurInconnu;
import '../capacites/capacite_indisponible.dart';
import '../capacites/permission_insuffisante.dart';
import 'modeles_enseignants.dart';
import 'port_enseignants.dart';

/// La liste des enseignants servie par Supabase.
class EnseignantsSupabase implements PortEnseignants, PortVoisinsEnseignant {
  /// Cree l'adaptateur sur le client de l'application.
  EnseignantsSupabase(SupabaseClient client)
    : _appel = ((String f, Map<String, dynamic> p) =>
          client.rpc<Object?>(f, params: p));

  /// Cree l'adaptateur sur un appel injecte (tests).
  EnseignantsSupabase.avecAppel(this._appel);

  final Future<Object?> Function(String fonction, Map<String, dynamic> params)
  _appel;

  @override
  Future<PageEnseignants> lister({
    required FiltreEnseignants filtre,
    required TriEnseignants tri,
    required int page,
  }) async {
    try {
      final Object? brut = await _appel('lister_enseignants', <String, dynamic>{
        'p_filtre': filtre.enJson(),
        'p_tri': tri.valeurSql,
        'p_page': page,
      });
      return PageEnseignants.depuisJson(brut);
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        if (e.message.contains('genre du lecteur inconnu')) {
          throw const GenreLecteurInconnu();
        }
        throw const PermissionInsuffisante('lister_enseignants');
      }
      if (e.code == 'PGRST202' || e.code == '42883') {
        throw const CapaciteIndisponible(dependanceListeEnseignants);
      }
      rethrow;
    }
  }

  /// PERSONNES-UNE-PAGE (d) : `voisins_enseignant(p_reference, p_filtre,
  /// p_tri)`. Le serveur rend `{precedent, suivant, rang, total}` ou
  /// `{erreur: absente | hors_liste}` : dans les deux cas d'erreur, des
  /// voisins vides (ni rang ni suivant), jamais un rang invente.
  @override
  Future<VoisinsCandidature> voisins(
    String reference, {
    required FiltreEnseignants filtre,
    required TriEnseignants tri,
  }) async {
    try {
      final Object? brut = await _appel('voisins_enseignant', <String, dynamic>{
        'p_reference': reference,
        'p_filtre': filtre.enJson(),
        'p_tri': tri.valeurSql,
      });
      if (brut is Map && brut['erreur'] == 'absente') {
        return const VoisinsCandidature();
      }
      return VoisinsCandidature.depuisJson(brut);
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        if (e.message.contains('genre du lecteur inconnu')) {
          throw const GenreLecteurInconnu();
        }
        throw const PermissionInsuffisante('voisins_enseignant');
      }
      if (e.code == 'PGRST202' || e.code == '42883') {
        throw const CapaciteIndisponible(dependanceListeEnseignants);
      }
      rethrow;
    }
  }
}
