// Inviter la conjointe ou le conjoint (EA-6, planche 2.2, UX_REVIEW_07
// ligne 9) : deux etapes, les coordonnees puis « Verifier et envoyer », et le
// detail de l'invitation envoyee, qui se laisse annuler. Etats du doc
// section 5.2 cote titulaire : en preparation (etape 2), envoyee, expiree et
// annulee (sur la ligne de Ma famille, F21), erreur reseau, double envoi,
// reponse tardive apres annulation (le serveur ne rattache personne, la
// ligne reste « annulee » ; la demonstration fait arriver cette acceptation
// tardive, `DonneesAdulteDemo.acceptationRecue`, EA-6c).
//
// Textes (EA-6c) : le titre « Inviter ma conjointe / mon conjoint » et les
// boutons « Continuer » puis « Envoyer l'invitation » suivent la decision
// E4 ; l'en-tete, sa phrase et l'aide de l'adresse viennent de la planche
// 2.2 et du doc section 19 ; les echecs reseau suivent D5 mot pour mot.
// Les autres libelles n'ont aucune source (spec, planche) : chacun est
// marque « libelle provisoire, lexique D4 » la ou il est lu.
//
// Rien de recree (K-51) : `PageEtape` et sa rangee d'etape, `ActionPrincipale`,
// `EtatSysteme`, `ConfirmDestructive`, `LigneCleValeur`, `PageShell`.
//
// **Aucune source serveur a ce jour** (EA-BR-15) : le port rend
// `CapaciteIndisponible`, la demonstration le surcharge (K-28). L'envoi est
// neutre (F4) : aucune reponse ne dit si l'adresse a deja un compte, ni quel
// genre il porte ; seule une erreur de format est dite, apres la sortie du
// champ.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_recharge_foyer.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/ecran_resultat.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/page_etape.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart' show TonEtat;
import '../../core/widgets/zone_saisie.dart' show ZoneSaisie;
import '../compte/donnees_compte.dart' show dateLongue;
import 'ligne_membre.dart' show dateEcheance;
import 'photo_eleve.dart';
import 'place_adulte.dart';

// Le cote du second adulte (EA-7) partage les briques privees de cette page
// (titre, note, actions, colonne, focus a l'apparition) : rien de recree.
part 'acceptation_invitation.dart';

// La sortie et le delai (EA-8) aussi.
part 'sortie_forfait.dart';

// La recharge du foyer (EA-10) aussi.
part 'recharge_foyer.dart';

// La reprise du foyer (EA-11) aussi.
part 'reprise_foyer.dart';

// « Ajouter ma famille » (EA-PL parcours) aussi.
part 'ajouter_ma_famille.dart';

/// Ce que le titulaire envoie : le prenom et l'adresse (obligatoires), le nom
/// (facultatif, Q7), et une cle d'idempotence tiree une fois par saisie, que
/// chaque nouvelle tentative reprend (doc section 17).
@immutable
class InvitationConjoint {
  /// Cree l'invitation.
  const InvitationConjoint({
    required this.prenom,
    required this.nom,
    required this.courriel,
    required this.cle,
  });

  /// Le prenom de la personne invitee.
  final String prenom;

  /// Son nom, vide s'il n'est pas donne.
  final String nom;

  /// L'adresse a laquelle l'invitation part.
  final String courriel;

  /// La cle d'idempotence de cet envoi.
  final String cle;
}

/// La reponse du serveur a un envoi.
sealed class ResultatInvitation {
  const ResultatInvitation();
}

/// L'invitation est partie.
final class InvitationPartie extends ResultatInvitation {
  /// Cree la reponse.
  const InvitationPartie();
}

/// Le serveur refuse, sans dire pourquoi (F4) : la place n'est plus libre, par
/// exemple. Jamais « cette adresse a deja un compte ».
final class InvitationRefusee extends ResultatInvitation {
  /// Cree la reponse.
  const InvitationRefusee();
}

/// La connexion a coupe : l'invitation n'est pas partie, ou sa reponse est
/// perdue ; la meme cle rend une nouvelle tentative sure.
final class InvitationEchecReseau extends ResultatInvitation {
  /// Cree la reponse.
  const InvitationEchecReseau();
}

