// Les avis en memoire : la demonstration et les tests (AVIS-PUBLICS). Meme
// contrat que le serveur : un lien ferme, expire ou plein refuse le depot
// (`LienAvisFerme`), un champ hors regle est nomme (`ChampAvisInvalide`), la
// moderation suit les memes transitions (en_attente vers publie ou refuse,
// publie vers retire), le motif est obligatoire pour refuser et retirer.
//
// Jamais branche en production : `lib/main.dart` y met `AvisSupabase`.

import 'port_avis.dart';

/// Les avis tenus en memoire.
class AvisDemonstration implements PortAvis {
  /// Cree le port, avec des liens et des avis de depart.
  AvisDemonstration({
    List<LienAvis> liens = const <LienAvis>[],
    List<AvisAdmin> avis = const <AvisAdmin>[],
    Set<String> ouverts = const <String>{'ouvert'},
    DateTime Function()? maintenant,
  }) : liens = List<LienAvis>.of(liens),
       avis = List<AvisAdmin>.of(avis),
       jetonsOuverts = Set<String>.of(ouverts),
       _maintenant = maintenant ?? DateTime.now;

  final DateTime Function() _maintenant;

  /// Les jetons dont le lien accepte des avis.
  final Set<String> jetonsOuverts;

  /// Les liens, le plus recent d'abord.
  final List<LienAvis> liens;

  /// Les avis, le plus recent d'abord.
  final List<AvisAdmin> avis;

  /// Les depots recus : (jeton, avis).
  final List<(String, DepotAvis)> depots = <(String, DepotAvis)>[];

  /// Les jetons crees, dans l'ordre.
  final List<String> jetonsCrees = <String>[];

  /// Une erreur a lever au prochain appel de chaque methode, puis oubliee.
  Object? erreurLienOuvert;
  Object? erreurDepot;
  Object? erreurLiens;
  Object? erreurCreation;
  Object? erreurFermeture;
  Object? erreurAvis;
  Object? erreurModeration;

  /// Un depot en attente de liberation, pour montrer l'etat « envoi ».
  Future<void>? retenueDepot;

  /// Les lectures de chaque liste, pour verifier une relecture.
  int lecturesAvis = 0;
  int lecturesLiens = 0;
  int lecturesEtat = 0;

  int _suite = 0;

  Future<T> _sortie<T>(Object? erreur, T Function() valeur) {
    if (erreur != null) return Future<T>.error(erreur);
    return Future<T>.value(valeur());
  }

  @override
  Future<bool> lienOuvert(String jeton) {
    lecturesEtat++;
    final Object? e = erreurLienOuvert;
    erreurLienOuvert = null;
    return _sortie<bool>(e, () => jetonsOuverts.contains(jeton));
  }

  /// Le premier champ hors regle d'un depot, ou `null`. Les memes bornes que le
  /// serveur : nom 2 a 60, titre 80 au plus, texte 20 a 1500, note 1 a 5,
  /// mois ni futur ni avant 2015, accord obligatoire.
  ChampAvis? champInvalide(DepotAvis a) {
    final int nom = a.nom.trim().length;
    if (nom < 2 || nom > 60) return ChampAvis.nom;
    if (a.pays.length != 2) return ChampAvis.pays;
    final DateTime maintenant = _maintenant();
    final DateTime mois = DateTime(a.depuis.year, a.depuis.month);
    if (mois.isBefore(DateTime(2015)) ||
        mois.isAfter(DateTime(maintenant.year, maintenant.month))) {
      return ChampAvis.depuis;
    }
    if (a.note < 1 || a.note > 5) return ChampAvis.note;
    if ((a.titre ?? '').trim().length > 80) return ChampAvis.titre;
    final int texte = a.texte.trim().length;
    if (texte < 20 || texte > 1500) return ChampAvis.texte;
    if (!a.accord) return ChampAvis.accord;
    return null;
  }

  @override
  Future<void> deposer(String jeton, DepotAvis a) async {
    final Future<void>? retenue = retenueDepot;
    if (retenue != null) await retenue;
    final Object? e = erreurDepot;
    erreurDepot = null;
    if (e != null) return Future<void>.error(e);
    if (!jetonsOuverts.contains(jeton)) throw const LienAvisFerme();
    final ChampAvis? champ = champInvalide(a);
    if (champ != null) throw ChampAvisInvalide(champ);
    depots.add((jeton, a));
    final DateTime maintenant = _maintenant();
    avis.insert(
      0,
      AvisAdmin(
        id: 'a${++_suite}',
        lienLibelle: 'Lien de demonstration',
        nomAffiche: a.nom.trim(),
        qualite: a.qualite,
        pays: a.pays.toUpperCase(),
        depuis: DateTime(a.depuis.year, a.depuis.month),
        note: a.note,
        titre: (a.titre ?? '').trim().isEmpty ? null : a.titre!.trim(),
        texte: a.texte.trim(),
        accordPublicLe: maintenant,
        statut: StatutAvis.enAttente,
        deposeLe: maintenant,
      ),
    );
  }

