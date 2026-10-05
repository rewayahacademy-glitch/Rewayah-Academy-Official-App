// MA-3 : l'Accueil de l'eleve en Mode Accessibilite (doc 06 §5, MA18,
// planches 1 et 3 rectifiees).
//
// Dans l'ordre : une salutation d'une ligne, « Prochaine seance » (la carte
// de seance CL-4 et son emplacement d'entree unique, R4), un seul bouton
// contextuel, « Avant le prochain cours » (3 au plus), « Lire le Coran »,
// « Besoin d'aide ? » en dernier (MA14). Retires : cloche, decor, pastille
// « Aujourd'hui », age, statistiques, phrase de promesse. Aucune couleur
// nouvelle (K-37), aucun appel serveur (K-28).
//
// DASH-MA-PROD : monte sur la vraie route de l'eleve (`/eleve`) quand le
// Mode Accessibilite est actif (`AccueilEleveSelonPresentation`), ses
// donnees lues dans un port neutre par defaut (K-09) et ses cinq etats
// (D11).
//
// MA-2COL-1 : les deux colonnes de MA-3 reviennent, comme la fiche ELV-02-MA
// le prevoit (DASH_STRATEGIE, « une colonne ; deux a partir de 840 /
// facteur de texte ; pas de Bento ») : Q3 ecarte le Bento, pas cette
// seconde colonne.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/port_accueil_accessibilite.dart';
import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/tc_groupe/group_home_vm.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../tc_espace_groupe/carte_session.dart';
import '../tc_espace_groupe/emplacements_groupe.dart';
import '../tc_mes_groupes/photo_enseignant.dart';

/// Largeur utile, divisee par le facteur de texte, a partir de laquelle
/// l'Accueil passe en deux colonnes (K-42 point 6, MA15, fiche ELV-02-MA).
const double seuilDeuxColonnesAccueil = 840;

/// L'Accueil de l'eleve en Mode Accessibilite.
///
/// Le seul bouton dominant est celui de la carte de seance : « Rejoindre »
/// quand l'emplacement d'entree en est un, sinon « Voir ma classe » sous la
/// ligne d'etat (jamais les deux, R4). Tout le reste est une ligne d'une
/// seule cible.
///
/// Une colonne ; deux a partir de [seuilDeuxColonnesAccueil] de largeur
/// utile divisee par le facteur de texte (fiche ELV-02-MA) : la salutation
/// et la seance gardent toute la largeur, puis « Avant le prochain cours » a
/// cote de « Lire le Coran » et de l'aide, lus dans cet ordre. Hors contenu
/// (chargement mis a part), une seule colonne. Deux formes :
///
/// - [AccueilAccessibilite.new] recoit ses donnees (tests de composant) ;
/// - [AccueilAccessibilite.lu] les lit dans [donneesAccueilAccessibiliteProvider]
///   et porte les cinq etats (D11) : chargement (squelette fidele, apres le
///   delai de `Skeleton`), contenu, vide (aucune Classe), erreur (ce qui
///   manque, puis « Reessayer », K-59) et hors ligne (bandeau de
///   `PageShell`, entree inerte). Une source en echec n'emporte que ce
///   qu'elle remplit : « Lire le Coran » et l'aide restent (D11). Jamais un
///   prenom ni une Classe de remplacement (D10).
class AccueilAccessibilite extends ConsumerWidget {
  /// Cree l'Accueil a partir de ses donnees.
  const AccueilAccessibilite({
    required String this.prenom,
    required GroupHomeVM this.espace,
    required this.onVoirClasse,
    required this.onCoran,
    required this.onAide,
    required bool this.tutoiement,
    super.key,
    this.onRejoindre,
    this.onTache,
  }) : onRejoindreEspace = null;

