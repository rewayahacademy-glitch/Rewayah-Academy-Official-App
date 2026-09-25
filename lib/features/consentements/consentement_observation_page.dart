import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../core/capacites/consentements_supabase.dart';
import '../../core/capacites/port_consentements.dart';
import '../../core/domain/enums.dart';
import '../../core/dossier/versions_contrat.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/profil/service_acceptations.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../connexion/recuperation_page.dart'
    show IssueEnvoiLien, issueEchecEnvoi;
import 'explication_observation.dart';
import 'texte_observation.dart';

/// Largeur a partir de laquelle la page passe en deux colonnes.
const double _largeurColonnes = 900;

/// `/tuteur/compte/consentements` : l'invite des comptes existants a lire et
/// accepter la nouvelle version des conditions (paragraphe des visites
/// d'observation, decision P2 et 03 section 1 bis-3).
///
/// Elle **lit** les acceptations avant de dire quoi que ce soit : aucune
/// acceptation n'est presumee, et un echec de lecture est dit comme tel, jamais
/// traite comme « rien a signer ». La case n'est jamais precochee ; l'accord
/// s'enregistre par le mecanisme existant (`contract_acceptances`).
class ConsentementObservationPage extends ConsumerStatefulWidget {
  /// Cree la page.
  const ConsentementObservationPage({super.key});

  @override
  ConsumerState<ConsentementObservationPage> createState() =>
      _ConsentementObservationPageState();
}

class _ConsentementObservationPageState
    extends ConsumerState<ConsentementObservationPage> {
  bool _cochee = false;
  bool _envoi = false;
  bool _merci = false;
  String? _erreur;

  VarianteObservation get _variante {
    String? pour;
    try {
      pour = GoRouterState.of(context).uri.queryParameters['pour'];
    } on Object {
      pour = null;
    }
    return VarianteObservation.depuisParametre(pour);
  }

  void _retour() => GoRouter.of(context).go(Routes.tuteurCompte);

  Future<void> _accepter() async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(portConsentementsProvider)
          .accepter(
            sorte: SorteContrat.conditionsTuteur,
            version: VersionsContrat.pour(SorteContrat.conditionsTuteur),
          );
      if (mounted) {
        setState(() => _merci = true);
      }
    } on PostgrestException catch (e) {
      // 23505 : la version est deja signee (autre appareil). On relit au lieu
      // de pretendre : c'est la lecture qui dira la date.
      if (e.code != '23505' && mounted) {
        setState(() => _erreur = t.contrat.erreur);
      }
    } on Object catch (e) {
      if (mounted) {
        setState(
          () => _erreur = issueEchecEnvoi(e) == IssueEnvoiLien.horsLigne
              ? t.contrat.horsLigne
              : t.contrat.erreur,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _envoi = false);
        ref.invalidate(accordsTitulaireProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Acceptation>> accords = ref.watch(
      accordsTitulaireProvider,
    );
    return PageShell(
      titre: t.consentement.texte.titre,
      onRetour: _retour,
      child: accords.hasValue
          ? _contenu(accords.requireValue)
          : accords.hasError
          ? _Echec(
              erreur: accords.error!,
              onReessayer: () => ref.invalidate(accordsTitulaireProvider),
            )
          : Semantics(
              label: t.consentement.compte.chargement,
              child: const Skeleton.liste(lignes: 4),
            ),
    );
  }

  Widget _contenu(List<Acceptation> lues) {
    final TextTheme textes = Theme.of(context).textTheme;
    final Acceptation? signee = acceptationObservation(lues);
    final bool accorde = signee != null || _merci;
    final VarianteObservation variante = _variante;

    final List<Widget> texte = <Widget>[
      Semantics(
        liveRegion: true,
        child: Text(
          signee != null
              ? t.consentement.compte.accepteLe(date: _date(signee.accepteeLe))
              : _merci
              ? t.consentement.compte.merci
              : t.consentement.compte.intro,
          style: textes.bodyLarge,
        ),
      ),
      Ecart.vXl,
      TexteObservation(variante: variante),
    ];

    final List<Widget> accord = <Widget>[
      if (!accorde) ...<Widget>[
        CaseAccordObservation(
          variante: variante,
          cochee: _cochee,
          onChanged: _envoi ? null : (bool v) => setState(() => _cochee = v),
        ),
        if (_erreur != null) ...<Widget>[
          Ecart.vMd,
          Semantics(
            liveRegion: true,
            child: Text(
              _erreur!,
              style: AppPalette.of(context).inkAlert
                  .applyTo(textes.bodyMedium ?? const TextStyle()),
            ),
          ),
        ],
        Ecart.vXl,
        ActionPrincipale(
          libelle: t.consentement.texte.continuer,
          onPress: _cochee ? () => unawaited(_accepter()) : null,
          enCours: _envoi,
        ),
        Ecart.vMd,
      ],
      ActionPrincipale(
        libelle: t.consentement.texte.retour,
        onPress: _retour,
        niveau: NiveauAction.tertiaire,
      ),
    ];

    const Widget explication = AppCard(child: ExplicationObservation());

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        if (contraintes.maxWidth >= _largeurColonnes) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[...texte, Ecart.vXl, ...accord],
                ),
              ),
              Ecart.hXxl,
              const Expanded(flex: 2, child: explication),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ...texte,
            Ecart.vXl,
            explication,
            Ecart.vXl,
            ...accord,
          ],
        );
      },
    );
  }
}

class _Echec extends StatelessWidget {
  const _Echec({required this.erreur, required this.onReessayer});

  final Object erreur;
  final VoidCallback onReessayer;

  @override
  Widget build(BuildContext context) {
    final String phrase = erreur is StateError
        ? t.consentement.compte.sansProfil
        : issueEchecEnvoi(erreur) == IssueEnvoiLien.horsLigne
        ? t.consentement.compte.horsLigne
        : t.consentement.compte.erreur;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          liveRegion: true,
          child: Text(phrase, style: Theme.of(context).textTheme.bodyLarge),
        ),
        Ecart.vXl,
        ActionPrincipale(libelle: t.commun.reessayer, onPress: onReessayer),
      ],
    );
  }
}

/// L'invite des comptes existants, a poser la ou l'on veut la signaler
/// (Compte, lot E ; demande A-3) : elle ne s'affiche que si la lecture des
/// acceptations **reussit** et montre la version non signee. Rien pendant la
/// lecture ni en echec : une invite n'affirme rien qu'elle n'a pas lu.
class InviteConsentementObservation extends ConsumerWidget {
  /// Cree l'invite.
  const InviteConsentementObservation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Acceptation>? lues = ref.watch(accordsTitulaireProvider).value;
    if (lues == null || acceptationObservation(lues) != null) {
      return const SizedBox.shrink();
    }
    return AppCard(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              t.consentement.compte.invite,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Ecart.hMd,
          ActionPrincipale(
            libelle: t.consentement.compte.inviteAction,
            onPress: () =>
                GoRouter.of(context).go(Routes.tuteurCompteConsentements),
            niveau: NiveauAction.secondaire,
            pleineLargeur: false,
          ),
        ],
      ),
    );
  }
}

String _date(DateTime quand) =>
    '${quand.day.toString().padLeft(2, '0')}/'
    '${quand.month.toString().padLeft(2, '0')}/${quand.year}';
