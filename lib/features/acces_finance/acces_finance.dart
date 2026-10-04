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
import 'package:flutter_riverpod/misc.dart'
    show FutureProviderFamily, ProviderFamily;

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_acces_foyer.dart';
import '../../core/capacites/port_mes_finances.dart';
import '../../core/finance/finances_profil.dart';
import '../../core/finance/format_montant.dart';
import '../../core/finance/montant.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/pastille_financiere.dart';
import '../../core/widgets/status_pill.dart';
import '../compte/donnees_compte.dart' show accesFoyerProvider, dateLongue;
import '../foyer/finances_foyer.dart' show financesFoyerProvider;

// Les finances du foyer ont une seule lecture, celle du Foyer (FI-4) :
// **jamais lue par un ecran d'enfant** (lecon 15).
export '../foyer/finances_foyer.dart' show financesFoyerProvider;

/// L'acces d'un eleve du foyer, `null` quand le port ne le rend pas. **Pour
/// le titulaire** (fiche eleve, Compte) : un ecran d'eleve lit
/// [accesAppelantProvider], borne a sa session (revue FI-VAGUE-R R4-02).
///
/// Lu de l'etat de `accesFoyerProvider`, jamais de son `future` : Riverpod
/// relance une lecture en echec et son `future` reste alors en attente, ce
/// qui laisserait l'ecran croire a un chargement sans fin (port neutre en
/// production). Ici l'echec se dit tout de suite, la relance comprise.
final ProviderFamily<AsyncValue<AccesBeneficiaire?>, String>
accesEleveProvider = Provider.family<AsyncValue<AccesBeneficiaire?>, String>(
  (Ref ref, String eleveId) =>
      _accesDe(ref.watch(accesFoyerProvider), () => eleveId),
);

/// L'acces de [eleveId] dans une lecture des acces : en attente tant que
/// rien n'est rendu, en echec des que la lecture echoue. [eleveId] n'est
/// demande qu'une fois des acces rendus.
AsyncValue<AccesBeneficiaire?> _accesDe(
  AsyncValue<List<AccesBeneficiaire>> lecture,
  String? Function() eleveId,
) {
  final List<AccesBeneficiaire>? acces = lecture.value;
  if (acces == null) {
    final Object? erreur = lecture.error;
    return erreur == null
        ? const AsyncValue<AccesBeneficiaire?>.loading()
        : AsyncValue<AccesBeneficiaire?>.error(
            erreur,
            lecture.stackTrace ?? StackTrace.empty,
          );
  }
  if (acces.isEmpty) return const AsyncValue<AccesBeneficiaire?>.data(null);
  final String? id = eleveId();
  for (final AccesBeneficiaire a in acces) {
    if (a.eleveId == id) return AsyncValue<AccesBeneficiaire?>.data(a);
  }
  return const AsyncValue<AccesBeneficiaire?>.data(null);
}

/// La lecture de l'acces de la personne connectee, **bornee a sa session**
/// (`PortMonAcces`, FI-BR-08, revue FI-VAGUE-R R4-02) : jamais l'acces du
/// foyer entier charge puis filtre sur l'appareil de l'enfant.
///
/// Une capacite absente (production, FI-BR-08) n'est jamais relancee : rien
/// ne changera avant le branchement, et une relance silencieuse ferait
/// tourner des minuteries sur chaque ecran d'eleve. Un autre echec garde la
/// relance par defaut de Riverpod.
///
/// Relue quand la personne connectee change (contre-revue FI-VAGUE-CORR) :
/// sur un appareil partage, la ligne de la personne precedente ne survit
/// jamais a sa deconnexion (meme precedent que `identiteTitulaireProvider`).
final FutureProvider<AccesBeneficiaire?> monAccesProvider =
    FutureProvider<AccesBeneficiaire?>(
      (Ref ref) {
        ref.watch(
          sessionProvider.select((SessionState session) => session.profileId),
        );
        return ref.watch(portMonAccesProvider).monAcces();
      },
      retry: (int essai, Object erreur) => erreur is CapaciteIndisponible
          ? null
          : ProviderContainer.defaultRetry(essai, erreur),
    );

