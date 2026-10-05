/// `ENS-02` Aujourd'hui : la journee de l'enseignant (EN-2, planche 1).
///
/// **Quatre blocs, pas un de plus** (K-42) : la carte « Prochaine seance »,
/// « Ma journee », « A terminer » (trois au plus) et « Alertes utiles », cette
/// derniere rendue seulement quand elle n'est pas vide. Sur bureau, deux
/// colonnes a partir de 840 de largeur utile divisee par le facteur de texte :
/// a gauche ce qui vient (carte puis journee), a droite ce qui reste a faire.
/// L'ordre de lecture reste celui du mobile.
///
/// Retires d'EN-2 (00_MAQUETTES §2, planche 1) : « Eleves en attente » (ancien
/// matching, E1), « Cours individuel » (une seance est celle d'une Classe), la
/// cloche, la ligne « Bonjour... » et la pastille « Confirmee ».
///
/// **Cours, pauses et prieres sont des entrees de meme nature** dans « Ma
/// journee » : le gabarit `TimelineRow` est le meme pour les trois sortes.
///
/// **La carte suit E11** : une ligne de contexte calme, puis un seul bouton
/// qui evolue. Le modele `EmplacementEntree` (CL-4) est reutilise sans fork :
/// [emplacementJournee] ne fait que donner un bouton aux etats ou CL-4 pose une
/// simple ligne (avant la fenetre, apres la seance). Le pre-vol ne se fait plus
/// ici : il appartient a la preparation de la Classe (CL-4).
///
/// **Le cahier a terminer (K-45)** : tout espace qui regroupe des cahiers a
/// terminer porte le point de rappel ([PointRappel]), et une phrase qui aide
/// plutot qu'elle ne reproche.
///
/// Depuis le pivot du 19 septembre 2026, l'ecran lit
/// `seancesEnseignantProvider`, une entree par seance de Classe. Les heures
/// affichees sont celles de l'appareil ; aucune mention de fuseau n'est posee.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/controle/service_controle.dart' show graceApresFin;
import '../../core/domain/enums.dart';
import '../../core/enseignant/absence_remplacement.dart';
import '../../core/enseignant/cta_seance.dart';
import '../../core/enseignant/depot_cahiers.dart' show cahiersEnFileProvider;
import '../../core/enseignant/modeles_enseignant.dart';
import '../../core/enseignant/service_enseignant.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/planning/journee.dart';
import '../../core/planning/service_planning.dart';
import '../../core/presence/service_presence.dart';
import '../../core/priere/reglages_priere.dart';
import '../../core/priere/service_priere.dart';
import '../../core/regles/service_regles.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/billet_salle.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/tc_horloge/emplacement_entree.dart';
import '../../core/tc_horloge/session_clock_vm.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/video/pre_vol.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/grille_bento.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pastille_etat_seance.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/point_rappel.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/timeline_row.dart';
import '../tc_espace_groupe/carte_session.dart' show EmplacementEntreeVue;
import 'absence_remplacement_vue.dart';

/// Combien de cahiers « A terminer » montre au plus (planche 1).
const int maximumATerminer = 3;

/// Combien d'alertes individuelles de presence la page montre a la fois.
///
/// Deux lignes se lisent d'un coup d'oeil avant un cours ; au dela, un lien
/// dit combien d'autres attendent et ouvre [Routes.enseignantAlertes]
/// (DASH-ENS-LISTES : l'exception D6 b tombe, la page existe).
const int maximumAlertes = 2;

/// Combien de remplacements confirmes la Journee montre au plus (D6) ; au
/// dela, « Voir tout » ouvre [Routes.enseignantRemplacements].
const int maximumRemplacements = 3;

/// L'horloge de la page. En production, l'heure de l'appareil ; la
/// demonstration (`/demo/enseignant`) la fixe au lundi 28 septembre 2026.
final Provider<DateTime Function()> maintenantJourneeProvider =
    Provider<DateTime Function()>((Ref _) => DateTime.now);

/// `ENS-02`, la racine du role Enseignant.
class JourneePage extends ConsumerWidget {
  /// Cree l'ecran de la journee.
  const JourneePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime Function() lire = ref.watch(maintenantJourneeProvider);
    // Un seul `PageShell`, quel que soit l'etat : le titre ne disparait pas
    // pendant une charge, et le bandeau hors ligne du shell coiffe la page.
    return _Cadence(
      lire: lire,
      constructeur: (DateTime maintenant) => PageShell(
        titre: t.enseignant.journee.titre,
        sousTitre: dateLisible(maintenant),
        child: _Corps(maintenant: maintenant),
      ),
    );
  }
}

/// Le battement d'une minute, pose sur l'ecran et non dans un provider.
class _Cadence extends StatefulWidget {
  const _Cadence({required this.lire, required this.constructeur});

  final DateTime Function() lire;
  final Widget Function(DateTime maintenant) constructeur;

  @override
  State<_Cadence> createState() => _CadenceEtat();
}

class _CadenceEtat extends State<_Cadence> {
  Timer? _horloge;
  late DateTime _maintenant = widget.lire();

  @override
  void initState() {
    super.initState();
    // Le decompte se lit en minutes : le rafraichir a la seconde ferait
    // travailler l'ecran soixante fois pour rien.
    _horloge = Timer.periodic(
      const Duration(minutes: 1),
      (Timer _) => setState(() => _maintenant = widget.lire()),
    );
  }

  @override
  void dispose() {
    _horloge?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.constructeur(_maintenant);
}

/// Le corps : quatre lectures, puis la composition.
class _Corps extends ConsumerWidget {
  const _Corps({required this.maintenant});

  final DateTime maintenant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? monId = ref.watch(sessionProvider).profileId;
    if (monId == null) return const _Squelette();

    final AsyncValue<List<SeanceEnseignant>> seances = ref.watch(
      seancesEnseignantProvider,
    );
    final AsyncValue<ReglagesPriere?> reglages = ref.watch(
      reglagesPriereProvider(monId),
    );
    // La pause vient de `regle_effective()`, jamais d'une constante (ADR-017
    // section 2.4, invariant I10).
    final AsyncValue<int> pause = ref.watch(
      valeurRegleProvider((profilId: monId, cle: CleRegle.pauseEntreCours)),
    );
    final AsyncValue<List<CahierEnRetard>> retards = ref.watch(
      cahiersEnRetardProvider,
    );

    final bool premiereCharge =
        <AsyncValue<Object?>>[seances, reglages, pause, retards].any(
          (AsyncValue<Object?> lecture) =>
              !lecture.hasValue && lecture.isLoading,
        );
    if (premiereCharge) return const _Squelette();

    if (seances.hasError) {
      return EmptyState(
        message: t.enseignant.journee.erreur,
        icone: AppIcons.avertissement,
        libelleAction: t.commun.reessayer,
        onAction: () => ref.invalidate(seancesEnseignantProvider),
      );
    }

