import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:go_router/go_router.dart';

import '../../core/appairage/service_appairage.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_accents_profils.dart';
import '../../core/capacites/port_classes_foyer.dart';
import '../../core/capacites/port_identite_titulaire.dart';
import '../../core/finance/finances_profil.dart';
import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/offres/offre_horaire.dart';
import '../../core/offres/service_offres.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/accent_profil.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/skeleton.dart';
import '../compte/compte_tuteur_page.dart' show CarteIdentiteCompte;
import '../compte/donnees_compte.dart' show identiteTitulaireProvider;
import 'finances_foyer.dart';
import 'ligne_membre.dart';
import 'photo_eleve.dart';
import 'place_adulte.dart';
import 'transactions_foyer.dart';

/// L'horloge du Foyer, pour dire qu'une echeance d'acces est passee.
///
/// Un provider plutot qu'un appel direct a `DateTime.now` : les tests fixent
/// l'instant, l'application garde l'horloge de l'appareil.
final Provider<DateTime Function()> horlogeFoyerProvider =
    Provider<DateTime Function()>((Ref ref) => DateTime.now);

/// Les classes d'un membre du foyer (port K6 `PortClassesFoyer`).
///
/// En production, le port n'a pas encore de service (DB-TRV-07, adaptateur du
/// lot C) : la lecture rend `CapaciteIndisponible`, et la page le dit une fois
/// au lieu d'inventer une classe ou une absence de classe.
final FutureProviderFamily<List<ClasseFoyer>, String> classesMembreProvider =
    FutureProvider.family<List<ClasseFoyer>, String>(
      (Ref ref, String eleveId) =>
          ref.watch(portClassesFoyerProvider).classesDe(eleveId),
    );

/// Le Foyer (`/tuteur/foyer`, deuxieme destination du tuteur).
///
/// Aucune maquette haute fidelite : la composition derive du manifeste
/// visuel (section 2, ligne `/tuteur/foyer`) : contenu de l'ancienne capture
/// « Foyer Member », rendu des lignes de rubrique de « Mon compte ». Titre,
/// action « Ajouter un profil eleve » en tete, les membres en UN groupe a
/// filets (prenom, classe quand elle est connue, statut d'acces en texte,
/// chevron vers la fiche), les appareils partages en une ligne vers l'ecran
/// du lot D, et l'option discrete « Creer mon profil eleve ». Aucun compteur
/// decoratif. Des la tablette, les cartes en grille et, sous elles, la vue
/// financiere, les transactions et les annexes (FI-5b, R1-04).
///
/// **Ma famille du titulaire adulte** (EA-5, EA-5c) : quand
/// [foyerTitulaireProvider] rend une valeur, la meme page devient « Ma
/// famille » : la carte du titulaire EN TETE, y compris sur telephone
/// (planches 3.1 et 6, decision E6), le groupe « Forfait famille » (la ligne
/// de la place adulte, F21, et, apres un refus, « Faire une nouvelle
/// demande », E5), les profils eleves, « Ajouter un profil eleve » sous eux
/// sur telephone (planche 3.1), puis « Paiements du foyer », les appareils,
/// et au pied « A propos du forfait famille » (planche 2.1) et « Creer mon
/// profil eleve » (garde, planche 2.3 G, decision E6 ; il ouvre la page
/// indisponible existante, DB-FOY-01, EA-BR-19). Sans valeur (le cas du tuteur
/// aujourd'hui, EA-BR-14), rien ne change.
class FoyerPage extends ConsumerWidget {
  /// Cree la page.
  const FoyerPage({
    super.key,
    this.onAller,
    this.onPlaceAdulte,
    this.onPaiementsFoyer,
    this.onAProposForfait,
    this.onNouvelleDemande,
  });

  /// Ouvre un chemin du Foyer (ajout, fiche, appareils) ; par defaut, le
  /// routeur. La demonstration adulte y garde la personne dans sa coquille.
  final void Function(String chemin)? onAller;

  /// Ouvre la place adulte quand sa ligne est une action (EA-6, EA-8).
  final VoidCallback? onPlaceAdulte;

