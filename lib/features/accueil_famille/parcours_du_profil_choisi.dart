// DEFAUT DU 11/11/2026 (directeur, production) : sur l'Accueil, avec un profil
// sans classe choisi, `BlocParcours` listait TOUS les apprenants du foyer sans
// groupe confirme, sous le prenom du premier : les enfants deja en classe (que
// la vue du parcours ne voit pas) y apparaissaient en « Horaire a choisir ».
//
// Cet adaptateur ne montre que le parcours du profil CHOISI : il passe a
// `BlocParcours` (inchange) le meme fournisseur du foyer, reduit a cet apprenant,
// dans une portee locale. Les etats (chargement, erreur, panne du parcours)
// sont ceux du fournisseur du foyer, sans changement.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../../core/offres/offre_horaire.dart';
import '../../core/offres/service_offres.dart';
import '../parcours_offres/bloc_parcours.dart';

/// Le parcours de [eleveId], et de lui seul, sous son propre prenom.
class ParcoursDuProfilChoisi extends ConsumerWidget {
  /// Cree le bloc de [eleveId].
  const ParcoursDuProfilChoisi({required this.eleveId, super.key});

  /// Le profil choisi a l'Accueil.
  final String eleveId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ParcoursApprenant>> foyer = ref.watch(
      parcoursFoyerProvider,
    );
    return ProviderScope(
      overrides: <Override>[
        parcoursFoyerProvider.overrideWithValue(
          foyer.whenData(
            (List<ParcoursApprenant> tous) =>
                List<ParcoursApprenant>.unmodifiable(
                  tous.where((ParcoursApprenant p) => p.eleveId == eleveId),
                ),
          ),
        ),
      ],
      child: const BlocParcours(),
    );
  }
}
