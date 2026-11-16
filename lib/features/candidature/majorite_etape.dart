/// La question d'age du recrutement : « J'ai 18 ans ou plus. » (directeur,
/// 16/11/2026, MAJEUR) : « S'il a plus de 18 ans, il peut continuer ; sinon, il
/// ne peut pas continuer. Pour ceux qui sont deja avances et acceptes, il faut le
/// leur ramener dans leur page, la ou ils sont ; ils vont devoir le cocher. »
///
/// Deux usages, une seule logique (`attesterMajorite` du port, rien ne se calcule
/// ici) :
///
/// * [PorteMajorite] : en salle 1, avant les questions. Sans la case cochee, le
///   bouton « Continuer » n'est pas rendu et une phrase dit pourquoi (K-56). Le
///   lien « J'ai moins de 18 ans » demande confirmation (l'effet se dit avant :
///   candidature en pause, rien n'est supprime), puis une phrase bienveillante dit
///   que le recrutement est reserve aux personnes de 18 ans et plus.
/// * [CarteMajorite] : en tete de la page de ceux qui sont deja avances (salle 2,
///   salle 3, confirmes), la meme case, la ou ils sont. La cocher l'enregistre.
///
/// Un serveur d'avant ce lot ne rend pas la question (`majorite.servie` faux) :
/// rien ne se demande, jamais un candidat bloque par une question que le serveur
/// ne pose pas.
///
/// Etats : chargement (le temps de l'envoi), contenu, echec (la reponse n'est pas
/// confirmee, K-59 : quoi faire), declaration deja faite, hors ligne (l'envoi
/// echoue en « non confirmee »).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/modeles_candidature.dart';
import '../../core/candidature/port_ma_candidature.dart';
import '../../core/dossier/service_dossier.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/page_shell.dart';
import '../consentements/texte_observation.dart' show CaseAccordTexte;

/// Les cles des tests.
abstract final class MajoriteCles {
  /// La case « J'ai 18 ans ou plus. » de l'ecran de la salle 1.
  static const Key caseEcran = ValueKey<String>('majorite-case');

  /// Le bouton « Continuer » de l'ecran de la salle 1.
  static const Key continuer = ValueKey<String>('majorite-continuer');

  /// Le lien « J'ai moins de 18 ans ».
  static const Key lienMoins18 = ValueKey<String>('majorite-moins-18');

  /// La phrase qui dit pourquoi « Continuer » n'est pas rendu.
  static const Key pourquoi = ValueKey<String>('majorite-pourquoi');

  /// La phrase d'echec ou de declaration deja faite.
  static const Key message = ValueKey<String>('majorite-message');

  /// La page bienveillante apres « moins de 18 ans ».
  static const Key merci = ValueKey<String>('majorite-merci');

  /// La carte de la page des candidats avances.
  static const Key carte = ValueKey<String>('majorite-carte');

  /// La case de la carte.
  static const Key caseCarte = ValueKey<String>('majorite-carte-case');
}

/// Le seul bouton plein de ces ecrans (K-56) : « Continuer ».
Widget _pleine({
  required VoidCallback? onPress,
  Key? cle,
  bool enCours = false,
}) => ActionPrincipale(
  key: cle,
  libelle: t.commun.continuer,
  enCours: enCours,
  onPress: onPress,
);

/// Fait la declaration par le port et dit ce qui s'est passe : `null` si elle est
/// enregistree, sinon la phrase a montrer.
Future<String?> _declarer(
  WidgetRef ref, {
  required bool majeur,
  required void Function() surDejaFaite,
}) async {
  final PortMaCandidature? port = ref.read(portMaCandidatureProvider);
  if (port == null) {
    return t.recrutement.majeur.echec;
  }
  try {
    await port.attesterMajorite(majeur: majeur);
    return null;
  } on DeclarationDejaFaite {
    surDejaFaite();
    return t.recrutement.majeur.dejaFaite;
  } on Object {
    // D5 : ce qui a ete envoye est non confirme, jamais « echec » sec.
    return t.recrutement.majeur.echec;
  }
}

