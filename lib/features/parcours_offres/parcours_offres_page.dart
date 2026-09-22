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
import '../../core/widgets/app_card.dart';
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
/// ni champ libre pour un cours sur mesure, ni position precise. La date de
/// naissance est demandee au tuteur uniquement, puis l'age et la cohorte sont
/// calcules par le serveur. Les horaires proposes sont ceux que l'academie
/// publie, et seulement eux.
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

class _ParcoursOffresPageState extends ConsumerState<ParcoursOffresPage> {
  /// Six questions, puis les horaires. Le total annonce inclut la derniere
  /// page : une barre qui s'arrete a six alors qu'il reste un ecran ment sur ce
  /// qu'il reste a faire.
  static const int _pages = 7;

  /// La page courante. Nulle tant que l'on ne sait pas d'ou partir.
  ///
  /// **Un foyer qui a deja repondu n'est pas renvoye a la premiere question.**
  /// On revient ici pour changer d'horaire bien apres son inscription, et
  /// reposer six questions deja repondues serait exactement ce que la mission
  /// interdit : redemander une information connue. Les questions restent
  /// accessibles par « Retour », pour qui veut corriger.
  int? _page;
  bool _envoi = false;
  String? _erreur;
  bool _demandeEnregistree = false;

  DateTime? _dateNaissanceTouchee;
  String? _langueTouchee;
  String? _fuseauTouche;
  NiveauDeclare? _niveauTouche;
  ObjectifApprentissage? _objectifTouche;
  final Set<MomentJournee> _moments = <MomentJournee>{};

  // Chaque reponse se lit « ce que la personne vient de toucher, sinon ce que
  // la fiche sait deja ». C'est ce qui permet de revenir corriger une seule
  // question sans devoir toutes les retaper.
  DateTime? get _dateNaissance =>
      _dateNaissanceTouchee ?? _apprenant?.dateNaissance;
  String? get _cohorte => _apprenant?.cohorteCode;
  String? get _langue => _langueTouchee ?? _apprenant?.langueCode;
  String? get _fuseau => _fuseauTouche ?? _apprenant?.fuseauFoyer;
  NiveauDeclare? get _niveau => _niveauTouche ?? _apprenant?.niveauDeclare;
  ObjectifApprentissage? get _objectif =>
      _objectifTouche ?? _apprenant?.objectif;

  /// Le fuseau retenu, ou celui du foyer tant que la question n'est pas passee.
  String get _fuseauVu => _fuseau ?? 'Europe/Paris';

  ParcoursApprenant? get _apprenant => ref
      .watch(parcoursFoyerProvider)
      .value
      ?.where((ParcoursApprenant p) => p.eleveId == widget.eleveId)
      .firstOrNull;

  void _avancer() => setState(() {
    _page = (_page ?? 0) + 1;
    _erreur = null;
  });

  void _reculer() => setState(() {
    _page = (_page ?? 0) - 1;
    _erreur = null;
  });

  /// Enregistre les six reponses, puis passe aux horaires.
  ///
  /// L'ecriture a lieu ICI et non page par page : une fiche a moitie ecrite
  /// serait consideree « personnalisee » par `profilRempli` et ferait sauter
  /// l'accueil a l'etape suivante alors que la famille n'a rien fini.
  Future<void> _enregistrerProfil() async {
    final DateTime? dateNaissance = _dateNaissance;
    final String? langue = _langue;
    final NiveauDeclare? niveau = _niveau;
    final ObjectifApprentissage? objectif = _objectif;
    if (dateNaissance == null ||
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
      if (_dateNaissanceTouchee != null || _apprenant?.dateNaissance == null) {
        await ref
            .read(serviceOffresProvider)
            .definirDateNaissance(
              membreId: widget.eleveId,
              date: dateNaissance,
            );
      }
      await ref
          .read(serviceOffresProvider)
          .enregistrerProfil(
            membreId: widget.eleveId,
            langueCode: langue,
            niveau: niveau,
            objectif: objectif,
            fuseau: _fuseauVu,
          );
      ref.invalidate(parcoursFoyerProvider);
      if (mounted) {
        _avancer();
      }
    } on Object {
      if (mounted) {
        setState(() => _erreur = t.parcours.erreur);
      }
    } finally {
      if (mounted) {
        setState(() => _envoi = false);
      }
    }
  }

