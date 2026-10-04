// L'acces, l'essai et l'impaye vus par chaque role (FI-9a, guide Finance V4
// §1.2, §1.7, §8 F5 ; revue FI-1a:77 ; FI-BR-08).
//
// Trois lectures, trois copies :
// - l'enfant lit l'etat d'acces seul (`AccesBeneficiaire`, port de l'acces
//   du foyer) : seances ouvertes ou non, essais. **Jamais une cause ni un
//   montant** : ce port n'en porte pas (lecon 15), la copie est neutre
//   (« Accès à cette classe temporairement indisponible ») ;
// - le tuteur et l'eleve adulte autonome lisent la finance du profil
//   (`FinancesProfil`) : « Accès à régulariser », le manque exact
//   (`FinancesProfil.manque`, mis en mots par `formaterMontant`) et le mois
//   du debit attendu, la fin de conservation de la place ;
// - « Essai : n/2 » vient des compteurs rendus par le port de l'acces.
//
// Aucun etat serveur nouveau : « a regulariser » se lit dans
// `EtatFinancier.aRegulariser`, jamais dans `EtatAccesAffiche` (question au
// directeur, FI-BR-08). Aucun calcul d'argent (FI6) : le manque arrive
// arrete. Rejoindre depend de la periode financee, jamais du solde (FI2,
// FIN4-08) : aucune de ces lectures ne touche au solde.
//
// En production les ports sont neutres (`CapaciteIndisponible`) : ces
// lectures echouent et les ecrans gardent leur affichage d'avant, rien n'est
// invente.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../../core/capacites/port_acces_foyer.dart';
import '../../core/capacites/port_paiements_foyer.dart';
import '../../core/finance/finances_profil.dart';
import '../../core/finance/format_montant.dart';
import '../../core/finance/montant.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/status_pill.dart';
import '../compte/donnees_compte.dart' show accesFoyerProvider, dateLongue;

/// L'acces d'un eleve, `null` quand le port ne le rend pas.
final FutureProviderFamily<AccesBeneficiaire?, String> accesEleveProvider =
    FutureProvider.family<AccesBeneficiaire?, String>((
      Ref ref,
      String eleveId,
    ) async {
      final List<AccesBeneficiaire> acces = await ref.watch(
        accesFoyerProvider.future,
      );
      for (final AccesBeneficiaire a in acces) {
        if (a.eleveId == eleveId) return a;
      }
      return null;
    });

/// Les finances du foyer, pour le titulaire ou l'eleve adulte lui-meme.
/// **Jamais lues par un ecran d'enfant** (lecon 15).
final FutureProvider<FinancesFoyer> financesFoyerProvider =
    FutureProvider<FinancesFoyer>(
      (Ref ref) => ref.watch(portPaiementsFoyerProvider).finances(),
    );

/// La finance d'un profil, `null` quand la source ne la rend pas.
final FutureProviderFamily<FinancesProfil?, String> financesProfilProvider =
    FutureProvider.family<FinancesProfil?, String>((
      Ref ref,
      String profilId,
    ) async {
      final FinancesFoyer foyer = await ref.watch(financesFoyerProvider.future);
      for (final FinancesProfil p in foyer.profils) {
        if (p.profilId == profilId) return p;
      }
      return null;
    });

/// Ce qu'un eleve peut faire de sa prochaine seance.
enum OuvertureSeances {
  /// La periode est financee : les seances payantes sont ouvertes.
  ouvertes,

  /// Une seance d'essai reste (FIN4-10) : la prochaine seance est ouverte.
  essai,

  /// Ni periode financee ni essai restant (FIN4-13) : Rejoindre est
  /// indisponible, l'enfant lit la copie neutre.
  fermees,

  /// La source ne dit rien : l'ecran garde son affichage d'avant.
  inconnue,
}

/// L'ouverture des seances d'apres l'acces rendu. Pure, sans solde : seuls
/// la periode financee (`seancesPayantesOuvertes`) et les compteurs d'essai
/// rendus comptent (FI2, FIN4-08, FIN4-13).
OuvertureSeances ouvertureSeances(AccesBeneficiaire? acces) {
  if (acces == null) return OuvertureSeances.inconnue;
  if (acces.seancesPayantesOuvertes ?? false) return OuvertureSeances.ouvertes;
  final int? utilises = acces.essaisUtilises;
  final int? max = acces.essaisMax;
  if (utilises != null && max != null && utilises < max) {
    return OuvertureSeances.essai;
  }
  return acces.seancesPayantesOuvertes == false
      ? OuvertureSeances.fermees
      : OuvertureSeances.inconnue;
}

/// « Essai : n/2 », `null` hors essai. Les deux nombres sont rendus par la
/// source (FIN4-10), jamais supposes.
String? libelleEssai(AccesBeneficiaire? acces) {
  final int? utilises = acces?.essaisUtilises;
  final int? max = acces?.essaisMax;
  if (utilises == null || max == null) return null;
  return t.argent.acces.essai(n: utilises, max: max);
}

