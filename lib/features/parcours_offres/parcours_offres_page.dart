import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/offres/offre_horaire.dart';
import '../../core/offres/service_offres.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/page_parcours.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/schedule_option.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import 'libelles_parcours.dart';

/// Le parcours de personnalisation, puis le choix d'un horaire vitrine.
///
/// **Une question par page, jamais un formulaire.** Le gabarit est celui de
/// l'inscription (`PageParcours`, ADR-013) et les cartes sont celles du produit
/// (`ChoiceCardGroup`) : ce parcours n'invente aucun composant.
///
/// **Ce que ce parcours ne demande jamais** : ni « quel horaire voulez-vous »,
/// ni champ libre pour un cours sur mesure, ni date de naissance, ni position
/// precise. Les horaires proposes sont ceux que l'academie publie, et
/// seulement eux.
///
/// **Ce qu'il ne promet jamais** : aucune place reservee, aucun enseignant,
/// aucun groupe. Le dernier ecran enregistre une preference et le dit avec ce
/// mot-la.
///
/// L'etape A de la mission -- « qui apprend » -- est resolue avant d'arriver
/// ici : on entre par la carte d'un apprenant precis, dont [eleveId] porte
/// l'identifiant. La reposer serait redemander une information connue.
class ParcoursOffresPage extends ConsumerStatefulWidget {
  /// Cree le parcours pour un apprenant.
  const ParcoursOffresPage({required this.eleveId, super.key});

  /// L'apprenant concerne.
  final String eleveId;

  @override
  ConsumerState<ParcoursOffresPage> createState() => _ParcoursOffresPageState();
}

/// Les questions du parcours, dans l'ordre.
enum _Question { age, langue, lieu, niveau, objectif, moments, offres }

class _ParcoursOffresPageState extends ConsumerState<ParcoursOffresPage> {
  bool _envoi = false;
  String? _erreur;
  bool _demandeEnregistree = false;

  /// Vrai une fois un horaire choisi : la page dit alors ce qui a ete
  /// enregistre et propose la suite, au lieu de renvoyer sans un mot.
  bool _fini = false;

  /// Les reponses en cours, gardees hors de la page (retour sans perte).
  BrouillonParcours get _b => ref
      .read(brouillonsParcoursProvider)
      .putIfAbsent(widget.eleveId, BrouillonParcours.new);

  // Chaque reponse se lit « ce que la personne vient de toucher, sinon ce que
  // la fiche sait deja ». C'est ce qui permet de revenir corriger une seule
  // question sans devoir toutes les retaper.
  String? get _cohorte => _b.cohorte ?? _apprenant?.cohorteCode;
  String? get _langue => _b.langue ?? _apprenant?.langueCode;
  String? get _fuseau => _b.fuseau ?? _apprenant?.fuseauFoyer;
  NiveauDeclare? get _niveau => _b.niveau ?? _apprenant?.niveauDeclare;

  // Aucune branche codee cote client (mandat LA-4 : branches serveur
  // seulement). L'ancienne deduction « debut_lettres => apprendre_a_lire »
  // a ete retiree (REVUE LA-F) : 0043 ne rend aucune regle de branchement,
  // la question de l'objectif est donc posee a tous.
  ObjectifApprentissage? get _objectif => _b.objectif ?? _apprenant?.objectif;

  Set<MomentJournee> get _moments => MomentJournee.values
      .where((MomentJournee m) => _b.moments.contains(m.name))
      .toSet();

  /// Le fuseau retenu, ou une suggestion d'apres l'horloge de l'appareil tant
  /// que la question n'est pas passee (jamais une valeur fixe : LA-F, constat
  /// honnetete, `parcours.offresRaison` promet l'heure locale).
  String get _fuseauVu =>
      _fuseau ??
      fuseauSuggere(
            fuseauConnu: _apprenant?.fuseauFoyer,
            decalageAppareil: DateTime.now().timeZoneOffset,
          )?.iana ??
      'Europe/Paris';

  ParcoursApprenant? get _apprenant => ref
      .watch(parcoursFoyerProvider)
      .value
      ?.where((ParcoursApprenant p) => p.eleveId == widget.eleveId)
      .firstOrNull;

