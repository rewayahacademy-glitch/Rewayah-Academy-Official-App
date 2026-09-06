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
