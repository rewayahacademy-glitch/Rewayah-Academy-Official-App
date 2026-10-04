// Aujourd'hui du Comptable (FIN-CPT-W01, M01 ecran 1 ; spec §29, §12, §28,
// §11 ; CPT-JOUR). Posee par CPT-F avec son constructeur definitif,
// **propriete de la voie CPT (CPT-JOUR)**, qui ecrit dans
// `lib/features/comptable/aujourdhui/**` seulement
// (`20_comptable/02_DECOUPAGE.md`).
//
// Repond a « Que dois-je faire maintenant ? » : neuf zones (§29), aucun
// graphique (DR-09), aucun bouton Payer (DR-11) ; chaque ligne ouvre l'ecran
// canonique par sa route de `Routes` (§5.1). Lit
// `portAujourdhuiComptableProvider` (CPT-BR-03) ; en production, sans
// source, l'ecran dit « indisponible » sans « Reessayer » (port neutre).
//
// Composition (planche H00, composition seulement, K-63 ; theme Rewayah) :
// - bureau : synthese de tresorerie (Tresorerie libre au centre, §11) et
//   Reserve strategique en lecture sur une rangee ; puis trois colonnes :
//   « A traiter » et « Paiements a effectuer » ; « Echeances » et
//   « Encaissements recents » ; « Alertes », « Prestataires », « Activite
//   recente » et « Acces rapides » ;
// - tablette : la meme chose sur deux colonnes ;
// - telephone (M01 ecran 1) : une tache dominante, pas un bureau
//   compresse (§36, §45) : Tresorerie libre, « A traiter » (trois lignes),
//   le resume des alertes, trois echeances ; le reste derriere « Voir tout »
//   (`?vue=attention`, meme route, DR-10) et les onglets du role.
//
// Les quatre metriques gardees repondent chacune a une question operatoire
// (§12.2, DR-08) : Tresorerie libre (que puis-je depenser ?), Fonds
// proteges (qu'est-ce qui n'est pas a moi ?), En transit (qu'est-ce qui
// n'est pas encore confirme ?), Tresorerie detenue (le solde brut, jamais
// presente comme depensable). Aucune variation, aucun « Revenu acquis ».

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/port_aujourdhui_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_gabarit.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/bascule_montants.dart';
import '../../../core/widgets/bloc_asynchrone.dart';
import '../../../core/widgets/comptable/carte_reserve_strategique.dart';
import '../../../core/widgets/comptable/resume_tresorerie.dart';
import '../../../core/widgets/etat_systeme.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/signal_row.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/status_pill.dart';
import 'file_attention.dart';
import 'zones_aujourdhui.dart';

/// La vue du jour, lue par le port (CPT-BR-03). Aucune relance
/// automatique : une capacite absente ne revient pas en insistant, et
/// « Reessayer » reste un geste de la personne (`BlocAsynchrone`).
final FutureProvider<AujourdhuiComptable> aujourdhuiComptableProvider =
    FutureProvider<AujourdhuiComptable>(
      (Ref ref) => ref.watch(portAujourdhuiComptableProvider).aujourdhui(),
      retry: (int retryCount, Object error) => null,
    );

/// Le nombre de lignes d'une liste d'Aujourd'hui sur telephone : le reste
/// est derriere « Voir tout ».
const int _lignesTelephone = 3;

/// Aujourd'hui du Comptable, dans la coquille du role (branche 0).
class AujourdhuiComptablePage extends ConsumerWidget {
  /// Cree la page. [vue] vient de `?vue=` : `attention` ouvre la file
  /// complete « A traiter » et « Alertes » (le « Voir tout » de M01, meme
  /// route, DR-10).
  const AujourdhuiComptablePage({super.key, this.vue});

