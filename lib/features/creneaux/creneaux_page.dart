import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_pill.dart';
import '../demo/enseignant_demo.dart';
import 'plages.dart';
import 'plages_disponibilite.dart';

/// Les Classes disponibles, telles que le serveur les filtrerait (doc 04 §15.4).
///
/// **`null` tant que rien n'est branche (BR-1)** : la section n'est alors pas
/// rendue, plutot que d'afficher un vide qui mentirait. La demonstration
/// (`/demo/enseignant`) la surcharge avec [DonneesEnseignantDemo.offres].
final Provider<List<OffreClasseDemo>?> offresClassesProvider =
    Provider<List<OffreClasseDemo>?>((Ref ref) => null);

/// `ENS-06` Disponibilites : les plages hebdomadaires de l'enseignant
/// (DISPO-1, une ligne par plage), puis les Classes disponibles (EN-5).
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
    const Widget heures = PlagesDisponibilite();
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
String _jour(int jour) => jourCapitalise(jour);

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
    final String heure = LibellesGroupe.insecable(
      t.enseignant.creneaux.heure(heure: '${offre.creneau.heure}'),
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
      valeur: LibellesGroupe.valeurSeule(
        t.enseignant.creneaux.heure(heure: '${offre.creneau.heure}'),
      ),
    ),
    if (offre.dureeMinutes != null)
      LigneCleValeur(
        cle: t.enseignant.creneaux.cleDuree,
        valeur: LibellesGroupe.valeurSeule(
          t.commun.formats.minutes(minutes: '${offre.dureeMinutes}'),
        ),
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
