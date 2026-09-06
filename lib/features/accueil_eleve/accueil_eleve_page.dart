import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/cle_audio.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/planning/journee.dart';
import '../../core/planning/service_planning.dart';
import '../../core/priere/horaires_priere.dart';
import '../../core/priere/libelle_priere.dart';
import '../../core/priere/reglages_priere.dart';
import '../../core/priere/service_priere.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/billet_salle.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/audio_label.dart';
import '../../core/widgets/bento_tile.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/offline_banner.dart';

/// Ce que le bloc principal de `ELV-02` annonce.
///
/// Les six etats sont ceux que la fiche produit tabule, dans son ordre : cours
/// dans plus d'une heure, cours dans moins de cinq minutes, cours en direct,
/// aucun cours aujourd'hui, seance annulee, hors ligne
/// (`docs/produit/parcours-utilisateurs.md`, fiche `ELV-02`).
enum EtatAccueilEleve {
  /// Un cours plus tard dans la journee.
  ///
  /// La fiche nomme « plus d'une heure » et « moins de cinq minutes » : elle
  /// donne **un seul seuil**, celui de l'imminence. Cet etat couvre donc tout
  /// le reste de la journee, et non la seule tranche au-dela d'une heure.
  coursPlusTard,

  /// Le cours commence dans moins de [seuilImminence].
  coursImminent,

  /// Le cours a commence : c'est le seul etat qui porte « Rejoindre ».
  coursEnDirect,

  /// Rien aujourd'hui. Le prochain cours s'exprime en jours, jamais en date.
  aucunCoursAujourdhui,

  /// Le cours attendu n'aura pas lieu. Aucune explication technique.
  seanceAnnulee,

  /// Un cours en direct, sans reseau pour y entrer.
  ///
  /// L'ecran reste identique : seul le bloc « Rejoindre » devient inerte et
  /// gagne le pictogramme de reseau.
  horsLigne,
}

/// La cle du bloc qui pulse.
///
/// Le retour tactile de `Pressable` est lui aussi un `ScaleTransition` : sans
/// cette cle, un test ne distinguerait pas la pulsation du bloc imminent de
/// l'echelle d'un bouton ordinaire, et croirait mesurer l'une en mesurant
/// l'autre.
@visibleForTesting
const Key clePulsationImminente = Key('elv02-pulsation');

/// A partir de quand un cours est imminent.
///
/// Seul seuil de la fiche produit. Il vit ici et non dans l'ecran : c'est lui
/// qui fait basculer le bloc en violet, et un test doit pouvoir le nommer.
const Duration seuilImminence = Duration(minutes: 5);

/// L'etat du bloc principal, a un instant donne.
///
/// Fonction pure, comme `deciderRedirection` : les six etats se verifient sans
/// monter d'ecran. [prochain] vient de `prochainCours`, qui ecarte deja les
/// seances annulees, et [annulee] de `seanceAnnuleeDuJour`.
///
/// **Une annulation ne passe devant que si elle vient avant.** Un enfant dont le
/// cours de dix heures est annule et qui en a un autre a dix-sept heures doit
/// lire l'annulation le matin, puis son cours l'apres-midi : c'est toujours le
/// prochain rendez-vous, tenu ou non, qui occupe le bloc.
EtatAccueilEleve etatAccueilEleve({
  required Seance? prochain,
  required Seance? annulee,
  required DateTime maintenant,
  required bool horsLigne,
}) {
  if (annulee != null &&
      (prochain == null || annulee.debut.isBefore(prochain.debut))) {
    return EtatAccueilEleve.seanceAnnulee;
  }
  if (prochain == null) {
    return EtatAccueilEleve.aucunCoursAujourdhui;
  }
  if (prochain.enCoursA(maintenant)) {
    return horsLigne
        ? EtatAccueilEleve.horsLigne
        : EtatAccueilEleve.coursEnDirect;
  }
  if (!_memeJour(prochain.debut, maintenant)) {
    return EtatAccueilEleve.aucunCoursAujourdhui;
  }
  return prochain.avantDebut(maintenant) <= seuilImminence
      ? EtatAccueilEleve.coursImminent
      : EtatAccueilEleve.coursPlusTard;
}

