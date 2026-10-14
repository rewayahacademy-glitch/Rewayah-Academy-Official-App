import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/appairage/service_appairage.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/chemin_retour.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import 'liste_appareils_eleve.dart';

/// `/tuteur/foyer/:eleveId/appareils` : les appareils d'un profil eleve.
///
/// Composition (manifeste section 2, contenu de l'ancienne capture « Profil »
/// #33, rendu des lignes de Mon compte #6) : titre et phrase « Gerez les
/// appareils autorises pour ... », UN groupe a filets (une ligne par appareil,
/// son action « Retirer »), puis l'action dominante « Connecter un appareil »
/// (emetteur QR du lot), puis deux encarts d'explication. Bureau : la liste et
/// l'action a gauche, les explications a droite.
///
/// Honnetete :
/// - aucune limite codee : le plafond reel est verifie par le serveur a la
///   creation du code, et l'emetteur le dit (DB-APP-04) ;
/// - le retrait se confirme, attend la reponse du service et dit qu'un
///   appareil deja connecte le reste jusqu'a sa deconnexion (DB-APP-03) ;
/// - « Appareil actuel » n'est pas affiche : la vue ne rend pas l'empreinte
///   de l'appareil (C05 3.2 point 15).
///
/// Etats : chargement (squelette), contenu, vide (aucun appareil), erreur
/// (« Reessayer »), hors ligne (sans donnees : etat hors ligne ; avec donnees :
/// retrait masque et phrase), profil introuvable.
class AppareilsElevePage extends ConsumerStatefulWidget {
  /// Cree la page.
  const AppareilsElevePage({required this.eleveId, super.key});

  /// L'eleve concerne. Un identifiant de chemin, jamais une autorisation : la
  /// RLS decide.
  final String eleveId;

  /// La cle de l'action dominante.
  static const Key connecterKey = ValueKey<String>('appareils-eleve-connecter');

  @override
  ConsumerState<AppareilsElevePage> createState() => _AppareilsElevePageState();
}

class _AppareilsElevePageState extends ConsumerState<AppareilsElevePage> {
  String? _retraitEnCours;
  String? _succes;
  String? _echec;

  GoRouter? get _routeur => GoRouter.maybeOf(context);

  Uri? _adresse() {
    try {
      return GoRouterState.of(context).uri;
    } on Object {
      return null;
    }
  }

  /// Le retour : le chemin `retour` valide s'il y en a un (la fiche de
  /// l'eleve, par exemple), sinon les appareils du foyer.
  void _retour() {
    final String? demande = _adresse()?.queryParameters['retour'];
    _routeur?.go(cheminRetourValide(demande) ?? Routes.tuteurFoyerAppareils);
  }

  /// L'emetteur QR du lot, qui revient ici.
  void _connecter() {
    final Uri? ici = _adresse();
    _routeur?.go(
      Uri(
        path: Routes.appairerPour(widget.eleveId),
        queryParameters: ici == null
            ? null
            : <String, String>{'retour': ici.toString()},
      ).toString(),
    );
  }

