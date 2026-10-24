// La lecture d'une valeur asynchrone au niveau d'une PAGE de la candidature :
// tant qu'elle manque ou qu'elle a echoue, une page simple (titre, retour au
// dossier) porte le bloc d'etat ; une fois lue, la valeur construit sa propre
// page (le parcours a sa coquille, la lecture seule a la sienne).
//
// Le chargement et l'echec passent par `BlocAsynchrone` : squelette a la forme
// du contenu (rien avant 180 ms), phrase au bout de 8 s, reprise bornee. Une
// capacite indisponible se dit sans « Reessayer » ; hors ligne, le bloc dit ce
// qui manque sans redire « hors ligne » (le bandeau de la page le dit).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/candidature/port_ma_candidature.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';

/// Une page simple : titre, retour au dossier, corps.
class PageSimple extends StatelessWidget {
  /// Cree la page. [titre] vaut « Votre candidature » par defaut.
  const PageSimple({required this.corps, this.titre, super.key});

  /// Le corps.
  final Widget corps;

  /// Le titre de la page, quand ce n'est pas celui du questionnaire.
  final String? titre;

  @override
  Widget build(BuildContext context) => PageShell(
    titre: titre ?? t.recrutement.questionnaire.titre,
    onRetour: () => GoRouter.of(context).go(Routes.attente),
    child: Align(
      alignment: AlignmentDirectional.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
        child: corps,
      ),
    ),
  );
}

/// « Cette etape n'est pas encore ouverte. Votre compte est garde. », sans
/// « Reessayer » : une capacite absente ne revient pas en insistant.
class EtapeNonOuverte extends StatelessWidget {
  /// Cree le bloc.
  const EtapeNonOuverte({super.key});

  /// La cle du bloc.
  static const Key blocKey = ValueKey<String>('candidature-non-ouverte');

  @override
  Widget build(BuildContext context) => EtatSysteme(
    key: blocKey,
    nature: NatureEtat.indisponible,
    phrase: t.recrutement.questionnaire.nonOuverte,
    dependance: dependanceCandidature,
  );
}

/// Lit [valeur] au niveau d'une page : [construire] rend la page entiere.
Widget lecturePage<T>({
  required WidgetRef ref,
  required AsyncValue<T> valeur,
  required Widget Function(T) construire,
  required String titreEchec,
  required VoidCallback onReessayer,
  String? titre,
  Key? key,
}) {
  if (valeur.hasValue) {
    return construire(valeur.requireValue);
  }
  final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
  return PageSimple(
    key: key,
    titre: titre,
    corps: BlocAsynchrone<T>(
      valeur: valeur,
      squelette: const Skeleton.liste(lignes: 3),
      titreEchec: titreEchec,
      onReessayer: onReessayer,
      erreurVersEtat: (Object erreur, VoidCallback? reessayer) {
        if (erreur is CapaciteIndisponible) {
          return const EtapeNonOuverte();
        }
        if (erreur is HorsLigneCandidature || horsLigne) {
          return EtatSansDonnees(quoi: titreEchec, onAction: reessayer);
        }
        return null;
      },
      construire: (T _) => const SizedBox.shrink(),
    ),
  );
}