/// `ELV-02` : l'accueil de l'eleve.
///
/// **Deux blocs, rien d'autre.** En mode enfant, aucune navigation : l'ecran est
/// le produit (`docs/architecture/etape-4-dashboards.md` section 5). Le premier
/// bloc dit ce qui vient, dans ses six etats ; le second, permanent, mene au
/// Coran.
///
/// Les interruptions de priere prevues pendant le cours du jour sont annoncees
/// **ici, avant le cours** et non decouvertes pendant (ADR-017). En mode enfant
/// par un pictogramme et un libelle parle, en mode standard en clair.
class AccueilElevePage extends ConsumerStatefulWidget {
  /// Cree l'accueil de l'eleve.
  const AccueilElevePage({super.key, this.horloge = DateTime.now});

  /// D'ou vient l'instant courant.
  ///
  /// Injectable pour la meme raison que le `maintenant` de
  /// `deciderRedirection` : les six etats de cet ecran se distinguent par des
  /// minutes, et un test qui lirait l'horloge de la machine changerait de
  /// resultat selon l'heure a laquelle la CI le lance. En production, c'est
  /// `DateTime.now`.
  final DateTime Function() horloge;

  @override
  ConsumerState<AccueilElevePage> createState() => _AccueilElevePageEtat();
}

class _AccueilElevePageEtat extends ConsumerState<AccueilElevePage> {
  Timer? _minuteur;
  late DateTime _maintenant = widget.horloge();

  @override
  void initState() {
    super.initState();
    // Le compte a rebours se lit en minutes, comme celui de `ENS-02` : le
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

    final AsyncValue<List<Seance>> seances = ref.watch(seancesProvider);
    // Lu par `value`, jamais par le type d'execution de l'AsyncValue : Riverpod
    // relance un provider en echec et repasse par AsyncLoading. Tant que la
    // reponse manque, l'appareil est repute en ligne.
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;

    final List<Seance> toutes = seances.value ?? const <Seance>[];
    final Seance? prochain = prochainCours(toutes, _maintenant);
    final Seance? annulee = seanceAnnuleeDuJour(toutes, _maintenant);
    final EtatAccueilEleve etat = etatAccueilEleve(
      prochain: prochain,
      annulee: annulee,
      maintenant: _maintenant,
      horsLigne: horsLigne,
    );

    // Les reglages de l'enseignant de ce cours, jamais ceux d'un autre : c'est
    // la meme ligne que son `ENS-02` lit, donc les deux ecrans annoncent la
    // meme minute (invariant I8).
    final AsyncValue<ReglagesPriere?> reglages = prochain == null
        ? const AsyncValue<ReglagesPriere?>.data(null)
        : ref.watch(reglagesPriereProvider(prochain.enseignantId));

    // **Toujours annoncees, sans condition d'etat.** Une regle qui n'annoncerait
    // les interruptions que le jour du cours se lirait bien et se verifierait
    // mal : l'enfant qui ouvre son ecran la veille apprendrait la pause le
    // lendemain, ce qui est exactement la surprise que l'ADR-017 refuse.
    final List<InterruptionPriere> interruptions = prochain == null
        ? const <InterruptionPriere>[]
        : interruptionsDe(prochain, reglages.value);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const OfflineBanner(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(metriques.marge),
                children: <Widget>[
                  _BlocPrincipal(
                    etat: etat,
                    prochain: prochain,
                    interruptions: interruptions,
                    maintenant: _maintenant,
                  ),
                  Ecart.vXl,
                  const _BlocCoran(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Le premier des deux blocs, dans l'un de ses six etats.
class _BlocPrincipal extends StatelessWidget {
  const _BlocPrincipal({
    required this.etat,
    required this.prochain,
    required this.interruptions,
    required this.maintenant,
  });

  final EtatAccueilEleve etat;
  final Seance? prochain;
  final List<InterruptionPriere> interruptions;
  final DateTime maintenant;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    // Une paire dit sur quoi elle s'ecrit : la surface et l'encre changent
    // ensemble, et chaque style la traverse par `applyTo`. Un style du theme
    // pose tel quel sur la surface d'accent y ecrirait en noir.
    final bool accentue = switch (etat) {
      EtatAccueilEleve.coursImminent ||
      EtatAccueilEleve.coursEnDirect ||
      EtatAccueilEleve.horsLigne => true,
      EtatAccueilEleve.coursPlusTard ||
      EtatAccueilEleve.aucunCoursAujourdhui ||
      EtatAccueilEleve.seanceAnnulee => false,
    };
    final AppColorPair paire = accentue
        ? palette.surfacePrimary
        : palette.surfaceBase;

    final Widget tuile = BentoTile(
      surface: paire,
      avecBordure: !accentue,
      child: switch (etat) {
        EtatAccueilEleve.coursPlusTard ||
        EtatAccueilEleve.coursImminent => _CoursAVenir(
          seance: prochain!,
          paire: paire,
          interruptions: interruptions,
          maintenant: maintenant,
        ),
        EtatAccueilEleve.coursEnDirect ||
        EtatAccueilEleve.horsLigne => _CoursEnDirect(
          seance: prochain!,
          paire: paire,
          interruptions: interruptions,
          joignable: etat == EtatAccueilEleve.coursEnDirect,
        ),
        EtatAccueilEleve.seanceAnnulee => _SansCoursAujourdhui(
          message: t.eleve.accueil.annulee,
          prochain: prochain,
          interruptions: interruptions,
          paire: paire,
          maintenant: maintenant,
        ),
        EtatAccueilEleve.aucunCoursAujourdhui => _SansCoursAujourdhui(
          message: t.eleve.accueil.aucunCours,
          prochain: prochain,
          interruptions: interruptions,
          paire: paire,
          maintenant: maintenant,
        ),
      },
    );

    return etat == EtatAccueilEleve.coursImminent
        ? _Pulsation(key: clePulsationImminente, child: tuile)
        : tuile;
  }
}

/// Le cours du jour, pas encore commence.
class _CoursAVenir extends StatelessWidget {
  const _CoursAVenir({
    required this.seance,
    required this.paire,
    required this.interruptions,
    required this.maintenant,
  });

  final Seance seance;
  final AppColorPair paire;
  final List<InterruptionPriere> interruptions;
  final DateTime maintenant;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final Duration reste = seance.avantDebut(maintenant);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Le haut-parleur lit la phrase : un enfant de six ans comprend cet
        // ecran sans savoir lire.
        AudioLabel(
          cle: ClesAudio.eleveAccueilProchainCours,
          surface: paire,
        ),
        Ecart.vMd,
        Text(
          _compteARebours(reste),
          style: paire.applyTo(textes.displayMedium ?? const TextStyle()),
        ),
        Ecart.vSm,
        // Le prenom de l'enseignant, jamais son nom de famille (ADR-008).
        Text(
          t.eleve.accueil.avec(prenom: seance.enseignantPrenom),
          style: paire.applyTo(textes.titleMedium ?? const TextStyle()),
        ),
        _Interruptions(interruptions: interruptions, paire: paire),
      ],
    );
  }
}

/// Le cours commence, avec ou sans reseau pour y entrer.
class _CoursEnDirect extends StatelessWidget {
  const _CoursEnDirect({
    required this.seance,
    required this.paire,
    required this.interruptions,
    required this.joignable,
  });

