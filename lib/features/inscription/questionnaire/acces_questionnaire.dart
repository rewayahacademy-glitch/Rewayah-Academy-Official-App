// QUESTIONNAIRE-FIN (directeur, 04/11/2026) : le dernier ecran du
// questionnaire, DANS le questionnaire (meme habillage, barre au bout).
//
// Le directeur a cru plusieurs fois que son inscription avait echoue : a la
// fin des questions, la page passait a la connexion (`/connexion?mode=creer`),
// avec ses onglets, son bouton eleve et un autre habillage. Ici, une phrase
// dit que les reponses sont gardees, puis l'ecran ne demande que l'acces :
// l'adresse electronique et « Recevoir le lien », ou Google. Pas d'onglets,
// pas de bouton eleve ; seulement les liens legaux en pied. L'ecran « lien
// envoye » reste dans le meme habillage.
//
// L'envoi est celui de la connexion (meme service, meme controle anti-robot,
// memes phrases d'echec) : les reponses du questionnaire restent dans le
// brouillon de l'appareil, et l'inscription les reprend au retour du lien,
// comme avant.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../../core/accessibilite/texte_sans_coupure.dart';
import '../../../core/auth/anti_robot.dart';
import '../../../core/auth/service_auth.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/marque/logo_google.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/controle_anti_robot.dart';
import '../../../core/widgets/page_etape.dart';
import '../../connexion/coquille_entree.dart';
import '../../connexion/recuperation_page.dart'
    show estInscriptionFermee, issueEchecEnvoi, phraseEchecEnvoi;
import '../../juridique/textes_juridiques.dart';

/// Le dernier ecran du questionnaire : l'acces (lien par courriel, ou Google).
class EcranAccesQuestionnaire extends ConsumerStatefulWidget {
  /// Cree l'ecran ; [numero] egale [total] : la barre est au bout.
  const EcranAccesQuestionnaire({
    required this.numero,
    required this.total,
    required this.onRetour,
    super.key,
  });

  /// Le rang de l'ecran (le dernier).
  final int numero;

  /// Le nombre d'ecrans du questionnaire, celui-ci compris.
  final int total;

  /// Revient a la derniere question.
  final VoidCallback? onRetour;

  /// La cle de l'ecran.
  static const Key cle = ValueKey<String>('questionnaire-acces');

  @override
  ConsumerState<EcranAccesQuestionnaire> createState() =>
      _EcranAccesQuestionnaireState();
}

