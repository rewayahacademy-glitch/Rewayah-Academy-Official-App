import '../../core/tc_bibliotheque/library_resource.dart';
import '../../core/tc_bibliotheque/vue_catalogue.dart';
import '../../core/tc_telechargement/port_etat_offline.dart';

/// Les libelles de la Bibliotheque, en attendant slang.
///
/// **Ce fichier est une facade temporaire, et il est fait pour disparaitre.**
/// `assets/i18n/fr.i18n.json` et `lib/core/i18n/strings*.g.dart` sont une
/// source unique de 617 cles et une sortie generee et versionnee de 244 Ko :
/// neuf agents qui y ecriraient en parallele produiraient neuf conflits
/// non fusionnables a la main (decision D-03).
///
/// Chaque constante porte donc la cle slang qu'elle prendra, en commentaire
/// `TC-I18N`. Les memes cles, avec les memes textes, sont deposees dans
/// `docs/teaching-core/i18n/tc_i18n_B.json`. Agent Z fusionne le JSON,
/// regenere, remplace les constantes et supprime ce fichier.
///
/// Aucun libelle n'y emploie « mode enfant » (decision D-07) ni « Ustaz »
/// (decision D-02) : le sous-arbre `tc.bibliotheque.*` n'en a pas besoin, mais
/// la regle vaut partout.
abstract final class LibellesTcB {
  // --- Ecran -------------------------------------------------------------

  // TC-I18N: cle=tc.bibliotheque.titre
  /// Le titre de l'ecran.
  static const String titre = 'Bibliothèque';

  // TC-I18N: cle=tc.bibliotheque.rechercheIndication
  /// L'indication du champ de recherche.
  static const String rechercheIndication = 'Titre, niveau, sourate ou page';

  // TC-I18N: cle=tc.bibliotheque.rechercheLibelle
  /// Le libelle parle du champ de recherche.
  static const String rechercheLibelle = 'Rechercher un support';

  // TC-I18N: cle=tc.bibliotheque.effacerRecherche
  /// L'action qui relache la recherche et les filtres.
  static const String effacerRecherche = 'Tout afficher';

  // TC-I18N: cle=tc.bibliotheque.filtre.type
  /// L'axe de filtre « type de support ».
  static const String filtreType = 'Type';

  // TC-I18N: cle=tc.bibliotheque.filtre.disponibilite
  /// L'axe de filtre « disponibilite hors ligne ».
  static const String filtreDisponibilite = 'Disponibilité';

  // --- Sections ----------------------------------------------------------

  // TC-I18N: cle=tc.bibliotheque.sections.continuer
  /// « Continuer ».
  static const String sectionContinuer = 'Continuer';

  // TC-I18N: cle=tc.bibliotheque.sections.pourCeGroupe
  /// « Pour ce groupe ».
  static const String sectionPourCeGroupe = 'Pour ce groupe';

  // TC-I18N: cle=tc.bibliotheque.sections.recents
  /// « Récents ».
  static const String sectionRecents = 'Récents';

  // TC-I18N: cle=tc.bibliotheque.sections.tousLesSupports
  /// « Tous les supports ».
  static const String sectionTousLesSupports = 'Tous les supports';

  // TC-I18N: cle=tc.bibliotheque.sections.resultats
  /// Les resultats d'une recherche.
  static const String sectionResultats = 'Résultats';

  /// Le titre d'une section.
  static String section(IdSectionCatalogue id) => switch (id) {
    IdSectionCatalogue.continuer => sectionContinuer,
    IdSectionCatalogue.pourCeGroupe => sectionPourCeGroupe,
    IdSectionCatalogue.recents => sectionRecents,
    IdSectionCatalogue.tousLesSupports => sectionTousLesSupports,
    IdSectionCatalogue.resultats => sectionResultats,
  };

  // --- Etats vides -------------------------------------------------------

  // TC-I18N: cle=tc.bibliotheque.vide.message
  /// Le constat d'un catalogue vide.
  static const String videMessage = 'Aucun support publié pour le moment';

