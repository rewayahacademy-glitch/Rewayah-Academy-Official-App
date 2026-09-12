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
	late final Traductions$attente$fr attente = Traductions$attente$fr.internal(_root);
	late final Traductions$connexion$fr connexion = Traductions$connexion$fr.internal(_root);
	late final Traductions$inscription$fr inscription = Traductions$inscription$fr.internal(_root);
	late final Traductions$contrat$fr contrat = Traductions$contrat$fr.internal(_root);
	late final Traductions$accuse$fr accuse = Traductions$accuse$fr.internal(_root);
	late final Traductions$kyc$fr kyc = Traductions$kyc$fr.internal(_root);
	late final Traductions$appareils$fr appareils = Traductions$appareils$fr.internal(_root);
	late final Traductions$enfant$fr enfant = Traductions$enfant$fr.internal(_root);
	late final Traductions$disponibilites$fr disponibilites = Traductions$disponibilites$fr.internal(_root);
	late final Traductions$creneaux$fr creneaux = Traductions$creneaux$fr.internal(_root);
	late final Traductions$priere$fr priere = Traductions$priere$fr.internal(_root);
	late final Traductions$eleveConnexion$fr eleveConnexion = Traductions$eleveConnexion$fr.internal(_root);
	late final Traductions$dossiers$fr dossiers = Traductions$dossiers$fr.internal(_root);
	late final Traductions$admin$fr admin = Traductions$admin$fr.internal(_root);
	late final Traductions$vide$fr vide = Traductions$vide$fr.internal(_root);
	late final Traductions$pin$fr pin = Traductions$pin$fr.internal(_root);
	late final Traductions$choix$fr choix = Traductions$choix$fr.internal(_root);
	late final Traductions$avatar$fr avatar = Traductions$avatar$fr.internal(_root);
	late final Traductions$nav$fr nav = Traductions$nav$fr.internal(_root);
	late final Traductions$eleve$fr eleve = Traductions$eleve$fr.internal(_root);
	late final Traductions$tuteur$fr tuteur = Traductions$tuteur$fr.internal(_root);
	late final Traductions$enseignant$fr enseignant = Traductions$enseignant$fr.internal(_root);
	late final Traductions$aConstruire$fr aConstruire = Traductions$aConstruire$fr.internal(_root);
	late final Traductions$galerie$fr galerie = Traductions$galerie$fr.internal(_root);
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

	/// fr: 'Participants'
	String get participants => 'Participants';

	/// fr: 'Enseignant'
	String get roleEnseignant => 'Enseignant';

	/// fr: 'Élève'
	String get roleEleve => 'Élève';

	/// fr: 'Tuteur, en observation'
	String get roleTuteur => 'Tuteur, en observation';

	/// fr: 'Vous assistez au cours. Vous n'êtes pas entendu.'
	String get observationMuette => 'Vous assistez au cours. Vous n\'êtes pas entendu.';

	/// fr: 'Visite de contrôle. Vous n'êtes ni vu ni entendu, et votre passage est inscrit au journal.'
	String get bandeauControle => 'Visite de contrôle. Vous n\'êtes ni vu ni entendu, et votre passage est inscrit au journal.';
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

	/// fr: '{n} dossier(s) en attente'
	String restants({required Object n}) => '${n} dossier(s) en attente';

	/// fr: 'Déposé le {date}'
	String deposeLe({required Object date}) => 'Déposé le ${date}';

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
	late final Traductions$admin$journal$fr journal = Traductions$admin$journal$fr.internal(_root);
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
}

// Path: eleve
class Traductions$eleve$fr {
	Traductions$eleve$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations
	late final Traductions$eleve$accueil$fr accueil = Traductions$eleve$accueil$fr.internal(_root);
}

// Path: tuteur
class Traductions$tuteur$fr {
	Traductions$tuteur$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations
	late final Traductions$tuteur$accueil$fr accueil = Traductions$tuteur$accueil$fr.internal(_root);
	late final Traductions$tuteur$reglages$fr reglages = Traductions$tuteur$reglages$fr.internal(_root);
}

