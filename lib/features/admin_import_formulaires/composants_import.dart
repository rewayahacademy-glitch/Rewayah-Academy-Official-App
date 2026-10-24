// Les briques de l'import des formulaires (`ADM-23`) : la question d'un pas, ses
// actions, les trois formes de la liste des pas (barre sur telephone, disques
// sur tablette, rail sur bureau), les compteurs et les listes de lignes.
//
// Un seul bouton plein par pas (K-56) : `ActionsDuPas` le pose, nulle part
// ailleurs. Les actions secondaires sont des liens (`LienFleche`) ou le
// tertiaire « Retour ». Aucune couleur, aucun espacement ni rayon litteral :
// tout vient des jetons.
library;

import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/modeles_import_candidatures.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/page_etape.dart' show RangeeEtape;
import '../../core/widgets/status_pill.dart';
import 'controleur_import.dart';
import 'libelles_import.dart';

/// Le nombre de lignes montrees d'une liste avant « Voir … de plus ».
const int lignesParPage = 50;

/// La question d'un pas et son explication.
class QuestionDuPas extends StatelessWidget {
  /// Cree la question.
  const QuestionDuPas({required this.question, super.key, this.explication});

  /// La question, en une phrase.
  final String question;

  /// Ce qui l'explique.
  final String? explication;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          header: true,
          child: TexteSansCoupure(
            question,
            style: textes.headlineSmall ?? const TextStyle(),
          ),
        ),
        if (explication != null) ...<Widget>[
          Ecart.vSm,
          TexteSansCoupure(
            explication!,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
      ],
    );
  }
}

/// Les actions d'un pas : le bouton plein qui avance (le seul de l'ecran), le
/// tertiaire « Retour », et une ligne au-dessus pour ce qui manque ou ce qui a
/// echoue.
///
/// [empile] : sur telephone, le bouton prend la largeur et « Retour » est
/// dessous, centre. Ailleurs, « Retour » est au bord de debut et le bouton au
/// bord de fin, a 16 sous le contenu (contrat B).
class ActionsDuPas extends StatelessWidget {
  /// Cree les actions.
  const ActionsDuPas({
    required this.empile,
    super.key,
    this.libelleAction,
    this.onAction,
    this.enCours = false,
    this.onRetour,
    this.souscription,
  });

  /// La cle du bouton plein.
  static const Key actionKey = ValueKey<String>('import-action');

  /// La cle du bouton « Retour ».
  static const Key retourKey = ValueKey<String>('import-retour');

  /// Vrai sur telephone.
  final bool empile;

  /// Le libelle du bouton plein ; `null` : pas de bouton plein (il ne peut pas
  /// aboutir, une phrase dit pourquoi).
  final String? libelleAction;

  /// Ce que fait le bouton plein.
  final VoidCallback? onAction;

  /// Vrai pendant un envoi : le bouton tourne, rien d'autre ne se presse.
  final bool enCours;

  /// Le retour au pas precedent ; `null` au premier pas.
  final VoidCallback? onRetour;

  /// Une ligne au-dessus du bouton.
  final Widget? souscription;

  @override
  Widget build(BuildContext context) {
    final Widget? principale = libelleAction == null
        ? null
        : ActionPrincipale(
            key: actionKey,
            libelle: libelleAction!,
            onPress: enCours ? null : onAction,
            enCours: enCours,
            pilule: true,
            fleche: true,
            affirmee: true,
            pleineLargeur: empile,
          );
    // Pendant un envoi, rien d'autre ne se presse : « Retour » n'est pas rendu
    // (un bouton qui ne peut pas aboutir ne s'affiche pas).
    final Widget? retour = onRetour == null || enCours
        ? null
        : ActionPrincipale(
            key: retourKey,
            libelle: t.commun.retour,
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
            onPress: onRetour,
          );
    if (principale == null && retour == null && souscription == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (souscription != null) ...<Widget>[souscription!, Ecart.vMd],
        if (empile) ...<Widget>[
          ?principale,
          if (principale != null && retour != null) Ecart.vXs,
          if (retour != null) Center(child: retour),
        ] else
          Row(children: <Widget>[?retour, const Spacer(), ?principale]),
      ],
    );
  }
}