/// L'acces de l'eleve connecte (enfant ou adulte autonome), pour ses ecrans :
/// Accueil, Mes groupes, Espace groupe, Mon espace. `null` quand le port ne
/// rend pas de ligne : un tuteur ou un enseignant n'en a pas, son ecran ne
/// change donc pas (aucun role lu). Lu de l'etat de [monAccesProvider],
/// jamais de son `future` : un echec se dit tout de suite, la relance
/// comprise (port neutre en production).
final Provider<AsyncValue<AccesBeneficiaire?>> accesAppelantProvider =
    Provider<AsyncValue<AccesBeneficiaire?>>(
      (Ref ref) => ref.watch(monAccesProvider),
    );

/// Ce que l'eleve connecte peut faire de Rejoindre (FI-9a, revue FI-VAGUE-R
/// R4-01) : la meme regle partout ou une carte de seance propose d'entrer
/// (Accueil, Mes groupes, Espace groupe, accueils de demonstration).
/// [ferme] : seances fermees, Rejoindre est retire et la copie le dit ;
/// [enLecture] : l'acces se lit encore, Rejoindre reste present et inerte.
/// Une lecture absente ou en echec ne change rien, et jamais selon un solde.
({bool ferme, bool enLecture}) rejoindreSelonAcces(
  AsyncValue<AccesBeneficiaire?> acces,
) => (
  ferme: ouvertureSeances(acces.value) == OuvertureSeances.fermees,
  enLecture: accesEnAttente(acces),
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

/// Vrai tant que la lecture de l'acces n'a rendu ni valeur ni echec (revue
/// FI-9a) : Rejoindre reste alors present et inerte, comme hors ligne, au
/// lieu d'etre actif puis de disparaitre. Une relance apres echec garde son
/// erreur et n'est pas une attente : l'ecran garde son affichage d'avant.
bool accesEnAttente(AsyncValue<Object?> lecture) =>
    lecture.isLoading && !lecture.hasValue && !lecture.hasError;

/// « Essai : n/2 », `null` hors essai. Les deux nombres sont rendus par la
/// source (FIN4-10), jamais supposes.
String? libelleEssai(AccesBeneficiaire? acces) {
  final int? utilises = acces?.essaisUtilises;
  final int? max = acces?.essaisMax;
  if (utilises == null || max == null) return null;
  return PastilleFinanciere.libelleEssai(utilises: utilises, max: max);
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

/// La phrase du tuteur (avec [prenom]) ou de l'adulte autonome (sans) sur
/// la place rendue par la source (FI-BR-08, guide §8 F5) : place liberee,
/// acces suspendu, ou acces reactive. `null` sans etat de place rendu.
/// **Jamais pour l'enfant** : sa copie reste neutre, sans cause.
String? phrasePlace(AccesBeneficiaire? acces, {String? prenom}) {
  final EtatPlace? place = acces?.place;
  if (place == null) return null;
  final DateTime? jour = acces?.datePlace;
  final String? date = jour == null ? null : dateLongue(jour);
  return switch ((place, prenom, date)) {
    (EtatPlace.liberee, final String p, final String d) =>
      t.argent.acces.suspenduTuteur(prenom: p, date: d),
    (EtatPlace.liberee, final String p, null) =>
      t.argent.acces.suspenduTuteurSansDate(prenom: p),
    (EtatPlace.liberee, null, final String d) => t.argent.acces.suspenduAdulte(
      date: d,
    ),
    (EtatPlace.liberee, null, null) => t.argent.acces.suspenduAdulteSansDate,
    (EtatPlace.reactivee, final String p, final String d) =>
      t.argent.acces.reactiveTuteur(prenom: p, date: d),
    (EtatPlace.reactivee, final String p, null) =>
      t.argent.acces.reactiveTuteurSansDate(prenom: p),
    (EtatPlace.reactivee, null, final String d) =>
      t.argent.acces.reactiveAdulte(date: d),
    (EtatPlace.reactivee, null, null) => t.argent.acces.reactiveAdulteSansDate,
  };
}

/// Le bandeau de la place pour le tuteur ou l'adulte autonome : « Accès
/// suspendu » (place liberee) ou « Accès réactivé ». Rien sans etat de place
/// rendu. Le compte reste navigable : le bandeau s'ajoute, il ne ferme rien.
class BandeauPlace extends StatelessWidget {
  /// Cree le bandeau ; [prenom] nul pour l'adulte autonome (« Votre place »).
  const BandeauPlace({required this.acces, super.key, this.prenom});

  /// L'acces rendu, avec son etat de place.
  final AccesBeneficiaire acces;

  /// Le prenom de l'eleve, pour le tuteur.
  final String? prenom;

  /// La cle du bandeau « Accès suspendu ».
  static const Key suspenduKey = Key('acces.place.suspendu');

  /// La cle du bandeau « Accès réactivé ».
  static const Key reactiveKey = Key('acces.place.reactive');

  /// Le bandeau de [acces], `null` sans etat de place rendu.
  static BandeauPlace? pour(AccesBeneficiaire? acces, {String? prenom}) =>
      acces?.place == null ? null : BandeauPlace(acces: acces!, prenom: prenom);

  @override
  Widget build(BuildContext context) {
    final bool liberee = acces.place == EtatPlace.liberee;
    return BandeauAttention(
      key: liberee ? suspenduKey : reactiveKey,
      titre: liberee
          ? t.argent.acces.suspenduTitre
          : t.argent.acces.reactiveTitre,
      message: phrasePlace(acces, prenom: prenom) ?? '',
      ton: liberee ? TonEtat.avertissement : TonEtat.succes,
    );
  }
}

/// La copie de l'eleve adulte autonome quand ses seances sont fermees, sans
/// etat de place ni manque rendus : neutre, au vouvoiement, sans cause
/// inventee. La cause utile vit dans Mon espace > Paiements.
class BandeauAccesAdulte extends StatelessWidget {
  /// Cree le bandeau.
  const BandeauAccesAdulte({super.key});

  /// La cle du bandeau.
  static const Key cle = Key('acces.adulte.ferme');

  @override
  Widget build(BuildContext context) => BandeauAttention(
    key: cle,
    titre: t.argent.acces.seancesFermeesTitre,
    message: t.argent.acces.adulteSeancesFermees,
    ton: TonEtat.accent,
  );
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

/// L'acces de l'eleve adulte autonome dans Mon espace : « Accès suspendu »
/// ou « Accès réactivé » (FI-BR-08), « Accès à régulariser » et le manque
/// exact, ou « Essai : n/2 ». Ses ports ne rendent que son seul profil
/// (revue FI-1a « Données financières par rôle » ; `PortMesFinances`,
/// `PortMonAcces`). Rien non plus tant que les lectures ne sont pas
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
    // FI-9b : les finances du seul adulte (PortMesFinances, borne a la
    // session), jamais celles du foyer entier chargees puis filtrees.
    // L'acces aussi est borne a sa session (FI-BR-08, revue FI-VAGUE-R
    // R4-02) : jamais la liste du foyer.
    final AsyncValue<FinancesProfil?> miennes = ref.watch(mesFinancesProvider);
    final AccesBeneficiaire? acces = ref.watch(accesAppelantProvider).value;
    final FinancesProfil? finances = miennes.hasValue && !miennes.hasError
        ? miennes.requireValue
        : null;
    final String? essai = libelleEssai(acces);
    // La place liberee passe avant le manque : elle dit ce qui a change
    // (FI-BR-08, guide §8 F5) ; la reactivation ne masque pas un nouveau
    // manque.
    final BandeauPlace? place = BandeauPlace.pour(acces);
    final Widget? contenu = acces?.place == EtatPlace.liberee
        ? place
        : aRegulariser(finances)
        ? BandeauRegularisation(finances: finances!)
        : place ??
              (essai != null
                  ? Align(
                      key: essaiKey,
                      alignment: AlignmentDirectional.centerStart,
                      child: StatusPill(
                        libelle: essai,
                        ton: PastilleFinanciere.tonDe(EtatFinancier.essai),
                      ),
                    )
                  : null);
    if (contenu == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: ecartApres),
      child: contenu,
    );
  }
}
