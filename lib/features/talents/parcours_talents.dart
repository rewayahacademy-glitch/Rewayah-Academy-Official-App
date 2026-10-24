// Le parcours d'ecriture de « Vos autres talents » (`CAND-07`) : l'introduction,
// les competences, les niveaux, puis la disponibilite et l'accord, avec
// « Continuer » en bas (le seul bouton plein), « Retour », et la barre de
// progression en haut (la meme coquille que le questionnaire,
// `CoquilleParcours`).
//
// **Rien ne s'enregistre avant la derniere etape.** « Enregistrer mes reponses »
// envoie tout d'un coup, avec la version lue a l'ouverture et une cle
// d'idempotence : la meme cle tant que rien ne change et que l'issue est
// incertaine, une cle neuve des qu'une reponse change. Le succes ne se dit
// qu'apres la reponse du serveur, et l'ecran relit alors les reponses (le
// serveur ne rend jamais une reponse a l'ecriture).
//
// Hors ligne, « Enregistrer mes reponses » n'est pas rendu : une phrase dit
// quand ce sera possible. Les etapes precedentes se parcourent sans reseau.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/candidature/modeles_autres_competences.dart';
import '../../core/candidature/port_autres_competences.dart';
import '../../core/candidature/port_ma_candidature.dart'
    show HorsLigneCandidature;
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../candidature/coquille_parcours.dart';
import 'controleur_talents.dart';
import 'etape_competences.dart';
import 'etape_disponibilite.dart';
import 'etape_introduction.dart';
import 'etape_niveaux.dart';
import 'libelles_talents.dart';

/// Ce que le parcours dit a la page quand l'enregistrement est termine ou que
/// la lecture doit etre refaite.
enum IssueEnregistrement {
  /// Enregistre : la page relit et montre les reponses.
  enregistre,

  /// Les reponses ont change ailleurs : la page relit et le dit.
  conflit,

  /// Une competence choisie n'est plus proposee : la page relit la liste.
  desactivee,

  /// Ce n'est plus ouvert (candidature close ou envoi manquant) : la page relit.
  ferme,
}

/// Le parcours d'ecriture.
class ParcoursTalents extends ConsumerStatefulWidget {
  /// Cree le parcours a partir de la lecture [lecture].
  const ParcoursTalents({
    required this.lecture,
    required this.avecIntroduction,
    required this.onIssue,
    this.messageInitial,
    this.reprise,
    super.key,
  });

  /// Ce que le serveur a rendu a l'ouverture.
  final AutresCompetences lecture;

  /// Faux : la personne modifie des reponses enregistrees, l'introduction est
  /// sautee.
  final bool avecIntroduction;

  /// Appele quand l'enregistrement est termine ou que la page doit relire, avec
  /// ce que la personne avait choisi (de quoi reprendre le parcours si la
  /// liste a change). La page relit les reponses au serveur avant de rendre la
  /// main : le bouton reste « en cours » jusque-la.
  final Future<void> Function(
    IssueEnregistrement issue,
    BrouillonTalents brouillon,
  )
  onIssue;

  /// Un brouillon a reprendre a la place des reponses enregistrees : la liste
  /// des competences vient de changer et la personne ne ressaisit rien.
  final BrouillonTalents? reprise;

  /// Un message a dire en tete de la derniere ligne (la liste vient d'etre mise
  /// a jour, par exemple).
  final String? messageInitial;

  /// La cle du message sous le bouton.
  static const Key messageKey = ValueKey<String>('talents-message');

  /// La cle de la phrase hors ligne.
  static const Key horsLigneKey = ValueKey<String>('talents-hors-ligne');

  /// La cle du compteur de competences choisies.
  static const Key compteurKey = ValueKey<String>('talents-compteur');

  @override
  ConsumerState<ParcoursTalents> createState() => _ParcoursTalentsEtat();
}