    final List<SeanceEnseignant> toutes =
        seances.value ?? const <SeanceEnseignant>[];
    // Le pont vers la journee partagee.
    final List<Seance> pont = toutes.map(_versSeance).toList(growable: false);
    final SeanceEnseignant? dominant = _seanceDominante(toutes, maintenant);
    final Seance? annulee = seanceAnnuleeDuJour(pont, maintenant);

    // Les bornes du jour civil local, par le calendrier et non par 24 heures.
    final DateTime debutJour = DateTime(
      maintenant.year,
      maintenant.month,
      maintenant.day,
    );
    final DateTime finJour = DateTime(
      maintenant.year,
      maintenant.month,
      maintenant.day + 1,
    );
    final List<EntreeJournee> journee = construireJournee(
      seances: pont,
      reglages: reglages.value,
      debut: debutJour,
      fin: finJour,
      // Une regle illisible ne se remplace pas par une valeur inventee.
      pauseMaximale: Duration(minutes: pause.value ?? 0),
    );

    final List<CahierEnRetard> aTerminer =
        retards.value ?? const <CahierEnRetard>[];

    // Les alertes utiles : ce qui change ce que l'enseignant fait aujourd'hui.
    // Toutes sont calculees ; la tuile en montre deux, la page les autres.
    final List<String> alertes =
        dominant != null && dominant.enCoursA(maintenant)
        ? alertesPresence(
            ref.watch(presenceSeanceProvider(dominant.id)).value ??
                const <PresenceParticipant>[],
          )
        : const <String>[];
    // LIB-ERR-1 : l'echec partiel dit ce qui manque, que les seances sont a
    // jour, et se relance d'un bouton.
    final bool partielle =
        reglages.hasError || pause.hasError || retards.hasError;

    // ENS-13B : les offres arrivent en Alerte utile ; une offre acceptee et
    // confirmee par le serveur devient la carte « Remplacement » (EN-8).
    final List<OffreRemplacement> confirmes = ref.watch(
      remplacementsConfirmesProvider,
    );
    final List<OffreRemplacement> offres = ref
        .watch(offresRemplacementProvider)
        .where(
          (OffreRemplacement o) =>
              !confirmes.any((OffreRemplacement c) => c.seanceId == o.seanceId),
        )
        .toList(growable: false);

    return _Composition(
      prochaine: _CarteProchaineSeance(
        // CTA-FIN-1 : la seance dont le bouton agit maintenant (salle ouverte,
        // cahier manquant, a venir, cahier depose), pas seulement la suivante.
        seance: seanceDeLaCarte(
          toutes,
          maintenant,
          fenetreAcces: seuilOuvertureSalle,
          graceApresFin: graceApresFin,
        ),
        maintenant: maintenant,
      ),
      // D6 : trois au plus, les plus proches d'abord ; au dela, « Voir
      // tout » sous la troisieme (DASH-ENS-LISTES).
      remplacements: _cartesRemplacements(trierRemplacements(confirmes)),
      maJournee: _MaJournee(
        journee: journee,
        prochain: dominant,
        maintenant: maintenant,
      ),
      aTerminer: aTerminer.isEmpty
          ? null
          : _ATerminer(
              cahiers: aTerminer,
              enFile:
                  ref.watch(cahiersEnFileProvider).value ?? const <String>{},
            ),
      alertes:
          alertes.isEmpty && offres.isEmpty && annulee == null && !partielle
          ? null
          : _AlertesUtiles(
              alertes: alertes.take(maximumAlertes).toList(growable: false),
              autres: alertes.length > maximumAlertes
                  ? alertes.length - maximumAlertes
                  : 0,
              offres: offres,
              coursAnnule: _retrouverParId(toutes, annulee),
              onReessayerPartiel: partielle
                  ? () {
                      ref
                        ..invalidate(reglagesPriereProvider(monId))
                        ..invalidate(
                          valeurRegleProvider((
                            profilId: monId,
                            cle: CleRegle.pauseEntreCours,
                          )),
                        )
                        ..invalidate(cahiersEnRetardProvider);
                    }
                  : null,
            ),
    );
  }
}

/// Toutes les absences et coupures du cours en direct, en phrases.
///
/// Une presence illisible (`null`) n'est pas une liste vide : « je ne sais
/// pas » ne s'annonce pas comme une absence (invariant J3) ; l'appelant
/// decide (la Journee se tait, la page des alertes dit l'echec). Seuls
/// `absente` et `deconnectee` deviennent une alerte.
List<String> alertesPresence(List<PresenceParticipant> lignes) => <String>[
  for (final PresenceParticipant ligne in lignes)
    if (!ligne.estEnseignant && ligne.etat == EtatPresence.absente)
      t.enseignant.journee.absenceDetectee(eleve: _nommer(ligne))
    else if (!ligne.estEnseignant && ligne.etat == EtatPresence.deconnectee)
      t.enseignant.journee.coupureDetectee(eleve: _nommer(ligne)),
];

/// La seance qui domine la journee : la prochaine (ou celle en cours), hors
/// annulees, retrouvee riche par son identifiant.
SeanceEnseignant? _seanceDominante(
  List<SeanceEnseignant> toutes,
  DateTime maintenant,
) {
  final Seance? relais = prochainCours(
    toutes.map(_versSeance).toList(growable: false),
    maintenant,
  );
  return _retrouverParId(toutes, relais);
}

/// La seance riche (Classe, groupe) qui porte le meme identifiant que
/// [relais], lue dans le pont vers la journee partagee. La carte du cours
/// annule en a besoin pour nommer sa Classe et y mener (SALLE-CORR-3).
SeanceEnseignant? _retrouverParId(
  List<SeanceEnseignant> toutes,
  Seance? relais,
) {
  if (relais == null) return null;
  for (final SeanceEnseignant seance in toutes) {
    if (seance.id == relais.id) return seance;
  }
  return null;
}

/// Les remplacements confirmes, les plus proches d'abord (D6).
List<OffreRemplacement> trierRemplacements(List<OffreRemplacement> offres) =>
    List<OffreRemplacement>.of(offres)..sort(
      (OffreRemplacement a, OffreRemplacement b) => a.debut.compareTo(b.debut),
    );

/// Les tuiles de remplacement de la Journee : [maximumRemplacements] au plus ;
/// au dela, la derniere porte « Voir tout » vers la liste entiere.
List<Widget> _cartesRemplacements(List<OffreRemplacement> tries) {
  final int montres = tries.length < maximumRemplacements
      ? tries.length
      : maximumRemplacements;
  return <Widget>[
    for (int i = 0; i < montres; i++)
      if (i == montres - 1 && tries.length > maximumRemplacements)
        _AvecVoirTousRemplacements(
          nombre: tries.length,
          child: CarteRemplacement(
            offre: tries[i],
            date: dateLisible(tries[i].debut),
          ),
        )
      else
        CarteRemplacement(offre: tries[i], date: dateLisible(tries[i].debut)),
  ];
}