  /// Cree l'Accueil qui lit sa source (route de l'eleve, demonstration).
  ///
  /// [onRejoindreEspace] recoit la Classe lue : l'entree en salle a besoin
  /// de sa seance.
  const AccueilAccessibilite.lu({
    required this.onVoirClasse,
    required this.onCoran,
    required this.onAide,
    super.key,
    this.onRejoindreEspace,
    this.onTache,
  }) : prenom = null,
       espace = null,
       tutoiement = null,
       onRejoindre = null;

  /// Le prenom de l'eleve, jamais son age ; nul : lu dans la source.
  final String? prenom;

  /// La Classe et sa prochaine seance, avec au plus trois actions ; nul :
  /// lue dans la source.
  final GroupHomeVM? espace;

  /// Vrai pour l'eleve mineur : l'Accueil le tutoie (« Ton heure ») ; un
  /// adulte est vouvoye (MA4). Suit l'age legal, jamais la presentation.
  final bool? tutoiement;

  /// « Voir ma classe » : le bouton quand on ne peut pas encore entrer.
  final VoidCallback onVoirClasse;

  /// « Rejoindre », porte par l'emplacement d'entree.
  final VoidCallback? onRejoindre;

  /// « Rejoindre », pour la forme qui lit sa source : recoit la Classe lue.
  final ValueChanged<GroupHomeVM>? onRejoindreEspace;

  /// Une ligne de « Avant le prochain cours ».
  final VoidCallback? onTache;

  /// « Lire le Coran ».
  final VoidCallback onCoran;

  /// « Besoin d'aide ? ».
  final VoidCallback onAide;

  /// Cle du bouton « Voir ma classe ».
  static const Key cleVoirClasse = ValueKey<String>('ma3-voir-classe');

  /// Cle de la mise en deux colonnes.
  static const Key cleDeuxColonnes = ValueKey<String>('ma3-deux-colonnes');

  /// Cle du squelette de chargement.
  static const Key cleSquelette = ValueKey<String>('ma3-squelette');

  /// Cle de l'etat vide (aucune Classe).
  static const Key cleVide = ValueKey<String>('ma3-vide');

  /// Cle de l'etat d'erreur de lecture.
  static const Key cleErreur = ValueKey<String>('ma3-erreur');

  /// Cle de l'etat « pas encore disponible » (port neutre).
  static const Key cleIndisponible = ValueKey<String>('ma3-indisponible');

