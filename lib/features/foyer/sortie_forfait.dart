// Sortie du forfait famille et delai (EA-8, planches 3.2 et 3.3, UX_REVIEW_07
// lignes 11 a 13) : « Retirer ma conjointe » ou « Retirer mon conjoint »
// (titulaire, depuis la ligne de la place de Ma famille) et « Quitter le
// forfait famille » (second adulte, depuis la ligne « Forfait famille » de Mon
// espace). Chaque sortie passe par une confirmation destructive qui dit ce
// qui ne change pas (F14, F15, textes du doc section 19), puis le resultat
// rendu par la reponse, sans « succes » ni coche (E7) : « Le rattachement au
// forfait famille a pris fin ». Le delai ouvert par la sortie se lit a la date
// RENDUE (F17), jamais calculee ; son detail est la page « Nouvelle invitation
// indisponible » (planche 3.3), ouverte depuis la ligne de la place (F21).
//
// Rien de recree (K-51) : `ConfirmDestructive`, `EcranResultat`,
// `EtatSysteme`, `PageShell`, `ActionPrincipale`, `AvatarTile`,
// `AppBottomSheet`, `LienFleche`, `BlocAsynchrone`, `Skeleton`, et les
// briques privees de l'invitation du titulaire (ce fichier en est une partie,
// comme l'acceptation d'EA-7).
//
// **Aucune source serveur a ce jour** : la sortie et ses notifications
// (EA-BR-21), la page Forfait famille du second adulte (EA-BR-22) rendent
// `CapaciteIndisponible`, la demonstration les surcharge (K-28).

part of 'invitation_conjoint.dart';

/// La reponse du serveur a une sortie (retrait ou depart), EA-BR-21.
sealed class ResultatSortie {
  const ResultatSortie();
}

/// Le rattachement a pris fin. [nouvelleDemandeLe] est la date que le serveur
/// rend pour le delai qui suit, telle quelle (F17), ou `null` s'il n'en rend
/// aucune.
final class SortieFaite extends ResultatSortie {
  /// Cree la reponse.
  const SortieFaite({this.nouvelleDemandeLe, this.foyerPersonnelCree = false});

  /// La date a partir de laquelle une nouvelle demande pourra etre deposee.
  final DateTime? nouvelleDemandeLe;

  /// BACK-FRONT-REPRISE-1 (K-65) : le serveur a cree un foyer personnel pour
  /// la personne qui sort. L'ecran l'explique ; jamais deduit cote client.
  final bool foyerPersonnelCree;
}

/// La connexion a coupe : la sortie n'est pas confirmee, l'ecran ne dit que
/// cela (decision D5) ; la meme cle rend une nouvelle tentative sure.
final class SortieEchecReseau extends ResultatSortie {
  /// Cree la reponse.
  const SortieEchecReseau();
}

/// La sortie du forfait famille (EA-BR-21) : idempotente par la cle fournie,
/// sans l'accord de l'autre adulte (F14), sans rien supprimer (F15), avec la
/// notification de l'autre adulte (F16).
abstract interface class PortSortieForfait {
  /// Le titulaire retire le second adulte de son foyer.
  Future<ResultatSortie> retirerSecondAdulte({required String cle});

  /// Le second adulte quitte le forfait famille.
  Future<ResultatSortie> quitterForfait({required String cle});
}

/// **Aucune source serveur a ce jour** (EA-BR-21).
class _SortieIndisponible implements PortSortieForfait {
  const _SortieIndisponible();

  @override
  Future<ResultatSortie> retirerSecondAdulte({required String cle}) =>
      Future<ResultatSortie>.error(const CapaciteIndisponible('EA-BR-21'));

  @override
  Future<ResultatSortie> quitterForfait({required String cle}) =>
      Future<ResultatSortie>.error(const CapaciteIndisponible('EA-BR-21'));
}

