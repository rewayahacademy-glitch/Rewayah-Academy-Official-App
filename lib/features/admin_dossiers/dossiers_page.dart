import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/capacites/port_revue_dossiers.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pied_de_liste.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import '../../core/widgets/status_pill.dart';
import 'acces_piece_kyc.dart';
import 'decision_dossier.dart';
import 'detail_dossier.dart';
import 'etat_file_dossiers.dart';
import 'file_dossiers.dart';
import 'textes_dossier.dart';

/// Le plafond du dossier ouvert : il ne s'etire pas sur un grand ecran.
const double largeurDetailDossier = 728;

/// `ADM-02A` : la file des dossiers a valider, et le dossier ouvert.
///
/// Orchestration seule : la file vient du port (`PortRevueDossiers`, K-09),
/// le dossier de la revue existante (AD-6).
///
/// L5 des listes (02/11/2026, DECISION-LISTES §5 quater.10 quinquies) : la
/// liste est la page, comme Classes, Comptes, Classes a ouvrir et l'Espace de
/// traitement. Le maitre-detail d'avant (une file de 336 et un dossier de
/// 728, chacun son defilement) est retire (DECISION-DEFILEMENT-2026-11-01 :
/// une seule barre de defilement par ecran) : la ligne ouvre le dossier sur
/// la meme route, en page, comme le faisait deja le repli du telephone, et
/// le retour ramene a la liste, le focus sur la ligne. **Aucun apercu de la
/// piece dans la liste**, et **aucune case a cocher** (DEC:24 : jamais de
/// decision groupee sur des dossiers d'identite) : la piece ne se voit que
/// dans le dossier, avec ses verifications.
class DossiersPage extends ConsumerStatefulWidget {
  /// Cree l'ecran de validation.
  const DossiersPage({super.key, this.profilId, this.horloge = DateTime.now});

  /// Le dossier a ouvrir (ligne de l'Accueil), passe par `extra`.
  final String? profilId;

  /// D'ou vient l'instant courant : « Aujourd'hui » et « Hier » se comptent
  /// en jours.
  final DateTime Function() horloge;

  /// La liste.
  static const Key cleFile = ValueKey<String>('adm02a-file');

  /// La cle d'une ligne.
  static ValueKey<String> cleLigne(String id) =>
      ValueKey<String>('adm02a-ligne-$id');

  @override
  ConsumerState<DossiersPage> createState() => _DossiersPageState();
}

class _DossiersPageState extends ConsumerState<DossiersPage> {
  /// Vrai juste apres la fermeture du dossier : le focus revient a la ligne.
  bool _retourDetail = false;

  /// Le message du retour local apres une decision (AD-8).
  String? _retour;

  /// Le titre de la page : il recoit le focus apres une decision sans
  /// dossier suivant (AD-FOCUS-MD).
  final FocusNode _focusTitre = FocusNode(debugLabel: 'adm02a-titre');