  @override
  Widget build(BuildContext context, WidgetRef ref) => PageShell(
    child: LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        final double facteur = MediaQuery.textScalerOf(context).scale(1);
        final bool deuxColonnes =
            contraintes.maxWidth / facteur >= seuilDeuxColonnesAccueil;
        return _composer(ref, deuxColonnes: deuxColonnes);
      },
    ),
  );

  Widget _composer(WidgetRef ref, {required bool deuxColonnes}) {
    final String? prenomDonne = prenom;
    final GroupHomeVM? espaceDonne = espace;
    final Widget coranEtAide = _CoranEtAide(onCoran: onCoran, onAide: onAide);
    // En deux colonnes, « Lire le Coran » et l'aide vont a cote des taches :
    // chaque temps du bloc les place lui-meme. En une colonne, ils restent
    // sous le bloc, a la meme place dans tous les etats.
    final Widget? aCote = deuxColonnes ? coranEtAide : null;
    final Widget? dessous = deuxColonnes
        ? Padding(
            padding: const EdgeInsets.only(top: AppSpacing.section),
            child: coranEtAide,
          )
        : null;

    final Widget haut;
    if (prenomDonne != null && espaceDonne != null) {
      haut = _Haut(
        prenom: prenomDonne,
        espace: espaceDonne,
        tutoiement: tutoiement ?? false,
        horsLigne: false,
        onVoirClasse: onVoirClasse,
        onRejoindre: onRejoindre,
        onReessayer: null,
        onTache: onTache,
        aCote: aCote,
      );
    } else {
      final AsyncValue<DonneesAccueilAccessibilite> lecture = ref.watch(
        donneesAccueilAccessibiliteProvider,
      );
      // Tant que la reponse manque, l'appareil est repute en ligne.
      final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
      haut = BlocAsynchrone<DonneesAccueilAccessibilite>(
        valeur: lecture,
        squelette: _Squelette(key: cleSquelette, aCote: aCote),
        onReessayer: () => ref.invalidate(donneesAccueilAccessibiliteProvider),
        // Echec ou indisponibilite : en deux colonnes, le Coran et l'aide
        // restent dessous (D11), tentative perdue comprise.
        piedEchec: dessous,
        erreurVersEtat: (Object erreur, VoidCallback? reessayer) =>
            erreur is CapaciteIndisponible
            // La source n'existe pas encore (BR-1) : on le dit, sans
            // « Reessayer », et on mene a Ma classe.
            ? EtatSysteme(
                key: cleIndisponible,
                nature: NatureEtat.indisponible,
                titre: t.accessibilite.accueil.indisponibleTitre,
                phrase: t.accessibilite.accueil.indisponiblePhrase,
                libelleAction: t.accessibilite.accueil.voirMaClasse,
                onAction: onVoirClasse,
                dependance: erreur.dependance,
              )
            // K-59 : ce qui manque, la cause probable, quoi faire.
            : EtatSysteme(
                key: cleErreur,
                nature: NatureEtat.echecServeur,
                titre: t.accessibilite.accueil.erreurTitre,
                phrase: reessayer == null
                    ? t.commun.etats.reessaisEpuises
                    : t.accessibilite.accueil.erreurPhrase,
                onAction: reessayer,
              ),
        construire: (DonneesAccueilAccessibilite donnees) {
          final GroupHomeVM? lu = donnees.espace;
          if (lu == null) {
            // Sans Classe, aucune tache : une seule colonne.
            final Widget vide = _Vide(key: cleVide, prenom: donnees.prenom);
            return dessous == null
                ? vide
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[vide, dessous],
                  );
          }
          final ValueChanged<GroupHomeVM>? rejoindre = onRejoindreEspace;
          return _Haut(
            prenom: donnees.prenom,
            espace: lu,
            tutoiement: donnees.tutoiement,
            horsLigne: horsLigne,
            onVoirClasse: onVoirClasse,
            onRejoindre: rejoindre == null ? null : () => rejoindre(lu),
            // Hors ligne, « Reessayer » relit l'etat du reseau (precedent
            // de `fiche_groupe_page.dart`) : jamais un bouton grise (D9).
            // De retour en ligne, l'entree et « Voir ma classe » reviennent.
            onReessayer: () => ref.invalidate(horsLigneProvider),
            onTache: onTache,
            aCote: aCote,
          );
        },
      );
    }

    // Une Column dans les deux cas, `haut` toujours en tete : franchir le
    // seuil (fenetre redimensionnee, facteur de texte change) garde le meme
    // element, donc le meme State du bloc asynchrone, ses reessais et ses
    // minuteries (MA-2COL-1b).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        haut,
        if (!deuxColonnes) ...<Widget>[Ecart.vSection, coranEtAide],
      ],
    );
  }
}

/// La rangee des deux colonnes : [gauche] puis [droite], lues et parcourues
/// au clavier dans cet ordre (MA-3).
class _DeuxColonnes extends StatelessWidget {
  const _DeuxColonnes({required this.gauche, required this.droite});

  final Widget gauche;
  final Widget droite;

  @override
  Widget build(BuildContext context) => Row(
    key: AccueilAccessibilite.cleDeuxColonnes,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Expanded(child: gauche),
      const SizedBox(width: AppSpacing.xxl),
      Expanded(child: droite),
    ],
  );
}

