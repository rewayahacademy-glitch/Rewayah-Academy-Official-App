// NAV-REFONTE 2b (directeur, 10/11/2026 ; condition du garde-cap) : « la salle
// est-elle rejoignable ? » se calcule ici, une seule fois, pour un eleve du
// foyer. L'Accueil du tuteur (le bouton « Rejoindre la salle avec... ») et le
// halo vert du cercle Compte lisent ce meme provider ; aucun autre ecran ne
// refait ce calcul.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;

import '../../core/foyer/selection_eleve.dart';
import '../../core/seance_famille/port_seances_famille.dart';
import '../../core/seance_famille/seance_famille.dart';
import '../../core/tc_groupe/concierge_seance.dart' show refusEntreeProvider;
import '../../core/tc_horloge/horloge_vivante.dart';
import '../../core/tc_horloge/session_clock_vm.dart';
import '../acces_finance/acces_finance.dart'
    show OuvertureSeances, accesEleveProvider, ouvertureSeances;
import '../classe_tuteur/rejoindre_avec_eleve.dart'
    show
        classeRejoignableSansSeance,
        entrerAvecEleve,
        rejoindreClasseAvecEleve,
        salleRejoignable;
import 'accueil_famille_page.dart' show classeDeLEleveProvider;
import 'bloc_seance.dart' show AffichageSeance;

/// La cle du calcul : un eleve, a un instant serveur (`null` sans horloge
/// serveur : aucune salle n'est alors dite ouverte par la seance).
typedef CleSalleEleve = ({String eleveId, DateTime? maintenantServeurUtc});

/// Ou en est la salle d'un eleve : ouverte par sa seance, ouverte par
/// l'horloge de sa Classe (seance encore absente, le concierge la rend), ou
/// fermee.
@immutable
class SalleDeLEleve {
  /// Cree l'etat.
  const SalleDeLEleve({
    required this.parSeance,
    required this.parClasse,
    this.seance,
    this.groupeId,
    this.horlogeClasse,
  });

  /// La salle de [seance] est ouverte (ou la seance en direct) et l'acces de
  /// l'eleve n'est pas ferme.
  final bool parSeance;

  /// Sans seance rejoignable connue, l'horloge de la Classe ouvre la porte
  /// (concierge (a), pilote, 24/10/2026).
  final bool parClasse;

  /// La prochaine seance de l'eleve, telle que le serveur la rend.
  final SeanceFamille? seance;

  /// La Classe de l'eleve, `null` s'il n'en a pas.
  final String? groupeId;

  /// L'horloge de la Classe, lue seulement quand la seance n'ouvre pas deja
  /// la salle ; la carte de l'Accueil la montre aussi.
  final SessionClockVM? horlogeClasse;

  /// Vrai quand l'eleve peut entrer maintenant.
  bool get rejoignable => parSeance || parClasse;
}

/// La salle d'un eleve du foyer, **seule source** de « salle rejoignable »
/// cote tuteur (Accueil et halo du cercle Compte).
///
/// Une lecture absente ou en echec n'ouvre rien ; des seances fermees
/// (paiement, lot B du 02/11/2026) non plus : le serveur refuserait de toute
/// facon (porte `acces_paye`).
final ProviderFamily<SalleDeLEleve, CleSalleEleve> salleDeLEleveProvider =
    Provider.autoDispose.family<SalleDeLEleve, CleSalleEleve>((
      Ref ref,
      CleSalleEleve cle,
    ) {
      final String eleveId = cle.eleveId;
      final bool accesFerme =
          ouvertureSeances(ref.watch(accesEleveProvider(eleveId)).value) ==
          OuvertureSeances.fermees;
      final AsyncValue<SeanceFamille?> prochaine = ref.watch(
        prochaineSeanceProvider(eleveId),
      );
      final String? groupeId = ref
          .watch(classeDeLEleveProvider(eleveId))
          .value
          ?.classe
          .groupeId;
      final SeanceFamille? seance = prochaine.value;
      final bool parSeance =
          !accesFerme &&
          seance != null &&
          !prochaine.hasError &&
          salleRejoignable(
            AffichageSeance.depuis(
              seance,
              maintenantServeurUtc: cle.maintenantServeurUtc,
            ).etat,
          );
      final SessionClockVM? horloge = groupeId == null || parSeance
          ? null
          : ref.watch(horlogeClasseVivanteProvider(groupeId)).value;
      return SalleDeLEleve(
        parSeance: parSeance,
        parClasse:
            !parSeance &&
            !accesFerme &&
            groupeId != null &&
            classeRejoignableSansSeance(horloge),
        seance: seance,
        groupeId: groupeId,
        horlogeClasse: horloge,
      );
    });

/// Le premier eleve du foyer (dans l'ordre stable des profils) dont la salle
/// est rejoignable, avec cette salle ; `null` quand aucune ne l'est, ou que
/// les profils ne se lisent pas encore.
final ProviderFamily<
  ({ProfilEleveFoyer eleve, SalleDeLEleve salle})?,
  DateTime?
>
salleOuverteDuFoyerProvider = Provider.autoDispose
    .family<({ProfilEleveFoyer eleve, SalleDeLEleve salle})?, DateTime?>((
      Ref ref,
      DateTime? maintenantServeurUtc,
    ) {
      final List<ProfilEleveFoyer> profils =
          ref.watch(profilsElevesFoyerProvider).value ??
          const <ProfilEleveFoyer>[];
      for (final ProfilEleveFoyer eleve in profils) {
        final SalleDeLEleve salle = ref.watch(
          salleDeLEleveProvider((
            eleveId: eleve.eleveId,
            maintenantServeurUtc: maintenantServeurUtc,
          )),
        );
        if (salle.rejoignable) return (eleve: eleve, salle: salle);
      }
      return null;
    });

/// Le geste « Rejoindre la salle avec {prenom} » pour [salle] : par la seance,
/// sinon par l'horloge de la Classe. Le meme que les boutons de l'Accueil ;
/// la feuille « En ce moment » du halo vert l'appelle. Un refus du concierge
/// se lit sous le bouton de l'Accueil : [versAccueil] y mene alors.
void rejoindreSalleDeLEleve(
  BuildContext context, {
  required ProfilEleveFoyer eleve,
  required SalleDeLEleve salle,
  required VoidCallback versAccueil,
}) {
  final SeanceFamille? seance = salle.seance;
  if (salle.parSeance && seance != null) {
    entrerAvecEleve(context, seance, eleve);
    return;
  }
  final String? groupeId = salle.groupeId;
  if (salle.parClasse && groupeId != null) {
    unawaited(
      rejoindreClasseAvecEleve(
        context,
        groupeId: groupeId,
        sessionId: salle.horlogeClasse?.sessionId,
        eleve: eleve,
      ).then((_) {
        final bool refuse =
            context.mounted &&
            ProviderScope.containerOf(
                  context,
                  listen: false,
                ).read(refusEntreeProvider)[groupeId] !=
                null;
        if (refuse) versAccueil();
      }),
    );
    return;
  }
  versAccueil();
}
