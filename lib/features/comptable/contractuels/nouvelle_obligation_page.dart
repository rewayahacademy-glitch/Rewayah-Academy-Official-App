// « Nouvelle obligation » (FIN-CPT-W06 ; spec §22.3, §34 ; K-57).
// **Propriete de la voie CPT-CTR** (`20_comptable/02_DECOUPAGE.md`).
//
// Une tache focalisee (`Routes.estTacheFocaliseeComptable`) : sans barre
// basse sur telephone, sans actions de coquille. Formulaire semi-automatique
// (K-57) dans cet ordre : on **preremplit** (beneficiaire propose, echeance,
// centre de cout, devise rendus par la source), on **propose** (les
// contractuels connus, les centres de cout), on **saisit en dernier** (l'objet
// et le montant, parce qu'une facture externe n'est connue que de celui qui
// la recoit). Le montant se saisit ici et nulle part ailleurs : il est fige a
// l'approbation (§22.3). Atteinte seulement si la source rend la capacite
// `creerObligation` ; sinon la raison rendue s'affiche, sans formulaire
// (§34). Ecrit par `portObligationsContractuelsProvider.creer` (CPT-BR-08),
// une fois (cle d'idempotence generee a l'ouverture).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/port_obligations_contractuels.dart';
import '../../../core/comptable/modeles_comptable.dart';
import '../../../core/comptable/navigation_comptable.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/finance/format_montant.dart';
import '../../../core/finance/montant.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_gabarit.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/bloc_asynchrone.dart';
import '../../../core/widgets/choice_card_group.dart';
import '../../../core/widgets/comptable/ligne_activite.dart' show dateComptable;
import '../../../core/widgets/etat_systeme.dart';
import '../../../core/widgets/filter_pill.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/pastilles_comptable.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton.dart';
import 'contractuels_commun.dart';

/// La valeur de l'option « Nouveau bénéficiaire externe » du choix.
const String _valeurExterne = r'$externe';

/// Le formulaire d'une nouvelle obligation ponctuelle.
class NouvelleObligationPage extends ConsumerStatefulWidget {
  /// Cree la page.
  const NouvelleObligationPage({super.key});

  @override
  ConsumerState<NouvelleObligationPage> createState() =>
      _NouvelleObligationPageState();
}

