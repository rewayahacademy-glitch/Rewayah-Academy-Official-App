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

  /// La cle d'une ligne, pour les tests.
  static ValueKey<String> cleLigne(String id) =>
      ValueKey<String>('administration-regle-$id');

  /// La hauteur reservee a la collection : elle defile elle-meme
  /// (`DataCollection`), dans une boite bornee. Tableau : l'en-tete puis une
  /// ligne de reglage par regle ; cartes : une carte de choix par regle.
  static double hauteurPour(BuildContext context, int lignes) =>
      AppGabarit.de(context) == Gabarit.desktop
      ? AppSpacing.titreEcran + lignes * AppPage.hauteurReglage
      : lignes * (AppPage.hauteurChoix + AppSpacing.lg);

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
          construire: (ReglesAudience v) => SizedBox(
            height: hauteurPour(context, v.regles.length),
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
                ColonneDonnees<RegleAudience>(
                  titre: m.validation,
                  texte: (RegleAudience r) => ouiNon(r.validationRequise),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
