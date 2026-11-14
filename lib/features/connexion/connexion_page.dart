import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../core/auth/anti_robot.dart';
import '../../core/auth/service_auth.dart';
import '../../core/config/env.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/marque/logo_google.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/source_session.dart'
    show sessionTermineeParLeServeur;
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/controle_anti_robot.dart';
import '../../core/widgets/controle_segmente.dart';
import '../../core/widgets/lien_fleche.dart';
import '../demo/mode_demonstration.dart';
import '../demo/racine_demonstrable.dart';
import '../inscription/invitation_en_cours.dart';
import '../inscription/questionnaire/questionnaire_inscription.dart'
    show questionnaireInscriptionProvider;
import '../juridique/textes_juridiques.dart';
import 'coquille_entree.dart';
import 'feuille_appareil_eleve.dart';
import 'invitation_compte.dart';
import 'lien_ailleurs.dart';
import 'recuperation_page.dart';
import 'saisie_code_courriel.dart';

/// L'environnement compile, lu par un provider pour que les tests le
/// surchargent. La garde reste [environnementAutoriseDemo], la meme que
/// `/demo/*` : ce provider ne fait que lui passer la valeur.
final Provider<String> environnementConnexionProvider = Provider<String>(
  (Ref ref) => Env.environnement,
);

/// Le chemin que prend le bouton principal. Le libelle et l'action sortent de
/// cette seule fonction, pour que le bouton ne mente jamais.
enum CheminConnexion {
  /// Mot de passe de demonstration saisi : connexion sans lien.
  motDePasse,

  /// Adresse fictive de demonstration, sans mot de passe : entree directe.
  demoDirecte,

  /// Tous les autres cas : un lien part par courriel.
  lien,
}

/// Le chemin pour un etat donne du formulaire. Pure, pour etre testee seule.
CheminConnexion cheminConnexion({
  required bool demo,
  required String courriel,
  required String motDePasse,
}) {
  if (!demo) {
    return CheminConnexion.lien;
  }
  if (motDePasse.isNotEmpty) {
    return CheminConnexion.motDePasse;
  }
  if (accesDemoDepuisCourriel(courriel) != null) {
    return CheminConnexion.demoDirecte;
  }
  return CheminConnexion.lien;
}

/// L4 (audit d'entree du 17/10/2026, E1-E2) : deux chemins distincts.
///
/// Le meme lien par courriel cree le compte ou connecte : c'est le serveur
/// qui decide. Mais le visiteur doit savoir lequel il prend. Le mode change
/// le titre, la phrase et le bouton ; en creation, les sorties reservees aux
/// comptes existants (appareil d'un eleve, lien expire) s'effacent.
enum ModeConnexion {
  /// « J'ai deja un compte ».
  connexion,

  /// « Creer un compte ».
  creation,
}

/// Le parametre d'adresse qui ouvre la connexion en mode creation
/// (`/connexion?mode=creer`), depuis le site public par exemple.
const String parametreModeCreation = 'creer';

/// Le mode lu dans l'adresse : creation pour `?mode=creer`, sinon connexion.
ModeConnexion modeDepuisAdresse(Uri adresse) =>
    adresse.queryParameters['mode'] == parametreModeCreation
    ? ModeConnexion.creation
    : ModeConnexion.connexion;

/// `TUT-00` : la connexion.
///
/// Un lien recu par courriel, ou Google. **Aucun mot de passe** en production :
/// ni a creer, ni a retenir, ni a reinitialiser. C'est aussi le seul ecran du
/// produit atteignable sans session.
///
/// L'etat « lien envoye » ne se ferme pas tout seul et ne compte pas a rebours :
/// rien ne se ferme sur minuterie dans ce produit
/// (`docs/archive/2026-09-pre-remise-a-plat/produit/parcours-utilisateurs.md`, regles communes).
///
/// ## Trois poids d'action, une seule bordure
///
/// L'ecran portait trois boutons a filet, dont le plus epais etait le bouton
/// principal **desactive** (3 points, contre 2 aux secondaires). Au premier
/// affichage, champ vide, la page se lisait donc comme trois boutons de meme
/// poids, et l'action a mener ne se distinguait pas des deux autres.
///
/// Elle se lit maintenant en trois rangs (`02-regles-ux.md` section 4) :
/// l'aplat plein pour le lien, le filet pour Google -- **le seul de l'ecran**,
/// et c'est ce qui le rend lisible -- et le texte seul pour l'entree eleve, qui
/// est un parcours different et non une autre facon de faire le meme.
///
/// **Le bouton principal n'est plus inerte au repos.** La fiche demande qu'il
/// ne soit « jamais grise sans raison dite » ; il l'etait, et la raison ne
/// s'affichait nulle part. La verification d'adresse existait deja dans
/// [_envoyerLien] mais ne pouvait jamais s'executer, le bouton etant mort avant
/// d'etre touche : ce chemin etait du code mort. Il parle desormais sous le
/// champ, au moment ou l'on appuie.
class ConnexionPage extends ConsumerStatefulWidget {
  /// Cree l'ecran de connexion.
  const ConnexionPage({
    super.key,
    this.demoAuth,
    this.urlRetour,
    this.mode = ModeConnexion.connexion,
  });

