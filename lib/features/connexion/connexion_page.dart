import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../core/auth/service_auth.dart';
import '../../core/config/env.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/marque/logo_google.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/controle_segmente.dart';
import '../demo/mode_demonstration.dart';
import '../demo/racine_demonstrable.dart';
import '../inscription/questionnaire/questionnaire_inscription.dart'
    show questionnaireInscriptionProvider;
import 'coquille_entree.dart';
import 'feuille_appareil_eleve.dart';
import 'recuperation_page.dart';

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

  @override
  void initState() {
    super.initState();
    final MotifRecuperation? motif = motifDepuisUrlRetour(
      widget.urlRetour ?? Uri.base,
    );
    if (motif != null) {
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted) {
          GoRouter.of(context).go(cheminRecuperation(motif));
        }
      });
    }
  }

  @override
  void dispose() {
    _courriel.dispose();
    _motDePasse.dispose();
    super.dispose();
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
      (ref.read(demoAuthActiveProvider) &&
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
      await ref.read(serviceAuthProvider).envoyerLienCourriel(_courriel.text);
      if (mounted) {
        setState(() {
          _envoye = true;
          _renvoye = false;
          _erreurRenvoi = null;
        });
      }
    } on Object catch (erreur) {
      if (mounted) {
        setState(() => _erreur = phraseEchecEnvoi(issueEchecEnvoi(erreur)));
      }
    } finally {
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
      await ref.read(serviceAuthProvider).envoyerLienCourriel(_courriel.text);
      if (mounted) {
        setState(() => _renvoye = true);
      }
    } on Object catch (erreur) {
      if (mounted) {
        setState(
          () => _erreurRenvoi = phraseEchecEnvoi(issueEchecEnvoi(erreur)),
        );
      }
    } finally {
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
        await ref
            .read(serviceAuthProvider)
            .connexionMotDePasse(_courriel.text.trim(), _motDePasse.text);
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
        setState(() => _erreur = erreur.message);
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
  Widget build(BuildContext context) => CoquilleEntree(
    formulaire: (bool bureau) => _envoye
        ? _LienEnvoye(
            bureau: bureau,
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
            courriel: _courriel,
            motDePasse: _motDePasse,
            demo: _demo,
            mode: _mode,
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
    pied: <Widget>[
      Ecart.vXxl,
      LienEntree(
        libelle: t.juridique.titre,
        onPress: () => GoRouter.of(context).push(Routes.juridique),
      ),
      // Hors production seulement : sans lanceur, rien.
      const EntreeDemonstration(),
    ],
  );
}

class _Saisie extends StatelessWidget {
  const _Saisie({
    required this.bureau,
    required this.courriel,
    required this.motDePasse,
    required this.demo,
    required this.mode,
    required this.onMode,
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
  final VoidCallback onProbleme;
  final TextEditingController courriel;
  final TextEditingController motDePasse;
  final bool demo;
  final ModeConnexion mode;
  final ValueChanged<ModeConnexion> onMode;
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
        Text(
          creation ? t.connexion.titreCreation : t.connexion.titre,
          style: textes.headlineMedium,
        ),
        Ecart.vMd,
        Text(
          !versLien
              ? t.connexion.introDemo
              : creation
              ? t.connexion.introCreation
              : t.connexion.intro,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vXxl,
        // L4 : deux chemins distincts, choisis avant de saisir.
        ControleSegmente<ModeConnexion>(
          key: const ValueKey<String>('connexion-mode'),
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
        Ecart.vXxl,
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
        Ecart.vLg,
        // Une rangee au bord de fin sur ordinateur, Google puis le lien ;
        // empiles pleine largeur sur telephone (correctif du 25/10/2026). Le
        // parcours de demonstration n'ouvre pas Google : un chemin reel vers
        // un vrai compte.
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
            pleineLargeur: !bureau,
          ),
          secondaire: demo
              ? null
              : ActionPrincipale(
                  libelle: t.connexion.avecGoogle,
                  onPress: onGoogle,
                  niveau: NiveauAction.secondaire,
                  pleineLargeur: !bureau,
                  // Une marque tierce se montre, elle ne se decrit pas : le
                  // logo est ce que l'usager cherche des yeux avant de lire
                  // le libelle.
                  prefixe: const LogoGoogle(),
                ),
        ),
        if (!demo) ...<Widget>[
          // L4 : en creation, les sorties reservees aux comptes existants
          // s'effacent (appareil d'un eleve, lien expire).
          if (!creation) ...<Widget>[
            // L'entree de l'eleve : un parcours different, pas une autre
            // facon de faire le meme. Un lien avec fleche, sous la phrase qui
            // dit a qui il s'adresse ; la feuille qui s'ouvre explique le code.
            Ecart.vXxl,
            Text(
              t.connexion.appareilEleveAide,
              style: palette.inkMuted.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
            LienEntree(
              cle: const ValueKey<String>('connexion-appareil-eleve'),
              libelle: t.connexion.appareilEleve,
              onPress: onEleve,
            ),
            // Une sortie discrete : la recuperation d'acces (lien expire ou
            // jamais recu).
            LienEntree(
              cle: const ValueKey<String>('connexion-probleme'),
              libelle: t.connexion.probleme,
              onPress: onProbleme,
            ),
          ],
        ],
      ],
    );
  }
}

class _LienEnvoye extends StatelessWidget {
  const _LienEnvoye({
    required this.bureau,
    required this.courriel,
    required this.renvoi,
    required this.renvoye,
    required this.erreurRenvoi,
    required this.onRenvoyer,
    required this.onChangerAdresse,
    required this.onProbleme,
  });

  final bool bureau;
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
        Ecart.vXxl,
        BoutonEntree(
          bureau: bureau,
          child: ActionPrincipale(
            key: const ValueKey<String>('connexion-renvoyer'),
            libelle: t.connexion.renvoyer,
            onPress: onRenvoyer,
            enCours: renvoi,
            niveau: NiveauAction.secondaire,
            pleineLargeur: !bureau,
          ),
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