/// A texte agrandi (au-dela de 130 %), le trait d'union est suivi d'un
/// gluon de mots (U+2060, WORD JOINER) a l'affichage : aucune coupure de
/// ligne apres lui, « As-salāmu », « An-Nour » restent entiers
/// (lecon 8, precedent MA-4 de `espace_groupe_page.dart`). Rendu a 100 %
/// inchange.
String _insecable(BuildContext context, String texte) =>
    MediaQuery.textScalerOf(context).scale(1) > 1.3
    ? texte.replaceAll('-', '-\u2060')
    : texte;

/// La salutation d'une ligne.
class _Salutation extends StatelessWidget {
  const _Salutation({required this.prenom});

  final String prenom;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return Semantics(
      header: true,
      child: TexteSansCoupure(
        _insecable(context, t.accessibilite.accueil.salutation(prenom: prenom)),
        style: palette.inkStrong.applyTo(
          textes.headlineSmall ?? const TextStyle(),
        ),
      ),
    );
  }
}

/// Le haut de l'Accueil : salutation, prochaine seance, avant le cours.
class _Haut extends StatelessWidget {
  const _Haut({
    required this.prenom,
    required this.espace,
    required this.tutoiement,
    required this.horsLigne,
    required this.onVoirClasse,
    required this.onRejoindre,
    required this.onReessayer,
    required this.onTache,
    required this.aCote,
  });

  final String prenom;
  final GroupHomeVM espace;
  final bool tutoiement;
  final bool horsLigne;
  final VoidCallback onVoirClasse;
  final VoidCallback? onRejoindre;

  /// « Reessayer » de l'emplacement d'entree hors ligne ; obligatoire des
  /// que [horsLigne] peut etre vrai (aucun bouton grise, D9).
  final VoidCallback? onReessayer;
  final VoidCallback? onTache;

  /// En deux colonnes, ce qui va a cote des taches (« Lire le Coran », puis
  /// l'aide) ; nul : une seule colonne.
  final Widget? aCote;

  @override
  Widget build(BuildContext context) {
    final bool mobile = AppGabarit.de(context) == Gabarit.mobile;

    final Widget voirClasse = ActionPrincipale(
      key: AccueilAccessibilite.cleVoirClasse,
      libelle: t.accessibilite.accueil.voirMaClasse,
      onPress: onVoirClasse,
      fleche: true,
      pleineLargeur: mobile,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Salutation(prenom: prenom),
        const SizedBox(height: AppSpacing.xxxl),
        SectionHeader(titre: t.accessibilite.accueil.prochaineSeance),
        Ecart.vMd,
        CarteSession(
          espace: espace,
          onRejoindre: onRejoindre,
          tutoiement: tutoiement,
          // Hors ligne, l'entree reste presente et inerte (D9) ; le bandeau
          // de `PageShell` dit pourquoi.
          horsLigne: horsLigne,
          onReessayer: onReessayer,
          identite: _IdentiteClasse(identite: espace.identite),
          actionHorsEntree: mobile
              ? voirClasse
              : Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[voirClasse],
                ),
        ),
        Ecart.vSection,
        if (aCote case final Widget droite)
          _DeuxColonnes(
            gauche: _Taches(espace: espace, onTache: onTache),
            droite: droite,
          )
        else
          _Taches(espace: espace, onTache: onTache),
      ],
    );
  }
}

/// L'etat vide : aucune Classe encore attribuee. La salutation reste (le
/// prenom est lu), puis le constat et la suite ; le chemin direct est
/// « Lire le Coran » et l'aide, juste dessous.
class _Vide extends StatelessWidget {
  const _Vide({required this.prenom, super.key});

  final String prenom;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      _Salutation(prenom: prenom),
      const SizedBox(height: AppSpacing.xxxl),
      AppCard(
        dominante: true,
        child: EmptyState(
          message: t.accessibilite.accueil.videTitre,
          invitation: t.accessibilite.accueil.videPhrase,
          icone: AppIcons.cours,
          registre: RegistreVide.subi,
        ),
      ),
    ],
  );
}