/// Le port de la sortie ; la demonstration le surcharge.
final Provider<PortSortieForfait> portSortieForfaitProvider =
    Provider<PortSortieForfait>((Ref _) => const _SortieIndisponible());

/// Ce que la page Forfait famille du second adulte lit : le seul prenom du
/// titulaire (EA-BR-22), rien du foyer ni des enfants (F6, F7).
@immutable
class ForfaitFamilleVM {
  /// Cree la vue.
  const ForfaitFamilleVM({required this.prenomTitulaire});

  /// Le prenom du titulaire du foyer.
  final String prenomTitulaire;
}

/// Le forfait famille du second adulte. **Aucune source serveur a ce jour**
/// (EA-BR-22) : `CapaciteIndisponible`.
final FutureProvider<ForfaitFamilleVM> forfaitFamilleProvider =
    FutureProvider<ForfaitFamilleVM>(
      (Ref _) => Future<ForfaitFamilleVM>.error(
        const CapaciteIndisponible('EA-BR-22'),
      ),
    );

/// La cle du resultat d'une sortie.
const Key sortieResultatKey = Key('sortie.resultat');

/// La place occupee, ouverte depuis sa ligne de Ma famille (titulaire) : le
/// prenom du second adulte, ses initiales (jamais sa photo, Q4, F6), et
/// « Retirer ma conjointe » ou « Retirer mon conjoint ».
class PlaceConjointPage extends StatelessWidget {
  /// Cree la page.
  const PlaceConjointPage({
    required this.placeFeminine,
    required this.prenom,
    required this.onRetour,
    required this.onCompris,
    super.key,
  });

  /// Vrai pour une conjointe, faux pour un conjoint (F3).
  final bool placeFeminine;

  /// Le prenom du second adulte, seul rendu (F6).
  final String prenom;

  /// Retour a Ma famille, avant la sortie.
  final VoidCallback onRetour;

  /// « Compris », apres le resultat : Ma famille relue.
  final VoidCallback onCompris;

  /// « Retirer ma conjointe » / « Retirer mon conjoint ».
  static const Key retirerKey = Key('sortie.retirer');

  @override
  Widget build(BuildContext context) {
    final bool f = placeFeminine;
    final String retirer = f
        ? t.adulte.sortie.retirerElle
        : t.adulte.sortie.retirerLui;
    return _PageSortie(
      titre: f
          ? t.adulte.famille.place.maConjointe(prenom: prenom)
          : t.adulte.famille.place.monConjoint(prenom: prenom),
      titreResultat: t.adulte.famille.maFamille,
      corps: Row(
        children: <Widget>[
          // Le second adulte : ses initiales, jamais sa photo (Q4).
          AvatarTile(prenom: prenom, diametre: AppSpacing.section),
          const SizedBox(width: AppSpacing.md),
          // Libelle provisoire, lexique D4.
          Expanded(
            child: _Note(
              texte: t.adulte.sortie.placePhrase(prenom: prenom),
              attenuee: true,
            ),
          ),
        ],
      ),
      boutonKey: retirerKey,
      libelleBouton: retirer,
      // Texte du doc section 19, mot pour mot ; le libelle de confirmation
      // nomme l'acte (UX_REVIEW_07 ligne 11 a).
      question: f
          ? t.adulte.sortie.retirerQuestionElle
          : t.adulte.sortie.retirerQuestionLui,
      consequence: t.adulte.sortie.retirerConsequence,
      libelleConfirmer: retirer,
      appel: (PortSortieForfait port, String cle) =>
          port.retirerSecondAdulte(cle: cle),
      echecTitre: t.adulte.sortie.retraitEchecTitre,
      // Ce qui reste, au passe de la reponse : libelle provisoire, lexique
      // D4 (doc section 9.3 accorde a la troisieme personne).
      resultatPhrase: t.adulte.sortie.resultatTitulaire,
      montrerDelai: true,
      onRetour: onRetour,
      onCompris: onCompris,
    );
  }
}

