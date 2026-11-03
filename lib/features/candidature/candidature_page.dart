/// `CAND-01` : le questionnaire de la Salle d'examen, en parcours d'accueil
/// (`/attente/candidature`).
///
/// Un parcours, pas un formulaire : trois ecrans de presentation, une
/// question par ecran (cartes a toucher), la barre de progression en haut,
/// « Retour » et « Continuer » en bas, puis le recapitulatif, les conditions de
/// remuneration en pourcentage et « Envoyer ma candidature ». Les questions
/// sont celles que rend le serveur (`questionnaire_salle_examen()`) ; rien
/// n'est invente ici.
///
/// Etats : chargement (`Skeleton`), contenu, erreur (« Reessayer »), hors
/// ligne (le bandeau de la page le dit une fois ; les reponses restent a
/// l'ecran), capacite indisponible (« Cette etape n'est pas encore ouverte »),
/// aucune candidature pour ce compte (retour au portail), lecture seule apres
/// l'envoi.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/candidature/modeles_candidature.dart';
import '../../core/candidature/port_ma_candidature.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/dossier/etat_dossier.dart';
import '../../core/dossier/service_dossier.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import 'controleur_parcours.dart';
import 'coquille_parcours.dart';
import 'disponibilites_etape.dart';
import 'lecture_page.dart';
import 'libelles_parcours.dart';
import 'modele_questions.dart';
import 'presentation_etape.dart';
import 'question_etape.dart';
import 'recapitulatif_etape.dart';

/// Le questionnaire de la Salle d'examen.
class CandidaturePage extends ConsumerStatefulWidget {
  /// Cree la page.
  const CandidaturePage({super.key});

  @override
  ConsumerState<CandidaturePage> createState() => _CandidaturePageState();
}

class _CandidaturePageState extends ConsumerState<CandidaturePage> {
  bool _versLePortail = false;

  /// Revient au portail, une seule fois, apres le rendu en cours.
  void _retourAuPortail() {
    if (_versLePortail) {
      return;
    }
    _versLePortail = true;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) {
        context.go(Routes.attente);
      }
    });
  }

  @override
  Widget build(BuildContext context) => lecturePage<EtatDossier>(
    ref: ref,
    key: const ValueKey<String>('candidature-etat'),
    valeur: ref.watch(etatDossierProvider),
    titreEchec: t.recrutement.portail.nonCharge,
    onReessayer: () => ref.invalidate(etatDossierProvider),
    construire: (EtatDossier lu) {
      final CandidatureDossier c = lu.candidature;
      // Une adresse tapee sans candidature, ou une candidature qui n'attend
      // plus de reponses : le portail dit ou on en est.
      if (!lu.profilExiste ||
          !c.existe ||
          c.issue != IssueCandidature.enCours) {
        _retourAuPortail();
        return const PageSimple(corps: Skeleton.liste(lignes: 3));
      }
      if (c.questionnaireOuvert) {
        return _Edition(candidature: c);
      }
      if (c.questionnaire.envoyeLe != null) {
        return _LectureSeule(candidature: c);
      }
      _retourAuPortail();
      return const PageSimple(corps: Skeleton.liste(lignes: 3));
    },
  );
}

/// Le parcours, tant que le questionnaire est ouvert en ecriture.
class _Edition extends ConsumerWidget {
  const _Edition({required this.candidature});

  final CandidatureDossier candidature;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ConditionsRemuneration> conditions = ref.watch(
      conditionsRemunerationCandidatProvider,
    );
    // Sans les conditions de remuneration, l'envoi ne peut pas aboutir : la
    // page le dit une fois, au lieu d'un parcours qui ne mene nulle part.
    if (conditions.hasError &&
        !conditions.hasValue &&
        conditions.error is CapaciteIndisponible) {
      return const PageSimple(corps: EtapeNonOuverte());
    }
    return lecturePage<Questionnaire>(
      ref: ref,
      valeur: ref.watch(questionnaireCandidatProvider),
      titreEchec: t.recrutement.questionnaire.nonCharge,
      onReessayer: () => ref.invalidate(questionnaireCandidatProvider),
      construire: (Questionnaire q) {
        if (!questionnaireReconnu(q)) {
          return const PageSimple(corps: EtapeNonOuverte());
        }
        return _Parcours(
          // Une nouvelle version du questionnaire repart de ses reponses.
          key: ValueKey<String>('parcours-${q.version}'),
          questionnaire: q,
          candidature: candidature,
        );
      },
    );
  }
}

