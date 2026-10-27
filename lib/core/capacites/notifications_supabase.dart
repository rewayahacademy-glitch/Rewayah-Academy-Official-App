import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_delais.dart';
import 'port_notifications.dart';

/// Texte prêt à afficher, produit à partir des seules données métier autorisées.
class NotificationContenu {
  /// Crée le contenu d'une notification.
  const NotificationContenu({required this.titre, this.texte});

  /// Titre localisé.
  final String titre;

  /// Détail localisé ; nul lorsque le titre suffit.
  final String? texte;
}

/// Résout un contenu localisé. Les paramètres reçus sont filtrés et ne
/// contiennent aucun identifiant de profil, foyer, demande ou groupe.
typedef NotificationContenuResolver = NotificationContenu Function(
  String evenement,
  Map<String, dynamic> params,
);

/// Les événements que le serveur écrit (contrainte `notifications_evenement_check`,
/// migration 20261027120000). Un événement hors de cette liste n'est **pas**
/// perdu : le résolveur lui donne un titre de repli lisible (fiche du 27/10,
/// ligne 13 : aucun événement inconnu ne fait planter la page).
const Set<String> evenementsNotificationConnus = <String>{
  'demande_recue',
  'classe_validee',
  'enseignant_affecte',
  'demande_close',
  'remplacement_propose',
  'remplacement_pris',
  'demande_presentation',
  'controle_mission_attribuee',
  'controle_mission_non_controlee',
  // Fusion ou transfert de l'eleve vers une classe parallele (R9, R10).
  'classe_changee',
  // Relance avant echeance, acces suspendu pour paiement, acces retabli
  // (FAC-F-01, migration 20261018170000).
  'paiement_relance',
  'acces_suspendu_paiement',
  'acces_retabli_paiement',
  // Fiche « Fraicheur et notifications » du 27/10/2026, ligne 11.
  'classe_creee',
  'enseignant_change',
  'eleve_inscrit',
  'eleve_retire',
  'creneau_change',
  'seance_annulee',
  'seance_deplacee',
  'enseignante_absente',
  'classe_supprimee',
};

const Set<String> _destinationsAutorisees = <String>{
  '/tuteur/demandes',
  '/enseignant/journee/remplacements',
  '/controleur',
  '/admin/securite-audit/tirages',
  // La recharge du foyer : le bouton Payer des relances (FAC-F-01).
  '/tuteur/foyer/recharge',
  // Fiche du 27/10 : les accueils et les classes de chaque role.
  '/eleve',
  '/tuteur',
  '/enseignant/classes',
  '/enseignant/journee',
};

/// La classe d'un eleve du foyer, et son planning : `/tuteur/classes/<uuid>`
/// ou `/tuteur/classes/<uuid>/planning` (la meme forme que la contrainte SQL).
final RegExp _destinationClasse = RegExp(
  r'^/tuteur/classes/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}(/planning)?$',
);

/// Vrai si [destination] est un ecran que l'ouverture d'une notification peut
/// atteindre. Pure.
bool destinationNotificationAutorisee(String? destination) =>
    destination != null &&
    (_destinationsAutorisees.contains(destination) ||
        _destinationClasse.hasMatch(destination));

