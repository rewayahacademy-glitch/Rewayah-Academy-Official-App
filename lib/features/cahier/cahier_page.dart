import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/enseignant/depot_cahiers.dart';
import '../../core/enseignant/modeles_enseignant.dart';
import '../../core/enseignant/service_enseignant.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/presence/vue_presence.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/ligne_presence.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/skeleton.dart';
import '../presence_correction/presence_correction.dart';
import '../presence_correction/presence_correction_page.dart';
import 'makharij.dart';
import 'vue_cahier.dart';

/// `ENS-04` : le cahier de transmission d'une seance.
///
/// **L'ecran de sortie de seance, et le seul.** On y arrive en quittant la
/// salle, jamais depuis la barre basse (`08-catalogue-ecrans.md`, fiche
/// `ENS-04`). Le branchement de la sortie de salle est pose par l'Agent Z ; cet
/// ecran garantit le reste : il se rend depuis une route a parametre, et il
/// ramene a la Journee des que le cahier est parti.
///
/// **Le principe anti-burnout commande toute la presentation.** L'ecran est
/// prerempli par `brouillon_cahier()` : presence deduite, duree calculee par la
/// base, unite de curriculum quand elle existe, evenements de seance. Tout vaut
/// « Continuer » par defaut, `BrouillonCahier.exceptions` rend les seules lignes
/// qui demandent un regard, et `toutEstNominal` ouvre le chemin d'un seul geste.
/// Aucun champ ne redemande ce que le systeme sait deja.
///
/// Ce que l'enseignant **ne peut pas** faire n'est pas grise : il n'est pas
/// rendu. Aucun selecteur de niveau, aucun changement de cycle, aucune
/// validation de palier -- `DecisionEleve` ne porte aucun champ qui le
/// permettrait, et une phrase dit pourquoi le programme est institutionnel.
class CahierPage extends ConsumerWidget {
  /// Cree le cahier d'une seance.
  const CahierPage({required this.seanceId, super.key});

  /// La seance dont on rend le cahier.
  final String seanceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<BrouillonCahier?> lecture = ref.watch(
      brouillonCahierProvider(seanceId),
    );

    return _Cahier(
      seanceId: seanceId,
      vue: VueCahier.depuis(lecture: lecture),
    );
  }
}

/// Le corps du cahier, qui porte les decisions en cours de saisie.
///
/// Les decisions vivent ici et nulle part ailleurs : aucun etat global n'est
/// cree pour un formulaire qui ne survit pas a l'ecran. Une entree absente de la
/// carte **est** la decision par defaut, « Continuer » : ainsi le chemin nominal
/// ne construit aucun objet, et rien a synchroniser quand le brouillon est relu.
class _Cahier extends ConsumerStatefulWidget {
  const _Cahier({required this.seanceId, required this.vue});

  final String seanceId;
  final VueCahier vue;

  @override
  ConsumerState<_Cahier> createState() => _CahierState();
}

class _CahierState extends ConsumerState<_Cahier> {
  final Map<String, DecisionEleve> _decisions = <String, DecisionEleve>{};
  final TextEditingController _note = TextEditingController();

  bool _envoiEnCours = false;
  bool _echecEnvoi = false;
  SortCahier? _sort;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final VueCahier vue = widget.vue;
    final SortCahier? sort = _sort;

    if (sort != null) {
      return PageShell(
        titre: t.enseignant.cahier.titre,
        actions: _retourJournee(),
        child: _ApresDepot(sort: sort),
      );
    }

