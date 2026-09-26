import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/port_revue_dossiers.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/status_pill.dart';
import 'decision_dossier.dart';
import 'file_dossiers.dart' show actualiserDossiers;
import 'surfaces_decision.dart';
import 'textes_dossier.dart';
import 'visionneuse_piece.dart';

/// La revue d'un dossier (`ADM-02B`, AD-6), lue par le port. Ordre de
/// lecture : titre, statut, identite, piece, verifications, accords, puis
/// decision et ses raisons.
///
/// Les DECISIONS restent jusqu'a AD-8 sur `ServiceValidation.decider` :
/// `decider_dossier` en production, le pont de demonstration sinon.
class RevueDossier extends ConsumerStatefulWidget {
  /// Cree la revue. A cle par dossier et revision : les cases repartent
  /// vides a chaque dossier et a chaque nouvelle revision.
  const RevueDossier({
    required this.dossier,
    required this.onDecision,
    required this.onActualiser,
    this.avecTitre = true,
    super.key,
  });

  /// Le dossier revu, tel que le port le rend.
  final DossierPourRevue dossier;

  /// Appele apres une decision confirmee par le serveur, avec le message du
  /// retour local (« Dossier refuse. » ou « Dossier valide. »).
  final void Function(String message) onDecision;

  /// Relit le dossier (hors ligne, dossier modifie).
  final VoidCallback onActualiser;

  /// Faux en panneau unique : le titre est deja dans l'en-tete de page.
  final bool avecTitre;

  @override
  ConsumerState<RevueDossier> createState() => _RevueDossierState();
}

class _RevueDossierState extends ConsumerState<RevueDossier> {
  /// Jamais precochees : vide a chaque creation d'etat.
  final Set<String> _faites = <String>{};
  final Map<String, FocusNode> _focus = <String, FocusNode>{};
  final FocusNode _focusTitre = FocusNode(debugLabel: 'adm02b-titre');
  final FocusNode _focusVoirPiece = FocusNode(debugLabel: 'adm02b-voir-piece');
  final FocusNode _focusRefuser = FocusNode(debugLabel: 'adm02b-refuser');
  final FocusNode _focusValider = FocusNode(debugLabel: 'adm02b-valider');

  /// Le motif de 02D, detenu ici : conserve tant que la revue vit (cle
  /// dossier + revision), sauf « Abandonner ».
  final TextEditingController _motif = TextEditingController();
  bool _decide = false;

  /// Vrai tant que 02D ou 02E est ouverte : le statut n'est dit qu'une fois.
  bool _surfaceOuverte = false;

  /// La visionneuse a affiche la piece (P-ADM-06 point 5) ; retombe a faux
  /// sur un echec de lecture.
  bool _pieceLue = false;

  /// Les verifications s'ouvrent : pas de lecture exigee, ou piece lue.
  bool get _lectureFaite => !widget.dossier.lectureRequise || _pieceLue;

  @override
  void dispose() {
    for (final FocusNode n in _focus.values) {
      n.dispose();
    }
    _focusTitre.dispose();
    _focusVoirPiece.dispose();
    _focusRefuser.dispose();
    _focusValider.dispose();
    _motif.dispose();
    super.dispose();
  }

  /// Ouvre la visionneuse puis rend le focus a « Voir la piece », quel que
  /// soit le chemin de fermeture (repli sur le titre si le bouton a disparu).
  Future<void> _voirPiece() async {
    await ouvrirVisionneusePiece(
      context,
      dossier: widget.dossier,
      onLecture: (bool lue) {
        if (mounted && lue != _pieceLue) {
          setState(() {
            _pieceLue = lue;
            // Un echec de lecture referme les cases deja cochees.
            if (!lue) {
              _faites.clear();
            }
          });
        }
      },
    );
    if (!mounted) {
      return;
    }
    (_focusVoirPiece.context != null ? _focusVoirPiece : _focusTitre)
        .requestFocus();
  }

  FocusNode _noeud(String id) =>
      _focus.putIfAbsent(id, () => FocusNode(debugLabel: 'verification-$id'));

