// La file de moderation de l'Administration des communications
// (`ModerationQueue`, spec section 5.5, section 17 COM-W04 ; COM-BR-06).
//
// Gabarit de la file des dossiers (`FileDossiers` + detail) : une file de
// lignes a gauche, le detail du signalement ouvert au centre, et la
// politique anti-promotion en contexte (la meme que la Communaute
// enseignants, `ReglesCommunaute`, COM-COMU-2), sur l'espace adaptatif du
// socle. Sur telephone : une surface a la fois, retour explicite.
//
// Tout passe par `PortModeration` du SOCLE, sans le modifier : capacites,
// file, decision. **Les actions ne se montrent qu'avec la capacite** donnee
// par le serveur (`CapacitesModeration.peut`), jamais deduite d'un role ; une
// action absente n'est pas rendue (jamais grisee). Les huit motifs et leur
// texte sont ceux du socle (`MotifSignalement.libelle`) ; la regle visee par
// un motif de la politique est celle de COM-COMU-2 (`reglePolitique`).
//
// Une decision n'est dite qu'apres l'accuse du serveur (« Décision
// enregistrée. ») ; un echec dit « pas encore confirmee » (K-59, D5), une
// capacite absente « pas encore disponible ». Aucune sanction de compte
// n'est appliquee automatiquement (spec section 5.5).
//
// Ce que la maquette montre et qui n'est pas repris : « Message d'un parent »
// et « Fichier partagé » dans la file (la moderation section 5.5 vise la
// Communaute, pas les fils metier ; UX_REVIEW L0, ecart 16).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/communications/moderation.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/carte_groupee.dart';
import '../../core/widgets/espace_travail_adaptatif.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/vue_etat_communication.dart';
import '../com_communaute/feuille_signalement_communaute.dart'
    show reglePolitique;
import '../com_communaute/regles_communaute.dart';
import '../suivi_foyer/filtres_historique.dart';
import 'annonces_planifiees.dart';

/// Les capacites de moderation de la personne connectee, relues a chaque
/// ouverture de la file.
final FutureProvider<CapacitesModeration> capacitesModerationFileProvider =
    FutureProvider.autoDispose<CapacitesModeration>(
      (Ref ref) => ref.watch(portModerationProvider).capacites(),
    );

/// La file des contenus signales, relue a chaque ouverture (le compteur
/// « Contenus en modération » des Annonces la lit aussi).
final FutureProvider<List<ElementModeration>> fileModerationProvider =
    FutureProvider.autoDispose<List<ElementModeration>>(
      (Ref ref) => ref.watch(portModerationProvider).file(),
    );

/// Vrai quand la file vient de fixtures de demonstration : la file et son
/// compteur le disent en clair. Faux en production ; seule la
/// demonstration le pose, dans sa portee (le modele du socle,
/// `ElementModeration`, ne porte pas de marque : point ouvert COM-FUS).
final Provider<bool> moderationDemonstrationProvider = Provider<bool>(
  (Ref ref) => false,
);

/// Le libelle d'une decision deja confirmee.
String libelleDecision(ActionModeration action) {
  final m = t.com.annonces.administration.moderation;
  return switch (action) {
    ActionModeration.masquer => m.masque,
    ActionModeration.restaurer => m.restaure,
    ActionModeration.rejeter => m.rejete,
    ActionModeration.approuver => m.approuve,
  };
}

/// Le libelle du bouton d'une action.
String libelleAction(ActionModeration action) {
  final m = t.com.annonces.administration.moderation;
  return switch (action) {
    ActionModeration.masquer => m.masquer,
    ActionModeration.restaurer => m.restaurer,
    ActionModeration.rejeter => m.rejeter,
    ActionModeration.approuver => m.approuver,
  };
}

/// Les actions qu'un signalement propose encore, selon la decision deja
/// confirmee pendant la visite : aucune decision, approuver, masquer ou
/// rejeter ; masque, restaurer ; sinon, plus rien.
List<ActionModeration> actionsPossibles(ActionModeration? decision) =>
    switch (decision) {
      null => const <ActionModeration>[
        ActionModeration.approuver,
        ActionModeration.masquer,
        ActionModeration.rejeter,
      ],
      ActionModeration.masquer => const <ActionModeration>[
        ActionModeration.restaurer,
      ],
      ActionModeration.restaurer ||
      ActionModeration.rejeter ||
      ActionModeration.approuver => const <ActionModeration>[],
    };

