import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../observabilite/journal_dev.dart';
import '../router/billet_salle.dart';
import '../router/routes.dart';
import '../tc_classe/port_session_persistante.dart';
import '../tc_classe/session_persistante.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../video/livekit_session_provider.dart';
import '../video/video_session_provider.dart';
import 'bouton_icone.dart';
import 'lien_fleche.dart';
import 'pastille_etat_seance.dart';

/// La barre « Seance toujours en direct » (directeur, 31/10/2026).
///
/// Pendant une seance, l'enseignant (et tout role qui atteint `/salle`) quitte
/// l'ecran de la salle et fait autre chose dans l'application, en continuant
/// d'entendre la classe, comme dans un appel. L'appel est tenu par
/// `controleurSessionProvider` ; cette barre le montre sur **tous les autres
/// ecrans**, au-dessus de la page, et ramene a la salle d'un appui, dans le
/// meme appel (le controleur le tient : ni jeton, ni reconnexion).
///
/// Elle lit des capacites, jamais un role : le micro n'y figure que si le
/// jeton permet de parler (`peutPublier`).
///
/// Etats : chargement et erreur du flux ne montrent rien (on ne pretend pas
/// a une seance qu'on ne connait pas ; l'erreur est journalisee) ; aucune
/// seance, rien ; seance en direct, la pastille ; lien perdu ou retour de
/// veille non reconfirme, la phrase de reconnexion de la salle.
///
/// Elle **compose** [child] : quand elle est visible, elle prend la marge du
/// haut de l'appareil (encoche), et la page dessous ne la reprend pas.
///
/// **La structure ne change jamais**, barre visible ou non : une colonne,
/// une place pour la barre, la page. Basculer entre « la page seule » et
/// « la barre et la page » remonterait le Navigator entier, et la pile de
/// l'application avec. Elle porte aussi son propre `Overlay` : posee
/// au-dessus du Navigator, l'infobulle de son micro n'en aurait aucun.
class BarreSeanceEnDirect extends StatefulWidget {
  /// Cree la barre au-dessus de [child].
  const BarreSeanceEnDirect({
    required this.routeur,
    required this.child,
    super.key,
  });

  /// Le routeur de l'application : la barre se cache sur `/salle`, et y mene.
  final GoRouter routeur;

  /// La page courante.
  final Widget child;

  @override
  State<BarreSeanceEnDirect> createState() => _BarreSeanceEnDirectEtat();
}

class _BarreSeanceEnDirectEtat extends State<BarreSeanceEnDirect> {
  late final OverlayEntry _entree = OverlayEntry(
    builder: (BuildContext _) =>
        _Colonne(routeur: widget.routeur, child: widget.child),
  );

  @override
  void didUpdateWidget(BarreSeanceEnDirect ancien) {
    super.didUpdateWidget(ancien);
    _entree.markNeedsBuild();
  }

  @override
  void dispose() {
    _entree
      ..remove()
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Overlay(initialEntries: <OverlayEntry>[_entree]);
}

class _Colonne extends ConsumerStatefulWidget {
  const _Colonne({required this.routeur, required this.child});

  final GoRouter routeur;
  final Widget child;

  @override
  ConsumerState<_Colonne> createState() => _ColonneEtat();
}

class _ColonneEtat extends ConsumerState<_Colonne> {
  @override
  void initState() {
    super.initState();
    widget.routeur.routerDelegate.addListener(_routeChangee);
  }

  @override
  void didUpdateWidget(_Colonne ancien) {
    super.didUpdateWidget(ancien);
    if (!identical(ancien.routeur, widget.routeur)) {
      ancien.routeur.routerDelegate.removeListener(_routeChangee);
      widget.routeur.routerDelegate.addListener(_routeChangee);
    }
  }

  @override
  void dispose() {
    widget.routeur.routerDelegate.removeListener(_routeChangee);
    super.dispose();
  }