  /// Ouvre les paiements du foyer (EA-9).
  final VoidCallback? onPaiementsFoyer;

  /// Ouvre « A propos du forfait famille » ; par defaut, la page est poussee
  /// sur le navigateur.
  final VoidCallback? onAProposForfait;

  /// Relance l'invitation apres un refus de validation (E5, doc section
  /// 10.3). Sans lui, le bouton n'est pas pose.
  final VoidCallback? onNouvelleDemande;

  /// La carte du titulaire.
  static const Key titulaireKey = Key('foyer.titulaire');

  /// « Recharger » (nom lu « Recharger {prenom} ») sous la carte d'un
  /// enfant (FI-4).
  static Key rechargerPourKey(String eleveId) =>
      Key('foyer.finances.recharger.$eleveId');

  /// « Voir le détail » sous la carte d'un enfant finance : sa fiche
  /// Finances (FI-4, revue FI-VAGUE-R R1-08).
  static Key voirDetailKey(String eleveId) =>
      Key('foyer.finances.voirDetail.$eleveId');

  /// L'action « Ajouter un profil eleve » de l'en-tete.
  static const Key ajouterKey = Key('foyer.ajouter');

  /// Le groupe des profils eleves.
  static const Key membresKey = Key('foyer.membres');

  /// La section des appareils partages.
  static const Key appareilsKey = Key('foyer.appareils');

  /// Le lien « Creer mon profil eleve ».
  static const Key monProfilKey = Key('foyer.monProfil');

  /// Le lien « Relire les classes » apres un echec de lecture.
  static const Key relireClassesKey = Key('foyer.relireClasses');

  /// La phrase qui dit que l'inscription en cours ne se lit pas.
  static const Key inscriptionIllisibleKey = Key('foyer.inscriptionIllisible');