/// « Forfait famille », ouvert par le second adulte depuis Mon espace
/// (UX_REVIEW_07 ligne 5 c) : le forfait de qui, puis « Quitter le forfait
/// famille » et « Demande de reprise du foyer » (lien tertiaire, EA-11),
/// jamais sur Mon espace lui-meme.
class ForfaitFamillePage extends ConsumerWidget {
  /// Cree la page.
  const ForfaitFamillePage({
    required this.onRetour,
    required this.onCompris,
    this.onReprise,
    super.key,
  });

  /// Retour a Mon espace, avant la sortie.
  final VoidCallback onRetour;

  /// « Compris », apres le resultat : Mon espace relu.
  final VoidCallback onCompris;

  /// « Demande de reprise du foyer » (EA-11) ; sans lui, aucun lien.
  final VoidCallback? onReprise;

  /// « Quitter le forfait famille ».
  static const Key quitterKey = Key('sortie.quitter');

  /// « Demande de reprise du foyer ».
  static const Key repriseKey = Key('sortie.reprise');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ForfaitFamilleVM> lecture = ref.watch(
      forfaitFamilleProvider,
    );
    final String titre = t.adulte.famille.forfaitFamille;
    if (lecture.error is CapaciteIndisponible) {
      return PageShell(
        titre: titre,
        onRetour: onRetour,
        child: const EtatSysteme(
          nature: NatureEtat.indisponible,
          dependance: 'EA-BR-22',
        ),
      );
    }
    final ForfaitFamilleVM? vue = lecture.value;
    if (vue == null) {
      return PageShell(
        titre: titre,
        onRetour: onRetour,
        child: BlocAsynchrone<ForfaitFamilleVM>(
          valeur: lecture,
          squelette: const Skeleton.texte(lignes: 3),
          onReessayer: () => ref.invalidate(forfaitFamilleProvider),
          construire: (ForfaitFamilleVM _) => const SizedBox.shrink(),
        ),
      );
    }
    return _PageSortie(
      titre: titre,
      titreResultat: titre,
      // Libelle provisoire, lexique D4 (d'apres « Vous avez rejoint le
      // forfait famille de {prenom} », EA-7).
      corps: _Note(
        texte: t.adulte.sortie.forfaitPhrase(
          dePrenom: deDevant(vue.prenomTitulaire),
        ),
        attenuee: true,
      ),
      boutonKey: quitterKey,
      libelleBouton: t.adulte.sortie.quitter,
      // Textes du doc section 19 et d'UX_REVIEW_07 ligne 11 a.
      question: t.adulte.sortie.quitterQuestion,
      consequence: t.adulte.sortie.quitterConsequence,
      libelleConfirmer: t.adulte.sortie.quitterConfirmer,
      appel: (PortSortieForfait port, String cle) =>
          port.quitterForfait(cle: cle),
      echecTitre: t.adulte.sortie.departEchecTitre,
      // Doc section 9.3, mot pour mot.
      resultatPhrase: t.adulte.sortie.resultatSecondAdulte,
      // Le delai porte sur le foyer du titulaire, pas sur ce compte.
      montrerDelai: false,
      // La reprise du foyer : un lien tertiaire, apres la seule action
      // destructive (UX_REVIEW_07 ligne 5 c, EA-11). Nom du doc section 19.
      pied: switch (onReprise) {
        final VoidCallback ouvrir => LienFleche(
          key: repriseKey,
          libelle: t.adulte.reprise.titre,
          onPress: ouvrir,
        ),
        null => null,
      },
      onRetour: onRetour,
      onCompris: onCompris,
    );
  }
}