/// Pose la question d'age avant [enfant] tant que le serveur la demande.
class PorteMajorite extends StatelessWidget {
  /// Cree la porte.
  const PorteMajorite({
    required this.candidature,
    required this.enfant,
    super.key,
  });

  /// La candidature lue (`etat_dossier().candidature`).
  final CandidatureDossier candidature;

  /// Ce qui s'ouvre une fois la question repondue, ou quand elle ne se pose pas.
  final Widget enfant;

  @override
  Widget build(BuildContext context) =>
      candidature.majorite.aAttester ? const MajoriteEtape() : enfant;
}

/// L'ecran de la question d'age, en tete du parcours de la salle 1.
class MajoriteEtape extends ConsumerStatefulWidget {
  /// Cree l'ecran.
  const MajoriteEtape({super.key});

  @override
  ConsumerState<MajoriteEtape> createState() => _MajoriteEtapeState();
}

class _MajoriteEtapeState extends ConsumerState<MajoriteEtape> {
  bool _cochee = false;
  bool _enCours = false;
  bool _moins18 = false;
  String? _message;

  Future<void> _continuer() async {
    if (_enCours || !_cochee) {
      return;
    }
    setState(() {
      _enCours = true;
      _message = null;
    });
    final String? echec = await _declarer(
      ref,
      majeur: true,
      surDejaFaite: () => ref.invalidate(etatDossierProvider),
    );
    if (!mounted) {
      return;
    }
    if (echec == null) {
      // L'etat relu leve la porte : le parcours s'ouvre.
      ref.invalidate(etatDossierProvider);
      return;
    }
    setState(() {
      _enCours = false;
      _message = echec;
    });
  }