/// La troisieme carte de remplacement, et sous elle le lien vers les autres.
class _AvecVoirTousRemplacements extends StatelessWidget {
  const _AvecVoirTousRemplacements({required this.nombre, required this.child});

  final int nombre;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      child,
      Ecart.vSm,
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: LienFleche(
          key: const ValueKey<String>('journee-remplacements-voir-tout'),
          libelle: t.tuteur.accueil.voirTout,
          // « Voir tout » seul ne dit pas quoi : le lecteur d'ecran entend
          // la liste et son nombre.
          libelleSemantique: t.enseignant.journee.voirTousRemplacements(
            nombre: '$nombre',
          ),
          alignerEnFin: true,
          onPress: () =>
              GoRouter.of(context).go(Routes.enseignantRemplacements),
        ),
      ),
    ],
  );
}

/// Le retour d'une liste de la Journee : la page precedente, ou la Journee
/// quand la liste a ete ouverte directement (rechargement, lien).
void _retourVersJournee(BuildContext context) {
  final GoRouter routeur = GoRouter.of(context);
  if (routeur.canPop()) {
    routeur.pop();
  } else {
    routeur.go(Routes.enseignantJournee);
  }
}

/// BENTO-2 : la grille Bento partagee, disposition de DASH_STRATEGIE.md §3.5.
///
/// Prochaine seance en grande tuile, une tuile large par remplacement
/// confirme, Ma journee haute (grande a trois colonnes et plus), A terminer en
/// grande tuile, Alertes utiles en large. Chaque tuile garde la hauteur de son
/// contenu (`hauteurContenu`) : la frise du jour n'est jamais bornee (D6 a).
/// Les colonnes suivent la largeur utile (`GrilleBento.colonnesPour`) : en
/// une colonne, les tuiles se suivent dans cet ordre (BENTO-1b, BENTO-1c).
class _Composition extends StatelessWidget {
  const _Composition({
    required this.prochaine,
    required this.maJournee,
    required this.aTerminer,
    required this.alertes,
    this.remplacements = const <Widget>[],
  });

  final Widget prochaine;
  final List<Widget> remplacements;
  final Widget maJournee;
  final Widget? aTerminer;
  final Widget? alertes;

  @override
  Widget build(BuildContext context) {
    final Widget? cahiers = aTerminer;
    final Widget? signaux = alertes;
    return GrilleBento(
      hauteurContenu: true,
      tuiles: <TuileBento>[
        TuileBento(etendue: EtendueBento.grande, child: prochaine),
        for (final Widget carte in remplacements)
          TuileBento(etendue: EtendueBento.large, child: carte),
        TuileBento(
          etendue: EtendueBento.haute,
          etendueLarge: EtendueBento.grande,
          child: maJournee,
        ),
        if (cahiers != null)
          TuileBento(etendue: EtendueBento.grande, child: cahiers),
        if (signaux != null)
          TuileBento(etendue: EtendueBento.large, child: signaux),
      ],
    );
  }
}

/// E11 : l'emplacement de la carte « Prochaine seance », depuis celui de CL-4.
///
/// **CTA-FIN-1 : le bouton ne se grise jamais, il change de sens** selon
/// [cta] (calcule par `ctaSeance`, `lib/core/enseignant/cta_seance.dart`) :
/// - avant l'heure : « Preparer la seance » ;
/// - pendant le creneau, et tant que la salle est ouverte : « Rejoindre la
///   salle » ;
/// - temps ecoule, cahier non depose : « Remplir le cahier de transmission »,
///   avec le rappel qu'il est obligatoire ;
/// - cahier depose : une ligne seule ; « Voir le cahier » est un lien discret
///   que la carte pose sous la ligne (K-56, un seul bouton plein) ;
/// - seance annulee ou absence declaree : « Voir la Classe ».
///
/// Ce que CL-4 propose en « Reessayer » (hors ligne, lecture) et la ligne de
/// preparation restent tels quels : sans information fiable, on ne propose pas
/// d'entrer.
EmplacementEntree emplacementJournee(
  EmplacementEntree base, {
  required String nomClasse,
  required EtatCtaSeance cta,
  EtatAbsence? absence,
}) {
  // ENS-13 : une absence declaree (hors « Demande annulee », ou l'enseignant
  // assure de nouveau la seance) ne laisse que « Voir la Classe » (E11, doc 04
  // §17.1 et §17.2).
  final bool absent = absence != null && absence != EtatAbsence.demandeAnnulee;
  if (base.reessayer || base.etat == EtatEntree.preparation) {
    return base;
  }
  // Le contexte calme au-dessus du bouton : la phrase d'etat de CL-4, qu'elle
  // etait une ligne ou deja un bouton.
  final String? contexte = base.estBouton ? base.detail : base.libelle;
  final EtatCtaSeance voulu = absent ? EtatCtaSeance.voirClasse : cta;
  final (String libelle, String lecteur, String? detail) = switch (voulu) {
    EtatCtaSeance.preparer => (
      t.enseignant.journee.preparerSeance,
      t.enseignant.journee.preparerSeanceLecteur(classe: deDevant(nomClasse)),
      contexte,
    ),
    EtatCtaSeance.rejoindre => (
      t.enseignant.journee.rejoindreSalle,
      t.enseignant.journee.rejoindreSalleLecteur(classe: nomClasse),
      contexte,
    ),
    EtatCtaSeance.remplirCahier => (
      t.enseignant.journee.remplirCahier,
      t.enseignant.journee.remplirCahierLecteur(classe: nomClasse),
      t.enseignant.journee.cahierObligatoire(classe: deDevant(nomClasse)),
    ),
    EtatCtaSeance.voirCahier => (
      t.enseignant.journee.voirCahier(classe: deDevant(nomClasse)),
      t.enseignant.journee.voirCahierLecteur(classe: nomClasse),
      null,
    ),
    EtatCtaSeance.voirClasse => (
      t.enseignant.journee.voirClasse,
      t.enseignant.journee.voirClasseLecteur(classe: nomClasse),
      contexte,
    ),
  };
  if (voulu == EtatCtaSeance.voirCahier) {
    // Une ligne seule : le lien « Voir le cahier » est rendu par la carte.
    return EmplacementEntree(
      role: base.role,
      etat: EtatEntree.terminee,
      forme: FormeEntree.ligne,
      libelle: t.classe.entree.terminee,
      libelleLecteur: lecteur,
      annonce: t.classe.entree.terminee,
      avisDst: base.avisDst,
    );
  }
  return EmplacementEntree(
    role: base.role,
    etat: voulu == EtatCtaSeance.remplirCahier
        ? EtatEntree.terminee
        : base.etat,
    forme: FormeEntree.bouton,
    libelle: libelle,
    libelleLecteur: lecteur,
    detail: detail,
    annonce: base.annonce,
    avisDst: base.avisDst,
  );
}