  /// Les questions de cet apprenant ; le total « n sur N » se calcule sur
  /// cette liste.
  List<_Question> get _questions => _Question.values;

  int get _total => _questions.length;

  int _numero(_Question q) => _questions.indexOf(q) + 1;

  void _avancer() => setState(() {
    _b.page = _pageCourante + 1;
    _erreur = null;
  });

  void _reculer() => setState(() {
    _b.page = _pageCourante - 1;
    _erreur = null;
  });

  /// Quitte le questionnaire sans rien perdre : le brouillon reste, et la
  /// prochaine visite reprend a la meme question.
  void _quitter() => GoRouter.of(context).go(Routes.tuteurAccueil);

  int get _pageCourante {
    final int? page = _b.page;
    if (page != null) {
      return page.clamp(0, _total - 1);
    }
    return (_apprenant?.profilRempli ?? false) ? _total - 1 : 0;
  }

  /// Enregistre les reponses, puis passe aux horaires.
  ///
  /// L'ecriture a lieu ICI et non page par page : une fiche a moitie ecrite
  /// serait consideree « personnalisee » par `profilRempli` et ferait sauter
  /// l'accueil a l'etape suivante alors que la famille n'a rien fini.
  Future<void> _enregistrerProfil() async {
    final String? cohorte = _cohorte;
    final String? langue = _langue;
    final NiveauDeclare? niveau = _niveau;
    final ObjectifApprentissage? objectif = _objectif;
    if (cohorte == null ||
        langue == null ||
        niveau == null ||
        objectif == null) {
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(serviceOffresProvider)
          .enregistrerProfil(
            membreId: widget.eleveId,
            langueCode: langue,
            cohorteCode: cohorte,
            niveau: niveau,
            objectif: objectif,
            fuseau: _fuseauVu,
          );
      ref.invalidate(parcoursFoyerProvider);
      if (mounted) {
        _avancer();
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() => _erreur = _messagePanne(e));
      }
    } finally {
      if (mounted) {
        setState(() => _envoi = false);
      }
    }
  }

  /// Une preference encore vivante sur un AUTRE horaire est retiree avant le
  /// nouveau choix (`renoncer_intention_horaire`, DB-ADM-08).
  bool _doitRenoncer(String offreId) {
    final ParcoursApprenant? p = _apprenant;
    if (p == null) {
      return false;
    }
    final EtatIntention? etat = p.intentionEtat;
    return etat != null &&
        etat != EtatIntention.retiree &&
        p.offreId != null &&
        p.offreId != offreId;
  }

  Future<void> _choisir(String offreId) async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      final ServiceOffres service = ref.read(serviceOffresProvider);
      if (_doitRenoncer(offreId)) {
        await service.renoncer(
          membreId: widget.eleveId,
          motif: 'changement_horaire',
        );
      }
      await service.choisirOffre(
        CleOffres(membreId: widget.eleveId, fuseau: _fuseauVu),
        offreId,
      );
      ref
        ..invalidate(parcoursFoyerProvider)
        ..invalidate(offresCompatiblesProvider)
        ..read(brouillonsParcoursProvider).remove(widget.eleveId);
      if (mounted) {
        setState(() => _fini = true);
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() => _erreur = _messagePanne(e));
      }
    } finally {
      if (mounted) {
        setState(() => _envoi = false);
      }
    }
  }

  Future<void> _signalerRefus() async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(serviceOffresProvider)
          .signalerHoraireInsatisfait(
            membreId: widget.eleveId,
            fuseau: _fuseauVu,
            langueCode: _langue,
            cohorteCode: _cohorte,
          );
      if (mounted) {
        setState(() => _demandeEnregistree = true);
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() => _erreur = _messagePanne(e));
      }
    } finally {
      if (mounted) {
        setState(() => _envoi = false);
      }
    }
  }

  String _messagePanne(Object e) => switch (classerPanneParcours(e)) {
    PanneParcours.indisponible => t.parcours.indisponibleTitre,
    PanneParcours.horsLigne => t.parcours.horsLigneDetail,
    PanneParcours.erreur => t.parcours.erreur,
  };

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<ParcoursApprenant>> foyer = ref.watch(
      parcoursFoyerProvider,
    );

    // Rien ne s'affiche avant de savoir de qui l'on parle : une question qui
    // dirait « Quel age a  ? » vaut moins qu'un squelette.
    if (!foyer.hasValue) {
      if (foyer.hasError) {
        return _pagePanne(classerPanneParcours(foyer.error!));
      }
      return PageShell(
        titre: t.parcours.chargement,
        onRetour: _quitter,
        child: const Skeleton.liste(lignes: 4),
      );
    }

    if (_apprenant == null) {
      return _EtatParcours(
        titre: t.parcours.introuvableTitre,
        detail: t.parcours.introuvableDetail,
        onRetour: _quitter,
        actions: <Widget>[
          ActionPrincipale(
            libelle: t.parcours.retourFoyer,
            onPress: () => GoRouter.of(context).go(Routes.tuteurFoyer),
          ),
        ],
      );
    }

    if (_fini) {
      return _pageFin();
    }

    return switch (_questions[_pageCourante]) {
      _Question.age => _pageAge(),
      _Question.langue => _pageLangue(),
      _Question.lieu => _pageLieu(),
      _Question.niveau => _pageNiveau(),
      _Question.objectif => _pageObjectif(),
      _Question.moments => _pageMoments(),
      _Question.offres => _pageOffres(),
    };
  }

  String get _prenom => _apprenant?.prenom ?? '';

  /// Le prenom de l'eleve en contexte, sur les questions qui ne le nomment
  /// pas : on sait toujours pour qui l'on repond.
  String _pour(String raison) =>
      '${t.parcours.pourPrenom(prenom: _prenom)}\n$raison';

  // --- Etats sans questionnaire ---------------------------------------------

  Widget _pagePanne(PanneParcours panne) {
    void reessayer() => ref.invalidate(parcoursFoyerProvider);
    return switch (panne) {
      // Le backend du parcours n'existe pas encore sur ce serveur : rien a
      // reessayer, et rien de faux a montrer.
      PanneParcours.indisponible => _EtatParcours(
        titre: t.parcours.indisponibleTitre,
        detail: t.parcours.indisponibleDetail,
        onRetour: _quitter,
        actions: <Widget>[
          ActionPrincipale(
            libelle: t.parcours.retourAccueil,
            onPress: _quitter,
          ),
        ],
      ),
      PanneParcours.horsLigne => _EtatParcours(
        titre: t.parcours.horsLigneTitre,
        detail: t.parcours.horsLigneDetail,
        onRetour: _quitter,
        actions: <Widget>[
          ActionPrincipale(libelle: t.parcours.reessayer, onPress: reessayer),
        ],
      ),
      PanneParcours.erreur => _EtatParcours(
        titre: t.parcours.erreurChargement,
        detail: t.parcours.erreurChargementDetail,
        onRetour: _quitter,
        actions: <Widget>[
          ActionPrincipale(libelle: t.parcours.reessayer, onPress: reessayer),
        ],
      ),
    };
  }

  /// Fin d'admission pour cet eleve : ce qui est enregistre, ce qui reste
  /// selon le statut rendu par le serveur, puis la suite.
  Widget _pageFin() {
    final StatutDiagnostic? diagnostic = _apprenant?.diagnostic;
    final String? reste = switch (diagnostic) {
      StatutDiagnostic.aPlanifier => t.parcours.etatDiagnosticRequisDetail(
        prenom: _prenom,
      ),
      StatutDiagnostic.planifie => t.parcours.etatDiagnosticEnAttenteDetail(
        prenom: _prenom,
      ),
      StatutDiagnostic.nonRequis || StatutDiagnostic.fait || null => null,
    };
    return _EtatParcours(
      titre: t.parcours.finTitre(prenom: _prenom),
      detail: reste == null
          ? t.parcours.finDetail
          : '${t.parcours.finDetail}\n\n$reste',
      onRetour: _quitter,
      actions: <Widget>[
        Text(
          t.parcours.finAjouterDetail,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Ecart.vMd,
        ActionPrincipale(
          libelle: t.parcours.finAjouterProfil,
          // Par la route seule : le formulaire appartient au Foyer.
          onPress: () => GoRouter.of(context).go(Routes.tuteurAjouterEnfant),
        ),
        Ecart.vMd,
        ActionPrincipale(
          libelle: t.parcours.retourAccueil,
          niveau: NiveauAction.secondaire,
          onPress: _quitter,
        ),
      ],
    );
  }

  // --- 1. L'age, jamais une date de naissance ------------------------------

  Widget _pageAge() {
    final AsyncValue<List<CohorteAge>> cohortes = ref.watch(
      cohortesAgeProvider,
    );

    return PageParcours(
      numero: _numero(_Question.age),
      total: _total,
      minutesRestantes: 3,
      question: t.parcours.ageQuestion(prenom: _prenom),
      explication: t.parcours.ageRaison,
      libelleAction: t.commun.continuer,
      onAction: _cohorte == null ? null : _avancer,
      // Premiere question : Retour quitte le questionnaire, le brouillon reste.
      onRetour: _quitter,
      enfant: cohortes.hasValue
          ? ChoiceCardGroup(
              // La liste des tranches est fermee et vient du serveur : aucune
              // reponse « Autre » n'aurait de sens, puisqu'il n'existe pas de
              // tranche que l'academie ne connaisse pas.
              autoriserSaisieLibre: false,
              valeurInitiale: _cohorte == null
                  ? null
                  : ReponseChoix(valeurs: <String>{_cohorte!}),
              options: <OptionChoix>[
                for (final CohorteAge c in cohortes.requireValue)
                  OptionChoix(valeur: c.code, libelle: c.nom),
              ],
              onChange: (ReponseChoix r) => setState(
                () => _b.cohorte = r.valeurs.isEmpty ? null : r.valeurs.first,
              ),
            )
          : cohortes.hasError
          ? _Refus(message: _messagePanne(cohortes.error!))
          : const Skeleton.liste(lignes: 4),
    );
  }

  // --- 2. La langue du COURS, pas celle de l'interface ---------------------

  Widget _pageLangue() {
    final AsyncValue<List<LangueCours>> langues = ref.watch(
      languesCoursProvider,
    );

    return PageParcours(
      numero: _numero(_Question.langue),
      total: _total,
      minutesRestantes: 3,
      question: t.parcours.langueQuestion,
      explication: _pour(t.parcours.langueRaison),
      libelleAction: t.commun.continuer,
      onAction: _langue == null ? null : _avancer,
      onRetour: _reculer,
      enfant: langues.hasValue
          ? ChoiceCardGroup(
              autoriserSaisieLibre: false,
              valeurInitiale: _langue == null
                  ? null
                  : ReponseChoix(valeurs: <String>{_langue!}),
              options: <OptionChoix>[
                for (final LangueCours l in langues.requireValue)
                  // Le nom d'une langue est rendu par le serveur et non
                  // traduit : le poular s'ecrit « Pulaar » dans toutes les
                  // langues de l'interface.
                  OptionChoix(valeur: l.code, libelle: l.nom),
              ],
              onChange: (ReponseChoix r) => setState(
                () => _b.langue = r.valeurs.isEmpty ? null : r.valeurs.first,
              ),
            )
          : langues.hasError
          ? _Refus(message: _messagePanne(langues.error!))
          : const Skeleton.liste(lignes: 3),
    );
  }

  // --- 3. Le lieu, pour l'heure affichee et pour rien d'autre --------------

  Widget _pageLieu() {
    final FuseauPropose? suggere = fuseauSuggere(
      fuseauConnu: _apprenant?.fuseauFoyer,
      decalageAppareil: DateTime.now().timeZoneOffset,
    );
    final String? retenu = _fuseau ?? suggere?.iana;

    return PageParcours(
      numero: _numero(_Question.lieu),
      total: _total,
      minutesRestantes: 2,
      question: t.parcours.lieuQuestion,
      explication: _pour(t.parcours.lieuRaison),
      libelleAction: t.commun.continuer,
      onAction: retenu == null
          ? null
          : () {
              setState(() => _b.fuseau = retenu);
              _avancer();
            },
      onRetour: _reculer,
      souscription: suggere != null && _b.fuseau == null
          ? Text(
              t.parcours.lieuSuggere,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      enfant: ChoiceCardGroup(
        // Pas de champ libre : personne n'a a taper « Africa/Conakry ».
        autoriserSaisieLibre: false,
        valeurInitiale: retenu == null
            ? null
            : ReponseChoix(valeurs: <String>{retenu}),
        options: <OptionChoix>[
          for (final FuseauPropose f in fuseauxProposes)
            OptionChoix(valeur: f.iana, libelle: f.libelle),
        ],
        onChange: (ReponseChoix r) => setState(
          () => _b.fuseau = r.valeurs.isEmpty ? null : r.valeurs.first,
        ),
      ),
    );
  }

  // --- 4. Le niveau AUTO-DECLARE, jamais le niveau officiel ----------------

  Widget _pageNiveau() {
    return PageParcours(
      numero: _numero(_Question.niveau),
      total: _total,
      minutesRestantes: 2,
      question: t.parcours.niveauQuestion(prenom: _prenom),
      explication: t.parcours.niveauRaison,
      libelleAction: t.commun.continuer,
      onAction: _niveau == null ? null : _avancer,
      onRetour: _reculer,
      enfant: ChoiceCardGroup(
        autoriserSaisieLibre: false,
        valeurInitiale: _niveau == null
            ? null
            : ReponseChoix(valeurs: <String>{_niveau!.valeurSql}),
        options: <OptionChoix>[
          for (final NiveauDeclare n in NiveauDeclare.values)
            OptionChoix(valeur: n.valeurSql, libelle: libelleNiveau(n)),
        ],
        onChange: (ReponseChoix r) => setState(
          () => _b.niveau = NiveauDeclare.depuisSql(
            r.valeurs.isEmpty ? null : r.valeurs.first,
          ),
        ),
      ),
    );
  }

  // --- 5. L'objectif (branche non debutant seulement) ----------------------

  Widget _pageObjectif() {
    return PageParcours(
      numero: _numero(_Question.objectif),
      total: _total,
      minutesRestantes: 1,
      question: t.parcours.objectifQuestion,
      explication: _pour(t.parcours.objectifRaison),
      libelleAction: t.commun.continuer,
      onAction: _objectif == null ? null : _avancer,
      onRetour: _reculer,
      enfant: ChoiceCardGroup(
        // « Je ne sais pas encore » est une reponse de la liste, pas un repli
        // en saisie libre : c'est une reponse legitime, et elle s'enregistre.
        autoriserSaisieLibre: false,
        valeurInitiale: _objectif == null
            ? null
            : ReponseChoix(valeurs: <String>{_objectif!.valeurSql}),
        options: <OptionChoix>[
          for (final ObjectifApprentissage o in ObjectifApprentissage.values)
            OptionChoix(valeur: o.valeurSql, libelle: libelleObjectif(o)),
        ],
        onChange: (ReponseChoix r) => setState(
          () => _b.objectif = ObjectifApprentissage.depuisSql(
            r.valeurs.isEmpty ? null : r.valeurs.first,
          ),
        ),
      ),
    );
  }

  // --- 6. Les moments, qui CLASSENT et ne filtrent pas ---------------------

  Widget _pageMoments() {
    return PageParcours(
      numero: _numero(_Question.moments),
      total: _total,
      minutesRestantes: 1,
      question: t.parcours.momentsQuestion,
      explication: _pour(t.parcours.momentsRaison),
      libelleAction: t.commun.continuer,
      // Repondre est facultatif : sans reponse, les horaires s'affichent dans
      // l'ordre publie par l'academie. Exiger une reponse a une question qui ne
      // sert qu'a classer serait un barrage sans contrepartie.
      onAction: () => unawaited(_enregistrerProfil()),
      onRetour: _reculer,
      enCours: _envoi,
      souscription: _erreur == null ? null : _Refus(message: _erreur!),
      enfant: ChoiceCardGroup(
        selectionMultiple: true,
        autoriserSaisieLibre: false,
        valeurInitiale: ReponseChoix(valeurs: Set<String>.of(_b.moments)),
        options: <OptionChoix>[
          for (final MomentJournee m in MomentJournee.values)
            OptionChoix(valeur: m.name, libelle: m.libelle),
        ],
        onChange: (ReponseChoix r) => setState(() {
          _b.moments
            ..clear()
            ..addAll(r.valeurs);
        }),
      ),
    );
  }

  // --- 7. Les offres vitrines ----------------------------------------------

  Widget _pageOffres() {
    final AsyncValue<List<OffreHoraire>> offres = ref.watch(
      offresCompatiblesProvider(
        CleOffres(membreId: widget.eleveId, fuseau: _fuseauVu),
      ),
    );
    final int numero = _numero(_Question.offres);

    if (!offres.hasValue) {
      return PageParcours(
        numero: numero,
        total: _total,
        question: t.parcours.offresQuestion(prenom: _prenom),
        libelleAction: t.parcours.reessayer,
        onAction: offres.hasError
            ? () => ref.invalidate(offresCompatiblesProvider)
            : null,
        onRetour: _reculer,
        souscription: offres.hasError
            ? _Refus(message: _messagePanne(offres.error!))
            : null,
        enfant: const Skeleton.liste(lignes: 3),
      );
    }

    final List<OffreHoraire> classees = classerOffres(
      offres.requireValue,
      _moments,
    );

    if (classees.isEmpty) {
      return _pageAucuneOffre(numero);
    }

    final OffreHoraire recommandee = classees.first;
    final List<OffreHoraire> autres = classees.skip(1).toList(growable: false);

    return PageParcours(
      numero: numero,
      total: _total,
      question: t.parcours.offresQuestion(prenom: _prenom),
      explication: t.parcours.offresRaison,
      libelleAction: t.parcours.retourAccueil,
      onAction: _quitter,
      onRetour: _reculer,
      enCours: _envoi,
      souscription: _erreur == null ? null : _Refus(message: _erreur!),
      enfant: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Une recommandation principale, puis les alternatives : c'est ce que
          // la mission demande, et cela evite la liste plate ou tout se vaut.
          SectionHeader(titre: t.parcours.offreRecommandee),
          Ecart.vMd,
          _CarteOffre(
            offre: recommandee,
            fuseauVu: _fuseauVu,
            onChoisir: _envoi
                ? null
                : () => unawaited(_choisir(recommandee.id)),
          ),
          if (autres.isNotEmpty) ...<Widget>[
            Ecart.vXl,
            SectionHeader(
              titre: t.parcours.offresAutres,
              compteur: autres.length,
            ),
            Ecart.vMd,
            for (final OffreHoraire o in autres)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: _CarteOffre(
                  offre: o,
                  fuseauVu: _fuseauVu,
                  onChoisir: _envoi ? null : () => unawaited(_choisir(o.id)),
                ),
              ),
          ],
          Ecart.vXl,
          _Repli(
            enregistree: _demandeEnregistree,
            enCours: _envoi,
            onSignaler: () => unawaited(_signalerRefus()),
          ),
        ],
      ),
    );
  }

  Widget _pageAucuneOffre(int numero) {
    return PageParcours(
      numero: numero,
      total: _total,
      question: t.parcours.aucuneOffre,
      explication: t.parcours.aucuneOffreDetail,
      libelleAction: t.parcours.retourAccueil,
      onAction: _quitter,
      onRetour: _reculer,
      enCours: _envoi,
      souscription: _erreur == null ? null : _Refus(message: _erreur!),
      enfant: _Repli(
        enregistree: _demandeEnregistree,
        enCours: _envoi,
        onSignaler: () => unawaited(_signalerRefus()),
      ),
    );
  }
}

