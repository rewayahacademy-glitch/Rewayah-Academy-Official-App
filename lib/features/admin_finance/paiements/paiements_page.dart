// L'onglet « Paiements » de la Finance de la direction (passation du
// 17/10/2026, point 3 ; FAC-C-01 ; fiche ADM-PAI du catalogue de la
// direction). Un paiement recu hors de l'application (virement, especes)
// s'enregistre ici, attribue a un eleve.
//
// Rendu DANS le `PageShell` de `FinancePage`. Lit `PortPaiementsSaisis` :
// sans source, l'onglet dit « Pas encore disponible ». Cinq etats par
// `BlocPolitique` : chargement, contenu (« A regulariser » puis « A jour »),
// vide, erreur, hors ligne.
//
// La fiche de saisie (K-57) : eleve et devise deduits de la ligne touchee,
// montant prerempli avec le reste a payer rendu par la source, reference
// seule saisie (le numero du virement n'est connu que de la personne qui l'a
// recu). L'issue est celle que rend la source, jamais deduite : « Mois
// regle », « Il manque encore », « deja enregistre », refus, ou issue
// inconnue (D5) ; la cle d'idempotence est tiree une fois par fiche, donc
// « Reessayer » ne compte jamais deux fois le meme paiement.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;
import 'package:uuid/uuid.dart';

import '../../../core/capacites/port_paiements_saisis.dart';
import '../../../core/finance/finances_profil.dart';
import '../../../core/finance/format_montant.dart';
import '../../../core/finance/montant.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/bandeau_attention.dart';
import '../../../core/widgets/carte_lignes.dart';
import '../../../core/widgets/champ_etiquete.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/ligne_cle_valeur.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/setting_row.dart';
import '../../../core/widgets/status_pill.dart';
import '../reserve_delegation/composants_politique.dart' show BlocPolitique;

/// Les eleves que la saisie peut viser, rendus par la source.
final FutureProvider<List<ElevePourPaiement>> elevesPourPaiementProvider =
    FutureProvider<List<ElevePourPaiement>>(
      (Ref ref) => ref.watch(portPaiementsSaisisProvider).eleves(),
      // Pas de retentative silencieuse derriere « Reessayer ».
      retry: (int _, Object _) => null,
      dependencies: <ProviderOrFamily>[portPaiementsSaisisProvider],
    );

/// Le nom affiche d'un eleve : prenom et nom.
String nomElevePaiement(ElevePourPaiement e) {
  final String? nom = e.nom;
  return nom == null || nom.isEmpty ? e.prenom : '${e.prenom} $nom';
}

/// Le montant en unites mineures lu dans [saisie] pour [devise], ou `null`
/// si la saisie n'est pas un montant positif (« 50 », « 50,5 », « 50.50 »).
int? mineurDepuisSaisie(String saisie, String devise) {
  final String s = saisie.trim().replaceAll(' ', '').replaceAll(',', '.');
  final int decimales = decimalesDe(devise);
  final RegExp forme = decimales == 0
      ? RegExp(r'^\d{1,9}$')
      : RegExp('^\\d{1,9}(\\.\\d{1,$decimales})?\$');
  if (!forme.hasMatch(s)) return null;
  final List<String> parties = s.split('.');
  final String fraction = parties.length > 1
      ? parties[1].padRight(decimales, '0')
      : ''.padRight(decimales, '0');
  final int mineur = int.parse('${parties[0]}$fraction');
  return mineur > 0 ? mineur : null;
}

/// La saisie preremplie d'un montant (le reste a payer), vide s'il est nul.
String saisieDepuisMontant(Montant m) {
  if (m.mineur <= 0) return '';
  final int decimales = decimalesDe(m.devise);
  if (decimales == 0) return '${m.mineur}';
  final String chiffres = m.mineur.toString().padLeft(decimales + 1, '0');
  final String entier = chiffres.substring(0, chiffres.length - decimales);
  final String fraction = chiffres.substring(chiffres.length - decimales);
  return int.parse(fraction) == 0 ? entier : '$entier,$fraction';
}

/// Le corps de l'onglet « Paiements ».
class PaiementsBloc extends ConsumerWidget {
  /// Cree le corps.
  const PaiementsBloc({super.key});

  /// La cle de l'etat vide.
  static const Key cleVide = ValueKey<String>('paiements-vide');

  /// La cle de la ligne d'un eleve.
  static Key cleEleve(String id) => ValueKey<String>('paiements-$id');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          t.admin.finance.pai.sousTitre,
          style: palette.inkMuted.applyTo(
            textes.bodyLarge ?? const TextStyle(),
          ),
        ),
        Ecart.vXl,
        BlocPolitique<List<ElevePourPaiement>>(
          fournisseur: elevesPourPaiementProvider,
          construire: (List<ElevePourPaiement> eleves) =>
              _Liste(eleves: eleves),
        ),
      ],
    );
  }
}

