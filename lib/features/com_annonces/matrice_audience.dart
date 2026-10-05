// La matrice des regles de portee (`AudienceRulesMatrix`, spec section 13.4,
// section 17 COM-W04 ; COM-BR-11), sur `DataCollection` : tableau dense sur
// ordinateur, cartes ailleurs, une seule definition de colonnes.
//
// **Aucune ligne inventee depuis la maquette** : chaque ligne vient du port
// (`PortReglesAudience`) ; en production, le port est neutre et la section dit
// « pas encore disponible ». La maquette montrait « Familles : peut publier
// Oui », contraire a la spec section 13.4 : rien de cela n'est repris
// (UX_REVIEW L0, ecart 16). Des lignes de demonstration portent la marque
// « Démonstration ».
//
// Les reponses « Oui » / « Non » sont des mots, avec une pastille : jamais la
// couleur seule.
//
// La colonne « Validation requise » de la maquette n'est ni dans la spec
// section 13.4 ni dans section 17 COM-W04 : elle n'est montree que si le
// serveur la renseigne (hypothese COM-BR-11), jamais un « Non » sans source.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import 'annonces_planifiees.dart';
import 'port_regles_audience.dart';

/// La matrice des regles de portee.
class MatriceAudience extends ConsumerWidget {
  /// Cree la matrice.
  const MatriceAudience({super.key});

  /// La cle de la matrice, pour les tests.
  static const ValueKey<String> cle = ValueKey<String>(
    'administration-matrice',
  );

  /// La cle de la boite qui porte la collection, pour les tests.
  static const ValueKey<String> cleCollection = ValueKey<String>(
    'administration-matrice-collection',
  );

  /// La cle d'une ligne, pour les tests.
  static ValueKey<String> cleLigne(String id) =>
      ValueKey<String>('administration-regle-$id');

  /// La hauteur estimee de la collection, avant sa premiere mise en page :
  /// `DataCollection` defile elle-meme et demande une boite bornee. Tableau :
  /// l'en-tete puis une ligne de reglage par regle ; cartes : une carte de
  /// choix par regle ; le tout suit l'agrandissement du texte (`textScaler`).
  /// L'estimation n'est qu'un depart : [_HauteurNaturelle] agrandit la boite
  /// de ce qui deborde encore, pour que la matrice garde sa hauteur naturelle
  /// et ne devienne jamais une zone a defilement imbrique dans la page qui
  /// defile deja (texte x2, libelles longs, telephone).
  static double hauteurPour(BuildContext context, int lignes) {
    final double base = AppGabarit.de(context) == Gabarit.desktop
        ? AppSpacing.titreEcran + lignes * AppPage.hauteurReglage
        : lignes * (AppPage.hauteurChoix + AppSpacing.lg);
    final double facteur =
        MediaQuery.textScalerOf(context).scale(AppSpacing.lg) / AppSpacing.lg;
    return base * (facteur < 1 ? 1 : facteur);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = t.com.annonces.administration.matrice;
    final AsyncValue<ReglesAudience> lue = ref.watch(reglesAudienceProvider);
    final ReglesAudience? vue = lue.value;
    String ouiNon(bool v) => v ? m.oui : m.non;
    return Column(
      key: cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        EnTeteSectionAdministration(
          titre: m.titre,
          compteur: lue.hasError ? null : vue?.regles.length,
          demonstration: vue?.demonstration ?? false,
          detail: m.detail,
        ),
        Ecart.vMd,
        BlocAsynchrone<ReglesAudience>(
          valeur: lue,
          squelette: const Skeleton.liste(lignes: 3),
          onReessayer: () => ref.invalidate(reglesAudienceProvider),
          erreurVersEtat: (Object e, VoidCallback? r) =>
              etatErreurAdministration(ref, e, r),
          estVide: (ReglesAudience v) => v.regles.isEmpty,
          vide: EtatSysteme(
            nature: NatureEtat.aucunResultat,
            titre: m.vide,
            phrase: '',
          ),
          construire: (ReglesAudience v) => _HauteurNaturelle(
            key: cleCollection,
            estimee: hauteurPour(context, v.regles.length),
            child: DataCollection<RegleAudience>(
              lignes: v.regles,
              cle: (RegleAudience r) => cleLigne(r.id),
              colonnes: <ColonneDonnees<RegleAudience>>[
                ColonneDonnees<RegleAudience>(
                  titre: m.auteurs,
                  role: RoleColonne.identifiante,
                  flex: 2,
                  texte: (RegleAudience r) => r.auteurs,
                ),
                ColonneDonnees<RegleAudience>(
                  titre: m.peutPublier,
                  texte: (RegleAudience r) => ouiNon(r.peutPublier),
                  rendu: (BuildContext _, RegleAudience r) => Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: StatusPill(
                      libelle: ouiNon(r.peutPublier),
                      ton: r.peutPublier ? TonEtat.succes : TonEtat.neutre,
                    ),
                  ),
                ),
                ColonneDonnees<RegleAudience>(
                  titre: m.audiences,
                  role: RoleColonne.aPart,
                  flex: 3,
                  texte: (RegleAudience r) =>
                      r.audiences.isEmpty ? m.aucune : r.audiences,
                ),
                if (v.regles.any(
                  (RegleAudience r) => r.validationRequise != null,
                ))
                  ColonneDonnees<RegleAudience>(
                    titre: m.validation,
                    texte: (RegleAudience r) => switch (r.validationRequise) {
                      final bool oui => ouiNon(oui),
                      null => '',
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Une boite bornee qui prend la hauteur naturelle de la collection qu'elle
/// porte : elle part de [estimee], puis s'agrandit de ce que la liste
/// interieure peut encore defiler (`ScrollMetricsNotification`, emise apres
/// chaque mise en page qui change les mesures), jusqu'a ce que plus rien ne
/// defile.
class _HauteurNaturelle extends StatefulWidget {
  const _HauteurNaturelle({
    required this.estimee,
    required this.child,
    super.key,
  });

  final double estimee;
  final Widget child;

  @override
  State<_HauteurNaturelle> createState() => _HauteurNaturelleState();
}

class _HauteurNaturelleState extends State<_HauteurNaturelle> {
  late double _hauteur = widget.estimee;

  @override
  void didUpdateWidget(_HauteurNaturelle ancien) {
    super.didUpdateWidget(ancien);
    // Une autre estimation (lignes, gabarit, taille du texte) : on repart
    // d'elle, puis la boite s'ajuste de nouveau.
    if (ancien.estimee != widget.estimee) _hauteur = widget.estimee;
  }

  bool _mesurer(ScrollMetricsNotification notification) {
    final ScrollMetrics mesures = notification.metrics;
    if (notification.depth == 0 &&
        mesures.axis == Axis.vertical &&
        mesures.maxScrollExtent > 0) {
      setState(() => _hauteur += mesures.maxScrollExtent);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollMetricsNotification>(
        onNotification: _mesurer,
        child: SizedBox(height: _hauteur, child: widget.child),
      );
}
