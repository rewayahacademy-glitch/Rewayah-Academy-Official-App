// Ce que le dossier montre de sa file (BE-SUIVANT) : « 3 sur 176 » avec deux
// fleches, le message qui precede le passage au suivant, la fin de file et le
// reglage « Passer au suivant apres une decision ».
//
// Rien ici ne decide : le rang, le total, le precedent et le suivant viennent
// du serveur (`suivant_dossier.dart`). Une commande qui ne peut pas aboutir
// n'est pas rendue (la fleche d'un bord disparait, sa place reste reservee).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/modeles_candidature_detail.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/barre_precedent_suivant.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/local_feedback.dart';
import 'suivant_dossier.dart';

/// « 3 sur 176 » et les deux fleches. Sans voisins lus (dossier sans file,
/// lecture en echec, dossier que le filtre ne contient pas), rien.
class NavigationFileDossier extends StatelessWidget {
  /// Cree la navigation.
  const NavigationFileDossier({
    required this.voisins,
    required this.onAller,
    super.key,
  });

  /// Les voisins du dossier dans sa file.
  final VoisinsCandidature voisins;

  /// Ouvre le dossier de reference donnee (il remplace le dossier courant).
  final ValueChanged<String> onAller;

  /// La cle de la navigation.
  static const Key cle = ValueKey<String>('dossier-navigation-file');

  @override
  Widget build(BuildContext context) {
    final int? rang = voisins.rang;
    final int? total = voisins.total;
    if (rang == null || total == null) return const SizedBox.shrink();
    final r = t.recrutement.suivant;
    final String? precedent = voisins.precedent;
    final String? suivant = voisins.suivant;
    return Align(
      key: cle,
      alignment: AlignmentDirectional.centerStart,
      child: BarrePrecedentSuivant(
        position: r.position(rang: rang, total: total),
        libellePrecedent: r.precedent,
        libelleSuivant: r.suivant,
        onPrecedent: precedent == null ? null : () => onAller(precedent),
        onSuivant: suivant == null ? null : () => onAller(suivant),
        etendue: false,
      ),
    );
  }
}

/// Ce qui suit une decision : la phrase qui la confirme, avec de quoi rester
/// sur ce dossier avant que le suivant ne s'ouvre ; ou, en fin de file, la
/// phrase qui le dit et le chemin de la liste.
class PassageAuSuivant extends StatelessWidget {
  /// Cree l'annonce.
  const PassageAuSuivant({
    required this.enCours,
    required this.finDeFile,
    required this.onRester,
    required this.onListe,
    super.key,
  });

  /// Vrai : le dossier suivant va s'ouvrir seul.
  final bool enCours;

  /// Vrai : la decision etait celle du dernier dossier de la file.
  final bool finDeFile;

  /// Reste sur ce dossier : le suivant ne s'ouvre pas.
  final VoidCallback onRester;

  /// Retourne a la liste.
  final VoidCallback onListe;

  /// La cle de l'annonce « le suivant s'ouvre ».
  static const Key cleEnCours = ValueKey<String>('dossier-passage-en-cours');

  /// La cle du bouton pour rester.
  static const Key cleRester = ValueKey<String>('dossier-passage-rester');

  /// La cle de la fin de file.
  static const Key cleFin = ValueKey<String>('dossier-fin-de-file');

  /// La cle du chemin vers la liste.
  static const Key cleListe = ValueKey<String>('dossier-fin-vers-liste');

  @override
  Widget build(BuildContext context) {
    final r = t.recrutement.suivant;
    if (enCours) {
      // La decision est deja enregistree au serveur : le bouton ne la defait
      // pas, il garde seulement ce dossier a l'ecran.
      // Le bouton est sous la phrase, pas dans sa rangee : « Rester sur ce
      // dossier » ne tient pas a cote d'elle a 360.
      return Column(
        key: cleEnCours,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LocalFeedback(message: r.decisionEnregistree, persistant: true),
          Ecart.vSm,
          ActionPrincipale(
            key: cleRester,
            libelle: r.rester,
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
            compacte: true,
            onPress: onRester,
          ),
        ],
      );
    }
    if (finDeFile) {
      return Column(
        key: cleFin,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TexteSansCoupure(
            r.fin,
            style: AppPalette.of(context).inkStrong.applyTo(
              Theme.of(context).textTheme.titleSmall ?? const TextStyle(),
            ),
          ),
          Ecart.vSm,
          ActionPrincipale(
            key: cleListe,
            libelle: r.versListe,
            niveau: NiveauAction.secondaire,
            pleineLargeur: false,
            compacte: true,
            onPress: onListe,
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

/// « Passer au suivant apres une decision » : un interrupteur, garde sur
/// l'appareil.
class ReglagePasserAuSuivant extends ConsumerWidget {
  /// Cree le reglage.
  const ReglagePasserAuSuivant({super.key});

  /// La cle de l'interrupteur.
  static const Key cleInterrupteur = ValueKey<String>('dossier-passer-suivant');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool actif = ref.watch(passerAuSuivantProvider);
    return GroupeReglages(
      lignes: <LigneRubrique>[
        LigneRubrique(
          libelle: t.recrutement.suivant.reglage,
          controle: Switch.adaptive(
            key: cleInterrupteur,
            value: actif,
            onChanged: (bool v) => unawaited(
              ref.read(passerAuSuivantProvider.notifier).choisir(actif: v),
            ),
          ),
        ),
      ],
    );
  }
}