class _ParcoursTalentsEtat extends ConsumerState<ParcoursTalents> {
  late final ControleurTalents _c = ControleurTalents(
    lecture: widget.lecture,
    avecIntroduction: widget.avecIntroduction,
    reprise: widget.reprise,
  );
  ManqueTalents? _manque;
  String? _codeSansNiveau;
  late String? _message = widget.messageInitial;
  bool _enCours = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(_surChangement);
  }

  @override
  void dispose() {
    _c
      ..removeListener(_surChangement)
      ..dispose();
    super.dispose();
  }

  void _surChangement() {
    // Une reponse change : l'indication « choisissez... » s'efface.
    if (_manque != null && _c.manque(_c.courante) == null) {
      setState(() {
        _manque = null;
        _codeSansNiveau = null;
      });
    }
  }

  void _sortir() => GoRouter.of(context).go(Routes.attente);

  void _continuer() {
    final ManqueTalents? manque = _c.manque(_c.courante);
    if (manque != null) {
      setState(() {
        _manque = manque;
        _codeSansNiveau = _c.premierSansNiveau;
        _message = null;
      });
      return;
    }
    setState(() {
      _manque = null;
      _message = null;
    });
    _c.avancer();
  }

  void _reculer() {
    setState(() {
      _manque = null;
      _message = null;
    });
    if (_c.estPremiere) {
      _sortir();
    } else {
      _c.reculer();
    }
  }

  Future<void> _enregistrer() async {
    final PortAutresCompetences? port = ref.read(portAutresCompetencesProvider);
    final ManqueTalents? manque = _c.manque(_c.courante);
    if (port == null || _enCours) {
      return;
    }
    if (manque != null) {
      setState(() => _manque = manque);
      return;
    }
    final DisponibiliteMission? dispo = _c.disponibilite;
    if (dispo == null) {
      return;
    }
    final r = t.recrutement.talents.erreurs;
    setState(() {
      _enCours = true;
      _message = null;
    });
    // Ce que la reponse du serveur dit : une issue pour la page, ou un echec a
    // dire ici. Les deux sont poses hors du `try` : un echec de la relecture
    // n'est pas un echec de l'enregistrement.
    IssueEnregistrement? issue;
    String? echec;
    try {
      await port.enregistrer(
        domaines: _c.domainesAEnvoyer,
        disponibilite: dispo,
        accord: _c.accord,
        versionAttendue: _c.lecture.version,
        cleIdempotence: _c.cleIdempotence(),
        autreTexte: _c.autreTexteAEnvoyer,
      );
      // La reponse du serveur est la : on peut le dire.
      _c.oublierCle();
      issue = IssueEnregistrement.enregistre;
    } on ConflitAutresCompetences {
      _c.oublierCle();
      issue = IssueEnregistrement.conflit;
    } on QuestionnaireNonEnvoye {
      _c.oublierCle();
      issue = IssueEnregistrement.ferme;
    } on CandidatureClose {
      _c.oublierCle();
      issue = IssueEnregistrement.ferme;
    } on ReponsesAutresCompetencesInvalides catch (e) {
      _c.oublierCle();
      if (e.domaineDesactive) {
        issue = IssueEnregistrement.desactivee;
      } else {
        echec = r.invalides;
      }
    } on CleAutresCompetencesReutilisee {
      _c.oublierCle();
      echec = r.echec;
    } on HorsLigneCandidature {
      // Non confirme : la meme cle rejouera le meme geste sans l'ecrire deux fois.
      echec = r.incertain;
    } on CapaciteIndisponible {
      echec = r.echec;
    } on PermissionInsuffisante {
      echec = r.echec;
    } on Object {
      echec = r.incertain;
    }
    if (issue != null) {
      await _fini(issue);
    } else if (echec != null) {
      _echec(echec);
    }
  }

  Future<void> _fini(IssueEnregistrement issue) async {
    if (!mounted) {
      return;
    }
    await widget.onIssue(issue, _c.brouillon());
    if (mounted) {
      setState(() => _enCours = false);
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

  /// Le message de ce qui manque pour continuer (K-59).
  String _messageManque() {
    final r = t.recrutement.talents;
    return switch (_manque!) {
      ManqueTalents.aucuneCompetence => r.competences.manque,
      ManqueTalents.autreVide => r.competences.autreVide,
      ManqueTalents.autreTropLong => r.competences.autreTropLong(
        max: widget.lecture.referentiel.autreTexteMax,
      ),
      ManqueTalents.niveau => r.niveaux.manque(
        competence: _nomSansNiveau() ?? '',
      ),
      ManqueTalents.disponibilite => r.disponibilite.manque,
    };
  }

  String? _nomSansNiveau() {
    final String? code = _codeSansNiveau ?? _c.premierSansNiveau;
    if (code == null) {
      return null;
    }
    final EntreeCatalogue? entree = widget.lecture.referentiel.entree(code);
    return libelleCompetence(code, entree: entree);
  }

  /// La ligne sous le bouton : ce qui manque, sinon le dernier echec, sinon (a
  /// l'etape des competences) le nombre de competences choisies.
  Widget? _souscription(bool horsLigne) {
    if (_manque != null) {
      return KeyedSubtree(
        key: ParcoursTalents.messageKey,
        child: IndicationParcours(message: _messageManque()),
      );
    }
    if (_message != null) {
      return KeyedSubtree(
        key: ParcoursTalents.messageKey,
        child: IndicationParcours(message: _message!),
      );
    }
    if (_c.estDerniere && horsLigne) {
      return IndicationParcours(
        key: ParcoursTalents.horsLigneKey,
        message: t.recrutement.talents.erreurs.horsLigne,
        discret: true,
      );
    }
    if (_c.courante == EtapeTalents.competences) {
      return IndicationParcours(
        key: ParcoursTalents.compteurKey,
        message: t.recrutement.talents.competences.choisies(
          n: _c.nombreChoisies,
        ),
        discret: true,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final r = t.recrutement.talents;
    return ListenableBuilder(
      listenable: _c,
      builder: (BuildContext context, Widget? _) {
        final int numero = _c.index + 1;
        final int total = _c.etapes.length;
        // Hors ligne, la derniere etape n'a plus de bouton plein : une phrase
        // dit quand l'enregistrement sera possible (jamais un bouton grise).
        final bool peutEnregistrer = !(_c.estDerniere && horsLigne);
        switch (_c.courante) {
          case EtapeTalents.introduction:
            return CoquilleParcours(
              numero: numero,
              total: total,
              titre: r.titre,
              explication: EtapeIntroduction.texte,
              enfant: const EtapeIntroduction(),
              libelleAction: t.commun.continuer,
              onAction: _continuer,
              onRetour: _reculer,
              choix: true,
            );
          case EtapeTalents.competences:
            return CoquilleParcours(
              numero: numero,
              total: total,
              titre: r.competences.titre,
              explication: r.competences.explication,
              enfant: EtapeCompetences(controleur: _c),
              libelleAction: t.commun.continuer,
              onAction: _continuer,
              onRetour: _reculer,
              choix: true,
              souscription: _souscription(horsLigne),
            );
          case EtapeTalents.niveaux:
            return CoquilleParcours(
              numero: numero,
              total: total,
              titre: r.niveaux.titre,
              explication: r.niveaux.explication,
              enfant: EtapeNiveaux(controleur: _c),
              libelleAction: t.commun.continuer,
              onAction: _continuer,
              onRetour: _reculer,
              choix: true,
              souscription: _souscription(horsLigne),
            );
          case EtapeTalents.disponibilite:
            return CoquilleParcours(
              numero: numero,
              total: total,
              titre: r.disponibilite.titre,
              explication: r.disponibilite.explication,
              enfant: EtapeDisponibilite(controleur: _c, enCours: _enCours),
              libelleAction: peutEnregistrer
                  ? r.disponibilite.enregistrer
                  : null,
              onAction: peutEnregistrer
                  ? () => unawaited(_enregistrer())
                  : null,
              enCours: _enCours,
              fleche: false,
              onRetour: _reculer,
              choix: true,
              souscription: _souscription(horsLigne),
            );
        }
      },
    );
  }
}
