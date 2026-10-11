// DELEG-FIN-1 : le champ « exceptions » de la delegation (spec §21.2). Des
// reglages propres a une delegation : les coffres autorises (liste fermee
// des sept coffres), les beneficiaires exclus et un plafond par transaction
// **plus bas** que celui de la politique generale, jamais plus haut.
//
// Tout est applique par le serveur (CPT-BR-13), qui refuse un plafond plus
// haut ; l'ecran le dit avant d'envoyer, par politesse, sans decider. Rien
// n'est enregistre avant « Enregistrer » du panneau : l'editeur rend la liste
// des exceptions, le panneau la garde dans son brouillon.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/port_beneficiaires_paiement.dart';
import '../../../core/capacites/port_delegation_finance.dart';
import '../../../core/comptable/statuts_comptable.dart' show Coffre;
import '../../../core/finance/format_montant.dart';
import '../../../core/finance/montant.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/carte_groupee.dart';
import '../../../core/widgets/lien_fleche.dart';
import '../../../core/widgets/pastilles_comptable.dart' show libelleCoffre;
import '../../../core/widgets/setting_row.dart';
import 'composants_politique.dart';
import 'saisie_politique.dart';

/// Les beneficiaires que la Direction peut exclure : ceux de la source.
final FutureProvider<List<ProfilPaiementBeneficiaire>>
beneficiairesExclusProvider = FutureProvider<List<ProfilPaiementBeneficiaire>>(
  (Ref ref) => ref
      .watch(portBeneficiairesPaiementProvider)
      .liste(FiltreBeneficiaires.tout),
  retry: (int _, Object _) => null,
  dependencies: <ProviderOrFamily>[portBeneficiairesPaiementProvider],
);

/// Le resultat de l'editeur : l'exception gardee, ou retiree.
class ResultatException {
  /// Garde [exception].
  const ResultatException.garde(this.exception) : retiree = false;

  /// Retire l'exception.
  const ResultatException.retiree() : exception = null, retiree = true;

  /// L'exception gardee.
  final ExceptionDelegation? exception;

  /// Vrai quand l'exception est retiree.
  final bool retiree;
}

/// La liste des exceptions et ses gestes.
class ExceptionsDelegation extends StatelessWidget {
  /// Cree la section.
  const ExceptionsDelegation({
    required this.exceptions,
    required this.plafondGeneral,
    required this.actif,
    required this.onChange,
    super.key,
  });

  /// Les exceptions du brouillon.
  final List<ExceptionDelegation> exceptions;

  /// Le plafond par transaction de la politique generale, ou `null` (rien
  /// n'est delegue : une exception ne peut etre plus basse).
  final Montant? plafondGeneral;

  /// Faux pendant un enregistrement.
  final bool actif;

  /// Rend la liste modifiee.
  final ValueChanged<List<ExceptionDelegation>> onChange;

  /// La cle du bouton « Ajouter une exception ».
  static const Key cleAjouter = ValueKey<String>('deleg-exception-ajouter');

  /// La cle d'une exception.
  static Key cleDe(String id) => ValueKey<String>('deleg-exception-$id');

  Future<void> _editer(
    BuildContext context,
    ExceptionDelegation? depart,
  ) async {
    final ResultatException? r = await AppBottomSheet.ouvrir<ResultatException>(
      context,
      titre: t.comptable.direction.delegationPanneau.exceptionTitre,
      constructeur: (BuildContext _) =>
          FeuilleException(depart: depart, plafondGeneral: plafondGeneral),
    );
    if (r == null) return;
    final List<ExceptionDelegation> liste = <ExceptionDelegation>[
      ...exceptions,
    ];
    if (r.retiree) {
      liste.removeWhere((ExceptionDelegation e) => e.id == depart?.id);
    } else if (r.exception != null) {
      final int i = liste.indexWhere(
        (ExceptionDelegation e) => e.id == depart?.id,
      );
      if (depart != null && i >= 0) {
        liste[i] = r.exception!;
      } else {
        liste.add(r.exception!);
      }
    }
    onChange(liste);
  }

  @override
  Widget build(BuildContext context) {
    final d = t.comptable.direction.delegationPanneau;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(d.exceptionsTitre, style: textes.titleMedium),
        ),
        Ecart.vXs,
        Text(
          d.exceptionsDetail,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vMd,
        if (exceptions.isEmpty)
          Text(
            d.exceptionsVide,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          )
        else
          CarteGroupee(
            sections: <Widget>[
              for (final ExceptionDelegation e in exceptions)
                _LigneException(
                  exception: e,
                  actif: actif,
                  onModifier: () => _editer(context, e),
                ),
            ],
          ),
        Ecart.vMd,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ActionPrincipale(
            key: cleAjouter,
            libelle: d.exceptionAjouter,
            niveau: NiveauAction.secondaire,
            pleineLargeur: false,
            onPress: actif ? () => _editer(context, null) : () {},
          ),
        ),
      ],
    );
  }
}

