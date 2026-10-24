// Les reponses enregistrees de « Vos autres talents » (`CAND-07`), en lecture :
// ce que la personne a donne, ce que cela permet, et ce qu'elle peut en faire.
//
// Une personne revient ici pour **modifier** (« Modifier mes reponses », le seul
// bouton plein) ou **retirer** ses reponses et son accord, a tout moment
// (proposition, section 5). Quand sa candidature d'enseignant est terminee
// (refusee ou retiree), elle ne peut plus modifier, seulement retirer : la page
// le dit. Retirer demande confirmation et dit l'effet avant le geste ; le
// succes ne se dit qu'apres la reponse du serveur.
//
// Hors ligne, rien ne s'ecrit : « Retirer mes reponses » n'est pas rendu, une
// phrase dit quand ce sera possible.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/modeles_autres_competences.dart';
import '../../core/candidature/port_autres_competences.dart';
import '../../core/candidature/port_ma_candidature.dart'
    show HorsLigneCandidature, nouvelleCleIdempotence;
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/carte_groupee.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/page_shell.dart';
import 'libelles_talents.dart';

/// La date d'un instant UTC, dans le fuseau de la personne.
String jourTalents(DateTime d) {
  final DateTime l = d.toLocal();
  return isolerSens(
    '${l.day.toString().padLeft(2, '0')}/'
    '${l.month.toString().padLeft(2, '0')}/${l.year}',
  );
}

/// La lecture des reponses enregistrees.
class LectureTalents extends ConsumerStatefulWidget {
  /// Cree la lecture.
  const LectureTalents({
    required this.lecture,
    required this.onRetire,
    this.onModifier,
    this.message,
    super.key,
  });

  /// Ce que le serveur a rendu : les reponses, la version, le catalogue.
  final AutresCompetences lecture;

  /// Ouvre le parcours de modification ; `null` quand la candidature d'enseignant
  /// est terminee (la page ne propose alors que le retrait).
  final VoidCallback? onModifier;

  /// Appele quand le serveur a confirme le retrait.
  final VoidCallback onRetire;

  /// Un message a dire en tete (les reponses ont change ailleurs, par exemple).
  final String? message;

  /// La cle de la carte qui dit que les reponses sont enregistrees.
  static const Key enregistreKey = ValueKey<String>('talents-enregistre');

  /// La cle de la carte des reponses.
  static const Key reponsesKey = ValueKey<String>('talents-reponses');

  /// La cle de la phrase « candidature terminee ».
  static const Key closeKey = ValueKey<String>('talents-close');

  /// La cle du bouton « Modifier mes reponses ».
  static const Key modifierKey = ValueKey<String>('talents-modifier');

  /// La cle du lien « Retirer mes reponses ».
  static const Key retirerKey = ValueKey<String>('talents-retirer');

  /// La cle de la phrase hors ligne du retrait.
  static const Key horsLigneKey = ValueKey<String>(
    'talents-retrait-hors-ligne',
  );

  /// La cle du message d'echec ou d'information.
  static const Key messageKey = ValueKey<String>('talents-lecture-message');

  /// La cle du lien de retour au dossier.
  static const Key retourKey = ValueKey<String>('talents-retour');

  @override
  ConsumerState<LectureTalents> createState() => _LectureTalentsEtat();
}

class _LectureTalentsEtat extends ConsumerState<LectureTalents> {
  bool _enCours = false;
  String? _message;
  String? _cle;

  void _retourDossier() => GoRouter.of(context).go(Routes.attente);

  Future<void> _retirer() async {
    final PortAutresCompetences? port = ref.read(portAutresCompetencesProvider);
    if (port == null) {
      return;
    }
    final l = t.recrutement.talents.lecture;
    final e = t.recrutement.talents.erreurs;
    final bool confirme = await ConfirmDestructive.demander(
      context,
      question: l.retraitQuestion,
      consequence: l.retraitConsequence,
      libelleConfirmer: l.retraitConfirmer,
    );
    if (!confirme || !mounted) {
      return;
    }
    setState(() {
      _enCours = true;
      _message = null;
    });
    // Une cle par geste, rejouee tant que l'issue est incertaine.
    final String cle = _cle ??= nouvelleCleIdempotence();
    try {
      await port.retirer(
        versionAttendue: widget.lecture.version,
        cleIdempotence: cle,
      );
      _cle = null;
      if (mounted) {
        setState(() => _enCours = false);
        widget.onRetire();
      }
    } on ConflitAutresCompetences {
      _cle = null;
      _echec(e.conflit);
    } on HorsLigneCandidature {
      _echec(e.retraitIncertain);
    } on CapaciteIndisponible {
      _cle = null;
      _echec(e.retraitEchec);
    } on PermissionInsuffisante {
      _cle = null;
      _echec(e.retraitEchec);
    } on Object {
      _echec(e.retraitIncertain);
    }
  }