  final Seance seance;
  final AppColorPair paire;
  final List<InterruptionPriere> interruptions;
  final bool joignable;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            // La pastille verte de la fiche produit. Elle accompagne la phrase,
            // elle ne la remplace pas : une couleur seule ne porte jamais un
            // etat.
            Container(
              width: AppSpacing.md,
              height: AppSpacing.md,
              decoration: palette.surfaceSuccess.decoration(
                borderRadius: BorderRadius.circular(AppSpacing.md),
              ),
            ),
            Ecart.hSm,
            Flexible(
              child: AudioLabel(
                cle: ClesAudio.eleveAccueilCoursEnDirect,
                surface: paire,
              ),
            ),
          ],
        ),
        Ecart.vSm,
        Text(
          t.eleve.accueil.avec(prenom: seance.enseignantPrenom),
          style: paire.applyTo(textes.titleMedium ?? const TextStyle()),
        ),
        _Interruptions(interruptions: interruptions, paire: paire),
        Ecart.vLg,
        // Hors ligne, le bouton reste **present et inerte**, contrairement a la
        // regle du bouton absent qui vaut pour une limite de droit. Ce n'est pas
        // une limite, c'est une panne passagere : un bouton disparu ferait
        // croire a l'enfant que son cours n'existe plus, alors qu'il attend le
        // reseau. `ActionPrincipale` signale l'inertie en changeant de PAIRE, et
        // non par de la transparence, qui ferait tomber son texte sous le seuil.
        ActionPrincipale(
          libelle: t.eleve.accueil.rejoindre,
          surface: palette.surfaceSuccess,
          onPress: joignable
              ? () => GoRouter.of(context).go(
                  Routes.salle,
                  // Le billet passe par `extra`, jamais par l'URL (ADR-005).
                  extra: BilletSalle(
                    sessionId: seance.id,
                    emisA: DateTime.now(),
                  ),
                )
              : null,
        ),
        if (!joignable) ...<Widget>[
          Ecart.vSm,
          Row(
            children: <Widget>[
              IconTheme(
                data: IconThemeData(
                  color: paire.onBackground,
                  size: AppSpacing.xl,
                ),
                child: Icon(AppIcons.horsLigne.repos),
              ),
              Ecart.hSm,
              Flexible(
                child: Text(
                  t.eleve.accueil.horsLigne,
                  style: paire.applyTo(
                    textes.titleMedium ?? const TextStyle(),
                  ),
                ),
              ),
            ],
          ),
          Ecart.vXs,
          Text(
            t.eleve.accueil.horsLigneDetail,
            style: paire.applyTo(textes.bodyMedium ?? const TextStyle()),
          ),
        ],
      ],
    );
  }
}