/// La carte « Prochaine seance » : peu de choses (E12), un seul emplacement
/// (E11), au style de la carte de seance CL-4.
class _CarteProchaineSeance extends ConsumerWidget {
  const _CarteProchaineSeance({required this.seance, required this.maintenant});

  final SeanceEnseignant? seance;
  final DateTime maintenant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final SeanceEnseignant? cours = seance;

    if (cours == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionHeader(titre: t.enseignant.journee.prochaineSeance),
          Ecart.vSm,
          AppCard(
            dominante: true,
            child: EmptyState(
              message: t.enseignant.journee.aucuneSeance,
              invitation: t.enseignant.journee.aucuneSeanceDetail,
              icone: AppIcons.cours,
              registre: RegistreVide.subi,
            ),
          ),
        ],
      );
    }

    final CtaSeance cta = ctaDeSeance(
      cours,
      maintenant,
      fenetreAcces: seuilOuvertureSalle,
      graceApresFin: graceApresFin,
    );
    final bool enCours = cta.enDirect;
    final bool terminee =
        cta.etat == EtatCtaSeance.remplirCahier ||
        cta.etat == EtatCtaSeance.voirCahier;
    final String nom = _nomClasse(cours.groupeLibelle);
    final DeclarationAbsence? declaration = ref.watch(
      declarationAbsenceProvider,
    );
    final EtatAbsence? absence = ref.watch(etatsAbsenceProvider)[cours.id];
    // Tant que la reponse est inconnue, l'appareil est repute en ligne.
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final SessionClockVM horloge = SessionClockVM.depuisFenetre(
      fenetre: FenetreSeance(
        debutUtc: cours.debut.toUtc(),
        finPrevueUtc: cours.fin.toUtc(),
        // Le seuil de la base, jamais redeclare ici (ADR-005).
        fenetreAcces: seuilOuvertureSalle,
        // La borne unique de core (ADR-005), jamais redeclaree ici (E6).
        graceApresFin: graceApresFin,
      ),
      maintenantServeurUtc: maintenant.toUtc(),
      horlogeUtilisateur: HorlogeAffichee(
        fuseauIana: '',
        libelleVille: '',
        heureLocaleRendue: _hhmm(cours.debut),
        dateLocaleRendue: dateLisible(cours.debut),
      ),
      sessionId: cours.id,
      seanceOuverte: salleOuverteSelon(cours.statut),
    );
    // Une seance annulee (par le serveur, ou parce que l'absence declaree n'a
    // trouve aucun remplacant) : surface enfoncee, horaire barre, et la ligne
    // qui dit pourquoi (ANNUL-VIS-1).
    final bool seanceAnnulee =
        absence == EtatAbsence.seanceAnnulee ||
        cours.statut == StatutSeance.annulee;
    final EmplacementEntree emplacement = emplacementJournee(
      EmplacementEntree.pour(
        role: RoleEntree.enseignant,
        horloge: horloge,
        nomClasse: nom,
        annulee: cours.statut == StatutSeance.annulee,
        horsLigne: horsLigne,
      ),
      nomClasse: nom,
      cta: cta.etat,
      absence: absence,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(
          titre: enCours
              ? t.enseignant.journee.coursEnCours
              : terminee
              ? t.enseignant.journee.derniereSeance
              : t.enseignant.journee.prochaineSeance,
        ),
        Ecart.vSm,
        AppCard(
          dominante: true,
          surface: seanceAnnulee
              ? surfaceCarteSeance(palette, annulee: true)
              : null,
          // La pastille passe sous le nom quand elle ne tient pas a cote : a
          // 320 px et en texte x2, rien ne deborde (K-54).
          entete: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  nom,
                  key: const ValueKey<String>('journee-carte-classe'),
                  style: textes.titleLarge ?? const TextStyle(),
                ),
              ),
              if (enCours)
                const PastilleEtatSeance(etat: EtatPastilleSeance.enDirect),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // ENS-13 : l'etat de l'absence, sous le nom (style K-42, §5).
              if (absence != null) ...<Widget>[
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: PastilleAbsence(etat: absence),
                ),
                Ecart.vMd,
              ],
              if (seanceAnnulee) ...<Widget>[
                LigneRaisonSeance(
                  raison: absence == EtatAbsence.seanceAnnulee
                      ? t.etat.aucunRemplacantTrouve
                      : t.etat.motifNonCommunique,
                  suite: absence == EtatAbsence.seanceAnnulee
                      ? t.etat.seanceNonFacturee
                      : null,
                ),
                Ecart.vMd,
              ],
              // La date seulement si ce n'est pas aujourd'hui : l'en-tete de
              // la page la dit deja (un element en moins, K-42).
              if (!_memeJour(cours.debut, maintenant)) ...<Widget>[
                Text(
                  horloge.horlogeUtilisateur.dateLocaleRendue,
                  style: palette.inkMuted.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
                Ecart.vMd,
              ],
              LigneCleValeur(
                cle: t.enseignant.journee.heure,
                valeur: t.enseignant.journee.plage(
                  debut: _hhmm(cours.debut),
                  fin: _hhmm(cours.fin),
                ),
                chiffres: true,
                annulee: seanceAnnulee,
              ),
              Ecart.vSm,
              LigneCleValeur(
                cle: LibellesGroupe.dureeLibelle,
                valeur: LibellesGroupe.dureeSeule(
                  cours.fin.difference(cours.debut),
                ),
                chiffres: true,
              ),
              Ecart.vSm,
              LigneCleValeur(
                cle: t.enseignant.journee.eleves,
                valeur: _effectif(cours.nbParticipants),
                chiffres: true,
              ),
              // Le bouton se pose 16 sous le contenu qu'il confirme (R20).
              Ecart.vLg,
              EmplacementEntreeVue(
                emplacement: emplacement,
                onEntrer: () => _agir(context, ref, cours, emplacement),
                onReessayer: () => ref.invalidate(seancesEnseignantProvider),
              ),
              // CTA-FIN-1 : cahier depose, « Voir le cahier » est un lien
              // discret, jamais un bouton plein (K-56).
              if (cta.etat == EtatCtaSeance.voirCahier &&
                  !emplacement.reessayer &&
                  absence == null) ...<Widget>[
                Ecart.vSm,
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: LienFleche(
                    key: const ValueKey<String>('journee-voir-cahier'),
                    libelle: t.enseignant.journee.voirCahier(
                      classe: deDevant(nom),
                    ),
                    onPress: () => unawaited(
                      GoRouter.of(context)
                          .push<void>(Routes.cahierPour(cours.id)),
                    ),
                  ),
                ),
              ],
              // ENS-13 : l'absence s'ouvre depuis sa seance (E3), une fois,
              // avant la seance. Ensuite, l'etat rendu par le serveur reste
              // lisible sur la pastille (doc 04 §17.2).
              if (declaration != null &&
                  absence == null &&
                  !enCours &&
                  cours.statut == StatutSeance.planifiee &&
                  cours.debut.isAfter(maintenant)) ...<Widget>[
                Ecart.vSm,
                // Au bord de debut, a largeur naturelle (contrat B).
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: IntrinsicWidth(
                    child: ActionPrincipale(
                      key: const ValueKey<String>('journee-declarer-absence'),
                      libelle: t.enseignant.journee.absence.ouvrir,
                      niveau: NiveauAction.tertiaire,
                      pleineLargeur: false,
                      onPress: () async {
                        final EtatAbsence? etat = await ouvrirFeuilleAbsence(
                          context,
                          port: declaration,
                          seanceId: cours.id,
                          classe: nom,
                          debut: cours.debut,
                          fin: cours.fin,
                          date: dateLisible(cours.debut),
                        );
                        if (etat != null) {
                          ref
                              .read(etatsAbsenceProvider.notifier)
                              .retenir(cours.id, etat);
                        }
                      },
                    ),
                  ),
                ),
                // LIB-ABS-1 : la suite de l'absence, dite sous le bouton.
                Ecart.vXs,
                Text(
                  t.enseignant.journee.absence.ouvrirContexte,
                  key: const ValueKey<String>('journee-absence-contexte'),
                  style: palette.inkMuted.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Ou mene le bouton unique : le cahier, sinon la Classe (sa preparation).
  Future<void> _agir(
    BuildContext context,
    WidgetRef ref,
    SeanceEnseignant cours,
    EmplacementEntree emplacement,
  ) async {
    final GoRouter routeur = GoRouter.of(context);
    if (emplacement.libelle == t.enseignant.journee.remplirCahier) {
      await routeur.push<void>(Routes.cahierPour(cours.id));
      if (context.mounted) {
        ref.invalidate(cahiersEnRetardProvider);
        ref.invalidate(seancesEnseignantProvider);
      }
      return;
    }
    final String? idGroupe = cours.groupeId;
    if (idGroupe == null) {
      routeur.go(Routes.enseignantClasses);
      return;
    }
    if (emplacement.libelle == t.enseignant.journee.rejoindreSalle) {
      // « Rejoindre la salle » mene a la salle, par son pre-vol : meme chemin
      // que le bouton de la fiche de la Classe, un seul geste (CTA-FIN-1).
      routeur.go(
        Routes.salle,
        // Le billet passe par `extra`, jamais par l'URL (ADR-005).
        extra: BilletSalle(
          sessionId: cours.id,
          emisA: DateTime.now(),
          preparation: true,
          groupeId: idGroupe,
        ),
      );
      return;
    }
    // `push` : le retour de l'Espace Classe se referme sur Aujourd'hui (R1).
    await routeur.push<void>(Routes.groupePour(idGroupe));
  }
}

