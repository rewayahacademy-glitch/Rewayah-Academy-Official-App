/// BACK-FRONT-REPRISE-1 : la file des reprises de foyer, cote administration.
///
/// Une carte par demande : qui demande, quel foyer, depuis quand. Quand le
/// serveur dit la demande decidable, deux gestes : « Valider la reprise »
/// (confirmee : elle transfere la titularite) et « Refuser la reprise ». Sinon
/// la raison remplace les boutons (jamais grises) : refusee par le titulaire,
/// ou examen possible a partir d'une date rendue par le serveur.
///
/// L'ecran lit une capacite (`decidable`), jamais un role. Aucun delai calcule
/// ici. Etats : chargement, contenu, vide, erreur, hors ligne, port absent
/// (« disponible au branchement serveur »). Aucun bouton plein : la decision
/// engage, elle se fait en deux gestes de meme poids apres confirmation.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/foyer/port_reprises_admin.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import '../../core/widgets/status_pill.dart';
import '../suivi_demandes/libelles_suivi_demandes.dart' show hhmmDemande;

String _date(DateTime d) => t.commun.dates.jourDate(
  jour: t.commun.dates.jours[d.weekday - 1],
  numero: d.day,
  mois: t.commun.dates.mois[d.month - 1],
);

/// L'ecran « Reprises de foyer ».
class ReprisesPage extends ConsumerStatefulWidget {
  /// Cree l'ecran.
  const ReprisesPage({super.key});

  @override
  ConsumerState<ReprisesPage> createState() => _ReprisesPageState();
}

class _ReprisesPageState extends ConsumerState<ReprisesPage> {
  /// Une cle par geste : une nouvelle tentative apres une coupure la reprend.
  final Map<String, String> _cles = <String, String>{};
  String? _enCours;
  String? _message;
  bool _echec = false;

  Future<void> _decider(RepriseAdmin r, {required bool approuver}) async {
    final PortReprisesAdmin? port = ref.read(portReprisesAdminProvider);
    if (port == null || _enCours != null) return;
    final a = t.reprisesAdmin;
    final bool oui = await ConfirmDestructive.demander(
      context,
      question: approuver
          ? a.validerQuestion(prenom: r.demandeurPrenom)
          : a.refuserQuestion(prenom: r.demandeurPrenom),
      consequence: approuver ? a.validerConsequence : a.refuserConsequence,
      libelleConfirmer: approuver ? a.valider : a.refuser,
    );
    if (!oui || !mounted) return;
    // Hors ligne, rien ne part.
    if (ref.read(horsLigneProvider).value ?? false) return;
    final String cle = _cles.putIfAbsent(
      '${r.id}:$approuver',
      () => const Uuid().v4(),
    );
    setState(() {
      _enCours = r.id;
      _echec = false;
      _message = null;
    });
    ResultatDecisionReprise resultat;
    try {
      resultat = await port.decider(
        repriseId: r.id,
        approuver: approuver,
        cle: cle,
      );
    } on Object {
      resultat = const RepriseDecisionEchecReseau();
    }
    if (!mounted) return;
    setState(() {
      _enCours = null;
      switch (resultat) {
        case RepriseDecidee():
          _message = approuver ? a.validee : a.refusee;
          _cles.remove('${r.id}:$approuver');
        case RepriseDejaTraitee():
          _message = a.dejaTraitee;
        case RepriseDecisionEchecReseau():
          _echec = true;
      }
    });
    // Dans tous les cas la liste est relue : une decision dont la reponse s'est
    // perdue doit y apparaitre (« non confirme », jamais « non envoye »).
    ref.invalidate(reprisesAdminProvider);
  }