  /// Le chemin propose a l'ouverture ; le visiteur peut en changer.
  final ModeConnexion mode;

  /// Force le mode demonstration, sans lire [demoAuthActiveProvider].
  ///
  /// Reserve aux tests de widget et au Playground. En production, c'est la
  /// compilation qui decide, par `DEMO_AUTH`.
  final bool? demoAuth;

  /// L'URL d'arrivee a examiner, pour les tests ; par defaut [Uri.base].
  ///
  /// Quand le fournisseur ramene l'usager avec une erreur (lien expire, deja
  /// utilise, refuse), la connexion l'envoie a la recuperation avec le motif
  /// au lieu de le laisser sur un formulaire muet (C03 section 9).
  final Uri? urlRetour;

  @override
  ConsumerState<ConnexionPage> createState() => _ConnexionPageState();
}

class _ConnexionPageState extends ConsumerState<ConnexionPage> {
  final TextEditingController _courriel = TextEditingController();
  final TextEditingController _motDePasse = TextEditingController();
  bool _envoi = false;
  bool _envoye = false;
  String? _erreur;
  bool _renvoi = false;
  bool _renvoye = false;
  String? _erreurRenvoi;
  late ModeConnexion _mode = widget.mode;

  /// FN-111 : le lien de connexion a ete ouvert ailleurs que la ou il a ete
  /// demande. Lu une fois, a l'ouverture : l'adresse d'arrivee ne change pas.
  bool _lienAilleurs = false;

  /// INVITATION-COMPTE : l'invitation portee par le lien de l'e-mail, s'il y
  /// en a une ; les inscriptions etant fermees, le serveur cree d'abord le
  /// compte de l'adresse invitee, et seulement elle.
  InvitationDansAdresse? _invitation;

  /// INVITATION-ENSEIGNANT-REPARE (14/11/2026) : sans code dans l'adresse, le
  /// visiteur saisit le sien ici : avant la connexion, aucun autre ecran ne
  /// l'accepte (la route du code est reservee aux comptes connectes).
  final TextEditingController _code = TextEditingController();
  bool _codeOuvert = false;

  /// L'invitation prise en compte : celle de l'adresse, sinon le code saisi
  /// (type equipe : le serveur dit lui-meme enseignant ou comptable).
  InvitationDansAdresse? get _invitationRetenue {
    final InvitationDansAdresse? dansAdresse = _invitation;
    if (dansAdresse != null) return dansAdresse;
    if (_mode != ModeConnexion.creation) return null;
    final String code = _code.text.trim().isNotEmpty
        ? _code.text.trim()
        : (_codeRetenu ?? '');
    if (code.isEmpty) return null;
    return InvitationDansAdresse(type: TypeInvitationCompte.equipe, code: code);
  }

  /// Le code d'un lien d'invitation ouvert plus tot sur cet appareil (retenu
  /// des l'ouverture de l'application, meme si l'adresse a change depuis :
  /// session deja ouverte, retour a la connexion simple).
  String? get _codeRetenu => lireInvitationEnCours()?.code;

  /// La phrase d'un envoi manque. Le lien d'une invitation de foyer dont le
  /// compte n'a pas pu etre cree (code deja utilise, echec de la creation :
  /// l'instance refuse alors l'inscription) dit quoi faire : demander un
  /// renvoi a la personne qui invite (seconde lecture, 07/11/2026).
  String _phraseEchec(Object erreur) {
    final IssueEnvoiLien issue = issueEchecEnvoi(erreur);
    // Une invitation dont l'adresse reste tenue par un compte supprime (la
    // liberation n'a pas abouti) : le serveur refuse l'envoi (`user_banned`).
    if (erreur is AuthException &&
        erreur.code == 'user_banned' &&
        _invitationRetenue != null) {
      return t.connexion.invitationCreationImpossible;
    }
    if (issue == IssueEnvoiLien.inscriptionFermee) {
      final TypeInvitationCompte? type = _invitationRetenue?.type;
      if (type == TypeInvitationCompte.foyer) {
        return t.connexion.invitationFoyer.creationImpossible;
      }
      // Equipe ou candidat : la creation du compte a echoue (code echu, deja
      // utilise, autre adresse) ; on le dit, avec quoi faire (K-59).
      if (type != null) return t.connexion.invitationCreationImpossible;
    }
    return phraseEchecEnvoi(issue);
  }

