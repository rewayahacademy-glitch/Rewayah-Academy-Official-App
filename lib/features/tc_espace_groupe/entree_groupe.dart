// NAV-REFONTE 2c (directeur, 10/11/2026 ; schema accepte par le garde-cap le
// 11/11/2026) : l'entree de la carte de seance d'une Classe (« Rejoindre » ou
// une ligne d'etat) se calcule ici, une seule fois, pour les ecrans de
// `LecteurGroupe` (Espace de la Classe, Ma classe adulte, Accueil adulte) et
// pour le halo vert du cercle Compte de l'eleve adulte. Le meme flux
// d'horloge, emis aux bascules : la carte et le cercle changent ensemble.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart'
    show ProviderFamily, ProviderOrFamily;

import '../../core/reseau/service_reseau.dart' show horsLigneProvider;
import '../../core/tc_groupe/group_home_vm.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/tc_groupe/port_groupes.dart' show groupeProvider;
import '../../core/tc_horloge/emplacement_entree.dart';
import '../../core/tc_horloge/port_horloge_seance.dart'
    show horlogeGroupeProvider;
import '../../core/tc_horloge/session_clock_vm.dart';
import '../acces_finance/acces_finance.dart'
    show accesAppelantProvider, rejoindreSelonAcces;
import 'carte_session.dart';
import 'emplacements_groupe.dart' show seanceAnnuleeProvider;

/// La cle : la Classe, qui regarde, et deux entrees de la fonction pure (le
/// libelle et le geste du bouton), jamais une decision d'ecran.
typedef CleEntreeGroupe = ({
  String groupeId,
  RoleEspaceGroupe role,
  bool tutoiement,
  bool seanceParServeur,
});

/// L'entree de la carte de seance d'une Classe.
@immutable
class EntreeCarte {
  /// Cree l'entree.
  const EntreeCarte({
    required this.groupe,
    required this.emplacement,
    required this.retiree,
    required this.enLecture,
  });

  /// La Classe lue, son horloge a jour.
  final GroupSummaryVM groupe;

  /// L'emplacement d'entree ([CarteSession.emplacementPour]), `null` sans
  /// horloge ni seance.
  final EmplacementEntree? emplacement;

  /// Seances fermees (FI-9a) : « Rejoindre » est retire de la carte.
  final bool retiree;

  /// L'acces se lit encore : « Rejoindre » reste present et inerte.
  final bool enLecture;

  /// Vrai quand « Rejoindre » est offert maintenant : un bouton, non retire.
  bool get rejoignable => !retiree && (emplacement?.estBouton ?? false);
}

/// L'entree de la carte de seance de la Classe, `null` tant que la Classe ne
/// se lit pas (ou ne se trouve pas). La seule source des ecrans de
/// `LecteurGroupe` et du halo vert de l'eleve adulte.
final ProviderFamily<EntreeCarte?, CleEntreeGroupe> entreeGroupeProvider =
    Provider.autoDispose.family<EntreeCarte?, CleEntreeGroupe>(
      (Ref ref, CleEntreeGroupe cle) {
        final GroupSummaryVM? trouve = ref
            .watch(groupeProvider(cle.groupeId))
            .value;
        if (trouve == null) return null;
        // Tant que le flux n'a rien emis, l'horloge de la Classe lue fait foi.
        final AsyncValue<SessionClockVM> flux = ref.watch(
          horlogeGroupeProvider(cle.groupeId),
        );
        final SessionClockVM? tic = flux.value;
        final GroupSummaryVM groupe = tic == null
            ? trouve
            : trouve.avecHorloge(tic);
        final ({bool ferme, bool enLecture}) acces = rejoindreSelonAcces(
          ref.watch(accesAppelantProvider),
        );
        return EntreeCarte(
          groupe: groupe,
          emplacement: CarteSession.emplacementPour(
            espace: GroupHomeVM.pourRole(identite: groupe, role: cle.role),
            horsLigne: ref.watch(horsLigneProvider).value ?? false,
            annulee: ref.watch(seanceAnnuleeProvider(cle.groupeId)),
            lectureEchouee: flux.hasError && tic == null,
            seanceParServeur: cle.seanceParServeur,
            tutoiement: cle.tutoiement,
          ),
          retiree: acces.ferme,
          enLecture: acces.enLecture,
        );
      },
      // Les demonstrations et les tests surchargent ces lectures dans un
      // ProviderScope imbrique : l'entree suit leur portee (lecon de la 410).
      dependencies: <ProviderOrFamily>[
        groupeProvider,
        horlogeGroupeProvider,
        horsLigneProvider,
        seanceAnnuleeProvider,
        accesAppelantProvider,
      ],
    );