    return PageShell(
      titre: t.enseignant.cahier.titre,
      actions: _actions(vue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_echecEnvoi)
            LocalFeedback(message: t.enseignant.cahier.echecEnvoi),
          switch (vue.etat) {
            EtatCahier.chargement => const Skeleton.liste(lignes: 4),
            EtatCahier.erreur => EmptyState(
              message: t.enseignant.cahier.erreur,
              invitation: t.enseignant.cahier.erreurDetail,
              icone: AppIcons.avertissement,
              libelleAction: t.commun.reessayer,
              onAction: _relire,
            ),
            EtatCahier.vide => EmptyState(
              message: t.enseignant.cahier.vide,
              invitation: t.enseignant.cahier.videDetail,
              icone: AppIcons.cahier,
              registre: RegistreVide.subi,
            ),
            EtatCahier.dejaDepose || EtatCahier.constat => _Constat(
              vue: vue,
              note: _note,
              decisions: _decisions,
              lectureSeule: vue.etat == EtatCahier.dejaDepose,
              onAjuster: _ajuster,
            ),
          },
        ],
      ),
    );
  }

  /// La zone d'action collee en bas : **un seul bouton**, jamais deux.
  ///
  /// En chargement, aucun : on ne valide pas un constat qu'on n'a pas lu. Sur un
  /// cahier deja depose, le bouton ramene a la Journee au lieu d'offrir un
  /// second depot.
  Widget? _actions(VueCahier vue) {
    if (vue.etat == EtatCahier.chargement) {
      return null;
    }
    if (vue.etat == EtatCahier.dejaDepose) {
      return _retourJournee();
    }

    return ActionPrincipale(
      libelle: switch (vue.etat) {
        EtatCahier.constat when vue.toutEstNominal =>
          t.enseignant.cahier.validerTout,
        EtatCahier.constat => t.enseignant.cahier.valider,
        // Sans constat, le libelle le dit : l'enseignant doit savoir qu'il
        // depose un cahier que la base n'a pas pu preremplir.
        _ => t.enseignant.cahier.validerSansConstat,
      },
      enCours: _envoiEnCours,
      onPress: _envoiEnCours ? null : () => unawaited(_deposer(vue)),
    );
  }

  Widget _retourJournee() => ActionPrincipale(
    libelle: t.enseignant.cahier.retourJournee,
    niveau: NiveauAction.secondaire,
    onPress: () => GoRouter.of(context).go(Routes.enseignantJournee),
  );

  void _relire() => ref.invalidate(brouillonCahierProvider(widget.seanceId));

  /// Ouvre le reglage d'un eleve : l'exception, le point phonetique, l'objectif,
  /// le travail maison, la suspension du nouveau.
  Future<void> _ajuster(ParticipantBrouillon participant) async {
    final BrouillonCahier? brouillon = widget.vue.brouillon;
    if (brouillon == null) {
      return;
    }
    final String eleveId = participant.membre.studentId;

    final DecisionEleve? decision = await AppBottomSheet.ouvrir<DecisionEleve>(
      context,
      titre: t.enseignant.cahier.ajusterPour(eleve: participant.membre.libelle),
      constructeur: (BuildContext _) => _FeuilleAjuster(
        participant: participant,
        brouillon: brouillon,
        decision: _decisions[eleveId] ?? DecisionEleve(studentId: eleveId),
      ),
    );
    if (decision == null || !mounted) {
      return;
    }
    setState(() => _decisions[eleveId] = decision);
  }

  /// Depose le cahier : une seule ecriture, une seule cle.
  ///
  /// La cle d'idempotence n'est **pas** generee ici : `FileRapports.enregistrer`
  /// la genere a la redaction, et ne la regenere jamais au rejeu. C'est elle qui
  /// permet a la contrainte d'unicite de `lesson_reports` de refuser un doublon
  /// apres une coupure.
  Future<void> _deposer(VueCahier vue) async {
    if (!vue.peutDeposer) {
      return;
    }
    setState(() {
      _envoiEnCours = true;
      _echecEnvoi = false;
    });

    final CahierARendre cahier = CahierARendre(
      seanceId: widget.seanceId,
      decisions: <DecisionEleve>[
        for (final ParticipantBrouillon p in vue.participants)
          _decisions[p.membre.studentId] ??
              DecisionEleve(studentId: p.membre.studentId),
      ],
      noteGroupe: _note.text,
    );

    try {
      final SortCahier sort = await ref
          .read(soumissionCahierProvider)
          .soumettre(cahier);
      if (!mounted) {
        return;
      }
      // Le compteur de cahiers manquants et le brouillon sont relus par leurs
      // proprietaires : aucun compteur n'est recalcule ici, la base en tient
      // deja trois.
      ref.invalidate(brouillonCahierProvider(widget.seanceId));
      ref.invalidate(cahiersEnRetardProvider);
      setState(() {
        _envoiEnCours = false;
        _sort = sort;
      });
    } on Object {
      // Un echec de file locale n'est pas un echec d'envoi : le cahier n'a pas
      // ete enregistre du tout, et l'enseignant doit pouvoir reessayer.
      if (mounted) {
        setState(() {
          _envoiEnCours = false;
          _echecEnvoi = true;
        });
      }
    }
  }
}

