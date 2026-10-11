import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../core/auth/service_auth.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/marque/logo_google.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/marque_page.dart';
import '../../core/widgets/page_shell.dart';
import '../demo/racine_demonstrable.dart';
import 'feuille_appareil_eleve.dart';
import 'recuperation_page.dart';

/// Largeur de la carte d'entree.
///
/// Une colonne unique aux trois gabarits : la fiche `TUT-00` le prescrit, et
/// une seconde colonne n'aurait rien a porter. Ce qui change d'un gabarit a
/// l'autre, c'est la respiration autour, pas la forme.
const double _largeurCarte = 460;

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
  const ConnexionPage({super.key, this.demoAuth, this.urlRetour});

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

  /// Vrai quand l'ecran doit proposer le raccourci de demonstration.
  ///
  /// `read` et non `watch` : c'est une decision de compilation, elle ne change
  /// pas sous les pieds d'un ecran deja monte.
  bool get _demo => widget.demoAuth ?? ref.read(demoAuthActiveProvider);

  Future<void> _soumettre() => _demo ? _ouvrirDemonstration() : _envoyerLien();

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
  Widget build(BuildContext context) {
    // La respiration au dessus de la carte, pas sa largeur : le gabarit change
    // l'air autour de la colonne, jamais la colonne.
    final Widget respiration = AppGabarit.de(context) == Gabarit.mobile
        ? Ecart.vXxl
        : Ecart.vSection;

    return PageShell(
      // La page mene son propre defilement : la carte se centre verticalement
      // quand la hauteur le permet, et redevient defilante des qu'elle ne le
      // permet plus. Sans cela, une fenetre de bureau posait la carte tout en
      // haut avec un desert en dessous, et un telephone en mode paysage
      // rognait le bas du formulaire.
      defilante: false,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints contraintes) =>
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: contraintes.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const MarquePage(logo: true),
                    respiration,
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _largeurCarte,
                      ),
                      child: AppCard(
                        key: const ValueKey<String>('connexion-carte'),
                        dominante: true,
                        child: _envoye
                            ? _LienEnvoye(
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
                                courriel: _courriel,
                                motDePasse: _motDePasse,
                                demo: _demo,
                                erreur: _erreur,
                                envoi: _envoi,
                                onChanged: () => setState(() {}),
                                onSoumettre: () => unawaited(_soumettre()),
                                onGoogle: () => unawaited(_google()),
                                onEleve: () => unawaited(_entreeEleve()),
                                onProbleme: _versRecuperation,
                                onDecouvrir: () =>
                                    GoRouter.of(context).go(Routes.bienvenue),
                              ),
                      ),
                    ),
                    // Hors production seulement : sans lanceur, rien.
                    const EntreeDemonstration(),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}

class _Saisie extends StatelessWidget {
  const _Saisie({
    required this.courriel,
    required this.motDePasse,
    required this.demo,
    required this.erreur,
    required this.envoi,
    required this.onChanged,
    required this.onSoumettre,
    required this.onGoogle,
    required this.onEleve,
    required this.onProbleme,
    required this.onDecouvrir,
  });

