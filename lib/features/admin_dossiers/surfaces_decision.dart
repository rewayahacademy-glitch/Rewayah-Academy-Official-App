// Les surfaces de decision (AD-8) : refus ADM-02D et validation ADM-02E.
// Toutes deux par `AppBottomSheet.ouvrir` (aucun fork) : seul le contenu est
// nouveau. L'envoi passe par le port, l'etat vit dans
// `decisionsDossiersProvider` (porte par la page).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/port_revue_dossiers.dart';
import '../../core/formulaires/motifs_proposes.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/recrutement/port_statuts_signature.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/selecteur_motif.dart';
import 'decision_dossier.dart';
import 'file_dossiers.dart' show actualiserDossiers;
import 'textes_dossier.dart';

/// Ouvre la surface de decision d'un dossier. [motif] est detenu par la
/// revue (conserve tant qu'elle vit, sauf « Abandonner ») ; exige pour un
/// refus. Se termine a la fermeture de la surface, quel qu'en soit le chemin.
Future<void> ouvrirDecision(
  BuildContext context, {
  required DossierPourRevue dossier,
  required DecisionDossier decision,
  required Set<String> verifications,
  TextEditingController? motif,
}) async {
  final bool refus = decision == DecisionDossier.refuser;
  assert(!refus || motif != null, 'un refus exige un controleur de motif');
  final _EtatSurface surface = _EtatSurface();
  await AppBottomSheet.ouvrir<void>(
    context,
    titre: refus ? t.dossiers.refus.titre : t.dossiers.validation.titre,
    constructeur: (BuildContext _) => _Corps(
      dossier: dossier,
      decision: decision,
      motif: motif,
      surface: surface,
    ),
    actions: (BuildContext _) => _Actions(
      dossier: dossier,
      decision: decision,
      verifications: verifications,
      motif: motif,
      surface: surface,
    ),
  );
}

/// L'erreur locale du motif, partagee entre le corps et les actions.
///
/// ponytail: jamais dispose explicitement -- la future d'`ouvrir` se complete
/// au pop, AVANT l'animation de sortie qui lit encore ce notifiant. Sans
/// ressource native (le FocusNode du champ est detenu par le corps), le
/// ramasse-miettes suffit.
class _EtatSurface extends ChangeNotifier {
  bool _erreurVide = false;

  /// Pose par le corps : ramene le focus dans la zone du motif (la premiere
  /// puce, ou le champ libre si « Autre » est ouvert).
  VoidCallback? focaliserChamp;

  bool get erreurVide => _erreurVide;

  set erreurVide(bool v) {
    if (v != _erreurVide) {
      _erreurVide = v;
      notifyListeners();
    }
  }
}

String _nom(DossierPourRevue d) =>
    t.dossiers.decision.nomComplet(prenom: d.prenom, nom: d.nom).trim();

/// Le message de l'etat, ou nul.
String? _message(
  EtatDecision? e, {
  required bool refus,
  required bool horsLigne,
}) => switch (e) {
  null when horsLigne =>
    refus ? t.dossiers.refus.horsLigne : t.dossiers.validation.horsLigne,
  DecisionEchec() when horsLigne =>
    refus ? t.dossiers.refus.horsLigne : t.dossiers.validation.horsLigne,
  DecisionEchec(code: CodeErreurRevue.motifTropLong) =>
    t.dossiers.refus.tropLong,
  DecisionEchec() =>
    refus ? t.dossiers.refus.erreur : t.dossiers.validation.erreur,
  DecisionConflit() => t.dossiers.decision.conflit,
  DecisionInconnue() || DecisionVerification() =>
    refus ? t.dossiers.refus.inconnu : t.dossiers.validation.inconnu,
  DecisionInterdite() =>
    refus ? t.dossiers.refus.interdit : t.dossiers.validation.interdit,
  DecisionIndisponible() =>
    refus ? t.dossiers.refus.indisponible : t.dossiers.validation.indisponible,
  DecisionContratNonSigne(:final List<ManqueSignature> manque) =>
    '${t.recrutement.statuts.refuse} ${_manque(manque)}',
  DecisionPlusPrete() => t.dossiers.validation.plusPret,
  DecisionTraitee() => t.dossiers.decision.dejaTraite,
  _ => null,
};

String _manque(List<ManqueSignature> manque) {
  final bool contrat = manque.contains(ManqueSignature.contrat);
  final bool accuse = manque.contains(ManqueSignature.accuse);
  return contrat && accuse
      ? t.recrutement.statuts.manqueLesDeux
      : contrat
      ? t.recrutement.statuts.manqueContrat
      : accuse
      ? t.recrutement.statuts.manqueAccuse
      : '';
}

