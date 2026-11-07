// REVENUS-VERITE point 5 (pilote, 06/11/2026 ; arbitrage du garde-cap) :
// « Autres revenus » dans le detail de la paie d'un enseignant pour un mois,
// sous Finance > Paie des enseignants (direction) et Paiements (comptabilite).
// Aucun ecran nouveau : une carte de plus dans le detail existant.
//
// La carte lit `autres_revenus_lister` : les lignes du mois (aide Internet,
// primes, missions) et la capacite `peutAttribuer` rendue par le serveur (la
// direction seule). Avec elle : « Attribuer une prime, une mission ou l'aide
// Internet » (feuille), et « Annuler » sur chaque ligne (confirmation ; la
// ligne reste dans l'historique, sans etre versee). Sans elle (comptabilite),
// la carte se lit seulement. Apres chaque geste, le detail et le releve sont
// relus : le total a payer est celui du serveur, jamais additionne ici.
//
// Etats : chargement (squelette), contenu, vide (« Aucun autre revenu pour ce
// mois »), indisponible (serveur d'avant le lot : la carte n'est pas
// rendue), erreur (phrase et « Reessayer »).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/port_autres_revenus.dart';
import '../../../core/finance/format_montant.dart';
import '../../../core/finance/montant.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/champ_etiquete.dart';
import '../../../core/widgets/choice_card_group.dart';
import '../../../core/widgets/confirm_destructive.dart';
import '../../../core/widgets/lien_fleche.dart';
import '../../../core/widgets/montant_sensible.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton.dart';
import '../../admin_finance/paiements/paiements_page.dart'
    show mineurDepuisSaisie, saisieDepuisMontant;

/// Les autres revenus d'un enseignant pour un mois.
final autresRevenusProvider = FutureProvider.autoDispose
    .family<AutresRevenusMois, ({String enseignant, DateTime mois})>(
      (Ref ref, ({String enseignant, DateTime mois}) cle) =>
          ref.watch(portAutresRevenusProvider).lister(cle.enseignant, cle.mois),
    );

/// La carte « Autres revenus » du detail de paie.
class CarteAutresRevenus extends ConsumerWidget {
  /// Cree la carte pour [enseignantId] et [mois] ; [nom] est celui de
  /// l'enseignant (titre de la feuille) ; [onChange] relit le detail.
  const CarteAutresRevenus({
    required this.enseignantId,
    required this.mois,
    required this.nom,
    required this.onChange,
    super.key,
  });

  /// L'enseignant.
  final String enseignantId;

  /// Le premier jour du mois.
  final DateTime mois;

  /// Le nom de l'enseignant.
  final String nom;

  /// Relit le detail et le releve apres un geste.
  final VoidCallback onChange;

  /// La cle de la carte.
  static const Key cle = ValueKey<String>('paie-autres-revenus');

  /// La cle du lien « Attribuer ».
  static const Key cleAttribuer = ValueKey<String>('paie-autres-attribuer');

  /// La cle d'une ligne.
  static Key cleLigne(String id) => ValueKey<String>('paie-autre-$id');

  /// La cle du lien « Annuler » d'une ligne.
  static Key cleAnnuler(String id) =>
      ValueKey<String>('paie-autre-annuler-$id');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ({String enseignant, DateTime mois}) id = (
      enseignant: enseignantId,
      mois: mois,
    );
    final AsyncValue<AutresRevenusMois> valeur = ref.watch(
      autresRevenusProvider(id),
    );
    // Un serveur d'avant le lot : rien a montrer, la carte n'existe pas.
    if (valeur.hasError && valeur.error is CapaciteIndisponible) {
      return const SizedBox.shrink();
    }
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final a = t.admin.finance.autres;
    void relire() {
      ref.invalidate(autresRevenusProvider(id));
      onChange();
    }