// Path: enseignant
class Traductions$enseignant$fr {
	Traductions$enseignant$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations
	late final Traductions$enseignant$journee$fr journee = Traductions$enseignant$journee$fr.internal(_root);
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

	/// fr: '{n} demande(s) en attente'
	String restantes({required Object n}) => '${n} demande(s) en attente';

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

	/// fr: '{nombre} entrée(s) ne correspondent plus à leur empreinte, à partir de la n° {entree}. Quelque chose a touché la base en dehors de l'application.'
	String chaineRompueDetail({required Object nombre, required Object entree}) => '${nombre} entrée(s) ne correspondent plus à leur empreinte, à partir de la n° ${entree}. Quelque chose a touché la base en dehors de l\'application.';

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

// Path: tuteur.accueil
class Traductions$tuteur$accueil$fr {
	Traductions$tuteur$accueil$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Votre foyer'
	String get titre => 'Votre foyer';

	/// fr: 'Assister'
	String get assister => 'Assister';

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

	/// fr: 'Cours en cours'
	String get coursEnCours => 'Cours en cours';

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

	/// fr: '{nombre} élèves attendent sur vos heures'
	String elevesEnAttente({required Object nombre}) => '${nombre} élèves attendent sur vos heures';

	/// fr: '1 élève attend sur vos heures'
	String get unEleveEnAttente => '1 élève attend sur vos heures';

	/// fr: 'Aucun élève en attente sur vos heures'
	String get aucunEleveEnAttente => 'Aucun élève en attente sur vos heures';

	/// fr: 'Voir mes créneaux'
	String get voirCreneaux => 'Voir mes créneaux';