/// La file de moderation.
class FileModeration extends ConsumerStatefulWidget {
  /// Cree la file.
  const FileModeration({super.key});

  /// La cle d'une ligne de la file, pour les tests.
  static ValueKey<String> cleLigne(String id) =>
      ValueKey<String>('moderation-ligne-$id');

  /// La cle du detail d'un signalement, pour les tests.
  static ValueKey<String> cleDetail(String id) =>
      ValueKey<String>('moderation-detail-$id');

  /// La cle d'une action, pour les tests.
  static ValueKey<String> cleAction(ActionModeration action) =>
      ValueKey<String>('moderation-action-${action.name}');

  /// La cle du message d'echec d'une decision, pour les tests.
  static const ValueKey<String> cleErreur = ValueKey<String>(
    'moderation-erreur',
  );

  @override
  ConsumerState<FileModeration> createState() => _FileModerationState();
}

class _FileModerationState extends ConsumerState<FileModeration> {
  String? _selection;
  SurfaceMobile _surface = SurfaceMobile.liste;

  /// Les decisions confirmees pendant la visite, par signalement.
  final Map<String, ActionModeration> _decisions = <String, ActionModeration>{};

  /// Le message d'echec d'une decision, par signalement.
  final Map<String, String> _erreurs = <String, String>{};

  /// La decision en cours d'envoi.
  (String, ActionModeration)? _enCours;

  String? _retourLocal;

  void _ouvrir(String id) => setState(() {
    _selection = id;
    _surface = SurfaceMobile.principal;
  });

  Future<void> _appliquer(String id, ActionModeration action) async {
    if (_enCours != null) return;
    final m = t.com.annonces.administration.moderation;
    setState(() {
      _enCours = (id, action);
      _erreurs.remove(id);
      _retourLocal = null;
    });
    try {
      await ref
          .read(portModerationProvider)
          .appliquer(signalementId: id, action: action);
      if (!mounted) return;
      setState(() {
        _enCours = null;
        _decisions[id] = action;
        _retourLocal = m.enregistree;
      });
    } on CapaciteIndisponible {
      if (!mounted) return;
      setState(() {
        _enCours = null;
        _erreurs[id] = m.indisponible;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _enCours = null;
        _erreurs[id] = m.nonConfirmee;
      });
    }
  }

  void _relire() => ref
    ..invalidate(capacitesModerationFileProvider)
    ..invalidate(fileModerationProvider);

