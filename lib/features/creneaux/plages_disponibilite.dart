import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/planning/service_planning.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/session/session_controleur.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/skeleton.dart';
import 'feuille_plage.dart';
import 'plages.dart';

/// Les heures qui portent deja une Classe de cet enseignant : le **conflit**.
///
/// Le conflit se **voit**, il ne se bloque pas : retirer une disponibilite
/// n'annule aucun cours (`weekly_availability` et
/// `teacher_student_assignments` sont deux tables). Deduplique : deux eleves
/// sur la meme heure ne font qu'un conflit.
Set<HeureSemaine> heuresEngagees(
  List<Affectation> affectations,
  String monId,
) => <HeureSemaine>{
  for (final Affectation a in affectations)
    if (a.active && a.enseignantId == monId)
      (jour: a.creneau.jour, heure: a.creneau.heure),
};

/// `ENS-06` « Mes disponibilites » : une ligne par plage (DISPO-1).
///
/// Le directeur, 01/10 23:16 : la grille de cases jour x heure etait trop
/// compliquee. L'ecran lit donc les heures posees comme des plages
/// « Lundi | de 17 h | a 23 h », et « Ajouter une plage » ouvre une feuille
/// (jours en puces, « de » et « a » dans deux listes, raccourcis). Toucher une
/// plage ouvre la meme feuille, preremplie, pour la modifier ou la supprimer.
///
/// La grille `GrilleSemaine` reste celle de la famille (`TUT-04`) : elle n'est
/// plus rendue ici.
class PlagesDisponibilite extends ConsumerStatefulWidget {
  /// Cree la section.
  const PlagesDisponibilite({super.key});

  @override
  ConsumerState<PlagesDisponibilite> createState() =>
      _PlagesDisponibiliteEtat();
}

class _PlagesDisponibiliteEtat extends ConsumerState<PlagesDisponibilite> {
  String? _confirmation;