  void _aProposForfait(BuildContext context) {
    final VoidCallback? propre = onAProposForfait;
    if (propre != null) {
      propre();
      return;
    }
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext page) => AProposForfaitFamillePage(
            onRetour: () => Navigator.of(page).pop(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Gabarit gabarit = AppGabarit.de(context);
    final bool bureau = gabarit == Gabarit.desktop;
    final GoRouter? routeur = GoRouter.maybeOf(context);
    void aller(String chemin) {
      final void Function(String chemin)? propre = onAller;
      if (propre != null) {
        propre(chemin);
      } else {
        routeur?.go(chemin);
      }
    }

    final AsyncValue<FoyerTitulaireVM> lectureAdulte = ref.watch(
      foyerTitulaireProvider,
    );
    // Seul « pas titulaire » (`CapaciteIndisponible`) rend le Foyer du tuteur.
    // Le chargement et toute autre erreur se disent comme tels (squelette,
    // puis erreur avec « Reessayer ») : jamais le Foyer du tuteur montre en
    // silence a un titulaire adulte, ni un saut de mise en page.
    if (lectureAdulte.hasError
        ? lectureAdulte.error is! CapaciteIndisponible
        : !lectureAdulte.hasValue) {
      return PageShell(
        child: BlocAsynchrone<FoyerTitulaireVM>(
          valeur: lectureAdulte,
          squelette: const Skeleton.liste(),
          onReessayer: () => ref.invalidate(foyerTitulaireProvider),
          construire: (FoyerTitulaireVM _) => const SizedBox.shrink(),
        ),
      );
    }
    final FoyerTitulaireVM? adulte = lectureAdulte.hasError
        ? null
        : lectureAdulte.requireValue;

    // L'action d'ajout tient a droite du titre sur bureau. En dessous de
    // 1200, le titre, la bascule de theme, la cloche et le libelle complet
    // ne tiennent pas toujours sur une ligne (358 sur telephone) : pour le
    // tuteur, elle passe juste sous le titre, hors de la zone defilante ; pour
    // le titulaire adulte, sous les profils eleves, apres la carte du
    // titulaire qui reste en tete (planche 3.1, decision E6). Une seule
    // action, un seul endroit. CTA dominant « libelle + fleche » (03, section
    // 3 point 3).
    //
    // Avec les finances rendues, « Recharger plusieurs profils » est le seul
    // bouton plein et l'ajout passe en secondaire, a sa place (Q-FI-2,
    // E-17, revue FI-VAGUE-R R1-01). Sans source de paiement (production),
    // en chargement ou en erreur, « Ajouter un profil eleve » est le bouton
    // plein (FI-Q1 (a), decide par delegation le 05/10).
    final AsyncValue<FinancesFoyer> finances = ref.watch(financesFoyerProvider);
    final bool avecFinances = financesDisponibles(finances);
    final Widget ajouter = ActionPrincipale(
      key: ajouterKey,
      libelle: t.foyer.ajouterProfil,
      niveau: rechargePosee(finances)
          ? NiveauAction.secondaire
          : NiveauAction.principale,
      fleche: true,
      pleineLargeur: gabarit == Gabarit.mobile,
      onPress: () => aller(Routes.tuteurAjouterEnfant),
    );

    // FI-5b : des la tablette, la synthese et les cartes des enfants sur
    // toute la largeur utile, les cartes en grille (guide V4 §5.1
    // « Desktop », maquette 05 ; revue FI-VAGUE-R R1-04). Le titulaire
    // adulte a la meme composition (E-11, R1-06) : sa carte et sa place en
    // tete, puis la meme synthese et les memes cartes.
    final bool large = gabarit.estLarge;
    final Widget profils = KeyedSubtree(
      key: membresKey,
      child: _Membres(aller, grille: large),
    );
    final VoidCallback? nouvelleDemande = onNouvelleDemande;
    final Widget membres = adulte == null
        ? profils
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              KeyedSubtree(key: titulaireKey, child: _CarteTitulaire(adulte)),
              Ecart.vSection,
              GroupeReglages(
                key: lignePlaceAdulteKey,
                titre: t.adulte.famille.forfaitFamille,
                lignes: <LigneRubrique>[
                  lignePlaceAdulte(adulte, onPress: onPlaceAdulte),
                ],
              ),
              // Validation refusee : une nouvelle demande, action secondaire
              // juste sous sa ligne d'etat. Le seul bouton plein reste celui
              // de la page : « Recharger plusieurs profils » quand les
              // finances sont rendues, sinon « Ajouter un profil eleve »
              // (R1-01).
              if (placePermetNouvelleDemande(adulte.place) &&
                  nouvelleDemande != null) ...<Widget>[
                Ecart.vLg,
                // Compact au bord de fin : l'action qui poursuit (contrat B,
                // revue EA-R m1). `IntrinsicWidth` : sans lui,
                // `ActionPrincipale` s'etire a toute la colonne meme avec
                // `pleineLargeur: false` (son `Container.alignment`, motif
                // deja contourne ainsi ailleurs) ; borne par la colonne, le
                // libelle passe a la ligne a 200 %.
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: IntrinsicWidth(
                    child: ActionPrincipale(
                      key: nouvelleDemandeKey,
                      libelle: t.adulte.famille.place.nouvelleDemande,
                      niveau: NiveauAction.secondaire,
                      pleineLargeur: false,
                      onPress: nouvelleDemande,
                    ),
                  ),
                ),
              ],
              Ecart.vSection,
              profils,
              // 16 entre les profils et leur action (contrat A, revue EA-R m2).
              if (!bureau) ...<Widget>[Ecart.vLg, ajouter],
            ],
          );
    final Widget annexes = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Une ligne vers la page des paiements du foyer (EA-9), sur tous
        // les gabarits. Les soldes ne sont plus repetes ici : la synthese et
        // les cartes des enfants les portent, comme pour le tuteur (E-11,
        // revue FI-VAGUE-R R1-06 ; `SoldesFoyerSection` retiree du Foyer).
        if (adulte != null) ...<Widget>[
          GroupeReglages(
            key: paiementsFoyerKey,
            lignes: <LigneRubrique>[
              LigneRubrique(
                icone: AppIcons.finance,
                libelle: t.adulte.famille.paiementsFoyer,
                onPress: onPaiementsFoyer,
              ),
            ],
          ),
          Ecart.vSection,
        ],
        KeyedSubtree(
          key: appareilsKey,
          child: GroupeReglages(
            titre: t.foyer.appareilsPartages,
            lignes: <LigneRubrique>[
              LigneRubrique(
                icone: AppIcons.appareil,
                libelle: t.foyer.appareilsFoyer,
                legende: t.foyer.appareilsFoyerLegende,
                onPress: () => aller(Routes.tuteurFoyerAppareils),
              ),
            ],
          ),
        ),
        // Garde pour le titulaire adulte aussi (planche 2.3 G, decision E6).
        // Le serveur ne dit pas encore s'il a deja son profil eleve, ni ne
        // sait le creer (DB-FOY-01, EA-BR-19) : la page dit qu'elle est
        // indisponible, avec les textes de l'adulte quand l'appelant les
        // demande (`CreerMonProfilIndisponible.titulaireAdulte`). « A propos du forfait famille » le precede, en lien
        // d'information au pied de la page (planche 2.1 P, decision E6).
        Ecart.vXxl,
        if (adulte != null) ...<Widget>[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: LienFleche(
              key: aProposForfaitKey,
              libelle: t.adulte.famille.aProposForfait,
              onPress: () => _aProposForfait(context),
            ),
          ),
          // Deux liens, deux cibles : jamais colles, meme a 200 %.
          Ecart.vSm,
        ],
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: LienFleche(
            key: monProfilKey,
            libelle: t.foyer.creerMonProfil,
            onPress: () => aller(Routes.tuteurAjouterPourMoi),
          ),
        ),
      ],
    );

    return PageShell(
      // En-tete sobre (K-42 point 5) : « Ma famille » pour le titulaire
      // adulte, comme sa ligne de Mon espace.
      titre: adulte == null ? t.foyer.titre : t.adulte.famille.maFamille,
      // « Soldes et paiements » quand les finances sont lues, rendues ou en
      // echec (maquettes 03 et 05, R1-09 : le titre de la synthese, qui dit
      // alors son contenu ou son erreur) ; pendant le chargement et sans
      // source (production), le sous-titre d'avant : jamais un sous-titre
      // pose une image puis retire (contre-revue FI-VAGUE-CORR).
      sousTitre: avecFinances && (finances.hasValue || finances.hasError)
          ? t.foyer.finances.titre
          : adulte == null
          ? t.foyer.sousTitre
          : null,
      actionsEntete: <Widget>[if (bureau) ajouter],
      entete: bureau || adulte != null
          ? null
          : Align(alignment: AlignmentDirectional.centerStart, child: ajouter),
      child: large
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                membres,
                Ecart.vSection,
                _RangeeBureau(
                  aller: aller,
                  annexes: annexes,
                  bureau: bureau,
                  onVoirTout: adulte == null ? null : onPaiementsFoyer,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[membres, Ecart.vSection, annexes],
            ),
    );
  }
}