class _Parcours extends ConsumerStatefulWidget {
  const _Parcours({
    required this.questionnaire,
    required this.candidature,
    super.key,
  });

  final Questionnaire questionnaire;
  final CandidatureDossier candidature;

  @override
  ConsumerState<_Parcours> createState() => _ParcoursState();
}

class _ParcoursState extends ConsumerState<_Parcours> {
  late final ParcoursControleur _c;
  ManqueReponse? _manque;

  /// Ce que le serveur a refuse a l'envoi, dit sur la question qu'il rouvre :
  /// il s'efface au premier geste de la personne.
  String? _renvoi;

  @override
  void initState() {
    super.initState();
    final Questionnaire q = widget.questionnaire;
    final DernieresReponses? derniere = q.dernieresReponses;
    final Set<String> cartes = <String>{
      for (final ChampQuestionnaire champ in q.champs) champ.carte,
    };
    _c = ParcoursControleur(
      questionnaire: q,
      port: ref.read(portMaCandidatureProvider),
      reponses: derniere == null
          ? const <String, Object?>{}
          : reponsesValables(q, derniere.reponses),
      cartesADemander: <String>{
        for (final String code in widget.candidature.complementDemande)
          if (cartes.contains(code)) code,
      },
    )..addListener(_surChangement);
  }

  void _surChangement() {
    // Une reponse change : l'indication « choisissez... » s'efface.
    if (_manque != null && _c.manque(_c.courante) == null) {
      _manque = null;
    }
  }

  @override
  void dispose() {
    _c
      ..removeListener(_surChangement)
      ..dispose();
    super.dispose();
  }

  void _sortir() => GoRouter.of(context).go(Routes.attente);

  void _continuer() {
    final ManqueReponse? manque = _c.manque(_c.courante);
    if (manque != null) {
      setState(() => _manque = manque);
      return;
    }
    setState(() {
      _manque = null;
      _renvoi = null;
    });
    _c.avancer();
  }