/// Adaptateur Supabase de la boîte privée de notifications.
class NotificationsSupabase
    implements
        PortNotifications,
        PortLectureNotifications,
        PortLectureGroupeeNotifications {
  /// Crée l'adaptateur avec le client de l'application et le résolveur localisé.
  const NotificationsSupabase(this._client, {required this.contenuPour});

  final SupabaseClient _client;
  final NotificationContenuResolver contenuPour;

  String get _destinataire {
    final String? id = _client.auth.currentUser?.id;
    if (id == null || id.isEmpty) {
      throw StateError('Session requise pour lire les notifications.');
    }
    return id;
  }

  @override
  Future<List<NotificationTuteur>> liste() async {
    final String destinataire = _destinataire;
    final dynamic rows = await _client
        .from('notifications')
        .select('id, evenement, params, destination, cree_le, lu_le')
        .eq('destinataire', destinataire)
        .order('cree_le', ascending: false)
        .timeout(AppDelais.requeteMax);

    if (rows is! List) {
      throw const FormatException('Réponse notifications invalide.');
    }
    return notificationsDepuis(rows, titrePour: contenuPour);
  }

  @override
  Future<NotificationTuteur?> detail(String id) async {
    final String identifiant = id.trim();
    if (identifiant.isEmpty) return null;

    final String destinataire = _destinataire;
    final dynamic row = await _client
        .from('notifications')
        .select('id, evenement, params, destination, cree_le, lu_le')
        .eq('destinataire', destinataire)
        .eq('id', identifiant)
        .maybeSingle()
        .timeout(AppDelais.requeteMax);
    if (row == null) return null;
    if (row is! Map) {
      throw const FormatException('Réponse notification invalide.');
    }
    try {
      return notificationDepuis(
        Map<String, dynamic>.from(row),
        titrePour: contenuPour,
      );
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> marquerLue(String id) async {
    final String identifiant = id.trim();
    if (identifiant.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Identifiant requis.');
    }
    final String destinataire = _destinataire;
    await _client
        .from('notifications')
        .update(<String, dynamic>{
          'lu_le': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', identifiant)
        .eq('destinataire', destinataire)
        .timeout(AppDelais.requeteMax);
  }

  /// Toutes les non-lues de la personne en une requête (politique
  /// `notifications_destinataire_accuse` de 0063 : UPDATE de `lu_le` par le
  /// destinataire seulement). Realtime transmet la mise à jour aux autres
  /// appareils de la personne, qui relisent la liste (ligne 14).
  @override
  Future<void> marquerToutesLues() async {
    final String destinataire = _destinataire;
    await _client
        .from('notifications')
        .update(<String, dynamic>{
          'lu_le': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('destinataire', destinataire)
        .isFilter('lu_le', null)
        .timeout(AppDelais.requeteMax);
  }
}

/// Décode les lignes indépendamment : une ligne mal formée ne rend pas
/// illisible toute la boîte du destinataire. Un événement inconnu est gardé,
/// avec le titre de repli du résolveur (ligne 13).
List<NotificationTuteur> notificationsDepuis(
  List<dynamic> rows, {
  required NotificationContenuResolver titrePour,
}) {
  final List<NotificationTuteur> notifications = <NotificationTuteur>[];
  for (final dynamic row in rows) {
    if (row is! Map || row['evenement'] is! String) continue;
    try {
      notifications.add(
        notificationDepuis(
          Map<String, dynamic>.from(row),
          titrePour: titrePour,
        ),
      );
    } on FormatException {
      continue;
    }
  }
  return List<NotificationTuteur>.unmodifiable(notifications);
}

/// Décode et réduit une ligne SQL sans laisser les paramètres serveur devenir
/// des liens, des noms d'acteurs ou des identifiants exposés à l'écran.
NotificationTuteur notificationDepuis(
  Map<String, dynamic> row, {
  required NotificationContenuResolver titrePour,
}) {
  final dynamic rawId = row['id'];
  final dynamic rawEvent = row['evenement'];
  final dynamic rawParams = row['params'];
  final dynamic rawCreated = row['cree_le'];
  final dynamic rawRead = row['lu_le'];
  final String? destination = row['destination'] is String
      ? row['destination'] as String
      : null;

  final String id = rawId is String ? rawId.trim() : '';
  final String? evenement = rawEvent is String ? rawEvent.trim() : null;
  final DateTime? date = DateTime.tryParse(rawCreated?.toString() ?? '');
  final DateTime? luLe = rawRead == null
      ? null
      : DateTime.tryParse(rawRead.toString());

  if (id.isEmpty ||
      evenement == null ||
      evenement.isEmpty ||
      rawParams is! Map ||
      date == null ||
      (rawRead != null && luLe == null)) {
    throw const FormatException('Notification Supabase invalide.');
  }

  final Map<String, dynamic> params = _parametresAffichables(rawParams);
  final NotificationContenu contenu = titrePour(evenement, params);
  final String titre = contenu.titre.trim();
  if (titre.isEmpty) {
    throw const FormatException('Libellé de notification absent.');
  }
  final String? texte = contenu.texte?.trim();
  final bool lue = luLe != null;

  return NotificationTuteur(
    id: id,
    titre: titre,
    texte: texte == null || texte.isEmpty ? null : texte,
    date: date.toUtc(),
    destination: destinationNotificationAutorisee(destination)
        ? destination
        : null,
    niveau: lue ? NiveauAttention.information : NiveauAttention.aLire,
    lue: lue,
    type: _typePour(evenement),
  );
}

Map<String, dynamic> _parametresAffichables(Map<dynamic, dynamic> bruts) {
  // `portee` (soi, foyer, classe) dit a qui le fait arrive, pour choisir la
  // phrase ; `debut_local` est l'heure de la seance dans le fuseau de la
  // personne. Jamais un identifiant.
  const Set<String> clesAutorisees = <String>{
    'etat',
    'debut_local',
    'motif',
    'portee',
  };
  final Map<String, dynamic> valeurs = <String, dynamic>{};
  for (final MapEntry<dynamic, dynamic> entree in bruts.entries) {
    if (entree.key is String &&
        clesAutorisees.contains(entree.key) &&
        entree.value is String) {
      final String valeur = (entree.value as String).trim();
      if (valeur.isNotEmpty) valeurs[entree.key as String] = valeur;
    }
  }
  return Map<String, dynamic>.unmodifiable(valeurs);
}

TypeNotification _typePour(String evenement) => switch (evenement) {
  'demande_recue' => TypeNotification.messageMetier,
  'classe_validee' ||
  'enseignant_affecte' ||
  'classe_changee' ||
  'classe_creee' ||
  'enseignant_change' ||
  'eleve_inscrit' ||
  'eleve_retire' ||
  'creneau_change' ||
  'classe_supprimee' => TypeNotification.changementPlanning,
  'seance_annulee' ||
  'seance_deplacee' ||
  'enseignante_absente' => TypeNotification.changementSeance,
  'demande_close' => TypeNotification.decisionDossier,
  'remplacement_propose' ||
  'remplacement_pris' => TypeNotification.remplacement,
  'demande_presentation' => TypeNotification.messageMetier,
  'controle_mission_attribuee' => TypeNotification.mission,
  'controle_mission_non_controlee' => TypeNotification.evenementOperationnel,
  'paiement_relance' ||
  'acces_suspendu_paiement' ||
  'acces_retabli_paiement' => TypeNotification.accesFinance,
  _ => TypeNotification.autre,
};