/// Une page de sortie : son objet, le bouton destructif au bord de fin, sa
/// confirmation, puis le resultat rendu par la reponse.
class _PageSortie extends ConsumerStatefulWidget {
  const _PageSortie({
    required this.titre,
    required this.titreResultat,
    required this.corps,
    required this.boutonKey,
    required this.libelleBouton,
    required this.question,
    required this.consequence,
    required this.libelleConfirmer,
    required this.appel,
    required this.echecTitre,
    required this.resultatPhrase,
    required this.montrerDelai,
    required this.onRetour,
    required this.onCompris,
    this.pied,
  });

  /// Un lien sous les actions, ou rien.
  final Widget? pied;

  final String titre;
  final String titreResultat;
  final Widget corps;
  final Key boutonKey;
  final String libelleBouton;
  final String question;
  final String consequence;
  final String libelleConfirmer;
  final Future<ResultatSortie> Function(PortSortieForfait port, String cle)
  appel;
  final String echecTitre;
  final String resultatPhrase;
  final bool montrerDelai;
  final VoidCallback onRetour;
  final VoidCallback onCompris;

  @override
  ConsumerState<_PageSortie> createState() => _PageSortieState();
}

class _PageSortieState extends ConsumerState<_PageSortie> {
  /// Une cle par page : une nouvelle tentative apres une coupure la reprend.
  final String _cle = const Uuid().v4();

  bool _envoi = false;
  _Echec? _echec;
  SortieFaite? _resultat;

  Future<void> _sortir() async {
    if (_envoi) return;
    final bool confirme = await ConfirmDestructive.demander(
      context,
      question: widget.question,
      consequence: widget.consequence,
      libelleConfirmer: widget.libelleConfirmer,
    );
    if (!confirme || !mounted || _envoi) return;
    // Le reseau a pu couper pendant la confirmation : « Rien n'est envoyé »
    // reste vrai (revue EA-R m13).
    if (ref.read(horsLigneProvider).value ?? false) return;
    setState(() {
      _envoi = true;
      _echec = null;
    });
    ResultatSortie resultat;
    try {
      resultat = await widget.appel(ref.read(portSortieForfaitProvider), _cle);
    } on CapaciteIndisponible {
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _echec = _Echec.indisponible;
      });
      return;
    } on Object {
      resultat = const SortieEchecReseau();
    }
    if (!mounted) return;
    setState(() {
      _envoi = false;
      switch (resultat) {
        case final SortieFaite faite:
          _resultat = faite;
        case SortieEchecReseau():
          _echec = _Echec.reseau;
      }
    });
    // Ma famille et Mon espace reliront l'etat rendu, jamais un etat garde.
    if (_resultat != null) {
      ref
        ..invalidate(foyerTitulaireProvider)
        ..invalidate(forfaitFamilleProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final SortieFaite? resultat = _resultat;
    if (resultat != null) {
      final DateTime? date = resultat.nouvelleDemandeLe;
      return PageShell(
        titre: widget.titreResultat,
        onRetour: widget.onCompris,
        child: _FocusALApparition(
          key: sortieResultatKey,
          child: Semantics(
            liveRegion: true,
            // Aucune coche, aucun « succes » (E7, planche 3.2 C2) ; la date
            // du delai seulement si la reponse la rend (F17).
            child: EcranResultat(
              icone: AppIcons.foyer,
              ton: TonEtat.neutre,
              titre: t.adulte.sortie.resultatTitre,
              phrase: resultat.foyerPersonnelCree
                  ? '${widget.resultatPhrase} ${t.adulte.sortie.foyerPersonnel}'
                  : widget.resultatPhrase,
              encart: widget.montrerDelai && date != null
                  ? t.adulte.sortie.delaiPhrase(date: dateEcheance(date))
                  : null,
              libelleAction: t.adulte.sortie.compris,
              onAction: widget.onCompris,
            ),
          ),
        ),
      );
    }
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    return PopScope(
      canPop: !_envoi,
      child: PageShell(
        titre: widget.titre,
        onRetour: _envoi ? null : widget.onRetour,
        child: _Colonne(
          auBordDeDebut: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              widget.corps,
              // D5 : la sortie n'est pas confirmee, rien de plus.
              if (_echec == _Echec.reseau) ...<Widget>[
                Ecart.vLg,
                _FocusALApparition(
                  key: InviterConjointPage.focusEchecKey,
                  child: EtatSysteme(
                    nature: NatureEtat.echecServeur,
                    titre: widget.echecTitre,
                    phrase: t.adulte.sortie.echecPhrase,
                  ),
                ),
              ] else if (_echec == _Echec.indisponible) ...<Widget>[
                Ecart.vLg,
                const EtatSysteme(
                  nature: NatureEtat.indisponible,
                  dependance: 'EA-BR-21',
                ),
              ],
              // Rien ne part tout seul. Libelle provisoire, lexique D4.
              if (horsLigne) ...<Widget>[
                Ecart.vLg,
                _Note(texte: t.adulte.sortie.horsLigne),
              ],
              Ecart.vLg,
              // Destructif : jamais un bouton plein (contrat B).
              _Actions(
                principale: ActionPrincipale(
                  key: widget.boutonKey,
                  libelle: widget.libelleBouton,
                  niveau: NiveauAction.destructive,
                  onPress: horsLigne || _echec == _Echec.indisponible
                      ? null
                      : () => unawaited(_sortir()),
                  enCours: _envoi,
                  pleineLargeur: false,
                ),
              ),
              if (widget.pied case final Widget pied)
                if (!_envoi) ...<Widget>[Ecart.vXxl, pied],
            ],
          ),
        ),
      ),
    );
  }
}