  /// Modifiable par le port ET piece lue quand la lecture est exigee.
  bool _modifiable(VerificationRevue v) => v.modifiable && _lectureFaite;

  bool _cochee(VerificationRevue v) => _modifiable(v)
      ? _faites.contains(v.id)
      : v.modifiable
      ? false
      : v.etat == EtatVerification.faite;

  /// Les verifications obligatoires encore a faire, dans l'ordre.
  List<VerificationRevue> get _manquantes => <VerificationRevue>[
    for (final VerificationRevue v in widget.dossier.verifications)
      if (v.obligatoire && _modifiable(v) && !_faites.contains(v.id)) v,
  ];

  void _allerPremiere() {
    final List<VerificationRevue> m = _manquantes;
    if (m.isEmpty) {
      return;
    }
    final FocusNode n = _noeud(m.first.id)..requestFocus();
    final BuildContext? c = n.context;
    if (c != null) {
      unawaited(
        Scrollable.ensureVisible(
          c,
          duration: AppMouvement.mouvementReduit(context)
              ? Duration.zero
              : AppMouvement.navigation,
        ),
      );
    }
  }

  /// Ouvre 02D ou 02E, puis rend le focus au declencheur (repli : titre).
  Future<void> _ouvrir(DecisionDossier decision) async {
    final bool refus = decision == DecisionDossier.refuser;
    // Une commande close (echec, conflit...) laissee par une surface fermee
    // est oubliee : la nouvelle ouverture repart d'une confirmation neuve.
    ref
        .read(decisionsDossiersProvider.notifier)
        .oublier(widget.dossier.dossierId);
    setState(() => _surfaceOuverte = true);
    await ouvrirDecision(
      context,
      dossier: widget.dossier,
      decision: decision,
      verifications: <String>{..._faites},
      motif: refus ? _motif : null,
    );
    if (mounted) {
      setState(() => _surfaceOuverte = false);
    }
    // Apres une decision, le focus appartient a la page (dossier suivant).
    if (!mounted || _decide) {
      return;
    }
    final FocusNode n = refus ? _focusRefuser : _focusValider;
    (n.context != null ? n : _focusTitre).requestFocus();
  }

  /// Apres confirmation serveur seulement : le message du retour local.
  void _surDecision(EtatDecision? avant, EtatDecision? apres) {
    if (apres is! DecisionReussie) {
      return;
    }
    final String message = apres.commande.decision == DecisionDossier.refuser
        ? t.dossiers.refus.succes
        : t.dossiers.validation.succes;
    _decide = true;
    actualiserDossiers(ref);
    widget.onDecision(message);
  }

