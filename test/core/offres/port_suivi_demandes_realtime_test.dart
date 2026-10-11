import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/offres/port_suivi_demandes.dart';
import 'package:rewayah_academy/core/offres/port_suivi_demandes_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('PortSuiviDemandesSupabase Realtime', () {
    test('propagates an error before the initial snapshot', () async {
      final StateError failure = StateError('subscription rejected');
      final _Harness harness = _Harness();
      final Completer<Object> receivedError = Completer<Object>();
      final StreamSubscription<List<SuiviDemande>> subscription = harness.port
          .suivre()
          .listen((_) {}, onError: receivedError.complete);
      await harness.channel.subscriptionStarted.future.timeout(
        const Duration(seconds: 3),
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        harness.channel.emitStatus(
          RealtimeSubscribeStatus.channelError,
          failure,
        ),
        isTrue,
      );

      expect(
        await receivedError.future.timeout(const Duration(seconds: 2)),
        same(failure),
      );
      await subscription.cancel();
      expect(harness.client.rpcCalls, 0);
      expect(harness.client.removedChannels, 1);
    });

    test('propagates a channel error after the initial snapshot', () async {
      final StateError failure = StateError('channel disconnected');
      final _Harness harness = _Harness();
      final Completer<void> receivedInitial = Completer<void>();
      final Completer<Object> receivedError = Completer<Object>();
      int snapshots = 0;
      final StreamSubscription<List<SuiviDemande>> subscription = harness.port
          .suivre()
          .listen((_) {
            snapshots++;
            if (!receivedInitial.isCompleted) receivedInitial.complete();
          }, onError: receivedError.complete);
      await harness.channel.subscriptionStarted.future.timeout(
        const Duration(seconds: 3),
      );
      await Future<void>.delayed(Duration.zero);
      harness.channel.emitStatus(RealtimeSubscribeStatus.subscribed);
      await receivedInitial.future.timeout(const Duration(seconds: 2));
      expect(harness.client.rpcCalls, 1);

      harness.channel.emitStatus(RealtimeSubscribeStatus.channelError, failure);

      expect(
        await receivedError.future.timeout(const Duration(seconds: 2)),
        same(failure),
      );
      await subscription.cancel();
      expect(snapshots, 1);
      expect(harness.client.removedChannels, 1);
    });

    test('coalesces a burst of row changes into one refresh', () async {
      final _Harness harness = _Harness();
      final Completer<void> receivedInitial = Completer<void>();
      final Completer<void> receivedSecond = Completer<void>();
      int snapshots = 0;
      final StreamSubscription<List<SuiviDemande>> subscription = harness.port
          .suivre()
          .listen((_) {
            snapshots++;
            if (snapshots == 1) receivedInitial.complete();
            if (snapshots == 2) receivedSecond.complete();
          });
      await harness.channel.subscriptionStarted.future.timeout(
        const Duration(seconds: 3),
      );
      await Future<void>.delayed(Duration.zero);
      harness.channel.emitStatus(RealtimeSubscribeStatus.subscribed);
      await receivedInitial.future.timeout(const Duration(seconds: 2));
      expect(harness.client.rpcCalls, 1);

      harness.channel.emitChange();
      harness.channel.emitChange();
      harness.channel.emitChange();

      await receivedSecond.future;
      expect(snapshots, 2);
      expect(harness.client.rpcCalls, 2);

      await subscription.cancel();
      expect(harness.client.removedChannels, 1);
    });
  });
}

class _Harness {
  _Harness() {
    client = _FakeSupabaseClient(channel, _EmptyAuth());
    port = PortSuiviDemandesSupabase(client);
  }

  final _FakeRealtimeChannel channel = _FakeRealtimeChannel();
  late final _FakeSupabaseClient client;
  late final PortSuiviDemandesSupabase port;
}

class _FakeSupabaseClient extends SupabaseClient {
  _FakeSupabaseClient(this._channel, GoTrueClient fakeAuth)
    : _fakeAuth = fakeAuth,
      super(
        'http://127.0.0.1:54321',
        'test-anon-key',
        accessToken: () async => null,
      );

  final _FakeRealtimeChannel _channel;
  final GoTrueClient _fakeAuth;
  int rpcCalls = 0;
  int removedChannels = 0;

  @override
  GoTrueClient get auth => _fakeAuth;

  @override
  RealtimeChannel channel(
    String name, {
    RealtimeChannelConfig opts = const RealtimeChannelConfig(),
  }) => _channel;

  @override
  Future<String> removeChannel(RealtimeChannel channel) async {
    removedChannels++;
    return 'ok';
  }

  @override
  PostgrestFilterBuilder<T> rpc<T>(
    String fn, {
    Map<String, dynamic>? params,
    get = false,
  }) {
    rpcCalls++;
    return _ImmediatePostgrestBuilder<T>(<dynamic>[] as T);
  }
}

class _ImmediatePostgrestBuilder<T> implements PostgrestFilterBuilder<T> {
  _ImmediatePostgrestBuilder(T result) : _result = Future<T>.value(result);

  final Future<T> _result;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) => _result.then(onValue, onError: onError);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EmptyAuth implements GoTrueClient {
  @override
  User? get currentUser => const User(
    id: 'family-user',
    appMetadata: <String, dynamic>{},
    userMetadata: <String, dynamic>{},
    aud: 'authenticated',
    createdAt: '2026-01-01T00:00:00Z',
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRealtimeChannel implements RealtimeChannel {
  final Completer<void> subscriptionStarted = Completer<void>();
  void Function(RealtimeSubscribeStatus, Object?)? _statusCallback;
  void Function(PostgresChangePayload)? _changeCallback;

  @override
  RealtimeChannel onPostgresChanges({
    required PostgresChangeEvent event,
    String? schema,
    String? table,
    PostgresChangeFilter? filter,
    List<PostgresChangeFilter>? filters,
    List<String>? select,
    required void Function(PostgresChangePayload payload) callback,
  }) {
    _changeCallback = callback;
    return this;
  }

  @override
  RealtimeChannel subscribe([
    void Function(RealtimeSubscribeStatus status, Object? error)? callback,
    Duration? timeout,
  ]) {
    _statusCallback = callback;
    if (!subscriptionStarted.isCompleted) subscriptionStarted.complete();
    return this;
  }

  bool emitStatus(RealtimeSubscribeStatus status, [Object? error]) {
    final callback = _statusCallback;
    if (callback == null) return false;
    callback(status, error);
    return true;
  }

  void emitChange() => _changeCallback?.call(
    PostgresChangePayload(
      schema: 'public',
      table: 'demandes_horaires_famille',
      commitTimestamp: _epoch,
      eventType: PostgresChangeEvent.update,
      newRecord: <String, dynamic>{},
      oldRecord: <String, dynamic>{},
      errors: null,
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