/// Le constat prerempli : la duree, les exceptions, puis le reste.
class _Constat extends StatelessWidget {
  const _Constat({
    required this.vue,
    required this.note,
    required this.decisions,
    required this.lectureSeule,
    required this.onAjuster,
  });

  final VueCahier vue;
  final TextEditingController note;
  final Map<String, DecisionEleve> decisions;
  final bool lectureSeule;
  final Future<void> Function(ParticipantBrouillon participant) onAjuster;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final BrouillonCahier? brouillon = vue.brouillon;
    if (brouillon == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (lectureSeule) ...<Widget>[
          AppCard(
            surface: palette.washAccent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  t.enseignant.cahier.dejaDepose,
                  style: palette.washAccent.applyTo(
                    textes.titleMedium ?? const TextStyle(),
                  ),
                ),
                Ecart.vSm,
                Text(
                  t.enseignant.cahier.dejaDeposeDetail,
                  style: palette.washAccent.applyTo(
                    textes.bodySmall ?? const TextStyle(),
                  ),
                ),
              ],
            ),
          ),
          Ecart.vXl,
        ],
        // La duree du cahier est celle que la base a calculee. Le depot sait en
        // calculer quatre autres pour la meme seance : en afficher une seconde
        // ici donnerait deux chiffres pour un meme cours.
        Text(
          brouillon.minutesInterruption > 0
              ? t.enseignant.cahier.dureeEtInterruption(
                  minutes: '${brouillon.dureeMinutes}',
                  interruption: '${brouillon.minutesInterruption}',
                )
              : t.enseignant.cahier.duree(minutes: '${brouillon.dureeMinutes}'),
          style: textes.titleMedium,
        ),
        Ecart.vXs,
        Text(
          brouillon.participants.length == 1
              ? t.enseignant.cahier.unEleve
              : t.enseignant.cahier.eleves(
                  nombre: '${brouillon.participants.length}',
                ),
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
        Ecart.vXl,
        if (vue.toutEstNominal && !lectureSeule) ...<Widget>[
          // Le chemin des 45 secondes, dit explicitement : l'enseignant n'a
          // rien a lire de plus, le bouton du bas suffit.
          AppCard(
            surface: palette.washSuccess,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  t.enseignant.cahier.toutEstNominal,
                  style: palette.washSuccess.applyTo(
                    textes.titleMedium ?? const TextStyle(),
                  ),
                ),
                Ecart.vSm,
                Text(
                  t.enseignant.cahier.toutEstNominalDetail,
                  style: palette.washSuccess.applyTo(
                    textes.bodySmall ?? const TextStyle(),
                  ),
                ),
              ],
            ),
          ),
          Ecart.vXl,
        ],
        if (vue.exceptions.isNotEmpty) ...<Widget>[
          Text(t.enseignant.cahier.exceptions, style: textes.titleSmall),
          Ecart.vXs,
          Text(
            vue.exceptions.length == 1
                ? t.enseignant.cahier.uneException
                : t.enseignant.cahier.plusieursExceptions(
                    nombre: '${vue.exceptions.length}',
                  ),
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
          Ecart.vMd,
          for (final ParticipantBrouillon p in vue.exceptions) ...<Widget>[
            _LigneEleve(
              participant: p,
              brouillon: brouillon,
              decision: decisions[p.membre.studentId],
              onAjuster: lectureSeule ? null : () => unawaited(onAjuster(p)),
            ),
            Ecart.vMd,
          ],
        ],
        if (vue.nominaux.isNotEmpty) ...<Widget>[
          Ecart.vSm,
          Text(t.enseignant.cahier.nominaux, style: textes.titleSmall),
          Ecart.vMd,
          for (final ParticipantBrouillon p in vue.nominaux) ...<Widget>[
            _LigneEleve(
              participant: p,
              brouillon: brouillon,
              decision: decisions[p.membre.studentId],
              onAjuster: lectureSeule ? null : () => unawaited(onAjuster(p)),
            ),
            Ecart.vMd,
          ],
        ],
        Ecart.vSm,
        // Le curriculum est institutionnel : l'ecran l'ecrit au lieu de poser un
        // selecteur inerte qui ne pourrait rien changer.
        Text(
          t.enseignant.cahier.curriculumFige,
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
        if (!lectureSeule) ...<Widget>[
          Ecart.vSection,
          Text(t.enseignant.cahier.noteGroupe, style: textes.titleSmall),
          Ecart.vXs,
          Text(
            t.enseignant.cahier.noteGroupeDetail,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
          Ecart.vMd,
          TextField(
            controller: note,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              labelText: t.enseignant.cahier.noteGroupe,
            ),
          ),
        ],
      ],
    );
  }
}

