// Lot (A), 02/11/2026 : « Accès offert » et « Prix spécial », dans l'onglet
// « Paiements » de la Finance de la direction.
//
// Demande du directeur (02/11) : certains eleves ne paient pas et gardent
// l'acces, d'autres ont un prix special (les inscrits actuels) ; « coder en
// dur sera catastrophique ». La direction saisit tout ici, eleve par eleve :
// la nature, la reduction ou le prix par mois hors taxes (prix special), le
// dernier mois couvert et la raison. L'ecran ne calcule rien : le serveur verifie, la facture du mois
// applique la remise (ligne « bourse » existante).
//
// Deux gestes : accorder (depuis la fiche de paiement d'un eleve, ou la
// liste n'a pas de selecteur d'eleve en plus) et retirer (depuis la liste des
// remises actives, en tete de l'onglet).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../../../core/capacites/port_tarifs_particuliers.dart';
import '../../../core/finance/format_montant.dart';
import '../../../core/finance/montant.dart';
import '../../../core/i18n/elision.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/bandeau_attention.dart';
import '../../../core/widgets/carte_lignes.dart';
import '../../../core/widgets/champ_etiquete.dart';
import '../../../core/widgets/controle_segmente.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/selecteur_mois.dart';
import '../../../core/widgets/setting_row.dart';
import '../../../core/widgets/status_pill.dart';
import '../reserve_delegation/composants_politique.dart' show BlocPolitique;
import 'paiements_page.dart' show mineurDepuisSaisie;

/// Les remises actives, rendues par la source.
final FutureProvider<List<TarifParticulier>> tarifsParticuliersProvider =
    FutureProvider<List<TarifParticulier>>(
      (Ref ref) => ref.watch(portTarifsParticuliersProvider).liste(),
      retry: (int _, Object _) => null,
      dependencies: <ProviderOrFamily>[portTarifsParticuliersProvider],
    );

/// La valeur d'une remise : « Accès offert jusqu'à fin janvier 2027 »,
/// « Moins 35 % jusqu'à fin janvier 2027 », « 40,00 $ par mois jusqu'à fin
/// janvier 2027 ».
String valeurTarif(TarifParticulier r) {
  final String mois = SelecteurMois.enMots(r.moisFin);
  final Montant? montant = r.montantMensuel;
  final int pourMille = r.pourMille ?? 0;
  if (montant != null) {
    return t.admin.finance.tarifs.valeurMontant(
      montant: formaterMontant(montant),
      mois: mois,
    );
  }
  return r.nature == NatureTarif.accesOffert || pourMille >= 1000
      ? t.admin.finance.tarifs.valeurOffert(mois: mois)
      : LibellesGroupe.insecable(
          t.admin.finance.tarifs.valeurPrix(
            pourcent: _pourcent(pourMille),
            mois: mois,
          ),
        );
}

String _pourcent(int pourMille) => pourMille % 10 == 0
    ? '${pourMille ~/ 10}'
    : '${pourMille ~/ 10},${pourMille % 10}';

/// Les mois qu'on peut choisir comme fin : le mois de [maintenant] et les
/// 23 suivants (premier jour de chaque mois).
List<DateTime> moisDeFin(DateTime maintenant) => <DateTime>[
  for (int i = 0; i < 24; i++) DateTime(maintenant.year, maintenant.month + i),
];

/// La reduction saisie, en pour mille, ou `null` si ce n'est pas un nombre
/// entier de 1 a 99.
int? pourMilleDepuisSaisie(String saisie) {
  final int? n = int.tryParse(saisie.trim().replaceAll('%', '').trim());
  if (n == null || n < 1 || n > 99) return null;
  return n * 10;
}

/// La liste des remises actives, en tete de l'onglet « Paiements ».
class BlocTarifsParticuliers extends ConsumerWidget {
  /// Cree le bloc.
  const BlocTarifsParticuliers({super.key});

  /// La cle de la phrase « aucune remise ».
  static const Key cleVide = ValueKey<String>('tarifs-vide');

