import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/planning/service_planning.dart';
import '../../core/router/routes.dart';
import '../../core/suivi/service_suivi.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/controle_segmente.dart';
import '../../core/widgets/menu_filtre.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/selecteur_profils.dart';
import '../../core/widgets/status_pill.dart';
import '../compte/carte_rubriques.dart';
import 'filtres_historique.dart';

// Composants de l'Historique du tuteur (lot E, chantier Tuteur V1), composes
// d'apres la maquette V8 D2 (`tuteur observation desktop light.png`,
// panneau 2) : titre, selecteur de profils, segment Seances / Observations,
// trois filtres, puis UNE carte dont les lignes sont separees par un filet.

/// Les deux vues de l'Historique, chacune sur sa route.
enum SegmentHistorique {
  /// `/tuteur/suivi`.
  seances,

  /// `/tuteur/suivi/observations`.
  observations,
}

/// La colonne de l'Historique : sur bureau, alignee au debut et bornee a la
/// largeur de lecture (manifeste section 7 : « desktop : selecteur aligne a
/// gauche, liste pleine largeur limitee a largeurLecture »).
class ColonneHistorique extends StatelessWidget {
  /// Cree la colonne.
  const ColonneHistorique({required this.child, super.key});

  /// Le contenu.
  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.topStart,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppPage.largeurLecture),
      child: child,
    ),
  );
}

/// La tete commune aux deux segments : selecteur de profils (contrat K1,
/// meme selection que l'Accueil) puis segment Seances / Observations.
///
/// L'item « Ajouter » du selecteur n'est **pas** rendu : ajouter un profil
/// eleve a sa place unique dans le Foyer (carte des fonctions du lot E).
class EnteteHistorique extends ConsumerWidget {
  /// Cree la tete.
  const EnteteHistorique({
    required this.segment,
    required this.maintenant,
    super.key,
  });

  /// Le segment affiche.
  final SegmentHistorique segment;

  /// L'instant de reference (compte des seances passees).
  final DateTime maintenant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ProfilEleveFoyer>> profils = ref.watch(
      profilsElevesFoyerProvider,
    );
    final AsyncValue<ProfilEleveFoyer?> retenu = ref.watch(
      eleveSelectionneProvider,
    );
    final AsyncValue<List<Seance>> seances = ref.watch(seancesDuSuiviProvider);
    final Map<String, int>? compte = seances.hasValue && !seances.hasError
        ? seancesPasseesParEleve(seances.requireValue, maintenant)
        : null;
    final List<ProfilEleveFoyer> liste = profils.hasValue && !profils.hasError
        ? profils.requireValue
        : const <ProfilEleveFoyer>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (liste.isNotEmpty) ...<Widget>[
          SelecteurProfils(
            profils: <ProfilSelectionnable>[
              for (final ProfilEleveFoyer p in liste)
                ProfilSelectionnable(
                  id: p.eleveId,
                  prenom: p.prenom,
                  etat: compte == null
                      ? ''
                      : nombreSeances(compte[p.eleveId] ?? 0),
                ),
            ],
            selectionId: retenu.hasValue ? retenu.value?.eleveId : null,
            onSelection: (String id) =>
                ref.read(selectionEleveProvider.notifier).choisir(id),
          ),
          Ecart.vLg,
        ],
        ControleSegmente<SegmentHistorique>(
          segments: <Segment<SegmentHistorique>>[
            Segment<SegmentHistorique>(
              valeur: SegmentHistorique.seances,
              libelle: t.historique.segments.seances,
            ),
            Segment<SegmentHistorique>(
              valeur: SegmentHistorique.observations,
              libelle: t.historique.segments.observations,
            ),
          ],
          valeur: segment,
          onChange: (SegmentHistorique vers) => GoRouter.of(context).go(
            vers == SegmentHistorique.seances
                ? Routes.tuteurSuivi
                : Routes.tuteurSuiviObservations,
          ),
        ),
      ],
    );
  }
}

/// Les trois filtres de la maquette : Classe, Periode, Statut. Un filtre
/// sans choix reel n'est pas rendu (aucune classe nommable : pas de menu
/// Classe ; aucune ligne : pas de menu Statut).
class BarreFiltresHistorique<S> extends StatelessWidget {
  /// Cree la barre.
  const BarreFiltresHistorique({
    required this.filtres,
    required this.classes,
    required this.statuts,
    required this.onFiltres,
    super.key,
  });

