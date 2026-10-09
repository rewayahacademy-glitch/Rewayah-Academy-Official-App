import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../demo/enseignant_demo.dart';
import '../disponibilites/grille_semaine.dart';

/// Les Classes disponibles, telles que le serveur les filtrerait (doc 04 §15.4).
///
/// **`null` tant que rien n'est branche (BR-1)** : la section n'est alors pas
/// rendue, plutot que d'afficher un vide qui mentirait. La demonstration
/// (`/demo/enseignant`) la surcharge avec [DonneesEnseignantDemo.offres].
final Provider<List<OffreClasseDemo>?> offresClassesProvider =
    Provider<List<OffreClasseDemo>?>((Ref ref) => null);

/// `ENS-06` Disponibilites : les heures hebdomadaires de l'enseignant, puis
/// les Classes disponibles (EN-5).
///
/// **L'ancien modele est retire de l'ecran** (doc 04 §15.1, E1) : plus
/// d'onglet « Eleves en attente », plus de « Prendre {jour} a {heure} ». Le
/// serveur n'est pas touche (BR-1).
///
/// **Hebdomadaire, sans date** (E15) : aucun « 16 sept. », aucune navigation
/// de semaine.
///
/// Mobile : une colonne, les heures puis « Classes disponibles ».
/// Bureau : deux colonnes, le planning hebdomadaire et les Classes (doc 04
/// §15.3).
class CreneauxPage extends StatelessWidget {
  /// Cree l'ecran des disponibilites.
  const CreneauxPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Gabarit gabarit = AppGabarit.de(context);
    // Le titre de la page dit deja « Disponibilites » : pas de sous-titre
    // « Mes disponibilites » qui le repete (K-42 §1).
    const Widget heures = _OngletHeures();
    const Widget classes = _ClassesDisponibles();

    return PageShell(
      // Le titre concorde avec la destination de la coquille.
      titre: t.nav.enseignant.creneaux,
      child: gabarit == Gabarit.desktop
          ? const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: heures),
                Ecart.hXxl,
                Expanded(child: classes),
              ],
            )
          : const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[heures, Ecart.vXxl, classes],
            ),
    );
  }
}

/// Un panneau nomme.
class _Panneau extends StatelessWidget {
  const _Panneau({required this.titre, required this.child});

  final String titre;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      SectionHeader(titre: titre),
      Ecart.vMd,
      child,
    ],
  );
}

/// Le jour ecrit en toutes lettres, avec sa majuscule (« Lundi », E15).
String _jour(int jour) {
  final String long = t.disponibilites.joursLongs[jour - 1];
  return long[0].toUpperCase() + long.substring(1);
}

/// « Mes disponibilites » : la liste par jour, puis la grille de `TUT-04`.
class _OngletHeures extends ConsumerStatefulWidget {
  const _OngletHeures();

  @override
  ConsumerState<_OngletHeures> createState() => _OngletHeuresEtat();
}

class _OngletHeuresEtat extends ConsumerState<_OngletHeures> {
  bool _enCours = false;
  bool _erreur = false;
  String? _confirmation;
  bool _grilleOuverte = false;

  /// Nomme une case : c'est ce qui manquait a l'etat « enregistre ».
  ///
  /// Sans le jour et l'heure, la confirmation dit qu'« un » creneau est passe,
  /// pas lequel : au troisieme tap d'affilee, l'enseignant ne sait plus si
  /// c'est le sien qui a abouti.
  String _nommer(Creneau creneau) => t.enseignant.creneaux.heureLibelle(
    jour: t.disponibilites.joursLongs[creneau.jour - 1],
    heure: '${creneau.heure}',
  );

  /// Les heures qui portent deja un eleve : le **conflit** de la grille.
  ///
  /// Sans ce calcul, une case sur laquelle un eleve est engage est indiscernable
  /// d'une case libre. Le conflit se **voit**, il ne se bloque pas : retirer une
  /// disponibilite n'annule aucun cours (`weekly_availability` et
  /// `teacher_student_assignments` sont deux tables), et refuser le geste serait
  /// une regle metier qu'aucun document ne pose. L'ecran dit donc ce que le
  /// retrait fait, et ce qu'il ne fait pas.
  ///
  /// Deduplique : deux eleves sur la meme heure ne font qu'un conflit, et
  /// l'enumeration ne repete pas « mardi 17 h, mardi 17 h ».
  List<Creneau> _engagements(List<Affectation> affectations, String monId) =>
      <Creneau>{
        for (final Affectation a in affectations)
          if (a.active && a.enseignantId == monId) a.creneau,
      }.toList();

  bool _engagee(List<Creneau> engagements, Creneau creneau) => engagements.any(
    (Creneau e) => e.jour == creneau.jour && e.heure == creneau.heure,
  );

