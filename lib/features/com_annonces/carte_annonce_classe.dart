// La carte d'une annonce de Classe (`ClassAnnouncementCard`, spec
// Communications V1, section 13.3).
//
// Une annonce apparait dans l'Espace Classe, dans le centre de notifications
// et, si son niveau le justifie, sur l'accueil. Elle ne devient jamais un fil
// : aucune reponse, aucun compteur de vues. Trois actions au plus, chacune
// rendue seulement quand elle peut aboutir (jamais grisee) :
//
// - « Marquer comme lue » (lire), quand l'annonce n'est pas lue ;
// - « Lire l'annonce en entier », quand le texte depasse la carte (le
//   detail, surface contextuelle, section 18) ;
// - « Ouvrir la Classe », hors de la Classe elle-meme (R-COM-12).
//
// Le niveau se dit par un mot et une icone (`BadgeNonLu`), jamais par la
// couleur seule. Sur `CarteGroupee` : une seule carte, le contenu puis les
// actions sous un filet.

import 'package:flutter/material.dart';

import '../../core/accessibilite/sens_du_contenu.dart';
import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/communications/modeles_communication.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/badge_non_lu.dart';
import '../../core/widgets/carte_groupee.dart';
import '../../core/widgets/lien_fleche.dart';
import '../suivi_foyer/filtres_historique.dart';
import 'port_annonces.dart';

/// La carte d'une annonce de Classe (`ClassAnnouncementCard`).
class CarteAnnonceClasse extends StatelessWidget {
  /// Cree la carte.
  const CarteAnnonceClasse({
    required this.annonce,
    super.key,
    this.complete = false,
    this.onLire,
    this.onOuvrirClasse,
    this.onMarquerLue,
  });

  /// L'annonce.
  final AnnonceClasse annonce;

  /// Vrai : le texte entier (le detail) ; faux : le debut, sur
  /// [lignesCarte] lignes au plus.
  final bool complete;

  /// Ouvre le detail. Rendu seulement si le texte depasse la carte.
  final VoidCallback? onLire;

  /// Ouvre la Classe de l'annonce. Sans lui (dans la Classe meme), aucun
  /// lien n'est rendu.
  final VoidCallback? onOuvrirClasse;

  /// Enregistre la lecture. Rendu seulement si l'annonce n'est pas lue.
  final VoidCallback? onMarquerLue;

  /// La marge interne de la carte, fixee pour que la mesure du texte soit
  /// celle du rendu.
  static const double _marge = AppSpacing.xl;

  /// Le nombre de lignes du texte sur la carte.
  static const int lignesCarte = 4;

  /// Cles, pour les tests.
  static const ValueKey<String> cleLire = ValueKey<String>('annonce-lire');

  /// Cle du lien « Ouvrir la Classe ».
  static const ValueKey<String> cleOuvrirClasse = ValueKey<String>(
    'annonce-ouvrir-classe',
  );

  /// Cle du lien « Marquer comme lue ».
  static const ValueKey<String> cleMarquerLue = ValueKey<String>(
    'annonce-marquer-lue',
  );

  /// Ce que le badge doit dire : le niveau tant que l'annonce n'est pas lue ;
  /// une fois lue, seul un niveau qui demande quelque chose reste dit.
  static IndicateurAttention indicateurDe(AnnonceClasse annonce) =>
      IndicateurAttention(
        niveau:
            annonce.lue &&
                !annonce.niveau.estAuMoins(NiveauAttention.actionRequise)
            ? NiveauAttention.information
            : annonce.niveau,
      );