/// Un etat hors questionnaire (indisponible, hors ligne, erreur, profil
/// introuvable, fin) : un titre, une phrase, les actions, et toujours un
/// retour visible.
class _EtatParcours extends StatelessWidget {
  const _EtatParcours({
    required this.titre,
    required this.detail,
    required this.onRetour,
    required this.actions,
  });

  final String titre;
  final String detail;
  final VoidCallback onRetour;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    return PageShell(
      titre: titre,
      onRetour: onRetour,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            liveRegion: true,
            child: Text(detail, style: textes.bodyLarge),
          ),
          Ecart.vXl,
          ...actions,
        ],
      ),
    );
  }
}

/// Une offre vitrine, rendue par le composant d'horaire du produit.
///
/// **Ce que cette carte n'affiche pas, et ne peut pas afficher** : nom ou photo
/// d'enseignant, badge, nombre d'inscrits, places restantes, identifiant de
/// groupe. Ce ne sont pas des champs omis a l'affichage : `OffreHoraire` ne les
/// porte pas, et `offres_horaires` n'a pas ces colonnes. A ce stade aucun vrai
/// groupe n'est garanti, et les montrer serait une promesse que l'academie n'a
/// pas faite.
class _CarteOffre extends ConsumerWidget {
  const _CarteOffre({
    required this.offre,
    required this.fuseauVu,
    required this.onChoisir,
  });

