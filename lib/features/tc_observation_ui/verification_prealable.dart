import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../../core/foyer/selection_eleve.dart';
import '../../core/observabilite/journal_dev.dart';
import '../../core/preferences/preferences_locales.dart';
import '../../core/presence/service_presence.dart';
import '../../core/tc_observation/disponibilite_observation.dart';
import '../../core/tc_observation/echec_observation.dart';
import '../../core/tc_observation/guardian_observation_policy.dart';
import '../../core/tc_observation/port_politique_observation.dart';

/// Ce que la verification prealable doit lire : une seance, pour un
/// observateur, et, quand l'entree les connait, la classe et l'eleve.
///
/// **Des identifiants, jamais une autorisation** : la RLS et les fonctions
/// serveur decident de ce qui se lit (mandat section 4, « un identifiant de
/// route ne vaut jamais une autorisation »).
@immutable
class DemandeVerification {
  /// Cree la demande.
  const DemandeVerification({
    required this.seanceId,
    required this.observateurId,
    this.classeId,
    this.eleveId,
  });

  /// La seance a observer.
  final String seanceId;

  /// Le compte qui observe : la memoire « explication deja vue » est la
  /// sienne, pas celle de l'appareil entier.
  final String observateurId;

  /// La classe (le groupe) de la seance, quand l'entree la donne : elle
  /// permet de lire la politique effective, et donc la duree par visite.
  final String? classeId;

  /// L'eleve dont on vient voir la seance, quand l'entree le donne.
  final String? eleveId;

  @override
  bool operator ==(Object other) =>
      other is DemandeVerification &&
      other.seanceId == seanceId &&
      other.observateurId == observateurId &&
      other.classeId == classeId &&
      other.eleveId == eleveId;

  @override
  int get hashCode => Object.hash(seanceId, observateurId, classeId, eleveId);
}

/// Le resultat de la verification prealable : ce qui est possible, et de quoi
/// l'expliquer.
///
/// **Lecture seule.** Rien ici n'ouvre de visite : `budget_observation()` ne
/// cree aucun intervalle (`C07` section 11), la presence et la politique se
/// lisent, la memoire d'explication se lit. Le compteur ne peut donc pas
/// demarrer pendant cette verification ni pendant la lecture de l'explication
/// (complement observation section 5).
@immutable
class VerificationPrealable {
  /// Cree le resultat.
  const VerificationPrealable({
    required this.disponibilite,
    required this.explicationVue,
    this.visitesMax,
    this.visitesUtilisees,
    this.dureeParVisite,
  });

  /// Ce que la famille peut faire maintenant (contrat K4).
  final DisponibiliteObservation disponibilite;

  /// Vrai quand ce compte a deja lu l'explication sur cet appareil.
  final bool explicationVue;

  /// Visites autorisees par seance, selon le serveur. `null` : non lu.
  final int? visitesMax;

  /// Visites deja consommees sur cette seance, selon le serveur.
  final int? visitesUtilisees;

  /// Duree d'une visite : le plafond par visite de la politique effective
  /// quand la classe est connue, sinon la duree de la prochaine visite rendue
  /// par le budget. Jamais une constante.
  final Duration? dureeParVisite;

  /// Vrai quand la regle (nombre et duree des visites) est connue et
  /// affichable : sans elle, l'explication ne dit pas de chiffres inventes.
  bool get regleConnue =>
      (visitesMax ?? 0) > 0 &&
      (dureeParVisite ?? Duration.zero) > Duration.zero;

  /// Visites restantes, jamais negatives.
  int get visitesRestantes {
    final int reste = (visitesMax ?? 0) - (visitesUtilisees ?? 0);
    return reste < 0 ? 0 : reste;
  }
}

/// La cle de la memoire « explication deja vue », par compte.
///
/// Un stockage local par appareil, documente comme tel (relevé V7 section 7
/// point 9) : ce n'est pas un secret, et aucun service ne le garde par compte.
/// Sur le web, la memoire ne dure que la session (`StockagePreferencesMemoire`).
String clefExplicationVue(String observateurId) =>
    'observation.explicationVue.$observateurId';

/// Retient que ce compte a lu l'explication. Une panne du stockage ne casse
/// rien : l'explication sera simplement proposee de nouveau.
Future<void> marquerExplicationVue(
  StockagePreferences stockage,
  String observateurId,
) async {
  try {
    await stockage.ecrire(clefExplicationVue(observateurId), 'oui');
  } on Object catch (erreur) {
    journalDev('Memoire d\'explication non ecrite : $erreur');
  }
}

