// La nouvelle publication de la Communaute (`PostComposerEntry`, spec
// section 5.3, section 18 « Composer communautaire », section 19).
//
// UNE seule entree, « Nouvelle publication » (`EntreeNouvellePublication`,
// posee en bas du flux, `flux_publications.dart`), et UN seul composer : texte,
// categorie, piece jointe autorisee, publication. Rien d'autre : ni prix, ni
// produit, ni boutique, ni lien de promotion, ni « Promouvoir »,
// « Sponsoriser » ou « Contacter en prive » (spec section 5.3). Le meme
// composant sert le telephone (surface focalisee, une tache) et l'ordinateur
// (colonne « Publication/Reponses »).
//
// Formulaire (K-57) : la categorie est DEDUITE de la categorie ouverte dans
// le flux, sinon CHOISIE parmi celles du port ; le titre et le texte sont
// SAISIS, car c'est le contenu meme de la publication. Le texte et le titre
// sont gardes en brouillon de session (`PortBrouillons`) et restaures a la
// reouverture.
//
// « Publiee » n'est dit qu'apres l'accuse du serveur ; un echec dit « pas
// encore confirmee », jamais un faux succes (R-COM-05, COM-BR-02).
//
// Garde anti-promotion (COM-COMU-2, `CommunityPromotionGuard`) : la politique
// est rappelee en tete (« Partage pedagogique uniquement »). Avant tout
// envoi, le brouillon passe par `PortGardePromotion` : un verdict
// « avertissement », « lien affilie » ou « vente » RETIENT la publication,
// le garde le dit en bas du formulaire, pres de « Publier », avec son motif
// et l'etat des liens ; rien ne part, aucun succes n'est affiche (R-COM-05,
// R-COM-06). Le garde ne detecte rien lui-meme. Sans contrat (COM-BR-07,
// port neutre) ou s'il ne repond pas, le composer ne pretend pas avoir relu
// la publication : il la transmet, et le serveur reste seul juge.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/communications/modeles_communication.dart';
import '../../core/communications/port_brouillons.dart';
import '../../core/communications/port_pieces_jointes.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/communications/carte_piece_jointe.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/section_header.dart';
import 'garde_promotion.dart';
import 'port_communaute.dart';
import 'port_garde_promotion.dart';

/// Le composer d'une nouvelle publication.
class ComposerPublication extends ConsumerStatefulWidget {
  /// Cree le composer.
  const ComposerPublication({
    required this.categories,
    required this.onPubliee,
    required this.onFermer,
    super.key,
    this.categorieInitiale,
  });

  /// Les categories proposees, dans l'ordre du port.
  final List<CategorieCommunaute> categories;

  /// La categorie deduite du flux, s'il y en a une.
  final String? categorieInitiale;

  /// La publication confirmee par le serveur.
  final ValueChanged<PublicationCommunaute> onPubliee;

  /// Ferme le composer sans publier (le brouillon reste).
  final VoidCallback onFermer;

  /// Cles, pour les tests.
  static const ValueKey<String> cleTitre = ValueKey<String>(
    'communaute-composer-titre',
  );

  /// La cle du champ de texte.
  static const ValueKey<String> cleTexte = ValueKey<String>(
    'communaute-composer-texte',
  );

  /// La cle de l'action « Publier ».
  static const ValueKey<String> clePublier = ValueKey<String>(
    'communaute-composer-publier',
  );

  /// La cle du bouton qui ferme le composer.
  static const ValueKey<String> cleFermer = ValueKey<String>(
    'communaute-composer-fermer',
  );

  /// La cle du message d'erreur d'envoi.
  static const ValueKey<String> cleErreur = ValueKey<String>(
    'communaute-composer-erreur',
  );

  /// La cle de l'emplacement du verdict du garde, pres de « Publier ».
  static const ValueKey<String> cleVerdict = ValueKey<String>(
    'communaute-composer-verdict',
  );

  /// La cle de la carte d'une categorie.
  static ValueKey<String> cleCategorie(String id) =>
      ValueKey<String>('communaute-composer-categorie-$id');

  /// Le brouillon du titre d'une nouvelle publication.
  static const CleBrouillon brouillonTitre = CleBrouillon(
    type: TypeObjetLie.publication,
    objetId: 'nouvelle-publication-titre',
  );

  /// Le brouillon du texte d'une nouvelle publication.
  static const CleBrouillon brouillonTexte = CleBrouillon(
    type: TypeObjetLie.publication,
    objetId: 'nouvelle-publication-texte',
  );

  @override
  ConsumerState<ComposerPublication> createState() =>
      _ComposerPublicationState();
}

class _ComposerPublicationState extends ConsumerState<ComposerPublication> {
  final TextEditingController _titre = TextEditingController();
  final TextEditingController _texte = TextEditingController();
  late final PortBrouillons _brouillons = ref.read(portBrouillonsProvider);
  late String? _categorie = widget.categorieInitiale;
  final List<PieceJointe> _pieces = <PieceJointe>[];
  bool _verifier = false;
  bool _enCours = false;
  bool _restaure = false;
  String? _erreur;
  String? _cle;
  int _numeroPiece = 0;

