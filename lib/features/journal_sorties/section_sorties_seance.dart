import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/journal_sorties/libelles_sorties.dart';
import '../../core/journal_sorties/port_journal_sorties.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/ligne_cle_valeur.dart';

/// HORS-SALLE-2 : « Sorties de l'application » dans le detail d'une seance
/// vu par le parent, sous le temps de presence : le nombre, la duree totale,
/// puis chaque sortie « De 20:12 a 20:13 », avec la mention quand elle a mene
/// a la sortie de la salle.
///
/// **Rien, pas meme un titre**, tant que la lecture n'a rien rendu de lisible
/// pour cet eleve (aucun accord, journal eteint, serveur ancien, lecture en
/// cours ou en echec) : la page n'annonce pas un releve qui n'existe pas.
///
/// [titre] et [carte] sont ceux de la page, pour que la section ait la meme
/// allure que ses voisines.
class SectionSortiesSeance extends ConsumerWidget {
  /// Cree la section.
  const SectionSortiesSeance({
    required this.seanceId,
    required this.eleveId,
    required this.titre,
    required this.carte,
    super.key,
  });

  /// La seance.
  final String seanceId;

  /// L'eleve dont on lit les sorties.
  final String eleveId;

  /// Le titre de bloc de la page.
  final Widget Function(String texte) titre;

  /// La carte de la page.
  final Widget Function(List<Widget> lignes) carte;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<SortieApp> sorties = <SortieApp>[
      for (final SortieApp s
          in ref.watch(sortiesSeanceProvider(seanceId)).value ??
              const <SortieApp>[])
        if (s.eleveId == eleveId) s,
    ];
    if (sorties.isEmpty) {
      return const SizedBox.shrink();
    }
    final ResumeSorties resume = ResumeSorties.parEleve(sorties)[eleveId]!;
    final Traductions$journalSorties$rapport$fr r = t.journalSorties.rapport;
    return Column(
      key: const ValueKey<String>('section-sorties-seance'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Ecart.vXl,
        titre(r.titre),
        carte(<Widget>[
          LigneCleValeur(
            cle: r.nombreCle,
            valeur: LibellesSorties.nombre(resume.nombre),
            chiffres: true,
          ),
          LigneCleValeur(
            cle: r.dureeTotale,
            valeur: LibellesSorties.dureeSeule(resume.totalSecondes),
            chiffres: true,
          ),
          for (final SortieApp s in sorties)
            LigneCleValeur(
              cle: LibellesSorties.plage(s),
              valeur: LibellesSorties.dureeSeule(s.dureeSecondes),
              detailCle: s.sortieSalle ? r.sortieSalle : null,
              chiffres: true,
            ),
        ]),
      ],
    );
  }
}
