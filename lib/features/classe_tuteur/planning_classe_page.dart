import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Comme partout ailleurs : le type d'une famille de providers n'est pas exporte
// par l'entree principale de Riverpod 3, il vit dans `misc.dart`.
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/seance_famille/port_seances_famille.dart';
import '../../core/seance_famille/seance_famille.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/pastille_etat_seance.dart';
import '../accueil_famille/ancre_horloge_serveur.dart';
import '../accueil_famille/bloc_seance.dart';
import 'contexte_classe.dart';

/// La classe et l'eleve d'une lecture de sous-page.
typedef CleEleveClasse = ({String classeId, String eleveId});

/// L'horizon du planning : quatre semaines, l'horizon de materialisation des
/// seances cote serveur (`matching_horizon_weeks`, `0033`). Au-dela, aucune
/// seance n'existe encore : le planning ne l'invente pas (DB-CRS-04).
const Duration horizonPlanning = Duration(days: 28);

/// Les statuts d'une seance qui est derriere nous. Une annulation a venir
/// reste au planning : la famille doit apprendre qu'elle n'aura pas lieu.
const Set<StatutSeance> _statutsClos = <StatutSeance>{
  StatutSeance.terminee,
  StatutSeance.enseignantAbsent,
  StatutSeance.eleveAbsent,
  StatutSeance.incidentTechnique,
};

/// Les seances a venir de [eleveId] dans [classeId], de la plus proche a la
/// plus lointaine.
///
/// **Pure.** Une seance dont la classe est connue et differente est ecartee ;
/// une seance sans classe connue (DB-CRS-13) est gardee : un eleve n'a qu'une
/// classe active a la fois (`0017`). Une seance close, ou dont la fin prevue
/// est passee a [referenceUtc], n'est plus « a venir ».
List<SeanceFamille> seancesAVenir(
  Iterable<SeanceFamille> seances, {
  required String classeId,
  required String eleveId,
  required DateTime referenceUtc,
}) {
  final DateTime reference = referenceUtc.toUtc();
  return seances
      .where(
        (SeanceFamille s) =>
            s.eleveId == eleveId &&
            (s.groupeId == null || s.groupeId == classeId) &&
            !_statutsClos.contains(s.statutServeur) &&
            reference.isBefore(s.finPrevueUtc),
      )
      .toList()
    ..sort(
      (SeanceFamille a, SeanceFamille b) => a.debutUtc.compareTo(b.debutUtc),
    );
}

/// Le planning d'un eleve dans sa classe (contrat K2).
///
/// Le planning date du serveur d'abord (`PortSeancesFamille.planning`, heures
/// rendues dans le fuseau du foyer) ; tant qu'il manque (DB-CRS-03), les
/// seances deja programmees de `mes_seances_v`, a l'heure de l'appareil
/// **dite comme telle**. Jamais une occurrence inventee, jamais un decalage
/// de fuseau calcule cote client.
final FutureProviderFamily<List<SeanceFamille>, CleEleveClasse>
planningClasseProvider =
    FutureProvider.family<List<SeanceFamille>, CleEleveClasse>((
      Ref ref,
      CleEleveClasse cle,
    ) async {
      final PortSeancesFamille port = ref.watch(portSeancesFamilleProvider);
      DateTime reference;
      try {
        reference = (await port.maintenantServeurUtc()).toUtc();
      } on Object {
        // ponytail: l'horloge de l'appareil ne sert qu'a CHOISIR les lignes a
        // venir quand le serveur ne donne pas l'heure (meme regle que
        // l'adaptateur K2) ; aucun etat affiche n'en depend. Plafond : un
        // appareil tres en avance masque une seance du jour.
        reference = DateTime.now().toUtc();
      }
      try {
        return seancesAVenir(
          await port.planning(
            groupeId: cle.classeId,
            eleveId: cle.eleveId,
            periode: DateTimeRange(
              start: reference,
              end: reference.add(horizonPlanning),
            ),
          ),
          classeId: cle.classeId,
          eleveId: cle.eleveId,
          referenceUtc: reference,
        );
      } on CapaciteIndisponible {
        return seancesAVenir(
          await port.historique(eleveId: cle.eleveId),
          classeId: cle.classeId,
          eleveId: cle.eleveId,
          referenceUtc: reference,
        );
      }
    });

/// Le planning date d'une classe (`/tuteur/classes/:classeId/planning`).
///
/// Derive des lignes de l'Historique mobile (#25 D2) : une carte, une seance
/// par ligne, filets ; jour, heure locale et duree ; une seance annulee ou non
/// tenue porte sa pastille et ne se presente jamais comme un cours normal.
class PlanningClassePage extends ConsumerWidget {
  /// Cree la page.
  const PlanningClassePage({required this.classeId, super.key, this.eleveId});

  /// La classe concernee.
  final String classeId;