  /// Le dernier verdict du garde qui a retenu la publication ; nul tant
  /// qu'aucun ne l'a fait.
  VerificationPromotion? _verdict;
  final GlobalKey _emplacementVerdict = GlobalKey();

  @override
  void initState() {
    super.initState();
    unawaited(_restaurer());
  }

  Future<void> _restaurer() async {
    final Brouillon? titre = await _brouillons.lire(
      ComposerPublication.brouillonTitre,
    );
    final Brouillon? texte = await _brouillons.lire(
      ComposerPublication.brouillonTexte,
    );
    if (!mounted || (titre == null && texte == null)) return;
    setState(() {
      if (_titre.text.isEmpty && titre != null) _titre.text = titre.texte;
      if (_texte.text.isEmpty && texte != null) _texte.text = texte.texte;
      _restaure = true;
    });
  }

  @override
  void dispose() {
    _titre.dispose();
    _texte.dispose();
    super.dispose();
  }

  Future<void> _joindre(PolitiquePiecesJointes politique) async {
    final FichierChoisi? fichier;
    try {
      fichier = await ref.read(choixPieceCommunauteProvider).choisir();
    } on Object catch (erreur) {
      if (!mounted) return;
      setState(
        () => _erreur = erreur is CapaciteIndisponible
            ? t.com.communaute.composer.choixIndisponible
            : t.com.socle.composants.pieceJointe.joindreIndisponible,
      );
      return;
    }
    if (fichier == null || !mounted) return;
    final FichierChoisi f = fichier;
    setState(() {
      // Une piece de plus est une autre publication : nouvelle cle.
      _cle = null;
      _numeroPiece++;
      _pieces.add(
        PieceJointe(
          reference: ReferencePieceJointe('piece-locale-$_numeroPiece'),
          nom: f.nom,
          nature: f.nature,
          typeLisible: f.typeLisible,
          tailleOctets: f.tailleOctets,
          etat: politique.evaluer(
            typeMime: f.typeMime,
            tailleOctets: f.tailleOctets,
          ),
        ),
      );
    });
  }

  bool get _piecesRefusees =>
      _pieces.any((PieceJointe p) => p.etat != EtatPieceJointe.autorisee);

