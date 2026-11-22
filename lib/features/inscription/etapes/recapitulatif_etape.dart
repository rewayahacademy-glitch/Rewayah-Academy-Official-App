import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/candidature/port_inscription_candidat.dart';
import '../../../core/candidature/port_ma_candidature.dart'
    show HorsLigneCandidature;
import '../../../core/candidature/port_nom_latin.dart';
import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/permission_insuffisante.dart';
import '../../../core/domain/enums.dart';
import '../../../core/dossier/etat_dossier.dart';
import '../../../core/dossier/service_dossier.dart';
import '../../../core/i18n/isolat_bidi.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/identite/nom_propre.dart';
import '../../../core/preferences/preferences_locales.dart';
import '../../../core/recrutement/port_invitations_comptable.dart';
import '../../../core/recrutement/port_invitations_enseignant.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/router/routes.dart';
import '../../../core/session/deconnexion.dart';
import '../../../core/session/session_controleur.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/champ_etiquete.dart';
import '../../../core/widgets/choice_card_group.dart';
import '../../../core/widgets/groupe_reglages.dart';
import '../../../core/widgets/lien_fleche.dart';
import '../../consentements/texte_observation.dart' show CaseAccordTexte;
import '../../juridique/juridique_pages.dart' show ligneVersionJuridique;
import '../../juridique/textes_juridiques.dart';
import '../brouillon_inscription.dart';
import '../brouillon_persistant.dart' show oublierBrouillonInscription;
import '../code_comptable_retenu.dart';
import '../inscription_page.dart';
import '../invitation_en_cours.dart';
import '../questionnaire/coquille_onboarding.dart';
import '../questionnaire/questionnaire_inscription.dart';

/// `/inscription/recapitulatif` : les reponses, un « Modifier » par ligne, et
/// la creation du compte.
///
/// Double soumission bloquee (drapeau pose avant tout `await`). Impasse apres
/// `refreshSession` corrigee : une fois le profil cree, une nouvelle tentative
/// ne rappelle que le rafraichissement (la creation refuserait un doublon), et
/// la page part d'elle-meme vers `/attente` (`/comptable` pour le comptable
/// invite, lot F2), le routeur redirigeant selon la porte ; si la porte reste `inscription`, on revient ici avec un message et
/// deux issues (reessayer, se deconnecter).
///
/// **Candidat enseignant (CAND-04), avec ou sans code d'invitation.** Le meme
/// recapitulatif ajoute le telephone, le choix de la langue de l'application
/// (deux cartes, la langue active est deja retenue) et la case de la politique
/// de confidentialite ; la creation passe par `inscrire_candidat`
/// (`PortInscriptionCandidat`). Le serveur y repond de la meme facon au succes
/// et au depassement du plafond horaire (CAND-F03) : l'ecran ne les distingue
/// donc pas, il relit la session et laisse le routeur dire si le compte
/// existe. Il ne dit jamais qu'une adresse ou un telephone est deja connu.
/// (Porte de la PR 50 par CANDIDATS-FLUX, 06/11/2026.)
class RecapitulatifEtape extends ConsumerStatefulWidget {
  /// Cree l'etape.
  const RecapitulatifEtape({super.key});

  /// ONBOARDING-PRAXIS : la cle de l'ecran « Vous, le tuteur du compte » (ou
  /// « Votre nom de famille »).
  static const Key cleVous = ValueKey<String>('inscription-vous');

  /// ONBOARDING-PRAXIS : la cle de la fin (« Votre demande est en cours »).
  static const Key cleFin = ValueKey<String>('inscription-fin');

  @override
  ConsumerState<RecapitulatifEtape> createState() => _RecapitulatifEtapeState();
}

class _RecapitulatifEtapeState extends ConsumerState<RecapitulatifEtape> {
  static const String _route = Routes.inscriptionRecapitulatif;

  final FocusNode _focusCase = FocusNode();

  /// Les reponses du recapitulatif : quand le serveur refuse un champ, la page
  /// les ramene a l'ecran, avec leurs « Modifier ».
  final GlobalKey _cleLignes = GlobalKey();

  bool _envoi = false;
  String? _erreur;

  /// Le filet de [_actualiserPuisAller], annule a la fermeture.
  Timer? _filet;

  /// Candidat : l'inscription sans code n'est pas (ou plus) ouverte. Aucun
  /// bouton plein : il ne pourrait pas aboutir ; un lien mene au code.
  bool _fermee = false;

  /// Candidat : la case de confidentialite manque a la derniere tentative.
  bool _caseManquante = false;

  /// Candidat : la derniere tentative a echoue sans rien creer de sur ; le
  /// bouton dit « Reessayer ».
  bool _reessayer = false;

