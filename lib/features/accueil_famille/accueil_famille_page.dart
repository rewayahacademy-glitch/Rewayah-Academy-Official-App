import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/appairage/service_appairage.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/planning/journee.dart';
import '../../core/planning/service_planning.dart';
import '../../core/router/billet_salle.dart';
import '../../core/router/routes.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/video/service_video.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bento_tile.dart';
import '../../core/widgets/child_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../parcours_offres/bloc_parcours.dart';

/// La phase de vie d'un enfant du foyer, a un instant donne.
///
/// Cinq phases, celles que la fiche produit tabule
/// (`docs/produit/parcours-utilisateurs.md`, fiche `TUT-01`) : en cours, cours a
/// venir aujourd'hui, rien aujourd'hui, en recherche d'enseignant, seance
/// annulee.
///
/// Le nom evite la collision avec `EtatEnfant` de `child_card.dart`, et la
/// distinction est reelle : `PhaseEnfant` **decide** de ce qui se passe,
/// `EtatEnfant` **affiche** avec les phrases deja mises en forme. Le passage de
/// l'une a l'autre est [_CarteEnfant._etat].
enum PhaseEnfant {
  /// Le cours se tient maintenant. Seule phase qui porte « Assister ».
  enCours,

  /// Un cours plus tard dans la journee.
  coursAujourdhui,

  /// Rien aujourd'hui. Le prochain cours se dit avec sa date, ou, quand la
  /// semaine n'est pas encore posee, sans date.
  rienAujourdhui,

  /// Aucun enseignant ne suit encore cet enfant.
  enRecherche,

  /// Le cours attendu n'aura pas lieu.
  seanceAnnulee,
}

/// La phase d'un enfant, a un instant donne.
///
/// Fonction pure, comme `etatAccueilEleve` : les cinq phases se verifient sans
/// monter d'ecran. [prochain] vient de `prochainCours`, qui ecarte deja les
/// seances annulees, et [annulee] de `seanceAnnuleeDuJour`. Les deux ecrans
/// lisent donc la meme seance par les memes fonctions : `ELV-02` et `TUT-01`
/// disent ainsi la meme chose du meme cours, l'un a l'enfant et l'autre a
/// l'adulte.
///
/// **L'affectation ne passe devant que lorsqu'il n'y a rien a annoncer.** Un
/// enfant dont l'enseignant vient de changer garde des seances planifiees :
/// afficher « en recherche d'un enseignant » au-dessus d'un cours qui commence
/// dans dix minutes serait faux, et inquietant.
PhaseEnfant phaseEnfant({
  required Seance? prochain,
  required Seance? annulee,
  required bool affecte,
  required DateTime maintenant,
}) {
  if (annulee != null &&
      (prochain == null || annulee.debut.isBefore(prochain.debut))) {
    return PhaseEnfant.seanceAnnulee;
  }
  if (prochain == null) {
    return affecte ? PhaseEnfant.rienAujourdhui : PhaseEnfant.enRecherche;
  }
  if (prochain.enCoursA(maintenant)) {
    return PhaseEnfant.enCours;
  }
  return _memeJour(prochain.debut, maintenant)
      ? PhaseEnfant.coursAujourdhui
      : PhaseEnfant.rienAujourdhui;
}

/// Depuis quand ce foyer attend un enseignant.
///
/// C'est la date de la premiere heure proposee, et **la meme grandeur que celle
/// sur laquelle `ENS-06` trie son feed** : le foyer et l'enseignant lisent la
/// meme anciennete. `null` quand aucune heure n'est proposee, ou quand la
/// source ne date pas ses lignes.
DateTime? attendDepuis(List<Creneau> creneaux) {
  DateTime? plusAncien;
  for (final Creneau creneau in creneaux) {
    final DateTime? pose = creneau.poseLe;
    if (pose != null && (plusAncien == null || pose.isBefore(plusAncien))) {
      plusAncien = pose;
    }
  }
  return plusAncien;
}

