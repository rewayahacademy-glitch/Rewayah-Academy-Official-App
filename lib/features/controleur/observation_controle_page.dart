// Observation structuree (CTR-03A, CT-5, doc 08 P-CTR-05) : une question par
// page (nature, domaine, personne concernee, texte, recapitulatif), puis
// « Envoyer le compte rendu ».
//
// UX_REVIEW_08 n° 7 :
// - cartes de choix (`ChoiceCardGroup`), jamais de liste deroulante ;
// - « Eleve precis » ouvre le roster autorise : prenom seul, une ligne par
//   eleve, aucun champ de recherche ni saisie libre (C8) ;
// - l'erreur « texte requis » apparait a la validation de l'etape et
//   disparait des la saisie ; aucun compteur (C15) ;
// - le retour d'etape garde toutes les reponses, en memoire seulement (C12) ;
// - aucun interrupteur de partage : la notice dit la transmission (C2) ;
// - aucun succes sans reponse du serveur ; en cas d'echec, la saisie reste.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/mouvement/apparition_douce.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/ecran_resultat.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/page_parcours.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/status_pill.dart' show TonEtat;
import 'compte_rendu_controle.dart';
import 'observation_controle.dart';

enum _Etape { nature, domaine, personne, texte, recapitulatif, envoye }

/// Le parcours d'observation du controleur.
class ObservationControlePage extends ConsumerStatefulWidget {
  /// Cree la page.
  const ObservationControlePage({
    super.key,
    this.seanceId,
    this.choix = ChoixCompteRendu.ajouterObservation,
    this.onRetour,
    this.onRevenir,
    this.onEcrireAdmin,
  });

  /// La visite dont on complete le rapport (`?seance=`, revue CT-R B1) ;
  /// inconnue : le message generique (C7), jamais la mission courante.
  final String? seanceId;

  /// L'entree choisie sur le compte rendu : observation ou point important.
  final ChoixCompteRendu choix;

  /// Le retour au compte rendu depuis la premiere etape ; par defaut, sa
  /// route. Le brouillon est abandonne : le compte rendu reste a terminer.
  final VoidCallback? onRetour;

  /// Le retour au Controle apres l'envoi ; par defaut, sa destination.
  final VoidCallback? onRevenir;

  /// La discussion avec l'administration (CTR-04) sur la mission de la
  /// visite (nulle si inconnue) ; par defaut, son fil dans Echanges.
  final void Function(String? missionId)? onEcrireAdmin;

  /// La cle d'une carte de nature.
  static Key cleNature(NatureObservation n) =>
      ValueKey<String>('ctr03a-nature-${n.name}');

  /// La cle d'une carte de domaine.
  static Key cleDomaine(DomaineObservation d) =>
      ValueKey<String>('ctr03a-domaine-${d.name}');

  /// La cle d'une carte de personne.
  static Key clePersonne(PersonneConcernee p) =>
      ValueKey<String>('ctr03a-personne-${p.name}');

  /// La cle de la ligne d'un eleve du roster.
  static Key cleEleve(String id) => ValueKey<String>('ctr03a-eleve-$id');

  /// La cle du champ de texte.
  static const Key texteKey = ValueKey<String>('ctr03a-texte');

  /// La cle de « Reessayer » quand la liste des eleves n'est pas recue.
  static const Key reessayerRosterKey = ValueKey<String>(
    'ctr03a-roster-reessayer',
  );

  /// Le libelle d'une nature.
  static String libelleNature(NatureObservation n) => switch (n) {
    NatureObservation.pointPositif => t.controleur.observation.pointPositif,
    NatureObservation.aSuivre => t.controleur.observation.aSuivre,
    NatureObservation.interventionAdmin =>
      t.controleur.observation.interventionAdmin,
  };

  /// Le libelle d'un domaine.
  static String libelleDomaine(DomaineObservation d) => switch (d) {
    DomaineObservation.pedagogie => t.controleur.observation.pedagogie,
    DomaineObservation.interaction => t.controleur.observation.interaction,
    DomaineObservation.gestionClasse => t.controleur.observation.gestionClasse,
    DomaineObservation.respectCadre => t.controleur.observation.respectCadre,
    DomaineObservation.climat => t.controleur.observation.climat,
    DomaineObservation.autre => t.controleur.observation.autre,
  };

