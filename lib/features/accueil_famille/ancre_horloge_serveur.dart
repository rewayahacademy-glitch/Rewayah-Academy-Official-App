import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/seance_famille/port_seances_famille.dart';

/// L'instant serveur lu a l'ouverture d'un ecran de seance (`maintenant_serveur()`,
/// contrat K2), ou `null` quand aucune horloge serveur ne repond.
///
/// `null` n'est pas une panne : chaque seance passe alors en
/// `horaireIncertain`, sans « Salle ouverte » ni compte a rebours affirme.
/// **Jamais `DateTime.now()` a sa place.** Lu par l'Accueil et par la Classe.
final FutureProvider<DateTime?> ancreServeurProvider =
    FutureProvider<DateTime?>((Ref ref) async {
      try {
        return (await ref
                .watch(portSeancesFamilleProvider)
                .maintenantServeurUtc())
            .toUtc();
      } on Object {
        return null;
      }
    });

/// L'instant serveur courant d'un ecran qui affiche un compte a rebours :
/// l'ancre lue une fois ([ancreServeurProvider]), avancee du temps ecoule sur
/// l'horloge de l'appareil depuis cette lecture, et une reconstruction toutes
/// les trente secondes.
///
/// Partage par l'Accueil et la Classe (lot C) : deux ecrans qui calculeraient
/// l'instant chacun a sa facon finiraient par ne plus dire la meme chose de la
/// meme seance.
///
/// ponytail: une seule lecture de l'horloge serveur par ouverture d'ecran ;
/// plafond : une derive de l'horloge de l'appareil pendant une tres longue
/// ouverture. Relire l'ancre periodiquement si cela se mesure.
mixin AncreHorlogeServeur<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// La cadence de rafraichissement : la ligne d'etat se lit a la minute.
  static const Duration cadence = Duration(seconds: 30);

  Timer? _minuteur;
  DateTime? _ancre;
  DateTime? _appareilALAncre;

  /// L'horloge de l'appareil, **pour mesurer un ecoulement seulement**.
  DateTime Function() get horlogeAppareil;

  @override
  void initState() {
    super.initState();
    _minuteur = Timer.periodic(cadence, (Timer _) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    super.dispose();
  }

  /// L'instant serveur courant, `null` sans horloge serveur.
  DateTime? maintenantServeur() {
    final DateTime? ancre = ref.watch(ancreServeurProvider).value;
    if (ancre == null) {
      return null;
    }
    if (_ancre != ancre || _appareilALAncre == null) {
      _ancre = ancre;
      _appareilALAncre = horlogeAppareil();
    }
    return ancre.add(horlogeAppareil().difference(_appareilALAncre!));
  }
}
