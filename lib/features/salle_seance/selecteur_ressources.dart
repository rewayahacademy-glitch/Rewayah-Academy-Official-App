// Le selecteur de ressources de la salle enseignant (EN-10, 04 §19).
//
// Ordre : Recents, Cette Classe, Tous les supports, puis la recherche
// (04 §19.1). Mobile : dans la feuille du panneau Supports ; bureau : dans le
// panneau lateral (04 §19.2). Choisir une ressource appelle
// `ActionsSeance.onOuvrirSupport` : la salle reste ouverte (04 §19.3), rien
// n'est publie ici (aucun branchement serveur, K-28).

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/controle_segmente.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/selecteur_section.dart';
import 'actions_seance.dart';
import 'libelles_salle_b.dart';
import 'vue_seance.dart';

/// Les trois onglets, dans l'ordre de 04 §19.1.
enum OngletRessources { recents, cetteClasse, tous }

/// Le selecteur : onglets, recherche, liste.
class SelecteurRessources extends StatefulWidget {
  const SelecteurRessources({
    required this.supports,
    required this.actions,
    super.key,
  });

  final List<SupportDisponible> supports;
  final ActionsSeance actions;

  @override
  State<SelecteurRessources> createState() => _SelecteurRessourcesState();
}

class _SelecteurRessourcesState extends State<SelecteurRessources> {
  OngletRessources _onglet = OngletRessources.recents;
  String _recherche = '';
  final TextEditingController _champ = TextEditingController();

  @override
  void dispose() {
    _champ.dispose();
    super.dispose();
  }

  /// Choisir un onglet vide la recherche : sinon la liste, cherchee dans
  /// tous les supports, ne changerait pas (W-141).
  void _choisirOnglet(OngletRessources o) => setState(() {
    _onglet = o;
    _recherche = '';
    _champ.clear();
  });

  static String _libelle(OngletRessources onglet) => switch (onglet) {
    OngletRessources.recents => t.tc.bibliotheque.sections.recents,
    OngletRessources.cetteClasse => LibellesSalleB.cetteClasse,
    OngletRessources.tous => t.tc.bibliotheque.sections.tousLesSupports,
  };

  List<SupportDisponible> get _visibles {
    final String q = _recherche.trim().toLowerCase();
    return <SupportDisponible>[
      for (final SupportDisponible s in widget.supports)
        if (q.isNotEmpty
            ? s.titre.toLowerCase().contains(q)
            : switch (_onglet) {
                OngletRessources.recents =>
                  s.rubrique == RubriqueSupport.reprendre ||
                      s.rubrique == RubriqueSupport.recent,
                OngletRessources.cetteClasse =>
                  s.rubrique == RubriqueSupport.classe,
                OngletRessources.tous => true,
              })
          s,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme texte = Theme.of(context).textTheme;
    final List<SupportDisponible> visibles = _visibles;
    final ValueChanged<SupportDisponible>? ouvrir =
        widget.actions.onOuvrirSupport;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Trois sections exclusives : controle segmente, ou menu si les
          // libelles ne tiennent pas (ONGLETS-1).
          SelecteurSection<OngletRessources>(
            libelle: t.tc.bibliotheque.sections.groupe,
            valeur: _onglet,
            sections: <Segment<OngletRessources>>[
              for (final OngletRessources o in OngletRessources.values)
                Segment<OngletRessources>(valeur: o, libelle: _libelle(o)),
            ],
            onChange: _choisirOnglet,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const ValueKey<String>('recherche-ressources'),
            controller: _champ,
            onChanged: (String v) => setState(() => _recherche = v),
            decoration: InputDecoration(
              labelText: t.tc.bibliotheque.rechercheLibelle,
              hintText: t.tc.bibliotheque.rechercheIndication,
              prefixIcon: Icon(AppIcons.recherche.repos),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (visibles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              // Annonce en tapant (W-413, message d'etat).
              child: Semantics(
                liveRegion: true,
                child: Text(
                  t.tc.bibliotheque.aucunResultat.message,
                  style: palette.inkMuted.applyTo(
                    texte.bodyMedium ?? const TextStyle(),
                  ),
                ),
              ),
            )
          else
            for (final SupportDisponible s in visibles)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Pressable(
                  key: ValueKey<String>('ressource-${s.id}'),
                  libelleSemantique: t.salle.seance.panneauSupports
                      .ouvrirSupport(titre: s.titre),
                  onPress: ouvrir == null ? null : () => ouvrir(s),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: palette.surfaceOverlay.decoration(
                      borderRadius: AppRadius.arrondiMd,
                      side: palette.borderHairline.asBorderSide(),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(s.titre, style: texte.titleSmall),
                        Text(
                          s.detail,
                          style: palette.inkMuted.applyTo(
                            texte.bodySmall ?? const TextStyle(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