class _LigneException extends StatelessWidget {
  const _LigneException({
    required this.exception,
    required this.actif,
    required this.onModifier,
  });

  final ExceptionDelegation exception;
  final bool actif;
  final VoidCallback onModifier;

  @override
  Widget build(BuildContext context) {
    final d = t.comptable.direction.delegationPanneau;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle cle = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final String coffres = exception.coffresAutorises.isEmpty
        ? d.exceptionCoffresAucun
        : exception.coffresAutorises.map(libelleCoffre).join(', ');
    final String exclus = exception.beneficiairesExclus.isEmpty
        ? d.exceptionExclusAucun
        : exception.beneficiairesExclus
              .map((BeneficiaireExclu b) => b.nom)
              .join(', ');
    final Montant? plafond = exception.plafondParTransaction;
    return Column(
      key: ExceptionsDelegation.cleDe(exception.id),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(exception.libelle, style: textes.titleSmall),
        Ecart.vXs,
        Text(
          '${d.exceptionCoffres} : $coffres'.replaceAll(' :', ' :'),
          style: cle,
        ),
        Text(
          '${d.exceptionExclus} : $exclus'.replaceAll(' :', ' :'),
          style: cle,
        ),
        Text(
          '${d.exceptionPlafond} : ${plafond == null ? d.exceptionPlafondGeneral : formaterMontant(plafond)}'
              .replaceAll(' :', ' :'),
          style: cle,
        ),
        Ecart.vXs,
        LienFleche(
          libelle: d.exceptionModifier(libelle: exception.libelle),
          alignerEnDebut: true,
          onPress: actif ? onModifier : () {},
        ),
      ],
    );
  }
}

/// L'editeur d'une exception, dans une feuille.
class FeuilleException extends ConsumerStatefulWidget {
  /// Cree l'editeur ; [depart] nul pour une nouvelle exception.
  const FeuilleException({
    required this.depart,
    required this.plafondGeneral,
    super.key,
  });

  /// L'exception a modifier, ou `null`.
  final ExceptionDelegation? depart;

  /// Le plafond par transaction general, ou `null`.
  final Montant? plafondGeneral;

  /// La cle de « Garder l'exception ».
  static const Key cleGarder = ValueKey<String>('deleg-exception-garder');

  /// La cle de « Retirer cette exception ».
  static const Key cleRetirer = ValueKey<String>('deleg-exception-retirer');

  /// La cle du champ de plafond.
  static const Key clePlafond = ValueKey<String>('deleg-exception-plafond');

  /// La cle d'un coffre.
  static Key cleCoffre(Coffre c) =>
      ValueKey<String>('deleg-exception-coffre-${c.name}');

  /// La cle d'un beneficiaire a exclure.
  static Key cleExclure(String id) =>
      ValueKey<String>('deleg-exception-exclure-$id');

  @override
  ConsumerState<FeuilleException> createState() => _FeuilleExceptionEtat();
}

class _FeuilleExceptionEtat extends ConsumerState<FeuilleException> {
  late final Set<Coffre> _coffres = <Coffre>{
    ...?widget.depart?.coffresAutorises,
  };
  late final List<BeneficiaireExclu> _exclus = <BeneficiaireExclu>[
    ...?widget.depart?.beneficiairesExclus,
  ];
  late final TextEditingController _plafond = TextEditingController(
    text: texteMontant(widget.depart?.plafondParTransaction),
  );
  bool _tente = false;

  String get _devise => widget.plafondGeneral?.devise ?? deviseDeLancement;

  @override
  void dispose() {
    _plafond.dispose();
    super.dispose();
  }

  /// Le plafond saisi : `null` vide, ou lisible ; `erreur` sinon.
  ({Montant? valeur, String? erreur}) _lirePlafond() {
    final d = t.comptable.direction.delegationPanneau;
    if (_plafond.text.trim().isEmpty) return (valeur: null, erreur: null);
    final Montant? m = lireMontant(_plafond.text, _devise);
    if (m == null) {
      return (valeur: null, erreur: t.comptable.direction.erreurMontant);
    }
    final Montant? general = widget.plafondGeneral;
    if (general == null) {
      return (valeur: null, erreur: d.exceptionPlafondSansGeneral);
    }
    if (m.mineur > general.mineur) {
      return (
        valeur: null,
        erreur: d.exceptionPlafondTropHaut(plafond: formaterMontant(general)),
      );
    }
    return (valeur: m, erreur: null);
  }

