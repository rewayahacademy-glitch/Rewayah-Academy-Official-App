// Ce que la cloche affiche : notifications et annonces sur une seule liste
// (CLOCHE-C, decision du directeur du 21/11/2026, regles 2 a 5). Pur et
// teste : les ecrans ne trient ni ne comptent rien eux-memes.

import 'package:flutter/foundation.dart';

import '../../../core/capacites/port_notifications.dart';
import 'annonces_cloche.dart';

/// Les trois onglets de la cloche, du panneau, de la feuille et de la page.
enum OngletCloche {
  /// « Tout » : notifications et annonces non fermees.
  tout,

  /// « Annonces » : les annonces des 90 derniers jours, fermees comprises.
  annonces,

  /// « A faire » : ce qui attend un geste.
  aFaire,
}

/// Un element de la liste : une notification ou une annonce.
@immutable
sealed class ElementCloche {
  const ElementCloche();

  /// La cle stable de la ligne.
  String get cle;

  /// L'instant qui la classe.
  DateTime get date;

  /// Vrai si elle n'est pas encore lue (ou vue).
  bool get nonLu;

  /// Vrai si elle passe en tete : une urgence qui attend un geste.
  bool get urgente => false;
}

/// Une notification de la personne.
final class ElementNotification extends ElementCloche {
  /// Cree l'element.
  const ElementNotification(this.notification);

  /// La notification.
  final NotificationTuteur notification;

  @override
  String get cle => 'n-${notification.id}';

  @override
  DateTime get date => notification.date;

  @override
  bool get nonLu => !notification.lue;

  @override
  bool get urgente =>
      notification.aFaire && notification.niveau == NiveauAttention.urgent;
}

/// Une annonce de l'academie.
final class ElementAnnonce extends ElementCloche {
  /// Cree l'element.
  const ElementAnnonce(this.annonce);

  /// L'annonce.
  final AnnonceCloche annonce;

  @override
  String get cle => 'a-${annonce.id}';

  @override
  DateTime get date => annonce.publieeLe;

  @override
  bool get nonLu => !annonce.vue;
}

/// Les elements d'un onglet, dans l'ordre d'affichage : les urgences qui
/// attendent un geste en tete (`lib/CLAUDE.md`), puis du plus recent au plus
/// ancien.
///
/// [fermeturesLocales] : les fermetures faites sur cet appareil et pas encore
/// relues du serveur (id vers fermee). [enAnnulation] : les annonces dont la
/// ligne montre encore « Annuler » ; elles restent a leur place dans « Tout ».
List<ElementCloche> elementsOnglet(
  OngletCloche onglet, {
  required List<NotificationTuteur> notifications,
  required List<AnnonceCloche> annoncesOuvertes,
  required List<AnnonceCloche> annoncesToutes,
  Map<String, bool> fermeturesLocales = const <String, bool>{},
  Set<String> enAnnulation = const <String>{},
}) {
  bool fermee(AnnonceCloche a) => fermeturesLocales[a.id] ?? a.fermee;
  AnnonceCloche etat(AnnonceCloche a) => a.avecFermee(fermee(a));
  final List<ElementCloche> elements = switch (onglet) {
    OngletCloche.tout => <ElementCloche>[
      for (final NotificationTuteur n in notifications) ElementNotification(n),
      for (final AnnonceCloche a in annoncesOuvertes)
        if (!fermee(a) || enAnnulation.contains(a.id)) ElementAnnonce(etat(a)),
    ],
    OngletCloche.annonces => <ElementCloche>[
      for (final AnnonceCloche a in annoncesToutes) ElementAnnonce(etat(a)),
    ],
    OngletCloche.aFaire => <ElementCloche>[
      for (final NotificationTuteur n in notifications)
        if (n.aFaire) ElementNotification(n),
    ],
  };
  elements.sort((ElementCloche a, ElementCloche b) {
    if (a.urgente != b.urgente) return a.urgente ? -1 : 1;
    return b.date.compareTo(a.date);
  });
  return elements;
}

/// Le nombre d'un onglet, montre a cote de son nom : les non lues (« Tout »,
/// « Annonces ») ou ce qui attend un geste (« A faire »). Zero : aucun nombre.
int nombreOnglet(
  OngletCloche onglet, {
  required List<NotificationTuteur> notifications,
  required List<AnnonceCloche> annoncesOuvertes,
  Map<String, bool> fermeturesLocales = const <String, bool>{},
}) {
  bool ouverte(AnnonceCloche a) => !(fermeturesLocales[a.id] ?? a.fermee);
  final int annoncesNonVues = annoncesOuvertes
      .where((AnnonceCloche a) => ouverte(a) && !a.vue)
      .length;
  return switch (onglet) {
    OngletCloche.tout =>
      notifications.where((NotificationTuteur n) => !n.lue).length +
          annoncesNonVues,
    OngletCloche.annonces => annoncesNonVues,
    OngletCloche.aFaire =>
      notifications.where((NotificationTuteur n) => n.aFaire).length,
  };
}
