// L'espace de travail adaptatif des communications
// (`ResponsiveWorkspaceShell`, spec section 20, section 23 « Responsive »).
//
// UN seul composant, pas trois ecrans mobile, tablette et bureau. Il se pose
// DANS la coquille du role (NavShell, AdminShell) : la navigation reste celle
// du role, l'espace ne rend que ses panneaux. Il compte donc la largeur qu'il
// recoit (LayoutBuilder), pas celle de la fenetre, mais la classe sur la
// grille unique du depot, `AppGabarit.classe` (600 / 840 / 1200) : aucun
// seuil parallele. Ses colonnes laterales ont la largeur de la barre laterale
// permanente (`AppGabarit.largeurBarreLaterale`).
//
// Mesure dans la vraie coquille : a 768 (rail 80, gouttieres 2 x 24),
// l'espace recoit 640, classe « moyenne » : deux colonnes (maitre-detail) ;
// a 1440 (barre laterale, gouttieres 2 x 32), il recoit 1120, classe
// « etendue » : trois colonnes ; a 390, une.
//
// L'arbre ne change pas de forme quand le contexte se ferme, se rouvre ou que
// le nombre de colonnes change : le contenu garde son etat (brouillon du
// champ, position de lecture).
//
// - Une colonne : une surface a la fois (liste OU contenu) ; le contexte
//   s'ouvre en feuille temporaire (`AppBottomSheet`).
// - Deux colonnes : liste et contenu (maitre-detail) ; sans liste, contenu et
//   contexte ; le contexte qui n'a pas de place s'ouvre en feuille.
// - Trois colonnes : liste, contenu, contexte.
//
// Le panneau de contexte se ferme et se rouvre. Un panneau absent ou ferme ne
// laisse AUCUNE colonne vide : le contenu prend la place.

import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_gabarit.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'app_bottom_sheet.dart';
import 'bouton_icone.dart';

/// La surface montree quand une seule colonne tient.
enum SurfaceMobile {
  /// La liste (fils, canaux, publications).
  liste,

  /// Le contenu (fil, canal, publication).
  principal,
}

/// Le nombre de colonnes qu'une largeur donnee peut tenir.
///
/// Fonction pure, testee seule, sur la classe de largeur d'`AppGabarit` :
/// compacte, une colonne ; moyenne, deux ; etendue et large, trois. Au plus
/// bas de chaque classe, le contenu garde au moins 328 (840 - 2 x 256).
int colonnesPour(double largeur) => switch (AppGabarit.classe(largeur)) {
  ClasseLargeur.compacte => 1,
  ClasseLargeur.moyenne => 2,
  ClasseLargeur.etendue || ClasseLargeur.large => 3,
};

/// L'espace de travail adaptatif (`ResponsiveWorkspaceShell`).
///
/// [contexte] est un contenu a hauteur naturelle (une `Column`) : l'espace le
/// fait defiler lui-meme, en colonne comme en feuille. [principal] et [liste]
/// recoivent une hauteur bornee et gerent leur propre defilement (le fil
/// garde son champ visible au-dessus du clavier).
class EspaceTravailAdaptatif extends StatefulWidget {
  /// Cree l'espace.
  const EspaceTravailAdaptatif({
    required this.principal,
    super.key,
    this.liste,
    this.contexte,
    this.titreContexte,
    this.surfaceMobile = SurfaceMobile.principal,
    this.onRetourListe,
    this.contexteOuvertInitial = true,
    this.onContexteBascule,
  });

  /// Le contenu : toujours present.
  final Widget principal;

  /// La liste, ou `null` sans liste (aucune colonne n'est reservee).
  final Widget? liste;

  /// Le contexte (objet, participants, fichiers), ou `null` sans contexte.
  final Widget? contexte;

  /// Le titre du panneau de contexte ; par defaut « Contexte ».
  final String? titreContexte;

  /// La surface montree en une colonne. Sans [liste], toujours le contenu.
  final SurfaceMobile surfaceMobile;

  /// Le retour explicite du contenu vers la liste, en une colonne. Sans lui,
  /// aucun bouton de retour n'est rendu (le retour de la page suffit).
  final VoidCallback? onRetourListe;

