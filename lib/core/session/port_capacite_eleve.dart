import 'package:flutter_riverpod/flutter_riverpod.dart';

sealed class CapaciteEleve {
  const CapaciteEleve();
}

final class EleveAutonome extends CapaciteEleve {
  const EleveAutonome();
}

final class PasEleve extends CapaciteEleve {
  const PasEleve();
}

final class CapaciteInconnue extends CapaciteEleve {
  const CapaciteInconnue();
}

abstract interface class PortCapaciteEleve {
  Future<CapaciteEleve> lire();
}

final Provider<PortCapaciteEleve?> portCapaciteEleveProvider =
    Provider<PortCapaciteEleve?>((Ref ref) => null);