  void _echec(String message) {
    if (mounted) {
      setState(() {
        _enCours = false;
        _message = message;
      });
    }
  }

  /// Le libelle d'une competence enregistree : le texte de l'application, sinon
  /// celui du catalogue, sinon une phrase neutre (jamais le code).
  String _nom(String code) {
    final EntreeCatalogue? entree = widget.lecture.referentiel.entree(code);
    return libelleCompetence(code, entree: entree) ??
        t.admin.candidatures.detail.talents.competenceInconnue;
  }

  @override
  Widget build(BuildContext context) {
    final ReponsesAutresCompetences? r = widget.lecture.reponses;
    final l = t.recrutement.talents.lecture;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final String? message = _message ?? widget.message;
    final DateTime? majLe = r?.majLe;
    // Dans l'ordre du catalogue, comme au choix.
    final List<MapEntry<String, NiveauCompetence>> competences =
        <MapEntry<String, NiveauCompetence>>[
          if (r != null)
            for (final EntreeCatalogue e
                in widget.lecture.referentiel.competences)
              if (r.domaines[e.code] case final NiveauCompetence n)
                MapEntry<String, NiveauCompetence>(e.code, n),
        ];
    return PageShell(
      titre: t.recrutement.talents.titre,
      onRetour: _retourDossier,
      actions: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (widget.onModifier != null)
            ActionPrincipale(
              key: LectureTalents.modifierKey,
              libelle: l.modifier,
              onPress: _enCours ? null : widget.onModifier,
            ),
          Ecart.vXs,
          if (horsLigne)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                t.recrutement.talents.erreurs.retraitHorsLigne,
                key: LectureTalents.horsLigneKey,
                textAlign: TextAlign.center,
                style: palette.inkMuted.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            )
          else
            ActionPrincipale(
              key: LectureTalents.retirerKey,
              libelle: l.retirer,
              niveau: NiveauAction.tertiaire,
              pleineLargeur: false,
              enCours: _enCours,
              onPress: _enCours ? null : () => unawaited(_retirer()),
            ),
          ActionPrincipale(
            key: LectureTalents.retourKey,
            libelle: t.recrutement.questionnaire.retourDossier,
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
            onPress: _retourDossier,
          ),
        ],
      ),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppPage.largeurMaxContenu,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppCard(
                key: LectureTalents.enregistreKey,
                selectionnee: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        ExcludeSemantics(
                          child: IconTheme(
                            data: IconThemeData(
                              color: palette.washAccent.onBackground,
                              size: AppSpacing.xxl,
                            ),
                            child: Icon(AppIcons.succes.actif),
                          ),
                        ),
                        Ecart.hMd,
                        Expanded(
                          child: TexteSansCoupure(
                            l.enregistre,
                            style: textes.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    if (majLe != null) ...<Widget>[
                      Ecart.vSm,
                      Text(
                        l.misesAJour(date: jourTalents(majLe)),
                        style: textes.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.onModifier == null) ...<Widget>[
                Ecart.vLg,
                TexteSansCoupure(
                  l.close,
                  key: LectureTalents.closeKey,
                  style: palette.inkMuted.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
              ],
              if (message != null) ...<Widget>[
                Ecart.vLg,
                Semantics(
                  liveRegion: true,
                  child: Text(
                    message,
                    key: LectureTalents.messageKey,
                    style: palette.inkAlert.applyTo(
                      textes.bodyMedium ?? const TextStyle(),
                    ),
                  ),
                ),
              ],
              Ecart.vXl,
              if (r != null)
                CarteGroupee(
                  key: LectureTalents.reponsesKey,
                  sections: <Widget>[
                    _Section(
                      titre: l.competences,
                      lignes: <Widget>[
                        for (final MapEntry<String, NiveauCompetence> e
                            in competences)
                          LigneCleValeur(
                            cle:
                                e.key == EntreeCatalogue.codeAutre &&
                                    r.autreTexte != null
                                ? l.autreDomaine(texte: r.autreTexte!)
                                : _nom(e.key),
                            valeur: libelleNiveau(e.value),
                          ),
                      ],
                    ),
                    _Section(
                      titre: l.disponibilite,
                      lignes: <Widget>[
                        TexteSansCoupure(
                          libelleDisponibilite(r.disponibilite),
                          style: textes.bodyLarge,
                        ),
                      ],
                    ),
                    _Section(
                      titre: l.contact,
                      lignes: <Widget>[
                        TexteSansCoupure(
                          r.accord ? l.contactOui : l.contactNon,
                          style: textes.bodyLarge,
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Une section de la carte des reponses : son titre, puis ses lignes.
class _Section extends StatelessWidget {
  const _Section({required this.titre, required this.lignes});

  final String titre;
  final List<Widget> lignes;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Semantics(
        header: true,
        child: TexteSansCoupure(
          titre,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      Ecart.vSm,
      ...lignes,
    ],
  );
}
