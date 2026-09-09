import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'session_state.dart';
import 'source_session.dart';

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

  @override
  SessionState build() {
    final SourceSession source = ref.watch(sourceSessionProvider);

    _abonnement = source.etats().listen((SessionState etat) {
      state = etat;
    });
    ref.onDispose(() => unawaited(_abonnement?.cancel()));

    return const SessionState.chargement();
  }
}
