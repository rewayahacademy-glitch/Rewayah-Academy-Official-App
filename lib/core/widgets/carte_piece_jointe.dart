// La carte d'une piece jointe et l'entree « Joindre un fichier » des
// communications (spec section 12, COM-BR-04).
//
// La carte affiche le nom (sans chemin), le type, la taille si elle est
// connue, l'etat en toutes lettres, et l'action « Ouvrir » seulement si elle
// est autorisee. Elle n'affiche JAMAIS la reference opaque, une URL de
// stockage, un chemin interne ou un jeton : le modele `PieceJointe` ne les
// porte pas, et rien ici ne lit `reference.valeur`.
//
// L'entree « Joindre un fichier » est pilotee par `PortPolitiquePiecesJointes`
// : tant que le serveur ne donne pas de politique (port de production,
// `CapaciteIndisponible`), aucune action n'est proposee, une phrase le dit.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../communications/port_pieces_jointes.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'action_principale.dart';
import 'app_card.dart';
import 'lien_fleche.dart';
import 'status_pill.dart';

/// La politique des pieces jointes lue une fois par ecran. Elle echoue avec
/// `CapaciteIndisponible` tant que le port de production n'a pas de contrat.
final FutureProvider<PolitiquePiecesJointes> politiquePiecesJointesProvider =
    FutureProvider.autoDispose<PolitiquePiecesJointes>(
      (Ref ref) => ref.watch(portPolitiquePiecesJointesProvider).politique(),
    );

/// La carte d'une piece jointe.
///
/// Les actions ne sont rendues que si elles peuvent aboutir (jamais grisees,
/// lib/CLAUDE.md) :
///
/// - « Ouvrir » : piece envoyee, [PieceJointe.peutOuvrir] et [onOuvrir] ;
/// - « Retirer » : piece pas encore partie (prete, refusee ou non confirmee)
///   et [onRetirer] ;
/// - « Reessayer » : envoi non confirme et [onReessayer].
class CartePieceJointe extends StatelessWidget {
  /// Cree la carte.
  const CartePieceJointe({
    required this.piece,
    super.key,
    this.onOuvrir,
    this.onRetirer,
    this.onReessayer,
  });

  /// La piece a montrer.
  final PieceJointe piece;

  /// Ouvre la piece (jeton ephemere demande au serveur au toucher, BR-1).
  final VoidCallback? onOuvrir;

  /// Retire la piece du message en preparation.
  final VoidCallback? onRetirer;

  /// Relance l'envoi d'une piece non confirmee.
  final VoidCallback? onReessayer;

  /// La cle de l'action « Ouvrir », pour les tests.
  static const ValueKey<String> cleOuvrir = ValueKey<String>('pj-ouvrir');

  /// La cle de l'action « Retirer », pour les tests.
  static const ValueKey<String> cleRetirer = ValueKey<String>('pj-retirer');

  /// La cle de l'action « Reessayer », pour les tests.
  static const ValueKey<String> cleReessayer = ValueKey<String>('pj-reessayer');

  /// Le mot d'un etat.
  static String libelleEtat(EtatPieceJointe etat) {
    final p = t.com.socle.composants.pieceJointe;
    return switch (etat) {
      EtatPieceJointe.autorisee => p.autorisee,
      EtatPieceJointe.tropVolumineuse => p.tropVolumineuse,
      EtatPieceJointe.typeInterdit => p.typeInterdit,
      EtatPieceJointe.enCours => p.enCours,
      EtatPieceJointe.envoyee => p.envoyee,
      EtatPieceJointe.echec => p.echec,
      EtatPieceJointe.indisponible => p.indisponible,
    };
  }

  /// La phrase qui dit quoi faire, pour les etats qui en demandent une ;
  /// `null` sinon (K-59 : ce qui manque, la cause, l'action possible).
  static String? detailEtat(EtatPieceJointe etat) {
    final p = t.com.socle.composants.pieceJointe;
    return switch (etat) {
      EtatPieceJointe.tropVolumineuse => p.tropVolumineuseDetail,
      EtatPieceJointe.typeInterdit => p.typeInterditDetail,
      EtatPieceJointe.echec => p.erreurEnvoi,
      EtatPieceJointe.indisponible => p.indisponibleDetail,
      EtatPieceJointe.autorisee ||
      EtatPieceJointe.enCours ||
      EtatPieceJointe.envoyee => null,
    };
  }

  /// La famille d'un etat : l'alerte pour le seul envoi non confirme.
  static TonEtat tonEtat(EtatPieceJointe etat) => switch (etat) {
    EtatPieceJointe.autorisee => TonEtat.accent,
    EtatPieceJointe.tropVolumineuse ||
    EtatPieceJointe.typeInterdit => TonEtat.avertissement,
    EtatPieceJointe.enCours || EtatPieceJointe.indisponible => TonEtat.neutre,
    EtatPieceJointe.envoyee => TonEtat.succes,
    EtatPieceJointe.echec => TonEtat.alerte,
  };

  /// L'icone d'une nature de piece.
  static AppIcon iconeNature(NaturePieceJointe nature) => switch (nature) {
    NaturePieceJointe.document => AppIcons.fichierPdf,
    NaturePieceJointe.image => AppIcons.image,
    NaturePieceJointe.audio => AppIcons.libelleAudio,
    NaturePieceJointe.vocal => AppIcons.micro,
    NaturePieceJointe.autre => AppIcons.texteStructure,
  };