  final OffreHoraire offre;
  final String fuseauVu;
  final VoidCallback? onChoisir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ReglesAcademie> regles = ref.watch(reglesAcademieProvider);
    final int seances = regles.value?.seancesParSemaine ?? 0;

    final String recurrence = offre.pauseMinutes > 0
        ? t.parcours.offreRecurrencePause(
            seances: seances,
            duree: offre.dureeMinutes,
            pause: offre.pauseMinutes,
          )
        : t.parcours.offreRecurrence(
            seances: seances,
            duree: offre.dureeMinutes,
          );

    return ScheduleOption(
      day: libelleJours(offre.creneaux),
      hours: libelleHeures(offre.creneaux),
      // L'ecart d'heure est EXPLIQUE plutot que subi : une famille de Conakry
      // qui voit « 19:00 » sur une offre parisienne de 18:00 doit savoir
      // pourquoi, sinon elle croit a une erreur.
      timeZone: offre.heureTraduite
          ? t.parcours.offreTraduite
          : t.parcours.offreFuseau(fuseau: fuseauVu),
      recurrence:
          '${t.parcours.offreLangue(langue: offre.langueNom)}\n'
          '$recurrence',
      selected: offre.dejaChoisie,
      enabled: onChoisir != null && !offre.dejaChoisie,
      onSelected: onChoisir,
    );
  }
}

