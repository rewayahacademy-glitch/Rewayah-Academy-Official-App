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
	late final Traductions$salle$fr salle = Traductions$salle$fr.internal(_root);
	late final Traductions$attente$fr attente = Traductions$attente$fr.internal(_root);
	late final Traductions$connexion$fr connexion = Traductions$connexion$fr.internal(_root);
	late final Traductions$inscription$fr inscription = Traductions$inscription$fr.internal(_root);
	late final Traductions$contrat$fr contrat = Traductions$contrat$fr.internal(_root);
	late final Traductions$accuse$fr accuse = Traductions$accuse$fr.internal(_root);
	late final Traductions$kyc$fr kyc = Traductions$kyc$fr.internal(_root);
	late final Traductions$appareils$fr appareils = Traductions$appareils$fr.internal(_root);
	late final Traductions$eleveConnexion$fr eleveConnexion = Traductions$eleveConnexion$fr.internal(_root);
	late final Traductions$dossiers$fr dossiers = Traductions$dossiers$fr.internal(_root);
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

	/// fr: 'Prochain cours'
	String get prochainCours => 'Prochain cours';

	/// fr: 'Ton cours a commencé'
	String get coursEnDirect => 'Ton cours a commencé';
}

// Path: tuteur.accueil
class Traductions$tuteur$accueil$fr {
	Traductions$tuteur$accueil$fr.internal(this._root);

	final Traductions _root; // ignore: unused_field

	// Translations

	/// fr: 'Assister'
	String get assister => 'Assister';
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
}

/// The flat map containing all translations for locale <fr>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Traductions {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
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
			'salle.bandeauPermanent' => 'Cours enregistré, visite de contrôle possible.',
			'salle.micro' => 'Micro',
			'salle.microCoupe' => 'Micro coupé',
			'salle.camera' => 'Caméra',
			'salle.cameraCoupee' => 'Caméra éteinte',
			'salle.quitter' => 'Quitter',
			'salle.ouvrirCoran' => 'Ouvrir le Coran',
			'salle.confirmerSortie' => 'Quitter le cours ?',
			'salle.expiree' => 'Cette salle n\'est plus accessible. Revenez à votre accueil pour rejoindre le prochain cours.',
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
			'nav.admin.attribution' => 'Attribution',
			'nav.admin.journal' => 'Journal',
			'eleve.accueil.rejoindre' => 'Rejoindre',
			'eleve.accueil.coran' => 'Le Coran',
			'eleve.accueil.prochainCours' => 'Prochain cours',
			'eleve.accueil.coursEnDirect' => 'Ton cours a commencé',
			'tuteur.accueil.assister' => 'Assister',
			'enseignant.journee.lancer' => 'Lancer le cours',
			'enseignant.journee.preflight' => 'Vérifier avant le cours',
			'aConstruire.titre' => 'Écran à construire',
			'aConstruire.detail' => 'Cet écran arrive à l\'étape 3.',
			'galerie.titre' => 'Galerie des composants',
			'galerie.avertissement' => 'Banc d\'essai de développement. Absent des versions de production.',
			'galerie.paires' => 'Paires de couleurs',
			'galerie.typographie' => 'Échelles typographiques',
			'galerie.polices' => 'Polices',
			'galerie.composants' => 'Composants partagés',
			'galerie.modeEnfant' => 'Mode enfant',
			'galerie.modeStandard' => 'Mode standard',
			_ => null,
		};
	}
}
