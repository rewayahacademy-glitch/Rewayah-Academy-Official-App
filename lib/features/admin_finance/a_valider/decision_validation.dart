// La decision sur une demande de validation (CPT-VAL-1, decision Q-8 = (a)
// du 05/10 ; CPT-BR-09) : la feuille rend la demande (nature, objet,
// demandeur, date, raison et sa precision, montant exact, etat, historique)
// puis, seulement si la source le permet a la personne connectee
// (`approuver`), « Valider » et « Refuser ».
//
// - **Refuser** demande un motif : des puces (motifs rediges a partir des
//   textes de l'app, valides par delegation le 05/10) et « Autre » avec sa
//   saisie. Sans motif, rien ne part : la feuille dit quoi faire.
// - **Jamais le demandeur** : quand la source bloque `approuver` avec
//   `autoPaiement`, la feuille le dit et ne pose aucun bouton de decision.
//   La source le refuse aussi si on essaie (`RefusDecision`).
// - **Aucune promesse non confirmee** : la decision n'est annoncee qu'avec
//   la demande que rend la source. Un refus de la source dit « rien n'a
//   change » ; toute autre erreur laisse l'issue inconnue et invite a
//   relire la liste avant de decider a nouveau. La cle d'idempotence est
//   tiree une fois par feuille et rejouee telle quelle.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart'
    show FutureProviderFamily, ProviderOrFamily;
import 'package:uuid/uuid.dart';

import '../../../core/capacites/port_validations_finance.dart';
import '../../../core/comptable/modeles_comptable.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/bandeau_attention.dart';
import '../../../core/widgets/comptable/ligne_activite.dart';
import '../../../core/widgets/filter_pill.dart';
import '../../../core/widgets/ligne_cle_valeur.dart';
import '../../../core/widgets/montant_argent.dart';
import '../../../core/widgets/pastilles_comptable.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/status_pill.dart';
import 'a_valider_page.dart';

/// Le journal d'une demande (CPT-BR-17).
final FutureProviderFamily<List<EntreeJournal>, String>
journalValidationProvider = FutureProvider.family<List<EntreeJournal>, String>(
  (Ref ref, String id) => ref.watch(portValidationsFinanceProvider).journal(id),
  retry: (int _, Object _) => null,
  dependencies: <ProviderOrFamily>[portValidationsFinanceProvider],
);

/// Les motifs proposes pour un refus, dans l'ordre ; « Autre » ouvre une
/// saisie.
enum MotifRefusValidation {
  /// Coordonnees du beneficiaire a verifier.
  coordonnees,

  /// Montant a verifier a la source.
  montant,

  /// Justificatif manquant ou illisible.
  justificatif,

  /// Hors de la politique de la Reserve.
  reserve,

  /// A reporter au prochain cycle.
  reporter,

  /// Autre : le motif est saisi.
  autre;

  /// Le libelle, qui part aussi a la source comme motif (sauf « Autre »).
  String get libelle {
    final m = t.comptable.validation.motifs;
    return switch (this) {
      MotifRefusValidation.coordonnees => m.coordonnees,
      MotifRefusValidation.montant => m.montant,
      MotifRefusValidation.justificatif => m.justificatif,
      MotifRefusValidation.reserve => m.reserve,
      MotifRefusValidation.reporter => m.reporter,
      MotifRefusValidation.autre => m.autre,
    };
  }
}

/// Ouvre la decision sur [demande]. Rend `true` quand quelque chose a pu
/// changer a la source (decision enregistree, ou issue inconnue) : la liste
/// se relit alors.
Future<bool> ouvrirDecisionValidation(
  BuildContext context,
  DemandeValidation demande,
) async {
  // La feuille lit le port de la portee de la page (demonstration comprise).
  final ProviderContainer portee = ProviderScope.containerOf(
    context,
    listen: false,
  );
  final bool? change = await AppBottomSheet.ouvrir<bool>(
    context,
    titre: t.comptable.validation.detail.titre,
    constructeur: (BuildContext _) => UncontrolledProviderScope(
      container: portee,
      child: FeuilleDecisionValidation(demande: demande),
    ),
  );
  return change ?? false;
}

enum _Phase { lecture, motif, envoi, decidee, refusee, inconnue }