  // TC-I18N: cle=tc.bibliotheque.vide.invitation
  /// Ce que la personne peut attendre.
  static const String videInvitation =
      'Vos enseignants déposeront ici les supports de vos cours.';

  // TC-I18N: cle=tc.bibliotheque.aucunResultat.message
  /// Le constat d'une recherche sans resultat.
  static const String aucunResultatMessage = 'Aucun support ne correspond';

  // TC-I18N: cle=tc.bibliotheque.aucunResultat.invitation
  /// Ce que la personne peut faire ensuite.
  static const String aucunResultatInvitation =
      'Essayez un autre mot, ou relâchez les filtres.';

  // TC-I18N: cle=tc.bibliotheque.indisponible.message
  /// Le constat d'une lecture qui a echoue.
  static const String indisponibleMessage =
      'La bibliothèque est momentanément indisponible';

  // TC-I18N: cle=tc.bibliotheque.indisponible.action
  /// L'action de reprise.
  static const String indisponibleAction = 'Réessayer';

  // TC-I18N: cle=tc.bibliotheque.introuvable.message
  /// Le constat d'une ressource que l'appelant ne voit pas.
  static const String introuvableMessage = 'Ce support ne vous est pas ouvert';

  // TC-I18N: cle=tc.bibliotheque.introuvable.invitation
  /// La raison, sans accuser la personne.
  static const String introuvableInvitation =
      'Il a peut-être été retiré, ou il est réservé à un autre groupe. '
      'Votre enseignant peut vous le rouvrir.';

  // --- Etats hors ligne --------------------------------------------------

  // TC-I18N: cle=tc.bibliotheque.offline.aTelecharger
  /// La ressource n'est pas encore sur l'appareil.
  static const String offlineATelecharger = 'À télécharger';

  // TC-I18N: cle=tc.bibliotheque.offline.enCours
  /// Le telechargement est en route.
  static const String offlineEnCours = 'Téléchargement';

  // TC-I18N: cle=tc.bibliotheque.offline.enCache
  /// La ressource est la, sans avoir ete demandee.
  static const String offlineEnCache = 'En cache';

  // TC-I18N: cle=tc.bibliotheque.offline.telecharge
  /// La ressource a ete demandee et conservee.
  static const String offlineTelecharge = 'Téléchargé';

  // TC-I18N: cle=tc.bibliotheque.offline.indisponible
  /// La ressource n'existe pas hors ligne.
  static const String offlineIndisponible = 'Hors ligne indisponible';

  /// Le libelle d'un etat hors ligne.
  static String offline(EtatOffline etat) => switch (etat) {
    EtatOffline.aTelecharger => offlineATelecharger,
    EtatOffline.enCours => offlineEnCours,
    EtatOffline.enCache => offlineEnCache,
    EtatOffline.telecharge => offlineTelecharge,
    EtatOffline.indisponible => offlineIndisponible,
  };

  // --- Types de ressource ------------------------------------------------

  // TC-I18N: cle=tc.bibliotheque.type.quran
  /// Le Coran.
  static const String typeQuran = 'Coran';

  // TC-I18N: cle=tc.bibliotheque.type.texteStructure
  /// Un texte structure.
  static const String typeTexteStructure = 'Texte';

  // TC-I18N: cle=tc.bibliotheque.type.pdf
  /// Un PDF.
  static const String typePdf = 'PDF';

  // TC-I18N: cle=tc.bibliotheque.type.image
  /// Une image pedagogique.
  static const String typeImage = 'Image';

  // TC-I18N: cle=tc.bibliotheque.type.lecon
  /// Une lecon Rewayah.
  static const String typeLecon = 'Leçon';

  /// Le libelle d'un type de ressource.
  static String type(TypeRessource type) => switch (type) {
    TypeRessource.quran => typeQuran,
    TypeRessource.texteStructure => typeTexteStructure,
    TypeRessource.pdf => typePdf,
    TypeRessource.image => typeImage,
    TypeRessource.lecon => typeLecon,
  };

