import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/tc_classe/controleur_recitation.dart';
import '../../core/tc_classe/port_rappel_discret.dart';
import '../../core/tc_classe/rappel_discret.dart';
import '../../core/tc_classe/teacher_student_projection.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/status_pill.dart';
import 'roster_classe.dart';

/// La fiche pedagogique de seance (spec section 10.1).
///
/// **Connaissance pedagogique forte, connaissance privee minimale.** Elle ne
/// lit que [TeacherStudentProjection], et ce type ne porte ni telephone, ni
/// email, ni adresse, ni identite de tuteur, ni paiement, ni nom de famille --
/// pas meme une initiale (decision D-08). Ce fichier n'a donc **aucune barriere
/// a poser** : il n'y a rien a masquer, parce que rien n'est livre.
///
/// Les quatre actions frequentes ne changent **ni la page, ni le focus, ni le
/// stylet, ni le support** (contrat section 12, invariant 6). Deux sont
/// branchees ici -- le rappel discret et la recitation -- et deux attendent leur
/// proprietaire : « Noter » appartient au cahier du chantier enseignant, et
/// « Signaler un besoin » a `PortSignalement` d'Agent H. Elles sont donc des
/// rappels de fonction : **absentes tant qu'elles ne peuvent pas aboutir**,
/// jamais grisees. Un bouton visible mais inerte invite a appuyer dessus ; son
/// absence ne pose pas la question.
class FicheSeance extends ConsumerStatefulWidget {
  /// Cree la fiche d'un eleve.
  const FicheSeance({
    required this.eleve,
    required this.sessionId,
    super.key,
    this.onNoter,
    this.onSignaler,
    this.onOuvrirContexte,
  });

  /// L'eleve concerne.
  final TeacherStudentProjection eleve;

  /// La seance en cours, pour le rappel discret et la recitation.
  final String sessionId;

  /// Ouvre le cahier de seance. Branche par Agent Z.
  final VoidCallback? onNoter;

  /// Ouvre le signalement d'Agent H. Branche par Agent Z.
  final VoidCallback? onSignaler;

  /// Ouvre le contexte pedagogique complet. Branche par Agent Z.
  final VoidCallback? onOuvrirContexte;

  @override
  ConsumerState<FicheSeance> createState() => _FicheSeanceEtat();
}

class _FicheSeanceEtat extends ConsumerState<FicheSeance> {
  /// Le **seul** message que la fiche affiche.
  ///
  /// Le rappel reussi ne produit rien : ni coche, ni bandeau, ni accuse. La spec
  /// section 10.2 interdit la boucle « envoye / revenu / confirme », et ce champ
  /// reste donc `null` dans le cas nominal.
  String? _echec;

  Future<void> _rappeler() async {
    final PortRappelDiscret rappel = ref.read(portRappelDiscretProvider);
    try {
      await rappel.rappeler(
        sessionId: widget.sessionId,
        academyId: widget.eleve.academyId,
      );
      // Reussite silencieuse. Rien ne s'affiche, volontairement.
      if (mounted) {
        setState(() => _echec = null);
      }
    } on EchecRappel catch (echec) {
      if (!mounted) {
        return;
      }
      setState(() => _echec = _messageEchec(echec, rappel));
    }
  }

  /// Le message d'echec, choisi sur le motif.
  ///
  /// Le cooldown se dit **sans reproche** : ce n'est pas une erreur de
  /// l'enseignant, c'est la protection contre le spam, et elle annonce quand
  /// l'action redeviendra possible.
  String _messageEchec(EchecRappel echec, PortRappelDiscret rappel) =>
      switch (echec.motif) {
        MotifEchecRappel.cooldown => t.tc.classe.rappel.cooldown(
          secondes:
              (rappel.cooldownRestant(
                        sessionId: widget.sessionId,
                        academyId: widget.eleve.academyId,
                      ) ??
                      rappel.cooldown)
                  .inSeconds,
        ),
        MotifEchecRappel.droitRefuse => t.tc.classe.rappel.echecDroit,
        MotifEchecRappel.transport => t.tc.classe.rappel.echec,
      };

  void _donnerLaParole() {
    ref
        .read(recitationProvider.notifier)
        .donnerLaParoleA(widget.eleve.academyId);
  }

