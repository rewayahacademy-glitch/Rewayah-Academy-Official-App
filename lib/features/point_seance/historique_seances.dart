// POINT-DE-SEANCE (lot 6 de la charte) : l'historique des seances d'un eleve,
// ecrit par le systeme (presence mesuree et points de fin de seance), et ce
// que le serveur en deduit : ce qui est a renforcer, ce qui est acquis, le
// travail avant le prochain cours. Personne ne le remplit.
//
// UN seul composant, pose en raccourci la ou chaque role lit deja l'eleve :
// la fiche de l'eleve chez l'enseignant, l'onglet Historique du tuteur, le
// suivi de l'eleve, la fiche de classe de la direction. Le serveur decide de
// ce que chacun lit (la note et le tirage : enseignant et direction seuls ;
// rien pour le compte d'un enfant de 6 a 9 ans).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/point_seance/port_point_seance.dart';
import '../../core/session/session_controleur.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/section_header.dart';
import 'point_seance_page.dart' show libelleReponsePoint;

/// Le bloc « Historique des seances » de [eleveId], ou rien : sans port, pendant
/// la lecture, ou quand le serveur ne l'ouvre pas a la personne connectee.
class BlocHistoriqueSeances extends ConsumerWidget {
  /// Cree le bloc.
  const BlocHistoriqueSeances({
    this.eleveId,
    this.lignesMax = 6,
    this.avecTitre = true,
    this.seulementPoints = false,
    super.key,
  });

  /// L'eleve ; nul : la personne connectee (son profil eleve).
  final String? eleveId;

  /// Le nombre de seances montrees.
  final int lignesMax;

  /// Faux quand le titre est deja porte par la feuille qui contient le bloc.
  final bool avecTitre;

  /// Vrai la ou la liste des seances et la presence sont deja sur la page
  /// (Historique du tuteur, Suivi de l'eleve) : seules les seances qui ont une
  /// reponse du point sont montrees, sans redire la presence.
  final bool seulementPoints;

  /// La cle du bloc lu.
  static const Key contenuKey = ValueKey<String>('historique-seances');

  /// La cle de la ligne d'echec.
  static const Key echecKey = ValueKey<String>('historique-seances-echec');

  /// La cle de la ligne vide.
  static const Key videKey = ValueKey<String>('historique-seances-vide');

  String _date(DateTime d) => t.historiqueSeances.date(
    jour: t.commun.dates.jours[d.weekday - 1],
    numero: '${d.day}',
    mois: t.commun.dates.mois[d.month - 1],
  );

  String _presence(PresencePoint p) => switch (p) {
    PresencePoint.presente => t.historiqueSeances.present,
    PresencePoint.partielle => t.historiqueSeances.partiel,
    PresencePoint.absente => t.historiqueSeances.absent,
    PresencePoint.inconnue => t.historiqueSeances.inconnu,
  };

  String? _jointes(List<String> lignes) =>
      lignes.isEmpty ? null : lignes.join('\n');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(portPointSeanceProvider) == null) {
      return const SizedBox.shrink();
    }
    final String? eleveId =
        this.eleveId ?? ref.watch(sessionProvider).profileId;
    if (eleveId == null) return const SizedBox.shrink();
    final AsyncValue<HistoriqueSeances?> lecture = ref.watch(
      historiqueSeancesProvider(eleveId),
    );
    final h = t.historiqueSeances;
    final List<LigneRubrique> lignes;
    final Key cle;
    if (lecture.hasError && !lecture.hasValue) {
      cle = echecKey;
      lignes = <LigneRubrique>[
        LigneRubrique(
          icone: AppIcons.suivi,
          libelle: h.titre,
          legende: h.illisible,
          onPress: () => ref.invalidate(historiqueSeancesProvider(eleveId)),
        ),
      ];
    } else if (!lecture.hasValue) {
      return const SizedBox.shrink();
    } else {
      final HistoriqueSeances? histo = lecture.value;
      // Le serveur ne l'ouvre pas a cette personne (enfant de 6 a 9 ans).
      if (histo == null) return const SizedBox.shrink();
      if (histo.seances.isEmpty) {
        cle = videKey;
        lignes = <LigneRubrique>[
          LigneRubrique(icone: AppIcons.suivi, libelle: h.vide),
        ];
      } else {
        cle = contenuKey;
        final DateTime? depuis = histo.aRenforcerDepuis;
        lignes = <LigneRubrique>[
          if (histo.points > 0)
            LigneRubrique(
              cle: const ValueKey<String>('historique-seances-synthese'),
              icone: AppIcons.suivi,
              libelle: histo.aRenforcer && depuis != null
                  ? h.aRenforcerDepuis(
                      numero: '${depuis.day}',
                      mois: t.commun.dates.mois[depuis.month - 1],
                    )
                  : h.rienARenforcer,
              legende: <String>[
                ?histo.etape,
                if (histo.deuxDeSuite) h.deuxDeSuite,
                h.acquisCompte(n: '${histo.acquis}'),
                if (histo.travail == TravailPoint.cible && depuis != null)
                  h.travailCible(
                    numero: '${depuis.day}',
                    mois: t.commun.dates.mois[depuis.month - 1],
                  )
                else if (histo.travail != null)
                  h.travailRelire,
              ].join('\n'),
            ),
          for (final SeancePassee s
              in histo.seances
                  .where(
                    (SeancePassee s) => !seulementPoints || s.reponse != null,
                  )
                  .take(lignesMax))
            LigneRubrique(
              libelle: _date(s.debut),
              valeur: s.reponse == null
                  ? null
                  : libelleReponsePoint(s.reponse!),
              legende: _jointes(<String>[
                if (!seulementPoints) _presence(s.presence),
                if (s.reponse == null && s.presence == PresencePoint.presente)
                  h.sansPoint,
                if (s.tire) h.ecoute,
                if ((s.note ?? '').isNotEmpty) h.noteDe(note: s.note!),
              ]),
            ),
        ];
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (avecTitre) SectionHeader(titre: h.titre),
          GroupeReglages(key: cle, lignes: lignes),
        ],
      ),
    );
  }
}