  /// Le routeur notifie aussi pendant le premier rendu du Router, qui est
  /// sous cette barre : la reconstruction attend alors la fin de l'image.
  void _routeChangee() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted) setState(() {});
      });
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final GoRouter routeur = widget.routeur;
    final AsyncValue<EtatSessionPersistante> lecture = ref.watch(
      etatSessionProvider,
    );
    if (lecture.hasError) {
      journalDev('barre de seance : ${lecture.error}');
    }
    final EtatSessionPersistante? etat = lecture.value;
    final SessionEnCours? cours = etat?.cours;
    final bool visible =
        etat != null &&
        cours != null &&
        routeur.routerDelegate.currentConfiguration.uri.path != Routes.salle;
    return Column(
      children: <Widget>[
        if (visible)
          _Barre(
            etat: etat,
            cours: cours,
            onRetour: () => routeur.go(
              Routes.salle,
              // Un billet neuf : celui de l'entree a pu expirer pendant la
              // seance (ADR-005), l'appel, lui, continue.
              extra: BilletSalle(
                sessionId: cours.sessionId,
                emisA: DateTime.now(),
                groupeId: cours.groupeId.isEmpty ? null : cours.groupeId,
                eleveId: cours.eleveId,
                interfaceGuidee: cours.interfaceGuidee,
              ),
            ),
          )
        else
          const SizedBox.shrink(),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: visible,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

class _Barre extends ConsumerWidget {
  const _Barre({
    required this.etat,
    required this.cours,
    required this.onRetour,
  });

  final EtatSessionPersistante etat;
  final SessionEnCours cours;
  final VoidCallback onRetour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final AppColorPair paire = palette.surfaceRaised;
    final bool horsLigne = etat.lienPerdu || etat.retourDeSuspension;
    final bool peutParler = etat.acces?.capacites.peutPublier ?? false;
    final VideoSessionProvider moteur = ref.watch(moteurSalleProvider);
    final TextStyle style = paire.applyTo(
      Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
    );

    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: paire.background,
          border: Border(bottom: palette.borderStrong.asBorderSide()),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: <Widget>[
                if (horsLigne) ...<Widget>[
                  IconTheme(
                    data: IconThemeData(
                      color: paire.onBackground,
                      size: AppSpacing.xl,
                    ),
                    child: Icon(AppIcons.reconnexion.repos),
                  ),
                  Ecart.hSm,
                  Expanded(
                    child: Text(t.salle.secours.reconnexion, style: style),
                  ),
                ] else ...<Widget>[
                  Flexible(
                    child: PastilleEtatSeance(
                      etat: EtatPastilleSeance.enDirect,
                      libelle: t.tc.groupe.temps.prolongee,
                    ),
                  ),
                  const Spacer(),
                ],
                Ecart.hSm,
                Flexible(
                  child: LienFleche(
                    libelle: t.salle.retourner,
                    onPress: onRetour,
                  ),
                ),
                if (peutParler && !horsLigne) ...<Widget>[
                  Ecart.hSm,
                  _MicroDeLaBarre(moteur: moteur),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Couper ou rouvrir son micro sans retourner dans la salle.
class _MicroDeLaBarre extends StatelessWidget {
  const _MicroDeLaBarre({required this.moteur});

  final VideoSessionProvider moteur;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<ParticipantSalle>>(
    stream: moteur.participants,
    builder: (BuildContext context, AsyncSnapshot<List<ParticipantSalle>> s) {
      final List<ParticipantSalle> liste = s.data ?? const <ParticipantSalle>[];
      final bool ouvert = liste.any(
        (ParticipantSalle p) => p.estLocal && p.micro,
      );
      return BoutonIcone(
        icone: ouvert ? AppIcons.micro : AppIcons.microCoupe,
        libelle: ouvert ? t.salle.fermerMicro : t.salle.ouvrirMicro,
        infobulle: ouvert ? t.salle.microOuvert : t.salle.microCoupe,
        selectionne: ouvert,
        onPress: () => unawaited(moteur.reglerMicro(actif: !ouvert)),
      );
    },
  );
}
