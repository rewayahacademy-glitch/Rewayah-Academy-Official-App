// Le portail de la candidature (`TUT-00b` etendu, `/attente`) : ou en est la
// candidature, et la prochaine action. Une seule.
//
// **Rien n'est calcule ici.** L'etape, l'etat, la pause, la reprise, ce qui
// reste a completer et le versement viennent de `etat_dossier().candidature`
// (`CandidatureDossier`). Le texte d'une pause ou d'un refus est celui du
// modele de la direction, rendu mot pour mot quand le serveur le porte ; jamais
// un motif interne. Aucun code d'etat ne s'affiche : chaque etat a son libelle.
//
// Le retrait de la candidature (CAND-03) est le lien discret du bas : la
// confirmation dit l'effet avant, le succes ne se dit qu'apres la reponse.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/candidature/modeles_candidature.dart';
import '../../core/candidature/port_ma_candidature.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/dossier/etat_dossier.dart';
import '../../core/dossier/service_dossier.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/page_etape.dart' show RangeeEtape;

/// Vrai quand le portail montre l'etat de la candidature plutot que les cinq
/// etats du dossier : en Salle d'examen, ou apres un refus ou un retrait. En
/// Salle de verification et d'entretien, les accords, la piece et la
/// verification gardent leurs ecrans (`TUT-00c`), sous l'en-tete de la salle.
bool vueCandidature(EtatDossier lu) {
  final CandidatureDossier c = lu.candidature;
  if (!c.existe || lu.etape == EtapeDossier.suspendu) {
    return false;
  }
  return c.enSalleExamen || c.issue != IssueCandidature.enCours;
}

/// Le nom de la salle tel que le candidat le lit (directeur, 02/11/2026 ;
/// lot 4 SALLE-1-TOUT-ICI) : « Votre candidature », « Faisons connaissance »,
/// « Bienvenue dans l'equipe ». Les noms de la direction (Salle d'examen...)
/// ne s'affichent jamais au candidat.
String nomDeSalle(CandidatureDossier c) => switch (c.etape) {
  EtapeCandidature.verifications => t.recrutement.sallesCandidat.connaissance,
  EtapeCandidature.confirmee => t.recrutement.sallesCandidat.equipe,
  _ => t.recrutement.sallesCandidat.candidature,
};

/// Le rang de la salle du candidat sur les trois (PLAN-TROIS-SALLES-2026-11-07 :
/// 1 « Votre candidature », 2 « Faisons connaissance », 3 « Bienvenue dans
/// l'equipe »), lu de l'etape que le serveur rend (`etat_dossier()`), jamais
/// deduit ; `null` pour une etape que cette version ne connait pas.
int? rangDeSalle(CandidatureDossier c) => switch (c.etape) {
  EtapeCandidature.recue ||
  EtapeCandidature.invitee ||
  EtapeCandidature.prequalification => 1,
  EtapeCandidature.verifications => 2,
  EtapeCandidature.confirmee => 3,
  null => null,
};

/// Le nombre de salles du parcours du candidat.
const int sallesDuCandidat = 3;

/// La phrase de contexte d'un passage d'etape (CANDIDATURE-UX, directeur,
/// 14/11/2026) : en salle 2 ou 3, tant que la candidature est en cours ;
/// `null` sinon (salle 1, pause, refus, retrait).
String? phrasePassage(CandidatureDossier c) {
  if (c.issue != IssueCandidature.enCours || c.enPause) return null;
  return switch (c.etape) {
    EtapeCandidature.verifications => t.recrutement.sallesCandidat.retenue,
    EtapeCandidature.confirmee => t.recrutement.sallesCandidat.arrivee,
    _ => null,
  };
}

/// Vrai quand le contrat, l'avis d'enregistrement et le code de conduite sont
/// acceptes (lus dans `etat_dossier()`, jamais deduits).
bool accordsFaits(EtatDossier d) =>
    d.contratSigne && d.accuseSigne && d.codeConduiteSigne;

