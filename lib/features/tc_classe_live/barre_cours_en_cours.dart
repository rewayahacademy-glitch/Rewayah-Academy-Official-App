import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tc_classe/libelles_tc_classe.dart';
import '../../core/tc_classe/session_persistante.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/status_pill.dart';
import 'entete_classe.dart';

/// La barre compacte « Cours en cours » (spec section 9.4).
///
/// **Elle est la preuve visible que le shell ne possede pas la salle.** Elle se
/// pose au-dessus de n'importe quel ecran -- le Groupe, l'Accueil, la
/// Bibliotheque -- et elle n'existe que parce que le cours, lui, continue.
///
/// Elle ne rend **rien** quand aucun cours n'est ouvert : pas un cadre vide,
/// pas une hauteur reservee. C'est un `SizedBox.shrink`, et c'est ce qui permet
/// a Agent Z de la poser inconditionnellement dans la coque de navigation sans
/// deplacer un seul pixel des ecrans ordinaires.
///
/// Elle ne connait **pas** le routeur : [onRevenir] est fourni par qui la pose.
/// Une barre qui naviguerait elle-meme imposerait sa route a tous les ecrans qui
/// l'accueillent.
class BarreCoursEnCours extends ConsumerWidget {
  /// Cree la barre.
  const BarreCoursEnCours({required this.onRevenir, super.key});

  /// Le retour instantane a la Classe Live.
  final VoidCallback onRevenir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `.value` et surtout pas un filtrage par le type de l'AsyncValue : « pas
    // encore charge » et « aucun cours » se disent de la meme facon, par
    // l'absence de barre.
    final EtatSessionPersistante etat =
        ref.watch(etatSessionProvider).value ?? EtatSessionPersistante.aucun;
    final CoursOuvert? cours = etat.cours;
    if (cours == null) {
      return const SizedBox.shrink();
    }

    final TextTheme textes = Theme.of(context).textTheme;
    final String? restant = libelleTempsRestant(cours.horloge);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Pressable(
        onPress: onRevenir,
        libelleSemantique: LibellesClasse.barreRevenir(cours.libelleGroupe),
        child: MergeSemantics(
          child: Row(
            children: <Widget>[
              // Le mot porte l'etat, jamais la seule couleur (invariant J7).
              const StatusPill(
                libelle: LibellesClasse.barreCoursEnCours,
                ton: TonEtat.succes,
              ),
              Ecart.hSm,
              Expanded(
                child: Text(
                  cours.libelleGroupe,
                  overflow: TextOverflow.ellipsis,
                  style: textes.labelLarge ?? const TextStyle(),
                ),
              ),
              if (restant != null) ...<Widget>[
                Ecart.hSm,
                Text(
                  restant,
                  style: textes.labelMedium ?? const TextStyle(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