/// Le contenu de la feuille de decision.
class FeuilleDecisionValidation extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleDecisionValidation({required this.demande, super.key});

  /// La demande.
  final DemandeValidation demande;

  /// La cle du bouton « Valider ».
  static const Key cleValider = ValueKey<String>('validation-valider');

  /// La cle du bouton « Refuser ».
  static const Key cleRefuser = ValueKey<String>('validation-refuser');

  /// La cle du bouton « Confirmer le refus ».
  static const Key cleConfirmerRefus = ValueKey<String>(
    'validation-confirmer-refus',
  );

  /// La cle du champ « Autre ».
  static const Key cleMotifAutre = ValueKey<String>('validation-motif-autre');

  /// La cle de la puce d'un motif.
  static Key cleMotif(MotifRefusValidation m) =>
      ValueKey<String>('validation-motif-${m.name}');

  @override
  ConsumerState<FeuilleDecisionValidation> createState() =>
      _FeuilleDecisionValidationState();
}

class _FeuilleDecisionValidationState
    extends ConsumerState<FeuilleDecisionValidation> {
  /// Tiree une fois par feuille, rejouee telle quelle a chaque nouvel essai.
  final String _cle = const Uuid().v4();
  final TextEditingController _autre = TextEditingController();

  _Phase _phase = _Phase.lecture;
  MotifRefusValidation? _motif;
  String? _erreurMotif;
  DecisionValidation? _enCours;
  DemandeValidation? _rendue;
  MotifRefusDecision? _refus;
  bool _change = false;

  @override
  void dispose() {
    _autre.dispose();
    super.dispose();
  }

  String? _motifSaisi() {
    final MotifRefusValidation? m = _motif;
    if (m == null) return null;
    if (m != MotifRefusValidation.autre) return m.libelle;
    final String saisi = _autre.text.trim();
    return saisi.isEmpty ? null : saisi;
  }

  Future<void> _decider(DecisionValidation decision) async {
    if (_phase == _Phase.envoi) return;
    String? motif;
    if (decision == DecisionValidation.refuser) {
      motif = _motifSaisi();
      if (motif == null) {
        // Sans motif, rien ne part (motif obligatoire).
        setState(
          () => _erreurMotif = _motif == MotifRefusValidation.autre
              ? t.comptable.validation.erreurMotifAutre
              : t.comptable.validation.erreurMotif,
        );
        return;
      }
    }
    final _Phase avant = _phase;
    setState(() {
      _phase = _Phase.envoi;
      _enCours = decision;
      _erreurMotif = null;
    });
    try {
      final DemandeValidation rendue = await ref
          .read(portValidationsFinanceProvider)
          .decider(
            demandeId: widget.demande.id,
            decision: decision,
            cleIdempotence: _cle,
            motif: motif,
          );
      if (!mounted) return;
      setState(() {
        _rendue = rendue;
        _change = true;
        _phase = _Phase.decidee;
      });
    } on RefusDecision catch (refus) {
      if (!mounted) return;
      setState(() {
        _refus = refus.motif;
        _phase = refus.motif == MotifRefusDecision.motifObligatoire
            ? avant
            : _Phase.refusee;
        if (refus.motif == MotifRefusDecision.motifObligatoire) {
          _erreurMotif = t.comptable.validation.refusMotif;
        }
        if (refus.motif == MotifRefusDecision.dejaDecidee) _change = true;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _change = true;
        _phase = _Phase.inconnue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = t.comptable.validation;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final DemandeValidation d = _rendue ?? widget.demande;
    final bool peutDecider =
        widget.demande.etat == EtatDemandeValidation.enAttente &&
        widget.demande.permissions.permet(ActionFinance.approuver);
    final bool sienne =
        widget.demande.etat == EtatDemandeValidation.enAttente &&
        estSaPropreDemande(widget.demande);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Resume(demande: d),
        Ecart.vLg,
        if (sienne) ...<Widget>[
          BandeauAttention(
            titre: v.votreDemandeTitre,
            message: v.votreDemandePhrase,
            ton: TonEtat.neutre,
          ),
          Ecart.vLg,
        ],
        ..._issue(d),
        if (peutDecider &&
            (_phase == _Phase.motif ||
                (_phase == _Phase.envoi &&
                    _enCours == DecisionValidation.refuser))) ...<Widget>[
          _SaisieMotif(
            motif: _motif,
            autre: _autre,
            erreur: _erreurMotif,
            envoi: _phase == _Phase.envoi,
            onMotif: (MotifRefusValidation m) => setState(() {
              _motif = m;
              _erreurMotif = null;
            }),
            onSaisie: () {
              if (_erreurMotif != null) setState(() => _erreurMotif = null);
            },
          ),
          Ecart.vLg,
        ],
        _Historique(demandeId: d.id),
        Ecart.vXl,
        _actions(context, peutDecider: peutDecider, horsLigne: horsLigne),
      ],
    );
  }

  List<Widget> _issue(DemandeValidation d) {
    final v = t.comptable.validation;
    switch (_phase) {
      case _Phase.decidee:
        final bool validee = d.etat == EtatDemandeValidation.validee;
        return <Widget>[
          BandeauAttention(
            titre: libelleDemandeValidation(d.etat),
            message: validee ? v.decisionValidee : v.decisionRefusee,
            ton: tonDemandeValidation(d.etat),
          ),
          Ecart.vLg,
        ];
      case _Phase.refusee:
        return <Widget>[
          BandeauAttention(
            titre: v.refusTitre,
            message: switch (_refus) {
              MotifRefusDecision.demandeurNePeutPasValider => v.refusDemandeur,
              MotifRefusDecision.dejaDecidee => v.refusDejaDecidee,
              _ => v.refusMotif,
            },
            ton: TonEtat.alerte,
          ),
          Ecart.vLg,
        ];
      case _Phase.inconnue:
        return <Widget>[
          BandeauAttention(
            titre: v.inconnuTitre,
            message: v.inconnuPhrase,
            ton: TonEtat.alerte,
          ),
          Ecart.vLg,
        ];
      case _Phase.lecture:
      case _Phase.motif:
      case _Phase.envoi:
        return const <Widget>[];
    }
  }

  Widget _actions(
    BuildContext context, {
    required bool peutDecider,
    required bool horsLigne,
  }) {
    final v = t.comptable.validation;
    final TextTheme textes = Theme.of(context).textTheme;
    final bool termine =
        _phase == _Phase.decidee ||
        _phase == _Phase.refusee ||
        _phase == _Phase.inconnue;
    final bool envoi = _phase == _Phase.envoi;
    final bool saisieMotif =
        _phase == _Phase.motif ||
        (envoi && _enCours == DecisionValidation.refuser);
    final List<Widget> boutons = <Widget>[];
    Widget? phrase;
    if (termine || !peutDecider) {
      boutons.add(
        ActionPrincipale(
          libelle: _phase == _Phase.inconnue ? v.relireListe : v.fermer,
          niveau: _phase == _Phase.inconnue
              ? NiveauAction.secondaire
              : NiveauAction.tertiaire,
          onPress: () => Navigator.of(context).pop(_change),
        ),
      );
    } else if (horsLigne) {
      // Hors ligne : aucune decision ne part ; une phrase, pas de bouton
      // grise.
      phrase = Text(
        v.horsLigne,
        style: AppPalette.of(context).inkMuted
            .applyTo(textes.bodyMedium ?? const TextStyle()),
      );
      boutons.add(
        ActionPrincipale(
          libelle: v.fermer,
          niveau: NiveauAction.tertiaire,
          onPress: () => Navigator.of(context).pop(_change),
        ),
      );
    } else {
      // Une seule action pleine : « Confirmer le refus » pendant la saisie
      // du motif, « Valider » sinon ; l'autre geste est secondaire.
      boutons
        ..add(
          saisieMotif
              ? ActionPrincipale(
                  libelle: v.annuler,
                  niveau: NiveauAction.tertiaire,
                  onPress: envoi
                      ? null
                      : () => setState(() {
                          _phase = _Phase.lecture;
                          _erreurMotif = null;
                        }),
                )
              : ActionPrincipale(
                  key: FeuilleDecisionValidation.cleRefuser,
                  libelle: v.refuser,
                  niveau: NiveauAction.secondaire,
                  onPress: envoi
                      ? null
                      : () => setState(() => _phase = _Phase.motif),
                ),
        )
        ..add(
          ActionPrincipale(
            key: saisieMotif
                ? FeuilleDecisionValidation.cleConfirmerRefus
                : FeuilleDecisionValidation.cleValider,
            libelle: saisieMotif ? v.confirmerRefus : v.valider,
            enCours:
                envoi &&
                _enCours ==
                    (saisieMotif
                        ? DecisionValidation.refuser
                        : DecisionValidation.valider),
            onPress: () => _decider(
              saisieMotif
                  ? DecisionValidation.refuser
                  : DecisionValidation.valider,
            ),
          ),
        );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (phrase != null) ...<Widget>[phrase, Ecart.vMd],
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.end,
          children: boutons,
        ),
      ],
    );
  }
}

