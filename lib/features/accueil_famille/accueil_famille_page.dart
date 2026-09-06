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
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bento_tile.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/offline_banner.dart';

/// Ce que la ligne d'un enfant annonce sur `TUT-01`.
///
/// Les cinq etats sont ceux que la fiche produit tabule, dans son ordre : en
/// cours, cours a venir aujourd'hui, rien aujourd'hui, en recherche
/// d'enseignant, seance annulee
/// (`docs/produit/parcours-utilisateurs.md`, fiche `TUT-01`).
enum EtatEnfant {
  /// Le cours se tient maintenant. Seul etat qui porte « Assister ».
  enCours,

  /// Un cours plus tard dans la journee.
  coursAujourdhui,

  /// Rien aujourd'hui. Le prochain cours se dit avec sa date.
  rienAujourdhui,

  /// Aucun enseignant ne suit encore cet enfant.
  enRecherche,

  /// Le cours attendu n'aura pas lieu.
  seanceAnnulee,
}

/// L'etat d'un enfant, a un instant donne.
///
/// Fonction pure, comme `etatAccueilEleve` : les cinq etats se verifient sans
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
EtatEnfant etatEnfant({
  required Seance? prochain,
  required Seance? annulee,
  required bool affecte,
  required DateTime maintenant,
}) {
  if (annulee != null &&
      (prochain == null || annulee.debut.isBefore(prochain.debut))) {
    return EtatEnfant.seanceAnnulee;
  }
  if (prochain == null) {
    return affecte ? EtatEnfant.rienAujourdhui : EtatEnfant.enRecherche;
  }
  if (prochain.enCoursA(maintenant)) {
    return EtatEnfant.enCours;
  }
  return _memeJour(prochain.debut, maintenant)
      ? EtatEnfant.coursAujourdhui
      : EtatEnfant.rienAujourdhui;
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
/// **Bloc dominant : l'etat en direct de chaque enfant, une ligne par enfant.**
/// Le bouton « Assister » n'est rendu que pendant une seance en cours ; il entre
/// en observateur muet, et c'est la fonction de confiance la plus forte du
/// produit (`docs/produit/parcours-utilisateurs.md`).
///
/// Blocs secondaires : les appareils, les reglages par enfant, et la date de fin
/// d'acces de chaque enfant, qui tient lieu de portefeuille en MVP-0.
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

  @override
  Widget build(BuildContext context) {
    final AppMetriques metriques = AppMetriques.of(context);
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    final AsyncValue<List<EleveDuFoyer>> enfants = ref.watch(
      elevesDuFoyerProvider,
    );
    final AsyncValue<List<Seance>> seances = ref.watch(seancesProvider);
    final AsyncValue<List<Affectation>> affectations = ref.watch(
      affectationsProvider,
    );

    final List<EleveDuFoyer> foyer =
        enfants.value ?? const <EleveDuFoyer>[];
    final List<Seance> toutes = seances.value ?? const <Seance>[];
    final List<Affectation> liens =
        affectations.value ?? const <Affectation>[];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const OfflineBanner(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref
                    ..invalidate(elevesDuFoyerProvider)
                    ..invalidate(seancesProvider)
                    ..invalidate(affectationsProvider);
                },
                child: ListView(
                  padding: EdgeInsets.all(metriques.marge),
                  children: <Widget>[
                    Text(t.tuteur.accueil.titre, style: textes.headlineSmall),
                    Ecart.vLg,
                    if (enfants.hasValue && foyer.isEmpty)
                      EmptyState(
                        message: t.tuteur.accueil.aucunEnfant,
                        invitation: t.tuteur.accueil.aucunEnfantDetail,
                        libelleAction: t.enfant.titre,
                        onAction: () => GoRouter.of(
                          context,
                        ).go(Routes.tuteurAjouterEnfant),
                      )
                    else
                      for (final EleveDuFoyer enfant in foyer)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _LigneEnfant(
                            enfant: enfant,
                            seances: toutes
                                .where(
                                  (Seance s) => s.eleveId == enfant.id,
                                )
                                .toList(),
                            affecte: liens.any(
                              (Affectation a) =>
                                  a.active && a.eleveId == enfant.id,
                            ),
                            maintenant: _maintenant,
                          ),
                        ),
                    if (seances.hasError ||
                        enfants.hasError ||
                        affectations.hasError) ...<Widget>[
                      Ecart.vSm,
                      Text(
                        t.tuteur.accueil.erreur,
                        // L'encre d'alerte, jamais la paire : `surfaceAlert`
                        // ecrit en blanc, illisible sur la page.
                        style: palette.textOnLightAlert.applyTo(
                          textes.bodySmall ?? const TextStyle(),
                        ),
                      ),
                    ],
                    Ecart.vXl,
                    const _BlocAppareils(),
                    Ecart.vMd,
                    const _BlocReglages(),
                    if (foyer.isNotEmpty) ...<Widget>[
                      Ecart.vXl,
                      _BlocAcces(enfants: foyer),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une ligne par enfant, dans l'un de ses cinq etats.
class _LigneEnfant extends StatelessWidget {
  const _LigneEnfant({
    required this.enfant,
    required this.seances,
    required this.affecte,
    required this.maintenant,
  });

  final EleveDuFoyer enfant;
  final List<Seance> seances;
  final bool affecte;
  final DateTime maintenant;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    final Seance? prochain = prochainCours(seances, maintenant);
    final Seance? annulee = seanceAnnuleeDuJour(seances, maintenant);
    final EtatEnfant etat = etatEnfant(
      prochain: prochain,
      annulee: annulee,
      affecte: affecte,
      maintenant: maintenant,
    );

    // Une paire dit sur quoi elle s'ecrit : la surface et l'encre changent
    // ensemble, et chaque style la traverse par `applyTo`. Un style du theme
    // pose tel quel sur la surface d'accent y ecrirait en noir.
    final bool enDirect = etat == EtatEnfant.enCours;
    final AppColorPair paire = enDirect
        ? palette.surfacePrimary
        : palette.surfaceBase;

    return BentoTile(
      surface: paire,
      avecBordure: !enDirect,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (enDirect) ...<Widget>[
                // La pastille verte de la fiche produit. Elle accompagne la
                // phrase, elle ne la remplace pas : une couleur seule ne porte
                // jamais un etat.
                Container(
                  width: AppSpacing.md,
                  height: AppSpacing.md,
                  decoration: palette.surfaceSuccess.decoration(
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                  ),
                ),
                Ecart.hSm,
              ],
              Expanded(
                child: Text(
                  enfant.prenom,
                  style: paire.applyTo(
                    textes.titleLarge ?? const TextStyle(),
                  ),
                ),
              ),
            ],
          ),
          Ecart.vSm,
          _EtatDeLEnfant(
            etat: etat,
            enfant: enfant,
            prochain: prochain,
            annulee: annulee,
            paire: paire,
            maintenant: maintenant,
          ),
          // Le bouton n'est rendu QUE pendant une seance en cours : partout
          // ailleurs, il n'y a pas de salle a rejoindre, et un bouton qui
          // echoue apres le geste coute plus cher qu'un bouton absent.
          if (enDirect && prochain != null) ...<Widget>[
            Ecart.vMd,
            ActionPrincipale(
              libelle: t.tuteur.accueil.assister,
              surface: palette.surfaceSuccess,
              onPress: () => GoRouter.of(context).go(
                Routes.salle,
                // Le billet passe par `extra`, jamais par l'URL (ADR-005).
                extra: BilletSalle(
                  sessionId: prochain.id,
                  emisA: DateTime.now(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ce que la ligne dit, selon l'etat.
class _EtatDeLEnfant extends StatelessWidget {
  const _EtatDeLEnfant({
    required this.etat,
    required this.enfant,
    required this.prochain,
    required this.annulee,
    required this.paire,
    required this.maintenant,
  });

  final EtatEnfant etat;
  final EleveDuFoyer enfant;
  final Seance? prochain;
  final Seance? annulee;
  final AppColorPair paire;
  final DateTime maintenant;

  @override
  Widget build(BuildContext context) {
    return switch (etat) {
      EtatEnfant.enCours => _lignes(context, <String>[
        t.tuteur.accueil.enCours(prenom: prochain!.enseignantPrenom),
        _ecoule(maintenant.difference(prochain!.debut)),
      ]),
      EtatEnfant.coursAujourdhui => _lignes(context, <String>[
        t.tuteur.accueil.aujourdhui(
          heure: _hhmm(prochain!.debut),
          prenom: prochain!.enseignantPrenom,
        ),
      ]),
      EtatEnfant.rienAujourdhui => _lignes(context, <String>[
        t.tuteur.accueil.rienAujourdhui,
        if (prochain == null)
          t.tuteur.accueil.aucunCoursPrevu
        else
          t.tuteur.accueil.unAutreJour(
            jour: t.disponibilites.joursLongs[prochain!.debut.weekday - 1],
            heure: _hhmm(prochain!.debut),
            prenom: prochain!.enseignantPrenom,
          ),
      ]),
      EtatEnfant.seanceAnnulee => _lignes(context, <String>[
        t.tuteur.accueil.annulee(heure: _hhmm(annulee!.debut)),
        // Le motif est le statut que la base a pose, dit en clair. Il n'existe
        // aucune colonne de motif libre : en inventer une ici afficherait une
        // phrase que personne n'a ecrite.
        annulee!.statut == StatutSeance.annuleeTard
            ? t.tuteur.accueil.motifAnnuleeTard
            : t.tuteur.accueil.motifAnnulee,
        // Et ce qui est propose a la place.
        if (prochain == null)
          t.tuteur.accueil.proposeAucun
        else
          t.tuteur.accueil.proposeApres(
            jour: t.disponibilites.joursLongs[prochain!.debut.weekday - 1],
            heure: _hhmm(prochain!.debut),
          ),
      ]),
      EtatEnfant.enRecherche => _EnRecherche(enfant: enfant, paire: paire),
    };
  }

  Widget _lignes(BuildContext context, List<String> phrases) {
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          phrases.first,
          style: paire.applyTo(textes.titleMedium ?? const TextStyle()),
        ),
        for (final String phrase in phrases.skip(1))
          Text(
            phrase,
            style: paire.applyTo(textes.bodySmall ?? const TextStyle()),
          ),
      ],
    );
  }
}

/// L'enfant attend un enseignant : depuis quand, et ce qui manque.
class _EnRecherche extends ConsumerWidget {
  const _EnRecherche({required this.enfant, required this.paire});

  final EleveDuFoyer enfant;
  final AppColorPair paire;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<List<Creneau>> creneaux = ref.watch(
      disponibilitesProvider(enfant.id),
    );
    final List<Creneau> poses = creneaux.value ?? const <Creneau>[];
    final DateTime? depuis = attendDepuis(poses);

    // Sans heure proposee, la recherche ne peut pas aboutir : ce n'est pas une
    // attente, c'est une etape qui manque. L'ecran le dit et donne le chemin.
    if (creneaux.hasValue && poses.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            t.tuteur.accueil.sansCreneau(prenom: enfant.prenom),
            style: paire.applyTo(textes.titleMedium ?? const TextStyle()),
          ),
          Text(
            t.tuteur.accueil.sansCreneauDetail(prenom: enfant.prenom),
            style: paire.applyTo(textes.bodySmall ?? const TextStyle()),
          ),
          Ecart.vSm,
          ActionPrincipale(
            libelle: t.tuteur.accueil.poserDesHeures,
            surface: AppPalette.of(context).surfaceBase,
            onPress: () =>
                GoRouter.of(context).go(Routes.tuteurDisponibilites),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          t.tuteur.accueil.enRecherche,
          style: paire.applyTo(textes.titleMedium ?? const TextStyle()),
        ),
        Text(
          depuis == null
              ? t.tuteur.accueil.enRechercheSansDate(prenom: enfant.prenom)
              : t.tuteur.accueil.enRechercheDepuis(date: _jour(depuis)),
          style: paire.applyTo(textes.bodySmall ?? const TextStyle()),
        ),
      ],
    );
  }
}

/// Bloc secondaire : les appareils du foyer.
class _BlocAppareils extends StatelessWidget {
  const _BlocAppareils();

  @override
  Widget build(BuildContext context) => _BlocSecondaire(
    icone: AppIcons.appareil,
    titre: t.tuteur.accueil.blocAppareils,
    detail: t.tuteur.accueil.blocAppareilsDetail,
    destination: Routes.tuteurFoyer,
  );
}

/// Bloc secondaire : les reglages par enfant, c'est-a-dire `TUT-05`.
class _BlocReglages extends StatelessWidget {
  const _BlocReglages();

  @override
  Widget build(BuildContext context) => _BlocSecondaire(
    icone: AppIcons.reglages,
    titre: t.tuteur.accueil.blocReglages,
    detail: t.tuteur.accueil.blocReglagesDetail,
    destination: Routes.tuteurReglages,
  );
}

/// Le gabarit commun des deux blocs secondaires.
class _BlocSecondaire extends StatelessWidget {
  const _BlocSecondaire({
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

    return BentoTile(
      avecBordure: true,
      libelleSemantique: titre,
      onPress: () => GoRouter.of(context).go(destination),
      child: Row(
        children: <Widget>[
          IconTheme(
            data: palette.textOnLightAccent.asIconTheme(
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
        ],
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
      avecBordure: true,
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
