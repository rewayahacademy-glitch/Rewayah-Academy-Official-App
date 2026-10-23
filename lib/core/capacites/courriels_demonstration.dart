// Les e-mails sortants en memoire : la demonstration et les tests
// (COURRIELS-1). Meme contrat que le serveur : memes bornes (sujet 1 a 120,
// texte 1 a 5000), meme adresse exigee, categorie active exigee, une meme cle
// rend la ligne deja creee, seuls un echec ou un annule se relancent. Un
// envoi manuel reste `en_attente` : c'est le serveur qui le fait partir, jamais
// l'ecran.
//
// Jamais branche en production : `lib/main.dart` y met `CourrielsSupabase`.

import 'port_courriels.dart';

/// Les e-mails sortants tenus en memoire.
class CourrielsDemonstration implements PortCourriels {
  /// Cree le port, avec des lignes et des categories de depart.
  CourrielsDemonstration({
    List<CourrielSortant> courriels = const <CourrielSortant>[],
    List<CategorieCourriel>? categories,
    DateTime Function()? maintenant,
  }) : file = List<CourrielSortant>.of(courriels),
       _categories = categories ?? categoriesDeDepart,
       _maintenant = maintenant ?? DateTime.now;

  /// Les categories du serveur au depart, avec leurs alias.
  static const List<CategorieCourriel> categoriesDeDepart = <CategorieCourriel>[
    CategorieCourriel(
      code: 'direction',
      libelle: 'Message de la direction',
      expediteurAdresse: 'contact@rewayahacademy.com',
      expediteurNom: 'Rewayah Academy',
      repondreA: 'contact@rewayahacademy.com',
      essentielle: true,
      active: true,
    ),
    CategorieCourriel(
      code: 'facturation',
      libelle: 'Facturation',
      expediteurAdresse: 'invoice@rewayahacademy.com',
      expediteurNom: 'Rewayah Academy · Facturation',
      repondreA: 'invoice@rewayahacademy.com',
      essentielle: true,
      active: true,
    ),
    CategorieCourriel(
      code: 'nouvelles',
      libelle: "Nouvelles de l'académie",
      expediteurAdresse: 'contact@rewayahacademy.com',
      expediteurNom: 'Rewayah Academy',
      repondreA: 'contact@rewayahacademy.com',
      essentielle: false,
      active: true,
    ),
  ];

  final DateTime Function() _maintenant;
  final List<CategorieCourriel> _categories;

  /// La file, la plus recente d'abord.
  final List<CourrielSortant> file;

  /// Les envois recus : (cle, categorie, adresse, sujet, corps).
  final List<(String, String, String?, String, String)> envois =
      <(String, String, String?, String, String)>[];

  /// Toutes les cles recues, meme pour un envoi refuse ou perdu.
  final List<String> clesVues = <String>[];

  /// Les cles deja vues et la ligne qu'elles ont creee.
  final Map<String, String> _parCle = <String, String>{};

  /// Une erreur a lever au prochain appel de chaque methode, puis oubliee.
  Object? erreurEnvoi;
  Object? erreurListe;
  Object? erreurRelance;
  Object? erreurCategories;

  /// Un envoi en attente de liberation, pour montrer l'etat « en cours ».
  Future<void>? retenueEnvoi;

  /// Les appels de chaque methode.
  int appelsEnvoi = 0;
  int lecturesFile = 0;
  int relances = 0;

  int _suite = 0;

  @override
  Future<String> envoyer({
    required String categorie,
    required String sujet,
    required String corps,
    required String cle,
    String? adresse,
    String? profil,
  }) async {
    appelsEnvoi++;
    clesVues.add(cle);
    final Future<void>? retenue = retenueEnvoi;
    if (retenue != null) await retenue;
    final Object? e = erreurEnvoi;
    erreurEnvoi = null;
    if (e != null) return Future<String>.error(e);
    final String a = (adresse ?? '').trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(a)) {
      throw const CourrielInvalide(ChampCourriel.adresse);
    }
    if (!_categories.any(
      (CategorieCourriel c) => c.code == categorie && c.active,
    )) {
      throw const CourrielInvalide(ChampCourriel.categorie);
    }
    final int s = sujet.trim().length;
    if (s < 1 || s > 120) throw const CourrielInvalide(ChampCourriel.sujet);
    final int c = corps.trim().length;
    if (c < 1 || c > 5000) throw const CourrielInvalide(ChampCourriel.corps);
    final String? deja = _parCle[cle];
    if (deja != null) return deja;
    final String id = 'c${++_suite}';
    _parCle[cle] = id;
    envois.add((cle, categorie, a, sujet.trim(), corps.trim()));
    file.insert(
      0,
      CourrielSortant(
        id: id,
        categorie: categorie,
        modele: 'message_libre',
        destinataire: a,
        origine: OrigineCourriel.manuel,
        statut: StatutCourriel.enAttente,
        tentatives: 0,
        creeLe: _maintenant(),
        sujet: sujet.trim(),
      ),
    );
    return id;
  }

  @override
  Future<List<CourrielSortant>> lister({
    StatutCourriel? statut,
    int limite = 100,
  }) {
    lecturesFile++;
    final Object? e = erreurListe;
    erreurListe = null;
    if (e != null) return Future<List<CourrielSortant>>.error(e);
    return Future<List<CourrielSortant>>.value(
      List<CourrielSortant>.unmodifiable(
        file
            .where((CourrielSortant x) => statut == null || x.statut == statut)
            .take(limite),
      ),
    );
  }

  @override
  Future<void> reessayer(String id) {
    relances++;
    final Object? e = erreurRelance;
    erreurRelance = null;
    if (e != null) return Future<void>.error(e);
    final int i = file.indexWhere((CourrielSortant x) => x.id == id);
    if (i < 0 || !file[i].statut.peutReessayer) {
      return Future<void>.error(const CourrielIntrouvable());
    }
    final CourrielSortant x = file[i];
    file[i] = CourrielSortant(
      id: x.id,
      categorie: x.categorie,
      modele: x.modele,
      destinataire: x.destinataire,
      origine: x.origine,
      statut: StatutCourriel.enAttente,
      tentatives: 0,
      creeLe: x.creeLe,
      sujet: x.sujet,
      langue: x.langue,
    );
    return Future<void>.value();
  }

  @override
  Future<List<CategorieCourriel>> categories() {
    final Object? e = erreurCategories;
    erreurCategories = null;
    if (e != null) return Future<List<CategorieCourriel>>.error(e);
    return Future<List<CategorieCourriel>>.value(
      List<CategorieCourriel>.unmodifiable(_categories),
    );
  }
}
