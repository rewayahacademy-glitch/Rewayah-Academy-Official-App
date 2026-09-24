import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Comme partout ailleurs : le type d'une famille de providers n'est pas exporte
// par l'entree principale de Riverpod 3, il vit dans `misc.dart`.
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/tc_bibliotheque/catalogue_local.dart';
import '../../core/tc_bibliotheque/donnees_catalogue.dart';
import '../../core/tc_bibliotheque/library_resource.dart';
import '../../core/tc_bibliotheque/port_catalogue.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../tc_catalogue/libelles_bibliotheque.dart';
import '../tc_catalogue/routes_tc_b.dart';
import '../tc_catalogue/vignette_ressource.dart';
import 'contexte_classe.dart';

/// Les ressources de la classe, telles que le serveur les laisse voir.
///
/// Leve `CapaciteIndisponible('LOT-C')` tant que la Bibliotheque sert son
/// catalogue local vide : la source existe (`library_resource`,
/// `ressources_du_groupe`, `0032` a `0035`), l'adaptateur Supabase
/// (`lib/core/tc_bibliotheque/catalogue_supabase.dart`, lot C) manque. Un
/// catalogue local vide ferait dire « aucune ressource » a tort.
///
/// ponytail: le type du catalogue dit s'il est branche ; plafond : un
/// catalogue local peuple (Playground) passe aussi pour « non branche ».
/// Remplacer par un indicateur du port quand l'adaptateur existera.
final FutureProviderFamily<List<LibraryResource>, String>
ressourcesClasseProvider = FutureProvider.family<List<LibraryResource>, String>(
  (Ref ref, String classeId) async {
    final PortCatalogue catalogue = ref.watch(portCatalogueProvider);
    if (catalogue is CatalogueLocal) {
      throw const CapaciteIndisponible('LOT-C');
    }
    return catalogue.pourGroupe(classeId);
  },
);

/// La bibliotheque d'une classe (`/tuteur/classes/:classeId/ressources`).
///
/// Derive des lignes du Compte (#5, #6) : UN groupe a filets, une ressource
/// par ligne (type, titre), chevron vers le detail existant
/// (`/tc/bibliotheque/:resourceId`, le « lecteur existant »). L'adresse du
/// detail porte `?retour=` (chemin interne valide par `cheminRetourValide`) :
/// son disque retour revient ici, rechargement de page compris.
class RessourcesClassePage extends ConsumerWidget {
  /// Cree la page.
  const RessourcesClassePage({required this.classeId, super.key, this.eleveId});

  /// La classe concernee.
  final String classeId;

  /// L'eleve concerne, s'il est donne.
  final String? eleveId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => CadreClasse(
    cle: (classeId: classeId, eleveId: eleveId),
    titre: t.classe.ressources,
    sousTitre: sousTitreSousPage,
    onRetour: () =>
        GoRouter.of(context).go(Routes.classePour(classeId, eleveId: eleveId)),
    construire: (ContexteClasse c) => _Ressources(contexte: c),
  );
}

class _Ressources extends ConsumerWidget {
  const _Ressources({required this.contexte});

  final ContexteClasse contexte;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String classeId = contexte.classeId;
    return LectureClasse<List<LibraryResource>>(
      valeur: ref.watch(ressourcesClasseProvider(classeId)),
      phraseIndisponible: t.classe.pageRessources.indisponible,
      onReessayer: () => ref.invalidate(ressourcesClasseProvider(classeId)),
      vide: EtatSysteme(
        nature: NatureEtat.aucunResultat,
        titre: t.classe.pageRessources.aucune,
        phrase: t.classe.pageRessources.aucuneDetail,
      ),
      construire: (List<LibraryResource> ressources) => GroupeReglages(
        lignes: <LigneRubrique>[
          for (final LibraryResource r in ressources)
            LigneRubrique(
              icone: VignetteRessource.iconeDe(r.resourceType),
              libelle: r.title,
              legende: libelleTypeRessource(r.resourceType),
              onPress: () => GoRouter.of(context).go(
                Uri(
                  path: RoutesTcB.versRessource(r.id),
                  queryParameters: <String, String>{
                    'retour': cheminClasse(
                      classeId,
                      contexte.eleveId,
                      'ressources',
                    ),
                  },
                ).toString(),
              ),
            ),
        ],
      ),
    );
  }
}