/// `TUT-01` : l'accueil du foyer.
///
/// **Bloc dominant : l'etat en direct de chaque enfant, une carte par enfant**,
/// portee par `ChildCard` (`docs/design/07-catalogue-composants.md` section 3).
/// Le bouton « Assister » n'est cable que pendant une seance en cours ; il entre
/// en observateur muet, et c'est la fonction de confiance la plus forte du
/// produit (`docs/produit/parcours-utilisateurs.md`).
///
/// Sous les cartes, une section « Gerer le foyer » : les appareils, les reglages
/// par enfant, et la date de fin d'acces de chaque enfant, qui tient lieu de
/// portefeuille en MVP-0.
///
/// Repris au lot R (sous-lot R2) : l'ecran passe par `PageShell` au lieu de son
/// `Scaffold` propre, ses lignes deviennent des `ChildCard`, et la pastille
/// « en direct » qui etait un `Container` decore passe par `StatusPill`, portee
/// par la carte. La consequence de fond, la meme qu'a `ELV-02` : le cours en
/// direct n'est plus un aplat `surfacePrimary` plein mais une carte posee, seul
/// son bouton porte l'aplat sature, et deux enfants en cours ne font donc plus
/// deux zones pleines (`docs/design/01-systeme-visuel.md` section 3).
class AccueilFamillePage extends ConsumerStatefulWidget {
  /// Cree l'accueil du foyer.
  const AccueilFamillePage({super.key, this.horloge = DateTime.now});

  /// D'ou vient l'instant courant.
  ///
  /// Injectable pour la meme raison que sur `ELV-02` : le minuteur ecoule et le
  /// partage entre « aujourd'hui » et « un autre jour » se comptent en minutes,
  /// et un test cale sur l'horloge de la machine changerait de resultat selon
  /// l'heure a laquelle la CI le lance.
  final DateTime Function() horloge;

  @override
  ConsumerState<AccueilFamillePage> createState() => _AccueilFamillePageEtat();
}

class _AccueilFamillePageEtat extends ConsumerState<AccueilFamillePage> {
  Timer? _minuteur;
  late DateTime _maintenant = widget.horloge();

  /// Ce que dit l'ecran quand l'inscription du tuteur a echoue. `null` tant que
  /// rien n'a echoue.
  String? _echecAssistance;

  @override
  void initState() {
    super.initState();
    // Le minuteur ecoule se lit en minutes, comme celui de `ENS-02` : le
    // rafraichir a la seconde ferait travailler l'ecran soixante fois pour rien.
    _minuteur = Timer.periodic(
      const Duration(minutes: 1),
      (Timer _) => setState(() => _maintenant = widget.horloge()),
    );
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    super.dispose();
  }

  /// Inscrit le tuteur comme temoin, PUIS ouvre la salle.
  ///
  /// Le geste etait un simple `go` jusqu'au lot `CTR-01`, et il ne pouvait pas
  /// aboutir : `autoriser_jeton_video()` lit l'appartenance dans
  /// `session_participants`, ou personne n'inscrivait le tuteur. Il arrivait
  /// donc dans l'impasse d'acces de la salle, sans que rien ne dise pourquoi.
  /// La migration `0012` ouvre la porte ; celle-ci la franchit avant de
  /// naviguer, parce qu'un refus se dit ici, pas trois ecrans plus loin.
  Future<void> _assister(String seanceId) async {
    try {
      await ref.read(serviceVideoProvider).assisterEnTuteur(seanceId);
    } on Object {
      if (mounted) {
        setState(() => _echecAssistance = t.tuteur.accueil.assisterRefuse);
      }
      return;
    }
    if (!mounted) {
      return;
    }
    GoRouter.of(context).go(
      Routes.salle,
      // Le billet passe par `extra`, jamais par l'URL (ADR-005).
      extra: BilletSalle(sessionId: seanceId, emisA: DateTime.now()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    final AsyncValue<List<EleveDuFoyer>> enfants = ref.watch(
      elevesDuFoyerProvider,
    );
    final AsyncValue<List<Seance>> seances = ref.watch(seancesProvider);
    final AsyncValue<List<Affectation>> affectations = ref.watch(
      affectationsProvider,
    );

    final List<EleveDuFoyer> foyer = enfants.value ?? const <EleveDuFoyer>[];
    final List<Seance> toutes = seances.value ?? const <Seance>[];
    final List<Affectation> liens = affectations.value ?? const <Affectation>[];

    final bool enErreur =
        seances.hasError || enfants.hasError || affectations.hasError;

    final bool chargementInitial =
        (!enfants.hasValue && enfants.isLoading) ||
        (!seances.hasValue && seances.isLoading) ||
        (!affectations.hasValue && affectations.isLoading);

    // `PageShell` porte le fond creme, la gouttiere du gabarit courant, la
    // colonne centree et bornee a 1200, le titre d'ecran et le bandeau hors
    // ligne. L'ecran ne rend plus que son contenu.
    return PageShell(
      titre: t.tuteur.accueil.titre,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Ce qui se passe AVANT qu'un cours existe : personnalisation, choix
          // d'horaire, constitution du groupe. Pose au-dessus des cartes parce
          // que c'est ce qui attend un geste ; il se retire tout seul quand
          // chaque apprenant du foyer a son groupe.
          const BlocParcours(),
          if (chargementInitial)
            const Skeleton.liste(lignes: 4)
          else if (enfants.hasValue && foyer.isEmpty)
            EmptyState(
              message: t.tuteur.accueil.aucunEnfant,
              invitation: t.tuteur.accueil.aucunEnfantDetail,
              libelleAction: t.enfant.titre,
              onAction: () =>
                  GoRouter.of(context).go(Routes.tuteurAjouterEnfant),
            )
          else
            for (final EleveDuFoyer enfant in foyer)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _CarteEnfant(
                  enfant: enfant,
                  seances: toutes
                      .where((Seance s) => s.eleveId == enfant.id)
                      .toList(),
                  affecte: liens.any(
                    (Affectation a) => a.active && a.eleveId == enfant.id,
                  ),
                  maintenant: _maintenant,
                  onAssister: _assister,
                ),
              ),
          // Pose sous les cartes, la ou le geste a eu lieu : un retour local ne
          // se met jamais au centre de l'ecran (`02-regles-ux.md` section 7).
          LocalFeedback(message: _echecAssistance),
          if (enErreur) ...<Widget>[
            Ecart.vSm,
            Text(
              t.tuteur.accueil.erreur,
              // L'encre d'alerte, jamais la paire : `surfaceAlert` ecrit en
              // blanc, illisible sur le fond de page.
              style: palette.inkAlert.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
          ],
          Ecart.vXl,
          SectionHeader(titre: t.tuteur.accueil.gererLeFoyer),
          Ecart.vLg,
          const _GererLeFoyer(),
          if (foyer.isNotEmpty) ...<Widget>[
            Ecart.vMd,
            _BlocAcces(enfants: foyer),
          ],
        ],
      ),
    );
  }
}

