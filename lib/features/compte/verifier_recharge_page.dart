import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_finance_foyer.dart';
import '../../core/finance/format_montant.dart';
import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/ecran_resultat.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/resultat_par_profil.dart';
import '../../core/widgets/status_pill.dart';
import '../foyer/fiche_eleve_page.dart' show ColonnesFiche;
import '../suivi_foyer/filtres_historique.dart' show dateCourte;
import 'carte_rubriques.dart';
import 'soldes_page.dart';

// S05 « Verifier la recharge » et S06 « Resultat » (LT-8, complement Tuteur
// section 5 ; planche « 01 Recharges, remises et acces »). Aucune somme ici :
// lignes, remises, total et issues sont ceux du serveur. Devis et resultat
// passent par `extra` ; sans lui (adresse tapee, rechargement), l'ecran le
// dit et renvoie a la recharge ou aux soldes, jamais un devis invente. Le
// paiement (DB-FIN-04) est indisponible partout pour l'instant.

Map<String, String> _prenoms(WidgetRef ref) {
  final AsyncValue<List<ProfilEleveFoyer>> profils = ref.watch(
    profilsElevesFoyerProvider,
  );
  return <String, String>{
    if (profils.hasValue && !profils.hasError)
      for (final ProfilEleveFoyer p in profils.requireValue)
        p.eleveId: p.prenom,
  };
}

/// S05 (`/tuteur/compte/soldes/recharge/verifier`), devis dans `extra`.
class VerifierRechargePage extends ConsumerStatefulWidget {
  /// Cree la page.
  const VerifierRechargePage({super.key, this.devis});

  /// Le devis rendu par le serveur ; `null` s'il n'a pas suivi.
  final DevisRecharge? devis;

  /// L'action « Payer ».
  static const Key payerKey = Key('recharge.payer');

  /// Le lien « Reprendre la recharge ».
  static const Key reprendreKey = Key('recharge.reprendre');

  /// Le recapitulatif rendu par le serveur (total, validite).
  static const Key recapitulatifKey = Key('recharge.recapitulatif');

  @override
  ConsumerState<VerifierRechargePage> createState() =>
      _VerifierRechargePageState();
}

class _VerifierRechargePageState extends ConsumerState<VerifierRechargePage> {
  /// Une cle par ecran, reprise a chaque nouvelle tentative : le serveur ne
  /// paie jamais deux fois le meme devis.
  final String _cle = const Uuid().v4();
  bool _enCours = false;
  Object? _echec;

  Future<void> _payer(DevisRecharge devis) async {
    if (_enCours) {
      return;
    }
    setState(() {
      _enCours = true;
      _echec = null;
    });
    try {
      final ResultatRecharge resultat = await ref
          .read(portFinanceFoyerProvider)
          .payer(referenceDevis: devis.reference, cleIdempotence: _cle);
      if (!mounted) {
        return;
      }
      setState(() => _enCours = false);
      GoRouter.of(context)
          .go(Routes.tuteurCompteRechargeResultat, extra: resultat);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _enCours = false;
          _echec = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final GoRouter? routeur = GoRouter.maybeOf(context);
    void reprendre() => routeur?.go(Routes.tuteurCompteRecharge);
    final DevisRecharge? devis = widget.devis;
    final Object? echec = _echec;
    // L'expiration est dite par le serveur (refus type DevisExpire), jamais
    // par l'horloge locale : « valable jusqu'au » reste une information.
    final bool expire = echec is DevisExpire;
    final bool payable =
        devis != null && !expire && echec is! CapaciteIndisponible;

    return PageShell(
      titre: t.finance.recharge.verification.titre,
      sousTitre: devis == null
          ? null
          : t.finance.recharge.verification.sousTitre,
      onRetour: reprendre,
      actions: payable
          ? ActionPrincipale(
              key: VerifierRechargePage.payerKey,
              libelle: t.finance.recharge.verification.payer,
              enCours: _enCours,
              onPress: _enCours ? null : () => _payer(devis),
            )
          : null,
      child: devis == null
          ? ColonneSousPage(
              child: _Reprendre(
                titre: t.finance.recharge.verification.perdu,
                phrase: t.finance.recharge.verification.perduPhrase,
                onPress: reprendre,
              ),
            )
          : _colonnes(
              context,
              devis: devis,
              etat: <Widget>[
                if (expire)
                  _Reprendre(
                    titre: t.finance.recharge.verification.expire,
                    phrase: t.finance.recharge.verification.expirePhrase,
                    onPress: reprendre,
                  )
                else if (echec is CapaciteIndisponible)
                  EtatSysteme(
                    nature: NatureEtat.indisponible,
                    titre: t.finance.recharge.verification.paiementIndisponible,
                    phrase: t
                        .finance
                        .recharge
                        .verification
                        .paiementIndisponiblePhrase,
                    dependance: echec.dependance,
                  )
                else if (echec != null)
                  EtatSysteme(
                    nature: NatureEtat.echecServeur,
                    onAction: _enCours ? null : () => _payer(devis),
                    actionEnCours: _enCours,
                  ),
              ],
            ),
    );
  }

  /// Telephone et tablette : lignes, total, puis l'etat, en une colonne. Sur
  /// bureau, le recapitulatif rendu par le serveur (total, validite) passe
  /// dans la colonne laterale (planche « 06 Web sombre, recharge »).
  Widget _colonnes(
    BuildContext context, {
    required DevisRecharge devis,
    required List<Widget> etat,
  }) {
    final Map<String, String> prenoms = _prenoms(ref);
    if (AppGabarit.de(context) == Gabarit.desktop) {
      return ColonnesFiche(
        principal: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _Devis(devis: devis, prenoms: prenoms, total: false),
            ...etat,
          ],
        ),
        annexe: _Devis(devis: devis, prenoms: prenoms, lignes: false),
      );
    }
    return ColonneSousPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _Devis(devis: devis, prenoms: prenoms),
          ...etat,
        ],
      ),
    );
  }
}

