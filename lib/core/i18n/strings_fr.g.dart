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
	late final Traductions$accessibilite$fr accessibilite = Traductions$accessibilite$fr.internal(_root);
	late final Traductions$accuse$fr accuse = Traductions$accuse$fr.internal(_root);
	late final Traductions$consentement$fr consentement = Traductions$consentement$fr.internal(_root);
	late final Traductions$kyc$fr kyc = Traductions$kyc$fr.internal(_root);
	late final Traductions$appareils$fr appareils = Traductions$appareils$fr.internal(_root);
	late final Traductions$enfant$fr enfant = Traductions$enfant$fr.internal(_root);
	late final Traductions$reglagesEnfant$fr reglagesEnfant = Traductions$reglagesEnfant$fr.internal(_root);
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
	late final Traductions$adulte$fr adulte = Traductions$adulte$fr.internal(_root);
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

	late final Traductions$commun$demonstration$fr demonstration = Traductions$commun$demonstration$fr.internal(_root);
	late final Traductions$commun$etape$fr etape = Traductions$commun$etape$fr.internal(_root);
	late final Traductions$commun$choix$fr choix = Traductions$commun$choix$fr.internal(_root);
	late final Traductions$commun$etats$fr etats = Traductions$commun$etats$fr.internal(_root);
	late final Traductions$commun$entete$fr entete = Traductions$commun$entete$fr.internal(_root);
	late final Traductions$commun$selecteurProfils$fr selecteurProfils = Traductions$commun$selecteurProfils$fr.internal(_root);
	late final Traductions$commun$theme$fr theme = Traductions$commun$theme$fr.internal(_root);
	late final Traductions$commun$demarrage$fr demarrage = Traductions$commun$demarrage$fr.internal(_root);
	late final Traductions$commun$dates$fr dates = Traductions$commun$dates$fr.internal(_root);
	late final Traductions$commun$sections$fr sections = Traductions$commun$sections$fr.internal(_root);
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

	/// fr: 'Annulée'
	String get seanceAnnulee => 'Annulée';

	/// fr: 'Annulée : {valeur}'
	String annuleeValeur({required Object valeur}) => 'Annulée : ${valeur}';

	/// fr: 'Motif non communiqué'
	String get motifNonCommunique => 'Motif non communiqué';

	/// fr: 'Aucun remplaçant trouvé'
	String get aucunRemplacantTrouve => 'Aucun remplaçant trouvé';

	/// fr: 'séance non facturée'
	String get seanceNonFacturee => 'séance non facturée';

	/// fr: '{raison} · {suite}'
	String raisonEtSuite({required Object raison, required Object suite}) => '${raison} · ${suite}';
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
	late final Traductions$salle$preparation$fr preparation = Traductions$salle$preparation$fr.internal(_root);

	/// fr: 'Cours enregistré, visite de contrôle possible.'
	String get bandeauPermanent => 'Cours enregistré, visite de contrôle possible.';

	late final Traductions$salle$secours$fr secours = Traductions$salle$secours$fr.internal(_root);
	late final Traductions$salle$seance$fr seance = Traductions$salle$seance$fr.internal(_root);
	late final Traductions$salle$fin$fr fin = Traductions$salle$fin$fr.internal(_root);

	/// fr: 'Micro'
	String get micro => 'Micro';

	/// fr: 'Micro coupé'
	String get microCoupe => 'Micro coupé';

	/// fr: 'Micro ouvert'
	String get microOuvert => 'Micro ouvert';

	/// fr: 'Caméra'
	String get camera => 'Caméra';

	/// fr: 'Caméra éteinte'
	String get cameraCoupee => 'Caméra éteinte';

	/// fr: 'Caméra allumée'
	String get cameraAllumee => 'Caméra allumée';

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

	late final Traductions$salle$visiteControle$fr visiteControle = Traductions$salle$visiteControle$fr.internal(_root);
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

	/// fr: 'Apprendre le Coran en classe, avec un enseignant attitré'
	String get accroche => 'Apprendre le Coran en classe, avec un enseignant attitré';

	/// fr: 'Des séances en visio, à horaire fixe, pour vous ou pour les élèves de votre foyer.'
	String get phrase => 'Des séances en visio, à horaire fixe, pour vous ou pour les élèves de votre foyer.';

	/// fr: 'Comment ça se passe'
	String get pointsTitre => 'Comment ça se passe';

	/// fr: 'Une classe stable'
	String get pointClasseTitre => 'Une classe stable';

	/// fr: 'Les mêmes camarades et le même horaire, chaque semaine.'
	String get pointClasse => 'Les mêmes camarades et le même horaire, chaque semaine.';

	/// fr: 'Un enseignant attitré'
	String get pointEnseignantTitre => 'Un enseignant attitré';

	/// fr: 'Un Sayyid ou une Sayyida qui suit chaque élève d'une séance à l'autre.'
	String get pointEnseignant => 'Un Sayyid ou une Sayyida qui suit chaque élève d\'une séance à l\'autre.';

	/// fr: 'Un seul compte pour le foyer'
	String get pointFoyerTitre => 'Un seul compte pour le foyer';

	/// fr: 'Les séances de chaque élève du foyer se suivent depuis votre compte.'
	String get pointFoyer => 'Les séances de chaque élève du foyer se suivent depuis votre compte.';

	/// fr: 'Commencer'
	String get commencer => 'Commencer';

	/// fr: 'J'ai déjà un compte'
	String get dejaCompte => 'J\'ai déjà un compte';
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

	/// fr: 'Nous vérifions votre dossier.'
	String get enVerification => 'Nous vérifions votre dossier.';

	/// fr: 'Dossier refusé'
	String get refuse => 'Dossier refusé';

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

	/// fr: 'Corriger'
	String get corriger => 'Corriger';

	/// fr: 'Ce dossier ne peut pas être modifié pour le moment.'
	String get correctionImpossible => 'Ce dossier ne peut pas être modifié pour le moment.';

	/// fr: 'Actualiser l'état du dossier'
	String get actualiser => 'Actualiser l\'état du dossier';

	/// fr: 'Vous pouvez joindre l'académie pour connaître la marche à suivre.'
	String get suspenduDetail => 'Vous pouvez joindre l\'académie pour connaître la marche à suivre.';

	/// fr: 'Se déconnecter'
	String get seDeconnecter => 'Se déconnecter';

	/// fr: 'Votre dossier'
	String get titreDossier => 'Votre dossier';

	/// fr: 'Votre compte'
	String get titreCompte => 'Votre compte';

	/// fr: 'Il vous reste nos conditions à lire et à accepter.'
	String get accordsARelire => 'Il vous reste nos conditions à lire et à accepter.';

	/// fr: 'Votre compte est créé'
	String get accesTitre => 'Votre compte est créé';

	/// fr: 'L'ouverture de votre compte n'est pas encore automatique.'
	String get accesEnPreparation => 'L\'ouverture de votre compte n\'est pas encore automatique.';

	/// fr: 'Vous n'avez aucun document à envoyer.'
	String get aucunDocument => 'Vous n\'avez aucun document à envoyer.';

	/// fr: 'L'académie peut l'ouvrir pour vous : joignez-la.'
	String get accesContact => 'L\'académie peut l\'ouvrir pour vous : joignez-la.';

	/// fr: 'Actualiser'
	String get actualiserCompte => 'Actualiser';

	/// fr: '(one) {Il reste un élément à fournir.} (other) {Il reste {n} éléments à fournir.}'
	String reste({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: 'Il reste un élément à fournir.',
		other: 'Il reste ${n} éléments à fournir.',
	);

	/// fr: 'À fournir'
	String get etatAFournir => 'À fournir';

	/// fr: 'Prochaine étape : {etape}'
	String prochaineEtape({required Object etape}) => 'Prochaine étape : ${etape}';

	/// fr: 'Pour relancer la vérification, commencez par cet élément : {element}.'
	String refuseDetail({required Object element}) => 'Pour relancer la vérification, commencez par cet élément : ${element}.';

	/// fr: 'Vous pouvez joindre l'académie pour connaître la marche à suivre.'
	String get refuseSansElement => 'Vous pouvez joindre l\'académie pour connaître la marche à suivre.';

	/// fr: 'L'état de votre dossier ne s'affiche pas pour le moment.'
	String get illisible => 'L\'état de votre dossier ne s\'affiche pas pour le moment.';

	/// fr: 'Vous êtes hors ligne. L'état de votre dossier s'affichera dès le retour du réseau.'
	String get horsLigne => 'Vous êtes hors ligne. L\'état de votre dossier s\'affichera dès le retour du réseau.';
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

	/// fr: 'Renvoyer le lien'
	String get renvoyer => 'Renvoyer le lien';

	/// fr: 'Un nouveau lien est parti à {courriel}. Utilisez celui du message le plus récent.'
	String renvoye({required Object courriel}) => 'Un nouveau lien est parti à ${courriel}. Utilisez celui du message le plus récent.';

	/// fr: 'Un lien vient déjà de partir. Attendez un moment avant d'en demander un autre.'
	String get erreurTropTot => 'Un lien vient déjà de partir. Attendez un moment avant d\'en demander un autre.';

	/// fr: 'Vous êtes hors ligne : le lien ne peut pas partir pour l'instant.'
	String get horsLigne => 'Vous êtes hors ligne : le lien ne peut pas partir pour l\'instant.';

	/// fr: 'Lien expiré ou jamais reçu ?'
	String get probleme => 'Lien expiré ou jamais reçu ?';

	/// fr: 'Découvrir Rewayah Academy'
	String get decouvrir => 'Découvrir Rewayah Academy';

	late final Traductions$connexion$recuperation$fr recuperation = Traductions$connexion$recuperation$fr.internal(_root);
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

	/// fr: '{n} sur {total}'
	String etapeCourte({required Object n, required Object total}) => '${n} sur ${total}';

	/// fr: 'Revenir à l'étape précédente'
	String get retourEtape => 'Revenir à l\'étape précédente';

	/// fr: 'Se déconnecter'
	String get seDeconnecter => 'Se déconnecter';

	/// fr: 'Modifier'
	String get modifier => 'Modifier';

	/// fr: 'Réessayer'
	String get reessayer => 'Réessayer';

	/// fr: 'Votre compte est créé, mais la connexion n'a pas pu être actualisée. Réessayez, ou déconnectez-vous puis reconnectez-vous.'
	String get erreurActualisation => 'Votre compte est créé, mais la connexion n\'a pas pu être actualisée. Réessayez, ou déconnectez-vous puis reconnectez-vous.';

	late final Traductions$inscription$usage$fr usage = Traductions$inscription$usage$fr.internal(_root);
	late final Traductions$inscription$recap$fr recap = Traductions$inscription$recap$fr.internal(_root);
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

	/// fr: 'Vous êtes hors ligne. Votre accord sera enregistré dès le retour du réseau, en appuyant de nouveau.'
	String get horsLigne => 'Vous êtes hors ligne. Votre accord sera enregistré dès le retour du réseau, en appuyant de nouveau.';

	/// fr: 'Cochez la case pour continuer.'
	String get caseRequise => 'Cochez la case pour continuer.';
}

// Path: accessibilite
class Traductions$accessibilite$fr {
	Traductions$accessibilite$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations
	late final Traductions$accessibilite$demo$fr demo = Traductions$accessibilite$demo$fr.internal(_root);
	late final Traductions$accessibilite$accueil$fr accueil = Traductions$accessibilite$accueil$fr.internal(_root);
	late final Traductions$accessibilite$coran$fr coran = Traductions$accessibilite$coran$fr.internal(_root);
	late final Traductions$accessibilite$maClasse$fr maClasse = Traductions$accessibilite$maClasse$fr.internal(_root);
	late final Traductions$accessibilite$tutoiement$fr tutoiement = Traductions$accessibilite$tutoiement$fr.internal(_root);
	late final Traductions$accessibilite$apres$fr apres = Traductions$accessibilite$apres$fr.internal(_root);
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

	late final Traductions$consentement$texte$fr texte = Traductions$consentement$texte$fr.internal(_root);
	late final Traductions$consentement$comment$fr comment = Traductions$consentement$comment$fr.internal(_root);
	late final Traductions$consentement$compte$fr compte = Traductions$consentement$compte$fr.internal(_root);
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

	late final Traductions$appareils$foyer$fr foyer = Traductions$appareils$foyer$fr.internal(_root);
	late final Traductions$appareils$eleve$fr eleve = Traductions$appareils$eleve$fr.internal(_root);
	late final Traductions$appareils$plateforme$fr plateforme = Traductions$appareils$plateforme$fr.internal(_root);
	late final Traductions$appareils$retrait$fr retrait = Traductions$appareils$retrait$fr.internal(_root);
	late final Traductions$appareils$emetteur$fr emetteur = Traductions$appareils$emetteur$fr.internal(_root);

	/// fr: 'Générer un nouveau code'
	String get regenerer => 'Générer un nouveau code';

	/// fr: 'Retirer'
	String get revoquer => 'Retirer';

	/// fr: 'Retirer cet appareil ? Il ne pourra plus se connecter tant que le tuteur ne l'aura pas reconnecté avec un nouveau code.'
	String get revoquerConfirmation => 'Retirer cet appareil ? Il ne pourra plus se connecter tant que le tuteur ne l\'aura pas reconnecté avec un nouveau code.';
}

// Path: enfant
class Traductions$enfant$fr {
	Traductions$enfant$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Ajouter un profil élève'
	String get titre => 'Ajouter un profil élève';

	/// fr: 'Aucun profil élève dans le foyer'
	String get aucun => 'Aucun profil élève dans le foyer';

	/// fr: 'Ajoutez d'abord un profil élève depuis le Foyer.'
	String get aucunDetail => 'Ajoutez d\'abord un profil élève depuis le Foyer.';
}

// Path: reglagesEnfant
class Traductions$reglagesEnfant$fr {
	Traductions$reglagesEnfant$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Réglages par profil élève'
	String get titre => 'Réglages par profil élève';

	/// fr: 'La photo, la caméra et l'interface de chaque élève se règlent dans sa fiche, depuis le Foyer. Les demandes à l'administration restent ici.'
	String get intro => 'La photo, la caméra et l\'interface de chaque élève se règlent dans sa fiche, depuis le Foyer. Les demandes à l\'administration restent ici.';

	/// fr: 'Photo, caméra et interface'
	String get renvoi => 'Photo, caméra et interface';

	/// fr: 'Dans la fiche de {prenom}'
	String renvoiLegende({required Object prenom}) => 'Dans la fiche de ${prenom}';
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

	/// fr: 'Les profils élèves de votre foyer'
	String get sousTitre => 'Les profils élèves de votre foyer';

	/// fr: 'Profils élèves'
	String get membres => 'Profils élèves';

	late final Traductions$foyer$vide$fr vide = Traductions$foyer$vide$fr.internal(_root);
	late final Traductions$foyer$membre$fr membre = Traductions$foyer$membre$fr.internal(_root);

	/// fr: 'La classe de chaque élève ne s'affiche pas encore sur cette page.'
	String get classesIndisponibles => 'La classe de chaque élève ne s\'affiche pas encore sur cette page.';

	/// fr: 'La classe de certains élèves n'a pas pu être lue.'
	String get classesEchec => 'La classe de certains élèves n\'a pas pu être lue.';

	/// fr: 'Relire les classes'
	String get relireClasses => 'Relire les classes';

	/// fr: 'L'inscription en cours de chaque élève ne s'affiche pas encore sur cette page.'
	String get inscriptionIllisible => 'L\'inscription en cours de chaque élève ne s\'affiche pas encore sur cette page.';

	/// fr: 'Appareils partagés'
	String get appareilsPartages => 'Appareils partagés';

	/// fr: 'Appareils du foyer'
	String get appareilsFoyer => 'Appareils du foyer';

	/// fr: 'Connecter un appareil, voir ceux qui sont reliés, en retirer un'
	String get appareilsFoyerLegende => 'Connecter un appareil, voir ceux qui sont reliés, en retirer un';

	/// fr: 'Créer mon profil élève'
	String get creerMonProfil => 'Créer mon profil élève';

	late final Traductions$foyer$monProfil$fr monProfil = Traductions$foyer$monProfil$fr.internal(_root);
	late final Traductions$foyer$ajout$fr ajout = Traductions$foyer$ajout$fr.internal(_root);
}

// Path: ficheEleve
class Traductions$ficheEleve$fr {
	Traductions$ficheEleve$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Profil élève'
	String get titreRepli => 'Profil élève';

	/// fr: 'Paramètres de l'élève'
	String get parametres => 'Paramètres de l\'élève';

	/// fr: 'Appareils'
	String get appareilsGroupe => 'Appareils';

	late final Traductions$ficheEleve$introuvable$fr introuvable = Traductions$ficheEleve$introuvable$fr.internal(_root);
	late final Traductions$ficheEleve$lignes$fr lignes = Traductions$ficheEleve$lignes$fr.internal(_root);
	late final Traductions$ficheEleve$informations$fr informations = Traductions$ficheEleve$informations$fr.internal(_root);
	late final Traductions$ficheEleve$inscription$fr inscription = Traductions$ficheEleve$inscription$fr.internal(_root);
	late final Traductions$ficheEleve$interface$fr interface = Traductions$ficheEleve$interface$fr.internal(_root);
	late final Traductions$ficheEleve$camera$fr camera = Traductions$ficheEleve$camera$fr.internal(_root);
	late final Traductions$ficheEleve$acces$fr acces = Traductions$ficheEleve$acces$fr.internal(_root);
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

	/// fr: 'Qui es-tu ?'
	String get choisirProfil => 'Qui es-tu ?';

	late final Traductions$eleveConnexion$profils$fr profils = Traductions$eleveConnexion$profils$fr.internal(_root);
	late final Traductions$eleveConnexion$pin$fr pin = Traductions$eleveConnexion$pin$fr.internal(_root);
	late final Traductions$eleveConnexion$saisie$fr saisie = Traductions$eleveConnexion$saisie$fr.internal(_root);
	late final Traductions$eleveConnexion$lecteur$fr lecteur = Traductions$eleveConnexion$lecteur$fr.internal(_root);
	late final Traductions$eleveConnexion$refus$fr refus = Traductions$eleveConnexion$refus$fr.internal(_root);
}

// Path: dossiers
class Traductions$dossiers$fr {
	Traductions$dossiers$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Dossiers à valider'
	String get titre => 'Dossiers à valider';

	/// fr: 'Examinez les dossiers prêts pour une décision.'
	String get sousTitre => 'Examinez les dossiers prêts pour une décision.';

	/// fr: 'Aucun dossier n'attend de validation.'
	String get aucun => 'Aucun dossier n\'attend de validation.';

	/// fr: 'Les nouveaux dossiers apparaîtront ici lorsqu'ils seront prêts.'
	String get aucunDetail => 'Les nouveaux dossiers apparaîtront ici lorsqu\'ils seront prêts.';

	late final Traductions$dossiers$file$fr file = Traductions$dossiers$file$fr.internal(_root);
	late final Traductions$dossiers$detail$fr detail = Traductions$dossiers$detail$fr.internal(_root);
	late final Traductions$dossiers$visionneuse$fr visionneuse = Traductions$dossiers$visionneuse$fr.internal(_root);
	late final Traductions$dossiers$revue$fr revue = Traductions$dossiers$revue$fr.internal(_root);

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

	/// fr: 'Refuser le dossier'
	String get refuser => 'Refuser le dossier';

	late final Traductions$dossiers$profilACompleter$fr profilACompleter = Traductions$dossiers$profilACompleter$fr.internal(_root);
	late final Traductions$dossiers$refus$fr refus = Traductions$dossiers$refus$fr.internal(_root);
	late final Traductions$dossiers$validation$fr validation = Traductions$dossiers$validation$fr.internal(_root);
	late final Traductions$dossiers$decision$fr decision = Traductions$dossiers$decision$fr.internal(_root);
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
	late final Traductions$admin$politiqueRevueKyc$fr politiqueRevueKyc = Traductions$admin$politiqueRevueKyc$fr.internal(_root);
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

	/// fr: 'Pour {prenom}'
	String pourPrenom({required Object prenom}) => 'Pour ${prenom}';

	/// fr: 'Retour à l'accueil'
	String get retourAccueil => 'Retour à l\'accueil';

	/// fr: 'Retour au Foyer'
	String get retourFoyer => 'Retour au Foyer';

	/// fr: 'Réessayer'
	String get reessayer => 'Réessayer';

	/// fr: 'Le questionnaire n'est pas encore disponible'
	String get indisponibleTitre => 'Le questionnaire n\'est pas encore disponible';

	/// fr: 'Cette étape n'est pas encore ouverte par l'académie. Vous n'avez rien à faire pour l'instant : rien n'est perdu, et vous pourrez la remplir dès qu'elle sera ouverte.'
	String get indisponibleDetail => 'Cette étape n\'est pas encore ouverte par l\'académie. Vous n\'avez rien à faire pour l\'instant : rien n\'est perdu, et vous pourrez la remplir dès qu\'elle sera ouverte.';

	/// fr: 'Pas de connexion'
	String get horsLigneTitre => 'Pas de connexion';

	/// fr: 'Vérifiez votre connexion, puis réessayez. Vos réponses sont gardées.'
	String get horsLigneDetail => 'Vérifiez votre connexion, puis réessayez. Vos réponses sont gardées.';

	/// fr: 'Le questionnaire n'a pas pu s'afficher'
	String get erreurChargement => 'Le questionnaire n\'a pas pu s\'afficher';

	/// fr: 'Une erreur est survenue de notre côté. Réessayez dans un instant ; vos réponses sont gardées.'
	String get erreurChargementDetail => 'Une erreur est survenue de notre côté. Réessayez dans un instant ; vos réponses sont gardées.';

	/// fr: 'Ce profil élève est introuvable'
	String get introuvableTitre => 'Ce profil élève est introuvable';

	/// fr: 'Il a peut-être été retiré du foyer. Revenez au Foyer pour choisir un profil élève.'
	String get introuvableDetail => 'Il a peut-être été retiré du foyer. Revenez au Foyer pour choisir un profil élève.';

	/// fr: 'Préférence enregistrée pour {prenom}'
	String finTitre({required Object prenom}) => 'Préférence enregistrée pour ${prenom}';

	/// fr: 'Cet horaire est noté comme votre préférence. Il ne réserve pas encore de place.'
	String get finDetail => 'Cet horaire est noté comme votre préférence. Il ne réserve pas encore de place.';

	/// fr: 'Une autre personne du foyer souhaite apprendre ?'
	String get finAjouterDetail => 'Une autre personne du foyer souhaite apprendre ?';

	/// fr: 'Ajouter un profil élève'
	String get finAjouterProfil => 'Ajouter un profil élève';

	/// fr: 'Quel âge a {prenom} ?'
	String ageQuestion({required Object prenom}) => 'Quel âge a ${prenom} ?';

	/// fr: 'L'âge décide de la durée des séances et du nombre d'élèves par classe. Nous ne demandons pas de date de naissance : une tranche suffit.'
	String get ageRaison => 'L\'âge décide de la durée des séances et du nombre d\'élèves par classe. Nous ne demandons pas de date de naissance : une tranche suffit.';

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

	/// fr: 'Ces horaires sont affichés à votre heure locale. Choisir un horaire enregistre votre préférence : cela ne réserve pas de place et ne constitue pas encore une classe.'
	String get offresRaison => 'Ces horaires sont affichés à votre heure locale. Choisir un horaire enregistre votre préférence : cela ne réserve pas de place et ne constitue pas encore une classe.';

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

	/// fr: 'Nous enregistrons que la demande existe. Cela ne crée pas de classe, ne cherche pas d'enseignant et ne promet aucun horaire futur.'
	String get refusEffet => 'Nous enregistrons que la demande existe. Cela ne crée pas de classe, ne cherche pas d\'enseignant et ne promet aucun horaire futur.';

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

	/// fr: 'L'horaire retenu pour {prenom} a été retiré avant qu'une classe soit constituée. Choisissez-en un autre : rien n'est perdu.'
	String etatOffreIndisponibleDetail({required Object prenom}) => 'L\'horaire retenu pour ${prenom} a été retiré avant qu\'une classe soit constituée. Choisissez-en un autre : rien n\'est perdu.';

	/// fr: 'Préférence enregistrée'
	String get etatDiagnosticRequis => 'Préférence enregistrée';

	/// fr: 'Il reste un échange avec un enseignant pour situer le niveau de {prenom}. L'académie vous proposera un rendez-vous.'
	String etatDiagnosticRequisDetail({required Object prenom}) => 'Il reste un échange avec un enseignant pour situer le niveau de ${prenom}. L\'académie vous proposera un rendez-vous.';

	/// fr: 'Rendez-vous prévu'
	String get etatDiagnosticEnAttente => 'Rendez-vous prévu';

	/// fr: 'Un échange est prévu pour situer le niveau de {prenom}.'
	String etatDiagnosticEnAttenteDetail({required Object prenom}) => 'Un échange est prévu pour situer le niveau de ${prenom}.';

	/// fr: 'Classe en cours de constitution'
	String get etatClasseEnFormation => 'Classe en cours de constitution';

	/// fr: 'Une classe démarre à partir de {minimum} élèves. Nous vous préviendrons dès qu'elle est confirmée.'
	String etatClasseEnFormationDetail({required Object minimum}) => 'Une classe démarre à partir de ${minimum} élèves. Nous vous préviendrons dès qu\'elle est confirmée.';

	/// fr: 'Une classe démarre à partir d'un certain nombre d'élèves. Nous vous préviendrons dès qu'elle est confirmée.'
	String get etatClasseEnFormationDetailSansMinimum => 'Une classe démarre à partir d\'un certain nombre d\'élèves. Nous vous préviendrons dès qu\'elle est confirmée.';

	/// fr: 'Classe confirmée'
	String get etatClasseConfirmee => 'Classe confirmée';

	/// fr: 'La classe de {prenom} est constituée. Vous retrouverez ses séances dans son espace.'
	String etatClasseConfirmeeDetail({required Object prenom}) => 'La classe de ${prenom} est constituée. Vous retrouverez ses séances dans son espace.';

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

	/// fr: 'Gérer mon foyer'
	String get profils => 'Gérer mon foyer';

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

	/// fr: 'Pour revenir à votre espace principal, quittez d'abord la mission en cours.'
	String get espacesMissionEnCours => 'Pour revenir à votre espace principal, quittez d\'abord la mission en cours.';

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

	/// fr: 'Choisissez l'apparence de l'application. Le changement est immédiat et reste sur cet appareil. Vous pouvez le modifier à tout moment.'
	String get themeContexte => 'Choisissez l\'apparence de l\'application. Le changement est immédiat et reste sur cet appareil. Vous pouvez le modifier à tout moment.';

	/// fr: 'Système'
	String get themeSysteme => 'Système';

	/// fr: 'Suit le réglage de votre appareil'
	String get themeSystemeDetail => 'Suit le réglage de votre appareil';

	/// fr: 'Clair'
	String get themeClair => 'Clair';

	/// fr: 'Fond clair, quel que soit le réglage de votre appareil'
	String get themeClairDetail => 'Fond clair, quel que soit le réglage de votre appareil';

	/// fr: 'Sombre'
	String get themeSombre => 'Sombre';

	/// fr: 'Fond sombre, quel que soit le réglage de votre appareil'
	String get themeSombreDetail => 'Fond sombre, quel que soit le réglage de votre appareil';

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
	late final Traductions$compte$tuteur$fr tuteur = Traductions$compte$tuteur$fr.internal(_root);
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
	List<String> get moisCourts => [
		'janv.',
		'févr.',
		'mars',
		'avr.',
		'mai',
		'juin',
		'juil.',
		'août',
		'sept.',
		'oct.',
		'nov.',
		'déc.',
	];

	/// fr: '{jour} {mois} {annee}'
	String dateCourte({required Object jour, required Object mois, required Object annee}) => '${jour} ${mois} ${annee}';

	/// fr: '{jourSemaine} {jour} {mois} {annee}'
	String dateLongue({required Object jourSemaine, required Object jour, required Object mois, required Object annee}) => '${jourSemaine} ${jour} ${mois} ${annee}';

	/// fr: '{debut} - {fin}'
	String plage({required Object debut, required Object fin}) => '${debut} - ${fin}';

	late final Traductions$historique$duree$fr duree = Traductions$historique$duree$fr.internal(_root);

	/// fr: 'Heures affichées à l'heure de cet appareil.'
	String get fuseauListe => 'Heures affichées à l\'heure de cet appareil.';

	/// fr: 'Heures affichées à l'heure de cet appareil (UTC{decalage}).'
	String fuseauDetail({required Object decalage}) => 'Heures affichées à l\'heure de cet appareil (UTC${decalage}).';

	/// fr: 'Classe non disponible'
	String get classeInconnue => 'Classe non disponible';

	late final Traductions$historique$selecteur$fr selecteur = Traductions$historique$selecteur$fr.internal(_root);
	late final Traductions$historique$filtres$fr filtres = Traductions$historique$filtres$fr.internal(_root);

	/// fr: 'Retour à l'historique'
	String get retour => 'Retour à l\'historique';

	late final Traductions$historique$etat$fr etat = Traductions$historique$etat$fr.internal(_root);

	/// fr: 'La présence n'a pas pu être lue : les états restent inconnus pour le moment.'
	String get presenceIllisible => 'La présence n\'a pas pu être lue : les états restent inconnus pour le moment.';

	late final Traductions$historique$seances$fr seances = Traductions$historique$seances$fr.internal(_root);
	late final Traductions$historique$observations$fr observations = Traductions$historique$observations$fr.internal(_root);
	late final Traductions$historique$seance$fr seance = Traductions$historique$seance$fr.internal(_root);
	late final Traductions$historique$observation$fr observation = Traductions$historique$observation$fr.internal(_root);
}

// Path: notifications
class Traductions$notifications$fr {
	Traductions$notifications$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Notifications'
	String get titre => 'Notifications';

	/// fr: 'Les notifications ne sont pas encore disponibles'
	String get indisponibleTitre => 'Les notifications ne sont pas encore disponibles';

	/// fr: 'Les rappels de séance et les messages de l'académie s'afficheront ici dès qu'ils seront ouverts.'
	String get indisponiblePhrase => 'Les rappels de séance et les messages de l\'académie s\'afficheront ici dès qu\'ils seront ouverts.';

	/// fr: 'Aucune notification'
	String get videTitre => 'Aucune notification';

	/// fr: 'Les rappels de séance et les messages de l'académie s'afficheront ici.'
	String get videPhrase => 'Les rappels de séance et les messages de l\'académie s\'afficheront ici.';

	/// fr: '{titre}, le {date} à {heure}'
	String ligne({required Object titre, required Object date, required Object heure}) => '${titre}, le ${date} à ${heure}';
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
}

// Path: classe
class Traductions$classe$fr {
	Traductions$classe$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations
	late final Traductions$classe$entree$fr entree = Traductions$classe$entree$fr.internal(_root);

	/// fr: 'Choisir une classe'
	String get catalogue => 'Choisir une classe';

	/// fr: 'Planning'
	String get planning => 'Planning';

	/// fr: 'Avant le prochain cours'
	String get travail => 'Avant le prochain cours';

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
	late final Traductions$classe$pageCatalogue$fr pageCatalogue = Traductions$classe$pageCatalogue$fr.internal(_root);
}

// Path: enseignant
class Traductions$enseignant$fr {
	Traductions$enseignant$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations
	late final Traductions$enseignant$classes$fr classes = Traductions$enseignant$classes$fr.internal(_root);
	late final Traductions$enseignant$eleve$fr eleve = Traductions$enseignant$eleve$fr.internal(_root);
	late final Traductions$enseignant$signalement$fr signalement = Traductions$enseignant$signalement$fr.internal(_root);
	late final Traductions$enseignant$demo$fr demo = Traductions$enseignant$demo$fr.internal(_root);
	late final Traductions$enseignant$bienvenue$fr bienvenue = Traductions$enseignant$bienvenue$fr.internal(_root);
	late final Traductions$enseignant$photo$fr photo = Traductions$enseignant$photo$fr.internal(_root);
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
	late final Traductions$controleur$historique$fr historique = Traductions$controleur$historique$fr.internal(_root);
	late final Traductions$controleur$compteRendu$fr compteRendu = Traductions$controleur$compteRendu$fr.internal(_root);
	late final Traductions$controleur$observation$fr observation = Traductions$controleur$observation$fr.internal(_root);
	late final Traductions$controleur$echanges$fr echanges = Traductions$controleur$echanges$fr.internal(_root);
	late final Traductions$controleur$demo$fr demo = Traductions$controleur$demo$fr.internal(_root);
	late final Traductions$controleur$acces$fr acces = Traductions$controleur$acces$fr.internal(_root);
	late final Traductions$controleur$controle$fr controle = Traductions$controleur$controle$fr.internal(_root);
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

// Path: adulte
class Traductions$adulte$fr {
	Traductions$adulte$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations
	late final Traductions$adulte$nav$fr nav = Traductions$adulte$nav$fr.internal(_root);
	late final Traductions$adulte$accueil$fr accueil = Traductions$adulte$accueil$fr.internal(_root);
	late final Traductions$adulte$maClasse$fr maClasse = Traductions$adulte$maClasse$fr.internal(_root);
	late final Traductions$adulte$monEspace$fr monEspace = Traductions$adulte$monEspace$fr.internal(_root);
	late final Traductions$adulte$provisoire$fr provisoire = Traductions$adulte$provisoire$fr.internal(_root);
	late final Traductions$adulte$famille$fr famille = Traductions$adulte$famille$fr.internal(_root);
	late final Traductions$adulte$invitation$fr invitation = Traductions$adulte$invitation$fr.internal(_root);
	late final Traductions$adulte$demo$fr demo = Traductions$adulte$demo$fr.internal(_root);
}

// Path: commun.demonstration
class Traductions$commun$demonstration$fr {
	Traductions$commun$demonstration$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Démonstration'
	String get repere => 'Démonstration';

	/// fr: 'Mode Démonstration'
	String get repereLu => 'Mode Démonstration';
}

// Path: commun.etape
class Traductions$commun$etape$fr {
	Traductions$commun$etape$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: '{n} sur {total}'
	String sur({required Object n, required Object total}) => '${n} sur ${total}';

	/// fr: 'Étape {n} sur {total}'
	String surLue({required Object n, required Object total}) => 'Étape ${n} sur ${total}';
}

// Path: commun.choix
class Traductions$commun$choix$fr {
	Traductions$commun$choix$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Indisponible'
	String get indisponible => 'Indisponible';
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

// Path: commun.sections
class Traductions$commun$sections$fr {
	Traductions$commun$sections$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Sections de la page'
	String get page => 'Sections de la page';
}

// Path: salle.preparation
class Traductions$salle$preparation$fr {
	Traductions$salle$preparation$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Préparer l'entrée dans la classe'
	String get titre => 'Préparer l\'entrée dans la classe';

	/// fr: 'Retour à la Classe'
	String get retour => 'Retour à la Classe';

	/// fr: 'Caméra coupée'
	String get cameraCoupee => 'Caméra coupée';

	/// fr: 'Tester la caméra'
	String get testerCamera => 'Tester la caméra';

	/// fr: 'Test local terminé. La caméra reste coupée à l'entrée.'
	String get testCameraFait => 'Test local terminé. La caméra reste coupée à l\'entrée.';

	/// fr: 'Votre équipement'
	String get equipement => 'Votre équipement';

	/// fr: 'Connexion'
	String get connexion => 'Connexion';

	/// fr: 'Micro'
	String get micro => 'Micro';

	/// fr: 'Sortie audio'
	String get sortieAudio => 'Sortie audio';

	/// fr: 'Caméra'
	String get camera => 'Caméra';

	/// fr: 'Vérification…'
	String get verification => 'Vérification…';

	/// fr: 'Vérification du matériel…'
	String get chargement => 'Vérification du matériel…';

	/// fr: 'Connexion prête'
	String get connexionPrete => 'Connexion prête';

	/// fr: 'Connexion instable'
	String get connexionInstable => 'Connexion instable';

	/// fr: 'Connexion instable. L'audio sera prioritaire.'
	String get reseauFaible => 'Connexion instable. L\'audio sera prioritaire.';

	/// fr: 'Micro détecté · Micro coupé à l'entrée'
	String get microPret => 'Micro détecté · Micro coupé à l\'entrée';

	/// fr: 'Aucun micro détecté'
	String get microAbsent => 'Aucun micro détecté';

	/// fr: 'Aucun micro détecté. Connectez ou activez un micro pour enseigner.'
	String get microAbsentRaison => 'Aucun micro détecté. Connectez ou activez un micro pour enseigner.';

	/// fr: 'Micro bloqué'
	String get microBloque => 'Micro bloqué';

	/// fr: 'Le micro est bloqué dans les réglages de cet appareil.'
	String get permissionRefusee => 'Le micro est bloqué dans les réglages de cet appareil.';

	/// fr: 'Ouvrir les réglages'
	String get ouvrirReglages => 'Ouvrir les réglages';

	/// fr: 'Réessayer'
	String get reessayer => 'Réessayer';

	/// fr: 'Sortie système'
	String get sortieSysteme => 'Sortie système';

	/// fr: 'Caméra détectée · Caméra coupée à l'entrée'
	String get cameraPrete => 'Caméra détectée · Caméra coupée à l\'entrée';

	/// fr: 'Caméra non disponible. Vous pouvez entrer sans caméra.'
	String get cameraAbsente => 'Caméra non disponible. Vous pouvez entrer sans caméra.';

	/// fr: 'Modifier les périphériques'
	String get modifierPeripheriques => 'Modifier les périphériques';

	/// fr: 'Contexte de la séance'
	String get contexte => 'Contexte de la séance';

	/// fr: 'Classe'
	String get classe => 'Classe';

	/// fr: 'Début'
	String get debut => 'Début';

	/// fr: 'Support prévu'
	String get support => 'Support prévu';

	/// fr: 'Reprise'
	String get reprise => 'Reprise';

	/// fr: 'Élèves attendus'
	String get eleves => 'Élèves attendus';

	/// fr: 'Entrer dans la classe'
	String get entrer => 'Entrer dans la classe';

	/// fr: 'Cette séance est terminée.'
	String get terminee => 'Cette séance est terminée.';

	/// fr: 'Cette séance ne vous est pas attribuée.'
	String get nonAssignee => 'Cette séance ne vous est pas attribuée.';

	/// fr: 'Retour à ma journée'
	String get retourJournee => 'Retour à ma journée';

	late final Traductions$salle$preparation$demo$fr demo = Traductions$salle$preparation$demo$fr.internal(_root);
	late final Traductions$salle$preparation$eleve$fr eleve = Traductions$salle$preparation$eleve$fr.internal(_root);
}

// Path: salle.secours
class Traductions$salle$secours$fr {
	Traductions$salle$secours$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Réseau faible. L'audio est prioritaire.'
	String get reseauFaible => 'Réseau faible. L\'audio est prioritaire.';

	/// fr: 'Le réseau est faible.'
	String get reseauFaibleGuidee => 'Le réseau est faible.';

	/// fr: 'Le son reste prioritaire.'
	String get reseauFaibleGuideeSuite => 'Le son reste prioritaire.';

	/// fr: 'Connexion interrompue. Reconnexion en cours…'
	String get reconnexion => 'Connexion interrompue. Reconnexion en cours…';

	/// fr: 'Reconnexion de la séance…'
	String get reconnexionGuidee => 'Reconnexion de la séance…';

	/// fr: 'Connexion rétablie.'
	String get retablie => 'Connexion rétablie.';

	/// fr: 'Impossible de rétablir la connexion.'
	String get echec => 'Impossible de rétablir la connexion.';

	/// fr: 'La connexion ne revient pas.'
	String get echecGuidee => 'La connexion ne revient pas.';

	/// fr: 'Vous êtes hors ligne. La séance nécessite une connexion.'
	String get horsLigne => 'Vous êtes hors ligne. La séance nécessite une connexion.';

	/// fr: 'Réessayer'
	String get reessayer => 'Réessayer';

	/// fr: 'Quitter'
	String get quitter => 'Quitter';

	/// fr: '{commande}. Indisponible pendant la reconnexion.'
	String indisponible({required Object commande}) => '${commande}. Indisponible pendant la reconnexion.';

	/// fr: 'Caméra désactivée pour ce profil.'
	String get cameraInterdite => 'Caméra désactivée pour ce profil.';

	/// fr: 'Le micro est bloqué dans les réglages de cet appareil.'
	String get microBloque => 'Le micro est bloqué dans les réglages de cet appareil.';

	/// fr: 'Le micro est bloqué sur cet appareil.'
	String get microBloqueGuidee => 'Le micro est bloqué sur cet appareil.';

	/// fr: 'Continuer sans micro'
	String get continuerSansMicro => 'Continuer sans micro';

	/// fr: 'Ouvrir les réglages'
	String get ouvrirReglages => 'Ouvrir les réglages';
}

// Path: salle.seance
class Traductions$salle$seance$fr {
	Traductions$salle$seance$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Séance en direct'
	String get titre => 'Séance en direct';

	/// fr: 'Ma séance'
	String get titreGuidee => 'Ma séance';

	/// fr: '{debut} · {fin}'
	String ligne({required Object debut, required Object fin}) => '${debut} · ${fin}';

	/// fr: '{minutes} min restantes'
	String minutesRestantes({required Object minutes}) => '${minutes} min restantes';

	/// fr: 'La séance se poursuit.'
	String get sePoursuit => 'La séance se poursuit.';

	/// fr: 'En ligne'
	String get enLigne => 'En ligne';

	/// fr: 'Reconnexion'
	String get reconnexion => 'Reconnexion';

	/// fr: 'Le cours est enregistré.'
	String get coursEnregistreCourt => 'Le cours est enregistré.';

	/// fr: 'Votre parent observe la séance.'
	String get votreParentObserve => 'Votre parent observe la séance.';

	/// fr: 'Ton parent observe la séance.'
	String get tonParentObserve => 'Ton parent observe la séance.';

	/// fr: 'Tuteur de {prenom} observe.'
	String tuteurDeObserve({required Object prenom}) => 'Tuteur de ${prenom} observe.';

	/// fr: 'Un parent observe cette séance'
	String get unParentObserve => 'Un parent observe cette séance';

	/// fr: 'Le tuteur de {prenom} observe la séance.'
	String leTuteurDeObserve({required Object prenom}) => 'Le tuteur de ${prenom} observe la séance.';

	/// fr: '{mention} {notice}'
	String mentionEtNotice({required Object mention, required Object notice}) => '${mention} ${notice}';

	/// fr: 'Retour'
	String get retour => 'Retour';

	/// fr: 'Notifications'
	String get notifications => 'Notifications';

	/// fr: 'Réglages'
	String get reglages => 'Réglages';

	/// fr: 'Compte de {nom}'
	String compteDe({required Object nom}) => 'Compte de ${nom}';

	/// fr: 'Quitter la séance'
	String get sortir => 'Quitter la séance';

	/// fr: 'Élèves {connectes}/{inscrits}'
	String compteurEleves({required Object connectes, required Object inscrits}) => 'Élèves ${connectes}/${inscrits}';

	/// fr: 'Parler'
	String get parler => 'Parler';

	/// fr: 'Agrandir'
	String get agrandir => 'Agrandir';

	/// fr: 'Réduire'
	String get reduire => 'Réduire';

	/// fr: '{nom} n'a rien partagé pour l'instant.'
	String rienPartage({required Object nom}) => '${nom} n\'a rien partagé pour l\'instant.';

	/// fr: 'Vidéo de {nom}'
	String videoDe({required Object nom}) => 'Vidéo de ${nom}';

	/// fr: '{page} / {pages}'
	String page({required Object page, required Object pages}) => '${page} / ${pages}';

	/// fr: 'Page {page} sur {pages}'
	String pageSemantique({required Object page, required Object pages}) => 'Page ${page} sur ${pages}';

	/// fr: 'Zoom local, sans effet sur les autres'
	String get zoomLocal => 'Zoom local, sans effet sur les autres';

	/// fr: '{valeur} %'
	String zoomValeur({required Object valeur}) => '${valeur} %';

	/// fr: 'Réduire le zoom'
	String get zoomMoins => 'Réduire le zoom';

	/// fr: 'Augmenter le zoom'
	String get zoomPlus => 'Augmenter le zoom';

	/// fr: 'Quitter la séance ?'
	String get quitterQuestion => 'Quitter la séance ?';

	/// fr: 'Vous pourrez revenir si la séance est encore ouverte.'
	String get quitterConsequence => 'Vous pourrez revenir si la séance est encore ouverte.';

	/// fr: 'Illustration du support'
	String get illustration => 'Illustration du support';

	/// fr: 'Vous passerez ensuite au cahier de transmission.'
	String get quitterCahierConsequence => 'Vous passerez ensuite au cahier de transmission.';

	/// fr: 'Quitter et ouvrir le cahier'
	String get quitterCahier => 'Quitter et ouvrir le cahier';

	/// fr: 'Rester'
	String get rester => 'Rester';

	/// fr: 'Supports'
	String get supports => 'Supports';

	/// fr: 'Réseau'
	String get reseau => 'Réseau';

	/// fr: 'Page précédente'
	String get pagePrecedente => 'Page précédente';

	/// fr: 'Page suivante'
	String get pageSuivante => 'Page suivante';

	late final Traductions$salle$seance$outils$fr outils = Traductions$salle$seance$outils$fr.internal(_root);
	late final Traductions$salle$seance$rail$fr rail = Traductions$salle$seance$rail$fr.internal(_root);

	/// fr: 'Fermer le panneau'
	String get fermerPanneau => 'Fermer le panneau';

	late final Traductions$salle$seance$panneauSupports$fr panneauSupports = Traductions$salle$seance$panneauSupports$fr.internal(_root);

	/// fr: 'Élèves'
	String get eleves => 'Élèves';

	/// fr: 'Appeler discrètement'
	String get rappeler => 'Appeler discrètement';

	/// fr: 'Faire réciter'
	String get faireReciter => 'Faire réciter';

	/// fr: 'File de récitation'
	String get fileRecitation => 'File de récitation';

	/// fr: 'À suivre'
	String get aSuivre => 'À suivre';

	/// fr: '{nom} vous appelle'
	String vousAppelle({required Object nom}) => '${nom} vous appelle';

	/// fr: 'Signaler un besoin'
	String get signalerBesoin => 'Signaler un besoin';

	/// fr: 'Afficher la fiche de {prenom}'
	String deplierFiche({required Object prenom}) => 'Afficher la fiche de ${prenom}';

	/// fr: 'Masquer la fiche de {prenom}'
	String replierFiche({required Object prenom}) => 'Masquer la fiche de ${prenom}';

	late final Traductions$salle$seance$fiche$fr fiche = Traductions$salle$seance$fiche$fr.internal(_root);

	/// fr: 'Options du panneau {titre}'
	String optionsPanneau({required Object titre}) => 'Options du panneau ${titre}';

	late final Traductions$salle$seance$demo$fr demo = Traductions$salle$seance$demo$fr.internal(_root);
	late final Traductions$salle$seance$statut$fr statut = Traductions$salle$seance$statut$fr.internal(_root);
}

// Path: salle.fin
class Traductions$salle$fin$fr {
	Traductions$salle$fin$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Séance terminée'
	String get titre => 'Séance terminée';

	/// fr: 'Vous pouvez retrouver votre travail dans votre Classe.'
	String get phrase => 'Vous pouvez retrouver votre travail dans votre Classe.';

	/// fr: 'Retour à la Classe'
	String get retourClasse => 'Retour à la Classe';

	/// fr: 'Vous avez quitté la séance.'
	String get quitteTitre => 'Vous avez quitté la séance.';

	/// fr: 'Vous pourrez revenir tant qu'elle reste ouverte.'
	String get quittePhrase => 'Vous pourrez revenir tant qu\'elle reste ouverte.';

	/// fr: 'Votre accès à cette séance a pris fin.'
	String get accesRetireTitre => 'Votre accès à cette séance a pris fin.';

	/// fr: 'La séance est terminée.'
	String get titreGuidee => 'La séance est terminée.';

	/// fr: 'Retour à l'accueil'
	String get retourAccueil => 'Retour à l\'accueil';

	late final Traductions$salle$fin$enseignant$fr enseignant = Traductions$salle$fin$enseignant$fr.internal(_root);
}

// Path: salle.visiteControle
class Traductions$salle$visiteControle$fr {
	Traductions$salle$visiteControle$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Contrôle Rewayah'
	String get titre => 'Contrôle Rewayah';

	/// fr: 'Son reçu'
	String get sonRecu => 'Son reçu';

	/// fr: 'Son coupé'
	String get sonCoupe => 'Son coupé';

	/// fr: 'Couper le son reçu'
	String get couperSon => 'Couper le son reçu';

	/// fr: 'Rétablir le son reçu'
	String get retablirSon => 'Rétablir le son reçu';

	/// fr: 'Agrandir le support'
	String get agrandir => 'Agrandir le support';

	/// fr: 'Réduire le support'
	String get reduire => 'Réduire le support';
}

// Path: connexion.recuperation
class Traductions$connexion$recuperation$fr {
	Traductions$connexion$recuperation$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Retrouver mon accès'
	String get titre => 'Retrouver mon accès';

	/// fr: 'Il n'y a pas de mot de passe à réinitialiser : indiquez votre adresse, nous vous envoyons un nouveau lien de connexion.'
	String get intro => 'Il n\'y a pas de mot de passe à réinitialiser : indiquez votre adresse, nous vous envoyons un nouveau lien de connexion.';

	/// fr: 'Ce lien n'est plus valable'
	String get lienExpireTitre => 'Ce lien n\'est plus valable';

	/// fr: 'Un lien de connexion ne sert qu'une fois et expire au bout d'un moment. Demandez-en un nouveau ci-dessous.'
	String get lienExpire => 'Un lien de connexion ne sert qu\'une fois et expire au bout d\'un moment. Demandez-en un nouveau ci-dessous.';

	/// fr: 'La connexion n'a pas abouti'
	String get lienRefuseTitre => 'La connexion n\'a pas abouti';

	/// fr: 'Ce lien n'a pas pu vous connecter. Demandez-en un nouveau ci-dessous.'
	String get lienRefuse => 'Ce lien n\'a pas pu vous connecter. Demandez-en un nouveau ci-dessous.';

	/// fr: 'Recevoir un nouveau lien'
	String get envoyer => 'Recevoir un nouveau lien';

	/// fr: 'Nouveau lien envoyé'
	String get envoyeTitre => 'Nouveau lien envoyé';

	/// fr: 'Ouvrez le message envoyé à {courriel}, puis suivez le lien.'
	String envoye({required Object courriel}) => 'Ouvrez le message envoyé à ${courriel}, puis suivez le lien.';

	/// fr: 'Le message peut mettre quelques minutes à arriver. Pensez à regarder dans les courriers indésirables.'
	String get envoyeEncart => 'Le message peut mettre quelques minutes à arriver. Pensez à regarder dans les courriers indésirables.';

	/// fr: 'Utiliser une autre adresse'
	String get autreAdresse => 'Utiliser une autre adresse';

	/// fr: 'Revenir à la connexion'
	String get revenirConnexion => 'Revenir à la connexion';
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

	/// fr: 'Sur votre propre appareil, ouvrez Foyer, puis Appareils du foyer.'
	String get etape1 => 'Sur votre propre appareil, ouvrez Foyer, puis Appareils du foyer.';

	/// fr: 'Touchez le profil de l'élève, puis Connecter un appareil.'
	String get etape2 => 'Touchez le profil de l\'élève, puis Connecter un appareil.';

	/// fr: 'Un QR code et un code de six caractères s'affichent, avec leur heure de fin.'
	String get etape3 => 'Un QR code et un code de six caractères s\'affichent, avec leur heure de fin.';

	/// fr: 'Sur l'appareil de l'élève, scannez le QR code ou saisissez le code.'
	String get etape4 => 'Sur l\'appareil de l\'élève, scannez le QR code ou saisissez le code.';

	/// fr: 'Le nombre d'appareils par élève est limité. Si la limite est atteinte, retirez-en un depuis Foyer, Appareils du foyer.'
	String get plafond => 'Le nombre d\'appareils par élève est limité. Si la limite est atteinte, retirez-en un depuis Foyer, Appareils du foyer.';

	/// fr: 'Saisir le code'
	String get saisir => 'Saisir le code';

	/// fr: 'Fermer'
	String get fermer => 'Fermer';
}

// Path: inscription.usage
class Traductions$inscription$usage$fr {
	Traductions$inscription$usage$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Quel type de compte souhaitez-vous créer ?'
	String get question => 'Quel type de compte souhaitez-vous créer ?';

	/// fr: 'Moi uniquement'
	String get moiTitre => 'Moi uniquement';

	/// fr: 'Je souhaite suivre les cours avec mon propre profil élève.'
	String get moiDescription => 'Je souhaite suivre les cours avec mon propre profil élève.';

	/// fr: 'Moi et ma famille'
	String get familleTitre => 'Moi et ma famille';

	/// fr: 'Inscrivez vos enfants ou vos proches, avec ou sans vous. Vous pourrez créer votre propre profil élève à tout moment.'
	String get familleDescription => 'Inscrivez vos enfants ou vos proches, avec ou sans vous. Vous pourrez créer votre propre profil élève à tout moment.';

	/// fr: 'Je suis enseignant'
	String get enseignant => 'Je suis enseignant';
}

// Path: inscription.recap
class Traductions$inscription$recap$fr {
	Traductions$inscription$recap$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Type de compte'
	String get usage => 'Type de compte';

	/// fr: 'Nom'
	String get identite => 'Nom';

	/// fr: 'Genre'
	String get genre => 'Genre';

	/// fr: 'Enseignant'
	String get enseignant => 'Enseignant';
}

// Path: accessibilite.demo
class Traductions$accessibilite$demo$fr {
	Traductions$accessibilite$demo$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Démonstration du Mode Accessibilité'
	String get titre => 'Démonstration du Mode Accessibilité';

	/// fr: 'Données fictives, aucun envoi.'
	String get mention => 'Données fictives, aucun envoi.';

	/// fr: 'Choisissez un élève et un moment de la séance.'
	String get intro => 'Choisissez un élève et un moment de la séance.';

	/// fr: 'Mariam, élève mineure'
	String get eleveMineure => 'Mariam, élève mineure';

	/// fr: 'Idriss, élève adulte'
	String get eleveAdulte => 'Idriss, élève adulte';

	/// fr: 'Avant la séance'
	String get etatAvant => 'Avant la séance';

	/// fr: 'Juste avant la séance, l'entrée est ouverte'
	String get etatFenetre => 'Juste avant la séance, l\'entrée est ouverte';

	/// fr: 'Pendant la séance'
	String get etatPendant => 'Pendant la séance';

	/// fr: 'Après la séance'
	String get etatApres => 'Après la séance';
}

// Path: accessibilite.accueil
class Traductions$accessibilite$accueil$fr {
	Traductions$accessibilite$accueil$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'As-salāmu ’alaykum, {prenom}.'
	String salutation({required Object prenom}) => 'As-salāmu ’alaykum, ${prenom}.';

	/// fr: 'Prochaine séance'
	String get prochaineSeance => 'Prochaine séance';

	/// fr: 'avec {nomme}'
	String avec({required Object nomme}) => 'avec ${nomme}';

	/// fr: 'Voir ma classe'
	String get voirMaClasse => 'Voir ma classe';

	/// fr: 'Lire le Coran'
	String get lireCoran => 'Lire le Coran';

	/// fr: 'Accéder au Mushaf'
	String get lireCoranDetail => 'Accéder au Mushaf';

	/// fr: 'Besoin d'aide ?'
	String get aide => 'Besoin d\'aide ?';
}

// Path: accessibilite.coran
class Traductions$accessibilite$coran$fr {
	Traductions$accessibilite$coran$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Ouvrir le Coran'
	String get ouvrir => 'Ouvrir le Coran';

	/// fr: 'Reprendre là où tu t'es arrêté(e)'
	String get reprendre => 'Reprendre là où tu t\'es arrêté(e)';

	/// fr: 'Reprendre là où vous vous êtes arrêté(e)'
	String get reprendreVous => 'Reprendre là où vous vous êtes arrêté(e)';

	/// fr: 'Tu en étais page {page}.'
	String reprendreDetail({required Object page}) => 'Tu en étais page ${page}.';

	/// fr: 'Vous en étiez page {page}.'
	String reprendreDetailVous({required Object page}) => 'Vous en étiez page ${page}.';

	/// fr: 'Le Coran s'ouvre en lecture agrandie, verset par verset.'
	String get lectureGrande => 'Le Coran s\'ouvre en lecture agrandie, verset par verset.';

	/// fr: 'Retour à l'entrée du Coran'
	String get retour => 'Retour à l\'entrée du Coran';
}

// Path: accessibilite.maClasse
class Traductions$accessibilite$maClasse$fr {
	Traductions$accessibilite$maClasse$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Ma classe'
	String get titre => 'Ma classe';

	/// fr: 'Mon suivi'
	String get suivi => 'Mon suivi';

	/// fr: 'Les séances passées et la présence'
	String get suiviDetail => 'Les séances passées et la présence';
}

// Path: accessibilite.tutoiement
class Traductions$accessibilite$tutoiement$fr {
	Traductions$accessibilite$tutoiement$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Ton heure'
	String get tonHeure => 'Ton heure';

	/// fr: 'Ce temps d'attente ne compte pas dans ta présence.'
	String get attenteDetail => 'Ce temps d\'attente ne compte pas dans ta présence.';

	/// fr: 'Tu es dans la salle. La séance commence dans {duree}.'
	String attente({required Object duree}) => 'Tu es dans la salle. La séance commence dans ${duree}.';

	/// fr: 'Tu es dans la salle. La séance commence dans moins d'une minute.'
	String get attenteImminent => 'Tu es dans la salle. La séance commence dans moins d\'une minute.';

	/// fr: 'Tu es dans la salle'
	String get annonceAttente => 'Tu es dans la salle';

	/// fr: 'Tu es hors ligne. La séance nécessite une connexion.'
	String get horsLigne => 'Tu es hors ligne. La séance nécessite une connexion.';

	/// fr: 'Tu peux retrouver ton travail dans ta Classe.'
	String get finPhrase => 'Tu peux retrouver ton travail dans ta Classe.';
}

// Path: accessibilite.apres
class Traductions$accessibilite$apres$fr {
	Traductions$accessibilite$apres$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Revoir le support du cours'
	String get revoirSupport => 'Revoir le support du cours';

	/// fr: 'Le support reste dans ta Classe.'
	String get revoirSupportDetail => 'Le support reste dans ta Classe.';

	/// fr: 'Le support reste dans votre Classe.'
	String get revoirSupportDetailVous => 'Le support reste dans votre Classe.';
}

// Path: consentement.texte
class Traductions$consentement$texte$fr {
	Traductions$consentement$texte$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Les visites des parents'
	String get titre => 'Les visites des parents';

	/// fr: 'Les parents des élèves présents peuvent observer brièvement la séance.'
	String get quiResponsable => 'Les parents des élèves présents peuvent observer brièvement la séance.';

	/// fr: 'Ils entendent l'enseignant et les élèves qui prennent la parole, y compris votre enfant. Leur micro et leur caméra restent désactivés : ils ne peuvent ni parler, ni écrire, ni apparaître à l'écran.'
	String get quiResponsableDetail => 'Ils entendent l\'enseignant et les élèves qui prennent la parole, y compris votre enfant. Leur micro et leur caméra restent désactivés : ils ne peuvent ni parler, ni écrire, ni apparaître à l\'écran.';

	/// fr: 'Les parents des autres élèves présents peuvent observer brièvement la séance.'
	String get quiAdulte => 'Les parents des autres élèves présents peuvent observer brièvement la séance.';

	/// fr: 'Ils entendent l'enseignant et les élèves qui prennent la parole, y compris vous. Leur micro et leur caméra restent désactivés : ils ne peuvent ni parler, ni écrire, ni apparaître à l'écran.'
	String get quiAdulteDetail => 'Ils entendent l\'enseignant et les élèves qui prennent la parole, y compris vous. Leur micro et leur caméra restent désactivés : ils ne peuvent ni parler, ni écrire, ni apparaître à l\'écran.';

	/// fr: 'Pour suivre l'apprentissage sans interrompre la classe.'
	String get pourquoi => 'Pour suivre l\'apprentissage sans interrompre la classe.';

	/// fr: 'Un parent vient voir si son enfant participe, puis repart. La salle rappelle en permanence qu'une visite est possible.'
	String get pourquoiDetail => 'Un parent vient voir si son enfant participe, puis repart. La salle rappelle en permanence qu\'une visite est possible.';

	/// fr: 'Des visites courtes, en nombre limité.'
	String get limites => 'Des visites courtes, en nombre limité.';

	/// fr: 'Chaque parent a un petit nombre de visites par séance, fixé par l'académie et rappelé dans « Comment ça marche ? ». Une visite quittée avant la fin compte comme une visite.'
	String get limitesDetail => 'Chaque parent a un petit nombre de visites par séance, fixé par l\'académie et rappelé dans « Comment ça marche ? ». Une visite quittée avant la fin compte comme une visite.';

	/// fr: 'J'accepte ces modalités pour mon enfant'
	String get caseResponsable => 'J\'accepte ces modalités pour mon enfant';

	/// fr: 'J'accepte ces modalités'
	String get caseAdulte => 'J\'accepte ces modalités';

	/// fr: 'Continuer'
	String get continuer => 'Continuer';

	/// fr: 'Retour'
	String get retour => 'Retour';
}

// Path: consentement.comment
class Traductions$consentement$comment$fr {
	Traductions$consentement$comment$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Comment ça marche ?'
	String get titre => 'Comment ça marche ?';

	/// fr: '(one) {Une visite de {minutes} min par séance.} (other) {{n} visites de {minutes} min par séance.}'
	String visites({required num n, required Object minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: 'Une visite de ${minutes} min par séance.',
		other: '${n} visites de ${minutes} min par séance.',
	);

	/// fr: '(one) {Une visite courte par séance.} (other) {{n} visites courtes par séance.}'
	String visitesSansDuree({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: 'Une visite courte par séance.',
		other: '${n} visites courtes par séance.',
	);

	/// fr: 'Ce nombre vaut pour chaque parent, que la séance réunisse un ou plusieurs de ses enfants.'
	String get parParent => 'Ce nombre vaut pour chaque parent, que la séance réunisse un ou plusieurs de ses enfants.';

	/// fr: 'Une visite quittée avant la fin est comptée : il ne reste alors que la suivante, jusqu'à la dernière.'
	String get ecourtee => 'Une visite quittée avant la fin est comptée : il ne reste alors que la suivante, jusqu\'à la dernière.';

	/// fr: 'Vous entendez l'enseignant et les élèves qui prennent la parole, y compris votre enfant.'
	String get ecouter => 'Vous entendez l\'enseignant et les élèves qui prennent la parole, y compris votre enfant.';

	/// fr: 'Votre micro et votre caméra restent désactivés pendant la visite.'
	String get sansMicro => 'Votre micro et votre caméra restent désactivés pendant la visite.';

	/// fr: 'Le nombre de visites et leur durée s'affichent depuis la classe de votre enfant, selon les règles de sa classe.'
	String get valeursIndisponibles => 'Le nombre de visites et leur durée s\'affichent depuis la classe de votre enfant, selon les règles de sa classe.';

	/// fr: 'Les visites d'observation ne sont pas ouvertes pour cette classe.'
	String get fermee => 'Les visites d\'observation ne sont pas ouvertes pour cette classe.';
}

// Path: consentement.compte
class Traductions$consentement$compte$fr {
	Traductions$consentement$compte$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'L'académie a ajouté à ses conditions un paragraphe sur les visites des parents. Rien n'est considéré comme accepté tant que vous ne l'avez pas fait.'
	String get intro => 'L\'académie a ajouté à ses conditions un paragraphe sur les visites des parents. Rien n\'est considéré comme accepté tant que vous ne l\'avez pas fait.';

	/// fr: 'Vous avez accepté ces modalités le {date}.'
	String accepteLe({required Object date}) => 'Vous avez accepté ces modalités le ${date}.';

	/// fr: 'Merci, votre accord est enregistré.'
	String get merci => 'Merci, votre accord est enregistré.';

	/// fr: 'Lecture de vos accords'
	String get chargement => 'Lecture de vos accords';

	/// fr: 'Vos accords ne s'affichent pas pour le moment.'
	String get erreur => 'Vos accords ne s\'affichent pas pour le moment.';

	/// fr: 'Vous êtes hors ligne. Vos accords s'afficheront dès le retour du réseau.'
	String get horsLigne => 'Vous êtes hors ligne. Vos accords s\'afficheront dès le retour du réseau.';

	/// fr: 'Aucun compte connecté : reconnectez-vous pour lire vos accords.'
	String get sansProfil => 'Aucun compte connecté : reconnectez-vous pour lire vos accords.';

	/// fr: 'Une nouvelle version à lire : les visites des parents'
	String get invite => 'Une nouvelle version à lire : les visites des parents';

	/// fr: 'Lire'
	String get inviteAction => 'Lire';
}

// Path: appareils.foyer
class Traductions$appareils$foyer$fr {
	Traductions$appareils$foyer$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Appareils du foyer'
	String get titre => 'Appareils du foyer';

	/// fr: 'Chaque profil élève a ses propres appareils. Touchez un profil pour voir ses appareils, en retirer un ou en connecter un nouveau.'
	String get phrase => 'Chaque profil élève a ses propres appareils. Touchez un profil pour voir ses appareils, en retirer un ou en connecter un nouveau.';

	/// fr: 'Profils élèves'
	String get groupeProfils => 'Profils élèves';

	/// fr: 'Aucun appareil connecté'
	String get aucunAppareil => 'Aucun appareil connecté';

	/// fr: '1 appareil connecté : {nom}'
	String unAppareil({required Object nom}) => '1 appareil connecté : ${nom}';

	/// fr: '{nombre} appareils connectés : {noms}'
	String plusieursAppareils({required Object nombre, required Object noms}) => '${nombre} appareils connectés : ${noms}';

	/// fr: 'Appareil partagé'
	String get partageTitre => 'Appareil partagé';

	/// fr: 'Sur un appareil partagé, chaque élève choisit son profil puis saisit son code personnel. Cet appareil apparaît alors sous chaque profil qui l'utilise.'
	String get partage => 'Sur un appareil partagé, chaque élève choisit son profil puis saisit son code personnel. Cet appareil apparaît alors sous chaque profil qui l\'utilise.';

	/// fr: 'Aucun profil élève'
	String get videTitre => 'Aucun profil élève';

	/// fr: 'Ajoutez un profil élève pour lui connecter une tablette, un téléphone ou un ordinateur.'
	String get vide => 'Ajoutez un profil élève pour lui connecter une tablette, un téléphone ou un ordinateur.';

	/// fr: 'Ajouter un profil élève'
	String get videAction => 'Ajouter un profil élève';
}

// Path: appareils.eleve
class Traductions$appareils$eleve$fr {
	Traductions$appareils$eleve$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Gérez les appareils autorisés pour {prenom}.'
	String sousTitre({required Object prenom}) => 'Gérez les appareils autorisés pour ${prenom}.';

	/// fr: 'Appareils connectés'
	String get groupe => 'Appareils connectés';

	/// fr: 'Connecter un appareil'
	String get connecter => 'Connecter un appareil';

	/// fr: 'Aucun appareil connecté'
	String get videTitre => 'Aucun appareil connecté';

	/// fr: 'Connectez la tablette, le téléphone ou l'ordinateur de {prenom} avec le code affiché par le bouton ci-dessous.'
	String vide({required Object prenom}) => 'Connectez la tablette, le téléphone ou l\'ordinateur de ${prenom} avec le code affiché par le bouton ci-dessous.';

	/// fr: 'Profil élève introuvable'
	String get introuvableTitre => 'Profil élève introuvable';

	/// fr: 'Ce profil élève n'est pas rattaché à votre foyer.'
	String get introuvable => 'Ce profil élève n\'est pas rattaché à votre foyer.';

	/// fr: 'Voir les appareils du foyer'
	String get introuvableAction => 'Voir les appareils du foyer';

	/// fr: 'Connecté le {date}'
	String connecteLe({required Object date}) => 'Connecté le ${date}';

	/// fr: 'Dernière utilisation : {date}'
	String utiliseLe({required Object date}) => 'Dernière utilisation : ${date}';

	/// fr: 'Pas encore utilisé'
	String get jamaisUtilise => 'Pas encore utilisé';

	/// fr: 'Retirer {appareil}'
	String retirerLibelle({required Object appareil}) => 'Retirer ${appareil}';

	/// fr: 'Retirer ou connecter un appareil demande une connexion internet.'
	String get horsLigne => 'Retirer ou connecter un appareil demande une connexion internet.';

	/// fr: 'Choix du profil et code personnel'
	String get partageTitre => 'Choix du profil et code personnel';

	/// fr: 'Sur un appareil partagé, chaque élève choisit son profil puis saisit son propre code personnel, gardé sur cet appareil.'
	String get partage => 'Sur un appareil partagé, chaque élève choisit son profil puis saisit son propre code personnel, gardé sur cet appareil.';

	/// fr: 'Retirer un appareil'
	String get retraitTitre => 'Retirer un appareil';

	/// fr: 'Un appareil retiré ne peut plus se reconnecter. S'il est connecté en ce moment, il le reste jusqu'à sa prochaine déconnexion.'
	String get retrait => 'Un appareil retiré ne peut plus se reconnecter. S\'il est connecté en ce moment, il le reste jusqu\'à sa prochaine déconnexion.';
}

// Path: appareils.plateforme
class Traductions$appareils$plateforme$fr {
	Traductions$appareils$plateforme$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Téléphone ou tablette Android'
	String get android => 'Téléphone ou tablette Android';

	/// fr: 'iPhone ou iPad'
	String get ios => 'iPhone ou iPad';

	/// fr: 'Navigateur web'
	String get web => 'Navigateur web';

	/// fr: 'Ordinateur'
	String get windows => 'Ordinateur';

	/// fr: 'Appareil'
	String get inconnue => 'Appareil';
}

// Path: appareils.retrait
class Traductions$appareils$retrait$fr {
	Traductions$appareils$retrait$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Retirer cet appareil ?'
	String get question => 'Retirer cet appareil ?';

	/// fr: '{appareil} ne pourra plus se connecter au profil de {prenom}. S'il est connecté en ce moment, il le reste jusqu'à sa prochaine déconnexion.'
	String consequence({required Object appareil, required Object prenom}) => '${appareil} ne pourra plus se connecter au profil de ${prenom}. S\'il est connecté en ce moment, il le reste jusqu\'à sa prochaine déconnexion.';

	/// fr: 'Retirer l'appareil'
	String get confirmer => 'Retirer l\'appareil';

	/// fr: 'Retrait en cours'
	String get enCours => 'Retrait en cours';

	/// fr: 'Appareil retiré. S'il est connecté en ce moment, il le reste jusqu'à sa prochaine déconnexion.'
	String get reussi => 'Appareil retiré. S\'il est connecté en ce moment, il le reste jusqu\'à sa prochaine déconnexion.';

	/// fr: 'Le retrait n'a pas abouti. L'appareil est toujours autorisé. Réessayez dans un instant.'
	String get echec => 'Le retrait n\'a pas abouti. L\'appareil est toujours autorisé. Réessayez dans un instant.';

	/// fr: 'Pas de connexion internet : l'appareil n'a pas été retiré.'
	String get horsLigne => 'Pas de connexion internet : l\'appareil n\'a pas été retiré.';
}

// Path: appareils.emetteur
class Traductions$appareils$emetteur$fr {
	Traductions$appareils$emetteur$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Connecter un appareil'
	String get titre => 'Connecter un appareil';

	/// fr: 'Pour {prenom}'
	String pourEleve({required Object prenom}) => 'Pour ${prenom}';

	/// fr: 'Sur l'autre appareil'
	String get consigneTitre => 'Sur l\'autre appareil';

	/// fr: 'Ouvrez Rewayah, touchez « Connecter l'appareil d'un élève », puis scannez ce QR ou saisissez le code.'
	String get consigne => 'Ouvrez Rewayah, touchez « Connecter l\'appareil d\'un élève », puis scannez ce QR ou saisissez le code.';

	/// fr: 'QR de connexion. Le même code est aussi écrit sur cet écran, à saisir si l'appareil ne lit pas le QR.'
	String get libelleQr => 'QR de connexion. Le même code est aussi écrit sur cet écran, à saisir si l\'appareil ne lit pas le QR.';

	/// fr: 'Code à saisir'
	String get codeManuel => 'Code à saisir';

	/// fr: 'Code à saisir : {code}'
	String codeLu({required Object code}) => 'Code à saisir : ${code}';

	/// fr: 'Valable jusqu'à {heure}'
	String valableJusqua({required Object heure}) => 'Valable jusqu\'à ${heure}';

	/// fr: 'Encore {temps}'
	String restant({required Object temps}) => 'Encore ${temps}';

	/// fr: 'Quitter cet écran n'annule pas le code : il reste valable jusqu'à {heure}.'
	String sortie({required Object heure}) => 'Quitter cet écran n\'annule pas le code : il reste valable jusqu\'à ${heure}.';

	/// fr: 'Cet écran ne peut pas confirmer la connexion. Vérifiez sur l'appareil de l'élève.'
	String get suiviIndisponible => 'Cet écran ne peut pas confirmer la connexion. Vérifiez sur l\'appareil de l\'élève.';

	/// fr: 'Préparation du code'
	String get preparation => 'Préparation du code';

	late final Traductions$appareils$emetteur$verification$fr verification = Traductions$appareils$emetteur$verification$fr.internal(_root);
	late final Traductions$appareils$emetteur$confirme$fr confirme = Traductions$appareils$emetteur$confirme$fr.internal(_root);
	late final Traductions$appareils$emetteur$expire$fr expire = Traductions$appareils$emetteur$expire$fr.internal(_root);
	late final Traductions$appareils$emetteur$remplace$fr remplace = Traductions$appareils$emetteur$remplace$fr.internal(_root);
	late final Traductions$appareils$emetteur$dejaActif$fr dejaActif = Traductions$appareils$emetteur$dejaActif$fr.internal(_root);
	late final Traductions$appareils$emetteur$horsLigne$fr horsLigne = Traductions$appareils$emetteur$horsLigne$fr.internal(_root);
	late final Traductions$appareils$emetteur$erreur$fr erreur = Traductions$appareils$emetteur$erreur$fr.internal(_root);
}

// Path: foyer.vide
class Traductions$foyer$vide$fr {
	Traductions$foyer$vide$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Aucun profil élève pour l'instant'
	String get titre => 'Aucun profil élève pour l\'instant';

	/// fr: 'Ajoutez un profil élève pour l'inscrire dans une classe et relier son appareil.'
	String get phrase => 'Ajoutez un profil élève pour l\'inscrire dans une classe et relier son appareil.';
}

// Path: foyer.membre
class Traductions$foyer$membre$fr {
	Traductions$foyer$membre$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Pas encore de classe'
	String get sansClasse => 'Pas encore de classe';

	/// fr: 'Classe non lue'
	String get classeEchec => 'Classe non lue';

	/// fr: 'Accès sans échéance'
	String get accesSansEcheance => 'Accès sans échéance';

	/// fr: 'Accès jusqu'au {date}'
	String accesJusquau({required Object date}) => 'Accès jusqu\'au ${date}';

	/// fr: 'Accès expiré depuis le {date}'
	String accesExpire({required Object date}) => 'Accès expiré depuis le ${date}';

	/// fr: '{jour} {mois} {annee}'
	String date({required Object jour, required Object mois, required Object annee}) => '${jour} ${mois} ${annee}';
}

// Path: foyer.monProfil
class Traductions$foyer$monProfil$fr {
	Traductions$foyer$monProfil$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Créer mon profil élève'
	String get titre => 'Créer mon profil élève';

	/// fr: 'Pas encore possible'
	String get indisponibleTitre => 'Pas encore possible';

	/// fr: 'Suivre vous-même les cours avec votre propre profil élève sera proposé prochainement. Votre compte de tuteur reste tel qu'il est.'
	String get indisponiblePhrase => 'Suivre vous-même les cours avec votre propre profil élève sera proposé prochainement. Votre compte de tuteur reste tel qu\'il est.';

	/// fr: 'Retour au foyer'
	String get retour => 'Retour au foyer';
}

// Path: foyer.ajout
class Traductions$foyer$ajout$fr {
	Traductions$foyer$ajout$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Suivant'
	String get suivant => 'Suivant';

	/// fr: 'Créer le profil'
	String get creer => 'Créer le profil';

	late final Traductions$foyer$ajout$porte$fr porte = Traductions$foyer$ajout$porte$fr.internal(_root);
	late final Traductions$foyer$ajout$pourQui$fr pourQui = Traductions$foyer$ajout$pourQui$fr.internal(_root);
	late final Traductions$foyer$ajout$identite$fr identite = Traductions$foyer$ajout$identite$fr.internal(_root);
	late final Traductions$foyer$ajout$erreurs$fr erreurs = Traductions$foyer$ajout$erreurs$fr.internal(_root);
	late final Traductions$foyer$ajout$refus$fr refus = Traductions$foyer$ajout$refus$fr.internal(_root);
	late final Traductions$foyer$ajout$incertaine$fr incertaine = Traductions$foyer$ajout$incertaine$fr.internal(_root);

	/// fr: 'Vous êtes hors ligne. Le profil pourra être créé quand la connexion reviendra.'
	String get horsLigne => 'Vous êtes hors ligne. Le profil pourra être créé quand la connexion reviendra.';
}

// Path: ficheEleve.introuvable
class Traductions$ficheEleve$introuvable$fr {
	Traductions$ficheEleve$introuvable$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Ce profil élève est introuvable'
	String get titre => 'Ce profil élève est introuvable';

	/// fr: 'Il ne fait pas partie de votre foyer, ou le lien est incomplet.'
	String get phrase => 'Il ne fait pas partie de votre foyer, ou le lien est incomplet.';

	/// fr: 'Retour au foyer'
	String get retour => 'Retour au foyer';
}

// Path: ficheEleve.lignes
class Traductions$ficheEleve$lignes$fr {
	Traductions$ficheEleve$lignes$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Informations'
	String get informations => 'Informations';

	/// fr: 'Prénom et photo'
	String get informationsLegende => 'Prénom et photo';

	/// fr: 'Parcours et inscription'
	String get inscription => 'Parcours et inscription';

	/// fr: 'Questionnaire et classe'
	String get inscriptionLegende => 'Questionnaire et classe';

	/// fr: 'Interface'
	String get interface => 'Interface';

	/// fr: 'Caméra en cours'
	String get camera => 'Caméra en cours';

	/// fr: 'Autorisée'
	String get cameraAutorisee => 'Autorisée';

	/// fr: 'Non autorisée'
	String get cameraNonAutorisee => 'Non autorisée';

	/// fr: 'Accès Rewayah'
	String get acces => 'Accès Rewayah';

	/// fr: 'Appareils de {prenom}'
	String appareils({required Object prenom}) => 'Appareils de ${prenom}';

	/// fr: 'Connecter un appareil, voir ceux qui sont reliés, en retirer un'
	String get appareilsLegende => 'Connecter un appareil, voir ceux qui sont reliés, en retirer un';
}

// Path: ficheEleve.informations
class Traductions$ficheEleve$informations$fr {
	Traductions$ficheEleve$informations$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Informations de l'élève'
	String get titre => 'Informations de l\'élève';

	/// fr: 'Identité'
	String get identite => 'Identité';

	/// fr: 'Prénom'
	String get prenom => 'Prénom';

	/// fr: 'Le prénom ne se modifie pas encore depuis cette page.'
	String get identiteNote => 'Le prénom ne se modifie pas encore depuis cette page.';

	/// fr: 'L'âge et la date de naissance ne sont pas encore enregistrés sur le profil.'
	String get ageNote => 'L\'âge et la date de naissance ne sont pas encore enregistrés sur le profil.';

	/// fr: 'Photo'
	String get photo => 'Photo';

	/// fr: 'Une photo du visage de {prenom}. Ce n'est pas une pièce d'identité.'
	String photoLegende({required Object prenom}) => 'Une photo du visage de ${prenom}. Ce n\'est pas une pièce d\'identité.';

	/// fr: 'Pas encore de photo'
	String get photoAucune => 'Pas encore de photo';

	/// fr: 'Photo enregistrée'
	String get photoPresente => 'Photo enregistrée';

	/// fr: 'Choisir une photo'
	String get choisir => 'Choisir une photo';

	/// fr: 'Changer la photo'
	String get changer => 'Changer la photo';

	/// fr: 'Aperçu'
	String get apercuTitre => 'Aperçu';

	/// fr: 'Vérifiez la photo avant de l'envoyer.'
	String get apercuPhrase => 'Vérifiez la photo avant de l\'envoyer.';

	/// fr: 'L'aperçu ne s'affiche pas sur cet appareil. La photo peut quand même être envoyée.'
	String get apercuIllisible => 'L\'aperçu ne s\'affiche pas sur cet appareil. La photo peut quand même être envoyée.';

	/// fr: 'Envoyer cette photo'
	String get envoyer => 'Envoyer cette photo';

	/// fr: 'Choisir une autre photo'
	String get autre => 'Choisir une autre photo';

	/// fr: 'Annuler'
	String get annuler => 'Annuler';

	/// fr: 'Envoi de la photo, étape 1 sur 2'
	String get etapeEnvoi => 'Envoi de la photo, étape 1 sur 2';

	/// fr: 'Enregistrement sur le profil, étape 2 sur 2'
	String get etapeEnregistrement => 'Enregistrement sur le profil, étape 2 sur 2';

	/// fr: 'La photo est enregistrée.'
	String get succes => 'La photo est enregistrée.';

	/// fr: 'Cette photo dépasse {taille} Mo. Choisissez une image plus légère.'
	String tropLourde({required Object taille}) => 'Cette photo dépasse ${taille} Mo. Choisissez une image plus légère.';

	/// fr: 'La photo n'a pas pu être envoyée. Rien n'a changé sur le profil.'
	String get echecEnvoi => 'La photo n\'a pas pu être envoyée. Rien n\'a changé sur le profil.';

	/// fr: 'La photo est envoyée, mais elle n'a pas pu être enregistrée sur le profil.'
	String get echecEnregistrement => 'La photo est envoyée, mais elle n\'a pas pu être enregistrée sur le profil.';

	/// fr: 'Réessayer'
	String get reprendre => 'Réessayer';

	/// fr: 'La photo n'a pas pu être ouverte. Vérifiez l'accès aux photos de l'appareil, puis réessayez.'
	String get selectionEchec => 'La photo n\'a pas pu être ouverte. Vérifiez l\'accès aux photos de l\'appareil, puis réessayez.';

	/// fr: 'Vous êtes hors ligne. La photo pourra être envoyée quand la connexion reviendra.'
	String get horsLigne => 'Vous êtes hors ligne. La photo pourra être envoyée quand la connexion reviendra.';
}

// Path: ficheEleve.inscription
class Traductions$ficheEleve$inscription$fr {
	Traductions$ficheEleve$inscription$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Parcours et inscription'
	String get titre => 'Parcours et inscription';

	/// fr: 'Où en est {prenom} : questionnaire et classe.'
	String intro({required Object prenom}) => 'Où en est ${prenom} : questionnaire et classe.';

	/// fr: 'Questionnaire'
	String get questionnaire => 'Questionnaire';

	/// fr: 'Classe'
	String get classe => 'Classe';

	/// fr: 'Lecture en cours'
	String get lecture => 'Lecture en cours';

	/// fr: 'L'état du questionnaire ne s'affiche pas encore.'
	String get etatInconnu => 'L\'état du questionnaire ne s\'affiche pas encore.';

	/// fr: 'À remplir'
	String get aRemplir => 'À remplir';

	/// fr: 'Rempli, horaire à choisir'
	String get horaireAChoisir => 'Rempli, horaire à choisir';

	/// fr: 'Horaire retiré, à choisir de nouveau'
	String get horaireRetire => 'Horaire retiré, à choisir de nouveau';

	/// fr: 'Préférence enregistrée, échange de niveau à prévoir'
	String get echangeAPrevoir => 'Préférence enregistrée, échange de niveau à prévoir';

	/// fr: 'Échange de niveau prévu'
	String get echangePrevu => 'Échange de niveau prévu';

	/// fr: 'Classe en cours de constitution'
	String get classeEnConstitution => 'Classe en cours de constitution';

	/// fr: 'Classe confirmée'
	String get classeConfirmee => 'Classe confirmée';

	/// fr: 'Pas encore de classe. Choisir une classe'
	String get classeAucune => 'Pas encore de classe. Choisir une classe';

	/// fr: 'La classe ne s'affiche pas encore ici. Choisir une classe'
	String get classeIndisponible => 'La classe ne s\'affiche pas encore ici. Choisir une classe';

	/// fr: 'La classe n'a pas pu être lue.'
	String get classeEchec => 'La classe n\'a pas pu être lue.';

	/// fr: 'Relire la classe'
	String get relireClasse => 'Relire la classe';
}

// Path: ficheEleve.interface
class Traductions$ficheEleve$interface$fr {
	Traductions$ficheEleve$interface$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Interface'
	String get titre => 'Interface';

	/// fr: 'Comment Rewayah s'affiche sur l'appareil de {prenom}.'
	String intro({required Object prenom}) => 'Comment Rewayah s\'affiche sur l\'appareil de ${prenom}.';

	/// fr: 'Interface guidée'
	String get guidee => 'Interface guidée';

	/// fr: 'Des écrans simplifiés, de grands boutons, une chose à la fois.'
	String get guideeDescription => 'Des écrans simplifiés, de grands boutons, une chose à la fois.';

	/// fr: 'Interface standard'
	String get standard => 'Interface standard';

	/// fr: 'L'affichage habituel de Rewayah.'
	String get standardDescription => 'L\'affichage habituel de Rewayah.';

	/// fr: 'Vous choisissez ce réglage. Au départ, il a été fixé selon l'âge indiqué à la création du profil.'
	String get politique => 'Vous choisissez ce réglage. Au départ, il a été fixé selon l\'âge indiqué à la création du profil.';

	/// fr: 'Le changement s'applique à la prochaine ouverture de Rewayah sur l'appareil de {prenom}.'
	String application({required Object prenom}) => 'Le changement s\'applique à la prochaine ouverture de Rewayah sur l\'appareil de ${prenom}.';

	/// fr: 'La demande de changement par l'élève lui-même n'est pas encore proposée.'
	String get demandeEleve => 'La demande de changement par l\'élève lui-même n\'est pas encore proposée.';

	/// fr: 'Enregistrement en cours'
	String get enCours => 'Enregistrement en cours';

	/// fr: 'Le changement n'a pas été enregistré. Réessayez.'
	String get echec => 'Le changement n\'a pas été enregistré. Réessayez.';

	/// fr: 'Vous êtes hors ligne. L'interface pourra être changée quand la connexion reviendra.'
	String get horsLigne => 'Vous êtes hors ligne. L\'interface pourra être changée quand la connexion reviendra.';
}

// Path: ficheEleve.camera
class Traductions$ficheEleve$camera$fr {
	Traductions$ficheEleve$camera$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Caméra en cours'
	String get titre => 'Caméra en cours';

	/// fr: 'Caméra pendant les séances'
	String get ligne => 'Caméra pendant les séances';

	/// fr: '{prenom} peut allumer sa caméra pendant les séances.'
	String autorisee({required Object prenom}) => '${prenom} peut allumer sa caméra pendant les séances.';

	/// fr: 'Le bouton caméra n'apparaîtra pas pour {prenom} pendant les séances.'
	String interdite({required Object prenom}) => 'Le bouton caméra n\'apparaîtra pas pour ${prenom} pendant les séances.';

	/// fr: 'Le changement compte à la prochaine entrée de {prenom} en séance.'
	String application({required Object prenom}) => 'Le changement compte à la prochaine entrée de ${prenom} en séance.';

	/// fr: 'Ce réglage ne change pas l'autorisation caméra de l'appareil, celle que le téléphone demande pour lire un QR code.'
	String get distincte => 'Ce réglage ne change pas l\'autorisation caméra de l\'appareil, celle que le téléphone demande pour lire un QR code.';

	/// fr: 'Le changement n'a pas été enregistré. Réessayez.'
	String get echec => 'Le changement n\'a pas été enregistré. Réessayez.';

	/// fr: 'Vous êtes hors ligne. La caméra pourra être réglée quand la connexion reviendra.'
	String get horsLigne => 'Vous êtes hors ligne. La caméra pourra être réglée quand la connexion reviendra.';
}

// Path: ficheEleve.acces
class Traductions$ficheEleve$acces$fr {
	Traductions$ficheEleve$acces$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Accès Rewayah'
	String get titre => 'Accès Rewayah';

	/// fr: 'Accès de {prenom}'
	String ligne({required Object prenom}) => 'Accès de ${prenom}';

	/// fr: 'Sans échéance'
	String get pastilleSansEcheance => 'Sans échéance';

	/// fr: 'En cours'
	String get pastilleEnCours => 'En cours';

	/// fr: 'Expiré'
	String get pastilleExpire => 'Expiré';

	/// fr: 'Aucune date de fin n'est enregistrée.'
	String get sansEcheance => 'Aucune date de fin n\'est enregistrée.';

	/// fr: 'Jusqu'au {date}'
	String jusquau({required Object date}) => 'Jusqu\'au ${date}';

	/// fr: 'Expiré depuis le {date}'
	String expireDepuis({required Object date}) => 'Expiré depuis le ${date}';

	/// fr: 'Depuis cette date, {prenom} ne peut plus entrer dans Rewayah.'
	String expirePhrase({required Object prenom}) => 'Depuis cette date, ${prenom} ne peut plus entrer dans Rewayah.';

	/// fr: 'Le début de l'accès et son motif ne s'affichent pas encore.'
	String get detailIndisponible => 'Le début de l\'accès et son motif ne s\'affichent pas encore.';
}

// Path: eleveConnexion.profils
class Traductions$eleveConnexion$profils$fr {
	Traductions$eleveConnexion$profils$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Touche ton prénom pour continuer.'
	String get phrase => 'Touche ton prénom pour continuer.';

	/// fr: 'Ajouter un profil sur cet appareil'
	String get ajouter => 'Ajouter un profil sur cet appareil';

	/// fr: 'Avec le code affiché par le tuteur'
	String get ajouterLegende => 'Avec le code affiché par le tuteur';

	/// fr: 'Continuer en tant que {prenom}'
	String profilLibelle({required Object prenom}) => 'Continuer en tant que ${prenom}';

	/// fr: 'Aucun profil sur cet appareil'
	String get videTitre => 'Aucun profil sur cet appareil';

	/// fr: 'Pour utiliser cet appareil, le tuteur doit afficher un nouveau code sur son propre appareil.'
	String get vide => 'Pour utiliser cet appareil, le tuteur doit afficher un nouveau code sur son propre appareil.';

	/// fr: 'Saisir un code'
	String get videAction => 'Saisir un code';

	/// fr: 'Cet appareil a été retiré pour {prenom}. Demande au tuteur de le reconnecter avec un nouveau code.'
	String retire({required Object prenom}) => 'Cet appareil a été retiré pour ${prenom}. Demande au tuteur de le reconnecter avec un nouveau code.';

	/// fr: 'Cet appareil ne retrouve plus la connexion de {prenom}. Demande au tuteur d'afficher un nouveau code, puis saisis-le ici.'
	String jetonAbsent({required Object prenom}) => 'Cet appareil ne retrouve plus la connexion de ${prenom}. Demande au tuteur d\'afficher un nouveau code, puis saisis-le ici.';
}

// Path: eleveConnexion.pin
class Traductions$eleveConnexion$pin$fr {
	Traductions$eleveConnexion$pin$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Bonjour {prenom}'
	String bonjour({required Object prenom}) => 'Bonjour ${prenom}';

	/// fr: 'Choisis ton code personnel'
	String get creer => 'Choisis ton code personnel';

	/// fr: 'Quatre chiffres, rien que pour toi. Il reste sur cet appareil.'
	String get creerPhrase => 'Quatre chiffres, rien que pour toi. Il reste sur cet appareil.';

	/// fr: 'Entre-le encore une fois'
	String get confirmer => 'Entre-le encore une fois';

	/// fr: 'Les deux codes ne sont pas les mêmes. Choisis ton code à nouveau.'
	String get different => 'Les deux codes ne sont pas les mêmes. Choisis ton code à nouveau.';

	/// fr: 'Connexion en cours'
	String get ouverture => 'Connexion en cours';

	/// fr: 'Pas de connexion internet. Ton code est bon : réessaie quand internet revient.'
	String get horsLigne => 'Pas de connexion internet. Ton code est bon : réessaie quand internet revient.';

	/// fr: 'Trop d'essais. Patiente un instant avant de réessayer.'
	String get tropDEssais => 'Trop d\'essais. Patiente un instant avant de réessayer.';

	/// fr: 'La connexion n'a pas abouti. Réessaie dans un instant.'
	String get echec => 'La connexion n\'a pas abouti. Réessaie dans un instant.';

	/// fr: 'Changer de profil'
	String get changerProfil => 'Changer de profil';

	/// fr: 'Code oublié ?'
	String get oublie => 'Code oublié ?';

	/// fr: 'Demande au tuteur d'afficher un nouveau code sur son appareil, puis saisis-le ici. Tu choisiras alors un nouveau code personnel.'
	String get oubliePhrase => 'Demande au tuteur d\'afficher un nouveau code sur son appareil, puis saisis-le ici. Tu choisiras alors un nouveau code personnel.';

	/// fr: 'Saisir un nouveau code'
	String get oublieAction => 'Saisir un nouveau code';
}

// Path: eleveConnexion.saisie
class Traductions$eleveConnexion$saisie$fr {
	Traductions$eleveConnexion$saisie$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Connecter cet appareil'
	String get titre => 'Connecter cet appareil';

	/// fr: 'Saisissez le code de six caractères affiché sous le QR code, sur l'appareil du tuteur.'
	String get phrase => 'Saisissez le code de six caractères affiché sous le QR code, sur l\'appareil du tuteur.';

	/// fr: 'Code'
	String get champ => 'Code';

	/// fr: 'Chiffres de 2 à 9 et lettres, sans I ni O.'
	String get aide => 'Chiffres de 2 à 9 et lettres, sans I ni O.';

	/// fr: 'Connecter l'appareil'
	String get valider => 'Connecter l\'appareil';

	/// fr: 'Scanner le QR code'
	String get scanner => 'Scanner le QR code';

	/// fr: 'Pas de connexion internet. Le code pourra être vérifié au retour du réseau.'
	String get horsLigne => 'Pas de connexion internet. Le code pourra être vérifié au retour du réseau.';
}

// Path: eleveConnexion.lecteur
class Traductions$eleveConnexion$lecteur$fr {
	Traductions$eleveConnexion$lecteur$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Scanner le QR code'
	String get titre => 'Scanner le QR code';

	/// fr: 'Visez le QR code affiché sur l'appareil du tuteur.'
	String get consigne => 'Visez le QR code affiché sur l\'appareil du tuteur.';

	/// fr: 'Autorisez la caméra si l'appareil le demande.'
	String get demarrage => 'Autorisez la caméra si l\'appareil le demande.';

	/// fr: 'Vue de la caméra'
	String get libelleApercu => 'Vue de la caméra';

	/// fr: 'Ce QR code n'est pas un code de connexion Rewayah. Visez celui affiché par le tuteur.'
	String get contenuInvalide => 'Ce QR code n\'est pas un code de connexion Rewayah. Visez celui affiché par le tuteur.';

	/// fr: 'Saisir le code'
	String get saisir => 'Saisir le code';

	/// fr: 'Scanner à nouveau'
	String get scannerANouveau => 'Scanner à nouveau';

	/// fr: 'Vérification du code'
	String get verificationTitre => 'Vérification du code';

	/// fr: 'La caméra est arrêtée pendant la vérification.'
	String get verificationPhrase => 'La caméra est arrêtée pendant la vérification.';

	/// fr: 'Caméra non autorisée'
	String get refuseeTitre => 'Caméra non autorisée';

	/// fr: 'Pour lire le QR code, autorisez la caméra. Vous pouvez aussi saisir le code affiché sous le QR.'
	String get refuseePhrase => 'Pour lire le QR code, autorisez la caméra. Vous pouvez aussi saisir le code affiché sous le QR.';

	/// fr: 'Autoriser la caméra'
	String get refuseeAction => 'Autoriser la caméra';

	/// fr: 'Caméra bloquée'
	String get refuseeDurablementTitre => 'Caméra bloquée';

	/// fr: 'La caméra reste refusée pour Rewayah. Autorisez-la dans les réglages de l'appareil ou du navigateur, ou saisissez le code.'
	String get refuseeDurablementPhrase => 'La caméra reste refusée pour Rewayah. Autorisez-la dans les réglages de l\'appareil ou du navigateur, ou saisissez le code.';

	/// fr: 'Caméra occupée'
	String get occupeeTitre => 'Caméra occupée';

	/// fr: 'Une autre application utilise la caméra. Fermez-la, puis réessayez, ou saisissez le code.'
	String get occupeePhrase => 'Une autre application utilise la caméra. Fermez-la, puis réessayez, ou saisissez le code.';

	/// fr: 'Aucune caméra'
	String get absenteTitre => 'Aucune caméra';

	/// fr: 'Cet appareil n'a pas de caméra disponible. Saisissez le code affiché sous le QR.'
	String get absentePhrase => 'Cet appareil n\'a pas de caméra disponible. Saisissez le code affiché sous le QR.';

	/// fr: 'Lecture impossible ici'
	String get nonSupporteeTitre => 'Lecture impossible ici';

	/// fr: 'Cet appareil ou ce navigateur ne sait pas lire un QR code. Saisissez le code affiché sous le QR.'
	String get nonSupporteePhrase => 'Cet appareil ou ce navigateur ne sait pas lire un QR code. Saisissez le code affiché sous le QR.';

	/// fr: 'La caméra n'a pas démarré'
	String get erreurTitre => 'La caméra n\'a pas démarré';

	/// fr: 'Réessayez, ou saisissez le code affiché sous le QR.'
	String get erreurPhrase => 'Réessayez, ou saisissez le code affiché sous le QR.';
}

// Path: eleveConnexion.refus
class Traductions$eleveConnexion$refus$fr {
	Traductions$eleveConnexion$refus$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Un code compte six caractères : chiffres de 2 à 9 et lettres, sans I ni O.'
	String get format => 'Un code compte six caractères : chiffres de 2 à 9 et lettres, sans I ni O.';

	/// fr: 'Code non reconnu'
	String get inconnuTitre => 'Code non reconnu';

	/// fr: 'Ce code n'existe pas, ou un code plus récent l'a remplacé. Vérifiez-le, ou affichez un nouveau code sur l'appareil du tuteur.'
	String get inconnu => 'Ce code n\'existe pas, ou un code plus récent l\'a remplacé. Vérifiez-le, ou affichez un nouveau code sur l\'appareil du tuteur.';

	/// fr: 'Code expiré'
	String get expireTitre => 'Code expiré';

	/// fr: 'Ce code n'est plus valable. Affichez un nouveau code sur l'appareil du tuteur.'
	String get expire => 'Ce code n\'est plus valable. Affichez un nouveau code sur l\'appareil du tuteur.';

	/// fr: 'Code déjà utilisé'
	String get dejaUtiliseTitre => 'Code déjà utilisé';

	/// fr: 'Ce code a déjà servi à connecter un appareil. Affichez un nouveau code sur l'appareil du tuteur.'
	String get dejaUtilise => 'Ce code a déjà servi à connecter un appareil. Affichez un nouveau code sur l\'appareil du tuteur.';

	/// fr: 'Appareil retiré'
	String get revoqueTitre => 'Appareil retiré';

	/// fr: 'Le tuteur a retiré cet appareil. Demandez-lui d'afficher un nouveau code.'
	String get revoque => 'Le tuteur a retiré cet appareil. Demandez-lui d\'afficher un nouveau code.';

	/// fr: 'Limite d'appareils atteinte'
	String get plafondTitre => 'Limite d\'appareils atteinte';

	/// fr: 'Ce profil élève a atteint le nombre d'appareils autorisés. Le tuteur peut en retirer un dans Foyer, puis afficher un nouveau code.'
	String get plafond => 'Ce profil élève a atteint le nombre d\'appareils autorisés. Le tuteur peut en retirer un dans Foyer, puis afficher un nouveau code.';

	/// fr: 'Trop d'essais'
	String get tropDEssaisTitre => 'Trop d\'essais';

	/// fr: 'Patientez un instant avant de réessayer.'
	String get tropDEssais => 'Patientez un instant avant de réessayer.';

	/// fr: 'Pas de connexion'
	String get horsLigneTitre => 'Pas de connexion';

	/// fr: 'Le code n'a pas pu être vérifié. Vérifiez la connexion internet, puis réessayez.'
	String get horsLigne => 'Le code n\'a pas pu être vérifié. Vérifiez la connexion internet, puis réessayez.';

	/// fr: 'Connexion non enregistrée'
	String get nonEnregistreTitre => 'Connexion non enregistrée';

	/// fr: 'Cet appareil n'a pas pu garder la connexion. Le code a sans doute déjà servi : affichez un nouveau code sur l'appareil du tuteur, puis recommencez.'
	String get nonEnregistre => 'Cet appareil n\'a pas pu garder la connexion. Le code a sans doute déjà servi : affichez un nouveau code sur l\'appareil du tuteur, puis recommencez.';

	/// fr: 'Connexion non aboutie'
	String get generiqueTitre => 'Connexion non aboutie';

	/// fr: 'La vérification du code n'a pas abouti. Réessayez dans un instant.'
	String get generique => 'La vérification du code n\'a pas abouti. Réessayez dans un instant.';
}

// Path: dossiers.file
class Traductions$dossiers$file$fr {
	Traductions$dossiers$file$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Chargement des dossiers…'
	String get chargement => 'Chargement des dossiers…';

	/// fr: 'Impossible de charger les dossiers.'
	String get erreur => 'Impossible de charger les dossiers.';

	/// fr: 'Vous êtes hors ligne. Les dossiers ne peuvent pas être actualisés.'
	String get horsLigne => 'Vous êtes hors ligne. Les dossiers ne peuvent pas être actualisés.';

	/// fr: 'Vous n'avez pas accès aux dossiers à valider.'
	String get accesRefuse => 'Vous n\'avez pas accès aux dossiers à valider.';

	/// fr: 'Actualisation des dossiers…'
	String get actualisation => 'Actualisation des dossiers…';

	/// fr: 'Le chargement prend plus de temps que prévu.'
	String get chargementProlonge => 'Le chargement prend plus de temps que prévu.';

	/// fr: 'Impossible de charger les dossiers suivants.'
	String get suivantsErreur => 'Impossible de charger les dossiers suivants.';

	/// fr: 'La consultation des dossiers est indisponible pour le moment.'
	String get indisponible => 'La consultation des dossiers est indisponible pour le moment.';

	/// fr: 'Ce dossier n’est plus disponible dans la file.'
	String get selectionRetiree => 'Ce dossier n’est plus disponible dans la file.';

	/// fr: 'Actualiser les dossiers'
	String get actualiser => 'Actualiser les dossiers';

	/// fr: 'Sélectionnez un dossier à examiner.'
	String get aucuneSelection => 'Sélectionnez un dossier à examiner.';

	/// fr: 'Charger les dossiers suivants'
	String get suivants => 'Charger les dossiers suivants';

	/// fr: 'Ouvrir le dossier de {nom}'
	String ouvrirDe({required Object nom}) => 'Ouvrir le dossier de ${nom}';

	/// fr: 'Ouvrir le dossier d'{nom}'
	String ouvrirElide({required Object nom}) => 'Ouvrir le dossier d\'${nom}';

	/// fr: 'En cours de vérification'
	String get enVerification => 'En cours de vérification';

	/// fr: 'Dossier sans nom disponible'
	String get sansNom => 'Dossier sans nom disponible';

	/// fr: '{type} · {date}'
	String legende({required Object type, required Object date}) => '${type} · ${date}';

	/// fr: '{date} à {heure} ({zone})'
	String dateHeure({required Object date, required Object heure, required Object zone}) => '${date} à ${heure} (${zone})';

	/// fr: '{jour}/{mois}/{annee}'
	String dateChiffres({required Object jour, required Object mois, required Object annee}) => '${jour}/${mois}/${annee}';

	/// fr: '{heures}:{minutes}'
	String heureChiffres({required Object heures, required Object minutes}) => '${heures}:${minutes}';

	/// fr: 'UTC'
	String get zoneUtc => 'UTC';

	/// fr: 'Dossier suivant : {nom}'
	String suivantAnnonce({required Object nom}) => 'Dossier suivant : ${nom}';
}

// Path: dossiers.detail
class Traductions$dossiers$detail$fr {
	Traductions$dossiers$detail$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Dossier de {nom}'
	String titreDe({required Object nom}) => 'Dossier de ${nom}';

	/// fr: 'Dossier d'{nom}'
	String titreElide({required Object nom}) => 'Dossier d\'${nom}';
}

// Path: dossiers.visionneuse
class Traductions$dossiers$visionneuse$fr {
	Traductions$dossiers$visionneuse$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Chargement de la pièce…'
	String get chargement => 'Chargement de la pièce…';

	/// fr: 'La pièce ne peut pas être affichée.'
	String get erreur => 'La pièce ne peut pas être affichée.';

	/// fr: 'L'accès à cette pièce a expiré.'
	String get expire => 'L\'accès à cette pièce a expiré.';

	/// fr: 'Recharger la pièce'
	String get recharger => 'Recharger la pièce';

	/// fr: 'Ce format de pièce ne peut pas être affiché.'
	String get formatNonPrisEnCharge => 'Ce format de pièce ne peut pas être affiché.';

	/// fr: 'Vous n’avez plus accès à cette pièce.'
	String get accesRetire => 'Vous n’avez plus accès à cette pièce.';

	/// fr: 'Vous êtes hors ligne. La pièce ne peut pas être chargée.'
	String get horsLigne => 'Vous êtes hors ligne. La pièce ne peut pas être chargée.';

	/// fr: 'Aucune pièce n’est disponible.'
	String get aucune => 'Aucune pièce n’est disponible.';

	/// fr: 'Fermer la pièce'
	String get fermerPiece => 'Fermer la pièce';

	/// fr: 'Agrandir'
	String get agrandir => 'Agrandir';

	/// fr: 'Réduire'
	String get reduire => 'Réduire';

	/// fr: 'Ajuster à l’écran'
	String get ajuster => 'Ajuster à l’écran';

	/// fr: '{action} (touche {touche})'
	String infoBulle({required Object action, required Object touche}) => '${action} (touche ${touche})';

	/// fr: 'Document fictif'
	String get documentFictif => 'Document fictif';
}

// Path: dossiers.revue
class Traductions$dossiers$revue$fr {
	Traductions$dossiers$revue$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Identité et dossier'
	String get identite => 'Identité et dossier';

	/// fr: 'La pièce requise n’a pas été transmise.'
	String get pieceNonTransmise => 'La pièce requise n’a pas été transmise.';

	/// fr: 'Pièce d'identité'
	String get piece => 'Pièce d\'identité';

	/// fr: 'Voir la pièce'
	String get voirPiece => 'Voir la pièce';

	/// fr: 'Accords et éléments soumis'
	String get accords => 'Accords et éléments soumis';

	/// fr: 'Nom'
	String get nom => 'Nom';

	/// fr: 'Prénom'
	String get prenom => 'Prénom';

	/// fr: 'Type de dossier'
	String get typeDossier => 'Type de dossier';

	/// fr: 'Date de dépôt'
	String get dateDepot => 'Date de dépôt';

	/// fr: 'État du dossier'
	String get etatDossier => 'État du dossier';

	/// fr: 'Date de dépôt indisponible'
	String get dateIndisponible => 'Date de dépôt indisponible';

	/// fr: 'Ce dossier n'est pas encore prêt à être validé.'
	String get pasPret => 'Ce dossier n\'est pas encore prêt à être validé.';

	/// fr: 'Impossible de charger ce dossier.'
	String get erreurChargement => 'Impossible de charger ce dossier.';

	/// fr: 'La consultation de la pièce est indisponible pour le moment.'
	String get pieceIndisponible => 'La consultation de la pièce est indisponible pour le moment.';

	late final Traductions$dossiers$revue$etats$fr etats = Traductions$dossiers$revue$etats$fr.internal(_root);
}

// Path: dossiers.profilACompleter
class Traductions$dossiers$profilACompleter$fr {
	Traductions$dossiers$profilACompleter$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Profil à compléter'
	String get titre => 'Profil à compléter';

	/// fr: 'Votre profil doit être complété avant de consulter les dossiers autorisés par cette règle.'
	String get texte => 'Votre profil doit être complété avant de consulter les dossiers autorisés par cette règle.';
}

// Path: dossiers.refus
class Traductions$dossiers$refus$fr {
	Traductions$dossiers$refus$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Refuser le dossier'
	String get titre => 'Refuser le dossier';

	/// fr: '{nom} · {type}'
	String nomType({required Object nom, required Object type}) => '${nom} · ${type}';

	/// fr: 'Indiquez le motif qui sera affiché à la personne concernée.'
	String get corps => 'Indiquez le motif qui sera affiché à la personne concernée.';

	/// fr: 'Motif du refus'
	String get champ => 'Motif du refus';

	/// fr: 'Expliquez ce qui doit être corrigé, sans donnée interne ni commentaire personnel.'
	String get aide => 'Expliquez ce qui doit être corrigé, sans donnée interne ni commentaire personnel.';

	/// fr: 'Indiquez le motif du refus.'
	String get erreurVide => 'Indiquez le motif du refus.';

	/// fr: 'Le motif dépasse la longueur autorisée.'
	String get tropLong => 'Le motif dépasse la longueur autorisée.';

	/// fr: 'Refus en cours…'
	String get envoi => 'Refus en cours…';

	/// fr: 'Le dossier n'a pas pu être refusé.'
	String get erreur => 'Le dossier n\'a pas pu être refusé.';

	/// fr: 'Vous êtes hors ligne. Le refus n’a pas été envoyé.'
	String get horsLigne => 'Vous êtes hors ligne. Le refus n’a pas été envoyé.';

	/// fr: 'Le résultat du refus n’est pas encore confirmé.'
	String get inconnu => 'Le résultat du refus n’est pas encore confirmé.';

	/// fr: 'Vous ne pouvez plus refuser ce dossier.'
	String get interdit => 'Vous ne pouvez plus refuser ce dossier.';

	/// fr: 'Le refus est indisponible pour le moment.'
	String get indisponible => 'Le refus est indisponible pour le moment.';

	/// fr: 'Dossier refusé.'
	String get succes => 'Dossier refusé.';

	/// fr: 'Abandonner le motif saisi ?'
	String get abandonQuestion => 'Abandonner le motif saisi ?';

	/// fr: 'Continuer la saisie'
	String get continuerSaisie => 'Continuer la saisie';

	/// fr: 'Abandonner'
	String get abandonner => 'Abandonner';
}

// Path: dossiers.validation
class Traductions$dossiers$validation$fr {
	Traductions$dossiers$validation$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Valider ce dossier ?'
	String get titre => 'Valider ce dossier ?';

	/// fr: 'Le dossier de {nom} sera validé. Son compte pourra accéder à son espace.'
	String corpsActivation({required Object nom}) => 'Le dossier de ${nom} sera validé. Son compte pourra accéder à son espace.';

	/// fr: 'Le dossier de {nom} sera validé. Les autres conditions d’accès resteront applicables.'
	String corpsDocumentaire({required Object nom}) => 'Le dossier de ${nom} sera validé. Les autres conditions d’accès resteront applicables.';

	/// fr: 'La validation est indisponible pour le moment.'
	String get indisponible => 'La validation est indisponible pour le moment.';

	/// fr: 'Validation en cours…'
	String get envoi => 'Validation en cours…';

	/// fr: 'Le dossier n'a pas pu être validé.'
	String get erreur => 'Le dossier n\'a pas pu être validé.';

	/// fr: 'Vous êtes hors ligne. La validation n’a pas été envoyée.'
	String get horsLigne => 'Vous êtes hors ligne. La validation n’a pas été envoyée.';

	/// fr: 'Le résultat de la validation n’est pas encore confirmé.'
	String get inconnu => 'Le résultat de la validation n’est pas encore confirmé.';

	/// fr: 'Ce dossier n’est plus prêt à être validé.'
	String get plusPret => 'Ce dossier n’est plus prêt à être validé.';

	/// fr: 'Vous ne pouvez plus valider ce dossier.'
	String get interdit => 'Vous ne pouvez plus valider ce dossier.';

	/// fr: 'Dossier validé.'
	String get succes => 'Dossier validé.';
}

// Path: dossiers.decision
class Traductions$dossiers$decision$fr {
	Traductions$dossiers$decision$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Vérifier le résultat'
	String get verifierResultat => 'Vérifier le résultat';

	/// fr: 'Ce dossier a déjà été traité.'
	String get dejaTraite => 'Ce dossier a déjà été traité.';

	/// fr: 'Ce dossier a été traité par un autre membre de l'équipe.'
	String get conflit => 'Ce dossier a été traité par un autre membre de l\'équipe.';

	/// fr: '{prenom} {nom}'
	String nomComplet({required Object prenom, required Object nom}) => '${prenom} ${nom}';
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

// Path: admin.politiqueRevueKyc
class Traductions$admin$politiqueRevueKyc$fr {
	Traductions$admin$politiqueRevueKyc$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Politique de genre pour la revue KYC'
	String get titre => 'Politique de genre pour la revue KYC';

	/// fr: 'Limiter la revue KYC selon le genre'
	String get libelle => 'Limiter la revue KYC selon le genre';

	/// fr: 'Lorsque cette règle est désactivée, tout membre autorisé à revoir les dossiers peut traiter les dossiers de son périmètre, quel que soit son genre.'
	String get aide => 'Lorsque cette règle est désactivée, tout membre autorisé à revoir les dossiers peut traiter les dossiers de son périmètre, quel que soit son genre.';

	/// fr: 'Le réglage n'a pas pu être enregistré.'
	String get echecEnregistrement => _root.admin.groupes.observationErreur;
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

	/// fr: 'Enregistrer la version'
	String get enregistrerVersion => 'Enregistrer la version';

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

	/// fr: 'Historique des observations'
	String get titrePage => 'Historique des observations';

	/// fr: 'Administration'
	String get sousTitre => 'Administration';

	/// fr: 'Rechercher un tuteur ou un élève'
	String get recherche => 'Rechercher un tuteur ou un élève';

	/// fr: 'Saisissez au moins deux lettres.'
	String get rechercheCourte => 'Saisissez au moins deux lettres.';

	/// fr: 'Aucun tuteur ni élève ne porte ce nom.'
	String get rechercheAucune => 'Aucun tuteur ni élève ne porte ce nom.';

	/// fr: 'La recherche n'a pas abouti. Réessayez.'
	String get rechercheErreur => 'La recherche n\'a pas abouti. Réessayez.';

	/// fr: 'Tuteur'
	String get roleTuteur => 'Tuteur';

	/// fr: 'Élève'
	String get roleEleve => 'Élève';

	/// fr: 'Tuteur : {nom}'
	String filtreTuteur({required Object nom}) => 'Tuteur : ${nom}';

	/// fr: 'Élève : {nom}'
	String filtreEleve({required Object nom}) => 'Élève : ${nom}';

	/// fr: 'Retirer le filtre {filtre}'
	String retirerFiltre({required Object filtre}) => 'Retirer le filtre ${filtre}';

	/// fr: 'Classe'
	String get classe => 'Classe';

	/// fr: 'Toutes les classes'
	String get toutesClasses => 'Toutes les classes';

	/// fr: 'Période'
	String get periode => 'Période';

	/// fr: 'Statut'
	String get statut => 'Statut';

	/// fr: 'Tous les statuts'
	String get tousStatuts => 'Tous les statuts';

	/// fr: 'Date'
	String get colonneDate => 'Date';

	/// fr: 'Tuteur'
	String get colonneTuteur => 'Tuteur';

	/// fr: 'Élève'
	String get colonneEleve => 'Élève';

	/// fr: 'Classe'
	String get colonneClasse => 'Classe';

	/// fr: 'Entrée'
	String get colonneEntree => 'Entrée';

	/// fr: 'Sortie'
	String get colonneSortie => 'Sortie';

	/// fr: 'Durée'
	String get colonneDuree => 'Durée';

	/// fr: 'Statut'
	String get colonneStatut => 'Statut';

	/// fr: 'Terminée'
	String get terminee => 'Terminée';

	/// fr: 'Sortie non enregistrée'
	String get ouverte => 'Sortie non enregistrée';

	/// fr: 'Non enregistrée'
	String get sortieAbsente => 'Non enregistrée';

	/// fr: 'Non confirmée'
	String get dureeNonConfirmee => 'Non confirmée';

	/// fr: 'Nom non disponible'
	String get nomInconnu => 'Nom non disponible';

	/// fr: 'Classe non disponible'
	String get classeInconnue => 'Classe non disponible';

	/// fr: '{entree} - {sortie}'
	String plage({required Object entree, required Object sortie}) => '${entree} - ${sortie}';

	/// fr: 'Visite {rang} du {date}, {tuteur} pour {eleve}, {classe}, entrée {entree}, sortie {sortie}, durée {duree}, {statut}'
	String ligne({required Object rang, required Object date, required Object tuteur, required Object eleve, required Object classe, required Object entree, required Object sortie, required Object duree, required Object statut}) => 'Visite ${rang} du ${date}, ${tuteur} pour ${eleve}, ${classe}, entrée ${entree}, sortie ${sortie}, durée ${duree}, ${statut}';

	/// fr: 'Heures affichées à l'heure de cet appareil (UTC{decalage}).'
	String fuseau({required Object decalage}) => 'Heures affichées à l\'heure de cet appareil (UTC${decalage}).';

	/// fr: 'Historique des observations indisponible'
	String get indisponibleTitre => 'Historique des observations indisponible';

	/// fr: 'La lecture des visites d'observation n'est pas encore ouverte dans l'application.'
	String get indisponiblePhrase => 'La lecture des visites d\'observation n\'est pas encore ouverte dans l\'application.';

	/// fr: 'Aucune visite enregistrée'
	String get videTitre => 'Aucune visite enregistrée';

	/// fr: 'Les visites d'observation des tuteurs s'afficheront ici.'
	String get videPhrase => 'Les visites d\'observation des tuteurs s\'afficheront ici.';

	/// fr: 'Aucune visite ne correspond'
	String get videFiltreTitre => 'Aucune visite ne correspond';

	/// fr: 'Élargissez la période ou retirez un filtre.'
	String get videFiltrePhrase => 'Élargissez la période ou retirez un filtre.';

	/// fr: 'Effacer les filtres'
	String get effacerFiltres => 'Effacer les filtres';

	/// fr: 'Charger les visites plus anciennes'
	String get chargerSuite => 'Charger les visites plus anciennes';

	/// fr: 'Les visites plus anciennes n'ont pas pu être lues.'
	String get erreurSuite => 'Les visites plus anciennes n\'ont pas pu être lues.';

	/// fr: 'Toutes les visites sont affichées.'
	String get fin => 'Toutes les visites sont affichées.';
}

// Path: admin.comptes
class Traductions$admin$comptes$fr {
	Traductions$admin$comptes$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Comptes'
	String get titre => 'Comptes';

	/// fr: 'Toutes les personnes inscrites, celles qui attendent une décision en premier. Un enseignant sans pièce d'identité déposée reste visible ici : c'est le seul endroit qui le montre.'
	String get intro => 'Toutes les personnes inscrites, celles qui attendent une décision en premier. Un enseignant sans pièce d\'identité déposée reste visible ici : c\'est le seul endroit qui le montre.';

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

	/// fr: 'Sans objet'
	String get pieceSansObjet => 'Sans objet';

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

	/// fr: 'Ma classe'
	String get maClasse => 'Ma classe';

	/// fr: 'Coran'
	String get coran => 'Coran';

	/// fr: 'Mon espace'
	String get monEspace => 'Mon espace';

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

	/// fr: 'Aujourd'hui'
	String get journee => 'Aujourd\'hui';

	/// fr: 'Classes'
	String get classes => 'Classes';

	/// fr: 'Disponibilités'
	String get creneaux => 'Disponibilités';

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

	/// fr: 'Contrôle'
	String get controle => 'Contrôle';

	/// fr: 'Historique'
	String get historique => 'Historique';

	/// fr: 'Échanges'
	String get echanges => 'Échanges';

	/// fr: 'Compte'
	String get compte => 'Compte';
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

// Path: compte.tuteur
class Traductions$compte$tuteur$fr {
	Traductions$compte$tuteur$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Préférences'
	String get preferences => 'Préférences';

	/// fr: '{jour} {mois} {annee}'
	String dateLongue({required Object jour, required Object mois, required Object annee}) => '${jour} ${mois} ${annee}';

	late final Traductions$compte$tuteur$identite$fr identite = Traductions$compte$tuteur$identite$fr.internal(_root);
	late final Traductions$compte$tuteur$acces$fr acces = Traductions$compte$tuteur$acces$fr.internal(_root);
	late final Traductions$compte$tuteur$securite$fr securite = Traductions$compte$tuteur$securite$fr.internal(_root);
	late final Traductions$compte$tuteur$informations$fr informations = Traductions$compte$tuteur$informations$fr.internal(_root);
	late final Traductions$compte$tuteur$foyer$fr foyer = Traductions$compte$tuteur$foyer$fr.internal(_root);
	late final Traductions$compte$tuteur$aide$fr aide = Traductions$compte$tuteur$aide$fr.internal(_root);
	late final Traductions$compte$tuteur$deconnexion$fr deconnexion = Traductions$compte$tuteur$deconnexion$fr.internal(_root);
	late final Traductions$compte$tuteur$pageInformations$fr pageInformations = Traductions$compte$tuteur$pageInformations$fr.internal(_root);
	late final Traductions$compte$tuteur$pageSecurite$fr pageSecurite = Traductions$compte$tuteur$pageSecurite$fr.internal(_root);
	late final Traductions$compte$tuteur$pageAcces$fr pageAcces = Traductions$compte$tuteur$pageAcces$fr.internal(_root);
	late final Traductions$compte$tuteur$pagePaiements$fr pagePaiements = Traductions$compte$tuteur$pagePaiements$fr.internal(_root);
	late final Traductions$compte$tuteur$pagePreferences$fr pagePreferences = Traductions$compte$tuteur$pagePreferences$fr.internal(_root);
	late final Traductions$compte$tuteur$pageApparence$fr pageApparence = Traductions$compte$tuteur$pageApparence$fr.internal(_root);
	late final Traductions$compte$tuteur$pageAide$fr pageAide = Traductions$compte$tuteur$pageAide$fr.internal(_root);
	late final Traductions$compte$tuteur$pageLegal$fr pageLegal = Traductions$compte$tuteur$pageLegal$fr.internal(_root);
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

// Path: historique.duree
class Traductions$historique$duree$fr {
	Traductions$historique$duree$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: '{s} s'
	String secondes({required Object s}) => '${s} s';

	/// fr: '{m} min'
	String minutes({required Object m}) => '${m} min';

	/// fr: '{m} min {s} s'
	String minutesSecondes({required Object m, required Object s}) => '${m} min ${s} s';

	/// fr: '{h} h'
	String heures({required Object h}) => '${h} h';

	/// fr: '{h} h {m}'
	String heuresMinutes({required Object h, required Object m}) => '${h} h ${m}';
}

// Path: historique.selecteur
class Traductions$historique$selecteur$fr {
	Traductions$historique$selecteur$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Aucune séance'
	String get aucune => 'Aucune séance';

	/// fr: '1 séance'
	String get une => '1 séance';

	/// fr: '{n} séances'
	String plusieurs({required Object n}) => '${n} séances';
}

// Path: historique.filtres
class Traductions$historique$filtres$fr {
	Traductions$historique$filtres$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Classe'
	String get classe => 'Classe';

	/// fr: 'Toutes les classes'
	String get toutesClasses => 'Toutes les classes';

	/// fr: 'Période'
	String get periode => 'Période';

	/// fr: 'Toute la période'
	String get toutePeriode => 'Toute la période';

	/// fr: '7 derniers jours'
	String get septJours => '7 derniers jours';

	/// fr: '30 derniers jours'
	String get trenteJours => '30 derniers jours';

	/// fr: '3 derniers mois'
	String get troisMois => '3 derniers mois';

	/// fr: 'Statut'
	String get statut => 'Statut';

	/// fr: 'Tous les statuts'
	String get tousStatuts => 'Tous les statuts';
}

// Path: historique.etat
class Traductions$historique$etat$fr {
	Traductions$historique$etat$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Présence'
	String get presence => 'Présence';

	/// fr: 'Retard {minutes} min'
	String retard({required Object minutes}) => 'Retard ${minutes} min';

	/// fr: 'Retard'
	String get retardSansDuree => 'Retard';

	/// fr: 'En cours de vérification'
	String get verification => 'En cours de vérification';

	/// fr: 'Cours annulé'
	String get annule => 'Cours annulé';

	/// fr: 'Cours non tenu'
	String get nonTenu => 'Cours non tenu';
}

// Path: historique.seances
class Traductions$historique$seances$fr {
	Traductions$historique$seances$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Aucune séance passée'
	String get videTitre => 'Aucune séance passée';

	/// fr: 'Les séances passées de {prenom} s'afficheront ici.'
	String videPhrase({required Object prenom}) => 'Les séances passées de ${prenom} s\'afficheront ici.';

	/// fr: 'Les séances passées des profils élèves s'afficheront ici.'
	String get videPhraseFoyer => 'Les séances passées des profils élèves s\'afficheront ici.';

	/// fr: 'Aucune séance ne correspond'
	String get filtreVideTitre => 'Aucune séance ne correspond';

	/// fr: 'Changez les filtres pour retrouver les autres séances.'
	String get filtreVidePhrase => 'Changez les filtres pour retrouver les autres séances.';

	/// fr: 'Les {nombre} séances les plus récentes sont affichées.'
	String tronquee({required Object nombre}) => 'Les ${nombre} séances les plus récentes sont affichées.';

	/// fr: 'Séance du {date}, {classe}, {etat}'
	String ouvrir({required Object date, required Object classe, required Object etat}) => 'Séance du ${date}, ${classe}, ${etat}';
}

// Path: historique.observations
class Traductions$historique$observations$fr {
	Traductions$historique$observations$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Historique des observations indisponible'
	String get indisponibleTitre => 'Historique des observations indisponible';

	/// fr: 'Les visites enregistrées ne peuvent pas encore être lues dans l'application.'
	String get indisponiblePhrase => 'Les visites enregistrées ne peuvent pas encore être lues dans l\'application.';

	/// fr: 'Aucune observation'
	String get videTitre => 'Aucune observation';

	/// fr: 'Les visites que vous faites pendant les séances de {prenom} s'afficheront ici.'
	String videPhrase({required Object prenom}) => 'Les visites que vous faites pendant les séances de ${prenom} s\'afficheront ici.';

	/// fr: 'Vos visites pendant les séances s'afficheront ici.'
	String get videPhraseFoyer => 'Vos visites pendant les séances s\'afficheront ici.';

	/// fr: 'Aucune observation ne correspond'
	String get filtreVideTitre => 'Aucune observation ne correspond';

	/// fr: 'Changez les filtres pour retrouver les autres visites.'
	String get filtreVidePhrase => 'Changez les filtres pour retrouver les autres visites.';

	/// fr: '1 visite'
	String get visiteUne => '1 visite';

	/// fr: '{n} visites'
	String visites({required Object n}) => '${n} visites';

	/// fr: 'Durée non confirmée'
	String get dureeNonConfirmee => 'Durée non confirmée';

	/// fr: 'Terminée'
	String get terminee => 'Terminée';

	/// fr: 'Sortie non enregistrée'
	String get nonRefermee => 'Sortie non enregistrée';

	/// fr: 'Élève'
	String get eleveInconnu => 'Élève';

	/// fr: 'Seules les visites les plus récentes sont affichées.'
	String get tronquee => 'Seules les visites les plus récentes sont affichées.';

	/// fr: 'Observations du {date}, {classe}, {etat}'
	String ouvrir({required Object date, required Object classe, required Object etat}) => 'Observations du ${date}, ${classe}, ${etat}';
}

// Path: historique.seance
class Traductions$historique$seance$fr {
	Traductions$historique$seance$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Séance du {date}'
	String titreSansClasse({required Object date}) => 'Séance du ${date}';

	/// fr: 'La séance'
	String get blocSeance => 'La séance';

	/// fr: 'Présence de {prenom}'
	String blocPresence({required Object prenom}) => 'Présence de ${prenom}';

	/// fr: 'Date'
	String get date => 'Date';

	/// fr: 'Horaire'
	String get horaire => 'Horaire';

	/// fr: 'Durée prévue'
	String get dureePrevue => 'Durée prévue';

	/// fr: 'Classe'
	String get classe => 'Classe';

	/// fr: 'Enseignant'
	String get enseignant => 'Enseignant';

	/// fr: 'Présence'
	String get presence => 'Présence';

	/// fr: 'Arrivée'
	String get arrivee => 'Arrivée';

	/// fr: 'Interruption'
	String get interruption => 'Interruption';

	/// fr: 'La présence n'est pas encore confirmée pour cette séance.'
	String get verificationPhrase => 'La présence n\'est pas encore confirmée pour cette séance.';

	/// fr: 'La séance n'a pas eu lieu : ce n'est pas le fait de l'élève.'
	String get nonTenuPhrase => 'La séance n\'a pas eu lieu : ce n\'est pas le fait de l\'élève.';

	/// fr: 'La séance a été annulée.'
	String get annulePhrase => 'La séance a été annulée.';

	/// fr: 'Séance introuvable'
	String get introuvableTitre => 'Séance introuvable';

	/// fr: 'Cette séance ne figure pas dans l'historique de votre foyer.'
	String get introuvablePhrase => 'Cette séance ne figure pas dans l\'historique de votre foyer.';
}

// Path: historique.observation
class Traductions$historique$observation$fr {
	Traductions$historique$observation$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Observations du {date}'
	String titreSansClasse({required Object date}) => 'Observations du ${date}';

	/// fr: 'Résumé'
	String get blocResume => 'Résumé';

	/// fr: 'Visites'
	String get blocVisites => 'Visites';

	/// fr: 'Observateur'
	String get observateur => 'Observateur';

	/// fr: 'Vous'
	String get vous => 'Vous';

	/// fr: 'Élève'
	String get eleve => 'Élève';

	/// fr: 'Enseignant'
	String get enseignant => 'Enseignant';

	/// fr: 'Durée totale'
	String get dureeTotale => 'Durée totale';

	/// fr: 'Visite {n}'
	String visite({required Object n}) => 'Visite ${n}';

	/// fr: 'Entrée à {debut}'
	String plageOuverte({required Object debut}) => 'Entrée à ${debut}';

	/// fr: 'Visite terminée'
	String get terminee => 'Visite terminée';

	/// fr: 'Aucune visite pour cette séance'
	String get introuvableTitre => 'Aucune visite pour cette séance';

	/// fr: 'Aucune visite enregistrée ne correspond à cette séance.'
	String get introuvablePhrase => 'Aucune visite enregistrée ne correspond à cette séance.';
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

// Path: classe.entree
class Traductions$classe$entree$fr {
	Traductions$classe$entree$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Cours dans {duree}'
	String coursDans({required Object duree}) => 'Cours dans ${duree}';

	/// fr: 'Cours dans moins d'une minute'
	String get coursImminent => 'Cours dans moins d\'une minute';

	/// fr: 'Rejoindre'
	String get rejoindre => 'Rejoindre';

	/// fr: 'Rejoindre la séance de {classe}'
	String rejoindreLecteur({required Object classe}) => 'Rejoindre la séance de ${classe}';

	/// fr: 'La salle est ouverte. La séance commence dans {duree}.'
	String salleOuverte({required Object duree}) => 'La salle est ouverte. La séance commence dans ${duree}.';

	/// fr: 'La salle est ouverte. La séance commence dans moins d'une minute.'
	String get salleOuverteImminent => 'La salle est ouverte. La séance commence dans moins d\'une minute.';

	/// fr: 'Préparation en cours'
	String get preparation => 'Préparation en cours';

	/// fr: 'Vous êtes dans la salle. La séance commence dans {duree}.'
	String attente({required Object duree}) => 'Vous êtes dans la salle. La séance commence dans ${duree}.';

	/// fr: 'Vous êtes dans la salle. La séance commence dans moins d'une minute.'
	String get attenteImminent => 'Vous êtes dans la salle. La séance commence dans moins d\'une minute.';

	/// fr: 'Séance en direct'
	String get enDirect => 'Séance en direct';

	/// fr: 'Temps prévu écoulé'
	String get tempsEcoule => 'Temps prévu écoulé';

	/// fr: 'Séance terminée'
	String get terminee => 'Séance terminée';

	/// fr: 'Séance annulée'
	String get annulee => 'Séance annulée';

	/// fr: 'Aucune séance prévue'
	String get aucune => 'Aucune séance prévue';

	/// fr: 'Vous êtes hors ligne. La séance nécessite une connexion.'
	String get horsLigne => 'Vous êtes hors ligne. La séance nécessite une connexion.';

	/// fr: 'L'information sur la séance est indisponible pour l'instant.'
	String get indisponible => 'L\'information sur la séance est indisponible pour l\'instant.';

	/// fr: 'L'accès à la salle ne peut pas être vérifié pour le moment.'
	String get accesInverifiable => 'L\'accès à la salle ne peut pas être vérifié pour le moment.';

	/// fr: 'Réessayer'
	String get reessayer => 'Réessayer';

	/// fr: 'Chargement de la prochaine séance.'
	String get chargementSeance => 'Chargement de la prochaine séance.';

	/// fr: '{chapitre} · {pourcentage} %'
	String progressionValeur({required Object chapitre, required Object pourcentage}) => '${chapitre} · ${pourcentage} %';

	/// fr: 'Changement d'heure : le cours passera de {avant} à {apres}.'
	String dst({required Object avant, required Object apres}) => 'Changement d\'heure : le cours passera de ${avant} à ${apres}.';

	late final Traductions$classe$entree$annonce$fr annonce = Traductions$classe$entree$annonce$fr.internal(_root);
	late final Traductions$classe$entree$demo$fr demo = Traductions$classe$entree$demo$fr.internal(_root);
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

	/// fr: 'Le planning de la classe n'est pas encore relié à cet espace.'
	String get indisponible => 'Le planning de la classe n\'est pas encore relié à cet espace.';
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

// Path: classe.pageCatalogue
class Traductions$classe$pageCatalogue$fr {
	Traductions$classe$pageCatalogue$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Pour {prenom}'
	String pour({required Object prenom}) => 'Pour ${prenom}';

	/// fr: 'Classes proposées'
	String get proposees => 'Classes proposées';

	/// fr: 'Le choix de classe en ligne n'est pas encore ouvert.'
	String get indisponible => 'Le choix de classe en ligne n\'est pas encore ouvert.';

	/// fr: 'Aucune classe ne convient pour l'instant'
	String get aucune => 'Aucune classe ne convient pour l\'instant';

	/// fr: 'Aucune classe ouverte ne correspond au profil de {prenom} en ce moment.'
	String aucuneDetail({required Object prenom}) => 'Aucune classe ouverte ne correspond au profil de ${prenom} en ce moment.';

	/// fr: 'Ce profil n'est pas dans votre foyer'
	String get eleveInconnuTitre => 'Ce profil n\'est pas dans votre foyer';

	/// fr: 'Revenez à l'accueil et choisissez le profil élève concerné.'
	String get eleveInconnuPhrase => 'Revenez à l\'accueil et choisissez le profil élève concerné.';

	/// fr: 'Les jours et heures de cette classe ne sont pas encore affichés ici.'
	String get horairesAbsents => 'Les jours et heures de cette classe ne sont pas encore affichés ici.';

	/// fr: '{jour} à {heure} · {duree} min'
	String seanceHebdo({required Object jour, required Object heure, required Object duree}) => '${jour} à ${heure} · ${duree} min';

	/// fr: 'Heures de la classe ({fuseau})'
	String fuseauClasse({required Object fuseau}) => 'Heures de la classe (${fuseau})';

	/// fr: '1 place restante'
	String get placeUne => '1 place restante';

	/// fr: '{nombre} places restantes'
	String places({required Object nombre}) => '${nombre} places restantes';

	late final Traductions$classe$pageCatalogue$etat$fr etat = Traductions$classe$pageCatalogue$etat$fr.internal(_root);

	/// fr: 'Choisir cette classe'
	String get choisir => 'Choisir cette classe';

	/// fr: 'Rejoindre la liste d'attente'
	String get rejoindreAttente => 'Rejoindre la liste d\'attente';

	/// fr: 'Avant de choisir'
	String get precisionsTitre => 'Avant de choisir';

	/// fr: 'Une classe garde le même enseignant pour toutes ses séances.'
	String get precisionEnseignant => 'Une classe garde le même enseignant pour toutes ses séances.';

	/// fr: 'Les places affichées sont celles de l'académie au moment de la lecture.'
	String get precisionPlaces => 'Les places affichées sont celles de l\'académie au moment de la lecture.';

	/// fr: 'Rien n'est réservé avant votre confirmation.'
	String get precisionReserve => 'Rien n\'est réservé avant votre confirmation.';

	/// fr: 'Confirmer la classe'
	String get confirmerTitre => 'Confirmer la classe';

	/// fr: 'Vous inscrivez {prenom} dans cette classe.'
	String confirmerPhrase({required Object prenom}) => 'Vous inscrivez ${prenom} dans cette classe.';

	/// fr: 'Vous inscrivez {prenom} sur la liste d'attente de cette classe.'
	String confirmerAttentePhrase({required Object prenom}) => 'Vous inscrivez ${prenom} sur la liste d\'attente de cette classe.';

	/// fr: 'Même classe et même enseignant pour toutes les séances de la semaine : {enseignant}.'
	String memeEnseignant({required Object enseignant}) => 'Même classe et même enseignant pour toutes les séances de la semaine : ${enseignant}.';

	/// fr: 'Confirmer l'inscription'
	String get confirmer => 'Confirmer l\'inscription';

	/// fr: 'Confirmer la liste d'attente'
	String get confirmerAttente => 'Confirmer la liste d\'attente';

	/// fr: 'La réponse de l'académie n'est pas arrivée. Réessayer ne crée pas de seconde inscription.'
	String get envoiIncertain => 'La réponse de l\'académie n\'est pas arrivée. Réessayer ne crée pas de seconde inscription.';

	/// fr: 'L'inscription en ligne n'est pas encore ouverte : aucune place n'a été réservée.'
	String get envoiIndisponible => 'L\'inscription en ligne n\'est pas encore ouverte : aucune place n\'a été réservée.';

	late final Traductions$classe$pageCatalogue$resultat$fr resultat = Traductions$classe$pageCatalogue$resultat$fr.internal(_root);
}

// Path: enseignant.classes
class Traductions$enseignant$classes$fr {
	Traductions$enseignant$classes$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Classes'
	String get titre => 'Classes';

	/// fr: 'Aucune Classe attribuée'
	String get vide => 'Aucune Classe attribuée';

	/// fr: 'Les Classes confirmées apparaîtront ici.'
	String get videDetail => 'Les Classes confirmées apparaîtront ici.';

	/// fr: 'Vos Classes n'ont pas pu être lues. Réessayez dans un instant.'
	String get erreur => 'Vos Classes n\'ont pas pu être lues. Réessayez dans un instant.';

	/// fr: 'Chargement de vos Classes.'
	String get chargement => 'Chargement de vos Classes.';

	/// fr: 'Niveau {niveau}'
	String niveau({required Object niveau}) => 'Niveau ${niveau}';

	/// fr: '1 élève'
	String get eleveUn => '1 élève';

	/// fr: '{nombre} élèves'
	String eleves({required Object nombre}) => '${nombre} élèves';

	/// fr: 'Prochaine séance : {jour} à {heure}'
	String prochaine({required Object jour, required Object heure}) => 'Prochaine séance : ${jour} à ${heure}';

	/// fr: 'Aucune séance prévue'
	String get sansProchaine => 'Aucune séance prévue';

	/// fr: 'Remplacement'
	String get remplacement => 'Remplacement';

	/// fr: 'Un cahier de séance reste à valider'
	String get rappelCahier => 'Un cahier de séance reste à valider';

	/// fr: 'Cahier à valider'
	String get cahierAValider => 'Cahier à valider';
}

// Path: enseignant.eleve
class Traductions$enseignant$eleve$fr {
	Traductions$enseignant$eleve$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Fiche de {prenom}'
	String titre({required Object prenom}) => 'Fiche de ${prenom}';

	/// fr: 'Élèves'
	String get retour => 'Élèves';

	/// fr: 'Identifiant Académie : {id}'
	String identifiant({required Object id}) => 'Identifiant Académie : ${id}';

	/// fr: 'Photo de {prenom}'
	String photo({required Object prenom}) => 'Photo de ${prenom}';

	/// fr: 'Niveau'
	String get niveau => 'Niveau';

	/// fr: 'Objectif'
	String get objectif => 'Objectif';

	/// fr: 'Présence récente'
	String get presence => 'Présence récente';

	/// fr: 'Travail'
	String get travail => 'Travail';

	/// fr: 'Reprise à la {page}'
	String travailReprise({required Object page}) => 'Reprise à la ${page}';

	/// fr: 'Dernière séance'
	String get derniereSeance => 'Dernière séance';

	/// fr: 'Non renseigné'
	String get nonRenseigne => 'Non renseigné';

	/// fr: 'Signaler un besoin'
	String get signaler => 'Signaler un besoin';

	/// fr: 'Un besoin à remonter à l'académie, sans recopier le contexte.'
	String get signalerAide => 'Un besoin à remonter à l\'académie, sans recopier le contexte.';
}

// Path: enseignant.signalement
class Traductions$enseignant$signalement$fr {
	Traductions$enseignant$signalement$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Signaler un besoin'
	String get titre => 'Signaler un besoin';

	/// fr: 'Pour {prenom} · {classe}'
	String contexte({required Object prenom, required Object classe}) => 'Pour ${prenom} · ${classe}';

	/// fr: 'Catégorie'
	String get categorieTitre => 'Catégorie';

	late final Traductions$enseignant$signalement$categories$fr categories = Traductions$enseignant$signalement$categories$fr.internal(_root);

	/// fr: 'Détails internes'
	String get details => 'Détails internes';

	/// fr: 'Lu par l'équipe de l'académie seulement.'
	String get detailsAide => 'Lu par l\'équipe de l\'académie seulement.';

	/// fr: 'Résumé partageable'
	String get resume => 'Résumé partageable';

	/// fr: 'Peut être partagé avec la famille par l'académie.'
	String get resumeAide => 'Peut être partagé avec la famille par l\'académie.';

	/// fr: 'Les détails internes ne sont pas envoyés automatiquement à la famille.'
	String get notice => 'Les détails internes ne sont pas envoyés automatiquement à la famille.';

	/// fr: 'Choisissez une catégorie pour continuer.'
	String get choisirCategorie => 'Choisissez une catégorie pour continuer.';

	/// fr: 'Pour « Autre », dites en quelques mots de quoi il s'agit.'
	String get detailsRequis => 'Pour « Autre », dites en quelques mots de quoi il s\'agit.';

	/// fr: 'Envoyer le signalement'
	String get envoyer => 'Envoyer le signalement';

	/// fr: 'Démonstration : ce signalement est prêt, mais rien n'a été envoyé.'
	String get demoSucces => 'Démonstration : ce signalement est prêt, mais rien n\'a été envoyé.';

	/// fr: 'Dans l'application reliée, il partira vers l'équipe de l'académie.'
	String get demoSuccesDetail => 'Dans l\'application reliée, il partira vers l\'équipe de l\'académie.';

	/// fr: 'Fermer'
	String get fermer => 'Fermer';
}

// Path: enseignant.demo
class Traductions$enseignant$demo$fr {
	Traductions$enseignant$demo$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Démonstration enseignant'
	String get titre => 'Démonstration enseignant';

	/// fr: 'Données fictives, aucun envoi.'
	String get mention => 'Données fictives, aucun envoi.';

	/// fr: 'Choisissez un écran de Sayyid Ibrahim.'
	String get intro => 'Choisissez un écran de Sayyid Ibrahim.';

	/// fr: 'Écrans'
	String get ecrans => 'Écrans';

	/// fr: 'Situations'
	String get etats => 'Situations';

	/// fr: 'Journée ordinaire'
	String get etatNominal => 'Journée ordinaire';

	/// fr: 'Aucune séance'
	String get etatVide => 'Aucune séance';

	/// fr: 'Hors ligne'
	String get etatHorsLigne => 'Hors ligne';
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

	/// fr: 'Préparez votre espace avant votre première Classe.'
	String get sousTitre => 'Préparez votre espace avant votre première Classe.';

	/// fr: 'À compléter'
	String get aCompleter => 'À compléter';

	/// fr: '{fait} sur {total}'
	String compteur({required Object fait, required Object total}) => '${fait} sur ${total}';

	/// fr: 'Ajouter ma photo professionnelle'
	String get prerequisPhoto => 'Ajouter ma photo professionnelle';

	/// fr: 'Vérifier mes langues d'enseignement'
	String get prerequisLangues => 'Vérifier mes langues d\'enseignement';

	/// fr: 'Vérifier mon fuseau horaire'
	String get prerequisFuseau => 'Vérifier mon fuseau horaire';

	/// fr: 'Ajouter ma photo'
	String get ctaPhoto => 'Ajouter ma photo';

	/// fr: 'Vérifier mes informations'
	String get ctaInformations => 'Vérifier mes informations';

	/// fr: 'Voir ma journée'
	String get ctaJournee => 'Voir ma journée';

	/// fr: 'Deux choses à ne pas découvrir en cours de route'
	String get rappels => 'Deux choses à ne pas découvrir en cours de route';

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

// Path: enseignant.photo
class Traductions$enseignant$photo$fr {
	Traductions$enseignant$photo$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Photo professionnelle'
	String get titre => 'Photo professionnelle';

	/// fr: 'Cette photo peut être visible par les élèves et les familles de vos Classes.'
	String get aide => 'Cette photo peut être visible par les élèves et les familles de vos Classes.';

	/// fr: 'N'utilisez pas votre pièce d'identité.'
	String get notice => 'N\'utilisez pas votre pièce d\'identité.';

	/// fr: 'Choisir une photo'
	String get choisir => 'Choisir une photo';

	/// fr: 'Utiliser cette photo'
	String get utiliser => 'Utiliser cette photo';

	/// fr: 'Remplacer la photo'
	String get remplacer => 'Remplacer la photo';

	/// fr: 'Choisir une autre photo'
	String get autre => 'Choisir une autre photo';

	/// fr: 'Changer la photo'
	String get changer => 'Changer la photo';

	/// fr: 'Votre photo publique'
	String get alternatif => 'Votre photo publique';

	/// fr: 'La photo est enregistrée.'
	String get succes => 'La photo est enregistrée.';

	/// fr: 'La photo n'a pas pu être envoyée. Rien n'a changé sur le profil.'
	String get echec => 'La photo n\'a pas pu être envoyée. Rien n\'a changé sur le profil.';

	/// fr: 'La photo n'a pas pu être ouverte. Vérifiez l'accès aux photos de l'appareil, puis réessayez.'
	String get selectionEchec => 'La photo n\'a pas pu être ouverte. Vérifiez l\'accès aux photos de l\'appareil, puis réessayez.';

	/// fr: 'Vous êtes hors ligne. La photo pourra être envoyée quand la connexion reviendra.'
	String get horsLigne => 'Vous êtes hors ligne. La photo pourra être envoyée quand la connexion reviendra.';
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

	/// fr: 'Aujourd'hui'
	String get titre => 'Aujourd\'hui';

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

	/// fr: 'Une partie de la journée n'a pas pu être lue : prières ou pauses peuvent manquer.'
	String get erreurPartielle => 'Une partie de la journée n\'a pas pu être lue : prières ou pauses peuvent manquer.';

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

	/// fr: 'Prochaine séance'
	String get prochaineSeance => 'Prochaine séance';

	/// fr: 'Ma journée'
	String get maJournee => 'Ma journée';

	/// fr: 'À terminer'
	String get aTerminer => 'À terminer';

	/// fr: 'Le cahier aide vos élèves et vous permet d'ajuster le prochain cours.'
	String get aTerminerAide => 'Le cahier aide vos élèves et vous permet d\'ajuster le prochain cours.';

	/// fr: 'Des cahiers attendent d'être terminés'
	String get rappelCahier => 'Des cahiers attendent d\'être terminés';

	/// fr: 'Cahier {classe}'
	String cahierLigne({required Object classe}) => 'Cahier ${classe}';

	/// fr: 'Séance du {jour} {numero} {mois} à {heure}'
	String cahierDetail({required Object jour, required Object numero, required Object mois, required Object heure}) => 'Séance du ${jour} ${numero} ${mois} à ${heure}';

	/// fr: 'Alertes utiles'
	String get alertesUtiles => 'Alertes utiles';

	/// fr: 'Heure'
	String get heure => 'Heure';

	/// fr: 'Élèves'
	String get eleves => 'Élèves';

	/// fr: 'Classe'
	String get classe => 'Classe';

	/// fr: 'Classe {classe}'
	String classeNommee({required Object classe}) => 'Classe ${classe}';

	/// fr: 'Préparer la séance'
	String get preparerSeance => 'Préparer la séance';

	/// fr: 'Préparer la séance {classe}'
	String preparerSeanceLecteur({required Object classe}) => 'Préparer la séance ${classe}';

	/// fr: 'Dernière séance'
	String get derniereSeance => 'Dernière séance';

	/// fr: 'Rejoindre la salle'
	String get rejoindreSalle => 'Rejoindre la salle';

	/// fr: 'Rejoindre la salle de la Classe {classe}'
	String rejoindreSalleLecteur({required Object classe}) => 'Rejoindre la salle de la Classe ${classe}';

	/// fr: 'Remplir le cahier de transmission'
	String get remplirCahier => 'Remplir le cahier de transmission';

	/// fr: 'Remplir le cahier de transmission de la Classe {classe}'
	String remplirCahierLecteur({required Object classe}) => 'Remplir le cahier de transmission de la Classe ${classe}';

	/// fr: 'Obligatoire : le cahier {classe} se remplit à la fin de chaque séance.'
	String cahierObligatoire({required Object classe}) => 'Obligatoire : le cahier ${classe} se remplit à la fin de chaque séance.';

	/// fr: 'Voir le cahier {classe}'
	String voirCahier({required Object classe}) => 'Voir le cahier ${classe}';

	/// fr: 'Voir le cahier de transmission de la Classe {classe}'
	String voirCahierLecteur({required Object classe}) => 'Voir le cahier de transmission de la Classe ${classe}';

	/// fr: 'Voir la Classe'
	String get voirClasse => 'Voir la Classe';

	/// fr: 'Voir la Classe {classe}'
	String voirClasseLecteur({required Object classe}) => 'Voir la Classe ${classe}';

	/// fr: 'Aucune séance à venir'
	String get aucuneSeance => 'Aucune séance à venir';

	/// fr: 'Vos prochaines séances apparaîtront ici.'
	String get aucuneSeanceDetail => 'Vos prochaines séances apparaîtront ici.';

	/// fr: '{jour} {numero} {mois}'
	String date({required Object jour, required Object numero, required Object mois}) => '${jour} ${numero} ${mois}';

	late final Traductions$enseignant$journee$absence$fr absence = Traductions$enseignant$journee$absence$fr.internal(_root);
	late final Traductions$enseignant$journee$remplacement$fr remplacement = Traductions$enseignant$journee$remplacement$fr.internal(_root);
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

	/// fr: 'Ouvrez le Coran pour montrer une page à votre Classe.'
	String get rienInvitation => 'Ouvrez le Coran pour montrer une page à votre Classe.';

	/// fr: 'Vous n'êtes pas encore dans la salle'
	String get attenteSalle => 'Vous n\'êtes pas encore dans la salle';

	/// fr: 'Les commandes de présentation s'ouvrent dès que le cours est connecté.'
	String get attenteSalleDetail => 'Les commandes de présentation s\'ouvrent dès que le cours est connecté.';

	/// fr: 'le tour de page peut arriver en retard chez votre Classe'
	String get lienFaibleDetail => 'le tour de page peut arriver en retard chez votre Classe';

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

	/// fr: 'Ce que votre Classe voit n'a pas changé. Réessayez.'
	String get souratesIndisponiblesDetail => 'Ce que votre Classe voit n\'a pas changé. Réessayez.';

	/// fr: 'Cette page n'a pas pu être lue'
	String get pageIndisponible => 'Cette page n\'a pas pu être lue';

	/// fr: 'Le texte n'est pas arrivé jusqu'ici. Votre Classe voit toujours la page présentée.'
	String get pageIndisponibleDetail => 'Le texte n\'est pas arrivé jusqu\'ici. Votre Classe voit toujours la page présentée.';

	/// fr: 'Le texte du Coran n'est pas installé'
	String get corpusAbsent => 'Le texte du Coran n\'est pas installé';

	/// fr: 'Il n'y a rien à présenter.'
	String get corpusAbsentDetail => 'Il n\'y a rien à présenter.';

	/// fr: 'Ce verset n'a pas pu être situé dans le mushaf. Rien n'a été envoyé à votre Classe.'
	String get echecPresentation => 'Ce verset n\'a pas pu être situé dans le mushaf. Rien n\'a été envoyé à votre Classe.';

	/// fr: 'Votre accès à cette séance ne permet pas de présenter un contenu.'
	String get sansDroitPresentation => 'Votre accès à cette séance ne permet pas de présenter un contenu.';
}

// Path: enseignant.cahier
class Traductions$enseignant$cahier$fr {
	Traductions$enseignant$cahier$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Cahier de séance'
	String get titre => 'Cahier de séance';

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

	/// fr: 'Valider le cahier'
	String get valider => 'Valider le cahier';

	/// fr: 'Tout est conforme, valider'
	String get validerTout => 'Tout est conforme, valider';

	/// fr: 'Déposer sans le constat'
	String get validerSansConstat => 'Déposer sans le constat';

	/// fr: 'Retour à ma journée'
	String get retourJournee => 'Retour à ma journée';

	/// fr: 'Le constat n'a pas pu être déduit'
	String get vide => 'Le constat n\'a pas pu être déduit';

	/// fr: 'Aucune présence et aucun événement n'ont été relevés pour cette séance. Vous pouvez tout de même déposer le cahier.'
	String get videDetail => 'Aucune présence et aucun événement n\'ont été relevés pour cette séance. Vous pouvez tout de même déposer le cahier.';

	/// fr: 'Le constat n'a pas pu être lu.'
	String get erreur => 'Le constat n\'a pas pu être lu.';

	/// fr: 'Réessayez, ou déposez le cahier sans le constat.'
	String get erreurDetail => 'Réessayez, ou déposez le cahier sans le constat.';

	/// fr: 'Le cahier n'a pas pu être enregistré. Réessayez.'
	String get echecEnvoi => 'Le cahier n\'a pas pu être enregistré. Réessayez.';

	/// fr: 'Le cahier de cette séance est déjà déposé.'
	String get dejaDepose => 'Le cahier de cette séance est déjà déposé.';

	/// fr: 'Un cahier ne se dépose qu'une fois, et il ne se supprime pas d'ici.'
	String get dejaDeposeDetail => 'Un cahier ne se dépose qu\'une fois, et il ne se supprime pas d\'ici.';

	/// fr: 'Cahier enregistré'
	String get depose => 'Cahier enregistré';

	/// fr: 'L'académie l'a reçu.'
	String get deposeDetail => 'L\'académie l\'a reçu.';

	/// fr: 'En attente d'envoi'
	String get enFileTitre => 'En attente d\'envoi';

	/// fr: 'Le cahier sera envoyé lorsque la connexion reviendra.'
	String get enFile => 'Le cahier sera envoyé lorsque la connexion reviendra.';

	/// fr: 'Le cahier sera envoyé lorsque la connexion reviendra.'
	String get enFileDetail => 'Le cahier sera envoyé lorsque la connexion reviendra.';

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

	/// fr: 'Devoir à faire'
	String get travailMaison => 'Devoir à faire';

	/// fr: 'Ajustez la suggestion, ou laissez-la telle quelle.'
	String get travailMaisonDetail => 'Ajustez la suggestion, ou laissez-la telle quelle.';

	/// fr: 'La suite pour cet élève'
	String get suite => 'La suite pour cet élève';

	/// fr: 'Continuer'
	String get suiteContinuer => 'Continuer';

	/// fr: 'Renforcer'
	String get suiteRenforcer => 'Renforcer';

	/// fr: 'Suspendre le nouveau'
	String get suspendreNouveau => 'Suspendre le nouveau';

	/// fr: 'Devoir précédent : {devoir}'
	String devoirPrecedent({required Object devoir}) => 'Devoir précédent : ${devoir}';

	/// fr: 'Réviser la sourate {sourate}, versets {debut} à {fin}.'
	String devoirPlage({required Object sourate, required Object debut, required Object fin}) => 'Réviser la sourate ${sourate}, versets ${debut} à ${fin}.';

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

	/// fr: 'Le motif est obligatoire.'
	String get exceptionMotifRequis => 'Le motif est obligatoire.';

	/// fr: 'Enregistrement…'
	String get exceptionEnCours => 'Enregistrement…';

	/// fr: 'Exception consignée. Elle partira avec le cahier.'
	String get exceptionSucces => 'Exception consignée. Elle partira avec le cahier.';

	/// fr: 'L'exception n'a pas pu être consignée.'
	String get exceptionErreur => 'L\'exception n\'a pas pu être consignée.';

	/// fr: 'Sans réseau, une exception ne peut pas être confirmée. Le cahier, lui, part quand même.'
	String get exceptionHorsLigne => 'Sans réseau, une exception ne peut pas être confirmée. Le cahier, lui, part quand même.';

	/// fr: 'À valider'
	String get aValider => 'À valider';

	/// fr: 'Présents {nombre}'
	String statutPresents({required Object nombre}) => 'Présents ${nombre}';

	/// fr: 'Absents {nombre}'
	String statutAbsents({required Object nombre}) => 'Absents ${nombre}';

	/// fr: 'En retard {nombre}'
	String statutEnRetard({required Object nombre}) => 'En retard ${nombre}';

	/// fr: 'Performance'
	String get performance => 'Performance';

	/// fr: 'Faiblesses'
	String get faiblesses => 'Faiblesses';

	/// fr: 'Où la Classe s'est arrêtée'
	String get reprise => 'Où la Classe s\'est arrêtée';

	/// fr: 'C'est la position de reprise d'un remplaçant.'
	String get repriseDetail => 'C\'est la position de reprise d\'un remplaçant.';

	/// fr: 'Sourate {sourate}, verset {verset}'
	String repriseProposee({required Object sourate, required Object verset}) => 'Sourate ${sourate}, verset ${verset}';

	/// fr: 'Indiquez où la Classe s'est arrêtée : un remplaçant reprendra ici.'
	String get repriseRequise => 'Indiquez où la Classe s\'est arrêtée : un remplaçant reprendra ici.';

	/// fr: 'Ce que vous écrivez ici engage votre parole. Les hommes ne peuvent pas le vérifier, mais Allah voit tout.'
	String get integrite => 'Ce que vous écrivez ici engage votre parole. Les hommes ne peuvent pas le vérifier, mais Allah voit tout.';

	/// fr: 'Corriger le cahier'
	String get corriger => 'Corriger le cahier';

	/// fr: 'Corrigé le {date}'
	String corrigeLe({required Object date}) => 'Corrigé le ${date}';
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

	/// fr: 'Vous pouvez enseigner et déclarer vos heures.'
	String get statutValideDetail => 'Vous pouvez enseigner et déclarer vos heures.';

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

	/// fr: 'Nous n'avons pas pu lire votre statut.'
	String get statutInconnuDetail => 'Nous n\'avons pas pu lire votre statut.';

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

	/// fr: 'Ces pièces sont en lecture seule.'
	String get contratLectureSeule => 'Ces pièces sont en lecture seule.';

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

	/// fr: 'Vous n'avez proposé aucune heure. Sans créneau, aucune Classe ne peut vous être proposée.'
	String get aucuneHeure => 'Vous n\'avez proposé aucune heure. Sans créneau, aucune Classe ne peut vous être proposée.';

	/// fr: '{heure} enregistré'
	String heureEnregistree({required Object heure}) => '${heure} enregistré';

	/// fr: '{heure} retiré'
	String heureRetiree({required Object heure}) => '${heure} retiré';

	/// fr: '{heure} retiré. La séance déjà attribuée sur cette heure continue : demandez une réaffectation pour l'arrêter.'
	String retraitEngage({required Object heure}) => '${heure} retiré. La séance déjà attribuée sur cette heure continue : demandez une réaffectation pour l\'arrêter.';

	/// fr: 'Vos heures n'ont pas pu être lues'
	String get grilleErreur => 'Vos heures n\'ont pas pu être lues';

	/// fr: 'Les heures que vous avez déjà posées ne sont pas perdues.'
	String get grilleErreurDetail => 'Les heures que vous avez déjà posées ne sont pas perdues.';

	/// fr: 'Sans réseau, vos heures restent consultables mais ne peuvent pas être modifiées.'
	String get horsLigneGrille => 'Sans réseau, vos heures restent consultables mais ne peuvent pas être modifiées.';

	/// fr: 'Vous avez déjà une Classe sur {heures}. Retirer cette heure ne met pas fin à la séance : il faut une réaffectation.'
	String heureEngagee({required Object heures}) => 'Vous avez déjà une Classe sur ${heures}. Retirer cette heure ne met pas fin à la séance : il faut une réaffectation.';

	/// fr: 'Vous avez déjà une Classe sur {heures}. Retirer ces heures ne met pas fin aux séances : il faut une réaffectation.'
	String heuresEngagees({required Object heures}) => 'Vous avez déjà une Classe sur ${heures}. Retirer ces heures ne met pas fin aux séances : il faut une réaffectation.';

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

	/// fr: 'Mes disponibilités'
	String get mesDisponibilites => 'Mes disponibilités';

	/// fr: 'Ajouter un créneau'
	String get ajouterCreneau => 'Ajouter un créneau';

	/// fr: '{heure} h'
	String heure({required Object heure}) => '${heure} h';

	/// fr: 'Classes disponibles'
	String get classesDisponibles => 'Classes disponibles';

	/// fr: 'Disponible'
	String get etatDisponible => 'Disponible';

	/// fr: 'En attente de validation'
	String get etatEnAttente => 'En attente de validation';

	/// fr: 'Limite de charge atteinte'
	String get etatLimite => 'Limite de charge atteinte';

	/// fr: 'Votre charge actuelle ne permet pas de réserver une Classe supplémentaire.'
	String get limiteDetail => 'Votre charge actuelle ne permet pas de réserver une Classe supplémentaire.';

	/// fr: 'Aucune Classe compatible pour le moment'
	String get aucuneClasse => 'Aucune Classe compatible pour le moment';

	/// fr: 'Modifiez vos disponibilités si votre emploi du temps a changé.'
	String get aucuneClasseDetail => 'Modifiez vos disponibilités si votre emploi du temps a changé.';

	/// fr: 'Réserver cette Classe'
	String get reserver => 'Réserver cette Classe';

	/// fr: 'Votre demande a été transmise.'
	String get demandeTransmise => 'Votre demande a été transmise.';

	/// fr: 'Elle apparaîtra dans vos Classes après confirmation.'
	String get demandeTransmiseDetail => 'Elle apparaîtra dans vos Classes après confirmation.';

	/// fr: 'Confirmer cette Classe ?'
	String get confirmerTitre => 'Confirmer cette Classe ?';

	/// fr: 'Confirmer cette Classe'
	String get confirmer => 'Confirmer cette Classe';

	/// fr: 'Revenir'
	String get revenir => 'Revenir';

	/// fr: 'Niveau'
	String get cleNiveau => 'Niveau';

	/// fr: 'Langue'
	String get cleLangue => 'Langue';

	/// fr: 'Récurrence'
	String get cleRecurrence => 'Récurrence';

	/// fr: 'Fuseau de référence'
	String get cleFuseau => 'Fuseau de référence';

	/// fr: 'Heure locale'
	String get cleHeureLocale => 'Heure locale';

	/// fr: 'Durée'
	String get cleDuree => 'Durée';

	/// fr: '{minutes} min'
	String duree({required Object minutes}) => '${minutes} min';
}

// Path: enseignant.ficheGroupe
class Traductions$enseignant$ficheGroupe$fr {
	Traductions$enseignant$ficheGroupe$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: '{jour} à {heure}, chaque semaine'
	String creneauHebdo({required Object jour, required Object heure}) => '${jour} à ${heure}, chaque semaine';

	/// fr: 'Aucun élève dans cette Classe'
	String get aucunMembre => 'Aucun élève dans cette Classe';

	/// fr: 'L'administration compose les Classes : celle-ci n'a pas encore d'élève.'
	String get aucunMembreDetail => 'L\'administration compose les Classes : celle-ci n\'a pas encore d\'élève.';

	/// fr: 'Cette Classe n'a pas pu être lue. Réessayez dans un instant.'
	String get erreur => 'Cette Classe n\'a pas pu être lue. Réessayez dans un instant.';

	/// fr: 'Cette Classe n'est pas l'une des vôtres'
	String get introuvable => 'Cette Classe n\'est pas l\'une des vôtres';

	/// fr: 'Elle a peut-être été clôturée, ou elle appartient à un autre enseignant.'
	String get introuvableDetail => 'Elle a peut-être été clôturée, ou elle appartient à un autre enseignant.';

	/// fr: 'Ouvrir la revue de la Classe'
	String get revue => 'Ouvrir la revue de la Classe';

	/// fr: 'Élèves'
	String get elevesTitre => 'Élèves';

	/// fr: 'À préparer'
	String get preparationTitre => 'À préparer';

	/// fr: 'Support prévu'
	String get supportPrevu => 'Support prévu';

	/// fr: 'Position de reprise'
	String get positionReprise => 'Position de reprise';

	/// fr: 'Objectif'
	String get objectif => 'Objectif';

	/// fr: 'Aucune préparation renseignée pour cette séance.'
	String get preparationVide => 'Aucune préparation renseignée pour cette séance.';

	/// fr: 'Supports récents'
	String get supportsTitre => 'Supports récents';

	/// fr: 'Reprise : {page}'
	String repriseEleve({required Object page}) => 'Reprise : ${page}';

	/// fr: 'Dernier point : {texte}'
	String dernierPoint({required Object texte}) => 'Dernier point : ${texte}';

	/// fr: 'Chargement de la Classe.'
	String get chargementClasse => 'Chargement de la Classe.';

	/// fr: 'Ressources récentes'
	String get ressourcesTitre => 'Ressources récentes';

	/// fr: 'Progression de la Classe'
	String get progressionTitre => 'Progression de la Classe';

	/// fr: 'Présence régulière'
	String get indicateurRegulier => 'Présence régulière';

	/// fr: 'À renforcer'
	String get indicateurARenforcer => 'À renforcer';

	/// fr: 'Absence récente'
	String get indicateurAbsence => 'Absence récente';
}

// Path: enseignant.revue
class Traductions$enseignant$revue$fr {
	Traductions$enseignant$revue$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Revue de la Classe'
	String get titre => 'Revue de la Classe';

	/// fr: 'Revue de la Classe {classe}'
	String titreClasse({required Object classe}) => 'Revue de la Classe ${classe}';

	/// fr: 'Rien ne demande votre attention.'
	String get aucuneAnomalie => 'Rien ne demande votre attention.';

	/// fr: 'La revue n'a pas pu être lue.'
	String get erreur => 'La revue n\'a pas pu être lue.';

	/// fr: 'Cette Classe n'est peut-être pas la vôtre, ou la lecture a échoué.'
	String get erreurDetail => 'Cette Classe n\'est peut-être pas la vôtre, ou la lecture a échoué.';

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

// Path: controleur.historique
class Traductions$controleur$historique$fr {
	Traductions$controleur$historique$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Historique'
	String get titre => 'Historique';

	/// fr: 'Cet écran est en préparation.'
	String get provisoire => 'Cet écran est en préparation.';
}

// Path: controleur.compteRendu
class Traductions$controleur$compteRendu$fr {
	Traductions$controleur$compteRendu$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Compte rendu'
	String get titre => 'Compte rendu';

	/// fr: 'Cet écran est en préparation.'
	String get provisoire => 'Cet écran est en préparation.';

	/// fr: 'Revenir au contrôle'
	String get revenir => 'Revenir au contrôle';

	/// fr: '{classe} · {heure}'
	String sousTitre({required Object classe, required Object heure}) => '${classe} · ${heure}';

	/// fr: 'Faits automatiques'
	String get faits => 'Faits automatiques';

	/// fr: 'Faits automatiques, repliés'
	String get faitsReplies => 'Faits automatiques, repliés';

	/// fr: 'Faits automatiques, dépliés'
	String get faitsDeplies => 'Faits automatiques, dépliés';

	/// fr: 'Lecture des faits de la visite en cours.'
	String get faitsChargement => 'Lecture des faits de la visite en cours.';

	/// fr: 'Les faits de la visite ne sont pas encore disponibles.'
	String get faitsAbsents => 'Les faits de la visite ne sont pas encore disponibles.';

	/// fr: 'Heure prévue'
	String get cleHoraire => 'Heure prévue';

	/// fr: '{debut} à {fin}'
	String horaire({required Object debut, required Object fin}) => '${debut} à ${fin}';

	/// fr: 'Début réel'
	String get cleDebutReel => 'Début réel';

	/// fr: '{heure}, {minutes} min de retard'
	String debutRetard({required Object heure, required Object minutes}) => '${heure}, ${minutes} min de retard';

	/// fr: '{heure}, à l'heure'
	String debutALHeure({required Object heure}) => '${heure}, à l\'heure';

	/// fr: 'Fin'
	String get cleFin => 'Fin';

	/// fr: 'En cours'
	String get enCours => 'En cours';

	/// fr: 'Élèves présents'
	String get clePresents => 'Élèves présents';

	/// fr: '{presents} sur {attendus}'
	String presents({required Object presents, required Object attendus}) => '${presents} sur ${attendus}';

	/// fr: 'Reconnexions'
	String get cleReconnexions => 'Reconnexions';

	/// fr: 'Avez-vous quelque chose à signaler ?'
	String get question => 'Avez-vous quelque chose à signaler ?';

	/// fr: 'Rien à signaler'
	String get rienASignaler => 'Rien à signaler';

	/// fr: 'Ajouter une observation'
	String get ajouterObservation => 'Ajouter une observation';

	/// fr: 'Signaler un point important'
	String get pointImportant => 'Signaler un point important';

	/// fr: 'Envoyer le compte rendu'
	String get envoyer => 'Envoyer le compte rendu';

	/// fr: 'Plus tard'
	String get plusTard => 'Plus tard';

	/// fr: 'Ce compte rendu est transmis automatiquement à l'administration.'
	String get notice => 'Ce compte rendu est transmis automatiquement à l\'administration.';

	/// fr: 'Le compte rendu n'a pas pu être envoyé. Votre choix est gardé : réessayez dans un instant.'
	String get echec => 'Le compte rendu n\'a pas pu être envoyé. Votre choix est gardé : réessayez dans un instant.';

	/// fr: 'Compte rendu envoyé'
	String get envoyeTitre => 'Compte rendu envoyé';

	/// fr: 'Il est transmis à l'administration. Pour y revenir, ouvrez-le dans l'Historique et choisissez « Ajouter un complément ».'
	String get envoyePhrase => 'Il est transmis à l\'administration. Pour y revenir, ouvrez-le dans l\'Historique et choisissez « Ajouter un complément ».';

	/// fr: 'Écrire à l'administration'
	String get ecrireAdmin => 'Écrire à l\'administration';

	/// fr: 'Transmission de la visite à l'administration en cours.'
	String get visiteEnCours => 'Transmission de la visite à l\'administration en cours.';

	/// fr: 'La visite et ses faits sont transmis à l'administration.'
	String get visiteTransmise => 'La visite et ses faits sont transmis à l\'administration.';

	/// fr: 'La visite n'a pas encore pu être transmise à l'administration.'
	String get visiteEchec => 'La visite n\'a pas encore pu être transmise à l\'administration.';

	/// fr: 'Compte rendu à terminer'
	String get aTerminer => 'Compte rendu à terminer';

	/// fr: 'Reprendre le compte rendu'
	String get reprendre => 'Reprendre le compte rendu';
}

// Path: controleur.observation
class Traductions$controleur$observation$fr {
	Traductions$controleur$observation$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Vous signalez un point important : votre texte sera demandé.'
	String get important => 'Vous signalez un point important : votre texte sera demandé.';

	/// fr: 'Quelle est la nature de votre observation ?'
	String get questionNature => 'Quelle est la nature de votre observation ?';

	/// fr: 'Point positif'
	String get pointPositif => 'Point positif';

	/// fr: 'À suivre'
	String get aSuivre => 'À suivre';

	/// fr: 'Intervention Admin souhaitée'
	String get interventionAdmin => 'Intervention Admin souhaitée';

	/// fr: 'Quel domaine concerne-t-elle ?'
	String get questionDomaine => 'Quel domaine concerne-t-elle ?';

	/// fr: 'Pédagogie'
	String get pedagogie => 'Pédagogie';

	/// fr: 'Interaction avec les élèves'
	String get interaction => 'Interaction avec les élèves';

	/// fr: 'Gestion de la classe'
	String get gestionClasse => 'Gestion de la classe';

	/// fr: 'Respect du cadre'
	String get respectCadre => 'Respect du cadre';

	/// fr: 'Comportement / climat'
	String get climat => 'Comportement / climat';

	/// fr: 'Autre'
	String get autre => 'Autre';

	/// fr: 'Qui est concerné ?'
	String get questionPersonne => 'Qui est concerné ?';

	/// fr: 'Enseignant'
	String get enseignant => 'Enseignant';

	/// fr: 'Classe entière'
	String get classeEntiere => 'Classe entière';

	/// fr: 'Élève précis'
	String get elevePrecis => 'Élève précis';

	/// fr: 'Aucun participant précis'
	String get aucun => 'Aucun participant précis';

	/// fr: 'Choisissez l'élève dans la liste de la Classe.'
	String get questionEleve => 'Choisissez l\'élève dans la liste de la Classe.';

	/// fr: 'La liste des élèves n'est pas disponible pour le moment.'
	String get rosterIndisponible => 'La liste des élèves n\'est pas disponible pour le moment.';

	/// fr: 'Qu'avez-vous observé ?'
	String get questionTexte => 'Qu\'avez-vous observé ?';

	/// fr: 'Votre texte est nécessaire pour cette observation.'
	String get texteObligatoire => 'Votre texte est nécessaire pour cette observation.';

	/// fr: 'Ce texte est facultatif.'
	String get texteFacultatif => 'Ce texte est facultatif.';

	/// fr: 'Votre remarque'
	String get libelleTexte => 'Votre remarque';

	/// fr: 'Décrivez seulement ce que vous avez observé.'
	String get aideTexte => 'Décrivez seulement ce que vous avez observé.';

	/// fr: 'Écrivez ce que vous avez observé pour continuer.'
	String get texteRequis => 'Écrivez ce que vous avez observé pour continuer.';

	/// fr: 'Vérifiez votre observation avant l'envoi.'
	String get questionRecap => 'Vérifiez votre observation avant l\'envoi.';

	/// fr: 'Nature'
	String get cleNature => 'Nature';

	/// fr: 'Domaine'
	String get cleDomaine => 'Domaine';

	/// fr: 'Personne concernée'
	String get clePersonne => 'Personne concernée';

	/// fr: 'Remarque'
	String get cleTexte => 'Remarque';

	/// fr: 'Aucun texte'
	String get sansTexte => 'Aucun texte';

	/// fr: 'L'observation n'a pas pu être envoyée. Votre saisie est gardée : réessayez dans un instant.'
	String get echec => 'L\'observation n\'a pas pu être envoyée. Votre saisie est gardée : réessayez dans un instant.';
}

// Path: controleur.echanges
class Traductions$controleur$echanges$fr {
	Traductions$controleur$echanges$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Échanges'
	String get titre => 'Échanges';

	/// fr: '{classe} · {date}'
	String titreFil({required Object classe, required Object date}) => '${classe} · ${date}';

	/// fr: 'Dernière activité : {date}'
	String derniereActivite({required Object date}) => 'Dernière activité : ${date}';

	/// fr: 'Réponse reçue'
	String get reponseRecue => 'Réponse reçue';

	/// fr: 'En attente'
	String get enAttente => 'En attente';

	/// fr: 'Aucun échange avec l'administration pour le moment.'
	String get vide => 'Aucun échange avec l\'administration pour le moment.';

	/// fr: 'Contexte de la visite, joint automatiquement'
	String get contexte => 'Contexte de la visite, joint automatiquement';

	/// fr: 'Classe'
	String get cleClasse => 'Classe';

	/// fr: 'Date'
	String get cleDate => 'Date';

	/// fr: 'Heure'
	String get cleHeure => 'Heure';

	/// fr: 'Vous'
	String get auteurVous => 'Vous';

	/// fr: 'Administration'
	String get auteurAdmin => 'Administration';

	/// fr: 'Répondre à l'administration…'
	String get champ => 'Répondre à l\'administration…';

	/// fr: 'Répondre à l'administration'
	String get champLibelle => 'Répondre à l\'administration';

	/// fr: 'Envoyer'
	String get envoyer => 'Envoyer';

	/// fr: 'Écrivez un message pour pouvoir l'envoyer.'
	String get champVide => 'Écrivez un message pour pouvoir l\'envoyer.';

	/// fr: 'Envoi en cours.'
	String get enCours => 'Envoi en cours.';

	/// fr: 'Envoyé.'
	String get envoye => 'Envoyé.';

	/// fr: 'Ce message n'a pas pu être envoyé. Il est gardé : réessayez.'
	String get echec => 'Ce message n\'a pas pu être envoyé. Il est gardé : réessayez.';

	/// fr: 'Réessayer'
	String get reessayer => 'Réessayer';

	/// fr: 'Nouveau message de {auteur} : {texte}'
	String nouveauMessage({required Object auteur, required Object texte}) => 'Nouveau message de ${auteur} : ${texte}';
}

// Path: controleur.demo
class Traductions$controleur$demo$fr {
	Traductions$controleur$demo$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Démonstration contrôleur'
	String get titre => 'Démonstration contrôleur';

	/// fr: 'Données fictives, aucun envoi.'
	String get mention => 'Données fictives, aucun envoi.';

	/// fr: 'Choisissez un écran du contrôle et une situation de mission.'
	String get intro => 'Choisissez un écran du contrôle et une situation de mission.';

	/// fr: 'Aucune mission'
	String get etatAucune => 'Aucune mission';

	/// fr: 'Séance pas encore en direct'
	String get etatPasEncoreEnDirect => 'Séance pas encore en direct';

	/// fr: 'Séance en direct'
	String get etatEnDirect => 'Séance en direct';

	/// fr: 'Mission indisponible'
	String get etatIndisponible => 'Mission indisponible';

	/// fr: 'Espaces et accès'
	String get espaces => 'Espaces et accès';

	/// fr: 'Le même compte, plusieurs espaces : Enseignant ou Admin passent en Contrôle par Compte, puis Espaces.'
	String get espacesIntro => 'Le même compte, plusieurs espaces : Enseignant ou Admin passent en Contrôle par Compte, puis Espaces.';

	/// fr: 'Enseignant-Contrôleur, espace Contrôle'
	String get enseignantControle => 'Enseignant-Contrôleur, espace Contrôle';

	/// fr: 'Enseignant-Contrôleur, espace Enseignant'
	String get enseignantPrincipal => 'Enseignant-Contrôleur, espace Enseignant';

	/// fr: 'Admin-Contrôleur, espace Contrôle'
	String get adminControle => 'Admin-Contrôleur, espace Contrôle';

	/// fr: 'Admin-Contrôleur, espace Admin'
	String get adminPrincipal => 'Admin-Contrôleur, espace Admin';

	/// fr: 'Mission en cours, retour à l'espace principal'
	String get missionEnCours => 'Mission en cours, retour à l\'espace principal';

	/// fr: 'Accès révoqué pendant la navigation'
	String get accesRevoque => 'Accès révoqué pendant la navigation';

	/// fr: 'Enseignant sans capacité Contrôle'
	String get sansCapacite => 'Enseignant sans capacité Contrôle';

	/// fr: 'Compte rendu, mission devenue indisponible'
	String get compteRenduIndisponible => 'Compte rendu, mission devenue indisponible';
}

// Path: controleur.acces
class Traductions$controleur$acces$fr {
	Traductions$controleur$acces$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Votre accès au contrôle n'est plus actif.'
	String get revoque => 'Votre accès au contrôle n\'est plus actif.';

	/// fr: 'Revenir à mon espace'
	String get revenir => 'Revenir à mon espace';
}

// Path: controleur.controle
class Traductions$controleur$controle$fr {
	Traductions$controleur$controle$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Contrôle'
	String get titre => 'Contrôle';

	/// fr: 'Votre prochaine mission'
	String get mission => 'Votre prochaine mission';

	/// fr: 'Commencer le contrôle'
	String get commencer => 'Commencer le contrôle';

	/// fr: 'Aucun contrôle n'est à réaliser pour le moment.'
	String get vide => 'Aucun contrôle n\'est à réaliser pour le moment.';

	/// fr: 'Rewayah vous proposera une mission lorsqu'une séance compatible sera disponible.'
	String get videAide => 'Rewayah vous proposera une mission lorsqu\'une séance compatible sera disponible.';

	/// fr: 'Cette mission n'est plus disponible.'
	String get indisponible => 'Cette mission n\'est plus disponible.';

	/// fr: 'Le contrôle s'ouvrira dès que la séance sera en direct.'
	String get attente => 'Le contrôle s\'ouvrira dès que la séance sera en direct.';

	/// fr: 'Visite en mode incognito : votre présence n'est pas annoncée à l'enseignant.'
	String get incognito => 'Visite en mode incognito : votre présence n\'est pas annoncée à l\'enseignant.';

	/// fr: '{debut} à {fin}'
	String horaire({required Object debut, required Object fin}) => '${debut} à ${fin}';

	/// fr: '{minutes} min prévues'
	String duree({required Object minutes}) => '${minutes} min prévues';

	/// fr: '(one) {{n} élève} (other) {{n} élèves}'
	String eleves({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n,
		one: '${n} élève',
		other: '${n} élèves',
	);

	/// fr: 'Lecture de votre mission en cours.'
	String get chargement => 'Lecture de votre mission en cours.';

	/// fr: 'Votre mission n'a pas pu être lue. Réessayez dans un instant.'
	String get erreur => 'Votre mission n\'a pas pu être lue. Réessayez dans un instant.';
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
	late final Traductions$tc$observation$explication$fr explication = Traductions$tc$observation$explication$fr.internal(_root);
	late final Traductions$tc$observation$disponibilite$fr disponibilite = Traductions$tc$observation$disponibilite$fr.internal(_root);
	late final Traductions$tc$observation$connexion$fr connexion = Traductions$tc$observation$connexion$fr.internal(_root);
	late final Traductions$tc$observation$duree$fr duree = Traductions$tc$observation$duree$fr.internal(_root);
	late final Traductions$tc$observation$refus$fr refus = Traductions$tc$observation$refus$fr.internal(_root);
	late final Traductions$tc$observation$visite$fr visite = Traductions$tc$observation$visite$fr.internal(_root);
	late final Traductions$tc$observation$fin$fr fin = Traductions$tc$observation$fin$fr.internal(_root);
	late final Traductions$tc$observation$resultat$fr resultat = Traductions$tc$observation$resultat$fr.internal(_root);
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

// Path: adulte.nav
class Traductions$adulte$nav$fr {
	Traductions$adulte$nav$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Accueil'
	String get accueil => 'Accueil';

	/// fr: 'Ma classe'
	String get maClasse => 'Ma classe';

	/// fr: 'Coran'
	String get coran => 'Coran';

	/// fr: 'Mon espace'
	String get monEspace => 'Mon espace';
}

// Path: adulte.accueil
class Traductions$adulte$accueil$fr {
	Traductions$adulte$accueil$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Bonjour {prenom}'
	String salutation({required Object prenom}) => 'Bonjour ${prenom}';

	/// fr: 'Prochaine séance'
	String get prochaineSeance => 'Prochaine séance';

	/// fr: 'Mon parcours'
	String get parcours => 'Mon parcours';

	/// fr: 'Dernières séances'
	String get dernieresSeances => 'Dernières séances';

	/// fr: 'Ressources de la classe'
	String get ressources => 'Ressources de la classe';

	/// fr: 'Absence'
	String get absence => 'Absence';

	/// fr: 'Aucune classe pour le moment.'
	String get aucuneClasse => 'Aucune classe pour le moment.';

	/// fr: 'Votre prochaine séance s'affichera ici dès que votre classe sera ouverte.'
	String get aucuneClasseDetail => 'Votre prochaine séance s\'affichera ici dès que votre classe sera ouverte.';
}

// Path: adulte.maClasse
class Traductions$adulte$maClasse$fr {
	Traductions$adulte$maClasse$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'À propos de cette classe'
	String get aPropos => 'À propos de cette classe';

	/// fr: 'Participants'
	String get participants => 'Participants';

	/// fr: '{prenom} (vous)'
	String vous({required Object prenom}) => '${prenom} (vous)';

	/// fr: 'Ma progression dans cette classe'
	String get progression => 'Ma progression dans cette classe';

	/// fr: 'Votre classe, ses participants et ses ressources s'afficheront ici dès qu'elle sera ouverte.'
	String get aucuneClasseDetail => 'Votre classe, ses participants et ses ressources s\'afficheront ici dès qu\'elle sera ouverte.';
}

// Path: adulte.monEspace
class Traductions$adulte$monEspace$fr {
	Traductions$adulte$monEspace$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Élève adulte'
	String get role => 'Élève adulte';

	/// fr: 'Mon compte'
	String get monCompte => 'Mon compte';

	/// fr: 'Mes informations'
	String get informations => 'Mes informations';

	/// fr: 'Cours et accès'
	String get coursAcces => 'Cours et accès';

	/// fr: 'Ma classe, mes séances et mon accès'
	String get coursAccesLegende => 'Ma classe, mes séances et mon accès';

	/// fr: 'Paiements'
	String get paiements => 'Paiements';

	/// fr: 'Historique et reçus de mes paiements'
	String get paiementsLegende => 'Historique et reçus de mes paiements';

	/// fr: 'Mes accords'
	String get accords => 'Mes accords';

	/// fr: 'Accepter, refuser ou retirer chacun de vos accords'
	String get accordsLegende => 'Accepter, refuser ou retirer chacun de vos accords';

	/// fr: 'Méthode et adresse de connexion'
	String get securiteLegende => 'Méthode et adresse de connexion';

	late final Traductions$adulte$monEspace$pageAccords$fr pageAccords = Traductions$adulte$monEspace$pageAccords$fr.internal(_root);
	late final Traductions$adulte$monEspace$pageCoursAcces$fr pageCoursAcces = Traductions$adulte$monEspace$pageCoursAcces$fr.internal(_root);
}

// Path: adulte.provisoire
class Traductions$adulte$provisoire$fr {
	Traductions$adulte$provisoire$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Le Coran de votre espace élève s'affichera ici.'
	String get coran => 'Le Coran de votre espace élève s\'affichera ici.';

	/// fr: 'La page de votre forfait famille arrivera dans une prochaine étape.'
	String get forfaitFamille => 'La page de votre forfait famille arrivera dans une prochaine étape.';

	/// fr: 'L'ajout de votre famille arrivera dans une prochaine étape.'
	String get ajouterMaFamille => 'L\'ajout de votre famille arrivera dans une prochaine étape.';

	/// fr: 'Le détail de cette place arrivera dans une prochaine étape.'
	String get placeAdulte => 'Le détail de cette place arrivera dans une prochaine étape.';
}

// Path: adulte.famille
class Traductions$adulte$famille$fr {
	Traductions$adulte$famille$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Ajouter ma famille'
	String get ajouter => 'Ajouter ma famille';

	/// fr: 'Inscrivez vos enfants et invitez un conjoint ou une conjointe à rejoindre votre forfait famille.'
	String get ajouterLegende => 'Inscrivez vos enfants et invitez un conjoint ou une conjointe à rejoindre votre forfait famille.';

	/// fr: 'Ma famille'
	String get maFamille => 'Ma famille';

	/// fr: 'Forfait famille'
	String get forfaitFamille => 'Forfait famille';

	/// fr: 'Revenir à Mon espace'
	String get retourMonEspace => 'Revenir à Mon espace';

	/// fr: 'Titulaire du foyer'
	String get titulaire => 'Titulaire du foyer';

	/// fr: 'Paiements du foyer'
	String get paiementsFoyer => 'Paiements du foyer';

	late final Traductions$adulte$famille$place$fr place = Traductions$adulte$famille$place$fr.internal(_root);
}

// Path: adulte.invitation
class Traductions$adulte$invitation$fr {
	Traductions$adulte$invitation$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Un compte personnel pour elle'
	String get enteteElle => 'Un compte personnel pour elle';

	/// fr: 'Un compte personnel pour lui'
	String get enteteLui => 'Un compte personnel pour lui';

	/// fr: 'Votre conjointe utilisera son propre compte. Elle ne pourra pas gérer votre foyer ni les profils élèves que vous avez créés.'
	String get phraseElle => 'Votre conjointe utilisera son propre compte. Elle ne pourra pas gérer votre foyer ni les profils élèves que vous avez créés.';

	/// fr: 'Votre conjoint utilisera son propre compte. Il ne pourra pas gérer votre foyer ni les profils élèves que vous avez créés.'
	String get phraseLui => 'Votre conjoint utilisera son propre compte. Il ne pourra pas gérer votre foyer ni les profils élèves que vous avez créés.';

	/// fr: 'Prénom'
	String get prenom => 'Prénom';

	/// fr: 'Nom'
	String get nom => 'Nom';

	/// fr: 'Facultatif.'
	String get nomAide => 'Facultatif.';

	/// fr: 'Adresse e-mail'
	String get courriel => 'Adresse e-mail';

	/// fr: 'Nous l'utiliserons seulement pour lui envoyer cette invitation.'
	String get courrielAide => 'Nous l\'utiliserons seulement pour lui envoyer cette invitation.';

	/// fr: 'Indiquez son prénom.'
	String get prenomRequis => 'Indiquez son prénom.';

	/// fr: 'Indiquez son adresse e-mail.'
	String get courrielRequis => 'Indiquez son adresse e-mail.';

	/// fr: 'Vérifiez l'adresse e-mail : elle doit ressembler à nom@exemple.com.'
	String get courrielInvalide => 'Vérifiez l\'adresse e-mail : elle doit ressembler à nom@exemple.com.';

	/// fr: 'Vérifier l'invitation'
	String get verifier => 'Vérifier l\'invitation';

	/// fr: 'Vérifier et envoyer'
	String get verifierTitre => 'Vérifier et envoyer';

	/// fr: 'Relisez ces informations. L'invitation partira à cette adresse.'
	String get verifierPhrase => 'Relisez ces informations. L\'invitation partira à cette adresse.';

	/// fr: 'Non renseigné'
	String get nonRenseigne => 'Non renseigné';

	/// fr: 'Modifier'
	String get modifier => 'Modifier';

	/// fr: 'Envoyer l'invitation'
	String get envoyer => 'Envoyer l\'invitation';

	/// fr: 'Vous êtes hors ligne. L'invitation pourra partir quand la connexion reviendra.'
	String get horsLigne => 'Vous êtes hors ligne. L\'invitation pourra partir quand la connexion reviendra.';

	/// fr: 'L'invitation n'est pas partie'
	String get echecTitre => 'L\'invitation n\'est pas partie';

	/// fr: 'La connexion a été interrompue. Vos informations sont conservées : vous pouvez réessayer.'
	String get echecPhrase => 'La connexion a été interrompue. Vos informations sont conservées : vous pouvez réessayer.';

	/// fr: 'Cette invitation ne peut pas être envoyée'
	String get refusTitre => 'Cette invitation ne peut pas être envoyée';

	/// fr: 'Revenez à Ma famille pour voir l'état de la place.'
	String get refusPhrase => 'Revenez à Ma famille pour voir l\'état de la place.';

	/// fr: 'Invitation envoyée'
	String get envoyeeTitre => 'Invitation envoyée';

	/// fr: 'L'invitation est partie vers {courriel}.'
	String envoyeePhrase({required Object courriel}) => 'L\'invitation est partie vers ${courriel}.';

	/// fr: 'Revenir à Ma famille'
	String get revenirMaFamille => 'Revenir à Ma famille';

	/// fr: 'L'invitation attend sa réponse. Vous pouvez l'annuler tant qu'elle n'a pas été acceptée.'
	String get detailPhrase => 'L\'invitation attend sa réponse. Vous pouvez l\'annuler tant qu\'elle n\'a pas été acceptée.';

	/// fr: 'Annuler l'invitation'
	String get annuler => 'Annuler l\'invitation';

	/// fr: 'Annuler l'invitation de {prenom} ?'
	String annulerQuestion({required Object prenom}) => 'Annuler l\'invitation de ${prenom} ?';

	/// fr: 'Annuler cette invitation ?'
	String get annulerQuestionSansPrenom => 'Annuler cette invitation ?';

	/// fr: 'Vous êtes hors ligne. L'invitation pourra être annulée quand la connexion reviendra.'
	String get annulerHorsLigne => 'Vous êtes hors ligne. L\'invitation pourra être annulée quand la connexion reviendra.';

	/// fr: 'L'invitation ne pourra plus être acceptée. Vous pourrez en envoyer une nouvelle quand vous le souhaitez.'
	String get annulerConsequence => 'L\'invitation ne pourra plus être acceptée. Vous pourrez en envoyer une nouvelle quand vous le souhaitez.';

	/// fr: 'Garder l'invitation'
	String get garder => 'Garder l\'invitation';

	/// fr: 'L'invitation n'a pas été annulée'
	String get annulationEchecTitre => 'L\'invitation n\'a pas été annulée';

	/// fr: 'La connexion a été interrompue. L'invitation est toujours envoyée : vous pouvez réessayer.'
	String get annulationEchecPhrase => 'La connexion a été interrompue. L\'invitation est toujours envoyée : vous pouvez réessayer.';
}

// Path: adulte.demo
class Traductions$adulte$demo$fr {
	Traductions$adulte$demo$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Démonstration de l'élève adulte'
	String get titre => 'Démonstration de l\'élève adulte';

	/// fr: 'Les données sont fictives et rien n'est envoyé.'
	String get mention => 'Les données sont fictives et rien n\'est envoyé.';

	/// fr: 'Choisissez un écran, puis une situation du foyer Diallo.'
	String get intro => 'Choisissez un écran, puis une situation du foyer Diallo.';

	/// fr: 'Les écrans'
	String get ecrans => 'Les écrans';

	/// fr: 'Les situations du foyer'
	String get situations => 'Les situations du foyer';

	/// fr: 'Les variantes'
	String get variantes => 'Les variantes';

	/// fr: 'La titulaire est une femme, son conjoint est le second adulte.'
	String get titulaireFemme => 'La titulaire est une femme, son conjoint est le second adulte.';

	/// fr: 'Mon espace vu par la conjointe, second adulte du foyer.'
	String get vueConjointe => 'Mon espace vu par la conjointe, second adulte du foyer.';

	/// fr: 'Mon espace vu par le conjoint, second adulte du foyer.'
	String get vueConjoint => 'Mon espace vu par le conjoint, second adulte du foyer.';

	late final Traductions$adulte$demo$etats$fr etats = Traductions$adulte$demo$etats$fr.internal(_root);
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

// Path: salle.preparation.demo
class Traductions$salle$preparation$demo$fr {
	Traductions$salle$preparation$demo$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Préparation enseignant'
	String get section => 'Préparation enseignant';

	/// fr: 'Prêt'
	String get pret => 'Prêt';

	/// fr: 'Réseau faible'
	String get reseauFaible => 'Réseau faible';

	/// fr: 'Micro absent'
	String get microAbsent => 'Micro absent';

	/// fr: 'Permission refusée'
	String get permissionRefusee => 'Permission refusée';
}

// Path: salle.preparation.eleve
class Traductions$salle$preparation$eleve$fr {
	Traductions$salle$preparation$eleve$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Nous vérifions votre appareil…'
	String get verification => 'Nous vérifions votre appareil…';

	/// fr: 'Tout est prêt'
	String get pret => 'Tout est prêt';

	/// fr: 'Audio'
	String get audio => 'Audio';

	/// fr: 'Accès à la classe'
	String get acces => 'Accès à la classe';

	/// fr: 'Vous pouvez entrer'
	String get accesOk => 'Vous pouvez entrer';

	/// fr: 'En attente de la connexion'
	String get accesAttente => 'En attente de la connexion';

	/// fr: 'Vous entrerez avec le micro coupé.'
	String get microCoupe => 'Vous entrerez avec le micro coupé.';

	/// fr: 'Votre micro n'est pas accessible'
	String get microInaccessible => 'Votre micro n\'est pas accessible';

	/// fr: 'Personne dans la classe ne pourra vous entendre tant que l'accès au micro reste bloqué.'
	String get microInaccessibleDetail => 'Personne dans la classe ne pourra vous entendre tant que l\'accès au micro reste bloqué.';

	/// fr: 'Autoriser le micro'
	String get autoriserMicro => 'Autoriser le micro';

	late final Traductions$salle$preparation$eleve$guidee$fr guidee = Traductions$salle$preparation$eleve$guidee$fr.internal(_root);
	late final Traductions$salle$preparation$eleve$demo$fr demo = Traductions$salle$preparation$eleve$demo$fr.internal(_root);
}

// Path: salle.seance.outils
class Traductions$salle$seance$outils$fr {
	Traductions$salle$seance$outils$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Outils d'enseignement'
	String get titre => 'Outils d\'enseignement';

	/// fr: 'Pointeur'
	String get pointeur => 'Pointeur';

	/// fr: 'Marquer'
	String get marquer => 'Marquer';

	/// fr: 'Masquer'
	String get masquer => 'Masquer';

	/// fr: 'Annoter'
	String get annoter => 'Annoter';
}

// Path: salle.seance.rail
class Traductions$salle$seance$rail$fr {
	Traductions$salle$seance$rail$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Navigation'
	String get navigation => 'Navigation';

	/// fr: 'Rewayah'
	String get marque => 'Rewayah';

	/// fr: 'Academy'
	String get sousMarque => 'Academy';

	/// fr: 'Journée'
	String get journee => 'Journée';

	/// fr: 'Classes'
	String get classes => 'Classes';

	/// fr: 'Ressources'
	String get ressources => 'Ressources';

	/// fr: 'Profil'
	String get profil => 'Profil';
}

// Path: salle.seance.panneauSupports
class Traductions$salle$seance$panneauSupports$fr {
	Traductions$salle$seance$panneauSupports$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Reprendre'
	String get reprendre => 'Reprendre';

	/// fr: 'Récents'
	String get recents => 'Récents';

	/// fr: 'Ressources de la Classe'
	String get ressourcesClasse => 'Ressources de la Classe';

	/// fr: 'Voir tout'
	String get voirTout => 'Voir tout';

	/// fr: 'Ouvrir'
	String get ouvrir => 'Ouvrir';

	/// fr: 'Ouvrir {titre}'
	String ouvrirSupport({required Object titre}) => 'Ouvrir ${titre}';

	/// fr: 'Voir toute la bibliothèque'
	String get voirBibliotheque => 'Voir toute la bibliothèque';
}

// Path: salle.seance.fiche
class Traductions$salle$seance$fiche$fr {
	Traductions$salle$seance$fiche$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Aucune séance cette semaine'
	String get aucuneSeanceSemaine => 'Aucune séance cette semaine';

	/// fr: '1 séance cette semaine'
	String get uneSeanceSemaine => '1 séance cette semaine';

	/// fr: '{nombre} séances cette semaine'
	String seancesSemaine({required Object nombre}) => '${nombre} séances cette semaine';
}

// Path: salle.seance.demo
class Traductions$salle$seance$demo$fr {
	Traductions$salle$seance$demo$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Salle de démonstration'
	String get titre => 'Salle de démonstration';

	/// fr: 'Données fictives, aucun serveur. Choisissez un rôle et un état.'
	String get intro => 'Données fictives, aucun serveur. Choisissez un rôle et un état.';

	late final Traductions$salle$seance$demo$groupes$fr groupes = Traductions$salle$seance$demo$groupes$fr.internal(_root);
	late final Traductions$salle$seance$demo$roles$fr roles = Traductions$salle$seance$demo$roles$fr.internal(_root);
	late final Traductions$salle$seance$demo$etats$fr etats = Traductions$salle$seance$demo$etats$fr.internal(_root);
}

// Path: salle.seance.statut
class Traductions$salle$seance$statut$fr {
	Traductions$salle$seance$statut$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Connecté'
	String get connecte => 'Connecté';

	/// fr: 'Pas encore connecté'
	String get pasEncoreConnecte => 'Pas encore connecté';

	/// fr: 'Connexion interrompue'
	String get connexionInterrompue => 'Connexion interrompue';
}

// Path: salle.fin.enseignant
class Traductions$salle$fin$enseignant$fr {
	Traductions$salle$fin$enseignant$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Terminée'
	String get terminee => 'Terminée';

	/// fr: 'Le cahier est prêt avec les informations de la séance.'
	String get phrase => 'Le cahier est prêt avec les informations de la séance.';

	/// fr: 'Récapitulatif de la séance'
	String get recapitulatif => 'Récapitulatif de la séance';

	/// fr: 'Fin'
	String get fin => 'Fin';

	/// fr: '{n} élèves connectés'
	String connectes({required Object n}) => '${n} élèves connectés';

	/// fr: '{n} élève connecté'
	String unConnecte({required Object n}) => '${n} élève connecté';

	/// fr: 'sur {n} inscrits'
	String inscrits({required Object n}) => 'sur ${n} inscrits';

	/// fr: 'sur {n} inscrit'
	String unInscrit({required Object n}) => 'sur ${n} inscrit';

	/// fr: 'Cahier de séance'
	String get cahierSeance => 'Cahier de séance';

	/// fr: 'Cahier à compléter'
	String get cahierACompleter => 'Cahier à compléter';

	/// fr: 'Ouvrir le cahier'
	String get ouvrirCahier => 'Ouvrir le cahier';

	/// fr: 'Revenir à ma journée'
	String get revenirJournee => 'Revenir à ma journée';

	/// fr: 'Le cahier ne peut pas être ouvert pour le moment.'
	String get erreurCahier => 'Le cahier ne peut pas être ouvert pour le moment.';
}

// Path: appareils.emetteur.verification
class Traductions$appareils$emetteur$verification$fr {
	Traductions$appareils$emetteur$verification$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Vérification du code'
	String get titre => 'Vérification du code';

	/// fr: 'Le code est masqué le temps de vérifier qu'il est toujours valable.'
	String get phrase => 'Le code est masqué le temps de vérifier qu\'il est toujours valable.';
}

// Path: appareils.emetteur.confirme
class Traductions$appareils$emetteur$confirme$fr {
	Traductions$appareils$emetteur$confirme$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Appareil connecté'
	String get titre => 'Appareil connecté';

	/// fr: 'L'appareil de {prenom} est prêt. Le code n'est plus affiché et ne peut plus servir.'
	String phrase({required Object prenom}) => 'L\'appareil de ${prenom} est prêt. Le code n\'est plus affiché et ne peut plus servir.';

	/// fr: 'L'appareil de l'élève est prêt. Le code n'est plus affiché et ne peut plus servir.'
	String get phraseSansPrenom => 'L\'appareil de l\'élève est prêt. Le code n\'est plus affiché et ne peut plus servir.';

	/// fr: 'Terminé'
	String get action => 'Terminé';
}

// Path: appareils.emetteur.expire
class Traductions$appareils$emetteur$expire$fr {
	Traductions$appareils$emetteur$expire$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Ce code a expiré'
	String get titre => 'Ce code a expiré';

	/// fr: 'Il ne peut plus servir. Générez-en un nouveau quand l'autre appareil est prêt.'
	String get phrase => 'Il ne peut plus servir. Générez-en un nouveau quand l\'autre appareil est prêt.';
}

// Path: appareils.emetteur.remplace
class Traductions$appareils$emetteur$remplace$fr {
	Traductions$appareils$emetteur$remplace$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Ce code a été remplacé'
	String get titre => 'Ce code a été remplacé';

	/// fr: 'Un nouveau code a été demandé pour cet élève, ici ou sur un autre appareil. Celui-ci ne marche plus.'
	String get phrase => 'Un nouveau code a été demandé pour cet élève, ici ou sur un autre appareil. Celui-ci ne marche plus.';
}

// Path: appareils.emetteur.dejaActif
class Traductions$appareils$emetteur$dejaActif$fr {
	Traductions$appareils$emetteur$dejaActif$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Un code est déjà valable'
	String get titre => 'Un code est déjà valable';

	/// fr: 'Un code créé pour cet élève vaut jusqu'à {heure}. Il ne peut pas être réaffiché : en générer un nouveau rendra l'ancien inutilisable.'
	String phrase({required Object heure}) => 'Un code créé pour cet élève vaut jusqu\'à ${heure}. Il ne peut pas être réaffiché : en générer un nouveau rendra l\'ancien inutilisable.';
}

// Path: appareils.emetteur.horsLigne
class Traductions$appareils$emetteur$horsLigne$fr {
	Traductions$appareils$emetteur$horsLigne$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Connexion interrompue'
	String get titre => 'Connexion interrompue';

	/// fr: 'Le code est masqué jusqu'au retour de la connexion. Il reste valable jusqu'à {heure}.'
	String phraseAvecCode({required Object heure}) => 'Le code est masqué jusqu\'au retour de la connexion. Il reste valable jusqu\'à ${heure}.';

	/// fr: 'Le code n'a pas pu être préparé. Il le sera dès le retour de la connexion.'
	String get phraseSansCode => 'Le code n\'a pas pu être préparé. Il le sera dès le retour de la connexion.';
}

// Path: appareils.emetteur.erreur
class Traductions$appareils$emetteur$erreur$fr {
	Traductions$appareils$emetteur$erreur$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Limite d'appareils atteinte'
	String get plafondTitre => 'Limite d\'appareils atteinte';

	/// fr: 'Cet élève a déjà le nombre maximal d'appareils. Retirez-en un pour en connecter un autre.'
	String get plafondPhrase => 'Cet élève a déjà le nombre maximal d\'appareils. Retirez-en un pour en connecter un autre.';

	/// fr: 'Voir les appareils'
	String get plafondAction => 'Voir les appareils';

	/// fr: 'Profil élève introuvable'
	String get horsFoyerTitre => 'Profil élève introuvable';

	/// fr: 'Ce profil élève n'est pas rattaché à votre foyer. Revenez au Foyer pour en choisir un.'
	String get horsFoyerPhrase => 'Ce profil élève n\'est pas rattaché à votre foyer. Revenez au Foyer pour en choisir un.';

	/// fr: 'Connexion d'appareil pas encore ouverte'
	String get compteTitre => 'Connexion d\'appareil pas encore ouverte';

	/// fr: 'Votre compte doit être ouvert avant de connecter l'appareil d'un élève.'
	String get comptePhrase => 'Votre compte doit être ouvert avant de connecter l\'appareil d\'un élève.';

	/// fr: 'Le code n'a pas pu être préparé'
	String get generiqueTitre => 'Le code n\'a pas pu être préparé';

	/// fr: 'La demande n'a pas abouti. Réessayez dans un instant.'
	String get generiquePhrase => 'La demande n\'a pas abouti. Réessayez dans un instant.';
}

// Path: foyer.ajout.porte
class Traductions$foyer$ajout$porte$fr {
	Traductions$foyer$ajout$porte$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Votre compte n'a pas pu être lu'
	String get illisibleTitre => 'Votre compte n\'a pas pu être lu';

	/// fr: 'Nous ne savons pas encore quels profils vous pouvez ajouter. Réessayez dans un instant.'
	String get illisiblePhrase => 'Nous ne savons pas encore quels profils vous pouvez ajouter. Réessayez dans un instant.';
}

// Path: foyer.ajout.pourQui
class Traductions$foyer$ajout$pourQui$fr {
	Traductions$foyer$ajout$pourQui$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Pour qui est ce profil élève ?'
	String get question => 'Pour qui est ce profil élève ?';

	/// fr: 'Choisissez la personne qui suivra les cours.'
	String get sousTitre => 'Choisissez la personne qui suivra les cours.';

	/// fr: 'Choisissez pour qui est ce profil pour continuer.'
	String get requis => 'Choisissez pour qui est ce profil pour continuer.';

	/// fr: 'Indisponible'
	String get indisponible => 'Indisponible';

	/// fr: 'Un enfant ou un mineur'
	String get enfantTitre => 'Un enfant ou un mineur';

	/// fr: 'Un profil rattaché à votre foyer, que vous gérez pour lui.'
	String get enfantDescription => 'Un profil rattaché à votre foyer, que vous gérez pour lui.';

	/// fr: 'Possible dès que votre accès est ouvert.'
	String get enfantAttente => 'Possible dès que votre accès est ouvert.';

	/// fr: 'Un proche adulte'
	String get procheTitre => 'Un proche adulte';

	/// fr: 'Pas encore possible : un adulte aura son propre profil et donnera lui-même son accord.'
	String get procheDescription => 'Pas encore possible : un adulte aura son propre profil et donnera lui-même son accord.';

	/// fr: 'Moi-même'
	String get moiTitre => 'Moi-même';

	/// fr: 'Pas encore possible : suivre vous-même les cours avec votre propre profil élève sera proposé prochainement.'
	String get moiDescription => 'Pas encore possible : suivre vous-même les cours avec votre propre profil élève sera proposé prochainement.';
}

// Path: foyer.ajout.identite
class Traductions$foyer$ajout$identite$fr {
	Traductions$foyer$ajout$identite$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Qui est l'élève ?'
	String get question => 'Qui est l\'élève ?';

	/// fr: 'Son prénom, son nom et son âge.'
	String get sousTitre => 'Son prénom, son nom et son âge.';

	/// fr: 'Prénom'
	String get prenom => 'Prénom';

	/// fr: 'Nom'
	String get nom => 'Nom';

	/// fr: 'Le nom de famille n'est jamais montré à l'enseignant.'
	String get nomAide => 'Le nom de famille n\'est jamais montré à l\'enseignant.';

	/// fr: 'Âge'
	String get age => 'Âge';

	/// fr: 'ans'
	String get ageSuffixe => 'ans';

	/// fr: 'L'âge fixe l'affichage et la caméra au départ. Vous pourrez changer les deux ensuite.'
	String get ageAide => 'L\'âge fixe l\'affichage et la caméra au départ. Vous pourrez changer les deux ensuite.';
}

// Path: foyer.ajout.erreurs
class Traductions$foyer$ajout$erreurs$fr {
	Traductions$foyer$ajout$erreurs$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Indiquez le prénom de l'élève.'
	String get prenomRequis => 'Indiquez le prénom de l\'élève.';

	/// fr: 'Indiquez le nom de l'élève.'
	String get nomRequis => 'Indiquez le nom de l\'élève.';

	/// fr: 'Indiquez l'âge, en chiffres.'
	String get ageRequis => 'Indiquez l\'âge, en chiffres.';

	/// fr: 'Indiquez un âge entre {min} et {max} ans.'
	String ageHorsBornes({required Object min, required Object max}) => 'Indiquez un âge entre ${min} et ${max} ans.';
}

// Path: foyer.ajout.refus
class Traductions$foyer$ajout$refus$fr {
	Traductions$foyer$ajout$refus$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Votre accès doit être ouvert avant d'ajouter un profil élève.'
	String get compteNonValide => 'Votre accès doit être ouvert avant d\'ajouter un profil élève.';

	/// fr: 'Cet âge n'est pas accepté. Vérifiez-le puis réessayez.'
	String get ageHorsBornes => 'Cet âge n\'est pas accepté. Vérifiez-le puis réessayez.';

	/// fr: 'La création n'a pas été acceptée. Vérifiez les informations puis réessayez.'
	String get refuse => 'La création n\'a pas été acceptée. Vérifiez les informations puis réessayez.';
}

// Path: foyer.ajout.incertaine
class Traductions$foyer$ajout$incertaine$fr {
	Traductions$foyer$ajout$incertaine$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Le profil a peut-être été créé'
	String get titre => 'Le profil a peut-être été créé';

	/// fr: 'La réponse ne nous est pas parvenue. Vérifiez le foyer avant de réessayer, pour ne pas créer le profil deux fois.'
	String get phrase => 'La réponse ne nous est pas parvenue. Vérifiez le foyer avant de réessayer, pour ne pas créer le profil deux fois.';

	/// fr: 'Voir le foyer'
	String get voirFoyer => 'Voir le foyer';

	/// fr: 'Réessayer quand même'
	String get reessayer => 'Réessayer quand même';
}

// Path: dossiers.revue.etats
class Traductions$dossiers$revue$etats$fr {
	Traductions$dossiers$revue$etats$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Chargement du dossier…'
	String get chargement => 'Chargement du dossier…';

	/// fr: 'Vous êtes hors ligne. Aucune décision ne peut être envoyée.'
	String get horsLigne => 'Vous êtes hors ligne. Aucune décision ne peut être envoyée.';

	/// fr: 'Vous n’avez plus accès à ce dossier.'
	String get accesPerdu => 'Vous n’avez plus accès à ce dossier.';

	/// fr: 'Retour aux dossiers'
	String get retourDossiers => 'Retour aux dossiers';

	/// fr: 'Terminez les vérifications requises.'
	String get verificationsIncompletes => 'Terminez les vérifications requises.';

	/// fr: 'Un accord requis manque à ce dossier.'
	String get accordManquant => 'Un accord requis manque à ce dossier.';

	/// fr: 'La décision est indisponible pour le moment.'
	String get decisionIndisponible => 'La décision est indisponible pour le moment.';

	/// fr: 'Ce dossier a changé depuis son ouverture.'
	String get modifie => 'Ce dossier a changé depuis son ouverture.';

	/// fr: 'Actualiser le dossier'
	String get actualiserDossier => 'Actualiser le dossier';

	/// fr: 'Ce dossier ne peut pas être refusé dans son état actuel.'
	String get refusNonAutorise => 'Ce dossier ne peut pas être refusé dans son état actuel.';
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

	/// fr: 'Règles d'observation de la classe modifiées'
	String get observationPolitiqueGroupeModifiee => 'Règles d\'observation de la classe modifiées';
}

// Path: compte.tuteur.identite
class Traductions$compte$tuteur$identite$fr {
	Traductions$compte$tuteur$identite$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Compte validé'
	String get statutValide => 'Compte validé';

	/// fr: 'Profil à compléter'
	String get statutProvisoire => 'Profil à compléter';

	/// fr: 'Titulaire du compte'
	String get nomInconnu => 'Titulaire du compte';

	/// fr: 'Adresse de connexion non communiquée'
	String get courrielAbsent => 'Adresse de connexion non communiquée';

	/// fr: 'Connexion par lien reçu par courriel'
	String get connexionLien => 'Connexion par lien reçu par courriel';

	/// fr: 'Connexion avec Google'
	String get connexionGoogle => 'Connexion avec Google';

	/// fr: 'Méthode de connexion non précisée'
	String get connexionInconnue => 'Méthode de connexion non précisée';
}

// Path: compte.tuteur.acces
class Traductions$compte$tuteur$acces$fr {
	Traductions$compte$tuteur$acces$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Accès et paiements'
	String get titre => 'Accès et paiements';

	/// fr: 'Statut et échéance de chaque profil élève'
	String get resume => 'Statut et échéance de chaque profil élève';

	/// fr: 'Accès actif'
	String get pastilleActif => 'Accès actif';

	/// fr: 'Accès terminé'
	String get pastilleExpire => 'Accès terminé';

	/// fr: 'Accès des profils élèves'
	String get ligne => 'Accès des profils élèves';

	/// fr: 'Paiements et reçus'
	String get paiements => 'Paiements et reçus';
}

// Path: compte.tuteur.securite
class Traductions$compte$tuteur$securite$fr {
	Traductions$compte$tuteur$securite$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Connexion et sécurité'
	String get titre => 'Connexion et sécurité';

	/// fr: 'Méthode de connexion'
	String get methode => 'Méthode de connexion';

	/// fr: 'Lien par courriel'
	String get methodeLien => 'Lien par courriel';

	/// fr: 'Google'
	String get methodeGoogle => 'Google';
}

// Path: compte.tuteur.informations
class Traductions$compte$tuteur$informations$fr {
	Traductions$compte$tuteur$informations$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Informations personnelles'
	String get titre => 'Informations personnelles';

	/// fr: 'Nom, adresse de connexion, langue et fuseau'
	String get resume => 'Nom, adresse de connexion, langue et fuseau';

	/// fr: 'Français · {ville}'
	String langueFuseau({required Object ville}) => 'Français · ${ville}';

	/// fr: 'Consulter mes informations'
	String get consulter => 'Consulter mes informations';
}

// Path: compte.tuteur.foyer
class Traductions$compte$tuteur$foyer$fr {
	Traductions$compte$tuteur$foyer$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Mon foyer'
	String get titre => 'Mon foyer';

	/// fr: 'Aucun profil élève pour le moment'
	String get aucun => 'Aucun profil élève pour le moment';

	/// fr: '1 profil élève'
	String get un => '1 profil élève';

	/// fr: '{nombre} profils élèves'
	String plusieurs({required Object nombre}) => '${nombre} profils élèves';

	/// fr: 'Profils élèves et appareils du foyer'
	String get legende => 'Profils élèves et appareils du foyer';

	/// fr: 'Créer mon profil élève'
	String get creerMonProfil => 'Créer mon profil élève';
}

// Path: compte.tuteur.aide
class Traductions$compte$tuteur$aide$fr {
	Traductions$compte$tuteur$aide$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Aide et support'
	String get titre => 'Aide et support';

	/// fr: 'Aide et contact'
	String get ligne => 'Aide et contact';

	/// fr: 'Informations légales'
	String get legal => 'Informations légales';
}

// Path: compte.tuteur.deconnexion
class Traductions$compte$tuteur$deconnexion$fr {
	Traductions$compte$tuteur$deconnexion$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Se déconnecter de Rewayah ?'
	String get question => 'Se déconnecter de Rewayah ?';

	/// fr: 'Vous devrez vous reconnecter pour revenir sur cet appareil. Vos autres appareils restent connectés.'
	String get consequence => 'Vous devrez vous reconnecter pour revenir sur cet appareil. Vos autres appareils restent connectés.';

	/// fr: 'Me déconnecter'
	String get confirmer => 'Me déconnecter';

	/// fr: 'La déconnexion n'a pas abouti. Vérifiez votre connexion, puis réessayez.'
	String get echec => 'La déconnexion n\'a pas abouti. Vérifiez votre connexion, puis réessayez.';
}

// Path: compte.tuteur.pageInformations
class Traductions$compte$tuteur$pageInformations$fr {
	Traductions$compte$tuteur$pageInformations$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Informations personnelles'
	String get titre => 'Informations personnelles';

	/// fr: 'Prénom'
	String get prenom => 'Prénom';

	/// fr: 'Nom'
	String get nom => 'Nom';

	/// fr: 'Adresse de connexion'
	String get courriel => 'Adresse de connexion';

	/// fr: 'Langue de l'interface'
	String get langue => 'Langue de l\'interface';

	/// fr: 'Fuseau des séances'
	String get fuseau => 'Fuseau des séances';

	/// fr: 'Non disponible pour le moment'
	String get fuseauIndisponible => 'Non disponible pour le moment';

	/// fr: 'Ces informations sont tenues par l'académie. Elles ne se modifient pas encore depuis l'application.'
	String get note => 'Ces informations sont tenues par l\'académie. Elles ne se modifient pas encore depuis l\'application.';
}

// Path: compte.tuteur.pageSecurite
class Traductions$compte$tuteur$pageSecurite$fr {
	Traductions$compte$tuteur$pageSecurite$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Connexion et sécurité'
	String get titre => 'Connexion et sécurité';

	/// fr: 'Comment vous accédez à votre compte.'
	String get sousTitre => 'Comment vous accédez à votre compte.';

	/// fr: 'Méthode de connexion'
	String get methode => 'Méthode de connexion';

	/// fr: 'Adresse de connexion'
	String get adresse => 'Adresse de connexion';

	/// fr: 'Les appareils connectés à votre compte ne sont pas encore listés dans l'application.'
	String get appareils => 'Les appareils connectés à votre compte ne sont pas encore listés dans l\'application.';

	/// fr: 'Pour fermer la session de cet appareil, utilisez « Se déconnecter » en bas de Mon compte.'
	String get deconnexion => 'Pour fermer la session de cet appareil, utilisez « Se déconnecter » en bas de Mon compte.';
}

// Path: compte.tuteur.pageAcces
class Traductions$compte$tuteur$pageAcces$fr {
	Traductions$compte$tuteur$pageAcces$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Accès des profils élèves'
	String get titre => 'Accès des profils élèves';

	/// fr: 'Le statut de l'accès de chaque profil élève.'
	String get sousTitre => 'Le statut de l\'accès de chaque profil élève.';

	/// fr: 'Sans date de fin'
	String get sansEcheance => 'Sans date de fin';

	/// fr: 'Ouvert jusqu'au {date}'
	String jusqua({required Object date}) => 'Ouvert jusqu\'au ${date}';

	/// fr: 'Terminé le {date}'
	String expire({required Object date}) => 'Terminé le ${date}';

	/// fr: 'Actif'
	String get pastilleActif => 'Actif';

	/// fr: 'Terminé'
	String get pastilleExpire => 'Terminé';

	/// fr: 'Aucun profil élève'
	String get aucunTitre => 'Aucun profil élève';

	/// fr: 'L'accès de chaque profil élève s'affichera ici.'
	String get aucunePhrase => 'L\'accès de chaque profil élève s\'affichera ici.';

	/// fr: 'Votre compte de titulaire n'a pas d'échéance propre : l'accès se règle profil par profil.'
	String get titulaire => 'Votre compte de titulaire n\'a pas d\'échéance propre : l\'accès se règle profil par profil.';
}

// Path: compte.tuteur.pagePaiements
class Traductions$compte$tuteur$pagePaiements$fr {
	Traductions$compte$tuteur$pagePaiements$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Paiements et reçus'
	String get titre => 'Paiements et reçus';

	/// fr: 'Paiements pas encore consultables'
	String get indisponibleTitre => 'Paiements pas encore consultables';

	/// fr: 'L'historique des paiements, les reçus et les moyens de paiement ne sont pas encore disponibles dans l'application. Aucun paiement ne vous est demandé ici.'
	String get indisponiblePhrase => 'L\'historique des paiements, les reçus et les moyens de paiement ne sont pas encore disponibles dans l\'application. Aucun paiement ne vous est demandé ici.';

	/// fr: 'Aucun paiement enregistré'
	String get aucunTitre => 'Aucun paiement enregistré';

	/// fr: 'Les paiements enregistrés par l'académie s'afficheront ici.'
	String get aucunePhrase => 'Les paiements enregistrés par l\'académie s\'afficheront ici.';

	/// fr: 'Paiement du {date}'
	String paiementDu({required Object date}) => 'Paiement du ${date}';

	/// fr: 'Justificatif disponible'
	String get justificatif => 'Justificatif disponible';
}

// Path: compte.tuteur.pagePreferences
class Traductions$compte$tuteur$pagePreferences$fr {
	Traductions$compte$tuteur$pagePreferences$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Préférences'
	String get titre => 'Préférences';

	/// fr: 'Personnalisez votre expérience sur cet appareil.'
	String get sousTitre => 'Personnalisez votre expérience sur cet appareil.';

	/// fr: 'Apparence'
	String get apparence => 'Apparence';

	/// fr: 'Thème et confort visuel'
	String get apparenceDetail => 'Thème et confort visuel';

	/// fr: 'Langue et région'
	String get langue => 'Langue et région';

	/// fr: 'Notifications'
	String get notifications => 'Notifications';

	/// fr: 'Pas encore disponibles dans l'application'
	String get notificationsDetail => 'Pas encore disponibles dans l\'application';
}

// Path: compte.tuteur.pageApparence
class Traductions$compte$tuteur$pageApparence$fr {
	Traductions$compte$tuteur$pageApparence$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Apparence'
	String get titre => 'Apparence';

	/// fr: 'Appliqué sur cet appareil.'
	String get sousTitre => 'Appliqué sur cet appareil.';

	/// fr: 'Thème de l'application'
	String get theme => 'Thème de l\'application';

	/// fr: 'Personnalisez l'apparence de Rewayah.'
	String get themeDetail => 'Personnalisez l\'apparence de Rewayah.';

	/// fr: 'Confort visuel'
	String get confort => 'Confort visuel';

	/// fr: 'Animations'
	String get animations => 'Animations';

	/// fr: 'Réduites quand votre appareil le demande'
	String get animationsDetail => 'Réduites quand votre appareil le demande';

	/// fr: 'Taille du texte'
	String get texte => 'Taille du texte';

	/// fr: 'Suit la taille du système'
	String get texteDetail => 'Suit la taille du système';
}

// Path: compte.tuteur.pageAide
class Traductions$compte$tuteur$pageAide$fr {
	Traductions$compte$tuteur$pageAide$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Aide et support'
	String get titre => 'Aide et support';

	/// fr: 'Aide pas encore disponible'
	String get indisponibleTitre => 'Aide pas encore disponible';

	/// fr: 'Les questions fréquentes et le contact de l'académie ne sont pas encore ouverts dans l'application.'
	String get indisponiblePhrase => 'Les questions fréquentes et le contact de l\'académie ne sont pas encore ouverts dans l\'application.';

	/// fr: 'Courriel de l'académie'
	String get canalCourriel => 'Courriel de l\'académie';

	/// fr: 'Page d'aide de l'académie'
	String get canalLien => 'Page d\'aide de l\'académie';

	/// fr: 'Aucun canal d'aide n'est publié pour le moment.'
	String get aucunCanal => 'Aucun canal d\'aide n\'est publié pour le moment.';
}

// Path: compte.tuteur.pageLegal
class Traductions$compte$tuteur$pageLegal$fr {
	Traductions$compte$tuteur$pageLegal$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Informations légales'
	String get titre => 'Informations légales';

	/// fr: 'Documents acceptés'
	String get documents => 'Documents acceptés';

	/// fr: 'Conditions du tuteur'
	String get conditionsTuteur => 'Conditions du tuteur';

	/// fr: 'Contrat enseignant'
	String get contratEnseignant => 'Contrat enseignant';

	/// fr: 'Accusé d'enregistrement des cours'
	String get accuseEnregistrement => 'Accusé d\'enregistrement des cours';

	/// fr: 'Version {version}, acceptée le {date}'
	String acceptation({required Object version, required Object date}) => 'Version ${version}, acceptée le ${date}';

	/// fr: 'Aucun document accepté'
	String get aucunTitre => 'Aucun document accepté';

	/// fr: 'Aucun document accepté n'est enregistré pour ce compte.'
	String get aucun => 'Aucun document accepté n\'est enregistré pour ce compte.';

	/// fr: 'Un document accepté ne se modifie pas.'
	String get lectureSeule => 'Un document accepté ne se modifie pas.';

	/// fr: 'Conditions et confidentialité'
	String get textes => 'Conditions et confidentialité';

	/// fr: 'Les conditions générales, la politique de confidentialité et les mentions légales ne sont pas encore consultables dans l'application.'
	String get textesIndisponibles => 'Les conditions générales, la politique de confidentialité et les mentions légales ne sont pas encore consultables dans l\'application.';
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

// Path: classe.entree.annonce
class Traductions$classe$entree$annonce$fr {
	Traductions$classe$entree$annonce$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Séance à venir'
	String get aVenir => 'Séance à venir';

	/// fr: 'La salle est ouverte'
	String get fenetreOuverte => 'La salle est ouverte';

	/// fr: 'Vous êtes dans la salle'
	String get attente => 'Vous êtes dans la salle';
}

// Path: classe.entree.demo
class Traductions$classe$entree$demo$fr {
	Traductions$classe$entree$demo$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Entrée en classe'
	String get titre => 'Entrée en classe';

	/// fr: 'Démonstration'
	String get mention => 'Démonstration';

	/// fr: 'Données fictives, aucun appel serveur. Chaque lien montre ce que dit l'emplacement d'entrée pour un rôle et un moment.'
	String get intro => 'Données fictives, aucun appel serveur. Chaque lien montre ce que dit l\'emplacement d\'entrée pour un rôle et un moment.';

	late final Traductions$classe$entree$demo$roles$fr roles = Traductions$classe$entree$demo$roles$fr.internal(_root);
	late final Traductions$classe$entree$demo$etats$fr etats = Traductions$classe$entree$demo$etats$fr.internal(_root);

	/// fr: 'Forme : bouton'
	String get formeBouton => 'Forme : bouton';

	/// fr: 'Forme : ligne d'état'
	String get formeLigne => 'Forme : ligne d\'état';

	/// fr: 'Lecteur d'écran : {texte}'
	String lecteur({required Object texte}) => 'Lecteur d\'écran : ${texte}';

	/// fr: 'Annonce : {texte}'
	String annonce({required Object texte}) => 'Annonce : ${texte}';

	/// fr: 'Détail : {texte}'
	String detail({required Object texte}) => 'Détail : ${texte}';

	/// fr: 'Retour à la liste'
	String get retour => 'Retour à la liste';
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

// Path: classe.pageCatalogue.etat
class Traductions$classe$pageCatalogue$etat$fr {
	Traductions$classe$pageCatalogue$etat$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Ouverte'
	String get ouverte => 'Ouverte';

	/// fr: 'Complète'
	String get complete => 'Complète';

	/// fr: 'Liste d'attente'
	String get listeAttente => 'Liste d\'attente';
}

// Path: classe.pageCatalogue.resultat
class Traductions$classe$pageCatalogue$resultat$fr {
	Traductions$classe$pageCatalogue$resultat$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Inscription confirmée'
	String get inscritTitre => 'Inscription confirmée';

	/// fr: '{prenom} rejoint {classe}.'
	String inscritPhrase({required Object prenom, required Object classe}) => '${prenom} rejoint ${classe}.';

	/// fr: 'Voir la classe'
	String get voirClasse => 'Voir la classe';

	/// fr: 'Demande envoyée'
	String get validationTitre => 'Demande envoyée';

	/// fr: 'L'académie doit encore valider l'inscription de {prenom} dans {classe}.'
	String validationPhrase({required Object prenom, required Object classe}) => 'L\'académie doit encore valider l\'inscription de ${prenom} dans ${classe}.';

	/// fr: 'Inscription sur liste d'attente'
	String get listeAttenteTitre => 'Inscription sur liste d\'attente';

	/// fr: '{prenom} est sur la liste d'attente de {classe}. Aucune place n'est réservée pour l'instant.'
	String listeAttentePhrase({required Object prenom, required Object classe}) => '${prenom} est sur la liste d\'attente de ${classe}. Aucune place n\'est réservée pour l\'instant.';

	/// fr: 'Inscription non acceptée'
	String get refuseTitre => 'Inscription non acceptée';

	/// fr: 'Aucune place n'a été réservée pour {prenom}. Vous pouvez choisir une autre classe.'
	String refusePhrase({required Object prenom}) => 'Aucune place n\'a été réservée pour ${prenom}. Vous pouvez choisir une autre classe.';

	/// fr: 'Voir les autres classes'
	String get autresClasses => 'Voir les autres classes';

	/// fr: 'Retour à l'accueil'
	String get retourAccueil => 'Retour à l\'accueil';
}

// Path: enseignant.signalement.categories
class Traductions$enseignant$signalement$categories$fr {
	Traductions$enseignant$signalement$categories$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Problème pédagogique'
	String get pedagogique => 'Problème pédagogique';

	/// fr: 'Présence'
	String get presence => 'Présence';

	/// fr: 'Technique'
	String get technique => 'Technique';

	/// fr: 'Changement'
	String get changement => 'Changement';

	/// fr: 'Autre'
	String get autre => 'Autre';
}

// Path: enseignant.journee.absence
class Traductions$enseignant$journee$absence$fr {
	Traductions$enseignant$journee$absence$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Déclarer une absence'
	String get ouvrir => 'Déclarer une absence';

	/// fr: 'Vous ne pourrez pas assurer cette séance ?'
	String get titre => 'Vous ne pourrez pas assurer cette séance ?';

	/// fr: 'Date'
	String get cleDate => 'Date';

	/// fr: 'Votre affectation à la Classe reste inchangée.'
	String get notice => 'Votre affectation à la Classe reste inchangée.';

	/// fr: 'Déclarer mon absence'
	String get declarer => 'Déclarer mon absence';

	/// fr: 'La demande n'a pas abouti. Réessayez dans un instant.'
	String get echec => 'La demande n\'a pas abouti. Réessayez dans un instant.';

	late final Traductions$enseignant$journee$absence$etats$fr etats = Traductions$enseignant$journee$absence$etats$fr.internal(_root);
}

// Path: enseignant.journee.remplacement
class Traductions$enseignant$journee$remplacement$fr {
	Traductions$enseignant$journee$remplacement$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Assurer ce remplacement ?'
	String get titre => 'Assurer ce remplacement ?';

	/// fr: 'Assurer ce remplacement'
	String get assurer => 'Assurer ce remplacement';

	/// fr: 'Pas cette fois'
	String get pasCetteFois => 'Pas cette fois';
}

// Path: tc.groupe.mesGroupes
class Traductions$tc$groupe$mesGroupes$fr {
	Traductions$tc$groupe$mesGroupes$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Mes classes'
	String get titre => 'Mes classes';

	/// fr: 'Aucune classe pour le moment'
	String get aucun => 'Aucune classe pour le moment';

	/// fr: 'L'académie vous placera dans une classe dès qu'un créneau vous correspond.'
	String get aucunDetail => 'L\'académie vous placera dans une classe dès qu\'un créneau vous correspond.';
}

// Path: tc.groupe.commun
class Traductions$tc$groupe$commun$fr {
	Traductions$tc$groupe$commun$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Vos classes n'ont pas pu être lues'
	String get erreur => 'Vos classes n\'ont pas pu être lues';

	/// fr: 'Réessayer'
	String get reessayer => 'Réessayer';
}

// Path: tc.groupe.carte
class Traductions$tc$groupe$carte$fr {
	Traductions$tc$groupe$carte$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Ouvrir la classe {libelle}'
	String ouvrir({required Object libelle}) => 'Ouvrir la classe ${libelle}';

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

	/// fr: 'Le planning de cette classe n'est pas encore posé.'
	String get aucuneSeanceDetail => 'Le planning de cette classe n\'est pas encore posé.';

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

	/// fr: 'Heure de la classe'
	String get heureGroupe => 'Heure de la classe';

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

	/// fr: 'Mes classes'
	String get retour => 'Mes classes';

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

	/// fr: 'Élèves de la Classe'
	String get roster => 'Élèves de la Classe';

	/// fr: 'Reprendre le cours'
	String get reprendreLeCours => 'Reprendre le cours';

	/// fr: 'Cette Classe ne vous est pas ouverte'
	String get introuvable => 'Cette Classe ne vous est pas ouverte';

	/// fr: 'Elle a peut-être été clôturée, ou elle concerne un autre profil.'
	String get introuvableDetail => 'Elle a peut-être été clôturée, ou elle concerne un autre profil.';
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

	/// fr: 'Pour cette Classe'
	String get pourCeGroupe => 'Pour cette Classe';

	/// fr: 'Supports à afficher'
	String get groupe => 'Supports à afficher';

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

	/// fr: 'La Classe en était page {page}'
	String groupeDetail({required Object page}) => 'La Classe en était page ${page}';
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

	/// fr: 'Ardoise d'annotation, facultative : le cours reste lisible sans elle'
	String get ardoise => 'Ardoise d\'annotation, facultative : le cours reste lisible sans elle';

	/// fr: 'Effacer mon dernier trait'
	String get effacerDernier => 'Effacer mon dernier trait';
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

	/// fr: 'Cette séance n'a aucun élève inscrit.'
	String get videDetail => 'Cette séance n\'a aucun élève inscrit.';

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

	/// fr: 'Ouvrez la Bibliothèque pour présenter un support à la Classe.'
	String get aucunDetail => 'Ouvrez la Bibliothèque pour présenter un support à la Classe.';

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

	/// fr: 'Retour à la classe'
	String get retourClasse => 'Retour à la classe';
}

// Path: tc.observation.explication
class Traductions$tc$observation$explication$fr {
	Traductions$tc$observation$explication$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Un aperçu de son apprentissage'
	String get titre => 'Un aperçu de son apprentissage';

	/// fr: '{n} visite de {duree}'
	String regleUne({required Object n, required Object duree}) => '${n} visite de ${duree}';

	/// fr: '{n} visites de {duree}'
	String regle({required Object n, required Object duree}) => '${n} visites de ${duree}';

	/// fr: 'Par séance et par parent, même si plusieurs de vos enfants sont dans la classe.'
	String get regleDetail => 'Par séance et par parent, même si plusieurs de vos enfants sont dans la classe.';

	/// fr: 'Écoutez l'enseignant et les élèves'
	String get ecoute => 'Écoutez l\'enseignant et les élèves';

	/// fr: 'Vous entendez l'enseignant et les élèves qui prennent la parole, y compris votre enfant.'
	String get ecouteDetail => 'Vous entendez l\'enseignant et les élèves qui prennent la parole, y compris votre enfant.';

	/// fr: 'Sans micro ni caméra'
	String get sansMedia => 'Sans micro ni caméra';

	/// fr: 'Votre micro et votre caméra restent désactivés pour ne pas interrompre la classe.'
	String get sansMediaDetail => 'Votre micro et votre caméra restent désactivés pour ne pas interrompre la classe.';

	/// fr: 'Si un autre élève récite lors de votre première visite, vous pourrez revenir plus tard pour écouter votre enfant.'
	String get revenir => 'Si un autre élève récite lors de votre première visite, vous pourrez revenir plus tard pour écouter votre enfant.';

	/// fr: 'Une visite quittée avant la fin compte comme une visite entière : le temps non utilisé n'est pas reporté.'
	String get ecourtee => 'Une visite quittée avant la fin compte comme une visite entière : le temps non utilisé n\'est pas reporté.';

	/// fr: 'Pour préserver la concentration, vous observez sans intervenir.'
	String get sansIntervenir => 'Pour préserver la concentration, vous observez sans intervenir.';

	/// fr: 'Votre enfant et son enseignant sont informés.'
	String get informes => 'Votre enfant et son enseignant sont informés.';

	/// fr: 'Observer maintenant'
	String get observer => 'Observer maintenant';

	/// fr: 'Pas maintenant'
	String get pasMaintenant => 'Pas maintenant';

	/// fr: '{restantes}/{max} visite restante pour cette séance'
	String restanteUne({required Object restantes, required Object max}) => '${restantes}/${max} visite restante pour cette séance';

	/// fr: '{restantes}/{max} visites restantes pour cette séance'
	String restantes({required Object restantes, required Object max}) => '${restantes}/${max} visites restantes pour cette séance';

	/// fr: 'Aucune visite restante pour cette séance'
	String get aucuneRestante => 'Aucune visite restante pour cette séance';
}

// Path: tc.observation.disponibilite
class Traductions$tc$observation$disponibilite$fr {
	Traductions$tc$observation$disponibilite$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Aucune visite restante pour cette séance'
	String get visitesEpuiseesTitre => 'Aucune visite restante pour cette séance';

	/// fr: 'Vous avez utilisé vos visites. Vous pourrez observer la prochaine séance.'
	String get visitesEpuisees => 'Vous avez utilisé vos visites. Vous pourrez observer la prochaine séance.';

	/// fr: 'Temps d'observation écoulé'
	String get tempsEpuiseTitre => 'Temps d\'observation écoulé';

	/// fr: 'Votre temps d'observation pour cette séance est utilisé. Vous pourrez observer la prochaine séance.'
	String get tempsEpuise => 'Votre temps d\'observation pour cette séance est utilisé. Vous pourrez observer la prochaine séance.';

	/// fr: 'La séance n'a pas encore commencé'
	String get seanceNonCommenceeTitre => 'La séance n\'a pas encore commencé';

	/// fr: 'L'observation s'ouvre pendant la séance.'
	String get seanceNonCommencee => 'L\'observation s\'ouvre pendant la séance.';

	/// fr: 'La séance est terminée'
	String get seanceTermineeTitre => 'La séance est terminée';

	/// fr: 'Vous pourrez observer la prochaine séance.'
	String get seanceTerminee => 'Vous pourrez observer la prochaine séance.';

	/// fr: 'Cette séance n'a pas lieu'
	String get seanceNonTenueTitre => 'Cette séance n\'a pas lieu';

	/// fr: 'Elle a été annulée, reportée ou n'a pas été tenue.'
	String get seanceNonTenue => 'Elle a été annulée, reportée ou n\'a pas été tenue.';

	/// fr: 'La séance n'est pas ouverte en ce moment'
	String get horsFenetreTitre => 'La séance n\'est pas ouverte en ce moment';

	/// fr: 'L'observation est possible seulement pendant la séance.'
	String get horsFenetre => 'L\'observation est possible seulement pendant la séance.';

	/// fr: 'Observation fermée pour cette classe'
	String get desactiveeTitre => 'Observation fermée pour cette classe';

	/// fr: 'L'administration a fermé l'observation de cette classe.'
	String get desactivee => 'L\'administration a fermé l\'observation de cette classe.';

	/// fr: 'Aucun de vos enfants dans cette séance'
	String get lienAbsentTitre => 'Aucun de vos enfants dans cette séance';

	/// fr: 'L'observation est réservée aux parents des élèves de la séance.'
	String get lienAbsent => 'L\'observation est réservée aux parents des élèves de la séance.';

	/// fr: 'Votre enfant n'est pas dans la séance'
	String get enfantAbsentTitre => 'Votre enfant n\'est pas dans la séance';

	/// fr: 'L'observation s'ouvre quand votre enfant est présent.'
	String get enfantAbsent => 'L\'observation s\'ouvre quand votre enfant est présent.';

	/// fr: 'Présence en cours de vérification'
	String get presenceTitre => 'Présence en cours de vérification';

	/// fr: 'L'observation s'ouvre dès que la présence de votre enfant est confirmée.'
	String get presence => 'L\'observation s\'ouvre dès que la présence de votre enfant est confirmée.';

	/// fr: 'Une visite est déjà ouverte'
	String get visiteOuverteTitre => 'Une visite est déjà ouverte';

	/// fr: 'Une de vos visites est encore ouverte pour cette séance, sur cet appareil ou sur un autre. Elle compte parmi vos visites.'
	String get visiteOuverte => 'Une de vos visites est encore ouverte pour cette séance, sur cet appareil ou sur un autre. Elle compte parmi vos visites.';

	/// fr: 'Observation pas encore ouverte'
	String get fermeeTitre => 'Observation pas encore ouverte';

	/// fr: 'L'observation des séances par les parents n'est pas encore ouverte. Elle sera proposée ici dès son ouverture.'
	String get fermee => 'L\'observation des séances par les parents n\'est pas encore ouverte. Elle sera proposée ici dès son ouverture.';

	/// fr: 'Vérification impossible'
	String get reseauTitre => 'Vérification impossible';

	/// fr: 'La disponibilité de l'observation n'a pas pu être vérifiée. Aucune visite n'a commencé.'
	String get reseau => 'La disponibilité de l\'observation n\'a pas pu être vérifiée. Aucune visite n\'a commencé.';

	/// fr: 'Observation indisponible'
	String get capaciteTitre => 'Observation indisponible';

	/// fr: 'L'observation n'est pas disponible pour le moment.'
	String get capacite => 'L\'observation n\'est pas disponible pour le moment.';
}

// Path: tc.observation.connexion
class Traductions$tc$observation$connexion$fr {
	Traductions$tc$observation$connexion$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Connexion et vérification'
	String get titre => 'Connexion et vérification';

	/// fr: 'Vos visites restantes sont vérifiées. La visite commence dès que l'entrée est acceptée, connexion vidéo comprise.'
	String get phrase => 'Vos visites restantes sont vérifiées. La visite commence dès que l\'entrée est acceptée, connexion vidéo comprise.';

	/// fr: 'Connexion et vérification en cours'
	String get enCours => 'Connexion et vérification en cours';

	/// fr: 'Restez sur cette page : la vérification continue.'
	String get prolongee => 'Restez sur cette page : la vérification continue.';

	/// fr: 'Connexion impossible'
	String get impossibleTitre => 'Connexion impossible';

	/// fr: 'L'entrée dans la séance n'a pas abouti. Vérifiez votre connexion, puis réessayez : vos visites restantes seront vérifiées à nouveau.'
	String get impossible => 'L\'entrée dans la séance n\'a pas abouti. Vérifiez votre connexion, puis réessayez : vos visites restantes seront vérifiées à nouveau.';
}

// Path: tc.observation.duree
class Traductions$tc$observation$duree$fr {
	Traductions$tc$observation$duree$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: '{n} seconde'
	String secondeUne({required Object n}) => '${n} seconde';

	/// fr: '{n} secondes'
	String secondes({required Object n}) => '${n} secondes';

	/// fr: '{n} minute'
	String minuteUne({required Object n}) => '${n} minute';

	/// fr: '{n} minutes'
	String minutes({required Object n}) => '${n} minutes';

	/// fr: '{m} min {s} s'
	String minutesSecondes({required Object m, required Object s}) => '${m} min ${s} s';
}

// Path: tc.observation.refus
class Traductions$tc$observation$refus$fr {
	Traductions$tc$observation$refus$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'L'observation est désactivée pour cette classe.'
	String get politiqueDesactivee => 'L\'observation est désactivée pour cette classe.';

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

	/// fr: 'Le support partagé par l'enseignant s'affiche ici.'
	String get supportIndisponible => 'Le support partagé par l\'enseignant s\'affiche ici.';

	/// fr: 'Enseignant'
	String get enseignant => 'Enseignant';

	/// fr: 'Votre enfant'
	String get monEnfant => 'Votre enfant';

	/// fr: 'Temps restant non confirmé par le serveur.'
	String get budgetIncertain => 'Temps restant non confirmé par le serveur.';

	/// fr: 'La vidéo de la séance n'a pas pu s'ouvrir. Votre temps d'observation continue de s'écouler.'
	String get videoIndisponible => 'La vidéo de la séance n\'a pas pu s\'ouvrir. Votre temps d\'observation continue de s\'écouler.';

	/// fr: 'La fin de votre visite n'a pas pu être confirmée. Elle sera fermée par le serveur.'
	String get sortieNonConfirmee => 'La fin de votre visite n\'a pas pu être confirmée. Elle sera fermée par le serveur.';

	/// fr: 'restantes'
	String get restantes => 'restantes';

	/// fr: 'Temps restant : {duree}'
	String decompteLu({required Object duree}) => 'Temps restant : ${duree}';

	/// fr: 'En direct'
	String get enDirect => 'En direct';

	/// fr: 'Connexion'
	String get connexion => 'Connexion';

	/// fr: 'Reconnexion'
	String get reconnexion => 'Reconnexion';

	/// fr: 'Vidéo indisponible'
	String get videoCoupee => 'Vidéo indisponible';

	/// fr: 'La connexion est interrompue, reconnexion en cours. Votre temps d'observation continue de s'écouler.'
	String get reconnexionDetail => 'La connexion est interrompue, reconnexion en cours. Votre temps d\'observation continue de s\'écouler.';

	/// fr: 'Son reçu'
	String get sonRecu => 'Son reçu';

	/// fr: 'Son interrompu'
	String get sonInterrompu => 'Son interrompu';

	/// fr: 'Agrandir'
	String get agrandir => 'Agrandir';

	/// fr: 'Réduire'
	String get reduire => 'Réduire';

	/// fr: 'Caméra fermée'
	String get cameraFermee => 'Caméra fermée';

	/// fr: 'Pas encore dans la salle'
	String get pasEncoreLa => 'Pas encore dans la salle';

	/// fr: '{nom} parle'
	String parle({required Object nom}) => '${nom} parle';

	/// fr: 'Quitter la visite ?'
	String get quitterQuestion => 'Quitter la visite ?';

	/// fr: 'Il vous reste {duree}. Une visite quittée avant la fin compte comme une visite entière : le temps non utilisé n'est pas reporté.'
	String quitterConsequence({required Object duree}) => 'Il vous reste ${duree}. Une visite quittée avant la fin compte comme une visite entière : le temps non utilisé n\'est pas reporté.';

	/// fr: 'Une visite quittée avant la fin compte comme une visite entière : le temps non utilisé n'est pas reporté.'
	String get quitterConsequenceSansTemps => 'Une visite quittée avant la fin compte comme une visite entière : le temps non utilisé n\'est pas reporté.';

	/// fr: 'Quitter la visite'
	String get quitterConfirmer => 'Quitter la visite';
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

// Path: tc.observation.resultat
class Traductions$tc$observation$resultat$fr {
	Traductions$tc$observation$resultat$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Votre première visite est terminée'
	String get premiereTerminee => 'Votre première visite est terminée';

	/// fr: 'Votre dernière visite est terminée'
	String get derniereTerminee => 'Votre dernière visite est terminée';

	/// fr: 'Votre visite est terminée'
	String get terminee => 'Votre visite est terminée';

	/// fr: 'Durée de visite atteinte'
	String get dureeAtteinte => 'Durée de visite atteinte';

	/// fr: 'Observation interrompue'
	String get interrompue => 'Observation interrompue';

	/// fr: 'La séance continue pour {prenom}.'
	String continuePour({required Object prenom}) => 'La séance continue pour ${prenom}.';

	/// fr: 'La séance continue.'
	String get continueSansPrenom => 'La séance continue.';

	/// fr: 'Il vous reste une visite de {duree}. Revenez plus tard pour l'écouter.'
	String resteUne({required Object duree}) => 'Il vous reste une visite de ${duree}. Revenez plus tard pour l\'écouter.';

	/// fr: 'Il vous reste {n} visites de {duree}. Revenez plus tard pour l'écouter.'
	String restent({required Object n, required Object duree}) => 'Il vous reste ${n} visites de ${duree}. Revenez plus tard pour l\'écouter.';

	/// fr: 'Il vous reste une visite. Revenez plus tard pour l'écouter.'
	String get resteUneSansDuree => 'Il vous reste une visite. Revenez plus tard pour l\'écouter.';

	/// fr: 'Il vous reste {n} visites. Revenez plus tard pour l'écouter.'
	String restentSansDuree({required Object n}) => 'Il vous reste ${n} visites. Revenez plus tard pour l\'écouter.';

	/// fr: 'Vous avez utilisé vos visites pour cette séance. Vous pourrez observer la prochaine séance.'
	String get aucune => 'Vous avez utilisé vos visites pour cette séance. Vous pourrez observer la prochaine séance.';

	/// fr: 'Vous pourrez observer la prochaine séance.'
	String get prochaineSeance => 'Vous pourrez observer la prochaine séance.';

	/// fr: 'Vérification de vos visites restantes'
	String get verification => 'Vérification de vos visites restantes';

	/// fr: 'Vos visites restantes n'ont pas pu être vérifiées. Elles le seront de nouveau dans la classe.'
	String get inconnues => 'Vos visites restantes n\'ont pas pu être vérifiées. Elles le seront de nouveau dans la classe.';

	/// fr: 'Voir mes observations'
	String get voirObservations => 'Voir mes observations';
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

// Path: adulte.monEspace.pageAccords
class Traductions$adulte$monEspace$pageAccords$fr {
	Traductions$adulte$monEspace$pageAccords$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Vos accords ne sont pas encore consultables'
	String get indisponibleTitre => 'Vos accords ne sont pas encore consultables';

	/// fr: 'Accepter, refuser ou retirer chacun de vos accords n'est pas encore possible dans l'application. Aucun accord ne vous est demandé ici.'
	String get indisponiblePhrase => 'Accepter, refuser ou retirer chacun de vos accords n\'est pas encore possible dans l\'application. Aucun accord ne vous est demandé ici.';
}

// Path: adulte.monEspace.pageCoursAcces
class Traductions$adulte$monEspace$pageCoursAcces$fr {
	Traductions$adulte$monEspace$pageCoursAcces$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Cours et accès pas encore consultables'
	String get indisponibleTitre => 'Cours et accès pas encore consultables';

	/// fr: 'Le détail de vos cours, de vos séances et de votre accès n'est pas encore disponible dans l'application.'
	String get indisponiblePhrase => 'Le détail de vos cours, de vos séances et de votre accès n\'est pas encore disponible dans l\'application.';
}

// Path: adulte.famille.place
class Traductions$adulte$famille$place$fr {
	Traductions$adulte$famille$place$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Ajouter une conjointe'
	String get ajouterConjointe => 'Ajouter une conjointe';

	/// fr: 'Ajouter un conjoint'
	String get ajouterConjoint => 'Ajouter un conjoint';

	/// fr: 'Invitez votre conjointe à rejoindre Rewayah avec son propre compte.'
	String get inviterConjointe => 'Invitez votre conjointe à rejoindre Rewayah avec son propre compte.';

	/// fr: 'Invitez votre conjoint à rejoindre Rewayah avec son propre compte.'
	String get inviterConjoint => 'Invitez votre conjoint à rejoindre Rewayah avec son propre compte.';

	/// fr: 'Invitation envoyée'
	String get invitationEnvoyee => 'Invitation envoyée';

	/// fr: 'Ma conjointe · {prenom}'
	String maConjointe({required Object prenom}) => 'Ma conjointe · ${prenom}';

	/// fr: 'Mon conjoint · {prenom}'
	String monConjoint({required Object prenom}) => 'Mon conjoint · ${prenom}';

	/// fr: 'En attente de validation administrative'
	String get validationEnAttente => 'En attente de validation administrative';

	/// fr: 'Demande refusée par l'administration'
	String get validationRefusee => 'Demande refusée par l\'administration';

	/// fr: 'Nouvelle invitation possible à partir du {date}'
	String nouvelleInvitation({required Object date}) => 'Nouvelle invitation possible à partir du ${date}';

	/// fr: 'Envoyée à {courriel}'
	String envoyeeA({required Object courriel}) => 'Envoyée à ${courriel}';

	/// fr: 'L'invitation précédente a expiré. Vous pouvez en envoyer une nouvelle.'
	String get expiree => 'L\'invitation précédente a expiré. Vous pouvez en envoyer une nouvelle.';

	/// fr: 'L'invitation a été annulée et ne peut plus être acceptée. Vous pouvez en envoyer une nouvelle.'
	String get annulee => 'L\'invitation a été annulée et ne peut plus être acceptée. Vous pouvez en envoyer une nouvelle.';
}

// Path: adulte.demo.etats
class Traductions$adulte$demo$etats$fr {
	Traductions$adulte$demo$etats$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'L'adulte est seul, sans foyer.'
	String get adulteSeul => 'L\'adulte est seul, sans foyer.';

	/// fr: 'Le foyer n'a pas de second adulte.'
	String get titulaireSansConjoint => 'Le foyer n\'a pas de second adulte.';

	/// fr: 'L'invitation du second adulte est en attente.'
	String get invitationEnAttente => 'L\'invitation du second adulte est en attente.';

	/// fr: 'L'invitation du second adulte a expiré.'
	String get invitationExpiree => 'L\'invitation du second adulte a expiré.';

	/// fr: 'L'invitation du second adulte a été annulée.'
	String get invitationAnnulee => 'L\'invitation du second adulte a été annulée.';

	/// fr: 'Le second adulte fait partie du foyer.'
	String get conjointActif => 'Le second adulte fait partie du foyer.';

	/// fr: 'Le second adulte a quitté le foyer.'
	String get conjointQuitte => 'Le second adulte a quitté le foyer.';

	/// fr: 'Le second adulte a été retiré du foyer.'
	String get conjointRetire => 'Le second adulte a été retiré du foyer.';

	/// fr: 'Un délai de 60 jours est en cours.'
	String get delai60 => 'Un délai de 60 jours est en cours.';

	/// fr: 'Une nouvelle invitation est possible après le délai de 60 jours.'
	String get nouvelleDemande => 'Une nouvelle invitation est possible après le délai de 60 jours.';

	/// fr: 'La validation administrative est en attente.'
	String get validationEnAttente => 'La validation administrative est en attente.';

	/// fr: 'La validation administrative a été refusée.'
	String get validationRefusee => 'La validation administrative a été refusée.';

	/// fr: 'Le second adulte est parti pour la deuxième fois.'
	String get secondDepart => 'Le second adulte est parti pour la deuxième fois.';

	/// fr: 'Un délai de 120 jours est en cours.'
	String get delai120 => 'Un délai de 120 jours est en cours.';

	/// fr: 'Après le troisième départ, le délai reste de 120 jours.'
	String get departsSuivants => 'Après le troisième départ, le délai reste de 120 jours.';

	/// fr: 'Une demande de reprise du foyer a été déposée.'
	String get repriseDemandee => 'Une demande de reprise du foyer a été déposée.';

	/// fr: 'La demande de reprise a été refusée par le titulaire.'
	String get repriseRefuseeParTitulaire => 'La demande de reprise a été refusée par le titulaire.';

	/// fr: 'Après 30 jours sans réponse, la demande attend l'administration.'
	String get repriseSansReponse => 'Après 30 jours sans réponse, la demande attend l\'administration.';

	/// fr: 'La reprise du foyer a été validée.'
	String get repriseValidee => 'La reprise du foyer a été validée.';

	/// fr: 'La reprise du foyer a été refusée.'
	String get repriseRefusee => 'La reprise du foyer a été refusée.';

	/// fr: 'L'adulte invité fait déjà partie d'un autre foyer.'
	String get dejaDansUnAutreFoyer => 'L\'adulte invité fait déjà partie d\'un autre foyer.';

	/// fr: 'Le réseau a coupé pendant une action.'
	String get erreurReseau => 'Le réseau a coupé pendant une action.';

	/// fr: 'La même action a été envoyée deux fois.'
	String get doubleSoumission => 'La même action a été envoyée deux fois.';

	/// fr: 'La notification n'a pas pu partir sur le téléphone, elle reste visible dans l'application.'
	String get notificationDansLApplication => 'La notification n\'a pas pu partir sur le téléphone, elle reste visible dans l\'application.';

	/// fr: 'Un élève devenu adulte garde toutes ses données.'
	String get emancipation => 'Un élève devenu adulte garde toutes ses données.';
}

// Path: salle.preparation.eleve.guidee
class Traductions$salle$preparation$eleve$guidee$fr {
	Traductions$salle$preparation$eleve$guidee$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Préparation de la séance…'
	String get verification => 'Préparation de la séance…';

	/// fr: 'Tout est prêt.'
	String get pret => 'Tout est prêt.';

	/// fr: 'Le micro sera coupé en entrant.'
	String get microCoupe => 'Le micro sera coupé en entrant.';

	/// fr: 'Le micro est bloqué. On l'autorise ?'
	String get microQuestion => 'Le micro est bloqué. On l\'autorise ?';

	/// fr: 'Le micro est bloqué.'
	String get microBloque => 'Le micro est bloqué.';

	/// fr: 'La connexion ne marche pas pour l'instant.'
	String get horsLigne => 'La connexion ne marche pas pour l\'instant.';
}

// Path: salle.preparation.eleve.demo
class Traductions$salle$preparation$eleve$demo$fr {
	Traductions$salle$preparation$eleve$demo$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Préparation élève'
	String get section => 'Préparation élève';

	/// fr: 'Préparation élève, Interface guidée'
	String get sectionGuidee => 'Préparation élève, Interface guidée';

	/// fr: 'Vérification en cours'
	String get verification => 'Vérification en cours';

	/// fr: 'Prêt'
	String get pret => 'Prêt';

	/// fr: 'Micro bloqué'
	String get microBloque => 'Micro bloqué';

	/// fr: 'Hors ligne'
	String get horsLigne => 'Hors ligne';
}

// Path: salle.seance.demo.groupes
class Traductions$salle$seance$demo$groupes$fr {
	Traductions$salle$seance$demo$groupes$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Déroulé de la séance'
	String get seance => 'Déroulé de la séance';

	/// fr: 'Situations de secours'
	String get secours => 'Situations de secours';
}

// Path: salle.seance.demo.roles
class Traductions$salle$seance$demo$roles$fr {
	Traductions$salle$seance$demo$roles$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Élève standard'
	String get eleve => 'Élève standard';

	/// fr: 'Interface guidée'
	String get guidee => 'Interface guidée';

	/// fr: 'Enseignant'
	String get enseignant => 'Enseignant';
}

// Path: salle.seance.demo.etats
class Traductions$salle$seance$demo$etats$fr {
	Traductions$salle$seance$demo$etats$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Repos'
	String get repos => 'Repos';

	/// fr: 'Visite'
	String get visite => 'Visite';

	/// fr: 'Rien partagé'
	String get rienPartage => 'Rien partagé';

	/// fr: 'Appeler discrètement'
	String get appel => 'Appeler discrètement';

	/// fr: 'Panneau Élèves'
	String get eleves => 'Panneau Élèves';

	/// fr: 'Panneau Supports'
	String get supports => 'Panneau Supports';

	/// fr: 'Fin de séance'
	String get fin => 'Fin de séance';

	/// fr: 'Réseau faible'
	String get reseauFaible => 'Réseau faible';

	/// fr: 'Reconnexion'
	String get reconnexion => 'Reconnexion';

	/// fr: 'Connexion rétablie'
	String get retablie => 'Connexion rétablie';

	/// fr: 'Reconnexion impossible'
	String get echec => 'Reconnexion impossible';

	/// fr: 'Hors ligne'
	String get horsLigne => 'Hors ligne';

	/// fr: 'Micro bloqué'
	String get microBloque => 'Micro bloqué';

	/// fr: 'Caméra interdite'
	String get cameraInterdite => 'Caméra interdite';

	/// fr: 'Séance prolongée'
	String get prolongee => 'Séance prolongée';

	/// fr: 'Accès retiré'
	String get accesRetire => 'Accès retiré';
}

// Path: classe.entree.demo.roles
class Traductions$classe$entree$demo$roles$fr {
	Traductions$classe$entree$demo$roles$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Élève'
	String get eleve => 'Élève';

	/// fr: 'Élève, Interface guidée'
	String get guidee => 'Élève, Interface guidée';

	/// fr: 'Enseignant'
	String get enseignant => 'Enseignant';
}

// Path: classe.entree.demo.etats
class Traductions$classe$entree$demo$etats$fr {
	Traductions$classe$entree$demo$etats$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'À venir'
	String get aVenir => 'À venir';

	/// fr: 'Fenêtre ouverte'
	String get fenetreOuverte => 'Fenêtre ouverte';

	/// fr: 'Préparation en cours'
	String get preparation => 'Préparation en cours';

	/// fr: 'Attente avant le début'
	String get attente => 'Attente avant le début';

	/// fr: 'En direct'
	String get enDirect => 'En direct';

	/// fr: 'Temps prévu écoulé'
	String get tempsEcoule => 'Temps prévu écoulé';

	/// fr: 'Terminée'
	String get terminee => 'Terminée';

	/// fr: 'Annulée'
	String get annulee => 'Annulée';

	/// fr: 'Hors ligne'
	String get horsLigne => 'Hors ligne';

	/// fr: 'Information indisponible'
	String get indisponible => 'Information indisponible';

	/// fr: 'Changement d'heure'
	String get changementHeure => 'Changement d\'heure';
}

// Path: enseignant.journee.absence.etats
class Traductions$enseignant$journee$absence$etats$fr {
	Traductions$enseignant$journee$absence$etats$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Absence enregistrée'
	String get enregistree => 'Absence enregistrée';

	/// fr: 'Recherche d'un remplaçant'
	String get recherche => 'Recherche d\'un remplaçant';

	/// fr: 'Remplaçant confirmé'
	String get remplacantConfirme => 'Remplaçant confirmé';

	/// fr: 'Aucun remplaçant confirmé'
	String get aucunRemplacant => 'Aucun remplaçant confirmé';

	/// fr: 'Séance annulée'
	String get seanceAnnulee => 'Séance annulée';

	/// fr: 'Demande annulée'
	String get demandeAnnulee => 'Demande annulée';
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
			'commun.demonstration.repere' => 'Démonstration',
			'commun.demonstration.repereLu' => 'Mode Démonstration',
			'commun.etape.sur' => ({required Object n, required Object total}) => '${n} sur ${total}',
			'commun.etape.surLue' => ({required Object n, required Object total}) => 'Étape ${n} sur ${total}',
			'commun.choix.indisponible' => 'Indisponible',
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
			'commun.sections.page' => 'Sections de la page',
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
			'etat.seanceAnnulee' => 'Annulée',
			'etat.annuleeValeur' => ({required Object valeur}) => 'Annulée : ${valeur}',
			'etat.motifNonCommunique' => 'Motif non communiqué',
			'etat.aucunRemplacantTrouve' => 'Aucun remplaçant trouvé',
			'etat.seanceNonFacturee' => 'séance non facturée',
			'etat.raisonEtSuite' => ({required Object raison, required Object suite}) => '${raison} · ${suite}',
			'destructif.irreversible' => 'Cette action ne peut pas être annulée.',
			'salle.preparation.titre' => 'Préparer l\'entrée dans la classe',
			'salle.preparation.retour' => 'Retour à la Classe',
			'salle.preparation.cameraCoupee' => 'Caméra coupée',
			'salle.preparation.testerCamera' => 'Tester la caméra',
			'salle.preparation.testCameraFait' => 'Test local terminé. La caméra reste coupée à l\'entrée.',
			'salle.preparation.equipement' => 'Votre équipement',
			'salle.preparation.connexion' => 'Connexion',
			'salle.preparation.micro' => 'Micro',
			'salle.preparation.sortieAudio' => 'Sortie audio',
			'salle.preparation.camera' => 'Caméra',
			'salle.preparation.verification' => 'Vérification…',
			'salle.preparation.chargement' => 'Vérification du matériel…',
			'salle.preparation.connexionPrete' => 'Connexion prête',
			'salle.preparation.connexionInstable' => 'Connexion instable',
			'salle.preparation.reseauFaible' => 'Connexion instable. L\'audio sera prioritaire.',
			'salle.preparation.microPret' => 'Micro détecté · Micro coupé à l\'entrée',
			'salle.preparation.microAbsent' => 'Aucun micro détecté',
			'salle.preparation.microAbsentRaison' => 'Aucun micro détecté. Connectez ou activez un micro pour enseigner.',
			'salle.preparation.microBloque' => 'Micro bloqué',
			'salle.preparation.permissionRefusee' => 'Le micro est bloqué dans les réglages de cet appareil.',
			'salle.preparation.ouvrirReglages' => 'Ouvrir les réglages',
			'salle.preparation.reessayer' => 'Réessayer',
			'salle.preparation.sortieSysteme' => 'Sortie système',
			'salle.preparation.cameraPrete' => 'Caméra détectée · Caméra coupée à l\'entrée',
			'salle.preparation.cameraAbsente' => 'Caméra non disponible. Vous pouvez entrer sans caméra.',
			'salle.preparation.modifierPeripheriques' => 'Modifier les périphériques',
			'salle.preparation.contexte' => 'Contexte de la séance',
			'salle.preparation.classe' => 'Classe',
			'salle.preparation.debut' => 'Début',
			'salle.preparation.support' => 'Support prévu',
			'salle.preparation.reprise' => 'Reprise',
			'salle.preparation.eleves' => 'Élèves attendus',
			'salle.preparation.entrer' => 'Entrer dans la classe',
			'salle.preparation.terminee' => 'Cette séance est terminée.',
			'salle.preparation.nonAssignee' => 'Cette séance ne vous est pas attribuée.',
			'salle.preparation.retourJournee' => 'Retour à ma journée',
			'salle.preparation.demo.section' => 'Préparation enseignant',
			'salle.preparation.demo.pret' => 'Prêt',
			'salle.preparation.demo.reseauFaible' => 'Réseau faible',
			'salle.preparation.demo.microAbsent' => 'Micro absent',
			'salle.preparation.demo.permissionRefusee' => 'Permission refusée',
			'salle.preparation.eleve.verification' => 'Nous vérifions votre appareil…',
			'salle.preparation.eleve.pret' => 'Tout est prêt',
			'salle.preparation.eleve.audio' => 'Audio',
			'salle.preparation.eleve.acces' => 'Accès à la classe',
			'salle.preparation.eleve.accesOk' => 'Vous pouvez entrer',
			'salle.preparation.eleve.accesAttente' => 'En attente de la connexion',
			'salle.preparation.eleve.microCoupe' => 'Vous entrerez avec le micro coupé.',
			'salle.preparation.eleve.microInaccessible' => 'Votre micro n\'est pas accessible',
			'salle.preparation.eleve.microInaccessibleDetail' => 'Personne dans la classe ne pourra vous entendre tant que l\'accès au micro reste bloqué.',
			'salle.preparation.eleve.autoriserMicro' => 'Autoriser le micro',
			'salle.preparation.eleve.guidee.verification' => 'Préparation de la séance…',
			'salle.preparation.eleve.guidee.pret' => 'Tout est prêt.',
			'salle.preparation.eleve.guidee.microCoupe' => 'Le micro sera coupé en entrant.',
			'salle.preparation.eleve.guidee.microQuestion' => 'Le micro est bloqué. On l\'autorise ?',
			'salle.preparation.eleve.guidee.microBloque' => 'Le micro est bloqué.',
			'salle.preparation.eleve.guidee.horsLigne' => 'La connexion ne marche pas pour l\'instant.',
			'salle.preparation.eleve.demo.section' => 'Préparation élève',
			'salle.preparation.eleve.demo.sectionGuidee' => 'Préparation élève, Interface guidée',
			'salle.preparation.eleve.demo.verification' => 'Vérification en cours',
			'salle.preparation.eleve.demo.pret' => 'Prêt',
			'salle.preparation.eleve.demo.microBloque' => 'Micro bloqué',
			'salle.preparation.eleve.demo.horsLigne' => 'Hors ligne',
			'salle.bandeauPermanent' => 'Cours enregistré, visite de contrôle possible.',
			'salle.secours.reseauFaible' => 'Réseau faible. L\'audio est prioritaire.',
			'salle.secours.reseauFaibleGuidee' => 'Le réseau est faible.',
			'salle.secours.reseauFaibleGuideeSuite' => 'Le son reste prioritaire.',
			'salle.secours.reconnexion' => 'Connexion interrompue. Reconnexion en cours…',
			'salle.secours.reconnexionGuidee' => 'Reconnexion de la séance…',
			'salle.secours.retablie' => 'Connexion rétablie.',
			'salle.secours.echec' => 'Impossible de rétablir la connexion.',
			'salle.secours.echecGuidee' => 'La connexion ne revient pas.',
			'salle.secours.horsLigne' => 'Vous êtes hors ligne. La séance nécessite une connexion.',
			'salle.secours.reessayer' => 'Réessayer',
			'salle.secours.quitter' => 'Quitter',
			'salle.secours.indisponible' => ({required Object commande}) => '${commande}. Indisponible pendant la reconnexion.',
			'salle.secours.cameraInterdite' => 'Caméra désactivée pour ce profil.',
			'salle.secours.microBloque' => 'Le micro est bloqué dans les réglages de cet appareil.',
			'salle.secours.microBloqueGuidee' => 'Le micro est bloqué sur cet appareil.',
			'salle.secours.continuerSansMicro' => 'Continuer sans micro',
			'salle.secours.ouvrirReglages' => 'Ouvrir les réglages',
			'salle.seance.titre' => 'Séance en direct',
			'salle.seance.titreGuidee' => 'Ma séance',
			'salle.seance.ligne' => ({required Object debut, required Object fin}) => '${debut} · ${fin}',
			'salle.seance.minutesRestantes' => ({required Object minutes}) => '${minutes} min restantes',
			'salle.seance.sePoursuit' => 'La séance se poursuit.',
			'salle.seance.enLigne' => 'En ligne',
			'salle.seance.reconnexion' => 'Reconnexion',
			'salle.seance.coursEnregistreCourt' => 'Le cours est enregistré.',
			'salle.seance.votreParentObserve' => 'Votre parent observe la séance.',
			'salle.seance.tonParentObserve' => 'Ton parent observe la séance.',
			'salle.seance.tuteurDeObserve' => ({required Object prenom}) => 'Tuteur de ${prenom} observe.',
			'salle.seance.unParentObserve' => 'Un parent observe cette séance',
			'salle.seance.leTuteurDeObserve' => ({required Object prenom}) => 'Le tuteur de ${prenom} observe la séance.',
			'salle.seance.mentionEtNotice' => ({required Object mention, required Object notice}) => '${mention} ${notice}',
			'salle.seance.retour' => 'Retour',
			'salle.seance.notifications' => 'Notifications',
			'salle.seance.reglages' => 'Réglages',
			'salle.seance.compteDe' => ({required Object nom}) => 'Compte de ${nom}',
			'salle.seance.sortir' => 'Quitter la séance',
			'salle.seance.compteurEleves' => ({required Object connectes, required Object inscrits}) => 'Élèves ${connectes}/${inscrits}',
			'salle.seance.parler' => 'Parler',
			'salle.seance.agrandir' => 'Agrandir',
			'salle.seance.reduire' => 'Réduire',
			'salle.seance.rienPartage' => ({required Object nom}) => '${nom} n\'a rien partagé pour l\'instant.',
			'salle.seance.videoDe' => ({required Object nom}) => 'Vidéo de ${nom}',
			'salle.seance.page' => ({required Object page, required Object pages}) => '${page} / ${pages}',
			'salle.seance.pageSemantique' => ({required Object page, required Object pages}) => 'Page ${page} sur ${pages}',
			'salle.seance.zoomLocal' => 'Zoom local, sans effet sur les autres',
			'salle.seance.zoomValeur' => ({required Object valeur}) => '${valeur} %',
			'salle.seance.zoomMoins' => 'Réduire le zoom',
			'salle.seance.zoomPlus' => 'Augmenter le zoom',
			'salle.seance.quitterQuestion' => 'Quitter la séance ?',
			'salle.seance.quitterConsequence' => 'Vous pourrez revenir si la séance est encore ouverte.',
			'salle.seance.illustration' => 'Illustration du support',
			'salle.seance.quitterCahierConsequence' => 'Vous passerez ensuite au cahier de transmission.',
			'salle.seance.quitterCahier' => 'Quitter et ouvrir le cahier',
			'salle.seance.rester' => 'Rester',
			'salle.seance.supports' => 'Supports',
			'salle.seance.reseau' => 'Réseau',
			'salle.seance.pagePrecedente' => 'Page précédente',
			'salle.seance.pageSuivante' => 'Page suivante',
			'salle.seance.outils.titre' => 'Outils d\'enseignement',
			'salle.seance.outils.pointeur' => 'Pointeur',
			'salle.seance.outils.marquer' => 'Marquer',
			'salle.seance.outils.masquer' => 'Masquer',
			'salle.seance.outils.annoter' => 'Annoter',
			'salle.seance.rail.navigation' => 'Navigation',
			'salle.seance.rail.marque' => 'Rewayah',
			'salle.seance.rail.sousMarque' => 'Academy',
			'salle.seance.rail.journee' => 'Journée',
			'salle.seance.rail.classes' => 'Classes',
			'salle.seance.rail.ressources' => 'Ressources',
			'salle.seance.rail.profil' => 'Profil',
			'salle.seance.fermerPanneau' => 'Fermer le panneau',
			'salle.seance.panneauSupports.reprendre' => 'Reprendre',
			'salle.seance.panneauSupports.recents' => 'Récents',
			'salle.seance.panneauSupports.ressourcesClasse' => 'Ressources de la Classe',
			'salle.seance.panneauSupports.voirTout' => 'Voir tout',
			'salle.seance.panneauSupports.ouvrir' => 'Ouvrir',
			'salle.seance.panneauSupports.ouvrirSupport' => ({required Object titre}) => 'Ouvrir ${titre}',
			'salle.seance.panneauSupports.voirBibliotheque' => 'Voir toute la bibliothèque',
			'salle.seance.eleves' => 'Élèves',
			'salle.seance.rappeler' => 'Appeler discrètement',
			'salle.seance.faireReciter' => 'Faire réciter',
			'salle.seance.fileRecitation' => 'File de récitation',
			'salle.seance.aSuivre' => 'À suivre',
			'salle.seance.vousAppelle' => ({required Object nom}) => '${nom} vous appelle',
			'salle.seance.signalerBesoin' => 'Signaler un besoin',
			'salle.seance.deplierFiche' => ({required Object prenom}) => 'Afficher la fiche de ${prenom}',
			'salle.seance.replierFiche' => ({required Object prenom}) => 'Masquer la fiche de ${prenom}',
			'salle.seance.fiche.aucuneSeanceSemaine' => 'Aucune séance cette semaine',
			'salle.seance.fiche.uneSeanceSemaine' => '1 séance cette semaine',
			'salle.seance.fiche.seancesSemaine' => ({required Object nombre}) => '${nombre} séances cette semaine',
			'salle.seance.optionsPanneau' => ({required Object titre}) => 'Options du panneau ${titre}',
			'salle.seance.demo.titre' => 'Salle de démonstration',
			'salle.seance.demo.intro' => 'Données fictives, aucun serveur. Choisissez un rôle et un état.',
			'salle.seance.demo.groupes.seance' => 'Déroulé de la séance',
			'salle.seance.demo.groupes.secours' => 'Situations de secours',
			'salle.seance.demo.roles.eleve' => 'Élève standard',
			'salle.seance.demo.roles.guidee' => 'Interface guidée',
			'salle.seance.demo.roles.enseignant' => 'Enseignant',
			'salle.seance.demo.etats.repos' => 'Repos',
			'salle.seance.demo.etats.visite' => 'Visite',
			'salle.seance.demo.etats.rienPartage' => 'Rien partagé',
			'salle.seance.demo.etats.appel' => 'Appeler discrètement',
			'salle.seance.demo.etats.eleves' => 'Panneau Élèves',
			'salle.seance.demo.etats.supports' => 'Panneau Supports',
			'salle.seance.demo.etats.fin' => 'Fin de séance',
			'salle.seance.demo.etats.reseauFaible' => 'Réseau faible',
			'salle.seance.demo.etats.reconnexion' => 'Reconnexion',
			'salle.seance.demo.etats.retablie' => 'Connexion rétablie',
			'salle.seance.demo.etats.echec' => 'Reconnexion impossible',
			'salle.seance.demo.etats.horsLigne' => 'Hors ligne',
			'salle.seance.demo.etats.microBloque' => 'Micro bloqué',
			'salle.seance.demo.etats.cameraInterdite' => 'Caméra interdite',
			'salle.seance.demo.etats.prolongee' => 'Séance prolongée',
			'salle.seance.demo.etats.accesRetire' => 'Accès retiré',
			'salle.seance.statut.connecte' => 'Connecté',
			'salle.seance.statut.pasEncoreConnecte' => 'Pas encore connecté',
			'salle.seance.statut.connexionInterrompue' => 'Connexion interrompue',
			'salle.fin.titre' => 'Séance terminée',
			'salle.fin.phrase' => 'Vous pouvez retrouver votre travail dans votre Classe.',
			'salle.fin.retourClasse' => 'Retour à la Classe',
			'salle.fin.quitteTitre' => 'Vous avez quitté la séance.',
			'salle.fin.quittePhrase' => 'Vous pourrez revenir tant qu\'elle reste ouverte.',
			'salle.fin.accesRetireTitre' => 'Votre accès à cette séance a pris fin.',
			'salle.fin.titreGuidee' => 'La séance est terminée.',
			'salle.fin.retourAccueil' => 'Retour à l\'accueil',
			'salle.fin.enseignant.terminee' => 'Terminée',
			'salle.fin.enseignant.phrase' => 'Le cahier est prêt avec les informations de la séance.',
			'salle.fin.enseignant.recapitulatif' => 'Récapitulatif de la séance',
			'salle.fin.enseignant.fin' => 'Fin',
			'salle.fin.enseignant.connectes' => ({required Object n}) => '${n} élèves connectés',
			'salle.fin.enseignant.unConnecte' => ({required Object n}) => '${n} élève connecté',
			'salle.fin.enseignant.inscrits' => ({required Object n}) => 'sur ${n} inscrits',
			'salle.fin.enseignant.unInscrit' => ({required Object n}) => 'sur ${n} inscrit',
			'salle.fin.enseignant.cahierSeance' => 'Cahier de séance',
			'salle.fin.enseignant.cahierACompleter' => 'Cahier à compléter',
			'salle.fin.enseignant.ouvrirCahier' => 'Ouvrir le cahier',
			'salle.fin.enseignant.revenirJournee' => 'Revenir à ma journée',
			'salle.fin.enseignant.erreurCahier' => 'Le cahier ne peut pas être ouvert pour le moment.',
			'salle.micro' => 'Micro',
			'salle.microCoupe' => 'Micro coupé',
			'salle.microOuvert' => 'Micro ouvert',
			'salle.camera' => 'Caméra',
			'salle.cameraCoupee' => 'Caméra éteinte',
			'salle.cameraAllumee' => 'Caméra allumée',
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
			'salle.visiteControle.titre' => 'Contrôle Rewayah',
			'salle.visiteControle.sonRecu' => 'Son reçu',
			'salle.visiteControle.sonCoupe' => 'Son coupé',
			'salle.visiteControle.couperSon' => 'Couper le son reçu',
			'salle.visiteControle.retablirSon' => 'Rétablir le son reçu',
			'salle.visiteControle.agrandir' => 'Agrandir le support',
			'salle.visiteControle.reduire' => 'Réduire le support',
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
			'bienvenue.accroche' => 'Apprendre le Coran en classe, avec un enseignant attitré',
			'bienvenue.phrase' => 'Des séances en visio, à horaire fixe, pour vous ou pour les élèves de votre foyer.',
			'bienvenue.pointsTitre' => 'Comment ça se passe',
			'bienvenue.pointClasseTitre' => 'Une classe stable',
			'bienvenue.pointClasse' => 'Les mêmes camarades et le même horaire, chaque semaine.',
			'bienvenue.pointEnseignantTitre' => 'Un enseignant attitré',
			'bienvenue.pointEnseignant' => 'Un Sayyid ou une Sayyida qui suit chaque élève d\'une séance à l\'autre.',
			'bienvenue.pointFoyerTitre' => 'Un seul compte pour le foyer',
			'bienvenue.pointFoyer' => 'Les séances de chaque élève du foyer se suivent depuis votre compte.',
			'bienvenue.commencer' => 'Commencer',
			'bienvenue.dejaCompte' => 'J\'ai déjà un compte',
			'attente.titre' => 'Votre dossier est en cours de vérification',
			'attente.dossierIncomplet' => 'Il manque encore des pièces à votre dossier.',
			'attente.enVerification' => 'Nous vérifions votre dossier.',
			'attente.refuse' => 'Dossier refusé',
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
			'attente.corriger' => 'Corriger',
			'attente.correctionImpossible' => 'Ce dossier ne peut pas être modifié pour le moment.',
			'attente.actualiser' => 'Actualiser l\'état du dossier',
			'attente.suspenduDetail' => 'Vous pouvez joindre l\'académie pour connaître la marche à suivre.',
			'attente.seDeconnecter' => 'Se déconnecter',
			'attente.titreDossier' => 'Votre dossier',
			'attente.titreCompte' => 'Votre compte',
			'attente.accordsARelire' => 'Il vous reste nos conditions à lire et à accepter.',
			'attente.accesTitre' => 'Votre compte est créé',
			'attente.accesEnPreparation' => 'L\'ouverture de votre compte n\'est pas encore automatique.',
			'attente.aucunDocument' => 'Vous n\'avez aucun document à envoyer.',
			'attente.accesContact' => 'L\'académie peut l\'ouvrir pour vous : joignez-la.',
			'attente.actualiserCompte' => 'Actualiser',
			'attente.reste' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: 'Il reste un élément à fournir.', other: 'Il reste ${n} éléments à fournir.', ), 
			'attente.etatAFournir' => 'À fournir',
			'attente.prochaineEtape' => ({required Object etape}) => 'Prochaine étape : ${etape}',
			'attente.refuseDetail' => ({required Object element}) => 'Pour relancer la vérification, commencez par cet élément : ${element}.',
			'attente.refuseSansElement' => 'Vous pouvez joindre l\'académie pour connaître la marche à suivre.',
			'attente.illisible' => 'L\'état de votre dossier ne s\'affiche pas pour le moment.',
			'attente.horsLigne' => 'Vous êtes hors ligne. L\'état de votre dossier s\'affichera dès le retour du réseau.',
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
			'connexion.renvoyer' => 'Renvoyer le lien',
			'connexion.renvoye' => ({required Object courriel}) => 'Un nouveau lien est parti à ${courriel}. Utilisez celui du message le plus récent.',
			'connexion.erreurTropTot' => 'Un lien vient déjà de partir. Attendez un moment avant d\'en demander un autre.',
			'connexion.horsLigne' => 'Vous êtes hors ligne : le lien ne peut pas partir pour l\'instant.',
			'connexion.probleme' => 'Lien expiré ou jamais reçu ?',
			'connexion.decouvrir' => 'Découvrir Rewayah Academy',
			'connexion.recuperation.titre' => 'Retrouver mon accès',
			'connexion.recuperation.intro' => 'Il n\'y a pas de mot de passe à réinitialiser : indiquez votre adresse, nous vous envoyons un nouveau lien de connexion.',
			'connexion.recuperation.lienExpireTitre' => 'Ce lien n\'est plus valable',
			'connexion.recuperation.lienExpire' => 'Un lien de connexion ne sert qu\'une fois et expire au bout d\'un moment. Demandez-en un nouveau ci-dessous.',
			'connexion.recuperation.lienRefuseTitre' => 'La connexion n\'a pas abouti',
			'connexion.recuperation.lienRefuse' => 'Ce lien n\'a pas pu vous connecter. Demandez-en un nouveau ci-dessous.',
			'connexion.recuperation.envoyer' => 'Recevoir un nouveau lien',
			'connexion.recuperation.envoyeTitre' => 'Nouveau lien envoyé',
			'connexion.recuperation.envoye' => ({required Object courriel}) => 'Ouvrez le message envoyé à ${courriel}, puis suivez le lien.',
			'connexion.recuperation.envoyeEncart' => 'Le message peut mettre quelques minutes à arriver. Pensez à regarder dans les courriers indésirables.',
			'connexion.recuperation.autreAdresse' => 'Utiliser une autre adresse',
			'connexion.recuperation.revenirConnexion' => 'Revenir à la connexion',
			'connexion.feuilleAppareil.pourQui' => 'Réservé aux tuteurs déjà inscrits. Cet écran donne à un élève de votre foyer son propre accès, sur sa tablette ou son téléphone, sans lui confier votre compte.',
			'connexion.feuilleAppareil.etapesTitre' => 'Où trouver le code',
			'connexion.feuilleAppareil.etape1' => 'Sur votre propre appareil, ouvrez Foyer, puis Appareils du foyer.',
			'connexion.feuilleAppareil.etape2' => 'Touchez le profil de l\'élève, puis Connecter un appareil.',
			'connexion.feuilleAppareil.etape3' => 'Un QR code et un code de six caractères s\'affichent, avec leur heure de fin.',
			'connexion.feuilleAppareil.etape4' => 'Sur l\'appareil de l\'élève, scannez le QR code ou saisissez le code.',
			'connexion.feuilleAppareil.plafond' => 'Le nombre d\'appareils par élève est limité. Si la limite est atteinte, retirez-en un depuis Foyer, Appareils du foyer.',
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
			'inscription.etapeCourte' => ({required Object n, required Object total}) => '${n} sur ${total}',
			'inscription.retourEtape' => 'Revenir à l\'étape précédente',
			'inscription.seDeconnecter' => 'Se déconnecter',
			'inscription.modifier' => 'Modifier',
			'inscription.reessayer' => 'Réessayer',
			'inscription.erreurActualisation' => 'Votre compte est créé, mais la connexion n\'a pas pu être actualisée. Réessayez, ou déconnectez-vous puis reconnectez-vous.',
			'inscription.usage.question' => 'Quel type de compte souhaitez-vous créer ?',
			'inscription.usage.moiTitre' => 'Moi uniquement',
			'inscription.usage.moiDescription' => 'Je souhaite suivre les cours avec mon propre profil élève.',
			'inscription.usage.familleTitre' => 'Moi et ma famille',
			'inscription.usage.familleDescription' => 'Inscrivez vos enfants ou vos proches, avec ou sans vous. Vous pourrez créer votre propre profil élève à tout moment.',
			'inscription.usage.enseignant' => 'Je suis enseignant',
			'inscription.recap.usage' => 'Type de compte',
			'inscription.recap.identite' => 'Nom',
			'inscription.recap.genre' => 'Genre',
			'inscription.recap.enseignant' => 'Enseignant',
			'contrat.titre' => 'Ce que vous signez',
			'contrat.intro' => 'Deux points comptent plus que les autres. Ils sont écrits ici en clair plutôt qu\'au milieu d\'un texte long.',
			'contrat.pointEnregistrement' => 'Chaque cours est enregistré en audio, conservé trente jours, puis effacé. Chaque écoute est inscrite au journal, avec le nom de qui écoute.',
			'contrat.pointControle' => 'Un contrôleur qualité peut assister à un cours sans être vu. La salle le rappelle en permanence, que la visite ait lieu ou non.',
			'contrat.pointCoordonnees' => 'Vous ne voyez jamais les coordonnées d\'une famille : ni nom complet, ni courriel, ni téléphone.',
			'contrat.lireTexte' => 'Lire le texte complet',
			'contrat.accepter' => 'J\'ai lu et j\'accepte',
			'contrat.accepteLe' => ({required Object date}) => 'Accepté le ${date}',
			_ => null,
		} ?? switch (path) {
			'contrat.erreur' => 'La signature n\'a pas abouti. Réessayez dans un instant.',
			'contrat.horsLigne' => 'Vous êtes hors ligne. Votre accord sera enregistré dès le retour du réseau, en appuyant de nouveau.',
			'contrat.caseRequise' => 'Cochez la case pour continuer.',
			'accessibilite.demo.titre' => 'Démonstration du Mode Accessibilité',
			'accessibilite.demo.mention' => 'Données fictives, aucun envoi.',
			'accessibilite.demo.intro' => 'Choisissez un élève et un moment de la séance.',
			'accessibilite.demo.eleveMineure' => 'Mariam, élève mineure',
			'accessibilite.demo.eleveAdulte' => 'Idriss, élève adulte',
			'accessibilite.demo.etatAvant' => 'Avant la séance',
			'accessibilite.demo.etatFenetre' => 'Juste avant la séance, l\'entrée est ouverte',
			'accessibilite.demo.etatPendant' => 'Pendant la séance',
			'accessibilite.demo.etatApres' => 'Après la séance',
			'accessibilite.accueil.salutation' => ({required Object prenom}) => 'As-salāmu ’alaykum, ${prenom}.',
			'accessibilite.accueil.prochaineSeance' => 'Prochaine séance',
			'accessibilite.accueil.avec' => ({required Object nomme}) => 'avec ${nomme}',
			'accessibilite.accueil.voirMaClasse' => 'Voir ma classe',
			'accessibilite.accueil.lireCoran' => 'Lire le Coran',
			'accessibilite.accueil.lireCoranDetail' => 'Accéder au Mushaf',
			'accessibilite.accueil.aide' => 'Besoin d\'aide ?',
			'accessibilite.coran.ouvrir' => 'Ouvrir le Coran',
			'accessibilite.coran.reprendre' => 'Reprendre là où tu t\'es arrêté(e)',
			'accessibilite.coran.reprendreVous' => 'Reprendre là où vous vous êtes arrêté(e)',
			'accessibilite.coran.reprendreDetail' => ({required Object page}) => 'Tu en étais page ${page}.',
			'accessibilite.coran.reprendreDetailVous' => ({required Object page}) => 'Vous en étiez page ${page}.',
			'accessibilite.coran.lectureGrande' => 'Le Coran s\'ouvre en lecture agrandie, verset par verset.',
			'accessibilite.coran.retour' => 'Retour à l\'entrée du Coran',
			'accessibilite.maClasse.titre' => 'Ma classe',
			'accessibilite.maClasse.suivi' => 'Mon suivi',
			'accessibilite.maClasse.suiviDetail' => 'Les séances passées et la présence',
			'accessibilite.tutoiement.tonHeure' => 'Ton heure',
			'accessibilite.tutoiement.attenteDetail' => 'Ce temps d\'attente ne compte pas dans ta présence.',
			'accessibilite.tutoiement.attente' => ({required Object duree}) => 'Tu es dans la salle. La séance commence dans ${duree}.',
			'accessibilite.tutoiement.attenteImminent' => 'Tu es dans la salle. La séance commence dans moins d\'une minute.',
			'accessibilite.tutoiement.annonceAttente' => 'Tu es dans la salle',
			'accessibilite.tutoiement.horsLigne' => 'Tu es hors ligne. La séance nécessite une connexion.',
			'accessibilite.tutoiement.finPhrase' => 'Tu peux retrouver ton travail dans ta Classe.',
			'accessibilite.apres.revoirSupport' => 'Revoir le support du cours',
			'accessibilite.apres.revoirSupportDetail' => 'Le support reste dans ta Classe.',
			'accessibilite.apres.revoirSupportDetailVous' => 'Le support reste dans votre Classe.',
			'accuse.titre' => 'À savoir avant de commencer',
			'accuse.compris' => 'J\'ai compris',
			'consentement.titre' => 'Consentements',
			'consentement.texte.titre' => 'Les visites des parents',
			'consentement.texte.quiResponsable' => 'Les parents des élèves présents peuvent observer brièvement la séance.',
			'consentement.texte.quiResponsableDetail' => 'Ils entendent l\'enseignant et les élèves qui prennent la parole, y compris votre enfant. Leur micro et leur caméra restent désactivés : ils ne peuvent ni parler, ni écrire, ni apparaître à l\'écran.',
			'consentement.texte.quiAdulte' => 'Les parents des autres élèves présents peuvent observer brièvement la séance.',
			'consentement.texte.quiAdulteDetail' => 'Ils entendent l\'enseignant et les élèves qui prennent la parole, y compris vous. Leur micro et leur caméra restent désactivés : ils ne peuvent ni parler, ni écrire, ni apparaître à l\'écran.',
			'consentement.texte.pourquoi' => 'Pour suivre l\'apprentissage sans interrompre la classe.',
			'consentement.texte.pourquoiDetail' => 'Un parent vient voir si son enfant participe, puis repart. La salle rappelle en permanence qu\'une visite est possible.',
			'consentement.texte.limites' => 'Des visites courtes, en nombre limité.',
			'consentement.texte.limitesDetail' => 'Chaque parent a un petit nombre de visites par séance, fixé par l\'académie et rappelé dans « Comment ça marche ? ». Une visite quittée avant la fin compte comme une visite.',
			'consentement.texte.caseResponsable' => 'J\'accepte ces modalités pour mon enfant',
			'consentement.texte.caseAdulte' => 'J\'accepte ces modalités',
			'consentement.texte.continuer' => 'Continuer',
			'consentement.texte.retour' => 'Retour',
			'consentement.comment.titre' => 'Comment ça marche ?',
			'consentement.comment.visites' => ({required num n, required Object minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: 'Une visite de ${minutes} min par séance.', other: '${n} visites de ${minutes} min par séance.', ), 
			'consentement.comment.visitesSansDuree' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: 'Une visite courte par séance.', other: '${n} visites courtes par séance.', ), 
			'consentement.comment.parParent' => 'Ce nombre vaut pour chaque parent, que la séance réunisse un ou plusieurs de ses enfants.',
			'consentement.comment.ecourtee' => 'Une visite quittée avant la fin est comptée : il ne reste alors que la suivante, jusqu\'à la dernière.',
			'consentement.comment.ecouter' => 'Vous entendez l\'enseignant et les élèves qui prennent la parole, y compris votre enfant.',
			'consentement.comment.sansMicro' => 'Votre micro et votre caméra restent désactivés pendant la visite.',
			'consentement.comment.valeursIndisponibles' => 'Le nombre de visites et leur durée s\'affichent depuis la classe de votre enfant, selon les règles de sa classe.',
			'consentement.comment.fermee' => 'Les visites d\'observation ne sont pas ouvertes pour cette classe.',
			'consentement.compte.intro' => 'L\'académie a ajouté à ses conditions un paragraphe sur les visites des parents. Rien n\'est considéré comme accepté tant que vous ne l\'avez pas fait.',
			'consentement.compte.accepteLe' => ({required Object date}) => 'Vous avez accepté ces modalités le ${date}.',
			'consentement.compte.merci' => 'Merci, votre accord est enregistré.',
			'consentement.compte.chargement' => 'Lecture de vos accords',
			'consentement.compte.erreur' => 'Vos accords ne s\'affichent pas pour le moment.',
			'consentement.compte.horsLigne' => 'Vous êtes hors ligne. Vos accords s\'afficheront dès le retour du réseau.',
			'consentement.compte.sansProfil' => 'Aucun compte connecté : reconnectez-vous pour lire vos accords.',
			'consentement.compte.invite' => 'Une nouvelle version à lire : les visites des parents',
			'consentement.compte.inviteAction' => 'Lire',
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
			'appareils.foyer.titre' => 'Appareils du foyer',
			'appareils.foyer.phrase' => 'Chaque profil élève a ses propres appareils. Touchez un profil pour voir ses appareils, en retirer un ou en connecter un nouveau.',
			'appareils.foyer.groupeProfils' => 'Profils élèves',
			'appareils.foyer.aucunAppareil' => 'Aucun appareil connecté',
			'appareils.foyer.unAppareil' => ({required Object nom}) => '1 appareil connecté : ${nom}',
			'appareils.foyer.plusieursAppareils' => ({required Object nombre, required Object noms}) => '${nombre} appareils connectés : ${noms}',
			'appareils.foyer.partageTitre' => 'Appareil partagé',
			'appareils.foyer.partage' => 'Sur un appareil partagé, chaque élève choisit son profil puis saisit son code personnel. Cet appareil apparaît alors sous chaque profil qui l\'utilise.',
			'appareils.foyer.videTitre' => 'Aucun profil élève',
			'appareils.foyer.vide' => 'Ajoutez un profil élève pour lui connecter une tablette, un téléphone ou un ordinateur.',
			'appareils.foyer.videAction' => 'Ajouter un profil élève',
			'appareils.eleve.sousTitre' => ({required Object prenom}) => 'Gérez les appareils autorisés pour ${prenom}.',
			'appareils.eleve.groupe' => 'Appareils connectés',
			'appareils.eleve.connecter' => 'Connecter un appareil',
			'appareils.eleve.videTitre' => 'Aucun appareil connecté',
			'appareils.eleve.vide' => ({required Object prenom}) => 'Connectez la tablette, le téléphone ou l\'ordinateur de ${prenom} avec le code affiché par le bouton ci-dessous.',
			'appareils.eleve.introuvableTitre' => 'Profil élève introuvable',
			'appareils.eleve.introuvable' => 'Ce profil élève n\'est pas rattaché à votre foyer.',
			'appareils.eleve.introuvableAction' => 'Voir les appareils du foyer',
			'appareils.eleve.connecteLe' => ({required Object date}) => 'Connecté le ${date}',
			'appareils.eleve.utiliseLe' => ({required Object date}) => 'Dernière utilisation : ${date}',
			'appareils.eleve.jamaisUtilise' => 'Pas encore utilisé',
			'appareils.eleve.retirerLibelle' => ({required Object appareil}) => 'Retirer ${appareil}',
			'appareils.eleve.horsLigne' => 'Retirer ou connecter un appareil demande une connexion internet.',
			'appareils.eleve.partageTitre' => 'Choix du profil et code personnel',
			'appareils.eleve.partage' => 'Sur un appareil partagé, chaque élève choisit son profil puis saisit son propre code personnel, gardé sur cet appareil.',
			'appareils.eleve.retraitTitre' => 'Retirer un appareil',
			'appareils.eleve.retrait' => 'Un appareil retiré ne peut plus se reconnecter. S\'il est connecté en ce moment, il le reste jusqu\'à sa prochaine déconnexion.',
			'appareils.plateforme.android' => 'Téléphone ou tablette Android',
			'appareils.plateforme.ios' => 'iPhone ou iPad',
			'appareils.plateforme.web' => 'Navigateur web',
			'appareils.plateforme.windows' => 'Ordinateur',
			'appareils.plateforme.inconnue' => 'Appareil',
			'appareils.retrait.question' => 'Retirer cet appareil ?',
			'appareils.retrait.consequence' => ({required Object appareil, required Object prenom}) => '${appareil} ne pourra plus se connecter au profil de ${prenom}. S\'il est connecté en ce moment, il le reste jusqu\'à sa prochaine déconnexion.',
			'appareils.retrait.confirmer' => 'Retirer l\'appareil',
			'appareils.retrait.enCours' => 'Retrait en cours',
			'appareils.retrait.reussi' => 'Appareil retiré. S\'il est connecté en ce moment, il le reste jusqu\'à sa prochaine déconnexion.',
			'appareils.retrait.echec' => 'Le retrait n\'a pas abouti. L\'appareil est toujours autorisé. Réessayez dans un instant.',
			'appareils.retrait.horsLigne' => 'Pas de connexion internet : l\'appareil n\'a pas été retiré.',
			'appareils.emetteur.titre' => 'Connecter un appareil',
			'appareils.emetteur.pourEleve' => ({required Object prenom}) => 'Pour ${prenom}',
			'appareils.emetteur.consigneTitre' => 'Sur l\'autre appareil',
			'appareils.emetteur.consigne' => 'Ouvrez Rewayah, touchez « Connecter l\'appareil d\'un élève », puis scannez ce QR ou saisissez le code.',
			'appareils.emetteur.libelleQr' => 'QR de connexion. Le même code est aussi écrit sur cet écran, à saisir si l\'appareil ne lit pas le QR.',
			'appareils.emetteur.codeManuel' => 'Code à saisir',
			'appareils.emetteur.codeLu' => ({required Object code}) => 'Code à saisir : ${code}',
			'appareils.emetteur.valableJusqua' => ({required Object heure}) => 'Valable jusqu\'à ${heure}',
			'appareils.emetteur.restant' => ({required Object temps}) => 'Encore ${temps}',
			'appareils.emetteur.sortie' => ({required Object heure}) => 'Quitter cet écran n\'annule pas le code : il reste valable jusqu\'à ${heure}.',
			'appareils.emetteur.suiviIndisponible' => 'Cet écran ne peut pas confirmer la connexion. Vérifiez sur l\'appareil de l\'élève.',
			'appareils.emetteur.preparation' => 'Préparation du code',
			'appareils.emetteur.verification.titre' => 'Vérification du code',
			'appareils.emetteur.verification.phrase' => 'Le code est masqué le temps de vérifier qu\'il est toujours valable.',
			'appareils.emetteur.confirme.titre' => 'Appareil connecté',
			'appareils.emetteur.confirme.phrase' => ({required Object prenom}) => 'L\'appareil de ${prenom} est prêt. Le code n\'est plus affiché et ne peut plus servir.',
			'appareils.emetteur.confirme.phraseSansPrenom' => 'L\'appareil de l\'élève est prêt. Le code n\'est plus affiché et ne peut plus servir.',
			'appareils.emetteur.confirme.action' => 'Terminé',
			'appareils.emetteur.expire.titre' => 'Ce code a expiré',
			'appareils.emetteur.expire.phrase' => 'Il ne peut plus servir. Générez-en un nouveau quand l\'autre appareil est prêt.',
			'appareils.emetteur.remplace.titre' => 'Ce code a été remplacé',
			'appareils.emetteur.remplace.phrase' => 'Un nouveau code a été demandé pour cet élève, ici ou sur un autre appareil. Celui-ci ne marche plus.',
			'appareils.emetteur.dejaActif.titre' => 'Un code est déjà valable',
			'appareils.emetteur.dejaActif.phrase' => ({required Object heure}) => 'Un code créé pour cet élève vaut jusqu\'à ${heure}. Il ne peut pas être réaffiché : en générer un nouveau rendra l\'ancien inutilisable.',
			'appareils.emetteur.horsLigne.titre' => 'Connexion interrompue',
			'appareils.emetteur.horsLigne.phraseAvecCode' => ({required Object heure}) => 'Le code est masqué jusqu\'au retour de la connexion. Il reste valable jusqu\'à ${heure}.',
			'appareils.emetteur.horsLigne.phraseSansCode' => 'Le code n\'a pas pu être préparé. Il le sera dès le retour de la connexion.',
			'appareils.emetteur.erreur.plafondTitre' => 'Limite d\'appareils atteinte',
			'appareils.emetteur.erreur.plafondPhrase' => 'Cet élève a déjà le nombre maximal d\'appareils. Retirez-en un pour en connecter un autre.',
			'appareils.emetteur.erreur.plafondAction' => 'Voir les appareils',
			'appareils.emetteur.erreur.horsFoyerTitre' => 'Profil élève introuvable',
			'appareils.emetteur.erreur.horsFoyerPhrase' => 'Ce profil élève n\'est pas rattaché à votre foyer. Revenez au Foyer pour en choisir un.',
			'appareils.emetteur.erreur.compteTitre' => 'Connexion d\'appareil pas encore ouverte',
			'appareils.emetteur.erreur.comptePhrase' => 'Votre compte doit être ouvert avant de connecter l\'appareil d\'un élève.',
			'appareils.emetteur.erreur.generiqueTitre' => 'Le code n\'a pas pu être préparé',
			'appareils.emetteur.erreur.generiquePhrase' => 'La demande n\'a pas abouti. Réessayez dans un instant.',
			'appareils.regenerer' => 'Générer un nouveau code',
			'appareils.revoquer' => 'Retirer',
			'appareils.revoquerConfirmation' => 'Retirer cet appareil ? Il ne pourra plus se connecter tant que le tuteur ne l\'aura pas reconnecté avec un nouveau code.',
			'enfant.titre' => 'Ajouter un profil élève',
			'enfant.aucun' => 'Aucun profil élève dans le foyer',
			'enfant.aucunDetail' => 'Ajoutez d\'abord un profil élève depuis le Foyer.',
			'reglagesEnfant.titre' => 'Réglages par profil élève',
			'reglagesEnfant.intro' => 'La photo, la caméra et l\'interface de chaque élève se règlent dans sa fiche, depuis le Foyer. Les demandes à l\'administration restent ici.',
			'reglagesEnfant.renvoi' => 'Photo, caméra et interface',
			'reglagesEnfant.renvoiLegende' => ({required Object prenom}) => 'Dans la fiche de ${prenom}',
			'foyer.titre' => 'Foyer',
			'foyer.ajouterProfil' => 'Ajouter un profil élève',
			'foyer.sousTitre' => 'Les profils élèves de votre foyer',
			'foyer.membres' => 'Profils élèves',
			'foyer.vide.titre' => 'Aucun profil élève pour l\'instant',
			'foyer.vide.phrase' => 'Ajoutez un profil élève pour l\'inscrire dans une classe et relier son appareil.',
			'foyer.membre.sansClasse' => 'Pas encore de classe',
			'foyer.membre.classeEchec' => 'Classe non lue',
			'foyer.membre.accesSansEcheance' => 'Accès sans échéance',
			'foyer.membre.accesJusquau' => ({required Object date}) => 'Accès jusqu\'au ${date}',
			'foyer.membre.accesExpire' => ({required Object date}) => 'Accès expiré depuis le ${date}',
			'foyer.membre.date' => ({required Object jour, required Object mois, required Object annee}) => '${jour} ${mois} ${annee}',
			'foyer.classesIndisponibles' => 'La classe de chaque élève ne s\'affiche pas encore sur cette page.',
			'foyer.classesEchec' => 'La classe de certains élèves n\'a pas pu être lue.',
			'foyer.relireClasses' => 'Relire les classes',
			'foyer.inscriptionIllisible' => 'L\'inscription en cours de chaque élève ne s\'affiche pas encore sur cette page.',
			'foyer.appareilsPartages' => 'Appareils partagés',
			'foyer.appareilsFoyer' => 'Appareils du foyer',
			'foyer.appareilsFoyerLegende' => 'Connecter un appareil, voir ceux qui sont reliés, en retirer un',
			'foyer.creerMonProfil' => 'Créer mon profil élève',
			'foyer.monProfil.titre' => 'Créer mon profil élève',
			'foyer.monProfil.indisponibleTitre' => 'Pas encore possible',
			'foyer.monProfil.indisponiblePhrase' => 'Suivre vous-même les cours avec votre propre profil élève sera proposé prochainement. Votre compte de tuteur reste tel qu\'il est.',
			'foyer.monProfil.retour' => 'Retour au foyer',
			'foyer.ajout.suivant' => 'Suivant',
			'foyer.ajout.creer' => 'Créer le profil',
			'foyer.ajout.porte.illisibleTitre' => 'Votre compte n\'a pas pu être lu',
			'foyer.ajout.porte.illisiblePhrase' => 'Nous ne savons pas encore quels profils vous pouvez ajouter. Réessayez dans un instant.',
			'foyer.ajout.pourQui.question' => 'Pour qui est ce profil élève ?',
			'foyer.ajout.pourQui.sousTitre' => 'Choisissez la personne qui suivra les cours.',
			'foyer.ajout.pourQui.requis' => 'Choisissez pour qui est ce profil pour continuer.',
			'foyer.ajout.pourQui.indisponible' => 'Indisponible',
			'foyer.ajout.pourQui.enfantTitre' => 'Un enfant ou un mineur',
			'foyer.ajout.pourQui.enfantDescription' => 'Un profil rattaché à votre foyer, que vous gérez pour lui.',
			'foyer.ajout.pourQui.enfantAttente' => 'Possible dès que votre accès est ouvert.',
			'foyer.ajout.pourQui.procheTitre' => 'Un proche adulte',
			'foyer.ajout.pourQui.procheDescription' => 'Pas encore possible : un adulte aura son propre profil et donnera lui-même son accord.',
			'foyer.ajout.pourQui.moiTitre' => 'Moi-même',
			'foyer.ajout.pourQui.moiDescription' => 'Pas encore possible : suivre vous-même les cours avec votre propre profil élève sera proposé prochainement.',
			'foyer.ajout.identite.question' => 'Qui est l\'élève ?',
			'foyer.ajout.identite.sousTitre' => 'Son prénom, son nom et son âge.',
			'foyer.ajout.identite.prenom' => 'Prénom',
			'foyer.ajout.identite.nom' => 'Nom',
			'foyer.ajout.identite.nomAide' => 'Le nom de famille n\'est jamais montré à l\'enseignant.',
			'foyer.ajout.identite.age' => 'Âge',
			'foyer.ajout.identite.ageSuffixe' => 'ans',
			'foyer.ajout.identite.ageAide' => 'L\'âge fixe l\'affichage et la caméra au départ. Vous pourrez changer les deux ensuite.',
			'foyer.ajout.erreurs.prenomRequis' => 'Indiquez le prénom de l\'élève.',
			'foyer.ajout.erreurs.nomRequis' => 'Indiquez le nom de l\'élève.',
			'foyer.ajout.erreurs.ageRequis' => 'Indiquez l\'âge, en chiffres.',
			'foyer.ajout.erreurs.ageHorsBornes' => ({required Object min, required Object max}) => 'Indiquez un âge entre ${min} et ${max} ans.',
			'foyer.ajout.refus.compteNonValide' => 'Votre accès doit être ouvert avant d\'ajouter un profil élève.',
			'foyer.ajout.refus.ageHorsBornes' => 'Cet âge n\'est pas accepté. Vérifiez-le puis réessayez.',
			'foyer.ajout.refus.refuse' => 'La création n\'a pas été acceptée. Vérifiez les informations puis réessayez.',
			'foyer.ajout.incertaine.titre' => 'Le profil a peut-être été créé',
			'foyer.ajout.incertaine.phrase' => 'La réponse ne nous est pas parvenue. Vérifiez le foyer avant de réessayer, pour ne pas créer le profil deux fois.',
			'foyer.ajout.incertaine.voirFoyer' => 'Voir le foyer',
			'foyer.ajout.incertaine.reessayer' => 'Réessayer quand même',
			'foyer.ajout.horsLigne' => 'Vous êtes hors ligne. Le profil pourra être créé quand la connexion reviendra.',
			'ficheEleve.titreRepli' => 'Profil élève',
			'ficheEleve.parametres' => 'Paramètres de l\'élève',
			'ficheEleve.appareilsGroupe' => 'Appareils',
			'ficheEleve.introuvable.titre' => 'Ce profil élève est introuvable',
			'ficheEleve.introuvable.phrase' => 'Il ne fait pas partie de votre foyer, ou le lien est incomplet.',
			'ficheEleve.introuvable.retour' => 'Retour au foyer',
			'ficheEleve.lignes.informations' => 'Informations',
			'ficheEleve.lignes.informationsLegende' => 'Prénom et photo',
			'ficheEleve.lignes.inscription' => 'Parcours et inscription',
			'ficheEleve.lignes.inscriptionLegende' => 'Questionnaire et classe',
			'ficheEleve.lignes.interface' => 'Interface',
			'ficheEleve.lignes.camera' => 'Caméra en cours',
			'ficheEleve.lignes.cameraAutorisee' => 'Autorisée',
			'ficheEleve.lignes.cameraNonAutorisee' => 'Non autorisée',
			'ficheEleve.lignes.acces' => 'Accès Rewayah',
			'ficheEleve.lignes.appareils' => ({required Object prenom}) => 'Appareils de ${prenom}',
			'ficheEleve.lignes.appareilsLegende' => 'Connecter un appareil, voir ceux qui sont reliés, en retirer un',
			'ficheEleve.informations.titre' => 'Informations de l\'élève',
			'ficheEleve.informations.identite' => 'Identité',
			'ficheEleve.informations.prenom' => 'Prénom',
			'ficheEleve.informations.identiteNote' => 'Le prénom ne se modifie pas encore depuis cette page.',
			'ficheEleve.informations.ageNote' => 'L\'âge et la date de naissance ne sont pas encore enregistrés sur le profil.',
			'ficheEleve.informations.photo' => 'Photo',
			'ficheEleve.informations.photoLegende' => ({required Object prenom}) => 'Une photo du visage de ${prenom}. Ce n\'est pas une pièce d\'identité.',
			'ficheEleve.informations.photoAucune' => 'Pas encore de photo',
			'ficheEleve.informations.photoPresente' => 'Photo enregistrée',
			'ficheEleve.informations.choisir' => 'Choisir une photo',
			'ficheEleve.informations.changer' => 'Changer la photo',
			'ficheEleve.informations.apercuTitre' => 'Aperçu',
			'ficheEleve.informations.apercuPhrase' => 'Vérifiez la photo avant de l\'envoyer.',
			'ficheEleve.informations.apercuIllisible' => 'L\'aperçu ne s\'affiche pas sur cet appareil. La photo peut quand même être envoyée.',
			'ficheEleve.informations.envoyer' => 'Envoyer cette photo',
			'ficheEleve.informations.autre' => 'Choisir une autre photo',
			'ficheEleve.informations.annuler' => 'Annuler',
			'ficheEleve.informations.etapeEnvoi' => 'Envoi de la photo, étape 1 sur 2',
			'ficheEleve.informations.etapeEnregistrement' => 'Enregistrement sur le profil, étape 2 sur 2',
			'ficheEleve.informations.succes' => 'La photo est enregistrée.',
			'ficheEleve.informations.tropLourde' => ({required Object taille}) => 'Cette photo dépasse ${taille} Mo. Choisissez une image plus légère.',
			'ficheEleve.informations.echecEnvoi' => 'La photo n\'a pas pu être envoyée. Rien n\'a changé sur le profil.',
			'ficheEleve.informations.echecEnregistrement' => 'La photo est envoyée, mais elle n\'a pas pu être enregistrée sur le profil.',
			'ficheEleve.informations.reprendre' => 'Réessayer',
			'ficheEleve.informations.selectionEchec' => 'La photo n\'a pas pu être ouverte. Vérifiez l\'accès aux photos de l\'appareil, puis réessayez.',
			'ficheEleve.informations.horsLigne' => 'Vous êtes hors ligne. La photo pourra être envoyée quand la connexion reviendra.',
			'ficheEleve.inscription.titre' => 'Parcours et inscription',
			'ficheEleve.inscription.intro' => ({required Object prenom}) => 'Où en est ${prenom} : questionnaire et classe.',
			'ficheEleve.inscription.questionnaire' => 'Questionnaire',
			'ficheEleve.inscription.classe' => 'Classe',
			'ficheEleve.inscription.lecture' => 'Lecture en cours',
			'ficheEleve.inscription.etatInconnu' => 'L\'état du questionnaire ne s\'affiche pas encore.',
			'ficheEleve.inscription.aRemplir' => 'À remplir',
			'ficheEleve.inscription.horaireAChoisir' => 'Rempli, horaire à choisir',
			'ficheEleve.inscription.horaireRetire' => 'Horaire retiré, à choisir de nouveau',
			'ficheEleve.inscription.echangeAPrevoir' => 'Préférence enregistrée, échange de niveau à prévoir',
			'ficheEleve.inscription.echangePrevu' => 'Échange de niveau prévu',
			'ficheEleve.inscription.classeEnConstitution' => 'Classe en cours de constitution',
			'ficheEleve.inscription.classeConfirmee' => 'Classe confirmée',
			'ficheEleve.inscription.classeAucune' => 'Pas encore de classe. Choisir une classe',
			'ficheEleve.inscription.classeIndisponible' => 'La classe ne s\'affiche pas encore ici. Choisir une classe',
			'ficheEleve.inscription.classeEchec' => 'La classe n\'a pas pu être lue.',
			'ficheEleve.inscription.relireClasse' => 'Relire la classe',
			'ficheEleve.interface.titre' => 'Interface',
			'ficheEleve.interface.intro' => ({required Object prenom}) => 'Comment Rewayah s\'affiche sur l\'appareil de ${prenom}.',
			'ficheEleve.interface.guidee' => 'Interface guidée',
			'ficheEleve.interface.guideeDescription' => 'Des écrans simplifiés, de grands boutons, une chose à la fois.',
			'ficheEleve.interface.standard' => 'Interface standard',
			'ficheEleve.interface.standardDescription' => 'L\'affichage habituel de Rewayah.',
			'ficheEleve.interface.politique' => 'Vous choisissez ce réglage. Au départ, il a été fixé selon l\'âge indiqué à la création du profil.',
			'ficheEleve.interface.application' => ({required Object prenom}) => 'Le changement s\'applique à la prochaine ouverture de Rewayah sur l\'appareil de ${prenom}.',
			'ficheEleve.interface.demandeEleve' => 'La demande de changement par l\'élève lui-même n\'est pas encore proposée.',
			'ficheEleve.interface.enCours' => 'Enregistrement en cours',
			'ficheEleve.interface.echec' => 'Le changement n\'a pas été enregistré. Réessayez.',
			'ficheEleve.interface.horsLigne' => 'Vous êtes hors ligne. L\'interface pourra être changée quand la connexion reviendra.',
			'ficheEleve.camera.titre' => 'Caméra en cours',
			'ficheEleve.camera.ligne' => 'Caméra pendant les séances',
			'ficheEleve.camera.autorisee' => ({required Object prenom}) => '${prenom} peut allumer sa caméra pendant les séances.',
			'ficheEleve.camera.interdite' => ({required Object prenom}) => 'Le bouton caméra n\'apparaîtra pas pour ${prenom} pendant les séances.',
			'ficheEleve.camera.application' => ({required Object prenom}) => 'Le changement compte à la prochaine entrée de ${prenom} en séance.',
			'ficheEleve.camera.distincte' => 'Ce réglage ne change pas l\'autorisation caméra de l\'appareil, celle que le téléphone demande pour lire un QR code.',
			'ficheEleve.camera.echec' => 'Le changement n\'a pas été enregistré. Réessayez.',
			'ficheEleve.camera.horsLigne' => 'Vous êtes hors ligne. La caméra pourra être réglée quand la connexion reviendra.',
			'ficheEleve.acces.titre' => 'Accès Rewayah',
			'ficheEleve.acces.ligne' => ({required Object prenom}) => 'Accès de ${prenom}',
			'ficheEleve.acces.pastilleSansEcheance' => 'Sans échéance',
			'ficheEleve.acces.pastilleEnCours' => 'En cours',
			'ficheEleve.acces.pastilleExpire' => 'Expiré',
			'ficheEleve.acces.sansEcheance' => 'Aucune date de fin n\'est enregistrée.',
			'ficheEleve.acces.jusquau' => ({required Object date}) => 'Jusqu\'au ${date}',
			'ficheEleve.acces.expireDepuis' => ({required Object date}) => 'Expiré depuis le ${date}',
			'ficheEleve.acces.expirePhrase' => ({required Object prenom}) => 'Depuis cette date, ${prenom} ne peut plus entrer dans Rewayah.',
			'ficheEleve.acces.detailIndisponible' => 'Le début de l\'accès et son motif ne s\'affichent pas encore.',
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
			'eleveConnexion.choisirProfil' => 'Qui es-tu ?',
			'eleveConnexion.profils.phrase' => 'Touche ton prénom pour continuer.',
			'eleveConnexion.profils.ajouter' => 'Ajouter un profil sur cet appareil',
			'eleveConnexion.profils.ajouterLegende' => 'Avec le code affiché par le tuteur',
			'eleveConnexion.profils.profilLibelle' => ({required Object prenom}) => 'Continuer en tant que ${prenom}',
			'eleveConnexion.profils.videTitre' => 'Aucun profil sur cet appareil',
			'eleveConnexion.profils.vide' => 'Pour utiliser cet appareil, le tuteur doit afficher un nouveau code sur son propre appareil.',
			'eleveConnexion.profils.videAction' => 'Saisir un code',
			'eleveConnexion.profils.retire' => ({required Object prenom}) => 'Cet appareil a été retiré pour ${prenom}. Demande au tuteur de le reconnecter avec un nouveau code.',
			'eleveConnexion.profils.jetonAbsent' => ({required Object prenom}) => 'Cet appareil ne retrouve plus la connexion de ${prenom}. Demande au tuteur d\'afficher un nouveau code, puis saisis-le ici.',
			'eleveConnexion.pin.bonjour' => ({required Object prenom}) => 'Bonjour ${prenom}',
			'eleveConnexion.pin.creer' => 'Choisis ton code personnel',
			'eleveConnexion.pin.creerPhrase' => 'Quatre chiffres, rien que pour toi. Il reste sur cet appareil.',
			'eleveConnexion.pin.confirmer' => 'Entre-le encore une fois',
			'eleveConnexion.pin.different' => 'Les deux codes ne sont pas les mêmes. Choisis ton code à nouveau.',
			'eleveConnexion.pin.ouverture' => 'Connexion en cours',
			'eleveConnexion.pin.horsLigne' => 'Pas de connexion internet. Ton code est bon : réessaie quand internet revient.',
			'eleveConnexion.pin.tropDEssais' => 'Trop d\'essais. Patiente un instant avant de réessayer.',
			'eleveConnexion.pin.echec' => 'La connexion n\'a pas abouti. Réessaie dans un instant.',
			'eleveConnexion.pin.changerProfil' => 'Changer de profil',
			'eleveConnexion.pin.oublie' => 'Code oublié ?',
			'eleveConnexion.pin.oubliePhrase' => 'Demande au tuteur d\'afficher un nouveau code sur son appareil, puis saisis-le ici. Tu choisiras alors un nouveau code personnel.',
			'eleveConnexion.pin.oublieAction' => 'Saisir un nouveau code',
			'eleveConnexion.saisie.titre' => 'Connecter cet appareil',
			'eleveConnexion.saisie.phrase' => 'Saisissez le code de six caractères affiché sous le QR code, sur l\'appareil du tuteur.',
			'eleveConnexion.saisie.champ' => 'Code',
			'eleveConnexion.saisie.aide' => 'Chiffres de 2 à 9 et lettres, sans I ni O.',
			'eleveConnexion.saisie.valider' => 'Connecter l\'appareil',
			'eleveConnexion.saisie.scanner' => 'Scanner le QR code',
			'eleveConnexion.saisie.horsLigne' => 'Pas de connexion internet. Le code pourra être vérifié au retour du réseau.',
			'eleveConnexion.lecteur.titre' => 'Scanner le QR code',
			'eleveConnexion.lecteur.consigne' => 'Visez le QR code affiché sur l\'appareil du tuteur.',
			'eleveConnexion.lecteur.demarrage' => 'Autorisez la caméra si l\'appareil le demande.',
			'eleveConnexion.lecteur.libelleApercu' => 'Vue de la caméra',
			'eleveConnexion.lecteur.contenuInvalide' => 'Ce QR code n\'est pas un code de connexion Rewayah. Visez celui affiché par le tuteur.',
			'eleveConnexion.lecteur.saisir' => 'Saisir le code',
			'eleveConnexion.lecteur.scannerANouveau' => 'Scanner à nouveau',
			'eleveConnexion.lecteur.verificationTitre' => 'Vérification du code',
			'eleveConnexion.lecteur.verificationPhrase' => 'La caméra est arrêtée pendant la vérification.',
			'eleveConnexion.lecteur.refuseeTitre' => 'Caméra non autorisée',
			'eleveConnexion.lecteur.refuseePhrase' => 'Pour lire le QR code, autorisez la caméra. Vous pouvez aussi saisir le code affiché sous le QR.',
			'eleveConnexion.lecteur.refuseeAction' => 'Autoriser la caméra',
			'eleveConnexion.lecteur.refuseeDurablementTitre' => 'Caméra bloquée',
			'eleveConnexion.lecteur.refuseeDurablementPhrase' => 'La caméra reste refusée pour Rewayah. Autorisez-la dans les réglages de l\'appareil ou du navigateur, ou saisissez le code.',
			'eleveConnexion.lecteur.occupeeTitre' => 'Caméra occupée',
			'eleveConnexion.lecteur.occupeePhrase' => 'Une autre application utilise la caméra. Fermez-la, puis réessayez, ou saisissez le code.',
			'eleveConnexion.lecteur.absenteTitre' => 'Aucune caméra',
			'eleveConnexion.lecteur.absentePhrase' => 'Cet appareil n\'a pas de caméra disponible. Saisissez le code affiché sous le QR.',
			'eleveConnexion.lecteur.nonSupporteeTitre' => 'Lecture impossible ici',
			'eleveConnexion.lecteur.nonSupporteePhrase' => 'Cet appareil ou ce navigateur ne sait pas lire un QR code. Saisissez le code affiché sous le QR.',
			'eleveConnexion.lecteur.erreurTitre' => 'La caméra n\'a pas démarré',
			'eleveConnexion.lecteur.erreurPhrase' => 'Réessayez, ou saisissez le code affiché sous le QR.',
			'eleveConnexion.refus.format' => 'Un code compte six caractères : chiffres de 2 à 9 et lettres, sans I ni O.',
			'eleveConnexion.refus.inconnuTitre' => 'Code non reconnu',
			'eleveConnexion.refus.inconnu' => 'Ce code n\'existe pas, ou un code plus récent l\'a remplacé. Vérifiez-le, ou affichez un nouveau code sur l\'appareil du tuteur.',
			'eleveConnexion.refus.expireTitre' => 'Code expiré',
			'eleveConnexion.refus.expire' => 'Ce code n\'est plus valable. Affichez un nouveau code sur l\'appareil du tuteur.',
			'eleveConnexion.refus.dejaUtiliseTitre' => 'Code déjà utilisé',
			'eleveConnexion.refus.dejaUtilise' => 'Ce code a déjà servi à connecter un appareil. Affichez un nouveau code sur l\'appareil du tuteur.',
			'eleveConnexion.refus.revoqueTitre' => 'Appareil retiré',
			'eleveConnexion.refus.revoque' => 'Le tuteur a retiré cet appareil. Demandez-lui d\'afficher un nouveau code.',
			'eleveConnexion.refus.plafondTitre' => 'Limite d\'appareils atteinte',
			'eleveConnexion.refus.plafond' => 'Ce profil élève a atteint le nombre d\'appareils autorisés. Le tuteur peut en retirer un dans Foyer, puis afficher un nouveau code.',
			'eleveConnexion.refus.tropDEssaisTitre' => 'Trop d\'essais',
			'eleveConnexion.refus.tropDEssais' => 'Patientez un instant avant de réessayer.',
			'eleveConnexion.refus.horsLigneTitre' => 'Pas de connexion',
			'eleveConnexion.refus.horsLigne' => 'Le code n\'a pas pu être vérifié. Vérifiez la connexion internet, puis réessayez.',
			'eleveConnexion.refus.nonEnregistreTitre' => 'Connexion non enregistrée',
			'eleveConnexion.refus.nonEnregistre' => 'Cet appareil n\'a pas pu garder la connexion. Le code a sans doute déjà servi : affichez un nouveau code sur l\'appareil du tuteur, puis recommencez.',
			'eleveConnexion.refus.generiqueTitre' => 'Connexion non aboutie',
			'eleveConnexion.refus.generique' => 'La vérification du code n\'a pas abouti. Réessayez dans un instant.',
			'dossiers.titre' => 'Dossiers à valider',
			'dossiers.sousTitre' => 'Examinez les dossiers prêts pour une décision.',
			'dossiers.aucun' => 'Aucun dossier n\'attend de validation.',
			'dossiers.aucunDetail' => 'Les nouveaux dossiers apparaîtront ici lorsqu\'ils seront prêts.',
			'dossiers.file.chargement' => 'Chargement des dossiers…',
			'dossiers.file.erreur' => 'Impossible de charger les dossiers.',
			'dossiers.file.horsLigne' => 'Vous êtes hors ligne. Les dossiers ne peuvent pas être actualisés.',
			'dossiers.file.accesRefuse' => 'Vous n\'avez pas accès aux dossiers à valider.',
			'dossiers.file.actualisation' => 'Actualisation des dossiers…',
			'dossiers.file.chargementProlonge' => 'Le chargement prend plus de temps que prévu.',
			'dossiers.file.suivantsErreur' => 'Impossible de charger les dossiers suivants.',
			'dossiers.file.indisponible' => 'La consultation des dossiers est indisponible pour le moment.',
			'dossiers.file.selectionRetiree' => 'Ce dossier n’est plus disponible dans la file.',
			'dossiers.file.actualiser' => 'Actualiser les dossiers',
			'dossiers.file.aucuneSelection' => 'Sélectionnez un dossier à examiner.',
			'dossiers.file.suivants' => 'Charger les dossiers suivants',
			'dossiers.file.ouvrirDe' => ({required Object nom}) => 'Ouvrir le dossier de ${nom}',
			'dossiers.file.ouvrirElide' => ({required Object nom}) => 'Ouvrir le dossier d\'${nom}',
			'dossiers.file.enVerification' => 'En cours de vérification',
			'dossiers.file.sansNom' => 'Dossier sans nom disponible',
			'dossiers.file.legende' => ({required Object type, required Object date}) => '${type} · ${date}',
			'dossiers.file.dateHeure' => ({required Object date, required Object heure, required Object zone}) => '${date} à ${heure} (${zone})',
			'dossiers.file.dateChiffres' => ({required Object jour, required Object mois, required Object annee}) => '${jour}/${mois}/${annee}',
			'dossiers.file.heureChiffres' => ({required Object heures, required Object minutes}) => '${heures}:${minutes}',
			'dossiers.file.zoneUtc' => 'UTC',
			'dossiers.file.suivantAnnonce' => ({required Object nom}) => 'Dossier suivant : ${nom}',
			'dossiers.detail.titreDe' => ({required Object nom}) => 'Dossier de ${nom}',
			'dossiers.detail.titreElide' => ({required Object nom}) => 'Dossier d\'${nom}',
			'dossiers.visionneuse.chargement' => 'Chargement de la pièce…',
			'dossiers.visionneuse.erreur' => 'La pièce ne peut pas être affichée.',
			'dossiers.visionneuse.expire' => 'L\'accès à cette pièce a expiré.',
			'dossiers.visionneuse.recharger' => 'Recharger la pièce',
			'dossiers.visionneuse.formatNonPrisEnCharge' => 'Ce format de pièce ne peut pas être affiché.',
			'dossiers.visionneuse.accesRetire' => 'Vous n’avez plus accès à cette pièce.',
			'dossiers.visionneuse.horsLigne' => 'Vous êtes hors ligne. La pièce ne peut pas être chargée.',
			'dossiers.visionneuse.aucune' => 'Aucune pièce n’est disponible.',
			'dossiers.visionneuse.fermerPiece' => 'Fermer la pièce',
			'dossiers.visionneuse.agrandir' => 'Agrandir',
			'dossiers.visionneuse.reduire' => 'Réduire',
			'dossiers.visionneuse.ajuster' => 'Ajuster à l’écran',
			'dossiers.visionneuse.infoBulle' => ({required Object action, required Object touche}) => '${action} (touche ${touche})',
			'dossiers.visionneuse.documentFictif' => 'Document fictif',
			'dossiers.revue.identite' => 'Identité et dossier',
			'dossiers.revue.pieceNonTransmise' => 'La pièce requise n’a pas été transmise.',
			'dossiers.revue.piece' => 'Pièce d\'identité',
			'dossiers.revue.voirPiece' => 'Voir la pièce',
			'dossiers.revue.accords' => 'Accords et éléments soumis',
			'dossiers.revue.nom' => 'Nom',
			'dossiers.revue.prenom' => 'Prénom',
			'dossiers.revue.typeDossier' => 'Type de dossier',
			'dossiers.revue.dateDepot' => 'Date de dépôt',
			'dossiers.revue.etatDossier' => 'État du dossier',
			'dossiers.revue.dateIndisponible' => 'Date de dépôt indisponible',
			_ => null,
		} ?? switch (path) {
			'dossiers.revue.pasPret' => 'Ce dossier n\'est pas encore prêt à être validé.',
			'dossiers.revue.erreurChargement' => 'Impossible de charger ce dossier.',
			'dossiers.revue.pieceIndisponible' => 'La consultation de la pièce est indisponible pour le moment.',
			'dossiers.revue.etats.chargement' => 'Chargement du dossier…',
			'dossiers.revue.etats.horsLigne' => 'Vous êtes hors ligne. Aucune décision ne peut être envoyée.',
			'dossiers.revue.etats.accesPerdu' => 'Vous n’avez plus accès à ce dossier.',
			'dossiers.revue.etats.retourDossiers' => 'Retour aux dossiers',
			'dossiers.revue.etats.verificationsIncompletes' => 'Terminez les vérifications requises.',
			'dossiers.revue.etats.accordManquant' => 'Un accord requis manque à ce dossier.',
			'dossiers.revue.etats.decisionIndisponible' => 'La décision est indisponible pour le moment.',
			'dossiers.revue.etats.modifie' => 'Ce dossier a changé depuis son ouverture.',
			'dossiers.revue.etats.actualiserDossier' => 'Actualiser le dossier',
			'dossiers.revue.etats.refusNonAutorise' => 'Ce dossier ne peut pas être refusé dans son état actuel.',
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
			'dossiers.refuser' => 'Refuser le dossier',
			'dossiers.profilACompleter.titre' => 'Profil à compléter',
			'dossiers.profilACompleter.texte' => 'Votre profil doit être complété avant de consulter les dossiers autorisés par cette règle.',
			'dossiers.refus.titre' => 'Refuser le dossier',
			'dossiers.refus.nomType' => ({required Object nom, required Object type}) => '${nom} · ${type}',
			'dossiers.refus.corps' => 'Indiquez le motif qui sera affiché à la personne concernée.',
			'dossiers.refus.champ' => 'Motif du refus',
			'dossiers.refus.aide' => 'Expliquez ce qui doit être corrigé, sans donnée interne ni commentaire personnel.',
			'dossiers.refus.erreurVide' => 'Indiquez le motif du refus.',
			'dossiers.refus.tropLong' => 'Le motif dépasse la longueur autorisée.',
			'dossiers.refus.envoi' => 'Refus en cours…',
			'dossiers.refus.erreur' => 'Le dossier n\'a pas pu être refusé.',
			'dossiers.refus.horsLigne' => 'Vous êtes hors ligne. Le refus n’a pas été envoyé.',
			'dossiers.refus.inconnu' => 'Le résultat du refus n’est pas encore confirmé.',
			'dossiers.refus.interdit' => 'Vous ne pouvez plus refuser ce dossier.',
			'dossiers.refus.indisponible' => 'Le refus est indisponible pour le moment.',
			'dossiers.refus.succes' => 'Dossier refusé.',
			'dossiers.refus.abandonQuestion' => 'Abandonner le motif saisi ?',
			'dossiers.refus.continuerSaisie' => 'Continuer la saisie',
			'dossiers.refus.abandonner' => 'Abandonner',
			'dossiers.validation.titre' => 'Valider ce dossier ?',
			'dossiers.validation.corpsActivation' => ({required Object nom}) => 'Le dossier de ${nom} sera validé. Son compte pourra accéder à son espace.',
			'dossiers.validation.corpsDocumentaire' => ({required Object nom}) => 'Le dossier de ${nom} sera validé. Les autres conditions d’accès resteront applicables.',
			'dossiers.validation.indisponible' => 'La validation est indisponible pour le moment.',
			'dossiers.validation.envoi' => 'Validation en cours…',
			'dossiers.validation.erreur' => 'Le dossier n\'a pas pu être validé.',
			'dossiers.validation.horsLigne' => 'Vous êtes hors ligne. La validation n’a pas été envoyée.',
			'dossiers.validation.inconnu' => 'Le résultat de la validation n’est pas encore confirmé.',
			'dossiers.validation.plusPret' => 'Ce dossier n’est plus prêt à être validé.',
			'dossiers.validation.interdit' => 'Vous ne pouvez plus valider ce dossier.',
			'dossiers.validation.succes' => 'Dossier validé.',
			'dossiers.decision.verifierResultat' => 'Vérifier le résultat',
			'dossiers.decision.dejaTraite' => 'Ce dossier a déjà été traité.',
			'dossiers.decision.conflit' => 'Ce dossier a été traité par un autre membre de l\'équipe.',
			'dossiers.decision.nomComplet' => ({required Object prenom, required Object nom}) => '${prenom} ${nom}',
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
			'admin.politiqueRevueKyc.titre' => 'Politique de genre pour la revue KYC',
			'admin.politiqueRevueKyc.libelle' => 'Limiter la revue KYC selon le genre',
			'admin.politiqueRevueKyc.aide' => 'Lorsque cette règle est désactivée, tout membre autorisé à revoir les dossiers peut traiter les dossiers de son périmètre, quel que soit son genre.',
			'admin.politiqueRevueKyc.echecEnregistrement' => _root.admin.groupes.observationErreur,
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
			'admin.programmes.enregistrerVersion' => 'Enregistrer la version',
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
			_ => null,
		} ?? switch (path) {
			'admin.journal.videFiltre' => 'Aucun événement ne correspond',
			'admin.journal.videFiltreDetail' => 'Élargissez la période, ou relâchez un filtre.',
			'admin.journal.effacerFiltres' => 'Effacer les filtres',
			'admin.journal.erreur' => 'Le journal n\'a pas pu être lu. Réessayez dans un instant.',
			'admin.journal.erreurSuite' => 'Les entrées plus anciennes n\'ont pas pu être lues.',
			'admin.journal.chargerSuite' => 'Charger les entrées plus anciennes',
			'admin.journal.fin' => 'Vous êtes remonté jusqu\'à la première entrée du journal.',
			'admin.journal.evenements.observationEntree' => 'Visite d\'observation commencée',
			'admin.journal.evenements.observationSortie' => 'Visite d\'observation terminée',
			'admin.journal.evenements.observationPolitiqueGroupeModifiee' => 'Règles d\'observation de la classe modifiées',
			'admin.observations.titre' => 'Observations',
			'admin.observations.titrePage' => 'Historique des observations',
			'admin.observations.sousTitre' => 'Administration',
			'admin.observations.recherche' => 'Rechercher un tuteur ou un élève',
			'admin.observations.rechercheCourte' => 'Saisissez au moins deux lettres.',
			'admin.observations.rechercheAucune' => 'Aucun tuteur ni élève ne porte ce nom.',
			'admin.observations.rechercheErreur' => 'La recherche n\'a pas abouti. Réessayez.',
			'admin.observations.roleTuteur' => 'Tuteur',
			'admin.observations.roleEleve' => 'Élève',
			'admin.observations.filtreTuteur' => ({required Object nom}) => 'Tuteur : ${nom}',
			'admin.observations.filtreEleve' => ({required Object nom}) => 'Élève : ${nom}',
			'admin.observations.retirerFiltre' => ({required Object filtre}) => 'Retirer le filtre ${filtre}',
			'admin.observations.classe' => 'Classe',
			'admin.observations.toutesClasses' => 'Toutes les classes',
			'admin.observations.periode' => 'Période',
			'admin.observations.statut' => 'Statut',
			'admin.observations.tousStatuts' => 'Tous les statuts',
			'admin.observations.colonneDate' => 'Date',
			'admin.observations.colonneTuteur' => 'Tuteur',
			'admin.observations.colonneEleve' => 'Élève',
			'admin.observations.colonneClasse' => 'Classe',
			'admin.observations.colonneEntree' => 'Entrée',
			'admin.observations.colonneSortie' => 'Sortie',
			'admin.observations.colonneDuree' => 'Durée',
			'admin.observations.colonneStatut' => 'Statut',
			'admin.observations.terminee' => 'Terminée',
			'admin.observations.ouverte' => 'Sortie non enregistrée',
			'admin.observations.sortieAbsente' => 'Non enregistrée',
			'admin.observations.dureeNonConfirmee' => 'Non confirmée',
			'admin.observations.nomInconnu' => 'Nom non disponible',
			'admin.observations.classeInconnue' => 'Classe non disponible',
			'admin.observations.plage' => ({required Object entree, required Object sortie}) => '${entree} - ${sortie}',
			'admin.observations.ligne' => ({required Object rang, required Object date, required Object tuteur, required Object eleve, required Object classe, required Object entree, required Object sortie, required Object duree, required Object statut}) => 'Visite ${rang} du ${date}, ${tuteur} pour ${eleve}, ${classe}, entrée ${entree}, sortie ${sortie}, durée ${duree}, ${statut}',
			'admin.observations.fuseau' => ({required Object decalage}) => 'Heures affichées à l\'heure de cet appareil (UTC${decalage}).',
			'admin.observations.indisponibleTitre' => 'Historique des observations indisponible',
			'admin.observations.indisponiblePhrase' => 'La lecture des visites d\'observation n\'est pas encore ouverte dans l\'application.',
			'admin.observations.videTitre' => 'Aucune visite enregistrée',
			'admin.observations.videPhrase' => 'Les visites d\'observation des tuteurs s\'afficheront ici.',
			'admin.observations.videFiltreTitre' => 'Aucune visite ne correspond',
			'admin.observations.videFiltrePhrase' => 'Élargissez la période ou retirez un filtre.',
			'admin.observations.effacerFiltres' => 'Effacer les filtres',
			'admin.observations.chargerSuite' => 'Charger les visites plus anciennes',
			'admin.observations.erreurSuite' => 'Les visites plus anciennes n\'ont pas pu être lues.',
			'admin.observations.fin' => 'Toutes les visites sont affichées.',
			'admin.comptes.titre' => 'Comptes',
			'admin.comptes.intro' => 'Toutes les personnes inscrites, celles qui attendent une décision en premier. Un enseignant sans pièce d\'identité déposée reste visible ici : c\'est le seul endroit qui le montre.',
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
			'admin.comptes.pieceSansObjet' => 'Sans objet',
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
			'parcours.pourPrenom' => ({required Object prenom}) => 'Pour ${prenom}',
			'parcours.retourAccueil' => 'Retour à l\'accueil',
			'parcours.retourFoyer' => 'Retour au Foyer',
			'parcours.reessayer' => 'Réessayer',
			'parcours.indisponibleTitre' => 'Le questionnaire n\'est pas encore disponible',
			'parcours.indisponibleDetail' => 'Cette étape n\'est pas encore ouverte par l\'académie. Vous n\'avez rien à faire pour l\'instant : rien n\'est perdu, et vous pourrez la remplir dès qu\'elle sera ouverte.',
			'parcours.horsLigneTitre' => 'Pas de connexion',
			'parcours.horsLigneDetail' => 'Vérifiez votre connexion, puis réessayez. Vos réponses sont gardées.',
			'parcours.erreurChargement' => 'Le questionnaire n\'a pas pu s\'afficher',
			'parcours.erreurChargementDetail' => 'Une erreur est survenue de notre côté. Réessayez dans un instant ; vos réponses sont gardées.',
			'parcours.introuvableTitre' => 'Ce profil élève est introuvable',
			'parcours.introuvableDetail' => 'Il a peut-être été retiré du foyer. Revenez au Foyer pour choisir un profil élève.',
			'parcours.finTitre' => ({required Object prenom}) => 'Préférence enregistrée pour ${prenom}',
			'parcours.finDetail' => 'Cet horaire est noté comme votre préférence. Il ne réserve pas encore de place.',
			'parcours.finAjouterDetail' => 'Une autre personne du foyer souhaite apprendre ?',
			'parcours.finAjouterProfil' => 'Ajouter un profil élève',
			'parcours.ageQuestion' => ({required Object prenom}) => 'Quel âge a ${prenom} ?',
			'parcours.ageRaison' => 'L\'âge décide de la durée des séances et du nombre d\'élèves par classe. Nous ne demandons pas de date de naissance : une tranche suffit.',
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
			'parcours.offresRaison' => 'Ces horaires sont affichés à votre heure locale. Choisir un horaire enregistre votre préférence : cela ne réserve pas de place et ne constitue pas encore une classe.',
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
			'parcours.refusEffet' => 'Nous enregistrons que la demande existe. Cela ne crée pas de classe, ne cherche pas d\'enseignant et ne promet aucun horaire futur.',
			'parcours.refusEnregistre' => 'C\'est noté. Nous vous préviendrons si un horaire correspondant ouvre.',
			'parcours.etatAPersonnaliser' => 'Parcours à personnaliser',
			'parcours.etatAPersonnaliserDetail' => ({required Object prenom}) => 'Quelques questions, et nous ne vous montrerons que ce qui convient à ${prenom}.',
			'parcours.etatHoraireAChoisir' => 'Horaire à choisir',
			'parcours.etatHoraireAChoisirDetail' => ({required Object prenom}) => 'Les horaires ouverts pour ${prenom} vous attendent.',
			'parcours.etatOffreIndisponible' => 'Cet horaire n\'est plus proposé',
			'parcours.etatOffreIndisponibleDetail' => ({required Object prenom}) => 'L\'horaire retenu pour ${prenom} a été retiré avant qu\'une classe soit constituée. Choisissez-en un autre : rien n\'est perdu.',
			'parcours.etatDiagnosticRequis' => 'Préférence enregistrée',
			'parcours.etatDiagnosticRequisDetail' => ({required Object prenom}) => 'Il reste un échange avec un enseignant pour situer le niveau de ${prenom}. L\'académie vous proposera un rendez-vous.',
			'parcours.etatDiagnosticEnAttente' => 'Rendez-vous prévu',
			'parcours.etatDiagnosticEnAttenteDetail' => ({required Object prenom}) => 'Un échange est prévu pour situer le niveau de ${prenom}.',
			'parcours.etatClasseEnFormation' => 'Classe en cours de constitution',
			'parcours.etatClasseEnFormationDetail' => ({required Object minimum}) => 'Une classe démarre à partir de ${minimum} élèves. Nous vous préviendrons dès qu\'elle est confirmée.',
			'parcours.etatClasseEnFormationDetailSansMinimum' => 'Une classe démarre à partir d\'un certain nombre d\'élèves. Nous vous préviendrons dès qu\'elle est confirmée.',
			'parcours.etatClasseConfirmee' => 'Classe confirmée',
			'parcours.etatClasseConfirmeeDetail' => ({required Object prenom}) => 'La classe de ${prenom} est constituée. Vous retrouverez ses séances dans son espace.',
			'parcours.fuseauChange' => 'Votre lieu a changé depuis ce choix',
			'parcours.fuseauChangeDetail' => 'L\'horaire est le même pour l\'académie, mais il ne tombe plus à la même heure chez vous. Vérifiez qu\'il vous convient toujours.',
			'parcours.voirHoraires' => 'Voir les horaires',
			'parcours.changerHoraire' => 'Changer d\'horaire',
			'parcours.renoncerMotif' => 'La famille a changé d\'horaire depuis le parcours',
			'avatar.sansPhoto' => 'Pas encore de photo',
			'nav.eleve.accueil' => 'Accueil',
			'nav.eleve.maClasse' => 'Ma classe',
			'nav.eleve.coran' => 'Coran',
			'nav.eleve.monEspace' => 'Mon espace',
			'nav.eleve.suivi' => 'Suivi',
			'nav.eleve.compte' => 'Compte',
			'nav.tuteur.accueil' => 'Accueil',
			'nav.tuteur.foyer' => 'Foyer',
			'nav.tuteur.disponibilites' => 'Disponibilités',
			'nav.tuteur.reglages' => 'Réglages',
			'nav.tuteur.suivi' => 'Suivi',
			'nav.tuteur.historique' => 'Historique',
			'nav.tuteur.compte' => 'Compte',
			'nav.enseignant.journee' => 'Aujourd\'hui',
			'nav.enseignant.classes' => 'Classes',
			'nav.enseignant.creneaux' => 'Disponibilités',
			'nav.enseignant.profil' => 'Profil',
			'nav.controleur.planning' => 'Planning',
			'nav.controleur.controle' => 'Contrôle',
			'nav.controleur.historique' => 'Historique',
			'nav.controleur.echanges' => 'Échanges',
			'nav.controleur.compte' => 'Compte',
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
			'compte.profils' => 'Gérer mon foyer',
			'compte.profilsDetail' => 'Gérer les profils de vos enfants',
			'compte.appareils' => 'Foyer',
			'compte.appareilsDetail' => 'Les appareils et profils rattachés à votre foyer',
			'compte.confidentialite' => 'Confidentialité',
			'compte.confidentialiteDetail' => 'Bientôt disponible',
			'compte.espaces' => 'Espaces',
			'compte.espacesDetail' => 'Les espaces auxquels votre compte donne accès',
			'compte.espacesMissionEnCours' => 'Pour revenir à votre espace principal, quittez d\'abord la mission en cours.',
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
			'compte.themeContexte' => 'Choisissez l\'apparence de l\'application. Le changement est immédiat et reste sur cet appareil. Vous pouvez le modifier à tout moment.',
			'compte.themeSysteme' => 'Système',
			'compte.themeSystemeDetail' => 'Suit le réglage de votre appareil',
			'compte.themeClair' => 'Clair',
			'compte.themeClairDetail' => 'Fond clair, quel que soit le réglage de votre appareil',
			'compte.themeSombre' => 'Sombre',
			'compte.themeSombreDetail' => 'Fond sombre, quel que soit le réglage de votre appareil',
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
			'compte.tuteur.preferences' => 'Préférences',
			'compte.tuteur.dateLongue' => ({required Object jour, required Object mois, required Object annee}) => '${jour} ${mois} ${annee}',
			'compte.tuteur.identite.statutValide' => 'Compte validé',
			'compte.tuteur.identite.statutProvisoire' => 'Profil à compléter',
			'compte.tuteur.identite.nomInconnu' => 'Titulaire du compte',
			'compte.tuteur.identite.courrielAbsent' => 'Adresse de connexion non communiquée',
			'compte.tuteur.identite.connexionLien' => 'Connexion par lien reçu par courriel',
			'compte.tuteur.identite.connexionGoogle' => 'Connexion avec Google',
			'compte.tuteur.identite.connexionInconnue' => 'Méthode de connexion non précisée',
			'compte.tuteur.acces.titre' => 'Accès et paiements',
			'compte.tuteur.acces.resume' => 'Statut et échéance de chaque profil élève',
			'compte.tuteur.acces.pastilleActif' => 'Accès actif',
			'compte.tuteur.acces.pastilleExpire' => 'Accès terminé',
			'compte.tuteur.acces.ligne' => 'Accès des profils élèves',
			'compte.tuteur.acces.paiements' => 'Paiements et reçus',
			'compte.tuteur.securite.titre' => 'Connexion et sécurité',
			'compte.tuteur.securite.methode' => 'Méthode de connexion',
			'compte.tuteur.securite.methodeLien' => 'Lien par courriel',
			'compte.tuteur.securite.methodeGoogle' => 'Google',
			'compte.tuteur.informations.titre' => 'Informations personnelles',
			'compte.tuteur.informations.resume' => 'Nom, adresse de connexion, langue et fuseau',
			'compte.tuteur.informations.langueFuseau' => ({required Object ville}) => 'Français · ${ville}',
			'compte.tuteur.informations.consulter' => 'Consulter mes informations',
			'compte.tuteur.foyer.titre' => 'Mon foyer',
			'compte.tuteur.foyer.aucun' => 'Aucun profil élève pour le moment',
			'compte.tuteur.foyer.un' => '1 profil élève',
			'compte.tuteur.foyer.plusieurs' => ({required Object nombre}) => '${nombre} profils élèves',
			'compte.tuteur.foyer.legende' => 'Profils élèves et appareils du foyer',
			'compte.tuteur.foyer.creerMonProfil' => 'Créer mon profil élève',
			'compte.tuteur.aide.titre' => 'Aide et support',
			'compte.tuteur.aide.ligne' => 'Aide et contact',
			'compte.tuteur.aide.legal' => 'Informations légales',
			'compte.tuteur.deconnexion.question' => 'Se déconnecter de Rewayah ?',
			'compte.tuteur.deconnexion.consequence' => 'Vous devrez vous reconnecter pour revenir sur cet appareil. Vos autres appareils restent connectés.',
			'compte.tuteur.deconnexion.confirmer' => 'Me déconnecter',
			'compte.tuteur.deconnexion.echec' => 'La déconnexion n\'a pas abouti. Vérifiez votre connexion, puis réessayez.',
			'compte.tuteur.pageInformations.titre' => 'Informations personnelles',
			'compte.tuteur.pageInformations.prenom' => 'Prénom',
			'compte.tuteur.pageInformations.nom' => 'Nom',
			'compte.tuteur.pageInformations.courriel' => 'Adresse de connexion',
			'compte.tuteur.pageInformations.langue' => 'Langue de l\'interface',
			'compte.tuteur.pageInformations.fuseau' => 'Fuseau des séances',
			'compte.tuteur.pageInformations.fuseauIndisponible' => 'Non disponible pour le moment',
			'compte.tuteur.pageInformations.note' => 'Ces informations sont tenues par l\'académie. Elles ne se modifient pas encore depuis l\'application.',
			'compte.tuteur.pageSecurite.titre' => 'Connexion et sécurité',
			'compte.tuteur.pageSecurite.sousTitre' => 'Comment vous accédez à votre compte.',
			'compte.tuteur.pageSecurite.methode' => 'Méthode de connexion',
			'compte.tuteur.pageSecurite.adresse' => 'Adresse de connexion',
			'compte.tuteur.pageSecurite.appareils' => 'Les appareils connectés à votre compte ne sont pas encore listés dans l\'application.',
			'compte.tuteur.pageSecurite.deconnexion' => 'Pour fermer la session de cet appareil, utilisez « Se déconnecter » en bas de Mon compte.',
			'compte.tuteur.pageAcces.titre' => 'Accès des profils élèves',
			'compte.tuteur.pageAcces.sousTitre' => 'Le statut de l\'accès de chaque profil élève.',
			'compte.tuteur.pageAcces.sansEcheance' => 'Sans date de fin',
			'compte.tuteur.pageAcces.jusqua' => ({required Object date}) => 'Ouvert jusqu\'au ${date}',
			'compte.tuteur.pageAcces.expire' => ({required Object date}) => 'Terminé le ${date}',
			'compte.tuteur.pageAcces.pastilleActif' => 'Actif',
			'compte.tuteur.pageAcces.pastilleExpire' => 'Terminé',
			'compte.tuteur.pageAcces.aucunTitre' => 'Aucun profil élève',
			'compte.tuteur.pageAcces.aucunePhrase' => 'L\'accès de chaque profil élève s\'affichera ici.',
			'compte.tuteur.pageAcces.titulaire' => 'Votre compte de titulaire n\'a pas d\'échéance propre : l\'accès se règle profil par profil.',
			'compte.tuteur.pagePaiements.titre' => 'Paiements et reçus',
			'compte.tuteur.pagePaiements.indisponibleTitre' => 'Paiements pas encore consultables',
			'compte.tuteur.pagePaiements.indisponiblePhrase' => 'L\'historique des paiements, les reçus et les moyens de paiement ne sont pas encore disponibles dans l\'application. Aucun paiement ne vous est demandé ici.',
			'compte.tuteur.pagePaiements.aucunTitre' => 'Aucun paiement enregistré',
			'compte.tuteur.pagePaiements.aucunePhrase' => 'Les paiements enregistrés par l\'académie s\'afficheront ici.',
			'compte.tuteur.pagePaiements.paiementDu' => ({required Object date}) => 'Paiement du ${date}',
			'compte.tuteur.pagePaiements.justificatif' => 'Justificatif disponible',
			'compte.tuteur.pagePreferences.titre' => 'Préférences',
			'compte.tuteur.pagePreferences.sousTitre' => 'Personnalisez votre expérience sur cet appareil.',
			'compte.tuteur.pagePreferences.apparence' => 'Apparence',
			'compte.tuteur.pagePreferences.apparenceDetail' => 'Thème et confort visuel',
			'compte.tuteur.pagePreferences.langue' => 'Langue et région',
			'compte.tuteur.pagePreferences.notifications' => 'Notifications',
			'compte.tuteur.pagePreferences.notificationsDetail' => 'Pas encore disponibles dans l\'application',
			'compte.tuteur.pageApparence.titre' => 'Apparence',
			'compte.tuteur.pageApparence.sousTitre' => 'Appliqué sur cet appareil.',
			'compte.tuteur.pageApparence.theme' => 'Thème de l\'application',
			'compte.tuteur.pageApparence.themeDetail' => 'Personnalisez l\'apparence de Rewayah.',
			'compte.tuteur.pageApparence.confort' => 'Confort visuel',
			'compte.tuteur.pageApparence.animations' => 'Animations',
			'compte.tuteur.pageApparence.animationsDetail' => 'Réduites quand votre appareil le demande',
			'compte.tuteur.pageApparence.texte' => 'Taille du texte',
			'compte.tuteur.pageApparence.texteDetail' => 'Suit la taille du système',
			'compte.tuteur.pageAide.titre' => 'Aide et support',
			'compte.tuteur.pageAide.indisponibleTitre' => 'Aide pas encore disponible',
			'compte.tuteur.pageAide.indisponiblePhrase' => 'Les questions fréquentes et le contact de l\'académie ne sont pas encore ouverts dans l\'application.',
			'compte.tuteur.pageAide.canalCourriel' => 'Courriel de l\'académie',
			'compte.tuteur.pageAide.canalLien' => 'Page d\'aide de l\'académie',
			'compte.tuteur.pageAide.aucunCanal' => 'Aucun canal d\'aide n\'est publié pour le moment.',
			'compte.tuteur.pageLegal.titre' => 'Informations légales',
			'compte.tuteur.pageLegal.documents' => 'Documents acceptés',
			'compte.tuteur.pageLegal.conditionsTuteur' => 'Conditions du tuteur',
			'compte.tuteur.pageLegal.contratEnseignant' => 'Contrat enseignant',
			'compte.tuteur.pageLegal.accuseEnregistrement' => 'Accusé d\'enregistrement des cours',
			'compte.tuteur.pageLegal.acceptation' => ({required Object version, required Object date}) => 'Version ${version}, acceptée le ${date}',
			'compte.tuteur.pageLegal.aucunTitre' => 'Aucun document accepté',
			'compte.tuteur.pageLegal.aucun' => 'Aucun document accepté n\'est enregistré pour ce compte.',
			'compte.tuteur.pageLegal.lectureSeule' => 'Un document accepté ne se modifie pas.',
			'compte.tuteur.pageLegal.textes' => 'Conditions et confidentialité',
			'compte.tuteur.pageLegal.textesIndisponibles' => 'Les conditions générales, la politique de confidentialité et les mentions légales ne sont pas encore consultables dans l\'application.',
			'historique.titre' => 'Historique',
			'historique.detailSeance' => 'Détail de la séance',
			'historique.segments.seances' => 'Séances',
			'historique.segments.observations' => 'Observations',
			'historique.moisCourts.0' => 'janv.',
			'historique.moisCourts.1' => 'févr.',
			_ => null,
		} ?? switch (path) {
			'historique.moisCourts.2' => 'mars',
			'historique.moisCourts.3' => 'avr.',
			'historique.moisCourts.4' => 'mai',
			'historique.moisCourts.5' => 'juin',
			'historique.moisCourts.6' => 'juil.',
			'historique.moisCourts.7' => 'août',
			'historique.moisCourts.8' => 'sept.',
			'historique.moisCourts.9' => 'oct.',
			'historique.moisCourts.10' => 'nov.',
			'historique.moisCourts.11' => 'déc.',
			'historique.dateCourte' => ({required Object jour, required Object mois, required Object annee}) => '${jour} ${mois} ${annee}',
			'historique.dateLongue' => ({required Object jourSemaine, required Object jour, required Object mois, required Object annee}) => '${jourSemaine} ${jour} ${mois} ${annee}',
			'historique.plage' => ({required Object debut, required Object fin}) => '${debut} - ${fin}',
			'historique.duree.secondes' => ({required Object s}) => '${s} s',
			'historique.duree.minutes' => ({required Object m}) => '${m} min',
			'historique.duree.minutesSecondes' => ({required Object m, required Object s}) => '${m} min ${s} s',
			'historique.duree.heures' => ({required Object h}) => '${h} h',
			'historique.duree.heuresMinutes' => ({required Object h, required Object m}) => '${h} h ${m}',
			'historique.fuseauListe' => 'Heures affichées à l\'heure de cet appareil.',
			'historique.fuseauDetail' => ({required Object decalage}) => 'Heures affichées à l\'heure de cet appareil (UTC${decalage}).',
			'historique.classeInconnue' => 'Classe non disponible',
			'historique.selecteur.aucune' => 'Aucune séance',
			'historique.selecteur.une' => '1 séance',
			'historique.selecteur.plusieurs' => ({required Object n}) => '${n} séances',
			'historique.filtres.classe' => 'Classe',
			'historique.filtres.toutesClasses' => 'Toutes les classes',
			'historique.filtres.periode' => 'Période',
			'historique.filtres.toutePeriode' => 'Toute la période',
			'historique.filtres.septJours' => '7 derniers jours',
			'historique.filtres.trenteJours' => '30 derniers jours',
			'historique.filtres.troisMois' => '3 derniers mois',
			'historique.filtres.statut' => 'Statut',
			'historique.filtres.tousStatuts' => 'Tous les statuts',
			'historique.retour' => 'Retour à l\'historique',
			'historique.etat.presence' => 'Présence',
			'historique.etat.retard' => ({required Object minutes}) => 'Retard ${minutes} min',
			'historique.etat.retardSansDuree' => 'Retard',
			'historique.etat.verification' => 'En cours de vérification',
			'historique.etat.annule' => 'Cours annulé',
			'historique.etat.nonTenu' => 'Cours non tenu',
			'historique.presenceIllisible' => 'La présence n\'a pas pu être lue : les états restent inconnus pour le moment.',
			'historique.seances.videTitre' => 'Aucune séance passée',
			'historique.seances.videPhrase' => ({required Object prenom}) => 'Les séances passées de ${prenom} s\'afficheront ici.',
			'historique.seances.videPhraseFoyer' => 'Les séances passées des profils élèves s\'afficheront ici.',
			'historique.seances.filtreVideTitre' => 'Aucune séance ne correspond',
			'historique.seances.filtreVidePhrase' => 'Changez les filtres pour retrouver les autres séances.',
			'historique.seances.tronquee' => ({required Object nombre}) => 'Les ${nombre} séances les plus récentes sont affichées.',
			'historique.seances.ouvrir' => ({required Object date, required Object classe, required Object etat}) => 'Séance du ${date}, ${classe}, ${etat}',
			'historique.observations.indisponibleTitre' => 'Historique des observations indisponible',
			'historique.observations.indisponiblePhrase' => 'Les visites enregistrées ne peuvent pas encore être lues dans l\'application.',
			'historique.observations.videTitre' => 'Aucune observation',
			'historique.observations.videPhrase' => ({required Object prenom}) => 'Les visites que vous faites pendant les séances de ${prenom} s\'afficheront ici.',
			'historique.observations.videPhraseFoyer' => 'Vos visites pendant les séances s\'afficheront ici.',
			'historique.observations.filtreVideTitre' => 'Aucune observation ne correspond',
			'historique.observations.filtreVidePhrase' => 'Changez les filtres pour retrouver les autres visites.',
			'historique.observations.visiteUne' => '1 visite',
			'historique.observations.visites' => ({required Object n}) => '${n} visites',
			'historique.observations.dureeNonConfirmee' => 'Durée non confirmée',
			'historique.observations.terminee' => 'Terminée',
			'historique.observations.nonRefermee' => 'Sortie non enregistrée',
			'historique.observations.eleveInconnu' => 'Élève',
			'historique.observations.tronquee' => 'Seules les visites les plus récentes sont affichées.',
			'historique.observations.ouvrir' => ({required Object date, required Object classe, required Object etat}) => 'Observations du ${date}, ${classe}, ${etat}',
			'historique.seance.titreSansClasse' => ({required Object date}) => 'Séance du ${date}',
			'historique.seance.blocSeance' => 'La séance',
			'historique.seance.blocPresence' => ({required Object prenom}) => 'Présence de ${prenom}',
			'historique.seance.date' => 'Date',
			'historique.seance.horaire' => 'Horaire',
			'historique.seance.dureePrevue' => 'Durée prévue',
			'historique.seance.classe' => 'Classe',
			'historique.seance.enseignant' => 'Enseignant',
			'historique.seance.presence' => 'Présence',
			'historique.seance.arrivee' => 'Arrivée',
			'historique.seance.interruption' => 'Interruption',
			'historique.seance.verificationPhrase' => 'La présence n\'est pas encore confirmée pour cette séance.',
			'historique.seance.nonTenuPhrase' => 'La séance n\'a pas eu lieu : ce n\'est pas le fait de l\'élève.',
			'historique.seance.annulePhrase' => 'La séance a été annulée.',
			'historique.seance.introuvableTitre' => 'Séance introuvable',
			'historique.seance.introuvablePhrase' => 'Cette séance ne figure pas dans l\'historique de votre foyer.',
			'historique.observation.titreSansClasse' => ({required Object date}) => 'Observations du ${date}',
			'historique.observation.blocResume' => 'Résumé',
			'historique.observation.blocVisites' => 'Visites',
			'historique.observation.observateur' => 'Observateur',
			'historique.observation.vous' => 'Vous',
			'historique.observation.eleve' => 'Élève',
			'historique.observation.enseignant' => 'Enseignant',
			'historique.observation.dureeTotale' => 'Durée totale',
			'historique.observation.visite' => ({required Object n}) => 'Visite ${n}',
			'historique.observation.plageOuverte' => ({required Object debut}) => 'Entrée à ${debut}',
			'historique.observation.terminee' => 'Visite terminée',
			'historique.observation.introuvableTitre' => 'Aucune visite pour cette séance',
			'historique.observation.introuvablePhrase' => 'Aucune visite enregistrée ne correspond à cette séance.',
			'notifications.titre' => 'Notifications',
			'notifications.indisponibleTitre' => 'Les notifications ne sont pas encore disponibles',
			'notifications.indisponiblePhrase' => 'Les rappels de séance et les messages de l\'académie s\'afficheront ici dès qu\'ils seront ouverts.',
			'notifications.videTitre' => 'Aucune notification',
			'notifications.videPhrase' => 'Les rappels de séance et les messages de l\'académie s\'afficheront ici.',
			'notifications.ligne' => ({required Object titre, required Object date, required Object heure}) => '${titre}, le ${date} à ${heure}',
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
			'classe.entree.coursDans' => ({required Object duree}) => 'Cours dans ${duree}',
			'classe.entree.coursImminent' => 'Cours dans moins d\'une minute',
			'classe.entree.rejoindre' => 'Rejoindre',
			'classe.entree.rejoindreLecteur' => ({required Object classe}) => 'Rejoindre la séance de ${classe}',
			'classe.entree.salleOuverte' => ({required Object duree}) => 'La salle est ouverte. La séance commence dans ${duree}.',
			'classe.entree.salleOuverteImminent' => 'La salle est ouverte. La séance commence dans moins d\'une minute.',
			'classe.entree.preparation' => 'Préparation en cours',
			'classe.entree.attente' => ({required Object duree}) => 'Vous êtes dans la salle. La séance commence dans ${duree}.',
			'classe.entree.attenteImminent' => 'Vous êtes dans la salle. La séance commence dans moins d\'une minute.',
			'classe.entree.enDirect' => 'Séance en direct',
			'classe.entree.tempsEcoule' => 'Temps prévu écoulé',
			'classe.entree.terminee' => 'Séance terminée',
			'classe.entree.annulee' => 'Séance annulée',
			'classe.entree.aucune' => 'Aucune séance prévue',
			'classe.entree.horsLigne' => 'Vous êtes hors ligne. La séance nécessite une connexion.',
			'classe.entree.indisponible' => 'L\'information sur la séance est indisponible pour l\'instant.',
			'classe.entree.accesInverifiable' => 'L\'accès à la salle ne peut pas être vérifié pour le moment.',
			'classe.entree.reessayer' => 'Réessayer',
			'classe.entree.chargementSeance' => 'Chargement de la prochaine séance.',
			'classe.entree.progressionValeur' => ({required Object chapitre, required Object pourcentage}) => '${chapitre} · ${pourcentage} %',
			'classe.entree.dst' => ({required Object avant, required Object apres}) => 'Changement d\'heure : le cours passera de ${avant} à ${apres}.',
			'classe.entree.annonce.aVenir' => 'Séance à venir',
			'classe.entree.annonce.fenetreOuverte' => 'La salle est ouverte',
			'classe.entree.annonce.attente' => 'Vous êtes dans la salle',
			'classe.entree.demo.titre' => 'Entrée en classe',
			'classe.entree.demo.mention' => 'Démonstration',
			'classe.entree.demo.intro' => 'Données fictives, aucun appel serveur. Chaque lien montre ce que dit l\'emplacement d\'entrée pour un rôle et un moment.',
			'classe.entree.demo.roles.eleve' => 'Élève',
			'classe.entree.demo.roles.guidee' => 'Élève, Interface guidée',
			'classe.entree.demo.roles.enseignant' => 'Enseignant',
			'classe.entree.demo.etats.aVenir' => 'À venir',
			'classe.entree.demo.etats.fenetreOuverte' => 'Fenêtre ouverte',
			'classe.entree.demo.etats.preparation' => 'Préparation en cours',
			'classe.entree.demo.etats.attente' => 'Attente avant le début',
			'classe.entree.demo.etats.enDirect' => 'En direct',
			'classe.entree.demo.etats.tempsEcoule' => 'Temps prévu écoulé',
			'classe.entree.demo.etats.terminee' => 'Terminée',
			'classe.entree.demo.etats.annulee' => 'Annulée',
			'classe.entree.demo.etats.horsLigne' => 'Hors ligne',
			'classe.entree.demo.etats.indisponible' => 'Information indisponible',
			'classe.entree.demo.etats.changementHeure' => 'Changement d\'heure',
			'classe.entree.demo.formeBouton' => 'Forme : bouton',
			'classe.entree.demo.formeLigne' => 'Forme : ligne d\'état',
			'classe.entree.demo.lecteur' => ({required Object texte}) => 'Lecteur d\'écran : ${texte}',
			'classe.entree.demo.annonce' => ({required Object texte}) => 'Annonce : ${texte}',
			'classe.entree.demo.detail' => ({required Object texte}) => 'Détail : ${texte}',
			'classe.entree.demo.retour' => 'Retour à la liste',
			'classe.catalogue' => 'Choisir une classe',
			'classe.planning' => 'Planning',
			'classe.travail' => 'Avant le prochain cours',
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
			'classe.pagePlanning.indisponible' => 'Le planning de la classe n\'est pas encore relié à cet espace.',
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
			'classe.pageCatalogue.pour' => ({required Object prenom}) => 'Pour ${prenom}',
			'classe.pageCatalogue.proposees' => 'Classes proposées',
			'classe.pageCatalogue.indisponible' => 'Le choix de classe en ligne n\'est pas encore ouvert.',
			'classe.pageCatalogue.aucune' => 'Aucune classe ne convient pour l\'instant',
			'classe.pageCatalogue.aucuneDetail' => ({required Object prenom}) => 'Aucune classe ouverte ne correspond au profil de ${prenom} en ce moment.',
			'classe.pageCatalogue.eleveInconnuTitre' => 'Ce profil n\'est pas dans votre foyer',
			'classe.pageCatalogue.eleveInconnuPhrase' => 'Revenez à l\'accueil et choisissez le profil élève concerné.',
			'classe.pageCatalogue.horairesAbsents' => 'Les jours et heures de cette classe ne sont pas encore affichés ici.',
			'classe.pageCatalogue.seanceHebdo' => ({required Object jour, required Object heure, required Object duree}) => '${jour} à ${heure} · ${duree} min',
			'classe.pageCatalogue.fuseauClasse' => ({required Object fuseau}) => 'Heures de la classe (${fuseau})',
			'classe.pageCatalogue.placeUne' => '1 place restante',
			'classe.pageCatalogue.places' => ({required Object nombre}) => '${nombre} places restantes',
			'classe.pageCatalogue.etat.ouverte' => 'Ouverte',
			'classe.pageCatalogue.etat.complete' => 'Complète',
			'classe.pageCatalogue.etat.listeAttente' => 'Liste d\'attente',
			'classe.pageCatalogue.choisir' => 'Choisir cette classe',
			'classe.pageCatalogue.rejoindreAttente' => 'Rejoindre la liste d\'attente',
			'classe.pageCatalogue.precisionsTitre' => 'Avant de choisir',
			'classe.pageCatalogue.precisionEnseignant' => 'Une classe garde le même enseignant pour toutes ses séances.',
			'classe.pageCatalogue.precisionPlaces' => 'Les places affichées sont celles de l\'académie au moment de la lecture.',
			'classe.pageCatalogue.precisionReserve' => 'Rien n\'est réservé avant votre confirmation.',
			'classe.pageCatalogue.confirmerTitre' => 'Confirmer la classe',
			'classe.pageCatalogue.confirmerPhrase' => ({required Object prenom}) => 'Vous inscrivez ${prenom} dans cette classe.',
			'classe.pageCatalogue.confirmerAttentePhrase' => ({required Object prenom}) => 'Vous inscrivez ${prenom} sur la liste d\'attente de cette classe.',
			'classe.pageCatalogue.memeEnseignant' => ({required Object enseignant}) => 'Même classe et même enseignant pour toutes les séances de la semaine : ${enseignant}.',
			'classe.pageCatalogue.confirmer' => 'Confirmer l\'inscription',
			'classe.pageCatalogue.confirmerAttente' => 'Confirmer la liste d\'attente',
			'classe.pageCatalogue.envoiIncertain' => 'La réponse de l\'académie n\'est pas arrivée. Réessayer ne crée pas de seconde inscription.',
			'classe.pageCatalogue.envoiIndisponible' => 'L\'inscription en ligne n\'est pas encore ouverte : aucune place n\'a été réservée.',
			'classe.pageCatalogue.resultat.inscritTitre' => 'Inscription confirmée',
			'classe.pageCatalogue.resultat.inscritPhrase' => ({required Object prenom, required Object classe}) => '${prenom} rejoint ${classe}.',
			'classe.pageCatalogue.resultat.voirClasse' => 'Voir la classe',
			'classe.pageCatalogue.resultat.validationTitre' => 'Demande envoyée',
			'classe.pageCatalogue.resultat.validationPhrase' => ({required Object prenom, required Object classe}) => 'L\'académie doit encore valider l\'inscription de ${prenom} dans ${classe}.',
			'classe.pageCatalogue.resultat.listeAttenteTitre' => 'Inscription sur liste d\'attente',
			'classe.pageCatalogue.resultat.listeAttentePhrase' => ({required Object prenom, required Object classe}) => '${prenom} est sur la liste d\'attente de ${classe}. Aucune place n\'est réservée pour l\'instant.',
			'classe.pageCatalogue.resultat.refuseTitre' => 'Inscription non acceptée',
			'classe.pageCatalogue.resultat.refusePhrase' => ({required Object prenom}) => 'Aucune place n\'a été réservée pour ${prenom}. Vous pouvez choisir une autre classe.',
			'classe.pageCatalogue.resultat.autresClasses' => 'Voir les autres classes',
			'classe.pageCatalogue.resultat.retourAccueil' => 'Retour à l\'accueil',
			'enseignant.classes.titre' => 'Classes',
			'enseignant.classes.vide' => 'Aucune Classe attribuée',
			'enseignant.classes.videDetail' => 'Les Classes confirmées apparaîtront ici.',
			'enseignant.classes.erreur' => 'Vos Classes n\'ont pas pu être lues. Réessayez dans un instant.',
			'enseignant.classes.chargement' => 'Chargement de vos Classes.',
			'enseignant.classes.niveau' => ({required Object niveau}) => 'Niveau ${niveau}',
			'enseignant.classes.eleveUn' => '1 élève',
			'enseignant.classes.eleves' => ({required Object nombre}) => '${nombre} élèves',
			'enseignant.classes.prochaine' => ({required Object jour, required Object heure}) => 'Prochaine séance : ${jour} à ${heure}',
			'enseignant.classes.sansProchaine' => 'Aucune séance prévue',
			'enseignant.classes.remplacement' => 'Remplacement',
			'enseignant.classes.rappelCahier' => 'Un cahier de séance reste à valider',
			'enseignant.classes.cahierAValider' => 'Cahier à valider',
			'enseignant.eleve.titre' => ({required Object prenom}) => 'Fiche de ${prenom}',
			'enseignant.eleve.retour' => 'Élèves',
			'enseignant.eleve.identifiant' => ({required Object id}) => 'Identifiant Académie : ${id}',
			'enseignant.eleve.photo' => ({required Object prenom}) => 'Photo de ${prenom}',
			'enseignant.eleve.niveau' => 'Niveau',
			'enseignant.eleve.objectif' => 'Objectif',
			'enseignant.eleve.presence' => 'Présence récente',
			'enseignant.eleve.travail' => 'Travail',
			'enseignant.eleve.travailReprise' => ({required Object page}) => 'Reprise à la ${page}',
			'enseignant.eleve.derniereSeance' => 'Dernière séance',
			'enseignant.eleve.nonRenseigne' => 'Non renseigné',
			'enseignant.eleve.signaler' => 'Signaler un besoin',
			'enseignant.eleve.signalerAide' => 'Un besoin à remonter à l\'académie, sans recopier le contexte.',
			'enseignant.signalement.titre' => 'Signaler un besoin',
			'enseignant.signalement.contexte' => ({required Object prenom, required Object classe}) => 'Pour ${prenom} · ${classe}',
			'enseignant.signalement.categorieTitre' => 'Catégorie',
			'enseignant.signalement.categories.pedagogique' => 'Problème pédagogique',
			'enseignant.signalement.categories.presence' => 'Présence',
			'enseignant.signalement.categories.technique' => 'Technique',
			'enseignant.signalement.categories.changement' => 'Changement',
			'enseignant.signalement.categories.autre' => 'Autre',
			'enseignant.signalement.details' => 'Détails internes',
			'enseignant.signalement.detailsAide' => 'Lu par l\'équipe de l\'académie seulement.',
			'enseignant.signalement.resume' => 'Résumé partageable',
			'enseignant.signalement.resumeAide' => 'Peut être partagé avec la famille par l\'académie.',
			'enseignant.signalement.notice' => 'Les détails internes ne sont pas envoyés automatiquement à la famille.',
			'enseignant.signalement.choisirCategorie' => 'Choisissez une catégorie pour continuer.',
			'enseignant.signalement.detailsRequis' => 'Pour « Autre », dites en quelques mots de quoi il s\'agit.',
			'enseignant.signalement.envoyer' => 'Envoyer le signalement',
			'enseignant.signalement.demoSucces' => 'Démonstration : ce signalement est prêt, mais rien n\'a été envoyé.',
			'enseignant.signalement.demoSuccesDetail' => 'Dans l\'application reliée, il partira vers l\'équipe de l\'académie.',
			'enseignant.signalement.fermer' => 'Fermer',
			'enseignant.demo.titre' => 'Démonstration enseignant',
			'enseignant.demo.mention' => 'Données fictives, aucun envoi.',
			'enseignant.demo.intro' => 'Choisissez un écran de Sayyid Ibrahim.',
			'enseignant.demo.ecrans' => 'Écrans',
			'enseignant.demo.etats' => 'Situations',
			'enseignant.demo.etatNominal' => 'Journée ordinaire',
			'enseignant.demo.etatVide' => 'Aucune séance',
			'enseignant.demo.etatHorsLigne' => 'Hors ligne',
			'enseignant.bienvenue.titre' => 'Premiers pas',
			'enseignant.bienvenue.salutation' => ({required Object prenom}) => 'Bienvenue, ${prenom}.',
			'enseignant.bienvenue.salutationSansNom' => 'Bienvenue.',
			'enseignant.bienvenue.dossierValide' => 'Votre dossier est validé.',
			'enseignant.bienvenue.sousTitre' => 'Préparez votre espace avant votre première Classe.',
			'enseignant.bienvenue.aCompleter' => 'À compléter',
			'enseignant.bienvenue.compteur' => ({required Object fait, required Object total}) => '${fait} sur ${total}',
			'enseignant.bienvenue.prerequisPhoto' => 'Ajouter ma photo professionnelle',
			'enseignant.bienvenue.prerequisLangues' => 'Vérifier mes langues d\'enseignement',
			'enseignant.bienvenue.prerequisFuseau' => 'Vérifier mon fuseau horaire',
			'enseignant.bienvenue.ctaPhoto' => 'Ajouter ma photo',
			'enseignant.bienvenue.ctaInformations' => 'Vérifier mes informations',
			'enseignant.bienvenue.ctaJournee' => 'Voir ma journée',
			'enseignant.bienvenue.rappels' => 'Deux choses à ne pas découvrir en cours de route',
			'enseignant.bienvenue.declarer' => 'Déclarer mes disponibilités',
			'enseignant.bienvenue.versJournee' => 'Aller à ma journée',
			'enseignant.bienvenue.horsLigne' => 'Sans réseau, vos créneaux ne pourront pas être enregistrés.',
			'enseignant.bienvenue.dossierIncomplet' => 'Votre dossier n\'est pas encore validé.',
			'enseignant.bienvenue.dossierIncompletDetail' => 'Le portail d\'attente vous dit ce qu\'il reste à fournir.',
			'enseignant.bienvenue.versAttente' => 'Voir mon dossier',
			'enseignant.bienvenue.erreur' => 'Votre profil n\'a pas pu être lu. Réessayez dans un instant.',
			'enseignant.photo.titre' => 'Photo professionnelle',
			'enseignant.photo.aide' => 'Cette photo peut être visible par les élèves et les familles de vos Classes.',
			'enseignant.photo.notice' => 'N\'utilisez pas votre pièce d\'identité.',
			'enseignant.photo.choisir' => 'Choisir une photo',
			'enseignant.photo.utiliser' => 'Utiliser cette photo',
			'enseignant.photo.remplacer' => 'Remplacer la photo',
			'enseignant.photo.autre' => 'Choisir une autre photo',
			'enseignant.photo.changer' => 'Changer la photo',
			'enseignant.photo.alternatif' => 'Votre photo publique',
			'enseignant.photo.succes' => 'La photo est enregistrée.',
			_ => null,
		} ?? switch (path) {
			'enseignant.photo.echec' => 'La photo n\'a pas pu être envoyée. Rien n\'a changé sur le profil.',
			'enseignant.photo.selectionEchec' => 'La photo n\'a pas pu être ouverte. Vérifiez l\'accès aux photos de l\'appareil, puis réessayez.',
			'enseignant.photo.horsLigne' => 'Vous êtes hors ligne. La photo pourra être envoyée quand la connexion reviendra.',
			'enseignant.journee.lancer' => 'Lancer le cours',
			'enseignant.journee.preflight' => 'Vérifier avant le cours',
			'enseignant.journee.titre' => 'Aujourd\'hui',
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
			'enseignant.journee.preflightOk' => 'Micro prêt',
			'enseignant.journee.preflightBloque' => 'Le micro est bloqué par votre navigateur. Autorisez-le pour lancer le cours.',
			'enseignant.journee.preflightSansMicro' => 'Aucun micro n\'est détecté. Branchez-en un pour lancer le cours.',
			'enseignant.journee.preflightIndisponible' => 'La vérification du matériel n\'a pas abouti. Réessayez avant de lancer le cours.',
			'enseignant.journee.lancerHorsLigne' => 'Sans réseau, la salle ne peut pas s\'ouvrir. Reconnectez-vous pour lancer le cours.',
			'enseignant.journee.erreurPartielle' => 'Une partie de la journée n\'a pas pu être lue : prières ou pauses peuvent manquer.',
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
			'enseignant.journee.prochaineSeance' => 'Prochaine séance',
			'enseignant.journee.maJournee' => 'Ma journée',
			'enseignant.journee.aTerminer' => 'À terminer',
			'enseignant.journee.aTerminerAide' => 'Le cahier aide vos élèves et vous permet d\'ajuster le prochain cours.',
			'enseignant.journee.rappelCahier' => 'Des cahiers attendent d\'être terminés',
			'enseignant.journee.cahierLigne' => ({required Object classe}) => 'Cahier ${classe}',
			'enseignant.journee.cahierDetail' => ({required Object jour, required Object numero, required Object mois, required Object heure}) => 'Séance du ${jour} ${numero} ${mois} à ${heure}',
			'enseignant.journee.alertesUtiles' => 'Alertes utiles',
			'enseignant.journee.heure' => 'Heure',
			'enseignant.journee.eleves' => 'Élèves',
			'enseignant.journee.classe' => 'Classe',
			'enseignant.journee.classeNommee' => ({required Object classe}) => 'Classe ${classe}',
			'enseignant.journee.preparerSeance' => 'Préparer la séance',
			'enseignant.journee.preparerSeanceLecteur' => ({required Object classe}) => 'Préparer la séance ${classe}',
			'enseignant.journee.derniereSeance' => 'Dernière séance',
			'enseignant.journee.rejoindreSalle' => 'Rejoindre la salle',
			'enseignant.journee.rejoindreSalleLecteur' => ({required Object classe}) => 'Rejoindre la salle de la Classe ${classe}',
			'enseignant.journee.remplirCahier' => 'Remplir le cahier de transmission',
			'enseignant.journee.remplirCahierLecteur' => ({required Object classe}) => 'Remplir le cahier de transmission de la Classe ${classe}',
			'enseignant.journee.cahierObligatoire' => ({required Object classe}) => 'Obligatoire : le cahier ${classe} se remplit à la fin de chaque séance.',
			'enseignant.journee.voirCahier' => ({required Object classe}) => 'Voir le cahier ${classe}',
			'enseignant.journee.voirCahierLecteur' => ({required Object classe}) => 'Voir le cahier de transmission de la Classe ${classe}',
			'enseignant.journee.voirClasse' => 'Voir la Classe',
			'enseignant.journee.voirClasseLecteur' => ({required Object classe}) => 'Voir la Classe ${classe}',
			'enseignant.journee.aucuneSeance' => 'Aucune séance à venir',
			'enseignant.journee.aucuneSeanceDetail' => 'Vos prochaines séances apparaîtront ici.',
			'enseignant.journee.date' => ({required Object jour, required Object numero, required Object mois}) => '${jour} ${numero} ${mois}',
			'enseignant.journee.absence.ouvrir' => 'Déclarer une absence',
			'enseignant.journee.absence.titre' => 'Vous ne pourrez pas assurer cette séance ?',
			'enseignant.journee.absence.cleDate' => 'Date',
			'enseignant.journee.absence.notice' => 'Votre affectation à la Classe reste inchangée.',
			'enseignant.journee.absence.declarer' => 'Déclarer mon absence',
			'enseignant.journee.absence.echec' => 'La demande n\'a pas abouti. Réessayez dans un instant.',
			'enseignant.journee.absence.etats.enregistree' => 'Absence enregistrée',
			'enseignant.journee.absence.etats.recherche' => 'Recherche d\'un remplaçant',
			'enseignant.journee.absence.etats.remplacantConfirme' => 'Remplaçant confirmé',
			'enseignant.journee.absence.etats.aucunRemplacant' => 'Aucun remplaçant confirmé',
			'enseignant.journee.absence.etats.seanceAnnulee' => 'Séance annulée',
			'enseignant.journee.absence.etats.demandeAnnulee' => 'Demande annulée',
			'enseignant.journee.remplacement.titre' => 'Assurer ce remplacement ?',
			'enseignant.journee.remplacement.assurer' => 'Assurer ce remplacement',
			'enseignant.journee.remplacement.pasCetteFois' => 'Pas cette fois',
			'enseignant.salle.reference' => ({required Object page, required Object total, required Object reference}) => 'Présenté : page ${page} sur ${total} · ${reference}',
			'enseignant.salle.rien' => 'Rien n\'est présenté',
			'enseignant.salle.rienInvitation' => 'Ouvrez le Coran pour montrer une page à votre Classe.',
			'enseignant.salle.attenteSalle' => 'Vous n\'êtes pas encore dans la salle',
			'enseignant.salle.attenteSalleDetail' => 'Les commandes de présentation s\'ouvrent dès que le cours est connecté.',
			'enseignant.salle.lienFaibleDetail' => 'le tour de page peut arriver en retard chez votre Classe',
			'enseignant.salle.presentationConservee' => 'la page présentée est conservée, elle repartira au retour du lien',
			'enseignant.salle.presentationSuspendue' => 'présentation suspendue',
			'enseignant.salle.precedente' => 'Présenter la page précédente',
			'enseignant.salle.suivante' => 'Présenter la page suivante',
			'enseignant.salle.bibliotheque' => 'Choisir une sourate',
			'enseignant.salle.presenterSourate' => ({required Object sourate}) => 'Présenter le début de ${sourate}',
			'enseignant.salle.sourateDetail' => ({required Object numero, required Object versets}) => 'Sourate ${numero} · ${versets} versets',
			'enseignant.salle.souratesIndisponibles' => 'La liste des sourates n\'a pas pu être lue',
			'enseignant.salle.souratesIndisponiblesDetail' => 'Ce que votre Classe voit n\'a pas changé. Réessayez.',
			'enseignant.salle.pageIndisponible' => 'Cette page n\'a pas pu être lue',
			'enseignant.salle.pageIndisponibleDetail' => 'Le texte n\'est pas arrivé jusqu\'ici. Votre Classe voit toujours la page présentée.',
			'enseignant.salle.corpusAbsent' => 'Le texte du Coran n\'est pas installé',
			'enseignant.salle.corpusAbsentDetail' => 'Il n\'y a rien à présenter.',
			'enseignant.salle.echecPresentation' => 'Ce verset n\'a pas pu être situé dans le mushaf. Rien n\'a été envoyé à votre Classe.',
			'enseignant.salle.sansDroitPresentation' => 'Votre accès à cette séance ne permet pas de présenter un contenu.',
			'enseignant.cahier.titre' => 'Cahier de séance',
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
			'enseignant.cahier.valider' => 'Valider le cahier',
			'enseignant.cahier.validerTout' => 'Tout est conforme, valider',
			'enseignant.cahier.validerSansConstat' => 'Déposer sans le constat',
			'enseignant.cahier.retourJournee' => 'Retour à ma journée',
			'enseignant.cahier.vide' => 'Le constat n\'a pas pu être déduit',
			'enseignant.cahier.videDetail' => 'Aucune présence et aucun événement n\'ont été relevés pour cette séance. Vous pouvez tout de même déposer le cahier.',
			'enseignant.cahier.erreur' => 'Le constat n\'a pas pu être lu.',
			'enseignant.cahier.erreurDetail' => 'Réessayez, ou déposez le cahier sans le constat.',
			'enseignant.cahier.echecEnvoi' => 'Le cahier n\'a pas pu être enregistré. Réessayez.',
			'enseignant.cahier.dejaDepose' => 'Le cahier de cette séance est déjà déposé.',
			'enseignant.cahier.dejaDeposeDetail' => 'Un cahier ne se dépose qu\'une fois, et il ne se supprime pas d\'ici.',
			'enseignant.cahier.depose' => 'Cahier enregistré',
			'enseignant.cahier.deposeDetail' => 'L\'académie l\'a reçu.',
			'enseignant.cahier.enFileTitre' => 'En attente d\'envoi',
			'enseignant.cahier.enFile' => 'Le cahier sera envoyé lorsque la connexion reviendra.',
			'enseignant.cahier.enFileDetail' => 'Le cahier sera envoyé lorsque la connexion reviendra.',
			'enseignant.cahier.enFileDetailHorsLigne' => 'Sans réseau, le cahier reste sur cet appareil et part dès que le réseau revient. Vous pouvez enchaîner sur votre cours suivant.',
			'enseignant.cahier.ajusterPour' => ({required Object eleve}) => 'Ajuster · ${eleve}',
			'enseignant.cahier.ajusterValider' => 'Enregistrer pour cet élève',
			'enseignant.cahier.exceptionConsignee' => 'Exception signalée',
			'enseignant.cahier.pointPhonetique' => 'Point de prononciation',
			'enseignant.cahier.pointPhonetiqueDetail' => 'Une paire, pas un bilan. Laissez vide s\'il n\'y a rien à dire.',
			'enseignant.cahier.pointPhonetiqueNote' => 'Point de prononciation noté',
			'enseignant.cahier.objectif' => 'Objectif personnel',
			'enseignant.cahier.objectifDetail' => 'Il s\'inscrit dans le programme de l\'académie, qui ne se modifie pas d\'ici.',
			'enseignant.cahier.travailMaison' => 'Devoir à faire',
			'enseignant.cahier.travailMaisonDetail' => 'Ajustez la suggestion, ou laissez-la telle quelle.',
			'enseignant.cahier.suite' => 'La suite pour cet élève',
			'enseignant.cahier.suiteContinuer' => 'Continuer',
			'enseignant.cahier.suiteRenforcer' => 'Renforcer',
			'enseignant.cahier.suspendreNouveau' => 'Suspendre le nouveau',
			'enseignant.cahier.devoirPrecedent' => ({required Object devoir}) => 'Devoir précédent : ${devoir}',
			'enseignant.cahier.devoirPlage' => ({required Object sourate, required Object debut, required Object fin}) => 'Réviser la sourate ${sourate}, versets ${debut} à ${fin}.',
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
			'enseignant.cahier.exceptionMotifRequis' => 'Le motif est obligatoire.',
			'enseignant.cahier.exceptionEnCours' => 'Enregistrement…',
			'enseignant.cahier.exceptionSucces' => 'Exception consignée. Elle partira avec le cahier.',
			'enseignant.cahier.exceptionErreur' => 'L\'exception n\'a pas pu être consignée.',
			'enseignant.cahier.exceptionHorsLigne' => 'Sans réseau, une exception ne peut pas être confirmée. Le cahier, lui, part quand même.',
			'enseignant.cahier.aValider' => 'À valider',
			'enseignant.cahier.statutPresents' => ({required Object nombre}) => 'Présents ${nombre}',
			'enseignant.cahier.statutAbsents' => ({required Object nombre}) => 'Absents ${nombre}',
			'enseignant.cahier.statutEnRetard' => ({required Object nombre}) => 'En retard ${nombre}',
			'enseignant.cahier.performance' => 'Performance',
			'enseignant.cahier.faiblesses' => 'Faiblesses',
			'enseignant.cahier.reprise' => 'Où la Classe s\'est arrêtée',
			'enseignant.cahier.repriseDetail' => 'C\'est la position de reprise d\'un remplaçant.',
			'enseignant.cahier.repriseProposee' => ({required Object sourate, required Object verset}) => 'Sourate ${sourate}, verset ${verset}',
			'enseignant.cahier.repriseRequise' => 'Indiquez où la Classe s\'est arrêtée : un remplaçant reprendra ici.',
			'enseignant.cahier.integrite' => 'Ce que vous écrivez ici engage votre parole. Les hommes ne peuvent pas le vérifier, mais Allah voit tout.',
			'enseignant.cahier.corriger' => 'Corriger le cahier',
			'enseignant.cahier.corrigeLe' => ({required Object date}) => 'Corrigé le ${date}',
			'enseignant.profil.titre' => 'Profil',
			'enseignant.profil.compteValide' => 'Compte enseignant vérifié',
			'enseignant.profil.intro' => 'Ce que l\'académie sait de vous, et ce que vous pouvez y changer.',
			'enseignant.profil.identite' => 'Identité professionnelle',
			'enseignant.profil.pays' => 'Pays',
			'enseignant.profil.langues' => 'Langues',
			'enseignant.profil.fuseau' => 'Fuseau de mes cours',
			'enseignant.profil.fuseauDetail' => 'C\'est lui qui décide de l\'heure de vos créneaux, pas l\'heure de cet appareil.',
			'enseignant.profil.plafond' => 'Plafond hebdomadaire',
			'enseignant.profil.plafondValeur' => ({required Object nombre}) => '${nombre} h par semaine',
			'enseignant.profil.plafondDetail' => 'Fixé par l\'académie.',
			'enseignant.profil.nonRenseigne' => 'Non renseigné',
			'enseignant.profil.statutSection' => 'Statut du compte',
			'enseignant.profil.statutValideDetail' => 'Vous pouvez enseigner et déclarer vos heures.',
			'enseignant.profil.statutEnAttente' => 'Dossier en cours de vérification',
			'enseignant.profil.statutEnAttenteDetail' => 'L\'académie vérifie vos pièces. Vous n\'avez rien de plus à faire.',
			'enseignant.profil.statutProvisoire' => 'Accès provisoire',
			'enseignant.profil.statutProvisoireDetail' => 'Vous enseignez déjà. Votre dossier reste à compléter, sans coupure automatique.',
			'enseignant.profil.statutSuspendu' => 'Compte suspendu',
			'enseignant.profil.statutSuspenduDetail' => 'Vous pouvez joindre l\'académie pour connaître la marche à suivre.',
			'enseignant.profil.statutInconnu' => 'Statut non disponible',
			'enseignant.profil.statutInconnuDetail' => 'Nous n\'avons pas pu lire votre statut.',
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
			'enseignant.profil.contratLectureSeule' => 'Ces pièces sont en lecture seule.',
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
			'enseignant.creneaux.aucuneHeure' => 'Vous n\'avez proposé aucune heure. Sans créneau, aucune Classe ne peut vous être proposée.',
			'enseignant.creneaux.heureEnregistree' => ({required Object heure}) => '${heure} enregistré',
			'enseignant.creneaux.heureRetiree' => ({required Object heure}) => '${heure} retiré',
			'enseignant.creneaux.retraitEngage' => ({required Object heure}) => '${heure} retiré. La séance déjà attribuée sur cette heure continue : demandez une réaffectation pour l\'arrêter.',
			'enseignant.creneaux.grilleErreur' => 'Vos heures n\'ont pas pu être lues',
			'enseignant.creneaux.grilleErreurDetail' => 'Les heures que vous avez déjà posées ne sont pas perdues.',
			'enseignant.creneaux.horsLigneGrille' => 'Sans réseau, vos heures restent consultables mais ne peuvent pas être modifiées.',
			'enseignant.creneaux.heureEngagee' => ({required Object heures}) => 'Vous avez déjà une Classe sur ${heures}. Retirer cette heure ne met pas fin à la séance : il faut une réaffectation.',
			'enseignant.creneaux.heuresEngagees' => ({required Object heures}) => 'Vous avez déjà une Classe sur ${heures}. Retirer ces heures ne met pas fin aux séances : il faut une réaffectation.',
			'enseignant.creneaux.feedErreur' => 'Les familles en attente n\'ont pas pu être lues',
			'enseignant.creneaux.feedErreurDetail' => 'Rien n\'est perdu : personne n\'a été pris, et vos heures restent posées.',
			'enseignant.creneaux.horsLignePrise' => 'Sans réseau, vous ne pouvez pas prendre d\'élève. Les demandes ci-dessous restent consultables.',
			'enseignant.creneaux.horsLigneDemande' => 'Sans réseau, cette demande ne partirait pas. Réessayez au retour de la connexion.',
			'enseignant.creneaux.refusDejaPris' => 'Cet élève vient d\'être pris par un autre enseignant. La liste ci-dessous est à jour.',
			'enseignant.creneaux.refusDejaSuivi' => 'Cet élève a déjà un enseignant. La liste ci-dessous est à jour.',
			'enseignant.creneaux.refusCreneauRetire' => 'Cette famille ne propose plus ce créneau. La liste ci-dessous est à jour.',
			'enseignant.creneaux.refusHorsMesHeures' => 'Ce créneau ne figure plus dans vos heures. Reposez-le dans Mes heures pour pouvoir le prendre.',
			'enseignant.creneaux.refusPlafond' => 'Vous avez atteint votre maximum d\'élèves. Demandez une augmentation pour en suivre un de plus.',
			'enseignant.creneaux.mesDisponibilites' => 'Mes disponibilités',
			'enseignant.creneaux.ajouterCreneau' => 'Ajouter un créneau',
			'enseignant.creneaux.heure' => ({required Object heure}) => '${heure} h',
			'enseignant.creneaux.classesDisponibles' => 'Classes disponibles',
			'enseignant.creneaux.etatDisponible' => 'Disponible',
			'enseignant.creneaux.etatEnAttente' => 'En attente de validation',
			'enseignant.creneaux.etatLimite' => 'Limite de charge atteinte',
			'enseignant.creneaux.limiteDetail' => 'Votre charge actuelle ne permet pas de réserver une Classe supplémentaire.',
			'enseignant.creneaux.aucuneClasse' => 'Aucune Classe compatible pour le moment',
			'enseignant.creneaux.aucuneClasseDetail' => 'Modifiez vos disponibilités si votre emploi du temps a changé.',
			'enseignant.creneaux.reserver' => 'Réserver cette Classe',
			'enseignant.creneaux.demandeTransmise' => 'Votre demande a été transmise.',
			'enseignant.creneaux.demandeTransmiseDetail' => 'Elle apparaîtra dans vos Classes après confirmation.',
			'enseignant.creneaux.confirmerTitre' => 'Confirmer cette Classe ?',
			'enseignant.creneaux.confirmer' => 'Confirmer cette Classe',
			'enseignant.creneaux.revenir' => 'Revenir',
			'enseignant.creneaux.cleNiveau' => 'Niveau',
			'enseignant.creneaux.cleLangue' => 'Langue',
			'enseignant.creneaux.cleRecurrence' => 'Récurrence',
			'enseignant.creneaux.cleFuseau' => 'Fuseau de référence',
			'enseignant.creneaux.cleHeureLocale' => 'Heure locale',
			'enseignant.creneaux.cleDuree' => 'Durée',
			'enseignant.creneaux.duree' => ({required Object minutes}) => '${minutes} min',
			'enseignant.ficheGroupe.creneauHebdo' => ({required Object jour, required Object heure}) => '${jour} à ${heure}, chaque semaine',
			'enseignant.ficheGroupe.aucunMembre' => 'Aucun élève dans cette Classe',
			'enseignant.ficheGroupe.aucunMembreDetail' => 'L\'administration compose les Classes : celle-ci n\'a pas encore d\'élève.',
			'enseignant.ficheGroupe.erreur' => 'Cette Classe n\'a pas pu être lue. Réessayez dans un instant.',
			'enseignant.ficheGroupe.introuvable' => 'Cette Classe n\'est pas l\'une des vôtres',
			'enseignant.ficheGroupe.introuvableDetail' => 'Elle a peut-être été clôturée, ou elle appartient à un autre enseignant.',
			'enseignant.ficheGroupe.revue' => 'Ouvrir la revue de la Classe',
			'enseignant.ficheGroupe.elevesTitre' => 'Élèves',
			'enseignant.ficheGroupe.preparationTitre' => 'À préparer',
			'enseignant.ficheGroupe.supportPrevu' => 'Support prévu',
			'enseignant.ficheGroupe.positionReprise' => 'Position de reprise',
			'enseignant.ficheGroupe.objectif' => 'Objectif',
			'enseignant.ficheGroupe.preparationVide' => 'Aucune préparation renseignée pour cette séance.',
			'enseignant.ficheGroupe.supportsTitre' => 'Supports récents',
			'enseignant.ficheGroupe.repriseEleve' => ({required Object page}) => 'Reprise : ${page}',
			'enseignant.ficheGroupe.dernierPoint' => ({required Object texte}) => 'Dernier point : ${texte}',
			'enseignant.ficheGroupe.chargementClasse' => 'Chargement de la Classe.',
			'enseignant.ficheGroupe.ressourcesTitre' => 'Ressources récentes',
			'enseignant.ficheGroupe.progressionTitre' => 'Progression de la Classe',
			'enseignant.ficheGroupe.indicateurRegulier' => 'Présence régulière',
			'enseignant.ficheGroupe.indicateurARenforcer' => 'À renforcer',
			'enseignant.ficheGroupe.indicateurAbsence' => 'Absence récente',
			'enseignant.revue.titre' => 'Revue de la Classe',
			'enseignant.revue.titreClasse' => ({required Object classe}) => 'Revue de la Classe ${classe}',
			'enseignant.revue.aucuneAnomalie' => 'Rien ne demande votre attention.',
			'enseignant.revue.erreur' => 'La revue n\'a pas pu être lue.',
			'enseignant.revue.erreurDetail' => 'Cette Classe n\'est peut-être pas la vôtre, ou la lecture a échoué.',
			'enseignant.revue.pasDeDecision' => 'Vous signalez, l\'académie tranche : un transfert et une réorientation ne se décident pas depuis ici.',
			'enseignant.revue.typeGate' => 'Palier à venir',
			'enseignant.revue.typeCorridor' => 'Élève hors corridor',
			'enseignant.revue.typeTransfert' => 'Proposition de transfert',
			'enseignant.revue.typeReorientation' => 'Proposition de réorientation',
			'controleur.historique.titre' => 'Historique',
			'controleur.historique.provisoire' => 'Cet écran est en préparation.',
			'controleur.compteRendu.titre' => 'Compte rendu',
			'controleur.compteRendu.provisoire' => 'Cet écran est en préparation.',
			'controleur.compteRendu.revenir' => 'Revenir au contrôle',
			'controleur.compteRendu.sousTitre' => ({required Object classe, required Object heure}) => '${classe} · ${heure}',
			'controleur.compteRendu.faits' => 'Faits automatiques',
			'controleur.compteRendu.faitsReplies' => 'Faits automatiques, repliés',
			'controleur.compteRendu.faitsDeplies' => 'Faits automatiques, dépliés',
			'controleur.compteRendu.faitsChargement' => 'Lecture des faits de la visite en cours.',
			'controleur.compteRendu.faitsAbsents' => 'Les faits de la visite ne sont pas encore disponibles.',
			'controleur.compteRendu.cleHoraire' => 'Heure prévue',
			'controleur.compteRendu.horaire' => ({required Object debut, required Object fin}) => '${debut} à ${fin}',
			'controleur.compteRendu.cleDebutReel' => 'Début réel',
			'controleur.compteRendu.debutRetard' => ({required Object heure, required Object minutes}) => '${heure}, ${minutes} min de retard',
			'controleur.compteRendu.debutALHeure' => ({required Object heure}) => '${heure}, à l\'heure',
			'controleur.compteRendu.cleFin' => 'Fin',
			'controleur.compteRendu.enCours' => 'En cours',
			'controleur.compteRendu.clePresents' => 'Élèves présents',
			'controleur.compteRendu.presents' => ({required Object presents, required Object attendus}) => '${presents} sur ${attendus}',
			'controleur.compteRendu.cleReconnexions' => 'Reconnexions',
			'controleur.compteRendu.question' => 'Avez-vous quelque chose à signaler ?',
			'controleur.compteRendu.rienASignaler' => 'Rien à signaler',
			'controleur.compteRendu.ajouterObservation' => 'Ajouter une observation',
			'controleur.compteRendu.pointImportant' => 'Signaler un point important',
			'controleur.compteRendu.envoyer' => 'Envoyer le compte rendu',
			'controleur.compteRendu.plusTard' => 'Plus tard',
			'controleur.compteRendu.notice' => 'Ce compte rendu est transmis automatiquement à l\'administration.',
			'controleur.compteRendu.echec' => 'Le compte rendu n\'a pas pu être envoyé. Votre choix est gardé : réessayez dans un instant.',
			'controleur.compteRendu.envoyeTitre' => 'Compte rendu envoyé',
			'controleur.compteRendu.envoyePhrase' => 'Il est transmis à l\'administration. Pour y revenir, ouvrez-le dans l\'Historique et choisissez « Ajouter un complément ».',
			'controleur.compteRendu.ecrireAdmin' => 'Écrire à l\'administration',
			'controleur.compteRendu.visiteEnCours' => 'Transmission de la visite à l\'administration en cours.',
			'controleur.compteRendu.visiteTransmise' => 'La visite et ses faits sont transmis à l\'administration.',
			'controleur.compteRendu.visiteEchec' => 'La visite n\'a pas encore pu être transmise à l\'administration.',
			'controleur.compteRendu.aTerminer' => 'Compte rendu à terminer',
			'controleur.compteRendu.reprendre' => 'Reprendre le compte rendu',
			'controleur.observation.important' => 'Vous signalez un point important : votre texte sera demandé.',
			'controleur.observation.questionNature' => 'Quelle est la nature de votre observation ?',
			'controleur.observation.pointPositif' => 'Point positif',
			'controleur.observation.aSuivre' => 'À suivre',
			'controleur.observation.interventionAdmin' => 'Intervention Admin souhaitée',
			'controleur.observation.questionDomaine' => 'Quel domaine concerne-t-elle ?',
			'controleur.observation.pedagogie' => 'Pédagogie',
			'controleur.observation.interaction' => 'Interaction avec les élèves',
			'controleur.observation.gestionClasse' => 'Gestion de la classe',
			'controleur.observation.respectCadre' => 'Respect du cadre',
			'controleur.observation.climat' => 'Comportement / climat',
			'controleur.observation.autre' => 'Autre',
			'controleur.observation.questionPersonne' => 'Qui est concerné ?',
			'controleur.observation.enseignant' => 'Enseignant',
			'controleur.observation.classeEntiere' => 'Classe entière',
			'controleur.observation.elevePrecis' => 'Élève précis',
			'controleur.observation.aucun' => 'Aucun participant précis',
			'controleur.observation.questionEleve' => 'Choisissez l\'élève dans la liste de la Classe.',
			'controleur.observation.rosterIndisponible' => 'La liste des élèves n\'est pas disponible pour le moment.',
			'controleur.observation.questionTexte' => 'Qu\'avez-vous observé ?',
			'controleur.observation.texteObligatoire' => 'Votre texte est nécessaire pour cette observation.',
			'controleur.observation.texteFacultatif' => 'Ce texte est facultatif.',
			'controleur.observation.libelleTexte' => 'Votre remarque',
			'controleur.observation.aideTexte' => 'Décrivez seulement ce que vous avez observé.',
			'controleur.observation.texteRequis' => 'Écrivez ce que vous avez observé pour continuer.',
			'controleur.observation.questionRecap' => 'Vérifiez votre observation avant l\'envoi.',
			'controleur.observation.cleNature' => 'Nature',
			'controleur.observation.cleDomaine' => 'Domaine',
			'controleur.observation.clePersonne' => 'Personne concernée',
			'controleur.observation.cleTexte' => 'Remarque',
			'controleur.observation.sansTexte' => 'Aucun texte',
			'controleur.observation.echec' => 'L\'observation n\'a pas pu être envoyée. Votre saisie est gardée : réessayez dans un instant.',
			'controleur.echanges.titre' => 'Échanges',
			'controleur.echanges.titreFil' => ({required Object classe, required Object date}) => '${classe} · ${date}',
			'controleur.echanges.derniereActivite' => ({required Object date}) => 'Dernière activité : ${date}',
			'controleur.echanges.reponseRecue' => 'Réponse reçue',
			'controleur.echanges.enAttente' => 'En attente',
			'controleur.echanges.vide' => 'Aucun échange avec l\'administration pour le moment.',
			'controleur.echanges.contexte' => 'Contexte de la visite, joint automatiquement',
			'controleur.echanges.cleClasse' => 'Classe',
			'controleur.echanges.cleDate' => 'Date',
			'controleur.echanges.cleHeure' => 'Heure',
			'controleur.echanges.auteurVous' => 'Vous',
			'controleur.echanges.auteurAdmin' => 'Administration',
			'controleur.echanges.champ' => 'Répondre à l\'administration…',
			'controleur.echanges.champLibelle' => 'Répondre à l\'administration',
			'controleur.echanges.envoyer' => 'Envoyer',
			'controleur.echanges.champVide' => 'Écrivez un message pour pouvoir l\'envoyer.',
			'controleur.echanges.enCours' => 'Envoi en cours.',
			'controleur.echanges.envoye' => 'Envoyé.',
			'controleur.echanges.echec' => 'Ce message n\'a pas pu être envoyé. Il est gardé : réessayez.',
			'controleur.echanges.reessayer' => 'Réessayer',
			'controleur.echanges.nouveauMessage' => ({required Object auteur, required Object texte}) => 'Nouveau message de ${auteur} : ${texte}',
			'controleur.demo.titre' => 'Démonstration contrôleur',
			'controleur.demo.mention' => 'Données fictives, aucun envoi.',
			'controleur.demo.intro' => 'Choisissez un écran du contrôle et une situation de mission.',
			'controleur.demo.etatAucune' => 'Aucune mission',
			'controleur.demo.etatPasEncoreEnDirect' => 'Séance pas encore en direct',
			'controleur.demo.etatEnDirect' => 'Séance en direct',
			'controleur.demo.etatIndisponible' => 'Mission indisponible',
			'controleur.demo.espaces' => 'Espaces et accès',
			'controleur.demo.espacesIntro' => 'Le même compte, plusieurs espaces : Enseignant ou Admin passent en Contrôle par Compte, puis Espaces.',
			'controleur.demo.enseignantControle' => 'Enseignant-Contrôleur, espace Contrôle',
			'controleur.demo.enseignantPrincipal' => 'Enseignant-Contrôleur, espace Enseignant',
			'controleur.demo.adminControle' => 'Admin-Contrôleur, espace Contrôle',
			'controleur.demo.adminPrincipal' => 'Admin-Contrôleur, espace Admin',
			'controleur.demo.missionEnCours' => 'Mission en cours, retour à l\'espace principal',
			'controleur.demo.accesRevoque' => 'Accès révoqué pendant la navigation',
			'controleur.demo.sansCapacite' => 'Enseignant sans capacité Contrôle',
			'controleur.demo.compteRenduIndisponible' => 'Compte rendu, mission devenue indisponible',
			'controleur.acces.revoque' => 'Votre accès au contrôle n\'est plus actif.',
			'controleur.acces.revenir' => 'Revenir à mon espace',
			'controleur.controle.titre' => 'Contrôle',
			'controleur.controle.mission' => 'Votre prochaine mission',
			'controleur.controle.commencer' => 'Commencer le contrôle',
			'controleur.controle.vide' => 'Aucun contrôle n\'est à réaliser pour le moment.',
			'controleur.controle.videAide' => 'Rewayah vous proposera une mission lorsqu\'une séance compatible sera disponible.',
			'controleur.controle.indisponible' => 'Cette mission n\'est plus disponible.',
			'controleur.controle.attente' => 'Le contrôle s\'ouvrira dès que la séance sera en direct.',
			'controleur.controle.incognito' => 'Visite en mode incognito : votre présence n\'est pas annoncée à l\'enseignant.',
			'controleur.controle.horaire' => ({required Object debut, required Object fin}) => '${debut} à ${fin}',
			'controleur.controle.duree' => ({required Object minutes}) => '${minutes} min prévues',
			'controleur.controle.eleves' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('fr'))(n, one: '${n} élève', other: '${n} élèves', ), 
			'controleur.controle.chargement' => 'Lecture de votre mission en cours.',
			'controleur.controle.erreur' => 'Votre mission n\'a pas pu être lue. Réessayez dans un instant.',
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
			'tc.groupe.mesGroupes.titre' => 'Mes classes',
			'tc.groupe.mesGroupes.aucun' => 'Aucune classe pour le moment',
			'tc.groupe.mesGroupes.aucunDetail' => 'L\'académie vous placera dans une classe dès qu\'un créneau vous correspond.',
			'tc.groupe.commun.erreur' => 'Vos classes n\'ont pas pu être lues',
			'tc.groupe.commun.reessayer' => 'Réessayer',
			'tc.groupe.carte.ouvrir' => ({required Object libelle}) => 'Ouvrir la classe ${libelle}',
			'tc.groupe.carte.capacite' => ({required Object membres, required Object seuil}) => '${membres} / ${seuil}',
			'tc.groupe.carte.capacitePhrase' => ({required Object membres, required Object seuil}) => '${membres} élèves sur ${seuil} places',
			'tc.groupe.carte.complet' => 'Complet',
			'tc.groupe.carte.prochainCours' => 'Prochain cours',
			'tc.groupe.carte.aucuneSeance' => 'Aucune séance planifiée',
			'tc.groupe.carte.aucuneSeanceDetail' => 'Le planning de cette classe n\'est pas encore posé.',
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
			'tc.groupe.horloges.heureGroupe' => 'Heure de la classe',
			'tc.groupe.horloges.heureEtVille' => ({required Object heure, required Object ville}) => '${heure} ${ville}',
			'tc.groupe.dst.j30' => 'Changement d\'heure dans un mois',
			'tc.groupe.dst.j7' => 'Changement d\'heure la semaine prochaine',
			'tc.groupe.dst.j1' => 'Changement d\'heure demain',
			'tc.groupe.dst.detail' => ({required Object avant, required Object apres}) => 'Votre cours passera de ${avant} à ${apres}.',
			'tc.groupe.session.conseilAppareil' => 'Tablette ou ordinateur conseillé pour le cours. Le téléphone reste pris en charge.',
			'tc.groupe.espace.retour' => 'Mes classes',
			'tc.groupe.espace.avantProchainCours' => 'Avant le prochain cours',
			'tc.groupe.espace.aucuneAction' => 'Rien à préparer pour l\'instant',
			'tc.groupe.espace.bibliotheque' => 'Bibliothèque',
			'tc.groupe.espace.bibliothequeVoirTout' => 'Voir tout',
			'tc.groupe.espace.progression' => 'Progression',
			'tc.groupe.espace.roster' => 'Élèves de la Classe',
			'tc.groupe.espace.reprendreLeCours' => 'Reprendre le cours',
			'tc.groupe.espace.introuvable' => 'Cette Classe ne vous est pas ouverte',
			'tc.groupe.espace.introuvableDetail' => 'Elle a peut-être été clôturée, ou elle concerne un autre profil.',
			'tc.groupe.emplacement.nonBranche' => 'Bientôt disponible',
			'tc.groupe.emplacement.nonBrancheDetail' => 'Ce contenu sera rattaché à cet espace prochainement.',
			'tc.bibliotheque.titre' => 'Bibliothèque',
			'tc.bibliotheque.rechercheIndication' => 'Titre, niveau, sourate ou page',
			'tc.bibliotheque.rechercheLibelle' => 'Rechercher un support',
			'tc.bibliotheque.effacerRecherche' => 'Tout afficher',
			'tc.bibliotheque.filtre.type' => 'Type',
			'tc.bibliotheque.filtre.disponibilite' => 'Disponibilité',
			'tc.bibliotheque.sections.continuer' => 'Continuer',
			'tc.bibliotheque.sections.pourCeGroupe' => 'Pour cette Classe',
			'tc.bibliotheque.sections.groupe' => 'Supports à afficher',
			'tc.bibliotheque.sections.recents' => 'Récents',
			'tc.bibliotheque.sections.tousLesSupports' => 'Tous les supports',
			'tc.bibliotheque.sections.resultats' => 'Résultats',
			_ => null,
		} ?? switch (path) {
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
			'tc.coran.reprise.groupeDetail' => ({required Object page}) => 'La Classe en était page ${page}',
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
			'tc.outils.trait.ardoise' => 'Ardoise d\'annotation, facultative : le cours reste lisible sans elle',
			'tc.outils.trait.effacerDernier' => 'Effacer mon dernier trait',
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
			'tc.classe.roster.videDetail' => 'Cette séance n\'a aucun élève inscrit.',
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
			'tc.classe.support.aucunDetail' => 'Ouvrez la Bibliothèque pour présenter un support à la Classe.',
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
			'tc.observation.entree.retourClasse' => 'Retour à la classe',
			'tc.observation.explication.titre' => 'Un aperçu de son apprentissage',
			'tc.observation.explication.regleUne' => ({required Object n, required Object duree}) => '${n} visite de ${duree}',
			'tc.observation.explication.regle' => ({required Object n, required Object duree}) => '${n} visites de ${duree}',
			'tc.observation.explication.regleDetail' => 'Par séance et par parent, même si plusieurs de vos enfants sont dans la classe.',
			'tc.observation.explication.ecoute' => 'Écoutez l\'enseignant et les élèves',
			'tc.observation.explication.ecouteDetail' => 'Vous entendez l\'enseignant et les élèves qui prennent la parole, y compris votre enfant.',
			'tc.observation.explication.sansMedia' => 'Sans micro ni caméra',
			'tc.observation.explication.sansMediaDetail' => 'Votre micro et votre caméra restent désactivés pour ne pas interrompre la classe.',
			'tc.observation.explication.revenir' => 'Si un autre élève récite lors de votre première visite, vous pourrez revenir plus tard pour écouter votre enfant.',
			'tc.observation.explication.ecourtee' => 'Une visite quittée avant la fin compte comme une visite entière : le temps non utilisé n\'est pas reporté.',
			'tc.observation.explication.sansIntervenir' => 'Pour préserver la concentration, vous observez sans intervenir.',
			'tc.observation.explication.informes' => 'Votre enfant et son enseignant sont informés.',
			'tc.observation.explication.observer' => 'Observer maintenant',
			'tc.observation.explication.pasMaintenant' => 'Pas maintenant',
			'tc.observation.explication.restanteUne' => ({required Object restantes, required Object max}) => '${restantes}/${max} visite restante pour cette séance',
			'tc.observation.explication.restantes' => ({required Object restantes, required Object max}) => '${restantes}/${max} visites restantes pour cette séance',
			'tc.observation.explication.aucuneRestante' => 'Aucune visite restante pour cette séance',
			'tc.observation.disponibilite.visitesEpuiseesTitre' => 'Aucune visite restante pour cette séance',
			'tc.observation.disponibilite.visitesEpuisees' => 'Vous avez utilisé vos visites. Vous pourrez observer la prochaine séance.',
			'tc.observation.disponibilite.tempsEpuiseTitre' => 'Temps d\'observation écoulé',
			'tc.observation.disponibilite.tempsEpuise' => 'Votre temps d\'observation pour cette séance est utilisé. Vous pourrez observer la prochaine séance.',
			'tc.observation.disponibilite.seanceNonCommenceeTitre' => 'La séance n\'a pas encore commencé',
			'tc.observation.disponibilite.seanceNonCommencee' => 'L\'observation s\'ouvre pendant la séance.',
			'tc.observation.disponibilite.seanceTermineeTitre' => 'La séance est terminée',
			'tc.observation.disponibilite.seanceTerminee' => 'Vous pourrez observer la prochaine séance.',
			'tc.observation.disponibilite.seanceNonTenueTitre' => 'Cette séance n\'a pas lieu',
			'tc.observation.disponibilite.seanceNonTenue' => 'Elle a été annulée, reportée ou n\'a pas été tenue.',
			'tc.observation.disponibilite.horsFenetreTitre' => 'La séance n\'est pas ouverte en ce moment',
			'tc.observation.disponibilite.horsFenetre' => 'L\'observation est possible seulement pendant la séance.',
			'tc.observation.disponibilite.desactiveeTitre' => 'Observation fermée pour cette classe',
			'tc.observation.disponibilite.desactivee' => 'L\'administration a fermé l\'observation de cette classe.',
			'tc.observation.disponibilite.lienAbsentTitre' => 'Aucun de vos enfants dans cette séance',
			'tc.observation.disponibilite.lienAbsent' => 'L\'observation est réservée aux parents des élèves de la séance.',
			'tc.observation.disponibilite.enfantAbsentTitre' => 'Votre enfant n\'est pas dans la séance',
			'tc.observation.disponibilite.enfantAbsent' => 'L\'observation s\'ouvre quand votre enfant est présent.',
			'tc.observation.disponibilite.presenceTitre' => 'Présence en cours de vérification',
			'tc.observation.disponibilite.presence' => 'L\'observation s\'ouvre dès que la présence de votre enfant est confirmée.',
			'tc.observation.disponibilite.visiteOuverteTitre' => 'Une visite est déjà ouverte',
			'tc.observation.disponibilite.visiteOuverte' => 'Une de vos visites est encore ouverte pour cette séance, sur cet appareil ou sur un autre. Elle compte parmi vos visites.',
			'tc.observation.disponibilite.fermeeTitre' => 'Observation pas encore ouverte',
			'tc.observation.disponibilite.fermee' => 'L\'observation des séances par les parents n\'est pas encore ouverte. Elle sera proposée ici dès son ouverture.',
			'tc.observation.disponibilite.reseauTitre' => 'Vérification impossible',
			'tc.observation.disponibilite.reseau' => 'La disponibilité de l\'observation n\'a pas pu être vérifiée. Aucune visite n\'a commencé.',
			'tc.observation.disponibilite.capaciteTitre' => 'Observation indisponible',
			'tc.observation.disponibilite.capacite' => 'L\'observation n\'est pas disponible pour le moment.',
			'tc.observation.connexion.titre' => 'Connexion et vérification',
			'tc.observation.connexion.phrase' => 'Vos visites restantes sont vérifiées. La visite commence dès que l\'entrée est acceptée, connexion vidéo comprise.',
			'tc.observation.connexion.enCours' => 'Connexion et vérification en cours',
			'tc.observation.connexion.prolongee' => 'Restez sur cette page : la vérification continue.',
			'tc.observation.connexion.impossibleTitre' => 'Connexion impossible',
			'tc.observation.connexion.impossible' => 'L\'entrée dans la séance n\'a pas abouti. Vérifiez votre connexion, puis réessayez : vos visites restantes seront vérifiées à nouveau.',
			'tc.observation.duree.secondeUne' => ({required Object n}) => '${n} seconde',
			'tc.observation.duree.secondes' => ({required Object n}) => '${n} secondes',
			'tc.observation.duree.minuteUne' => ({required Object n}) => '${n} minute',
			'tc.observation.duree.minutes' => ({required Object n}) => '${n} minutes',
			'tc.observation.duree.minutesSecondes' => ({required Object m, required Object s}) => '${m} min ${s} s',
			'tc.observation.refus.politiqueDesactivee' => 'L\'observation est désactivée pour cette classe.',
			'tc.observation.refus.quotaVisites' => 'Vous avez déjà utilisé vos visites pour cette séance.',
			'tc.observation.refus.tempsEpuise' => 'Votre temps d\'observation est épuisé pour cette séance.',
			'tc.observation.refus.lienTuteur' => 'Vous n\'êtes rattaché à aucun élève de cette séance.',
			'tc.observation.refus.seanceNonActive' => 'La séance n\'est pas en cours.',
			'tc.observation.refus.horsFenetre' => 'La salle n\'est pas ouverte à cette heure.',
			'tc.observation.refus.indisponible' => 'L\'observation n\'est pas disponible pour le moment.',
			'tc.observation.refus.capaciteAbsente' => 'L\'observation n\'est pas encore activée sur cette installation.',
			'tc.observation.visite.titre' => 'Observation en cours',
			'tc.observation.visite.quitter' => 'Quitter',
			'tc.observation.visite.supportIndisponible' => 'Le support partagé par l\'enseignant s\'affiche ici.',
			'tc.observation.visite.enseignant' => 'Enseignant',
			'tc.observation.visite.monEnfant' => 'Votre enfant',
			'tc.observation.visite.budgetIncertain' => 'Temps restant non confirmé par le serveur.',
			'tc.observation.visite.videoIndisponible' => 'La vidéo de la séance n\'a pas pu s\'ouvrir. Votre temps d\'observation continue de s\'écouler.',
			'tc.observation.visite.sortieNonConfirmee' => 'La fin de votre visite n\'a pas pu être confirmée. Elle sera fermée par le serveur.',
			'tc.observation.visite.restantes' => 'restantes',
			'tc.observation.visite.decompteLu' => ({required Object duree}) => 'Temps restant : ${duree}',
			'tc.observation.visite.enDirect' => 'En direct',
			'tc.observation.visite.connexion' => 'Connexion',
			'tc.observation.visite.reconnexion' => 'Reconnexion',
			'tc.observation.visite.videoCoupee' => 'Vidéo indisponible',
			'tc.observation.visite.reconnexionDetail' => 'La connexion est interrompue, reconnexion en cours. Votre temps d\'observation continue de s\'écouler.',
			'tc.observation.visite.sonRecu' => 'Son reçu',
			'tc.observation.visite.sonInterrompu' => 'Son interrompu',
			'tc.observation.visite.agrandir' => 'Agrandir',
			'tc.observation.visite.reduire' => 'Réduire',
			'tc.observation.visite.cameraFermee' => 'Caméra fermée',
			'tc.observation.visite.pasEncoreLa' => 'Pas encore dans la salle',
			'tc.observation.visite.parle' => ({required Object nom}) => '${nom} parle',
			'tc.observation.visite.quitterQuestion' => 'Quitter la visite ?',
			'tc.observation.visite.quitterConsequence' => ({required Object duree}) => 'Il vous reste ${duree}. Une visite quittée avant la fin compte comme une visite entière : le temps non utilisé n\'est pas reporté.',
			'tc.observation.visite.quitterConsequenceSansTemps' => 'Une visite quittée avant la fin compte comme une visite entière : le temps non utilisé n\'est pas reporté.',
			'tc.observation.visite.quitterConfirmer' => 'Quitter la visite',
			'tc.observation.fin.sortieVolontaire' => 'Vous avez quitté l\'observation.',
			'tc.observation.fin.quotaAtteint' => 'Votre temps d\'observation est écoulé.',
			'tc.observation.fin.seanceTerminee' => 'La séance est terminée.',
			'tc.observation.fin.revocationServeur' => 'Votre observation a été interrompue.',
			'tc.observation.fin.deconnexion' => 'La connexion a été perdue.',
			'tc.observation.resultat.premiereTerminee' => 'Votre première visite est terminée',
			'tc.observation.resultat.derniereTerminee' => 'Votre dernière visite est terminée',
			'tc.observation.resultat.terminee' => 'Votre visite est terminée',
			'tc.observation.resultat.dureeAtteinte' => 'Durée de visite atteinte',
			'tc.observation.resultat.interrompue' => 'Observation interrompue',
			'tc.observation.resultat.continuePour' => ({required Object prenom}) => 'La séance continue pour ${prenom}.',
			'tc.observation.resultat.continueSansPrenom' => 'La séance continue.',
			'tc.observation.resultat.resteUne' => ({required Object duree}) => 'Il vous reste une visite de ${duree}. Revenez plus tard pour l\'écouter.',
			'tc.observation.resultat.restent' => ({required Object n, required Object duree}) => 'Il vous reste ${n} visites de ${duree}. Revenez plus tard pour l\'écouter.',
			'tc.observation.resultat.resteUneSansDuree' => 'Il vous reste une visite. Revenez plus tard pour l\'écouter.',
			'tc.observation.resultat.restentSansDuree' => ({required Object n}) => 'Il vous reste ${n} visites. Revenez plus tard pour l\'écouter.',
			'tc.observation.resultat.aucune' => 'Vous avez utilisé vos visites pour cette séance. Vous pourrez observer la prochaine séance.',
			'tc.observation.resultat.prochaineSeance' => 'Vous pourrez observer la prochaine séance.',
			'tc.observation.resultat.verification' => 'Vérification de vos visites restantes',
			'tc.observation.resultat.inconnues' => 'Vos visites restantes n\'ont pas pu être vérifiées. Elles le seront de nouveau dans la classe.',
			'tc.observation.resultat.voirObservations' => 'Voir mes observations',
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
			'adulte.nav.accueil' => 'Accueil',
			'adulte.nav.maClasse' => 'Ma classe',
			'adulte.nav.coran' => 'Coran',
			'adulte.nav.monEspace' => 'Mon espace',
			'adulte.accueil.salutation' => ({required Object prenom}) => 'Bonjour ${prenom}',
			'adulte.accueil.prochaineSeance' => 'Prochaine séance',
			'adulte.accueil.parcours' => 'Mon parcours',
			'adulte.accueil.dernieresSeances' => 'Dernières séances',
			'adulte.accueil.ressources' => 'Ressources de la classe',
			'adulte.accueil.absence' => 'Absence',
			'adulte.accueil.aucuneClasse' => 'Aucune classe pour le moment.',
			'adulte.accueil.aucuneClasseDetail' => 'Votre prochaine séance s\'affichera ici dès que votre classe sera ouverte.',
			'adulte.maClasse.aPropos' => 'À propos de cette classe',
			'adulte.maClasse.participants' => 'Participants',
			'adulte.maClasse.vous' => ({required Object prenom}) => '${prenom} (vous)',
			'adulte.maClasse.progression' => 'Ma progression dans cette classe',
			'adulte.maClasse.aucuneClasseDetail' => 'Votre classe, ses participants et ses ressources s\'afficheront ici dès qu\'elle sera ouverte.',
			'adulte.monEspace.role' => 'Élève adulte',
			'adulte.monEspace.monCompte' => 'Mon compte',
			'adulte.monEspace.informations' => 'Mes informations',
			'adulte.monEspace.coursAcces' => 'Cours et accès',
			'adulte.monEspace.coursAccesLegende' => 'Ma classe, mes séances et mon accès',
			'adulte.monEspace.paiements' => 'Paiements',
			'adulte.monEspace.paiementsLegende' => 'Historique et reçus de mes paiements',
			'adulte.monEspace.accords' => 'Mes accords',
			'adulte.monEspace.accordsLegende' => 'Accepter, refuser ou retirer chacun de vos accords',
			'adulte.monEspace.securiteLegende' => 'Méthode et adresse de connexion',
			'adulte.monEspace.pageAccords.indisponibleTitre' => 'Vos accords ne sont pas encore consultables',
			'adulte.monEspace.pageAccords.indisponiblePhrase' => 'Accepter, refuser ou retirer chacun de vos accords n\'est pas encore possible dans l\'application. Aucun accord ne vous est demandé ici.',
			'adulte.monEspace.pageCoursAcces.indisponibleTitre' => 'Cours et accès pas encore consultables',
			'adulte.monEspace.pageCoursAcces.indisponiblePhrase' => 'Le détail de vos cours, de vos séances et de votre accès n\'est pas encore disponible dans l\'application.',
			'adulte.provisoire.coran' => 'Le Coran de votre espace élève s\'affichera ici.',
			'adulte.provisoire.forfaitFamille' => 'La page de votre forfait famille arrivera dans une prochaine étape.',
			'adulte.provisoire.ajouterMaFamille' => 'L\'ajout de votre famille arrivera dans une prochaine étape.',
			'adulte.provisoire.placeAdulte' => 'Le détail de cette place arrivera dans une prochaine étape.',
			'adulte.famille.ajouter' => 'Ajouter ma famille',
			'adulte.famille.ajouterLegende' => 'Inscrivez vos enfants et invitez un conjoint ou une conjointe à rejoindre votre forfait famille.',
			'adulte.famille.maFamille' => 'Ma famille',
			'adulte.famille.forfaitFamille' => 'Forfait famille',
			'adulte.famille.retourMonEspace' => 'Revenir à Mon espace',
			'adulte.famille.titulaire' => 'Titulaire du foyer',
			'adulte.famille.paiementsFoyer' => 'Paiements du foyer',
			'adulte.famille.place.ajouterConjointe' => 'Ajouter une conjointe',
			'adulte.famille.place.ajouterConjoint' => 'Ajouter un conjoint',
			'adulte.famille.place.inviterConjointe' => 'Invitez votre conjointe à rejoindre Rewayah avec son propre compte.',
			'adulte.famille.place.inviterConjoint' => 'Invitez votre conjoint à rejoindre Rewayah avec son propre compte.',
			'adulte.famille.place.invitationEnvoyee' => 'Invitation envoyée',
			'adulte.famille.place.maConjointe' => ({required Object prenom}) => 'Ma conjointe · ${prenom}',
			'adulte.famille.place.monConjoint' => ({required Object prenom}) => 'Mon conjoint · ${prenom}',
			'adulte.famille.place.validationEnAttente' => 'En attente de validation administrative',
			'adulte.famille.place.validationRefusee' => 'Demande refusée par l\'administration',
			'adulte.famille.place.nouvelleInvitation' => ({required Object date}) => 'Nouvelle invitation possible à partir du ${date}',
			'adulte.famille.place.envoyeeA' => ({required Object courriel}) => 'Envoyée à ${courriel}',
			'adulte.famille.place.expiree' => 'L\'invitation précédente a expiré. Vous pouvez en envoyer une nouvelle.',
			'adulte.famille.place.annulee' => 'L\'invitation a été annulée et ne peut plus être acceptée. Vous pouvez en envoyer une nouvelle.',
			'adulte.invitation.enteteElle' => 'Un compte personnel pour elle',
			'adulte.invitation.enteteLui' => 'Un compte personnel pour lui',
			'adulte.invitation.phraseElle' => 'Votre conjointe utilisera son propre compte. Elle ne pourra pas gérer votre foyer ni les profils élèves que vous avez créés.',
			'adulte.invitation.phraseLui' => 'Votre conjoint utilisera son propre compte. Il ne pourra pas gérer votre foyer ni les profils élèves que vous avez créés.',
			'adulte.invitation.prenom' => 'Prénom',
			'adulte.invitation.nom' => 'Nom',
			'adulte.invitation.nomAide' => 'Facultatif.',
			'adulte.invitation.courriel' => 'Adresse e-mail',
			'adulte.invitation.courrielAide' => 'Nous l\'utiliserons seulement pour lui envoyer cette invitation.',
			'adulte.invitation.prenomRequis' => 'Indiquez son prénom.',
			'adulte.invitation.courrielRequis' => 'Indiquez son adresse e-mail.',
			'adulte.invitation.courrielInvalide' => 'Vérifiez l\'adresse e-mail : elle doit ressembler à nom@exemple.com.',
			'adulte.invitation.verifier' => 'Vérifier l\'invitation',
			'adulte.invitation.verifierTitre' => 'Vérifier et envoyer',
			'adulte.invitation.verifierPhrase' => 'Relisez ces informations. L\'invitation partira à cette adresse.',
			'adulte.invitation.nonRenseigne' => 'Non renseigné',
			'adulte.invitation.modifier' => 'Modifier',
			'adulte.invitation.envoyer' => 'Envoyer l\'invitation',
			'adulte.invitation.horsLigne' => 'Vous êtes hors ligne. L\'invitation pourra partir quand la connexion reviendra.',
			'adulte.invitation.echecTitre' => 'L\'invitation n\'est pas partie',
			'adulte.invitation.echecPhrase' => 'La connexion a été interrompue. Vos informations sont conservées : vous pouvez réessayer.',
			'adulte.invitation.refusTitre' => 'Cette invitation ne peut pas être envoyée',
			'adulte.invitation.refusPhrase' => 'Revenez à Ma famille pour voir l\'état de la place.',
			'adulte.invitation.envoyeeTitre' => 'Invitation envoyée',
			'adulte.invitation.envoyeePhrase' => ({required Object courriel}) => 'L\'invitation est partie vers ${courriel}.',
			'adulte.invitation.revenirMaFamille' => 'Revenir à Ma famille',
			'adulte.invitation.detailPhrase' => 'L\'invitation attend sa réponse. Vous pouvez l\'annuler tant qu\'elle n\'a pas été acceptée.',
			'adulte.invitation.annuler' => 'Annuler l\'invitation',
			'adulte.invitation.annulerQuestion' => ({required Object prenom}) => 'Annuler l\'invitation de ${prenom} ?',
			'adulte.invitation.annulerQuestionSansPrenom' => 'Annuler cette invitation ?',
			'adulte.invitation.annulerHorsLigne' => 'Vous êtes hors ligne. L\'invitation pourra être annulée quand la connexion reviendra.',
			'adulte.invitation.annulerConsequence' => 'L\'invitation ne pourra plus être acceptée. Vous pourrez en envoyer une nouvelle quand vous le souhaitez.',
			'adulte.invitation.garder' => 'Garder l\'invitation',
			'adulte.invitation.annulationEchecTitre' => 'L\'invitation n\'a pas été annulée',
			'adulte.invitation.annulationEchecPhrase' => 'La connexion a été interrompue. L\'invitation est toujours envoyée : vous pouvez réessayer.',
			'adulte.demo.titre' => 'Démonstration de l\'élève adulte',
			'adulte.demo.mention' => 'Les données sont fictives et rien n\'est envoyé.',
			'adulte.demo.intro' => 'Choisissez un écran, puis une situation du foyer Diallo.',
			'adulte.demo.ecrans' => 'Les écrans',
			'adulte.demo.situations' => 'Les situations du foyer',
			'adulte.demo.variantes' => 'Les variantes',
			'adulte.demo.titulaireFemme' => 'La titulaire est une femme, son conjoint est le second adulte.',
			'adulte.demo.vueConjointe' => 'Mon espace vu par la conjointe, second adulte du foyer.',
			'adulte.demo.vueConjoint' => 'Mon espace vu par le conjoint, second adulte du foyer.',
			'adulte.demo.etats.adulteSeul' => 'L\'adulte est seul, sans foyer.',
			'adulte.demo.etats.titulaireSansConjoint' => 'Le foyer n\'a pas de second adulte.',
			'adulte.demo.etats.invitationEnAttente' => 'L\'invitation du second adulte est en attente.',
			_ => null,
		} ?? switch (path) {
			'adulte.demo.etats.invitationExpiree' => 'L\'invitation du second adulte a expiré.',
			'adulte.demo.etats.invitationAnnulee' => 'L\'invitation du second adulte a été annulée.',
			'adulte.demo.etats.conjointActif' => 'Le second adulte fait partie du foyer.',
			'adulte.demo.etats.conjointQuitte' => 'Le second adulte a quitté le foyer.',
			'adulte.demo.etats.conjointRetire' => 'Le second adulte a été retiré du foyer.',
			'adulte.demo.etats.delai60' => 'Un délai de 60 jours est en cours.',
			'adulte.demo.etats.nouvelleDemande' => 'Une nouvelle invitation est possible après le délai de 60 jours.',
			'adulte.demo.etats.validationEnAttente' => 'La validation administrative est en attente.',
			'adulte.demo.etats.validationRefusee' => 'La validation administrative a été refusée.',
			'adulte.demo.etats.secondDepart' => 'Le second adulte est parti pour la deuxième fois.',
			'adulte.demo.etats.delai120' => 'Un délai de 120 jours est en cours.',
			'adulte.demo.etats.departsSuivants' => 'Après le troisième départ, le délai reste de 120 jours.',
			'adulte.demo.etats.repriseDemandee' => 'Une demande de reprise du foyer a été déposée.',
			'adulte.demo.etats.repriseRefuseeParTitulaire' => 'La demande de reprise a été refusée par le titulaire.',
			'adulte.demo.etats.repriseSansReponse' => 'Après 30 jours sans réponse, la demande attend l\'administration.',
			'adulte.demo.etats.repriseValidee' => 'La reprise du foyer a été validée.',
			'adulte.demo.etats.repriseRefusee' => 'La reprise du foyer a été refusée.',
			'adulte.demo.etats.dejaDansUnAutreFoyer' => 'L\'adulte invité fait déjà partie d\'un autre foyer.',
			'adulte.demo.etats.erreurReseau' => 'Le réseau a coupé pendant une action.',
			'adulte.demo.etats.doubleSoumission' => 'La même action a été envoyée deux fois.',
			'adulte.demo.etats.notificationDansLApplication' => 'La notification n\'a pas pu partir sur le téléphone, elle reste visible dans l\'application.',
			'adulte.demo.etats.emancipation' => 'Un élève devenu adulte garde toutes ses données.',
			_ => null,
		};
	}
}
