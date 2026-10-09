import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/enums.dart';
import '../../core/dossier/resignature_contrat.dart';
import '../../core/dossier/service_dossier.dart';
import '../../core/dossier/versions_contrat.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/profil/service_acceptations.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/page_shell.dart';
import '../connexion/recuperation_page.dart'
    show IssueEnvoiLien, issueEchecEnvoi;
import '../consentements/texte_observation.dart';
import 'politique_controle.dart';

/// Un paragraphe d'un texte a signer : son titre en gras, puis son corps.
typedef ParagrapheTexte = ({String titre, String? corps});

/// Le texte A3 valide le 02/10/2026 (tuteur, eleve adulte), paragraphe par
/// paragraphe, mot pour mot (`t.contrat.a3`).
List<ParagrapheTexte> paragraphesA3() => <ParagrapheTexte>[
  (titre: t.contrat.a3.quoiTitre, corps: t.contrat.a3.quoi),
  (titre: t.contrat.a3.pourquoiTitre, corps: t.contrat.a3.pourquoi),
  (titre: t.contrat.a3.quiTitre, corps: t.contrat.a3.qui),
  (
    titre: t.contrat.a3.dureeTitre,
    corps: t.contrat.a3.duree(duree: VersionsContrat.dureeEnregistrementJours),
  ),
  (titre: t.contrat.a3.desaccordTitre, corps: t.contrat.a3.desaccord),
];

/// La version enseignant E1 : le texte A3 corrige, la phrase du compte rendu
/// ajoutee au controle, le « Pourquoi » complete et « Si vous refusez » propre
/// a l'enseignant (`t.contrat.e1`).
List<ParagrapheTexte> paragraphesE1() => <ParagrapheTexte>[
  (titre: t.contrat.a3.quoiTitre, corps: t.contrat.e1.quoi),
  (titre: t.contrat.a3.pourquoiTitre, corps: t.contrat.e1.pourquoi),
  (titre: t.contrat.a3.quiTitre, corps: t.contrat.a3.qui),
  (
    titre: t.contrat.a3.dureeTitre,
    corps: t.contrat.a3.duree(duree: VersionsContrat.dureeEnregistrementJours),
  ),
  (titre: t.contrat.e1.refusTitre, corps: t.contrat.e1.refus),
];

/// Le role lu dans l'etat du dossier ; tuteur par defaut. Il ne sert qu'a
/// choisir la sorte de contrat ([SorteContrat.pour], dans le domaine) : la
/// page lit ensuite cette sorte, jamais le role.
AppRole _role(WidgetRef ref) =>
    ref.watch(etatDossierProvider).value?.role ?? AppRole.guardian;

/// Vrai si le texte a signer est le contrat enseignant : c'est cette sorte,
/// et non le role, qui porte E1, la clause des visites et la case art. 9.
bool _contratEnseignant(WidgetRef ref) =>
    SorteContrat.pour(_role(ref)) == SorteContrat.contratEnseignant;

/// La carte a accuser une fois (ADR-011).
///
/// **Elle vient avant le contrat, pas apres.** Les deux dispositifs qu'elle
/// nomme, l'enregistrement audio et la visite de controle, figurent aussi dans
/// le contrat ; mais une clause signee au milieu d'un texte long n'informe
/// personne, et « un enseignant qui decouvre le dispositif apres coup est un
/// litige » (ADR-011). Cette carte est courte pour etre lue.
///
/// Depuis la version [VersionsContrat.textesJuridiques], elle porte le texte
/// A3 valide (E1 pour l'enseignant).
class AccusePage extends ConsumerWidget {
  /// Cree la carte d'accuse.
  const AccusePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool enseignant = _contratEnseignant(ref);
    return _PageASigner(
      titre: t.contrat.a3.titre,
      libelleAction: t.contrat.a3.jaiLu,
      sorte: SorteContrat.accuseEnregistrementControle,
      version: VersionsContrat.pour(SorteContrat.accuseEnregistrementControle),
      paragraphes: enseignant ? paragraphesE1() : paragraphesA3(),
    );
  }
}

