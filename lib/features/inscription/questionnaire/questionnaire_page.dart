import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/candidature/fuseau_appareil.dart';
import '../../../core/domain/enums.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/offres/offre_horaire.dart';
import '../../../core/router/routes.dart';
import '../../../core/session/session_controleur.dart';
import '../../../core/session/session_state.dart';
import '../../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/vivant/entree/gestes_praxis.dart' show Geste;
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/bandeau_attention.dart';
import '../../../core/widgets/champ_etiquete.dart';
import '../../../core/widgets/choice_card_group.dart';
import '../../../core/widgets/filter_pill.dart';
import '../../../core/widgets/lien_fleche.dart';
import '../../connexion/connexion_page.dart' show parametreModeCreation;
import '../../connexion/ordre_entree.dart' show adresseConnexionDemandee;
import '../invitation_en_cours.dart';
import 'acces_questionnaire.dart';
import 'coquille_onboarding.dart';
import 'interludes_onboarding.dart';
import 'onboarding_donnees.dart';
import 'questionnaire_inscription.dart';

/// `/commencer` : le questionnaire avant le compte, guide par Praxis
/// (ONBOARDING-PRAXIS, directeur, 22/11/2026 ; maquette validee
/// `docs/current/maquettes/onboarding-praxis/prototype.html`).
///
/// L'ecran courant se lit dans l'adresse (`?etape=age-0`) : le retour du
/// navigateur et un rechargement le gardent. Un ecran ouvert trop tot renvoie
/// au premier ecran sans reponse. Apres le recapitulatif, l'acces (adresse
/// e-mail ou Google, `?etape=acces`) ; un compte deja cree revient a
/// l'inscription.
class QuestionnairePage extends ConsumerWidget {
  /// Cree la page sur l'ecran [code] (`null` : le premier sans reponse).
  const QuestionnairePage({this.code, super.key});

  /// Le code de l'ecran, lu dans l'adresse.
  final String? code;

  /// L'adresse de l'acces, apres le recapitulatif.
  static String get adresseAcces => Uri(
    path: Routes.commencer,
    queryParameters: <String, String>{'etape': codeEtapeAcces},
  ).toString();

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
    final bool compteCree =
        ref.watch(sessionProvider).porte == PorteAcces.inscription;
    if (code == codeEtapeAcces) {
      if (!compteCree && q.complet) {
        return EcranAccesQuestionnaire(
          onRetour: () => context.go(adresse(etapes.last)),
        );
      }
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (context.mounted) {
          context.go(
            compteCree
                ? Routes.inscription
                : adresse(q.premiereManquante ?? etapes.first),
          );
        }
      });
      return const SizedBox.shrink();
    }
    final EtapeQuestionnaire? demandee = EtapeQuestionnaire.depuisCode(code);
    // La branche « Enseigner » : jamais d'apprenant, jamais de compte eleve.
    if (demandee?.sorte == SorteEtape.enseigner && !compteCree) {
      return _EcranQuestion(
        key: const ValueKey<String>('questionnaire-enseigner'),
        etape: demandee!,
        questionnaire: q,
        rang: -1,
      );
    }
    final EtapeQuestionnaire? manquante = q.premiereManquante;
    int rang = demandee == null ? -1 : etapes.indexOf(demandee);
    final int rangManquant = manquante == null
        ? etapes.length - 1
        : etapes.indexOf(manquante);
    if (rang == -1 || rang > rangManquant) {
      rang = rangManquant;
      final String fixe = adresse(etapes[rang]);
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (!context.mounted) return;
        // Sans `?etape=`, l'adresse se fixe sans entree d'historique de plus.
        if (demandee == null) {
          Router.neglect(context, () => context.go(fixe));
        } else {
          context.go(fixe);
        }
      });
    }
    final EtapeQuestionnaire etape = etapes[rang];
    return _EcranQuestion(
      // Une cle par ecran : un champ ne garde pas la saisie d'un autre.
      key: ValueKey<String>('questionnaire-${etape.code}'),
      etape: etape,
      questionnaire: q,
      rang: rang,
    );
  }
}

/// Le remplissage des quatre segments pour l'ecran de rang [rang] du plan
/// (la maquette : un chapitre fait est plein, un chapitre a venir vide, le
/// chapitre courant a la part de ses ecrans deja passes). Le chapitre
/// « Votre demande » compte aussi l'acces, le lien envoye, l'identite et la
/// fin : [rangDemande] est le rang de l'ecran dans ce chapitre.
List<double> remplissageOnboarding(
  List<EtapeQuestionnaire> plan,
  int rang, {
  int? rangDemande,
}) {
  const int ecransDemande = 5;
  final Chapitre courant = rangDemande != null
      ? Chapitre.demande
      : plan[rang].chapitre ?? Chapitre.quiApprend;
  return <double>[
    for (final Chapitre c in Chapitre.values)
      if (c.index < courant.index)
        1
      else if (c.index > courant.index)
        0
      else if (c == Chapitre.demande)
        (rangDemande ?? 0) / ecransDemande
      else
        _part(plan, rang, c),
  ];
}

