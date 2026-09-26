import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/capacites/port_revue_dossiers.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import 'detail_dossier.dart';
import 'etat_file_dossiers.dart';
import 'file_dossiers.dart';
import 'textes_dossier.dart';

/// Largeur de la file en maitre-detail (contrat D, bureau 1440).
const double largeurFileDossiers = 336;

/// Ecart entre la file et le detail.
const double ecartFileDetail = 24;

/// Largeur du panneau de detail.
const double largeurDetailDossier = 728;

/// `ADM-02A` : la file des dossiers a valider, et son detail.
///
/// Orchestration seule : la file vient du port (`PortRevueDossiers`, K-09),
/// le detail de la revue existante (AD-6 la refondra). A partir de 1088 de
/// largeur utile et sous 200 % de texte, maitre-detail 336 / 24 / 728 ;
/// sinon, repli sequentiel sur la meme route (liste, puis detail).
class DossiersPage extends ConsumerStatefulWidget {
  /// Cree l'ecran de validation.
  const DossiersPage({super.key, this.profilId});

  /// Le dossier a ouvrir (ligne de l'Accueil), passe par `extra`.
  final String? profilId;

  @override
  ConsumerState<DossiersPage> createState() => _DossiersPageState();
}

class _DossiersPageState extends ConsumerState<DossiersPage> {
  /// Vrai juste apres la fermeture du detail : le focus revient a la ligne.
  bool _retourDetail = false;

