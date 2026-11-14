/// SALLE2-ENTRETIEN (directeur, 14/11/2026) : l'entretien du candidat, en
/// tete de son ecran. « Le lien de l'entretien cote candidat est trop discret
/// et muet, il peut manquer son entretien. »
///
/// - Plus d'une heure avant : la date, et « Voir mon entretien ».
/// - Dans l'heure (`proche`) : « Votre entretien commence dans 25 minutes »,
///   lumiere orange (a preparer).
/// - Salle ouverte, puis entretien commence : lumiere verte (la salle) et
///   « Rejoindre l'entretien », la meme seance que celle de la direction.
///
/// La lumiere est celle des accueils (LUMIERE-ACCUEILS, `LumiereAutour` sur
/// `HaloLumiere`) : aucune copie. L'etat vient du serveur (`mon_entretien`,
/// etat et heure du serveur) ; entre deux lectures, l'horloge le fait
/// seulement avancer. Chaque changement d'entretien arrive par le signal
/// temps reel (`veilleEntretiensProvider`).
///
/// Rien n'est montre sans entretien, ni pendant la lecture, ni en erreur : la
/// page qui l'accueille a deja ses propres etats.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/candidature/entretien_candidat.dart';
import '../../core/candidature/entretiens_temps_reel.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/billet_salle.dart';
import '../../core/router/routes.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/halo_lumiere.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/lumiere_autour.dart';
import 'entretien_creneaux.dart' show horaireEntretien;

/// L'horloge de la carte (surchargee par les tests).
final Provider<DateTime Function()> horlogeCarteEntretienProvider =
    Provider<DateTime Function()>((Ref _) => DateTime.now);

/// La carte de l'entretien, en tete de l'ecran du candidat.
class CarteEntretienProche extends ConsumerStatefulWidget {
  /// Cree la carte. [lienVersPage] : montrer « Voir mon entretien » (faux sur
  /// la page de l'entretien elle-meme).
  const CarteEntretienProche({this.lienVersPage = true, super.key});

  /// Montrer le lien vers la page de l'entretien.
  final bool lienVersPage;

  /// La carte.
  static const Key carteKey = ValueKey<String>('carte-entretien-proche');

  /// « Rejoindre l'entretien ».
  static const Key rejoindreKey = ValueKey<String>('carte-entretien-rejoindre');

  @override
  ConsumerState<CarteEntretienProche> createState() => _EtatCarte();
}

class _EtatCarte extends ConsumerState<CarteEntretienProche> {
  Timer? _tic;

  @override
  void initState() {
    super.initState();
    // Le decompte et le passage a « Rejoindre » sans recharger.
    _tic = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tic?.cancel();
    super.dispose();
  }

  void _rejoindre(String seanceId) => GoRouter.of(context).go(
    Routes.salle,
    // Le billet passe par `extra`, jamais par l'URL (ADR-005).
    extra: BilletSalle(sessionId: seanceId, emisA: DateTime.now()),
  );

  @override
  Widget build(BuildContext context) {
    ref
      ..watch(veilleEntretiensProvider)
      ..watch(monHorlogeProvider);
    final MonEntretien? entretien = ref.watch(monEntretienProvider).value;
    if (entretien == null) return const SizedBox.shrink();
    final DateTime maintenant = ref.watch(horlogeCarteEntretienProvider)();
    final EtatEntretien etat = entretien.etatA(maintenant);
    if (etat == EtatEntretien.termine) return const SizedBox.shrink();

    final e = t.recrutement.entretien;
    final TextTheme textes = Theme.of(context).textTheme;
    final bool salleOuverte =
        etat == EtatEntretien.ouvert || etat == EtatEntretien.enCours;
    final int minutes = entretien.minutesAvant(maintenant);
    final String phrase = switch (etat) {
      EtatEntretien.enCours => e.aCommence,
      EtatEntretien.ouvert ||
      EtatEntretien.proche => e.commenceDans(n: minutes),
      _ => e.prevu(horaire: horaireEntretien(entretien.debut, entretien.fin)),
    };
    final NatureHalo? lumiere = salleOuverte
        ? NatureHalo.salle
        : etat == EtatEntretien.proche
        ? NatureHalo.aPreparer
        : null;

    // La marge basse est dans la carte : absente, elle ne laisse aucun vide.
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: LumiereAutour(
        nature: lumiere,
        apparition: etat,
        child: AppCard(
          key: CarteEntretienProche.carteKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(e.votreEntretien, style: textes.titleMedium),
              ),
              Ecart.vSm,
              Semantics(
                liveRegion: true,
                child: Text(phrase, style: textes.bodyLarge),
              ),
              if (salleOuverte) ...<Widget>[
                Ecart.vLg,
                ActionPrincipale(
                  key: CarteEntretienProche.rejoindreKey,
                  libelle: e.rejoindre,
                  onPress: () => _rejoindre(entretien.seanceId),
                ),
              ] else ...<Widget>[
                if (etat == EtatEntretien.proche) ...<Widget>[
                  Ecart.vXs,
                  Text(
                    e.ouvreA(
                      heure: heureChezMoi(
                        entretien.ouvertureLe ??
                            entretien.debut.subtract(
                              const Duration(minutes: 10),
                            ),
                      ),
                    ),
                    style: textes.bodyMedium,
                  ),
                ],
                if (widget.lienVersPage) ...<Widget>[
                  Ecart.vSm,
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: LienFleche(
                      libelle: e.portailVoir,
                      alignerEnDebut: true,
                      onPress: () =>
                          GoRouter.of(context).go(Routes.attenteEntretien),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