/// Une carte par enfant, dans l'une de ses cinq phases.
///
/// `ConsumerWidget` parce que la phase « en recherche » a besoin des creneaux
/// proposes pour l'enfant, et qu'ils vivent dans leur propre provider
/// (`disponibilitesProvider`). Les quatre autres phases ne le lisent pas.
class _CarteEnfant extends ConsumerWidget {
  const _CarteEnfant({
    required this.enfant,
    required this.seances,
    required this.affecte,
    required this.maintenant,
    required this.onAssister,
  });

  final EleveDuFoyer enfant;

  /// Les seances de cet enfant, deja filtrees par l'ecran.
  final List<Seance> seances;

  final bool affecte;
  final DateTime maintenant;

  /// Ce que fait « Assister » : inscrire, puis ouvrir la salle. La carte ne
  /// connait ni l'un ni l'autre, elle rend le geste a l'ecran qui la porte.
  final Future<void> Function(String seanceId) onAssister;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Seance? prochain = prochainCours(seances, maintenant);
    final Seance? annulee = seanceAnnuleeDuJour(seances, maintenant);
    final PhaseEnfant phase = phaseEnfant(
      prochain: prochain,
      annulee: annulee,
      affecte: affecte,
      maintenant: maintenant,
    );

    // Les creneaux ne sont lus que par la phase qui s'en sert : sans heure
    // proposee, la recherche ne peut pas aboutir, et l'ecran le dit autrement.
    final AsyncValue<List<Creneau>>? creneaux = phase == PhaseEnfant.enRecherche
        ? ref.watch(disponibilitesProvider(enfant.id))
        : null;
    final List<Creneau> poses = creneaux?.value ?? const <Creneau>[];
    final bool sansPlanning =
        phase == PhaseEnfant.enRecherche &&
        (creneaux?.hasValue ?? false) &&
        poses.isEmpty;