  /// L'eleve concerne, s'il est donne.
  final String? eleveId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => CadreClasse(
    cle: (classeId: classeId, eleveId: eleveId),
    titre: t.classe.planning,
    sousTitre: sousTitreSousPage,
    onRetour: () =>
        GoRouter.of(context).go(Routes.classePour(classeId, eleveId: eleveId)),
    construire: (ContexteClasse c) => _Planning(contexte: c),
  );
}

class _Planning extends ConsumerWidget {
  const _Planning({required this.contexte});

  final ContexteClasse contexte;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CleEleveClasse cle = (
      classeId: contexte.classeId,
      eleveId: contexte.eleveId,
    );
    final DateTime? maintenant = ref.watch(ancreServeurProvider).value;
    return LectureClasse<List<SeanceFamille>>(
      valeur: ref.watch(planningClasseProvider(cle)),
      // Source absente : jamais « aucune seance » (on ne sait pas).
      phraseIndisponible: t.classe.pagePlanning.indisponible,
      onReessayer: () => ref.invalidate(planningClasseProvider(cle)),
      vide: EtatSysteme(
        nature: NatureEtat.aucunResultat,
        titre: t.classe.pagePlanning.aucune,
        phrase: t.classe.pagePlanning.aucuneDetail(
          dePrenom: deDevant(
            contexte.eleve.prenom,
            cle: 'classe.pagePlanning.aucuneDetail',
          ),
        ),
      ),
      construire: (List<SeanceFamille> seances) => _Liste(
        affichages: <AffichageSeance>[
          for (final SeanceFamille s in seances)
            AffichageSeance.depuis(s, maintenantServeurUtc: maintenant),
        ],
      ),
    );
  }
}

class _Liste extends StatelessWidget {
  const _Liste({required this.affichages});

  final List<AffichageSeance> affichages;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle discret = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    // Un seul fuseau pour toutes les lignes : il se dit une fois, en tete.
    final Set<String> fuseaux = <String>{
      for (final AffichageSeance a in affichages) a.fuseau,
    };
    final bool fuseauUnique = fuseaux.length == 1;

    return ColonnesSousPage(
      principal: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              t.classe.pagePlanning.prochaines,
              style: palette.inkStrong.applyTo(
                textes.titleMedium ?? const TextStyle(),
              ),
            ),
          ),
          if (fuseauUnique) ...<Widget>[
            Ecart.vXs,
            Text(fuseaux.single, style: discret),
          ],
          Ecart.vMd,
          AppCard(
            marge: AppSpacing.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int i = 0; i < affichages.length; i++) ...<Widget>[
                  if (i > 0) const FiletHorizontal(),
                  _Ligne(affichage: affichages[i], avecFuseau: !fuseauUnique),
                ],
              ],
            ),
          ),
        ],
      ),
      precisions: Text(
        t.classe.pagePlanning.habituelIndisponible,
        style: discret,
      ),
    );
  }
}

/// Une seance : le jour, puis l'heure et la duree ; a droite, la pastille
/// d'un etat qui n'est pas celui d'un cours ordinaire a venir.
class _Ligne extends StatelessWidget {
  const _Ligne({required this.affichage, required this.avecFuseau});

  final AffichageSeance affichage;
  final bool avecFuseau;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final Widget? pastille = affichage.widgetPastille;
    final bool annulee = affichage.etatPastille == EtatPastilleSeance.annulee;
    final bool large = classeEnColonnes(context);
    final TextStyle styleDate = palette.inkStrong.applyTo(
      (large ? textes.titleMedium : textes.titleSmall) ?? const TextStyle(),
    );
    return MergeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppTouchTarget.standard),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          // La date et l'heure d'abord, la pastille au bout de la ligne ;
          // quand les deux ne tiennent pas (320 px, texte x2), la pastille
          // passe dessous : a cote, elle reduisait la date a « Di / ma /
          // nc... » (COM-RC tour 7, lot L).
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) => Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // « 4 octobre » sur une ligne quand il y tient (lot L).
                    TexteHeureSeance(
                      heure: nombresLiesSiTient(
                        context,
                        affichage.date,
                        styleDate,
                        c.maxWidth,
                      ),
                      annulee: annulee,
                      style: styleDate,
                    ),
                    Ecart.vXs,
                    TexteHeureSeance(
                      heure: avecFuseau
                          ? t.classe.pagePlanning.ligneFuseau(
                              heure: affichage.heure,
                              fuseau: affichage.fuseau,
                              duree: affichage.duree,
                            )
                          : t.classe.pagePlanning.ligne(
                              heure: affichage.heure,
                              duree: affichage.duree,
                            ),
                      annulee: annulee,
                      // Une seule annonce « Annulee » par carte : la date.
                      annoncer: false,
                      style: AppTypography.tabulaire(
                        palette.inkMuted.applyTo(
                          (large ? textes.bodyLarge : textes.bodyMedium) ??
                              const TextStyle(),
                        ),
                      ),
                    ),
                  ],
                ),
                ?pastille,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