double _part(List<EtapeQuestionnaire> plan, int rang, Chapitre c) {
  final List<int> rangs = <int>[
    for (final (int i, EtapeQuestionnaire e) in plan.indexed)
      if (e.chapitre == c) i,
  ];
  if (rangs.isEmpty) return 0;
  return rangs.where((int i) => i < rang).length / rangs.length;
}

class _EcranQuestion extends ConsumerStatefulWidget {
  const _EcranQuestion({
    required this.etape,
    required this.questionnaire,
    required this.rang,
    super.key,
  });

  final EtapeQuestionnaire etape;
  final QuestionnaireInscription questionnaire;
  final int rang;

  @override
  ConsumerState<_EcranQuestion> createState() => _EcranQuestionState();
}

class _EcranQuestionState extends ConsumerState<_EcranQuestion> {
  /// La reaction de Praxis au dernier choix ; `null` : la phrase de l'ecran.
  String? _reaction;
  ExpressionPraxis? _expressionReaction;

  /// Le geste de la reaction ; `null` : celui de l'ecran.
  Geste? _gesteReaction;

  /// Vrai apres un « Continuer » sans reponse : la phrase le dit.
  bool _tente = false;

  late final TextEditingController _prenom = TextEditingController(
    text: _apprenant?.prenom ?? '',
  );
  late final TextEditingController _lectureAutre = TextEditingController(
    text: _apprenant?.lectureAutre ?? '',
  );
  late final TextEditingController _langueAutre = TextEditingController(
    text: widget.questionnaire.langueAutre,
  );

  QuestionnaireControleur get _c =>
      ref.read(questionnaireInscriptionProvider.notifier);

  QuestionnaireInscription get _q => widget.questionnaire;

  ApprenantQuestionnaire? get _apprenant =>
      widget.etape.parApprenant &&
          widget.etape.rang < widget.questionnaire.apprenants.length
      ? widget.questionnaire.apprenants[widget.etape.rang]
      : null;

  int get _i => widget.etape.rang;

  @override
  void initState() {
    super.initState();
    _detecterFuseau();
    // « Deduit > choisi > saisi » : la langue de l'appareil est proposee.
    if (widget.etape.sorte == SorteEtape.langue &&
        widget.questionnaire.langue == null) {
      final String? deduite = langueDeLAppareil(
        WidgetsBinding.instance.platformDispatcher.locale.languageCode,
      );
      if (deduite != null) {
        WidgetsBinding.instance.addPostFrameCallback((Duration _) {
          if (mounted) _c.choisirLangue(deduite);
        });
      }
    }
  }