  /// Demande la creation du compte de l'adresse saisie, si le lien porte une
  /// invitation. Ne leve jamais : le lien part ensuite dans tous les cas.
  Future<void> _ouvrirCompteInvite() async {
    final InvitationDansAdresse? invitation = _invitationRetenue;
    if (invitation == null) return;
    if (_invitation == null && _code.text.trim().isNotEmpty) {
      // Le code saisi suit le meme chemin que celui du lien : il reste retenu
      // sur cet appareil pour l'inscription qui suit le lien de connexion.
      retenirInvitationEnCours(code: invitation.code, candidature: false);
    }
    await ref
        .read(portInvitationCompteProvider)
        .ouvrir(invitation, _courriel.text);
  }

  @override
  void initState() {
    super.initState();
    _controle = ref.read(fabriqueControleurAntiRobotProvider)();
    final Uri retour = widget.urlRetour ?? Uri.base;
    // I1 (UX-013) : le lien de l'invitation d'un enseignant
    // (`?mode=creer&invitation=1&code=...`) pose la marque de l'invitation en
    // cours, que l'inscription reprend au retour du lien de connexion.
    retenirInvitationDepuisAdresse(retour);
    // INVITATION-COMPTE (07/11/2026) : le code d'une invitation, lu une fois.
    _invitation = invitationDansAdresse(retour);
    _lienAilleurs = lienOuvertAilleursIci(retour);
    // Google refuse un nouveau compte quand les inscriptions sont fermees :
    // la phrase se dit ici, la recuperation d'acces n'y peut rien.
    if (inscriptionFermeeDepuisUrlRetour(retour)) {
      _erreur = t.connexion.inscriptionFermee;
      return;
    }
    final MotifRecuperation? motif = motifDepuisUrlRetour(retour);
    if (motif != null) {
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted) {
          GoRouter.of(context).go(cheminRecuperation(motif));
        }
      });
    }
  }

  /// Le controle anti-robot de l'ecran (ANTI-ROBOT, 03/11/2026) : pose
  /// seulement quand une cle publique est reglee.
  late final ControleurAntiRobot _controle;

  @override
  void dispose() {
    _courriel.dispose();
    _code.dispose();
    _motDePasse.dispose();
    _controle.dispose();
    super.dispose();
  }

  /// La cle publique du controle, ou nul : aucun controle (reglage vide),
  /// l'ecran se comporte comme avant.
  String? get _cleControle => ref.read(cleTurnstileProvider).value;

  /// Le jeton du controle pour un envoi. Nul et vrai : aucun controle pose.
  /// Nul et faux : un controle est pose et n'a pas abouti.
  Future<({String? jeton, bool ok})> _jetonControle() async {
    if (_cleControle == null) return (jeton: null, ok: true);
    final String? jeton = await _controle.jetonPourEnvoi();
    return (jeton: jeton, ok: jeton != null);
  }

  /// Apres un envoi : le jeton est use, un autre est demande.
  void _apresEnvoi() {
    if (_cleControle != null) _controle.apresEnvoi();
  }

  /// Vrai quand l'ecran propose le champ de mot de passe de demonstration.
  ///
  /// Deux verrous, tous deux hors production : le drapeau de compilation
  /// (`AUTH_PAR_MOT_DE_PASSE`) et la garde d'environnement de `/demo/*`.
  ///
  /// `read` et non `watch` : c'est une decision de compilation, elle ne change
  /// pas sous les pieds d'un ecran deja monte.
  bool get _demo =>
      widget.demoAuth ??
      // NETTOYAGE-1 : la constante d'abord, pour que dart2js retire la
      // demonstration du paquet de production.
      (Env.demoCompilee &&
          ref.read(demoAuthActiveProvider) &&
          environnementAutoriseDemo(ref.read(environnementConnexionProvider)));

  /// Le chemin decide de l'action ; le libelle de [_Saisie] lit la meme fonction.
  Future<void> _soumettre() {
    final CheminConnexion chemin = cheminConnexion(
      demo: _demo,
      courriel: _courriel.text,
      motDePasse: _motDePasse.text,
    );
    return chemin == CheminConnexion.lien
        ? _envoyerLien()
        : _ouvrirDemonstration();
  }

  Future<void> _envoyerLien() async {
    if (!courrielPlausible(_courriel.text)) {
      setState(() => _erreur = t.connexion.erreurCourriel);
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      final ({String? jeton, bool ok}) controle = await _jetonControle();
      if (!controle.ok) {
        if (mounted) setState(() => _erreur = t.connexion.controle.erreur);
        return;
      }
      await _ouvrirCompteInvite();
      await ref
          .read(serviceAuthProvider)
          .envoyerLienCourriel(_courriel.text, jetonControle: controle.jeton);
      if (mounted) {
        setState(() {
          _envoye = true;
          _renvoye = false;
          _erreurRenvoi = null;
        });
      }
    } on Object catch (erreur) {
      if (mounted) {
        setState(() => _erreur = _phraseEchec(erreur));
      }
    } finally {
      _apresEnvoi();
      if (mounted) {
        setState(() => _envoi = false);
      }
    }
  }

  /// « Renvoyer le lien » : la meme demande, dite differemment une fois
  /// partie (le message le plus recent est le seul a suivre).
  Future<void> _renvoyerLien() async {
    if (_renvoi) {
      return;
    }
    setState(() {
      _renvoi = true;
      _erreurRenvoi = null;
    });
    try {
      final ({String? jeton, bool ok}) controle = await _jetonControle();
      if (!controle.ok) {
        if (mounted) {
          setState(() => _erreurRenvoi = t.connexion.controle.erreur);
        }
        return;
      }
      await _ouvrirCompteInvite();
      await ref
          .read(serviceAuthProvider)
          .envoyerLienCourriel(_courriel.text, jetonControle: controle.jeton);
      if (mounted) {
        setState(() => _renvoye = true);
      }
    } on Object catch (erreur) {
      if (mounted) {
        setState(() => _erreurRenvoi = _phraseEchec(erreur));
      }
    } finally {
      _apresEnvoi();
      if (mounted) {
        setState(() => _renvoi = false);
      }
    }
  }

  /// Le parcours de demonstration : une adresse fictive ouvre un role sans
  /// contacter Supabase ; toute autre adresse passe par le mot de passe.
  Future<void> _ouvrirDemonstration() async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      final AccesDemo? acces = accesDemoDepuisCourriel(_courriel.text);
      if (acces != null) {
        ref.read(sessionProvider.notifier).ouvrirDemo(acces);
      } else {
        final ({String? jeton, bool ok}) controle = await _jetonControle();
        if (!controle.ok) {
          if (mounted) setState(() => _erreur = t.connexion.controle.erreur);
          return;
        }
        await ref
            .read(serviceAuthProvider)
            .connexionMotDePasse(
              _courriel.text.trim(),
              _motDePasse.text,
              jetonControle: controle.jeton,
            );
        _apresEnvoi();
      }
    } on AuthException {
      if (mounted) {
        setState(() => _erreur = t.connexion.erreurMotDePasse);
      }
    } on Object {
      if (mounted) {
        setState(() => _erreur = t.connexion.erreurEnvoi);
      }
    } finally {
      if (mounted) {
        setState(() => _envoi = false);
      }
    }
  }

  Future<void> _google() async {
    setState(() => _erreur = null);
    try {
      await ref.read(serviceAuthProvider).connexionGoogle();
    } on AuthException catch (erreur) {
      // **Le message du fournisseur se montre, il ne se resume pas.** Cet
      // ecran a longtemps affiche « L'envoi n'a pas abouti » sur un refus
      // `invalid_client` : le bouton Google etait casse pour tout le monde, et
      // la seule phrase capable de le dire etait avalee ici.
      if (mounted) {
        setState(
          () => _erreur =
              estInscriptionFermee(code: erreur.code, message: erreur.message)
              ? t.connexion.inscriptionFermee
              : erreur.message,
        );
      }
    } on Object {
      if (mounted) {
        setState(() => _erreur = t.connexion.erreurEnvoi);
      }
    }
  }

  /// « Un probleme pour vous connecter ? » : la recuperation s'ouvre avec le
  /// courriel deja saisi ici (FORM-L10), s'il y en a un.
  void _versRecuperation() {
    final String courriel = _courriel.text.trim();
    GoRouter.of(context).go(
      Routes.connexionRecuperation,
      extra: courriel.isEmpty ? null : courriel,
    );
  }

  Future<void> _entreeEleve() async {
    final bool saisir = await ouvrirFeuilleAppareilEleve(context);
    if (saisir && mounted) {
      GoRouter.of(context).go(Routes.connexionEleve);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? cle = ref.watch(cleTurnstileProvider).value;
    Widget? controle(bool enCours) => cle == null
        ? null
        : ControleAntiRobot(
            cle: cle,
            controleur: _controle,
            envoiEnCours: enCours,
          );
    return CoquilleEntree(
      formulaire: (bool bureau) => _envoye
          ? _LienEnvoye(
              controle: controle(_renvoi),
              courriel: _courriel.text.trim(),
              renvoi: _renvoi,
              renvoye: _renvoye,
              erreurRenvoi: _erreurRenvoi,
              onRenvoyer: () => unawaited(_renvoyerLien()),
              onChangerAdresse: () => setState(() {
                _envoye = false;
                _renvoye = false;
                _erreurRenvoi = null;
              }),
              onProbleme: _versRecuperation,
            )
          : _Saisie(
              bureau: bureau,
              lienAilleurs: _lienAilleurs,
              controle: controle(_envoi),
              courriel: _courriel,
              motDePasse: _motDePasse,
              demo: _demo,
              mode: _mode,
              // ONBOARDING-BOUCLE (14/11/2026) : un questionnaire deja rempli
              // sur cet appareil se dit, au lieu de passer sous silence.
              reponsesGardees:
                  ref.watch(questionnaireInscriptionProvider).complet &&
                  _invitation == null,
              onRevoirReponses: () => GoRouter.of(context).go(Routes.commencer),
              codeDansAdresse: _invitation?.code ?? _codeRetenu,
              code: _code,
              codeOuvert: _codeOuvert,
              onOuvrirCode: () => setState(() => _codeOuvert = true),
              onMode: (ModeConnexion m) {
                // Admission, lot B : creer un compte commence par le
                // questionnaire (fiche du 29/10, « compte en dernier »).
                if (m == ModeConnexion.creation &&
                    !ref.read(questionnaireInscriptionProvider).complet) {
                  GoRouter.of(context).go(Routes.commencer);
                  return;
                }
                setState(() {
                  _mode = m;
                  _erreur = null;
                });
              },
              erreur: _erreur,
              envoi: _envoi,
              onChanged: () => setState(() {}),
              onSoumettre: () => unawaited(_soumettre()),
              onGoogle: () => unawaited(_google()),
              onEleve: () => unawaited(_entreeEleve()),
              onProbleme: _versRecuperation,
            ),
      // CONNEXION-UX (directeur, 03/11/2026) : tout ce qui n'est pas le
      // titre, le champ et les boutons descend ici, en petits liens.
      pied: <Widget>[
        // CONNEXION-ALIGN (04/11/2026) : petits liens, ecarts courts, en un
        // seul bloc a la largeur du champ ; « Informations legales » et
        // « Confidentialite » sur une ligne.
        Ecart.vLg,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (!_envoye &&
                !_demo &&
                _mode == ModeConnexion.connexion) ...<Widget>[
              // Une sortie discrete : la recuperation d'acces (lien expire ou
              // jamais recu).
              LienPied(
                cibleReduite: true,
                cle: const ValueKey<String>('connexion-probleme'),
                libelle: t.connexion.probleme,
                onPress: _versRecuperation,
              ),
              LienPied(
                cibleReduite: true,
                cle: const ValueKey<String>('connexion-appareil-eleve-aide'),
                libelle: t.connexion.appareilEleveAide,
                onPress: () => unawaited(_entreeEleve()),
              ),
            ],
            // Sur une ligne quand elle tient ; a texte agrandi, le second lien
            // passe dessous plutot que de deborder.
            Wrap(
              spacing: AppSpacing.lg,
              children: <Widget>[
                LienPied(
                  cibleReduite: true,
                  libelle: t.juridique.titre,
                  onPress: () => GoRouter.of(context).push(Routes.juridique),
                ),
                // Le consentement (pilote, 03/11/2026, voie a) : la page de
                // confidentialite, ou ira la phrase sur la verification de
                // securite une fois validee par le directeur.
                LienPied(
                  cibleReduite: true,
                  cle: const ValueKey<String>('connexion-confidentialite'),
                  libelle: t.juridique.confidentialite.titre,
                  onPress: () =>
                      GoRouter.of(context)
                          .push(TexteJuridique.confidentialite.chemin),
                ),
              ],
            ),
          ],
        ),
        // Hors production seulement : sans lanceur, rien. La constante retire
        // le bouton du paquet de production (NETTOYAGE-1).
        if (Env.demoCompilee) const EntreeDemonstration(),
      ],
    );
  }
}