  /// La taille mise en mots : octets, Ko (entier) ou Mo (une decimale).
  static String libelleTaille(int octets) {
    final p = t.com.socle.composants.pieceJointe;
    const int ko = 1024;
    const int mo = ko * ko;
    if (octets < ko) return p.tailleOctets(taille: octets);
    if (octets < mo) return p.tailleKo(taille: (octets / ko).ceil());
    final String mega = (octets / mo).toStringAsFixed(1);
    final String separe = LocaleSettings.currentLocale == AppLocale.fr
        ? mega.replaceAll('.', ',')
        : mega;
    return p.tailleMo(taille: separe);
  }

  /// La duree d'un audio ou d'un vocal, en minutes et secondes (« 1:05 »).
  static String libelleDuree(Duration duree) {
    final int secondes = duree.inSeconds;
    final String reste = (secondes % 60).toString().padLeft(2, '0');
    return '${secondes ~/ 60}:$reste';
  }

  bool get _peutOuvrir =>
      onOuvrir != null &&
      piece.peutOuvrir &&
      piece.etat == EtatPieceJointe.envoyee;

  bool get _peutRetirer =>
      onRetirer != null &&
      switch (piece.etat) {
        EtatPieceJointe.autorisee ||
        EtatPieceJointe.tropVolumineuse ||
        EtatPieceJointe.typeInterdit ||
        EtatPieceJointe.echec => true,
        EtatPieceJointe.enCours ||
        EtatPieceJointe.envoyee ||
        EtatPieceJointe.indisponible => false,
      };

  bool get _peutReessayer =>
      onReessayer != null && piece.etat == EtatPieceJointe.echec;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final p = t.com.socle.composants.pieceJointe;
    final TextStyle discret = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final int? taille = piece.tailleOctets;
    final Duration? duree = piece.duree;
    final String? detail = detailEtat(piece.etat);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ExcludeSemantics(
                child: Icon(
                  iconeNature(piece.nature).repos,
                  size: AppSpacing.xxl,
                  color: palette.surfaceRaised.onBackground,
                ),
              ),
              Ecart.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      piece.nom,
                      style: palette.surfaceRaised.applyTo(
                        textes.titleSmall ?? const TextStyle(),
                      ),
                    ),
                    Ecart.vXs,
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: <Widget>[
                        Text(piece.typeLisible, style: discret),
                        if (taille != null)
                          Text(libelleTaille(taille), style: discret),
                        if (duree != null)
                          Text(libelleDuree(duree), style: discret),
                      ],
                    ),
                    Ecart.vSm,
                    StatusPill(
                      libelle: libelleEtat(piece.etat),
                      ton: tonEtat(piece.etat),
                    ),
                    if (detail != null) ...<Widget>[
                      Ecart.vSm,
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          detail,
                          style: palette.inkMuted.applyTo(
                            textes.bodyMedium ?? const TextStyle(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (_peutOuvrir) ...<Widget>[
            Ecart.vSm,
            // m3 (revue COM-F-R) : le verbe seul a l'ecran, le nom dans
            // le libelle semantique ; a 320 et texte double, « Ouvrir
            // <nom long> » prenait quatre lignes.
            LienFleche(
              key: cleOuvrir,
              libelle: p.ouvrir,
              libelleSemantique: p.ouvrirLecteur(nom: piece.nom),
              onPress: onOuvrir,
            ),
          ],
          if (_peutRetirer || _peutReessayer) ...<Widget>[
            Ecart.vLg,
            RangeeActions(
              children: <Widget>[
                if (_peutRetirer)
                  // Meme regle que « Ouvrir » : « Retirer » a l'ecran, le nom
                  // pour le lecteur d'ecran.
                  ActionPrincipale(
                    key: cleRetirer,
                    libelle: p.retirer,
                    libelleSemantique: p.retirerLecteur(nom: piece.nom),
                    onPress: onRetirer,
                    niveau: NiveauAction.tertiaire,
                    pleineLargeur: false,
                  ),
                if (_peutReessayer)
                  ActionPrincipale(
                    key: cleReessayer,
                    libelle: t.com.socle.composants.etats.reessayer,
                    onPress: onReessayer,
                    niveau: NiveauAction.secondaire,
                    pleineLargeur: false,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// L'entree « Joindre un fichier », pilotee par la politique du serveur.
///
/// - politique en cours de lecture : rien (pas de bouton qui clignote) ;
/// - politique connue : le lien « Joindre un fichier », qui rend la
///   politique a l'appelant pour qu'il evalue le fichier choisi
///   ([PolitiquePiecesJointes.evaluer]) ;
/// - pas de politique (capacite indisponible ou lecture en echec) : une
///   phrase, jamais un bouton grise ni une politique inventee.
class EntreePieceJointe extends ConsumerWidget {
  /// Cree l'entree.
  const EntreePieceJointe({required this.onJoindre, super.key});

  /// Le choix d'un fichier, avec la politique en vigueur.
  final void Function(PolitiquePiecesJointes politique) onJoindre;

  /// La cle du lien « Joindre un fichier », pour les tests.
  static const ValueKey<String> cleJoindre = ValueKey<String>('pj-joindre');

  /// La cle de la phrase d'indisponibilite, pour les tests.
  static const ValueKey<String> cleIndisponible = ValueKey<String>(
    'pj-joindre-indisponible',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<PolitiquePiecesJointes> lue = ref.watch(
      politiquePiecesJointesProvider,
    );
    final p = t.com.socle.composants.pieceJointe;
    final PolitiquePiecesJointes? politique = lue.hasValue ? lue.value : null;
    if (politique != null) {
      return LienFleche(
        key: cleJoindre,
        libelle: p.joindre,
        icone: AppIcons.pieceJointe,
        fleche: false,
        onPress: () => onJoindre(politique),
      );
    }
    if (lue.hasError) {
      final AppPalette palette = AppPalette.of(context);
      return Text(
        p.joindreIndisponible,
        key: cleIndisponible,
        style: palette.inkMuted.applyTo(
          Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
