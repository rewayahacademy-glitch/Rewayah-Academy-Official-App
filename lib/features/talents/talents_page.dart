/// `CAND-07` : « Vos autres talents » (`/attente/talents`), le parcours
/// facultatif de la salle d'attente, **apres l'envoi** de la candidature.
///
/// La direction a demande (22/10/2026) de profiter du grand nombre de candidats
/// pour d'autres recrutements, sans les ennuyer et en leur disant pourquoi.
/// Quatre ecrans a cartes, presque sans clavier : l'introduction (ce que
/// l'academie en fait), les competences precises par famille (lues dans le
/// catalogue du serveur), le niveau de chacune, la disponibilite et l'accord
/// d'etre contacte. Un seul champ au clavier : « Autre domaine ».
///
/// **Ce n'est pas un etat de la candidature.** Rien ici ne change l'etape, ne
/// bloque un passage ni ne touche au paiement : le serveur ne lit ces reponses
/// ni pour decider ni pour calculer. La page le dit avant de demander.
///
/// **Tout vient du serveur.** `lire_autres_competences()` dit si c'est ouvert
/// (et pourquoi sinon), la version, les reponses et le catalogue ; l'ecran ne
/// deduit aucun droit. Une personne qui a deja repondu voit ses reponses, avec
/// « Modifier » et « Retirer » ; quand sa candidature d'enseignant est terminee,
/// elle peut encore les lire et les retirer, plus les modifier.
///
/// Etats : chargement (`Skeleton`), contenu, erreur (« Reessayer »), hors ligne
/// (le bandeau de la page le dit une fois ; rien ne s'enregistre sans reseau),
/// capacite indisponible (« Cette etape n'est pas encore ouverte »), pas encore
/// ouvert (candidature non envoyee), termine (candidature close, aucune reponse),
/// aucune candidature pour ce compte (retour au portail), reponses retirees.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/candidature/modeles_autres_competences.dart';
import '../../core/candidature/port_autres_competences.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/dossier/etat_dossier.dart';
import '../../core/dossier/service_dossier.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/skeleton.dart';
import '../candidature/lecture_page.dart';
import 'controleur_talents.dart' show BrouillonTalents;
import 'lecture_talents.dart';
import 'parcours_talents.dart';

/// La page « Vos autres talents ».
class TalentsPage extends ConsumerStatefulWidget {
  /// Cree la page.
  const TalentsPage({super.key});

  /// La cle de la lecture du dossier.
  static const Key etatKey = ValueKey<String>('talents-etat');

  /// La cle de la lecture des reponses.
  static const Key lectureKey = ValueKey<String>('talents-lecture');

  /// La cle de l'etat « pas encore ouvert ».
  static const Key nonEnvoyeKey = ValueKey<String>('talents-non-envoye');

  /// La cle de l'etat « termine ».
  static const Key closKey = ValueKey<String>('talents-clos');

  /// La cle de l'etat « reponses retirees ».
  static const Key retireKey = ValueKey<String>('talents-retire');

  @override
  ConsumerState<TalentsPage> createState() => _TalentsPageEtat();
}

class _TalentsPageEtat extends ConsumerState<TalentsPage> {
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
    key: TalentsPage.etatKey,
    titre: t.recrutement.talents.titre,
    valeur: ref.watch(etatDossierProvider),
    titreEchec: t.recrutement.portail.nonCharge,
    onReessayer: () => ref.invalidate(etatDossierProvider),
    construire: (EtatDossier lu) {
      // Une adresse tapee sans candidature : le portail dit ou on en est.
      if (!lu.profilExiste || !lu.candidature.existe) {
        _retourAuPortail();
        return PageSimple(
          titre: t.recrutement.talents.titre,
          corps: const Skeleton.liste(lignes: 3),
        );
      }
      return _Corps(retourAuPortail: _retourAuPortail);
    },
  );
}

/// Le contenu : les reponses, le parcours, ou l'etat de la page.
class _Corps extends ConsumerStatefulWidget {
  const _Corps({required this.retourAuPortail});

  /// Renvoie au portail (le compte n'est pas le titulaire d'une candidature
  /// d'enseignant : le serveur refuse la lecture).
  final VoidCallback retourAuPortail;

  @override
  ConsumerState<_Corps> createState() => _CorpsEtat();
}

class _CorpsEtat extends ConsumerState<_Corps> {
  /// Vrai : la personne a ouvert « Modifier mes reponses ».
  bool _modification = false;

  /// Vrai : le serveur vient de confirmer le retrait.
  bool _retire = false;

  /// Vrai : l'introduction a deja ete lue pendant cette visite.
  bool _sansIntro = false;

  /// Un message a dire en tete (les reponses ont change ailleurs...).
  String? _message;

  /// Ce que la personne avait choisi quand une competence a ete retiree du
  /// catalogue : le parcours neuf le reprend, elle ne ressaisit rien.
  BrouillonTalents? _reprise;