  @override
  Widget build(BuildContext context) {
    final TeacherStudentProjection eleve = widget.eleve;
    final TextTheme textes = Theme.of(context).textTheme;
    final bool recite =
        ref.watch(recitationProvider).actif == eleve.academyId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Prenom et identifiant d'academie, l'un sous l'autre. L'identifiant
        // remplace le nom de famille dans toute desambiguisation (ADR-008).
        Text(eleve.firstName, style: textes.titleLarge ?? const TextStyle()),
        Text(eleve.academyId, style: textes.labelMedium ?? const TextStyle()),
        Ecart.vSm,
        Row(
          children: <Widget>[
            StatusPill(
              libelle: libelleEtatProjete(eleve.liveStatus),
              ton: tonEtatProjete(eleve.liveStatus),
            ),
            // « Interface guidee », JAMAIS « mode enfant » (decision D-07).
            if (eleve.interfaceGuidee) ...<Widget>[
              Ecart.hSm,
              StatusPill(
                libelle: t.tc.classe.fiche.interfaceGuidee,
                ton: TonEtat.accent,
              ),
            ],
          ],
        ),
        Ecart.vLg,
        if (eleve.aDuContenuPedagogique)
          _Faits(eleve: eleve)
        else
          // **Le serveur ne projette pas encore le domaine Pedagogie pour
          // l'enseignant** : `programme_*`, `progression_*` et `evaluations`
          // sont admin-only, et `student_reading_position` n'accorde aucune
          // lecture a l'enseignant. Une fiche blanche laisserait croire que
          // l'eleve n'a pas de parcours ; ce texte dit que la donnee n'est pas
          // ouverte. Demande en section 1 de `TC_CONTRACT_REQUEST_E.md`.
          EmptyState(
            message: t.tc.classe.fiche.sansPedagogie,
            invitation: t.tc.classe.fiche.sansPedagogieDetail,
            registre: RegistreVide.subi,
          ),
        Ecart.vLg,
        _Actions(
          recite: recite,
          onRappel: () => unawaited(_rappeler()),
          onReciter: _donnerLaParole,
          onNoter: widget.onNoter,
          onSignaler: widget.onSignaler,
          onOuvrirContexte: widget.onOuvrirContexte,
        ),
        // Le message n'existe que dans le cas d'echec. Dans le cas nominal,
        // cette ligne ne rend rien du tout.
        LocalFeedback(message: _echec),
      ],
    );
  }
}

/// Les faits pedagogiques, chacun avec son intitule.
///
/// Un fait absent **ne s'affiche pas** plutot que de s'afficher vide : une ligne
/// « Derniere seance : - » occupe la place d'une ligne utile et se lit comme un
/// zero. L'absence de la ligne dit la meme chose sans mentir.
class _Faits extends StatelessWidget {
  const _Faits({required this.eleve});

  final TeacherStudentProjection eleve;

  @override
  Widget build(BuildContext context) {
    final ResumeSeance? derniere = eleve.lastLesson;
    final AssiduiteRecente? assiduite = eleve.recentAttendance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (eleve.level case final String niveau)
          _Fait(intitule: t.tc.classe.fiche.niveau, valeur: niveau),
        if (eleve.activeGoals.isNotEmpty)
          _Fait(
            intitule: t.tc.classe.fiche.objectif,
            valeur: eleve.activeGoals.first,
          ),
        if (derniere?.positionAtteinte?.page case final int page)
          _Fait(
            intitule: t.tc.classe.fiche.derniereSeance,
            valeur: t.tc.classe.fiche.page(page: page),
          ),
        if (derniere?.pointARevoir case final String point)
          _Fait(intitule: t.tc.classe.fiche.aReprendre, valeur: point),
        if (assiduite != null)
          _Fait(
            intitule: t.tc.classe.fiche.presenceRecente,
            valeur: t.tc.classe.fiche.assiduite(
              presences: assiduite.presences,
              total: assiduite.total,
            ),
          ),
        if (eleve.currentAssignments.isNotEmpty)
          _Fait(
            intitule: t.tc.classe.fiche.travailActuel,
            valeur: t.tc.classe.fiche.travailEnCours(
              nombre: eleve.currentAssignments.length,
            ),
          ),
      ],
    );
  }
}

class _Fait extends StatelessWidget {
  const _Fait({required this.intitule, required this.valeur});

  final String intitule;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;

    // Une seule lecture pour les technologies d'assistance : l'intitule puis sa
    // valeur. Deux noeuds separes feraient deux annonces pour un seul fait.
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(intitule, style: textes.labelSmall ?? const TextStyle()),
            Text(valeur, style: textes.bodyMedium ?? const TextStyle()),
          ],
        ),
      ),
    );
  }
}

/// Les actions frequentes de la fiche.
///
/// **Aucune n'ouvre un micro a distance, aucune ne touche au support.** Le
/// professeur corrige en parlant a son propre micro (decision D-10).
class _Actions extends StatelessWidget {
  const _Actions({
    required this.recite,
    required this.onRappel,
    required this.onReciter,
    required this.onNoter,
    required this.onSignaler,
    required this.onOuvrirContexte,
  });

  final bool recite;
  final VoidCallback onRappel;
  final VoidCallback onReciter;
  final VoidCallback? onNoter;
  final VoidCallback? onSignaler;
  final VoidCallback? onOuvrirContexte;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        ActionPrincipale(
          libelle: t.tc.classe.action.rappel,
          onPress: onRappel,
          niveau: NiveauAction.secondaire,
          pleineLargeur: false,
        ),
        ActionPrincipale(
          libelle: t.tc.classe.action.reciter,
          // Rendre la parole n'est pas une action de la fiche : on la reprend
          // en la donnant a quelqu'un d'autre, ou on l'arrete depuis la file.
          onPress: recite ? null : onReciter,
          niveau: NiveauAction.secondaire,
          pleineLargeur: false,
        ),
        if (onNoter != null)
          ActionPrincipale(
            libelle: t.tc.classe.action.noter,
            onPress: onNoter,
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
          ),
        if (onSignaler != null)
          ActionPrincipale(
            libelle: t.tc.classe.action.signaler,
            onPress: onSignaler,
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
          ),
        if (onOuvrirContexte != null)
          ActionPrincipale(
            libelle: t.tc.classe.action.contexte,
            onPress: onOuvrirContexte,
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
          ),
      ],
    );
  }
}