  @override
  void dispose() {
    _focusTitre.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final String? cible = widget.profilId;
    if (cible != null) {
      // L'Accueil et l'Espace de traitement ouvrent ce dossier (AD-S).
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

  /// Apres une decision : relire, revenir a la liste, le focus sur la ligne
  /// suivante de l'ancien ordre (la ligne decidee a disparu), ou sur le
  /// titre quand il n'y en a pas.
  void _apresDecision(String id, String message) {
    // Le retour local, apres confirmation serveur seulement. Remis a nul
    // d'abord : deux decisions de suite rejouent l'apparition.
    setState(() => _retour = null);
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) {
        setState(() => _retour = message);
      }
    });
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
    setState(() => _retourDetail = true);
    if (suivant != null) {
      selection.choisir(suivant.dossierId);
    } else {
      selection.retirer();
      _focusAuTitre();
    }
  }

  /// AD-FOCUS-MD : sans dossier suivant (file videe, ou dernier dossier
  /// d'une file non vide), aucune ligne n'est retenue : le focus va au titre
  /// de la page au lieu de se perdre.
  void _focusAuTitre() {
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) {
        _focusTitre.requestFocus();
      }
    });
  }

  void _ouvrir(DossierEnFile d) {
    setState(() => _retourDetail = false);
    ref
        .read(selectionDossierProvider.notifier)
        .choisir(d.dossierId, ouvrir: true);
  }

  @override
  Widget build(BuildContext context) {
    // Les decisions en cours sont portees par la page (pas par la feuille
    // ni par la revue) : leur suivi survit a la fermeture des surfaces.
    ref.listen(decisionsDossiersProvider, (Object? _, Object? _) {});
    final SelectionDossier selection = ref.watch(selectionDossierProvider);
    final List<DossierEnFile> elements =
        ref.watch(fileDossiersProvider).value?.elements ?? <DossierEnFile>[];
    final String? id = selection.dossierId;
    final bool detailOuvert = selection.detailOuvert && id != null;

    return PopScope(
      canPop: !detailOuvert,
      onPopInvokedWithResult: (bool fait, Object? _) {
        if (!fait && detailOuvert) {
          _fermerDetail();
        }
      },
      child: detailOuvert ? _detail(id, elements) : _liste(selection, id),
    );
  }

  /// Le dossier ouvert, en page : son titre, le retour vers la liste.
  Widget _detail(String id, List<DossierEnFile> elements) {
    final String? nom = elements
        .where((DossierEnFile d) => d.dossierId == id)
        .map((DossierEnFile d) => d.nomAffiche)
        .firstOrNull;
    return PageShell(
      titre: nom != null ? titreRevue(nom) : t.dossiers.titre,
      onRetour: _fermerDetail,
      focusTitre: _focusTitre,
      entete: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SousNavigationDomaine(onglets: ongletsPersonnes(), indexActif: 0),
          const BandeauExceptionKyc(),
        ],
      ),
      defilante: false,
      child: SingleChildScrollView(
        key: ValueKey<String>('adm02a-detail-$id'),
        // Le dossier ne s'etire pas : plafond 728, aligne au debut.
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: largeurDetailDossier),
            child: DetailDossier(
              id: id,
              avecTitre: false,
              onDecision: _apresDecision,
            ),
          ),
        ),
      ),
    );
  }

  /// La liste, pleine largeur : la page.
  Widget _liste(SelectionDossier selection, String? id) {
    final AsyncValue<EtatFile> file = ref.watch(fileDossiersProvider);
    final bool actualisation = file.hasValue && file.isLoading;
    return PageShell(
      titre: t.dossiers.titre,
      focusTitre: _focusTitre,
      // La sous-navigation Personnes tient lieu de titre (§5 ter.2).
      entete: SousNavigationDomaine(onglets: ongletsPersonnes(), indexActif: 0),
      // LISTES-2 et LISTES-3 : la tete defile avec la liste, qui prend toute
      // la largeur au bureau, sans retour (la barre laterale navigue).
      teteAvecLaListe: true,
      listeBureau: true,
      // `DataCollection` porte le defilement de la page (une seule barre).
      defilante: false,
      child: ColonneCorps(
        children: <Widget>[Expanded(child: _corps(file, actualisation, id))],
      ),
    );
  }

  Widget _corps(AsyncValue<EtatFile> file, bool actualisation, String? id) {
    // Une actualisation qui echoue garde la liste deja autorisee (§26 ter) :
    // l'etat d'erreur se pose au-dessus. Seul un refus d'acces ou un profil a
    // completer la remplace.
    final Object? erreur = file.error;
    final bool garderListe =
        file.hasValue &&
        file.hasError &&
        !file.isLoading &&
        erreur is! ErreurRevueDossier;
    final AsyncValue<EtatFile> valeur = garderListe
        ? AsyncData<EtatFile>(file.requireValue)
        : file;
    void reessayer() => actualiserDossiers(ref);

    final Widget tete = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const BandeauExceptionKyc(),
        LocalFeedback(message: _retour),
        // La relecture dite au debut (le lecteur d'ecran l'entend ; le
        // nombre, le pied le dit), Actualiser au bord de fin. A l'etroit, le
        // bouton passe dessous, toujours au bord de fin (contrat B, Q18).
        OverflowBar(
          alignment: MainAxisAlignment.spaceBetween,
          overflowAlignment: OverflowBarAlignment.end,
          spacing: AppSpacing.sm,
          overflowSpacing: AppSpacing.sm,
          children: <Widget>[
            Semantics(
              liveRegion: true,
              child: Text(
                actualisation ? t.dossiers.file.actualisation : '',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            IntrinsicWidth(
              child: ActionPrincipale(
                libelle: t.dossiers.file.actualiser,
                niveau: NiveauAction.tertiaire,
                pleineLargeur: false,
                enCours: actualisation,
                onPress: reessayer,
              ),
            ),
          ],
        ),
        Ecart.vSm,
        if (garderListe) ...<Widget>[
          etatErreurDossiers(context, ref, erreur!, reessayer) ??
              EtatSysteme(
                nature: NatureEtat.echecServeur,
                titre: t.dossiers.file.erreur,
                phrase: '',
                libelleAction: t.commun.etats.actions.reessayer,
                onAction: reessayer,
              ),
          Ecart.vLg,
        ],
      ],
    );

    final EtatFile? etat = valeur.hasError ? null : valeur.value;
    if (etat == null || etat.elements.isEmpty) {
      // Chargement, echec, file vide : la page fait defiler sa tete et cet
      // etat ensemble (jamais un cadre de hauteur fixe).
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            tete,
            BlocAsynchrone<EtatFile>(
              valeur: valeur,
              squelette: const SqueletteFile(),
              titreProlonge: t.dossiers.file.chargementProlonge,
              titreEchec: t.dossiers.file.erreur,
              onReessayer: reessayer,
              erreurVersEtat: (Object e, VoidCallback? r) =>
                  etatErreurDossiers(context, ref, e, r),
              estVide: (EtatFile e) => e.elements.isEmpty,
              vide: EmptyState(
                message: t.dossiers.aucun,
                invitation: t.dossiers.aucunDetail,
                icone: AppIcons.dossiers,
              ),
              construire: (EtatFile _) => const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }

    final DateTime maintenant = widget.horloge();
    final List<DossierEnFile> lignes = etat.elements;
    return DataCollection<DossierEnFile>(
      key: DossiersPage.cleFile,
      // LISTES-2 et LISTES-3 (§5 quater) : la tete defile avec les lignes ;
      // au bureau, des cartes sous des en-tetes discrets ; au telephone, des
      // lignes denses.
      prendTeteDePage: true,
      tete: tete,
      densiteTelephone: true,
      lignesCartes: true,
      lignes: lignes,
      cle: (DossierEnFile d) => DossiersPage.cleLigne(d.dossierId),
      onSelectionner: _ouvrir,
      // Retour du dossier, ou decision : le focus sur la ligne retenue.
      auFocus: (DossierEnFile d) => _retourDetail && d.dossierId == id,
      colonnes: <ColonneDonnees<DossierEnFile>>[
        ColonneDonnees<DossierEnFile>(
          titre: t.admin.traitement.cleConcerne,
          role: RoleColonne.identifiante,
          flex: 3,
          texte: (DossierEnFile d) => nomOuDefaut(d.nomAffiche),
          rendu: (BuildContext _, DossierEnFile d) => _Identite(dossier: d),
        ),
        ColonneDonnees<DossierEnFile>(
          titre: t.dossiers.revue.piece,
          // Au telephone, la pastille passe sous le nom, avec la date : a
          // cote du nom, elle ne tenait pas (390 et 320).
          role: RoleColonne.aPart,
          flex: 2,
          texte: (DossierEnFile d) => pastilleDossier(d).$1,
          rendu: (BuildContext _, DossierEnFile d) {
            final (String libelle, TonEtat ton) = pastilleDossier(d);
            return StatusPill(libelle: libelle, ton: ton);
          },
        ),
        ColonneDonnees<DossierEnFile>(
          titre: t.admin.traitement.cleDepot,
          flex: 2,
          tabulaire: true,
          texte: (DossierEnFile d) => quandDepuis(d.soumisLeUtc, maintenant),
        ),
      ],
      // Les dossiers deja lus, et le total quand le serveur le garantit ; la
      // suite se charge par le curseur du serveur, sous la derniere ligne.
      piedDePage: _suite(etat),
      piedCollant: PiedDeListe(
        key: const ValueKey<String>('adm02a-pied'),
        debut: 1,
        fin: lignes.length,
        total: etat.total ?? lignes.length,
      ),
    );
  }

  /// « Charger les dossiers suivants », ou l'echec de cette lecture.
  Widget? _suite(EtatFile e) {
    if (e.erreurSuite) {
      return EtatSysteme(
        nature: NatureEtat.echecServeur,
        titre: t.dossiers.file.suivantsErreur,
        phrase: '',
        libelleAction: t.commun.etats.actions.reessayer,
        onAction: () => unawaited(
          ref.read(fileDossiersProvider.notifier).chargerSuivants(),
        ),
      );
    }
    if (!e.aSuite) return null;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: ActionPrincipale(
        libelle: t.dossiers.file.suivants,
        niveau: NiveauAction.secondaire,
        pleineLargeur: false,
        enCours: e.chargeSuite,
        onPress: () => unawaited(
          ref.read(fileDossiersProvider.notifier).chargerSuivants(),
        ),
      ),
    );
  }
}

/// La cellule d'identite : le nom, lu « Ouvrir le dossier de {nom} » (la
/// ligne ouvre le dossier). Aucun apercu de la piece.
class _Identite extends StatelessWidget {
  const _Identite({required this.dossier});

  final DossierEnFile dossier;

  @override
  Widget build(BuildContext context) {
    final String nom = nomOuDefaut(dossier.nomAffiche);
    return Semantics(
      // Sans nom, « Dossier sans nom disponible » seul : aucun texte compose
      // hors spec.
      label: dossier.nomAffiche.trim().isEmpty ? nom : ouvrirDossier(nom),
      excludeSemantics: true,
      child: Text(nom, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}
