// PE-B3 (directeur, 05/11/2026 : « une donnee saisie doit servir » ;
// PARCOURS-ENSEIGNANT/PLAN §2.7) : ce que le candidat a saisi hors du
// questionnaire et qu'il ne revoyait nulle part, montre dans « Votre
// candidature » : son nom en lettres latines (`lire_nom_latin`) et sa ville
// (`mon_lieu`).
//
// Rien n'est calcule ici : les deux valeurs viennent du serveur. Le telephone
// n'y est pas : aucune lecture du serveur ne le rend a son titulaire (manque
// cote serveur, dit dans le rapport du lot).
//
// Etats : chargement (squelette de deux lignes), contenu, vide (rien a montrer :
// le bloc ne prend aucune place), erreur (« Reessayer », la page autour reste),
// hors connexion (meme chemin que l'erreur, le bandeau de la page le dit).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/candidature/port_nom_latin.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/pays_iso.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/lieu/lieu.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/skeleton.dart';

/// Ce que le bloc montre : chaque valeur, ou `null` quand il n'y en a pas.
@immutable
class IdentiteCandidature {
  /// Cree la lecture.
  const IdentiteCandidature({this.nomLatin, this.ville});

  /// Le nom confirme en lettres latines, quand il differe du nom d'origine.
  final String? nomLatin;

  /// La ville choisie et son pays, deja mis en mots.
  final String? ville;

  /// Rien a montrer.
  bool get vide => nomLatin == null && ville == null;
}

/// Les deux lectures du serveur, en une. Le nom latin n'est montre que s'il a
/// ete confirme : un nom d'origine deja latin ne se repete pas.
final FutureProvider<IdentiteCandidature> identiteCandidatureProvider =
    FutureProvider.autoDispose<IdentiteCandidature>((Ref ref) async {
      final EtatNomLatin? nom = await ref.watch(etatNomLatinProvider.future);
      final LieuChoisi? lieu = await ref.watch(monLieuProvider.future);
      final String? latin = nom?.nomLatin?.trim();
      return IdentiteCandidature(
        nomLatin:
            latin == null || latin.isEmpty || latin == nom?.nomComplet.trim()
            ? null
            : latin,
        ville: lieu == null
            ? null
            : t.lieu.villeLigne(
                ville: lieu.ville,
                pays: nomDuPays(lieu.paysCode),
              ),
      );
    }, retry: (int _, Object _) => null);

/// Le bloc « Votre nom et votre ville » de « Votre candidature ».
class BlocIdentiteCandidature extends ConsumerWidget {
  /// Cree le bloc.
  const BlocIdentiteCandidature({super.key});

  /// La cle du bloc.
  static const Key cle = ValueKey<String>('lecture-identite');

  /// La cle de la ligne du nom latin.
  static const Key cleNomLatin = ValueKey<String>('lecture-nom-latin');

  /// La cle de la ligne de la ville.
  static const Key cleVille = ValueKey<String>('lecture-ville');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<IdentiteCandidature> valeur = ref.watch(
      identiteCandidatureProvider,
    );
    // Rien a montrer : le bloc ne prend aucune place, pas meme son ecart.
    if (valeur.hasValue && !valeur.hasError && valeur.requireValue.vide) {
      return const SizedBox.shrink(key: cle);
    }
    return Padding(
      key: cle,
      padding: const EdgeInsets.only(top: AppSpacing.section),
      child: _bloc(ref, valeur, textes),
    );
  }

  Widget _bloc(
    WidgetRef ref,
    AsyncValue<IdentiteCandidature> valeur,
    TextTheme textes,
  ) {
    return BlocAsynchrone<IdentiteCandidature>(
      valeur: valeur,
      squelette: const Skeleton.liste(lignes: 2),
      onReessayer: () => ref
        ..invalidate(etatNomLatinProvider)
        ..invalidate(monLieuProvider)
        ..invalidate(identiteCandidatureProvider),
      estVide: (IdentiteCandidature v) => v.vide,
      vide: const SizedBox.shrink(),
      construire: (IdentiteCandidature v) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              t.recrutement.questionnaire.identiteTitre,
              style: textes.titleMedium,
            ),
          ),
          Ecart.vSm,
          CarteLignes(
            lignes: <Widget>[
              if (v.nomLatin case final String nom)
                SettingRow(
                  key: cleNomLatin,
                  title: t.inscription.nomLatin.court,
                  // Un nom latin reste de gauche a droite dans une page arabe.
                  value: isolerSens(nom),
                ),
              if (v.ville case final String ville)
                SettingRow(
                  key: cleVille,
                  title: t.lieu.colonneVille,
                  value: ville,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
