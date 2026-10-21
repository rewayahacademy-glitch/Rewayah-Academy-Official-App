// Le detail d'une annonce de Classe (spec Communications V1, section 18
// « Detail annonce » : surface contextuelle ou page de niveau 2 selon la
// longueur, aucune navigation propre concurrente).
//
// Pas de route : le detail se pose dans le centre de notifications (panneau
// de droite sur ordinateur, surface unique sur telephone) ou dans une feuille
// depuis l'Espace Classe. Il relit l'annonce par son port (COM-BR-10) et rend
// chacun de ses etats ; une annonce retiree n'est jamais un faux contenu.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/vue_etat_communication.dart';
import 'carte_annonce_classe.dart';
import 'port_annonces.dart';

/// Le detail d'une annonce : le texte entier et « Ouvrir la Classe »
/// (R-COM-12).
class AnnonceDetail extends ConsumerWidget {
  /// Cree le detail de l'annonce [annonceId].
  const AnnonceDetail({required this.annonceId, super.key});

  /// L'annonce a montrer.
  final String annonceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AnnonceClasse?> valeur = ref.watch(
      annonceProvider(annonceId),
    );
    final a = t.com.annonces;
    return BlocCommunication<AnnonceClasse?>(
      valeur: valeur,
      squelette: const Skeleton.texte(lignes: 5),
      onReessayer: () => ref.invalidate(annonceProvider(annonceId)),
      // Absente ou retiree : elle ne s'invente pas.
      estVide: (AnnonceClasse? annonce) => annonce == null,
      titreVide: a.introuvableTitre,
      phraseVide: a.introuvablePhrase,
      construire: (AnnonceClasse? annonce) {
        final AnnonceClasse lue = annonce!;
        final String? destination = lue.classe.destination;
        return CarteAnnonceClasse(
          annonce: lue,
          complete: true,
          onOuvrirClasse: destination == null
              ? null
              : () => GoRouter.of(context).go(destination),
        );
      },
    );
  }
}