/// Le contrat propre au role : conditions du tuteur, ou non-concurrence de
/// l'enseignant.
///
/// Pour le tuteur, la version signee est celle qui ajoute le paragraphe des
/// visites d'observation (03 section 1 bis-2 et 3) au texte existant, notice
/// d'enregistrement comprise (texte A3 valide le 02/10) ; la case d'accord
/// n'est jamais precochee. `?pour=moi` donne la variante eleve adulte.
///
/// Pour l'enseignant : le texte E1, l'occultation des coordonnees, puis la
/// clause des visites de controle en paragraphe separe au-dessus de la
/// signature, et la case separee de l'article 9, jamais precochee, sans
/// laquelle la signature reste fermee (`POLITIQUE_CONTROLE_ENSEIGNANTS.md`,
/// partie A).
///
/// La clause est suivie du lien « Lire la politique de controle » : la piece
/// qu'elle fait « confirmer avoir recue » s'ouvre en lecture
/// ([ouvrirPolitiqueControle]), avant la signature.
///
/// **Garde-fou** ([VersionsContrat.politiqueControlePubliee], vrai depuis le
/// 05/10/2026) : s'il repasse a faux, un vrai enseignant lit et signe la
/// version [VersionsContrat.courante], ses textes d'origine gardes tels quels
/// (`t.contrat.intro`, `pointEnregistrement`, `pointControle`,
/// `pointCoordonnees`), sans la clause ni la case ; la demonstration seule
/// montre alors la version [VersionsContrat.textesJuridiques].
class ContratPage extends ConsumerWidget {
  /// Cree la page de contrat.
  const ContratPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SorteContrat sorte = SorteContrat.pour(_role(ref));
    final bool enseignant = sorte == SorteContrat.contratEnseignant;
    final String version = VersionsContrat.pour(
      sorte,
      demonstration: ref.watch(serviceDossierProvider).demonstration,
      politiquePubliee: ref.watch(politiqueControlePublieeProvider),
    );
    if (enseignant && version == VersionsContrat.courante) {
      return _PageASigner(
        titre: t.contrat.titre,
        introduction: t.contrat.intro,
        libelleAction: t.contrat.accepter,
        sorte: sorte,
        version: version,
        paragraphes: <ParagrapheTexte>[
          (titre: t.contrat.pointEnregistrement, corps: null),
          (titre: t.contrat.pointControle, corps: null),
          (titre: t.contrat.pointCoordonnees, corps: null),
        ],
      );
    }
    String? pour;
    try {
      pour = GoRouterState.of(context).uri.queryParameters['pour'];
    } on Object {
      pour = null;
    }

    // Nouvelle signature (Q-2 = a, 05/10/2026) : politique publiee, contrat
    // 2026-09 deja signe ; une phrase courte dit pourquoi au-dessus du texte.
    final bool resignature =
        enseignant && ref.watch(resignatureContratEnseignantProvider);
    return _PageASigner(
      titre: t.contrat.titre,
      introduction: resignature ? t.contrat.resignature : null,
      resignature: resignature,
      libelleAction: t.contrat.accepter,
      sorte: sorte,
      version: version,
      paragraphes: <ParagrapheTexte>[
        ...enseignant ? paragraphesE1() : paragraphesA3(),
        // L'occultation des coordonnees ne concerne que l'enseignant : c'est ce
        // qu'il accepte, et c'est aussi le controle anti-pillage central de
        // l'ADR-008.
        if (enseignant) (titre: t.contrat.pointCoordonnees, corps: null),
      ],
      clause: enseignant
          ? (
              titre: t.contrat.clauseControle.titre,
              corps: t.contrat.clauseControle.texte,
            )
          : null,
      caseReligion: enseignant,
      observation: enseignant
          ? null
          : VarianteObservation.depuisParametre(pour),
    );
  }
}

/// La coquille commune : les paragraphes en clair dans UNE carte groupee, la
/// clause et les cases s'il y en a, un bouton, rien d'autre.
class _PageASigner extends ConsumerStatefulWidget {
  const _PageASigner({
    required this.titre,
    required this.libelleAction,
    required this.sorte,
    required this.version,
    required this.paragraphes,
    this.introduction,
    this.clause,
    this.caseReligion = false,
    this.observation,
    this.resignature = false,
  });

  final String titre;
  final String libelleAction;
  final SorteContrat sorte;

  /// La version enregistree a la signature : celle du texte affiche.
  final String version;

  final List<ParagrapheTexte> paragraphes;