    final Widget corps;
    if (valeur.hasValue) {
      final AutresRevenusMois m = valeur.requireValue;
      corps = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (m.lignes.isEmpty)
            Text(
              a.vide,
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            )
          else
            for (final AutreRevenu l in m.lignes) ...<Widget>[
              // Le montant suit « Montants masques » de la page, comme les
              // lignes du calcul (`MontantSensible`).
              Padding(
                key: cleLigne(l.id),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            l.libelle,
                            style: palette.inkStrong.applyTo(
                              textes.bodyLarge ?? const TextStyle(),
                            ),
                          ),
                          Text(
                            libelleNatureAutreRevenu(l.nature),
                            style: palette.inkMuted.applyTo(
                              textes.bodySmall ?? const TextStyle(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Ecart.hMd,
                    MontantSensible(l.montant),
                  ],
                ),
              ),
              if (m.peutAttribuer)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: LienFleche(
                    key: cleAnnuler(l.id),
                    libelle: a.annuler(libelle: l.libelle),
                    legende: true,
                    onPress: () => _annuler(context, ref, l, relire),
                  ),
                ),
            ],
          if (m.peutAttribuer) ...<Widget>[
            Ecart.vMd,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: LienFleche(
                key: cleAttribuer,
                libelle: a.attribuer,
                onPress: () async {
                  final bool fait = await ouvrirAttribution(
                    context,
                    enseignantId: enseignantId,
                    mois: mois,
                    nom: nom,
                    aideInternetPolitique: m.aideInternetPolitique,
                    devise: m.devise,
                  );
                  if (fait) relire();
                },
              ),
            ),
          ],
        ],
      );
    } else if (valeur.hasError) {
      corps = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            a.erreurLecture,
            style: palette.inkAlert.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vSm,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: LienFleche(
              libelle: t.commun.reessayer,
              onPress: () => ref.invalidate(autresRevenusProvider(id)),
            ),
          ),
        ],
      );
    } else {
      corps = const Skeleton.texte(lignes: 2);
    }
    return AppCard(
      key: cle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SectionHeader(titre: a.titre),
          Text(
            a.intro,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
          Ecart.vSm,
          corps,
        ],
      ),
    );
  }

  Future<void> _annuler(
    BuildContext context,
    WidgetRef ref,
    AutreRevenu l,
    VoidCallback relire,
  ) async {
    final a = t.admin.finance.autres;
    final bool oui = await ConfirmDestructive.demander(
      context,
      question: a.annulerTitre,
      consequence: a.annulerPhrase(libelle: l.libelle),
      libelleConfirmer: a.annulerOui,
      libelleAnnuler: a.annulerNon,
      annulerParDefaut: true,
    );
    if (!oui) return;
    try {
      await ref.read(portAutresRevenusProvider).annuler(l.id);
      relire();
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)
            ?.showSnackBar(SnackBar(content: Text(a.erreurAnnulation)));
      }
    }
  }
}

/// Ouvre la feuille d'attribution ; vrai si un autre revenu a ete attribue.
Future<bool> ouvrirAttribution(
  BuildContext context, {
  required String enseignantId,
  required DateTime mois,
  required String nom,
  required String devise,
  Montant? aideInternetPolitique,
}) async {
  final ProviderContainer portee = ProviderScope.containerOf(
    context,
    listen: false,
  );
  final bool? fait = await AppBottomSheet.ouvrir<bool>(
    context,
    titre: t.admin.finance.autres.feuilleTitre(nom: nom),
    constructeur: (BuildContext _) => UncontrolledProviderScope(
      container: portee,
      child: FeuilleAttribution(
        enseignantId: enseignantId,
        mois: mois,
        devise: devise,
        aideInternetPolitique: aideInternetPolitique,
      ),
    ),
  );
  return fait ?? false;
}

/// La feuille « Attribuer un autre revenu ».
class FeuilleAttribution extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleAttribution({
    required this.enseignantId,
    required this.mois,
    required this.devise,
    this.aideInternetPolitique,
    super.key,
  });

  /// L'enseignant.
  final String enseignantId;

  /// Le mois.
  final DateTime mois;

  /// La devise du mois.
  final String devise;

  /// L'aide Internet de la politique, proposee ; nulle si non fixee.
  final Montant? aideInternetPolitique;

  /// La cle du champ du libelle.
  static const Key cleLibelle = ValueKey<String>('autre-revenu-libelle');

  /// La cle du champ du montant.
  static const Key cleMontant = ValueKey<String>('autre-revenu-montant');

  /// La cle du bouton qui attribue.
  static const Key cleConfirmer = ValueKey<String>('autre-revenu-confirmer');

  @override
  ConsumerState<FeuilleAttribution> createState() => _FeuilleAttributionEtat();
}

class _FeuilleAttributionEtat extends ConsumerState<FeuilleAttribution> {
  /// Tiree une fois par feuille : un double toucher ou « Reessayer » apres une
  /// coupure n'attribue jamais deux fois.
  final String _cle = const Uuid().v4();
  final TextEditingController _libelle = TextEditingController();
  final TextEditingController _montant = TextEditingController();
  NatureAutreRevenu _nature = NatureAutreRevenu.prime;
  String? _erreurLibelle;
  String? _erreurMontant;
  String? _erreurEnvoi;
  bool _envoi = false;

  @override
  void dispose() {
    _libelle.dispose();
    _montant.dispose();
    super.dispose();
  }

