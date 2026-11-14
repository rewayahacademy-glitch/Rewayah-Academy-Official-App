/// SALLE2-ENTRETIEN (directeur, 14/11/2026) : « L'interviewer ne sait pas
/// comment entrer dans la salle d'entretien pour retrouver le candidat. »
///
/// Les entretiens de la journee de la personne connectee, en tete de la file
/// des candidatures (direction) et de sa journee (enseignant qui mene un
/// entretien). Chaque ligne : le candidat, l'horaire, et des 10 minutes avant
/// le debut « Rejoindre l'entretien avec [nom] », qui ouvre la meme seance que
/// celle du candidat (`/salle`). Avant : l'heure d'ouverture, dite.
///
/// Lecture : `mes_entretiens()` ; relue a chaque signal temps reel. Rien a
/// montrer (aucun entretien, lecture en cours ou en echec) : rien n'est rendu,
/// l'ecran hote garde ses propres etats.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/candidature/entretiens_temps_reel.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/billet_salle.dart';
import '../../core/router/routes.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/carte_groupee.dart' show FiletCarte;
import '../../core/widgets/halo_lumiere.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/lumiere_autour.dart';
import '../candidature/entretien_creneaux.dart' show horaireEntretien;

/// L'horloge (surchargee par les tests).
final Provider<DateTime Function()> horlogeEntretiensDuJourProvider =
    Provider<DateTime Function()>((Ref _) => DateTime.now);

/// La carte « Entretiens du jour ».
class EntretiensDuJour extends ConsumerStatefulWidget {
  /// Cree la carte. [ficheOuverte] : montrer le lien vers la fiche de la
  /// candidature (la direction seulement).
  const EntretiensDuJour({this.ficheOuverte = false, super.key});

  /// Montrer « Voir la candidature de ... ».
  final bool ficheOuverte;

  /// La carte.
  static const Key carteKey = ValueKey<String>('entretiens-du-jour');

  @override
  ConsumerState<EntretiensDuJour> createState() => _EtatEntretiensDuJour();
}

class _EtatEntretiensDuJour extends ConsumerState<EntretiensDuJour> {
  Timer? _tic;

  @override
  void initState() {
    super.initState();
    // Le bouton apparait a l'heure, sans recharger.
    _tic = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tic?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..watch(veilleEntretiensProvider)
      ..watch(monHorlogeProvider);
    final List<EntretienDuJour> liste =
        ref.watch(entretiensDuJourProvider).value ?? const <EntretienDuJour>[];
    final DateTime maintenant = ref.watch(horlogeEntretiensDuJourProvider)();
    final List<EntretienDuJour> lignes = <EntretienDuJour>[
      for (final EntretienDuJour x in liste)
        if (x.duJourA(maintenant) && (x.jeParticipe || widget.ficheOuverte)) x,
    ];
    if (lignes.isEmpty) return const SizedBox.shrink();

    final j = t.recrutement.entretien.jour;
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle muet = AppPalette.of(context).inkMuted
        .applyTo(textes.bodyMedium ?? const TextStyle());
    final bool unOuvert = lignes.any(
      (EntretienDuJour x) => x.rejoignableA(maintenant),
    );

    // La marge basse est dans la carte : absente, elle ne laisse aucun vide.
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: LumiereAutour(
        nature: unOuvert ? NatureHalo.salle : null,
        apparition: unOuvert,
        child: AppCard(
          key: EntretiensDuJour.carteKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(j.titre, style: textes.titleMedium),
              ),
              Ecart.vXs,
              Text(j.intro, style: muet),
              for (int i = 0; i < lignes.length; i++) ...<Widget>[
                if (i > 0) const FiletCarte(),
                Ecart.vMd,
                _Ligne(
                  entretien: lignes[i],
                  maintenant: maintenant,
                  ficheOuverte: widget.ficheOuverte,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne({
    required this.entretien,
    required this.maintenant,
    required this.ficheOuverte,
  });

  final EntretienDuJour entretien;
  final DateTime maintenant;
  final bool ficheOuverte;

  @override
  Widget build(BuildContext context) {
    final j = t.recrutement.entretien.jour;
    final TextTheme textes = Theme.of(context).textTheme;
    final String nom = entretien.nom.isEmpty ? j.candidat : entretien.nom;
    final bool ouvert = entretien.rejoignableA(maintenant);
    return Column(
      key: ValueKey<String>('entretien-du-jour-${entretien.sessionId}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(nom, style: textes.titleSmall),
        Ecart.vXs,
        Text(
          horaireEntretien(entretien.debut, entretien.fin),
          style: textes.bodyMedium,
        ),
        if (ouvert) ...<Widget>[
          Ecart.vMd,
          ActionPrincipale(
            key: ValueKey<String>(
              'entretien-du-jour-rejoindre-${entretien.sessionId}',
            ),
            libelle: j.rejoindreAvec(nom: nom),
            niveau: NiveauAction.secondaire,
            onPress: () => GoRouter.of(context).go(
              Routes.salle,
              // Le billet passe par `extra`, jamais par l'URL (ADR-005).
              extra: BilletSalle(
                sessionId: entretien.sessionId,
                emisA: DateTime.now(),
              ),
            ),
          ),
        ] else if (entretien.jeParticipe) ...<Widget>[
          Ecart.vXs,
          Semantics(
            liveRegion: true,
            child: Text(
              j.ouvreA(
                heure: heureChezMoi(
                  entretien.debut.subtract(const Duration(minutes: 10)),
                ),
              ),
              style: textes.bodyMedium,
            ),
          ),
        ],
        if (ficheOuverte && entretien.reference.isNotEmpty) ...<Widget>[
          Ecart.vXs,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: LienFleche(
              libelle: j.voirFiche(nom: nom),
              alignerEnDebut: true,
              onPress: () => GoRouter.of(
                context,
              ).go(Routes.adminPersonnesCandidaturePour(entretien.reference)),
            ),
          ),
        ],
      ],
    );
  }
}
