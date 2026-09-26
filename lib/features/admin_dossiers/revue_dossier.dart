import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/port_revue_dossiers.dart';
import '../../core/domain/enums.dart';
import '../../core/dossier/service_validation.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/status_pill.dart';
import 'textes_dossier.dart';

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

  /// Appele apres une decision reussie.
  final VoidCallback onDecision;

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
  final TextEditingController _motif = TextEditingController();
  bool _refusEnCours = false;
  bool _envoi = false;
  bool _perime = false;
  String? _erreur;

  @override
  void dispose() {
    for (final FocusNode n in _focus.values) {
      n.dispose();
    }
    _focusTitre.dispose();
    _motif.dispose();
    super.dispose();
  }

  FocusNode _noeud(String id) =>
      _focus.putIfAbsent(id, () => FocusNode(debugLabel: 'verification-$id'));

  bool _cochee(VerificationRevue v) =>
      v.modifiable ? _faites.contains(v.id) : v.etat == EtatVerification.faite;

  /// Les verifications obligatoires encore a faire, dans l'ordre.
  List<VerificationRevue> get _manquantes => <VerificationRevue>[
    for (final VerificationRevue v in widget.dossier.verifications)
      if (v.obligatoire && v.modifiable && !_faites.contains(v.id)) v,
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

  Future<void> _decider({required bool approuve}) async {
    final String? documentId = widget.dossier.documentId;
    if (documentId == null) {
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(serviceValidationProvider)
          .decider(
            documentId: documentId,
            approuve: approuve,
            motif: approuve ? null : _motif.text.trim(),
          );
      ref.invalidate(dossiersEnAttenteProvider);
      if (mounted) {
        widget.onDecision();
      }
    } on ErreurRevueDossier catch (e) {
      if (mounted) {
        setState(() {
          if (e.code == CodeErreurRevue.perime) {
            _perime = true;
          } else {
            _erreur = t.dossiers.erreur;
          }
        });
      }
    } on Object {
      if (mounted) {
        setState(() => _erreur = t.dossiers.erreur);
      }
    } finally {
      if (mounted) {
        setState(() => _envoi = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final DossierPourRevue d = widget.dossier;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final double section = MediaQuery.sizeOf(context).width >= 600
        ? AppSpacing.xxxl
        : AppSpacing.xxl;
    final String nom = '${d.prenom} ${d.nom}'.trim();
    final List<VerificationRevue> manquantes = _manquantes;
    final bool canalAbsent =
        d.documentId == null && d.exigencePiece == ExigencePiece.dispensee;
    final bool bloque = horsLigne || _envoi || _perime;
    final bool peutValider =
        d.peutValider &&
        manquantes.isEmpty &&
        d.documentId != null &&
        !canalAbsent &&
        !bloque;
    final bool peutRefuser = d.peutRefuser && !canalAbsent && !bloque;
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
        _CartePiece(dossier: d),
        if (d.verifications.isNotEmpty) ...<Widget>[
          SizedBox(height: section),
          GroupeReglages(
            titre: t.dossiers.verifications,
            lignes: <LigneRubrique>[
              for (final VerificationRevue v in d.verifications)
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
        if (_perime) ...<Widget>[
          Ecart.vLg,
          Semantics(
            liveRegion: true,
            child: EtatSysteme(
              nature: NatureEtat.ressourceExpiree,
              titre: t.dossiers.revue.etats.modifie,
              phrase: '',
              libelleAction: t.dossiers.revue.etats.actualiserDossier,
              onAction: widget.onActualiser,
            ),
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
                onPress: peutRefuser
                    ? () => setState(() => _refusEnCours = true)
                    : null,
              ),
            ),
            IntrinsicWidth(
              child: ActionPrincipale(
                libelle: t.dossiers.approuver,
                pleineLargeur: false,
                enCours: _envoi && !_refusEnCours,
                onPress: peutValider
                    ? () => unawaited(_decider(approuve: true))
                    : null,
              ),
            ),
          ],
        ),
        _RaisonsDecision(
          horsLigne: horsLigne,
          dossier: d,
          canalAbsent: canalAbsent,
          verificationsManquantes: manquantes.isNotEmpty,
          onReessayer: widget.onActualiser,
          onAllerPremiere: _allerPremiere,
        ),
        if (_refusEnCours && peutRefuser) ...<Widget>[
          Ecart.vLg,
          TextField(
            controller: _motif,
            onChanged: (String _) => setState(() {}),
            maxLines: 2,
            decoration: InputDecoration(labelText: t.dossiers.motif),
          ),
          Ecart.vSm,
          Text(t.dossiers.motifRequis, style: textes.bodySmall),
          Ecart.vMd,
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: IntrinsicWidth(
              child: ActionPrincipale(
                libelle: t.dossiers.refuser,
                enCours: _envoi,
                niveau: NiveauAction.destructive,
                pleineLargeur: false,
                onPress: _motif.text.trim().isEmpty
                    ? null
                    : () => unawaited(_decider(approuve: false)),
              ),
            ),
          ),
        ],
        if (_erreur != null) ...<Widget>[
          Ecart.vMd,
          Text(
            _erreur!,
            style: palette.inkAlert.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
      ],
    );
  }

  LigneRubrique _ligneVerification(VerificationRevue v, AppPalette palette) {
    final bool cochee = _cochee(v);
    return LigneRubrique(
      libelle: libelleVerification(v.id),
      cochee: cochee,
      focusNode: _noeud(v.id),
      onPress: v.modifiable
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
/// validite.
String libelleVerification(String id) => switch (id) {
  'lisible' => t.dossiers.pointLisible,
  'nom' => t.dossiers.pointNom,
  _ => t.dossiers.pointValidite,
};

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
  const _CartePiece({required this.dossier});

  final DossierPourRevue dossier;

  @override
  Widget build(BuildContext context) {
    final TypePiece? type = dossier.typePiece;
    final LigneRubrique ligne = switch (dossier.etatPiece) {
      EtatPieceRevue.disponible => LigneRubrique(
        icone: AppIcons.dossiers,
        libelle: type == null ? t.dossiers.revue.piece : libelleTypePiece(type),
        // « Voir la piece » attend la visionneuse d'AD-7 (AD-BR-03).
        legende: t.dossiers.revue.pieceIndisponible,
        controle: ActionPrincipale(
          libelle: t.dossiers.revue.voirPiece,
          niveau: NiveauAction.tertiaire,
          pleineLargeur: false,
          onPress: null,
        ),
      ),
      EtatPieceRevue.nonVisible => LigneRubrique(
        icone: AppIcons.dossiers,
        libelle: t.dossiers.pieceNonVisible,
      ),
      EtatPieceRevue.absente || EtatPieceRevue.nonRequise => LigneRubrique(
        icone: AppIcons.dossiers,
        libelle: t.dossiers.sansPiece,
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
    required this.canalAbsent,
    required this.verificationsManquantes,
    required this.onReessayer,
    required this.onAllerPremiere,
  });

  final bool horsLigne;
  final DossierPourRevue dossier;
  final bool canalAbsent;
  final bool verificationsManquantes;
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
    } else if (b.contains(BlocageRevue.decisionIndisponible) || canalAbsent) {
      raison = Text(t.dossiers.revue.etats.decisionIndisponible, style: style);
    } else if (b.contains(BlocageRevue.accordManquant)) {
      raison = Text(t.dossiers.revue.etats.accordManquant, style: style);
    } else if (b.isNotEmpty) {
      raison = Text(t.dossiers.revue.pasPret, style: style);
    } else if (verificationsManquantes) {
      raison = Semantics(
        link: true,
        child: LienFleche(
          libelle: t.dossiers.revue.etats.verificationsIncompletes,
          onPress: onAllerPremiere,
          fleche: false,
        ),
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

/// Le genre du lecteur manque : l'etat actuel, sans action (AD-9).
class GenreManquant extends StatelessWidget {
  /// Cree l'etat.
  const GenreManquant({super.key});

  @override
  Widget build(BuildContext context) => EmptyState(
    message: t.dossiers.genreManquant,
    icone: AppIcons.avertissement,
  );
}