  /// Les filtres courants.
  final FiltresHistorique<S> filtres;

  /// Les classes nommables : identifiant vers libelle.
  final Map<String, String> classes;

  /// Les statuts presents dans la lecture, avec leur compte.
  final List<(S, int)> statuts;

  /// Rappele avec les nouveaux filtres.
  final ValueChanged<FiltresHistorique<S>> onFiltres;

  /// Le libelle d'un statut.
  static String libelleDe(Object? statut) => switch (statut) {
    final StatutHistorique s => s.libelle,
    final StatutObservation s => s.libelle,
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, String>> classesTriees =
        classes.entries.toList()..sort(
          (MapEntry<String, String> a, MapEntry<String, String> b) =>
              a.value.compareTo(b.value),
        );
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        if (classesTriees.isNotEmpty)
          MenuFiltre<String>(
            libelle: t.historique.filtres.classe,
            valeur: filtres.classeId,
            entrees: <EntreeFiltre<String>>[
              EntreeFiltre<String>(
                valeur: null,
                libelle: t.historique.filtres.toutesClasses,
              ),
              for (final MapEntry<String, String> c in classesTriees)
                EntreeFiltre<String>(valeur: c.key, libelle: c.value),
            ],
            onChoix: (String? c) => onFiltres(filtres.avecClasse(c)),
          ),
        MenuFiltre<PeriodeHistorique>(
          libelle: t.historique.filtres.periode,
          valeur: filtres.periode == PeriodeHistorique.toute
              ? null
              : filtres.periode,
          entrees: <EntreeFiltre<PeriodeHistorique>>[
            for (final PeriodeHistorique p in PeriodeHistorique.values)
              EntreeFiltre<PeriodeHistorique>(
                valeur: p == PeriodeHistorique.toute ? null : p,
                libelle: p.libelle,
              ),
          ],
          onChoix: (PeriodeHistorique? p) =>
              onFiltres(filtres.avecPeriode(p ?? PeriodeHistorique.toute)),
        ),
        if (statuts.isNotEmpty)
          MenuFiltre<S>(
            libelle: t.historique.filtres.statut,
            valeur: filtres.statut,
            entrees: <EntreeFiltre<S>>[
              EntreeFiltre<S>(
                valeur: null,
                libelle: t.historique.filtres.tousStatuts,
              ),
              for (final (S statut, int n) in statuts)
                EntreeFiltre<S>(
                  valeur: statut,
                  libelle: libelleDe(statut),
                  compteur: n,
                ),
            ],
            onChoix: (S? s) => onFiltres(filtres.avecStatut(s)),
          ),
      ],
    );
  }
}

/// UNE carte, des lignes separees par un filet fin (decision du directeur :
/// « carte groupee = un seul rectangle »).
class CarteLignes extends StatelessWidget {
  /// Cree la carte.
  const CarteLignes({required this.lignes, super.key});

  /// Les lignes, dans l'ordre d'affichage.
  final List<Widget> lignes;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return SurfaceCarte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < lignes.length; i++)
            if (i == 0)
              lignes[i]
            else
              DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  border: Border(top: palette.contourCarte.asBorderSide()),
                ),
                child: lignes[i],
              ),
        ],
      ),
    );
  }
}

/// Une ligne d'historique (maquette V8 D2) : date en gras et meta a gauche,
/// filet vertical, classe et second libelle, pastille de statut, chevron.
///
/// Sur telephone a texte agrandi (>= 150 %), les trois blocs s'empilent au
/// lieu de couper les mots. Le lecteur d'ecran lit une phrase entiere
/// ([semantique]) ; la ligne entiere est la cible (>= 48 de haut).
class LigneHistorique extends StatelessWidget {
  /// Cree une ligne.
  const LigneHistorique({
    required this.date,
    required this.meta,
    required this.titre,
    required this.sousTitre,
    required this.statut,
    required this.ton,
    required this.semantique,
    required this.onPress,
    super.key,
  });

  /// La date, en gras.
  final String date;

  /// La ligne sous la date : horaire ou resume des visites.
  final String meta;