/// La demande en lignes cle / valeur : le montant **exact** (jamais masque
/// dans une decision).
class _Resume extends StatelessWidget {
  const _Resume({required this.demande});

  final DemandeValidation demande;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final v = t.comptable.validation;
    final DemandeValidation d = demande;
    final String? precision = d.precision;
    final String? motif = d.motifDecision;
    final String? decideur = d.decideur;
    final DateTime? quand = d.dateDecision;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            d.objet,
            style: palette.inkStrong.applyTo(
              textes.titleMedium ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vSm,
        MontantArgent(d.montant, taille: TailleMontant.grand),
        Ecart.vLg,
        LigneCleValeur(
          cle: v.detail.nature,
          valeur: libelleNatureValidation(d.nature),
        ),
        LigneCleValeur(
          cle: v.detail.raison,
          valeur: precision == null
              ? libelleRaisonBlocage(d.raison)
              : '${libelleRaisonBlocage(d.raison)}. $precision',
        ),
        LigneCleValeur(cle: v.detail.demandeur, valeur: d.demandeur),
        LigneCleValeur(cle: v.detail.date, valeur: dateComptable(d.date)),
        LigneCleValeur(
          cle: v.detail.etat,
          valeur: decideur == null || quand == null
              ? libelleDemandeValidation(d.etat)
              : d.etat == EtatDemandeValidation.validee
              ? v.valideePar(decideur: decideur, date: dateComptable(quand))
              : v.refuseePar(decideur: decideur, date: dateComptable(quand)),
        ),
        if (motif != null) LigneCleValeur(cle: v.motifTitre, valeur: motif),
      ],
    );
  }
}

