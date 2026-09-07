import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/matching/service_matching.dart';
import '../../core/planning/service_planning.dart';
import '../../core/regles/service_regles.dart';
import '../../core/session/session_controleur.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bento_tile.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/offline_banner.dart';
import '../disponibilites/grille_semaine.dart';

/// `ENS-06` : les heures de l'enseignant, et les eleves qui les attendent.
///
/// Ce qui se prend ici est un **eleve**, pas un creneau : la relation dure et ne
/// se rompt que par une demande tranchee par l'administration (ADR-017). Le
/// creneau n'est que l'heure du rendez-vous hebdomadaire qui en decoule.
class CreneauxPage extends ConsumerWidget {
  /// Cree l'ecran des creneaux.
  const CreneauxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textes = Theme.of(context).textTheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: <Widget>[
              const OfflineBanner(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    t.creneaux.titre,
                    style: textes.headlineSmall,
                  ),
                ),
              ),
              TabBar(
                tabs: <Widget>[
                  Tab(text: t.creneaux.ongletHeures),
                  Tab(text: t.creneaux.ongletEleves),
                ],
              ),
              const Expanded(
                child: TabBarView(
                  children: <Widget>[_OngletHeures(), _OngletEleves()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Onglet 1 : la meme grille que `TUT-04`, au sens litteral.
class _OngletHeures extends ConsumerStatefulWidget {
  const _OngletHeures();

  @override
  ConsumerState<_OngletHeures> createState() => _OngletHeuresEtat();
}

class _OngletHeuresEtat extends ConsumerState<_OngletHeures> {
  bool _enCours = false;
  bool _erreur = false;

  Future<void> _basculer(String monId, Creneau creneau, bool posee) async {
    setState(() {
      _enCours = true;
      _erreur = false;
    });
    try {
      final ServicePlanning service = ref.read(servicePlanningProvider);
      if (posee) {
        await service.retirer(profilId: monId, creneau: creneau);
      } else {
        await service.poser(profilId: monId, creneau: creneau);
      }
      ref
        ..invalidate(disponibilitesProvider(monId))
        // Les heures decident du feed : le laisser tel quel montrerait des
        // eleves qu'on ne peut plus prendre, ou en cacherait qu'on pourrait.
        ..invalidate(elevesEnAttenteProvider);
    } on Object {
      if (mounted) {
        setState(() => _erreur = true);
      }
    } finally {
      if (mounted) {
        setState(() => _enCours = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppMetriques metriques = AppMetriques.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final String? monId = ref.watch(sessionProvider).profileId;
    final AsyncValue<String> fuseau = ref.watch(monFuseauProvider);

    if (monId == null) {
      return EmptyState(message: t.commun.chargement, invitation: '');
    }

    final AsyncValue<List<Creneau>> creneaux = ref.watch(
      disponibilitesProvider(monId),
    );
    final List<Creneau> poses = creneaux.value ?? const <Creneau>[];

    return ListView(
      padding: EdgeInsets.all(metriques.marge),
      children: <Widget>[
        Text(t.disponibilites.titreEnseignant, style: textes.titleMedium),
        Ecart.vXs,
        Text(t.disponibilites.consigneEnseignant, style: textes.bodySmall),
        Ecart.vMd,
        GrilleSemaine(
          creneaux: poses,
          fuseau: fuseau.value ?? 'Europe/Paris',
          enCours: _enCours,
          onBasculer: (Creneau creneau, bool posee) =>
              _basculer(monId, creneau, posee),
        ),
        Ecart.vSm,
        Text(t.disponibilites.effetEnseignant, style: textes.bodySmall),
        if (_erreur || creneaux.hasError) ...<Widget>[
          Ecart.vSm,
          Text(
            t.disponibilites.erreur,
            style: palette.inkAlert.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
      ],
    );
  }
}

/// Onglet 2 : les eleves en attente, anciennete d'abord.
class _OngletEleves extends ConsumerStatefulWidget {
  const _OngletEleves();

  @override
  ConsumerState<_OngletEleves> createState() => _OngletElevesEtat();
}

class _OngletElevesEtat extends ConsumerState<_OngletEleves> {
  String? _priseEnCours;
  String? _erreur;

  /// Au-dela de ce delai, la demande porte un lisere : sans lui, une famille
  /// peut rester en bas de liste sans que personne ne le remarque.
  static const int joursAvantSignal = 3;

  Future<void> _prendre(EleveEnAttente eleve) async {
    setState(() {
      _priseEnCours = eleve.eleveId;
      _erreur = null;
    });
    try {
      await ref
          .read(serviceMatchingProvider)
          .prendre(eleveId: eleve.eleveId, creneau: eleve.creneau);
      ref
        ..invalidate(elevesEnAttenteProvider)
        ..invalidate(affectationsProvider)
        ..invalidate(seancesProvider);
    } on Object catch (erreur) {
      // La base tranche, pas l'ecran : si un autre enseignant vient de prendre
      // cet eleve, le refus vient de la et se lit tel quel.
      if (mounted) {
        setState(() => _erreur = _message(erreur));
      }
    } finally {
      if (mounted) {
        setState(() => _priseEnCours = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppMetriques metriques = AppMetriques.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final String? monId = ref.watch(sessionProvider).profileId;
    final AsyncValue<List<EleveEnAttente>> feed = ref.watch(
      elevesEnAttenteProvider,
    );
    final AsyncValue<List<Affectation>> affectations = ref.watch(
      affectationsProvider,
    );

    final int suivis = (affectations.value ?? const <Affectation>[])
        .where((Affectation a) => a.active && a.enseignantId == monId)
        .length;
    final int plafond = monId == null
        ? 0
        : (ref.watch(reglesProfilProvider(monId)).value ?? const <RegleProfil>[])
              .where((RegleProfil r) => r.cle == CleRegle.plafondEleves)
              .map((RegleProfil r) => r.valeurEffective)
              .followedBy(const <int>[0])
              .first;
    final bool auPlafond = plafond > 0 && suivis >= plafond;

    // L'anciennete ordonne la liste ici, et non dans la requete : sans ce tri,
    // la famille qui attend depuis le plus longtemps se retrouvait en bas, ce
    // qui vide le matching de son interet.
    final List<EleveEnAttente> eleves = parAnciennete(
      feed.value ?? const <EleveEnAttente>[],
    );

    return ListView(
      padding: EdgeInsets.all(metriques.marge),
      children: <Widget>[
        if (plafond > 0)
          Text(
            t.creneaux.mesEleves(
              nombre: '$suivis',
              plafond: '$plafond',
            ),
            style: textes.bodySmall,
          ),
        Ecart.vMd,
        if (auPlafond) ...<Widget>[
          // Le bouton « Prendre » n'est pas rendu au plafond : un bouton qui
          // echoue apres le geste coute plus cher qu'un bouton absent.
          Text(
            t.creneaux.plafondAtteint(nombre: '$suivis'),
            style: textes.bodyMedium,
          ),
          Ecart.vSm,
          ActionPrincipale(
            libelle: t.creneaux.plafondDemander,
            onPress: () => _ouvrirDemande(context, monId!, plafond),
            surface: palette.surfaceCanvas,
          ),
          Ecart.vLg,
        ],
        if (_erreur != null) ...<Widget>[
          Text(
            t.creneaux.erreur(message: _erreur!),
            style: palette.inkAlert.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
          Ecart.vMd,
        ],
        if (feed.hasValue && eleves.isEmpty)
          EmptyState(
            message: t.creneaux.aucunEleve,
            invitation: t.creneaux.aucunEleveDetail,
          )
        else
          for (final EleveEnAttente eleve in eleves)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _CarteEleve(
                eleve: eleve,
                enCours: _priseEnCours == eleve.eleveId,
                // Au plafond, la carte reste visible : l'enseignant doit
                // pouvoir constater qui attend avant de demander plus.
                avecBouton: !auPlafond,
                onPrendre: () => _prendre(eleve),
              ),
            ),
      ],
    );
  }

  Future<void> _ouvrirDemande(
    BuildContext context,
    String monId,
    int plafond,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext contexteFeuille) =>
          _FeuilleDemande(monId: monId, plafondActuel: plafond),
    );
  }
}

String _message(Object erreur) {
  final String brut = erreur.toString();
  // Les exceptions Postgrest portent le message metier en clair : c'est lui
  // qu'il faut montrer, pas le type de l'exception.
  final int deuxPoints = brut.indexOf(': ');
  return deuxPoints >= 0 && deuxPoints + 2 < brut.length
      ? brut.substring(deuxPoints + 2)
      : brut;
}

class _CarteEleve extends StatelessWidget {
  const _CarteEleve({
    required this.eleve,
    required this.enCours,
    required this.avecBouton,
    required this.onPrendre,
  });

  final EleveEnAttente eleve;
  final bool enCours;
  final bool avecBouton;
  final VoidCallback onPrendre;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final int jours = eleve.joursDAttente(DateTime.now());
    final bool signale = jours >= _OngletElevesEtat.joursAvantSignal;

    return BentoTile(
      avecBordure: true,
      // Le lisere de l'attente : il ne remplace pas le texte, il le double.
      surface: signale ? palette.surfaceWarning : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(eleve.prenom, style: textes.titleMedium),
          Text(eleve.identifiantImmuable, style: textes.bodySmall),
          if (eleve.niveau != null)
            Text(
              t.creneaux.niveau(niveau: eleve.niveau!),
              style: textes.bodySmall,
            ),
          Ecart.vXs,
          Text(
            switch (jours) {
              0 => t.creneaux.attendAujourdhui,
              1 => t.creneaux.attendUnJour,
              _ => t.creneaux.attendDepuis(jours: '$jours'),
            },
            style: textes.bodySmall,
          ),
          Ecart.vSm,
          if (avecBouton)
            ActionPrincipale(
              libelle: t.creneaux.prendre(
                jour: t.disponibilites.joursLongs[eleve.creneau.jour - 1],
                heure: '${eleve.creneau.heure}',
              ),
              onPress: onPrendre,
              enCours: enCours,
            ),
        ],
      ),
    );
  }
}

/// La demande d'augmentation de plafond, faite par l'enseignant pour lui-meme.
class _FeuilleDemande extends ConsumerStatefulWidget {
  const _FeuilleDemande({required this.monId, required this.plafondActuel});

  final String monId;
  final int plafondActuel;

  @override
  ConsumerState<_FeuilleDemande> createState() => _FeuilleDemandeEtat();
}

class _FeuilleDemandeEtat extends ConsumerState<_FeuilleDemande> {
  final TextEditingController _motif = TextEditingController();
  int? _valeur;
  bool _enCours = false;
  String? _erreur;
  bool _envoyee = false;

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    final int? valeur = _valeur;
    if (valeur == null || _motif.text.trim().isEmpty) {
      setState(() => _erreur = t.creneaux.demandeMotifRequis);
      return;
    }
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await ref.read(serviceMatchingProvider).demander(
        sorte: SorteDemande.plafond,
        sujetId: widget.monId,
        motif: _motif.text.trim(),
        valeur: valeur,
      );
      if (mounted) {
        setState(() => _envoyee = true);
      }
    } on Object catch (erreur) {
      if (mounted) {
        setState(() => _erreur = _message(erreur));
      }
    } finally {
      if (mounted) {
        setState(() => _enCours = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppMetriques metriques = AppMetriques.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: metriques.marge,
        right: metriques.marge,
        top: metriques.marge,
        bottom: MediaQuery.viewInsetsOf(context).bottom + metriques.marge,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(t.creneaux.demandeTitre, style: textes.titleMedium),
          Ecart.vMd,
          if (_envoyee)
            Text(t.creneaux.demandeEnvoyee, style: textes.bodyMedium)
          else ...<Widget>[
            ChoiceCardGroup(
              options: <OptionChoix>[
                for (int de = 1; de <= 3; de++)
                  OptionChoix(
                    valeur: '${widget.plafondActuel + de}',
                    libelle: t.creneaux.eleves(
                      nombre: '${widget.plafondActuel + de}',
                    ),
                  ),
              ],
              onChange: (ReponseChoix reponse) => setState(() {
                _valeur = int.tryParse(
                  reponse.valeurs.isEmpty
                      ? reponse.saisieLibre ?? ''
                      : reponse.valeurs.first,
                );
              }),
            ),
            Ecart.vMd,
            TextField(
              controller: _motif,
              decoration: InputDecoration(labelText: t.creneaux.demandeMotif),
              // Sans ceci, le bouton ne se reconstruit pas a la frappe et
              // reste inerte alors que le motif est saisi (piege de l'etape 3).
              onChanged: (String _) => setState(() {}),
              maxLines: 2,
            ),
            if (_erreur != null) ...<Widget>[
              Ecart.vSm,
              Text(
                _erreur!,
                style: palette.inkAlert.applyTo(
                  textes.bodySmall ?? const TextStyle(),
                ),
              ),
            ],
            Ecart.vMd,
            ActionPrincipale(
              libelle: t.creneaux.demandeEnvoyer,
              enCours: _enCours,
              onPress: _valeur == null || _motif.text.trim().isEmpty
                  ? null
                  : _envoyer,
            ),
          ],
        ],
      ),
    );
  }
}