/// Sous la grille, des la tablette : « Vue financiere du foyer », « Dernieres
/// transactions » et les annexes (appareils partages, « Creer mon profil
/// eleve »). Sur bureau, cote a cote (maquette 05) ; a la tablette, l'un sous
/// l'autre, jamais trois colonnes serrees (R1-04). Sans source (production),
/// les annexes seules, a leur largeur de colonne : jamais une colonne etiree
/// sur toute la page.
class _RangeeBureau extends ConsumerWidget {
  const _RangeeBureau({
    required this.aller,
    required this.annexes,
    required this.bureau,
    this.onVoirTout,
  });

  final void Function(String chemin) aller;

  final Widget annexes;

  final bool bureau;

  final VoidCallback? onVoirTout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool avecTransactions = transactionsDisponibles(
      ref.watch(derniersMouvementsFoyerProvider),
    );
    final bool avecVue = financesDisponibles(ref.watch(financesFoyerProvider));
    final Widget transactions = DernieresTransactionsFoyer(
      aller: aller,
      onVoirTout: onVoirTout,
    );
    if (!bureau) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (avecVue) ...<Widget>[
            VueFinanciereFoyer(onNosPrix: () => aller(Routes.tuteurFoyerPrix)),
            Ecart.vSection,
          ],
          if (avecTransactions) ...<Widget>[transactions, Ecart.vSection],
          annexes,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (avecVue) ...<Widget>[
          Expanded(
            flex: 2,
            child: VueFinanciereFoyer(
              onNosPrix: () => aller(Routes.tuteurFoyerPrix),
            ),
          ),
          Ecart.hXxl,
        ],
        if (avecTransactions) ...<Widget>[
          Expanded(flex: 3, child: transactions),
          Ecart.hXxl,
        ],
        Expanded(flex: 2, child: annexes),
        if (!avecVue && !avecTransactions) const Spacer(flex: 3),
      ],
    );
  }
}

