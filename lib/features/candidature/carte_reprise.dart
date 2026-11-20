// PE-A6 (directeur, 19/11/2026) : la carte d'une candidature retiree, avec
// « Reprendre ma candidature » pendant 7 jours. Posee par l'onglet Dossier
// (`onglet_dossier.dart`), dans son propre fichier : l'ecran n'a qu'un bouton
// plein a la fois (« a faire maintenant » OU « reprendre », jamais les deux).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/candidature/modeles_candidature.dart';
import '../../core/candidature/port_ma_candidature.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/dossier/service_dossier.dart';
import '../../core/fraicheur/avis_ephemere.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/skeleton.dart';
import 'reprise_candidature.dart';

/// PE-A6 : la candidature retiree. Pendant 7 jours, le candidat la reprend
/// lui-meme ; sinon l'ecran dit pourquoi seule l'academie la rouvre. Ce que
/// la carte dit vient du serveur (`etat_dossier().candidature.reprise`) ;
/// sans cette lecture, elle garde la phrase d'avant et ne propose rien.
class CarteReprise extends ConsumerStatefulWidget {
  /// Cree la carte.
  const CarteReprise({required this.candidature, super.key});

  /// La candidature retiree.
  final CandidatureDossier candidature;

  /// La cle du bouton « Reprendre ma candidature ».
  static const Key cleBouton = ValueKey<String>('reprise-bouton');

  /// La cle de la phrase de la carte.
  static const Key clePhrase = ValueKey<String>('reprise-phrase');

  /// La cle du message d'echec.
  static const Key cleMessage = ValueKey<String>('reprise-message');

  /// La cle de la note hors ligne.
  static const Key cleHorsLigne = ValueKey<String>('reprise-hors-ligne');

  @override
  ConsumerState<CarteReprise> createState() => _EtatCarteReprise();
}

class _EtatCarteReprise extends ConsumerState<CarteReprise> {
  bool _enCours = false;
  String? _message;
  String? _cle;

  Future<void> _reprendre() async {
    final r = t.recrutement.accueil.reprise;
    setState(() {
      _enCours = true;
      _message = null;
    });
    // Une cle par geste, rejouee tant que l'issue est incertaine.
    final String cle = _cle ??= nouvelleCleIdempotence();
    try {
      await ref
          .read(portRepriseCandidatureProvider)
          .reprendre(
            versionAttendue: widget.candidature.version,
            cleIdempotence: cle,
          );
      // La reprise ne s'affiche qu'apres la reponse : l'ecran relit l'etat.
      ref
        ..invalidate(etatDossierProvider)
        ..invalidate(repriseCandidatureProvider);
      ref.read(avisEphemereProvider.notifier).dire(r.faite);
      if (mounted) setState(() => _enCours = false);
    } on ConflitCandidature {
      _cle = null;
      ref.invalidate(etatDossierProvider);
      _echec(r.conflit);
    } on RepriseFermee catch (e) {
      _cle = null;
      ref.invalidate(repriseCandidatureProvider);
      _echec(_raison(e.raison));
    } on TransitionInterdite {
      // Elle n'est plus retiree (rouverte entre-temps) : l'etat relu le dit.
      _cle = null;
      ref
        ..invalidate(etatDossierProvider)
        ..invalidate(repriseCandidatureProvider);
      if (mounted) setState(() => _enCours = false);
    } on HorsLigneCandidature {
      _echec(r.incertain);
    } on CapaciteIndisponible {
      _cle = null;
      _echec(r.echec);
    } on PermissionInsuffisante {
      _cle = null;
      _echec(r.echec);
    } on Object {
      _echec(r.incertain);
    }
  }

  void _echec(String message) {
    if (mounted) {
      setState(() {
        _enCours = false;
        _message = message;
      });
    }
  }

  static String _raison(RaisonRepriseFermee raison) {
    final r = t.recrutement.accueil.reprise;
    return switch (raison) {
      RaisonRepriseFermee.delaiDepasse => r.delaiDepasse,
      RaisonRepriseFermee.retraitParLaDirection => r.parDirection,
      RaisonRepriseFermee.controles => r.controles,
      RaisonRepriseFermee.type => t.recrutement.portail.retiree,
    };
  }

  static String _jour(DateTime d) => isolerSens(
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}',
  );

  @override
  Widget build(BuildContext context) {
    final AsyncValue<RepriseCandidature> lue = ref.watch(
      repriseCandidatureProvider,
    );
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final r = t.recrutement.accueil.reprise;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final TextStyle corps = textes.bodyLarge ?? const TextStyle();

    if (!lue.hasValue && !lue.hasError) {
      return const AppCard(child: Skeleton.texte(lignes: 2));
    }
    final RepriseCandidature? reprise = lue.hasValue ? lue.requireValue : null;
    final DateTime? jusquAu = reprise?.repriseJusquAu;
    final bool possible =
        reprise != null &&
        reprise.retiree &&
        reprise.possible &&
        jusquAu != null;
    final String phrase = possible
        ? r.possible(date: _jour(jusquAu))
        : reprise?.raison == null
        // Sans lecture du serveur : la phrase d'avant, qui reste vraie.
        ? t.recrutement.portail.retiree
        : _raison(reprise!.raison!);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(phrase, key: CarteReprise.clePhrase, style: corps),
          if (_message != null) ...<Widget>[
            Ecart.vMd,
            Semantics(
              liveRegion: true,
              child: Text(
                _message!,
                key: CarteReprise.cleMessage,
                style: palette.inkAlert.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
          ],
          if (possible) ...<Widget>[
            Ecart.vLg,
            if (horsLigne)
              // Un bouton qui ne peut pas aboutir n'est pas rendu.
              Text(
                r.horsLigne,
                key: CarteReprise.cleHorsLigne,
                style: palette.inkMuted.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              )
            else
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: ActionPrincipale(
                  key: CarteReprise.cleBouton,
                  libelle: r.bouton,
                  enCours: _enCours,
                  pleineLargeur: false,
                  onPress: _enCours ? null : () => unawaited(_reprendre()),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
