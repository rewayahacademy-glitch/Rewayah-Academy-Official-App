import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
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
  });

  /// Le noeud de focus de la case : il y revient quand l'accord manque
  /// (BOUTONS-GRISES-1).
  final FocusNode? focusNode;

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
  });

  /// Le noeud de focus de la case : il y revient quand l'accord manque
  /// (BOUTONS-GRISES-1).
  final FocusNode? focusNode;

  /// Le texte de l'accord, mot pour mot.
  final String libelle;

  /// L'etat de la case.
  final bool cochee;

  /// Appele au geste. `null` desactive la case (envoi en cours).
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
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
    final VoidCallback? basculer = geste == null ? null : () => geste(!cochee);
    return Semantics(
      checked: cochee,
      child: AppCard(
        selectionnee: cochee,
        focusNode: focusNode,
        libelleSemantique: libelle,
        onPress: basculer,
        child: Row(
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
                      onChanged: geste == null ? null : (bool? _) {},
                    ),
                  ),
                ),
              ),
            ),
            Ecart.hMd,
            Expanded(
              child: ExcludeSemantics(
                excluding: geste != null,
                child: Text(
                  libelle,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