/// Une ligne d'eleve : son etat deduit, son unite quand elle existe, et ce que
/// l'enseignant a decide.
class _LigneEleve extends StatelessWidget {
  const _LigneEleve({
    required this.participant,
    required this.brouillon,
    required this.decision,
    required this.onAjuster,
  });

  final ParticipantBrouillon participant;
  final BrouillonCahier brouillon;
  final DecisionEleve? decision;
  final VoidCallback? onAjuster;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle discret = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final UniteCurriculum? unite = participant.unite;
    final DecisionEleve? d = decision;

    return AppCard(
      onPress: onAjuster,
      libelleSemantique: onAjuster == null
          ? null
          : t.enseignant.cahier.ajusterPour(eleve: participant.membre.libelle),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LignePresence(
            nom: participant.membre.libelle,
            vue: VuePresence.depuis(
              ligne: ligneDePresence(
                participant: participant,
                brouillon: brouillon,
              ),
              maintenant: brouillon.fin,
            ),
            // Le brouillon ne rend pas la colonne `consolide` : l'ecran se tait
            // plutot que d'affirmer qu'aucune decision humaine n'a fige l'etat.
            afficherConsolide: false,
          ),
          Ecart.vXs,
          Text(participant.membre.identifiantImmuable, style: discret),
          if (unite != null) ...<Widget>[
            Ecart.vSm,
            // Le nom humain seul fait titre. `codeTechnique` (F1-PHO-01) a une
            // interdiction UX explicite : sous-texte technique discret, jamais
            // un titre.
            Text(unite.nomHumain, style: textes.bodyMedium),
            Text(unite.codeTechnique, style: discret),
          ],
          if (participant.position case final position?) ...<Widget>[
            Ecart.vSm,
            // Lecture seule : la position appartient a l'eleve (invariant J2),
            // l'enseignant la lit pour preremplir, il ne l'ecrit jamais.
            Text(
              t.enseignant.cahier.position(
                sourate: '${position.sourate}',
                verset: '${position.verset}',
              ),
              style: discret,
            ),
          ],
          if (d != null && !d.confirme) ...<Widget>[
            Ecart.vSm,
            Text(
              t.enseignant.cahier.exceptionConsignee,
              style: textes.bodyMedium,
            ),
          ],
          if (d?.pointPhonetique != null) ...<Widget>[
            Ecart.vXs,
            Text(t.enseignant.cahier.pointPhonetiqueNote, style: discret),
          ],
        ],
      ),
    );
  }
}

/// La feuille de reglage d'un eleve.
///
/// **La correction de presence n'est pas redessinee** : c'est
/// `PresenceCorrectionPanneau`, deja teste, avec ses quatre etats de mutation et
/// sa regle de motif obligatoire, que son propre commentaire destinait « a la
/// salle enseignant ou a l'espace administration ». Le cahier le branche ici.
class _FeuilleAjuster extends StatefulWidget {
  const _FeuilleAjuster({
    required this.participant,
    required this.brouillon,
    required this.decision,
  });

  final ParticipantBrouillon participant;
  final BrouillonCahier brouillon;
  final DecisionEleve decision;

  @override
  State<_FeuilleAjuster> createState() => _FeuilleAjusterState();
}

class _FeuilleAjusterState extends State<_FeuilleAjuster> {
  late final TextEditingController _objectif = TextEditingController(
    text: widget.decision.objectifPersonnel ?? '',
  );
  late final TextEditingController _travail = TextEditingController(
    text: widget.decision.travailMaison ?? '',
  );

  late String? _motifException = widget.decision.motifException;
  late String? _phonetique = widget.decision.pointPhonetique;
  late bool _nouveauSuspendu = widget.decision.nouveauSuspendu;

