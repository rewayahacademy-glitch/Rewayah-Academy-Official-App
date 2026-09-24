///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TraductionsFr = Traductions; // ignore: unused_element
class Traductions with BaseTranslations<AppLocale, Traductions> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Traductions.of(context);
	static Traductions of(BuildContext context) => InheritedLocaleData.of<AppLocale, Traductions>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Traductions({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Traductions>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.fr,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <fr>.
	final TranslationMetadata<AppLocale, Traductions> _meta;
	@override TranslationMetadata<AppLocale, Traductions> get $meta => _meta;

	/// Access flat map
	dynamic operator[](String key) => _meta.getTranslation(key);

	late final Traductions _root = this; // ignore: unused_field

	Traductions $copyWith({TranslationMetadata<AppLocale, Traductions>? meta}) => Traductions(meta: meta ?? this.$meta);

	// Translations
	late final Traductions$commun$fr commun = Traductions$commun$fr.internal(_root);
	late final Traductions$reseau$fr reseau = Traductions$reseau$fr.internal(_root);
	late final Traductions$etat$fr etat = Traductions$etat$fr.internal(_root);
	late final Traductions$destructif$fr destructif = Traductions$destructif$fr.internal(_root);
	late final Traductions$salle$fr salle = Traductions$salle$fr.internal(_root);
	late final Traductions$presence$fr presence = Traductions$presence$fr.internal(_root);
	late final Traductions$bienvenue$fr bienvenue = Traductions$bienvenue$fr.internal(_root);
	late final Traductions$attente$fr attente = Traductions$attente$fr.internal(_root);
	late final Traductions$connexion$fr connexion = Traductions$connexion$fr.internal(_root);
	late final Traductions$inscription$fr inscription = Traductions$inscription$fr.internal(_root);
	late final Traductions$contrat$fr contrat = Traductions$contrat$fr.internal(_root);
	late final Traductions$accuse$fr accuse = Traductions$accuse$fr.internal(_root);
	late final Traductions$consentement$fr consentement = Traductions$consentement$fr.internal(_root);
	late final Traductions$kyc$fr kyc = Traductions$kyc$fr.internal(_root);
	late final Traductions$appareils$fr appareils = Traductions$appareils$fr.internal(_root);
	late final Traductions$enfant$fr enfant = Traductions$enfant$fr.internal(_root);
	late final Traductions$foyer$fr foyer = Traductions$foyer$fr.internal(_root);
	late final Traductions$ficheEleve$fr ficheEleve = Traductions$ficheEleve$fr.internal(_root);
	late final Traductions$disponibilites$fr disponibilites = Traductions$disponibilites$fr.internal(_root);
	late final Traductions$creneaux$fr creneaux = Traductions$creneaux$fr.internal(_root);
	late final Traductions$priere$fr priere = Traductions$priere$fr.internal(_root);
	late final Traductions$eleveConnexion$fr eleveConnexion = Traductions$eleveConnexion$fr.internal(_root);
	late final Traductions$dossiers$fr dossiers = Traductions$dossiers$fr.internal(_root);
	late final Traductions$admin$fr admin = Traductions$admin$fr.internal(_root);
	late final Traductions$agent$fr agent = Traductions$agent$fr.internal(_root);
	late final Traductions$vide$fr vide = Traductions$vide$fr.internal(_root);
	late final Traductions$pin$fr pin = Traductions$pin$fr.internal(_root);
	late final Traductions$choix$fr choix = Traductions$choix$fr.internal(_root);
	late final Traductions$parcours$fr parcours = Traductions$parcours$fr.internal(_root);
	late final Traductions$avatar$fr avatar = Traductions$avatar$fr.internal(_root);
	late final Traductions$nav$fr nav = Traductions$nav$fr.internal(_root);
	late final Traductions$compte$fr compte = Traductions$compte$fr.internal(_root);
	late final Traductions$historique$fr historique = Traductions$historique$fr.internal(_root);
	late final Traductions$notifications$fr notifications = Traductions$notifications$fr.internal(_root);
	late final Traductions$eleve$fr eleve = Traductions$eleve$fr.internal(_root);
	late final Traductions$tuteur$fr tuteur = Traductions$tuteur$fr.internal(_root);
	late final Traductions$classe$fr classe = Traductions$classe$fr.internal(_root);
	late final Traductions$enseignant$fr enseignant = Traductions$enseignant$fr.internal(_root);
	late final Traductions$controleur$fr controleur = Traductions$controleur$fr.internal(_root);
	late final Traductions$aConstruire$fr aConstruire = Traductions$aConstruire$fr.internal(_root);
	late final Traductions$galerie$fr galerie = Traductions$galerie$fr.internal(_root);
	late final Traductions$tc$fr tc = Traductions$tc$fr.internal(_root);
}

// Path: commun
class Traductions$commun$fr {
	Traductions$commun$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Rewayah Academy'
	String get marque => 'Rewayah Academy';

	/// fr: 'Continuer'
	String get continuer => 'Continuer';

	/// fr: 'Retour'
	String get retour => 'Retour';

	/// fr: 'Valider'
	String get valider => 'Valider';

	/// fr: 'Annuler'
	String get annuler => 'Annuler';

	/// fr: 'Fermer'
	String get fermer => 'Fermer';

	/// fr: 'Réessayer'
	String get reessayer => 'Réessayer';

	/// fr: 'Chargement'
	String get chargement => 'Chargement';

	late final Traductions$commun$etats$fr etats = Traductions$commun$etats$fr.internal(_root);
	late final Traductions$commun$entete$fr entete = Traductions$commun$entete$fr.internal(_root);
	late final Traductions$commun$selecteurProfils$fr selecteurProfils = Traductions$commun$selecteurProfils$fr.internal(_root);
	late final Traductions$commun$theme$fr theme = Traductions$commun$theme$fr.internal(_root);
	late final Traductions$commun$demarrage$fr demarrage = Traductions$commun$demarrage$fr.internal(_root);
	late final Traductions$commun$dates$fr dates = Traductions$commun$dates$fr.internal(_root);
}

// Path: reseau
class Traductions$reseau$fr {
	Traductions$reseau$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Pas de réseau. Tout reste consultable, l'envoi attendra.'
	String get horsLigne => 'Pas de réseau. Tout reste consultable, l\'envoi attendra.';

	/// fr: 'Sera envoyé dès le retour du réseau'
	String get enAttenteEnvoi => 'Sera envoyé dès le retour du réseau';

	/// fr: 'Réseau rétabli'
	String get retabli => 'Réseau rétabli';

	/// fr: 'Synchronisation impossible'
	String get syncImpossible => 'Synchronisation impossible';
}

// Path: etat
class Traductions$etat$fr {
	Traductions$etat$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'En direct'
	String get enDirect => 'En direct';

	/// fr: 'C'est bientôt'
	String get imminent => 'C\'est bientôt';

	/// fr: 'Annulé'
	String get annule => 'Annulé';

	/// fr: 'En attente'
	String get enAttente => 'En attente';

	/// fr: 'En retard'
	String get enRetard => 'En retard';

	/// fr: 'Terminé'
	String get termine => 'Terminé';
}

// Path: destructif
class Traductions$destructif$fr {
	Traductions$destructif$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Cette action ne peut pas être annulée.'
	String get irreversible => 'Cette action ne peut pas être annulée.';
}

// Path: salle
class Traductions$salle$fr {
	Traductions$salle$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Cours enregistré, visite de contrôle possible.'
	String get bandeauPermanent => 'Cours enregistré, visite de contrôle possible.';

	/// fr: 'Micro'
	String get micro => 'Micro';

	/// fr: 'Micro coupé'
	String get microCoupe => 'Micro coupé';

	/// fr: 'Caméra'
	String get camera => 'Caméra';

	/// fr: 'Caméra éteinte'
	String get cameraCoupee => 'Caméra éteinte';

	/// fr: 'Quitter'
	String get quitter => 'Quitter';

	/// fr: 'Ouvrir le Coran'
	String get ouvrirCoran => 'Ouvrir le Coran';

	/// fr: 'Quitter le cours ?'
	String get confirmerSortie => 'Quitter le cours ?';

	/// fr: 'Cette salle n'est plus accessible. Revenez à votre accueil pour rejoindre le prochain cours.'
	String get expiree => 'Cette salle n\'est plus accessible. Revenez à votre accueil pour rejoindre le prochain cours.';

	/// fr: 'Ouverture de la salle'
	String get ouverture => 'Ouverture de la salle';

	/// fr: 'Vérification de votre micro'
	String get verificationMateriel => 'Vérification de votre micro';

	/// fr: 'Connexion au cours'
	String get connexion => 'Connexion au cours';

	/// fr: 'Connexion instable, reconnexion en cours'
	String get reconnexion => 'Connexion instable, reconnexion en cours';

	/// fr: 'Reconnexion'
	String get reconnexionCourt => 'Reconnexion';

	/// fr: 'La connexion au cours est perdue'
	String get perdue => 'La connexion au cours est perdue';

	/// fr: 'Votre professeur n'est pas encore arrivé'
	String get seulEnseignant => 'Votre professeur n\'est pas encore arrivé';

	/// fr: 'Restez sur cet écran. Vous le verrez apparaître.'
	String get seulEnseignantDetail => 'Restez sur cet écran. Vous le verrez apparaître.';

	/// fr: 'Votre élève n'est pas encore arrivé'
	String get seulEleve => 'Votre élève n\'est pas encore arrivé';

	/// fr: 'Restez sur cet écran. Vous le verrez apparaître.'
	String get seulEleveDetail => 'Restez sur cet écran. Vous le verrez apparaître.';

	/// fr: 'Personne n'est encore entré dans cette salle'
	String get seulObservation => 'Personne n\'est encore entré dans cette salle';

	/// fr: 'Le cours n'a pas commencé, ou il est déjà terminé.'
	String get seulObservationDetail => 'Le cours n\'a pas commencé, ou il est déjà terminé.';

	/// fr: 'Ce cours ne vous est pas ouvert en ce moment'
	String get refusAcces => 'Ce cours ne vous est pas ouvert en ce moment';

	/// fr: 'La salle s'ouvre dix minutes avant l'heure du cours, et se ferme un quart d'heure après sa fin.'
	String get refusAccesDetail => 'La salle s\'ouvre dix minutes avant l\'heure du cours, et se ferme un quart d\'heure après sa fin.';

	/// fr: 'La salle n'est pas encore disponible'
	String get refusConfiguration => 'La salle n\'est pas encore disponible';

	/// fr: 'Ce n'est pas votre appareil : le service de visioconférence n'est pas branché. L'équipe le sait.'
	String get refusConfigurationDetail => 'Ce n\'est pas votre appareil : le service de visioconférence n\'est pas branché. L\'équipe le sait.';

	/// fr: 'La salle n'a pas répondu'
	String get refusReseau => 'La salle n\'a pas répondu';

	/// fr: 'Vérifiez votre connexion, puis réessayez.'
	String get refusReseauDetail => 'Vérifiez votre connexion, puis réessayez.';

	/// fr: 'Aucun micro utilisable sur cet appareil'
	String get refusMateriel => 'Aucun micro utilisable sur cet appareil';

	/// fr: 'Un cours de Coran se fait à la voix. Autorisez l'accès au micro, ou branchez un casque, puis réessayez.'
	String get refusMaterielDetail => 'Un cours de Coran se fait à la voix. Autorisez l\'accès au micro, ou branchez un casque, puis réessayez.';

	/// fr: 'Revenir à mon accueil'
	String get retourAccueil => 'Revenir à mon accueil';

	/// fr: 'Ouvrir le micro'
	String get ouvrirMicro => 'Ouvrir le micro';

	/// fr: 'Fermer le micro'
	String get fermerMicro => 'Fermer le micro';

	/// fr: 'Allumer la caméra'
	String get ouvrirCamera => 'Allumer la caméra';

	/// fr: 'Éteindre la caméra'
	String get fermerCamera => 'Éteindre la caméra';

	/// fr: 'Quitter le cours'
	String get quitterLeCours => 'Quitter le cours';

	/// fr: 'Le cours continue sans vous, et votre départ est inscrit dans la séance.'
	String get consequenceSortie => 'Le cours continue sans vous, et votre départ est inscrit dans la séance.';

	/// fr: 'Vous'
	String get vousMeme => 'Vous';

	/// fr: 'Sans image'
	String get sansImage => 'Sans image';

	/// fr: 'Connexion faible'
	String get lienMediocre => 'Connexion faible';

	/// fr: 'Connexion perdue'
	String get lienPerdu => 'Connexion perdue';

	/// fr: 'Image coupée le temps que la connexion revienne. La voix continue.'
	String get videoSuspendue => 'Image coupée le temps que la connexion revienne. La voix continue.';

	/// fr: 'Enseignant'
	String get roleEnseignant => 'Enseignant';

	/// fr: 'Élève'
	String get roleEleve => 'Élève';

	/// fr: 'Tuteur, en observation'
	String get roleTuteur => 'Tuteur, en observation';

	/// fr: 'Administration Rewayah'
	String get roleAdministration => 'Administration Rewayah';

	/// fr: 'Vous assistez au cours. Vous n'êtes pas entendu.'
	String get observationMuette => 'Vous assistez au cours. Vous n\'êtes pas entendu.';

	/// fr: 'Visite de contrôle. Vous n'êtes ni vu ni entendu, et votre passage est inscrit au journal.'
	String get bandeauControle => 'Visite de contrôle. Vous n\'êtes ni vu ni entendu, et votre passage est inscrit au journal.';
}

// Path: presence
class Traductions$presence$fr {
	Traductions$presence$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Présence'
	String get titre => 'Présence';

	/// fr: 'Voir la présence'
	String get voir => 'Voir la présence';

	/// fr: 'Votre présence'
	String get mienne => 'Votre présence';

	/// fr: 'consolidé'
	String get consolide => 'consolidé';

	/// fr: 'Cours à venir'
	String get planifiee => 'Cours à venir';

	/// fr: 'Pas encore là'
	String get enAttente => 'Pas encore là';

	/// fr: 'Connexion en cours'
	String get enConnexion => 'Connexion en cours';

	/// fr: 'En salle'
	String get presente => 'En salle';

	/// fr: 'En retard'
	String get enRetard => 'En retard';

	/// fr: 'Lien coupé'
	String get deconnectee => 'Lien coupé';

	/// fr: 'Reconnexion en cours'
	String get enReconnexion => 'Reconnexion en cours';

	/// fr: 'De retour'
	String get reconnectee => 'De retour';

	/// fr: 'A quitté le cours'
	String get sortie => 'A quitté le cours';

	/// fr: 'Absence'
	String get absente => 'Absence';

	/// fr: 'Absence excusée'
	String get excusee => 'Absence excusée';

	/// fr: 'À confirmer'
	String get confirmationEnAttente => 'À confirmer';

	/// fr: 'Correction manuelle'
	String get corrigeeManuel => 'Correction manuelle';

	/// fr: 'Définitif'
	String get finalisee => 'Définitif';

	/// fr: 'État inconnu'
	String get inconnu => 'État inconnu';

	/// fr: 'en salle à l'instant'
	String get entreeInstant => 'en salle à l\'instant';

	/// fr: 'en salle depuis {minutes} min'
	String entreeMinutes({required Object minutes}) => 'en salle depuis ${minutes} min';

	/// fr: '{minutes} min après l'heure'
	String retardMinutes({required Object minutes}) => '${minutes} min après l\'heure';

	/// fr: 'sans nouvelles depuis quelques secondes'
	String get silenceInstant => 'sans nouvelles depuis quelques secondes';

	/// fr: 'sans nouvelles depuis {minutes} min'
	String silenceMinutes({required Object minutes}) => 'sans nouvelles depuis ${minutes} min';

	/// fr: 'le cours vient de commencer'
	String get attenteInstant => 'le cours vient de commencer';

	/// fr: 'le cours a commencé il y a {minutes} min'
	String attenteMinutes({required Object minutes}) => 'le cours a commencé il y a ${minutes} min';
}

// Path: bienvenue
class Traductions$bienvenue$fr {
	Traductions$bienvenue$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Bienvenue'
	String get titre => 'Bienvenue';
}

// Path: attente
class Traductions$attente$fr {
	Traductions$attente$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Votre dossier est en cours de vérification'
	String get titre => 'Votre dossier est en cours de vérification';

	/// fr: 'Il manque encore des pièces à votre dossier.'
	String get dossierIncomplet => 'Il manque encore des pièces à votre dossier.';

	/// fr: 'Nous vérifions votre dossier. Vous recevrez une notification dès qu'il est validé.'
	String get enVerification => 'Nous vérifions votre dossier. Vous recevrez une notification dès qu\'il est validé.';

	/// fr: 'Votre dossier n'a pas été validé.'
	String get refuse => 'Votre dossier n\'a pas été validé.';

	/// fr: 'Votre compte est suspendu.'
	String get suspendu => 'Votre compte est suspendu.';

	/// fr: 'Contacter l'académie'
	String get contacterAcademie => 'Contacter l\'académie';

	/// fr: 'Déposé le {date}'
	String deposeLe({required Object date}) => 'Déposé le ${date}';

	/// fr: 'La vérification prend en général moins de 48 heures.'
	String get delai => 'La vérification prend en général moins de 48 heures.';

	/// fr: 'À fournir'
	String get aFournir => 'À fournir';

	/// fr: 'Une pièce d'identité'
	String get pieceIdentite => 'Une pièce d\'identité';

	/// fr: 'La signature du contrat'
	String get signatureContrat => 'La signature du contrat';

	/// fr: 'Ce que vous devez savoir'
	String get carteAccuse => 'Ce que vous devez savoir';

	/// fr: 'Déposer ma pièce'
	String get deposerLaPiece => 'Déposer ma pièce';

	/// fr: 'Lire et signer'
	String get signerLeContrat => 'Lire et signer';

	/// fr: 'Lire'
	String get lireLaCarte => 'Lire';

	/// fr: 'Tout est déposé.'
	String get toutEstDepose => 'Tout est déposé.';

	/// fr: 'Reprendre mon dossier'
	String get corriger => 'Reprendre mon dossier';

	/// fr: 'Vous pouvez joindre l'académie pour connaître la marche à suivre.'
	String get suspenduDetail => 'Vous pouvez joindre l\'académie pour connaître la marche à suivre.';

	/// fr: 'Se déconnecter'
	String get seDeconnecter => 'Se déconnecter';
}

// Path: connexion
class Traductions$connexion$fr {
	Traductions$connexion$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Se connecter'
	String get titre => 'Se connecter';

	/// fr: 'Nous vous envoyons un lien par courriel. Aucun mot de passe à retenir, donc aucun à perdre.'
	String get intro => 'Nous vous envoyons un lien par courriel. Aucun mot de passe à retenir, donc aucun à perdre.';

	/// fr: 'Votre adresse électronique'
	String get courriel => 'Votre adresse électronique';

	/// fr: 'vous@exemple.com'
	String get courrielIndice => 'vous@exemple.com';

	/// fr: 'Mot de passe de démonstration'
	String get motDePasseDemo => 'Mot de passe de démonstration';

	/// fr: 'Recevoir le lien'
	String get envoyerLien => 'Recevoir le lien';

	/// fr: 'Continuer avec Google'
	String get avecGoogle => 'Continuer avec Google';

	/// fr: 'ou'
	String get ou => 'ou';

	/// fr: 'Lien envoyé'
	String get lienEnvoye => 'Lien envoyé';

	/// fr: 'Ouvrez le message envoyé à {courriel}, puis suivez le lien. Vous pouvez laisser cette page ouverte.'
	String lienEnvoyeDetail({required Object courriel}) => 'Ouvrez le message envoyé à ${courriel}, puis suivez le lien. Vous pouvez laisser cette page ouverte.';

	/// fr: 'Utiliser une autre adresse'
	String get changerAdresse => 'Utiliser une autre adresse';

	/// fr: 'Cette adresse ne semble pas valide.'
	String get erreurCourriel => 'Cette adresse ne semble pas valide.';

	/// fr: 'L'envoi n'a pas abouti. Réessayez dans un instant.'
	String get erreurEnvoi => 'L\'envoi n\'a pas abouti. Réessayez dans un instant.';

	/// fr: 'Vous êtes tuteur et vous préparez l'appareil d'un élève ?'
	String get appareilEleveAide => 'Vous êtes tuteur et vous préparez l\'appareil d\'un élève ?';

	/// fr: 'Connecter l'appareil d'un élève'
	String get appareilEleve => 'Connecter l\'appareil d\'un élève';

	late final Traductions$connexion$feuilleAppareil$fr feuilleAppareil = Traductions$connexion$feuilleAppareil$fr.internal(_root);
}

// Path: inscription
class Traductions$inscription$fr {
	Traductions$inscription$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Créer votre compte'
	String get titre => 'Créer votre compte';

	/// fr: 'Étape {n} sur {total}'
	String etapeSur({required Object n, required Object total}) => 'Étape ${n} sur ${total}';

	/// fr: 'Environ {minutes} min'
	String tempsRestant({required Object minutes}) => 'Environ ${minutes} min';

	/// fr: 'Vous inscrivez-vous comme parent ou comme enseignant ?'
	String get roleQuestion => 'Vous inscrivez-vous comme parent ou comme enseignant ?';

	/// fr: 'Parent ou tuteur'
	String get roleTuteur => 'Parent ou tuteur';

	/// fr: 'Élève adulte, pour moi-même'
	String get roleEleveAdulte => 'Élève adulte, pour moi-même';

	/// fr: 'Enseignant'
	String get roleEnseignant => 'Enseignant';

	/// fr: 'Écrivez à l'académie et nous créerons votre accès. Cette page ne peut pas le faire pour vous.'
	String get autreAide => 'Écrivez à l\'académie et nous créerons votre accès. Cette page ne peut pas le faire pour vous.';

	/// fr: 'Comment vous appelez-vous ?'
	String get identiteQuestion => 'Comment vous appelez-vous ?';

	/// fr: 'Ce nom doit être celui de votre pièce d'identité.'
	String get identiteRaison => 'Ce nom doit être celui de votre pièce d\'identité.';

	/// fr: 'Prénom'
	String get prenom => 'Prénom';

	/// fr: 'Nom'
	String get nom => 'Nom';

	/// fr: 'Vous êtes'
	String get genreQuestion => 'Vous êtes';

	/// fr: 'Un homme'
	String get genreHomme => 'Un homme';

	/// fr: 'Une femme'
	String get genreFemme => 'Une femme';

	/// fr: 'Cette réponse ne sert qu'à confier votre pièce d'identité à un membre du personnel du même genre.'
	String get genreRaison => 'Cette réponse ne sert qu\'à confier votre pièce d\'identité à un membre du personnel du même genre.';

	/// fr: 'Avant de continuer'
	String get recapitulatif => 'Avant de continuer';

	/// fr: 'Créer mon compte'
	String get creer => 'Créer mon compte';

	/// fr: 'La création du compte n'a pas abouti. Réessayez dans un instant.'
	String get erreur => 'La création du compte n\'a pas abouti. Réessayez dans un instant.';

	/// fr: 'Cette réponse est nécessaire pour continuer.'
	String get champRequis => 'Cette réponse est nécessaire pour continuer.';
}

// Path: contrat
class Traductions$contrat$fr {
	Traductions$contrat$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Ce que vous signez'
	String get titre => 'Ce que vous signez';

	/// fr: 'Deux points comptent plus que les autres. Ils sont écrits ici en clair plutôt qu'au milieu d'un texte long.'
	String get intro => 'Deux points comptent plus que les autres. Ils sont écrits ici en clair plutôt qu\'au milieu d\'un texte long.';

	/// fr: 'Chaque cours est enregistré en audio, conservé trente jours, puis effacé. Chaque écoute est inscrite au journal, avec le nom de qui écoute.'
	String get pointEnregistrement => 'Chaque cours est enregistré en audio, conservé trente jours, puis effacé. Chaque écoute est inscrite au journal, avec le nom de qui écoute.';

	/// fr: 'Un contrôleur qualité peut assister à un cours sans être vu. La salle le rappelle en permanence, que la visite ait lieu ou non.'
	String get pointControle => 'Un contrôleur qualité peut assister à un cours sans être vu. La salle le rappelle en permanence, que la visite ait lieu ou non.';

	/// fr: 'Vous ne voyez jamais les coordonnées d'une famille : ni nom complet, ni courriel, ni téléphone.'
	String get pointCoordonnees => 'Vous ne voyez jamais les coordonnées d\'une famille : ni nom complet, ni courriel, ni téléphone.';

	/// fr: 'Lire le texte complet'
	String get lireTexte => 'Lire le texte complet';

	/// fr: 'J'ai lu et j'accepte'
	String get accepter => 'J\'ai lu et j\'accepte';

	/// fr: 'Accepté le {date}'
	String accepteLe({required Object date}) => 'Accepté le ${date}';

	/// fr: 'La signature n'a pas abouti. Réessayez dans un instant.'
	String get erreur => 'La signature n\'a pas abouti. Réessayez dans un instant.';
}

// Path: accuse
class Traductions$accuse$fr {
	Traductions$accuse$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'À savoir avant de commencer'
	String get titre => 'À savoir avant de commencer';

	/// fr: 'J'ai compris'
	String get compris => 'J\'ai compris';
}

// Path: consentement
class Traductions$consentement$fr {
	Traductions$consentement$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Consentements'
	String get titre => 'Consentements';
}

// Path: kyc
class Traductions$kyc$fr {
	Traductions$kyc$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Votre pièce d'identité'
	String get titre => 'Votre pièce d\'identité';

	/// fr: 'Une photo lisible suffit. Elle est conservée le temps de la vérification, puis effacée.'
	String get intro => 'Une photo lisible suffit. Elle est conservée le temps de la vérification, puis effacée.';

	/// fr: 'Quelle pièce déposez-vous ?'
	String get typeQuestion => 'Quelle pièce déposez-vous ?';

	/// fr: 'Carte d'identité'
	String get carteIdentite => 'Carte d\'identité';

	/// fr: 'Passeport'
	String get passeport => 'Passeport';

	/// fr: 'Titre de séjour'
	String get titreSejour => 'Titre de séjour';

	/// fr: 'Choisir la photo'
	String get choisirFichier => 'Choisir la photo';

	/// fr: 'Photo prête à être envoyée'
	String get fichierChoisi => 'Photo prête à être envoyée';

	/// fr: 'Envoyer ma pièce'
	String get envoyer => 'Envoyer ma pièce';

	/// fr: 'Envoi en cours'
	String get envoiEnCours => 'Envoi en cours';

	/// fr: 'Pièce reçue'
	String get deposee => 'Pièce reçue';

	/// fr: 'L'envoi n'a pas abouti. Réessayez dans un instant.'
	String get erreur => 'L\'envoi n\'a pas abouti. Réessayez dans un instant.';

	/// fr: 'Cette photo dépasse {taille} Mo. Reprenez-la en qualité plus basse.'
	String tropVolumineux({required Object taille}) => 'Cette photo dépasse ${taille} Mo. Reprenez-la en qualité plus basse.';
}

// Path: appareils
class Traductions$appareils$fr {
	Traductions$appareils$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Appareils'
	String get titre => 'Appareils';

	/// fr: 'Deux appareils au maximum par enfant, un seul en cours à la fois.'
	String get regle => 'Deux appareils au maximum par enfant, un seul en cours à la fois.';

	/// fr: 'Ajouter un appareil'
	String get ajouter => 'Ajouter un appareil';

	/// fr: 'Deux appareils sont déjà appairés pour {prenom}. Retirez-en un pour en ajouter un autre.'
	String limiteAtteinte({required Object prenom}) => 'Deux appareils sont déjà appairés pour ${prenom}. Retirez-en un pour en ajouter un autre.';

	/// fr: 'Sur l'appareil de l'enfant'
	String get codeTitre => 'Sur l\'appareil de l\'enfant';

	/// fr: 'Ouvrez l'application Rewayah, puis entrez ce code.'
	String get codeInstruction => 'Ouvrez l\'application Rewayah, puis entrez ce code.';

	/// fr: 'Expire dans {temps}'
	String expireDans({required Object temps}) => 'Expire dans ${temps}';

	/// fr: 'Ce code a expiré.'
	String get expire => 'Ce code a expiré.';

	/// fr: 'Générer un nouveau code'
	String get regenerer => 'Générer un nouveau code';

	/// fr: 'Retirer'
	String get revoquer => 'Retirer';

	/// fr: 'Retirer cet appareil ? L'enfant devra le réappairer pour s'en resservir.'
	String get revoquerConfirmation => 'Retirer cet appareil ? L\'enfant devra le réappairer pour s\'en resservir.';

	/// fr: 'Utilisé {quand}'
	String derniereUtilisation({required Object quand}) => 'Utilisé ${quand}';

	/// fr: 'Jamais utilisé'
	String get jamaisUtilise => 'Jamais utilisé';

	/// fr: 'L'opération n'a pas abouti. Réessayez dans un instant.'
	String get erreur => 'L\'opération n\'a pas abouti. Réessayez dans un instant.';
}

// Path: enfant
class Traductions$enfant$fr {
	Traductions$enfant$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Ajouter un enfant'
	String get titre => 'Ajouter un enfant';

	/// fr: 'Son prénom'
	String get prenom => 'Son prénom';

	/// fr: 'Son nom'
	String get nom => 'Son nom';

	/// fr: 'Son âge'
	String get age => 'Son âge';

	/// fr: 'Indiquez un âge entre 3 et 18 ans.'
	String get ageInvalide => 'Indiquez un âge entre 3 et 18 ans.';

	/// fr: 'L'âge fixe le mode d'affichage et la politique caméra. Vous pourrez changer les deux à tout moment.'
	String get ageRaison => 'L\'âge fixe le mode d\'affichage et la politique caméra. Vous pourrez changer les deux à tout moment.';

	/// fr: 'Ajouter au foyer'
	String get creer => 'Ajouter au foyer';

	/// fr: 'L'ajout n'a pas abouti. Réessayez dans un instant.'
	String get erreur => 'L\'ajout n\'a pas abouti. Réessayez dans un instant.';

	/// fr: 'Aucun enfant dans le foyer'
	String get aucun => 'Aucun enfant dans le foyer';

	/// fr: 'Ajoutez votre premier enfant pour pouvoir appairer son appareil.'
	String get aucunDetail => 'Ajoutez votre premier enfant pour pouvoir appairer son appareil.';
}

// Path: foyer
class Traductions$foyer$fr {
	Traductions$foyer$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Foyer'
	String get titre => 'Foyer';

	/// fr: 'Ajouter un profil élève'
	String get ajouterProfil => 'Ajouter un profil élève';
}

// Path: ficheEleve
class Traductions$ficheEleve$fr {
	Traductions$ficheEleve$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Informations de l'élève'
	String get informations => 'Informations de l\'élève';

	/// fr: 'Parcours et inscription'
	String get inscription => 'Parcours et inscription';

	/// fr: 'Interface'
	String get interface => 'Interface';

	/// fr: 'Caméra en cours'
	String get camera => 'Caméra en cours';

	/// fr: 'Accès Rewayah'
	String get acces => 'Accès Rewayah';

	/// fr: 'Appareils'
	String get appareils => 'Appareils';
}

// Path: disponibilites
class Traductions$disponibilites$fr {
	Traductions$disponibilites$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Quand vos enfants peuvent-ils suivre un cours ?'
	String get titre => 'Quand vos enfants peuvent-ils suivre un cours ?';

	/// fr: 'Quand pouvez-vous donner cours ?'
	String get titreEnseignant => 'Quand pouvez-vous donner cours ?';

	/// fr: 'Touchez les heures possibles pour {prenom}.'
	String consigne({required Object prenom}) => 'Touchez les heures possibles pour ${prenom}.';

	/// fr: 'Touchez les heures où vous êtes disponible.'
	String get consigneEnseignant => 'Touchez les heures où vous êtes disponible.';

	/// fr: 'Un enseignant choisira parmi ces heures. Plus vous en proposez, plus vite le cours démarre.'
	String get effet => 'Un enseignant choisira parmi ces heures. Plus vous en proposez, plus vite le cours démarre.';

	/// fr: 'Vous ne verrez que les élèves dont les heures croisent les vôtres.'
	String get effetEnseignant => 'Vous ne verrez que les élèves dont les heures croisent les vôtres.';

	/// fr: 'Heures affichées en {fuseau}'
	String fuseau({required Object fuseau}) => 'Heures affichées en ${fuseau}';

	/// fr: 'Aucune heure proposée pour {prenom}'
	String aucune({required Object prenom}) => 'Aucune heure proposée pour ${prenom}';

	/// fr: 'Sans créneau, aucun enseignant ne peut prendre {prenom} en charge.'
	String aucuneDetail({required Object prenom}) => 'Sans créneau, aucun enseignant ne peut prendre ${prenom} en charge.';

	/// fr: '{nombre} heures proposées'
	String posees({required Object nombre}) => '${nombre} heures proposées';

	/// fr: '1 heure proposée'
	String get poseeUne => '1 heure proposée';

	/// fr: '{jour} {heure} heures, proposé. Toucher pour retirer'
	String cellulePosee({required Object jour, required Object heure}) => '${jour} ${heure} heures, proposé. Toucher pour retirer';

	/// fr: '{jour} {heure} heures, libre. Toucher pour proposer'
	String celluleLibre({required Object jour, required Object heure}) => '${jour} ${heure} heures, libre. Toucher pour proposer';

	/// fr: 'Ce créneau n'a pas pu être enregistré. Réessayez.'
	String get erreur => 'Ce créneau n\'a pas pu être enregistré. Réessayez.';

	List<String> get joursCourts => [
		'Lun',
		'Mar',
		'Mer',
		'Jeu',
		'Ven',
		'Sam',
		'Dim',
	];
	List<String> get joursLongs => [
		'lundi',
		'mardi',
		'mercredi',
		'jeudi',
		'vendredi',
		'samedi',
		'dimanche',
	];
}

// Path: creneaux
class Traductions$creneaux$fr {
	Traductions$creneaux$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Créneaux'
	String get titre => 'Créneaux';

	/// fr: 'Mes heures'
	String get ongletHeures => 'Mes heures';

	/// fr: 'Élèves en attente'
	String get ongletEleves => 'Élèves en attente';

	/// fr: 'Vous suivez {nombre} élèves sur {plafond} possibles.'
	String mesEleves({required Object nombre, required Object plafond}) => 'Vous suivez ${nombre} élèves sur ${plafond} possibles.';

	/// fr: 'Aucun élève en attente sur vos heures'
	String get aucunEleve => 'Aucun élève en attente sur vos heures';

	/// fr: 'Proposez d'autres heures pour voir plus de familles.'
	String get aucunEleveDetail => 'Proposez d\'autres heures pour voir plus de familles.';

	/// fr: 'Attend depuis {jours} jours'
	String attendDepuis({required Object jours}) => 'Attend depuis ${jours} jours';

	/// fr: 'Attend depuis 1 jour'
	String get attendUnJour => 'Attend depuis 1 jour';

	/// fr: 'Demande déposée aujourd'hui'
	String get attendAujourdhui => 'Demande déposée aujourd\'hui';

	/// fr: 'Niveau {niveau}'
	String niveau({required Object niveau}) => 'Niveau ${niveau}';

	/// fr: 'Prendre {jour} à {heure} h'
	String prendre({required Object jour, required Object heure}) => 'Prendre ${jour} à ${heure} h';

	/// fr: 'Enregistrement'
	String get priseEnCours => 'Enregistrement';

	/// fr: 'Vous suivez déjà {nombre} élèves, votre maximum. Un élève pris est un engagement durable, pas une réservation.'
	String plafondAtteint({required Object nombre}) => 'Vous suivez déjà ${nombre} élèves, votre maximum. Un élève pris est un engagement durable, pas une réservation.';

	/// fr: 'Demander à suivre plus d'élèves'
	String get plafondDemander => 'Demander à suivre plus d\'élèves';

	/// fr: 'Combien d'élèves pouvez-vous suivre ?'
	String get demandeTitre => 'Combien d\'élèves pouvez-vous suivre ?';

	/// fr: 'Pourquoi ce changement ?'
	String get demandeMotif => 'Pourquoi ce changement ?';

	/// fr: 'Un motif est nécessaire : c'est lui qui permet de trancher.'
	String get demandeMotifRequis => 'Un motif est nécessaire : c\'est lui qui permet de trancher.';

	/// fr: 'Envoyer la demande'
	String get demandeEnvoyer => 'Envoyer la demande';

	/// fr: 'Demande envoyée. L'administration la tranchera.'
	String get demandeEnvoyee => 'Demande envoyée. L\'administration la tranchera.';

	/// fr: '{nombre} élèves'
	String eleves({required Object nombre}) => '${nombre} élèves';

	/// fr: 'L'opération n'a pas abouti : {message}'
	String erreur({required Object message}) => 'L\'opération n\'a pas abouti : ${message}';
}

// Path: priere
class Traductions$priere$fr {
	Traductions$priere$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Fajr'
	String get fajr => 'Fajr';

	/// fr: 'Dhuhr'
	String get dhuhr => 'Dhuhr';

	/// fr: 'Asr'
	String get asr => 'Asr';

	/// fr: 'Maghrib'
	String get maghrib => 'Maghrib';

	/// fr: 'Isha'
	String get isha => 'Isha';

	/// fr: '{priere}, {minutes} min'
	String entree({required Object priere, required Object minutes}) => '${priere}, ${minutes} min';

	/// fr: 'Ce cours sera interrompu pour {priere}, vers {heure}.'
	String annonce({required Object priere, required Object heure}) => 'Ce cours sera interrompu pour ${priere}, vers ${heure}.';

	/// fr: 'Aucune interruption prévue pendant ce cours.'
	String get annonceAucune => 'Aucune interruption prévue pendant ce cours.';

	/// fr: '{priere} dans {minutes} min'
	String alerte({required Object priere, required Object minutes}) => '${priere} dans ${minutes} min';

	/// fr: 'Pause pour {priere}, reprise à {heure}'
	String alerteMaintenant({required Object priere, required Object heure}) => 'Pause pour ${priere}, reprise à ${heure}';

	/// fr: 'Pause'
	String get pause => 'Pause';

	/// fr: 'Horaires calculés pour {lieu}'
	String lieu({required Object lieu}) => 'Horaires calculés pour ${lieu}';

	/// fr: 'Horaires calculés pour le lieu de l'enseignant'
	String get lieuSansNom => 'Horaires calculés pour le lieu de l\'enseignant';

	/// fr: '{priere} ajustée de {minutes} min par l'enseignant'
	String ajustee({required Object priere, required Object minutes}) => '${priere} ajustée de ${minutes} min par l\'enseignant';

	/// fr: 'L'enseignant n'a pas encore réglé ses horaires de prière.'
	String get reglagesAbsents => 'L\'enseignant n\'a pas encore réglé ses horaires de prière.';
}

// Path: eleveConnexion
class Traductions$eleveConnexion$fr {
	Traductions$eleveConnexion$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'J'ai un code'
	String get entrerCode => 'J\'ai un code';

	/// fr: 'Scanner le carré'
	String get scanner => 'Scanner le carré';

	/// fr: 'Entre le code affiché sur le téléphone de tes parents'
	String get codeInvite => 'Entre le code affiché sur le téléphone de tes parents';

	/// fr: 'Ce code ne marche pas'
	String get codeErreur => 'Ce code ne marche pas';

	/// fr: 'Ce code est trop vieux. Demande-en un nouveau.'
	String get codeExpire => 'Ce code est trop vieux. Demande-en un nouveau.';

	/// fr: 'Qui es-tu ?'
	String get choisirProfil => 'Qui es-tu ?';

	/// fr: 'Choisis ton code secret'
	String get nouveauCode => 'Choisis ton code secret';

	/// fr: 'Entre-le encore une fois'
	String get nouveauCodeConfirmer => 'Entre-le encore une fois';

	/// fr: 'Les deux codes ne sont pas les mêmes'
	String get codeDifferent => 'Les deux codes ne sont pas les mêmes';

	/// fr: 'Code enregistré'
	String get codeEnregistre => 'Code enregistré';
}

// Path: dossiers
class Traductions$dossiers$fr {
	Traductions$dossiers$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Dossiers à valider'
	String get titre => 'Dossiers à valider';

	/// fr: 'Aucun dossier en attente'
	String get aucun => 'Aucun dossier en attente';

	/// fr: 'Les nouvelles inscriptions apparaîtront ici, la plus ancienne en premier.'
	String get aucunDetail => 'Les nouvelles inscriptions apparaîtront ici, la plus ancienne en premier.';

	/// fr: '1 dossier en attente'
	String get restantUn => '1 dossier en attente';

	/// fr: '{n} dossiers en attente'
	String restants({required Object n}) => '${n} dossiers en attente';

	/// fr: 'Déposé le {date}'
	String deposeLe({required Object date}) => 'Déposé le ${date}';

	/// fr: 'Inscrit aujourd'hui'
	String get inscritAujourdhui => 'Inscrit aujourd\'hui';

	/// fr: 'Inscrit depuis 1 jour'
	String get inscritDepuisUnJour => 'Inscrit depuis 1 jour';

	/// fr: 'Inscrit depuis {jours} jours'
	String inscritDepuis({required Object jours}) => 'Inscrit depuis ${jours} jours';

	/// fr: 'Aucune pièce déposée'
	String get sansPiece => 'Aucune pièce déposée';

	/// fr: 'Cette personne a créé son compte et accepté les contrats, mais n'a pas encore envoyé sa pièce d'identité. Il n'y a donc rien à vérifier : le geste est chez elle.'
	String get sansPieceDetail => 'Cette personne a créé son compte et accepté les contrats, mais n\'a pas encore envoyé sa pièce d\'identité. Il n\'y a donc rien à vérifier : le geste est chez elle.';

	/// fr: 'Pièce hors de votre portée'
	String get pieceNonVisible => 'Pièce hors de votre portée';

	/// fr: 'Une pièce a bien été déposée, mais la règle de genre vous interdit de la consulter. Un membre du personnel du même genre que cette personne doit la vérifier.'
	String get pieceNonVisibleDetail => 'Une pièce a bien été déposée, mais la règle de genre vous interdit de la consulter. Un membre du personnel du même genre que cette personne doit la vérifier.';

	/// fr: 'Rien à trancher pour l'instant'
	String get rienATrancher => 'Rien à trancher pour l\'instant';

	/// fr: 'La pièce déposée'
	String get apercu => 'La pièce déposée';

	/// fr: 'Aperçu indisponible'
	String get apercuIndisponible => 'Aperçu indisponible';

	/// fr: 'Vérifications'
	String get verifications => 'Vérifications';

	/// fr: 'La pièce est lisible'
	String get pointLisible => 'La pièce est lisible';

	/// fr: 'Le nom correspond à celui du compte'
	String get pointNom => 'Le nom correspond à celui du compte';

	/// fr: 'La pièce n'est pas expirée'
	String get pointValidite => 'La pièce n\'est pas expirée';

	/// fr: 'Décision'
	String get verdict => 'Décision';

	/// fr: 'Valider le dossier'
	String get approuver => 'Valider le dossier';

	/// fr: 'Refuser'
	String get refuser => 'Refuser';

	/// fr: 'Ce qui ne va pas, en une phrase'
	String get motif => 'Ce qui ne va pas, en une phrase';

	/// fr: 'Un refus doit dire ce qui ne va pas : la famille n'a que cette phrase pour corriger.'
	String get motifRequis => 'Un refus doit dire ce qui ne va pas : la famille n\'a que cette phrase pour corriger.';

	/// fr: 'Chaque consultation de pièce est inscrite au journal d'audit, avec votre nom.'
	String get journalisation => 'Chaque consultation de pièce est inscrite au journal d\'audit, avec votre nom.';

	/// fr: 'Renseignez votre genre dans votre profil avant de consulter un dossier.'
	String get genreManquant => 'Renseignez votre genre dans votre profil avant de consulter un dossier.';

	/// fr: 'La décision n'a pas abouti. Réessayez dans un instant.'
	String get erreur => 'La décision n\'a pas abouti. Réessayez dans un instant.';
}

// Path: admin
class Traductions$admin$fr {
	Traductions$admin$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations
	late final Traductions$admin$tableau$fr tableau = Traductions$admin$tableau$fr.internal(_root);
	late final Traductions$admin$demandes$fr demandes = Traductions$admin$demandes$fr.internal(_root);
	late final Traductions$admin$attribution$fr attribution = Traductions$admin$attribution$fr.internal(_root);
	late final Traductions$admin$groupes$fr groupes = Traductions$admin$groupes$fr.internal(_root);
	late final Traductions$admin$diagnostics$fr diagnostics = Traductions$admin$diagnostics$fr.internal(_root);
	late final Traductions$admin$qualite$fr qualite = Traductions$admin$qualite$fr.internal(_root);
	late final Traductions$admin$regles$fr regles = Traductions$admin$regles$fr.internal(_root);
	late final Traductions$admin$fonctionnalites$fr fonctionnalites = Traductions$admin$fonctionnalites$fr.internal(_root);
	late final Traductions$admin$conservationDonnees$fr conservationDonnees = Traductions$admin$conservationDonnees$fr.internal(_root);
	late final Traductions$admin$evaluations$fr evaluations = Traductions$admin$evaluations$fr.internal(_root);
	late final Traductions$admin$progression$fr progression = Traductions$admin$progression$fr.internal(_root);
	late final Traductions$admin$programmes$fr programmes = Traductions$admin$programmes$fr.internal(_root);
	late final Traductions$admin$journal$fr journal = Traductions$admin$journal$fr.internal(_root);
	late final Traductions$admin$observations$fr observations = Traductions$admin$observations$fr.internal(_root);
	late final Traductions$admin$comptes$fr comptes = Traductions$admin$comptes$fr.internal(_root);
	late final Traductions$admin$agents$fr agents = Traductions$admin$agents$fr.internal(_root);
	late final Traductions$admin$notifications$fr notifications = Traductions$admin$notifications$fr.internal(_root);
}

// Path: agent
class Traductions$agent$fr {
	Traductions$agent$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Entrée d'un agent'
	String get titre => 'Entrée d\'un agent';

	/// fr: 'Cette page ouvre l'application en lecture seule, avec le jeton remis par l'académie.'
	String get intro => 'Cette page ouvre l\'application en lecture seule, avec le jeton remis par l\'académie.';

	/// fr: 'Jeton d'observation'
	String get jeton => 'Jeton d\'observation';

	/// fr: 'rag_...'
	String get jetonExemple => 'rag_...';

	/// fr: 'Ouvrir l'application'
	String get entrer => 'Ouvrir l\'application';

	/// fr: 'Ouverture'
	String get ouverture => 'Ouverture';

	/// fr: 'Jeton refusé'
	String get refus => 'Jeton refusé';

	/// fr: 'Ce jeton est inconnu, révoqué ou expiré. Demandez-en un nouveau à l'académie.'
	String get refusDetail => 'Ce jeton est inconnu, révoqué ou expiré. Demandez-en un nouveau à l\'académie.';

	/// fr: 'Service indisponible'
	String get indisponible => 'Service indisponible';

	/// fr: 'L'ouverture de session n'a pas répondu. Réessayez dans un instant.'
	String get indisponibleDetail => 'L\'ouverture de session n\'a pas répondu. Réessayez dans un instant.';

	/// fr: 'Réessayer'
	String get reessayer => 'Réessayer';

	/// fr: 'Observation, lecture seule'
	String get bandeau => 'Observation, lecture seule';

	/// fr: 'Prénoms masqués'
	String get bandeauMasque => 'Prénoms masqués';

	/// fr: 'jusqu'à {heure}'
	String bandeauExpire({required Object heure}) => 'jusqu\'à ${heure}';
}

// Path: vide
class Traductions$vide$fr {
	Traductions$vide$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Aucun cours aujourd'hui'
	String get aucunCours => 'Aucun cours aujourd\'hui';

	/// fr: 'Votre prochain cours apparaîtra ici.'
	String get aucunCoursDetail => 'Votre prochain cours apparaîtra ici.';

	/// fr: 'Aucun créneau disponible pour le moment'
	String get aucunCreneau => 'Aucun créneau disponible pour le moment';

	/// fr: 'Aucun cahier de transmission pour l'instant'
	String get aucunRapport => 'Aucun cahier de transmission pour l\'instant';

	/// fr: 'Aucun appareil appairé'
	String get aucunAppareil => 'Aucun appareil appairé';
}

// Path: pin
class Traductions$pin$fr {
	Traductions$pin$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Entre ton code'
	String get titre => 'Entre ton code';

	/// fr: 'Ce code ne correspond pas'
	String get erreur => 'Ce code ne correspond pas';

	/// fr: 'Effacer'
	String get effacer => 'Effacer';
}

// Path: choix
class Traductions$choix$fr {
	Traductions$choix$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Autre'
	String get autre => 'Autre';

	/// fr: 'Précisez'
	String get autreInvite => 'Précisez';

	/// fr: 'Plusieurs réponses possibles'
	String get selectionMultiple => 'Plusieurs réponses possibles';
}

// Path: parcours
class Traductions$parcours$fr {
	Traductions$parcours$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Le parcours de {prenom}'
	String titre({required Object prenom}) => 'Le parcours de ${prenom}';

	/// fr: 'Quelques questions pour personnaliser votre parcours. Vous ne verrez ensuite que les horaires et options adaptés à votre situation.'
	String get intro => 'Quelques questions pour personnaliser votre parcours. Vous ne verrez ensuite que les horaires et options adaptés à votre situation.';

	/// fr: 'Reprendre'
	String get reprendre => 'Reprendre';

	/// fr: 'Personnaliser le parcours'
	String get commencer => 'Personnaliser le parcours';

	/// fr: 'Modifier mes réponses'
	String get modifier => 'Modifier mes réponses';

	/// fr: 'Cette réponse n'a pas pu être enregistrée. Réessayez.'
	String get erreur => 'Cette réponse n\'a pas pu être enregistrée. Réessayez.';

	/// fr: 'Nous préparons vos options.'
	String get chargement => 'Nous préparons vos options.';

	/// fr: 'Quel âge a {prenom} ?'
	String ageQuestion({required Object prenom}) => 'Quel âge a ${prenom} ?';

	/// fr: 'L'âge décide de la durée des séances et du nombre d'élèves par groupe. Nous ne demandons pas de date de naissance : une tranche suffit.'
	String get ageRaison => 'L\'âge décide de la durée des séances et du nombre d\'élèves par groupe. Nous ne demandons pas de date de naissance : une tranche suffit.';

	/// fr: 'Dans quelle langue le cours doit-il être donné ?'
	String get langueQuestion => 'Dans quelle langue le cours doit-il être donné ?';

	/// fr: 'C'est la langue que l'enseignant parlera pendant la séance. Elle est indépendante de la langue de l'application, que vous pouvez changer à tout moment dans vos réglages.'
	String get langueRaison => 'C\'est la langue que l\'enseignant parlera pendant la séance. Elle est indépendante de la langue de l\'application, que vous pouvez changer à tout moment dans vos réglages.';

	/// fr: 'Où vous trouvez-vous ?'
	String get lieuQuestion => 'Où vous trouvez-vous ?';

	/// fr: 'Nous nous en servons uniquement pour vous montrer les horaires à votre heure locale. Nous ne demandons jamais votre position exacte, et cette réponse ne quitte pas votre dossier.'
	String get lieuRaison => 'Nous nous en servons uniquement pour vous montrer les horaires à votre heure locale. Nous ne demandons jamais votre position exacte, et cette réponse ne quitte pas votre dossier.';

	/// fr: 'Proposé d'après l'heure de votre appareil'
	String get lieuSuggere => 'Proposé d\'après l\'heure de votre appareil';

	/// fr: 'Où en est {prenom} aujourd'hui ?'
	String niveauQuestion({required Object prenom}) => 'Où en est ${prenom} aujourd\'hui ?';

	/// fr: 'Votre réponse oriente les premières propositions. Elle ne fixe pas le niveau officiel : celui-ci est attribué par l'académie après un échange avec un enseignant.'
	String get niveauRaison => 'Votre réponse oriente les premières propositions. Elle ne fixe pas le niveau officiel : celui-ci est attribué par l\'académie après un échange avec un enseignant.';

	/// fr: 'Nous commençons par les lettres'
	String get niveauDebutLettres => 'Nous commençons par les lettres';

	/// fr: 'Les lettres sont reconnues, la lecture demande de l'aide'
	String get niveauLettresAvecAide => 'Les lettres sont reconnues, la lecture demande de l\'aide';

	/// fr: 'La lecture est possible, lentement'
	String get niveauLectureLente => 'La lecture est possible, lentement';

	/// fr: 'Le Coran se lit déjà couramment'
	String get niveauLectureCourante => 'Le Coran se lit déjà couramment';

	/// fr: 'Une partie est déjà mémorisée'
	String get niveauMemorisationPartielle => 'Une partie est déjà mémorisée';

	/// fr: 'Que souhaitez-vous d'abord ?'
	String get objectifQuestion => 'Que souhaitez-vous d\'abord ?';

	/// fr: 'Vous pourrez changer d'objectif plus tard : il oriente le travail de l'enseignant, il ne vous engage pas.'
	String get objectifRaison => 'Vous pourrez changer d\'objectif plus tard : il oriente le travail de l\'enseignant, il ne vous engage pas.';

	/// fr: 'Apprendre à lire'
	String get objectifApprendreALire => 'Apprendre à lire';

	/// fr: 'Lire plus couramment'
	String get objectifDevenirFluide => 'Lire plus couramment';

	/// fr: 'Mémoriser'
	String get objectifMemoriser => 'Mémoriser';

	/// fr: 'Je ne sais pas encore'
	String get objectifIndecis => 'Je ne sais pas encore';

	/// fr: 'Quels moments de la journée vous conviennent le mieux ?'
	String get momentsQuestion => 'Quels moments de la journée vous conviennent le mieux ?';

	/// fr: 'Cette réponse ne crée aucun horaire et ne réserve rien. Elle sert seulement à mettre en avant, parmi les horaires que l'académie propose déjà, ceux qui tombent le mieux pour vous. Vous verrez tous les autres juste en dessous.'
	String get momentsRaison => 'Cette réponse ne crée aucun horaire et ne réserve rien. Elle sert seulement à mettre en avant, parmi les horaires que l\'académie propose déjà, ceux qui tombent le mieux pour vous. Vous verrez tous les autres juste en dessous.';

	/// fr: 'Le matin'
	String get momentMatin => 'Le matin';

	/// fr: 'L'après-midi'
	String get momentApresMidi => 'L\'après-midi';

	/// fr: 'Le soir'
	String get momentSoir => 'Le soir';

	/// fr: 'Voici les horaires ouverts pour {prenom}'
	String offresQuestion({required Object prenom}) => 'Voici les horaires ouverts pour ${prenom}';

	/// fr: 'Ces horaires sont affichés à votre heure locale. Choisir un horaire enregistre votre préférence : cela ne réserve pas de place et ne constitue pas encore un groupe.'
	String get offresRaison => 'Ces horaires sont affichés à votre heure locale. Choisir un horaire enregistre votre préférence : cela ne réserve pas de place et ne constitue pas encore un groupe.';

	/// fr: 'Le plus proche de vos réponses'
	String get offreRecommandee => 'Le plus proche de vos réponses';

	/// fr: 'Autres horaires possibles'
	String get offresAutres => 'Autres horaires possibles';

	/// fr: '{seances} séances par semaine, {duree} min'
	String offreRecurrence({required Object seances, required Object duree}) => '${seances} séances par semaine, ${duree} min';

	/// fr: '{seances} séances par semaine, {duree} min dont {pause} min de pause'
	String offreRecurrencePause({required Object seances, required Object duree, required Object pause}) => '${seances} séances par semaine, ${duree} min dont ${pause} min de pause';

	/// fr: 'Cours en {langue}'
	String offreLangue({required Object langue}) => 'Cours en ${langue}';

	/// fr: 'Heure affichée pour {fuseau}'
	String offreFuseau({required Object fuseau}) => 'Heure affichée pour ${fuseau}';

	/// fr: 'Affiché à votre heure locale'
	String get offreTraduite => 'Affiché à votre heure locale';

	/// fr: '{jours}'
	String offreJours({required Object jours}) => '${jours}';

	/// fr: 'Choisir cet horaire'
	String get offreChoisir => 'Choisir cet horaire';

	/// fr: 'Horaire retenu'
	String get offreChoisie => 'Horaire retenu';

	/// fr: 'Aucun horaire ouvert ne correspond encore'
	String get aucuneOffre => 'Aucun horaire ouvert ne correspond encore';

	/// fr: 'L'académie ouvre de nouveaux horaires au fil des inscriptions. Vous pouvez nous signaler votre besoin : cela nous aide à décider lesquels ouvrir.'
	String get aucuneOffreDetail => 'L\'académie ouvre de nouveaux horaires au fil des inscriptions. Vous pouvez nous signaler votre besoin : cela nous aide à décider lesquels ouvrir.';

	/// fr: 'Aucun de ces horaires ne me convient'
	String get refusAucun => 'Aucun de ces horaires ne me convient';

	/// fr: 'Me prévenir si de nouveaux horaires ouvrent'
	String get refusPrevenir => 'Me prévenir si de nouveaux horaires ouvrent';

	/// fr: 'Nous enregistrons que la demande existe. Cela ne crée pas de groupe, ne cherche pas d'enseignant et ne promet aucun horaire futur.'
	String get refusEffet => 'Nous enregistrons que la demande existe. Cela ne crée pas de groupe, ne cherche pas d\'enseignant et ne promet aucun horaire futur.';

	/// fr: 'C'est noté. Nous vous préviendrons si un horaire correspondant ouvre.'
	String get refusEnregistre => 'C\'est noté. Nous vous préviendrons si un horaire correspondant ouvre.';

	/// fr: 'Parcours à personnaliser'
	String get etatAPersonnaliser => 'Parcours à personnaliser';

	/// fr: 'Quelques questions, et nous ne vous montrerons que ce qui convient à {prenom}.'
	String etatAPersonnaliserDetail({required Object prenom}) => 'Quelques questions, et nous ne vous montrerons que ce qui convient à ${prenom}.';

	/// fr: 'Horaire à choisir'
	String get etatHoraireAChoisir => 'Horaire à choisir';

	/// fr: 'Les horaires ouverts pour {prenom} vous attendent.'
	String etatHoraireAChoisirDetail({required Object prenom}) => 'Les horaires ouverts pour ${prenom} vous attendent.';

	/// fr: 'Cet horaire n'est plus proposé'
	String get etatOffreIndisponible => 'Cet horaire n\'est plus proposé';

	/// fr: 'L'horaire retenu pour {prenom} a été retiré avant qu'un groupe soit constitué. Choisissez-en un autre : rien n'est perdu.'
	String etatOffreIndisponibleDetail({required Object prenom}) => 'L\'horaire retenu pour ${prenom} a été retiré avant qu\'un groupe soit constitué. Choisissez-en un autre : rien n\'est perdu.';

	/// fr: 'Préférence enregistrée'
	String get etatDiagnosticRequis => 'Préférence enregistrée';

	/// fr: 'Il reste un échange avec un enseignant pour situer le niveau de {prenom}. L'académie vous proposera un rendez-vous.'
	String etatDiagnosticRequisDetail({required Object prenom}) => 'Il reste un échange avec un enseignant pour situer le niveau de ${prenom}. L\'académie vous proposera un rendez-vous.';

	/// fr: 'Rendez-vous prévu'
	String get etatDiagnosticEnAttente => 'Rendez-vous prévu';

	/// fr: 'Un échange est prévu pour situer le niveau de {prenom}.'
	String etatDiagnosticEnAttenteDetail({required Object prenom}) => 'Un échange est prévu pour situer le niveau de ${prenom}.';

	/// fr: 'Groupe en cours de constitution'
	String get etatGroupeEnFormation => 'Groupe en cours de constitution';

	/// fr: 'Un groupe démarre à partir de {minimum} élèves. Nous vous préviendrons dès qu'il est confirmé.'
	String etatGroupeEnFormationDetail({required Object minimum}) => 'Un groupe démarre à partir de ${minimum} élèves. Nous vous préviendrons dès qu\'il est confirmé.';

	/// fr: 'Groupe confirmé'
	String get etatGroupeConfirme => 'Groupe confirmé';

	/// fr: 'Le groupe de {prenom} est constitué. Vous retrouverez ses séances dans son espace.'
	String etatGroupeConfirmeDetail({required Object prenom}) => 'Le groupe de ${prenom} est constitué. Vous retrouverez ses séances dans son espace.';

	/// fr: 'Votre lieu a changé depuis ce choix'
	String get fuseauChange => 'Votre lieu a changé depuis ce choix';

	/// fr: 'L'horaire est le même pour l'académie, mais il ne tombe plus à la même heure chez vous. Vérifiez qu'il vous convient toujours.'
	String get fuseauChangeDetail => 'L\'horaire est le même pour l\'académie, mais il ne tombe plus à la même heure chez vous. Vérifiez qu\'il vous convient toujours.';

	/// fr: 'Voir les horaires'
	String get voirHoraires => 'Voir les horaires';

	/// fr: 'Changer d'horaire'
	String get changerHoraire => 'Changer d\'horaire';

	/// fr: 'La famille a changé d'horaire depuis le parcours'
	String get renoncerMotif => 'La famille a changé d\'horaire depuis le parcours';
}

// Path: avatar
class Traductions$avatar$fr {
	Traductions$avatar$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Pas encore de photo'
	String get sansPhoto => 'Pas encore de photo';
}

// Path: nav
class Traductions$nav$fr {
	Traductions$nav$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations
	late final Traductions$nav$eleve$fr eleve = Traductions$nav$eleve$fr.internal(_root);
	late final Traductions$nav$tuteur$fr tuteur = Traductions$nav$tuteur$fr.internal(_root);
	late final Traductions$nav$enseignant$fr enseignant = Traductions$nav$enseignant$fr.internal(_root);
	late final Traductions$nav$controleur$fr controleur = Traductions$nav$controleur$fr.internal(_root);
	late final Traductions$nav$admin$fr admin = Traductions$nav$admin$fr.internal(_root);

	/// fr: 'Mon compte'
	String get compte => 'Mon compte';

	/// fr: 'Navigation principale'
	String get principale => 'Navigation principale';

	/// fr: 'Rewayah'
	String get motSymbole => 'Rewayah';

	/// fr: 'Replier la navigation'
	String get replier => 'Replier la navigation';

	/// fr: 'Déplier la navigation'
	String get deplier => 'Déplier la navigation';
}

// Path: compte
class Traductions$compte$fr {
	Traductions$compte$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Mon compte'
	String get titre => 'Mon compte';

	/// fr: 'Vos informations, vos préférences et vos accès, au même endroit.'
	String get intro => 'Vos informations, vos préférences et vos accès, au même endroit.';

	/// fr: 'Informations'
	String get informations => 'Informations';

	/// fr: 'Profil'
	String get profil => 'Profil';

	/// fr: 'Voir et gérer vos informations'
	String get profilDetail => 'Voir et gérer vos informations';

	/// fr: 'Réglages'
	String get reglages => 'Réglages';

	/// fr: 'Apparence, notifications et accessibilité'
	String get reglagesDetail => 'Apparence, notifications et accessibilité';

	/// fr: 'Profils du foyer'
	String get profils => 'Profils du foyer';

	/// fr: 'Gérer les profils de vos enfants'
	String get profilsDetail => 'Gérer les profils de vos enfants';

	/// fr: 'Foyer'
	String get appareils => 'Foyer';

	/// fr: 'Les appareils et profils rattachés à votre foyer'
	String get appareilsDetail => 'Les appareils et profils rattachés à votre foyer';

	/// fr: 'Confidentialité'
	String get confidentialite => 'Confidentialité';

	/// fr: 'Bientôt disponible'
	String get confidentialiteDetail => 'Bientôt disponible';

	/// fr: 'Espaces'
	String get espaces => 'Espaces';

	/// fr: 'Les espaces auxquels votre compte donne accès'
	String get espacesDetail => 'Les espaces auxquels votre compte donne accès';

	/// fr: 'Habilité'
	String get habilitation => 'Habilité';

	/// fr: 'Se déconnecter'
	String get deconnexion => 'Se déconnecter';

	/// fr: 'Mettre fin à la session sur cet appareil'
	String get deconnexionDetail => 'Mettre fin à la session sur cet appareil';

	/// fr: 'Identifiant'
	String get identifiant => 'Identifiant';

	/// fr: 'Non disponible'
	String get nonDisponible => 'Non disponible';

	/// fr: 'Contact'
	String get contact => 'Contact';

	/// fr: 'Géré par l'académie'
	String get contactDetail => 'Géré par l\'académie';

	/// fr: 'Langue'
	String get langue => 'Langue';

	/// fr: 'Français'
	String get francais => 'Français';

	/// fr: 'Fuseau horaire'
	String get fuseau => 'Fuseau horaire';

	/// fr: 'Académie'
	String get academie => 'Académie';

	/// fr: 'Sécurité'
	String get securite => 'Sécurité';

	/// fr: 'Statut'
	String get statut => 'Statut';

	/// fr: 'Réglages'
	String get reglagesTitre => 'Réglages';

	/// fr: 'Ces préférences restent sur cet appareil et s'appliquent tout de suite.'
	String get reglagesIntro => 'Ces préférences restent sur cet appareil et s\'appliquent tout de suite.';

	/// fr: 'Apparence'
	String get apparence => 'Apparence';

	/// fr: 'Système'
	String get themeSysteme => 'Système';

	/// fr: 'Suit le réglage de votre appareil'
	String get themeSystemeDetail => 'Suit le réglage de votre appareil';

	/// fr: 'Clair'
	String get themeClair => 'Clair';

	/// fr: 'Sombre'
	String get themeSombre => 'Sombre';

	/// fr: 'Accessibilité'
	String get accessibilite => 'Accessibilité';

	/// fr: 'Réduire les animations'
	String get animations => 'Réduire les animations';

	/// fr: 'Limite les mouvements à l'écran'
	String get animationsDetail => 'Limite les mouvements à l\'écran';

	/// fr: 'Réduire les effets'
	String get effets => 'Réduire les effets';

	/// fr: 'Limite les transparences et les ombres'
	String get effetsDetail => 'Limite les transparences et les ombres';

	/// fr: 'La taille du texte suit le réglage de votre appareil.'
	String get lisibiliteDetail => 'La taille du texte suit le réglage de votre appareil.';

	/// fr: 'Langue et région'
	String get langueRegion => 'Langue et région';

	/// fr: 'Langue de l'interface'
	String get francaisDetail => 'Langue de l\'interface';

	/// fr: 'Actif'
	String get actif => 'Actif';

	/// fr: 'Arabe'
	String get arabe => 'Arabe';

	/// fr: 'Bientôt disponible'
	String get arabeDetail => 'Bientôt disponible';

	/// fr: 'Détecté automatiquement'
	String get fuseauDetail => 'Détecté automatiquement';

	/// fr: 'Notifications'
	String get notifications => 'Notifications';

	/// fr: 'Cours'
	String get notificationsCours => 'Cours';

	/// fr: 'Rappels avant vos cours'
	String get notificationsCoursDetail => 'Rappels avant vos cours';

	/// fr: 'Foyer'
	String get notificationsFoyer => 'Foyer';

	/// fr: 'Activité des profils de votre foyer'
	String get notificationsFoyerDetail => 'Activité des profils de votre foyer';

	/// fr: 'Les notifications dépendent aussi des réglages de votre appareil et de votre navigateur.'
	String get notificationsEtat => 'Les notifications dépendent aussi des réglages de votre appareil et de votre navigateur.';

	/// fr: 'Cours et données'
	String get coursDonnees => 'Cours et données';

	/// fr: 'Économie de données'
	String get economieDonnees => 'Économie de données';

	/// fr: 'Réduit la qualité vidéo sur réseau mobile'
	String get economieDonneesDetail => 'Réduit la qualité vidéo sur réseau mobile';

	/// fr: 'Lecture en grand texte'
	String get lectureGrande => 'Lecture en grand texte';

	/// fr: 'Affiche le Coran en plus grand par défaut'
	String get lectureGrandeDetail => 'Affiche le Coran en plus grand par défaut';

	/// fr: 'Profils du foyer'
	String get profilsTitre => 'Profils du foyer';

	/// fr: 'Les enfants rattachés à votre foyer.'
	String get profilsIntro => 'Les enfants rattachés à votre foyer.';

	/// fr: 'Les profils n'ont pas pu être lus.'
	String get erreurProfils => 'Les profils n\'ont pas pu être lus.';

	/// fr: 'Réessayer'
	String get reessayer => 'Réessayer';

	/// fr: 'Aucun profil pour l'instant'
	String get aucunProfil => 'Aucun profil pour l\'instant';

	/// fr: 'Ajoutez un enfant pour commencer'
	String get aucunProfilDetail => 'Ajoutez un enfant pour commencer';

	/// fr: 'Ajouter un enfant'
	String get ajouterEnfant => 'Ajouter un enfant';

	/// fr: 'Ouvrir le profil'
	String get ouvrirProfil => 'Ouvrir le profil';

	/// fr: 'Mode enfant'
	String get modeEnfant => 'Mode enfant';

	/// fr: 'Mode standard'
	String get modeStandard => 'Mode standard';

	/// fr: 'Caméra'
	String get cameraLabel => 'Caméra';

	/// fr: 'Autorisée'
	String get cameraAutorisee => 'Autorisée';

	/// fr: 'Interdite'
	String get cameraInterdite => 'Interdite';

	/// fr: 'Accès sans date de fin'
	String get accesSansFin => 'Accès sans date de fin';

	/// fr: 'Accès jusqu'au {date}'
	String accesJusqua({required Object date}) => 'Accès jusqu\'au ${date}';

	/// fr: 'Actif'
	String get statutActif => 'Actif';

	/// fr: 'Actif, à titre provisoire'
	String get statutProvisoire => 'Actif, à titre provisoire';

	/// fr: 'Profil de {prenom}'
	String profilEnfant({required Object prenom}) => 'Profil de ${prenom}';

	/// fr: 'Identifiant : {identifiant}'
	String identifiantEnfant({required Object identifiant}) => 'Identifiant : ${identifiant}';

	late final Traductions$compte$roles$fr roles = Traductions$compte$roles$fr.internal(_root);
	late final Traductions$compte$roleDetail$fr roleDetail = Traductions$compte$roleDetail$fr.internal(_root);
}

// Path: historique
class Traductions$historique$fr {
	Traductions$historique$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Historique'
	String get titre => 'Historique';

	/// fr: 'Détail de la séance'
	String get detailSeance => 'Détail de la séance';

	late final Traductions$historique$segments$fr segments = Traductions$historique$segments$fr.internal(_root);
}

// Path: notifications
class Traductions$notifications$fr {
	Traductions$notifications$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Notifications'
	String get titre => 'Notifications';
}

// Path: eleve
class Traductions$eleve$fr {
	Traductions$eleve$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations
	late final Traductions$eleve$accueil$fr accueil = Traductions$eleve$accueil$fr.internal(_root);
	late final Traductions$eleve$coran$fr coran = Traductions$eleve$coran$fr.internal(_root);
	late final Traductions$eleve$suivi$fr suivi = Traductions$eleve$suivi$fr.internal(_root);
}

// Path: tuteur
class Traductions$tuteur$fr {
	Traductions$tuteur$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations
	late final Traductions$tuteur$accueil$fr accueil = Traductions$tuteur$accueil$fr.internal(_root);
	late final Traductions$tuteur$reglages$fr reglages = Traductions$tuteur$reglages$fr.internal(_root);
	late final Traductions$tuteur$suivi$fr suivi = Traductions$tuteur$suivi$fr.internal(_root);
}

// Path: classe
class Traductions$classe$fr {
	Traductions$classe$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Choisir une classe'
	String get catalogue => 'Choisir une classe';

	/// fr: 'Planning'
	String get planning => 'Planning';

	/// fr: 'Travail à préparer'
	String get travail => 'Travail à préparer';

	/// fr: 'Bibliothèque'
	String get ressources => 'Bibliothèque';

	/// fr: 'Progression'
	String get progression => 'Progression';

	/// fr: 'Observer la séance'
	String get observer => 'Observer la séance';

	/// fr: 'Classe'
	String get titre => 'Classe';

	/// fr: 'Historique'
	String get historique => 'Historique';

	/// fr: '{prenom} · {enseignant}'
	String sousTitre({required Object prenom, required Object enseignant}) => '${prenom} · ${enseignant}';

	/// fr: 'Le détail de la classe n'est pas encore disponible ici.'
	String get indisponiblePhrase => 'Le détail de la classe n\'est pas encore disponible ici.';

	/// fr: 'Cette classe n'est pas ouverte à ce profil'
	String get introuvableTitre => 'Cette classe n\'est pas ouverte à ce profil';

	/// fr: 'Elle a peut-être pris fin, ou elle concerne un autre élève du foyer.'
	String get introuvablePhrase => 'Elle a peut-être pris fin, ou elle concerne un autre élève du foyer.';

	late final Traductions$classe$seance$fr seance = Traductions$classe$seance$fr.internal(_root);
	late final Traductions$classe$observation$fr observation = Traductions$classe$observation$fr.internal(_root);
	late final Traductions$classe$pagePlanning$fr pagePlanning = Traductions$classe$pagePlanning$fr.internal(_root);
	late final Traductions$classe$pageTravail$fr pageTravail = Traductions$classe$pageTravail$fr.internal(_root);
	late final Traductions$classe$pageRessources$fr pageRessources = Traductions$classe$pageRessources$fr.internal(_root);
	late final Traductions$classe$pageProgression$fr pageProgression = Traductions$classe$pageProgression$fr.internal(_root);
}

// Path: enseignant
class Traductions$enseignant$fr {
	Traductions$enseignant$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations
	late final Traductions$enseignant$bienvenue$fr bienvenue = Traductions$enseignant$bienvenue$fr.internal(_root);
	late final Traductions$enseignant$journee$fr journee = Traductions$enseignant$journee$fr.internal(_root);
	late final Traductions$enseignant$salle$fr salle = Traductions$enseignant$salle$fr.internal(_root);
	late final Traductions$enseignant$cahier$fr cahier = Traductions$enseignant$cahier$fr.internal(_root);
	late final Traductions$enseignant$profil$fr profil = Traductions$enseignant$profil$fr.internal(_root);
	late final Traductions$enseignant$creneaux$fr creneaux = Traductions$enseignant$creneaux$fr.internal(_root);
	late final Traductions$enseignant$ficheGroupe$fr ficheGroupe = Traductions$enseignant$ficheGroupe$fr.internal(_root);
	late final Traductions$enseignant$revue$fr revue = Traductions$enseignant$revue$fr.internal(_root);
}

// Path: controleur
class Traductions$controleur$fr {
	Traductions$controleur$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations
	late final Traductions$controleur$planning$fr planning = Traductions$controleur$planning$fr.internal(_root);
}

// Path: aConstruire
class Traductions$aConstruire$fr {
	Traductions$aConstruire$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Écran à construire'
	String get titre => 'Écran à construire';

	/// fr: 'Cet écran arrive à l'étape 3.'
	String get detail => 'Cet écran arrive à l\'étape 3.';
}

// Path: galerie
class Traductions$galerie$fr {
	Traductions$galerie$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Galerie des composants'
	String get titre => 'Galerie des composants';

	/// fr: 'Banc d'essai de développement. Absent des versions de production.'
	String get avertissement => 'Banc d\'essai de développement. Absent des versions de production.';

	/// fr: 'Paires de couleurs'
	String get paires => 'Paires de couleurs';

	/// fr: 'Élévation et rayons'
	String get elevation => 'Élévation et rayons';

	/// fr: 'Échelles typographiques'
	String get typographie => 'Échelles typographiques';

	/// fr: 'Polices'
	String get polices => 'Polices';

	/// fr: 'Composants partagés'
	String get composants => 'Composants partagés';

	/// fr: 'Mode enfant'
	String get modeEnfant => 'Mode enfant';

	/// fr: 'Mode standard'
	String get modeStandard => 'Mode standard';
}

// Path: tc
class Traductions$tc$fr {
	Traductions$tc$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations
	late final Traductions$tc$groupe$fr groupe = Traductions$tc$groupe$fr.internal(_root);
	late final Traductions$tc$bibliotheque$fr bibliotheque = Traductions$tc$bibliotheque$fr.internal(_root);
	late final Traductions$tc$coran$fr coran = Traductions$tc$coran$fr.internal(_root);
	late final Traductions$tc$outils$fr outils = Traductions$tc$outils$fr.internal(_root);
	late final Traductions$tc$classe$fr classe = Traductions$tc$classe$fr.internal(_root);
	late final Traductions$tc$realtime$fr realtime = Traductions$tc$realtime$fr.internal(_root);
	late final Traductions$tc$observation$fr observation = Traductions$tc$observation$fr.internal(_root);
	late final Traductions$tc$parcours$fr parcours = Traductions$tc$parcours$fr.internal(_root);
}

// Path: commun.etats
class Traductions$commun$etats$fr {
	Traductions$commun$etats$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations
	late final Traductions$commun$etats$chargementProlonge$fr chargementProlonge = Traductions$commun$etats$chargementProlonge$fr.internal(_root);
	late final Traductions$commun$etats$horsLigne$fr horsLigne = Traductions$commun$etats$horsLigne$fr.internal(_root);
	late final Traductions$commun$etats$reconnexion$fr reconnexion = Traductions$commun$etats$reconnexion$fr.internal(_root);
	late final Traductions$commun$etats$echecServeur$fr echecServeur = Traductions$commun$etats$echecServeur$fr.internal(_root);
	late final Traductions$commun$etats$introuvable$fr introuvable = Traductions$commun$etats$introuvable$fr.internal(_root);
	late final Traductions$commun$etats$accesRefuse$fr accesRefuse = Traductions$commun$etats$accesRefuse$fr.internal(_root);
	late final Traductions$commun$etats$sessionExpiree$fr sessionExpiree = Traductions$commun$etats$sessionExpiree$fr.internal(_root);
	late final Traductions$commun$etats$dossierEnAttente$fr dossierEnAttente = Traductions$commun$etats$dossierEnAttente$fr.internal(_root);
	late final Traductions$commun$etats$aucunResultat$fr aucunResultat = Traductions$commun$etats$aucunResultat$fr.internal(_root);
	late final Traductions$commun$etats$permissionRefusee$fr permissionRefusee = Traductions$commun$etats$permissionRefusee$fr.internal(_root);
	late final Traductions$commun$etats$ressourceExpiree$fr ressourceExpiree = Traductions$commun$etats$ressourceExpiree$fr.internal(_root);
	late final Traductions$commun$etats$indisponible$fr indisponible = Traductions$commun$etats$indisponible$fr.internal(_root);

	/// fr: 'Toujours sans réponse. Réessayez un peu plus tard.'
	String get reessaisEpuises => 'Toujours sans réponse. Réessayez un peu plus tard.';

	/// fr: 'Rewayah a besoin d'Internet pour vérifier votre compte. Reconnectez cet appareil, puis réessayez.'
	String get horsLigneDemarrage => 'Rewayah a besoin d\'Internet pour vérifier votre compte. Reconnectez cet appareil, puis réessayez.';

	late final Traductions$commun$etats$actions$fr actions = Traductions$commun$etats$actions$fr.internal(_root);
}

// Path: commun.entete
class Traductions$commun$entete$fr {
	Traductions$commun$entete$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Retour'
	String get retour => 'Retour';

	/// fr: 'Notifications'
	String get notifications => 'Notifications';

	/// fr: 'Notifications, une non lue'
	String get notificationsUneNonLue => 'Notifications, une non lue';

	/// fr: 'Notifications, {nombre} non lues'
	String notificationsNonLues({required Object nombre}) => 'Notifications, ${nombre} non lues';
}

// Path: commun.selecteurProfils
class Traductions$commun$selecteurProfils$fr {
	Traductions$commun$selecteurProfils$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: '{prenom}, {etat}'
	String etiquette({required Object prenom, required Object etat}) => '${prenom}, ${etat}';

	/// fr: 'Ajouter'
	String get ajouter => 'Ajouter';

	/// fr: 'Ajouter un profil élève'
	String get ajouterSemantique => 'Ajouter un profil élève';
}

// Path: commun.theme
class Traductions$commun$theme$fr {
	Traductions$commun$theme$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Apparence'
	String get groupe => 'Apparence';

	/// fr: 'Thème clair'
	String get clair => 'Thème clair';

	/// fr: 'Thème sombre'
	String get sombre => 'Thème sombre';
}

// Path: commun.demarrage
class Traductions$commun$demarrage$fr {
	Traductions$commun$demarrage$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Ouverture de Rewayah'
	String get ouverture => 'Ouverture de Rewayah';
}

// Path: commun.dates
class Traductions$commun$dates$fr {
	Traductions$commun$dates$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations
	List<String> get jours => [
		'Lundi',
		'Mardi',
		'Mercredi',
		'Jeudi',
		'Vendredi',
		'Samedi',
		'Dimanche',
	];
	List<String> get mois => [
		'janvier',
		'février',
		'mars',
		'avril',
		'mai',
		'juin',
		'juillet',
		'août',
		'septembre',
		'octobre',
		'novembre',
		'décembre',
	];

	/// fr: '{jour} {numero} {mois}'
	String jourDate({required Object jour, required Object numero, required Object mois}) => '${jour} ${numero} ${mois}';
}

// Path: connexion.feuilleAppareil
class Traductions$connexion$feuilleAppareil$fr {
	Traductions$connexion$feuilleAppareil$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Réservé aux tuteurs déjà inscrits. Cet écran donne à un élève de votre foyer son propre accès, sur sa tablette ou son téléphone, sans lui confier votre compte.'
	String get pourQui => 'Réservé aux tuteurs déjà inscrits. Cet écran donne à un élève de votre foyer son propre accès, sur sa tablette ou son téléphone, sans lui confier votre compte.';

	/// fr: 'Où trouver le code'
	String get etapesTitre => 'Où trouver le code';

	/// fr: 'Sur votre propre appareil, ouvrez Foyer et appareils.'
	String get etape1 => 'Sur votre propre appareil, ouvrez Foyer et appareils.';

	/// fr: 'Ouvrez le profil de l'élève, puis Ajouter un appareil.'
	String get etape2 => 'Ouvrez le profil de l\'élève, puis Ajouter un appareil.';

	/// fr: 'Un code de six caractères s'affiche. Il reste valable dix minutes.'
	String get etape3 => 'Un code de six caractères s\'affiche. Il reste valable dix minutes.';

	/// fr: 'Saisissez-le ici, sur l'appareil de l'élève.'
	String get etape4 => 'Saisissez-le ici, sur l\'appareil de l\'élève.';

	/// fr: 'Deux appareils au plus par élève. Au-delà, révoquez-en un depuis Foyer et appareils.'
	String get plafond => 'Deux appareils au plus par élève. Au-delà, révoquez-en un depuis Foyer et appareils.';

	/// fr: 'Saisir le code'
	String get saisir => 'Saisir le code';

	/// fr: 'Fermer'
	String get fermer => 'Fermer';
}

// Path: admin.tableau
class Traductions$admin$tableau$fr {
	Traductions$admin$tableau$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Centre de commande'
	String get titre => 'Centre de commande';

	/// fr: 'Dossiers à valider'
	String get dossiers => 'Dossiers à valider';

	/// fr: 'Foyers sans enseignant'
	String get foyers => 'Foyers sans enseignant';

	/// fr: 'Cahiers manquants'
	String get rapports => 'Cahiers manquants';

	/// fr: 'Incidents (24 h)'
	String get incidents => 'Incidents (24 h)';

	/// fr: 'Accès échus'
	String get comptes => 'Accès échus';

	/// fr: 'Demandes à trancher'
	String get demandes => 'Demandes à trancher';

	/// fr: 'Les compteurs n'ont pas pu être lus. Réessayez dans un instant.'
	String get compteursErreur => 'Les compteurs n\'ont pas pu être lus. Réessayez dans un instant.';

	/// fr: 'À traiter en premier'
	String get aTraiter => 'À traiter en premier';

	/// fr: 'Rien à traiter'
	String get aTraiterAucun => 'Rien à traiter';

	/// fr: 'Les dossiers déposés et les demandes des familles et des enseignants apparaîtront ici, le plus ancien en premier.'
	String get aTraiterAucunDetail => 'Les dossiers déposés et les demandes des familles et des enseignants apparaîtront ici, le plus ancien en premier.';

	/// fr: 'Les foyers sans enseignant s'attribuent depuis leur compteur. Les trois derniers se règlent ailleurs : ils n'ont pas encore d'écran d'action.'
	String get aTraiterPortee => 'Les foyers sans enseignant s\'attribuent depuis leur compteur. Les trois derniers se règlent ailleurs : ils n\'ont pas encore d\'écran d\'action.';

	/// fr: 'Outils'
	String get outils => 'Outils';

	/// fr: 'Comptes'
	String get outilsComptes => 'Comptes';

	/// fr: 'Toutes les personnes inscrites, celles qui attendent une décision en premier. Y compris celles qui n'ont pas encore déposé de pièce.'
	String get outilsComptesDetail => 'Toutes les personnes inscrites, celles qui attendent une décision en premier. Y compris celles qui n\'ont pas encore déposé de pièce.';

	/// fr: 'Accès des agents IA'
	String get outilsAccesAgents => 'Accès des agents IA';

	/// fr: 'Ouvrir un accès en lecture seule, borné dans le temps, sur le parcours d'une personne.'
	String get outilsAccesAgentsDetail => 'Ouvrir un accès en lecture seule, borné dans le temps, sur le parcours d\'une personne.';

	/// fr: 'La liste n'a pas pu être lue en entier. Les compteurs, eux, restent justes.'
	String get listeErreur => 'La liste n\'a pas pu être lue en entier. Les compteurs, eux, restent justes.';

	/// fr: 'Dossier d'identité de {prenom}'
	String ligneDossier({required Object prenom}) => 'Dossier d\'identité de ${prenom}';

	/// fr: 'Changement d'enseignant pour {prenom}'
	String ligneReaffectation({required Object prenom}) => 'Changement d\'enseignant pour ${prenom}';

	/// fr: 'Plafond d'élèves de {prenom}'
	String lignePlafond({required Object prenom}) => 'Plafond d\'élèves de ${prenom}';

	/// fr: 'Changement de règle pour {prenom}'
	String ligneRegle({required Object prenom}) => 'Changement de règle pour ${prenom}';

	/// fr: 'Déposé aujourd'hui'
	String get attenteAujourdhui => 'Déposé aujourd\'hui';

	/// fr: 'En attente depuis 1 jour'
	String get attenteUnJour => 'En attente depuis 1 jour';

	/// fr: 'En attente depuis {jours} jours'
	String attenteJours({required Object jours}) => 'En attente depuis ${jours} jours';
}

// Path: admin.demandes
class Traductions$admin$demandes$fr {
	Traductions$admin$demandes$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Demandes et règles'
	String get titre => 'Demandes et règles';

	/// fr: '1 demande en attente'
	String get restanteUne => '1 demande en attente';

	/// fr: '{n} demandes en attente'
	String restantes({required Object n}) => '${n} demandes en attente';

	/// fr: 'Aucune demande en attente'
	String get aucune => 'Aucune demande en attente';

	/// fr: 'Les demandes des familles, des élèves autonomes et des enseignants arrivent ici, la plus ancienne en premier.'
	String get aucuneDetail => 'Les demandes des familles, des élèves autonomes et des enseignants arrivent ici, la plus ancienne en premier.';

	/// fr: 'Demandée le {date}, par {role}'
	String faitePar({required Object date, required Object role}) => 'Demandée le ${date}, par ${role}';

	/// fr: 'un tuteur'
	String get roleGuardian => 'un tuteur';

	/// fr: 'un enseignant'
	String get roleTeacher => 'un enseignant';

	/// fr: 'un élève autonome'
	String get roleStudent => 'un élève autonome';

	/// fr: 'l'administration'
	String get roleAdmin => 'l\'administration';

	/// fr: 'un contrôleur'
	String get roleController => 'un contrôleur';

	/// fr: 'une partie au dossier'
	String get roleInconnu => 'une partie au dossier';

	/// fr: 'Ce qui est demandé'
	String get reclame => 'Ce qui est demandé';

	/// fr: 'Changer l'enseignant de {prenom}'
	String reclameReaffectation({required Object prenom}) => 'Changer l\'enseignant de ${prenom}';

	/// fr: 'Porter le plafond à {valeur} élèves'
	String reclamePlafond({required Object valeur}) => 'Porter le plafond à ${valeur} élèves';

	/// fr: 'Porter {regle} à {valeur} min'
	String reclameRegle({required Object regle, required Object valeur}) => 'Porter ${regle} à ${valeur} min';

	/// fr: 'Revoir {regle}'
	String reclameRegleSansValeur({required Object regle}) => 'Revoir ${regle}';

	/// fr: 'Motif invoqué'
	String get motifDemande => 'Motif invoqué';

	/// fr: 'Décision'
	String get verdict => 'Décision';

	/// fr: 'Accorder'
	String get accorder => 'Accorder';

	/// fr: 'Refuser'
	String get refuser => 'Refuser';

	/// fr: 'Ce qui motive ce refus, en une phrase'
	String get motif => 'Ce qui motive ce refus, en une phrase';

	/// fr: 'Un refus doit dire pourquoi : c'est la seule phrase que la partie recevra.'
	String get motifRequis => 'Un refus doit dire pourquoi : c\'est la seule phrase que la partie recevra.';

	/// fr: 'Accorder applique l'effet en base : l'affectation se clôt, ou la règle se pose. Cet écran ne fait que rendre le verdict.'
	String get effet => 'Accorder applique l\'effet en base : l\'affectation se clôt, ou la règle se pose. Cet écran ne fait que rendre le verdict.';

	/// fr: 'Chaque décision et chaque règle posée sont inscrites au journal d'audit, avec votre nom.'
	String get journalisation => 'Chaque décision et chaque règle posée sont inscrites au journal d\'audit, avec votre nom.';

	/// fr: 'Les règles de {prenom}'
	String feuille({required Object prenom}) => 'Les règles de ${prenom}';

	/// fr: 'La valeur de la plateforme et celle qui s'applique, côte à côte. Une règle se change ici sans qu'une demande existe.'
	String get feuilleIntro => 'La valeur de la plateforme et celle qui s\'applique, côte à côte. Une règle se change ici sans qu\'une demande existe.';

	/// fr: 'Durée d'une séance'
	String get regleDuree => 'Durée d\'une séance';

	/// fr: 'Durée minimale payable'
	String get regleMinimum => 'Durée minimale payable';

	/// fr: 'Pause entre deux cours'
	String get reglePause => 'Pause entre deux cours';

	/// fr: 'Plafond d'élèves'
	String get reglePlafond => 'Plafond d\'élèves';

	/// fr: 'Règle non reconnue'
	String get regleInconnue => 'Règle non reconnue';

	/// fr: 'Plateforme : {valeur}'
	String plateforme({required Object valeur}) => 'Plateforme : ${valeur}';

	/// fr: 'Appliquée : {valeur}'
	String effective({required Object valeur}) => 'Appliquée : ${valeur}';

	/// fr: '{valeur} min'
	String minutes({required Object valeur}) => '${valeur} min';

	/// fr: '{valeur} élèves'
	String eleves({required Object valeur}) => '${valeur} élèves';

	/// fr: 'Posée le {date} : {motif}'
	String surchargeDepuis({required Object date, required Object motif}) => 'Posée le ${date} : ${motif}';

	/// fr: 'Cet élève suit la règle de la plateforme.'
	String get sansSurcharge => 'Cet élève suit la règle de la plateforme.';

	/// fr: 'Changer'
	String get changer => 'Changer';

	/// fr: 'Revenir à la règle de la plateforme'
	String get clore => 'Revenir à la règle de la plateforme';

	/// fr: 'Surcharges closes'
	String get historique => 'Surcharges closes';

	/// fr: '{valeur}, du {debut} au {fin}'
	String historiqueLigne({required Object valeur, required Object debut, required Object fin}) => '${valeur}, du ${debut} au ${fin}';

	/// fr: 'Posée : {motif}. Close : {cloture}.'
	String historiqueMotifs({required Object motif, required Object cloture}) => 'Posée : ${motif}. Close : ${cloture}.';

	/// fr: '{regle}, pour {prenom}'
	String poserTitre({required Object regle, required Object prenom}) => '${regle}, pour ${prenom}';

	/// fr: 'Clore la surcharge de {prenom}'
	String cloreTitre({required Object prenom}) => 'Clore la surcharge de ${prenom}';

	/// fr: 'Pourquoi ce changement ?'
	String get poserMotif => 'Pourquoi ce changement ?';

	/// fr: 'Une règle sans motif ne se relit pas six mois plus tard.'
	String get poserMotifRequis => 'Une règle sans motif ne se relit pas six mois plus tard.';

	/// fr: 'Poser la règle'
	String get poserEnvoyer => 'Poser la règle';

	/// fr: 'Clore la surcharge'
	String get cloreEnvoyer => 'Clore la surcharge';

	/// fr: 'L'opération n'a pas abouti : {message}'
	String erreur({required Object message}) => 'L\'opération n\'a pas abouti : ${message}';
}

// Path: admin.attribution
class Traductions$admin$attribution$fr {
	Traductions$admin$attribution$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Attribution'
	String get titre => 'Attribution';

	/// fr: 'Quand aucun enseignant n'a pris un enfant, c'est ici qu'on lui en donne un.'
	String get intro => 'Quand aucun enseignant n\'a pris un enfant, c\'est ici qu\'on lui en donne un.';

	/// fr: 'Élèves sans enseignant'
	String get colonneEleves => 'Élèves sans enseignant';

	/// fr: 'Enseignants'
	String get colonneEnseignants => 'Enseignants';

	/// fr: 'Chaque élève a son enseignant'
	String get aucunEleve => 'Chaque élève a son enseignant';

	/// fr: 'Les enfants que personne n'a encore pris apparaîtront ici, celui qui attend depuis le plus longtemps en premier.'
	String get aucunEleveDetail => 'Les enfants que personne n\'a encore pris apparaîtront ici, celui qui attend depuis le plus longtemps en premier.';

	/// fr: 'La file n'a pas pu être lue. Réessayez dans un instant.'
	String get erreurEleves => 'La file n\'a pas pu être lue. Réessayez dans un instant.';

	/// fr: 'Les enseignants n'ont pas pu être lus. Réessayez dans un instant.'
	String get erreurEnseignants => 'Les enseignants n\'ont pas pu être lus. Réessayez dans un instant.';

	/// fr: 'Inscrit aujourd'hui'
	String get attendAujourdhui => 'Inscrit aujourd\'hui';

	/// fr: 'Attend depuis 1 jour'
	String get attendUnJour => 'Attend depuis 1 jour';

	/// fr: 'Attend depuis {jours} jours'
	String attendJours({required Object jours}) => 'Attend depuis ${jours} jours';

	/// fr: 'Niveau {niveau}'
	String niveau({required Object niveau}) => 'Niveau ${niveau}';

	/// fr: '{nombre} heures proposées'
	String heuresProposees({required Object nombre}) => '${nombre} heures proposées';

	/// fr: '1 heure proposée'
	String get heureProposee => '1 heure proposée';

	/// fr: 'Aucune heure proposée'
	String get sansHeure => 'Aucune heure proposée';

	/// fr: 'Tant que la famille n'a posé aucun créneau, personne ne peut lui donner d'enseignant, pas même vous. Le geste est chez elle, sur ses disponibilités.'
	String get sansHeureDetail => 'Tant que la famille n\'a posé aucun créneau, personne ne peut lui donner d\'enseignant, pas même vous. Le geste est chez elle, sur ses disponibilités.';

	/// fr: 'Choisir un autre élève'
	String get changerEleve => 'Choisir un autre élève';

	/// fr: 'Choisissez un élève'
	String get choisirEleve => 'Choisissez un élève';

	/// fr: 'Les enseignants s'afficheront ici, ceux qui partagent une heure avec lui en premier.'
	String get choisirEleveDetail => 'Les enseignants s\'afficheront ici, ceux qui partagent une heure avec lui en premier.';

	/// fr: '{actifs} élèves sur {plafond}'
	String charge({required Object actifs, required Object plafond}) => '${actifs} élèves sur ${plafond}';

	/// fr: 'Plafond atteint'
	String get complet => 'Plafond atteint';

	/// fr: 'Libre {jour} à {heure} h'
	String libreSur({required Object jour, required Object heure}) => 'Libre ${jour} à ${heure} h';

	/// fr: 'Libre sur {nombre} des heures proposées'
	String libreSurPlusieurs({required Object nombre}) => 'Libre sur ${nombre} des heures proposées';

	/// fr: 'Aucune heure commune'
	String get sansHeureCommune => 'Aucune heure commune';

	/// fr: 'Sur quelle heure ?'
	String get quelleHeure => 'Sur quelle heure ?';

	/// fr: '{jour} à {heure} h'
	String creneau({required Object jour, required Object heure}) => '${jour} à ${heure} h';

	/// fr: 'Pourquoi passer outre ?'
	String get motif => 'Pourquoi passer outre ?';

	/// fr: '{prenom} n'a pas posé cette heure. L'attribuer quand même peut se justifier, et cela s'inscrit au journal.'
	String motifRequis({required Object prenom}) => '${prenom} n\'a pas posé cette heure. L\'attribuer quand même peut se justifier, et cela s\'inscrit au journal.';

	/// fr: 'Attribuer {eleve} à {enseignant}'
	String attribuer({required Object eleve, required Object enseignant}) => 'Attribuer ${eleve} à ${enseignant}';

	/// fr: 'Chaque attribution est journalisée : qui a décidé, quand, sur quelle heure, et le motif s'il a fallu passer outre.'
	String get journalisation => 'Chaque attribution est journalisée : qui a décidé, quand, sur quelle heure, et le motif s\'il a fallu passer outre.';

	/// fr: 'L'élève quitte cette file et ses cours sont posés au calendrier tout de suite.'
	String get effet => 'L\'élève quitte cette file et ses cours sont posés au calendrier tout de suite.';

	/// fr: 'L'attribution n'a pas abouti : {message}'
	String erreur({required Object message}) => 'L\'attribution n\'a pas abouti : ${message}';
}

// Path: admin.groupes
class Traductions$admin$groupes$fr {
	Traductions$admin$groupes$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Groupes'
	String get titre => 'Groupes';

	/// fr: 'Chaque groupe réunit un enseignant et ses élèves autour d'un créneau commun : c'est là que se donne le cours.'
	String get intro => 'Chaque groupe réunit un enseignant et ses élèves autour d\'un créneau commun : c\'est là que se donne le cours.';

	/// fr: 'Groupe'
	String get colonneGroupe => 'Groupe';

	/// fr: 'Enseignant'
	String get colonneEnseignant => 'Enseignant';

	/// fr: 'Public'
	String get colonneType => 'Public';

	/// fr: 'Membres'
	String get colonneMembres => 'Membres';

	/// fr: 'Créneau'
	String get colonneCreneau => 'Créneau';

	/// fr: 'État'
	String get colonneEtat => 'État';

	/// fr: 'Enfants'
	String get typeEnfant => 'Enfants';

	/// fr: 'Adultes'
	String get typeAdulte => 'Adultes';

	/// fr: 'Tous les publics'
	String get filtreTousTypes => 'Tous les publics';

	/// fr: 'Actif'
	String get etatActif => 'Actif';

	/// fr: 'Clôturé'
	String get etatCloture => 'Clôturé';

	/// fr: '{actifs} / {seuil}'
	String membresSur({required Object actifs, required Object seuil}) => '${actifs} / ${seuil}';

	/// fr: 'Aucun groupe créé'
	String get aucun => 'Aucun groupe créé';

	/// fr: 'Créez un premier groupe pour donner un enseignant et des élèves à un créneau commun.'
	String get aucunDetail => 'Créez un premier groupe pour donner un enseignant et des élèves à un créneau commun.';

	/// fr: 'Aucun groupe avec ce filtre'
	String get aucunAvecCeFiltre => 'Aucun groupe avec ce filtre';

	/// fr: 'Changez de filtre pour voir les autres groupes.'
	String get aucunAvecCeFiltreDetail => 'Changez de filtre pour voir les autres groupes.';

	/// fr: 'Les groupes n'ont pas pu être lus. Réessayez dans un instant.'
	String get erreur => 'Les groupes n\'ont pas pu être lus. Réessayez dans un instant.';

	/// fr: 'Créer un groupe'
	String get creer => 'Créer un groupe';

	/// fr: 'Créer un groupe'
	String get creerTitre => 'Créer un groupe';

	/// fr: 'Nom du groupe'
	String get champLibelle => 'Nom du groupe';

	/// fr: 'Identifiant de l'enseignant'
	String get champEnseignantId => 'Identifiant de l\'enseignant';

	/// fr: 'Public'
	String get champType => 'Public';

	/// fr: 'Jour'
	String get champJour => 'Jour';

	/// fr: 'Heure (0-23)'
	String get champHeure => 'Heure (0-23)';

	/// fr: 'Seuil maximal'
	String get champSeuil => 'Seuil maximal';

	/// fr: 'Créer le groupe'
	String get creerEnvoyer => 'Créer le groupe';

	/// fr: 'La création n'a pas abouti : {message}'
	String creerErreur({required Object message}) => 'La création n\'a pas abouti : ${message}';

	/// fr: 'Groupe {libelle}'
	String detailTitre({required Object libelle}) => 'Groupe ${libelle}';

	/// fr: 'Membres'
	String get detailMembres => 'Membres';

	/// fr: 'Aucun élève dans ce groupe pour l'instant.'
	String get detailAucunMembre => 'Aucun élève dans ce groupe pour l\'instant.';

	/// fr: 'Ajouter un élève'
	String get actionAjouter => 'Ajouter un élève';

	/// fr: 'Retirer'
	String get actionRetirer => 'Retirer';

	/// fr: 'Modifier le seuil'
	String get actionModifierSeuil => 'Modifier le seuil';

	/// fr: 'Réglages d'observation'
	String get actionObservation => 'Réglages d\'observation';

	/// fr: 'Clôturer le groupe'
	String get actionCloturer => 'Clôturer le groupe';

	/// fr: 'Ajouter un élève à {libelle}'
	String ajouterTitre({required Object libelle}) => 'Ajouter un élève à ${libelle}';

	/// fr: 'Identifiant de l'élève'
	String get champEleveId => 'Identifiant de l\'élève';

	/// fr: 'Motif'
	String get champMotif => 'Motif';

	/// fr: 'Un motif est requis, il s'inscrit au journal d'audit.'
	String get motifRequis => 'Un motif est requis, il s\'inscrit au journal d\'audit.';

	/// fr: 'Ajouter'
	String get ajouterEnvoyer => 'Ajouter';

	/// fr: 'L'ajout n'a pas abouti : {message}'
	String ajouterErreur({required Object message}) => 'L\'ajout n\'a pas abouti : ${message}';

	/// fr: 'Retirer {prenom} de {libelle}'
	String retirerTitre({required Object prenom, required Object libelle}) => 'Retirer ${prenom} de ${libelle}';

	/// fr: 'Retirer'
	String get retirerEnvoyer => 'Retirer';

	/// fr: 'Le retrait n'a pas abouti : {message}'
	String retirerErreur({required Object message}) => 'Le retrait n\'a pas abouti : ${message}';

	/// fr: 'Seuil maximal de {libelle}'
	String modifierSeuilTitre({required Object libelle}) => 'Seuil maximal de ${libelle}';

	/// fr: 'Enregistrer'
	String get modifierSeuilEnvoyer => 'Enregistrer';

	/// fr: 'La modification n'a pas abouti : {message}'
	String modifierSeuilErreur({required Object message}) => 'La modification n\'a pas abouti : ${message}';

	/// fr: 'Clôturer {libelle}'
	String cloturerTitre({required Object libelle}) => 'Clôturer ${libelle}';

	/// fr: 'Tous les membres actifs seront retirés du groupe. Cette action ne peut pas être annulée.'
	String get cloturerDetail => 'Tous les membres actifs seront retirés du groupe. Cette action ne peut pas être annulée.';

	/// fr: 'Clôturer'
	String get cloturerEnvoyer => 'Clôturer';

	/// fr: 'La clôture n'a pas abouti : {message}'
	String cloturerErreur({required Object message}) => 'La clôture n\'a pas abouti : ${message}';

	/// fr: 'Chaque création, ajout, retrait et clôture est inscrit au journal d'audit.'
	String get journalisation => 'Chaque création, ajout, retrait et clôture est inscrit au journal d\'audit.';

	/// fr: 'Observation : {libelle}'
	String observationTitre({required Object libelle}) => 'Observation : ${libelle}';

	/// fr: 'Le réglage n'a pas pu être enregistré.'
	String get observationErreur => 'Le réglage n\'a pas pu être enregistré.';

	/// fr: 'Cette installation n'a pas encore la mise à jour serveur que ce réglage demande (migration 0036). Réessayer n'y changera rien : elle doit d'abord être appliquée à la base.'
	String get observationCapaciteAbsente => 'Cette installation n\'a pas encore la mise à jour serveur que ce réglage demande (migration 0036). Réessayer n\'y changera rien : elle doit d\'abord être appliquée à la base.';
}

// Path: admin.diagnostics
class Traductions$admin$diagnostics$fr {
	Traductions$admin$diagnostics$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Diagnostics'
	String get titre => 'Diagnostics';

	/// fr: 'Chaque élève inscrit attend un premier niveau avant de rejoindre un groupe : c'est ici que ce placement se décide.'
	String get intro => 'Chaque élève inscrit attend un premier niveau avant de rejoindre un groupe : c\'est ici que ce placement se décide.';

	/// fr: 'Aucun programme publié'
	String get aucunProgramme => 'Aucun programme publié';

	/// fr: 'Publiez une première version du programme (Pédagogie > Programmes) avant de pouvoir décider un placement.'
	String get aucunProgrammeDetail => 'Publiez une première version du programme (Pédagogie > Programmes) avant de pouvoir décider un placement.';

	/// fr: 'La file n'a pas pu être lue. Réessayez dans un instant.'
	String get erreur => 'La file n\'a pas pu être lue. Réessayez dans un instant.';

	/// fr: '{n} élèves restants'
	String restants({required Object n}) => '${n} élèves restants';

	/// fr: '1 élève restant'
	String get restantUn => '1 élève restant';

	/// fr: 'Inscrit aujourd'hui'
	String get inscritAujourdhui => 'Inscrit aujourd\'hui';

	/// fr: 'Inscrit depuis 1 jour'
	String get inscritDepuisUnJour => 'Inscrit depuis 1 jour';

	/// fr: 'Inscrit depuis {jours} jours'
	String inscritDepuis({required Object jours}) => 'Inscrit depuis ${jours} jours';

	/// fr: 'Aucun élève à diagnostiquer'
	String get aucun => 'Aucun élève à diagnostiquer';

	/// fr: 'Tous les élèves inscrits ont déjà un niveau décidé.'
	String get aucunDetail => 'Tous les élèves inscrits ont déjà un niveau décidé.';

	/// fr: 'Niveau de placement'
	String get champNiveau => 'Niveau de placement';

	/// fr: 'Motif'
	String get champMotif => 'Motif';

	/// fr: 'Un motif est requis, il s'inscrit au journal d'audit.'
	String get motifRequis => 'Un motif est requis, il s\'inscrit au journal d\'audit.';

	/// fr: 'Décider le placement'
	String get decider => 'Décider le placement';

	/// fr: 'La décision n'a pas abouti : {message}'
	String deciderErreur({required Object message}) => 'La décision n\'a pas abouti : ${message}';

	/// fr: 'Chaque placement décidé est inscrit au journal d'audit.'
	String get journalisation => 'Chaque placement décidé est inscrit au journal d\'audit.';
}

// Path: admin.qualite
class Traductions$admin$qualite$fr {
	Traductions$admin$qualite$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Qualité'
	String get titre => 'Qualité';

	/// fr: 'Les anomalies pédagogiques détectées : rapports manquants, blocages sans suivi, évaluations en retard.'
	String get intro => 'Les anomalies pédagogiques détectées : rapports manquants, blocages sans suivi, évaluations en retard.';

	/// fr: 'Les anomalies n'ont pas pu être lues. Réessayez dans un instant.'
	String get erreur => 'Les anomalies n\'ont pas pu être lues. Réessayez dans un instant.';

	/// fr: 'Aucune anomalie détectée'
	String get aucune => 'Aucune anomalie détectée';

	/// fr: 'Tout est à jour : rapports rédigés, blocages suivis, évaluations à l'heure.'
	String get aucuneDetail => 'Tout est à jour : rapports rédigés, blocages suivis, évaluations à l\'heure.';

	/// fr: 'Toutes'
	String get filtreToutes => 'Toutes';

	/// fr: 'Ouvertes'
	String get filtreOuvertes => 'Ouvertes';

	/// fr: 'Traitées'
	String get filtreTraitees => 'Traitées';

	/// fr: 'Rapports de séance manquants'
	String get groupeRapportManquant => 'Rapports de séance manquants';

	/// fr: 'Blocages sans suivi'
	String get groupeBlocageSansSuivi => 'Blocages sans suivi';

	/// fr: 'Évaluations en retard'
	String get groupeEvaluationEnRetard => 'Évaluations en retard';

	/// fr: 'Concerne'
	String get colonnePersonne => 'Concerne';

	/// fr: 'Depuis'
	String get colonneDepuis => 'Depuis';

	/// fr: 'Statut'
	String get colonneStatut => 'Statut';

	/// fr: 'Ouverte'
	String get statutOuvert => 'Ouverte';

	/// fr: 'Traitée'
	String get statutTraite => 'Traitée';

	/// fr: 'Aujourd'hui'
	String get depuisAujourdhui => 'Aujourd\'hui';

	/// fr: '1 jour'
	String get depuisUnJour => '1 jour';

	/// fr: '{jours} jours'
	String depuisJours({required Object jours}) => '${jours} jours';

	/// fr: 'Marquer traité'
	String get actionTraiter => 'Marquer traité';

	/// fr: 'Marquer traité : {personne}'
	String traiterTitre({required Object personne}) => 'Marquer traité : ${personne}';

	/// fr: 'Note (optionnelle)'
	String get champNote => 'Note (optionnelle)';

	/// fr: 'Marquer traité'
	String get traiterEnvoyer => 'Marquer traité';

	/// fr: 'Le traitement n'a pas abouti : {message}'
	String traiterErreur({required Object message}) => 'Le traitement n\'a pas abouti : ${message}';
}

// Path: admin.regles
class Traductions$admin$regles$fr {
	Traductions$admin$regles$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Règles'
	String get titre => 'Règles';

	/// fr: 'Les valeurs par défaut de toute la plateforme. Une exception pour un profil précis se pose depuis Opérations > Règles individuelles, jamais ici.'
	String get intro => 'Les valeurs par défaut de toute la plateforme. Une exception pour un profil précis se pose depuis Opérations > Règles individuelles, jamais ici.';

	/// fr: 'Les règles n'ont pas pu être lues. Réessayez dans un instant.'
	String get erreur => 'Les règles n\'ont pas pu être lues. Réessayez dans un instant.';

	/// fr: 'L'enregistrement n'a pas abouti : {message}'
	String erreurEcriture({required Object message}) => 'L\'enregistrement n\'a pas abouti : ${message}';

	/// fr: 'Entrez un nombre valide.'
	String get valeurInvalide => 'Entrez un nombre valide.';

	/// fr: 'Enregistrer'
	String get envoyer => 'Enregistrer';

	/// fr: 'Valeur'
	String get champValeur => 'Valeur';

	/// fr: 'Seuil d'absence'
	String get absenceSeuil => 'Seuil d\'absence';

	/// fr: 'Au-delà de ce nombre de minutes sans rejoindre la séance, l'élève est marqué absent.'
	String get absenceSeuilDetail => 'Au-delà de ce nombre de minutes sans rejoindre la séance, l\'élève est marqué absent.';

	/// fr: 'Durée de séance'
	String get dureeSeance => 'Durée de séance';

	/// fr: 'La durée par défaut d'une séance, avant toute exception individuelle.'
	String get dureeSeanceDetail => 'La durée par défaut d\'une séance, avant toute exception individuelle.';

	/// fr: 'Durée minimale payée'
	String get dureeMinimalePayee => 'Durée minimale payée';

	/// fr: 'En dessous de cette durée, une séance écourtée reste payée en entier.'
	String get dureeMinimalePayeeDetail => 'En dessous de cette durée, une séance écourtée reste payée en entier.';

	/// fr: 'Pause entre deux séances'
	String get pauseEntreSeances => 'Pause entre deux séances';

	/// fr: 'Le temps minimum laissé à un enseignant entre deux séances consécutives.'
	String get pauseEntreSeancesDetail => 'Le temps minimum laissé à un enseignant entre deux séances consécutives.';

	/// fr: 'Élèves par enseignant'
	String get elevesParEnseignant => 'Élèves par enseignant';

	/// fr: 'Le nombre maximal d'élèves qu'un enseignant peut suivre en parallèle.'
	String get elevesParEnseignantDetail => 'Le nombre maximal d\'élèves qu\'un enseignant peut suivre en parallèle.';

	/// fr: 'Horizon d'affectation'
	String get horizonAffectation => 'Horizon d\'affectation';

	/// fr: 'Le nombre de semaines à l'avance sur lesquelles l'affectation cherche un enseignant disponible.'
	String get horizonAffectationDetail => 'Le nombre de semaines à l\'avance sur lesquelles l\'affectation cherche un enseignant disponible.';

	/// fr: 'Âge minimum caméra automatique'
	String get ageCameraAuto => 'Âge minimum caméra automatique';

	/// fr: 'En dessous de cet âge, l'activation de la caméra reste soumise à l'accord du tuteur.'
	String get ageCameraAutoDetail => 'En dessous de cet âge, l\'activation de la caméra reste soumise à l\'accord du tuteur.';

	/// fr: 'Âge maximum interface enfant'
	String get ageInterfaceEnfant => 'Âge maximum interface enfant';

	/// fr: 'En dessous de cet âge, un profil bascule sur l'interface simplifiée à sa création.'
	String get ageInterfaceEnfantDetail => 'En dessous de cet âge, un profil bascule sur l\'interface simplifiée à sa création.';

	/// fr: 'Appareils par élève'
	String get appareilsParEleve => 'Appareils par élève';

	/// fr: 'Le nombre d'appareils qu'un élève peut avoir actifs en même temps.'
	String get appareilsParEleveDetail => 'Le nombre d\'appareils qu\'un élève peut avoir actifs en même temps.';

	/// fr: 'Séances simultanées par profil'
	String get seancesSimultanees => 'Séances simultanées par profil';

	/// fr: 'Le nombre de séances qu'un même profil peut suivre en même temps.'
	String get seancesSimultaneesDetail => 'Le nombre de séances qu\'un même profil peut suivre en même temps.';

	/// fr: '{n} min'
	String uniteMinutes({required Object n}) => '${n} min';

	/// fr: '{n} sem.'
	String uniteSemaines({required Object n}) => '${n} sem.';

	/// fr: '{n}'
	String uniteNombre({required Object n}) => '${n}';
}

// Path: admin.fonctionnalites
class Traductions$admin$fonctionnalites$fr {
	Traductions$admin$fonctionnalites$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Fonctionnalités'
	String get titre => 'Fonctionnalités';

	/// fr: 'Les fonctionnalités qui changent le comportement de toute la plateforme.'
	String get intro => 'Les fonctionnalités qui changent le comportement de toute la plateforme.';

	/// fr: 'Les fonctionnalités n'ont pas pu être lues. Réessayez dans un instant.'
	String get erreur => 'Les fonctionnalités n\'ont pas pu être lues. Réessayez dans un instant.';

	/// fr: 'L'enregistrement n'a pas abouti : {message}'
	String erreurEcriture({required Object message}) => 'L\'enregistrement n\'a pas abouti : ${message}';

	/// fr: 'Entrez un nombre valide.'
	String get valeurInvalide => 'Entrez un nombre valide.';

	/// fr: 'Enregistrer'
	String get envoyer => 'Enregistrer';

	/// fr: 'Valeur'
	String get champValeur => 'Valeur';

	/// fr: 'Séances multi-participants'
	String get multiParticipants => 'Séances multi-participants';

	/// fr: 'Autorise plusieurs élèves dans une même séance de visioconférence.'
	String get multiParticipantsDetail => 'Autorise plusieurs élèves dans une même séance de visioconférence.';

	/// fr: 'Participants maximum'
	String get participantsMax => 'Participants maximum';

	/// fr: 'Le nombre de participants autorisés quand les séances multi-participants sont actives.'
	String get participantsMaxDetail => 'Le nombre de participants autorisés quand les séances multi-participants sont actives.';

	/// fr: '{n}'
	String uniteNombre({required Object n}) => '${n}';
}

// Path: admin.conservationDonnees
class Traductions$admin$conservationDonnees$fr {
	Traductions$admin$conservationDonnees$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Conservation des données'
	String get titre => 'Conservation des données';

	/// fr: 'Depuis combien de temps ces éléments restent accessibles avant leur suppression automatique.'
	String get intro => 'Depuis combien de temps ces éléments restent accessibles avant leur suppression automatique.';

	/// fr: 'Les délais de conservation n'ont pas pu être lus. Réessayez dans un instant.'
	String get erreur => 'Les délais de conservation n\'ont pas pu être lus. Réessayez dans un instant.';

	/// fr: 'L'enregistrement n'a pas abouti : {message}'
	String erreurEcriture({required Object message}) => 'L\'enregistrement n\'a pas abouti : ${message}';

	/// fr: 'Entrez un nombre valide.'
	String get valeurInvalide => 'Entrez un nombre valide.';

	/// fr: 'Enregistrer'
	String get envoyer => 'Enregistrer';

	/// fr: 'Valeur'
	String get champValeur => 'Valeur';

	/// fr: 'Enregistrements de séance'
	String get enregistrements => 'Enregistrements de séance';

	/// fr: 'Le nombre de jours pendant lesquels un enregistrement de séance reste accessible.'
	String get enregistrementsDetail => 'Le nombre de jours pendant lesquels un enregistrement de séance reste accessible.';

	/// fr: 'Documents d'identité'
	String get documentsIdentite => 'Documents d\'identité';

	/// fr: 'Le nombre de jours pendant lesquels un document d'identité déposé reste accessible avant sa purge.'
	String get documentsIdentiteDetail => 'Le nombre de jours pendant lesquels un document d\'identité déposé reste accessible avant sa purge.';

	/// fr: '{n} j'
	String uniteJours({required Object n}) => '${n} j';
}

// Path: admin.evaluations
class Traductions$admin$evaluations$fr {
	Traductions$admin$evaluations$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Évaluations'
	String get titre => 'Évaluations';

	/// fr: 'Ce qui est prévu, ce qui a été passé, et les certifications obtenues.'
	String get intro => 'Ce qui est prévu, ce qui a été passé, et les certifications obtenues.';

	/// fr: 'Les évaluations n'ont pas pu être lues. Réessayez dans un instant.'
	String get erreur => 'Les évaluations n\'ont pas pu être lues. Réessayez dans un instant.';

	/// fr: 'Aucune évaluation'
	String get aucune => 'Aucune évaluation';

	/// fr: 'Planifiez une première évaluation pour un élève déjà diagnostiqué.'
	String get aucuneDetail => 'Planifiez une première évaluation pour un élève déjà diagnostiqué.';

	/// fr: 'Aucune évaluation avec ce filtre'
	String get aucuneAvecCeFiltre => 'Aucune évaluation avec ce filtre';

	/// fr: 'Changez de filtre pour voir les autres évaluations.'
	String get aucuneAvecCeFiltreDetail => 'Changez de filtre pour voir les autres évaluations.';

	/// fr: 'Toutes'
	String get filtreToutes => 'Toutes';

	/// fr: 'Planifiées'
	String get filtrePlanifiees => 'Planifiées';

	/// fr: 'Réalisées'
	String get filtreRealisees => 'Réalisées';

	/// fr: 'Annulées'
	String get filtreAnnulees => 'Annulées';

	/// fr: 'Certifications'
	String get filtreCertifications => 'Certifications';

	/// fr: 'Élève'
	String get colonneEleve => 'Élève';

	/// fr: 'Niveau'
	String get colonneNiveau => 'Niveau';

	/// fr: 'Type'
	String get colonneType => 'Type';

	/// fr: 'Prévue le'
	String get colonneDatePrevue => 'Prévue le';

	/// fr: 'Statut'
	String get colonneStatut => 'Statut';

	/// fr: 'Résultat'
	String get colonneResultat => 'Résultat';

	/// fr: 'Initiale'
	String get typeInitiale => 'Initiale';

	/// fr: 'Périodique'
	String get typePeriodique => 'Périodique';

	/// fr: 'Réévaluation'
	String get typeReevaluation => 'Réévaluation';

	/// fr: 'Certification'
	String get typeCertification => 'Certification';

	/// fr: 'Planifiée'
	String get statutPlanifiee => 'Planifiée';

	/// fr: 'Réalisée'
	String get statutRealisee => 'Réalisée';

	/// fr: 'Annulée'
	String get statutAnnulee => 'Annulée';

	/// fr: 'Réussi'
	String get resultatReussi => 'Réussi';

	/// fr: 'Échec'
	String get resultatEchec => 'Échec';

	/// fr: 'À revoir'
	String get resultatARevoir => 'À revoir';

	/// fr: 'Planifier une évaluation'
	String get planifier => 'Planifier une évaluation';

	/// fr: 'Planifier une évaluation'
	String get planifierTitre => 'Planifier une évaluation';

	/// fr: 'Identifiant de l'élève'
	String get champEleveId => 'Identifiant de l\'élève';

	/// fr: 'Niveau évalué'
	String get champNiveau => 'Niveau évalué';

	/// fr: 'Type'
	String get champType => 'Type';

	/// fr: 'Date prévue (JJ/MM/AAAA)'
	String get champDatePrevue => 'Date prévue (JJ/MM/AAAA)';

	/// fr: 'Planifier'
	String get planifierEnvoyer => 'Planifier';

	/// fr: 'La planification n'a pas abouti : {message}'
	String planifierErreur({required Object message}) => 'La planification n\'a pas abouti : ${message}';

	/// fr: 'Enregistrer le résultat'
	String get actionEnregistrerResultat => 'Enregistrer le résultat';

	/// fr: 'Annuler l'évaluation'
	String get actionAnnuler => 'Annuler l\'évaluation';

	/// fr: 'Résultat de {eleve}'
	String resultatTitre({required Object eleve}) => 'Résultat de ${eleve}';

	/// fr: 'Notes (optionnelles)'
	String get champNotes => 'Notes (optionnelles)';

	/// fr: 'Enregistrer'
	String get resultatEnvoyer => 'Enregistrer';

	/// fr: 'L'enregistrement n'a pas abouti : {message}'
	String resultatErreur({required Object message}) => 'L\'enregistrement n\'a pas abouti : ${message}';

	/// fr: 'Annuler l'évaluation de {eleve}'
	String annulerTitre({required Object eleve}) => 'Annuler l\'évaluation de ${eleve}';

	/// fr: 'Annuler'
	String get annulerEnvoyer => 'Annuler';

	/// fr: 'L'annulation n'a pas abouti : {message}'
	String annulerErreur({required Object message}) => 'L\'annulation n\'a pas abouti : ${message}';

	/// fr: 'Motif'
	String get champMotif => 'Motif';

	/// fr: 'Un motif est requis, il s'inscrit au journal d'audit.'
	String get motifRequis => 'Un motif est requis, il s\'inscrit au journal d\'audit.';

	/// fr: 'Chaque planification, résultat et annulation est inscrit au journal d'audit.'
	String get journalisation => 'Chaque planification, résultat et annulation est inscrit au journal d\'audit.';
}

// Path: admin.progression
class Traductions$admin$progression$fr {
	Traductions$admin$progression$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Progression'
	String get titre => 'Progression';

	/// fr: 'Le niveau courant de chaque élève, son groupe, et les blocages ou dérogations en cours.'
	String get intro => 'Le niveau courant de chaque élève, son groupe, et les blocages ou dérogations en cours.';

	/// fr: 'La progression n'a pas pu être lue. Réessayez dans un instant.'
	String get erreur => 'La progression n\'a pas pu être lue. Réessayez dans un instant.';

	/// fr: 'Aucun élève actif'
	String get aucun => 'Aucun élève actif';

	/// fr: 'Les élèves apparaîtront ici dès leur premier diagnostic de placement.'
	String get aucunDetail => 'Les élèves apparaîtront ici dès leur premier diagnostic de placement.';

	/// fr: 'Élève'
	String get colonneEleve => 'Élève';

	/// fr: 'Groupe'
	String get colonneGroupe => 'Groupe';

	/// fr: 'Niveau'
	String get colonneNiveau => 'Niveau';

	/// fr: 'Depuis'
	String get colonneDepuis => 'Depuis';

	/// fr: 'Exception'
	String get colonneException => 'Exception';

	/// fr: 'Sans groupe'
	String get sansGroupe => 'Sans groupe';

	/// fr: 'Non diagnostiqué'
	String get sansNiveau => 'Non diagnostiqué';

	/// fr: 'Tous les cycles'
	String get filtreTousCycles => 'Tous les cycles';

	/// fr: 'Aujourd'hui'
	String get depuisAujourdhui => 'Aujourd\'hui';

	/// fr: '1 jour'
	String get depuisUnJour => '1 jour';

	/// fr: '{jours} jours'
	String depuisJours({required Object jours}) => '${jours} jours';

	/// fr: 'Blocage'
	String get typeBlocage => 'Blocage';

	/// fr: 'Dérogation'
	String get typeDerogation => 'Dérogation';

	/// fr: 'Poser un blocage'
	String get actionPoserBlocage => 'Poser un blocage';

	/// fr: 'Poser une dérogation'
	String get actionPoserDerogation => 'Poser une dérogation';

	/// fr: 'Clore l'exception'
	String get actionCloreException => 'Clore l\'exception';

	/// fr: 'Changer de niveau'
	String get actionPromouvoir => 'Changer de niveau';

	/// fr: '{type} pour {eleve}'
	String poserExceptionTitre({required Object type, required Object eleve}) => '${type} pour ${eleve}';

	/// fr: 'Poser l'exception'
	String get poserExceptionEnvoyer => 'Poser l\'exception';

	/// fr: 'La pose n'a pas abouti : {message}'
	String poserExceptionErreur({required Object message}) => 'La pose n\'a pas abouti : ${message}';

	/// fr: 'Clore l'exception de {eleve}'
	String clorerExceptionTitre({required Object eleve}) => 'Clore l\'exception de ${eleve}';

	/// fr: 'Clore'
	String get clorerExceptionEnvoyer => 'Clore';

	/// fr: 'La clôture n'a pas abouti : {message}'
	String clorerExceptionErreur({required Object message}) => 'La clôture n\'a pas abouti : ${message}';

	/// fr: 'Changer le niveau de {eleve}'
	String promouvoirTitre({required Object eleve}) => 'Changer le niveau de ${eleve}';

	/// fr: 'Nouveau niveau'
	String get promouvoirChampNiveau => 'Nouveau niveau';

	/// fr: 'Enregistrer'
	String get promouvoirEnvoyer => 'Enregistrer';

	/// fr: 'Le changement n'a pas abouti : {message}'
	String promouvoirErreur({required Object message}) => 'Le changement n\'a pas abouti : ${message}';

	/// fr: 'Motif'
	String get champMotif => 'Motif';

	/// fr: 'Un motif est requis, il s'inscrit au journal d'audit.'
	String get motifRequis => 'Un motif est requis, il s\'inscrit au journal d\'audit.';

	/// fr: 'Chaque exception posée, close, et chaque changement de niveau est inscrit au journal d'audit.'
	String get journalisation => 'Chaque exception posée, close, et chaque changement de niveau est inscrit au journal d\'audit.';
}

// Path: admin.programmes
class Traductions$admin$programmes$fr {
	Traductions$admin$programmes$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Programmes'
	String get titre => 'Programmes';

	/// fr: 'Le curriculum Rewayah, versionné : une version publiée ne peut plus être modifiée, toute évolution académique en crée une nouvelle.'
	String get intro => 'Le curriculum Rewayah, versionné : une version publiée ne peut plus être modifiée, toute évolution académique en crée une nouvelle.';

	/// fr: 'Aucune version de programme'
	String get aucuneVersion => 'Aucune version de programme';

	/// fr: 'Créez la première version, encore en brouillon, pour commencer à y ajouter des niveaux.'
	String get aucuneVersionDetail => 'Créez la première version, encore en brouillon, pour commencer à y ajouter des niveaux.';

	/// fr: 'Le programme n'a pas pu être lu. Réessayez dans un instant.'
	String get erreur => 'Le programme n\'a pas pu être lu. Réessayez dans un instant.';

	/// fr: 'Brouillon'
	String get statutBrouillon => 'Brouillon';

	/// fr: 'Publiée'
	String get statutPubliee => 'Publiée';

	/// fr: 'Archivée'
	String get statutArchivee => 'Archivée';

	/// fr: 'Version {numero}'
	String versionNumero({required Object numero}) => 'Version ${numero}';

	/// fr: '{nombre} niveaux'
	String niveauxSur({required Object nombre}) => '${nombre} niveaux';

	/// fr: 'Créer une version'
	String get creerVersion => 'Créer une version';

	/// fr: 'Créer une version vide'
	String get creerVersionVide => 'Créer une version vide';

	/// fr: 'Créer une nouvelle version à partir de celle-ci'
	String get creerVersionDepuisPubliee => 'Créer une nouvelle version à partir de celle-ci';

	/// fr: 'La création n'a pas abouti : {message}'
	String creerVersionErreur({required Object message}) => 'La création n\'a pas abouti : ${message}';

	/// fr: 'Niveaux'
	String get niveauxTitre => 'Niveaux';

	/// fr: 'Aucun niveau dans cette version'
	String get niveauAucun => 'Aucun niveau dans cette version';

	/// fr: 'Ajoutez un premier niveau pour commencer à composer cette version.'
	String get niveauAucunDetail => 'Ajoutez un premier niveau pour commencer à composer cette version.';

	/// fr: 'Code : {code}'
	String codeTechnique({required Object code}) => 'Code : ${code}';

	/// fr: 'Ajouter un niveau'
	String get ajouterNiveau => 'Ajouter un niveau';

	/// fr: 'Ajouter un niveau à {version}'
	String ajouterNiveauTitre({required Object version}) => 'Ajouter un niveau à ${version}';

	/// fr: 'Ajouter'
	String get ajouterNiveauEnvoyer => 'Ajouter';

	/// fr: 'L'ajout n'a pas abouti : {message}'
	String ajouterNiveauErreur({required Object message}) => 'L\'ajout n\'a pas abouti : ${message}';

	/// fr: 'Modifier'
	String get modifierNiveau => 'Modifier';

	/// fr: 'Modifier {nom}'
	String modifierNiveauTitre({required Object nom}) => 'Modifier ${nom}';

	/// fr: 'Enregistrer'
	String get modifierNiveauEnvoyer => 'Enregistrer';

	/// fr: 'La modification n'a pas abouti : {message}'
	String modifierNiveauErreur({required Object message}) => 'La modification n\'a pas abouti : ${message}';

	/// fr: 'Supprimer'
	String get supprimerNiveau => 'Supprimer';

	/// fr: 'Supprimer {nom}'
	String supprimerNiveauTitre({required Object nom}) => 'Supprimer ${nom}';

	/// fr: 'Supprimer'
	String get supprimerNiveauEnvoyer => 'Supprimer';

	/// fr: 'La suppression n'a pas abouti : {message}'
	String supprimerNiveauErreur({required Object message}) => 'La suppression n\'a pas abouti : ${message}';

	/// fr: 'Publier la version'
	String get publierVersion => 'Publier la version';

	/// fr: 'Publier {version}'
	String publierVersionTitre({required Object version}) => 'Publier ${version}';

	/// fr: 'Une fois publiée, cette version ne pourra plus être modifiée. Toute évolution académique en créera une nouvelle.'
	String get publierVersionDetail => 'Une fois publiée, cette version ne pourra plus être modifiée. Toute évolution académique en créera une nouvelle.';

	/// fr: 'Publier'
	String get publierVersionEnvoyer => 'Publier';

	/// fr: 'La publication n'a pas abouti : {message}'
	String publierVersionErreur({required Object message}) => 'La publication n\'a pas abouti : ${message}';

	/// fr: 'Code technique (usage interne, jamais affiché à l'élève)'
	String get champCodeTechnique => 'Code technique (usage interne, jamais affiché à l\'élève)';

	/// fr: 'Nom affiché'
	String get champNomHumain => 'Nom affiché';

	/// fr: 'Cycle'
	String get champCycle => 'Cycle';

	/// fr: 'Ordre'
	String get champOrdre => 'Ordre';

	/// fr: 'Description (optionnelle)'
	String get champDescription => 'Description (optionnelle)';

	/// fr: 'Motif'
	String get champMotif => 'Motif';

	/// fr: 'Un motif est requis, il s'inscrit au journal d'audit.'
	String get motifRequis => 'Un motif est requis, il s\'inscrit au journal d\'audit.';

	/// fr: 'Chaque création, modification, suppression et publication est inscrite au journal d'audit.'
	String get journalisation => 'Chaque création, modification, suppression et publication est inscrite au journal d\'audit.';
}

// Path: admin.journal
class Traductions$admin$journal$fr {
	Traductions$admin$journal$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Journal'
	String get titre => 'Journal';

	/// fr: 'Journal intact'
	String get chaineIntacte => 'Journal intact';

	/// fr: '{nombre} entrées relues une à une : aucune n'a été modifiée ni retirée depuis son écriture.'
	String chaineIntacteDetail({required Object nombre}) => '${nombre} entrées relues une à une : aucune n\'a été modifiée ni retirée depuis son écriture.';

	/// fr: 'Journal altéré'
	String get chaineRompue => 'Journal altéré';

	/// fr: 'Une entrée ne correspond plus à son empreinte, la n° {entree}. Quelque chose a touché la base en dehors de l'application.'
	String chaineRompueUne({required Object entree}) => 'Une entrée ne correspond plus à son empreinte, la n° ${entree}. Quelque chose a touché la base en dehors de l\'application.';

	/// fr: '{nombre} entrées ne correspondent plus à leur empreinte, à partir de la n° {entree}. Quelque chose a touché la base en dehors de l'application.'
	String chaineRompueDetail({required Object nombre, required Object entree}) => '${nombre} entrées ne correspondent plus à leur empreinte, à partir de la n° ${entree}. Quelque chose a touché la base en dehors de l\'application.';

	/// fr: 'Intégrité inconnue'
	String get chaineInconnue => 'Intégrité inconnue';

	/// fr: 'La vérification n'a pas abouti. Les entrées ci-dessous restent lisibles, mais rien ne garantit pour l'instant qu'elles sont complètes.'
	String get chaineInconnueDetail => 'La vérification n\'a pas abouti. Les entrées ci-dessous restent lisibles, mais rien ne garantit pour l\'instant qu\'elles sont complètes.';

	/// fr: 'Vérification'
	String get chaineEnCours => 'Vérification';

	/// fr: 'Relecture de l'empreinte de chaque entrée.'
	String get chaineEnCoursDetail => 'Relecture de l\'empreinte de chaque entrée.';

	/// fr: '7 derniers jours'
	String get periodeSemaine => '7 derniers jours';

	/// fr: '30 derniers jours'
	String get periodeMois => '30 derniers jours';

	/// fr: 'Depuis le début'
	String get periodeTout => 'Depuis le début';

	/// fr: 'Tous les événements'
	String get tousTypes => 'Tous les événements';

	/// fr: 'Tout le monde'
	String get tousActeurs => 'Tout le monde';

	/// fr: 'Quand'
	String get colonneQuand => 'Quand';

	/// fr: 'Qui'
	String get colonneQui => 'Qui';

	/// fr: 'À quel titre'
	String get colonneRole => 'À quel titre';

	/// fr: 'Ce qui a été fait'
	String get colonneQuoi => 'Ce qui a été fait';

	/// fr: 'Sur quoi'
	String get colonneCible => 'Sur quoi';

	/// fr: 'Détail'
	String get colonneDetail => 'Détail';

	/// fr: '{date} à {heure}'
	String horodatage({required Object date, required Object heure}) => '${date} à ${heure}';

	/// fr: 'Le système'
	String get acteurSysteme => 'Le système';

	/// fr: 'Compte supprimé'
	String get acteurInconnu => 'Compte supprimé';

	/// fr: 'Administration'
	String get roleAdmin => 'Administration';

	/// fr: 'Enseignant'
	String get roleEnseignant => 'Enseignant';

	/// fr: 'Tuteur'
	String get roleTuteur => 'Tuteur';

	/// fr: 'Élève'
	String get roleEleve => 'Élève';

	/// fr: 'Contrôleur'
	String get roleControleur => 'Contrôleur';

	/// fr: 'Comptable'
	String get roleComptable => 'Comptable';

	/// fr: 'Hors session'
	String get roleAucun => 'Hors session';

	/// fr: 'Dossier d'identité consulté'
	String get evtKycLu => 'Dossier d\'identité consulté';

	/// fr: 'Dossier d'identité tranché'
	String get evtKycTranche => 'Dossier d\'identité tranché';

	/// fr: 'Profil créé'
	String get evtProfilCree => 'Profil créé';

	/// fr: 'Profil enfant créé'
	String get evtProfilEnfantCree => 'Profil enfant créé';

	/// fr: 'Code d'appairage créé'
	String get evtCodeCree => 'Code d\'appairage créé';

	/// fr: 'Appareil appairé'
	String get evtAppareilAppaire => 'Appareil appairé';

	/// fr: 'Appareil révoqué'
	String get evtAppareilRevoque => 'Appareil révoqué';

	/// fr: 'Réglages pédagogiques modifiés'
	String get evtPedagogie => 'Réglages pédagogiques modifiés';

	/// fr: 'Élève pris par un enseignant'
	String get evtAffectationPrise => 'Élève pris par un enseignant';

	/// fr: 'Élève attribué par l'administration'
	String get evtAffectationAttribuee => 'Élève attribué par l\'administration';

	/// fr: 'Demande déposée'
	String get evtDemandeCreee => 'Demande déposée';

	/// fr: 'Demande tranchée'
	String get evtDemandeTranchee => 'Demande tranchée';

	/// fr: 'Règle posée'
	String get evtReglePosee => 'Règle posée';

	/// fr: 'Règle close'
	String get evtRegleClose => 'Règle close';

	/// fr: 'Événement'
	String get filtreEvenement => 'Événement';

	/// fr: 'Acteur'
	String get filtreActeur => 'Acteur';

	/// fr: 'Accès d'agent IA émis'
	String get evtAgentJetonEmis => 'Accès d\'agent IA émis';

	/// fr: 'Accès d'agent IA révoqué'
	String get evtAgentJetonRevoque => 'Accès d\'agent IA révoqué';

	/// fr: 'Session d'agent IA ouverte'
	String get evtAgentSessionOuverte => 'Session d\'agent IA ouverte';

	/// fr: 'Visite de contrôle commencée'
	String get evtObservationControleur => 'Visite de contrôle commencée';

	/// fr: 'Entrée en salle autorisée'
	String get evtJetonVideo => 'Entrée en salle autorisée';

	/// fr: 'Aucun événement enregistré'
	String get vide => 'Aucun événement enregistré';

	/// fr: 'Chaque lecture de dossier, chaque décision et chaque attribution viendra s'inscrire ici.'
	String get videDetail => 'Chaque lecture de dossier, chaque décision et chaque attribution viendra s\'inscrire ici.';

	/// fr: 'Aucun événement ne correspond'
	String get videFiltre => 'Aucun événement ne correspond';

	/// fr: 'Élargissez la période, ou relâchez un filtre.'
	String get videFiltreDetail => 'Élargissez la période, ou relâchez un filtre.';

	/// fr: 'Effacer les filtres'
	String get effacerFiltres => 'Effacer les filtres';

	/// fr: 'Le journal n'a pas pu être lu. Réessayez dans un instant.'
	String get erreur => 'Le journal n\'a pas pu être lu. Réessayez dans un instant.';

	/// fr: 'Les entrées plus anciennes n'ont pas pu être lues.'
	String get erreurSuite => 'Les entrées plus anciennes n\'ont pas pu être lues.';

	/// fr: 'Charger les entrées plus anciennes'
	String get chargerSuite => 'Charger les entrées plus anciennes';

	/// fr: 'Vous êtes remonté jusqu'à la première entrée du journal.'
	String get fin => 'Vous êtes remonté jusqu\'à la première entrée du journal.';

	late final Traductions$admin$journal$evenements$fr evenements = Traductions$admin$journal$evenements$fr.internal(_root);
}

// Path: admin.observations
class Traductions$admin$observations$fr {
	Traductions$admin$observations$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Observations'
	String get titre => 'Observations';
}

// Path: admin.comptes
class Traductions$admin$comptes$fr {
	Traductions$admin$comptes$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Comptes'
	String get titre => 'Comptes';

	/// fr: 'Toutes les personnes inscrites, celles qui attendent une décision en premier. Un compte sans pièce d'identité déposée reste visible ici : c'est le seul endroit qui le montre.'
	String get intro => 'Toutes les personnes inscrites, celles qui attendent une décision en premier. Un compte sans pièce d\'identité déposée reste visible ici : c\'est le seul endroit qui le montre.';

	/// fr: 'Une personne attend une décision, inscrite aujourd'hui.'
	String get attenteUneAujourdhui => 'Une personne attend une décision, inscrite aujourd\'hui.';

	/// fr: 'Une personne attend une décision depuis 1 jour.'
	String get attenteUneUnJour => 'Une personne attend une décision depuis 1 jour.';

	/// fr: 'Une personne attend une décision depuis {jours} jours.'
	String attenteUne({required Object jours}) => 'Une personne attend une décision depuis ${jours} jours.';

	/// fr: '{nombre} personnes attendent une décision.'
	String attentePlusieurs({required Object nombre}) => '${nombre} personnes attendent une décision.';

	/// fr: 'Tous'
	String get filtreTousEtats => 'Tous';

	/// fr: 'Tous les rôles'
	String get filtreTousRoles => 'Tous les rôles';

	/// fr: 'Rôle'
	String get filtreRole => 'Rôle';

	/// fr: 'Aucun compte avec ce filtre'
	String get aucunAvecCeFiltre => 'Aucun compte avec ce filtre';

	/// fr: 'Retirez un filtre pour élargir la liste.'
	String get aucunAvecCeFiltreDetail => 'Retirez un filtre pour élargir la liste.';

	/// fr: 'Les comptes n'ont pas pu être lus. Réessayez dans un instant.'
	String get erreur => 'Les comptes n\'ont pas pu être lus. Réessayez dans un instant.';

	/// fr: 'Personne'
	String get colonnePersonne => 'Personne';

	/// fr: 'Identifiant'
	String get colonneIdentifiant => 'Identifiant';

	/// fr: 'Rôle'
	String get colonneRole => 'Rôle';

	/// fr: 'État'
	String get colonneEtat => 'État';

	/// fr: 'Pièce d'identité'
	String get colonnePiece => 'Pièce d\'identité';

	/// fr: 'Inscrit depuis'
	String get colonneAttente => 'Inscrit depuis';

	/// fr: 'Contrats'
	String get colonneContrats => 'Contrats';

	/// fr: 'En attente'
	String get etatEnAttente => 'En attente';

	/// fr: 'Actif'
	String get etatActif => 'Actif';

	/// fr: 'Provisoire'
	String get etatProvisoire => 'Provisoire';

	/// fr: 'Suspendu'
	String get etatSuspendu => 'Suspendu';

	/// fr: 'État inconnu'
	String get etatInconnu => 'État inconnu';

	/// fr: 'Administration'
	String get roleAdmin => 'Administration';

	/// fr: 'Comptable'
	String get roleComptable => 'Comptable';

	/// fr: 'Contrôleur'
	String get roleControleur => 'Contrôleur';

	/// fr: 'Enseignant'
	String get roleEnseignant => 'Enseignant';

	/// fr: 'Tuteur'
	String get roleTuteur => 'Tuteur';

	/// fr: 'Élève'
	String get roleEleve => 'Élève';

	/// fr: 'Rôle inconnu'
	String get roleInconnu => 'Rôle inconnu';

	/// fr: 'Aucune pièce déposée'
	String get pieceAucune => 'Aucune pièce déposée';

	/// fr: 'À vérifier'
	String get pieceAVerifier => 'À vérifier';

	/// fr: 'Validée'
	String get pieceValidee => 'Validée';

	/// fr: 'Refusée'
	String get pieceRefusee => 'Refusée';

	/// fr: 'Hors de votre portée'
	String get pieceNonVisible => 'Hors de votre portée';

	/// fr: 'Aujourd'hui'
	String get attendAujourdhui => 'Aujourd\'hui';

	/// fr: '1 jour'
	String get attendUnJour => '1 jour';

	/// fr: '{jours} jours'
	String attendJours({required Object jours}) => '${jours} jours';
}

// Path: admin.agents
class Traductions$admin$agents$fr {
	Traductions$admin$agents$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Accès des agents IA'
	String get titre => 'Accès des agents IA';

	/// fr: 'Un jeton laisse un agent IA ouvrir l'application et lire ce qu'une personne y lit. Il ne peut rien écrire, rien annuler, rien modifier : la base le lui refuse, pas l'interface.'
	String get intro => 'Un jeton laisse un agent IA ouvrir l\'application et lire ce qu\'une personne y lit. Il ne peut rien écrire, rien annuler, rien modifier : la base le lui refuse, pas l\'interface.';

	/// fr: 'Émettre un jeton'
	String get emettre => 'Émettre un jeton';

	/// fr: 'À quoi sert ce jeton'
	String get libelle => 'À quoi sert ce jeton';

	/// fr: 'Obligatoire. Un jeton sans nom est un jeton que personne n'ose révoquer.'
	String get libelleAide => 'Obligatoire. Un jeton sans nom est un jeton que personne n\'ose révoquer.';

	/// fr: 'Relecture du suivi de Maryam'
	String get libelleExemple => 'Relecture du suivi de Maryam';

	/// fr: 'Qui l'agent observe'
	String get qui => 'Qui l\'agent observe';

	/// fr: 'L'agent verra exactement l'écran de cette personne, et son parcours sera le sien.'
	String get quiAide => 'L\'agent verra exactement l\'écran de cette personne, et son parcours sera le sien.';

	/// fr: 'Choisir une personne'
	String get quiVide => 'Choisir une personne';

	/// fr: 'Chercher un nom ou un identifiant'
	String get chercher => 'Chercher un nom ou un identifiant';

	/// fr: 'Pendant combien de temps'
	String get duree => 'Pendant combien de temps';

	/// fr: '{nombre} h'
	String dureeHeure({required Object nombre}) => '${nombre} h';

	/// fr: 'Vingt-quatre heures au maximum, et la base le vérifie elle-même.'
	String get dureePlafond => 'Vingt-quatre heures au maximum, et la base le vérifie elle-même.';

	/// fr: 'Les prénoms'
	String get identite => 'Les prénoms';

	/// fr: 'Masqués'
	String get identiteMasquee => 'Masqués';

	/// fr: 'L'agent lit les identifiants (ELV-0042) à la place des prénoms. La substitution est faite par la base : le prénom ne sort pas.'
	String get identiteMasqueeDetail => 'L\'agent lit les identifiants (ELV-0042) à la place des prénoms. La substitution est faite par la base : le prénom ne sort pas.';

	/// fr: 'Visibles'
	String get identiteVisible => 'Visibles';

	/// fr: 'L'agent lit les prénoms, comme la personne observée les voit.'
	String get identiteVisibleDetail => 'L\'agent lit les prénoms, comme la personne observée les voit.';

	/// fr: 'Pourra'
	String get pourra => 'Pourra';

	/// fr: 'Ouvrir l'application, naviguer, et lire tout ce que cette personne lit.'
	String get pourraDetail => 'Ouvrir l\'application, naviguer, et lire tout ce que cette personne lit.';

	/// fr: 'Ne pourra pas'
	String get nePourraPas => 'Ne pourra pas';

	/// fr: 'Écrire quoi que ce soit, voir une pièce d'identité, un appareil, le journal d'audit, ni sortir du périmètre de cette personne.'
	String get nePourraPasDetail => 'Écrire quoi que ce soit, voir une pièce d\'identité, un appareil, le journal d\'audit, ni sortir du périmètre de cette personne.';

	/// fr: 'Émission'
	String get emissionEnCours => 'Émission';

	/// fr: 'Jeton émis'
	String get emis => 'Jeton émis';

	/// fr: 'Remettez ce lien à l'agent. Il n'apparaîtra plus : ni cet écran ni la base ne peuvent le retrouver.'
	String get emisDetail => 'Remettez ce lien à l\'agent. Il n\'apparaîtra plus : ni cet écran ni la base ne peuvent le retrouver.';

	/// fr: 'Copier le lien'
	String get copier => 'Copier le lien';

	/// fr: 'Lien copié'
	String get copie => 'Lien copié';

	/// fr: 'J'ai copié le lien'
	String get termine => 'J\'ai copié le lien';

	/// fr: 'Le jeton n'a pas pu être émis. Réessayez dans un instant.'
	String get erreurEmission => 'Le jeton n\'a pas pu être émis. Réessayez dans un instant.';

	/// fr: 'Jeton'
	String get colonneLibelle => 'Jeton';

	/// fr: 'Observe'
	String get colonneQui => 'Observe';

	/// fr: 'Parcours'
	String get colonneParcours => 'Parcours';

	/// fr: 'Prénoms'
	String get colonneIdentite => 'Prénoms';

	/// fr: 'Jusqu'à'
	String get colonneExpire => 'Jusqu\'à';

	/// fr: 'Ouvertures'
	String get colonneUsage => 'Ouvertures';

	/// fr: 'État'
	String get colonneEtat => 'État';

	/// fr: 'Élève'
	String get parcoursEleve => 'Élève';

	/// fr: 'Tuteur'
	String get parcoursTuteur => 'Tuteur';

	/// fr: 'Enseignant'
	String get parcoursEnseignant => 'Enseignant';

	/// fr: 'Contrôle qualité'
	String get parcoursControleur => 'Contrôle qualité';

	/// fr: 'Administration'
	String get parcoursAdmin => 'Administration';

	/// fr: 'Comptable'
	String get parcoursComptable => 'Comptable';

	/// fr: 'Parcours inconnu'
	String get parcoursInconnu => 'Parcours inconnu';

	/// fr: 'Actif'
	String get etatActif => 'Actif';

	/// fr: 'Révoqué'
	String get etatRevoque => 'Révoqué';

	/// fr: 'Expiré'
	String get etatExpire => 'Expiré';

	/// fr: 'Jamais utilisé'
	String get jamaisServi => 'Jamais utilisé';

	/// fr: '{nombre} fois, la dernière {quand}'
	String usage({required Object nombre, required Object quand}) => '${nombre} fois, la dernière ${quand}';

	/// fr: 'Révoquer'
	String get revoquer => 'Révoquer';

	/// fr: 'Révoquer ce jeton ?'
	String get revoquerTitre => 'Révoquer ce jeton ?';

	/// fr: 'L'agent perdra l'accès à sa requête suivante. C'est définitif : un jeton révoqué ne se réactive pas.'
	String get revoquerDetail => 'L\'agent perdra l\'accès à sa requête suivante. C\'est définitif : un jeton révoqué ne se réactive pas.';

	/// fr: 'Révoquer'
	String get revoquerConfirmer => 'Révoquer';

	/// fr: 'Annuler'
	String get annuler => 'Annuler';

	/// fr: 'Jeton révoqué'
	String get revoque => 'Jeton révoqué';

	/// fr: 'La révocation n'a pas abouti. Réessayez.'
	String get erreurRevocation => 'La révocation n\'a pas abouti. Réessayez.';

	/// fr: 'Aucun jeton d'observation'
	String get vide => 'Aucun jeton d\'observation';

	/// fr: 'Aucun agent IA n'a accès à l'application pour l'instant.'
	String get videDetail => 'Aucun agent IA n\'a accès à l\'application pour l\'instant.';

	/// fr: 'La liste des jetons n'a pas pu être lue.'
	String get erreur => 'La liste des jetons n\'a pas pu être lue.';
}

// Path: admin.notifications
class Traductions$admin$notifications$fr {
	Traductions$admin$notifications$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Notifications'
	String get titre => 'Notifications';

	/// fr: 'Aucune notification'
	String get vide => 'Aucune notification';

	/// fr: 'Rien à signaler pour l'instant.'
	String get videDetail => 'Rien à signaler pour l\'instant.';
}

// Path: nav.eleve
class Traductions$nav$eleve$fr {
	Traductions$nav$eleve$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Accueil'
	String get accueil => 'Accueil';

	/// fr: 'Coran'
	String get coran => 'Coran';

	/// fr: 'Suivi'
	String get suivi => 'Suivi';

	/// fr: 'Compte'
	String get compte => 'Compte';
}

// Path: nav.tuteur
class Traductions$nav$tuteur$fr {
	Traductions$nav$tuteur$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Accueil'
	String get accueil => 'Accueil';

	/// fr: 'Foyer'
	String get foyer => 'Foyer';

	/// fr: 'Disponibilités'
	String get disponibilites => 'Disponibilités';

	/// fr: 'Réglages'
	String get reglages => 'Réglages';

	/// fr: 'Suivi'
	String get suivi => 'Suivi';

	/// fr: 'Historique'
	String get historique => 'Historique';

	/// fr: 'Compte'
	String get compte => 'Compte';
}

// Path: nav.enseignant
class Traductions$nav$enseignant$fr {
	Traductions$nav$enseignant$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Journée'
	String get journee => 'Journée';

	/// fr: 'Créneaux'
	String get creneaux => 'Créneaux';

	/// fr: 'Profil'
	String get profil => 'Profil';
}

// Path: nav.controleur
class Traductions$nav$controleur$fr {
	Traductions$nav$controleur$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Planning'
	String get planning => 'Planning';
}

// Path: nav.admin
class Traductions$nav$admin$fr {
	Traductions$nav$admin$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Tableau de bord'
	String get tableauDeBord => 'Tableau de bord';

	/// fr: 'Dossiers'
	String get dossiers => 'Dossiers';

	/// fr: 'Demandes'
	String get demandes => 'Demandes';

	/// fr: 'Attribution'
	String get attribution => 'Attribution';

	/// fr: 'Journal'
	String get journal => 'Journal';

	/// fr: 'Comptes'
	String get comptes => 'Comptes';

	/// fr: 'Accès des agents'
	String get accesAgents => 'Accès des agents';

	/// fr: 'Accueil'
	String get accueil => 'Accueil';

	/// fr: 'Opérations'
	String get operations => 'Opérations';

	/// fr: 'Personnes'
	String get personnes => 'Personnes';

	/// fr: 'Pédagogie'
	String get pedagogie => 'Pédagogie';

	/// fr: 'Finance'
	String get finance => 'Finance';

	/// fr: 'Configuration'
	String get configuration => 'Configuration';

	/// fr: 'Sécurité et audit'
	String get securite => 'Sécurité et audit';

	/// fr: 'Direction'
	String get direction => 'Direction';

	/// fr: 'Recherche'
	String get recherche => 'Recherche';

	/// fr: 'Rechercher un écran'
	String get rechercheIndication => 'Rechercher un écran';

	/// fr: 'Notifications'
	String get notificationsTitre => 'Notifications';

	/// fr: 'Menu'
	String get menu => 'Menu';
}

// Path: compte.roles
class Traductions$compte$roles$fr {
	Traductions$compte$roles$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Administrateur'
	String get admin => 'Administrateur';

	/// fr: 'Comptable'
	String get accountant => 'Comptable';

	/// fr: 'Contrôleur'
	String get controller => 'Contrôleur';

	/// fr: 'Enseignant'
	String get teacher => 'Enseignant';

	/// fr: 'Tuteur'
	String get guardian => 'Tuteur';

	/// fr: 'Élève'
	String get student => 'Élève';
}

// Path: compte.roleDetail
class Traductions$compte$roleDetail$fr {
	Traductions$compte$roleDetail$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Gère les dossiers, l'attribution et le journal de l'académie'
	String get admin => 'Gère les dossiers, l\'attribution et le journal de l\'académie';

	/// fr: 'Gère les paiements et les factures'
	String get accountant => 'Gère les paiements et les factures';

	/// fr: 'Observe les séances pour la qualité pédagogique'
	String get controller => 'Observe les séances pour la qualité pédagogique';

	/// fr: 'Donne les cours et suit ses créneaux'
	String get teacher => 'Donne les cours et suit ses créneaux';

	/// fr: 'Suit le foyer et ses enfants'
	String get guardian => 'Suit le foyer et ses enfants';

	/// fr: 'Suit ses cours et son Coran'
	String get student => 'Suit ses cours et son Coran';
}

// Path: historique.segments
class Traductions$historique$segments$fr {
	Traductions$historique$segments$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Séances'
	String get seances => 'Séances';

	/// fr: 'Observations'
	String get observations => 'Observations';
}

// Path: eleve.accueil
class Traductions$eleve$accueil$fr {
	Traductions$eleve$accueil$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Rejoindre'
	String get rejoindre => 'Rejoindre';

	/// fr: 'Le Coran'
	String get coran => 'Le Coran';

	/// fr: 'À lire quand tu veux'
	String get coranDetail => 'À lire quand tu veux';

	/// fr: 'Prochain cours'
	String get prochainCours => 'Prochain cours';

	/// fr: 'Ton cours a commencé'
	String get coursEnDirect => 'Ton cours a commencé';

	/// fr: 'Avec {prenom}'
	String avec({required Object prenom}) => 'Avec ${prenom}';

	/// fr: 'Dans {minutes} min'
	String dansMinutes({required Object minutes}) => 'Dans ${minutes} min';

	/// fr: 'Dans {heures} h {minutes}'
	String dansHeures({required Object heures, required Object minutes}) => 'Dans ${heures} h ${minutes}';

	/// fr: 'C'est presque l'heure'
	String get imminent => 'C\'est presque l\'heure';

	/// fr: 'Pas de cours aujourd'hui'
	String get aucunCours => 'Pas de cours aujourd\'hui';

	/// fr: 'Ton enseignant prépare le prochain.'
	String get aucunCoursDetail => 'Ton enseignant prépare le prochain.';

	/// fr: 'Ton prochain cours est plus tard aujourd'hui.'
	String get prochainAujourdhui => 'Ton prochain cours est plus tard aujourd\'hui.';

	/// fr: 'Ton prochain cours est demain.'
	String get prochainDemain => 'Ton prochain cours est demain.';

	/// fr: 'Ton prochain cours est dans {jours} jours.'
	String prochainDansJours({required Object jours}) => 'Ton prochain cours est dans ${jours} jours.';

	/// fr: 'Ce cours n'aura pas lieu'
	String get annulee => 'Ce cours n\'aura pas lieu';

	/// fr: 'Pas de réseau'
	String get horsLigne => 'Pas de réseau';

	/// fr: 'Tu pourras entrer dès que le réseau revient.'
	String get horsLigneDetail => 'Tu pourras entrer dès que le réseau revient.';

	/// fr: 'Pause pour la prière'
	String get pausePriere => 'Pause pour la prière';

	/// fr: '{priere}, vers {heure}'
	String pausePriereDetail({required Object priere, required Object heure}) => '${priere}, vers ${heure}';
}

// Path: eleve.coran
class Traductions$eleve$coran$fr {
	Traductions$eleve$coran$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Le Coran'
	String get titre => 'Le Coran';

	/// fr: 'Page {page} sur {total}'
	String page({required Object page, required Object total}) => 'Page ${page} sur ${total}';

	/// fr: 'Juz {juz}'
	String juz({required Object juz}) => 'Juz ${juz}';

	/// fr: 'Révélée à La Mecque'
	String get mecquoise => 'Révélée à La Mecque';

	/// fr: 'Révélée à Médine'
	String get medinoise => 'Révélée à Médine';

	/// fr: 'Reprendre ta lecture'
	String get reprendre => 'Reprendre ta lecture';

	/// fr: 'Tu en étais page {page}'
	String reprendreDetail({required Object page}) => 'Tu en étais page ${page}';

	/// fr: 'Le texte arrive'
	String get chargement => 'Le texte arrive';

	/// fr: 'Le texte n'a pas pu être chargé'
	String get indisponible => 'Le texte n\'a pas pu être chargé';

	/// fr: 'Dès que le réseau revient, ta page se rouvre ici.'
	String get indisponibleDetail => 'Dès que le réseau revient, ta page se rouvre ici.';

	/// fr: 'Réessayer'
	String get reessayer => 'Réessayer';

	/// fr: 'Cette page est vide'
	String get absent => 'Cette page est vide';

	/// fr: 'Le texte n'a pas été installé sur cette page. Signale-le : ce n'est pas toi.'
	String get absentDetail => 'Le texte n\'a pas été installé sur cette page. Signale-le : ce n\'est pas toi.';

	/// fr: 'Page précédente'
	String get pagePrecedente => 'Page précédente';

	/// fr: 'Page suivante'
	String get pageSuivante => 'Page suivante';

	/// fr: 'Réglages de lecture'
	String get reglages => 'Réglages de lecture';

	/// fr: 'Fermer les réglages'
	String get fermerReglages => 'Fermer les réglages';

	/// fr: 'Taille du texte'
	String get taille => 'Taille du texte';

	/// fr: 'Agrandir le texte'
	String get agrandir => 'Agrandir le texte';

	/// fr: 'Réduire le texte'
	String get reduire => 'Réduire le texte';

	/// fr: 'Texte du Coran : Tanzil Project'
	String get source => 'Texte du Coran : Tanzil Project';

	/// fr: 'tanzil.net'
	String get sourceLien => 'tanzil.net';

	/// fr: 'Mushaf de Médine, riwaya Hafs'
	String get edition => 'Mushaf de Médine, riwaya Hafs';
}

// Path: eleve.suivi
class Traductions$eleve$suivi$fr {
	Traductions$eleve$suivi$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Suivi de mes cours'
	String get titre => 'Suivi de mes cours';

	/// fr: 'Date'
	String get colonneDate => 'Date';

	/// fr: 'Cours'
	String get colonneCours => 'Cours';

	/// fr: 'Enseignant'
	String get colonneEnseignant => 'Enseignant';

	/// fr: 'Présence'
	String get colonneEtat => 'Présence';

	/// fr: 'Cours de Coran'
	String get cours => 'Cours de Coran';

	/// fr: 'Ma présence'
	String get moi => 'Ma présence';

	/// fr: 'Aujourd'hui, {heure}'
	String aujourdhui({required Object heure}) => 'Aujourd\'hui, ${heure}';

	/// fr: 'Hier, {heure}'
	String hier({required Object heure}) => 'Hier, ${heure}';

	/// fr: '{date}, {heure}'
	String date({required Object date, required Object heure}) => '${date}, ${heure}';

	/// fr: 'Cours annulé'
	String get annule => 'Cours annulé';

	/// fr: 'Cours non tenu'
	String get nonTenu => 'Cours non tenu';

	/// fr: 'Aucun cours pour l'instant'
	String get vide => 'Aucun cours pour l\'instant';

	/// fr: 'Vos cours s'afficheront ici, du plus récent au plus ancien, avec votre présence.'
	String get videDetail => 'Vos cours s\'afficheront ici, du plus récent au plus ancien, avec votre présence.';

	/// fr: 'Le suivi n'a pas pu être lu. Réessayez dans un instant.'
	String get erreur => 'Le suivi n\'a pas pu être lu. Réessayez dans un instant.';

	/// fr: 'Les {nombre} cours les plus récents sont affichés.'
	String tronquee({required Object nombre}) => 'Les ${nombre} cours les plus récents sont affichés.';

	/// fr: '{nombre} cours au suivi.'
	String fin({required Object nombre}) => '${nombre} cours au suivi.';

	/// fr: '1 cours au suivi.'
	String get finUn => '1 cours au suivi.';
}

// Path: tuteur.accueil
class Traductions$tuteur$accueil$fr {
	Traductions$tuteur$accueil$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Accueil'
	String get titre => 'Accueil';

	/// fr: 'Voir la classe'
	String get voirLaClasse => 'Voir la classe';

	/// fr: 'Prochaine séance'
	String get prochaineSeance => 'Prochaine séance';

	/// fr: 'Heure de {ville}'
	String heureDe({required Object ville}) => 'Heure de ${ville}';

	/// fr: 'Heure de cet appareil'
	String get heureAppareil => 'Heure de cet appareil';

	/// fr: '{date} · {fuseau}'
	String dateEtFuseau({required Object date, required Object fuseau}) => '${date} · ${fuseau}';

	/// fr: 'Heure de la classe : {heure} {ville}'
	String heureClasse({required Object heure, required Object ville}) => 'Heure de la classe : ${heure} ${ville}';

	/// fr: 'Séance en direct'
	String get seanceEnDirect => 'Séance en direct';

	/// fr: 'Séance terminée'
	String get seanceTerminee => 'Séance terminée';

	/// fr: 'Cette séance n'aura pas lieu.'
	String get seanceAnnulee => 'Cette séance n\'aura pas lieu.';

	/// fr: 'Cette séance n'a pas pu se tenir.'
	String get seanceNonTenue => 'Cette séance n\'a pas pu se tenir.';

	/// fr: 'Ouverture de la salle non confirmée pour l'instant'
	String get horaireIncertain => 'Ouverture de la salle non confirmée pour l\'instant';

	/// fr: 'Annulée'
	String get pastilleAnnulee => 'Annulée';

	/// fr: 'Non tenue'
	String get pastilleNonTenue => 'Non tenue';

	/// fr: 'Terminée'
	String get pastilleTerminee => 'Terminée';

	/// fr: 'Aucune séance planifiée'
	String get aucuneSeance => 'Aucune séance planifiée';

	/// fr: 'La prochaine séance de {prenom} apparaîtra ici dès qu'elle sera programmée.'
	String aucuneSeanceDetail({required Object prenom}) => 'La prochaine séance de ${prenom} apparaîtra ici dès qu\'elle sera programmée.';

	/// fr: 'La prochaine séance n'a pas pu être lue.'
	String get seanceIllisible => 'La prochaine séance n\'a pas pu être lue.';

	/// fr: 'Le détail de la classe n'est pas encore disponible ici.'
	String get classeIndisponible => 'Le détail de la classe n\'est pas encore disponible ici.';

	/// fr: 'La classe n'a pas pu être lue.'
	String get classeIllisible => 'La classe n\'a pas pu être lue.';

	/// fr: 'Aucune classe pour {prenom}'
	String sansClasseTitre({required Object prenom}) => 'Aucune classe pour ${prenom}';

	/// fr: 'Choisissez une classe pour que {prenom} puisse commencer les cours.'
	String sansClassePhrase({required Object prenom}) => 'Choisissez une classe pour que ${prenom} puisse commencer les cours.';

	/// fr: 'Aucun profil élève pour l'instant'
	String get foyerVideTitre => 'Aucun profil élève pour l\'instant';

	/// fr: 'Ajoutez un profil élève pour choisir une classe et suivre ses séances.'
	String get foyerVidePhrase => 'Ajoutez un profil élève pour choisir une classe et suivre ses séances.';

	/// fr: 'Ajouter un profil élève'
	String get ajouterProfil => 'Ajouter un profil élève';

	/// fr: 'Les profils du foyer n'ont pas pu être lus.'
	String get profilsIllisibles => 'Les profils du foyer n\'ont pas pu être lus.';

	/// fr: 'Aucun appareil prêt pour {prenom}'
	String blocageAppareilTitre({required Object prenom}) => 'Aucun appareil prêt pour ${prenom}';

	/// fr: 'Sans appareil connecté, {prenom} ne pourra pas entrer en classe.'
	String blocageAppareilPhrase({required Object prenom}) => 'Sans appareil connecté, ${prenom} ne pourra pas entrer en classe.';

	/// fr: 'Connecter un appareil'
	String get connecterAppareil => 'Connecter un appareil';

	/// fr: 'Avant le prochain cours'
	String get avantProchainCours => 'Avant le prochain cours';

	/// fr: 'Voir tout'
	String get voirTout => 'Voir tout';

	/// fr: 'Le travail à préparer n'est pas encore relié à cet espace.'
	String get travailIndisponible => 'Le travail à préparer n\'est pas encore relié à cet espace.';

	/// fr: 'Le travail à préparer n'a pas pu être lu.'
	String get travailIllisible => 'Le travail à préparer n\'a pas pu être lu.';

	/// fr: 'Rien à préparer pour l'instant'
	String get rienAPreparer => 'Rien à préparer pour l\'instant';

	/// fr: 'Dernière séance'
	String get derniereSeance => 'Dernière séance';

	/// fr: 'Voir l'historique'
	String get voirHistorique => 'Voir l\'historique';

	/// fr: 'Détails de la séance'
	String get detailsSeance => 'Détails de la séance';

	/// fr: 'Aucune séance passée pour l'instant'
	String get aucuneDerniere => 'Aucune séance passée pour l\'instant';

	/// fr: 'La dernière séance n'a pas pu être lue.'
	String get derniereIllisible => 'La dernière séance n\'a pas pu être lue.';

	/// fr: '{date} · {duree}'
	String dateEtDuree({required Object date, required Object duree}) => '${date} · ${duree}';

	late final Traductions$tuteur$accueil$etatCourt$fr etatCourt = Traductions$tuteur$accueil$etatCourt$fr.internal(_root);

	/// fr: 'Assister'
	String get assister => 'Assister';

	/// fr: 'Le cours n'a pas pu être rejoint. Il vient peut-être de se terminer.'
	String get assisterRefuse => 'Le cours n\'a pas pu être rejoint. Il vient peut-être de se terminer.';

	/// fr: 'En cours avec {prenom}'
	String enCours({required Object prenom}) => 'En cours avec ${prenom}';

	/// fr: 'Commencé il y a {minutes} min'
	String depuisMinutes({required Object minutes}) => 'Commencé il y a ${minutes} min';

	/// fr: 'Vient de commencer'
	String get depuisInstant => 'Vient de commencer';

	/// fr: 'Aujourd'hui à {heure}, avec {prenom}'
	String aujourdhui({required Object heure, required Object prenom}) => 'Aujourd\'hui à ${heure}, avec ${prenom}';

	/// fr: '{jour} à {heure}, avec {prenom}'
	String unAutreJour({required Object jour, required Object heure, required Object prenom}) => '${jour} à ${heure}, avec ${prenom}';

	/// fr: 'Rien aujourd'hui'
	String get rienAujourdhui => 'Rien aujourd\'hui';

	/// fr: 'Aucun cours programmé pour l'instant'
	String get aucunCoursPrevu => 'Aucun cours programmé pour l\'instant';

	/// fr: 'Les cours de la semaine sont préparés à l'avance. Celui-ci apparaîtra ici.'
	String get aucunCoursPrevuDetail => 'Les cours de la semaine sont préparés à l\'avance. Celui-ci apparaîtra ici.';

	/// fr: 'En recherche d'un enseignant'
	String get enRecherche => 'En recherche d\'un enseignant';

	/// fr: 'Demande déposée le {date}'
	String enRechercheDepuis({required Object date}) => 'Demande déposée le ${date}';

	/// fr: 'Un enseignant prendra {prenom} en charge parmi les heures proposées.'
	String enRechercheSansDate({required Object prenom}) => 'Un enseignant prendra ${prenom} en charge parmi les heures proposées.';

	/// fr: 'Aucune heure proposée pour {prenom}'
	String sansCreneau({required Object prenom}) => 'Aucune heure proposée pour ${prenom}';

	/// fr: 'Sans créneau, aucun enseignant ne peut prendre {prenom} en charge.'
	String sansCreneauDetail({required Object prenom}) => 'Sans créneau, aucun enseignant ne peut prendre ${prenom} en charge.';

	/// fr: 'Proposer des heures'
	String get poserDesHeures => 'Proposer des heures';

	/// fr: 'Le cours de {heure} n'aura pas lieu'
	String annulee({required Object heure}) => 'Le cours de ${heure} n\'aura pas lieu';

	/// fr: 'Séance annulée'
	String get motifAnnulee => 'Séance annulée';

	/// fr: 'Séance annulée peu avant l'heure'
	String get motifAnnuleeTard => 'Séance annulée peu avant l\'heure';

	/// fr: 'Prochain cours {jour} à {heure}'
	String proposeApres({required Object jour, required Object heure}) => 'Prochain cours ${jour} à ${heure}';

	/// fr: 'Un nouveau cours vous sera proposé.'
	String get proposeAucun => 'Un nouveau cours vous sera proposé.';

	/// fr: 'Gérer le foyer'
	String get gererLeFoyer => 'Gérer le foyer';

	/// fr: 'Appareils du foyer'
	String get blocAppareils => 'Appareils du foyer';

	/// fr: 'Ajouter un appareil, ou en retirer un.'
	String get blocAppareilsDetail => 'Ajouter un appareil, ou en retirer un.';

	/// fr: 'Réglages par enfant'
	String get blocReglages => 'Réglages par enfant';

	/// fr: 'Photo, caméra et affichage, enfant par enfant.'
	String get blocReglagesDetail => 'Photo, caméra et affichage, enfant par enfant.';

	/// fr: 'Le groupe, l'enseignant et le prochain cours de chaque enfant.'
	String get blocGroupesDetail => 'Le groupe, l\'enseignant et le prochain cours de chaque enfant.';

	/// fr: 'Accès'
	String get acces => 'Accès';

	/// fr: 'Accès de {prenom} jusqu'au {date}'
	String accesJusqua({required Object prenom, required Object date}) => 'Accès de ${prenom} jusqu\'au ${date}';

	/// fr: 'Accès de {prenom} sans date de fin'
	String accesSansFin({required Object prenom}) => 'Accès de ${prenom} sans date de fin';

	/// fr: 'Aucun enfant dans le foyer'
	String get aucunEnfant => 'Aucun enfant dans le foyer';

	/// fr: 'Ajoutez votre premier enfant pour commencer.'
	String get aucunEnfantDetail => 'Ajoutez votre premier enfant pour commencer.';

	/// fr: 'Le foyer n'a pas pu être lu en entier. Réessayez dans un instant.'
	String get erreur => 'Le foyer n\'a pas pu être lu en entier. Réessayez dans un instant.';
}

// Path: tuteur.reglages
class Traductions$tuteur$reglages$fr {
	Traductions$tuteur$reglages$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Réglages par enfant'
	String get titre => 'Réglages par enfant';

	/// fr: 'Ces réglages s'appliquent à la séance suivante, jamais pendant un cours.'
	String get intro => 'Ces réglages s\'appliquent à la séance suivante, jamais pendant un cours.';

	/// fr: 'Photo'
	String get photo => 'Photo';

	/// fr: '{prenom} n'a pas encore de photo. Elle reste visible du seul foyer.'
	String photoAucune({required Object prenom}) => '${prenom} n\'a pas encore de photo. Elle reste visible du seul foyer.';

	/// fr: 'La photo de {prenom} reste visible du seul foyer, jamais de son enseignant ni des autres élèves.'
	String photoPresente({required Object prenom}) => 'La photo de ${prenom} reste visible du seul foyer, jamais de son enseignant ni des autres élèves.';

	/// fr: 'Ajouter une photo'
	String get photoAjouter => 'Ajouter une photo';

	/// fr: 'Changer la photo'
	String get photoChanger => 'Changer la photo';

	/// fr: 'Cette photo dépasse {taille} Mo. Reprenez-la en qualité plus basse.'
	String photoTropLourde({required Object taille}) => 'Cette photo dépasse ${taille} Mo. Reprenez-la en qualité plus basse.';

	/// fr: 'Caméra'
	String get camera => 'Caméra';

	/// fr: '{prenom} peut allumer sa caméra pendant le cours.'
	String cameraAutorisee({required Object prenom}) => '${prenom} peut allumer sa caméra pendant le cours.';

	/// fr: 'Le bouton caméra n'apparaîtra pas pour {prenom}.'
	String cameraInterdite({required Object prenom}) => 'Le bouton caméra n\'apparaîtra pas pour ${prenom}.';

	/// fr: 'Autoriser la caméra de {prenom}'
	String cameraAutoriser({required Object prenom}) => 'Autoriser la caméra de ${prenom}';

	/// fr: 'Retirer la caméra de {prenom}'
	String cameraRetirer({required Object prenom}) => 'Retirer la caméra de ${prenom}';

	/// fr: 'Affichage'
	String get mode => 'Affichage';

	/// fr: 'Grand affichage, sans lecture : {prenom} reconnaît des images et écoute.'
	String modeEnfant({required Object prenom}) => 'Grand affichage, sans lecture : ${prenom} reconnaît des images et écoute.';

	/// fr: 'Affichage courant : {prenom} lit son écran.'
	String modeStandard({required Object prenom}) => 'Affichage courant : ${prenom} lit son écran.';

	/// fr: 'Passer {prenom} au grand affichage'
	String modePasserEnfant({required Object prenom}) => 'Passer ${prenom} au grand affichage';

	/// fr: 'Passer {prenom} à l'affichage courant'
	String modePasserStandard({required Object prenom}) => 'Passer ${prenom} à l\'affichage courant';

	/// fr: 'Demander un changement'
	String get demandes => 'Demander un changement';

	/// fr: 'Changer d'enseignant'
	String get demandeReaffectation => 'Changer d\'enseignant';

	/// fr: 'Changer la durée des cours'
	String get demandeDuree => 'Changer la durée des cours';

	/// fr: 'Changer la durée minimale payable'
	String get demandeMinimum => 'Changer la durée minimale payable';

	/// fr: '{prenom} n'a pas encore d'enseignant : il n'y a rien à changer.'
	String demandeSansEnseignant({required Object prenom}) => '${prenom} n\'a pas encore d\'enseignant : il n\'y a rien à changer.';

	/// fr: 'Changer l'enseignant de {prenom}'
	String demandeTitreReaffectation({required Object prenom}) => 'Changer l\'enseignant de ${prenom}';

	/// fr: 'La durée des cours de {prenom}'
	String demandeTitreDuree({required Object prenom}) => 'La durée des cours de ${prenom}';

	/// fr: 'La durée minimale payable pour {prenom}'
	String demandeTitreMinimum({required Object prenom}) => 'La durée minimale payable pour ${prenom}';

	/// fr: 'Aujourd'hui : {minutes} min'
	String demandeActuelle({required Object minutes}) => 'Aujourd\'hui : ${minutes} min';

	/// fr: '{minutes} min'
	String demandeMinutes({required Object minutes}) => '${minutes} min';

	/// fr: 'Pourquoi ce changement ?'
	String get demandeMotif => 'Pourquoi ce changement ?';

	/// fr: 'Un motif est nécessaire : c'est lui qui permet de trancher.'
	String get demandeMotifRequis => 'Un motif est nécessaire : c\'est lui qui permet de trancher.';

	/// fr: 'Envoyer la demande'
	String get demandeEnvoyer => 'Envoyer la demande';

	/// fr: 'Demande envoyée. L'administration la tranchera.'
	String get demandeEnvoyee => 'Demande envoyée. L\'administration la tranchera.';

	/// fr: 'Aucun enfant dans le foyer'
	String get aucunEnfant => 'Aucun enfant dans le foyer';

	/// fr: 'Ajoutez un enfant pour pouvoir régler son affichage et sa caméra.'
	String get aucunEnfantDetail => 'Ajoutez un enfant pour pouvoir régler son affichage et sa caméra.';

	/// fr: 'L'enregistrement n'a pas abouti : {message}'
	String erreur({required Object message}) => 'L\'enregistrement n\'a pas abouti : ${message}';
}

// Path: tuteur.suivi
class Traductions$tuteur$suivi$fr {
	Traductions$tuteur$suivi$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Suivi du foyer'
	String get titre => 'Suivi du foyer';

	/// fr: 'Tous les enfants'
	String get tousLesEnfants => 'Tous les enfants';

	/// fr: 'Date'
	String get colonneDate => 'Date';

	/// fr: 'Enfant'
	String get colonneEnfant => 'Enfant';

	/// fr: 'Enseignant'
	String get colonneEnseignant => 'Enseignant';

	/// fr: 'État'
	String get colonneEtat => 'État';

	/// fr: 'Aujourd'hui, {heure}'
	String aujourdhui({required Object heure}) => 'Aujourd\'hui, ${heure}';

	/// fr: 'Hier, {heure}'
	String hier({required Object heure}) => 'Hier, ${heure}';

	/// fr: '{date}, {heure}'
	String date({required Object date, required Object heure}) => '${date}, ${heure}';

	/// fr: 'Cours annulé'
	String get annule => 'Cours annulé';

	/// fr: 'Cours non tenu'
	String get nonTenu => 'Cours non tenu';

	/// fr: 'Aucun cours pour l'instant'
	String get vide => 'Aucun cours pour l\'instant';

	/// fr: 'Les cours de vos enfants s'afficheront ici, du plus récent au plus ancien, avec leur présence.'
	String get videDetail => 'Les cours de vos enfants s\'afficheront ici, du plus récent au plus ancien, avec leur présence.';

	/// fr: 'Aucun cours pour cet enfant'
	String get videFiltre => 'Aucun cours pour cet enfant';

	/// fr: 'Relâchez le filtre pour retrouver le reste du foyer.'
	String get videFiltreDetail => 'Relâchez le filtre pour retrouver le reste du foyer.';

	/// fr: 'Tout afficher'
	String get effacerFiltres => 'Tout afficher';

	/// fr: 'Le suivi n'a pas pu être lu. Réessayez dans un instant.'
	String get erreur => 'Le suivi n\'a pas pu être lu. Réessayez dans un instant.';

	/// fr: 'Les {nombre} cours les plus récents sont affichés.'
	String tronquee({required Object nombre}) => 'Les ${nombre} cours les plus récents sont affichés.';

	/// fr: '{nombre} cours au suivi.'
	String fin({required Object nombre}) => '${nombre} cours au suivi.';

	/// fr: '1 cours au suivi.'
	String get finUn => '1 cours au suivi.';
}

// Path: classe.seance
class Traductions$classe$seance$fr {
	Traductions$classe$seance$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Aucune séance planifiée'
	String get aucune => 'Aucune séance planifiée';

	/// fr: 'La prochaine séance de {prenom} apparaîtra ici dès qu'elle sera programmée.'
	String aucuneDetail({required Object prenom}) => 'La prochaine séance de ${prenom} apparaîtra ici dès qu\'elle sera programmée.';

	/// fr: 'La prochaine séance n'a pas pu être lue.'
	String get illisible => 'La prochaine séance n\'a pas pu être lue.';

	/// fr: '{prenom} : {etat}'
	String presence({required Object prenom, required Object etat}) => '${prenom} : ${etat}';
}

// Path: classe.observation
class Traductions$classe$observation$fr {
	Traductions$classe$observation$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Comment ça marche ?'
	String get commentCaMarche => 'Comment ça marche ?';

	/// fr: '1 visite disponible'
	String get uneVisite => '1 visite disponible';

	/// fr: '{nombre} visites disponibles'
	String visites({required Object nombre}) => '${nombre} visites disponibles';

	/// fr: '{visites} · {duree} par visite'
	String resume({required Object visites, required Object duree}) => '${visites} · ${duree} par visite';

	/// fr: 'Aucune visite restante pour cette séance'
	String get restanteAucune => 'Aucune visite restante pour cette séance';

	/// fr: '1 visite restante pour cette séance'
	String get restanteUne => '1 visite restante pour cette séance';

	/// fr: '{nombre} visites restantes pour cette séance'
	String restantes({required Object nombre}) => '${nombre} visites restantes pour cette séance';

	/// fr: '{minutes} min'
	String minutes({required Object minutes}) => '${minutes} min';

	/// fr: '{minutes} min {secondes} s'
	String minutesSecondes({required Object minutes, required Object secondes}) => '${minutes} min ${secondes} s';

	/// fr: '{secondes} s'
	String secondes({required Object secondes}) => '${secondes} s';

	late final Traductions$classe$observation$motif$fr motif = Traductions$classe$observation$motif$fr.internal(_root);
}

// Path: classe.pagePlanning
class Traductions$classe$pagePlanning$fr {
	Traductions$classe$pagePlanning$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Prochaines séances'
	String get prochaines => 'Prochaines séances';

	/// fr: '{heure} · {duree}'
	String ligne({required Object heure, required Object duree}) => '${heure} · ${duree}';

	/// fr: '{heure} ({fuseau}) · {duree}'
	String ligneFuseau({required Object heure, required Object fuseau, required Object duree}) => '${heure} (${fuseau}) · ${duree}';

	/// fr: 'Aucune séance à venir pour l'instant'
	String get aucune => 'Aucune séance à venir pour l\'instant';

	/// fr: 'Les prochaines séances de {prenom} apparaîtront ici dès qu'elles seront programmées.'
	String aucuneDetail({required Object prenom}) => 'Les prochaines séances de ${prenom} apparaîtront ici dès qu\'elles seront programmées.';

	/// fr: 'Les jours habituels de la classe ne sont pas encore affichés ici : seules les séances déjà programmées apparaissent.'
	String get habituelIndisponible => 'Les jours habituels de la classe ne sont pas encore affichés ici : seules les séances déjà programmées apparaissent.';
}

// Path: classe.pageTravail
class Traductions$classe$pageTravail$fr {
	Traductions$classe$pageTravail$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Rien à préparer pour l'instant'
	String get aucun => 'Rien à préparer pour l\'instant';

	/// fr: 'Le travail donné par l'enseignant apparaîtra ici.'
	String get aucunDetail => 'Le travail donné par l\'enseignant apparaîtra ici.';

	/// fr: 'Le travail à préparer n'est pas encore relié à cet espace.'
	String get indisponible => 'Le travail à préparer n\'est pas encore relié à cet espace.';

	/// fr: 'Échéance : {date}'
	String echeance({required Object date}) => 'Échéance : ${date}';

	/// fr: 'Marquer un travail comme fait n'est pas encore possible ici.'
	String get nonCochable => 'Marquer un travail comme fait n\'est pas encore possible ici.';

	late final Traductions$classe$pageTravail$statut$fr statut = Traductions$classe$pageTravail$statut$fr.internal(_root);
}

// Path: classe.pageRessources
class Traductions$classe$pageRessources$fr {
	Traductions$classe$pageRessources$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Aucune ressource pour cette classe pour l'instant'
	String get aucune => 'Aucune ressource pour cette classe pour l\'instant';

	/// fr: 'Les supports choisis par l'enseignant apparaîtront ici.'
	String get aucuneDetail => 'Les supports choisis par l\'enseignant apparaîtront ici.';

	/// fr: 'La bibliothèque de la classe n'est pas encore reliée à cet espace.'
	String get indisponible => 'La bibliothèque de la classe n\'est pas encore reliée à cet espace.';
}

// Path: classe.pageProgression
class Traductions$classe$pageProgression$fr {
	Traductions$classe$pageProgression$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'La progression de {prenom} n'est pas encore partagée ici.'
	String indisponible({required Object prenom}) => 'La progression de ${prenom} n\'est pas encore partagée ici.';

	/// fr: 'Niveau'
	String get niveau => 'Niveau';

	/// fr: 'Étapes franchies'
	String get jalons => 'Étapes franchies';

	/// fr: 'Aucune étape partagée pour l'instant'
	String get aucune => 'Aucune étape partagée pour l\'instant';

	/// fr: 'Les progrès que l'enseignant partage avec la famille apparaîtront ici.'
	String get aucuneDetail => 'Les progrès que l\'enseignant partage avec la famille apparaîtront ici.';
}

// Path: enseignant.bienvenue
class Traductions$enseignant$bienvenue$fr {
	Traductions$enseignant$bienvenue$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Premiers pas'
	String get titre => 'Premiers pas';

	/// fr: 'Bienvenue, {prenom}.'
	String salutation({required Object prenom}) => 'Bienvenue, ${prenom}.';

	/// fr: 'Bienvenue.'
	String get salutationSansNom => 'Bienvenue.';

	/// fr: 'Votre dossier est validé.'
	String get dossierValide => 'Votre dossier est validé.';

	/// fr: 'Ce qui vient maintenant'
	String get suite => 'Ce qui vient maintenant';

	/// fr: 'Vous déclarez vos heures d'enseignement, par créneaux d'une heure.'
	String get pas1 => 'Vous déclarez vos heures d\'enseignement, par créneaux d\'une heure.';

	/// fr: 'L'académie vous confie des élèves sur ces heures, en groupes de cinq enfants ou six adultes.'
	String get pas2 => 'L\'académie vous confie des élèves sur ces heures, en groupes de cinq enfants ou six adultes.';

	/// fr: 'Après chaque cours, vous remplissez un cahier de transmission. Il est prérempli : vous ne corrigez que les exceptions.'
	String get pas3 => 'Après chaque cours, vous remplissez un cahier de transmission. Il est prérempli : vous ne corrigez que les exceptions.';

	/// fr: 'Deux choses à ne pas découvrir en cours de route'
	String get rappels => 'Deux choses à ne pas découvrir en cours de route';

	/// fr: 'Vous les avez accusées à l'inscription. Elles sont rappelées ici, et la salle les rappelle en permanence.'
	String get rappelDejaAccepte => 'Vous les avez accusées à l\'inscription. Elles sont rappelées ici, et la salle les rappelle en permanence.';

	/// fr: 'Déclarer mes disponibilités'
	String get declarer => 'Déclarer mes disponibilités';

	/// fr: 'Aller à ma journée'
	String get versJournee => 'Aller à ma journée';

	/// fr: 'Sans réseau, vos créneaux ne pourront pas être enregistrés.'
	String get horsLigne => 'Sans réseau, vos créneaux ne pourront pas être enregistrés.';

	/// fr: 'Votre dossier n'est pas encore validé.'
	String get dossierIncomplet => 'Votre dossier n\'est pas encore validé.';

	/// fr: 'Le portail d'attente vous dit ce qu'il reste à fournir.'
	String get dossierIncompletDetail => 'Le portail d\'attente vous dit ce qu\'il reste à fournir.';

	/// fr: 'Voir mon dossier'
	String get versAttente => 'Voir mon dossier';

	/// fr: 'Votre profil n'a pas pu être lu. Réessayez dans un instant.'
	String get erreur => 'Votre profil n\'a pas pu être lu. Réessayez dans un instant.';
}

// Path: enseignant.journee
class Traductions$enseignant$journee$fr {
	Traductions$enseignant$journee$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Lancer le cours'
	String get lancer => 'Lancer le cours';

	/// fr: 'Vérifier avant le cours'
	String get preflight => 'Vérifier avant le cours';

	/// fr: 'Votre journée'
	String get titre => 'Votre journée';

	/// fr: 'Prochain cours'
	String get prochainCours => 'Prochain cours';

	/// fr: 'Séance en direct'
	String get coursEnCours => 'Séance en direct';

	/// fr: 'Dans {heures} h {minutes}'
	String minuteurHeures({required Object heures, required Object minutes}) => 'Dans ${heures} h ${minutes}';

	/// fr: 'Dans {minutes} min'
	String minuteurMinutes({required Object minutes}) => 'Dans ${minutes} min';

	/// fr: 'Ça commence'
	String get minuteurImminent => 'Ça commence';

	/// fr: 'Jusqu'à {heure}'
	String jusqua({required Object heure}) => 'Jusqu\'à ${heure}';

	/// fr: '{jour}, à {heure}'
	String unAutreJour({required Object jour, required Object heure}) => '${jour}, à ${heure}';

	/// fr: 'Le lancement s'ouvre dix minutes avant l'heure du cours.'
	String get lancementPlusTard => 'Le lancement s\'ouvre dix minutes avant l\'heure du cours.';

	/// fr: 'Aucun cours à venir'
	String get aucunCours => 'Aucun cours à venir';

	/// fr: 'Prenez un élève en attente : c'est ce qui remplit votre journée.'
	String get aucunCoursDetail => 'Prenez un élève en attente : c\'est ce qui remplit votre journée.';

	/// fr: 'La journée'
	String get colonne => 'La journée';

	/// fr: 'Cours avec {prenom}'
	String ligneCours({required Object prenom}) => 'Cours avec ${prenom}';

	/// fr: 'Pause'
	String get lignePause => 'Pause';

	/// fr: '{debut} à {fin}'
	String plage({required Object debut, required Object fin}) => '${debut} à ${fin}';

	/// fr: '{minutes} min'
	String duree({required Object minutes}) => '${minutes} min';

	/// fr: 'Rien de prévu aujourd'hui'
	String get rienAujourdhui => 'Rien de prévu aujourd\'hui';

	/// fr: 'Votre prochain cours est {jour} à {heure}.'
	String rienAujourdhuiDetail({required Object jour, required Object heure}) => 'Votre prochain cours est ${jour} à ${heure}.';

	/// fr: '{nombre} cours donnés aujourd'hui.'
	String journeeTerminee({required Object nombre}) => '${nombre} cours donnés aujourd\'hui.';

	/// fr: '1 cours donné aujourd'hui.'
	String get journeeTermineeUn => '1 cours donné aujourd\'hui.';

	/// fr: 'Voir mes créneaux'
	String get voirCreneaux => 'Voir mes créneaux';

	/// fr: 'La journée n'a pas pu être lue en entier. Réessayez dans un instant.'
	String get erreur => 'La journée n\'a pas pu être lue en entier. Réessayez dans un instant.';

	/// fr: 'Cours individuel'
	String get coursIndividuel => 'Cours individuel';

	/// fr: '{nombre} élèves'
	String effectif({required Object nombre}) => '${nombre} élèves';

	/// fr: '1 élève'
	String get effectifUn => '1 élève';

	/// fr: 'Voir le groupe'
	String get voirGroupe => 'Voir le groupe';

	/// fr: 'Micro prêt'
	String get preflightOk => 'Micro prêt';

	/// fr: 'Le micro est bloqué par votre navigateur. Autorisez-le pour lancer le cours.'
	String get preflightBloque => 'Le micro est bloqué par votre navigateur. Autorisez-le pour lancer le cours.';

	/// fr: 'Aucun micro n'est détecté. Branchez-en un pour lancer le cours.'
	String get preflightSansMicro => 'Aucun micro n\'est détecté. Branchez-en un pour lancer le cours.';

	/// fr: 'La vérification du matériel n'a pas abouti. Réessayez avant de lancer le cours.'
	String get preflightIndisponible => 'La vérification du matériel n\'a pas abouti. Réessayez avant de lancer le cours.';

	/// fr: 'Sans réseau, la salle ne peut pas s'ouvrir. Reconnectez-vous pour lancer le cours.'
	String get lancerHorsLigne => 'Sans réseau, la salle ne peut pas s\'ouvrir. Reconnectez-vous pour lancer le cours.';

	/// fr: 'Une partie de la journée n'a pas pu être lue : prières, pauses ou rapports peuvent manquer.'
	String get erreurPartielle => 'Une partie de la journée n\'a pas pu être lue : prières, pauses ou rapports peuvent manquer.';

	/// fr: '{eleve} n'est pas entré en salle.'
	String absenceDetectee({required Object eleve}) => '${eleve} n\'est pas entré en salle.';

	/// fr: '{eleve} a perdu la connexion.'
	String coupureDetectee({required Object eleve}) => '${eleve} a perdu la connexion.';

	/// fr: 'et {nombre} autres élèves.'
	String autresAbsences({required Object nombre}) => 'et ${nombre} autres élèves.';

	/// fr: 'Le cours de {heure} est annulé.'
	String coursAnnule({required Object heure}) => 'Le cours de ${heure} est annulé.';

	/// fr: 'Rapports en attente'
	String get rapportsTitre => 'Rapports en attente';

	/// fr: 'Cours du {jour} à {heure}'
	String rapportLigne({required Object jour, required Object heure}) => 'Cours du ${jour} à ${heure}';

	/// fr: 'À déposer depuis {heures} h'
	String rapportAttente({required Object heures}) => 'À déposer depuis ${heures} h';

	/// fr: 'En retard de {heures} h'
	String rapportRetard({required Object heures}) => 'En retard de ${heures} h';

	/// fr: 'Élèves en attente'
	String get enAttenteTitre => 'Élèves en attente';

	/// fr: 'élèves en attente sur vos heures'
	String get enAttenteLibelle => 'élèves en attente sur vos heures';

	/// fr: 'élève en attente sur vos heures'
	String get enAttenteLibelleUn => 'élève en attente sur vos heures';
}

// Path: enseignant.salle
class Traductions$enseignant$salle$fr {
	Traductions$enseignant$salle$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Présenté : page {page} sur {total} · {reference}'
	String reference({required Object page, required Object total, required Object reference}) => 'Présenté : page ${page} sur ${total} · ${reference}';

	/// fr: 'Rien n'est présenté'
	String get rien => 'Rien n\'est présenté';

	/// fr: 'Ouvrez le Coran pour montrer une page à votre groupe.'
	String get rienInvitation => 'Ouvrez le Coran pour montrer une page à votre groupe.';

	/// fr: 'Vous n'êtes pas encore dans la salle'
	String get attenteSalle => 'Vous n\'êtes pas encore dans la salle';

	/// fr: 'Les commandes de présentation s'ouvrent dès que le cours est connecté.'
	String get attenteSalleDetail => 'Les commandes de présentation s\'ouvrent dès que le cours est connecté.';

	/// fr: 'le tour de page peut arriver en retard chez votre groupe'
	String get lienFaibleDetail => 'le tour de page peut arriver en retard chez votre groupe';

	/// fr: 'la page présentée est conservée, elle repartira au retour du lien'
	String get presentationConservee => 'la page présentée est conservée, elle repartira au retour du lien';

	/// fr: 'présentation suspendue'
	String get presentationSuspendue => 'présentation suspendue';

	/// fr: 'Présenter la page précédente'
	String get precedente => 'Présenter la page précédente';

	/// fr: 'Présenter la page suivante'
	String get suivante => 'Présenter la page suivante';

	/// fr: 'Choisir une sourate'
	String get bibliotheque => 'Choisir une sourate';

	/// fr: 'Présenter le début de {sourate}'
	String presenterSourate({required Object sourate}) => 'Présenter le début de ${sourate}';

	/// fr: 'Sourate {numero} · {versets} versets'
	String sourateDetail({required Object numero, required Object versets}) => 'Sourate ${numero} · ${versets} versets';

	/// fr: 'La liste des sourates n'a pas pu être lue'
	String get souratesIndisponibles => 'La liste des sourates n\'a pas pu être lue';

	/// fr: 'Ce que votre groupe voit n'a pas changé. Réessayez.'
	String get souratesIndisponiblesDetail => 'Ce que votre groupe voit n\'a pas changé. Réessayez.';

	/// fr: 'Cette page n'a pas pu être lue'
	String get pageIndisponible => 'Cette page n\'a pas pu être lue';

	/// fr: 'Le texte n'est pas arrivé jusqu'ici. Votre groupe voit toujours la page présentée.'
	String get pageIndisponibleDetail => 'Le texte n\'est pas arrivé jusqu\'ici. Votre groupe voit toujours la page présentée.';

	/// fr: 'Le texte du Coran n'est pas installé'
	String get corpusAbsent => 'Le texte du Coran n\'est pas installé';

	/// fr: 'Le corpus n'a pas été importé dans cet environnement. Il n'y a rien à présenter.'
	String get corpusAbsentDetail => 'Le corpus n\'a pas été importé dans cet environnement. Il n\'y a rien à présenter.';

	/// fr: 'Ce verset n'a pas pu être situé dans le mushaf. Rien n'a été envoyé à votre groupe.'
	String get echecPresentation => 'Ce verset n\'a pas pu être situé dans le mushaf. Rien n\'a été envoyé à votre groupe.';

	/// fr: 'Votre accès à cette séance ne permet pas de présenter un contenu.'
	String get sansDroitPresentation => 'Votre accès à cette séance ne permet pas de présenter un contenu.';
}

// Path: enseignant.cahier
class Traductions$enseignant$cahier$fr {
	Traductions$enseignant$cahier$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Cahier de transmission'
	String get titre => 'Cahier de transmission';

	/// fr: '{minutes} min de cours'
	String duree({required Object minutes}) => '${minutes} min de cours';

	/// fr: '{minutes} min de cours, dont {interruption} min d'interruption'
	String dureeEtInterruption({required Object minutes, required Object interruption}) => '${minutes} min de cours, dont ${interruption} min d\'interruption';

	/// fr: '1 élève'
	String get unEleve => '1 élève';

	/// fr: '{nombre} élèves'
	String eleves({required Object nombre}) => '${nombre} élèves';

	/// fr: 'Tout s'est passé comme prévu.'
	String get toutEstNominal => 'Tout s\'est passé comme prévu.';

	/// fr: 'Validez, et votre journée continue.'
	String get toutEstNominalDetail => 'Validez, et votre journée continue.';

	/// fr: 'À regarder'
	String get exceptions => 'À regarder';

	/// fr: '1 élève demande un regard.'
	String get uneException => '1 élève demande un regard.';

	/// fr: '{nombre} élèves demandent un regard.'
	String plusieursExceptions({required Object nombre}) => '${nombre} élèves demandent un regard.';

	/// fr: 'Rien à signaler'
	String get nominaux => 'Rien à signaler';

	/// fr: 'Le niveau et le programme sont ceux de l'académie : ils ne se modifient pas depuis le cahier.'
	String get curriculumFige => 'Le niveau et le programme sont ceux de l\'académie : ils ne se modifient pas depuis le cahier.';

	/// fr: 'Note pour le groupe'
	String get noteGroupe => 'Note pour le groupe';

	/// fr: 'Facultative. Aucun texte n'est attendu.'
	String get noteGroupeDetail => 'Facultative. Aucun texte n\'est attendu.';

	/// fr: 'Valider le cahier'
	String get valider => 'Valider le cahier';

	/// fr: 'Tout est conforme, valider'
	String get validerTout => 'Tout est conforme, valider';

	/// fr: 'Déposer sans le constat'
	String get validerSansConstat => 'Déposer sans le constat';

	/// fr: 'Retour à la journée'
	String get retourJournee => 'Retour à la journée';

	/// fr: 'Le constat n'a pas pu être déduit'
	String get vide => 'Le constat n\'a pas pu être déduit';

	/// fr: 'Aucune présence et aucun événement n'ont été relevés pour cette séance. Vous pouvez tout de même déposer le cahier.'
	String get videDetail => 'Aucune présence et aucun événement n\'ont été relevés pour cette séance. Vous pouvez tout de même déposer le cahier.';

	/// fr: 'Le constat n'a pas pu être lu.'
	String get erreur => 'Le constat n\'a pas pu être lu.';

	/// fr: 'Réessayez, ou déposez le cahier sans le constat : un cahier tardif vaut mieux qu'un cahier perdu.'
	String get erreurDetail => 'Réessayez, ou déposez le cahier sans le constat : un cahier tardif vaut mieux qu\'un cahier perdu.';

	/// fr: 'Le cahier n'a pas pu être enregistré. Réessayez.'
	String get echecEnvoi => 'Le cahier n\'a pas pu être enregistré. Réessayez.';

	/// fr: 'Le cahier de cette séance est déjà déposé.'
	String get dejaDepose => 'Le cahier de cette séance est déjà déposé.';

	/// fr: 'Un cahier ne se dépose qu'une fois, et il ne se supprime pas d'ici.'
	String get dejaDeposeDetail => 'Un cahier ne se dépose qu\'une fois, et il ne se supprime pas d\'ici.';

	/// fr: 'Cahier déposé'
	String get depose => 'Cahier déposé';

	/// fr: 'L'académie l'a reçu.'
	String get deposeDetail => 'L\'académie l\'a reçu.';

	/// fr: 'Cahier enregistré'
	String get enFileTitre => 'Cahier enregistré';

	/// fr: 'Enregistré. Sera envoyé dès le retour du réseau.'
	String get enFile => 'Enregistré. Sera envoyé dès le retour du réseau.';

	/// fr: 'L'envoi n'a pas abouti : il repartira tout seul, sans que vous ayez à revenir ici.'
	String get enFileDetail => 'L\'envoi n\'a pas abouti : il repartira tout seul, sans que vous ayez à revenir ici.';

	/// fr: 'Sans réseau, le cahier reste sur cet appareil et part dès que le réseau revient. Vous pouvez enchaîner sur votre cours suivant.'
	String get enFileDetailHorsLigne => 'Sans réseau, le cahier reste sur cet appareil et part dès que le réseau revient. Vous pouvez enchaîner sur votre cours suivant.';

	/// fr: 'Ajuster · {eleve}'
	String ajusterPour({required Object eleve}) => 'Ajuster · ${eleve}';

	/// fr: 'Enregistrer pour cet élève'
	String get ajusterValider => 'Enregistrer pour cet élève';

	/// fr: 'Exception signalée'
	String get exceptionConsignee => 'Exception signalée';

	/// fr: 'Point de prononciation'
	String get pointPhonetique => 'Point de prononciation';

	/// fr: 'Une paire, pas un bilan. Laissez vide s'il n'y a rien à dire.'
	String get pointPhonetiqueDetail => 'Une paire, pas un bilan. Laissez vide s\'il n\'y a rien à dire.';

	/// fr: 'Point de prononciation noté'
	String get pointPhonetiqueNote => 'Point de prononciation noté';

	/// fr: 'Objectif personnel'
	String get objectif => 'Objectif personnel';

	/// fr: 'Il s'inscrit dans le programme de l'académie, qui ne se modifie pas d'ici.'
	String get objectifDetail => 'Il s\'inscrit dans le programme de l\'académie, qui ne se modifie pas d\'ici.';

	/// fr: 'Travail à la maison'
	String get travailMaison => 'Travail à la maison';

	/// fr: 'Ajustez la suggestion, ou laissez-la telle quelle.'
	String get travailMaisonDetail => 'Ajustez la suggestion, ou laissez-la telle quelle.';

	/// fr: 'Suspendre le nouveau contenu'
	String get suspendreNouveau => 'Suspendre le nouveau contenu';

	/// fr: 'La révision continue, rien de nouveau n'est ajouté pour cet élève.'
	String get suspendreNouveauDetail => 'La révision continue, rien de nouveau n\'est ajouté pour cet élève.';

	/// fr: 'Lecture : sourate {sourate}, verset {verset}'
	String position({required Object sourate, required Object verset}) => 'Lecture : sourate ${sourate}, verset ${verset}';

	/// fr: 'Sîn / Sâd (س / ص)'
	String get makhrajSinSad => 'Sîn / Sâd (س / ص)';

	/// fr: 'Tâ / Tâ emphatique (ت / ط)'
	String get makhrajTaTah => 'Tâ / Tâ emphatique (ت / ط)';

	/// fr: 'Dhâl / Zây (ذ / ز)'
	String get makhrajDhalZay => 'Dhâl / Zây (ذ / ز)';

	/// fr: 'Hâ / Hâ' (ه / ح)'
	String get makhrajHaHah => 'Hâ / Hâ\' (ه / ح)';

	/// fr: 'Signaler une exception'
	String get exceptionTitre => 'Signaler une exception';

	/// fr: 'Corriger la présence'
	String get exceptionCorriger => 'Corriger la présence';

	/// fr: 'Excuser l'absence'
	String get exceptionExcuser => 'Excuser l\'absence';

	/// fr: 'Confirmer l'exception'
	String get exceptionConfirmation => 'Confirmer l\'exception';

	/// fr: 'Motif'
	String get exceptionMotif => 'Motif';

	/// fr: 'Le motif est obligatoire : il reste au dossier de la séance.'
	String get exceptionMotifRequis => 'Le motif est obligatoire : il reste au dossier de la séance.';

	/// fr: 'Enregistrement…'
	String get exceptionEnCours => 'Enregistrement…';

	/// fr: 'Exception consignée. Elle partira avec le cahier.'
	String get exceptionSucces => 'Exception consignée. Elle partira avec le cahier.';

	/// fr: 'L'exception n'a pas pu être consignée.'
	String get exceptionErreur => 'L\'exception n\'a pas pu être consignée.';

	/// fr: 'Sans réseau, une exception ne peut pas être confirmée. Le cahier, lui, part quand même.'
	String get exceptionHorsLigne => 'Sans réseau, une exception ne peut pas être confirmée. Le cahier, lui, part quand même.';

	/// fr: 'Votre décision et son motif sont consignés dans le cahier, avec votre nom.'
	String get exceptionJournalisation => 'Votre décision et son motif sont consignés dans le cahier, avec votre nom.';
}

// Path: enseignant.profil
class Traductions$enseignant$profil$fr {
	Traductions$enseignant$profil$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Profil'
	String get titre => 'Profil';

	/// fr: 'Compte enseignant vérifié'
	String get compteValide => 'Compte enseignant vérifié';

	/// fr: 'Ce que l'académie sait de vous, et ce que vous pouvez y changer.'
	String get intro => 'Ce que l\'académie sait de vous, et ce que vous pouvez y changer.';

	/// fr: 'Identité professionnelle'
	String get identite => 'Identité professionnelle';

	/// fr: 'C'est ce que les familles voient de vous. Il ne change jamais.'
	String get identifiantDetail => 'C\'est ce que les familles voient de vous. Il ne change jamais.';

	/// fr: 'Pays'
	String get pays => 'Pays';

	/// fr: 'Langues'
	String get langues => 'Langues';

	/// fr: 'Fuseau de mes cours'
	String get fuseau => 'Fuseau de mes cours';

	/// fr: 'C'est lui qui décide de l'heure de vos créneaux, pas l'heure de cet appareil.'
	String get fuseauDetail => 'C\'est lui qui décide de l\'heure de vos créneaux, pas l\'heure de cet appareil.';

	/// fr: 'Plafond hebdomadaire'
	String get plafond => 'Plafond hebdomadaire';

	/// fr: '{nombre} h par semaine'
	String plafondValeur({required Object nombre}) => '${nombre} h par semaine';

	/// fr: 'Fixé par l'académie.'
	String get plafondDetail => 'Fixé par l\'académie.';

	/// fr: 'Non renseigné'
	String get nonRenseigne => 'Non renseigné';

	/// fr: 'Statut du compte'
	String get statutSection => 'Statut du compte';

	/// fr: 'Vous pouvez enseigner, déclarer vos heures et recevoir des élèves.'
	String get statutValideDetail => 'Vous pouvez enseigner, déclarer vos heures et recevoir des élèves.';

	/// fr: 'Dossier en cours de vérification'
	String get statutEnAttente => 'Dossier en cours de vérification';

	/// fr: 'L'académie vérifie vos pièces. Vous n'avez rien de plus à faire.'
	String get statutEnAttenteDetail => 'L\'académie vérifie vos pièces. Vous n\'avez rien de plus à faire.';

	/// fr: 'Accès provisoire'
	String get statutProvisoire => 'Accès provisoire';

	/// fr: 'Vous enseignez déjà. Votre dossier reste à compléter, sans coupure automatique.'
	String get statutProvisoireDetail => 'Vous enseignez déjà. Votre dossier reste à compléter, sans coupure automatique.';

	/// fr: 'Compte suspendu'
	String get statutSuspendu => 'Compte suspendu';

	/// fr: 'Vous pouvez joindre l'académie pour connaître la marche à suivre.'
	String get statutSuspenduDetail => 'Vous pouvez joindre l\'académie pour connaître la marche à suivre.';

	/// fr: 'Statut non disponible'
	String get statutInconnu => 'Statut non disponible';

	/// fr: 'Nous n'avons pas pu lire votre statut. Il n'est pas supposé pour autant.'
	String get statutInconnuDetail => 'Nous n\'avons pas pu lire votre statut. Il n\'est pas supposé pour autant.';

	/// fr: 'Ce statut vient de changer. Rouvrez l'application pour que votre accès suive.'
	String get statutDivergent => 'Ce statut vient de changer. Rouvrez l\'application pour que votre accès suive.';

	/// fr: 'Vérification du dossier'
	String get verification => 'Vérification du dossier';

	/// fr: 'En attente'
	String get verificationEnAttente => 'En attente';

	/// fr: 'Validée'
	String get verificationValidee => 'Validée';

	/// fr: 'À reprendre'
	String get verificationRefusee => 'À reprendre';

	/// fr: 'Contrat et accusés'
	String get contratSection => 'Contrat et accusés';

	/// fr: 'Contrat enseignant'
	String get contratEnseignant => 'Contrat enseignant';

	/// fr: 'Conditions d'utilisation'
	String get contratConditions => 'Conditions d\'utilisation';

	/// fr: 'Enregistrement audio et visite de contrôle'
	String get contratAccuse => 'Enregistrement audio et visite de contrôle';

	/// fr: 'Version {version}, accepté le {date}'
	String contratDetail({required Object version, required Object date}) => 'Version ${version}, accepté le ${date}';

	/// fr: 'Aucun contrat enregistré'
	String get contratAucun => 'Aucun contrat enregistré';

	/// fr: 'Votre dossier n'est pas encore passé par la signature.'
	String get contratAucunDetail => 'Votre dossier n\'est pas encore passé par la signature.';

	/// fr: 'Vos contrats n'ont pas pu être lus.'
	String get contratErreur => 'Vos contrats n\'ont pas pu être lus.';

	/// fr: 'Ces pièces sont en lecture seule : un contrat qui s'édite depuis l'écran de la personne qu'il engage n'est plus un contrat.'
	String get contratLectureSeule => 'Ces pièces sont en lecture seule : un contrat qui s\'édite depuis l\'écran de la personne qu\'il engage n\'est plus un contrat.';

	/// fr: 'Mes réglages'
	String get personnel => 'Mes réglages';

	/// fr: 'Se déconnecter de cet appareil ?'
	String get deconnexionQuestion => 'Se déconnecter de cet appareil ?';

	/// fr: 'Me déconnecter maintenant'
	String get deconnexionConfirmer => 'Me déconnecter maintenant';

	/// fr: 'Votre journée, vos créneaux et vos cahiers restent enregistrés. Il faudra un nouveau lien de connexion pour revenir.'
	String get deconnexionConsequence => 'Votre journée, vos créneaux et vos cahiers restent enregistrés. Il faudra un nouveau lien de connexion pour revenir.';

	/// fr: 'Votre profil n'a pas pu être lu. Réessayez dans un instant.'
	String get erreur => 'Votre profil n\'a pas pu être lu. Réessayez dans un instant.';

	/// fr: 'Aucun profil enseignant'
	String get vide => 'Aucun profil enseignant';

	/// fr: 'Ce compte n'a pas de profil enseignant. Seule l'académie peut en créer un.'
	String get videDetail => 'Ce compte n\'a pas de profil enseignant. Seule l\'académie peut en créer un.';

	/// fr: 'Pas de réseau : rien ne peut être modifié ici pour l'instant.'
	String get horsLigne => 'Pas de réseau : rien ne peut être modifié ici pour l\'instant.';

	/// fr: 'Modifier le pays'
	String get modifierPays => 'Modifier le pays';

	/// fr: 'Modifier les langues'
	String get modifierLangues => 'Modifier les langues';

	/// fr: 'Séparez les langues par une virgule'
	String get languesIndice => 'Séparez les langues par une virgule';

	/// fr: 'Enregistrer'
	String get enregistrer => 'Enregistrer';

	/// fr: 'Modification enregistrée'
	String get enregistre => 'Modification enregistrée';

	/// fr: 'La modification n'a pas abouti. Réessayez dans un instant.'
	String get editionErreur => 'La modification n\'a pas abouti. Réessayez dans un instant.';
}

// Path: enseignant.creneaux
class Traductions$enseignant$creneaux$fr {
	Traductions$enseignant$creneaux$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: '{jour} {heure} h'
	String heureLibelle({required Object jour, required Object heure}) => '${jour} ${heure} h';

	/// fr: 'Vous n'avez proposé aucune heure. Sans créneau, aucune famille ne peut vous être proposée.'
	String get aucuneHeure => 'Vous n\'avez proposé aucune heure. Sans créneau, aucune famille ne peut vous être proposée.';

	/// fr: '{heure} enregistré'
	String heureEnregistree({required Object heure}) => '${heure} enregistré';

	/// fr: '{heure} retiré'
	String heureRetiree({required Object heure}) => '${heure} retiré';

	/// fr: '{heure} retiré. Le cours déjà attribué sur cette heure continue : demandez une réaffectation pour l'arrêter.'
	String retraitEngage({required Object heure}) => '${heure} retiré. Le cours déjà attribué sur cette heure continue : demandez une réaffectation pour l\'arrêter.';

	/// fr: 'Vos heures n'ont pas pu être lues'
	String get grilleErreur => 'Vos heures n\'ont pas pu être lues';

	/// fr: 'Le serveur n'a pas répondu. Les heures que vous avez déjà posées ne sont pas perdues.'
	String get grilleErreurDetail => 'Le serveur n\'a pas répondu. Les heures que vous avez déjà posées ne sont pas perdues.';

	/// fr: 'Sans réseau, vos heures restent consultables mais ne peuvent pas être modifiées.'
	String get horsLigneGrille => 'Sans réseau, vos heures restent consultables mais ne peuvent pas être modifiées.';

	/// fr: 'Vous avez déjà un élève sur {heures}. Retirer cette heure ne met pas fin au cours : il faut une réaffectation.'
	String heureEngagee({required Object heures}) => 'Vous avez déjà un élève sur ${heures}. Retirer cette heure ne met pas fin au cours : il faut une réaffectation.';

	/// fr: 'Vous avez déjà un élève sur {heures}. Retirer ces heures ne met pas fin aux cours : il faut une réaffectation.'
	String heuresEngagees({required Object heures}) => 'Vous avez déjà un élève sur ${heures}. Retirer ces heures ne met pas fin aux cours : il faut une réaffectation.';

	/// fr: 'Les familles en attente n'ont pas pu être lues'
	String get feedErreur => 'Les familles en attente n\'ont pas pu être lues';

	/// fr: 'Rien n'est perdu : personne n'a été pris, et vos heures restent posées.'
	String get feedErreurDetail => 'Rien n\'est perdu : personne n\'a été pris, et vos heures restent posées.';

	/// fr: 'Sans réseau, vous ne pouvez pas prendre d'élève. Les demandes ci-dessous restent consultables.'
	String get horsLignePrise => 'Sans réseau, vous ne pouvez pas prendre d\'élève. Les demandes ci-dessous restent consultables.';

	/// fr: 'Sans réseau, cette demande ne partirait pas. Réessayez au retour de la connexion.'
	String get horsLigneDemande => 'Sans réseau, cette demande ne partirait pas. Réessayez au retour de la connexion.';

	/// fr: 'Cet élève vient d'être pris par un autre enseignant. La liste ci-dessous est à jour.'
	String get refusDejaPris => 'Cet élève vient d\'être pris par un autre enseignant. La liste ci-dessous est à jour.';

	/// fr: 'Cet élève a déjà un enseignant. La liste ci-dessous est à jour.'
	String get refusDejaSuivi => 'Cet élève a déjà un enseignant. La liste ci-dessous est à jour.';

	/// fr: 'Cette famille ne propose plus ce créneau. La liste ci-dessous est à jour.'
	String get refusCreneauRetire => 'Cette famille ne propose plus ce créneau. La liste ci-dessous est à jour.';

	/// fr: 'Ce créneau ne figure plus dans vos heures. Reposez-le dans Mes heures pour pouvoir le prendre.'
	String get refusHorsMesHeures => 'Ce créneau ne figure plus dans vos heures. Reposez-le dans Mes heures pour pouvoir le prendre.';

	/// fr: 'Vous avez atteint votre maximum d'élèves. Demandez une augmentation pour en suivre un de plus.'
	String get refusPlafond => 'Vous avez atteint votre maximum d\'élèves. Demandez une augmentation pour en suivre un de plus.';
}

// Path: enseignant.ficheGroupe
class Traductions$enseignant$ficheGroupe$fr {
	Traductions$enseignant$ficheGroupe$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Fiche du groupe'
	String get titre => 'Fiche du groupe';

	/// fr: 'Retour à la journée'
	String get retour => 'Retour à la journée';

	/// fr: 'Le rendez-vous du groupe'
	String get creneauTitre => 'Le rendez-vous du groupe';

	/// fr: '{jour} à {heure}, chaque semaine'
	String creneauHebdo({required Object jour, required Object heure}) => '${jour} à ${heure}, chaque semaine';

	/// fr: 'Groupe complet'
	String get complet => 'Groupe complet';

	/// fr: 'places libres'
	String get placesLibres => 'places libres';

	/// fr: 'place libre'
	String get placesLibresUn => 'place libre';

	/// fr: 'Les élèves du groupe'
	String get membresTitre => 'Les élèves du groupe';

	/// fr: 'Niveau indiqué : {niveau}'
	String niveauIndique({required Object niveau}) => 'Niveau indiqué : ${niveau}';

	/// fr: 'Aucun élève dans ce groupe'
	String get aucunMembre => 'Aucun élève dans ce groupe';

	/// fr: 'L'administration compose les groupes : celui-ci n'a pas encore d'élève.'
	String get aucunMembreDetail => 'L\'administration compose les groupes : celui-ci n\'a pas encore d\'élève.';

	/// fr: 'Ce groupe n'a pas pu être lu. Réessayez dans un instant.'
	String get erreur => 'Ce groupe n\'a pas pu être lu. Réessayez dans un instant.';

	/// fr: 'Ce groupe n'est pas l'un des vôtres'
	String get introuvable => 'Ce groupe n\'est pas l\'un des vôtres';

	/// fr: 'Il a peut-être été clôturé, ou il appartient à un autre enseignant.'
	String get introuvableDetail => 'Il a peut-être été clôturé, ou il appartient à un autre enseignant.';

	/// fr: 'Ouvrir la revue du groupe'
	String get revue => 'Ouvrir la revue du groupe';
}

// Path: enseignant.revue
class Traductions$enseignant$revue$fr {
	Traductions$enseignant$revue$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Revue du groupe'
	String get titre => 'Revue du groupe';

	/// fr: 'Rien ne demande votre attention.'
	String get aucuneAnomalie => 'Rien ne demande votre attention.';

	/// fr: 'Le calcul des anomalies pédagogiques n'est pas encore ouvert aux enseignants : cette page reste vide jusque-là.'
	String get aucuneAnomalieDetail => 'Le calcul des anomalies pédagogiques n\'est pas encore ouvert aux enseignants : cette page reste vide jusque-là.';

	/// fr: 'La revue n'a pas pu être lue.'
	String get erreur => 'La revue n\'a pas pu être lue.';

	/// fr: 'Ce groupe n'est peut-être pas le vôtre, ou la lecture a échoué.'
	String get erreurDetail => 'Ce groupe n\'est peut-être pas le vôtre, ou la lecture a échoué.';

	/// fr: 'Vous signalez, l'académie tranche : un transfert et une réorientation ne se décident pas depuis ici.'
	String get pasDeDecision => 'Vous signalez, l\'académie tranche : un transfert et une réorientation ne se décident pas depuis ici.';

	/// fr: 'Palier à venir'
	String get typeGate => 'Palier à venir';

	/// fr: 'Élève hors corridor'
	String get typeCorridor => 'Élève hors corridor';

	/// fr: 'Proposition de transfert'
	String get typeTransfert => 'Proposition de transfert';

	/// fr: 'Proposition de réorientation'
	String get typeReorientation => 'Proposition de réorientation';
}

// Path: controleur.planning
class Traductions$controleur$planning$fr {
	Traductions$controleur$planning$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Planning global'
	String get titre => 'Planning global';

	/// fr: 'Votre entrée est enregistrée : votre nom, la séance, l'heure. Les participants, eux, ne vous voient pas.'
	String get visiteJournalisee => 'Votre entrée est enregistrée : votre nom, la séance, l\'heure. Les participants, eux, ne vous voient pas.';

	/// fr: 'Tout'
	String get tousEtats => 'Tout';

	/// fr: 'En cours'
	String get etatEnCours => 'En cours';

	/// fr: 'À venir'
	String get etatAVenir => 'À venir';

	/// fr: 'À vérifier'
	String get etatIncident => 'À vérifier';

	/// fr: 'Tous les enseignants'
	String get tousEnseignants => 'Tous les enseignants';

	/// fr: 'Enseignant'
	String get colonneEnseignant => 'Enseignant';

	/// fr: 'Élève'
	String get colonneEleve => 'Élève';

	/// fr: 'Heure locale'
	String get colonneHeure => 'Heure locale';

	/// fr: 'UTC'
	String get colonneUtc => 'UTC';

	/// fr: 'État'
	String get colonneEtat => 'État';

	/// fr: 'Entrée'
	String get colonneEntree => 'Entrée';

	/// fr: '{enseignant} et {eleve}'
	String avec({required Object enseignant, required Object eleve}) => '${enseignant} et ${eleve}';

	/// fr: '{debut} à {fin}'
	String plage({required Object debut, required Object fin}) => '${debut} à ${fin}';

	/// fr: '{jour} {debut} à {fin}'
	String plageAutreJour({required Object jour, required Object debut, required Object fin}) => '${jour} ${debut} à ${fin}';

	/// fr: '{debut} à {fin} UTC'
	String plageUtc({required Object debut, required Object fin}) => '${debut} à ${fin} UTC';

	/// fr: 'Observer'
	String get observer => 'Observer';

	/// fr: 'Entrée en cours'
	String get entree => 'Entrée en cours';

	/// fr: 'L'entrée n'a pas été accordée. La séance vient peut-être de se terminer.'
	String get entreeRefusee => 'L\'entrée n\'a pas été accordée. La séance vient peut-être de se terminer.';

	/// fr: 'Aucune séance en cours ni à venir'
	String get vide => 'Aucune séance en cours ni à venir';

	/// fr: 'Les cours programmés apparaîtront ici, du plus proche au plus lointain.'
	String get videDetail => 'Les cours programmés apparaîtront ici, du plus proche au plus lointain.';

	/// fr: 'Aucune séance ne correspond'
	String get videFiltre => 'Aucune séance ne correspond';

	/// fr: 'Relâchez un filtre pour retrouver le reste du planning.'
	String get videFiltreDetail => 'Relâchez un filtre pour retrouver le reste du planning.';

	/// fr: 'Tout afficher'
	String get effacerFiltres => 'Tout afficher';

	/// fr: 'Le planning n'a pas pu être lu. Réessayez dans un instant.'
	String get erreur => 'Le planning n\'a pas pu être lu. Réessayez dans un instant.';

	/// fr: 'Les {nombre} premières séances sont affichées.'
	String tronquee({required Object nombre}) => 'Les ${nombre} premières séances sont affichées.';

	/// fr: '{nombre} séances au planning.'
	String fin({required Object nombre}) => '${nombre} séances au planning.';

	/// fr: '1 séance au planning.'
	String get finUne => '1 séance au planning.';
}

// Path: tc.groupe
class Traductions$tc$groupe$fr {
	Traductions$tc$groupe$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations
	late final Traductions$tc$groupe$mesGroupes$fr mesGroupes = Traductions$tc$groupe$mesGroupes$fr.internal(_root);
	late final Traductions$tc$groupe$commun$fr commun = Traductions$tc$groupe$commun$fr.internal(_root);
	late final Traductions$tc$groupe$carte$fr carte = Traductions$tc$groupe$carte$fr.internal(_root);
	late final Traductions$tc$groupe$enseignant$fr enseignant = Traductions$tc$groupe$enseignant$fr.internal(_root);
	late final Traductions$tc$groupe$cours$fr cours = Traductions$tc$groupe$cours$fr.internal(_root);
	late final Traductions$tc$groupe$temps$fr temps = Traductions$tc$groupe$temps$fr.internal(_root);
	late final Traductions$tc$groupe$duree$fr duree = Traductions$tc$groupe$duree$fr.internal(_root);
	late final Traductions$tc$groupe$horloges$fr horloges = Traductions$tc$groupe$horloges$fr.internal(_root);
	late final Traductions$tc$groupe$dst$fr dst = Traductions$tc$groupe$dst$fr.internal(_root);
	late final Traductions$tc$groupe$session$fr session = Traductions$tc$groupe$session$fr.internal(_root);
	late final Traductions$tc$groupe$espace$fr espace = Traductions$tc$groupe$espace$fr.internal(_root);
	late final Traductions$tc$groupe$emplacement$fr emplacement = Traductions$tc$groupe$emplacement$fr.internal(_root);
}

// Path: tc.bibliotheque
class Traductions$tc$bibliotheque$fr {
	Traductions$tc$bibliotheque$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Bibliothèque'
	String get titre => 'Bibliothèque';

	/// fr: 'Titre, niveau, sourate ou page'
	String get rechercheIndication => 'Titre, niveau, sourate ou page';

	/// fr: 'Rechercher un support'
	String get rechercheLibelle => 'Rechercher un support';

	/// fr: 'Tout afficher'
	String get effacerRecherche => 'Tout afficher';

	late final Traductions$tc$bibliotheque$filtre$fr filtre = Traductions$tc$bibliotheque$filtre$fr.internal(_root);
	late final Traductions$tc$bibliotheque$sections$fr sections = Traductions$tc$bibliotheque$sections$fr.internal(_root);
	late final Traductions$tc$bibliotheque$vide$fr vide = Traductions$tc$bibliotheque$vide$fr.internal(_root);
	late final Traductions$tc$bibliotheque$aucunResultat$fr aucunResultat = Traductions$tc$bibliotheque$aucunResultat$fr.internal(_root);
	late final Traductions$tc$bibliotheque$indisponible$fr indisponible = Traductions$tc$bibliotheque$indisponible$fr.internal(_root);
	late final Traductions$tc$bibliotheque$introuvable$fr introuvable = Traductions$tc$bibliotheque$introuvable$fr.internal(_root);
	late final Traductions$tc$bibliotheque$offline$fr offline = Traductions$tc$bibliotheque$offline$fr.internal(_root);
	late final Traductions$tc$bibliotheque$type$fr type = Traductions$tc$bibliotheque$type$fr.internal(_root);
	late final Traductions$tc$bibliotheque$detail$fr detail = Traductions$tc$bibliotheque$detail$fr.internal(_root);
	late final Traductions$tc$bibliotheque$action$fr action = Traductions$tc$bibliotheque$action$fr.internal(_root);
	late final Traductions$tc$bibliotheque$message$fr message = Traductions$tc$bibliotheque$message$fr.internal(_root);
	late final Traductions$tc$bibliotheque$classe$fr classe = Traductions$tc$bibliotheque$classe$fr.internal(_root);
}

// Path: tc.coran
class Traductions$tc$coran$fr {
	Traductions$tc$coran$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations
	late final Traductions$tc$coran$modes$fr modes = Traductions$tc$coran$modes$fr.internal(_root);
	late final Traductions$tc$coran$mushaf$fr mushaf = Traductions$tc$coran$mushaf$fr.internal(_root);
	late final Traductions$tc$coran$fidelite$fr fidelite = Traductions$tc$coran$fidelite$fr.internal(_root);
	late final Traductions$tc$coran$zoom$fr zoom = Traductions$tc$coran$zoom$fr.internal(_root);
	late final Traductions$tc$coran$navigation$fr navigation = Traductions$tc$coran$navigation$fr.internal(_root);
	late final Traductions$tc$coran$reprise$fr reprise = Traductions$tc$coran$reprise$fr.internal(_root);
	late final Traductions$tc$coran$focus$fr focus = Traductions$tc$coran$focus$fr.internal(_root);
}

// Path: tc.outils
class Traductions$tc$outils$fr {
	Traductions$tc$outils$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations
	late final Traductions$tc$outils$dock$fr dock = Traductions$tc$outils$dock$fr.internal(_root);
	late final Traductions$tc$outils$intention$fr intention = Traductions$tc$outils$intention$fr.internal(_root);
	late final Traductions$tc$outils$trait$fr trait = Traductions$tc$outils$trait$fr.internal(_root);
	late final Traductions$tc$outils$portee$fr portee = Traductions$tc$outils$portee$fr.internal(_root);
	late final Traductions$tc$outils$marquer$fr marquer = Traductions$tc$outils$marquer$fr.internal(_root);
	late final Traductions$tc$outils$revision$fr revision = Traductions$tc$outils$revision$fr.internal(_root);
	late final Traductions$tc$outils$masquer$fr masquer = Traductions$tc$outils$masquer$fr.internal(_root);
	late final Traductions$tc$outils$focus$fr focus = Traductions$tc$outils$focus$fr.internal(_root);
	late final Traductions$tc$outils$annotation$fr annotation = Traductions$tc$outils$annotation$fr.internal(_root);
}

// Path: tc.classe
class Traductions$tc$classe$fr {
	Traductions$tc$classe$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations
	late final Traductions$tc$classe$entete$fr entete = Traductions$tc$classe$entete$fr.internal(_root);
	late final Traductions$tc$classe$roster$fr roster = Traductions$tc$classe$roster$fr.internal(_root);
	late final Traductions$tc$classe$etat$fr etat = Traductions$tc$classe$etat$fr.internal(_root);
	late final Traductions$tc$classe$fiche$fr fiche = Traductions$tc$classe$fiche$fr.internal(_root);
	late final Traductions$tc$classe$action$fr action = Traductions$tc$classe$action$fr.internal(_root);
	late final Traductions$tc$classe$rappel$fr rappel = Traductions$tc$classe$rappel$fr.internal(_root);
	late final Traductions$tc$classe$recitation$fr recitation = Traductions$tc$classe$recitation$fr.internal(_root);
	late final Traductions$tc$classe$support$fr support = Traductions$tc$classe$support$fr.internal(_root);
	late final Traductions$tc$classe$commandes$fr commandes = Traductions$tc$classe$commandes$fr.internal(_root);
	late final Traductions$tc$classe$scene$fr scene = Traductions$tc$classe$scene$fr.internal(_root);
	late final Traductions$tc$classe$reseau$fr reseau = Traductions$tc$classe$reseau$fr.internal(_root);
	late final Traductions$tc$classe$attente$fr attente = Traductions$tc$classe$attente$fr.internal(_root);
	late final Traductions$tc$classe$lien$fr lien = Traductions$tc$classe$lien$fr.internal(_root);
	late final Traductions$tc$classe$barre$fr barre = Traductions$tc$classe$barre$fr.internal(_root);
	late final Traductions$tc$classe$prevol$fr prevol = Traductions$tc$classe$prevol$fr.internal(_root);
	late final Traductions$tc$classe$observation$fr observation = Traductions$tc$classe$observation$fr.internal(_root);
}

// Path: tc.realtime
class Traductions$tc$realtime$fr {
	Traductions$tc$realtime$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations
	late final Traductions$tc$realtime$transport$fr transport = Traductions$tc$realtime$transport$fr.internal(_root);
	late final Traductions$tc$realtime$etat$fr etat = Traductions$tc$realtime$etat$fr.internal(_root);
}

// Path: tc.observation
class Traductions$tc$observation$fr {
	Traductions$tc$observation$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations
	late final Traductions$tc$observation$entree$fr entree = Traductions$tc$observation$entree$fr.internal(_root);
	late final Traductions$tc$observation$refus$fr refus = Traductions$tc$observation$refus$fr.internal(_root);
	late final Traductions$tc$observation$visite$fr visite = Traductions$tc$observation$visite$fr.internal(_root);
	late final Traductions$tc$observation$fin$fr fin = Traductions$tc$observation$fin$fr.internal(_root);
	late final Traductions$tc$observation$annonce$fr annonce = Traductions$tc$observation$annonce$fr.internal(_root);
	late final Traductions$tc$observation$reglages$fr reglages = Traductions$tc$observation$reglages$fr.internal(_root);
}

// Path: tc.parcours
class Traductions$tc$parcours$fr {
	Traductions$tc$parcours$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations
	late final Traductions$tc$parcours$avant$fr avant = Traductions$tc$parcours$avant$fr.internal(_root);
	late final Traductions$tc$parcours$intention$fr intention = Traductions$tc$parcours$intention$fr.internal(_root);
	late final Traductions$tc$parcours$plage$fr plage = Traductions$tc$parcours$plage$fr.internal(_root);
	late final Traductions$tc$parcours$feedback$fr feedback = Traductions$tc$parcours$feedback$fr.internal(_root);
	late final Traductions$tc$parcours$signalement$fr signalement = Traductions$tc$parcours$signalement$fr.internal(_root);
	late final Traductions$tc$parcours$postCours$fr postCours = Traductions$tc$parcours$postCours$fr.internal(_root);
}

// Path: commun.etats.chargementProlonge
class Traductions$commun$etats$chargementProlonge$fr {
	Traductions$commun$etats$chargementProlonge$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'La connexion prend plus de temps que prévu'
	String get titre => 'La connexion prend plus de temps que prévu';

	/// fr: 'Vous pouvez patienter encore un peu ou réessayer.'
	String get phrase => 'Vous pouvez patienter encore un peu ou réessayer.';
}

// Path: commun.etats.horsLigne
class Traductions$commun$etats$horsLigne$fr {
	Traductions$commun$etats$horsLigne$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Vous êtes hors ligne'
	String get titre => 'Vous êtes hors ligne';

	/// fr: 'Vérifiez votre connexion. Ce qui est déjà affiché reste consultable.'
	String get phrase => 'Vérifiez votre connexion. Ce qui est déjà affiché reste consultable.';
}

// Path: commun.etats.reconnexion
class Traductions$commun$etats$reconnexion$fr {
	Traductions$commun$etats$reconnexion$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Reconnexion en cours'
	String get titre => 'Reconnexion en cours';

	/// fr: 'Une nouvelle tentative de connexion est en cours.'
	String get phrase => 'Une nouvelle tentative de connexion est en cours.';
}

// Path: commun.etats.echecServeur
class Traductions$commun$etats$echecServeur$fr {
	Traductions$commun$etats$echecServeur$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Impossible de charger ces informations'
	String get titre => 'Impossible de charger ces informations';

	/// fr: 'Le chargement n'a pas abouti. Réessayez dans un instant.'
	String get phrase => 'Le chargement n\'a pas abouti. Réessayez dans un instant.';
}

// Path: commun.etats.introuvable
class Traductions$commun$etats$introuvable$fr {
	Traductions$commun$etats$introuvable$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Cette page est introuvable'
	String get titre => 'Cette page est introuvable';

	/// fr: 'Le lien est peut-être incomplet, ou la page n'existe plus.'
	String get phrase => 'Le lien est peut-être incomplet, ou la page n\'existe plus.';
}

// Path: commun.etats.accesRefuse
class Traductions$commun$etats$accesRefuse$fr {
	Traductions$commun$etats$accesRefuse$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Vous n'avez pas accès à cette page'
	String get titre => 'Vous n\'avez pas accès à cette page';

	/// fr: 'Ce contenu n'est pas ouvert à votre compte.'
	String get phrase => 'Ce contenu n\'est pas ouvert à votre compte.';
}

// Path: commun.etats.sessionExpiree
class Traductions$commun$etats$sessionExpiree$fr {
	Traductions$commun$etats$sessionExpiree$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Votre session a expiré'
	String get titre => 'Votre session a expiré';

	/// fr: 'Reconnectez-vous pour continuer.'
	String get phrase => 'Reconnectez-vous pour continuer.';
}

// Path: commun.etats.dossierEnAttente
class Traductions$commun$etats$dossierEnAttente$fr {
	Traductions$commun$etats$dossierEnAttente$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Votre dossier est en attente'
	String get titre => 'Votre dossier est en attente';

	/// fr: 'Une étape reste à franchir avant d'ouvrir cet espace.'
	String get phrase => 'Une étape reste à franchir avant d\'ouvrir cet espace.';
}

// Path: commun.etats.aucunResultat
class Traductions$commun$etats$aucunResultat$fr {
	Traductions$commun$etats$aucunResultat$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Aucun résultat'
	String get titre => 'Aucun résultat';

	/// fr: 'Rien ne correspond pour le moment.'
	String get phrase => 'Rien ne correspond pour le moment.';
}

// Path: commun.etats.permissionRefusee
class Traductions$commun$etats$permissionRefusee$fr {
	Traductions$commun$etats$permissionRefusee$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Autorisation refusée'
	String get titre => 'Autorisation refusée';

	/// fr: 'Sans cette autorisation, cette fonction ne peut pas s'ouvrir. Vous pouvez la modifier dans les réglages de votre appareil.'
	String get phrase => 'Sans cette autorisation, cette fonction ne peut pas s\'ouvrir. Vous pouvez la modifier dans les réglages de votre appareil.';
}

// Path: commun.etats.ressourceExpiree
class Traductions$commun$etats$ressourceExpiree$fr {
	Traductions$commun$etats$ressourceExpiree$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Ce contenu n'est plus disponible'
	String get titre => 'Ce contenu n\'est plus disponible';

	/// fr: 'Il a été retiré, ou son accès a pris fin.'
	String get phrase => 'Il a été retiré, ou son accès a pris fin.';
}

// Path: commun.etats.indisponible
class Traductions$commun$etats$indisponible$fr {
	Traductions$commun$etats$indisponible$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Pas encore disponible'
	String get titre => 'Pas encore disponible';

	/// fr: 'Cette fonction n'est pas encore ouverte.'
	String get phrase => 'Cette fonction n\'est pas encore ouverte.';
}

// Path: commun.etats.actions
class Traductions$commun$etats$actions$fr {
	Traductions$commun$etats$actions$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Réessayer'
	String get reessayer => 'Réessayer';

	/// fr: 'Retour à l'accueil'
	String get retourAccueil => 'Retour à l\'accueil';

	/// fr: 'Se connecter'
	String get seConnecter => 'Se connecter';

	/// fr: 'Se reconnecter'
	String get seReconnecter => 'Se reconnecter';

	/// fr: 'Voir mon dossier'
	String get voirDossier => 'Voir mon dossier';

	/// fr: 'Réinitialiser les filtres'
	String get reinitialiserFiltres => 'Réinitialiser les filtres';

	/// fr: 'Revenir en arrière'
	String get revenir => 'Revenir en arrière';
}

// Path: admin.journal.evenements
class Traductions$admin$journal$evenements$fr {
	Traductions$admin$journal$evenements$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Visite d'observation commencée'
	String get observationEntree => 'Visite d\'observation commencée';

	/// fr: 'Visite d'observation terminée'
	String get observationSortie => 'Visite d\'observation terminée';

	/// fr: 'Règles d'observation du groupe modifiées'
	String get observationPolitiqueGroupeModifiee => 'Règles d\'observation du groupe modifiées';
}

// Path: tuteur.accueil.etatCourt
class Traductions$tuteur$accueil$etatCourt$fr {
	Traductions$tuteur$accueil$etatCourt$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'En direct'
	String get enDirect => 'En direct';

	/// fr: 'Salle ouverte'
	String get salleOuverte => 'Salle ouverte';

	/// fr: 'Dans {minutes} min'
	String dansMinutes({required Object minutes}) => 'Dans ${minutes} min';

	/// fr: 'Dans {heures} h {minutes}'
	String dansHeures({required Object heures, required Object minutes}) => 'Dans ${heures} h ${minutes}';

	/// fr: 'Dans {jours} j'
	String dansJours({required Object jours}) => 'Dans ${jours} j';

	/// fr: 'Séance prévue'
	String get prevue => 'Séance prévue';

	/// fr: 'Séance annulée'
	String get annulee => 'Séance annulée';

	/// fr: 'Séance non tenue'
	String get nonTenue => 'Séance non tenue';

	/// fr: 'Séance terminée'
	String get terminee => 'Séance terminée';

	/// fr: 'Aucune séance'
	String get aucune => 'Aucune séance';

	/// fr: 'Non disponible'
	String get illisible => 'Non disponible';
}

// Path: classe.observation.motif
class Traductions$classe$observation$motif$fr {
	Traductions$classe$observation$motif$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Vous avez utilisé vos visites pour cette séance.'
	String get visitesEpuisees => 'Vous avez utilisé vos visites pour cette séance.';

	/// fr: 'Votre temps d'observation est épuisé pour cette séance.'
	String get tempsEpuise => 'Votre temps d\'observation est épuisé pour cette séance.';

	/// fr: 'L'observation ouvre quand la séance commence.'
	String get seanceNonCommencee => 'L\'observation ouvre quand la séance commence.';

	/// fr: 'La séance est terminée.'
	String get seanceTerminee => 'La séance est terminée.';

	/// fr: 'Cette séance n'a pas lieu : il n'y a rien à observer.'
	String get seanceNonTenue => 'Cette séance n\'a pas lieu : il n\'y a rien à observer.';

	/// fr: 'La salle n'est pas ouverte à cette heure.'
	String get horsFenetre => 'La salle n\'est pas ouverte à cette heure.';

	/// fr: 'L'observation est fermée pour cette classe.'
	String get observationDesactivee => 'L\'observation est fermée pour cette classe.';

	/// fr: 'Aucun élève de votre foyer n'est rattaché à cette séance.'
	String get lienAbsent => 'Aucun élève de votre foyer n\'est rattaché à cette séance.';

	/// fr: 'L'observation attend l'arrivée de {prenom}.'
	String enfantAbsent({required Object prenom}) => 'L\'observation attend l\'arrivée de ${prenom}.';

	/// fr: 'La présence de {prenom} est en cours de vérification.'
	String presenceEnVerification({required Object prenom}) => 'La présence de ${prenom} est en cours de vérification.';

	/// fr: 'Une visite est déjà ouverte, sur cet appareil ou sur un autre.'
	String get visiteDejaOuverte => 'Une visite est déjà ouverte, sur cet appareil ou sur un autre.';

	/// fr: 'L'observation des séances n'est pas encore ouverte.'
	String get garantieServeurAbsente => 'L\'observation des séances n\'est pas encore ouverte.';

	/// fr: 'La disponibilité de l'observation n'a pas pu être vérifiée.'
	String get reseau => 'La disponibilité de l\'observation n\'a pas pu être vérifiée.';

	/// fr: 'L'observation n'est pas disponible pour le moment.'
	String get capaciteAbsente => 'L\'observation n\'est pas disponible pour le moment.';
}

// Path: classe.pageTravail.statut
class Traductions$classe$pageTravail$statut$fr {
	Traductions$classe$pageTravail$statut$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'À faire'
	String get aFaire => 'À faire';

	/// fr: 'Commencé'
	String get enCours => 'Commencé';

	/// fr: 'Fait'
	String get fait => 'Fait';

	/// fr: 'Échéance passée'
	String get expire => 'Échéance passée';
}

// Path: tc.groupe.mesGroupes
class Traductions$tc$groupe$mesGroupes$fr {
	Traductions$tc$groupe$mesGroupes$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Mes groupes'
	String get titre => 'Mes groupes';

	/// fr: 'Aucun groupe pour le moment'
	String get aucun => 'Aucun groupe pour le moment';

	/// fr: 'L'académie vous placera dans un groupe dès qu'un créneau vous correspond.'
	String get aucunDetail => 'L\'académie vous placera dans un groupe dès qu\'un créneau vous correspond.';
}

// Path: tc.groupe.commun
class Traductions$tc$groupe$commun$fr {
	Traductions$tc$groupe$commun$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Vos groupes n'ont pas pu être lus'
	String get erreur => 'Vos groupes n\'ont pas pu être lus';

	/// fr: 'Réessayer'
	String get reessayer => 'Réessayer';
}

// Path: tc.groupe.carte
class Traductions$tc$groupe$carte$fr {
	Traductions$tc$groupe$carte$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Ouvrir le groupe {libelle}'
	String ouvrir({required Object libelle}) => 'Ouvrir le groupe ${libelle}';

	/// fr: '{membres} / {seuil}'
	String capacite({required Object membres, required Object seuil}) => '${membres} / ${seuil}';

	/// fr: '{membres} élèves sur {seuil} places'
	String capacitePhrase({required Object membres, required Object seuil}) => '${membres} élèves sur ${seuil} places';

	/// fr: 'Complet'
	String get complet => 'Complet';

	/// fr: 'Prochain cours'
	String get prochainCours => 'Prochain cours';

	/// fr: 'Aucune séance planifiée'
	String get aucuneSeance => 'Aucune séance planifiée';

	/// fr: 'Le planning de ce groupe n'est pas encore posé.'
	String get aucuneSeanceDetail => 'Le planning de ce groupe n\'est pas encore posé.';

	/// fr: 'Durée {valeur}'
	String duree({required Object valeur}) => 'Durée ${valeur}';

	/// fr: 'Durée'
	String get dureeLibelle => 'Durée';

	/// fr: 'Rejoindre'
	String get rejoindre => 'Rejoindre';
}

// Path: tc.groupe.enseignant
class Traductions$tc$groupe$enseignant$fr {
	Traductions$tc$groupe$enseignant$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Sayyid'
	String get sayyid => 'Sayyid';

	/// fr: 'Sayyida'
	String get sayyida => 'Sayyida';

	/// fr: 'Photo à fournir'
	String get photoManquante => 'Photo à fournir';

	/// fr: 'La photo de l'enseignant n'a pas encore été enregistrée.'
	String get photoManquanteDetail => 'La photo de l\'enseignant n\'a pas encore été enregistrée.';
}

// Path: tc.groupe.cours
class Traductions$tc$groupe$cours$fr {
	Traductions$tc$groupe$cours$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: '{cours} · {niveau}'
	String coursEtNiveau({required Object cours, required Object niveau}) => '${cours} · ${niveau}';
}

// Path: tc.groupe.temps
class Traductions$tc$groupe$temps$fr {
	Traductions$tc$groupe$temps$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Cours dans {minutes} min'
	String dansMinutes({required Object minutes}) => 'Cours dans ${minutes} min';

	/// fr: 'Cours dans {heures} h {minutes}'
	String dansHeures({required Object heures, required Object minutes}) => 'Cours dans ${heures} h ${minutes}';

	/// fr: 'Cours imminent'
	String get imminent => 'Cours imminent';

	/// fr: 'Salle ouverte · {reste}'
	String salleOuverte({required Object reste}) => 'Salle ouverte · ${reste}';

	/// fr: 'Salle ouverte'
	String get salleOuverteCourt => 'Salle ouverte';

	/// fr: 'Vous êtes dans la salle. Le cours n'a pas encore commencé.'
	String get attente => 'Vous êtes dans la salle. Le cours n\'a pas encore commencé.';

	/// fr: 'Ce temps d'attente ne compte pas dans votre présence.'
	String get attenteDetail => 'Ce temps d\'attente ne compte pas dans votre présence.';

	/// fr: 'En salle'
	String get enSalle => 'En salle';

	/// fr: 'Reste {minutes} min'
	String resteMinutes({required Object minutes}) => 'Reste ${minutes} min';

	/// fr: 'Reste {heures} h {minutes}'
	String resteHeures({required Object heures, required Object minutes}) => 'Reste ${heures} h ${minutes}';

	/// fr: 'Séance en direct · {reste}'
	String enCours({required Object reste}) => 'Séance en direct · ${reste}';

	/// fr: 'En direct'
	String get enDirect => 'En direct';

	/// fr: 'Séance toujours en direct'
	String get prolongee => 'Séance toujours en direct';

	/// fr: 'En dépassement'
	String get depassement => 'En dépassement';

	/// fr: 'Cours terminé'
	String get terminee => 'Cours terminé';
}

// Path: tc.groupe.duree
class Traductions$tc$groupe$duree$fr {
	Traductions$tc$groupe$duree$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: '{minutes} min'
	String minutes({required Object minutes}) => '${minutes} min';

	/// fr: '{heures} h'
	String heures({required Object heures}) => '${heures} h';

	/// fr: '{heures} h {minutes}'
	String heuresMinutes({required Object heures, required Object minutes}) => '${heures} h ${minutes}';
}

// Path: tc.groupe.horloges
class Traductions$tc$groupe$horloges$fr {
	Traductions$tc$groupe$horloges$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Votre heure'
	String get votreHeure => 'Votre heure';

	/// fr: 'Chez {nomme}'
	String chezEnseignant({required Object nomme}) => 'Chez ${nomme}';

	/// fr: 'Heure du groupe'
	String get heureGroupe => 'Heure du groupe';

	/// fr: '{heure} {ville}'
	String heureEtVille({required Object heure, required Object ville}) => '${heure} ${ville}';
}

// Path: tc.groupe.dst
class Traductions$tc$groupe$dst$fr {
	Traductions$tc$groupe$dst$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Changement d'heure dans un mois'
	String get j30 => 'Changement d\'heure dans un mois';

	/// fr: 'Changement d'heure la semaine prochaine'
	String get j7 => 'Changement d\'heure la semaine prochaine';

	/// fr: 'Changement d'heure demain'
	String get j1 => 'Changement d\'heure demain';

	/// fr: 'Votre cours passera de {avant} à {apres}.'
	String detail({required Object avant, required Object apres}) => 'Votre cours passera de ${avant} à ${apres}.';
}

// Path: tc.groupe.session
class Traductions$tc$groupe$session$fr {
	Traductions$tc$groupe$session$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Tablette ou ordinateur conseillé pour le cours. Le téléphone reste pris en charge.'
	String get conseilAppareil => 'Tablette ou ordinateur conseillé pour le cours. Le téléphone reste pris en charge.';
}

// Path: tc.groupe.espace
class Traductions$tc$groupe$espace$fr {
	Traductions$tc$groupe$espace$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Mes groupes'
	String get retour => 'Mes groupes';

	/// fr: 'Avant le prochain cours'
	String get avantProchainCours => 'Avant le prochain cours';

	/// fr: 'Rien à préparer pour l'instant'
	String get aucuneAction => 'Rien à préparer pour l\'instant';

	/// fr: 'Bibliothèque'
	String get bibliotheque => 'Bibliothèque';

	/// fr: 'Voir tout'
	String get bibliothequeVoirTout => 'Voir tout';

	/// fr: 'Progression'
	String get progression => 'Progression';

	/// fr: 'Élèves du groupe'
	String get roster => 'Élèves du groupe';

	/// fr: 'Reprendre le cours'
	String get reprendreLeCours => 'Reprendre le cours';

	/// fr: 'Ce groupe ne vous est pas ouvert'
	String get introuvable => 'Ce groupe ne vous est pas ouvert';

	/// fr: 'Il a peut-être été clôturé, ou il appartient à une autre classe.'
	String get introuvableDetail => 'Il a peut-être été clôturé, ou il appartient à une autre classe.';
}

// Path: tc.groupe.emplacement
class Traductions$tc$groupe$emplacement$fr {
	Traductions$tc$groupe$emplacement$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Bientôt disponible'
	String get nonBranche => 'Bientôt disponible';

	/// fr: 'Ce contenu sera rattaché à cet espace prochainement.'
	String get nonBrancheDetail => 'Ce contenu sera rattaché à cet espace prochainement.';
}

// Path: tc.bibliotheque.filtre
class Traductions$tc$bibliotheque$filtre$fr {
	Traductions$tc$bibliotheque$filtre$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Type'
	String get type => 'Type';

	/// fr: 'Disponibilité'
	String get disponibilite => 'Disponibilité';
}

// Path: tc.bibliotheque.sections
class Traductions$tc$bibliotheque$sections$fr {
	Traductions$tc$bibliotheque$sections$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Continuer'
	String get continuer => 'Continuer';

	/// fr: 'Pour ce groupe'
	String get pourCeGroupe => 'Pour ce groupe';

	/// fr: 'Récents'
	String get recents => 'Récents';

	/// fr: 'Tous les supports'
	String get tousLesSupports => 'Tous les supports';

	/// fr: 'Résultats'
	String get resultats => 'Résultats';
}

// Path: tc.bibliotheque.vide
class Traductions$tc$bibliotheque$vide$fr {
	Traductions$tc$bibliotheque$vide$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Aucun support publié pour le moment'
	String get message => 'Aucun support publié pour le moment';

	/// fr: 'Vos enseignants déposeront ici les supports de vos cours.'
	String get invitation => 'Vos enseignants déposeront ici les supports de vos cours.';
}

// Path: tc.bibliotheque.aucunResultat
class Traductions$tc$bibliotheque$aucunResultat$fr {
	Traductions$tc$bibliotheque$aucunResultat$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Aucun support ne correspond'
	String get message => 'Aucun support ne correspond';

	/// fr: 'Essayez un autre mot, ou relâchez les filtres.'
	String get invitation => 'Essayez un autre mot, ou relâchez les filtres.';
}

// Path: tc.bibliotheque.indisponible
class Traductions$tc$bibliotheque$indisponible$fr {
	Traductions$tc$bibliotheque$indisponible$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'La bibliothèque est momentanément indisponible'
	String get message => 'La bibliothèque est momentanément indisponible';

	/// fr: 'Réessayer'
	String get action => 'Réessayer';
}

// Path: tc.bibliotheque.introuvable
class Traductions$tc$bibliotheque$introuvable$fr {
	Traductions$tc$bibliotheque$introuvable$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Ce support ne vous est pas ouvert'
	String get message => 'Ce support ne vous est pas ouvert';

	/// fr: 'Il a peut-être été retiré, ou il est réservé à un autre groupe. Votre enseignant peut vous le rouvrir.'
	String get invitation => 'Il a peut-être été retiré, ou il est réservé à un autre groupe. Votre enseignant peut vous le rouvrir.';
}

// Path: tc.bibliotheque.offline
class Traductions$tc$bibliotheque$offline$fr {
	Traductions$tc$bibliotheque$offline$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'À télécharger'
	String get aTelecharger => 'À télécharger';

	/// fr: 'Téléchargement'
	String get enCours => 'Téléchargement';

	/// fr: 'En cache'
	String get enCache => 'En cache';

	/// fr: 'Téléchargé'
	String get telecharge => 'Téléchargé';

	/// fr: 'Hors ligne indisponible'
	String get indisponible => 'Hors ligne indisponible';
}

// Path: tc.bibliotheque.type
class Traductions$tc$bibliotheque$type$fr {
	Traductions$tc$bibliotheque$type$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Coran'
	String get quran => 'Coran';

	/// fr: 'Texte'
	String get texteStructure => 'Texte';

	/// fr: 'PDF'
	String get pdf => 'PDF';

	/// fr: 'Image'
	String get image => 'Image';

	/// fr: 'Leçon'
	String get lecon => 'Leçon';
}

// Path: tc.bibliotheque.detail
class Traductions$tc$bibliotheque$detail$fr {
	Traductions$tc$bibliotheque$detail$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Support'
	String get titre => 'Support';

	/// fr: 'Ce que ce support permet'
	String get capacites => 'Ce que ce support permet';

	/// fr: 'Niveaux'
	String get niveaux => 'Niveaux';

	/// fr: 'Aucune version publiée : rien à ouvrir pour le moment.'
	String get sansVersion => 'Aucune version publiée : rien à ouvrir pour le moment.';

	/// fr: 'L’aperçu de ce format n’est pas encore disponible dans l’application. Vous pouvez en enregistrer une copie.'
	String get apercuIndisponible => 'L’aperçu de ce format n’est pas encore disponible dans l’application. Vous pouvez en enregistrer une copie.';

	/// fr: 'Le Coran s’ouvre dans le lecteur dédié.'
	String get renduCoran => 'Le Coran s’ouvre dans le lecteur dédié.';
}

// Path: tc.bibliotheque.action
class Traductions$tc$bibliotheque$action$fr {
	Traductions$tc$bibliotheque$action$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Rendre disponible hors ligne'
	String get telecharger => 'Rendre disponible hors ligne';

	/// fr: 'Libérer la place'
	String get liberer => 'Libérer la place';

	/// fr: 'Enregistrer une copie'
	String get enregistrerCopie => 'Enregistrer une copie';
}

// Path: tc.bibliotheque.message
class Traductions$tc$bibliotheque$message$fr {
	Traductions$tc$bibliotheque$message$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Copie enregistrée'
	String get copieEnregistree => 'Copie enregistrée';

	/// fr: 'Cette copie n’est pas disponible pour le moment'
	String get copieImpossible => 'Cette copie n’est pas disponible pour le moment';

	/// fr: 'Ce support n’est pas encore disponible hors ligne'
	String get telechargementImpossible => 'Ce support n’est pas encore disponible hors ligne';

	/// fr: 'Disponible une fois téléchargé ou de retour en ligne'
	String get horsLigneNonTelecharge => 'Disponible une fois téléchargé ou de retour en ligne';

	/// fr: 'Aucun fichier à télécharger pour cette version.'
	String get aucunTelechargement => 'Aucun fichier à télécharger pour cette version.';
}

// Path: tc.bibliotheque.classe
class Traductions$tc$bibliotheque$classe$fr {
	Traductions$tc$bibliotheque$classe$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Choisir un support'
	String get titre => 'Choisir un support';

	/// fr: 'Le support choisi remplace celui affiché. Le cours continue.'
	String get sousTitre => 'Le support choisi remplace celui affiché. Le cours continue.';
}

// Path: tc.coran.modes
class Traductions$tc$coran$modes$fr {
	Traductions$tc$coran$modes$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Page du mushaf'
	String get mushaf => 'Page du mushaf';

	/// fr: 'Lecture agrandie'
	String get verset => 'Lecture agrandie';

	/// fr: 'Focus'
	String get focus => 'Focus';

	/// fr: 'Mode de lecture'
	String get choisir => 'Mode de lecture';
}

// Path: tc.coran.mushaf
class Traductions$tc$coran$mushaf$fr {
	Traductions$tc$coran$mushaf$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Page de droite'
	String get coteDroite => 'Page de droite';

	/// fr: 'Page de gauche'
	String get coteGauche => 'Page de gauche';

	/// fr: 'Ouverture, pages {droite} et {gauche}'
	String ouverture({required Object droite, required Object gauche}) => 'Ouverture, pages ${droite} et ${gauche}';
}

// Path: tc.coran.fidelite
class Traductions$tc$coran$fidelite$fr {
	Traductions$tc$coran$fidelite$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Composition approchée'
	String get approchee => 'Composition approchée';

	/// fr: 'Les versets de cette page sont exactement ceux de la page du Mushaf de Médine. Leur répartition sur les lignes, elle, est celle de cet écran : le découpage en lignes de l'édition n'est pas encore importé.'
	String get approcheeDetail => 'Les versets de cette page sont exactement ceux de la page du Mushaf de Médine. Leur répartition sur les lignes, elle, est celle de cet écran : le découpage en lignes de l\'édition n\'est pas encore importé.';

	/// fr: 'Composition de l'édition'
	String get fidele => 'Composition de l\'édition';
}

// Path: tc.coran.zoom
class Traductions$tc$coran$zoom$fr {
	Traductions$tc$coran$zoom$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Grossissement limité par la largeur : au-delà, un mot serait coupé.'
	String get bride => 'Grossissement limité par la largeur : au-delà, un mot serait coupé.';

	/// fr: '{pourcent} %'
	String valeur({required Object pourcent}) => '${pourcent} %';

	/// fr: 'Pour grossir le texte, passez en lecture agrandie : la page du mushaf garde sa géométrie.'
	String get renvoiLectureAgrandie => 'Pour grossir le texte, passez en lecture agrandie : la page du mushaf garde sa géométrie.';
}

// Path: tc.coran.navigation
class Traductions$tc$coran$navigation$fr {
	Traductions$tc$coran$navigation$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Aller à'
	String get titre => 'Aller à';

	/// fr: 'Aller à une page'
	String get ouvrir => 'Aller à une page';

	/// fr: 'Page, sourate, juz ou référence'
	String get champ => 'Page, sourate, juz ou référence';

	/// fr: 'Par exemple 18, Al-Kahf, juz 15, 2:255'
	String get indice => 'Par exemple 18, Al-Kahf, juz 15, 2:255';

	/// fr: 'La recherche porte sur les numéros de page, les références et les noms de sourate. La recherche dans le texte du Coran n'est pas encore disponible.'
	String get limite => 'La recherche porte sur les numéros de page, les références et les noms de sourate. La recherche dans le texte du Coran n\'est pas encore disponible.';

	/// fr: 'Aucune référence trouvée'
	String get aucunResultat => 'Aucune référence trouvée';

	/// fr: 'Essayez un numéro de page, un nom de sourate, ou une référence comme 2:255.'
	String get aucunResultatDetail => 'Essayez un numéro de page, un nom de sourate, ou une référence comme 2:255.';

	/// fr: 'Page {page}'
	String pageNumero({required Object page}) => 'Page ${page}';
}

// Path: tc.coran.reprise
class Traductions$tc$coran$reprise$fr {
	Traductions$tc$coran$reprise$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Reprendre le cours'
	String get groupe => 'Reprendre le cours';

	/// fr: 'Le groupe en était page {page}'
	String groupeDetail({required Object page}) => 'Le groupe en était page ${page}';
}

// Path: tc.coran.focus
class Traductions$tc$coran$focus$fr {
	Traductions$tc$coran$focus$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Aucun passage mis en avant'
	String get aucunePlage => 'Aucun passage mis en avant';

	/// fr: 'Le focus suit le passage que l'enseignant désigne. Hors classe, il centre la page ouverte.'
	String get aucunePlageDetail => 'Le focus suit le passage que l\'enseignant désigne. Hors classe, il centre la page ouverte.';

	/// fr: 'Quitter le focus'
	String get quitter => 'Quitter le focus';
}

// Path: tc.outils.dock
class Traductions$tc$outils$dock$fr {
	Traductions$tc$outils$dock$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Outils'
	String get titre => 'Outils';

	/// fr: 'Déplacer les outils'
	String get deplacer => 'Déplacer les outils';

	late final Traductions$tc$outils$dock$position$fr position = Traductions$tc$outils$dock$position$fr.internal(_root);

	/// fr: 'Bibliothèque'
	String get bibliotheque => 'Bibliothèque';

	/// fr: 'Focus'
	String get focus => 'Focus';

	/// fr: 'Marquer'
	String get marquer => 'Marquer';

	/// fr: 'Masquer'
	String get masquer => 'Masquer';

	/// fr: 'Stylet'
	String get stylet => 'Stylet';

	/// fr: 'Pointeur'
	String get pointeur => 'Pointeur';

	/// fr: 'Révision'
	String get revision => 'Révision';
}

// Path: tc.outils.intention
class Traductions$tc$outils$intention$fr {
	Traductions$tc$outils$intention$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'À apprendre'
	String get aApprendre => 'À apprendre';

	/// fr: 'À revoir'
	String get aRevoir => 'À revoir';

	/// fr: 'À renforcer'
	String get aRenforcer => 'À renforcer';

	/// fr: 'À entretenir'
	String get aEntretenir => 'À entretenir';

	/// fr: 'Pour l'évaluation'
	String get pourEvaluation => 'Pour l\'évaluation';
}

// Path: tc.outils.trait
class Traductions$tc$outils$trait$fr {
	Traductions$tc$outils$trait$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Stylet'
	String get stylet => 'Stylet';

	/// fr: 'Surligner'
	String get surligneur => 'Surligner';

	/// fr: 'Gomme'
	String get gomme => 'Gomme';

	/// fr: 'Annuler'
	String get annuler => 'Annuler';

	/// fr: 'Plus'
	String get plus => 'Plus';
}

// Path: tc.outils.portee
class Traductions$tc$outils$portee$fr {
	Traductions$tc$outils$portee$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Le temps d'expliquer'
	String get temporaire => 'Le temps d\'expliquer';

	/// fr: 'Jusqu'à la fin du cours'
	String get seance => 'Jusqu\'à la fin du cours';

	/// fr: 'Enregistrer'
	String get enregistree => 'Enregistrer';

	/// fr: 'Combien de temps garder ces annotations ?'
	String get aide => 'Combien de temps garder ces annotations ?';
}

// Path: tc.outils.marquer
class Traductions$tc$outils$marquer$fr {
	Traductions$tc$outils$marquer$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Marquer ce passage'
	String get titre => 'Marquer ce passage';

	/// fr: 'Choisissez ce que ce passage demande.'
	String get aide => 'Choisissez ce que ce passage demande.';

	/// fr: 'Retirer le marqueur'
	String get retirer => 'Retirer le marqueur';
}

// Path: tc.outils.revision
class Traductions$tc$outils$revision$fr {
	Traductions$tc$outils$revision$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'À préparer'
	String get titre => 'À préparer';

	/// fr: 'Le passage sélectionné devient un travail à préparer.'
	String get aide => 'Le passage sélectionné devient un travail à préparer.';

	/// fr: 'Tout le groupe'
	String get groupeEntier => 'Tout le groupe';

	/// fr: 'Consigne courte (facultatif)'
	String get consigne => 'Consigne courte (facultatif)';

	/// fr: 'Poser le travail'
	String get creer => 'Poser le travail';

	/// fr: 'Travail à préparer posé'
	String get posee => 'Travail à préparer posé';
}

// Path: tc.outils.masquer
class Traductions$tc$outils$masquer$fr {
	Traductions$tc$outils$masquer$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Révéler'
	String get reveler => 'Révéler';

	/// fr: 'Masquer de nouveau'
	String get refermer => 'Masquer de nouveau';

	/// fr: 'Tout démasquer'
	String get tout => 'Tout démasquer';
}

// Path: tc.outils.focus
class Traductions$tc$outils$focus$fr {
	Traductions$tc$outils$focus$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Quitter le focus'
	String get quitter => 'Quitter le focus';
}

// Path: tc.outils.annotation
class Traductions$tc$outils$annotation$fr {
	Traductions$tc$outils$annotation$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Ce passage n'a pas de repère de texte : l'annotation suivra la page, pas les mots.'
	String get ancrageDegrade => 'Ce passage n\'a pas de repère de texte : l\'annotation suivra la page, pas les mots.';

	/// fr: 'Annotations masquées : leur passage n'est pas à l'écran.'
	String get horsPage => 'Annotations masquées : leur passage n\'est pas à l\'écran.';

	/// fr: 'Sélectionnez d'abord un passage.'
	String get aucuneSelection => 'Sélectionnez d\'abord un passage.';
}

// Path: tc.classe.entete
class Traductions$tc$classe$entete$fr {
	Traductions$tc$classe$entete$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations
	late final Traductions$tc$classe$entete$titreEnseignant$fr titreEnseignant = Traductions$tc$classe$entete$titreEnseignant$fr.internal(_root);

	/// fr: 'Reste {minutes} min'
	String resteMinutes({required Object minutes}) => 'Reste ${minutes} min';

	/// fr: 'Reste {heures} h {minutes}'
	String resteHeuresMinutes({required Object heures, required Object minutes}) => 'Reste ${heures} h ${minutes}';

	/// fr: 'Séance toujours en direct'
	String get coursEnCours => 'Séance toujours en direct';

	/// fr: 'Photo enseignant manquante'
	String get photoManquante => 'Photo enseignant manquante';
}

// Path: tc.classe.roster
class Traductions$tc$classe$roster$fr {
	Traductions$tc$classe$roster$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Élèves'
	String get titre => 'Élèves';

	/// fr: 'Élèves : {presents} présents sur {attendus} attendus'
	String compteur({required Object presents, required Object attendus}) => 'Élèves : ${presents} présents sur ${attendus} attendus';

	/// fr: 'Roster indisponible'
	String get indisponible => 'Roster indisponible';

	/// fr: 'Les états de vos élèves n'ont pas pu être lus. Le cours continue.'
	String get indisponibleDetail => 'Les états de vos élèves n\'ont pas pu être lus. Le cours continue.';

	/// fr: 'Aucun élève inscrit'
	String get vide => 'Aucun élève inscrit';

	/// fr: 'Cette séance n'a aucun élève inscrit. Vérifiez le groupe.'
	String get videDetail => 'Cette séance n\'a aucun élève inscrit. Vérifiez le groupe.';

	/// fr: 'Ouvrir la fiche de {prenom}'
	String ouvrirFiche({required Object prenom}) => 'Ouvrir la fiche de ${prenom}';

	/// fr: '{inscrits} / {plafond} places'
	String places({required Object inscrits, required Object plafond}) => '${inscrits} / ${plafond} places';
}

// Path: tc.classe.etat
class Traductions$tc$classe$etat$fr {
	Traductions$tc$classe$etat$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'État inconnu'
	String get inconnu => 'État inconnu';

	/// fr: 'Attendu'
	String get attendu => 'Attendu';

	/// fr: 'En connexion'
	String get enConnexion => 'En connexion';

	/// fr: 'Présent'
	String get present => 'Présent';

	/// fr: 'En retard'
	String get enRetard => 'En retard';

	/// fr: 'Déconnecté'
	String get deconnecte => 'Déconnecté';

	/// fr: 'En reconnexion'
	String get enReconnexion => 'En reconnexion';

	/// fr: 'Sorti'
	String get sorti => 'Sorti';

	/// fr: 'Absent'
	String get absent => 'Absent';
}

// Path: tc.classe.fiche
class Traductions$tc$classe$fiche$fr {
	Traductions$tc$classe$fiche$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Niveau'
	String get niveau => 'Niveau';

	/// fr: 'Objectif actuel'
	String get objectif => 'Objectif actuel';

	/// fr: 'Dernière séance'
	String get derniereSeance => 'Dernière séance';

	/// fr: 'Page {page}'
	String page({required Object page}) => 'Page ${page}';

	/// fr: '{nombre} élément(s)'
	String travailEnCours({required Object nombre}) => '${nombre} élément(s)';

	/// fr: 'À reprendre'
	String get aReprendre => 'À reprendre';

	/// fr: 'Présence récente'
	String get presenceRecente => 'Présence récente';

	/// fr: '{presences} / {total} cours'
	String assiduite({required Object presences, required Object total}) => '${presences} / ${total} cours';

	/// fr: 'Travail actuel'
	String get travailActuel => 'Travail actuel';

	/// fr: 'Interface guidée'
	String get interfaceGuidee => 'Interface guidée';

	/// fr: 'Suivi pédagogique indisponible'
	String get sansPedagogie => 'Suivi pédagogique indisponible';

	/// fr: 'Le parcours, les objectifs et le travail en cours ne sont pas encore ouverts à l'enseignant.'
	String get sansPedagogieDetail => 'Le parcours, les objectifs et le travail en cours ne sont pas encore ouverts à l\'enseignant.';
}

// Path: tc.classe.action
class Traductions$tc$classe$action$fr {
	Traductions$tc$classe$action$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Rappel discret'
	String get rappel => 'Rappel discret';

	/// fr: 'Choisir pour réciter'
	String get reciter => 'Choisir pour réciter';

	/// fr: 'Noter'
	String get noter => 'Noter';

	/// fr: 'Signaler un besoin'
	String get signaler => 'Signaler un besoin';

	/// fr: 'Ouvrir le contexte'
	String get contexte => 'Ouvrir le contexte';
}

// Path: tc.classe.rappel
class Traductions$tc$classe$rappel$fr {
	Traductions$tc$classe$rappel$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Le professeur vous appelle'
	String get recu => 'Le professeur vous appelle';

	/// fr: 'Le rappel n'a pas pu être envoyé'
	String get echec => 'Le rappel n\'a pas pu être envoyé';

	/// fr: 'Votre accès à cette séance ne permet pas d'appeler un élève'
	String get echecDroit => 'Votre accès à cette séance ne permet pas d\'appeler un élève';

	/// fr: 'Déjà appelé. À nouveau dans {secondes} s'
	String cooldown({required Object secondes}) => 'Déjà appelé. À nouveau dans ${secondes} s';
}

// Path: tc.classe.recitation
class Traductions$tc$classe$recitation$fr {
	Traductions$tc$classe$recitation$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Récitation'
	String get titre => 'Récitation';

	/// fr: '{prenom} récite'
	String actif({required Object prenom}) => '${prenom} récite';

	/// fr: 'Récite'
	String get pastille => 'Récite';

	/// fr: 'Ensuite'
	String get suivants => 'Ensuite';

	/// fr: 'Personne ne récite'
	String get personne => 'Personne ne récite';

	/// fr: 'Arrêter la récitation'
	String get arreter => 'Arrêter la récitation';
}

// Path: tc.classe.support
class Traductions$tc$classe$support$fr {
	Traductions$tc$classe$support$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Aucun support présenté'
	String get aucun => 'Aucun support présenté';

	/// fr: 'Ouvrez la Bibliothèque pour présenter un support au groupe.'
	String get aucunDetail => 'Ouvrez la Bibliothèque pour présenter un support au groupe.';

	/// fr: 'Bibliothèque'
	String get bibliotheque => 'Bibliothèque';

	/// fr: 'Bibliothèque non branchée'
	String get bibliothequeAbsente => 'Bibliothèque non branchée';

	/// fr: 'Le choix de support sera disponible dès l'intégration du catalogue.'
	String get bibliothequeAbsenteDetail => 'Le choix de support sera disponible dès l\'intégration du catalogue.';
}

// Path: tc.classe.commandes
class Traductions$tc$classe$commandes$fr {
	Traductions$tc$classe$commandes$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Ouvrir le micro'
	String get micro => 'Ouvrir le micro';

	/// fr: 'Fermer le micro'
	String get microFermer => 'Fermer le micro';

	/// fr: 'Ouvrir la caméra'
	String get camera => 'Ouvrir la caméra';

	/// fr: 'Fermer la caméra'
	String get cameraFermer => 'Fermer la caméra';

	/// fr: 'Micro fermé'
	String get microCoupe => 'Micro fermé';

	/// fr: 'Quitter'
	String get quitter => 'Quitter';

	/// fr: 'Quitter le cours ?'
	String get quitterQuestion => 'Quitter le cours ?';

	/// fr: 'Votre sortie sera enregistrée. Vous pourrez revenir tant que la séance est ouverte.'
	String get quitterConsequence => 'Votre sortie sera enregistrée. Vous pourrez revenir tant que la séance est ouverte.';

	/// fr: 'Fermer la Bibliothèque'
	String get fermerBibliotheque => 'Fermer la Bibliothèque';
}

// Path: tc.classe.scene
class Traductions$tc$classe$scene$fr {
	Traductions$tc$classe$scene$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Vous êtes seul dans la salle pour le moment'
	String get vide => 'Vous êtes seul dans la salle pour le moment';

	/// fr: 'Sans image'
	String get sansImage => 'Sans image';
}

// Path: tc.classe.reseau
class Traductions$tc$classe$reseau$fr {
	Traductions$tc$classe$reseau$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Réseau bon'
	String get bon => 'Réseau bon';

	/// fr: 'Réseau instable'
	String get mediocre => 'Réseau instable';

	/// fr: 'Réseau perdu'
	String get perdu => 'Réseau perdu';
}

// Path: tc.classe.attente
class Traductions$tc$classe$attente$fr {
	Traductions$tc$classe$attente$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Vérification de votre micro'
	String get materiel => 'Vérification de votre micro';

	/// fr: 'Ouverture du cours'
	String get ouverture => 'Ouverture du cours';

	/// fr: 'Connexion au cours'
	String get connexion => 'Connexion au cours';

	/// fr: 'Le cours n'est pas accessible pour le moment'
	String get refus => 'Le cours n\'est pas accessible pour le moment';
}

// Path: tc.classe.lien
class Traductions$tc$classe$lien$fr {
	Traductions$tc$classe$lien$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Connexion instable'
	String get instable => 'Connexion instable';

	/// fr: 'Reconnexion en cours'
	String get reconnexion => 'Reconnexion en cours';

	/// fr: 'Connexion rétablie'
	String get retabli => 'Connexion rétablie';

	/// fr: 'Connexion perdue'
	String get echec => 'Connexion perdue';

	/// fr: 'Le cours a été mis en pause par le système. Vérification du lien en cours.'
	String get retourDeSuspension => 'Le cours a été mis en pause par le système. Vérification du lien en cours.';
}

// Path: tc.classe.barre
class Traductions$tc$classe$barre$fr {
	Traductions$tc$classe$barre$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Séance en direct'
	String get titre => 'Séance en direct';

	/// fr: 'Revenir au cours de {groupe}'
	String revenir({required Object groupe}) => 'Revenir au cours de ${groupe}';
}

// Path: tc.classe.prevol
class Traductions$tc$classe$prevol$fr {
	Traductions$tc$classe$prevol$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Avant d'ouvrir le cours'
	String get titre => 'Avant d\'ouvrir le cours';

	/// fr: 'Micro détecté'
	String get microOk => 'Micro détecté';

	/// fr: 'Aucun micro utilisable'
	String get microAbsent => 'Aucun micro utilisable';

	/// fr: 'Caméra détectée'
	String get cameraOk => 'Caméra détectée';

	/// fr: 'Aucune caméra. Le cours reste possible.'
	String get cameraAbsente => 'Aucune caméra. Le cours reste possible.';

	/// fr: 'Accès au micro refusé. Autorisez-le pour ouvrir le cours.'
	String get permissionRefusee => 'Accès au micro refusé. Autorisez-le pour ouvrir le cours.';

	/// fr: 'Vérifier à nouveau'
	String get reessayer => 'Vérifier à nouveau';
}

// Path: tc.classe.observation
class Traductions$tc$classe$observation$fr {
	Traductions$tc$classe$observation$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Reste {secondes} s'
	String restant({required Object secondes}) => 'Reste ${secondes} s';
}

// Path: tc.realtime.transport
class Traductions$tc$realtime$transport$fr {
	Traductions$tc$realtime$transport$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Le partage du support n’est pas disponible sur ce serveur. Le cours continue, mais les autres appareils ne suivront pas la page.'
	String get partage_indisponible => 'Le partage du support n’est pas disponible sur ce serveur. Le cours continue, mais les autres appareils ne suivront pas la page.';
}

// Path: tc.realtime.etat
class Traductions$tc$realtime$etat$fr {
	Traductions$tc$realtime$etat$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Impossible de retrouver le support en cours. Demandez à l’enseignant de le présenter à nouveau.'
	String get restauration_impossible => 'Impossible de retrouver le support en cours. Demandez à l’enseignant de le présenter à nouveau.';
}

// Path: tc.observation.entree
class Traductions$tc$observation$entree$fr {
	Traductions$tc$observation$entree$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Observer la séance'
	String get titre => 'Observer la séance';

	/// fr: 'Vous pouvez regarder un court moment le cours de votre enfant. Votre micro et votre caméra restent fermés.'
	String get tuteurIntro => 'Vous pouvez regarder un court moment le cours de votre enfant. Votre micro et votre caméra restent fermés.';

	/// fr: 'Choisissez votre mode avant d'entrer. Il ne change plus ensuite.'
	String get adminIntro => 'Choisissez votre mode avant d\'entrer. Il ne change plus ensuite.';

	/// fr: 'Vous entrez en observation invisible. Aucun micro, aucune caméra.'
	String get controleurIntro => 'Vous entrez en observation invisible. Aucun micro, aucune caméra.';

	/// fr: 'Entrer'
	String get entrer => 'Entrer';

	/// fr: 'Observer discrètement'
	String get modeDiscret => 'Observer discrètement';

	/// fr: 'Invisible pour les participants. Sans micro ni caméra, sans annonce.'
	String get modeDiscretDetail => 'Invisible pour les participants. Sans micro ni caméra, sans annonce.';

	/// fr: 'Rejoindre la classe'
	String get modeVisible => 'Rejoindre la classe';

	/// fr: 'Visible par tous sous le nom Administration Rewayah. Micro et caméra permis, annonce faite.'
	String get modeVisibleDetail => 'Visible par tous sous le nom Administration Rewayah. Micro et caméra permis, annonce faite.';

	/// fr: 'Administration Rewayah'
	String get nomInstitutionnel => 'Administration Rewayah';

	/// fr: 'Visite journalisée : identité, séance, entrée, sortie et durée.'
	String get visiteJournalisee => 'Visite journalisée : identité, séance, entrée, sortie et durée.';

	/// fr: 'Votre compte n'observe pas les séances.'
	String get roleSansObservation => 'Votre compte n\'observe pas les séances.';
}

// Path: tc.observation.refus
class Traductions$tc$observation$refus$fr {
	Traductions$tc$observation$refus$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'L'observation est désactivée pour ce groupe.'
	String get politiqueDesactivee => 'L\'observation est désactivée pour ce groupe.';

	/// fr: 'Vous avez déjà utilisé vos visites pour cette séance.'
	String get quotaVisites => 'Vous avez déjà utilisé vos visites pour cette séance.';

	/// fr: 'Votre temps d'observation est épuisé pour cette séance.'
	String get tempsEpuise => 'Votre temps d\'observation est épuisé pour cette séance.';

	/// fr: 'Vous n'êtes rattaché à aucun élève de cette séance.'
	String get lienTuteur => 'Vous n\'êtes rattaché à aucun élève de cette séance.';

	/// fr: 'La séance n'est pas en cours.'
	String get seanceNonActive => 'La séance n\'est pas en cours.';

	/// fr: 'La salle n'est pas ouverte à cette heure.'
	String get horsFenetre => 'La salle n\'est pas ouverte à cette heure.';

	/// fr: 'L'observation n'est pas disponible pour le moment.'
	String get indisponible => 'L\'observation n\'est pas disponible pour le moment.';

	/// fr: 'L'observation n'est pas encore activée sur cette installation.'
	String get capaciteAbsente => 'L\'observation n\'est pas encore activée sur cette installation.';
}

// Path: tc.observation.visite
class Traductions$tc$observation$visite$fr {
	Traductions$tc$observation$visite$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Observation en cours'
	String get titre => 'Observation en cours';

	/// fr: 'Quitter'
	String get quitter => 'Quitter';

	/// fr: 'Micro et caméra fermés pendant l'observation.'
	String get mediaFerme => 'Micro et caméra fermés pendant l\'observation.';

	/// fr: 'Le support partagé par l'enseignant s'affiche ici.'
	String get supportIndisponible => 'Le support partagé par l\'enseignant s\'affiche ici.';

	/// fr: 'Enseignant'
	String get enseignant => 'Enseignant';

	/// fr: 'Votre enfant'
	String get monEnfant => 'Votre enfant';

	/// fr: 'Votre enfant n'a pas d'image ouverte.'
	String get enfantAbsent => 'Votre enfant n\'a pas d\'image ouverte.';

	/// fr: 'Temps restant non confirmé par le serveur.'
	String get budgetIncertain => 'Temps restant non confirmé par le serveur.';

	/// fr: 'La vidéo de la séance n'a pas pu s'ouvrir. Votre temps d'observation continue de s'écouler.'
	String get videoIndisponible => 'La vidéo de la séance n\'a pas pu s\'ouvrir. Votre temps d\'observation continue de s\'écouler.';

	/// fr: 'La fin de votre visite n'a pas pu être confirmée. Elle sera fermée par le serveur.'
	String get sortieNonConfirmee => 'La fin de votre visite n\'a pas pu être confirmée. Elle sera fermée par le serveur.';

	/// fr: '{secondes} s restantes'
	String restant({required Object secondes}) => '${secondes} s restantes';

	/// fr: 'Visite {rang} sur {total}'
	String visites({required Object rang, required Object total}) => 'Visite ${rang} sur ${total}';
}

// Path: tc.observation.fin
class Traductions$tc$observation$fin$fr {
	Traductions$tc$observation$fin$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Vous avez quitté l'observation.'
	String get sortieVolontaire => 'Vous avez quitté l\'observation.';

	/// fr: 'Votre temps d'observation est écoulé.'
	String get quotaAtteint => 'Votre temps d\'observation est écoulé.';

	/// fr: 'La séance est terminée.'
	String get seanceTerminee => 'La séance est terminée.';

	/// fr: 'Votre observation a été interrompue.'
	String get revocationServeur => 'Votre observation a été interrompue.';

	/// fr: 'La connexion a été perdue.'
	String get deconnexion => 'La connexion a été perdue.';
}

// Path: tc.observation.annonce
class Traductions$tc$observation$annonce$fr {
	Traductions$tc$observation$annonce$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Tuteur de {prenomEnfant} observe'
	String tuteurObserve({required Object prenomEnfant}) => 'Tuteur de ${prenomEnfant} observe';

	/// fr: '{secondes} s'
	String restant({required Object secondes}) => '${secondes} s';

	/// fr: 'Ton tuteur regarde le cours'
	String get enfantIndicateur => 'Ton tuteur regarde le cours';

	/// fr: '{nombre} tuteurs observent'
	String tuteursObservent({required Object nombre}) => '${nombre} tuteurs observent';
}

// Path: tc.observation.reglages
class Traductions$tc$observation$reglages$fr {
	Traductions$tc$observation$reglages$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Observation par les tuteurs'
	String get titre => 'Observation par les tuteurs';

	/// fr: 'Un tuteur peut regarder un court moment le cours de son enfant, sans micro ni caméra. Ce réglage décide de ce qui s'applique à ce groupe.'
	String get intro => 'Un tuteur peut regarder un court moment le cours de son enfant, sans micro ni caméra. Ce réglage décide de ce qui s\'applique à ce groupe.';

	/// fr: 'Hériter de l'Académie'
	String get heriter => 'Hériter de l\'Académie';

	/// fr: 'Personnaliser pour ce groupe'
	String get personnaliser => 'Personnaliser pour ce groupe';

	/// fr: 'Désactiver pour ce groupe'
	String get desactiver => 'Désactiver pour ce groupe';

	/// fr: 'Visites par séance'
	String get maxVisites => 'Visites par séance';

	/// fr: 'Temps total par séance'
	String get tempsTotal => 'Temps total par séance';

	/// fr: 'Durée maximale d'une visite'
	String get plafondVisite => 'Durée maximale d\'une visite';

	/// fr: 'Diminuer'
	String get diminuer => 'Diminuer';

	/// fr: 'Augmenter'
	String get augmenter => 'Augmenter';

	/// fr: 'Enregistrer'
	String get enregistrer => 'Enregistrer';

	/// fr: 'Au moins une visite par séance.'
	String get invalideVisites => 'Au moins une visite par séance.';

	/// fr: 'Au moins trente secondes par séance.'
	String get invalideTemps => 'Au moins trente secondes par séance.';

	/// fr: 'Académie : {valeur}'
	String valeurHeritee({required Object valeur}) => 'Académie : ${valeur}';

	/// fr: '{n} visite'
	String uniteVisiteUne({required Object n}) => '${n} visite';

	/// fr: '{n} visites'
	String uniteVisites({required Object n}) => '${n} visites';

	/// fr: '{n} s'
	String uniteSecondes({required Object n}) => '${n} s';

	/// fr: 'Version {version}'
	String versionPolitique({required Object version}) => 'Version ${version}';
}

// Path: tc.parcours.avant
class Traductions$tc$parcours$avant$fr {
	Traductions$tc$parcours$avant$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Avant le prochain cours'
	String get titre => 'Avant le prochain cours';

	/// fr: 'Rien à préparer pour le prochain cours.'
	String get rien => 'Rien à préparer pour le prochain cours.';

	/// fr: 'Votre enseignant proposera le travail à la fin de la prochaine séance.'
	String get rienDetail => 'Votre enseignant proposera le travail à la fin de la prochaine séance.';

	/// fr: 'Le travail à préparer n'est pas encore relié à cet espace.'
	String get nonBranche => 'Le travail à préparer n\'est pas encore relié à cet espace.';

	/// fr: 'Cela ne veut pas dire qu'il n'y a rien à préparer : cet écran ne sait pas encore le lire.'
	String get nonBrancheDetail => 'Cela ne veut pas dire qu\'il n\'y a rien à préparer : cet écran ne sait pas encore le lire.';

	/// fr: 'Reprendre le cours'
	String get reprendre => 'Reprendre le cours';

	/// fr: 'Reprendre le cours à {position}'
	String reprendreDepuis({required Object position}) => 'Reprendre le cours à ${position}';
}

// Path: tc.parcours.intention
class Traductions$tc$parcours$intention$fr {
	Traductions$tc$parcours$intention$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'À apprendre'
	String get apprendre => 'À apprendre';

	/// fr: 'À revoir'
	String get revoir => 'À revoir';

	/// fr: 'À renforcer'
	String get renforcer => 'À renforcer';

	/// fr: 'À entretenir'
	String get entretenir => 'À entretenir';

	/// fr: 'Pour l'évaluation'
	String get evaluation => 'Pour l\'évaluation';
}

// Path: tc.parcours.plage
class Traductions$tc$parcours$plage$fr {
	Traductions$tc$parcours$plage$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Sourate {sourate}, versets {premier} à {dernier}'
	String versets({required Object sourate, required Object premier, required Object dernier}) => 'Sourate ${sourate}, versets ${premier} à ${dernier}';

	/// fr: 'Sourate {sourate}, verset {premier}'
	String versetUnique({required Object sourate, required Object premier}) => 'Sourate ${sourate}, verset ${premier}';

	/// fr: 'Sourate {sourateDebut}, verset {versetDebut} jusqu'à sourate {sourateFin}, verset {versetFin}'
	String versetsCroisee({required Object sourateDebut, required Object versetDebut, required Object sourateFin, required Object versetFin}) => 'Sourate ${sourateDebut}, verset ${versetDebut} jusqu\'à sourate ${sourateFin}, verset ${versetFin}';

	/// fr: 'Pages {premiere} à {derniere}'
	String pages({required Object premiere, required Object derniere}) => 'Pages ${premiere} à ${derniere}';

	/// fr: 'Page {premiere}'
	String pageUnique({required Object premiere}) => 'Page ${premiere}';

	/// fr: 'Section {section}'
	String section({required Object section}) => 'Section ${section}';

	/// fr: 'Tout le support'
	String get ressource => 'Tout le support';
}

// Path: tc.parcours.feedback
class Traductions$tc$parcours$feedback$fr {
	Traductions$tc$parcours$feedback$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations
	late final Traductions$tc$parcours$feedback$cours$fr cours = Traductions$tc$parcours$feedback$cours$fr.internal(_root);
	late final Traductions$tc$parcours$feedback$comprehension$fr comprehension = Traductions$tc$parcours$feedback$comprehension$fr.internal(_root);
	late final Traductions$tc$parcours$feedback$rythme$fr rythme = Traductions$tc$parcours$feedback$rythme$fr.internal(_root);
	late final Traductions$tc$parcours$feedback$technique$fr technique = Traductions$tc$parcours$feedback$technique$fr.internal(_root);
	late final Traductions$tc$parcours$feedback$confiance$fr confiance = Traductions$tc$parcours$feedback$confiance$fr.internal(_root);

	/// fr: 'Merci.'
	String get merci => 'Merci.';

	late final Traductions$tc$parcours$feedback$tendance$fr tendance = Traductions$tc$parcours$feedback$tendance$fr.internal(_root);
}

// Path: tc.parcours.signalement
class Traductions$tc$parcours$signalement$fr {
	Traductions$tc$parcours$signalement$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Signaler un besoin'
	String get titre => 'Signaler un besoin';

	/// fr: 'De quoi s'agit-il ?'
	String get categorie => 'De quoi s\'agit-il ?';

	late final Traductions$tc$parcours$signalement$categorieValeur$fr categorieValeur = Traductions$tc$parcours$signalement$categorieValeur$fr.internal(_root);

	/// fr: 'Note interne'
	String get interne => 'Note interne';

	/// fr: 'Lue par l'administration seulement. Elle ne part jamais automatiquement à la famille.'
	String get interneAide => 'Lue par l\'administration seulement. Elle ne part jamais automatiquement à la famille.';

	/// fr: 'Message pour la famille'
	String get famille => 'Message pour la famille';

	/// fr: 'Facultatif. L'administration décide seule de le transmettre, en un clic.'
	String get familleAide => 'Facultatif. L\'administration décide seule de le transmettre, en un clic.';

	/// fr: 'Élève {eleve}. La séance, le groupe et votre nom sont déjà joints.'
	String contexte({required Object eleve}) => 'Élève ${eleve}. La séance, le groupe et votre nom sont déjà joints.';

	/// fr: 'Envoyer le signalement'
	String get envoyer => 'Envoyer le signalement';

	/// fr: 'Signalement transmis à l'administration.'
	String get envoye => 'Signalement transmis à l\'administration.';

	/// fr: 'Écrivez au moins ce que l'administration doit savoir.'
	String get interneRequis => 'Écrivez au moins ce que l\'administration doit savoir.';

	/// fr: 'Le signalement n'a pas pu être transmis. Réessayez.'
	String get echec => 'Le signalement n\'a pas pu être transmis. Réessayez.';
}

// Path: tc.parcours.postCours
class Traductions$tc$parcours$postCours$fr {
	Traductions$tc$parcours$postCours$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Après le cours'
	String get titre => 'Après le cours';

	/// fr: 'Durée réelle {minutes} min'
	String duree({required Object minutes}) => 'Durée réelle ${minutes} min';

	/// fr: 'À confirmer'
	String get exceptions => 'À confirmer';

	/// fr: 'Rien ne demande votre attention.'
	String get toutEstNominal => 'Rien ne demande votre attention.';

	/// fr: 'Reprise proposée'
	String get reprise => 'Reprise proposée';

	/// fr: 'Aucune position de reprise connue pour cette séance.'
	String get repriseInconnue => 'Aucune position de reprise connue pour cette séance.';

	/// fr: 'Travail proposé'
	String get travail => 'Travail proposé';

	/// fr: 'Aucun travail proposé pour l'instant.'
	String get travailAucun => 'Aucun travail proposé pour l\'instant.';

	/// fr: 'Valider'
	String get valider => 'Valider';

	/// fr: 'Enregistré. Il partira dès le retour du réseau.'
	String get enFile => 'Enregistré. Il partira dès le retour du réseau.';

	/// fr: 'Cours clôturé.'
	String get envoye => 'Cours clôturé.';
}

// Path: tc.outils.dock.position
class Traductions$tc$outils$dock$position$fr {
	Traductions$tc$outils$dock$position$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'En bas'
	String get bas => 'En bas';

	/// fr: 'À gauche'
	String get gauche => 'À gauche';

	/// fr: 'À droite'
	String get droite => 'À droite';
}

// Path: tc.classe.entete.titreEnseignant
class Traductions$tc$classe$entete$titreEnseignant$fr {
	Traductions$tc$classe$entete$titreEnseignant$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Sayyid'
	String get sayyid => 'Sayyid';

	/// fr: 'Sayyida'
	String get sayyida => 'Sayyida';
}

// Path: tc.parcours.feedback.cours
class Traductions$tc$parcours$feedback$cours$fr {
	Traductions$tc$parcours$feedback$cours$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Comment était le cours aujourd'hui ?'
	String get intitule => 'Comment était le cours aujourd\'hui ?';

	/// fr: 'Difficile'
	String get difficile => 'Difficile';

	/// fr: 'Bien'
	String get bien => 'Bien';

	/// fr: 'Très bien'
	String get tresBien => 'Très bien';
}

// Path: tc.parcours.feedback.comprehension
class Traductions$tc$parcours$feedback$comprehension$fr {
	Traductions$tc$parcours$feedback$comprehension$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Avez-vous compris ce qui a été travaillé ?'
	String get intitule => 'Avez-vous compris ce qui a été travaillé ?';

	/// fr: 'Pas vraiment'
	String get difficile => 'Pas vraiment';

	/// fr: 'Plutôt oui'
	String get bien => 'Plutôt oui';

	/// fr: 'Tout à fait'
	String get tresBien => 'Tout à fait';
}

// Path: tc.parcours.feedback.rythme
class Traductions$tc$parcours$feedback$rythme$fr {
	Traductions$tc$parcours$feedback$rythme$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Le rythme du cours vous a-t-il convenu ?'
	String get intitule => 'Le rythme du cours vous a-t-il convenu ?';

	/// fr: 'Trop rapide'
	String get difficile => 'Trop rapide';

	/// fr: 'Convenable'
	String get bien => 'Convenable';

	/// fr: 'Très confortable'
	String get tresBien => 'Très confortable';
}

// Path: tc.parcours.feedback.technique
class Traductions$tc$parcours$feedback$technique$fr {
	Traductions$tc$parcours$feedback$technique$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Le son et l'image étaient-ils confortables ?'
	String get intitule => 'Le son et l\'image étaient-ils confortables ?';

	/// fr: 'Gênants'
	String get difficile => 'Gênants';

	/// fr: 'Corrects'
	String get bien => 'Corrects';

	/// fr: 'Très bons'
	String get tresBien => 'Très bons';
}

// Path: tc.parcours.feedback.confiance
class Traductions$tc$parcours$feedback$confiance$fr {
	Traductions$tc$parcours$feedback$confiance$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Vous sentez-vous prêt pour le prochain cours ?'
	String get intitule => 'Vous sentez-vous prêt pour le prochain cours ?';

	/// fr: 'Pas encore'
	String get difficile => 'Pas encore';

	/// fr: 'Plutôt'
	String get bien => 'Plutôt';

	/// fr: 'Tout à fait'
	String get tresBien => 'Tout à fait';
}

// Path: tc.parcours.feedback.tendance
class Traductions$tc$parcours$feedback$tendance$fr {
	Traductions$tc$parcours$feedback$tendance$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Retour des élèves'
	String get titre => 'Retour des élèves';

	/// fr: 'Pas encore assez de retours pour dégager une tendance.'
	String get sousSeuil => 'Pas encore assez de retours pour dégager une tendance.';

	/// fr: 'Les retours sont anonymes et agrégés. Ils ne suffisent jamais, seuls, à une décision.'
	String get anonyme => 'Les retours sont anonymes et agrégés. Ils ne suffisent jamais, seuls, à une décision.';
}

// Path: tc.parcours.signalement.categorieValeur
class Traductions$tc$parcours$signalement$categorieValeur$fr {
	Traductions$tc$parcours$signalement$categorieValeur$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Pédagogique'
	String get pedagogique => 'Pédagogique';

	/// fr: 'Présence'
	String get presence => 'Présence';

	/// fr: 'Technique'
	String get technique => 'Technique';

	/// fr: 'Changement'
	String get changement => 'Changement';

	/// fr: 'Autre'
	String get autre => 'Autre';
}

/// The flat map containing all translations for locale <fr>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Traductions {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'commun.marque' => 'Rewayah Academy',
			'commun.continuer' => 'Continuer',
			'commun.retour' => 'Retour',
			'commun.valider' => 'Valider',
			'commun.annuler' => 'Annuler',
			'commun.fermer' => 'Fermer',
			'commun.reessayer' => 'Réessayer',
			'commun.chargement' => 'Chargement',
			'commun.etats.chargementProlonge.titre' => 'La connexion prend plus de temps que prévu',
			'commun.etats.chargementProlonge.phrase' => 'Vous pouvez patienter encore un peu ou réessayer.',
			'commun.etats.horsLigne.titre' => 'Vous êtes hors ligne',
			'commun.etats.horsLigne.phrase' => 'Vérifiez votre connexion. Ce qui est déjà affiché reste consultable.',
			'commun.etats.reconnexion.titre' => 'Reconnexion en cours',
			'commun.etats.reconnexion.phrase' => 'Une nouvelle tentative de connexion est en cours.',
			'commun.etats.echecServeur.titre' => 'Impossible de charger ces informations',
			'commun.etats.echecServeur.phrase' => 'Le chargement n\'a pas abouti. Réessayez dans un instant.',
			'commun.etats.introuvable.titre' => 'Cette page est introuvable',
			'commun.etats.introuvable.phrase' => 'Le lien est peut-être incomplet, ou la page n\'existe plus.',
			'commun.etats.accesRefuse.titre' => 'Vous n\'avez pas accès à cette page',
			'commun.etats.accesRefuse.phrase' => 'Ce contenu n\'est pas ouvert à votre compte.',
			'commun.etats.sessionExpiree.titre' => 'Votre session a expiré',
			'commun.etats.sessionExpiree.phrase' => 'Reconnectez-vous pour continuer.',
			'commun.etats.dossierEnAttente.titre' => 'Votre dossier est en attente',
			'commun.etats.dossierEnAttente.phrase' => 'Une étape reste à franchir avant d\'ouvrir cet espace.',
			'commun.etats.aucunResultat.titre' => 'Aucun résultat',
			'commun.etats.aucunResultat.phrase' => 'Rien ne correspond pour le moment.',
			'commun.etats.permissionRefusee.titre' => 'Autorisation refusée',
			'commun.etats.permissionRefusee.phrase' => 'Sans cette autorisation, cette fonction ne peut pas s\'ouvrir. Vous pouvez la modifier dans les réglages de votre appareil.',
			'commun.etats.ressourceExpiree.titre' => 'Ce contenu n\'est plus disponible',
			'commun.etats.ressourceExpiree.phrase' => 'Il a été retiré, ou son accès a pris fin.',
			'commun.etats.indisponible.titre' => 'Pas encore disponible',
			'commun.etats.indisponible.phrase' => 'Cette fonction n\'est pas encore ouverte.',
			'commun.etats.reessaisEpuises' => 'Toujours sans réponse. Réessayez un peu plus tard.',
			'commun.etats.horsLigneDemarrage' => 'Rewayah a besoin d\'Internet pour vérifier votre compte. Reconnectez cet appareil, puis réessayez.',
			'commun.etats.actions.reessayer' => 'Réessayer',
			'commun.etats.actions.retourAccueil' => 'Retour à l\'accueil',
			'commun.etats.actions.seConnecter' => 'Se connecter',
			'commun.etats.actions.seReconnecter' => 'Se reconnecter',
			'commun.etats.actions.voirDossier' => 'Voir mon dossier',
			'commun.etats.actions.reinitialiserFiltres' => 'Réinitialiser les filtres',
			'commun.etats.actions.revenir' => 'Revenir en arrière',
			'commun.entete.retour' => 'Retour',
			'commun.entete.notifications' => 'Notifications',
			'commun.entete.notificationsUneNonLue' => 'Notifications, une non lue',
			'commun.entete.notificationsNonLues' => ({required Object nombre}) => 'Notifications, ${nombre} non lues',
			'commun.selecteurProfils.etiquette' => ({required Object prenom, required Object etat}) => '${prenom}, ${etat}',
			'commun.selecteurProfils.ajouter' => 'Ajouter',
			'commun.selecteurProfils.ajouterSemantique' => 'Ajouter un profil élève',
			'commun.theme.groupe' => 'Apparence',
			'commun.theme.clair' => 'Thème clair',
			'commun.theme.sombre' => 'Thème sombre',
			'commun.demarrage.ouverture' => 'Ouverture de Rewayah',
			'commun.dates.jours.0' => 'Lundi',
			'commun.dates.jours.1' => 'Mardi',
			'commun.dates.jours.2' => 'Mercredi',
			'commun.dates.jours.3' => 'Jeudi',
			'commun.dates.jours.4' => 'Vendredi',
			'commun.dates.jours.5' => 'Samedi',
			'commun.dates.jours.6' => 'Dimanche',
			'commun.dates.mois.0' => 'janvier',
			'commun.dates.mois.1' => 'février',
			'commun.dates.mois.2' => 'mars',
			'commun.dates.mois.3' => 'avril',
			'commun.dates.mois.4' => 'mai',
			'commun.dates.mois.5' => 'juin',
			'commun.dates.mois.6' => 'juillet',
			'commun.dates.mois.7' => 'août',
			'commun.dates.mois.8' => 'septembre',
			'commun.dates.mois.9' => 'octobre',
			'commun.dates.mois.10' => 'novembre',
			'commun.dates.mois.11' => 'décembre',
			'commun.dates.jourDate' => ({required Object jour, required Object numero, required Object mois}) => '${jour} ${numero} ${mois}',
			'reseau.horsLigne' => 'Pas de réseau. Tout reste consultable, l\'envoi attendra.',
			'reseau.enAttenteEnvoi' => 'Sera envoyé dès le retour du réseau',
			'reseau.retabli' => 'Réseau rétabli',
			'reseau.syncImpossible' => 'Synchronisation impossible',
			'etat.enDirect' => 'En direct',
			'etat.imminent' => 'C\'est bientôt',
			'etat.annule' => 'Annulé',
			'etat.enAttente' => 'En attente',
			'etat.enRetard' => 'En retard',
			'etat.termine' => 'Terminé',
			'destructif.irreversible' => 'Cette action ne peut pas être annulée.',
			'salle.bandeauPermanent' => 'Cours enregistré, visite de contrôle possible.',
			'salle.micro' => 'Micro',
			'salle.microCoupe' => 'Micro coupé',
			'salle.camera' => 'Caméra',
			'salle.cameraCoupee' => 'Caméra éteinte',
			'salle.quitter' => 'Quitter',
			'salle.ouvrirCoran' => 'Ouvrir le Coran',
			'salle.confirmerSortie' => 'Quitter le cours ?',
			'salle.expiree' => 'Cette salle n\'est plus accessible. Revenez à votre accueil pour rejoindre le prochain cours.',
			'salle.ouverture' => 'Ouverture de la salle',
			'salle.verificationMateriel' => 'Vérification de votre micro',
			'salle.connexion' => 'Connexion au cours',
			'salle.reconnexion' => 'Connexion instable, reconnexion en cours',
			'salle.reconnexionCourt' => 'Reconnexion',
			'salle.perdue' => 'La connexion au cours est perdue',
			'salle.seulEnseignant' => 'Votre professeur n\'est pas encore arrivé',
			'salle.seulEnseignantDetail' => 'Restez sur cet écran. Vous le verrez apparaître.',
			'salle.seulEleve' => 'Votre élève n\'est pas encore arrivé',
			'salle.seulEleveDetail' => 'Restez sur cet écran. Vous le verrez apparaître.',
			'salle.seulObservation' => 'Personne n\'est encore entré dans cette salle',
			'salle.seulObservationDetail' => 'Le cours n\'a pas commencé, ou il est déjà terminé.',
			'salle.refusAcces' => 'Ce cours ne vous est pas ouvert en ce moment',
			'salle.refusAccesDetail' => 'La salle s\'ouvre dix minutes avant l\'heure du cours, et se ferme un quart d\'heure après sa fin.',
			'salle.refusConfiguration' => 'La salle n\'est pas encore disponible',
			'salle.refusConfigurationDetail' => 'Ce n\'est pas votre appareil : le service de visioconférence n\'est pas branché. L\'équipe le sait.',
			'salle.refusReseau' => 'La salle n\'a pas répondu',
			'salle.refusReseauDetail' => 'Vérifiez votre connexion, puis réessayez.',
			'salle.refusMateriel' => 'Aucun micro utilisable sur cet appareil',
			'salle.refusMaterielDetail' => 'Un cours de Coran se fait à la voix. Autorisez l\'accès au micro, ou branchez un casque, puis réessayez.',
			'salle.retourAccueil' => 'Revenir à mon accueil',
			'salle.ouvrirMicro' => 'Ouvrir le micro',
			'salle.fermerMicro' => 'Fermer le micro',
			'salle.ouvrirCamera' => 'Allumer la caméra',
			'salle.fermerCamera' => 'Éteindre la caméra',
			'salle.quitterLeCours' => 'Quitter le cours',
			'salle.consequenceSortie' => 'Le cours continue sans vous, et votre départ est inscrit dans la séance.',
			'salle.vousMeme' => 'Vous',
			'salle.sansImage' => 'Sans image',
			'salle.lienMediocre' => 'Connexion faible',
			'salle.lienPerdu' => 'Connexion perdue',
			'salle.videoSuspendue' => 'Image coupée le temps que la connexion revienne. La voix continue.',
			'salle.roleEnseignant' => 'Enseignant',
			'salle.roleEleve' => 'Élève',
			'salle.roleTuteur' => 'Tuteur, en observation',
			'salle.roleAdministration' => 'Administration Rewayah',
			'salle.observationMuette' => 'Vous assistez au cours. Vous n\'êtes pas entendu.',
			'salle.bandeauControle' => 'Visite de contrôle. Vous n\'êtes ni vu ni entendu, et votre passage est inscrit au journal.',
			'presence.titre' => 'Présence',
			'presence.voir' => 'Voir la présence',
			'presence.mienne' => 'Votre présence',
			'presence.consolide' => 'consolidé',
			'presence.planifiee' => 'Cours à venir',
			'presence.enAttente' => 'Pas encore là',
			'presence.enConnexion' => 'Connexion en cours',
			'presence.presente' => 'En salle',
			'presence.enRetard' => 'En retard',
			'presence.deconnectee' => 'Lien coupé',
			'presence.enReconnexion' => 'Reconnexion en cours',
			'presence.reconnectee' => 'De retour',
			'presence.sortie' => 'A quitté le cours',
			'presence.absente' => 'Absence',
			'presence.excusee' => 'Absence excusée',
			'presence.confirmationEnAttente' => 'À confirmer',
			'presence.corrigeeManuel' => 'Correction manuelle',
			'presence.finalisee' => 'Définitif',
			'presence.inconnu' => 'État inconnu',
			'presence.entreeInstant' => 'en salle à l\'instant',
			'presence.entreeMinutes' => ({required Object minutes}) => 'en salle depuis ${minutes} min',
			'presence.retardMinutes' => ({required Object minutes}) => '${minutes} min après l\'heure',
			'presence.silenceInstant' => 'sans nouvelles depuis quelques secondes',
			'presence.silenceMinutes' => ({required Object minutes}) => 'sans nouvelles depuis ${minutes} min',
			'presence.attenteInstant' => 'le cours vient de commencer',
			'presence.attenteMinutes' => ({required Object minutes}) => 'le cours a commencé il y a ${minutes} min',
			'bienvenue.titre' => 'Bienvenue',
			'attente.titre' => 'Votre dossier est en cours de vérification',
			'attente.dossierIncomplet' => 'Il manque encore des pièces à votre dossier.',
			'attente.enVerification' => 'Nous vérifions votre dossier. Vous recevrez une notification dès qu\'il est validé.',
			'attente.refuse' => 'Votre dossier n\'a pas été validé.',
			'attente.suspendu' => 'Votre compte est suspendu.',
			'attente.contacterAcademie' => 'Contacter l\'académie',
			'attente.deposeLe' => ({required Object date}) => 'Déposé le ${date}',
			'attente.delai' => 'La vérification prend en général moins de 48 heures.',
			'attente.aFournir' => 'À fournir',
			'attente.pieceIdentite' => 'Une pièce d\'identité',
			'attente.signatureContrat' => 'La signature du contrat',
			'attente.carteAccuse' => 'Ce que vous devez savoir',
			'attente.deposerLaPiece' => 'Déposer ma pièce',
			'attente.signerLeContrat' => 'Lire et signer',
			'attente.lireLaCarte' => 'Lire',
			'attente.toutEstDepose' => 'Tout est déposé.',
			'attente.corriger' => 'Reprendre mon dossier',
			'attente.suspenduDetail' => 'Vous pouvez joindre l\'académie pour connaître la marche à suivre.',
			'attente.seDeconnecter' => 'Se déconnecter',
			'connexion.titre' => 'Se connecter',
			'connexion.intro' => 'Nous vous envoyons un lien par courriel. Aucun mot de passe à retenir, donc aucun à perdre.',
			'connexion.courriel' => 'Votre adresse électronique',
			'connexion.courrielIndice' => 'vous@exemple.com',
			'connexion.motDePasseDemo' => 'Mot de passe de démonstration',
			'connexion.envoyerLien' => 'Recevoir le lien',
			'connexion.avecGoogle' => 'Continuer avec Google',
			'connexion.ou' => 'ou',
			'connexion.lienEnvoye' => 'Lien envoyé',
			'connexion.lienEnvoyeDetail' => ({required Object courriel}) => 'Ouvrez le message envoyé à ${courriel}, puis suivez le lien. Vous pouvez laisser cette page ouverte.',
			'connexion.changerAdresse' => 'Utiliser une autre adresse',
			'connexion.erreurCourriel' => 'Cette adresse ne semble pas valide.',
			'connexion.erreurEnvoi' => 'L\'envoi n\'a pas abouti. Réessayez dans un instant.',
			'connexion.appareilEleveAide' => 'Vous êtes tuteur et vous préparez l\'appareil d\'un élève ?',
			'connexion.appareilEleve' => 'Connecter l\'appareil d\'un élève',
			'connexion.feuilleAppareil.pourQui' => 'Réservé aux tuteurs déjà inscrits. Cet écran donne à un élève de votre foyer son propre accès, sur sa tablette ou son téléphone, sans lui confier votre compte.',
			'connexion.feuilleAppareil.etapesTitre' => 'Où trouver le code',
			'connexion.feuilleAppareil.etape1' => 'Sur votre propre appareil, ouvrez Foyer et appareils.',
			'connexion.feuilleAppareil.etape2' => 'Ouvrez le profil de l\'élève, puis Ajouter un appareil.',
			'connexion.feuilleAppareil.etape3' => 'Un code de six caractères s\'affiche. Il reste valable dix minutes.',
			'connexion.feuilleAppareil.etape4' => 'Saisissez-le ici, sur l\'appareil de l\'élève.',
			'connexion.feuilleAppareil.plafond' => 'Deux appareils au plus par élève. Au-delà, révoquez-en un depuis Foyer et appareils.',
			'connexion.feuilleAppareil.saisir' => 'Saisir le code',
			'connexion.feuilleAppareil.fermer' => 'Fermer',
			'inscription.titre' => 'Créer votre compte',
			'inscription.etapeSur' => ({required Object n, required Object total}) => 'Étape ${n} sur ${total}',
			'inscription.tempsRestant' => ({required Object minutes}) => 'Environ ${minutes} min',
			'inscription.roleQuestion' => 'Vous inscrivez-vous comme parent ou comme enseignant ?',
			'inscription.roleTuteur' => 'Parent ou tuteur',
			'inscription.roleEleveAdulte' => 'Élève adulte, pour moi-même',
			'inscription.roleEnseignant' => 'Enseignant',
			'inscription.autreAide' => 'Écrivez à l\'académie et nous créerons votre accès. Cette page ne peut pas le faire pour vous.',
			'inscription.identiteQuestion' => 'Comment vous appelez-vous ?',
			'inscription.identiteRaison' => 'Ce nom doit être celui de votre pièce d\'identité.',
			'inscription.prenom' => 'Prénom',
			'inscription.nom' => 'Nom',
			'inscription.genreQuestion' => 'Vous êtes',
			'inscription.genreHomme' => 'Un homme',
			'inscription.genreFemme' => 'Une femme',
			'inscription.genreRaison' => 'Cette réponse ne sert qu\'à confier votre pièce d\'identité à un membre du personnel du même genre.',
			'inscription.recapitulatif' => 'Avant de continuer',
			'inscription.creer' => 'Créer mon compte',
			'inscription.erreur' => 'La création du compte n\'a pas abouti. Réessayez dans un instant.',
			'inscription.champRequis' => 'Cette réponse est nécessaire pour continuer.',
			'contrat.titre' => 'Ce que vous signez',
			'contrat.intro' => 'Deux points comptent plus que les autres. Ils sont écrits ici en clair plutôt qu\'au milieu d\'un texte long.',
			'contrat.pointEnregistrement' => 'Chaque cours est enregistré en audio, conservé trente jours, puis effacé. Chaque écoute est inscrite au journal, avec le nom de qui écoute.',
			'contrat.pointControle' => 'Un contrôleur qualité peut assister à un cours sans être vu. La salle le rappelle en permanence, que la visite ait lieu ou non.',
			'contrat.pointCoordonnees' => 'Vous ne voyez jamais les coordonnées d\'une famille : ni nom complet, ni courriel, ni téléphone.',
			'contrat.lireTexte' => 'Lire le texte complet',
			'contrat.accepter' => 'J\'ai lu et j\'accepte',
			'contrat.accepteLe' => ({required Object date}) => 'Accepté le ${date}',
			'contrat.erreur' => 'La signature n\'a pas abouti. Réessayez dans un instant.',
			'accuse.titre' => 'À savoir avant de commencer',
			'accuse.compris' => 'J\'ai compris',
			'consentement.titre' => 'Consentements',
			'kyc.titre' => 'Votre pièce d\'identité',
			'kyc.intro' => 'Une photo lisible suffit. Elle est conservée le temps de la vérification, puis effacée.',
			'kyc.typeQuestion' => 'Quelle pièce déposez-vous ?',
			'kyc.carteIdentite' => 'Carte d\'identité',
			'kyc.passeport' => 'Passeport',
			'kyc.titreSejour' => 'Titre de séjour',
			'kyc.choisirFichier' => 'Choisir la photo',
			'kyc.fichierChoisi' => 'Photo prête à être envoyée',
			'kyc.envoyer' => 'Envoyer ma pièce',
			'kyc.envoiEnCours' => 'Envoi en cours',
			'kyc.deposee' => 'Pièce reçue',
			'kyc.erreur' => 'L\'envoi n\'a pas abouti. Réessayez dans un instant.',
			'kyc.tropVolumineux' => ({required Object taille}) => 'Cette photo dépasse ${taille} Mo. Reprenez-la en qualité plus basse.',
			'appareils.titre' => 'Appareils',
			'appareils.regle' => 'Deux appareils au maximum par enfant, un seul en cours à la fois.',
			'appareils.ajouter' => 'Ajouter un appareil',
			'appareils.limiteAtteinte' => ({required Object prenom}) => 'Deux appareils sont déjà appairés pour ${prenom}. Retirez-en un pour en ajouter un autre.',
			'appareils.codeTitre' => 'Sur l\'appareil de l\'enfant',
			'appareils.codeInstruction' => 'Ouvrez l\'application Rewayah, puis entrez ce code.',
			'appareils.expireDans' => ({required Object temps}) => 'Expire dans ${temps}',
			'appareils.expire' => 'Ce code a expiré.',
			'appareils.regenerer' => 'Générer un nouveau code',
			'appareils.revoquer' => 'Retirer',
			'appareils.revoquerConfirmation' => 'Retirer cet appareil ? L\'enfant devra le réappairer pour s\'en resservir.',
			'appareils.derniereUtilisation' => ({required Object quand}) => 'Utilisé ${quand}',
			'appareils.jamaisUtilise' => 'Jamais utilisé',
			'appareils.erreur' => 'L\'opération n\'a pas abouti. Réessayez dans un instant.',
			'enfant.titre' => 'Ajouter un enfant',
			'enfant.prenom' => 'Son prénom',
			'enfant.nom' => 'Son nom',
			'enfant.age' => 'Son âge',
			'enfant.ageInvalide' => 'Indiquez un âge entre 3 et 18 ans.',
			'enfant.ageRaison' => 'L\'âge fixe le mode d\'affichage et la politique caméra. Vous pourrez changer les deux à tout moment.',
			'enfant.creer' => 'Ajouter au foyer',
			'enfant.erreur' => 'L\'ajout n\'a pas abouti. Réessayez dans un instant.',
			'enfant.aucun' => 'Aucun enfant dans le foyer',
			'enfant.aucunDetail' => 'Ajoutez votre premier enfant pour pouvoir appairer son appareil.',
			'foyer.titre' => 'Foyer',
			'foyer.ajouterProfil' => 'Ajouter un profil élève',
			'ficheEleve.informations' => 'Informations de l\'élève',
			'ficheEleve.inscription' => 'Parcours et inscription',
			'ficheEleve.interface' => 'Interface',
			'ficheEleve.camera' => 'Caméra en cours',
			'ficheEleve.acces' => 'Accès Rewayah',
			'ficheEleve.appareils' => 'Appareils',
			'disponibilites.titre' => 'Quand vos enfants peuvent-ils suivre un cours ?',
			'disponibilites.titreEnseignant' => 'Quand pouvez-vous donner cours ?',
			'disponibilites.consigne' => ({required Object prenom}) => 'Touchez les heures possibles pour ${prenom}.',
			'disponibilites.consigneEnseignant' => 'Touchez les heures où vous êtes disponible.',
			'disponibilites.effet' => 'Un enseignant choisira parmi ces heures. Plus vous en proposez, plus vite le cours démarre.',
			'disponibilites.effetEnseignant' => 'Vous ne verrez que les élèves dont les heures croisent les vôtres.',
			'disponibilites.fuseau' => ({required Object fuseau}) => 'Heures affichées en ${fuseau}',
			'disponibilites.aucune' => ({required Object prenom}) => 'Aucune heure proposée pour ${prenom}',
			'disponibilites.aucuneDetail' => ({required Object prenom}) => 'Sans créneau, aucun enseignant ne peut prendre ${prenom} en charge.',
			'disponibilites.posees' => ({required Object nombre}) => '${nombre} heures proposées',
			'disponibilites.poseeUne' => '1 heure proposée',
			'disponibilites.cellulePosee' => ({required Object jour, required Object heure}) => '${jour} ${heure} heures, proposé. Toucher pour retirer',
			'disponibilites.celluleLibre' => ({required Object jour, required Object heure}) => '${jour} ${heure} heures, libre. Toucher pour proposer',
			'disponibilites.erreur' => 'Ce créneau n\'a pas pu être enregistré. Réessayez.',
			'disponibilites.joursCourts.0' => 'Lun',
			'disponibilites.joursCourts.1' => 'Mar',
			'disponibilites.joursCourts.2' => 'Mer',
			'disponibilites.joursCourts.3' => 'Jeu',
			'disponibilites.joursCourts.4' => 'Ven',
			'disponibilites.joursCourts.5' => 'Sam',
			'disponibilites.joursCourts.6' => 'Dim',
			'disponibilites.joursLongs.0' => 'lundi',
			'disponibilites.joursLongs.1' => 'mardi',
			'disponibilites.joursLongs.2' => 'mercredi',
			'disponibilites.joursLongs.3' => 'jeudi',
			'disponibilites.joursLongs.4' => 'vendredi',
			'disponibilites.joursLongs.5' => 'samedi',
			'disponibilites.joursLongs.6' => 'dimanche',
			'creneaux.titre' => 'Créneaux',
			'creneaux.ongletHeures' => 'Mes heures',
			'creneaux.ongletEleves' => 'Élèves en attente',
			'creneaux.mesEleves' => ({required Object nombre, required Object plafond}) => 'Vous suivez ${nombre} élèves sur ${plafond} possibles.',
			'creneaux.aucunEleve' => 'Aucun élève en attente sur vos heures',
			'creneaux.aucunEleveDetail' => 'Proposez d\'autres heures pour voir plus de familles.',
			'creneaux.attendDepuis' => ({required Object jours}) => 'Attend depuis ${jours} jours',
			'creneaux.attendUnJour' => 'Attend depuis 1 jour',
			'creneaux.attendAujourdhui' => 'Demande déposée aujourd\'hui',
			'creneaux.niveau' => ({required Object niveau}) => 'Niveau ${niveau}',
			'creneaux.prendre' => ({required Object jour, required Object heure}) => 'Prendre ${jour} à ${heure} h',
			'creneaux.priseEnCours' => 'Enregistrement',
			'creneaux.plafondAtteint' => ({required Object nombre}) => 'Vous suivez déjà ${nombre} élèves, votre maximum. Un élève pris est un engagement durable, pas une réservation.',
			'creneaux.plafondDemander' => 'Demander à suivre plus d\'élèves',
			'creneaux.demandeTitre' => 'Combien d\'élèves pouvez-vous suivre ?',
			'creneaux.demandeMotif' => 'Pourquoi ce changement ?',
			'creneaux.demandeMotifRequis' => 'Un motif est nécessaire : c\'est lui qui permet de trancher.',
			'creneaux.demandeEnvoyer' => 'Envoyer la demande',
			'creneaux.demandeEnvoyee' => 'Demande envoyée. L\'administration la tranchera.',
			'creneaux.eleves' => ({required Object nombre}) => '${nombre} élèves',
			'creneaux.erreur' => ({required Object message}) => 'L\'opération n\'a pas abouti : ${message}',
			'priere.fajr' => 'Fajr',
			'priere.dhuhr' => 'Dhuhr',
			'priere.asr' => 'Asr',
			'priere.maghrib' => 'Maghrib',
			'priere.isha' => 'Isha',
			'priere.entree' => ({required Object priere, required Object minutes}) => '${priere}, ${minutes} min',
			'priere.annonce' => ({required Object priere, required Object heure}) => 'Ce cours sera interrompu pour ${priere}, vers ${heure}.',
			'priere.annonceAucune' => 'Aucune interruption prévue pendant ce cours.',
			'priere.alerte' => ({required Object priere, required Object minutes}) => '${priere} dans ${minutes} min',
			'priere.alerteMaintenant' => ({required Object priere, required Object heure}) => 'Pause pour ${priere}, reprise à ${heure}',
			'priere.pause' => 'Pause',
			'priere.lieu' => ({required Object lieu}) => 'Horaires calculés pour ${lieu}',
			'priere.lieuSansNom' => 'Horaires calculés pour le lieu de l\'enseignant',
			'priere.ajustee' => ({required Object priere, required Object minutes}) => '${priere} ajustée de ${minutes} min par l\'enseignant',
			'priere.reglagesAbsents' => 'L\'enseignant n\'a pas encore réglé ses horaires de prière.',
			'eleveConnexion.entrerCode' => 'J\'ai un code',
			'eleveConnexion.scanner' => 'Scanner le carré',
			'eleveConnexion.codeInvite' => 'Entre le code affiché sur le téléphone de tes parents',
			'eleveConnexion.codeErreur' => 'Ce code ne marche pas',
			'eleveConnexion.codeExpire' => 'Ce code est trop vieux. Demande-en un nouveau.',
			'eleveConnexion.choisirProfil' => 'Qui es-tu ?',
			'eleveConnexion.nouveauCode' => 'Choisis ton code secret',
			'eleveConnexion.nouveauCodeConfirmer' => 'Entre-le encore une fois',
			'eleveConnexion.codeDifferent' => 'Les deux codes ne sont pas les mêmes',
			'eleveConnexion.codeEnregistre' => 'Code enregistré',
			'dossiers.titre' => 'Dossiers à valider',
			'dossiers.aucun' => 'Aucun dossier en attente',
			'dossiers.aucunDetail' => 'Les nouvelles inscriptions apparaîtront ici, la plus ancienne en premier.',
			'dossiers.restantUn' => '1 dossier en attente',
			'dossiers.restants' => ({required Object n}) => '${n} dossiers en attente',
			'dossiers.deposeLe' => ({required Object date}) => 'Déposé le ${date}',
			'dossiers.inscritAujourdhui' => 'Inscrit aujourd\'hui',
			'dossiers.inscritDepuisUnJour' => 'Inscrit depuis 1 jour',
			'dossiers.inscritDepuis' => ({required Object jours}) => 'Inscrit depuis ${jours} jours',
			'dossiers.sansPiece' => 'Aucune pièce déposée',
			'dossiers.sansPieceDetail' => 'Cette personne a créé son compte et accepté les contrats, mais n\'a pas encore envoyé sa pièce d\'identité. Il n\'y a donc rien à vérifier : le geste est chez elle.',
			'dossiers.pieceNonVisible' => 'Pièce hors de votre portée',
			'dossiers.pieceNonVisibleDetail' => 'Une pièce a bien été déposée, mais la règle de genre vous interdit de la consulter. Un membre du personnel du même genre que cette personne doit la vérifier.',
			'dossiers.rienATrancher' => 'Rien à trancher pour l\'instant',
			'dossiers.apercu' => 'La pièce déposée',
			'dossiers.apercuIndisponible' => 'Aperçu indisponible',
			'dossiers.verifications' => 'Vérifications',
			'dossiers.pointLisible' => 'La pièce est lisible',
			'dossiers.pointNom' => 'Le nom correspond à celui du compte',
			'dossiers.pointValidite' => 'La pièce n\'est pas expirée',
			'dossiers.verdict' => 'Décision',
			'dossiers.approuver' => 'Valider le dossier',
			'dossiers.refuser' => 'Refuser',
			'dossiers.motif' => 'Ce qui ne va pas, en une phrase',
			'dossiers.motifRequis' => 'Un refus doit dire ce qui ne va pas : la famille n\'a que cette phrase pour corriger.',
			'dossiers.journalisation' => 'Chaque consultation de pièce est inscrite au journal d\'audit, avec votre nom.',
			'dossiers.genreManquant' => 'Renseignez votre genre dans votre profil avant de consulter un dossier.',
			'dossiers.erreur' => 'La décision n\'a pas abouti. Réessayez dans un instant.',
			'admin.tableau.titre' => 'Centre de commande',
			'admin.tableau.dossiers' => 'Dossiers à valider',
			'admin.tableau.foyers' => 'Foyers sans enseignant',
			'admin.tableau.rapports' => 'Cahiers manquants',
			'admin.tableau.incidents' => 'Incidents (24 h)',
			'admin.tableau.comptes' => 'Accès échus',
			'admin.tableau.demandes' => 'Demandes à trancher',
			'admin.tableau.compteursErreur' => 'Les compteurs n\'ont pas pu être lus. Réessayez dans un instant.',
			'admin.tableau.aTraiter' => 'À traiter en premier',
			'admin.tableau.aTraiterAucun' => 'Rien à traiter',
			'admin.tableau.aTraiterAucunDetail' => 'Les dossiers déposés et les demandes des familles et des enseignants apparaîtront ici, le plus ancien en premier.',
			'admin.tableau.aTraiterPortee' => 'Les foyers sans enseignant s\'attribuent depuis leur compteur. Les trois derniers se règlent ailleurs : ils n\'ont pas encore d\'écran d\'action.',
			'admin.tableau.outils' => 'Outils',
			'admin.tableau.outilsComptes' => 'Comptes',
			'admin.tableau.outilsComptesDetail' => 'Toutes les personnes inscrites, celles qui attendent une décision en premier. Y compris celles qui n\'ont pas encore déposé de pièce.',
			'admin.tableau.outilsAccesAgents' => 'Accès des agents IA',
			'admin.tableau.outilsAccesAgentsDetail' => 'Ouvrir un accès en lecture seule, borné dans le temps, sur le parcours d\'une personne.',
			'admin.tableau.listeErreur' => 'La liste n\'a pas pu être lue en entier. Les compteurs, eux, restent justes.',
			'admin.tableau.ligneDossier' => ({required Object prenom}) => 'Dossier d\'identité de ${prenom}',
			'admin.tableau.ligneReaffectation' => ({required Object prenom}) => 'Changement d\'enseignant pour ${prenom}',
			'admin.tableau.lignePlafond' => ({required Object prenom}) => 'Plafond d\'élèves de ${prenom}',
			'admin.tableau.ligneRegle' => ({required Object prenom}) => 'Changement de règle pour ${prenom}',
			'admin.tableau.attenteAujourdhui' => 'Déposé aujourd\'hui',
			'admin.tableau.attenteUnJour' => 'En attente depuis 1 jour',
			'admin.tableau.attenteJours' => ({required Object jours}) => 'En attente depuis ${jours} jours',
			'admin.demandes.titre' => 'Demandes et règles',
			'admin.demandes.restanteUne' => '1 demande en attente',
			'admin.demandes.restantes' => ({required Object n}) => '${n} demandes en attente',
			'admin.demandes.aucune' => 'Aucune demande en attente',
			'admin.demandes.aucuneDetail' => 'Les demandes des familles, des élèves autonomes et des enseignants arrivent ici, la plus ancienne en premier.',
			'admin.demandes.faitePar' => ({required Object date, required Object role}) => 'Demandée le ${date}, par ${role}',
			'admin.demandes.roleGuardian' => 'un tuteur',
			'admin.demandes.roleTeacher' => 'un enseignant',
			'admin.demandes.roleStudent' => 'un élève autonome',
			'admin.demandes.roleAdmin' => 'l\'administration',
			'admin.demandes.roleController' => 'un contrôleur',
			'admin.demandes.roleInconnu' => 'une partie au dossier',
			'admin.demandes.reclame' => 'Ce qui est demandé',
			'admin.demandes.reclameReaffectation' => ({required Object prenom}) => 'Changer l\'enseignant de ${prenom}',
			'admin.demandes.reclamePlafond' => ({required Object valeur}) => 'Porter le plafond à ${valeur} élèves',
			'admin.demandes.reclameRegle' => ({required Object regle, required Object valeur}) => 'Porter ${regle} à ${valeur} min',
			'admin.demandes.reclameRegleSansValeur' => ({required Object regle}) => 'Revoir ${regle}',
			'admin.demandes.motifDemande' => 'Motif invoqué',
			'admin.demandes.verdict' => 'Décision',
			'admin.demandes.accorder' => 'Accorder',
			'admin.demandes.refuser' => 'Refuser',
			'admin.demandes.motif' => 'Ce qui motive ce refus, en une phrase',
			'admin.demandes.motifRequis' => 'Un refus doit dire pourquoi : c\'est la seule phrase que la partie recevra.',
			'admin.demandes.effet' => 'Accorder applique l\'effet en base : l\'affectation se clôt, ou la règle se pose. Cet écran ne fait que rendre le verdict.',
			'admin.demandes.journalisation' => 'Chaque décision et chaque règle posée sont inscrites au journal d\'audit, avec votre nom.',
			'admin.demandes.feuille' => ({required Object prenom}) => 'Les règles de ${prenom}',
			'admin.demandes.feuilleIntro' => 'La valeur de la plateforme et celle qui s\'applique, côte à côte. Une règle se change ici sans qu\'une demande existe.',
			'admin.demandes.regleDuree' => 'Durée d\'une séance',
			'admin.demandes.regleMinimum' => 'Durée minimale payable',
			'admin.demandes.reglePause' => 'Pause entre deux cours',
			'admin.demandes.reglePlafond' => 'Plafond d\'élèves',
			'admin.demandes.regleInconnue' => 'Règle non reconnue',
			'admin.demandes.plateforme' => ({required Object valeur}) => 'Plateforme : ${valeur}',
			'admin.demandes.effective' => ({required Object valeur}) => 'Appliquée : ${valeur}',
			'admin.demandes.minutes' => ({required Object valeur}) => '${valeur} min',
			'admin.demandes.eleves' => ({required Object valeur}) => '${valeur} élèves',
			'admin.demandes.surchargeDepuis' => ({required Object date, required Object motif}) => 'Posée le ${date} : ${motif}',
			'admin.demandes.sansSurcharge' => 'Cet élève suit la règle de la plateforme.',
			'admin.demandes.changer' => 'Changer',
			'admin.demandes.clore' => 'Revenir à la règle de la plateforme',
			'admin.demandes.historique' => 'Surcharges closes',
			'admin.demandes.historiqueLigne' => ({required Object valeur, required Object debut, required Object fin}) => '${valeur}, du ${debut} au ${fin}',
			'admin.demandes.historiqueMotifs' => ({required Object motif, required Object cloture}) => 'Posée : ${motif}. Close : ${cloture}.',
			'admin.demandes.poserTitre' => ({required Object regle, required Object prenom}) => '${regle}, pour ${prenom}',
			'admin.demandes.cloreTitre' => ({required Object prenom}) => 'Clore la surcharge de ${prenom}',
			'admin.demandes.poserMotif' => 'Pourquoi ce changement ?',
			'admin.demandes.poserMotifRequis' => 'Une règle sans motif ne se relit pas six mois plus tard.',
			'admin.demandes.poserEnvoyer' => 'Poser la règle',
			'admin.demandes.cloreEnvoyer' => 'Clore la surcharge',
			'admin.demandes.erreur' => ({required Object message}) => 'L\'opération n\'a pas abouti : ${message}',
			'admin.attribution.titre' => 'Attribution',
			'admin.attribution.intro' => 'Quand aucun enseignant n\'a pris un enfant, c\'est ici qu\'on lui en donne un.',
			'admin.attribution.colonneEleves' => 'Élèves sans enseignant',
			'admin.attribution.colonneEnseignants' => 'Enseignants',
			'admin.attribution.aucunEleve' => 'Chaque élève a son enseignant',
			'admin.attribution.aucunEleveDetail' => 'Les enfants que personne n\'a encore pris apparaîtront ici, celui qui attend depuis le plus longtemps en premier.',
			'admin.attribution.erreurEleves' => 'La file n\'a pas pu être lue. Réessayez dans un instant.',
			'admin.attribution.erreurEnseignants' => 'Les enseignants n\'ont pas pu être lus. Réessayez dans un instant.',
			'admin.attribution.attendAujourdhui' => 'Inscrit aujourd\'hui',
			'admin.attribution.attendUnJour' => 'Attend depuis 1 jour',
			'admin.attribution.attendJours' => ({required Object jours}) => 'Attend depuis ${jours} jours',
			'admin.attribution.niveau' => ({required Object niveau}) => 'Niveau ${niveau}',
			'admin.attribution.heuresProposees' => ({required Object nombre}) => '${nombre} heures proposées',
			'admin.attribution.heureProposee' => '1 heure proposée',
			'admin.attribution.sansHeure' => 'Aucune heure proposée',
			'admin.attribution.sansHeureDetail' => 'Tant que la famille n\'a posé aucun créneau, personne ne peut lui donner d\'enseignant, pas même vous. Le geste est chez elle, sur ses disponibilités.',
			'admin.attribution.changerEleve' => 'Choisir un autre élève',
			'admin.attribution.choisirEleve' => 'Choisissez un élève',
			'admin.attribution.choisirEleveDetail' => 'Les enseignants s\'afficheront ici, ceux qui partagent une heure avec lui en premier.',
			'admin.attribution.charge' => ({required Object actifs, required Object plafond}) => '${actifs} élèves sur ${plafond}',
			'admin.attribution.complet' => 'Plafond atteint',
			'admin.attribution.libreSur' => ({required Object jour, required Object heure}) => 'Libre ${jour} à ${heure} h',
			'admin.attribution.libreSurPlusieurs' => ({required Object nombre}) => 'Libre sur ${nombre} des heures proposées',
			'admin.attribution.sansHeureCommune' => 'Aucune heure commune',
			'admin.attribution.quelleHeure' => 'Sur quelle heure ?',
			'admin.attribution.creneau' => ({required Object jour, required Object heure}) => '${jour} à ${heure} h',
			'admin.attribution.motif' => 'Pourquoi passer outre ?',
			'admin.attribution.motifRequis' => ({required Object prenom}) => '${prenom} n\'a pas posé cette heure. L\'attribuer quand même peut se justifier, et cela s\'inscrit au journal.',
			'admin.attribution.attribuer' => ({required Object eleve, required Object enseignant}) => 'Attribuer ${eleve} à ${enseignant}',
			'admin.attribution.journalisation' => 'Chaque attribution est journalisée : qui a décidé, quand, sur quelle heure, et le motif s\'il a fallu passer outre.',
			'admin.attribution.effet' => 'L\'élève quitte cette file et ses cours sont posés au calendrier tout de suite.',
			'admin.attribution.erreur' => ({required Object message}) => 'L\'attribution n\'a pas abouti : ${message}',
			'admin.groupes.titre' => 'Groupes',
			'admin.groupes.intro' => 'Chaque groupe réunit un enseignant et ses élèves autour d\'un créneau commun : c\'est là que se donne le cours.',
			'admin.groupes.colonneGroupe' => 'Groupe',
			'admin.groupes.colonneEnseignant' => 'Enseignant',
			'admin.groupes.colonneType' => 'Public',
			'admin.groupes.colonneMembres' => 'Membres',
			'admin.groupes.colonneCreneau' => 'Créneau',
			'admin.groupes.colonneEtat' => 'État',
			'admin.groupes.typeEnfant' => 'Enfants',
			'admin.groupes.typeAdulte' => 'Adultes',
			'admin.groupes.filtreTousTypes' => 'Tous les publics',
			'admin.groupes.etatActif' => 'Actif',
			'admin.groupes.etatCloture' => 'Clôturé',
			'admin.groupes.membresSur' => ({required Object actifs, required Object seuil}) => '${actifs} / ${seuil}',
			'admin.groupes.aucun' => 'Aucun groupe créé',
			'admin.groupes.aucunDetail' => 'Créez un premier groupe pour donner un enseignant et des élèves à un créneau commun.',
			'admin.groupes.aucunAvecCeFiltre' => 'Aucun groupe avec ce filtre',
			'admin.groupes.aucunAvecCeFiltreDetail' => 'Changez de filtre pour voir les autres groupes.',
			'admin.groupes.erreur' => 'Les groupes n\'ont pas pu être lus. Réessayez dans un instant.',
			'admin.groupes.creer' => 'Créer un groupe',
			'admin.groupes.creerTitre' => 'Créer un groupe',
			'admin.groupes.champLibelle' => 'Nom du groupe',
			'admin.groupes.champEnseignantId' => 'Identifiant de l\'enseignant',
			'admin.groupes.champType' => 'Public',
			'admin.groupes.champJour' => 'Jour',
			'admin.groupes.champHeure' => 'Heure (0-23)',
			_ => null,
		} ?? switch (path) {
			'admin.groupes.champSeuil' => 'Seuil maximal',
			'admin.groupes.creerEnvoyer' => 'Créer le groupe',
			'admin.groupes.creerErreur' => ({required Object message}) => 'La création n\'a pas abouti : ${message}',
			'admin.groupes.detailTitre' => ({required Object libelle}) => 'Groupe ${libelle}',
			'admin.groupes.detailMembres' => 'Membres',
			'admin.groupes.detailAucunMembre' => 'Aucun élève dans ce groupe pour l\'instant.',
			'admin.groupes.actionAjouter' => 'Ajouter un élève',
			'admin.groupes.actionRetirer' => 'Retirer',
			'admin.groupes.actionModifierSeuil' => 'Modifier le seuil',
			'admin.groupes.actionObservation' => 'Réglages d\'observation',
			'admin.groupes.actionCloturer' => 'Clôturer le groupe',
			'admin.groupes.ajouterTitre' => ({required Object libelle}) => 'Ajouter un élève à ${libelle}',
			'admin.groupes.champEleveId' => 'Identifiant de l\'élève',
			'admin.groupes.champMotif' => 'Motif',
			'admin.groupes.motifRequis' => 'Un motif est requis, il s\'inscrit au journal d\'audit.',
			'admin.groupes.ajouterEnvoyer' => 'Ajouter',
			'admin.groupes.ajouterErreur' => ({required Object message}) => 'L\'ajout n\'a pas abouti : ${message}',
			'admin.groupes.retirerTitre' => ({required Object prenom, required Object libelle}) => 'Retirer ${prenom} de ${libelle}',
			'admin.groupes.retirerEnvoyer' => 'Retirer',
			'admin.groupes.retirerErreur' => ({required Object message}) => 'Le retrait n\'a pas abouti : ${message}',
			'admin.groupes.modifierSeuilTitre' => ({required Object libelle}) => 'Seuil maximal de ${libelle}',
			'admin.groupes.modifierSeuilEnvoyer' => 'Enregistrer',
			'admin.groupes.modifierSeuilErreur' => ({required Object message}) => 'La modification n\'a pas abouti : ${message}',
			'admin.groupes.cloturerTitre' => ({required Object libelle}) => 'Clôturer ${libelle}',
			'admin.groupes.cloturerDetail' => 'Tous les membres actifs seront retirés du groupe. Cette action ne peut pas être annulée.',
			'admin.groupes.cloturerEnvoyer' => 'Clôturer',
			'admin.groupes.cloturerErreur' => ({required Object message}) => 'La clôture n\'a pas abouti : ${message}',
			'admin.groupes.journalisation' => 'Chaque création, ajout, retrait et clôture est inscrit au journal d\'audit.',
			'admin.groupes.observationTitre' => ({required Object libelle}) => 'Observation : ${libelle}',
			'admin.groupes.observationErreur' => 'Le réglage n\'a pas pu être enregistré.',
			'admin.groupes.observationCapaciteAbsente' => 'Cette installation n\'a pas encore la mise à jour serveur que ce réglage demande (migration 0036). Réessayer n\'y changera rien : elle doit d\'abord être appliquée à la base.',
			'admin.diagnostics.titre' => 'Diagnostics',
			'admin.diagnostics.intro' => 'Chaque élève inscrit attend un premier niveau avant de rejoindre un groupe : c\'est ici que ce placement se décide.',
			'admin.diagnostics.aucunProgramme' => 'Aucun programme publié',
			'admin.diagnostics.aucunProgrammeDetail' => 'Publiez une première version du programme (Pédagogie > Programmes) avant de pouvoir décider un placement.',
			'admin.diagnostics.erreur' => 'La file n\'a pas pu être lue. Réessayez dans un instant.',
			'admin.diagnostics.restants' => ({required Object n}) => '${n} élèves restants',
			'admin.diagnostics.restantUn' => '1 élève restant',
			'admin.diagnostics.inscritAujourdhui' => 'Inscrit aujourd\'hui',
			'admin.diagnostics.inscritDepuisUnJour' => 'Inscrit depuis 1 jour',
			'admin.diagnostics.inscritDepuis' => ({required Object jours}) => 'Inscrit depuis ${jours} jours',
			'admin.diagnostics.aucun' => 'Aucun élève à diagnostiquer',
			'admin.diagnostics.aucunDetail' => 'Tous les élèves inscrits ont déjà un niveau décidé.',
			'admin.diagnostics.champNiveau' => 'Niveau de placement',
			'admin.diagnostics.champMotif' => 'Motif',
			'admin.diagnostics.motifRequis' => 'Un motif est requis, il s\'inscrit au journal d\'audit.',
			'admin.diagnostics.decider' => 'Décider le placement',
			'admin.diagnostics.deciderErreur' => ({required Object message}) => 'La décision n\'a pas abouti : ${message}',
			'admin.diagnostics.journalisation' => 'Chaque placement décidé est inscrit au journal d\'audit.',
			'admin.qualite.titre' => 'Qualité',
			'admin.qualite.intro' => 'Les anomalies pédagogiques détectées : rapports manquants, blocages sans suivi, évaluations en retard.',
			'admin.qualite.erreur' => 'Les anomalies n\'ont pas pu être lues. Réessayez dans un instant.',
			'admin.qualite.aucune' => 'Aucune anomalie détectée',
			'admin.qualite.aucuneDetail' => 'Tout est à jour : rapports rédigés, blocages suivis, évaluations à l\'heure.',
			'admin.qualite.filtreToutes' => 'Toutes',
			'admin.qualite.filtreOuvertes' => 'Ouvertes',
			'admin.qualite.filtreTraitees' => 'Traitées',
			'admin.qualite.groupeRapportManquant' => 'Rapports de séance manquants',
			'admin.qualite.groupeBlocageSansSuivi' => 'Blocages sans suivi',
			'admin.qualite.groupeEvaluationEnRetard' => 'Évaluations en retard',
			'admin.qualite.colonnePersonne' => 'Concerne',
			'admin.qualite.colonneDepuis' => 'Depuis',
			'admin.qualite.colonneStatut' => 'Statut',
			'admin.qualite.statutOuvert' => 'Ouverte',
			'admin.qualite.statutTraite' => 'Traitée',
			'admin.qualite.depuisAujourdhui' => 'Aujourd\'hui',
			'admin.qualite.depuisUnJour' => '1 jour',
			'admin.qualite.depuisJours' => ({required Object jours}) => '${jours} jours',
			'admin.qualite.actionTraiter' => 'Marquer traité',
			'admin.qualite.traiterTitre' => ({required Object personne}) => 'Marquer traité : ${personne}',
			'admin.qualite.champNote' => 'Note (optionnelle)',
			'admin.qualite.traiterEnvoyer' => 'Marquer traité',
			'admin.qualite.traiterErreur' => ({required Object message}) => 'Le traitement n\'a pas abouti : ${message}',
			'admin.regles.titre' => 'Règles',
			'admin.regles.intro' => 'Les valeurs par défaut de toute la plateforme. Une exception pour un profil précis se pose depuis Opérations > Règles individuelles, jamais ici.',
			'admin.regles.erreur' => 'Les règles n\'ont pas pu être lues. Réessayez dans un instant.',
			'admin.regles.erreurEcriture' => ({required Object message}) => 'L\'enregistrement n\'a pas abouti : ${message}',
			'admin.regles.valeurInvalide' => 'Entrez un nombre valide.',
			'admin.regles.envoyer' => 'Enregistrer',
			'admin.regles.champValeur' => 'Valeur',
			'admin.regles.absenceSeuil' => 'Seuil d\'absence',
			'admin.regles.absenceSeuilDetail' => 'Au-delà de ce nombre de minutes sans rejoindre la séance, l\'élève est marqué absent.',
			'admin.regles.dureeSeance' => 'Durée de séance',
			'admin.regles.dureeSeanceDetail' => 'La durée par défaut d\'une séance, avant toute exception individuelle.',
			'admin.regles.dureeMinimalePayee' => 'Durée minimale payée',
			'admin.regles.dureeMinimalePayeeDetail' => 'En dessous de cette durée, une séance écourtée reste payée en entier.',
			'admin.regles.pauseEntreSeances' => 'Pause entre deux séances',
			'admin.regles.pauseEntreSeancesDetail' => 'Le temps minimum laissé à un enseignant entre deux séances consécutives.',
			'admin.regles.elevesParEnseignant' => 'Élèves par enseignant',
			'admin.regles.elevesParEnseignantDetail' => 'Le nombre maximal d\'élèves qu\'un enseignant peut suivre en parallèle.',
			'admin.regles.horizonAffectation' => 'Horizon d\'affectation',
			'admin.regles.horizonAffectationDetail' => 'Le nombre de semaines à l\'avance sur lesquelles l\'affectation cherche un enseignant disponible.',
			'admin.regles.ageCameraAuto' => 'Âge minimum caméra automatique',
			'admin.regles.ageCameraAutoDetail' => 'En dessous de cet âge, l\'activation de la caméra reste soumise à l\'accord du tuteur.',
			'admin.regles.ageInterfaceEnfant' => 'Âge maximum interface enfant',
			'admin.regles.ageInterfaceEnfantDetail' => 'En dessous de cet âge, un profil bascule sur l\'interface simplifiée à sa création.',
			'admin.regles.appareilsParEleve' => 'Appareils par élève',
			'admin.regles.appareilsParEleveDetail' => 'Le nombre d\'appareils qu\'un élève peut avoir actifs en même temps.',
			'admin.regles.seancesSimultanees' => 'Séances simultanées par profil',
			'admin.regles.seancesSimultaneesDetail' => 'Le nombre de séances qu\'un même profil peut suivre en même temps.',
			'admin.regles.uniteMinutes' => ({required Object n}) => '${n} min',
			'admin.regles.uniteSemaines' => ({required Object n}) => '${n} sem.',
			'admin.regles.uniteNombre' => ({required Object n}) => '${n}',
			'admin.fonctionnalites.titre' => 'Fonctionnalités',
			'admin.fonctionnalites.intro' => 'Les fonctionnalités qui changent le comportement de toute la plateforme.',
			'admin.fonctionnalites.erreur' => 'Les fonctionnalités n\'ont pas pu être lues. Réessayez dans un instant.',
			'admin.fonctionnalites.erreurEcriture' => ({required Object message}) => 'L\'enregistrement n\'a pas abouti : ${message}',
			'admin.fonctionnalites.valeurInvalide' => 'Entrez un nombre valide.',
			'admin.fonctionnalites.envoyer' => 'Enregistrer',
			'admin.fonctionnalites.champValeur' => 'Valeur',
			'admin.fonctionnalites.multiParticipants' => 'Séances multi-participants',
			'admin.fonctionnalites.multiParticipantsDetail' => 'Autorise plusieurs élèves dans une même séance de visioconférence.',
			'admin.fonctionnalites.participantsMax' => 'Participants maximum',
			'admin.fonctionnalites.participantsMaxDetail' => 'Le nombre de participants autorisés quand les séances multi-participants sont actives.',
			'admin.fonctionnalites.uniteNombre' => ({required Object n}) => '${n}',
			'admin.conservationDonnees.titre' => 'Conservation des données',
			'admin.conservationDonnees.intro' => 'Depuis combien de temps ces éléments restent accessibles avant leur suppression automatique.',
			'admin.conservationDonnees.erreur' => 'Les délais de conservation n\'ont pas pu être lus. Réessayez dans un instant.',
			'admin.conservationDonnees.erreurEcriture' => ({required Object message}) => 'L\'enregistrement n\'a pas abouti : ${message}',
			'admin.conservationDonnees.valeurInvalide' => 'Entrez un nombre valide.',
			'admin.conservationDonnees.envoyer' => 'Enregistrer',
			'admin.conservationDonnees.champValeur' => 'Valeur',
			'admin.conservationDonnees.enregistrements' => 'Enregistrements de séance',
			'admin.conservationDonnees.enregistrementsDetail' => 'Le nombre de jours pendant lesquels un enregistrement de séance reste accessible.',
			'admin.conservationDonnees.documentsIdentite' => 'Documents d\'identité',
			'admin.conservationDonnees.documentsIdentiteDetail' => 'Le nombre de jours pendant lesquels un document d\'identité déposé reste accessible avant sa purge.',
			'admin.conservationDonnees.uniteJours' => ({required Object n}) => '${n} j',
			'admin.evaluations.titre' => 'Évaluations',
			'admin.evaluations.intro' => 'Ce qui est prévu, ce qui a été passé, et les certifications obtenues.',
			'admin.evaluations.erreur' => 'Les évaluations n\'ont pas pu être lues. Réessayez dans un instant.',
			'admin.evaluations.aucune' => 'Aucune évaluation',
			'admin.evaluations.aucuneDetail' => 'Planifiez une première évaluation pour un élève déjà diagnostiqué.',
			'admin.evaluations.aucuneAvecCeFiltre' => 'Aucune évaluation avec ce filtre',
			'admin.evaluations.aucuneAvecCeFiltreDetail' => 'Changez de filtre pour voir les autres évaluations.',
			'admin.evaluations.filtreToutes' => 'Toutes',
			'admin.evaluations.filtrePlanifiees' => 'Planifiées',
			'admin.evaluations.filtreRealisees' => 'Réalisées',
			'admin.evaluations.filtreAnnulees' => 'Annulées',
			'admin.evaluations.filtreCertifications' => 'Certifications',
			'admin.evaluations.colonneEleve' => 'Élève',
			'admin.evaluations.colonneNiveau' => 'Niveau',
			'admin.evaluations.colonneType' => 'Type',
			'admin.evaluations.colonneDatePrevue' => 'Prévue le',
			'admin.evaluations.colonneStatut' => 'Statut',
			'admin.evaluations.colonneResultat' => 'Résultat',
			'admin.evaluations.typeInitiale' => 'Initiale',
			'admin.evaluations.typePeriodique' => 'Périodique',
			'admin.evaluations.typeReevaluation' => 'Réévaluation',
			'admin.evaluations.typeCertification' => 'Certification',
			'admin.evaluations.statutPlanifiee' => 'Planifiée',
			'admin.evaluations.statutRealisee' => 'Réalisée',
			'admin.evaluations.statutAnnulee' => 'Annulée',
			'admin.evaluations.resultatReussi' => 'Réussi',
			'admin.evaluations.resultatEchec' => 'Échec',
			'admin.evaluations.resultatARevoir' => 'À revoir',
			'admin.evaluations.planifier' => 'Planifier une évaluation',
			'admin.evaluations.planifierTitre' => 'Planifier une évaluation',
			'admin.evaluations.champEleveId' => 'Identifiant de l\'élève',
			'admin.evaluations.champNiveau' => 'Niveau évalué',
			'admin.evaluations.champType' => 'Type',
			'admin.evaluations.champDatePrevue' => 'Date prévue (JJ/MM/AAAA)',
			'admin.evaluations.planifierEnvoyer' => 'Planifier',
			'admin.evaluations.planifierErreur' => ({required Object message}) => 'La planification n\'a pas abouti : ${message}',
			'admin.evaluations.actionEnregistrerResultat' => 'Enregistrer le résultat',
			'admin.evaluations.actionAnnuler' => 'Annuler l\'évaluation',
			'admin.evaluations.resultatTitre' => ({required Object eleve}) => 'Résultat de ${eleve}',
			'admin.evaluations.champNotes' => 'Notes (optionnelles)',
			'admin.evaluations.resultatEnvoyer' => 'Enregistrer',
			'admin.evaluations.resultatErreur' => ({required Object message}) => 'L\'enregistrement n\'a pas abouti : ${message}',
			'admin.evaluations.annulerTitre' => ({required Object eleve}) => 'Annuler l\'évaluation de ${eleve}',
			'admin.evaluations.annulerEnvoyer' => 'Annuler',
			'admin.evaluations.annulerErreur' => ({required Object message}) => 'L\'annulation n\'a pas abouti : ${message}',
			'admin.evaluations.champMotif' => 'Motif',
			'admin.evaluations.motifRequis' => 'Un motif est requis, il s\'inscrit au journal d\'audit.',
			'admin.evaluations.journalisation' => 'Chaque planification, résultat et annulation est inscrit au journal d\'audit.',
			'admin.progression.titre' => 'Progression',
			'admin.progression.intro' => 'Le niveau courant de chaque élève, son groupe, et les blocages ou dérogations en cours.',
			'admin.progression.erreur' => 'La progression n\'a pas pu être lue. Réessayez dans un instant.',
			'admin.progression.aucun' => 'Aucun élève actif',
			'admin.progression.aucunDetail' => 'Les élèves apparaîtront ici dès leur premier diagnostic de placement.',
			'admin.progression.colonneEleve' => 'Élève',
			'admin.progression.colonneGroupe' => 'Groupe',
			'admin.progression.colonneNiveau' => 'Niveau',
			'admin.progression.colonneDepuis' => 'Depuis',
			'admin.progression.colonneException' => 'Exception',
			'admin.progression.sansGroupe' => 'Sans groupe',
			'admin.progression.sansNiveau' => 'Non diagnostiqué',
			'admin.progression.filtreTousCycles' => 'Tous les cycles',
			'admin.progression.depuisAujourdhui' => 'Aujourd\'hui',
			'admin.progression.depuisUnJour' => '1 jour',
			'admin.progression.depuisJours' => ({required Object jours}) => '${jours} jours',
			'admin.progression.typeBlocage' => 'Blocage',
			'admin.progression.typeDerogation' => 'Dérogation',
			'admin.progression.actionPoserBlocage' => 'Poser un blocage',
			'admin.progression.actionPoserDerogation' => 'Poser une dérogation',
			'admin.progression.actionCloreException' => 'Clore l\'exception',
			'admin.progression.actionPromouvoir' => 'Changer de niveau',
			'admin.progression.poserExceptionTitre' => ({required Object type, required Object eleve}) => '${type} pour ${eleve}',
			'admin.progression.poserExceptionEnvoyer' => 'Poser l\'exception',
			'admin.progression.poserExceptionErreur' => ({required Object message}) => 'La pose n\'a pas abouti : ${message}',
			'admin.progression.clorerExceptionTitre' => ({required Object eleve}) => 'Clore l\'exception de ${eleve}',
			'admin.progression.clorerExceptionEnvoyer' => 'Clore',
			'admin.progression.clorerExceptionErreur' => ({required Object message}) => 'La clôture n\'a pas abouti : ${message}',
			'admin.progression.promouvoirTitre' => ({required Object eleve}) => 'Changer le niveau de ${eleve}',
			'admin.progression.promouvoirChampNiveau' => 'Nouveau niveau',
			'admin.progression.promouvoirEnvoyer' => 'Enregistrer',
			'admin.progression.promouvoirErreur' => ({required Object message}) => 'Le changement n\'a pas abouti : ${message}',
			'admin.progression.champMotif' => 'Motif',
			'admin.progression.motifRequis' => 'Un motif est requis, il s\'inscrit au journal d\'audit.',
			'admin.progression.journalisation' => 'Chaque exception posée, close, et chaque changement de niveau est inscrit au journal d\'audit.',
			'admin.programmes.titre' => 'Programmes',
			'admin.programmes.intro' => 'Le curriculum Rewayah, versionné : une version publiée ne peut plus être modifiée, toute évolution académique en crée une nouvelle.',
			'admin.programmes.aucuneVersion' => 'Aucune version de programme',
			'admin.programmes.aucuneVersionDetail' => 'Créez la première version, encore en brouillon, pour commencer à y ajouter des niveaux.',
			'admin.programmes.erreur' => 'Le programme n\'a pas pu être lu. Réessayez dans un instant.',
			'admin.programmes.statutBrouillon' => 'Brouillon',
			'admin.programmes.statutPubliee' => 'Publiée',
			'admin.programmes.statutArchivee' => 'Archivée',
			'admin.programmes.versionNumero' => ({required Object numero}) => 'Version ${numero}',
			'admin.programmes.niveauxSur' => ({required Object nombre}) => '${nombre} niveaux',
			'admin.programmes.creerVersion' => 'Créer une version',
			'admin.programmes.creerVersionVide' => 'Créer une version vide',
			'admin.programmes.creerVersionDepuisPubliee' => 'Créer une nouvelle version à partir de celle-ci',
			'admin.programmes.creerVersionErreur' => ({required Object message}) => 'La création n\'a pas abouti : ${message}',
			'admin.programmes.niveauxTitre' => 'Niveaux',
			'admin.programmes.niveauAucun' => 'Aucun niveau dans cette version',
			'admin.programmes.niveauAucunDetail' => 'Ajoutez un premier niveau pour commencer à composer cette version.',
			'admin.programmes.codeTechnique' => ({required Object code}) => 'Code : ${code}',
			'admin.programmes.ajouterNiveau' => 'Ajouter un niveau',
			'admin.programmes.ajouterNiveauTitre' => ({required Object version}) => 'Ajouter un niveau à ${version}',
			'admin.programmes.ajouterNiveauEnvoyer' => 'Ajouter',
			'admin.programmes.ajouterNiveauErreur' => ({required Object message}) => 'L\'ajout n\'a pas abouti : ${message}',
			'admin.programmes.modifierNiveau' => 'Modifier',
			'admin.programmes.modifierNiveauTitre' => ({required Object nom}) => 'Modifier ${nom}',
			'admin.programmes.modifierNiveauEnvoyer' => 'Enregistrer',
			'admin.programmes.modifierNiveauErreur' => ({required Object message}) => 'La modification n\'a pas abouti : ${message}',
			'admin.programmes.supprimerNiveau' => 'Supprimer',
			'admin.programmes.supprimerNiveauTitre' => ({required Object nom}) => 'Supprimer ${nom}',
			'admin.programmes.supprimerNiveauEnvoyer' => 'Supprimer',
			'admin.programmes.supprimerNiveauErreur' => ({required Object message}) => 'La suppression n\'a pas abouti : ${message}',
			'admin.programmes.publierVersion' => 'Publier la version',
			'admin.programmes.publierVersionTitre' => ({required Object version}) => 'Publier ${version}',
			'admin.programmes.publierVersionDetail' => 'Une fois publiée, cette version ne pourra plus être modifiée. Toute évolution académique en créera une nouvelle.',
			'admin.programmes.publierVersionEnvoyer' => 'Publier',
			'admin.programmes.publierVersionErreur' => ({required Object message}) => 'La publication n\'a pas abouti : ${message}',
			'admin.programmes.champCodeTechnique' => 'Code technique (usage interne, jamais affiché à l\'élève)',
			'admin.programmes.champNomHumain' => 'Nom affiché',
			'admin.programmes.champCycle' => 'Cycle',
			'admin.programmes.champOrdre' => 'Ordre',
			'admin.programmes.champDescription' => 'Description (optionnelle)',
			'admin.programmes.champMotif' => 'Motif',
			'admin.programmes.motifRequis' => 'Un motif est requis, il s\'inscrit au journal d\'audit.',
			'admin.programmes.journalisation' => 'Chaque création, modification, suppression et publication est inscrite au journal d\'audit.',
			'admin.journal.titre' => 'Journal',
			'admin.journal.chaineIntacte' => 'Journal intact',
			'admin.journal.chaineIntacteDetail' => ({required Object nombre}) => '${nombre} entrées relues une à une : aucune n\'a été modifiée ni retirée depuis son écriture.',
			'admin.journal.chaineRompue' => 'Journal altéré',
			'admin.journal.chaineRompueUne' => ({required Object entree}) => 'Une entrée ne correspond plus à son empreinte, la n° ${entree}. Quelque chose a touché la base en dehors de l\'application.',
			'admin.journal.chaineRompueDetail' => ({required Object nombre, required Object entree}) => '${nombre} entrées ne correspondent plus à leur empreinte, à partir de la n° ${entree}. Quelque chose a touché la base en dehors de l\'application.',
			'admin.journal.chaineInconnue' => 'Intégrité inconnue',
			'admin.journal.chaineInconnueDetail' => 'La vérification n\'a pas abouti. Les entrées ci-dessous restent lisibles, mais rien ne garantit pour l\'instant qu\'elles sont complètes.',
			'admin.journal.chaineEnCours' => 'Vérification',
			'admin.journal.chaineEnCoursDetail' => 'Relecture de l\'empreinte de chaque entrée.',
			'admin.journal.periodeSemaine' => '7 derniers jours',
			'admin.journal.periodeMois' => '30 derniers jours',
			'admin.journal.periodeTout' => 'Depuis le début',
			'admin.journal.tousTypes' => 'Tous les événements',
			'admin.journal.tousActeurs' => 'Tout le monde',
			'admin.journal.colonneQuand' => 'Quand',
			'admin.journal.colonneQui' => 'Qui',
			'admin.journal.colonneRole' => 'À quel titre',
			'admin.journal.colonneQuoi' => 'Ce qui a été fait',
			'admin.journal.colonneCible' => 'Sur quoi',
			'admin.journal.colonneDetail' => 'Détail',
			'admin.journal.horodatage' => ({required Object date, required Object heure}) => '${date} à ${heure}',
			'admin.journal.acteurSysteme' => 'Le système',
			'admin.journal.acteurInconnu' => 'Compte supprimé',
			'admin.journal.roleAdmin' => 'Administration',
			'admin.journal.roleEnseignant' => 'Enseignant',
			'admin.journal.roleTuteur' => 'Tuteur',
			'admin.journal.roleEleve' => 'Élève',
			'admin.journal.roleControleur' => 'Contrôleur',
			'admin.journal.roleComptable' => 'Comptable',
			'admin.journal.roleAucun' => 'Hors session',
			'admin.journal.evtKycLu' => 'Dossier d\'identité consulté',
			'admin.journal.evtKycTranche' => 'Dossier d\'identité tranché',
			'admin.journal.evtProfilCree' => 'Profil créé',
			'admin.journal.evtProfilEnfantCree' => 'Profil enfant créé',
			'admin.journal.evtCodeCree' => 'Code d\'appairage créé',
			'admin.journal.evtAppareilAppaire' => 'Appareil appairé',
			'admin.journal.evtAppareilRevoque' => 'Appareil révoqué',
			'admin.journal.evtPedagogie' => 'Réglages pédagogiques modifiés',
			'admin.journal.evtAffectationPrise' => 'Élève pris par un enseignant',
			'admin.journal.evtAffectationAttribuee' => 'Élève attribué par l\'administration',
			'admin.journal.evtDemandeCreee' => 'Demande déposée',
			'admin.journal.evtDemandeTranchee' => 'Demande tranchée',
			'admin.journal.evtReglePosee' => 'Règle posée',
			'admin.journal.evtRegleClose' => 'Règle close',
			'admin.journal.filtreEvenement' => 'Événement',
			'admin.journal.filtreActeur' => 'Acteur',
			'admin.journal.evtAgentJetonEmis' => 'Accès d\'agent IA émis',
			'admin.journal.evtAgentJetonRevoque' => 'Accès d\'agent IA révoqué',
			'admin.journal.evtAgentSessionOuverte' => 'Session d\'agent IA ouverte',
			'admin.journal.evtObservationControleur' => 'Visite de contrôle commencée',
			'admin.journal.evtJetonVideo' => 'Entrée en salle autorisée',
			'admin.journal.vide' => 'Aucun événement enregistré',
			'admin.journal.videDetail' => 'Chaque lecture de dossier, chaque décision et chaque attribution viendra s\'inscrire ici.',
			'admin.journal.videFiltre' => 'Aucun événement ne correspond',
			'admin.journal.videFiltreDetail' => 'Élargissez la période, ou relâchez un filtre.',
			'admin.journal.effacerFiltres' => 'Effacer les filtres',
			'admin.journal.erreur' => 'Le journal n\'a pas pu être lu. Réessayez dans un instant.',
			'admin.journal.erreurSuite' => 'Les entrées plus anciennes n\'ont pas pu être lues.',
			'admin.journal.chargerSuite' => 'Charger les entrées plus anciennes',
			'admin.journal.fin' => 'Vous êtes remonté jusqu\'à la première entrée du journal.',
			'admin.journal.evenements.observationEntree' => 'Visite d\'observation commencée',
			'admin.journal.evenements.observationSortie' => 'Visite d\'observation terminée',
			'admin.journal.evenements.observationPolitiqueGroupeModifiee' => 'Règles d\'observation du groupe modifiées',
			'admin.observations.titre' => 'Observations',
			'admin.comptes.titre' => 'Comptes',
			'admin.comptes.intro' => 'Toutes les personnes inscrites, celles qui attendent une décision en premier. Un compte sans pièce d\'identité déposée reste visible ici : c\'est le seul endroit qui le montre.',
			'admin.comptes.attenteUneAujourdhui' => 'Une personne attend une décision, inscrite aujourd\'hui.',
			'admin.comptes.attenteUneUnJour' => 'Une personne attend une décision depuis 1 jour.',
			'admin.comptes.attenteUne' => ({required Object jours}) => 'Une personne attend une décision depuis ${jours} jours.',
			'admin.comptes.attentePlusieurs' => ({required Object nombre}) => '${nombre} personnes attendent une décision.',
			'admin.comptes.filtreTousEtats' => 'Tous',
			'admin.comptes.filtreTousRoles' => 'Tous les rôles',
			'admin.comptes.filtreRole' => 'Rôle',
			'admin.comptes.aucunAvecCeFiltre' => 'Aucun compte avec ce filtre',
			'admin.comptes.aucunAvecCeFiltreDetail' => 'Retirez un filtre pour élargir la liste.',
			'admin.comptes.erreur' => 'Les comptes n\'ont pas pu être lus. Réessayez dans un instant.',
			'admin.comptes.colonnePersonne' => 'Personne',
			'admin.comptes.colonneIdentifiant' => 'Identifiant',
			'admin.comptes.colonneRole' => 'Rôle',
			'admin.comptes.colonneEtat' => 'État',
			'admin.comptes.colonnePiece' => 'Pièce d\'identité',
			'admin.comptes.colonneAttente' => 'Inscrit depuis',
			'admin.comptes.colonneContrats' => 'Contrats',
			'admin.comptes.etatEnAttente' => 'En attente',
			'admin.comptes.etatActif' => 'Actif',
			'admin.comptes.etatProvisoire' => 'Provisoire',
			'admin.comptes.etatSuspendu' => 'Suspendu',
			'admin.comptes.etatInconnu' => 'État inconnu',
			'admin.comptes.roleAdmin' => 'Administration',
			'admin.comptes.roleComptable' => 'Comptable',
			'admin.comptes.roleControleur' => 'Contrôleur',
			'admin.comptes.roleEnseignant' => 'Enseignant',
			'admin.comptes.roleTuteur' => 'Tuteur',
			'admin.comptes.roleEleve' => 'Élève',
			'admin.comptes.roleInconnu' => 'Rôle inconnu',
			'admin.comptes.pieceAucune' => 'Aucune pièce déposée',
			'admin.comptes.pieceAVerifier' => 'À vérifier',
			'admin.comptes.pieceValidee' => 'Validée',
			'admin.comptes.pieceRefusee' => 'Refusée',
			'admin.comptes.pieceNonVisible' => 'Hors de votre portée',
			'admin.comptes.attendAujourdhui' => 'Aujourd\'hui',
			'admin.comptes.attendUnJour' => '1 jour',
			'admin.comptes.attendJours' => ({required Object jours}) => '${jours} jours',
			'admin.agents.titre' => 'Accès des agents IA',
			'admin.agents.intro' => 'Un jeton laisse un agent IA ouvrir l\'application et lire ce qu\'une personne y lit. Il ne peut rien écrire, rien annuler, rien modifier : la base le lui refuse, pas l\'interface.',
			'admin.agents.emettre' => 'Émettre un jeton',
			'admin.agents.libelle' => 'À quoi sert ce jeton',
			'admin.agents.libelleAide' => 'Obligatoire. Un jeton sans nom est un jeton que personne n\'ose révoquer.',
			'admin.agents.libelleExemple' => 'Relecture du suivi de Maryam',
			'admin.agents.qui' => 'Qui l\'agent observe',
			'admin.agents.quiAide' => 'L\'agent verra exactement l\'écran de cette personne, et son parcours sera le sien.',
			'admin.agents.quiVide' => 'Choisir une personne',
			'admin.agents.chercher' => 'Chercher un nom ou un identifiant',
			'admin.agents.duree' => 'Pendant combien de temps',
			'admin.agents.dureeHeure' => ({required Object nombre}) => '${nombre} h',
			'admin.agents.dureePlafond' => 'Vingt-quatre heures au maximum, et la base le vérifie elle-même.',
			'admin.agents.identite' => 'Les prénoms',
			'admin.agents.identiteMasquee' => 'Masqués',
			'admin.agents.identiteMasqueeDetail' => 'L\'agent lit les identifiants (ELV-0042) à la place des prénoms. La substitution est faite par la base : le prénom ne sort pas.',
			'admin.agents.identiteVisible' => 'Visibles',
			'admin.agents.identiteVisibleDetail' => 'L\'agent lit les prénoms, comme la personne observée les voit.',
			'admin.agents.pourra' => 'Pourra',
			'admin.agents.pourraDetail' => 'Ouvrir l\'application, naviguer, et lire tout ce que cette personne lit.',
			'admin.agents.nePourraPas' => 'Ne pourra pas',
			'admin.agents.nePourraPasDetail' => 'Écrire quoi que ce soit, voir une pièce d\'identité, un appareil, le journal d\'audit, ni sortir du périmètre de cette personne.',
			'admin.agents.emissionEnCours' => 'Émission',
			'admin.agents.emis' => 'Jeton émis',
			'admin.agents.emisDetail' => 'Remettez ce lien à l\'agent. Il n\'apparaîtra plus : ni cet écran ni la base ne peuvent le retrouver.',
			'admin.agents.copier' => 'Copier le lien',
			'admin.agents.copie' => 'Lien copié',
			'admin.agents.termine' => 'J\'ai copié le lien',
			'admin.agents.erreurEmission' => 'Le jeton n\'a pas pu être émis. Réessayez dans un instant.',
			'admin.agents.colonneLibelle' => 'Jeton',
			'admin.agents.colonneQui' => 'Observe',
			'admin.agents.colonneParcours' => 'Parcours',
			'admin.agents.colonneIdentite' => 'Prénoms',
			'admin.agents.colonneExpire' => 'Jusqu\'à',
			'admin.agents.colonneUsage' => 'Ouvertures',
			'admin.agents.colonneEtat' => 'État',
			'admin.agents.parcoursEleve' => 'Élève',
			'admin.agents.parcoursTuteur' => 'Tuteur',
			'admin.agents.parcoursEnseignant' => 'Enseignant',
			'admin.agents.parcoursControleur' => 'Contrôle qualité',
			'admin.agents.parcoursAdmin' => 'Administration',
			'admin.agents.parcoursComptable' => 'Comptable',
			'admin.agents.parcoursInconnu' => 'Parcours inconnu',
			'admin.agents.etatActif' => 'Actif',
			'admin.agents.etatRevoque' => 'Révoqué',
			'admin.agents.etatExpire' => 'Expiré',
			'admin.agents.jamaisServi' => 'Jamais utilisé',
			'admin.agents.usage' => ({required Object nombre, required Object quand}) => '${nombre} fois, la dernière ${quand}',
			'admin.agents.revoquer' => 'Révoquer',
			'admin.agents.revoquerTitre' => 'Révoquer ce jeton ?',
			'admin.agents.revoquerDetail' => 'L\'agent perdra l\'accès à sa requête suivante. C\'est définitif : un jeton révoqué ne se réactive pas.',
			'admin.agents.revoquerConfirmer' => 'Révoquer',
			'admin.agents.annuler' => 'Annuler',
			'admin.agents.revoque' => 'Jeton révoqué',
			'admin.agents.erreurRevocation' => 'La révocation n\'a pas abouti. Réessayez.',
			'admin.agents.vide' => 'Aucun jeton d\'observation',
			'admin.agents.videDetail' => 'Aucun agent IA n\'a accès à l\'application pour l\'instant.',
			'admin.agents.erreur' => 'La liste des jetons n\'a pas pu être lue.',
			'admin.notifications.titre' => 'Notifications',
			'admin.notifications.vide' => 'Aucune notification',
			'admin.notifications.videDetail' => 'Rien à signaler pour l\'instant.',
			'agent.titre' => 'Entrée d\'un agent',
			'agent.intro' => 'Cette page ouvre l\'application en lecture seule, avec le jeton remis par l\'académie.',
			'agent.jeton' => 'Jeton d\'observation',
			'agent.jetonExemple' => 'rag_...',
			'agent.entrer' => 'Ouvrir l\'application',
			'agent.ouverture' => 'Ouverture',
			'agent.refus' => 'Jeton refusé',
			'agent.refusDetail' => 'Ce jeton est inconnu, révoqué ou expiré. Demandez-en un nouveau à l\'académie.',
			'agent.indisponible' => 'Service indisponible',
			'agent.indisponibleDetail' => 'L\'ouverture de session n\'a pas répondu. Réessayez dans un instant.',
			'agent.reessayer' => 'Réessayer',
			'agent.bandeau' => 'Observation, lecture seule',
			'agent.bandeauMasque' => 'Prénoms masqués',
			'agent.bandeauExpire' => ({required Object heure}) => 'jusqu\'à ${heure}',
			'vide.aucunCours' => 'Aucun cours aujourd\'hui',
			'vide.aucunCoursDetail' => 'Votre prochain cours apparaîtra ici.',
			'vide.aucunCreneau' => 'Aucun créneau disponible pour le moment',
			'vide.aucunRapport' => 'Aucun cahier de transmission pour l\'instant',
			'vide.aucunAppareil' => 'Aucun appareil appairé',
			'pin.titre' => 'Entre ton code',
			'pin.erreur' => 'Ce code ne correspond pas',
			'pin.effacer' => 'Effacer',
			'choix.autre' => 'Autre',
			'choix.autreInvite' => 'Précisez',
			'choix.selectionMultiple' => 'Plusieurs réponses possibles',
			'parcours.titre' => ({required Object prenom}) => 'Le parcours de ${prenom}',
			'parcours.intro' => 'Quelques questions pour personnaliser votre parcours. Vous ne verrez ensuite que les horaires et options adaptés à votre situation.',
			'parcours.reprendre' => 'Reprendre',
			'parcours.commencer' => 'Personnaliser le parcours',
			'parcours.modifier' => 'Modifier mes réponses',
			'parcours.erreur' => 'Cette réponse n\'a pas pu être enregistrée. Réessayez.',
			'parcours.chargement' => 'Nous préparons vos options.',
			'parcours.ageQuestion' => ({required Object prenom}) => 'Quel âge a ${prenom} ?',
			'parcours.ageRaison' => 'L\'âge décide de la durée des séances et du nombre d\'élèves par groupe. Nous ne demandons pas de date de naissance : une tranche suffit.',
			'parcours.langueQuestion' => 'Dans quelle langue le cours doit-il être donné ?',
			'parcours.langueRaison' => 'C\'est la langue que l\'enseignant parlera pendant la séance. Elle est indépendante de la langue de l\'application, que vous pouvez changer à tout moment dans vos réglages.',
			'parcours.lieuQuestion' => 'Où vous trouvez-vous ?',
			'parcours.lieuRaison' => 'Nous nous en servons uniquement pour vous montrer les horaires à votre heure locale. Nous ne demandons jamais votre position exacte, et cette réponse ne quitte pas votre dossier.',
			'parcours.lieuSuggere' => 'Proposé d\'après l\'heure de votre appareil',
			'parcours.niveauQuestion' => ({required Object prenom}) => 'Où en est ${prenom} aujourd\'hui ?',
			'parcours.niveauRaison' => 'Votre réponse oriente les premières propositions. Elle ne fixe pas le niveau officiel : celui-ci est attribué par l\'académie après un échange avec un enseignant.',
			'parcours.niveauDebutLettres' => 'Nous commençons par les lettres',
			'parcours.niveauLettresAvecAide' => 'Les lettres sont reconnues, la lecture demande de l\'aide',
			'parcours.niveauLectureLente' => 'La lecture est possible, lentement',
			'parcours.niveauLectureCourante' => 'Le Coran se lit déjà couramment',
			'parcours.niveauMemorisationPartielle' => 'Une partie est déjà mémorisée',
			'parcours.objectifQuestion' => 'Que souhaitez-vous d\'abord ?',
			'parcours.objectifRaison' => 'Vous pourrez changer d\'objectif plus tard : il oriente le travail de l\'enseignant, il ne vous engage pas.',
			'parcours.objectifApprendreALire' => 'Apprendre à lire',
			'parcours.objectifDevenirFluide' => 'Lire plus couramment',
			'parcours.objectifMemoriser' => 'Mémoriser',
			'parcours.objectifIndecis' => 'Je ne sais pas encore',
			'parcours.momentsQuestion' => 'Quels moments de la journée vous conviennent le mieux ?',
			'parcours.momentsRaison' => 'Cette réponse ne crée aucun horaire et ne réserve rien. Elle sert seulement à mettre en avant, parmi les horaires que l\'académie propose déjà, ceux qui tombent le mieux pour vous. Vous verrez tous les autres juste en dessous.',
			'parcours.momentMatin' => 'Le matin',
			'parcours.momentApresMidi' => 'L\'après-midi',
			'parcours.momentSoir' => 'Le soir',
			'parcours.offresQuestion' => ({required Object prenom}) => 'Voici les horaires ouverts pour ${prenom}',
			'parcours.offresRaison' => 'Ces horaires sont affichés à votre heure locale. Choisir un horaire enregistre votre préférence : cela ne réserve pas de place et ne constitue pas encore un groupe.',
			'parcours.offreRecommandee' => 'Le plus proche de vos réponses',
			'parcours.offresAutres' => 'Autres horaires possibles',
			'parcours.offreRecurrence' => ({required Object seances, required Object duree}) => '${seances} séances par semaine, ${duree} min',
			'parcours.offreRecurrencePause' => ({required Object seances, required Object duree, required Object pause}) => '${seances} séances par semaine, ${duree} min dont ${pause} min de pause',
			'parcours.offreLangue' => ({required Object langue}) => 'Cours en ${langue}',
			'parcours.offreFuseau' => ({required Object fuseau}) => 'Heure affichée pour ${fuseau}',
			'parcours.offreTraduite' => 'Affiché à votre heure locale',
			'parcours.offreJours' => ({required Object jours}) => '${jours}',
			'parcours.offreChoisir' => 'Choisir cet horaire',
			'parcours.offreChoisie' => 'Horaire retenu',
			'parcours.aucuneOffre' => 'Aucun horaire ouvert ne correspond encore',
			'parcours.aucuneOffreDetail' => 'L\'académie ouvre de nouveaux horaires au fil des inscriptions. Vous pouvez nous signaler votre besoin : cela nous aide à décider lesquels ouvrir.',
			'parcours.refusAucun' => 'Aucun de ces horaires ne me convient',
			'parcours.refusPrevenir' => 'Me prévenir si de nouveaux horaires ouvrent',
			'parcours.refusEffet' => 'Nous enregistrons que la demande existe. Cela ne crée pas de groupe, ne cherche pas d\'enseignant et ne promet aucun horaire futur.',
			'parcours.refusEnregistre' => 'C\'est noté. Nous vous préviendrons si un horaire correspondant ouvre.',
			'parcours.etatAPersonnaliser' => 'Parcours à personnaliser',
			'parcours.etatAPersonnaliserDetail' => ({required Object prenom}) => 'Quelques questions, et nous ne vous montrerons que ce qui convient à ${prenom}.',
			'parcours.etatHoraireAChoisir' => 'Horaire à choisir',
			'parcours.etatHoraireAChoisirDetail' => ({required Object prenom}) => 'Les horaires ouverts pour ${prenom} vous attendent.',
			'parcours.etatOffreIndisponible' => 'Cet horaire n\'est plus proposé',
			'parcours.etatOffreIndisponibleDetail' => ({required Object prenom}) => 'L\'horaire retenu pour ${prenom} a été retiré avant qu\'un groupe soit constitué. Choisissez-en un autre : rien n\'est perdu.',
			'parcours.etatDiagnosticRequis' => 'Préférence enregistrée',
			'parcours.etatDiagnosticRequisDetail' => ({required Object prenom}) => 'Il reste un échange avec un enseignant pour situer le niveau de ${prenom}. L\'académie vous proposera un rendez-vous.',
			'parcours.etatDiagnosticEnAttente' => 'Rendez-vous prévu',
			'parcours.etatDiagnosticEnAttenteDetail' => ({required Object prenom}) => 'Un échange est prévu pour situer le niveau de ${prenom}.',
			'parcours.etatGroupeEnFormation' => 'Groupe en cours de constitution',
			'parcours.etatGroupeEnFormationDetail' => ({required Object minimum}) => 'Un groupe démarre à partir de ${minimum} élèves. Nous vous préviendrons dès qu\'il est confirmé.',
			'parcours.etatGroupeConfirme' => 'Groupe confirmé',
			'parcours.etatGroupeConfirmeDetail' => ({required Object prenom}) => 'Le groupe de ${prenom} est constitué. Vous retrouverez ses séances dans son espace.',
			'parcours.fuseauChange' => 'Votre lieu a changé depuis ce choix',
			'parcours.fuseauChangeDetail' => 'L\'horaire est le même pour l\'académie, mais il ne tombe plus à la même heure chez vous. Vérifiez qu\'il vous convient toujours.',
			'parcours.voirHoraires' => 'Voir les horaires',
			'parcours.changerHoraire' => 'Changer d\'horaire',
			'parcours.renoncerMotif' => 'La famille a changé d\'horaire depuis le parcours',
			_ => null,
		} ?? switch (path) {
			'avatar.sansPhoto' => 'Pas encore de photo',
			'nav.eleve.accueil' => 'Accueil',
			'nav.eleve.coran' => 'Coran',
			'nav.eleve.suivi' => 'Suivi',
			'nav.eleve.compte' => 'Compte',
			'nav.tuteur.accueil' => 'Accueil',
			'nav.tuteur.foyer' => 'Foyer',
			'nav.tuteur.disponibilites' => 'Disponibilités',
			'nav.tuteur.reglages' => 'Réglages',
			'nav.tuteur.suivi' => 'Suivi',
			'nav.tuteur.historique' => 'Historique',
			'nav.tuteur.compte' => 'Compte',
			'nav.enseignant.journee' => 'Journée',
			'nav.enseignant.creneaux' => 'Créneaux',
			'nav.enseignant.profil' => 'Profil',
			'nav.controleur.planning' => 'Planning',
			'nav.admin.tableauDeBord' => 'Tableau de bord',
			'nav.admin.dossiers' => 'Dossiers',
			'nav.admin.demandes' => 'Demandes',
			'nav.admin.attribution' => 'Attribution',
			'nav.admin.journal' => 'Journal',
			'nav.admin.comptes' => 'Comptes',
			'nav.admin.accesAgents' => 'Accès des agents',
			'nav.admin.accueil' => 'Accueil',
			'nav.admin.operations' => 'Opérations',
			'nav.admin.personnes' => 'Personnes',
			'nav.admin.pedagogie' => 'Pédagogie',
			'nav.admin.finance' => 'Finance',
			'nav.admin.configuration' => 'Configuration',
			'nav.admin.securite' => 'Sécurité et audit',
			'nav.admin.direction' => 'Direction',
			'nav.admin.recherche' => 'Recherche',
			'nav.admin.rechercheIndication' => 'Rechercher un écran',
			'nav.admin.notificationsTitre' => 'Notifications',
			'nav.admin.menu' => 'Menu',
			'nav.compte' => 'Mon compte',
			'nav.principale' => 'Navigation principale',
			'nav.motSymbole' => 'Rewayah',
			'nav.replier' => 'Replier la navigation',
			'nav.deplier' => 'Déplier la navigation',
			'compte.titre' => 'Mon compte',
			'compte.intro' => 'Vos informations, vos préférences et vos accès, au même endroit.',
			'compte.informations' => 'Informations',
			'compte.profil' => 'Profil',
			'compte.profilDetail' => 'Voir et gérer vos informations',
			'compte.reglages' => 'Réglages',
			'compte.reglagesDetail' => 'Apparence, notifications et accessibilité',
			'compte.profils' => 'Profils du foyer',
			'compte.profilsDetail' => 'Gérer les profils de vos enfants',
			'compte.appareils' => 'Foyer',
			'compte.appareilsDetail' => 'Les appareils et profils rattachés à votre foyer',
			'compte.confidentialite' => 'Confidentialité',
			'compte.confidentialiteDetail' => 'Bientôt disponible',
			'compte.espaces' => 'Espaces',
			'compte.espacesDetail' => 'Les espaces auxquels votre compte donne accès',
			'compte.habilitation' => 'Habilité',
			'compte.deconnexion' => 'Se déconnecter',
			'compte.deconnexionDetail' => 'Mettre fin à la session sur cet appareil',
			'compte.identifiant' => 'Identifiant',
			'compte.nonDisponible' => 'Non disponible',
			'compte.contact' => 'Contact',
			'compte.contactDetail' => 'Géré par l\'académie',
			'compte.langue' => 'Langue',
			'compte.francais' => 'Français',
			'compte.fuseau' => 'Fuseau horaire',
			'compte.academie' => 'Académie',
			'compte.securite' => 'Sécurité',
			'compte.statut' => 'Statut',
			'compte.reglagesTitre' => 'Réglages',
			'compte.reglagesIntro' => 'Ces préférences restent sur cet appareil et s\'appliquent tout de suite.',
			'compte.apparence' => 'Apparence',
			'compte.themeSysteme' => 'Système',
			'compte.themeSystemeDetail' => 'Suit le réglage de votre appareil',
			'compte.themeClair' => 'Clair',
			'compte.themeSombre' => 'Sombre',
			'compte.accessibilite' => 'Accessibilité',
			'compte.animations' => 'Réduire les animations',
			'compte.animationsDetail' => 'Limite les mouvements à l\'écran',
			'compte.effets' => 'Réduire les effets',
			'compte.effetsDetail' => 'Limite les transparences et les ombres',
			'compte.lisibiliteDetail' => 'La taille du texte suit le réglage de votre appareil.',
			'compte.langueRegion' => 'Langue et région',
			'compte.francaisDetail' => 'Langue de l\'interface',
			'compte.actif' => 'Actif',
			'compte.arabe' => 'Arabe',
			'compte.arabeDetail' => 'Bientôt disponible',
			'compte.fuseauDetail' => 'Détecté automatiquement',
			'compte.notifications' => 'Notifications',
			'compte.notificationsCours' => 'Cours',
			'compte.notificationsCoursDetail' => 'Rappels avant vos cours',
			'compte.notificationsFoyer' => 'Foyer',
			'compte.notificationsFoyerDetail' => 'Activité des profils de votre foyer',
			'compte.notificationsEtat' => 'Les notifications dépendent aussi des réglages de votre appareil et de votre navigateur.',
			'compte.coursDonnees' => 'Cours et données',
			'compte.economieDonnees' => 'Économie de données',
			'compte.economieDonneesDetail' => 'Réduit la qualité vidéo sur réseau mobile',
			'compte.lectureGrande' => 'Lecture en grand texte',
			'compte.lectureGrandeDetail' => 'Affiche le Coran en plus grand par défaut',
			'compte.profilsTitre' => 'Profils du foyer',
			'compte.profilsIntro' => 'Les enfants rattachés à votre foyer.',
			'compte.erreurProfils' => 'Les profils n\'ont pas pu être lus.',
			'compte.reessayer' => 'Réessayer',
			'compte.aucunProfil' => 'Aucun profil pour l\'instant',
			'compte.aucunProfilDetail' => 'Ajoutez un enfant pour commencer',
			'compte.ajouterEnfant' => 'Ajouter un enfant',
			'compte.ouvrirProfil' => 'Ouvrir le profil',
			'compte.modeEnfant' => 'Mode enfant',
			'compte.modeStandard' => 'Mode standard',
			'compte.cameraLabel' => 'Caméra',
			'compte.cameraAutorisee' => 'Autorisée',
			'compte.cameraInterdite' => 'Interdite',
			'compte.accesSansFin' => 'Accès sans date de fin',
			'compte.accesJusqua' => ({required Object date}) => 'Accès jusqu\'au ${date}',
			'compte.statutActif' => 'Actif',
			'compte.statutProvisoire' => 'Actif, à titre provisoire',
			'compte.profilEnfant' => ({required Object prenom}) => 'Profil de ${prenom}',
			'compte.identifiantEnfant' => ({required Object identifiant}) => 'Identifiant : ${identifiant}',
			'compte.roles.admin' => 'Administrateur',
			'compte.roles.accountant' => 'Comptable',
			'compte.roles.controller' => 'Contrôleur',
			'compte.roles.teacher' => 'Enseignant',
			'compte.roles.guardian' => 'Tuteur',
			'compte.roles.student' => 'Élève',
			'compte.roleDetail.admin' => 'Gère les dossiers, l\'attribution et le journal de l\'académie',
			'compte.roleDetail.accountant' => 'Gère les paiements et les factures',
			'compte.roleDetail.controller' => 'Observe les séances pour la qualité pédagogique',
			'compte.roleDetail.teacher' => 'Donne les cours et suit ses créneaux',
			'compte.roleDetail.guardian' => 'Suit le foyer et ses enfants',
			'compte.roleDetail.student' => 'Suit ses cours et son Coran',
			'historique.titre' => 'Historique',
			'historique.detailSeance' => 'Détail de la séance',
			'historique.segments.seances' => 'Séances',
			'historique.segments.observations' => 'Observations',
			'notifications.titre' => 'Notifications',
			'eleve.accueil.rejoindre' => 'Rejoindre',
			'eleve.accueil.coran' => 'Le Coran',
			'eleve.accueil.coranDetail' => 'À lire quand tu veux',
			'eleve.accueil.prochainCours' => 'Prochain cours',
			'eleve.accueil.coursEnDirect' => 'Ton cours a commencé',
			'eleve.accueil.avec' => ({required Object prenom}) => 'Avec ${prenom}',
			'eleve.accueil.dansMinutes' => ({required Object minutes}) => 'Dans ${minutes} min',
			'eleve.accueil.dansHeures' => ({required Object heures, required Object minutes}) => 'Dans ${heures} h ${minutes}',
			'eleve.accueil.imminent' => 'C\'est presque l\'heure',
			'eleve.accueil.aucunCours' => 'Pas de cours aujourd\'hui',
			'eleve.accueil.aucunCoursDetail' => 'Ton enseignant prépare le prochain.',
			'eleve.accueil.prochainAujourdhui' => 'Ton prochain cours est plus tard aujourd\'hui.',
			'eleve.accueil.prochainDemain' => 'Ton prochain cours est demain.',
			'eleve.accueil.prochainDansJours' => ({required Object jours}) => 'Ton prochain cours est dans ${jours} jours.',
			'eleve.accueil.annulee' => 'Ce cours n\'aura pas lieu',
			'eleve.accueil.horsLigne' => 'Pas de réseau',
			'eleve.accueil.horsLigneDetail' => 'Tu pourras entrer dès que le réseau revient.',
			'eleve.accueil.pausePriere' => 'Pause pour la prière',
			'eleve.accueil.pausePriereDetail' => ({required Object priere, required Object heure}) => '${priere}, vers ${heure}',
			'eleve.coran.titre' => 'Le Coran',
			'eleve.coran.page' => ({required Object page, required Object total}) => 'Page ${page} sur ${total}',
			'eleve.coran.juz' => ({required Object juz}) => 'Juz ${juz}',
			'eleve.coran.mecquoise' => 'Révélée à La Mecque',
			'eleve.coran.medinoise' => 'Révélée à Médine',
			'eleve.coran.reprendre' => 'Reprendre ta lecture',
			'eleve.coran.reprendreDetail' => ({required Object page}) => 'Tu en étais page ${page}',
			'eleve.coran.chargement' => 'Le texte arrive',
			'eleve.coran.indisponible' => 'Le texte n\'a pas pu être chargé',
			'eleve.coran.indisponibleDetail' => 'Dès que le réseau revient, ta page se rouvre ici.',
			'eleve.coran.reessayer' => 'Réessayer',
			'eleve.coran.absent' => 'Cette page est vide',
			'eleve.coran.absentDetail' => 'Le texte n\'a pas été installé sur cette page. Signale-le : ce n\'est pas toi.',
			'eleve.coran.pagePrecedente' => 'Page précédente',
			'eleve.coran.pageSuivante' => 'Page suivante',
			'eleve.coran.reglages' => 'Réglages de lecture',
			'eleve.coran.fermerReglages' => 'Fermer les réglages',
			'eleve.coran.taille' => 'Taille du texte',
			'eleve.coran.agrandir' => 'Agrandir le texte',
			'eleve.coran.reduire' => 'Réduire le texte',
			'eleve.coran.source' => 'Texte du Coran : Tanzil Project',
			'eleve.coran.sourceLien' => 'tanzil.net',
			'eleve.coran.edition' => 'Mushaf de Médine, riwaya Hafs',
			'eleve.suivi.titre' => 'Suivi de mes cours',
			'eleve.suivi.colonneDate' => 'Date',
			'eleve.suivi.colonneCours' => 'Cours',
			'eleve.suivi.colonneEnseignant' => 'Enseignant',
			'eleve.suivi.colonneEtat' => 'Présence',
			'eleve.suivi.cours' => 'Cours de Coran',
			'eleve.suivi.moi' => 'Ma présence',
			'eleve.suivi.aujourdhui' => ({required Object heure}) => 'Aujourd\'hui, ${heure}',
			'eleve.suivi.hier' => ({required Object heure}) => 'Hier, ${heure}',
			'eleve.suivi.date' => ({required Object date, required Object heure}) => '${date}, ${heure}',
			'eleve.suivi.annule' => 'Cours annulé',
			'eleve.suivi.nonTenu' => 'Cours non tenu',
			'eleve.suivi.vide' => 'Aucun cours pour l\'instant',
			'eleve.suivi.videDetail' => 'Vos cours s\'afficheront ici, du plus récent au plus ancien, avec votre présence.',
			'eleve.suivi.erreur' => 'Le suivi n\'a pas pu être lu. Réessayez dans un instant.',
			'eleve.suivi.tronquee' => ({required Object nombre}) => 'Les ${nombre} cours les plus récents sont affichés.',
			'eleve.suivi.fin' => ({required Object nombre}) => '${nombre} cours au suivi.',
			'eleve.suivi.finUn' => '1 cours au suivi.',
			'tuteur.accueil.titre' => 'Accueil',
			'tuteur.accueil.voirLaClasse' => 'Voir la classe',
			'tuteur.accueil.prochaineSeance' => 'Prochaine séance',
			'tuteur.accueil.heureDe' => ({required Object ville}) => 'Heure de ${ville}',
			'tuteur.accueil.heureAppareil' => 'Heure de cet appareil',
			'tuteur.accueil.dateEtFuseau' => ({required Object date, required Object fuseau}) => '${date} · ${fuseau}',
			'tuteur.accueil.heureClasse' => ({required Object heure, required Object ville}) => 'Heure de la classe : ${heure} ${ville}',
			'tuteur.accueil.seanceEnDirect' => 'Séance en direct',
			'tuteur.accueil.seanceTerminee' => 'Séance terminée',
			'tuteur.accueil.seanceAnnulee' => 'Cette séance n\'aura pas lieu.',
			'tuteur.accueil.seanceNonTenue' => 'Cette séance n\'a pas pu se tenir.',
			'tuteur.accueil.horaireIncertain' => 'Ouverture de la salle non confirmée pour l\'instant',
			'tuteur.accueil.pastilleAnnulee' => 'Annulée',
			'tuteur.accueil.pastilleNonTenue' => 'Non tenue',
			'tuteur.accueil.pastilleTerminee' => 'Terminée',
			'tuteur.accueil.aucuneSeance' => 'Aucune séance planifiée',
			'tuteur.accueil.aucuneSeanceDetail' => ({required Object prenom}) => 'La prochaine séance de ${prenom} apparaîtra ici dès qu\'elle sera programmée.',
			'tuteur.accueil.seanceIllisible' => 'La prochaine séance n\'a pas pu être lue.',
			'tuteur.accueil.classeIndisponible' => 'Le détail de la classe n\'est pas encore disponible ici.',
			'tuteur.accueil.classeIllisible' => 'La classe n\'a pas pu être lue.',
			'tuteur.accueil.sansClasseTitre' => ({required Object prenom}) => 'Aucune classe pour ${prenom}',
			'tuteur.accueil.sansClassePhrase' => ({required Object prenom}) => 'Choisissez une classe pour que ${prenom} puisse commencer les cours.',
			'tuteur.accueil.foyerVideTitre' => 'Aucun profil élève pour l\'instant',
			'tuteur.accueil.foyerVidePhrase' => 'Ajoutez un profil élève pour choisir une classe et suivre ses séances.',
			'tuteur.accueil.ajouterProfil' => 'Ajouter un profil élève',
			'tuteur.accueil.profilsIllisibles' => 'Les profils du foyer n\'ont pas pu être lus.',
			'tuteur.accueil.blocageAppareilTitre' => ({required Object prenom}) => 'Aucun appareil prêt pour ${prenom}',
			'tuteur.accueil.blocageAppareilPhrase' => ({required Object prenom}) => 'Sans appareil connecté, ${prenom} ne pourra pas entrer en classe.',
			'tuteur.accueil.connecterAppareil' => 'Connecter un appareil',
			'tuteur.accueil.avantProchainCours' => 'Avant le prochain cours',
			'tuteur.accueil.voirTout' => 'Voir tout',
			'tuteur.accueil.travailIndisponible' => 'Le travail à préparer n\'est pas encore relié à cet espace.',
			'tuteur.accueil.travailIllisible' => 'Le travail à préparer n\'a pas pu être lu.',
			'tuteur.accueil.rienAPreparer' => 'Rien à préparer pour l\'instant',
			'tuteur.accueil.derniereSeance' => 'Dernière séance',
			'tuteur.accueil.voirHistorique' => 'Voir l\'historique',
			'tuteur.accueil.detailsSeance' => 'Détails de la séance',
			'tuteur.accueil.aucuneDerniere' => 'Aucune séance passée pour l\'instant',
			'tuteur.accueil.derniereIllisible' => 'La dernière séance n\'a pas pu être lue.',
			'tuteur.accueil.dateEtDuree' => ({required Object date, required Object duree}) => '${date} · ${duree}',
			'tuteur.accueil.etatCourt.enDirect' => 'En direct',
			'tuteur.accueil.etatCourt.salleOuverte' => 'Salle ouverte',
			'tuteur.accueil.etatCourt.dansMinutes' => ({required Object minutes}) => 'Dans ${minutes} min',
			'tuteur.accueil.etatCourt.dansHeures' => ({required Object heures, required Object minutes}) => 'Dans ${heures} h ${minutes}',
			'tuteur.accueil.etatCourt.dansJours' => ({required Object jours}) => 'Dans ${jours} j',
			'tuteur.accueil.etatCourt.prevue' => 'Séance prévue',
			'tuteur.accueil.etatCourt.annulee' => 'Séance annulée',
			'tuteur.accueil.etatCourt.nonTenue' => 'Séance non tenue',
			'tuteur.accueil.etatCourt.terminee' => 'Séance terminée',
			'tuteur.accueil.etatCourt.aucune' => 'Aucune séance',
			'tuteur.accueil.etatCourt.illisible' => 'Non disponible',
			'tuteur.accueil.assister' => 'Assister',
			'tuteur.accueil.assisterRefuse' => 'Le cours n\'a pas pu être rejoint. Il vient peut-être de se terminer.',
			'tuteur.accueil.enCours' => ({required Object prenom}) => 'En cours avec ${prenom}',
			'tuteur.accueil.depuisMinutes' => ({required Object minutes}) => 'Commencé il y a ${minutes} min',
			'tuteur.accueil.depuisInstant' => 'Vient de commencer',
			'tuteur.accueil.aujourdhui' => ({required Object heure, required Object prenom}) => 'Aujourd\'hui à ${heure}, avec ${prenom}',
			'tuteur.accueil.unAutreJour' => ({required Object jour, required Object heure, required Object prenom}) => '${jour} à ${heure}, avec ${prenom}',
			'tuteur.accueil.rienAujourdhui' => 'Rien aujourd\'hui',
			'tuteur.accueil.aucunCoursPrevu' => 'Aucun cours programmé pour l\'instant',
			'tuteur.accueil.aucunCoursPrevuDetail' => 'Les cours de la semaine sont préparés à l\'avance. Celui-ci apparaîtra ici.',
			'tuteur.accueil.enRecherche' => 'En recherche d\'un enseignant',
			'tuteur.accueil.enRechercheDepuis' => ({required Object date}) => 'Demande déposée le ${date}',
			'tuteur.accueil.enRechercheSansDate' => ({required Object prenom}) => 'Un enseignant prendra ${prenom} en charge parmi les heures proposées.',
			'tuteur.accueil.sansCreneau' => ({required Object prenom}) => 'Aucune heure proposée pour ${prenom}',
			'tuteur.accueil.sansCreneauDetail' => ({required Object prenom}) => 'Sans créneau, aucun enseignant ne peut prendre ${prenom} en charge.',
			'tuteur.accueil.poserDesHeures' => 'Proposer des heures',
			'tuteur.accueil.annulee' => ({required Object heure}) => 'Le cours de ${heure} n\'aura pas lieu',
			'tuteur.accueil.motifAnnulee' => 'Séance annulée',
			'tuteur.accueil.motifAnnuleeTard' => 'Séance annulée peu avant l\'heure',
			'tuteur.accueil.proposeApres' => ({required Object jour, required Object heure}) => 'Prochain cours ${jour} à ${heure}',
			'tuteur.accueil.proposeAucun' => 'Un nouveau cours vous sera proposé.',
			'tuteur.accueil.gererLeFoyer' => 'Gérer le foyer',
			'tuteur.accueil.blocAppareils' => 'Appareils du foyer',
			'tuteur.accueil.blocAppareilsDetail' => 'Ajouter un appareil, ou en retirer un.',
			'tuteur.accueil.blocReglages' => 'Réglages par enfant',
			'tuteur.accueil.blocReglagesDetail' => 'Photo, caméra et affichage, enfant par enfant.',
			'tuteur.accueil.blocGroupesDetail' => 'Le groupe, l\'enseignant et le prochain cours de chaque enfant.',
			'tuteur.accueil.acces' => 'Accès',
			'tuteur.accueil.accesJusqua' => ({required Object prenom, required Object date}) => 'Accès de ${prenom} jusqu\'au ${date}',
			'tuteur.accueil.accesSansFin' => ({required Object prenom}) => 'Accès de ${prenom} sans date de fin',
			'tuteur.accueil.aucunEnfant' => 'Aucun enfant dans le foyer',
			'tuteur.accueil.aucunEnfantDetail' => 'Ajoutez votre premier enfant pour commencer.',
			'tuteur.accueil.erreur' => 'Le foyer n\'a pas pu être lu en entier. Réessayez dans un instant.',
			'tuteur.reglages.titre' => 'Réglages par enfant',
			'tuteur.reglages.intro' => 'Ces réglages s\'appliquent à la séance suivante, jamais pendant un cours.',
			'tuteur.reglages.photo' => 'Photo',
			'tuteur.reglages.photoAucune' => ({required Object prenom}) => '${prenom} n\'a pas encore de photo. Elle reste visible du seul foyer.',
			'tuteur.reglages.photoPresente' => ({required Object prenom}) => 'La photo de ${prenom} reste visible du seul foyer, jamais de son enseignant ni des autres élèves.',
			'tuteur.reglages.photoAjouter' => 'Ajouter une photo',
			'tuteur.reglages.photoChanger' => 'Changer la photo',
			'tuteur.reglages.photoTropLourde' => ({required Object taille}) => 'Cette photo dépasse ${taille} Mo. Reprenez-la en qualité plus basse.',
			'tuteur.reglages.camera' => 'Caméra',
			'tuteur.reglages.cameraAutorisee' => ({required Object prenom}) => '${prenom} peut allumer sa caméra pendant le cours.',
			'tuteur.reglages.cameraInterdite' => ({required Object prenom}) => 'Le bouton caméra n\'apparaîtra pas pour ${prenom}.',
			'tuteur.reglages.cameraAutoriser' => ({required Object prenom}) => 'Autoriser la caméra de ${prenom}',
			'tuteur.reglages.cameraRetirer' => ({required Object prenom}) => 'Retirer la caméra de ${prenom}',
			'tuteur.reglages.mode' => 'Affichage',
			'tuteur.reglages.modeEnfant' => ({required Object prenom}) => 'Grand affichage, sans lecture : ${prenom} reconnaît des images et écoute.',
			'tuteur.reglages.modeStandard' => ({required Object prenom}) => 'Affichage courant : ${prenom} lit son écran.',
			'tuteur.reglages.modePasserEnfant' => ({required Object prenom}) => 'Passer ${prenom} au grand affichage',
			'tuteur.reglages.modePasserStandard' => ({required Object prenom}) => 'Passer ${prenom} à l\'affichage courant',
			'tuteur.reglages.demandes' => 'Demander un changement',
			'tuteur.reglages.demandeReaffectation' => 'Changer d\'enseignant',
			'tuteur.reglages.demandeDuree' => 'Changer la durée des cours',
			'tuteur.reglages.demandeMinimum' => 'Changer la durée minimale payable',
			'tuteur.reglages.demandeSansEnseignant' => ({required Object prenom}) => '${prenom} n\'a pas encore d\'enseignant : il n\'y a rien à changer.',
			'tuteur.reglages.demandeTitreReaffectation' => ({required Object prenom}) => 'Changer l\'enseignant de ${prenom}',
			'tuteur.reglages.demandeTitreDuree' => ({required Object prenom}) => 'La durée des cours de ${prenom}',
			'tuteur.reglages.demandeTitreMinimum' => ({required Object prenom}) => 'La durée minimale payable pour ${prenom}',
			'tuteur.reglages.demandeActuelle' => ({required Object minutes}) => 'Aujourd\'hui : ${minutes} min',
			'tuteur.reglages.demandeMinutes' => ({required Object minutes}) => '${minutes} min',
			'tuteur.reglages.demandeMotif' => 'Pourquoi ce changement ?',
			'tuteur.reglages.demandeMotifRequis' => 'Un motif est nécessaire : c\'est lui qui permet de trancher.',
			'tuteur.reglages.demandeEnvoyer' => 'Envoyer la demande',
			'tuteur.reglages.demandeEnvoyee' => 'Demande envoyée. L\'administration la tranchera.',
			'tuteur.reglages.aucunEnfant' => 'Aucun enfant dans le foyer',
			'tuteur.reglages.aucunEnfantDetail' => 'Ajoutez un enfant pour pouvoir régler son affichage et sa caméra.',
			'tuteur.reglages.erreur' => ({required Object message}) => 'L\'enregistrement n\'a pas abouti : ${message}',
			'tuteur.suivi.titre' => 'Suivi du foyer',
			'tuteur.suivi.tousLesEnfants' => 'Tous les enfants',
			'tuteur.suivi.colonneDate' => 'Date',
			'tuteur.suivi.colonneEnfant' => 'Enfant',
			'tuteur.suivi.colonneEnseignant' => 'Enseignant',
			'tuteur.suivi.colonneEtat' => 'État',
			'tuteur.suivi.aujourdhui' => ({required Object heure}) => 'Aujourd\'hui, ${heure}',
			'tuteur.suivi.hier' => ({required Object heure}) => 'Hier, ${heure}',
			'tuteur.suivi.date' => ({required Object date, required Object heure}) => '${date}, ${heure}',
			'tuteur.suivi.annule' => 'Cours annulé',
			'tuteur.suivi.nonTenu' => 'Cours non tenu',
			'tuteur.suivi.vide' => 'Aucun cours pour l\'instant',
			'tuteur.suivi.videDetail' => 'Les cours de vos enfants s\'afficheront ici, du plus récent au plus ancien, avec leur présence.',
			'tuteur.suivi.videFiltre' => 'Aucun cours pour cet enfant',
			'tuteur.suivi.videFiltreDetail' => 'Relâchez le filtre pour retrouver le reste du foyer.',
			'tuteur.suivi.effacerFiltres' => 'Tout afficher',
			'tuteur.suivi.erreur' => 'Le suivi n\'a pas pu être lu. Réessayez dans un instant.',
			'tuteur.suivi.tronquee' => ({required Object nombre}) => 'Les ${nombre} cours les plus récents sont affichés.',
			'tuteur.suivi.fin' => ({required Object nombre}) => '${nombre} cours au suivi.',
			'tuteur.suivi.finUn' => '1 cours au suivi.',
			'classe.catalogue' => 'Choisir une classe',
			'classe.planning' => 'Planning',
			'classe.travail' => 'Travail à préparer',
			'classe.ressources' => 'Bibliothèque',
			'classe.progression' => 'Progression',
			'classe.observer' => 'Observer la séance',
			'classe.titre' => 'Classe',
			'classe.historique' => 'Historique',
			'classe.sousTitre' => ({required Object prenom, required Object enseignant}) => '${prenom} · ${enseignant}',
			'classe.indisponiblePhrase' => 'Le détail de la classe n\'est pas encore disponible ici.',
			'classe.introuvableTitre' => 'Cette classe n\'est pas ouverte à ce profil',
			'classe.introuvablePhrase' => 'Elle a peut-être pris fin, ou elle concerne un autre élève du foyer.',
			'classe.seance.aucune' => 'Aucune séance planifiée',
			'classe.seance.aucuneDetail' => ({required Object prenom}) => 'La prochaine séance de ${prenom} apparaîtra ici dès qu\'elle sera programmée.',
			'classe.seance.illisible' => 'La prochaine séance n\'a pas pu être lue.',
			'classe.seance.presence' => ({required Object prenom, required Object etat}) => '${prenom} : ${etat}',
			'classe.observation.commentCaMarche' => 'Comment ça marche ?',
			'classe.observation.uneVisite' => '1 visite disponible',
			'classe.observation.visites' => ({required Object nombre}) => '${nombre} visites disponibles',
			'classe.observation.resume' => ({required Object visites, required Object duree}) => '${visites} · ${duree} par visite',
			'classe.observation.restanteAucune' => 'Aucune visite restante pour cette séance',
			'classe.observation.restanteUne' => '1 visite restante pour cette séance',
			'classe.observation.restantes' => ({required Object nombre}) => '${nombre} visites restantes pour cette séance',
			'classe.observation.minutes' => ({required Object minutes}) => '${minutes} min',
			'classe.observation.minutesSecondes' => ({required Object minutes, required Object secondes}) => '${minutes} min ${secondes} s',
			'classe.observation.secondes' => ({required Object secondes}) => '${secondes} s',
			'classe.observation.motif.visitesEpuisees' => 'Vous avez utilisé vos visites pour cette séance.',
			'classe.observation.motif.tempsEpuise' => 'Votre temps d\'observation est épuisé pour cette séance.',
			'classe.observation.motif.seanceNonCommencee' => 'L\'observation ouvre quand la séance commence.',
			'classe.observation.motif.seanceTerminee' => 'La séance est terminée.',
			'classe.observation.motif.seanceNonTenue' => 'Cette séance n\'a pas lieu : il n\'y a rien à observer.',
			'classe.observation.motif.horsFenetre' => 'La salle n\'est pas ouverte à cette heure.',
			'classe.observation.motif.observationDesactivee' => 'L\'observation est fermée pour cette classe.',
			'classe.observation.motif.lienAbsent' => 'Aucun élève de votre foyer n\'est rattaché à cette séance.',
			'classe.observation.motif.enfantAbsent' => ({required Object prenom}) => 'L\'observation attend l\'arrivée de ${prenom}.',
			'classe.observation.motif.presenceEnVerification' => ({required Object prenom}) => 'La présence de ${prenom} est en cours de vérification.',
			'classe.observation.motif.visiteDejaOuverte' => 'Une visite est déjà ouverte, sur cet appareil ou sur un autre.',
			'classe.observation.motif.garantieServeurAbsente' => 'L\'observation des séances n\'est pas encore ouverte.',
			'classe.observation.motif.reseau' => 'La disponibilité de l\'observation n\'a pas pu être vérifiée.',
			'classe.observation.motif.capaciteAbsente' => 'L\'observation n\'est pas disponible pour le moment.',
			'classe.pagePlanning.prochaines' => 'Prochaines séances',
			'classe.pagePlanning.ligne' => ({required Object heure, required Object duree}) => '${heure} · ${duree}',
			'classe.pagePlanning.ligneFuseau' => ({required Object heure, required Object fuseau, required Object duree}) => '${heure} (${fuseau}) · ${duree}',
			'classe.pagePlanning.aucune' => 'Aucune séance à venir pour l\'instant',
			'classe.pagePlanning.aucuneDetail' => ({required Object prenom}) => 'Les prochaines séances de ${prenom} apparaîtront ici dès qu\'elles seront programmées.',
			'classe.pagePlanning.habituelIndisponible' => 'Les jours habituels de la classe ne sont pas encore affichés ici : seules les séances déjà programmées apparaissent.',
			'classe.pageTravail.aucun' => 'Rien à préparer pour l\'instant',
			'classe.pageTravail.aucunDetail' => 'Le travail donné par l\'enseignant apparaîtra ici.',
			'classe.pageTravail.indisponible' => 'Le travail à préparer n\'est pas encore relié à cet espace.',
			'classe.pageTravail.echeance' => ({required Object date}) => 'Échéance : ${date}',
			'classe.pageTravail.nonCochable' => 'Marquer un travail comme fait n\'est pas encore possible ici.',
			'classe.pageTravail.statut.aFaire' => 'À faire',
			'classe.pageTravail.statut.enCours' => 'Commencé',
			'classe.pageTravail.statut.fait' => 'Fait',
			'classe.pageTravail.statut.expire' => 'Échéance passée',
			'classe.pageRessources.aucune' => 'Aucune ressource pour cette classe pour l\'instant',
			'classe.pageRessources.aucuneDetail' => 'Les supports choisis par l\'enseignant apparaîtront ici.',
			'classe.pageRessources.indisponible' => 'La bibliothèque de la classe n\'est pas encore reliée à cet espace.',
			'classe.pageProgression.indisponible' => ({required Object prenom}) => 'La progression de ${prenom} n\'est pas encore partagée ici.',
			'classe.pageProgression.niveau' => 'Niveau',
			'classe.pageProgression.jalons' => 'Étapes franchies',
			'classe.pageProgression.aucune' => 'Aucune étape partagée pour l\'instant',
			'classe.pageProgression.aucuneDetail' => 'Les progrès que l\'enseignant partage avec la famille apparaîtront ici.',
			'enseignant.bienvenue.titre' => 'Premiers pas',
			'enseignant.bienvenue.salutation' => ({required Object prenom}) => 'Bienvenue, ${prenom}.',
			'enseignant.bienvenue.salutationSansNom' => 'Bienvenue.',
			'enseignant.bienvenue.dossierValide' => 'Votre dossier est validé.',
			'enseignant.bienvenue.suite' => 'Ce qui vient maintenant',
			'enseignant.bienvenue.pas1' => 'Vous déclarez vos heures d\'enseignement, par créneaux d\'une heure.',
			'enseignant.bienvenue.pas2' => 'L\'académie vous confie des élèves sur ces heures, en groupes de cinq enfants ou six adultes.',
			'enseignant.bienvenue.pas3' => 'Après chaque cours, vous remplissez un cahier de transmission. Il est prérempli : vous ne corrigez que les exceptions.',
			'enseignant.bienvenue.rappels' => 'Deux choses à ne pas découvrir en cours de route',
			'enseignant.bienvenue.rappelDejaAccepte' => 'Vous les avez accusées à l\'inscription. Elles sont rappelées ici, et la salle les rappelle en permanence.',
			'enseignant.bienvenue.declarer' => 'Déclarer mes disponibilités',
			'enseignant.bienvenue.versJournee' => 'Aller à ma journée',
			'enseignant.bienvenue.horsLigne' => 'Sans réseau, vos créneaux ne pourront pas être enregistrés.',
			'enseignant.bienvenue.dossierIncomplet' => 'Votre dossier n\'est pas encore validé.',
			'enseignant.bienvenue.dossierIncompletDetail' => 'Le portail d\'attente vous dit ce qu\'il reste à fournir.',
			'enseignant.bienvenue.versAttente' => 'Voir mon dossier',
			'enseignant.bienvenue.erreur' => 'Votre profil n\'a pas pu être lu. Réessayez dans un instant.',
			'enseignant.journee.lancer' => 'Lancer le cours',
			'enseignant.journee.preflight' => 'Vérifier avant le cours',
			'enseignant.journee.titre' => 'Votre journée',
			'enseignant.journee.prochainCours' => 'Prochain cours',
			'enseignant.journee.coursEnCours' => 'Séance en direct',
			'enseignant.journee.minuteurHeures' => ({required Object heures, required Object minutes}) => 'Dans ${heures} h ${minutes}',
			'enseignant.journee.minuteurMinutes' => ({required Object minutes}) => 'Dans ${minutes} min',
			'enseignant.journee.minuteurImminent' => 'Ça commence',
			'enseignant.journee.jusqua' => ({required Object heure}) => 'Jusqu\'à ${heure}',
			'enseignant.journee.unAutreJour' => ({required Object jour, required Object heure}) => '${jour}, à ${heure}',
			'enseignant.journee.lancementPlusTard' => 'Le lancement s\'ouvre dix minutes avant l\'heure du cours.',
			'enseignant.journee.aucunCours' => 'Aucun cours à venir',
			'enseignant.journee.aucunCoursDetail' => 'Prenez un élève en attente : c\'est ce qui remplit votre journée.',
			'enseignant.journee.colonne' => 'La journée',
			'enseignant.journee.ligneCours' => ({required Object prenom}) => 'Cours avec ${prenom}',
			'enseignant.journee.lignePause' => 'Pause',
			'enseignant.journee.plage' => ({required Object debut, required Object fin}) => '${debut} à ${fin}',
			'enseignant.journee.duree' => ({required Object minutes}) => '${minutes} min',
			'enseignant.journee.rienAujourdhui' => 'Rien de prévu aujourd\'hui',
			'enseignant.journee.rienAujourdhuiDetail' => ({required Object jour, required Object heure}) => 'Votre prochain cours est ${jour} à ${heure}.',
			'enseignant.journee.journeeTerminee' => ({required Object nombre}) => '${nombre} cours donnés aujourd\'hui.',
			'enseignant.journee.journeeTermineeUn' => '1 cours donné aujourd\'hui.',
			'enseignant.journee.voirCreneaux' => 'Voir mes créneaux',
			'enseignant.journee.erreur' => 'La journée n\'a pas pu être lue en entier. Réessayez dans un instant.',
			'enseignant.journee.coursIndividuel' => 'Cours individuel',
			'enseignant.journee.effectif' => ({required Object nombre}) => '${nombre} élèves',
			'enseignant.journee.effectifUn' => '1 élève',
			'enseignant.journee.voirGroupe' => 'Voir le groupe',
			'enseignant.journee.preflightOk' => 'Micro prêt',
			'enseignant.journee.preflightBloque' => 'Le micro est bloqué par votre navigateur. Autorisez-le pour lancer le cours.',
			'enseignant.journee.preflightSansMicro' => 'Aucun micro n\'est détecté. Branchez-en un pour lancer le cours.',
			'enseignant.journee.preflightIndisponible' => 'La vérification du matériel n\'a pas abouti. Réessayez avant de lancer le cours.',
			'enseignant.journee.lancerHorsLigne' => 'Sans réseau, la salle ne peut pas s\'ouvrir. Reconnectez-vous pour lancer le cours.',
			'enseignant.journee.erreurPartielle' => 'Une partie de la journée n\'a pas pu être lue : prières, pauses ou rapports peuvent manquer.',
			'enseignant.journee.absenceDetectee' => ({required Object eleve}) => '${eleve} n\'est pas entré en salle.',
			'enseignant.journee.coupureDetectee' => ({required Object eleve}) => '${eleve} a perdu la connexion.',
			'enseignant.journee.autresAbsences' => ({required Object nombre}) => 'et ${nombre} autres élèves.',
			'enseignant.journee.coursAnnule' => ({required Object heure}) => 'Le cours de ${heure} est annulé.',
			'enseignant.journee.rapportsTitre' => 'Rapports en attente',
			'enseignant.journee.rapportLigne' => ({required Object jour, required Object heure}) => 'Cours du ${jour} à ${heure}',
			'enseignant.journee.rapportAttente' => ({required Object heures}) => 'À déposer depuis ${heures} h',
			'enseignant.journee.rapportRetard' => ({required Object heures}) => 'En retard de ${heures} h',
			'enseignant.journee.enAttenteTitre' => 'Élèves en attente',
			'enseignant.journee.enAttenteLibelle' => 'élèves en attente sur vos heures',
			'enseignant.journee.enAttenteLibelleUn' => 'élève en attente sur vos heures',
			'enseignant.salle.reference' => ({required Object page, required Object total, required Object reference}) => 'Présenté : page ${page} sur ${total} · ${reference}',
			'enseignant.salle.rien' => 'Rien n\'est présenté',
			'enseignant.salle.rienInvitation' => 'Ouvrez le Coran pour montrer une page à votre groupe.',
			'enseignant.salle.attenteSalle' => 'Vous n\'êtes pas encore dans la salle',
			'enseignant.salle.attenteSalleDetail' => 'Les commandes de présentation s\'ouvrent dès que le cours est connecté.',
			'enseignant.salle.lienFaibleDetail' => 'le tour de page peut arriver en retard chez votre groupe',
			'enseignant.salle.presentationConservee' => 'la page présentée est conservée, elle repartira au retour du lien',
			'enseignant.salle.presentationSuspendue' => 'présentation suspendue',
			'enseignant.salle.precedente' => 'Présenter la page précédente',
			'enseignant.salle.suivante' => 'Présenter la page suivante',
			'enseignant.salle.bibliotheque' => 'Choisir une sourate',
			'enseignant.salle.presenterSourate' => ({required Object sourate}) => 'Présenter le début de ${sourate}',
			'enseignant.salle.sourateDetail' => ({required Object numero, required Object versets}) => 'Sourate ${numero} · ${versets} versets',
			'enseignant.salle.souratesIndisponibles' => 'La liste des sourates n\'a pas pu être lue',
			'enseignant.salle.souratesIndisponiblesDetail' => 'Ce que votre groupe voit n\'a pas changé. Réessayez.',
			'enseignant.salle.pageIndisponible' => 'Cette page n\'a pas pu être lue',
			'enseignant.salle.pageIndisponibleDetail' => 'Le texte n\'est pas arrivé jusqu\'ici. Votre groupe voit toujours la page présentée.',
			'enseignant.salle.corpusAbsent' => 'Le texte du Coran n\'est pas installé',
			'enseignant.salle.corpusAbsentDetail' => 'Le corpus n\'a pas été importé dans cet environnement. Il n\'y a rien à présenter.',
			'enseignant.salle.echecPresentation' => 'Ce verset n\'a pas pu être situé dans le mushaf. Rien n\'a été envoyé à votre groupe.',
			'enseignant.salle.sansDroitPresentation' => 'Votre accès à cette séance ne permet pas de présenter un contenu.',
			'enseignant.cahier.titre' => 'Cahier de transmission',
			'enseignant.cahier.duree' => ({required Object minutes}) => '${minutes} min de cours',
			'enseignant.cahier.dureeEtInterruption' => ({required Object minutes, required Object interruption}) => '${minutes} min de cours, dont ${interruption} min d\'interruption',
			'enseignant.cahier.unEleve' => '1 élève',
			'enseignant.cahier.eleves' => ({required Object nombre}) => '${nombre} élèves',
			'enseignant.cahier.toutEstNominal' => 'Tout s\'est passé comme prévu.',
			'enseignant.cahier.toutEstNominalDetail' => 'Validez, et votre journée continue.',
			'enseignant.cahier.exceptions' => 'À regarder',
			'enseignant.cahier.uneException' => '1 élève demande un regard.',
			'enseignant.cahier.plusieursExceptions' => ({required Object nombre}) => '${nombre} élèves demandent un regard.',
			'enseignant.cahier.nominaux' => 'Rien à signaler',
			'enseignant.cahier.curriculumFige' => 'Le niveau et le programme sont ceux de l\'académie : ils ne se modifient pas depuis le cahier.',
			'enseignant.cahier.noteGroupe' => 'Note pour le groupe',
			'enseignant.cahier.noteGroupeDetail' => 'Facultative. Aucun texte n\'est attendu.',
			'enseignant.cahier.valider' => 'Valider le cahier',
			'enseignant.cahier.validerTout' => 'Tout est conforme, valider',
			'enseignant.cahier.validerSansConstat' => 'Déposer sans le constat',
			'enseignant.cahier.retourJournee' => 'Retour à la journée',
			'enseignant.cahier.vide' => 'Le constat n\'a pas pu être déduit',
			'enseignant.cahier.videDetail' => 'Aucune présence et aucun événement n\'ont été relevés pour cette séance. Vous pouvez tout de même déposer le cahier.',
			'enseignant.cahier.erreur' => 'Le constat n\'a pas pu être lu.',
			'enseignant.cahier.erreurDetail' => 'Réessayez, ou déposez le cahier sans le constat : un cahier tardif vaut mieux qu\'un cahier perdu.',
			'enseignant.cahier.echecEnvoi' => 'Le cahier n\'a pas pu être enregistré. Réessayez.',
			'enseignant.cahier.dejaDepose' => 'Le cahier de cette séance est déjà déposé.',
			'enseignant.cahier.dejaDeposeDetail' => 'Un cahier ne se dépose qu\'une fois, et il ne se supprime pas d\'ici.',
			'enseignant.cahier.depose' => 'Cahier déposé',
			'enseignant.cahier.deposeDetail' => 'L\'académie l\'a reçu.',
			'enseignant.cahier.enFileTitre' => 'Cahier enregistré',
			'enseignant.cahier.enFile' => 'Enregistré. Sera envoyé dès le retour du réseau.',
			'enseignant.cahier.enFileDetail' => 'L\'envoi n\'a pas abouti : il repartira tout seul, sans que vous ayez à revenir ici.',
			'enseignant.cahier.enFileDetailHorsLigne' => 'Sans réseau, le cahier reste sur cet appareil et part dès que le réseau revient. Vous pouvez enchaîner sur votre cours suivant.',
			'enseignant.cahier.ajusterPour' => ({required Object eleve}) => 'Ajuster · ${eleve}',
			'enseignant.cahier.ajusterValider' => 'Enregistrer pour cet élève',
			_ => null,
		} ?? switch (path) {
			'enseignant.cahier.exceptionConsignee' => 'Exception signalée',
			'enseignant.cahier.pointPhonetique' => 'Point de prononciation',
			'enseignant.cahier.pointPhonetiqueDetail' => 'Une paire, pas un bilan. Laissez vide s\'il n\'y a rien à dire.',
			'enseignant.cahier.pointPhonetiqueNote' => 'Point de prononciation noté',
			'enseignant.cahier.objectif' => 'Objectif personnel',
			'enseignant.cahier.objectifDetail' => 'Il s\'inscrit dans le programme de l\'académie, qui ne se modifie pas d\'ici.',
			'enseignant.cahier.travailMaison' => 'Travail à la maison',
			'enseignant.cahier.travailMaisonDetail' => 'Ajustez la suggestion, ou laissez-la telle quelle.',
			'enseignant.cahier.suspendreNouveau' => 'Suspendre le nouveau contenu',
			'enseignant.cahier.suspendreNouveauDetail' => 'La révision continue, rien de nouveau n\'est ajouté pour cet élève.',
			'enseignant.cahier.position' => ({required Object sourate, required Object verset}) => 'Lecture : sourate ${sourate}, verset ${verset}',
			'enseignant.cahier.makhrajSinSad' => 'Sîn / Sâd (س / ص)',
			'enseignant.cahier.makhrajTaTah' => 'Tâ / Tâ emphatique (ت / ط)',
			'enseignant.cahier.makhrajDhalZay' => 'Dhâl / Zây (ذ / ز)',
			'enseignant.cahier.makhrajHaHah' => 'Hâ / Hâ\' (ه / ح)',
			'enseignant.cahier.exceptionTitre' => 'Signaler une exception',
			'enseignant.cahier.exceptionCorriger' => 'Corriger la présence',
			'enseignant.cahier.exceptionExcuser' => 'Excuser l\'absence',
			'enseignant.cahier.exceptionConfirmation' => 'Confirmer l\'exception',
			'enseignant.cahier.exceptionMotif' => 'Motif',
			'enseignant.cahier.exceptionMotifRequis' => 'Le motif est obligatoire : il reste au dossier de la séance.',
			'enseignant.cahier.exceptionEnCours' => 'Enregistrement…',
			'enseignant.cahier.exceptionSucces' => 'Exception consignée. Elle partira avec le cahier.',
			'enseignant.cahier.exceptionErreur' => 'L\'exception n\'a pas pu être consignée.',
			'enseignant.cahier.exceptionHorsLigne' => 'Sans réseau, une exception ne peut pas être confirmée. Le cahier, lui, part quand même.',
			'enseignant.cahier.exceptionJournalisation' => 'Votre décision et son motif sont consignés dans le cahier, avec votre nom.',
			'enseignant.profil.titre' => 'Profil',
			'enseignant.profil.compteValide' => 'Compte enseignant vérifié',
			'enseignant.profil.intro' => 'Ce que l\'académie sait de vous, et ce que vous pouvez y changer.',
			'enseignant.profil.identite' => 'Identité professionnelle',
			'enseignant.profil.identifiantDetail' => 'C\'est ce que les familles voient de vous. Il ne change jamais.',
			'enseignant.profil.pays' => 'Pays',
			'enseignant.profil.langues' => 'Langues',
			'enseignant.profil.fuseau' => 'Fuseau de mes cours',
			'enseignant.profil.fuseauDetail' => 'C\'est lui qui décide de l\'heure de vos créneaux, pas l\'heure de cet appareil.',
			'enseignant.profil.plafond' => 'Plafond hebdomadaire',
			'enseignant.profil.plafondValeur' => ({required Object nombre}) => '${nombre} h par semaine',
			'enseignant.profil.plafondDetail' => 'Fixé par l\'académie.',
			'enseignant.profil.nonRenseigne' => 'Non renseigné',
			'enseignant.profil.statutSection' => 'Statut du compte',
			'enseignant.profil.statutValideDetail' => 'Vous pouvez enseigner, déclarer vos heures et recevoir des élèves.',
			'enseignant.profil.statutEnAttente' => 'Dossier en cours de vérification',
			'enseignant.profil.statutEnAttenteDetail' => 'L\'académie vérifie vos pièces. Vous n\'avez rien de plus à faire.',
			'enseignant.profil.statutProvisoire' => 'Accès provisoire',
			'enseignant.profil.statutProvisoireDetail' => 'Vous enseignez déjà. Votre dossier reste à compléter, sans coupure automatique.',
			'enseignant.profil.statutSuspendu' => 'Compte suspendu',
			'enseignant.profil.statutSuspenduDetail' => 'Vous pouvez joindre l\'académie pour connaître la marche à suivre.',
			'enseignant.profil.statutInconnu' => 'Statut non disponible',
			'enseignant.profil.statutInconnuDetail' => 'Nous n\'avons pas pu lire votre statut. Il n\'est pas supposé pour autant.',
			'enseignant.profil.statutDivergent' => 'Ce statut vient de changer. Rouvrez l\'application pour que votre accès suive.',
			'enseignant.profil.verification' => 'Vérification du dossier',
			'enseignant.profil.verificationEnAttente' => 'En attente',
			'enseignant.profil.verificationValidee' => 'Validée',
			'enseignant.profil.verificationRefusee' => 'À reprendre',
			'enseignant.profil.contratSection' => 'Contrat et accusés',
			'enseignant.profil.contratEnseignant' => 'Contrat enseignant',
			'enseignant.profil.contratConditions' => 'Conditions d\'utilisation',
			'enseignant.profil.contratAccuse' => 'Enregistrement audio et visite de contrôle',
			'enseignant.profil.contratDetail' => ({required Object version, required Object date}) => 'Version ${version}, accepté le ${date}',
			'enseignant.profil.contratAucun' => 'Aucun contrat enregistré',
			'enseignant.profil.contratAucunDetail' => 'Votre dossier n\'est pas encore passé par la signature.',
			'enseignant.profil.contratErreur' => 'Vos contrats n\'ont pas pu être lus.',
			'enseignant.profil.contratLectureSeule' => 'Ces pièces sont en lecture seule : un contrat qui s\'édite depuis l\'écran de la personne qu\'il engage n\'est plus un contrat.',
			'enseignant.profil.personnel' => 'Mes réglages',
			'enseignant.profil.deconnexionQuestion' => 'Se déconnecter de cet appareil ?',
			'enseignant.profil.deconnexionConfirmer' => 'Me déconnecter maintenant',
			'enseignant.profil.deconnexionConsequence' => 'Votre journée, vos créneaux et vos cahiers restent enregistrés. Il faudra un nouveau lien de connexion pour revenir.',
			'enseignant.profil.erreur' => 'Votre profil n\'a pas pu être lu. Réessayez dans un instant.',
			'enseignant.profil.vide' => 'Aucun profil enseignant',
			'enseignant.profil.videDetail' => 'Ce compte n\'a pas de profil enseignant. Seule l\'académie peut en créer un.',
			'enseignant.profil.horsLigne' => 'Pas de réseau : rien ne peut être modifié ici pour l\'instant.',
			'enseignant.profil.modifierPays' => 'Modifier le pays',
			'enseignant.profil.modifierLangues' => 'Modifier les langues',
			'enseignant.profil.languesIndice' => 'Séparez les langues par une virgule',
			'enseignant.profil.enregistrer' => 'Enregistrer',
			'enseignant.profil.enregistre' => 'Modification enregistrée',
			'enseignant.profil.editionErreur' => 'La modification n\'a pas abouti. Réessayez dans un instant.',
			'enseignant.creneaux.heureLibelle' => ({required Object jour, required Object heure}) => '${jour} ${heure} h',
			'enseignant.creneaux.aucuneHeure' => 'Vous n\'avez proposé aucune heure. Sans créneau, aucune famille ne peut vous être proposée.',
			'enseignant.creneaux.heureEnregistree' => ({required Object heure}) => '${heure} enregistré',
			'enseignant.creneaux.heureRetiree' => ({required Object heure}) => '${heure} retiré',
			'enseignant.creneaux.retraitEngage' => ({required Object heure}) => '${heure} retiré. Le cours déjà attribué sur cette heure continue : demandez une réaffectation pour l\'arrêter.',
			'enseignant.creneaux.grilleErreur' => 'Vos heures n\'ont pas pu être lues',
			'enseignant.creneaux.grilleErreurDetail' => 'Le serveur n\'a pas répondu. Les heures que vous avez déjà posées ne sont pas perdues.',
			'enseignant.creneaux.horsLigneGrille' => 'Sans réseau, vos heures restent consultables mais ne peuvent pas être modifiées.',
			'enseignant.creneaux.heureEngagee' => ({required Object heures}) => 'Vous avez déjà un élève sur ${heures}. Retirer cette heure ne met pas fin au cours : il faut une réaffectation.',
			'enseignant.creneaux.heuresEngagees' => ({required Object heures}) => 'Vous avez déjà un élève sur ${heures}. Retirer ces heures ne met pas fin aux cours : il faut une réaffectation.',
			'enseignant.creneaux.feedErreur' => 'Les familles en attente n\'ont pas pu être lues',
			'enseignant.creneaux.feedErreurDetail' => 'Rien n\'est perdu : personne n\'a été pris, et vos heures restent posées.',
			'enseignant.creneaux.horsLignePrise' => 'Sans réseau, vous ne pouvez pas prendre d\'élève. Les demandes ci-dessous restent consultables.',
			'enseignant.creneaux.horsLigneDemande' => 'Sans réseau, cette demande ne partirait pas. Réessayez au retour de la connexion.',
			'enseignant.creneaux.refusDejaPris' => 'Cet élève vient d\'être pris par un autre enseignant. La liste ci-dessous est à jour.',
			'enseignant.creneaux.refusDejaSuivi' => 'Cet élève a déjà un enseignant. La liste ci-dessous est à jour.',
			'enseignant.creneaux.refusCreneauRetire' => 'Cette famille ne propose plus ce créneau. La liste ci-dessous est à jour.',
			'enseignant.creneaux.refusHorsMesHeures' => 'Ce créneau ne figure plus dans vos heures. Reposez-le dans Mes heures pour pouvoir le prendre.',
			'enseignant.creneaux.refusPlafond' => 'Vous avez atteint votre maximum d\'élèves. Demandez une augmentation pour en suivre un de plus.',
			'enseignant.ficheGroupe.titre' => 'Fiche du groupe',
			'enseignant.ficheGroupe.retour' => 'Retour à la journée',
			'enseignant.ficheGroupe.creneauTitre' => 'Le rendez-vous du groupe',
			'enseignant.ficheGroupe.creneauHebdo' => ({required Object jour, required Object heure}) => '${jour} à ${heure}, chaque semaine',
			'enseignant.ficheGroupe.complet' => 'Groupe complet',
			'enseignant.ficheGroupe.placesLibres' => 'places libres',
			'enseignant.ficheGroupe.placesLibresUn' => 'place libre',
			'enseignant.ficheGroupe.membresTitre' => 'Les élèves du groupe',
			'enseignant.ficheGroupe.niveauIndique' => ({required Object niveau}) => 'Niveau indiqué : ${niveau}',
			'enseignant.ficheGroupe.aucunMembre' => 'Aucun élève dans ce groupe',
			'enseignant.ficheGroupe.aucunMembreDetail' => 'L\'administration compose les groupes : celui-ci n\'a pas encore d\'élève.',
			'enseignant.ficheGroupe.erreur' => 'Ce groupe n\'a pas pu être lu. Réessayez dans un instant.',
			'enseignant.ficheGroupe.introuvable' => 'Ce groupe n\'est pas l\'un des vôtres',
			'enseignant.ficheGroupe.introuvableDetail' => 'Il a peut-être été clôturé, ou il appartient à un autre enseignant.',
			'enseignant.ficheGroupe.revue' => 'Ouvrir la revue du groupe',
			'enseignant.revue.titre' => 'Revue du groupe',
			'enseignant.revue.aucuneAnomalie' => 'Rien ne demande votre attention.',
			'enseignant.revue.aucuneAnomalieDetail' => 'Le calcul des anomalies pédagogiques n\'est pas encore ouvert aux enseignants : cette page reste vide jusque-là.',
			'enseignant.revue.erreur' => 'La revue n\'a pas pu être lue.',
			'enseignant.revue.erreurDetail' => 'Ce groupe n\'est peut-être pas le vôtre, ou la lecture a échoué.',
			'enseignant.revue.pasDeDecision' => 'Vous signalez, l\'académie tranche : un transfert et une réorientation ne se décident pas depuis ici.',
			'enseignant.revue.typeGate' => 'Palier à venir',
			'enseignant.revue.typeCorridor' => 'Élève hors corridor',
			'enseignant.revue.typeTransfert' => 'Proposition de transfert',
			'enseignant.revue.typeReorientation' => 'Proposition de réorientation',
			'controleur.planning.titre' => 'Planning global',
			'controleur.planning.visiteJournalisee' => 'Votre entrée est enregistrée : votre nom, la séance, l\'heure. Les participants, eux, ne vous voient pas.',
			'controleur.planning.tousEtats' => 'Tout',
			'controleur.planning.etatEnCours' => 'En cours',
			'controleur.planning.etatAVenir' => 'À venir',
			'controleur.planning.etatIncident' => 'À vérifier',
			'controleur.planning.tousEnseignants' => 'Tous les enseignants',
			'controleur.planning.colonneEnseignant' => 'Enseignant',
			'controleur.planning.colonneEleve' => 'Élève',
			'controleur.planning.colonneHeure' => 'Heure locale',
			'controleur.planning.colonneUtc' => 'UTC',
			'controleur.planning.colonneEtat' => 'État',
			'controleur.planning.colonneEntree' => 'Entrée',
			'controleur.planning.avec' => ({required Object enseignant, required Object eleve}) => '${enseignant} et ${eleve}',
			'controleur.planning.plage' => ({required Object debut, required Object fin}) => '${debut} à ${fin}',
			'controleur.planning.plageAutreJour' => ({required Object jour, required Object debut, required Object fin}) => '${jour} ${debut} à ${fin}',
			'controleur.planning.plageUtc' => ({required Object debut, required Object fin}) => '${debut} à ${fin} UTC',
			'controleur.planning.observer' => 'Observer',
			'controleur.planning.entree' => 'Entrée en cours',
			'controleur.planning.entreeRefusee' => 'L\'entrée n\'a pas été accordée. La séance vient peut-être de se terminer.',
			'controleur.planning.vide' => 'Aucune séance en cours ni à venir',
			'controleur.planning.videDetail' => 'Les cours programmés apparaîtront ici, du plus proche au plus lointain.',
			'controleur.planning.videFiltre' => 'Aucune séance ne correspond',
			'controleur.planning.videFiltreDetail' => 'Relâchez un filtre pour retrouver le reste du planning.',
			'controleur.planning.effacerFiltres' => 'Tout afficher',
			'controleur.planning.erreur' => 'Le planning n\'a pas pu être lu. Réessayez dans un instant.',
			'controleur.planning.tronquee' => ({required Object nombre}) => 'Les ${nombre} premières séances sont affichées.',
			'controleur.planning.fin' => ({required Object nombre}) => '${nombre} séances au planning.',
			'controleur.planning.finUne' => '1 séance au planning.',
			'aConstruire.titre' => 'Écran à construire',
			'aConstruire.detail' => 'Cet écran arrive à l\'étape 3.',
			'galerie.titre' => 'Galerie des composants',
			'galerie.avertissement' => 'Banc d\'essai de développement. Absent des versions de production.',
			'galerie.paires' => 'Paires de couleurs',
			'galerie.elevation' => 'Élévation et rayons',
			'galerie.typographie' => 'Échelles typographiques',
			'galerie.polices' => 'Polices',
			'galerie.composants' => 'Composants partagés',
			'galerie.modeEnfant' => 'Mode enfant',
			'galerie.modeStandard' => 'Mode standard',
			'tc.groupe.mesGroupes.titre' => 'Mes groupes',
			'tc.groupe.mesGroupes.aucun' => 'Aucun groupe pour le moment',
			'tc.groupe.mesGroupes.aucunDetail' => 'L\'académie vous placera dans un groupe dès qu\'un créneau vous correspond.',
			'tc.groupe.commun.erreur' => 'Vos groupes n\'ont pas pu être lus',
			'tc.groupe.commun.reessayer' => 'Réessayer',
			'tc.groupe.carte.ouvrir' => ({required Object libelle}) => 'Ouvrir le groupe ${libelle}',
			'tc.groupe.carte.capacite' => ({required Object membres, required Object seuil}) => '${membres} / ${seuil}',
			'tc.groupe.carte.capacitePhrase' => ({required Object membres, required Object seuil}) => '${membres} élèves sur ${seuil} places',
			'tc.groupe.carte.complet' => 'Complet',
			'tc.groupe.carte.prochainCours' => 'Prochain cours',
			'tc.groupe.carte.aucuneSeance' => 'Aucune séance planifiée',
			'tc.groupe.carte.aucuneSeanceDetail' => 'Le planning de ce groupe n\'est pas encore posé.',
			'tc.groupe.carte.duree' => ({required Object valeur}) => 'Durée ${valeur}',
			'tc.groupe.carte.dureeLibelle' => 'Durée',
			'tc.groupe.carte.rejoindre' => 'Rejoindre',
			'tc.groupe.enseignant.sayyid' => 'Sayyid',
			'tc.groupe.enseignant.sayyida' => 'Sayyida',
			'tc.groupe.enseignant.photoManquante' => 'Photo à fournir',
			'tc.groupe.enseignant.photoManquanteDetail' => 'La photo de l\'enseignant n\'a pas encore été enregistrée.',
			'tc.groupe.cours.coursEtNiveau' => ({required Object cours, required Object niveau}) => '${cours} · ${niveau}',
			'tc.groupe.temps.dansMinutes' => ({required Object minutes}) => 'Cours dans ${minutes} min',
			'tc.groupe.temps.dansHeures' => ({required Object heures, required Object minutes}) => 'Cours dans ${heures} h ${minutes}',
			'tc.groupe.temps.imminent' => 'Cours imminent',
			'tc.groupe.temps.salleOuverte' => ({required Object reste}) => 'Salle ouverte · ${reste}',
			'tc.groupe.temps.salleOuverteCourt' => 'Salle ouverte',
			'tc.groupe.temps.attente' => 'Vous êtes dans la salle. Le cours n\'a pas encore commencé.',
			'tc.groupe.temps.attenteDetail' => 'Ce temps d\'attente ne compte pas dans votre présence.',
			'tc.groupe.temps.enSalle' => 'En salle',
			'tc.groupe.temps.resteMinutes' => ({required Object minutes}) => 'Reste ${minutes} min',
			'tc.groupe.temps.resteHeures' => ({required Object heures, required Object minutes}) => 'Reste ${heures} h ${minutes}',
			'tc.groupe.temps.enCours' => ({required Object reste}) => 'Séance en direct · ${reste}',
			'tc.groupe.temps.enDirect' => 'En direct',
			'tc.groupe.temps.prolongee' => 'Séance toujours en direct',
			'tc.groupe.temps.depassement' => 'En dépassement',
			'tc.groupe.temps.terminee' => 'Cours terminé',
			'tc.groupe.duree.minutes' => ({required Object minutes}) => '${minutes} min',
			'tc.groupe.duree.heures' => ({required Object heures}) => '${heures} h',
			'tc.groupe.duree.heuresMinutes' => ({required Object heures, required Object minutes}) => '${heures} h ${minutes}',
			'tc.groupe.horloges.votreHeure' => 'Votre heure',
			'tc.groupe.horloges.chezEnseignant' => ({required Object nomme}) => 'Chez ${nomme}',
			'tc.groupe.horloges.heureGroupe' => 'Heure du groupe',
			'tc.groupe.horloges.heureEtVille' => ({required Object heure, required Object ville}) => '${heure} ${ville}',
			'tc.groupe.dst.j30' => 'Changement d\'heure dans un mois',
			'tc.groupe.dst.j7' => 'Changement d\'heure la semaine prochaine',
			'tc.groupe.dst.j1' => 'Changement d\'heure demain',
			'tc.groupe.dst.detail' => ({required Object avant, required Object apres}) => 'Votre cours passera de ${avant} à ${apres}.',
			'tc.groupe.session.conseilAppareil' => 'Tablette ou ordinateur conseillé pour le cours. Le téléphone reste pris en charge.',
			'tc.groupe.espace.retour' => 'Mes groupes',
			'tc.groupe.espace.avantProchainCours' => 'Avant le prochain cours',
			'tc.groupe.espace.aucuneAction' => 'Rien à préparer pour l\'instant',
			'tc.groupe.espace.bibliotheque' => 'Bibliothèque',
			'tc.groupe.espace.bibliothequeVoirTout' => 'Voir tout',
			'tc.groupe.espace.progression' => 'Progression',
			'tc.groupe.espace.roster' => 'Élèves du groupe',
			'tc.groupe.espace.reprendreLeCours' => 'Reprendre le cours',
			'tc.groupe.espace.introuvable' => 'Ce groupe ne vous est pas ouvert',
			'tc.groupe.espace.introuvableDetail' => 'Il a peut-être été clôturé, ou il appartient à une autre classe.',
			'tc.groupe.emplacement.nonBranche' => 'Bientôt disponible',
			'tc.groupe.emplacement.nonBrancheDetail' => 'Ce contenu sera rattaché à cet espace prochainement.',
			'tc.bibliotheque.titre' => 'Bibliothèque',
			'tc.bibliotheque.rechercheIndication' => 'Titre, niveau, sourate ou page',
			'tc.bibliotheque.rechercheLibelle' => 'Rechercher un support',
			'tc.bibliotheque.effacerRecherche' => 'Tout afficher',
			'tc.bibliotheque.filtre.type' => 'Type',
			'tc.bibliotheque.filtre.disponibilite' => 'Disponibilité',
			'tc.bibliotheque.sections.continuer' => 'Continuer',
			'tc.bibliotheque.sections.pourCeGroupe' => 'Pour ce groupe',
			'tc.bibliotheque.sections.recents' => 'Récents',
			'tc.bibliotheque.sections.tousLesSupports' => 'Tous les supports',
			'tc.bibliotheque.sections.resultats' => 'Résultats',
			'tc.bibliotheque.vide.message' => 'Aucun support publié pour le moment',
			'tc.bibliotheque.vide.invitation' => 'Vos enseignants déposeront ici les supports de vos cours.',
			'tc.bibliotheque.aucunResultat.message' => 'Aucun support ne correspond',
			'tc.bibliotheque.aucunResultat.invitation' => 'Essayez un autre mot, ou relâchez les filtres.',
			'tc.bibliotheque.indisponible.message' => 'La bibliothèque est momentanément indisponible',
			'tc.bibliotheque.indisponible.action' => 'Réessayer',
			'tc.bibliotheque.introuvable.message' => 'Ce support ne vous est pas ouvert',
			'tc.bibliotheque.introuvable.invitation' => 'Il a peut-être été retiré, ou il est réservé à un autre groupe. Votre enseignant peut vous le rouvrir.',
			'tc.bibliotheque.offline.aTelecharger' => 'À télécharger',
			'tc.bibliotheque.offline.enCours' => 'Téléchargement',
			'tc.bibliotheque.offline.enCache' => 'En cache',
			'tc.bibliotheque.offline.telecharge' => 'Téléchargé',
			'tc.bibliotheque.offline.indisponible' => 'Hors ligne indisponible',
			'tc.bibliotheque.type.quran' => 'Coran',
			'tc.bibliotheque.type.texteStructure' => 'Texte',
			'tc.bibliotheque.type.pdf' => 'PDF',
			'tc.bibliotheque.type.image' => 'Image',
			'tc.bibliotheque.type.lecon' => 'Leçon',
			'tc.bibliotheque.detail.titre' => 'Support',
			'tc.bibliotheque.detail.capacites' => 'Ce que ce support permet',
			'tc.bibliotheque.detail.niveaux' => 'Niveaux',
			'tc.bibliotheque.detail.sansVersion' => 'Aucune version publiée : rien à ouvrir pour le moment.',
			'tc.bibliotheque.detail.apercuIndisponible' => 'L’aperçu de ce format n’est pas encore disponible dans l’application. Vous pouvez en enregistrer une copie.',
			'tc.bibliotheque.detail.renduCoran' => 'Le Coran s’ouvre dans le lecteur dédié.',
			'tc.bibliotheque.action.telecharger' => 'Rendre disponible hors ligne',
			'tc.bibliotheque.action.liberer' => 'Libérer la place',
			'tc.bibliotheque.action.enregistrerCopie' => 'Enregistrer une copie',
			'tc.bibliotheque.message.copieEnregistree' => 'Copie enregistrée',
			'tc.bibliotheque.message.copieImpossible' => 'Cette copie n’est pas disponible pour le moment',
			'tc.bibliotheque.message.telechargementImpossible' => 'Ce support n’est pas encore disponible hors ligne',
			'tc.bibliotheque.message.horsLigneNonTelecharge' => 'Disponible une fois téléchargé ou de retour en ligne',
			'tc.bibliotheque.message.aucunTelechargement' => 'Aucun fichier à télécharger pour cette version.',
			'tc.bibliotheque.classe.titre' => 'Choisir un support',
			'tc.bibliotheque.classe.sousTitre' => 'Le support choisi remplace celui affiché. Le cours continue.',
			'tc.coran.modes.mushaf' => 'Page du mushaf',
			'tc.coran.modes.verset' => 'Lecture agrandie',
			'tc.coran.modes.focus' => 'Focus',
			'tc.coran.modes.choisir' => 'Mode de lecture',
			'tc.coran.mushaf.coteDroite' => 'Page de droite',
			'tc.coran.mushaf.coteGauche' => 'Page de gauche',
			'tc.coran.mushaf.ouverture' => ({required Object droite, required Object gauche}) => 'Ouverture, pages ${droite} et ${gauche}',
			'tc.coran.fidelite.approchee' => 'Composition approchée',
			'tc.coran.fidelite.approcheeDetail' => 'Les versets de cette page sont exactement ceux de la page du Mushaf de Médine. Leur répartition sur les lignes, elle, est celle de cet écran : le découpage en lignes de l\'édition n\'est pas encore importé.',
			'tc.coran.fidelite.fidele' => 'Composition de l\'édition',
			'tc.coran.zoom.bride' => 'Grossissement limité par la largeur : au-delà, un mot serait coupé.',
			'tc.coran.zoom.valeur' => ({required Object pourcent}) => '${pourcent} %',
			'tc.coran.zoom.renvoiLectureAgrandie' => 'Pour grossir le texte, passez en lecture agrandie : la page du mushaf garde sa géométrie.',
			'tc.coran.navigation.titre' => 'Aller à',
			'tc.coran.navigation.ouvrir' => 'Aller à une page',
			'tc.coran.navigation.champ' => 'Page, sourate, juz ou référence',
			'tc.coran.navigation.indice' => 'Par exemple 18, Al-Kahf, juz 15, 2:255',
			'tc.coran.navigation.limite' => 'La recherche porte sur les numéros de page, les références et les noms de sourate. La recherche dans le texte du Coran n\'est pas encore disponible.',
			'tc.coran.navigation.aucunResultat' => 'Aucune référence trouvée',
			'tc.coran.navigation.aucunResultatDetail' => 'Essayez un numéro de page, un nom de sourate, ou une référence comme 2:255.',
			'tc.coran.navigation.pageNumero' => ({required Object page}) => 'Page ${page}',
			'tc.coran.reprise.groupe' => 'Reprendre le cours',
			'tc.coran.reprise.groupeDetail' => ({required Object page}) => 'Le groupe en était page ${page}',
			'tc.coran.focus.aucunePlage' => 'Aucun passage mis en avant',
			'tc.coran.focus.aucunePlageDetail' => 'Le focus suit le passage que l\'enseignant désigne. Hors classe, il centre la page ouverte.',
			'tc.coran.focus.quitter' => 'Quitter le focus',
			'tc.outils.dock.titre' => 'Outils',
			'tc.outils.dock.deplacer' => 'Déplacer les outils',
			'tc.outils.dock.position.bas' => 'En bas',
			'tc.outils.dock.position.gauche' => 'À gauche',
			'tc.outils.dock.position.droite' => 'À droite',
			'tc.outils.dock.bibliotheque' => 'Bibliothèque',
			'tc.outils.dock.focus' => 'Focus',
			'tc.outils.dock.marquer' => 'Marquer',
			'tc.outils.dock.masquer' => 'Masquer',
			'tc.outils.dock.stylet' => 'Stylet',
			'tc.outils.dock.pointeur' => 'Pointeur',
			'tc.outils.dock.revision' => 'Révision',
			'tc.outils.intention.aApprendre' => 'À apprendre',
			'tc.outils.intention.aRevoir' => 'À revoir',
			'tc.outils.intention.aRenforcer' => 'À renforcer',
			'tc.outils.intention.aEntretenir' => 'À entretenir',
			'tc.outils.intention.pourEvaluation' => 'Pour l\'évaluation',
			'tc.outils.trait.stylet' => 'Stylet',
			'tc.outils.trait.surligneur' => 'Surligner',
			'tc.outils.trait.gomme' => 'Gomme',
			'tc.outils.trait.annuler' => 'Annuler',
			'tc.outils.trait.plus' => 'Plus',
			'tc.outils.portee.temporaire' => 'Le temps d\'expliquer',
			'tc.outils.portee.seance' => 'Jusqu\'à la fin du cours',
			'tc.outils.portee.enregistree' => 'Enregistrer',
			'tc.outils.portee.aide' => 'Combien de temps garder ces annotations ?',
			'tc.outils.marquer.titre' => 'Marquer ce passage',
			'tc.outils.marquer.aide' => 'Choisissez ce que ce passage demande.',
			'tc.outils.marquer.retirer' => 'Retirer le marqueur',
			'tc.outils.revision.titre' => 'À préparer',
			'tc.outils.revision.aide' => 'Le passage sélectionné devient un travail à préparer.',
			'tc.outils.revision.groupeEntier' => 'Tout le groupe',
			'tc.outils.revision.consigne' => 'Consigne courte (facultatif)',
			'tc.outils.revision.creer' => 'Poser le travail',
			'tc.outils.revision.posee' => 'Travail à préparer posé',
			'tc.outils.masquer.reveler' => 'Révéler',
			'tc.outils.masquer.refermer' => 'Masquer de nouveau',
			'tc.outils.masquer.tout' => 'Tout démasquer',
			'tc.outils.focus.quitter' => 'Quitter le focus',
			'tc.outils.annotation.ancrageDegrade' => 'Ce passage n\'a pas de repère de texte : l\'annotation suivra la page, pas les mots.',
			'tc.outils.annotation.horsPage' => 'Annotations masquées : leur passage n\'est pas à l\'écran.',
			'tc.outils.annotation.aucuneSelection' => 'Sélectionnez d\'abord un passage.',
			'tc.classe.entete.titreEnseignant.sayyid' => 'Sayyid',
			'tc.classe.entete.titreEnseignant.sayyida' => 'Sayyida',
			'tc.classe.entete.resteMinutes' => ({required Object minutes}) => 'Reste ${minutes} min',
			'tc.classe.entete.resteHeuresMinutes' => ({required Object heures, required Object minutes}) => 'Reste ${heures} h ${minutes}',
			'tc.classe.entete.coursEnCours' => 'Séance toujours en direct',
			'tc.classe.entete.photoManquante' => 'Photo enseignant manquante',
			'tc.classe.roster.titre' => 'Élèves',
			'tc.classe.roster.compteur' => ({required Object presents, required Object attendus}) => 'Élèves : ${presents} présents sur ${attendus} attendus',
			'tc.classe.roster.indisponible' => 'Roster indisponible',
			'tc.classe.roster.indisponibleDetail' => 'Les états de vos élèves n\'ont pas pu être lus. Le cours continue.',
			'tc.classe.roster.vide' => 'Aucun élève inscrit',
			'tc.classe.roster.videDetail' => 'Cette séance n\'a aucun élève inscrit. Vérifiez le groupe.',
			'tc.classe.roster.ouvrirFiche' => ({required Object prenom}) => 'Ouvrir la fiche de ${prenom}',
			'tc.classe.roster.places' => ({required Object inscrits, required Object plafond}) => '${inscrits} / ${plafond} places',
			'tc.classe.etat.inconnu' => 'État inconnu',
			'tc.classe.etat.attendu' => 'Attendu',
			'tc.classe.etat.enConnexion' => 'En connexion',
			'tc.classe.etat.present' => 'Présent',
			'tc.classe.etat.enRetard' => 'En retard',
			'tc.classe.etat.deconnecte' => 'Déconnecté',
			'tc.classe.etat.enReconnexion' => 'En reconnexion',
			'tc.classe.etat.sorti' => 'Sorti',
			'tc.classe.etat.absent' => 'Absent',
			'tc.classe.fiche.niveau' => 'Niveau',
			'tc.classe.fiche.objectif' => 'Objectif actuel',
			'tc.classe.fiche.derniereSeance' => 'Dernière séance',
			'tc.classe.fiche.page' => ({required Object page}) => 'Page ${page}',
			'tc.classe.fiche.travailEnCours' => ({required Object nombre}) => '${nombre} élément(s)',
			'tc.classe.fiche.aReprendre' => 'À reprendre',
			'tc.classe.fiche.presenceRecente' => 'Présence récente',
			'tc.classe.fiche.assiduite' => ({required Object presences, required Object total}) => '${presences} / ${total} cours',
			'tc.classe.fiche.travailActuel' => 'Travail actuel',
			'tc.classe.fiche.interfaceGuidee' => 'Interface guidée',
			'tc.classe.fiche.sansPedagogie' => 'Suivi pédagogique indisponible',
			'tc.classe.fiche.sansPedagogieDetail' => 'Le parcours, les objectifs et le travail en cours ne sont pas encore ouverts à l\'enseignant.',
			'tc.classe.action.rappel' => 'Rappel discret',
			'tc.classe.action.reciter' => 'Choisir pour réciter',
			'tc.classe.action.noter' => 'Noter',
			'tc.classe.action.signaler' => 'Signaler un besoin',
			'tc.classe.action.contexte' => 'Ouvrir le contexte',
			'tc.classe.rappel.recu' => 'Le professeur vous appelle',
			'tc.classe.rappel.echec' => 'Le rappel n\'a pas pu être envoyé',
			'tc.classe.rappel.echecDroit' => 'Votre accès à cette séance ne permet pas d\'appeler un élève',
			'tc.classe.rappel.cooldown' => ({required Object secondes}) => 'Déjà appelé. À nouveau dans ${secondes} s',
			'tc.classe.recitation.titre' => 'Récitation',
			'tc.classe.recitation.actif' => ({required Object prenom}) => '${prenom} récite',
			'tc.classe.recitation.pastille' => 'Récite',
			'tc.classe.recitation.suivants' => 'Ensuite',
			'tc.classe.recitation.personne' => 'Personne ne récite',
			'tc.classe.recitation.arreter' => 'Arrêter la récitation',
			'tc.classe.support.aucun' => 'Aucun support présenté',
			'tc.classe.support.aucunDetail' => 'Ouvrez la Bibliothèque pour présenter un support au groupe.',
			'tc.classe.support.bibliotheque' => 'Bibliothèque',
			'tc.classe.support.bibliothequeAbsente' => 'Bibliothèque non branchée',
			'tc.classe.support.bibliothequeAbsenteDetail' => 'Le choix de support sera disponible dès l\'intégration du catalogue.',
			'tc.classe.commandes.micro' => 'Ouvrir le micro',
			'tc.classe.commandes.microFermer' => 'Fermer le micro',
			'tc.classe.commandes.camera' => 'Ouvrir la caméra',
			'tc.classe.commandes.cameraFermer' => 'Fermer la caméra',
			'tc.classe.commandes.microCoupe' => 'Micro fermé',
			'tc.classe.commandes.quitter' => 'Quitter',
			'tc.classe.commandes.quitterQuestion' => 'Quitter le cours ?',
			'tc.classe.commandes.quitterConsequence' => 'Votre sortie sera enregistrée. Vous pourrez revenir tant que la séance est ouverte.',
			'tc.classe.commandes.fermerBibliotheque' => 'Fermer la Bibliothèque',
			'tc.classe.scene.vide' => 'Vous êtes seul dans la salle pour le moment',
			'tc.classe.scene.sansImage' => 'Sans image',
			'tc.classe.reseau.bon' => 'Réseau bon',
			'tc.classe.reseau.mediocre' => 'Réseau instable',
			'tc.classe.reseau.perdu' => 'Réseau perdu',
			'tc.classe.attente.materiel' => 'Vérification de votre micro',
			'tc.classe.attente.ouverture' => 'Ouverture du cours',
			'tc.classe.attente.connexion' => 'Connexion au cours',
			'tc.classe.attente.refus' => 'Le cours n\'est pas accessible pour le moment',
			'tc.classe.lien.instable' => 'Connexion instable',
			'tc.classe.lien.reconnexion' => 'Reconnexion en cours',
			'tc.classe.lien.retabli' => 'Connexion rétablie',
			'tc.classe.lien.echec' => 'Connexion perdue',
			'tc.classe.lien.retourDeSuspension' => 'Le cours a été mis en pause par le système. Vérification du lien en cours.',
			'tc.classe.barre.titre' => 'Séance en direct',
			'tc.classe.barre.revenir' => ({required Object groupe}) => 'Revenir au cours de ${groupe}',
			'tc.classe.prevol.titre' => 'Avant d\'ouvrir le cours',
			'tc.classe.prevol.microOk' => 'Micro détecté',
			'tc.classe.prevol.microAbsent' => 'Aucun micro utilisable',
			'tc.classe.prevol.cameraOk' => 'Caméra détectée',
			'tc.classe.prevol.cameraAbsente' => 'Aucune caméra. Le cours reste possible.',
			'tc.classe.prevol.permissionRefusee' => 'Accès au micro refusé. Autorisez-le pour ouvrir le cours.',
			'tc.classe.prevol.reessayer' => 'Vérifier à nouveau',
			'tc.classe.observation.restant' => ({required Object secondes}) => 'Reste ${secondes} s',
			'tc.realtime.transport.partage_indisponible' => 'Le partage du support n’est pas disponible sur ce serveur. Le cours continue, mais les autres appareils ne suivront pas la page.',
			'tc.realtime.etat.restauration_impossible' => 'Impossible de retrouver le support en cours. Demandez à l’enseignant de le présenter à nouveau.',
			'tc.observation.entree.titre' => 'Observer la séance',
			'tc.observation.entree.tuteurIntro' => 'Vous pouvez regarder un court moment le cours de votre enfant. Votre micro et votre caméra restent fermés.',
			'tc.observation.entree.adminIntro' => 'Choisissez votre mode avant d\'entrer. Il ne change plus ensuite.',
			'tc.observation.entree.controleurIntro' => 'Vous entrez en observation invisible. Aucun micro, aucune caméra.',
			'tc.observation.entree.entrer' => 'Entrer',
			'tc.observation.entree.modeDiscret' => 'Observer discrètement',
			'tc.observation.entree.modeDiscretDetail' => 'Invisible pour les participants. Sans micro ni caméra, sans annonce.',
			'tc.observation.entree.modeVisible' => 'Rejoindre la classe',
			'tc.observation.entree.modeVisibleDetail' => 'Visible par tous sous le nom Administration Rewayah. Micro et caméra permis, annonce faite.',
			'tc.observation.entree.nomInstitutionnel' => 'Administration Rewayah',
			'tc.observation.entree.visiteJournalisee' => 'Visite journalisée : identité, séance, entrée, sortie et durée.',
			'tc.observation.entree.roleSansObservation' => 'Votre compte n\'observe pas les séances.',
			'tc.observation.refus.politiqueDesactivee' => 'L\'observation est désactivée pour ce groupe.',
			'tc.observation.refus.quotaVisites' => 'Vous avez déjà utilisé vos visites pour cette séance.',
			'tc.observation.refus.tempsEpuise' => 'Votre temps d\'observation est épuisé pour cette séance.',
			'tc.observation.refus.lienTuteur' => 'Vous n\'êtes rattaché à aucun élève de cette séance.',
			'tc.observation.refus.seanceNonActive' => 'La séance n\'est pas en cours.',
			'tc.observation.refus.horsFenetre' => 'La salle n\'est pas ouverte à cette heure.',
			'tc.observation.refus.indisponible' => 'L\'observation n\'est pas disponible pour le moment.',
			'tc.observation.refus.capaciteAbsente' => 'L\'observation n\'est pas encore activée sur cette installation.',
			'tc.observation.visite.titre' => 'Observation en cours',
			'tc.observation.visite.quitter' => 'Quitter',
			'tc.observation.visite.mediaFerme' => 'Micro et caméra fermés pendant l\'observation.',
			'tc.observation.visite.supportIndisponible' => 'Le support partagé par l\'enseignant s\'affiche ici.',
			'tc.observation.visite.enseignant' => 'Enseignant',
			'tc.observation.visite.monEnfant' => 'Votre enfant',
			'tc.observation.visite.enfantAbsent' => 'Votre enfant n\'a pas d\'image ouverte.',
			'tc.observation.visite.budgetIncertain' => 'Temps restant non confirmé par le serveur.',
			'tc.observation.visite.videoIndisponible' => 'La vidéo de la séance n\'a pas pu s\'ouvrir. Votre temps d\'observation continue de s\'écouler.',
			'tc.observation.visite.sortieNonConfirmee' => 'La fin de votre visite n\'a pas pu être confirmée. Elle sera fermée par le serveur.',
			'tc.observation.visite.restant' => ({required Object secondes}) => '${secondes} s restantes',
			'tc.observation.visite.visites' => ({required Object rang, required Object total}) => 'Visite ${rang} sur ${total}',
			'tc.observation.fin.sortieVolontaire' => 'Vous avez quitté l\'observation.',
			'tc.observation.fin.quotaAtteint' => 'Votre temps d\'observation est écoulé.',
			'tc.observation.fin.seanceTerminee' => 'La séance est terminée.',
			'tc.observation.fin.revocationServeur' => 'Votre observation a été interrompue.',
			'tc.observation.fin.deconnexion' => 'La connexion a été perdue.',
			'tc.observation.annonce.tuteurObserve' => ({required Object prenomEnfant}) => 'Tuteur de ${prenomEnfant} observe',
			'tc.observation.annonce.restant' => ({required Object secondes}) => '${secondes} s',
			'tc.observation.annonce.enfantIndicateur' => 'Ton tuteur regarde le cours',
			'tc.observation.annonce.tuteursObservent' => ({required Object nombre}) => '${nombre} tuteurs observent',
			'tc.observation.reglages.titre' => 'Observation par les tuteurs',
			'tc.observation.reglages.intro' => 'Un tuteur peut regarder un court moment le cours de son enfant, sans micro ni caméra. Ce réglage décide de ce qui s\'applique à ce groupe.',
			'tc.observation.reglages.heriter' => 'Hériter de l\'Académie',
			'tc.observation.reglages.personnaliser' => 'Personnaliser pour ce groupe',
			'tc.observation.reglages.desactiver' => 'Désactiver pour ce groupe',
			'tc.observation.reglages.maxVisites' => 'Visites par séance',
			'tc.observation.reglages.tempsTotal' => 'Temps total par séance',
			'tc.observation.reglages.plafondVisite' => 'Durée maximale d\'une visite',
			'tc.observation.reglages.diminuer' => 'Diminuer',
			'tc.observation.reglages.augmenter' => 'Augmenter',
			'tc.observation.reglages.enregistrer' => 'Enregistrer',
			'tc.observation.reglages.invalideVisites' => 'Au moins une visite par séance.',
			'tc.observation.reglages.invalideTemps' => 'Au moins trente secondes par séance.',
			'tc.observation.reglages.valeurHeritee' => ({required Object valeur}) => 'Académie : ${valeur}',
			'tc.observation.reglages.uniteVisiteUne' => ({required Object n}) => '${n} visite',
			'tc.observation.reglages.uniteVisites' => ({required Object n}) => '${n} visites',
			'tc.observation.reglages.uniteSecondes' => ({required Object n}) => '${n} s',
			'tc.observation.reglages.versionPolitique' => ({required Object version}) => 'Version ${version}',
			'tc.parcours.avant.titre' => 'Avant le prochain cours',
			'tc.parcours.avant.rien' => 'Rien à préparer pour le prochain cours.',
			'tc.parcours.avant.rienDetail' => 'Votre enseignant proposera le travail à la fin de la prochaine séance.',
			'tc.parcours.avant.nonBranche' => 'Le travail à préparer n\'est pas encore relié à cet espace.',
			'tc.parcours.avant.nonBrancheDetail' => 'Cela ne veut pas dire qu\'il n\'y a rien à préparer : cet écran ne sait pas encore le lire.',
			'tc.parcours.avant.reprendre' => 'Reprendre le cours',
			'tc.parcours.avant.reprendreDepuis' => ({required Object position}) => 'Reprendre le cours à ${position}',
			'tc.parcours.intention.apprendre' => 'À apprendre',
			'tc.parcours.intention.revoir' => 'À revoir',
			'tc.parcours.intention.renforcer' => 'À renforcer',
			'tc.parcours.intention.entretenir' => 'À entretenir',
			'tc.parcours.intention.evaluation' => 'Pour l\'évaluation',
			'tc.parcours.plage.versets' => ({required Object sourate, required Object premier, required Object dernier}) => 'Sourate ${sourate}, versets ${premier} à ${dernier}',
			'tc.parcours.plage.versetUnique' => ({required Object sourate, required Object premier}) => 'Sourate ${sourate}, verset ${premier}',
			'tc.parcours.plage.versetsCroisee' => ({required Object sourateDebut, required Object versetDebut, required Object sourateFin, required Object versetFin}) => 'Sourate ${sourateDebut}, verset ${versetDebut} jusqu\'à sourate ${sourateFin}, verset ${versetFin}',
			'tc.parcours.plage.pages' => ({required Object premiere, required Object derniere}) => 'Pages ${premiere} à ${derniere}',
			'tc.parcours.plage.pageUnique' => ({required Object premiere}) => 'Page ${premiere}',
			'tc.parcours.plage.section' => ({required Object section}) => 'Section ${section}',
			'tc.parcours.plage.ressource' => 'Tout le support',
			'tc.parcours.feedback.cours.intitule' => 'Comment était le cours aujourd\'hui ?',
			'tc.parcours.feedback.cours.difficile' => 'Difficile',
			'tc.parcours.feedback.cours.bien' => 'Bien',
			'tc.parcours.feedback.cours.tresBien' => 'Très bien',
			'tc.parcours.feedback.comprehension.intitule' => 'Avez-vous compris ce qui a été travaillé ?',
			'tc.parcours.feedback.comprehension.difficile' => 'Pas vraiment',
			'tc.parcours.feedback.comprehension.bien' => 'Plutôt oui',
			'tc.parcours.feedback.comprehension.tresBien' => 'Tout à fait',
			'tc.parcours.feedback.rythme.intitule' => 'Le rythme du cours vous a-t-il convenu ?',
			'tc.parcours.feedback.rythme.difficile' => 'Trop rapide',
			'tc.parcours.feedback.rythme.bien' => 'Convenable',
			_ => null,
		} ?? switch (path) {
			'tc.parcours.feedback.rythme.tresBien' => 'Très confortable',
			'tc.parcours.feedback.technique.intitule' => 'Le son et l\'image étaient-ils confortables ?',
			'tc.parcours.feedback.technique.difficile' => 'Gênants',
			'tc.parcours.feedback.technique.bien' => 'Corrects',
			'tc.parcours.feedback.technique.tresBien' => 'Très bons',
			'tc.parcours.feedback.confiance.intitule' => 'Vous sentez-vous prêt pour le prochain cours ?',
			'tc.parcours.feedback.confiance.difficile' => 'Pas encore',
			'tc.parcours.feedback.confiance.bien' => 'Plutôt',
			'tc.parcours.feedback.confiance.tresBien' => 'Tout à fait',
			'tc.parcours.feedback.merci' => 'Merci.',
			'tc.parcours.feedback.tendance.titre' => 'Retour des élèves',
			'tc.parcours.feedback.tendance.sousSeuil' => 'Pas encore assez de retours pour dégager une tendance.',
			'tc.parcours.feedback.tendance.anonyme' => 'Les retours sont anonymes et agrégés. Ils ne suffisent jamais, seuls, à une décision.',
			'tc.parcours.signalement.titre' => 'Signaler un besoin',
			'tc.parcours.signalement.categorie' => 'De quoi s\'agit-il ?',
			'tc.parcours.signalement.categorieValeur.pedagogique' => 'Pédagogique',
			'tc.parcours.signalement.categorieValeur.presence' => 'Présence',
			'tc.parcours.signalement.categorieValeur.technique' => 'Technique',
			'tc.parcours.signalement.categorieValeur.changement' => 'Changement',
			'tc.parcours.signalement.categorieValeur.autre' => 'Autre',
			'tc.parcours.signalement.interne' => 'Note interne',
			'tc.parcours.signalement.interneAide' => 'Lue par l\'administration seulement. Elle ne part jamais automatiquement à la famille.',
			'tc.parcours.signalement.famille' => 'Message pour la famille',
			'tc.parcours.signalement.familleAide' => 'Facultatif. L\'administration décide seule de le transmettre, en un clic.',
			'tc.parcours.signalement.contexte' => ({required Object eleve}) => 'Élève ${eleve}. La séance, le groupe et votre nom sont déjà joints.',
			'tc.parcours.signalement.envoyer' => 'Envoyer le signalement',
			'tc.parcours.signalement.envoye' => 'Signalement transmis à l\'administration.',
			'tc.parcours.signalement.interneRequis' => 'Écrivez au moins ce que l\'administration doit savoir.',
			'tc.parcours.signalement.echec' => 'Le signalement n\'a pas pu être transmis. Réessayez.',
			'tc.parcours.postCours.titre' => 'Après le cours',
			'tc.parcours.postCours.duree' => ({required Object minutes}) => 'Durée réelle ${minutes} min',
			'tc.parcours.postCours.exceptions' => 'À confirmer',
			'tc.parcours.postCours.toutEstNominal' => 'Rien ne demande votre attention.',
			'tc.parcours.postCours.reprise' => 'Reprise proposée',
			'tc.parcours.postCours.repriseInconnue' => 'Aucune position de reprise connue pour cette séance.',
			'tc.parcours.postCours.travail' => 'Travail proposé',
			'tc.parcours.postCours.travailAucun' => 'Aucun travail proposé pour l\'instant.',
			'tc.parcours.postCours.valider' => 'Valider',
			'tc.parcours.postCours.enFile' => 'Enregistré. Il partira dès le retour du réseau.',
			'tc.parcours.postCours.envoye' => 'Cours clôturé.',
			_ => null,
		};
	}
}
