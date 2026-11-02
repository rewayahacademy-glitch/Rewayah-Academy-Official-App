import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/groupe_reglages.dart';

/// Qui signe le paragraphe des visites d'observation.
enum VarianteObservation {
  /// Un responsable legal, pour son enfant (defaut).
  responsableLegal,

  /// Un eleve adulte, son propre tuteur (ADR-009).
  eleveAdulte;

  /// La variante lue dans le parametre `?pour=` d'une route : `moi` designe
  /// l'eleve adulte, tout le reste le responsable legal.
  static VarianteObservation depuisParametre(String? pour) =>
      pour == 'moi' ? eleveAdulte : responsableLegal;
}

/// Le paragraphe signe des visites d'observation (decision 03 section 1 bis-3),
/// en UNE carte groupee (maquette M6) : qui observe et ce qu'il entend, ce
/// qu'il ne peut pas faire, pourquoi, et la limite des visites.
///
/// Le texte ne porte aucun chiffre : la politique de visites peut changer sans
/// changer le texte signe. Les valeurs sont dites par [ExplicationObservation]
/// depuis la politique effective.
class TexteObservation extends StatelessWidget {
  /// Cree le paragraphe.
  const TexteObservation({required this.variante, super.key});

  /// La variante a afficher.
  final VarianteObservation variante;

  @override
  Widget build(BuildContext context) {
    final bool adulte = variante == VarianteObservation.eleveAdulte;
    return GroupeReglages(
      lignes: <LigneRubrique>[
        LigneRubrique(
          icone: AppIcons.foyer,
          libelle: adulte
              ? t.consentement.texte.quiAdulte
              : t.consentement.texte.quiResponsable,
          legende: adulte
              ? t.consentement.texte.quiAdulteDetail
              : t.consentement.texte.quiResponsableDetail,
        ),
        LigneRubrique(
          icone: AppIcons.controleQualite,
          libelle: t.consentement.texte.pourquoi,
          legende: t.consentement.texte.pourquoiDetail,
        ),
        LigneRubrique(
          icone: AppIcons.attente,
          libelle: t.consentement.texte.limites,
          legende: t.consentement.texte.limitesDetail,
        ),
      ],
    );
  }
}

/// La case d'accord, **jamais precochee** : son etat vient toujours de
/// l'appelant, qui part de `false`.
class CaseAccordObservation extends StatelessWidget {
  /// Cree la case.
  const CaseAccordObservation({
    required this.variante,
    required this.cochee,
    required this.onChanged,
    super.key,
    this.focusNode,
    this.erreur,
  });

  /// Le noeud de focus de la case : il y revient quand l'accord manque
  /// (BOUTONS-GRISES-1).
  final FocusNode? focusNode;

  /// La phrase d'une case qui manque ([CaseAccordTexte.erreur]).
  final String? erreur;

  /// La variante du libelle.
  final VarianteObservation variante;

  /// L'etat de la case.
  final bool cochee;

  /// Appele au geste. `null` desactive la case (envoi en cours).
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => CaseAccordTexte(
    libelle: variante == VarianteObservation.eleveAdulte
        ? t.consentement.texte.caseAdulte
        : t.consentement.texte.caseResponsable,
    cochee: cochee,
    onChanged: onChanged,
    focusNode: focusNode,
    erreur: erreur,
  );
}

/// Une case d'accord a libelle libre, **jamais precochee** : son etat vient
/// toujours de l'appelant, qui part de `false`. La case des visites
/// d'observation et celle de l'article 9 du contrat enseignant en sont deux
/// usages.
class CaseAccordTexte extends StatelessWidget {
  /// Cree la case.
  const CaseAccordTexte({
    required this.libelle,
    required this.cochee,
    required this.onChanged,
    super.key,
    this.focusNode,
    this.erreur,
  });

  /// Le noeud de focus de la case : il y revient quand l'accord manque
  /// (BOUTONS-GRISES-1).
  final FocusNode? focusNode;