  /// La ligne de l'auteur et de la date (« Enseignante de la Classe, le 3
  /// oct. a 18:00 »).
  static String ligneAuteur(AnnonceClasse annonce) {
    final DateTime quand = annonce.publieeLe.toLocal();
    final String date = dateLongueHistorique(quand);
    final String heure = heureMinute(quand);
    final a = t.com.annonces;
    final Participant? auteur = annonce.auteur;
    return auteur == null
        ? a.date(date: date, heure: heure)
        : a.auteurDate(
            auteur: auteur.fonction ?? auteur.nomAffiche,
            date: date,
            heure: heure,
          );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final a = t.com.annonces;
    final TextStyle styleTexte = palette.inkStrong.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final IndicateurAttention indicateur = indicateurDe(annonce);

    final Widget contenu = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Le mot « Annonce » et la Classe, puis le niveau en toutes lettres.
        Text(
          // « An-Nour » ne se coupe pas au trait d'union (lot L).
          '${a.annonce} · ${traitsDUnionInsecables(annonce.classe.libelle)}',
          style: palette.inkMuted.applyTo(
            textes.labelMedium ?? const TextStyle(),
          ),
        ),
        if (indicateur.estVisible) ...<Widget>[
          Ecart.vSm,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: BadgeNonLu(indicateur: indicateur),
          ),
        ],
        Ecart.vSm,
        Semantics(
          header: true,
          child: Text(
            annonce.titre,
            // Le contenu garde le sens de sa langue (COM-RC tour 3).
            textDirection: sensDuContenu(context, annonce.titre),
            style: palette.inkStrong.applyTo(
              textes.titleMedium ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vXs,
        Text(
          ligneAuteur(annonce),
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
        Ecart.vMd,
        if (complete)
          Text(
            annonce.texte,
            textDirection: sensDuContenu(context, annonce.texte),
            style: styleTexte,
          )
        else
          Text(
            annonce.texte,
            textDirection: sensDuContenu(context, annonce.texte),
            style: styleTexte,
            maxLines: lignesCarte,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        final bool depasse =
            !complete &&
            _depasse(
              annonce.texte,
              styleTexte,
              // La largeur du texte : celle de la carte moins ses marges.
              contraintes.maxWidth - 2 * _marge,
              MediaQuery.textScalerOf(context),
              sensDuContenu(context, annonce.texte),
            );
        final VoidCallback? lire = onLire;
        final VoidCallback? ouvrirClasse = onOuvrirClasse;
        final VoidCallback? marquerLue = onMarquerLue;
        final List<Widget> actions = <Widget>[
          if (!annonce.lue && marquerLue != null)
            LienFleche(
              key: cleMarquerLue,
              libelle: a.marquerLue,
              fleche: false,
              onPress: marquerLue,
            ),
          if (depasse && lire != null)
            LienFleche(key: cleLire, libelle: a.lire, onPress: lire),
          if (ouvrirClasse != null && annonce.classe.destination != null)
            LienFleche(
              key: cleOuvrirClasse,
              libelle: a.ouvrirClasse,
              libelleSemantique: a.ouvrirClasseSemantique(
                classe: annonce.classe.libelle,
              ),
              onPress: ouvrirClasse,
            ),
        ];
        return Semantics(
          container: true,
          label: a.carteSemantique(
            classe: annonce.classe.libelle,
            titre: annonce.titre,
          ),
          child: CarteGroupee(
            marge: _marge,
            sections: <Widget>[
              contenu,
              if (actions.isNotEmpty)
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppSpacing.lg,
                  children: actions,
                ),
            ],
          ),
        );
      },
    );
  }

  /// Vrai si [texte] ne tient pas sur [lignesCarte] lignes de [largeur], au
  /// texte agrandi compris : la mesure suit le `TextScaler` de la page.
  static bool _depasse(
    String texte,
    TextStyle style,
    double largeur,
    TextScaler echelle,
    TextDirection direction,
  ) {
    if (largeur <= 0) return false;
    final TextPainter mesure = TextPainter(
      text: TextSpan(text: texte, style: style),
      maxLines: lignesCarte,
      textDirection: direction,
      textScaler: echelle,
    )..layout(maxWidth: largeur);
    final bool depasse = mesure.didExceedMaxLines;
    mesure.dispose();
    return depasse;
  }
}