class _Saisie extends StatelessWidget {
  const _Saisie({
    required this.bureau,
    required this.lienAilleurs,
    required this.controle,
    required this.courriel,
    required this.motDePasse,
    required this.demo,
    required this.mode,
    required this.codeDansAdresse,
    required this.code,
    required this.codeOuvert,
    required this.onOuvrirCode,
    required this.onMode,
    required this.reponsesGardees,
    required this.onRevoirReponses,
    required this.erreur,
    required this.envoi,
    required this.onChanged,
    required this.onSoumettre,
    required this.onGoogle,
    required this.onEleve,
    required this.onProbleme,
  });

  /// Vrai dans le volet du formulaire sur ordinateur : boutons a la largeur
  /// de leur contenu, au bord de fin.
  final bool bureau;

  /// FN-111 : le lien de connexion a ete ouvert sur un autre appareil ou dans
  /// un autre navigateur ; la page le dit avant tout le reste.
  final bool lienAilleurs;

  /// Le controle anti-robot, ou nul (aucun controle : l'ecran d'avant).
  final Widget? controle;
  final VoidCallback onProbleme;
  final TextEditingController courriel;
  final TextEditingController motDePasse;
  final bool demo;
  final ModeConnexion mode;

  /// Le code d'invitation que l'adresse porte deja, ou nul.
  final String? codeDansAdresse;

