import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/accessibilite/texte_sans_coupure.dart';
import '../../../core/domain/enums.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/offres/offre_horaire.dart';
import '../../../core/offres/service_offres.dart' show languesCoursProvider;
import '../../../core/router/routes.dart';
import '../../../core/session/session_controleur.dart';
import '../../../core/session/session_state.dart';
import '../../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/choice_card_group.dart';
import '../../../core/widgets/etat_systeme.dart';
import '../../../core/widgets/filter_pill.dart';
import '../../../core/widgets/page_etape.dart';
import '../../../core/widgets/skeleton.dart';
import '../../connexion/connexion_page.dart' show parametreModeCreation;
import '../../connexion/coquille_entree.dart';
import '../../parcours_offres/libelles_parcours.dart';
import '../brouillon_inscription.dart' show UsageInscription;
import '../invitation_en_cours.dart';
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
    if (demandee == null) {
      // INSCRIPTION-3 (constat du directeur, 01/11) : sans `?etape=`, l'ecran
      // montre « le premier sans reponse » ; une reponse le deplacait, et un
      // toucher sur « Pour qui » passait aussitot au prenom, sans etat choisi
      // ni « Continuer ». L'ecran affiche fixe donc son adresse des
      // l'ouverture, comme tous les autres : un toucher choisit, « Continuer »
      // avance. Sans entree d'historique de plus (`Router.neglect`) : le
      // retour du navigateur ne revient pas sur `/commencer` nu, qui
      // redirigerait aussitot.
      final String fixe = adresse(etapes[rang]);
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (context.mounted) {
          Router.neglect(context, () => context.go(fixe));
        }
      });
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

class _EcranQuestion extends ConsumerStatefulWidget {
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
  ConsumerState<_EcranQuestion> createState() => _EcranQuestionState();
}

class _EcranQuestionState extends ConsumerState<_EcranQuestion> {
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
    HardwareKeyboard.instance.removeHandler(_lettre);
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

  /// Les reponses de l'ecran au dernier dessin, pour les lettres du clavier ;
  /// `null` : l'ecran n'a pas de choix (prenom) ou pas encore (langues).
  List<_Reponse>? _reponsesAffichees;

  /// Vrai quand le dernier dessin etait celui de l'ordinateur : les lettres
  /// n'y sont dessinees, et donc tenues, que la.
  bool _bureau = false;

