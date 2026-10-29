import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/accessibilite/texte_sans_coupure.dart';
import '../../../core/domain/enums.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/offres/offre_horaire.dart';
import '../../../core/router/routes.dart';
import '../../../core/session/session_controleur.dart';
import '../../../core/session/session_state.dart';
import '../../../core/theme/app_gabarit.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/choice_card_group.dart';
import '../../../core/widgets/filter_pill.dart';
import '../../../core/widgets/page_etape.dart';
import '../../connexion/connexion_page.dart' show parametreModeCreation;
import '../../parcours_offres/libelles_parcours.dart';
import '../brouillon_inscription.dart' show UsageInscription;
import 'questionnaire_inscription.dart';

/// `/commencer` : le questionnaire d'inscription, une question par ecran,
/// avant le compte (admission, lot B ; fiche du 29/10/2026, §3).
///
/// L'ecran courant se lit dans l'adresse (`?etape=age-0`) : le retour du
/// navigateur et un rechargement le gardent. Un ecran ouvert trop tot renvoie
/// au premier ecran sans reponse. A la fin, un visiteur sans compte va a la
/// creation du compte ; un compte deja cree (« Ajouter un autre profil
/// eleve » depuis le recapitulatif) revient a l'inscription.
class QuestionnairePage extends ConsumerWidget {
  /// Cree la page sur l'ecran [code] (`null` : le premier sans reponse).
  const QuestionnairePage({this.code, super.key});

  /// Le code de l'ecran, lu dans l'adresse.
  final String? code;

  /// L'adresse d'un ecran.
  static String adresse(EtapeQuestionnaire etape) => Uri(
    path: Routes.commencer,
    queryParameters: <String, String>{'etape': etape.code},
  ).toString();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuestionnaireInscription q = ref.watch(
      questionnaireInscriptionProvider,
    );
    final List<EtapeQuestionnaire> etapes = q.etapes;
    final EtapeQuestionnaire? demandee = EtapeQuestionnaire.depuisCode(code);
    final EtapeQuestionnaire? manquante = q.premiereManquante;
    int rang = demandee == null ? -1 : etapes.indexOf(demandee);
    // Un ecran inconnu, ou ouvert avant ceux qui le precedent : le premier
    // sans reponse (jamais d'ecran sans ses prealables).
    final int rangManquant = manquante == null
        ? etapes.length - 1
        : etapes.indexOf(manquante);
    if (rang == -1 || rang > rangManquant) {
      rang = rangManquant;
      if (demandee != null) {
        WidgetsBinding.instance.addPostFrameCallback((Duration _) {
          if (context.mounted) {
            context.go(adresse(etapes[rang]));
          }
        });
      }
    }
    final EtapeQuestionnaire etape = etapes[rang];
    final QuestionnaireControleur controleur = ref.read(
      questionnaireInscriptionProvider.notifier,
    );

    void avancer() {
      final QuestionnaireInscription apres = ref.read(
        questionnaireInscriptionProvider,
      );
      final List<EtapeQuestionnaire> suite = apres.etapes;
      final int ici = suite.indexOf(etape);
      // Les ecrans d'un meme enfant se suivent toujours (« Modifier » depuis
      // le recapitulatif atteint son age et son niveau) ; ensuite, l'ecran
      // suivant sans reponse : apres « Ajouter un autre profil eleve », les
      // ecrans deja repondus ne se reposent pas.
      final EtapeQuestionnaire? memeEnfant =
          etape.parEnfant && ici + 1 < suite.length ? suite[ici + 1] : null;
      final EtapeQuestionnaire? suivante =
          memeEnfant != null &&
              memeEnfant.parEnfant &&
              memeEnfant.rang == etape.rang
          ? memeEnfant
          : suite
                .skip(ici + 1)
                .where((EtapeQuestionnaire e) => !apres.repondue(e))
                .firstOrNull;
      if (suivante != null) {
        context.go(adresse(suivante));
        return;
      }
      final bool compteCree =
          ref.read(sessionProvider).porte == PorteAcces.inscription;
      context.go(
        compteCree
            ? Routes.inscription
            : Uri(
                path: Routes.connexion,
                queryParameters: <String, String>{
                  'mode': parametreModeCreation,
                },
              ).toString(),
      );
    }

    VoidCallback? retour;
    if (rang > 0) {
      retour = () {
        // Revenir du prenom d'un enfant ajoute, sans l'avoir saisi, le retire.
        if (etape.sorte == SorteEtape.prenom &&
            !q.repondue(etape) &&
            etape.rang > 0) {
          controleur.retirerEnfant(etape.rang);
        }
        context.go(adresse(etapes[rang - 1]));
      };
    }

