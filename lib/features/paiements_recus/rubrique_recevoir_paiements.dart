// La rubrique « Paiements > Recevoir mes paiements », posee **une fois** dans
// Compte (`compte_page.dart`) et dans le Profil de l'enseignant
// (`profil_enseignant_page.dart`), une ligne chacun.
//
// Elle n'apparait que si le port de mes coordonnees de versement repond :
// c'est la capacite rendue par la source qui decide, **jamais le role** (un
// widget ne lit pas un role). Sans source, ou pour une personne qui n'est pas
// payee, le port rend `CapaciteIndisponible` : rien, aucun lien mort.
//
// Quand les coordonnees manquent ou sont incompletes, la notice « Informations
// de paiement a completer » vient avant la ligne, avec « Configurer mes
// paiements » (lot FINANCE-ENSEIGNANT, 06/11/2026).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_coordonnees_versement.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/nouveautes/nouveautes.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/lien_fleche.dart';
import 'etat_coordonnees.dart';

/// La rubrique, precedee de son ecart de section quand elle s'affiche.
class RubriqueRecevoirPaiements extends ConsumerWidget {
  /// Cree la rubrique.
  const RubriqueRecevoirPaiements({super.key});

  /// La cle de la ligne.
  static const Key ligneKey = ValueKey<String>('rubrique-recevoir-paiements');

  /// La cle de la notice.
  static const Key noticeKey = ValueKey<String>('notice-infos-paiement');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LigneRubrique? ligne = ligneRecevoirPaiements(context, ref);
    if (ligne == null) return const SizedBox.shrink();
    final Widget? avis = avisRecevoirPaiements(context, ref);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Ecart.vSection,
        if (avis != null) ...<Widget>[avis, Ecart.vLg],
        GroupeReglages(
          titre: t.comptable.beneficiaires.recevoir.rubrique,
          lignes: <LigneRubrique>[ligne],
          key: ligneKey,
        ),
      ],
    );
  }
}

/// Capacite absente, ou pas encore lue : `null`. Sinon, l'etat servi.
AsyncValue<MesCoordonneesVersement>? _etatServi(WidgetRef ref) {
  final AsyncValue<MesCoordonneesVersement> etat = ref.watch(
    mesCoordonneesVersementProvider,
  );
  if (!etat.hasValue &&
      (!etat.hasError || etat.error is CapaciteIndisponible)) {
    return null;
  }
  return etat;
}

void _ouvrirRecevoir(BuildContext context, WidgetRef ref) {
  marquerNouveauteVue(ref, CleNouveaute.recevoirPaiements);
  unawaited(context.push(Routes.comptePaiementsRecus));
}

/// La ligne « Recevoir mes paiements » (CPT-BEN-2), selon la capacite du
/// port : `null` quand elle est absente ou pas encore lue. Partagee par la
/// rubrique et par le Compte (PROFILS P4).
LigneRubrique? ligneRecevoirPaiements(BuildContext context, WidgetRef ref) {
  if (_etatServi(ref) == null) return null;
  final r = t.comptable.beneficiaires.recevoir;
  return LigneRubrique(
    libelle: r.titre,
    // NOUVEAUTES (07/11/2026).
    pastille: estNouveau(ref, CleNouveaute.recevoirPaiements)
        ? const BadgeNouveau(cle: CleNouveaute.recevoirPaiements)
        : null,
    legende: r.wise.titreCoordonnees,
    icone: AppIcons.paiements,
    onPress: () => _ouvrirRecevoir(context, ref),
  );
}

/// L'avis « coordonnees incompletes », quand le serveur le dit ; `null`
/// sinon.
Widget? avisRecevoirPaiements(BuildContext context, WidgetRef ref) {
  final AsyncValue<MesCoordonneesVersement>? etat = _etatServi(ref);
  final MesCoordonneesVersement? valeur = (etat != null && etat.hasValue)
      ? etat.value
      : null;
  if (valeur == null || valeur.complet) return null;
  final r = t.comptable.beneficiaires.recevoir;
  return BandeauAttention(
    key: RubriqueRecevoirPaiements.noticeKey,
    titre: r.notice,
    message: valeur.enregistre
        ? r.wise.phraseIncomplete
        : r.wise.phraseAucune(devise: valeur.deviseCible),
    action: LienFleche(
      libelle: r.configurer,
      onPress: () => _ouvrirRecevoir(context, ref),
    ),
  );
}