  @override
  void dispose() {
    _objectif.dispose();
    _travail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle discret = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PresenceCorrectionPanneau(
          cible: PresenceCorrectionCible(
            ligne: ligneDePresence(
              participant: widget.participant,
              brouillon: widget.brouillon,
            ),
            vue: VuePresence.depuis(
              ligne: ligneDePresence(
                participant: widget.participant,
                brouillon: widget.brouillon,
              ),
              maintenant: widget.brouillon.fin,
            ),
          ),
          // Des capacites, jamais un role : un `if (role == admin)` dans un
          // ecran est un defaut (lib/CLAUDE.md). L'enseignant de la seance peut
          // signaler les deux exceptions que le contrat autorise, et rien de
          // plus.
          capacites: const PresenceCorrectionCapacites(
            peutCorriger: true,
            peutExcuser: true,
          ),
          adaptateur: _AdaptateurExceptionCahier(_consigner),
          libelles: libellesCorrectionCahier(),
        ),
        Ecart.vSection,
        Text(t.enseignant.cahier.pointPhonetique, style: textes.titleSmall),
        Ecart.vXs,
        Text(t.enseignant.cahier.pointPhonetiqueDetail, style: discret),
        Ecart.vMd,
        ChoiceCardGroup(
          options: referentielMakharij(),
          valeurInitiale: _reponseInitiale(),
          onChange: _choisirPhonetique,
        ),
        Ecart.vSection,
        Text(t.enseignant.cahier.objectif, style: textes.titleSmall),
        Ecart.vXs,
        // La marge autorisee d'un objectif personnel n'existe pas encore comme
        // regle : `CleRegle` ne porte que quatre cles, toutes en minutes ou en
        // nombre d'eleves. L'ecran ne borne donc rien avec une constante
        // inventee ; il dit ce qui encadre l'objectif
        // (`CONTRACT_REQUEST_C.md`).
        Text(t.enseignant.cahier.objectifDetail, style: discret),
        Ecart.vMd,
        TextField(
          controller: _objectif,
          maxLines: 2,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(labelText: t.enseignant.cahier.objectif),
        ),
        Ecart.vXl,
        Text(t.enseignant.cahier.travailMaison, style: textes.titleSmall),
        Ecart.vXs,
        Text(t.enseignant.cahier.travailMaisonDetail, style: discret),
        Ecart.vMd,
        TextField(
          controller: _travail,
          maxLines: 2,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            labelText: t.enseignant.cahier.travailMaison,
          ),
        ),
        Ecart.vXl,
        SettingRow(
          title: t.enseignant.cahier.suspendreNouveau,
          description: t.enseignant.cahier.suspendreNouveauDetail,
          icon: AppIcons.pause,
          controle: Switch(
            value: _nouveauSuspendu,
            onChanged: (bool actif) => setState(() => _nouveauSuspendu = actif),
          ),
        ),
        Ecart.vSection,
        // Un libelle qui lui est propre, et non « Valider » : la feuille de
        // confirmation du panneau de presence porte deja ce mot, et deux boutons
        // « Valider » sur une meme surface ne se distinguent pas.
        ActionPrincipale(
          libelle: t.enseignant.cahier.ajusterValider,
          onPress: _rendre,
        ),
      ],
    );
  }

  ReponseChoix? _reponseInitiale() {
    final String? phonetique = _phonetique;
    if (phonetique == null || phonetique.isEmpty) {
      return null;
    }
    final bool connu = referentielMakharij().any(
      (OptionChoix o) => o.valeur == phonetique,
    );
    return connu
        ? ReponseChoix(valeurs: <String>{phonetique})
        : ReponseChoix(
            valeurs: const <String>{ChoiceCardGroup.valeurAutre},
            saisieLibre: phonetique,
          );
  }

  void _choisirPhonetique(ReponseChoix reponse) {
    final String? libre = reponse.saisieLibre?.trim();
    setState(() {
      if (reponse.valeurs.contains(ChoiceCardGroup.valeurAutre)) {
        _phonetique = libre == null || libre.isEmpty ? null : libre;
      } else {
        _phonetique = reponse.valeurs.isEmpty ? null : reponse.valeurs.first;
      }
    });
  }

  /// Consigne l'exception signalee par le panneau partage.
  ///
  /// Elle part **dans le cahier**, pas dans une seconde ecriture : le contenu du
  /// cahier porte le motif, la file hors ligne porte la cle, et une seule
  /// ecriture atteint la base. L'application de l'exception a
  /// `session_presence_override` demande un adaptateur serveur qui n'existe pas
  /// encore (`CONTRACT_REQUEST_C.md`) ; l'ecrire ici ferait deux chemins vers la
  /// meme decision.
  void _consigner(PresenceCorrectionCommande commande) =>
      setState(() => _motifException = commande.motif);

  void _rendre() {
    final String objectif = _objectif.text.trim();
    final String travail = _travail.text.trim();
    final String? motif = _motifException;

    Navigator.of(context).pop(
      DecisionEleve(
        studentId: widget.participant.membre.studentId,
        confirme: motif == null,
        motifException: motif,
        pointPhonetique: _phonetique,
        objectifPersonnel: objectif.isEmpty ? null : objectif,
        travailMaison: travail.isEmpty ? null : travail,
        nouveauSuspendu: _nouveauSuspendu,
      ),
    );
  }
}