  Future<void> _creer() async {
    if (_envoi) {
      return;
    }
    final BrouillonInscription brouillon = ref.read(
      brouillonInscriptionProvider,
    );
    final UsageInscription? usage = brouillon.usage;
    if (usage == null) {
      return;
    }
    final QuestionnaireInscription questionnaire = ref.read(
      questionnaireInscriptionProvider,
    );
    if (brouillon.titulaire &&
        !brouillon.profilCree &&
        !questionnaire.complet) {
      context.go(Routes.commencer);
      return;
    }
    if (usage == UsageInscription.comptable) {
      await _creerComptable(brouillon);
      return;
    }
    // CAND-04 : l'enseignant est un candidat, avec ou sans code d'invitation.
    if (usage == UsageInscription.enseignant) {
      await _creerCandidat(brouillon);
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    // RACCORDEMENT-1016 (D) : le code verifie par le candidat enseignant est
    // consomme par le serveur avec la creation du profil, dans la meme
    // transaction. Il ne sert qu'a l'enseignant.
    final String? codeInvitation = usage.role == AppRole.teacher
        ? ref.read(codeInvitationRetenuProvider)
        : null;
    try {
      if (!brouillon.profilCree) {
        await ref
            .read(serviceDossierProvider)
            .creerProfil(
              role: usage.role,
              prenom: brouillon.prenom,
              nom: brouillon.nom,
              genre: brouillon.genre,
              codeInvitation: codeInvitation,
              usage: switch (usage) {
                UsageInscription.moi => UsageTitulaire.moi,
                UsageInscription.famille => UsageTitulaire.famille,
                UsageInscription.enseignant ||
                UsageInscription.comptable => null,
              },
              suitDesCours: brouillon.titulaire
                  ? questionnaire.titulaireApprend
                  : usage == UsageInscription.moi ||
                        brouillon.parentSuitDesCours == true,
              // Admission, lot B : les apprenants du questionnaire partent
              // avec la demande, dans la meme transaction.
              apprenants: brouillon.titulaire
                  ? questionnaire.apprenantsPourServeur()
                  : null,
              source: brouillon.titulaire
                  ? questionnaire.sourcePourServeur
                  : null,
              fuseau: brouillon.titulaire ? questionnaire.fuseau : null,
            );
        ref.read(brouillonInscriptionProvider.notifier).noterProfilCree();
        // La demande est partie : les reponses quitteront l'appareil a
        // l'arrivee sur `/attente` ([DepartDemande]). ONBOARDING-PRAXIS : le
        // titulaire voit d'abord la fin (« Votre demande est en cours ») ; le
        // depart commence a « Suivre ma demande ».
        if (!brouillon.titulaire) {
          ref.read(departDemandeProvider.notifier).commencer();
        }
        ref.read(codeInvitationRetenuProvider.notifier).oublier();
        // I1 : le profil existe, l'invitation n'est plus en cours.
        oublierInvitationEnCours();
      }
    } on InvitationNonConsommee {
      // Aucun profil n'a ete cree : le code est oublie, le candidat en
      // demande un nouveau (K-59 : ce qui manque, pourquoi, quoi faire).
      ref.read(codeInvitationRetenuProvider.notifier).oublier();
      oublierInvitationEnCours();
      _echec(t.inscription.erreurInvitation);
      return;
    } on Object {
      _echec(t.inscription.erreur);
      return;
    }
    if (brouillon.titulaire) {
      if (mounted) setState(() => _envoi = false);
      return;
    }
    ref.read(departDemandeProvider.notifier).commencer();
    await _actualiserPuisAller(Routes.attente);
  }

  /// ONBOARDING-PRAXIS : « Suivre ma demande », depuis la fin.
  Future<void> _suivreDemande() async {
    if (_envoi) return;
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    ref.read(departDemandeProvider.notifier).commencer();
    await _actualiserPuisAller(Routes.attente);
  }

  /// Lot F2 : l'inscription du comptable invite, par
  /// `inscrire_comptable_invite` a la place de `creer_profil_inscription`.
  /// Le serveur consomme le code avec la creation du profil, actif d'emblee :
  /// l'arrivee se fait sur `/comptable`.
  Future<void> _creerComptable(BrouillonInscription brouillon) async {
    final PortInscriptionComptable? port = ref.read(
      portInscriptionComptableProvider,
    );
    final String? code = ref.read(codeComptableRetenuProvider);
    if (!brouillon.profilCree && (port == null || code == null)) {
      context.go(Routes.inscriptionInvitationComptable);
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    if (!brouillon.profilCree) {
      final ResultatInscriptionComptable resultat;
      try {
        resultat = await port!.inscrire(
          code: code!,
          prenom: brouillon.prenom,
          nom: brouillon.nom,
          genre: brouillon.genre?.valeurSql,
        );
      } on Object {
        _echec(t.inscription.erreur);
        return;
      }
      if (resultat != ResultatInscriptionComptable.consommee) {
        // Aucun profil n'a ete cree : le code est oublie (K-59).
        ref.read(codeComptableRetenuProvider.notifier).oublier();
        _echec(t.inscription.erreurInvitation);
        return;
      }
      ref.read(brouillonInscriptionProvider.notifier).noterProfilCree();
      ref.read(codeComptableRetenuProvider.notifier).oublier();
    }
    await _actualiserPuisAller(Routes.comptable);
  }

  /// CAND-04 : l'inscription du candidat enseignant, par `inscrire_candidat`.
  ///
  /// Deux portes, un compte : le code d'invitation retenu, ou « Deposer ma
  /// candidature » (sans code, seulement quand le serveur l'ouvre). Ni l'un ni
  /// l'autre : le champ du code, comme avant. La case de confidentialite est
  /// exigee ici, a l'ecran, et le serveur la revérifie a la version attendue.
  Future<void> _creerCandidat(BrouillonInscription brouillon) async {
    final String? code = ref.read(codeInvitationRetenuProvider);
    if (code == null && !brouillon.sansCode) {
      context.go(Routes.inscriptionInvitation);
      return;
    }
    final Genre? genre = brouillon.genre;
    final String? telephone = brouillon.telephone;
    if (genre == null || telephone == null || !brouillon.identiteComplete) {
      context.go(brouillon.premiereEtapeManquante);
      return;
    }
    if (!brouillon.confidentialiteAcceptee) {
      setState(() => _caseManquante = true);
      _focusCase.requestFocus();
      return;
    }
    final PortInscriptionCandidat? port = ref.read(
      portInscriptionCandidatProvider,
    );
    if (port == null) {
      _echec(t.inscription.candidat.indisponible);
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
      _fermee = false;
      _caseManquante = false;
    });
    // La version que la case accepte est celle de ce texte, compile dans
    // l'application. Si le serveur en attend une autre, on ne l'envoie pas
    // (le serveur la refuserait) et on le dit tout de suite. Une lecture qui
    // echoue ne bloque rien : le serveur reste juge a l'envoi.
    ref.invalidate(ouvertureInscriptionCandidatProvider);
    final OuvertureInscriptionCandidat? ouverture = await ref.read(
      ouvertureInscriptionCandidatProvider.future,
    );
    final String? attendue = ouverture?.versionConfidentialite;
    if (!mounted) {
      return;
    }
    if (attendue != null && attendue != VersionsJuridiques.version) {
      _echec(t.inscription.candidat.confidentialitePerimee, reessayer: false);
      return;
    }
    final ResultatInscriptionCandidat resultat;
    try {
      resultat = await port.inscrire(
        code: code,
        prenom: brouillon.prenom,
        nom: brouillon.nom,
        genre: genre.valeurSql,
        telephone: telephone,
        // La langue de l'ecran, jamais deduite d'ailleurs : fr, ar ou en
        // (l'anglais depuis la migration 20261125750000, CANDIDATURE-UX).
        langue: LocaleSettings.currentLocale.languageCode,
        // La version du texte que la case affiche et que la personne peut lire.
        versionConfidentialite: VersionsJuridiques.version,
      );
    } on PermissionInsuffisante {
      // Une session qui a deja un profil : il n'y a rien a creer, la suite est
      // le portail. Si le routeur renvoie ici, le message le dit.
      ref.read(brouillonInscriptionProvider.notifier).noterInscriptionEnvoyee();
      await _actualiserPuisAller(
        Routes.attente,
        echec: t.inscription.candidat.nonConfirmee,
      );
      return;
    } on CapaciteIndisponible {
      // Le lot serveur CAND-L3 n'est pas encore verse. L'invite, lui, ne doit
      // pas etre bloque : son code passe par l'ancien chemin (profil cree avec
      // le code), sans telephone ni langue. Sans code, il n'y a rien d'autre.
      if (code != null) {
        await _creerInviteSansLot(brouillon, code);
        return;
      }
      _echec(t.inscription.candidat.indisponible, reessayer: false);
      return;
    } on HorsLigneCandidature {
      // D5 : ce qui a ete envoye est non confirme.
      _echec(t.inscription.candidat.nonConfirmee);
      return;
    } on Object {
      _echec(t.inscription.candidat.creationEchec);
      return;
    }
    if (!mounted) {
      return;
    }
    switch (resultat) {
      case InscriptionAcceptee():
        // Aucun signe de plus : au-dela du plafond horaire, le serveur rend
        // exactement cette reponse sans rien creer (CAND-F03). Seule la
        // relecture de la session dit si le compte existe.
        ref
            .read(brouillonInscriptionProvider.notifier)
            .noterInscriptionEnvoyee();
        await _confirmerNomLatin(brouillon);
        // Le code reste retenu tant que la session n'a pas confirme le compte :
        // si la relecture echoue, « Reessayer » rejoue l'envoi avec ce code
        // (un compte deja cree repond 42501, donc la suite) au lieu de renvoyer
        // la personne au champ du code. Il est oublie des que la session est lue.
        await _actualiserPuisAller(
          Routes.attente,
          echec: t.inscription.candidat.nonConfirmee,
          apres: () {
            ref.read(codeInvitationRetenuProvider.notifier).oublier();
            // I1 : le profil existe, l'invitation n'est plus en cours.
            oublierInvitationEnCours();
          },
        );
      case InscriptionFermee():
        setState(() {
          _envoi = false;
          _fermee = true;
          _erreur = t.inscription.candidat.nonOuverte;
        });
      case InscriptionCourrielNonConfirme():
        _echec(t.inscription.candidat.courrielAConfirmer);
      case InscriptionCodeInconnu() ||
          InscriptionCodeDejaUtilise() ||
          InscriptionCodeExpire():
        // Aucun compte n'a ete cree : le code est oublie, le candidat en
        // demande un nouveau (K-59 : ce qui manque, pourquoi, quoi faire).
        ref.read(codeInvitationRetenuProvider.notifier).oublier();
        oublierInvitationEnCours();
        _echec(t.inscription.erreurInvitation, reessayer: false);
      case InscriptionInvalide(:final List<String> champs):
        _echec(
          t.inscription.candidat.aCorriger(champs: _nomsDesChamps(champs)),
          reessayer: false,
        );
        WidgetsBinding.instance.addPostFrameCallback((Duration _) {
          final BuildContext? lignes = _cleLignes.currentContext;
          if (mounted && lignes != null && lignes.mounted) {
            Scrollable.ensureVisible(lignes);
          }
        });
      case InscriptionConfidentialiteRequise():
        // L'ecran a deja exige la case : ce refus n'est pas un texte perime.
        _echec(t.inscription.candidat.creationEchec, reessayer: false);
      case InscriptionConfidentialitePerimee():
        _echec(t.inscription.candidat.confidentialitePerimee, reessayer: false);
      case InscriptionConfidentialiteIndisponible():
        _echec(t.inscription.candidat.indisponible, reessayer: false);
    }
  }

  /// Envoie le nom en lettres latines que la personne a confirme a l'etape
  /// d'identite (decision du directeur du 23/10/2026), une fois la candidature
  /// creee. **Au mieux** : un echec (reseau, plafond horaire sans compte, lot
  /// serveur absent) ne bloque rien ; le nom reste « a confirmer » et la Salle
  /// d'examen le redemande. Le serveur ne translittere jamais : seul le texte
  /// confirme part.
  Future<void> _confirmerNomLatin(BrouillonInscription brouillon) async {
    final String? nomLatin = brouillon.nomLatinAEnvoyer;
    final PortNomLatin? port = ref.read(portNomLatinProvider);
    if (nomLatin == null || port == null) {
      return;
    }
    try {
      await port.confirmer(nomLatin);
    } on Object {
      // Voir ci-dessus : la Salle d'examen le redemandera.
    }
  }

  /// Repli de l'invite tant que `inscrire_candidat` n'est pas sur le serveur :
  /// le chemin d'avant (`creer_profil_inscription` avec le code d'invitation).
  Future<void> _creerInviteSansLot(
    BrouillonInscription brouillon,
    String code,
  ) async {
    try {
      if (!brouillon.profilCree) {
        await ref
            .read(serviceDossierProvider)
            .creerProfil(
              role: AppRole.teacher,
              prenom: brouillon.prenom,
              nom: brouillon.nom,
              genre: brouillon.genre,
              codeInvitation: code,
              suitDesCours: false,
            );
        ref.read(brouillonInscriptionProvider.notifier).noterProfilCree();
        ref.read(codeInvitationRetenuProvider.notifier).oublier();
        oublierInvitationEnCours();
      }
    } on InvitationNonConsommee {
      ref.read(codeInvitationRetenuProvider.notifier).oublier();
      oublierInvitationEnCours();
      _echec(t.inscription.erreurInvitation, reessayer: false);
      return;
    } on Object {
      _echec(t.inscription.erreur);
      return;
    }
    await _actualiserPuisAller(Routes.attente);
  }

  /// Les champs refuses par le serveur, nommes comme a l'ecran.
  String _nomsDesChamps(List<String> champs) {
    final List<String> noms = <String>[
      for (final String c in champs)
        switch (c) {
          'prenom' => t.inscription.prenom,
          'nom' => t.inscription.nom,
          'genre' => t.inscription.recap.genre,
          'telephone' => t.inscription.recap.telephone,
          'langue' => t.inscription.recap.langue,
          _ => c,
        },
    ];
    return noms.join(
      LocaleSettings.currentLocale == AppLocale.ar ? '، ' : ', ',
    );
  }

  void _echec(String message, {bool reessayer = true}) {
    if (mounted) {
      setState(() {
        _envoi = false;
        _erreur = message;
        _reessayer = reessayer;
      });
    }
  }

  /// Relit la session puis va a [destination] ; le routeur decide, selon la
  /// porte, si la personne y entre. [echec] remplace le message d'une session
  /// qui ne se rafraichit pas (le candidat ne sait pas encore si son compte
  /// existe, le tuteur oui) ; [apres] s'execute une fois la session lue.
  Future<void> _actualiserPuisAller(
    String destination, {
    String? echec,
    VoidCallback? apres,
  }) async {
    // Lu avant l'attente : l'ecran peut etre remonte pendant l'actualisation,
    // le drapeau doit retomber quand meme en cas d'echec.
    final DepartDemande depart = ref.read(departDemandeProvider.notifier);
    try {
      // Le role et le foyer sont injectes dans le jeton par le hook de la base :
      // le jeton emis avant la creation ne les porte pas encore.
      await ref.read(sourceSessionProvider).rafraichir();
    } on Object {
      depart.finir();
      _echec(echec ?? t.inscription.erreurActualisation);
      return;
    }
    if (mounted) {
      apres?.call();
      context.go(destination);
      // Filet : si l'ecran est encore la bien apres (aucune navigation), le
      // bouton revient au lieu de tourner sans fin.
      _filet?.cancel();
      _filet = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          depart.finir();
          setState(() => _envoi = false);
        }
      });
    }
  }

  // ---------------------------------------------------------------------------
  // ONBOARDING-PRAXIS : la demande du titulaire, apres la connexion
  // ---------------------------------------------------------------------------

  final TextEditingController _prenomTitulaire = TextEditingController();
  final TextEditingController _nomTitulaire = TextEditingController();
  Genre? _genreTitulaire;
  bool _tenteTitulaire = false;

  String? _erreurNom(String saisie, String enLettres) {
    if (!_tenteTitulaire) return null;
    if (saisie.trim().isEmpty) return t.inscription.champRequis;
    return nomPropreValide(saisie) ? null : enLettres;
  }

  void _envoyerTitulaire(ApprenantQuestionnaire? apprenant) {
    final String prenom = apprenant?.prenom ?? _prenomTitulaire.text;
    final Genre? genre = apprenant?.genre ?? _genreTitulaire;
    if (!nomPropreValide(prenom) ||
        !nomPropreValide(_nomTitulaire.text) ||
        genre == null) {
      setState(() => _tenteTitulaire = true);
      return;
    }
    ref
        .read(brouillonInscriptionProvider.notifier)
        .saisirIdentite(prenom: prenom, nom: _nomTitulaire.text);
    ref.read(brouillonInscriptionProvider.notifier).choisirGenre(genre);
    unawaited(_creer());
  }

  /// Le seul bouton plein de l'ecran du titulaire (les trois etats, la
  /// demande, la reprise et la fin, s'excluent) : coupe pendant l'envoi deja
  /// parti, jamais grise autrement.
  ActionPrincipale _boutonDemande({
    required Key cle,
    required String libelle,
    required VoidCallback onPress,
    required bool enCours,
  }) => ActionPrincipale(
    key: cle,
    libelle: libelle,
    onPress: enCours ? null : onPress,
    enCours: enCours,
    affirmee: true,
  );

  Widget _vueTitulaire(
    BuildContext context, {
    required BrouillonInscription brouillon,
    required QuestionnaireInscription questionnaire,
    required bool sansQuestionnaire,
    required bool enCours,
    required String? erreur,
  }) {
    final o = t.onboarding;
    final TextTheme textes = Theme.of(context).textTheme;
    void deconnecter() => unawaited(
      seDeconnecter(context, ref).then((bool sortie) {
        if (sortie) oublierBrouillonInscription();
      }),
    );
    final Widget sortie = LienFleche(
      key: const Key('inscription-deconnexion'),
      libelle: t.inscription.seDeconnecter,
      fleche: false,
      onPress: deconnecter,
    );
    final Widget? ligneErreur = erreur == null
        ? null
        : ErreurEtape(message: erreur);
    // La demande est partie : la fin.
    if (brouillon.profilCree) {
      final f = o.fin;
      final int enfants = questionnaire.enfants.length;
      return KeyedSubtree(
        key: RecapitulatifEtape.cleFin,
        child: CoquilleOnboarding(
          chapitre: Chapitre.demande,
          remplissage: const <double>[1, 1, 1, 4 / 5],
          grand: true,
          expression: ExpressionPraxis.joie,
          phrase: f.dit,
          titre: f.titre,
          corps: <Widget>[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(f.maintenant, style: textes.titleMedium),
                  Ecart.vSm,
                  Text(f.un, style: textes.bodyMedium),
                  Ecart.vXs,
                  Text(
                    questionnaire.apprenants.length > 1
                        ? f.deuxPlusieurs
                        : f.deux,
                    style: textes.bodyMedium,
                  ),
                  Ecart.vXs,
                  Text(f.trois, style: textes.bodyMedium),
                  // Les freres et soeurs ne sont jamais dans la meme classe
                  // (directeur, 22/11/2026) : dit comme un avantage.
                  if (enfants > 1) ...<Widget>[
                    Ecart.vSm,
                    Text(
                      f.fratrie,
                      key: const Key('inscription-fin-fratrie'),
                      style: textes.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            if (ligneErreur != null) ...<Widget>[Ecart.vMd, ligneErreur],
          ],
          action: _boutonDemande(
            cle: const Key('inscription-suivre'),
            libelle: f.suivre,
            onPress: () => unawaited(_suivreDemande()),
            enCours: enCours,
          ),
        ),
      );
    }
    // Les reponses ne sont plus sur cet appareil : reprendre les questions.
    if (sansQuestionnaire) {
      return CoquilleOnboarding(
        chapitre: Chapitre.demande,
        expression: ExpressionPraxis.reflexion,
        phrase: t.inscription.questionnaire.aucuneReponse,
        titre: t.inscription.questionnaire.acces.absentesTitre,
        corps: const <Widget>[],
        action: _boutonDemande(
          cle: const Key('inscription-reprendre'),
          libelle: t.commun.continuer,
          onPress: () => context.go(Routes.commencer),
          enCours: false,
        ),
        liens: <Widget>[sortie],
      );
    }
    final v = o.vous;
    final ApprenantQuestionnaire? l0 = questionnaire.titulaire;
    return KeyedSubtree(
      key: RecapitulatifEtape.cleVous,
      child: CoquilleOnboarding(
        chapitre: Chapitre.demande,
        remplissage: const <double>[1, 1, 1, 3 / 5],
        expression: ExpressionPraxis.reflexion,
        phrase: l0 != null ? v.ditMoi(prenom: l0.prenom) : v.dit,
        titre: l0 != null ? v.titreMoi : v.titre,
        sousTitre: l0 != null ? null : v.sous,
        corps: <Widget>[
          AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // L'adulte (ou le parent qui apprend) a deja dit son prenom :
                // il n'est jamais redemande.
                if (l0 == null) ...<Widget>[
                  ChampEtiquete(
                    libelle: v.prenom,
                    obligatoire: true,
                    cleChamp: const Key('inscription-prenom'),
                    controller: _prenomTitulaire,
                    textCapitalization: TextCapitalization.words,
                    actionClavier: TextInputAction.next,
                    remplissage: const <String>[AutofillHints.givenName],
                    erreur: _erreurNom(
                      _prenomTitulaire.text,
                      t.inscription.nomEnLettresPrenom,
                    ),
                    onChanged: (String _) => setState(() {}),
                  ),
                  Ecart.vLg,
                ],
                ChampEtiquete(
                  libelle: v.nom,
                  obligatoire: true,
                  cleChamp: const Key('inscription-nom'),
                  controller: _nomTitulaire,
                  textCapitalization: TextCapitalization.words,
                  actionClavier: TextInputAction.done,
                  remplissage: const <String>[AutofillHints.familyName],
                  erreur: _erreurNom(
                    _nomTitulaire.text,
                    t.inscription.nomEnLettresNom,
                  ),
                  onChanged: (String _) => setState(() {}),
                  onSubmitted: (String _) => _envoyerTitulaire(l0),
                ),
                if (l0 == null) ...<Widget>[
                  Ecart.vLg,
                  Text(v.vousEtes, style: textes.titleSmall),
                  Ecart.vSm,
                  ChoiceCardGroup(
                    key: const Key('inscription-genre'),
                    autoriserSaisieLibre: false,
                    compacte: true,
                    valeurInitiale: _genreTitulaire == null
                        ? null
                        : ReponseChoix(
                            valeurs: <String>{_genreTitulaire!.name},
                          ),
                    options: <OptionChoix>[
                      OptionChoix(
                        cle: const Key('inscription-genre-homme'),
                        valeur: Genre.homme.name,
                        libelle: o.genre.homme,
                        // K-58 : le choix s'explique (a quoi sert la reponse).
                        description: t.inscription.genreHommeExplication,
                      ),
                      OptionChoix(
                        cle: const Key('inscription-genre-femme'),
                        valeur: Genre.femme.name,
                        libelle: o.genre.femme,
                        // K-58 : le choix s'explique (a quoi sert la reponse).
                        description: t.inscription.genreFemmeExplication,
                      ),
                    ],
                    onChange: (ReponseChoix r) {
                      if (r.valeurs.isEmpty) return;
                      setState(
                        () => _genreTitulaire = Genre.values.byName(
                          r.valeurs.first,
                        ),
                      );
                    },
                  ),
                  if (_tenteTitulaire && _genreTitulaire == null) ...<Widget>[
                    Ecart.vSm,
                    ErreurEtape(message: t.inscription.champRequis),
                  ],
                ],
              ],
            ),
          ),
          if (ligneErreur != null) ...<Widget>[Ecart.vMd, ligneErreur],
        ],
        action: _boutonDemande(
          cle: const Key('inscription-envoyer'),
          libelle: v.envoyer,
          onPress: () => _envoyerTitulaire(l0),
          enCours: enCours,
        ),
        liens: <Widget>[sortie],
      ),
    );
  }

  @override
  void dispose() {
    _filet?.cancel();
    _prenomTitulaire.dispose();
    _nomTitulaire.dispose();
    _focusCase.dispose();
    super.dispose();
  }

  /// Une question du questionnaire s'ouvre telle quelle (il revient ici une
  /// fois tout repondu) ; une etape de l'inscription, avec « Modifier ».
  void _modifier(String route) => context.go(
    route.startsWith(Routes.commencer)
        ? route
        : Uri(
            path: route,
            queryParameters: <String, String>{parametreModifier: '1'},
          ).toString(),
  );

  /// Le telephone tel que la personne le relit : « +33 612345678 », isole pour
  /// rester dans le bon sens en arabe.
  String _telephoneAffiche(BrouillonInscription brouillon) {
    final String? international = brouillon.telephone;
    final String? code = brouillon.indicatif;
    if (international == null || code == null) {
      return '';
    }
    return '\u2066+$code ${international.substring(code.length + 1)}\u2069';
  }

  @override
  Widget build(BuildContext context) {
    final BrouillonInscription brouillon = ref.watch(
      brouillonInscriptionProvider,
    );
    exigerEtapesPrecedentes(context, brouillon, _route);
    final QuestionnaireInscription questionnaire = ref.watch(
      questionnaireInscriptionProvider,
    );
    // Admission, lot B : sans les reponses du questionnaire (un autre
    // appareil, une memoire effacee), on reprend les premieres questions.
    final bool sansQuestionnaire =
        brouillon.titulaire && !brouillon.profilCree && !questionnaire.complet;
    // INSCRIPTION-3 : le profil cree, la demande part ([DepartDemande]) ;
    // l'ecran ne propose plus rien et ne dit plus « Reessayer », meme
    // remonte par l'actualisation de la session (lu sur la pile locale, 229 a
    // 302 ms apres l'envoi).
    final bool depart =
        brouillon.profilCree && ref.watch(departDemandeProvider);
    final bool enCours = _envoi || depart;
    // CAND-04 : le candidat peut changer la langue de l'application ici meme :
    // la page se reconstruit quand la langue change, pour que chaque texte
    // suive.
    TranslationProvider.of(context);
    final bool candidat = brouillon.usage == UsageInscription.enseignant;
    // Le candidat ne cree rien hors ligne : le bouton n'est pas rendu et une
    // phrase dit quand ce sera possible (jamais un bouton grise).
    final bool horsLigne =
        candidat && (ref.watch(horsLigneProvider).value ?? false);
    final String? erreur =
        _erreur ??
        (candidat
            ? (brouillon.inscriptionEnvoyee && !enCours
                  ? t.inscription.candidat.creationEchec
                  : null)
            : (brouillon.profilCree && !enCours
                  ? t.inscription.erreurActualisation
                  : null));

    // ONBOARDING-PRAXIS (directeur, 22/11/2026) : le titulaire a tout dit dans
    // le questionnaire ; ici, seulement son nom (et, pour le tuteur qui ne
    // suit pas de cours, son prenom et son genre), puis la fin.
    if (brouillon.titulaire) {
      return _vueTitulaire(
        context,
        brouillon: brouillon,
        questionnaire: questionnaire,
        sansQuestionnaire: sansQuestionnaire,
        enCours: enCours,
        erreur: _erreur,
      );
    }

    // Le profil deja cree ne se modifie plus d'ici : « Modifier » n'est pas
    // rendu (jamais grise, BOUTONS-GRISES-1) ; l'erreur d'actualisation et
    // « Reessayer » disent la suite. Pendant l'envoi, il ne repart pas. Le
    // candidat, lui, n'a rien de cree tant que la session n'a pas de profil :
    // il peut corriger.
    final bool figee = !candidat && brouillon.profilCree;
    Widget? modifier(String route, String cle) => figee
        ? null
        : ActionPrincipale(
            key: Key(cle),
            libelle: t.inscription.modifier,
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
            onPress: enCours ? null : () => _modifier(route),
          );

    final bool refaire = candidat
        ? (_reessayer || brouillon.inscriptionEnvoyee)
        : brouillon.profilCree;
    final Widget lignes = KeyedSubtree(
      key: _cleLignes,
      child: GroupeReglages(
        lignes: <LigneRubrique>[
          LigneRubrique(
            icone: brouillon.usage == UsageInscription.famille
                ? AppIcons.foyer
                : AppIcons.profil,
            libelle: t.inscription.recap.usage,
            legende: switch (brouillon.usage) {
              UsageInscription.moi => t.inscription.usage.moiTitre,
              UsageInscription.famille => t.inscription.usage.familleTitre,
              UsageInscription.enseignant => t.inscription.recap.enseignant,
              UsageInscription.comptable => t.inscription.recap.comptable,
              null => '',
            },
            controle: modifier(
              Routes.inscriptionUsage,
              'inscription-modifier-usage',
            ),
          ),
          LigneRubrique(
            icone: AppIcons.profil,
            libelle: t.inscription.recap.identite,
            legende: '${brouillon.prenom} ${brouillon.nom}',
            controle: modifier(
              Routes.inscriptionIdentite,
              'inscription-modifier-identite',
            ),
          ),
          if (candidat && brouillon.nomLatinAEnvoyer != null)
            LigneRubrique(
              icone: AppIcons.profil,
              libelle: t.inscription.nomLatin.libelle,
              legende: isolerSens(brouillon.nomLatinAEnvoyer!),
              controle: modifier(
                Routes.inscriptionIdentite,
                'inscription-modifier-nom-latin',
              ),
            ),
          LigneRubrique(
            icone: AppIcons.profil,
            libelle: t.inscription.recap.genre,
            legende: switch (brouillon.genre) {
              Genre.femme => t.inscription.genreFemme,
              Genre.homme => t.inscription.genreHomme,
              null => '',
            },
            controle: modifier(
              Routes.inscriptionGenre,
              'inscription-modifier-genre',
            ),
          ),
          if (candidat)
            LigneRubrique(
              icone: AppIcons.appareil,
              libelle: t.inscription.recap.telephone,
              legende: _telephoneAffiche(brouillon),
              controle: modifier(
                Routes.inscriptionTelephone,
                'inscription-modifier-telephone',
              ),
            ),
        ],
      ),
    );
    return CoquilleEtape(
      route: _route,
      question: t.inscription.recapitulatif,
      // INSCRIPTION-3 : pendant l'envoi, l'etiquette ne change pas ; le
      // profil cree, elle disait « Reessayer » avant meme le depart, alors
      // que rien n'avait echoue.
      libelleAction: candidat && (_fermee || horsLigne)
          ? null
          : candidat
          ? (refaire && !enCours
                ? t.inscription.reessayer
                : t.inscription.candidat.envoyer)
          : brouillon.profilCree && !enCours
          ? t.inscription.reessayer
          : t.inscription.creer,
      onAction: brouillon.usage == null ? null : _creer,
      complement: candidat && _fermee
          ? Center(
              child: LienFleche(
                key: const Key('inscription-recap-code'),
                libelle: t.inscription.usage.enseignant,
                onPress: () => context.go(Routes.inscriptionInvitation),
              ),
            )
          : null,
      onRetour: enCours || figee
          ? null
          : candidat
          ? reculerDepuis(context, brouillon, _route)
          : () => context.go(Routes.inscriptionGenre),
      enCours: enCours,
      souscription: horsLigne
          ? const _NoteHorsLigne()
          : (erreur == null ? null : ErreurEtape(message: erreur)),
      enfant: candidat
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                lignes,
                Ecart.vLg,
                Text(
                  t.inscription.candidat.ensuite,
                  key: const Key('inscription-recap-ensuite'),
                  style: AppPalette.of(context).inkMuted.applyTo(
                    Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
                  ),
                ),
                Ecart.vXxl,
                _ChoixLangue(enCours: enCours),
                Ecart.vXxl,
                _Confidentialite(
                  cochee: brouillon.confidentialiteAcceptee,
                  manquante:
                      _caseManquante && !brouillon.confidentialiteAcceptee,
                  focusNode: _focusCase,
                  enCours: enCours,
                  onChanged: (bool v) {
                    ref
                        .read(brouillonInscriptionProvider.notifier)
                        .accepterConfidentialite(acceptee: v);
                    if (v && _caseManquante) {
                      setState(() => _caseManquante = false);
                    }
                  },
                ),
              ],
            )
          : lignes,
    );
  }
}