class _NouvelleObligationPageState
    extends ConsumerState<NouvelleObligationPage> {
  final TextEditingController _nomExterne = TextEditingController();
  final TextEditingController _objet = TextEditingController();
  final TextEditingController _justificatif = TextEditingController();
  final TextEditingController _montant = TextEditingController();

  /// Generee une fois a l'ouverture et rejouee telle quelle : une double
  /// reception n'agit qu'une fois (`CPT-BR.md` §1).
  final String _cleIdempotence = 'ctr-${DateTime.now().microsecondsSinceEpoch}';

  bool _initialise = false;
  String? _beneficiaire;
  DateTime? _echeance;
  String? _centreCout;
  bool _erreurNom = false;
  bool _erreurObjet = false;
  bool _erreurMontant = false;
  bool _enCours = false;
  String? _erreurCreation;

  @override
  void dispose() {
    _nomExterne.dispose();
    _objet.dispose();
    _justificatif.dispose();
    _montant.dispose();
    super.dispose();
  }

  /// Preremplit une seule fois, depuis ce que la source propose.
  void _preremplir(ContexteCreationObligation contexte) {
    if (_initialise) return;
    _initialise = true;
    _beneficiaire =
        contexte.beneficiairePropose ??
        (contexte.beneficiaires.isNotEmpty
            ? contexte.beneficiaires.first.id
            : _valeurExterne);
    _echeance = contexte.echeanceProposee;
    _centreCout = contexte.centreCoutPropose;
  }

  void _relire() => ref.invalidate(contexteCreationObligationProvider);

  Future<void> _choisirEcheance() async {
    final DateTime base = _echeance ?? DateTime.now();
    final DateTime? choisie = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(base.year - 1),
      lastDate: DateTime(base.year + 5),
    );
    if (choisie != null && mounted) {
      setState(() => _echeance = choisie);
    }
  }

  Future<void> _creer(ContexteCreationObligation contexte) async {
    final bool externe = _beneficiaire == _valeurExterne;
    final String objet = _objet.text.trim();
    final String nom = _nomExterne.text.trim();
    final int? mineur = lireMontantSaisi(_montant.text, contexte.devise);
    final DateTime? echeance = _echeance;
    setState(() {
      _erreurNom = externe && nom.isEmpty;
      _erreurObjet = objet.isEmpty;
      _erreurMontant = mineur == null;
      _erreurCreation = null;
    });
    if (_erreurNom ||
        _erreurObjet ||
        _erreurMontant ||
        mineur == null ||
        echeance == null) {
      return;
    }
    setState(() => _enCours = true);
    try {
      final String justificatif = _justificatif.text.trim();
      final ObligationContractuel creee = await ref
          .read(portObligationsContractuelsProvider)
          .creer(
            brouillon: BrouillonObligationContractuel(
              beneficiaireId: externe ? '' : (_beneficiaire ?? ''),
              objet: objet,
              montant: Montant(mineur, contexte.devise),
              echeance: echeance,
              justificatif: justificatif.isEmpty ? null : justificatif,
              centreCout: _centreCout,
              nouveauBeneficiaire: externe ? nom : null,
            ),
            cleIdempotence: _cleIdempotence,
          );
      ref.invalidate(obligationsContractuelsProvider);
      if (!mounted) return;
      // La tache est finie : on ouvre l'obligation creee, a la place du
      // formulaire, pour que le retour revienne a la liste.
      context.pushReplacement(
        Routes.comptableContractuelObligationPour(creee.id),
      );
    } on Object {
      if (mounted) {
        setState(() {
          _enCours = false;
          _erreurCreation = t.comptable.contractuels.erreurCreation;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = t.comptable.contractuels;
    final AsyncValue<ContexteCreationObligation> lecture = ref.watch(
      contexteCreationObligationProvider,
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final Object? erreur = lecture.hasError ? lecture.error : null;
    final bool echecHorsLigne =
        erreur != null && erreur is! CapaciteIndisponible && horsLigne;
    final ContexteCreationObligation? contexte = lecture.value;
    final bool formulaire = contexte != null && contexte.peutCreer;

    return PageShell(
      titre: c.nouvelle,
      onRetour: () => retourComptable(context, Routes.comptableContractuels),
      actionsCoquille: false,
      actions: formulaire
          ? _Pied(
              horsLigne: horsLigne,
              erreur: _erreurCreation,
              enCours: _enCours,
              onCreer: () => _creer(contexte),
            )
          : null,
      child: echecHorsLigne
          ? EtatSysteme(nature: NatureEtat.horsLigne, onAction: _relire)
          : BlocAsynchrone<ContexteCreationObligation>(
              valeur: lecture,
              squelette: const Skeleton.liste(lignes: 6),
              onReessayer: _relire,
              construire: (ContexteCreationObligation contexte) {
                if (!contexte.peutCreer) {
                  return _Refus(contexte: contexte);
                }
                _preremplir(contexte);
                return _Formulaire(
                  contexte: contexte,
                  nomExterne: _nomExterne,
                  objet: _objet,
                  justificatif: _justificatif,
                  montant: _montant,
                  beneficiaire: _beneficiaire,
                  echeance: _echeance,
                  centreCout: _centreCout,
                  erreurNom: _erreurNom,
                  erreurObjet: _erreurObjet,
                  erreurMontant: _erreurMontant,
                  onBeneficiaire: (String v) => setState(() {
                    _beneficiaire = v;
                    _erreurNom = false;
                  }),
                  onCentreCout: (String v) => setState(() => _centreCout = v),
                  onChangerEcheance: _choisirEcheance,
                );
              },
            ),
    );
  }
}

/// Le pied : l'erreur eventuelle et l'unique bouton plein. Hors ligne, le
/// bouton est retire et une phrase dit quoi faire (un bouton qui ne peut pas
/// aboutir n'est pas rendu).
class _Pied extends StatelessWidget {
  const _Pied({
    required this.horsLigne,
    required this.erreur,
    required this.enCours,
    required this.onCreer,
  });

  final bool horsLigne;
  final String? erreur;
  final bool enCours;
  final VoidCallback onCreer;

  @override
  Widget build(BuildContext context) {
    final c = t.comptable.contractuels;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    if (horsLigne) {
      return Text(
        c.horsLigneCreation,
        style: palette.inkMuted.applyTo(textes.bodyMedium ?? const TextStyle()),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (erreur != null) ...<Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              erreur!,
              style: palette.inkAlert.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vSm,
        ],
        ActionPrincipale(
          key: const ValueKey<String>('creer-obligation'),
          libelle: c.creer,
          enCours: enCours,
          onPress: onCreer,
        ),
      ],
    );
  }
}

/// Le compte ne peut pas creer : la raison rendue, sans formulaire.
class _Refus extends StatelessWidget {
  const _Refus({required this.contexte});

  final ContexteCreationObligation contexte;

  @override
  Widget build(BuildContext context) {
    final c = t.comptable.contractuels;
    final RaisonBlocage? raison = contexte.permissions.raisonDe(
      ActionFinance.creerObligation,
    );
    return EtatSysteme(
      nature: NatureEtat.accesRefuse,
      titre: raison == null ? null : libelleRaisonBlocage(raison),
      phrase: c.creationIndisponible,
      libelleAction: c.retourListe,
      onAction: () => retourComptable(context, Routes.comptableContractuels),
    );
  }
}

/// Le formulaire : prerempli, propose, puis saisi (K-57).
class _Formulaire extends StatelessWidget {
  const _Formulaire({
    required this.contexte,
    required this.nomExterne,
    required this.objet,
    required this.justificatif,
    required this.montant,
    required this.beneficiaire,
    required this.echeance,
    required this.centreCout,
    required this.erreurNom,
    required this.erreurObjet,
    required this.erreurMontant,
    required this.onBeneficiaire,
    required this.onCentreCout,
    required this.onChangerEcheance,
  });

  final ContexteCreationObligation contexte;
  final TextEditingController nomExterne;
  final TextEditingController objet;
  final TextEditingController justificatif;
  final TextEditingController montant;
  final String? beneficiaire;
  final DateTime? echeance;
  final String? centreCout;
  final bool erreurNom;
  final bool erreurObjet;
  final bool erreurMontant;
  final ValueChanged<String> onBeneficiaire;
  final ValueChanged<String> onCentreCout;
  final VoidCallback onChangerEcheance;

  @override
  Widget build(BuildContext context) {
    final c = t.comptable.contractuels;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final bool externe = beneficiaire == _valeurExterne;
    final DateTime? jour = echeance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          c.formIntro,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vXl,
        // 1. Prerempli : le beneficiaire propose, a changer au besoin.
        SectionHeader(titre: c.champBeneficiaire),
        ChoiceCardGroup(
          key: const ValueKey<String>('choix-beneficiaire'),
          autoriserSaisieLibre: false,
          valeurInitiale: beneficiaire == null
              ? null
              : ReponseChoix(valeurs: <String>{beneficiaire!}),
          options: <OptionChoix>[
            for (final IdentiteBeneficiaire b in contexte.beneficiaires)
              OptionChoix(valeur: b.id, libelle: b.nom, cle: ValueKey(b.id)),
            OptionChoix(
              valeur: _valeurExterne,
              libelle: c.beneficiaireExterne,
              description: c.beneficiaireExterneAide,
              cle: const ValueKey<String>('beneficiaire-externe'),
            ),
          ],
          onChange: (ReponseChoix r) {
            if (r.valeurs.isNotEmpty) onBeneficiaire(r.valeurs.first);
          },
        ),
        if (externe) ...<Widget>[
          Ecart.vMd,
          TextField(
            key: const ValueKey<String>('champ-nom-externe'),
            controller: nomExterne,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: c.champNomExterne,
              errorText: erreurNom ? c.erreurNomExterne : null,
              errorMaxLines: 3,
            ),
          ),
        ],
        Ecart.vXl,
        // 2. Prerempli : l'echeance proposee.
        SectionHeader(titre: c.champEcheance),
        if (jour != null)
          Text(
            dateComptable(jour),
            style: palette.inkStrong.applyTo(
              textes.titleMedium ?? const TextStyle(),
            ),
          ),
        Ecart.vSm,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ActionPrincipale(
            key: const ValueKey<String>('changer-echeance'),
            libelle: c.changerEcheance,
            niveau: NiveauAction.secondaire,
            compacte: true,
            pleineLargeur: false,
            onPress: onChangerEcheance,
          ),
        ),
        // 3. Propose : le centre de cout.
        if (contexte.centresCout.isNotEmpty) ...<Widget>[
          Ecart.vXl,
          SectionHeader(titre: c.champCentreCout),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final String centre in contexte.centresCout)
                FilterPill(
                  key: ValueKey<String>('centre-$centre'),
                  libelle: centre,
                  retenue: centre == centreCout,
                  onPress: () => onCentreCout(centre),
                ),
            ],
          ),
        ],
        Ecart.vXl,
        // 4. Saisi en dernier : l'objet, le justificatif, le montant.
        TextField(
          key: const ValueKey<String>('champ-objet'),
          controller: objet,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: c.champObjet,
            hintText: c.aideObjet,
            // 320 px, texte x2 : l'aide passe a la ligne au lieu d'une
            // ellipse (CPT-FUS).
            hintMaxLines:
                MediaQuery.textScalerOf(context).scale(AppSpacing.lg) /
                        AppSpacing.lg >=
                    AppGabarit.seuilTexteColonne
                ? 3
                : 1,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            errorText: erreurObjet ? c.erreurObjet : null,
            errorMaxLines: 3,
          ),
        ),
        Ecart.vLg,
        TextField(
          key: const ValueKey<String>('champ-justificatif'),
          controller: justificatif,
          // Un libelle compose (et non `labelText`, une seule ligne) : a
          // 320 px, texte x2, il passe a la ligne au lieu d'une ellipse
          // (CPT-FUS).
          decoration: InputDecoration(label: Text(c.champRefJustificatif)),
        ),
        Ecart.vLg,
        Text(c.deviseDe(devise: contexte.devise), style: attenue),
        Ecart.vXs,
        TextField(
          key: const ValueKey<String>('champ-montant'),
          controller: montant,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]')),
          ],
          style: AppTypography.tabulaire(textes.bodyLarge ?? const TextStyle()),
          decoration: InputDecoration(
            labelText: c.champMontantSaisi,
            suffixText: symboleDe(contexte.devise),
            helperText: c.aideMontant,
            helperMaxLines: 3,
            errorText: erreurMontant ? c.erreurMontant : null,
            errorMaxLines: 3,
          ),
        ),
      ],
    );
  }
}
