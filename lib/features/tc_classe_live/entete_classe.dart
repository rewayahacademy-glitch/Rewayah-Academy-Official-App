import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/tc_classe/roster_classe_vm.dart';
import '../../core/tc_classe/session_live_vm.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/tc_horloge/session_clock_vm.dart';
import '../../core/tc_observation/port_annonce_observation.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/status_pill.dart';
import '../tc_observation_ui/indicateur_observation.dart';
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
  return heures == 0
      ? t.tc.classe.entete.resteMinutes(minutes: restant.inMinutes)
      : t.tc.classe.entete.resteHeuresMinutes(
          heures: heures,
          minutes: minutes.toString().padLeft(2, '0'),
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
    this.onVoirRoster,
  });

  /// La seance live.
  final SessionLiveVM session;

  /// La composition de l'ecran.
  final VueClasseLive vue;

  /// Le roster, pour le compteur compact.
  final RosterClasseVM roster;

  /// Les observateurs annonces. Vide = personne n'observe.
  final List<AnnonceObservation> annonces;

  /// Ouvre la feuille de roster. `null` quand le roster est deja en colonne.
  final VoidCallback? onVoirRoster;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final String? restant = libelleTempsRestant(session.horloge);
    final String? compteur = vue.compteurCompact;
    final VoidCallback? voirRoster = onVoirRoster;
    final String? mot = _motDuLien(vue.motLien);
    // `null` quand l'ecran d'entree ne connaissait pas l'enseignant : on
    // n'ecrit alors ni nom ni « photo manquante », plutot qu'un enseignant
    // invente.
    final EnseignantDeClasse? enseignant = session.enseignant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            // La photo enseignant est OBLIGATOIRE (decision D-01). Quand elle
            // manque, on ne pose pas un avatar generique : cela masquerait une
            // donnee absente au lieu de la signaler. On ecrit qu'elle manque.
            if (enseignant?.photoCleOuUrl case final String photo) ...<Widget>[
              AvatarTile(prenom: enseignant!.nomAffichage, urlSignee: photo),
              Ecart.hSm,
            ],
            Expanded(
              child: MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      session.libelleGroupe,
                      overflow: TextOverflow.ellipsis,
                      style: textes.titleSmall ?? const TextStyle(),
                    ),
                    if (enseignant != null)
                      Text(
                        nomAvecTitre(enseignant),
                        overflow: TextOverflow.ellipsis,
                        style: textes.labelMedium ?? const TextStyle(),
                      ),
                  ],
                ),
              ),
            ),
            if (restant != null) ...<Widget>[
              Ecart.hSm,
              Text(restant, style: textes.labelLarge ?? const TextStyle()),
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
        if (enseignant != null && enseignant.photoManquante) ...<Widget>[
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
            style: textes.labelMedium ?? const TextStyle(),
          ),
        ],
        // **Le composant d'Agent G, pas une seconde ecriture du meme.** Il
        // porte deja la regle : rien quand personne n'observe, et aucune
        // notification de sortie (decision D-14) -- la ligne disparait, et
        // c'est tout.
        //
        // **Cette ligne ne peut pas encore s'allumer, et ce n'est pas une
        // panne.** La chaine, rejouee de bout en bout le 21/09/2026 :
        // `annonces_observation` ne lit que `guardian_session_visit` ou
        // `role = 'guardian_observer'` et `left_at is null`
        // (`0033_tc_vues_rpc.sql:1292-1296`) ; la seule ecriture de cette
        // table est `entrer_observation` (`0033:1172`) ; `entrer_observation`
        // n'est appelee que par `VisiteObservationSupabase`
        // (`lib/core/tc_observation/port_visite_observation.dart:97`), que
        // seule `EntreeObservationPage` emprunte, laquelle n'est atteignable
        // que par `/tc/observation/:seanceId` -- une route bien enregistree
        // (`app_router.dart:591`) mais vers laquelle AUCUN fichier de `lib/`
        // ne navigue : `RoutesTcG.versObservation` n'a aucun appelant. Le
        // bouton « Assister » du tuteur passe encore par la porte d'avant,
        // `assister_seance` (`accueil_famille_page.dart:181` ->
        // `service_video.dart:131`).
        //
        // La bascule d'« Assister » vers la porte d'observation est en attente
        // VOLONTAIRE : sans la migration `0037`, `entrer_observation` ne rend
        // pas `enfant_profile_id`, et le panneau du tuteur lui dirait
        // « Votre enfant n'a pas d'image ouverte » meme camera ouverte.
        // `0037` n'est pas appliquee (derniere migration en base le
        // 21/09/2026 : `0033_tc_vues_rpc_durcissement_grants`). Basculer
        // avant, ce serait livrer au parent l'inverse du service promis.
        if (annonces.isNotEmpty) ...<Widget>[
          Ecart.vSm,
          IndicateurObservation(annonces: annonces),
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