  void _garder() {
    final r = _lirePlafond();
    if (r.erreur != null) {
      setState(() => _tente = true);
      return;
    }
    Navigator.of(context).pop(
      ResultatException.garde(
        ExceptionDelegation(
          id: widget.depart?.id ?? 'nouvelle',
          libelle:
              widget.depart?.libelle ??
              t.comptable.direction.delegationPanneau.exceptionLibelleDefaut,
          coffresAutorises: _coffres,
          beneficiairesExclus: _exclus,
          plafondParTransaction: r.valeur,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = t.comptable.direction.delegationPanneau;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final r = _lirePlafond();
    final AsyncValue<List<ProfilPaiementBeneficiaire>> candidats = ref.watch(
      beneficiairesExclusProvider,
    );
    final Set<String> dejaExclus = _exclus
        .map((BeneficiaireExclu b) => b.id)
        .toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        GroupePolitique(
          titre: d.exceptionCoffres,
          detail: d.exceptionCoffresDetail,
          enfants: <Widget>[
            for (final Coffre c in Coffre.values)
              SettingRow(
                key: FeuilleException.cleCoffre(c),
                title: libelleCoffre(c),
                controle: Switch.adaptive(
                  value: _coffres.contains(c),
                  onChanged: (bool v) =>
                      setState(() => v ? _coffres.add(c) : _coffres.remove(c)),
                ),
              ),
          ],
        ),
        Ecart.vXxl,
        Semantics(
          header: true,
          child: Text(d.exceptionExclus, style: textes.titleMedium),
        ),
        Ecart.vSm,
        if (_exclus.isEmpty)
          Text(
            d.exceptionExclusAucun,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          )
        else
          for (final BeneficiaireExclu b in _exclus)
            LienFleche(
              libelle: d.exceptionRetirerExclu(nom: b.nom),
              alignerEnDebut: true,
              onPress: () => setState(
                () =>
                    _exclus.removeWhere((BeneficiaireExclu x) => x.id == b.id),
              ),
            ),
        Ecart.vMd,
        Text(
          d.exceptionExclure,
          style: palette.inkStrong.applyTo(
            textes.labelLarge ?? const TextStyle(),
          ),
        ),
        Ecart.vXs,
        candidats.when(
          data: (List<ProfilPaiementBeneficiaire> liste) {
            final List<ProfilPaiementBeneficiaire> possibles =
                <ProfilPaiementBeneficiaire>[
                  for (final ProfilPaiementBeneficiaire b in liste)
                    if (!dejaExclus.contains(b.identite.id)) b,
                ];
            if (possibles.isEmpty) {
              return Text(
                d.exceptionExclureAucun,
                style: palette.inkMuted.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final ProfilPaiementBeneficiaire b in possibles)
                  LienFleche(
                    key: FeuilleException.cleExclure(b.identite.id),
                    libelle: b.identite.nom,
                    alignerEnDebut: true,
                    onPress: () => setState(
                      () => _exclus.add(
                        BeneficiaireExclu(
                          id: b.identite.id,
                          nom: b.identite.nom,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (Object e, StackTrace _) => Text(
            e is CapaciteIndisponible
                ? d.exceptionExclureAucun
                : d.sortiesErreur,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vXxl,
        ChampPolitique(
          key: FeuilleException.clePlafond,
          libelle: d.exceptionPlafond,
          consequence: d.exceptionPlafondDetail,
          suffixe: symboleDe(_devise),
          indice: d.plafondIndice,
          controleur: _plafond,
          erreur: _tente ? r.erreur : null,
          onChange: () => setState(() {}),
        ),
        Ecart.vXxl,
        ActionPrincipale(
          key: FeuilleException.cleGarder,
          libelle: d.exceptionGarder,
          onPress: _garder,
        ),
        if (widget.depart != null) ...<Widget>[
          Ecart.vMd,
          Text(
            d.exceptionRetirerPhrase,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
          Ecart.vSm,
          ActionPrincipale(
            key: FeuilleException.cleRetirer,
            libelle: d.exceptionRetirer,
            niveau: NiveauAction.destructive,
            pleineLargeur: false,
            onPress: () =>
                Navigator.of(context).pop(const ResultatException.retiree()),
          ),
        ],
      ],
    );
  }
}
