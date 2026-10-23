// La rubrique « Paiements > Recevoir mes paiements » (spec §17, §27.1 ;
// CPT-BEN-2), posee **une fois** dans Compte (`compte_page.dart`) et dans le
// Profil de l'enseignant (`profil_enseignant_page.dart`), une ligne chacun.
//
// Elle n'apparait que si le port de mes moyens de paiement repond : c'est la
// capacite rendue par la source qui decide, **jamais le role** (un widget ne
// lit pas un role). En production, tant que CPT-BR-16 n'existe pas, le port
// rend `CapaciteIndisponible` : rien n'est affiche, aucun lien mort.
//
// Quand des informations manquent (§27.1, R-FIN-19), la notice « Informations
// de paiement a completer » vient avant la ligne, avec « Configurer mes
// paiements ».

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_mes_moyens_paiement.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/pastilles_comptable.dart';
import 'etat_mes_moyens.dart';

/// La rubrique, precedee de son ecart de section quand elle s'affiche.
class RubriqueRecevoirPaiements extends ConsumerWidget {
  /// Cree la rubrique.
  const RubriqueRecevoirPaiements({super.key});

  /// La cle de la ligne.
  static const Key ligneKey = ValueKey<String>('rubrique-recevoir-paiements');

  /// La cle de la notice §27.1.
  static const Key noticeKey = ValueKey<String>('notice-infos-paiement');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<EtatMesMoyensPaiement> etat = ref.watch(
      mesMoyensPaiementProvider,
    );
    // Capacite absente, ou pas encore lue : rien.
    if (!etat.hasValue &&
        (!etat.hasError || etat.error is CapaciteIndisponible)) {
      return const SizedBox.shrink();
    }
    final EtatMesMoyensPaiement? valeur = etat.hasValue ? etat.value : null;
    final r = t.comptable.beneficiaires.recevoir;
    void ouvrir() => context.push(Routes.comptePaiementsRecus);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Ecart.vSection,
        if (valeur != null && infosACompleter(valeur)) ...<Widget>[
          BandeauAttention(
            key: noticeKey,
            titre: r.notice,
            message: r.noticeDetail,
            action: LienFleche(libelle: r.configurer, onPress: ouvrir),
          ),
          Ecart.vLg,
        ],
        GroupeReglages(
          titre: r.rubrique,
          lignes: <LigneRubrique>[
            LigneRubrique(
              libelle: r.titre,
              legende: r.ligneDetail,
              icone: AppIcons.paiements,
              pastille: valeur == null
                  ? null
                  : PastilleProfilPaiement(valeur.etat),
              onPress: ouvrir,
            ),
          ],
          key: ligneKey,
        ),
      ],
    );
  }
}
