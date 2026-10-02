import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:go_router/go_router.dart';

import '../../core/appairage/service_appairage.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_classes_foyer.dart';
import '../../core/capacites/port_identite_titulaire.dart';
import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/offres/offre_horaire.dart';
import '../../core/offres/service_offres.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../compte/compte_tuteur_page.dart' show CarteIdentiteCompte;
import '../compte/donnees_compte.dart' show identiteTitulaireProvider;
import '../compte/soldes_foyer.dart';
import 'ligne_membre.dart';
import 'photo_eleve.dart';
import 'place_adulte.dart';

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
/// decoratif. Sur bureau (a partir de 1200), deux colonnes comme le Compte.
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
    this.onRecharger,
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

  /// Ouvre la recharge depuis la section des soldes, sur bureau (EA-9,
  /// planche 6 ; la recharge vient avec EA-10).
  final VoidCallback? onRecharger;

  /// Ouvre « A propos du forfait famille » ; par defaut, la page est poussee
  /// sur le navigateur.
  final VoidCallback? onAProposForfait;

  /// Relance l'invitation apres un refus de validation (E5, doc section
  /// 10.3). Sans lui, le bouton n'est pas pose.
  final VoidCallback? onNouvelleDemande;

  /// La carte du titulaire.
  static const Key titulaireKey = Key('foyer.titulaire');

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
    final bool bureau = AppGabarit.de(context) == Gabarit.desktop;
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
    final Widget ajouter = ActionPrincipale(
      key: ajouterKey,
      libelle: t.foyer.ajouterProfil,
      fleche: true,
      pleineLargeur: AppGabarit.de(context) == Gabarit.mobile,
      onPress: () => aller(Routes.tuteurAjouterEnfant),
    );

    final Widget profils = KeyedSubtree(
      key: membresKey,
      child: _Membres(aller),
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
              // juste sous sa ligne d'etat (le seul bouton dominant reste
              // « Ajouter un profil eleve »).
              if (placePermetNouvelleDemande(adulte.place) &&
                  nouvelleDemande != null) ...<Widget>[
                Ecart.vMd,
                // Compact au bord de debut. `IntrinsicWidth` : sans lui,
                // `ActionPrincipale` s'etire a toute la colonne meme avec
                // `pleineLargeur: false` (son `Container.alignment`, motif
                // deja contourne ainsi ailleurs) ; borne par la colonne, le
                // libelle passe a la ligne a 200 %.
                Align(
                  alignment: AlignmentDirectional.centerStart,
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
              if (!bureau) ...<Widget>[Ecart.vXl, ajouter],
            ],
          );
    final Widget annexes = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Sur bureau, la colonne droite porte la section « Paiements du
        // foyer » elle-meme (planche 6, UX_REVIEW_07 ligne 7 a) : les soldes
        // et son seul bouton « Recharger » (un bouton dominant par colonne),
        // puis l'historique en une ligne. Sur telephone, une ligne vers la
        // page des paiements du foyer (EA-9).
        if (adulte != null && bureau) ...<Widget>[
          SoldesFoyerSection(
            titre: t.adulte.famille.paiementsFoyer,
            onRecharger: onRecharger,
          ),
          Ecart.vXl,
        ],
        if (adulte != null) ...<Widget>[
          GroupeReglages(
            key: paiementsFoyerKey,
            lignes: <LigneRubrique>[
              LigneRubrique(
                icone: AppIcons.finance,
                libelle: bureau
                    ? t.adulte.paiements.historique
                    : t.adulte.famille.paiementsFoyer,
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
      sousTitre: adulte == null ? t.foyer.sousTitre : null,
      actionsEntete: <Widget>[if (bureau) ajouter],
      entete: bureau || adulte != null
          ? null
          : Align(alignment: AlignmentDirectional.centerStart, child: ajouter),
      child: bureau
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 3, child: membres),
                Ecart.hXxl,
                Expanded(flex: 2, child: annexes),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[membres, Ecart.vSection, annexes],
            ),
    );
  }
}

/// Les membres : chargement, contenu, vide, erreur, hors ligne.
class _Membres extends ConsumerWidget {
  const _Membres(this.aller);

  final void Function(String chemin) aller;

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

    // Sans reseau, un echec se dit comme tel : « hors ligne », pas « le
    // serveur n'a pas repondu ».
    if (horsLigne &&
        profils.hasError &&
        profils.error is! CapaciteIndisponible) {
      return EtatSysteme(
        nature: NatureEtat.horsLigne,
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
      construire: (List<ProfilEleveFoyer> p) => _ListeMembres(p, aller),
    );
  }
}

class _ListeMembres extends ConsumerWidget {
  const _ListeMembres(this.profils, this.aller);

  final List<ProfilEleveFoyer> profils;

  final void Function(String chemin) aller;

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
    final List<LigneRubrique> lignes = <LigneRubrique>[];
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
      lignes.add(
        ligneMembre(
          profil: profil,
          classe: classe,
          maintenant: maintenant,
          inscription: etapeInscriptionLue(parcours, profil.eleveId),
          onPress: () => aller(Routes.ficheElevePour(profil.eleveId)),
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
        GroupeReglages(titre: t.foyer.membres, lignes: lignes),
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
    final AsyncValue<IdentiteTitulaire> identite = ref.watch(
      identiteTitulaireProvider,
    );
    void relire() => ref.invalidate(identiteTitulaireProvider);
    if ((ref.watch(horsLigneProvider).value ?? false) &&
        identite.hasError &&
        identite.error is! CapaciteIndisponible) {
      return EtatSysteme(nature: NatureEtat.horsLigne, onAction: relire);
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