  Future<void> _retirer(AppareilAppaire appareil, String prenom) async {
    if (_retraitEnCours != null) {
      return;
    }
    final r = t.appareils.retrait;
    final bool confirme = await ConfirmDestructive.demander(
      context,
      question: r.question,
      consequence: r.consequence(
        appareil: libellePlateforme(appareil.plateforme),
        dePrenom: deDevant(prenom),
      ),
      libelleConfirmer: r.confirmer,
    );
    if (!confirme || !mounted) {
      return;
    }
    setState(() {
      _retraitEnCours = appareil.id;
      _succes = null;
      _echec = null;
    });
    try {
      await ref.read(serviceAppairageProvider).revoquer(appareil.id);
      if (!mounted) {
        return;
      }
      // La liste est relue : c'est le serveur qui dit ce qui reste autorise.
      ref.invalidate(appareilsDuFoyerProvider);
      setState(() => _succes = r.reussi);
    } on Object {
      if (!mounted) {
        return;
      }
      final AsyncValue<bool> reseau = ref.read(horsLigneProvider);
      final bool horsLigne = reseau.hasValue && reseau.requireValue;
      setState(() => _echec = horsLigne ? r.horsLigne : r.echec);
    } finally {
      if (mounted) {
        setState(() => _retraitEnCours = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<DonneesAppareilsFoyer> donnees = ref.watch(
      donneesAppareilsFoyerProvider,
    );
    final AsyncValue<bool> reseau = ref.watch(horsLigneProvider);
    final bool horsLigne = reseau.hasValue && reseau.requireValue;

    EleveDuFoyer? eleve;
    if (donnees.hasValue) {
      for (final EleveDuFoyer e in donnees.requireValue.eleves) {
        if (e.id == widget.eleveId) {
          eleve = e;
        }
      }
    }

    final Widget corps;
    if (horsLigne && !donnees.hasValue) {
      // Le bandeau de `PageShell` dit le reseau, le bloc dit ce qui manque
      // (EA-HL-DOUBLE-1).
      corps = EtatSansDonnees(
        quoi: t.appareils.eleve.sansDonnees,
        onAction: () => relireAppareilsFoyer(ref),
      );
    } else {
      corps = BlocAsynchrone<DonneesAppareilsFoyer>(
        valeur: donnees,
        squelette: const _Squelette(),
        onReessayer: () => relireAppareilsFoyer(ref),
        construire: (DonneesAppareilsFoyer d) {
          final EleveDuFoyer? trouve = eleve;
          if (trouve == null) {
            return EtatSysteme(
              nature: NatureEtat.introuvable,
              titre: t.appareils.eleve.introuvableTitre,
              phrase: t.appareils.eleve.introuvable,
              libelleAction: t.appareils.eleve.introuvableAction,
              onAction: () => _routeur?.go(Routes.tuteurFoyerAppareils),
            );
          }
          return _Contenu(
            eleve: trouve,
            appareils: appareilsActifsDe(trouve.id, d.appareils),
            horsLigne: horsLigne,
            retraitEnCours: _retraitEnCours,
            succes: _succes,
            echec: _echec,
            onRetirer: (AppareilAppaire a) =>
                unawaited(_retirer(a, trouve.prenom)),
            onConnecter: _connecter,
          );
        },
      );
    }

    return PageShell(
      titre: t.appareils.titre,
      sousTitre: eleve == null
          ? null
          : t.appareils.eleve.sousTitre(prenom: eleve.prenom),
      onRetour: _retour,
      child: corps,
    );
  }
}

class _Contenu extends StatelessWidget {
  const _Contenu({
    required this.eleve,
    required this.appareils,
    required this.horsLigne,
    required this.retraitEnCours,
    required this.succes,
    required this.echec,
    required this.onRetirer,
    required this.onConnecter,
  });

  final EleveDuFoyer eleve;
  final List<AppareilAppaire> appareils;
  final bool horsLigne;
  final String? retraitEnCours;
  final String? succes;
  final String? echec;
  final void Function(AppareilAppaire appareil) onRetirer;
  final VoidCallback onConnecter;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final e = t.appareils.eleve;
    final bool bureau = AppGabarit.de(context) == Gabarit.desktop;

    final List<Widget> principal = <Widget>[
      if (appareils.isEmpty)
        // Le vide n'a pas d'action propre : l'action de l'ecran, juste
        // dessous, est la seule (un seul CTA par ecran).
        EtatSysteme(
          nature: NatureEtat.aucunResultat,
          titre: e.videTitre,
          phrase: e.vide(dePrenom: deDevant(eleve.prenom)),
        )
      else
        ListeAppareilsEleve(
          appareils: appareils,
          retraitEnCours: retraitEnCours,
          onRetirer: horsLigne ? null : onRetirer,
        ),
      LocalFeedback(message: succes, persistant: true),
      if (echec != null) ...<Widget>[
        Ecart.vMd,
        Semantics(
          liveRegion: true,
          child: Text(
            echec!,
            style: palette.inkAlert.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ),
      ],
      if (horsLigne) ...<Widget>[
        Ecart.vMd,
        Text(
          e.horsLigne,
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
      ],
      Ecart.vXxl,
      ActionPrincipale(
        key: AppareilsElevePage.connecterKey,
        libelle: e.connecter,
        prefixe: Icon(AppIcons.ajouter.repos),
        onPress: onConnecter,
      ),
    ];

    final List<Widget> explications = <Widget>[
      EncartAppareils(
        icone: AppIcons.verrou,
        titre: e.partageTitre,
        phrase: e.partage,
      ),
      Ecart.vXxl,
      EncartAppareils(
        icone: AppIcons.avertissement,
        titre: e.retraitTitre,
        phrase: e.retrait,
      ),
    ];

    if (bureau) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: principal,
            ),
          ),
          const SizedBox(width: AppSpacing.section),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: explications,
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[...principal, Ecart.vSection, ...explications],
    );
  }
}

class _Squelette extends StatelessWidget {
  const _Squelette();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Skeleton(hauteur: AppSpacing.xxl),
      Ecart.vSm,
      Skeleton(hauteur: AppSpacing.respiration * 2),
      Ecart.vXxl,
      Skeleton(hauteur: AppSpacing.xxxl + AppSpacing.xl),
    ],
  );
}