  /// Mode de la page des accords (UX-047, pilote 02/11/2026) : non nul quand
  /// « Suivant » a ete touche alors que cette case manque. La carte, sa case
  /// et son texte passent a l'encre d'alerte et la phrase s'affiche sous la
  /// carte ; elle disparait des que la case est cochee.
  final String? erreur;

  /// Le texte de l'accord, mot pour mot.
  final String libelle;

  /// L'etat de la case.
  final bool cochee;

  /// Appele au geste. `null` desactive la case (envoi en cours).
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final String? manque = cochee ? null : erreur;
    final Widget carte = _carte(context, alerte: manque != null);
    if (manque == null) {
      return carte;
    }
    final AppPalette palette = AppPalette.of(context);
    // Le contour d'alerte, pose par-dessus la carte : le filet de la carte
    // reste celui de son etat, la couleur dit ce qui manque.
    final Widget cerclee = DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: AppRadius.arrondiMd,
        border: Border.fromBorderSide(palette.inkAlert.asBorderSide(width: 2)),
      ),
      child: carte,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        cerclee,
        Ecart.vSm,
        Text(
          manque,
          key: const ValueKey<String>('case-accord-manque'),
          style: palette.inkAlert.applyTo(
            Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          ),
        ),
      ],
    );
  }

  Widget _carte(BuildContext context, {required bool alerte}) {
    final AppPalette palette = AppPalette.of(context);
    final ValueChanged<bool>? geste = onChanged;
    // E1 (demande du directeur du 17/10) : la carte entiere est la cible. Un
    // appui n'importe ou sur la carte, marge comprise, coche ou decoche :
    // `AppCard(onPress:)` pose un [Pressable] sur toute la surface (geste
    // opaque, curseur main sur le Web, Entree et Espace au clavier). Cochee,
    // la carte prend le registre de la selection (fond doux, contour
    // d'accent) : l'etat se voit sur toute la carte, pas sur la seule case.
    //
    // La case dessinee est une `Checkbox` Material, sans geste, sans focus et
    // sans semantique propres : la carte porte les trois, une seule cible et
    // un seul arret de tabulation.
    // Sans geste (envoi en cours, accord deja fige), la carte ne se presse
    // pas : meme regle qu'avant E1, quand `onChanged` nul figeait la case.
    // Case d'accord inactive voulue (DECISION-ENTREE-2026-10-17, accords et
    // consentements), admise dans tool/revue_socle.txt.
    return Semantics(
      checked: cochee,
      child: AppCard(
        selectionnee: cochee,
        // UX-047 : la case qui manque se voit en rouge, contour et texte.
        surface: alerte ? palette.washAlert : null,
        focusNode: focusNode,
        libelleSemantique: libelle,
        onPress: geste == null ? null : () => geste(!cochee),
        // AVIS-UI (24/10/2026) : la case s'aligne sur la premiere ligne du
        // texte, jamais au milieu d'un accord de plusieurs lignes.
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ExcludeSemantics(
              child: ExcludeFocus(
                child: IgnorePointer(
                  // Material transparent : la case le demande, sans peindre
                  // de fond sur celui de la carte.
                  child: Material(
                    type: MaterialType.transparency,
                    // Un rappel vide garde a la case l'aspect actif tant que
                    // la carte se presse ; c'est la carte qui agit.
                    child: Checkbox(
                      value: cochee,
                      isError: alerte,
                      onChanged: geste == null ? null : (bool? _) {},
                    ),
                  ),
                ),
              ),
            ),
            Ecart.hMd,
            Expanded(
              child: Padding(
                // La case occupe une cible de 48 : sa ligne mediane tombe a
                // 12 du haut, celle d'une ligne de corps de 24 aussi.
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: ExcludeSemantics(
                  excluding: geste != null,
                  child: Text(
                    libelle,
                    style: alerte
                        ? palette.inkAlert.applyTo(
                            Theme.of(context).textTheme.bodyLarge ??
                                const TextStyle(),
                          )
                        : Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