  // --- Detail et actions -------------------------------------------------

  // TC-I18N: cle=tc.bibliotheque.detail.titre
  /// Le titre de la fiche d'une ressource.
  static const String detailTitre = 'Support';

  // TC-I18N: cle=tc.bibliotheque.detail.capacites
  /// L'en-tete de la liste des capacites.
  static const String detailCapacites = 'Ce que ce support permet';

  // TC-I18N: cle=tc.bibliotheque.detail.niveaux
  /// L'en-tete des niveaux.
  static const String detailNiveaux = 'Niveaux';

  // TC-I18N: cle=tc.bibliotheque.detail.sansVersion
  /// Rien n'est encore publie pour cette ressource.
  static const String detailSansVersion =
      'Aucune version publiée : rien à ouvrir pour le moment.';

  // TC-I18N: cle=tc.bibliotheque.detail.apercuIndisponible
  /// Le produit ne sait pas encore afficher ce format.
  static const String detailApercuIndisponible =
      'L’aperçu de ce format n’est pas encore disponible dans '
      'l’application. Vous pouvez en enregistrer une copie.';

  // TC-I18N: cle=tc.bibliotheque.detail.renduCoran
  /// Le Coran a son propre moteur de rendu.
  static const String detailRenduCoran =
      'Le Coran s’ouvre dans le lecteur dédié.';

  // TC-I18N: cle=tc.bibliotheque.action.telecharger
  /// Rendre la ressource disponible hors ligne.
  static const String actionTelecharger = 'Rendre disponible hors ligne';

  // TC-I18N: cle=tc.bibliotheque.action.liberer
  /// Liberer la place occupee.
  static const String actionLiberer = 'Libérer la place';

  // TC-I18N: cle=tc.bibliotheque.action.enregistrerCopie
  /// Enregistrer une copie par le selecteur du systeme.
  ///
  /// La spec section 6.5 propose « Enregistrer une copie » **ou**
  /// « Telecharger en PDF ». Un seul libelle est retenu : le second promet un
  /// format, or le format depend de l'artefact publie. Le premier dit ce qui
  /// se passe sans rien promettre sur le contenu.
  static const String actionEnregistrerCopie = 'Enregistrer une copie';

  // --- Messages ----------------------------------------------------------

  // TC-I18N: cle=tc.bibliotheque.message.copieEnregistree
  /// La copie est enregistree.
  static const String messageCopieEnregistree = 'Copie enregistrée';

  // TC-I18N: cle=tc.bibliotheque.message.copieImpossible
  /// La copie n'a pas pu etre produite.
  static const String messageCopieImpossible =
      'Cette copie n’est pas disponible pour le moment';

  // TC-I18N: cle=tc.bibliotheque.message.telechargementImpossible
  /// Le hors ligne n'a pas pu etre prepare.
  static const String messageTelechargementImpossible =
      'Ce support n’est pas encore disponible hors ligne';

  // TC-I18N: cle=tc.bibliotheque.message.horsLigneNonTelecharge
  /// La raison pour laquelle une carte ne s'ouvre pas sans reseau.
  static const String messageHorsLigneNonTelecharge =
      'Disponible une fois téléchargé ou de retour en ligne';

  // TC-I18N: cle=tc.bibliotheque.message.aucunTelechargement
  /// Aucun artefact n'existe pour cette version.
  static const String messageAucunTelechargement =
      'Aucun fichier à télécharger pour cette version.';

  // --- Picker de classe --------------------------------------------------

  // TC-I18N: cle=tc.bibliotheque.classe.titre
  /// Le titre du panneau ouvert en classe.
  static const String classeTitre = 'Choisir un support';

  // TC-I18N: cle=tc.bibliotheque.classe.sousTitre
  /// Ce que le choix change, et ce qu'il ne change pas.
  static const String classeSousTitre =
      'Le support choisi remplace celui affiché. Le cours continue.';
}
