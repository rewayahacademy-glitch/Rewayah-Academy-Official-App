// Le jeu de demonstration de la Classe du tuteur, coherent avec la
// demonstration des Communications (COM-RC tour 7, lot L) : la Classe
// An-Nour de Sayyida Mariam, l'eleve Adam, une seance dont la salle est
// ouverte. La page, la carte de seance, le planning et l'annonce de la
// Classe disent la meme Classe ; aucun « Classe fictive A » ni « Eleve A1 »
// a cote d'une annonce de la Classe An-Nour (COM-CAPT tour 6, defaut 5).
//
// Donnees fictives uniquement : aucune n'est servie par un provider de
// `lib/` (la demonstration de production a ses propres doubles).

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/communications/capacites_communication.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/seance_famille/seance_famille.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/features/com_annonces/port_annonces.dart';
import 'package:rewayah_academy/features/demo/communications/com_annonces_demo.dart';
import 'package:rewayah_academy/features/demo/communications/demo_communications_page.dart'
    show RoleDemoCommunications;

import '../../fixtures/tuteur/faux_classes_foyer.dart';
import '../../fixtures/tuteur/faux_seances_famille.dart';
import 'support_classe.dart';

/// Le prenom de l'eleve de la demonstration (« Classe An-Nour · Adam » dans
/// les Messages).
const String prenomAdam = 'Adam';

/// Le prenom de l'enseignante de la Classe An-Nour (« Mme Mariam »).
const String prenomMariam = 'Mariam';

/// Le nom de la Classe An-Nour dans la langue courante, celui que porte
/// l'annonce de demonstration.
String libelleAnNour() =>
    ClassesDemoAnnonces.libelle(ClassesDemoAnnonces.nour)!;

/// La Classe du tuteur sur le jeu An-Nour, a l'instant serveur [maintenant] :
/// une seance dans 10 min (salle ouverte), qui passe avant les annonces
/// (R-16).
List<Override> surchargesClasseAnNour(DateTime maintenant) => surchargesClasse(
  maintenantServeur: maintenant,
  eleves: const <EleveDuFoyer>[
    EleveDuFoyer(
      id: eleveA1,
      prenom: prenomAdam,
      identifiantImmuable: 'DEMO-AD1',
      mode: InterfaceMode.standard,
      camera: CameraPolicy.forbidden,
    ),
  ],
  seances: <SeanceFamille>[
    seanceFictive(
      eleveId: eleveA1,
      debutUtc: maintenant.add(const Duration(minutes: 10)),
      prenomEnseignant: prenomMariam,
      heureFoyer: heureRendue(
        'Europe/Paris',
        'Paris',
        '14:10',
        date: 'Dimanche 4 octobre',
      ),
    ),
  ],
  portClasses: FauxClassesFoyer(
    classes: <ClasseFoyer>[
      ClasseFoyer(
        eleveId: eleveA1,
        classe: GroupSummaryVM(
          groupeId: classeA,
          libelle: libelleAnNour(),
          couleurJeton: const JetonCouleurGroupe(index: 0, codeStable: 'g0'),
          enseignant: const EnseignantVM(
            enseignantId: 'demo-enseignante',
            titre: TitreEnseignant.sayyida,
            nomAffichage: prenomMariam,
          ),
          nombreMembres: 5,
          seuilMax: 8,
          typePublic: TypePublicGroupeVM.enfant,
          actif: true,
          nomCours: 'Coran',
          niveauHumain: 'Niveau 1',
        ),
      ),
    ],
  ),
);

/// Les annonces de demonstration du tuteur, celles de la Classe An-Nour
/// rangees aussi sous la Classe montee ([classeA]).
List<Override> annoncesClasseAnNour(DateTime maintenant) {
  final Map<String, List<AnnonceClasse>> parClasse = annoncesDemo(
    RoleDemoCommunications.tuteur,
    maintenant,
  );
  return surchargesAdministrationDemo(
    annonces: AnnoncesDemonstration(<String, List<AnnonceClasse>>{
      ...parClasse,
      classeA: parClasse[ClassesDemoAnnonces.nour] ?? <AnnonceClasse>[],
    }, maintenant: () => maintenant),
    moderation: ModerationAdministrationDemo(maintenant: maintenant),
    capacites: const <CapaciteCommunication>{},
  );
}