    return ChildCard(
      prenom: enfant.prenom,
      etat: _etat(
        phase: phase,
        prochain: prochain,
        annulee: annulee,
        poses: poses,
        sansPlanning: sansPlanning,
      ),
      // `TUT-01` n'a pas d'ecran de detail par enfant : la carte n'est pas
      // cliquable et ne porte pas de chevron, comme avant la reprise. Le chevron
      // de la ligne « Normal » du catalogue attend un ecran de suivi par enfant
      // (`docs/design/07-catalogue-composants.md` section 3).
      onPoserHoraire: sansPlanning
          ? () => GoRouter.of(context).go(Routes.tuteurDisponibilites)
          : null,
      // Le bouton n'est cable que pendant une seance en cours : ailleurs, il
      // n'y a pas de salle a rejoindre, et un bouton qui echoue apres le geste
      // coute plus cher qu'un bouton absent.
      onAssister: phase == PhaseEnfant.enCours && prochain != null
          ? () => unawaited(onAssister(prochain.id))
          : null,
    );
  }

  /// Traduit une [PhaseEnfant] en `EtatEnfant`, l'etat visuel scelle de
  /// `ChildCard`, avec les phrases mises en forme pour un adulte.
  EtatEnfant _etat({
    required PhaseEnfant phase,
    required Seance? prochain,
    required Seance? annulee,
    required List<Creneau> poses,
    required bool sansPlanning,
  }) => switch (phase) {
    PhaseEnfant.enCours => EnfantEnCours(
      // Le prenom de l'enseignant, jamais son nom de famille (ADR-008).
      enseignant: prochain!.enseignantPrenom,
      depuis: _ecoule(maintenant.difference(prochain.debut)),
    ),
    PhaseEnfant.coursAujourdhui => EnfantProchainCours(
      t.tuteur.accueil.aujourdhui(
        heure: _hhmm(prochain!.debut),
        prenom: prochain.enseignantPrenom,
      ),
    ),
    // Date et heure, contrairement a `ELV-02` qui compte en jours : le parent
    // organise sa semaine. La reprise laisse tomber le preambule « Rien
    // aujourd'hui » : la carte affiche directement le prochain rendez-vous, ce
    // que le catalogue nomme « Rien aujourd'hui : prochain cours date ».
    PhaseEnfant.rienAujourdhui => EnfantProchainCours(
      prochain == null
          ? t.tuteur.accueil.aucunCoursPrevu
          : t.tuteur.accueil.unAutreJour(
              jour: t.disponibilites.joursLongs[prochain.debut.weekday - 1],
              heure: _hhmm(prochain.debut),
              prenom: prochain.enseignantPrenom,
            ),
    ),
    PhaseEnfant.enRecherche =>
      sansPlanning ? const EnfantSansPlanning() : _enRecherche(poses),
    PhaseEnfant.seanceAnnulee => EnfantSeanceAnnulee(
      // Le motif tenait sur deux registres : un libelle de statut et une
      // phrase. `ChildCard` porte le statut dans sa pastille « Annule » ; la
      // phrase va dans `motif`. L'annulation tardive garde sa phrase a elle,
      // la seule difference qui compte pour un parent.
      motif: annulee!.statut == StatutSeance.annuleeTard
          ? t.tuteur.accueil.motifAnnuleeTard
          : t.tuteur.accueil.annulee(heure: _hhmm(annulee.debut)),
      propose: prochain == null
          ? t.tuteur.accueil.proposeAucun
          : t.tuteur.accueil.proposeApres(
              jour: t.disponibilites.joursLongs[prochain.debut.weekday - 1],
              heure: _hhmm(prochain.debut),
            ),
    ),
  };

  /// L'enfant attend un enseignant, et des heures sont bien proposees : depuis
  /// quand. La plus ancienne des heures, pas la derniere, parce que c'est
  /// l'anciennete sur laquelle `ENS-06` trie son feed.
  EtatEnfant _enRecherche(List<Creneau> poses) {
    final DateTime? depuis = attendDepuis(poses);
    return EnfantEnRecherche(
      depuis == null
          ? t.tuteur.accueil.enRechercheSansDate(prenom: enfant.prenom)
          : t.tuteur.accueil.enRechercheDepuis(date: _jour(depuis)),
    );
  }
}

/// Le bloc « Gerer le foyer » : une seule carte elevee, deux lignes de menu.
///
/// Avant ce lot, chaque lien etait sa propre `BentoTile` : deux surfaces
/// elevees empilees, du meme poids visuel que les `ChildCard` au dessus,
/// exactement la « decoration universelle » que `00-bible-frontend-v2.md`
/// section 11 bis interdit a `BentoTile`. Une seule `AppCard` les regroupe
/// desormais, chaque ligne restant pressable pour sa propre destination
/// (constat du 11 septembre 2026, capture d'ecran a l'appui).
class _GererLeFoyer extends StatelessWidget {
  const _GererLeFoyer();

