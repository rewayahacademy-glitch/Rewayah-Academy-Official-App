// La langue de communication en memoire : la demonstration et les tests
// (COURRIELS-2). Meme contrat que le serveur : un code inconnu est refuse, la
// langue reglee se relit, `null` veut dire francais.
//
// Jamais branche en production : `lib/main.dart` y met
// `LanguesCommunicationSupabase`.

import 'port_langues_communication.dart';

/// La langue de communication tenue en memoire.
class LanguesCommunicationDemonstration implements PortLanguesCommunication {
  /// Cree le port, avec les langues du serveur au depart.
  LanguesCommunicationDemonstration({
    List<LangueCommunication>? langues,
    this.langue,
  }) : _langues = langues ?? languesDeDepart;

  /// Les langues du serveur au depart.
  static const List<LangueCommunication> languesDeDepart =
      <LangueCommunication>[
        LangueCommunication(code: 'fr', libelle: 'Français'),
        LangueCommunication(code: 'en', libelle: 'English'),
        LangueCommunication(
          code: 'ar',
          libelle: 'العربية',
          droiteAGauche: true,
        ),
        LangueCommunication(code: 'es', libelle: 'Español'),
        LangueCommunication(code: 'pt', libelle: 'Português'),
        LangueCommunication(code: 'ff', libelle: 'Pulaar'),
      ];

  final List<LangueCommunication> _langues;

  /// La langue reglee (`null` : francais).
  String? langue;

  /// Une erreur a lever au prochain appel de chaque methode, puis oubliee.
  Object? erreurListe;
  Object? erreurLecture;
  Object? erreurReglage;

  /// Les codes recus par `regler`, meme refuses.
  final List<String> reglages = <String>[];

  @override
  Future<List<LangueCommunication>> lister() {
    final Object? e = erreurListe;
    erreurListe = null;
    if (e != null) return Future<List<LangueCommunication>>.error(e);
    return Future<List<LangueCommunication>>.value(
      List<LangueCommunication>.unmodifiable(_langues),
    );
  }

  @override
  Future<String?> maLangue() {
    final Object? e = erreurLecture;
    erreurLecture = null;
    if (e != null) return Future<String?>.error(e);
    return Future<String?>.value(langue);
  }

  @override
  Future<void> regler(String code) {
    reglages.add(code);
    final Object? e = erreurReglage;
    erreurReglage = null;
    if (e != null) return Future<void>.error(e);
    final String propre = code.trim().toLowerCase();
    if (!_langues.any((LangueCommunication l) => l.code == propre)) {
      return Future<void>.error(const LangueRefusee());
    }
    langue = propre;
    return Future<void>.value();
  }
}