	/// fr: 'La journée n'a pas pu être lue en entier. Réessayez dans un instant.'
	String get erreur => 'La journée n\'a pas pu être lue en entier. Réessayez dans un instant.';
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
			'salle.participants' => 'Participants',
			'salle.roleEnseignant' => 'Enseignant',
			'salle.roleEleve' => 'Élève',
			'salle.roleTuteur' => 'Tuteur, en observation',
			'salle.observationMuette' => 'Vous assistez au cours. Vous n\'êtes pas entendu.',
			'salle.bandeauControle' => 'Visite de contrôle. Vous n\'êtes ni vu ni entendu, et votre passage est inscrit au journal.',
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
			'connexion.envoyerLien' => 'Recevoir le lien',
			'connexion.avecGoogle' => 'Continuer avec Google',
			'connexion.ou' => 'ou',
			'connexion.lienEnvoye' => 'Lien envoyé',
			'connexion.lienEnvoyeDetail' => ({required Object courriel}) => 'Ouvrez le message envoyé à ${courriel}, puis suivez le lien. Vous pouvez laisser cette page ouverte.',
			'connexion.changerAdresse' => 'Utiliser une autre adresse',
			'connexion.erreurCourriel' => 'Cette adresse ne semble pas valide.',
			'connexion.erreurEnvoi' => 'L\'envoi n\'a pas abouti. Réessayez dans un instant.',
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
			'dossiers.restants' => ({required Object n}) => '${n} dossier(s) en attente',
			'dossiers.deposeLe' => ({required Object date}) => 'Déposé le ${date}',
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
			'admin.tableau.listeErreur' => 'La liste n\'a pas pu être lue en entier. Les compteurs, eux, restent justes.',
			'admin.tableau.ligneDossier' => ({required Object prenom}) => 'Dossier d\'identité de ${prenom}',
			'admin.tableau.ligneReaffectation' => ({required Object prenom}) => 'Changement d\'enseignant pour ${prenom}',
			'admin.tableau.lignePlafond' => ({required Object prenom}) => 'Plafond d\'élèves de ${prenom}',
			'admin.tableau.ligneRegle' => ({required Object prenom}) => 'Changement de règle pour ${prenom}',
			'admin.tableau.attenteAujourdhui' => 'Déposé aujourd\'hui',
			'admin.tableau.attenteUnJour' => 'En attente depuis 1 jour',
			'admin.tableau.attenteJours' => ({required Object jours}) => 'En attente depuis ${jours} jours',
			'admin.demandes.titre' => 'Demandes et règles',
			'admin.demandes.restantes' => ({required Object n}) => '${n} demande(s) en attente',
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
			'admin.journal.titre' => 'Journal',
			'admin.journal.chaineIntacte' => 'Journal intact',
			'admin.journal.chaineIntacteDetail' => ({required Object nombre}) => '${nombre} entrées relues une à une : aucune n\'a été modifiée ni retirée depuis son écriture.',
			'admin.journal.chaineRompue' => 'Journal altéré',
			'admin.journal.chaineRompueDetail' => ({required Object nombre, required Object entree}) => '${nombre} entrée(s) ne correspondent plus à leur empreinte, à partir de la n° ${entree}. Quelque chose a touché la base en dehors de l\'application.',
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
			'admin.journal.vide' => 'Aucun événement enregistré',
			'admin.journal.videDetail' => 'Chaque lecture de dossier, chaque décision et chaque attribution viendra s\'inscrire ici.',
			'admin.journal.videFiltre' => 'Aucun événement ne correspond',
			'admin.journal.videFiltreDetail' => 'Élargissez la période, ou relâchez un filtre.',
			'admin.journal.effacerFiltres' => 'Effacer les filtres',
			'admin.journal.erreur' => 'Le journal n\'a pas pu être lu. Réessayez dans un instant.',
			'admin.journal.erreurSuite' => 'Les entrées plus anciennes n\'ont pas pu être lues.',
			'admin.journal.chargerSuite' => 'Charger les entrées plus anciennes',
			'admin.journal.fin' => 'Vous êtes remonté jusqu\'à la première entrée du journal.',
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
			'avatar.sansPhoto' => 'Pas encore de photo',
			'nav.eleve.accueil' => 'Accueil',
			'nav.eleve.coran' => 'Coran',
			'nav.eleve.suivi' => 'Suivi',
			'nav.tuteur.accueil' => 'Accueil',
			'nav.tuteur.foyer' => 'Foyer',
			'nav.tuteur.disponibilites' => 'Disponibilités',
			'nav.tuteur.reglages' => 'Réglages',
			'nav.tuteur.suivi' => 'Suivi',
			'nav.enseignant.journee' => 'Journée',
			'nav.enseignant.creneaux' => 'Créneaux',
			'nav.enseignant.profil' => 'Profil',
			'nav.controleur.planning' => 'Planning',
			'nav.admin.tableauDeBord' => 'Tableau de bord',
			'nav.admin.dossiers' => 'Dossiers',
			'nav.admin.demandes' => 'Demandes',
			'nav.admin.attribution' => 'Attribution',
			'nav.admin.journal' => 'Journal',
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
			'tuteur.accueil.titre' => 'Votre foyer',
			'tuteur.accueil.assister' => 'Assister',
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
			_ => null,
		} ?? switch (path) {
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
			'enseignant.journee.lancer' => 'Lancer le cours',
			'enseignant.journee.preflight' => 'Vérifier avant le cours',
			'enseignant.journee.titre' => 'Votre journée',
			'enseignant.journee.prochainCours' => 'Prochain cours',
			'enseignant.journee.coursEnCours' => 'Cours en cours',
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
			'enseignant.journee.elevesEnAttente' => ({required Object nombre}) => '${nombre} élèves attendent sur vos heures',
			'enseignant.journee.unEleveEnAttente' => '1 élève attend sur vos heures',
			'enseignant.journee.aucunEleveEnAttente' => 'Aucun élève en attente sur vos heures',
			'enseignant.journee.voirCreneaux' => 'Voir mes créneaux',
			'enseignant.journee.erreur' => 'La journée n\'a pas pu être lue en entier. Réessayez dans un instant.',
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
			_ => null,
		};
	}
}
