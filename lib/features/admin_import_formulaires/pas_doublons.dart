// Pas 4 de l'import des formulaires (`ADM-23`) : les doublons.
//
// Une question : ces lignes viennent-elles de la meme personne ? Le serveur
// propose des cas (des lignes qui partagent un courriel ou un telephone) ; chacun
// dit la **nature** de sa cle (« Meme courriel »), jamais sa valeur. Sans choix,
// la ligne la plus recente est gardee et les autres restent dans l'historique
// (decision du directeur `CAND-Q16`) : l'ecran le dit, et la direction ne touche
// que les cas ou elle veut autre chose. Toucher un cas ouvre sa question, sur une
// page, en cartes qu'on touche ; le choix s'applique tout de suite.
library;

import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/modeles_import_candidatures.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/setting_row.dart';
import 'composants_import.dart';
import 'controleur_import.dart';
import 'libelles_import.dart';

/// Combien de cas la liste montre avant « Voir … de plus ».
const int casParPage = 20;

const String _valeurDefaut = 'defaut';
const String _valeurDistinctes = 'distinctes';
String _valeurLigne(int ligne) => 'ligne:$ligne';

/// Le pas « Doublons ».
class PasDoublons extends StatefulWidget {
  /// Cree le pas.
  const PasDoublons({
    required this.controleur,
    required this.empile,
    super.key,
  });

  /// Le controleur de l'import.
  final ControleurImportCandidatures controleur;

  /// Vrai sur telephone.
  final bool empile;

  /// La cle de la liste des cas.
  static const Key listeKey = ValueKey<String>('import-doublons-liste');

  /// La cle de la page d'un cas.
  static const Key casKey = ValueKey<String>('import-doublons-cas');

  @override
  State<PasDoublons> createState() => _PasDoublonsEtat();
}

class _PasDoublonsEtat extends State<PasDoublons> {
  String? _ouvert;
  int _montres = casParPage;

  ControleurImportCandidatures get _c => widget.controleur;

  List<GroupeDoublons> get _groupes =>
      _c.apercu?.groupes ?? const <GroupeDoublons>[];

  @override
  Widget build(BuildContext context) {
    final GroupeDoublons? ouvert = _ouvert == null
        ? null
        : _groupes.where((GroupeDoublons g) => g.id == _ouvert).firstOrNull;
    return ouvert == null ? _liste() : _cas(ouvert);
  }

  // --- la liste ---