  @override
  Widget build(BuildContext context) {
    final DossierPourRevue d = widget.dossier;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    ref.listen<EtatDecision?>(
      decisionsDossiersProvider.select(
        (Map<String, EtatDecision> m) => m[widget.dossier.dossierId],
      ),
      _surDecision,
    );
    final EtatDecision? commande = ref.watch(
      decisionsDossiersProvider.select(
        (Map<String, EtatDecision> m) => m[widget.dossier.dossierId],
      ),
    );
    final bool nonResolue = commande?.nonResolue ?? false;
    final double section = MediaQuery.sizeOf(context).width >= 600
        ? AppSpacing.xxxl
        : AppSpacing.xxl;
    final String nom = '${d.prenom} ${d.nom}'.trim();
    final List<VerificationRevue> manquantes = _manquantes;

    final bool bloque = horsLigne || nonResolue;
    final bool validationIndeterminee =
        d.consequence == ConsequenceValidation.indeterminee;
    final bool peutValider =
        d.peutValider &&
        _lectureFaite &&
        manquantes.isEmpty &&
        (d.documentId != null || d.etatPiece == EtatPieceRevue.nonRequise) &&
        !validationIndeterminee &&
        !bloque;
    final bool peutRefuser = d.peutRefuser && !bloque;
    final List<AccordSoumis> acceptes = <AccordSoumis>[
      for (final AccordSoumis a in d.accords)
        if (a.etat == EtatAccord.accepte) a,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.avecTitre) ...<Widget>[
          Focus(
            focusNode: _focusTitre,
            child: Semantics(
              header: true,
              child: Text(titreRevue(nom), style: textes.headlineSmall),
            ),
          ),
          Ecart.vSm,
        ],
        Text(
          t.dossiers.file.legende(
            type: typeDossier(d.role),
            date: t.dossiers.deposeLe(date: dateRevue(d.soumisLeUtc)),
          ),
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vSm,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: StatusPill(
            libelle: t.dossiers.file.enVerification,
            ton: TonEtat.accent,
          ),
        ),
        SizedBox(height: section),
        _CarteIdentite(dossier: d),
        SizedBox(height: section),
        _CartePiece(
          dossier: d,
          focusNode: _focusVoirPiece,
          onVoirPiece: () => unawaited(_voirPiece()),
        ),
        if (d.etatPiece != EtatPieceRevue.nonRequise) ...<Widget>[
          SizedBox(height: section),
          GroupeReglages(
            titre: t.dossiers.verifications,
            lignes: <LigneRubrique>[
              if (d.verifications.isEmpty)
                for (final String id in _verificationsAffichees)
                  _ligneInactive(id, palette)
              else
                for (final VerificationRevue v in d.verifications)
                  if (libelleVerification(v.id) != null)
                    _ligneVerification(v, palette),
            ],
          ),
        ],
        if (acceptes.isNotEmpty) ...<Widget>[
          SizedBox(height: section),
          GroupeReglages(
            titre: t.dossiers.revue.accords,
            lignes: <LigneRubrique>[
              for (final AccordSoumis a in acceptes)
                LigneRubrique(libelle: libelleAccord(a.sorte)),
            ],
          ),
        ],
        Ecart.vLg,
        Wrap(
          alignment: WrapAlignment.end,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          // IntrinsicWidth : le bouton au contenu (le Container centre
          // d'ActionPrincipale s'etirerait sinon a la largeur du Wrap).
          children: <Widget>[
            IntrinsicWidth(
              child: ActionPrincipale(
                libelle: t.dossiers.refuser,
                niveau: NiveauAction.destructive,
                pleineLargeur: false,
                focusNode: _focusRefuser,
                onPress: peutRefuser
                    ? () => unawaited(_ouvrir(DecisionDossier.refuser))
                    : null,
              ),
            ),
            IntrinsicWidth(
              child: ActionPrincipale(
                libelle: t.dossiers.approuver,
                pleineLargeur: false,
                focusNode: _focusValider,
                onPress: peutValider
                    ? () => unawaited(_ouvrir(DecisionDossier.valider))
                    : null,
              ),
            ),
          ],
        ),
        if (!_surfaceOuverte &&
            (commande is DecisionInconnue ||
                commande is DecisionVerification)) ...<Widget>[
          Ecart.vXs,
          // Surface fermee : le statut reste sous les actions (P-ADM-10.6).
          Semantics(
            liveRegion: true,
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              children: <Widget>[
                Text(
                  commande!.commande.decision == DecisionDossier.refuser
                      ? t.dossiers.refus.inconnu
                      : t.dossiers.validation.inconnu,
                  style: palette.inkMuted.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
                ActionPrincipale(
                  libelle: t.dossiers.decision.verifierResultat,
                  niveau: NiveauAction.tertiaire,
                  pleineLargeur: false,
                  enCours: commande is DecisionVerification,
                  onPress: commande is DecisionVerification
                      ? null
                      : () => unawaited(
                          ref
                              .read(decisionsDossiersProvider.notifier)
                              .verifier(d.dossierId),
                        ),
                ),
              ],
            ),
          ),
        ],
        _RaisonsDecision(
          horsLigne: horsLigne,
          dossier: d,

          lectureAttendue: !_lectureFaite,
          verificationsManquantes: manquantes.isNotEmpty,
          validationIndeterminee: validationIndeterminee,
          onReessayer: widget.onActualiser,
          onAllerPremiere: _allerPremiere,
        ),
      ],
    );
  }

  /// Une verification que ce dossier n'ouvre pas : non cochee, non pressable.
  LigneRubrique _ligneInactive(String id, AppPalette palette) => LigneRubrique(
    libelle: libelleVerification(id)!,
    cochee: false,
    meneur: ExcludeSemantics(
      child: IconTheme(
        data: palette.borderStrong.asIconTheme(size: AppSpacing.xxl),
        child: Icon(AppIcons.succes.resoudre(selectionne: false)),
      ),
    ),
  );

  LigneRubrique _ligneVerification(VerificationRevue v, AppPalette palette) {
    final bool cochee = _cochee(v);
    return LigneRubrique(
      libelle: libelleVerification(v.id)!,
      cochee: cochee,
      focusNode: _noeud(v.id),
      onPress: _modifiable(v)
          ? () => setState(() {
              if (!_faites.remove(v.id)) {
                _faites.add(v.id);
              }
            })
          : null,
      meneur: ExcludeSemantics(
        child: IconTheme(
          data: cochee
              ? palette.inkAccent.asIconTheme(size: AppSpacing.xxl)
              : palette.borderStrong.asIconTheme(size: AppSpacing.xxl),
          child: Icon(AppIcons.succes.resoudre(selectionne: cochee)),
        ),
      ),
    );
  }
}