  /// Compte les relectures qui refont le parcours : un parcours neuf repart de
  /// ce que le serveur vient de rendre.
  int _cycle = 0;

  /// Relit les reponses au serveur. Un echec de relecture n'annule rien : la
  /// page montre alors l'etat de la lecture.
  Future<void> _relire() async {
    ref.invalidate(autresCompetencesProvider);
    try {
      await ref.read(autresCompetencesProvider.future);
    } on Object {
      // La lecture en echec se dit par la page (« Reessayer »).
    }
  }

  Future<void> _issue(
    IssueEnregistrement issue,
    BrouillonTalents brouillon,
  ) async {
    final r = t.recrutement.talents.erreurs;
    switch (issue) {
      case IssueEnregistrement.enregistre:
        await _relire();
        if (mounted) {
          setState(() {
            _modification = false;
            _message = null;
            _reprise = null;
            _cycle++;
          });
        }
      case IssueEnregistrement.conflit:
        await _relire();
        if (mounted) {
          setState(() {
            _modification = false;
            _sansIntro = true;
            _message = r.conflit;
            _reprise = null;
            _cycle++;
          });
        }
      case IssueEnregistrement.desactivee:
        await _relire();
        if (mounted) {
          setState(() {
            _modification = true;
            _sansIntro = true;
            _message = r.desactivee;
            // Les autres choix restent : seule la competence retiree s'en va.
            _reprise = brouillon;
            _cycle++;
          });
        }
      case IssueEnregistrement.ferme:
        await _relire();
        if (mounted) {
          setState(() {
            _modification = false;
            _message = null;
            _reprise = null;
            _cycle++;
          });
        }
    }
  }

  Future<void> _surRetrait() async {
    await _relire();
    if (mounted) {
      setState(() {
        _retire = true;
        _modification = false;
        _message = null;
        _reprise = null;
        _cycle++;
      });
    }
  }

  Widget _contenu(AutresCompetences a) {
    if (_retire) {
      return PageSimple(
        titre: t.recrutement.talents.titre,
        corps: EmptyState(
          key: TalentsPage.retireKey,
          message: t.recrutement.talents.lecture.retire,
          libelleAction: t.recrutement.questionnaire.retourDossier,
          onAction: () => context.go(Routes.attente),
        ),
      );
    }
    if (_modification && a.ouvert) {
      return ParcoursTalents(
        key: ValueKey<String>('talents-parcours-${a.version}-$_cycle'),
        lecture: a,
        avecIntroduction: false,
        messageInitial: _message,
        reprise: _reprise,
        onIssue: _issue,
      );
    }
    if (a.aDesReponses) {
      return LectureTalents(
        key: ValueKey<String>('talents-reponses-${a.version}-$_cycle'),
        lecture: a,
        message: _message,
        onModifier: a.ouvert
            ? () => setState(() {
                _modification = true;
                _message = null;
              })
            : null,
        onRetire: _surRetrait,
      );
    }
    if (a.ouvert) {
      return ParcoursTalents(
        key: ValueKey<String>('talents-parcours-${a.version}-$_cycle'),
        lecture: a,
        avecIntroduction: !_sansIntro,
        messageInitial: _message,
        reprise: _reprise,
        onIssue: _issue,
      );
    }
    // Ni ouvert ni reponse a lire : la page dit pourquoi, et renvoie au dossier.
    final r = t.recrutement.talents.etats;
    final bool nonEnvoye = a.raison == RaisonFermeture.questionnaireNonEnvoye;
    return PageSimple(
      titre: t.recrutement.talents.titre,
      corps: EmptyState(
        key: nonEnvoye ? TalentsPage.nonEnvoyeKey : TalentsPage.closKey,
        message: nonEnvoye ? r.nonEnvoyeTitre : r.closTitre,
        invitation: nonEnvoye ? r.nonEnvoye : r.clos,
        libelleAction: t.recrutement.questionnaire.retourDossier,
        onAction: () => context.go(Routes.attente),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<AutresCompetences> valeur = ref.watch(
      autresCompetencesProvider,
    );
    // Le serveur ne reconnait pas la personne comme titulaire d'une candidature
    // d'enseignant : rien a faire ici, le portail dit ou elle en est.
    if (valeur.hasError &&
        !valeur.hasValue &&
        valeur.error is PermissionInsuffisante) {
      widget.retourAuPortail();
      return PageSimple(
        titre: t.recrutement.talents.titre,
        corps: const Skeleton.liste(lignes: 3),
      );
    }
    return lecturePage<AutresCompetences>(
      ref: ref,
      key: TalentsPage.lectureKey,
      titre: t.recrutement.talents.titre,
      valeur: valeur,
      titreEchec: t.recrutement.talents.etats.nonCharge,
      onReessayer: () => ref.invalidate(autresCompetencesProvider),
      construire: _contenu,
    );
  }
}
