///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TraductionsEn extends Traductions with BaseTranslations<AppLocale, Traductions> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TraductionsEn({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Traductions>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	final TranslationMetadata<AppLocale, Traductions> _meta;
	@override TranslationMetadata<AppLocale, Traductions> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TraductionsEn _root = this; // ignore: unused_field

	@override 
	TraductionsEn $copyWith({TranslationMetadata<AppLocale, Traductions>? meta}) => TraductionsEn(meta: meta ?? this.$meta);

	// Translations
	@override late final _Traductions$commun$en commun = _Traductions$commun$en._(_root);
	@override late final _Traductions$attente$en attente = _Traductions$attente$en._(_root);
	@override late final _Traductions$accords$en accords = _Traductions$accords$en._(_root);
	@override late final _Traductions$connexion$en connexion = _Traductions$connexion$en._(_root);
	@override late final _Traductions$inscription$en inscription = _Traductions$inscription$en._(_root);
	@override late final _Traductions$codeConduite$en codeConduite = _Traductions$codeConduite$en._(_root);
	@override late final _Traductions$consentement$en consentement = _Traductions$consentement$en._(_root);
	@override late final _Traductions$kyc$en kyc = _Traductions$kyc$en._(_root);
	@override late final _Traductions$enfant$en enfant = _Traductions$enfant$en._(_root);
	@override late final _Traductions$foyer$en foyer = _Traductions$foyer$en._(_root);
	@override late final _Traductions$ficheEleve$en ficheEleve = _Traductions$ficheEleve$en._(_root);
	@override late final _Traductions$recrutement$en recrutement = _Traductions$recrutement$en._(_root);
	@override late final _Traductions$parcours$en parcours = _Traductions$parcours$en._(_root);
	@override late final _Traductions$nav$en nav = _Traductions$nav$en._(_root);
	@override late final _Traductions$compte$en compte = _Traductions$compte$en._(_root);
	@override late final _Traductions$historique$en historique = _Traductions$historique$en._(_root);
	@override late final _Traductions$notifications$en notifications = _Traductions$notifications$en._(_root);
	@override late final _Traductions$eleve$en eleve = _Traductions$eleve$en._(_root);
	@override late final _Traductions$tuteur$en tuteur = _Traductions$tuteur$en._(_root);
	@override late final _Traductions$classe$en classe = _Traductions$classe$en._(_root);
	@override late final _Traductions$suiviFamille$en suiviFamille = _Traductions$suiviFamille$en._(_root);
	@override late final _Traductions$suiviDemandes$en suiviDemandes = _Traductions$suiviDemandes$en._(_root);
	@override late final _Traductions$juridique$en juridique = _Traductions$juridique$en._(_root);
	@override late final _Traductions$accueilInscrits$en accueilInscrits = _Traductions$accueilInscrits$en._(_root);
	@override late final _Traductions$accueilInvite$en accueilInvite = _Traductions$accueilInvite$en._(_root);
	@override late final _Traductions$payUx$en payUx = _Traductions$payUx$en._(_root);
	@override late final _Traductions$accueilHoraire$en accueilHoraire = _Traductions$accueilHoraire$en._(_root);
	@override late final _Traductions$suiviAttente$en suiviAttente = _Traductions$suiviAttente$en._(_root);
}

// Path: commun
class _Traductions$commun$en extends Traductions$commun$fr {
	_Traductions$commun$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$commun$langue$en langue = _Traductions$commun$langue$en._(_root);
	@override late final _Traductions$commun$formats$en formats = _Traductions$commun$formats$en._(_root);
	@override late final _Traductions$commun$roles$en roles = _Traductions$commun$roles$en._(_root);
	@override late final _Traductions$commun$classeDistincte$en classeDistincte = _Traductions$commun$classeDistincte$en._(_root);
	@override String get continuer => 'Continue';
	@override String get retour => 'Back';
	@override String get valider => 'Confirm';
	@override String get annuler => 'Cancel';
	@override String get fermer => 'Close';
	@override String get erreurElement => 'This item could not be displayed. Try again in a moment.';
	@override String get reessayer => 'Try again';
	@override String get chargement => 'Loading';
	@override String get reussite => 'Done.';
	@override late final _Traductions$commun$etape$en etape = _Traductions$commun$etape$en._(_root);
	@override late final _Traductions$commun$choix$en choix = _Traductions$commun$choix$en._(_root);
	@override late final _Traductions$commun$champDate$en champDate = _Traductions$commun$champDate$en._(_root);
	@override late final _Traductions$commun$etats$en etats = _Traductions$commun$etats$en._(_root);
	@override late final _Traductions$commun$entete$en entete = _Traductions$commun$entete$en._(_root);
	@override late final _Traductions$commun$selecteurProfils$en selecteurProfils = _Traductions$commun$selecteurProfils$en._(_root);
	@override late final _Traductions$commun$theme$en theme = _Traductions$commun$theme$en._(_root);
	@override late final _Traductions$commun$demarrage$en demarrage = _Traductions$commun$demarrage$en._(_root);
	@override late final _Traductions$commun$fuseaux$en fuseaux = _Traductions$commun$fuseaux$en._(_root);
	@override late final _Traductions$commun$dates$en dates = _Traductions$commun$dates$en._(_root);
	@override late final _Traductions$commun$sections$en sections = _Traductions$commun$sections$en._(_root);
	@override late final _Traductions$commun$recherche$en recherche = _Traductions$commun$recherche$en._(_root);
}

// Path: attente
class _Traductions$attente$en extends Traductions$attente$fr {
	_Traductions$attente$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Your file is being reviewed';
	@override String get dossierIncomplet => 'Some documents are still missing from your file.';
	@override String get enVerification => 'We are reviewing your file.';
	@override String get refuse => 'File refused';
	@override String get suspendu => 'Your account is suspended.';
	@override String get contacterAcademie => 'Contact the academy';
	@override String deposeLe({required Object date}) => 'Submitted on ${date}';
	@override String get delai => 'Review usually takes less than 48 hours.';
	@override String get aFournir => 'To provide';
	@override String get pieceIdentite => 'An ID document';
	@override String get signatureContrat => 'Signing the contract';
	@override String get carteAccuse => 'What you need to know';
	@override String get deposerLaPiece => 'Submit my document';
	@override String get signerLeContrat => 'Read and sign';
	@override String get lireLaCarte => 'Read';
	@override String get toutEstDepose => 'Everything has been submitted.';
	@override String get corriger => 'Correct';
	@override String get correctionImpossible => 'This file cannot be edited for now.';
	@override String get actualiser => 'Reload the file status';
	@override String get suspenduDetail => 'You can contact the academy to find out what to do.';
	@override String get copieDonnees => 'To get a copy of your data, write to the academy.';
	@override String get seDeconnecter => 'Sign out';
	@override String get titreDossier => 'Your file';
	@override String get titreCompte => 'Your account';
	@override String get accordsARelire => 'You still have our terms to read and accept.';
	@override String get demandeTitre => 'Your request is in progress';
	@override String get demandeMessage => 'The management reads every request before opening an account.';
	@override String get demandeDetail => 'You have nothing to send. We write to your email address as soon as the management has replied.';
	@override String demandePour({required Object liste}) => 'Your request concerns: ${liste}.';
	@override String get demandeRefuseeTitre => 'We cannot proceed';
	@override String get demandeRefuseeMessage => 'The management has read your request and cannot proceed with it for now.';
	@override String get demandeRefuseeDetail => 'The email we sent you gives the reason. You can reply to it with any question.';
	@override String get precisionsTitre => 'We are missing some information';
	@override String get precisionsMessage => 'To review your request, the management needs a clarification:';
	@override String get precisionsReponse => 'Simply reply to the email we sent you. The management resumes your request as soon as you reply.';
	@override String get actualiserCompte => 'Reload';
	@override String get lireEtAccepter => 'Read and accept our terms';
	@override String get nosConditions => 'Our terms, to read and accept';
	@override String get etatAAccepter => 'To accept';
	@override String reste({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'One item remains to be provided.',
		other: '${n} items remain to be provided.',
	);
	@override String get etatAFournir => 'To provide';
	@override String prochaineEtape({required Object etape}) => 'Next step: ${etape}';
	@override String refuseDetail({required Object element}) => 'Item to redo: ${element}.';
	@override String get refuseSansElement => 'You can contact the academy to find out what to do.';
	@override String get illisible => 'Your account status cannot be displayed for now.';
	@override String get horsLigne => 'Your account status will be displayed as soon as the network is back.';
}

// Path: accords
class _Traductions$accords$en extends Traductions$accords$fr {
	_Traductions$accords$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Our terms';
	@override String get intro => 'Read each text, then tick the box that follows it. The "Next" button becomes active when everything is ticked.';
	@override String get caseManquante => 'Tick this box to continue.';
	@override String get introCases => 'Read each text, then tick the box that follows it.';
	@override String get lireJusquEnBas => 'Read to the bottom to confirm.';
	@override String get caseSavoir => 'I have read and understood what I need to know.';
	@override String get sectionContrat => 'Your contract';
	@override String get caseContrat => 'I have read and accept my contract, including review visits.';
	@override String reste({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'One agreement remains to be ticked.',
		other: '${n} agreements remain to be ticked.',
	);
	@override String get toutCoche => 'Everything is ticked.';
	@override String get suivant => 'Next';
	@override String get dejaAcceptes => 'Your agreements are already saved.';
	@override String get cadreNonPublie => 'Sending your application will be possible once the religious and educational framework is published.';
}

// Path: connexion
class _Traductions$connexion$en extends Traductions$connexion$fr {
	_Traductions$connexion$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Sign in';
	@override String get sessionTermineeTitre => 'You have been signed out';
	@override String get sessionTermineePhrase => 'Your session has ended: this account, or another one, signed in elsewhere, in this browser or on another device. Sign in again here. To use two accounts at the same time, open the second one in a private window or on another device.';
	@override String get lienAilleursTitre => 'This link was opened on another device';
	@override String get lienAilleursPhrase => 'A sign-in link only opens in the browser where you requested it. Open it on that device: if you started signing up, your answers are saved there. Otherwise, request a new link here.';
	@override String get modeConnexion => 'I already have an account';
	@override String get modeCreation => 'Create an account';
	@override String get titreCreation => 'Create your account';
	@override String get introCreation => 'Enter your address: we send you a link that creates your account. No password to choose.';
	@override String get envoyerLienCreation => 'Get the sign-up link';
	@override String get intro => 'We send you a link by email. No password to remember, so none to lose.';
	@override String get courriel => 'Your email address';
	@override String get courrielIndice => 'you@example.com';
	@override String get motDePasseDemo => 'Demo password';
	@override String get envoyerLien => 'Get the link';
	@override String get entrerDemo => 'Enter the demo';
	@override String get introDemo => 'Demo mode: no link will be sent. You go straight in, without email.';
	@override String get essayerDemo => 'Try the demo';
	@override String get avecGoogle => 'Continue with Google';
	@override String get ou => 'or';
	@override String get lienEnvoye => 'Link sent';
	@override String lienEnvoyeDetail({required Object courriel}) => 'Open the message sent to ${courriel}, then follow the link. You can leave this page open.';
	@override String get changerAdresse => 'Use another address';
	@override String get erreurCourriel => 'This address does not look valid.';
	@override String get erreurEnvoi => 'The message was not sent. Try again in a moment.';
	@override String get erreurMotDePasse => 'Wrong address or password. Check both, or clear the password to receive a link by email.';
	@override String get appareilEleveAide => 'Are you a guardian preparing a student\'s device?';
	@override String get appareilEleve => 'Connect a student\'s device';
	@override String get renvoyer => 'Resend the link';
	@override String renvoye({required Object courriel}) => 'A new link was sent to ${courriel}. Use the one in the most recent message.';
	@override String get inscriptionFermee => 'Sign-ups are currently by invitation only. Did you apply to teach? You will receive a personal email from us: there is nothing for you to do. Are you a family? Sign-ups reopen soon.';
	@override late final _Traductions$connexion$invitationFoyer$en invitationFoyer = _Traductions$connexion$invitationFoyer$en._(_root);
	@override String get erreurTropTot => 'A link has just been sent. Wait a moment before requesting another.';
	@override String get horsLigne => 'The link cannot be sent right now. Try again when the connection is back.';
	@override late final _Traductions$connexion$controle$en controle = _Traductions$connexion$controle$en._(_root);
	@override String get probleme => 'Link expired or never received?';
	@override late final _Traductions$connexion$recuperation$en recuperation = _Traductions$connexion$recuperation$en._(_root);
	@override late final _Traductions$connexion$feuilleAppareil$en feuilleAppareil = _Traductions$connexion$feuilleAppareil$en._(_root);
}

// Path: inscription
class _Traductions$inscription$en extends Traductions$inscription$fr {
	_Traductions$inscription$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$inscription$questionnaire$en questionnaire = _Traductions$inscription$questionnaire$en._(_root);
	@override String get titre => 'Create your account';
	@override String etapeSur({required Object n, required Object total}) => 'Step ${n} of ${total}';
	@override String tempsRestant({required Object minutes}) => 'About ${minutes} min';
	@override String get roleQuestion => 'Are you signing up as a parent or as a teacher?';
	@override String get roleTuteur => 'Parent or guardian';
	@override String get roleEleveAdulte => 'Adult student, for myself';
	@override String get roleEnseignant => 'Teacher';
	@override String get autreAide => 'Write to the academy and we will create your access. This page cannot do it for you.';
	@override String get identiteQuestion => 'What is your name?';
	@override String get identiteQuestionFamille => 'What is your own name, as the parent or guardian?';
	@override String get identiteAideFamille => 'Not the child\'s: their student profile will have its own name.';
	@override String get identiteRaison => 'This name must match your ID document.';
	@override String get prenom => 'First name';
	@override String get nom => 'Last name';
	@override String get genreQuestion => 'You are';
	@override String get genreHomme => 'A man';
	@override String get genreFemme => 'A woman';
	@override String get genreRaison => 'This answer is only used to have your ID document handled by a staff member of the same gender.';
	@override String get genreHommeExplication => 'If you take classes, the academy takes this into account when forming classes and choosing the teacher.';
	@override String get genreFemmeExplication => 'If you take classes, the academy takes this into account when forming classes and choosing the teacher.';
	@override String get genreHommeEnseignant => 'Your ID document will be reviewed by a man on the team.';
	@override String get genreFemmeEnseignant => 'Your ID document will be reviewed by a woman on the team.';
	@override String get recapitulatif => 'Before you continue';
	@override String get creer => 'Create my account';
	@override String get erreur => 'The account could not be created. Try again in a moment.';
	@override String get champRequis => 'This answer is needed to continue.';
	@override String etapeCourte({required Object n, required Object total}) => '${n} of ${total}';
	@override String get retourEtape => 'Back to the previous step';
	@override String get seDeconnecter => 'Sign out';
	@override String get modifier => 'Edit';
	@override String get reessayer => 'Try again';
	@override String get erreurActualisation => 'Your account is created, but the sign-in could not be refreshed. Try again, or sign out and sign back in.';
	@override String get erreurInvitation => 'Your invitation code could not be used: it has expired, has already been used, or does not match your address. Ask the management for a new code, then enter it again.';
	@override late final _Traductions$inscription$usage$en usage = _Traductions$inscription$usage$en._(_root);
	@override late final _Traductions$inscription$recap$en recap = _Traductions$inscription$recap$en._(_root);
	@override late final _Traductions$inscription$telephone$en telephone = _Traductions$inscription$telephone$en._(_root);
	@override late final _Traductions$inscription$langue$en langue = _Traductions$inscription$langue$en._(_root);
	@override late final _Traductions$inscription$confidentialite$en confidentialite = _Traductions$inscription$confidentialite$en._(_root);
	@override late final _Traductions$inscription$candidat$en candidat = _Traductions$inscription$candidat$en._(_root);
	@override late final _Traductions$inscription$nomLatin$en nomLatin = _Traductions$inscription$nomLatin$en._(_root);
}

// Path: codeConduite
class _Traductions$codeConduite$en extends Traductions$codeConduite$fr {
	_Traductions$codeConduite$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Teacher code of conduct';
	@override String get lien => 'Read the code of conduct';
	@override String get intro => 'These rules protect students, and they protect you. Read them, then accept.';
	@override List<String> get regles => [
		'Your classes are held in the academy\'s room. A class may be audio-recorded, and a person in charge of review may follow it live without telling you when. A parent may also attend the class for a limited time, to see how the session goes: you are informed. You accept these measures: they protect children and they protect you.',
		'You see your students\' first names. Their full name is not shown, to keep the screen short. You never see a family\'s contact details: no email, no phone.',
		'What you know about a child stays with the academy, to protect their personal data. You do not make it public and you do not show it to other families.',
		'You never contact a student or their family privately, outside the app.',
		'In front of the camera, your dress is appropriate and the background behind you is neutral and calm.',
		'You are on time. You open the room before the class starts.',
		'You are also callers to the faith: be exemplary in your words and gestures, and patient with each student.',
		'If a child\'s safety worries you, report it right away with "Report a need", category "A child\'s safety". The management reads it first.',
		'If you refuse these rules, the academy cannot entrust students to you, because they protect children.',
	];
	@override String get caseAccord => 'I have read the code of conduct and I accept it.';
	@override String get accepter => 'I accept the code of conduct';
	@override String accepteLe({required Object date, required Object version}) => 'Accepted on ${date}. Version ${version}.';
	@override String get erreur => 'Your agreement was not saved. Try again in a moment.';
	@override String get erreurLecture => 'We could not load your agreements. Try again.';
	@override String get aAccepter => 'To accept';
}

// Path: consentement
class _Traductions$consentement$en extends Traductions$consentement$fr {
	_Traductions$consentement$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Consents';
	@override late final _Traductions$consentement$texte$en texte = _Traductions$consentement$texte$en._(_root);
	@override late final _Traductions$consentement$comment$en comment = _Traductions$consentement$comment$en._(_root);
	@override late final _Traductions$consentement$compte$en compte = _Traductions$consentement$compte$en._(_root);
}

// Path: kyc
class _Traductions$kyc$en extends Traductions$kyc$fr {
	_Traductions$kyc$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Your ID document';
	@override String get intro => 'Photograph the side or page that shows your photo and your name. A readable photo is enough. It is kept for the time of the check, then deleted.';
	@override String get confidentialite => 'Your ID document is submitted as it is: it is never public, only the management views it, and it is required by child protection regulations.';
	@override String get typeQuestion => 'Which document are you submitting?';
	@override String get carteIdentite => 'ID card';
	@override String get passeport => 'Passport';
	@override String get titreSejour => 'Residence permit';
	@override String get autrePiece => 'Other official document';
	@override String get explicationCarteIdentite => 'The national ID card of your country, currently valid.';
	@override String get explicationPasseport => 'Your passport, currently valid.';
	@override String get explicationTitreSejour => 'The card of the country where you live without being a citizen, currently valid.';
	@override String get explicationAutre => 'Another official document that shows your photo and your name.';
	@override String get exempleAutre => 'a driving licence or a consular card';
	@override String get choisirFichier => 'Choose the photo';
	@override String get fichierChoisi => 'Photo ready to be sent';
	@override String get envoyer => 'Send my document';
	@override String get envoiEnCours => 'Sending';
	@override String get deposee => 'Document received';
	@override String get erreur => 'The upload did not complete. Try again in a moment.';
	@override String get erreurFormat => 'This file was not accepted: only JPEG, PNG, HEIC or WebP photos and PDF files are. Choose another photo of your document.';
	@override String get erreurReseau => 'The upload did not complete: your request may not have reached Rewayah. Tap "Send my document" again in a moment.';
	@override String get contenuNonConforme => 'This file does not open as a photo or as a PDF: it may be damaged, or of another type that was renamed. Choose the photo or PDF of your ID document.';
	@override String tropVolumineux({required Object taille}) => 'This photo is larger than ${taille} MB. Retake it at a lower quality.';
	@override String get manqueType => 'First choose the document you are submitting.';
}

// Path: enfant
class _Traductions$enfant$en extends Traductions$enfant$fr {
	_Traductions$enfant$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Add a student profile';
	@override String get aucun => 'No student profile in the household';
	@override String get aucunDetail => 'First add a student profile from the Household.';
}

// Path: foyer
class _Traductions$foyer$en extends Traductions$foyer$fr {
	_Traductions$foyer$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Household';
	@override String get ajouterProfil => 'Add a student profile';
	@override String get sousTitre => 'The student profiles of your household';
	@override String get membres => 'Student profiles';
	@override late final _Traductions$foyer$vide$en vide = _Traductions$foyer$vide$en._(_root);
	@override late final _Traductions$foyer$membre$en membre = _Traductions$foyer$membre$en._(_root);
	@override late final _Traductions$foyer$ajout$en ajout = _Traductions$foyer$ajout$en._(_root);
}

// Path: ficheEleve
class _Traductions$ficheEleve$en extends Traductions$ficheEleve$fr {
	_Traductions$ficheEleve$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get sansDonnees => 'This student\'s profile could not be loaded';
	@override String get titreRepli => 'Student profile';
	@override String get parametres => 'Student settings';
	@override String get appareilsGroupe => 'Devices';
	@override late final _Traductions$ficheEleve$supprimer$en supprimer = _Traductions$ficheEleve$supprimer$en._(_root);
	@override late final _Traductions$ficheEleve$introuvable$en introuvable = _Traductions$ficheEleve$introuvable$en._(_root);
	@override late final _Traductions$ficheEleve$lignes$en lignes = _Traductions$ficheEleve$lignes$en._(_root);
	@override late final _Traductions$ficheEleve$informations$en informations = _Traductions$ficheEleve$informations$en._(_root);
	@override late final _Traductions$ficheEleve$inscription$en inscription = _Traductions$ficheEleve$inscription$en._(_root);
	@override late final _Traductions$ficheEleve$interface$en interface = _Traductions$ficheEleve$interface$en._(_root);
	@override late final _Traductions$ficheEleve$camera$en camera = _Traductions$ficheEleve$camera$en._(_root);
	@override late final _Traductions$ficheEleve$acces$en acces = _Traductions$ficheEleve$acces$en._(_root);
	@override late final _Traductions$ficheEleve$couleur$en couleur = _Traductions$ficheEleve$couleur$en._(_root);
	@override late final _Traductions$ficheEleve$filAriane$en filAriane = _Traductions$ficheEleve$filAriane$en._(_root);
	@override late final _Traductions$ficheEleve$onglets$en onglets = _Traductions$ficheEleve$onglets$en._(_root);
	@override late final _Traductions$ficheEleve$finances$en finances = _Traductions$ficheEleve$finances$en._(_root);
	@override late final _Traductions$ficheEleve$mouvements$en mouvements = _Traductions$ficheEleve$mouvements$en._(_root);
}

// Path: recrutement
class _Traductions$recrutement$en extends Traductions$recrutement$fr {
	_Traductions$recrutement$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$recrutement$nomLatin$en nomLatin = _Traductions$recrutement$nomLatin$en._(_root);
	@override late final _Traductions$recrutement$candidat$en candidat = _Traductions$recrutement$candidat$en._(_root);
	@override late final _Traductions$recrutement$signature$en signature = _Traductions$recrutement$signature$en._(_root);
	@override late final _Traductions$recrutement$cadre$en cadre = _Traductions$recrutement$cadre$en._(_root);
	@override late final _Traductions$recrutement$portail$en portail = _Traductions$recrutement$portail$en._(_root);
	@override late final _Traductions$recrutement$entretien$en entretien = _Traductions$recrutement$entretien$en._(_root);
	@override late final _Traductions$recrutement$questionnaire$en questionnaire = _Traductions$recrutement$questionnaire$en._(_root);
	@override late final _Traductions$recrutement$parcours$en parcours = _Traductions$recrutement$parcours$en._(_root);
}

// Path: parcours
class _Traductions$parcours$en extends Traductions$parcours$fr {
	_Traductions$parcours$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String titre({required Object dePrenom}) => '${dePrenom}\'s journey';
	@override String get intro => 'A few questions to personalise your journey. You will then only see the schedules and options that fit your situation.';
	@override String get reprendre => 'Resume';
	@override String get commencer => 'Personalise the journey';
	@override String get modifier => 'Edit my answers';
	@override String recapNiveau({required Object niveau}) => 'Stated level: ${niveau}';
	@override String recapObjectif({required Object objectif}) => 'Goal: ${objectif}';
	@override String get erreur => 'This answer could not be saved. Try again.';
	@override String get chargement => 'We are preparing your options.';
	@override String pourPrenom({required Object prenom}) => 'For ${prenom}';
	@override String get retourAccueil => 'Back to home';
	@override String get retourFoyer => 'Back to the Household';
	@override String get reessayer => 'Try again';
	@override String get indisponibleTitre => 'The questionnaire is not available yet';
	@override String get indisponibleDetail => 'The academy has not opened this step yet. You have nothing to do for now: nothing is lost, and you can fill it in as soon as it opens.';
	@override String get horsLigneTitre => 'The journey could not be loaded';
	@override String get horsLigneDetail => 'You can try again when the connection is back. Your answers are saved.';
	@override String get erreurChargement => 'The questionnaire could not be displayed';
	@override String get erreurChargementDetail => 'An error occurred on our side. Try again in a moment; your answers are saved.';
	@override String get introuvableTitre => 'This student profile cannot be found';
	@override String get introuvableDetail => 'It may have been removed from the household. Go back to the Household to choose a student profile.';
	@override String finTitre({required Object prenom}) => 'Preference saved for ${prenom}';
	@override String get finDetail => 'This time slot is noted as your preference. It does not reserve a place yet.';
	@override String get finAjouterDetail => 'Does someone else in the household want to learn?';
	@override String get finAjouterProfil => 'Add a student profile';
	@override String ageQuestion({required Object prenom}) => 'How old is ${prenom}?';
	@override String get ageRaison => 'Age decides the length of sessions and the number of students per class. We do not ask for a date of birth: age in years is enough.';
	@override String get ageAide => 'Choose the age in years from the list, as when adding the profile.';
	@override String get ageSansTranche => 'No class is planned for this age for now. The academy team can guide you.';
	@override String get langueQuestion => 'In which language should the class be taught?';
	@override String get langueRaison => 'This is the language the teacher will speak during the session. It is independent of the app language, which you can change at any time in your settings.';
	@override String get lieuQuestion => 'Where are you?';
	@override String get lieuRaison => 'We only use it to show you schedules in your local time. We never ask for your exact location, and this answer does not leave your file.';
	@override String get lieuSuggere => 'Suggested from your device\'s time';
	@override String niveauQuestion({required Object prenom}) => 'Where is ${prenom} today?';
	@override String get niveauRaison => 'Your answer guides the first suggestions. It does not set the official level: the academy assigns it after a conversation with a teacher.';
	@override String get niveauDebutLettres => 'We start with the letters';
	@override String get niveauLettresAvecAide => 'Letters are recognised, reading needs help';
	@override String get niveauLectureLente => 'Reading is possible, slowly';
	@override String get niveauLectureCourante => 'The Quran is already read fluently';
	@override String get niveauMemorisationPartielle => 'Part of it is already memorised';
	@override String get objectifQuestion => 'What do you want first?';
	@override String get objectifRaison => 'You can change your goal later: it guides the teacher\'s work, it does not commit you.';
	@override String get objectifApprendreALire => 'Learn to read';
	@override String get objectifDevenirFluide => 'Read more fluently';
	@override String get objectifMemoriser => 'Memorise';
	@override String get objectifIndecis => 'I don\'t know yet';
	@override String get momentsQuestion => 'Which times of day suit you best?';
	@override String get momentsRaison => 'This answer creates no schedule and reserves nothing. It is only used to highlight, among the schedules the academy already offers, those that suit you best. You will see all the others just below.';
	@override String get momentMatin => 'Mornings';
	@override String get momentApresMidi => 'Afternoons';
	@override String get momentSoir => 'Evenings';
	@override String offresQuestion({required Object prenom}) => 'Here are the open schedules for ${prenom}';
	@override String get offresRaison => 'These schedules are shown in your local time. Choosing a schedule saves your preference: it does not reserve a place and is not yet a class.';
	@override String get offreRecommandee => 'Closest to your answers';
	@override String get offresAutres => 'Other possible schedules';
	@override String offreLangue({required Object langue}) => 'Class in ${langue}';
	@override String offreFuseau({required Object fuseau}) => 'Time shown for ${fuseau}';
	@override String get offreTraduite => 'Shown in your local time';
	@override String offreJours({required Object jours}) => '${jours}';
	@override String get offreChoisir => 'Choose this schedule';
	@override String get offreChoisie => 'Schedule chosen';
	@override String get aucuneOffre => 'No open schedule matches yet';
	@override String get aucuneOffreDetail => 'The academy opens new schedules as sign-ups come in. You can tell us what you need: it helps us decide which ones to open.';
	@override String get refusAucun => 'None of these schedules suits me';
	@override String get refusPrevenir => 'Let me know if new schedules open';
	@override String get refusEffet => 'We record that the request exists. This does not create a class, does not look for a teacher and does not promise any future schedule.';
	@override String get refusEnregistre => 'Noted. We will let you know if a matching schedule opens.';
	@override String get etatAPersonnaliser => 'Journey to personalise';
	@override String etatAPersonnaliserDetail({required Object prenom}) => 'A few questions, and we will only show what suits ${prenom}.';
	@override String get etatHoraireAChoisir => 'Schedule to choose';
	@override String etatHoraireAChoisirDetail({required Object prenom}) => 'The open schedules for ${prenom} are waiting for you.';
	@override String get etatOffreIndisponible => 'This schedule is no longer offered';
	@override String etatOffreIndisponibleDetail({required Object prenom}) => 'The schedule chosen for ${prenom} was withdrawn before a class was formed. Choose another: nothing is lost.';
	@override String get etatDiagnosticRequis => 'Preference saved';
	@override String etatDiagnosticRequisDetail({required Object dePrenom}) => 'One conversation with a teacher remains to place ${dePrenom}\'s level. The academy will offer you an appointment.';
	@override String get etatDiagnosticEnAttente => 'Appointment planned';
	@override String etatDiagnosticEnAttenteDetail({required Object dePrenom}) => 'A conversation is planned to place ${dePrenom}\'s level.';
	@override String get etatClasseEnFormation => 'Class being formed';
	@override String get etatClasseEnFormationDetailSansMinimum => 'A class starts once there are enough students. We will let you know as soon as it is confirmed.';
	@override String get etatClasseConfirmee => 'Class confirmed';
	@override String etatClasseConfirmeeDetail({required Object dePrenom}) => '${dePrenom}\'s class is formed. You will find its sessions in their space.';
	@override String get fuseauChange => 'Your location has changed since this choice';
	@override String get fuseauChangeDetail => 'The schedule is the same for the academy, but it no longer falls at the same time for you. Check that it still suits you.';
	@override String get voirHoraires => 'See the schedules';
	@override String get changerHoraire => 'Change schedule';
	@override String get renoncerMotif => 'The family changed schedule since the journey';
	@override String offreRecurrence({required num seances, required Object duree}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(seances,
		one: '${seances} session per week, ${duree} min',
		other: '${seances} sessions per week, ${duree} min',
	);
	@override String offreRecurrencePause({required num seances, required Object duree, required Object pause}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(seances,
		one: '${seances} session per week, ${duree} min including ${pause} min of break',
		other: '${seances} sessions per week, ${duree} min including ${pause} min of break',
	);
	@override String etatClasseEnFormationDetail({required num minimum}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(minimum,
		one: 'A class starts once there is ${minimum} student. We will let you know as soon as it is confirmed.',
		other: 'A class starts once there are ${minimum} students. We will let you know as soon as it is confirmed.',
	);
}

// Path: nav
class _Traductions$nav$en extends Traductions$nav$fr {
	_Traductions$nav$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$nav$eleve$en eleve = _Traductions$nav$eleve$en._(_root);
	@override late final _Traductions$nav$tuteur$en tuteur = _Traductions$nav$tuteur$en._(_root);
	@override late final _Traductions$nav$enseignant$en enseignant = _Traductions$nav$enseignant$en._(_root);
	@override late final _Traductions$nav$controleur$en controleur = _Traductions$nav$controleur$en._(_root);
	@override late final _Traductions$nav$admin$en admin = _Traductions$nav$admin$en._(_root);
	@override String get compte => 'My account';
	@override String get principale => 'Main navigation';
	@override String get motSymbole => 'Rewayah';
	@override String get logoAccueil => 'Rewayah Academy, home';
	@override String get replier => 'Collapse navigation';
	@override String get deplier => 'Expand navigation';
	@override late final _Traductions$nav$halo$en halo = _Traductions$nav$halo$en._(_root);
	@override late final _Traductions$nav$filAriane$en filAriane = _Traductions$nav$filAriane$en._(_root);
}

// Path: compte
class _Traductions$compte$en extends Traductions$compte$fr {
	_Traductions$compte$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$compte$page$en page = _Traductions$compte$page$en._(_root);
	@override String get langue => 'Language';
}

// Path: historique
class _Traductions$historique$en extends Traductions$historique$fr {
	_Traductions$historique$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'History';
	@override String get detailSeance => 'Session details';
	@override late final _Traductions$historique$segments$en segments = _Traductions$historique$segments$en._(_root);
	@override List<String> get moisCourts => [
		'Jan',
		'Feb',
		'Mar',
		'Apr',
		'May',
		'Jun',
		'Jul',
		'Aug',
		'Sep',
		'Oct',
		'Nov',
		'Dec',
	];
	@override String dateCourte({required Object mois, required Object jour, required Object annee}) => '${mois} ${jour}, ${annee}';
	@override String dateLongue({required Object jourSemaine, required Object mois, required Object jour, required Object annee}) => '${jourSemaine}, ${mois} ${jour}, ${annee}';
	@override String plage({required Object debut, required Object fin}) => '${debut} - ${fin}';
	@override late final _Traductions$historique$duree$en duree = _Traductions$historique$duree$en._(_root);
	@override String get fuseauListe => 'Times shown in this device\'s time.';
	@override String fuseauDetail({required Object decalage}) => 'Times shown in this device\'s time (UTC${decalage}).';
	@override String get classeInconnue => 'Class not available';
	@override late final _Traductions$historique$selecteur$en selecteur = _Traductions$historique$selecteur$en._(_root);
	@override late final _Traductions$historique$filtres$en filtres = _Traductions$historique$filtres$en._(_root);
	@override String get retour => 'Back to the history';
	@override late final _Traductions$historique$etat$en etat = _Traductions$historique$etat$en._(_root);
	@override String get presenceIllisible => 'Attendance could not be loaded: statuses stay unknown for now.';
	@override late final _Traductions$historique$seances$en seances = _Traductions$historique$seances$en._(_root);
	@override late final _Traductions$historique$observations$en observations = _Traductions$historique$observations$en._(_root);
	@override late final _Traductions$historique$seance$en seance = _Traductions$historique$seance$en._(_root);
	@override late final _Traductions$historique$observation$en observation = _Traductions$historique$observation$en._(_root);
	@override late final _Traductions$historique$compteRendu$en compteRendu = _Traductions$historique$compteRendu$en._(_root);
	@override String dateCourteSansAnnee({required Object mois, required Object jour}) => '${mois} ${jour}';
}

// Path: notifications
class _Traductions$notifications$en extends Traductions$notifications$fr {
	_Traductions$notifications$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$notifications$evenements$en evenements = _Traductions$notifications$evenements$en._(_root);
	@override late final _Traductions$notifications$filtres$en filtres = _Traductions$notifications$filtres$en._(_root);
	@override String get filtreVideTitre => 'No notification in this filter';
	@override String get filtreVidePhrase => 'Choose "All" to see all your notifications again.';
	@override String get voirToutes => 'See all notifications';
	@override String get sectionAFaire => 'To do';
	@override String get sectionNouvelles => 'New';
	@override String get sectionPlusAnciennes => 'Older';
	@override String get voirPlus => 'See more';
	@override String get voirPlusErreur => 'Older notifications could not be loaded.';
	@override String get toutMarquerLu => 'Mark all as read';
	@override String get ecarter => 'Dismiss';
	@override String get gesteTraiterContestation => 'Handle the dispute';
	@override String get gesteObserver => 'Observe the class';
	@override String get gesteRepondre => 'Reply';
	@override String get gestePrendreSeance => 'Take the session';
	@override String get gesteRecharger => 'Reload';
	@override String get ecartNonConfirme => 'The dismissal is not yet confirmed. Try again in a moment.';
	@override String repetitions({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} time',
		other: '${n} times',
	);
	@override String get nonLue => 'Unread';
	@override String get nonLueSemantique => 'unread';
	@override String get lectureNonConfirmee => 'Reading is not yet confirmed. Try again in a moment.';
	@override late final _Traductions$notifications$detail$en detail = _Traductions$notifications$detail$en._(_root);
	@override late final _Traductions$notifications$types$en types = _Traductions$notifications$types$en._(_root);
	@override String get titre => 'Notifications';
	@override String quand({required Object date, required Object heure}) => '${date} at ${heure}';
	@override String get indisponibleTitre => 'Notifications are not available yet';
	@override String get indisponiblePhrase => 'Session reminders and messages from the academy will appear here once they are open.';
	@override String get videTitre => 'No notifications';
	@override String get videPhrase => 'Session reminders and messages from the academy will appear here.';
	@override String ligne({required Object titre, required Object date, required Object heure}) => '${titre}, on ${date} at ${heure}';
}

// Path: eleve
class _Traductions$eleve$en extends Traductions$eleve$fr {
	_Traductions$eleve$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$eleve$accueil$en accueil = _Traductions$eleve$accueil$en._(_root);
	@override late final _Traductions$eleve$coran$en coran = _Traductions$eleve$coran$en._(_root);
	@override late final _Traductions$eleve$suivi$en suivi = _Traductions$eleve$suivi$en._(_root);
}

// Path: tuteur
class _Traductions$tuteur$en extends Traductions$tuteur$fr {
	_Traductions$tuteur$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tuteur$accueil$en accueil = _Traductions$tuteur$accueil$en._(_root);
}

// Path: classe
class _Traductions$classe$en extends Traductions$classe$fr {
	_Traductions$classe$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$classe$entree$en entree = _Traductions$classe$entree$en._(_root);
	@override String get planning => 'Schedule';
	@override String get travail => 'Before the next class';
	@override String get ressources => 'Library';
	@override String get progression => 'Progress';
	@override String get observer => 'Observe the session';
	@override String get titre => 'Class';
	@override String get historique => 'History';
	@override String sousTitre({required Object prenom, required Object enseignant}) => '${prenom} · ${enseignant}';
	@override String get indisponiblePhrase => 'The class details are not yet available here.';
	@override String get introuvableTitre => 'This class is not open to this profile';
	@override String get introuvablePhrase => 'It may have ended, or it concerns another student in the household.';
	@override String get disparue => 'This class no longer exists.';
	@override late final _Traductions$classe$seance$en seance = _Traductions$classe$seance$en._(_root);
	@override late final _Traductions$classe$observation$en observation = _Traductions$classe$observation$en._(_root);
	@override late final _Traductions$classe$pagePlanning$en pagePlanning = _Traductions$classe$pagePlanning$en._(_root);
	@override late final _Traductions$classe$pageTravail$en pageTravail = _Traductions$classe$pageTravail$en._(_root);
	@override late final _Traductions$classe$pageRessources$en pageRessources = _Traductions$classe$pageRessources$en._(_root);
	@override late final _Traductions$classe$pageProgression$en pageProgression = _Traductions$classe$pageProgression$en._(_root);
	@override late final _Traductions$classe$cartes$en cartes = _Traductions$classe$cartes$en._(_root);
}

// Path: suiviFamille
class _Traductions$suiviFamille$en extends Traductions$suiviFamille$fr {
	_Traductions$suiviFamille$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Tracking of requests';
	@override String get contexte => 'Each request moves forward step by step. You are notified at each stage.';
	@override String carteTitre({required Object dePrenom}) => '${dePrenom}\'s request';
	@override String detailTitre({required Object dePrenom}) => 'Tracking of ${dePrenom}\'s request';
	@override String etapeCourante({required Object etape}) => 'Current step: ${etape}';
	@override String get toutFait => 'All steps are complete.';
	@override String get voirSuivi => 'See the tracking';
	@override String get vide => 'No request for now.';
	@override String get faireDemande => 'Make a request';
	@override String get erreur => 'The tracking could not be loaded. Try again.';
	@override String get sansDonnees => 'your requests';
	@override String get introuvable => 'This request no longer exists or is not yours.';
	@override String get retour => 'Back to requests';
	@override String fuseau({required Object deVille}) => 'Times shown: ${deVille} time.';
	@override String prevue({required Object date, required Object heure}) => 'Planned for ${date} at ${heure}';
	@override String prevueJour({required Object date}) => 'Planned for ${date}';
	@override late final _Traductions$suiviFamille$etapes$en etapes = _Traductions$suiviFamille$etapes$en._(_root);
	@override late final _Traductions$suiviFamille$etats$en etats = _Traductions$suiviFamille$etats$en._(_root);
	@override late final _Traductions$suiviFamille$motif$en motif = _Traductions$suiviFamille$motif$en._(_root);
	@override late final _Traductions$suiviFamille$intervalle$en intervalle = _Traductions$suiviFamille$intervalle$en._(_root);
	@override late final _Traductions$suiviFamille$notification$en notification = _Traductions$suiviFamille$notification$en._(_root);
	@override String etapeSurTotal({required Object n, required Object total, required Object etape}) => 'Step ${n} of ${total}: ${etape}';
	@override late final _Traductions$suiviFamille$close$en close = _Traductions$suiviFamille$close$en._(_root);
}

// Path: suiviDemandes
class _Traductions$suiviDemandes$en extends Traductions$suiviDemandes$fr {
	_Traductions$suiviDemandes$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Tracking of time slot requests';
	@override String get contexte => 'Each request moves forward step by step. You are notified at each stage.';
	@override String carteTitre({required Object dePrenom}) => '${dePrenom}\'s time slot request';
	@override String get joursChoisis => 'Chosen days';
	@override String get heureChoisie => 'Chosen time';
	@override String joursEt({required Object debut, required Object dernier}) => '${debut} and ${dernier}';
	@override String heureFuseau({required Object heure, required Object deVille}) => '${heure}, ${deVille} time';
	@override String get creneauxChoisis => 'Chosen days and times';
	@override String jourHeure({required Object jour, required Object heure}) => '${jour} ${heure}';
	@override String get fuseauChoisi => 'Time zone';
	@override String fuseauValeur({required Object deVille}) => '${deVille} time';
	@override late final _Traductions$suiviDemandes$etapes$en etapes = _Traductions$suiviDemandes$etapes$en._(_root);
	@override late final _Traductions$suiviDemandes$etats$en etats = _Traductions$suiviDemandes$etats$en._(_root);
	@override late final _Traductions$suiviDemandes$situation$en situation = _Traductions$suiviDemandes$situation$en._(_root);
	@override late final _Traductions$suiviDemandes$prochaine$en prochaine = _Traductions$suiviDemandes$prochaine$en._(_root);
	@override String get debutCours => 'Classes start';
	@override String debutValeur({required Object date, required Object heure, required Object deVille}) => '${date} at ${heure}, ${deVille} time';
	@override String get debutAFixer => 'The date of the first class will appear here as soon as it is set.';
	@override String get enseignant => 'Teacher';
	@override String get personnaliseNotice => 'This slot will only open if other students choose it and fill the class.';
	@override late final _Traductions$suiviDemandes$close$en close = _Traductions$suiviDemandes$close$en._(_root);
	@override String get vide => 'No time slot request in progress.';
	@override String get erreur => 'The tracking of your requests could not be displayed: the reading may not have reached Rewayah. This failure only concerns the display of the tracking: it says nothing about your time slot requests. Try again in a moment.';
	@override String get sansDonnees => 'The tracking of requests could not be loaded';
	@override late final _Traductions$suiviDemandes$accueil$en accueil = _Traductions$suiviDemandes$accueil$en._(_root);
	@override late final _Traductions$suiviDemandes$notification$en notification = _Traductions$suiviDemandes$notification$en._(_root);
	@override late final _Traductions$suiviDemandes$jalon$en jalon = _Traductions$suiviDemandes$jalon$en._(_root);
	@override late final _Traductions$suiviDemandes$changement$en changement = _Traductions$suiviDemandes$changement$en._(_root);
}

// Path: juridique
class _Traductions$juridique$en extends Traductions$juridique$fr {
	_Traductions$juridique$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Legal information';
	@override String get intro => 'The texts that govern the service. They can be read without an account.';
	@override String version({required Object version, required Object date}) => 'Version ${version}, text of ${date}';
	@override String contact({required Object contact}) => 'For any question, write to ${contact}.';
	@override String get lire => 'Read';
	@override late final _Traductions$juridique$coord$en coord = _Traductions$juridique$coord$en._(_root);
	@override String aCompleter({required Object quoi}) => '[to be completed by the management: ${quoi}]';
}

// Path: accueilInscrits
class _Traductions$accueilInscrits$en extends Traductions$accueilInscrits$fr {
	_Traductions$accueilInscrits$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'We already know you';
	@override String get phrase => 'Your registration has been carried over. You do not have to enter everything again.';
	@override String get motTitre => 'A word from the management';
	@override String get elevesTitre => 'Your children already registered';
	@override String get elevesPhrase => 'Their first name is already filled in. Their age remains to be entered.';
	@override String get aJour => 'Up to date';
	@override String get aCompleter => 'To complete';
	@override String ajouterProfil({required Object dePrenom}) => 'Add ${dePrenom}\'s student profile';
	@override String get plusTard => 'You can also do it later, from the Household.';
	@override String get sansEleve => 'No student profile was carried over for your family. You can add one from the Household.';
	@override String get finirCompte => 'A few questions remain to finish your account.';
	@override String get continuer => 'Continue';
	@override String get echecTitre => 'Your registration could not be verified';
	@override String get echecPhrase => 'Probable cause: the connection to the server was interrupted (not confirmed). Try again in a moment: nothing is created twice.';
	@override String get sansDonnees => 'The check of your registration';
}

// Path: accueilInvite
class _Traductions$accueilInvite$en extends Traductions$accueilInvite$fr {
	_Traductions$accueilInvite$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Your invitation';
	@override late final _Traductions$accueilInvite$roles$en roles = _Traductions$accueilInvite$roles$en._(_root);
	@override String invitant({required Object prenom}) => 'Person inviting you to their household: ${prenom}.';
	@override String get foyerIdentite => 'Tell us who you are, then answer the invitation. Your account is only created if you accept it.';
	@override String get suite => 'Continue to create your account.';
	@override String get champsRequis => 'Enter your first name, last name and gender.';
}

// Path: payUx
class _Traductions$payUx$en extends Traductions$payUx$fr {
	_Traductions$payUx$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get repriseTitre => 'Did you leave the form without paying?';
	@override String get reprisePhrase => 'Resume the payment: a new form opens. If the payment already went through, nothing is paid twice; reload to see its status.';
	@override String get reprendre => 'Resume payment';
	@override String get rassurance => 'Payment is processed by Stripe. Your card details go directly to Stripe: Rewayah Academy does not see them and does not keep them.';
	@override String get precedentOuvertTitre => 'The payment started earlier could not be closed';
	@override String get precedentOuvertPhrase => 'Nothing is paid twice and no new form opens. Try again in a moment: if that payment has just gone through, it will appear in your payments.';
	@override String get payer => 'Pay';
	@override String get ouCarte => 'Or pay by card';
	@override String get enCours => 'Payment in progress';
	@override String get refus => 'The payment did not go through: some card information is probably incomplete or refused. Check it, then press "Pay" again. Nothing was paid.';
}

// Path: accueilHoraire
class _Traductions$accueilHoraire$en extends Traductions$accueilHoraire$fr {
	_Traductions$accueilHoraire$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get demandeTitre => 'Request saved';
	@override String demandeDetail({required Object prenom}) => 'We will let you know as soon as a time slot opens for ${prenom}.';
	@override String get erreurEnvoi => 'Your request was not confirmed. Try again in a moment.';
}

// Path: suiviAttente
class _Traductions$suiviAttente$en extends Traductions$suiviAttente$fr {
	_Traductions$suiviAttente$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Where your request stands';
	@override String get titreSimple => 'Where your request stands';
	@override late final _Traductions$suiviAttente$tu$en tu = _Traductions$suiviAttente$tu$en._(_root);
	@override String get contexte => 'The academy confirms each step. You are notified at each stage.';
	@override String get contexteSimple => 'Here is where your request stands. The academy lets you know at each step.';
	@override String pour({required Object prenom}) => 'For ${prenom}';
	@override String etapeSurTotal({required Object n, required Object total, required Object etape}) => 'Step ${n} of ${total}: ${etape}';
	@override late final _Traductions$suiviAttente$etapes$en etapes = _Traductions$suiviAttente$etapes$en._(_root);
	@override late final _Traductions$suiviAttente$etats$en etats = _Traductions$suiviAttente$etats$en._(_root);
	@override late final _Traductions$suiviAttente$dit$en dit = _Traductions$suiviAttente$dit$en._(_root);
	@override String premierCours({required Object quand}) => 'Your first class: ${quand}';
	@override String premierCoursSimple({required Object quand}) => 'Your first class: ${quand}';
	@override String premierCoursPasse({required Object quand}) => 'Your first class took place on ${quand}.';
	@override String depuis({required Object date}) => 'Since ${date}';
	@override String ensuite({required Object etape}) => 'Next: ${etape}';
	@override late final _Traductions$suiviAttente$delai$en delai = _Traductions$suiviAttente$delai$en._(_root);
	@override String changement({required Object date}) => 'The class slot changed on ${date}. You received the notice in your notifications.';
	@override late final _Traductions$suiviAttente$cloture$en cloture = _Traductions$suiviAttente$cloture$en._(_root);
	@override late final _Traductions$suiviAttente$enseignant$en enseignant = _Traductions$suiviAttente$enseignant$en._(_root);
	@override late final _Traductions$suiviAttente$vide$en vide = _Traductions$suiviAttente$vide$en._(_root);
	@override String get erreur => 'We could not read the tracking of your request. This is often caused by the connection. Try again in a moment.';
	@override String get sansDonnees => 'The tracking of your request could not be loaded';
	@override String get introuvable => 'This request no longer exists in your tracking.';
	@override String get retour => 'Back';
	@override late final _Traductions$suiviAttente$carte$en carte = _Traductions$suiviAttente$carte$en._(_root);
	@override late final _Traductions$suiviAttente$presentation$en presentation = _Traductions$suiviAttente$presentation$en._(_root);
	@override late final _Traductions$suiviAttente$mePresenter$en mePresenter = _Traductions$suiviAttente$mePresenter$en._(_root);
}

// Path: commun.langue
class _Traductions$commun$langue$en extends Traductions$commun$langue$fr {
	_Traductions$commun$langue$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get systeme => 'System';
	@override String get francais => 'Français';
	@override String get arabe => 'العربية';
	@override String get anglais => 'English';
}

// Path: commun.formats
class _Traductions$commun$formats$en extends Traductions$commun$formats$fr {
	_Traductions$commun$formats$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String dateHeure({required Object date, required Object heure}) => '${date} at ${heure}';
	@override String minutes({required Object minutes}) => '${minutes} min';
	@override String pageSur({required Object page, required Object total}) => 'Page ${page} of ${total}';
}

// Path: commun.roles
class _Traductions$commun$roles$en extends Traductions$commun$roles$fr {
	_Traductions$commun$roles$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get eleve => 'Student';
	@override String get tuteur => 'Guardian';
	@override String get enseignant => 'Teacher';
	@override String get administration => 'Administration';
	@override String get comptable => 'Accountant';
}

// Path: commun.classeDistincte
class _Traductions$commun$classeDistincte$en extends Traductions$commun$classeDistincte$fr {
	_Traductions$commun$classeDistincte$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String numero({required Object libelle, required Object numero}) => '${libelle} · no. ${numero}';
	@override String code({required Object libelle, required Object code}) => '${libelle} · ${code}';
	@override String enseignant({required Object libelle, required Object enseignant}) => '${libelle} · with ${enseignant}';
}

// Path: commun.etape
class _Traductions$commun$etape$en extends Traductions$commun$etape$fr {
	_Traductions$commun$etape$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String sur({required Object n, required Object total}) => '${n} of ${total}';
	@override String surLue({required Object n, required Object total}) => 'Step ${n} of ${total}';
}

// Path: commun.choix
class _Traductions$commun$choix$en extends Traductions$commun$choix$fr {
	_Traductions$commun$choix$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get indisponible => 'Unavailable';
}

// Path: commun.champDate
class _Traductions$commun$champDate$en extends Traductions$commun$champDate$fr {
	_Traductions$commun$champDate$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get choisir => 'Choose a date';
	@override String get aide => 'Between today and one year from now.';
}

// Path: commun.etats
class _Traductions$commun$etats$en extends Traductions$commun$etats$fr {
	_Traductions$commun$etats$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$commun$etats$recharge1$en recharge1 = _Traductions$commun$etats$recharge1$en._(_root);
	@override String get branchementServeur => 'Available once the server is connected';
	@override late final _Traductions$commun$etats$chargementProlonge$en chargementProlonge = _Traductions$commun$etats$chargementProlonge$en._(_root);
	@override late final _Traductions$commun$etats$horsLigne$en horsLigne = _Traductions$commun$etats$horsLigne$en._(_root);
	@override late final _Traductions$commun$etats$reconnexion$en reconnexion = _Traductions$commun$etats$reconnexion$en._(_root);
	@override late final _Traductions$commun$etats$echecServeur$en echecServeur = _Traductions$commun$etats$echecServeur$en._(_root);
	@override late final _Traductions$commun$etats$introuvable$en introuvable = _Traductions$commun$etats$introuvable$en._(_root);
	@override late final _Traductions$commun$etats$accesRefuse$en accesRefuse = _Traductions$commun$etats$accesRefuse$en._(_root);
	@override late final _Traductions$commun$etats$sessionExpiree$en sessionExpiree = _Traductions$commun$etats$sessionExpiree$en._(_root);
	@override late final _Traductions$commun$etats$dossierEnAttente$en dossierEnAttente = _Traductions$commun$etats$dossierEnAttente$en._(_root);
	@override late final _Traductions$commun$etats$aucunResultat$en aucunResultat = _Traductions$commun$etats$aucunResultat$en._(_root);
	@override late final _Traductions$commun$etats$permissionRefusee$en permissionRefusee = _Traductions$commun$etats$permissionRefusee$en._(_root);
	@override late final _Traductions$commun$etats$ressourceExpiree$en ressourceExpiree = _Traductions$commun$etats$ressourceExpiree$en._(_root);
	@override late final _Traductions$commun$etats$indisponible$en indisponible = _Traductions$commun$etats$indisponible$en._(_root);
	@override String get reessaisEpuises => 'Still no answer. Try again a little later.';
	@override String get horsLigneDemarrageTitre => 'Your account could not be verified';
	@override String get horsLigneDemarrage => 'It can be verified when the connection returns. Try again then.';
	@override late final _Traductions$commun$etats$actions$en actions = _Traductions$commun$etats$actions$en._(_root);
}

// Path: commun.entete
class _Traductions$commun$entete$en extends Traductions$commun$entete$fr {
	_Traductions$commun$entete$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get retour => 'Back';
	@override String get notifications => 'Notifications';
	@override String get notificationsUneNonLue => 'Notifications, one unread';
	@override String notificationsNonLues({required Object nombre}) => 'Notifications, ${nombre} unread';
}

// Path: commun.selecteurProfils
class _Traductions$commun$selecteurProfils$en extends Traductions$commun$selecteurProfils$fr {
	_Traductions$commun$selecteurProfils$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String etiquette({required Object prenom, required Object etat}) => '${prenom}, ${etat}';
	@override String get ajouter => 'Add';
	@override String get ajouterSemantique => 'Add a student profile';
}

// Path: commun.theme
class _Traductions$commun$theme$en extends Traductions$commun$theme$fr {
	_Traductions$commun$theme$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get groupe => 'Appearance';
	@override String get clair => 'Light theme';
	@override String get sombre => 'Dark theme';
}

// Path: commun.demarrage
class _Traductions$commun$demarrage$en extends Traductions$commun$demarrage$fr {
	_Traductions$commun$demarrage$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get ouverture => 'Opening Rewayah';
}

// Path: commun.fuseaux
class _Traductions$commun$fuseaux$en extends Traductions$commun$fuseaux$fr {
	_Traductions$commun$fuseaux$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get europeParis => 'Paris';
	@override String get africaConakry => 'Conakry';
	@override String get americaToronto => 'Toronto';
	@override String get europeLondon => 'London';
	@override String get asiaRiyadh => 'Riyadh';
	@override String get americaLosAngeles => 'Los Angeles';
	@override String get africaLagos => 'Lagos';
	@override String get africaAbidjan => 'Abidjan';
	@override String get americaNewYork => 'New York';
	@override String get africaCasablanca => 'Casablanca';
	@override String get asiaTokyo => 'Tokyo';
	@override String get americaArgentinaBuenosAires => 'Buenos Aires';
	@override String get africaDakar => 'Dakar';
	@override String get africaBamako => 'Bamako';
	@override String get africaNouakchott => 'Nouakchott';
	@override String get europeBrussels => 'Brussels';
}

// Path: commun.dates
class _Traductions$commun$dates$en extends Traductions$commun$dates$fr {
	_Traductions$commun$dates$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String moisAnnee({required Object mois, required Object annee}) => '${mois} ${annee}';
	@override String get choixMois => 'Month';
	@override List<String> get jours => [
		'Monday',
		'Tuesday',
		'Wednesday',
		'Thursday',
		'Friday',
		'Saturday',
		'Sunday',
	];
	@override List<String> get mois => [
		'January',
		'February',
		'March',
		'April',
		'May',
		'June',
		'July',
		'August',
		'September',
		'October',
		'November',
		'December',
	];
	@override String jourDate({required Object jour, required Object mois, required Object numero}) => '${jour} ${mois} ${numero}';
	@override String get premierJour => '1st';
}

// Path: commun.sections
class _Traductions$commun$sections$en extends Traductions$commun$sections$fr {
	_Traductions$commun$sections$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get page => 'Page sections';
}

// Path: commun.recherche
class _Traductions$commun$recherche$en extends Traductions$commun$recherche$fr {
	_Traductions$commun$recherche$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get effacer => 'Clear search';
	@override String get fermer => 'Close search';
}

// Path: connexion.invitationFoyer
class _Traductions$connexion$invitationFoyer$en extends Traductions$connexion$invitationFoyer$fr {
	_Traductions$connexion$invitationFoyer$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Invitation to join a household';
	@override String get autreAdresse => 'This invitation is for another address: sign out to open it.';
	@override String get autreAdressePhrase => 'Nothing was used: the invitation stays valid for the person invited.';
	@override String get creationImpossible => 'Your account could not be created with this link. Ask the person who invited you to send the invitation again.';
	@override String get plusValable => 'This invitation is no longer valid.';
	@override String get plusValablePhrase => 'Ask the person who invited you to send it again.';
}

// Path: connexion.controle
class _Traductions$connexion$controle$en extends Traductions$connexion$controle$fr {
	_Traductions$connexion$controle$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Security check';
	@override String get chargement => 'Security check in progress.';
	@override String get erreur => 'The check did not complete. Try again.';
	@override String get horsLigne => 'The check cannot be done right now. Try again when the connection is back.';
}

// Path: connexion.recuperation
class _Traductions$connexion$recuperation$en extends Traductions$connexion$recuperation$fr {
	_Traductions$connexion$recuperation$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Get back into my account';
	@override String get intro => 'There is no password to reset: enter your address and we send you a new sign-in link.';
	@override String get lienExpireTitre => 'This link is no longer valid';
	@override String get lienExpire => 'A sign-in link works only once and expires after a while. Request a new one below.';
	@override String get lienRefuseTitre => 'Sign-in did not complete';
	@override String get lienRefuse => 'This link could not sign you in. Request a new one below.';
	@override String get envoyer => 'Get a new link';
	@override String get envoyeTitre => 'New link sent';
	@override String envoye({required Object courriel}) => 'Open the message sent to ${courriel}, then follow the link.';
	@override String get envoyeEncart => 'The message can take a few minutes to arrive. Remember to check your spam folder.';
	@override String get autreAdresse => 'Use another address';
	@override String get revenirConnexion => 'Back to sign-in';
}

// Path: connexion.feuilleAppareil
class _Traductions$connexion$feuilleAppareil$en extends Traductions$connexion$feuilleAppareil$fr {
	_Traductions$connexion$feuilleAppareil$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get pourQui => 'For guardians who are already registered. This screen gives a student in your household their own access, on their tablet or phone, without handing over your account.';
	@override String get etapesTitre => 'Where to find the code';
	@override String get etape1 => 'On your own device, open Household, then Household devices.';
	@override String get etape2 => 'Tap the student\'s profile, then Connect a device.';
	@override String get etape3 => 'A QR code and a six-character code appear, with their expiry time.';
	@override String get etape4 => 'On the student\'s device, scan the QR code or enter the code.';
	@override String get plafond => 'The number of devices per student is limited. If the limit is reached, remove one from Household, Household devices.';
	@override String get saisir => 'Enter the code';
	@override String get fermer => 'Close';
}

// Path: inscription.questionnaire
class _Traductions$inscription$questionnaire$en extends Traductions$inscription$questionnaire$fr {
	_Traductions$inscription$questionnaire$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get recapLangue => 'Course language';
	@override String get prenomQuestion => 'What is your child\'s name?';
	@override String get prenomRaison => 'Their first name is enough. You can register other children at the end.';
	@override String get prenomIndice => 'For example: Yasmine';
	@override String ageQuestion({required Object prenom}) => 'How old is ${prenom}?';
	@override String ageMinimum({required Object min}) => 'The minimum age is ${min}.';
	@override String ans({required Object n}) => '${n} years old';
	@override String get adulte => '18 or older';
	@override String get adulteDetail => 'From 18, everyone registers for themselves, with "I\'m signing up for myself".';
	@override String get clavierLettres => 'On a keyboard, press the letter of an answer to choose it.';
	@override String genreQuestion({required Object prenom}) => '${prenom} is…';
	@override String get garcon => 'A boy';
	@override String get fille => 'A girl';
	@override String get genreRaison => 'The academy takes this into account when forming classes.';
	@override String get niveauQuestionMoi => 'Where are you today?';
	@override String etapeCourte({required Object n, required Object total}) => '${n} of ${total}';
	@override String get recapTitre => 'Here is what we understood';
	@override String get recapApprenants => 'Who is learning';
	@override String ligneEnfant({required Object prenom, required Object age}) => '${prenom}, ${age}';
	@override String get ligneVous => 'You';
	@override String get ajouterProfil => 'Add another student profile';
	@override String get envoyer => 'Send my request';
	@override String get dejaUnCompte => 'I already have an account';
	@override String get aucuneReponse => 'The answers to your sign-up are no longer on this device. Go back to the first questions: they take two minutes.';
	@override late final _Traductions$inscription$questionnaire$acces$en acces = _Traductions$inscription$questionnaire$acces$en._(_root);
}

// Path: inscription.usage
class _Traductions$inscription$usage$en extends Traductions$inscription$usage$fr {
	_Traductions$inscription$usage$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get question => 'Who are you creating this account for?';
	@override String get moiTitre => 'I\'m signing up for myself';
	@override String get moiDescription => 'You take the classes yourself. Your student profile is created with your account.';
	@override String get familleTitre => 'I\'m registering my child';
	@override String get familleDescription => 'You register one or more children and follow their progress. You can also take classes yourself.';
	@override String get enseignant => 'I have an invitation code';
	@override String get enseignantInvite => 'Are you a teacher? The academy invites you by email.';
	@override String get comptable => 'I have an accountant code';
	@override String get comptableInvite => 'Are you an accountant? The management invites you by email.';
	@override String get coursQuestion => 'Do you also take classes?';
	@override String get coursOui => 'Yes';
	@override String get coursNon => 'No';
	@override String get moiExemple => 'you are 18 or older and you are learning recitation for yourself.';
	@override String get familleExemple => 'you register Yasmine, 9, and Bilal, 12.';
	@override String get coursOuiExplication => 'You take classes yourself too, in addition to those of your family.';
	@override String get coursOuiExemple => 'your children attend their class and you attend yours.';
	@override String get coursNonExplication => 'You register your family and follow their progress, with no classes for yourself. You can change your mind later.';
	@override String get coursNonExemple => 'you register your daughter and follow her sessions from your account.';
	@override String get enseignantPostuler => 'Do you want to teach at Rewayah?';
	@override String get deposerCandidature => 'Submit my application';
}

// Path: inscription.recap
class _Traductions$inscription$recap$en extends Traductions$inscription$recap$fr {
	_Traductions$inscription$recap$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get usage => 'Account type';
	@override String get identite => 'Name';
	@override String get genre => 'Gender';
	@override String get enseignant => 'Teacher';
	@override String get comptable => 'Accountant';
	@override String get cours => 'Your own classes';
	@override String get coursOui => 'You also take classes';
	@override String get coursNon => 'No classes for you';
	@override String get telephone => 'Phone';
	@override String get langue => 'Language';
}

// Path: inscription.telephone
class _Traductions$inscription$telephone$en extends Traductions$inscription$telephone$fr {
	_Traductions$inscription$telephone$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get question => 'Your phone number';
	@override String get explication => 'It is used to avoid duplicates and to link your exchanges with the academy to your application. The academy writes to you in the app. It is never shown to other applicants.';
	@override String get indicatif => 'Country code';
	@override String get numero => 'Number, without the country code';
	@override String get indicatifManquant => 'Choose your country code.';
	@override String get numeroManquant => 'Enter your phone number.';
	@override String get numeroInvalide => 'This number is not readable. Write it in digits, without the country code.';
	@override String get changerIndicatif => 'Change country code';
	@override String get pays => 'Country';
	@override String get numeroCourt => 'Number';
	@override String get choisirPays => 'Choose your country';
	@override String get rechercherPays => 'Search for a country or a code';
}

// Path: inscription.langue
class _Traductions$inscription$langue$en extends Traductions$inscription$langue$fr {
	_Traductions$inscription$langue$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get question => 'In which language do you want to read the app?';
	@override String get francais => 'Français';
	@override String get arabe => 'العربية';
	@override String get francaisExplication => 'The app and the academy\'s messages are written in French.';
	@override String get francaisExemple => 'buttons, explanations and messages are shown from left to right.';
	@override String get arabeExplication => 'The app and the academy\'s messages are written in Arabic.';
	@override String get arabeExemple => 'buttons, explanations and messages are shown from right to left.';
}

// Path: inscription.confidentialite
class _Traductions$inscription$confidentialite$en extends Traductions$inscription$confidentialite$fr {
	_Traductions$inscription$confidentialite$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get kCase => 'I have read and accept the privacy policy.';
	@override String get lire => 'Read the privacy policy';
	@override String get requise => 'Tick this box to send your application.';
}

// Path: inscription.candidat
class _Traductions$inscription$candidat$en extends Traductions$inscription$candidat$fr {
	_Traductions$inscription$candidat$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get creationEchec => 'Your application may not have been sent. Try again in a moment.';
	@override String get envoyer => 'Send my application';
	@override String get accueil => 'You are submitting an application to teach at Rewayah. It does not commit you to anything.';
	@override String get ensuite => 'Next, the management reads your application and writes to you in the app.';
	@override String get horsLigne => 'The application can be sent when the connection is back.';
	@override String get courrielAConfirmer => 'Confirm your address first: open the link you received by email.';
	@override String get nonOuverte => 'Applications without a code are not open yet. If the management gave you a code, enter it.';
	@override String get nonConfirmee => 'Your request may not have reached Rewayah. Try again in a moment.';
	@override String aCorriger({required Object champs}) => 'One answer needs to be corrected: ${champs}. Press "Edit" next to the answer.';
	@override String get confidentialitePerimee => 'The privacy policy text has changed, and the version shown is no longer up to date. Reload the page or update the app, then read the text again.';
	@override String get indisponible => 'Sign-up is not available right now. Try again a little later.';
}

// Path: inscription.nomLatin
class _Traductions$inscription$nomLatin$en extends Traductions$inscription$nomLatin$fr {
	_Traductions$inscription$nomLatin$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Your name in Latin letters';
	@override String get raison => 'For lists, certificates and exchanges with the academy.';
	@override String get aide => 'Here is our suggestion. Correct it if your name is not written this way.';
	@override String get erreur => 'Write your name using Latin alphabet letters (a, b, c) to continue.';
}

// Path: consentement.texte
class _Traductions$consentement$texte$en extends Traductions$consentement$texte$fr {
	_Traductions$consentement$texte$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Parent visits';
	@override String get quiResponsable => 'The parents of the students present can briefly observe the session.';
	@override String get quiResponsableDetail => 'They hear the teacher and the students who speak, including your child. Their microphone and camera stay off: they can neither speak, nor write, nor appear on screen.';
	@override String get quiAdulte => 'The parents of the other students present can briefly observe the session.';
	@override String get quiAdulteDetail => 'They hear the teacher and the students who speak, including you. Their microphone and camera stay off: they can neither speak, nor write, nor appear on screen.';
	@override String get pourquoi => 'To follow learning without interrupting the class.';
	@override String get pourquoiDetail => 'A parent comes to see whether their child is taking part, then leaves. The room constantly reminds that a visit is possible.';
	@override String get limites => 'Short visits, in limited number.';
	@override String get limitesDetail => 'Each parent has a small number of visits per session, set by the academy and recalled in "How does it work?". A visit left before the end counts as a visit.';
	@override String get caseResponsable => 'I accept these terms for my child';
	@override String get caseAdulte => 'I accept these terms';
	@override String get continuer => 'Continue';
	@override String get retour => 'Back';
}

// Path: consentement.comment
class _Traductions$consentement$comment$en extends Traductions$consentement$comment$fr {
	_Traductions$consentement$comment$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'How does it work?';
	@override String visites({required num n, required Object minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'One visit of ${minutes} min per session.',
		other: '${n} visits of ${minutes} min per session.',
	);
	@override String visitesSansDuree({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'One short visit per session.',
		other: '${n} short visits per session.',
	);
	@override String get parParent => 'This number applies to each parent, whether the session brings together one or several of their children.';
	@override String get ecourtee => 'A visit left before the end is counted: only the next one remains, up to the last.';
	@override String get ecouter => 'You hear the teacher and the students who speak, including your child.';
	@override String get sansMicro => 'Your microphone and camera stay off during the visit.';
	@override String get valeursIndisponibles => 'The number of visits and their length are shown from your child\'s class, according to the rules of their class.';
	@override String get fermee => 'Observation visits are not open for this class.';
}

// Path: consentement.compte
class _Traductions$consentement$compte$en extends Traductions$consentement$compte$fr {
	_Traductions$consentement$compte$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get intro => 'The academy has added a paragraph on parent visits to its terms. Nothing is considered accepted until you have done so.';
	@override String accepteLe({required Object date}) => 'You accepted these terms on ${date}.';
	@override String get merci => 'Thank you, your agreement is saved.';
	@override String get chargement => 'Loading your agreements';
	@override String get erreur => 'Your agreements cannot be displayed for now.';
	@override String get horsLigne => 'Your agreements will be displayed as soon as the network is back.';
	@override String get sansProfil => 'No account signed in: sign in again to read your agreements.';
	@override String get invite => 'A new version to read: parent visits';
	@override String get inviteAction => 'Read';
}

// Path: foyer.vide
class _Traductions$foyer$vide$en extends Traductions$foyer$vide$fr {
	_Traductions$foyer$vide$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'No student profile yet';
	@override String get phrase => 'Add a student profile to register them in a class and link their device.';
	@override String get moiTitre => 'You take the classes';
	@override String get moiPhrase => 'Your student profile is linked to your account. Only add a student profile for another person in your family, a child for example.';
}

// Path: foyer.membre
class _Traductions$foyer$membre$en extends Traductions$foyer$membre$fr {
	_Traductions$foyer$membre$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get sansClasse => 'No class yet';
	@override String get classeEchec => 'Class not loaded';
	@override String get vous => 'You';
	@override String get accesSansEcheance => 'Access with no end date';
	@override String accesJusquau({required Object date}) => 'Access until ${date}';
	@override String accesExpire({required Object date}) => 'Access expired since ${date}';
	@override String date({required Object mois, required Object jour, required Object annee}) => '${mois} ${jour}, ${annee}';
}

// Path: foyer.ajout
class _Traductions$foyer$ajout$en extends Traductions$foyer$ajout$fr {
	_Traductions$foyer$ajout$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get suivant => 'Next';
	@override String get creer => 'Create the profile';
	@override late final _Traductions$foyer$ajout$porte$en porte = _Traductions$foyer$ajout$porte$en._(_root);
	@override late final _Traductions$foyer$ajout$pourQui$en pourQui = _Traductions$foyer$ajout$pourQui$en._(_root);
	@override late final _Traductions$foyer$ajout$identite$en identite = _Traductions$foyer$ajout$identite$en._(_root);
	@override late final _Traductions$foyer$ajout$erreurs$en erreurs = _Traductions$foyer$ajout$erreurs$en._(_root);
	@override late final _Traductions$foyer$ajout$refus$en refus = _Traductions$foyer$ajout$refus$en._(_root);
	@override late final _Traductions$foyer$ajout$incertaine$en incertaine = _Traductions$foyer$ajout$incertaine$en._(_root);
	@override String get horsLigne => 'The profile can be created when the connection is back.';
}

// Path: ficheEleve.supprimer
class _Traductions$ficheEleve$supprimer$en extends Traductions$ficheEleve$supprimer$fr {
	_Traductions$ficheEleve$supprimer$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get groupe => 'Delete the profile';
	@override String ligne({required Object dePrenom}) => 'Delete ${dePrenom}\'s profile';
	@override String get legende => 'The profile leaves its classes and can no longer sign in.';
	@override String question({required Object dePrenom}) => 'Delete ${dePrenom}\'s profile?';
	@override String get consequence => 'The profile can no longer sign in, immediately, and leaves its classes. It is anonymised at the end of the retention period. To get it back before then, write to the management.';
	@override String confirmer({required Object prenom}) => 'Yes, delete ${prenom}';
	@override String saisieLibelle({required Object prenom}) => 'To confirm, write the first name ${prenom}';
	@override String saisieErreur({required Object prenom}) => 'That is not the first name ${prenom}. Write it to confirm the deletion.';
	@override String get rester => 'Change nothing';
	@override String get horsFoyer => 'This profile cannot be deleted from your account. Write to the management.';
	@override String get dejaRetire => 'This profile is already deleted. The list is up to date.';
	@override String get refuse => 'Your account cannot delete this profile. Write to the management.';
	@override String get indisponible => 'Deleting a profile is not available yet. Nothing was deleted.';
	@override String get echec => 'The deletion could not be confirmed. Reopen the household to check before trying again.';
	@override String get horsLigne => 'Nothing was sent: there is no network. Try again as soon as it is back.';
}

// Path: ficheEleve.introuvable
class _Traductions$ficheEleve$introuvable$en extends Traductions$ficheEleve$introuvable$fr {
	_Traductions$ficheEleve$introuvable$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'This student profile cannot be found';
	@override String get phrase => 'It is not part of your household, or the link is incomplete.';
	@override String get retour => 'Back to the household';
}

// Path: ficheEleve.lignes
class _Traductions$ficheEleve$lignes$en extends Traductions$ficheEleve$lignes$fr {
	_Traductions$ficheEleve$lignes$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get informations => 'Information';
	@override String get informationsLegende => 'First name and photo';
	@override String get inscription => 'Journey and registration';
	@override String get inscriptionLegende => 'Questionnaire and class';
	@override String get interface => 'Interface';
	@override String get camera => 'Current camera';
	@override String get cameraAutorisee => 'Allowed';
	@override String get cameraNonAutorisee => 'Not allowed';
	@override String get acces => 'Rewayah access';
	@override String appareils({required Object dePrenom}) => '${dePrenom}\'s devices';
	@override String get appareilsLegende => 'Connect a device, see those that are linked, remove one';
	@override String get couleur => 'Profile colour';
	@override String get couleurAucune => 'No colour';
	@override String get couleurIndisponible => 'Not available yet';
	@override String get couleurEchec => 'Colour not loaded';
	@override String get finances => 'Finances';
}

// Path: ficheEleve.informations
class _Traductions$ficheEleve$informations$en extends Traductions$ficheEleve$informations$fr {
	_Traductions$ficheEleve$informations$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Student information';
	@override String get identite => 'Identity';
	@override String get prenom => 'First name';
	@override String get tranche => 'Age group';
	@override String get trancheInconnue => 'Not known yet';
	@override String get trancheNonLue => 'Not loaded';
	@override String get photo => 'Photo';
	@override String photoLegende({required Object dePrenom}) => 'A photo of ${dePrenom}\'s face. It is not an ID document. Their teacher, the students in their class and the management see it.';
	@override String get photoAucune => 'No photo yet';
	@override String get photoPresente => 'Photo saved';
	@override String get choisir => 'Choose a photo';
	@override String get changer => 'Change the photo';
	@override String get apercuTitre => 'Preview';
	@override String get apercuPhrase => 'Check the photo before sending it.';
	@override String get apercuIllisible => 'The preview cannot be displayed on this device. The photo can still be sent.';
	@override String get envoyer => 'Send this photo';
	@override String get autre => 'Choose another photo';
	@override String get annuler => 'Cancel';
	@override String get etapeEnvoi => 'Sending the photo, step 1 of 2';
	@override String get etapeEnregistrement => 'Saving to the profile, step 2 of 2';
	@override String get succes => 'The photo is saved.';
	@override String tropLourde({required Object taille}) => 'This photo is larger than ${taille} MB. Choose a lighter image.';
	@override String get echecEnvoi => 'The photo could not be sent. Nothing changed on the profile.';
	@override String get echecEnregistrement => 'The photo was sent, but it could not be saved to the profile.';
	@override String get reprendre => 'Try again';
	@override String get selectionEchec => 'The photo could not be opened. Check access to the device\'s photos, then try again.';
	@override String get horsLigne => 'The photo can be sent when the connection is back.';
}

// Path: ficheEleve.inscription
class _Traductions$ficheEleve$inscription$en extends Traductions$ficheEleve$inscription$fr {
	_Traductions$ficheEleve$inscription$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Journey and registration';
	@override String intro({required Object prenom}) => 'Where ${prenom} stands: questionnaire and class.';
	@override String get questionnaire => 'Questionnaire';
	@override String get classe => 'Class';
	@override String get lecture => 'Loading';
	@override String get etatInconnu => 'The questionnaire status cannot be displayed yet.';
	@override String get aRemplir => 'To fill in';
	@override String get horaireAChoisir => 'Filled in, schedule to choose';
	@override String get horaireRetire => 'Schedule withdrawn, to choose again';
	@override String get echangeAPrevoir => 'Preference saved, level conversation to schedule';
	@override String get echangePrevu => 'Level conversation planned';
	@override String get classeEnConstitution => 'Class being formed';
	@override String get classeConfirmee => 'Class confirmed';
	@override String get classeAucune => 'No class yet. Choose a class';
	@override String get classeIndisponible => 'The class cannot be displayed here yet. Choose a class';
	@override String get classeEchec => 'The class could not be loaded.';
	@override String get relireClasse => 'Reload the class';
}

// Path: ficheEleve.interface
class _Traductions$ficheEleve$interface$en extends Traductions$ficheEleve$interface$fr {
	_Traductions$ficheEleve$interface$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Interface';
	@override String intro({required Object dePrenom}) => 'Choose how Rewayah is displayed on ${dePrenom}\'s device. You can change this choice at any time.';
	@override String get guidee => 'Guided interface';
	@override String guideeDescription({required Object prenom}) => 'When ${prenom} prefers airy screens: larger text, one action at a time. Same sections and same rights.';
	@override String get standard => 'Standard display';
	@override String standardDescription({required Object prenom}) => 'When ${prenom} is comfortable with denser screens: more information per screen. Same sections and same rights.';
	@override String get politique => 'You choose this setting. No reason is asked, and the teacher only sees the name of the mode.';
	@override String application({required Object dePrenom}) => 'The change applies the next time Rewayah is opened on ${dePrenom}\'s device.';
	@override String get demandeEleve => 'Requesting the change by the student themselves is not offered yet.';
	@override String echec({required Object dePrenom}) => 'The change is not confirmed: it may not have reached Rewayah. Tap your choice again. If it did not arrive, ${dePrenom}\'s display stays as it was.';
	@override String get horsLigne => 'The display can be changed when the connection is back.';
}

// Path: ficheEleve.camera
class _Traductions$ficheEleve$camera$en extends Traductions$ficheEleve$camera$fr {
	_Traductions$ficheEleve$camera$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Current camera';
	@override String get ligne => 'Camera during sessions';
	@override String autorisee({required Object prenom}) => '${prenom} can turn on their camera during sessions.';
	@override String interdite({required Object prenom}) => 'The camera button will not appear for ${prenom} during sessions.';
	@override String application({required Object dePrenom}) => 'The change counts the next time ${dePrenom} joins a session.';
	@override String get distincte => 'This setting does not change the device\'s camera permission, the one the phone asks for to read a QR code.';
	@override String get echec => 'The change was not saved. Try again.';
	@override String get horsLigne => 'The camera can be set when the connection is back.';
}

// Path: ficheEleve.acces
class _Traductions$ficheEleve$acces$en extends Traductions$ficheEleve$acces$fr {
	_Traductions$ficheEleve$acces$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Rewayah access';
	@override String ligne({required Object dePrenom}) => '${dePrenom}\'s access';
	@override String get pastilleSansEcheance => 'No end date';
	@override String get pastilleEnCours => 'Active';
	@override String get pastilleExpire => 'Expired';
	@override String get sansEcheance => 'No end date is recorded.';
	@override String jusquau({required Object date}) => 'Until ${date}';
	@override String expireDepuis({required Object date}) => 'Expired since ${date}';
	@override String expirePhrase({required Object prenom}) => 'Since this date, ${prenom} can no longer enter Rewayah.';
	@override String get detailIndisponible => 'The start of access and its reason are not displayed yet.';
}

// Path: ficheEleve.couleur
class _Traductions$ficheEleve$couleur$en extends Traductions$ficheEleve$couleur$fr {
	_Traductions$ficheEleve$couleur$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Profile colour';
	@override String contexte({required Object prenom}) => 'Choose the colour that distinguishes ${prenom} from the other profiles in the household. It is shown behind their photo on household screens. It is neither a status nor a class.';
	@override String get menthe => 'Mint';
	@override String get ciel => 'Sky';
	@override String get lavande => 'Lavender';
	@override String get rose => 'Pink';
	@override String get peche => 'Peach';
	@override String get sable => 'Sand';
	@override String dejaPrise({required Object prenom}) => 'Already chosen for ${prenom}: the colour would no longer distinguish these profiles.';
	@override String prenomsEt({required Object premiers, required Object dernier}) => '${premiers} and ${dernier}';
	@override String get aucune => 'No colour';
	@override String choisie({required Object couleur}) => 'Colour chosen: ${couleur}.';
	@override String priseLigne({required Object couleur, required Object prenom}) => '${couleur}: already chosen for ${prenom}.';
	@override String aucuneDetail({required Object prenom}) => 'Only the photo and first name distinguish ${prenom}.';
	@override String get echec => 'The colour change is not confirmed: it may not have reached Rewayah. Choose the colour again.';
	@override String get horsLigne => 'The colour cannot be changed now. It can be chosen again as soon as sending is possible.';
}

// Path: ficheEleve.filAriane
class _Traductions$ficheEleve$filAriane$en extends Traductions$ficheEleve$filAriane$fr {
	_Traductions$ficheEleve$filAriane$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get foyer => 'Household';
}

// Path: ficheEleve.onglets
class _Traductions$ficheEleve$onglets$en extends Traductions$ficheEleve$onglets$fr {
	_Traductions$ficheEleve$onglets$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get general => 'General';
	@override String get finances => 'Finances';
}

// Path: ficheEleve.finances
class _Traductions$ficheEleve$finances$en extends Traductions$ficheEleve$finances$fr {
	_Traductions$ficheEleve$finances$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Finances';
	@override String titreBureau({required Object prenom}) => '${prenom} · Finances';
	@override String get vueTitre => 'Financial view';
	@override String get mensualite => 'Monthly fee';
	@override String mensualiteValeur({required Object montant}) => '${montant} / month';
	@override String get detailTitre => 'Monthly fee details';
	@override String get tarifEnfant => 'Child rate';
	@override String get tarifAdulte => 'Adult rate';
	@override String get remiseRang => 'Family discount';
	@override String remiseRangDe({required Object rang}) => 'Family discount, member no. ${rang}';
	@override String get prorata => 'Calendar reduction';
	@override String get bourse => 'Rewayah scholarship';
	@override String get accesOffert => 'Free access';
	@override String get prixSpecial => 'Special price';
	@override String get remisePrepaiement => 'Advance payment discount';
	@override String get avoir => 'Credit note';
	@override String get taxe => 'Applicable tax';
	@override String get total => 'Total to fund';
	@override String get regulariserTitre => 'Access to settle';
	@override String get aFinancerTitre => 'Next period to fund';
	@override String get expireTitre => 'Access expired';
	@override String manqueEtConservation({required Object montant, required Object date}) => '${montant} is missing for the next period. The place is kept until ${date}.';
	@override String get sansManque => 'The next period is not funded yet.';
	@override String manquePourMois({required Object montant, required Object mois}) => '${montant} is missing to fund ${mois}.';
	@override String manquePourMoisEtConservation({required Object montant, required Object mois, required Object date}) => '${montant} is missing to fund ${mois}. The place is kept until ${date}.';
	@override String moisNonFinance({required Object deMois}) => 'The period of ${deMois} is not funded yet.';
	@override String get periodeAFinancer => 'Period to fund';
	@override String periodeAFinancerValeur({required Object mois, required Object annee, required Object montant}) => '${mois} ${annee} · ${montant}';
	@override String get confirmationTitre => 'Payment being confirmed';
	@override String get confirmationPhrase => 'Do not pay a second time: the period updates as soon as it is confirmed.';
	@override String get indisponibleTitre => 'Finances are not available yet';
	@override String indisponiblePhrase({required Object dePrenom}) => '${dePrenom}\'s balance and monthly fee will appear here as soon as the academy has published them.';
	@override String erreurTitre({required Object dePrenom}) => '${dePrenom}\'s finances cannot be loaded';
	@override String videTitre({required Object prenom}) => 'No finances recorded for ${prenom}';
	@override String get videPhrase => 'No balance or monthly fee is shown yet for this profile. They will appear here after they register in a class.';
	@override String get voirMouvements => 'See the movements';
	@override String get noteAbsences => 'Ordinary absences do not reduce the month once it is funded.';
	@override String get faitSeance => 'No charge per session';
	@override String get faitPeriode => 'Access tied to the funded period';
	@override String get historiqueTitre => 'Transaction history';
	@override String get voirTout => 'See all';
	@override String voirToutSemantique({required Object dePrenom}) => 'See all: ${dePrenom}\'s movements';
	@override String voirMouvementsSemantique({required Object dePrenom}) => 'See ${dePrenom}\'s movements';
	@override String get telechargerRecu => 'Download the receipt';
	@override String get recuIndisponibleTitre => 'The receipt is not available yet';
	@override String get recuIndisponiblePhrase => 'Receipt download arrives with the launch of payments. Each payment stays visible in the movements.';
	@override String get recuEchecTitre => 'The receipt could not be prepared';
	@override String get recuEchecPhrase => 'Your request may not have reached Rewayah. Try again in a moment.';
	@override String get sansDonnees => 'The finances of this profile could not be loaded';
}

// Path: ficheEleve.mouvements
class _Traductions$ficheEleve$mouvements$en extends Traductions$ficheEleve$mouvements$fr {
	_Traductions$ficheEleve$mouvements$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Movements';
	@override String dateHeure({required Object date, required Object heure}) => '${date} at ${heure}';
	@override String heureChiffres({required Object heures, required Object minutes}) => '${heures}:${minutes}';
	@override String contexte({required Object dePrenom}) => '${dePrenom}\'s top-ups, monthly fees, discounts and credit notes, from the most recent to the oldest. Nothing is erased: a correction is added as a new movement.';
	@override String get personne => 'Person';
	@override late final _Traductions$ficheEleve$mouvements$colonne$en colonne = _Traductions$ficheEleve$mouvements$colonne$en._(_root);
	@override late final _Traductions$ficheEleve$mouvements$nature$en nature = _Traductions$ficheEleve$mouvements$nature$en._(_root);
	@override late final _Traductions$ficheEleve$mouvements$statut$en statut = _Traductions$ficheEleve$mouvements$statut$en._(_root);
	@override String get voirRecu => 'See the receipt';
	@override String voirRecuSemantique({required Object reference}) => 'See receipt ${reference}';
	@override late final _Traductions$ficheEleve$mouvements$recu$en recu = _Traductions$ficheEleve$mouvements$recu$en._(_root);
	@override String get videTitre => 'No movements';
	@override String videPhrase({required Object prenom}) => 'No top-up or monthly fee is recorded yet for ${prenom}. Movements will appear here after the first payment.';
	@override String erreurTitre({required Object dePrenom}) => '${dePrenom}\'s movements cannot be loaded';
	@override String get indisponibleTitre => 'Movements are not available yet';
	@override String indisponiblePhrase({required Object dePrenom}) => '${dePrenom}\'s top-ups and monthly fees will appear here once they are in service.';
	@override String get sansDonnees => 'The movements of this profile could not be loaded';
}

// Path: recrutement.nomLatin
class _Traductions$recrutement$nomLatin$en extends Traductions$recrutement$nomLatin$fr {
	_Traductions$recrutement$nomLatin$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Your name in Latin letters';
	@override String get explication => 'Your name is written in another script. For lists, certificates and exchanges with the academy, we need it written in Latin letters.';
	@override String get libelle => 'Your name in Latin letters';
	@override String get aide => 'Here is our suggestion. Correct it if your name is not written this way, then confirm.';
	@override String origine({required Object nom}) => 'Your name as you wrote it: ${nom}';
	@override String get confirmer => 'Confirm my name';
	@override String get plusTard => 'Later';
	@override String get erreur => 'Write your name using Latin alphabet letters (a, b, c) to continue.';
	@override String get echec => 'Your name is not confirmed. Try again in a moment.';
}

// Path: recrutement.candidat
class _Traductions$recrutement$candidat$en extends Traductions$recrutement$candidat$fr {
	_Traductions$recrutement$candidat$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Your code';
	@override String get intro => 'To sign up as a teacher, enter the invitation code you received from the management.';
	@override String get champ => 'Invitation code';
	@override String get champVide => 'Enter the invitation code you received.';
	@override String get verifier => 'Check the code';
	@override String valide({required Object date}) => 'Invitation valid until ${date}.';
	@override String get valideDetail => 'You can create your teacher profile.';
	@override String get creerProfil => 'Create my profile';
	@override String get expiree => 'This invitation has expired.';
	@override String get expireeDetail => 'Ask the academy\'s management for a new invitation.';
	@override String get demanderNouvelle => 'Request a new invitation';
	@override String get contactCopie => 'The management\'s address was copied: write to them from your email.';
	@override String get dejaUtilisee => 'This invitation has already been used.';
	@override String get dejaUtiliseeDetail => 'If it was you, sign in with the account you created.';
	@override String get seConnecter => 'Sign in';
	@override String get inconnue => 'Code not recognised.';
	@override String get inconnueDetail => 'Check the code, then enter it again.';
	@override String get ressaisir => 'Enter another code';
	@override String get horsLigne => 'The code was not checked. Try again in a moment.';
	@override String get erreur => 'The code could not be checked. Try again in a moment.';
	@override String get indisponible => 'Checking invitations will be available once the server is connected.';
	@override late final _Traductions$recrutement$candidat$comptable$en comptable = _Traductions$recrutement$candidat$comptable$en._(_root);
}

// Path: recrutement.signature
class _Traductions$recrutement$signature$en extends Traductions$recrutement$signature$fr {
	_Traductions$recrutement$signature$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Contract';
	@override String version({required Object version}) => 'Version ${version}';
	@override String empreinte({required Object empreinte}) => 'Text fingerprint: ${empreinte}';
	@override String get texteAltere => 'The text received does not match its fingerprint: signing is not offered. Try again later or let the management know.';
	@override String get champNom => 'Signer\'s name';
	@override String get aideNom => 'Your account name. If it differs from your ID document, let the management know.';
	@override String get nomCompteVide => 'Your account has no name yet: signing is not possible. Let the management know.';
	@override String get nomCompteLecture => 'Your account name is not displayed: signing is waiting. Try again in a moment.';
	@override String get nomVide => 'Enter your full name to sign.';
	@override String get nomTropLong => 'This name is too long: shorten it.';
	@override String get accuse => 'I confirm I have read this contract.';
	@override String get signer => 'Sign the contract';
	@override String dejaSigne({required Object date, required Object version}) => 'Signed on ${date}, version ${version}.';
	@override String signePar({required Object nom}) => 'Signed by ${nom}';
	@override String get copie => 'Download my copy';
	@override String get copieLien => 'The link to your copy is copied. Paste it into your browser: it stays valid for a few minutes.';
	@override String get copieErreur => 'Your copy could not be prepared. Try again in a moment.';
	@override String nouvelleVersion({required Object version}) => 'The contract has been updated since your last signature (version ${version}). Read it again, then sign again.';
	@override String get versionPerimee => 'The contract was updated while you were reading. The text is reloaded: read it again, then sign again.';
	@override String get horsLigne => 'The contract is not signed. Try again in a moment.';
	@override String get erreur => 'The signature is not confirmed. Check whether the contract appears signed before trying again.';
	@override String get nonConnecte => 'Your session has expired. Sign in again to sign.';
	@override String get introuvable => 'No contract is published for now. Let the management know.';
	@override String get erreurLecture => 'The contract could not be loaded. Try again in a moment.';
	@override String get sansDonnees => 'The contract cannot be read offline.';
	@override String get indisponible => 'Signing the contract will be available once the server is connected.';
	@override String get retour => 'Back';
}

// Path: recrutement.cadre
class _Traductions$recrutement$cadre$en extends Traductions$recrutement$cadre$fr {
	_Traductions$recrutement$cadre$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'The religious and educational framework';
	@override String get caseAccord => 'I confirm I have read this framework and I adhere to it.';
	@override String get accepter => 'Accept the framework';
	@override String get erreurLecture => 'The framework could not be loaded. Try again.';
	@override String get erreurAccord => 'Your agreement was not saved. Try again.';
	@override String get refuse => 'This framework cannot be accepted for now: your application is no longer at this step.';
}

// Path: recrutement.portail
class _Traductions$recrutement$portail$en extends Traductions$recrutement$portail$fr {
	_Traductions$recrutement$portail$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get aCompleterTitre => 'Your application needs to be completed';
	@override String get aCompleter => 'To complete';
	@override String get elementCadre => 'The religious and educational framework';
	@override String get etatAEnvoyer => 'To send';
	@override String get completer => 'Complete my application';
	@override String get enExamenTitre => 'Your application has been sent';
	@override String get enExamen => 'The academy is reading your answers and will notify you here.';
	@override String get versementImpossible => 'Rewayah cannot yet pay you through the means declared in your country. Your application stays on hold. The academy will let you know as soon as a means becomes possible.';
	@override String get libreDePartir => 'You remain free to withdraw your application.';
	@override String get enPauseTitre => 'Your application is on hold';
	@override String repriseLe({required Object date}) => 'Resumes on ${date}.';
	@override String get refuseeTitre => 'Your application was not accepted';
	@override String get retireeTitre => 'Application withdrawn';
	@override String get retiree => 'You withdrew your application. Only the academy can reopen it.';
	@override String get complementDemande => 'The academy is asking you for more information.';
	@override String complementListe({required Object elements}) => 'To complete: ${elements}.';
	@override String get nonCharge => 'The status of your application could not be loaded.';
	@override String get elementPiece => 'Your ID document';
	@override String get elementContrat => 'The teacher contract';
	@override String get versementImpossibleTitre => 'Payment not possible yet';
	@override String get relire => 'Review my application';
	@override String get toutIci => 'Everything is done here. What is already done is marked "Done".';
	@override String get listeTitre => 'What is needed to send';
	@override String get etatFait => 'Done';
	@override String get etatADeposer => 'To submit';
	@override String get elementAccords => 'The contract and our agreements';
	@override String get elementReponses => 'Your answers';
	@override String reponsesRestantes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} answer remains',
		other: '${n} answers remain',
	);
	@override String get reponsesPretes => 'Ready to send';
	@override String get elementPhoto => 'Your photo';
	@override String get etatAAjouter => 'To add';
}

// Path: recrutement.entretien
class _Traductions$recrutement$entretien$en extends Traductions$recrutement$entretien$fr {
	_Traductions$recrutement$entretien$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Let\'s get to know each other';
	@override String get intro => 'Choose a time for a video interview with the academy.';
	@override String get heureAppareil => 'This device\'s time';
	@override String horaire({required Object date, required Object debut, required Object fin}) => '${date}, from ${debut} to ${fin}';
	@override String get choisir => 'Choose a time.';
	@override String get reserver => 'Book this time';
	@override String get aucunCreneau => 'No time is open for now. Come back later.';
	@override String get erreurLecture => 'The times could not be loaded. Try again.';
	@override String get pris => 'This time has just been taken. Choose another.';
	@override String get dejaPlanifie => 'Your interview is already set.';
	@override String get perime => 'Your application has changed in the meantime. Reload the page.';
	@override String get erreurReservation => 'The booking did not complete. Try again.';
	@override String get votreEntretien => 'Your interview';
	@override String get rejoindre => 'Join the interview';
	@override String ouvreA({required Object heure}) => 'You can join from ${heure}.';
	@override String get termine => 'The time of your interview has passed. The academy will write to you with what comes next.';
	@override String get pasEncore => 'The interview is not open yet for your application.';
	@override String get portailChoisir => 'Choose a time for our interview';
	@override String get portailVoir => 'See my interview';
	@override late final _Traductions$recrutement$entretien$notifications$en notifications = _Traductions$recrutement$entretien$notifications$en._(_root);
}

// Path: recrutement.questionnaire
class _Traductions$recrutement$questionnaire$en extends Traductions$recrutement$questionnaire$fr {
	_Traductions$recrutement$questionnaire$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Your application';
	@override String get conditionsTitre => 'Pay terms';
	@override String part({required Object part}) => 'Your share: ${part} of the public price, for each student present.';
	@override String partPublic({required Object public, required Object part}) => '${public}: ${part} of the public price, for each student present.';
	@override String get publicEnfant => 'Children (6 to 17)';
	@override String get publicAdulte => 'Adults (18 and over)';
	@override String get coordonneesPlusTard => 'Your financial details will only be requested before your first payment.';
	@override String get montantsSurDemande => 'To find out the amounts, ask the administration.';
	@override String conditionsDateEffet({required Object date}) => 'These terms apply from ${date}.';
	@override String get accordRemuneration => 'I have read these terms and I accept them.';
	@override String get accordManquant => 'Tick the box to accept these terms and send your application.';
	@override String get envoyer => 'Send my application';
	@override String get cadreManquant => 'First accept the religious and educational framework.';
	@override String get cadreAccepte => 'You have accepted the religious and educational framework.';
	@override String get langues => 'Your languages';
	@override String get recitation => 'Your recitation';
	@override String get disponibilites => 'Your availability';
	@override String get publics => 'The audiences you can teach';
	@override String get versement => 'Your country and your payment';
	@override String get perime => 'The questionnaire has changed since your last visit. Read your answers again before sending.';
	@override String incomplet({required Object question}) => 'An answer is missing: ${question}.';
	@override String reponseInvalide({required Object question}) => 'An answer is no longer valid: ${question}.';
	@override String get conflit => 'Your application has changed since this page was opened. Read it again, then send it.';
	@override String get conditionsPerimees => 'The pay terms have changed. Read them again, then accept them again.';
	@override String get interdit => 'Your application can no longer be sent from this page.';
	@override String get echec => 'One of your answers needs to be reviewed. Read them again, then send your application again.';
	@override String get incertain => 'Your application may not have reached Rewayah. Try again: it will not be saved twice.';
	@override String get horsLigne => 'Your application can be sent when the connection is back.';
	@override String get nonOuverte => 'This step is not open yet. Your account is kept.';
	@override String get nonCharge => 'The questionnaire could not be loaded.';
	@override String get conditionsNonCharge => 'The pay terms could not be loaded.';
	@override String get envoyee => 'Your application has been sent. The academy will notify you here if it needs to be completed.';
	@override String envoyeeLe({required Object date}) => 'Sent on ${date}.';
	@override String etatVersement({required Object etat}) => 'Payment method: ${etat}';
	@override String get retourDossier => 'Back to my file';
	@override String get complementCarte => 'The academy asks you to complete this part.';
	@override String get moyenValide => 'You receive your pay through a method approved by Rewayah.';
	@override String get continuite => 'By accepting these terms, you commit to holding your class on the same days and at the same times, every week.';
	@override String get plagesChevauchent => 'Your availability overlaps on the same day. Review it, then send your application again.';
}

// Path: recrutement.parcours
class _Traductions$recrutement$parcours$en extends Traductions$recrutement$parcours$fr {
	_Traductions$recrutement$parcours$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get choisir => 'Choose an answer to continue.';
	@override String get choisirPlusieurs => 'Choose at least one answer to continue.';
	@override String trop({required num max}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(max,
		one: 'Choose only one answer.',
		other: 'Choose at most ${max} answers.',
	);
	@override String get aucune => 'None';
	@override String get oui => 'Yes';
	@override String get non => 'No';
	@override String get modifier => 'Edit';
	@override String get sauvegardeEchec => 'Your latest answers could not be saved. They stay on screen: continue, they will be sent with your application.';
	@override late final _Traductions$recrutement$parcours$presentation$en presentation = _Traductions$recrutement$parcours$presentation$en._(_root);
	@override late final _Traductions$recrutement$parcours$langues$en langues = _Traductions$recrutement$parcours$langues$en._(_root);
	@override late final _Traductions$recrutement$parcours$pays$en pays = _Traductions$recrutement$parcours$pays$en._(_root);
	@override late final _Traductions$recrutement$parcours$riwayat$en riwayat = _Traductions$recrutement$parcours$riwayat$en._(_root);
	@override late final _Traductions$recrutement$parcours$fuseau$en fuseau = _Traductions$recrutement$parcours$fuseau$en._(_root);
	@override late final _Traductions$recrutement$parcours$creneaux$en creneaux = _Traductions$recrutement$parcours$creneaux$en._(_root);
	@override late final _Traductions$recrutement$parcours$versement$en versement = _Traductions$recrutement$parcours$versement$en._(_root);
	@override late final _Traductions$recrutement$parcours$recap$en recap = _Traductions$recrutement$parcours$recap$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$en q = _Traductions$recrutement$parcours$q$en._(_root);
	@override late final _Traductions$recrutement$parcours$classes$en classes = _Traductions$recrutement$parcours$classes$en._(_root);
	@override late final _Traductions$recrutement$parcours$moyens$en moyens = _Traductions$recrutement$parcours$moyens$en._(_root);
	@override String get choisirJour => 'Choose at least one day to continue.';
	@override String get choisirHeure => 'Choose at least one start time to continue.';
	@override String choisirHeureJour({required Object jour}) => 'Choose at least one start time for ${jour}.';
}

// Path: nav.eleve
class _Traductions$nav$eleve$en extends Traductions$nav$eleve$fr {
	_Traductions$nav$eleve$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get accueil => 'Home';
	@override String get maClasse => 'My class';
	@override String get coran => 'Quran';
	@override String get monEspace => 'My space';
	@override String get suivi => 'Progress';
	@override String get compte => 'Account';
	@override String get aujourdhui => 'Today';
	@override String get apprendre => 'Learn';
	@override String get profil => 'Profile';
}

// Path: nav.tuteur
class _Traductions$nav$tuteur$en extends Traductions$nav$tuteur$fr {
	_Traductions$nav$tuteur$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get accueil => 'Home';
	@override String get foyer => 'Household';
	@override String get disponibilites => 'Availability';
	@override String get reglages => 'Settings';
	@override String get suivi => 'Progress';
	@override String get historique => 'History';
	@override String get compte => 'Account';
}

// Path: nav.enseignant
class _Traductions$nav$enseignant$en extends Traductions$nav$enseignant$fr {
	_Traductions$nav$enseignant$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get journee => 'Today';
	@override String get classes => 'Classes';
	@override String get creneaux => 'Availability';
	@override String get profil => 'Profile';
	@override String get compte => 'Account';
}

// Path: nav.controleur
class _Traductions$nav$controleur$en extends Traductions$nav$controleur$fr {
	_Traductions$nav$controleur$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get planning => 'Schedule';
	@override String get controle => 'Review';
	@override String get historique => 'History';
	@override String get echanges => 'Messages';
	@override String get compte => 'Account';
}

// Path: nav.admin
class _Traductions$nav$admin$en extends Traductions$nav$admin$fr {
	_Traductions$nav$admin$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get tableauDeBord => 'Dashboard';
	@override String get dossiers => 'Files';
	@override String get demandes => 'Requests';
	@override String get journal => 'Log';
	@override String get comptes => 'Accounts';
	@override String get accesAgents => 'Agent access';
	@override String get accueil => 'Home';
	@override String get operations => 'Operations';
	@override String get personnes => 'People';
	@override String get pedagogie => 'Teaching';
	@override String get finance => 'Finance';
	@override String get configuration => 'Settings';
	@override String get securite => 'Security and audit';
	@override String get direction => 'Management';
	@override String get recherche => 'Search';
	@override String get rechercheIndication => 'Search for a screen';
	@override String get notificationsTitre => 'Notifications';
	@override String get menu => 'Menu';
}

// Path: nav.halo
class _Traductions$nav$halo$en extends Traductions$nav$halo$fr {
	_Traductions$nav$halo$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get enCeMoment => 'Right now';
	@override String get monCompte => 'My account';
	@override String urgentNom({required Object compte}) => '${compte}, one urgent alert';
	@override String get urgentMot => 'Urgent';
	@override String get ouvrirAlerte => 'Open the alert';
	@override String nouveauNom({required num n, required Object compte, required Object nombre}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${compte}, ${nombre} new item to read',
		other: '${compte}, ${nombre} new items to read',
	);
	@override String nouveauTitre({required num n, required Object nombre}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${nombre} new item to read',
		other: '${nombre} new items to read',
	);
	@override String get nouveauMot => 'To read';
	@override String get lire => 'Read';
	@override String salleNom({required Object compte}) => '${compte}, the room is open';
}

// Path: nav.filAriane
class _Traductions$nav$filAriane$en extends Traductions$nav$filAriane$fr {
	_Traductions$nav$filAriane$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get separateur => '›';
	@override String suite({required Object libelle}) => '› ${libelle}';
}

// Path: compte.page
class _Traductions$compte$page$en extends Traductions$compte$page$fr {
	_Traductions$compte$page$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$compte$page$langue$en langue = _Traductions$compte$page$langue$en._(_root);
}

// Path: historique.segments
class _Traductions$historique$segments$en extends Traductions$historique$segments$fr {
	_Traductions$historique$segments$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get seances => 'Sessions';
	@override String get observations => 'Observations';
}

// Path: historique.duree
class _Traductions$historique$duree$en extends Traductions$historique$duree$fr {
	_Traductions$historique$duree$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String secondes({required Object s}) => '${s} s';
	@override String minutes({required Object m}) => '${m} min';
	@override String minutesSecondes({required Object m, required Object s}) => '${m} min ${s} s';
	@override String heures({required Object h}) => '${h} h';
	@override String heuresMinutes({required Object h, required Object m}) => '${h} h ${m}';
}

// Path: historique.selecteur
class _Traductions$historique$selecteur$en extends Traductions$historique$selecteur$fr {
	_Traductions$historique$selecteur$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get aucune => 'No session';
	@override String get une => '1 session';
	@override String plusieurs({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} session',
		other: '${n} sessions',
	);
}

// Path: historique.filtres
class _Traductions$historique$filtres$en extends Traductions$historique$filtres$fr {
	_Traductions$historique$filtres$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get classe => 'Class';
	@override String get toutesClasses => 'All classes';
	@override String get periode => 'Period';
	@override String get toutePeriode => 'Whole period';
	@override String get septJours => 'Last 7 days';
	@override String get trenteJours => 'Last 30 days';
	@override String get troisMois => 'Last 3 months';
	@override String get statut => 'Status';
	@override String get tousStatuts => 'All statuses';
}

// Path: historique.etat
class _Traductions$historique$etat$en extends Traductions$historique$etat$fr {
	_Traductions$historique$etat$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get presence => 'Present';
	@override String retard({required Object minutes}) => 'Late ${minutes} min';
	@override String get retardSansDuree => 'Late';
	@override String get verification => 'Being verified';
	@override String get annule => 'Class cancelled';
	@override String get nonTenu => 'Class not held';
	@override String avecDuree({required Object etat, required Object duree}) => '${etat} · ${duree}';
}

// Path: historique.seances
class _Traductions$historique$seances$en extends Traductions$historique$seances$fr {
	_Traductions$historique$seances$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get videTitre => 'No past sessions';
	@override String videPhrase({required Object dePrenom}) => '${dePrenom}\'s past sessions will appear here.';
	@override String get videPhraseFoyer => 'The past sessions of the student profiles will appear here.';
	@override String get filtreVideTitre => 'No session matches';
	@override String get filtreVidePhrase => 'Change the filters to find the other sessions.';
	@override String tronquee({required Object nombre}) => 'The ${nombre} most recent sessions are shown.';
	@override String ouvrir({required Object date, required Object classe, required Object etat}) => 'Session of ${date}, ${classe}, ${etat}';
}

// Path: historique.observations
class _Traductions$historique$observations$en extends Traductions$historique$observations$fr {
	_Traductions$historique$observations$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get indisponibleTitre => 'Observation history unavailable';
	@override String get indisponiblePhrase => 'Recorded visits cannot be read in the app yet.';
	@override String get videTitre => 'No observations';
	@override String videPhrase({required Object dePrenom}) => 'The visits you make during ${dePrenom}\'s sessions will appear here.';
	@override String get videPhraseFoyer => 'Your visits during sessions will appear here.';
	@override String get filtreVideTitre => 'No observation matches';
	@override String get filtreVidePhrase => 'Change the filters to find the other visits.';
	@override String get visiteUne => '1 visit';
	@override String visites({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} visit',
		other: '${n} visits',
	);
	@override String get dureeNonConfirmee => 'Duration not confirmed';
	@override String get terminee => 'Ended';
	@override String get nonRefermee => 'Exit not recorded';
	@override String get eleveInconnu => 'Student';
	@override String get tronquee => 'Only the most recent visits are shown.';
	@override String ouvrir({required Object date, required Object classe, required Object etat}) => 'Observations of ${date}, ${classe}, ${etat}';
}

// Path: historique.seance
class _Traductions$historique$seance$en extends Traductions$historique$seance$fr {
	_Traductions$historique$seance$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String titreSansClasse({required Object date}) => 'Session of ${date}';
	@override String get blocSeance => 'The session';
	@override String blocPresence({required Object dePrenom}) => '${dePrenom}\'s attendance';
	@override String get date => 'Date';
	@override String get horaire => 'Time';
	@override String get dureePrevue => 'Planned duration';
	@override String get classe => 'Class';
	@override String get enseignant => 'Teacher';
	@override String get presence => 'Attendance';
	@override String get arrivee => 'Arrival';
	@override String get sortie => 'Exit';
	@override String get tempsPresence => 'Time present';
	@override String minutesSur({required Object minutes, required Object prevues}) => '${minutes} min out of ${prevues}';
	@override String get presencePartielle => 'Partial attendance';
	@override String get interruption => 'Interruption';
	@override String get verificationPhrase => 'Attendance is not yet confirmed for this session.';
	@override String get mesureAutomatique => 'Attendance measured automatically from connections to the room.';
	@override String get nonTenuPhrase => 'The session did not take place: this is not the student\'s doing.';
	@override String get annulePhrase => 'The session was cancelled.';
	@override String get introuvableTitre => 'Session not found';
	@override String get introuvablePhrase => 'This session is not in your household\'s history.';
}

// Path: historique.observation
class _Traductions$historique$observation$en extends Traductions$historique$observation$fr {
	_Traductions$historique$observation$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String titreSansClasse({required Object date}) => 'Observations of ${date}';
	@override String get blocResume => 'Summary';
	@override String get blocVisites => 'Visits';
	@override String get observateur => 'Observer';
	@override String get vous => 'You';
	@override String get eleve => 'Student';
	@override String get enseignant => 'Teacher';
	@override String get dureeTotale => 'Total duration';
	@override String visite({required Object n}) => 'Visit ${n}';
	@override String plageOuverte({required Object debut}) => 'Entered at ${debut}';
	@override String get terminee => 'Visit ended';
	@override String get introuvableTitre => 'No visit for this session';
	@override String get introuvablePhrase => 'No recorded visit matches this session.';
}

// Path: historique.compteRendu
class _Traductions$historique$compteRendu$en extends Traductions$historique$compteRendu$fr {
	_Traductions$historique$compteRendu$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Teaching report';
	@override String get travaille => 'What was worked on';
	@override String get appreciation => 'Assessment of the session';
	@override String get aRenforcer => 'To reinforce';
	@override String get aPreparer => 'To prepare for the next session';
	@override String get commentaire => 'Shared comment';
	@override String corrigeLe({required Object date}) => 'Corrected on ${date}';
	@override String get nonDisponibleTitre => 'Teaching report not available';
	@override String get nonPartagePhrase => 'The observations of this session are not shared with your family for now.';
	@override String get enAttentePhrase => 'The report is not available yet.';
	@override String get illisiblePhrase => 'The report cannot be displayed.';
	@override String get horsLignePhrase => 'A connection is needed to view the report.';
	@override String get aucunChampPhrase => 'No teaching report is available for this session.';
	@override String get voirTravail => 'See the work to prepare';
	@override String get voirProgression => 'See the progress';
	@override String get etatARenforcer => 'To reinforce';
	@override String get etatAcquis => 'Mastered';
}

// Path: notifications.evenements
class _Traductions$notifications$evenements$en extends Traductions$notifications$evenements$fr {
	_Traductions$notifications$evenements$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get bienvenueEquipe => 'Welcome to the team. You still need to set up your space.';
	@override String get retenuEntretien => 'You have been selected for an interview. Let\'s get to know each other: choose your time in the app.';
	@override String pauseRepondueAcceptee({required Object dePrenom, required Object mois}) => '${dePrenom}\'s one-month pause is accepted for ${mois}. Their deadline moves back by the same amount. Their place is kept.';
	@override String pauseRepondueAccepteeAdulte({required Object mois}) => 'Your one-month pause is accepted for ${mois}. Your deadline moves back by the same amount. Your place is kept.';
	@override String pauseRepondueRefusee({required Object dePrenom, required Object mois}) => '${dePrenom}\'s one-month pause for ${mois} is not accepted. The reason is in the app.';
	@override String pauseRepondueRefuseeAdulte({required Object mois}) => 'Your one-month pause for ${mois} is not accepted. The reason is in the app.';
	@override String get demandeRecue => 'A new time slot request has been received.';
	@override String get demandePresentation => 'A standard display request has been received.';
	@override String get classeValidee => 'The class is ready and waiting for its teacher.';
	@override String get enseignantAffecte => 'A teacher has been assigned to the class.';
	@override String get demandeClose => 'A time slot request has been closed.';
	@override String get remplacementPropose => 'A class replacement is being offered to you.';
	@override String get remplacementPris => 'A class replacement has been assigned.';
	@override String get controleMissionAttribuee => 'A review mission has been assigned to you.';
	@override String get controleMissionNonControlee => 'A review mission was left without a check.';
	@override String get classeChangee => 'A student in the family has joined another class, at the same time.';
	@override String get paiementRelance => 'A payment is coming due. It is paid in Payments.';
	@override String get accesSuspenduPaiement => 'Access is suspended: this month\'s payment has not been received.';
	@override String get accesRetabliPaiement => 'Access is restored: the payment has been received.';
	@override String get paiementRecu => 'The payment has been received. The balance is up to date.';
	@override String get accesSuspenduRemboursement => 'Access is suspended: a payment was refunded, the month is no longer paid.';
	@override String get accesSuspenduLitige => 'Access is suspended: a payment is disputed with the bank.';
	@override String get remboursementEffectue => 'A refund has been made. The balance is up to date.';
	@override String get remboursementEffectueDirection => 'A refund has been made to a family.';
	@override String get litigeOuvert => 'A payment is disputed with the bank. Access is suspended during the review.';
	@override String get litigeOuvertDirection => 'A family is disputing a payment with their bank.';
	@override String get litigeClosGagne => 'The dispute is closed: the bank ruled in the academy\'s favour.';
	@override String get litigeClosPerdu => 'The dispute is closed: the payment is refunded, the fees go to the household balance.';
	@override String get litigeClosDirection => 'A payment dispute is closed.';
	@override String get enseignantAffecteSoi => 'A teacher has been assigned to your class.';
	@override String get toutEstPret => 'All set: see the tracking of your request.';
	@override String get toutEstPretSoi => 'All set: your class, your teacher and your first class are confirmed.';
	@override String toutEstPretPour({required Object prenom}) => 'All set for ${prenom}: see the tracking of the request.';
	@override String get enseignantAffecteClasse => 'A class is entrusted to you.';
	@override String remplacementPrisQuand({required Object quand}) => 'The session of ${quand} will be taken by a replacement teacher.';
	@override String get classeCreee => 'A class has just been created.';
	@override String get classeCreeeSoi => 'Your class is created. Its schedule is in the app.';
	@override String get classeCreeeFoyer => 'A class is created for a student in your household.';
	@override String get classeCreeeClasse => 'A new class is entrusted to you.';
	@override String get enseignantChange => 'The class teacher has changed.';
	@override String get enseignantChangeClasse => 'The teacher of one of your classes has changed.';
	@override String get eleveInscrit => 'A student is registered in the class.';
	@override String get eleveInscritSoi => 'You are registered in a class.';
	@override String get eleveInscritFoyer => 'A student in your household is registered in a class.';
	@override String get eleveInscritClasse => 'A student joins one of your classes.';
	@override String get eleveRetire => 'A student is no longer part of the class.';
	@override String get eleveRetireSoi => 'You are no longer part of this class.';
	@override String get eleveRetireFoyer => 'A student in your household is no longer part of their class.';
	@override String get eleveRetireClasse => 'A student leaves one of your classes.';
	@override String get creneauChange => 'The class schedule has changed.';
	@override String changementHeureUn({required Object date, required Object cours, required Object jour, required Object avant, required Object apres}) => 'From ${date}, ${cours} on ${jour} moves from ${avant} to ${apres}.';
	@override String changementHeurePlusieurs({required Object date, required Object cours, required Object liste}) => 'From ${date}, the time ${cours} changes: ${liste}.';
	@override String changementHeureUnJour({required Object date, required Object cours, required Object jourAvant, required Object avant, required Object jourApres, required Object apres}) => 'From ${date}, ${cours} moves from ${jourAvant} ${avant} to ${jourApres} ${apres}.';
	@override String changementHeureLigneJour({required Object jourAvant, required Object avant, required Object jourApres, required Object apres}) => 'from ${jourAvant} ${avant} to ${jourApres} ${apres}';
	@override String get changementHeureMecque => 'The class stays at the same time in Makkah: it is your city\'s time that changes.';
	@override String conversionRefusee({required Object classe, required Object raison}) => 'Class ${classe} could not move to Makkah time: ${raison} It will be retried tonight.';
	@override String get conversionRefuseeProche => 'a time change is approaching (less than 28 days).';
	@override String get conversionRefuseeDemiHeure => 'one of its slots has no whole hour in Makkah.';
	@override String get conversionRefuseeAutre => 'a check failed, see the class.';
	@override String changementHeureLigne({required Object jour, required Object avant, required Object apres}) => 'on ${jour} from ${avant} to ${apres}';
	@override String get changementHeureCoursUn => 'your class';
	@override String get changementHeureCoursUnFoyer => 'the class';
	@override String get changementHeureCoursPlusieurs => 'your classes';
	@override String get changementHeureCoursPlusieursFoyer => 'the classes';
	@override String get seanceAnnulee => 'A session is cancelled.';
	@override String seanceAnnuleeQuand({required Object quand}) => 'The session of ${quand} is cancelled.';
	@override String get seanceDeplacee => 'A session is moved.';
	@override String seanceDeplaceeQuand({required Object quand}) => 'A session is moved to ${quand}.';
	@override String get enseignanteAbsente => 'The teacher will be absent from a session. A replacement is being sought.';
	@override String enseignanteAbsenteQuand({required Object quand}) => 'The teacher will be absent from the session of ${quand}. A replacement is being sought.';
	@override String get remplacementAvertissement => 'You are not in the room yet. Join quickly: otherwise you lose access to today\'s session.';
	@override String remplacementAvertissementMinutes({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(minutes,
		one: 'You are not in the room yet. Join within the minute: otherwise you lose access to today\'s session.',
		other: 'You are not in the room yet. Join within ${minutes} minutes: otherwise you lose access to today\'s session.',
	);
	@override String get remplacementPreAlerte => 'A replacement is being prepared: a teacher is not yet in their room. Declare yourself ready in Replacements.';
	@override String get remplacementInutile => 'The replacement is no longer needed: the class teacher has arrived. Thank you for being ready.';
	@override String get titulaireEnRetard => 'The class teacher is late. The academy is looking for a replacement: stay in the room.';
	@override String get titulaireEnRetardDirection => 'A class teacher has not entered their room. A replacement is being sought: see the schedule.';
	@override String get remplacantArrive => 'A replacement is arriving: stay in the room.';
	@override String get classeSupprimee => 'The class is closed.';
	@override String get classeSupprimeeSoi => 'Your class is closed.';
	@override String get classeSupprimeeFoyer => 'The class of a student in your household is closed.';
	@override String get classeSupprimeeClasse => 'One of your classes is closed.';
	@override String get seanceTerminee => 'A session has ended.';
	@override String seanceTermineeDe({required Object deClasse, required Object quand}) => 'The session ${deClasse} of ${quand} has ended.';
	@override String seanceTermineeTravail({required Object travail}) => 'Work to prepare: ${travail}';
	@override String get seanceTermineeAucunTravail => 'No work to prepare.';
	@override String seanceTermineePresents({required num n, required Object total}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} student present out of ${total}.',
		other: '${n} students present out of ${total}.',
	);
	@override String get seanceTermineeCahierAttend => 'The handover notebook is waiting for your information.';
	@override String get seanceTermineeCahierDepose => 'Notebook submitted, thank you.';
	@override String seanceTermineePhrases({required Object premiere, required Object suite}) => '${premiere} ${suite}';
	@override String get inconnu => 'This notification needs a more recent version of the app. Reload the page to read it.';
}

// Path: notifications.filtres
class _Traductions$notifications$filtres$en extends Traductions$notifications$filtres$fr {
	_Traductions$notifications$filtres$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Filter notifications';
	@override String get toutes => 'All';
	@override String get nonLues => 'Unread';
}

// Path: notifications.detail
class _Traductions$notifications$detail$en extends Traductions$notifications$detail$fr {
	_Traductions$notifications$detail$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String recue({required Object date, required Object heure}) => 'Received on ${date} at ${heure}';
	@override String get ouvrir => 'Open the page concerned';
}

// Path: notifications.types
class _Traductions$notifications$types$en extends Traductions$notifications$types$fr {
	_Traductions$notifications$types$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get annonceClasse => 'Class announcement';
	@override String get changementSeance => 'Session change';
	@override String get decisionDossier => 'Decision on a file';
	@override String get messageMetier => 'Message';
	@override String get reponseAttendue => 'Reply expected';
	@override String get accesFinance => 'Access and payments';
	@override String get observation => 'Observation';
	@override String get travailRessource => 'Work or resource';
	@override String get annonceDirection => 'Announcement from the management';
	@override String get changementPlanning => 'Schedule change';
	@override String get remplacement => 'Replacement';
	@override String get mentionCommunaute => 'Mention in the Community';
	@override String get reponseCommunaute => 'Reply in the Community';
	@override String get messageAdministration => 'Message from the Administration';
	@override String get dossierATraiter => 'File to handle';
	@override String get signalementCommunaute => 'Report in the Community';
	@override String get reponseFil => 'Reply in a conversation';
	@override String get annoncePlanifiee => 'Scheduled announcement to publish';
	@override String get evenementOperationnel => 'Academy event';
	@override String get mission => 'Mission';
	@override String get changementMission => 'Mission change';
	@override String get reponseAdministration => 'Reply from the Administration';
	@override String get mentionStudio => 'Mention in The Studio';
	@override String get reponseStudio => 'Reply in The Studio';
	@override String get decisionDemandee => 'Decision requested';
	@override String get elementAssigne => 'Assigned item';
	@override String get annonceInterne => 'Internal announcement';
	@override String get evenementContextuel => 'Event';
	@override String get autre => 'Notification';
}

// Path: eleve.accueil
class _Traductions$eleve$accueil$en extends Traductions$eleve$accueil$fr {
	_Traductions$eleve$accueil$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get rejoindre => 'Join';
	@override String get coran => 'The Quran';
	@override String get coranDetail => 'To read whenever you want';
	@override String get coranEcouter => 'Listen: The Quran';
	@override String get prochainCours => 'Next class';
	@override String get coursEnDirect => 'Your class has started';
	@override String avec({required Object prenom}) => 'With ${prenom}';
	@override String dansMinutes({required Object minutes}) => 'In ${minutes} min';
	@override String dansHeures({required Object heures, required Object minutes}) => 'In ${heures} h ${minutes}';
	@override String demainA({required Object heure}) => 'Tomorrow at ${heure}';
	@override String dansJours({required num jours}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(jours,
		one: 'In ${jours} day',
		other: 'In ${jours} days',
	);
	@override String get imminent => 'It is almost time';
	@override String get aucunCours => 'No class today';
	@override String get aucunCoursDetail => 'Your teacher is preparing the next one.';
	@override String get erreurCours => 'Your classes could not be loaded. Try again in a moment.';
	@override String get erreurCoursHorsLigneTitre => 'Your classes are not available';
	@override String get prochainAujourdhui => 'Your next class is later today.';
	@override String get prochainDemain => 'Your next class is tomorrow.';
	@override String get annulee => 'This class will not take place';
	@override String get horsLigne => 'Entry pending';
	@override String get horsLigneDetail => 'You will be able to enter as soon as the network is back.';
	@override String get pausePriere => 'Prayer break';
	@override String pausePriereDetail({required Object heure}) => 'At ${heure}';
	@override String prochainDansJours({required num jours}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(jours,
		one: 'Your next class is in ${jours} day.',
		other: 'Your next class is in ${jours} days.',
	);
	@override String get entreeSePrepare => 'Your entry is getting ready. Try again in a moment.';
}

// Path: eleve.coran
class _Traductions$eleve$coran$en extends Traductions$eleve$coran$fr {
	_Traductions$eleve$coran$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'The Quran';
	@override String juz({required Object juz}) => 'Juz ${juz}';
	@override String get mecquoise => 'Revealed in Makkah';
	@override String get medinoise => 'Revealed in Madinah';
	@override String get reprendre => 'Resume your reading';
	@override String reprendreDetail({required Object page}) => 'You were on page ${page}';
	@override String get chargement => 'The text is on its way';
	@override String get indisponible => 'The text could not be loaded';
	@override String get indisponibleDetail => 'As soon as the network is back, your page reopens here.';
	@override String get reessayer => 'Try again';
	@override String get absent => 'This page is empty';
	@override String get absentDetail => 'The text has not been installed on this page. Report it: it is not you.';
	@override String get pagePrecedente => 'Previous page';
	@override String get pageSuivante => 'Next page';
	@override String get reglages => 'Reading settings';
	@override String get fermerReglages => 'Close the settings';
	@override String get taille => 'Text size';
	@override String get agrandir => 'Enlarge the text';
	@override String get reduire => 'Reduce the text';
	@override String get source => 'Quran text: Tanzil Project';
	@override String get sourceLien => 'tanzil.net';
	@override String get edition => 'Madinah Mushaf, Hafs riwaya';
}

// Path: eleve.suivi
class _Traductions$eleve$suivi$en extends Traductions$eleve$suivi$fr {
	_Traductions$eleve$suivi$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get colonneDate => 'Date';
	@override String get colonneCours => 'Class';
	@override String get colonneEnseignant => 'Teacher';
	@override String get colonneEtat => 'Attendance';
	@override String get cours => 'Quran class';
	@override String get moi => 'My attendance';
	@override String aujourdhui({required Object heure}) => 'Today, ${heure}';
	@override String hier({required Object heure}) => 'Yesterday, ${heure}';
	@override String date({required Object date, required Object heure}) => '${date}, ${heure}';
	@override String get annule => 'Class cancelled';
	@override String get nonTenu => 'Class not held';
	@override String get vide => 'No class yet';
	@override String get videDetail => 'Your classes will appear here, from the most recent to the oldest, with your attendance.';
	@override String get erreur => 'The tracking could not be loaded. Try again in a moment.';
	@override String tronquee({required Object nombre}) => 'The ${nombre} most recent classes are shown.';
	@override String fin({required Object nombre}) => '${nombre} classes in the tracking.';
	@override String get finUn => '1 class in the tracking.';
}

// Path: tuteur.accueil
class _Traductions$tuteur$accueil$en extends Traductions$tuteur$accueil$fr {
	_Traductions$tuteur$accueil$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Home';
	@override String get voirLaClasse => 'See the class';
	@override String get prochaineSeance => 'Next session';
	@override String heureDe({required Object deVille}) => '${deVille} time';
	@override String get heureAppareil => 'This device\'s time';
	@override String dateEtFuseau({required Object date, required Object fuseau}) => '${date} · ${fuseau}';
	@override String heureClasse({required Object heure, required Object ville}) => 'Class time: ${heure} ${ville}';
	@override String get seanceEnDirect => 'Live session';
	@override String get seanceTerminee => 'Session ended';
	@override String get seanceAnnulee => 'This session will not take place.';
	@override String get seanceNonTenue => 'This session could not be held.';
	@override String get horaireIncertain => 'Room opening not confirmed for now';
	@override String horaireIncertainAvant({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'The join button will appear ${n} minute before the start.',
		other: 'The join button will appear ${n} minutes before the start.',
	);
	@override String get horaireIncertainPendant => 'We cannot verify whether the room is open. Reload the page.';
	@override String get pastilleAnnulee => 'Cancelled';
	@override String get pastilleNonTenue => 'Not held';
	@override String get pastilleTerminee => 'Ended';
	@override String get aucuneSeance => 'No session planned';
	@override String aucuneSeanceDetail({required Object dePrenom}) => '${dePrenom}\'s next session will appear here as soon as it is scheduled.';
	@override String get seanceIllisible => 'The next session could not be loaded.';
	@override String get classeIndisponible => 'The class details are not yet available here.';
	@override String get classeIllisible => 'The class could not be loaded.';
	@override String sansClasseTitre({required Object prenom}) => 'No class for ${prenom}';
	@override String sansClassePhrase({required Object quePrenom}) => 'Choose a class so ${quePrenom} can start classes.';
	@override String financesTitre({required Object dePrenom}) => '${dePrenom}\'s finances';
	@override String get financesPhrase => 'Balance, next debit and what remains to be funded.';
	@override String get foyerVideTitre => 'No student profile yet';
	@override String get foyerVidePhrase => 'Add a student profile to choose a class and follow their sessions.';
	@override String get ouvrirEspaceEleve => 'Open my student space';
	@override late final _Traductions$tuteur$accueil$autreAppareilFeuille$en autreAppareilFeuille = _Traductions$tuteur$accueil$autreAppareilFeuille$en._(_root);
	@override String get autreAppareil => 'Use another device';
	@override String get ajouterProfil => 'Add a student profile';
	@override String get profilsIllisibles => 'The household profiles could not be loaded.';
	@override String blocageAppareilTitre({required Object prenom}) => 'No device ready for ${prenom}';
	@override String blocageAppareilPhrase({required Object prenom}) => 'Without a connected device, ${prenom} will not be able to join class.';
	@override String get connecterAppareil => 'Connect a device';
	@override String get avantProchainCours => 'Before the next class';
	@override String get voirTout => 'See all';
	@override String get travailIndisponible => 'The work to prepare is not yet linked to this space.';
	@override String get travailIllisible => 'The work to prepare could not be loaded.';
	@override String get rienAPreparer => 'Nothing to prepare for now';
	@override String get derniereSeance => 'Last session';
	@override String get voirHistorique => 'See the history';
	@override String get detailsSeance => 'Session details';
	@override String get aucuneDerniere => 'No past session yet';
	@override String get derniereIllisible => 'The last session could not be loaded.';
	@override String dateEtDuree({required Object date, required Object duree}) => '${date} · ${duree}';
	@override late final _Traductions$tuteur$accueil$etatCourt$en etatCourt = _Traductions$tuteur$accueil$etatCourt$en._(_root);
	@override String get assister => 'Observe';
	@override String get assisterRefuse => 'The class could not be joined. It may have just ended.';
	@override String enCours({required Object prenom}) => 'In progress with ${prenom}';
	@override String depuisMinutes({required Object minutes}) => 'Started ${minutes} min ago';
	@override String get depuisInstant => 'Just started';
	@override String aujourdhui({required Object heure, required Object prenom}) => 'Today at ${heure}, with ${prenom}';
	@override String unAutreJour({required Object jour, required Object heure, required Object prenom}) => '${jour} at ${heure}, with ${prenom}';
	@override String get rienAujourdhui => 'Nothing today';
	@override String get aucunCoursPrevu => 'No class scheduled yet';
	@override String get aucunCoursPrevuDetail => 'The week\'s classes are prepared in advance. This one will appear here.';
	@override String get enRecherche => 'Looking for a teacher';
	@override String enRechercheDepuis({required Object date}) => 'Request submitted on ${date}';
	@override String enRechercheSansDate({required Object prenom}) => 'A teacher will take ${prenom} on from the times offered.';
	@override String sansCreneau({required Object prenom}) => 'No times offered for ${prenom}';
	@override String sansCreneauDetail({required Object prenom}) => 'Without a slot, no teacher can take ${prenom} on.';
	@override String get poserDesHeures => 'Offer times';
	@override String annulee({required Object heure}) => 'The ${heure} class will not take place';
	@override String get motifAnnulee => 'Session cancelled';
	@override String get motifAnnuleeTard => 'Session cancelled shortly before the start time';
	@override String proposeApres({required Object jour, required Object heure}) => 'Next class ${jour} at ${heure}';
	@override String get proposeAucun => 'A new class will be offered to you.';
	@override String get gererLeFoyer => 'Manage the household';
	@override String get blocAppareils => 'Household devices';
	@override String get blocAppareilsDetail => 'Add a device, or remove one.';
	@override String get blocReglages => 'Settings per child';
	@override String get blocReglagesDetail => 'Photo, camera and display, child by child.';
	@override String get blocGroupesDetail => 'Each child\'s class, teacher and next class.';
	@override String get acces => 'Access';
	@override String get aucunEnfant => 'No child in the household';
	@override String get aucunEnfantDetail => 'Add your first child to get started.';
	@override String get erreur => 'The household could not be loaded completely. Try again in a moment.';
}

// Path: classe.entree
class _Traductions$classe$entree$en extends Traductions$classe$entree$fr {
	_Traductions$classe$entree$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String coursDans({required Object duree}) => 'Class in ${duree}';
	@override String get coursImminent => 'Class in less than a minute';
	@override String coursDemainA({required Object heure}) => 'Class tomorrow at ${heure}';
	@override String coursDansJours({required num jours}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(jours,
		one: 'Class in ${jours} day',
		other: 'Class in ${jours} days',
	);
	@override String get revenirAvant => 'This class is not open to you right now. Come back 20 minutes before the class time.';
	@override String get rejoindre => 'Join';
	@override String rejoindreLecteur({required Object deClasse}) => 'Join ${deClasse}\'s session';
	@override String salleOuverte({required Object duree}) => 'The room is open. The session starts in ${duree}.';
	@override String get salleOuverteImminent => 'The room is open. The session starts in less than a minute.';
	@override String get preparation => 'Getting ready';
	@override String attente({required Object duree}) => 'You are in the room. The session starts in ${duree}.';
	@override String get attenteImminent => 'You are in the room. The session starts in less than a minute.';
	@override String get enDirect => 'Live session';
	@override String get tempsEcoule => 'Scheduled time elapsed';
	@override String get terminee => 'Session ended';
	@override String get annulee => 'Session cancelled';
	@override String get aucune => 'No session planned';
	@override String get horsLigne => 'You will be able to join the session as soon as the connection is back.';
	@override String get indisponible => 'The session information could not be loaded: the request may not have reached Rewayah. Try again in a moment.';
	@override String get indisponibleCourt => 'The session information could not be loaded';
	@override String get indisponibleInvitation => 'The request may not have reached Rewayah. Try again in a moment.';
	@override String get accesInverifiable => 'Access to the room cannot be verified right now.';
	@override String get reessayer => 'Try again';
	@override String get chargementSeance => 'Loading the next session.';
	@override String progressionValeur({required Object chapitre, required Object pourcentage}) => '${chapitre} · ${pourcentage}%';
	@override String dst({required Object avant, required Object apres}) => 'Time change: the class will move from ${avant} to ${apres}.';
	@override late final _Traductions$classe$entree$annonce$en annonce = _Traductions$classe$entree$annonce$en._(_root);
	@override late final _Traductions$classe$entree$demo$en demo = _Traductions$classe$entree$demo$en._(_root);
}

// Path: classe.seance
class _Traductions$classe$seance$en extends Traductions$classe$seance$fr {
	_Traductions$classe$seance$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get aucune => 'No session planned';
	@override String aucuneDetail({required Object dePrenom}) => '${dePrenom}\'s next session will appear here as soon as it is scheduled.';
	@override String get illisible => 'The next session could not be loaded.';
	@override String presence({required Object prenom, required Object etat}) => '${prenom}: ${etat}';
	@override String rejoindreAvec({required Object prenom}) => 'Join the room with ${prenom}';
	@override String salleOuvreA({required Object heure}) => 'The room opens at ${heure}.';
}

// Path: classe.observation
class _Traductions$classe$observation$en extends Traductions$classe$observation$fr {
	_Traductions$classe$observation$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get commentCaMarche => 'How does it work?';
	@override String get uneVisite => '1 visit available';
	@override String resume({required Object visites, required Object duree}) => '${visites} · ${duree} per visit';
	@override String get restanteAucune => 'No visit left for this session';
	@override String get restanteUne => '1 visit left for this session';
	@override String minutesSecondes({required Object minutes, required Object secondes}) => '${minutes} min ${secondes} s';
	@override String secondes({required Object secondes}) => '${secondes} s';
	@override late final _Traductions$classe$observation$motif$en motif = _Traductions$classe$observation$motif$en._(_root);
	@override String visites({required num nombre}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(nombre,
		one: '${nombre} visit available',
		other: '${nombre} visits available',
	);
	@override String restantes({required num nombre}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(nombre,
		one: '${nombre} visit left for this session',
		other: '${nombre} visits left for this session',
	);
}

// Path: classe.pagePlanning
class _Traductions$classe$pagePlanning$en extends Traductions$classe$pagePlanning$fr {
	_Traductions$classe$pagePlanning$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get prochaines => 'Upcoming sessions';
	@override String ligne({required Object heure, required Object duree}) => '${heure} · ${duree}';
	@override String ligneFuseau({required Object heure, required Object fuseau, required Object duree}) => '${heure} (${fuseau}) · ${duree}';
	@override String get aucune => 'No upcoming session for now';
	@override String aucuneDetail({required Object dePrenom}) => '${dePrenom}\'s next sessions will appear here as soon as they are scheduled.';
	@override String get habituelIndisponible => 'The class\'s usual days are not shown here yet: only sessions already scheduled appear.';
	@override String get indisponible => 'The class schedule is not yet linked to this space.';
}

// Path: classe.pageTravail
class _Traductions$classe$pageTravail$en extends Traductions$classe$pageTravail$fr {
	_Traductions$classe$pageTravail$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get aucun => 'Nothing to prepare for now';
	@override String get aucunDetail => 'The work given by the teacher will appear here.';
	@override String get indisponible => 'The work to prepare is not yet linked to this space.';
	@override String echeance({required Object date}) => 'Due: ${date}';
	@override String get nonCochable => 'Marking work as done is not yet possible here.';
	@override late final _Traductions$classe$pageTravail$statut$en statut = _Traductions$classe$pageTravail$statut$en._(_root);
}

// Path: classe.pageRessources
class _Traductions$classe$pageRessources$en extends Traductions$classe$pageRessources$fr {
	_Traductions$classe$pageRessources$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get aucune => 'No resources for this class yet';
	@override String get aucuneDetail => 'The materials chosen by the teacher will appear here.';
	@override String get indisponible => 'The class library is not yet linked to this space.';
}

// Path: classe.pageProgression
class _Traductions$classe$pageProgression$en extends Traductions$classe$pageProgression$fr {
	_Traductions$classe$pageProgression$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String indisponible({required Object dePrenom}) => '${dePrenom}\'s progress is not shared here yet.';
	@override String get niveau => 'Level';
	@override String get jalons => 'Stages completed';
	@override String get aucune => 'No stage shared yet';
	@override String get aucuneDetail => 'The progress the teacher shares with the family will appear here.';
}

// Path: classe.cartes
class _Traductions$classe$cartes$en extends Traductions$classe$cartes$fr {
	_Traductions$classe$cartes$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Class cards';
	@override String get contexteEnseignant => 'Tap a card to edit it. Students and their families see it immediately.';
	@override String get modificationPlusTard => 'Cards can be edited when the connection is back.';
	@override String get aucune => 'No cards yet';
	@override String get aucuneDetail => 'The class teacher will post useful information here.';
	@override String get aucuneEnseignant => 'No cards yet. Add one: the class will see it immediately.';
	@override String get ajouter => 'Add a card';
	@override String limite({required Object max}) => '${max} cards at most: remove one to add another.';
	@override String modifierLecteur({required Object titre}) => 'Edit the card "${titre}"';
	@override String echeance({required Object date}) => 'Due: ${date}';
	@override String copierLien({required Object titre}) => 'Copy the link for "${titre}"';
	@override String get copierLienCourt => 'Copy the link';
	@override String get lienCopie => 'Link copied. Paste it into your browser to open it.';
	@override String get indisponibleTitre => 'Class cards are not open yet';
	@override String get indisponiblePhrase => 'They will appear here as soon as they open. Nothing to do on your side.';
	@override String get erreurLecture => 'The class cards could not be loaded. Try again in a moment.';
	@override String get sansDonnees => 'The class cards could not be loaded';
	@override String get enregistree => 'Card saved. The class sees it now.';
	@override String get retiree => 'Card removed. The class no longer sees it.';
	@override late final _Traductions$classe$cartes$types$en types = _Traductions$classe$cartes$types$en._(_root);
	@override late final _Traductions$classe$cartes$typesDetail$en typesDetail = _Traductions$classe$cartes$typesDetail$en._(_root);
	@override late final _Traductions$classe$cartes$modeles$en modeles = _Traductions$classe$cartes$modeles$en._(_root);
	@override late final _Traductions$classe$cartes$feuille$en feuille = _Traductions$classe$cartes$feuille$en._(_root);
}

// Path: suiviFamille.etapes
class _Traductions$suiviFamille$etapes$en extends Traductions$suiviFamille$etapes$fr {
	_Traductions$suiviFamille$etapes$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get envoyee => 'Request sent';
	@override String get enAttente => 'On the waiting list';
	@override String get classeCreee => 'Class created';
	@override String get enseignantAffecte => 'Teacher assigned';
	@override String get eleveIntegre => 'Student placed';
	@override String get premiereSeance => 'First session';
}

// Path: suiviFamille.etats
class _Traductions$suiviFamille$etats$en extends Traductions$suiviFamille$etats$fr {
	_Traductions$suiviFamille$etats$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get fait => 'Done';
	@override String get enCours => 'In progress';
	@override String get aVenir => 'Upcoming';
}

// Path: suiviFamille.motif
class _Traductions$suiviFamille$motif$en extends Traductions$suiviFamille$motif$fr {
	_Traductions$suiviFamille$motif$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get classesPleines => 'All classes for this slot are full. You will be notified as soon as a place opens.';
	@override String get aucunEnseignantLibre => 'No teacher is free for this slot for now. You will be notified as soon as that changes.';
	@override String get inconnu => 'Your request is pending. You will be notified as soon as it moves forward.';
}

// Path: suiviFamille.intervalle
class _Traductions$suiviFamille$intervalle$en extends Traductions$suiviFamille$intervalle$fr {
	_Traductions$suiviFamille$intervalle$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get moinsHeure => 'Less than an hour later';
	@override String heures({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} hour later',
		other: '${n} hours later',
	);
	@override String jours({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} day later',
		other: '${n} days later',
	);
}

// Path: suiviFamille.notification
class _Traductions$suiviFamille$notification$en extends Traductions$suiviFamille$notification$fr {
	_Traductions$suiviFamille$notification$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String enAttente({required Object dePrenom}) => '${dePrenom}\'s request: on the waiting list';
	@override String eleveIntegre({required Object dePrenom}) => '${dePrenom}\'s request: student placed in the class';
	@override String premiereSeance({required Object dePrenom}) => '${dePrenom}\'s request: first session held';
	@override String close({required Object dePrenom, required Object motif}) => '${dePrenom}\'s request: ${motif}';
	@override String dejaEnClasse({required Object dePrenom}) => '${dePrenom}\'s request: student already in a class, request filed';
}

// Path: suiviFamille.close
class _Traductions$suiviFamille$close$en extends Traductions$suiviFamille$close$fr {
	_Traductions$suiviFamille$close$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get etat => 'Request closed';
	@override String suite({required Object prenom}) => 'You can choose another slot for ${prenom}.';
	@override String get suiteSansChoix => 'Nothing else to do on your side.';
	@override String choisirAutre({required Object prenom}) => 'Choose another slot for ${prenom}';
	@override late final _Traductions$suiviFamille$close$motif$en motif = _Traductions$suiviFamille$close$motif$en._(_root);
}

// Path: suiviDemandes.etapes
class _Traductions$suiviDemandes$etapes$en extends Traductions$suiviDemandes$etapes$fr {
	_Traductions$suiviDemandes$etapes$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get envoyee => 'Request sent';
	@override String get classeValidee => 'Class approved';
	@override String get enseignantAffecte => 'Teacher assigned';
	@override String get listeAttente => 'On the waiting list';
	@override String get eleveIntegre => 'Student placed in the class';
	@override String get coursCommences => 'Classes start';
}

// Path: suiviDemandes.etats
class _Traductions$suiviDemandes$etats$en extends Traductions$suiviDemandes$etats$fr {
	_Traductions$suiviDemandes$etats$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get fait => 'Done';
	@override String get enCours => 'In progress';
	@override String get prochaine => 'Next step';
	@override String get aVenir => 'Upcoming';
}

// Path: suiviDemandes.situation
class _Traductions$suiviDemandes$situation$en extends Traductions$suiviDemandes$situation$fr {
	_Traductions$suiviDemandes$situation$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get envoyee => 'Your request has reached the administration';
	@override String get classeValidee => 'Your class is ready: it is waiting for its teacher';
	@override String get enseignantAffecte => 'Class approved · teacher assigned';
	@override String get listeAttente => 'Your request is on the waiting list';
	@override String get eleveIntegre => 'Class approved · teacher assigned · student placed';
	@override String get coursCommences => 'Classes have started';
}

// Path: suiviDemandes.prochaine
class _Traductions$suiviDemandes$prochaine$en extends Traductions$suiviDemandes$prochaine$fr {
	_Traductions$suiviDemandes$prochaine$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get envoyee => 'Next step: forming the class';
	@override String get classeValidee => 'Next step: the class teacher is appointed. We will let you know as soon as it is done.';
	@override String get listeAttente => 'We will let you know as soon as a place opens. No date is announced until it is known.';
	@override String get eleveIntegre => 'Next step: classes start';
}

// Path: suiviDemandes.close
class _Traductions$suiviDemandes$close$en extends Traductions$suiviDemandes$close$fr {
	_Traductions$suiviDemandes$close$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get retiree => 'Request withdrawn';
	@override String get nonRetenue => 'Request not accepted';
	@override String get close => 'Request closed';
	@override late final _Traductions$suiviDemandes$close$motif$en motif = _Traductions$suiviDemandes$close$motif$en._(_root);
	@override String get suite => 'You can choose another slot among those offered.';
	@override String get suiteSansChoix => 'No other slot is offered for now. Come back to this page later.';
	@override String choisirAutre({required Object prenom}) => 'Choose another slot for ${prenom}';
}

// Path: suiviDemandes.accueil
class _Traductions$suiviDemandes$accueil$en extends Traductions$suiviDemandes$accueil$fr {
	_Traductions$suiviDemandes$accueil$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Your time slot requests';
	@override String ligne({required Object prenom, required Object etat}) => '${prenom}: ${etat}';
	@override String get voir => 'See the tracking of requests';
}

// Path: suiviDemandes.notification
class _Traductions$suiviDemandes$notification$en extends Traductions$suiviDemandes$notification$fr {
	_Traductions$suiviDemandes$notification$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String envoyee({required Object dePrenom}) => '${dePrenom}\'s time slot request: your request has reached the administration';
	@override String classeValidee({required Object dePrenom}) => '${dePrenom}\'s time slot request: your class is ready, it is waiting for its teacher';
	@override String enseignantAffecte({required Object dePrenom}) => '${dePrenom}\'s time slot request: class approved · teacher assigned';
	@override String close({required Object dePrenom, required Object motif}) => '${dePrenom}\'s time slot request: ${motif}';
	@override String listeAttente({required Object dePrenom}) => '${dePrenom}\'s time slot request: your request is on the waiting list';
	@override String eleveIntegre({required Object dePrenom}) => '${dePrenom}\'s time slot request: student placed in the class';
	@override String coursCommences({required Object dePrenom}) => '${dePrenom}\'s time slot request: classes have started';
	@override String dejaEnClasse({required Object dePrenom}) => '${dePrenom}\'s time slot request: student already in a class, request filed';
	@override String changementFusion({required Object dePrenom}) => '${dePrenom}\'s time slot request: your class was merged with another, see the new class';
	@override String changementTransfert({required Object dePrenom}) => '${dePrenom}\'s time slot request: new class, see the details';
}

// Path: suiviDemandes.jalon
class _Traductions$suiviDemandes$jalon$en extends Traductions$suiviDemandes$jalon$fr {
	_Traductions$suiviDemandes$jalon$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String apres({required Object date, required Object heure, required Object duree}) => '${date} at ${heure}, ${duree}';
	@override String get aussitot => 'immediately';
	@override String minutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} minute later',
		other: '${n} minutes later',
	);
	@override String heures({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} hour later',
		other: '${n} hours later',
	);
	@override String jours({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} day later',
		other: '${n} days later',
	);
}

// Path: suiviDemandes.changement
class _Traductions$suiviDemandes$changement$en extends Traductions$suiviDemandes$changement$fr {
	_Traductions$suiviDemandes$changement$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titrePage => 'Class change';
	@override String titre({required Object dePrenom}) => '${dePrenom}\'s class has changed';
	@override String fusion({required Object prenom}) => 'Your class was merged with another. ${prenom} now has the class below.';
	@override String transfert({required Object prenom}) => 'The management moved ${prenom} to another class. Here is the new class.';
	@override String get classe => 'New class';
	@override String get enseignant => 'Teacher';
	@override String get sansEnseignant => 'Their teacher will be announced as soon as one is appointed.';
	@override String get date => 'Change made on';
	@override String get lien => 'See the new class';
	@override String lienPour({required Object dePrenom}) => 'See ${dePrenom}\'s new class';
	@override String get retour => 'Back to the tracking of requests';
	@override String get introuvable => 'This class change no longer needs to be shown';
	@override String get introuvableDetail => 'Go back to the tracking to see where your requests stand.';
}

// Path: juridique.coord
class _Traductions$juridique$coord$en extends Traductions$juridique$coord$fr {
	_Traductions$juridique$coord$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get societe => 'Company: Rewayah Academy Ltd';
	@override String get numero => 'Registration number: 16624644, England and Wales';
	@override String get adresse => 'Registered office: 71-75 Shelton Street, Covent Garden, London WC2H 9JQ, United Kingdom';
}

// Path: accueilInvite.roles
class _Traductions$accueilInvite$roles$en extends Traductions$accueilInvite$roles$fr {
	_Traductions$accueilInvite$roles$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get foyer => 'Rewayah Academy invites you as a guardian.';
	@override String get enseignant => 'Rewayah Academy invites you as a teacher.';
	@override String get comptable => 'Rewayah Academy invites you as an accountant.';
	@override String get candidat => 'Rewayah Academy invites you as a teaching applicant.';
}

// Path: suiviAttente.tu
class _Traductions$suiviAttente$tu$en extends Traductions$suiviAttente$tu$fr {
	_Traductions$suiviAttente$tu$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get formationListeAttente => 'All classes for this slot are full. Your request is waiting for a place to open.';
	@override String get confirmeeFait => 'Your class is confirmed.';
	@override String confirmeeFaitNom({required Object classe}) => 'Your class "${classe}" is confirmed.';
	@override String get enseignantEnAttente => 'Your class is waiting for its teacher. The academy appoints one and lets you know.';
	@override String get pretEnCours => 'The academy is setting your first class. It lets you know as soon as the date is known.';
	@override String get pretAVenir => 'Your first class is announced once the teacher is assigned.';
	@override String premierCoursPasse({required Object quand}) => 'Your first class took place on ${quand}.';
	@override String get premierCoursPetit => 'Your first class is coming. Your guardian will tell you when.';
	@override String get premierCoursPassePetit => 'Your first class took place.';
	@override String get depasse => 'Forming your class is taking longer than expected.';
	@override String changement({required Object date}) => 'The class slot changed on ${date}. Your guardian received the notice.';
	@override String get titreRefusee => 'Your request was not accepted';
	@override String get retraitFamille => 'Your guardian withdrew this request.';
	@override String get erreur => 'We could not read your request. This is often caused by the connection. Try again in a moment.';
	@override String get sansDonnees => 'Your request could not be loaded';
	@override String get introuvable => 'This request no longer exists.';
}

// Path: suiviAttente.etapes
class _Traductions$suiviAttente$etapes$en extends Traductions$suiviAttente$etapes$fr {
	_Traductions$suiviAttente$etapes$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get recue => 'Request received';
	@override String get formation => 'Class being formed';
	@override String get confirmee => 'Class confirmed';
	@override String get enseignant => 'Teacher assigned';
	@override String get pret => 'All set';
}

// Path: suiviAttente.etats
class _Traductions$suiviAttente$etats$en extends Traductions$suiviAttente$etats$fr {
	_Traductions$suiviAttente$etats$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get fait => 'Done';
	@override String get enCours => 'In progress';
	@override String get aVenir => 'Upcoming';
}

// Path: suiviAttente.dit
class _Traductions$suiviAttente$dit$en extends Traductions$suiviAttente$dit$fr {
	_Traductions$suiviAttente$dit$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get recueFait => 'Your request has reached the academy.';
	@override String get recueFaitSimple => 'Your request has reached the academy.';
	@override String get formationEnCours => 'The academy is bringing together the students of this class.';
	@override String get formationListeAttente => 'All classes for this slot are full. Your request is waiting for a place to open.';
	@override String get formationFait => 'The students of the class have been brought together.';
	@override String get formationAVenir => 'The academy brings the class students together once the request is received.';
	@override String get confirmeeFait => 'Your class is confirmed.';
	@override String confirmeeFaitNom({required Object classe}) => 'Your class "${classe}" is confirmed.';
	@override String get confirmeeAVenir => 'The academy confirms the class when its students are brought together.';
	@override String get enseignantEnCours => 'The academy is appointing the class teacher.';
	@override String get enseignantEnAttente => 'Your class is waiting for its teacher. The academy appoints one and lets you know.';
	@override String get enseignantFait => 'Your teacher is known.';
	@override String get enseignantFaitSimple => 'Your teacher is known.';
	@override String get enseignantAVenir => 'The academy appoints the teacher once the class is confirmed.';
	@override String get pretFait => 'The class, the teacher and the first class are known.';
	@override String get pretEnCours => 'The academy is setting your first class. You are notified as soon as the date is known.';
	@override String get pretAVenir => 'Your first class is announced once the teacher is assigned.';
}

// Path: suiviAttente.delai
class _Traductions$suiviAttente$delai$en extends Traductions$suiviAttente$delai$fr {
	_Traductions$suiviAttente$delai$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get depasse => 'Forming your class is taking longer than expected.';
}

// Path: suiviAttente.cloture
class _Traductions$suiviAttente$cloture$en extends Traductions$suiviAttente$cloture$fr {
	_Traductions$suiviAttente$cloture$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titreRefusee => 'Your request was not accepted';
	@override String get titreRetiree => 'This request is withdrawn';
	@override String get titreClose => 'This request is closed';
	@override late final _Traductions$suiviAttente$cloture$motif$en motif = _Traductions$suiviAttente$cloture$motif$en._(_root);
	@override String get suite => 'You can choose another slot.';
	@override String get autreCreneau => 'Choose another slot';
	@override late final _Traductions$suiviAttente$cloture$simple$en simple = _Traductions$suiviAttente$cloture$simple$en._(_root);
}

// Path: suiviAttente.enseignant
class _Traductions$suiviAttente$enseignant$en extends Traductions$suiviAttente$enseignant$fr {
	_Traductions$suiviAttente$enseignant$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Your teacher';
	@override String get titreSimple => 'Your teacher';
	@override String get sayyid => 'Sayyid';
	@override String get sayyida => 'Sayyida';
	@override String nomPlein({required Object prenom}) => '${prenom}';
	@override String nomAvecTitre({required Object titre, required Object prenom}) => '${titre} ${prenom}';
	@override String get langue => 'Class language';
	@override String get origine => 'Country of origin';
	@override String get residence => 'Country of residence';
	@override String get mot => 'Their introduction';
	@override String get peutSePresenter => 'Your teacher can introduce themselves to the families of the class with a message in Messages.';
}

// Path: suiviAttente.vide
class _Traductions$suiviAttente$vide$en extends Traductions$suiviAttente$vide$fr {
	_Traductions$suiviAttente$vide$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get message => 'You have not chosen a class yet.';
	@override String get invitation => 'Choose a class: the academy then follows you step by step.';
	@override String get action => 'Choose a class';
	@override String get messageSimple => 'There is no class request for you yet.';
	@override String get invitationSimple => 'Your guardian can make one.';
}

// Path: suiviAttente.carte
class _Traductions$suiviAttente$carte$en extends Traductions$suiviAttente$carte$fr {
	_Traductions$suiviAttente$carte$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Your class request';
	@override String get titreSimple => 'Your class request';
	@override String ligne({required Object prenom, required Object n, required Object total, required Object etape}) => '${prenom}: step ${n} of ${total}, ${etape}';
	@override String get suivre => 'Follow my request';
	@override String pret({required Object prenom, required Object quand}) => '${prenom}: all set. First class: ${quand}';
	@override String pretSansDate({required Object prenom}) => '${prenom}: all set.';
}

// Path: suiviAttente.presentation
class _Traductions$suiviAttente$presentation$en extends Traductions$suiviAttente$presentation$fr {
	_Traductions$suiviAttente$presentation$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'What families see of you';
	@override String get phrase => 'The families of your classes already see, as everywhere in the app, your title, first name, class language, photo and country if it is filled in. This setting only concerns the card tracking their request: you choose to also show your two countries and an introduction there, when you have entered them.';
	@override String get montrer => 'Show my countries and my introduction on the tracking card';
	@override String get paysOrigine => 'Country of origin';
	@override String get paysResidence => 'Country of residence';
	@override String get choisirPays => 'Choose a country';
	@override String get nonRenseigne => 'Not provided';
	@override String get mot => 'My introduction';
	@override String get motAide => '500 characters at most. Families read it exactly as you write it.';
	@override String get nonConfirme => 'You have not confirmed this choice yet. Until you do, your countries and your introduction, if entered, are shown on the tracking card.';
	@override String get enregistrer => 'Save';
	@override String get enregistre => 'Saved.';
	@override String get erreur => 'Your choice is not confirmed: it may not have reached Rewayah. Try again in a moment.';
	@override String get effacerPays => 'Do not provide';
}

// Path: suiviAttente.mePresenter
class _Traductions$suiviAttente$mePresenter$en extends Traductions$suiviAttente$mePresenter$fr {
	_Traductions$suiviAttente$mePresenter$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get lien => 'Introduce myself to the families';
	@override String get titre => 'Introduce myself';
	@override String get contexte => 'A message is already written. You can edit it before sending. It goes in Messages, to the families of the class and to adult students.';
	@override String messageSayyid({required Object nom, required Object classe}) => 'Hello, I am Sayyid ${nom}, your teacher for the class "${classe}". I am glad to begin with you. Write to me here if you have a question. See you soon.';
	@override String messageSayyida({required Object nom, required Object classe}) => 'Hello, I am Sayyida ${nom}, your teacher for the class "${classe}". I am glad to begin with you. Write to me here if you have a question. See you soon.';
	@override String get champ => 'Your message';
	@override String get rappel => 'This message is read by the guardians of minor students and by adult students. It is never sent to a minor. Do not exchange phone numbers or addresses: everything goes through the app.';
	@override String get envoyer => 'Send to the families';
	@override String envoye({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'Message sent to ${n} family.',
		other: 'Message sent to ${n} families.',
	);
	@override String dejaEcrit({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} family already has a conversation with you: it does not receive this message.',
		other: '${n} families already have a conversation with you: they do not receive this message.',
	);
	@override String get aucune => 'No family in this class can receive a message right now.';
	@override String get echec => 'The message is not confirmed for some families: it may not have reached them. Try again: those who received it do not receive it twice.';
	@override String get chargement => 'Loading the families of the class';
	@override String get erreur => 'The families of the class could not be loaded. Try again in a moment.';
	@override String get vide => 'Write a message before sending it.';
}

// Path: commun.etats.recharge1
class _Traductions$commun$etats$recharge1$en extends Traductions$commun$etats$recharge1$fr {
	_Traductions$commun$etats$recharge1$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get ouvertureTitre => 'This screen did not open';
	@override String get ouverturePhrase => 'Loading was interrupted. Try again; if it keeps happening, reload the page.';
	@override String get repetePhrase => 'Loading was interrupted again. Reload the page to open this screen: you stay signed in.';
	@override String get versionPhrase => 'Reload the page to open this screen: you stay signed in.';
}

// Path: commun.etats.chargementProlonge
class _Traductions$commun$etats$chargementProlonge$en extends Traductions$commun$etats$chargementProlonge$fr {
	_Traductions$commun$etats$chargementProlonge$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'The connection is taking longer than expected';
	@override String get phrase => 'You can wait a little longer or try again.';
}

// Path: commun.etats.horsLigne
class _Traductions$commun$etats$horsLigne$en extends Traductions$commun$etats$horsLigne$fr {
	_Traductions$commun$etats$horsLigne$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'You are offline';
	@override String get phrase => 'Check your connection. What is already displayed stays available.';
}

// Path: commun.etats.reconnexion
class _Traductions$commun$etats$reconnexion$en extends Traductions$commun$etats$reconnexion$fr {
	_Traductions$commun$etats$reconnexion$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Reconnecting';
	@override String get phrase => 'A new connection attempt is in progress.';
}

// Path: commun.etats.echecServeur
class _Traductions$commun$etats$echecServeur$en extends Traductions$commun$etats$echecServeur$fr {
	_Traductions$commun$etats$echecServeur$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Unable to load this information';
	@override String get phrase => 'Loading did not complete. Try again in a moment.';
}

// Path: commun.etats.introuvable
class _Traductions$commun$etats$introuvable$en extends Traductions$commun$etats$introuvable$fr {
	_Traductions$commun$etats$introuvable$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'This page cannot be found';
	@override String get phrase => 'The link may be incomplete, or the page no longer exists.';
}

// Path: commun.etats.accesRefuse
class _Traductions$commun$etats$accesRefuse$en extends Traductions$commun$etats$accesRefuse$fr {
	_Traductions$commun$etats$accesRefuse$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'You do not have access to this page';
	@override String get phrase => 'This content is not open to your account.';
}

// Path: commun.etats.sessionExpiree
class _Traductions$commun$etats$sessionExpiree$en extends Traductions$commun$etats$sessionExpiree$fr {
	_Traductions$commun$etats$sessionExpiree$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Your session has expired';
	@override String get phrase => 'Sign in again to continue.';
}

// Path: commun.etats.dossierEnAttente
class _Traductions$commun$etats$dossierEnAttente$en extends Traductions$commun$etats$dossierEnAttente$fr {
	_Traductions$commun$etats$dossierEnAttente$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Your file is pending';
	@override String get phrase => 'One step remains before this space opens.';
}

// Path: commun.etats.aucunResultat
class _Traductions$commun$etats$aucunResultat$en extends Traductions$commun$etats$aucunResultat$fr {
	_Traductions$commun$etats$aucunResultat$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'No results';
	@override String get phrase => 'Nothing matches for now.';
}

// Path: commun.etats.permissionRefusee
class _Traductions$commun$etats$permissionRefusee$en extends Traductions$commun$etats$permissionRefusee$fr {
	_Traductions$commun$etats$permissionRefusee$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Permission denied';
	@override String get phrase => 'Without this permission, this feature cannot open. You can change it in your device settings.';
}

// Path: commun.etats.ressourceExpiree
class _Traductions$commun$etats$ressourceExpiree$en extends Traductions$commun$etats$ressourceExpiree$fr {
	_Traductions$commun$etats$ressourceExpiree$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'This content is no longer available';
	@override String get phrase => 'It has been removed, or access to it has ended.';
}

// Path: commun.etats.indisponible
class _Traductions$commun$etats$indisponible$en extends Traductions$commun$etats$indisponible$fr {
	_Traductions$commun$etats$indisponible$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Not available yet';
	@override String get phrase => 'This feature is not open yet.';
}

// Path: commun.etats.actions
class _Traductions$commun$etats$actions$en extends Traductions$commun$etats$actions$fr {
	_Traductions$commun$etats$actions$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get reessayer => 'Try again';
	@override String get retourAccueil => 'Back to home';
	@override String get seConnecter => 'Sign in';
	@override String get seReconnecter => 'Sign in again';
	@override String get voirDossier => 'See my file';
	@override String get reinitialiserFiltres => 'Reset filters';
	@override String get revenir => 'Go back';
}

// Path: inscription.questionnaire.acces
class _Traductions$inscription$questionnaire$acces$en extends Traductions$inscription$questionnaire$acces$fr {
	_Traductions$inscription$questionnaire$acces$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Last step: your access';
	@override String get reponsesGardees => 'Your answers are saved.';
	@override String get resteAcces => 'All that is left is to receive your access link, or to continue with Google.';
}

// Path: foyer.ajout.porte
class _Traductions$foyer$ajout$porte$en extends Traductions$foyer$ajout$porte$fr {
	_Traductions$foyer$ajout$porte$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get sansDonneesTitre => 'The profiles you can add could not be checked';
	@override String get illisibleTitre => 'Your account could not be read';
	@override String get illisiblePhrase => 'We do not know yet which profiles you can add. Try again in a moment.';
}

// Path: foyer.ajout.pourQui
class _Traductions$foyer$ajout$pourQui$en extends Traductions$foyer$ajout$pourQui$fr {
	_Traductions$foyer$ajout$pourQui$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get question => 'Who is this student profile for?';
	@override String get sousTitre => 'Choose the person who will take the classes.';
	@override String get requis => 'Choose who this profile is for to continue.';
	@override String get indisponible => 'Unavailable';
	@override String get enfantTitre => 'A child or a minor';
	@override String get enfantDescription => 'A profile attached to your household, which you manage for them.';
	@override String get enfantAttente => 'Possible as soon as your access is open.';
	@override String get moiTitre => 'Myself';
}

// Path: foyer.ajout.identite
class _Traductions$foyer$ajout$identite$en extends Traductions$foyer$ajout$identite$fr {
	_Traductions$foyer$ajout$identite$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get question => 'Who is the student?';
	@override String get sousTitre => 'Their first name, last name and age.';
	@override String get prenom => 'First name';
	@override String get nom => 'Last name';
	@override String get nomAide => 'The family name is never shown to the teacher.';
	@override String get nomAidePrerempli => 'Filled in with your account name: change it if the student has a different name. Never shown to the teacher.';
	@override String get age => 'Age, in years';
	@override String ageAide({required Object min}) => 'Age sets the display and the camera to start with. You can change both afterwards. The minimum age is ${min}.';
	@override String get ageFige => 'Sending is in progress: the age can be changed after the reply.';
	@override String get ageAdulte => 'From 18, the student creates their own adult account.';
	@override String get genre => 'Boy or girl';
}

// Path: foyer.ajout.erreurs
class _Traductions$foyer$ajout$erreurs$en extends Traductions$foyer$ajout$erreurs$fr {
	_Traductions$foyer$ajout$erreurs$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get prenomRequis => 'Enter the student\'s first name.';
	@override String get nomRequis => 'Enter the student\'s last name.';
	@override String get ageRequis => 'Choose the student\'s age to continue.';
	@override String ageHorsBornes({required Object min, required Object max}) => 'Enter an age between ${min} and ${max}.';
	@override String get genreRequis => 'Gender is missing: tap "A boy" or "A girl", then "Create the profile".';
}

// Path: foyer.ajout.refus
class _Traductions$foyer$ajout$refus$en extends Traductions$foyer$ajout$refus$fr {
	_Traductions$foyer$ajout$refus$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get compteNonValide => 'Your access must be open before you add a student profile.';
	@override String get ageHorsBornes => 'This age is not accepted. Check it and try again.';
	@override String get refuse => 'The creation was not accepted. Check the information and try again.';
	@override String get titulaire => 'This first and last name are yours. A profile added here is a child\'s: to take classes yourself, use "Create my student profile".';
	@override String get adulte => 'From 18, a profile is not added here: this page is for children. To take classes yourself, use "Create my student profile".';
}

// Path: foyer.ajout.incertaine
class _Traductions$foyer$ajout$incertaine$en extends Traductions$foyer$ajout$incertaine$fr {
	_Traductions$foyer$ajout$incertaine$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'The profile may have been created';
	@override String get phrase => 'The reply did not reach us. Check the household before trying again, so the profile is not created twice.';
	@override String get voirFoyer => 'See the household';
	@override String get reessayer => 'Try again anyway';
}

// Path: ficheEleve.mouvements.colonne
class _Traductions$ficheEleve$mouvements$colonne$en extends Traductions$ficheEleve$mouvements$colonne$fr {
	_Traductions$ficheEleve$mouvements$colonne$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get date => 'Date';
	@override String get libelle => 'Label';
	@override String get montant => 'Amount';
	@override String get statut => 'Status';
	@override String get recu => 'Receipt';
}

// Path: ficheEleve.mouvements.nature
class _Traductions$ficheEleve$mouvements$nature$en extends Traductions$ficheEleve$mouvements$nature$fr {
	_Traductions$ficheEleve$mouvements$nature$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get recharge => 'Top-up';
	@override String get mensualite => 'Monthly fee';
	@override String mensualiteDe({required Object mois, required Object annee}) => 'Monthly fee ${mois} ${annee}';
	@override String get avoir => 'Credit note';
	@override String get remise => 'Discount';
	@override String get taxe => 'Applicable tax';
	@override String get debitSeance => 'Session debit';
	@override String get correction => 'Balance correction';
	@override String get remboursement => 'Refund';
}

// Path: ficheEleve.mouvements.statut
class _Traductions$ficheEleve$mouvements$statut$en extends Traductions$ficheEleve$mouvements$statut$fr {
	_Traductions$ficheEleve$mouvements$statut$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get enregistre => 'Recorded';
	@override String get enConfirmation => 'Being confirmed';
}

// Path: ficheEleve.mouvements.recu
class _Traductions$ficheEleve$mouvements$recu$en extends Traductions$ficheEleve$mouvements$recu$fr {
	_Traductions$ficheEleve$mouvements$recu$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Receipt';
	@override String get fermer => 'Close the receipt';
	@override String get date => 'Date';
	@override String get reference => 'Reference';
	@override String get moyen => 'Payment method';
	@override String get montant => 'Amount paid';
	@override String get repartition => 'Breakdown';
}

// Path: recrutement.candidat.comptable
class _Traductions$recrutement$candidat$comptable$en extends Traductions$recrutement$candidat$comptable$fr {
	_Traductions$recrutement$candidat$comptable$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Your accountant code';
	@override String get intro => 'To sign up as an accountant, enter the invitation code you received from the management.';
	@override String get valideDetail => 'You can create your accountant profile.';
	@override String get indisponible => 'Checking accountant codes will be available once the server is connected.';
}

// Path: recrutement.entretien.notifications
class _Traductions$recrutement$entretien$notifications$en extends Traductions$recrutement$entretien$notifications$fr {
	_Traductions$recrutement$entretien$notifications$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get reserve => 'Your interview is set. The day and time are in "Let\'s get to know each other".';
	@override String reserveQuand({required Object quand}) => 'Your interview is set for ${quand}.';
	@override String get veille => 'Your interview is tomorrow.';
	@override String veilleQuand({required Object quand}) => 'Your interview is tomorrow, ${quand}.';
	@override String get quinze => 'Your interview starts in 15 minutes: join it from "Let\'s get to know each other".';
	@override String get tenu => 'Your interview took place. The management is reviewing your application and will write to you with what comes next.';
	@override String get aReplanifier => 'Your interview did not take place. Choose another time.';
	@override String get reserveDirection => 'An applicant has booked an interview you conduct.';
	@override String reserveDirectionQuand({required Object quand}) => 'An applicant has booked an interview you conduct, on ${quand}.';
	@override String get rappelDirection => 'You are conducting an interview that starts soon.';
	@override String rappelDirectionQuand({required Object quand}) => 'You are conducting an interview on ${quand}.';
}

// Path: recrutement.parcours.presentation
class _Traductions$recrutement$parcours$presentation$en extends Traductions$recrutement$parcours$presentation$fr {
	_Traductions$recrutement$parcours$presentation$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$recrutement$parcours$presentation$p1$en p1 = _Traductions$recrutement$parcours$presentation$p1$en._(_root);
	@override late final _Traductions$recrutement$parcours$presentation$p2$en p2 = _Traductions$recrutement$parcours$presentation$p2$en._(_root);
	@override late final _Traductions$recrutement$parcours$presentation$p3$en p3 = _Traductions$recrutement$parcours$presentation$p3$en._(_root);
}

// Path: recrutement.parcours.langues
class _Traductions$recrutement$parcours$langues$en extends Traductions$recrutement$parcours$langues$fr {
	_Traductions$recrutement$parcours$langues$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get poular => 'Pulaar (Fula, Fulfulde)';
	@override String get man => 'Malinke';
	@override String get sus => 'Susu';
	@override String get sw => 'Swahili';
	@override String get ha => 'Hausa';
	@override String get wo => 'Wolof';
	@override String get bm => 'Bambara';
	@override String get snk => 'Soninke';
	@override String get mnk => 'Mandinka';
	@override String get francais => 'French';
	@override String get english => 'English';
	@override String get ar => 'Arabic';
	@override String get ps => 'Pashto';
	@override String get ur => 'Urdu';
	@override String get om => 'Oromo';
	@override String get am => 'Amharic';
	@override String get yo => 'Yoruba';
	@override String get bn => 'Bengali';
	@override String get fa => 'Persian';
	@override String get id => 'Indonesian';
	@override String get so => 'Somali';
	@override String get hi => 'Hindi';
	@override String get uz => 'Uzbek';
	@override String get tr => 'Turkish';
	@override String get de => 'German';
	@override String get pt => 'Portuguese';
	@override String get ru => 'Russian';
	@override String get autre => 'Another language';
	@override String get autreDescription => 'A language that is not in the list. The management will see it.';
	@override String get dansReferentiel => 'Rewayah offers classes in this language.';
	@override String get horsReferentiel => 'Rewayah does not yet offer classes in this language. You can choose it: the management will see it.';
	@override String get chercher => 'Search for another language';
	@override String get recherche => 'Search for a language';
	@override String get rechercheAide => 'Language name';
	@override String get aucune => 'No language matches.';
	@override String get retour => 'Back to the languages offered';
}

// Path: recrutement.parcours.pays
class _Traductions$recrutement$parcours$pays$en extends Traductions$recrutement$parcours$pays$fr {
	_Traductions$recrutement$parcours$pays$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get autre => 'Another country';
	@override String get recherche => 'Search for a country';
	@override String get rechercheAide => 'Country name';
	@override String get aucun => 'No country matches.';
	@override String get retour => 'Back to the countries offered';
}

// Path: recrutement.parcours.riwayat
class _Traductions$recrutement$parcours$riwayat$en extends Traductions$recrutement$parcours$riwayat$fr {
	_Traductions$recrutement$parcours$riwayat$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get autre => 'Another riwaya';
	@override String get recherche => 'Search for a riwaya';
	@override String get rechercheAide => 'Riwaya name';
	@override String get aucune => 'No riwaya matches.';
	@override String get retour => 'Back to the riwayat offered';
}

// Path: recrutement.parcours.fuseau
class _Traductions$recrutement$parcours$fuseau$en extends Traductions$recrutement$parcours$fuseau$fr {
	_Traductions$recrutement$parcours$fuseau$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String heureChezVous({required Object heure}) => 'Is it ${heure} where you are?';
	@override String lieuPropose({required Object lieu}) => 'Suggested time zone: ${lieu}.';
	@override String retenu({required Object lieu}) => 'Time zone kept: ${lieu}.';
	@override String get oui => 'Yes, that is my local time';
	@override String get ouiDescription => 'Your time zone is confirmed.';
	@override String get changer => 'No, I want to change it';
	@override String get changerDescription => 'You choose the city closest to you.';
	@override String get choisirTitre => 'Which city is closest to you?';
	@override String get choisirExplication => 'It gives your time zone. The times of your interview will be shown in this time zone.';
	@override String get recherche => 'Search for a city';
	@override String get rechercheAide => 'City name';
	@override String get aucune => 'No city matches.';
	@override String get autre => 'Another city';
	@override String get retour => 'Back to the suggestion';
	@override late final _Traductions$recrutement$parcours$fuseau$regions$en regions = _Traductions$recrutement$parcours$fuseau$regions$en._(_root);
	@override String get ouiExplication => 'Your availability and your interview will be in your local time.';
	@override String get changerExplication => 'Useful if you travel or if your device\'s time is wrong.';
}

// Path: recrutement.parcours.creneaux
class _Traductions$recrutement$parcours$creneaux$en extends Traductions$recrutement$parcours$creneaux$fr {
	_Traductions$recrutement$parcours$creneaux$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String heure({required Object h}) => '${h}:00';
	@override String heureMinutes({required Object h, required Object m}) => '${h}:${m}';
	@override String intervalle({required Object debut, required Object fin}) => 'from ${debut} to ${fin}';
	@override String fuseauRappel({required Object lieu}) => 'Times in ${lieu}.';
	@override late final _Traductions$recrutement$parcours$creneaux$moments$en moments = _Traductions$recrutement$parcours$creneaux$moments$en._(_root);
	@override String get raccourcis => 'Shortcuts';
	@override String get raccourciLmv => 'Monday, Wednesday, Friday';
	@override String get raccourciMjs => 'Tuesday, Thursday, Saturday';
	@override String get raccourciFinDeSemaine => 'Weekend';
	@override String get raccourcisAide => 'A shortcut chooses several days at once. You can then add or remove some.';
	@override String moinsDeTrois({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'You chose a single day. A class meets three times a week, on the same days: consider choosing at least three.',
		other: 'You chose ${n} days. A class meets three times a week, on the same days: consider choosing at least three.',
	);
	@override String get troisSeances => 'A class meets three times a week, on the same days and at the same time.';
	@override String durees({required Object enfants, required Object adultes}) => 'A children\'s class lasts ${enfants}, an adults\' class lasts ${adultes}.';
	@override String enseigneEnfants({required Object duree, required Object intervalles}) => 'Children\'s classes (${duree}): you teach ${intervalles}.';
	@override String enseigneAdultes({required Object duree, required Object intervalles}) => 'Adults\' classes (${duree}): you teach ${intervalles}.';
	@override String heuresChoisies({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		zero: 'No start time chosen',
		one: 'One start time chosen',
		other: '${n} start times chosen',
	);
	@override String debutsDuJour({required Object heures}) => 'Possible start times: ${heures}.';
	@override String get separateurListe => ', ';
	@override String etListe({required Object debut, required Object dernier}) => '${debut} and ${dernier}';
}

// Path: recrutement.parcours.versement
class _Traductions$recrutement$parcours$versement$en extends Traductions$recrutement$parcours$versement$fr {
	_Traductions$recrutement$parcours$versement$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get virementSeul => 'In your country, the academy has confirmed bank transfer. No mobile payment method is offered for now.';
	@override String get aucunMoyen => 'Rewayah does not yet pay teachers in this country. You can send your application: it will stay on hold until a method becomes possible.';
	@override String get operateurDescription => 'Mobile payment';
	@override String get chargement => 'We are looking for the methods possible in your country.';
	@override String get nonCharge => 'The payment methods for your country could not be loaded.';
	@override String get operateurExplication => 'You declare it now. Your details are only requested before your first payment.';
}

// Path: recrutement.parcours.recap
class _Traductions$recrutement$parcours$recap$en extends Traductions$recrutement$parcours$recap$fr {
	_Traductions$recrutement$parcours$recap$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Review your application';
	@override String get explication => 'Tap an answer to change it. Nothing is sent before the "Send my application" button.';
	@override String jours({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'One day per week',
		other: '${n} days per week',
	);
}

// Path: recrutement.parcours.q
class _Traductions$recrutement$parcours$q$en extends Traductions$recrutement$parcours$q$fr {
	_Traductions$recrutement$parcours$q$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$recrutement$parcours$q$langueMaternelle$en langueMaternelle = _Traductions$recrutement$parcours$q$langueMaternelle$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$languesExplication$en languesExplication = _Traductions$recrutement$parcours$q$languesExplication$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$niveauMemorisationDeclare$en niveauMemorisationDeclare = _Traductions$recrutement$parcours$q$niveauMemorisationDeclare$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$niveauLectureTajwid$en niveauLectureTajwid = _Traductions$recrutement$parcours$q$niveauLectureTajwid$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$riwayat$en riwayat = _Traductions$recrutement$parcours$q$riwayat$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$ijazaPresentable$en ijazaPresentable = _Traductions$recrutement$parcours$q$ijazaPresentable$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$experienceDebutants$en experienceDebutants = _Traductions$recrutement$parcours$q$experienceDebutants$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$fuseauIana$en fuseauIana = _Traductions$recrutement$parcours$q$fuseauIana$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$disponibilitesDeclarees$en disponibilitesDeclarees = _Traductions$recrutement$parcours$q$disponibilitesDeclarees$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$classesSouhaitees$en classesSouhaitees = _Traductions$recrutement$parcours$q$classesSouhaitees$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$debutPossible$en debutPossible = _Traductions$recrutement$parcours$q$debutPossible$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$publics$en publics = _Traductions$recrutement$parcours$q$publics$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$paysResidence$en paysResidence = _Traductions$recrutement$parcours$q$paysResidence$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$paysVersement$en paysVersement = _Traductions$recrutement$parcours$q$paysVersement$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$compteBancaire$en compteBancaire = _Traductions$recrutement$parcours$q$compteBancaire$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$operateurs$en operateurs = _Traductions$recrutement$parcours$q$operateurs$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$moyensAccessibles$en moyensAccessibles = _Traductions$recrutement$parcours$q$moyensAccessibles$en._(_root);
}

// Path: recrutement.parcours.classes
class _Traductions$recrutement$parcours$classes$en extends Traductions$recrutement$parcours$classes$fr {
	_Traductions$recrutement$parcours$classes$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String libelle({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} class',
		other: '${n} classes',
	);
	@override String seances({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} session per week.',
		other: '${n} sessions per week.',
	);
	@override String heuresEnfants({required Object heures}) => 'That is ${heures} per week with children.';
	@override String heuresAdultes({required Object heures}) => 'That is ${heures} per week with adults.';
	@override String heuresLesDeux({required Object enfants, required Object adultes}) => 'That is ${enfants} per week with children, or ${adultes} with adults.';
	@override String get explication => 'Each class has its own schedule, which it keeps every week.';
	@override String get exemple1 => 'on Monday, Wednesday and Friday at 6 pm.';
	@override String get exemple2 => 'on Monday, Wednesday and Friday at 6 pm, then on Tuesday, Thursday and Saturday at 7 pm.';
	@override String exemplePlusieurs({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} class, with its days and its time.',
		other: '${n} classes, each with its days and its time.',
	);
}

// Path: recrutement.parcours.moyens
class _Traductions$recrutement$parcours$moyens$en extends Traductions$recrutement$parcours$moyens$fr {
	_Traductions$recrutement$parcours$moyens$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get mobile => 'Mobile payment';
	@override String get virement => 'Bank transfer';
	@override String get explication => 'Choose it if it is common where you live.';
	@override String get nonElimine => 'This question is optional and eliminates no one: your application does not depend on your answer. It helps the academy know the methods used where you live.';
}

// Path: compte.page.langue
class _Traductions$compte$page$langue$en extends Traductions$compte$page$langue$fr {
	_Traductions$compte$page$langue$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get legende => 'For the app and for the academy\'s emails';
	@override String get refus => 'The app changed language, but the language of your emails is not confirmed. Try again in a moment.';
}

// Path: tuteur.accueil.autreAppareilFeuille
class _Traductions$tuteur$accueil$autreAppareilFeuille$en extends Traductions$tuteur$accueil$autreAppareilFeuille$fr {
	_Traductions$tuteur$accueil$autreAppareilFeuille$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get phrase => 'Your account follows you on all your devices. On the other device, open the app at this address, then sign in with the same sign-in address.';
	@override String get aucunCode => 'No code to enter: it is your own account.';
	@override String get adresseApplication => 'App address';
	@override String get adresseConnexion => 'Sign-in address';
	@override String get copier => 'Copy the app link';
	@override String get copie => 'Link copied';
}

// Path: tuteur.accueil.etatCourt
class _Traductions$tuteur$accueil$etatCourt$en extends Traductions$tuteur$accueil$etatCourt$fr {
	_Traductions$tuteur$accueil$etatCourt$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get enDirect => 'Live';
	@override String get salleOuverte => 'Room open';
	@override String dansMinutes({required Object minutes}) => 'In ${minutes} min';
	@override String dansHeures({required Object heures, required Object minutes}) => 'In ${heures} h ${minutes}';
	@override String dansJours({required Object jours}) => 'In ${jours} d';
	@override String get prevue => 'Session planned';
	@override String get annulee => 'Session cancelled';
	@override String get nonTenue => 'Session not held';
	@override String get terminee => 'Session ended';
	@override String get aucune => 'No session';
	@override String get illisible => 'Not available';
}

// Path: classe.entree.annonce
class _Traductions$classe$entree$annonce$en extends Traductions$classe$entree$annonce$fr {
	_Traductions$classe$entree$annonce$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get aVenir => 'Upcoming session';
	@override String get fenetreOuverte => 'The room is open';
	@override String get attente => 'You are in the room';
}

// Path: classe.entree.demo
class _Traductions$classe$entree$demo$en extends Traductions$classe$entree$demo$fr {
	_Traductions$classe$entree$demo$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Joining class';
	@override String get mention => 'Demo';
	@override String get intro => 'Fictitious data, no server call. Each link shows what the entry spot says for a role and a moment.';
	@override late final _Traductions$classe$entree$demo$roles$en roles = _Traductions$classe$entree$demo$roles$en._(_root);
	@override late final _Traductions$classe$entree$demo$etats$en etats = _Traductions$classe$entree$demo$etats$en._(_root);
	@override String get formeBouton => 'Form: button';
	@override String get formeLigne => 'Form: status line';
	@override String lecteur({required Object texte}) => 'Screen reader: ${texte}';
	@override String annonce({required Object texte}) => 'Announcement: ${texte}';
	@override String detail({required Object texte}) => 'Detail: ${texte}';
	@override String get retour => 'Back to the list';
}

// Path: classe.observation.motif
class _Traductions$classe$observation$motif$en extends Traductions$classe$observation$motif$fr {
	_Traductions$classe$observation$motif$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get visitesEpuisees => 'You have used your visits for this session.';
	@override String get tempsEpuise => 'Your observation time is used up for this session.';
	@override String get seanceNonCommencee => 'Observation opens when the session starts.';
	@override String get seanceTerminee => 'The session has ended.';
	@override String get seanceNonTenue => 'This session is not taking place: there is nothing to observe.';
	@override String get horsFenetre => 'The room is not open at this time.';
	@override String get observationDesactivee => 'Observation is closed for this class.';
	@override String get lienAbsent => 'No student in your household is linked to this session.';
	@override String enfantAbsent({required Object dePrenom}) => 'Observation is waiting for ${dePrenom} to arrive.';
	@override String presenceEnVerification({required Object dePrenom}) => '${dePrenom}\'s attendance is being verified.';
	@override String get visiteDejaOuverte => 'A visit is already open, on this device or another.';
	@override String get garantieServeurAbsente => 'Session observation is not open yet.';
	@override String get reseau => 'The availability of observation could not be verified.';
	@override String get capaciteAbsente => 'Observation cannot open for this session.';
}

// Path: classe.pageTravail.statut
class _Traductions$classe$pageTravail$statut$en extends Traductions$classe$pageTravail$statut$fr {
	_Traductions$classe$pageTravail$statut$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get aFaire => 'To do';
	@override String get enCours => 'Started';
	@override String get fait => 'Done';
	@override String get expire => 'Past due';
}

// Path: classe.cartes.types
class _Traductions$classe$cartes$types$en extends Traductions$classe$cartes$types$fr {
	_Traductions$classe$cartes$types$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get annonce => 'Announcement';
	@override String get devoir => 'Homework';
	@override String get lien => 'Useful link';
	@override String get rappel => 'Reminder';
}

// Path: classe.cartes.typesDetail
class _Traductions$classe$cartes$typesDetail$en extends Traductions$classe$cartes$typesDetail$fr {
	_Traductions$classe$cartes$typesDetail$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get annonce => 'For information for the whole class.';
	@override String get devoir => 'For work to prepare: the suggested due date is the next session.';
	@override String get lien => 'To share a page or a material: paste its address.';
	@override String get rappel => 'For a date not to forget: outing, exam, schedule change.';
}

// Path: classe.cartes.modeles
class _Traductions$classe$cartes$modeles$en extends Traductions$classe$cartes$modeles$fr {
	_Traductions$classe$cartes$modeles$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get annonce => 'Information for the class';
	@override String get devoir => 'To prepare for the next session';
	@override String get lien => 'Material to look at';
	@override String get rappel => 'Do not forget';
}

// Path: classe.cartes.feuille
class _Traductions$classe$cartes$feuille$en extends Traductions$classe$cartes$feuille$fr {
	_Traductions$classe$cartes$feuille$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titreNouvelle => 'New class card';
	@override String titreModifier({required Object titre}) => 'Edit the card "${titre}"';
	@override String get contexte => 'Choose a template: it pre-fills the card. It is immediately visible to the class students and their families.';
	@override String get modele => 'Card template';
	@override String get champTitre => 'Card title';
	@override String get champTexte => 'Card text (optional)';
	@override String get champLien => 'Card link (optional)';
	@override String aideLongueur({required Object max}) => '${max} characters at most';
	@override String get aideLien => 'A full address, starting with https://';
	@override String get echeanceAucune => 'No due date';
	@override String get choisirEcheance => 'Choose the due date';
	@override String get retirerEcheance => 'Remove the due date';
	@override String get enregistrer => 'Save the card';
	@override String get retirer => 'Remove this card';
	@override String retirerQuestion({required Object titre}) => 'Remove the card "${titre}"?';
	@override String get retirerConsequence => 'It disappears immediately for the class students and their families.';
	@override String get retirerConfirmer => 'Remove the card';
	@override String get envoiNonConfirme => 'The card is not confirmed: the reply did not arrive. Save again in a moment.';
	@override String get retraitNonConfirme => 'The removal is not confirmed: the reply did not arrive. Try again in a moment.';
	@override late final _Traductions$classe$cartes$feuille$defauts$en defauts = _Traductions$classe$cartes$feuille$defauts$en._(_root);
}

// Path: suiviFamille.close.motif
class _Traductions$suiviFamille$close$motif$en extends Traductions$suiviFamille$close$motif$fr {
	_Traductions$suiviFamille$close$motif$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get retraitFamille => 'You withdrew this request.';
	@override String get offreRetiree => 'This slot is no longer offered.';
	@override String get classeNonConstituee => 'The class for this slot could not be formed.';
	@override String get refusDirection => 'The management did not accept this request.';
	@override String dejaEnClasse({required Object prenom}) => '${prenom} already has a place in a class: this request is no longer needed.';
	@override String get inconnu => 'This request is closed.';
}

// Path: suiviDemandes.close.motif
class _Traductions$suiviDemandes$close$motif$en extends Traductions$suiviDemandes$close$motif$fr {
	_Traductions$suiviDemandes$close$motif$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get retraitFamille => 'You withdrew this request.';
	@override String get offreRetiree => 'The academy removed this slot from its offers.';
	@override String get classeNonConstituee => 'The class for this slot could not be formed.';
	@override String get refusDirection => 'The management could not accept this request.';
	@override String dejaEnClasse({required Object prenom}) => '${prenom} already has a place in a class: this request is no longer needed.';
	@override String get inconnu => 'This request is closed.';
}

// Path: suiviAttente.cloture.motif
class _Traductions$suiviAttente$cloture$motif$en extends Traductions$suiviAttente$cloture$motif$fr {
	_Traductions$suiviAttente$cloture$motif$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get retraitFamille => 'You withdrew this request.';
	@override String get offreRetiree => 'The academy removed this slot from its offers.';
	@override String get classeNonConstituee => 'The class for this slot could not be formed.';
	@override String get refusDirection => 'The management did not accept this request.';
	@override String get dejaEnClasse => 'This student already has a place in a class: the request is no longer needed.';
	@override String get inconnu => 'This request is closed.';
}

// Path: suiviAttente.cloture.simple
class _Traductions$suiviAttente$cloture$simple$en extends Traductions$suiviAttente$cloture$simple$fr {
	_Traductions$suiviAttente$cloture$simple$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get refusee => 'Your request was not accepted. Your guardian can choose another slot.';
	@override String get retiree => 'This request is withdrawn.';
	@override String get close => 'This request is closed.';
}

// Path: recrutement.parcours.presentation.p1
class _Traductions$recrutement$parcours$presentation$p1$en extends Traductions$recrutement$parcours$presentation$p1$fr {
	_Traductions$recrutement$parcours$presentation$p1$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Who is Rewayah Academy?';
	@override String get intro => 'Before the questions, here is what you need to know about us.';
	@override late final _Traductions$recrutement$parcours$presentation$p1$academie$en academie = _Traductions$recrutement$parcours$presentation$p1$academie$en._(_root);
	@override late final _Traductions$recrutement$parcours$presentation$p1$liberte$en liberte = _Traductions$recrutement$parcours$presentation$p1$liberte$en._(_root);
	@override late final _Traductions$recrutement$parcours$presentation$p1$donnees$en donnees = _Traductions$recrutement$parcours$presentation$p1$donnees$en._(_root);
	@override late final _Traductions$recrutement$parcours$presentation$p1$separation$en separation = _Traductions$recrutement$parcours$presentation$p1$separation$en._(_root);
}

// Path: recrutement.parcours.presentation.p2
class _Traductions$recrutement$parcours$presentation$p2$en extends Traductions$recrutement$parcours$presentation$p2$fr {
	_Traductions$recrutement$parcours$presentation$p2$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'What a teacher does';
	@override String get intro => 'You teach by video, in a class that stays the same.';
	@override late final _Traductions$recrutement$parcours$presentation$p2$classe$en classe = _Traductions$recrutement$parcours$presentation$p2$classe$en._(_root);
	@override late final _Traductions$recrutement$parcours$presentation$p2$horaires$en horaires = _Traductions$recrutement$parcours$presentation$p2$horaires$en._(_root);
	@override late final _Traductions$recrutement$parcours$presentation$p2$visio$en visio = _Traductions$recrutement$parcours$presentation$p2$visio$en._(_root);
	@override late final _Traductions$recrutement$parcours$presentation$p2$remuneration$en remuneration = _Traductions$recrutement$parcours$presentation$p2$remuneration$en._(_root);
}

// Path: recrutement.parcours.presentation.p3
class _Traductions$recrutement$parcours$presentation$p3$en extends Traductions$recrutement$parcours$presentation$p3$fr {
	_Traductions$recrutement$parcours$presentation$p3$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'How your application works';
	@override String get intro => 'Three steps, in the app.';
	@override late final _Traductions$recrutement$parcours$presentation$p3$examen$en examen = _Traductions$recrutement$parcours$presentation$p3$examen$en._(_root);
	@override late final _Traductions$recrutement$parcours$presentation$p3$entretien$en entretien = _Traductions$recrutement$parcours$presentation$p3$entretien$en._(_root);
	@override late final _Traductions$recrutement$parcours$presentation$p3$verification$en verification = _Traductions$recrutement$parcours$presentation$p3$verification$en._(_root);
}

// Path: recrutement.parcours.fuseau.regions
class _Traductions$recrutement$parcours$fuseau$regions$en extends Traductions$recrutement$parcours$fuseau$regions$fr {
	_Traductions$recrutement$parcours$fuseau$regions$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get Africa => 'Africa';
	@override String get America => 'Americas';
	@override String get Antarctica => 'Antarctica';
	@override String get Arctic => 'Arctic';
	@override String get Asia => 'Asia';
	@override String get Atlantic => 'Atlantic';
	@override String get Australia => 'Australia';
	@override String get Europe => 'Europe';
	@override String get Indian => 'Indian Ocean';
	@override String get Pacific => 'Pacific';
}

// Path: recrutement.parcours.creneaux.moments
class _Traductions$recrutement$parcours$creneaux$moments$en extends Traductions$recrutement$parcours$creneaux$moments$fr {
	_Traductions$recrutement$parcours$creneaux$moments$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get nuit => 'At night, from 0:00 to 5:00';
	@override String get matin => 'In the morning, from 6:00 to 11:00';
	@override String get apresMidi => 'In the afternoon, from 12:00 to 17:00';
	@override String get soir => 'In the evening, from 18:00 to 23:00';
}

// Path: recrutement.parcours.q.langueMaternelle
class _Traductions$recrutement$parcours$q$langueMaternelle$en extends Traductions$recrutement$parcours$q$langueMaternelle$fr {
	_Traductions$recrutement$parcours$q$langueMaternelle$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'What is your mother tongue?';
	@override String get explication => 'It is the language you have spoken since childhood. This question is optional: you can continue without answering.';
	@override String get court => 'Mother tongue';
}

// Path: recrutement.parcours.q.languesExplication
class _Traductions$recrutement$parcours$q$languesExplication$en extends Traductions$recrutement$parcours$q$languesExplication$fr {
	_Traductions$recrutement$parcours$q$languesExplication$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'In which languages can you explain and correct?';
	@override String get explication => 'Choose all the languages in which you can explain a rule to a student and correct their mistakes, with no limit on the number. The student or their parent chooses their language at sign-up, and the academy assigns them a teacher who speaks it: the more you speak, the more you can teach. Arabic is not a class language: it is not in this list.';
	@override String get court => 'Languages of explanation';
}

// Path: recrutement.parcours.q.niveauMemorisationDeclare
class _Traductions$recrutement$parcours$q$niveauMemorisationDeclare$en extends Traductions$recrutement$parcours$q$niveauMemorisationDeclare$fr {
	_Traductions$recrutement$parcours$q$niveauMemorisationDeclare$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'How much of the Quran have you memorised?';
	@override String get explication => 'You declare it here. Having memorised and having an ijaza are two different things: the ijaza is asked a little further on.';
	@override String get court => 'Memorisation level';
	@override late final _Traductions$recrutement$parcours$q$niveauMemorisationDeclare$options$en options = _Traductions$recrutement$parcours$q$niveauMemorisationDeclare$options$en._(_root);
}

// Path: recrutement.parcours.q.niveauLectureTajwid
class _Traductions$recrutement$parcours$q$niveauLectureTajwid$en extends Traductions$recrutement$parcours$q$niveauLectureTajwid$fr {
	_Traductions$recrutement$parcours$q$niveauLectureTajwid$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'How do you read the Quran?';
	@override String get explication => 'Tajwid is the set of rules that say how to pronounce each letter of the Quran.';
	@override String get court => 'Reading and tajwid';
	@override late final _Traductions$recrutement$parcours$q$niveauLectureTajwid$options$en options = _Traductions$recrutement$parcours$q$niveauLectureTajwid$options$en._(_root);
}

// Path: recrutement.parcours.q.riwayat
class _Traductions$recrutement$parcours$q$riwayat$en extends Traductions$recrutement$parcours$q$riwayat$fr {
	_Traductions$recrutement$parcours$q$riwayat$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Which riwayat do you recite?';
	@override String get explication => 'A riwaya is a transmitted way of reciting the Quran. Choose all those you recite.';
	@override String get court => 'Riwayat';
	@override late final _Traductions$recrutement$parcours$q$riwayat$options$en options = _Traductions$recrutement$parcours$q$riwayat$options$en._(_root);
}

// Path: recrutement.parcours.q.ijazaPresentable
class _Traductions$recrutement$parcours$q$ijazaPresentable$en extends Traductions$recrutement$parcours$q$ijazaPresentable$fr {
	_Traductions$recrutement$parcours$q$ijazaPresentable$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Do you have an ijaza?';
	@override String get explication => 'An ijaza is a written authorisation, given by a teacher, to transmit the Quran. Whoever has an ijaza has memorised, but whoever has memorised does not necessarily have an ijaza: it is a separate question.';
	@override String get court => 'Ijaza';
	@override late final _Traductions$recrutement$parcours$q$ijazaPresentable$options$en options = _Traductions$recrutement$parcours$q$ijazaPresentable$options$en._(_root);
}

// Path: recrutement.parcours.q.experienceDebutants
class _Traductions$recrutement$parcours$q$experienceDebutants$en extends Traductions$recrutement$parcours$q$experienceDebutants$fr {
	_Traductions$recrutement$parcours$q$experienceDebutants$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Have you already taught beginners?';
	@override String get explication => 'A beginner is still learning to read the letters and join them.';
	@override String get court => 'Experience with beginners';
	@override late final _Traductions$recrutement$parcours$q$experienceDebutants$options$en options = _Traductions$recrutement$parcours$q$experienceDebutants$options$en._(_root);
}

// Path: recrutement.parcours.q.fuseauIana
class _Traductions$recrutement$parcours$q$fuseauIana$en extends Traductions$recrutement$parcours$q$fuseauIana$fr {
	_Traductions$recrutement$parcours$q$fuseauIana$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Your time zone';
	@override String get explication => 'Your availability is in your local time. So the time must be right.';
	@override String get court => 'Time zone';
}

// Path: recrutement.parcours.q.disponibilitesDeclarees
class _Traductions$recrutement$parcours$q$disponibilitesDeclarees$en extends Traductions$recrutement$parcours$q$disponibilitesDeclarees$fr {
	_Traductions$recrutement$parcours$q$disponibilitesDeclarees$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Which days can you teach?';
	@override String get explication => 'A class meets three times a week, on the same days and at the same time. Tap the days you can teach, or use a shortcut.';
	@override String get court => 'Availability';
	@override late final _Traductions$recrutement$parcours$q$disponibilitesDeclarees$heures$en heures = _Traductions$recrutement$parcours$q$disponibilitesDeclarees$heures$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$disponibilitesDeclarees$memes$en memes = _Traductions$recrutement$parcours$q$disponibilitesDeclarees$memes$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$disponibilitesDeclarees$parJour$en parJour = _Traductions$recrutement$parcours$q$disponibilitesDeclarees$parJour$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$disponibilitesDeclarees$semaine$en semaine = _Traductions$recrutement$parcours$q$disponibilitesDeclarees$semaine$en._(_root);
}

// Path: recrutement.parcours.q.classesSouhaitees
class _Traductions$recrutement$parcours$q$classesSouhaitees$en extends Traductions$recrutement$parcours$q$classesSouhaitees$fr {
	_Traductions$recrutement$parcours$q$classesSouhaitees$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'How many classes do you want to hold?';
	@override String get explication => 'A class is a group of students who meet three times a week, on the same days and at the same time, with the same teacher. It is a wish: the academy decides which classes it assigns to you.';
	@override String get court => 'Classes wanted';
}

// Path: recrutement.parcours.q.debutPossible
class _Traductions$recrutement$parcours$q$debutPossible$en extends Traductions$recrutement$parcours$q$debutPossible$fr {
	_Traductions$recrutement$parcours$q$debutPossible$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'When can you start?';
	@override String get explication => 'This date helps the management know when to offer you a class.';
	@override String get court => 'Start date';
	@override late final _Traductions$recrutement$parcours$q$debutPossible$options$en options = _Traductions$recrutement$parcours$q$debutPossible$options$en._(_root);
}

// Path: recrutement.parcours.q.publics
class _Traductions$recrutement$parcours$q$publics$en extends Traductions$recrutement$parcours$q$publics$fr {
	_Traductions$recrutement$parcours$q$publics$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Which students can you teach?';
	@override String get explication => 'Choose the age groups you are comfortable teaching. There is no wrong answer: you can choose just one, or several.';
	@override String get court => 'Audiences';
	@override late final _Traductions$recrutement$parcours$q$publics$options$en options = _Traductions$recrutement$parcours$q$publics$options$en._(_root);
}

// Path: recrutement.parcours.q.paysResidence
class _Traductions$recrutement$parcours$q$paysResidence$en extends Traductions$recrutement$parcours$q$paysResidence$fr {
	_Traductions$recrutement$parcours$q$paysResidence$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Which country do you live in?';
	@override String get explication => 'Choose the country where you live today.';
	@override String get court => 'Country of residence';
}

// Path: recrutement.parcours.q.paysVersement
class _Traductions$recrutement$parcours$q$paysVersement$en extends Traductions$recrutement$parcours$q$paysVersement$fr {
	_Traductions$recrutement$parcours$q$paysVersement$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'In which country do you want to receive your pay?';
	@override String get explication => 'The academy checks, country by country, which payment method is possible. We carried over your country of residence: change it if needed.';
	@override String get court => 'Payment country';
}

// Path: recrutement.parcours.q.compteBancaire
class _Traductions$recrutement$parcours$q$compteBancaire$en extends Traductions$recrutement$parcours$q$compteBancaire$fr {
	_Traductions$recrutement$parcours$q$compteBancaire$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Do you have a bank account to receive your payment, in your name or a relative\'s?';
	@override String get explication => 'Pay is paid by bank transfer where the academy has confirmed it. Your details are only requested before the first payment.';
	@override String get court => 'Bank account';
	@override late final _Traductions$recrutement$parcours$q$compteBancaire$options$en options = _Traductions$recrutement$parcours$q$compteBancaire$options$en._(_root);
}

// Path: recrutement.parcours.q.operateurs
class _Traductions$recrutement$parcours$q$operateurs$en extends Traductions$recrutement$parcours$q$operateurs$fr {
	_Traductions$recrutement$parcours$q$operateurs$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Which mobile payment methods do you use?';
	@override String get explication => 'Here are the methods the academy has confirmed in your country. Choose those you use, if any.';
	@override String get court => 'Mobile payment methods';
}

// Path: recrutement.parcours.q.moyensAccessibles
class _Traductions$recrutement$parcours$q$moyensAccessibles$en extends Traductions$recrutement$parcours$q$moyensAccessibles$fr {
	_Traductions$recrutement$parcours$q$moyensAccessibles$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Which payment methods are common where you live?';
	@override String get explication => 'Here are the methods the academy knows. Choose those that are common in your country, if any.';
	@override String get court => 'Payment methods of the country';
}

// Path: classe.entree.demo.roles
class _Traductions$classe$entree$demo$roles$en extends Traductions$classe$entree$demo$roles$fr {
	_Traductions$classe$entree$demo$roles$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get eleve => 'Student';
	@override String get guidee => 'Student, Guided interface';
	@override String get enseignant => 'Teacher';
}

// Path: classe.entree.demo.etats
class _Traductions$classe$entree$demo$etats$en extends Traductions$classe$entree$demo$etats$fr {
	_Traductions$classe$entree$demo$etats$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get aVenir => 'Upcoming';
	@override String get fenetreOuverte => 'Window open';
	@override String get preparation => 'Getting ready';
	@override String get attente => 'Waiting before the start';
	@override String get enDirect => 'Live';
	@override String get tempsEcoule => 'Scheduled time elapsed';
	@override String get terminee => 'Ended';
	@override String get annulee => 'Cancelled';
	@override String get horsLigne => 'Offline';
	@override String get indisponible => 'Information unavailable';
	@override String get changementHeure => 'Time change';
}

// Path: classe.cartes.feuille.defauts
class _Traductions$classe$cartes$feuille$defauts$en extends Traductions$classe$cartes$feuille$defauts$fr {
	_Traductions$classe$cartes$feuille$defauts$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titreVide => 'The title is missing. Write a few words, for example "Surah to review".';
	@override String titreLong({required Object max}) => 'The title exceeds ${max} characters. Shorten it.';
	@override String texteLong({required Object max}) => 'The text exceeds ${max} characters. Shorten it or share a link.';
	@override String get lienInvalide => 'This link is not a full address. Paste an address that starts with https://.';
	@override String get echeanceManquante => 'Homework needs a due date. Choose the due date.';
}

// Path: recrutement.parcours.presentation.p1.academie
class _Traductions$recrutement$parcours$presentation$p1$academie$en extends Traductions$recrutement$parcours$presentation$p1$academie$fr {
	_Traductions$recrutement$parcours$presentation$p1$academie$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'An online Quran academy';
	@override String get texte => 'Rewayah Academy teaches the Quran remotely, in stable classes, with a dedicated teacher. It has been teaching since 1 May 2024.';
}

// Path: recrutement.parcours.presentation.p1.liberte
class _Traductions$recrutement$parcours$presentation$p1$liberte$en extends Traductions$recrutement$parcours$presentation$p1$liberte$fr {
	_Traductions$recrutement$parcours$presentation$p1$liberte$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'You remain free';
	@override String get texte => 'As long as you are not a teacher, you can withdraw your application from your file.';
}

// Path: recrutement.parcours.presentation.p1.donnees
class _Traductions$recrutement$parcours$presentation$p1$donnees$en extends Traductions$recrutement$parcours$presentation$p1$donnees$fr {
	_Traductions$recrutement$parcours$presentation$p1$donnees$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Your data is protected';
	@override String get texte => 'Your answers are only read by the people at the academy who review your application.';
}

// Path: recrutement.parcours.presentation.p1.separation
class _Traductions$recrutement$parcours$presentation$p1$separation$en extends Traductions$recrutement$parcours$presentation$p1$separation$fr {
	_Traductions$recrutement$parcours$presentation$p1$separation$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Women and men separated';
	@override String get texte => 'A woman\'s application is followed by the management on the women\'s side, a man\'s application on the men\'s side.';
}

// Path: recrutement.parcours.presentation.p2.classe
class _Traductions$recrutement$parcours$presentation$p2$classe$en extends Traductions$recrutement$parcours$presentation$p2$classe$fr {
	_Traductions$recrutement$parcours$presentation$p2$classe$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'A stable class';
	@override String get texte => 'You keep the same class over time, with the same students.';
}

// Path: recrutement.parcours.presentation.p2.horaires
class _Traductions$recrutement$parcours$presentation$p2$horaires$en extends Traductions$recrutement$parcours$presentation$p2$horaires$fr {
	_Traductions$recrutement$parcours$presentation$p2$horaires$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'The same schedule every week';
	@override String get texte => 'Your class meets on the same days and at the same times, three times a week.';
}

// Path: recrutement.parcours.presentation.p2.visio
class _Traductions$recrutement$parcours$presentation$p2$visio$en extends Traductions$recrutement$parcours$presentation$p2$visio$fr {
	_Traductions$recrutement$parcours$presentation$p2$visio$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'By video, in the app';
	@override String get texte => 'Classes are given by video conference, in the Rewayah app.';
}

// Path: recrutement.parcours.presentation.p2.remuneration
class _Traductions$recrutement$parcours$presentation$p2$remuneration$en extends Traductions$recrutement$parcours$presentation$p2$remuneration$fr {
	_Traductions$recrutement$parcours$presentation$p2$remuneration$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Pay that is explained';
	@override String get texte => 'Your pay is a share of the price each student present pays. It is explained to you as a percentage before you send your application.';
}

// Path: recrutement.parcours.presentation.p3.examen
class _Traductions$recrutement$parcours$presentation$p3$examen$en extends Traductions$recrutement$parcours$presentation$p3$examen$fr {
	_Traductions$recrutement$parcours$presentation$p3$examen$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Your application';
	@override String get texte => 'You answer the questions, read and accept our agreements, upload your photo and your ID document, then send your application. The management reads it.';
}

// Path: recrutement.parcours.presentation.p3.entretien
class _Traductions$recrutement$parcours$presentation$p3$entretien$en extends Traductions$recrutement$parcours$presentation$p3$entretien$fr {
	_Traductions$recrutement$parcours$presentation$p3$entretien$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Let\'s get to know each other';
	@override String get texte => 'If your application is accepted, you choose a slot and the management meets you by video, in the app.';
}

// Path: recrutement.parcours.presentation.p3.verification
class _Traductions$recrutement$parcours$presentation$p3$verification$en extends Traductions$recrutement$parcours$presentation$p3$verification$fr {
	_Traductions$recrutement$parcours$presentation$p3$verification$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Welcome to the team';
	@override String get texte => 'When everything is in order, you join the academy\'s team of teachers, in the app.';
}

// Path: recrutement.parcours.q.niveauMemorisationDeclare.options
class _Traductions$recrutement$parcours$q$niveauMemorisationDeclare$options$en extends Traductions$recrutement$parcours$q$niveauMemorisationDeclare$options$fr {
	_Traductions$recrutement$parcours$q$niveauMemorisationDeclare$options$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$recrutement$parcours$q$niveauMemorisationDeclare$options$aucune$en aucune = _Traductions$recrutement$parcours$q$niveauMemorisationDeclare$options$aucune$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$niveauMemorisationDeclare$options$moins_10_juz$en moins_10_juz = _Traductions$recrutement$parcours$q$niveauMemorisationDeclare$options$moins_10_juz$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$niveauMemorisationDeclare$options$de_10_a_29_juz$en de_10_a_29_juz = _Traductions$recrutement$parcours$q$niveauMemorisationDeclare$options$de_10_a_29_juz$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$niveauMemorisationDeclare$options$coran_entier$en coran_entier = _Traductions$recrutement$parcours$q$niveauMemorisationDeclare$options$coran_entier$en._(_root);
}

// Path: recrutement.parcours.q.niveauLectureTajwid.options
class _Traductions$recrutement$parcours$q$niveauLectureTajwid$options$en extends Traductions$recrutement$parcours$q$niveauLectureTajwid$options$fr {
	_Traductions$recrutement$parcours$q$niveauLectureTajwid$options$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$recrutement$parcours$q$niveauLectureTajwid$options$lecture_sans_regles_tajwid$en lecture_sans_regles_tajwid = _Traductions$recrutement$parcours$q$niveauLectureTajwid$options$lecture_sans_regles_tajwid$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$niveauLectureTajwid$options$tajwid_applique$en tajwid_applique = _Traductions$recrutement$parcours$q$niveauLectureTajwid$options$tajwid_applique$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$niveauLectureTajwid$options$tajwid_enseigne$en tajwid_enseigne = _Traductions$recrutement$parcours$q$niveauLectureTajwid$options$tajwid_enseigne$en._(_root);
}

// Path: recrutement.parcours.q.riwayat.options
class _Traductions$recrutement$parcours$q$riwayat$options$en extends Traductions$recrutement$parcours$q$riwayat$options$fr {
	_Traductions$recrutement$parcours$q$riwayat$options$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$recrutement$parcours$q$riwayat$options$hafs$en hafs = _Traductions$recrutement$parcours$q$riwayat$options$hafs$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$riwayat$options$shuba$en shuba = _Traductions$recrutement$parcours$q$riwayat$options$shuba$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$riwayat$options$warsh$en warsh = _Traductions$recrutement$parcours$q$riwayat$options$warsh$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$riwayat$options$qalun$en qalun = _Traductions$recrutement$parcours$q$riwayat$options$qalun$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$riwayat$options$al_bazzi$en al_bazzi = _Traductions$recrutement$parcours$q$riwayat$options$al_bazzi$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$riwayat$options$qunbul$en qunbul = _Traductions$recrutement$parcours$q$riwayat$options$qunbul$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$riwayat$options$ad_duri_abi_amr$en ad_duri_abi_amr = _Traductions$recrutement$parcours$q$riwayat$options$ad_duri_abi_amr$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$riwayat$options$as_susi$en as_susi = _Traductions$recrutement$parcours$q$riwayat$options$as_susi$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$riwayat$options$hisham$en hisham = _Traductions$recrutement$parcours$q$riwayat$options$hisham$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$riwayat$options$ibn_dhakwan$en ibn_dhakwan = _Traductions$recrutement$parcours$q$riwayat$options$ibn_dhakwan$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$riwayat$options$khalaf_an_hamza$en khalaf_an_hamza = _Traductions$recrutement$parcours$q$riwayat$options$khalaf_an_hamza$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$riwayat$options$khallad$en khallad = _Traductions$recrutement$parcours$q$riwayat$options$khallad$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$riwayat$options$abu_al_harith$en abu_al_harith = _Traductions$recrutement$parcours$q$riwayat$options$abu_al_harith$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$riwayat$options$ad_duri_al_kisai$en ad_duri_al_kisai = _Traductions$recrutement$parcours$q$riwayat$options$ad_duri_al_kisai$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$riwayat$options$ibn_wardan$en ibn_wardan = _Traductions$recrutement$parcours$q$riwayat$options$ibn_wardan$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$riwayat$options$ibn_jammaz$en ibn_jammaz = _Traductions$recrutement$parcours$q$riwayat$options$ibn_jammaz$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$riwayat$options$ruways$en ruways = _Traductions$recrutement$parcours$q$riwayat$options$ruways$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$riwayat$options$rawh$en rawh = _Traductions$recrutement$parcours$q$riwayat$options$rawh$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$riwayat$options$ishaq$en ishaq = _Traductions$recrutement$parcours$q$riwayat$options$ishaq$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$riwayat$options$idris$en idris = _Traductions$recrutement$parcours$q$riwayat$options$idris$en._(_root);
}

// Path: recrutement.parcours.q.ijazaPresentable.options
class _Traductions$recrutement$parcours$q$ijazaPresentable$options$en extends Traductions$recrutement$parcours$q$ijazaPresentable$options$fr {
	_Traductions$recrutement$parcours$q$ijazaPresentable$options$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$recrutement$parcours$q$ijazaPresentable$options$oui$en oui = _Traductions$recrutement$parcours$q$ijazaPresentable$options$oui$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$ijazaPresentable$options$pret_test$en pret_test = _Traductions$recrutement$parcours$q$ijazaPresentable$options$pret_test$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$ijazaPresentable$options$non$en non = _Traductions$recrutement$parcours$q$ijazaPresentable$options$non$en._(_root);
}

// Path: recrutement.parcours.q.experienceDebutants.options
class _Traductions$recrutement$parcours$q$experienceDebutants$options$en extends Traductions$recrutement$parcours$q$experienceDebutants$options$fr {
	_Traductions$recrutement$parcours$q$experienceDebutants$options$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$recrutement$parcours$q$experienceDebutants$options$oui$en oui = _Traductions$recrutement$parcours$q$experienceDebutants$options$oui$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$experienceDebutants$options$non$en non = _Traductions$recrutement$parcours$q$experienceDebutants$options$non$en._(_root);
}

// Path: recrutement.parcours.q.disponibilitesDeclarees.heures
class _Traductions$recrutement$parcours$q$disponibilitesDeclarees$heures$en extends Traductions$recrutement$parcours$q$disponibilitesDeclarees$heures$fr {
	_Traductions$recrutement$parcours$q$disponibilitesDeclarees$heures$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String titre({required Object jour}) => 'At what time can you start, on ${jour}?';
	@override String get explication => 'Choose all the times at which you can start a class. The end of the class is calculated for you.';
	@override String get suite => 'You will then say whether it is the same on the other days.';
}

// Path: recrutement.parcours.q.disponibilitesDeclarees.memes
class _Traductions$recrutement$parcours$q$disponibilitesDeclarees$memes$en extends Traductions$recrutement$parcours$q$disponibilitesDeclarees$memes$fr {
	_Traductions$recrutement$parcours$q$disponibilitesDeclarees$memes$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Are these the same times for all these days?';
	@override String explication({required Object jours, required Object premier, required Object heures}) => 'You chose ${jours}. On ${premier}, you start at ${heures}.';
	@override late final _Traductions$recrutement$parcours$q$disponibilitesDeclarees$memes$oui$en oui = _Traductions$recrutement$parcours$q$disponibilitesDeclarees$memes$oui$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$disponibilitesDeclarees$memes$non$en non = _Traductions$recrutement$parcours$q$disponibilitesDeclarees$memes$non$en._(_root);
}

// Path: recrutement.parcours.q.disponibilitesDeclarees.parJour
class _Traductions$recrutement$parcours$q$disponibilitesDeclarees$parJour$en extends Traductions$recrutement$parcours$q$disponibilitesDeclarees$parJour$fr {
	_Traductions$recrutement$parcours$q$disponibilitesDeclarees$parJour$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Set the times, day by day';
	@override String get explication => 'Each day starts from the times already chosen. Add or remove times where it is not the same.';
}

// Path: recrutement.parcours.q.disponibilitesDeclarees.semaine
class _Traductions$recrutement$parcours$q$disponibilitesDeclarees$semaine$en extends Traductions$recrutement$parcours$q$disponibilitesDeclarees$semaine$fr {
	_Traductions$recrutement$parcours$q$disponibilitesDeclarees$semaine$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Your week';
	@override String get explication => 'Here is when you can teach, in your local time. Review it, then continue.';
}

// Path: recrutement.parcours.q.debutPossible.options
class _Traductions$recrutement$parcours$q$debutPossible$options$en extends Traductions$recrutement$parcours$q$debutPossible$options$fr {
	_Traductions$recrutement$parcours$q$debutPossible$options$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$recrutement$parcours$q$debutPossible$options$immediat$en immediat = _Traductions$recrutement$parcours$q$debutPossible$options$immediat$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$debutPossible$options$mois_prochain$en mois_prochain = _Traductions$recrutement$parcours$q$debutPossible$options$mois_prochain$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$debutPossible$options$sous_3_mois$en sous_3_mois = _Traductions$recrutement$parcours$q$debutPossible$options$sous_3_mois$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$debutPossible$options$inconnu$en inconnu = _Traductions$recrutement$parcours$q$debutPossible$options$inconnu$en._(_root);
}

// Path: recrutement.parcours.q.publics.options
class _Traductions$recrutement$parcours$q$publics$options$en extends Traductions$recrutement$parcours$q$publics$options$fr {
	_Traductions$recrutement$parcours$q$publics$options$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$recrutement$parcours$q$publics$options$o_6_9$en o_6_9 = _Traductions$recrutement$parcours$q$publics$options$o_6_9$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$publics$options$o_10_13$en o_10_13 = _Traductions$recrutement$parcours$q$publics$options$o_10_13$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$publics$options$o_14_17$en o_14_17 = _Traductions$recrutement$parcours$q$publics$options$o_14_17$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$publics$options$adultes$en adultes = _Traductions$recrutement$parcours$q$publics$options$adultes$en._(_root);
}

// Path: recrutement.parcours.q.compteBancaire.options
class _Traductions$recrutement$parcours$q$compteBancaire$options$en extends Traductions$recrutement$parcours$q$compteBancaire$options$fr {
	_Traductions$recrutement$parcours$q$compteBancaire$options$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$recrutement$parcours$q$compteBancaire$options$oui$en oui = _Traductions$recrutement$parcours$q$compteBancaire$options$oui$en._(_root);
	@override late final _Traductions$recrutement$parcours$q$compteBancaire$options$non$en non = _Traductions$recrutement$parcours$q$compteBancaire$options$non$en._(_root);
}

// Path: recrutement.parcours.q.niveauMemorisationDeclare.options.aucune
class _Traductions$recrutement$parcours$q$niveauMemorisationDeclare$options$aucune$en extends Traductions$recrutement$parcours$q$niveauMemorisationDeclare$options$aucune$fr {
	_Traductions$recrutement$parcours$q$niveauMemorisationDeclare$options$aucune$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'I have not memorised a whole juz';
	@override String get description => 'You may know a few surahs, but not a whole juz.';
	@override String get explication => 'This level is assessed during the interview.';
	@override String get exemple => 'you recite a few short surahs from memory, but not a whole juz.';
}

// Path: recrutement.parcours.q.niveauMemorisationDeclare.options.moins_10_juz
class _Traductions$recrutement$parcours$q$niveauMemorisationDeclare$options$moins_10_juz$en extends Traductions$recrutement$parcours$q$niveauMemorisationDeclare$options$moins_10_juz$fr {
	_Traductions$recrutement$parcours$q$niveauMemorisationDeclare$options$moins_10_juz$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'I have memorised fewer than 10 juz';
	@override String get description => 'From one whole juz to nine juz, out of the thirty of the Quran.';
	@override String get explication => 'This level is assessed during the interview.';
	@override String get exemple => 'you have memorised five juz out of thirty.';
}

// Path: recrutement.parcours.q.niveauMemorisationDeclare.options.de_10_a_29_juz
class _Traductions$recrutement$parcours$q$niveauMemorisationDeclare$options$de_10_a_29_juz$en extends Traductions$recrutement$parcours$q$niveauMemorisationDeclare$options$de_10_a_29_juz$fr {
	_Traductions$recrutement$parcours$q$niveauMemorisationDeclare$options$de_10_a_29_juz$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'I have memorised 10 to 29 juz';
	@override String get description => 'From a third of the Quran to almost all of it.';
	@override String get explication => 'This level is assessed during the interview.';
	@override String get exemple => 'you have memorised twenty juz out of thirty.';
}

// Path: recrutement.parcours.q.niveauMemorisationDeclare.options.coran_entier
class _Traductions$recrutement$parcours$q$niveauMemorisationDeclare$options$coran_entier$en extends Traductions$recrutement$parcours$q$niveauMemorisationDeclare$options$coran_entier$fr {
	_Traductions$recrutement$parcours$q$niveauMemorisationDeclare$options$coran_entier$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'I have memorised the whole Quran';
	@override String get description => 'All 114 surahs, from the first to the last, by heart.';
	@override String get explication => 'This level is assessed during the interview.';
	@override String get exemple => 'you recite Al-Baqara, then An-Nas, without opening the book.';
}

// Path: recrutement.parcours.q.niveauLectureTajwid.options.lecture_sans_regles_tajwid
class _Traductions$recrutement$parcours$q$niveauLectureTajwid$options$lecture_sans_regles_tajwid$en extends Traductions$recrutement$parcours$q$niveauLectureTajwid$options$lecture_sans_regles_tajwid$fr {
	_Traductions$recrutement$parcours$q$niveauLectureTajwid$options$lecture_sans_regles_tajwid$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'I read without applying the tajwid rules';
	@override String get description => 'You read fluently, without following the pronunciation rules.';
	@override String get explication => 'Your reading is assessed during the interview.';
	@override String get exemple => 'you read a page without hesitating, but you do not apply the tajwid rules.';
}

// Path: recrutement.parcours.q.niveauLectureTajwid.options.tajwid_applique
class _Traductions$recrutement$parcours$q$niveauLectureTajwid$options$tajwid_applique$en extends Traductions$recrutement$parcours$q$niveauLectureTajwid$options$tajwid_applique$fr {
	_Traductions$recrutement$parcours$q$niveauLectureTajwid$options$tajwid_applique$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'I apply the tajwid rules when reading';
	@override String get description => 'You follow the pronunciation rules when you read.';
	@override String get explication => 'Your reading is assessed during the interview.';
	@override String get exemple => 'you lengthen and pronounce letters as the tajwid rules require.';
}

// Path: recrutement.parcours.q.niveauLectureTajwid.options.tajwid_enseigne
class _Traductions$recrutement$parcours$q$niveauLectureTajwid$options$tajwid_enseigne$en extends Traductions$recrutement$parcours$q$niveauLectureTajwid$options$tajwid_enseigne$fr {
	_Traductions$recrutement$parcours$q$niveauLectureTajwid$options$tajwid_enseigne$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'I apply tajwid and I can teach it';
	@override String get description => 'You follow the rules and can explain them to a student.';
	@override String get explication => 'Your reading is assessed during the interview.';
	@override String get exemple => 'when a student makes a mistake on a letter, you explain the rule and they repeat it.';
}

// Path: recrutement.parcours.q.riwayat.options.hafs
class _Traductions$recrutement$parcours$q$riwayat$options$hafs$en extends Traductions$recrutement$parcours$q$riwayat$options$hafs$fr {
	_Traductions$recrutement$parcours$q$riwayat$options$hafs$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Hafs';
	@override String get description => 'Transmitted from Asim';
}

// Path: recrutement.parcours.q.riwayat.options.shuba
class _Traductions$recrutement$parcours$q$riwayat$options$shuba$en extends Traductions$recrutement$parcours$q$riwayat$options$shuba$fr {
	_Traductions$recrutement$parcours$q$riwayat$options$shuba$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Shuba';
	@override String get description => 'Transmitted from Asim';
}

// Path: recrutement.parcours.q.riwayat.options.warsh
class _Traductions$recrutement$parcours$q$riwayat$options$warsh$en extends Traductions$recrutement$parcours$q$riwayat$options$warsh$fr {
	_Traductions$recrutement$parcours$q$riwayat$options$warsh$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Warsh';
	@override String get description => 'Transmitted from Nafi';
}

// Path: recrutement.parcours.q.riwayat.options.qalun
class _Traductions$recrutement$parcours$q$riwayat$options$qalun$en extends Traductions$recrutement$parcours$q$riwayat$options$qalun$fr {
	_Traductions$recrutement$parcours$q$riwayat$options$qalun$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Qalun';
	@override String get description => 'Transmitted from Nafi';
}

// Path: recrutement.parcours.q.riwayat.options.al_bazzi
class _Traductions$recrutement$parcours$q$riwayat$options$al_bazzi$en extends Traductions$recrutement$parcours$q$riwayat$options$al_bazzi$fr {
	_Traductions$recrutement$parcours$q$riwayat$options$al_bazzi$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Al-Bazzi';
	@override String get description => 'Transmitted from Ibn Kathir';
}

// Path: recrutement.parcours.q.riwayat.options.qunbul
class _Traductions$recrutement$parcours$q$riwayat$options$qunbul$en extends Traductions$recrutement$parcours$q$riwayat$options$qunbul$fr {
	_Traductions$recrutement$parcours$q$riwayat$options$qunbul$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Qunbul';
	@override String get description => 'Transmitted from Ibn Kathir';
}

// Path: recrutement.parcours.q.riwayat.options.ad_duri_abi_amr
class _Traductions$recrutement$parcours$q$riwayat$options$ad_duri_abi_amr$en extends Traductions$recrutement$parcours$q$riwayat$options$ad_duri_abi_amr$fr {
	_Traductions$recrutement$parcours$q$riwayat$options$ad_duri_abi_amr$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Ad-Duri (Abu Amr)';
	@override String get description => 'Transmitted from Abu Amr';
}

// Path: recrutement.parcours.q.riwayat.options.as_susi
class _Traductions$recrutement$parcours$q$riwayat$options$as_susi$en extends Traductions$recrutement$parcours$q$riwayat$options$as_susi$fr {
	_Traductions$recrutement$parcours$q$riwayat$options$as_susi$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'As-Susi';
	@override String get description => 'Transmitted from Abu Amr';
}

// Path: recrutement.parcours.q.riwayat.options.hisham
class _Traductions$recrutement$parcours$q$riwayat$options$hisham$en extends Traductions$recrutement$parcours$q$riwayat$options$hisham$fr {
	_Traductions$recrutement$parcours$q$riwayat$options$hisham$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Hisham';
	@override String get description => 'Transmitted from Ibn Amir';
}

// Path: recrutement.parcours.q.riwayat.options.ibn_dhakwan
class _Traductions$recrutement$parcours$q$riwayat$options$ibn_dhakwan$en extends Traductions$recrutement$parcours$q$riwayat$options$ibn_dhakwan$fr {
	_Traductions$recrutement$parcours$q$riwayat$options$ibn_dhakwan$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Ibn Dhakwan';
	@override String get description => 'Transmitted from Ibn Amir';
}

// Path: recrutement.parcours.q.riwayat.options.khalaf_an_hamza
class _Traductions$recrutement$parcours$q$riwayat$options$khalaf_an_hamza$en extends Traductions$recrutement$parcours$q$riwayat$options$khalaf_an_hamza$fr {
	_Traductions$recrutement$parcours$q$riwayat$options$khalaf_an_hamza$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Khalaf (Hamza)';
	@override String get description => 'Transmitted from Hamza';
}

// Path: recrutement.parcours.q.riwayat.options.khallad
class _Traductions$recrutement$parcours$q$riwayat$options$khallad$en extends Traductions$recrutement$parcours$q$riwayat$options$khallad$fr {
	_Traductions$recrutement$parcours$q$riwayat$options$khallad$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Khallad';
	@override String get description => 'Transmitted from Hamza';
}

// Path: recrutement.parcours.q.riwayat.options.abu_al_harith
class _Traductions$recrutement$parcours$q$riwayat$options$abu_al_harith$en extends Traductions$recrutement$parcours$q$riwayat$options$abu_al_harith$fr {
	_Traductions$recrutement$parcours$q$riwayat$options$abu_al_harith$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Abu al-Harith';
	@override String get description => 'Transmitted from Al-Kisai';
}

// Path: recrutement.parcours.q.riwayat.options.ad_duri_al_kisai
class _Traductions$recrutement$parcours$q$riwayat$options$ad_duri_al_kisai$en extends Traductions$recrutement$parcours$q$riwayat$options$ad_duri_al_kisai$fr {
	_Traductions$recrutement$parcours$q$riwayat$options$ad_duri_al_kisai$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Ad-Duri (Al-Kisai)';
	@override String get description => 'Transmitted from Al-Kisai';
}

// Path: recrutement.parcours.q.riwayat.options.ibn_wardan
class _Traductions$recrutement$parcours$q$riwayat$options$ibn_wardan$en extends Traductions$recrutement$parcours$q$riwayat$options$ibn_wardan$fr {
	_Traductions$recrutement$parcours$q$riwayat$options$ibn_wardan$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Ibn Wardan';
	@override String get description => 'Transmitted from Abu Jafar';
}

// Path: recrutement.parcours.q.riwayat.options.ibn_jammaz
class _Traductions$recrutement$parcours$q$riwayat$options$ibn_jammaz$en extends Traductions$recrutement$parcours$q$riwayat$options$ibn_jammaz$fr {
	_Traductions$recrutement$parcours$q$riwayat$options$ibn_jammaz$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Ibn Jammaz';
	@override String get description => 'Transmitted from Abu Jafar';
}

// Path: recrutement.parcours.q.riwayat.options.ruways
class _Traductions$recrutement$parcours$q$riwayat$options$ruways$en extends Traductions$recrutement$parcours$q$riwayat$options$ruways$fr {
	_Traductions$recrutement$parcours$q$riwayat$options$ruways$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Ruways';
	@override String get description => 'Transmitted from Yaqub';
}

// Path: recrutement.parcours.q.riwayat.options.rawh
class _Traductions$recrutement$parcours$q$riwayat$options$rawh$en extends Traductions$recrutement$parcours$q$riwayat$options$rawh$fr {
	_Traductions$recrutement$parcours$q$riwayat$options$rawh$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Rawh';
	@override String get description => 'Transmitted from Yaqub';
}

// Path: recrutement.parcours.q.riwayat.options.ishaq
class _Traductions$recrutement$parcours$q$riwayat$options$ishaq$en extends Traductions$recrutement$parcours$q$riwayat$options$ishaq$fr {
	_Traductions$recrutement$parcours$q$riwayat$options$ishaq$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Ishaq';
	@override String get description => 'Transmitted from Khalaf, the tenth reciter';
}

// Path: recrutement.parcours.q.riwayat.options.idris
class _Traductions$recrutement$parcours$q$riwayat$options$idris$en extends Traductions$recrutement$parcours$q$riwayat$options$idris$fr {
	_Traductions$recrutement$parcours$q$riwayat$options$idris$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Idris';
	@override String get description => 'Transmitted from Khalaf, the tenth reciter';
}

// Path: recrutement.parcours.q.ijazaPresentable.options.oui
class _Traductions$recrutement$parcours$q$ijazaPresentable$options$oui$en extends Traductions$recrutement$parcours$q$ijazaPresentable$options$oui$fr {
	_Traductions$recrutement$parcours$q$ijazaPresentable$options$oui$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Yes, I have an ijaza to present';
	@override String get description => 'You can show it by video.';
	@override String get explication => 'It is shown during the interview: you have nothing to send now.';
	@override String get exemple => 'a document signed by your teacher, which you keep at home.';
}

// Path: recrutement.parcours.q.ijazaPresentable.options.pret_test
class _Traductions$recrutement$parcours$q$ijazaPresentable$options$pret_test$en extends Traductions$recrutement$parcours$q$ijazaPresentable$options$pret_test$fr {
	_Traductions$recrutement$parcours$q$ijazaPresentable$options$pret_test$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'No ijaza, but I can take a test';
	@override String get description => 'You have no ijaza to present, but you agree to take a test.';
	@override String get explication => 'The academy will discuss it with you during the interview.';
	@override String get exemple => 'you learned with a teacher without a written document, and you agree to be tested.';
}

// Path: recrutement.parcours.q.ijazaPresentable.options.non
class _Traductions$recrutement$parcours$q$ijazaPresentable$options$non$en extends Traductions$recrutement$parcours$q$ijazaPresentable$options$non$fr {
	_Traductions$recrutement$parcours$q$ijazaPresentable$options$non$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'No, I do not have an ijaza';
	@override String get description => 'You have no ijaza, and you do not plan to take a test for now.';
	@override String get explication => 'Your level is then assessed during the interview.';
	@override String get exemple => 'you learned with a teacher, without receiving a written document.';
}

// Path: recrutement.parcours.q.experienceDebutants.options.oui
class _Traductions$recrutement$parcours$q$experienceDebutants$options$oui$en extends Traductions$recrutement$parcours$q$experienceDebutants$options$oui$fr {
	_Traductions$recrutement$parcours$q$experienceDebutants$options$oui$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Yes, I have already taught beginners';
	@override String get description => 'You have already guided students who are just starting.';
	@override String get explication => 'The management knows before the interview.';
	@override String get exemple => 'you taught the Arabic letters to children or to adults.';
}

// Path: recrutement.parcours.q.experienceDebutants.options.non
class _Traductions$recrutement$parcours$q$experienceDebutants$options$non$en extends Traductions$recrutement$parcours$q$experienceDebutants$options$non$fr {
	_Traductions$recrutement$parcours$q$experienceDebutants$options$non$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'No, not yet';
	@override String get description => 'You have not yet taught beginners.';
	@override String get explication => 'You can still send your application.';
	@override String get exemple => 'you have only taught students who already knew how to read.';
}

// Path: recrutement.parcours.q.disponibilitesDeclarees.memes.oui
class _Traductions$recrutement$parcours$q$disponibilitesDeclarees$memes$oui$en extends Traductions$recrutement$parcours$q$disponibilitesDeclarees$memes$oui$fr {
	_Traductions$recrutement$parcours$q$disponibilitesDeclarees$memes$oui$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Yes, the same times';
	@override String description({required Object premier, required Object autres}) => 'The times for ${premier} also apply to ${autres}.';
	@override String get explication => 'You can change a day before sending your application.';
	@override String get exemple => 'you can start at 6 pm on Monday, Wednesday and Friday.';
}

// Path: recrutement.parcours.q.disponibilitesDeclarees.memes.non
class _Traductions$recrutement$parcours$q$disponibilitesDeclarees$memes$non$en extends Traductions$recrutement$parcours$q$disponibilitesDeclarees$memes$non$fr {
	_Traductions$recrutement$parcours$q$disponibilitesDeclarees$memes$non$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'No, day by day';
	@override String get description => 'You set the times for each day, one after the other.';
	@override String get explication => 'The times already chosen stay: you adjust them.';
	@override String get exemple => 'you start at 6 pm on Monday, but at 8 pm on Wednesday.';
}

// Path: recrutement.parcours.q.debutPossible.options.immediat
class _Traductions$recrutement$parcours$q$debutPossible$options$immediat$en extends Traductions$recrutement$parcours$q$debutPossible$options$immediat$fr {
	_Traductions$recrutement$parcours$q$debutPossible$options$immediat$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Right now';
	@override String get description => 'You can start as soon as a class is assigned to you.';
	@override String get exemple => 'no commitment holds you back this month.';
}

// Path: recrutement.parcours.q.debutPossible.options.mois_prochain
class _Traductions$recrutement$parcours$q$debutPossible$options$mois_prochain$en extends Traductions$recrutement$parcours$q$debutPossible$options$mois_prochain$fr {
	_Traductions$recrutement$parcours$q$debutPossible$options$mois_prochain$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Next month';
	@override String get description => 'You will be available from next month.';
	@override String get exemple => 'you finish another job at the end of this month.';
}

// Path: recrutement.parcours.q.debutPossible.options.sous_3_mois
class _Traductions$recrutement$parcours$q$debutPossible$options$sous_3_mois$en extends Traductions$recrutement$parcours$q$debutPossible$options$sous_3_mois$fr {
	_Traductions$recrutement$parcours$q$debutPossible$options$sous_3_mois$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'In less than three months';
	@override String get description => 'You will be available within the next three months.';
	@override String get exemple => 'you are travelling or sitting exams for a few weeks.';
}

// Path: recrutement.parcours.q.debutPossible.options.inconnu
class _Traductions$recrutement$parcours$q$debutPossible$options$inconnu$en extends Traductions$recrutement$parcours$q$debutPossible$options$inconnu$fr {
	_Traductions$recrutement$parcours$q$debutPossible$options$inconnu$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'I don\'t know yet';
	@override String get description => 'You do not yet know your start date.';
	@override String get explication => 'You can tell the management during the interview.';
	@override String get exemple => 'your schedule depends on an answer you are still waiting for.';
}

// Path: recrutement.parcours.q.publics.options.o_6_9
class _Traductions$recrutement$parcours$q$publics$options$o_6_9$en extends Traductions$recrutement$parcours$q$publics$options$o_6_9$fr {
	_Traductions$recrutement$parcours$q$publics$options$o_6_9$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Children aged 6 to 9';
	@override String get description => 'They start with Rewayah\'s reading book, letter by letter, up to the shadda. Then come the first short surahs, the words of the prayer and the ablutions.';
	@override String get explication => 'Classes of 5 children at most (4 for beginners), three one-hour sessions per week. The ablutions and the prayer are shown in practice, with illustrations.';
	@override String get exemple => 'a class of eight-year-olds, on Monday, Wednesday and Friday.';
}

// Path: recrutement.parcours.q.publics.options.o_10_13
class _Traductions$recrutement$parcours$q$publics$options$o_10_13$en extends Traductions$recrutement$parcours$q$publics$options$o_10_13$fr {
	_Traductions$recrutement$parcours$q$publics$options$o_10_13$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Children aged 10 to 13';
	@override String get description => 'Same start with the reading book, and Al-Fatiha from the first week, because at this age the child must pray.';
	@override String get explication => 'Classes of 5 children at most (4 for beginners), three one-hour sessions per week.';
	@override String get exemple => 'a class of twelve-year-olds, three times a week.';
}

// Path: recrutement.parcours.q.publics.options.o_14_17
class _Traductions$recrutement$parcours$q$publics$options$o_14_17$en extends Traductions$recrutement$parcours$q$publics$options$o_14_17$fr {
	_Traductions$recrutement$parcours$q$publics$options$o_14_17$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Teenagers aged 14 to 17';
	@override String get description => 'The same content as for ages 10 to 13: the reading book, and Al-Fatiha from the first week.';
	@override String get explication => 'Classes of 5 teenagers at most (4 for beginners), three one-hour sessions per week.';
	@override String get exemple => 'a class of sixteen-year-olds, three times a week.';
}

// Path: recrutement.parcours.q.publics.options.adultes
class _Traductions$recrutement$parcours$q$publics$options$adultes$en extends Traductions$recrutement$parcours$q$publics$options$adultes$fr {
	_Traductions$recrutement$parcours$q$publics$options$adultes$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Adults (18 and over)';
	@override String get description => 'Adults first learn to read with Rewayah\'s book. After the basics, the student chooses to read the whole Quran or to memorise it, on the teacher\'s advice.';
	@override String get explication => 'Classes of 6 adults at most (4 for beginners), three sessions of an hour and a half per week. Adult classes are separate: women with women, men with men.';
	@override String get exemple => 'a women\'s class, or a men\'s class, three times a week.';
}

// Path: recrutement.parcours.q.compteBancaire.options.oui
class _Traductions$recrutement$parcours$q$compteBancaire$options$oui$en extends Traductions$recrutement$parcours$q$compteBancaire$options$oui$fr {
	_Traductions$recrutement$parcours$q$compteBancaire$options$oui$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'Yes, in my name or a relative\'s';
	@override String get description => 'An account at a bank, in your name or a relative\'s.';
	@override String get explication => 'Bank transfer can be your payment method, if the academy has confirmed it in your country.';
	@override String get exemple => 'an account opened at a bank, in your brother\'s name.';
}

// Path: recrutement.parcours.q.compteBancaire.options.non
class _Traductions$recrutement$parcours$q$compteBancaire$options$non$en extends Traductions$recrutement$parcours$q$compteBancaire$options$non$fr {
	_Traductions$recrutement$parcours$q$compteBancaire$options$non$en._(TraductionsEn root) : this._root = root, super.internal(root);

	final TraductionsEn _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'No, I don\'t have one';
	@override String get description => 'Neither in your name, nor in a relative\'s.';
	@override String get explication => 'You can then choose a mobile payment method, if there is one in your country.';
	@override String get exemple => 'you only receive and send money with your phone.';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TraductionsEn {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'commun.langue.systeme' => 'System',
			'commun.langue.francais' => 'Français',
			'commun.langue.arabe' => 'العربية',
			'commun.langue.anglais' => 'English',
			'commun.formats.dateHeure' => ({required Object date, required Object heure}) => '${date} at ${heure}',
			'commun.formats.minutes' => ({required Object minutes}) => '${minutes} min',
			'commun.formats.pageSur' => ({required Object page, required Object total}) => 'Page ${page} of ${total}',
			'commun.roles.eleve' => 'Student',
			'commun.roles.tuteur' => 'Guardian',
			'commun.roles.enseignant' => 'Teacher',
			'commun.roles.administration' => 'Administration',
			'commun.roles.comptable' => 'Accountant',
			'commun.classeDistincte.numero' => ({required Object libelle, required Object numero}) => '${libelle} · no. ${numero}',
			'commun.classeDistincte.code' => ({required Object libelle, required Object code}) => '${libelle} · ${code}',
			'commun.classeDistincte.enseignant' => ({required Object libelle, required Object enseignant}) => '${libelle} · with ${enseignant}',
			'commun.continuer' => 'Continue',
			'commun.retour' => 'Back',
			'commun.valider' => 'Confirm',
			'commun.annuler' => 'Cancel',
			'commun.fermer' => 'Close',
			'commun.erreurElement' => 'This item could not be displayed. Try again in a moment.',
			'commun.reessayer' => 'Try again',
			'commun.chargement' => 'Loading',
			'commun.reussite' => 'Done.',
			'commun.etape.sur' => ({required Object n, required Object total}) => '${n} of ${total}',
			'commun.etape.surLue' => ({required Object n, required Object total}) => 'Step ${n} of ${total}',
			'commun.choix.indisponible' => 'Unavailable',
			'commun.champDate.choisir' => 'Choose a date',
			'commun.champDate.aide' => 'Between today and one year from now.',
			'commun.etats.recharge1.ouvertureTitre' => 'This screen did not open',
			'commun.etats.recharge1.ouverturePhrase' => 'Loading was interrupted. Try again; if it keeps happening, reload the page.',
			'commun.etats.recharge1.repetePhrase' => 'Loading was interrupted again. Reload the page to open this screen: you stay signed in.',
			'commun.etats.recharge1.versionPhrase' => 'Reload the page to open this screen: you stay signed in.',
			'commun.etats.branchementServeur' => 'Available once the server is connected',
			'commun.etats.chargementProlonge.titre' => 'The connection is taking longer than expected',
			'commun.etats.chargementProlonge.phrase' => 'You can wait a little longer or try again.',
			'commun.etats.horsLigne.titre' => 'You are offline',
			'commun.etats.horsLigne.phrase' => 'Check your connection. What is already displayed stays available.',
			'commun.etats.reconnexion.titre' => 'Reconnecting',
			'commun.etats.reconnexion.phrase' => 'A new connection attempt is in progress.',
			'commun.etats.echecServeur.titre' => 'Unable to load this information',
			'commun.etats.echecServeur.phrase' => 'Loading did not complete. Try again in a moment.',
			'commun.etats.introuvable.titre' => 'This page cannot be found',
			'commun.etats.introuvable.phrase' => 'The link may be incomplete, or the page no longer exists.',
			'commun.etats.accesRefuse.titre' => 'You do not have access to this page',
			'commun.etats.accesRefuse.phrase' => 'This content is not open to your account.',
			'commun.etats.sessionExpiree.titre' => 'Your session has expired',
			'commun.etats.sessionExpiree.phrase' => 'Sign in again to continue.',
			'commun.etats.dossierEnAttente.titre' => 'Your file is pending',
			'commun.etats.dossierEnAttente.phrase' => 'One step remains before this space opens.',
			'commun.etats.aucunResultat.titre' => 'No results',
			'commun.etats.aucunResultat.phrase' => 'Nothing matches for now.',
			'commun.etats.permissionRefusee.titre' => 'Permission denied',
			'commun.etats.permissionRefusee.phrase' => 'Without this permission, this feature cannot open. You can change it in your device settings.',
			'commun.etats.ressourceExpiree.titre' => 'This content is no longer available',
			'commun.etats.ressourceExpiree.phrase' => 'It has been removed, or access to it has ended.',
			'commun.etats.indisponible.titre' => 'Not available yet',
			'commun.etats.indisponible.phrase' => 'This feature is not open yet.',
			'commun.etats.reessaisEpuises' => 'Still no answer. Try again a little later.',
			'commun.etats.horsLigneDemarrageTitre' => 'Your account could not be verified',
			'commun.etats.horsLigneDemarrage' => 'It can be verified when the connection returns. Try again then.',
			'commun.etats.actions.reessayer' => 'Try again',
			'commun.etats.actions.retourAccueil' => 'Back to home',
			'commun.etats.actions.seConnecter' => 'Sign in',
			'commun.etats.actions.seReconnecter' => 'Sign in again',
			'commun.etats.actions.voirDossier' => 'See my file',
			'commun.etats.actions.reinitialiserFiltres' => 'Reset filters',
			'commun.etats.actions.revenir' => 'Go back',
			'commun.entete.retour' => 'Back',
			'commun.entete.notifications' => 'Notifications',
			'commun.entete.notificationsUneNonLue' => 'Notifications, one unread',
			'commun.entete.notificationsNonLues' => ({required Object nombre}) => 'Notifications, ${nombre} unread',
			'commun.selecteurProfils.etiquette' => ({required Object prenom, required Object etat}) => '${prenom}, ${etat}',
			'commun.selecteurProfils.ajouter' => 'Add',
			'commun.selecteurProfils.ajouterSemantique' => 'Add a student profile',
			'commun.theme.groupe' => 'Appearance',
			'commun.theme.clair' => 'Light theme',
			'commun.theme.sombre' => 'Dark theme',
			'commun.demarrage.ouverture' => 'Opening Rewayah',
			'commun.fuseaux.europeParis' => 'Paris',
			'commun.fuseaux.africaConakry' => 'Conakry',
			'commun.fuseaux.americaToronto' => 'Toronto',
			'commun.fuseaux.europeLondon' => 'London',
			'commun.fuseaux.asiaRiyadh' => 'Riyadh',
			'commun.fuseaux.americaLosAngeles' => 'Los Angeles',
			'commun.fuseaux.africaLagos' => 'Lagos',
			'commun.fuseaux.africaAbidjan' => 'Abidjan',
			'commun.fuseaux.americaNewYork' => 'New York',
			'commun.fuseaux.africaCasablanca' => 'Casablanca',
			'commun.fuseaux.asiaTokyo' => 'Tokyo',
			'commun.fuseaux.americaArgentinaBuenosAires' => 'Buenos Aires',
			'commun.fuseaux.africaDakar' => 'Dakar',
			'commun.fuseaux.africaBamako' => 'Bamako',
			'commun.fuseaux.africaNouakchott' => 'Nouakchott',
			'commun.fuseaux.europeBrussels' => 'Brussels',
			'commun.dates.moisAnnee' => ({required Object mois, required Object annee}) => '${mois} ${annee}',
			'commun.dates.choixMois' => 'Month',
			'commun.dates.jours.0' => 'Monday',
			'commun.dates.jours.1' => 'Tuesday',
			'commun.dates.jours.2' => 'Wednesday',
			'commun.dates.jours.3' => 'Thursday',
			'commun.dates.jours.4' => 'Friday',
			'commun.dates.jours.5' => 'Saturday',
			'commun.dates.jours.6' => 'Sunday',
			'commun.dates.mois.0' => 'January',
			'commun.dates.mois.1' => 'February',
			'commun.dates.mois.2' => 'March',
			'commun.dates.mois.3' => 'April',
			'commun.dates.mois.4' => 'May',
			'commun.dates.mois.5' => 'June',
			'commun.dates.mois.6' => 'July',
			'commun.dates.mois.7' => 'August',
			'commun.dates.mois.8' => 'September',
			'commun.dates.mois.9' => 'October',
			'commun.dates.mois.10' => 'November',
			'commun.dates.mois.11' => 'December',
			'commun.dates.jourDate' => ({required Object jour, required Object mois, required Object numero}) => '${jour} ${mois} ${numero}',
			'commun.dates.premierJour' => '1st',
			'commun.sections.page' => 'Page sections',
			'commun.recherche.effacer' => 'Clear search',
			'commun.recherche.fermer' => 'Close search',
			'attente.titre' => 'Your file is being reviewed',
			'attente.dossierIncomplet' => 'Some documents are still missing from your file.',
			'attente.enVerification' => 'We are reviewing your file.',
			'attente.refuse' => 'File refused',
			'attente.suspendu' => 'Your account is suspended.',
			'attente.contacterAcademie' => 'Contact the academy',
			'attente.deposeLe' => ({required Object date}) => 'Submitted on ${date}',
			'attente.delai' => 'Review usually takes less than 48 hours.',
			'attente.aFournir' => 'To provide',
			'attente.pieceIdentite' => 'An ID document',
			'attente.signatureContrat' => 'Signing the contract',
			'attente.carteAccuse' => 'What you need to know',
			'attente.deposerLaPiece' => 'Submit my document',
			'attente.signerLeContrat' => 'Read and sign',
			'attente.lireLaCarte' => 'Read',
			'attente.toutEstDepose' => 'Everything has been submitted.',
			'attente.corriger' => 'Correct',
			'attente.correctionImpossible' => 'This file cannot be edited for now.',
			'attente.actualiser' => 'Reload the file status',
			'attente.suspenduDetail' => 'You can contact the academy to find out what to do.',
			'attente.copieDonnees' => 'To get a copy of your data, write to the academy.',
			'attente.seDeconnecter' => 'Sign out',
			'attente.titreDossier' => 'Your file',
			'attente.titreCompte' => 'Your account',
			'attente.accordsARelire' => 'You still have our terms to read and accept.',
			'attente.demandeTitre' => 'Your request is in progress',
			'attente.demandeMessage' => 'The management reads every request before opening an account.',
			'attente.demandeDetail' => 'You have nothing to send. We write to your email address as soon as the management has replied.',
			'attente.demandePour' => ({required Object liste}) => 'Your request concerns: ${liste}.',
			'attente.demandeRefuseeTitre' => 'We cannot proceed',
			'attente.demandeRefuseeMessage' => 'The management has read your request and cannot proceed with it for now.',
			'attente.demandeRefuseeDetail' => 'The email we sent you gives the reason. You can reply to it with any question.',
			'attente.precisionsTitre' => 'We are missing some information',
			'attente.precisionsMessage' => 'To review your request, the management needs a clarification:',
			'attente.precisionsReponse' => 'Simply reply to the email we sent you. The management resumes your request as soon as you reply.',
			'attente.actualiserCompte' => 'Reload',
			'attente.lireEtAccepter' => 'Read and accept our terms',
			'attente.nosConditions' => 'Our terms, to read and accept',
			'attente.etatAAccepter' => 'To accept',
			'attente.reste' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: 'One item remains to be provided.', other: '${n} items remain to be provided.', ), 
			'attente.etatAFournir' => 'To provide',
			'attente.prochaineEtape' => ({required Object etape}) => 'Next step: ${etape}',
			'attente.refuseDetail' => ({required Object element}) => 'Item to redo: ${element}.',
			'attente.refuseSansElement' => 'You can contact the academy to find out what to do.',
			'attente.illisible' => 'Your account status cannot be displayed for now.',
			'attente.horsLigne' => 'Your account status will be displayed as soon as the network is back.',
			'accords.titre' => 'Our terms',
			'accords.intro' => 'Read each text, then tick the box that follows it. The "Next" button becomes active when everything is ticked.',
			'accords.caseManquante' => 'Tick this box to continue.',
			'accords.introCases' => 'Read each text, then tick the box that follows it.',
			'accords.lireJusquEnBas' => 'Read to the bottom to confirm.',
			'accords.caseSavoir' => 'I have read and understood what I need to know.',
			'accords.sectionContrat' => 'Your contract',
			'accords.caseContrat' => 'I have read and accept my contract, including review visits.',
			'accords.reste' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: 'One agreement remains to be ticked.', other: '${n} agreements remain to be ticked.', ), 
			'accords.toutCoche' => 'Everything is ticked.',
			'accords.suivant' => 'Next',
			'accords.dejaAcceptes' => 'Your agreements are already saved.',
			'accords.cadreNonPublie' => 'Sending your application will be possible once the religious and educational framework is published.',
			'connexion.titre' => 'Sign in',
			'connexion.sessionTermineeTitre' => 'You have been signed out',
			'connexion.sessionTermineePhrase' => 'Your session has ended: this account, or another one, signed in elsewhere, in this browser or on another device. Sign in again here. To use two accounts at the same time, open the second one in a private window or on another device.',
			'connexion.lienAilleursTitre' => 'This link was opened on another device',
			'connexion.lienAilleursPhrase' => 'A sign-in link only opens in the browser where you requested it. Open it on that device: if you started signing up, your answers are saved there. Otherwise, request a new link here.',
			'connexion.modeConnexion' => 'I already have an account',
			'connexion.modeCreation' => 'Create an account',
			'connexion.titreCreation' => 'Create your account',
			'connexion.introCreation' => 'Enter your address: we send you a link that creates your account. No password to choose.',
			'connexion.envoyerLienCreation' => 'Get the sign-up link',
			'connexion.intro' => 'We send you a link by email. No password to remember, so none to lose.',
			'connexion.courriel' => 'Your email address',
			'connexion.courrielIndice' => 'you@example.com',
			'connexion.motDePasseDemo' => 'Demo password',
			'connexion.envoyerLien' => 'Get the link',
			'connexion.entrerDemo' => 'Enter the demo',
			'connexion.introDemo' => 'Demo mode: no link will be sent. You go straight in, without email.',
			'connexion.essayerDemo' => 'Try the demo',
			'connexion.avecGoogle' => 'Continue with Google',
			'connexion.ou' => 'or',
			'connexion.lienEnvoye' => 'Link sent',
			'connexion.lienEnvoyeDetail' => ({required Object courriel}) => 'Open the message sent to ${courriel}, then follow the link. You can leave this page open.',
			'connexion.changerAdresse' => 'Use another address',
			'connexion.erreurCourriel' => 'This address does not look valid.',
			'connexion.erreurEnvoi' => 'The message was not sent. Try again in a moment.',
			'connexion.erreurMotDePasse' => 'Wrong address or password. Check both, or clear the password to receive a link by email.',
			'connexion.appareilEleveAide' => 'Are you a guardian preparing a student\'s device?',
			'connexion.appareilEleve' => 'Connect a student\'s device',
			'connexion.renvoyer' => 'Resend the link',
			'connexion.renvoye' => ({required Object courriel}) => 'A new link was sent to ${courriel}. Use the one in the most recent message.',
			'connexion.inscriptionFermee' => 'Sign-ups are currently by invitation only. Did you apply to teach? You will receive a personal email from us: there is nothing for you to do. Are you a family? Sign-ups reopen soon.',
			'connexion.invitationFoyer.titre' => 'Invitation to join a household',
			'connexion.invitationFoyer.autreAdresse' => 'This invitation is for another address: sign out to open it.',
			'connexion.invitationFoyer.autreAdressePhrase' => 'Nothing was used: the invitation stays valid for the person invited.',
			'connexion.invitationFoyer.creationImpossible' => 'Your account could not be created with this link. Ask the person who invited you to send the invitation again.',
			'connexion.invitationFoyer.plusValable' => 'This invitation is no longer valid.',
			'connexion.invitationFoyer.plusValablePhrase' => 'Ask the person who invited you to send it again.',
			'connexion.erreurTropTot' => 'A link has just been sent. Wait a moment before requesting another.',
			'connexion.horsLigne' => 'The link cannot be sent right now. Try again when the connection is back.',
			'connexion.controle.libelle' => 'Security check',
			'connexion.controle.chargement' => 'Security check in progress.',
			'connexion.controle.erreur' => 'The check did not complete. Try again.',
			'connexion.controle.horsLigne' => 'The check cannot be done right now. Try again when the connection is back.',
			'connexion.probleme' => 'Link expired or never received?',
			'connexion.recuperation.titre' => 'Get back into my account',
			'connexion.recuperation.intro' => 'There is no password to reset: enter your address and we send you a new sign-in link.',
			'connexion.recuperation.lienExpireTitre' => 'This link is no longer valid',
			'connexion.recuperation.lienExpire' => 'A sign-in link works only once and expires after a while. Request a new one below.',
			'connexion.recuperation.lienRefuseTitre' => 'Sign-in did not complete',
			'connexion.recuperation.lienRefuse' => 'This link could not sign you in. Request a new one below.',
			'connexion.recuperation.envoyer' => 'Get a new link',
			'connexion.recuperation.envoyeTitre' => 'New link sent',
			'connexion.recuperation.envoye' => ({required Object courriel}) => 'Open the message sent to ${courriel}, then follow the link.',
			'connexion.recuperation.envoyeEncart' => 'The message can take a few minutes to arrive. Remember to check your spam folder.',
			'connexion.recuperation.autreAdresse' => 'Use another address',
			'connexion.recuperation.revenirConnexion' => 'Back to sign-in',
			'connexion.feuilleAppareil.pourQui' => 'For guardians who are already registered. This screen gives a student in your household their own access, on their tablet or phone, without handing over your account.',
			'connexion.feuilleAppareil.etapesTitre' => 'Where to find the code',
			'connexion.feuilleAppareil.etape1' => 'On your own device, open Household, then Household devices.',
			'connexion.feuilleAppareil.etape2' => 'Tap the student\'s profile, then Connect a device.',
			'connexion.feuilleAppareil.etape3' => 'A QR code and a six-character code appear, with their expiry time.',
			'connexion.feuilleAppareil.etape4' => 'On the student\'s device, scan the QR code or enter the code.',
			'connexion.feuilleAppareil.plafond' => 'The number of devices per student is limited. If the limit is reached, remove one from Household, Household devices.',
			'connexion.feuilleAppareil.saisir' => 'Enter the code',
			'connexion.feuilleAppareil.fermer' => 'Close',
			'inscription.questionnaire.recapLangue' => 'Course language',
			'inscription.questionnaire.prenomQuestion' => 'What is your child\'s name?',
			'inscription.questionnaire.prenomRaison' => 'Their first name is enough. You can register other children at the end.',
			'inscription.questionnaire.prenomIndice' => 'For example: Yasmine',
			'inscription.questionnaire.ageQuestion' => ({required Object prenom}) => 'How old is ${prenom}?',
			'inscription.questionnaire.ageMinimum' => ({required Object min}) => 'The minimum age is ${min}.',
			'inscription.questionnaire.ans' => ({required Object n}) => '${n} years old',
			'inscription.questionnaire.adulte' => '18 or older',
			'inscription.questionnaire.adulteDetail' => 'From 18, everyone registers for themselves, with "I\'m signing up for myself".',
			'inscription.questionnaire.clavierLettres' => 'On a keyboard, press the letter of an answer to choose it.',
			'inscription.questionnaire.genreQuestion' => ({required Object prenom}) => '${prenom} is…',
			'inscription.questionnaire.garcon' => 'A boy',
			'inscription.questionnaire.fille' => 'A girl',
			'inscription.questionnaire.genreRaison' => 'The academy takes this into account when forming classes.',
			'inscription.questionnaire.niveauQuestionMoi' => 'Where are you today?',
			'inscription.questionnaire.etapeCourte' => ({required Object n, required Object total}) => '${n} of ${total}',
			'inscription.questionnaire.recapTitre' => 'Here is what we understood',
			'inscription.questionnaire.recapApprenants' => 'Who is learning',
			'inscription.questionnaire.ligneEnfant' => ({required Object prenom, required Object age}) => '${prenom}, ${age}',
			'inscription.questionnaire.ligneVous' => 'You',
			'inscription.questionnaire.ajouterProfil' => 'Add another student profile',
			'inscription.questionnaire.envoyer' => 'Send my request',
			'inscription.questionnaire.dejaUnCompte' => 'I already have an account',
			'inscription.questionnaire.aucuneReponse' => 'The answers to your sign-up are no longer on this device. Go back to the first questions: they take two minutes.',
			'inscription.questionnaire.acces.titre' => 'Last step: your access',
			'inscription.questionnaire.acces.reponsesGardees' => 'Your answers are saved.',
			'inscription.questionnaire.acces.resteAcces' => 'All that is left is to receive your access link, or to continue with Google.',
			'inscription.titre' => 'Create your account',
			'inscription.etapeSur' => ({required Object n, required Object total}) => 'Step ${n} of ${total}',
			'inscription.tempsRestant' => ({required Object minutes}) => 'About ${minutes} min',
			'inscription.roleQuestion' => 'Are you signing up as a parent or as a teacher?',
			'inscription.roleTuteur' => 'Parent or guardian',
			'inscription.roleEleveAdulte' => 'Adult student, for myself',
			'inscription.roleEnseignant' => 'Teacher',
			'inscription.autreAide' => 'Write to the academy and we will create your access. This page cannot do it for you.',
			'inscription.identiteQuestion' => 'What is your name?',
			'inscription.identiteQuestionFamille' => 'What is your own name, as the parent or guardian?',
			'inscription.identiteAideFamille' => 'Not the child\'s: their student profile will have its own name.',
			'inscription.identiteRaison' => 'This name must match your ID document.',
			'inscription.prenom' => 'First name',
			'inscription.nom' => 'Last name',
			'inscription.genreQuestion' => 'You are',
			'inscription.genreHomme' => 'A man',
			'inscription.genreFemme' => 'A woman',
			'inscription.genreRaison' => 'This answer is only used to have your ID document handled by a staff member of the same gender.',
			'inscription.genreHommeExplication' => 'If you take classes, the academy takes this into account when forming classes and choosing the teacher.',
			'inscription.genreFemmeExplication' => 'If you take classes, the academy takes this into account when forming classes and choosing the teacher.',
			'inscription.genreHommeEnseignant' => 'Your ID document will be reviewed by a man on the team.',
			'inscription.genreFemmeEnseignant' => 'Your ID document will be reviewed by a woman on the team.',
			'inscription.recapitulatif' => 'Before you continue',
			'inscription.creer' => 'Create my account',
			'inscription.erreur' => 'The account could not be created. Try again in a moment.',
			'inscription.champRequis' => 'This answer is needed to continue.',
			'inscription.etapeCourte' => ({required Object n, required Object total}) => '${n} of ${total}',
			'inscription.retourEtape' => 'Back to the previous step',
			'inscription.seDeconnecter' => 'Sign out',
			'inscription.modifier' => 'Edit',
			'inscription.reessayer' => 'Try again',
			'inscription.erreurActualisation' => 'Your account is created, but the sign-in could not be refreshed. Try again, or sign out and sign back in.',
			'inscription.erreurInvitation' => 'Your invitation code could not be used: it has expired, has already been used, or does not match your address. Ask the management for a new code, then enter it again.',
			'inscription.usage.question' => 'Who are you creating this account for?',
			'inscription.usage.moiTitre' => 'I\'m signing up for myself',
			'inscription.usage.moiDescription' => 'You take the classes yourself. Your student profile is created with your account.',
			'inscription.usage.familleTitre' => 'I\'m registering my child',
			'inscription.usage.familleDescription' => 'You register one or more children and follow their progress. You can also take classes yourself.',
			'inscription.usage.enseignant' => 'I have an invitation code',
			'inscription.usage.enseignantInvite' => 'Are you a teacher? The academy invites you by email.',
			'inscription.usage.comptable' => 'I have an accountant code',
			'inscription.usage.comptableInvite' => 'Are you an accountant? The management invites you by email.',
			'inscription.usage.coursQuestion' => 'Do you also take classes?',
			'inscription.usage.coursOui' => 'Yes',
			'inscription.usage.coursNon' => 'No',
			'inscription.usage.moiExemple' => 'you are 18 or older and you are learning recitation for yourself.',
			'inscription.usage.familleExemple' => 'you register Yasmine, 9, and Bilal, 12.',
			'inscription.usage.coursOuiExplication' => 'You take classes yourself too, in addition to those of your family.',
			'inscription.usage.coursOuiExemple' => 'your children attend their class and you attend yours.',
			'inscription.usage.coursNonExplication' => 'You register your family and follow their progress, with no classes for yourself. You can change your mind later.',
			'inscription.usage.coursNonExemple' => 'you register your daughter and follow her sessions from your account.',
			'inscription.usage.enseignantPostuler' => 'Do you want to teach at Rewayah?',
			'inscription.usage.deposerCandidature' => 'Submit my application',
			'inscription.recap.usage' => 'Account type',
			'inscription.recap.identite' => 'Name',
			'inscription.recap.genre' => 'Gender',
			'inscription.recap.enseignant' => 'Teacher',
			'inscription.recap.comptable' => 'Accountant',
			'inscription.recap.cours' => 'Your own classes',
			'inscription.recap.coursOui' => 'You also take classes',
			'inscription.recap.coursNon' => 'No classes for you',
			'inscription.recap.telephone' => 'Phone',
			'inscription.recap.langue' => 'Language',
			'inscription.telephone.question' => 'Your phone number',
			'inscription.telephone.explication' => 'It is used to avoid duplicates and to link your exchanges with the academy to your application. The academy writes to you in the app. It is never shown to other applicants.',
			'inscription.telephone.indicatif' => 'Country code',
			'inscription.telephone.numero' => 'Number, without the country code',
			'inscription.telephone.indicatifManquant' => 'Choose your country code.',
			'inscription.telephone.numeroManquant' => 'Enter your phone number.',
			'inscription.telephone.numeroInvalide' => 'This number is not readable. Write it in digits, without the country code.',
			'inscription.telephone.changerIndicatif' => 'Change country code',
			'inscription.telephone.pays' => 'Country',
			'inscription.telephone.numeroCourt' => 'Number',
			'inscription.telephone.choisirPays' => 'Choose your country',
			'inscription.telephone.rechercherPays' => 'Search for a country or a code',
			'inscription.langue.question' => 'In which language do you want to read the app?',
			'inscription.langue.francais' => 'Français',
			'inscription.langue.arabe' => 'العربية',
			'inscription.langue.francaisExplication' => 'The app and the academy\'s messages are written in French.',
			'inscription.langue.francaisExemple' => 'buttons, explanations and messages are shown from left to right.',
			'inscription.langue.arabeExplication' => 'The app and the academy\'s messages are written in Arabic.',
			'inscription.langue.arabeExemple' => 'buttons, explanations and messages are shown from right to left.',
			'inscription.confidentialite.kCase' => 'I have read and accept the privacy policy.',
			'inscription.confidentialite.lire' => 'Read the privacy policy',
			'inscription.confidentialite.requise' => 'Tick this box to send your application.',
			'inscription.candidat.creationEchec' => 'Your application may not have been sent. Try again in a moment.',
			'inscription.candidat.envoyer' => 'Send my application',
			'inscription.candidat.accueil' => 'You are submitting an application to teach at Rewayah. It does not commit you to anything.',
			'inscription.candidat.ensuite' => 'Next, the management reads your application and writes to you in the app.',
			'inscription.candidat.horsLigne' => 'The application can be sent when the connection is back.',
			'inscription.candidat.courrielAConfirmer' => 'Confirm your address first: open the link you received by email.',
			'inscription.candidat.nonOuverte' => 'Applications without a code are not open yet. If the management gave you a code, enter it.',
			'inscription.candidat.nonConfirmee' => 'Your request may not have reached Rewayah. Try again in a moment.',
			'inscription.candidat.aCorriger' => ({required Object champs}) => 'One answer needs to be corrected: ${champs}. Press "Edit" next to the answer.',
			'inscription.candidat.confidentialitePerimee' => 'The privacy policy text has changed, and the version shown is no longer up to date. Reload the page or update the app, then read the text again.',
			'inscription.candidat.indisponible' => 'Sign-up is not available right now. Try again a little later.',
			'inscription.nomLatin.libelle' => 'Your name in Latin letters',
			'inscription.nomLatin.raison' => 'For lists, certificates and exchanges with the academy.',
			'inscription.nomLatin.aide' => 'Here is our suggestion. Correct it if your name is not written this way.',
			'inscription.nomLatin.erreur' => 'Write your name using Latin alphabet letters (a, b, c) to continue.',
			'codeConduite.titre' => 'Teacher code of conduct',
			'codeConduite.lien' => 'Read the code of conduct',
			'codeConduite.intro' => 'These rules protect students, and they protect you. Read them, then accept.',
			'codeConduite.regles.0' => 'Your classes are held in the academy\'s room. A class may be audio-recorded, and a person in charge of review may follow it live without telling you when. A parent may also attend the class for a limited time, to see how the session goes: you are informed. You accept these measures: they protect children and they protect you.',
			'codeConduite.regles.1' => 'You see your students\' first names. Their full name is not shown, to keep the screen short. You never see a family\'s contact details: no email, no phone.',
			'codeConduite.regles.2' => 'What you know about a child stays with the academy, to protect their personal data. You do not make it public and you do not show it to other families.',
			'codeConduite.regles.3' => 'You never contact a student or their family privately, outside the app.',
			'codeConduite.regles.4' => 'In front of the camera, your dress is appropriate and the background behind you is neutral and calm.',
			'codeConduite.regles.5' => 'You are on time. You open the room before the class starts.',
			'codeConduite.regles.6' => 'You are also callers to the faith: be exemplary in your words and gestures, and patient with each student.',
			'codeConduite.regles.7' => 'If a child\'s safety worries you, report it right away with "Report a need", category "A child\'s safety". The management reads it first.',
			'codeConduite.regles.8' => 'If you refuse these rules, the academy cannot entrust students to you, because they protect children.',
			'codeConduite.caseAccord' => 'I have read the code of conduct and I accept it.',
			'codeConduite.accepter' => 'I accept the code of conduct',
			'codeConduite.accepteLe' => ({required Object date, required Object version}) => 'Accepted on ${date}. Version ${version}.',
			'codeConduite.erreur' => 'Your agreement was not saved. Try again in a moment.',
			'codeConduite.erreurLecture' => 'We could not load your agreements. Try again.',
			'codeConduite.aAccepter' => 'To accept',
			'consentement.titre' => 'Consents',
			'consentement.texte.titre' => 'Parent visits',
			'consentement.texte.quiResponsable' => 'The parents of the students present can briefly observe the session.',
			'consentement.texte.quiResponsableDetail' => 'They hear the teacher and the students who speak, including your child. Their microphone and camera stay off: they can neither speak, nor write, nor appear on screen.',
			'consentement.texte.quiAdulte' => 'The parents of the other students present can briefly observe the session.',
			'consentement.texte.quiAdulteDetail' => 'They hear the teacher and the students who speak, including you. Their microphone and camera stay off: they can neither speak, nor write, nor appear on screen.',
			'consentement.texte.pourquoi' => 'To follow learning without interrupting the class.',
			'consentement.texte.pourquoiDetail' => 'A parent comes to see whether their child is taking part, then leaves. The room constantly reminds that a visit is possible.',
			'consentement.texte.limites' => 'Short visits, in limited number.',
			'consentement.texte.limitesDetail' => 'Each parent has a small number of visits per session, set by the academy and recalled in "How does it work?". A visit left before the end counts as a visit.',
			'consentement.texte.caseResponsable' => 'I accept these terms for my child',
			'consentement.texte.caseAdulte' => 'I accept these terms',
			'consentement.texte.continuer' => 'Continue',
			'consentement.texte.retour' => 'Back',
			'consentement.comment.titre' => 'How does it work?',
			'consentement.comment.visites' => ({required num n, required Object minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: 'One visit of ${minutes} min per session.', other: '${n} visits of ${minutes} min per session.', ), 
			'consentement.comment.visitesSansDuree' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: 'One short visit per session.', other: '${n} short visits per session.', ), 
			'consentement.comment.parParent' => 'This number applies to each parent, whether the session brings together one or several of their children.',
			'consentement.comment.ecourtee' => 'A visit left before the end is counted: only the next one remains, up to the last.',
			'consentement.comment.ecouter' => 'You hear the teacher and the students who speak, including your child.',
			'consentement.comment.sansMicro' => 'Your microphone and camera stay off during the visit.',
			'consentement.comment.valeursIndisponibles' => 'The number of visits and their length are shown from your child\'s class, according to the rules of their class.',
			'consentement.comment.fermee' => 'Observation visits are not open for this class.',
			'consentement.compte.intro' => 'The academy has added a paragraph on parent visits to its terms. Nothing is considered accepted until you have done so.',
			'consentement.compte.accepteLe' => ({required Object date}) => 'You accepted these terms on ${date}.',
			'consentement.compte.merci' => 'Thank you, your agreement is saved.',
			'consentement.compte.chargement' => 'Loading your agreements',
			'consentement.compte.erreur' => 'Your agreements cannot be displayed for now.',
			'consentement.compte.horsLigne' => 'Your agreements will be displayed as soon as the network is back.',
			'consentement.compte.sansProfil' => 'No account signed in: sign in again to read your agreements.',
			'consentement.compte.invite' => 'A new version to read: parent visits',
			'consentement.compte.inviteAction' => 'Read',
			'kyc.titre' => 'Your ID document',
			'kyc.intro' => 'Photograph the side or page that shows your photo and your name. A readable photo is enough. It is kept for the time of the check, then deleted.',
			'kyc.confidentialite' => 'Your ID document is submitted as it is: it is never public, only the management views it, and it is required by child protection regulations.',
			'kyc.typeQuestion' => 'Which document are you submitting?',
			'kyc.carteIdentite' => 'ID card',
			'kyc.passeport' => 'Passport',
			'kyc.titreSejour' => 'Residence permit',
			'kyc.autrePiece' => 'Other official document',
			'kyc.explicationCarteIdentite' => 'The national ID card of your country, currently valid.',
			'kyc.explicationPasseport' => 'Your passport, currently valid.',
			'kyc.explicationTitreSejour' => 'The card of the country where you live without being a citizen, currently valid.',
			'kyc.explicationAutre' => 'Another official document that shows your photo and your name.',
			'kyc.exempleAutre' => 'a driving licence or a consular card',
			'kyc.choisirFichier' => 'Choose the photo',
			'kyc.fichierChoisi' => 'Photo ready to be sent',
			'kyc.envoyer' => 'Send my document',
			'kyc.envoiEnCours' => 'Sending',
			'kyc.deposee' => 'Document received',
			'kyc.erreur' => 'The upload did not complete. Try again in a moment.',
			'kyc.erreurFormat' => 'This file was not accepted: only JPEG, PNG, HEIC or WebP photos and PDF files are. Choose another photo of your document.',
			'kyc.erreurReseau' => 'The upload did not complete: your request may not have reached Rewayah. Tap "Send my document" again in a moment.',
			'kyc.contenuNonConforme' => 'This file does not open as a photo or as a PDF: it may be damaged, or of another type that was renamed. Choose the photo or PDF of your ID document.',
			'kyc.tropVolumineux' => ({required Object taille}) => 'This photo is larger than ${taille} MB. Retake it at a lower quality.',
			'kyc.manqueType' => 'First choose the document you are submitting.',
			'enfant.titre' => 'Add a student profile',
			'enfant.aucun' => 'No student profile in the household',
			'enfant.aucunDetail' => 'First add a student profile from the Household.',
			'foyer.titre' => 'Household',
			'foyer.ajouterProfil' => 'Add a student profile',
			'foyer.sousTitre' => 'The student profiles of your household',
			'foyer.membres' => 'Student profiles',
			'foyer.vide.titre' => 'No student profile yet',
			'foyer.vide.phrase' => 'Add a student profile to register them in a class and link their device.',
			'foyer.vide.moiTitre' => 'You take the classes',
			'foyer.vide.moiPhrase' => 'Your student profile is linked to your account. Only add a student profile for another person in your family, a child for example.',
			'foyer.membre.sansClasse' => 'No class yet',
			'foyer.membre.classeEchec' => 'Class not loaded',
			'foyer.membre.vous' => 'You',
			'foyer.membre.accesSansEcheance' => 'Access with no end date',
			'foyer.membre.accesJusquau' => ({required Object date}) => 'Access until ${date}',
			'foyer.membre.accesExpire' => ({required Object date}) => 'Access expired since ${date}',
			'foyer.membre.date' => ({required Object mois, required Object jour, required Object annee}) => '${mois} ${jour}, ${annee}',
			'foyer.ajout.suivant' => 'Next',
			'foyer.ajout.creer' => 'Create the profile',
			'foyer.ajout.porte.sansDonneesTitre' => 'The profiles you can add could not be checked',
			'foyer.ajout.porte.illisibleTitre' => 'Your account could not be read',
			'foyer.ajout.porte.illisiblePhrase' => 'We do not know yet which profiles you can add. Try again in a moment.',
			'foyer.ajout.pourQui.question' => 'Who is this student profile for?',
			'foyer.ajout.pourQui.sousTitre' => 'Choose the person who will take the classes.',
			'foyer.ajout.pourQui.requis' => 'Choose who this profile is for to continue.',
			'foyer.ajout.pourQui.indisponible' => 'Unavailable',
			'foyer.ajout.pourQui.enfantTitre' => 'A child or a minor',
			'foyer.ajout.pourQui.enfantDescription' => 'A profile attached to your household, which you manage for them.',
			'foyer.ajout.pourQui.enfantAttente' => 'Possible as soon as your access is open.',
			'foyer.ajout.pourQui.moiTitre' => 'Myself',
			'foyer.ajout.identite.question' => 'Who is the student?',
			'foyer.ajout.identite.sousTitre' => 'Their first name, last name and age.',
			'foyer.ajout.identite.prenom' => 'First name',
			'foyer.ajout.identite.nom' => 'Last name',
			'foyer.ajout.identite.nomAide' => 'The family name is never shown to the teacher.',
			'foyer.ajout.identite.nomAidePrerempli' => 'Filled in with your account name: change it if the student has a different name. Never shown to the teacher.',
			'foyer.ajout.identite.age' => 'Age, in years',
			'foyer.ajout.identite.ageAide' => ({required Object min}) => 'Age sets the display and the camera to start with. You can change both afterwards. The minimum age is ${min}.',
			'foyer.ajout.identite.ageFige' => 'Sending is in progress: the age can be changed after the reply.',
			'foyer.ajout.identite.ageAdulte' => 'From 18, the student creates their own adult account.',
			'foyer.ajout.identite.genre' => 'Boy or girl',
			'foyer.ajout.erreurs.prenomRequis' => 'Enter the student\'s first name.',
			'foyer.ajout.erreurs.nomRequis' => 'Enter the student\'s last name.',
			'foyer.ajout.erreurs.ageRequis' => 'Choose the student\'s age to continue.',
			'foyer.ajout.erreurs.ageHorsBornes' => ({required Object min, required Object max}) => 'Enter an age between ${min} and ${max}.',
			'foyer.ajout.erreurs.genreRequis' => 'Gender is missing: tap "A boy" or "A girl", then "Create the profile".',
			'foyer.ajout.refus.compteNonValide' => 'Your access must be open before you add a student profile.',
			'foyer.ajout.refus.ageHorsBornes' => 'This age is not accepted. Check it and try again.',
			'foyer.ajout.refus.refuse' => 'The creation was not accepted. Check the information and try again.',
			'foyer.ajout.refus.titulaire' => 'This first and last name are yours. A profile added here is a child\'s: to take classes yourself, use "Create my student profile".',
			'foyer.ajout.refus.adulte' => 'From 18, a profile is not added here: this page is for children. To take classes yourself, use "Create my student profile".',
			'foyer.ajout.incertaine.titre' => 'The profile may have been created',
			'foyer.ajout.incertaine.phrase' => 'The reply did not reach us. Check the household before trying again, so the profile is not created twice.',
			'foyer.ajout.incertaine.voirFoyer' => 'See the household',
			'foyer.ajout.incertaine.reessayer' => 'Try again anyway',
			'foyer.ajout.horsLigne' => 'The profile can be created when the connection is back.',
			'ficheEleve.sansDonnees' => 'This student\'s profile could not be loaded',
			'ficheEleve.titreRepli' => 'Student profile',
			'ficheEleve.parametres' => 'Student settings',
			'ficheEleve.appareilsGroupe' => 'Devices',
			'ficheEleve.supprimer.groupe' => 'Delete the profile',
			'ficheEleve.supprimer.ligne' => ({required Object dePrenom}) => 'Delete ${dePrenom}\'s profile',
			'ficheEleve.supprimer.legende' => 'The profile leaves its classes and can no longer sign in.',
			'ficheEleve.supprimer.question' => ({required Object dePrenom}) => 'Delete ${dePrenom}\'s profile?',
			'ficheEleve.supprimer.consequence' => 'The profile can no longer sign in, immediately, and leaves its classes. It is anonymised at the end of the retention period. To get it back before then, write to the management.',
			_ => null,
		} ?? switch (path) {
			'ficheEleve.supprimer.confirmer' => ({required Object prenom}) => 'Yes, delete ${prenom}',
			'ficheEleve.supprimer.saisieLibelle' => ({required Object prenom}) => 'To confirm, write the first name ${prenom}',
			'ficheEleve.supprimer.saisieErreur' => ({required Object prenom}) => 'That is not the first name ${prenom}. Write it to confirm the deletion.',
			'ficheEleve.supprimer.rester' => 'Change nothing',
			'ficheEleve.supprimer.horsFoyer' => 'This profile cannot be deleted from your account. Write to the management.',
			'ficheEleve.supprimer.dejaRetire' => 'This profile is already deleted. The list is up to date.',
			'ficheEleve.supprimer.refuse' => 'Your account cannot delete this profile. Write to the management.',
			'ficheEleve.supprimer.indisponible' => 'Deleting a profile is not available yet. Nothing was deleted.',
			'ficheEleve.supprimer.echec' => 'The deletion could not be confirmed. Reopen the household to check before trying again.',
			'ficheEleve.supprimer.horsLigne' => 'Nothing was sent: there is no network. Try again as soon as it is back.',
			'ficheEleve.introuvable.titre' => 'This student profile cannot be found',
			'ficheEleve.introuvable.phrase' => 'It is not part of your household, or the link is incomplete.',
			'ficheEleve.introuvable.retour' => 'Back to the household',
			'ficheEleve.lignes.informations' => 'Information',
			'ficheEleve.lignes.informationsLegende' => 'First name and photo',
			'ficheEleve.lignes.inscription' => 'Journey and registration',
			'ficheEleve.lignes.inscriptionLegende' => 'Questionnaire and class',
			'ficheEleve.lignes.interface' => 'Interface',
			'ficheEleve.lignes.camera' => 'Current camera',
			'ficheEleve.lignes.cameraAutorisee' => 'Allowed',
			'ficheEleve.lignes.cameraNonAutorisee' => 'Not allowed',
			'ficheEleve.lignes.acces' => 'Rewayah access',
			'ficheEleve.lignes.appareils' => ({required Object dePrenom}) => '${dePrenom}\'s devices',
			'ficheEleve.lignes.appareilsLegende' => 'Connect a device, see those that are linked, remove one',
			'ficheEleve.lignes.couleur' => 'Profile colour',
			'ficheEleve.lignes.couleurAucune' => 'No colour',
			'ficheEleve.lignes.couleurIndisponible' => 'Not available yet',
			'ficheEleve.lignes.couleurEchec' => 'Colour not loaded',
			'ficheEleve.lignes.finances' => 'Finances',
			'ficheEleve.informations.titre' => 'Student information',
			'ficheEleve.informations.identite' => 'Identity',
			'ficheEleve.informations.prenom' => 'First name',
			'ficheEleve.informations.tranche' => 'Age group',
			'ficheEleve.informations.trancheInconnue' => 'Not known yet',
			'ficheEleve.informations.trancheNonLue' => 'Not loaded',
			'ficheEleve.informations.photo' => 'Photo',
			'ficheEleve.informations.photoLegende' => ({required Object dePrenom}) => 'A photo of ${dePrenom}\'s face. It is not an ID document. Their teacher, the students in their class and the management see it.',
			'ficheEleve.informations.photoAucune' => 'No photo yet',
			'ficheEleve.informations.photoPresente' => 'Photo saved',
			'ficheEleve.informations.choisir' => 'Choose a photo',
			'ficheEleve.informations.changer' => 'Change the photo',
			'ficheEleve.informations.apercuTitre' => 'Preview',
			'ficheEleve.informations.apercuPhrase' => 'Check the photo before sending it.',
			'ficheEleve.informations.apercuIllisible' => 'The preview cannot be displayed on this device. The photo can still be sent.',
			'ficheEleve.informations.envoyer' => 'Send this photo',
			'ficheEleve.informations.autre' => 'Choose another photo',
			'ficheEleve.informations.annuler' => 'Cancel',
			'ficheEleve.informations.etapeEnvoi' => 'Sending the photo, step 1 of 2',
			'ficheEleve.informations.etapeEnregistrement' => 'Saving to the profile, step 2 of 2',
			'ficheEleve.informations.succes' => 'The photo is saved.',
			'ficheEleve.informations.tropLourde' => ({required Object taille}) => 'This photo is larger than ${taille} MB. Choose a lighter image.',
			'ficheEleve.informations.echecEnvoi' => 'The photo could not be sent. Nothing changed on the profile.',
			'ficheEleve.informations.echecEnregistrement' => 'The photo was sent, but it could not be saved to the profile.',
			'ficheEleve.informations.reprendre' => 'Try again',
			'ficheEleve.informations.selectionEchec' => 'The photo could not be opened. Check access to the device\'s photos, then try again.',
			'ficheEleve.informations.horsLigne' => 'The photo can be sent when the connection is back.',
			'ficheEleve.inscription.titre' => 'Journey and registration',
			'ficheEleve.inscription.intro' => ({required Object prenom}) => 'Where ${prenom} stands: questionnaire and class.',
			'ficheEleve.inscription.questionnaire' => 'Questionnaire',
			'ficheEleve.inscription.classe' => 'Class',
			'ficheEleve.inscription.lecture' => 'Loading',
			'ficheEleve.inscription.etatInconnu' => 'The questionnaire status cannot be displayed yet.',
			'ficheEleve.inscription.aRemplir' => 'To fill in',
			'ficheEleve.inscription.horaireAChoisir' => 'Filled in, schedule to choose',
			'ficheEleve.inscription.horaireRetire' => 'Schedule withdrawn, to choose again',
			'ficheEleve.inscription.echangeAPrevoir' => 'Preference saved, level conversation to schedule',
			'ficheEleve.inscription.echangePrevu' => 'Level conversation planned',
			'ficheEleve.inscription.classeEnConstitution' => 'Class being formed',
			'ficheEleve.inscription.classeConfirmee' => 'Class confirmed',
			'ficheEleve.inscription.classeAucune' => 'No class yet. Choose a class',
			'ficheEleve.inscription.classeIndisponible' => 'The class cannot be displayed here yet. Choose a class',
			'ficheEleve.inscription.classeEchec' => 'The class could not be loaded.',
			'ficheEleve.inscription.relireClasse' => 'Reload the class',
			'ficheEleve.interface.titre' => 'Interface',
			'ficheEleve.interface.intro' => ({required Object dePrenom}) => 'Choose how Rewayah is displayed on ${dePrenom}\'s device. You can change this choice at any time.',
			'ficheEleve.interface.guidee' => 'Guided interface',
			'ficheEleve.interface.guideeDescription' => ({required Object prenom}) => 'When ${prenom} prefers airy screens: larger text, one action at a time. Same sections and same rights.',
			'ficheEleve.interface.standard' => 'Standard display',
			'ficheEleve.interface.standardDescription' => ({required Object prenom}) => 'When ${prenom} is comfortable with denser screens: more information per screen. Same sections and same rights.',
			'ficheEleve.interface.politique' => 'You choose this setting. No reason is asked, and the teacher only sees the name of the mode.',
			'ficheEleve.interface.application' => ({required Object dePrenom}) => 'The change applies the next time Rewayah is opened on ${dePrenom}\'s device.',
			'ficheEleve.interface.demandeEleve' => 'Requesting the change by the student themselves is not offered yet.',
			'ficheEleve.interface.echec' => ({required Object dePrenom}) => 'The change is not confirmed: it may not have reached Rewayah. Tap your choice again. If it did not arrive, ${dePrenom}\'s display stays as it was.',
			'ficheEleve.interface.horsLigne' => 'The display can be changed when the connection is back.',
			'ficheEleve.camera.titre' => 'Current camera',
			'ficheEleve.camera.ligne' => 'Camera during sessions',
			'ficheEleve.camera.autorisee' => ({required Object prenom}) => '${prenom} can turn on their camera during sessions.',
			'ficheEleve.camera.interdite' => ({required Object prenom}) => 'The camera button will not appear for ${prenom} during sessions.',
			'ficheEleve.camera.application' => ({required Object dePrenom}) => 'The change counts the next time ${dePrenom} joins a session.',
			'ficheEleve.camera.distincte' => 'This setting does not change the device\'s camera permission, the one the phone asks for to read a QR code.',
			'ficheEleve.camera.echec' => 'The change was not saved. Try again.',
			'ficheEleve.camera.horsLigne' => 'The camera can be set when the connection is back.',
			'ficheEleve.acces.titre' => 'Rewayah access',
			'ficheEleve.acces.ligne' => ({required Object dePrenom}) => '${dePrenom}\'s access',
			'ficheEleve.acces.pastilleSansEcheance' => 'No end date',
			'ficheEleve.acces.pastilleEnCours' => 'Active',
			'ficheEleve.acces.pastilleExpire' => 'Expired',
			'ficheEleve.acces.sansEcheance' => 'No end date is recorded.',
			'ficheEleve.acces.jusquau' => ({required Object date}) => 'Until ${date}',
			'ficheEleve.acces.expireDepuis' => ({required Object date}) => 'Expired since ${date}',
			'ficheEleve.acces.expirePhrase' => ({required Object prenom}) => 'Since this date, ${prenom} can no longer enter Rewayah.',
			'ficheEleve.acces.detailIndisponible' => 'The start of access and its reason are not displayed yet.',
			'ficheEleve.couleur.titre' => 'Profile colour',
			'ficheEleve.couleur.contexte' => ({required Object prenom}) => 'Choose the colour that distinguishes ${prenom} from the other profiles in the household. It is shown behind their photo on household screens. It is neither a status nor a class.',
			'ficheEleve.couleur.menthe' => 'Mint',
			'ficheEleve.couleur.ciel' => 'Sky',
			'ficheEleve.couleur.lavande' => 'Lavender',
			'ficheEleve.couleur.rose' => 'Pink',
			'ficheEleve.couleur.peche' => 'Peach',
			'ficheEleve.couleur.sable' => 'Sand',
			'ficheEleve.couleur.dejaPrise' => ({required Object prenom}) => 'Already chosen for ${prenom}: the colour would no longer distinguish these profiles.',
			'ficheEleve.couleur.prenomsEt' => ({required Object premiers, required Object dernier}) => '${premiers} and ${dernier}',
			'ficheEleve.couleur.aucune' => 'No colour',
			'ficheEleve.couleur.choisie' => ({required Object couleur}) => 'Colour chosen: ${couleur}.',
			'ficheEleve.couleur.priseLigne' => ({required Object couleur, required Object prenom}) => '${couleur}: already chosen for ${prenom}.',
			'ficheEleve.couleur.aucuneDetail' => ({required Object prenom}) => 'Only the photo and first name distinguish ${prenom}.',
			'ficheEleve.couleur.echec' => 'The colour change is not confirmed: it may not have reached Rewayah. Choose the colour again.',
			'ficheEleve.couleur.horsLigne' => 'The colour cannot be changed now. It can be chosen again as soon as sending is possible.',
			'ficheEleve.filAriane.foyer' => 'Household',
			'ficheEleve.onglets.general' => 'General',
			'ficheEleve.onglets.finances' => 'Finances',
			'ficheEleve.finances.titre' => 'Finances',
			'ficheEleve.finances.titreBureau' => ({required Object prenom}) => '${prenom} · Finances',
			'ficheEleve.finances.vueTitre' => 'Financial view',
			'ficheEleve.finances.mensualite' => 'Monthly fee',
			'ficheEleve.finances.mensualiteValeur' => ({required Object montant}) => '${montant} / month',
			'ficheEleve.finances.detailTitre' => 'Monthly fee details',
			'ficheEleve.finances.tarifEnfant' => 'Child rate',
			'ficheEleve.finances.tarifAdulte' => 'Adult rate',
			'ficheEleve.finances.remiseRang' => 'Family discount',
			'ficheEleve.finances.remiseRangDe' => ({required Object rang}) => 'Family discount, member no. ${rang}',
			'ficheEleve.finances.prorata' => 'Calendar reduction',
			'ficheEleve.finances.bourse' => 'Rewayah scholarship',
			'ficheEleve.finances.accesOffert' => 'Free access',
			'ficheEleve.finances.prixSpecial' => 'Special price',
			'ficheEleve.finances.remisePrepaiement' => 'Advance payment discount',
			'ficheEleve.finances.avoir' => 'Credit note',
			'ficheEleve.finances.taxe' => 'Applicable tax',
			'ficheEleve.finances.total' => 'Total to fund',
			'ficheEleve.finances.regulariserTitre' => 'Access to settle',
			'ficheEleve.finances.aFinancerTitre' => 'Next period to fund',
			'ficheEleve.finances.expireTitre' => 'Access expired',
			'ficheEleve.finances.manqueEtConservation' => ({required Object montant, required Object date}) => '${montant} is missing for the next period. The place is kept until ${date}.',
			'ficheEleve.finances.sansManque' => 'The next period is not funded yet.',
			'ficheEleve.finances.manquePourMois' => ({required Object montant, required Object mois}) => '${montant} is missing to fund ${mois}.',
			'ficheEleve.finances.manquePourMoisEtConservation' => ({required Object montant, required Object mois, required Object date}) => '${montant} is missing to fund ${mois}. The place is kept until ${date}.',
			'ficheEleve.finances.moisNonFinance' => ({required Object deMois}) => 'The period of ${deMois} is not funded yet.',
			'ficheEleve.finances.periodeAFinancer' => 'Period to fund',
			'ficheEleve.finances.periodeAFinancerValeur' => ({required Object mois, required Object annee, required Object montant}) => '${mois} ${annee} · ${montant}',
			'ficheEleve.finances.confirmationTitre' => 'Payment being confirmed',
			'ficheEleve.finances.confirmationPhrase' => 'Do not pay a second time: the period updates as soon as it is confirmed.',
			'ficheEleve.finances.indisponibleTitre' => 'Finances are not available yet',
			'ficheEleve.finances.indisponiblePhrase' => ({required Object dePrenom}) => '${dePrenom}\'s balance and monthly fee will appear here as soon as the academy has published them.',
			'ficheEleve.finances.erreurTitre' => ({required Object dePrenom}) => '${dePrenom}\'s finances cannot be loaded',
			'ficheEleve.finances.videTitre' => ({required Object prenom}) => 'No finances recorded for ${prenom}',
			'ficheEleve.finances.videPhrase' => 'No balance or monthly fee is shown yet for this profile. They will appear here after they register in a class.',
			'ficheEleve.finances.voirMouvements' => 'See the movements',
			'ficheEleve.finances.noteAbsences' => 'Ordinary absences do not reduce the month once it is funded.',
			'ficheEleve.finances.faitSeance' => 'No charge per session',
			'ficheEleve.finances.faitPeriode' => 'Access tied to the funded period',
			'ficheEleve.finances.historiqueTitre' => 'Transaction history',
			'ficheEleve.finances.voirTout' => 'See all',
			'ficheEleve.finances.voirToutSemantique' => ({required Object dePrenom}) => 'See all: ${dePrenom}\'s movements',
			'ficheEleve.finances.voirMouvementsSemantique' => ({required Object dePrenom}) => 'See ${dePrenom}\'s movements',
			'ficheEleve.finances.telechargerRecu' => 'Download the receipt',
			'ficheEleve.finances.recuIndisponibleTitre' => 'The receipt is not available yet',
			'ficheEleve.finances.recuIndisponiblePhrase' => 'Receipt download arrives with the launch of payments. Each payment stays visible in the movements.',
			'ficheEleve.finances.recuEchecTitre' => 'The receipt could not be prepared',
			'ficheEleve.finances.recuEchecPhrase' => 'Your request may not have reached Rewayah. Try again in a moment.',
			'ficheEleve.finances.sansDonnees' => 'The finances of this profile could not be loaded',
			'ficheEleve.mouvements.titre' => 'Movements',
			'ficheEleve.mouvements.dateHeure' => ({required Object date, required Object heure}) => '${date} at ${heure}',
			'ficheEleve.mouvements.heureChiffres' => ({required Object heures, required Object minutes}) => '${heures}:${minutes}',
			'ficheEleve.mouvements.contexte' => ({required Object dePrenom}) => '${dePrenom}\'s top-ups, monthly fees, discounts and credit notes, from the most recent to the oldest. Nothing is erased: a correction is added as a new movement.',
			'ficheEleve.mouvements.personne' => 'Person',
			'ficheEleve.mouvements.colonne.date' => 'Date',
			'ficheEleve.mouvements.colonne.libelle' => 'Label',
			'ficheEleve.mouvements.colonne.montant' => 'Amount',
			'ficheEleve.mouvements.colonne.statut' => 'Status',
			'ficheEleve.mouvements.colonne.recu' => 'Receipt',
			'ficheEleve.mouvements.nature.recharge' => 'Top-up',
			'ficheEleve.mouvements.nature.mensualite' => 'Monthly fee',
			'ficheEleve.mouvements.nature.mensualiteDe' => ({required Object mois, required Object annee}) => 'Monthly fee ${mois} ${annee}',
			'ficheEleve.mouvements.nature.avoir' => 'Credit note',
			'ficheEleve.mouvements.nature.remise' => 'Discount',
			'ficheEleve.mouvements.nature.taxe' => 'Applicable tax',
			'ficheEleve.mouvements.nature.debitSeance' => 'Session debit',
			'ficheEleve.mouvements.nature.correction' => 'Balance correction',
			'ficheEleve.mouvements.nature.remboursement' => 'Refund',
			'ficheEleve.mouvements.statut.enregistre' => 'Recorded',
			'ficheEleve.mouvements.statut.enConfirmation' => 'Being confirmed',
			'ficheEleve.mouvements.voirRecu' => 'See the receipt',
			'ficheEleve.mouvements.voirRecuSemantique' => ({required Object reference}) => 'See receipt ${reference}',
			'ficheEleve.mouvements.recu.titre' => 'Receipt',
			'ficheEleve.mouvements.recu.fermer' => 'Close the receipt',
			'ficheEleve.mouvements.recu.date' => 'Date',
			'ficheEleve.mouvements.recu.reference' => 'Reference',
			'ficheEleve.mouvements.recu.moyen' => 'Payment method',
			'ficheEleve.mouvements.recu.montant' => 'Amount paid',
			'ficheEleve.mouvements.recu.repartition' => 'Breakdown',
			'ficheEleve.mouvements.videTitre' => 'No movements',
			'ficheEleve.mouvements.videPhrase' => ({required Object prenom}) => 'No top-up or monthly fee is recorded yet for ${prenom}. Movements will appear here after the first payment.',
			'ficheEleve.mouvements.erreurTitre' => ({required Object dePrenom}) => '${dePrenom}\'s movements cannot be loaded',
			'ficheEleve.mouvements.indisponibleTitre' => 'Movements are not available yet',
			'ficheEleve.mouvements.indisponiblePhrase' => ({required Object dePrenom}) => '${dePrenom}\'s top-ups and monthly fees will appear here once they are in service.',
			'ficheEleve.mouvements.sansDonnees' => 'The movements of this profile could not be loaded',
			'recrutement.nomLatin.titre' => 'Your name in Latin letters',
			'recrutement.nomLatin.explication' => 'Your name is written in another script. For lists, certificates and exchanges with the academy, we need it written in Latin letters.',
			'recrutement.nomLatin.libelle' => 'Your name in Latin letters',
			'recrutement.nomLatin.aide' => 'Here is our suggestion. Correct it if your name is not written this way, then confirm.',
			'recrutement.nomLatin.origine' => ({required Object nom}) => 'Your name as you wrote it: ${nom}',
			'recrutement.nomLatin.confirmer' => 'Confirm my name',
			'recrutement.nomLatin.plusTard' => 'Later',
			'recrutement.nomLatin.erreur' => 'Write your name using Latin alphabet letters (a, b, c) to continue.',
			'recrutement.nomLatin.echec' => 'Your name is not confirmed. Try again in a moment.',
			'recrutement.candidat.titre' => 'Your code',
			'recrutement.candidat.intro' => 'To sign up as a teacher, enter the invitation code you received from the management.',
			'recrutement.candidat.champ' => 'Invitation code',
			'recrutement.candidat.champVide' => 'Enter the invitation code you received.',
			'recrutement.candidat.verifier' => 'Check the code',
			'recrutement.candidat.valide' => ({required Object date}) => 'Invitation valid until ${date}.',
			'recrutement.candidat.valideDetail' => 'You can create your teacher profile.',
			'recrutement.candidat.creerProfil' => 'Create my profile',
			'recrutement.candidat.expiree' => 'This invitation has expired.',
			'recrutement.candidat.expireeDetail' => 'Ask the academy\'s management for a new invitation.',
			'recrutement.candidat.demanderNouvelle' => 'Request a new invitation',
			'recrutement.candidat.contactCopie' => 'The management\'s address was copied: write to them from your email.',
			'recrutement.candidat.dejaUtilisee' => 'This invitation has already been used.',
			'recrutement.candidat.dejaUtiliseeDetail' => 'If it was you, sign in with the account you created.',
			'recrutement.candidat.seConnecter' => 'Sign in',
			'recrutement.candidat.inconnue' => 'Code not recognised.',
			'recrutement.candidat.inconnueDetail' => 'Check the code, then enter it again.',
			'recrutement.candidat.ressaisir' => 'Enter another code',
			'recrutement.candidat.horsLigne' => 'The code was not checked. Try again in a moment.',
			'recrutement.candidat.erreur' => 'The code could not be checked. Try again in a moment.',
			'recrutement.candidat.indisponible' => 'Checking invitations will be available once the server is connected.',
			'recrutement.candidat.comptable.titre' => 'Your accountant code',
			'recrutement.candidat.comptable.intro' => 'To sign up as an accountant, enter the invitation code you received from the management.',
			'recrutement.candidat.comptable.valideDetail' => 'You can create your accountant profile.',
			'recrutement.candidat.comptable.indisponible' => 'Checking accountant codes will be available once the server is connected.',
			'recrutement.signature.titre' => 'Contract',
			'recrutement.signature.version' => ({required Object version}) => 'Version ${version}',
			'recrutement.signature.empreinte' => ({required Object empreinte}) => 'Text fingerprint: ${empreinte}',
			'recrutement.signature.texteAltere' => 'The text received does not match its fingerprint: signing is not offered. Try again later or let the management know.',
			'recrutement.signature.champNom' => 'Signer\'s name',
			'recrutement.signature.aideNom' => 'Your account name. If it differs from your ID document, let the management know.',
			'recrutement.signature.nomCompteVide' => 'Your account has no name yet: signing is not possible. Let the management know.',
			'recrutement.signature.nomCompteLecture' => 'Your account name is not displayed: signing is waiting. Try again in a moment.',
			'recrutement.signature.nomVide' => 'Enter your full name to sign.',
			'recrutement.signature.nomTropLong' => 'This name is too long: shorten it.',
			'recrutement.signature.accuse' => 'I confirm I have read this contract.',
			'recrutement.signature.signer' => 'Sign the contract',
			'recrutement.signature.dejaSigne' => ({required Object date, required Object version}) => 'Signed on ${date}, version ${version}.',
			'recrutement.signature.signePar' => ({required Object nom}) => 'Signed by ${nom}',
			'recrutement.signature.copie' => 'Download my copy',
			'recrutement.signature.copieLien' => 'The link to your copy is copied. Paste it into your browser: it stays valid for a few minutes.',
			'recrutement.signature.copieErreur' => 'Your copy could not be prepared. Try again in a moment.',
			'recrutement.signature.nouvelleVersion' => ({required Object version}) => 'The contract has been updated since your last signature (version ${version}). Read it again, then sign again.',
			'recrutement.signature.versionPerimee' => 'The contract was updated while you were reading. The text is reloaded: read it again, then sign again.',
			'recrutement.signature.horsLigne' => 'The contract is not signed. Try again in a moment.',
			'recrutement.signature.erreur' => 'The signature is not confirmed. Check whether the contract appears signed before trying again.',
			'recrutement.signature.nonConnecte' => 'Your session has expired. Sign in again to sign.',
			'recrutement.signature.introuvable' => 'No contract is published for now. Let the management know.',
			'recrutement.signature.erreurLecture' => 'The contract could not be loaded. Try again in a moment.',
			'recrutement.signature.sansDonnees' => 'The contract cannot be read offline.',
			'recrutement.signature.indisponible' => 'Signing the contract will be available once the server is connected.',
			'recrutement.signature.retour' => 'Back',
			'recrutement.cadre.titre' => 'The religious and educational framework',
			'recrutement.cadre.caseAccord' => 'I confirm I have read this framework and I adhere to it.',
			'recrutement.cadre.accepter' => 'Accept the framework',
			'recrutement.cadre.erreurLecture' => 'The framework could not be loaded. Try again.',
			'recrutement.cadre.erreurAccord' => 'Your agreement was not saved. Try again.',
			'recrutement.cadre.refuse' => 'This framework cannot be accepted for now: your application is no longer at this step.',
			'recrutement.portail.aCompleterTitre' => 'Your application needs to be completed',
			'recrutement.portail.aCompleter' => 'To complete',
			'recrutement.portail.elementCadre' => 'The religious and educational framework',
			'recrutement.portail.etatAEnvoyer' => 'To send',
			'recrutement.portail.completer' => 'Complete my application',
			'recrutement.portail.enExamenTitre' => 'Your application has been sent',
			'recrutement.portail.enExamen' => 'The academy is reading your answers and will notify you here.',
			'recrutement.portail.versementImpossible' => 'Rewayah cannot yet pay you through the means declared in your country. Your application stays on hold. The academy will let you know as soon as a means becomes possible.',
			'recrutement.portail.libreDePartir' => 'You remain free to withdraw your application.',
			'recrutement.portail.enPauseTitre' => 'Your application is on hold',
			'recrutement.portail.repriseLe' => ({required Object date}) => 'Resumes on ${date}.',
			'recrutement.portail.refuseeTitre' => 'Your application was not accepted',
			'recrutement.portail.retireeTitre' => 'Application withdrawn',
			'recrutement.portail.retiree' => 'You withdrew your application. Only the academy can reopen it.',
			'recrutement.portail.complementDemande' => 'The academy is asking you for more information.',
			'recrutement.portail.complementListe' => ({required Object elements}) => 'To complete: ${elements}.',
			'recrutement.portail.nonCharge' => 'The status of your application could not be loaded.',
			'recrutement.portail.elementPiece' => 'Your ID document',
			'recrutement.portail.elementContrat' => 'The teacher contract',
			'recrutement.portail.versementImpossibleTitre' => 'Payment not possible yet',
			'recrutement.portail.relire' => 'Review my application',
			'recrutement.portail.toutIci' => 'Everything is done here. What is already done is marked "Done".',
			'recrutement.portail.listeTitre' => 'What is needed to send',
			'recrutement.portail.etatFait' => 'Done',
			'recrutement.portail.etatADeposer' => 'To submit',
			'recrutement.portail.elementAccords' => 'The contract and our agreements',
			'recrutement.portail.elementReponses' => 'Your answers',
			'recrutement.portail.reponsesRestantes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} answer remains', other: '${n} answers remain', ), 
			'recrutement.portail.reponsesPretes' => 'Ready to send',
			'recrutement.portail.elementPhoto' => 'Your photo',
			'recrutement.portail.etatAAjouter' => 'To add',
			'recrutement.entretien.titre' => 'Let\'s get to know each other',
			'recrutement.entretien.intro' => 'Choose a time for a video interview with the academy.',
			'recrutement.entretien.heureAppareil' => 'This device\'s time',
			'recrutement.entretien.horaire' => ({required Object date, required Object debut, required Object fin}) => '${date}, from ${debut} to ${fin}',
			'recrutement.entretien.choisir' => 'Choose a time.',
			'recrutement.entretien.reserver' => 'Book this time',
			'recrutement.entretien.aucunCreneau' => 'No time is open for now. Come back later.',
			'recrutement.entretien.erreurLecture' => 'The times could not be loaded. Try again.',
			'recrutement.entretien.pris' => 'This time has just been taken. Choose another.',
			'recrutement.entretien.dejaPlanifie' => 'Your interview is already set.',
			'recrutement.entretien.perime' => 'Your application has changed in the meantime. Reload the page.',
			'recrutement.entretien.erreurReservation' => 'The booking did not complete. Try again.',
			'recrutement.entretien.votreEntretien' => 'Your interview',
			'recrutement.entretien.rejoindre' => 'Join the interview',
			'recrutement.entretien.ouvreA' => ({required Object heure}) => 'You can join from ${heure}.',
			'recrutement.entretien.termine' => 'The time of your interview has passed. The academy will write to you with what comes next.',
			'recrutement.entretien.pasEncore' => 'The interview is not open yet for your application.',
			'recrutement.entretien.portailChoisir' => 'Choose a time for our interview',
			'recrutement.entretien.portailVoir' => 'See my interview',
			'recrutement.entretien.notifications.reserve' => 'Your interview is set. The day and time are in "Let\'s get to know each other".',
			'recrutement.entretien.notifications.reserveQuand' => ({required Object quand}) => 'Your interview is set for ${quand}.',
			'recrutement.entretien.notifications.veille' => 'Your interview is tomorrow.',
			'recrutement.entretien.notifications.veilleQuand' => ({required Object quand}) => 'Your interview is tomorrow, ${quand}.',
			'recrutement.entretien.notifications.quinze' => 'Your interview starts in 15 minutes: join it from "Let\'s get to know each other".',
			'recrutement.entretien.notifications.tenu' => 'Your interview took place. The management is reviewing your application and will write to you with what comes next.',
			'recrutement.entretien.notifications.aReplanifier' => 'Your interview did not take place. Choose another time.',
			'recrutement.entretien.notifications.reserveDirection' => 'An applicant has booked an interview you conduct.',
			'recrutement.entretien.notifications.reserveDirectionQuand' => ({required Object quand}) => 'An applicant has booked an interview you conduct, on ${quand}.',
			'recrutement.entretien.notifications.rappelDirection' => 'You are conducting an interview that starts soon.',
			'recrutement.entretien.notifications.rappelDirectionQuand' => ({required Object quand}) => 'You are conducting an interview on ${quand}.',
			'recrutement.questionnaire.titre' => 'Your application',
			'recrutement.questionnaire.conditionsTitre' => 'Pay terms',
			'recrutement.questionnaire.part' => ({required Object part}) => 'Your share: ${part} of the public price, for each student present.',
			'recrutement.questionnaire.partPublic' => ({required Object public, required Object part}) => '${public}: ${part} of the public price, for each student present.',
			'recrutement.questionnaire.publicEnfant' => 'Children (6 to 17)',
			'recrutement.questionnaire.publicAdulte' => 'Adults (18 and over)',
			'recrutement.questionnaire.coordonneesPlusTard' => 'Your financial details will only be requested before your first payment.',
			'recrutement.questionnaire.montantsSurDemande' => 'To find out the amounts, ask the administration.',
			'recrutement.questionnaire.conditionsDateEffet' => ({required Object date}) => 'These terms apply from ${date}.',
			'recrutement.questionnaire.accordRemuneration' => 'I have read these terms and I accept them.',
			'recrutement.questionnaire.accordManquant' => 'Tick the box to accept these terms and send your application.',
			'recrutement.questionnaire.envoyer' => 'Send my application',
			'recrutement.questionnaire.cadreManquant' => 'First accept the religious and educational framework.',
			'recrutement.questionnaire.cadreAccepte' => 'You have accepted the religious and educational framework.',
			'recrutement.questionnaire.langues' => 'Your languages',
			'recrutement.questionnaire.recitation' => 'Your recitation',
			'recrutement.questionnaire.disponibilites' => 'Your availability',
			'recrutement.questionnaire.publics' => 'The audiences you can teach',
			'recrutement.questionnaire.versement' => 'Your country and your payment',
			'recrutement.questionnaire.perime' => 'The questionnaire has changed since your last visit. Read your answers again before sending.',
			'recrutement.questionnaire.incomplet' => ({required Object question}) => 'An answer is missing: ${question}.',
			'recrutement.questionnaire.reponseInvalide' => ({required Object question}) => 'An answer is no longer valid: ${question}.',
			'recrutement.questionnaire.conflit' => 'Your application has changed since this page was opened. Read it again, then send it.',
			'recrutement.questionnaire.conditionsPerimees' => 'The pay terms have changed. Read them again, then accept them again.',
			'recrutement.questionnaire.interdit' => 'Your application can no longer be sent from this page.',
			'recrutement.questionnaire.echec' => 'One of your answers needs to be reviewed. Read them again, then send your application again.',
			'recrutement.questionnaire.incertain' => 'Your application may not have reached Rewayah. Try again: it will not be saved twice.',
			'recrutement.questionnaire.horsLigne' => 'Your application can be sent when the connection is back.',
			'recrutement.questionnaire.nonOuverte' => 'This step is not open yet. Your account is kept.',
			'recrutement.questionnaire.nonCharge' => 'The questionnaire could not be loaded.',
			'recrutement.questionnaire.conditionsNonCharge' => 'The pay terms could not be loaded.',
			'recrutement.questionnaire.envoyee' => 'Your application has been sent. The academy will notify you here if it needs to be completed.',
			'recrutement.questionnaire.envoyeeLe' => ({required Object date}) => 'Sent on ${date}.',
			'recrutement.questionnaire.etatVersement' => ({required Object etat}) => 'Payment method: ${etat}',
			'recrutement.questionnaire.retourDossier' => 'Back to my file',
			'recrutement.questionnaire.complementCarte' => 'The academy asks you to complete this part.',
			'recrutement.questionnaire.moyenValide' => 'You receive your pay through a method approved by Rewayah.',
			'recrutement.questionnaire.continuite' => 'By accepting these terms, you commit to holding your class on the same days and at the same times, every week.',
			'recrutement.questionnaire.plagesChevauchent' => 'Your availability overlaps on the same day. Review it, then send your application again.',
			'recrutement.parcours.choisir' => 'Choose an answer to continue.',
			'recrutement.parcours.choisirPlusieurs' => 'Choose at least one answer to continue.',
			'recrutement.parcours.trop' => ({required num max}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(max, one: 'Choose only one answer.', other: 'Choose at most ${max} answers.', ), 
			'recrutement.parcours.aucune' => 'None',
			'recrutement.parcours.oui' => 'Yes',
			'recrutement.parcours.non' => 'No',
			'recrutement.parcours.modifier' => 'Edit',
			'recrutement.parcours.sauvegardeEchec' => 'Your latest answers could not be saved. They stay on screen: continue, they will be sent with your application.',
			'recrutement.parcours.presentation.p1.titre' => 'Who is Rewayah Academy?',
			'recrutement.parcours.presentation.p1.intro' => 'Before the questions, here is what you need to know about us.',
			'recrutement.parcours.presentation.p1.academie.titre' => 'An online Quran academy',
			'recrutement.parcours.presentation.p1.academie.texte' => 'Rewayah Academy teaches the Quran remotely, in stable classes, with a dedicated teacher. It has been teaching since 1 May 2024.',
			'recrutement.parcours.presentation.p1.liberte.titre' => 'You remain free',
			'recrutement.parcours.presentation.p1.liberte.texte' => 'As long as you are not a teacher, you can withdraw your application from your file.',
			'recrutement.parcours.presentation.p1.donnees.titre' => 'Your data is protected',
			'recrutement.parcours.presentation.p1.donnees.texte' => 'Your answers are only read by the people at the academy who review your application.',
			'recrutement.parcours.presentation.p1.separation.titre' => 'Women and men separated',
			'recrutement.parcours.presentation.p1.separation.texte' => 'A woman\'s application is followed by the management on the women\'s side, a man\'s application on the men\'s side.',
			'recrutement.parcours.presentation.p2.titre' => 'What a teacher does',
			'recrutement.parcours.presentation.p2.intro' => 'You teach by video, in a class that stays the same.',
			'recrutement.parcours.presentation.p2.classe.titre' => 'A stable class',
			'recrutement.parcours.presentation.p2.classe.texte' => 'You keep the same class over time, with the same students.',
			'recrutement.parcours.presentation.p2.horaires.titre' => 'The same schedule every week',
			'recrutement.parcours.presentation.p2.horaires.texte' => 'Your class meets on the same days and at the same times, three times a week.',
			'recrutement.parcours.presentation.p2.visio.titre' => 'By video, in the app',
			'recrutement.parcours.presentation.p2.visio.texte' => 'Classes are given by video conference, in the Rewayah app.',
			'recrutement.parcours.presentation.p2.remuneration.titre' => 'Pay that is explained',
			'recrutement.parcours.presentation.p2.remuneration.texte' => 'Your pay is a share of the price each student present pays. It is explained to you as a percentage before you send your application.',
			'recrutement.parcours.presentation.p3.titre' => 'How your application works',
			'recrutement.parcours.presentation.p3.intro' => 'Three steps, in the app.',
			'recrutement.parcours.presentation.p3.examen.titre' => 'Your application',
			'recrutement.parcours.presentation.p3.examen.texte' => 'You answer the questions, read and accept our agreements, upload your photo and your ID document, then send your application. The management reads it.',
			'recrutement.parcours.presentation.p3.entretien.titre' => 'Let\'s get to know each other',
			'recrutement.parcours.presentation.p3.entretien.texte' => 'If your application is accepted, you choose a slot and the management meets you by video, in the app.',
			'recrutement.parcours.presentation.p3.verification.titre' => 'Welcome to the team',
			'recrutement.parcours.presentation.p3.verification.texte' => 'When everything is in order, you join the academy\'s team of teachers, in the app.',
			'recrutement.parcours.langues.poular' => 'Pulaar (Fula, Fulfulde)',
			'recrutement.parcours.langues.man' => 'Malinke',
			'recrutement.parcours.langues.sus' => 'Susu',
			'recrutement.parcours.langues.sw' => 'Swahili',
			'recrutement.parcours.langues.ha' => 'Hausa',
			'recrutement.parcours.langues.wo' => 'Wolof',
			'recrutement.parcours.langues.bm' => 'Bambara',
			'recrutement.parcours.langues.snk' => 'Soninke',
			'recrutement.parcours.langues.mnk' => 'Mandinka',
			'recrutement.parcours.langues.francais' => 'French',
			'recrutement.parcours.langues.english' => 'English',
			'recrutement.parcours.langues.ar' => 'Arabic',
			'recrutement.parcours.langues.ps' => 'Pashto',
			'recrutement.parcours.langues.ur' => 'Urdu',
			'recrutement.parcours.langues.om' => 'Oromo',
			'recrutement.parcours.langues.am' => 'Amharic',
			'recrutement.parcours.langues.yo' => 'Yoruba',
			'recrutement.parcours.langues.bn' => 'Bengali',
			'recrutement.parcours.langues.fa' => 'Persian',
			'recrutement.parcours.langues.id' => 'Indonesian',
			'recrutement.parcours.langues.so' => 'Somali',
			'recrutement.parcours.langues.hi' => 'Hindi',
			'recrutement.parcours.langues.uz' => 'Uzbek',
			'recrutement.parcours.langues.tr' => 'Turkish',
			'recrutement.parcours.langues.de' => 'German',
			'recrutement.parcours.langues.pt' => 'Portuguese',
			'recrutement.parcours.langues.ru' => 'Russian',
			'recrutement.parcours.langues.autre' => 'Another language',
			'recrutement.parcours.langues.autreDescription' => 'A language that is not in the list. The management will see it.',
			'recrutement.parcours.langues.dansReferentiel' => 'Rewayah offers classes in this language.',
			'recrutement.parcours.langues.horsReferentiel' => 'Rewayah does not yet offer classes in this language. You can choose it: the management will see it.',
			'recrutement.parcours.langues.chercher' => 'Search for another language',
			'recrutement.parcours.langues.recherche' => 'Search for a language',
			'recrutement.parcours.langues.rechercheAide' => 'Language name',
			'recrutement.parcours.langues.aucune' => 'No language matches.',
			'recrutement.parcours.langues.retour' => 'Back to the languages offered',
			'recrutement.parcours.pays.autre' => 'Another country',
			'recrutement.parcours.pays.recherche' => 'Search for a country',
			'recrutement.parcours.pays.rechercheAide' => 'Country name',
			'recrutement.parcours.pays.aucun' => 'No country matches.',
			'recrutement.parcours.pays.retour' => 'Back to the countries offered',
			'recrutement.parcours.riwayat.autre' => 'Another riwaya',
			'recrutement.parcours.riwayat.recherche' => 'Search for a riwaya',
			'recrutement.parcours.riwayat.rechercheAide' => 'Riwaya name',
			'recrutement.parcours.riwayat.aucune' => 'No riwaya matches.',
			'recrutement.parcours.riwayat.retour' => 'Back to the riwayat offered',
			'recrutement.parcours.fuseau.heureChezVous' => ({required Object heure}) => 'Is it ${heure} where you are?',
			'recrutement.parcours.fuseau.lieuPropose' => ({required Object lieu}) => 'Suggested time zone: ${lieu}.',
			'recrutement.parcours.fuseau.retenu' => ({required Object lieu}) => 'Time zone kept: ${lieu}.',
			'recrutement.parcours.fuseau.oui' => 'Yes, that is my local time',
			'recrutement.parcours.fuseau.ouiDescription' => 'Your time zone is confirmed.',
			'recrutement.parcours.fuseau.changer' => 'No, I want to change it',
			'recrutement.parcours.fuseau.changerDescription' => 'You choose the city closest to you.',
			'recrutement.parcours.fuseau.choisirTitre' => 'Which city is closest to you?',
			'recrutement.parcours.fuseau.choisirExplication' => 'It gives your time zone. The times of your interview will be shown in this time zone.',
			'recrutement.parcours.fuseau.recherche' => 'Search for a city',
			'recrutement.parcours.fuseau.rechercheAide' => 'City name',
			'recrutement.parcours.fuseau.aucune' => 'No city matches.',
			'recrutement.parcours.fuseau.autre' => 'Another city',
			'recrutement.parcours.fuseau.retour' => 'Back to the suggestion',
			'recrutement.parcours.fuseau.regions.Africa' => 'Africa',
			'recrutement.parcours.fuseau.regions.America' => 'Americas',
			'recrutement.parcours.fuseau.regions.Antarctica' => 'Antarctica',
			'recrutement.parcours.fuseau.regions.Arctic' => 'Arctic',
			'recrutement.parcours.fuseau.regions.Asia' => 'Asia',
			'recrutement.parcours.fuseau.regions.Atlantic' => 'Atlantic',
			'recrutement.parcours.fuseau.regions.Australia' => 'Australia',
			'recrutement.parcours.fuseau.regions.Europe' => 'Europe',
			'recrutement.parcours.fuseau.regions.Indian' => 'Indian Ocean',
			'recrutement.parcours.fuseau.regions.Pacific' => 'Pacific',
			'recrutement.parcours.fuseau.ouiExplication' => 'Your availability and your interview will be in your local time.',
			'recrutement.parcours.fuseau.changerExplication' => 'Useful if you travel or if your device\'s time is wrong.',
			'recrutement.parcours.creneaux.heure' => ({required Object h}) => '${h}:00',
			'recrutement.parcours.creneaux.heureMinutes' => ({required Object h, required Object m}) => '${h}:${m}',
			'recrutement.parcours.creneaux.intervalle' => ({required Object debut, required Object fin}) => 'from ${debut} to ${fin}',
			'recrutement.parcours.creneaux.fuseauRappel' => ({required Object lieu}) => 'Times in ${lieu}.',
			'recrutement.parcours.creneaux.moments.nuit' => 'At night, from 0:00 to 5:00',
			'recrutement.parcours.creneaux.moments.matin' => 'In the morning, from 6:00 to 11:00',
			'recrutement.parcours.creneaux.moments.apresMidi' => 'In the afternoon, from 12:00 to 17:00',
			'recrutement.parcours.creneaux.moments.soir' => 'In the evening, from 18:00 to 23:00',
			'recrutement.parcours.creneaux.raccourcis' => 'Shortcuts',
			'recrutement.parcours.creneaux.raccourciLmv' => 'Monday, Wednesday, Friday',
			'recrutement.parcours.creneaux.raccourciMjs' => 'Tuesday, Thursday, Saturday',
			'recrutement.parcours.creneaux.raccourciFinDeSemaine' => 'Weekend',
			'recrutement.parcours.creneaux.raccourcisAide' => 'A shortcut chooses several days at once. You can then add or remove some.',
			'recrutement.parcours.creneaux.moinsDeTrois' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: 'You chose a single day. A class meets three times a week, on the same days: consider choosing at least three.', other: 'You chose ${n} days. A class meets three times a week, on the same days: consider choosing at least three.', ), 
			'recrutement.parcours.creneaux.troisSeances' => 'A class meets three times a week, on the same days and at the same time.',
			'recrutement.parcours.creneaux.durees' => ({required Object enfants, required Object adultes}) => 'A children\'s class lasts ${enfants}, an adults\' class lasts ${adultes}.',
			'recrutement.parcours.creneaux.enseigneEnfants' => ({required Object duree, required Object intervalles}) => 'Children\'s classes (${duree}): you teach ${intervalles}.',
			'recrutement.parcours.creneaux.enseigneAdultes' => ({required Object duree, required Object intervalles}) => 'Adults\' classes (${duree}): you teach ${intervalles}.',
			'recrutement.parcours.creneaux.heuresChoisies' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, zero: 'No start time chosen', one: 'One start time chosen', other: '${n} start times chosen', ), 
			'recrutement.parcours.creneaux.debutsDuJour' => ({required Object heures}) => 'Possible start times: ${heures}.',
			'recrutement.parcours.creneaux.separateurListe' => ', ',
			'recrutement.parcours.creneaux.etListe' => ({required Object debut, required Object dernier}) => '${debut} and ${dernier}',
			'recrutement.parcours.versement.virementSeul' => 'In your country, the academy has confirmed bank transfer. No mobile payment method is offered for now.',
			'recrutement.parcours.versement.aucunMoyen' => 'Rewayah does not yet pay teachers in this country. You can send your application: it will stay on hold until a method becomes possible.',
			'recrutement.parcours.versement.operateurDescription' => 'Mobile payment',
			'recrutement.parcours.versement.chargement' => 'We are looking for the methods possible in your country.',
			'recrutement.parcours.versement.nonCharge' => 'The payment methods for your country could not be loaded.',
			'recrutement.parcours.versement.operateurExplication' => 'You declare it now. Your details are only requested before your first payment.',
			'recrutement.parcours.recap.titre' => 'Review your application',
			'recrutement.parcours.recap.explication' => 'Tap an answer to change it. Nothing is sent before the "Send my application" button.',
			'recrutement.parcours.recap.jours' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: 'One day per week', other: '${n} days per week', ), 
			_ => null,
		} ?? switch (path) {
			'recrutement.parcours.q.langueMaternelle.titre' => 'What is your mother tongue?',
			'recrutement.parcours.q.langueMaternelle.explication' => 'It is the language you have spoken since childhood. This question is optional: you can continue without answering.',
			'recrutement.parcours.q.langueMaternelle.court' => 'Mother tongue',
			'recrutement.parcours.q.languesExplication.titre' => 'In which languages can you explain and correct?',
			'recrutement.parcours.q.languesExplication.explication' => 'Choose all the languages in which you can explain a rule to a student and correct their mistakes, with no limit on the number. The student or their parent chooses their language at sign-up, and the academy assigns them a teacher who speaks it: the more you speak, the more you can teach. Arabic is not a class language: it is not in this list.',
			'recrutement.parcours.q.languesExplication.court' => 'Languages of explanation',
			'recrutement.parcours.q.niveauMemorisationDeclare.titre' => 'How much of the Quran have you memorised?',
			'recrutement.parcours.q.niveauMemorisationDeclare.explication' => 'You declare it here. Having memorised and having an ijaza are two different things: the ijaza is asked a little further on.',
			'recrutement.parcours.q.niveauMemorisationDeclare.court' => 'Memorisation level',
			'recrutement.parcours.q.niveauMemorisationDeclare.options.aucune.libelle' => 'I have not memorised a whole juz',
			'recrutement.parcours.q.niveauMemorisationDeclare.options.aucune.description' => 'You may know a few surahs, but not a whole juz.',
			'recrutement.parcours.q.niveauMemorisationDeclare.options.aucune.explication' => 'This level is assessed during the interview.',
			'recrutement.parcours.q.niveauMemorisationDeclare.options.aucune.exemple' => 'you recite a few short surahs from memory, but not a whole juz.',
			'recrutement.parcours.q.niveauMemorisationDeclare.options.moins_10_juz.libelle' => 'I have memorised fewer than 10 juz',
			'recrutement.parcours.q.niveauMemorisationDeclare.options.moins_10_juz.description' => 'From one whole juz to nine juz, out of the thirty of the Quran.',
			'recrutement.parcours.q.niveauMemorisationDeclare.options.moins_10_juz.explication' => 'This level is assessed during the interview.',
			'recrutement.parcours.q.niveauMemorisationDeclare.options.moins_10_juz.exemple' => 'you have memorised five juz out of thirty.',
			'recrutement.parcours.q.niveauMemorisationDeclare.options.de_10_a_29_juz.libelle' => 'I have memorised 10 to 29 juz',
			'recrutement.parcours.q.niveauMemorisationDeclare.options.de_10_a_29_juz.description' => 'From a third of the Quran to almost all of it.',
			'recrutement.parcours.q.niveauMemorisationDeclare.options.de_10_a_29_juz.explication' => 'This level is assessed during the interview.',
			'recrutement.parcours.q.niveauMemorisationDeclare.options.de_10_a_29_juz.exemple' => 'you have memorised twenty juz out of thirty.',
			'recrutement.parcours.q.niveauMemorisationDeclare.options.coran_entier.libelle' => 'I have memorised the whole Quran',
			'recrutement.parcours.q.niveauMemorisationDeclare.options.coran_entier.description' => 'All 114 surahs, from the first to the last, by heart.',
			'recrutement.parcours.q.niveauMemorisationDeclare.options.coran_entier.explication' => 'This level is assessed during the interview.',
			'recrutement.parcours.q.niveauMemorisationDeclare.options.coran_entier.exemple' => 'you recite Al-Baqara, then An-Nas, without opening the book.',
			'recrutement.parcours.q.niveauLectureTajwid.titre' => 'How do you read the Quran?',
			'recrutement.parcours.q.niveauLectureTajwid.explication' => 'Tajwid is the set of rules that say how to pronounce each letter of the Quran.',
			'recrutement.parcours.q.niveauLectureTajwid.court' => 'Reading and tajwid',
			'recrutement.parcours.q.niveauLectureTajwid.options.lecture_sans_regles_tajwid.libelle' => 'I read without applying the tajwid rules',
			'recrutement.parcours.q.niveauLectureTajwid.options.lecture_sans_regles_tajwid.description' => 'You read fluently, without following the pronunciation rules.',
			'recrutement.parcours.q.niveauLectureTajwid.options.lecture_sans_regles_tajwid.explication' => 'Your reading is assessed during the interview.',
			'recrutement.parcours.q.niveauLectureTajwid.options.lecture_sans_regles_tajwid.exemple' => 'you read a page without hesitating, but you do not apply the tajwid rules.',
			'recrutement.parcours.q.niveauLectureTajwid.options.tajwid_applique.libelle' => 'I apply the tajwid rules when reading',
			'recrutement.parcours.q.niveauLectureTajwid.options.tajwid_applique.description' => 'You follow the pronunciation rules when you read.',
			'recrutement.parcours.q.niveauLectureTajwid.options.tajwid_applique.explication' => 'Your reading is assessed during the interview.',
			'recrutement.parcours.q.niveauLectureTajwid.options.tajwid_applique.exemple' => 'you lengthen and pronounce letters as the tajwid rules require.',
			'recrutement.parcours.q.niveauLectureTajwid.options.tajwid_enseigne.libelle' => 'I apply tajwid and I can teach it',
			'recrutement.parcours.q.niveauLectureTajwid.options.tajwid_enseigne.description' => 'You follow the rules and can explain them to a student.',
			'recrutement.parcours.q.niveauLectureTajwid.options.tajwid_enseigne.explication' => 'Your reading is assessed during the interview.',
			'recrutement.parcours.q.niveauLectureTajwid.options.tajwid_enseigne.exemple' => 'when a student makes a mistake on a letter, you explain the rule and they repeat it.',
			'recrutement.parcours.q.riwayat.titre' => 'Which riwayat do you recite?',
			'recrutement.parcours.q.riwayat.explication' => 'A riwaya is a transmitted way of reciting the Quran. Choose all those you recite.',
			'recrutement.parcours.q.riwayat.court' => 'Riwayat',
			'recrutement.parcours.q.riwayat.options.hafs.libelle' => 'Hafs',
			'recrutement.parcours.q.riwayat.options.hafs.description' => 'Transmitted from Asim',
			'recrutement.parcours.q.riwayat.options.shuba.libelle' => 'Shuba',
			'recrutement.parcours.q.riwayat.options.shuba.description' => 'Transmitted from Asim',
			'recrutement.parcours.q.riwayat.options.warsh.libelle' => 'Warsh',
			'recrutement.parcours.q.riwayat.options.warsh.description' => 'Transmitted from Nafi',
			'recrutement.parcours.q.riwayat.options.qalun.libelle' => 'Qalun',
			'recrutement.parcours.q.riwayat.options.qalun.description' => 'Transmitted from Nafi',
			'recrutement.parcours.q.riwayat.options.al_bazzi.libelle' => 'Al-Bazzi',
			'recrutement.parcours.q.riwayat.options.al_bazzi.description' => 'Transmitted from Ibn Kathir',
			'recrutement.parcours.q.riwayat.options.qunbul.libelle' => 'Qunbul',
			'recrutement.parcours.q.riwayat.options.qunbul.description' => 'Transmitted from Ibn Kathir',
			'recrutement.parcours.q.riwayat.options.ad_duri_abi_amr.libelle' => 'Ad-Duri (Abu Amr)',
			'recrutement.parcours.q.riwayat.options.ad_duri_abi_amr.description' => 'Transmitted from Abu Amr',
			'recrutement.parcours.q.riwayat.options.as_susi.libelle' => 'As-Susi',
			'recrutement.parcours.q.riwayat.options.as_susi.description' => 'Transmitted from Abu Amr',
			'recrutement.parcours.q.riwayat.options.hisham.libelle' => 'Hisham',
			'recrutement.parcours.q.riwayat.options.hisham.description' => 'Transmitted from Ibn Amir',
			'recrutement.parcours.q.riwayat.options.ibn_dhakwan.libelle' => 'Ibn Dhakwan',
			'recrutement.parcours.q.riwayat.options.ibn_dhakwan.description' => 'Transmitted from Ibn Amir',
			'recrutement.parcours.q.riwayat.options.khalaf_an_hamza.libelle' => 'Khalaf (Hamza)',
			'recrutement.parcours.q.riwayat.options.khalaf_an_hamza.description' => 'Transmitted from Hamza',
			'recrutement.parcours.q.riwayat.options.khallad.libelle' => 'Khallad',
			'recrutement.parcours.q.riwayat.options.khallad.description' => 'Transmitted from Hamza',
			'recrutement.parcours.q.riwayat.options.abu_al_harith.libelle' => 'Abu al-Harith',
			'recrutement.parcours.q.riwayat.options.abu_al_harith.description' => 'Transmitted from Al-Kisai',
			'recrutement.parcours.q.riwayat.options.ad_duri_al_kisai.libelle' => 'Ad-Duri (Al-Kisai)',
			'recrutement.parcours.q.riwayat.options.ad_duri_al_kisai.description' => 'Transmitted from Al-Kisai',
			'recrutement.parcours.q.riwayat.options.ibn_wardan.libelle' => 'Ibn Wardan',
			'recrutement.parcours.q.riwayat.options.ibn_wardan.description' => 'Transmitted from Abu Jafar',
			'recrutement.parcours.q.riwayat.options.ibn_jammaz.libelle' => 'Ibn Jammaz',
			'recrutement.parcours.q.riwayat.options.ibn_jammaz.description' => 'Transmitted from Abu Jafar',
			'recrutement.parcours.q.riwayat.options.ruways.libelle' => 'Ruways',
			'recrutement.parcours.q.riwayat.options.ruways.description' => 'Transmitted from Yaqub',
			'recrutement.parcours.q.riwayat.options.rawh.libelle' => 'Rawh',
			'recrutement.parcours.q.riwayat.options.rawh.description' => 'Transmitted from Yaqub',
			'recrutement.parcours.q.riwayat.options.ishaq.libelle' => 'Ishaq',
			'recrutement.parcours.q.riwayat.options.ishaq.description' => 'Transmitted from Khalaf, the tenth reciter',
			'recrutement.parcours.q.riwayat.options.idris.libelle' => 'Idris',
			'recrutement.parcours.q.riwayat.options.idris.description' => 'Transmitted from Khalaf, the tenth reciter',
			'recrutement.parcours.q.ijazaPresentable.titre' => 'Do you have an ijaza?',
			'recrutement.parcours.q.ijazaPresentable.explication' => 'An ijaza is a written authorisation, given by a teacher, to transmit the Quran. Whoever has an ijaza has memorised, but whoever has memorised does not necessarily have an ijaza: it is a separate question.',
			'recrutement.parcours.q.ijazaPresentable.court' => 'Ijaza',
			'recrutement.parcours.q.ijazaPresentable.options.oui.libelle' => 'Yes, I have an ijaza to present',
			'recrutement.parcours.q.ijazaPresentable.options.oui.description' => 'You can show it by video.',
			'recrutement.parcours.q.ijazaPresentable.options.oui.explication' => 'It is shown during the interview: you have nothing to send now.',
			'recrutement.parcours.q.ijazaPresentable.options.oui.exemple' => 'a document signed by your teacher, which you keep at home.',
			'recrutement.parcours.q.ijazaPresentable.options.pret_test.libelle' => 'No ijaza, but I can take a test',
			'recrutement.parcours.q.ijazaPresentable.options.pret_test.description' => 'You have no ijaza to present, but you agree to take a test.',
			'recrutement.parcours.q.ijazaPresentable.options.pret_test.explication' => 'The academy will discuss it with you during the interview.',
			'recrutement.parcours.q.ijazaPresentable.options.pret_test.exemple' => 'you learned with a teacher without a written document, and you agree to be tested.',
			'recrutement.parcours.q.ijazaPresentable.options.non.libelle' => 'No, I do not have an ijaza',
			'recrutement.parcours.q.ijazaPresentable.options.non.description' => 'You have no ijaza, and you do not plan to take a test for now.',
			'recrutement.parcours.q.ijazaPresentable.options.non.explication' => 'Your level is then assessed during the interview.',
			'recrutement.parcours.q.ijazaPresentable.options.non.exemple' => 'you learned with a teacher, without receiving a written document.',
			'recrutement.parcours.q.experienceDebutants.titre' => 'Have you already taught beginners?',
			'recrutement.parcours.q.experienceDebutants.explication' => 'A beginner is still learning to read the letters and join them.',
			'recrutement.parcours.q.experienceDebutants.court' => 'Experience with beginners',
			'recrutement.parcours.q.experienceDebutants.options.oui.libelle' => 'Yes, I have already taught beginners',
			'recrutement.parcours.q.experienceDebutants.options.oui.description' => 'You have already guided students who are just starting.',
			'recrutement.parcours.q.experienceDebutants.options.oui.explication' => 'The management knows before the interview.',
			'recrutement.parcours.q.experienceDebutants.options.oui.exemple' => 'you taught the Arabic letters to children or to adults.',
			'recrutement.parcours.q.experienceDebutants.options.non.libelle' => 'No, not yet',
			'recrutement.parcours.q.experienceDebutants.options.non.description' => 'You have not yet taught beginners.',
			'recrutement.parcours.q.experienceDebutants.options.non.explication' => 'You can still send your application.',
			'recrutement.parcours.q.experienceDebutants.options.non.exemple' => 'you have only taught students who already knew how to read.',
			'recrutement.parcours.q.fuseauIana.titre' => 'Your time zone',
			'recrutement.parcours.q.fuseauIana.explication' => 'Your availability is in your local time. So the time must be right.',
			'recrutement.parcours.q.fuseauIana.court' => 'Time zone',
			'recrutement.parcours.q.disponibilitesDeclarees.titre' => 'Which days can you teach?',
			'recrutement.parcours.q.disponibilitesDeclarees.explication' => 'A class meets three times a week, on the same days and at the same time. Tap the days you can teach, or use a shortcut.',
			'recrutement.parcours.q.disponibilitesDeclarees.court' => 'Availability',
			'recrutement.parcours.q.disponibilitesDeclarees.heures.titre' => ({required Object jour}) => 'At what time can you start, on ${jour}?',
			'recrutement.parcours.q.disponibilitesDeclarees.heures.explication' => 'Choose all the times at which you can start a class. The end of the class is calculated for you.',
			'recrutement.parcours.q.disponibilitesDeclarees.heures.suite' => 'You will then say whether it is the same on the other days.',
			'recrutement.parcours.q.disponibilitesDeclarees.memes.titre' => 'Are these the same times for all these days?',
			'recrutement.parcours.q.disponibilitesDeclarees.memes.explication' => ({required Object jours, required Object premier, required Object heures}) => 'You chose ${jours}. On ${premier}, you start at ${heures}.',
			'recrutement.parcours.q.disponibilitesDeclarees.memes.oui.libelle' => 'Yes, the same times',
			'recrutement.parcours.q.disponibilitesDeclarees.memes.oui.description' => ({required Object premier, required Object autres}) => 'The times for ${premier} also apply to ${autres}.',
			'recrutement.parcours.q.disponibilitesDeclarees.memes.oui.explication' => 'You can change a day before sending your application.',
			'recrutement.parcours.q.disponibilitesDeclarees.memes.oui.exemple' => 'you can start at 6 pm on Monday, Wednesday and Friday.',
			'recrutement.parcours.q.disponibilitesDeclarees.memes.non.libelle' => 'No, day by day',
			'recrutement.parcours.q.disponibilitesDeclarees.memes.non.description' => 'You set the times for each day, one after the other.',
			'recrutement.parcours.q.disponibilitesDeclarees.memes.non.explication' => 'The times already chosen stay: you adjust them.',
			'recrutement.parcours.q.disponibilitesDeclarees.memes.non.exemple' => 'you start at 6 pm on Monday, but at 8 pm on Wednesday.',
			'recrutement.parcours.q.disponibilitesDeclarees.parJour.titre' => 'Set the times, day by day',
			'recrutement.parcours.q.disponibilitesDeclarees.parJour.explication' => 'Each day starts from the times already chosen. Add or remove times where it is not the same.',
			'recrutement.parcours.q.disponibilitesDeclarees.semaine.titre' => 'Your week',
			'recrutement.parcours.q.disponibilitesDeclarees.semaine.explication' => 'Here is when you can teach, in your local time. Review it, then continue.',
			'recrutement.parcours.q.classesSouhaitees.titre' => 'How many classes do you want to hold?',
			'recrutement.parcours.q.classesSouhaitees.explication' => 'A class is a group of students who meet three times a week, on the same days and at the same time, with the same teacher. It is a wish: the academy decides which classes it assigns to you.',
			'recrutement.parcours.q.classesSouhaitees.court' => 'Classes wanted',
			'recrutement.parcours.q.debutPossible.titre' => 'When can you start?',
			'recrutement.parcours.q.debutPossible.explication' => 'This date helps the management know when to offer you a class.',
			'recrutement.parcours.q.debutPossible.court' => 'Start date',
			'recrutement.parcours.q.debutPossible.options.immediat.libelle' => 'Right now',
			'recrutement.parcours.q.debutPossible.options.immediat.description' => 'You can start as soon as a class is assigned to you.',
			'recrutement.parcours.q.debutPossible.options.immediat.exemple' => 'no commitment holds you back this month.',
			'recrutement.parcours.q.debutPossible.options.mois_prochain.libelle' => 'Next month',
			'recrutement.parcours.q.debutPossible.options.mois_prochain.description' => 'You will be available from next month.',
			'recrutement.parcours.q.debutPossible.options.mois_prochain.exemple' => 'you finish another job at the end of this month.',
			'recrutement.parcours.q.debutPossible.options.sous_3_mois.libelle' => 'In less than three months',
			'recrutement.parcours.q.debutPossible.options.sous_3_mois.description' => 'You will be available within the next three months.',
			'recrutement.parcours.q.debutPossible.options.sous_3_mois.exemple' => 'you are travelling or sitting exams for a few weeks.',
			'recrutement.parcours.q.debutPossible.options.inconnu.libelle' => 'I don\'t know yet',
			'recrutement.parcours.q.debutPossible.options.inconnu.description' => 'You do not yet know your start date.',
			'recrutement.parcours.q.debutPossible.options.inconnu.explication' => 'You can tell the management during the interview.',
			'recrutement.parcours.q.debutPossible.options.inconnu.exemple' => 'your schedule depends on an answer you are still waiting for.',
			'recrutement.parcours.q.publics.titre' => 'Which students can you teach?',
			'recrutement.parcours.q.publics.explication' => 'Choose the age groups you are comfortable teaching. There is no wrong answer: you can choose just one, or several.',
			'recrutement.parcours.q.publics.court' => 'Audiences',
			'recrutement.parcours.q.publics.options.o_6_9.libelle' => 'Children aged 6 to 9',
			'recrutement.parcours.q.publics.options.o_6_9.description' => 'They start with Rewayah\'s reading book, letter by letter, up to the shadda. Then come the first short surahs, the words of the prayer and the ablutions.',
			'recrutement.parcours.q.publics.options.o_6_9.explication' => 'Classes of 5 children at most (4 for beginners), three one-hour sessions per week. The ablutions and the prayer are shown in practice, with illustrations.',
			'recrutement.parcours.q.publics.options.o_6_9.exemple' => 'a class of eight-year-olds, on Monday, Wednesday and Friday.',
			'recrutement.parcours.q.publics.options.o_10_13.libelle' => 'Children aged 10 to 13',
			'recrutement.parcours.q.publics.options.o_10_13.description' => 'Same start with the reading book, and Al-Fatiha from the first week, because at this age the child must pray.',
			'recrutement.parcours.q.publics.options.o_10_13.explication' => 'Classes of 5 children at most (4 for beginners), three one-hour sessions per week.',
			'recrutement.parcours.q.publics.options.o_10_13.exemple' => 'a class of twelve-year-olds, three times a week.',
			'recrutement.parcours.q.publics.options.o_14_17.libelle' => 'Teenagers aged 14 to 17',
			'recrutement.parcours.q.publics.options.o_14_17.description' => 'The same content as for ages 10 to 13: the reading book, and Al-Fatiha from the first week.',
			'recrutement.parcours.q.publics.options.o_14_17.explication' => 'Classes of 5 teenagers at most (4 for beginners), three one-hour sessions per week.',
			'recrutement.parcours.q.publics.options.o_14_17.exemple' => 'a class of sixteen-year-olds, three times a week.',
			'recrutement.parcours.q.publics.options.adultes.libelle' => 'Adults (18 and over)',
			'recrutement.parcours.q.publics.options.adultes.description' => 'Adults first learn to read with Rewayah\'s book. After the basics, the student chooses to read the whole Quran or to memorise it, on the teacher\'s advice.',
			'recrutement.parcours.q.publics.options.adultes.explication' => 'Classes of 6 adults at most (4 for beginners), three sessions of an hour and a half per week. Adult classes are separate: women with women, men with men.',
			'recrutement.parcours.q.publics.options.adultes.exemple' => 'a women\'s class, or a men\'s class, three times a week.',
			'recrutement.parcours.q.paysResidence.titre' => 'Which country do you live in?',
			'recrutement.parcours.q.paysResidence.explication' => 'Choose the country where you live today.',
			'recrutement.parcours.q.paysResidence.court' => 'Country of residence',
			'recrutement.parcours.q.paysVersement.titre' => 'In which country do you want to receive your pay?',
			'recrutement.parcours.q.paysVersement.explication' => 'The academy checks, country by country, which payment method is possible. We carried over your country of residence: change it if needed.',
			'recrutement.parcours.q.paysVersement.court' => 'Payment country',
			'recrutement.parcours.q.compteBancaire.titre' => 'Do you have a bank account to receive your payment, in your name or a relative\'s?',
			'recrutement.parcours.q.compteBancaire.explication' => 'Pay is paid by bank transfer where the academy has confirmed it. Your details are only requested before the first payment.',
			'recrutement.parcours.q.compteBancaire.court' => 'Bank account',
			'recrutement.parcours.q.compteBancaire.options.oui.libelle' => 'Yes, in my name or a relative\'s',
			'recrutement.parcours.q.compteBancaire.options.oui.description' => 'An account at a bank, in your name or a relative\'s.',
			'recrutement.parcours.q.compteBancaire.options.oui.explication' => 'Bank transfer can be your payment method, if the academy has confirmed it in your country.',
			'recrutement.parcours.q.compteBancaire.options.oui.exemple' => 'an account opened at a bank, in your brother\'s name.',
			'recrutement.parcours.q.compteBancaire.options.non.libelle' => 'No, I don\'t have one',
			'recrutement.parcours.q.compteBancaire.options.non.description' => 'Neither in your name, nor in a relative\'s.',
			'recrutement.parcours.q.compteBancaire.options.non.explication' => 'You can then choose a mobile payment method, if there is one in your country.',
			'recrutement.parcours.q.compteBancaire.options.non.exemple' => 'you only receive and send money with your phone.',
			'recrutement.parcours.q.operateurs.titre' => 'Which mobile payment methods do you use?',
			'recrutement.parcours.q.operateurs.explication' => 'Here are the methods the academy has confirmed in your country. Choose those you use, if any.',
			'recrutement.parcours.q.operateurs.court' => 'Mobile payment methods',
			'recrutement.parcours.q.moyensAccessibles.titre' => 'Which payment methods are common where you live?',
			'recrutement.parcours.q.moyensAccessibles.explication' => 'Here are the methods the academy knows. Choose those that are common in your country, if any.',
			'recrutement.parcours.q.moyensAccessibles.court' => 'Payment methods of the country',
			'recrutement.parcours.classes.libelle' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} class', other: '${n} classes', ), 
			'recrutement.parcours.classes.seances' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} session per week.', other: '${n} sessions per week.', ), 
			'recrutement.parcours.classes.heuresEnfants' => ({required Object heures}) => 'That is ${heures} per week with children.',
			'recrutement.parcours.classes.heuresAdultes' => ({required Object heures}) => 'That is ${heures} per week with adults.',
			'recrutement.parcours.classes.heuresLesDeux' => ({required Object enfants, required Object adultes}) => 'That is ${enfants} per week with children, or ${adultes} with adults.',
			'recrutement.parcours.classes.explication' => 'Each class has its own schedule, which it keeps every week.',
			'recrutement.parcours.classes.exemple1' => 'on Monday, Wednesday and Friday at 6 pm.',
			'recrutement.parcours.classes.exemple2' => 'on Monday, Wednesday and Friday at 6 pm, then on Tuesday, Thursday and Saturday at 7 pm.',
			'recrutement.parcours.classes.exemplePlusieurs' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} class, with its days and its time.', other: '${n} classes, each with its days and its time.', ), 
			'recrutement.parcours.moyens.mobile' => 'Mobile payment',
			'recrutement.parcours.moyens.virement' => 'Bank transfer',
			'recrutement.parcours.moyens.explication' => 'Choose it if it is common where you live.',
			'recrutement.parcours.moyens.nonElimine' => 'This question is optional and eliminates no one: your application does not depend on your answer. It helps the academy know the methods used where you live.',
			'recrutement.parcours.choisirJour' => 'Choose at least one day to continue.',
			'recrutement.parcours.choisirHeure' => 'Choose at least one start time to continue.',
			'recrutement.parcours.choisirHeureJour' => ({required Object jour}) => 'Choose at least one start time for ${jour}.',
			'parcours.titre' => ({required Object dePrenom}) => '${dePrenom}\'s journey',
			'parcours.intro' => 'A few questions to personalise your journey. You will then only see the schedules and options that fit your situation.',
			'parcours.reprendre' => 'Resume',
			'parcours.commencer' => 'Personalise the journey',
			'parcours.modifier' => 'Edit my answers',
			'parcours.recapNiveau' => ({required Object niveau}) => 'Stated level: ${niveau}',
			'parcours.recapObjectif' => ({required Object objectif}) => 'Goal: ${objectif}',
			'parcours.erreur' => 'This answer could not be saved. Try again.',
			'parcours.chargement' => 'We are preparing your options.',
			'parcours.pourPrenom' => ({required Object prenom}) => 'For ${prenom}',
			'parcours.retourAccueil' => 'Back to home',
			'parcours.retourFoyer' => 'Back to the Household',
			'parcours.reessayer' => 'Try again',
			'parcours.indisponibleTitre' => 'The questionnaire is not available yet',
			'parcours.indisponibleDetail' => 'The academy has not opened this step yet. You have nothing to do for now: nothing is lost, and you can fill it in as soon as it opens.',
			'parcours.horsLigneTitre' => 'The journey could not be loaded',
			'parcours.horsLigneDetail' => 'You can try again when the connection is back. Your answers are saved.',
			'parcours.erreurChargement' => 'The questionnaire could not be displayed',
			'parcours.erreurChargementDetail' => 'An error occurred on our side. Try again in a moment; your answers are saved.',
			'parcours.introuvableTitre' => 'This student profile cannot be found',
			'parcours.introuvableDetail' => 'It may have been removed from the household. Go back to the Household to choose a student profile.',
			'parcours.finTitre' => ({required Object prenom}) => 'Preference saved for ${prenom}',
			'parcours.finDetail' => 'This time slot is noted as your preference. It does not reserve a place yet.',
			'parcours.finAjouterDetail' => 'Does someone else in the household want to learn?',
			'parcours.finAjouterProfil' => 'Add a student profile',
			'parcours.ageQuestion' => ({required Object prenom}) => 'How old is ${prenom}?',
			'parcours.ageRaison' => 'Age decides the length of sessions and the number of students per class. We do not ask for a date of birth: age in years is enough.',
			'parcours.ageAide' => 'Choose the age in years from the list, as when adding the profile.',
			'parcours.ageSansTranche' => 'No class is planned for this age for now. The academy team can guide you.',
			'parcours.langueQuestion' => 'In which language should the class be taught?',
			'parcours.langueRaison' => 'This is the language the teacher will speak during the session. It is independent of the app language, which you can change at any time in your settings.',
			'parcours.lieuQuestion' => 'Where are you?',
			'parcours.lieuRaison' => 'We only use it to show you schedules in your local time. We never ask for your exact location, and this answer does not leave your file.',
			'parcours.lieuSuggere' => 'Suggested from your device\'s time',
			'parcours.niveauQuestion' => ({required Object prenom}) => 'Where is ${prenom} today?',
			'parcours.niveauRaison' => 'Your answer guides the first suggestions. It does not set the official level: the academy assigns it after a conversation with a teacher.',
			'parcours.niveauDebutLettres' => 'We start with the letters',
			'parcours.niveauLettresAvecAide' => 'Letters are recognised, reading needs help',
			'parcours.niveauLectureLente' => 'Reading is possible, slowly',
			'parcours.niveauLectureCourante' => 'The Quran is already read fluently',
			'parcours.niveauMemorisationPartielle' => 'Part of it is already memorised',
			'parcours.objectifQuestion' => 'What do you want first?',
			'parcours.objectifRaison' => 'You can change your goal later: it guides the teacher\'s work, it does not commit you.',
			'parcours.objectifApprendreALire' => 'Learn to read',
			'parcours.objectifDevenirFluide' => 'Read more fluently',
			'parcours.objectifMemoriser' => 'Memorise',
			'parcours.objectifIndecis' => 'I don\'t know yet',
			'parcours.momentsQuestion' => 'Which times of day suit you best?',
			'parcours.momentsRaison' => 'This answer creates no schedule and reserves nothing. It is only used to highlight, among the schedules the academy already offers, those that suit you best. You will see all the others just below.',
			'parcours.momentMatin' => 'Mornings',
			'parcours.momentApresMidi' => 'Afternoons',
			'parcours.momentSoir' => 'Evenings',
			'parcours.offresQuestion' => ({required Object prenom}) => 'Here are the open schedules for ${prenom}',
			'parcours.offresRaison' => 'These schedules are shown in your local time. Choosing a schedule saves your preference: it does not reserve a place and is not yet a class.',
			'parcours.offreRecommandee' => 'Closest to your answers',
			'parcours.offresAutres' => 'Other possible schedules',
			'parcours.offreLangue' => ({required Object langue}) => 'Class in ${langue}',
			'parcours.offreFuseau' => ({required Object fuseau}) => 'Time shown for ${fuseau}',
			'parcours.offreTraduite' => 'Shown in your local time',
			'parcours.offreJours' => ({required Object jours}) => '${jours}',
			'parcours.offreChoisir' => 'Choose this schedule',
			'parcours.offreChoisie' => 'Schedule chosen',
			'parcours.aucuneOffre' => 'No open schedule matches yet',
			'parcours.aucuneOffreDetail' => 'The academy opens new schedules as sign-ups come in. You can tell us what you need: it helps us decide which ones to open.',
			'parcours.refusAucun' => 'None of these schedules suits me',
			'parcours.refusPrevenir' => 'Let me know if new schedules open',
			'parcours.refusEffet' => 'We record that the request exists. This does not create a class, does not look for a teacher and does not promise any future schedule.',
			'parcours.refusEnregistre' => 'Noted. We will let you know if a matching schedule opens.',
			'parcours.etatAPersonnaliser' => 'Journey to personalise',
			'parcours.etatAPersonnaliserDetail' => ({required Object prenom}) => 'A few questions, and we will only show what suits ${prenom}.',
			'parcours.etatHoraireAChoisir' => 'Schedule to choose',
			'parcours.etatHoraireAChoisirDetail' => ({required Object prenom}) => 'The open schedules for ${prenom} are waiting for you.',
			'parcours.etatOffreIndisponible' => 'This schedule is no longer offered',
			'parcours.etatOffreIndisponibleDetail' => ({required Object prenom}) => 'The schedule chosen for ${prenom} was withdrawn before a class was formed. Choose another: nothing is lost.',
			'parcours.etatDiagnosticRequis' => 'Preference saved',
			'parcours.etatDiagnosticRequisDetail' => ({required Object dePrenom}) => 'One conversation with a teacher remains to place ${dePrenom}\'s level. The academy will offer you an appointment.',
			'parcours.etatDiagnosticEnAttente' => 'Appointment planned',
			'parcours.etatDiagnosticEnAttenteDetail' => ({required Object dePrenom}) => 'A conversation is planned to place ${dePrenom}\'s level.',
			'parcours.etatClasseEnFormation' => 'Class being formed',
			'parcours.etatClasseEnFormationDetailSansMinimum' => 'A class starts once there are enough students. We will let you know as soon as it is confirmed.',
			'parcours.etatClasseConfirmee' => 'Class confirmed',
			'parcours.etatClasseConfirmeeDetail' => ({required Object dePrenom}) => '${dePrenom}\'s class is formed. You will find its sessions in their space.',
			'parcours.fuseauChange' => 'Your location has changed since this choice',
			'parcours.fuseauChangeDetail' => 'The schedule is the same for the academy, but it no longer falls at the same time for you. Check that it still suits you.',
			'parcours.voirHoraires' => 'See the schedules',
			'parcours.changerHoraire' => 'Change schedule',
			'parcours.renoncerMotif' => 'The family changed schedule since the journey',
			'parcours.offreRecurrence' => ({required num seances, required Object duree}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(seances, one: '${seances} session per week, ${duree} min', other: '${seances} sessions per week, ${duree} min', ), 
			'parcours.offreRecurrencePause' => ({required num seances, required Object duree, required Object pause}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(seances, one: '${seances} session per week, ${duree} min including ${pause} min of break', other: '${seances} sessions per week, ${duree} min including ${pause} min of break', ), 
			'parcours.etatClasseEnFormationDetail' => ({required num minimum}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(minimum, one: 'A class starts once there is ${minimum} student. We will let you know as soon as it is confirmed.', other: 'A class starts once there are ${minimum} students. We will let you know as soon as it is confirmed.', ), 
			'nav.eleve.accueil' => 'Home',
			'nav.eleve.maClasse' => 'My class',
			'nav.eleve.coran' => 'Quran',
			'nav.eleve.monEspace' => 'My space',
			'nav.eleve.suivi' => 'Progress',
			'nav.eleve.compte' => 'Account',
			'nav.eleve.aujourdhui' => 'Today',
			'nav.eleve.apprendre' => 'Learn',
			'nav.eleve.profil' => 'Profile',
			'nav.tuteur.accueil' => 'Home',
			'nav.tuteur.foyer' => 'Household',
			'nav.tuteur.disponibilites' => 'Availability',
			'nav.tuteur.reglages' => 'Settings',
			'nav.tuteur.suivi' => 'Progress',
			'nav.tuteur.historique' => 'History',
			'nav.tuteur.compte' => 'Account',
			'nav.enseignant.journee' => 'Today',
			'nav.enseignant.classes' => 'Classes',
			'nav.enseignant.creneaux' => 'Availability',
			'nav.enseignant.profil' => 'Profile',
			'nav.enseignant.compte' => 'Account',
			'nav.controleur.planning' => 'Schedule',
			'nav.controleur.controle' => 'Review',
			'nav.controleur.historique' => 'History',
			'nav.controleur.echanges' => 'Messages',
			'nav.controleur.compte' => 'Account',
			'nav.admin.tableauDeBord' => 'Dashboard',
			'nav.admin.dossiers' => 'Files',
			'nav.admin.demandes' => 'Requests',
			'nav.admin.journal' => 'Log',
			'nav.admin.comptes' => 'Accounts',
			'nav.admin.accesAgents' => 'Agent access',
			'nav.admin.accueil' => 'Home',
			'nav.admin.operations' => 'Operations',
			'nav.admin.personnes' => 'People',
			'nav.admin.pedagogie' => 'Teaching',
			'nav.admin.finance' => 'Finance',
			'nav.admin.configuration' => 'Settings',
			'nav.admin.securite' => 'Security and audit',
			'nav.admin.direction' => 'Management',
			'nav.admin.recherche' => 'Search',
			'nav.admin.rechercheIndication' => 'Search for a screen',
			'nav.admin.notificationsTitre' => 'Notifications',
			'nav.admin.menu' => 'Menu',
			'nav.compte' => 'My account',
			'nav.principale' => 'Main navigation',
			'nav.motSymbole' => 'Rewayah',
			'nav.logoAccueil' => 'Rewayah Academy, home',
			'nav.replier' => 'Collapse navigation',
			'nav.deplier' => 'Expand navigation',
			'nav.halo.enCeMoment' => 'Right now',
			'nav.halo.monCompte' => 'My account',
			'nav.halo.urgentNom' => ({required Object compte}) => '${compte}, one urgent alert',
			'nav.halo.urgentMot' => 'Urgent',
			'nav.halo.ouvrirAlerte' => 'Open the alert',
			'nav.halo.nouveauNom' => ({required num n, required Object compte, required Object nombre}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${compte}, ${nombre} new item to read', other: '${compte}, ${nombre} new items to read', ), 
			'nav.halo.nouveauTitre' => ({required num n, required Object nombre}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${nombre} new item to read', other: '${nombre} new items to read', ), 
			'nav.halo.nouveauMot' => 'To read',
			'nav.halo.lire' => 'Read',
			'nav.halo.salleNom' => ({required Object compte}) => '${compte}, the room is open',
			'nav.filAriane.separateur' => '›',
			'nav.filAriane.suite' => ({required Object libelle}) => '› ${libelle}',
			'compte.page.langue.legende' => 'For the app and for the academy\'s emails',
			'compte.page.langue.refus' => 'The app changed language, but the language of your emails is not confirmed. Try again in a moment.',
			'compte.langue' => 'Language',
			'historique.titre' => 'History',
			'historique.detailSeance' => 'Session details',
			'historique.segments.seances' => 'Sessions',
			'historique.segments.observations' => 'Observations',
			'historique.moisCourts.0' => 'Jan',
			'historique.moisCourts.1' => 'Feb',
			'historique.moisCourts.2' => 'Mar',
			'historique.moisCourts.3' => 'Apr',
			'historique.moisCourts.4' => 'May',
			'historique.moisCourts.5' => 'Jun',
			'historique.moisCourts.6' => 'Jul',
			'historique.moisCourts.7' => 'Aug',
			'historique.moisCourts.8' => 'Sep',
			'historique.moisCourts.9' => 'Oct',
			'historique.moisCourts.10' => 'Nov',
			'historique.moisCourts.11' => 'Dec',
			'historique.dateCourte' => ({required Object mois, required Object jour, required Object annee}) => '${mois} ${jour}, ${annee}',
			'historique.dateLongue' => ({required Object jourSemaine, required Object mois, required Object jour, required Object annee}) => '${jourSemaine}, ${mois} ${jour}, ${annee}',
			'historique.plage' => ({required Object debut, required Object fin}) => '${debut} - ${fin}',
			'historique.duree.secondes' => ({required Object s}) => '${s} s',
			'historique.duree.minutes' => ({required Object m}) => '${m} min',
			'historique.duree.minutesSecondes' => ({required Object m, required Object s}) => '${m} min ${s} s',
			'historique.duree.heures' => ({required Object h}) => '${h} h',
			'historique.duree.heuresMinutes' => ({required Object h, required Object m}) => '${h} h ${m}',
			'historique.fuseauListe' => 'Times shown in this device\'s time.',
			'historique.fuseauDetail' => ({required Object decalage}) => 'Times shown in this device\'s time (UTC${decalage}).',
			'historique.classeInconnue' => 'Class not available',
			'historique.selecteur.aucune' => 'No session',
			'historique.selecteur.une' => '1 session',
			'historique.selecteur.plusieurs' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} session', other: '${n} sessions', ), 
			'historique.filtres.classe' => 'Class',
			'historique.filtres.toutesClasses' => 'All classes',
			'historique.filtres.periode' => 'Period',
			'historique.filtres.toutePeriode' => 'Whole period',
			'historique.filtres.septJours' => 'Last 7 days',
			'historique.filtres.trenteJours' => 'Last 30 days',
			'historique.filtres.troisMois' => 'Last 3 months',
			'historique.filtres.statut' => 'Status',
			'historique.filtres.tousStatuts' => 'All statuses',
			'historique.retour' => 'Back to the history',
			'historique.etat.presence' => 'Present',
			'historique.etat.retard' => ({required Object minutes}) => 'Late ${minutes} min',
			'historique.etat.retardSansDuree' => 'Late',
			'historique.etat.verification' => 'Being verified',
			'historique.etat.annule' => 'Class cancelled',
			'historique.etat.nonTenu' => 'Class not held',
			'historique.etat.avecDuree' => ({required Object etat, required Object duree}) => '${etat} · ${duree}',
			'historique.presenceIllisible' => 'Attendance could not be loaded: statuses stay unknown for now.',
			'historique.seances.videTitre' => 'No past sessions',
			'historique.seances.videPhrase' => ({required Object dePrenom}) => '${dePrenom}\'s past sessions will appear here.',
			'historique.seances.videPhraseFoyer' => 'The past sessions of the student profiles will appear here.',
			'historique.seances.filtreVideTitre' => 'No session matches',
			'historique.seances.filtreVidePhrase' => 'Change the filters to find the other sessions.',
			'historique.seances.tronquee' => ({required Object nombre}) => 'The ${nombre} most recent sessions are shown.',
			'historique.seances.ouvrir' => ({required Object date, required Object classe, required Object etat}) => 'Session of ${date}, ${classe}, ${etat}',
			'historique.observations.indisponibleTitre' => 'Observation history unavailable',
			'historique.observations.indisponiblePhrase' => 'Recorded visits cannot be read in the app yet.',
			'historique.observations.videTitre' => 'No observations',
			'historique.observations.videPhrase' => ({required Object dePrenom}) => 'The visits you make during ${dePrenom}\'s sessions will appear here.',
			'historique.observations.videPhraseFoyer' => 'Your visits during sessions will appear here.',
			'historique.observations.filtreVideTitre' => 'No observation matches',
			'historique.observations.filtreVidePhrase' => 'Change the filters to find the other visits.',
			'historique.observations.visiteUne' => '1 visit',
			'historique.observations.visites' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} visit', other: '${n} visits', ), 
			'historique.observations.dureeNonConfirmee' => 'Duration not confirmed',
			'historique.observations.terminee' => 'Ended',
			'historique.observations.nonRefermee' => 'Exit not recorded',
			'historique.observations.eleveInconnu' => 'Student',
			'historique.observations.tronquee' => 'Only the most recent visits are shown.',
			'historique.observations.ouvrir' => ({required Object date, required Object classe, required Object etat}) => 'Observations of ${date}, ${classe}, ${etat}',
			'historique.seance.titreSansClasse' => ({required Object date}) => 'Session of ${date}',
			'historique.seance.blocSeance' => 'The session',
			'historique.seance.blocPresence' => ({required Object dePrenom}) => '${dePrenom}\'s attendance',
			'historique.seance.date' => 'Date',
			'historique.seance.horaire' => 'Time',
			'historique.seance.dureePrevue' => 'Planned duration',
			'historique.seance.classe' => 'Class',
			'historique.seance.enseignant' => 'Teacher',
			'historique.seance.presence' => 'Attendance',
			'historique.seance.arrivee' => 'Arrival',
			'historique.seance.sortie' => 'Exit',
			'historique.seance.tempsPresence' => 'Time present',
			'historique.seance.minutesSur' => ({required Object minutes, required Object prevues}) => '${minutes} min out of ${prevues}',
			'historique.seance.presencePartielle' => 'Partial attendance',
			'historique.seance.interruption' => 'Interruption',
			'historique.seance.verificationPhrase' => 'Attendance is not yet confirmed for this session.',
			'historique.seance.mesureAutomatique' => 'Attendance measured automatically from connections to the room.',
			'historique.seance.nonTenuPhrase' => 'The session did not take place: this is not the student\'s doing.',
			'historique.seance.annulePhrase' => 'The session was cancelled.',
			'historique.seance.introuvableTitre' => 'Session not found',
			'historique.seance.introuvablePhrase' => 'This session is not in your household\'s history.',
			'historique.observation.titreSansClasse' => ({required Object date}) => 'Observations of ${date}',
			'historique.observation.blocResume' => 'Summary',
			'historique.observation.blocVisites' => 'Visits',
			'historique.observation.observateur' => 'Observer',
			'historique.observation.vous' => 'You',
			'historique.observation.eleve' => 'Student',
			'historique.observation.enseignant' => 'Teacher',
			'historique.observation.dureeTotale' => 'Total duration',
			'historique.observation.visite' => ({required Object n}) => 'Visit ${n}',
			'historique.observation.plageOuverte' => ({required Object debut}) => 'Entered at ${debut}',
			'historique.observation.terminee' => 'Visit ended',
			'historique.observation.introuvableTitre' => 'No visit for this session',
			'historique.observation.introuvablePhrase' => 'No recorded visit matches this session.',
			'historique.compteRendu.titre' => 'Teaching report',
			'historique.compteRendu.travaille' => 'What was worked on',
			'historique.compteRendu.appreciation' => 'Assessment of the session',
			'historique.compteRendu.aRenforcer' => 'To reinforce',
			'historique.compteRendu.aPreparer' => 'To prepare for the next session',
			'historique.compteRendu.commentaire' => 'Shared comment',
			'historique.compteRendu.corrigeLe' => ({required Object date}) => 'Corrected on ${date}',
			'historique.compteRendu.nonDisponibleTitre' => 'Teaching report not available',
			'historique.compteRendu.nonPartagePhrase' => 'The observations of this session are not shared with your family for now.',
			'historique.compteRendu.enAttentePhrase' => 'The report is not available yet.',
			'historique.compteRendu.illisiblePhrase' => 'The report cannot be displayed.',
			'historique.compteRendu.horsLignePhrase' => 'A connection is needed to view the report.',
			'historique.compteRendu.aucunChampPhrase' => 'No teaching report is available for this session.',
			'historique.compteRendu.voirTravail' => 'See the work to prepare',
			'historique.compteRendu.voirProgression' => 'See the progress',
			'historique.compteRendu.etatARenforcer' => 'To reinforce',
			'historique.compteRendu.etatAcquis' => 'Mastered',
			'historique.dateCourteSansAnnee' => ({required Object mois, required Object jour}) => '${mois} ${jour}',
			'notifications.evenements.bienvenueEquipe' => 'Welcome to the team. You still need to set up your space.',
			'notifications.evenements.retenuEntretien' => 'You have been selected for an interview. Let\'s get to know each other: choose your time in the app.',
			'notifications.evenements.pauseRepondueAcceptee' => ({required Object dePrenom, required Object mois}) => '${dePrenom}\'s one-month pause is accepted for ${mois}. Their deadline moves back by the same amount. Their place is kept.',
			'notifications.evenements.pauseRepondueAccepteeAdulte' => ({required Object mois}) => 'Your one-month pause is accepted for ${mois}. Your deadline moves back by the same amount. Your place is kept.',
			'notifications.evenements.pauseRepondueRefusee' => ({required Object dePrenom, required Object mois}) => '${dePrenom}\'s one-month pause for ${mois} is not accepted. The reason is in the app.',
			'notifications.evenements.pauseRepondueRefuseeAdulte' => ({required Object mois}) => 'Your one-month pause for ${mois} is not accepted. The reason is in the app.',
			'notifications.evenements.demandeRecue' => 'A new time slot request has been received.',
			'notifications.evenements.demandePresentation' => 'A standard display request has been received.',
			'notifications.evenements.classeValidee' => 'The class is ready and waiting for its teacher.',
			'notifications.evenements.enseignantAffecte' => 'A teacher has been assigned to the class.',
			'notifications.evenements.demandeClose' => 'A time slot request has been closed.',
			'notifications.evenements.remplacementPropose' => 'A class replacement is being offered to you.',
			'notifications.evenements.remplacementPris' => 'A class replacement has been assigned.',
			'notifications.evenements.controleMissionAttribuee' => 'A review mission has been assigned to you.',
			'notifications.evenements.controleMissionNonControlee' => 'A review mission was left without a check.',
			'notifications.evenements.classeChangee' => 'A student in the family has joined another class, at the same time.',
			'notifications.evenements.paiementRelance' => 'A payment is coming due. It is paid in Payments.',
			'notifications.evenements.accesSuspenduPaiement' => 'Access is suspended: this month\'s payment has not been received.',
			'notifications.evenements.accesRetabliPaiement' => 'Access is restored: the payment has been received.',
			'notifications.evenements.paiementRecu' => 'The payment has been received. The balance is up to date.',
			'notifications.evenements.accesSuspenduRemboursement' => 'Access is suspended: a payment was refunded, the month is no longer paid.',
			'notifications.evenements.accesSuspenduLitige' => 'Access is suspended: a payment is disputed with the bank.',
			'notifications.evenements.remboursementEffectue' => 'A refund has been made. The balance is up to date.',
			'notifications.evenements.remboursementEffectueDirection' => 'A refund has been made to a family.',
			'notifications.evenements.litigeOuvert' => 'A payment is disputed with the bank. Access is suspended during the review.',
			'notifications.evenements.litigeOuvertDirection' => 'A family is disputing a payment with their bank.',
			_ => null,
		} ?? switch (path) {
			'notifications.evenements.litigeClosGagne' => 'The dispute is closed: the bank ruled in the academy\'s favour.',
			'notifications.evenements.litigeClosPerdu' => 'The dispute is closed: the payment is refunded, the fees go to the household balance.',
			'notifications.evenements.litigeClosDirection' => 'A payment dispute is closed.',
			'notifications.evenements.enseignantAffecteSoi' => 'A teacher has been assigned to your class.',
			'notifications.evenements.toutEstPret' => 'All set: see the tracking of your request.',
			'notifications.evenements.toutEstPretSoi' => 'All set: your class, your teacher and your first class are confirmed.',
			'notifications.evenements.toutEstPretPour' => ({required Object prenom}) => 'All set for ${prenom}: see the tracking of the request.',
			'notifications.evenements.enseignantAffecteClasse' => 'A class is entrusted to you.',
			'notifications.evenements.remplacementPrisQuand' => ({required Object quand}) => 'The session of ${quand} will be taken by a replacement teacher.',
			'notifications.evenements.classeCreee' => 'A class has just been created.',
			'notifications.evenements.classeCreeeSoi' => 'Your class is created. Its schedule is in the app.',
			'notifications.evenements.classeCreeeFoyer' => 'A class is created for a student in your household.',
			'notifications.evenements.classeCreeeClasse' => 'A new class is entrusted to you.',
			'notifications.evenements.enseignantChange' => 'The class teacher has changed.',
			'notifications.evenements.enseignantChangeClasse' => 'The teacher of one of your classes has changed.',
			'notifications.evenements.eleveInscrit' => 'A student is registered in the class.',
			'notifications.evenements.eleveInscritSoi' => 'You are registered in a class.',
			'notifications.evenements.eleveInscritFoyer' => 'A student in your household is registered in a class.',
			'notifications.evenements.eleveInscritClasse' => 'A student joins one of your classes.',
			'notifications.evenements.eleveRetire' => 'A student is no longer part of the class.',
			'notifications.evenements.eleveRetireSoi' => 'You are no longer part of this class.',
			'notifications.evenements.eleveRetireFoyer' => 'A student in your household is no longer part of their class.',
			'notifications.evenements.eleveRetireClasse' => 'A student leaves one of your classes.',
			'notifications.evenements.creneauChange' => 'The class schedule has changed.',
			'notifications.evenements.changementHeureUn' => ({required Object date, required Object cours, required Object jour, required Object avant, required Object apres}) => 'From ${date}, ${cours} on ${jour} moves from ${avant} to ${apres}.',
			'notifications.evenements.changementHeurePlusieurs' => ({required Object date, required Object cours, required Object liste}) => 'From ${date}, the time ${cours} changes: ${liste}.',
			'notifications.evenements.changementHeureUnJour' => ({required Object date, required Object cours, required Object jourAvant, required Object avant, required Object jourApres, required Object apres}) => 'From ${date}, ${cours} moves from ${jourAvant} ${avant} to ${jourApres} ${apres}.',
			'notifications.evenements.changementHeureLigneJour' => ({required Object jourAvant, required Object avant, required Object jourApres, required Object apres}) => 'from ${jourAvant} ${avant} to ${jourApres} ${apres}',
			'notifications.evenements.changementHeureMecque' => 'The class stays at the same time in Makkah: it is your city\'s time that changes.',
			'notifications.evenements.conversionRefusee' => ({required Object classe, required Object raison}) => 'Class ${classe} could not move to Makkah time: ${raison} It will be retried tonight.',
			'notifications.evenements.conversionRefuseeProche' => 'a time change is approaching (less than 28 days).',
			'notifications.evenements.conversionRefuseeDemiHeure' => 'one of its slots has no whole hour in Makkah.',
			'notifications.evenements.conversionRefuseeAutre' => 'a check failed, see the class.',
			'notifications.evenements.changementHeureLigne' => ({required Object jour, required Object avant, required Object apres}) => 'on ${jour} from ${avant} to ${apres}',
			'notifications.evenements.changementHeureCoursUn' => 'your class',
			'notifications.evenements.changementHeureCoursUnFoyer' => 'the class',
			'notifications.evenements.changementHeureCoursPlusieurs' => 'your classes',
			'notifications.evenements.changementHeureCoursPlusieursFoyer' => 'the classes',
			'notifications.evenements.seanceAnnulee' => 'A session is cancelled.',
			'notifications.evenements.seanceAnnuleeQuand' => ({required Object quand}) => 'The session of ${quand} is cancelled.',
			'notifications.evenements.seanceDeplacee' => 'A session is moved.',
			'notifications.evenements.seanceDeplaceeQuand' => ({required Object quand}) => 'A session is moved to ${quand}.',
			'notifications.evenements.enseignanteAbsente' => 'The teacher will be absent from a session. A replacement is being sought.',
			'notifications.evenements.enseignanteAbsenteQuand' => ({required Object quand}) => 'The teacher will be absent from the session of ${quand}. A replacement is being sought.',
			'notifications.evenements.remplacementAvertissement' => 'You are not in the room yet. Join quickly: otherwise you lose access to today\'s session.',
			'notifications.evenements.remplacementAvertissementMinutes' => ({required num minutes}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(minutes, one: 'You are not in the room yet. Join within the minute: otherwise you lose access to today\'s session.', other: 'You are not in the room yet. Join within ${minutes} minutes: otherwise you lose access to today\'s session.', ), 
			'notifications.evenements.remplacementPreAlerte' => 'A replacement is being prepared: a teacher is not yet in their room. Declare yourself ready in Replacements.',
			'notifications.evenements.remplacementInutile' => 'The replacement is no longer needed: the class teacher has arrived. Thank you for being ready.',
			'notifications.evenements.titulaireEnRetard' => 'The class teacher is late. The academy is looking for a replacement: stay in the room.',
			'notifications.evenements.titulaireEnRetardDirection' => 'A class teacher has not entered their room. A replacement is being sought: see the schedule.',
			'notifications.evenements.remplacantArrive' => 'A replacement is arriving: stay in the room.',
			'notifications.evenements.classeSupprimee' => 'The class is closed.',
			'notifications.evenements.classeSupprimeeSoi' => 'Your class is closed.',
			'notifications.evenements.classeSupprimeeFoyer' => 'The class of a student in your household is closed.',
			'notifications.evenements.classeSupprimeeClasse' => 'One of your classes is closed.',
			'notifications.evenements.seanceTerminee' => 'A session has ended.',
			'notifications.evenements.seanceTermineeDe' => ({required Object deClasse, required Object quand}) => 'The session ${deClasse} of ${quand} has ended.',
			'notifications.evenements.seanceTermineeTravail' => ({required Object travail}) => 'Work to prepare: ${travail}',
			'notifications.evenements.seanceTermineeAucunTravail' => 'No work to prepare.',
			'notifications.evenements.seanceTermineePresents' => ({required num n, required Object total}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} student present out of ${total}.', other: '${n} students present out of ${total}.', ), 
			'notifications.evenements.seanceTermineeCahierAttend' => 'The handover notebook is waiting for your information.',
			'notifications.evenements.seanceTermineeCahierDepose' => 'Notebook submitted, thank you.',
			'notifications.evenements.seanceTermineePhrases' => ({required Object premiere, required Object suite}) => '${premiere} ${suite}',
			'notifications.evenements.inconnu' => 'This notification needs a more recent version of the app. Reload the page to read it.',
			'notifications.filtres.libelle' => 'Filter notifications',
			'notifications.filtres.toutes' => 'All',
			'notifications.filtres.nonLues' => 'Unread',
			'notifications.filtreVideTitre' => 'No notification in this filter',
			'notifications.filtreVidePhrase' => 'Choose "All" to see all your notifications again.',
			'notifications.voirToutes' => 'See all notifications',
			'notifications.sectionAFaire' => 'To do',
			'notifications.sectionNouvelles' => 'New',
			'notifications.sectionPlusAnciennes' => 'Older',
			'notifications.voirPlus' => 'See more',
			'notifications.voirPlusErreur' => 'Older notifications could not be loaded.',
			'notifications.toutMarquerLu' => 'Mark all as read',
			'notifications.ecarter' => 'Dismiss',
			'notifications.gesteTraiterContestation' => 'Handle the dispute',
			'notifications.gesteObserver' => 'Observe the class',
			'notifications.gesteRepondre' => 'Reply',
			'notifications.gestePrendreSeance' => 'Take the session',
			'notifications.gesteRecharger' => 'Reload',
			'notifications.ecartNonConfirme' => 'The dismissal is not yet confirmed. Try again in a moment.',
			'notifications.repetitions' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} time', other: '${n} times', ), 
			'notifications.nonLue' => 'Unread',
			'notifications.nonLueSemantique' => 'unread',
			'notifications.lectureNonConfirmee' => 'Reading is not yet confirmed. Try again in a moment.',
			'notifications.detail.recue' => ({required Object date, required Object heure}) => 'Received on ${date} at ${heure}',
			'notifications.detail.ouvrir' => 'Open the page concerned',
			'notifications.types.annonceClasse' => 'Class announcement',
			'notifications.types.changementSeance' => 'Session change',
			'notifications.types.decisionDossier' => 'Decision on a file',
			'notifications.types.messageMetier' => 'Message',
			'notifications.types.reponseAttendue' => 'Reply expected',
			'notifications.types.accesFinance' => 'Access and payments',
			'notifications.types.observation' => 'Observation',
			'notifications.types.travailRessource' => 'Work or resource',
			'notifications.types.annonceDirection' => 'Announcement from the management',
			'notifications.types.changementPlanning' => 'Schedule change',
			'notifications.types.remplacement' => 'Replacement',
			'notifications.types.mentionCommunaute' => 'Mention in the Community',
			'notifications.types.reponseCommunaute' => 'Reply in the Community',
			'notifications.types.messageAdministration' => 'Message from the Administration',
			'notifications.types.dossierATraiter' => 'File to handle',
			'notifications.types.signalementCommunaute' => 'Report in the Community',
			'notifications.types.reponseFil' => 'Reply in a conversation',
			'notifications.types.annoncePlanifiee' => 'Scheduled announcement to publish',
			'notifications.types.evenementOperationnel' => 'Academy event',
			'notifications.types.mission' => 'Mission',
			'notifications.types.changementMission' => 'Mission change',
			'notifications.types.reponseAdministration' => 'Reply from the Administration',
			'notifications.types.mentionStudio' => 'Mention in The Studio',
			'notifications.types.reponseStudio' => 'Reply in The Studio',
			'notifications.types.decisionDemandee' => 'Decision requested',
			'notifications.types.elementAssigne' => 'Assigned item',
			'notifications.types.annonceInterne' => 'Internal announcement',
			'notifications.types.evenementContextuel' => 'Event',
			'notifications.types.autre' => 'Notification',
			'notifications.titre' => 'Notifications',
			'notifications.quand' => ({required Object date, required Object heure}) => '${date} at ${heure}',
			'notifications.indisponibleTitre' => 'Notifications are not available yet',
			'notifications.indisponiblePhrase' => 'Session reminders and messages from the academy will appear here once they are open.',
			'notifications.videTitre' => 'No notifications',
			'notifications.videPhrase' => 'Session reminders and messages from the academy will appear here.',
			'notifications.ligne' => ({required Object titre, required Object date, required Object heure}) => '${titre}, on ${date} at ${heure}',
			'eleve.accueil.rejoindre' => 'Join',
			'eleve.accueil.coran' => 'The Quran',
			'eleve.accueil.coranDetail' => 'To read whenever you want',
			'eleve.accueil.coranEcouter' => 'Listen: The Quran',
			'eleve.accueil.prochainCours' => 'Next class',
			'eleve.accueil.coursEnDirect' => 'Your class has started',
			'eleve.accueil.avec' => ({required Object prenom}) => 'With ${prenom}',
			'eleve.accueil.dansMinutes' => ({required Object minutes}) => 'In ${minutes} min',
			'eleve.accueil.dansHeures' => ({required Object heures, required Object minutes}) => 'In ${heures} h ${minutes}',
			'eleve.accueil.demainA' => ({required Object heure}) => 'Tomorrow at ${heure}',
			'eleve.accueil.dansJours' => ({required num jours}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(jours, one: 'In ${jours} day', other: 'In ${jours} days', ), 
			'eleve.accueil.imminent' => 'It is almost time',
			'eleve.accueil.aucunCours' => 'No class today',
			'eleve.accueil.aucunCoursDetail' => 'Your teacher is preparing the next one.',
			'eleve.accueil.erreurCours' => 'Your classes could not be loaded. Try again in a moment.',
			'eleve.accueil.erreurCoursHorsLigneTitre' => 'Your classes are not available',
			'eleve.accueil.prochainAujourdhui' => 'Your next class is later today.',
			'eleve.accueil.prochainDemain' => 'Your next class is tomorrow.',
			'eleve.accueil.annulee' => 'This class will not take place',
			'eleve.accueil.horsLigne' => 'Entry pending',
			'eleve.accueil.horsLigneDetail' => 'You will be able to enter as soon as the network is back.',
			'eleve.accueil.pausePriere' => 'Prayer break',
			'eleve.accueil.pausePriereDetail' => ({required Object heure}) => 'At ${heure}',
			'eleve.accueil.prochainDansJours' => ({required num jours}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(jours, one: 'Your next class is in ${jours} day.', other: 'Your next class is in ${jours} days.', ), 
			'eleve.accueil.entreeSePrepare' => 'Your entry is getting ready. Try again in a moment.',
			'eleve.coran.titre' => 'The Quran',
			'eleve.coran.juz' => ({required Object juz}) => 'Juz ${juz}',
			'eleve.coran.mecquoise' => 'Revealed in Makkah',
			'eleve.coran.medinoise' => 'Revealed in Madinah',
			'eleve.coran.reprendre' => 'Resume your reading',
			'eleve.coran.reprendreDetail' => ({required Object page}) => 'You were on page ${page}',
			'eleve.coran.chargement' => 'The text is on its way',
			'eleve.coran.indisponible' => 'The text could not be loaded',
			'eleve.coran.indisponibleDetail' => 'As soon as the network is back, your page reopens here.',
			'eleve.coran.reessayer' => 'Try again',
			'eleve.coran.absent' => 'This page is empty',
			'eleve.coran.absentDetail' => 'The text has not been installed on this page. Report it: it is not you.',
			'eleve.coran.pagePrecedente' => 'Previous page',
			'eleve.coran.pageSuivante' => 'Next page',
			'eleve.coran.reglages' => 'Reading settings',
			'eleve.coran.fermerReglages' => 'Close the settings',
			'eleve.coran.taille' => 'Text size',
			'eleve.coran.agrandir' => 'Enlarge the text',
			'eleve.coran.reduire' => 'Reduce the text',
			'eleve.coran.source' => 'Quran text: Tanzil Project',
			'eleve.coran.sourceLien' => 'tanzil.net',
			'eleve.coran.edition' => 'Madinah Mushaf, Hafs riwaya',
			'eleve.suivi.colonneDate' => 'Date',
			'eleve.suivi.colonneCours' => 'Class',
			'eleve.suivi.colonneEnseignant' => 'Teacher',
			'eleve.suivi.colonneEtat' => 'Attendance',
			'eleve.suivi.cours' => 'Quran class',
			'eleve.suivi.moi' => 'My attendance',
			'eleve.suivi.aujourdhui' => ({required Object heure}) => 'Today, ${heure}',
			'eleve.suivi.hier' => ({required Object heure}) => 'Yesterday, ${heure}',
			'eleve.suivi.date' => ({required Object date, required Object heure}) => '${date}, ${heure}',
			'eleve.suivi.annule' => 'Class cancelled',
			'eleve.suivi.nonTenu' => 'Class not held',
			'eleve.suivi.vide' => 'No class yet',
			'eleve.suivi.videDetail' => 'Your classes will appear here, from the most recent to the oldest, with your attendance.',
			'eleve.suivi.erreur' => 'The tracking could not be loaded. Try again in a moment.',
			'eleve.suivi.tronquee' => ({required Object nombre}) => 'The ${nombre} most recent classes are shown.',
			'eleve.suivi.fin' => ({required Object nombre}) => '${nombre} classes in the tracking.',
			'eleve.suivi.finUn' => '1 class in the tracking.',
			'tuteur.accueil.titre' => 'Home',
			'tuteur.accueil.voirLaClasse' => 'See the class',
			'tuteur.accueil.prochaineSeance' => 'Next session',
			'tuteur.accueil.heureDe' => ({required Object deVille}) => '${deVille} time',
			'tuteur.accueil.heureAppareil' => 'This device\'s time',
			'tuteur.accueil.dateEtFuseau' => ({required Object date, required Object fuseau}) => '${date} · ${fuseau}',
			'tuteur.accueil.heureClasse' => ({required Object heure, required Object ville}) => 'Class time: ${heure} ${ville}',
			'tuteur.accueil.seanceEnDirect' => 'Live session',
			'tuteur.accueil.seanceTerminee' => 'Session ended',
			'tuteur.accueil.seanceAnnulee' => 'This session will not take place.',
			'tuteur.accueil.seanceNonTenue' => 'This session could not be held.',
			'tuteur.accueil.horaireIncertain' => 'Room opening not confirmed for now',
			'tuteur.accueil.horaireIncertainAvant' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: 'The join button will appear ${n} minute before the start.', other: 'The join button will appear ${n} minutes before the start.', ), 
			'tuteur.accueil.horaireIncertainPendant' => 'We cannot verify whether the room is open. Reload the page.',
			'tuteur.accueil.pastilleAnnulee' => 'Cancelled',
			'tuteur.accueil.pastilleNonTenue' => 'Not held',
			'tuteur.accueil.pastilleTerminee' => 'Ended',
			'tuteur.accueil.aucuneSeance' => 'No session planned',
			'tuteur.accueil.aucuneSeanceDetail' => ({required Object dePrenom}) => '${dePrenom}\'s next session will appear here as soon as it is scheduled.',
			'tuteur.accueil.seanceIllisible' => 'The next session could not be loaded.',
			'tuteur.accueil.classeIndisponible' => 'The class details are not yet available here.',
			'tuteur.accueil.classeIllisible' => 'The class could not be loaded.',
			'tuteur.accueil.sansClasseTitre' => ({required Object prenom}) => 'No class for ${prenom}',
			'tuteur.accueil.sansClassePhrase' => ({required Object quePrenom}) => 'Choose a class so ${quePrenom} can start classes.',
			'tuteur.accueil.financesTitre' => ({required Object dePrenom}) => '${dePrenom}\'s finances',
			'tuteur.accueil.financesPhrase' => 'Balance, next debit and what remains to be funded.',
			'tuteur.accueil.foyerVideTitre' => 'No student profile yet',
			'tuteur.accueil.foyerVidePhrase' => 'Add a student profile to choose a class and follow their sessions.',
			'tuteur.accueil.ouvrirEspaceEleve' => 'Open my student space',
			'tuteur.accueil.autreAppareilFeuille.phrase' => 'Your account follows you on all your devices. On the other device, open the app at this address, then sign in with the same sign-in address.',
			'tuteur.accueil.autreAppareilFeuille.aucunCode' => 'No code to enter: it is your own account.',
			'tuteur.accueil.autreAppareilFeuille.adresseApplication' => 'App address',
			'tuteur.accueil.autreAppareilFeuille.adresseConnexion' => 'Sign-in address',
			'tuteur.accueil.autreAppareilFeuille.copier' => 'Copy the app link',
			'tuteur.accueil.autreAppareilFeuille.copie' => 'Link copied',
			'tuteur.accueil.autreAppareil' => 'Use another device',
			'tuteur.accueil.ajouterProfil' => 'Add a student profile',
			'tuteur.accueil.profilsIllisibles' => 'The household profiles could not be loaded.',
			'tuteur.accueil.blocageAppareilTitre' => ({required Object prenom}) => 'No device ready for ${prenom}',
			'tuteur.accueil.blocageAppareilPhrase' => ({required Object prenom}) => 'Without a connected device, ${prenom} will not be able to join class.',
			'tuteur.accueil.connecterAppareil' => 'Connect a device',
			'tuteur.accueil.avantProchainCours' => 'Before the next class',
			'tuteur.accueil.voirTout' => 'See all',
			'tuteur.accueil.travailIndisponible' => 'The work to prepare is not yet linked to this space.',
			'tuteur.accueil.travailIllisible' => 'The work to prepare could not be loaded.',
			'tuteur.accueil.rienAPreparer' => 'Nothing to prepare for now',
			'tuteur.accueil.derniereSeance' => 'Last session',
			'tuteur.accueil.voirHistorique' => 'See the history',
			'tuteur.accueil.detailsSeance' => 'Session details',
			'tuteur.accueil.aucuneDerniere' => 'No past session yet',
			'tuteur.accueil.derniereIllisible' => 'The last session could not be loaded.',
			'tuteur.accueil.dateEtDuree' => ({required Object date, required Object duree}) => '${date} · ${duree}',
			'tuteur.accueil.etatCourt.enDirect' => 'Live',
			'tuteur.accueil.etatCourt.salleOuverte' => 'Room open',
			'tuteur.accueil.etatCourt.dansMinutes' => ({required Object minutes}) => 'In ${minutes} min',
			'tuteur.accueil.etatCourt.dansHeures' => ({required Object heures, required Object minutes}) => 'In ${heures} h ${minutes}',
			'tuteur.accueil.etatCourt.dansJours' => ({required Object jours}) => 'In ${jours} d',
			'tuteur.accueil.etatCourt.prevue' => 'Session planned',
			'tuteur.accueil.etatCourt.annulee' => 'Session cancelled',
			'tuteur.accueil.etatCourt.nonTenue' => 'Session not held',
			'tuteur.accueil.etatCourt.terminee' => 'Session ended',
			'tuteur.accueil.etatCourt.aucune' => 'No session',
			'tuteur.accueil.etatCourt.illisible' => 'Not available',
			'tuteur.accueil.assister' => 'Observe',
			'tuteur.accueil.assisterRefuse' => 'The class could not be joined. It may have just ended.',
			'tuteur.accueil.enCours' => ({required Object prenom}) => 'In progress with ${prenom}',
			'tuteur.accueil.depuisMinutes' => ({required Object minutes}) => 'Started ${minutes} min ago',
			'tuteur.accueil.depuisInstant' => 'Just started',
			'tuteur.accueil.aujourdhui' => ({required Object heure, required Object prenom}) => 'Today at ${heure}, with ${prenom}',
			'tuteur.accueil.unAutreJour' => ({required Object jour, required Object heure, required Object prenom}) => '${jour} at ${heure}, with ${prenom}',
			'tuteur.accueil.rienAujourdhui' => 'Nothing today',
			'tuteur.accueil.aucunCoursPrevu' => 'No class scheduled yet',
			'tuteur.accueil.aucunCoursPrevuDetail' => 'The week\'s classes are prepared in advance. This one will appear here.',
			'tuteur.accueil.enRecherche' => 'Looking for a teacher',
			'tuteur.accueil.enRechercheDepuis' => ({required Object date}) => 'Request submitted on ${date}',
			'tuteur.accueil.enRechercheSansDate' => ({required Object prenom}) => 'A teacher will take ${prenom} on from the times offered.',
			'tuteur.accueil.sansCreneau' => ({required Object prenom}) => 'No times offered for ${prenom}',
			'tuteur.accueil.sansCreneauDetail' => ({required Object prenom}) => 'Without a slot, no teacher can take ${prenom} on.',
			'tuteur.accueil.poserDesHeures' => 'Offer times',
			'tuteur.accueil.annulee' => ({required Object heure}) => 'The ${heure} class will not take place',
			'tuteur.accueil.motifAnnulee' => 'Session cancelled',
			'tuteur.accueil.motifAnnuleeTard' => 'Session cancelled shortly before the start time',
			'tuteur.accueil.proposeApres' => ({required Object jour, required Object heure}) => 'Next class ${jour} at ${heure}',
			'tuteur.accueil.proposeAucun' => 'A new class will be offered to you.',
			'tuteur.accueil.gererLeFoyer' => 'Manage the household',
			'tuteur.accueil.blocAppareils' => 'Household devices',
			'tuteur.accueil.blocAppareilsDetail' => 'Add a device, or remove one.',
			'tuteur.accueil.blocReglages' => 'Settings per child',
			'tuteur.accueil.blocReglagesDetail' => 'Photo, camera and display, child by child.',
			'tuteur.accueil.blocGroupesDetail' => 'Each child\'s class, teacher and next class.',
			'tuteur.accueil.acces' => 'Access',
			'tuteur.accueil.aucunEnfant' => 'No child in the household',
			'tuteur.accueil.aucunEnfantDetail' => 'Add your first child to get started.',
			'tuteur.accueil.erreur' => 'The household could not be loaded completely. Try again in a moment.',
			'classe.entree.coursDans' => ({required Object duree}) => 'Class in ${duree}',
			'classe.entree.coursImminent' => 'Class in less than a minute',
			'classe.entree.coursDemainA' => ({required Object heure}) => 'Class tomorrow at ${heure}',
			'classe.entree.coursDansJours' => ({required num jours}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(jours, one: 'Class in ${jours} day', other: 'Class in ${jours} days', ), 
			'classe.entree.revenirAvant' => 'This class is not open to you right now. Come back 20 minutes before the class time.',
			'classe.entree.rejoindre' => 'Join',
			'classe.entree.rejoindreLecteur' => ({required Object deClasse}) => 'Join ${deClasse}\'s session',
			'classe.entree.salleOuverte' => ({required Object duree}) => 'The room is open. The session starts in ${duree}.',
			'classe.entree.salleOuverteImminent' => 'The room is open. The session starts in less than a minute.',
			'classe.entree.preparation' => 'Getting ready',
			'classe.entree.attente' => ({required Object duree}) => 'You are in the room. The session starts in ${duree}.',
			'classe.entree.attenteImminent' => 'You are in the room. The session starts in less than a minute.',
			'classe.entree.enDirect' => 'Live session',
			'classe.entree.tempsEcoule' => 'Scheduled time elapsed',
			'classe.entree.terminee' => 'Session ended',
			'classe.entree.annulee' => 'Session cancelled',
			'classe.entree.aucune' => 'No session planned',
			'classe.entree.horsLigne' => 'You will be able to join the session as soon as the connection is back.',
			'classe.entree.indisponible' => 'The session information could not be loaded: the request may not have reached Rewayah. Try again in a moment.',
			'classe.entree.indisponibleCourt' => 'The session information could not be loaded',
			'classe.entree.indisponibleInvitation' => 'The request may not have reached Rewayah. Try again in a moment.',
			'classe.entree.accesInverifiable' => 'Access to the room cannot be verified right now.',
			'classe.entree.reessayer' => 'Try again',
			'classe.entree.chargementSeance' => 'Loading the next session.',
			'classe.entree.progressionValeur' => ({required Object chapitre, required Object pourcentage}) => '${chapitre} · ${pourcentage}%',
			'classe.entree.dst' => ({required Object avant, required Object apres}) => 'Time change: the class will move from ${avant} to ${apres}.',
			'classe.entree.annonce.aVenir' => 'Upcoming session',
			'classe.entree.annonce.fenetreOuverte' => 'The room is open',
			'classe.entree.annonce.attente' => 'You are in the room',
			'classe.entree.demo.titre' => 'Joining class',
			'classe.entree.demo.mention' => 'Demo',
			'classe.entree.demo.intro' => 'Fictitious data, no server call. Each link shows what the entry spot says for a role and a moment.',
			'classe.entree.demo.roles.eleve' => 'Student',
			'classe.entree.demo.roles.guidee' => 'Student, Guided interface',
			'classe.entree.demo.roles.enseignant' => 'Teacher',
			'classe.entree.demo.etats.aVenir' => 'Upcoming',
			'classe.entree.demo.etats.fenetreOuverte' => 'Window open',
			'classe.entree.demo.etats.preparation' => 'Getting ready',
			'classe.entree.demo.etats.attente' => 'Waiting before the start',
			'classe.entree.demo.etats.enDirect' => 'Live',
			'classe.entree.demo.etats.tempsEcoule' => 'Scheduled time elapsed',
			'classe.entree.demo.etats.terminee' => 'Ended',
			'classe.entree.demo.etats.annulee' => 'Cancelled',
			'classe.entree.demo.etats.horsLigne' => 'Offline',
			'classe.entree.demo.etats.indisponible' => 'Information unavailable',
			'classe.entree.demo.etats.changementHeure' => 'Time change',
			'classe.entree.demo.formeBouton' => 'Form: button',
			'classe.entree.demo.formeLigne' => 'Form: status line',
			'classe.entree.demo.lecteur' => ({required Object texte}) => 'Screen reader: ${texte}',
			'classe.entree.demo.annonce' => ({required Object texte}) => 'Announcement: ${texte}',
			'classe.entree.demo.detail' => ({required Object texte}) => 'Detail: ${texte}',
			'classe.entree.demo.retour' => 'Back to the list',
			'classe.planning' => 'Schedule',
			'classe.travail' => 'Before the next class',
			'classe.ressources' => 'Library',
			'classe.progression' => 'Progress',
			'classe.observer' => 'Observe the session',
			'classe.titre' => 'Class',
			'classe.historique' => 'History',
			'classe.sousTitre' => ({required Object prenom, required Object enseignant}) => '${prenom} · ${enseignant}',
			'classe.indisponiblePhrase' => 'The class details are not yet available here.',
			'classe.introuvableTitre' => 'This class is not open to this profile',
			'classe.introuvablePhrase' => 'It may have ended, or it concerns another student in the household.',
			'classe.disparue' => 'This class no longer exists.',
			'classe.seance.aucune' => 'No session planned',
			'classe.seance.aucuneDetail' => ({required Object dePrenom}) => '${dePrenom}\'s next session will appear here as soon as it is scheduled.',
			'classe.seance.illisible' => 'The next session could not be loaded.',
			'classe.seance.presence' => ({required Object prenom, required Object etat}) => '${prenom}: ${etat}',
			'classe.seance.rejoindreAvec' => ({required Object prenom}) => 'Join the room with ${prenom}',
			'classe.seance.salleOuvreA' => ({required Object heure}) => 'The room opens at ${heure}.',
			'classe.observation.commentCaMarche' => 'How does it work?',
			'classe.observation.uneVisite' => '1 visit available',
			'classe.observation.resume' => ({required Object visites, required Object duree}) => '${visites} · ${duree} per visit',
			'classe.observation.restanteAucune' => 'No visit left for this session',
			'classe.observation.restanteUne' => '1 visit left for this session',
			'classe.observation.minutesSecondes' => ({required Object minutes, required Object secondes}) => '${minutes} min ${secondes} s',
			'classe.observation.secondes' => ({required Object secondes}) => '${secondes} s',
			'classe.observation.motif.visitesEpuisees' => 'You have used your visits for this session.',
			'classe.observation.motif.tempsEpuise' => 'Your observation time is used up for this session.',
			'classe.observation.motif.seanceNonCommencee' => 'Observation opens when the session starts.',
			'classe.observation.motif.seanceTerminee' => 'The session has ended.',
			'classe.observation.motif.seanceNonTenue' => 'This session is not taking place: there is nothing to observe.',
			'classe.observation.motif.horsFenetre' => 'The room is not open at this time.',
			'classe.observation.motif.observationDesactivee' => 'Observation is closed for this class.',
			'classe.observation.motif.lienAbsent' => 'No student in your household is linked to this session.',
			'classe.observation.motif.enfantAbsent' => ({required Object dePrenom}) => 'Observation is waiting for ${dePrenom} to arrive.',
			'classe.observation.motif.presenceEnVerification' => ({required Object dePrenom}) => '${dePrenom}\'s attendance is being verified.',
			'classe.observation.motif.visiteDejaOuverte' => 'A visit is already open, on this device or another.',
			'classe.observation.motif.garantieServeurAbsente' => 'Session observation is not open yet.',
			'classe.observation.motif.reseau' => 'The availability of observation could not be verified.',
			'classe.observation.motif.capaciteAbsente' => 'Observation cannot open for this session.',
			'classe.observation.visites' => ({required num nombre}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(nombre, one: '${nombre} visit available', other: '${nombre} visits available', ), 
			'classe.observation.restantes' => ({required num nombre}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(nombre, one: '${nombre} visit left for this session', other: '${nombre} visits left for this session', ), 
			'classe.pagePlanning.prochaines' => 'Upcoming sessions',
			'classe.pagePlanning.ligne' => ({required Object heure, required Object duree}) => '${heure} · ${duree}',
			'classe.pagePlanning.ligneFuseau' => ({required Object heure, required Object fuseau, required Object duree}) => '${heure} (${fuseau}) · ${duree}',
			'classe.pagePlanning.aucune' => 'No upcoming session for now',
			'classe.pagePlanning.aucuneDetail' => ({required Object dePrenom}) => '${dePrenom}\'s next sessions will appear here as soon as they are scheduled.',
			'classe.pagePlanning.habituelIndisponible' => 'The class\'s usual days are not shown here yet: only sessions already scheduled appear.',
			'classe.pagePlanning.indisponible' => 'The class schedule is not yet linked to this space.',
			'classe.pageTravail.aucun' => 'Nothing to prepare for now',
			'classe.pageTravail.aucunDetail' => 'The work given by the teacher will appear here.',
			'classe.pageTravail.indisponible' => 'The work to prepare is not yet linked to this space.',
			'classe.pageTravail.echeance' => ({required Object date}) => 'Due: ${date}',
			'classe.pageTravail.nonCochable' => 'Marking work as done is not yet possible here.',
			'classe.pageTravail.statut.aFaire' => 'To do',
			'classe.pageTravail.statut.enCours' => 'Started',
			'classe.pageTravail.statut.fait' => 'Done',
			'classe.pageTravail.statut.expire' => 'Past due',
			'classe.pageRessources.aucune' => 'No resources for this class yet',
			'classe.pageRessources.aucuneDetail' => 'The materials chosen by the teacher will appear here.',
			'classe.pageRessources.indisponible' => 'The class library is not yet linked to this space.',
			'classe.pageProgression.indisponible' => ({required Object dePrenom}) => '${dePrenom}\'s progress is not shared here yet.',
			'classe.pageProgression.niveau' => 'Level',
			'classe.pageProgression.jalons' => 'Stages completed',
			'classe.pageProgression.aucune' => 'No stage shared yet',
			'classe.pageProgression.aucuneDetail' => 'The progress the teacher shares with the family will appear here.',
			'classe.cartes.titre' => 'Class cards',
			'classe.cartes.contexteEnseignant' => 'Tap a card to edit it. Students and their families see it immediately.',
			'classe.cartes.modificationPlusTard' => 'Cards can be edited when the connection is back.',
			'classe.cartes.aucune' => 'No cards yet',
			'classe.cartes.aucuneDetail' => 'The class teacher will post useful information here.',
			'classe.cartes.aucuneEnseignant' => 'No cards yet. Add one: the class will see it immediately.',
			'classe.cartes.ajouter' => 'Add a card',
			'classe.cartes.limite' => ({required Object max}) => '${max} cards at most: remove one to add another.',
			'classe.cartes.modifierLecteur' => ({required Object titre}) => 'Edit the card "${titre}"',
			'classe.cartes.echeance' => ({required Object date}) => 'Due: ${date}',
			'classe.cartes.copierLien' => ({required Object titre}) => 'Copy the link for "${titre}"',
			'classe.cartes.copierLienCourt' => 'Copy the link',
			'classe.cartes.lienCopie' => 'Link copied. Paste it into your browser to open it.',
			'classe.cartes.indisponibleTitre' => 'Class cards are not open yet',
			'classe.cartes.indisponiblePhrase' => 'They will appear here as soon as they open. Nothing to do on your side.',
			'classe.cartes.erreurLecture' => 'The class cards could not be loaded. Try again in a moment.',
			'classe.cartes.sansDonnees' => 'The class cards could not be loaded',
			'classe.cartes.enregistree' => 'Card saved. The class sees it now.',
			'classe.cartes.retiree' => 'Card removed. The class no longer sees it.',
			'classe.cartes.types.annonce' => 'Announcement',
			'classe.cartes.types.devoir' => 'Homework',
			'classe.cartes.types.lien' => 'Useful link',
			'classe.cartes.types.rappel' => 'Reminder',
			'classe.cartes.typesDetail.annonce' => 'For information for the whole class.',
			'classe.cartes.typesDetail.devoir' => 'For work to prepare: the suggested due date is the next session.',
			'classe.cartes.typesDetail.lien' => 'To share a page or a material: paste its address.',
			'classe.cartes.typesDetail.rappel' => 'For a date not to forget: outing, exam, schedule change.',
			'classe.cartes.modeles.annonce' => 'Information for the class',
			'classe.cartes.modeles.devoir' => 'To prepare for the next session',
			'classe.cartes.modeles.lien' => 'Material to look at',
			'classe.cartes.modeles.rappel' => 'Do not forget',
			'classe.cartes.feuille.titreNouvelle' => 'New class card',
			'classe.cartes.feuille.titreModifier' => ({required Object titre}) => 'Edit the card "${titre}"',
			'classe.cartes.feuille.contexte' => 'Choose a template: it pre-fills the card. It is immediately visible to the class students and their families.',
			'classe.cartes.feuille.modele' => 'Card template',
			'classe.cartes.feuille.champTitre' => 'Card title',
			'classe.cartes.feuille.champTexte' => 'Card text (optional)',
			'classe.cartes.feuille.champLien' => 'Card link (optional)',
			'classe.cartes.feuille.aideLongueur' => ({required Object max}) => '${max} characters at most',
			'classe.cartes.feuille.aideLien' => 'A full address, starting with https://',
			'classe.cartes.feuille.echeanceAucune' => 'No due date',
			'classe.cartes.feuille.choisirEcheance' => 'Choose the due date',
			'classe.cartes.feuille.retirerEcheance' => 'Remove the due date',
			'classe.cartes.feuille.enregistrer' => 'Save the card',
			'classe.cartes.feuille.retirer' => 'Remove this card',
			'classe.cartes.feuille.retirerQuestion' => ({required Object titre}) => 'Remove the card "${titre}"?',
			'classe.cartes.feuille.retirerConsequence' => 'It disappears immediately for the class students and their families.',
			'classe.cartes.feuille.retirerConfirmer' => 'Remove the card',
			'classe.cartes.feuille.envoiNonConfirme' => 'The card is not confirmed: the reply did not arrive. Save again in a moment.',
			'classe.cartes.feuille.retraitNonConfirme' => 'The removal is not confirmed: the reply did not arrive. Try again in a moment.',
			'classe.cartes.feuille.defauts.titreVide' => 'The title is missing. Write a few words, for example "Surah to review".',
			'classe.cartes.feuille.defauts.titreLong' => ({required Object max}) => 'The title exceeds ${max} characters. Shorten it.',
			'classe.cartes.feuille.defauts.texteLong' => ({required Object max}) => 'The text exceeds ${max} characters. Shorten it or share a link.',
			'classe.cartes.feuille.defauts.lienInvalide' => 'This link is not a full address. Paste an address that starts with https://.',
			'classe.cartes.feuille.defauts.echeanceManquante' => 'Homework needs a due date. Choose the due date.',
			'suiviFamille.titre' => 'Tracking of requests',
			'suiviFamille.contexte' => 'Each request moves forward step by step. You are notified at each stage.',
			'suiviFamille.carteTitre' => ({required Object dePrenom}) => '${dePrenom}\'s request',
			'suiviFamille.detailTitre' => ({required Object dePrenom}) => 'Tracking of ${dePrenom}\'s request',
			'suiviFamille.etapeCourante' => ({required Object etape}) => 'Current step: ${etape}',
			'suiviFamille.toutFait' => 'All steps are complete.',
			'suiviFamille.voirSuivi' => 'See the tracking',
			'suiviFamille.vide' => 'No request for now.',
			'suiviFamille.faireDemande' => 'Make a request',
			'suiviFamille.erreur' => 'The tracking could not be loaded. Try again.',
			'suiviFamille.sansDonnees' => 'your requests',
			'suiviFamille.introuvable' => 'This request no longer exists or is not yours.',
			'suiviFamille.retour' => 'Back to requests',
			'suiviFamille.fuseau' => ({required Object deVille}) => 'Times shown: ${deVille} time.',
			'suiviFamille.prevue' => ({required Object date, required Object heure}) => 'Planned for ${date} at ${heure}',
			'suiviFamille.prevueJour' => ({required Object date}) => 'Planned for ${date}',
			'suiviFamille.etapes.envoyee' => 'Request sent',
			'suiviFamille.etapes.enAttente' => 'On the waiting list',
			'suiviFamille.etapes.classeCreee' => 'Class created',
			'suiviFamille.etapes.enseignantAffecte' => 'Teacher assigned',
			'suiviFamille.etapes.eleveIntegre' => 'Student placed',
			'suiviFamille.etapes.premiereSeance' => 'First session',
			'suiviFamille.etats.fait' => 'Done',
			'suiviFamille.etats.enCours' => 'In progress',
			'suiviFamille.etats.aVenir' => 'Upcoming',
			'suiviFamille.motif.classesPleines' => 'All classes for this slot are full. You will be notified as soon as a place opens.',
			'suiviFamille.motif.aucunEnseignantLibre' => 'No teacher is free for this slot for now. You will be notified as soon as that changes.',
			'suiviFamille.motif.inconnu' => 'Your request is pending. You will be notified as soon as it moves forward.',
			'suiviFamille.intervalle.moinsHeure' => 'Less than an hour later',
			'suiviFamille.intervalle.heures' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} hour later', other: '${n} hours later', ), 
			'suiviFamille.intervalle.jours' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} day later', other: '${n} days later', ), 
			'suiviFamille.notification.enAttente' => ({required Object dePrenom}) => '${dePrenom}\'s request: on the waiting list',
			'suiviFamille.notification.eleveIntegre' => ({required Object dePrenom}) => '${dePrenom}\'s request: student placed in the class',
			'suiviFamille.notification.premiereSeance' => ({required Object dePrenom}) => '${dePrenom}\'s request: first session held',
			'suiviFamille.notification.close' => ({required Object dePrenom, required Object motif}) => '${dePrenom}\'s request: ${motif}',
			'suiviFamille.notification.dejaEnClasse' => ({required Object dePrenom}) => '${dePrenom}\'s request: student already in a class, request filed',
			'suiviFamille.etapeSurTotal' => ({required Object n, required Object total, required Object etape}) => 'Step ${n} of ${total}: ${etape}',
			'suiviFamille.close.etat' => 'Request closed',
			'suiviFamille.close.suite' => ({required Object prenom}) => 'You can choose another slot for ${prenom}.',
			'suiviFamille.close.suiteSansChoix' => 'Nothing else to do on your side.',
			'suiviFamille.close.choisirAutre' => ({required Object prenom}) => 'Choose another slot for ${prenom}',
			'suiviFamille.close.motif.retraitFamille' => 'You withdrew this request.',
			'suiviFamille.close.motif.offreRetiree' => 'This slot is no longer offered.',
			'suiviFamille.close.motif.classeNonConstituee' => 'The class for this slot could not be formed.',
			'suiviFamille.close.motif.refusDirection' => 'The management did not accept this request.',
			'suiviFamille.close.motif.dejaEnClasse' => ({required Object prenom}) => '${prenom} already has a place in a class: this request is no longer needed.',
			'suiviFamille.close.motif.inconnu' => 'This request is closed.',
			'suiviDemandes.titre' => 'Tracking of time slot requests',
			'suiviDemandes.contexte' => 'Each request moves forward step by step. You are notified at each stage.',
			'suiviDemandes.carteTitre' => ({required Object dePrenom}) => '${dePrenom}\'s time slot request',
			'suiviDemandes.joursChoisis' => 'Chosen days',
			'suiviDemandes.heureChoisie' => 'Chosen time',
			'suiviDemandes.joursEt' => ({required Object debut, required Object dernier}) => '${debut} and ${dernier}',
			'suiviDemandes.heureFuseau' => ({required Object heure, required Object deVille}) => '${heure}, ${deVille} time',
			'suiviDemandes.creneauxChoisis' => 'Chosen days and times',
			'suiviDemandes.jourHeure' => ({required Object jour, required Object heure}) => '${jour} ${heure}',
			'suiviDemandes.fuseauChoisi' => 'Time zone',
			_ => null,
		} ?? switch (path) {
			'suiviDemandes.fuseauValeur' => ({required Object deVille}) => '${deVille} time',
			'suiviDemandes.etapes.envoyee' => 'Request sent',
			'suiviDemandes.etapes.classeValidee' => 'Class approved',
			'suiviDemandes.etapes.enseignantAffecte' => 'Teacher assigned',
			'suiviDemandes.etapes.listeAttente' => 'On the waiting list',
			'suiviDemandes.etapes.eleveIntegre' => 'Student placed in the class',
			'suiviDemandes.etapes.coursCommences' => 'Classes start',
			'suiviDemandes.etats.fait' => 'Done',
			'suiviDemandes.etats.enCours' => 'In progress',
			'suiviDemandes.etats.prochaine' => 'Next step',
			'suiviDemandes.etats.aVenir' => 'Upcoming',
			'suiviDemandes.situation.envoyee' => 'Your request has reached the administration',
			'suiviDemandes.situation.classeValidee' => 'Your class is ready: it is waiting for its teacher',
			'suiviDemandes.situation.enseignantAffecte' => 'Class approved · teacher assigned',
			'suiviDemandes.situation.listeAttente' => 'Your request is on the waiting list',
			'suiviDemandes.situation.eleveIntegre' => 'Class approved · teacher assigned · student placed',
			'suiviDemandes.situation.coursCommences' => 'Classes have started',
			'suiviDemandes.prochaine.envoyee' => 'Next step: forming the class',
			'suiviDemandes.prochaine.classeValidee' => 'Next step: the class teacher is appointed. We will let you know as soon as it is done.',
			'suiviDemandes.prochaine.listeAttente' => 'We will let you know as soon as a place opens. No date is announced until it is known.',
			'suiviDemandes.prochaine.eleveIntegre' => 'Next step: classes start',
			'suiviDemandes.debutCours' => 'Classes start',
			'suiviDemandes.debutValeur' => ({required Object date, required Object heure, required Object deVille}) => '${date} at ${heure}, ${deVille} time',
			'suiviDemandes.debutAFixer' => 'The date of the first class will appear here as soon as it is set.',
			'suiviDemandes.enseignant' => 'Teacher',
			'suiviDemandes.personnaliseNotice' => 'This slot will only open if other students choose it and fill the class.',
			'suiviDemandes.close.retiree' => 'Request withdrawn',
			'suiviDemandes.close.nonRetenue' => 'Request not accepted',
			'suiviDemandes.close.close' => 'Request closed',
			'suiviDemandes.close.motif.retraitFamille' => 'You withdrew this request.',
			'suiviDemandes.close.motif.offreRetiree' => 'The academy removed this slot from its offers.',
			'suiviDemandes.close.motif.classeNonConstituee' => 'The class for this slot could not be formed.',
			'suiviDemandes.close.motif.refusDirection' => 'The management could not accept this request.',
			'suiviDemandes.close.motif.dejaEnClasse' => ({required Object prenom}) => '${prenom} already has a place in a class: this request is no longer needed.',
			'suiviDemandes.close.motif.inconnu' => 'This request is closed.',
			'suiviDemandes.close.suite' => 'You can choose another slot among those offered.',
			'suiviDemandes.close.suiteSansChoix' => 'No other slot is offered for now. Come back to this page later.',
			'suiviDemandes.close.choisirAutre' => ({required Object prenom}) => 'Choose another slot for ${prenom}',
			'suiviDemandes.vide' => 'No time slot request in progress.',
			'suiviDemandes.erreur' => 'The tracking of your requests could not be displayed: the reading may not have reached Rewayah. This failure only concerns the display of the tracking: it says nothing about your time slot requests. Try again in a moment.',
			'suiviDemandes.sansDonnees' => 'The tracking of requests could not be loaded',
			'suiviDemandes.accueil.titre' => 'Your time slot requests',
			'suiviDemandes.accueil.ligne' => ({required Object prenom, required Object etat}) => '${prenom}: ${etat}',
			'suiviDemandes.accueil.voir' => 'See the tracking of requests',
			'suiviDemandes.notification.envoyee' => ({required Object dePrenom}) => '${dePrenom}\'s time slot request: your request has reached the administration',
			'suiviDemandes.notification.classeValidee' => ({required Object dePrenom}) => '${dePrenom}\'s time slot request: your class is ready, it is waiting for its teacher',
			'suiviDemandes.notification.enseignantAffecte' => ({required Object dePrenom}) => '${dePrenom}\'s time slot request: class approved · teacher assigned',
			'suiviDemandes.notification.close' => ({required Object dePrenom, required Object motif}) => '${dePrenom}\'s time slot request: ${motif}',
			'suiviDemandes.notification.listeAttente' => ({required Object dePrenom}) => '${dePrenom}\'s time slot request: your request is on the waiting list',
			'suiviDemandes.notification.eleveIntegre' => ({required Object dePrenom}) => '${dePrenom}\'s time slot request: student placed in the class',
			'suiviDemandes.notification.coursCommences' => ({required Object dePrenom}) => '${dePrenom}\'s time slot request: classes have started',
			'suiviDemandes.notification.dejaEnClasse' => ({required Object dePrenom}) => '${dePrenom}\'s time slot request: student already in a class, request filed',
			'suiviDemandes.notification.changementFusion' => ({required Object dePrenom}) => '${dePrenom}\'s time slot request: your class was merged with another, see the new class',
			'suiviDemandes.notification.changementTransfert' => ({required Object dePrenom}) => '${dePrenom}\'s time slot request: new class, see the details',
			'suiviDemandes.jalon.apres' => ({required Object date, required Object heure, required Object duree}) => '${date} at ${heure}, ${duree}',
			'suiviDemandes.jalon.aussitot' => 'immediately',
			'suiviDemandes.jalon.minutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} minute later', other: '${n} minutes later', ), 
			'suiviDemandes.jalon.heures' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} hour later', other: '${n} hours later', ), 
			'suiviDemandes.jalon.jours' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} day later', other: '${n} days later', ), 
			'suiviDemandes.changement.titrePage' => 'Class change',
			'suiviDemandes.changement.titre' => ({required Object dePrenom}) => '${dePrenom}\'s class has changed',
			'suiviDemandes.changement.fusion' => ({required Object prenom}) => 'Your class was merged with another. ${prenom} now has the class below.',
			'suiviDemandes.changement.transfert' => ({required Object prenom}) => 'The management moved ${prenom} to another class. Here is the new class.',
			'suiviDemandes.changement.classe' => 'New class',
			'suiviDemandes.changement.enseignant' => 'Teacher',
			'suiviDemandes.changement.sansEnseignant' => 'Their teacher will be announced as soon as one is appointed.',
			'suiviDemandes.changement.date' => 'Change made on',
			'suiviDemandes.changement.lien' => 'See the new class',
			'suiviDemandes.changement.lienPour' => ({required Object dePrenom}) => 'See ${dePrenom}\'s new class',
			'suiviDemandes.changement.retour' => 'Back to the tracking of requests',
			'suiviDemandes.changement.introuvable' => 'This class change no longer needs to be shown',
			'suiviDemandes.changement.introuvableDetail' => 'Go back to the tracking to see where your requests stand.',
			'juridique.titre' => 'Legal information',
			'juridique.intro' => 'The texts that govern the service. They can be read without an account.',
			'juridique.version' => ({required Object version, required Object date}) => 'Version ${version}, text of ${date}',
			'juridique.contact' => ({required Object contact}) => 'For any question, write to ${contact}.',
			'juridique.lire' => 'Read',
			'juridique.coord.societe' => 'Company: Rewayah Academy Ltd',
			'juridique.coord.numero' => 'Registration number: 16624644, England and Wales',
			'juridique.coord.adresse' => 'Registered office: 71-75 Shelton Street, Covent Garden, London WC2H 9JQ, United Kingdom',
			'juridique.aCompleter' => ({required Object quoi}) => '[to be completed by the management: ${quoi}]',
			'accueilInscrits.titre' => 'We already know you',
			'accueilInscrits.phrase' => 'Your registration has been carried over. You do not have to enter everything again.',
			'accueilInscrits.motTitre' => 'A word from the management',
			'accueilInscrits.elevesTitre' => 'Your children already registered',
			'accueilInscrits.elevesPhrase' => 'Their first name is already filled in. Their age remains to be entered.',
			'accueilInscrits.aJour' => 'Up to date',
			'accueilInscrits.aCompleter' => 'To complete',
			'accueilInscrits.ajouterProfil' => ({required Object dePrenom}) => 'Add ${dePrenom}\'s student profile',
			'accueilInscrits.plusTard' => 'You can also do it later, from the Household.',
			'accueilInscrits.sansEleve' => 'No student profile was carried over for your family. You can add one from the Household.',
			'accueilInscrits.finirCompte' => 'A few questions remain to finish your account.',
			'accueilInscrits.continuer' => 'Continue',
			'accueilInscrits.echecTitre' => 'Your registration could not be verified',
			'accueilInscrits.echecPhrase' => 'Probable cause: the connection to the server was interrupted (not confirmed). Try again in a moment: nothing is created twice.',
			'accueilInscrits.sansDonnees' => 'The check of your registration',
			'accueilInvite.titre' => 'Your invitation',
			'accueilInvite.roles.foyer' => 'Rewayah Academy invites you as a guardian.',
			'accueilInvite.roles.enseignant' => 'Rewayah Academy invites you as a teacher.',
			'accueilInvite.roles.comptable' => 'Rewayah Academy invites you as an accountant.',
			'accueilInvite.roles.candidat' => 'Rewayah Academy invites you as a teaching applicant.',
			'accueilInvite.invitant' => ({required Object prenom}) => 'Person inviting you to their household: ${prenom}.',
			'accueilInvite.foyerIdentite' => 'Tell us who you are, then answer the invitation. Your account is only created if you accept it.',
			'accueilInvite.suite' => 'Continue to create your account.',
			'accueilInvite.champsRequis' => 'Enter your first name, last name and gender.',
			'payUx.repriseTitre' => 'Did you leave the form without paying?',
			'payUx.reprisePhrase' => 'Resume the payment: a new form opens. If the payment already went through, nothing is paid twice; reload to see its status.',
			'payUx.reprendre' => 'Resume payment',
			'payUx.rassurance' => 'Payment is processed by Stripe. Your card details go directly to Stripe: Rewayah Academy does not see them and does not keep them.',
			'payUx.precedentOuvertTitre' => 'The payment started earlier could not be closed',
			'payUx.precedentOuvertPhrase' => 'Nothing is paid twice and no new form opens. Try again in a moment: if that payment has just gone through, it will appear in your payments.',
			'payUx.payer' => 'Pay',
			'payUx.ouCarte' => 'Or pay by card',
			'payUx.enCours' => 'Payment in progress',
			'payUx.refus' => 'The payment did not go through: some card information is probably incomplete or refused. Check it, then press "Pay" again. Nothing was paid.',
			'accueilHoraire.demandeTitre' => 'Request saved',
			'accueilHoraire.demandeDetail' => ({required Object prenom}) => 'We will let you know as soon as a time slot opens for ${prenom}.',
			'accueilHoraire.erreurEnvoi' => 'Your request was not confirmed. Try again in a moment.',
			'suiviAttente.titre' => 'Where your request stands',
			'suiviAttente.titreSimple' => 'Where your request stands',
			'suiviAttente.tu.formationListeAttente' => 'All classes for this slot are full. Your request is waiting for a place to open.',
			'suiviAttente.tu.confirmeeFait' => 'Your class is confirmed.',
			'suiviAttente.tu.confirmeeFaitNom' => ({required Object classe}) => 'Your class "${classe}" is confirmed.',
			'suiviAttente.tu.enseignantEnAttente' => 'Your class is waiting for its teacher. The academy appoints one and lets you know.',
			'suiviAttente.tu.pretEnCours' => 'The academy is setting your first class. It lets you know as soon as the date is known.',
			'suiviAttente.tu.pretAVenir' => 'Your first class is announced once the teacher is assigned.',
			'suiviAttente.tu.premierCoursPasse' => ({required Object quand}) => 'Your first class took place on ${quand}.',
			'suiviAttente.tu.premierCoursPetit' => 'Your first class is coming. Your guardian will tell you when.',
			'suiviAttente.tu.premierCoursPassePetit' => 'Your first class took place.',
			'suiviAttente.tu.depasse' => 'Forming your class is taking longer than expected.',
			'suiviAttente.tu.changement' => ({required Object date}) => 'The class slot changed on ${date}. Your guardian received the notice.',
			'suiviAttente.tu.titreRefusee' => 'Your request was not accepted',
			'suiviAttente.tu.retraitFamille' => 'Your guardian withdrew this request.',
			'suiviAttente.tu.erreur' => 'We could not read your request. This is often caused by the connection. Try again in a moment.',
			'suiviAttente.tu.sansDonnees' => 'Your request could not be loaded',
			'suiviAttente.tu.introuvable' => 'This request no longer exists.',
			'suiviAttente.contexte' => 'The academy confirms each step. You are notified at each stage.',
			'suiviAttente.contexteSimple' => 'Here is where your request stands. The academy lets you know at each step.',
			'suiviAttente.pour' => ({required Object prenom}) => 'For ${prenom}',
			'suiviAttente.etapeSurTotal' => ({required Object n, required Object total, required Object etape}) => 'Step ${n} of ${total}: ${etape}',
			'suiviAttente.etapes.recue' => 'Request received',
			'suiviAttente.etapes.formation' => 'Class being formed',
			'suiviAttente.etapes.confirmee' => 'Class confirmed',
			'suiviAttente.etapes.enseignant' => 'Teacher assigned',
			'suiviAttente.etapes.pret' => 'All set',
			'suiviAttente.etats.fait' => 'Done',
			'suiviAttente.etats.enCours' => 'In progress',
			'suiviAttente.etats.aVenir' => 'Upcoming',
			'suiviAttente.dit.recueFait' => 'Your request has reached the academy.',
			'suiviAttente.dit.recueFaitSimple' => 'Your request has reached the academy.',
			'suiviAttente.dit.formationEnCours' => 'The academy is bringing together the students of this class.',
			'suiviAttente.dit.formationListeAttente' => 'All classes for this slot are full. Your request is waiting for a place to open.',
			'suiviAttente.dit.formationFait' => 'The students of the class have been brought together.',
			'suiviAttente.dit.formationAVenir' => 'The academy brings the class students together once the request is received.',
			'suiviAttente.dit.confirmeeFait' => 'Your class is confirmed.',
			'suiviAttente.dit.confirmeeFaitNom' => ({required Object classe}) => 'Your class "${classe}" is confirmed.',
			'suiviAttente.dit.confirmeeAVenir' => 'The academy confirms the class when its students are brought together.',
			'suiviAttente.dit.enseignantEnCours' => 'The academy is appointing the class teacher.',
			'suiviAttente.dit.enseignantEnAttente' => 'Your class is waiting for its teacher. The academy appoints one and lets you know.',
			'suiviAttente.dit.enseignantFait' => 'Your teacher is known.',
			'suiviAttente.dit.enseignantFaitSimple' => 'Your teacher is known.',
			'suiviAttente.dit.enseignantAVenir' => 'The academy appoints the teacher once the class is confirmed.',
			'suiviAttente.dit.pretFait' => 'The class, the teacher and the first class are known.',
			'suiviAttente.dit.pretEnCours' => 'The academy is setting your first class. You are notified as soon as the date is known.',
			'suiviAttente.dit.pretAVenir' => 'Your first class is announced once the teacher is assigned.',
			'suiviAttente.premierCours' => ({required Object quand}) => 'Your first class: ${quand}',
			'suiviAttente.premierCoursSimple' => ({required Object quand}) => 'Your first class: ${quand}',
			'suiviAttente.premierCoursPasse' => ({required Object quand}) => 'Your first class took place on ${quand}.',
			'suiviAttente.depuis' => ({required Object date}) => 'Since ${date}',
			'suiviAttente.ensuite' => ({required Object etape}) => 'Next: ${etape}',
			'suiviAttente.delai.depasse' => 'Forming your class is taking longer than expected.',
			'suiviAttente.changement' => ({required Object date}) => 'The class slot changed on ${date}. You received the notice in your notifications.',
			'suiviAttente.cloture.titreRefusee' => 'Your request was not accepted',
			'suiviAttente.cloture.titreRetiree' => 'This request is withdrawn',
			'suiviAttente.cloture.titreClose' => 'This request is closed',
			'suiviAttente.cloture.motif.retraitFamille' => 'You withdrew this request.',
			'suiviAttente.cloture.motif.offreRetiree' => 'The academy removed this slot from its offers.',
			'suiviAttente.cloture.motif.classeNonConstituee' => 'The class for this slot could not be formed.',
			'suiviAttente.cloture.motif.refusDirection' => 'The management did not accept this request.',
			'suiviAttente.cloture.motif.dejaEnClasse' => 'This student already has a place in a class: the request is no longer needed.',
			'suiviAttente.cloture.motif.inconnu' => 'This request is closed.',
			'suiviAttente.cloture.suite' => 'You can choose another slot.',
			'suiviAttente.cloture.autreCreneau' => 'Choose another slot',
			'suiviAttente.cloture.simple.refusee' => 'Your request was not accepted. Your guardian can choose another slot.',
			'suiviAttente.cloture.simple.retiree' => 'This request is withdrawn.',
			'suiviAttente.cloture.simple.close' => 'This request is closed.',
			'suiviAttente.enseignant.titre' => 'Your teacher',
			'suiviAttente.enseignant.titreSimple' => 'Your teacher',
			'suiviAttente.enseignant.sayyid' => 'Sayyid',
			'suiviAttente.enseignant.sayyida' => 'Sayyida',
			'suiviAttente.enseignant.nomPlein' => ({required Object prenom}) => '${prenom}',
			'suiviAttente.enseignant.nomAvecTitre' => ({required Object titre, required Object prenom}) => '${titre} ${prenom}',
			'suiviAttente.enseignant.langue' => 'Class language',
			'suiviAttente.enseignant.origine' => 'Country of origin',
			'suiviAttente.enseignant.residence' => 'Country of residence',
			'suiviAttente.enseignant.mot' => 'Their introduction',
			'suiviAttente.enseignant.peutSePresenter' => 'Your teacher can introduce themselves to the families of the class with a message in Messages.',
			'suiviAttente.vide.message' => 'You have not chosen a class yet.',
			'suiviAttente.vide.invitation' => 'Choose a class: the academy then follows you step by step.',
			'suiviAttente.vide.action' => 'Choose a class',
			'suiviAttente.vide.messageSimple' => 'There is no class request for you yet.',
			'suiviAttente.vide.invitationSimple' => 'Your guardian can make one.',
			'suiviAttente.erreur' => 'We could not read the tracking of your request. This is often caused by the connection. Try again in a moment.',
			'suiviAttente.sansDonnees' => 'The tracking of your request could not be loaded',
			'suiviAttente.introuvable' => 'This request no longer exists in your tracking.',
			'suiviAttente.retour' => 'Back',
			'suiviAttente.carte.titre' => 'Your class request',
			'suiviAttente.carte.titreSimple' => 'Your class request',
			'suiviAttente.carte.ligne' => ({required Object prenom, required Object n, required Object total, required Object etape}) => '${prenom}: step ${n} of ${total}, ${etape}',
			'suiviAttente.carte.suivre' => 'Follow my request',
			'suiviAttente.carte.pret' => ({required Object prenom, required Object quand}) => '${prenom}: all set. First class: ${quand}',
			'suiviAttente.carte.pretSansDate' => ({required Object prenom}) => '${prenom}: all set.',
			'suiviAttente.presentation.titre' => 'What families see of you',
			'suiviAttente.presentation.phrase' => 'The families of your classes already see, as everywhere in the app, your title, first name, class language, photo and country if it is filled in. This setting only concerns the card tracking their request: you choose to also show your two countries and an introduction there, when you have entered them.',
			'suiviAttente.presentation.montrer' => 'Show my countries and my introduction on the tracking card',
			'suiviAttente.presentation.paysOrigine' => 'Country of origin',
			'suiviAttente.presentation.paysResidence' => 'Country of residence',
			'suiviAttente.presentation.choisirPays' => 'Choose a country',
			'suiviAttente.presentation.nonRenseigne' => 'Not provided',
			'suiviAttente.presentation.mot' => 'My introduction',
			'suiviAttente.presentation.motAide' => '500 characters at most. Families read it exactly as you write it.',
			'suiviAttente.presentation.nonConfirme' => 'You have not confirmed this choice yet. Until you do, your countries and your introduction, if entered, are shown on the tracking card.',
			'suiviAttente.presentation.enregistrer' => 'Save',
			'suiviAttente.presentation.enregistre' => 'Saved.',
			'suiviAttente.presentation.erreur' => 'Your choice is not confirmed: it may not have reached Rewayah. Try again in a moment.',
			'suiviAttente.presentation.effacerPays' => 'Do not provide',
			'suiviAttente.mePresenter.lien' => 'Introduce myself to the families',
			'suiviAttente.mePresenter.titre' => 'Introduce myself',
			'suiviAttente.mePresenter.contexte' => 'A message is already written. You can edit it before sending. It goes in Messages, to the families of the class and to adult students.',
			'suiviAttente.mePresenter.messageSayyid' => ({required Object nom, required Object classe}) => 'Hello, I am Sayyid ${nom}, your teacher for the class "${classe}". I am glad to begin with you. Write to me here if you have a question. See you soon.',
			'suiviAttente.mePresenter.messageSayyida' => ({required Object nom, required Object classe}) => 'Hello, I am Sayyida ${nom}, your teacher for the class "${classe}". I am glad to begin with you. Write to me here if you have a question. See you soon.',
			'suiviAttente.mePresenter.champ' => 'Your message',
			'suiviAttente.mePresenter.rappel' => 'This message is read by the guardians of minor students and by adult students. It is never sent to a minor. Do not exchange phone numbers or addresses: everything goes through the app.',
			'suiviAttente.mePresenter.envoyer' => 'Send to the families',
			'suiviAttente.mePresenter.envoye' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: 'Message sent to ${n} family.', other: 'Message sent to ${n} families.', ), 
			'suiviAttente.mePresenter.dejaEcrit' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} family already has a conversation with you: it does not receive this message.', other: '${n} families already have a conversation with you: they do not receive this message.', ), 
			'suiviAttente.mePresenter.aucune' => 'No family in this class can receive a message right now.',
			'suiviAttente.mePresenter.echec' => 'The message is not confirmed for some families: it may not have reached them. Try again: those who received it do not receive it twice.',
			'suiviAttente.mePresenter.chargement' => 'Loading the families of the class',
			'suiviAttente.mePresenter.erreur' => 'The families of the class could not be loaded. Try again in a moment.',
			'suiviAttente.mePresenter.vide' => 'Write a message before sending it.',
			_ => null,
		};
	}
}