/// Vrai quand la piece est a deposer en salle 1 : pas encore deposee, et le
/// serveur l'accepte maintenant (SALLE-1-TOUT-ICI).
bool pieceADeposer(EtatDossier d) =>
    !d.pieceDeposee && !d.candidature.depotPieceSuspendu;

/// La prochaine action du candidat sur le portail : un libelle et une route,
/// ou `null` quand il n'a rien a faire (examen, pause, refus, retrait).
///
/// SALLE-1-TOUT-ICI : en salle 1, tout se fait ici, dans l'ordre ou les
/// ecrans s'enchainent deja : le cadre et les accords (une seule page, qui
/// mene a la piece), puis la piece, puis les reponses et l'envoi. [dossier]
/// porte l'etat des accords et de la piece ; sans lui, l'ordre d'avant.
({String libelle, String chemin})? prochaineCandidature(
  CandidatureDossier c, {
  EtatDossier? dossier,
}) {
  if (!c.questionnaireOuvert) {
    return null;
  }
  // Le cadre religieux et pedagogique d'abord, quand une case est a cocher :
  // il se lit avant d'avancer, et l'envoi l'exige. CADRE-ECRAN : il a sa
  // propre page, distincte des accords (directeur, 21/10, TEXTES-VALIDES).
  // SALLE-1-TOUT-ICI : puis le contrat et nos accords, sur la leur.
  if (c.cadre.publie && !c.cadre.accepte) {
    return (libelle: t.attente.lireEtAccepter, chemin: Routes.attenteCadre);
  }
  if (dossier != null && !accordsFaits(dossier)) {
    return (libelle: t.attente.lireEtAccepter, chemin: Routes.attenteAccords);
  }
  if (dossier != null && pieceADeposer(dossier)) {
    return (libelle: t.attente.deposerLaPiece, chemin: Routes.attentePiece);
  }
  return (
    libelle: t.recrutement.portail.completer,
    chemin: Routes.attenteCandidature,
  );
}

/// SALLE-2-ENTRETIEN (07/11/2026) : le chemin vers « Faisons connaissance »,
/// quand l'entretien est a fixer ou fixe ; `null` sinon. L'etat vient du
/// serveur (`etat_dossier().candidature.etat`), jamais deduit ici.
String? libelleEntretienPortail(CandidatureDossier c) {
  if (c.issue != IssueCandidature.enCours || c.enPause) return null;
  return switch (c.etat) {
    EtatCandidature.entretienAPlanifier =>
      t.recrutement.entretien.portailChoisir,
    EtatCandidature.entretienPlanifie => t.recrutement.entretien.portailVoir,
    _ => null,
  };
}

/// L'en-tete de la salle, au-dessus des etats qui gardent leurs ecrans.
/// SALLE-2-ENTRETIEN : quand l'entretien est a fixer ou fixe, le lien vers
/// « Faisons connaissance » (`/attente/entretien`) suit l'en-tete.
class EnteteSalle extends StatelessWidget {
  /// Cree l'en-tete.
  const EnteteSalle({required this.candidature, super.key});

  /// La candidature.
  final CandidatureDossier candidature;

  /// La cle de l'en-tete.
  static const Key salleKey = ValueKey<String>('portail-salle');

  /// Le lien vers « Faisons connaissance ».
  static const Key entretienKey = ValueKey<String>('portail-entretien');

  /// La phrase de passage d'etape.
  static const Key passageKey = ValueKey<String>('portail-passage');