/// « Ma journee » : cours, pauses et prieres, du haut vers le bas.
class _MaJournee extends StatelessWidget {
  const _MaJournee({
    required this.journee,
    required this.prochain,
    required this.maintenant,
  });

  final List<EntreeJournee> journee;
  final SeanceEnseignant? prochain;
  final DateTime maintenant;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final List<EntreeJournee> cours = journee
        .where((EntreeJournee entree) => entree.sorte == SorteEntree.cours)
        .toList(growable: false);
    final bool finie =
        cours.isNotEmpty &&
        cours.every((EntreeJournee entree) => !maintenant.isBefore(entree.fin));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(titre: t.enseignant.journee.maJournee),
        Ecart.vSm,
        if (journee.isEmpty)
          _RienAujourdhui(prochain: prochain)
        else
          for (int i = 0; i < journee.length; i++) ...<Widget>[
            if (i > 0) Ecart.vMd,
            TimelineRow(entree: journee[i]),
          ],
        if (finie) ...<Widget>[
          Ecart.vMd,
          Text(
            cours.length == 1
                ? t.enseignant.journee.journeeTermineeUn
                : t.enseignant.journee.journeeTerminee(
                    nombre: '${cours.length}',
                  ),
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
      ],
    );
  }
}

/// « A terminer » : les cahiers non valides, trois au plus (K-45).
class _ATerminer extends ConsumerWidget {
  const _ATerminer({required this.cahiers, this.enFile = const <String>{}});

  final List<CahierEnRetard> cahiers;

  /// Les seances dont le cahier valide attend l'envoi (file locale).
  final Set<String> enFile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    // Doc 04 §11.4 et §33 n. 9 : du plus ancien au plus recent, trois au
    // plus ; au-dela, « Voir tout » ouvre la liste complete.
    final List<CahierEnRetard> tries = trierCahiersATerminer(cahiers);
    final Widget entete = Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: Semantics(
                header: true,
                child: Text(
                  t.enseignant.journee.aTerminer,
                  // Un titre de section : `titleLarge`, comme
                  // `SectionHeader` ; la page porte son titre d'ecran au
                  // rang `headline*` (HIER-1).
                  style: palette.surfaceCanvas.applyTo(
                    textes.titleLarge ?? const TextStyle(),
                  ),
                ),
              ),
            ),
            Ecart.hXs,
            PointRappel(
              key: const ValueKey<String>('journee-point-rappel'),
              libelle: t.enseignant.journee.rappelCahier,
            ),
          ],
        ),
        // LIB-CAHIER-1 : le caractere obligatoire se voit sur la carte.
        StatusPill(
          key: const ValueKey<String>('journee-cahier-obligatoire'),
          libelle: t.enseignant.cahier.obligatoire,
          ton: TonEtat.avertissement,
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Le titre au style de `SectionHeader`, le point colle a lui : dans
        // `SectionHeader`, qui occupe toute la ligne, il partirait au bout.
        // Titre et point forment UN enfant du `Wrap` (le point ne reste
        // jamais seul en tete de ligne) ; la pastille passe a la ligne au
        // lieu de serrer le titre (« À termi/ner », BENTO-2b).
        // BENTO-2c : « Voir tout » n'est plus dans une `Row` qui laissait au
        // titre ce qu'il restait (320 px, texte double : « termi/ner »,
        // « Obligatoi/re ») : un `OverflowBar` le met au bout de la ligne
        // quand tout tient, sous l'en-tete sinon, comme `SectionHeader`.
        if (tries.length > maximumATerminer)
          OverflowBar(
            key: const ValueKey<String>('journee-a-terminer-entete'),
            alignment: MainAxisAlignment.spaceBetween,
            spacing: AppSpacing.lg,
            overflowSpacing: AppSpacing.sm,
            children: <Widget>[
              entete,
              LienFleche(
                key: const ValueKey<String>('journee-a-terminer-voir-tout'),
                libelle: t.tuteur.accueil.voirTout,
                legende: true,
                // DASH-ENS-ROUTE : une adresse, pour qu'un rechargement Web ou
                // un lien garde la liste (DASH_STRATEGIE §5).
                onPress: () =>
                    GoRouter.of(context).go(Routes.enseignantATerminer),
              ),
            ],
          )
        else
          KeyedSubtree(
            key: const ValueKey<String>('journee-a-terminer-entete'),
            child: entete,
          ),
        Ecart.vXs,
        Text(
          t.enseignant.journee.aTerminerAide,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vSm,
        _LignesATerminer(
          cahiers: tries.take(maximumATerminer).toList(growable: false),
          enFile: enFile,
        ),
      ],
    );
  }
}

