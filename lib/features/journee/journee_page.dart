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
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/tc_horloge/emplacement_entree.dart';
import '../../core/tc_horloge/session_clock_vm.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/video/pre_vol.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/page_shell.dart';
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
/// Deux lignes se lisent d'un coup d'oeil avant un cours ; au dela, une
/// phrase dit combien d'autres attendent.
const int _maximumAlertes = 2;

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
    final Map<String, SeanceEnseignant> parId = <String, SeanceEnseignant>{
      for (final SeanceEnseignant seance in toutes) seance.id: seance,
    };
    // Le pont vers la journee partagee, relu par identifiant pour retrouver
    // la seance riche.
    final List<Seance> pont = toutes.map(_versSeance).toList(growable: false);
    final Seance? relais = prochainCours(pont, maintenant);
    final SeanceEnseignant? dominant = relais == null ? null : parId[relais.id];
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
    final List<String> alertes = <String>[
      if (annulee != null)
        t.enseignant.journee.coursAnnule(heure: _hhmm(annulee.debut)),
      if (dominant != null && dominant.enCoursA(maintenant))
        ..._alertesPresence(ref, dominant),
      if (reglages.hasError || pause.hasError || retards.hasError)
        t.enseignant.journee.erreurPartielle,
    ];

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
        seance: dominant,
        maintenant: maintenant,
      ),
      remplacements: <Widget>[
        for (final OffreRemplacement r in confirmes)
          CarteRemplacement(offre: r, date: dateLisible(r.debut)),
      ],
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
      alertes: alertes.isEmpty && offres.isEmpty
          ? null
          : _AlertesUtiles(alertes: alertes, offres: offres),
    );
  }
}

/// Les absences et coupures du cours en direct, en phrases.
///
/// `null` n'est pas une liste vide : « je ne sais pas » ne s'annonce pas
/// comme une absence (invariant J3). Seuls `absente` et `deconnectee`
/// deviennent une alerte.
List<String> _alertesPresence(WidgetRef ref, SeanceEnseignant seance) {
  final List<PresenceParticipant>? lignes = ref
      .watch(presenceSeanceProvider(seance.id))
      .value;
  if (lignes == null) return const <String>[];
  final List<PresenceParticipant> manquants = lignes
      .where(
        (PresenceParticipant ligne) =>
            !ligne.estEnseignant &&
            (ligne.etat == EtatPresence.absente ||
                ligne.etat == EtatPresence.deconnectee),
      )
      .toList(growable: false);
  final int reste = manquants.length - _maximumAlertes;
  return <String>[
    for (final PresenceParticipant ligne in manquants.take(_maximumAlertes))
      ligne.etat == EtatPresence.absente
          ? t.enseignant.journee.absenceDetectee(eleve: _nommer(ligne))
          : t.enseignant.journee.coupureDetectee(eleve: _nommer(ligne)),
    if (reste > 0) t.enseignant.journee.autresAbsences(nombre: '$reste'),
  ];
}

/// Une ou deux colonnes, selon la largeur utile divisee par le facteur de
/// texte (UX_REVIEW_04, ligne ENS-02, point c).
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
    final double facteur = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        final bool deuxColonnes =
            contraintes.maxWidth / facteur >= AppGabarit.seuilEtendu;
        final Widget ecartSection = deuxColonnes ? Ecart.vXxxl : Ecart.vXxl;
        final List<Widget> principale = <Widget>[
          prochaine,
          // Deux cartes autonomes d'une meme section : 16 (contrat A).
          for (final Widget carte in remplacements) ...<Widget>[
            Ecart.vLg,
            carte,
          ],
          ecartSection,
          maJournee,
        ];
        final Widget? cahiers = aTerminer;
        final Widget? signaux = alertes;
        final List<Widget> secondaire = <Widget>[
          ?cahiers,
          if (cahiers != null && signaux != null) ecartSection,
          ?signaux,
        ];

        if (!deuxColonnes || secondaire.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ...principale,
              if (secondaire.isNotEmpty) ecartSection,
              ...secondaire,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: principale,
              ),
            ),
            const SizedBox(width: AppSpacing.xxxl),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: secondaire,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// E11 : l'emplacement de la carte « Prochaine seance », depuis celui de CL-4.
