/// BE-LISTE : l'entree « Personnes » de la direction.
///
/// Tant qu'il y a des candidatures en cours, « Personnes » ouvre
/// « Candidatures » (la file ou travaille la direction) ; sinon, ou si le
/// serveur ne repond pas, « Dossiers a valider », comme avant. La decision se
/// lit au serveur (le total des candidatures en cours, dans la portee du
/// lecteur) : rien n'est deduit ici. Pendant la lecture, un squelette, jamais
/// une page vide ; l'ecran remplace l'entree dans la pile, le retour ne
/// repasse donc jamais par elle.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/candidature/modeles_candidature.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/candidature/port_candidatures_direction.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';

/// La requete qui compte les candidatures en cours.
const RequeteCandidatures requeteEntreePersonnes = RequeteCandidatures(
  filtre: FiltreCandidatures(issue: IssueCandidature.enCours),
);

/// Vers ou « Personnes » ouvre, une fois la lecture faite.
String destinationEntreePersonnes(AsyncValue<PageCandidatures> lecture) {
  if (lecture.hasValue && lecture.requireValue.total > 0) {
    return Routes.adminPersonnesCandidatures;
  }
  return Routes.adminPersonnesDossiers;
}

/// L'entree « Personnes ».
class EntreePersonnes extends ConsumerStatefulWidget {
  /// Cree l'entree.
  const EntreePersonnes({super.key});

  /// La cle de l'attente.
  static const Key cleAttente = ValueKey<String>('entree-personnes-attente');

  @override
  ConsumerState<EntreePersonnes> createState() => _EntreePersonnesEtat();
}

class _EntreePersonnesEtat extends ConsumerState<EntreePersonnes> {
  bool _partie = false;

  void _aller(AsyncValue<PageCandidatures> lecture) {
    if (_partie || lecture.isLoading) return;
    _partie = true;
    final String destination = destinationEntreePersonnes(lecture);
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) context.replace(destination);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<PageCandidatures> lecture = ref.watch(
      pageCandidaturesProvider(requeteEntreePersonnes),
    );
    _aller(lecture);
    return PageShell(
      key: EntreePersonnes.cleAttente,
      titre: t.nav.admin.personnes,
      child: const Skeleton.liste(lignes: 4),
    );
  }
}
