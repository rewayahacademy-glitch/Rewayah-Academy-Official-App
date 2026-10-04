// L'espace de travail adaptatif des communications
// (`ResponsiveWorkspaceShell`, spec section 20, section 23 « Responsive »).
//
// UN seul composant, pas trois ecrans mobile, tablette et bureau. Il se pose
// DANS la coquille du role (NavShell, AdminShell) : la navigation reste celle
// du role, l'espace ne rend que ses panneaux. Il compte donc la largeur qu'il
// recoit (LayoutBuilder), pas celle de la fenetre, et ses seuils derivent des
// largeurs de panneaux ci-dessous, toutes tirees des jetons.
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

import '../../i18n/strings.g.dart';
import '../../icons/app_icons.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_spacing.dart';
import '../app_bottom_sheet.dart';
import '../bouton_icone.dart';

/// La surface montree quand une seule colonne tient.
enum SurfaceMobile {
  /// La liste (fils, canaux, publications).
  liste,

  /// Le contenu (fil, canal, publication).
  principal,
}

/// Le nombre de colonnes qu'une largeur donnee peut tenir.
///
/// Fonction pure, testee seule : 3 si la liste, le contenu et le contexte
/// tiennent cote a cote ; 2 si la liste et le contenu tiennent ; 1 sinon.
int colonnesPour(double largeur) {
  if (largeur >= EspaceTravailAdaptatif.largeurTroisColonnes) return 3;
  if (largeur >= EspaceTravailAdaptatif.largeurDeuxColonnes) return 2;
  return 1;
}

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

  /// La largeur de la colonne de liste : cinq paliers de respiration (320),
  /// celle du volet de la salle.
  static const double largeurListe = AppSpacing.respiration * 5;

  /// La largeur de la colonne de contexte (320).
  static const double largeurContexte = AppSpacing.respiration * 5;

  /// La largeur minimale du contenu en colonne : celle d'un etat vide (400).
  static const double largeurContenuMin = AppPage.largeurEtatVide;

  /// A partir de cette largeur recue, liste et contenu tiennent cote a cote.
  static const double largeurDeuxColonnes = largeurListe + largeurContenuMin;

  /// A partir de cette largeur recue, les trois colonnes tiennent.
  static const double largeurTroisColonnes =
      largeurListe + largeurContenuMin + largeurContexte;

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

    // Une colonne : une surface a la fois.
    if (colonnes == 1) {
      if (liste != null && widget.surfaceMobile == SurfaceMobile.liste) {
        return KeyedSubtree(key: EspaceTravailAdaptatif.cleListe, child: liste);
      }
      return _principalAvecBarre(
        retour: liste != null ? widget.onRetourListe : null,
        contexteEnFeuille: contexte != null,
      );
    }

    // Plusieurs colonnes : la liste d'abord, puis le contexte s'il reste une
    // colonne et qu'il est ouvert ; sinon il passe en feuille.
    final bool avecListe = liste != null;
    final int restantes = colonnes - 1 - (avecListe ? 1 : 0);
    final bool contexteEnColonne =
        contexte != null && _contexteOuvert && restantes >= 1;
    final bool boutonContexte = contexte != null && !contexteEnColonne;

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
          child: _filetDebut(
            palette,
            avecListe,
            _principalAvecBarre(
              retour: null,
              contexteEnFeuille: boutonContexte,
              // Le contexte ferme se rouvre en colonne s'il en a la place.
              rouvrirEnColonne: boutonContexte && restantes >= 1,
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
  /// voisine sans carte ni ombre.
  Widget _filetDebut(AppPalette palette, bool filet, Widget enfant) => filet
      ? DecoratedBox(
          decoration: BoxDecoration(
            border: BorderDirectional(
              start: palette.borderHairline.asBorderSide(),
            ),
          ),
          child: enfant,
        )
      : enfant;

  /// Le contenu, sous une barre qui n'existe que si elle porte un bouton
  /// (retour a la liste, ouverture du contexte) : jamais de bandeau vide,
  /// jamais un bouton pose sur le contenu.
  Widget _principalAvecBarre({
    required VoidCallback? retour,
    required bool contexteEnFeuille,
    bool rouvrirEnColonne = false,
  }) {
    final x = t.com.socle.composants.espace;
    final bool avecBarre = retour != null || contexteEnFeuille;
    final Widget principal = KeyedSubtree(
      key: EspaceTravailAdaptatif.clePrincipal,
      child: widget.principal,
    );
    if (!avecBarre) return principal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
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
        ),
        Expanded(child: principal),
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