  /// Le chapeau au-dessus des paragraphes (version 2026-09 du contrat).
  final String? introduction;

  /// Un paragraphe separe, au-dessus de la signature (clause enseignant).
  final ParagrapheTexte? clause;

  /// Vrai : la case separee de l'article 9 (enseignant), requise pour signer.
  final bool caseReligion;

  /// Avec une variante, le paragraphe des visites d'observation et sa case.
  final VarianteObservation? observation;

  /// Vrai : nouvelle signature du contrat enseignant (Q-2 = a). Apres la
  /// signature, les acceptations sont relues avant de partir, pour que la
  /// redirection ne ramene pas ici.
  final bool resignature;

  @override
  ConsumerState<_PageASigner> createState() => _PageASignerState();
}

class _PageASignerState extends ConsumerState<_PageASigner> {
  bool _envoi = false;
  bool _cochee = false;
  bool _religionCochee = false;
  String? _erreur;

  bool get _signable =>
      (widget.observation == null || _cochee) &&
      (!widget.caseReligion || _religionCochee);

  Future<void> _signer() async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(serviceDossierProvider)
          .accepterContrat(widget.sorte, widget.version);
      ref.invalidate(etatDossierProvider);
      if (widget.resignature) {
        // Une relecture en echec n'annule pas la signature, deja enregistree :
        // la redirection se reposera la question a la lecture suivante.
        try {
          ref.invalidate(acceptationsProvider);
          await ref.read(acceptationsProvider.future);
        } on Object {
          // Rien : voir ci-dessus.
        }
      }
      if (mounted) {
        GoRouter.of(context).go(Routes.attente);
      }
    } on Object catch (e) {
      if (mounted) {
        setState(
          () => _erreur = issueEchecEnvoi(e) == IssueEnvoiLien.horsLigne
              ? t.contrat.horsLigne
              : t.contrat.erreur,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _envoi = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final VarianteObservation? observation = widget.observation;
    final ParagrapheTexte? clause = widget.clause;

    return PageShell(
      titre: widget.titre,
      onRetour: () => GoRouter.of(context).go(Routes.attente),
      actions: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (_erreur != null) ...<Widget>[
            Semantics(
              liveRegion: true,
              child: Text(
                _erreur!,
                textAlign: TextAlign.center,
                style: palette.inkAlert.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vMd,
          ],
          ActionPrincipale(
            libelle: widget.libelleAction,
            onPress: _signable ? () => unawaited(_signer()) : null,
            enCours: _envoi,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (widget.introduction case final String intro) ...<Widget>[
            Text(intro, style: textes.bodyMedium),
            Ecart.vXl,
          ],
          GroupeReglages(
            lignes: <LigneRubrique>[
              for (final ParagrapheTexte p in widget.paragraphes)
                LigneRubrique(
                  icone: AppIcons.controleQualite,
                  libelle: p.titre,
                  legende: p.corps,
                ),
            ],
          ),
          if (clause != null) ...<Widget>[
            Ecart.vXl,
            GroupeReglages(
              lignes: <LigneRubrique>[
                LigneRubrique(
                  icone: AppIcons.controleQualite,
                  libelle: clause.titre,
                  legende: clause.corps,
                ),
              ],
            ),
            // La politique que la clause fait « confirmer avoir recue », a
            // lire avant de signer : un lien, jamais un second bouton plein
            // (K-56).
            LienFleche(
              libelle: t.contrat.politique.lien,
              onPress: () => unawaited(ouvrirPolitiqueControle(context)),
            ),
          ],
          if (widget.caseReligion) ...<Widget>[
            Ecart.vXl,
            CaseAccordTexte(
              libelle: t.contrat.clauseControle.caseReligion,
              cochee: _religionCochee,
              onChanged: _envoi
                  ? null
                  : (bool v) => setState(() => _religionCochee = v),
            ),
          ],
          if (observation != null) ...<Widget>[
            Ecart.vXxl,
            Text(t.consentement.texte.titre, style: textes.titleMedium),
            Ecart.vMd,
            TexteObservation(variante: observation),
            Ecart.vXl,
            CaseAccordObservation(
              variante: observation,
              cochee: _cochee,
              onChanged: _envoi
                  ? null
                  : (bool v) => setState(() => _cochee = v),
            ),
          ],
        ],
      ),
    );
  }
}