    return _EcranQuestion(
      // Une cle par ecran : le champ du prenom ne garde pas la saisie d'un
      // autre enfant.
      key: ValueKey<String>('questionnaire-${etape.code}'),
      numero: rang + 1,
      // Avant « Pour qui », le parcours le plus court (« pour moi ») : un
      // total ne se devine pas, il ne gonfle pas non plus.
      total: q.usage == null
          ? const QuestionnaireInscription(usage: UsageInscription.moi)
                .etapes
                .length
          : etapes.length,
      etape: etape,
      questionnaire: q,
      controleur: controleur,
      onAvancer: avancer,
      onRetour: retour,
    );
  }
}

class _EcranQuestion extends StatefulWidget {
  const _EcranQuestion({
    required this.numero,
    required this.total,
    required this.etape,
    required this.questionnaire,
    required this.controleur,
    required this.onAvancer,
    required this.onRetour,
    super.key,
  });

  final int numero;
  final int total;
  final EtapeQuestionnaire etape;
  final QuestionnaireInscription questionnaire;
  final QuestionnaireControleur controleur;
  final VoidCallback onAvancer;
  final VoidCallback? onRetour;

  @override
  State<_EcranQuestion> createState() => _EcranQuestionState();
}

class _EcranQuestionState extends State<_EcranQuestion> {
  late final TextEditingController _prenom = TextEditingController(
    text: _enfant.prenom,
  );
  bool _adulte = false;
  bool _tente = false;

  EnfantQuestionnaire get _enfant =>
      widget.etape.rang < widget.questionnaire.enfants.length
      ? widget.questionnaire.enfants[widget.etape.rang]
      : const EnfantQuestionnaire();

  String get _prenomEnfant => _enfant.prenom.trim();

  @override
  void dispose() {
    _prenom.dispose();
    super.dispose();
  }

  void _modifierEnfant(
    EnfantQuestionnaire Function(EnfantQuestionnaire e) modifier,
  ) => widget.controleur.modifierEnfant(widget.etape.rang, modifier);

  /// « Continuer » n'est jamais grise (BOUTONS-GRISES-1) : sans reponse, il
  /// le dit sous la question ; a 18 ans ou plus, la phrase de l'age suffit.
  void _continuer({required bool repondue}) {
    if (!repondue) {
      setState(() => _tente = true);
      return;
    }
    if (widget.etape.sorte == SorteEtape.prenom) {
      _modifierEnfant(
        (EnfantQuestionnaire e) => e.copier(prenom: _prenom.text),
      );
    }
    widget.onAvancer();
  }

