// Le double de `ServicePraxis` : aucune base, des donnees fictives, un journal
// de ce que l'ecran a demande. Sert aux tests de la section « Praxis » et aux
// ecrans qui l'embarquent (Acces des agents IA).

import 'package:rewayah_academy/core/agent/service_praxis.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

/// Une cle fictive.
ClePraxis clePraxisFictive({
  String id = 'c1',
  String libelle = 'Conversation du directeur',
  String prefixe = 'prx_1a2b3c4d',
  UsageClePraxis usage = UsageClePraxis.chat,
  EtatClePraxis etat = EtatClePraxis.active,
  DateTime? derniereUtilisation,
}) => ClePraxis(
  id: id,
  libelle: libelle,
  prefixe: prefixe,
  usage: usage,
  emiseLe: DateTime(2026, 11, 10, 9),
  expireLe: DateTime(2026, 12, 10, 9),
  etat: etat,
  derniereUtilisationLe: derniereUtilisation,
);

/// Une ligne de journal fictive.
LigneJournalPraxis ligneJournalFictive(
  int id, {
  String outil = 'ecrire',
  String issue = 'ok',
  String? extrait = 'Bonjour, votre demande est bien reçue.',
}) => LigneJournalPraxis(
  id: id,
  outil: outil,
  issue: issue,
  heure: DateTime(2026, 11, 16, 8, id % 60),
  extrait: extrait,
);

/// Le double.
class FauxServicePraxis implements ServicePraxis {
  /// Cree le double.
  FauxServicePraxis({
    EtatPraxis? etat,
    List<List<LigneJournalPraxis>>? pages,
    this.erreurEtat,
    this.erreurJournal,
    this.refusDroit = false,
    this.erreurEcriture,
  }) : _etat =
           etat ??
           EtatPraxis(
             actif: false,
             autonome: false,
             envoisParHeure: 30,
             cles: <ClePraxis>[
               clePraxisFictive(
                 derniereUtilisation: DateTime(2026, 11, 15, 18),
               ),
               clePraxisFictive(
                 id: 'c2',
                 libelle: 'Routine du soir',
                 prefixe: 'prx_9f8e7d6c',
                 usage: UsageClePraxis.routine,
                 etat: EtatClePraxis.revoquee,
               ),
             ],
           ),
       _pages = pages ?? <List<LigneJournalPraxis>>[];

  EtatPraxis _etat;
  final List<List<LigneJournalPraxis>> _pages;

  /// Une lecture de l'etat qui echoue (reseau, serveur).
  Exception? erreurEtat;

  /// Une lecture du journal qui echoue.
  Exception? erreurJournal;

  /// Vrai : toute ecriture est refusee par le serveur faute de double
  /// verification (42501).
  bool refusDroit;

  /// Une erreur quelconque a l'ecriture (reponse perdue, panne).
  Exception? erreurEcriture;

  /// Ce que l'ecran a demande, dans l'ordre.
  final List<String> appels = <String>[];

  @override
  String get adresseConnecteur =>
      'https://exemple.test/functions/v1/praxis-mcp';

  void _ecrire() {
    if (refusDroit) {
      throw const PostgrestException(message: 'refus', code: '42501');
    }
    if (erreurEcriture != null) {
      throw erreurEcriture!;
    }
  }

  @override
  Future<EtatPraxis> etat() async {
    appels.add('etat');
    if (erreurEtat != null) {
      throw erreurEtat!;
    }
    return _etat;
  }

  @override
  Future<PageJournalPraxis> journal({int? avant}) async {
    appels.add('journal:${avant ?? '-'}');
    if (erreurJournal != null) {
      throw erreurJournal!;
    }
    if (_pages.isEmpty) {
      return const PageJournalPraxis(lignes: <LigneJournalPraxis>[]);
    }
    final int index = avant == null
        ? 0
        : _pages.indexWhere((List<LigneJournalPraxis> p) => p.first.id < avant);
    if (index < 0) {
      return const PageJournalPraxis(lignes: <LigneJournalPraxis>[]);
    }
    final List<LigneJournalPraxis> page = _pages[index];
    return PageJournalPraxis(
      lignes: page,
      suite: index < _pages.length - 1 ? page.last.id : null,
    );
  }

  @override
  Future<void> regler({
    bool? actif,
    bool? autonome,
    int? envoisParHeure,
  }) async {
    appels.add('regler:$actif:$autonome:$envoisParHeure');
    _ecrire();
    _etat = EtatPraxis(
      actif: actif ?? _etat.actif,
      autonome: autonome ?? _etat.autonome,
      envoisParHeure: envoisParHeure ?? _etat.envoisParHeure,
      essaiFils: _etat.essaiFils,
      donneesReelles: _etat.donneesReelles,
      cles: _etat.cles,
    );
  }

  @override
  Future<void> reglerDonneesReelles({required bool ouvert}) async {
    appels.add('donnees:$ouvert');
    _ecrire();
    _etat = EtatPraxis(
      actif: _etat.actif,
      autonome: _etat.autonome,
      envoisParHeure: _etat.envoisParHeure,
      essaiFils: _etat.essaiFils,
      donneesReelles: ouvert,
      cles: _etat.cles,
    );
  }

  @override
  Future<void> reglerEssai(List<String> fils) async {
    appels.add('essai:${fils.join(',')}');
    _ecrire();
    _etat = EtatPraxis(
      actif: _etat.actif,
      autonome: _etat.autonome,
      envoisParHeure: _etat.envoisParHeure,
      essaiFils: fils,
      donneesReelles: _etat.donneesReelles,
      cles: _etat.cles,
    );
  }

  @override
  Future<ClePraxisEmise> emettre({
    required String libelle,
    required UsageClePraxis usage,
    required DateTime expireLe,
    required String cleEmission,
  }) async {
    appels.add('emettre:$libelle:${usage.name}:$cleEmission');
    _ecrire();
    _etat = EtatPraxis(
      actif: _etat.actif,
      autonome: _etat.autonome,
      envoisParHeure: _etat.envoisParHeure,
      essaiFils: _etat.essaiFils,
      donneesReelles: _etat.donneesReelles,
      cles: <ClePraxis>[
        clePraxisFictive(id: 'c-neuve', libelle: libelle, usage: usage),
        ..._etat.cles,
      ],
    );
    return ClePraxisEmise(
      secret: 'prx_${'ab12' * 16}',
      id: 'c-neuve',
      expireLe: expireLe,
    );
  }

  @override
  Future<bool> revoquer({
    required String id,
    required String motif,
    required String cleRevocation,
  }) async {
    appels.add('revoquer:$id:$motif');
    _ecrire();
    _etat = EtatPraxis(
      actif: _etat.actif,
      autonome: _etat.autonome,
      envoisParHeure: _etat.envoisParHeure,
      essaiFils: _etat.essaiFils,
      donneesReelles: _etat.donneesReelles,
      cles: <ClePraxis>[
        for (final ClePraxis c in _etat.cles)
          if (c.id == id)
            clePraxisFictive(
              id: c.id,
              libelle: c.libelle,
              prefixe: c.prefixe,
              usage: c.usage,
              etat: EtatClePraxis.revoquee,
            )
          else
            c,
      ],
    );
    return true;
  }
}