  /// La rangee « Etape X sur 3 ».
  static const Key rangKey = ValueKey<String>('portail-rang');

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final String? passage = phrasePassage(candidature);
    final int? rang = rangDeSalle(candidature);
    // CANDIDATURE-UX (directeur, 14/11/2026) : la phrase du passage d'etape
    // au-dessus, puis le nom de la salle et « Etape X sur 3 », avec la
    // rangee d'etapes de l'inscription (`RangeeEtape`), jamais recomposee.
    final Widget entete = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (passage != null) ...<Widget>[
          Text(passage, key: passageKey, style: textes.bodyLarge),
          Ecart.vMd,
        ],
        Text(
          nomDeSalle(candidature),
          key: salleKey,
          style: AppPalette.of(context).inkMuted
              .applyTo(textes.titleSmall ?? const TextStyle()),
        ),
        if (rang != null) ...<Widget>[
          Ecart.vSm,
          RangeeEtape(
            key: rangKey,
            numero: rang,
            total: sallesDuCandidat,
            libelleComplet: true,
          ),
        ],
      ],
    );
    final String? entretien = libelleEntretienPortail(candidature);
    if (entretien == null) return entete;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        entete,
        Ecart.vSm,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: LienFleche(
            key: entretienKey,
            libelle: entretien,
            alignerEnDebut: true,
            onPress: () => GoRouter.of(context).go(Routes.attenteEntretien),
          ),
        ),
      ],
    );
  }
}

/// Le contenu de la carte d'etat d'une candidature.
class StatutCandidature extends StatelessWidget {
  /// Cree le contenu.
  const StatutCandidature({required this.candidature, this.dossier, super.key});

  /// La candidature.
  final CandidatureDossier candidature;

  /// L'etat du dossier (accords, piece), pour la page unique de la salle 1.
  final EtatDossier? dossier;

  /// La cle du titre de l'etat.
  static const Key titreKey = ValueKey<String>('portail-titre');

  @override
  Widget build(BuildContext context) {
    final CandidatureDossier c = candidature;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final r = t.recrutement.portail;
    final TextStyle muet = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );

    // Un texte tres agrandi passe d'un titre d'ecran a un titre de carte :
    // « candidature » ne se coupe pas a 320 de large.
    final bool agrandi = MediaQuery.textScalerOf(context).scale(14) / 14 > 1.3;
    Widget titre(String texte) => Text(
      texte,
      key: titreKey,
      style: agrandi ? textes.titleMedium : textes.headlineSmall,
    );
    Widget paragraphe(String texte, {Key? cle, TextStyle? style}) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Text(texte, key: cle, style: style ?? textes.bodyMedium),
    );

    final List<Widget> corps;
    if (c.issue == IssueCandidature.refusee) {
      corps = <Widget>[
        titre(r.refuseeTitre),
        // Le texte du modele de la direction, mot pour mot ; jamais le motif.
        if (c.refusTexte != null)
          paragraphe(
            c.refusTexte!,
            cle: const ValueKey<String>('portail-refus-texte'),
            style: textes.bodyLarge,
          ),
      ];
    } else if (c.issue == IssueCandidature.retiree) {
      corps = <Widget>[titre(r.retireeTitre), paragraphe(r.retiree)];
    } else if (c.enPause) {
      corps = <Widget>[
        titre(r.enPauseTitre),
        if (c.pauseTexte != null)
          paragraphe(
            c.pauseTexte!,
            cle: const ValueKey<String>('portail-pause-texte'),
            style: textes.bodyLarge,
          ),
        if (c.repriseLe != null)
          paragraphe(r.repriseLe(date: _jour(c.repriseLe!)), style: muet),
        paragraphe(r.libreDePartir, style: muet),
      ];
    } else if (c.questionnaireOuvert) {
      final List<String> demandes = <String>[
        for (final String code in c.complementDemande)
          if (_elementDemande(code) case final String libelle) libelle,
      ];
      final EtatDossier? d = dossier;
      final int restantes = c.questionnaire.manquants.length;
      final bool reponsesPretes = !c.questionnaire.perime && restantes == 0;
      String etat(bool fait, String aFaire) => fait ? r.etatFait : aFaire;
      corps = <Widget>[
        titre(r.aCompleterTitre),
        // SALLE-1-TOUT-ICI : tout se fait ici, et le deja fait se voit.
        paragraphe(r.toutIci, style: muet),
        if (demandes.isNotEmpty) ...<Widget>[
          paragraphe(r.complementDemande),
          // La liste que la direction a choisie, jamais un texte libre.
          paragraphe(
            r.complementListe(elements: demandes.join(', ')),
            cle: const ValueKey<String>('portail-complement'),
          ),
        ],
        Ecart.vXl,
        GroupeReglages(
          titre: d == null ? r.aCompleter : r.listeTitre,
          lignes: <LigneRubrique>[
            // CADRE-ECRAN : tant qu'il reste a accepter, la ligne mene au
            // cadre, ou il se lit et s'accepte ; accepte, elle dit « Fait »,
            // sans lien (regle 296/312 du garde-cap, 07/11).
            if (c.cadre.publie && !c.cadre.accepte)
              LigneRubrique(
                icone: AppIcons.cahier,
                libelle: r.elementCadre,
                valeur: t.attente.etatAAccepter,
                onPress: () => unawaited(context.push(Routes.attenteCadre)),
              )
            else if (c.cadre.publie && d != null)
              LigneRubrique(
                icone: AppIcons.cahier,
                libelle: r.elementCadre,
                valeur: r.etatFait,
              ),
            if (d != null) ...<LigneRubrique>[
              LigneRubrique(
                icone: AppIcons.contractuel,
                libelle: r.elementAccords,
                valeur: etat(accordsFaits(d), t.attente.etatAAccepter),
              ),
              if (!d.candidature.depotPieceSuspendu)
                LigneRubrique(
                  icone: AppIcons.profil,
                  libelle: r.elementPiece,
                  valeur: etat(d.pieceDeposee, r.etatADeposer),
                  // INCIDENT-CANDIDATS (14/11/2026) : la piece recue se dit
                  // en mots, pas seulement par « Fait ».
                  legende: d.pieceDeposee ? r.pieceRecue : null,
                ),
              // HARMONISATION-E : la photo et l'accord de publication, lus
              // dans etat_dossier() ; ils se posent au recapitulatif des
              // reponses. Un serveur qui ne les rend pas : pas de ligne.
              if (d.photoPosee != null)
                LigneRubrique(
                  icone: AppIcons.image,
                  libelle: r.elementPhoto,
                  // INCIDENT-CANDIDATS (14/11/2026) : la photo envoyee
                  // s'affichait « A ajouter » tant que l'accord de
                  // publication (coche a l'envoi des reponses) manquait : le
                  // candidat croyait l'envoi rate. La photo se lit seule ;
                  // l'accord qui reste se dit dessous.
                  valeur: etat(d.photoPosee!, r.etatAAjouter),
                  legende: !d.photoPosee!
                      ? null
                      : (d.accordPublicationSigne ?? false)
                      ? r.photoRecue
                      : r.accordAEnvoyer,
                ),
            ],
            LigneRubrique(
              icone: AppIcons.dossiers,
              libelle: d == null
                  ? t.recrutement.questionnaire.titre
                  : r.elementReponses,
              legende: d == null
                  ? null
                  : reponsesPretes
                  ? r.reponsesPretes
                  : r.reponsesRestantes(n: restantes),
              valeur: r.etatAEnvoyer,
            ),
          ],
        ),
      ];
    } else if (c.etat == EtatCandidature.paiementNonDisponible) {
      // Versement pas encore possible : l'etat vient du serveur (transition 8
      // de L6), l'ecran ne le deduit pas du versement. La direction n'examine
      // plus rien tant qu'aucun moyen n'est possible : « en examen » serait
      // faux ici. Rien a faire, sauf attendre ou retirer.
      corps = <Widget>[
        titre(r.versementImpossibleTitre),
        paragraphe(
          r.versementImpossible,
          cle: const ValueKey<String>('portail-versement'),
        ),
        paragraphe(r.libreDePartir, style: muet),
      ];
    } else {
      // En examen : la direction lit les reponses.
      corps = <Widget>[titre(r.enExamenTitre), paragraphe(r.enExamen)];
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        EnteteSalle(candidature: c),
        Ecart.vSm,
        ...corps,
      ],
    );
  }

  /// Le libelle d'un element que la direction demande de completer, ou `null`
  /// pour un code que cette version ne connait pas (il ne s'affiche jamais).
  static String? _elementDemande(String code) => switch (code) {
    'langues' => t.recrutement.questionnaire.langues,
    'recitation' => t.recrutement.questionnaire.recitation,
    'disponibilites' => t.recrutement.questionnaire.disponibilites,
    'publics' => t.recrutement.questionnaire.publics,
    'versement' => t.recrutement.questionnaire.versement,
    'cadre_religieux' => t.recrutement.portail.elementCadre,
    'piece_identite' => t.recrutement.portail.elementPiece,
    'contrat' => t.recrutement.portail.elementContrat,
    'avis' => t.attente.carteAccuse,
    _ => null,
  };

  static String _jour(DateTime d) => isolerSens(
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}',
  );
}