class _Liste extends ConsumerWidget {
  const _Liste({required this.eleves});

  final List<ElevePourPaiement> eleves;

  Future<void> _ouvrir(
    BuildContext context,
    WidgetRef ref,
    ElevePourPaiement e,
  ) async {
    final bool change = await ouvrirSaisiePaiement(context, e);
    if (change) ref.invalidate(elevesPourPaiementProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = t.admin.finance.pai;
    if (eleves.isEmpty) {
      return EmptyState(
        key: PaiementsBloc.cleVide,
        message: p.videTitre,
        invitation: p.videPhrase,
        registre: RegistreVide.subi,
      );
    }
    final List<ElevePourPaiement> dus = <ElevePourPaiement>[
      for (final ElevePourPaiement e in eleves)
        if (e.resteAPayer.mineur > 0) e,
    ];
    final List<ElevePourPaiement> aJour = <ElevePourPaiement>[
      for (final ElevePourPaiement e in eleves)
        if (e.resteAPayer.mineur <= 0) e,
    ];
    Widget lignes(List<ElevePourPaiement> liste) => CarteLignes(
      lignes: <Widget>[
        for (final ElevePourPaiement e in liste)
          SettingRow(
            key: PaiementsBloc.cleEleve(e.profilId),
            title: nomElevePaiement(e),
            description: e.matricule,
            value: e.resteAPayer.mineur > 0
                ? formaterMontant(e.resteAPayer)
                : p.aJourValeur,
            lien: true,
            onPress: () => _ouvrir(context, ref, e),
          ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (dus.isNotEmpty) ...<Widget>[
          SectionHeader(titre: p.aRegulariser, compteur: dus.length),
          lignes(dus),
        ],
        if (dus.isNotEmpty && aJour.isNotEmpty) Ecart.vSection,
        if (aJour.isNotEmpty) ...<Widget>[
          SectionHeader(titre: p.aJour, compteur: aJour.length),
          lignes(aJour),
        ],
      ],
    );
  }
}

/// Ouvre la fiche de saisie pour [eleve] ; rend vrai si la liste est a
/// relire.
Future<bool> ouvrirSaisiePaiement(
  BuildContext context,
  ElevePourPaiement eleve,
) async {
  // La fiche lit le port de la portee de la page.
  final ProviderContainer portee = ProviderScope.containerOf(
    context,
    listen: false,
  );
  final bool? change = await AppBottomSheet.ouvrir<bool>(
    context,
    titre: t.admin.finance.pai.feuilleTitre(prenom: eleve.prenom),
    constructeur: (BuildContext _) => UncontrolledProviderScope(
      container: portee,
      child: FeuillePaiement(eleve: eleve),
    ),
  );
  return change ?? false;
}

enum _Phase { saisie, envoi, faite, refusee, inconnue }

/// Le contenu de la fiche de saisie d'un paiement.
class FeuillePaiement extends ConsumerStatefulWidget {
  /// Cree la fiche.
  const FeuillePaiement({required this.eleve, super.key});

  /// L'eleve vise.
  final ElevePourPaiement eleve;

  /// La cle du champ du montant.
  static const Key cleMontant = ValueKey<String>('paiement-montant');

  /// La cle du champ de la reference.
  static const Key cleReference = ValueKey<String>('paiement-reference');

  /// La cle de la ligne du reste a payer apres un paiement partiel.
  static const Key cleManque = ValueKey<String>('paiement-manque');

  /// La cle du bouton qui enregistre.
  static const Key cleEnregistrer = ValueKey<String>('paiement-enregistrer');

  @override
  ConsumerState<FeuillePaiement> createState() => _FeuillePaiementState();
}

class _FeuillePaiementState extends ConsumerState<FeuillePaiement> {
  /// Tiree une fois par fiche, rejouee telle quelle a chaque nouvel essai.
  final String _cle = const Uuid().v4();
  late final TextEditingController _montant = TextEditingController(
    text: saisieDepuisMontant(widget.eleve.resteAPayer),
  );
  final TextEditingController _reference = TextEditingController();

  _Phase _phase = _Phase.saisie;
  String? _erreurMontant;
  PaiementEnregistre? _resultat;
  MotifRefusPaiement? _refus;
  int? _mineurEnvoye;
  bool _change = false;

  String get _devise => widget.eleve.resteAPayer.devise;

  @override
  void dispose() {
    _montant.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (_phase == _Phase.envoi) return;
    // Un nouvel essai apres une issue inconnue rejoue la meme saisie : meme
    // cle, meme montant, jamais un second paiement.
    final int? mineur = _phase == _Phase.inconnue
        ? _mineurEnvoye
        : mineurDepuisSaisie(_montant.text, _devise);
    if (mineur == null) {
      setState(() => _erreurMontant = t.admin.finance.pai.erreurMontant);
      return;
    }
    final String reference = _reference.text.trim();
    setState(() {
      _phase = _Phase.envoi;
      _erreurMontant = null;
      _mineurEnvoye = mineur;
    });
    try {
      final PaiementEnregistre r = await ref
          .read(portPaiementsSaisisProvider)
          .enregistrer(
            profilId: widget.eleve.profilId,
            montant: Montant(mineur, _devise),
            cle: _cle,
            reference: reference.isEmpty ? null : reference,
          );
      if (!mounted) return;
      setState(() {
        _resultat = r;
        _change = true;
        _phase = _Phase.faite;
      });
    } on RefusPaiement catch (refus) {
      if (!mounted) return;
      setState(() {
        _refus = refus.motif;
        _phase = _Phase.refusee;
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
    final p = t.admin.finance.pai;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final bool saisie = _phase == _Phase.saisie || _phase == _Phase.envoi;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        LigneCleValeur(cle: p.eleve, valeur: nomElevePaiement(widget.eleve)),
        LigneCleValeur(
          cle: p.resteAPayer,
          valeur: widget.eleve.resteAPayer.mineur > 0
              ? formaterMontant(widget.eleve.resteAPayer)
              : p.aJourValeur,
          chiffres: true,
        ),
        Ecart.vLg,
        if (saisie) ...<Widget>[
          ChampEtiquete(
            key: FeuillePaiement.cleMontant,
            libelle: p.montantRecu(devise: _devise),
            controller: _montant,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            obligatoire: true,
            aide: _erreurMontant ?? p.montantAide,
            onChanged: (String _) {
              if (_erreurMontant != null) {
                setState(() => _erreurMontant = null);
              }
            },
          ),
          Ecart.vLg,
          ChampEtiquete(
            key: FeuillePaiement.cleReference,
            libelle: p.reference,
            controller: _reference,
            aide: p.referenceAide,
          ),
          Ecart.vLg,
        ],
        ..._issue(),
        Ecart.vXl,
        _actions(context, horsLigne: horsLigne),
      ],
    );
  }

  List<Widget> _issue() {
    final p = t.admin.finance.pai;
    final String prenom = widget.eleve.prenom;
    switch (_phase) {
      case _Phase.faite:
        final PaiementEnregistre r = _resultat!;
        final FinancesProfil? f = r.finance;
        final Montant? manque = f?.manque;
        final String message = !r.nouveau
            ? p.dejaEnregistre
            : f?.etat == EtatFinancier.finance
            ? p.moisRegle(prenom: prenom)
            : manque != null
            ? p.ilManque(prenom: prenom)
            : p.enregistreSansEtat(prenom: prenom);
        return <Widget>[
          BandeauAttention(
            titre: p.faitTitre,
            message: message,
            ton: TonEtat.succes,
          ),
          if (r.nouveau &&
              f?.etat != EtatFinancier.finance &&
              manque != null) ...<Widget>[
            Ecart.vMd,
            CarteLignes(
              lignes: <Widget>[
                SettingRow(
                  key: FeuillePaiement.cleManque,
                  title: p.resteAPayer,
                  value: formaterMontant(manque),
                ),
              ],
            ),
          ],
        ];
      case _Phase.refusee:
        return <Widget>[
          BandeauAttention(
            titre: p.refusTitre,
            message: _refus == MotifRefusPaiement.droits
                ? p.refusDroits
                : p.refusInvalide,
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

  Widget _actions(BuildContext context, {required bool horsLigne}) {
    final p = t.admin.finance.pai;
    final TextTheme textes = Theme.of(context).textTheme;
    final bool envoi = _phase == _Phase.envoi;
    final bool peutEnvoyer =
        _phase == _Phase.saisie || envoi || _phase == _Phase.inconnue;
    final List<Widget> boutons = <Widget>[];
    Widget? phrase;
    if (!peutEnvoyer) {
      boutons.add(
        ActionPrincipale(
          libelle: p.fermer,
          niveau: NiveauAction.tertiaire,
          onPress: () => Navigator.of(context).pop(_change),
        ),
      );
    } else if (horsLigne) {
      // Hors ligne : rien ne part ; une phrase, pas de bouton grise.
      phrase = Text(
        p.horsLigne,
        style: AppPalette.of(context).inkMuted
            .applyTo(textes.bodyMedium ?? const TextStyle()),
      );
      boutons.add(
        ActionPrincipale(
          libelle: p.fermer,
          niveau: NiveauAction.tertiaire,
          onPress: () => Navigator.of(context).pop(_change),
        ),
      );
    } else {
      boutons
        ..add(
          ActionPrincipale(
            libelle: p.annuler,
            niveau: NiveauAction.tertiaire,
            onPress: envoi ? null : () => Navigator.of(context).pop(_change),
          ),
        )
        ..add(
          ActionPrincipale(
            key: FeuillePaiement.cleEnregistrer,
            libelle: _phase == _Phase.inconnue
                ? p.reessayer
                : p.enregistrer(prenom: widget.eleve.prenom),
            enCours: envoi,
            onPress: _enregistrer,
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
