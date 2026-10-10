// Les lectures des deux panneaux (CPT-DIR-1) : la politique de la Reserve
// (CPT-BR-12), la delegation (CPT-BR-13), l'etat actuel de la Reserve et les
// deux historiques de versions (CPT-BR-17).
//
// Chaque lecteur declare le port dont il depend : sans cela, il vivrait dans
// le conteneur racine et lirait le vrai port meme quand la demonstration
// surcharge le port dans une portee imbriquee (meme precaution que
// `demo_finance_page.dart`). `retry` nul : pas de retentative silencieuse de
// Riverpod 3 derriere le bouton « Reessayer ».

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../../../core/capacites/port_delegation_finance.dart';
import '../../../core/capacites/port_politique_reserve.dart';
import '../../../core/comptable/modeles_comptable.dart';

Duration? _sansRetentative(int tentative, Object erreur) => null;

/// La politique de la Reserve en vigueur.
final FutureProvider<PolitiqueReserve> politiqueReserveProvider =
    FutureProvider<PolitiqueReserve>(
      (Ref ref) => ref.watch(portPolitiqueReserveProvider).politique(),
      retry: _sansRetentative,
      dependencies: <ProviderOrFamily>[portPolitiqueReserveProvider],
    );

/// L'etat actuel de la Reserve (§9.7), lu avec la politique.
final FutureProvider<IndicateursReserve> indicateursReserveDirectionProvider =
    FutureProvider<IndicateursReserve>(
      (Ref ref) => ref.watch(portPolitiqueReserveProvider).indicateurs(),
      retry: _sansRetentative,
      dependencies: <ProviderOrFamily>[portPolitiqueReserveProvider],
    );

/// Les versions de la politique de la Reserve.
final FutureProvider<List<EntreeJournal>> journalReserveProvider =
    FutureProvider<List<EntreeJournal>>(
      (Ref ref) => ref.watch(portPolitiqueReserveProvider).journal(),
      retry: _sansRetentative,
      dependencies: <ProviderOrFamily>[portPolitiqueReserveProvider],
    );

/// La politique de delegation en vigueur.
final FutureProvider<PolitiqueDelegationFinance> politiqueDelegationProvider =
    FutureProvider<PolitiqueDelegationFinance>(
      (Ref ref) => ref.watch(portDelegationFinanceProvider).politique(),
      retry: _sansRetentative,
      dependencies: <ProviderOrFamily>[portDelegationFinanceProvider],
    );

/// Les versions de la delegation.
final FutureProvider<List<EntreeJournal>> journalDelegationProvider =
    FutureProvider<List<EntreeJournal>>(
      (Ref ref) => ref.watch(portDelegationFinanceProvider).journal(),
      retry: _sansRetentative,
      dependencies: <ProviderOrFamily>[portDelegationFinanceProvider],
    );
