import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../../core/capacites/port_classes_foyer.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/tc_groupe/group_summary_vm.dart';

/// L'en-tete de la salle, lu depuis la classe du foyer (contrat K6) : le nom
/// de la classe et l'enseignant avec Sayyid ou Sayyida (maquettes M3, M4, D1 :
/// « Classe An-Nour », « Mariam · Sayyida Amina »).
@immutable
class ContexteSalleObservation {
  /// Cree le contexte.
  const ContexteSalleObservation({
    required this.nomClasse,
    required this.enseignant,
  });

  /// Le nom familier de la classe. **Jamais un code.**
  final String nomClasse;

  /// « Sayyida Amina ».
  final String enseignant;
}

/// La cle de lecture : la classe et l'eleve transmis par l'entree.
typedef CleContexteSalle = ({String classeId, String eleveId});

/// « Sayyid Karim », « Sayyida Amina » : le titre et le nom d'affichage.
String enseignantAvecTitre(EnseignantVM enseignant) =>
    switch (enseignant.titre) {
      TitreEnseignant.sayyid =>
        '${t.tc.classe.entete.titreEnseignant.sayyid} '
            '${enseignant.nomAffichage}',
      TitreEnseignant.sayyida =>
        '${t.tc.classe.entete.titreEnseignant.sayyida} '
            '${enseignant.nomAffichage}',
    };

/// Le contexte de la salle, quand la classe du foyer se lit.
///
/// **`null` n'est pas une erreur** : sans source branchee (DB-TRV-07, adaptateur
/// du lot C), ou pour une classe que l'eleve a quittee, la salle garde son
/// titre generique « Observation en cours » et les noms que la salle video
/// porte. Un en-tete ne ferme jamais une visite deja ouverte.
final FutureProviderFamily<ContexteSalleObservation?, CleContexteSalle>
contexteSalleObservationProvider =
    FutureProvider.family<ContexteSalleObservation?, CleContexteSalle>((
      Ref ref,
      CleContexteSalle cle,
    ) async {
      final PortClassesFoyer port = ref.watch(portClassesFoyerProvider);
      try {
        final ClasseFoyer? classe = await port.classe(
          groupeId: cle.classeId,
          eleveId: cle.eleveId,
        );
        if (classe == null) {
          return null;
        }
        return ContexteSalleObservation(
          nomClasse: classe.classe.libelle,
          enseignant: enseignantAvecTitre(classe.classe.enseignant),
        );
      } on Object catch (erreur) {
        debugPrint('Contexte de la salle d\'observation illisible : $erreur');
        return null;
      }
    }, isAutoDispose: true);