/// La reponse du serveur a une annulation.
sealed class ResultatAnnulation {
  const ResultatAnnulation();
}

/// L'invitation est annulee : elle ne peut plus etre acceptee.
final class AnnulationFaite extends ResultatAnnulation {
  /// Cree la reponse.
  const AnnulationFaite();
}

/// La connexion a coupe : l'annulation n'est pas confirmee, l'ecran ne dit
/// que cela (decision D5), jamais « pas annulee ».
final class AnnulationEchecReseau extends ResultatAnnulation {
  /// Cree la reponse.
  const AnnulationEchecReseau();
}

/// L'invitation du second adulte, cote titulaire (EA-BR-15).
abstract interface class PortInvitationConjoint {
  /// Envoie l'invitation. Une seule invitation active par foyer : le serveur
  /// le verifie.
  Future<ResultatInvitation> envoyer(InvitationConjoint invitation);

  /// Annule l'invitation active. Une reponse tardive ne rattache personne.
  Future<ResultatAnnulation> annuler();
}

/// **Aucune source serveur a ce jour** (EA-BR-15).
class _InvitationIndisponible implements PortInvitationConjoint {
  const _InvitationIndisponible();

  @override
  Future<ResultatInvitation> envoyer(InvitationConjoint _) =>
      Future<ResultatInvitation>.error(
        const CapaciteIndisponible('invitation_conjoint'),
      );

  @override
  Future<ResultatAnnulation> annuler() => Future<ResultatAnnulation>.error(
    const CapaciteIndisponible('invitation_conjoint'),
  );
}

/// Le port de l'invitation ; la demonstration le surcharge.
final Provider<PortInvitationConjoint> portInvitationConjointProvider =
    Provider<PortInvitationConjoint>(
      (Ref _) => const _InvitationIndisponible(),
    );

/// Une adresse de forme valable : un seul `@`, un point dans le domaine. Le
/// serveur refait le controle ; ce n'est qu'une aide de saisie.
bool courrielBienForme(String valeur) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(valeur.trim());

/// Ce que l'ecran dit apres un envoi ou une annulation manques.
enum _Echec { reseau, refus, indisponible }

/// Inviter la conjointe (titulaire homme) ou le conjoint (titulaire femme) :
/// etape 1, les coordonnees ; etape 2, « Verifier et envoyer » ; puis
/// « Invitation envoyee ». Le retour de l'etape 2 garde la saisie (W-337).
class InviterConjointPage extends ConsumerStatefulWidget {
  /// Cree la page.
  const InviterConjointPage({
    required this.placeFeminine,
    required this.onAbandon,
    required this.onTerminee,
    super.key,
  });

  /// Vrai pour une conjointe, faux pour un conjoint (F3).
  final bool placeFeminine;

  /// Quitter depuis la premiere etape.
  final VoidCallback onAbandon;

  /// « Revenir a Ma famille », apres l'envoi.
  final VoidCallback onTerminee;

  /// Le champ prenom.
  static const Key prenomKey = Key('invitation.prenom');

  /// Le champ nom.
  static const Key nomKey = Key('invitation.nom');

  /// Le champ adresse.
  static const Key courrielKey = Key('invitation.courriel');

  /// « Continuer » (etape 1, decision E4 ; corrige en EA-5c).
  static const Key verifierKey = Key('invitation.verifier');

  /// « Modifier » (etape 2).
  static const Key modifierKey = Key('invitation.modifier');

  /// « Envoyer l'invitation » (etape 2).
  static const Key envoyerKey = Key('invitation.envoyer');

  /// Le recapitulatif (etape 2).
  static const Key recapitulatifKey = Key('invitation.recapitulatif');

  /// Le resultat « Invitation envoyee ».
  static const Key envoyeeKey = Key('invitation.envoyee');

  /// « Revenir a Ma famille » apres l'envoi.
  static const Key revenirKey = Key('invitation.revenir');

  /// Le titre de l'etape 2, qui prend le focus a son apparition.
  static const Key focusEtape2Key = Key('invitation.focusEtape2');

