import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/port_acces_foyer.dart';
import '../../core/capacites/port_identite_titulaire.dart';
import '../../core/capacites/port_paiements_foyer.dart';
import '../../core/capacites/port_profil_eleve_titulaire.dart';
import '../../core/capacites/port_support.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/jour_du_mois.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';

// Les lectures du Compte du tuteur (lot E du chantier Tuteur V1).
//
// Chaque provider passe par le PORT du contrat K6, jamais par un adaptateur :
// le provider de production du port decide de la source (adaptateur reel ou
// implementation « indisponible »), et les tests le remplacent par un double.

/// L'identite du titulaire, relue quand la personne connectee change.
final FutureProvider<IdentiteTitulaire> identiteTitulaireProvider =
    FutureProvider<IdentiteTitulaire>((Ref ref) {
      ref.watch(
        sessionProvider.select((SessionState session) => session.profileId),
      );
      return ref.watch(portIdentiteTitulaireProvider).lire();
    });

// Les trois lectures d'argent et d'acces ci-dessous suivent la personne
// connectee (revue FI-VAGUE-CORR-R, R7-04) : sur un appareil partage, la
// personne suivante declenche une nouvelle lecture, jamais la valeur gardee
// de la precedente (meme precedent que `monAccesProvider`).

/// L'acces de chaque profil eleve du foyer.
final FutureProvider<List<AccesBeneficiaire>> accesFoyerProvider =
    FutureProvider<List<AccesBeneficiaire>>((Ref ref) async {
      // R9 : apres la deconnexion, aucun appel (`acces_du_foyer` en 401).
      if (surveillerPersonneConnectee(ref) == null) {
        return const <AccesBeneficiaire>[];
      }
      return ref.watch(portAccesFoyerProvider).acces();
    });

/// L'historique des paiements du foyer (indisponible tant que DB-CPT-03
/// manque).
final FutureProvider<List<PaiementFoyer>> paiementsFoyerProvider =
    FutureProvider<List<PaiementFoyer>>((Ref ref) {
      surveillerPersonneConnectee(ref);
      return ref.watch(portPaiementsFoyerProvider).historique();
    });

/// Les soldes des beneficiaires du foyer, pour le titulaire (EA-9 ;
/// indisponibles tant que FI-BR-03, qui remplace EA-BR-23, manque).
final FutureProvider<SoldesFoyer> soldesFoyerProvider =
    FutureProvider<SoldesFoyer>((Ref ref) {
      surveillerPersonneConnectee(ref);
      return ref.watch(portPaiementsFoyerProvider).soldes();
    });

/// Le canal d'aide de l'academie (indisponible tant que DB-CPT-07 manque).
final FutureProvider<CanalSupport?> canalSupportProvider =
    FutureProvider<CanalSupport?>(
      (Ref ref) => ref.watch(portSupportProvider).canal(),
    );

/// Vrai quand le titulaire a deja son propre profil eleve.
///
/// Tant que le serveur ne le sait pas (DB-FOY-01), la lecture echoue : la
/// ligne « Creer mon profil eleve » reste alors proposee, et c'est l'ecran du
/// lot B qui dit la limite. Elle ne disparait que sur un « oui » explicite.
final FutureProvider<bool> profilEleveTitulaireExisteProvider =
    FutureProvider<bool>(
      (Ref ref) => ref.watch(portProfilEleveTitulaireProvider).existe(),
    );

/// Une date en toutes lettres : « 30 octobre 2026 », « 1er novembre 2026 »
/// (R8-05), en heure locale.
///
/// DATE-ARABE-ISOLAT (garde-cap, 12/11/2026) : en arabe, le gabarit isole
/// chaque morceau (jour, mois, annee) ; une phrase qui isole a son tour la
/// date entiere (« Paiement du {date} », « expire le {date} ») donnait un isolat
/// exterieur sans lettre forte, donc de gauche a droite, et la date se lisait
/// a l'envers (annee, mois, jour). La marque de lettre arabe (U+061C, forte
/// de droite a gauche) en tete lui donne le sens de l'interface. Une seule
/// solution, a la source.
String dateLongue(DateTime date) {
  final DateTime locale = date.toLocal();
  final String texte = t.compte.tuteur.dateLongue(
    jour: jourDuMois(locale.day),
    mois: t.commun.dates.mois[locale.month - 1],
    annee: locale.year,
  );
  return LocaleSettings.currentLocale == AppLocale.ar
      ? '$marqueLettreArabe$texte'
      : texte;
}

/// La marque de lettre arabe (U+061C), invisible et forte de droite a
/// gauche : en tete d'une date arabe ([dateLongue]).
const String marqueLettreArabe = '\u061C';

/// Le nom complet du titulaire, ou `null` quand ni prenom ni nom ne sont
/// renseignes.
String? nomComplet(IdentiteTitulaire identite) {
  final String nom = '${identite.prenom.trim()} ${identite.nom.trim()}'.trim();
  return nom.isEmpty ? null : nom;
}

/// Ce que l'ecran dit de la methode de connexion, en une phrase.
String phraseConnexion(MethodeConnexion methode) => switch (methode) {
  MethodeConnexion.lienCourriel => t.compte.tuteur.identite.connexionLien,
  MethodeConnexion.google => t.compte.tuteur.identite.connexionGoogle,
  MethodeConnexion.inconnue => t.compte.tuteur.identite.connexionInconnue,
};

/// La methode de connexion en valeur courte, ou `null` quand elle est
/// inconnue (on ne l'invente pas).
String? valeurConnexion(MethodeConnexion methode) => switch (methode) {
  MethodeConnexion.lienCourriel => t.compte.tuteur.securite.methodeLien,
  MethodeConnexion.google => t.compte.tuteur.securite.methodeGoogle,
  MethodeConnexion.inconnue => null,
};

/// Le statut du compte tel qu'une pastille peut le dire, ou `null` quand il
/// n'y a rien d'affirme (statut illisible, en attente ou suspendu : ces
/// comptes-la n'atteignent pas le Compte).
({String libelle, bool valide})? statutAffiche(AccountStatus? statut) =>
    switch (statut) {
      AccountStatus.active => (
        libelle: t.compte.tuteur.identite.statutValide,
        valide: true,
      ),
      AccountStatus.provisionalActive => (
        libelle: t.compte.tuteur.identite.statutProvisoire,
        valide: false,
      ),
      _ => null,
    };