  Future<void> _choisir(String offreId) async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(serviceOffresProvider)
          .choisirOffre(
            CleOffres(membreId: widget.eleveId, fuseau: _fuseauVu),
            offreId,
          );
      ref
        ..invalidate(parcoursFoyerProvider)
        ..invalidate(offresCompatiblesProvider);
      if (mounted) {
        // Retour a l'accueil : c'est lui qui dit l'etat reel, et il le dira
        // mieux que cette page, qui vient de faire son travail.
        GoRouter.of(context).go(Routes.tuteurAccueil);
      }
    } on Object {
      if (mounted) {
        setState(() => _erreur = t.parcours.erreur);
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
    } on Object {
      if (mounted) {
        setState(() => _erreur = t.parcours.erreur);
      }
    } finally {
      if (mounted) {
        setState(() => _envoi = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<ParcoursApprenant>> foyer = ref.watch(
      parcoursFoyerProvider,
    );

    // Rien ne s'affiche avant de savoir de qui l'on parle : une question qui
    // dirait « Quel age a  ? » vaut moins qu'un squelette.
    if (!foyer.hasValue) {
      return PageShell(
        titre: t.parcours.chargement,
        child: foyer.hasError
            ? _Refus(message: t.parcours.erreur)
            : const Skeleton.liste(lignes: 4),
      );
    }

    // Le profil deja rempli ouvre directement sur les horaires : les cinq
    // getters ci-dessus reprennent les reponses connues, donc « Retour »
    // retrouve des pages deja remplies plutot que vides.
    final int page =
        _page ?? ((_apprenant?.profilRempli ?? false) ? _pages - 1 : 0);

    return switch (page) {
      0 => _pageAge(),
      1 => _pageLangue(),
      2 => _pageLieu(),
      3 => _pageNiveau(),
      4 => _pageObjectif(),
      5 => _pageMoments(),
      _ => _pageOffres(),
    };
  }

  String get _prenom => _apprenant?.prenom ?? '';

  // --- 1. L'age, date fournie par le tuteur -------------------------------

  Widget _pageAge() {
    return PageParcours(
      numero: 1,
      total: _pages,
      minutesRestantes: 3,
      question: t.parcours.ageQuestion(prenom: _prenom),
      explication: t.parcours.ageRaison,
      libelleAction: t.commun.continuer,
      onAction: _dateNaissance == null ? null : _avancer,
      enfant: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              _dateNaissance == null
                  ? t.parcours.dateNaissanceChoisir
                  : t.parcours.dateNaissanceApercu(
                      date: MaterialLocalizations.of(context)
                          .formatMediumDate(_dateNaissance!),
                    ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Ecart.vMd,
            ActionPrincipale(
              libelle: t.parcours.dateNaissanceChoisir,
              niveau: NiveauAction.secondaire,
              onPress: () => unawaited(_choisirDateNaissance()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _choisirDateNaissance() async {
    final DateTime aujourdHui = DateTime.now();
    final DateTime? choisie = await showDatePicker(
      context: context,
      initialDate:
          _dateNaissance ??
          DateTime(aujourdHui.year - 10, aujourdHui.month, aujourdHui.day),
      firstDate: DateTime(
        aujourdHui.year - 18,
        aujourdHui.month,
        aujourdHui.day,
      ),
      lastDate: aujourdHui,
    );
    if (choisie != null && mounted) {
      setState(() => _dateNaissanceTouchee = DateUtils.dateOnly(choisie));
    }
  }

  // --- 2. La langue du COURS, pas celle de l'interface ---------------------

  Widget _pageLangue() {
    final AsyncValue<List<LangueCours>> langues = ref.watch(
      languesCoursProvider,
    );

    return PageParcours(
      numero: 2,
      total: _pages,
      minutesRestantes: 3,
      question: t.parcours.langueQuestion,
      explication: t.parcours.langueRaison,
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
                () =>
                    _langueTouchee = r.valeurs.isEmpty ? null : r.valeurs.first,
              ),
            )
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
      numero: 3,
      total: _pages,
      minutesRestantes: 2,
      question: t.parcours.lieuQuestion,
      explication: t.parcours.lieuRaison,
      libelleAction: t.commun.continuer,
      onAction: retenu == null
          ? null
          : () {
              setState(() => _fuseauTouche = retenu);
              _avancer();
            },
      onRetour: _reculer,
      souscription: suggere != null && _fuseauTouche == null
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
          () => _fuseauTouche = r.valeurs.isEmpty ? null : r.valeurs.first,
        ),
      ),
    );
  }

  // --- 4. Le niveau AUTO-DECLARE, jamais le niveau officiel ----------------

  Widget _pageNiveau() {
    return PageParcours(
      numero: 4,
      total: _pages,
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
          () => _niveauTouche = NiveauDeclare.depuisSql(
            r.valeurs.isEmpty ? null : r.valeurs.first,
          ),
        ),
      ),
    );
  }

  // --- 5. L'objectif -------------------------------------------------------

  Widget _pageObjectif() {
    return PageParcours(
      numero: 5,
      total: _pages,
      minutesRestantes: 1,
      question: t.parcours.objectifQuestion,
      explication: t.parcours.objectifRaison,
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
          () => _objectifTouche = ObjectifApprentissage.depuisSql(
            r.valeurs.isEmpty ? null : r.valeurs.first,
          ),
        ),
      ),
    );
  }

  // --- 6. Les moments, qui CLASSENT et ne filtrent pas ---------------------

  Widget _pageMoments() {
    return PageParcours(
      numero: 6,
      total: _pages,
      minutesRestantes: 1,
      question: t.parcours.momentsQuestion,
      explication: t.parcours.momentsRaison,
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
        valeurInitiale: ReponseChoix(
          valeurs: _moments.map((MomentJournee m) => m.name).toSet(),
        ),
        options: <OptionChoix>[
          for (final MomentJournee m in MomentJournee.values)
            OptionChoix(valeur: m.name, libelle: m.libelle),
        ],
        onChange: (ReponseChoix r) => setState(() {
          _moments
            ..clear()
            ..addAll(
              MomentJournee.values.where(
                (MomentJournee m) => r.valeurs.contains(m.name),
              ),
            );
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

    if (!offres.hasValue) {
      return PageParcours(
        numero: 7,
        total: _pages,
        question: t.parcours.offresQuestion(prenom: _prenom),
        libelleAction: t.commun.continuer,
        onAction: null,
        onRetour: _reculer,
        souscription: offres.hasError
            ? _Refus(message: t.parcours.erreur)
            : null,
        enfant: const Skeleton.liste(lignes: 3),
      );
    }

    final List<OffreHoraire> classees = classerOffres(
      offres.requireValue,
      _moments,
    );

    if (classees.isEmpty) {
      return _pageAucuneOffre();
    }

    final OffreHoraire recommandee = classees.first;
    final List<OffreHoraire> autres = classees.skip(1).toList(growable: false);

    return PageParcours(
      numero: 7,
      total: _pages,
      question: t.parcours.offresQuestion(prenom: _prenom),
      explication: t.parcours.offresRaison,
      libelleAction: t.commun.retour,
      onAction: () => GoRouter.of(context).go(Routes.tuteurAccueil),
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
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
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

  Widget _pageAucuneOffre() {
    return PageParcours(
      numero: 7,
      total: _pages,
      question: t.parcours.aucuneOffre,
      explication: t.parcours.aucuneOffreDetail,
      libelleAction: t.commun.retour,
      onAction: () => GoRouter.of(context).go(Routes.tuteurAccueil),
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