  void _reculer() {
    setState(() {
      _manque = null;
      _renvoi = null;
    });
    if (_c.estPremiere) {
      _sortir();
    } else {
      _c.reculer();
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _c,
    builder: (BuildContext context, Widget? _) {
      final EtapeParcours etape = _c.courante;
      final int numero = _c.index + 1;
      final int total = _c.etapes.length;
      switch (etape) {
        case EtapePresentation(:final int rang):
          return CoquilleParcours(
            numero: numero,
            total: total,
            titre: titrePresentation(rang),
            explication: intro(rang),
            enfant: TuilesPresentation(rang: rang),
            libelleAction: t.commun.continuer,
            onAction: _continuer,
            onRetour: _reculer,
            choix: true,
          );
        case EtapeChamp():
          final String code = etape.champ.code;
          return CoquilleParcours(
            numero: numero,
            total: total,
            titre: titreQuestion(code) ?? '',
            explication: explicationQuestion(code),
            entete: _entete(etape),
            enfant: QuestionEtape(etape: etape, controleur: _c),
            libelleAction: t.commun.continuer,
            onAction: _continuer,
            onRetour: _reculer,
            choix: true,
            souscription: _souscription(etape),
          );
        case EtapeDisponibilites():
          final ({String titre, String? explication}) textes =
              textesDisponibilites(etape, _c);
          return CoquilleParcours(
            numero: numero,
            total: total,
            titre: textes.titre,
            explication: textes.explication,
            entete: _entete(etape),
            enfant: DisponibilitesEtape(etape: etape, controleur: _c),
            libelleAction: t.commun.continuer,
            onAction: _continuer,
            onRetour: _reculer,
            choix: true,
            souscription: _souscription(etape),
          );
        case EtapeRecapitulatif():
          return RecapitulatifEtape(
            controleur: _c,
            candidature: widget.candidature,
            versionCandidature: widget.questionnaire.candidatureVersion,
            numero: numero,
            total: total,
            onRenvoi: (String phrase) => setState(() => _renvoi = phrase),
          );
      }
    },
  );

  /// La ligne sous le bouton : ce qui manque pour continuer, sinon ce que le
  /// serveur a refuse, sinon l'echec du brouillon.
  Widget? _souscription(EtapeParcours etape) {
    if (_manque != null) {
      return IndicationParcours(message: _messageManque(etape));
    }
    final String? renvoi = _renvoi;
    if (renvoi != null) {
      return IndicationParcours(message: renvoi);
    }
    if (_c.brouillonNonGarde) {
      return IndicationParcours(
        message: t.recrutement.parcours.sauvegardeEchec,
      );
    }
    return null;
  }

  /// Le bloc au-dessus d'une question : ce que la direction demande de
  /// completer, ou le questionnaire qui a change.
  Widget? _entete(EtapeParcours etape) {
    final DernieresReponses? derniere = widget.questionnaire.dernieresReponses;
    final String? message = _c.aCompleter(etape)
        ? t.recrutement.questionnaire.complementCarte
        : (derniere != null && derniere.perime
              ? t.recrutement.questionnaire.perime
              : null);
    if (message == null) {
      return null;
    }
    return AppCard(
      key: const ValueKey<String>('parcours-entete'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ExcludeSemantics(
            child: IconTheme(
              data: AppPalette.of(context).inkAccent
                  .asIconTheme(size: AppSpacing.xxl),
              child: Icon(AppIcons.info.repos),
            ),
          ),
          Ecart.hMd,
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  String _messageManque(EtapeParcours etape) {
    final r = t.recrutement.parcours;
    return switch (_manque!) {
      ManqueReponse.aucunJour => r.choisirJour,
      ManqueReponse.aucuneHeure => r.choisirHeure,
      ManqueReponse.jourSansHeure => r.choisirHeureJour(
        jour: _c.jourSansHeure == null
            ? ''
            : t.disponibilites.joursLongs[_c.jourSansHeure! - 1],
      ),
      ManqueReponse.trop => r.trop(
        max: etape is EtapeChamp ? etape.champ.max ?? 1 : 1,
      ),
      ManqueReponse.aucune =>
        etape is EtapeChamp &&
                (etape.forme == FormeQuestion.choixMultiple ||
                    etape.forme == FormeQuestion.langues ||
                    etape.forme == FormeQuestion.riwayat)
            ? r.choisirPlusieurs
            : r.choisir,
    };
  }
}

/// La candidature envoyee, en lecture seule : ses reponses, l'etat du
/// versement, un retour au dossier. Aucun champ, aucun bouton plein.
class _LectureSeule extends ConsumerWidget {
  const _LectureSeule({required this.candidature});

  final CandidatureDossier candidature;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = t.recrutement.questionnaire;
    return lecturePage<Questionnaire>(
      ref: ref,
      valeur: ref.watch(questionnaireCandidatProvider),
      titreEchec: r.nonCharge,
      onReessayer: () => ref.invalidate(questionnaireCandidatProvider),
      construire: (Questionnaire q) {
        final Map<String, Object?> reponses = q.dernieresReponses == null
            ? const <String, Object?>{}
            : reponsesValables(q, q.dernieresReponses!.reponses);
        final DateTime? envoyeLe = candidature.questionnaire.envoyeLe;
        final TextTheme textes = Theme.of(context).textTheme;
        final AppPalette palette = AppPalette.of(context);
        return PageShell(
          titre: r.titre,
          onRetour: () => GoRouter.of(context).go(Routes.attente),
          actions: ActionPrincipale(
            key: const ValueKey<String>('lecture-retour'),
            libelle: r.retourDossier,
            niveau: NiveauAction.tertiaire,
            onPress: () => GoRouter.of(context).go(Routes.attente),
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
                    key: const ValueKey<String>('lecture-envoyee'),
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
                              child: Text(r.envoyee, style: textes.titleMedium),
                            ),
                          ],
                        ),
                        if (envoyeLe != null) ...<Widget>[
                          Ecart.vSm,
                          Text(
                            r.envoyeeLe(date: _jour(envoyeLe)),
                            style: textes.bodyMedium,
                          ),
                        ],
                        Ecart.vSm,
                        Text(
                          r.etatVersement(
                            etat: _versement(candidature.paiement),
                          ),
                          key: const ValueKey<String>('lecture-versement'),
                          style: textes.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Ecart.vSection,
                  CartesRecapitulatif(questionnaire: q, reponses: reponses),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _versement(EtatVersement etat) => switch (etat) {
    EtatVersement.inconnu => t.recrutement.paiement.inconnu,
    EtatVersement.aVerifier => t.recrutement.paiement.aVerifier,
    EtatVersement.compatible => t.recrutement.paiement.compatible,
    EtatVersement.incompatible => t.recrutement.paiement.incompatible,
  };

  static String _jour(DateTime d) => isolerSens(
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}',
  );
}
