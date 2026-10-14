import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/tc_classe/roster_classe_vm.dart';
import '../../core/tc_classe/session_live_vm.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/tc_horloge/session_clock_vm.dart';
import '../../core/tc_observation/port_annonce_observation.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/status_pill.dart';
import '../tc_observation_ui/indicateur_observation.dart';
import 'encre_salle.dart';
import 'roster_classe.dart';
import 'vue_classe_live.dart';

/// Le temps restant, tel que l'en-tete l'ecrit.
///
/// **Fonction pure, et elle ne calcule aucune duree.** Elle met en mots ce que
/// `SessionClockVM.restant` contient deja : cette duree est derivee de
/// `calculeeAUtc`, l'instant serveur de reference, et non de l'horloge de
/// l'appareil. Un en-tete qui ferait la soustraction lui-meme afficherait le
/// decalage de la machine de l'enseignant.
///
/// Rend `null` quand il n'y a rien a dire : pas d'horloge, ou une seance
/// terminee. Une prolongation, elle, se dit -- **sans compte a rebours**, parce
/// qu'il serait negatif (invariant 3 de `SessionClockVM`).
String? libelleTempsRestant(SessionClockVM? horloge) {
  if (horloge == null) {
    return null;
  }
  if (horloge.phase == PhaseSeance.prolongee) {
    return t.tc.classe.entete.coursEnCours;
  }
  final Duration? restant = horloge.restant;
  if (restant == null) {
    return null;
  }
  final int heures = restant.inHours;
  final int minutes = restant.inMinutes % Duration.minutesPerHour;
  // DUREE-INSECABLE-1 : la duree restante n'est jamais scindee.
  return LibellesGroupe.insecable(
    heures == 0
        ? t.tc.classe.entete.resteMinutes(minutes: restant.inMinutes)
        : t.tc.classe.entete.resteHeuresMinutes(
            heures: heures,
            minutes: minutes.toString().padLeft(2, '0'),
          ),
  );
}

/// Le nom de l'enseignant, precede de son titre.
///
/// **Sayyid / Sayyida, jamais Ustaz** (decision D-02). Le titre manquant n'est
/// pas une faute : la base ne le porte pas encore, et l'ecrire au hasard serait
/// pire que de ne pas l'ecrire.
///
/// Les formes arabes (سيد / سيدة) sont fournies par Agent A dans
/// `tc.groupe.enseignant.*`, pas ici : ce sous-arbre `tc.classe.entete.*` ne
/// porte que le francais.
String nomAvecTitre(EnseignantDeClasse enseignant) =>
    switch (enseignant.titre) {
      TitreEnseignant.sayyid =>
        '${t.tc.classe.entete.titreEnseignant.sayyid} '
            '${enseignant.nomAffichage}',
      TitreEnseignant.sayyida =>
        '${t.tc.classe.entete.titreEnseignant.sayyida} '
            '${enseignant.nomAffichage}',
      null => enseignant.nomAffichage,
    };

/// L'en-tete de la Classe Live (spec section 9.1).
///
/// Groupe, titre et nom de l'enseignant, temps restant. Puis, sur une seconde
/// ligne et seulement quand il y a quelque chose a dire : l'etat du lien,
/// l'avertissement d'arriere-plan, et les annonces d'observation.
///
/// **Discret par construction** : c'est le contenu pedagogique qui domine, et
/// `PageImmersive` pose deja cet en-tete au-dessus du contenu, jamais par-dessus.
class EnteteClasse extends StatelessWidget {
  /// Cree l'en-tete.
  const EnteteClasse({
    required this.session,
    required this.vue,
    required this.roster,
    super.key,
    this.annonces = const <AnnonceObservation>[],
    this.monTuteurObserve = false,
    this.onVoirRoster,
  });

  /// La seance live.
  final SessionLiveVM session;

  /// La composition de l'ecran.
  final VueClasseLive vue;

  /// Le roster, pour le compteur compact.
  final RosterClasseVM roster;

  /// Les observateurs annonces. Vide = personne n'observe.
  ///
  /// **Reserve a l'enseignant** : le serveur refuse cette lecture a tout autre
  /// appelant, et elle porte les prenoms de TOUS les enfants observes.
  final List<AnnonceObservation> annonces;

  /// Vrai quand le tuteur de l'eleve qui regarde cet ecran observe la seance.
  ///
  /// **A ne remplir que pour l'eleve lui-meme.** C'est une information sur SON
  /// foyer : la faire circuler vers un autre role la transformerait en
  /// information sur le foyer d'autrui.
  final bool monTuteurObserve;

