import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/enums.dart';
import '../i18n/strings.g.dart';
import '../theme/app_spacing.dart';
import '../widgets/action_principale.dart';
import '../widgets/bento_tile.dart';

/// Etat serveur de la demande d'affichage standard d'un eleve.
@immutable
class EtatInterfaceGuidee {
  const EtatInterfaceGuidee({
    required this.mode,
    required this.eligible,
    required this.demande,
  });

  factory EtatInterfaceGuidee.depuisJson(Map<String, dynamic> json) {
    return EtatInterfaceGuidee(
      mode: InterfaceMode.depuisSql(json['interface_mode'] as String?),
      eligible: json['eligible'] as bool? ?? false,
      demande: json['request_status'] as String? ?? 'none',
    );
  }

  final InterfaceMode mode;
  final bool eligible;
  final String demande;

  bool get enAttente => demande == 'pending';
  bool get refusee => demande == 'declined';
}

/// Portes serveur de l'Interface guidee. La date et l'age ne sont jamais
/// calcules dans Flutter.
abstract interface class ServiceInterfaceGuidee {
  Future<EtatInterfaceGuidee> etat();

  Future<void> demanderAffichageStandard();
}

class ServiceInterfaceGuideeSupabase implements ServiceInterfaceGuidee {
  const ServiceInterfaceGuideeSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<EtatInterfaceGuidee> etat() async {
    final List<dynamic> lignes = await _client.rpc<List<dynamic>>(
      'interface_guidee_etat',
    );
    if (lignes.isEmpty) {
      throw StateError('etat interface guidee absent');
    }
    return EtatInterfaceGuidee.depuisJson(lignes.first as Map<String, dynamic>);
  }

  @override
  Future<void> demanderAffichageStandard() async {
    await _client.rpc<dynamic>('demander_affichage_standard');
  }
}

final Provider<ServiceInterfaceGuidee> serviceInterfaceGuideeProvider =
    Provider<ServiceInterfaceGuidee>(
      (Ref ref) => ServiceInterfaceGuideeSupabase(Supabase.instance.client),
    );

final FutureProvider<EtatInterfaceGuidee> etatInterfaceGuideeProvider =
    FutureProvider<EtatInterfaceGuidee>(
      (Ref ref) => ref.watch(serviceInterfaceGuideeProvider).etat(),
    );

/// Notice volontairement compacte, rendue uniquement quand le serveur
/// confirme l'eligibilite. Un profil plus jeune, sans date fiable ou deja
/// standard ne voit aucun appel a l'action.
class InterfaceGuideeNotice extends ConsumerStatefulWidget {
  const InterfaceGuideeNotice({super.key});

  @override
  ConsumerState<InterfaceGuideeNotice> createState() =>
      _InterfaceGuideeNoticeState();
}

class _InterfaceGuideeNoticeState extends ConsumerState<InterfaceGuideeNotice> {
  bool _envoi = false;
  String? _erreur;

  Future<void> _demander() async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(serviceInterfaceGuideeProvider)
          .demanderAffichageStandard();
      ref.invalidate(etatInterfaceGuideeProvider);
    } on Object catch (erreur) {
      if (mounted) setState(() => _erreur = erreur.toString());
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<EtatInterfaceGuidee> etat = ref.watch(
      etatInterfaceGuideeProvider,
    );
    final EtatInterfaceGuidee? valeur = etat.value;
    if (valeur == null || valeur.mode != InterfaceMode.enfant) {
      return const SizedBox.shrink();
    }
    if (!valeur.eligible) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: BentoTile(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(t.eleve.accueil.interfaceGuideeDemander),
            Ecart.vSm,
            Text(
              valeur.enAttente
                  ? t.eleve.accueil.interfaceGuideeDemandeEnvoyee
                  : valeur.refusee
                  ? t.eleve.accueil.interfaceGuideeDemandeRefusee
                  : t.eleve.accueil.interfaceGuideeDemanderDetail,
            ),
            if (!valeur.enAttente) ...<Widget>[
              Ecart.vMd,
              ActionPrincipale(
                libelle: t.eleve.accueil.interfaceGuideeDemander,
                enCours: _envoi,
                onPress: _demander,
              ),
            ],
            if (_erreur != null) ...<Widget>[Ecart.vSm, Text(_erreur!)],
          ],
        ),
      ),
    );
  }
}