  @override
  Widget build(BuildContext context) {
    final a = t.reprisesAdmin;
    final AsyncValue<List<RepriseAdmin>> valeur = ref.watch(
      reprisesAdminProvider,
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return PageShell(
      titre: a.titre,
      sousTitre: a.sousTitre,
      entete: SousNavigationDomaine(onglets: ongletsPersonnes(), indexActif: 3),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_message != null || _echec)
                Semantics(
                  liveRegion: true,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(
                      _echec ? a.echecReseau : _message!,
                      key: ValueKey<String>(
                        _echec ? 'reprises-echec' : 'reprises-message',
                      ),
                      style: (_echec ? palette.inkAlert : palette.inkMuted)
                          .applyTo(textes.bodyMedium ?? const TextStyle()),
                    ),
                  ),
                ),
              BlocAsynchrone<List<RepriseAdmin>>(
                key: const ValueKey<String>('reprises-bloc'),
                valeur: valeur,
                squelette: const Skeleton.liste(lignes: 3),
                onReessayer: () => ref.invalidate(reprisesAdminProvider),
                vide: EmptyState(
                  key: const ValueKey<String>('reprises-vide'),
                  message: a.vide,
                  icone: AppIcons.foyer,
                  registre: RegistreVide.subi,
                ),
                erreurVersEtat: (Object e, VoidCallback? reessayer) {
                  if (e is CapaciteIndisponible) {
                    return EtatSysteme(
                      key: const ValueKey<String>('reprises-indisponible'),
                      nature: NatureEtat.indisponible,
                      titre: a.indisponibleTitre,
                      phrase: a.indisponiblePhrase,
                      dependance: dependanceReprisesAdmin,
                    );
                  }
                  return horsLigne
                      ? EtatSansDonnees(
                          key: const ValueKey<String>('reprises-sans-donnees'),
                          quoi: a.sansDonnees,
                          onAction: reessayer,
                        )
                      : EtatSysteme(
                          key: const ValueKey<String>('reprises-erreur'),
                          nature: NatureEtat.echecServeur,
                          phrase: a.erreur,
                          onAction: reessayer,
                        );
                },
                construire: (List<RepriseAdmin> lues) => PileCartes(
                  key: const ValueKey<String>('reprises-contenu'),
                  children: <Widget>[
                    for (final RepriseAdmin r in lues)
                      _CarteReprise(
                        reprise: r,
                        enCours: _enCours == r.id,
                        occupe: _enCours != null,
                        onValider: () =>
                            unawaited(_decider(r, approuver: true)),
                        onRefuser: () =>
                            unawaited(_decider(r, approuver: false)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarteReprise extends StatelessWidget {
  const _CarteReprise({
    required this.reprise,
    required this.enCours,
    required this.occupe,
    required this.onValider,
    required this.onRefuser,
  });

  final RepriseAdmin reprise;
  final bool enCours;
  final bool occupe;
  final VoidCallback onValider;
  final VoidCallback onRefuser;

  @override
  Widget build(BuildContext context) {
    final a = t.reprisesAdmin;
    final RepriseAdmin r = reprise;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle corps = palette.inkStrong.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final DateTime? depot = r.deposeeLe;
    final DateTime? examen = r.examenPossibleLe;
    return AppCard(
      key: ValueKey<String>('reprise-${r.id}'),
      entete: OverflowBar(
        alignment: MainAxisAlignment.spaceBetween,
        overflowAlignment: OverflowBarAlignment.start,
        spacing: AppSpacing.sm,
        overflowSpacing: AppSpacing.sm,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              '${r.demandeurPrenom} ${r.demandeurNom}',
              style: textes.titleMedium,
            ),
          ),
          StatusPill(
            libelle: r.etat == EtatRepriseAdmin.aExaminer
                ? a.etat.aExaminer
                : a.etat.refuseeParTitulaire,
            ton: r.etat == EtatRepriseAdmin.aExaminer
                ? TonEtat.accent
                : TonEtat.neutre,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LigneCleValeur(cle: a.foyer, valeur: r.foyerNom),
          if (depot != null) ...<Widget>[
            Ecart.vSm,
            LigneCleValeur(
              cle: a.deposeeLe,
              valeur:
                  '${_date(depot)} ${hhmmDemande(depot.hour, depot.minute)}',
            ),
          ],
          Ecart.vLg,
          // Pendant une decision, les autres gestes ne sont pas rendus
          // (jamais grises).
          if (r.decidable && (enCours || !occupe)) ...<Widget>[
            ActionPrincipale(
              key: ValueKey<String>('reprise-valider-${r.id}'),
              libelle: a.valider,
              niveau: NiveauAction.secondaire,
              enCours: enCours,
              onPress: enCours ? null : onValider,
            ),
            if (!enCours) ...<Widget>[
              Ecart.vSm,
              ActionPrincipale(
                key: ValueKey<String>('reprise-refuser-${r.id}'),
                libelle: a.refuser,
                niveau: NiveauAction.tertiaire,
                onPress: onRefuser,
              ),
            ],
          ] else if (!r.decidable) ...<Widget>[
            Text(
              r.etat == EtatRepriseAdmin.refuseeParTitulaire
                  ? a.refuseeInfo
                  : examen != null
                  ? a.examenLe(date: _date(examen))
                  : a.refuseeInfo,
              key: ValueKey<String>('reprise-raison-${r.id}'),
              style: corps,
            ),
          ],
        ],
      ),
    );
  }
}
