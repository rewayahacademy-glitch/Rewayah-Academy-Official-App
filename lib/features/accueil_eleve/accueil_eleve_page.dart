import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/signaler_manque.dart';
import '../../core/capacites/port_acces_foyer.dart';
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
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/audio_label.dart';
import '../../core/widgets/bento_tile.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pastille_etat_seance.dart';
import '../../core/widgets/pays_enseignant.dart';
import '../../core/widgets/raccourci_tactile.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/skeleton.dart';
import '../acces_finance/acces_finance.dart';

/// Ce que le bloc principal de `ELV-02` annonce.
///
/// Les six etats sont ceux que la fiche produit tabule, dans son ordre : cours
/// dans plus d'une heure, cours dans moins de cinq minutes, cours en direct,
/// aucun cours aujourd'hui, seance annulee, hors ligne
/// (`docs/archive/2026-09-pre-remise-a-plat/produit/parcours-utilisateurs.md`, fiche `ELV-02`).
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
  /// L'ecran reste identique : le bloc « Rejoindre » dit l'attente de
  /// l'entree a l'appui (jamais grise, BOUTONS-GRISES-1) et gagne le
  /// pictogramme d'attente.
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
/// le produit (`docs/archive/2026-09-pre-remise-a-plat/architecture/etape-4-dashboards.md` section 5). Le premier
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
    final AsyncValue<List<Seance>> seances = ref.watch(seancesProvider);
    // Lu par `value`, jamais par le type d'execution de l'AsyncValue : Riverpod
    // relance un provider en echec et repasse par AsyncLoading. Tant que la
    // reponse manque, l'appareil est repute en ligne.
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;

    // DASH-ELV-ERR-b (revue DASH-ELV-ERR-R, m1 et i1) : l'echec passe avant
    // le squelette. Pendant la relecture lancee par « Reessayer », Riverpod
    // garde l'erreur precedente (`hasError` reste vrai, `isLoading` monte) :
    // le message et le Coran restent a l'ecran, seul le bouton dit qu'il
    // travaille.
    final bool echec = seances.hasError && !seances.hasValue;

    if (!echec && !seances.hasValue && seances.isLoading) {
      return const PageShell(child: Skeleton.liste(lignes: 2));
    }

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

    // L'acces de l'eleve connecte (FI-9a) : seances ouvertes, essai ou
    // fermees, jamais une cause ni un montant (guide §1.7, lecon 15). Lu
    // borne a sa session (`PortMonAcces`, FI-BR-08, revue FI-VAGUE-R R4-02) :
    // l'acces des freres et soeurs n'est jamais charge ici. Une lecture
    // absente ou en echec ne change rien a l'ecran (port neutre en
    // production) : Rejoindre ne disparait que sur un « ferme » explicite,
    // et jamais selon un solde, que ce port ne porte pas. L'enfant ne voit
    // que l'etat « ferme », jamais « Essai : n/2 » ni « Accès actif » (FI-Q12
    // (b), decide par delegation le 05/10 ; revue FI-VAGUE-R R4-03).
    final AsyncValue<AccesBeneficiaire?>? acces = prochain == null
        ? null
        : ref.watch(accesAppelantProvider);
    final bool accesFerme =
        ouvertureSeances(acces?.value) == OuvertureSeances.fermees;
    // Tant que l'acces se lit, Rejoindre reste present sans entrer (revue
    // FI-9a) : un bouton actif qui disparaitrait ensuite serait une promesse
    // retiree.
    final bool accesEnLecture = acces != null && accesEnAttente(acces);

    // `PageShell` porte le fond creme, la gouttiere du gabarit courant, la
    // colonne centree et bornee a 1200 (« centre et borne, on n'ajoute rien »,
    // `docs/archive/2026-09-pre-remise-a-plat/design/05-regles-responsive.md` section 3) et le bandeau hors ligne.
    // L'ecran ne rend plus que ses deux blocs.
    final bool enChargement =
        !echec && seances.isLoading && seances.value == null;

    return PageShell(
      child: enChargement
          ? const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Skeleton.tuileBento(hauteur: 160),
                Ecart.vXl,
                Skeleton.tuileBento(hauteur: 156),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // DASH-ELV-ERR (DASH_STRATEGIE D10, D11) : une lecture en
                // echec n'est jamais « pas de cours aujourd'hui ». Le bloc dit
                // que les cours manquent et propose de relire ; le Coran, lu
                // ailleurs, reste en place. Une erreur apres une valeur deja
                // lue garde cette valeur (DASH-ELV-ERR-b, m3) : l'eleve voit
                // encore son prochain cours plutot qu'un message. Hors ligne,
                // le bloc dit la cause par sa nature (K-59, m2).
                if (accesFerme) ...<Widget>[
                  BandeauAccesFerme(acces: acces?.value),
                  Ecart.vLg,
                ],
                if (echec)
                  EtatSysteme(
                    key: const ValueKey<String>('accueil-eleve-erreur'),
                    nature: horsLigne
                        ? NatureEtat.horsLigne
                        : NatureEtat.echecServeur,
                    // Hors ligne se dit une fois (EA-HL-DOUBLE-1d) : le
                    // « wifi barre » est celui du bandeau de `PageShell` ;
                    // sous lui, le bloc prend l'attente (sablier).
                    icone: horsLigne ? AppIcons.attente : null,
                    // Le titre commun hors ligne vouvoie ; l'accueil eleve
                    // tutoie.
                    titre: horsLigne
                        ? t.eleve.accueil.erreurCoursHorsLigneTitre
                        : null,
                    phrase: t.eleve.accueil.erreurCours,
                    onAction: () => ref.invalidate(seancesProvider),
                    actionEnCours: seances.isLoading,
                  )
                else
                  _BlocPrincipal(
                    etat: etat,
                    prochain: prochain,
                    interruptions: interruptions,
                    maintenant: _maintenant,
                    accesFerme: accesFerme,
                    accesEnLecture: accesEnLecture,
                  ),
                Ecart.vXl,
                const _BlocCoran(),
              ],
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
    this.accesFerme = false,
    this.accesEnLecture = false,
  });

  final EtatAccueilEleve etat;
  final Seance? prochain;
  final List<InterruptionPriere> interruptions;
  final DateTime maintenant;

  /// Seances fermees (FI-9a) : Rejoindre n'est pas rendu.
  final bool accesFerme;

  /// L'acces se lit encore : Rejoindre dit d'attendre un instant.
  final bool accesEnLecture;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool imminent = etat == EtatAccueilEleve.coursImminent;
    final bool mouvementReduit = AppMouvement.mouvementReduit(context);

    // **Une seule zone pleine par ecran** (`docs/archive/2026-09-pre-remise-a-plat/design/01-systeme-visuel.md`
    // section 3) : le bloc imminent, et lui seul. Le cours en direct redevient
    // une carte normale avec sa pastille verte et son bouton d'entree en
    // `surfacePrimary`. Une paire dit sur quoi elle s'ecrit : les styles des
    // enfants la traversent par `applyTo`.
    final AppColorPair paire = imminent
        ? palette.surfacePrimary
        : palette.surfaceRaised;

    final Widget tuile = BentoTile(
      surface: imminent ? palette.surfacePrimary : null,
      // Sous mouvement reduit, la pulsation disparait et une bordure
      // `borderStrong` fixe porte a sa place l'information d'imminence
      // (`docs/archive/2026-09-pre-remise-a-plat/design/04-systeme-mouvement.md` section 5).
      contourFort: imminent && mouvementReduit,
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
          joignable: etat == EtatAccueilEleve.coursEnDirect && !accesEnLecture,
          accesFerme: accesFerme,
          accesEnLecture: accesEnLecture,
        ),
        EtatAccueilEleve.seanceAnnulee => _SansCoursAujourdhui(
          message: t.eleve.accueil.annulee,
          annulee: true,
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

    // La pulsation ne bat que si le mouvement est autorise : sinon, la bordure
    // fixe posee ci-dessus l'a deja remplacee.
    return imminent && !mouvementReduit
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
        AudioLabel(cle: ClesAudio.eleveAccueilProchainCours, surface: paire),
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
        // ENS-PAYS-1 : le pays de l'enseignant sous son prenom, rien s'il
        // n'est pas declare.
        PaysEnseignant(
          pays: seance.enseignantPays,
          style: paire.applyTo(textes.bodyMedium ?? const TextStyle()),
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
    this.accesFerme = false,
    this.accesEnLecture = false,
  });

  final Seance seance;
  final AppColorPair paire;
  final List<InterruptionPriere> interruptions;
  final bool joignable;

  /// Seances fermees (FI-9a) : une limite de droit, pas une panne. Le bouton
  /// est absent, jamais grise ; le bandeau au-dessus du bloc dit l'etat, sans
  /// cause (guide §1.7).
  final bool accesFerme;

  /// L'acces se lit encore (revue FI-9a) : le bouton est present sans entrer
  /// ([joignable] est alors faux), sans le message hors ligne, le temps que
  /// la lecture aboutisse.
  final bool accesEnLecture;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // La pastille verte de la fiche produit, portee par le composant
        // d'etat : une pastille pleine `surfaceSuccess` et son mot, jamais la
        // couleur seule (`docs/archive/2026-09-pre-remise-a-plat/design/01-systeme-visuel.md` section 8).
        const Align(
          alignment: AlignmentDirectional.centerStart,
          child: PastilleEtatSeance(etat: EtatPastilleSeance.enDirect),
        ),
        Ecart.vSm,
        AudioLabel(cle: ClesAudio.eleveAccueilCoursEnDirect, surface: paire),
        Ecart.vSm,
        Text(
          t.eleve.accueil.avec(prenom: seance.enseignantPrenom),
          style: paire.applyTo(textes.titleMedium ?? const TextStyle()),
        ),
        // ENS-PAYS-1 : le pays de l'enseignant sous son prenom, rien s'il
        // n'est pas declare.
        PaysEnseignant(
          pays: seance.enseignantPays,
          style: paire.applyTo(textes.bodyMedium ?? const TextStyle()),
        ),
        _Interruptions(interruptions: interruptions, paire: paire),
        if (!accesFerme) ...<Widget>[
          Ecart.vLg,
          // Hors ligne, le bouton reste **present**, contrairement a la regle
          // du bouton absent qui vaut pour une limite de droit. Ce n'est pas une
          // limite, c'est une panne passagere : un bouton disparu ferait croire
          // a l'enfant que son cours n'existe plus, alors qu'il attend le
          // reseau.
          //
          // BOUTONS-GRISES-1 : present, mais jamais grise. Tant que l'entree
          // ne peut pas aboutir, l'appui dit pourquoi (annonce au lecteur
          // d'ecran) au lieu de rester sans reponse.
          _Rejoindre(
            joignable: joignable,
            accesEnLecture: accesEnLecture,
            paire: paire,
            onRejoindre: () => GoRouter.of(context).go(
              Routes.salle,
              // Le billet passe par `extra`, jamais par l'URL (ADR-005).
              extra: BilletSalle(sessionId: seance.id, emisA: DateTime.now()),
            ),
          ),
          if (!joignable && !accesEnLecture) ...<Widget>[
            Ecart.vSm,
            Row(
              children: <Widget>[
                IconTheme(
                  data: IconThemeData(
                    color: paire.onBackground,
                    size: AppSpacing.xl,
                  ),
                  // Hors ligne se dit une fois (EA-HL-DOUBLE-1) : le « wifi
                  // barre » est celui du bandeau ; ici, l'attente de l'entree.
                  child: Icon(AppIcons.attente.repos),
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
      ],
    );
  }
}

/// « Rejoindre » du cours en direct, jamais grise (BOUTONS-GRISES-1).
///
/// Joignable, l'appui entre dans la salle. Sinon, il dit pourquoi : l'acces
/// se lit encore (phrase sous le bouton, annoncee), ou l'entree attend le
/// reseau (la phrase deja posee sous le bouton est annoncee).
class _Rejoindre extends StatefulWidget {
  const _Rejoindre({
    required this.joignable,
    required this.accesEnLecture,
    required this.paire,
    required this.onRejoindre,
  });

  final bool joignable;
  final bool accesEnLecture;
  final AppColorPair paire;
  final VoidCallback onRejoindre;

  @override
  State<_Rejoindre> createState() => _RejoindreEtat();
}

class _RejoindreEtat extends State<_Rejoindre> {
  bool _attenteDite = false;

  void _appui() {
    if (widget.joignable) {
      widget.onRejoindre();
      return;
    }
    if (widget.accesEnLecture) {
      setState(() => _attenteDite = true);
    }
    signalerManque(
      context,
      widget.accesEnLecture
          ? t.eleve.accueil.entreeSePrepare
          : t.eleve.accueil.horsLigneDetail,
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ActionPrincipale(libelle: t.eleve.accueil.rejoindre, onPress: _appui),
        if (_attenteDite &&
            widget.accesEnLecture &&
            !widget.joignable) ...<Widget>[
          Ecart.vSm,
          Semantics(
            liveRegion: true,
            child: Text(
              t.eleve.accueil.entreeSePrepare,
              style: widget.paire.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
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
    this.annulee = false,
  });

  final String message;

  /// Vrai quand le message dit une seance annulee : la pastille « Annulee »
  /// ouvre le bloc (ANNUL-VIS-1), le mot ne reste pas seul dans le texte.
  final bool annulee;
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
        if (annulee) ...<Widget>[
          const Align(
            child: PastilleEtatSeance(etat: EtatPastilleSeance.annulee),
          ),
          Ecart.vSm,
        ],
        _etatVide(cours, jours),
        _Interruptions(interruptions: interruptions, paire: paire),
      ],
    );
  }

  Widget _etatVide(Seance? cours, int jours) {
    return EmptyState(
      message: message,
      // Registre **subi** : l'enfant ne peut rien y faire, son enseignant
      // prepare le prochain cours. Proposer un bouton ici mentirait sur ce que
      // l'enfant peut obtenir (`docs/archive/2026-09-pre-remise-a-plat/design/02-regles-ux.md` section 6).
      registre: RegistreVide.subi,
      // Un etat vide est une invitation, pas un constat. Le prochain cours peut
      // tomber le jour meme : une seance annulee le matin n'empeche pas celle
      // de l'apres-midi, et « demain » serait alors faux.
      invitation: switch ((cours, jours)) {
        (null, _) => t.eleve.accueil.aucunCoursDetail,
        (_, <= 0) => t.eleve.accueil.prochainAujourdhui,
        (_, 1) => t.eleve.accueil.prochainDemain,
        (_, _) => LibellesGroupe.insecable(
          t.eleve.accueil.prochainDansJours(jours: jours),
        ),
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
///
/// Deux etages, une action par zone (demande du directeur du 04/10/2026 :
/// « chaque element a part et lisible ») :
/// - en-tete sans texte : le livre au bord de debut, le haut-parleur au bord
///   de fin ;
/// - une [SettingRow] nue : titre, phrase et chevron, le lien qui ouvre le
///   Coran (`ELV-04`).
///
/// Le livre ouvre aussi le Coran : c'est un [RaccourciTactile] du lien,
/// touchable au doigt et a la souris, hors du clavier et du lecteur d'ecran
/// (un seul lien « Le Coran »). La tuile ne se presse pas : les cibles sont
/// soeurs, jamais l'une dans l'autre.
///
/// Le haut-parleur dit « Le Coran » a qui ne lit pas encore ; pour le lecteur
/// d'ecran, c'est le bouton « Ecouter : Le Coran », distinct du lien.
///
/// Sur grand ecran, le contenu garde la largeur de la colonne de l'etat vide
/// ([AppPage.largeurEtatVide]), calee sur le bord de debut de la carte comme
/// le contenu des autres tuiles Bento (a gauche en LTR, a droite en RTL) : le
/// haut-parleur reste pres du titre qu'il prononce au lieu de partir au bout
/// d'une carte de 1 100 points.
///
/// Les icones gardent leur taille quand le texte est agrandi (spec
/// CORAN-CARTE-1, point 6, acte) : elles vivent seules sur leur ligne et
/// grandissent avec l'Interface guidee (le mode enfant), jamais avec
/// l'echelle du texte. A 320 points et texte x2, le livre et le haut-parleur
/// gardent donc leur taille pendant que le titre et la phrase doublent ;
/// c'est voulu, ce n'est pas un oubli.
class _BlocCoran extends StatelessWidget {
  const _BlocCoran();

  @override
  Widget build(BuildContext context) {
    final AppMetriques metriques = AppMetriques.of(context);
    final AppPalette palette = AppPalette.of(context);
    final double tailleLivre = metriques.estEnfant
        ? AppSpacing.xxxl
        : AppSpacing.xxl;
    // L'en-tete a la hauteur de la cible tactile, le livre y est centre, avec
    // cet air au-dessus de lui. Le meme air est rendu sous la phrase (la
    // ligne nue pose son texte en bas de sa cible), pour que la carte
    // respire autant en haut qu'en bas.
    final double airEntete = (metriques.cibleTactile - tailleLivre) / 2;
    void ouvrir() => GoRouter.of(context).go(Routes.eleveCoran);

    return BentoTile(
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurEtatVide),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  RaccourciTactile(
                    onPress: ouvrir,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: 1,
                      child: IconTheme(
                        data: palette.inkAccent.asIconTheme(size: tailleLivre),
                        child: Icon(AppIcons.coran.repos),
                      ),
                    ),
                  ),
                  const Spacer(),
                  AudioLabel(
                    cle: ClesAudio.eleveAccueilCoran,
                    afficherTexte: false,
                    alignerEnFin: true,
                    libelleSemantique: t.eleve.accueil.coranEcouter,
                  ),
                ],
              ),
              Ecart.vSm,
              SettingRow(
                title: t.eleve.accueil.coran,
                description: t.eleve.accueil.coranDetail,
                nue: true,
                lien: true,
                onPress: ouvrir,
              ),
              SizedBox(height: airEntete),
            ],
          ),
        ),
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
    duration: AppMouvement.pulsation,
  );

  // Le battement se compose des deux seules courbes du produit : l'entree a
  // l'aller, la sortie au retour. Aucune troisieme courbe n'est necessaire, et
  // le systeme de mouvement n'en autorise pas
  // (`docs/archive/2026-09-pre-remise-a-plat/design/04-systeme-mouvement.md` section 2).
  late final Animation<double> _echelle = Tween<double>(begin: 1, end: 1.02)
      .animate(
        CurvedAnimation(
          parent: _controleur,
          curve: AppMouvement.entree,
          reverseCurve: AppMouvement.sortie,
        ),
      );

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
  final int minutes = LibellesGroupe.minutesAvant(reste);
  if (minutes <= 0) {
    return t.eleve.accueil.imminent;
  }
  // DUREE-INSECABLE-1 : la duree ne se scinde jamais sur deux lignes.
  if (minutes < Duration.minutesPerHour) {
    return LibellesGroupe.insecable(
      t.eleve.accueil.dansMinutes(minutes: '$minutes'),
    );
  }
  return LibellesGroupe.insecable(
    t.eleve.accueil.dansHeures(
      heures: '${minutes ~/ Duration.minutesPerHour}',
      minutes: (minutes % Duration.minutesPerHour).toString().padLeft(2, '0'),
    ),
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