/// Le lien discret « Retirer ma candidature » (CAND-03), avec sa confirmation.
///
/// Rendu seulement tant que la candidature peut etre retiree (`peutRetirer`,
/// lu au serveur) et que le port existe. Hors ligne, le lien n'est pas rendu :
/// une note dit quand il le sera.
class LienRetraitCandidature extends ConsumerStatefulWidget {
  /// Cree le lien.
  const LienRetraitCandidature({required this.candidature, super.key});

  /// La candidature.
  final CandidatureDossier candidature;

  /// La cle du lien.
  static const Key lienKey = ValueKey<String>('retrait-lien');

  /// La cle de la note hors ligne.
  static const Key noteKey = ValueKey<String>('retrait-hors-ligne');

  /// La cle du message d'echec.
  static const Key messageKey = ValueKey<String>('retrait-message');

  @override
  ConsumerState<LienRetraitCandidature> createState() =>
      _LienRetraitCandidatureState();
}

class _LienRetraitCandidatureState
    extends ConsumerState<LienRetraitCandidature> {
  bool _enCours = false;
  String? _message;
  String? _cle;

  Future<void> _retirer() async {
    final PortMaCandidature? port = ref.read(portMaCandidatureProvider);
    if (port == null) {
      return;
    }
    final r = t.recrutement.retrait;
    final CandidatureDossier c = widget.candidature;
    // L'effet se dit avant le geste ; en Salle d'examen, jamais un mot
    // d'entretien (ce ne serait pas vrai).
    final bool confirme = await ConfirmDestructive.demander(
      context,
      question: r.question,
      consequence: c.etat == EtatCandidature.entretienPlanifie
          ? r.consequenceEntretien
          : r.consequence,
      libelleConfirmer: r.confirmer,
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
      await port.retirer(versionAttendue: c.version, cleIdempotence: cle);
      // Le retrait ne s'affiche qu'apres la reponse : le portail relit l'etat.
      ref.invalidate(etatDossierProvider);
      if (mounted) {
        setState(() => _enCours = false);
      }
    } on ConflitCandidature {
      _cle = null;
      ref.invalidate(etatDossierProvider);
      _echec(r.conflit);
    } on TransitionInterdite {
      _cle = null;
      ref.invalidate(etatDossierProvider);
      _echec(r.interdit);
    } on HorsLigneCandidature {
      _echec(r.incertain);
    } on CapaciteIndisponible {
      _cle = null;
      _echec(r.echec);
    } on PermissionInsuffisante {
      _cle = null;
      _echec(r.interdit);
    } on Object {
      _echec(r.incertain);
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

  @override
  Widget build(BuildContext context) {
    final PortMaCandidature? port = ref.watch(portMaCandidatureProvider);
    if (port == null || !widget.candidature.peutRetirer) {
      return const SizedBox.shrink();
    }
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (_message != null) ...<Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              _message!,
              key: LienRetraitCandidature.messageKey,
              textAlign: TextAlign.center,
              style: palette.inkAlert.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vSm,
        ],
        if (horsLigne)
          Text(
            t.recrutement.retrait.horsLigne,
            key: LienRetraitCandidature.noteKey,
            textAlign: TextAlign.center,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          )
        else
          ActionPrincipale(
            key: LienRetraitCandidature.lienKey,
            libelle: t.recrutement.retrait.lien,
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
            enCours: _enCours,
            onPress: _enCours ? null : () => unawaited(_retirer()),
          ),
      ],
    );
  }
}