/// Le choix de la langue de l'application : une carte par langue chargee dans
/// l'application ([AppLocale.values] : francais, arabe, anglais), la langue
/// active deja retenue (deduite, jamais imposee).
///
/// CANDIDATURE-UX (directeur, 14/11/2026) : le directeur choisit Francais,
/// puis l'interface passe en arabe. Cause : la carte changeait la langue
/// d'affichage seule (`LocaleSettings.setLocale`), sans passer par la
/// preference ; a la creation du compte, la persistance remettait la
/// preference du compte neuf (« Systeme », donc la langue de l'appareil). La
/// carte passe maintenant par la preference ([PreferencesLocalesControleur]) :
/// la langue s'applique tout de suite, et ce choix devient celui du compte a
/// sa creation (`_persisterParCompte`, langue du compte au serveur).
class _ChoixLangue extends ConsumerWidget {
  const _ChoixLangue({required this.enCours});

  final bool enCours;

  /// La cle du groupe de cartes (tests).
  static const Key groupeKey = ValueKey<String>('inscription-langue');

  /// La cle de la carte d'une langue (tests).
  static Key carteKey(String code) =>
      ValueKey<String>('inscription-langue-$code');

  /// La preference qui impose [langue].
  static PreferenceLangue preferencePour(AppLocale langue) => switch (langue) {
    AppLocale.fr => PreferenceLangue.francais,
    AppLocale.ar => PreferenceLangue.arabe,
    AppLocale.en => PreferenceLangue.anglais,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = t.inscription.langue;
    final AppLocale active = LocaleSettings.currentLocale;
    OptionChoix option(AppLocale l) => switch (l) {
      AppLocale.fr => OptionChoix(
        cle: carteKey('fr'),
        valeur: 'fr',
        libelle: r.francais,
        explication: r.francaisExplication,
        exemple: r.francaisExemple,
      ),
      AppLocale.ar => OptionChoix(
        cle: carteKey('ar'),
        valeur: 'ar',
        libelle: r.arabe,
        explication: r.arabeExplication,
        exemple: r.arabeExemple,
      ),
      AppLocale.en => OptionChoix(
        cle: carteKey('en'),
        valeur: 'en',
        libelle: r.anglais,
        explication: r.anglaisExplication,
        exemple: r.anglaisExemple,
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TitreChamp(r.question, style: Theme.of(context).textTheme.titleMedium),
        Ecart.vMd,
        IgnorePointer(
          ignoring: enCours,
          child: ChoiceCardGroup(
            key: groupeKey,
            autoriserSaisieLibre: false,
            valeurInitiale: ReponseChoix(
              valeurs: <String>{active.languageCode},
            ),
            options: <OptionChoix>[
              for (final AppLocale l in AppLocale.values) option(l),
            ],
            onChange: (ReponseChoix reponse) {
              for (final AppLocale l in AppLocale.values) {
                if (reponse.valeurs.contains(l.languageCode) && l != active) {
                  // La preference applique la langue (chargee a la demande
                  // pour l'arabe et l'anglais : l'ecran se reconstruit a son
                  // arrivee) et la garde pour le compte qui va naitre.
                  ref
                      .read(preferencesLocalesProvider.notifier)
                      .langue(preferencePour(l));
                  unawaited(appliquerPreferenceLangue(preferencePour(l)));
                }
              }
            },
          ),
        ),
      ],
    );
  }
}