///
/// Ce que CL-4 montre en bouton (« Preparer l'entree », avec son decompte) et
/// ce qui propose « Reessayer » restent tels quels. Aux etats ou CL-4 ne pose
/// qu'une ligne, la ligne devient le contexte calme et un seul bouton suit :
/// - avant la fenetre : « Preparer la seance » ;
/// - apres la seance, cahier non depose : « Finaliser le cahier » ;
/// - sinon (annulee, terminee et deposee) : « Voir la Classe ».
///
/// Pendant le pre-vol (`preparation`), la ligne seule : l'enseignant est deja
/// en train de faire le geste. Jamais de bouton grise.
EmplacementEntree emplacementJournee(
  EmplacementEntree base, {
  required String nomClasse,
  required bool cahierAFinaliser,
  EtatAbsence? absence,
}) {
  // ENS-13 : une absence declaree (hors « Demande annulee », ou l'enseignant
  // assure de nouveau la seance) ne laisse que « Voir la Classe » (E11, doc 04
  // §17.1 et §17.2).
  final bool absent = absence != null && absence != EtatAbsence.demandeAnnulee;
  if (base.reessayer ||
      base.etat == EtatEntree.preparation ||
      (base.estBouton && !absent)) {
    return base;
  }
  final (String libelle, String lecteur) = switch (base.etat) {
    _ when absent => (
      t.enseignant.journee.voirClasse,
      t.enseignant.journee.voirClasseLecteur(classe: nomClasse),
    ),
    EtatEntree.aVenir => (
      t.enseignant.journee.preparerSeance,
      t.enseignant.journee.preparerSeanceLecteur(classe: deDevant(nomClasse)),
    ),
    EtatEntree.terminee when cahierAFinaliser => (
      t.enseignant.journee.finaliserCahier,
      t.enseignant.journee.finaliserCahierLecteur(classe: deDevant(nomClasse)),
    ),
    _ => (
      t.enseignant.journee.voirClasse,
      t.enseignant.journee.voirClasseLecteur(classe: nomClasse),
    ),
  };
  return EmplacementEntree(
    role: base.role,
    etat: base.etat,
    forme: FormeEntree.bouton,
    libelle: libelle,
    libelleLecteur: lecteur,
    // Un bouton de CL-4 remplace porte deja son contexte dans `detail`.
    detail: base.estBouton ? base.detail : base.libelle,
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

    final bool enCours = cours.enCoursA(maintenant);
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
    );
    final EmplacementEntree emplacement = emplacementJournee(
      EmplacementEntree.pour(
        role: RoleEntree.enseignant,
        horloge: horloge,
        nomClasse: nom,
        annulee: cours.statut == StatutSeance.annulee,
        horsLigne: horsLigne,
      ),
      nomClasse: nom,
      cahierAFinaliser: !cours.cahierDepose,
      absence: absence,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(
          titre: enCours
              ? t.enseignant.journee.coursEnCours
              : t.enseignant.journee.prochaineSeance,
        ),
        Ecart.vSm,
        AppCard(
          dominante: true,
          entete: Row(
            children: <Widget>[
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    nom,
                    key: const ValueKey<String>('journee-carte-classe'),
                    style: textes.titleLarge ?? const TextStyle(),
                  ),
                ),
              ),
              if (enCours)
                StatusPill(libelle: t.etat.enDirect, ton: TonEtat.succes),
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
              ),
              Ecart.vSm,
              LigneCleValeur(
                cle: LibellesGroupe.dureeLibelle,
                valeur: LibellesGroupe.dureeLisible(
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
    if (emplacement.libelle == t.enseignant.journee.finaliserCahier) {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Le titre au style de `SectionHeader`, le point colle a lui : dans
        // `SectionHeader`, qui occupe toute la ligne, il partirait au bout.
        Row(
          children: <Widget>[
            Flexible(
              child: Semantics(
                header: true,
                child: Text(
                  t.enseignant.journee.aTerminer,
                  // Un titre de section : `titleLarge`, comme `SectionHeader` ; la
                  // page porte son titre d'ecran au rang `headline*` (HIER-1).
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
            if (tries.length > maximumATerminer) ...<Widget>[
              const Spacer(),
              LienFleche(
                key: const ValueKey<String>('journee-a-terminer-voir-tout'),
                libelle: t.tuteur.accueil.voirTout,
                legende: true,
                onPress: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (BuildContext _) =>
                        _ListeATerminer(cahiers: tries),
                  ),
                ),
              ),
            ],
          ],
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
    List<CahierEnRetard>.of(cahiers)
      ..sort((CahierEnRetard a, CahierEnRetard b) => a.debut.compareTo(b.debut));

/// La liste complete « A terminer », ouverte par « Voir tout » (§11.4).
class _ListeATerminer extends ConsumerWidget {
  const _ListeATerminer({required this.cahiers});

  final List<CahierEnRetard> cahiers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageShell(
      titre: t.enseignant.journee.aTerminer,
      onRetour: () => Navigator.of(context).pop(),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: _LignesATerminer(
            // Relue au retour d'un cahier : une ligne validee disparait.
            cahiers: trierCahiersATerminer(
              ref.watch(cahiersEnRetardProvider).value ?? cahiers,
            ),
            enFile: ref.watch(cahiersEnFileProvider).value ?? const <String>{},
          ),
        ),
      ),
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
    this.offres = const <OffreRemplacement>[],
  });

  final List<String> alertes;
  final List<OffreRemplacement> offres;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ReponseRemplacement? port = ref.watch(reponseRemplacementProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(titre: t.enseignant.journee.alertesUtiles),
        Ecart.vSm,
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
      ],
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
