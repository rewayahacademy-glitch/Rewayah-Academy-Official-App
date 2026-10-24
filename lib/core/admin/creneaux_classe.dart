// B2.2 bis (c), plan de nuit du pilote (24/10/2026) : la direction ajoute un
// creneau hebdomadaire a une Classe. Le serveur repasse le predicat
// d'affectation (memes refus que le deplacement d'une Classe) puis cree aussitot
// les seances des quatre prochaines semaines
// (`ajouter_creneau_classe_admin`, migration 20261025020000).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'creneaux_classe_supabase.dart';

/// L'ajout d'un creneau a une Classe.
abstract interface class ServiceCreneauxClasse {
  /// Ajoute le creneau ([jour] ISO 1 a 7, [heure] 0 a 23, dans le fuseau de
  /// la Classe) et rend le nombre de seances creees : 0 quand la Classe
  /// avait deja ce creneau. Un refus du predicat arrive en
  /// `AffectationRefusee`.
  Future<int> ajouter({
    required String groupeId,
    required int jour,
    required int heure,
  });
}

/// Le service employe par l'application.
final Provider<ServiceCreneauxClasse> serviceCreneauxClasseProvider =
    Provider<ServiceCreneauxClasse>(
      (Ref ref) => CreneauxClasseSupabase(Supabase.instance.client),
    );