  Future<void> _ouvrir({
    required String monId,
    required String fuseau,
    required Set<HeureSemaine> existantes,
    required Set<HeureSemaine> engagees,
    Plage? plage,
  }) async {
    final String? message = await AppBottomSheet.ouvrir<String>(
      context,
      titre: plage == null
          ? t.enseignant.creneaux.feuilleAjouterTitre
          : t.enseignant.creneaux.feuilleModifierTitre(
              jour: t.disponibilites.joursLongs[plage.jour - 1],
            ),
      constructeur: (BuildContext _) => FeuillePlage(
        profilId: monId,
        fuseau: fuseau,
        existantes: existantes,
        engagees: engagees,
        modifiee: plage,
        // Chaque ecriture partielle relit la liste : ce qui est passe se voit
        // derriere la feuille, meme si l'enseignant la ferme sur un echec.
        onEcrit: () => ref.invalidate(disponibilitesProvider(monId)),
      ),
    );
    if (message != null && mounted) {
      setState(() => _confirmation = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final String? monId = ref.watch(sessionProvider).profileId;

    if (monId == null) {
      // La session n'a pas encore livre l'identifiant : c'est un CHARGEMENT.
      return const Skeleton.liste(lignes: 6);
    }

    final AsyncValue<String> fuseau = ref.watch(monFuseauProvider);
    final AsyncValue<List<Creneau>> creneaux = ref.watch(
      disponibilitesProvider(monId),
    );
    final AsyncValue<List<Affectation>> affectations = ref.watch(
      affectationsProvider,
    );
    // Tant que la reponse n'est pas la, l'appareil est repute en ligne : un
    // bandeau affiche pendant la premiere frame clignoterait a chaque montage.
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;

    // Jamais par le type d'execution de l'`AsyncValue` (Riverpod 3).
    final bool lisible = fuseau.hasValue && creneaux.hasValue;
    final bool echec = fuseau.hasError || creneaux.hasError;

    if (!lisible) {
      if (echec) {
        return EmptyState(
          message: t.enseignant.creneaux.grilleErreur,
          invitation: t.enseignant.creneaux.grilleErreurDetail,
          icone: AppIcons.avertissement,
          libelleAction: t.commun.reessayer,
          onAction: () {
            ref.invalidate(monFuseauProvider);
            ref.invalidate(disponibilitesProvider(monId));
          },
        );
      }
      // Aucune heure affichee avant que le fuseau ait repondu : une heure lue
      // dans un fuseau de repli est une heure fausse.
      return const Skeleton.liste(lignes: 6);
    }

    final List<Creneau> poses = creneaux.requireValue;
    final Set<HeureSemaine> existantes = heuresDe(poses);
    final List<Plage> plages = deduirePlages(existantes);
    final Set<HeureSemaine> engagees = heuresEngagees(
      affectations.value ?? const <Affectation>[],
      monId,
    );
    final List<HeureSemaine> engageesTriees = engagees.toList()
      ..sort(
        (HeureSemaine x, HeureSemaine y) => x.jour != y.jour
            ? x.jour.compareTo(y.jour)
            : x.heure.compareTo(y.heure),
      );
    final bool bureau = AppGabarit.de(context) == Gabarit.desktop;

    void ouvrir([Plage? plage]) => _ouvrir(
      monId: monId,
      fuseau: fuseau.requireValue,
      existantes: existantes,
      engagees: engagees,
      plage: plage,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // K-58 : l'ecran commence par une phrase de contexte.
        TexteSansCoupure(
          t.disponibilites.titreEnseignant,
          style: textes.titleMedium,
        ),
        Ecart.vXs,
        TexteSansCoupure(
          plages.isEmpty
              ? t.enseignant.creneaux.aucuneHeure
              : t.enseignant.creneaux.plagesContexte,
          style: textes.bodySmall,
        ),
        if (plages.isNotEmpty) ...<Widget>[
          Ecart.vMd,
          _ListePlages(
            plages: plages,
            engagees: engagees,
            // Hors ligne, la liste reste CONSULTABLE mais inerte : une plage
            // touchee sans reseau echouerait apres le geste.
            onToucher: horsLigne ? null : ouvrir,
          ),
          Ecart.vSm,
          TexteSansCoupure(switch (poses.length) {
            1 => t.disponibilites.poseeUne,
            _ => t.disponibilites.posees(nombre: '${poses.length}'),
          }, style: textes.bodySmall),
        ],
        if (horsLigne) ...<Widget>[
          Ecart.vSm,
          TexteSansCoupure(
            t.enseignant.creneaux.horsLigneGrille,
            style: palette.inkWarning.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
        if (engageesTriees.isNotEmpty) ...<Widget>[
          Ecart.vSm,
          TexteSansCoupure(
            // Le conflit se VOIT, ecrit, avant tout geste.
            engageesTriees.length == 1
                ? t.enseignant.creneaux.heureEngagee(
                    heures: nommerHeure(engageesTriees.single),
                  )
                : t.enseignant.creneaux.heuresEngagees(
                    heures: engageesTriees.map(nommerHeure).join(', '),
                  ),
            style: palette.inkWarning.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
        Ecart.vSm,
        // L'etat « enregistre », nomme : quelle plage, quels jours.
        LocalFeedback(message: _confirmation),
        // K-56 : la seule action pleine de l'ecran, sous sa liste, au bord de
        // fin ; pleine largeur sur telephone seulement (contrat B). Hors
        // ligne, elle n'est pas rendue (jamais grisee) : la phrase ci-dessus
        // dit pourquoi.
        if (!horsLigne) ...<Widget>[
          Ecart.vLg,
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ActionPrincipale(
              libelle: t.enseignant.creneaux.ajouterPlage,
              prefixe: Icon(AppIcons.ajouter.repos),
              pleineLargeur: !bureau,
              onPress: ouvrir,
            ),
          ),
        ],
      ],
    );
  }
}

/// Les plages, une par ligne, dans UNE carte a filets (K-55, contenus lies).
///
/// Trois colonnes alignees « Lundi | de 17 h | a 23 h » tant qu'elles
/// tiennent ; a texte agrandi ou sur une ligne etroite, la ligne s'empile
/// (« Lundi » puis « de 17 h a 23 h ») au lieu de couper un mot.
class _ListePlages extends StatelessWidget {
  const _ListePlages({
    required this.plages,
    required this.engagees,
    required this.onToucher,
  });

  final List<Plage> plages;
  final Set<HeureSemaine> engagees;
  final void Function(Plage plage)? onToucher;

  /// Ce que la ligne pose autour des colonnes : retrait de debut (16), ecart
  /// apres la tete (12), ecart et chevron (8 + 20), retrait de fin (16), et
  /// le filet de la carte.
  static const double _fixes =
      AppSpacing.lg +
      AppSpacing.md +
      AppSpacing.sm +
      AppSpacing.xl +
      AppSpacing.lg +
      AppSpacing.xs;

  /// Ecart entre deux colonnes.
  static const double _gouttiere = AppSpacing.lg;

  static double _largeur(BuildContext context, String texte, TextStyle style) {
    final TextPainter p = TextPainter(
      text: TextSpan(text: texte, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final double largeur = p.width.ceilToDouble() + 1;
    p.dispose();
    return largeur;
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle style = palette.inkStrong.applyTo(
      Theme.of(context).textTheme.bodyLarge ?? const TextStyle(),
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double jour = plages
            .map((Plage p) => _largeur(context, jourCapitalise(p.jour), style))
            .fold<double>(0, (double a, double b) => a > b ? a : b);
        final double de = plages
            .map((Plage p) => _largeur(context, libelleDe(p.de), style))
            .fold<double>(0, (double a, double b) => a > b ? a : b);
        final double a = plages
            .map((Plage p) => _largeur(context, libelleA(p.a), style))
            .fold<double>(0, (double x, double y) => x > y ? x : y);
        final bool colonnes =
            MediaQuery.textScalerOf(context).scale(1) <= seuilTexteEmpile &&
            jour + _gouttiere + de + a + _fixes <= c.maxWidth;

        return GroupeReglages(
          lignes: <LigneRubrique>[
            for (final Plage plage in plages)
              _ligne(plage, colonnes: colonnes, jour: jour, de: de, style: style),
          ],
        );
      },
    );
  }

  LigneRubrique _ligne(
    Plage plage, {
    required bool colonnes,
    required double jour,
    required double de,
    required TextStyle style,
  }) {
    final List<HeureSemaine> engagement =
        engagees.where(plage.contient).toList()..sort(
          (HeureSemaine x, HeureSemaine y) => x.heure.compareTo(y.heure),
        );
    // Le conflit est ECRIT sur la plage, jamais porte par la seule couleur.
    final String? conflit = engagement.isEmpty
        ? null
        : t.enseignant.creneaux.plageEngagee(
            heures: engagement.map(nommerHeure).join(', '),
          );
    final String nom = jourCapitalise(plage.jour);
    final String debut = libelleDe(plage.de);
    final String fin = libelleA(plage.a);
    final VoidCallback? onPress = onToucher == null
        ? null
        : () => onToucher!(plage);
    // Aucun libelle semantique pose : la ligne (un bouton) est lue par ses
    // textes, « Lundi, de 17 h, a 23 h », une seule fois.

    if (colonnes) {
      return LigneRubrique(
        // Les deux premieres colonnes, a largeur commune mesuree : « de »
        // commence au meme bord sur chaque ligne, quel que soit le jour.
        meneur: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: jour,
              child: Text(nom, style: style, softWrap: false),
            ),
            const SizedBox(width: _gouttiere),
            SizedBox(
              width: de,
              child: Text(debut, style: style, softWrap: false),
            ),
          ],
        ),
        libelle: fin,
        legende: conflit,
        onPress: onPress,
      );
    }
    return LigneRubrique(
      libelle: nom,
      legende: <String>['$debut $fin', ?conflit].join('\n'),
      onPress: onPress,
    );
  }
}
