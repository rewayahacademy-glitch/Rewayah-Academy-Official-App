import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/service_configuration.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_observation/echec_observation.dart';
import '../../core/tc_observation/guardian_observation_policy.dart';
import '../../core/tc_observation/port_politique_observation.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/skeleton.dart';
import '../tc_observation_ui/module_reglages_observation.dart';

/// Les defauts d'observation de l'Academie, lus dans `app_config`.
///
/// **Pourquoi pas la RPC.** `politique_observation_effective(p_groupe_id)` rend
/// la politique EFFECTIVE d'un groupe : sur un groupe personnalise, elle rend
/// les valeurs du groupe et n'a plus rien a dire de l'Academie
/// (`0033_tc_vues_rpc.sql`, branche `v_source = 'groupe'`). Afficher cette
/// reponse sous l'etiquette « Academie : ... » ferait lire a l'administrateur
/// ses propres valeurs comme si elles etaient celles dont il herite. Les
/// defauts vivent dans `app_config`, que l'administration lit deja directement
/// (RLS `app_config_admin_read`, migration `0001`) : on les lit la, a la meme
/// source que le serveur.
///
/// Les replis sont ceux du serveur, cle par cle -- une cle jamais seedee doit
/// afficher ce que la base appliquerait, pas un chiffre invente.
final FutureProvider<GuardianObservationPolicy>
politiqueAcademieObservationProvider = FutureProvider<GuardianObservationPolicy>(
  (Ref ref) async => politiqueAcademieDepuis(
    await ref.watch(serviceConfigurationProvider).lire(clesObservation),
  ),
);

/// Construit la politique d'Academie depuis les quatre valeurs de `app_config`.
GuardianObservationPolicy politiqueAcademieDepuis(List<ValeurConfig> valeurs) {
  final Map<String, Object?> parCle = <String, Object?>{
    for (final ValeurConfig valeur in valeurs) valeur.cle: valeur.valeur,
  };
  int entier(String cle, int defaut) {
    final Object? brut = parCle[cle];
    return brut is num ? brut.toInt() : defaut;
  }

  final Object? version = parCle['observation.policy_version'];
  final Object? parVisite = parCle['observation.max_seconds_per_visit'];
  return GuardianObservationPolicy(
    policyVersion: version is String && version.isNotEmpty ? version : 'a1',
    source: SourcePolitique.academie,
    observationActivee: true,
    maxVisitsPerSession: entier('observation.max_visits_per_session', 1),
    maxTotalObservationTime: Duration(
      seconds: entier('observation.max_total_seconds', 120),
    ),
    maxParVisite: parVisite is num
        ? Duration(seconds: parVisite.toInt())
        : null,
  );
}

/// Le reglage d'observation d'un groupe, en feuille sur sa ligne.
///
/// **Aucune route n'est posee pour ce module, et c'est voulu.** Ni
/// `lib/core/router/app_router.dart` ni `lib/features/tc_observation_ui/
/// routes_tc_g.dart` ne le connaissent : le seul acces est l'action
/// « Reglages d'observation » de la ligne du groupe, dans Admin > Operations >
/// Groupes, qui ouvre cette feuille en `AppBottomSheet`. Toutes les actions de
/// groupe du produit s'ouvrent ainsi (jamais une boite de dialogue Material), et
/// un ecran de plus aurait demande une route, une entree de navigation et une
/// place dans le gel des huit domaines pour le meme geste.
///
/// **Depuis le groupe parce que le serveur est par groupe** :
/// `definir_politique_observation_groupe` prend un `p_groupe_id` et n'ecrit que
/// sur `public.groupes`. La page hote vit sous `/admin/operations/groupes`, ou
/// `deciderRedirection` n'admet que le role admin -- le meme role que la RPC
/// exige, avec `app_account_valid()`. Aucun role que le serveur refuserait
/// n'atteint donc cette feuille.
class FeuilleObservationGroupe extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleObservationGroupe({
    required this.groupeId,
    required this.onEnregistre,
    super.key,
  });

  /// Le groupe regle.
  final String groupeId;

  /// Appele apres un enregistrement accepte par le serveur.
  final VoidCallback onEnregistre;

  @override
  ConsumerState<FeuilleObservationGroupe> createState() =>
      _FeuilleObservationGroupeEtat();
}

