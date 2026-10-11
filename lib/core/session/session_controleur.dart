import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import '../domain/enums.dart';
import 'port_capacite_eleve.dart';
import 'session_state.dart';
import 'source_session.dart';

/// Active le raccourci de demonstration uniquement dans le build qui le demande.
final Provider<bool> demoAuthActiveProvider = Provider<bool>(
  (Ref ref) => Env.authParMotDePasseActive,
);

/// Role et variante d'interface demandes par une adresse fictive.
typedef AccesDemo = ({AppRole role, InterfaceMode mode});

/// Traduit le prefixe d'un courriel fictif en interface de demonstration.
///
/// Le domaine est libre : `admin@demo.test` et `admin@example.test` ouvrent le
/// meme espace. Aucun de ces identifiants n'est envoye a Supabase.
AccesDemo? accesDemoDepuisCourriel(String courriel) {
  final String prefixe = courriel.trim().toLowerCase().split('@').first;
  return switch (prefixe) {
    'admin' => (role: AppRole.admin, mode: InterfaceMode.standard),
    'comptable' ||
    'accountant' => (role: AppRole.accountant, mode: InterfaceMode.standard),
    'controleur' ||
    'controller' => (role: AppRole.controller, mode: InterfaceMode.standard),
    'enseignant' ||
    'teacher' => (role: AppRole.teacher, mode: InterfaceMode.standard),
    'tuteur' ||
    'guardian' => (role: AppRole.guardian, mode: InterfaceMode.standard),
    'eleve' ||
    'student' => (role: AppRole.student, mode: InterfaceMode.standard),
    'enfant' || 'child' => (role: AppRole.student, mode: InterfaceMode.enfant),
    _ => null,
  };
}

/// La source de session utilisee par l'application.
///
/// Les tests la remplacent par une source en memoire : le routeur se verifie
/// alors sans reseau ni backend.
final Provider<SourceSession> sourceSessionProvider = Provider<SourceSession>(
  (Ref ref) => SourceSessionSupabase(Supabase.instance.client),
);

/// L'etat de session courant, synchrone.
///
/// Synchrone volontairement : la redirection du routeur doit pouvoir decider
/// sans attendre. L'attente est representee par [PorteAcces.chargement], pas
/// par un `Future`.
final NotifierProvider<SessionControleur, SessionState> sessionProvider =
    NotifierProvider<SessionControleur, SessionState>(SessionControleur.new);

/// Maintient [SessionState] a jour a partir de la [SourceSession].
class SessionControleur extends Notifier<SessionState> {
  StreamSubscription<SessionState>? _abonnement;
  bool _demoActive = false;
  final Map<String, bool> _autonomes = <String, bool>{};

  @override
  SessionState build() {
    final SourceSession source = ref.watch(sourceSessionProvider);

    _abonnement = source.etats().listen((SessionState etat) {
      if (!_demoActive) {
        _appliquer(etat);
      }
    });
    ref.onDispose(() => unawaited(_abonnement?.cancel()));

    return const SessionState.chargement();
  }

  /// Ouvre une session locale de demonstration sans contacter Supabase.
  void ouvrirDemo(AccesDemo acces) {
    if (!ref.read(demoAuthActiveProvider)) {
      throw StateError('Le mode de demonstration n est pas compile.');
    }
    _demoActive = true;
    _appliquer(
      SessionState(
        resolue: true,
        role: acces.role,
        profileId: 'demo-${acces.role.valeurSql}',
        accountStatus: AccountStatus.active,
        interfaceMode: acces.mode,
        lectureProfil: LectureProfil.presente,
      ),
    );
  }

  /// Publie [etat] avec la capacite « eleve autonome » deja connue pour ce
  /// profil, puis la lit sur le port si elle ne l'est pas encore (C-24).
  /// Une reponse inconnue ou en echec laisse la capacite fausse.
  void _appliquer(SessionState etat) {
    final String? profil = etat.profileId;
    state = etat.copyWith(
      eleveAutonome: profil != null && (_autonomes[profil] ?? false),
    );
    if (profil == null || _autonomes.containsKey(profil)) {
      return;
    }
    _autonomes[profil] = false;
    unawaited(_lireCapacite(profil));
  }

  Future<void> _lireCapacite(String profil) async {
    CapaciteEleve capacite;
    try {
      capacite = await ref.read(portCapaciteEleveProvider).lire(profil);
    } on Object {
      capacite = const CapaciteInconnue();
    }
    final bool autonome = capacite is EleveAutonome;
    _autonomes[profil] = autonome;
    if (ref.mounted && state.profileId == profil) {
      state = state.copyWith(eleveAutonome: autonome);
    }
  }

  /// Ferme la session locale et indique si une session demo etait active.
  bool fermerDemo() {
    if (!_demoActive) {
      return false;
    }
    _demoActive = false;
    state = const SessionState.deconnecte();
    return true;
  }
}

/// Lie une lecture a la personne connectee : la lecture qui l'appelle est
/// refaite des que l'identifiant du profil de la session change
/// (deconnexion, changement de compte sur un appareil partage). Une lecture
/// d'argent (soldes, mouvements, recharge, revenus) ne survit jamais a la
/// personne qui l'a demandee (revue FI-VAGUE-R R7-04 ; meme precedent que
/// `identiteTitulaireProvider` et `monAccesProvider`).
void surveillerPersonneConnectee(Ref ref) =>
    ref.watch(sessionProvider.select((SessionState s) => s.profileId));