/// Le libelle d'une verification, dans l'ordre du code : lisible, nom,
/// validite. Un identifiant inconnu n'a pas de libelle : il n'est pas
/// affiche, plutot que d'emprunter celui d'une autre verification.
String? libelleVerification(String id) => switch (id) {
  'lisible' => t.dossiers.pointLisible,
  'nom' => t.dossiers.pointNom,
  'validite' => t.dossiers.pointValidite,
  _ => null,
};

/// Les verifications montrees sans case active quand le dossier n'en ouvre
/// aucune (piece absente ou hors de portee) : la carte reste, la raison est
/// dite sous les actions (§10.4, §26 ter).
const List<String> _verificationsAffichees = <String>[
  'lisible',
  'nom',
  'validite',
];

class _CarteIdentite extends StatelessWidget {
  const _CarteIdentite({required this.dossier});

  final DossierPourRevue dossier;

  @override
  Widget build(BuildContext context) => GroupeReglages(
    titre: t.dossiers.revue.identite,
    lignes: <LigneRubrique>[
      if (dossier.nom.trim().isNotEmpty)
        LigneRubrique(libelle: t.dossiers.revue.nom, valeur: dossier.nom),
      if (dossier.prenom.trim().isNotEmpty)
        LigneRubrique(libelle: t.dossiers.revue.prenom, valeur: dossier.prenom),
      LigneRubrique(
        libelle: t.dossiers.revue.typeDossier,
        valeur: typeDossier(dossier.role),
      ),
      LigneRubrique(
        libelle: t.dossiers.revue.dateDepot,
        valeur: dateRevue(dossier.soumisLeUtc),
      ),
      LigneRubrique(
        libelle: t.dossiers.revue.etatDossier,
        valeur: t.dossiers.file.enVerification,
      ),
    ],
  );
}

class _CartePiece extends StatelessWidget {
  const _CartePiece({
    required this.dossier,
    required this.focusNode,
    required this.onVoirPiece,
  });

  final DossierPourRevue dossier;
  final FocusNode focusNode;
  final VoidCallback onVoirPiece;