  /// La vue demandee par l'adresse, ou nulle pour l'ecran complet.
  final String? vue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = t.comptable.aujourdhui;
    final bool fileComplete = vue == Routes.vueAttentionComptable;
    final AsyncValue<AujourdhuiComptable> jour = ref.watch(
      aujourdhuiComptableProvider,
    );
    void relire() => ref.invalidate(aujourdhuiComptableProvider);
    // Sans reseau, un echec se dit « hors ligne » ; une capacite absente
    // reste dite indisponible (meme regle que les autres ecrans d'argent).
    final Object? erreur = jour.hasError ? jour.error : null;
    final bool echecHorsLigne =
        erreur != null &&
        erreur is! CapaciteIndisponible &&
        (ref.watch(horsLigneProvider).value ?? false);
    return PageShell(
      titre: fileComplete ? a.attention : a.titre,
      sousTitre: fileComplete ? a.attentionSousTitre : a.sousTitre,
      onRetour: fileComplete ? () => context.go(Routes.comptable) : null,
      actionsEntete: const <Widget>[BasculeMontants(avecEtat: true)],
      child: echecHorsLigne
          ? EtatSysteme(nature: NatureEtat.horsLigne, onAction: relire)
          : BlocAsynchrone<AujourdhuiComptable>(
              valeur: jour,
              squelette: const Skeleton.liste(lignes: 6),
              onReessayer: relire,
              construire: (AujourdhuiComptable j) =>
                  fileComplete ? _FileComplete(jour: j) : _Corps(jour: j),
            ),
    );
  }
}

/// L'ecran complet, compose selon le gabarit (jamais une largeur comparee
/// a un nombre).
class _Corps extends StatelessWidget {
  const _Corps({required this.jour});

  final AujourdhuiComptable jour;

  @override
  Widget build(BuildContext context) {
    final Gabarit gabarit = AppGabarit.de(context);
    if (gabarit == Gabarit.mobile) return _Telephone(jour: jour);
    final bool bureau = gabarit == Gabarit.desktop;
    final a = t.comptable.aujourdhui;
    final Widget colonneA = _Colonne(<Widget>[
      _zoneATraiter(context, jour.aTraiterHorsPaiements),
      _zone(
        titre: a.paiementsAEffectuer,
        compteur: jour.paiementsAEffectuer.length,
        corps: ZonePaiementsAEffectuer(jour.paiementsAEffectuer),
      ),
    ]);
    final Widget colonneB = _Colonne(<Widget>[
      _zone(
        titre: a.echeances,
        compteur: jour.echeances.length,
        libelleAction: a.voirTout,
        onAction: () => context.go(Routes.comptablePaiements),
        corps: ZoneEcheances(jour.echeances),
      ),
      _zone(
        titre: a.encaissementsRecents,
        libelleAction: a.voirTout,
        onAction: () => context.go(Routes.comptableEncaissements),
        corps: ZoneEncaissementsRecents(jour.encaissementsRecents),
      ),
    ]);
    final Widget colonneC = _Colonne(<Widget>[
      _zone(
        titre: a.alertes,
        compteur: jour.alertes.length,
        corps: FileAttention(elements: jour.alertes, vide: a.alertesVide),
      ),
      _zone(titre: a.prestataires, corps: ZonePrestataires(jour.prestataires)),
      _zone(titre: a.activiteRecente, corps: ZoneActivite(jour.activite)),
      _zone(titre: a.accesRapides, corps: const ZoneAccesRapides()),
    ]);
    final Widget entete = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: bureau ? 3 : 1,
          child: ResumeTresorerie(jour.tresorerie),
        ),
        Ecart.hXxl,
        Expanded(
          flex: bureau ? 2 : 1,
          child: _Reserve(jour: jour),
        ),
      ],
    );
    final Widget colonnes = bureau
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: colonneA),
              Ecart.hXxl,
              Expanded(child: colonneB),
              Ecart.hXxl,
              Expanded(child: colonneC),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: _Colonne(<Widget>[colonneA, colonneB])),
              Ecart.hXxl,
              Expanded(child: colonneC),
            ],
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[entete, Ecart.vSection, colonnes],
    );
  }
}

/// M01 ecran 1 : une colonne, une tache dominante.
class _Telephone extends StatelessWidget {
  const _Telephone({required this.jour});

  final AujourdhuiComptable jour;