/// Le repli, quand aucun horaire ne convient.
///
/// **Exception assumee a ADR-013** (voir ADR-030) : la carte generique « Autre »
/// de `ChoiceCardGroup` ouvrirait un champ libre, donc inviterait a ecrire un
/// horaire souhaite. Ce parcours ne vend pas de cours sur mesure ; le repli dit
/// donc qu'aucun horaire ne convient, et propose d'etre prevenu.
///
/// Ce que le bouton fait : un signal de demande non satisfaite, lu par
/// l'academie en `ADM-06`. Ce qu'il ne fait pas : creer un groupe, chercher un
/// enseignant, promettre un horaire. La phrase sous le bouton le dit, avant le
/// clic et non apres.
class _Repli extends StatelessWidget {
  const _Repli({
    required this.enregistree,
    required this.enCours,
    required this.onSignaler,
  });

  final bool enregistree;
  final bool enCours;
  final VoidCallback onSignaler;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    if (enregistree) {
      return Semantics(
        liveRegion: true,
        child: Row(
          children: <Widget>[
            IconTheme(
              data: palette.inkAccent.asIconTheme(size: AppSpacing.xxl),
              child: Icon(AppIcons.succes.actif),
            ),
            Ecart.hMd,
            Expanded(
              child: Text(t.parcours.refusEnregistre, style: textes.bodyMedium),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(t.parcours.refusAucun, style: textes.titleMedium),
        Ecart.vSm,
        Text(t.parcours.refusEffet, style: textes.bodySmall),
        Ecart.vMd,
        ActionPrincipale(
          libelle: t.parcours.refusPrevenir,
          niveau: NiveauAction.secondaire,
          onPress: enCours ? null : onSignaler,
        ),
      ],
    );
  }
}

/// Un refus, ou une impasse, dit en une phrase sous le bouton.
class _Refus extends StatelessWidget {
  const _Refus({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Semantics(
      liveRegion: true,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: palette.inkAlert.applyTo(
          Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
        ),
      ),
    );
  }
}