class _Corps extends ConsumerStatefulWidget {
  const _Corps({
    required this.dossier,
    required this.decision,
    required this.motif,
    required this.surface,
  });

  final DossierPourRevue dossier;
  final DecisionDossier decision;
  final TextEditingController? motif;
  final _EtatSurface surface;

  @override
  ConsumerState<_Corps> createState() => _CorpsState();
}

class _CorpsState extends ConsumerState<_Corps> {
  final FocusNode _champ = FocusNode(debugLabel: 'adm02d-motif');
  final GlobalKey<SelecteurMotifEtat> _selecteur =
      GlobalKey<SelecteurMotifEtat>();

  /// Le focus dans la zone du motif (clavier, lecteur d'ecran).
  void _focaliserMotif() => _selecteur.currentState?.focaliser();

  DossierPourRevue get dossier => widget.dossier;
  TextEditingController? get motif => widget.motif;
  _EtatSurface get surface => widget.surface;
  bool get _refus => widget.decision == DecisionDossier.refuser;

  @override
  void initState() {
    super.initState();
    surface.focaliserChamp = _focaliserMotif;
  }

  @override
  void dispose() {
    surface.focaliserChamp = null;
    _champ.dispose();
    super.dispose();
  }

  Future<void> _demanderAbandon(BuildContext context) async {
    final bool? abandon = await AppBottomSheet.ouvrir<bool>(
      context,
      titre: t.dossiers.refus.abandonQuestion,
      constructeur: (BuildContext _) => const SizedBox.shrink(),
      actions: (BuildContext c) => _AvecFocus(
        constructeur: (FocusNode n) => _RangeeActions(
          enfants: <Widget>[
            ActionPrincipale(
              libelle: t.dossiers.refus.continuerSaisie,
              niveau: NiveauAction.tertiaire,
              pleineLargeur: false,
              focusNode: n,
              onPress: () => Navigator.of(c).pop(false),
            ),
            ActionPrincipale(
              libelle: t.dossiers.refus.abandonner,
              niveau: NiveauAction.destructive,
              pleineLargeur: false,
              onPress: () => Navigator.of(c).pop(true),
            ),
          ],
        ),
      ),
    );
    if (abandon ?? false) {
      motif?.clear();
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } else if (context.mounted) {
      // « Continuer la saisie » : retour dans la zone du motif.
      _focaliserMotif();
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final EtatDecision? e = ref.watch(
      decisionsDossiersProvider.select(
        (Map<String, EtatDecision> m) => m[dossier.dossierId],
      ),
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final String? message = _message(e, refus: _refus, horsLigne: horsLigne);
    final Widget statut = message == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsetsDirectional.only(top: AppSpacing.lg),
            child: Semantics(
              liveRegion: true,
              child: Text(
                message,
                style:
                    (e is DecisionEchec ? palette.inkAlert : palette.inkMuted)
                        .applyTo(textes.bodyMedium ?? const TextStyle()),
              ),
            ),
          );

    if (!_refus) {
      final String nom = nomOuDefaut(_nom(dossier));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // HL-A-5 : meme anatomie que 02D, une ligne de contexte douce.
          Text(
            t.dossiers.refus.nomType(nom: nom, type: typeDossier()),
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vSm,
          Text(
            corpsValidation(
              nom,
              activation:
                  dossier.consequence ==
                  ConsequenceValidation.activationPossible,
            ),
            style: textes.bodyMedium,
          ),
          statut,
        ],
      );
    }

    final TextEditingController champ = motif!;
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[champ, surface]),
      builder: (BuildContext context, Widget? _) => PopScope(
        canPop: champ.text.trim().isEmpty || (e?.nonResolue ?? false),
        onPopInvokedWithResult: (bool fait, Object? _) {
          if (!fait) {
            unawaited(_demanderAbandon(context));
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              t.dossiers.refus.nomType(
                nom: nomOuDefaut(_nom(dossier)),
                type: typeDossier(),
              ),
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
            Ecart.vSm,
            Text(t.dossiers.refus.corps, style: textes.bodyMedium),
            Ecart.vLg,
            SelecteurMotif(
              key: _selecteur,
              motifs: MotifsProposes.refusDossier(),
              controleur: champ,
              focusNode: _champ,
              // 02D s'ouvre sur la zone du motif : la premiere puce, ou le
              // champ si « Autre » est deja ouvert (motif conserve).
              autofocus: true,
              // HL-A-5 : le motif envoye (ou dont le resultat est inconnu)
              // ne se modifie plus ; etat de rendu seulement.
              lectureSeule:
                  e is DecisionEnvoi ||
                  e is DecisionInconnue ||
                  e is DecisionVerification,
              lignesMin: 3,
              lignesMax: 8,
              // AD-11 (1.4.4) : le libelle du champ libre passe a la ligne.
              libelleChamp: t.dossiers.refus.champ,
              aide: t.dossiers.refus.aide,
              erreur: surface.erreurVide ? t.dossiers.refus.erreurVide : null,
              onChange: (String v) {
                if (v.isNotEmpty) {
                  surface.erreurVide = false;
                }
              },
            ),
            statut,
          ],
        ),
      ),
    );
  }
}