  final VoidCallback onProbleme;
  final VoidCallback onDecouvrir;
  final TextEditingController courriel;
  final TextEditingController motDePasse;
  final bool demo;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(t.connexion.titre, style: textes.headlineMedium),
        Ecart.vMd,
        Text(
          t.connexion.intro,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vXxl,
        _Champ(
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
          Ecart.vLg,
          _Champ(
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
        Ecart.vXl,
        ActionPrincipale(
          libelle: t.connexion.envoyerLien,
          onPress: onSoumettre,
          enCours: envoi,
        ),

        // Le parcours de demonstration s'arrete la : il n'ouvre ni Google ni
        // l'entree eleve, qui sont des chemins reels vers un vrai compte.
        if (!demo) ...<Widget>[
          Ecart.vXl,
          Row(
            children: <Widget>[
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  t.connexion.ou,
                  style: palette.inkMuted.applyTo(
                    textes.bodySmall ?? const TextStyle(),
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          Ecart.vXl,
          ActionPrincipale(
            libelle: t.connexion.avecGoogle,
            onPress: onGoogle,
            niveau: NiveauAction.secondaire,
            // Une marque tierce se montre, elle ne se decrit pas : le logo est
            // ce que l'usager cherche des yeux avant de lire le libelle.
            prefixe: const LogoGoogle(),
          ),

          // L'entree de l'eleve, en texte seul : c'est un parcours different,
          // pas une autre facon de faire le meme. Elle etait au meme rang que
          // Google, avec le meme filet, et son libelle -- « J'ai un code » --
          // ne disait ni a qui elle s'adressait ni ou trouver ce code. La
          // feuille qui s'ouvre au clic porte desormais cette explication.
          Ecart.vSection,
          Text(
            t.connexion.appareilEleveAide,
            textAlign: TextAlign.center,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
          Ecart.vSm,
          Align(
            child: ActionPrincipale(
              libelle: t.connexion.appareilEleve,
              onPress: onEleve,
              niveau: NiveauAction.tertiaire,
              pleineLargeur: false,
            ),
          ),
          Ecart.vLg,
          const Divider(),
          Ecart.vSm,
          // Deux sorties discretes : la recuperation d'acces (lien expire ou
          // jamais recu) et l'accueil public pour une premiere visite.
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            children: <Widget>[
              ActionPrincipale(
                key: const ValueKey<String>('connexion-probleme'),
                libelle: t.connexion.probleme,
                onPress: onProbleme,
                niveau: NiveauAction.tertiaire,
                pleineLargeur: false,
              ),
              ActionPrincipale(
                key: const ValueKey<String>('connexion-decouvrir'),
                libelle: t.connexion.decouvrir,
                onPress: onDecouvrir,
                niveau: NiveauAction.tertiaire,
                pleineLargeur: false,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Un champ avec son etiquette **au dessus**, et non flottante dans le cadre.
///
/// L'etiquette flottante de Material se pose a l'interieur du champ tant qu'il
/// est vide, en gris, exactement la ou l'oeil attend un texte d'invite. Le
/// champ courriel de cet ecran se lisait donc comme desactive alors qu'il
/// attendait une frappe. L'etiquette monte, l'invite descend, et les deux
/// disent chacune une chose.
class _Champ extends StatelessWidget {
  const _Champ({
    required this.cle,
    required this.etiquette,
    required this.indice,
    required this.controleur,
    required this.erreur,
    required this.onChanged,
    required this.onSoumettre,
    required this.clavier,
    required this.autofill,
    this.masque = false,
  });

  final String cle;
  final String etiquette;
  final String? indice;
  final TextEditingController controleur;
  final String? erreur;
  final VoidCallback onChanged;
  final VoidCallback? onSoumettre;
  final TextInputType clavier;
  final List<String> autofill;
  final bool masque;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(etiquette, style: textes.labelLarge),
        Ecart.vSm,
        TextField(
          key: ValueKey<String>(cle),
          controller: controleur,
          onChanged: (String _) => onChanged(),
          onSubmitted: onSoumettre == null
              ? null
              : (String _) => onSoumettre!(),
          keyboardType: clavier,
          autofillHints: autofill,
          obscureText: masque,
          textInputAction: onSoumettre == null
              ? TextInputAction.next
              : TextInputAction.go,
          decoration: InputDecoration(hintText: indice, errorText: erreur),
        ),
      ],
    );
  }
}

class _LienEnvoye extends StatelessWidget {
  const _LienEnvoye({
    required this.courriel,
    required this.renvoi,
    required this.renvoye,
    required this.erreurRenvoi,
    required this.onRenvoyer,
    required this.onChangerAdresse,
    required this.onProbleme,
  });

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
              style: textes.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
        Ecart.vXxl,
        ActionPrincipale(
          key: const ValueKey<String>('connexion-renvoyer'),
          libelle: t.connexion.renvoyer,
          onPress: onRenvoyer,
          enCours: renvoi,
          niveau: NiveauAction.secondaire,
        ),
        Ecart.vLg,
        Align(
          child: ActionPrincipale(
            libelle: t.connexion.changerAdresse,
            onPress: onChangerAdresse,
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
          ),
        ),
        Align(
          child: ActionPrincipale(
            libelle: t.connexion.probleme,
            onPress: onProbleme,
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
          ),
        ),
      ],
    );
  }
}