/// Les cahiers « A terminer », du plus ancien au plus recent (§11.4).
List<CahierEnRetard> trierCahiersATerminer(List<CahierEnRetard> cahiers) =>
    List<CahierEnRetard>.of(
      cahiers,
    )..sort((CahierEnRetard a, CahierEnRetard b) => a.debut.compareTo(b.debut));

/// La liste complete « A terminer » (§11.4), a son adresse
/// [Routes.enseignantATerminer] (DASH-ENS-ROUTE) : ouverte par « Voir tout »,
/// ou directement (rechargement, lien). Elle lit elle-meme les cahiers en
/// retard, avec ses etats : chargement, erreur, vide, contenu, et hors ligne
/// (un echec sans reseau se dit « hors ligne », sous le bandeau de
/// [PageShell]).
class ListeATerminerPage extends ConsumerWidget {
  /// Cree la page.
  const ListeATerminerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<CahierEnRetard>> lecture = ref.watch(
      cahiersEnRetardProvider,
    );
    final Widget corps;
    if (!lecture.hasValue && lecture.isLoading) {
      corps = const Skeleton.liste(lignes: 3);
    } else if (lecture.hasError && !lecture.hasValue) {
      // Jamais « rien a terminer » sur une lecture ratee (D10). Sans reseau,
      // l'echec se dit « hors ligne », pas « le serveur n'a pas repondu ».
      corps = _EchecLecture(
        cle: 'a-terminer-erreur',
        phraseServeur: t.enseignant.journee.aTerminerErreur,
        quoiHorsLigne: t.enseignant.journee.aTerminerSansDonnees,
        onReessayer: () => ref.invalidate(cahiersEnRetardProvider),
      );
    } else if (lecture.requireValue.isEmpty) {
      corps = EmptyState(
        key: const ValueKey<String>('a-terminer-vide'),
        message: t.enseignant.journee.aTerminerVide,
        icone: AppIcons.cahier,
      );
    } else {
      corps = _LignesATerminer(
        // Relue au retour d'un cahier : une ligne validee disparait.
        cahiers: trierCahiersATerminer(lecture.requireValue),
        enFile: ref.watch(cahiersEnFileProvider).value ?? const <String>{},
      );
    }
    return PageShell(
      titre: t.enseignant.journee.aTerminer,
      onRetour: () => _retourVersJournee(context),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: corps,
        ),
      ),
    );
  }
}

/// Tous les remplacements confirmes (DASH-ENS-LISTES, ligne DASH-ENS-REMPL),
/// a l'adresse [Routes.enseignantRemplacements] : ouverte par « Voir tout »
/// de la Journee, ou directement. Les plus proches d'abord (D6).
///
/// La source est la memoire des remplacements que le serveur a confirmes
/// (`remplacementsConfirmesProvider`, synchrone) : elle n'a ni chargement ni
/// echec de lecture, et aucun n'est invente (D10). Etats : vide, contenu ;
/// le bandeau hors ligne vient de [PageShell].
class ListeRemplacementsPage extends ConsumerWidget {
  /// Cree la page.
  const ListeRemplacementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<OffreRemplacement> tries = trierRemplacements(
      ref.watch(remplacementsConfirmesProvider),
    );
    return PageShell(
      titre: t.enseignant.journee.remplacementsTitre,
      onRetour: () => _retourVersJournee(context),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: tries.isEmpty
              ? EmptyState(
                  key: const ValueKey<String>('remplacements-vide'),
                  message: t.enseignant.journee.remplacementsVide,
                  icone: AppIcons.cours,
                )
              : PileCartes(
                  key: const ValueKey<String>('remplacements-liste'),
                  children: <Widget>[
                    for (final OffreRemplacement offre in tries)
                      CarteRemplacement(
                        offre: offre,
                        date: dateLisible(offre.debut),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Toutes les « Alertes utiles » (DASH-ENS-LISTES, ligne DASH-ENS-ALERTES), a
/// l'adresse [Routes.enseignantAlertes] : ouverte par le lien « Voir les N
/// autres alertes » de la Journee, ou directement.
///
/// Elle lit ce que lit le bloc de la Journee : les seances (pour le cours en
/// direct et le cours annule), la presence du cours en direct, les offres de
/// remplacement. Etats : chargement, erreur (une seance ou une presence
/// illisible le dit, jamais « aucune alerte », D10), vide, contenu ; le
/// bandeau hors ligne vient de [PageShell].
class ListeAlertesPage extends ConsumerWidget {
  /// Cree la page.
  const ListeAlertesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime maintenant = ref.watch(maintenantJourneeProvider)();
    final AsyncValue<List<SeanceEnseignant>> seances = ref.watch(
      seancesEnseignantProvider,
    );
    final Widget corps;
    if (!seances.hasValue && seances.isLoading) {
      corps = const Skeleton.liste(lignes: 3);
    } else if (seances.hasError && !seances.hasValue) {
      corps = _ErreurAlertes(
        onReessayer: () => ref.invalidate(seancesEnseignantProvider),
      );
    } else {
      final List<SeanceEnseignant> toutes = seances.requireValue;
      final SeanceEnseignant? dominant = _seanceDominante(toutes, maintenant);
      final SeanceEnseignant? enDirect =
          dominant != null && dominant.enCoursA(maintenant) ? dominant : null;
      final AsyncValue<List<PresenceParticipant>?>? presence = enDirect == null
          ? null
          : ref.watch(presenceSeanceProvider(enDirect.id));
      final List<OffreRemplacement> confirmes = ref.watch(
        remplacementsConfirmesProvider,
      );
      final List<OffreRemplacement> offres = ref
          .watch(offresRemplacementProvider)
          .where(
            (OffreRemplacement o) => !confirmes.any(
              (OffreRemplacement c) => c.seanceId == o.seanceId,
            ),
          )
          .toList(growable: false);
      final Seance? annulee = seanceAnnuleeDuJour(
        toutes.map(_versSeance).toList(growable: false),
        maintenant,
      );
      if (presence != null && !presence.hasValue && presence.isLoading) {
        corps = const Skeleton.liste(lignes: 3);
      } else if (presence != null && presence.value == null) {
        // Presence illisible : on ne dit pas « aucune absence » (J3, D10).
        corps = _ErreurAlertes(
          onReessayer: () =>
              ref.invalidate(presenceSeanceProvider(enDirect!.id)),
        );
      } else {
        final List<String> alertes = alertesPresence(
          presence?.value ?? const <PresenceParticipant>[],
        );
        corps = alertes.isEmpty && offres.isEmpty && annulee == null
            ? EmptyState(
                key: const ValueKey<String>('alertes-vide'),
                message: t.enseignant.journee.alertesVide,
                icone: AppIcons.avertissement,
              )
            : _AlertesUtiles(
                key: const ValueKey<String>('alertes-liste'),
                entete: false,
                alertes: alertes,
                offres: offres,
                coursAnnule: _retrouverParId(toutes, annulee),
              );
      }
    }
    return PageShell(
      titre: t.enseignant.journee.alertesUtiles,
      onRetour: () => _retourVersJournee(context),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: corps,
        ),
      ),
    );
  }
}

/// L'echec de lecture des alertes (K-59) : ce qui manque, la cause probable,
/// et « Reessayer ».
class _ErreurAlertes extends StatelessWidget {
  const _ErreurAlertes({required this.onReessayer});

  final VoidCallback onReessayer;

  @override
  Widget build(BuildContext context) => _EchecLecture(
    cle: 'alertes-erreur',
    phraseServeur: t.enseignant.journee.alertesErreur,
    quoiHorsLigne: t.enseignant.journee.alertesSansDonnees,
    onReessayer: onReessayer,
  );
}

/// L'echec de lecture d'une liste de la Journee : quand le reseau manque,
/// le bandeau de `PageShell` le dit deja et le bloc dit seulement ce qui
/// manque ([quoiHorsLigne], EA-HL-DOUBLE-1) ; sinon l'echec serveur et sa
/// phrase (K-59). Les deux proposent de relire ; aucun ne dit « rien a
/// afficher » (D10).
class _EchecLecture extends ConsumerWidget {
  const _EchecLecture({
    required this.cle,
    required this.phraseServeur,
    required this.quoiHorsLigne,
    required this.onReessayer,
  });

  final String cle;
  final String phraseServeur;
  final String quoiHorsLigne;
  final VoidCallback onReessayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    if (horsLigne) {
      return EtatSansDonnees(
        key: ValueKey<String>(cle),
        quoi: quoiHorsLigne,
        onAction: onReessayer,
      );
    }
    return EtatSysteme(
      key: ValueKey<String>(cle),
      nature: NatureEtat.echecServeur,
      phrase: phraseServeur,
      onAction: onReessayer,
    );
  }
}

/// Une ligne par cahier ; l'appui ouvre le cahier de la seance.
class _LignesATerminer extends ConsumerWidget {
  const _LignesATerminer({required this.cahiers, required this.enFile});