/// L'adaptateur du panneau de correction, cote cahier.
///
/// Il n'ecrit rien tout seul : il **consigne** la decision dans le cahier en
/// cours de redaction, qui partira avec sa cle d'idempotence. C'est ce qui rend
/// l'exception aussi resistante a la coupure que le reste du cahier.
class _AdaptateurExceptionCahier implements PresenceCorrectionAdaptateur {
  const _AdaptateurExceptionCahier(this._consigner);

  final void Function(PresenceCorrectionCommande commande) _consigner;

  @override
  Future<void> appliquer(PresenceCorrectionCommande commande) async =>
      _consigner(commande);
}

/// Les libelles du panneau de correction, lus depuis l'i18n.
///
/// `PresenceCorrectionLibelles` injecte treize chaines en parametres au lieu de
/// lire `t.*` : c'est une dette de son lot d'origine, pas une liberte. Cette
/// fonction est le seul endroit du cahier ou elle se paie, et elle la paie avec
/// des cles slang.
PresenceCorrectionLibelles libellesCorrectionCahier() =>
    PresenceCorrectionLibelles(
      titre: t.enseignant.cahier.exceptionTitre,
      corriger: t.enseignant.cahier.exceptionCorriger,
      excuser: t.enseignant.cahier.exceptionExcuser,
      confirmation: t.enseignant.cahier.exceptionConfirmation,
      motif: t.enseignant.cahier.exceptionMotif,
      motifRequis: t.enseignant.cahier.exceptionMotifRequis,
      confirmer: t.commun.valider,
      annuler: t.commun.annuler,
      mutationEnCours: t.enseignant.cahier.exceptionEnCours,
      succes: t.enseignant.cahier.exceptionSucces,
      erreur: t.enseignant.cahier.exceptionErreur,
      horsLigne: t.enseignant.cahier.exceptionHorsLigne,
      journalisation: t.enseignant.cahier.exceptionJournalisation,
    );

/// Ce que l'ecran dit une fois le cahier parti.
///
/// Deux sorts, deux phrases, et **aucune minuterie** : rien ne se ferme tout
/// seul ici. Un cahier qui se validerait ou se quitterait seul serait un faux
/// temoignage.
class _ApresDepot extends ConsumerWidget {
  const _ApresDepot({required this.sort});

  final SortCahier sort;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // L'etat hors ligne se lit a la source unique, par `value`, jamais par le
    // type de l'AsyncValue.
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (sort == SortCahier.enFile)
          // Le seul cas persistant prevu du produit, nomme dans le commentaire
          // de `LocalFeedback` : le rapport mis en file hors ligne, affiche tant
          // que la file n'est pas videe.
          LocalFeedback(message: t.enseignant.cahier.enFile, persistant: true),
        Ecart.vXl,
        switch (sort) {
          SortCahier.envoye => EmptyState(
            message: t.enseignant.cahier.depose,
            invitation: t.enseignant.cahier.deposeDetail,
            icone: AppIcons.succes,
            registre: RegistreVide.bonneNouvelle,
          ),
          SortCahier.enFile => EmptyState(
            message: t.enseignant.cahier.enFileTitre,
            invitation: horsLigne
                ? t.enseignant.cahier.enFileDetailHorsLigne
                : t.enseignant.cahier.enFileDetail,
            icone: AppIcons.enAttenteEnvoi,
            registre: RegistreVide.bonneNouvelle,
          ),
        },
      ],
    );
  }
}