/// Une phrase qui rassure ou qui precise, precedee d'une icone : ce que
/// l'import ne fait pas, ce qui est masque. Jamais un etat d'echec.
class InfoPas extends StatelessWidget {
  /// Cree la phrase.
  const InfoPas({required this.message, super.key, this.icone = AppIcons.info});

  /// Le message.
  final String message;

  /// L'icone, decorative.
  final AppIcon icone;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ExcludeSemantics(
          child: IconTheme(
            data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
            child: Icon(icone.repos),
          ),
        ),
        Ecart.hSm,
        Expanded(
          child: TexteSansCoupure(
            message,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ),
      ],
    );
  }
}

/// Un lien secondaire pose au bord de debut de sa colonne, sans fleche : une
/// action discrete (« Corriger ces noms »), jamais un bouton.
class LienDebut extends StatelessWidget {
  /// Cree le lien.
  const LienDebut({
    required this.libelle,
    required this.onPress,
    super.key,
    this.fleche = false,
  });

  /// Le libelle : un verbe et son objet.
  final String libelle;

  /// Ce que fait le lien.
  final VoidCallback onPress;

  /// Vrai : une fleche suit le libelle.
  final bool fleche;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: LienFleche(
      libelle: libelle,
      fleche: fleche,
      alignerEnDebut: true,
      onPress: onPress,
    ),
  );
}

/// Une ligne d'indication au-dessus du bouton : ce qui manque pour continuer
/// (K-59), annoncee au lecteur d'ecran. [discret] : une precision et non une
/// faute, en encre attenuee.
class IndicationPas extends StatelessWidget {
  /// Cree la ligne.
  const IndicationPas({required this.message, super.key, this.discret = false});

  /// Le message.
  final String message;

  /// Vrai : encre attenuee, au lieu de l'encre d'alerte.
  final bool discret;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Semantics(
      liveRegion: true,
      child: TexteSansCoupure(
        message,
        textAlign: TextAlign.center,
        style: (discret ? palette.inkMuted : palette.inkAlert).applyTo(
          Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
        ),
      ),
    );
  }
}

/// L'etat d'un pas dans la liste des pas.
enum EtatPas {
  /// Passe.
  fait,

  /// Le pas courant.
  enCours,

  /// Pas encore atteint.
  aVenir,
}

/// L'etat du pas [pas] quand le pas courant est [courant].
EtatPas etatDuPas(PasImport pas, PasImport courant) => pas.index < courant.index
    ? EtatPas.fait
    : pas == courant
    ? EtatPas.enCours
    : EtatPas.aVenir;

String _motEtat(EtatPas etat) => switch (etat) {
  EtatPas.fait => t.admin.importFormulaires.pas.fait,
  EtatPas.enCours => t.admin.importFormulaires.pas.enCours,
  EtatPas.aVenir => t.admin.importFormulaires.pas.aVenir,
};

/// Le disque d'un pas : coche (fait), numero cerne (en cours), numero (a venir).
/// L'etat se lit a l'icone et au contour, jamais a la couleur seule.
class _DisquePas extends StatelessWidget {
  const _DisquePas({required this.numero, required this.etat});