/// « Nouvelle invitation indisponible » (planche 3.3, UX_REVIEW_07 ligne
/// 13) : le detail de la ligne de la place pendant un delai. La date rendue,
/// en clair, le texte du doc section 19 mot pour mot, aucun bouton
/// d'invitation (R4, doc section 10.4).
class DelaiPlacePage extends StatelessWidget {
  /// Cree la page.
  const DelaiPlacePage({
    required this.possibleLe,
    required this.onRetour,
    super.key,
  });

  /// La date rendue par le serveur (F17), jamais calculee.
  final DateTime possibleLe;

  /// Retour a Ma famille.
  final VoidCallback onRetour;

  /// « Pourquoi cette attente ? ».
  static const Key pourquoiKey = Key('delai.pourquoi');

  /// « Revenir a Ma famille ».
  static const Key revenirKey = Key('delai.revenir');

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return PageShell(
      titre: t.adulte.sortie.delaiTitre,
      onRetour: onRetour,
      child: _Colonne(
        auBordDeDebut: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              t.adulte.sortie.delaiPhrase(date: dateEcheance(possibleLe)),
              style: palette.inkStrong.applyTo(
                textes.titleMedium ?? const TextStyle(),
              ),
            ),
            Ecart.vMd,
            // Un lien, une feuille d'une phrase (ligne 13 c) : le texte de la
            // planche 3.3, sans duree, libelle provisoire, lexique D4.
            LienFleche(
              key: pourquoiKey,
              libelle: t.adulte.sortie.pourquoi,
              onPress: () => unawaited(
                AppBottomSheet.ouvrir<void>(
                  context,
                  titre: t.adulte.sortie.pourquoi,
                  constructeur: (BuildContext contexte) => Text(
                    t.adulte.sortie.pourquoiPhrase,
                    style: AppPalette.of(contexte).surfaceRaised.applyTo(
                      Theme.of(contexte).textTheme.bodyLarge ??
                          const TextStyle(),
                    ),
                  ),
                ),
              ),
            ),
            Ecart.vLg,
            _Actions(
              principale: ActionPrincipale(
                key: revenirKey,
                libelle: t.adulte.invitation.revenirMaFamille,
                onPress: onRetour,
                pleineLargeur: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