/// Rien a attendre aujourd'hui, que la seance ait ete annulee ou qu'il n'y en
/// ait jamais eu.
///
/// Les deux etats partagent leur forme : une illustration neutre, un message
/// court, et **le prochain cours exprime en jours**. Aucune explication
/// technique, pas de statut, pas de motif : l'enfant a besoin de savoir quand
/// il revoit son enseignant, pas pourquoi la base a change une ligne.
class _SansCoursAujourdhui extends StatelessWidget {
  const _SansCoursAujourdhui({
    required this.message,
    required this.prochain,
    required this.interruptions,
    required this.paire,
    required this.maintenant,
  });

  final String message;
  final Seance? prochain;
  final List<InterruptionPriere> interruptions;
  final AppColorPair paire;
  final DateTime maintenant;

  @override
  Widget build(BuildContext context) {
    final Seance? cours = prochain;
    final int jours = cours == null
        ? 0
        : joursCivilsEntre(maintenant, cours.debut);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _etatVide(cours, jours),
        _Interruptions(interruptions: interruptions, paire: paire),
      ],
    );
  }

  Widget _etatVide(Seance? cours, int jours) {
    return EmptyState(
      message: message,
      // Un etat vide est une invitation, pas un constat. Le prochain cours peut
      // tomber le jour meme : une seance annulee le matin n'empeche pas celle
      // de l'apres-midi, et « demain » serait alors faux.
      invitation: switch ((cours, jours)) {
        (null, _) => t.eleve.accueil.aucunCoursDetail,
        (_, <= 0) => t.eleve.accueil.prochainAujourdhui,
        (_, 1) => t.eleve.accueil.prochainDemain,
        (_, _) => t.eleve.accueil.prochainDansJours(jours: '$jours'),
      },
    );
  }
}

/// Les interruptions de priere du cours annonce.
class _Interruptions extends StatelessWidget {
  const _Interruptions({required this.interruptions, required this.paire});

  final List<InterruptionPriere> interruptions;
  final AppColorPair paire;

  @override
  Widget build(BuildContext context) {
    if (interruptions.isEmpty) {
      return const SizedBox.shrink();
    }

    final AppMetriques metriques = AppMetriques.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Ecart.vMd,
        Row(
          children: <Widget>[
            IconTheme(
              data: IconThemeData(
                color: paire.onBackground,
                size: metriques.estEnfant ? AppSpacing.xxxl : AppSpacing.xxl,
              ),
              child: Icon(AppIcons.priere.repos),
            ),
            Ecart.hSm,
            // En mode enfant, le pictogramme et le libelle parle suffisent : ni
            // le nom de la priere ni son heure ne se lisent a six ans. En mode
            // standard, l'annonce est en clair, priere par priere.
            Flexible(
              child: AudioLabel(
                cle: ClesAudio.eleveAccueilPausePriere,
                surface: paire,
              ),
            ),
          ],
        ),
        if (!metriques.estEnfant)
          for (final InterruptionPriere interruption in interruptions)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                t.eleve.accueil.pausePriereDetail(
                  priere: libellePriere(interruption.priere),
                  heure: _hhmm(interruption.debut),
                ),
                style: paire.applyTo(textes.bodyMedium ?? const TextStyle()),
              ),
            ),
      ],
    );
  }
}

