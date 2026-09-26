import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/tc_bibliotheque/content_position.dart';
import '../../core/tc_classe/teacher_student_projection.dart';
import '../../core/tc_outils/learning_assignment.dart';
import '../../core/tc_parcours/libelles_parcours.dart';
import '../../core/tc_parcours/plage_lisible.dart';
import '../../core/tc_parcours/port_post_cours.dart';
import '../../core/tc_parcours/post_cours_vm.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';

/// Le panneau d'apres-cours (spec section 9.5).
///
/// **Ce panneau ne refait pas le cahier de transmission `ENS-04`.** Le cahier
/// existe, il est teste, il porte deja la presence deduite, la duree calculee
/// par la base et la confirmation par eleve. Ce panneau porte ce qui lui
/// manquait : la **position de reprise proposee** et le **travail propose**,
/// deduits de ce qui a ete presente pendant la seance. Agent Z le pose sous le
/// constat du cahier ; il ne le remplace pas.
///
/// **Tout est prerempli, l'enseignant ne saisit que les exceptions.** Le seul
/// champ de texte est facultatif, et le chemin nominal est un seul geste : c'est
/// la cible des 45 secondes, et c'est la seule facon de la tenir.
class PanneauPostCours extends ConsumerStatefulWidget {
  /// Cree le panneau d'une seance.
  const PanneauPostCours({required this.sessionId, this.onTermine, super.key});

  /// La seance que l'on cloture.
  final String sessionId;

  /// Ce que l'hote fait une fois le post-cours enregistre.
  ///
  /// Recoit le sort du compte rendu : parti, ou en file jusqu'au retour du
  /// reseau. `null` laisse le panneau afficher lui-meme le resultat.
  final void Function(SortPostCours sort)? onTermine;

  @override
  ConsumerState<PanneauPostCours> createState() => _PanneauPostCoursState();
}

class _PanneauPostCoursState extends ConsumerState<PanneauPostCours> {
  final TextEditingController _notes = TextEditingController();

  bool _envoi = false;
  SortPostCours? _sort;
  String? _erreur;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<PostCoursVM> lecture = ref.watch(
      postCoursProvider(widget.sessionId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(titre: t.tc.parcours.postCours.titre),
        Ecart.vMd,
        _corps(context, lecture),
      ],
    );
  }

  /// Les quatre etats, lus par `hasValue` / `hasError`.
  Widget _corps(BuildContext context, AsyncValue<PostCoursVM> lecture) {
    if (!lecture.hasValue) {
      if (lecture.hasError) {
        return EmptyState(
          message: t.tc.parcours.postCours.repriseInconnue,
          libelleAction: t.tc.parcours.postCours.valider,
          onAction: () => ref.invalidate(postCoursProvider(widget.sessionId)),
        );
      }
      return const Skeleton.liste(lignes: 3);
    }

    final PostCoursVM postCours = lecture.requireValue;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // 1. CE QUE LE SYSTEME SAIT DEJA, en premier et sans champ.
        Text(
          t.tc.parcours.postCours.duree(
            minutes: postCours.dureeReelle.inMinutes,
          ),
          style: textes.bodyMedium,
        ),
        Ecart.vMd,
        _Exceptions(postCours: postCours),
        Ecart.vXl,

        // 2. CE QUE LE SYSTEME PROPOSE.
        _Reprise(position: postCours.positionDeRepriseProposee),
        Ecart.vXl,
        _Travail(travaux: postCours.travailPropose),
        Ecart.vXl,

        // 3. CE QUE L'ENSEIGNANT AJOUTE, en dernier, et facultatif.
        TextField(
          controller: _notes,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: t.tc.parcours.postCours.exceptions,
          ),
        ),
        Ecart.vLg,

        if (_sort case final SortPostCours sort) ...<Widget>[
          Text(
            sort == SortPostCours.enFile
                ? t.tc.parcours.postCours.enFile
                : t.tc.parcours.postCours.envoye,
            textAlign: TextAlign.center,
            style: textes.bodyMedium,
          ),
        ] else
          ActionPrincipale(
            libelle: t.tc.parcours.postCours.valider,
            enCours: _envoi,
            onPress: () => _valider(postCours),
          ),

        if (_erreur case final String message) ...<Widget>[
          Ecart.vMd,
          Text(
            message,
            textAlign: TextAlign.center,
            style: palette.inkAlert.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _valider(PostCoursVM postCours) async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });

    final PortPostCours port = ref.read(portPostCoursProvider);
    final PostCoursVM saisie = postCours.avecNotes(_notes.text);
    try {
      final SortPostCours sort = await port.enregistrer(saisie);
      if (!mounted) {
        return;
      }
      setState(() {
        _envoi = false;
        _sort = sort;
      });
      widget.onTermine?.call(sort);
    } on Object {
      if (mounted) {
        setState(() {
          _envoi = false;
          _erreur = t.tc.parcours.signalement.echec;
        });
      }
    }
  }
}