/// La presence de l'enfant concerne, parmi les lignes lues.
///
/// [eleveId] connu : sa ligne seule. Inconnu : les eleves du foyer
/// ([idsDuFoyer]), et la premiere presence confirmee l'emporte. `null` quand
/// rien n'est lisible : c'est « en verification », **jamais « absent »**
/// (invariant J3 de `service_presence.dart`).
@visibleForTesting
EtatPresence? presenceDeLEnfant({
  required List<PresenceParticipant>? lignes,
  required String? eleveId,
  required Set<String> idsDuFoyer,
}) {
  if (lignes == null) {
    return null;
  }
  EtatPresence? premiere;
  for (final PresenceParticipant ligne in lignes) {
    final bool concerne = eleveId != null
        ? ligne.profilId == eleveId
        : idsDuFoyer.contains(ligne.profilId);
    if (!concerne) {
      continue;
    }
    if (_confirmee(ligne.etat)) {
      return ligne.etat;
    }
    premiere ??= ligne.etat;
  }
  return premiere;
}

bool _confirmee(EtatPresence etat) => switch (etat) {
  EtatPresence.presente ||
  EtatPresence.enRetard ||
  EtatPresence.reconnectee => true,
  _ => false,
};

/// La verification prealable d'une observation.
///
/// Trois lectures, aucune ecriture : le budget du serveur (verite sur les
/// visites et le motif de refus), la politique effective quand la classe est
/// connue, la presence de l'enfant (indicative). Le tout passe par
/// `disponibiliteObservation` (contrat K4), seule regle de decision.
///
/// Un echec de lecture du budget n'est pas une exception : il devient un motif
/// d'indisponibilite (`reseau` se reessaye, les autres non).
final FutureProviderFamily<VerificationPrealable, DemandeVerification>
verificationPrealableProvider =
    FutureProvider.family<VerificationPrealable, DemandeVerification>((
      Ref ref,
      DemandeVerification demande,
    ) async {
      final PortPolitiqueObservation port = ref.watch(
        portPolitiqueObservationProvider,
      );
      final ServicePresence presence = ref.watch(servicePresenceProvider);
      final StockagePreferences stockage = ref.watch(
        stockagePreferencesProvider,
      );
      // Lu avant toute attente : un `ref.watch` pose apres un `await` suivrait
      // un provider que ce calcul a peut-etre deja quitte.
      // L'echec est attrape ici meme, et non a l'attente : un futur en echec
      // sans ecouteur au moment ou il se termine serait une erreur non geree.
      final Future<Set<String>> foyer = demande.eleveId == null
          ? ref
                .watch(profilsElevesFoyerProvider.future)
                .then(
                  (List<ProfilEleveFoyer> profils) => <String>{
                    for (final ProfilEleveFoyer p in profils) p.eleveId,
                  },
                  onError: (Object _) => const <String>{},
                )
          : Future<Set<String>>.value(const <String>{});

      Future<GuardianObservationPolicy?> lirePolitique() async {
        final String? classe = demande.classeId;
        if (classe == null) {
          return null;
        }
        try {
          return await port.politiqueEffective(groupeId: classe);
        } on EchecObservation {
          // La politique precise la duree par visite ; le budget suffit a
          // decider. Son absence ne ferme rien.
          return null;
        }
      }

      Future<bool> lireExplicationVue() async {
        try {
          return await stockage.lire(
                clefExplicationVue(demande.observateurId),
              ) !=
              null;
        } on Object {
          return false;
        }
      }

      final BudgetObservation budget;
      try {
        budget = await port.budget(sessionId: demande.seanceId);
      } on EchecObservation catch (echec) {
        return VerificationPrealable(
          disponibilite: ObservationIndisponible(motifDepuisEchec(echec)),
          explicationVue: await lireExplicationVue(),
        );
      }

      final (
        GuardianObservationPolicy? politique,
        List<PresenceParticipant>? lignes,
        Set<String> idsDuFoyer,
        bool vue,
      ) = await (
        lirePolitique(),
        presence.presence(demande.seanceId),
        foyer,
        lireExplicationVue(),
      ).wait;

      return VerificationPrealable(
        disponibilite: disponibiliteObservation(
          budget: budget,
          politique: politique,
          presenceEnfant: presenceDeLEnfant(
            lignes: lignes,
            eleveId: demande.eleveId,
            idsDuFoyer: idsDuFoyer,
          ),
          // Cette verification n'est lancee que si l'interrupteur P3 est
          // ouvert : l'ecran ne l'appelle pas autrement (aucun appel serveur
          // quand l'observation reelle est fermee).
          activationReelle: true,
        ),
        explicationVue: vue,
        visitesMax: budget.visitesMax,
        visitesUtilisees: budget.visitesUtilisees,
        dureeParVisite: politique?.maxParVisite ?? budget.restant,
      );
    }, isAutoDispose: true);