  /// Ouvre la feuille de roster. `null` quand le roster est deja en colonne.
  final VoidCallback? onVoirRoster;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final String? restant = libelleTempsRestant(session.horloge);
    final String? compteur = vue.compteurCompact;
    final VoidCallback? voirRoster = onVoirRoster;
    final String? mot = _motDuLien(vue.motLien);
    final String? photoEnseignant = session.enseignant.photoCleOuUrl;
    // L'en-tete est pose sur le fond inverse de la salle (`PageImmersive`),
    // qui donne son encre par `DefaultTextStyle`. Les styles du theme portent
    // l'encre du fond clair : on leur rend celle de la paire, sinon le nom
    // s'ecrit en encre sombre sur fond sombre (releve ENS-PAYS-1, capture
    // 320 x2 de la classe en direct).
    final Color? encre = DefaultTextStyle.of(context).style.color;
    final TextStyle styleNom = (textes.titleSmall ?? const TextStyle())
        .copyWith(color: encre);
    final TextStyle styleLigne = (textes.labelMedium ?? const TextStyle())
        .copyWith(color: encre);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            // La photo enseignant est OBLIGATOIRE (decision D-01). Quand elle
            // manque, on ne pose pas un avatar generique : cela masquerait une
            // donnee absente au lieu de la signaler. On ecrit qu'elle manque.
            Expanded(
              child: MergeSemantics(
                // AVATAR-1 : couple avatar + nom du composant partage, le nom
                // de l'enseignant centre sur le cercle, une ligne de role (la
                // classe).
                // ENS-PAYS-SALLE-1 (decision Q-4 = b du 05/10) : le pays de
                // l'enseignant ne s'affiche que sur les cartes, jamais dans
                // la salle pendant le cours. Aucun `pays:` ici, aucune ligne
                // `PaysEnseignant` dans la branche sans photo.
                child: photoEnseignant != null
                    ? AvatarNom.enLigne(
                        prenom: session.enseignant.nomAffichage,
                        urlSignee: photoEnseignant,
                        nom: nomAvecTitre(session.enseignant),
                        role: session.libelleGroupe,
                        diametre: AppAvatar.petit,
                        ecart: AppSpacing.sm,
                        styleNom: styleNom,
                        styleRole: styleLigne,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            session.libelleGroupe,
                            overflow: TextOverflow.ellipsis,
                            style: styleNom,
                          ),
                          Text(
                            nomAvecTitre(session.enseignant),
                            overflow: TextOverflow.ellipsis,
                            style: styleLigne,
                          ),
                        ],
                      ),
              ),
            ),
            if (restant != null) ...<Widget>[
              Ecart.hSm,
              Text(restant, style: styleDuFond(context, textes.labelLarge)),
            ],
            if (compteur != null && voirRoster != null) ...<Widget>[
              Ecart.hSm,
              BoutonRoster(
                compteur: compteur,
                presents: roster.presents,
                attendus: roster.attendus,
                onOuvrir: voirRoster,
              ),
            ],
          ],
        ),
        if (session.enseignant.photoCleOuUrl == null) ...<Widget>[
          Ecart.vSm,
          StatusPill(
            libelle: t.tc.classe.entete.photoManquante,
            ton: TonEtat.avertissement,
          ),
        ],
        if (mot != null) ...<Widget>[
          Ecart.vSm,
          StatusPill(libelle: mot, ton: _tonDuLien(vue.motLien)),
        ],
        if (vue.avertitSuspension) ...<Widget>[
          Ecart.vSm,
          // **On ne promet rien.** Quand la plateforme suspend le processus,
          // aucune machine de reconnexion ne peut tenir parole : la phrase dit
          // le risque, elle n'annonce pas une coupure qui n'a pas eu lieu.
          Text(
            t.tc.classe.lien.retourDeSuspension,
            style: styleDuFond(context, textes.labelMedium),
          ),
        ],
        // **Le composant d'Agent G, pas une seconde ecriture du meme.** Il
        // porte deja la regle : rien quand personne n'observe, et aucune
        // notification de sortie (decision D-14) -- la ligne disparait, et
        // c'est tout.
        //
        // **La chaine est desormais entiere**, rejouee de bout en bout le
        // 21/09/2026 : `entrer_observation` (seule ecriture de
        // `guardian_session_visit`) est appelee par `EntreeObservationPage`,
        // atteignable par `/tc/observation/:seanceId`, vers laquelle le bouton
        // « Assister » du tuteur navigue maintenant
        // (`accueil_famille_page.dart`). Les migrations `0035` a `0037`, `0039`
        // et `0040` sont appliquees ; `0037` fait rendre `enfant_profile_id`,
        // sans quoi le panneau du tuteur aurait dit « Votre enfant n'a pas
        // d'image ouverte » meme camera ouverte.
        if (annonces.isNotEmpty) ...<Widget>[
          Ecart.vSm,
          IndicateurObservation(annonces: annonces),
        ],
        // **La symetrie cote enfant, dans la MEME colonne** : une mention, pas
        // un bloc. Elle ne s'allume que pour l'enfant reellement observe, et la
        // borne est en base -- `annonce_observation_pour_moi` (`0040`) porte
        // `enfant_profile_id = auth.uid()` dans son WHERE. Les quatre autres
        // enfants du groupe recoivent `observe: false` et ne lisent rien
        // (specification 11.3).
        if (monTuteurObserve) ...<Widget>[
          Ecart.vSm,
          const IndicateurObservationEnfant(visible: true),
        ],
      ],
    );
  }

  /// Le mot de l'etat du lien. `null` quand il n'y a rien a dire.
  ///
  /// « Connexion excellente » n'apporte rien pendant un cours et occuperait la
  /// place que le Coran prendra. Seuls les etats qui changent quelque chose se
  /// disent.
  static String? _motDuLien(MotLien mot) => switch (mot) {
    MotLien.aucun => null,
    MotLien.instable => t.tc.classe.lien.instable,
    MotLien.reconnexion => t.tc.classe.lien.reconnexion,
    MotLien.retabli => t.tc.classe.lien.retabli,
    MotLien.echec => t.tc.classe.lien.echec,
  };

  static TonEtat _tonDuLien(MotLien mot) => switch (mot) {
    MotLien.retabli => TonEtat.succes,
    MotLien.echec => TonEtat.alerte,
    MotLien.aucun ||
    MotLien.instable ||
    MotLien.reconnexion => TonEtat.avertissement,
  };
}