  Future<void> _moinsDe18() async {
    if (_enCours) {
      return;
    }
    final r = t.recrutement.majeur.confirmer;
    final bool confirme = await ConfirmDestructive.demander(
      context,
      question: r.titre,
      consequence: r.explication,
      libelleConfirmer: r.action,
      libelleAnnuler: r.retour,
    );
    if (!confirme || !mounted) {
      return;
    }
    setState(() {
      _enCours = true;
      _message = null;
    });
    final String? echec = await _declarer(
      ref,
      majeur: false,
      surDejaFaite: () => ref.invalidate(etatDossierProvider),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _enCours = false;
      if (echec == null) {
        _moins18 = true;
      } else {
        _message = echec;
      }
    });
  }

  void _versLeDossier() {
    ref.invalidate(etatDossierProvider);
    GoRouter.of(context).go(Routes.attente);
  }

  @override
  Widget build(BuildContext context) {
    final r = t.recrutement.majeur;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    if (_moins18) {
      return PageShell(
        titre: r.moins18.titre,
        actions: _pleine(onPress: _versLeDossier),
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppPage.largeurReglages,
            ),
            child: TexteSansCoupure(
              r.moins18.texte,
              key: MajoriteCles.merci,
              style: textes.bodyLarge,
            ),
          ),
        ),
      );
    }
    return PageShell(
      titre: r.titre,
      onRetour: () => GoRouter.of(context).go(Routes.attente),
      actions: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (_message != null) ...<Widget>[
            Semantics(
              liveRegion: true,
              child: Text(
                _message!,
                key: MajoriteCles.message,
                textAlign: TextAlign.center,
                style: palette.inkAlert.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vMd,
          ],
          // K-56 : un bouton qui ne peut pas aboutir n'est pas rendu ; une phrase
          // dit ce qui manque.
          if (_cochee)
            _pleine(
              cle: MajoriteCles.continuer,
              enCours: _enCours,
              onPress: _enCours ? null : () => unawaited(_continuer()),
            )
          else
            Text(
              r.pourquoiBloque,
              key: MajoriteCles.pourquoi,
              textAlign: TextAlign.center,
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          Ecart.vXs,
          Center(
            child: ActionPrincipale(
              key: MajoriteCles.lienMoins18,
              libelle: r.lienMoins18,
              niveau: NiveauAction.tertiaire,
              pleineLargeur: false,
              onPress: _enCours ? null : () => unawaited(_moinsDe18()),
            ),
          ),
        ],
      ),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TexteSansCoupure(
                r.explication,
                style: palette.inkMuted.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
              Ecart.vXl,
              CaseAccordTexte(
                key: MajoriteCles.caseEcran,
                libelle: r.coche,
                cochee: _cochee,
                onChanged: _enCours
                    ? null
                    : (bool v) => setState(() {
                        _cochee = v;
                        _message = null;
                      }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La carte d'age, en tete de la page d'un candidat deja avance : la meme case,
/// la ou il est. Rien n'est rendu quand le serveur ne pose pas la question, ni
/// une fois l'age atteste.
class CarteMajorite extends ConsumerStatefulWidget {
  /// Cree la carte.
  const CarteMajorite({required this.candidature, super.key});

  /// La candidature lue.
  final CandidatureDossier candidature;

  @override
  ConsumerState<CarteMajorite> createState() => _CarteMajoriteState();
}

class _CarteMajoriteState extends ConsumerState<CarteMajorite> {
  bool _cochee = false;
  bool _enCours = false;
  String? _message;

  Future<void> _cocher(bool v) async {
    if (_enCours || !v) {
      return;
    }
    setState(() {
      _cochee = true;
      _enCours = true;
      _message = null;
    });
    final String? echec = await _declarer(
      ref,
      majeur: true,
      surDejaFaite: () => ref.invalidate(etatDossierProvider),
    );
    if (!mounted) {
      return;
    }
    if (echec == null) {
      ref.invalidate(etatDossierProvider);
      return;
    }
    setState(() {
      _cochee = false;
      _enCours = false;
      _message = echec;
    });
  }

  Future<void> _moinsDe18() async {
    if (_enCours) {
      return;
    }
    final r = t.recrutement.majeur.confirmer;
    final bool confirme = await ConfirmDestructive.demander(
      context,
      question: r.titre,
      consequence: r.explication,
      libelleConfirmer: r.action,
      libelleAnnuler: r.retour,
    );
    if (!confirme || !mounted) {
      return;
    }
    setState(() {
      _enCours = true;
      _message = null;
    });
    final String? echec = await _declarer(
      ref,
      majeur: false,
      surDejaFaite: () => ref.invalidate(etatDossierProvider),
    );
    if (!mounted) {
      return;
    }
    if (echec == null) {
      ref.invalidate(etatDossierProvider);
      return;
    }
    setState(() {
      _enCours = false;
      _message = echec;
    });
  }

  @override
  Widget build(BuildContext context) {
    final MajoriteCandidature m = widget.candidature.majorite;
    if (!widget.candidature.existe ||
        widget.candidature.issue != IssueCandidature.enCours ||
        (!m.aAttester && !m.moinsDe18)) {
      return const SizedBox.shrink();
    }
    final r = t.recrutement.majeur;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    if (m.moinsDe18) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          key: MajoriteCles.carte,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(r.moins18.titre, style: textes.titleMedium),
            Ecart.vSm,
            TexteSansCoupure(r.moins18.texte, style: textes.bodyMedium),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        key: MajoriteCles.carte,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(r.portail.titre, style: textes.titleMedium),
          Ecart.vSm,
          TexteSansCoupure(
            r.portail.explication,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vMd,
          CaseAccordTexte(
            key: MajoriteCles.caseCarte,
            libelle: r.coche,
            cochee: _cochee,
            onChanged: _enCours ? null : (bool v) => unawaited(_cocher(v)),
          ),
          if (_message != null) ...<Widget>[
            Ecart.vSm,
            Semantics(
              liveRegion: true,
              child: Text(
                _message!,
                key: MajoriteCles.message,
                style: palette.inkAlert.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
          ],
          Ecart.vXs,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ActionPrincipale(
              key: MajoriteCles.lienMoins18,
              libelle: r.lienMoins18,
              niveau: NiveauAction.tertiaire,
              pleineLargeur: false,
              onPress: _enCours ? null : () => unawaited(_moinsDe18()),
            ),
          ),
        ],
      ),
    );
  }
}
