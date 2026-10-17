import 'package:flutter/material.dart';

import '../../core/appairage/service_appairage.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bandeau_attention.dart';

/// Vrai quand les donnees **confirment** qu'aucun appareil n'est pret pour
/// [eleveId] : la liste des appareils du foyer est lue, et aucun appareil
/// actif (non revoque) n'y est appaire a cet eleve.
///
/// Pure. Une liste illisible ou en cours de lecture ne confirme rien : le
/// blocage n'est alors pas affiche (mandat, Accueil : « seulement si confirme
/// par les donnees »).
bool aucunAppareilPret(List<AppareilAppaire> appareils, String eleveId) =>
    !appareils.any((AppareilAppaire a) => a.actif && a.profilId == eleveId);

/// Le blocage prioritaire de l'Accueil : **un seul**, avec **une seule**
/// action contextualisee (defaut C3 des maquettes, qui en montraient deux).
///
/// Aujourd'hui le seul blocage confirme par les donnees est « aucun appareil
/// pret » ; « photo requise » n'a aucune regle en base (point P6) et le
/// dossier a completer relève du portail d'attente.
///
/// L4-05 : **un seul rendu aux deux largeurs**, le [BandeauAttention] du
/// depot (avertissement : icone, titre, phrase). Avant, une carte jaune a
/// bouton plein sur telephone et un texte nu a bouton plein sur bureau
/// faisaient deux composants pour un bloc. Le bouton « Connecter un
/// appareil » reste le seul bouton plein de l'Accueil bloque (decision D5,
/// DASH-TUT-CTA, qui prime sur la fiche L4-05).
class BandeauBlocage extends StatelessWidget {
  /// Cree le bandeau.
  const BandeauBlocage({
    required this.prenom,
    required this.onConnecter,
    super.key,
  });

  /// La cle du bandeau d'alerte, identique a toute largeur.
  static const Key cleAlerte = ValueKey<String>('accueil-alerte-appareil');

  /// Le prenom de l'eleve concerne.
  final String prenom;

  /// Ouvre l'emetteur de code d'appairage de cet eleve.
  final VoidCallback onConnecter;

  @override
  Widget build(BuildContext context) {
    return BandeauAttention(
      key: cleAlerte,
      titre: t.tuteur.accueil.blocageAppareilTitre(prenom: prenom),
      message: t.tuteur.accueil.blocageAppareilPhrase(prenom: prenom),
      // L4-05-reprise (defaut D-1) : le bouton garde son propre noeud
      // semantique, avec son role de bouton. Sans cette frontiere, il se
      // fondait dans le titre de l'alerte (titre et bouton a la fois).
      action: Semantics(
        container: true,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: ActionPrincipale(
            libelle: t.tuteur.accueil.connecterAppareil,
            onPress: onConnecter,
            // D5 / DASH-TUT-CTA : la tache immediate porte le seul bouton plein.
            niveau: NiveauAction.principale,
            pleineLargeur: false,
          ),
        ),
      ),
    );
  }
}