  /// Le contexte est-il ouvert a l'arrivee (bureau) ?
  final bool contexteOuvertInitial;

  /// Previent l'appelant quand le panneau de contexte s'ouvre ou se ferme,
  /// pour qu'il le memorise s'il le souhaite.
  final ValueChanged<bool>? onContexteBascule;

  /// La largeur de la colonne de liste : celle de la barre laterale
  /// permanente (256), la colonne de navigation du produit.
  static const double largeurListe = AppGabarit.largeurBarreLaterale;

  /// La largeur de la colonne de contexte (256).
  static const double largeurContexte = AppGabarit.largeurBarreLaterale;

  /// A partir de cette largeur recue, liste et contenu tiennent cote a cote :
  /// le seuil tablette d'`AppGabarit`.
  static const double largeurDeuxColonnes = AppGabarit.seuilTablette;

  /// A partir de cette largeur recue, les trois colonnes tiennent : le seuil
  /// etendu d'`AppGabarit`.
  static const double largeurTroisColonnes = AppGabarit.seuilEtendu;

  /// Cle de la colonne qui porte le contenu, stable d'une disposition a
  /// l'autre (une ou plusieurs colonnes) pour que le contenu garde son etat.
  static const ValueKey<String> cleColonnePrincipale = ValueKey<String>(
    'espace-colonne-principale',
  );

  /// Cles, pour les tests.
  static const ValueKey<String> cleListe = ValueKey<String>('espace-liste');

  /// Cle de la colonne de contenu.
  static const ValueKey<String> clePrincipal = ValueKey<String>(
    'espace-principal',
  );

  /// Cle de la colonne de contexte.
  static const ValueKey<String> cleContexte = ValueKey<String>(
    'espace-contexte',
  );

  /// Cle du bouton qui ferme le contexte.
  static const ValueKey<String> cleFermerContexte = ValueKey<String>(
    'espace-fermer-contexte',
  );

  /// Cle du bouton qui ouvre le contexte.
  static const ValueKey<String> cleOuvrirContexte = ValueKey<String>(
    'espace-ouvrir-contexte',
  );

  /// Cle du bouton de retour a la liste.
  static const ValueKey<String> cleRetourListe = ValueKey<String>(
    'espace-retour-liste',
  );

  @override
  State<EspaceTravailAdaptatif> createState() => _EspaceTravailAdaptatifState();
}

class _EspaceTravailAdaptatifState extends State<EspaceTravailAdaptatif> {
  late bool _contexteOuvert = widget.contexteOuvertInitial;

  String get _titreContexte =>
      widget.titreContexte ?? t.com.socle.composants.espace.panneauContexte;

  void _basculer(bool ouvert) {
    setState(() => _contexteOuvert = ouvert);
    widget.onContexteBascule?.call(ouvert);
  }

  Future<void> _ouvrirFeuille() async {
    final Widget? contexte = widget.contexte;
    if (contexte == null) return;
    await AppBottomSheet.ouvrir<void>(
      context,
      titre: _titreContexte,
      constructeur: (BuildContext _) => contexte,
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints contraintes) {
      final int colonnes = colonnesPour(contraintes.maxWidth);
      return _disposer(context, colonnes);
    },
  );