/// La largeur minimale d'une carte d'enfant en grille, a texte normal : le
/// prenom, la legende, les pastilles et les lignes solde / prochain debit
/// sans coupure. Multipliee par l'echelle du texte : a texte agrandi, moins
/// de colonnes, jamais une carte plus etroite que son contenu.
///
/// 300 : deux colonnes des 632 px utiles (la tablette de 768, R1-04), trois
/// a 1440.
const double _largeurMinCarte = 300;

/// Au plus trois cartes cote a cote (maquette 05).
const int _colonnesMax = 3;

/// Les cartes des enfants en grille (FI-5b) : autant de colonnes que la
/// largeur en tient, de une a trois. Une seule colonne : la pile d'avant.
class _GrilleCartes extends StatelessWidget {
  const _GrilleCartes(this.cartes);

  final List<Widget> cartes;

  @override
  Widget build(BuildContext context) {
    final double echelle = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints contraintes) {
        final int colonnes =
            ((contraintes.maxWidth + AppSpacing.lg) /
                    (_largeurMinCarte * echelle + AppSpacing.lg))
                .floor()
                .clamp(1, _colonnesMax);
        if (colonnes == 1) return PileCartes(children: cartes);
        // Des rangees de cartes separees de 16 dans les deux sens (K-55) ;
        // la derniere rangee garde la largeur de colonne.
        return PileCartes(
          children: <Widget>[
            for (int debut = 0; debut < cartes.length; debut += colonnes)
              PileCartes(
                axe: Axis.horizontal,
                alignement: CrossAxisAlignment.start,
                children: <Widget>[
                  for (int i = debut; i < debut + colonnes; i++)
                    Expanded(
                      child: i < cartes.length
                          ? cartes[i]
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

/// Les membres : chargement, contenu, vide, erreur, hors ligne.
class _Membres extends ConsumerWidget {
  const _Membres(this.aller, {this.grille = false});

  final void Function(String chemin) aller;

  /// Vrai des la tablette : les cartes en grille.
  final bool grille;

  void _relire(WidgetRef ref) => ref.invalidate(elevesDuFoyerProvider);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // La source (`profils_du_foyer_v`) d'abord : pendant les nouvelles
    // tentatives automatiques de Riverpod, `profilsElevesFoyerProvider`
    // (K1, qui attend `elevesDuFoyerProvider.future`) reste en chargement
    // sans exposer l'echec (mesure : test `foyer_page_test.dart`, etat
    // « erreur »). L'echec de la source est donc lu ici, tel quel, pour que
    // la page dise l'erreur au lieu d'un squelette sans fin (demande B-3).
    final AsyncValue<List<EleveDuFoyer>> source = ref.watch(
      elevesDuFoyerProvider,
    );
    final AsyncValue<List<ProfilEleveFoyer>> profils = source.hasError
        ? AsyncValue<List<ProfilEleveFoyer>>.error(
            source.error!,
            source.stackTrace ?? StackTrace.empty,
          )
        : ref.watch(profilsElevesFoyerProvider);
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;

    // Sans reseau, un echec n'est pas « le serveur n'a pas repondu » : le
    // bandeau de `PageShell` dit le reseau, le bloc dit ce qui manque
    // (EA-HL-DOUBLE-1).
    if (sansDonneesHorsLigne(profils, horsLigne: horsLigne)) {
      return EtatSansDonnees(
        quoi: t.foyer.profilsSansDonnees,
        onAction: () => _relire(ref),
      );
    }

    return BlocAsynchrone<List<ProfilEleveFoyer>>(
      valeur: profils,
      squelette: const Skeleton.liste(),
      onReessayer: () => _relire(ref),
      vide: EtatSysteme(
        nature: NatureEtat.aucunResultat,
        titre: t.foyer.vide.titre,
        phrase: t.foyer.vide.phrase,
      ),
      construire: (List<ProfilEleveFoyer> p) =>
          _ListeMembres(p, aller, grille: grille),
    );
  }
}

class _ListeMembres extends ConsumerWidget {
  const _ListeMembres(this.profils, this.aller, {required this.grille});

  final List<ProfilEleveFoyer> profils;

  final void Function(String chemin) aller;

  final bool grille;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final DateTime maintenant = ref.watch(horlogeFoyerProvider)();
    // L'inscription en cours de chaque membre sans classe connue
    // (`v_parcours_onboarding`, 0043). Non appliquee en production : la
    // lecture echoue, et la page le dit une fois au lieu d'inventer une
    // etape.
    final AsyncValue<List<ParcoursApprenant>> parcours = ref.watch(
      parcoursFoyerProvider,
    );

    bool classesIndisponibles = false;
    final List<String> classesEnEchec = <String>[];
    final List<Widget> cartes = <Widget>[];
    final AsyncValue<Map<String, AccentProfil>> accents = ref.watch(
      accentsProfilsProvider,
    );
    // FI-4 : la finance de chaque enfant, quand la source la rend.
    final Map<String, FinancesProfil> finances = financesParProfil(
      ref.watch(financesFoyerProvider),
    );
    for (final ProfilEleveFoyer profil in profils) {
      final ClasseMembre classe = classeMembreLue(
        ref.watch(classesMembreProvider(profil.eleveId)),
      );
      if (classeIndisponible(classe)) {
        classesIndisponibles = true;
      }
      if (classeEnEchec(classe)) {
        classesEnEchec.add(profil.eleveId);
      }
      final FinancesProfil? finance = finances[profil.eleveId];
      final Widget carte = CarteMembre(
        profil: profil,
        legende: legendeMembre(
          profil: profil,
          classe: classe,
          maintenant: maintenant,
          inscription: etapeInscriptionLue(parcours, profil.eleveId),
          // Une seule date pour une seule echeance (R1-11) : quand la
          // pastille de periode dit deja « Financé jusqu'au » ce jour-la,
          // la legende ne repete pas « Accès jusqu'au ».
          avecAcces: !memeEcheance(finance?.periode?.fin, profil.finAcces),
        ),
        accent: accentLu(accents, profil.eleveId),
        finance: finance,
        onPress: () => aller(Routes.ficheElevePour(profil.eleveId)),
      );
      // Une action sous la carte, jamais dedans (aucun bouton dans un
      // bouton : toute la carte ouvre la fiche). « Recharger » quand le
      // profil en a besoin, le meme flux que la recharge de plusieurs
      // profils, l'enfant coche (guide V4 §4) ; sinon « Voir le détail »,
      // sa fiche Finances (02_DECOUPAGE FI-4, R1-08). Le prenom est dans le
      // nom lu, pas dans le libelle visible (R1-10).
      final LienFleche? action = finance == null
          ? null
          : aRecharger(finance)
          ? LienFleche(
              key: FoyerPage.rechargerPourKey(profil.eleveId),
              libelle: t.foyer.finances.recharger,
              libelleSemantique: t.foyer.finances.rechargerPour(
                prenom: profil.prenom,
              ),
              onPress: () =>
                  aller(Routes.rechargePour(<String>[profil.eleveId])),
            )
          : LienFleche(
              key: FoyerPage.voirDetailKey(profil.eleveId),
              libelle: t.foyer.finances.voirDetail,
              libelleSemantique: t.foyer.finances.voirDetailSemantique(
                dePrenom: deDevant(
                  profil.prenom,
                  cle: 'foyer.finances.voirDetailSemantique',
                ),
              ),
              onPress: () =>
                  aller(Routes.ficheEleveSousPage(profil.eleveId, 'finances')),
            );
      cartes.add(
        action == null
            ? carte
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  carte,
                  Ecart.vSm,
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: action,
                  ),
                ],
              ),
      );
    }

    final TextStyle note = palette.inkMuted.applyTo(
      Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // FI-4 (guide V4 §5.1, maquette 03) : la synthese des soldes en tete,
        // puis les cartes des enfants.
        SyntheseSoldesFoyer(
          onRechargerPlusieurs: () => aller(Routes.tuteurFoyerRecharge),
        ),
        // Une carte par enfant (maquette 11, K-62), separees par l'ecart des
        // jetons (K-55).
        Semantics(
          header: true,
          child: Text(
            // « Profils élèves » pour tous les titulaires (FI-Q3 (b), decide
            // par delegation le 05/10) : juste aussi quand le titulaire
            // adulte suit lui-meme des cours.
            t.foyer.membres,
            style: palette.inkStrong.applyTo(
              Theme.of(context).textTheme.titleMedium ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vSm,
        if (grille) _GrilleCartes(cartes) else PileCartes(children: cartes),
        if (classesIndisponibles) ...<Widget>[
          Ecart.vSm,
          Text(t.foyer.classesIndisponibles, style: note),
        ],
        if (parcours.hasError) ...<Widget>[
          Ecart.vSm,
          Text(
            key: FoyerPage.inscriptionIllisibleKey,
            t.foyer.inscriptionIllisible,
            style: note,
          ),
        ],
        if (classesEnEchec.isNotEmpty) ...<Widget>[
          Ecart.vSm,
          Text(t.foyer.classesEchec, style: note),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: LienFleche(
              key: FoyerPage.relireClassesKey,
              libelle: t.foyer.relireClasses,
              onPress: () {
                for (final String id in classesEnEchec) {
                  ref.invalidate(classesMembreProvider(id));
                }
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// La carte du titulaire adulte : la carte d'identite du Compte, reprise
/// telle quelle (K-51), son role dit en une phrase entiere (« Vous etes
/// titulaire du foyer », K-41 ; libelle provisoire, lexique D4) et sa photo
/// (`PhotoEleve`, K-44). Aucune pastille pour l'etat normal (E12). Sa
/// lecture a ses propres etats : squelette, erreur avec « Reessayer », et,
/// sans reseau, « hors ligne » dit comme tel, comme les profils eleves.
class _CarteTitulaire extends ConsumerWidget {
  const _CarteTitulaire(this.vue);

  final FoyerTitulaireVM vue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    // Hors ligne, une identite deja lue reste affichee ; sans elle, le bloc
    // dit ce qui manque, le bandeau dit le reseau (EA-HL-DOUBLE-1).
    final AsyncValue<IdentiteTitulaire> identite = lectureHorsLigne(
      ref.watch(identiteTitulaireProvider),
      horsLigne: horsLigne,
    );
    void relire() => ref.invalidate(identiteTitulaireProvider);
    if (sansDonneesHorsLigne(identite, horsLigne: horsLigne)) {
      return EtatSansDonnees(
        quoi: t.foyer.titulaireSansDonnees,
        onAction: relire,
      );
    }
    return BlocAsynchrone<IdentiteTitulaire>(
      valeur: identite,
      squelette: const Skeleton(hauteur: AppSpacing.respiration * 2),
      onReessayer: relire,
      construire: (IdentiteTitulaire lue) => CarteIdentiteCompte(
        identite: lue,
        large: AppGabarit.de(context).estLarge,
        role: t.adulte.famille.titulaire,
        pastilleEtatNormal: false,
        photo: (double diametre) => PhotoEleve(
          prenom: lue.prenom,
          cleAvatar: vue.cleAvatar,
          diametre: diametre,
        ),
      ),
    );
  }
}