  @override
  Widget build(BuildContext context) {
    final m = t.com.annonces.administration.moderation;
    final AsyncValue<CapacitesModeration> capacitesLues = ref.watch(
      capacitesModerationFileProvider,
    );
    final AsyncValue<List<ElementModeration>> fileLue = ref.watch(
      fileModerationProvider,
    );
    final CapacitesModeration? capacites = capacitesLues.value;

    // Sans la capacite de moderer, la file n'est pas montree, meme si elle a
    // pu etre lue.
    if (capacites != null && !capacites.voitLaFile) {
      return SingleChildScrollView(
        child: EtatSysteme(
          nature: NatureEtat.accesRefuse,
          titre: m.refuseTitre,
          phrase: m.refuse,
        ),
      );
    }
    final Object? erreur = capacitesLues.error ?? fileLue.error;
    if (erreur != null) {
      return SingleChildScrollView(
        child: erreur is CapaciteIndisponible
            ? EtatSysteme(
                nature: NatureEtat.indisponible,
                titre: t.com.socle.composants.etats.indisponibleTitre,
                phrase: m.indisponible,
                dependance: erreur.dependance,
              )
            : VueEtatCommunication(
                etat: ref.watch(horsLigneProvider).value ?? false
                    ? EtatCommunication.horsLigne
                    : EtatCommunication.erreur,
                onReessayer: _relire,
              ),
      );
    }
    if (capacites == null || !fileLue.hasValue) {
      return Semantics(
        label: t.com.socle.composants.etats.chargement,
        child: const ExcludeSemantics(
          child: SingleChildScrollView(child: Skeleton.liste()),
        ),
      );
    }
    final List<ElementModeration> elements = fileLue.requireValue;
    final bool demonstration = ref.watch(moderationDemonstrationProvider);
    if (elements.isEmpty) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (demonstration) ...<Widget>[
              const MarqueDemonstration(),
              Ecart.vLg,
            ],
            EtatSysteme(
              nature: NatureEtat.aucunResultat,
              titre: m.videTitre,
              phrase: m.vide,
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        final bool uneColonne = colonnesPour(contraintes.maxWidth) == 1;
        return PopScope(
          canPop: !(uneColonne && _surface == SurfaceMobile.principal),
          onPopInvokedWithResult: (bool fait, Object? _) {
            if (!fait) setState(() => _surface = SurfaceMobile.liste);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              LocalFeedback(message: _retourLocal),
              Expanded(
                child: EspaceTravailAdaptatif(
                  liste: Padding(
                    padding: uneColonne
                        ? EdgeInsets.zero
                        : const EdgeInsetsDirectional.only(end: AppSpacing.lg),
                    child: _liste(elements, demonstration, uneColonne),
                  ),
                  principal: Padding(
                    padding: uneColonne
                        ? EdgeInsets.zero
                        : const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: _principal(elements, capacites),
                  ),
                  contexte: const _Politique(),
                  titreContexte: m.politique,
                  surfaceMobile: _surface,
                  onRetourListe: () =>
                      setState(() => _surface = SurfaceMobile.liste),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _liste(
    List<ElementModeration> elements,
    bool demonstration,
    bool uneColonne,
  ) {
    final m = t.com.annonces.administration.moderation;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          EnTeteSectionAdministration(
            titre: m.titre,
            compteur: elements.length,
            demonstration: demonstration,
          ),
          Ecart.vMd,
          GroupeReglages(
            lignes: <LigneRubrique>[
              for (final ElementModeration e in elements)
                _ligne(e, selectionnee: uneColonne ? null : e.id == _selection),
            ],
          ),
        ],
      ),
    );
  }

  LigneRubrique _ligne(ElementModeration e, {bool? selectionnee}) {
    final m = t.com.annonces.administration.moderation;
    final DateTime le = e.signaleLe.toLocal();
    final ActionModeration? decision = _decisions[e.id];
    return LigneRubrique(
      libelle: e.objet.libelle,
      libelleSemantique: m.ouvrirSemantique(
        objet: e.objet.libelle,
        motif: e.motif.libelle,
      ),
      pastille: decision != null
          ? StatusPill(
              libelle: libelleDecision(decision),
              ton: switch (decision) {
                ActionModeration.masquer => TonEtat.avertissement,
                ActionModeration.rejeter => TonEtat.neutre,
                ActionModeration.approuver ||
                ActionModeration.restaurer => TonEtat.succes,
              },
            )
          : StatusPill(
              libelle: e.motif.libelle,
              ton: reglePolitique(e.motif) == null
                  ? TonEtat.neutre
                  : TonEtat.avertissement,
            ),
      legende: m.legende(date: dateCourte(le), heure: heureMinute(le)),
      selectionnee: selectionnee,
      onPress: () => _ouvrir(e.id),
    );
  }

  Widget _principal(
    List<ElementModeration> elements,
    CapacitesModeration capacites,
  ) {
    final m = t.com.annonces.administration.moderation;
    final ElementModeration? e = elements
        .where((ElementModeration x) => x.id == _selection)
        .firstOrNull;
    if (e == null) {
      return SingleChildScrollView(
        child: EtatSysteme(
          nature: NatureEtat.aucunResultat,
          titre: m.choisirTitre,
          phrase: m.choisir,
        ),
      );
    }
    return SingleChildScrollView(
      key: FileModeration.cleDetail(e.id),
      child: _Detail(
        element: e,
        decision: _decisions[e.id],
        erreur: _erreurs[e.id],
        enCours: _enCours?.$1 == e.id ? _enCours?.$2 : null,
        actions: <ActionModeration>[
          for (final ActionModeration a in actionsPossibles(_decisions[e.id]))
            if (capacites.peut(a)) a,
        ],
        onAction: (ActionModeration a) => _appliquer(e.id, a),
      ),
    );
  }
}

/// Le detail d'un signalement : l'objet, le motif et la regle visee,
/// l'extrait nettoye par le serveur, puis les actions permises.
class _Detail extends StatelessWidget {
  const _Detail({
    required this.element,
    required this.decision,
    required this.erreur,
    required this.enCours,
    required this.actions,
    required this.onAction,
  });

  final ElementModeration element;
  final ActionModeration? decision;
  final String? erreur;
  final ActionModeration? enCours;
  final List<ActionModeration> actions;
  final ValueChanged<ActionModeration> onAction;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final m = t.com.annonces.administration.moderation;
    final DateTime le = element.signaleLe.toLocal();
    final String? regle = reglePolitique(element.motif);
    final String? destination = element.objet.destination;
    final TextStyle titre = palette.inkStrong.applyTo(
      textes.titleSmall ?? const TextStyle(),
    );
    final TextStyle corps = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final ActionModeration? d = decision;
    final String? e = erreur;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        CarteGroupee(
          sections: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Semantics(
                  header: true,
                  child: Text(
                    element.objet.libelle,
                    style: palette.inkStrong.applyTo(
                      textes.titleMedium ?? const TextStyle(),
                    ),
                  ),
                ),
                Ecart.vXs,
                Text(
                  m.legende(date: dateCourte(le), heure: heureMinute(le)),
                  style: corps,
                ),
                if (d != null) ...<Widget>[
                  Ecart.vSm,
                  StatusPill(
                    libelle: libelleDecision(d),
                    ton: d == ActionModeration.masquer
                        ? TonEtat.avertissement
                        : TonEtat.succes,
                  ),
                ],
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(m.motif(motif: element.motif.libelle), style: titre),
                if (regle != null) ...<Widget>[
                  Ecart.vXs,
                  Text(m.regle, style: corps),
                  Text(
                    regle,
                    style: palette.inkStrong.applyTo(
                      textes.bodyMedium ?? const TextStyle(),
                    ),
                  ),
                ],
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(m.extraitTitre, style: titre),
                Ecart.vXs,
                Text(
                  element.extrait ?? m.extraitAbsent,
                  style: element.extrait == null
                      ? corps
                      : palette.inkStrong.applyTo(
                          textes.bodyMedium ?? const TextStyle(),
                        ),
                ),
              ],
            ),
          ],
        ),
        Ecart.vLg,
        if (actions.isNotEmpty)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: RangeeActions(
              children: <Widget>[
                for (final ActionModeration a in actions)
                  ActionPrincipale(
                    key: FileModeration.cleAction(a),
                    libelle: libelleAction(a),
                    niveau: NiveauAction.secondaire,
                    pleineLargeur: false,
                    enCours: enCours == a,
                    onPress: () => onAction(a),
                  ),
              ],
            ),
          )
        else if (d == null)
          Text(m.sansAction, style: corps),
        if (e != null) ...<Widget>[
          Ecart.vMd,
          Semantics(
            liveRegion: true,
            child: Text(
              e,
              key: FileModeration.cleErreur,
              style: palette.inkAlert.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
        ],
        if (destination != null) ...<Widget>[
          Ecart.vMd,
          LienFleche(
            libelle: m.contexte,
            onPress: () => GoRouter.of(context).go(destination),
          ),
        ],
      ],
    );
  }
}

/// La politique anti-promotion, en contexte de la file : les regles de la
/// Communaute (COM-COMU-2), puis l'absence de sanction automatique.
class _Politique extends StatelessWidget {
  const _Politique();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const ReglesCommunaute(),
        Ecart.vMd,
        Text(
          t.com.annonces.administration.moderation.sansSanction,
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
      ],
    );
  }
}