  /// Le fuseau lu sur l'appareil, au recapitulatif (« deduit > choisi »).
  void _detecterFuseau() {
    if (widget.etape.sorte != SorteEtape.recap ||
        widget.questionnaire.fuseau != null) {
      return;
    }
    final String? lu = fuseauIanaAppareil();
    if (lu == null) return;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) _c.detecterFuseau(lu);
    });
  }

  @override
  void dispose() {
    _prenom.dispose();
    _lectureAutre.dispose();
    _langueAutre.dispose();
    super.dispose();
  }

  /// La reaction de Praxis a un choix. Comme la maquette, une reaction qui
  /// change son visage pose ses mains (sauf geste donne) ; une phrase seule
  /// garde le geste de l'ecran.
  void _reagir(String phrase, [ExpressionPraxis? expression, Geste? geste]) =>
      setState(() {
        _reaction = phrase;
        _expressionReaction = expression;
        _gesteReaction = geste ?? (expression == null ? null : Geste.aucun);
        _tente = false;
      });

  bool get _compteCree =>
      ref.read(sessionProvider).porte == PorteAcces.inscription;

  /// L'ecran suivant du plan, une fois la reponse retenue.
  void _avancer() {
    final QuestionnaireInscription apres = ref.read(
      questionnaireInscriptionProvider,
    );
    final List<EtapeQuestionnaire> plan = apres.etapes;
    final int ici = plan.indexOf(widget.etape);
    if (ici >= 0 && ici + 1 < plan.length) {
      context.go(QuestionnairePage.adresse(plan[ici + 1]));
      return;
    }
    context.go(
      _compteCree ? Routes.inscription : QuestionnairePage.adresseAcces,
    );
  }

  void _aller(EtapeQuestionnaire etape) =>
      context.go(QuestionnairePage.adresse(etape));

  /// Le retour : l'ecran precedent du plan. Revenir du prenom d'un apprenant
  /// ajoute, sans l'avoir saisi, le retire et ramene a la famille.
  VoidCallback? get _retour {
    if (widget.etape.sorte == SorteEtape.enseigner) {
      return () => _aller(const EtapeQuestionnaire(SorteEtape.garde));
    }
    if (widget.rang <= 0) return null;
    return () {
      final EtapeQuestionnaire e = widget.etape;
      if (e.sorte == SorteEtape.prenom && e.rang > 0 && !_q.repondue(e)) {
        _c.retirer(e.rang);
        _aller(const EtapeQuestionnaire(SorteEtape.famille));
        return;
      }
      _aller(_q.etapes[widget.rang - 1]);
    };
  }

  /// « Continuer » n'est jamais grise (BOUTONS-GRISES-1) : sans reponse, il le
  /// dit sous la question.
  void _continuer({required bool pret, VoidCallback? avant}) {
    if (!pret) {
      setState(() => _tente = true);
      return;
    }
    avant?.call();
    _avancer();
  }

  ActionPrincipale _bouton(String libelle, VoidCallback onPress) =>
      ActionPrincipale(
        key: const Key('questionnaire-continuer'),
        libelle: libelle,
        onPress: onPress,
        affirmee: true,
      );

  Widget _requis() => Semantics(
    liveRegion: true,
    child: Text(
      t.inscription.champRequis,
      key: const Key('questionnaire-reponse-requise'),
      style: AppPalette.of(context).inkAlert
          .applyTo(Theme.of(context).textTheme.bodyMedium ?? const TextStyle()),
    ),
  );

  LienFleche _lienDejaCompte() => LienFleche(
    key: const Key('questionnaire-deja-un-compte'),
    libelle: t.onboarding.accueil.dejaCompte,
    onPress: () => context.go(adresseConnexionDemandee),
  );

  /// Un groupe de cartes a choix unique.
  Widget _cartes({
    required String cle,
    required List<(String, String, String?)> options,
    required String? retenue,
    required void Function(String valeur) onChoix,
  }) => ChoiceCardGroup(
    key: ValueKey<String>('questionnaire-$cle'),
    autoriserSaisieLibre: false,
    // La maquette : des cartes empilees, a toutes les largeurs (jamais le
    // bento du grand ecran).
    compacte: true,
    valeurInitiale: retenue == null
        ? null
        : ReponseChoix(valeurs: <String>{retenue}),
    options: <OptionChoix>[
      for (final (String v, String libelle, String? description) in options)
        OptionChoix(
          cle: ValueKey<String>('questionnaire-$cle-$v'),
          valeur: v,
          libelle: libelle,
          description: description,
        ),
    ],
    onChange: (ReponseChoix r) {
      if (r.valeurs.isNotEmpty) onChoix(r.valeurs.first);
    },
  );

  /// Des puces (choix courts), dans un `Wrap`.
  Widget _puces({
    required String cle,
    required List<(String, String)> options,
    required bool Function(String valeur) retenue,
    required void Function(String valeur) onChoix,
  }) =>
      // Choix de formulaire, pas un filtre : une reponse au questionnaire.
      Wrap(
        key: ValueKey<String>('questionnaire-$cle'),
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: <Widget>[
          for (final (String v, String libelle) in options)
            FilterPill(
              key: ValueKey<String>('questionnaire-$cle-$v'),
              libelle: libelle,
              retenue: retenue(v),
              onPress: () => onChoix(v),
            ),
        ],
      );

  CoquilleOnboarding _ecran({
    required String phrase,
    required List<Widget> corps,
    ExpressionPraxis expression = ExpressionPraxis.attente,
    bool grand = false,
    String? titre,
    String? sousTitre,
    Widget? action,
    List<Widget> liens = const <Widget>[],
    String? indice,
  }) {
    final List<EtapeQuestionnaire> plan = _q.etapes;
    final Chapitre? chapitre = widget.etape.chapitre;
    return CoquilleOnboarding(
      chapitre: chapitre,
      remplissage: chapitre == null || widget.rang < 0
          ? const <double>[0, 0, 0, 0]
          : remplissageOnboarding(plan, widget.rang),
      onRetour: _retour,
      phrase: _reaction ?? phrase,
      expression: _expressionReaction ?? expression,
      geste: _gesteReaction ?? gesteDeLEcran(widget.etape.sorte),
      grand: grand,
      titre: titre,
      sousTitre: sousTitre,
      corps: <Widget>[
        // ONBOARDING-BOUCLE (14/11/2026) : la session est arrivee ici sans
        // les reponses (autre navigateur) : on le dit.
        if (ref.watch(reponsesResteesAilleursProvider) &&
            !_q.complet &&
            widget.etape.sorte == SorteEtape.accueil) ...<Widget>[
          BandeauAttention(
            key: const ValueKey<String>('questionnaire-absentes'),
            titre: t.inscription.questionnaire.acces.absentesTitre,
            message: t.inscription.questionnaire.acces.absentesPhrase,
          ),
          Ecart.vLg,
        ],
        ...corps,
        if (_tente) ...<Widget>[Ecart.vMd, _requis()],
      ],
      action: action,
      liens: liens,
      indice: indice,
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = t.onboarding;
    final ApprenantQuestionnaire? a = _apprenant;
    final bool moi = a?.titulaire ?? false;
    final String prenom = a?.prenom ?? '';
    final bool elle = a?.genre == Genre.femme;
    switch (widget.etape.sorte) {
      case SorteEtape.accueil:
        return _ecran(
          grand: true,
          expression: ExpressionPraxis.joie,
          phrase: o.accueil.dit,
          titre: o.accueil.titre,
          sousTitre: o.accueil.sous,
          corps: const <Widget>[],
          action: _bouton(o.accueil.commencer, () {
            _c.commencer();
            _avancer();
          }),
          liens: <Widget>[_lienDejaCompte()],
          indice: o.praxisIa,
        );
      case SorteEtape.garde:
        return _ecran(
          phrase: o.garde.dit,
          titre: o.garde.titre,
          corps: <Widget>[
            _cartes(
              cle: 'garde',
              retenue: _q.apprendre ? 'apprendre' : null,
              options: <(String, String, String?)>[
                ('apprendre', o.garde.apprendre, o.garde.apprendreDesc),
                ('enseigner', o.garde.enseigner, o.garde.enseignerDesc),
              ],
              onChoix: (String v) {
                if (v == 'enseigner') {
                  _aller(const EtapeQuestionnaire(SorteEtape.enseigner));
                  return;
                }
                _c.apprendre();
                _reagir(
                  o.garde.reponse,
                  ExpressionPraxis.sourire,
                  Geste.pointe,
                );
              },
            ),
          ],
          action: _bouton(
            t.commun.continuer,
            () => _continuer(
              pret: ref.read(questionnaireInscriptionProvider).apprendre,
            ),
          ),
          liens: <Widget>[_lienDejaCompte()],
        );
      case SorteEtape.enseigner:
        return _ecran(
          grand: true,
          expression: ExpressionPraxis.sourire,
          phrase: o.enseigner.dit,
          titre: o.enseigner.titre,
          sousTitre: o.enseigner.sous,
          corps: const <Widget>[],
          action: _bouton(o.enseigner.commencer, () {
            // POSTULER-ICI : la candidature sans invitation (CAND-04), par le
            // chemin existant du lien direct du candidat (`candidature=1`) :
            // la creation du compte, puis l'ecran de la candidature. Aucune
            // demande d'eleve n'est creee.
            retenirInvitationEnCours(candidature: true);
            context.go(
              Uri(
                path: Routes.connexion,
                queryParameters: <String, String>{
                  'mode': parametreModeCreation,
                  parametreCandidature: '1',
                },
              ).toString(),
            );
          }),
          liens: <Widget>[
            LienFleche(
              key: const Key('questionnaire-enseigner-trompe'),
              libelle: o.enseigner.trompe,
              fleche: false,
              onPress: () => _aller(const EtapeQuestionnaire(SorteEtape.garde)),
            ),
          ],
        );
      case SorteEtape.pourQui:
        return _ecran(
          phrase: o.pourQui.dit,
          titre: o.pourQui.titre,
          corps: <Widget>[
            _cartes(
              cle: 'pour-qui',
              retenue: _q.pourQui?.name,
              options: <(String, String, String?)>[
                (PourQui.moi.name, o.pourQui.moi, o.pourQui.moiDesc),
                (
                  PourQui.unEnfant.name,
                  o.pourQui.unEnfant,
                  o.pourQui.unEnfantDesc,
                ),
                (
                  PourQui.plusieurs.name,
                  o.pourQui.plusieurs,
                  o.pourQui.plusieursDesc,
                ),
              ],
              onChoix: (String v) {
                final PourQui p = PourQui.values.byName(v);
                _c.choisirPourQui(p);
                _reagir(switch (p) {
                  PourQui.moi => o.pourQui.reponseMoi,
                  PourQui.unEnfant => o.pourQui.reponseUn,
                  PourQui.plusieurs => o.pourQui.reponsePlusieurs,
                }, ExpressionPraxis.joie);
              },
            ),
          ],
          action: _bouton(
            t.commun.continuer,
            () => _continuer(
              pret: ref.read(questionnaireInscriptionProvider).pourQui != null,
              avant: _c.validerPourQui,
            ),
          ),
          liens: <Widget>[
            LienFleche(
              key: const Key('questionnaire-mineur'),
              libelle: o.pourQui.mineur,
              fleche: false,
              onPress: () => _reagir(o.pourQui.mineurReponse),
            ),
          ],
        );
      case SorteEtape.prenom:
        final bool premier = _i == 0;
        final bool valide = prenomValide(_prenom.text);
        return _ecran(
          phrase: moi
              ? o.prenom.ditMoi
              : premier
              ? o.prenom.ditEnfant
              : o.prenom.ditSuivant,
          titre: moi
              ? o.prenom.titreMoi
              : premier
              ? o.prenom.titreEnfant
              : o.prenom.titreSuivant,
          sousTitre: moi ? o.prenom.sousMoi : o.prenom.sousEnfant,
          corps: <Widget>[
            ChampEtiquete(
              cleChamp: const Key('questionnaire-prenom'),
              libelle: o.prenom.etiquette,
              obligatoire: true,
              indice: moi ? o.prenom.indiceMoi : o.prenom.indice,
              controller: _prenom,
              textCapitalization: TextCapitalization.words,
              remplissage: const <String>[AutofillHints.givenName],
              actionClavier: TextInputAction.done,
              inputFormatters: <TextInputFormatter>[
                LengthLimitingTextInputFormatter(30),
              ],
              erreur: _tente && !valide ? o.prenom.refus : null,
              onChanged: (String v) {
                final bool bon = prenomValide(v);
                setState(() {
                  _tente = false;
                  if (v.trim().isNotEmpty && !bon) {
                    _reaction = o.prenom.refus;
                    _expressionReaction = ExpressionPraxis.reflexion;
                  } else {
                    _reaction = null;
                    _expressionReaction = null;
                  }
                });
              },
              onSubmitted: (String _) => _validerPrenom(),
            ),
          ],
          action: _bouton(t.commun.continuer, _validerPrenom),
        );
      case SorteEtape.age:
        return _ecran(
          phrase: o.age.titre(prenom: prenom),
          titre: o.age.titre(prenom: prenom),
          sousTitre: o.age.sous,
          corps: <Widget>[
            _puces(
              cle: 'age',
              options: <(String, String)>[
                for (int n = ageMinimum; n <= ageMaximum; n++) ('$n', '$n'),
              ],
              retenue: (String v) => a?.age == int.parse(v),
              onChoix: (String v) {
                final int n = int.parse(v);
                _c.modifier(_i, (ApprenantQuestionnaire x) => x.copier(age: n));
                _reagir(
                  LibellesGroupe.insecable(o.age.reponse(n: n)),
                  ExpressionPraxis.sourire,
                );
              },
            ),
          ],
          action: _bouton(
            t.commun.continuer,
            () => _continuer(pret: _apprenantLu?.age != null),
          ),
          liens: <Widget>[
            LienFleche(
              key: const Key('questionnaire-age-adulte'),
              libelle: o.age.adulte,
              fleche: false,
              onPress: () => _reagir(o.age.adulteReponse),
            ),
          ],
        );
      case SorteEtape.genre:
        return _ecran(
          phrase: o.genre.dit,
          titre: moi ? o.genre.titreMoi : o.genre.titre(prenom: prenom),
          corps: <Widget>[
            _cartes(
              cle: 'genre',
              retenue: a?.genre?.name,
              options: <(String, String, String?)>[
                (Genre.homme.name, moi ? o.genre.homme : o.genre.garcon, null),
                (Genre.femme.name, moi ? o.genre.femme : o.genre.fille, null),
              ],
              onChoix: (String v) {
                final Genre g = Genre.values.byName(v);
                _c.modifier(
                  _i,
                  (ApprenantQuestionnaire x) => x.copier(genre: g),
                );
                _reagir(o.genre.reponse, ExpressionPraxis.sourire);
              },
            ),
          ],
          action: _bouton(
            t.commun.continuer,
            () => _continuer(pret: _apprenantLu?.genre != null),
          ),
        );
      case SorteEtape.famille:
        return interludeFamille(context, ref, _ecran, _aller, _avancer);
      case SorteEtape.niveau:
        final String sujet = moi ? 'moi' : (elle ? 'elle' : 'il');
        String lib(NiveauDeclare n) => libelleNiveauSujet(n, sujet);
        return _ecran(
          phrase: o.niveau.dit,
          titre: moi ? o.niveau.titreMoi : o.niveau.titre(prenom: prenom),
          corps: <Widget>[
            _cartes(
              cle: 'niveau',
              retenue: a?.niveau?.valeurSql,
              options: <(String, String, String?)>[
                for (final NiveauDeclare n in NiveauDeclare.values)
                  (n.valeurSql, lib(n), descriptionNiveau(n)),
              ],
              onChoix: (String v) {
                final NiveauDeclare n = NiveauDeclare.depuisSql(v)!;
                _c.choisirNiveau(_i, n);
                _reagir(switch (n) {
                  NiveauDeclare.debutLettres => o.niveau.reponseDebut,
                  NiveauDeclare.memorisationPartielle => o.niveau.reponseMemo,
                  NiveauDeclare.lectureCourante => o.niveau.reponseLecture,
                  _ => o.niveau.reponse,
                }, ExpressionPraxis.reflexion);
              },
            ),
          ],
          action: _bouton(
            t.commun.continuer,
            () => _continuer(pret: _apprenantLu?.niveau != null),
          ),
        );
      case SorteEtape.lecture:
        final LectureCoran lecture = a?.lecture ?? LectureCoran.hafs;
        return _ecran(
          expression: ExpressionPraxis.reflexion,
          phrase: o.lecture.dit,
          titre: moi
              ? o.lecture.titreMoi
              : elle
              ? o.lecture.titreElle(prenom: prenom)
              : o.lecture.titreIl(prenom: prenom),
          sousTitre: o.lecture.sous,
          corps: <Widget>[
            _cartes(
              cle: 'lecture',
              retenue: lecture.name,
              options: <(String, String, String?)>[
                (LectureCoran.hafs.name, o.lecture.hafs, o.lecture.hafsDesc),
                (LectureCoran.warsh.name, o.lecture.warsh, o.lecture.warshDesc),
                (LectureCoran.autre.name, o.lecture.autre, o.lecture.autreDesc),
              ],
              onChoix: (String v) {
                final LectureCoran l = LectureCoran.values.byName(v);
                _c.modifier(
                  _i,
                  (ApprenantQuestionnaire x) => x.copier(lecture: l),
                );
                _reagir(switch (l) {
                  LectureCoran.hafs => o.lecture.reponseHafs,
                  LectureCoran.warsh => o.lecture.reponseWarsh,
                  LectureCoran.autre => o.lecture.reponseAutre,
                }, ExpressionPraxis.reflexion);
              },
            ),
            if (lecture == LectureCoran.autre) ...<Widget>[
              Ecart.vLg,
              ChampEtiquete(
                cleChamp: const Key('questionnaire-lecture-autre'),
                libelle: o.lecture.autreEtiquette,
                indice: o.lecture.autreIndice,
                controller: _lectureAutre,
                inputFormatters: <TextInputFormatter>[
                  LengthLimitingTextInputFormatter(40),
                ],
                onChanged: (String v) => _c.modifier(
                  _i,
                  (ApprenantQuestionnaire x) =>
                      x.copier(lectureAutre: v.trim()),
                ),
              ),
            ],
          ],
          action: _bouton(t.commun.continuer, _avancer),
        );
      case SorteEtape.memorise:
        return _ecran(
          phrase: o.memorise.dit,
          titre: moi
              ? o.memorise.titreMoi
              : elle
              ? o.memorise.titreElle(prenom: prenom)
              : o.memorise.titreIl(prenom: prenom),
          corps: <Widget>[
            _cartes(
              cle: 'memorise',
              retenue: a?.quantite?.valeurSql,
              options: <(String, String, String?)>[
                for (final QuantiteMemorisee m in QuantiteMemorisee.values)
                  (m.valeurSql, libelleQuantite(m), null),
              ],
              onChoix: (String v) {
                final QuantiteMemorisee m = QuantiteMemorisee.depuisSql(v)!;
                _c.modifier(
                  _i,
                  (ApprenantQuestionnaire x) => x.copier(quantite: m),
                );
                _reagir(
                  m == QuantiteMemorisee.coranEntier
                      ? o.memorise.reponseTout
                      : o.memorise.reponse,
                  ExpressionPraxis.etonne,
                );
              },
            ),
          ],
          action: _bouton(
            t.commun.continuer,
            () => _continuer(pret: _apprenantLu?.quantite != null),
          ),
        );
      case SorteEtape.detail:
        final bool enJuz = a?.detailEnJuz ?? true;
        return _ecran(
          expression: ExpressionPraxis.concentre,
          phrase: enJuz ? o.detail.ditJuz : o.detail.ditSourates,
          titre: enJuz ? o.detail.titreJuz : o.detail.titreSourates,
          sousTitre: o.detail.sous,
          corps: <Widget>[
            _puces(
              cle: enJuz ? 'juz' : 'sourates',
              options: enJuz
                  ? <(String, String)>[
                      for (int j = 1; j <= 30; j++) ('$j', '$j'),
                    ]
                  : <(String, String)>[
                      for (final String s in souratesDesBases)
                        (s, nomSourate(s)),
                    ],
              retenue: (String v) => enJuz
                  ? (_apprenantLu?.juz.contains(int.parse(v)) ?? false)
                  : (_apprenantLu?.sourates.contains(v) ?? false),
              onChoix: (String v) {
                if (enJuz) {
                  _c.basculerDetail(_i, juz: int.parse(v));
                } else {
                  _c.basculerDetail(_i, sourate: v);
                }
                final ApprenantQuestionnaire? apres = _apprenantLu;
                final int n = enJuz
                    ? apres?.juz.length ?? 0
                    : apres?.sourates.length ?? 0;
                _reagir(
                  n == 0
                      ? o.detail.aucun
                      : n == 1
                      ? o.detail.un
                      : o.detail.plusieurs(n: n),
                  ExpressionPraxis.reflexion,
                );
              },
            ),
          ],
          action: _bouton(t.commun.continuer, _avancer),
        );
      case SorteEtape.objectif:
        final bool bases =
            a?.niveau == NiveauDeclare.debutLettres ||
            a?.niveau == NiveauDeclare.lettresAvecAide;
        return _ecran(
          phrase: o.objectif.dit,
          titre: moi ? o.objectif.titreMoi : o.objectif.titre(prenom: prenom),
          sousTitre: a?.niveau == NiveauDeclare.memorisationPartielle
              ? o.objectif.sousMemo
              : null,
          corps: <Widget>[
            _cartes(
              cle: 'objectif',
              retenue: a?.objectif?.name,
              options: <(String, String, String?)>[
                (
                  ObjectifOnboarding.lire.name,
                  bases ? o.objectif.lireBases : o.objectif.lireCourant,
                  bases ? o.objectif.lireBasesDesc : o.objectif.lireCourantDesc,
                ),
                (
                  ObjectifOnboarding.memoriser.name,
                  o.objectif.memoriser,
                  bases
                      ? o.objectif.memoriserApresBases
                      : o.objectif.memoriserAvec,
                ),
                if (!moi)
                  (
                    ObjectifOnboarding.priere.name,
                    o.objectif.priere,
                    o.objectif.priereDesc,
                  ),
                (
                  ObjectifOnboarding.indecis.name,
                  o.objectif.indecis,
                  o.objectif.indecisDesc,
                ),
              ],
              onChoix: (String v) {
                final ObjectifOnboarding ob = ObjectifOnboarding.values.byName(
                  v,
                );
                _c.modifier(
                  _i,
                  (ApprenantQuestionnaire x) => x.copier(objectif: ob),
                );
                _reagir(
                  ob == ObjectifOnboarding.indecis
                      ? o.objectif.reponseIndecis
                      : o.objectif.reponse,
                  ExpressionPraxis.joie,
                );
              },
            ),
          ],
          action: _bouton(
            t.commun.continuer,
            () => _continuer(pret: _apprenantLu?.objectif != null),
          ),
        );
      case SorteEtape.depart:
        return interludeDepart(context, _q, _ecran, _avancer);
      case SorteEtape.langue:
        return _ecran(
          phrase: o.langue.dit,
          titre: o.langue.titre,
          sousTitre: o.langue.sous,
          corps: <Widget>[
            for (final MapEntry<GroupeLangues, List<String>> g
                in languesDesExplications.entries) ...<Widget>[
              Text(
                nomGroupeLangues(g.key),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Ecart.vSm,
              _puces(
                cle: 'langue-${g.key.name}',
                options: <(String, String)>[
                  for (final String code in g.value) (code, nomLangue(code)),
                ],
                retenue: (String v) =>
                    ref.read(questionnaireInscriptionProvider).langue == v,
                onChoix: (String v) {
                  _c.choisirLangue(v);
                  _reagir(
                    o.langue.reponse(langue: nomLangue(v)),
                    ExpressionPraxis.sourire,
                  );
                },
              ),
              Ecart.vLg,
            ],
          ],
          action: _bouton(
            t.commun.continuer,
            () => _continuer(
              pret: ref.read(questionnaireInscriptionProvider).langue != null,
            ),
          ),
        );
      case SorteEtape.langueSecours:
        return _ecran(
          expression: ExpressionPraxis.reflexion,
          phrase: o.langueSecours.dit,
          titre: o.langueSecours.titre,
          sousTitre: o.langueSecours.sous,
          corps: <Widget>[
            _puces(
              cle: 'langue-secours',
              options: <(String, String)>[
                ('aucune', o.langueSecours.aucune),
                for (final String code in codesDesExplications)
                  if (code != _q.langue) (code, nomLangue(code)),
              ],
              retenue: (String v) {
                final String? s = ref
                    .read(questionnaireInscriptionProvider)
                    .langueSecours;
                return v == 'aucune' ? (_secoursTouche && s == null) : s == v;
              },
              onChoix: (String v) {
                _secoursTouche = true;
                _c.choisirLangueSecours(v == 'aucune' ? null : v);
                _reagir(
                  v == 'aucune'
                      ? o.langueSecours.reponseAucune
                      : o.langueSecours.reponse,
                  ExpressionPraxis.sourire,
                );
              },
            ),
            Ecart.vLg,
            ChampEtiquete(
              cleChamp: const Key('questionnaire-langue-autre'),
              libelle: o.langueSecours.autreEtiquette,
              indice: o.langueSecours.autreIndice,
              controller: _langueAutre,
              inputFormatters: <TextInputFormatter>[
                LengthLimitingTextInputFormatter(40),
              ],
              onChanged: _c.saisirLangueAutre,
            ),
          ],
          action: _bouton(t.commun.continuer, _avancer),
        );
      case SorteEtape.chemin:
        return interludeChemin(context, _q, _ecran, _avancer);
      case SorteEtape.recap:
        return interludeRecap(
          context,
          ref,
          _q,
          _ecran,
          // Sans fuseau, la demande ne part pas : jamais une valeur par
          // defaut (directeur, 22/11/2026).
          () => _continuer(
            pret: ref.read(questionnaireInscriptionProvider).fuseau != null,
          ),
        );
    }
  }

  /// Vrai des que « Aucune autre » a ete touche (sinon rien n'est retenu).
  bool _secoursTouche = false;

  /// L'apprenant tel qu'il est maintenant (apres un choix fait sur l'ecran).
  ApprenantQuestionnaire? get _apprenantLu {
    final List<ApprenantQuestionnaire> l = ref
        .read(questionnaireInscriptionProvider)
        .apprenants;
    return _i < l.length ? l[_i] : null;
  }

  void _validerPrenom() {
    if (!prenomValide(_prenom.text)) {
      setState(() {
        _tente = true;
        _reaction = t.onboarding.prenom.refus;
        _expressionReaction = ExpressionPraxis.reflexion;
      });
      return;
    }
    _c.modifier(
      _i,
      (ApprenantQuestionnaire x) => x.copier(prenom: _prenom.text.trim()),
    );
    _avancer();
  }
}

/// Le code de l'acces, apres le recapitulatif (`?etape=acces`).
const String codeEtapeAcces = 'acces';

/// Le parametre de la connexion qui dit « j'ai un code d'invitation » : la
/// creation du compte s'ouvre sans le questionnaire.
const String parametreInvitation = 'invitation';

/// Le parametre de la connexion qui porte l'invitation d'un second adulte a
/// rejoindre un foyer (INVITATION-SECOND-ADULTE, 07/11/2026).
const String parametreFoyer = 'foyer';

/// Ou mene la creation d'un compte (`/connexion?mode=creer`) : au
/// questionnaire tant qu'il n'est pas repondu, sauf avec un code
/// d'invitation ([parametreInvitation]), pour le candidat enseignant
/// ([parametreCandidature], CAND-04, et la branche « Enseigner » de
/// l'onboarding) ou pour l'adulte invite a rejoindre un foyer
/// ([parametreFoyer]). Fonction pure.
String? redirectionCreationCompte(
  Uri adresse, {
  required bool questionnaireComplet,
}) =>
    adresse.queryParameters['mode'] == parametreModeCreation &&
        !adresse.queryParameters.containsKey(parametreInvitation) &&
        !adresse.queryParameters.containsKey(parametreCandidature) &&
        !adresse.queryParameters.containsKey(parametreFoyer) &&
        !questionnaireComplet
    ? Routes.commencer
    : null;

/// Le geste de Praxis sur chaque ecran, comme la maquette (`pose(e, g)`) :
/// salut a l'accueil, il montre les choix, main sur le coeur a la famille et
/// au recapitulatif, il reflechit sur le chemin.
Geste gesteDeLEcran(SorteEtape sorte) => switch (sorte) {
  SorteEtape.accueil => Geste.salut,
  SorteEtape.garde ||
  SorteEtape.enseigner ||
  SorteEtape.pourQui ||
  SorteEtape.niveau ||
  SorteEtape.objectif ||
  SorteEtape.depart ||
  SorteEtape.langue => Geste.pointe,
  SorteEtape.famille || SorteEtape.recap => Geste.coeur,
  SorteEtape.chemin => Geste.reflexion,
  SorteEtape.prenom ||
  SorteEtape.age ||
  SorteEtape.genre ||
  SorteEtape.lecture ||
  SorteEtape.memorise ||
  SorteEtape.detail ||
  SorteEtape.langueSecours => Geste.aucun,
};