  /// La classe.
  final String titre;

  /// L'enseignant (seances) ou l'eleve (observations).
  final String sousTitre;

  /// Le libelle de la pastille.
  final String statut;

  /// Le ton de la pastille.
  final TonEtat ton;

  /// Ce que lit le lecteur d'ecran.
  final String semantique;

  /// L'ouverture du detail.
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) => Pressable.selon(
    onPress: onPress,
    libelleSemantique: semantique,
    respecterCibleTactile: false,
    arrondiFocus: AppRadius.arrondiSm,
    constructeur: _contenu,
  );

  Widget _contenu(BuildContext context, EtatPression etat) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool empiler =
        MediaQuery.textScalerOf(context).scale(AppSpacing.lg) / AppSpacing.lg >=
        AppGabarit.seuilTexteColonne;
    final TextStyle fort = palette.inkStrong.applyTo(
      textes.titleSmall ?? const TextStyle(),
    );
    final TextStyle doux = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );

    final Widget blocDate = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(date, style: fort),
        Ecart.vXs,
        Text(meta, style: AppTypography.tabulaire(doux)),
      ],
    );
    final Widget blocClasse = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(titre, style: fort),
        Ecart.vXs,
        Text(sousTitre, style: doux),
      ],
    );
    final Widget pastille = StatusPill(libelle: statut, ton: ton);
    final Widget chevron = IconTheme(
      data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
      child: Icon(AppIcons.chevron.repos),
    );

    return ColoredBox(
      color: etat.survole || etat.presse
          ? Color.alphaBlend(
              palette.calqueInteraction(presse: etat.presse),
              palette.surfaceRaised.background,
            )
          : palette.surfaceRaised.background,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppTouchTarget.standard),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: ExcludeSemantics(
            child: empiler
                ? Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            blocDate,
                            Ecart.vSm,
                            blocClasse,
                            Ecart.vSm,
                            pastille,
                          ],
                        ),
                      ),
                      Ecart.hSm,
                      chevron,
                    ],
                  )
                : LayoutBuilder(
                    builder: (BuildContext _, BoxConstraints contraintes) {
                      // Sur un vrai telephone (la maquette est dessinee plus
                      // dense), la pastille passe sous la classe plutot que
                      // d'ecraser les deux colonnes de texte.
                      final bool pastilleADroite =
                          contraintes.maxWidth >= _largeurPastilleADroite;
                      return Row(
                        children: <Widget>[
                          Expanded(flex: 5, child: blocDate),
                          // Le filet vertical de la maquette, centre dans
                          // une gouttiere de 24.
                          SizedBox(
                            height: AppSpacing.section,
                            child: VerticalDivider(
                              width: AppSpacing.xxl,
                              thickness: palette.contourCarte
                                  .asBorderSide()
                                  .width,
                              color: palette.contourCarte.asBorderSide().color,
                            ),
                          ),
                          Expanded(
                            flex: 6,
                            child: pastilleADroite
                                ? blocClasse
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      blocClasse,
                                      Ecart.vSm,
                                      pastille,
                                    ],
                                  ),
                          ),
                          if (pastilleADroite) ...<Widget>[Ecart.hSm, pastille],
                          Ecart.hXs,
                          chevron,
                        ],
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  /// La largeur de ligne a partir de laquelle la pastille tient a droite.
  static const double _largeurPastilleADroite = AppPage.largeurDialogue;
}

/// La phrase de fuseau, en pied de liste ou de detail : l'heure affichee est
/// celle de l'appareil, et on le dit (mandat : fuseau explicite).
class NoteHistorique extends StatelessWidget {
  /// Cree la note.
  const NoteHistorique(this.texte, {super.key});

  /// Le texte.
  final String texte;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Text(
      texte,
      style: palette.inkMuted.applyTo(textes.bodySmall ?? const TextStyle()),
    );
  }
}

/// Un parametre de requete de l'adresse courante (`?eleve=`, `?classe=`),
/// ou `null` hors routeur.
String? parametreRequete(BuildContext context, String cle) {
  if (GoRouter.maybeOf(context) == null) {
    return null;
  }
  final String? valeur = GoRouterState.of(context).uri.queryParameters[cle];
  return valeur == null || valeur.isEmpty ? null : valeur;
}