  /// L'echec d'un envoi, qui prend le focus a son apparition.
  static const Key focusEchecKey = Key('invitation.focusEchec');

  /// Le resultat « Invitation envoyee », qui prend le focus.
  static const Key focusResultatKey = Key('invitation.focusResultat');

  @override
  ConsumerState<InviterConjointPage> createState() =>
      _InviterConjointPageState();
}

class _InviterConjointPageState extends ConsumerState<InviterConjointPage> {
  final TextEditingController _prenom = TextEditingController();
  final TextEditingController _nom = TextEditingController();
  final TextEditingController _courriel = TextEditingController();
  final FocusNode _focusCourriel = FocusNode();

  /// Une cle par saisie : une nouvelle tentative apres une coupure reprend la
  /// meme ; une saisie modifiee en tire une autre.
  String _cle = const Uuid().v4();

  bool _verification = false;
  bool _montrerErreurs = false;
  bool _courrielQuitte = false;
  bool _envoi = false;
  bool _partie = false;
  _Echec? _echec;

  @override
  void initState() {
    super.initState();
    // L'erreur de format se dit a la sortie du champ, pas a chaque lettre.
    _focusCourriel.addListener(() {
      if (!_focusCourriel.hasFocus && _courriel.text.trim().isNotEmpty) {
        setState(() => _courrielQuitte = true);
      }
    });
  }

  @override
  void dispose() {
    _prenom.dispose();
    _nom.dispose();
    _courriel.dispose();
    _focusCourriel.dispose();
    super.dispose();
  }

  String? get _erreurPrenom => _montrerErreurs && _prenom.text.trim().isEmpty
      ? t.adulte.invitation.prenomRequis
      : null;

  String? get _erreurCourriel {
    final String valeur = _courriel.text.trim();
    if (valeur.isEmpty) {
      return _montrerErreurs ? t.adulte.invitation.courrielRequis : null;
    }
    if ((_montrerErreurs || _courrielQuitte) && !courrielBienForme(valeur)) {
      return t.adulte.invitation.courrielInvalide;
    }
    return null;
  }

  void _verifier() {
    setState(() => _montrerErreurs = true);
    if (_erreurPrenom != null || _erreurCourriel != null) return;
    setState(() {
      _verification = true;
      _echec = null;
    });
  }

  void _retour() {
    if (_envoi) return;
    if (_verification) {
      // Retour sans perte : les champs gardent leur saisie (W-337).
      setState(() {
        _verification = false;
        _echec = null;
      });
      return;
    }
    widget.onAbandon();
  }

  void _modifie(String _) {
    // Une autre saisie est un autre envoi : une autre cle.
    _cle = const Uuid().v4();
    setState(() {});
  }