/// Les eleves qui demandent un regard, et eux seuls.
class _Exceptions extends StatelessWidget {
  const _Exceptions({required this.postCours});

  final PostCoursVM postCours;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;

    if (postCours.toutEstNominal) {
      // Le chemin des 45 secondes, dit explicitement : l'enseignant n'a rien a
      // lire de plus, le bouton du bas suffit.
      return Text(
        t.tc.parcours.postCours.toutEstNominal,
        style: textes.bodyMedium,
      );
    }

    final List<TeacherStudentProjection> exceptions = postCours.exceptions;
    if (exceptions.isEmpty) {
      // Ni nominal, ni exception : le roster n'est pas projete. On se tait
      // plutot que d'affirmer que la seance etait deserte.
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(t.tc.parcours.postCours.exceptions, style: textes.titleSmall),
        Ecart.vSm,
        for (final TeacherStudentProjection eleve in exceptions) ...<Widget>[
          AppCard(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    // Prenom seul, et l'identifiant d'academie en desambiguation
                    // -- jamais un nom de famille, pas meme une initiale.
                    '${eleve.firstName} ${eleve.academyId}',
                    style: textes.bodyMedium,
                  ),
                ),
                Ecart.hSm,
                StatusPill(
                  libelle: eleve.liveStatus.valeurSql,
                  ton: TonEtat.avertissement,
                ),
              ],
            ),
          ),
          Ecart.vSm,
        ],
      ],
    );
  }
}

/// La position de reprise proposee.
class _Reprise extends StatelessWidget {
  const _Reprise({this.position});

  final ContentPosition? position;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final ContentPosition? position = this.position;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(t.tc.parcours.postCours.reprise, style: textes.titleSmall),
        Ecart.vSm,
        Text(
          position == null
              ? t.tc.parcours.postCours.repriseInconnue
              : positionLisible(position),
          style: position == null
              ? palette.inkMuted.applyTo(textes.bodySmall ?? const TextStyle())
              : textes.bodyMedium,
        ),
      ],
    );
  }
}

/// Le travail propose pour la suite.
class _Travail extends StatelessWidget {
  const _Travail({required this.travaux});

  final List<LearningAssignment> travaux;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(t.tc.parcours.postCours.travail, style: textes.titleSmall),
        Ecart.vSm,
        if (travaux.isEmpty)
          Text(
            t.tc.parcours.postCours.travailAucun,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          )
        else
          for (final LearningAssignment travail in travaux) ...<Widget>[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: StatusPill(
                      libelle: libelleIntentionParcours(travail.purpose),
                      ton: TonEtat.neutre,
                    ),
                  ),
                  Ecart.vSm,
                  Text(
                    travail.contentRange == null
                        ? t.tc.parcours.plage.ressource
                        : plageLisible(travail.contentRange!),
                    style: textes.bodyMedium,
                  ),
                ],
              ),
            ),
            Ecart.vSm,
          ],
      ],
    );
  }
}