  Future<void> _basculer(
    String monId,
    List<Creneau> engagements,
    Creneau creneau,
    bool posee,
  ) async {
    // Retirer une heure engagee n'annule pas le cours : la relation dure et ne
    // se rompt que par une demande de reaffectation (ADR-017). Le geste passe,
    // et la confirmation dit exactement cela plutot que « retire » tout court.
    final bool engagee = posee && _engagee(engagements, creneau);

    setState(() {
      _enCours = true;
      _erreur = false;
    });
    try {
      final ServicePlanning service = ref.read(servicePlanningProvider);
      if (posee) {
        await service.retirer(profilId: monId, creneau: creneau);
      } else {
        await service.poser(profilId: monId, creneau: creneau);
      }
      ref.invalidate(disponibilitesProvider(monId));
      if (mounted) {
        setState(() {
          final String heure = _nommer(creneau);
          _confirmation = switch ((posee, engagee)) {
            (true, true) => t.enseignant.creneaux.retraitEngage(heure: heure),
            (true, false) => t.enseignant.creneaux.heureRetiree(heure: heure),
            (false, _) => t.enseignant.creneaux.heureEnregistree(heure: heure),
          };
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _erreur = true;
          _confirmation = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _enCours = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final String? monId = ref.watch(sessionProvider).profileId;

    if (monId == null) {
      // La session n'a pas encore livre l'identifiant : c'est un CHARGEMENT,
      // pas un vide. L'ecran rendait ici un `EmptyState` avec une invitation
      // vide, c'est-a-dire ni l'un ni l'autre des deux etats.
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

    // Jamais par le type d'execution de l'`AsyncValue` : Riverpod 3 relance un
    // provider en echec et repasse par `AsyncLoading` en conservant `hasError`.
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
      // **Aucune heure affichee avant que le fuseau ait repondu.** La grille
      // se repliait sur 'Europe/Paris' code en dur : un enseignant de Conakry
      // lisait ses heures en heure de Paris, puis les voyait changer.
      return const Skeleton.liste(lignes: 6);
    }

    final List<Creneau> poses = creneaux.requireValue;
    final List<Creneau> engagements = _engagements(
      affectations.value ?? const <Affectation>[],
      monId,
    );

    // Mobile : la liste par jour avec les plages, puis « Ajouter un creneau »
    // qui ouvre la grille (00_MAQUETTES, ENS-06 P). Sans aucune plage, la
    // grille est ouverte d'emblee. Bureau : le planning est toujours visible.
    final bool liste =
        AppGabarit.de(context) == Gabarit.mobile && poses.isNotEmpty;
    final bool grille = !liste || _grilleOuverte;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Jours sans date (E15).
        if (liste) ...<Widget>[
          for (final int jour in (<int>{
            for (final Creneau c in poses) c.jour,
          }.toList()..sort()))
            LigneCleValeur(
              cle: _jour(jour),
              valeur:
                  (poses
                          .where((Creneau c) => c.jour == jour)
                          .map((Creneau c) => c.heure)
                          .toList()
                        ..sort())
                      .map((int h) => t.enseignant.creneaux.heure(heure: '$h'))
                      .join(', '),
            ),
          Ecart.vLg,
        ],
        if (!grille)
          ActionPrincipale(
            libelle: t.enseignant.creneaux.ajouterCreneau,
            niveau: NiveauAction.secondaire,
            onPress: () => setState(() => _grilleOuverte = true),
          )
        else ...<Widget>[
          Text(t.disponibilites.titreEnseignant, style: textes.titleMedium),
          Ecart.vXs,
          Text(t.disponibilites.consigneEnseignant, style: textes.bodySmall),
          Ecart.vMd,
          GrilleSemaine(
            creneaux: poses,
            fuseau: fuseau.requireValue,
            // Hors ligne, la grille reste CONSULTABLE mais inerte : une case
            // pressee sans reseau echouerait apres le geste, et un bouton qui ne
            // peut pas aboutir n'est pas rendu (`lib/CLAUDE.md`).
            enCours: _enCours || horsLigne,
            onBasculer: (Creneau creneau, bool posee) =>
                _basculer(monId, engagements, creneau, posee),
          ),
        ],
        Ecart.vSm,
        Text(switch (poses.length) {
          0 => t.enseignant.creneaux.aucuneHeure,
          1 => t.disponibilites.poseeUne,
          _ => t.disponibilites.posees(nombre: poses.length),
        }, style: textes.bodySmall),
        if (horsLigne) ...<Widget>[
          Ecart.vSm,
          Text(
            t.enseignant.creneaux.horsLigneGrille,
            style: palette.inkWarning.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
        if (engagements.isNotEmpty) ...<Widget>[
          Ecart.vSm,
          Text(
            // Le conflit se VOIT, avant tout geste : une case engagee et une
            // case libre ne se distinguent autrement par rien.
            engagements.length == 1
                ? t.enseignant.creneaux.heureEngagee(
                    heures: _nommer(engagements.single),
                  )
                : t.enseignant.creneaux.heuresEngagees(
                    heures: engagements.map(_nommer).join(', '),
                  ),
            style: palette.inkWarning.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
        if (_erreur || echec) ...<Widget>[
          Ecart.vSm,
          Text(
            t.disponibilites.erreur,
            style: palette.inkAlert.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
        Ecart.vSm,
        // L'etat « enregistre », nomme. `enCours` figeait la grille sans
        // jamais dire qu'une case etait passee : l'enseignant tapait, la
        // couleur changeait, et rien ne distinguait un enregistrement reussi
        // d'un rendu optimiste.
        LocalFeedback(message: _confirmation),
      ],
    );
  }
}

/// Le mot et le ton de chaque etat, ecrits et pas seulement colores
/// (UX_REVIEW_04, ligne 7 b).
(String, TonEtat) _etat(EtatOffreDemo etat) => switch (etat) {
  EtatOffreDemo.disponible => (
    t.enseignant.creneaux.etatDisponible,
    TonEtat.succes,
  ),
  EtatOffreDemo.enAttenteValidation => (
    t.enseignant.creneaux.etatEnAttente,
    TonEtat.neutre,
  ),
  EtatOffreDemo.limiteAtteinte => (
    t.enseignant.creneaux.etatLimite,
    TonEtat.avertissement,
  ),
};

/// « Lundi, Mercredi, Vendredi » : tous les jours du rendez-vous.
String _recurrence(OffreClasseDemo offre) => offre.jours.map(_jour).join(', ');

/// Section « Classes disponibles » (doc 04 §15.6, §15.7).
class _ClassesDisponibles extends ConsumerStatefulWidget {
  const _ClassesDisponibles();

  @override
  ConsumerState<_ClassesDisponibles> createState() => _ClassesDisponiblesEtat();
}

class _ClassesDisponiblesEtat extends ConsumerState<_ClassesDisponibles> {
  /// Les Classes demandees pendant cette visite : en demonstration, leur etat
  /// passe a « En attente de validation », rien n'est envoye.
  final Set<String> _demandees = <String>{};

  Future<void> _ouvrir(OffreClasseDemo offre) async {
    final bool? demandee = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext _) => DetailOffrePage(offre: offre),
      ),
    );
    if (demandee == true && mounted) {
      setState(() => _demandees.add(offre.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<OffreClasseDemo>? offres = ref.watch(offresClassesProvider);
    if (offres == null) {
      return const SizedBox.shrink();
    }
    return _Panneau(
      titre: t.enseignant.creneaux.classesDisponibles,
      child: offres.isEmpty
          ? EmptyState(
              message: t.enseignant.creneaux.aucuneClasse,
              invitation: t.enseignant.creneaux.aucuneClasseDetail,
            )
          // K-42 §4 : un seul groupe a filets, une ligne par Classe, jamais
          // une carte par Classe.
          : GroupeReglages(
              lignes: <LigneRubrique>[
                for (final OffreClasseDemo offre in offres)
                  _ligneOffre(
                    offre,
                    _demandees.contains(offre.id)
                        ? EtatOffreDemo.enAttenteValidation
                        : offre.etat,
                  ),
              ],
            ),
    );
  }

  /// Une Classe disponible : nom, niveau, langue, jours et heure. Seule
  /// l'exception porte une pastille (E2) ; seule une Classe disponible
  /// s'ouvre sur son detail, avec un chevron (ENS-06B).
  LigneRubrique _ligneOffre(OffreClasseDemo offre, EtatOffreDemo etat) {
    final bool ouvrable = etat == EtatOffreDemo.disponible;
    final String heure = t.enseignant.creneaux.heure(
      heure: '${offre.creneau.heure}',
    );
    final (String mot, TonEtat ton) = _etat(etat);
    return LigneRubrique(
      icone: AppIcons.classes,
      libelle: offre.nom,
      legende: <String>[
        '${t.creneaux.niveau(niveau: '${offre.niveau}')} · ${offre.langue}',
        '${_recurrence(offre)} · $heure',
        // La charge de l'ENSEIGNANT, pas la capacite de la Classe
        // (00_MAQUETTES, ENS-06 R3).
        if (etat == EtatOffreDemo.limiteAtteinte)
          t.enseignant.creneaux.limiteDetail,
      ].join('\n'),
      marque: ouvrable ? null : StatusPill(libelle: mot, ton: ton),
      onPress: ouvrable ? () => _ouvrir(offre) : null,
    );
  }
}

/// `ENS-06B` : le detail d'une Classe disponible, sa confirmation, puis un
/// succes honnete (E7).
///
/// L'enseignant voit tout le rendez-vous avant de s'engager : il accepte la
/// Classe entiere (doc 04 §16.2). **En demonstration, rien n'est envoye** :
/// le succes le dit, et la Classe passe a « En attente de validation ».
///
/// Les champs que la source ne donne pas (public, capacite, date de debut,
/// parcours) ne sont pas rendus plutot qu'inventes.
class DetailOffrePage extends StatefulWidget {
  /// Cree le detail.
  const DetailOffrePage({required this.offre, super.key});

  /// La Classe proposee.
  final OffreClasseDemo offre;

  @override
  State<DetailOffrePage> createState() => _DetailOffrePageEtat();
}

class _DetailOffrePageEtat extends State<DetailOffrePage> {
  bool _demandee = false;

  List<Widget> _resume(OffreClasseDemo offre) => <Widget>[
    LigneCleValeur(
      cle: t.enseignant.creneaux.cleRecurrence,
      valeur: _recurrence(offre),
    ),
    LigneCleValeur(
      cle: t.enseignant.creneaux.cleHeureLocale,
      valeur: t.enseignant.creneaux.heure(heure: '${offre.creneau.heure}'),
    ),
    if (offre.dureeMinutes != null)
      LigneCleValeur(
        cle: t.enseignant.creneaux.cleDuree,
        valeur: t.enseignant.creneaux.duree(minutes: '${offre.dureeMinutes}'),
      ),
  ];

  /// La confirmation « Confirmer cette Classe ? », qui rappelle tous les jours
  /// avant l'envoi (doc 04 §16.4).
  Future<void> _confirmer() async {
    final OffreClasseDemo offre = widget.offre;
    final bool? ok = await AppBottomSheet.ouvrir<bool>(
      context,
      titre: t.enseignant.creneaux.confirmerTitre,
      constructeur: (BuildContext _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _resume(offre),
      ),
      // « Revenir » d'abord, « Confirmer cette Classe » en fin de ligne,
      // aucun choix preselectionne (UX_REVIEW_04, ligne 8).
      actions: (BuildContext feuille) => Wrap(
        alignment: WrapAlignment.end,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: <Widget>[
          ActionPrincipale(
            libelle: t.enseignant.creneaux.revenir,
            niveau: NiveauAction.secondaire,
            onPress: () => Navigator.of(feuille).pop(false),
          ),
          ActionPrincipale(
            libelle: t.enseignant.creneaux.confirmer,
            onPress: () => Navigator.of(feuille).pop(true),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      setState(() => _demandee = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final OffreClasseDemo offre = widget.offre;
    final (String mot, TonEtat ton) = _etat(
      _demandee ? EtatOffreDemo.enAttenteValidation : offre.etat,
    );
    // K-42 (style, regles 2 et 6) : sur bureau, une colonne bornee et le
    // bouton dominant a sa largeur naturelle, au bord de fin.
    final bool bureau = AppGabarit.de(context) == Gabarit.desktop;

    return PageShell(
      titre: offre.nom,
      onRetour: () => Navigator.of(context).pop(_demandee),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: _contenu(context, offre, mot, ton, bureau),
        ),
      ),
    );
  }

  Widget _contenu(
    BuildContext context,
    OffreClasseDemo offre,
    String mot,
    TonEtat ton,
    bool bureau,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: StatusPill(libelle: mot, ton: ton),
        ),
        Ecart.vMd,
        LigneCleValeur(
          cle: t.enseignant.creneaux.cleNiveau,
          valeur: '${offre.niveau}',
        ),
        LigneCleValeur(
          cle: t.enseignant.creneaux.cleLangue,
          valeur: offre.langue,
        ),
        ..._resume(offre),
        LigneCleValeur(
          cle: t.enseignant.creneaux.cleFuseau,
          valeur: offre.creneau.fuseau,
        ),
        Ecart.vLg,
        if (_demandee) ...<Widget>[
          // Succes E7 et doc 04 §16.5, annonce une fois, poliment.
          Semantics(
            liveRegion: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  t.enseignant.creneaux.demandeTransmise,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Ecart.vXs,
                Text(
                  t.enseignant.creneaux.demandeTransmiseDetail,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Ecart.vMd,
          // La demonstration n'envoie rien, et le dit.
          LocalFeedback(message: t.enseignant.demo.mention, persistant: true),
        ] else if (offre.etat == EtatOffreDemo.disponible)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ActionPrincipale(
              libelle: t.enseignant.creneaux.reserver,
              pleineLargeur: !bureau,
              onPress: _confirmer,
            ),
          ),
      ],
    );
  }
}
