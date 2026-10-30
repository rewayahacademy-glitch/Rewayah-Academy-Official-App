/// La duree d'un creneau de classe (decision du directeur relayee par le
/// pilote, 30/10/2026 : « jour + heure + duree »), commune a la creation
/// d'une classe (`groupes_page.dart`) et a la modification d'un creneau
/// (`feuille_reglages_classe.dart`).
///
/// Par defaut, un creneau dure le temps de la classe (son offre, sinon le
/// reglage de son public), lu par le serveur : l'ecran ne le devine pas et
/// l'envoie nul. Une autre duree vaut pour ce creneau seulement ; le serveur
/// la borne de 15 a 240 minutes et en tient compte dans le controle des
/// chevauchements de l'enseignant.
library;

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/widgets/menu_filtre.dart';

/// La valeur du menu qui garde la duree de la classe (envoyee nulle).
const int dureeDeLaClasse = 0;

/// Les durees proposees, en minutes, apres la duree de la classe.
const List<int> dureesCreneau = <int>[30, 45, 60, 75, 90, 120];

/// La duree d'un creneau en mots : « 45 min », ou « Duree de la classe »
/// quand elle est nulle.
String libelleDureeCreneau(int? minutes) =>
    minutes == null || minutes == dureeDeLaClasse
    ? t.admin.groupes.formulaire.dureeClasse
    : LibellesGroupe.insecable(
        t.admin.groupes.formulaire.dureeValeur(minutes: '$minutes'),
      );

/// Le menu de la duree d'un creneau. [duree] nulle : la duree de la classe ;
/// [onChoix] rend nulle cette meme valeur.
class MenuDureeCreneau extends StatelessWidget {
  /// Cree le menu.
  const MenuDureeCreneau({
    required this.duree,
    required this.onChoix,
    super.key,
  });

  /// La duree retenue, en minutes ; nulle pour la duree de la classe.
  final int? duree;

  /// La duree choisie, nulle pour la duree de la classe.
  final ValueChanged<int?> onChoix;

  @override
  Widget build(BuildContext context) => MenuFiltre<int>(
    libelle: t.admin.groupes.formulaire.duree,
    valeur: duree ?? dureeDeLaClasse,
    entrees: <EntreeFiltre<int>>[
      for (final int m in <int>[dureeDeLaClasse, ...dureesCreneau])
        EntreeFiltre<int>(valeur: m, libelle: libelleDureeCreneau(m)),
    ],
    onChoix: (int? m) {
      if (m != null) onChoix(m == dureeDeLaClasse ? null : m);
    },
  );
}