  Future<void> _envoyer() async {
    // Double envoi : un seul appel part, le bouton attend la reponse.
    if (_envoi) return;
    // Hors ligne, rien ne part, meme si le bouton n'a pas encore ete
    // reconstruit (revue EA-R m13).
    if (ref.read(horsLigneProvider).value ?? false) return;
    setState(() {
      _envoi = true;
      _echec = null;
    });
    ResultatInvitation resultat;
    try {
      resultat = await ref
          .read(portInvitationConjointProvider)
          .envoyer(
            InvitationConjoint(
              prenom: _prenom.text.trim(),
              nom: _nom.text.trim(),
              courriel: _courriel.text.trim(),
              cle: _cle,
            ),
          );
    } on CapaciteIndisponible {
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _echec = _Echec.indisponible;
      });
      return;
    } on Object {
      resultat = const InvitationEchecReseau();
    }
    if (!mounted) return;
    setState(() {
      _envoi = false;
      switch (resultat) {
        case InvitationPartie():
          _partie = true;
        case InvitationRefusee():
          _echec = _Echec.refus;
        case InvitationEchecReseau():
          _echec = _Echec.reseau;
      }
    });
    // Ma famille relira la place : « Invitation envoyee » apres l'envoi,
    // jamais un rattachement (E7) ; son etat reel apres un refus.
    if (_partie || _echec == _Echec.refus) {
      ref.invalidate(foyerTitulaireProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    if (_partie) {
      // Le titre est celui de l'ecran resultat (M4) : la coquille n'en porte
      // pas, pour qu'il ne soit pas dit deux fois.
      return PageShell(
        child: _Resultat(
          courriel: _courriel.text.trim(),
          onRevenir: widget.onTerminee,
        ),
      );
    }
    return PopScope(
      canPop: !_verification && !_envoi,
      onPopInvokedWithResult: (bool fait, Object? _) {
        if (!fait) _retour();
      },
      child: PageEtape(
        numero: _verification ? 2 : 1,
        total: 2,
        onRetour: _retour,
        child: _Colonne(
          child: _verification
              ? _pageVerification(context, horsLigne)
              : _pageCoordonnees(context),
        ),
      ),
    );
  }

  Widget _pageCoordonnees(BuildContext context) {
    final bool f = widget.placeFeminine;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Titre(
          // Decision E4 : « Inviter ma conjointe / Inviter mon conjoint ».
          titre: f
              ? t.adulte.invitation.titreElle
              : t.adulte.invitation.titreLui,
          sousTitre: f
              ? t.adulte.invitation.enteteElle
              : t.adulte.invitation.enteteLui,
          phrase: f
              ? t.adulte.invitation.phraseElle
              : t.adulte.invitation.phraseLui,
        ),
        Ecart.vXxl,
        TextField(
          key: InviterConjointPage.prenomKey,
          controller: _prenom,
          onChanged: _modifie,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          // Erreurs de saisie : libelles provisoires, lexique D4.
          decoration: InputDecoration(
            labelText: t.adulte.invitation.prenom,
            errorText: _erreurPrenom,
            errorMaxLines: ZoneSaisie.lignesAideMax,
          ),
        ),
        Ecart.vMd,
        TextField(
          key: InviterConjointPage.nomKey,
          controller: _nom,
          onChanged: _modifie,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          // « Facultatif. » : libelle provisoire, lexique D4 (Q7).
          decoration: InputDecoration(
            labelText: t.adulte.invitation.nom,
            helperText: t.adulte.invitation.nomAide,
            helperMaxLines: ZoneSaisie.lignesAideMax,
          ),
        ),
        Ecart.vMd,
        TextField(
          key: InviterConjointPage.courrielKey,
          controller: _courriel,
          focusNode: _focusCourriel,
          onChanged: _modifie,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          autofillHints: const <String>[AutofillHints.email],
          onSubmitted: (String _) => _verifier(),
          // L'aide de la planche 2.2, accordee au genre de la place.
          decoration: InputDecoration(
            labelText: t.adulte.invitation.courriel,
            helperText: f
                ? t.adulte.invitation.courrielAideElle
                : t.adulte.invitation.courrielAideLui,
            helperMaxLines: ZoneSaisie.lignesAideMax,
            errorText: _erreurCourriel,
            errorMaxLines: ZoneSaisie.lignesAideMax,
          ),
        ),
        Ecart.vLg,
        _Actions(
          principale: ActionPrincipale(
            key: InviterConjointPage.verifierKey,
            libelle: t.adulte.invitation.verifier,
            onPress: _verifier,
            fleche: true,
            pleineLargeur: false,
          ),
        ),
      ],
    );
  }

  Widget _pageVerification(BuildContext context, bool horsLigne) {
    final String nom = _nom.text.trim();
    final Widget? etat = switch (_echec) {
      // D5 : l'ecran ne dit que ce qu'il sait, l'envoi n'est pas confirme.
      _Echec.reseau => EtatSysteme(
        nature: NatureEtat.echecServeur,
        titre: t.adulte.invitation.echecTitre,
        phrase: t.adulte.invitation.echecPhrase,
      ),
      // Refus neutre (F4) : une action, revenir a Ma famille qui dit l'etat
      // reel de la place ; « Envoyer » ne reste pas actif. Titre et phrase :
      // libelles provisoires, lexique D4.
      _Echec.refus => EtatSysteme(
        nature: NatureEtat.accesRefuse,
        titre: t.adulte.invitation.refusTitre,
        phrase: t.adulte.invitation.refusPhrase,
        libelleAction: t.adulte.invitation.revenirMaFamille,
        onAction: widget.onAbandon,
      ),
      _Echec.indisponible => const EtatSysteme(
        nature: NatureEtat.indisponible,
        dependance: 'EA-BR-15',
      ),
      null => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // « Verifier et envoyer » (planche 2.2, UX_REVIEW_07 ligne 9) ; sa
        // phrase et « Non renseigne » : libelles provisoires, lexique D4.
        _FocusALApparition(
          key: InviterConjointPage.focusEtape2Key,
          child: _Titre(
            titre: t.adulte.invitation.verifierTitre,
            phrase: t.adulte.invitation.verifierPhrase,
          ),
        ),
        Ecart.vXxl,
        _Carte(
          key: InviterConjointPage.recapitulatifKey,
          lignes: <Widget>[
            LigneCleValeur(
              cle: t.adulte.invitation.prenom,
              valeur: _prenom.text.trim(),
            ),
            LigneCleValeur(
              cle: t.adulte.invitation.nom,
              valeur: nom.isEmpty ? t.adulte.invitation.nonRenseigne : nom,
            ),
            LigneCleValeur(
              cle: t.adulte.invitation.courriel,
              valeur: _courriel.text.trim(),
            ),
          ],
        ),
        if (etat != null) ...<Widget>[
          Ecart.vLg,
          _FocusALApparition(
            key: InviterConjointPage.focusEchecKey,
            child: etat,
          ),
        ],
        // Hors ligne : rien ne part tout seul. Libelle provisoire, lexique D4.
        if (horsLigne) ...<Widget>[
          Ecart.vLg,
          _Note(texte: t.adulte.invitation.horsLigne),
        ],
        Ecart.vLg,
        _Actions(
          secondaire: ActionPrincipale(
            key: InviterConjointPage.modifierKey,
            libelle: t.adulte.invitation.modifier,
            onPress: _envoi ? null : _retour,
            niveau: NiveauAction.secondaire,
            pleineLargeur: false,
          ),
          principale: ActionPrincipale(
            key: InviterConjointPage.envoyerKey,
            libelle: t.adulte.invitation.envoyer,
            onPress:
                horsLigne ||
                    _echec == _Echec.indisponible ||
                    _echec == _Echec.refus
                ? null
                : () => unawaited(_envoyer()),
            enCours: _envoi,
            pleineLargeur: false,
          ),
        ),
      ],
    );
  }
}