class _FeuilleObservationGroupeEtat
    extends ConsumerState<FeuilleObservationGroupe> {
  bool _envoi = false;
  String? _erreur;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<GuardianObservationPolicy> groupe = ref.watch(
      politiqueObservationProvider(widget.groupeId),
    );
    final AsyncValue<GuardianObservationPolicy> academie = ref.watch(
      politiqueAcademieObservationProvider,
    );

    if (groupe.hasError || academie.hasError) {
      return _echec(groupe.error ?? academie.error);
    }
    if (!groupe.hasValue || !academie.hasValue) {
      return const Skeleton.liste(lignes: 4);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ModuleReglagesObservation(
          politiqueAcademie: academie.requireValue,
          politiqueGroupe: groupe.requireValue,
          enCours: _envoi,
          onEnregistrer: _enregistrer,
        ),
        if (_erreur != null) ...<Widget>[
          Ecart.vMd,
          Text(
            _erreur!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        Ecart.vMd,
        Text(
          t.admin.groupes.journalisation,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// Ce qu'on affiche quand la lecture n'a pas pu se faire.
  ///
  /// Une capacite absente ne se reessaye pas, elle s'installe : le dire
  /// autrement enverrait un administrateur presser un bouton qui echouera a
  /// l'identique.
  Widget _echec(Object? erreur) => EmptyState(
    message: erreur is EchecObservation &&
            erreur.motif == MotifEchecObservation.capaciteAbsente
        ? t.admin.groupes.observationCapaciteAbsente
        : t.admin.groupes.erreur,
    icone: AppIcons.avertissement,
    registre: RegistreVide.subi,
  );

  Future<void> _enregistrer(GuardianObservationPolicy demandee) async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(portPolitiqueObservationProvider)
          .definirPolitiqueGroupe(
            groupeId: widget.groupeId,
            politique: demandee,
          );
      // Relire plutot que croire l'apercu : la RPC borne le plafond par visite
      // au temps total et rend la politique reellement ecrite.
      ref.invalidate(politiqueObservationProvider(widget.groupeId));
      widget.onEnregistre();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on EchecObservation catch (echec) {
      // **Le motif exact, pas le motif generique du tuteur.**
      // `t.tc.observation.refus.capaciteAbsente` (« L'observation n'est pas
      // encore activee sur cette installation. ») est ecrit pour un tuteur a
      // qui la salle se refuse ; servi a un administrateur, il est faux : la
      // base porte bien les quatre fonctions d'observation de `0033`
      // (verifie en production le 21/09/2026, `0033_tc_vues_rpc` est la
      // derniere migration appliquee). Ce qui manque est la seule migration
      // `0036`, qui ajoute le cinquieme argument `p_max_secondes_par_visite` :
      // PostgREST resout par NOM d'argument, l'appel a cinq revient donc en
      // `PGRST202` contre la fonction a quatre arguments encore en place
      // (`pg_get_function_identity_arguments` rejoue le 21/09 : `p_groupe_id
      // uuid, p_source text, p_max_visites smallint, p_max_secondes integer`).
      // Un administrateur a qui l'on dit « l'observation n'est pas activee »
      // ira la chercher dans Configuration et ne la trouvera jamais.
      if (mounted) {
        setState(
          () => _erreur = echec.motif == MotifEchecObservation.capaciteAbsente
              ? t.admin.groupes.observationCapaciteAbsente
              : t.admin.groupes.observationErreur,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _envoi = false);
      }
    }
  }
}