  @override
  Widget build(BuildContext context) {
    final QuestionnaireInscription q = widget.questionnaire;
    final bool repondue = widget.etape.sorte == SorteEtape.prenom
        ? _prenom.text.trim().isNotEmpty
        : q.repondue(widget.etape);
    final (String question, String? explication, Widget corps) = _contenu(
      context,
    );
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final bool choix = widget.etape.sorte == SorteEtape.pourQui;

    return PageEtape(
      numero: widget.numero,
      total: widget.total,
      onRetour: widget.onRetour,
      colonneLarge: choix,
      action: Column(
        crossAxisAlignment: AppGabarit.de(context) == Gabarit.mobile
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (_tente && !repondue && !_adulte) ...<Widget>[
            Semantics(
              liveRegion: true,
              child: Text(
                t.inscription.champRequis,
                key: const Key('questionnaire-reponse-requise'),
                textAlign: TextAlign.center,
                style: palette.inkAlert.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vMd,
          ],
          ActionPrincipale(
            key: const Key('questionnaire-continuer'),
            libelle: t.commun.continuer,
            onPress: () => _continuer(repondue: repondue),
            pilule: true,
            fleche: true,
          ),
          if (choix) ...<Widget>[
            Ecart.vXs,
            Center(
              child: ActionPrincipale(
                key: const Key('questionnaire-deja-un-compte'),
                libelle: t.inscription.questionnaire.dejaUnCompte,
                niveau: NiveauAction.tertiaire,
                pleineLargeur: false,
                onPress: () => context.go(Routes.connexion),
              ),
            ),
            Center(
              child: ActionPrincipale(
                key: const Key('questionnaire-invitation'),
                libelle: t.inscription.usage.enseignant,
                niveau: NiveauAction.tertiaire,
                pleineLargeur: false,
                // Les codes d'invitation (enseignant, comptable) ne passent
                // pas par le questionnaire : le compte d'abord, puis le code.
                onPress: () => context.go(
                  Uri(
                    path: Routes.connexion,
                    queryParameters: <String, String>{
                      'mode': parametreModeCreation,
                      parametreInvitation: '1',
                    },
                  ).toString(),
                ),
              ),
            ),
          ],
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TexteSansCoupure(
            question,
            style: textes.headlineSmall ?? const TextStyle(),
          ),
          if (explication != null) ...<Widget>[
            Ecart.vSm,
            TexteSansCoupure(
              explication,
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ],
          Ecart.vXl,
          corps,
        ],
      ),
    );
  }

  (String, String?, Widget) _contenu(BuildContext context) {
    final QuestionnaireInscription q = widget.questionnaire;
    final QuestionnaireControleur c = widget.controleur;
    return switch (widget.etape.sorte) {
      SorteEtape.pourQui => (
        t.inscription.usage.question,
        null,
        ChoiceCardGroup(
          key: const Key('questionnaire-pour-qui'),
          autoriserSaisieLibre: false,
          coteACote: true,
          choixEgaux: true,
          valeurInitiale: q.usage == null
              ? null
              : ReponseChoix(valeurs: <String>{q.usage!.name}),
          options: <OptionChoix>[
            OptionChoix(
              valeur: UsageInscription.moi.name,
              libelle: t.inscription.usage.moiTitre,
              explication: t.inscription.usage.moiDescription,
              icone: AppIcons.profil,
            ),
            OptionChoix(
              valeur: UsageInscription.famille.name,
              libelle: t.inscription.usage.familleTitre,
              explication: t.inscription.usage.familleDescription,
              icone: AppIcons.foyer,
            ),
          ],
          onChange: (ReponseChoix r) {
            for (final UsageInscription u in <UsageInscription>[
              UsageInscription.moi,
              UsageInscription.famille,
            ]) {
              if (r.valeurs.contains(u.name)) {
                c.choisirUsage(u);
              }
            }
          },
        ),
      ),
      SorteEtape.prenom => (
        t.inscription.questionnaire.prenomQuestion,
        widget.etape.rang == 0
            ? t.inscription.questionnaire.prenomRaison
            : null,
        TextField(
          key: const Key('questionnaire-prenom'),
          controller: _prenom,
          autofocus: true,
          onChanged: (String _) => setState(() {}),
          onSubmitted: (String _) =>
              _continuer(repondue: _prenom.text.trim().isNotEmpty),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(labelText: t.inscription.prenom),
        ),
      ),
      SorteEtape.age => (
        t.inscription.questionnaire.ageQuestion(prenom: _prenomEnfant),
        null,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Un age parmi treize, d'un geste, sans faire defiler une liste.
            // Choix de formulaire, pas un filtre : l'age d'un enfant.
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                for (int a = ageMinimum; a <= ageMaximum; a++)
                  FilterPill(
                    key: ValueKey<String>('questionnaire-age-$a'),
                    libelle: t.inscription.questionnaire.ans(n: a),
                    retenue: !_adulte && _enfant.age == a,
                    onPress: () {
                      setState(() => _adulte = false);
                      _modifierEnfant(
                        (EnfantQuestionnaire e) => e.copier(age: a),
                      );
                    },
                  ),
                FilterPill(
                  key: const ValueKey<String>('questionnaire-age-adulte'),
                  libelle: t.inscription.questionnaire.adulte,
                  retenue: _adulte,
                  onPress: () => setState(() => _adulte = true),
                ),
              ],
            ),
            if (_adulte) ...<Widget>[
              Ecart.vLg,
              Semantics(
                liveRegion: true,
                child: Text(
                  t.inscription.questionnaire.adulteDetail,
                  key: const Key('questionnaire-age-adulte-detail'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ],
        ),
      ),
      SorteEtape.genre => (
        t.inscription.questionnaire.genreQuestion(prenom: _prenomEnfant),
        t.inscription.questionnaire.genreRaison,
        ChoiceCardGroup(
          key: const Key('questionnaire-genre'),
          autoriserSaisieLibre: false,
          enLigne: true,
          valeurInitiale: _enfant.genre == null
              ? null
              : ReponseChoix(valeurs: <String>{_enfant.genre!.name}),
          options: <OptionChoix>[
            OptionChoix(
              valeur: Genre.homme.name,
              libelle: t.inscription.questionnaire.garcon,
            ),
            OptionChoix(
              valeur: Genre.femme.name,
              libelle: t.inscription.questionnaire.fille,
            ),
          ],
          onChange: (ReponseChoix r) {
            for (final Genre g in Genre.values) {
              if (r.valeurs.contains(g.name)) {
                _modifierEnfant((EnfantQuestionnaire e) => e.copier(genre: g));
              }
            }
          },
        ),
      ),
      SorteEtape.parent => (
        t.inscription.usage.coursQuestion,
        null,
        ChoiceCardGroup(
          key: const Key('questionnaire-parent'),
          autoriserSaisieLibre: false,
          enLigne: true,
          valeurInitiale: q.parentSuitDesCours == null
              ? null
              : ReponseChoix(
                  valeurs: <String>{q.parentSuitDesCours! ? 'oui' : 'non'},
                ),
          options: <OptionChoix>[
            OptionChoix(valeur: 'oui', libelle: t.inscription.usage.coursOui),
            OptionChoix(valeur: 'non', libelle: t.inscription.usage.coursNon),
          ],
          onChange: (ReponseChoix r) {
            if (r.valeurs.contains('oui')) {
              c.choisirParent(suit: true);
            } else if (r.valeurs.contains('non')) {
              c.choisirParent(suit: false);
            }
          },
        ),
      ),
      SorteEtape.niveau || SorteEtape.niveauTitulaire => (
        widget.etape.sorte == SorteEtape.niveau
            ? t.parcours.niveauQuestion(prenom: _prenomEnfant)
            : t.inscription.questionnaire.niveauQuestionMoi,
        t.parcours.niveauRaison,
        ChoiceCardGroup(
          key: const Key('questionnaire-niveau'),
          autoriserSaisieLibre: false,
          valeurInitiale: _niveau == null
              ? null
              : ReponseChoix(valeurs: <String>{_niveau!.valeurSql}),
          options: <OptionChoix>[
            for (final NiveauDeclare n in NiveauDeclare.values)
              OptionChoix(valeur: n.valeurSql, libelle: libelleNiveau(n)),
          ],
          onChange: (ReponseChoix r) {
            final NiveauDeclare? n = r.valeurs.isEmpty
                ? null
                : NiveauDeclare.depuisSql(r.valeurs.first);
            if (n == null) {
              return;
            }
            if (widget.etape.sorte == SorteEtape.niveau) {
              _modifierEnfant((EnfantQuestionnaire e) => e.copier(niveau: n));
            } else {
              c.choisirNiveauTitulaire(n);
            }
          },
        ),
      ),
      SorteEtape.objectif => (
        t.parcours.objectifQuestion,
        t.parcours.objectifRaison,
        ChoiceCardGroup(
          key: const Key('questionnaire-objectif'),
          autoriserSaisieLibre: false,
          valeurInitiale: q.objectif == null
              ? null
              : ReponseChoix(valeurs: <String>{q.objectif!.valeurSql}),
          options: <OptionChoix>[
            for (final ObjectifApprentissage o in ObjectifApprentissage.values)
              OptionChoix(valeur: o.valeurSql, libelle: libelleObjectif(o)),
          ],
          onChange: (ReponseChoix r) {
            final ObjectifApprentissage? o = r.valeurs.isEmpty
                ? null
                : ObjectifApprentissage.depuisSql(r.valeurs.first);
            if (o != null) {
              c.choisirObjectif(o);
            }
          },
        ),
      ),
      SorteEtape.moments => (
        t.parcours.momentsQuestion,
        null,
        ChoiceCardGroup(
          key: const Key('questionnaire-moments'),
          autoriserSaisieLibre: false,
          selectionMultiple: true,
          valeurInitiale: ReponseChoix(
            valeurs: <String>{for (final MomentJournee m in q.moments) m.name},
          ),
          options: <OptionChoix>[
            for (final MomentJournee m in MomentJournee.values)
              OptionChoix(valeur: m.name, libelle: m.libelle),
          ],
          onChange: (ReponseChoix r) {
            for (final MomentJournee m in MomentJournee.values) {
              if (r.valeurs.contains(m.name) != q.moments.contains(m)) {
                c.basculerMoment(m);
              }
            }
          },
        ),
      ),
    };
  }

  NiveauDeclare? get _niveau => widget.etape.sorte == SorteEtape.niveau
      ? _enfant.niveau
      : widget.questionnaire.niveauTitulaire;
}

/// Le parametre de la connexion qui dit « j'ai un code d'invitation » : la
/// creation du compte s'ouvre sans le questionnaire.
const String parametreInvitation = 'invitation';

/// Ou mene la creation d'un compte (`/connexion?mode=creer`) : au
/// questionnaire tant qu'il n'est pas repondu, sauf avec un code
/// d'invitation ([parametreInvitation]). Fonction pure.
String? redirectionCreationCompte(
  Uri adresse, {
  required bool questionnaireComplet,
}) =>
    adresse.queryParameters['mode'] == parametreModeCreation &&
        !adresse.queryParameters.containsKey(parametreInvitation) &&
        !questionnaireComplet
    ? Routes.commencer
    : null;