/// Le detail de l'invitation envoyee, ouvert depuis la ligne de la place :
/// a qui elle est partie, et « Annuler l'invitation » (destructif, confirme).
class InvitationEnvoyeePage extends ConsumerStatefulWidget {
  /// Cree la page.
  const InvitationEnvoyeePage({
    required this.invitation,
    required this.onRetour,
    required this.onAnnulee,
    super.key,
  });

  /// L'invitation, telle que le serveur la rend.
  final InvitationEnvoyee invitation;

  /// Retour a Ma famille.
  final VoidCallback onRetour;

  /// L'invitation est annulee : retour a Ma famille, place libre.
  final VoidCallback onAnnulee;

  /// « Annuler l'invitation ».
  static const Key annulerKey = Key('invitation.annuler');

  @override
  ConsumerState<InvitationEnvoyeePage> createState() =>
      _InvitationEnvoyeePageState();
}

class _InvitationEnvoyeePageState extends ConsumerState<InvitationEnvoyeePage> {
  bool _envoi = false;
  _Echec? _echec;

  Future<void> _annuler() async {
    if (_envoi) return;
    final String? prenom = widget.invitation.prenom;
    final bool confirme = await ConfirmDestructive.demander(
      context,
      question: prenom == null
          ? t.adulte.invitation.annulerQuestionSansPrenom
          : t.adulte.invitation.annulerQuestion(prenom: prenom),
      consequence: t.adulte.invitation.annulerConsequence,
      libelleConfirmer: t.adulte.invitation.annuler,
      libelleAnnuler: t.adulte.invitation.garder,
    );
    if (!confirme || !mounted || _envoi) return;
    // Le reseau a pu couper pendant la confirmation (revue EA-R m13).
    if (ref.read(horsLigneProvider).value ?? false) return;
    setState(() {
      _envoi = true;
      _echec = null;
    });
    ResultatAnnulation resultat;
    try {
      resultat = await ref.read(portInvitationConjointProvider).annuler();
    } on CapaciteIndisponible {
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _echec = _Echec.indisponible;
      });
      return;
    } on Object {
      resultat = const AnnulationEchecReseau();
    }
    if (!mounted) return;
    switch (resultat) {
      case AnnulationFaite():
        setState(() => _envoi = false);
        ref.invalidate(foyerTitulaireProvider);
        widget.onAnnulee();
      case AnnulationEchecReseau():
        setState(() {
          _envoi = false;
          _echec = _Echec.reseau;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final InvitationEnvoyee invitation = widget.invitation;
    return PageShell(
      titre: t.adulte.famille.place.invitationEnvoyee,
      onRetour: widget.onRetour,
      // Le contenu part du bord du titre de la page, aussi a 1440 (EA-6c).
      child: _Colonne(
        auBordDeDebut: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Phrase, question, consequence et « Garder l'invitation » :
            // libelles provisoires, lexique D4.
            _Note(texte: t.adulte.invitation.detailPhrase, attenuee: true),
            if (invitation.prenom != null ||
                invitation.courriel != null) ...<Widget>[
              Ecart.vXxl,
              _Carte(
                lignes: <Widget>[
                  if (invitation.prenom case final String prenom)
                    LigneCleValeur(
                      cle: t.adulte.invitation.prenom,
                      valeur: prenom,
                    ),
                  if (invitation.courriel case final String courriel)
                    LigneCleValeur(
                      cle: t.adulte.invitation.courriel,
                      valeur: courriel,
                    ),
                ],
              ),
            ],
            // D5 : l'annulation n'est pas confirmee, rien de plus.
            if (_echec == _Echec.reseau) ...<Widget>[
              Ecart.vLg,
              _FocusALApparition(
                key: InviterConjointPage.focusEchecKey,
                child: EtatSysteme(
                  nature: NatureEtat.echecServeur,
                  titre: t.adulte.invitation.annulationEchecTitre,
                  phrase: t.adulte.invitation.annulationEchecPhrase,
                ),
              ),
            ] else if (_echec == _Echec.indisponible) ...<Widget>[
              Ecart.vLg,
              const EtatSysteme(
                nature: NatureEtat.indisponible,
                dependance: 'EA-BR-15',
              ),
            ],
            // Rien ne s'annule tout seul. Libelle provisoire, lexique D4.
            if (horsLigne) ...<Widget>[
              Ecart.vLg,
              _Note(texte: t.adulte.invitation.annulerHorsLigne),
            ],
            Ecart.vLg,
            // Destructif : jamais un second bouton plein (contrat B).
            _Actions(
              principale: ActionPrincipale(
                key: InvitationEnvoyeePage.annulerKey,
                libelle: t.adulte.invitation.annuler,
                niveau: NiveauAction.destructive,
                onPress: horsLigne || _echec == _Echec.indisponible
                    ? null
                    : () => unawaited(_annuler()),
                enCours: _envoi,
                pleineLargeur: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Le resultat de l'envoi : ce que la reponse dit, et seulement cela (E7),
/// dans la grammaire partagee `EcranResultat` (M4), comme la sortie (EA-8) :
/// aucune coche, aucun « succes », le ton neutre.
class _Resultat extends StatelessWidget {
  const _Resultat({required this.courriel, required this.onRevenir});

  final String courriel;
  final VoidCallback onRevenir;

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: InviterConjointPage.envoyeeKey,
    child: _FocusALApparition(
      key: InviterConjointPage.focusResultatKey,
      child: Semantics(
        liveRegion: true,
        // La phrase du resultat : libelle provisoire, lexique D4.
        child: EcranResultat(
          icone: AppIcons.invitationEnvoyee,
          ton: TonEtat.neutre,
          titre: t.adulte.invitation.envoyeeTitre,
          phrase: t.adulte.invitation.envoyeePhrase(courriel: courriel),
          libelleAction: t.adulte.invitation.revenirMaFamille,
          onAction: onRevenir,
          cleAction: InviterConjointPage.revenirKey,
        ),
      ),
    ),
  );
}

/// Le titre de l'etape, en en-tete, puis son sous-titre et sa phrase.
class _Titre extends StatelessWidget {
  const _Titre({required this.titre, required this.phrase, this.sousTitre});

  final String titre;
  final String? sousTitre;
  final String phrase;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            titre,
            style: palette.inkStrong.applyTo(
              textes.headlineMedium ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vLg,
        if (sousTitre case final String s) ...<Widget>[
          Text(
            s,
            style: palette.inkStrong.applyTo(
              textes.titleMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vXs,
        ],
        Text(
          phrase,
          style: palette.inkMuted.applyTo(
            textes.bodyLarge ?? const TextStyle(),
          ),
        ),
      ],
    );
  }
}

/// Une phrase d'etat ou de precision, annoncee a son apparition.
class _Note extends StatelessWidget {
  const _Note({required this.texte, this.attenuee = false, super.key});

  final String texte;
  final bool attenuee;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: !attenuee,
      child: Text(
        texte,
        style: (attenuee ? palette.inkMuted : palette.inkStrong).applyTo(
          (attenuee ? textes.bodyLarge : textes.bodyMedium) ??
              const TextStyle(),
        ),
      ),
    );
  }
}

/// Un groupe de lignes sur une seule surface (K-42 point 4) : la surface est
/// `AppCard`, seul point d'entree d'une surface (M4) ; `_Carte` ne fait que
/// poser les lignes en colonne, sans decoration propre.
class _Carte extends StatelessWidget {
  const _Carte({required this.lignes, super.key});

  final List<Widget> lignes;

  @override
  Widget build(BuildContext context) => AppCard(
    marge: AppSpacing.lg,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: lignes,
    ),
  );
}

/// Les actions d'une etape, dans le flux, 16 sous leur objet (contrat A) :
/// groupees au bord de fin, la sortie avant la poursuite (contrat B), comme
/// `EtatSysteme` (contrat B, seule disposition depuis HU-1) : la meme
/// `RangeeActions`, empilee a largeur egale quand elle ne tient pas.
class _Actions extends StatelessWidget {
  const _Actions({required this.principale, this.secondaire});

  final Widget principale;
  final Widget? secondaire;

  @override
  Widget build(BuildContext context) => RangeeActions(
    children: <Widget>[if (secondaire case final Widget s) s, principale],
  );
}

/// La colonne bornee a la largeur de dialogue (contrat D) : pleine largeur
/// sur telephone, jamais etiree sur bureau. Centree sous la rangee d'etape ;
/// au bord de debut sous le titre d'un `PageShell`, pour que le contenu parte
/// du meme bord que le titre (EA-6c).
class _Colonne extends StatelessWidget {
  const _Colonne({required this.child, this.auBordDeDebut = false});

  final Widget child;
  final bool auBordDeDebut;

  @override
  Widget build(BuildContext context) {
    final Widget borne = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppPage.largeurDialogue),
      child: child,
    );
    return auBordDeDebut
        ? Align(alignment: AlignmentDirectional.topStart, child: borne)
        : Center(child: borne);
  }
}

/// Prend le focus a son apparition (EA-6c) : le titre de l'etape 2, un echec
/// ou le resultat sont lus d'abord, au clavier comme au lecteur d'ecran.
class _FocusALApparition extends StatefulWidget {
  const _FocusALApparition({required this.child, super.key});

  final Widget child;

  @override
  State<_FocusALApparition> createState() => _FocusALApparitionState();
}

class _FocusALApparitionState extends State<_FocusALApparition> {
  final FocusNode _noeud = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) _noeud.requestFocus();
    });
  }

  @override
  void dispose() {
    _noeud.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Focus(focusNode: _noeud, child: widget.child);
}
