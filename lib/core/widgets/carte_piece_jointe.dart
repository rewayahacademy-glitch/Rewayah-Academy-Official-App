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

import 'dart:math' as math;

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
                    _NomFichier(
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

/// Le nom d'un fichier sur une ligne, jamais coupe au milieu d'un mot
/// (COM-RC tour 2, R-11 : « Devoir_semaine_3.pd / f » a 768).
///
/// Un nom de fichier n'a souvent aucune espace : le moteur de texte le
/// couperait n'importe ou. Quand il ne tient pas sur une ligne, son milieu
/// s'efface (« Devoir_se…e_3.pdf ») : le debut et l'extension restent
/// visibles. Le nom complet reste celui que lit le lecteur d'ecran.
///
/// COM-RC tour 3 : le debut garde au moins [debutMinimal] caracteres (a 320
/// et texte x2, il ne restait que « …_3.pdf »). Quand ce debut, l'ellipse et
/// l'extension ne tiennent pas sur une ligne, le nom passe sur deux : le
/// debut, puis l'ellipse et la fin (« Devoir_s » / « …e_3.pdf »).
class _NomFichier extends StatelessWidget {
  /// Cree le nom.
  const _NomFichier(this.nom, {this.style});

  /// Le nom complet du fichier.
  final String nom;

  /// Son style.
  final TextStyle? style;

  /// La marque de l'effacement.
  static const String ellipse = '\u2026';

  /// Le nombre de caracteres gardes avant l'extension, quand il y en a.
  static const int _finGardee = 3;

  /// Le debut du nom garde au moins ces caracteres avant l'ellipse.
  static const int debutMinimal = 6;

  /// [nom] raccourci par le milieu pour tenir dans [largeur], ou [nom] s'il
  /// tient ; sur deux lignes (separees par un saut de ligne) quand une seule
  /// ne garde pas [debutMinimal] caracteres du debut.
  static String raccourci({
    required String nom,
    required double largeur,
    required TextStyle style,
    required TextDirection sens,
    required TextScaler echelle,
  }) {
    bool tient(String texte) {
      final TextPainter p = TextPainter(
        text: TextSpan(text: texte, style: style),
        textDirection: sens,
        textScaler: echelle,
        maxLines: 1,
      )..layout();
      final bool ok = p.width <= largeur;
      p.dispose();
      return ok;
    }

    if (!largeur.isFinite || tient(nom)) return nom;
    final Characters lettres = nom.characters;
    final int total = lettres.length;
    if (total < 2) return nom;
    String debut(int n) => lettres.take(n).toString();
    String fin(int n) => lettres.skip(total - n).toString();

    // Le plus long debut (au plus [plafond]) tel que [forme] tienne.
    int plusLong(int plafond, bool Function(int n) forme) {
      int bas = 0;
      int haut = plafond;
      while (bas < haut) {
        final int milieu = (bas + haut + 1) ~/ 2;
        if (forme(milieu)) {
          bas = milieu;
        } else {
          haut = milieu - 1;
        }
      }
      return bas;
    }

    final int point = nom.lastIndexOf('.');
    // L'extension (« .pdf ») et quelques caracteres avant elle.
    final int longueurExtension = point > 0
        ? nom.substring(point).characters.length
        : 0;
    final int finPlancher = longueurExtension.clamp(1, total - 1);
    // Une ligne : la queue la plus longue (jamais plus courte que
    // l'extension) qui laisse au debut ses caracteres minimaux.
    for (
      int queue = (longueurExtension + _finGardee).clamp(1, total - 1);
      queue >= finPlancher;
      queue--
    ) {
      final String suite = fin(queue);
      final int maxDebut = total - queue;
      final int garde = plusLong(
        maxDebut,
        (int n) => tient('${debut(n)}$ellipse$suite'),
      );
      if (garde >= math.min(debutMinimal, maxDebut)) {
        return '${debut(garde)}$ellipse$suite';
      }
    }
    // Deux lignes : le plus long debut qui tient seul, puis l'ellipse et la
    // plus longue fin qui tient (le reste entier s'il tient sans ellipse).
    final int premiere = math.max(
      1,
      plusLong(total - 1, (int n) => tient(debut(n))),
    );
    final int reste = total - premiere;
    if (tient(fin(reste))) return '${debut(premiere)}\n${fin(reste)}';
    final int queue = math.max(
      1,
      plusLong(reste, (int n) => tient('$ellipse${fin(n)}')),
    );
    return '${debut(premiere)}\n$ellipse${fin(queue)}';
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle complet = DefaultTextStyle.of(context).style.merge(style);
    final TextDirection sens = Directionality.of(context);
    final TextScaler echelle = MediaQuery.textScalerOf(context);
    return Semantics(
      label: nom,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (BuildContext _, BoxConstraints c) => Text(
            raccourci(
              nom: nom,
              largeur: c.maxWidth,
              style: complet,
              sens: sens,
              echelle: echelle,
            ),
            style: style,
            maxLines: 2,
            softWrap: false,
            // Filet de securite : une queue qui ne tient meme pas seule.
            overflow: TextOverflow.ellipsis,
          ),
        ),
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