/// Les actions : Wrap a la fin, secondaire puis principale, 8 d'ecart. Sur
/// mobile (HL-A-5, reference CL-4.7), empilees en pleine largeur, l'action
/// qui confirme (la derniere) en haut.
class _RangeeActions extends StatelessWidget {
  const _RangeeActions({required this.enfants});

  final List<Widget> enfants;

  @override
  Widget build(BuildContext context) {
    if (AppGabarit.de(context) == Gabarit.mobile) {
      final List<Widget> ordre = enfants.reversed.toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < ordre.length; i++) ...<Widget>[
            if (i > 0) Ecart.vSm,
            ordre[i],
          ],
        ],
      );
    }
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (final Widget e in enfants) IntrinsicWidth(child: e),
      ],
    );
  }
}

/// Donne un noeud focalise apres la premiere image (ActionPrincipale n'a
/// pas d'autofocus).
class _AvecFocus extends StatefulWidget {
  const _AvecFocus({required this.constructeur});

  final Widget Function(FocusNode noeud) constructeur;

  @override
  State<_AvecFocus> createState() => _AvecFocusState();
}

class _AvecFocusState extends State<_AvecFocus> {
  final FocusNode _noeud = FocusNode(debugLabel: 'surface-autofocus');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted && _noeud.context != null) {
        _noeud.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _noeud.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.constructeur(_noeud);
}

class _Actions extends ConsumerStatefulWidget {
  const _Actions({
    required this.dossier,
    required this.decision,
    required this.verifications,
    required this.motif,
    required this.surface,
  });

  final DossierPourRevue dossier;
  final DecisionDossier decision;
  final Set<String> verifications;
  final TextEditingController? motif;
  final _EtatSurface surface;

  @override
  ConsumerState<_Actions> createState() => _ActionsState();
}

class _ActionsState extends ConsumerState<_Actions> {
  final FocusNode _annuler = FocusNode(debugLabel: 'surface-annuler');
  final FocusNode _etat = FocusNode(debugLabel: 'surface-action-etat');

  bool get _refus => widget.decision == DecisionDossier.refuser;
  String get _id => widget.dossier.dossierId;