  @override
  Widget build(BuildContext context) => AppCard(
    marge: 0,
    child: Column(
      children: <Widget>[
        _LigneMenu(
          icone: AppIcons.appareil,
          titre: t.tuteur.accueil.blocAppareils,
          detail: t.tuteur.accueil.blocAppareilsDetail,
          destination: Routes.tuteurFoyer,
        ),
        const Divider(height: 1),
        _LigneMenu(
          icone: AppIcons.reglages,
          titre: t.tuteur.accueil.blocReglages,
          detail: t.tuteur.accueil.blocReglagesDetail,
          destination: Routes.tuteurReglages,
        ),
        const Divider(height: 1),
        // Mes groupes (Teaching Core, lot A) : plafond de quatre destinations
        // deja tenu par la barre, l'entree se pose ici plutot que d'en
        // forcer une cinquieme (meme motif que ce bloc lui-meme pour les
        // appareils et les reglages).
        _LigneMenu(
          icone: AppIcons.cours,
          titre: LibellesGroupe.mesGroupesTitre,
          detail: t.tuteur.accueil.blocGroupesDetail,
          destination: Routes.tcGroupes,
        ),
      ],
    ),
  );
}

/// Une ligne de menu vers un ecran : icone, titre, detail, chevron.
class _LigneMenu extends StatelessWidget {
  const _LigneMenu({
    required this.icone,
    required this.titre,
    required this.detail,
    required this.destination,
  });

  final AppIcon icone;
  final String titre;
  final String detail;
  final String destination;

  @override
  Widget build(BuildContext context) {
    final AppMetriques metriques = AppMetriques.of(context);
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Pressable(
      onPress: () => GoRouter.of(context).go(destination),
      libelleSemantique: '$titre, $detail',
      respecterCibleTactile: false,
      arrondiFocus: AppRadius.arrondiSm,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: metriques.cibleTactile),
        child: Padding(
          padding: EdgeInsets.all(metriques.marge),
          child: Row(
            children: <Widget>[
              IconTheme(
                data: palette.inkAccent.asIconTheme(
                  size: metriques.estEnfant ? AppSpacing.xxxl : AppSpacing.xxl,
                ),
                child: Icon(icone.repos),
              ),
              Ecart.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(titre, style: textes.titleMedium),
                    Text(detail, style: textes.bodySmall),
                  ],
                ),
              ),
              Ecart.hSm,
              IconTheme(
                data: palette.inkFaint.asIconTheme(size: AppSpacing.xl),
                // Le chevron se miroite en arabe : une direction de lecture,
                // pas une progression du temps (meme registre que
                // `SignalRow`).
                child: Icon(AppIcons.chevron.repos),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bloc secondaire : la date de fin d'acces de chaque enfant.
///
/// Elle tient lieu de portefeuille en MVP-0 : le produit n'a pas de solde, il a
/// une echeance, et c'est elle que le parent veut voir sans la chercher.
class _BlocAcces extends StatelessWidget {
  const _BlocAcces({required this.enfants});

  final List<EleveDuFoyer> enfants;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;

    return BentoTile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(t.tuteur.accueil.acces, style: textes.titleMedium),
          Ecart.vXs,
          for (final EleveDuFoyer enfant in enfants)
            Text(
              enfant.finAcces == null
                  ? t.tuteur.accueil.accesSansFin(prenom: enfant.prenom)
                  : t.tuteur.accueil.accesJusqua(
                      prenom: enfant.prenom,
                      date: _jour(enfant.finAcces!),
                    ),
              style: textes.bodySmall,
            ),
        ],
      ),
    );
  }
}

/// Le temps ecoule depuis le debut du cours, dit a un adulte.
String _ecoule(Duration depuis) {
  final int minutes = depuis.inMinutes;
  return minutes <= 0
      ? t.tuteur.accueil.depuisInstant
      : t.tuteur.accueil.depuisMinutes(minutes: '$minutes');
}

/// L'heure locale d'un instant, sur deux chiffres.
String _hhmm(DateTime quand) =>
    '${quand.hour.toString().padLeft(2, '0')}:'
    '${quand.minute.toString().padLeft(2, '0')}';

/// Une date civile, telle que le reste des ecrans du tuteur l'ecrit.
String _jour(DateTime quand) =>
    '${quand.day.toString().padLeft(2, '0')}/'
    '${quand.month.toString().padLeft(2, '0')}/${quand.year}';

/// Vrai quand deux instants tombent le meme jour civil local.
bool _memeJour(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