  /// Le libelle d'une personne concernee.
  static String libellePersonne(PersonneConcernee p) => switch (p) {
    PersonneConcernee.enseignant => t.controleur.observation.enseignant,
    PersonneConcernee.classeEntiere => t.controleur.observation.classeEntiere,
    PersonneConcernee.elevePrecis => t.controleur.observation.elevePrecis,
    PersonneConcernee.aucun => t.controleur.observation.aucun,
  };

  @override
  ConsumerState<ObservationControlePage> createState() =>
      _ObservationControlePageState();
}

class _ObservationControlePageState
    extends ConsumerState<ObservationControlePage> {
  _Etape _etape = _Etape.nature;
  NatureObservation? _nature;
  DomaineObservation? _domaine;
  PersonneConcernee? _personne;
  String? _eleveId;
  final TextEditingController _texte = TextEditingController();
  bool _texteManquant = false;
  bool _enCours = false;
  bool _echec = false;

  /// La visite, retrouvee par sa seance ; nulle si inconnue.
  late final CompteRenduEnSuspens? _visite = visiteDeSeance(
    ref,
    widget.seanceId,
  );

  bool get _important => widget.choix == ChoixCompteRendu.pointImportant;

  bool get _texteRequis =>
      texteObligatoire(important: _important, nature: _nature);

  @override
  void dispose() {
    _texte.dispose();
    super.dispose();
  }

  void _aller(_Etape etape) => setState(() {
    _etape = etape;
    _echec = false;
  });

  void _precedent() {
    switch (_etape) {
      case _Etape.nature:
        final VoidCallback? f = widget.onRetour;
        if (f == null) {
          GoRouter.of(context).go(
            adresseCompteRendu(Routes.controleurCompteRendu, widget.seanceId),
          );
        } else {
          f();
        }
      case _Etape.domaine:
        _aller(_Etape.nature);
      case _Etape.personne:
        _aller(_Etape.domaine);
      case _Etape.texte:
        _aller(_Etape.personne);
      case _Etape.recapitulatif:
        _aller(_Etape.texte);
      case _Etape.envoye:
        break;
    }
  }

  void _validerTexte() {
    if (_texteRequis && _texte.text.trim().isEmpty) {
      setState(() => _texteManquant = true);
      return;
    }
    _aller(_Etape.recapitulatif);
  }

  Future<void> _envoyer() async {
    final NatureObservation? nature = _nature;
    final DomaineObservation? domaine = _domaine;
    final PersonneConcernee? personne = _personne;
    final CompteRenduEnSuspens? visite = _visite;
    if (_enCours ||
        visite == null ||
        nature == null ||
        domaine == null ||
        personne == null) {
      return;
    }
    // Garde-fou : un texte obligatoire vide ne part jamais.
    if (_texteRequis && _texte.text.trim().isEmpty) {
      setState(() {
        _etape = _Etape.texte;
        _texteManquant = true;
      });
      return;
    }
    setState(() {
      _enCours = true;
      _echec = false;
    });
    try {
      await ref
          .read(envoiCompteRenduProvider)
          .envoyerObservation(
            visite.seanceId,
            ObservationControle(
              important: _important,
              nature: nature,
              domaine: domaine,
              personne: personne,
              eleveId: personne == PersonneConcernee.elevePrecis
                  ? _eleveId
                  : null,
              texte: _texte.text.trim(),
            ),
          );
      if (!mounted) return;
      ref.read(compteRenduATerminerProvider.notifier).terminer(visite.seanceId);
      setState(() {
        _enCours = false;
        _etape = _Etape.envoye;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _echec = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mission devenue indisponible : l'observation se termine quand meme
    // apres la sortie (C1), comme le compte rendu.
    if (_etape == _Etape.envoye) {
      return PageShell(
        titre: t.controleur.compteRendu.titre,
        child: ApparitionDouce(
          child: EcranResultat(
            icone: AppIcons.succes,
            ton: TonEtat.succes,
            titre: t.controleur.compteRendu.envoyeTitre,
            phrase: t.controleur.compteRendu.envoyePhrase,
            libelleAction: t.controleur.compteRendu.revenir,
            onAction:
                widget.onRevenir ??
                () => GoRouter.of(context).go(Routes.controleur),
            libelleSecondaire: t.controleur.compteRendu.ecrireAdmin,
            // Le fil de la mission de CETTE visite (P-CTR-06), la liste si
            // son identifiant n'est pas connu ; jamais la mission courante.
            onSecondaire: () => widget.onEcrireAdmin == null
                ? GoRouter.of(context)
                      .go(Routes.controleurEcrireAdmin(_visite?.missionId))
                : widget.onEcrireAdmin!(_visite?.missionId),
          ),
        ),
      );
    }
    if (_visite == null) {
      // Seance inconnue (rechargement, lien direct) : la visite n'est plus en
      // memoire, jamais une autre mission (C7, revue CT-R B1, CTRL-MSG-1).
      return PageShell(
        titre: t.controleur.compteRendu.titre,
        child: EmptyState(
          message: t.controleur.compteRendu.visiteInconnue,
          invitation: t.controleur.compteRendu.visiteInconnueAide,
          registre: RegistreVide.subi,
          libelleAction: t.controleur.compteRendu.revenir,
          onAction:
              widget.onRevenir ??
              () => GoRouter.of(context).go(Routes.controleur),
        ),
      );
    }

    final o = t.controleur.observation;
    final String question;
    String? explication;
    final Widget corps;
    VoidCallback? action;
    String libelle = t.commun.continuer;
    switch (_etape) {
      case _Etape.nature:
        question = o.questionNature;
        // Phrase de contexte et lignes « quand · consequence » (K-58) :
        // libelles provisoires (D4), proposes par un agent.
        explication = _important ? o.important : o.contexteNature;
        corps = _cartes<NatureObservation>(
          NatureObservation.values,
          _nature,
          ObservationControlePage.libelleNature,
          ObservationControlePage.cleNature,
          (NatureObservation n) => setState(() {
            _nature = n;
            _texteManquant = false;
          }),
          icone: (NatureObservation n) => switch (n) {
            NatureObservation.pointPositif => AppIcons.succes,
            NatureObservation.aSuivre => AppIcons.noter,
            NatureObservation.interventionAdmin => AppIcons.signaler,
          },
          description: (NatureObservation n) => switch (n) {
            NatureObservation.pointPositif => o.pointPositifAide,
            NatureObservation.aSuivre => o.aSuivreAide,
            NatureObservation.interventionAdmin => o.interventionAdminAide,
          },
        );
        if (_nature != null) action = () => _aller(_Etape.domaine);
      case _Etape.domaine:
        question = o.questionDomaine;
        explication = o.contexteDomaine;
        corps = _cartes<DomaineObservation>(
          DomaineObservation.values,
          _domaine,
          ObservationControlePage.libelleDomaine,
          ObservationControlePage.cleDomaine,
          (DomaineObservation d) => setState(() => _domaine = d),
          // Une ligne « quand » par domaine, sans consequence inventee (D4).
          description: (DomaineObservation d) => switch (d) {
            DomaineObservation.pedagogie => o.pedagogieAide,
            DomaineObservation.interaction => o.interactionAide,
            DomaineObservation.gestionClasse => o.gestionClasseAide,
            DomaineObservation.respectCadre => o.respectCadreAide,
            DomaineObservation.climat => o.climatAide,
            DomaineObservation.autre => o.autreAide,
          },
        );
        if (_domaine != null) action = () => _aller(_Etape.personne);
      case _Etape.personne:
        question = o.questionPersonne;
        explication = o.contextePersonne;
        corps = _personneEtRoster();
        final bool pret =
            _personne != null &&
            (_personne != PersonneConcernee.elevePrecis || _eleveId != null);
        if (pret) action = () => _aller(_Etape.texte);
      case _Etape.texte:
        question = o.questionTexte;
        explication = _texteRequis ? o.texteObligatoire : o.texteFacultatif;
        corps = _champTexte();
        action = _validerTexte;
      case _Etape.recapitulatif:
      case _Etape.envoye:
        question = o.questionRecap;
        corps = _recapitulatif();
        action = _envoyer;
        libelle = t.controleur.compteRendu.envoyer;
    }

    return PageParcours(
      numero: _etape.index + 1,
      total: 5,
      question: question,
      explication: explication,
      enfant: ApparitionDouce(key: ValueKey<_Etape>(_etape), child: corps),
      libelleAction: libelle,
      onAction: _enCours ? null : action,
      onRetour: _enCours ? null : _precedent,
      enCours: _enCours,
      souscription: _etape == _Etape.recapitulatif
          ? _Souscription(echec: _echec, sansTexte: _texte.text.trim().isEmpty)
          : null,
    );
  }

  Widget _cartes<E extends Enum>(
    List<E> valeurs,
    E? retenue,
    String Function(E) libelle,
    Key Function(E) cle,
    void Function(E) onChoix, {
    AppIcon Function(E)? icone,
    String Function(E)? description,
  }) => ChoiceCardGroup(
    key: ValueKey<Type>(E),
    autoriserSaisieLibre: false,
    valeurInitiale: retenue == null
        ? null
        : ReponseChoix(valeurs: <String>{retenue.name}),
    options: <OptionChoix>[
      for (final E v in valeurs)
        OptionChoix(
          cle: cle(v),
          valeur: v.name,
          libelle: libelle(v),
          description: description?.call(v),
          icone: icone?.call(v),
        ),
    ],
    onChange: (ReponseChoix r) {
      if (r.valeurs.isEmpty) return;
      onChoix(valeurs.firstWhere((E v) => v.name == r.valeurs.first));
    },
  );

  Widget _personneEtRoster() {
    final AsyncValue<List<EleveRoster>> etatRoster = ref.watch(
      rosterControleProvider,
    );
    final List<EleveRoster> roster = etatRoster.hasError
        ? const <EleveRoster>[]
        : etatRoster.value ?? const <EleveRoster>[];
    final o = t.controleur.observation;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String? eleve = _eleveId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _cartes<PersonneConcernee>(
          PersonneConcernee.values,
          _personne,
          ObservationControlePage.libellePersonne,
          ObservationControlePage.clePersonne,
          (PersonneConcernee p) => setState(() {
            _personne = p;
            if (p != PersonneConcernee.elevePrecis) _eleveId = null;
          }),
          description: (PersonneConcernee p) => switch (p) {
            PersonneConcernee.enseignant => o.enseignantAide,
            PersonneConcernee.classeEntiere => o.classeEntiereAide,
            PersonneConcernee.elevePrecis => o.elevePrecisAide,
            PersonneConcernee.aucun => o.aucunAide,
          },
        ),
        if (_personne == PersonneConcernee.elevePrecis) ...<Widget>[
          Ecart.vXl,
          ApparitionDouce(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Revue CT-R m2 : chargement, erreur (avec « Reessayer ») et
                // liste vide sont trois etats distincts (K-59).
                Semantics(
                  header: roster.isNotEmpty,
                  liveRegion: roster.isEmpty,
                  child: Text(
                    switch (etatRoster) {
                      AsyncValue<List<EleveRoster>>(
                        isLoading: true,
                        hasValue: false,
                      ) =>
                        o.rosterChargement,
                      AsyncValue<List<EleveRoster>>(hasError: true) =>
                        o.rosterIndisponible,
                      AsyncValue<List<EleveRoster>>(hasValue: false) =>
                        o.rosterChargement,
                      _ when roster.isEmpty => o.rosterVide,
                      _ => o.questionEleve,
                    },
                    style:
                        (roster.isEmpty ? palette.inkMuted : palette.inkStrong)
                            .applyTo(
                              (roster.isEmpty
                                      ? textes.bodyMedium
                                      : textes.titleMedium) ??
                                  const TextStyle(),
                            ),
                  ),
                ),
                if (etatRoster.hasError && !etatRoster.isLoading) ...<Widget>[
                  Ecart.vMd,
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ActionPrincipale(
                      key: ObservationControlePage.reessayerRosterKey,
                      libelle: t.commun.reessayer,
                      niveau: NiveauAction.secondaire,
                      pleineLargeur: false,
                      onPress: () => ref.invalidate(rosterControleProvider),
                    ),
                  ),
                ],
                if (roster.isNotEmpty) ...<Widget>[
                  Ecart.vMd,
                  ChoiceCardGroup(
                    key: const ValueKey<String>('ctr03a-roster'),
                    autoriserSaisieLibre: false,
                    valeurInitiale: eleve == null
                        ? null
                        : ReponseChoix(valeurs: <String>{eleve}),
                    options: <OptionChoix>[
                      for (final EleveRoster e in roster)
                        OptionChoix(
                          cle: ObservationControlePage.cleEleve(e.id),
                          valeur: e.id,
                          libelle: e.prenom,
                        ),
                    ],
                    onChange: (ReponseChoix r) => setState(
                      () =>
                          _eleveId = r.valeurs.isEmpty ? null : r.valeurs.first,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _champTexte() => TextField(
    key: ObservationControlePage.texteKey,
    controller: _texte,
    minLines: 4,
    maxLines: 8,
    textCapitalization: TextCapitalization.sentences,
    decoration: InputDecoration(
      labelText: t.controleur.observation.libelleTexte,
      hintText: t.controleur.observation.aideTexte,
      alignLabelWithHint: true,
      // L'aide du document reste lisible avant la saisie.
      floatingLabelBehavior: FloatingLabelBehavior.always,
      errorText: _texteManquant ? t.controleur.observation.texteRequis : null,
    ),
    // L'erreur disparait des la saisie (BAY-IV) ; aucune validation pendant
    // la frappe.
    onChanged: (String _) {
      if (_texteManquant) setState(() => _texteManquant = false);
    },
  );

  Widget _recapitulatif() {
    final o = t.controleur.observation;
    final List<EleveRoster> roster =
        ref.watch(rosterControleProvider).value ?? const <EleveRoster>[];
    final PersonneConcernee? p = _personne;
    final NatureObservation? n = _nature;
    final DomaineObservation? d = _domaine;
    String personne = p == null
        ? ''
        : ObservationControlePage.libellePersonne(p);
    if (p == PersonneConcernee.elevePrecis) {
      for (final EleveRoster e in roster) {
        if (e.id == _eleveId) personne = '$personne · ${e.prenom}';
      }
    }
    final String texte = _texte.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        LigneCleValeur(
          cle: o.cleNature,
          valeur: n == null ? '' : ObservationControlePage.libelleNature(n),
        ),
        LigneCleValeur(
          cle: o.cleDomaine,
          valeur: d == null ? '' : ObservationControlePage.libelleDomaine(d),
        ),
        LigneCleValeur(cle: o.clePersonne, valeur: personne),
        LigneCleValeur(
          cle: o.cleTexte,
          valeur: texte.isEmpty ? o.sansTexte : texte,
        ),
      ],
    );
  }
}

/// La notice de transmission, au-dessus du bouton, et l'echec honnete.
class _Souscription extends StatelessWidget {
  const _Souscription({required this.echec, required this.sansTexte});

  final bool echec;

  /// Texte facultatif laisse vide : l'echec ne parle pas d'un texte garde
  /// (CTRL-MSG-1).
  final bool sansTexte;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            IconTheme(
              data: palette.inkMuted.asIconTheme(size: 18),
              child: Icon(AppIcons.info.resoudre()),
            ),
            Ecart.hSm,
            Expanded(
              child: Text(
                t.controleur.compteRendu.notice,
                style: palette.inkMuted.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
          ],
        ),
        Semantics(
          liveRegion: true,
          child: echec
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Text(
                    sansTexte
                        ? t.controleur.observation.echecSansTexte
                        : t.controleur.observation.echec,
                    style: palette.inkStrong.applyTo(
                      textes.bodyMedium ?? const TextStyle(),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