/// Les puces de motif, « Autre » et sa saisie, et l'erreur.
class _SaisieMotif extends StatelessWidget {
  const _SaisieMotif({
    required this.motif,
    required this.autre,
    required this.erreur,
    required this.envoi,
    required this.onMotif,
    required this.onSaisie,
  });

  final MotifRefusValidation? motif;
  final TextEditingController autre;
  final String? erreur;

  /// Vrai pendant l'envoi du refus : rien ne change plus.
  final bool envoi;
  final void Function(MotifRefusValidation m) onMotif;
  final VoidCallback onSaisie;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final v = t.comptable.validation;
    final String? message = erreur;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            v.motifTitre,
            style: palette.inkStrong.applyTo(
              textes.titleSmall ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vXs,
        Text(
          v.motifPhrase,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vMd,
        // Choix de formulaire, pas un filtre : le motif du refus.
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final MotifRefusValidation m in MotifRefusValidation.values)
              FilterPill(
                key: FeuilleDecisionValidation.cleMotif(m),
                libelle: m.libelle,
                retenue: motif == m,
                onPress: envoi ? null : () => onMotif(m),
              ),
          ],
        ),
        if (motif == MotifRefusValidation.autre) ...<Widget>[
          Ecart.vMd,
          Semantics(
            label: v.motifAutreChamp,
            child: TextField(
              key: FeuilleDecisionValidation.cleMotifAutre,
              controller: autre,
              enabled: !envoi,
              maxLength: 200,
              minLines: 1,
              maxLines: 3,
              onChanged: (String _) => onSaisie(),
              decoration: InputDecoration(labelText: v.motifAutreChamp),
            ),
          ),
        ],
        if (message != null) ...<Widget>[
          Ecart.vMd,
          BandeauAttention(
            titre: v.motifTitre,
            message: message,
            ton: TonEtat.alerte,
          ),
        ],
      ],
    );
  }
}

/// L'historique de la demande (CPT-BR-17).
class _Historique extends ConsumerWidget {
  const _Historique({required this.demandeId});

  final String demandeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final v = t.comptable.validation;
    final AsyncValue<List<EntreeJournal>> journal = ref.watch(
      journalValidationProvider(demandeId),
    );
    final List<EntreeJournal>? entrees = journal.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            v.detail.historique,
            style: palette.inkStrong.applyTo(
              textes.titleSmall ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vSm,
        if (entrees == null && journal.isLoading)
          const Skeleton.texte(lignes: 2)
        else if (entrees == null || entrees.isEmpty)
          Text(
            v.detail.historiqueVide,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          )
        else
          for (final EntreeJournal e in entrees) LigneActivite(e),
      ],
    );
  }
}