  Widget _liste() {
    final a = t.admin.importFormulaires.doublons;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final List<GroupeDoublons> groupes = _groupes;
    final List<GroupeDoublons> vus = groupes
        .take(_montres)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        QuestionDuPas(question: a.question, explication: a.explication),
        Ecart.vXl,
        if (groupes.isEmpty)
          EmptyState(
            key: const ValueKey<String>('import-doublons-aucun'),
            message: a.aucun,
            invitation: a.aucunAide,
            icone: AppIcons.succes,
            registre: RegistreVide.bonneNouvelle,
          )
        else ...<Widget>[
          TexteSansCoupure(
            a.total(n: groupes.length),
            key: const ValueKey<String>('import-doublons-total'),
            style: textes.titleMedium,
          ),
          Ecart.vXs,
          TexteSansCoupure(
            a.tranches(
              choisis: '${_c.groupesTranches}',
              total: '${groupes.length}',
            ),
            key: const ValueKey<String>('import-doublons-tranches'),
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vLg,
          CarteLignes(
            key: PasDoublons.listeKey,
            lignes: <Widget>[
              for (final GroupeDoublons g in vus)
                SettingRow(
                  key: ValueKey<String>('import-doublon-${g.id}'),
                  icon: AppIcons.rapprochement,
                  title: libelleNature(g.nature),
                  description: '${_lignesDuCas(g)}\n${_etat(g)}',
                  onPress: () => setState(() => _ouvert = g.id),
                ),
            ],
          ),
          if (groupes.length > vus.length) ...<Widget>[
            Ecart.vMd,
            LienDebut(
              key: const ValueKey<String>('import-doublons-plus'),
              libelle: a.plus(
                n: groupes.length - vus.length < casParPage
                    ? groupes.length - vus.length
                    : casParPage,
              ),
              onPress: () => setState(() => _montres += casParPage),
            ),
          ],
        ],
        Ecart.vLg,
        ActionsDuPas(
          empile: widget.empile,
          libelleAction: t.commun.continuer,
          onAction: _c.suivant,
          onRetour: _c.precedent,
        ),
      ],
    );
  }

  String _lignesDuCas(GroupeDoublons g) {
    final a = t.admin.importFormulaires.doublons;
    final String lignes = a.lignes(
      liste: listeDe(<String>[for (final int l in g.lignes) '$l']),
    );
    final int enBase = g.taille - g.lignes.length;
    return enBase > 0 ? '$lignes ${a.dansLaBase(n: enBase)}' : lignes;
  }

  String _etat(GroupeDoublons g) {
    final a = t.admin.importFormulaires.doublons.etat;
    return switch (_c.choixDuGroupe(g.id)) {
      GardeLigne(:final int ligne) => a.ligne(ligne: ligne),
      PersonnesDistinctes() => a.distinctes,
      ParDefaut() =>
        g.choisi
            ? a.enregistre
            : g.retenueProposee == null && g.retenueDansLaBase
            ? a.base
            : a.recente,
    };
  }

  // --- la question d'un cas ---

  Widget _cas(GroupeDoublons g) {
    final a = t.admin.importFormulaires.doublons;
    final int rang = _groupes.indexWhere((GroupeDoublons x) => x.id == g.id);
    final ChoixGroupe actuel = _c.choixDuGroupe(g.id);
    final String valeur = switch (actuel) {
      ParDefaut() => _valeurDefaut,
      GardeLigne(:final int ligne) => _valeurLigne(ligne),
      PersonnesDistinctes() => _valeurDistinctes,
    };
    return Column(
      key: PasDoublons.casKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        QuestionDuPas(
          question: a.casTitre(
            nature: libelleNature(g.nature),
            n: rang + 1,
            total: _groupes.length,
          ),
          explication: '${_lignesDuCas(g)}. ${a.choisirLigne}',
        ),
        Ecart.vXl,
        ChoiceCardGroup(
          autoriserSaisieLibre: false,
          valeurInitiale: ReponseChoix(valeurs: <String>{valeur}),
          options: _options(g),
          onChange: (ReponseChoix r) {
            if (r.valeurs.isEmpty) return;
            final String v = r.valeurs.first;
            _c.choisir(
              g.id,
              v == _valeurDistinctes
                  ? const PersonnesDistinctes()
                  : v.startsWith('ligne:')
                  ? GardeLigne(int.parse(v.substring('ligne:'.length)))
                  : const ParDefaut(),
            );
            setState(() => _ouvert = null);
          },
        ),
        Ecart.vLg,
        ActionsDuPas(
          empile: widget.empile,
          onRetour: () => setState(() => _ouvert = null),
        ),
      ],
    );
  }

  List<OptionChoix> _options(GroupeDoublons g) {
    final o = t.admin.importFormulaires.doublons.option;
    final bool distinctesEnregistre = g.choisi && g.choix == retenueDistinctes;
    final OptionChoix defaut;
    if (g.choisi) {
      defaut = OptionChoix(
        valeur: _valeurDefaut,
        cle: const ValueKey<String>('import-doublon-option-defaut'),
        libelle: o.enregistre.titre,
        description: distinctesEnregistre
            ? o.enregistre.distinctes
            : o.enregistre.ligne,
        icone: AppIcons.rapprochement,
      );
    } else if (g.retenueProposee == null && g.retenueDansLaBase) {
      defaut = OptionChoix(
        valeur: _valeurDefaut,
        cle: const ValueKey<String>('import-doublon-option-defaut'),
        libelle: o.base.titre,
        description: o.base.description,
        icone: AppIcons.rapprochement,
      );
    } else {
      defaut = OptionChoix(
        valeur: _valeurDefaut,
        cle: const ValueKey<String>('import-doublon-option-defaut'),
        libelle: o.recente.titre(
          ligne: g.retenueProposee ?? (g.lignes.isEmpty ? 0 : g.lignes.last),
        ),
        description: o.recente.description,
        icone: AppIcons.rapprochement,
      );
    }
    return <OptionChoix>[
      defaut,
      for (final int l in g.lignes)
        if (l != g.retenueProposee)
          OptionChoix(
            valeur: _valeurLigne(l),
            cle: ValueKey<String>('import-doublon-option-ligne-$l'),
            libelle: o.ligne.titre(ligne: l),
            description: o.ligne.description,
            icone: AppIcons.succes,
          ),
      if (!distinctesEnregistre)
        OptionChoix(
          valeur: _valeurDistinctes,
          cle: const ValueKey<String>('import-doublon-option-distinctes'),
          libelle: o.distinctes.titre,
          description: o.distinctes.description,
          exemple: o.distinctes.exemple,
          icone: AppIcons.eleves,
        ),
    ];
  }
}
