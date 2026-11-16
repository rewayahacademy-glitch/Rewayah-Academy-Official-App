// Un bandeau d'attention que la personne ferme une fois (« J'ai compris ») :
// le choix reste dans la memoire de l'appareil, pas sur le compte. Un seul
// composant pour tous les bandeaux d'information qu'on n'a pas besoin de relire
// a chaque ouverture (PIECE-DANS-DOSSIER, directeur, 16/11/2026) ; il enveloppe
// [BandeauAttention], jamais une copie.
//
// Tant que la memoire n'est pas lue, rien ne s'affiche (jamais un bandeau qui
// disparait d'un coup apres l'ouverture) ; si elle est illisible, le bandeau
// reste visible. La fermeture se fait par un fondu de hauteur.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/strings.g.dart';
import '../observabilite/journal_dev.dart';
import '../preferences/preferences_locales.dart';
import '../theme/app_mouvement.dart';
import 'bandeau_attention.dart';
import 'lien_fleche.dart';
import 'status_pill.dart' show TonEtat;

/// Le bandeau fermable.
class BandeauFermable extends ConsumerStatefulWidget {
  /// Cree le bandeau ; [clef] est le nom, dans la memoire de l'appareil, de ce
  /// qui a ete vu.
  const BandeauFermable({
    required this.clef,
    required this.titre,
    required this.message,
    this.ton = TonEtat.avertissement,
    super.key,
  });

  /// La clef de la memoire de l'appareil (par exemple `bandeau.exceptionKyc`).
  final String clef;

  /// Ce qui se passe, en quelques mots.
  final String titre;

  /// La consequence ou la cause utile.
  final String message;

  /// La famille de l'attention.
  final TonEtat ton;

  /// La cle du lien « J'ai compris ».
  static const Key cleFermer = ValueKey<String>('bandeau-fermable-fermer');

  @override
  ConsumerState<BandeauFermable> createState() => _EtatBandeauFermable();
}

class _EtatBandeauFermable extends ConsumerState<BandeauFermable> {
  /// `null` : memoire pas encore lue ; vrai : deja ferme.
  bool? _ferme;

  @override
  void initState() {
    super.initState();
    unawaited(_lire());
  }

  Future<void> _lire() async {
    bool ferme = false;
    try {
      ferme =
          await ref.read(stockagePreferencesProvider).lire(widget.clef) == 'vu';
    } on Object catch (erreur) {
      journalDev('Bandeau ${widget.clef} : memoire illisible ($erreur)');
    }
    if (mounted) setState(() => _ferme = ferme);
  }

  Future<void> _fermer() async {
    setState(() => _ferme = true);
    try {
      await ref.read(stockagePreferencesProvider).ecrire(widget.clef, 'vu');
    } on Object catch (erreur) {
      journalDev('Bandeau ${widget.clef} : fermeture non gardee ($erreur)');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool visible = _ferme == false;
    return AnimatedSize(
      duration: AppMouvement.duree(context, AppMouvement.apparition),
      curve: AppMouvement.entree,
      alignment: AlignmentDirectional.topCenter,
      child: visible
          ? BandeauAttention(
              titre: widget.titre,
              message: widget.message,
              ton: widget.ton,
              action: LienFleche(
                key: BandeauFermable.cleFermer,
                libelle: t.accuse.compris,
                alignerEnDebut: true,
                onPress: () => unawaited(_fermer()),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}
