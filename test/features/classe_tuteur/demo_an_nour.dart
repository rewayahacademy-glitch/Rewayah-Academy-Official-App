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
import 'package:rewayah_academy/core/i18n/strings.g.dart';
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
/// les Messages), dans l'alphabet de la langue courante.
String get prenomAdam =>
    LocaleSettings.currentLocale == AppLocale.ar ? 'آدم' : 'Adam';

/// Le prenom de l'enseignante de la Classe An-Nour (« Sayyida Mariam »),
/// celle de la demonstration des Communications.
String get prenomMariam => ClassesDemoAnnonces.enseignanteNour.nomAffichage;

/// Ce que le serveur rendrait dans la langue du foyer : les dates des trois
/// prochaines seances (dimanches 4, 11 et 18 octobre), la ville, le cours et
/// le niveau. En arabe, aucun mot francais dans la carte.
({List<String> dates, String ville, String cours, String niveau})
_rendusServeur() => LocaleSettings.currentLocale == AppLocale.ar
    ? (
        dates: const <String>[
          'الأحد 4 أكتوبر',
          'الأحد 11 أكتوبر',
          'الأحد 18 أكتوبر',
        ],
        ville: 'باريس',
        cours: 'القرآن',
        niveau: 'المستوى 1',
      )
    : (
        dates: const <String>[
          'Dimanche 4 octobre',
          'Dimanche 11 octobre',
          'Dimanche 18 octobre',
        ],
        ville: 'Paris',
        cours: 'Coran',
        niveau: 'Niveau 1',
      );

/// Le nom de la Classe An-Nour dans la langue courante, celui que porte
/// l'annonce de demonstration.
String libelleAnNour() =>
    ClassesDemoAnnonces.libelle(ClassesDemoAnnonces.nour)!;

/// La Classe du tuteur sur le jeu An-Nour, a l'instant serveur [maintenant] :
/// une seance dans 10 min (salle ouverte), qui passe avant les annonces
/// (R-16).
List<Override> surchargesClasseAnNour(DateTime maintenant) {
  final ({List<String> dates, String ville, String cours, String niveau})
  rendus = _rendusServeur();
  return surchargesClasse(
    maintenantServeur: maintenant,
    eleves: <EleveDuFoyer>[
      EleveDuFoyer(
        id: eleveA1,
        prenom: prenomAdam,
        identifiantImmuable: 'DEMO-AD1',
        mode: InterfaceMode.standard,
        camera: CameraPolicy.forbidden,
      ),
    ],
    // La seance du jour, salle ouverte, puis les deux suivantes (planning
    // de la Classe : une par semaine, le dimanche a 14:10).
    seances: <SeanceFamille>[
      for (int semaine = 0; semaine < rendus.dates.length; semaine++)
        seanceFictive(
          seanceId: 'an-nour-${semaine + 1}',
          eleveId: eleveA1,
          debutUtc: maintenant.add(Duration(minutes: 10, days: 7 * semaine)),
          prenomEnseignant: prenomMariam,
          heureFoyer: heureRendue(
            'Europe/Paris',
            rendus.ville,
            '14:10',
            date: rendus.dates[semaine],
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
            enseignant: ClassesDemoAnnonces.enseignanteNour,
            nombreMembres: 5,
            seuilMax: 8,
            typePublic: TypePublicGroupeVM.enfant,
            actif: true,
            nomCours: rendus.cours,
            niveauHumain: rendus.niveau,
          ),
        ),
      ],
    ),
  );
}

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
