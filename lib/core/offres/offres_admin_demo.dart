/// Le double de demonstration du port des offres administrateur (K-28).
///
/// Donnees fictives, en memoire, jamais envoyees au serveur. Trois offres, une
/// par etat. Les memes refus que le serveur sont simules (jours hors nombre
/// annonce, motif vide, offre deja publiee) pour que la demonstration ne
/// montre pas un parcours que le serveur refuserait.
library;

import 'dart:async';

import '../i18n/strings.g.dart';
import 'offre_horaire.dart' show LangueCours, PublicOffre, ReglesAcademie;
import 'port_offres_admin.dart';

/// Le port de demonstration.
class OffresAdminDemo implements PortOffresAdmin {
  /// Cree le double, avec ses trois offres (ou [offres] si fournies). Sans
  /// latence par defaut, comme les autres doubles du depot (aucune minuterie
  /// en attente dans les tests).
  OffresAdminDemo({List<OffreAdmin>? offres, this.latence = Duration.zero})
    : _offres = List<OffreAdmin>.of(offres ?? offresDemoParDefaut);

  /// L'attente simulee avant chaque reponse.
  final Duration latence;

  final List<OffreAdmin> _offres;
  int _suivant = 100;

  /// Les trois offres de demonstration : une publiee, un brouillon, une
  /// retiree. Horaires de soiree en Europe et en fin de semaine, comme la
  /// decision du 09/10 les decrit.
  static const List<OffreAdmin> offresDemoParDefaut = <OffreAdmin>[
    OffreAdmin(
      id: 'offre-demo-1',
      public: PublicOffre.enfants,
      langueCode: 'francais',
      langueNom: 'Français',
      fuseauIana: 'Europe/Paris',
      jours: <int>[1, 3, 5],
      heureLocale: 18,
      dureeMinutes: 60,
      etat: EtatOffreAdmin.publiee,
    ),
    OffreAdmin(
      id: 'offre-demo-2',
      public: PublicOffre.adultes,
      langueCode: 'francais',
      langueNom: 'Français',
      fuseauIana: 'Europe/Paris',
      jours: <int>[2, 4, 6],
      heureLocale: 20,
      dureeMinutes: 90,
      etat: EtatOffreAdmin.brouillon,
    ),
    OffreAdmin(
      id: 'offre-demo-3',
      public: PublicOffre.enfants,
      langueCode: 'poular',
      langueNom: 'Poular',
      fuseauIana: 'America/Toronto',
      jours: <int>[6, 7, 3],
      heureLocale: 10,
      dureeMinutes: 60,
      etat: EtatOffreAdmin.retiree,
      motifRetrait: 'Horaire remplacé par une offre plus proche des familles.',
    ),
  ];

  Future<void> _attendre() async {
    if (latence > Duration.zero) await Future<void>.delayed(latence);
  }

  int _rang(EtatOffreAdmin e) => switch (e) {
    EtatOffreAdmin.publiee => 0,
    EtatOffreAdmin.brouillon => 1,
    EtatOffreAdmin.retiree => 2,
  };

  @override
  Future<ReglesCreationOffre> reglesCreation() async {
    await _attendre();
    return ReglesCreationOffre(
      langues: const <LangueCours>[
        LangueCours(code: 'poular', nom: 'Poular'),
        LangueCours(code: 'francais', nom: 'Français'),
        LangueCours(code: 'english', nom: 'English'),
      ],
      regles: ReglesAcademie.depuisJson(const <String, dynamic>{}),
    );
  }

  @override
  Future<List<OffreAdmin>> lister() async {
    await _attendre();
    final List<OffreAdmin> tri = List<OffreAdmin>.of(_offres)
      ..sort((OffreAdmin a, OffreAdmin b) {
        final int c = _rang(a.etat).compareTo(_rang(b.etat));
        return c != 0 ? c : a.heureLocale.compareTo(b.heureLocale);
      });
    return tri;
  }

  @override
  Future<String> creer({
    required String typePublic,
    required String langueCode,
    required String fuseauIana,
    required List<int> jours,
    required int heureLocale,
    int? dureeMinutes,
  }) async {
    await _attendre();
    if (jours.isEmpty) {
      throw OffreAdminRefusee(t.admin.offres.serveur.jourManquant);
    }
    final List<int> tries = (<int>{...jours}.toList()..sort());
    final PublicOffre public = PublicOffre.depuisSql(typePublic);
    final String id = 'offre-demo-${_suivant++}';
    _offres.add(
      OffreAdmin(
        id: id,
        public: public,
        langueCode: langueCode,
        langueNom: langueCode == 'poular'
            ? 'Poular'
            : langueCode == 'english'
            ? 'English'
            : 'Français',
        fuseauIana: fuseauIana,
        jours: tries,
        heureLocale: heureLocale,
        dureeMinutes: dureeMinutes ?? (public == PublicOffre.adultes ? 90 : 60),
        etat: EtatOffreAdmin.brouillon,
      ),
    );
    return id;
  }

  OffreAdmin _trouver(String id) => _offres.firstWhere(
    (OffreAdmin o) => o.id == id,
    orElse: () => throw OffreAdminRefusee(t.admin.offres.serveur.introuvable),
  );

  void _remplacer(OffreAdmin o, EtatOffreAdmin etat, {String? motif}) {
    final int i = _offres.indexWhere((OffreAdmin x) => x.id == o.id);
    _offres[i] = OffreAdmin(
      id: o.id,
      public: o.public,
      langueCode: o.langueCode,
      langueNom: o.langueNom,
      fuseauIana: o.fuseauIana,
      jours: o.jours,
      heureLocale: o.heureLocale,
      dureeMinutes: o.dureeMinutes,
      etat: etat,
      motifRetrait: motif,
    );
  }

  @override
  Future<void> publier(String offreId) async {
    await _attendre();
    final OffreAdmin o = _trouver(offreId);
    if (o.etat != EtatOffreAdmin.brouillon) {
      throw OffreAdminRefusee(t.admin.offres.serveur.dejaPubliee);
    }
    _remplacer(o, EtatOffreAdmin.publiee);
  }

  @override
  Future<void> retirer(String offreId, {required String motif}) async {
    await _attendre();
    if (motif.trim().isEmpty) {
      throw OffreAdminRefusee(t.admin.offres.serveur.motifRequis);
    }
    final OffreAdmin o = _trouver(offreId);
    if (o.etat == EtatOffreAdmin.retiree) {
      throw OffreAdminRefusee(t.admin.offres.serveur.dejaRetiree);
    }
    _remplacer(o, EtatOffreAdmin.retiree, motif: motif.trim());
  }
}