class _Reprendre extends StatelessWidget {
  const _Reprendre({
    required this.titre,
    required this.phrase,
    required this.onPress,
  });

  final String titre;
  final String phrase;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) => EtatSysteme(
    key: VerifierRechargePage.reprendreKey,
    nature: NatureEtat.ressourceExpiree,
    titre: titre,
    phrase: phrase,
    libelleAction: t.finance.recharge.verification.reprendre,
    onAction: onPress,
  );
}

/// Les lignes par profil, puis le total et la validite, tels que rendus.
class _Devis extends StatelessWidget {
  const _Devis({
    required this.devis,
    required this.prenoms,
    this.lignes = true,
    this.total = true,
  });

  final DevisRecharge devis;
  final Map<String, String> prenoms;

  /// Les cartes par profil.
  final bool lignes;

  /// Le recapitulatif : total et validite.
  final bool total;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final String d = devis.devise;
    final v = t.finance.recharge.verification;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (lignes)
          for (final LigneDevis l in devis.lignes) ...<Widget>[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Semantics(
                    header: true,
                    child: Text(
                      prenoms[l.profilId] ?? t.finance.profilSansPrenom,
                      style: textes.titleSmall,
                    ),
                  ),
                  Ecart.vSm,
                  // ponytail: la quantite est ecrite dans la devise du devis,
                  // faute de devise du solde dans `LigneDevis` (comme LT-7).
                  LigneCleValeur(
                    cle: v.quantite,
                    valeur: formaterMontant(l.quantiteMineure, d),
                    chiffres: true,
                  ),
                  LigneCleValeur(
                    cle: v.prix,
                    valeur: formaterMontant(l.prixMineur, d),
                    chiffres: true,
                  ),
                  LigneCleValeur(
                    cle: v.remise,
                    valeur: l.remiseMineure == 0
                        ? v.aucuneRemise
                        : formaterMontant(l.remiseMineure, d),
                    chiffres: l.remiseMineure != 0,
                  ),
                ],
              ),
            ),
            Ecart.vMd,
          ],
        if (total) ...<Widget>[
          AppCard(
            key: VerifierRechargePage.recapitulatifKey,
            dominante: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                LigneCleValeur(
                  cle: v.total,
                  valeur: formaterMontant(devis.totalMineur, d),
                  chiffres: true,
                ),
                Ecart.vSm,
                Text(
                  v.valableJusqua(
                    date: dateCourte(devis.valableJusqua.toLocal()),
                  ),
                  style: textes.bodySmall,
                ),
              ],
            ),
          ),
          Ecart.vLg,
        ],
      ],
    );
  }
}

/// S06 (`/tuteur/compte/soldes/recharge/resultat`), resultat dans `extra`.
class ResultatRechargePage extends ConsumerWidget {
  /// Cree la page.
  const ResultatRechargePage({super.key, this.resultat});

  /// Le resultat rendu par le serveur ; `null` s'il n'a pas suivi.
  final ResultatRecharge? resultat;

  /// L'action « Revenir aux soldes ».
  static const Key soldesKey = Key('recharge.resultat.soldes');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter? routeur = GoRouter.maybeOf(context);
    void soldes() {
      // Le paiement a pu changer les soldes : ils sont relus.
      ref.invalidate(soldesFoyerProvider);
      routeur?.go(Routes.tuteurCompteSoldes);
    }

    final ResultatRecharge? r = resultat;
    final ActionPrincipale action = ActionPrincipale(
      key: soldesKey,
      libelle: t.finance.recharge.resultat.retourSoldes,
      onPress: soldes,
    );
    if (r == null) {
      return PageShell(
        titre: t.finance.recharge.resultat.titre,
        onRetour: soldes,
        actions: action,
        child: EtatSysteme(
          nature: NatureEtat.ressourceExpiree,
          titre: t.finance.recharge.resultat.perdu,
          phrase: t.finance.recharge.resultat.perduPhrase,
        ),
      );
    }

    final res = t.finance.recharge.resultat;
    final (AppIcon icone, TonEtat ton, String titre) = switch (r.paiement) {
      IssueServeur.confirmee => (
        AppIcons.succes,
        TonEtat.succes,
        res.paiementConfirme,
      ),
      IssueServeur.enAttente => (
        AppIcons.attente,
        TonEtat.neutre,
        res.paiementEnAttente,
      ),
      IssueServeur.echouee => (
        AppIcons.avertissement,
        TonEtat.alerte,
        res.paiementEchoue,
      ),
    };
    return PageShell(
      titre: res.titre,
      onRetour: soldes,
      actions: action,
      child: ColonneSousPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            EcranResultat(
              icone: icone,
              ton: ton,
              titre: titre,
              phrase: res.reference(reference: r.referencePaiement),
            ),
            Ecart.vXl,
            ResultatParProfil(
              titre: res.attribution,
              issues: r.attributions,
              prenoms: _prenoms(ref),
            ),
          ],
        ),
      ),
    );
  }
}