/// Le squelette du haut de l'Accueil : la salutation, le titre de section,
/// la carte de seance, puis les lignes « Avant le prochain cours ». Aucune
/// fausse donnee (DESIGN-GOV §4 bis.6) ; le delai d'apparition est celui
/// de `Skeleton`.
class _Squelette extends StatelessWidget {
  const _Squelette({required this.aCote, super.key});

  /// En deux colonnes, le Coran et l'aide, deja la, a cote des lignes ; nul :
  /// une seule colonne.
  final Widget? aCote;

  @override
  Widget build(BuildContext context) {
    final Widget? droite = aCote;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Skeleton(hauteur: AppSpacing.xxxl),
        const SizedBox(height: AppSpacing.xxxl),
        const Skeleton(hauteur: AppSpacing.xxl),
        Ecart.vMd,
        const Skeleton.tuileBento(hauteur: AppPage.hauteurChoix * 2),
        Ecart.vSection,
        if (droite == null)
          const Skeleton.liste()
        else
          _DeuxColonnes(gauche: const Skeleton.liste(), droite: droite),
      ],
    );
  }
}

/// « Lire le Coran », puis l'aide, dernier bloc du contenu (MA14). Ne
/// dependent d'aucune lecture : ils restent dans tous les etats.
class _CoranEtAide extends StatelessWidget {
  const _CoranEtAide({required this.onCoran, required this.onAide});

  final VoidCallback onCoran;
  final VoidCallback onAide;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      GroupeReglages(
        lignes: <LigneRubrique>[
          LigneRubrique(
            libelle: t.accessibilite.accueil.lireCoran,
            legende: t.accessibilite.accueil.lireCoranDetail,
            icone: AppIcons.coran,
            onPress: onCoran,
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.xxl),
      GroupeReglages(
        lignes: <LigneRubrique>[
          LigneRubrique(
            libelle: t.accessibilite.accueil.aide,
            icone: AppIcons.info,
            onPress: onAide,
          ),
        ],
      ),
    ],
  );
}

/// La Classe, son enseignant et sa photo, au-dessus des heures.
class _IdentiteClasse extends StatelessWidget {
  const _IdentiteClasse({required this.identite});

  final GroupSummaryVM identite;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    // AVATAR-1 : le nom de la Classe est le titre ; l'enseignant est un couple
    // avatar + nom du composant partage, centre verticalement sur le cercle.
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            _insecable(context, identite.libelle),
            style: palette.inkStrong.applyTo(
              textes.titleMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vSm,
          AvatarNom.enLigne(
            prenom: identite.enseignant.nomAffichage,
            nom: t.accessibilite.accueil.avec(
              nomme: LibellesGroupe.enseignantNomme(identite.enseignant),
            ),
            ecart: AppSpacing.lg,
            styleNom: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
            avatar: PhotoEnseignant(
              enseignant: identite.enseignant,
              diametre: AppAvatar.moyen,
              // Un eleve ne voit jamais d'avertissement pour une photo
              // manquante : les initiales en repli (MA-3).
              repliInitiales: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// « Avant le prochain cours » : trois lignes au plus, chacune une cible.
class _Taches extends StatelessWidget {
  const _Taches({required this.espace, required this.onTache});

  final GroupHomeVM espace;
  final VoidCallback? onTache;

  @override
  Widget build(BuildContext context) {
    if (espace.avantProchainCours.isEmpty) {
      return EmplacementAvantProchainCours(
        actions: espace.avantProchainCours,
        portBranche: true,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SectionHeader(titre: LibellesGroupe.avantProchainCours),
        Ecart.vMd,
        GroupeReglages(
          lignes: <LigneRubrique>[
            for (final SlotAction action in espace.avantProchainCours.take(3))
              LigneRubrique(
                libelle: action.libelle,
                icone: AppIcons.cours,
                onPress: onTache,
              ),
          ],
        ),
      ],
    );
  }
}