/// Vrai quand la finance du profil dit « a regulariser » (FI11).
bool aRegulariser(FinancesProfil? finances) =>
    finances?.etat == EtatFinancier.aRegulariser;

/// La cause utile, pour le tuteur et l'adulte autonome seulement : « Il
/// manque 8 $ pour financer octobre. ». Le mois est celui du debit attendu
/// (`prochainDebit`), le montant est le manque rendu, mis en mots par le seul
/// formateur : rien n'est calcule.
String messageRegularisation(FinancesProfil finances) {
  final Montant? manque = finances.manque;
  if (manque == null) return t.argent.acces.regulariserSansManque;
  final String montant = formaterMontant(manque);
  final DateTime? debit = finances.prochainDebit?.date;
  if (debit == null) {
    return t.argent.acces.regulariserManqueNouvellePeriode(montant: montant);
  }
  return t.argent.acces.regulariserManque(
    montant: montant,
    mois: t.commun.dates.mois[debit.month - 1],
  );
}

/// « Place conservée jusqu'au 8 octobre 2026. », `null` sans fin de
/// conservation rendue (guide §1.7 : 7 jours au lancement, decides par la
/// politique, jamais par l'ecran).
String? phraseConservation(FinancesProfil finances) {
  final DateTime? fin = finances.finConservation;
  return fin == null
      ? null
      : t.argent.acces.placeConservee(date: dateLongue(fin));
}

/// La copie de l'enfant quand ses seances sont fermees (guide §1.7) : neutre,
/// sans cause, sans montant, sans action. Le ton « accent » dit une attente,
/// jamais une faute.
class BandeauAccesEnfant extends StatelessWidget {
  /// Cree le bandeau.
  const BandeauAccesEnfant({super.key});

  /// La cle du bandeau.
  static const Key cle = Key('acces.enfant.bandeau');

  @override
  Widget build(BuildContext context) => BandeauAttention(
    key: cle,
    titre: t.argent.acces.enfantTitre,
    message: t.argent.acces.enfantMessage,
    ton: TonEtat.accent,
  );
}

/// La copie du tuteur ou de l'adulte autonome quand la nouvelle periode
/// n'est pas financee (guide §1.7) : « Accès à régulariser », le manque
/// exact, puis la fin de conservation de la place quand elle est rendue.
/// Aucun compte n'est ferme : le bandeau s'ajoute, il ne remplace rien.
class BandeauRegularisation extends StatelessWidget {
  /// Cree le bandeau.
  const BandeauRegularisation({required this.finances, super.key});

  /// La finance du profil, a l'etat `aRegulariser`.
  final FinancesProfil finances;

  /// La cle du bandeau.
  static const Key cle = Key('acces.regulariser.bandeau');

  @override
  Widget build(BuildContext context) {
    final String? conservation = phraseConservation(finances);
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      key: cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        BandeauAttention(
          titre: t.argent.acces.regulariserTitre,
          message: messageRegularisation(finances),
        ),
        if (conservation != null) ...<Widget>[
          Ecart.vSm,
          Text(
            conservation,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
      ],
    );
  }
}

/// L'acces de l'eleve adulte autonome dans Mon espace : « Accès à
/// régulariser » et le manque exact, ou « Essai : n/2 ». Ses ports ne
/// rendent que son seul profil (revue FI-1a « Données financières par
/// rôle ») : le bloc ne lit rien d'autre qu'une liste a un element, et ne
/// rend rien sinon. Rien non plus tant que les lectures ne sont pas
/// abouties, en echec ou en production (ports neutres) : Mon espace garde
/// ses rubriques et ses propres etats.
class AccesAdulte extends ConsumerWidget {
  /// Cree le bloc.
  const AccesAdulte({required this.ecartApres, super.key});

  /// L'ecart sous le bloc quand il est rendu.
  final double ecartApres;

  /// La cle de la pastille d'essai.
  static const Key essaiKey = Key('acces.adulte.essai');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<FinancesProfil>? profils = ref
        .watch(financesFoyerProvider)
        .value
        ?.profils;
    final List<AccesBeneficiaire>? acces = ref.watch(accesFoyerProvider).value;
    final FinancesProfil? finances = profils?.length == 1
        ? profils!.single
        : null;
    final String? essai = libelleEssai(
      acces?.length == 1 ? acces!.single : null,
    );
    final Widget? contenu = aRegulariser(finances)
        ? BandeauRegularisation(finances: finances!)
        : essai != null
        ? Align(
            key: essaiKey,
            alignment: AlignmentDirectional.centerStart,
            child: StatusPill(libelle: essai, ton: TonEtat.accent),
          )
        : null;
    if (contenu == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: ecartApres),
      child: contenu,
    );
  }
}
