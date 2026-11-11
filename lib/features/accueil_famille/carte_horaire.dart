// ACCUEIL-HORAIRE (PLAN-LOTS rang 22 g, constat du directeur du 05/11/2026,
// capture) : a l'Accueil du tuteur, la carte « Horaire a choisir » de l'enfant
// sans classe menait a « Aucun horaire ouvert ne correspond encore » ; revenu a
// l'Accueil, elle ne disparaissait jamais, et une seconde carte « Aucune classe
// pour ... » disait la meme chose.
//
// Une seule carte pour l'enfant choisi, trois etats :
// - des horaires ouverts lui correspondent : « Horaire a choisir », et « Voir
//   les horaires » ;
// - aucun : elle le dit, et « Me prevenir si de nouveaux horaires ouvrent »
//   agit depuis la carte (aucune impasse) ;
// - le geste fait : « Demande enregistree », sans bouton.
// Elle disparait quand l'enfant a une classe (l'Accueil ne la pose que sans
// classe).
//
// Aucune migration : le geste est `signaler_horaire_insatisfait` (0043), deja
// employe par la page du parcours ; sa trace se relit dans
// `matching_requests` (politique `matching_requests_parties_read`, 0005).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/offres/offre_horaire.dart';
import '../../core/offres/service_offres.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bento_tile.dart';
import '../parcours_offres/libelles_parcours.dart';

/// La sorte d'une demande « aucun horaire ne convient »
/// (`matching_requests.kind`, 0043).
const String sorteHoraireInsatisfait = 'horaire_insatisfait';

/// Lit les apprenants pour qui une demande « me prevenir » attend encore
/// (statut `pending`). Seules les demandes de ce compte ou de son foyer sont
/// lisibles (RLS) ; on ne lit que l'identifiant de l'apprenant, jamais le
/// detail ni le motif.
Future<Set<String>> lireDemandesHoraire(SupabaseClient client) async {
  final List<Map<String, dynamic>> lignes = await client
      .from('matching_requests')
      .select('subject_profile_id')
      .eq('kind', sorteHoraireInsatisfait)
      .eq('status', 'pending');
  return <String>{
    for (final Map<String, dynamic> l in lignes)
      if (l['subject_profile_id'] is String) l['subject_profile_id'] as String,
  };
}

/// Les apprenants du foyer pour qui « Me prevenir si de nouveaux horaires
/// ouvrent » a ete touche. Relue a chaque ouverture de l'Accueil
/// (`autoDispose`) : un geste fait sur la page du parcours s'y voit au retour.
/// Une lecture en echec ne dit rien : la carte garde alors son geste, jamais un
/// etat invente.
final FutureProvider<Set<String>> demandesHoraireProvider =
    FutureProvider.autoDispose<Set<String>>(
      (Ref ref) => lireDemandesHoraire(Supabase.instance.client),
    );

/// L'etat de la carte, fonction pure (testee sans ecran).
enum EtatCarteHoraire {
  /// Des horaires ouverts correspondent (ou ne sont pas encore lus).
  aChoisir,

  /// Aucun horaire ouvert ne correspond, aucune demande faite.
  aucunHoraire,

  /// « Me prevenir » a ete touche.
  demandeEnregistree,
}

/// L'etat de la carte : [offres] nulles tant qu'elles ne sont pas lues ou en
/// echec (on garde alors l'etat d'avant, « Horaire a choisir »).
EtatCarteHoraire etatCarteHoraire({
  required List<OffreHoraire>? offres,
  required bool demandeFaite,
}) {
  if (offres == null || offres.isNotEmpty) {
    return EtatCarteHoraire.aChoisir;
  }
  return demandeFaite
      ? EtatCarteHoraire.demandeEnregistree
      : EtatCarteHoraire.aucunHoraire;
}

/// Le fuseau des horaires de [a], comme la page du parcours le choisit. Une
/// seule definition : la carte et la porte de l'Accueil (qui attend la lecture
/// des offres) doivent construire la meme cle.
String fuseauCarteHoraire(ParcoursApprenant a) =>
    fuseauSuggere(
      fuseauConnu: a.fuseauFoyer,
      decalageAppareil: DateTime.now().timeZoneOffset,
    )?.iana ??
    'Europe/Paris';

/// La cle des offres lues pour la carte de [a] (la meme pour la carte et pour
/// la porte de l'Accueil).
CleOffres cleOffresCarteHoraire(ParcoursApprenant a) =>
    CleOffres(membreId: a.eleveId, fuseau: fuseauCarteHoraire(a));

/// La carte de l'horaire de l'enfant choisi, a l'Accueil du tuteur.
class CarteHoraireAccueil extends ConsumerStatefulWidget {
  /// Cree la carte de [apprenant], dont l'etape est « Horaire a choisir ».
  const CarteHoraireAccueil({required this.apprenant, super.key});

  /// L'apprenant.
  final ParcoursApprenant apprenant;