/// Le second bloc, permanent : le Coran.
class _BlocCoran extends StatelessWidget {
  const _BlocCoran();

  @override
  Widget build(BuildContext context) {
    final AppMetriques metriques = AppMetriques.of(context);
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return BentoTile(
      avecBordure: true,
      libelleSemantique: t.eleve.accueil.coran,
      onPress: () => GoRouter.of(context).go(Routes.eleveCoran),
      child: Row(
        children: <Widget>[
          IconTheme(
            data: palette.textOnLightAccent.asIconTheme(
              size: metriques.estEnfant ? AppSpacing.xxxl : AppSpacing.xxl,
            ),
            child: Icon(AppIcons.coran.repos),
          ),
          Ecart.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const AudioLabel(cle: ClesAudio.eleveAccueilCoran),
                Text(t.eleve.accueil.coranDetail, style: textes.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// La pulsation douce du bloc imminent.
///
/// Elle joue sur l'**echelle**, jamais sur l'opacite : une opacite qui varie
/// ferait passer tout le sous-arbre sous le seuil de contraste a chaque
/// battement, defaut deja paye a l'etape 3.
///
/// Elle s'arrete quand le systeme demande de reduire les animations, ce qui
/// donne aussi aux tests une fenetre stable.
class _Pulsation extends StatefulWidget {
  const _Pulsation({required this.child, super.key});

  final Widget child;

  @override
  State<_Pulsation> createState() => _PulsationEtat();
}

class _PulsationEtat extends State<_Pulsation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controleur = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  late final Animation<double> _echelle = Tween<double>(begin: 1, end: 1.02)
      .animate(CurvedAnimation(parent: _controleur, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduite = MediaQuery.disableAnimationsOf(context);
    if (reduite && _controleur.isAnimating) {
      _controleur.stop();
      _controleur.value = 0;
    } else if (!reduite && !_controleur.isAnimating) {
      _controleur.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _echelle, child: widget.child);
}

/// Le temps restant avant le debut, dit a un enfant.
///
/// Meme forme que le minuteur de `ENS-02`, avec les libelles de l'eleve : les
/// deux ecrans ne s'adressent pas a la meme personne, et « Dans 25 min » tutoye
/// ici ce qu'il vouvoie la-bas.
String _compteARebours(Duration reste) {
  final int minutes = reste.inMinutes;
  if (minutes <= 0) {
    return t.eleve.accueil.imminent;
  }
  if (minutes < Duration.minutesPerHour) {
    return t.eleve.accueil.dansMinutes(minutes: '$minutes');
  }
  return t.eleve.accueil.dansHeures(
    heures: '${minutes ~/ Duration.minutesPerHour}',
    minutes: (minutes % Duration.minutesPerHour).toString().padLeft(2, '0'),
  );
}

/// Le nombre de jours civils entre deux instants.
///
/// **Compte des dates, pas des durees.** Deux fois par an, un jour civil local
/// ne dure pas vingt-quatre heures : la nuit du passage a l'heure d'ete n'en
/// dure que vingt-trois, et un `inDays` pose sur deux minuits locaux rendrait
/// zero pour deux dates voisines, donc « demain » pour apres-demain.
///
/// Les deux dates civiles sont donc reposees **en UTC**, ou un jour dure
/// toujours vingt-quatre heures. Le calendrier est conserve, le fuseau est
/// neutralise : le compte est le meme a Paris, a Conakry et sur une machine de
/// CI. C'est la meme regle qu'a L5 pour `PrayerTimes.utc`, appliquee au
/// calendrier plutot qu'au soleil.
int joursCivilsEntre(DateTime debut, DateTime fin) => DateTime.utc(
  fin.year,
  fin.month,
  fin.day,
).difference(DateTime.utc(debut.year, debut.month, debut.day)).inDays;

/// L'heure locale d'un instant, sur deux chiffres.
String _hhmm(DateTime quand) =>
    '${quand.hour.toString().padLeft(2, '0')}:'
    '${quand.minute.toString().padLeft(2, '0')}';

/// Vrai quand deux instants tombent le meme jour civil local.
bool _memeJour(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