  @override
  void initState() {
    super.initState();
    final String? cible = widget.profilId;
    if (cible != null) {
      // L'Accueil ouvre ce dossier, quelle que soit la largeur (AD-S).
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted) {
          ref
              .read(selectionDossierProvider.notifier)
              .choisir(cible, ouvrir: true);
        }
      });
    }
  }

  void _fermerDetail() {
    setState(() => _retourDetail = true);
    ref.read(selectionDossierProvider.notifier).fermerDetail();
  }

  /// Apres une decision : relire, puis passer au suivant de l'ancien ordre.
  /// Deux panneaux : le suivant est selectionne et annonce (§26 ter,
  /// « Dossier suivant : {nom} »). Panneau unique : retour a la liste, le
  /// focus sur la ligne suivante (la ligne decidee a disparu).
  void _apresDecision(String id, {required bool maitreDetail}) {
    final List<DossierEnFile> avant =
        ref.read(fileDossiersProvider).value?.elements ?? <DossierEnFile>[];
    final int i = avant.indexWhere((DossierEnFile d) => d.dossierId == id);
    final DossierEnFile? suivant = i >= 0 && i + 1 < avant.length
        ? avant[i + 1]
        : null;
    actualiserDossiers(ref);
    final SelectionDossierNotifier selection = ref.read(
      selectionDossierProvider.notifier,
    );
    if (maitreDetail && suivant != null) {
      selection.choisir(suivant.dossierId);
      unawaited(
        SemanticsService.sendAnnouncement(
          View.of(context),
          t.dossiers.file.suivantAnnonce(nom: nomOuDefaut(suivant.nomAffiche)),
          Directionality.of(context),
        ),
      );
    } else if (maitreDetail) {
      selection.retirer();
    } else {
      setState(() => _retourDetail = true);
      if (suivant != null) {
        selection.choisir(suivant.dossierId);
      } else {
        selection.retirer();
      }
    }
  }

  /// Le mode mesure dans le corps (largeur utile du PageShell), retenu pour
  /// le titre et le retour, poses au-dessus de lui.
  bool _maitreDetail = false;

  void _signalerMode(bool maitreDetail) {
    if (maitreDetail != _maitreDetail) {
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted && maitreDetail != _maitreDetail) {
          setState(() => _maitreDetail = maitreDetail);
        }
      });
    }
  }

  void _choisir(String id, {required bool maitreDetail}) {
    setState(() => _retourDetail = false);
    ref
        .read(selectionDossierProvider.notifier)
        .choisir(id, ouvrir: !maitreDetail);
  }

  @override
  Widget build(BuildContext context) {
    final SelectionDossier selection = ref.watch(selectionDossierProvider);
    final List<DossierEnFile> elements =
        ref.watch(fileDossiersProvider).value?.elements ?? <DossierEnFile>[];
    final bool texteGrand = MediaQuery.textScalerOf(context).scale(1) >= 2.0;
    final String? id = selection.dossierId;
    final bool detailSeul =
        !_maitreDetail && selection.detailOuvert && id != null;
    final String? nom = id == null
        ? null
        : elements
              .where((DossierEnFile d) => d.dossierId == id)
              .map((DossierEnFile d) => nomOuDefaut(d.nomAffiche))
              .firstOrNull;

    return PopScope(
      canPop: !detailSeul,
      onPopInvokedWithResult: (bool fait, Object? _) {
        if (!fait && detailSeul) {
          _fermerDetail();
        }
      },
      child: PageShell(
        titre: detailSeul && nom != null ? titreDossier(nom) : t.dossiers.titre,
        sousTitre: detailSeul ? null : t.dossiers.sousTitre,
        onRetour: detailSeul ? _fermerDetail : null,
        entete: SousNavigationDomaine(
          onglets: ongletsPersonnes(),
          indexActif: 0,
        ),
        defilante: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints contraintes) {
            final bool md =
                !texteGrand &&
                contraintes.maxWidth >=
                    largeurFileDossiers +
                        ecartFileDetail +
                        largeurDetailDossier;
            _signalerMode(md);
            if (md) {
              return _MaitreDetail(
                selection: selection,
                elements: elements,
                onChoisir: (String x) => _choisir(x, maitreDetail: true),
                onDecision: (String x) => _apresDecision(x, maitreDetail: true),
              );
            }
            if (selection.detailOuvert && id != null) {
              return SingleChildScrollView(
                key: ValueKey<String>('adm02a-detail-$id'),
                child: DetailDossier(
                  id: id,
                  onDecision: (String x) =>
                      _apresDecision(x, maitreDetail: false),
                ),
              );
            }
            return SingleChildScrollView(
              key: const PageStorageKey<String>('adm02a-file'),
              child: FileDossiers(
                selection: id,
                marquerSelection: false,
                focusSurSelection: _retourDetail,
                onChoisir: (String x) => _choisir(x, maitreDetail: false),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MaitreDetail extends ConsumerStatefulWidget {
  const _MaitreDetail({
    required this.selection,
    required this.elements,
    required this.onChoisir,
    required this.onDecision,
  });

  final SelectionDossier selection;
  final List<DossierEnFile> elements;
  final void Function(String id) onChoisir;
  final void Function(String id) onDecision;

  @override
  ConsumerState<_MaitreDetail> createState() => _MaitreDetailState();
}

class _MaitreDetailState extends ConsumerState<_MaitreDetail> {
  @override
  Widget build(BuildContext context) {
    final String? id = widget.selection.dossierId;
    // Selection automatique du premier, une fois, sans focus ni appel de plus.
    if (id == null &&
        !widget.selection.autoFaite &&
        widget.elements.isNotEmpty) {
      final String premier = widget.elements.first.dossierId;
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted) {
          ref.read(selectionDossierProvider.notifier).choisirAuto(premier);
        }
      });
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: largeurFileDossiers,
          child: SingleChildScrollView(
            key: const PageStorageKey<String>('adm02a-file'),
            child: FileDossiers(selection: id, onChoisir: widget.onChoisir),
          ),
        ),
        const SizedBox(width: ecartFileDetail),
        SizedBox(
          width: largeurDetailDossier,
          child: SingleChildScrollView(
            key: ValueKey<String?>(id),
            child: id == null
                ? const AucuneSelection()
                : DetailDossier(id: id, onDecision: widget.onDecision),
          ),
        ),
      ],
    );
  }
}