  @override
  Widget build(BuildContext context) {
    final a = t.comptable.aujourdhui;
    final int alertes = jour.alertes.length;
    return _Colonne(<Widget>[
      ResumeTresorerie(jour.tresorerie),
      _zone(
        titre: a.aTraiter,
        compteur: jour.aTraiter.length,
        libelleAction: a.voirTout,
        onAction: () => context.go(Routes.comptableAttention),
        corps: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FileAttention(
              elements: jour.aTraiter,
              vide: a.aTraiterVide,
              videDetail: a.aTraiterVideDetail,
              limite: _lignesTelephone,
            ),
            if (alertes > 0) ...<Widget>[
              Ecart.vLg,
              SignalRow(
                key: const ValueKey<String>('resume-alertes'),
                phrase: a.alertesResume(n: alertes),
                icone: AppIcons.avertissement,
                ton: TonEtat.avertissement,
                onPress: () => context.go(Routes.comptableAttention),
              ),
            ],
          ],
        ),
      ),
      _zone(
        titre: a.echeances,
        compteur: jour.echeances.length,
        libelleAction: a.voirTout,
        onAction: () => context.go(Routes.comptablePaiements),
        corps: ZoneEcheances(jour.echeances, limite: _lignesTelephone),
      ),
    ]);
  }
}

/// La file complete (`?vue=attention`) : « A traiter » puis « Alertes »,
/// toutes les lignes, sur tous les gabarits. C'est aussi l'ecran
/// « Alertes / relances » de M02 (DR-10) : pas de troisieme liste.
class _FileComplete extends StatelessWidget {
  const _FileComplete({required this.jour});

  final AujourdhuiComptable jour;

  @override
  Widget build(BuildContext context) {
    final a = t.comptable.aujourdhui;
    return _Colonne(<Widget>[
      _zone(
        titre: a.aTraiter,
        compteur: jour.aTraiter.length,
        corps: FileAttention(
          elements: jour.aTraiter,
          vide: a.aTraiterVide,
          videDetail: a.aTraiterVideDetail,
        ),
      ),
      _zone(
        titre: a.alertes,
        compteur: jour.alertes.length,
        corps: FileAttention(elements: jour.alertes, vide: a.alertesVide),
      ),
    ]);
  }
}

/// La Reserve strategique en lecture ; l'appui ouvre la Tresorerie (W04),
/// ou elle se gere.
class _Reserve extends StatelessWidget {
  const _Reserve({required this.jour});

  final AujourdhuiComptable jour;

  @override
  Widget build(BuildContext context) => CarteReserveStrategique(
    jour.reserve,
    onOuvrir: () => context.go(Routes.comptableTresorerie),
  );
}

/// La zone 3 « A traiter » sur tablette et bureau (hors paiements, qui ont
/// leur zone) ; « Voir tout » ouvre la file complete.
Widget _zoneATraiter(BuildContext context, List<ElementAttention> elements) {
  final a = t.comptable.aujourdhui;
  return _zone(
    titre: a.aTraiter,
    compteur: elements.length,
    libelleAction: a.voirTout,
    onAction: () => context.go(Routes.comptableAttention),
    corps: FileAttention(
      elements: elements,
      vide: a.aTraiterVide,
      videDetail: a.aTraiterVideDetail,
    ),
  );
}

/// Une zone : son titre de section (compteur, « Voir tout ») et son corps.
Widget _zone({
  required String titre,
  required Widget corps,
  int? compteur,
  String? libelleAction,
  VoidCallback? onAction,
}) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    SectionHeader(
      titre: titre,
      compteur: compteur,
      libelleAction: libelleAction,
      onAction: onAction,
    ),
    corps,
  ],
);

/// Des zones empilees, separees par l'ecart de section.
class _Colonne extends StatelessWidget {
  const _Colonne(this.zones);

  final List<Widget> zones;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      for (int i = 0; i < zones.length; i++) ...<Widget>[
        if (i > 0) Ecart.vSection,
        zones[i],
      ],
    ],
  );
}
