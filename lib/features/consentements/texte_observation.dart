import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
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
  });

  /// La variante du libelle.
  final VarianteObservation variante;

  /// L'etat de la case.
  final bool cochee;

  /// Appele au geste. `null` desactive la case (envoi en cours).
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final String libelle = variante == VarianteObservation.eleveAdulte
        ? t.consentement.texte.caseAdulte
        : t.consentement.texte.caseResponsable;
    final ValueChanged<bool>? geste = onChanged;
    return AppCard(
      child: MergeSemantics(
        child: InkWell(
          onTap: geste == null ? null : () => geste(!cochee),
          child: Row(
            children: <Widget>[
              Checkbox(
                value: cochee,
                onChanged: geste == null
                    ? null
                    : (bool? valeur) => geste(valeur ?? false),
              ),
              Expanded(
                child: Text(
                  libelle,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