  /// Monte a chaque choix fait au clavier : les cartes (qui gardent leur
  /// propre selection) se redessinent depuis la reponse retenue. Un toucher
  /// ne le change pas : la carte touchee garde le focus.
  int _versionClavier = 0;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_lettre);
  }

  /// A, B, C... choisit la reponse de ce rang (fiche ONBOARDING §2), sur
  /// ordinateur, hors saisie et sans touche de commande.
  bool _lettre(KeyEvent evenement) {
    final List<_Reponse>? reponses = _reponsesAffichees;
    if (!_bureau ||
        reponses == null ||
        evenement is! KeyDownEvent ||
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isAltPressed ||
        FocusManager.instance.primaryFocus?.context?.widget is EditableText) {
      return false;
    }
    final String? caractere = evenement.character?.toUpperCase();
    if (caractere == null || caractere.length != 1) {
      return false;
    }
    final int rang = caractere.codeUnitAt(0) - 0x41;
    if (rang < 0 || rang >= reponses.length) {
      return false;
    }
    setState(() => _versionClavier++);
    reponses[rang].choisir();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final QuestionnaireInscription q = widget.questionnaire;
    final bool repondue = widget.etape.sorte == SorteEtape.prenom
        ? _prenom.text.trim().isNotEmpty
        : q.repondue(widget.etape);
    final (String question, String? explication) = _question();
    final bool choix = widget.etape.sorte == SorteEtape.pourQui;

    // UX-046 (pilote, 02/11/2026) : l'habillage de la connexion. Sur
    // ordinateur, des 840 points, deux volets : l'etape et la question sur la
    // marque au debut de ligne, les reponses et « Continuer » sur le
    // parchemin a cote ; sur telephone, une page sur la marque.
    return CoquilleEntree(
      // Un `Builder` : le theme lu est celui de la surface ou le contenu est
      // pose (marque ou parchemin), pas celui de la page.
      volet: (bool bureau) => Builder(
        builder: (BuildContext context) {
          final TextTheme textes = Theme.of(context).textTheme;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              RangeeEtape(
                numero: widget.numero,
                total: widget.total,
                onRetour: widget.onRetour,
              ),
              Ecart.vXxl,
              Semantics(
                header: true,
                child: TexteSansCoupure(
                  question,
                  style:
                      (bureau ? textes.headlineMedium : textes.headlineSmall) ??
                      const TextStyle(),
                ),
              ),
              if (explication != null) ...<Widget>[
                Ecart.vSm,
                TexteSansCoupure(
                  explication,
                  style: textes.bodyMedium ?? const TextStyle(),
                ),
              ],
              if (bureau &&
                  widget.etape.sorte != SorteEtape.prenom) ...<Widget>[
                Ecart.vXl,
                Text(
                  t.inscription.questionnaire.clavierLettres,
                  key: const Key('questionnaire-clavier'),
                  style: textes.bodySmall,
                ),
              ],
            ],
          );
        },
      ),
      formulaire: (bool bureau) => Builder(
        builder: (BuildContext context) {
          _bureau = bureau;
          final AppPalette palette = AppPalette.of(context);
          final TextTheme textes = Theme.of(context).textTheme;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _corps(context, bureau: bureau),
              Ecart.vXl,
              if (_tente && !repondue && !_adulte) ...<Widget>[
                Semantics(
                  liveRegion: true,
                  child: Text(
                    t.inscription.champRequis,
                    key: const Key('questionnaire-reponse-requise'),
                    style: palette.inkAlert.applyTo(
                      textes.bodyMedium ?? const TextStyle(),
                    ),
                  ),
                ),
                Ecart.vMd,
              ],
              // Un bouton plein, comme « Recevoir le lien » : le « Continuer »
              // en pilule lilas se lisait comme eteint (UX-046).
              BoutonEntree(
                bureau: bureau,
                child: ActionPrincipale(
                  key: const Key('questionnaire-continuer'),
                  libelle: t.commun.continuer,
                  onPress: () => _continuer(repondue: repondue),
                  pleineLargeur: !bureau,
                  fleche: true,
                  // Sur la marque, l'aplat blanc a encre violette ; sur le
                  // parchemin, le violet a encre blanche (comme la connexion).
                  affirmee: true,
                ),
              ),
              if (choix) ...<Widget>[
                Ecart.vXl,
                LienEntree(
                  cle: const Key('questionnaire-deja-un-compte'),
                  libelle: t.inscription.questionnaire.dejaUnCompte,
                  onPress: () => context.go(Routes.connexion),
                ),
                Ecart.vSm,
                LienEntree(
                  cle: const Key('questionnaire-invitation'),
                  libelle: t.inscription.usage.enseignant,
                  // Les codes d'invitation (enseignant, comptable) ne passent
                  // pas par le questionnaire : le compte d'abord, puis le code.
                  onPress: () {
                    // I1 (UX-013) : l'invitation en cours survit au lien de
                    // connexion, ouvert souvent dans un autre onglet.
                    retenirInvitationEnCours();
                    context.go(
                      Uri(
                        path: Routes.connexion,
                        queryParameters: <String, String>{
                          'mode': parametreModeCreation,
                          parametreInvitation: '1',
                        },
                      ).toString(),
                    );
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  (String, String?) _question() => switch (widget.etape.sorte) {
    SorteEtape.pourQui => (t.inscription.usage.question, null),
    SorteEtape.prenom => (
      t.inscription.questionnaire.prenomQuestion,
      widget.etape.rang == 0 ? t.inscription.questionnaire.prenomRaison : null,
    ),
    SorteEtape.age => (
      t.inscription.questionnaire.ageQuestion(prenom: _prenomEnfant),
      // UX-032 : la regle se dit au moment du choix (K-58).
      t.inscription.questionnaire.ageMinimum(min: ageMinimum),
    ),
    SorteEtape.genre => (
      t.inscription.questionnaire.genreQuestion(prenom: _prenomEnfant),
      t.inscription.questionnaire.genreRaison,
    ),
    SorteEtape.parent => (t.inscription.usage.coursQuestion, null),
    SorteEtape.langue => (t.parcours.langueQuestion, t.parcours.langueRaison),
    SorteEtape.niveau => (
      t.parcours.niveauQuestion(prenom: _prenomEnfant),
      t.parcours.niveauRaison,
    ),
    SorteEtape.niveauTitulaire => (
      t.inscription.questionnaire.niveauQuestionMoi,
      t.parcours.niveauRaison,
    ),
    SorteEtape.objectif => (
      t.parcours.objectifQuestion,
      t.parcours.objectifRaison,
    ),
    SorteEtape.moments => (t.parcours.momentsQuestion, null),
  };

  /// Les reponses de l'ecran, dans l'ordre des lettres ; `null` sans choix.
  List<_Reponse>? _reponses(List<LangueCours>? langues) {
    final QuestionnaireInscription q = widget.questionnaire;
    final QuestionnaireControleur c = widget.controleur;
    return switch (widget.etape.sorte) {
      SorteEtape.prenom => null,
      SorteEtape.pourQui => <_Reponse>[
        for (final (UsageInscription u, String libelle, String explication)
            in <(UsageInscription, String, String)>[
              (
                UsageInscription.moi,
                t.inscription.usage.moiTitre,
                t.inscription.usage.moiDescription,
              ),
              (
                UsageInscription.famille,
                t.inscription.usage.familleTitre,
                t.inscription.usage.familleDescription,
              ),
            ])
          (
            valeur: u.name,
            libelle: libelle,
            explication: explication,
            retenue: q.usage == u,
            choisir: () => c.choisirUsage(u),
          ),
      ],
      SorteEtape.age => <_Reponse>[
        for (int a = ageMinimum; a <= ageMaximum; a++)
          (
            valeur: '$a',
            libelle: LibellesGroupe.insecable(
              t.inscription.questionnaire.ans(n: a),
            ),
            explication: null,
            retenue: !_adulte && _enfant.age == a,
            choisir: () {
              setState(() => _adulte = false);
              _modifierEnfant((EnfantQuestionnaire e) => e.copier(age: a));
            },
          ),
        (
          valeur: 'adulte',
          libelle: t.inscription.questionnaire.adulte,
          explication: null,
          retenue: _adulte,
          choisir: () => setState(() => _adulte = true),
        ),
      ],
      SorteEtape.genre => <_Reponse>[
        for (final (Genre g, String libelle) in <(Genre, String)>[
          (Genre.homme, t.inscription.questionnaire.garcon),
          (Genre.femme, t.inscription.questionnaire.fille),
        ])
          (
            valeur: g.name,
            libelle: libelle,
            explication: null,
            retenue: _enfant.genre == g,
            choisir: () =>
                _modifierEnfant((EnfantQuestionnaire e) => e.copier(genre: g)),
          ),
      ],
      SorteEtape.parent => <_Reponse>[
        for (final (bool suit, String libelle) in <(bool, String)>[
          (true, t.inscription.usage.coursOui),
          (false, t.inscription.usage.coursNon),
        ])
          (
            valeur: suit ? 'oui' : 'non',
            libelle: libelle,
            explication: null,
            retenue: q.parentSuitDesCours == suit,
            choisir: () => c.choisirParent(suit: suit),
          ),
      ],
      // La langue du cours, avant le compte (directeur, 29/10/2026) : la liste
      // des langues actives se lit sans compte (`langues_cours_publiques`).
      SorteEtape.langue =>
        langues == null
            ? null
            : <_Reponse>[
                // Le nom vient du serveur et ne se traduit pas.
                for (final LangueCours l in langues)
                  (
                    valeur: l.code,
                    libelle: l.nom,
                    explication: null,
                    retenue: q.langue == l.code,
                    choisir: () => c.choisirLangue(l.code),
                  ),
              ],
      SorteEtape.niveau || SorteEtape.niveauTitulaire => <_Reponse>[
        for (final NiveauDeclare n in NiveauDeclare.values)
          (
            valeur: n.valeurSql,
            libelle: libelleNiveau(n),
            explication: null,
            retenue: _niveau == n,
            choisir: () => widget.etape.sorte == SorteEtape.niveau
                ? _modifierEnfant(
                    (EnfantQuestionnaire e) => e.copier(niveau: n),
                  )
                : c.choisirNiveauTitulaire(n),
          ),
      ],
      SorteEtape.objectif => <_Reponse>[
        for (final ObjectifApprentissage o in ObjectifApprentissage.values)
          (
            valeur: o.valeurSql,
            libelle: libelleObjectif(o),
            explication: null,
            retenue: q.objectif == o,
            choisir: () => c.choisirObjectif(o),
          ),
      ],
      SorteEtape.moments => <_Reponse>[
        for (final MomentJournee m in MomentJournee.values)
          (
            valeur: m.name,
            libelle: m.libelle,
            explication: null,
            retenue: q.moments.contains(m),
            choisir: () => c.basculerMoment(m),
          ),
      ],
    };
  }

  /// Les reponses : des puces pour les choix courts, des cartes legeres
  /// seulement la ou une explication aide (pour qui, niveau, objectif),
  /// fiche ONBOARDING §2.
  Widget _corps(BuildContext context, {required bool bureau}) {
    final SorteEtape sorte = widget.etape.sorte;
    if (sorte == SorteEtape.prenom) {
      _reponsesAffichees = null;
      return ChampEntree(
        cle: 'questionnaire-prenom',
        etiquette: t.inscription.prenom,
        indice: null,
        controleur: _prenom,
        erreur: null,
        onChanged: () => setState(() {}),
        onSoumettre: () => _continuer(repondue: _prenom.text.trim().isNotEmpty),
        clavier: TextInputType.name,
        autofill: const <String>[AutofillHints.givenName],
      );
    }
    List<LangueCours>? langues;
    if (sorte == SorteEtape.langue) {
      final AsyncValue<List<LangueCours>> lues = ref.watch(
        languesCoursProvider,
      );
      if (lues.hasError && !lues.hasValue) {
        _reponsesAffichees = null;
        return EtatSysteme(
          nature: NatureEtat.echecServeur,
          libelleAction: t.commun.etats.actions.reessayer,
          onAction: () => ref.invalidate(languesCoursProvider),
        );
      }
      if (!lues.hasValue) {
        _reponsesAffichees = null;
        return const Skeleton.liste(lignes: 3);
      }
      langues = lues.requireValue;
    }
    final List<_Reponse> reponses = _reponses(langues)!;
    _reponsesAffichees = reponses;
    if (sorte == SorteEtape.pourQui ||
        sorte == SorteEtape.niveau ||
        sorte == SorteEtape.niveauTitulaire ||
        sorte == SorteEtape.objectif) {
      final Set<String> retenues = <String>{
        for (final _Reponse r in reponses)
          if (r.retenue) r.valeur,
      };
      return ChoiceCardGroup(
        key: ValueKey<String>(
          'questionnaire-${switch (sorte) {
            SorteEtape.pourQui => 'pour-qui',
            SorteEtape.objectif => 'objectif',
            _ => 'niveau',
          }}-$_versionClavier',
        ),
        autoriserSaisieLibre: false,
        lettres: bureau,
        valeurInitiale: retenues.isEmpty
            ? null
            : ReponseChoix(valeurs: retenues),
        options: <OptionChoix>[
          for (final _Reponse r in reponses)
            OptionChoix(
              valeur: r.valeur,
              libelle: r.libelle,
              explication: r.explication,
            ),
        ],
        onChange: (ReponseChoix choisie) {
          for (final _Reponse r in reponses) {
            if (choisie.valeurs.contains(r.valeur) && !r.retenue) {
              r.choisir();
            }
          }
        },
      );
    }
    final bool plusieurs = sorte == SorteEtape.moments;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (plusieurs) ...<Widget>[
          TexteSansCoupure(
            t.choix.selectionMultiple,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Ecart.vMd,
        ],
        // Des puces, un geste par reponse.
        // Choix de formulaire, pas un filtre : une reponse au questionnaire.
        Wrap(
          key: ValueKey<String>('questionnaire-${widget.etape.sorte.name}'),
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final (int i, _Reponse r) in reponses.indexed)
              FilterPill(
                key: ValueKey<String>(
                  'questionnaire-${_cle(sorte)}-${r.valeur}',
                ),
                libelle: r.libelle,
                retenue: r.retenue,
                apercu: bureau ? LettreChoix(lettre: lettreChoix(i)) : null,
                onPress: r.choisir,
              ),
          ],
        ),
        if (sorte == SorteEtape.age && _adulte) ...<Widget>[
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
    );
  }

  static String _cle(SorteEtape sorte) => switch (sorte) {
    SorteEtape.age => 'age',
    SorteEtape.genre => 'genre',
    SorteEtape.parent => 'parent',
    SorteEtape.langue => 'langue',
    _ => 'moment',
  };

  NiveauDeclare? get _niveau => widget.etape.sorte == SorteEtape.niveau
      ? _enfant.niveau
      : widget.questionnaire.niveauTitulaire;
}

/// Une reponse proposee : sa valeur, son libelle, si elle est retenue, et le
/// geste qui la choisit (toucher ou lettre du clavier).
typedef _Reponse = ({
  String valeur,
  String libelle,
  String? explication,
  bool retenue,
  VoidCallback choisir,
});

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
