// CAND-PHOTO (06/11/2026, demande du directeur) : l'accord de publication,
// separe de la candidature et facultatif. « Votre nom, votre photo et votre
// pays peuvent apparaitre sur le site public de Rewayah Academy. » La case se
// coche, puis le nom du compte vaut signature : le serveur enregistre l'accord
// avec la date et la version du texte. Il se retire plus tard, depuis le
// Profil de l'enseignant, apres une confirmation qui dit l'effet.
//
// La carte du Profil de l'enseignant (l'accord se donne d'abord, requis, au
// recapitulatif de la candidature). Etats : chargement, accord donne (signe), pas d'accord (case),
// envoi en cours, refus ou panne (phrase et « Reessayer »), hors ligne (rien
// n'est envoye), indisponible (rien n'est rendu).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/signaler_manque.dart';
import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/port_accord_publication.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/skeleton.dart';
import '../consentements/texte_observation.dart' show CaseAccordTexte;

/// La carte de l'accord de publication.
class CarteAccordPublication extends ConsumerStatefulWidget {
  /// Cree la carte. [retirable] : le lien « Retirer mon accord » est offert
  /// (Profil de l'enseignant) ; au recapitulatif, la case seule.
  const CarteAccordPublication({super.key, this.retirable = false});

  /// Vrai quand le retrait est offert ici.
  final bool retirable;

  /// La case.
  static const Key caseKey = ValueKey<String>('accord-publication-case');

  /// La ligne de signature.
  static const Key signatureKey = ValueKey<String>(
    'accord-publication-signature',
  );

  /// Le bouton « Donner mon accord ».
  static const Key donnerKey = ValueKey<String>('accord-publication-donner');

  /// Le lien de retrait.
  static const Key retirerKey = ValueKey<String>('accord-publication-retirer');

  @override
  ConsumerState<CarteAccordPublication> createState() =>
      _CarteAccordPublicationState();
}

class _CarteAccordPublicationState
    extends ConsumerState<CarteAccordPublication> {
  bool _envoi = false;
  String? _erreur;

  /// La case, cochee localement : rien ne part avant le bouton (UX-047).
  bool _coche = false;

  /// La case manque : signalee sous elle-meme, en rouge, jusqu'a ce qu'elle
  /// soit cochee.
  bool _manque = false;

  /// Hors ligne, au bouton : la phrase dite, rien n'est envoye.
  bool _horsLigneDit = false;

  final FocusNode _focusCase = FocusNode();

  @override
  void dispose() {
    _focusCase.dispose();
    super.dispose();
  }

  /// Le bouton, jamais grise (K-56) : sans case, il la signale ; hors ligne,
  /// il le dit et n'envoie rien ; sinon l'accord part a la [version].
  void _donner(String version, {required bool horsLigne}) {
    if (!_coche) {
      setState(() {
        _manque = true;
        _horsLigneDit = false;
      });
      signalerManque(context, t.accords.caseManquante, champ: _focusCase);
      return;
    }
    if (horsLigne) {
      setState(() => _horsLigneDit = true);
      return;
    }
    setState(() => _horsLigneDit = false);
    unawaited(_agir((PortAccordPublication p) => p.accepter(version)));
  }

  Future<void> _agir(
    Future<AccordPublication> Function(PortAccordPublication) geste,
  ) async {
    final PortAccordPublication? port = ref.read(portAccordPublicationProvider);
    if (port == null || _envoi) return;
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await geste(port);
      ref.invalidate(accordPublicationProvider);
    } on Object {
      if (mounted) setState(() => _erreur = t.candidatsFlux.publication.echec);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _retirer() async {
    final r = t.candidatsFlux.publication;
    final bool oui = await ConfirmDestructive.demander(
      context,
      question: r.retirerQuestion,
      consequence: r.retirerConsequence,
      libelleConfirmer: r.retirer,
    );
    if (!oui || !mounted) return;
    await _agir((PortAccordPublication p) => p.retirer());
  }

  @override
  Widget build(BuildContext context) {
    final r = t.candidatsFlux.publication;
    final AsyncValue<AccordPublication> lecture = ref.watch(
      accordPublicationProvider,
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );

    // Capacite absente (lot serveur non verse) : la carte n'est pas rendue.
    if (lecture.hasError && lecture.error is CapaciteIndisponible) {
      return const SizedBox.shrink();
    }
    final AccordPublication? accord = lecture.value;
    final String? version = accord?.versionCourante;

    final List<Widget> corps = <Widget>[
      Text(r.titre, style: textes.titleMedium),
      Ecart.vSm,
      TexteSansCoupure(r.texte, style: attenue),
      Ecart.vMd,
    ];
    if (accord == null) {
      if (lecture.hasError) {
        corps.addAll(<Widget>[
          Text(
            r.lectureEchec,
            style: palette.inkAlert.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          LienFleche(
            libelle: t.commun.reessayer,
            alignerEnDebut: true,
            onPress: () => ref.invalidate(accordPublicationProvider),
          ),
        ]);
      } else {
        corps.add(const Skeleton.texte(lignes: 1));
      }
    } else if (accord.enCours) {
      corps.add(
        TexteSansCoupure(
          r.signe(
            nom: accord.nomSigne ?? '',
            date: accord.accepteLe == null
                ? ''
                : MaterialLocalizations.of(context)
                      .formatMediumDate(accord.accepteLe!),
          ),
          key: CarteAccordPublication.signatureKey,
          style: textes.bodyMedium,
        ),
      );
      if (widget.retirable && !horsLigne) {
        corps.addAll(<Widget>[
          Ecart.vSm,
          LienFleche(
            key: CarteAccordPublication.retirerKey,
            libelle: r.retirer,
            alignerEnDebut: true,
            onPress: _envoi ? null : () => unawaited(_retirer()),
          ),
        ]);
      }
    } else if (version == null) {
      corps.add(Text(r.nonPublie, style: attenue));
    } else {
      // Le modele du recapitulatif de candidature (UX-047) : la case se
      // coche sans rien envoyer ; l'accord part au seul bouton.
      corps.addAll(<Widget>[
        CaseAccordTexte(
          key: CarteAccordPublication.caseKey,
          libelle: r.kCase,
          cochee: _coche,
          focusNode: _focusCase,
          erreur: _manque ? t.accords.caseManquante : null,
          onChanged: _envoi
              ? null
              : (bool v) => setState(() {
                  _coche = v;
                  if (v) _manque = false;
                }),
        ),
        Ecart.vLg,
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: ActionPrincipale(
            key: CarteAccordPublication.donnerKey,
            libelle: r.donner,
            enCours: _envoi,
            affirmee: true,
            onPress: () => _donner(version, horsLigne: horsLigne),
          ),
        ),
      ]);
      if (_horsLigneDit && horsLigne) {
        corps.addAll(<Widget>[
          Ecart.vSm,
          Semantics(liveRegion: true, child: Text(r.horsLigne, style: attenue)),
        ]);
      }
    }
    if (_erreur != null) {
      corps.addAll(<Widget>[
        Ecart.vSm,
        Semantics(
          liveRegion: true,
          child: Text(
            _erreur!,
            style: palette.inkAlert.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ),
      ]);
    }
    return AppCard(
      key: const ValueKey<String>('accord-publication'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: corps,
      ),
    );
  }
}
