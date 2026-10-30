import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../domain/enums.dart';
import '../dossier/etat_dossier.dart';
import '../dossier/service_dossier.dart';
import 'session_controleur.dart';
import 'session_state.dart';

/// L'usage choisi a l'inscription par le titulaire [profil] (« Moi » ou
/// « Famille »), tel que le serveur le garde (`etat_dossier().usage`) ; `null`
/// s'il ne le dit pas. Une lecture par compte.
final FutureProviderFamily<UsageTitulaire?, String> usageTitulaireProvider =
    FutureProvider.family<UsageTitulaire?, String>(
      (Ref ref, String _) async =>
          (await ref.watch(serviceDossierProvider).etat()).usage,
    );

/// Vrai quand le compte doit atterrir sur l'accueil de l'eleve adulte plutot
/// que sur celui du tuteur (admission, lot B, 29/10/2026 : une eleve adulte
/// inscrite « pour moi » arrivait sur l'accueil du tuteur et a du ajouter un
/// profil eleve) : un titulaire, eleve autonome (capacite servie), inscrit
/// « Je m'inscris pour moi ». Un parent qui suit aussi des cours garde
/// l'accueil du tuteur : il a des enfants a suivre.
final Provider<bool> atterrissageAdulteProvider = Provider<bool>((Ref ref) {
  final SessionState session = ref.watch(sessionProvider);
  final String? profil = session.profileId;
  if (session.role != AppRole.guardian ||
      !session.eleveAutonome ||
      profil == null) {
    return false;
  }
  return ref.watch(usageTitulaireProvider(profil)).value == UsageTitulaire.moi;
});
