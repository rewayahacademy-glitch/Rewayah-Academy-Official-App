import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/tc_bibliotheque/content_position.dart';
import '../../core/tc_bibliotheque/library_resource.dart';
import '../../core/tc_bibliotheque/vue_catalogue.dart';
import '../../core/widgets/page_shell.dart';
import 'routes_tc_b.dart';
import 'surface_bibliotheque.dart';

/// La Bibliotheque hors classe.
///
/// Elle n'est qu'une coquille : tout le contenu vient de
/// [SurfaceBibliotheque], celle-la meme qu'ouvre le `ClassLibraryPicker`. Une
/// page qui recomposerait ses propres sections deviendrait une deuxieme
/// bibliotheque des le premier ajout (decision D-20).
///
/// `defilante: false` : la surface gere son propre defilement, en slivers, et
/// recoit donc une hauteur bornee. Le commentaire de `PageShell` documente
/// pourquoi le cas inverse a fait disparaitre cinq corps d'ecran en release.
class BibliothequePage extends ConsumerWidget {
  /// Cree l'ecran.
  const BibliothequePage({super.key, this.groupeId});

  /// Le groupe dont on montre les ressources epinglees, quand on vient de son
  /// espace. `null` depuis la navigation generale.
  final String? groupeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageShell(
      titre: t.tc.bibliotheque.titre,
      defilante: false,
      child: SurfaceBibliotheque(
        contexte: ContexteDecouverte.horsClasse,
        groupeId: groupeId,
        // La position demandee par une recherche chiffree n'est pas transmise,
        // et c'est assume : aucun renderer ne sait encore ouvrir un support a
        // une page ou a un verset. La transporter jusqu'a une fiche qui n'en
        // ferait rien donnerait l'illusion d'un saut qui n'existe pas. Le jour
        // ou le moteur d'Agent C et un moteur PDF sont la, elle passe en
        // `extra` de la route.
        //
        // Le detail porte `?retour=` (LT-11, revue C m5) : ouvert par `go`,
        // il n'a rien a depiler, et son disque retour revient a CETTE liste,
        // groupe de contexte compris, rechargement de page compris.
        onChoisir: (LibraryResource r, ContentPosition? _) => context.go(
          Uri(
            path: RoutesTcB.versRessource(r.id),
            queryParameters: <String, String>{
              'retour': groupeId == null
                  ? RoutesTcB.bibliotheque
                  : RoutesTcB.avecGroupe(groupeId!),
            },
          ).toString(),
        ),
      ),
    );
  }
}