  Widget _disposer(BuildContext context, int colonnes) {
    final Widget? liste = widget.liste;
    final Widget? contexte = widget.contexte;
    final AppPalette palette = AppPalette.of(context);

    // Une colonne, surface liste : la liste seule. Le contenu n'est pas
    // montre, il n'a pas d'etat a garder ici.
    if (colonnes == 1 &&
        liste != null &&
        widget.surfaceMobile == SurfaceMobile.liste) {
      return KeyedSubtree(key: EspaceTravailAdaptatif.cleListe, child: liste);
    }

    // Une colonne : le contenu seul, le contexte en feuille. Plusieurs : la
    // liste d'abord, puis le contexte s'il reste une colonne et qu'il est
    // ouvert ; sinon il passe en feuille.
    final bool uneColonne = colonnes == 1;
    final bool avecListe = !uneColonne && liste != null;
    final int restantes = colonnes - 1 - (avecListe ? 1 : 0);
    final bool contexteEnColonne =
        !uneColonne && contexte != null && _contexteOuvert && restantes >= 1;
    final bool boutonContexte = contexte != null && !contexteEnColonne;

    // Toujours la meme forme : Row > Expanded(cle stable) > filet > Column
    // [barre, Expanded(contenu)]. Seuls les freres cles (liste, contexte)
    // apparaissent ou disparaissent.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (avecListe)
          SizedBox(
            key: EspaceTravailAdaptatif.cleListe,
            width: EspaceTravailAdaptatif.largeurListe,
            child: liste,
          ),
        Expanded(
          key: EspaceTravailAdaptatif.cleColonnePrincipale,
          child: _filetDebut(
            palette,
            avecListe,
            _principalAvecBarre(
              retour: uneColonne && liste != null ? widget.onRetourListe : null,
              contexteEnFeuille: boutonContexte,
              // Le contexte ferme se rouvre en colonne s'il en a la place.
              rouvrirEnColonne: !uneColonne && boutonContexte && restantes >= 1,
            ),
          ),
        ),
        if (contexteEnColonne)
          SizedBox(
            key: EspaceTravailAdaptatif.cleContexte,
            width: EspaceTravailAdaptatif.largeurContexte,
            child: _filetDebut(palette, true, _colonneContexte(context)),
          ),
      ],
    );
  }

  /// Un filet fin au bord de debut d'une colonne, pour la detacher de sa
  /// voisine sans carte ni ombre. Le `DecoratedBox` est toujours la : seul
  /// son bord change, l'enfant garde sa place dans l'arbre.
  Widget _filetDebut(AppPalette palette, bool filet, Widget enfant) =>
      DecoratedBox(
        decoration: BoxDecoration(
          border: filet
              ? BorderDirectional(start: palette.borderHairline.asBorderSide())
              : null,
        ),
        child: enfant,
      );

  /// Le contenu, sous une barre qui n'existe que si elle porte un bouton
  /// (retour a la liste, ouverture du contexte) : jamais de bandeau vide,
  /// jamais un bouton pose sur le contenu. Le contenu reste toujours le
  /// second enfant de la meme `Column` : il garde son etat quand la barre
  /// apparait ou disparait.
  Widget _principalAvecBarre({
    required VoidCallback? retour,
    required bool contexteEnFeuille,
    bool rouvrirEnColonne = false,
  }) {
    final x = t.com.socle.composants.espace;
    final bool avecBarre = retour != null || contexteEnFeuille;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (avecBarre)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              children: <Widget>[
                if (retour != null)
                  BoutonIcone(
                    key: EspaceTravailAdaptatif.cleRetourListe,
                    icone: AppIcons.retour,
                    libelle: x.retourListe,
                    infobulle: x.retourListe,
                    onPress: retour,
                  ),
                const Spacer(),
                if (contexteEnFeuille)
                  BoutonIcone(
                    key: EspaceTravailAdaptatif.cleOuvrirContexte,
                    icone: AppIcons.info,
                    libelle: x.ouvrirPanneau,
                    infobulle: x.ouvrirPanneau,
                    onPress: rouvrirEnColonne
                        ? () => _basculer(true)
                        : _ouvrirFeuille,
                  ),
              ],
            ),
          )
        else
          const SizedBox.shrink(),
        Expanded(
          child: KeyedSubtree(
            key: EspaceTravailAdaptatif.clePrincipal,
            child: widget.principal,
          ),
        ),
      ],
    );
  }

  Widget _colonneContexte(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final x = t.com.socle.composants.espace;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.lg,
            end: AppSpacing.sm,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    _titreContexte,
                    style: palette.surfaceCanvas.applyTo(
                      textes.titleSmall ?? const TextStyle(),
                    ),
                  ),
                ),
              ),
              BoutonIcone(
                key: EspaceTravailAdaptatif.cleFermerContexte,
                icone: AppIcons.fermer,
                libelle: x.fermerPanneau,
                infobulle: x.fermerPanneau,
                onPress: () => _basculer(false),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: widget.contexte,
          ),
        ),
      ],
    );
  }
}