  Future<void> _publier() async {
    final String? categorie = _categorie;
    final String titre = _titre.text.trim();
    final String texte = _texte.text.trim();
    setState(() {
      _verifier = true;
      _erreur = null;
    });
    if (categorie == null ||
        titre.isEmpty ||
        texte.isEmpty ||
        _piecesRefusees) {
      return;
    }
    // La cle d'idempotence vit avec le contenu : un renvoi apres un echec la
    // rejoue telle quelle, et le serveur ne cree jamais deux publications.
    final String cle = _cle ??= 'pub-${DateTime.now().microsecondsSinceEpoch}';
    final BrouillonPublication brouillon = BrouillonPublication(
      categorieId: categorie,
      titre: titre,
      texte: texte,
      piecesJointes: List<PieceJointe>.unmodifiable(_pieces),
    );
    setState(() => _enCours = true);
    final VerificationPromotion? verification = await _relireGarde(brouillon);
    if (!mounted) return;
    if (verification != null && verification.verdict.retient) {
      // Le garde retient la publication : rien ne part, aucun succes.
      setState(() {
        _enCours = false;
        _verdict = verification;
      });
      _montrerVerdict();
      return;
    }
    setState(() => _verdict = null);
    try {
      final PublicationCommunaute publiee = await ref
          .read(portCommunauteProvider)
          .publier(brouillon, cleIdempotence: cle);
      await _brouillons.effacer(ComposerPublication.brouillonTitre);
      await _brouillons.effacer(ComposerPublication.brouillonTexte);
      if (!mounted) return;
      setState(() => _enCours = false);
      widget.onPubliee(publiee);
    } on Object catch (erreur) {
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _erreur = erreur is CapaciteIndisponible
            ? t.com.communaute.composer.indisponible
            : t.com.communaute.composer.erreurEnvoi;
      });
    }
  }

  /// Le verdict du garde sur [brouillon] ; nul si le garde n'a pas de
  /// contrat (COM-BR-07) ou ne repond pas. Dans ce cas, rien n'est affirme :
  /// la publication part au serveur, seul juge.
  Future<VerificationPromotion?> _relireGarde(
    BrouillonPublication brouillon,
  ) async {
    try {
      return await ref.read(portGardePromotionProvider).verifier(brouillon);
    } on Object {
      return null;
    }
  }

  /// Amene le verdict a l'ecran : il s'affiche pres de « Publier », mais un
  /// long texte peut l'avoir pousse hors de la vue.
  void _montrerVerdict() {
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      final BuildContext? contexte = _emplacementVerdict.currentContext;
      if (contexte == null || !contexte.mounted) return;
      unawaited(Scrollable.ensureVisible(contexte));
    });
  }

  void _contenuModifie() {
    // Un contenu modifie (titre, texte, categorie, pieces) est une autre
    // publication : nouvelle cle.
    _cle = null;
    if (_erreur != null) setState(() => _erreur = null);
  }

  @override
  Widget build(BuildContext context) {
    final c = t.com.communaute.composer;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool bureau = AppGabarit.de(context) == Gabarit.desktop;
    final String? erreur = _erreur;

    String? manque(bool absent, String texte) =>
        _verifier && absent ? texte : null;

    final Widget formulaire = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          c.contexte,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vLg,
        // La politique, en tete (spec section 5.2, etats « Normal » et
        // « Aide ») : le garde sans verdict.
        const GardePromotion(),
        if (_restaure) ...<Widget>[
          Ecart.vMd,
          Semantics(
            liveRegion: true,
            child: Text(
              t.com.socle.composants.composer.brouillonRestaure,
              style: palette.inkMuted.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
          ),
        ],
        Ecart.vXl,
        Semantics(
          header: true,
          child: Text(
            c.categorie,
            style: palette.inkStrong.applyTo(
              textes.titleSmall ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vMd,
        ChoiceCardGroup(
          autoriserSaisieLibre: false,
          valeurInitiale: _categorie == null
              ? null
              : ReponseChoix(valeurs: <String>{_categorie!}),
          options: <OptionChoix>[
            for (final CategorieCommunaute categorie in widget.categories)
              OptionChoix(
                cle: ComposerPublication.cleCategorie(categorie.id),
                valeur: categorie.id,
                libelle: categorie.libelle,
              ),
          ],
          onChange: (ReponseChoix reponse) => setState(() {
            _categorie = reponse.valeurs.firstOrNull;
            // Une autre categorie est une autre publication : nouvelle cle.
            _cle = null;
          }),
        ),
        if (manque(_categorie == null, c.categorieManquante)
            case final String texte) ...<Widget>[
          Text(
            texte,
            style: palette.inkAlert.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
          Ecart.vLg,
        ],
        TextField(
          key: ComposerPublication.cleTitre,
          controller: _titre,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          onChanged: (String texte) {
            unawaited(
              _brouillons.enregistrer(
                ComposerPublication.brouillonTitre,
                texte,
              ),
            );
            _contenuModifie();
          },
          decoration: InputDecoration(
            labelText: c.champTitre,
            hintText: c.aideTitre,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            errorText: manque(_titre.text.trim().isEmpty, c.titreManquant),
          ),
        ),
        Ecart.vLg,
        TextField(
          key: ComposerPublication.cleTexte,
          controller: _texte,
          minLines: 5,
          maxLines: 12,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (String texte) {
            unawaited(
              _brouillons.enregistrer(
                ComposerPublication.brouillonTexte,
                texte,
              ),
            );
            _contenuModifie();
          },
          decoration: InputDecoration(
            labelText: c.champTexte,
            hintText: c.aideTexte,
            alignLabelWithHint: true,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            errorText: manque(_texte.text.trim().isEmpty, c.texteManquant),
          ),
        ),
        Ecart.vXl,
        Semantics(
          header: true,
          child: Text(
            c.pieces,
            style: palette.inkStrong.applyTo(
              textes.titleSmall ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vSm,
        if (_pieces.isNotEmpty) ...<Widget>[
          PileCartes(
            children: <Widget>[
              for (final PieceJointe piece in _pieces)
                CartePieceJointe(
                  piece: piece,
                  onRetirer: () => setState(() {
                    _pieces.remove(piece);
                    _cle = null;
                  }),
                ),
            ],
          ),
          Ecart.vSm,
        ],
        EntreePieceJointe(
          onJoindre: (PolitiquePiecesJointes politique) {
            unawaited(_joindre(politique));
          },
        ),
        if (_verifier && _piecesRefusees) ...<Widget>[
          Ecart.vSm,
          Text(
            c.pieceRefusee,
            style: palette.inkAlert.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
        if (_verdict case final VerificationPromotion verdict) ...<Widget>[
          Ecart.vXl,
          KeyedSubtree(
            key: _emplacementVerdict,
            child: KeyedSubtree(
              key: ComposerPublication.cleVerdict,
              child: GardePromotion(verification: verdict),
            ),
          ),
        ],
        if (erreur != null) ...<Widget>[
          Ecart.vLg,
          Semantics(
            liveRegion: true,
            child: Text(
              erreur,
              key: ComposerPublication.cleErreur,
              style: palette.inkAlert.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: SectionHeader(titre: c.nouvelle)),
            BoutonIcone(
              key: ComposerPublication.cleFermer,
              icone: AppIcons.fermer,
              libelle: c.fermer,
              infobulle: c.fermer,
              onPress: widget.onFermer,
            ),
          ],
        ),
        Ecart.vMd,
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: formulaire,
          ),
        ),
        Ecart.vMd,
        // Le seul bouton plein de la surface, en bas du formulaire (K-56) ;
        // jamais pleine largeur sur ordinateur (contrat A).
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: ActionPrincipale(
            key: ComposerPublication.clePublier,
            libelle: c.publier,
            enCours: _enCours,
            pleineLargeur: !bureau,
            onPress: _publier,
          ),
        ),
        Ecart.vLg,
      ],
    );
  }
}