  @override
  Future<LienAvisCree> creerLien({
    required String libelle,
    required int jours,
    required int avisMax,
  }) {
    final Object? e = erreurCreation;
    erreurCreation = null;
    return _sortie<LienAvisCree>(e, () {
      final DateTime maintenant = _maintenant();
      final String id = 'l${++_suite}';
      final String jeton = 'jeton-$id';
      final DateTime fin = maintenant.add(Duration(days: jours));
      jetonsCrees.add(jeton);
      jetonsOuverts.add(jeton);
      liens.insert(
        0,
        LienAvis(
          id: id,
          libelle: libelle.trim(),
          creeLe: maintenant,
          expireLe: fin,
          avisMax: avisMax,
          avisRecus: 0,
          ferme: false,
          actif: true,
        ),
      );
      return LienAvisCree(id: id, jeton: jeton, expireLe: fin);
    });
  }

  @override
  Future<List<LienAvis>> listerLiens() {
    lecturesLiens++;
    final Object? e = erreurLiens;
    erreurLiens = null;
    return _sortie<List<LienAvis>>(e, () => List<LienAvis>.of(liens));
  }

  @override
  Future<void> fermerLien(String id) {
    final Object? e = erreurFermeture;
    erreurFermeture = null;
    return _sortie<void>(e, () {
      final int i = liens.indexWhere((LienAvis l) => l.id == id);
      if (i < 0) return;
      final LienAvis l = liens[i];
      liens[i] = LienAvis(
        id: l.id,
        libelle: l.libelle,
        creeLe: l.creeLe,
        expireLe: l.expireLe,
        avisMax: l.avisMax,
        avisRecus: l.avisRecus,
        ferme: true,
        actif: false,
      );
    });
  }

  @override
  Future<List<AvisAdmin>> listerAvis({StatutAvis? statut}) {
    lecturesAvis++;
    final Object? e = erreurAvis;
    erreurAvis = null;
    return _sortie<List<AvisAdmin>>(
      e,
      () => <AvisAdmin>[
        for (final AvisAdmin a in avis)
          if (statut == null || a.statut == statut) a,
      ],
    );
  }

  @override
  Future<void> moderer(String id, StatutAvis statut, {String? motif}) {
    final Object? e = erreurModeration;
    erreurModeration = null;
    if (e != null) return Future<void>.error(e);
    final int i = avis.indexWhere((AvisAdmin a) => a.id == id);
    if (i < 0) {
      return Future<void>.error(
        const ModerationAvisRefusee(RefusModeration.introuvable),
      );
    }
    final AvisAdmin a = avis[i];
    final bool permis =
        (a.statut == StatutAvis.enAttente &&
            (statut == StatutAvis.publie || statut == StatutAvis.refuse)) ||
        (a.statut == StatutAvis.publie && statut == StatutAvis.retire);
    if (!permis) {
      return Future<void>.error(
        const ModerationAvisRefusee(RefusModeration.etatChange),
      );
    }
    final String propre = (motif ?? '').trim();
    final bool motifRequis =
        statut == StatutAvis.refuse || statut == StatutAvis.retire;
    if (motifRequis && propre.isEmpty) {
      return Future<void>.error(
        const ModerationAvisRefusee(RefusModeration.motifManquant),
      );
    }
    final DateTime maintenant = _maintenant();
    avis[i] = AvisAdmin(
      id: a.id,
      lienLibelle: a.lienLibelle,
      nomAffiche: a.nomAffiche,
      qualite: a.qualite,
      pays: a.pays,
      depuis: a.depuis,
      note: a.note,
      titre: a.titre,
      texte: a.texte,
      accordPublicLe: a.accordPublicLe,
      statut: statut,
      motif: motifRequis ? propre : null,
      deposeLe: a.deposeLe,
      modereLe: maintenant,
      publieLe: statut == StatutAvis.publie ? maintenant : a.publieLe,
    );
    return Future<void>.value();
  }
}