  final List<CahierEnRetard> cahiers;
  final Set<String> enFile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GroupeReglages(
      lignes: <LigneRubrique>[
        for (final CahierEnRetard cahier in cahiers)
          LigneRubrique(
            icone: AppIcons.cahier,
            libelle: t.enseignant.journee.cahierLigne(
              classe: deDevant(_nomClasse(cahier.groupeLibelle)),
            ),
            // Doc 04 §20.8 : valide hors ligne, le cahier reste ici
            // « En attente d'envoi » jusqu'a la confirmation du serveur ;
            // l'appui ouvre cet etat, pas le formulaire (§33 n. 14).
            legende: enFile.contains(cahier.seanceId)
                ? t.enseignant.cahier.enFileTitre
                : t.enseignant.journee.cahierDetail(
                    jour: t.commun.dates.jours[cahier.debut.weekday - 1]
                        .toLowerCase(),
                    numero: '${cahier.debut.day}',
                    mois: t.commun.dates.mois[cahier.debut.month - 1],
                    heure: _hhmm(cahier.debut),
                  ),
            onPress: () async {
              // `push` et non `go` : au retour, la file se relit et la
              // ligne disparait d'elle-meme.
              await GoRouter.of(context)
                  .push<void>(Routes.cahierPour(cahier.seanceId));
              if (context.mounted) {
                ref.invalidate(cahiersEnRetardProvider);
                ref.invalidate(seancesEnseignantProvider);
                ref.invalidate(cahiersEnFileProvider);
              }
            },
          ),
      ],
    );
  }
}

/// « Alertes utiles » : une ligne par alerte, sans destination, sauf l'offre
/// de remplacement (ENS-13B), qui ouvre « Assurer ce remplacement ? ».
class _AlertesUtiles extends ConsumerWidget {
  const _AlertesUtiles({
    required this.alertes,
    super.key,
    this.autres = 0,
    this.entete = true,
    this.offres = const <OffreRemplacement>[],
    this.coursAnnule,
    this.onReessayerPartiel,
  });

  /// Combien d'alertes de presence ne sont pas montrees : au-dela de zero,
  /// un lien ouvre la page qui les liste toutes (DASH-ENS-LISTES).
  final int autres;

  /// Faux sur la page des alertes, qui porte deja le titre.
  final bool entete;

  /// Relance des lectures secondaires (prieres, pauses, cahiers en retard)
  /// quand elles ont echoue, ou `null` si tout a ete lu (LIB-ERR-1).
  final VoidCallback? onReessayerPartiel;