/// La politique de confidentialite : un lien pour la lire, puis la case, jamais
/// precochee, juste au-dessus du bouton. La version que le serveur recoit est
/// celle du texte que le lien ouvre (`VersionsJuridiques`).
class _Confidentialite extends StatelessWidget {
  const _Confidentialite({
    required this.cochee,
    required this.manquante,
    required this.focusNode,
    required this.enCours,
    required this.onChanged,
  });

  final bool cochee;
  final bool manquante;
  final FocusNode focusNode;
  final bool enCours;
  final ValueChanged<bool> onChanged;

  /// La cle de la case (tests).
  static const Key caseKey = ValueKey<String>('inscription-confidentialite');

  /// La cle du lien vers la politique (tests).
  static const Key lienKey = ValueKey<String>(
    'inscription-confidentialite-lire',
  );

  /// La cle de la ligne qui dit la version du texte (tests).
  static const Key versionKey = ValueKey<String>(
    'inscription-confidentialite-version',
  );

  @override
  Widget build(BuildContext context) {
    final r = t.inscription.confidentialite;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LienFleche(
          key: lienKey,
          libelle: r.lire,
          alignerEnDebut: true,
          onPress: () =>
              GoRouter.of(context).push(TexteJuridique.confidentialite.chemin),
        ),
        // La version que la case accepte, celle que le lien ouvre et celle que
        // le serveur recoit : une seule (`VersionsJuridiques`).
        Text(
          ligneVersionJuridique(),
          key: versionKey,
          textAlign: TextAlign.center,
          style: AppPalette.of(context).inkMuted.applyTo(
            Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
          ),
        ),
        Ecart.vMd,
        CaseAccordTexte(
          key: caseKey,
          libelle: r.kCase,
          cochee: cochee,
          focusNode: focusNode,
          onChanged: enCours ? null : onChanged,
        ),
        if (manquante) ...<Widget>[
          Ecart.vSm,
          Semantics(
            liveRegion: true,
            child: Text(
              r.requise,
              style: AppPalette.of(context).inkAlert.applyTo(
                Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// La phrase d'un bouton qui n'est pas rendu hors ligne : ce n'est pas une
/// erreur, elle dit quand l'action sera possible. Le bandeau de la page dit
/// deja que le reseau manque : elle ne le redit pas.
class _NoteHorsLigne extends StatelessWidget {
  const _NoteHorsLigne();

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      t.inscription.candidat.horsLigne,
      key: const Key('inscription-note-hors-ligne'),
      textAlign: TextAlign.center,
      style: AppPalette.of(context).inkMuted
          .applyTo(Theme.of(context).textTheme.bodyMedium ?? const TextStyle()),
    ),
  );
}
