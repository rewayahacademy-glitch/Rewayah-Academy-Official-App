// La deuxieme etape de « Vos autres talents » (`CAND-07`) : les competences.
//
// **Precises, jamais des domaines vagues** (directeur, 22/10/2026) : la liste
// est celle du catalogue du serveur, que la direction complete sans nouvelle
// version de l'app, regroupee par famille pour se lire d'un coup d'oeil. Chaque
// competence est une carte decrite (ce que c'est, un cas concret) ; plusieurs
// choix. Sur grand ecran, chaque famille passe en Bento (`ChoiceCardGroup`),
// jamais les cartes du telephone etirees.
//
// **Un seul champ au clavier** : « Autre domaine », quelques mots, qui n'apparait
// qu'une fois la carte choisie. Tout le reste se touche.
//
// Une competence que la direction a desactivee depuis reste affichee, avec sa
// phrase, quand la personne l'avait deja choisie : elle la garde ou la decoche.
// Une competence dont le texte manque a l'application prend le libelle du
// catalogue ; un code sans aucun texte ne s'affiche pas.
library;

import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/modeles_autres_competences.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/champ_etiquete.dart';
import '../../core/widgets/choice_card_group.dart';
import 'controleur_talents.dart';
import 'libelles_talents.dart';

/// Le corps de l'etape des competences.
class EtapeCompetences extends StatefulWidget {
  /// Cree le corps.
  const EtapeCompetences({required this.controleur, super.key});

  /// Le parcours.
  final ControleurTalents controleur;

  /// La cle de la phrase « Plusieurs reponses possibles ».
  static const Key plusieursKey = ValueKey<String>('talents-plusieurs');

  /// La cle du champ « Autre domaine ».
  static const Key autreChampKey = ValueKey<String>('talents-autre-champ');

  /// La cle de la carte d'une competence.
  static Key carteKey(String code) => ValueKey<String>('talent-$code');

  /// La cle du groupe de cartes d'une famille.
  static Key familleKey(FamilleCompetence famille) =>
      ValueKey<String>('talents-famille-${famille.valeurSql}');

  @override
  State<EtapeCompetences> createState() => _EtapeCompetencesEtat();
}

class _EtapeCompetencesEtat extends State<EtapeCompetences> {
  late final TextEditingController _texte = TextEditingController(
    text: widget.controleur.autreTexte,
  );

  @override
  void dispose() {
    _texte.dispose();
    super.dispose();
  }

  /// Les competences offertes d'une famille, dans l'ordre du serveur.
  List<EntreeCatalogue> _offertes(FamilleCompetence famille) =>
      widget.controleur.lecture.referentiel.deLaFamille(famille);

  OptionChoix _option(EntreeCatalogue entree, FamilleCompetence famille) {
    final TextesCompetence textes = textesCompetence(entree);
    return OptionChoix(
      cle: EtapeCompetences.carteKey(entree.code),
      valeur: entree.code,
      libelle: textes.libelle,
      description: textes.description,
      // Une competence retiree du catalogue depuis le dernier choix : la
      // personne la garde ou la decoche, elle ne la reprend plus ensuite.
      explication: entree.actif
          ? null
          : t.recrutement.talents.competences.nonProposee,
      exemple: textes.exemple,
      icone: iconeFamille(famille),
      illustration: illustrationFamille(famille),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ControleurTalents c = widget.controleur;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final r = t.recrutement.talents.competences;
    final List<Widget> sections = <Widget>[];
    for (final String code in c.lecture.referentiel.familles) {
      final FamilleCompetence? famille = FamilleCompetence.depuisSql(code);
      if (famille == null) {
        // Une famille que cette version ne sait pas nommer ne s'affiche pas.
        continue;
      }
      final List<EntreeCatalogue> entrees = _offertes(famille);
      if (entrees.isEmpty) {
        continue;
      }
      final Set<String> codes = <String>{
        for (final EntreeCatalogue e in entrees) e.code,
      };
      sections.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // « Autre domaine » n'a pas de titre de famille : sa carte porte
            // deja ce nom, et le redire en titre ferait un doublon.
            if (famille != FamilleCompetence.autre) ...<Widget>[
              Semantics(
                header: true,
                child: TexteSansCoupure(
                  titreFamille(famille),
                  style: textes.titleLarge,
                ),
              ),
              Ecart.vMd,
            ],
            ChoiceCardGroup(
              key: EtapeCompetences.familleKey(famille),
              autoriserSaisieLibre: false,
              selectionMultiple: true,
              indicationMultiple: false,
              valeurInitiale: ReponseChoix(valeurs: c.choisiesParmi(codes)),
              options: <OptionChoix>[
                for (final EntreeCatalogue e in entrees) _option(e, famille),
              ],
              onChange: (ReponseChoix reponse) =>
                  c.definirFamille(codes, reponse.valeurs),
            ),
            if (famille == FamilleCompetence.autre &&
                c.autreChoisi) ...<Widget>[
              Ecart.vSm,
              ChampEtiquete(
                key: EtapeCompetences.autreChampKey,
                libelle: r.autreChamp,
                controller: _texte,
                aide: r.autreAide,
                onChanged: c.definirAutreTexte,
              ),
              Ecart.vLg,
            ],
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TexteSansCoupure(
          t.choix.selectionMultiple,
          key: EtapeCompetences.plusieursKey,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vXl,
        for (final (int i, Widget s) in sections.indexed) ...<Widget>[
          if (i > 0) Ecart.vSection,
          s,
        ],
      ],
    );
  }
}