  /// Le champ du code saisi, quand l'adresse n'en porte pas.
  final TextEditingController code;
  final bool codeOuvert;
  final VoidCallback onOuvrirCode;
  final ValueChanged<ModeConnexion> onMode;

  /// Vrai quand le questionnaire est deja rempli sur cet appareil : en
  /// creation, l'ecran le dit et propose de revoir les reponses.
  final bool reponsesGardees;
  final VoidCallback onRevoirReponses;
  final String? erreur;
  final bool envoi;
  final VoidCallback onChanged;
  final VoidCallback onSoumettre;
  final VoidCallback onGoogle;
  final VoidCallback onEleve;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    // Lu au rendu : chaque frappe reconstruit l'ecran (onChanged).
    final CheminConnexion chemin = cheminConnexion(
      demo: demo,
      courriel: courriel.text,
      motDePasse: motDePasse.text,
    );
    final bool versLien = chemin == CheminConnexion.lien;
    final bool creation = mode == ModeConnexion.creation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Demande du directeur (01/11/2026) : une session coupee par le
        // serveur (deux connexions, un autre compte ouvert ici) se dit.
        ValueListenableBuilder<bool>(
          valueListenable: sessionTermineeParLeServeur,
          builder: (BuildContext _, bool terminee, Widget? _) => terminee
              ? Padding(
                  padding: const EdgeInsetsDirectional.only(
                    bottom: AppSpacing.lg,
                  ),
                  child: BandeauAttention(
                    titre: t.connexion.sessionTermineeTitre,
                    message: t.connexion.sessionTermineePhrase,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        // FN-111 (31/10/2026) : sans ce bandeau, la personne arrivait ici
        // sans un mot, et croyait le lien casse.
        if (lienAilleurs)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.lg),
            child: BandeauAttention(
              key: const ValueKey<String>('connexion-lien-ailleurs'),
              titre: t.connexion.lienAilleursTitre,
              message: t.connexion.lienAilleursPhrase,
            ),
          ),
        Text(
          creation ? t.connexion.titreCreation : t.connexion.titre,
          style: textes.headlineMedium,
        ),
        // CONNEXION-UX (directeur, 03/11/2026) : la page est simple ; la
        // phrase d'introduction ne reste qu'en demonstration (hors
        // production), ou elle dit qu'aucun lien ne part.
        if (!versLien) ...<Widget>[
          Ecart.vMd,
          Text(
            t.connexion.introDemo,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
        Ecart.vXl,
        // L4 : deux chemins distincts, choisis avant de saisir. Plus petits
        // (CONNEXION-UX) : le registre de legende. CONNEXION-ALIGN
        // (04/11/2026) : « petits » veut dire un texte plus petit, jamais plus
        // etroits ; les onglets ont la largeur du champ.
        Theme(
          data: Theme.of(context).copyWith(
            textTheme: textes.copyWith(labelLarge: textes.labelMedium),
          ),
          child: ControleSegmente<ModeConnexion>(
            key: const ValueKey<String>('connexion-mode'),
            dense: true,
            segments: <Segment<ModeConnexion>>[
              Segment<ModeConnexion>(
                valeur: ModeConnexion.connexion,
                libelle: t.connexion.modeConnexion,
              ),
              Segment<ModeConnexion>(
                valeur: ModeConnexion.creation,
                libelle: t.connexion.modeCreation,
              ),
            ],
            valeur: mode,
            onChange: onMode,
          ),
        ),
        if (creation && reponsesGardees) ...<Widget>[
          Ecart.vLg,
          Semantics(
            liveRegion: true,
            child: Text(
              t.inscription.questionnaire.acces.reponsesGardees,
              key: const ValueKey<String>('connexion-reponses-gardees'),
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
          LienEntree(
            cle: const ValueKey<String>('connexion-revoir-reponses'),
            libelle: t.connexion.revoirReponses,
            onPress: onRevoirReponses,
          ),
        ],
        Ecart.vXl,
        ChampEntree(
          cle: 'connexion-courriel',
          etiquette: t.connexion.courriel,
          indice: t.connexion.courrielIndice,
          controleur: courriel,
          erreur: erreur,
          onChanged: onChanged,
          onSoumettre: demo ? null : onSoumettre,
          clavier: TextInputType.emailAddress,
          autofill: const <String>[AutofillHints.email],
        ),
        // INVITATION-ENSEIGNANT-REPARE : le code d'invitation a une place. Pris
        // dans l'adresse, il se dit ; sinon un lien ouvre son champ.
        if (creation && codeDansAdresse != null) ...<Widget>[
          Ecart.vSm,
          Text(
            t.connexion.codeInvitationReconnu(
              code: codeDansAdresse!.trim().toUpperCase(),
            ),
            key: const ValueKey<String>('connexion-code-reconnu'),
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ] else if (creation && codeOuvert) ...<Widget>[
          Ecart.vMd,
          ChampEntree(
            cle: 'connexion-code-invitation',
            etiquette: t.connexion.codeInvitation,
            indice: t.connexion.codeInvitationIndice,
            controleur: code,
            erreur: null,
            onChanged: onChanged,
            onSoumettre: demo ? null : onSoumettre,
            clavier: TextInputType.text,
            autofill: const <String>[],
          ),
        ] else if (creation) ...<Widget>[
          Ecart.vSm,
          LienFleche(
            key: const ValueKey<String>('connexion-code-lien'),
            libelle: t.connexion.avoirCodeInvitation,
            onPress: onOuvrirCode,
            alignerEnDebut: true,
          ),
        ],
        if (demo) ...<Widget>[
          Ecart.vMd,
          ChampEntree(
            cle: 'connexion-mot-de-passe',
            etiquette: t.connexion.motDePasseDemo,
            indice: null,
            controleur: motDePasse,
            erreur: null,
            onChanged: onChanged,
            onSoumettre: onSoumettre,
            clavier: TextInputType.text,
            autofill: const <String>[AutofillHints.password],
            masque: true,
          ),
        ],
        // ANTI-ROBOT : le controle se pose entre le champ et les boutons ; il
        // ne prend de place que s'il se montre (CONNEXION-UX).
        ?controle,
        Ecart.vLg,
        // CONNEXION-ALIGN (04/11/2026) : les boutons ont ensemble la largeur
        // du champ ([ActionsEntree]). Le parcours de demonstration n'ouvre pas
        // Google : un chemin reel vers un vrai compte.
        ActionsEntree(
          bureau: bureau,
          principale: ActionPrincipale(
            libelle: !versLien
                ? t.connexion.entrerDemo
                : creation
                ? t.connexion.envoyerLienCreation
                : t.connexion.envoyerLien,
            onPress: onSoumettre,
            enCours: envoi,
            // Sur la marque, l'aplat blanc a encre violette ; sur le volet
            // caramel, le violet a encre blanche (fiche, sections 3 et 4).
            affirmee: true,
            pleineLargeur: true,
            margeHorizontaleReduite: true,
            // Texte reduit seulement quand le bouton partage sa rangee
            // (ordinateur, ou creation sur telephone) ; seul en pleine
            // largeur sur telephone, il garde son texte (garde-cap, 04/11).
            libelleReduit: !demo && (bureau || creation),
          ),
          secondaire: demo
              ? null
              : ActionPrincipale(
                  libelle: t.connexion.avecGoogle,
                  onPress: onGoogle,
                  niveau: NiveauAction.secondaire,
                  pleineLargeur: true,
                  margeHorizontaleReduite: true,
                  libelleReduit: true,
                  // Une marque tierce se montre, elle ne se decrit pas : le
                  // logo est ce que l'usager cherche des yeux avant de lire
                  // le libelle. Sur le violet du telephone, pose sur un disque
                  // blanc (pilote, 04/11/2026, comme le questionnaire).
                  prefixe: bureau
                      ? const LogoGoogle()
                      : const _LogoGoogleSurBlanc(),
                ),
          // CONNEXION-UX (directeur, 03/11/2026) : l'entree de l'eleve devient
          // un bouton, a cote de Google (avant lui dans le sens de lecture) ;
          // la feuille qui s'ouvre explique le code. L4 : en creation, elle
          // s'efface (reservee aux comptes existants).
          tierce: demo || creation
              ? null
              : ActionPrincipale(
                  key: const ValueKey<String>('connexion-appareil-eleve'),
                  libelle: t.connexion.appareilEleve,
                  onPress: onEleve,
                  niveau: NiveauAction.secondaire,
                  pleineLargeur: true,
                  margeHorizontaleReduite: true,
                  libelleReduit: true,
                  prefixe: Icon(AppIcons.enfant.repos, size: AppSpacing.xl),
                ),
        ),
      ],
    );
  }
}

class _LienEnvoye extends StatelessWidget {
  const _LienEnvoye({
    required this.controle,
    required this.courriel,
    required this.renvoi,
    required this.renvoye,
    required this.erreurRenvoi,
    required this.onRenvoyer,
    required this.onChangerAdresse,
    required this.onProbleme,
  });

  /// Le controle anti-robot, ou nul (aucun controle : l'ecran d'avant).
  final Widget? controle;
  final String courriel;
  final bool renvoi;
  final bool renvoye;
  final String? erreurRenvoi;
  final VoidCallback onRenvoyer;
  final VoidCallback onChangerAdresse;
  final VoidCallback onProbleme;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(t.connexion.lienEnvoye, style: textes.headlineMedium),
        Ecart.vMd,
        Semantics(
          liveRegion: true,
          child: Text(
            renvoye
                ? t.connexion.renvoye(courriel: courriel)
                : t.connexion.lienEnvoyeDetail(courriel: courriel),
            key: const ValueKey<String>('connexion-envoye-detail'),
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ),
        if (erreurRenvoi != null) ...<Widget>[
          Ecart.vMd,
          Semantics(
            liveRegion: true,
            child: Text(
              erreurRenvoi!,
              key: const ValueKey<String>('connexion-erreur-renvoi'),
              // E2 : l'encre d'alerte du produit, pas celle de Material.
              style: palette.inkAlert.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
        ],
        // ONBOARDING-BOUCLE (14/11/2026) : le code du message, saisi dans ce
        // navigateur, ouvre la session meme si le lien s'ouvre ailleurs.
        Ecart.vXl,
        SaisieCodeCourriel(courriel: courriel),
        ?controle,
        Ecart.vXxl,
        // ALIGN-RENVOI (04/11/2026) : le bouton seul a la largeur du champ,
        // sur ordinateur comme sur telephone (meme regle que CONNEXION-ALIGN).
        ActionPrincipale(
          key: const ValueKey<String>('connexion-renvoyer'),
          libelle: t.connexion.renvoyer,
          onPress: onRenvoyer,
          enCours: renvoi,
          niveau: NiveauAction.secondaire,
          pleineLargeur: true,
        ),
        Ecart.vLg,
        LienEntree(
          libelle: t.connexion.changerAdresse,
          onPress: onChangerAdresse,
        ),
        LienEntree(libelle: t.connexion.probleme, onPress: onProbleme),
      ],
    );
  }
}

/// Le logo Google pose sur un disque blanc, sur la surface de marque du
/// telephone : sur le violet, ses couleurs officielles (bleu, rouge) se
/// fondaient dans le fond (pilote et garde-cap, 04/11/2026, meme traitement
/// que la fin du questionnaire). Le disque prend le blanc de la palette de la
/// marque (`surfacePrimary`) ; le logo reste tel quel. Sur le parchemin de
/// l'ordinateur, le logo se pose seul.
class _LogoGoogleSurBlanc extends StatelessWidget {
  const _LogoGoogleSurBlanc();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppPalette.of(context).surfacePrimary.background,
      shape: BoxShape.circle,
    ),
    child: const Padding(
      padding: EdgeInsets.all(AppSpacing.xs),
      child: LogoGoogle(taille: 18),
    ),
  );
}
