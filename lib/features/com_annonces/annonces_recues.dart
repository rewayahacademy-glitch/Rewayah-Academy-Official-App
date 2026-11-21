// La derniere annonce de l'academie, en UNE ligne (CLOCHE-C, decision du
// directeur du 21/11/2026, DECISION-ANNONCES-NOTIFS : « ca s'empile, toutes
// les annonces s'empilent et ne se ferment jamais […] imagine si on a 100
// annonces »). Plus de pile : au plus la derniere annonce non fermee ; la
// toucher ouvre la cloche (panneau ou feuille), ou toutes les annonces se
// lisent, se ferment et se paginent. Rien quand il n'y en a aucune, ou sans
// source (un mineur : le serveur refuse `com_mes_annonces`).
//
// Pose dans la page d'attente d'un compte qui n'a pas encore d'espace (la
// famille dont le dossier est en verification).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../notifications/cloche/annonces_cloche.dart';
import '../notifications/cloche/etat_annonces_cloche.dart';
import '../notifications/cloche/ligne_cloche.dart';
import '../notifications/cloche/ouvrir_cloche.dart';
import '../suivi_foyer/filtres_historique.dart';

/// La derniere annonce non fermee, en une ligne ; rien sinon.
class AnnoncesRecues extends ConsumerWidget {
  /// Cree la ligne. [ecartApres] la separe de ce qui la suit, quand elle est
  /// rendue.
  const AnnoncesRecues({super.key, this.ecartApres = Ecart.vLg});

  /// L'ecart pose sous la ligne quand elle est rendue.
  final Widget ecartApres;

  /// La cle de la ligne, pour les tests.
  static const ValueKey<String> cle = ValueKey<String>('annonces-recues');

  /// La cle de la ligne d'une annonce, pour les tests.
  static ValueKey<String> cleAnnonce(String id) =>
      ValueKey<String>('annonce-recue-$id');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EtatAnnoncesCloche etat = ref.watch(annoncesClocheProvider(false));
    final Map<String, bool> fermetures = ref.watch(fermeturesClocheProvider);
    final AnnonceCloche? derniere = etat.lues
        .where((AnnonceCloche a) => !(fermetures[a.id] ?? a.fermee))
        .firstOrNull;
    if (derniere == null) return const SizedBox.shrink();
    final DateTime quand = chezMoi(derniere.publieeLe);
    return Column(
      key: cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: AppRadius.arrondiMd,
          child: Builder(
            builder: (BuildContext ancre) => LigneCloche(
              key: cleAnnonce(derniere.id),
              categorie: CategorieLigneCloche.annonce,
              prefixe: t.notifications.cloche.annonce,
              titre: derniere.titre,
              quand: dateCourte(quand),
              nonLu: !derniere.vue,
              libelleSemantique: <String>[
                t.notifications.cloche.annonceLu(
                  titre: derniere.titre,
                  quand: dateCourte(quand),
                ),
                if (!derniere.vue) t.notifications.nonLueSemantique,
              ].join(', '),
              onOuvrir: () => unawaited(ouvrirCloche(ancre)),
            ),
          ),
        ),
        ecartApres,
      ],
    );
  }
}