  void _choisir(NatureAutreRevenu n) {
    setState(() {
      _nature = n;
      // L'aide Internet : son nom et le montant de la politique, proposes
      // (deduit > choisi > saisi, K-57) ; la direction peut les changer.
      if (n == NatureAutreRevenu.aideInternet) {
        if (_libelle.text.trim().isEmpty) {
          _libelle.text = t.commun.autresRevenus.aideInternet;
        }
        final Montant? propose = widget.aideInternetPolitique;
        if (propose != null && _montant.text.trim().isEmpty) {
          _montant.text = saisieDepuisMontant(propose);
        }
      } else if (_libelle.text == t.commun.autresRevenus.aideInternet) {
        _libelle.clear();
      }
      _erreurLibelle = null;
      _erreurEnvoi = null;
      // Rien a dire tant que rien n'est saisi.
      if (_montant.text.trim().isEmpty) _erreurMontant = null;
    });
  }

  Future<void> _attribuer() async {
    if (_envoi) return;
    final a = t.admin.finance.autres;
    final String libelle = _libelle.text.trim();
    final int? mineur = mineurDepuisSaisie(_montant.text, widget.devise);
    setState(() {
      _erreurLibelle = libelle.isEmpty || libelle.length > 120
          ? a.erreurLibelle
          : null;
      _erreurMontant = mineur == null ? a.erreurMontant : null;
      _erreurEnvoi = null;
    });
    if (_erreurLibelle != null || _erreurMontant != null || mineur == null) {
      return;
    }
    setState(() => _envoi = true);
    try {
      await ref
          .read(portAutresRevenusProvider)
          .attribuer(
            enseignantId: widget.enseignantId,
            mois: widget.mois,
            nature: _nature,
            libelle: libelle,
            montantMineur: mineur,
            cle: _cle,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on Object {
      if (mounted) setState(() => _erreurEnvoi = a.erreurEnvoi);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = t.admin.finance.autres;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final int? mineur = mineurDepuisSaisie(_montant.text, widget.devise);
    final Montant? politique = widget.aideInternetPolitique;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(a.feuilleIntro, style: textes.bodyMedium),
        Ecart.vLg,
        Text(a.natureChoix, style: textes.titleSmall),
        Ecart.vSm,
        ChoiceCardGroup(
          autoriserSaisieLibre: false,
          valeurInitiale: ReponseChoix(
            valeurs: <String>{natureAutreRevenuServeur(_nature)},
          ),
          options: <OptionChoix>[
            OptionChoix(
              valeur: natureAutreRevenuServeur(NatureAutreRevenu.prime),
              libelle: t.commun.autresRevenus.prime,
              description: a.naturePrimeDetail,
            ),
            OptionChoix(
              valeur: natureAutreRevenuServeur(NatureAutreRevenu.mission),
              libelle: t.commun.autresRevenus.mission,
              description: a.natureMissionDetail,
            ),
            OptionChoix(
              valeur: natureAutreRevenuServeur(NatureAutreRevenu.aideInternet),
              libelle: t.commun.autresRevenus.aideInternet,
              description: politique == null
                  ? a.natureAideInternetDetail
                  : a.natureAideInternetPolitique(
                      montant: formaterMontant(politique),
                    ),
            ),
          ],
          onChange: (ReponseChoix r) {
            if (r.valeurs.isEmpty) return;
            _choisir(natureAutreRevenuJson(r.valeurs.first));
          },
        ),
        Ecart.vLg,
        ChampEtiquete(
          key: FeuilleAttribution.cleLibelle,
          libelle: a.libelle,
          controller: _libelle,
          obligatoire: true,
          aide: _erreurLibelle ?? a.libelleAide,
        ),
        Ecart.vLg,
        ChampEtiquete(
          key: FeuilleAttribution.cleMontant,
          libelle: a.montant(devise: widget.devise),
          controller: _montant,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          obligatoire: true,
          aide: _erreurMontant ?? a.montantAide,
          onChanged: (_) => setState(() => _erreurMontant = null),
        ),
        if (_erreurEnvoi case final String e) ...<Widget>[
          Ecart.vMd,
          Text(
            e,
            style: palette.inkAlert.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
        Ecart.vXl,
        ActionPrincipale(
          key: FeuilleAttribution.cleConfirmer,
          libelle: mineur == null
              ? a.confirmerSansMontant
              : a.confirmer(
                  montant: formaterMontant(Montant(mineur, widget.devise)),
                ),
          enCours: _envoi,
          onPress: _attribuer,
        ),
      ],
    );
  }
}