class _EcranAccesQuestionnaireState
    extends ConsumerState<EcranAccesQuestionnaire> {
  final TextEditingController _courriel = TextEditingController();
  late final ControleurAntiRobot _controle;
  bool _envoi = false;

  /// Vrai pendant la connexion avec Google (DECISION-FLUIDITE : une
  /// connexion est sensible, son attente est animee dans le bouton).
  bool _googleEnCours = false;
  bool _envoye = false;
  String? _erreur;
  bool _renvoi = false;
  bool _renvoye = false;
  String? _erreurRenvoi;

  @override
  void initState() {
    super.initState();
    // Lu ici, pas paresseusement : `dispose` ne doit pas toucher `ref`.
    _controle = ref.read(fabriqueControleurAntiRobotProvider)();
  }

  @override
  void dispose() {
    _courriel.dispose();
    _controle.dispose();
    super.dispose();
  }

  String? get _cleControle => ref.read(cleTurnstileProvider).value;

  /// Le jeton du controle. Nul et vrai : aucun controle pose.
  Future<({String? jeton, bool ok})> _jetonControle() async {
    if (_cleControle == null) return (jeton: null, ok: true);
    final String? jeton = await _controle.jetonPourEnvoi();
    return (jeton: jeton, ok: jeton != null);
  }

  void _apresEnvoi() {
    if (_cleControle != null) _controle.apresEnvoi();
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
        setState(() => _erreur = phraseEchecEnvoi(issueEchecEnvoi(erreur)));
      }
    } finally {
      _apresEnvoi();
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _renvoyerLien() async {
    if (_renvoi) return;
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
      await ref
          .read(serviceAuthProvider)
          .envoyerLienCourriel(_courriel.text, jetonControle: controle.jeton);
      if (mounted) setState(() => _renvoye = true);
    } on Object catch (erreur) {
      if (mounted) {
        setState(
          () => _erreurRenvoi = phraseEchecEnvoi(issueEchecEnvoi(erreur)),
        );
      }
    } finally {
      _apresEnvoi();
      if (mounted) setState(() => _renvoi = false);
    }
  }

  Future<void> _google() async {
    if (_googleEnCours) return;
    setState(() {
      _erreur = null;
      _googleEnCours = true;
    });
    try {
      await ref.read(serviceAuthProvider).connexionGoogle();
    } on AuthException catch (erreur) {
      // Le message du fournisseur se montre, il ne se resume pas.
      if (mounted) {
        setState(
          () => _erreur =
              estInscriptionFermee(code: erreur.code, message: erreur.message)
              ? t.connexion.inscriptionFermee
              : erreur.message,
        );
      }
    } on Object {
      if (mounted) setState(() => _erreur = t.connexion.erreurEnvoi);
    } finally {
      // Sur le web, la page part vers Google et ne revient pas ici ; ailleurs,
      // ou en echec, le bouton redevient pressable.
      if (mounted) setState(() => _googleEnCours = false);
    }
  }

  void _versRecuperation() {
    final String courriel = _courriel.text.trim();
    GoRouter.of(context).go(
      Routes.connexionRecuperation,
      extra: courriel.isEmpty ? null : courriel,
    );
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
    final a = t.inscription.questionnaire.acces;
    return KeyedSubtree(
      key: EcranAccesQuestionnaire.cle,
      child: CoquilleEntree(
        volet: (bool bureau) => Builder(
          builder: (BuildContext context) {
            final TextTheme textes = Theme.of(context).textTheme;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                RangeeEtape(
                  numero: widget.numero,
                  total: widget.total,
                  onRetour: _envoye ? null : widget.onRetour,
                ),
                Ecart.vXxl,
                Semantics(
                  header: true,
                  child: TexteSansCoupure(
                    _envoye ? t.connexion.lienEnvoye : a.titre,
                    style:
                        (bureau
                            ? textes.headlineMedium
                            : textes.headlineSmall) ??
                        const TextStyle(),
                  ),
                ),
                Ecart.vSm,
                // Le lien parti, la phrase ne dit plus ce qu'il reste a faire
                // (garde-cap, 04/11) : seulement que les reponses sont gardees.
                TexteSansCoupure(
                  _envoye
                      ? a.reponsesGardees
                      : '${a.reponsesGardees} ${a.resteAcces}',
                  key: const ValueKey<String>('questionnaire-acces-gardees'),
                  style: textes.bodyMedium ?? const TextStyle(),
                ),
              ],
            );
          },
        ),
        formulaire: (bool bureau) => Builder(
          builder: (BuildContext context) => _envoye
              ? _envoyeContenu(context, bureau, controle(_renvoi))
              : _saisie(context, bureau, controle(_envoi)),
        ),
        pied: <Widget>[
          Ecart.vXxl,
          LiensPied(
            liens: <Widget>[
              LienPied(
                libelle: t.juridique.titre,
                onPress: () => GoRouter.of(context).push(Routes.juridique),
              ),
              LienPied(
                cle: const ValueKey<String>('questionnaire-confidentialite'),
                libelle: t.juridique.confidentialite.titre,
                onPress: () =>
                    GoRouter.of(context)
                        .push(TexteJuridique.confidentialite.chemin),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _saisie(BuildContext context, bool bureau, Widget? controle) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      ChampEntree(
        cle: 'questionnaire-acces-courriel',
        etiquette: t.connexion.courriel,
        indice: t.connexion.courrielIndice,
        controleur: _courriel,
        erreur: _erreur,
        onChanged: () => setState(() {}),
        onSoumettre: () => unawaited(_envoyerLien()),
        clavier: TextInputType.emailAddress,
        autofill: const <String>[AutofillHints.email],
      ),
      ?controle,
      Ecart.vLg,
      ActionsEntree(
        bureau: bureau,
        principale: ActionPrincipale(
          key: const ValueKey<String>('questionnaire-acces-envoyer'),
          libelle: t.connexion.envoyerLien,
          onPress: () => unawaited(_envoyerLien()),
          enCours: _envoi,
          affirmee: true,
          pleineLargeur: !bureau,
        ),
        secondaire: ActionPrincipale(
          key: const ValueKey<String>('questionnaire-acces-google'),
          libelle: t.connexion.avecGoogle,
          onPress: () => unawaited(_google()),
          enCours: _googleEnCours,
          niveau: NiveauAction.secondaire,
          pleineLargeur: !bureau,
          // Sur le violet du telephone, le logo se pose sur un disque blanc ;
          // sur le parchemin de l'ordinateur, il se pose seul (le disque y
          // prendrait le violet de `surfacePrimary`), comme la connexion.
          prefixe: bureau ? const LogoGoogle() : const _LogoGoogleSurBlanc(),
        ),
      ),
    ],
  );

  Widget _envoyeContenu(BuildContext context, bool bureau, Widget? controle) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String courriel = _courriel.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          liveRegion: true,
          child: Text(
            _renvoye
                ? t.connexion.renvoye(courriel: courriel)
                : t.connexion.lienEnvoyeDetail(courriel: courriel),
            key: const ValueKey<String>('questionnaire-acces-envoye'),
            style: textes.bodyLarge,
          ),
        ),
        if (_erreurRenvoi case final String e) ...<Widget>[
          Ecart.vMd,
          Semantics(
            liveRegion: true,
            child: Text(
              e,
              style: palette.inkAlert.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
        ],
        ?controle,
        Ecart.vXxl,
        // ALIGN-RENVOI (garde-cap, 04/11) : « Renvoyer le lien » prend la
        // largeur du champ, a l'ordinateur comme au telephone.
        ActionPrincipale(
          key: const ValueKey<String>('questionnaire-acces-renvoyer'),
          libelle: t.connexion.renvoyer,
          onPress: () => unawaited(_renvoyerLien()),
          enCours: _renvoi,
          niveau: NiveauAction.secondaire,
          pleineLargeur: true,
        ),
        Ecart.vLg,
        LienEntree(
          libelle: t.connexion.changerAdresse,
          onPress: () => setState(() {
            _envoye = false;
            _renvoye = false;
            _erreurRenvoi = null;
          }),
        ),
        LienEntree(libelle: t.connexion.probleme, onPress: _versRecuperation),
      ],
    );
  }
}

/// Le logo Google pose sur un disque blanc. Sur le violet de la marque, ses
/// couleurs officielles (bleu, rouge) se fondaient dans le fond (garde-cap,
/// 04/11) ; les regles de Google demandent un logo en couleur, lisible. Le
/// disque prend le blanc de la palette de la marque (`surfacePrimary`), et
/// le logo reste tel quel. Au telephone seulement : sur le parchemin de
/// l'ordinateur, `surfacePrimary` est violet.
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