  @override
  void initState() {
    super.initState();
    if (!_refus) {
      // 02E : le focus va sur Annuler, jamais sur Valider.
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted && _annuler.context != null) {
          _annuler.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _annuler.dispose();
    _etat.dispose();
    super.dispose();
  }

  void _fermer() {
    if (mounted) {
      unawaited(Navigator.of(context).maybePop());
    }
  }

  void _fermerApres(EtatDecision e) {
    if (e is DecisionReussie &&
        mounted &&
        (ModalRoute.of(context)?.isCurrent ?? false)) {
      Navigator.of(context).pop();
    }
  }

  void _confirmer(EtatDecision? e) {
    // L'etat capture a la construction peut etre perime (double tap, Entree
    // repetee avant la reconstruction) : on relit l'etat courant.
    if ((ref.read(horsLigneProvider).value ?? false) ||
        (ref.read(decisionsDossiersProvider)[_id]?.nonResolue ?? false)) {
      return;
    }
    final TextEditingController? motif = widget.motif;
    if (_refus && (motif == null || motif.text.trim().isEmpty)) {
      widget.surface.erreurVide = true;
      widget.surface.focaliserChamp?.call();
      return;
    }
    final CommandeDecision c = e is DecisionEchec
        // Reessayer : la MEME commande, la meme charge (P-ADM-10.5).
        ? e.commande
        : CommandeDecision(
            dossierId: _id,
            revision: widget.dossier.revision,
            decision: widget.decision,
            verifications: widget.verifications,
            motif: _refus ? motif!.text : null,
          );
    unawaited(
      ref
          .read(decisionsDossiersProvider.notifier)
          .envoyer(c)
          .then(_fermerApres),
    );
  }

  void _verifier() => unawaited(
    ref
        .read(decisionsDossiersProvider.notifier)
        .verifier(_id)
        .then(_fermerApres),
  );

  /// Actualiser, retour aux dossiers, fermer : on oublie et on relit.
  void _relire({bool purgerMotif = false}) {
    ref.read(decisionsDossiersProvider.notifier).oublier(_id);
    actualiserDossiers(ref);
    if (purgerMotif) {
      widget.motif?.clear();
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _annulerCommande() {
    ref.read(decisionsDossiersProvider.notifier).oublier(_id);
    _fermer();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<EtatDecision?>(
      decisionsDossiersProvider.select((Map<String, EtatDecision> m) => m[_id]),
      (EtatDecision? avant, EtatDecision? apres) {
        if (apres.runtimeType != avant.runtimeType) {
          WidgetsBinding.instance.addPostFrameCallback((Duration _) {
            if (mounted && _etat.context != null) {
              _etat.requestFocus();
            }
          });
        }
      },
    );
    final EtatDecision? e = ref.watch(
      decisionsDossiersProvider.select((Map<String, EtatDecision> m) => m[_id]),
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final String libelle = _refus ? t.dossiers.refuser : t.dossiers.approuver;
    final NiveauAction niveau = _refus
        ? NiveauAction.destructive
        : NiveauAction.principale;

    Widget unique(String l, VoidCallback f, {NiveauAction? n}) =>
        _RangeeActions(
          enfants: <Widget>[
            ActionPrincipale(
              libelle: l,
              niveau: n ?? NiveauAction.secondaire,
              pleineLargeur: false,
              focusNode: _etat,
              onPress: f,
            ),
          ],
        );

    return switch (e) {
      // Le dossier a change ou ete traite : l'ancien motif ne vaut plus
      // (en production la revision reste 0, la cle de la revue ne change pas).
      DecisionConflit() ||
      DecisionPlusPrete() ||
      DecisionContratNonSigne() => unique(
        t.dossiers.revue.etats.actualiserDossier,
        () => _relire(purgerMotif: true),
      ),
      DecisionTraitee() => unique(
        t.dossiers.revue.etats.retourDossiers,
        () => _relire(purgerMotif: true),
      ),
      DecisionInterdite() => unique(
        t.commun.fermer,
        () => _relire(purgerMotif: true),
      ),
      DecisionIndisponible() => unique(t.commun.annuler, _annulerCommande),
      // AD-NETTOYAGE-2 (n8) : la surface se ferme d'elle-meme apres une
      // decision reussie ; si elle reste affichee un instant, Confirmer ne
      // doit pas rester actif.
      DecisionReussie() => unique(t.commun.fermer, _fermer),
      DecisionInconnue() || DecisionVerification() => _RangeeActions(
        enfants: <Widget>[
          ActionPrincipale(
            libelle: t.commun.fermer,
            niveau: NiveauAction.secondaire,
            pleineLargeur: false,
            onPress: e is DecisionVerification ? null : _fermer,
          ),
          ActionPrincipale(
            libelle: t.dossiers.decision.verifierResultat,
            pleineLargeur: false,
            focusNode: _etat,
            enCours: e is DecisionVerification,
            onPress: e is DecisionVerification ? null : _verifier,
          ),
        ],
      ),
      _ => _RangeeActions(
        enfants: <Widget>[
          ActionPrincipale(
            libelle: t.commun.annuler,
            // HL-A-5 : Annuler en tertiaire dans 02D comme dans 02E (meme
            // anatomie). Le destructif reste un texte (jamais d'aplat rouge,
            // contrat d'ActionPrincipale).
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
            focusNode: _annuler,
            // Pendant l'envoi, Annuler laisserait croire a une annulation
            // (Q-AD8-8) : Echap et retour ferment sans rien annuler.
            onPress: e is DecisionEnvoi ? null : _annulerCommande,
          ),
          // Hors ligne, la decision ne peut pas partir : le bouton n'est
          // pas rendu, le message au-dessus dit quand reessayer (lib/CLAUDE.md,
          // BOUTONS-GRISES-1, jamais grise). Un envoi deja parti reste
          // affiche, en cours, sans repartir.
          if (!horsLigne || e is DecisionEnvoi)
            ActionPrincipale(
              libelle: switch (e) {
                DecisionEnvoi() =>
                  _refus ? t.dossiers.refus.envoi : t.dossiers.validation.envoi,
                DecisionEchec() => t.commun.reessayer,
                _ => libelle,
              },
              niveau: niveau,
              pleineLargeur: false,
              focusNode: e is DecisionEchec ? _etat : null,
              enCours: e is DecisionEnvoi,
              onPress: e is DecisionEnvoi ? null : () => _confirmer(e),
            ),
        ],
      ),
    };
  }
}
