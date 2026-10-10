/// CAP29-0 : la porte commune des ecrans de la bibliotheque d'administration.
///
/// Elle lit le port et les capacites rendues par le serveur, jamais un role,
/// et ne laisse passer a l'ecran que s'il peut lire :
/// - port absent (production avant branchement) : « disponible au branchement
///   serveur », rien d'invente ;
/// - capacites en cours de lecture : squelette ;
/// - lecture en echec : erreur et « Reessayer » (ou le bloc sans donnees hors
///   ligne) ;
/// - pas de capacite de lecture : « vous n'avez pas acces ».
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/port_bibliotheque_admin.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/skeleton.dart';

/// Les capacites de la personne connectee. Sans port : erreur d'indisponibilite
/// (traitee par [PorteBibliotheque]).
final FutureProvider<CapacitesBibliotheque> capacitesBibliothequeProvider =
    FutureProvider<CapacitesBibliotheque>((Ref ref) {
      final PortBibliothequeAdmin? port = ref.watch(
        portBibliothequeAdminProvider,
      );
      if (port == null) {
        return Future<CapacitesBibliotheque>.value(
          CapacitesBibliotheque.aucune,
        );
      }
      return port.capacites();
    }, retry: (int _, Object _) => null);

/// La porte : construit [construire] quand le port existe et que la personne
/// peut lire la bibliotheque.
class PorteBibliotheque extends ConsumerWidget {
  /// Cree la porte.
  const PorteBibliotheque({required this.construire, super.key});

  /// Construit le contenu avec le port et les capacites.
  final Widget Function(
    BuildContext context,
    PortBibliothequeAdmin port,
    CapacitesBibliotheque capacites,
  )
  construire;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PortBibliothequeAdmin? port = ref.watch(
      portBibliothequeAdminProvider,
    );
    final a = t.admin.bibliotheque;
    if (port == null) {
      return EtatSysteme(
        key: const ValueKey<String>('bibliotheque-indisponible'),
        nature: NatureEtat.indisponible,
        titre: a.indisponibleTitre,
        phrase: a.indisponiblePhrase,
        dependance: dependanceBibliothequeAdmin,
      );
    }
    final AsyncValue<CapacitesBibliotheque> caps = ref.watch(
      capacitesBibliothequeProvider,
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    if (caps.hasError && !caps.hasValue) {
      void relire() => ref.invalidate(capacitesBibliothequeProvider);
      return horsLigne
          ? EtatSansDonnees(
              key: const ValueKey<String>('bibliotheque-sans-donnees'),
              quoi: a.sansDonnees,
              onAction: relire,
            )
          : EtatSysteme(
              key: const ValueKey<String>('bibliotheque-erreur'),
              nature: NatureEtat.echecServeur,
              phrase: a.erreur,
              onAction: relire,
            );
    }
    if (!caps.hasValue) {
      return const Skeleton.liste(lignes: 4);
    }
    final CapacitesBibliotheque c = caps.requireValue;
    if (!c.peutLire) {
      return EtatSysteme(
        key: const ValueKey<String>('bibliotheque-non-autorise'),
        nature: NatureEtat.accesRefuse,
        titre: a.titre,
        phrase: a.nonAutorise,
      );
    }
    return construire(context, port, c);
  }
}