  @override
  ConsumerState<CarteHoraireAccueil> createState() =>
      _CarteHoraireAccueilState();
}

class _CarteHoraireAccueilState extends ConsumerState<CarteHoraireAccueil> {
  bool _envoi = false;
  bool _envoyee = false;
  bool _erreur = false;

  /// Le fuseau des horaires, comme la page du parcours le choisit.
  String get _fuseau => fuseauCarteHoraire(widget.apprenant);

  Future<void> _prevenir() async {
    setState(() {
      _envoi = true;
      _erreur = false;
    });
    try {
      await ref
          .read(serviceOffresProvider)
          .signalerHoraireInsatisfait(
            membreId: widget.apprenant.eleveId,
            fuseau: _fuseau,
            langueCode: widget.apprenant.langueCode,
            cohorteCode: widget.apprenant.cohorteCode,
          );
      if (mounted) {
        setState(() => _envoyee = true);
        ref.invalidate(demandesHoraireProvider);
      }
    } on Object {
      if (mounted) {
        setState(() => _erreur = true);
      }
    } finally {
      if (mounted) {
        setState(() => _envoi = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final ParcoursApprenant a = widget.apprenant;
    final AsyncValue<List<OffreHoraire>> offres = ref.watch(
      offresCompatiblesProvider(cleOffresCarteHoraire(a)),
    );
    final List<OffreHoraire>? lues = offres.hasValue && !offres.hasError
        ? offres.requireValue
        : null;
    // La demande n'est lue que quand elle peut changer l'etat.
    final AsyncValue<Set<String>>? demandes = lues != null && lues.isEmpty
        ? ref.watch(demandesHoraireProvider)
        : null;
    final bool demandeFaite =
        _envoyee || (demandes?.value?.contains(a.eleveId) ?? false);
    // DEFAUT DU 11/11/2026 : le geste n'est JAMAIS rendu tant que la lecture
    // qui peut le retirer (les offres, puis la demande deja faite) n'est pas
    // arrivee. La porte de l'Accueil l'attend deja (`lecturesCarteHoraire`) ;
    // ceci tient aussi quand la porte s'ouvre au delai maximal.
    final bool lectureArrivee =
        (offres.hasValue || offres.hasError) &&
        (demandes == null || demandes.hasValue || demandes.hasError);
    final EtatCarteHoraire etat = etatCarteHoraire(
      offres: lues,
      demandeFaite: demandeFaite,
    );

    final (String titre, String detail) = switch (etat) {
      EtatCarteHoraire.aChoisir => (
        titreEtape(EtapeParcours.horaireAChoisir),
        detailEtape(
          EtapeParcours.horaireAChoisir,
          prenom: a.prenom,
          minimumLancement: null,
        ),
      ),
      EtatCarteHoraire.aucunHoraire => (
        t.parcours.aucuneOffre,
        t.parcours.aucuneOffreDetail,
      ),
      EtatCarteHoraire.demandeEnregistree => (
        t.accueilHoraire.demandeTitre,
        t.accueilHoraire.demandeDetail(prenom: a.prenom),
      ),
    };

    final (String, VoidCallback?)? action = !lectureArrivee
        ? null
        : switch (etat) {
            EtatCarteHoraire.aChoisir => (
              t.parcours.voirHoraires,
              () => GoRouter.of(context).go(Routes.parcoursPour(a.eleveId)),
            ),
            EtatCarteHoraire.aucunHoraire => (
              t.parcours.refusPrevenir,
              _envoi ? null : () => unawaited(_prevenir()),
            ),
            EtatCarteHoraire.demandeEnregistree => null,
          };

    return BentoTile(
      key: ValueKey<String>('carte-horaire-${etat.name}'),
      // Le contour fort marque ce qui attend un geste de la famille.
      contourFort: etat != EtatCarteHoraire.demandeEnregistree,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(a.prenom, style: textes.bodySmall),
          Ecart.vXs,
          Text(titre, style: textes.titleMedium),
          Ecart.vSm,
          Text(detail, style: textes.bodyMedium),
          if (_erreur) ...<Widget>[
            Ecart.vMd,
            Semantics(
              liveRegion: true,
              child: Text(
                t.accueilHoraire.erreurEnvoi,
                style: palette.inkAlert.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
          ],
          // Un seul bouton (K-56) : voir les horaires, ou etre prevenu ;
          // aucun une fois la demande enregistree.
          if (action != null) ...<Widget>[
            Ecart.vMd,
            // L'action qui fait avancer le parcours de la famille : en aplat
            // (`affirmee`, 22/10 ; UX-046 : la lavande douce se lisait comme
            // eteinte).
            ActionPrincipale(
              libelle: action.$1,
              onPress: action.$2,
              affirmee: true,
            ),
          ] else if (!lectureArrivee) ...<Widget>[
            // Place reservee : ni bouton provisoire, ni saut a l'arrivee.
            Ecart.vMd,
            const SizedBox(height: 48),
          ],
        ],
      ),
    );
  }
}