  /// La cle de la ligne d'une remise.
  static Key cleLigne(String profilId) => ValueKey<String>('tarifs-$profilId');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final p = t.admin.finance.tarifs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SectionHeader(titre: p.titre),
        Ecart.vSm,
        Text(
          p.phrase,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vMd,
        BlocPolitique<List<TarifParticulier>>(
          fournisseur: tarifsParticuliersProvider,
          construire: (List<TarifParticulier> remises) {
            final List<TarifParticulier> particulieres = <TarifParticulier>[
              for (final TarifParticulier r in remises)
                if (r.nature != NatureTarif.bourse) r,
            ];
            if (particulieres.isEmpty) {
              return Text(
                p.vide,
                key: cleVide,
                style: palette.inkMuted.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              );
            }
            return CarteLignes(
              lignes: <Widget>[
                for (final TarifParticulier r in particulieres)
                  SettingRow(
                    key: cleLigne(r.profilId),
                    title: r.nom == null || r.nom!.isEmpty
                        ? r.prenom
                        : '${r.prenom} ${r.nom}',
                    description: r.motif,
                    value: valeurTarif(r),
                    lien: true,
                    onPress: () async {
                      final bool change = await ouvrirRetraitTarif(context, r);
                      if (change) ref.invalidate(tarifsParticuliersProvider);
                    },
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Ouvre la fiche « Accès offert ou prix spécial » pour un eleve ; rend vrai
/// si la liste des remises est a relire. [devise] : celle des factures de
/// l'eleve, pour un prix special en montant.
Future<bool> ouvrirTarifParticulier(
  BuildContext context, {
  required String profilId,
  required String prenom,
  required String devise,
}) async {
  final ProviderContainer portee = ProviderScope.containerOf(
    context,
    listen: false,
  );
  final bool? change = await AppBottomSheet.ouvrir<bool>(
    context,
    titre: t.admin.finance.tarifs.feuilleTitre(prenom: prenom),
    constructeur: (BuildContext _) => UncontrolledProviderScope(
      container: portee,
      child: FeuilleTarifParticulier(
        profilId: profilId,
        prenom: prenom,
        devise: devise,
      ),
    ),
  );
  if (change ?? false) portee.invalidate(tarifsParticuliersProvider);
  return change ?? false;
}

/// Ouvre la fiche de retrait d'une remise ; rend vrai si elle est retiree.
Future<bool> ouvrirRetraitTarif(
  BuildContext context,
  TarifParticulier r,
) async {
  final ProviderContainer portee = ProviderScope.containerOf(
    context,
    listen: false,
  );
  final bool? change = await AppBottomSheet.ouvrir<bool>(
    context,
    titre: t.admin.finance.tarifs.retirerTitre(prenom: r.prenom),
    constructeur: (BuildContext _) => UncontrolledProviderScope(
      container: portee,
      child: FeuilleTarifParticulier(
        profilId: r.profilId,
        prenom: r.prenom,
        retrait: r,
      ),
    ),
  );
  return change ?? false;
}

enum _Phase { saisie, envoi, faite, refusee, inconnue }

/// Comment se dit un prix special.
enum FormePrix {
  /// Une reduction en pourcentage du prix normal.
  pourcentage,

  /// Le prix du mois, hors taxes.
  montant,
}

/// La fiche : accorder (sans [retrait]) ou retirer (avec [retrait]).
class FeuilleTarifParticulier extends ConsumerStatefulWidget {
  /// Cree la fiche.
  const FeuilleTarifParticulier({
    required this.profilId,
    required this.prenom,
    this.devise,
    this.retrait,
    super.key,
  });

  /// L'eleve.
  final String profilId;

  /// Son prenom.
  final String prenom;

  /// La devise des factures de l'eleve ; nulle : le prix special ne se dit
  /// qu'en pourcentage.
  final String? devise;

  /// La remise a retirer ; nulle : la fiche accorde.
  final TarifParticulier? retrait;

  /// La cle du champ du prix par mois.
  static const Key cleMontant = ValueKey<String>('tarif-montant');

  /// La cle du champ de la reduction.
  static const Key cleReduction = ValueKey<String>('tarif-reduction');

  /// La cle du champ de la raison.
  static const Key cleRaison = ValueKey<String>('tarif-raison');

  /// La cle du bouton qui envoie.
  static const Key cleEnvoyer = ValueKey<String>('tarif-envoyer');

  @override
  ConsumerState<FeuilleTarifParticulier> createState() =>
      _FeuilleTarifParticulierState();
}

class _FeuilleTarifParticulierState
    extends ConsumerState<FeuilleTarifParticulier> {
  final TextEditingController _reduction = TextEditingController();
  final TextEditingController _montant = TextEditingController();
  FormePrix _forme = FormePrix.pourcentage;
  String? _erreurMontant;
  final TextEditingController _raison = TextEditingController();
  late final List<DateTime> _mois = moisDeFin(DateTime.now());
  NatureTarif _nature = NatureTarif.accesOffert;
  late DateTime _moisFin = _mois[2];
  _Phase _phase = _Phase.saisie;
  String? _erreurReduction;
  String? _erreurRaison;
  MotifRefusTarif? _refus;

  bool get _retrait => widget.retrait != null;

  @override
  void dispose() {
    _reduction.dispose();
    _montant.dispose();
    _raison.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (_phase == _Phase.envoi) return;
    final p = t.admin.finance.tarifs;
    final String raison = _raison.text.trim();
    final bool prix = !_retrait && _nature == NatureTarif.prixSpecial;
    final String? devise = widget.devise;
    final bool enMontant =
        prix && _forme == FormePrix.montant && devise != null;
    final int? pourMille = prix && !enMontant
        ? pourMilleDepuisSaisie(_reduction.text)
        : null;
    final int? mineur = enMontant
        ? mineurDepuisSaisie(_montant.text, devise)
        : null;
    setState(() {
      _erreurRaison = raison.isEmpty ? p.erreurRaison : null;
      _erreurReduction = prix && !enMontant && pourMille == null
          ? p.erreurReduction
          : null;
      _erreurMontant = enMontant && mineur == null ? p.erreurMontant : null;
    });
    if (_erreurRaison != null ||
        _erreurReduction != null ||
        _erreurMontant != null) {
      return;
    }
    setState(() => _phase = _Phase.envoi);
    final PortTarifsParticuliers port = ref.read(
      portTarifsParticuliersProvider,
    );
    try {
      if (_retrait) {
        await port.retirer(profilId: widget.profilId, motif: raison);
      } else {
        await port.accorder(
          profilId: widget.profilId,
          nature: _nature,
          moisFin: _moisFin,
          motif: raison,
          pourMille: pourMille,
          montant: mineur == null || devise == null
              ? null
              : Montant(mineur, devise),
        );
      }
      if (!mounted) return;
      setState(() => _phase = _Phase.faite);
    } on RefusTarif catch (refus) {
      if (!mounted) return;
      setState(() {
        _refus = refus.motif;
        _phase = _Phase.refusee;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _phase = _Phase.inconnue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = t.admin.finance.tarifs;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool saisie = _phase == _Phase.saisie || _phase == _Phase.envoi;
    final TarifParticulier? r = widget.retrait;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (saisie && r != null) ...<Widget>[
          Text(valeurTarif(r), style: textes.titleMedium ?? const TextStyle()),
          Ecart.vSm,
          Text(
            p.retirerPhrase(dePrenom: deDevant(widget.prenom)),
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vLg,
        ],
        if (saisie && r == null) ...<Widget>[
          ControleSegmente<NatureTarif>(
            segments: <Segment<NatureTarif>>[
              Segment<NatureTarif>(
                valeur: NatureTarif.accesOffert,
                libelle: p.choixOffert,
              ),
              Segment<NatureTarif>(
                valeur: NatureTarif.prixSpecial,
                libelle: p.choixPrix,
              ),
            ],
            valeur: _nature,
            onChange: (NatureTarif n) => setState(() => _nature = n),
          ),
          Ecart.vLg,
          if (_nature == NatureTarif.accesOffert)
            Text(
              p.offertAide(prenom: widget.prenom),
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            )
          else ...<Widget>[
            if (widget.devise != null) ...<Widget>[
              ControleSegmente<FormePrix>(
                segments: <Segment<FormePrix>>[
                  Segment<FormePrix>(
                    valeur: FormePrix.pourcentage,
                    libelle: p.choixPourcentage,
                  ),
                  Segment<FormePrix>(
                    valeur: FormePrix.montant,
                    libelle: p.choixMontant,
                  ),
                ],
                valeur: _forme,
                onChange: (FormePrix f) => setState(() => _forme = f),
              ),
              Ecart.vLg,
            ],
            if (_forme == FormePrix.montant && widget.devise != null)
              ChampEtiquete(
                key: FeuilleTarifParticulier.cleMontant,
                libelle: p.montant(devise: widget.devise!),
                controller: _montant,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                obligatoire: true,
                aide: _erreurMontant ?? p.montantAide,
              )
            else
              ChampEtiquete(
                key: FeuilleTarifParticulier.cleReduction,
                libelle: p.reduction,
                controller: _reduction,
                keyboardType: TextInputType.number,
                obligatoire: true,
                aide: _erreurReduction ?? p.reductionAide,
              ),
          ],
          Ecart.vLg,
          Text(p.moisFin, style: textes.titleSmall ?? const TextStyle()),
          Ecart.vSm,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SelecteurMois(
              mois: _mois,
              choisi: _moisFin,
              onChoix: (DateTime m) => setState(() => _moisFin = m),
            ),
          ),
          Ecart.vLg,
        ],
        if (saisie) ...<Widget>[
          ChampEtiquete(
            key: FeuilleTarifParticulier.cleRaison,
            libelle: p.raison,
            controller: _raison,
            obligatoire: true,
            aide: _erreurRaison ?? p.raisonAide,
          ),
          Ecart.vLg,
        ],
        ..._issue(),
        Ecart.vXl,
        _actions(context),
      ],
    );
  }

  List<Widget> _issue() {
    final p = t.admin.finance.tarifs;
    switch (_phase) {
      case _Phase.faite:
        return <Widget>[
          BandeauAttention(
            titre: _retrait ? p.retireTitre : p.faitTitre,
            message: _retrait
                ? p.retirerPhrase(dePrenom: deDevant(widget.prenom))
                : p.faitPhrase(dePrenom: deDevant(widget.prenom)),
            ton: TonEtat.succes,
          ),
        ];
      case _Phase.refusee:
        return <Widget>[
          BandeauAttention(
            titre: p.refusTitre,
            message: switch (_refus) {
              MotifRefusTarif.droits => p.refusDroits,
              MotifRefusTarif.dejaActive => p.refusDejaActive(
                prenom: widget.prenom,
              ),
              MotifRefusTarif.montantTropHaut => p.refusMontant(
                dePrenom: deDevant(widget.prenom),
              ),
              _ => p.refusInvalide,
            },
            ton: TonEtat.alerte,
          ),
        ];
      case _Phase.inconnue:
        return <Widget>[
          BandeauAttention(
            titre: p.inconnuTitre,
            message: p.inconnuPhrase,
            ton: TonEtat.alerte,
          ),
        ];
      case _Phase.saisie:
      case _Phase.envoi:
        return const <Widget>[];
    }
  }

  Widget _actions(BuildContext context) {
    final p = t.admin.finance.tarifs;
    final pai = t.admin.finance.pai;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final bool envoi = _phase == _Phase.envoi;
    final bool fini = _phase == _Phase.faite;
    final List<Widget> boutons = <Widget>[
      ActionPrincipale(
        libelle: fini || _phase == _Phase.refusee || _phase == _Phase.inconnue
            ? pai.fermer
            : pai.annuler,
        niveau: NiveauAction.tertiaire,
        onPress: envoi ? null : () => Navigator.of(context).pop(fini),
      ),
      if ((_phase == _Phase.saisie || envoi) && !horsLigne)
        ActionPrincipale(
          key: FeuilleTarifParticulier.cleEnvoyer,
          libelle: _retrait ? p.retirer : p.enregistrer,
          enCours: envoi,
          onPress: _envoyer,
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (horsLigne && !fini) ...<Widget>[
          Text(
            pai.horsLigne,
            style: AppPalette.of(context).inkMuted.applyTo(
              Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vMd,
        ],
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