  /// Le cours annule du jour : une carte attenuee avant toute autre alerte,
  /// avec la pastille « Annulee », l'horaire barre et la ligne « pourquoi »
  /// (ANNUL-VIS-1).
  final SeanceEnseignant? coursAnnule;
  final List<String> alertes;
  final List<OffreRemplacement> offres;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ReponseRemplacement? port = ref.watch(reponseRemplacementProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (entete) ...<Widget>[
          SectionHeader(titre: t.enseignant.journee.alertesUtiles),
          Ecart.vSm,
        ],
        if (coursAnnule != null) ...<Widget>[
          _CarteCoursAnnule(cours: coursAnnule!),
          if (alertes.isNotEmpty || offres.isNotEmpty) Ecart.vLg,
        ],
        if (alertes.isNotEmpty || offres.isNotEmpty)
          GroupeReglages(
            lignes: <LigneRubrique>[
              for (final OffreRemplacement offre in offres)
                LigneRubrique(
                  icone: AppIcons.cours,
                  libelle: t.enseignant.journee.remplacement.titre,
                  legende:
                      '${offre.classe} · ${dateLisible(offre.debut)} · '
                      '${_hhmm(offre.debut)}',
                  onPress: port == null
                      ? null
                      : () async {
                          final bool confirme = await ouvrirFeuilleRemplacement(
                            context,
                            port: port,
                            offre: offre,
                            date: dateLisible(offre.debut),
                          );
                          // La carte n'apparait que sur la confirmation du
                          // serveur (E7).
                          if (confirme) {
                            ref
                                .read(remplacementsConfirmesProvider.notifier)
                                .confirmer(offre);
                          }
                        },
                ),
              for (final String alerte in alertes)
                LigneRubrique(icone: AppIcons.avertissement, libelle: alerte),
            ],
          ),
        // DASH-ENS-LISTES : « et N autres » devient un lien vers la page qui
        // les liste toutes (l'exception D6 b tombe).
        if (autres > 0) ...<Widget>[
          Ecart.vSm,
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: LienFleche(
              key: const ValueKey<String>('journee-alertes-voir-autres'),
              libelle: autres == 1
                  ? t.enseignant.journee.voirAutreAlerte
                  : t.enseignant.journee.voirAutresAlertes(nombre: '$autres'),
              alignerEnFin: true,
              onPress: () => GoRouter.of(context).go(Routes.enseignantAlertes),
            ),
          ),
        ],
        if (onReessayerPartiel != null) ...<Widget>[
          if (coursAnnule != null || alertes.isNotEmpty || offres.isNotEmpty)
            Ecart.vLg,
          Text(
            t.enseignant.journee.erreurPartielle,
            key: const ValueKey<String>('journee-erreur-partielle'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          // Le bouton se pose 16 sous le contenu qu'il confirme (R20).
          Ecart.vLg,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: IntrinsicWidth(
              child: ActionPrincipale(
                key: const ValueKey<String>(
                  'journee-erreur-partielle-reessayer',
                ),
                libelle: t.commun.reessayer,
                niveau: NiveauAction.secondaire,
                pleineLargeur: false,
                onPress: onReessayerPartiel,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Le cours annule du jour : la surface enfoncee (jamais une opacite), la
/// pastille « Annulee », l'horaire barre et la ligne qui dit pourquoi.
///
/// Le serveur ne rend pas encore le motif de l'annulation : la ligne le dit
/// (« Motif non communique ») plutot que d'en inventer un. La suite (« seance
/// non facturee », remplacant) viendra avec la donnee (BR-1).
///
/// SALLE-CORR-3 (releve VERIF-CORR-2) : comme la carte de seance, elle nomme
/// sa Classe et y mene par « Voir la Classe » (un lien, K-56 : le seul
/// bouton plein de la page reste celui de la carte de seance).
class _CarteCoursAnnule extends StatelessWidget {
  const _CarteCoursAnnule({required this.cours});

  final SeanceEnseignant cours;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final String nom = _nomClasse(cours.groupeLibelle);
    return AppCard(
      key: const ValueKey<String>('journee-cours-annule'),
      surface: surfaceCarteSeance(palette, annulee: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const PastilleEtatSeance(etat: EtatPastilleSeance.annulee),
          Ecart.vMd,
          Semantics(
            header: true,
            child: Text(
              nom,
              style: palette.inkStrong.applyTo(
                textes.titleMedium ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vXs,
          TexteHeureSeance(
            heure: t.enseignant.journee.plage(
              debut: _hhmm(cours.debut),
              fin: _hhmm(cours.fin),
            ),
            annulee: true,
            style: AppTypography.tabulaire(
              palette.inkStrong.applyTo(
                textes.titleMedium ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vXs,
          LigneRaisonSeance(raison: t.etat.motifNonCommunique),
          Ecart.vMd,
          LienFleche(
            key: const ValueKey<String>('journee-cours-annule-classe'),
            libelle: t.enseignant.journee.voirClasse,
            libelleSemantique: t.enseignant.journee.voirClasseLecteur(
              classe: nom,
            ),
            onPress: () {
              final String? idGroupe = cours.groupeId;
              if (idGroupe == null) {
                GoRouter.of(context).go(Routes.enseignantClasses);
                return;
              }
              // `push` : le retour de l'Espace Classe se referme sur
              // Aujourd'hui (R1), comme la carte de seance.
              unawaited(
                GoRouter.of(context).push<void>(Routes.groupePour(idGroupe)),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Ce que « Ma journee » dit quand elle est vide.
class _RienAujourdhui extends StatelessWidget {
  const _RienAujourdhui({required this.prochain});

  final SeanceEnseignant? prochain;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final SeanceEnseignant? cours = prochain;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(t.enseignant.journee.rienAujourdhui, style: textes.bodyLarge),
        if (cours != null) ...<Widget>[
          Ecart.vXs,
          Text(
            t.enseignant.journee.rienAujourdhuiDetail(
              jour: t.disponibilites.joursLongs[cours.debut.weekday - 1],
              heure: _hhmm(cours.debut),
            ),
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
      ],
    );
  }
}

/// Le squelette : la forme de la page qui arrive, sans fausse donnee.
class _Squelette extends StatelessWidget {
  const _Squelette();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Skeleton.tuileBento(hauteur: 240),
      Ecart.vXxl,
      Skeleton.ligneTimeline(lignes: 3),
    ],
  );
}

/// La seance d'enseignant, vue comme la `Seance` que la journee partagee sait
/// lire. `elevePrenom` porte « Classe An-Nour » et `eleveIdentifiant`
/// l'effectif, ce que `TimelineRow` doit dire d'une seance de Classe.
///
/// `ponytail:` dette assumee (champ de modele partage employe pour un
/// libelle). Reprise : un champ de groupe sur `EntreeJournee`, demande dans
/// `CONTRACT_REQUEST_A.md`.
Seance _versSeance(SeanceEnseignant seance) => Seance(
  id: seance.id,
  debut: seance.debut,
  fin: seance.fin,
  statut: seance.statut,
  eleveId: '',
  elevePrenom: t.enseignant.journee.classeNommee(
    classe: _nomClasse(seance.groupeLibelle),
  ),
  eleveIdentifiant: _effectif(seance.nbParticipants),
  enseignantId: '',
  enseignantPrenom: '',
  enseignantIdentifiant: '',
  minutesInterruption: seance.minutesInterruption,
);

/// Le nom d'une Classe, « Classe » quand la base n'en donne pas.
String _nomClasse(String? libelle) =>
    libelle == null || libelle.isEmpty ? t.enseignant.journee.classe : libelle;

/// Combien d'eleves, au singulier ou au pluriel.
String _effectif(int nombre) => nombre == 1
    ? t.enseignant.journee.effectifUn
    : t.enseignant.journee.effectif(nombre: '$nombre');

/// Comment nommer un eleve dans une alerte : son prenom, sinon son identifiant
/// immuable. **Jamais un nom de famille.**
String _nommer(PresenceParticipant ligne) =>
    ligne.prenom.trim().isEmpty ? ligne.identifiantImmuable : ligne.prenom;

/// « Lundi 28 septembre » : la date d'un instant, en toutes lettres.
String dateLisible(DateTime quand) => t.enseignant.journee.date(
  jour: t.commun.dates.jours[quand.weekday - 1],
  numero: '${quand.day}',
  mois: t.commun.dates.mois[quand.month - 1],
);

/// Vrai quand deux instants tombent le meme jour civil local.
bool _memeJour(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// L'heure locale d'un instant, sur deux chiffres.
String _hhmm(DateTime quand) =>
    '${quand.hour.toString().padLeft(2, '0')}:'
    '${quand.minute.toString().padLeft(2, '0')}';