  final int numero;
  final EtatPas etat;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppColorPair paire = switch (etat) {
      EtatPas.fait => palette.washSuccess,
      EtatPas.enCours => palette.washAccent,
      EtatPas.aVenir => palette.surfaceSunken,
    };
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: paire.background,
          borderRadius: AppRadius.arrondiFull,
          border: etat == EtatPas.enCours
              ? Border.fromBorderSide(
                  palette.borderStrong.asBorderSide(width: 2),
                )
              : null,
        ),
        child: SizedBox(
          width: AppSpacing.xxxl,
          height: AppSpacing.xxxl,
          child: Center(
            child: etat == EtatPas.fait
                ? IconTheme(
                    data: IconThemeData(
                      color: paire.onBackground,
                      size: AppSpacing.xl,
                    ),
                    child: Icon(AppIcons.succes.actif),
                  )
                : TexteSansCoupure(
                    '$numero',
                    style: AppTypography.tabulaire(
                      etat == EtatPas.enCours
                          ? paire.applyTo(
                              textes.titleSmall ?? const TextStyle(),
                            )
                          : palette.inkMuted.applyTo(
                              textes.titleSmall ?? const TextStyle(),
                            ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// La liste des huit pas sur bureau : un rail, au bord de debut. Chaque ligne
/// dit son pas, son rang et son etat en mots.
class RailPas extends StatelessWidget {
  /// Cree le rail.
  const RailPas({required this.courant, super.key});

  /// Le pas courant.
  final PasImport courant;

  /// La cle du rail.
  static const Key railKey = ValueKey<String>('import-rail');

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final a = t.admin.importFormulaires;
    return AppCard(
      key: railKey,
      child: Semantics(
        container: true,
        label: a.pas.liste,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final PasImport pas in PasImport.values) ...<Widget>[
              if (pas.index > 0) Ecart.vMd,
              Semantics(
                container: true,
                selected: pas == courant,
                label:
                    '${a.pas.surTotalNomme(n: pas.index + 1, total: PasImport.values.length, nom: libellePas(pas))}, ${_motEtat(etatDuPas(pas, courant))}',
                excludeSemantics: true,
                child: Row(
                  key: ValueKey<String>('import-rail-${pas.name}'),
                  children: <Widget>[
                    _DisquePas(
                      numero: pas.index + 1,
                      etat: etatDuPas(pas, courant),
                    ),
                    Ecart.hMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          TexteSansCoupure(
                            libellePas(pas),
                            style:
                                (pas == courant
                                        ? palette.inkStrong
                                        : palette.inkMuted)
                                    .applyTo(
                                      pas == courant
                                          ? (textes.titleMedium ??
                                                const TextStyle())
                                          : (textes.bodyLarge ??
                                                const TextStyle()),
                                    ),
                          ),
                          TexteSansCoupure(
                            _motEtat(etatDuPas(pas, courant)),
                            style: palette.inkMuted.applyTo(
                              textes.bodySmall ?? const TextStyle(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// La liste des huit pas sur tablette : les huit disques en haut, puis le pas
/// courant en mots.
class BandePas extends StatelessWidget {
  /// Cree la bande.
  const BandePas({required this.courant, super.key});

  /// Le pas courant.
  final PasImport courant;

  /// La cle de la bande.
  static const Key bandeKey = ValueKey<String>('import-bande');

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final a = t.admin.importFormulaires;
    return Semantics(
      container: true,
      label: a.pas.liste,
      child: Column(
        key: bandeKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              for (final PasImport pas in PasImport.values)
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _DisquePas(
                      numero: pas.index + 1,
                      etat: etatDuPas(pas, courant),
                    ),
                  ),
                ),
            ],
          ),
          Ecart.vMd,
          TexteSansCoupure(
            a.pas.surTotalNomme(
              n: courant.index + 1,
              total: PasImport.values.length,
              nom: libellePas(courant),
            ),
            style: palette.inkMuted.applyTo(
              textes.labelLarge ?? const TextStyle(),
            ),
          ),
        ],
      ),
    );
  }
}

/// La progression sur telephone : la barre du parcours, puis le nom du pas.
class ProgressionPas extends StatelessWidget {
  /// Cree la progression.
  const ProgressionPas({required this.courant, super.key});

  /// Le pas courant.
  final PasImport courant;

  /// La cle de la progression.
  static const Key progressionKey = ValueKey<String>('import-progression');

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final a = t.admin.importFormulaires;
    return Column(
      key: progressionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        RangeeEtape(numero: courant.index + 1, total: PasImport.values.length),
        Ecart.vSm,
        TexteSansCoupure(
          a.pas.surTotalNomme(
            n: courant.index + 1,
            total: PasImport.values.length,
            nom: libellePas(courant),
          ),
          style: palette.inkMuted.applyTo(
            textes.labelLarge ?? const TextStyle(),
          ),
        ),
      ],
    );
  }
}

/// Un compteur : un nombre, son nom, une phrase.
class _Compteur extends StatelessWidget {
  const _Compteur({
    required this.cleValeur,
    required this.valeur,
    required this.libelle,
    required this.aide,
  });

  final Key cleValeur;
  final int valeur;
  final String libelle;
  final String aide;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TexteSansCoupure(
            '$valeur',
            key: cleValeur,
            style: AppTypography.tabulaire(
              palette.inkStrong.applyTo(
                textes.displaySmall ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vXs,
          TexteSansCoupure(libelle, style: textes.titleSmall),
          Ecart.vXs,
          TexteSansCoupure(
            aide,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Les compteurs du serveur : les quatre de la fiche (nouvelles, deja connues,
/// ignorees, a corriger) dans UNE carte, puis les lignes lues, les corrigees et
/// les personnes. Rien n'est recalcule.
class CompteursCarte extends StatelessWidget {
  /// Cree la carte.
  const CompteursCarte({
    required this.compteurs,
    super.key,
    this.termine = false,
  });

  /// Les compteurs.
  final CompteursImport compteurs;

  /// Vrai pour le rapport final : les phrases parlent de ce qui est fait, pas
  /// de ce qui sera fait.
  final bool termine;

  /// La cle de la carte.
  static const Key carteKey = ValueKey<String>('import-compteurs');

  @override
  Widget build(BuildContext context) {
    final a = t.admin.importFormulaires.comptes;
    final f = t.admin.importFormulaires.rapport.compteurs;
    final List<Widget> quatre = <Widget>[
      _Compteur(
        cleValeur: const ValueKey<String>('import-compteur-nouvelles'),
        valeur: compteurs.nouvelles,
        libelle: a.nouvelles,
        aide: termine ? f.nouvelles : a.nouvellesAide,
      ),
      _Compteur(
        cleValeur: const ValueKey<String>('import-compteur-dejaConnues'),
        valeur: compteurs.dejaConnues,
        libelle: a.dejaConnues,
        aide: termine ? f.dejaConnues : a.dejaConnuesAide,
      ),
      _Compteur(
        cleValeur: const ValueKey<String>('import-compteur-ignorees'),
        valeur: compteurs.ignorees,
        libelle: a.ignorees,
        aide: a.ignoreesAide,
      ),
      _Compteur(
        cleValeur: const ValueKey<String>('import-compteur-aCorriger'),
        valeur: compteurs.aCorriger,
        libelle: a.aCorriger,
        aide: termine ? f.aCorriger : a.aCorrigerAide,
      ),
    ];
    return AppCard(
      key: carteKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final int colonnes = c.maxWidth >= 560 ? 4 : 2;
              final List<Widget> rangees = <Widget>[];
              for (int i = 0; i < quatre.length; i += colonnes) {
                if (i > 0) rangees.add(Ecart.vXl);
                rangees.add(
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        for (int k = i; k < i + colonnes; k++) ...<Widget>[
                          if (k > i) Ecart.hLg,
                          Expanded(child: quatre[k]),
                        ],
                      ],
                    ),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rangees,
              );
            },
          ),
          Ecart.vXl,
          LigneCleValeur(
            cle: a.lignesLues,
            valeur: '${compteurs.lignesLues}',
            chiffres: true,
            valeurEnFin: true,
          ),
          if (compteurs.corrigees > 0)
            LigneCleValeur(
              cle: a.corrigees,
              valeur: '${compteurs.corrigees}',
              chiffres: true,
              valeurEnFin: true,
            ),
          LigneCleValeur(
            cle: a.personnes,
            valeur: '${compteurs.personnes}',
            chiffres: true,
            valeurEnFin: true,
          ),
        ],
      ),
    );
  }
}

/// Une ligne d'une liste : son numero, sa phrase.
@immutable
class EntreeLigne {
  /// Cree l'entree.
  const EntreeLigne({
    required this.ligne,
    required this.texte,
    this.pastille,
    this.ton = TonEtat.neutre,
    this.complement,
  });

  /// Le numero de la ligne dans le fichier.
  final int ligne;

  /// Ce qu'il y a a dire de la ligne.
  final String texte;

  /// Un mot d'etat, a cote.
  final String? pastille;

  /// Le ton de la pastille.
  final TonEtat ton;

  /// Une seconde ligne, en retrait (la reference source du rapport).
  final String? complement;
}

/// Une carte qui liste des lignes du fichier, [lignesParPage] a la fois.
class ListeLignesCarte extends StatefulWidget {
  /// Cree la liste.
  const ListeLignesCarte({
    required this.cle,
    required this.titre,
    required this.entrees,
    required this.pasDeLignes,
    super.key,
    this.aide,
    this.ton = TonEtat.neutre,
    this.compteur,
  });

  /// La cle de la carte.
  final String cle;

  /// Le titre.
  final String titre;

  /// Une phrase sous le titre.
  final String? aide;

  /// Les lignes.
  final List<EntreeLigne> entrees;

  /// Le ton du compteur.
  final TonEtat ton;

  /// Le nombre affiche a cote du titre (par defaut, le nombre de lignes).
  final int? compteur;

  /// Ce que dit le lien « Voir … de plus » : le nombre de lignes cachees.
  final String Function(int n) pasDeLignes;

  @override
  State<ListeLignesCarte> createState() => _ListeLignesCarteEtat();
}

class _ListeLignesCarteEtat extends State<ListeLignesCarte> {
  int _montrees = lignesParPage;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    // Texte tres agrandi : la pastille passe sous la phrase, pas a cote.
    final bool empile =
        MediaQuery.textScalerOf(context).scale(1) > seuilTexteEmpile;
    final List<EntreeLigne> vues = widget.entrees
        .take(_montrees)
        .toList(growable: false);
    final int cachees = widget.entrees.length - vues.length;
    return AppCard(
      key: ValueKey<String>('import-liste-${widget.cle}'),
      entete: OverflowBar(
        alignment: MainAxisAlignment.spaceBetween,
        overflowAlignment: OverflowBarAlignment.start,
        spacing: AppSpacing.sm,
        overflowSpacing: AppSpacing.sm,
        children: <Widget>[
          Semantics(
            header: true,
            child: TexteSansCoupure(widget.titre, style: textes.titleMedium),
          ),
          StatusPill(
            libelle: '${widget.compteur ?? widget.entrees.length}',
            ton: widget.ton,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (widget.aide != null) ...<Widget>[
            TexteSansCoupure(widget.aide!, style: textes.bodyMedium),
            Ecart.vMd,
          ],
          for (final EntreeLigne e in vues) ...<Widget>[
            _LigneDeListe(
              key: ValueKey<String>('import-ligne-${widget.cle}-${e.ligne}'),
              entree: e,
              empile: empile,
            ),
            Ecart.vSm,
          ],
          if (cachees > 0)
            LienDebut(
              key: ValueKey<String>('import-plus-${widget.cle}'),
              libelle: widget.pasDeLignes(
                cachees < lignesParPage ? cachees : lignesParPage,
              ),
              onPress: () => setState(() => _montrees += lignesParPage),
            ),
        ],
      ),
    );
  }
}

/// Une ligne d'une liste : sa phrase, et son mot d'etat a cote ou dessous.
class _LigneDeListe extends StatelessWidget {
  const _LigneDeListe({required this.entree, required this.empile, super.key});

  final EntreeLigne entree;

  /// Vrai quand le texte est tres agrandi : le mot d'etat passe dessous.
  final bool empile;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final Widget phrase = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TexteSansCoupure(entree.texte, style: textes.bodyMedium),
        if (entree.complement != null)
          TexteSansCoupure(
            entree.complement!,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
      ],
    );
    final String? pastille = entree.pastille;
    if (pastille == null) return phrase;
    final Widget mot = StatusPill(libelle: pastille, ton: entree.ton);
    if (empile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[phrase, Ecart.vXs, mot],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: phrase),
        Ecart.hSm,
        mot,
      ],
    );
  }
}