  @override
  Widget build(BuildContext context) {
    final TypePiece? type = dossier.typePiece;
    final LigneRubrique ligne = switch (dossier.etatPiece) {
      EtatPieceRevue.disponible => LigneRubrique(
        icone: AppIcons.dossiers,
        libelle: type == null ? t.dossiers.revue.piece : libelleTypePiece(type),
        // AD-7 : la visionneuse (lecture et zoom seulement).
        controle: ActionPrincipale(
          libelle: t.dossiers.revue.voirPiece,
          niveau: NiveauAction.tertiaire,
          pleineLargeur: false,
          focusNode: focusNode,
          onPress: dossier.peutVoirPiece ? onVoirPiece : null,
        ),
      ),
      EtatPieceRevue.nonVisible => LigneRubrique(
        icone: AppIcons.dossiers,
        libelle: t.dossiers.pieceNonVisible,
      ),
      EtatPieceRevue.absente => LigneRubrique(
        icone: AppIcons.dossiers,
        libelle: t.dossiers.revue.pieceNonTransmise,
      ),
      EtatPieceRevue.nonRequise => LigneRubrique(
        icone: AppIcons.dossiers,
        libelle: t.dossiers.revue.pieceNonRequise,
      ),
    };
    return GroupeReglages(
      titre: t.dossiers.revue.piece,
      lignes: <LigneRubrique>[ligne],
    );
  }
}

/// Les raisons sous les actions, a 4, annoncees (liveRegion).
class _RaisonsDecision extends StatelessWidget {
  const _RaisonsDecision({
    required this.horsLigne,
    required this.dossier,
    required this.lectureAttendue,
    required this.verificationsManquantes,
    required this.validationIndeterminee,
    required this.onReessayer,
    required this.onAllerPremiere,
  });

  final bool horsLigne;
  final DossierPourRevue dossier;

  /// La piece doit etre vue avant de verifier (production, AD-7).
  final bool lectureAttendue;
  final bool verificationsManquantes;

  /// La consequence de la validation est inconnue : 02E ne s'ouvre pas
  /// (13.4, Q21).
  final bool validationIndeterminee;
  final VoidCallback onReessayer;
  final VoidCallback onAllerPremiere;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle style = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final List<BlocageRevue> b = dossier.blocagesValidation;
    Widget? raison;
    if (horsLigne) {
      raison = Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.sm,
        children: <Widget>[
          Text(t.dossiers.revue.etats.horsLigne, style: style),
          ActionPrincipale(
            libelle: t.commun.reessayer,
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
            onPress: onReessayer,
          ),
        ],
      );
    } else if (b.contains(BlocageRevue.decisionIndisponible)) {
      raison = Text(t.dossiers.revue.etats.decisionIndisponible, style: style);
    } else if (b.contains(BlocageRevue.accordManquant)) {
      raison = Text(t.dossiers.revue.etats.accordManquant, style: style);
    } else if (validationIndeterminee && dossier.peutValider) {
      raison = Text(t.dossiers.validation.indisponible, style: style);
    } else if (b.contains(BlocageRevue.pieceAbsente)) {
      raison = Text(
        t.dossiers.revue.pieceNonTransmise,
        style: style,
        textAlign: TextAlign.end,
      );
    } else if (b.isNotEmpty || lectureAttendue) {
      raison = Text(t.dossiers.revue.pasPret, style: style);
    } else if (verificationsManquantes) {
      raison = LienFleche(
        libelle: t.dossiers.revue.etats.verificationsIncompletes,
        onPress: onAllerPremiere,
        fleche: false,
        annonceLien: true,
        alignerEnFin: true,
      );
    }
    final bool refusFerme = !dossier.peutRefuser && !horsLigne;
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (raison != null) ...<Widget>[Ecart.vXs, raison],
          if (refusFerme) ...<Widget>[
            Ecart.vXs,
            Text(
              t.dossiers.revue.etats.refusNonAutorise,
              style: style,
              textAlign: TextAlign.end,
            ),
          ],
        ],
      ),
    );
  }
}

/// Le genre du lecteur manque, politique activee (spec 15.3, AD-9). SANS
/// « Completer mon profil » : `/compte/profil` n'a pas de champ genre et le
/// relecteur ne doit pas le modifier lui-meme (15.3, AD-BR-20).
class GenreManquant extends StatelessWidget {
  /// Cree l'etat.
  const GenreManquant({super.key});

  @override
  Widget build(BuildContext context) => EtatSysteme(
    nature: NatureEtat.accesRefuse,
    titre: t.dossiers.profilACompleter.titre,
    phrase: t.dossiers.profilACompleter.texte,
  );
}
