// Les elements enregistres, vus depuis Le Studio (`SavedForLater`, spec
// section 8.3 ; arborescence section 15, « Le Studio > Elements
// enregistres » ; contrat COM-BR-12).
//
// Une liste de REFERENCES : chaque ligne nomme l'objet et sa nature, et
// l'ouvre a sa place d'origine (le canal, l'element) ; rien n'est copie ici.
// Un objet sans destination est nomme sans chevron ni geste (rien n'est
// grise). On retire un element la ou il vit (« Retirer » dans le panneau du
// canal), pour ne pas offrir deux endroits a la meme action.
//
// Tant qu'aucun contrat n'existe, le port de production rend
// `CapaciteIndisponible('COM-BR-12')` : l'ecran le dit, sans « Reessayer »
// ni liste vide inventee.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/communications/modeles_communication.dart';
import '../../core/communications/port_elements_enregistres.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/vue_etat_communication.dart';

/// Le mot de la nature d'un objet enregistre.
String libelleTypeEnregistre(TypeObjetLie type) {
  final x = t.com.studio.enregistres.types;
  return switch (type) {
    TypeObjetLie.canal => x.canal,
    TypeObjetLie.publication => x.publication,
    TypeObjetLie.message => x.message,
    TypeObjetLie.classe ||
    TypeObjetLie.eleve ||
    TypeObjetLie.dossier ||
    TypeObjetLie.mission ||
    TypeObjetLie.remplacement ||
    TypeObjetLie.annonce ||
    TypeObjetLie.autre => x.element,
  };
}

/// L'icone de la nature d'un objet enregistre.
AppIcon _icone(TypeObjetLie type) => switch (type) {
  TypeObjetLie.canal => AppIcons.discussion,
  TypeObjetLie.message => AppIcons.envoyerMessage,
  _ => AppIcons.texteStructure,
};

/// Les elements enregistres de la personne, depuis Le Studio.
class VueElementsEnregistres extends ConsumerStatefulWidget {
  /// Cree la vue.
  const VueElementsEnregistres({required this.onOuvrir, super.key});

  /// Ouvre la destination interne d'un element.
  final ValueChanged<String> onOuvrir;

  /// La cle du groupe des elements, pour les tests.
  static const ValueKey<String> cleListe = ValueKey<String>(
    'studio-enregistres-liste',
  );

  @override
  ConsumerState<VueElementsEnregistres> createState() =>
      _VueElementsEnregistresState();
}

class _VueElementsEnregistresState
    extends ConsumerState<VueElementsEnregistres> {
  AsyncValue<List<ElementEnregistre>> _elements =
      const AsyncValue<List<ElementEnregistre>>.loading();

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(
      () => _elements = const AsyncValue<List<ElementEnregistre>>.loading(),
    );
    final AsyncValue<List<ElementEnregistre>> lus =
        await AsyncValue.guard<List<ElementEnregistre>>(
          () => ref.read(portElementsEnregistresProvider).liste(),
        );
    if (!mounted) return;
    setState(() => _elements = lus);
  }

  @override
  Widget build(BuildContext context) {
    final e = t.com.studio.enregistres;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final Object? erreur = _elements.isLoading ? null : _elements.error;
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      children: <Widget>[
        // Hors ligne : le bandeau des communications, comme dans l'espace des
        // canaux ; la liste deja lue reste en place.
        if (horsLigne) ...<Widget>[
          const BandeauHorsLigneCommunication(encadre: true),
          Ecart.vLg,
        ],
        Text(
          e.detail,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vLg,
        // Une lecture en echec hors ligne dit la connexion, avec
        // « Reessayer » ; une capacite absente reste « indisponible ».
        if (horsLigne && erreur != null && erreur is! CapaciteIndisponible)
          VueEtatCommunication(
            etat: EtatCommunication.horsLigne,
            onReessayer: _charger,
          )
        else
          BlocCommunication<List<ElementEnregistre>>(
            valeur: _elements,
            onReessayer: _charger,
            titreVide: e.videTitre,
            phraseVide: e.vide,
            construire: (List<ElementEnregistre> elements) => GroupeReglages(
              key: VueElementsEnregistres.cleListe,
              lignes: <LigneRubrique>[
                for (final ElementEnregistre el in elements) _ligne(el),
              ],
            ),
          ),
      ],
    );
  }

  LigneRubrique _ligne(ElementEnregistre element) {
    final e = t.com.studio.enregistres;
    final ObjetLie objet = element.objet;
    final String? chemin = objet.destination;
    if (chemin == null) {
      return LigneRubrique(
        icone: _icone(objet.type),
        libelle: objet.libelle,
        legende: e.sansDestination(type: libelleTypeEnregistre(objet.type)),
      );
    }
    return LigneRubrique(
      icone: _icone(objet.type),
      libelle: objet.libelle,
      legende: libelleTypeEnregistre(objet.type),
      libelleSemantique: e.ouvrir(titre: objet.libelle),
      onPress: () => widget.onOuvrir(chemin),
    );
  }
}
