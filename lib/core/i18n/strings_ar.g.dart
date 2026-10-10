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
class TraductionsAr extends Traductions with BaseTranslations<AppLocale, Traductions> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TraductionsAr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Traductions>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ar,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ar>.
	final TranslationMetadata<AppLocale, Traductions> _meta;
	@override TranslationMetadata<AppLocale, Traductions> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TraductionsAr _root = this; // ignore: unused_field

	@override 
	TraductionsAr $copyWith({TranslationMetadata<AppLocale, Traductions>? meta}) => TraductionsAr(meta: meta ?? this.$meta);

	// Translations
	@override late final _Traductions$formulaire$ar formulaire = _Traductions$formulaire$ar._(_root);
	@override late final _Traductions$kyc$ar kyc = _Traductions$kyc$ar._(_root);
	@override late final _Traductions$notifications$ar notifications = _Traductions$notifications$ar._(_root);
	@override late final _Traductions$historique$ar historique = _Traductions$historique$ar._(_root);
	@override late final _Traductions$commun$ar commun = _Traductions$commun$ar._(_root);
	@override late final _Traductions$etat$ar etat = _Traductions$etat$ar._(_root);
	@override late final _Traductions$accessibilite$ar accessibilite = _Traductions$accessibilite$ar._(_root);
	@override late final _Traductions$classe$ar classe = _Traductions$classe$ar._(_root);
	@override late final _Traductions$salle$ar salle = _Traductions$salle$ar._(_root);
	@override late final _Traductions$eleve$ar eleve = _Traductions$eleve$ar._(_root);
	@override late final _Traductions$enseignant$ar enseignant = _Traductions$enseignant$ar._(_root);
	@override late final _Traductions$compte$ar compte = _Traductions$compte$ar._(_root);
	@override late final _Traductions$tuteur$ar tuteur = _Traductions$tuteur$ar._(_root);
	@override late final _Traductions$nav$ar nav = _Traductions$nav$ar._(_root);
	@override late final _Traductions$tc$ar tc = _Traductions$tc$ar._(_root);
	@override late final _Traductions$com$ar com = _Traductions$com$ar._(_root);
	@override late final _Traductions$choix$ar choix = _Traductions$choix$ar._(_root);
	@override late final _Traductions$destructif$ar destructif = _Traductions$destructif$ar._(_root);
	@override late final _Traductions$reseau$ar reseau = _Traductions$reseau$ar._(_root);
	@override late final _Traductions$admin$ar admin = _Traductions$admin$ar._(_root);
	@override late final _Traductions$comptable$ar comptable = _Traductions$comptable$ar._(_root);
}

// Path: formulaire
class _Traductions$formulaire$ar extends Traductions$formulaire$fr {
	_Traductions$formulaire$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get manqueAccord => 'موافقتك ناقصة: ضع علامة في الخانة للمتابعة.';
	@override late final _Traductions$formulaire$motif$ar motif = _Traductions$formulaire$motif$ar._(_root);
}

// Path: kyc
class _Traductions$kyc$ar extends Traductions$kyc$fr {
	_Traductions$kyc$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get manquePhoto => 'اختر أولًا صورة وثيقتك.';
	@override String get manqueType => 'اختر أولًا الوثيقة التي تودعها.';
}

// Path: notifications
class _Traductions$notifications$ar extends Traductions$notifications$fr {
	_Traductions$notifications$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الإشعارات';
	@override String get indisponibleTitre => 'الإشعارات غير متاحة بعد';
	@override String get indisponiblePhrase => 'ستظهر هنا تذكيرات الحصص ورسائل الأكاديمية بمجرد تفعيلها.';
	@override String get videTitre => 'لا توجد إشعارات';
	@override String get videPhrase => 'ستظهر هنا تذكيرات الحصص ورسائل الأكاديمية.';
	@override String ligne({required Object titre, required Object date, required Object heure}) => '${titre}‏، يوم ${date} الساعة ${heure}';
	@override late final _Traductions$notifications$filtres$ar filtres = _Traductions$notifications$filtres$ar._(_root);
	@override String get filtreVideTitre => 'لا توجد إشعارات في هذا التصنيف';
	@override String get filtreVidePhrase => 'اختر «الكل» لرؤية جميع إشعاراتك من جديد.';
	@override String get voirToutes => 'عرض كل الإشعارات';
	@override String get nonLue => 'غير مقروء';
	@override String get nonLueSemantique => 'غير مقروء';
	@override String get lectureNonConfirmee => 'لم تُؤكَّد القراءة بعد. أعد المحاولة بعد قليل.';
	@override late final _Traductions$notifications$detail$ar detail = _Traductions$notifications$detail$ar._(_root);
	@override late final _Traductions$notifications$types$ar types = _Traductions$notifications$types$ar._(_root);
}

// Path: historique
class _Traductions$historique$ar extends Traductions$historique$fr {
	_Traductions$historique$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override List<String> get moisCourts => [
		'يناير',
		'فبراير',
		'مارس',
		'أبريل',
		'مايو',
		'يونيو',
		'يوليو',
		'أغسطس',
		'سبتمبر',
		'أكتوبر',
		'نوفمبر',
		'ديسمبر',
	];
	@override String dateCourte({required Object jour, required Object mois, required Object annee}) => '${jour} ${mois} ${annee}';
	@override String dateCourteSansAnnee({required Object jour, required Object mois}) => '${jour} ${mois}';
	@override String dateLongue({required Object jourSemaine, required Object jour, required Object mois, required Object annee}) => '${jourSemaine} ${jour} ${mois} ${annee}';
}

// Path: commun
class _Traductions$commun$ar extends Traductions$commun$fr {
	_Traductions$commun$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$commun$recherche$ar recherche = _Traductions$commun$recherche$ar._(_root);
	@override late final _Traductions$commun$sections$ar sections = _Traductions$commun$sections$ar._(_root);
	@override late final _Traductions$commun$dates$ar dates = _Traductions$commun$dates$ar._(_root);
	@override String get reessayer => 'إعادة المحاولة';
	@override String get annuler => 'إلغاء';
	@override late final _Traductions$commun$choix$ar choix = _Traductions$commun$choix$ar._(_root);
	@override late final _Traductions$commun$etats$ar etats = _Traductions$commun$etats$ar._(_root);
}

// Path: etat
class _Traductions$etat$ar extends Traductions$etat$fr {
	_Traductions$etat$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get enDirect => 'مباشر';
	@override String get seanceAnnulee => 'ملغاة';
	@override String annuleeValeur({required Object valeur}) => 'ملغاة: ${valeur}';
	@override String get motifNonCommunique => 'السبب غير متوفر';
	@override String get aucunRemplacantTrouve => 'لم يُعثر على بديل';
	@override String get seanceNonFacturee => 'الحصة غير مفوترة';
	@override String raisonEtSuite({required Object raison, required Object suite}) => '${raison} · ${suite}';
}

// Path: accessibilite
class _Traductions$accessibilite$ar extends Traductions$accessibilite$fr {
	_Traductions$accessibilite$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$accessibilite$tutoiement$ar tutoiement = _Traductions$accessibilite$tutoiement$ar._(_root);
}

// Path: classe
class _Traductions$classe$ar extends Traductions$classe$fr {
	_Traductions$classe$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$classe$entree$ar entree = _Traductions$classe$entree$ar._(_root);
	@override String get catalogue => 'اختيار فصل';
	@override String get planning => 'الجدول';
	@override String get travail => 'قبل الدرس القادم';
	@override String get ressources => 'المكتبة';
	@override String get progression => 'التقدم';
	@override String get observer => 'متابعة الحصة';
	@override String get titre => 'الفصل';
	@override String get historique => 'السجل';
	@override String sousTitre({required Object prenom, required Object enseignant}) => '${prenom} · ${enseignant}';
	@override String get indisponiblePhrase => 'تفاصيل الفصل غير متاحة هنا بعد.';
	@override String get introuvableTitre => 'هذا الفصل غير متاح لهذا الملف';
	@override String get introuvablePhrase => 'ربما انتهى، أو يخص طالبًا آخر من الأسرة.';
	@override late final _Traductions$classe$seance$ar seance = _Traductions$classe$seance$ar._(_root);
	@override late final _Traductions$classe$observation$ar observation = _Traductions$classe$observation$ar._(_root);
	@override late final _Traductions$classe$pagePlanning$ar pagePlanning = _Traductions$classe$pagePlanning$ar._(_root);
	@override late final _Traductions$classe$pageTravail$ar pageTravail = _Traductions$classe$pageTravail$ar._(_root);
	@override late final _Traductions$classe$pageRessources$ar pageRessources = _Traductions$classe$pageRessources$ar._(_root);
	@override late final _Traductions$classe$pageProgression$ar pageProgression = _Traductions$classe$pageProgression$ar._(_root);
	@override late final _Traductions$classe$pageCatalogue$ar pageCatalogue = _Traductions$classe$pageCatalogue$ar._(_root);
	@override late final _Traductions$classe$cartes$ar cartes = _Traductions$classe$cartes$ar._(_root);
}

// Path: salle
class _Traductions$salle$ar extends Traductions$salle$fr {
	_Traductions$salle$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get microOuvert => 'الميكروفون مفتوح';
	@override String get microCoupe => 'الميكروفون مغلق';
	@override String get cameraAllumee => 'الكاميرا مشغّلة';
	@override String get cameraCoupee => 'الكاميرا مطفأة';
	@override late final _Traductions$salle$secours$ar secours = _Traductions$salle$secours$ar._(_root);
}

// Path: eleve
class _Traductions$eleve$ar extends Traductions$eleve$fr {
	_Traductions$eleve$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$eleve$accueil$ar accueil = _Traductions$eleve$accueil$ar._(_root);
	@override late final _Traductions$eleve$suivi$ar suivi = _Traductions$eleve$suivi$ar._(_root);
}

// Path: enseignant
class _Traductions$enseignant$ar extends Traductions$enseignant$fr {
	_Traductions$enseignant$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$enseignant$journee$ar journee = _Traductions$enseignant$journee$ar._(_root);
	@override late final _Traductions$enseignant$ficheGroupe$ar ficheGroupe = _Traductions$enseignant$ficheGroupe$ar._(_root);
}

// Path: compte
class _Traductions$compte$ar extends Traductions$compte$fr {
	_Traductions$compte$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get themeContexte => 'اختر مظهر التطبيق. يتم التغيير فورًا ويبقى على هذا الجهاز، ويمكنك تعديله في أي وقت.';
	@override String get themeSysteme => 'النظام';
	@override String get themeSystemeDetail => 'يتبع إعداد جهازك';
	@override String get themeClair => 'فاتح';
	@override String get themeClairDetail => 'خلفية فاتحة مهما كان إعداد جهازك';
	@override String get themeSombre => 'داكن';
	@override String get themeSombreDetail => 'خلفية داكنة مهما كان إعداد جهازك';
}

// Path: tuteur
class _Traductions$tuteur$ar extends Traductions$tuteur$fr {
	_Traductions$tuteur$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tuteur$accueil$ar accueil = _Traductions$tuteur$accueil$ar._(_root);
}

// Path: nav
class _Traductions$nav$ar extends Traductions$nav$fr {
	_Traductions$nav$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$nav$eleve$ar eleve = _Traductions$nav$eleve$ar._(_root);
	@override late final _Traductions$nav$tuteur$ar tuteur = _Traductions$nav$tuteur$ar._(_root);
	@override late final _Traductions$nav$enseignant$ar enseignant = _Traductions$nav$enseignant$ar._(_root);
	@override late final _Traductions$nav$controleur$ar controleur = _Traductions$nav$controleur$ar._(_root);
	@override late final _Traductions$nav$admin$ar admin = _Traductions$nav$admin$ar._(_root);
	@override String get compte => 'حسابي';
	@override String get principale => 'التنقل الرئيسي';
	@override String get motSymbole => 'Rewayah';
	@override String get replier => 'طيّ شريط التنقل';
	@override String get deplier => 'فتح شريط التنقل';
}

// Path: tc
class _Traductions$tc$ar extends Traductions$tc$fr {
	_Traductions$tc$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tc$groupe$ar groupe = _Traductions$tc$groupe$ar._(_root);
	@override late final _Traductions$tc$bibliotheque$ar bibliotheque = _Traductions$tc$bibliotheque$ar._(_root);
}

// Path: com
class _Traductions$com$ar extends Traductions$com$fr {
	_Traductions$com$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$com$socle$ar socle = _Traductions$com$socle$ar._(_root);
	@override late final _Traductions$com$messages$ar messages = _Traductions$com$messages$ar._(_root);
	@override late final _Traductions$com$vocal$ar vocal = _Traductions$com$vocal$ar._(_root);
	@override late final _Traductions$com$communaute$ar communaute = _Traductions$com$communaute$ar._(_root);
	@override late final _Traductions$com$studio$ar studio = _Traductions$com$studio$ar._(_root);
	@override late final _Traductions$com$annonces$ar annonces = _Traductions$com$annonces$ar._(_root);
}

// Path: choix
class _Traductions$choix$ar extends Traductions$choix$fr {
	_Traductions$choix$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get autre => 'آخر';
	@override String get autreInvite => 'حدّد';
	@override String get selectionMultiple => 'يمكن اختيار أكثر من إجابة';
}

// Path: destructif
class _Traductions$destructif$ar extends Traductions$destructif$fr {
	_Traductions$destructif$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get irreversible => 'لا يمكن التراجع عن هذا الإجراء.';
}

// Path: reseau
class _Traductions$reseau$ar extends Traductions$reseau$fr {
	_Traductions$reseau$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get horsLigne => 'لا توجد شبكة. يبقى كل شيء متاحًا للاطلاع، وسينتظر الإرسال.';
}

// Path: admin
class _Traductions$admin$ar extends Traductions$admin$fr {
	_Traductions$admin$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$admin$evaluations$ar evaluations = _Traductions$admin$evaluations$ar._(_root);
	@override late final _Traductions$admin$programmes$ar programmes = _Traductions$admin$programmes$ar._(_root);
	@override late final _Traductions$admin$finance$ar finance = _Traductions$admin$finance$ar._(_root);
}

// Path: comptable
class _Traductions$comptable$ar extends Traductions$comptable$fr {
	_Traductions$comptable$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$comptable$nav$ar nav = _Traductions$comptable$nav$ar._(_root);
	@override late final _Traductions$comptable$onglets$ar onglets = _Traductions$comptable$onglets$ar._(_root);
	@override late final _Traductions$comptable$commun$ar commun = _Traductions$comptable$commun$ar._(_root);
	@override late final _Traductions$comptable$coffres$ar coffres = _Traductions$comptable$coffres$ar._(_root);
	@override late final _Traductions$comptable$statuts$ar statuts = _Traductions$comptable$statuts$ar._(_root);
	@override late final _Traductions$comptable$alertes$ar alertes = _Traductions$comptable$alertes$ar._(_root);
	@override late final _Traductions$comptable$aujourdhui$ar aujourdhui = _Traductions$comptable$aujourdhui$ar._(_root);
	@override late final _Traductions$comptable$paiements$ar paiements = _Traductions$comptable$paiements$ar._(_root);
	@override late final _Traductions$comptable$tresorerie$ar tresorerie = _Traductions$comptable$tresorerie$ar._(_root);
	@override late final _Traductions$comptable$encaissements$ar encaissements = _Traductions$comptable$encaissements$ar._(_root);
	@override late final _Traductions$comptable$beneficiaires$ar beneficiaires = _Traductions$comptable$beneficiaires$ar._(_root);
	@override late final _Traductions$comptable$contractuels$ar contractuels = _Traductions$comptable$contractuels$ar._(_root);
	@override late final _Traductions$comptable$validation$ar validation = _Traductions$comptable$validation$ar._(_root);
	@override late final _Traductions$comptable$direction$ar direction = _Traductions$comptable$direction$ar._(_root);
	@override late final _Traductions$comptable$demo$ar demo = _Traductions$comptable$demo$ar._(_root);
}

// Path: formulaire.motif
class _Traductions$formulaire$motif$ar extends Traductions$formulaire$motif$fr {
	_Traductions$formulaire$motif$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get manqueSaisi => 'السبب ناقص: اكتبه في كلمات قليلة.';
}

// Path: notifications.filtres
class _Traductions$notifications$filtres$ar extends Traductions$notifications$filtres$fr {
	_Traductions$notifications$filtres$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'تصفية الإشعارات';
	@override String get toutes => 'الكل';
	@override String get nonLues => 'غير المقروءة';
	@override String get mentions => 'الإشارات';
	@override String get actionRequise => 'إجراء مطلوب';
}

// Path: notifications.detail
class _Traductions$notifications$detail$ar extends Traductions$notifications$detail$fr {
	_Traductions$notifications$detail$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get choisirTitre => 'اختر إشعارًا';
	@override String get choisirPhrase => 'تظهر تفاصيله هنا، بجانب القائمة.';
	@override String recue({required Object date, required Object heure}) => 'وصل يوم ${date} الساعة ${heure}';
	@override String get ouvrir => 'فتح الصفحة المعنية';
}

// Path: notifications.types
class _Traductions$notifications$types$ar extends Traductions$notifications$types$fr {
	_Traductions$notifications$types$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get annonceClasse => 'إعلان الفصل';
	@override String get changementSeance => 'تغيير في الحصة';
	@override String get decisionDossier => 'قرار بشأن ملف';
	@override String get messageMetier => 'رسالة';
	@override String get reponseAttendue => 'رد منتظر';
	@override String get accesFinance => 'الوصول والمدفوعات';
	@override String get observation => 'ملاحظة';
	@override String get travailRessource => 'واجب أو مورد';
	@override String get annonceDirection => 'إعلان من الإدارة';
	@override String get changementPlanning => 'تغيير في الجدول';
	@override String get remplacement => 'استخلاف';
	@override String get mentionCommunaute => 'إشارة في مجتمع المعلمين';
	@override String get reponseCommunaute => 'رد في مجتمع المعلمين';
	@override String get messageAdministration => 'رسالة من الإدارة';
	@override String get dossierATraiter => 'ملف للمعالجة';
	@override String get signalementCommunaute => 'بلاغ في مجتمع المعلمين';
	@override String get reponseFil => 'رد في محادثة';
	@override String get annoncePlanifiee => 'إعلان مجدول للنشر';
	@override String get evenementOperationnel => 'حدث في الأكاديمية';
	@override String get mission => 'مهمة';
	@override String get changementMission => 'تغيير في المهمة';
	@override String get reponseAdministration => 'رد من الإدارة';
	@override String get mentionStudio => 'إشارة في الاستوديو';
	@override String get reponseStudio => 'رد في الاستوديو';
	@override String get decisionDemandee => 'قرار مطلوب';
	@override String get elementAssigne => 'عنصر مُسند';
	@override String get annonceInterne => 'إعلان داخلي';
	@override String get evenementContextuel => 'حدث';
	@override String get autre => 'إشعار';
}

// Path: commun.recherche
class _Traductions$commun$recherche$ar extends Traductions$commun$recherche$fr {
	_Traductions$commun$recherche$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get effacer => 'مسح البحث';
	@override String get fermer => 'إغلاق البحث';
}

// Path: commun.sections
class _Traductions$commun$sections$ar extends Traductions$commun$sections$fr {
	_Traductions$commun$sections$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get page => 'أقسام الصفحة';
}

// Path: commun.dates
class _Traductions$commun$dates$ar extends Traductions$commun$dates$fr {
	_Traductions$commun$dates$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get premierJour => '1';
	@override List<String> get jours => [
		'الاثنين',
		'الثلاثاء',
		'الأربعاء',
		'الخميس',
		'الجمعة',
		'السبت',
		'الأحد',
	];
	@override List<String> get mois => [
		'يناير',
		'فبراير',
		'مارس',
		'أبريل',
		'مايو',
		'يونيو',
		'يوليو',
		'أغسطس',
		'سبتمبر',
		'أكتوبر',
		'نوفمبر',
		'ديسمبر',
	];
	@override String jourDate({required Object jour, required Object numero, required Object mois}) => '${jour} ${numero} ${mois}';
}

// Path: commun.choix
class _Traductions$commun$choix$ar extends Traductions$commun$choix$fr {
	_Traductions$commun$choix$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get indisponible => 'غير متاح';
}

// Path: commun.etats
class _Traductions$commun$etats$ar extends Traductions$commun$etats$fr {
	_Traductions$commun$etats$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$commun$etats$chargementProlonge$ar chargementProlonge = _Traductions$commun$etats$chargementProlonge$ar._(_root);
	@override late final _Traductions$commun$etats$horsLigne$ar horsLigne = _Traductions$commun$etats$horsLigne$ar._(_root);
	@override late final _Traductions$commun$etats$reconnexion$ar reconnexion = _Traductions$commun$etats$reconnexion$ar._(_root);
	@override late final _Traductions$commun$etats$echecServeur$ar echecServeur = _Traductions$commun$etats$echecServeur$ar._(_root);
	@override late final _Traductions$commun$etats$introuvable$ar introuvable = _Traductions$commun$etats$introuvable$ar._(_root);
	@override late final _Traductions$commun$etats$accesRefuse$ar accesRefuse = _Traductions$commun$etats$accesRefuse$ar._(_root);
	@override late final _Traductions$commun$etats$sessionExpiree$ar sessionExpiree = _Traductions$commun$etats$sessionExpiree$ar._(_root);
	@override late final _Traductions$commun$etats$dossierEnAttente$ar dossierEnAttente = _Traductions$commun$etats$dossierEnAttente$ar._(_root);
	@override late final _Traductions$commun$etats$aucunResultat$ar aucunResultat = _Traductions$commun$etats$aucunResultat$ar._(_root);
	@override late final _Traductions$commun$etats$permissionRefusee$ar permissionRefusee = _Traductions$commun$etats$permissionRefusee$ar._(_root);
	@override late final _Traductions$commun$etats$ressourceExpiree$ar ressourceExpiree = _Traductions$commun$etats$ressourceExpiree$ar._(_root);
	@override late final _Traductions$commun$etats$indisponible$ar indisponible = _Traductions$commun$etats$indisponible$ar._(_root);
	@override String get reessaisEpuises => 'لا يزال دون رد. أعد المحاولة لاحقًا.';
	@override String get horsLigneDemarrageTitre => 'تعذّر التحقق من حسابك';
	@override String get horsLigneDemarrage => 'يمكن التحقق منه عند عودة الاتصال. أعد المحاولة حينها.';
	@override late final _Traductions$commun$etats$actions$ar actions = _Traductions$commun$etats$actions$ar._(_root);
}

// Path: accessibilite.tutoiement
class _Traductions$accessibilite$tutoiement$ar extends Traductions$accessibilite$tutoiement$fr {
	_Traductions$accessibilite$tutoiement$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get tonHeure => 'توقيتك';
	@override String get attenteDetail => 'وقت الانتظار هذا لا يُحتسب في حضورك.';
	@override String attente({required Object duree}) => 'أنت في القاعة. تبدأ الحصة بعد ${duree}.';
	@override String get attenteImminent => 'أنت في القاعة. تبدأ الحصة بعد أقل من دقيقة.';
	@override String get annonceAttente => 'أنت في القاعة';
	@override String get horsLigne => 'يمكنك دخول الحصة فور عودة الاتصال.';
	@override String get finPhrase => 'يمكنك العثور على عملك في فصلك.';
}

// Path: classe.entree
class _Traductions$classe$entree$ar extends Traductions$classe$entree$fr {
	_Traductions$classe$entree$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String coursDans({required Object duree}) => 'الدرس بعد ${duree}';
	@override String get coursImminent => 'الدرس بعد أقل من دقيقة';
	@override String get rejoindre => 'انضمام';
	@override String rejoindreLecteur({required Object deClasse}) => 'الانضمام إلى حصة ${deClasse}';
	@override String salleOuverte({required Object duree}) => 'القاعة مفتوحة. تبدأ الحصة بعد ${duree}.';
	@override String get salleOuverteImminent => 'القاعة مفتوحة. تبدأ الحصة بعد أقل من دقيقة.';
	@override String get preparation => 'التحضير جارٍ';
	@override String attente({required Object duree}) => 'أنت في القاعة. تبدأ الحصة بعد ${duree}.';
	@override String get attenteImminent => 'أنت في القاعة. تبدأ الحصة بعد أقل من دقيقة.';
	@override String get enDirect => 'الحصة مباشرة';
	@override String get tempsEcoule => 'انتهى الوقت المقرر';
	@override String get terminee => 'انتهت الحصة';
	@override String get annulee => 'أُلغيت الحصة';
	@override String get aucune => 'لا توجد حصة مقررة';
	@override String get horsLigne => 'أنت غير متصل. تحتاج الحصة إلى اتصال.';
	@override String get indisponible => 'معلومات الحصة غير متاحة حاليًا.';
	@override String get accesInverifiable => 'لا يمكن التحقق من الدخول إلى القاعة حاليًا.';
	@override String get reessayer => 'إعادة المحاولة';
	@override String get chargementSeance => 'جارٍ تحميل الحصة القادمة.';
	@override String progressionValeur({required Object chapitre, required Object pourcentage}) => '${chapitre} · ${pourcentage} %';
	@override String dst({required Object avant, required Object apres}) => 'تغيير التوقيت: سينتقل الدرس من ${avant} إلى ${apres}.';
	@override late final _Traductions$classe$entree$annonce$ar annonce = _Traductions$classe$entree$annonce$ar._(_root);
}

// Path: classe.seance
class _Traductions$classe$seance$ar extends Traductions$classe$seance$fr {
	_Traductions$classe$seance$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aucune => 'لا توجد حصة مجدولة';
	@override String aucuneDetail({required Object dePrenom}) => 'ستظهر هنا الحصة القادمة لـ${dePrenom} بمجرد جدولتها.';
	@override String get illisible => 'تعذّرت قراءة الحصة القادمة.';
	@override String presence({required Object prenom, required Object etat}) => '${prenom}: ${etat}';
}

// Path: classe.observation
class _Traductions$classe$observation$ar extends Traductions$classe$observation$fr {
	_Traductions$classe$observation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get commentCaMarche => 'كيف تعمل؟';
	@override String get uneVisite => 'زيارة واحدة متاحة';
	@override String visites({required Object nombre}) => 'الزيارات المتاحة: ${nombre}';
	@override String resume({required Object visites, required Object duree}) => '${visites} · ${duree} لكل زيارة';
	@override String get restanteAucune => 'لا زيارات متبقية لهذه الحصة';
	@override String get restanteUne => 'زيارة واحدة متبقية لهذه الحصة';
	@override String restantes({required Object nombre}) => 'الزيارات المتبقية لهذه الحصة: ${nombre}';
	@override String minutes({required Object minutes}) => '${minutes} د';
	@override String minutesSecondes({required Object minutes, required Object secondes}) => '${minutes} د ${secondes} ث';
	@override String secondes({required Object secondes}) => '${secondes} ث';
	@override late final _Traductions$classe$observation$motif$ar motif = _Traductions$classe$observation$motif$ar._(_root);
}

// Path: classe.pagePlanning
class _Traductions$classe$pagePlanning$ar extends Traductions$classe$pagePlanning$fr {
	_Traductions$classe$pagePlanning$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get prochaines => 'الحصص القادمة';
	@override String ligne({required Object heure, required Object duree}) => '${heure} · ${duree}';
	@override String ligneFuseau({required Object heure, required Object fuseau, required Object duree}) => '${heure} (${fuseau}) · ${duree}';
	@override String get aucune => 'لا توجد حصص قادمة حاليًا';
	@override String aucuneDetail({required Object dePrenom}) => 'ستظهر هنا الحصص القادمة لـ${dePrenom} بمجرد جدولتها.';
	@override String get habituelIndisponible => 'الأيام المعتادة للفصل لا تظهر هنا بعد: تظهر فقط الحصص المجدولة.';
	@override String get indisponible => 'جدول الفصل غير مربوط بهذه المساحة بعد.';
}

// Path: classe.pageTravail
class _Traductions$classe$pageTravail$ar extends Traductions$classe$pageTravail$fr {
	_Traductions$classe$pageTravail$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aucun => 'لا شيء للتحضير حاليًا';
	@override String get aucunDetail => 'سيظهر هنا العمل الذي يكلّف به المعلم.';
	@override String get indisponible => 'العمل المطلوب تحضيره غير مربوط بهذه المساحة بعد.';
	@override String echeance({required Object date}) => 'الموعد النهائي: ${date}';
	@override String get nonCochable => 'لا يمكن بعد تحديد عمل على أنه منجز من هنا.';
	@override late final _Traductions$classe$pageTravail$statut$ar statut = _Traductions$classe$pageTravail$statut$ar._(_root);
}

// Path: classe.pageRessources
class _Traductions$classe$pageRessources$ar extends Traductions$classe$pageRessources$fr {
	_Traductions$classe$pageRessources$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aucune => 'لا توجد موارد لهذا الفصل حاليًا';
	@override String get aucuneDetail => 'ستظهر هنا المواد التي يختارها المعلم.';
	@override String get indisponible => 'مكتبة الفصل غير مربوطة بهذه المساحة بعد.';
}

// Path: classe.pageProgression
class _Traductions$classe$pageProgression$ar extends Traductions$classe$pageProgression$fr {
	_Traductions$classe$pageProgression$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String indisponible({required Object dePrenom}) => 'تقدم ${dePrenom} غير مُشارك هنا بعد.';
	@override String get niveau => 'المستوى';
	@override String get jalons => 'المراحل المنجزة';
	@override String get aucune => 'لا توجد مراحل مُشاركة حاليًا';
	@override String get aucuneDetail => 'سيظهر هنا التقدم الذي يشاركه المعلم مع الأسرة.';
}

// Path: classe.pageCatalogue
class _Traductions$classe$pageCatalogue$ar extends Traductions$classe$pageCatalogue$fr {
	_Traductions$classe$pageCatalogue$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String pour({required Object prenom}) => 'لـ${prenom}';
	@override String get proposees => 'الفصول المقترحة';
	@override String get indisponible => 'اختيار الفصل عبر الإنترنت غير مفتوح بعد.';
	@override String get aucune => 'لا يوجد فصل مناسب حاليًا';
	@override String aucuneDetail({required Object dePrenom}) => 'لا يوجد فصل مفتوح يناسب ملف ${dePrenom} في الوقت الحالي.';
	@override String get eleveInconnuTitre => 'هذا الملف ليس ضمن أسرتك';
	@override String get eleveInconnuPhrase => 'عد إلى الصفحة الرئيسية واختر ملف الطالب المعني.';
	@override String get horairesAbsents => 'أيام هذا الفصل ومواعيده لا تظهر هنا بعد.';
	@override String seanceHebdo({required Object jour, required Object heure, required Object duree}) => '${jour} الساعة ${heure} · ${duree} د';
	@override String fuseauClasse({required Object fuseau}) => 'مواعيد الفصل (${fuseau})';
	@override String get placeUne => 'مقعد واحد متبقٍّ';
	@override String places({required Object nombre}) => 'المقاعد المتبقية: ${nombre}';
	@override late final _Traductions$classe$pageCatalogue$etat$ar etat = _Traductions$classe$pageCatalogue$etat$ar._(_root);
	@override String get choisir => 'اختيار هذا الفصل';
	@override String get rejoindreAttente => 'الانضمام إلى قائمة الانتظار';
	@override String get precisionsTitre => 'قبل الاختيار';
	@override String get precisionEnseignant => 'يحتفظ الفصل بالمعلم نفسه في كل حصصه.';
	@override String get precisionPlaces => 'المقاعد المعروضة هي مقاعد الأكاديمية لحظة القراءة.';
	@override String get precisionReserve => 'لا يُحجز شيء قبل تأكيدك.';
	@override String get confirmerTitre => 'تأكيد الفصل';
	@override String confirmerPhrase({required Object prenom}) => 'أنت تسجّل ${prenom} في هذا الفصل.';
	@override String confirmerAttentePhrase({required Object prenom}) => 'أنت تسجّل ${prenom} في قائمة انتظار هذا الفصل.';
	@override String memeEnseignant({required Object enseignant}) => 'الفصل نفسه والمعلم نفسه في كل حصص الأسبوع: ${enseignant}.';
	@override String get confirmer => 'تأكيد التسجيل';
	@override String get confirmerAttente => 'تأكيد قائمة الانتظار';
	@override String get envoiIncertain => 'لم يصل رد الأكاديمية. إعادة المحاولة لا تنشئ تسجيلًا ثانيًا.';
	@override String get envoiIndisponible => 'التسجيل عبر الإنترنت غير مفتوح بعد: لم يُحجز أي مقعد.';
	@override late final _Traductions$classe$pageCatalogue$resultat$ar resultat = _Traductions$classe$pageCatalogue$resultat$ar._(_root);
}

// Path: classe.cartes
class _Traductions$classe$cartes$ar extends Traductions$classe$cartes$fr {
	_Traductions$classe$cartes$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'بطاقات الفصل';
	@override String get contexteEnseignant => 'المس بطاقة لتعديلها. يراها الطلاب وأسرهم فورًا.';
	@override String get modificationPlusTard => 'يمكن تعديل البطاقات عند عودة الاتصال.';
	@override String get aucune => 'لا توجد بطاقات حاليًا';
	@override String get aucuneDetail => 'سيضع معلم الفصل هنا المعلومات المفيدة.';
	@override String get aucuneEnseignant => 'لا توجد بطاقات حاليًا. أضف بطاقة: سيراها الفصل فورًا.';
	@override String get ajouter => 'إضافة بطاقة';
	@override String limite({required Object max}) => '${max} بطاقات على الأكثر: احذف واحدة لتضيف أخرى.';
	@override String modifierLecteur({required Object titre}) => 'تعديل البطاقة «${titre}»';
	@override String echeance({required Object date}) => 'الموعد النهائي: ${date}';
	@override String copierLien({required Object titre}) => 'نسخ رابط «${titre}»';
	@override String get copierLienCourt => 'نسخ الرابط';
	@override String get lienCopie => 'تم نسخ الرابط. الصقه في متصفحك لفتحه.';
	@override String get indisponibleTitre => 'بطاقات الفصل غير مفتوحة بعد';
	@override String get indisponiblePhrase => 'ستظهر هنا فور فتحها. لا شيء مطلوب منك.';
	@override String get erreurLecture => 'تعذرت قراءة بطاقات الفصل. أعد المحاولة بعد قليل.';
	@override String get sansDonnees => 'تعذر تحميل بطاقات الفصل';
	@override String get enregistree => 'تم حفظ البطاقة. يراها الفصل الآن.';
	@override String get retiree => 'تم حذف البطاقة. لم يعد الفصل يراها.';
	@override late final _Traductions$classe$cartes$types$ar types = _Traductions$classe$cartes$types$ar._(_root);
	@override late final _Traductions$classe$cartes$typesDetail$ar typesDetail = _Traductions$classe$cartes$typesDetail$ar._(_root);
	@override late final _Traductions$classe$cartes$modeles$ar modeles = _Traductions$classe$cartes$modeles$ar._(_root);
	@override late final _Traductions$classe$cartes$feuille$ar feuille = _Traductions$classe$cartes$feuille$ar._(_root);
}

// Path: salle.secours
class _Traductions$salle$secours$ar extends Traductions$salle$secours$fr {
	_Traductions$salle$secours$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get reseauFaible => 'الشبكة ضعيفة. الأولوية للصوت.';
	@override String get reseauFaibleGuidee => 'الشبكة ضعيفة.';
	@override String get reseauFaibleGuideeSuite => 'الصوت يبقى أولوية.';
	@override String get reconnexion => 'انقطع الاتصال. جارٍ إعادة الاتصال…';
	@override String get reconnexionGuidee => 'جارٍ إعادة الاتصال بالحصة…';
	@override String get retablie => 'عاد الاتصال.';
	@override String get echec => 'تعذّرت إعادة الاتصال.';
	@override String get echecGuidee => 'الاتصال لا يعود.';
	@override String get horsLigne => 'أنت غير متصل. تحتاج الحصة إلى اتصال.';
	@override String get reessayer => 'إعادة المحاولة';
	@override String get quitter => 'خروج';
	@override String indisponible({required Object commande}) => '${commande}. غير متاح أثناء إعادة الاتصال.';
	@override String get cameraInterdite => 'الكاميرا معطّلة لهذا الملف.';
	@override String get microBloque => 'الميكروفون محظور في إعدادات هذا الجهاز.';
	@override String get microBloqueGuidee => 'الميكروفون محظور على هذا الجهاز.';
	@override String get continuerSansMicro => 'المتابعة دون ميكروفون';
	@override String get ouvrirReglages => 'فتح الإعدادات';
}

// Path: eleve.accueil
class _Traductions$eleve$accueil$ar extends Traductions$eleve$accueil$fr {
	_Traductions$eleve$accueil$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get entreeSePrepare => 'دخولك قيد التحضير. أعد المحاولة بعد لحظة.';
}

// Path: eleve.suivi
class _Traductions$eleve$suivi$ar extends Traductions$eleve$suivi$fr {
	_Traductions$eleve$suivi$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'متابعة دروسي';
	@override String get colonneDate => 'التاريخ';
	@override String get colonneCours => 'الدرس';
	@override String get colonneEnseignant => 'المعلم';
	@override String get colonneEtat => 'الحضور';
	@override String get cours => 'درس القرآن';
	@override String get moi => 'حضوري';
	@override String aujourdhui({required Object heure}) => 'اليوم، ${heure}';
	@override String hier({required Object heure}) => 'أمس، ${heure}';
	@override String date({required Object date, required Object heure}) => '${date}، ${heure}';
	@override String get annule => 'درس ملغى';
	@override String get nonTenu => 'درس لم يُعقد';
	@override String get vide => 'لا توجد دروس حتى الآن';
	@override String get videDetail => 'ستظهر دروسك هنا من الأحدث إلى الأقدم مع حالة حضورك.';
	@override String get erreur => 'تعذرت قراءة المتابعة. حاول مرة أخرى بعد قليل.';
	@override String tronquee({required Object nombre}) => 'تظهر أحدث ${nombre} دروس.';
	@override String fin({required Object nombre}) => 'عدد الدروس في المتابعة: ${nombre}.';
	@override String get finUn => 'درس واحد في المتابعة.';
}

// Path: enseignant.journee
class _Traductions$enseignant$journee$ar extends Traductions$enseignant$journee$fr {
	_Traductions$enseignant$journee$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get derniereSeance => 'آخر حصة';
	@override String get rejoindreSalle => 'الدخول إلى القاعة';
	@override String rejoindreSalleLecteur({required Object classe}) => 'الدخول إلى قاعة الفصل ${classe}';
	@override String get remplirCahier => 'تعبئة دفتر المتابعة';
	@override String remplirCahierLecteur({required Object classe}) => 'تعبئة دفتر المتابعة للفصل ${classe}';
	@override String cahierObligatoire({required Object classe}) => 'إلزامي: يُعبَّأ دفتر ${classe} في نهاية كل حصة.';
	@override String voirCahier({required Object classe}) => 'عرض دفتر ${classe}';
	@override String voirCahierLecteur({required Object classe}) => 'عرض دفتر المتابعة للفصل ${classe}';
}

// Path: enseignant.ficheGroupe
class _Traductions$enseignant$ficheGroupe$ar extends Traductions$enseignant$ficheGroupe$fr {
	_Traductions$enseignant$ficheGroupe$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get elevesTitre => 'الطلاب';
	@override String get preparationTitre => 'للتحضير';
	@override String get supportPrevu => 'المادة المقررة';
	@override String get positionReprise => 'موضع الاستئناف';
	@override String get objectif => 'الهدف';
	@override String get preparationVide => 'لم يُسجَّل أي تحضير لهذه الحصة.';
	@override String get supportsTitre => 'أحدث المواد';
	@override String repriseEleve({required Object page}) => 'الاستئناف: ${page}';
	@override String dernierPoint({required Object texte}) => 'آخر ملاحظة: ${texte}';
	@override String get chargementClasse => 'جارٍ تحميل الفصل.';
}

// Path: tuteur.accueil
class _Traductions$tuteur$accueil$ar extends Traductions$tuteur$accueil$fr {
	_Traductions$tuteur$accueil$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get prochaineSeance => 'الحصة القادمة';
	@override String heureDe({required Object deVille}) => 'توقيت ${deVille}';
	@override String get heureAppareil => 'توقيت هذا الجهاز';
	@override String heureClasse({required Object heure, required Object ville}) => 'توقيت الفصل: ${heure} ${ville}';
	@override String get seanceEnDirect => 'الحصة مباشرة';
	@override String get seanceTerminee => 'انتهت الحصة';
	@override String get seanceAnnulee => 'لن تُعقد هذه الحصة.';
	@override String get seanceNonTenue => 'تعذّر عقد هذه الحصة.';
	@override String get horaireIncertain => 'لم يُؤكَّد فتح القاعة بعد';
	@override String get pastilleAnnulee => 'ملغاة';
	@override String get pastilleNonTenue => 'لم تُعقد';
	@override String get pastilleTerminee => 'منتهية';
	@override late final _Traductions$tuteur$accueil$etatCourt$ar etatCourt = _Traductions$tuteur$accueil$etatCourt$ar._(_root);
	@override String get motifAnnuleeTard => 'أُلغيت الحصة قبل موعدها بقليل';
}

// Path: nav.eleve
class _Traductions$nav$eleve$ar extends Traductions$nav$eleve$fr {
	_Traductions$nav$eleve$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get accueil => 'الرئيسية';
	@override String get maClasse => 'فصلي';
	@override String get coran => 'القرآن';
	@override String get monEspace => 'مساحتي';
	@override String get suivi => 'المتابعة';
	@override String get compte => 'الحساب';
}

// Path: nav.tuteur
class _Traductions$nav$tuteur$ar extends Traductions$nav$tuteur$fr {
	_Traductions$nav$tuteur$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get accueil => 'الرئيسية';
	@override String get foyer => 'الأسرة';
	@override String get disponibilites => 'الأوقات المتاحة';
	@override String get reglages => 'الإعدادات';
	@override String get suivi => 'المتابعة';
	@override String get historique => 'السجل';
	@override String get compte => 'الحساب';
}

// Path: nav.enseignant
class _Traductions$nav$enseignant$ar extends Traductions$nav$enseignant$fr {
	_Traductions$nav$enseignant$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get journee => 'اليوم';
	@override String get classes => 'الفصول';
	@override String get creneaux => 'الأوقات المتاحة';
	@override String get profil => 'الملف الشخصي';
}

// Path: nav.controleur
class _Traductions$nav$controleur$ar extends Traductions$nav$controleur$fr {
	_Traductions$nav$controleur$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get planning => 'الجدول';
	@override String get controle => 'المراقبة';
	@override String get historique => 'السجل';
	@override String get echanges => 'المراسلات';
	@override String get compte => 'الحساب';
}

// Path: nav.admin
class _Traductions$nav$admin$ar extends Traductions$nav$admin$fr {
	_Traductions$nav$admin$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get tableauDeBord => 'لوحة التحكم';
	@override String get dossiers => 'الملفات';
	@override String get demandes => 'الطلبات';
	@override String get attribution => 'الإسناد';
	@override String get journal => 'السجل';
	@override String get comptes => 'الحسابات';
	@override String get accesAgents => 'صلاحيات الموظفين';
	@override String get accueil => 'الرئيسية';
	@override String get operations => 'العمليات';
	@override String get personnes => 'الأشخاص';
	@override String get pedagogie => 'التعليم';
	@override String get finance => 'المالية';
	@override String get configuration => 'الإعدادات';
	@override String get securite => 'الأمان والتدقيق';
	@override String get direction => 'الإدارة';
	@override String get recherche => 'البحث';
	@override String get rechercheIndication => 'البحث عن شاشة';
	@override String get notificationsTitre => 'الإشعارات';
	@override String get menu => 'القائمة';
}

// Path: tc.groupe
class _Traductions$tc$groupe$ar extends Traductions$tc$groupe$fr {
	_Traductions$tc$groupe$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tc$groupe$mesGroupes$ar mesGroupes = _Traductions$tc$groupe$mesGroupes$ar._(_root);
	@override late final _Traductions$tc$groupe$commun$ar commun = _Traductions$tc$groupe$commun$ar._(_root);
	@override late final _Traductions$tc$groupe$carte$ar carte = _Traductions$tc$groupe$carte$ar._(_root);
	@override late final _Traductions$tc$groupe$enseignant$ar enseignant = _Traductions$tc$groupe$enseignant$ar._(_root);
	@override late final _Traductions$tc$groupe$cours$ar cours = _Traductions$tc$groupe$cours$ar._(_root);
	@override late final _Traductions$tc$groupe$temps$ar temps = _Traductions$tc$groupe$temps$ar._(_root);
	@override late final _Traductions$tc$groupe$duree$ar duree = _Traductions$tc$groupe$duree$ar._(_root);
	@override late final _Traductions$tc$groupe$horloges$ar horloges = _Traductions$tc$groupe$horloges$ar._(_root);
	@override late final _Traductions$tc$groupe$dst$ar dst = _Traductions$tc$groupe$dst$ar._(_root);
	@override late final _Traductions$tc$groupe$session$ar session = _Traductions$tc$groupe$session$ar._(_root);
	@override late final _Traductions$tc$groupe$espace$ar espace = _Traductions$tc$groupe$espace$ar._(_root);
	@override late final _Traductions$tc$groupe$emplacement$ar emplacement = _Traductions$tc$groupe$emplacement$ar._(_root);
}

// Path: tc.bibliotheque
class _Traductions$tc$bibliotheque$ar extends Traductions$tc$bibliotheque$fr {
	_Traductions$tc$bibliotheque$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tc$bibliotheque$sections$ar sections = _Traductions$tc$bibliotheque$sections$ar._(_root);
}

// Path: com.socle
class _Traductions$com$socle$ar extends Traductions$com$socle$fr {
	_Traductions$com$socle$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$com$socle$composants$ar composants = _Traductions$com$socle$composants$ar._(_root);
	@override late final _Traductions$com$socle$lexique$ar lexique = _Traductions$com$socle$lexique$ar._(_root);
	@override late final _Traductions$com$socle$motifs$ar motifs = _Traductions$com$socle$motifs$ar._(_root);
	@override late final _Traductions$com$socle$signalement$ar signalement = _Traductions$com$socle$signalement$ar._(_root);
	@override late final _Traductions$com$socle$enregistrement$ar enregistrement = _Traductions$com$socle$enregistrement$ar._(_root);
	@override late final _Traductions$com$socle$navigation$ar navigation = _Traductions$com$socle$navigation$ar._(_root);
}

// Path: com.messages
class _Traductions$com$messages$ar extends Traductions$com$messages$fr {
	_Traductions$com$messages$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$com$messages$entree$ar entree = _Traductions$com$messages$entree$ar._(_root);
	@override String get videDetail => 'تُفتح المحادثة من فصل أو طالب أو ملف.';
	@override String get choisirTitre => 'اختر محادثة';
	@override String get choisir => 'اختر محادثة من القائمة لقراءتها والرد عليها.';
	@override late final _Traductions$com$messages$recherche$ar recherche = _Traductions$com$messages$recherche$ar._(_root);
	@override late final _Traductions$com$messages$ligne$ar ligne = _Traductions$com$messages$ligne$ar._(_root);
	@override late final _Traductions$com$messages$noms$ar noms = _Traductions$com$messages$noms$ar._(_root);
	@override late final _Traductions$com$messages$entete$ar entete = _Traductions$com$messages$entete$ar._(_root);
	@override late final _Traductions$com$messages$types$ar types = _Traductions$com$messages$types$ar._(_root);
	@override late final _Traductions$com$messages$panneau$ar panneau = _Traductions$com$messages$panneau$ar._(_root);
	@override late final _Traductions$com$messages$fil$ar fil = _Traductions$com$messages$fil$ar._(_root);
	@override late final _Traductions$com$messages$demo$ar demo = _Traductions$com$messages$demo$ar._(_root);
	@override String get titre => _root.com.socle.lexique.messagesMetier;
	@override String get vide => 'لا توجد محادثات حاليًا.';
}

// Path: com.vocal
class _Traductions$com$vocal$ar extends Traductions$com$vocal$fr {
	_Traductions$com$vocal$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$com$vocal$composer$ar composer = _Traductions$com$vocal$composer$ar._(_root);
	@override late final _Traductions$com$vocal$lecteur$ar lecteur = _Traductions$com$vocal$lecteur$ar._(_root);
	@override late final _Traductions$com$vocal$demo$ar demo = _Traductions$com$vocal$demo$ar._(_root);
	@override String get titre => 'رسالة صوتية';
}

// Path: com.communaute
class _Traductions$com$communaute$ar extends Traductions$com$communaute$fr {
	_Traductions$com$communaute$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$com$communaute$garde$ar garde = _Traductions$com$communaute$garde$ar._(_root);
	@override late final _Traductions$com$communaute$lien$ar lien = _Traductions$com$communaute$lien$ar._(_root);
	@override String get sousTitre => 'تبادل وتعاون بين المعلّمين';
	@override String get sections => 'فئات مجتمع المعلّمين';
	@override String get toutes => 'الكل';
	@override String get videTitre => 'لا توجد منشورات';
	@override String get rechercheVideTitre => 'لا توجد نتائج';
	@override String get rechercheVide => 'لا يوجد منشور يطابق بحثك. جرّب كلمة أخرى.';
	@override String get videToutes => 'لا توجد منشورات حاليًا.';
	@override late final _Traductions$com$communaute$flux$ar flux = _Traductions$com$communaute$flux$ar._(_root);
	@override late final _Traductions$com$communaute$recherche$ar recherche = _Traductions$com$communaute$recherche$ar._(_root);
	@override late final _Traductions$com$communaute$moment$ar moment = _Traductions$com$communaute$moment$ar._(_root);
	@override late final _Traductions$com$communaute$publication$ar publication = _Traductions$com$communaute$publication$ar._(_root);
	@override late final _Traductions$com$communaute$reponses$ar reponses = _Traductions$com$communaute$reponses$ar._(_root);
	@override late final _Traductions$com$communaute$signalement$ar signalement = _Traductions$com$communaute$signalement$ar._(_root);
	@override late final _Traductions$com$communaute$composer$ar composer = _Traductions$com$communaute$composer$ar._(_root);
	@override late final _Traductions$com$communaute$regles$ar regles = _Traductions$com$communaute$regles$ar._(_root);
	@override late final _Traductions$com$communaute$entree$ar entree = _Traductions$com$communaute$entree$ar._(_root);
	@override late final _Traductions$com$communaute$demo$ar demo = _Traductions$com$communaute$demo$ar._(_root);
	@override String get titre => _root.com.socle.lexique.communaute;
	@override String get vide => 'لا توجد منشورات في هذه الفئة.';
}

// Path: com.studio
class _Traductions$com$studio$ar extends Traductions$com$studio$fr {
	_Traductions$com$studio$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$com$studio$focus$ar focus = _Traductions$com$studio$focus$ar._(_root);
	@override late final _Traductions$com$studio$aujourdhui$ar aujourdhui = _Traductions$com$studio$aujourdhui$ar._(_root);
	@override late final _Traductions$com$studio$brouillons$ar brouillons = _Traductions$com$studio$brouillons$ar._(_root);
	@override String get sousTitre => 'مساحة عمل الفريق';
	@override late final _Traductions$com$studio$navigation$ar navigation = _Traductions$com$studio$navigation$ar._(_root);
	@override String get choisirTitre => 'اختر قناة';
	@override String get choisir => 'اختر قناة من القائمة لقراءة النقاش والكتابة فيه.';
	@override String get aucunCanalTitre => 'لا توجد قنوات حاليًا';
	@override String get aucunCanal => 'ستظهر هنا القنوات المفتوحة لك.';
	@override late final _Traductions$com$studio$sections$ar sections = _Traductions$com$studio$sections$ar._(_root);
	@override late final _Traductions$com$studio$visibilite$ar visibilite = _Traductions$com$studio$visibilite$ar._(_root);
	@override late final _Traductions$com$studio$canal$ar canal = _Traductions$com$studio$canal$ar._(_root);
	@override late final _Traductions$com$studio$panneau$ar panneau = _Traductions$com$studio$panneau$ar._(_root);
	@override late final _Traductions$com$studio$enregistrer$ar enregistrer = _Traductions$com$studio$enregistrer$ar._(_root);
	@override late final _Traductions$com$studio$enregistres$ar enregistres = _Traductions$com$studio$enregistres$ar._(_root);
	@override late final _Traductions$com$studio$recherche$ar recherche = _Traductions$com$studio$recherche$ar._(_root);
	@override late final _Traductions$com$studio$demo$ar demo = _Traductions$com$studio$demo$ar._(_root);
	@override String get titre => _root.com.socle.lexique.studio;
	@override String get vide => 'لا يوجد نشاط للمعالجة هنا.';
}

// Path: com.annonces
class _Traductions$com$annonces$ar extends Traductions$com$annonces$fr {
	_Traductions$com$annonces$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$com$annonces$publieur$ar publieur = _Traductions$com$annonces$publieur$ar._(_root);
	@override late final _Traductions$com$annonces$administration$ar administration = _Traductions$com$annonces$administration$ar._(_root);
	@override late final _Traductions$com$annonces$demoPublication$ar demoPublication = _Traductions$com$annonces$demoPublication$ar._(_root);
	@override String get section => 'إعلانات الفصل';
	@override String get annonce => 'إعلان';
	@override String get publier => 'نشر إعلان';
	@override String get videPublier => 'لا توجد إعلانات لهذا الفصل. انشر أول إعلان للفصل كله.';
	@override String auteurDate({required Object auteur, required Object date, required Object heure}) => '${auteur}‏، يوم ${date} الساعة ${heure}';
	@override String date({required Object date, required Object heure}) => 'يوم ${date} الساعة ${heure}';
	@override String get lire => 'قراءة الإعلان كاملًا';
	@override String get ouvrirClasse => 'فتح الفصل';
	@override String ouvrirClasseSemantique({required Object classe}) => 'فتح ${classe}';
	@override String get marquerLue => 'تحديد كمقروء';
	@override String get lue => 'مقروء';
	@override String carteSemantique({required Object classe, required Object titre}) => 'إعلان ${classe}: ${titre}';
	@override String get introuvableTitre => 'هذا الإعلان لم يعد متاحًا';
	@override String get introuvablePhrase => 'ربما سُحب من الفصل. عد إلى إشعاراتك.';
	@override late final _Traductions$com$annonces$demo$ar demo = _Traductions$com$annonces$demo$ar._(_root);
	@override String get titre => 'الإعلانات';
}

// Path: admin.evaluations
class _Traductions$admin$evaluations$ar extends Traductions$admin$evaluations$fr {
	_Traductions$admin$evaluations$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get manqueResultat => 'اختر أولًا نتيجة التقييم.';
}

// Path: admin.programmes
class _Traductions$admin$programmes$ar extends Traductions$admin$programmes$fr {
	_Traductions$admin$programmes$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get publierSansNiveau => 'أضف مستوى واحدًا على الأقل لتتمكن من نشر هذه النسخة.';
}

// Path: admin.finance
class _Traductions$admin$finance$ar extends Traductions$admin$finance$fr {
	_Traductions$admin$finance$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aValider => 'للمصادقة';
}

// Path: comptable.nav
class _Traductions$comptable$nav$ar extends Traductions$comptable$nav$fr {
	_Traductions$comptable$nav$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aujourdhui => 'اليوم';
	@override String get paiements => 'المدفوعات';
	@override String get tresorerie => 'الخزينة';
	@override String get compte => 'الحساب';
}

// Path: comptable.onglets
class _Traductions$comptable$onglets$ar extends Traductions$comptable$onglets$fr {
	_Traductions$comptable$onglets$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aEffectuer => 'للتنفيذ';
	@override String get contractuels => 'المتعاقدون';
	@override String get beneficiaires => 'المستفيدون';
	@override String get coffres => 'الصناديق';
	@override String get encaissements => 'المقبوضات';
	@override String get rapprochement => 'المطابقة';
}

// Path: comptable.commun
class _Traductions$comptable$commun$ar extends Traductions$comptable$commun$fr {
	_Traductions$comptable$commun$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get montantMasque => 'مبلغ مخفي';
	@override String get afficherMontants => 'إظهار المبالغ';
	@override String get masquerMontants => 'إخفاء المبالغ';
	@override String get montantsMasques => 'المبالغ مخفية';
	@override String get montantsAffiches => 'المبالغ ظاهرة';
	@override String get enPreparationTitre => 'هذه الشاشة قيد الإعداد.';
	@override String get enPreparationPhrase => 'لا يُعرض هنا أي رقم في الوقت الحالي. لا يمكن تنفيذ أي دفعة من هذه الشاشة.';
	@override String get reserveStrategique => 'الاحتياطي الاستراتيجي';
	@override String get tresorerieLibre => 'الخزينة الحرة';
	@override String get tresorerieDetenue => 'الخزينة المحتفَظ بها';
	@override String get fondsProteges => 'الأموال المحمية';
	@override String get enTransit => 'قيد التحويل';
	@override String get tresorerieLibreDetail => 'ما يبقى متاحًا فعلًا بعد الأموال المحمية والالتزامات والمبالغ قيد التحويل.';
	@override String get objectifFixe => 'الهدف: مبلغ ثابت';
	@override String objectifMois({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		one: 'الهدف الحالي: شهر واحد من المصاريف الأساسية',
		two: 'الهدف الحالي: شهران من المصاريف الأساسية',
		few: 'الهدف الحالي: ${n} أشهر من المصاريف الأساسية',
		many: 'الهدف الحالي: ${n} شهرًا من المصاريف الأساسية',
		other: 'الهدف الحالي: ${n} شهر من المصاريف الأساسية',
	);
	@override String get montantActuel => 'المبلغ الحالي';
	@override String get manque => 'المتبقي لبلوغ الهدف';
	@override String atteint({required Object pourcent}) => 'تحقق ${pourcent} %';
	@override String get modeCalcul => 'طريقة الحساب';
	@override String get modeMontantFixe => 'مبلغ مستهدف ثابت';
	@override String get modeCouvertureMois => 'تغطية بعدد أشهر المصاريف الأساسية';
	@override String derniereAllocation({required Object date}) => 'آخر تخصيص: ${date}';
	@override String prochaineAllocation({required Object date}) => 'التخصيص القادم المقرر: ${date}';
	@override String get aucuneAllocation => 'لا يوجد أي تخصيص مسجل';
	@override String get destination => 'الوجهة';
	@override String destinationMasquee({required Object type, required Object suffixe}) => '${type} •••• ${suffixe}';
	@override String destinationMasqueeLecteur({required Object type, required Object suffixe}) => '${type}، الرقم مخفي، ينتهي بـ ${suffixe}';
	@override String get destinationAucune => 'لا توجد وسيلة دفع';
	@override String paysDevise({required Object pays, required Object devise}) => '${pays} · ${devise}';
	@override String get verification => 'التحقق';
	@override String activiteInitiateurDate({required Object initiateur, required Object date}) => '${initiateur} · ${date}';
	@override String activiteTransition({required Object avant, required Object apres}) => '${avant} ← ${apres}';
	@override String activiteReference({required Object reference}) => 'المرجع ${reference}';
	@override String get relancePreparee => 'تذكير جاهز (عرض توضيحي)';
	@override String prestataireDemonstration({required Object nom}) => '${nom} (عرض توضيحي)';
	@override String date({required Object jour, required Object mois, required Object annee}) => '${jour} ${mois} ${annee}';
	@override String get aucuneValeur => 'غير محدد';
}

// Path: comptable.coffres
class _Traductions$comptable$coffres$ar extends Traductions$comptable$coffres$fr {
	_Traductions$comptable$coffres$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get fondsClientsEngages => 'أموال العملاء الملتزَم بها';
	@override String get paieADecaisser => 'رواتب مستحقة الصرف';
	@override String get chargesEssentielles => 'المصاريف الأساسية';
	@override String get taxesObligations => 'الضرائب والالتزامات';
	@override String get reserveStrategique => 'الاحتياطي الاستراتيجي';
	@override String get enTransit => 'قيد التحويل';
	@override String get tresorerieLibre => 'الخزينة الحرة';
}

// Path: comptable.statuts
class _Traductions$comptable$statuts$ar extends Traductions$comptable$statuts$fr {
	_Traductions$comptable$statuts$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$comptable$statuts$paiement$ar paiement = _Traductions$comptable$statuts$paiement$ar._(_root);
	@override late final _Traductions$comptable$statuts$encaissement$ar encaissement = _Traductions$comptable$statuts$encaissement$ar._(_root);
	@override late final _Traductions$comptable$statuts$rapprochement$ar rapprochement = _Traductions$comptable$statuts$rapprochement$ar._(_root);
	@override late final _Traductions$comptable$statuts$profil$ar profil = _Traductions$comptable$statuts$profil$ar._(_root);
	@override late final _Traductions$comptable$statuts$capacite$ar capacite = _Traductions$comptable$statuts$capacite$ar._(_root);
	@override late final _Traductions$comptable$statuts$reserve$ar reserve = _Traductions$comptable$statuts$reserve$ar._(_root);
	@override late final _Traductions$comptable$statuts$obligation$ar obligation = _Traductions$comptable$statuts$obligation$ar._(_root);
	@override late final _Traductions$comptable$statuts$remboursement$ar remboursement = _Traductions$comptable$statuts$remboursement$ar._(_root);
	@override late final _Traductions$comptable$statuts$validation$ar validation = _Traductions$comptable$statuts$validation$ar._(_root);
	@override late final _Traductions$comptable$statuts$raison$ar raison = _Traductions$comptable$statuts$raison$ar._(_root);
}

// Path: comptable.alertes
class _Traductions$comptable$alertes$ar extends Traductions$comptable$alertes$fr {
	_Traductions$comptable$alertes$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get enseignantsAPayer => 'معلمون للدفع';
	@override String get contractuelsAEcheance => 'متعاقدون حان موعد استحقاقهم';
	@override String get infosManquantes => 'معلومات الدفع ناقصة';
	@override String get payoutEchoue => 'فشل صرف دفعة';
	@override String get paiementFamilleEchoue => 'فشل دفع أسرة';
	@override String get transactionNonRapprochee => 'معاملة غير مطابَقة';
	@override String get remboursementEnAttente => 'استرداد قيد الانتظار';
	@override String get reserveSousObjectif => 'الاحتياطي الاستراتيجي دون الهدف';
	@override String get soldePrestataireInsuffisant => 'رصيد مزوّد الدفع غير كافٍ';
	@override String get methodeModifieeRecemment => 'وسيلة دفع عُدّلت مؤخرًا';
	@override String get doublonPotentiel => 'تكرار محتمل';
	@override String get validationRequise => 'تلزم مصادقة إضافية';
}

// Path: comptable.aujourdhui
class _Traductions$comptable$aujourdhui$ar extends Traductions$comptable$aujourdhui$fr {
	_Traductions$comptable$aujourdhui$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get attentionSousTitre => 'ما ينتظر إجراءً منك، ثم المخاطر التي تجب مراقبتها.';
	@override String elementCompteur({required Object libelle, required Object n}) => '${libelle}: ${n}';
	@override String elementDepuis({required Object date}) => 'قيد الانتظار منذ ${date}';
	@override String get aTraiterVide => 'لا شيء للمعالجة اليوم.';
	@override String get aTraiterVideDetail => 'ستظهر هنا المدفوعات والتذكيرات والمطابقات المطلوبة.';
	@override String get alertesVide => 'لا توجد تنبيهات حاليًا.';
	@override String alertesResume({required Object n}) => 'تنبيهات للمراقبة: ${n}';
	@override String get paiementsAEffectuer => 'مدفوعات للتنفيذ';
	@override String get paiementsAEffectuerDetail => 'تُراجَع كل دفعة في قائمتها قبل دفعها.';
	@override String get paiementsVide => 'لا توجد مدفوعات للتنفيذ.';
	@override String get echeancesVide => 'لا توجد مواعيد استحقاق قريبة.';
	@override String get encaissementsVide => 'لا توجد مقبوضات حديثة.';
	@override String get activiteVide => 'لا يوجد نشاط حديث.';
	@override String get prestatairesVide => 'لا يوجد مزوّد دفع مفعّل.';
	@override String get prestatairesVideDetail => 'ستنطلق المدفوعات الصادرة عندما تفعّل الإدارة مزوّد دفع.';
	@override String get accesPaiements => 'عرض المدفوعات للتنفيذ';
	@override String get accesContractuels => 'إدارة التزامات المتعاقدين';
	@override String get accesEncaissements => 'عرض المقبوضات';
	@override String get accesTresorerie => 'عرض الخزينة والصناديق';
	@override String get accesAlimenter => 'تغذية الاحتياطي الاستراتيجي';
	@override String get titre => 'اليوم';
	@override String get sousTitre => 'ماذا عليّ أن أفعل الآن؟';
	@override String get attention => 'للمعالجة والتنبيهات';
	@override String get aTraiter => 'للمعالجة اليوم';
	@override String get aTraiterHorsPaiements => 'مهام أخرى';
	@override String get alertes => 'التنبيهات';
	@override String get echeances => 'مواعيد استحقاق قريبة';
	@override String get prestataires => 'مزوّدو الدفع';
	@override String get activiteRecente => 'النشاط الحديث';
	@override String get accesRapides => 'وصول سريع';
	@override String get encaissementsRecents => 'المقبوضات الحديثة';
	@override String get voirTout => 'عرض الكل';
}

// Path: comptable.paiements
class _Traductions$comptable$paiements$ar extends Traductions$comptable$paiements$fr {
	_Traductions$comptable$paiements$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$comptable$paiements$confirmation$ar confirmation = _Traductions$comptable$paiements$confirmation$ar._(_root);
	@override late final _Traductions$comptable$paiements$filtres$ar filtres = _Traductions$comptable$paiements$filtres$ar._(_root);
	@override late final _Traductions$comptable$paiements$colonnes$ar colonnes = _Traductions$comptable$paiements$colonnes$ar._(_root);
	@override late final _Traductions$comptable$paiements$types$ar types = _Traductions$comptable$paiements$types$ar._(_root);
	@override String compteur({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		one: 'دفعة واحدة',
		two: 'دفعتان',
		few: '${n} دفعات',
		other: '${n} دفعة',
	);
	@override late final _Traductions$comptable$paiements$actions$ar actions = _Traductions$comptable$paiements$actions$ar._(_root);
	@override String selection({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		one: 'دفعة واحدة محددة',
		two: 'دفعتان محددتان',
		few: '${n} دفعات محددة',
		other: '${n} دفعة محددة',
	);
	@override String get selectionPhrase => 'يُرجع الفحص الإجمالي والاستبعادات قبل أي إرسال.';
	@override String get horsLigneCourt => 'غير متصل: الدفع غير ممكن';
	@override late final _Traductions$comptable$paiements$vide$ar vide = _Traductions$comptable$paiements$vide$ar._(_root);
	@override String get horsLigne => 'غير متصل: لا تُرسَل أي دفعة دون شبكة. أعد الاتصال لتدفع.';
	@override late final _Traductions$comptable$paiements$detail$ar detail = _Traductions$comptable$paiements$detail$ar._(_root);
	@override late final _Traductions$comptable$paiements$ecart$ar ecart = _Traductions$comptable$paiements$ecart$ar._(_root);
	@override String get titre => 'مدفوعات للتنفيذ';
	@override String get sousTitre => 'مبالغ محسوبة في المصدر: هنا نراجع وندفع، ولا نعدّل شيئًا.';
	@override String get detailTitre => 'تفاصيل الدفعة';
	@override String get detailSousTitre => 'لكل سطر مصدره. يُبلَّغ عن الفرق ولا يُصحَّح هنا.';
}

// Path: comptable.tresorerie
class _Traductions$comptable$tresorerie$ar extends Traductions$comptable$tresorerie$fr {
	_Traductions$comptable$tresorerie$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get coffresTitre => 'الصناديق';
	@override String get coffresPhrase => 'حيث يُخصَّص المال. المبلغ المحمي لا يُحسب أبدًا ضمن الحر.';
	@override String get coffreProtege => 'محمي';
	@override String get coffreNonProtege => 'غير محمي';
	@override String partDetenue({required Object part}) => '${part} % من الخزينة المحتفَظ بها';
	@override String regleUsage({required Object regle}) => 'قاعدة الاستخدام: ${regle}';
	@override String get coffresVide => 'لم يُرجَع أي صندوق بعد.';
	@override String get coffresVidePhrase => 'ستظهر الصناديق السبعة هنا بمجرد أن يُرجعها المصدر.';
	@override late final _Traductions$comptable$tresorerie$descriptions$ar descriptions = _Traductions$comptable$tresorerie$descriptions$ar._(_root);
	@override String get politiqueTitre => 'سياسة الاحتياطي الاستراتيجي';
	@override String get politiquePhrase => 'تحددها الإدارة. أنت تطبّقها ولا تعدّلها.';
	@override String get alimentationAuto => 'التغذية التلقائية';
	@override late final _Traductions$comptable$tresorerie$regle$ar regle = _Traductions$comptable$tresorerie$regle$ar._(_root);
	@override String get cadence => 'الوتيرة';
	@override late final _Traductions$comptable$tresorerie$cadences$ar cadences = _Traductions$comptable$tresorerie$cadences$ar._(_root);
	@override String seuilAlerte({required Object pourcent}) => 'تنبيه دون ${pourcent} % من المبلغ المستهدف';
	@override String get retraitValidation => 'كل سحب يتطلب مصادقة إضافية.';
	@override String get retraitSansValidation => 'لا تشترط السياسة مصادقة للسحب؛ ويبقى معامَلًا كحركة حساسة.';
	@override String version({required Object version}) => 'الإصدار ${version}';
	@override String versionDepuis({required Object version, required Object date}) => 'الإصدار ${version}، ساري المفعول منذ ${date}';
	@override String get mouvementsTitre => 'الحركات بين الصناديق';
	@override String get mouvementsPhrase => 'نحو الحماية: حسب تفويضك. الخروج من صندوق محمي: تلزم مصادقة إضافية.';
	@override String get preparerMouvement => 'إعداد حركة';
	@override String get retirer => 'السحب من الاحتياطي الاستراتيجي';
	@override String retraitBloque({required Object raison}) => 'السحب من الاحتياطي الاستراتيجي: ${raison}.';
	@override String alimenterBloque({required Object raison}) => 'تغذية الاحتياطي الاستراتيجي: ${raison}.';
	@override String get aucunMouvement => 'لا تسمح السياسة لحسابك بأي حركة بين الصناديق.';
	@override String get mouvementsHorsLigne => 'غير متصل: تُستأنف الحركات بين الصناديق مع عودة الشبكة.';
	@override String get interdits => 'أموال العملاء الملتزَم بها والضرائب والالتزامات لا تموّل أبدًا مصروفًا عاديًا؛ والتخصيص السابق لا يُعدَّل.';
	@override String get previsionTitre => 'التوقعات';
	@override String get previsionPhrase => 'الداخل والخارج المتوقع، حسب التاريخ.';
	@override String get previsionVide => 'لا يوجد داخل ولا خارج متوقع حاليًا.';
	@override String get entree => 'داخل';
	@override String get sortie => 'خارج';
	@override String get historiqueTitre => 'سجل التخصيصات';
	@override String get historiquePhrase => 'كل حركة مسجلة في السجل؛ ولا يُعدَّل فيه شيء.';
	@override String get historiqueVide => 'لا توجد حركة مسجلة بين الصناديق.';
	@override late final _Traductions$comptable$tresorerie$transfert$ar transfert = _Traductions$comptable$tresorerie$transfert$ar._(_root);
	@override String get titre => 'الخزينة والصناديق';
	@override String get sousTitre => 'الخزينة الحرة هي الرقم الوحيد القابل للإنفاق.';
	@override String get alimenter => 'تغذية الاحتياطي الاستراتيجي';
}

// Path: comptable.encaissements
class _Traductions$comptable$encaissements$ar extends Traductions$comptable$encaissements$fr {
	_Traductions$comptable$encaissements$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get filtreTous => 'الكل';
	@override String get filtreConfirmes => 'مؤكَّدة';
	@override String get filtreEnAttente => 'قيد الانتظار';
	@override String get filtreEchoues => 'فاشلة';
	@override String get filtreRembourses => 'مُسترَدة';
	@override String get filtreContestes => 'متنازَع عليها';
	@override String get filtreARapprocher => 'للمطابقة';
	@override String get recherche => 'البحث عن أسرة أو مرجع';
	@override String get colDate => 'التاريخ';
	@override String get colFamille => 'الأسرة';
	@override String get colReference => 'المرجع';
	@override String get colBrut => 'الإجمالي';
	@override String get colFrais => 'الرسوم';
	@override String get colNet => 'الصافي';
	@override String get colMoyen => 'الوسيلة';
	@override String get colEtat => 'الحالة';
	@override String profilsPour({required Object prenoms}) => 'لـ ${prenoms}';
	@override String moyenPrestataire({required Object moyen, required Object prestataire}) => '${moyen} · ${prestataire}';
	@override String get videTitre => 'لا توجد مقبوضات حاليًا.';
	@override String get videPhrase => 'ستظهر هنا مدفوعات الأسر بمجرد أن يرسلها مزوّد الدفع.';
	@override String get videFiltreTitre => 'لا يوجد مقبوض مطابق.';
	@override String get videFiltrePhrase => 'اختر «الكل» أو امسح البحث لرؤية القائمة كاملة.';
	@override String get voirTous => 'عرض كل المقبوضات';
	@override String ouvrirDetailLecteur({required Object famille}) => 'فتح تفاصيل مقبوض ${famille}';
	@override String get fermerDetail => 'إغلاق التفاصيل';
	@override String get brut => 'المبلغ الإجمالي';
	@override String get frais => 'رسوم مزوّد الدفع';
	@override String get net => 'الصافي المستلَم';
	@override String get fraisSource => 'الرسوم والصرف كما أبلغ بها مزوّد الدفع، ولا يُعاد حسابها هنا أبدًا.';
	@override String get reference => 'المرجع';
	@override String get prestataire => 'مزوّد الدفع';
	@override String get moyen => 'وسيلة الدفع';
	@override String get foyer => 'الأسرة';
	@override String get date => 'التاريخ';
	@override String get etat => 'الحالة';
	@override String get devise => 'العملة';
	@override String get affectation => 'التوزيع حسب الملف';
	@override String get affectationAucune => 'لم يُرجع المصدر أي توزيع لهذا المقبوض.';
	@override String get rapprochement => 'المطابقة';
	@override String get rapprochementAucun => 'لم تتم المطابقة بعد';
	@override String get ouvrirRapprochement => 'فتح المطابقة';
	@override String get confirmeNote => 'لا تظهر «مؤكَّد» إلا بعد تأكيد مزوّد الدفع.';
	@override String get enAttenteNote => 'بانتظار تأكيد مزوّد الدفع: لم يُكتسب شيء بعد.';
	@override String get journal => 'سجل المقبوض';
	@override String get journalVide => 'لا توجد عملية مسجلة لهذا المقبوض.';
	@override late final _Traductions$comptable$encaissements$rap$ar rap = _Traductions$comptable$encaissements$rap$ar._(_root);
	@override String get titre => 'المقبوضات';
	@override String get sousTitre => 'لا تُؤكَّد الدفعة إلا بعد مزوّد الدفع.';
	@override String get detailTitre => 'تفاصيل المقبوض';
	@override String get rapprochementTitre => 'المطابقة';
	@override String get rapprochementSousTitre => 'ربط كل معاملة بما كان ينتظرها.';
}

// Path: comptable.beneficiaires
class _Traductions$comptable$beneficiaires$ar extends Traductions$comptable$beneficiaires$fr {
	_Traductions$comptable$beneficiaires$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get intro => 'ملف الدفع لكل معلم ولكل متعاقد. المستفيد وحده يُدخل بياناته أو يعدّلها: يمكنك تذكيره، أو طلب تحديث منه، أو إيقاف مدفوعاته.';
	@override String get filtreTous => 'الكل';
	@override String get filtreInfos => 'معلومات ناقصة';
	@override String get filtreVerification => 'قيد التحقق';
	@override String get filtreSuspendus => 'موقوفة';
	@override String get filtreInvitations => 'دعوات مُرسَلة';
	@override String get colonneBeneficiaire => 'المستفيد';
	@override String get colonneType => 'النوع';
	@override String get colonneDestination => 'الوجهة';
	@override String get colonneEtat => 'حالة الملف';
	@override String get colonneEnAttente => 'مدفوعات قيد الانتظار';
	@override String get typeEnseignant => 'معلم';
	@override String get typeContractuel => 'متعاقد';
	@override String enAttente({required Object n}) => '${n} قيد الانتظار';
	@override String get aucunEnAttente => 'لا شيء';
	@override String get vide => 'لا يوجد مستفيد حاليًا.';
	@override String get videDetail => 'يظهر المعلمون والمتعاقدون هنا بمجرد وجود دفعة تخصهم.';
	@override String get videFiltre => 'لا يوجد مستفيد بعامل التصفية هذا.';
	@override String get videFiltreDetail => 'اختر «الكل» لرؤية القائمة كاملة.';
	@override late final _Traductions$comptable$beneficiaires$profil$ar profil = _Traductions$comptable$beneficiaires$profil$ar._(_root);
	@override String get titre => 'المستفيدون';
	@override String get sousTitre => 'البيانات مخفية: المستفيد وحده يعدّل بياناته.';
	@override String get profilTitre => 'ملف الدفع';
	@override late final _Traductions$comptable$beneficiaires$recevoir$ar recevoir = _Traductions$comptable$beneficiaires$recevoir$ar._(_root);
}

// Path: comptable.contractuels
class _Traductions$comptable$contractuels$ar extends Traductions$comptable$contractuels$fr {
	_Traductions$comptable$contractuels$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get ongletObligations => 'الالتزامات';
	@override String get ongletAApprouver => 'للاعتماد';
	@override String get ongletAPayer => 'للدفع';
	@override String get ongletHistorique => 'السجل';
	@override String get ongletsLecteur => 'عرض الالتزامات';
	@override String get colonneBeneficiaire => 'المستفيد';
	@override String get colonneObjet => 'الموضوع';
	@override String get colonneMontant => 'المبلغ';
	@override String get colonneEcheance => 'الاستحقاق';
	@override String get colonneStatut => 'الحالة';
	@override String get typeRecurrente => 'متكرر';
	@override String get typePonctuelle => 'لمرة واحدة';
	@override String echeanceLe({required Object date}) => 'الاستحقاق: ${date}';
	@override String get payer => 'دفع';
	@override String payerLecteur({required Object objet}) => 'دفع الالتزام ${objet}';
	@override String get approuver => 'اعتماد';
	@override String ouvrirLecteur({required Object objet}) => 'فتح الالتزام ${objet}';
	@override String creationBloquee({required Object raison}) => 'الالتزام الجديد غير متاح: ${raison}.';
	@override String get videObligations => 'لا يوجد التزام جارٍ';
	@override String get videObligationsDetail => 'تظهر هنا الالتزامات المنشأة، مع استحقاقها وحالتها.';
	@override String get videAApprouver => 'لا شيء للاعتماد';
	@override String get videAApprouverDetail => 'تظهر هنا الالتزامات التي تنتظر الاعتماد.';
	@override String get videAPayer => 'لا شيء للدفع';
	@override String get videAPayerDetail => 'يظهر هنا الالتزام المعتمَد، جاهزًا للدفع.';
	@override String get videHistorique => 'لا يوجد التزام منتهٍ';
	@override String get videHistoriqueDetail => 'تظهر هنا الالتزامات المدفوعة أو المرفوضة أو الملغاة.';
	@override String get montantDefini => 'مبلغ يُحدَّد عند الإنشاء، ويُثبَّت بعد الاعتماد.';
	@override String get montantFige => 'مبلغ ثُبّت عند الاعتماد: لم يعد يُعدَّل.';
	@override String get montantTitre => 'المبلغ';
	@override String get sectionLignes => 'تفاصيل المبلغ';
	@override String get sectionInfos => 'المعلومات';
	@override String get sectionHistorique => 'سجل الالتزام';
	@override String get historiqueVide => 'لا توجد عملية مسجلة لهذا الالتزام.';
	@override String get champBeneficiaire => 'المستفيد';
	@override String get champType => 'النوع';
	@override String get champEcheance => 'الاستحقاق';
	@override String get champJustificatif => 'المستند المؤيِّد';
	@override String get champCentreCout => 'مركز التكلفة';
	@override String get champAuteur => 'المُنشئ';
	@override String get champApprobateur => 'المعتمِد';
	@override String get champProfilPaiement => 'دفع المستفيد';
	@override String get champMotifRefus => 'سبب الرفض';
	@override String get aucunJustificatif => 'لا يوجد مستند مؤيِّد مرفق';
	@override String get nonRenseigne => 'غير محدد';
	@override String ligneSource({required Object source}) => 'المصدر: ${source}';
	@override String ligneAuteur({required Object auteur}) => 'أضافه ${auteur}';
	@override String ligneValidation({required Object validation}) => 'المصادقة: ${validation}';
	@override String get payerAide => 'يُفتح الدفع في تفاصيل الدفعة، بالمبلغ الدقيق.';
	@override String get approuverAide => 'بعد الاعتماد، يُثبَّت المبلغ ويصبح الالتزام قابلًا للدفع.';
	@override String get renvoyerInvitation => 'إعادة إرسال الدعوة';
	@override String get invitationAide => 'هذا المستفيد الخارجي يُدخل وسيلة الدفع بنفسه، من دعوته الآمنة.';
	@override String get invitationRenvoyee => 'أُعيد إرسال الدعوة';
	@override String get erreurApprobation => 'لا نعلم إن كان الاعتماد قد سُجّل. حدّث الالتزام قبل إعادة المحاولة.';
	@override String get erreurInvitation => 'لا نعلم إن كانت الدعوة قد أُعيد إرسالها. حدّث الالتزام قبل إعادة المحاولة.';
	@override String get formIntro => 'المستفيد والاستحقاق ومركز التكلفة مقترحة: غيّرها عند الحاجة، ثم أدخل الموضوع والمبلغ.';
	@override String get beneficiaireExterne => 'مستفيد خارجي جديد';
	@override String get beneficiaireExterneAide => 'يتلقى دعوة آمنة ليُدخل وسيلة الدفع بنفسه.';
	@override String get champNomExterne => 'اسم المستفيد الخارجي';
	@override String get changerEcheance => 'تغيير الاستحقاق';
	@override String deviseDe({required Object devise}) => 'العملة: ${devise}';
	@override String get champObjet => 'موضوع الالتزام';
	@override String get aideObjet => 'مثلًا: الفاتورة رقم 024';
	@override String get champRefJustificatif => 'مرجع المستند المؤيِّد (اختياري)';
	@override String get champMontantSaisi => 'المبلغ';
	@override String get aideMontant => 'يُدخل مرة واحدة: لا يُعدَّل بعد الاعتماد.';
	@override String get creer => 'إنشاء الالتزام';
	@override String get horsLigneCreation => 'أنت غير متصل. أعد الاتصال لإنشاء الالتزام.';
	@override String get erreurObjet => 'أدخل موضوع الالتزام.';
	@override String get erreurMontant => 'أدخل مبلغًا أكبر من صفر، مثلًا 350 أو 350,50.';
	@override String get erreurNomExterne => 'أدخل اسم المستفيد الخارجي.';
	@override String get erreurCreation => 'لا نعلم إن كان الالتزام قد أُنشئ. حدّث القائمة قبل إعادة المحاولة.';
	@override String get creationIndisponible => 'لا يستطيع حسابك إنشاء التزام.';
	@override String get retourListe => 'العودة إلى المتعاقدين';
	@override String get titre => 'المتعاقدون والالتزامات';
	@override String get sousTitre => 'تُحدَّد المبالغ عند إنشاء الالتزام، وتُثبَّت بعد الاعتماد.';
	@override String get nouvelle => 'التزام جديد';
	@override String get detailTitre => 'الالتزام';
}

// Path: comptable.validation
class _Traductions$comptable$validation$ar extends Traductions$comptable$validation$fr {
	_Traductions$comptable$validation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get sousTitre => 'طلبات المحاسب التي تنتظر قرار شخص مخوَّل آخر. صاحب الطلب لا يصادق أبدًا على طلبه.';
	@override String get aDecider => 'للبتّ';
	@override String get decidees => 'بُتّ فيها مؤخرًا';
	@override String get videTitre => 'لا شيء للمصادقة';
	@override String get videPhrase => 'ستظهر هنا طلبات المحاسب القادمة.';
	@override late final _Traductions$comptable$validation$natures$ar natures = _Traductions$comptable$validation$natures$ar._(_root);
	@override String demandePar({required Object demandeur, required Object date}) => 'طلبه ${demandeur} في ${date}';
	@override String valideePar({required Object decideur, required Object date}) => 'صادق عليه ${decideur} في ${date}';
	@override String refuseePar({required Object decideur, required Object date}) => 'رفضه ${decideur} في ${date}';
	@override String motif({required Object motif}) => 'السبب: ${motif}';
	@override String ouvrir({required Object objet}) => 'عرض الطلب: ${objet}';
	@override String get votreDemandeTitre => 'طلبك أنت';
	@override String get votreDemandePhrase => 'سيبتّ فيه شخص مخوَّل آخر: لا تصادق أبدًا على طلب قدّمته.';
	@override late final _Traductions$comptable$validation$detail$ar detail = _Traductions$comptable$validation$detail$ar._(_root);
	@override String get valider => 'مصادقة';
	@override String get refuser => 'رفض';
	@override String get annuler => 'إلغاء';
	@override String get fermer => 'إغلاق';
	@override String get confirmerRefus => 'تأكيد الرفض';
	@override String get motifTitre => 'سبب الرفض';
	@override String get motifPhrase => 'سيقرأ المحاسب هذا السبب مع القرار. اختر واحدًا، أو حدّد سببك.';
	@override late final _Traductions$comptable$validation$motifs$ar motifs = _Traductions$comptable$validation$motifs$ar._(_root);
	@override String get motifAutreChamp => 'حدّد السبب';
	@override String get erreurMotif => 'اختر سببًا للرفض.';
	@override String get erreurMotifAutre => 'حدّد السبب للرفض.';
	@override String get decisionValidee => 'سُجّل قرارك: تمت المصادقة على الطلب.';
	@override String get decisionRefusee => 'سُجّل قرارك: رُفض الطلب، مع سببه.';
	@override String get refusTitre => 'لم يُسجَّل القرار';
	@override String get refusDemandeur => 'أنت من قدّم هذا الطلب: يجب أن يبتّ فيه شخص مخوَّل آخر. لم يتغير شيء.';
	@override String get refusMotif => 'الرفض يتطلب سببًا. اختر واحدًا، ثم أكّد.';
	@override String get refusDejaDecidee => 'سبق البتّ في هذا الطلب. أعد قراءة القائمة.';
	@override String get inconnuTitre => 'القرار غير مؤكد';
	@override String get inconnuPhrase => 'لا نعلم إن كان قرارك قد سُجّل. أعد قراءة القائمة قبل أن تقرر من جديد.';
	@override String get relireListe => 'إعادة قراءة القائمة';
	@override String get horsLigne => 'غير متصل: أعد الاتصال لتقرر.';
	@override String suiviEnAttente({required Object date}) => 'طُلب في ${date}. سيقرر شخص مخوَّل آخر؛ لا يُرسَل شيء قبل قراره.';
	@override String suiviValidee({required Object decideur, required Object date}) => 'صادق عليه ${decideur} في ${date}.';
	@override String suiviRefusee({required Object decideur, required Object date, required Object motif}) => 'رفضه ${decideur} في ${date}. السبب: ${motif}';
	@override String get erreurSuivi => 'تعذرت قراءة حالة طلب المصادقة. أعد المحاولة بعد قليل.';
	@override String get reessayer => 'إعادة المحاولة';
}

// Path: comptable.direction
class _Traductions$comptable$direction$ar extends Traductions$comptable$direction$fr {
	_Traductions$comptable$direction$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String versionDepuis({required Object version, required Object date}) => 'الإصدار ${version}، ساري المفعول منذ ${date}';
	@override String versionSansDate({required Object version}) => 'الإصدار ${version}';
	@override String auteur({required Object auteur}) => 'سجّله ${auteur}';
	@override String get enregistrer => 'تسجيل إصدار جديد';
	@override String get aucuneModification => 'لا يوجد تعديل للتسجيل.';
	@override String get corrigezChamps => 'صحّح الحقول المشار إليها للتسجيل.';
	@override String get enregistree => 'سُجّل الإصدار الجديد.';
	@override String get erreurEnregistrement => 'لا نعلم إن كان هذا الإصدار قد سُجّل. أعد قراءة الإصدار الساري، ثم أعد المحاولة.';
	@override String get enregistrementIndisponible => 'التسجيل غير متاح بعد. أعد المحاولة لاحقًا.';
	@override String get historique => 'سجل الإصدارات';
	@override String get historiqueVide => 'لا يوجد إصدار قبل هذا.';
	@override String get etatActuel => 'الحالة الحالية للاحتياطي';
	@override String get suffixeMois => 'أشهر';
	@override String get suffixeJours => 'أيام';
	@override String get suffixePourcent => '%';
	@override String get erreurNombre => 'أدخل عددًا صحيحًا أكبر من صفر.';
	@override String get erreurPourcentage => 'أدخل نسبة أكبر من صفر ولا تتجاوز 100، بمنزلة عشرية واحدة على الأكثر.';
	@override String get erreurMontant => 'أدخل مبلغًا أكبر من صفر.';
	@override late final _Traductions$comptable$direction$reservePanneau$ar reservePanneau = _Traductions$comptable$direction$reservePanneau$ar._(_root);
	@override late final _Traductions$comptable$direction$delegationPanneau$ar delegationPanneau = _Traductions$comptable$direction$delegationPanneau$ar._(_root);
	@override String get titre => 'الاحتياطي والتفويض';
	@override String get sousTitre => 'سياسة الاحتياطي الاستراتيجي وما يستطيع المحاسب تنفيذه وحده.';
	@override String get reserve => 'سياسة الاحتياطي الاستراتيجي';
	@override String get delegation => 'التفويض المالي';
}

// Path: comptable.demo
class _Traductions$comptable$demo$ar extends Traductions$comptable$demo$fr {
	_Traductions$comptable$demo$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'عرض توضيحي للمحاسب';
	@override String get mention => 'بيانات وهمية، لا دفع، لا إرسال.';
	@override String get intro => 'اختر شاشة من شاشات المحاسب. المبالغ مخفية افتراضيًا؛ ونسخة «المبالغ ظاهرة» تكشفها طوال مدة الصفحة.';
	@override String get montantsMasques => 'المبالغ مخفية';
	@override String get montantsAffiches => 'المبالغ ظاهرة';
	@override String get groupeComptable => 'واجهة المحاسب';
	@override String get groupeCompte => 'الحساب والمستفيد';
	@override String get groupeDirection => 'الإدارة';
}

// Path: commun.etats.chargementProlonge
class _Traductions$commun$etats$chargementProlonge$ar extends Traductions$commun$etats$chargementProlonge$fr {
	_Traductions$commun$etats$chargementProlonge$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'يستغرق الاتصال وقتًا أطول من المتوقع';
	@override String get phrase => 'يمكنك الانتظار قليلًا أو إعادة المحاولة.';
}

// Path: commun.etats.horsLigne
class _Traductions$commun$etats$horsLigne$ar extends Traductions$commun$etats$horsLigne$fr {
	_Traductions$commun$etats$horsLigne$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'أنت غير متصل';
	@override String get phrase => 'تحقق من اتصالك. ما هو معروض يبقى متاحًا للاطلاع.';
}

// Path: commun.etats.reconnexion
class _Traductions$commun$etats$reconnexion$ar extends Traductions$commun$etats$reconnexion$fr {
	_Traductions$commun$etats$reconnexion$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'جارٍ إعادة الاتصال';
	@override String get phrase => 'محاولة اتصال جديدة جارية.';
}

// Path: commun.etats.echecServeur
class _Traductions$commun$etats$echecServeur$ar extends Traductions$commun$etats$echecServeur$fr {
	_Traductions$commun$etats$echecServeur$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'تعذّر تحميل هذه المعلومات';
	@override String get phrase => 'لم يكتمل التحميل. أعد المحاولة بعد لحظة.';
}

// Path: commun.etats.introuvable
class _Traductions$commun$etats$introuvable$ar extends Traductions$commun$etats$introuvable$fr {
	_Traductions$commun$etats$introuvable$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'هذه الصفحة غير موجودة';
	@override String get phrase => 'ربما يكون الرابط ناقصًا، أو لم تعد الصفحة موجودة.';
}

// Path: commun.etats.accesRefuse
class _Traductions$commun$etats$accesRefuse$ar extends Traductions$commun$etats$accesRefuse$fr {
	_Traductions$commun$etats$accesRefuse$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'ليس لديك وصول إلى هذه الصفحة';
	@override String get phrase => 'هذا المحتوى غير مفتوح لحسابك.';
}

// Path: commun.etats.sessionExpiree
class _Traductions$commun$etats$sessionExpiree$ar extends Traductions$commun$etats$sessionExpiree$fr {
	_Traductions$commun$etats$sessionExpiree$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'انتهت جلستك';
	@override String get phrase => 'سجّل الدخول من جديد للمتابعة.';
}

// Path: commun.etats.dossierEnAttente
class _Traductions$commun$etats$dossierEnAttente$ar extends Traductions$commun$etats$dossierEnAttente$fr {
	_Traductions$commun$etats$dossierEnAttente$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'ملفك قيد الانتظار';
	@override String get phrase => 'تبقى خطوة قبل فتح هذه المساحة.';
}

// Path: commun.etats.aucunResultat
class _Traductions$commun$etats$aucunResultat$ar extends Traductions$commun$etats$aucunResultat$fr {
	_Traductions$commun$etats$aucunResultat$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'لا توجد نتائج';
	@override String get phrase => 'لا شيء مطابق حاليًا.';
}

// Path: commun.etats.permissionRefusee
class _Traductions$commun$etats$permissionRefusee$ar extends Traductions$commun$etats$permissionRefusee$fr {
	_Traductions$commun$etats$permissionRefusee$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الإذن مرفوض';
	@override String get phrase => 'دون هذا الإذن لا يمكن فتح هذه الوظيفة. يمكنك تعديله في إعدادات جهازك.';
}

// Path: commun.etats.ressourceExpiree
class _Traductions$commun$etats$ressourceExpiree$ar extends Traductions$commun$etats$ressourceExpiree$fr {
	_Traductions$commun$etats$ressourceExpiree$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'هذا المحتوى لم يعد متاحًا';
	@override String get phrase => 'لقد سُحب، أو انتهى الوصول إليه.';
}

// Path: commun.etats.indisponible
class _Traductions$commun$etats$indisponible$ar extends Traductions$commun$etats$indisponible$fr {
	_Traductions$commun$etats$indisponible$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'غير متاح بعد';
	@override String get phrase => 'هذه الوظيفة غير مفتوحة بعد.';
}

// Path: commun.etats.actions
class _Traductions$commun$etats$actions$ar extends Traductions$commun$etats$actions$fr {
	_Traductions$commun$etats$actions$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get reessayer => 'إعادة المحاولة';
	@override String get retourAccueil => 'العودة إلى الرئيسية';
	@override String get seConnecter => 'تسجيل الدخول';
	@override String get seReconnecter => 'تسجيل الدخول من جديد';
	@override String get voirDossier => 'عرض ملفي';
	@override String get reinitialiserFiltres => 'إعادة ضبط عوامل التصفية';
	@override String get revenir => 'الرجوع';
}

// Path: classe.entree.annonce
class _Traductions$classe$entree$annonce$ar extends Traductions$classe$entree$annonce$fr {
	_Traductions$classe$entree$annonce$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aVenir => 'حصة قادمة';
	@override String get fenetreOuverte => 'القاعة مفتوحة';
	@override String get attente => 'أنت في القاعة';
}

// Path: classe.observation.motif
class _Traductions$classe$observation$motif$ar extends Traductions$classe$observation$motif$fr {
	_Traductions$classe$observation$motif$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get visitesEpuisees => 'استخدمت زياراتك لهذه الحصة.';
	@override String get tempsEpuise => 'انتهى وقت المتابعة المخصص لك في هذه الحصة.';
	@override String get seanceNonCommencee => 'تُفتح المتابعة عند بدء الحصة.';
	@override String get seanceTerminee => 'انتهت الحصة.';
	@override String get seanceNonTenue => 'هذه الحصة لن تُعقد، فلا شيء للمتابعة.';
	@override String get horsFenetre => 'القاعة غير مفتوحة في هذا الوقت.';
	@override String get observationDesactivee => 'المتابعة مغلقة لهذا الفصل.';
	@override String get lienAbsent => 'لا يوجد طالب من أسرتك مرتبط بهذه الحصة.';
	@override String enfantAbsent({required Object dePrenom}) => 'تنتظر المتابعة وصول ${dePrenom}.';
	@override String presenceEnVerification({required Object dePrenom}) => 'يجري التحقق من حضور ${dePrenom}.';
	@override String get visiteDejaOuverte => 'توجد زيارة مفتوحة بالفعل، على هذا الجهاز أو على جهاز آخر.';
	@override String get garantieServeurAbsente => 'متابعة الحصص غير مفتوحة بعد.';
	@override String get reseau => 'تعذّر التحقق من إتاحة المتابعة.';
	@override String get capaciteAbsente => 'المتابعة غير متاحة حاليًا.';
}

// Path: classe.pageTravail.statut
class _Traductions$classe$pageTravail$statut$ar extends Traductions$classe$pageTravail$statut$fr {
	_Traductions$classe$pageTravail$statut$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aFaire => 'للإنجاز';
	@override String get enCours => 'بدأ';
	@override String get fait => 'منجز';
	@override String get expire => 'فات الموعد';
}

// Path: classe.pageCatalogue.etat
class _Traductions$classe$pageCatalogue$etat$ar extends Traductions$classe$pageCatalogue$etat$fr {
	_Traductions$classe$pageCatalogue$etat$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get ouverte => 'مفتوح';
	@override String get complete => 'مكتمل';
	@override String get listeAttente => 'قائمة الانتظار';
}

// Path: classe.pageCatalogue.resultat
class _Traductions$classe$pageCatalogue$resultat$ar extends Traductions$classe$pageCatalogue$resultat$fr {
	_Traductions$classe$pageCatalogue$resultat$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get inscritTitre => 'تم تأكيد التسجيل';
	@override String inscritPhrase({required Object prenom, required Object classe}) => 'انضم ${prenom} إلى ${classe}.';
	@override String get voirClasse => 'عرض الفصل';
	@override String get validationTitre => 'تم إرسال الطلب';
	@override String validationPhrase({required Object dePrenom, required Object classe}) => 'ما زال على الأكاديمية اعتماد تسجيل ${dePrenom} في ${classe}.';
	@override String get listeAttenteTitre => 'التسجيل في قائمة الانتظار';
	@override String listeAttentePhrase({required Object prenom, required Object deClasse}) => '${prenom} في قائمة انتظار ${deClasse}. لم يُحجز أي مقعد حاليًا.';
	@override String get refuseTitre => 'لم يُقبل التسجيل';
	@override String refusePhrase({required Object prenom}) => 'لم يُحجز أي مقعد لـ${prenom}. يمكنك اختيار فصل آخر.';
	@override String get autresClasses => 'عرض الفصول الأخرى';
	@override String get retourAccueil => 'العودة إلى الصفحة الرئيسية';
}

// Path: classe.cartes.types
class _Traductions$classe$cartes$types$ar extends Traductions$classe$cartes$types$fr {
	_Traductions$classe$cartes$types$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get annonce => 'إعلان';
	@override String get devoir => 'واجب';
	@override String get lien => 'رابط مفيد';
	@override String get rappel => 'تذكير';
}

// Path: classe.cartes.typesDetail
class _Traductions$classe$cartes$typesDetail$ar extends Traductions$classe$cartes$typesDetail$fr {
	_Traductions$classe$cartes$typesDetail$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get annonce => 'لمعلومة موجهة إلى الفصل كله.';
	@override String get devoir => 'لعمل يُحضَّر: الموعد النهائي المقترح هو الحصة القادمة.';
	@override String get lien => 'لمشاركة صفحة أو مادة: الصق عنوانها.';
	@override String get rappel => 'لتاريخ لا يُنسى: رحلة، امتحان، تغيير في الموعد.';
}

// Path: classe.cartes.modeles
class _Traductions$classe$cartes$modeles$ar extends Traductions$classe$cartes$modeles$fr {
	_Traductions$classe$cartes$modeles$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get annonce => 'معلومة للفصل';
	@override String get devoir => 'للتحضير للحصة القادمة';
	@override String get lien => 'مادة للاطلاع';
	@override String get rappel => 'لا تنسَ';
}

// Path: classe.cartes.feuille
class _Traductions$classe$cartes$feuille$ar extends Traductions$classe$cartes$feuille$fr {
	_Traductions$classe$cartes$feuille$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titreNouvelle => 'بطاقة جديدة للفصل';
	@override String titreModifier({required Object titre}) => 'تعديل البطاقة «${titre}»';
	@override String get contexte => 'اختر نموذجًا: يملأ البطاقة مسبقًا. يراها طلاب الفصل وأسرهم فورًا.';
	@override String get modele => 'نموذج البطاقة';
	@override String get champTitre => 'عنوان البطاقة';
	@override String get champTexte => 'نص البطاقة (اختياري)';
	@override String get champLien => 'رابط البطاقة (اختياري)';
	@override String aideLongueur({required Object max}) => '${max} حرفًا على الأكثر';
	@override String get aideLien => 'عنوان كامل، كما يظهر في شريط المتصفح';
	@override String get echeanceAucune => 'بلا موعد نهائي';
	@override String get choisirEcheance => 'اختيار الموعد النهائي';
	@override String get retirerEcheance => 'إزالة الموعد النهائي';
	@override String get enregistrer => 'حفظ البطاقة';
	@override String get retirer => 'حذف هذه البطاقة';
	@override String retirerQuestion({required Object titre}) => 'حذف البطاقة «${titre}»؟';
	@override String get retirerConsequence => 'تختفي فورًا عند طلاب الفصل وأسرهم.';
	@override String get retirerConfirmer => 'حذف البطاقة';
	@override String get envoiNonConfirme => 'لم يتأكد حفظ البطاقة: لم يصل الرد. احفظ من جديد بعد قليل.';
	@override String get retraitNonConfirme => 'لم يتأكد الحذف: لم يصل الرد. أعد المحاولة بعد قليل.';
	@override late final _Traductions$classe$cartes$feuille$defauts$ar defauts = _Traductions$classe$cartes$feuille$defauts$ar._(_root);
}

// Path: tuteur.accueil.etatCourt
class _Traductions$tuteur$accueil$etatCourt$ar extends Traductions$tuteur$accueil$etatCourt$fr {
	_Traductions$tuteur$accueil$etatCourt$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get enDirect => 'مباشر';
	@override String get salleOuverte => 'القاعة مفتوحة';
	@override String dansMinutes({required Object minutes}) => 'بعد ${minutes} د';
	@override String dansHeures({required Object heures, required Object minutes}) => 'بعد ${heures} س ${minutes} د';
	@override String dansJours({required Object jours}) => 'بعد ${jours} يوم';
	@override String get prevue => 'حصة مقررة';
	@override String get annulee => 'حصة ملغاة';
	@override String get nonTenue => 'حصة لم تُعقد';
	@override String get terminee => 'حصة منتهية';
	@override String get aucune => 'لا توجد حصة';
	@override String get illisible => 'غير متاح';
}

// Path: tc.groupe.mesGroupes
class _Traductions$tc$groupe$mesGroupes$ar extends Traductions$tc$groupe$mesGroupes$fr {
	_Traductions$tc$groupe$mesGroupes$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'فصولي';
	@override String get aucun => 'لا يوجد فصل حاليًا';
	@override String get aucunDetail => 'ستضعك الأكاديمية في فصل بمجرد توفر موعد يناسبك.';
}

// Path: tc.groupe.commun
class _Traductions$tc$groupe$commun$ar extends Traductions$tc$groupe$commun$fr {
	_Traductions$tc$groupe$commun$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get erreur => 'تعذّرت قراءة فصولك';
	@override String get reessayer => 'إعادة المحاولة';
}

// Path: tc.groupe.carte
class _Traductions$tc$groupe$carte$ar extends Traductions$tc$groupe$carte$fr {
	_Traductions$tc$groupe$carte$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String ouvrir({required Object libelle}) => 'فتح الفصل ${libelle}';
	@override String capacite({required Object membres, required Object seuil}) => '${membres} / ${seuil}';
	@override String capacitePhrase({required Object membres, required Object seuil}) => '${membres} طلاب من أصل ${seuil} مقاعد';
	@override String get complet => 'مكتمل';
	@override String get prochainCours => 'الدرس القادم';
	@override String get aucuneSeance => 'لا توجد حصة مجدولة';
	@override String get aucuneSeanceDetail => 'لم يُحدَّد جدول هذا الفصل بعد.';
	@override String duree({required Object valeur}) => 'المدة ${valeur}';
	@override String get dureeLibelle => 'المدة';
	@override String get rejoindre => 'انضمام';
}

// Path: tc.groupe.enseignant
class _Traductions$tc$groupe$enseignant$ar extends Traductions$tc$groupe$enseignant$fr {
	_Traductions$tc$groupe$enseignant$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get sayyid => 'سيد';
	@override String get sayyida => 'سيدة';
	@override String get photoManquante => 'الصورة مطلوبة';
	@override String get photoManquanteDetail => 'لم تُسجَّل صورة المعلم بعد.';
}

// Path: tc.groupe.cours
class _Traductions$tc$groupe$cours$ar extends Traductions$tc$groupe$cours$fr {
	_Traductions$tc$groupe$cours$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String coursEtNiveau({required Object cours, required Object niveau}) => '${cours} · ${niveau}';
}

// Path: tc.groupe.temps
class _Traductions$tc$groupe$temps$ar extends Traductions$tc$groupe$temps$fr {
	_Traductions$tc$groupe$temps$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String dansMinutes({required Object minutes}) => 'الدرس بعد ${minutes} د';
	@override String dansHeures({required Object heures, required Object minutes}) => 'الدرس بعد ${heures} س ${minutes} د';
	@override String get imminent => 'الدرس وشيك';
	@override String salleOuverte({required Object reste}) => 'القاعة مفتوحة · ${reste}';
	@override String get salleOuverteCourt => 'القاعة مفتوحة';
	@override String get attente => 'أنت في القاعة. لم يبدأ الدرس بعد.';
	@override String get attenteDetail => 'وقت الانتظار هذا لا يُحتسب في حضورك.';
	@override String get enSalle => 'في القاعة';
	@override String resteMinutes({required Object minutes}) => 'متبقٍّ ${minutes} د';
	@override String resteHeures({required Object heures, required Object minutes}) => 'متبقٍّ ${heures} س ${minutes} د';
	@override String enCours({required Object reste}) => 'الحصة مباشرة · ${reste}';
	@override String get enDirect => 'مباشر';
	@override String get prolongee => 'الحصة ما زالت مباشرة';
	@override String get depassement => 'تجاوز الوقت';
	@override String get terminee => 'انتهى الدرس';
}

// Path: tc.groupe.duree
class _Traductions$tc$groupe$duree$ar extends Traductions$tc$groupe$duree$fr {
	_Traductions$tc$groupe$duree$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String minutes({required Object minutes}) => '${minutes} د';
	@override String heures({required Object heures}) => '${heures} س';
	@override String heuresMinutes({required Object heures, required Object minutes}) => '${heures} س ${minutes} د';
}

// Path: tc.groupe.horloges
class _Traductions$tc$groupe$horloges$ar extends Traductions$tc$groupe$horloges$fr {
	_Traductions$tc$groupe$horloges$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get votreHeure => 'توقيتك';
	@override String chezEnseignant({required Object nomme}) => 'توقيت ${nomme}';
	@override String get heureGroupe => 'توقيت الفصل';
	@override String heureEtVille({required Object heure, required Object ville}) => '${heure} ${ville}';
}

// Path: tc.groupe.dst
class _Traductions$tc$groupe$dst$ar extends Traductions$tc$groupe$dst$fr {
	_Traductions$tc$groupe$dst$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get j30 => 'تغيير التوقيت بعد شهر';
	@override String get j7 => 'تغيير التوقيت الأسبوع القادم';
	@override String get j1 => 'تغيير التوقيت غدًا';
	@override String detail({required Object avant, required Object apres}) => 'سينتقل درسك من ${avant} إلى ${apres}.';
}

// Path: tc.groupe.session
class _Traductions$tc$groupe$session$ar extends Traductions$tc$groupe$session$fr {
	_Traductions$tc$groupe$session$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get conseilAppareil => 'يُنصح بجهاز لوحي أو حاسوب للدرس. يبقى الهاتف مدعومًا.';
}

// Path: tc.groupe.espace
class _Traductions$tc$groupe$espace$ar extends Traductions$tc$groupe$espace$fr {
	_Traductions$tc$groupe$espace$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get retour => 'فصولي';
	@override String get avantProchainCours => 'قبل الدرس القادم';
	@override String get aucuneAction => 'لا شيء للتحضير حاليًا';
	@override String get bibliotheque => 'المكتبة';
	@override String get bibliothequeVoirTout => 'عرض الكل';
	@override String get progression => 'التقدم';
	@override String get roster => 'طلاب الفصل';
	@override String get reprendreLeCours => 'استئناف الدرس';
	@override String get introuvable => 'هذا الفصل غير متاح لك';
	@override String get introuvableDetail => 'ربما أُغلق، أو يخص ملفًا آخر.';
}

// Path: tc.groupe.emplacement
class _Traductions$tc$groupe$emplacement$ar extends Traductions$tc$groupe$emplacement$fr {
	_Traductions$tc$groupe$emplacement$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get nonBranche => 'متاح قريبًا';
	@override String get nonBrancheDetail => 'سيُربط هذا المحتوى بهذه المساحة قريبًا.';
}

// Path: tc.bibliotheque.sections
class _Traductions$tc$bibliotheque$sections$ar extends Traductions$tc$bibliotheque$sections$fr {
	_Traductions$tc$bibliotheque$sections$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get groupe => 'المواد المعروضة';
}

// Path: com.socle.composants
class _Traductions$com$socle$composants$ar extends Traductions$com$socle$composants$fr {
	_Traductions$com$socle$composants$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$com$socle$composants$lecture$ar lecture = _Traductions$com$socle$composants$lecture$ar._(_root);
	@override late final _Traductions$com$socle$composants$badge$ar badge = _Traductions$com$socle$composants$badge$ar._(_root);
	@override late final _Traductions$com$socle$composants$pieceJointe$ar pieceJointe = _Traductions$com$socle$composants$pieceJointe$ar._(_root);
	@override late final _Traductions$com$socle$composants$composer$ar composer = _Traductions$com$socle$composants$composer$ar._(_root);
	@override late final _Traductions$com$socle$composants$etats$ar etats = _Traductions$com$socle$composants$etats$ar._(_root);
	@override late final _Traductions$com$socle$composants$espace$ar espace = _Traductions$com$socle$composants$espace$ar._(_root);
}

// Path: com.socle.lexique
class _Traductions$com$socle$lexique$ar extends Traductions$com$socle$lexique$fr {
	_Traductions$com$socle$lexique$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get messages => 'الرسائل';
	@override String get messagesMetier => 'رسائل العمل';
	@override String get communaute => 'مجتمع المعلّمين';
	@override String get studio => 'الاستوديو';
	@override String get aujourdhui => 'اليوم';
	@override String get notifications => 'الإشعارات';
	@override String get annonce => 'إعلان';
	@override String get publication => 'منشور';
	@override String get reponse => 'رد';
	@override String get enregistrer => 'حفظ';
	@override String get signaler => 'إبلاغ';
	@override String get modeFocus => 'وضع التركيز';
	@override String get quitterFocus => 'الخروج من التركيز';
	@override String get aTraiter => 'للمعالجة';
	@override String get actionRequise => 'إجراء مطلوب';
	@override String get brouillon => 'مسودة';
	@override String get elementsEpingles => 'العناصر المثبّتة';
	@override String get fichiersPartages => 'الملفات المشتركة';
}

// Path: com.socle.motifs
class _Traductions$com$socle$motifs$ar extends Traductions$com$socle$motifs$fr {
	_Traductions$com$socle$motifs$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'لماذا تبلّغ عن هذا المحتوى؟';
	@override String get publicite => 'إعلان تجاري';
	@override String get lienAffilie => 'رابط تسويق بالعمولة';
	@override String get venteNonAutorisee => 'بيع غير مسموح به';
	@override String get sollicitationCommerciale => 'استدراج تجاري';
	@override String get horsSujet => 'محتوى لا علاقة له بالمجتمع';
	@override String get harcelement => 'مضايقة أو لغة غير لائقة';
	@override String get donneesPersonnelles => 'بيانات شخصية لطالب أو لعائلة';
	@override String get autre => 'محتوى آخر يحتاج إلى فحص';
}

// Path: com.socle.signalement
class _Traductions$com$socle$signalement$ar extends Traductions$com$socle$signalement$fr {
	_Traductions$com$socle$signalement$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الإبلاغ عن هذا المحتوى';
	@override String get precision => 'توضيح اختياري';
	@override String get envoyer => 'إرسال البلاغ';
	@override String get confirme => 'تم الإبلاغ عن المحتوى. ستتم مراجعته.';
	@override String get erreur => 'لم يُؤكَّد البلاغ بعد. أعد المحاولة بعد قليل.';
	@override String get indisponible => 'الإبلاغ غير متاح هنا بعد.';
}

// Path: com.socle.enregistrement
class _Traductions$com$socle$enregistrement$ar extends Traductions$com$socle$enregistrement$fr {
	_Traductions$com$socle$enregistrement$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get enregistrer => _root.com.socle.lexique.enregistrer;
	@override String get retirer => 'إزالة من العناصر المحفوظة';
	@override String get enregistre => 'محفوظ';
	@override String get indisponible => 'الحفظ غير متاح هنا بعد.';
}

// Path: com.socle.navigation
class _Traductions$com$socle$navigation$ar extends Traductions$com$socle$navigation$fr {
	_Traductions$com$socle$navigation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get notifications => _root.com.socle.lexique.notifications;
	@override String get ouvrirNotifications => 'فتح الإشعارات';
	@override String get studio => _root.com.socle.lexique.studio;
	@override String get ouvrirStudio => 'فتح الاستوديو';
	@override String get quitterStudio => 'الخروج من الاستوديو';
	@override String get messages => _root.com.socle.lexique.messages;
	@override String get communaute => _root.com.socle.lexique.communaute;
	@override String get communications => 'الاتصالات';
	@override String get communicationsDetail => 'الإعلانات والإشراف ورسائل الصفوف';
	@override String get ongletAnnonces => 'الإعلانات';
	@override String get ongletModeration => 'الإشراف';
	@override String get ongletMessages => _root.com.socle.lexique.messages;
	@override String get bientot => 'متاح قريبًا';
	@override late final _Traductions$com$socle$navigation$provisoire$ar provisoire = _Traductions$com$socle$navigation$provisoire$ar._(_root);
	@override late final _Traductions$com$socle$navigation$demo$ar demo = _Traductions$com$socle$navigation$demo$ar._(_root);
}

// Path: com.messages.entree
class _Traductions$com$messages$entree$ar extends Traductions$com$messages$entree$fr {
	_Traductions$com$messages$entree$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titreClasse => 'التواصل بشأن هذا الفصل';
	@override String get titreDossier => 'التواصل بشأن هذا الملف';
	@override String get titreObjet => 'التواصل بشأن هذا الموضوع';
	@override String get ecrireFamille => 'مراسلة الأسرة';
	@override String get ecrireAdministration => 'مراسلة الإدارة';
	@override String ecrireA({required Object nom}) => 'مراسلة ${nom}';
	@override String conversationAvec({required Object nom}) => 'محادثة مع ${nom}';
	@override String get voirTout => 'عرض كل المحادثات';
	@override String get toutes => 'كل محادثاتك';
	@override String get aLireUne => 'محادثة واحدة للقراءة';
	@override String aLire({required Object nombre}) => '${nombre} محادثات للقراءة';
	@override String get ouverture => 'جارٍ فتح المحادثة';
	@override String get inaccessibleTitre => 'محادثة غير متاحة';
	@override String get inaccessible => 'لم تعد هذه المحادثة متاحة لك. اختر شخصًا آخر من القائمة.';
	@override String get erreurOuvertureTitre => 'تعذّر فتح هذه المحادثة.';
	@override String get ouvertureEchouee => 'تحقّق من اتصالك ثم أعد المحاولة.';
}

// Path: com.messages.recherche
class _Traductions$com$messages$recherche$ar extends Traductions$com$messages$recherche$fr {
	_Traductions$com$messages$recherche$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get champ => 'البحث عن محادثة';
	@override String get aide => 'الاسم أو الفصل أو الملف';
	@override String get aucunTitre => 'لم يتم العثور على أي محادثة';
	@override String aucun({required Object texte}) => 'لا توجد محادثة تطابق «⁨${texte}⁩». جرّب اسمًا آخر أو فصلًا آخر.';
	@override String get resultatUn => 'تم العثور على محادثة واحدة';
	@override String resultats({required Object nombre}) => 'تم العثور على ${nombre} محادثات';
}

// Path: com.messages.ligne
class _Traductions$com$messages$ligne$ar extends Traductions$com$messages$ligne$fr {
	_Traductions$com$messages$ligne$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String legende({required Object objet, required Object apercu}) => '${objet} · ${apercu}';
	@override String get sansApercu => 'لا توجد رسائل حاليًا';
	@override String dateCourte({required Object numero, required Object mois}) => '${numero} ${mois}';
}

// Path: com.messages.noms
class _Traductions$com$messages$noms$ar extends Traductions$com$messages$noms$fr {
	_Traductions$com$messages$noms$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String avecFonction({required Object nom, required Object fonction}) => '${nom} · ${fonction}';
	@override String deux({required Object premier, required Object second}) => '${premier} و${second}';
	@override String plusieurs({required Object premier, required Object nombre}) => '${premier} و${nombre} أشخاص آخرين';
	@override String surObjet({required Object objet}) => 'محادثة بخصوص ${objet}';
	@override String get sansObjet => 'محادثة';
}

// Path: com.messages.entete
class _Traductions$com$messages$entete$ar extends Traductions$com$messages$entete$fr {
	_Traductions$com$messages$entete$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String avecAttention({required Object entete, required Object attention}) => '${entete}. ${attention}';
	@override String deuxObjets({required Object premier, required Object second}) => '${premier} · ${second}';
	@override String semantique({required Object noms, required Object objets}) => 'محادثة مع ${noms}‏، بخصوص ${objets}';
	@override String semantiqueSansNoms({required Object objets}) => 'محادثة بخصوص ${objets}';
}

// Path: com.messages.types
class _Traductions$com$messages$types$ar extends Traductions$com$messages$types$fr {
	_Traductions$com$messages$types$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get classe => 'الفصل';
	@override String get eleve => 'الطالب';
	@override String get dossier => 'الملف';
	@override String get mission => 'مهمة المراقبة';
	@override String get remplacement => 'الاستبدال';
	@override String get profilPaiement => 'ملف الدفع';
	@override String get autre => 'موضوع آخر';
}

// Path: com.messages.panneau
class _Traductions$com$messages$panneau$ar extends Traductions$com$messages$panneau$fr {
	_Traductions$com$messages$panneau$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get objets => 'بخصوص';
	@override String get participants => 'المشاركون';
	@override String get fichiers => _root.com.socle.lexique.fichiersPartages;
	@override String ouvrir({required Object objet}) => 'فتح ${objet}';
	@override String get inaccessible => 'لم يعد هذا الموضوع متاحًا لك. تبقى المحادثة متاحة للقراءة.';
	@override String get vous => 'أنت';
}

// Path: com.messages.fil
class _Traductions$com$messages$fil$ar extends Traductions$com$messages$fil$fr {
	_Traductions$com$messages$fil$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get lectureSeule => 'يمكنك قراءة هذه المحادثة. الرد فيها غير متاح لك.';
}

// Path: com.messages.demo
class _Traductions$com$messages$demo$ar extends Traductions$com$messages$demo$fr {
	_Traductions$com$messages$demo$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get choisirRole => 'اختر وجهة النظر في هذا العرض التوضيحي.';
	@override late final _Traductions$com$messages$demo$roles$ar roles = _Traductions$com$messages$demo$roles$ar._(_root);
	@override String get situations => 'حالات للتجربة';
	@override String get echec => 'إرسال غير مؤكد، من جهة المعلم';
	@override String get horsLigne => 'دون اتصال، من جهة الأسرة';
	@override String get refuse => 'محادثة أسرة أخرى، مرفوضة';
	@override String vue({required Object role}) => 'وجهة النظر: ${role}';
	@override late final _Traductions$com$messages$demo$f$ar f = _Traductions$com$messages$demo$f$ar._(_root);
}

// Path: com.vocal.composer
class _Traductions$com$vocal$composer$ar extends Traductions$com$vocal$composer$fr {
	_Traductions$com$vocal$composer$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get libelle => 'رسالة صوتية';
	@override String get enregistrer => 'تسجيل رسالة صوتية';
	@override String get indisponible => 'الرسالة الصوتية غير متاحة هنا بعد. اكتب رسالتك في الحقل أعلاه.';
	@override String get erreurVerificationTitre => 'تعذّر التحقق من الميكروفون.';
	@override String get erreurVerificationAction => 'إعادة المحاولة';
	@override String get erreurDemarrage => 'تعذّر بدء التسجيل. تحقّق من أن الميكروفون لا يستخدمه تطبيق آخر، ثم أعد المحاولة.';
	@override String get erreurInterrompu => 'توقف التسجيل. تحقّق من الميكروفون، ثم أعد المحاولة.';
	@override String get permissionTitre => 'الميكروفون مطلوب';
	@override String get permissionPhrase => 'يحتاج رواية إلى الميكروفون لتسجيل رسالتك الصوتية. لا يُرسل شيء دون موافقتك.';
	@override String get autoriser => 'السماح باستخدام الميكروفون';
	@override String get annuler => 'إلغاء';
	@override String get refuse => 'الميكروفون غير مسموح به لتطبيق رواية.';
	@override String get refuseAide => 'لإرسال رسالة صوتية، اسمح باستخدام الميكروفون من إعدادات جهازك، ثم عد إلى هنا.';
	@override String get fermer => 'إغلاق';
	@override String get enregistrement => 'التسجيل جارٍ';
	@override String get pause => 'التسجيل متوقف مؤقتًا';
	@override String get reprise => 'استُؤنف التسجيل';
	@override String limiteProche({required Object seuil, required Object max}) => 'بقي أقل من ${seuil} قبل الحد الأقصى ${max}';
	@override String limiteAtteinte({required Object max}) => 'بلغت المدة القصوى (${max}). استمع إلى رسالتك، ثم أرسلها أو احذفها.';
	@override String ecoule({required Object ecoule, required Object max}) => '${ecoule} من ${max}';
	@override String get preEcoute => 'الاستماع قبل الإرسال';
	@override String get preEcouteAide => 'استمع إلى رسالتك قبل إرسالها. لا يُرسل شيء دون موافقتك.';
	@override String duree({required Object duree}) => 'المدة: ${duree}';
	@override String get actionPause => 'إيقاف مؤقت';
	@override String get actionReprendre => 'استئناف';
	@override String get actionArreter => 'إيقاف';
	@override String get actionSupprimer => 'حذف';
	@override String get actionEnvoyer => 'إرسال';
	@override String get confirmerTitre => 'حذف هذه الرسالة الصوتية؟';
	@override String get confirmerPhrase => 'ستُمحى من هذا الجهاز. لا يمكن التراجع عن هذا الإجراء.';
	@override String get garder => 'الاحتفاظ بها';
	@override String get envoi => 'جارٍ إرسال الرسالة الصوتية';
	@override String get nonConfirme => 'لم يتم تأكيد هذه الرسالة الصوتية بعد.';
	@override String get nonConfirmeAide => 'تحقّق من اتصالك، ثم أعد المحاولة. الرسالة الصوتية محفوظة هنا.';
	@override String get reessayer => 'إعادة المحاولة';
	@override String get envoye => 'أُرسلت الرسالة الصوتية.';
	@override String get horsLigne => 'أنت غير متصل. الرسالة الصوتية محفوظة هنا: أرسلها عند عودة الاتصال.';
}

// Path: com.vocal.lecteur
class _Traductions$com$vocal$lecteur$ar extends Traductions$com$vocal$lecteur$fr {
	_Traductions$com$vocal$lecteur$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String libelleAuteur({required Object auteur, required Object duree}) => 'رسالة صوتية من ${auteur}‏، ${duree}';
	@override String libelle({required Object duree}) => 'رسالة صوتية، ${duree}';
	@override String get ecouter => 'استماع';
	@override String get pause => 'إيقاف مؤقت';
	@override String get reprendre => 'استئناف';
	@override String get reecouter => 'إعادة الاستماع';
	@override String get nonEcoute => 'لم يُستمع إليها بعد';
	@override String get lecture => 'التشغيل جارٍ';
	@override String get enPause => 'التشغيل متوقف مؤقتًا';
	@override String get fin => 'استُمع إليها كاملة';
	@override String position({required Object position, required Object duree}) => '${position} من ${duree}';
	@override String get indisponible => 'التشغيل غير متاح هنا بعد. تبقى الرسالة في المحادثة: عد لاحقًا للاستماع إليها.';
	@override String get erreurLectureTitre => 'تعذّر تشغيل هذه الرسالة الصوتية.';
	@override String get erreurLectureAction => 'إعادة المحاولة';
}

// Path: com.vocal.demo
class _Traductions$com$vocal$demo$ar extends Traductions$com$vocal$demo$fr {
	_Traductions$com$vocal$demo$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get contexte => 'عرض توضيحي للرسالة الصوتية: لا يُستخدم ميكروفون حقيقي، والتسجيل محاكى.';
	@override String get situations => 'حالات العرض التوضيحي';
	@override String get autorise => 'الميكروفون مسموح';
	@override String get aDemander => 'يُطلب الإذن';
	@override String get refuse => 'الميكروفون مرفوض';
	@override String get nonConfirme => 'غير مؤكد';
	@override String get indisponible => 'غير متاح';
	@override String get recu => 'رسالة صوتية واردة';
	@override String get repondre => 'الرد في المحادثة';
	@override String get envoyes => 'الرسائل الصوتية المرسلة';
	@override String get auteurEnseignante => 'سيدة مريم، معلمة';
	@override String get auteurParent => 'أحمد، ولي أمر آدم';
	@override String get messageRecu => 'السلام عليكم، هذه ملاحظاتي على تلاوة هذا الأسبوع.';
	@override String get horodatage => 'اليوم، 10:28';
}

// Path: com.communaute.garde
class _Traductions$com$communaute$garde$ar extends Traductions$com$communaute$garde$fr {
	_Traductions$com$communaute$garde$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aide => 'لا إعلانات. لا روابط تسويق بالعمولة. لا بيع.';
	@override String get avertissement => 'يبدو أن هذا المنشور يتضمّن ترويجًا تجاريًا. أزِل الرابط أو الرمز أو العرض قبل النشر.';
	@override String get bloqueAffilie => 'روابط التسويق بالعمولة غير مسموح بها في مجتمع المعلّمين.';
	@override String get bloqueVente => 'بيع المنتجات أو الخدمات غير مسموح به في هذه المساحة.';
	@override String get titreAvertissement => 'منشور يحتاج إلى مراجعة';
	@override String get titreBlocage => 'منشور محظور';
	@override String motif({required Object motif}) => 'السبب: ${motif}';
	@override String get liensTitre => 'روابط المنشور';
	@override String get consigneBlocage => 'عدِّل المنشور ثم انشره من جديد.';
	@override String get panne => 'لم يُؤكَّد التحقق من هذا المحتوى، على الأرجح بسبب الاتصال؛ لم يُنشر شيء. تحقّق من الاتصال ثم أعد المحاولة.';
	@override late final _Traductions$com$communaute$garde$reponse$ar reponse = _Traductions$com$communaute$garde$reponse$ar._(_root);
}

// Path: com.communaute.lien
class _Traductions$com$communaute$lien$ar extends Traductions$com$communaute$lien$fr {
	_Traductions$com$communaute$lien$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get interne => 'رابط داخلي في رواية';
	@override String get ressourceExterne => 'مورد تعليمي خارجي';
	@override String get commercialInterdit => 'رابط تجاري ممنوع';
	@override String get nonVerifie => 'رابط غير مُتحقَّق منه';
	@override String semantique({required Object adresse, required Object etat}) => '${adresse}‏، ${etat}';
}

// Path: com.communaute.flux
class _Traductions$com$communaute$flux$ar extends Traductions$com$communaute$flux$fr {
	_Traductions$com$communaute$flux$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String ouvrir({required Object titre}) => 'فتح المنشور ${titre}';
	@override String get reponseUne => 'رد واحد';
	@override String reponses({required Object nombre}) => '${nombre} ردود';
	@override String get aucuneReponse => 'لا توجد ردود';
	@override String categorie({required Object categorie}) => 'الفئة ${categorie}';
}

// Path: com.communaute.recherche
class _Traductions$com$communaute$recherche$ar extends Traductions$com$communaute$recherche$fr {
	_Traductions$com$communaute$recherche$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get ouvrir => 'البحث عن منشور';
	@override String get champ => 'البحث عن منشور';
	@override String get aide => 'كلمة من العنوان أو النص';
}

// Path: com.communaute.moment
class _Traductions$com$communaute$moment$ar extends Traductions$com$communaute$moment$fr {
	_Traductions$com$communaute$moment$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get instant => 'الآن';
	@override String minutes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		one: 'منذ دقيقة',
		two: 'منذ دقيقتين',
		few: 'منذ ${n} دقائق',
		many: 'منذ ${n} دقيقة',
		other: 'منذ ${n} دقيقة',
	);
	@override String heures({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		one: 'منذ ساعة',
		two: 'منذ ساعتين',
		few: 'منذ ${n} ساعات',
		many: 'منذ ${n} ساعة',
		other: 'منذ ${n} ساعة',
	);
	@override String jours({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		one: 'منذ يوم',
		two: 'منذ يومين',
		few: 'منذ ${n} أيام',
		many: 'منذ ${n} يومًا',
		other: 'منذ ${n} يوم',
	);
	@override String date({required Object jour, required Object mois}) => 'في ${jour}/${mois}';
}

// Path: com.communaute.publication
class _Traductions$com$communaute$publication$ar extends Traductions$com$communaute$publication$fr {
	_Traductions$com$communaute$publication$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String auteur({required Object fonction, required Object moment}) => '${fonction} · ${moment}';
	@override String get enregistrer => 'حفظ المنشور';
	@override String get enregistree => 'منشور محفوظ';
	@override String get retirer => 'إزالة من العناصر المحفوظة';
	@override String menu({required Object titre}) => 'إجراءات على المنشور ${titre}';
	@override String get signaler => 'الإبلاغ عن المنشور';
	@override String get signalee => 'تم الإبلاغ عن المحتوى إلى فريق الإشراف.';
	@override String get choisirTitre => 'لا يوجد منشور مفتوح';
	@override String get choisir => 'اختر منشورًا من القائمة لقراءته والرد عليه.';
	@override String get introuvableTitre => 'المنشور غير متاح';
	@override String get introuvable => 'تمت إزالة هذا المنشور أو لم يعد متاحًا لك. عد إلى المنشورات لاختيار منشور آخر.';
	@override String get revenir => 'العودة إلى المنشورات';
}

// Path: com.communaute.reponses
class _Traductions$com$communaute$reponses$ar extends Traductions$com$communaute$reponses$fr {
	_Traductions$com$communaute$reponses$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String titre({required Object nombre}) => 'الردود (${nombre})';
	@override String get vide => 'لا توجد ردود حاليًا.';
	@override String get erreurTitre => 'تعذّر تحميل الردود.';
	@override String get champ => 'ردك';
	@override String get aide => 'اكتب ردًا';
	@override String get envoyer => 'إرسال الرد';
	@override String get champVide => 'اكتب ردًا لإرساله.';
	@override String get enCours => 'جارٍ الإرسال';
	@override String get nonConfirmee => 'لم يُؤكَّد هذا الرد بعد. تحقّق من اتصالك ثم أعد إرساله.';
	@override String get refusee => 'رفضته سياسة المجتمع';
	@override String get reessayer => 'إعادة إرسال الرد';
	@override String get indisponible => 'الردود غير متاحة هنا بعد.';
	@override String menu({required Object nom}) => 'إجراءات على رد ${nom}';
	@override String get signaler => 'الإبلاغ عن الرد';
	@override String get signalee => 'لقد أبلغت عن هذا الرد.';
}

// Path: com.communaute.signalement
class _Traductions$com$communaute$signalement$ar extends Traductions$com$communaute$signalement$fr {
	_Traductions$com$communaute$signalement$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$com$communaute$signalement$politique$ar politique = _Traductions$com$communaute$signalement$politique$ar._(_root);
	@override String get motifManquant => 'اختر سببًا لإرسال البلاغ.';
}

// Path: com.communaute.composer
class _Traductions$com$communaute$composer$ar extends Traductions$com$communaute$composer$fr {
	_Traductions$com$communaute$composer$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get nouvelle => 'منشور جديد';
	@override String get contexte => 'شارك سؤالًا أو طريقة أو موردًا مفيدًا للتعليم.';
	@override String get categorie => 'الفئة';
	@override String get categorieManquante => 'اختر فئة للنشر.';
	@override String get champTitre => 'العنوان';
	@override String get aideTitre => 'الموضوع في كلمات قليلة';
	@override String get titreManquant => 'اكتب عنوانًا للنشر.';
	@override String get champTexte => 'النص';
	@override String get aideTexte => 'سؤالك أو خبرتك';
	@override String get texteManquant => 'اكتب نص المنشور للنشر.';
	@override String get pieces => 'المرفقات';
	@override String get pieceRefusee => 'أزل الملفات المرفوضة قبل النشر.';
	@override String get choixIndisponible => 'اختيار ملف غير متاح هنا بعد.';
	@override String get publier => 'نشر';
	@override String get fermer => 'إغلاق المنشور الجديد';
	@override String get confirmee => 'منشورك متاح الآن.';
	@override String get erreurEnvoi => 'لم يُؤكَّد منشورك بعد. تحقّق من اتصالك ثم أعد المحاولة.';
	@override String get indisponible => 'النشر غير متاح هنا بعد.';
}

// Path: com.communaute.regles
class _Traductions$com$communaute$regles$ar extends Traductions$com$communaute$regles$fr {
	_Traductions$com$communaute$regles$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get panneau => 'المساعدة والقواعد';
	@override String get aProposTitre => 'حول هذه المساحة';
	@override String get aPropos => 'مساحة تعاون بين المعلّمين لطرح الأسئلة وتبادل الطرق والموارد التعليمية.';
	@override String get titre => 'مشاركة تعليمية فقط';
	@override String get corps => 'هذا المجتمع مخصّص للتبادل المهني بين المعلّمين.';
	@override String get reglesTitre => 'قواعد النشر';
	@override String get pasPublicite => 'لا إعلانات';
	@override String get pasAffilie => 'لا روابط تسويق بالعمولة';
	@override String get pasVente => 'لا بيع لمنتج أو خدمة';
	@override String get pasSollicitation => 'لا التماس تجاري';
	@override String get pasDonnees => 'لا بيانات شخصية لطالب أو عائلة';
	@override String get signaler => 'يُبلَّغ عن المحتوى غير المناسب من قائمة المنشور.';
	@override String get voir => 'عرض القواعد';
}

// Path: com.communaute.entree
class _Traductions$com$communaute$entree$ar extends Traductions$com$communaute$entree$fr {
	_Traductions$com$communaute$entree$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get lecteur => 'فتح مجتمع المعلّمين';
	@override String get detail => 'أسئلة وطرق وموارد بين المعلّمين';
}

// Path: com.communaute.demo
class _Traductions$com$communaute$demo$ar extends Traductions$com$communaute$demo$fr {
	_Traductions$com$communaute$demo$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get avertissement => 'منشور يحتاج إلى مراجعة: إعلان تجاري';
	@override String get lienAffilie => 'رابط تسويق بالعمولة محظور';
	@override String get vente => 'بيع محظور';
	@override String get signalementNonConfirme => 'إبلاغ غير مؤكَّد';
	@override String get choisir => 'اختر حالة لتجربتها كما يراها معلّم.';
	@override String get aujourdhui => 'اليوم، مع الاختصار';
	@override String get nominal => 'ستة منشورات';
	@override String get publication => 'منشور مفتوح';
	@override String get vide => 'لا توجد منشورات';
	@override String get lectureEchouee => 'فشل القراءة';
	@override String get indisponible => 'الخدمة غير متاحة بعد';
	@override String get horsLigne => 'غير متصل';
	@override String get envoiNonConfirme => 'إرسال غير مؤكَّد';
	@override String get moderationIndisponible => 'الإشراف غير متاح';
	@override String get lecteurSeul => 'قراءة فقط، دون نشر';
	@override late final _Traductions$com$communaute$demo$f$ar f = _Traductions$com$communaute$demo$f$ar._(_root);
}

// Path: com.studio.focus
class _Traductions$com$studio$focus$ar extends Traductions$com$studio$focus$fr {
	_Traductions$com$studio$focus$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get entrer => _root.com.socle.lexique.modeFocus;
	@override String get quitter => _root.com.socle.lexique.quitterFocus;
	@override String get actif => 'التركيز مفعّل';
	@override String get actifAvecEchap => 'التركيز مفعّل. اضغط Esc للخروج.';
	@override String get aide => 'أخفِ اللوحات الثانوية للتركيز على هذه المحادثة.';
}

// Path: com.studio.aujourdhui
class _Traductions$com$studio$aujourdhui$ar extends Traductions$com$studio$aujourdhui$fr {
	_Traductions$com$studio$aujourdhui$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => _root.com.socle.lexique.aujourdhui;
	@override String get sousTitre => 'ما يستحق انتباهك في الاستوديو';
	@override late final _Traductions$com$studio$aujourdhui$indicateurs$ar indicateurs = _Traductions$com$studio$aujourdhui$indicateurs$ar._(_root);
	@override late final _Traductions$com$studio$aujourdhui$blocs$ar blocs = _Traductions$com$studio$aujourdhui$blocs$ar._(_root);
	@override late final _Traductions$com$studio$aujourdhui$videsBlocs$ar videsBlocs = _Traductions$com$studio$aujourdhui$videsBlocs$ar._(_root);
	@override String get videTitre => 'لا شيء للمعالجة حاليًا';
	@override String dansCanal({required Object nom}) => 'في ${nom}';
	@override String echeance({required Object date}) => 'الموعد ${date}';
	@override String seTraiteDans({required Object module}) => 'يُعالَج في ${module}';
	@override String ouvrirDans({required Object module, required Object libelle}) => 'فتح في ${module}: ${libelle}';
	@override late final _Traductions$com$studio$aujourdhui$modules$ar modules = _Traductions$com$studio$aujourdhui$modules$ar._(_root);
	@override late final _Traductions$com$studio$aujourdhui$acces$ar acces = _Traductions$com$studio$aujourdhui$acces$ar._(_root);
}

// Path: com.studio.brouillons
class _Traductions$com$studio$brouillons$ar extends Traductions$com$studio$brouillons$fr {
	_Traductions$com$studio$brouillons$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'المسودات';
	@override String get detail => 'الرسائل التي بدأتها في قناة ولم تُرسل بعد. تبقى على هذا الجهاز طوال الجلسة، دون مزامنة.';
	@override String dansCanal({required Object nom}) => 'مسودة في ${nom}';
	@override String get canalInconnu => 'مسودة في قناة';
	@override String get canalIndisponible => 'مسودة في قناة لم تعد متاحة';
	@override String modifie({required Object moment}) => 'عُدّلت في ${moment}';
	@override String reprendre({required Object nom}) => 'متابعة المسودة في ${nom}';
	@override String get videTitre => 'لا توجد مسودات';
	@override String get vide => 'ستظهر هنا أي رسالة بدأتها في قناة ولم تُرسل بعد.';
	@override String tous({required Object nombre}) => 'عرض كل المسودات (${nombre})';
	@override String get restaure => 'استُعيدت المسودة. يمكنك متابعة رسالتك.';
}

// Path: com.studio.navigation
class _Traductions$com$studio$navigation$ar extends Traductions$com$studio$navigation$fr {
	_Traductions$com$studio$navigation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aujourdhui => _root.com.socle.lexique.aujourdhui;
	@override String get brouillons => 'المسودات';
	@override String get canaux => 'القنوات';
	@override String get enregistres => 'العناصر المحفوظة';
}

// Path: com.studio.sections
class _Traductions$com$studio$sections$ar extends Traductions$com$studio$sections$fr {
	_Traductions$com$studio$sections$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get organisation => 'التنظيم';
	@override String get admissionsFamilles => 'القبول والأسر';
	@override String get pedagogieQualite => 'التعليم والجودة';
	@override String get planningRemplacements => 'الجدولة والاستبدال';
	@override String get finance => 'المالية';
	@override String get support => 'الدعم';
	@override String get produitTechnique => 'المنتج والتقنية';
	@override String get direction => 'الإدارة العليا';
}

// Path: com.studio.visibilite
class _Traductions$com$studio$visibilite$ar extends Traductions$com$studio$visibilite$fr {
	_Traductions$com$studio$visibilite$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get restreint => 'محدودة';
	@override String get prive => 'خاصة';
	@override String get visibleDetail => 'مفتوحة لكل الفريق.';
	@override String get restreintDetail => 'مفتوحة لجزء من الفريق، وأنت منهم.';
	@override String get priveDetail => 'قناة خاصة، مفتوحة لأعضائها فقط. وأنت منهم.';
}

// Path: com.studio.canal
class _Traductions$com$studio$canal$ar extends Traductions$com$studio$canal$fr {
	_Traductions$com$studio$canal$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get membresUn => 'عضو واحد';
	@override String membres({required Object nombre}) => '${nombre} أعضاء';
	@override String aide({required Object nom}) => 'اكتب في ${nom}';
	@override String get lectureSeule => 'يمكنك قراءة هذه القناة. الكتابة فيها غير مفتوحة لك.';
	@override String get aucunMessageTitre => 'لا توجد رسائل حاليًا';
	@override String get aucunMessage => 'ستظهر رسائل هذه القناة هنا فور نشرها.';
	@override String get indisponibleTitre => 'القناة غير متاحة';
	@override String get indisponible => 'هذه القناة غير متاحة لك. اختر قناة أخرى من القائمة.';
}

// Path: com.studio.panneau
class _Traductions$com$studio$panneau$ar extends Traductions$com$studio$panneau$fr {
	_Traductions$com$studio$panneau$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'حول القناة';
	@override String get aPropos => 'حول';
	@override String get section => 'القسم';
	@override String get visibilite => 'الظهور';
	@override String get epingles => _root.com.socle.lexique.elementsEpingles;
	@override String get fichiers => 'الملفات الأخيرة';
	@override String get liens => 'روابط مفيدة';
	@override String get vous => 'أنت';
	@override String get parametres => 'إعدادات القناة';
	@override String get parametresDetail => 'سيتاح تعديل الإعدادات مع خدمة الاستوديو.';
	@override String ouvrir({required Object titre}) => 'فتح ${titre}';
	@override String lienExterne({required Object hote}) => 'موقع خارجي: ${hote}';
	@override String get aucunPartageTitre => 'لا شيء مشترك حاليًا';
	@override String get aucunPartage => 'ستظهر هنا العناصر المثبتة والملفات والروابط الخاصة بهذه القناة.';
}

// Path: com.studio.enregistrer
class _Traductions$com$studio$enregistrer$ar extends Traductions$com$studio$enregistrer$fr {
	_Traductions$com$studio$enregistrer$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get enregistrer => _root.com.socle.lexique.enregistrer;
	@override String get retirer => 'إزالة';
	@override String semantiqueEnregistrer({required Object titre}) => 'حفظ ${titre}';
	@override String semantiqueRetirer({required Object titre}) => 'إزالة ${titre} من العناصر المحفوظة';
	@override String ajoute({required Object titre}) => 'أضيف إلى العناصر المحفوظة: ${titre}.';
	@override String retire({required Object titre}) => 'أزيل من العناصر المحفوظة: ${titre}.';
	@override String get nonConfirme => 'لم يتأكد الحفظ بعد. أعد المحاولة بعد لحظة.';
}

// Path: com.studio.enregistres
class _Traductions$com$studio$enregistres$ar extends Traductions$com$studio$enregistres$fr {
	_Traductions$com$studio$enregistres$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get detail => 'القنوات والعناصر التي تحتفظ بها في متناولك. يُفتح كل منها في مكانه الأصلي.';
	@override String get videTitre => 'لا توجد عناصر محفوظة';
	@override String get vide => 'اضغط على حفظ في لوحة قناة لتجد هنا قناة أو عنصرًا.';
	@override String ouvrir({required Object titre}) => 'فتح ${titre}';
	@override String sansDestination({required Object type}) => '${type}‏، لم يعد يُفتح من هنا';
	@override late final _Traductions$com$studio$enregistres$types$ar types = _Traductions$com$studio$enregistres$types$ar._(_root);
}

// Path: com.studio.recherche
class _Traductions$com$studio$recherche$ar extends Traductions$com$studio$recherche$fr {
	_Traductions$com$studio$recherche$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get champ => 'البحث في الاستوديو';
	@override String get aide => 'قناة أو رسالة أو ملف';
	@override String get aucunTitre => 'لا توجد نتائج';
	@override String aucun({required Object texte}) => 'لا شيء يطابق «⁨${texte}⁩» في قنواتك. جرّب كلمة أخرى.';
	@override String get aucunDansFiltre => 'لا شيء من هذا النوع يطابق البحث. اختر الكل لرؤية النتائج الأخرى.';
	@override String get resultatUn => 'نتيجة واحدة';
	@override String resultats({required Object nombre}) => '${nombre} نتائج';
	@override String get filtre => 'نوع النتيجة';
	@override String get tout => 'الكل';
	@override String get canaux => 'القنوات';
	@override String get messages => 'الرسائل';
	@override String get fichiers => 'الملفات';
	@override String dansCanal({required Object canal}) => 'في ${canal}';
	@override String messageDe({required Object auteur, required Object canal}) => '${auteur}‏، في ${canal}';
}

// Path: com.studio.demo
class _Traductions$com$studio$demo$ar extends Traductions$com$studio$demo$fr {
	_Traductions$com$studio$demo$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get focus => 'قناة في وضع التركيز';
	@override String get aujourdhuiVide => 'اليوم دون نشاط';
	@override String horsDemo({required Object module}) => 'في التطبيق، يفتح هذا السطر ${module}. يبقى العرض التجريبي على هذه الصفحة.';
	@override String get choisir => 'اختر حالة لتجربتها.';
	@override String get normale => 'الاستوديو وقنواته';
	@override String get echec => 'إرسال غير مؤكد';
	@override String get horsLigne => 'غير متصل';
	@override String get canalPrive => 'عنوان قناة خاصة غير مفتوحة لك';
	@override String get sansCanaux => 'لا توجد قناة مفتوحة';
	@override String vue({required Object situation}) => 'الحالة: ${situation}';
	@override late final _Traductions$com$studio$demo$f$ar f = _Traductions$com$studio$demo$f$ar._(_root);
}

// Path: com.annonces.publieur
class _Traductions$com$annonces$publieur$ar extends Traductions$com$annonces$publieur$fr {
	_Traductions$com$annonces$publieur$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'إعلان جديد';
	@override late final _Traductions$com$annonces$publieur$etapes$ar etapes = _Traductions$com$annonces$publieur$etapes$ar._(_root);
	@override late final _Traductions$com$annonces$publieur$contexte$ar contexte = _Traductions$com$annonces$publieur$contexte$ar._(_root);
	@override String get champTitre => 'عنوان الإعلان';
	@override String get champTexte => 'نص الإعلان';
	@override late final _Traductions$com$annonces$publieur$nature$ar nature = _Traductions$com$annonces$publieur$nature$ar._(_root);
	@override late final _Traductions$com$annonces$publieur$quand$ar quand = _Traductions$com$annonces$publieur$quand$ar._(_root);
	@override late final _Traductions$com$annonces$publieur$apercu$ar apercu = _Traductions$com$annonces$publieur$apercu$ar._(_root);
	@override String get continuer => 'متابعة';
	@override String get publier => 'نشر الإعلان';
	@override String get programmer => 'جدولة الإعلان';
	@override String get reessayer => 'إعادة محاولة النشر';
	@override String get terminer => 'إنهاء';
	@override String get manqueContenu => 'اكتب عنوانًا ونصًا للمتابعة.';
	@override String get manqueAudience => 'اختر المستلمين للمتابعة.';
	@override String get enCours => 'النشر جارٍ. انتظر التأكيد.';
	@override String get publiee => 'نُشر الإعلان. يستلمه المستلمون.';
	@override String planifiee({required Object date, required Object heure}) => 'جُدول الإعلان ليوم ${date} الساعة ${heure}.';
	@override String get nonConfirmee => 'لم يُؤكَّد هذا الإعلان بعد. تحقّق من الاتصال ثم أعد المحاولة؛ لن يُرسل إلا مرة واحدة.';
	@override String get horsLigne => 'أنت غير متصل، ولم يُؤكَّد هذا الإعلان بعد. أعد المحاولة عند عودة الاتصال.';
	@override String get indisponible => 'نشر الإعلانات غير متاح بعد. عد لاحقًا.';
	@override String get aucuneCibleTitre => 'لا يوجد مستلم متاح';
	@override String get aucuneCible => 'لا يمكنك النشر لأي مستلم حاليًا. اطلب الإذن من الإدارة.';
	@override String get classeRefuseeTitre => 'النشر مقصور';
	@override String get classeRefusee => 'لا يمكنك نشر إعلان لهذا الفصل. اطلب الإذن من الإدارة.';
}

// Path: com.annonces.administration
class _Traductions$com$annonces$administration$ar extends Traductions$com$annonces$administration$fr {
	_Traductions$com$annonces$administration$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get nouvelle => 'إعلان جديد';
	@override String get demo => 'عرض تجريبي';
	@override String get demoDetail => 'بيانات تجريبية: لا رقم حقيقي.';
	@override String get horsLigne => 'أنت غير متصل. لا يمكن تحديث الإعلانات.';
	@override late final _Traductions$com$annonces$administration$indicateurs$ar indicateurs = _Traductions$com$annonces$administration$indicateurs$ar._(_root);
	@override late final _Traductions$com$annonces$administration$publiees$ar publiees = _Traductions$com$annonces$administration$publiees$ar._(_root);
	@override late final _Traductions$com$annonces$administration$planifiees$ar planifiees = _Traductions$com$annonces$administration$planifiees$ar._(_root);
	@override late final _Traductions$com$annonces$administration$matrice$ar matrice = _Traductions$com$annonces$administration$matrice$ar._(_root);
	@override late final _Traductions$com$annonces$administration$moderation$ar moderation = _Traductions$com$annonces$administration$moderation$ar._(_root);
}

// Path: com.annonces.demoPublication
class _Traductions$com$annonces$demoPublication$ar extends Traductions$com$annonces$demoPublication$fr {
	_Traductions$com$annonces$demoPublication$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get lienAdministration => 'إدارة التواصل (الإدارة)';
	@override String get lienPublier => 'نشر إعلان لفصل (المعلم)';
	@override String get toutes => 'الأكاديمية كلها';
	@override String get familles => 'الأسر';
	@override String get enseignants => 'المعلمون';
	@override String get eleves => 'الطلاب';
	@override String get controleurs => 'المراقبون';
	@override String get direction => 'الإدارة';
	@override String get audiencesDirection => 'الأكاديمية كلها، أو جمهور، أو فصل';
	@override String get audiencesEnseignant => 'فصله فقط';
	@override String get vacancesTitre => 'تقويم عطلة الشتاء';
	@override String get vacancesTexte => 'تتوقف الدروس من 21 ديسمبر إلى 5 يناير. تُستأنف الحصص يوم الاثنين 6 يناير في المواعيد المعتادة.';
	@override String get reunionTitre => 'اجتماع المعلمين يوم الخميس';
	@override String get reunionTexte => 'يبدأ الاجتماع التربوي يوم الخميس الساعة 18، عبر الاتصال المرئي. جدول الأعمال في الاستوديو.';
	@override String get recitationTitre => 'تلاوة نهاية الفصل الدراسي';
	@override String get recitationTexte => 'سيقدم فصل النور تلاوة نهاية الفصل الدراسي يوم السبت الساعة 10، عبر الاتصال المرئي.';
	@override String get rentreeTitre => 'استئناف الدروس بعد العطلة';
	@override String get rentreeTexte => 'تُستأنف الحصص يوم الاثنين 6 يناير في المواعيد المعتادة.';
	@override String get signalementAffilie => 'منشور «بطاقات تجويد للطباعة»';
	@override String get extraitAffilie => 'تجدون بطاقاتي عبر هذا الرابط الشريك، خصم 20 % برمزي.';
	@override String get signalementVente => 'منشور «دروس خصوصية متاحة»';
	@override String get extraitVente => 'أقدم دروسًا خصوصية مدفوعة في عطلة نهاية الأسبوع، راسلوني.';
	@override String get signalementHorsSujet => 'رد تحت «تنظيم مراجعة جماعية»';
}

// Path: com.annonces.demo
class _Traductions$com$annonces$demo$ar extends Traductions$com$annonces$demo$fr {
	_Traductions$com$annonces$demo$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get detail => 'عرض تجريبي خارج الإنتاج: بيانات وهمية، ولا يُرسل شيء.';
	@override String get choisirRole => 'اختر الدور المراد عرضه';
	@override late final _Traductions$com$annonces$demo$roles$ar roles = _Traductions$com$annonces$demo$roles$ar._(_root);
	@override String get classeNour => 'فصل النور';
	@override String get classeFajr => 'فصل الفجر';
	@override String get enseignante => 'معلمة الفصل';
	@override late final _Traductions$com$annonces$demo$f$ar f = _Traductions$com$annonces$demo$f$ar._(_root);
}

// Path: comptable.statuts.paiement
class _Traductions$comptable$statuts$paiement$ar extends Traductions$comptable$statuts$paiement$fr {
	_Traductions$comptable$statuts$paiement$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aCalculer => 'قيد الحساب';
	@override String get calcule => 'محسوب';
	@override String get aVerifier => 'للتحقق';
	@override String get infosManquantes => 'معلومات الدفع ناقصة';
	@override String get verificationRequise => 'يلزم التحقق من الدفع';
	@override String get pretAPayer => 'جاهز للدفع';
	@override String get validationRequise => 'تلزم مصادقة إضافية';
	@override String get soumis => 'مُرسَل';
	@override String get enTransit => 'قيد التحويل';
	@override String get reussi => 'ناجح';
	@override String get echoue => 'فاشل';
	@override String get aRelancer => 'للتذكير';
	@override String get annule => 'ملغى';
	@override String get retourne => 'مُسترَد / مُعاد';
	@override String get indisponible => 'غير متاح';
}

// Path: comptable.statuts.encaissement
class _Traductions$comptable$statuts$encaissement$ar extends Traductions$comptable$statuts$encaissement$fr {
	_Traductions$comptable$statuts$encaissement$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get enAttente => 'قيد الانتظار';
	@override String get confirme => 'مؤكَّد';
	@override String get echoue => 'فاشل';
	@override String get rembourse => 'مُسترَد';
	@override String get partiellementRembourse => 'مُسترَد جزئيًا';
	@override String get conteste => 'متنازَع عليه';
	@override String get chargeback => 'استرجاع بنكي';
	@override String get aRapprocher => 'للمطابقة';
	@override String get rapproche => 'مطابَق';
}

// Path: comptable.statuts.rapprochement
class _Traductions$comptable$statuts$rapprochement$ar extends Traductions$comptable$statuts$rapprochement$fr {
	_Traductions$comptable$statuts$rapprochement$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get automatique => 'تلقائي';
	@override String get aVerifier => 'للتحقق';
	@override String get rapproche => 'مطابَق';
	@override String get conflit => 'تعارض';
	@override String get sansCorrespondance => 'بلا مقابل';
	@override String get doublonPotentiel => 'تكرار محتمل';
}

// Path: comptable.statuts.profil
class _Traductions$comptable$statuts$profil$ar extends Traductions$comptable$statuts$profil$fr {
	_Traductions$comptable$statuts$profil$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aucunMoyen => 'لا توجد وسيلة';
	@override String get incomplet => 'غير مكتمل';
	@override String get enVerification => 'قيد التحقق';
	@override String get verifie => 'تم التحقق';
	@override String get suspendu => 'موقوف';
	@override String get actionRequise => 'يلزم إجراء';
	@override String get invitationEnvoyee => 'أُرسلت الدعوة';
}

// Path: comptable.statuts.capacite
class _Traductions$comptable$statuts$capacite$ar extends Traductions$comptable$statuts$capacite$fr {
	_Traductions$comptable$statuts$capacite$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get prisEnCharge => 'مدعوم';
	@override String get nonPrisEnCharge => 'غير مدعوم';
	@override String get temporairementIndisponible => 'غير متاح مؤقتًا';
	@override String get verificationRequise => 'يلزم التحقق';
	@override String get soldePrestataireInsuffisant => 'رصيد مزوّد الدفع غير كافٍ';
}

// Path: comptable.statuts.reserve
class _Traductions$comptable$statuts$reserve$ar extends Traductions$comptable$statuts$reserve$fr {
	_Traductions$comptable$statuts$reserve$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get atteint => 'تحقق الهدف';
	@override String get sousObjectif => 'دون الهدف';
	@override String get depassement => 'تجاوز الهدف';
	@override String get regleInactive => 'القاعدة غير مفعّلة';
	@override String get alimentationPrevue => 'تغذية مقررة';
	@override String get mouvementSensible => 'حركة حساسة';
}

// Path: comptable.statuts.obligation
class _Traductions$comptable$statuts$obligation$ar extends Traductions$comptable$statuts$obligation$fr {
	_Traductions$comptable$statuts$obligation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get brouillon => 'مسودة';
	@override String get aApprouver => 'للاعتماد';
	@override String get approuvee => 'معتمَد';
	@override String get refusee => 'مرفوض';
	@override String get payable => 'قابل للدفع';
	@override String get payee => 'مدفوع';
	@override String get annulee => 'ملغى';
}

// Path: comptable.statuts.remboursement
class _Traductions$comptable$statuts$remboursement$ar extends Traductions$comptable$statuts$remboursement$fr {
	_Traductions$comptable$statuts$remboursement$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get demande => 'مطلوب';
	@override String get approbationRequise => 'يلزم الاعتماد';
	@override String get approuve => 'معتمَد';
	@override String get execute => 'منفَّذ';
	@override String get refuse => 'مرفوض';
}

// Path: comptable.statuts.validation
class _Traductions$comptable$statuts$validation$ar extends Traductions$comptable$statuts$validation$fr {
	_Traductions$comptable$statuts$validation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get enAttente => 'طُلبت المصادقة';
	@override String get validee => 'تمت المصادقة';
	@override String get refusee => 'مرفوضة';
}

// Path: comptable.statuts.raison
class _Traductions$comptable$statuts$raison$ar extends Traductions$comptable$statuts$raison$fr {
	_Traductions$comptable$statuts$raison$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get autoPaiement => 'يلزم أن يعالجه مسؤول آخر';
	@override String get validationRequise => 'تلزم مصادقة إضافية';
	@override String get infosManquantes => 'معلومات الدفع ناقصة';
	@override String get verificationRequise => 'يلزم التحقق من الدفع';
	@override String get horsDelegation => 'خارج التفويض';
	@override String get fournisseurIndisponible => 'المزوّد غير متاح';
	@override String get fondsInsuffisants => 'الأموال غير كافية';
	@override String get doublonPotentiel => 'تكرار محتمل';
	@override String get nonApprouvee => 'التزام غير معتمَد';
	@override String get capaciteAbsente => 'القدرة غير متوفرة';
}

// Path: comptable.paiements.confirmation
class _Traductions$comptable$paiements$confirmation$ar extends Traductions$comptable$paiements$confirmation$fr {
	_Traductions$comptable$paiements$confirmation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titreUn => 'تأكيد الدفعة';
	@override String get titreLot => 'تأكيد الدفعة المجمّعة';
	@override String get titreValidation => 'طلب مصادقة';
	@override String get payerMaintenant => 'ادفع الآن';
	@override String get controleEchoueTitre => 'توقف الفحص';
	@override String get controleEchoue => 'لم يكتمل فحص التحديد. لم يُرسَل أي شيء. أعد تشغيل الفحص.';
	@override String get relancerControle => 'إعادة تشغيل الفحص';
	@override String get montant => 'المبلغ الدقيق';
	@override String get beneficiaire => 'المستفيد';
	@override String get devise => 'العملة';
	@override String get type => 'النوع';
	@override String get periode => 'الفترة / الموضوع';
	@override String get prestataire => 'مزوّد الدفع المقرر';
	@override String get prestataireAucun => 'لم يُرجعه المصدر';
	@override String get taux => 'سعر الصرف';
	@override String tauxDate({required Object taux, required Object date}) => '${taux}، بتاريخ ${date}';
	@override String get frais => 'رسوم مزوّد الدفع';
	@override String get change => 'تكلفة الصرف';
	@override String get montantEnvoye => 'إجمالي المُرسَل';
	@override String get montantRecu => 'المبلغ المتوقع استلامه';
	@override String get controlesTitre => 'الفحوص المجتازة';
	@override String get controlesPhrase => 'المبلغ محسوب، ووسيلة الدفع متحقَّق منها، والتفويض والتكرارات مفحوصة من المصدر. لن تُرسَل إلا المدفوعات الجاهزة.';
	@override String get sensiblePhrase => 'هذه الدفعة حساسة: يجب أن يصادق عليها شخص مخوَّل آخر. اطلب المصادقة، فهي لا تُرسَل قبلها.';
	@override String prets({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		one: 'دفعة جاهزة واحدة',
		two: 'دفعتان جاهزتان',
		few: '${n} دفعات جاهزة',
		other: '${n} دفعة جاهزة',
	);
	@override String exclus({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		one: 'دفعة مستبعدة واحدة',
		two: 'دفعتان مستبعدتان',
		few: '${n} دفعات مستبعدة',
		other: '${n} دفعة مستبعدة',
	);
	@override String get total => 'إجمالي المدفوعات الجاهزة';
	@override String get beneficiairesCle => 'المستفيدون';
	@override String beneficiaires({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		one: 'مستفيد واحد',
		two: 'مستفيدان',
		few: '${n} مستفيدين',
		other: '${n} مستفيدًا',
	);
	@override String get devises => 'العملات';
	@override String get prestataires => 'مزوّدو الدفع';
	@override String get plafond => 'التفويض المتبقي';
	@override String get exclusTitre => 'مستبعدة من هذه الدفعة المجمّعة: لن تُرسَل';
	@override String get aucunPretTitre => 'لا توجد دفعة جاهزة';
	@override String get aucunPret => 'لن يُرسَل أي شيء. افتح كل دفعة مستبعدة لإزالة سببها، ثم أعد تشغيل الفحص.';
	@override String get erreursTitre => 'أخطاء أرجعها الفحص';
	@override String confirmerUn({required Object montant}) => 'تأكيد دفع ${montant}';
	@override String confirmerLot({required num n, required Object montants}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		one: 'تأكيد الدفعة الجاهزة بمبلغ ${montants}',
		two: 'تأكيد الدفعتين الجاهزتين: ${montants}',
		few: 'تأكيد ${n} دفعات جاهزة: ${montants}',
		other: 'تأكيد ${n} دفعة جاهزة: ${montants}',
	);
	@override String get demanderValidation => 'طلب المصادقة';
	@override String get annuler => 'إلغاء';
	@override String get fermer => 'إغلاق';
	@override String get soumisTitre => 'أُرسلت إلى مزوّد الدفع';
	@override String get soumisPhrase => 'الدفعة المُرسَلة لم تُستلَم بعد: حالتها تأتي من متابعة مزوّد الدفع. حدّث المتابعة لترى تقدمها.';
	@override String get actualiser => 'تحديث المتابعة';
	@override String get suiviEchoue => 'تعذرت قراءة المتابعة. تبقى الدفعة مُرسَلة: حدّث مرة أخرى بعد قليل.';
	@override String get referenceCle => 'مرجع مزوّد الدفع';
	@override String get recalculeTitre => 'أُعيد حساب المبلغ';
	@override String get recalculePhrase => 'تغيّر حساب في المصدر منذ الفحص. لم يُرسَل أي شيء. أعد تشغيل الفحص لتأكيد المبلغ الجديد.';
	@override String nouveauMontant({required Object nom}) => 'المبلغ الجديد لـ ${nom}';
	@override String get refusTitre => 'رفض المصدر الدفعة';
	@override String get refusDejaSoumis => 'سبق إرسال هذه الدفعة: لن يُعاد إرسال أي شيء. تابعها من تبويب المدفوعات الجارية.';
	@override String get refusHorsDelegation => 'يتجاوز المجموع تفويضك، لكل مستفيد أو لكل فترة. لم يُرسَل أي شيء. أعد تشغيل الفحص: ستُستبعد المدفوعات المعنية.';
	@override String get refusPerime => 'انتهت صلاحية الفحص. لم يُرسَل أي شيء. أعد تشغيل الفحص قبل التأكيد.';
	@override String get refusFournisseur => 'أصبح مزوّد الدفع غير متاح. لم يُرسَل أي شيء. أعد تشغيل الفحص بعد قليل.';
	@override String get inconnuTitre => 'نتيجة غير معروفة';
	@override String get inconnuPhrase => 'لم يصلنا الرد: ربما أُرسلت الدفعة. أعد المحاولة: يُعاد إرسال الطلب نفسه ولن يُنفَّذ إلا مرة واحدة.';
	@override String get reessayer => 'إعادة المحاولة';
	@override String get validationDemandeeTitre => 'طُلبت المصادقة';
	@override String get validationDemandeePhrase => 'سيصادق شخص مخوَّل آخر على هذه الدفعة. لن تُرسَل قبل قراره.';
	@override String get validationEchouee => 'لم يكتمل طلب المصادقة. أعد المحاولة: لن يُسجَّل إلا مرة واحدة.';
}

// Path: comptable.paiements.filtres
class _Traductions$comptable$paiements$filtres$ar extends Traductions$comptable$paiements$filtres$fr {
	_Traductions$comptable$paiements$filtres$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get tous => 'الكل';
	@override String get enseignants => 'المعلمون';
	@override String get contractuels => 'المتعاقدون';
	@override String get statut => 'الحالة';
	@override String get tousStatuts => 'كل الحالات';
	@override String get prets => 'جاهزة';
	@override String get infos => 'معلومات ناقصة';
	@override String get verification => 'التحقق';
	@override String get validation => 'المصادقة';
	@override String get retard => 'متأخرة';
	@override String get classe => 'الفصل';
	@override String get toutesClasses => 'كل الفصول';
	@override String get periode => 'الفترة';
	@override String get toutesPeriodes => 'كل الفترات';
	@override String get effacer => 'مسح عوامل التصفية';
}

// Path: comptable.paiements.colonnes
class _Traductions$comptable$paiements$colonnes$ar extends Traductions$comptable$paiements$colonnes$fr {
	_Traductions$comptable$paiements$colonnes$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get beneficiaire => 'المستفيد';
	@override String get type => 'النوع';
	@override String get periode => 'الفترة / الموضوع';
	@override String get montant => 'المبلغ';
	@override String get destination => 'الوجهة';
	@override String get echeance => 'الاستحقاق';
	@override String get statut => 'الحالة';
	@override String get action => 'الإجراء';
}

// Path: comptable.paiements.types
class _Traductions$comptable$paiements$types$ar extends Traductions$comptable$paiements$types$fr {
	_Traductions$comptable$paiements$types$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get enseignant => 'معلم';
	@override String get contractuel => 'متعاقد';
}

// Path: comptable.paiements.actions
class _Traductions$comptable$paiements$actions$ar extends Traductions$comptable$paiements$actions$fr {
	_Traductions$comptable$paiements$actions$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get voir => 'عرض';
	@override String get payer => 'دفع';
	@override String get demanderValidation => 'طلب المصادقة';
	@override String get relancer => 'تذكير';
	@override String get signalerEcart => 'الإبلاغ عن فرق';
	@override String selectionner({required Object nom}) => 'تحديد دفعة ${nom}';
	@override String get selectionnerPrets => 'تحديد كل المدفوعات الجاهزة';
	@override String get payerSelection => 'دفع المحدد';
	@override String get viderSelection => 'إلغاء التحديد';
	@override String get voirProfil => 'عرض ملف الدفع';
}

// Path: comptable.paiements.vide
class _Traductions$comptable$paiements$vide$ar extends Traductions$comptable$paiements$vide$fr {
	_Traductions$comptable$paiements$vide$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get message => 'لا توجد مدفوعات للتنفيذ.';
	@override String get invitation => 'تظهر الالتزامات هنا بمجرد حسابها في المصدر.';
	@override String get filtreMessage => 'لا توجد دفعة تطابق عوامل التصفية هذه.';
	@override String get filtreInvitation => 'امسح عوامل التصفية لرؤية كل المدفوعات مجددًا.';
}

// Path: comptable.paiements.detail
class _Traductions$comptable$paiements$detail$ar extends Traductions$comptable$paiements$detail$fr {
	_Traductions$comptable$paiements$detail$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get total => 'الإجمالي المستحق';
	@override String get lignes => 'تفاصيل الحساب';
	@override String get ligneTotal => 'الإجمالي';
	@override String source({required Object source}) => 'المصدر: ${source}';
	@override String auteur({required Object auteur}) => 'أضافه ${auteur}';
	@override String get voirSource => 'عرض المصدر';
	@override String get methode => 'وسيلة الدفع';
	@override String get informations => 'المعلومات';
	@override String get type => 'النوع';
	@override String get periode => 'الفترة / الموضوع';
	@override String get echeance => 'الاستحقاق';
	@override String get prestataire => 'مزوّد الدفع المقرر';
	@override String get preuve => 'الإثبات';
	@override String get classes => 'الفصول';
	@override String get version => 'إصدار الحساب';
	@override String get historique => 'السجل';
	@override String get historiqueVide => 'لا توجد عملية مسجلة لهذه الدفعة.';
	@override String get encart => 'لا يستطيع المحاسب تعديل المبلغ ولا بيانات الدفع الخاصة بالمستفيد.';
	@override String alerteMethodeRecente({required Object date}) => 'عُدّلت وسيلة الدفع في ${date}: تلزم مصادقة إضافية قبل أي دفع.';
	@override String get alerteLieeOperateur => 'المستفيد مرتبط بالمنفِّذ: تلزم مصادقة إضافية قبل أي دفع.';
	@override String get alerteEchec => 'فشل آخر إرسال لدى مزوّد الدفع. تحقق من وسيلة الدفع قبل محاولة جديدة.';
	@override String get alerteInfos => 'ليست لدى المستفيد بعد وسيلة دفع مكتملة. ذكّره من ملف الدفع الخاص به.';
	@override String get alerteTitre => 'ما يجب معرفته قبل الدفع';
	@override String get autoPaiementPhrase => 'هذه الدفعة تخصك: سيعالجها شخص مخوَّل آخر. لا يمكن لأحد تنفيذ دفعته بنفسه.';
	@override String get introuvableTitre => 'هذه الدفعة غير موجودة.';
	@override String get introuvablePhrase => 'عد إلى قائمة المدفوعات للتنفيذ لاختيار دفعة أخرى.';
}

// Path: comptable.paiements.ecart
class _Traductions$comptable$paiements$ecart$ar extends Traductions$comptable$paiements$ecart$fr {
	_Traductions$comptable$paiements$ecart$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الإبلاغ عن فرق';
	@override String get phrase => 'اختر السطر وما الخطأ فيه. يتم التصحيح في المصدر، ثم يُعاد حساب المبلغ.';
	@override String get ligne => 'السطر المعني';
	@override String get motif => 'ما الخطأ';
	@override late final _Traductions$comptable$paiements$ecart$motifs$ar motifs = _Traductions$comptable$paiements$ecart$motifs$ar._(_root);
	@override String get envoyer => 'إرسال البلاغ';
	@override String get annuler => 'إلغاء';
	@override String envoye({required Object date}) => 'أُبلغ عن الفرق في ${date}. يبقى المبلغ كما في المصدر حتى إعادة الحساب.';
	@override String get erreurEnvoi => 'لم يكتمل البلاغ. أعد المحاولة: لن يُسجَّل إلا مرة واحدة.';
}

// Path: comptable.tresorerie.descriptions
class _Traductions$comptable$tresorerie$descriptions$ar extends Traductions$comptable$tresorerie$descriptions$fr {
	_Traductions$comptable$tresorerie$descriptions$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get fondsClientsEngages => 'أموال مقبوضة مرتبطة بخدمات لم تُستحق بعد.';
	@override String get paieADecaisser => 'أجور محسوبة ومستحقة.';
	@override String get chargesEssentielles => 'البنية التحتية والاشتراكات الضرورية والوظائف الثابتة.';
	@override String get taxesObligations => 'مخصص للالتزامات الضريبية أو الاجتماعية أو التنظيمية.';
	@override String get reserveStrategique => 'صندوق الاستمرارية والأمان.';
	@override String get enTransit => 'أموال ملتزَم بها في عملية لم تُؤكَّد بعد.';
	@override String get tresorerieLibre => 'ما يبقى متاحًا فعلًا بعد التخصيصات المحمية.';
}

// Path: comptable.tresorerie.regle
class _Traductions$comptable$tresorerie$regle$ar extends Traductions$comptable$tresorerie$regle$fr {
	_Traductions$comptable$tresorerie$regle$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get desactivee => 'معطّلة';
	@override String get montantFixe => 'مبلغ ثابت في كل موعد';
	@override String pourcentage({required Object pourcent}) => '${pourcent} % من كل مقبوض مُثبَّت';
	@override String get jusquAObjectif => 'الإكمال حتى المبلغ المستهدف';
	@override String get proposee => 'اقتراح يتطلب تأكيدك';
}

// Path: comptable.tresorerie.cadences
class _Traductions$comptable$tresorerie$cadences$ar extends Traductions$comptable$tresorerie$cadences$fr {
	_Traductions$comptable$tresorerie$cadences$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get clotureCycle => 'عند كل إقفال دورة';
	@override String get hebdomadaire => 'كل أسبوع';
	@override String get mensuelle => 'كل شهر';
	@override String get apresEncaissementConsolide => 'بعد كل مقبوض مُثبَّت';
	@override String get manuelle => 'يدوية';
}

// Path: comptable.tresorerie.transfert
class _Traductions$comptable$tresorerie$transfert$ar extends Traductions$comptable$tresorerie$transfert$fr {
	_Traductions$comptable$tresorerie$transfert$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'حركة بين الصناديق';
	@override String get choix => 'حركة تسمح بها السياسة';
	@override String couple({required Object origine, required Object destination}) => '${origine} ← ${destination}';
	@override String get delegable => 'نحو الحماية: تُنفَّذ حسب تفويضك.';
	@override String get sensible => 'تلزم مصادقة إضافية: يقرر شخص آخر، ولا يخرج شيء من الصندوق قبل ذلك.';
	@override String get montant => 'المبلغ';
	@override String montantAide({required Object devise}) => 'بوحدات صحيحة، ${devise}.';
	@override String get montantPropose => 'المبلغ الذي تقترحه السياسة';
	@override String get utiliserPropose => 'استخدام المبلغ المقترح';
	@override String get erreurMontant => 'أدخل مبلغًا صحيحًا أكبر من صفر.';
	@override String get verifier => 'مراجعة الحركة';
	@override String get recapPhrase => 'راجع المبلغ الدقيق قبل الإرسال.';
	@override String get de => 'من';
	@override String get vers => 'إلى';
	@override String get confirmer => 'تأكيد الحركة';
	@override String get demanderValidation => 'طلب المصادقة';
	@override String get modifier => 'تعديل الحركة';
	@override String get fermer => 'إغلاق';
	@override String get executeTitre => 'نفّذ المصدر الحركة';
	@override String get executePhrase => 'سجّلها السجل. يُعاد قراءة الأرصدة المعروضة.';
	@override String reference({required Object reference}) => 'المرجع: ${reference}';
	@override String get validationTitre => 'طُلبت المصادقة';
	@override String get validationPhrase => 'يجب أن يقرر شخص آخر. يبقى الصندوق المصدر دون تغيير حتى ذلك الحين.';
	@override String get refusTitre => 'رفض المصدر الحركة';
	@override String refusPhrase({required Object raison}) => 'السبب: ${raison}. لم يُنقَل أي شيء.';
	@override String get erreurEnvoiTitre => 'لم يصل الرد';
	@override String get erreurEnvoi => 'لم يصل الرد. راجع السجل قبل إعادة المحاولة: لن تُحسب الحركة نفسها مرتين أبدًا.';
	@override String get indisponible => 'الحركات بين الصناديق غير مربوطة بالخادم بعد. لم يُنقَل أي شيء.';
	@override String get aucunCouple => 'لا تسمح السياسة بأي حركة لحسابك.';
}

// Path: comptable.encaissements.rap
class _Traductions$comptable$encaissements$rap$ar extends Traductions$comptable$encaissements$rap$fr {
	_Traductions$comptable$encaissements$rap$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get vueTransactions => 'للمطابقة';
	@override String get vueRemboursements => 'الاستردادات';
	@override String get natPaiementAttendu => 'دفعة متوقعة';
	@override String get natTransaction => 'معاملة مزوّد الدفع';
	@override String get natMensualite => 'رصيد أو قسط شهري';
	@override String get natFrais => 'رسوم';
	@override String get natRemboursement => 'استرداد';
	@override String get natPayout => 'صرف دفعة';
	@override String get natPreuve => 'إثبات';
	@override String natureDate({required Object nature, required Object date}) => '${nature} · ${date}';
	@override String get choisirTitre => 'اختر معاملة.';
	@override String get choisirPhrase => 'تُفتح هنا المطابقات المقترحة لها وحالتها وسجلها.';
	@override String get videTitre => 'لا شيء للمطابقة.';
	@override String get videPhrase => 'كل معاملة مستلَمة مرتبطة بالفعل بما كان ينتظرها.';
	@override String get videFiltreTitre => 'لا توجد معاملة بهذه الحالة.';
	@override String get videFiltrePhrase => 'اختر «الكل» لرؤية كل المعاملات.';
	@override String get voirToutes => 'عرض كل المعاملات';
	@override String ouvrirLecteur({required Object libelle}) => 'فتح مطابقة ${libelle}';
	@override String get candidats => 'المطابقات المقترحة';
	@override String get candidatsAucun => 'لا يقترح المصدر أي مطابقة لهذه المعاملة.';
	@override String relieA({required Object libelle}) => 'مرتبطة بـ: ${libelle}';
	@override String get rapprocher => 'مطابقة';
	@override String rapprocherLecteur({required Object libelle}) => 'المطابقة مع ${libelle}';
	@override String get doublonTitre => 'تكرار محتمل';
	@override String get doublonPhrase => 'تشبه هذه المعاملة معاملة أخرى مستلَمة سابقًا. تحقق قبل المطابقة: لا يُقبل التكرار أبدًا بصمت.';
	@override String get marquerDoublon => 'وضع علامة تكرار';
	@override String resultat({required Object etat}) => 'الحالة التي أرجعها المصدر: ${etat}';
	@override String get erreurEnvoi => 'لا نعلم إن كانت العملية قد سُجّلت. حدّث القائمة قبل إعادة المحاولة.';
	@override String get actualiser => 'تحديث';
	@override String get journal => 'سجل المعاملة';
	@override String get journalVide => 'لا توجد عملية مسجلة لهذه المعاملة.';
	@override String get beneficiaire => 'المستفيد';
	@override String get motif => 'السبب';
	@override String get montant => 'المبلغ';
	@override String get source => 'المصدر';
	@override String demandeLe({required Object date}) => 'طُلب في ${date}';
	@override String get approbationRequise => 'تشترط السياسة الاعتماد';
	@override String get approbationNon => 'دون اعتماد حسب السياسة';
	@override String get politiqueNote => 'قواعد الاسترداد جزء من سياسة المالية. هنا نطبّقها ولا نعيد كتابتها.';
	@override String get executer => 'تنفيذ الاسترداد';
	@override String executerLecteur({required Object beneficiaire}) => 'تنفيذ استرداد ${beneficiaire}';
	@override String get executerTitre => 'تنفيذ هذا الاسترداد؟';
	@override String get executerPhrase => 'المبلغ والشروط مصدرها سياسة المالية. سيؤكد مزوّد الدفع التنفيذ.';
	@override String get remboursementsVideTitre => 'لا يوجد استرداد ولا رصيد دائن جارٍ.';
	@override String get journalRemboursement => 'سجل الاسترداد';
	@override String get journalRemboursementVide => 'لا توجد عملية مسجلة لهذا الاسترداد.';
	@override String get erreurEnvoiTitre => 'عملية غير مؤكدة';
	@override String get remboursementsVidePhrase => 'ستظهر هنا طلبات الاسترداد مع سببها وحالتها.';
}

// Path: comptable.beneficiaires.profil
class _Traductions$comptable$beneficiaires$profil$ar extends Traductions$comptable$beneficiaires$profil$fr {
	_Traductions$comptable$beneficiaires$profil$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String carteTitre({required Object nom}) => 'ملف الدفع الخاص بـ ${nom}';
	@override String get etat => 'حالة الملف';
	@override String get derniereModification => 'آخر تعديل';
	@override String get capacite => 'قدرة الدفع في هذا المسار';
	@override String get capaciteNonEvaluee => 'لم تُقيَّم بعد';
	@override String get enAttente => 'مدفوعات تنتظر هذا الملف';
	@override String proprietaire({required Object nom}) => 'وحده ${nom} يمكنه إدخال بيانات الدفع الخاصة به أو تعديلها. أنت ترى نسخة مخفية منها.';
	@override String get historiqueTitre => 'سجل المدفوعات';
	@override String get historiqueVide => 'لم تُصرف أي دفعة لهذا المستفيد حتى الآن.';
	@override String get journalTitre => 'سجل الملف';
	@override String get journalVide => 'لا يوجد أي تعديل مسجل على هذا الملف حتى الآن.';
	@override String get actionsTitre => 'ما العمل لهذا الملف';
	@override String relancer({required Object nom}) => 'تذكير ${nom}';
	@override String get relancerDetail => 'يفتح محادثة «ملف الدفع» برسالة معدّة مسبقًا، في رسائل العمل.';
	@override String demanderMiseAJour({required Object nom}) => 'طلب تحديث من ${nom}';
	@override String suspendre({required Object nom}) => 'إيقاف مدفوعات ${nom}';
	@override String reprendre({required Object nom}) => 'استئناف مدفوعات ${nom}';
	@override String externe({required Object nom}) => 'ليس لدى ${nom} حساب Rewayah: تتيح له دعوة آمنة إدخال وسيلته بنفسه. أعد إرسالها من التزامه، في المتعاقدين.';
	@override String get voirContractuels => 'عرض التزامات المتعاقدين';
	@override String get aucuneAction => 'لا يوجد أي إجراء مفتوح على هذا الملف: إنه محدَّث.';
	@override String get filTitre => 'محادثة «ملف الدفع»';
	@override String relanceRefusee({required Object nom}) => 'لا يمكن فتح محادثة «ملف الدفع» مع ${nom}: لا تسمح Rewayah بذلك لهذا المستفيد. اطلب تحديثًا بدلًا من ذلك، أو أبلغ الإدارة.';
	@override String get messageModele => 'يجب إكمال معلومات الدفع الخاصة بك قبل دفعتك القادمة. يمكنك إضافتها من مساحتك الشخصية.';
	@override String miseAJourDemandee({required Object nom}) => 'سُجّل طلب التحديث لـ ${nom}.';
	@override String suspendus({required Object nom}) => 'أُوقفت مدفوعات ${nom}: لن تُصرف أي دفعة ما لم تُستأنف.';
	@override String repris({required Object nom}) => 'استُؤنفت مدفوعات ${nom}.';
	@override String get erreurAction => 'لم يكتمل الإجراء. تحقق من اتصالك، ثم أعد المحاولة.';
	@override String get erreurIndisponible => 'هذا الإجراء غير مربوط بعد بالخدمة التي تعالجه. أعد المحاولة لاحقًا.';
	@override String suspensionTitre({required Object nom}) => 'إيقاف مدفوعات ${nom}؟';
	@override String get suspensionContexte => 'لن تُصرف أي دفعة لهذا المستفيد ما لم تستأنفها. لن تتغير بياناته. اختر السبب: سيُدوَّن في سجل الملف.';
	@override String get motifVerifier => 'بيانات تحتاج إلى تحقق';
	@override String get motifVerifierDetail => 'تبدو الوسيلة غير صحيحة أو تعذّر تأكيدها.';
	@override String get motifAnomalie => 'خلل مُبلَّغ عنه';
	@override String get motifAnomalieDetail => 'فشلت دفعة حديثة أو أُبلغ عن فرق.';
	@override String get motifDemande => 'طلب من المستفيد';
	@override String get motifDemandeDetail => 'طلب المستفيد عدم استلام أي دفعة حاليًا.';
	@override String get motifRequis => 'اختر سببًا للمتابعة.';
}

// Path: comptable.beneficiaires.recevoir
class _Traductions$comptable$beneficiaires$recevoir$ar extends Traductions$comptable$beneficiaires$recevoir$fr {
	_Traductions$comptable$beneficiaires$recevoir$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get rubrique => 'المدفوعات';
	@override String get ligneDetail => 'وسائل الدفع الخاصة بك، تديرها أنت وحدك.';
	@override String get noticeDetail => 'أضف وسيلة دفع لتتمكن الأكاديمية من صرف دفعتك القادمة.';
	@override String get phraseAucunMoyen => 'ليست لديك أي وسيلة دفع بعد. أضف واحدة لاستلام دفعاتك.';
	@override String get phraseIncomplet => 'وسيلة الدفع الخاصة بك غير مكتملة. أكملها لاستلام دفعتك القادمة.';
	@override String get phraseEnVerification => 'وسيلتك الجديدة قيد التحقق. تُحدَّث حالتها هنا.';
	@override String get phraseVerifie => 'تم التحقق من وسيلة الدفع الخاصة بك. ستُرسَل إليها دفعاتك القادمة.';
	@override String get phraseSuspendu => 'دفعاتك موقوفة. تواصل مع الأكاديمية لمعرفة السبب.';
	@override String get phraseActionRequise => 'مطلوب تحديث وسيلة الدفع الخاصة بك. استبدلها لاستلام دفعتك القادمة.';
	@override String get phraseInvitationEnvoyee => 'أُرسلت إليك دعوة آمنة. أضف وسيلة الدفع الخاصة بك لإكمالها.';
	@override String get suspenduTemporairement => 'دفعاتك موقوفة ريثما يتم التحقق من وسيلتك الجديدة: هذه حماية من الاحتيال.';
	@override String get mesMethodes => 'وسائل الدفع الخاصة بي';
	@override String get preferee => 'الوسيلة المفضلة';
	@override String get inactive => 'وسيلة سابقة، محفوظة غير مفعّلة';
	@override String choisirPreferee({required Object methode}) => 'جعل ${methode} وسيلتي المفضلة';
	@override String remplacer({required Object methode}) => 'استبدال ${methode}';
	@override String supprimer({required Object methode}) => 'حذف ${methode}';
	@override String supprimerQuestion({required Object methode}) => 'حذف ${methode}؟';
	@override String get supprimerConsequence => 'لن تستلم بعد الآن أي دفعة على هذه الوسيلة. إن كانت الوحيدة، فستنتظر دفعتك القادمة وسيلة جديدة.';
	@override String get ajouter => 'إضافة وسيلة دفع';
	@override String get ajoutTitre => 'إضافة وسيلة دفع';
	@override String remplacementTitre({required Object methode}) => 'استبدال ${methode}';
	@override String get ajoutContexte => 'اختر نوع الوسيلة. ستُدخل بعد ذلك بياناتك في مساحة آمنة: التطبيق لا يراها ولا يحتفظ بها.';
	@override String get continuerSaisie => 'المتابعة إلى الإدخال الآمن';
	@override String get typeRequis => 'اختر نوع وسيلة للمتابعة.';
	@override String get aucunType => 'لا يُقترح أي نوع وسيلة حاليًا. تواصل مع الأكاديمية لفتح نوع.';
	@override String get verificationAnnoncee => 'يُتحقَّق من كل تغيير قبل الدفعة القادمة.';
	@override String get ajoutee => 'أُضيفت الوسيلة: إنها قيد التحقق.';
	@override String get remplacee => 'سُجّلت الوسيلة الجديدة: إنها قيد التحقق.';
	@override String get supprimee => 'حُذفت الوسيلة.';
	@override String get prefereeChoisie => 'حُدّثت الوسيلة المفضلة.';
	@override String get erreurAction => 'لم يكتمل التغيير. تحقق من اتصالك، ثم أعد المحاولة.';
	@override String get erreurIndisponible => 'هذا التغيير غير مربوط بعد بخدمة الدفع. أعد المحاولة لاحقًا.';
	@override String get journalTitre => 'سجل تغييراتي';
	@override String get journalVide => 'لا يوجد أي تغيير مسجل حتى الآن.';
	@override String get seulVous => 'أنت وحدك يمكنك تعديل هذه المعلومات: لا المحاسبة ولا الإدارة تستطيع ذلك نيابة عنك.';
	@override String get titre => 'استلام مدفوعاتي';
	@override String get sousTitre => 'بيانات الدفع الخاصة بك، لا يعدّلها أحد سواك.';
	@override String get notice => 'معلومات دفع يجب إكمالها';
	@override String get configurer => 'إعداد مدفوعاتي';
}

// Path: comptable.validation.natures
class _Traductions$comptable$validation$natures$ar extends Traductions$comptable$validation$natures$fr {
	_Traductions$comptable$validation$natures$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get payoutSensible => 'دفعة حساسة';
	@override String get retraitReserve => 'السحب من الاحتياطي الاستراتيجي';
	@override String get obligationAApprouver => 'التزام لمرة واحدة';
	@override String get payoutDuComptable => 'أجر المحاسب';
	@override String get sortieCoffreProtege => 'الخروج من صندوق محمي';
}

// Path: comptable.validation.detail
class _Traductions$comptable$validation$detail$ar extends Traductions$comptable$validation$detail$fr {
	_Traductions$comptable$validation$detail$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'طلب مصادقة';
	@override String get nature => 'النوع';
	@override String get objet => 'الموضوع';
	@override String get demandeur => 'طلبه';
	@override String get date => 'تاريخ الطلب';
	@override String get raison => 'السبب';
	@override String get montant => 'المبلغ الدقيق';
	@override String get etat => 'الحالة';
	@override String get historique => 'السجل';
	@override String get historiqueVide => 'لا يوجد أي إدخال حتى الآن.';
}

// Path: comptable.validation.motifs
class _Traductions$comptable$validation$motifs$ar extends Traductions$comptable$validation$motifs$fr {
	_Traductions$comptable$validation$motifs$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get coordonnees => 'بيانات المستفيد تحتاج إلى تحقق';
	@override String get montant => 'المبلغ يحتاج إلى تحقق في المصدر';
	@override String get justificatif => 'المستند المؤيِّد ناقص أو غير مقروء';
	@override String get reserve => 'خارج سياسة الاحتياطي';
	@override String get reporter => 'يؤجَّل إلى الدورة القادمة';
	@override String get autre => 'آخر';
}

// Path: comptable.direction.reservePanneau
class _Traductions$comptable$direction$reservePanneau$ar extends Traductions$comptable$direction$reservePanneau$fr {
	_Traductions$comptable$direction$reservePanneau$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get intro => 'أنت تحدد السياسة؛ والمحاسب يقرؤها وينفّذها. كل تسجيل يُنشئ إصدارًا جديدًا يُحفظ في السجل.';
	@override String get objectifTitre => 'هدف الاحتياطي';
	@override String get objectifDetail => 'ما يجب أن يبلغه الاحتياطي الاستراتيجي.';
	@override String get modeFixe => 'مبلغ ثابت';
	@override String get modeFixeDetail => 'مبلغ محدد تختاره أنت.';
	@override String get modeMois => 'تغطية بالأشهر';
	@override String get modeMoisDetail => 'عدد من أشهر المصاريف الأساسية.';
	@override String get montantCible => 'المبلغ المستهدف';
	@override String get montantCibleDetail => 'المبلغ الذي يجب أن يبلغه الاحتياطي الاستراتيجي.';
	@override String get nombreMois => 'عدد أشهر التغطية';
	@override String get nombreMoisDetail => 'كم شهرًا من المصاريف الأساسية يجب أن يغطي الاحتياطي.';
	@override String get alimentationTitre => 'التغذية التلقائية';
	@override String get alimentationDetail => 'كيف يمتلئ الاحتياطي دون تدخل من المحاسب.';
	@override late final _Traductions$comptable$direction$reservePanneau$regle$ar regle = _Traductions$comptable$direction$reservePanneau$regle$ar._(_root);
	@override String get montantAuto => 'المبلغ المخصَّص';
	@override String get montantAutoDetail => 'المبلغ المخصَّص للاحتياطي في كل موعد.';
	@override String get pourcentageAuto => 'حصة المقبوض المُثبَّت';
	@override String get pourcentageAutoDetail => 'الحصة المخصَّصة للاحتياطي في كل موعد.';
	@override String get cadenceTitre => 'الوتيرة';
	@override String get cadenceDetail => 'متى تتم التغذية.';
	@override late final _Traductions$comptable$direction$reservePanneau$cadence$ar cadence = _Traductions$comptable$direction$reservePanneau$cadence$ar._(_root);
	@override String get seuilTitre => 'التنبيه';
	@override String get seuil => 'حد التنبيه';
	@override String get seuilDetail => 'دون هذه الحصة من الهدف، يُشار إلى الاحتياطي بأنه «دون الهدف». اتركه فارغًا لعدم تحديد أي حد.';
	@override String get seuilIndice => 'بلا حد';
	@override String get retraitTitre => 'السحب';
	@override String get retraitSwitch => 'السحب يتطلب مصادقة إضافية';
	@override String get retraitSwitchDetail => 'إخراج المال من الاحتياطي عملية حساسة: يصادق عليها شخص غير صاحب الطلب.';
}

// Path: comptable.direction.delegationPanneau
class _Traductions$comptable$direction$delegationPanneau$ar extends Traductions$comptable$direction$delegationPanneau$fr {
	_Traductions$comptable$direction$delegationPanneau$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get intro => 'تحدد مرة واحدة ما يستطيع المحاسب تنفيذه وحده. وكل ما عدا ذلك يعود إليك.';
	@override String get pouvoirsTitre => 'ما يستطيع المحاسب فعله وحده';
	@override String get paiementsStandards => 'دفع المدفوعات العادية';
	@override String get paiementsStandardsDetail => 'الدفعة بالمبلغ المحسوب، نحو وسيلة متحقَّق منها، تُرسَل دون مصادقة يومية.';
	@override String get remboursement => 'تنفيذ استرداد عادي';
	@override String get remboursementDetail => 'الاسترداد المطابق للقاعدة يُنفَّذ دون مصادقة.';
	@override String get alimentationReserve => 'تغذية الاحتياطي الاستراتيجي';
	@override String get alimentationReserveDetail => 'حركة نحو الاحتياطي، مطابقة لسياسته.';
	@override String get plafondsTitre => 'الحدود القصوى';
	@override String get plafondsDetail => 'بعد تجاوز الحد الأقصى، تتطلب الدفعة مصادقتك. اتركه فارغًا لعدم تحديد أي حد.';
	@override String get plafondTransaction => 'الحد الأقصى لكل معاملة';
	@override String get plafondTransactionDetail => 'أقصى مبلغ لدفعة واحدة.';
	@override String get plafondLot => 'الحد الأقصى لكل دفعة مجمّعة';
	@override String get plafondLotDetail => 'أقصى مبلغ لمجموعة مدفوعات.';
	@override String get plafondPeriode => 'الحد الأقصى التراكمي لكل فترة';
	@override String get plafondPeriodeDetail => 'أقصى إجمالي خلال الفترة؛ يمنع الالتفاف على الحد بالتجزئة.';
	@override String get plafondIndice => 'بلا حد';
	@override String get validationsTitre => 'متى تُشترط مصادقة ثانية';
	@override String get retraitReserve => 'السحب من الاحتياطي الاستراتيجي';
	@override String get retraitReserveDetail => 'ممنوع على المحاسب دون مصادقة.';
	@override String get premierPaiement => 'أول دفعة لمستفيد';
	@override String get premierPaiementDetail => 'أول دفعة لمستفيد تتطلب مصادقة ثانية.';
	@override String get coordonnees => 'بيانات عُدّلت مؤخرًا';
	@override String get coordonneesDetail => 'الدفعة نحو بيانات عُدّلت مؤخرًا تتطلب مصادقة ثانية.';
	@override String get joursRecents => 'مدة التعديل الحديث';
	@override String get joursRecentsDetail => 'خلال هذا العدد من الأيام بعد التعديل، تُعدّ البيانات حديثة.';
	@override String get toujoursTitre => 'ممنوع دائمًا على المحاسب';
	@override String get toujoursDetail => 'هذه القواعد الثلاث لا تُعدَّل.';
	@override String get autoPayout => 'أن يدفع لنفسه';
	@override String get autoPayoutDetail => 'دفعته الخاصة تمر دائمًا عبر شخص آخر.';
	@override String get montantManuel => 'إدخال مبلغ يدويًا عند الدفع';
	@override String get montantManuelDetail => 'مبلغ الدفعة هو دائمًا مبلغ الالتزام.';
	@override String get politiqueTarifaire => 'تعديل الأسعار';
	@override String get politiqueTarifaireDetail => 'سياسة الأسعار تبقى للإدارة.';
}

// Path: classe.cartes.feuille.defauts
class _Traductions$classe$cartes$feuille$defauts$ar extends Traductions$classe$cartes$feuille$defauts$fr {
	_Traductions$classe$cartes$feuille$defauts$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titreVide => 'العنوان ناقص. اكتب بضع كلمات، مثل «سورة للمراجعة».';
	@override String titreLong({required Object max}) => 'العنوان يتجاوز ${max} حرفًا. اختصره.';
	@override String texteLong({required Object max}) => 'النص يتجاوز ${max} حرفًا. اختصره أو شارك رابطًا.';
	@override String get lienInvalide => 'هذا الرابط ليس عنوانًا كاملًا. انسخ العنوان كما يظهر في شريط المتصفح والصقه هنا.';
	@override String get echeanceManquante => 'يحتاج الواجب إلى موعد نهائي. اختر الموعد النهائي.';
}

// Path: com.socle.composants.lecture
class _Traductions$com$socle$composants$lecture$ar extends Traductions$com$socle$composants$lecture$fr {
	_Traductions$com$socle$composants$lecture$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String pieceJointe({required Object nom}) => 'مرفق: ${nom}';
	@override String vocal({required Object duree}) => 'رسالة صوتية مدتها ${duree}';
	@override String get vocalSansDuree => 'رسالة صوتية';
	@override String horodatage({required Object date, required Object heure}) => '${date} · ${heure}';
}

// Path: com.socle.composants.badge
class _Traductions$com$socle$composants$badge$ar extends Traductions$com$socle$composants$badge$fr {
	_Traductions$com$socle$composants$badge$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get nonLuUn => '1 غير مقروء';
	@override String nonLus({required Object nombre}) => '${nombre} غير مقروءة';
	@override String nonLusSemantique({required Object nombre}) => '${nombre} عناصر غير مقروءة';
	@override String get nonLuUnSemantique => 'عنصر واحد غير مقروء';
	@override String get information => 'للعلم';
	@override String get aLire => 'للقراءة';
	@override String get actionRequise => _root.com.socle.lexique.actionRequise;
	@override String get urgent => 'عاجل';
	@override String get mention => 'إشارة';
	@override String get mentionSemantique => 'هناك إشارة تخصّك';
}

// Path: com.socle.composants.pieceJointe
class _Traductions$com$socle$composants$pieceJointe$ar extends Traductions$com$socle$composants$pieceJointe$fr {
	_Traductions$com$socle$composants$pieceJointe$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get joindre => 'إرفاق ملف';
	@override String get joindreIndisponible => 'إرفاق الملفات غير متاح هنا بعد.';
	@override String get ouvrir => 'فتح';
	@override String ouvrirLecteur({required Object nom}) => 'فتح ${nom}';
	@override String get retirer => 'إزالة';
	@override String retirerLecteur({required Object nom}) => 'إزالة ${nom}';
	@override String tailleOctets({required Object taille}) => '${taille} بايت';
	@override String tailleKo({required Object taille}) => '${taille} كيلوبايت';
	@override String tailleMo({required Object taille}) => '${taille} ميغابايت';
	@override String get autorisee => 'جاهز للإرسال';
	@override String get tropVolumineuse => 'الملف كبير جدًا';
	@override String get tropVolumineuseDetail => 'هذا الملف يتجاوز الحجم المسموح به. اختر ملفًا أصغر.';
	@override String get typeInterdit => 'نوع الملف مرفوض';
	@override String get typeInterditDetail => 'هذا النوع من الملفات غير مقبول هنا. اختر صيغة أخرى.';
	@override String get enCours => 'جارٍ الإرسال';
	@override String get envoyee => 'أُرسل';
	@override String get echec => 'لم يُؤكَّد';
	@override String get erreurEnvoi => 'لم يُؤكَّد إرسال هذا الملف بعد. أعد المحاولة بعد قليل.';
	@override String get indisponible => 'المرفق غير متاح';
	@override String get indisponibleDetail => 'هذا الملف لم يعد متاحًا. اطلب من الشخص الذي شاركه أن يعيد إرساله.';
}

// Path: com.socle.composants.composer
class _Traductions$com$socle$composants$composer$ar extends Traductions$com$socle$composants$composer$fr {
	_Traductions$com$socle$composants$composer$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get message => 'رسالة';
	@override String get aide => 'اكتب رسالة';
	@override String get envoyer => 'إرسال';
	@override String get champVide => 'اكتب رسالة لإرسالها.';
	@override String get vocal => 'رسالة صوتية';
	@override String get vocalAVenir => 'الرسالة الصوتية متاحة قريبًا';
	@override String get enCours => 'جارٍ الإرسال';
	@override String get envoye => 'أُرسلت';
	@override String get nonConfirme => 'لم يُؤكَّد إرسال هذه الرسالة بعد.';
	@override String get reessayer => 'إعادة المحاولة';
	@override String get auteurSoi => 'أنت';
	@override String annonce({required Object auteur, required Object texte}) => 'رسالة جديدة من ${auteur}: ${texte}';
	@override String get brouillon => _root.com.socle.lexique.brouillon;
	@override String get brouillonRestaure => 'تمت استعادة المسودة';
	@override String get enregistrerVocal => _root.com.vocal.composer.enregistrer;
	@override String get aucunMessageTitre => 'لا توجد رسائل حاليًا';
	@override String get aucunMessage => 'اكتب أول رسالة في هذه المحادثة، وستظهر هنا.';
}

// Path: com.socle.composants.etats
class _Traductions$com$socle$composants$etats$ar extends Traductions$com$socle$composants$etats$fr {
	_Traductions$com$socle$composants$etats$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get chargement => 'جارٍ التحميل';
	@override String get videTitre => 'لا شيء هنا حاليًا';
	@override String get erreurTitre => 'تعذّر تحميل هذا المحتوى.';
	@override String get erreur => 'تحقّق من اتصالك ثم أعد المحاولة.';
	@override String get reessayer => 'إعادة المحاولة';
	@override String get horsLigne => 'أنت غير متصل. لا يمكن تحديث الرسائل الجديدة.';
	@override String get horsLigneBloc => 'أعد المحاولة عند عودة الاتصال.';
	@override String get indisponibleTitre => 'غير متاح بعد';
	@override String get indisponible => 'هذه الميزة غير متاحة هنا بعد. ستُفتح حين تصبح الخدمة جاهزة.';
	@override String get permissionRefusee => 'ليس لديك صلاحية الوصول إلى هذا المحتوى.';
}

// Path: com.socle.composants.espace
class _Traductions$com$socle$composants$espace$ar extends Traductions$com$socle$composants$espace$fr {
	_Traductions$com$socle$composants$espace$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get ouvrirPanneau => 'فتح لوحة السياق';
	@override String get fermerPanneau => 'إغلاق لوحة السياق';
	@override String get panneauContexte => 'السياق';
	@override String get retourListe => 'العودة إلى القائمة';
}

// Path: com.socle.navigation.provisoire
class _Traductions$com$socle$navigation$provisoire$ar extends Traductions$com$socle$navigation$provisoire$fr {
	_Traductions$com$socle$navigation$provisoire$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get messagesTitre => _root.com.socle.lexique.messages;
	@override String get messagesDetail => 'ستصل الرسائل المرتبطة بفصولك إلى هذه المساحة قريبًا.';
	@override String get communauteTitre => _root.com.socle.lexique.communaute;
	@override String get communauteDetail => 'ستصل مساحة التبادل بين المعلّمين إلى هنا قريبًا.';
	@override String get studioTitre => _root.com.socle.lexique.studio;
	@override String get studioDetail => 'ستصل مساحة عمل الفريق إلى هنا قريبًا.';
	@override String get administrationTitre => 'إدارة الاتصالات';
	@override String get administrationDetail => 'ستُدار الإعلانات والإشراف والرسائل من هنا قريبًا.';
	@override String get publierAnnonceTitre => 'نشر إعلان';
	@override String get publierAnnonceDetail => 'سيصل نشر إعلان لفصل ما إلى هنا قريبًا.';
}

// Path: com.socle.navigation.demo
class _Traductions$com$socle$navigation$demo$ar extends Traductions$com$socle$navigation$demo$fr {
	_Traductions$com$socle$navigation$demo$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'عرض توضيحي للاتصالات';
	@override String get detail => 'بيانات وهمية، غير موجودة في نسخ الإنتاج.';
	@override String get choisir => 'اختر مساحة لتجربتها.';
}

// Path: com.messages.demo.roles
class _Traductions$com$messages$demo$roles$ar extends Traductions$com$messages$demo$roles$fr {
	_Traductions$com$messages$demo$roles$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get tuteur => 'الأسرة';
	@override String get enseignant => 'المعلم';
	@override String get adulte => 'طالب بالغ';
	@override String get admin => 'الإدارة';
	@override String get controleur => 'المراقب';
}

// Path: com.messages.demo.f
class _Traductions$com$messages$demo$f$ar extends Traductions$com$messages$demo$f$fr {
	_Traductions$com$messages$demo$f$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get ahmed => 'أحمد';
	@override String get parentAdam => 'ولي أمر آدم';
	@override String get enseignanteNour => 'معلمة فصل النور';
	@override String get fatima => 'فاطمة';
	@override String get parentYasmine => 'ولية أمر ياسمين';
	@override String get karim => 'كريم';
	@override String get parentYusuf => 'ولي أمر يوسف';
	@override String get administration => 'الإدارة';
	@override String get directionRewayah => 'إدارة رواية';
	@override String get rachid => 'الأستاذ رشيد';
	@override String get controleurPedagogique => 'مراقب تربوي';
	@override String get youssef => 'يوسف';
	@override String get enseignantFajr => 'معلم فصل الفجر';
	@override String get khadija => 'خديجة';
	@override String get eleveFajr => 'طالبة في فصل الفجر';
	@override String get adam => 'آدم';
	@override String get yasmine => 'ياسمين';
	@override String get yusuf => 'يوسف';
	@override String get dossierAdam => 'ملف تسجيل آدم';
	@override String get missionNour => 'زيارة مراقبة، فصل النور';
	@override String get pieceDevoir => 'واجب_الأسبوع_3.pdf';
	@override String get pieceAttestation => 'الشهادة_القديمة.pdf';
	@override String get pieceVocal => 'رسالة_صوتية.m4a';
	@override String get typeAudio => 'صوت';
	@override String get adamQuestion => 'السلام عليكم، أردت أن أعرف كيف مرّت حصة اليوم بالنسبة إلى آدم. شكرًا جزيلًا.';
	@override String get adamReponse => 'وعليكم السلام، مرّت الحصة على أحسن وجه. كان آدم منتبهًا وشارك مشاركة جيدة.';
	@override String get adamDevoir => 'إليكم واجب الأسبوع القادم.';
	@override String get dossierManque => 'تنقص شهادة مستوى آدم لإتمام تسجيله. هل يمكنكم إيداعها في ملفه؟';
	@override String get missionRetard => 'بدأت الحصة متأخرة ثماني دقائق. أُودع التقرير.';
	@override String get missionSuite => 'شكرًا، سنتحدث في الأمر مع المعلمة هذا الأسبوع.';
	@override String get yasmineMerci => 'شكرًا جزيلًا على هذه التوضيحات.';
	@override String get affectation => 'ينتقل فصل النور إلى يوم الثلاثاء الساعة 18 ابتداءً من الشهر القادم. يرجى التأكيد.';
	@override String get khadijaRevision => 'تذكّري مراجعة سورة الملك قبل يوم الخميس.';
}

// Path: com.communaute.garde.reponse
class _Traductions$com$communaute$garde$reponse$ar extends Traductions$com$communaute$garde$reponse$fr {
	_Traductions$com$communaute$garde$reponse$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get avertissement => 'يبدو أن هذا الرد يتضمن ترويجًا تجاريًا. احذف الرابط أو رمز الخصم أو العرض قبل إرساله.';
	@override String get liensTitre => 'روابط الرد';
	@override String get consigneBlocage => 'عدِّل الرد ثم أرسله من جديد.';
}

// Path: com.communaute.signalement.politique
class _Traductions$com$communaute$signalement$politique$ar extends Traductions$com$communaute$signalement$politique$fr {
	_Traductions$com$communaute$signalement$politique$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get publicite => 'الإعلانات التجارية غير مسموح بها في مجتمع المعلّمين.';
	@override String get sollicitation => 'الاستدراج التجاري غير مسموح به في هذه المساحة.';
}

// Path: com.communaute.demo.f
class _Traductions$com$communaute$demo$f$ar extends Traductions$com$communaute$demo$f$fr {
	_Traductions$com$communaute$demo$f$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get categoriePedagogie => 'التربية';
	@override String get categorieRessources => 'الموارد';
	@override String get categorieGestion => 'التسيير';
	@override String get fonctionSoi => 'معلم، فصل الفاتحة';
	@override String get prenomSoi => 'إبراهيم';
	@override String get samira => 'سميرة بلقاسم';
	@override String get fonctionSamira => 'معلمة، فصل النور';
	@override String get nour => 'نور الإدريسي';
	@override String get fonctionNour => 'معلمة، فصل الفجر';
	@override String get yasmine => 'ياسمين حداد';
	@override String get fonctionYasmine => 'معلمة، فصل البدر';
	@override String get youssef => 'يوسف العمراني';
	@override String get fonctionYoussef => 'معلم، فصل الكوثر';
	@override String get mariam => 'مريم بن علي';
	@override String get fonctionMariam => 'معلمة، فصل الناس';
	@override String get hamza => 'حمزة والي';
	@override String get fonctionHamza => 'معلم، فصل الإخلاص';
	@override String get memorisationTitre => 'أفكار للمساعدة على الحفظ؟';
	@override String get memorisationTexte => 'ما العادات أو الأنشطة التي تنجح في مساعدة الطلاب على حفظ السور؟ أبحث عن تجارب عملية: ألعاب، ووسائل بصرية، وتكرار ثنائي. شكرًا على أفكاركم!';
	@override String get cartesTitre => 'تجربتي مع بطاقات التكرار';
	@override String get cartesTexte => 'أستخدم بطاقات التكرار منذ بداية العام الدراسي وهي تنجح كثيرًا، حتى مع الأصغر سنًّا. أرفقت النموذج الذي أملؤه قبل كل حصة.';
	@override String get cartesFichier => 'بطاقات_التكرار.pdf';
	@override String get niveauxTitre => 'كيف ندير المستويات المختلفة؟';
	@override String get niveauxTexte => 'كيف تديرون فصلًا تتفاوت فيه المستويات كثيرًا؟ أخشى أن يفقد المتقدمون اهتمامهم بينما أعيد الأساسيات مع الآخرين.';
	@override String get timidesTitre => 'تشجيع الطلاب الخجولين على التلاوة';
	@override String get timidesTexte => 'طالبة ترفض التلاوة أمام الآخرين. أقترح عليها أن تتلو أولًا، حين يكون الفصل لا يزال هادئًا. هل لديكم أفكار أخرى؟';
	@override String get ficheTitre => 'بطاقة لمتابعة المراجعات';
	@override String get ficheTexte => 'أدوّن كل أسبوع السور التي رُوجعت والنقاط التي تحتاج إلى إعادة. تكفي البطاقة صفحة واحدة وتساعد كثيرًا في التحضير للحصة التالية.';
	@override String get heureTitre => 'بدء الحصة في موعدها';
	@override String get heureTexte => 'كثيرًا ما تضيع الدقائق الأولى في التجهيز. صرت أطلب من الطلاب تحضير صفحتهم قبل الموعد. ما رأيكم؟';
	@override String get reponseMariam => 'أستخدم كثيرًا التكرار الثنائي والبطاقات المصوّرة. وهذا يحفّز الطلاب حقًّا.';
	@override String get reponseYoussef => 'يعيد الطلاب الاستماع إلى تلاوة الحصة في البيت، وهذا يساعد كثيرًا بين درسين.';
	@override String get reponseSamira => 'شكرًا على النموذج، سأجربه هذا الأسبوع.';
	@override String get reponseHamza => 'أترك الطالب أحيانًا يتلو على انفراد في نهاية الحصة، ثم أمام زميل واحد.';
	@override String get affilieTitre => 'مشغّلي الصوتي المفضل للمراجعة';
	@override String affilieTexte({required Object lien}) => 'أستخدم هذا المشغّل لإعادة الاستماع إلى السور. سعره مخفَّض هذا الأسبوع عبر رابطي: ${lien}';
	@override String get venteTitre => 'أبيع بطاقات الحفظ الخاصة بي';
	@override String get venteTexte => 'مجموعة من 30 بطاقة مغلَّفة، بـ 25 يورو، تُرسل بالبريد. راسلوني للطلب.';
	@override String get publiciteTitre => 'تطبيق للمراجعة';
	@override String publiciteTexte({required Object lienOffre, required Object lienInterne, required Object lienRessource}) => 'أنصح بتطبيق المراجعة هذا، مع الرمز PROF20 للاشتراك: ${lienOffre}. أما النص، فيكفي مورد المكتبة (${lienInterne}) و${lienRessource}.';
	@override String reponseAffilie({required Object lien}) => 'للمراجعة، أنصح بهذا المشغّل، بسعر مخفَّض عبر رابطي: ${lien}';
	@override String get fichierChoisi => 'بطاقة_الحصة.pdf';
}

// Path: com.studio.aujourdhui.indicateurs
class _Traductions$com$studio$aujourdhui$indicateurs$ar extends Traductions$com$studio$aujourdhui$indicateurs$fr {
	_Traductions$com$studio$aujourdhui$indicateurs$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'مؤشرات الانتباه';
	@override String get aTraiter => _root.com.socle.lexique.aTraiter;
	@override String get mentions => 'الإشارات والردود';
	@override String get decisions => 'قرارات معلّقة';
	@override String get nonLus => 'غير مقروءة';
}

// Path: com.studio.aujourdhui.blocs
class _Traductions$com$studio$aujourdhui$blocs$ar extends Traductions$com$studio$aujourdhui$blocs$fr {
	_Traductions$com$studio$aujourdhui$blocs$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aTraiter => 'للمعالجة اليوم';
	@override String get mentions => 'الإشارات والردود';
	@override String get decisions => 'قرارات معلّقة';
	@override String get echeances => 'مواعيد قريبة';
	@override String get activite => 'النشاط الأخير';
	@override String get brouillons => 'المسودات';
	@override String get acces => 'وصول سريع';
}

// Path: com.studio.aujourdhui.videsBlocs
class _Traductions$com$studio$aujourdhui$videsBlocs$ar extends Traductions$com$studio$aujourdhui$videsBlocs$fr {
	_Traductions$com$studio$aujourdhui$videsBlocs$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aTraiter => 'لا شيء للمعالجة اليوم.';
	@override String get mentions => 'لا توجد إشارات أو ردود في الانتظار.';
	@override String get decisions => 'لا توجد قرارات معلّقة.';
	@override String get echeances => 'لا توجد مواعيد قريبة.';
	@override String get activite => 'لا يوجد نشاط حديث.';
}

// Path: com.studio.aujourdhui.modules
class _Traductions$com$studio$aujourdhui$modules$ar extends Traductions$com$studio$aujourdhui$modules$fr {
	_Traductions$com$studio$aujourdhui$modules$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get studio => _root.com.socle.lexique.studio;
	@override String get finance => 'المالية';
	@override String get planning => 'الجدولة';
	@override String get dossiers => 'الملفات';
	@override String get classes => 'الفصول';
	@override String get admissions => 'القبول';
	@override String get demandes => 'الطلبات';
	@override String get communications => 'إدارة الاتصالات';
}

// Path: com.studio.aujourdhui.acces
class _Traductions$com$studio$aujourdhui$acces$ar extends Traductions$com$studio$aujourdhui$acces$fr {
	_Traductions$com$studio$aujourdhui$acces$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get messages => _root.com.socle.lexique.messagesMetier;
	@override String get messagesDetail => 'المحادثات مع الأسر والمعلّمين والمراقبين';
	@override String get annonces => 'الإعلانات';
	@override String get annoncesDetail => 'نشر الإعلانات ومتابعتها';
	@override String get dossiers => 'ملفات للتصديق';
	@override String get dossiersDetail => 'الملفات الجاهزة لاتخاذ قرار';
	@override String get classes => 'الفصول';
	@override String get classesDetail => 'الفصول ومواعيدها ومعلّموها';
	@override String get demandes => 'طلبات بانتظار القرار';
	@override String get demandesDetail => 'طلبات التغيير المنتظرة';
}

// Path: com.studio.enregistres.types
class _Traductions$com$studio$enregistres$types$ar extends Traductions$com$studio$enregistres$types$fr {
	_Traductions$com$studio$enregistres$types$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get canal => 'قناة';
	@override String get publication => 'منشور';
	@override String get message => 'رسالة';
	@override String get element => 'عنصر من الاستوديو';
}

// Path: com.studio.demo.f
class _Traductions$com$studio$demo$f$ar extends Traductions$com$studio$demo$f$fr {
	_Traductions$com$studio$demo$f$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get nadia => 'نادية';
	@override String get fonctionDirection => 'الإدارة';
	@override String get mariam => 'مريم';
	@override String get fonctionCoordination => 'التنسيق العام';
	@override String get youssef => 'يوسف';
	@override String get fonctionProduit => 'المنتج والتقنية';
	@override String get amina => 'أمينة';
	@override String get fonctionPedagogie => 'الشؤون التربوية';
	@override String get samira => 'سميرة';
	@override String get fonctionAdmissions => 'القبول';
	@override String get ibrahim => 'إبراهيم';
	@override String get fonctionPlanning => 'الجدولة';
	@override String get pieceAudio => 'صوت';
	@override String get fichierPlanning => 'جدول_الفصل_الثالث.pdf';
	@override String get fichierModeration => 'دليل_الإشراف.pdf';
	@override String get fichierVocal => 'رسالة_صوتية_يوسف.m4a';
	@override String get fichierCompteRendu => 'تقرير_الزيارات.pdf';
	@override String get fichierBudget => 'الميزانية_السرية.pdf';
	@override String get canalOrganisation => 'التنظيم العام';
	@override String get canalOrganisationDetail => 'تنسيق عمل الفريق كله';
	@override String get canalAdmissions => 'القبول';
	@override String get canalAdmissionsDetail => 'متابعة طلبات التسجيل';
	@override String get canalQualite => 'متابعة الجودة';
	@override String get canalQualiteDetail => 'ملاحظات زيارات المراقبة';
	@override String get canalRemplacements => 'البدلاء';
	@override String get canalRemplacementsDetail => 'غيابات الأسبوع والمعلمون البدلاء';
	@override String get canalCloture => 'إقفال الشهر';
	@override String get canalClotureDetail => 'التحضير للإقفال الشهري';
	@override String get canalDirection => 'الإدارة الاستراتيجية';
	@override String get canalDirectionDetail => 'توجهات الإدارة';
	@override String get messagePlanning => 'السلام عليكم جميعًا. إليكم جدول الفصل الدراسي القادم، أخبروني إن كان فيه ما لا يناسب.';
	@override String get messageSupports => 'أحدّث مواد المستوى 2 ونراجع الأمر معًا غدًا.';
	@override String get messageMerci => 'شكرًا للجميع على هذا الأسبوع.';
	@override String get messageDossiers => 'ثلاثة ملفات تنتظر قرارًا قبل يوم الجمعة. نادية، هل يمكنك الاطلاع على ملف أسرة كريم؟';
	@override String get messageCompteRendu => 'تقرير زيارات هذا الشهر جاهز.';
	@override String get messageRemplacement => 'يوم الثلاثاء، يتولى معلم بديل فصل النور. الجدول محدَّث.';
	@override String get messageJustificatifs => 'جُمعت مستندات شهر سبتمبر.';
	@override String get messageBudget => 'الميزانية السرية لهذا الفصل الدراسي.';
	@override String get activiteBudget => 'الميزانية السرية لهذا الفصل الدراسي';
	@override String get partagePlanning => 'جدول الفصل الدراسي';
	@override String get partageModeration => 'دليل الإشراف';
	@override String epinglePar({required Object nom}) => 'ثبّته ${nom}';
	@override String partagePar({required Object nom}) => 'شاركه ${nom}';
	@override String get lienRemplacements => 'بدلاء الأسبوع';
	@override String get lienCharte => 'ميثاق الفريق';
	@override String get brouillon => 'سميرة، سأطّلع على ملف أسرة كريم هذا المساء وأخبرك صباح الغد';
	@override String get activitePaiement => 'دفعة سبتمبر غير مؤكدة لأسرة حداد';
	@override String get objetEcheancier => 'جدول أقساط أسرة حداد';
	@override String get activiteDossierKarim => 'ملف أسرة كريم جاهز لاتخاذ قرار';
	@override String get objetDossierKarim => 'ملف أسرة كريم';
	@override String get activiteMention => 'أشارت إليك سميرة';
	@override String get activiteReponse => 'ردت أمينة على رسالتك';
	@override String get activiteRemplacant => 'اختيار المعلم البديل ليوم الثلاثاء لفصل النور';
	@override String get objetRemplacement => 'البديل ليوم الثلاثاء';
	@override String get activiteOuverture => 'المصادقة على فتح فصل صباح يوم السبت';
	@override String get objetClasseSamedi => 'فصل صباح يوم السبت';
	@override String get activiteCloture => 'إقفال شهر سبتمبر';
	@override String get objetCloture => 'إقفال سبتمبر';
	@override String get activiteBilans => 'تقييمات منتصف الفصل للمراجعة';
	@override String get objetBilans => 'تقييمات منتصف الفصل';
	@override String get activiteMessages => 'رسالتان جديدتان';
	@override String get activiteAnnonce => 'نُشر إعلان: الأكاديمية مغلقة يوم 1 نوفمبر';
	@override String get objetFermeture => 'الإغلاق يوم 1 نوفمبر';
	@override String activiteFichier({required Object nom, required Object fichier}) => '${nom} شاركت ${fichier}';
	@override String get activiteInscription => 'وصل طلب تسجيل جديد';
	@override String get objetDossierBenali => 'ملف أسرة بن علي';
}

// Path: com.annonces.publieur.etapes
class _Traductions$com$annonces$publieur$etapes$ar extends Traductions$com$annonces$publieur$etapes$fr {
	_Traductions$com$annonces$publieur$etapes$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get contenu => 'محتوى الإعلان';
	@override String get audience => 'مستلمو الإعلان';
	@override String get programmation => 'تاريخ النشر';
	@override String get previsualisation => 'معاينة الإعلان';
	@override String get publication => 'نشر الإعلان';
}

// Path: com.annonces.publieur.contexte
class _Traductions$com$annonces$publieur$contexte$ar extends Traductions$com$annonces$publieur$contexte$fr {
	_Traductions$com$annonces$publieur$contexte$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get contenu => 'اكتب ما يجب أن يعرفه المستلمون. الإعلان في اتجاه واحد: لا أحد يرد عليه.';
	@override String get audience => 'اختر من يستلم الإعلان. لا يُعرض إلا المستلمون الذين يمكنك النشر لهم.';
	@override String audienceFixee({required Object cible}) => 'يُرسل هذا الإعلان إلى ${cible}. أنت تنشر لفصلك فقط.';
	@override String get programmation => 'اختر متى يُرسل الإعلان. الإعلان المجدول ينتظر تاريخه.';
	@override String get previsualisation => 'هذا هو الإعلان كما سيقرؤه المستلمون.';
	@override String get publication => 'راجع المستلمين والتاريخ، ثم انشر. لا يُنشر شيء قبل التأكيد.';
}

// Path: com.annonces.publieur.nature
class _Traductions$com$annonces$publieur$nature$ar extends Traductions$com$annonces$publieur$nature$fr {
	_Traductions$com$annonces$publieur$nature$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get classe => 'تستلمه أسر هذا الفصل وطلابه فقط.';
	@override String get public => 'يستلمه كل أفراد هذا الجمهور.';
	@override String get toutes => 'تستلمه الأكاديمية كلها. خصصه لما يهم الجميع.';
}

// Path: com.annonces.publieur.quand
class _Traductions$com$annonces$publieur$quand$ar extends Traductions$com$annonces$publieur$quand$fr {
	_Traductions$com$annonces$publieur$quand$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get maintenant => 'فور التأكيد';
	@override String get maintenantDetail => 'يُرسل الإعلان فور تأكيد النشر.';
	@override String creneau({required Object date, required Object heure}) => 'يوم ${date} الساعة ${heure}';
	@override String get creneauDetail => 'ينتظر الإعلان هذا التاريخ. ستجده في الإعلانات المجدولة.';
}

// Path: com.annonces.publieur.apercu
class _Traductions$com$annonces$publieur$apercu$ar extends Traductions$com$annonces$publieur$apercu$fr {
	_Traductions$com$annonces$publieur$apercu$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String a({required Object cible}) => 'إلى: ${cible}';
	@override String get diffusionMaintenant => 'النشر: فور التأكيد';
	@override String diffusionLe({required Object date, required Object heure}) => 'النشر المقرر يوم ${date} الساعة ${heure}';
}

// Path: com.annonces.administration.indicateurs
class _Traductions$com$annonces$administration$indicateurs$ar extends Traductions$com$annonces$administration$indicateurs$fr {
	_Traductions$com$annonces$administration$indicateurs$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'مؤشرات التواصل';
	@override String get publiees => 'الإعلانات المنشورة';
	@override String get planifiees => 'الإعلانات المجدولة';
	@override String get moderation => 'محتويات قيد الإشراف';
	@override String get regles => 'صلاحيات النشر';
	@override String indisponible({required Object libelle}) => '${libelle}: غير متاح بعد';
	@override String echec({required Object libelle}) => '${libelle}: لم يُحمَّل. تحقّق من الاتصال ثم أعد تحميل الصفحة.';
	@override String reserve({required Object libelle}) => '${libelle}: خاص بالمكلفين بالإشراف';
}

// Path: com.annonces.administration.publiees
class _Traductions$com$annonces$administration$publiees$ar extends Traductions$com$annonces$administration$publiees$fr {
	_Traductions$com$annonces$administration$publiees$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الإعلانات المنشورة';
	@override String get vide => 'لا توجد إعلانات منشورة في هذه الفترة.';
	@override String get pastille => 'منشور';
	@override String legende({required Object cible, required Object date, required Object heure}) => '${cible} · يوم ${date} الساعة ${heure}';
}

// Path: com.annonces.administration.planifiees
class _Traductions$com$annonces$administration$planifiees$ar extends Traductions$com$annonces$administration$planifiees$fr {
	_Traductions$com$annonces$administration$planifiees$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الإعلانات المجدولة';
	@override String get vide => 'لا توجد إعلانات مجدولة.';
	@override String get pastille => 'مجدول';
	@override String legende({required Object cible, required Object date, required Object heure}) => '${cible} · مقرر يوم ${date} الساعة ${heure}';
}

// Path: com.annonces.administration.matrice
class _Traductions$com$annonces$administration$matrice$ar extends Traductions$com$annonces$administration$matrice$fr {
	_Traductions$com$annonces$administration$matrice$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'صلاحيات نشر الإعلانات';
	@override String get detail => 'قاعدة الأكاديمية، تُطبَّق على كل عملية نشر.';
	@override String get auteurs => 'من ينشر';
	@override String get peutPublier => 'يمكنه النشر';
	@override String get audiences => 'المستلمون';
	@override String get validation => 'يتطلب موافقة';
	@override String get oui => 'نعم';
	@override String get non => 'لا';
	@override String get aucune => 'لا شيء';
	@override String get vide => 'لم تُضبط أي صلاحية نشر.';
}

// Path: com.annonces.administration.moderation
class _Traductions$com$annonces$administration$moderation$ar extends Traductions$com$annonces$administration$moderation$fr {
	_Traductions$com$annonces$administration$moderation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'قائمة الإشراف';
	@override String legende({required Object date, required Object heure}) => 'أُبلغ عنه يوم ${date} الساعة ${heure}';
	@override String motif({required Object motif}) => 'السبب: ${motif}';
	@override String get extraitTitre => 'المحتوى المُبلغ عنه';
	@override String get extraitAbsent => 'مقتطف هذا المحتوى غير متاح.';
	@override String get regle => 'القاعدة المعنية';
	@override String get approuver => 'الموافقة بعد الفحص';
	@override String get masquer => 'إخفاء المحتوى';
	@override String get restaurer => 'استعادة المحتوى';
	@override String get rejeter => 'رفض البلاغ';
	@override String get contexte => 'فتح السياق';
	@override String get masque => 'مخفي';
	@override String get approuve => 'تمت الموافقة';
	@override String get rejete => 'رُفض البلاغ';
	@override String get restaure => 'مستعاد';
	@override String get enregistree => 'سُجل القرار.';
	@override String get nonConfirmee => 'لم يُؤكَّد هذا القرار بعد. تحقق من الاتصال ثم أعد المحاولة.';
	@override String get horsLigne => 'أنت غير متصل. لا يمكن تحديث قائمة الإشراف.';
	@override String get indisponible => 'الإشراف غير متاح بعد. عد لاحقًا.';
	@override String get videTitre => 'لا يوجد محتوى للفحص';
	@override String get vide => 'تصل هنا بلاغات مجتمع المعلمين.';
	@override String get refuseTitre => 'قائمة خاصة بالإشراف';
	@override String get refuse => 'لا يرى هذه القائمة إلا المكلفون بالإشراف.';
	@override String get choisirTitre => 'لا يوجد بلاغ مفتوح';
	@override String get choisir => 'اختر بلاغًا من القائمة لفحصه.';
	@override String get sansAction => 'لا يتاح لك أي إجراء إشراف على هذا المحتوى.';
	@override String get sansSanction => 'لا تُطبق أي عقوبة على الحساب تلقائيًا.';
	@override String get politique => 'سياسة منع الترويج';
	@override String ouvrirSemantique({required Object objet, required Object motif}) => 'فحص ${objet}‏، السبب ${motif}';
	@override late final _Traductions$com$annonces$administration$moderation$regleMotif$ar regleMotif = _Traductions$com$annonces$administration$moderation$regleMotif$ar._(_root);
	@override late final _Traductions$com$annonces$administration$moderation$regles$ar regles = _Traductions$com$annonces$administration$moderation$regles$ar._(_root);
}

// Path: com.annonces.demo.roles
class _Traductions$com$annonces$demo$roles$ar extends Traductions$com$annonces$demo$roles$fr {
	_Traductions$com$annonces$demo$roles$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get tuteur => 'الأسرة';
	@override String get enseignant => 'المعلم';
	@override String get adulte => 'الطالب البالغ';
	@override String get admin => 'الإدارة';
	@override String get controleur => 'المراقب';
}

// Path: com.annonces.demo.f
class _Traductions$com$annonces$demo$f$ar extends Traductions$com$annonces$demo$f$fr {
	_Traductions$com$annonces$demo$f$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get adminStudioMention => 'الاستوديو: نقاش في قناة البرامج يشير إليك';
	@override String get adminStudioReponse => 'الاستوديو: رد جديد على رسالتك بشأن برنامج الربيع';
	@override String get adminStudioDecision => 'الاستوديو: مطلوب قرار بشأن مادة الدرس 4';
	@override String get adminStudioAssigne => 'الاستوديو: أُسندت إليك مراجعة مادة التجويد';
	@override String get adminStudioInterne => 'إعلان داخلي لفريق الاستوديو: اجتماع الفريق يوم الخميس الساعة 18';
	@override String get adminStudioContexte => 'الاستوديو: مادة جاهزة لفصل النور';
	@override String get annonceNourTitre => 'تلاوة نهاية الفصل الدراسي أمام الأسر';
	@override String get annonceNourTexte => 'أسرنا الكريمة، سيقدم فصل النور تلاوة نهاية الفصل الدراسي يوم السبت 14 ديسمبر الساعة 10، عبر الاتصال المرئي. سيتلو كل طالب السورة التي عمل عليها خلال هذا الفصل الدراسي. يرجى تجهيز اتصال مستقر ومكان هادئ. يمكن للطلاب الراغبين التدرب خلال حصة الأربعاء السابقة. يمكن للأسر الحضور بصمت مع كتم الميكروفون. سيُشارك تقرير بعد الحصة.';
	@override String get annonceFajrTitre => 'مراجعة قبل تقييم يوم الخميس';
	@override String get annonceFajrTexte => 'راجعوا الآيات العشر الأخيرة من سورة الملك قبل يوم الخميس.';
	@override String get tuteurUrgent => 'حصة هذا المساء ملغاة';
	@override String get tuteurUrgentTexte => 'المعلمة غائبة هذا المساء. أُجّلت الحصة إلى يوم الخميس في الوقت نفسه. لا شيء عليك فعله.';
	@override String get tuteurReponse => 'رد منتظر: الموافقة على تلاوة ياسمين';
	@override String get tuteurReponseTexte => 'تنتظر المعلمة موافقتك لتتلو ياسمين أمام الأسر. أجبها من فضاء الفصل.';
	@override String get tuteurMessage => 'رسالة جديدة من معلمة فصل النور';
	@override String get tuteurDossier => 'تم قبول ملف التسجيل الخاص بك';
	@override String get adulteSeance => 'نُقلت حصتك يوم الثلاثاء إلى الساعة 19';
	@override String get adulteMessage => 'رسالة جديدة من معلمتك';
	@override String get enseignantFamille => 'رسالة من أسرة ياسمين، فصل النور';
	@override String get enseignantDirection => 'إعلان من الإدارة: جدول عطلة الشتاء';
	@override String get enseignantDirectionTexte => 'تتوقف الدروس من 21 ديسمبر إلى 5 يناير. تُستأنف الحصص يوم الاثنين 6 يناير في المواعيد المعتادة.';
	@override String get enseignantPlanning => 'تغيّر جدولك للأسبوع القادم';
	@override String get enseignantMention => 'منشور في مجتمع المعلمين يشير إليك';
	@override String get enseignantReponse => 'رد جديد على منشورك';
	@override String get enseignantAdministration => 'رسالة من الإدارة: وثائق مطلوبة';
	@override String get adminDossiers => 'ثلاثة ملفات تسجيل في انتظار المعالجة';
	@override String get adminSignalement => 'تم الإبلاغ عن منشور في مجتمع المعلمين';
	@override String get adminReponse => 'رد أسرة بلال على رسالتك';
	@override String get adminPlanifiee => 'إعلان مجدول يحتاج إلى مراجعة قبل النشر';
	@override String get adminOperationnel => 'فصل النور: العدد مكتمل';
	@override String get controleurMission => 'مهمة جديدة: زيارة فصل النور';
	@override String get controleurChangement => 'نُقلت مهمتك يوم الخميس إلى الساعة 18';
	@override String get controleurReponse => 'رد الإدارة على تقريرك';
}

// Path: comptable.paiements.ecart.motifs
class _Traductions$comptable$paiements$ecart$motifs$ar extends Traductions$comptable$paiements$ecart$motifs$fr {
	_Traductions$comptable$paiements$ecart$motifs$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get montantLigne => 'مبلغ هذا السطر غير مطابق';
	@override String get ligneManquante => 'سطر ناقص (حصة، استبدال، مكافأة)';
	@override String get ligneEnTrop => 'هذا السطر لا ينبغي أن يكون هنا';
	@override String get sourceErronee => 'المصدر المذكور غير صحيح';
}

// Path: comptable.direction.reservePanneau.regle
class _Traductions$comptable$direction$reservePanneau$regle$ar extends Traductions$comptable$direction$reservePanneau$regle$fr {
	_Traductions$comptable$direction$reservePanneau$regle$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get desactivee => 'معطّلة';
	@override String get desactiveeDetail => 'لا توجد تغذية تلقائية.';
	@override String get montantFixe => 'مبلغ ثابت';
	@override String get montantFixeDetail => 'المبلغ نفسه في كل موعد.';
	@override String get pourcentage => 'نسبة مئوية';
	@override String get pourcentageDetail => 'حصة من المقبوض المُثبَّت.';
	@override String get jusquAObjectif => 'حتى بلوغ الهدف';
	@override String get jusquAObjectifDetail => 'إكمال ما ينقص لبلوغ الهدف.';
	@override String get proposee => 'مقترحة';
	@override String get proposeeDetail => 'اقتراح يؤكده المحاسب.';
}

// Path: comptable.direction.reservePanneau.cadence
class _Traductions$comptable$direction$reservePanneau$cadence$ar extends Traductions$comptable$direction$reservePanneau$cadence$fr {
	_Traductions$comptable$direction$reservePanneau$cadence$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get clotureCycle => 'عند كل إقفال دورة';
	@override String get hebdomadaire => 'كل أسبوع';
	@override String get mensuelle => 'كل شهر';
	@override String get apresEncaissementConsolide => 'بعد كل مقبوض مُثبَّت';
	@override String get manuelle => 'يدوية';
}

// Path: com.annonces.administration.moderation.regleMotif
class _Traductions$com$annonces$administration$moderation$regleMotif$ar extends Traductions$com$annonces$administration$moderation$regleMotif$fr {
	_Traductions$com$annonces$administration$moderation$regleMotif$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get publicite => 'الإعلانات التجارية غير مسموح بها في مجتمع المعلّمين.';
	@override String get lienAffilie => 'روابط التسويق بالعمولة غير مسموح بها في مجتمع المعلّمين.';
	@override String get vente => 'بيع المنتجات أو الخدمات غير مسموح به في هذه المساحة.';
	@override String get sollicitation => 'الاستدراج التجاري غير مسموح به في هذه المساحة.';
}

// Path: com.annonces.administration.moderation.regles
class _Traductions$com$annonces$administration$moderation$regles$ar extends Traductions$com$annonces$administration$moderation$regles$fr {
	_Traductions$com$annonces$administration$moderation$regles$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'مشاركة تعليمية فقط';
	@override String get corps => 'مجتمع المعلّمين مخصّص للتبادل المهني بين المعلّمين.';
	@override String get reglesTitre => 'قواعد النشر';
	@override String get pasPublicite => 'لا إعلانات';
	@override String get pasAffilie => 'لا روابط تسويق بالعمولة';
	@override String get pasVente => 'لا بيع لمنتج أو خدمة';
	@override String get pasSollicitation => 'لا التماس تجاري';
	@override String get pasDonnees => 'لا بيانات شخصية لطالب أو عائلة';
}

/// The flat map containing all translations for locale <ar>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TraductionsAr {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'formulaire.manqueAccord' => 'موافقتك ناقصة: ضع علامة في الخانة للمتابعة.',
			'formulaire.motif.manqueSaisi' => 'السبب ناقص: اكتبه في كلمات قليلة.',
			'kyc.manquePhoto' => 'اختر أولًا صورة وثيقتك.',
			'kyc.manqueType' => 'اختر أولًا الوثيقة التي تودعها.',
			'notifications.titre' => 'الإشعارات',
			'notifications.indisponibleTitre' => 'الإشعارات غير متاحة بعد',
			'notifications.indisponiblePhrase' => 'ستظهر هنا تذكيرات الحصص ورسائل الأكاديمية بمجرد تفعيلها.',
			'notifications.videTitre' => 'لا توجد إشعارات',
			'notifications.videPhrase' => 'ستظهر هنا تذكيرات الحصص ورسائل الأكاديمية.',
			'notifications.ligne' => ({required Object titre, required Object date, required Object heure}) => '${titre}‏، يوم ${date} الساعة ${heure}',
			'notifications.filtres.libelle' => 'تصفية الإشعارات',
			'notifications.filtres.toutes' => 'الكل',
			'notifications.filtres.nonLues' => 'غير المقروءة',
			'notifications.filtres.mentions' => 'الإشارات',
			'notifications.filtres.actionRequise' => 'إجراء مطلوب',
			'notifications.filtreVideTitre' => 'لا توجد إشعارات في هذا التصنيف',
			'notifications.filtreVidePhrase' => 'اختر «الكل» لرؤية جميع إشعاراتك من جديد.',
			'notifications.voirToutes' => 'عرض كل الإشعارات',
			'notifications.nonLue' => 'غير مقروء',
			'notifications.nonLueSemantique' => 'غير مقروء',
			'notifications.lectureNonConfirmee' => 'لم تُؤكَّد القراءة بعد. أعد المحاولة بعد قليل.',
			'notifications.detail.choisirTitre' => 'اختر إشعارًا',
			'notifications.detail.choisirPhrase' => 'تظهر تفاصيله هنا، بجانب القائمة.',
			'notifications.detail.recue' => ({required Object date, required Object heure}) => 'وصل يوم ${date} الساعة ${heure}',
			'notifications.detail.ouvrir' => 'فتح الصفحة المعنية',
			'notifications.types.annonceClasse' => 'إعلان الفصل',
			'notifications.types.changementSeance' => 'تغيير في الحصة',
			'notifications.types.decisionDossier' => 'قرار بشأن ملف',
			'notifications.types.messageMetier' => 'رسالة',
			'notifications.types.reponseAttendue' => 'رد منتظر',
			'notifications.types.accesFinance' => 'الوصول والمدفوعات',
			'notifications.types.observation' => 'ملاحظة',
			'notifications.types.travailRessource' => 'واجب أو مورد',
			'notifications.types.annonceDirection' => 'إعلان من الإدارة',
			'notifications.types.changementPlanning' => 'تغيير في الجدول',
			'notifications.types.remplacement' => 'استخلاف',
			'notifications.types.mentionCommunaute' => 'إشارة في مجتمع المعلمين',
			'notifications.types.reponseCommunaute' => 'رد في مجتمع المعلمين',
			'notifications.types.messageAdministration' => 'رسالة من الإدارة',
			'notifications.types.dossierATraiter' => 'ملف للمعالجة',
			'notifications.types.signalementCommunaute' => 'بلاغ في مجتمع المعلمين',
			'notifications.types.reponseFil' => 'رد في محادثة',
			'notifications.types.annoncePlanifiee' => 'إعلان مجدول للنشر',
			'notifications.types.evenementOperationnel' => 'حدث في الأكاديمية',
			'notifications.types.mission' => 'مهمة',
			'notifications.types.changementMission' => 'تغيير في المهمة',
			'notifications.types.reponseAdministration' => 'رد من الإدارة',
			'notifications.types.mentionStudio' => 'إشارة في الاستوديو',
			'notifications.types.reponseStudio' => 'رد في الاستوديو',
			'notifications.types.decisionDemandee' => 'قرار مطلوب',
			'notifications.types.elementAssigne' => 'عنصر مُسند',
			'notifications.types.annonceInterne' => 'إعلان داخلي',
			'notifications.types.evenementContextuel' => 'حدث',
			'notifications.types.autre' => 'إشعار',
			'historique.moisCourts.0' => 'يناير',
			'historique.moisCourts.1' => 'فبراير',
			'historique.moisCourts.2' => 'مارس',
			'historique.moisCourts.3' => 'أبريل',
			'historique.moisCourts.4' => 'مايو',
			'historique.moisCourts.5' => 'يونيو',
			'historique.moisCourts.6' => 'يوليو',
			'historique.moisCourts.7' => 'أغسطس',
			'historique.moisCourts.8' => 'سبتمبر',
			'historique.moisCourts.9' => 'أكتوبر',
			'historique.moisCourts.10' => 'نوفمبر',
			'historique.moisCourts.11' => 'ديسمبر',
			'historique.dateCourte' => ({required Object jour, required Object mois, required Object annee}) => '${jour} ${mois} ${annee}',
			'historique.dateCourteSansAnnee' => ({required Object jour, required Object mois}) => '${jour} ${mois}',
			'historique.dateLongue' => ({required Object jourSemaine, required Object jour, required Object mois, required Object annee}) => '${jourSemaine} ${jour} ${mois} ${annee}',
			'commun.recherche.effacer' => 'مسح البحث',
			'commun.recherche.fermer' => 'إغلاق البحث',
			'commun.sections.page' => 'أقسام الصفحة',
			'commun.dates.premierJour' => '1',
			'commun.dates.jours.0' => 'الاثنين',
			'commun.dates.jours.1' => 'الثلاثاء',
			'commun.dates.jours.2' => 'الأربعاء',
			'commun.dates.jours.3' => 'الخميس',
			'commun.dates.jours.4' => 'الجمعة',
			'commun.dates.jours.5' => 'السبت',
			'commun.dates.jours.6' => 'الأحد',
			'commun.dates.mois.0' => 'يناير',
			'commun.dates.mois.1' => 'فبراير',
			'commun.dates.mois.2' => 'مارس',
			'commun.dates.mois.3' => 'أبريل',
			'commun.dates.mois.4' => 'مايو',
			'commun.dates.mois.5' => 'يونيو',
			'commun.dates.mois.6' => 'يوليو',
			'commun.dates.mois.7' => 'أغسطس',
			'commun.dates.mois.8' => 'سبتمبر',
			'commun.dates.mois.9' => 'أكتوبر',
			'commun.dates.mois.10' => 'نوفمبر',
			'commun.dates.mois.11' => 'ديسمبر',
			'commun.dates.jourDate' => ({required Object jour, required Object numero, required Object mois}) => '${jour} ${numero} ${mois}',
			'commun.reessayer' => 'إعادة المحاولة',
			'commun.annuler' => 'إلغاء',
			'commun.choix.indisponible' => 'غير متاح',
			'commun.etats.chargementProlonge.titre' => 'يستغرق الاتصال وقتًا أطول من المتوقع',
			'commun.etats.chargementProlonge.phrase' => 'يمكنك الانتظار قليلًا أو إعادة المحاولة.',
			'commun.etats.horsLigne.titre' => 'أنت غير متصل',
			'commun.etats.horsLigne.phrase' => 'تحقق من اتصالك. ما هو معروض يبقى متاحًا للاطلاع.',
			'commun.etats.reconnexion.titre' => 'جارٍ إعادة الاتصال',
			'commun.etats.reconnexion.phrase' => 'محاولة اتصال جديدة جارية.',
			'commun.etats.echecServeur.titre' => 'تعذّر تحميل هذه المعلومات',
			'commun.etats.echecServeur.phrase' => 'لم يكتمل التحميل. أعد المحاولة بعد لحظة.',
			'commun.etats.introuvable.titre' => 'هذه الصفحة غير موجودة',
			'commun.etats.introuvable.phrase' => 'ربما يكون الرابط ناقصًا، أو لم تعد الصفحة موجودة.',
			'commun.etats.accesRefuse.titre' => 'ليس لديك وصول إلى هذه الصفحة',
			'commun.etats.accesRefuse.phrase' => 'هذا المحتوى غير مفتوح لحسابك.',
			'commun.etats.sessionExpiree.titre' => 'انتهت جلستك',
			'commun.etats.sessionExpiree.phrase' => 'سجّل الدخول من جديد للمتابعة.',
			'commun.etats.dossierEnAttente.titre' => 'ملفك قيد الانتظار',
			'commun.etats.dossierEnAttente.phrase' => 'تبقى خطوة قبل فتح هذه المساحة.',
			'commun.etats.aucunResultat.titre' => 'لا توجد نتائج',
			'commun.etats.aucunResultat.phrase' => 'لا شيء مطابق حاليًا.',
			'commun.etats.permissionRefusee.titre' => 'الإذن مرفوض',
			'commun.etats.permissionRefusee.phrase' => 'دون هذا الإذن لا يمكن فتح هذه الوظيفة. يمكنك تعديله في إعدادات جهازك.',
			'commun.etats.ressourceExpiree.titre' => 'هذا المحتوى لم يعد متاحًا',
			'commun.etats.ressourceExpiree.phrase' => 'لقد سُحب، أو انتهى الوصول إليه.',
			'commun.etats.indisponible.titre' => 'غير متاح بعد',
			'commun.etats.indisponible.phrase' => 'هذه الوظيفة غير مفتوحة بعد.',
			'commun.etats.reessaisEpuises' => 'لا يزال دون رد. أعد المحاولة لاحقًا.',
			'commun.etats.horsLigneDemarrageTitre' => 'تعذّر التحقق من حسابك',
			'commun.etats.horsLigneDemarrage' => 'يمكن التحقق منه عند عودة الاتصال. أعد المحاولة حينها.',
			'commun.etats.actions.reessayer' => 'إعادة المحاولة',
			'commun.etats.actions.retourAccueil' => 'العودة إلى الرئيسية',
			'commun.etats.actions.seConnecter' => 'تسجيل الدخول',
			'commun.etats.actions.seReconnecter' => 'تسجيل الدخول من جديد',
			'commun.etats.actions.voirDossier' => 'عرض ملفي',
			'commun.etats.actions.reinitialiserFiltres' => 'إعادة ضبط عوامل التصفية',
			'commun.etats.actions.revenir' => 'الرجوع',
			'etat.enDirect' => 'مباشر',
			'etat.seanceAnnulee' => 'ملغاة',
			'etat.annuleeValeur' => ({required Object valeur}) => 'ملغاة: ${valeur}',
			'etat.motifNonCommunique' => 'السبب غير متوفر',
			'etat.aucunRemplacantTrouve' => 'لم يُعثر على بديل',
			'etat.seanceNonFacturee' => 'الحصة غير مفوترة',
			'etat.raisonEtSuite' => ({required Object raison, required Object suite}) => '${raison} · ${suite}',
			'accessibilite.tutoiement.tonHeure' => 'توقيتك',
			'accessibilite.tutoiement.attenteDetail' => 'وقت الانتظار هذا لا يُحتسب في حضورك.',
			'accessibilite.tutoiement.attente' => ({required Object duree}) => 'أنت في القاعة. تبدأ الحصة بعد ${duree}.',
			'accessibilite.tutoiement.attenteImminent' => 'أنت في القاعة. تبدأ الحصة بعد أقل من دقيقة.',
			'accessibilite.tutoiement.annonceAttente' => 'أنت في القاعة',
			'accessibilite.tutoiement.horsLigne' => 'يمكنك دخول الحصة فور عودة الاتصال.',
			'accessibilite.tutoiement.finPhrase' => 'يمكنك العثور على عملك في فصلك.',
			'classe.entree.coursDans' => ({required Object duree}) => 'الدرس بعد ${duree}',
			'classe.entree.coursImminent' => 'الدرس بعد أقل من دقيقة',
			'classe.entree.rejoindre' => 'انضمام',
			'classe.entree.rejoindreLecteur' => ({required Object deClasse}) => 'الانضمام إلى حصة ${deClasse}',
			'classe.entree.salleOuverte' => ({required Object duree}) => 'القاعة مفتوحة. تبدأ الحصة بعد ${duree}.',
			'classe.entree.salleOuverteImminent' => 'القاعة مفتوحة. تبدأ الحصة بعد أقل من دقيقة.',
			'classe.entree.preparation' => 'التحضير جارٍ',
			'classe.entree.attente' => ({required Object duree}) => 'أنت في القاعة. تبدأ الحصة بعد ${duree}.',
			'classe.entree.attenteImminent' => 'أنت في القاعة. تبدأ الحصة بعد أقل من دقيقة.',
			'classe.entree.enDirect' => 'الحصة مباشرة',
			'classe.entree.tempsEcoule' => 'انتهى الوقت المقرر',
			'classe.entree.terminee' => 'انتهت الحصة',
			'classe.entree.annulee' => 'أُلغيت الحصة',
			'classe.entree.aucune' => 'لا توجد حصة مقررة',
			'classe.entree.horsLigne' => 'أنت غير متصل. تحتاج الحصة إلى اتصال.',
			'classe.entree.indisponible' => 'معلومات الحصة غير متاحة حاليًا.',
			'classe.entree.accesInverifiable' => 'لا يمكن التحقق من الدخول إلى القاعة حاليًا.',
			'classe.entree.reessayer' => 'إعادة المحاولة',
			'classe.entree.chargementSeance' => 'جارٍ تحميل الحصة القادمة.',
			'classe.entree.progressionValeur' => ({required Object chapitre, required Object pourcentage}) => '${chapitre} · ${pourcentage} %',
			'classe.entree.dst' => ({required Object avant, required Object apres}) => 'تغيير التوقيت: سينتقل الدرس من ${avant} إلى ${apres}.',
			'classe.entree.annonce.aVenir' => 'حصة قادمة',
			'classe.entree.annonce.fenetreOuverte' => 'القاعة مفتوحة',
			'classe.entree.annonce.attente' => 'أنت في القاعة',
			'classe.catalogue' => 'اختيار فصل',
			'classe.planning' => 'الجدول',
			'classe.travail' => 'قبل الدرس القادم',
			'classe.ressources' => 'المكتبة',
			'classe.progression' => 'التقدم',
			'classe.observer' => 'متابعة الحصة',
			'classe.titre' => 'الفصل',
			'classe.historique' => 'السجل',
			'classe.sousTitre' => ({required Object prenom, required Object enseignant}) => '${prenom} · ${enseignant}',
			'classe.indisponiblePhrase' => 'تفاصيل الفصل غير متاحة هنا بعد.',
			'classe.introuvableTitre' => 'هذا الفصل غير متاح لهذا الملف',
			'classe.introuvablePhrase' => 'ربما انتهى، أو يخص طالبًا آخر من الأسرة.',
			'classe.seance.aucune' => 'لا توجد حصة مجدولة',
			'classe.seance.aucuneDetail' => ({required Object dePrenom}) => 'ستظهر هنا الحصة القادمة لـ${dePrenom} بمجرد جدولتها.',
			'classe.seance.illisible' => 'تعذّرت قراءة الحصة القادمة.',
			'classe.seance.presence' => ({required Object prenom, required Object etat}) => '${prenom}: ${etat}',
			'classe.observation.commentCaMarche' => 'كيف تعمل؟',
			'classe.observation.uneVisite' => 'زيارة واحدة متاحة',
			'classe.observation.visites' => ({required Object nombre}) => 'الزيارات المتاحة: ${nombre}',
			'classe.observation.resume' => ({required Object visites, required Object duree}) => '${visites} · ${duree} لكل زيارة',
			'classe.observation.restanteAucune' => 'لا زيارات متبقية لهذه الحصة',
			'classe.observation.restanteUne' => 'زيارة واحدة متبقية لهذه الحصة',
			'classe.observation.restantes' => ({required Object nombre}) => 'الزيارات المتبقية لهذه الحصة: ${nombre}',
			'classe.observation.minutes' => ({required Object minutes}) => '${minutes} د',
			'classe.observation.minutesSecondes' => ({required Object minutes, required Object secondes}) => '${minutes} د ${secondes} ث',
			'classe.observation.secondes' => ({required Object secondes}) => '${secondes} ث',
			'classe.observation.motif.visitesEpuisees' => 'استخدمت زياراتك لهذه الحصة.',
			'classe.observation.motif.tempsEpuise' => 'انتهى وقت المتابعة المخصص لك في هذه الحصة.',
			'classe.observation.motif.seanceNonCommencee' => 'تُفتح المتابعة عند بدء الحصة.',
			'classe.observation.motif.seanceTerminee' => 'انتهت الحصة.',
			'classe.observation.motif.seanceNonTenue' => 'هذه الحصة لن تُعقد، فلا شيء للمتابعة.',
			'classe.observation.motif.horsFenetre' => 'القاعة غير مفتوحة في هذا الوقت.',
			'classe.observation.motif.observationDesactivee' => 'المتابعة مغلقة لهذا الفصل.',
			'classe.observation.motif.lienAbsent' => 'لا يوجد طالب من أسرتك مرتبط بهذه الحصة.',
			'classe.observation.motif.enfantAbsent' => ({required Object dePrenom}) => 'تنتظر المتابعة وصول ${dePrenom}.',
			'classe.observation.motif.presenceEnVerification' => ({required Object dePrenom}) => 'يجري التحقق من حضور ${dePrenom}.',
			'classe.observation.motif.visiteDejaOuverte' => 'توجد زيارة مفتوحة بالفعل، على هذا الجهاز أو على جهاز آخر.',
			'classe.observation.motif.garantieServeurAbsente' => 'متابعة الحصص غير مفتوحة بعد.',
			'classe.observation.motif.reseau' => 'تعذّر التحقق من إتاحة المتابعة.',
			'classe.observation.motif.capaciteAbsente' => 'المتابعة غير متاحة حاليًا.',
			'classe.pagePlanning.prochaines' => 'الحصص القادمة',
			'classe.pagePlanning.ligne' => ({required Object heure, required Object duree}) => '${heure} · ${duree}',
			'classe.pagePlanning.ligneFuseau' => ({required Object heure, required Object fuseau, required Object duree}) => '${heure} (${fuseau}) · ${duree}',
			'classe.pagePlanning.aucune' => 'لا توجد حصص قادمة حاليًا',
			'classe.pagePlanning.aucuneDetail' => ({required Object dePrenom}) => 'ستظهر هنا الحصص القادمة لـ${dePrenom} بمجرد جدولتها.',
			'classe.pagePlanning.habituelIndisponible' => 'الأيام المعتادة للفصل لا تظهر هنا بعد: تظهر فقط الحصص المجدولة.',
			'classe.pagePlanning.indisponible' => 'جدول الفصل غير مربوط بهذه المساحة بعد.',
			'classe.pageTravail.aucun' => 'لا شيء للتحضير حاليًا',
			'classe.pageTravail.aucunDetail' => 'سيظهر هنا العمل الذي يكلّف به المعلم.',
			'classe.pageTravail.indisponible' => 'العمل المطلوب تحضيره غير مربوط بهذه المساحة بعد.',
			'classe.pageTravail.echeance' => ({required Object date}) => 'الموعد النهائي: ${date}',
			'classe.pageTravail.nonCochable' => 'لا يمكن بعد تحديد عمل على أنه منجز من هنا.',
			'classe.pageTravail.statut.aFaire' => 'للإنجاز',
			'classe.pageTravail.statut.enCours' => 'بدأ',
			'classe.pageTravail.statut.fait' => 'منجز',
			'classe.pageTravail.statut.expire' => 'فات الموعد',
			'classe.pageRessources.aucune' => 'لا توجد موارد لهذا الفصل حاليًا',
			'classe.pageRessources.aucuneDetail' => 'ستظهر هنا المواد التي يختارها المعلم.',
			'classe.pageRessources.indisponible' => 'مكتبة الفصل غير مربوطة بهذه المساحة بعد.',
			'classe.pageProgression.indisponible' => ({required Object dePrenom}) => 'تقدم ${dePrenom} غير مُشارك هنا بعد.',
			'classe.pageProgression.niveau' => 'المستوى',
			'classe.pageProgression.jalons' => 'المراحل المنجزة',
			'classe.pageProgression.aucune' => 'لا توجد مراحل مُشاركة حاليًا',
			'classe.pageProgression.aucuneDetail' => 'سيظهر هنا التقدم الذي يشاركه المعلم مع الأسرة.',
			'classe.pageCatalogue.pour' => ({required Object prenom}) => 'لـ${prenom}',
			'classe.pageCatalogue.proposees' => 'الفصول المقترحة',
			'classe.pageCatalogue.indisponible' => 'اختيار الفصل عبر الإنترنت غير مفتوح بعد.',
			'classe.pageCatalogue.aucune' => 'لا يوجد فصل مناسب حاليًا',
			'classe.pageCatalogue.aucuneDetail' => ({required Object dePrenom}) => 'لا يوجد فصل مفتوح يناسب ملف ${dePrenom} في الوقت الحالي.',
			'classe.pageCatalogue.eleveInconnuTitre' => 'هذا الملف ليس ضمن أسرتك',
			'classe.pageCatalogue.eleveInconnuPhrase' => 'عد إلى الصفحة الرئيسية واختر ملف الطالب المعني.',
			'classe.pageCatalogue.horairesAbsents' => 'أيام هذا الفصل ومواعيده لا تظهر هنا بعد.',
			'classe.pageCatalogue.seanceHebdo' => ({required Object jour, required Object heure, required Object duree}) => '${jour} الساعة ${heure} · ${duree} د',
			'classe.pageCatalogue.fuseauClasse' => ({required Object fuseau}) => 'مواعيد الفصل (${fuseau})',
			'classe.pageCatalogue.placeUne' => 'مقعد واحد متبقٍّ',
			'classe.pageCatalogue.places' => ({required Object nombre}) => 'المقاعد المتبقية: ${nombre}',
			'classe.pageCatalogue.etat.ouverte' => 'مفتوح',
			'classe.pageCatalogue.etat.complete' => 'مكتمل',
			'classe.pageCatalogue.etat.listeAttente' => 'قائمة الانتظار',
			'classe.pageCatalogue.choisir' => 'اختيار هذا الفصل',
			'classe.pageCatalogue.rejoindreAttente' => 'الانضمام إلى قائمة الانتظار',
			'classe.pageCatalogue.precisionsTitre' => 'قبل الاختيار',
			'classe.pageCatalogue.precisionEnseignant' => 'يحتفظ الفصل بالمعلم نفسه في كل حصصه.',
			'classe.pageCatalogue.precisionPlaces' => 'المقاعد المعروضة هي مقاعد الأكاديمية لحظة القراءة.',
			'classe.pageCatalogue.precisionReserve' => 'لا يُحجز شيء قبل تأكيدك.',
			'classe.pageCatalogue.confirmerTitre' => 'تأكيد الفصل',
			'classe.pageCatalogue.confirmerPhrase' => ({required Object prenom}) => 'أنت تسجّل ${prenom} في هذا الفصل.',
			'classe.pageCatalogue.confirmerAttentePhrase' => ({required Object prenom}) => 'أنت تسجّل ${prenom} في قائمة انتظار هذا الفصل.',
			'classe.pageCatalogue.memeEnseignant' => ({required Object enseignant}) => 'الفصل نفسه والمعلم نفسه في كل حصص الأسبوع: ${enseignant}.',
			'classe.pageCatalogue.confirmer' => 'تأكيد التسجيل',
			'classe.pageCatalogue.confirmerAttente' => 'تأكيد قائمة الانتظار',
			'classe.pageCatalogue.envoiIncertain' => 'لم يصل رد الأكاديمية. إعادة المحاولة لا تنشئ تسجيلًا ثانيًا.',
			'classe.pageCatalogue.envoiIndisponible' => 'التسجيل عبر الإنترنت غير مفتوح بعد: لم يُحجز أي مقعد.',
			'classe.pageCatalogue.resultat.inscritTitre' => 'تم تأكيد التسجيل',
			'classe.pageCatalogue.resultat.inscritPhrase' => ({required Object prenom, required Object classe}) => 'انضم ${prenom} إلى ${classe}.',
			'classe.pageCatalogue.resultat.voirClasse' => 'عرض الفصل',
			'classe.pageCatalogue.resultat.validationTitre' => 'تم إرسال الطلب',
			'classe.pageCatalogue.resultat.validationPhrase' => ({required Object dePrenom, required Object classe}) => 'ما زال على الأكاديمية اعتماد تسجيل ${dePrenom} في ${classe}.',
			'classe.pageCatalogue.resultat.listeAttenteTitre' => 'التسجيل في قائمة الانتظار',
			'classe.pageCatalogue.resultat.listeAttentePhrase' => ({required Object prenom, required Object deClasse}) => '${prenom} في قائمة انتظار ${deClasse}. لم يُحجز أي مقعد حاليًا.',
			'classe.pageCatalogue.resultat.refuseTitre' => 'لم يُقبل التسجيل',
			'classe.pageCatalogue.resultat.refusePhrase' => ({required Object prenom}) => 'لم يُحجز أي مقعد لـ${prenom}. يمكنك اختيار فصل آخر.',
			'classe.pageCatalogue.resultat.autresClasses' => 'عرض الفصول الأخرى',
			'classe.pageCatalogue.resultat.retourAccueil' => 'العودة إلى الصفحة الرئيسية',
			'classe.cartes.titre' => 'بطاقات الفصل',
			'classe.cartes.contexteEnseignant' => 'المس بطاقة لتعديلها. يراها الطلاب وأسرهم فورًا.',
			'classe.cartes.modificationPlusTard' => 'يمكن تعديل البطاقات عند عودة الاتصال.',
			'classe.cartes.aucune' => 'لا توجد بطاقات حاليًا',
			'classe.cartes.aucuneDetail' => 'سيضع معلم الفصل هنا المعلومات المفيدة.',
			'classe.cartes.aucuneEnseignant' => 'لا توجد بطاقات حاليًا. أضف بطاقة: سيراها الفصل فورًا.',
			'classe.cartes.ajouter' => 'إضافة بطاقة',
			'classe.cartes.limite' => ({required Object max}) => '${max} بطاقات على الأكثر: احذف واحدة لتضيف أخرى.',
			'classe.cartes.modifierLecteur' => ({required Object titre}) => 'تعديل البطاقة «${titre}»',
			'classe.cartes.echeance' => ({required Object date}) => 'الموعد النهائي: ${date}',
			'classe.cartes.copierLien' => ({required Object titre}) => 'نسخ رابط «${titre}»',
			'classe.cartes.copierLienCourt' => 'نسخ الرابط',
			'classe.cartes.lienCopie' => 'تم نسخ الرابط. الصقه في متصفحك لفتحه.',
			'classe.cartes.indisponibleTitre' => 'بطاقات الفصل غير مفتوحة بعد',
			'classe.cartes.indisponiblePhrase' => 'ستظهر هنا فور فتحها. لا شيء مطلوب منك.',
			'classe.cartes.erreurLecture' => 'تعذرت قراءة بطاقات الفصل. أعد المحاولة بعد قليل.',
			'classe.cartes.sansDonnees' => 'تعذر تحميل بطاقات الفصل',
			'classe.cartes.enregistree' => 'تم حفظ البطاقة. يراها الفصل الآن.',
			'classe.cartes.retiree' => 'تم حذف البطاقة. لم يعد الفصل يراها.',
			'classe.cartes.types.annonce' => 'إعلان',
			'classe.cartes.types.devoir' => 'واجب',
			'classe.cartes.types.lien' => 'رابط مفيد',
			'classe.cartes.types.rappel' => 'تذكير',
			'classe.cartes.typesDetail.annonce' => 'لمعلومة موجهة إلى الفصل كله.',
			'classe.cartes.typesDetail.devoir' => 'لعمل يُحضَّر: الموعد النهائي المقترح هو الحصة القادمة.',
			'classe.cartes.typesDetail.lien' => 'لمشاركة صفحة أو مادة: الصق عنوانها.',
			'classe.cartes.typesDetail.rappel' => 'لتاريخ لا يُنسى: رحلة، امتحان، تغيير في الموعد.',
			'classe.cartes.modeles.annonce' => 'معلومة للفصل',
			'classe.cartes.modeles.devoir' => 'للتحضير للحصة القادمة',
			'classe.cartes.modeles.lien' => 'مادة للاطلاع',
			'classe.cartes.modeles.rappel' => 'لا تنسَ',
			'classe.cartes.feuille.titreNouvelle' => 'بطاقة جديدة للفصل',
			'classe.cartes.feuille.titreModifier' => ({required Object titre}) => 'تعديل البطاقة «${titre}»',
			'classe.cartes.feuille.contexte' => 'اختر نموذجًا: يملأ البطاقة مسبقًا. يراها طلاب الفصل وأسرهم فورًا.',
			'classe.cartes.feuille.modele' => 'نموذج البطاقة',
			'classe.cartes.feuille.champTitre' => 'عنوان البطاقة',
			'classe.cartes.feuille.champTexte' => 'نص البطاقة (اختياري)',
			'classe.cartes.feuille.champLien' => 'رابط البطاقة (اختياري)',
			'classe.cartes.feuille.aideLongueur' => ({required Object max}) => '${max} حرفًا على الأكثر',
			'classe.cartes.feuille.aideLien' => 'عنوان كامل، كما يظهر في شريط المتصفح',
			'classe.cartes.feuille.echeanceAucune' => 'بلا موعد نهائي',
			'classe.cartes.feuille.choisirEcheance' => 'اختيار الموعد النهائي',
			'classe.cartes.feuille.retirerEcheance' => 'إزالة الموعد النهائي',
			'classe.cartes.feuille.enregistrer' => 'حفظ البطاقة',
			'classe.cartes.feuille.retirer' => 'حذف هذه البطاقة',
			'classe.cartes.feuille.retirerQuestion' => ({required Object titre}) => 'حذف البطاقة «${titre}»؟',
			'classe.cartes.feuille.retirerConsequence' => 'تختفي فورًا عند طلاب الفصل وأسرهم.',
			'classe.cartes.feuille.retirerConfirmer' => 'حذف البطاقة',
			'classe.cartes.feuille.envoiNonConfirme' => 'لم يتأكد حفظ البطاقة: لم يصل الرد. احفظ من جديد بعد قليل.',
			'classe.cartes.feuille.retraitNonConfirme' => 'لم يتأكد الحذف: لم يصل الرد. أعد المحاولة بعد قليل.',
			'classe.cartes.feuille.defauts.titreVide' => 'العنوان ناقص. اكتب بضع كلمات، مثل «سورة للمراجعة».',
			'classe.cartes.feuille.defauts.titreLong' => ({required Object max}) => 'العنوان يتجاوز ${max} حرفًا. اختصره.',
			'classe.cartes.feuille.defauts.texteLong' => ({required Object max}) => 'النص يتجاوز ${max} حرفًا. اختصره أو شارك رابطًا.',
			'classe.cartes.feuille.defauts.lienInvalide' => 'هذا الرابط ليس عنوانًا كاملًا. انسخ العنوان كما يظهر في شريط المتصفح والصقه هنا.',
			'classe.cartes.feuille.defauts.echeanceManquante' => 'يحتاج الواجب إلى موعد نهائي. اختر الموعد النهائي.',
			'salle.microOuvert' => 'الميكروفون مفتوح',
			'salle.microCoupe' => 'الميكروفون مغلق',
			'salle.cameraAllumee' => 'الكاميرا مشغّلة',
			'salle.cameraCoupee' => 'الكاميرا مطفأة',
			'salle.secours.reseauFaible' => 'الشبكة ضعيفة. الأولوية للصوت.',
			'salle.secours.reseauFaibleGuidee' => 'الشبكة ضعيفة.',
			'salle.secours.reseauFaibleGuideeSuite' => 'الصوت يبقى أولوية.',
			'salle.secours.reconnexion' => 'انقطع الاتصال. جارٍ إعادة الاتصال…',
			'salle.secours.reconnexionGuidee' => 'جارٍ إعادة الاتصال بالحصة…',
			'salle.secours.retablie' => 'عاد الاتصال.',
			'salle.secours.echec' => 'تعذّرت إعادة الاتصال.',
			'salle.secours.echecGuidee' => 'الاتصال لا يعود.',
			'salle.secours.horsLigne' => 'أنت غير متصل. تحتاج الحصة إلى اتصال.',
			'salle.secours.reessayer' => 'إعادة المحاولة',
			'salle.secours.quitter' => 'خروج',
			'salle.secours.indisponible' => ({required Object commande}) => '${commande}. غير متاح أثناء إعادة الاتصال.',
			'salle.secours.cameraInterdite' => 'الكاميرا معطّلة لهذا الملف.',
			'salle.secours.microBloque' => 'الميكروفون محظور في إعدادات هذا الجهاز.',
			'salle.secours.microBloqueGuidee' => 'الميكروفون محظور على هذا الجهاز.',
			'salle.secours.continuerSansMicro' => 'المتابعة دون ميكروفون',
			'salle.secours.ouvrirReglages' => 'فتح الإعدادات',
			'eleve.accueil.entreeSePrepare' => 'دخولك قيد التحضير. أعد المحاولة بعد لحظة.',
			'eleve.suivi.titre' => 'متابعة دروسي',
			'eleve.suivi.colonneDate' => 'التاريخ',
			'eleve.suivi.colonneCours' => 'الدرس',
			'eleve.suivi.colonneEnseignant' => 'المعلم',
			'eleve.suivi.colonneEtat' => 'الحضور',
			'eleve.suivi.cours' => 'درس القرآن',
			'eleve.suivi.moi' => 'حضوري',
			'eleve.suivi.aujourdhui' => ({required Object heure}) => 'اليوم، ${heure}',
			'eleve.suivi.hier' => ({required Object heure}) => 'أمس، ${heure}',
			'eleve.suivi.date' => ({required Object date, required Object heure}) => '${date}، ${heure}',
			'eleve.suivi.annule' => 'درس ملغى',
			'eleve.suivi.nonTenu' => 'درس لم يُعقد',
			'eleve.suivi.vide' => 'لا توجد دروس حتى الآن',
			'eleve.suivi.videDetail' => 'ستظهر دروسك هنا من الأحدث إلى الأقدم مع حالة حضورك.',
			'eleve.suivi.erreur' => 'تعذرت قراءة المتابعة. حاول مرة أخرى بعد قليل.',
			'eleve.suivi.tronquee' => ({required Object nombre}) => 'تظهر أحدث ${nombre} دروس.',
			'eleve.suivi.fin' => ({required Object nombre}) => 'عدد الدروس في المتابعة: ${nombre}.',
			'eleve.suivi.finUn' => 'درس واحد في المتابعة.',
			'enseignant.journee.derniereSeance' => 'آخر حصة',
			'enseignant.journee.rejoindreSalle' => 'الدخول إلى القاعة',
			'enseignant.journee.rejoindreSalleLecteur' => ({required Object classe}) => 'الدخول إلى قاعة الفصل ${classe}',
			'enseignant.journee.remplirCahier' => 'تعبئة دفتر المتابعة',
			'enseignant.journee.remplirCahierLecteur' => ({required Object classe}) => 'تعبئة دفتر المتابعة للفصل ${classe}',
			'enseignant.journee.cahierObligatoire' => ({required Object classe}) => 'إلزامي: يُعبَّأ دفتر ${classe} في نهاية كل حصة.',
			'enseignant.journee.voirCahier' => ({required Object classe}) => 'عرض دفتر ${classe}',
			'enseignant.journee.voirCahierLecteur' => ({required Object classe}) => 'عرض دفتر المتابعة للفصل ${classe}',
			'enseignant.ficheGroupe.elevesTitre' => 'الطلاب',
			'enseignant.ficheGroupe.preparationTitre' => 'للتحضير',
			'enseignant.ficheGroupe.supportPrevu' => 'المادة المقررة',
			'enseignant.ficheGroupe.positionReprise' => 'موضع الاستئناف',
			'enseignant.ficheGroupe.objectif' => 'الهدف',
			'enseignant.ficheGroupe.preparationVide' => 'لم يُسجَّل أي تحضير لهذه الحصة.',
			'enseignant.ficheGroupe.supportsTitre' => 'أحدث المواد',
			'enseignant.ficheGroupe.repriseEleve' => ({required Object page}) => 'الاستئناف: ${page}',
			'enseignant.ficheGroupe.dernierPoint' => ({required Object texte}) => 'آخر ملاحظة: ${texte}',
			'enseignant.ficheGroupe.chargementClasse' => 'جارٍ تحميل الفصل.',
			'compte.themeContexte' => 'اختر مظهر التطبيق. يتم التغيير فورًا ويبقى على هذا الجهاز، ويمكنك تعديله في أي وقت.',
			'compte.themeSysteme' => 'النظام',
			'compte.themeSystemeDetail' => 'يتبع إعداد جهازك',
			'compte.themeClair' => 'فاتح',
			'compte.themeClairDetail' => 'خلفية فاتحة مهما كان إعداد جهازك',
			'compte.themeSombre' => 'داكن',
			'compte.themeSombreDetail' => 'خلفية داكنة مهما كان إعداد جهازك',
			'tuteur.accueil.prochaineSeance' => 'الحصة القادمة',
			'tuteur.accueil.heureDe' => ({required Object deVille}) => 'توقيت ${deVille}',
			'tuteur.accueil.heureAppareil' => 'توقيت هذا الجهاز',
			'tuteur.accueil.heureClasse' => ({required Object heure, required Object ville}) => 'توقيت الفصل: ${heure} ${ville}',
			'tuteur.accueil.seanceEnDirect' => 'الحصة مباشرة',
			'tuteur.accueil.seanceTerminee' => 'انتهت الحصة',
			'tuteur.accueil.seanceAnnulee' => 'لن تُعقد هذه الحصة.',
			'tuteur.accueil.seanceNonTenue' => 'تعذّر عقد هذه الحصة.',
			'tuteur.accueil.horaireIncertain' => 'لم يُؤكَّد فتح القاعة بعد',
			'tuteur.accueil.pastilleAnnulee' => 'ملغاة',
			'tuteur.accueil.pastilleNonTenue' => 'لم تُعقد',
			'tuteur.accueil.pastilleTerminee' => 'منتهية',
			'tuteur.accueil.etatCourt.enDirect' => 'مباشر',
			'tuteur.accueil.etatCourt.salleOuverte' => 'القاعة مفتوحة',
			'tuteur.accueil.etatCourt.dansMinutes' => ({required Object minutes}) => 'بعد ${minutes} د',
			'tuteur.accueil.etatCourt.dansHeures' => ({required Object heures, required Object minutes}) => 'بعد ${heures} س ${minutes} د',
			'tuteur.accueil.etatCourt.dansJours' => ({required Object jours}) => 'بعد ${jours} يوم',
			'tuteur.accueil.etatCourt.prevue' => 'حصة مقررة',
			'tuteur.accueil.etatCourt.annulee' => 'حصة ملغاة',
			'tuteur.accueil.etatCourt.nonTenue' => 'حصة لم تُعقد',
			'tuteur.accueil.etatCourt.terminee' => 'حصة منتهية',
			'tuteur.accueil.etatCourt.aucune' => 'لا توجد حصة',
			'tuteur.accueil.etatCourt.illisible' => 'غير متاح',
			'tuteur.accueil.motifAnnuleeTard' => 'أُلغيت الحصة قبل موعدها بقليل',
			'nav.eleve.accueil' => 'الرئيسية',
			'nav.eleve.maClasse' => 'فصلي',
			'nav.eleve.coran' => 'القرآن',
			'nav.eleve.monEspace' => 'مساحتي',
			'nav.eleve.suivi' => 'المتابعة',
			'nav.eleve.compte' => 'الحساب',
			'nav.tuteur.accueil' => 'الرئيسية',
			'nav.tuteur.foyer' => 'الأسرة',
			'nav.tuteur.disponibilites' => 'الأوقات المتاحة',
			'nav.tuteur.reglages' => 'الإعدادات',
			'nav.tuteur.suivi' => 'المتابعة',
			'nav.tuteur.historique' => 'السجل',
			'nav.tuteur.compte' => 'الحساب',
			'nav.enseignant.journee' => 'اليوم',
			'nav.enseignant.classes' => 'الفصول',
			'nav.enseignant.creneaux' => 'الأوقات المتاحة',
			'nav.enseignant.profil' => 'الملف الشخصي',
			'nav.controleur.planning' => 'الجدول',
			'nav.controleur.controle' => 'المراقبة',
			'nav.controleur.historique' => 'السجل',
			'nav.controleur.echanges' => 'المراسلات',
			'nav.controleur.compte' => 'الحساب',
			'nav.admin.tableauDeBord' => 'لوحة التحكم',
			'nav.admin.dossiers' => 'الملفات',
			'nav.admin.demandes' => 'الطلبات',
			'nav.admin.attribution' => 'الإسناد',
			'nav.admin.journal' => 'السجل',
			'nav.admin.comptes' => 'الحسابات',
			'nav.admin.accesAgents' => 'صلاحيات الموظفين',
			'nav.admin.accueil' => 'الرئيسية',
			'nav.admin.operations' => 'العمليات',
			'nav.admin.personnes' => 'الأشخاص',
			'nav.admin.pedagogie' => 'التعليم',
			'nav.admin.finance' => 'المالية',
			'nav.admin.configuration' => 'الإعدادات',
			'nav.admin.securite' => 'الأمان والتدقيق',
			'nav.admin.direction' => 'الإدارة',
			'nav.admin.recherche' => 'البحث',
			'nav.admin.rechercheIndication' => 'البحث عن شاشة',
			'nav.admin.notificationsTitre' => 'الإشعارات',
			'nav.admin.menu' => 'القائمة',
			'nav.compte' => 'حسابي',
			'nav.principale' => 'التنقل الرئيسي',
			'nav.motSymbole' => 'Rewayah',
			'nav.replier' => 'طيّ شريط التنقل',
			'nav.deplier' => 'فتح شريط التنقل',
			'tc.groupe.mesGroupes.titre' => 'فصولي',
			'tc.groupe.mesGroupes.aucun' => 'لا يوجد فصل حاليًا',
			'tc.groupe.mesGroupes.aucunDetail' => 'ستضعك الأكاديمية في فصل بمجرد توفر موعد يناسبك.',
			'tc.groupe.commun.erreur' => 'تعذّرت قراءة فصولك',
			'tc.groupe.commun.reessayer' => 'إعادة المحاولة',
			'tc.groupe.carte.ouvrir' => ({required Object libelle}) => 'فتح الفصل ${libelle}',
			'tc.groupe.carte.capacite' => ({required Object membres, required Object seuil}) => '${membres} / ${seuil}',
			'tc.groupe.carte.capacitePhrase' => ({required Object membres, required Object seuil}) => '${membres} طلاب من أصل ${seuil} مقاعد',
			'tc.groupe.carte.complet' => 'مكتمل',
			'tc.groupe.carte.prochainCours' => 'الدرس القادم',
			'tc.groupe.carte.aucuneSeance' => 'لا توجد حصة مجدولة',
			'tc.groupe.carte.aucuneSeanceDetail' => 'لم يُحدَّد جدول هذا الفصل بعد.',
			'tc.groupe.carte.duree' => ({required Object valeur}) => 'المدة ${valeur}',
			'tc.groupe.carte.dureeLibelle' => 'المدة',
			'tc.groupe.carte.rejoindre' => 'انضمام',
			'tc.groupe.enseignant.sayyid' => 'سيد',
			'tc.groupe.enseignant.sayyida' => 'سيدة',
			'tc.groupe.enseignant.photoManquante' => 'الصورة مطلوبة',
			'tc.groupe.enseignant.photoManquanteDetail' => 'لم تُسجَّل صورة المعلم بعد.',
			'tc.groupe.cours.coursEtNiveau' => ({required Object cours, required Object niveau}) => '${cours} · ${niveau}',
			'tc.groupe.temps.dansMinutes' => ({required Object minutes}) => 'الدرس بعد ${minutes} د',
			'tc.groupe.temps.dansHeures' => ({required Object heures, required Object minutes}) => 'الدرس بعد ${heures} س ${minutes} د',
			'tc.groupe.temps.imminent' => 'الدرس وشيك',
			'tc.groupe.temps.salleOuverte' => ({required Object reste}) => 'القاعة مفتوحة · ${reste}',
			'tc.groupe.temps.salleOuverteCourt' => 'القاعة مفتوحة',
			'tc.groupe.temps.attente' => 'أنت في القاعة. لم يبدأ الدرس بعد.',
			'tc.groupe.temps.attenteDetail' => 'وقت الانتظار هذا لا يُحتسب في حضورك.',
			'tc.groupe.temps.enSalle' => 'في القاعة',
			'tc.groupe.temps.resteMinutes' => ({required Object minutes}) => 'متبقٍّ ${minutes} د',
			'tc.groupe.temps.resteHeures' => ({required Object heures, required Object minutes}) => 'متبقٍّ ${heures} س ${minutes} د',
			'tc.groupe.temps.enCours' => ({required Object reste}) => 'الحصة مباشرة · ${reste}',
			'tc.groupe.temps.enDirect' => 'مباشر',
			'tc.groupe.temps.prolongee' => 'الحصة ما زالت مباشرة',
			'tc.groupe.temps.depassement' => 'تجاوز الوقت',
			'tc.groupe.temps.terminee' => 'انتهى الدرس',
			'tc.groupe.duree.minutes' => ({required Object minutes}) => '${minutes} د',
			'tc.groupe.duree.heures' => ({required Object heures}) => '${heures} س',
			'tc.groupe.duree.heuresMinutes' => ({required Object heures, required Object minutes}) => '${heures} س ${minutes} د',
			'tc.groupe.horloges.votreHeure' => 'توقيتك',
			'tc.groupe.horloges.chezEnseignant' => ({required Object nomme}) => 'توقيت ${nomme}',
			'tc.groupe.horloges.heureGroupe' => 'توقيت الفصل',
			'tc.groupe.horloges.heureEtVille' => ({required Object heure, required Object ville}) => '${heure} ${ville}',
			'tc.groupe.dst.j30' => 'تغيير التوقيت بعد شهر',
			'tc.groupe.dst.j7' => 'تغيير التوقيت الأسبوع القادم',
			'tc.groupe.dst.j1' => 'تغيير التوقيت غدًا',
			'tc.groupe.dst.detail' => ({required Object avant, required Object apres}) => 'سينتقل درسك من ${avant} إلى ${apres}.',
			'tc.groupe.session.conseilAppareil' => 'يُنصح بجهاز لوحي أو حاسوب للدرس. يبقى الهاتف مدعومًا.',
			'tc.groupe.espace.retour' => 'فصولي',
			'tc.groupe.espace.avantProchainCours' => 'قبل الدرس القادم',
			'tc.groupe.espace.aucuneAction' => 'لا شيء للتحضير حاليًا',
			_ => null,
		} ?? switch (path) {
			'tc.groupe.espace.bibliotheque' => 'المكتبة',
			'tc.groupe.espace.bibliothequeVoirTout' => 'عرض الكل',
			'tc.groupe.espace.progression' => 'التقدم',
			'tc.groupe.espace.roster' => 'طلاب الفصل',
			'tc.groupe.espace.reprendreLeCours' => 'استئناف الدرس',
			'tc.groupe.espace.introuvable' => 'هذا الفصل غير متاح لك',
			'tc.groupe.espace.introuvableDetail' => 'ربما أُغلق، أو يخص ملفًا آخر.',
			'tc.groupe.emplacement.nonBranche' => 'متاح قريبًا',
			'tc.groupe.emplacement.nonBrancheDetail' => 'سيُربط هذا المحتوى بهذه المساحة قريبًا.',
			'tc.bibliotheque.sections.groupe' => 'المواد المعروضة',
			'com.socle.composants.lecture.pieceJointe' => ({required Object nom}) => 'مرفق: ${nom}',
			'com.socle.composants.lecture.vocal' => ({required Object duree}) => 'رسالة صوتية مدتها ${duree}',
			'com.socle.composants.lecture.vocalSansDuree' => 'رسالة صوتية',
			'com.socle.composants.lecture.horodatage' => ({required Object date, required Object heure}) => '${date} · ${heure}',
			'com.socle.composants.badge.nonLuUn' => '1 غير مقروء',
			'com.socle.composants.badge.nonLus' => ({required Object nombre}) => '${nombre} غير مقروءة',
			'com.socle.composants.badge.nonLusSemantique' => ({required Object nombre}) => '${nombre} عناصر غير مقروءة',
			'com.socle.composants.badge.nonLuUnSemantique' => 'عنصر واحد غير مقروء',
			'com.socle.composants.badge.information' => 'للعلم',
			'com.socle.composants.badge.aLire' => 'للقراءة',
			'com.socle.composants.badge.actionRequise' => _root.com.socle.lexique.actionRequise,
			'com.socle.composants.badge.urgent' => 'عاجل',
			'com.socle.composants.badge.mention' => 'إشارة',
			'com.socle.composants.badge.mentionSemantique' => 'هناك إشارة تخصّك',
			'com.socle.composants.pieceJointe.joindre' => 'إرفاق ملف',
			'com.socle.composants.pieceJointe.joindreIndisponible' => 'إرفاق الملفات غير متاح هنا بعد.',
			'com.socle.composants.pieceJointe.ouvrir' => 'فتح',
			'com.socle.composants.pieceJointe.ouvrirLecteur' => ({required Object nom}) => 'فتح ${nom}',
			'com.socle.composants.pieceJointe.retirer' => 'إزالة',
			'com.socle.composants.pieceJointe.retirerLecteur' => ({required Object nom}) => 'إزالة ${nom}',
			'com.socle.composants.pieceJointe.tailleOctets' => ({required Object taille}) => '${taille} بايت',
			'com.socle.composants.pieceJointe.tailleKo' => ({required Object taille}) => '${taille} كيلوبايت',
			'com.socle.composants.pieceJointe.tailleMo' => ({required Object taille}) => '${taille} ميغابايت',
			'com.socle.composants.pieceJointe.autorisee' => 'جاهز للإرسال',
			'com.socle.composants.pieceJointe.tropVolumineuse' => 'الملف كبير جدًا',
			'com.socle.composants.pieceJointe.tropVolumineuseDetail' => 'هذا الملف يتجاوز الحجم المسموح به. اختر ملفًا أصغر.',
			'com.socle.composants.pieceJointe.typeInterdit' => 'نوع الملف مرفوض',
			'com.socle.composants.pieceJointe.typeInterditDetail' => 'هذا النوع من الملفات غير مقبول هنا. اختر صيغة أخرى.',
			'com.socle.composants.pieceJointe.enCours' => 'جارٍ الإرسال',
			'com.socle.composants.pieceJointe.envoyee' => 'أُرسل',
			'com.socle.composants.pieceJointe.echec' => 'لم يُؤكَّد',
			'com.socle.composants.pieceJointe.erreurEnvoi' => 'لم يُؤكَّد إرسال هذا الملف بعد. أعد المحاولة بعد قليل.',
			'com.socle.composants.pieceJointe.indisponible' => 'المرفق غير متاح',
			'com.socle.composants.pieceJointe.indisponibleDetail' => 'هذا الملف لم يعد متاحًا. اطلب من الشخص الذي شاركه أن يعيد إرساله.',
			'com.socle.composants.composer.message' => 'رسالة',
			'com.socle.composants.composer.aide' => 'اكتب رسالة',
			'com.socle.composants.composer.envoyer' => 'إرسال',
			'com.socle.composants.composer.champVide' => 'اكتب رسالة لإرسالها.',
			'com.socle.composants.composer.vocal' => 'رسالة صوتية',
			'com.socle.composants.composer.vocalAVenir' => 'الرسالة الصوتية متاحة قريبًا',
			'com.socle.composants.composer.enCours' => 'جارٍ الإرسال',
			'com.socle.composants.composer.envoye' => 'أُرسلت',
			'com.socle.composants.composer.nonConfirme' => 'لم يُؤكَّد إرسال هذه الرسالة بعد.',
			'com.socle.composants.composer.reessayer' => 'إعادة المحاولة',
			'com.socle.composants.composer.auteurSoi' => 'أنت',
			'com.socle.composants.composer.annonce' => ({required Object auteur, required Object texte}) => 'رسالة جديدة من ${auteur}: ${texte}',
			'com.socle.composants.composer.brouillon' => _root.com.socle.lexique.brouillon,
			'com.socle.composants.composer.brouillonRestaure' => 'تمت استعادة المسودة',
			'com.socle.composants.composer.enregistrerVocal' => _root.com.vocal.composer.enregistrer,
			'com.socle.composants.composer.aucunMessageTitre' => 'لا توجد رسائل حاليًا',
			'com.socle.composants.composer.aucunMessage' => 'اكتب أول رسالة في هذه المحادثة، وستظهر هنا.',
			'com.socle.composants.etats.chargement' => 'جارٍ التحميل',
			'com.socle.composants.etats.videTitre' => 'لا شيء هنا حاليًا',
			'com.socle.composants.etats.erreurTitre' => 'تعذّر تحميل هذا المحتوى.',
			'com.socle.composants.etats.erreur' => 'تحقّق من اتصالك ثم أعد المحاولة.',
			'com.socle.composants.etats.reessayer' => 'إعادة المحاولة',
			'com.socle.composants.etats.horsLigne' => 'أنت غير متصل. لا يمكن تحديث الرسائل الجديدة.',
			'com.socle.composants.etats.horsLigneBloc' => 'أعد المحاولة عند عودة الاتصال.',
			'com.socle.composants.etats.indisponibleTitre' => 'غير متاح بعد',
			'com.socle.composants.etats.indisponible' => 'هذه الميزة غير متاحة هنا بعد. ستُفتح حين تصبح الخدمة جاهزة.',
			'com.socle.composants.etats.permissionRefusee' => 'ليس لديك صلاحية الوصول إلى هذا المحتوى.',
			'com.socle.composants.espace.ouvrirPanneau' => 'فتح لوحة السياق',
			'com.socle.composants.espace.fermerPanneau' => 'إغلاق لوحة السياق',
			'com.socle.composants.espace.panneauContexte' => 'السياق',
			'com.socle.composants.espace.retourListe' => 'العودة إلى القائمة',
			'com.socle.lexique.messages' => 'الرسائل',
			'com.socle.lexique.messagesMetier' => 'رسائل العمل',
			'com.socle.lexique.communaute' => 'مجتمع المعلّمين',
			'com.socle.lexique.studio' => 'الاستوديو',
			'com.socle.lexique.aujourdhui' => 'اليوم',
			'com.socle.lexique.notifications' => 'الإشعارات',
			'com.socle.lexique.annonce' => 'إعلان',
			'com.socle.lexique.publication' => 'منشور',
			'com.socle.lexique.reponse' => 'رد',
			'com.socle.lexique.enregistrer' => 'حفظ',
			'com.socle.lexique.signaler' => 'إبلاغ',
			'com.socle.lexique.modeFocus' => 'وضع التركيز',
			'com.socle.lexique.quitterFocus' => 'الخروج من التركيز',
			'com.socle.lexique.aTraiter' => 'للمعالجة',
			'com.socle.lexique.actionRequise' => 'إجراء مطلوب',
			'com.socle.lexique.brouillon' => 'مسودة',
			'com.socle.lexique.elementsEpingles' => 'العناصر المثبّتة',
			'com.socle.lexique.fichiersPartages' => 'الملفات المشتركة',
			'com.socle.motifs.titre' => 'لماذا تبلّغ عن هذا المحتوى؟',
			'com.socle.motifs.publicite' => 'إعلان تجاري',
			'com.socle.motifs.lienAffilie' => 'رابط تسويق بالعمولة',
			'com.socle.motifs.venteNonAutorisee' => 'بيع غير مسموح به',
			'com.socle.motifs.sollicitationCommerciale' => 'استدراج تجاري',
			'com.socle.motifs.horsSujet' => 'محتوى لا علاقة له بالمجتمع',
			'com.socle.motifs.harcelement' => 'مضايقة أو لغة غير لائقة',
			'com.socle.motifs.donneesPersonnelles' => 'بيانات شخصية لطالب أو لعائلة',
			'com.socle.motifs.autre' => 'محتوى آخر يحتاج إلى فحص',
			'com.socle.signalement.titre' => 'الإبلاغ عن هذا المحتوى',
			'com.socle.signalement.precision' => 'توضيح اختياري',
			'com.socle.signalement.envoyer' => 'إرسال البلاغ',
			'com.socle.signalement.confirme' => 'تم الإبلاغ عن المحتوى. ستتم مراجعته.',
			'com.socle.signalement.erreur' => 'لم يُؤكَّد البلاغ بعد. أعد المحاولة بعد قليل.',
			'com.socle.signalement.indisponible' => 'الإبلاغ غير متاح هنا بعد.',
			'com.socle.enregistrement.enregistrer' => _root.com.socle.lexique.enregistrer,
			'com.socle.enregistrement.retirer' => 'إزالة من العناصر المحفوظة',
			'com.socle.enregistrement.enregistre' => 'محفوظ',
			'com.socle.enregistrement.indisponible' => 'الحفظ غير متاح هنا بعد.',
			'com.socle.navigation.notifications' => _root.com.socle.lexique.notifications,
			'com.socle.navigation.ouvrirNotifications' => 'فتح الإشعارات',
			'com.socle.navigation.studio' => _root.com.socle.lexique.studio,
			'com.socle.navigation.ouvrirStudio' => 'فتح الاستوديو',
			'com.socle.navigation.quitterStudio' => 'الخروج من الاستوديو',
			'com.socle.navigation.messages' => _root.com.socle.lexique.messages,
			'com.socle.navigation.communaute' => _root.com.socle.lexique.communaute,
			'com.socle.navigation.communications' => 'الاتصالات',
			'com.socle.navigation.communicationsDetail' => 'الإعلانات والإشراف ورسائل الصفوف',
			'com.socle.navigation.ongletAnnonces' => 'الإعلانات',
			'com.socle.navigation.ongletModeration' => 'الإشراف',
			'com.socle.navigation.ongletMessages' => _root.com.socle.lexique.messages,
			'com.socle.navigation.bientot' => 'متاح قريبًا',
			'com.socle.navigation.provisoire.messagesTitre' => _root.com.socle.lexique.messages,
			'com.socle.navigation.provisoire.messagesDetail' => 'ستصل الرسائل المرتبطة بفصولك إلى هذه المساحة قريبًا.',
			'com.socle.navigation.provisoire.communauteTitre' => _root.com.socle.lexique.communaute,
			'com.socle.navigation.provisoire.communauteDetail' => 'ستصل مساحة التبادل بين المعلّمين إلى هنا قريبًا.',
			'com.socle.navigation.provisoire.studioTitre' => _root.com.socle.lexique.studio,
			'com.socle.navigation.provisoire.studioDetail' => 'ستصل مساحة عمل الفريق إلى هنا قريبًا.',
			'com.socle.navigation.provisoire.administrationTitre' => 'إدارة الاتصالات',
			'com.socle.navigation.provisoire.administrationDetail' => 'ستُدار الإعلانات والإشراف والرسائل من هنا قريبًا.',
			'com.socle.navigation.provisoire.publierAnnonceTitre' => 'نشر إعلان',
			'com.socle.navigation.provisoire.publierAnnonceDetail' => 'سيصل نشر إعلان لفصل ما إلى هنا قريبًا.',
			'com.socle.navigation.demo.titre' => 'عرض توضيحي للاتصالات',
			'com.socle.navigation.demo.detail' => 'بيانات وهمية، غير موجودة في نسخ الإنتاج.',
			'com.socle.navigation.demo.choisir' => 'اختر مساحة لتجربتها.',
			'com.messages.entree.titreClasse' => 'التواصل بشأن هذا الفصل',
			'com.messages.entree.titreDossier' => 'التواصل بشأن هذا الملف',
			'com.messages.entree.titreObjet' => 'التواصل بشأن هذا الموضوع',
			'com.messages.entree.ecrireFamille' => 'مراسلة الأسرة',
			'com.messages.entree.ecrireAdministration' => 'مراسلة الإدارة',
			'com.messages.entree.ecrireA' => ({required Object nom}) => 'مراسلة ${nom}',
			'com.messages.entree.conversationAvec' => ({required Object nom}) => 'محادثة مع ${nom}',
			'com.messages.entree.voirTout' => 'عرض كل المحادثات',
			'com.messages.entree.toutes' => 'كل محادثاتك',
			'com.messages.entree.aLireUne' => 'محادثة واحدة للقراءة',
			'com.messages.entree.aLire' => ({required Object nombre}) => '${nombre} محادثات للقراءة',
			'com.messages.entree.ouverture' => 'جارٍ فتح المحادثة',
			'com.messages.entree.inaccessibleTitre' => 'محادثة غير متاحة',
			'com.messages.entree.inaccessible' => 'لم تعد هذه المحادثة متاحة لك. اختر شخصًا آخر من القائمة.',
			'com.messages.entree.erreurOuvertureTitre' => 'تعذّر فتح هذه المحادثة.',
			'com.messages.entree.ouvertureEchouee' => 'تحقّق من اتصالك ثم أعد المحاولة.',
			'com.messages.videDetail' => 'تُفتح المحادثة من فصل أو طالب أو ملف.',
			'com.messages.choisirTitre' => 'اختر محادثة',
			'com.messages.choisir' => 'اختر محادثة من القائمة لقراءتها والرد عليها.',
			'com.messages.recherche.champ' => 'البحث عن محادثة',
			'com.messages.recherche.aide' => 'الاسم أو الفصل أو الملف',
			'com.messages.recherche.aucunTitre' => 'لم يتم العثور على أي محادثة',
			'com.messages.recherche.aucun' => ({required Object texte}) => 'لا توجد محادثة تطابق «⁨${texte}⁩». جرّب اسمًا آخر أو فصلًا آخر.',
			'com.messages.recherche.resultatUn' => 'تم العثور على محادثة واحدة',
			'com.messages.recherche.resultats' => ({required Object nombre}) => 'تم العثور على ${nombre} محادثات',
			'com.messages.ligne.legende' => ({required Object objet, required Object apercu}) => '${objet} · ${apercu}',
			'com.messages.ligne.sansApercu' => 'لا توجد رسائل حاليًا',
			'com.messages.ligne.dateCourte' => ({required Object numero, required Object mois}) => '${numero} ${mois}',
			'com.messages.noms.avecFonction' => ({required Object nom, required Object fonction}) => '${nom} · ${fonction}',
			'com.messages.noms.deux' => ({required Object premier, required Object second}) => '${premier} و${second}',
			'com.messages.noms.plusieurs' => ({required Object premier, required Object nombre}) => '${premier} و${nombre} أشخاص آخرين',
			'com.messages.noms.surObjet' => ({required Object objet}) => 'محادثة بخصوص ${objet}',
			'com.messages.noms.sansObjet' => 'محادثة',
			'com.messages.entete.avecAttention' => ({required Object entete, required Object attention}) => '${entete}. ${attention}',
			'com.messages.entete.deuxObjets' => ({required Object premier, required Object second}) => '${premier} · ${second}',
			'com.messages.entete.semantique' => ({required Object noms, required Object objets}) => 'محادثة مع ${noms}‏، بخصوص ${objets}',
			'com.messages.entete.semantiqueSansNoms' => ({required Object objets}) => 'محادثة بخصوص ${objets}',
			'com.messages.types.classe' => 'الفصل',
			'com.messages.types.eleve' => 'الطالب',
			'com.messages.types.dossier' => 'الملف',
			'com.messages.types.mission' => 'مهمة المراقبة',
			'com.messages.types.remplacement' => 'الاستبدال',
			'com.messages.types.profilPaiement' => 'ملف الدفع',
			'com.messages.types.autre' => 'موضوع آخر',
			'com.messages.panneau.objets' => 'بخصوص',
			'com.messages.panneau.participants' => 'المشاركون',
			'com.messages.panneau.fichiers' => _root.com.socle.lexique.fichiersPartages,
			'com.messages.panneau.ouvrir' => ({required Object objet}) => 'فتح ${objet}',
			'com.messages.panneau.inaccessible' => 'لم يعد هذا الموضوع متاحًا لك. تبقى المحادثة متاحة للقراءة.',
			'com.messages.panneau.vous' => 'أنت',
			'com.messages.fil.lectureSeule' => 'يمكنك قراءة هذه المحادثة. الرد فيها غير متاح لك.',
			'com.messages.demo.choisirRole' => 'اختر وجهة النظر في هذا العرض التوضيحي.',
			'com.messages.demo.roles.tuteur' => 'الأسرة',
			'com.messages.demo.roles.enseignant' => 'المعلم',
			'com.messages.demo.roles.adulte' => 'طالب بالغ',
			'com.messages.demo.roles.admin' => 'الإدارة',
			'com.messages.demo.roles.controleur' => 'المراقب',
			'com.messages.demo.situations' => 'حالات للتجربة',
			'com.messages.demo.echec' => 'إرسال غير مؤكد، من جهة المعلم',
			'com.messages.demo.horsLigne' => 'دون اتصال، من جهة الأسرة',
			'com.messages.demo.refuse' => 'محادثة أسرة أخرى، مرفوضة',
			'com.messages.demo.vue' => ({required Object role}) => 'وجهة النظر: ${role}',
			'com.messages.demo.f.ahmed' => 'أحمد',
			'com.messages.demo.f.parentAdam' => 'ولي أمر آدم',
			'com.messages.demo.f.enseignanteNour' => 'معلمة فصل النور',
			'com.messages.demo.f.fatima' => 'فاطمة',
			'com.messages.demo.f.parentYasmine' => 'ولية أمر ياسمين',
			'com.messages.demo.f.karim' => 'كريم',
			'com.messages.demo.f.parentYusuf' => 'ولي أمر يوسف',
			'com.messages.demo.f.administration' => 'الإدارة',
			'com.messages.demo.f.directionRewayah' => 'إدارة رواية',
			'com.messages.demo.f.rachid' => 'الأستاذ رشيد',
			'com.messages.demo.f.controleurPedagogique' => 'مراقب تربوي',
			'com.messages.demo.f.youssef' => 'يوسف',
			'com.messages.demo.f.enseignantFajr' => 'معلم فصل الفجر',
			'com.messages.demo.f.khadija' => 'خديجة',
			'com.messages.demo.f.eleveFajr' => 'طالبة في فصل الفجر',
			'com.messages.demo.f.adam' => 'آدم',
			'com.messages.demo.f.yasmine' => 'ياسمين',
			'com.messages.demo.f.yusuf' => 'يوسف',
			'com.messages.demo.f.dossierAdam' => 'ملف تسجيل آدم',
			'com.messages.demo.f.missionNour' => 'زيارة مراقبة، فصل النور',
			'com.messages.demo.f.pieceDevoir' => 'واجب_الأسبوع_3.pdf',
			'com.messages.demo.f.pieceAttestation' => 'الشهادة_القديمة.pdf',
			'com.messages.demo.f.pieceVocal' => 'رسالة_صوتية.m4a',
			'com.messages.demo.f.typeAudio' => 'صوت',
			'com.messages.demo.f.adamQuestion' => 'السلام عليكم، أردت أن أعرف كيف مرّت حصة اليوم بالنسبة إلى آدم. شكرًا جزيلًا.',
			'com.messages.demo.f.adamReponse' => 'وعليكم السلام، مرّت الحصة على أحسن وجه. كان آدم منتبهًا وشارك مشاركة جيدة.',
			'com.messages.demo.f.adamDevoir' => 'إليكم واجب الأسبوع القادم.',
			'com.messages.demo.f.dossierManque' => 'تنقص شهادة مستوى آدم لإتمام تسجيله. هل يمكنكم إيداعها في ملفه؟',
			'com.messages.demo.f.missionRetard' => 'بدأت الحصة متأخرة ثماني دقائق. أُودع التقرير.',
			'com.messages.demo.f.missionSuite' => 'شكرًا، سنتحدث في الأمر مع المعلمة هذا الأسبوع.',
			'com.messages.demo.f.yasmineMerci' => 'شكرًا جزيلًا على هذه التوضيحات.',
			'com.messages.demo.f.affectation' => 'ينتقل فصل النور إلى يوم الثلاثاء الساعة 18 ابتداءً من الشهر القادم. يرجى التأكيد.',
			'com.messages.demo.f.khadijaRevision' => 'تذكّري مراجعة سورة الملك قبل يوم الخميس.',
			'com.messages.titre' => _root.com.socle.lexique.messagesMetier,
			'com.messages.vide' => 'لا توجد محادثات حاليًا.',
			'com.vocal.composer.libelle' => 'رسالة صوتية',
			'com.vocal.composer.enregistrer' => 'تسجيل رسالة صوتية',
			'com.vocal.composer.indisponible' => 'الرسالة الصوتية غير متاحة هنا بعد. اكتب رسالتك في الحقل أعلاه.',
			'com.vocal.composer.erreurVerificationTitre' => 'تعذّر التحقق من الميكروفون.',
			'com.vocal.composer.erreurVerificationAction' => 'إعادة المحاولة',
			'com.vocal.composer.erreurDemarrage' => 'تعذّر بدء التسجيل. تحقّق من أن الميكروفون لا يستخدمه تطبيق آخر، ثم أعد المحاولة.',
			'com.vocal.composer.erreurInterrompu' => 'توقف التسجيل. تحقّق من الميكروفون، ثم أعد المحاولة.',
			'com.vocal.composer.permissionTitre' => 'الميكروفون مطلوب',
			'com.vocal.composer.permissionPhrase' => 'يحتاج رواية إلى الميكروفون لتسجيل رسالتك الصوتية. لا يُرسل شيء دون موافقتك.',
			'com.vocal.composer.autoriser' => 'السماح باستخدام الميكروفون',
			'com.vocal.composer.annuler' => 'إلغاء',
			'com.vocal.composer.refuse' => 'الميكروفون غير مسموح به لتطبيق رواية.',
			'com.vocal.composer.refuseAide' => 'لإرسال رسالة صوتية، اسمح باستخدام الميكروفون من إعدادات جهازك، ثم عد إلى هنا.',
			'com.vocal.composer.fermer' => 'إغلاق',
			'com.vocal.composer.enregistrement' => 'التسجيل جارٍ',
			'com.vocal.composer.pause' => 'التسجيل متوقف مؤقتًا',
			'com.vocal.composer.reprise' => 'استُؤنف التسجيل',
			'com.vocal.composer.limiteProche' => ({required Object seuil, required Object max}) => 'بقي أقل من ${seuil} قبل الحد الأقصى ${max}',
			'com.vocal.composer.limiteAtteinte' => ({required Object max}) => 'بلغت المدة القصوى (${max}). استمع إلى رسالتك، ثم أرسلها أو احذفها.',
			'com.vocal.composer.ecoule' => ({required Object ecoule, required Object max}) => '${ecoule} من ${max}',
			'com.vocal.composer.preEcoute' => 'الاستماع قبل الإرسال',
			'com.vocal.composer.preEcouteAide' => 'استمع إلى رسالتك قبل إرسالها. لا يُرسل شيء دون موافقتك.',
			'com.vocal.composer.duree' => ({required Object duree}) => 'المدة: ${duree}',
			'com.vocal.composer.actionPause' => 'إيقاف مؤقت',
			'com.vocal.composer.actionReprendre' => 'استئناف',
			'com.vocal.composer.actionArreter' => 'إيقاف',
			'com.vocal.composer.actionSupprimer' => 'حذف',
			'com.vocal.composer.actionEnvoyer' => 'إرسال',
			'com.vocal.composer.confirmerTitre' => 'حذف هذه الرسالة الصوتية؟',
			'com.vocal.composer.confirmerPhrase' => 'ستُمحى من هذا الجهاز. لا يمكن التراجع عن هذا الإجراء.',
			'com.vocal.composer.garder' => 'الاحتفاظ بها',
			'com.vocal.composer.envoi' => 'جارٍ إرسال الرسالة الصوتية',
			'com.vocal.composer.nonConfirme' => 'لم يتم تأكيد هذه الرسالة الصوتية بعد.',
			'com.vocal.composer.nonConfirmeAide' => 'تحقّق من اتصالك، ثم أعد المحاولة. الرسالة الصوتية محفوظة هنا.',
			'com.vocal.composer.reessayer' => 'إعادة المحاولة',
			'com.vocal.composer.envoye' => 'أُرسلت الرسالة الصوتية.',
			'com.vocal.composer.horsLigne' => 'أنت غير متصل. الرسالة الصوتية محفوظة هنا: أرسلها عند عودة الاتصال.',
			'com.vocal.lecteur.libelleAuteur' => ({required Object auteur, required Object duree}) => 'رسالة صوتية من ${auteur}‏، ${duree}',
			'com.vocal.lecteur.libelle' => ({required Object duree}) => 'رسالة صوتية، ${duree}',
			'com.vocal.lecteur.ecouter' => 'استماع',
			'com.vocal.lecteur.pause' => 'إيقاف مؤقت',
			'com.vocal.lecteur.reprendre' => 'استئناف',
			'com.vocal.lecteur.reecouter' => 'إعادة الاستماع',
			'com.vocal.lecteur.nonEcoute' => 'لم يُستمع إليها بعد',
			'com.vocal.lecteur.lecture' => 'التشغيل جارٍ',
			'com.vocal.lecteur.enPause' => 'التشغيل متوقف مؤقتًا',
			'com.vocal.lecteur.fin' => 'استُمع إليها كاملة',
			'com.vocal.lecteur.position' => ({required Object position, required Object duree}) => '${position} من ${duree}',
			'com.vocal.lecteur.indisponible' => 'التشغيل غير متاح هنا بعد. تبقى الرسالة في المحادثة: عد لاحقًا للاستماع إليها.',
			'com.vocal.lecteur.erreurLectureTitre' => 'تعذّر تشغيل هذه الرسالة الصوتية.',
			'com.vocal.lecteur.erreurLectureAction' => 'إعادة المحاولة',
			'com.vocal.demo.contexte' => 'عرض توضيحي للرسالة الصوتية: لا يُستخدم ميكروفون حقيقي، والتسجيل محاكى.',
			'com.vocal.demo.situations' => 'حالات العرض التوضيحي',
			'com.vocal.demo.autorise' => 'الميكروفون مسموح',
			'com.vocal.demo.aDemander' => 'يُطلب الإذن',
			'com.vocal.demo.refuse' => 'الميكروفون مرفوض',
			'com.vocal.demo.nonConfirme' => 'غير مؤكد',
			'com.vocal.demo.indisponible' => 'غير متاح',
			'com.vocal.demo.recu' => 'رسالة صوتية واردة',
			'com.vocal.demo.repondre' => 'الرد في المحادثة',
			'com.vocal.demo.envoyes' => 'الرسائل الصوتية المرسلة',
			'com.vocal.demo.auteurEnseignante' => 'سيدة مريم، معلمة',
			'com.vocal.demo.auteurParent' => 'أحمد، ولي أمر آدم',
			'com.vocal.demo.messageRecu' => 'السلام عليكم، هذه ملاحظاتي على تلاوة هذا الأسبوع.',
			'com.vocal.demo.horodatage' => 'اليوم، 10:28',
			'com.vocal.titre' => 'رسالة صوتية',
			'com.communaute.garde.aide' => 'لا إعلانات. لا روابط تسويق بالعمولة. لا بيع.',
			'com.communaute.garde.avertissement' => 'يبدو أن هذا المنشور يتضمّن ترويجًا تجاريًا. أزِل الرابط أو الرمز أو العرض قبل النشر.',
			'com.communaute.garde.bloqueAffilie' => 'روابط التسويق بالعمولة غير مسموح بها في مجتمع المعلّمين.',
			'com.communaute.garde.bloqueVente' => 'بيع المنتجات أو الخدمات غير مسموح به في هذه المساحة.',
			'com.communaute.garde.titreAvertissement' => 'منشور يحتاج إلى مراجعة',
			'com.communaute.garde.titreBlocage' => 'منشور محظور',
			'com.communaute.garde.motif' => ({required Object motif}) => 'السبب: ${motif}',
			'com.communaute.garde.liensTitre' => 'روابط المنشور',
			'com.communaute.garde.consigneBlocage' => 'عدِّل المنشور ثم انشره من جديد.',
			'com.communaute.garde.panne' => 'لم يُؤكَّد التحقق من هذا المحتوى، على الأرجح بسبب الاتصال؛ لم يُنشر شيء. تحقّق من الاتصال ثم أعد المحاولة.',
			'com.communaute.garde.reponse.avertissement' => 'يبدو أن هذا الرد يتضمن ترويجًا تجاريًا. احذف الرابط أو رمز الخصم أو العرض قبل إرساله.',
			'com.communaute.garde.reponse.liensTitre' => 'روابط الرد',
			'com.communaute.garde.reponse.consigneBlocage' => 'عدِّل الرد ثم أرسله من جديد.',
			'com.communaute.lien.interne' => 'رابط داخلي في رواية',
			'com.communaute.lien.ressourceExterne' => 'مورد تعليمي خارجي',
			'com.communaute.lien.commercialInterdit' => 'رابط تجاري ممنوع',
			'com.communaute.lien.nonVerifie' => 'رابط غير مُتحقَّق منه',
			'com.communaute.lien.semantique' => ({required Object adresse, required Object etat}) => '${adresse}‏، ${etat}',
			'com.communaute.sousTitre' => 'تبادل وتعاون بين المعلّمين',
			'com.communaute.sections' => 'فئات مجتمع المعلّمين',
			'com.communaute.toutes' => 'الكل',
			'com.communaute.videTitre' => 'لا توجد منشورات',
			'com.communaute.rechercheVideTitre' => 'لا توجد نتائج',
			'com.communaute.rechercheVide' => 'لا يوجد منشور يطابق بحثك. جرّب كلمة أخرى.',
			'com.communaute.videToutes' => 'لا توجد منشورات حاليًا.',
			'com.communaute.flux.ouvrir' => ({required Object titre}) => 'فتح المنشور ${titre}',
			'com.communaute.flux.reponseUne' => 'رد واحد',
			'com.communaute.flux.reponses' => ({required Object nombre}) => '${nombre} ردود',
			'com.communaute.flux.aucuneReponse' => 'لا توجد ردود',
			'com.communaute.flux.categorie' => ({required Object categorie}) => 'الفئة ${categorie}',
			'com.communaute.recherche.ouvrir' => 'البحث عن منشور',
			'com.communaute.recherche.champ' => 'البحث عن منشور',
			'com.communaute.recherche.aide' => 'كلمة من العنوان أو النص',
			'com.communaute.moment.instant' => 'الآن',
			'com.communaute.moment.minutes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, one: 'منذ دقيقة', two: 'منذ دقيقتين', few: 'منذ ${n} دقائق', many: 'منذ ${n} دقيقة', other: 'منذ ${n} دقيقة', ), 
			'com.communaute.moment.heures' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, one: 'منذ ساعة', two: 'منذ ساعتين', few: 'منذ ${n} ساعات', many: 'منذ ${n} ساعة', other: 'منذ ${n} ساعة', ), 
			'com.communaute.moment.jours' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, one: 'منذ يوم', two: 'منذ يومين', few: 'منذ ${n} أيام', many: 'منذ ${n} يومًا', other: 'منذ ${n} يوم', ), 
			'com.communaute.moment.date' => ({required Object jour, required Object mois}) => 'في ${jour}/${mois}',
			'com.communaute.publication.auteur' => ({required Object fonction, required Object moment}) => '${fonction} · ${moment}',
			'com.communaute.publication.enregistrer' => 'حفظ المنشور',
			'com.communaute.publication.enregistree' => 'منشور محفوظ',
			'com.communaute.publication.retirer' => 'إزالة من العناصر المحفوظة',
			'com.communaute.publication.menu' => ({required Object titre}) => 'إجراءات على المنشور ${titre}',
			'com.communaute.publication.signaler' => 'الإبلاغ عن المنشور',
			'com.communaute.publication.signalee' => 'تم الإبلاغ عن المحتوى إلى فريق الإشراف.',
			'com.communaute.publication.choisirTitre' => 'لا يوجد منشور مفتوح',
			'com.communaute.publication.choisir' => 'اختر منشورًا من القائمة لقراءته والرد عليه.',
			'com.communaute.publication.introuvableTitre' => 'المنشور غير متاح',
			'com.communaute.publication.introuvable' => 'تمت إزالة هذا المنشور أو لم يعد متاحًا لك. عد إلى المنشورات لاختيار منشور آخر.',
			'com.communaute.publication.revenir' => 'العودة إلى المنشورات',
			'com.communaute.reponses.titre' => ({required Object nombre}) => 'الردود (${nombre})',
			'com.communaute.reponses.vide' => 'لا توجد ردود حاليًا.',
			'com.communaute.reponses.erreurTitre' => 'تعذّر تحميل الردود.',
			'com.communaute.reponses.champ' => 'ردك',
			'com.communaute.reponses.aide' => 'اكتب ردًا',
			'com.communaute.reponses.envoyer' => 'إرسال الرد',
			'com.communaute.reponses.champVide' => 'اكتب ردًا لإرساله.',
			'com.communaute.reponses.enCours' => 'جارٍ الإرسال',
			'com.communaute.reponses.nonConfirmee' => 'لم يُؤكَّد هذا الرد بعد. تحقّق من اتصالك ثم أعد إرساله.',
			'com.communaute.reponses.refusee' => 'رفضته سياسة المجتمع',
			'com.communaute.reponses.reessayer' => 'إعادة إرسال الرد',
			'com.communaute.reponses.indisponible' => 'الردود غير متاحة هنا بعد.',
			'com.communaute.reponses.menu' => ({required Object nom}) => 'إجراءات على رد ${nom}',
			'com.communaute.reponses.signaler' => 'الإبلاغ عن الرد',
			'com.communaute.reponses.signalee' => 'لقد أبلغت عن هذا الرد.',
			'com.communaute.signalement.politique.publicite' => 'الإعلانات التجارية غير مسموح بها في مجتمع المعلّمين.',
			'com.communaute.signalement.politique.sollicitation' => 'الاستدراج التجاري غير مسموح به في هذه المساحة.',
			'com.communaute.signalement.motifManquant' => 'اختر سببًا لإرسال البلاغ.',
			'com.communaute.composer.nouvelle' => 'منشور جديد',
			'com.communaute.composer.contexte' => 'شارك سؤالًا أو طريقة أو موردًا مفيدًا للتعليم.',
			'com.communaute.composer.categorie' => 'الفئة',
			'com.communaute.composer.categorieManquante' => 'اختر فئة للنشر.',
			'com.communaute.composer.champTitre' => 'العنوان',
			'com.communaute.composer.aideTitre' => 'الموضوع في كلمات قليلة',
			'com.communaute.composer.titreManquant' => 'اكتب عنوانًا للنشر.',
			'com.communaute.composer.champTexte' => 'النص',
			'com.communaute.composer.aideTexte' => 'سؤالك أو خبرتك',
			'com.communaute.composer.texteManquant' => 'اكتب نص المنشور للنشر.',
			'com.communaute.composer.pieces' => 'المرفقات',
			'com.communaute.composer.pieceRefusee' => 'أزل الملفات المرفوضة قبل النشر.',
			'com.communaute.composer.choixIndisponible' => 'اختيار ملف غير متاح هنا بعد.',
			'com.communaute.composer.publier' => 'نشر',
			'com.communaute.composer.fermer' => 'إغلاق المنشور الجديد',
			'com.communaute.composer.confirmee' => 'منشورك متاح الآن.',
			'com.communaute.composer.erreurEnvoi' => 'لم يُؤكَّد منشورك بعد. تحقّق من اتصالك ثم أعد المحاولة.',
			'com.communaute.composer.indisponible' => 'النشر غير متاح هنا بعد.',
			'com.communaute.regles.panneau' => 'المساعدة والقواعد',
			'com.communaute.regles.aProposTitre' => 'حول هذه المساحة',
			'com.communaute.regles.aPropos' => 'مساحة تعاون بين المعلّمين لطرح الأسئلة وتبادل الطرق والموارد التعليمية.',
			'com.communaute.regles.titre' => 'مشاركة تعليمية فقط',
			'com.communaute.regles.corps' => 'هذا المجتمع مخصّص للتبادل المهني بين المعلّمين.',
			'com.communaute.regles.reglesTitre' => 'قواعد النشر',
			'com.communaute.regles.pasPublicite' => 'لا إعلانات',
			'com.communaute.regles.pasAffilie' => 'لا روابط تسويق بالعمولة',
			'com.communaute.regles.pasVente' => 'لا بيع لمنتج أو خدمة',
			'com.communaute.regles.pasSollicitation' => 'لا التماس تجاري',
			'com.communaute.regles.pasDonnees' => 'لا بيانات شخصية لطالب أو عائلة',
			'com.communaute.regles.signaler' => 'يُبلَّغ عن المحتوى غير المناسب من قائمة المنشور.',
			'com.communaute.regles.voir' => 'عرض القواعد',
			'com.communaute.entree.lecteur' => 'فتح مجتمع المعلّمين',
			'com.communaute.entree.detail' => 'أسئلة وطرق وموارد بين المعلّمين',
			'com.communaute.demo.avertissement' => 'منشور يحتاج إلى مراجعة: إعلان تجاري',
			'com.communaute.demo.lienAffilie' => 'رابط تسويق بالعمولة محظور',
			'com.communaute.demo.vente' => 'بيع محظور',
			'com.communaute.demo.signalementNonConfirme' => 'إبلاغ غير مؤكَّد',
			'com.communaute.demo.choisir' => 'اختر حالة لتجربتها كما يراها معلّم.',
			'com.communaute.demo.aujourdhui' => 'اليوم، مع الاختصار',
			'com.communaute.demo.nominal' => 'ستة منشورات',
			'com.communaute.demo.publication' => 'منشور مفتوح',
			'com.communaute.demo.vide' => 'لا توجد منشورات',
			'com.communaute.demo.lectureEchouee' => 'فشل القراءة',
			'com.communaute.demo.indisponible' => 'الخدمة غير متاحة بعد',
			'com.communaute.demo.horsLigne' => 'غير متصل',
			'com.communaute.demo.envoiNonConfirme' => 'إرسال غير مؤكَّد',
			'com.communaute.demo.moderationIndisponible' => 'الإشراف غير متاح',
			'com.communaute.demo.lecteurSeul' => 'قراءة فقط، دون نشر',
			'com.communaute.demo.f.categoriePedagogie' => 'التربية',
			'com.communaute.demo.f.categorieRessources' => 'الموارد',
			'com.communaute.demo.f.categorieGestion' => 'التسيير',
			'com.communaute.demo.f.fonctionSoi' => 'معلم، فصل الفاتحة',
			'com.communaute.demo.f.prenomSoi' => 'إبراهيم',
			'com.communaute.demo.f.samira' => 'سميرة بلقاسم',
			'com.communaute.demo.f.fonctionSamira' => 'معلمة، فصل النور',
			'com.communaute.demo.f.nour' => 'نور الإدريسي',
			'com.communaute.demo.f.fonctionNour' => 'معلمة، فصل الفجر',
			'com.communaute.demo.f.yasmine' => 'ياسمين حداد',
			'com.communaute.demo.f.fonctionYasmine' => 'معلمة، فصل البدر',
			'com.communaute.demo.f.youssef' => 'يوسف العمراني',
			'com.communaute.demo.f.fonctionYoussef' => 'معلم، فصل الكوثر',
			'com.communaute.demo.f.mariam' => 'مريم بن علي',
			'com.communaute.demo.f.fonctionMariam' => 'معلمة، فصل الناس',
			'com.communaute.demo.f.hamza' => 'حمزة والي',
			'com.communaute.demo.f.fonctionHamza' => 'معلم، فصل الإخلاص',
			'com.communaute.demo.f.memorisationTitre' => 'أفكار للمساعدة على الحفظ؟',
			'com.communaute.demo.f.memorisationTexte' => 'ما العادات أو الأنشطة التي تنجح في مساعدة الطلاب على حفظ السور؟ أبحث عن تجارب عملية: ألعاب، ووسائل بصرية، وتكرار ثنائي. شكرًا على أفكاركم!',
			'com.communaute.demo.f.cartesTitre' => 'تجربتي مع بطاقات التكرار',
			'com.communaute.demo.f.cartesTexte' => 'أستخدم بطاقات التكرار منذ بداية العام الدراسي وهي تنجح كثيرًا، حتى مع الأصغر سنًّا. أرفقت النموذج الذي أملؤه قبل كل حصة.',
			'com.communaute.demo.f.cartesFichier' => 'بطاقات_التكرار.pdf',
			'com.communaute.demo.f.niveauxTitre' => 'كيف ندير المستويات المختلفة؟',
			'com.communaute.demo.f.niveauxTexte' => 'كيف تديرون فصلًا تتفاوت فيه المستويات كثيرًا؟ أخشى أن يفقد المتقدمون اهتمامهم بينما أعيد الأساسيات مع الآخرين.',
			'com.communaute.demo.f.timidesTitre' => 'تشجيع الطلاب الخجولين على التلاوة',
			'com.communaute.demo.f.timidesTexte' => 'طالبة ترفض التلاوة أمام الآخرين. أقترح عليها أن تتلو أولًا، حين يكون الفصل لا يزال هادئًا. هل لديكم أفكار أخرى؟',
			'com.communaute.demo.f.ficheTitre' => 'بطاقة لمتابعة المراجعات',
			'com.communaute.demo.f.ficheTexte' => 'أدوّن كل أسبوع السور التي رُوجعت والنقاط التي تحتاج إلى إعادة. تكفي البطاقة صفحة واحدة وتساعد كثيرًا في التحضير للحصة التالية.',
			'com.communaute.demo.f.heureTitre' => 'بدء الحصة في موعدها',
			'com.communaute.demo.f.heureTexte' => 'كثيرًا ما تضيع الدقائق الأولى في التجهيز. صرت أطلب من الطلاب تحضير صفحتهم قبل الموعد. ما رأيكم؟',
			'com.communaute.demo.f.reponseMariam' => 'أستخدم كثيرًا التكرار الثنائي والبطاقات المصوّرة. وهذا يحفّز الطلاب حقًّا.',
			'com.communaute.demo.f.reponseYoussef' => 'يعيد الطلاب الاستماع إلى تلاوة الحصة في البيت، وهذا يساعد كثيرًا بين درسين.',
			'com.communaute.demo.f.reponseSamira' => 'شكرًا على النموذج، سأجربه هذا الأسبوع.',
			'com.communaute.demo.f.reponseHamza' => 'أترك الطالب أحيانًا يتلو على انفراد في نهاية الحصة، ثم أمام زميل واحد.',
			'com.communaute.demo.f.affilieTitre' => 'مشغّلي الصوتي المفضل للمراجعة',
			'com.communaute.demo.f.affilieTexte' => ({required Object lien}) => 'أستخدم هذا المشغّل لإعادة الاستماع إلى السور. سعره مخفَّض هذا الأسبوع عبر رابطي: ${lien}',
			'com.communaute.demo.f.venteTitre' => 'أبيع بطاقات الحفظ الخاصة بي',
			'com.communaute.demo.f.venteTexte' => 'مجموعة من 30 بطاقة مغلَّفة، بـ 25 يورو، تُرسل بالبريد. راسلوني للطلب.',
			'com.communaute.demo.f.publiciteTitre' => 'تطبيق للمراجعة',
			'com.communaute.demo.f.publiciteTexte' => ({required Object lienOffre, required Object lienInterne, required Object lienRessource}) => 'أنصح بتطبيق المراجعة هذا، مع الرمز PROF20 للاشتراك: ${lienOffre}. أما النص، فيكفي مورد المكتبة (${lienInterne}) و${lienRessource}.',
			'com.communaute.demo.f.reponseAffilie' => ({required Object lien}) => 'للمراجعة، أنصح بهذا المشغّل، بسعر مخفَّض عبر رابطي: ${lien}',
			'com.communaute.demo.f.fichierChoisi' => 'بطاقة_الحصة.pdf',
			'com.communaute.titre' => _root.com.socle.lexique.communaute,
			'com.communaute.vide' => 'لا توجد منشورات في هذه الفئة.',
			'com.studio.focus.entrer' => _root.com.socle.lexique.modeFocus,
			'com.studio.focus.quitter' => _root.com.socle.lexique.quitterFocus,
			'com.studio.focus.actif' => 'التركيز مفعّل',
			'com.studio.focus.actifAvecEchap' => 'التركيز مفعّل. اضغط Esc للخروج.',
			'com.studio.focus.aide' => 'أخفِ اللوحات الثانوية للتركيز على هذه المحادثة.',
			'com.studio.aujourdhui.titre' => _root.com.socle.lexique.aujourdhui,
			'com.studio.aujourdhui.sousTitre' => 'ما يستحق انتباهك في الاستوديو',
			'com.studio.aujourdhui.indicateurs.titre' => 'مؤشرات الانتباه',
			'com.studio.aujourdhui.indicateurs.aTraiter' => _root.com.socle.lexique.aTraiter,
			'com.studio.aujourdhui.indicateurs.mentions' => 'الإشارات والردود',
			'com.studio.aujourdhui.indicateurs.decisions' => 'قرارات معلّقة',
			'com.studio.aujourdhui.indicateurs.nonLus' => 'غير مقروءة',
			'com.studio.aujourdhui.blocs.aTraiter' => 'للمعالجة اليوم',
			'com.studio.aujourdhui.blocs.mentions' => 'الإشارات والردود',
			'com.studio.aujourdhui.blocs.decisions' => 'قرارات معلّقة',
			'com.studio.aujourdhui.blocs.echeances' => 'مواعيد قريبة',
			'com.studio.aujourdhui.blocs.activite' => 'النشاط الأخير',
			'com.studio.aujourdhui.blocs.brouillons' => 'المسودات',
			'com.studio.aujourdhui.blocs.acces' => 'وصول سريع',
			'com.studio.aujourdhui.videsBlocs.aTraiter' => 'لا شيء للمعالجة اليوم.',
			'com.studio.aujourdhui.videsBlocs.mentions' => 'لا توجد إشارات أو ردود في الانتظار.',
			'com.studio.aujourdhui.videsBlocs.decisions' => 'لا توجد قرارات معلّقة.',
			'com.studio.aujourdhui.videsBlocs.echeances' => 'لا توجد مواعيد قريبة.',
			'com.studio.aujourdhui.videsBlocs.activite' => 'لا يوجد نشاط حديث.',
			'com.studio.aujourdhui.videTitre' => 'لا شيء للمعالجة حاليًا',
			'com.studio.aujourdhui.dansCanal' => ({required Object nom}) => 'في ${nom}',
			'com.studio.aujourdhui.echeance' => ({required Object date}) => 'الموعد ${date}',
			'com.studio.aujourdhui.seTraiteDans' => ({required Object module}) => 'يُعالَج في ${module}',
			'com.studio.aujourdhui.ouvrirDans' => ({required Object module, required Object libelle}) => 'فتح في ${module}: ${libelle}',
			'com.studio.aujourdhui.modules.studio' => _root.com.socle.lexique.studio,
			'com.studio.aujourdhui.modules.finance' => 'المالية',
			'com.studio.aujourdhui.modules.planning' => 'الجدولة',
			'com.studio.aujourdhui.modules.dossiers' => 'الملفات',
			'com.studio.aujourdhui.modules.classes' => 'الفصول',
			'com.studio.aujourdhui.modules.admissions' => 'القبول',
			'com.studio.aujourdhui.modules.demandes' => 'الطلبات',
			'com.studio.aujourdhui.modules.communications' => 'إدارة الاتصالات',
			'com.studio.aujourdhui.acces.messages' => _root.com.socle.lexique.messagesMetier,
			'com.studio.aujourdhui.acces.messagesDetail' => 'المحادثات مع الأسر والمعلّمين والمراقبين',
			'com.studio.aujourdhui.acces.annonces' => 'الإعلانات',
			'com.studio.aujourdhui.acces.annoncesDetail' => 'نشر الإعلانات ومتابعتها',
			'com.studio.aujourdhui.acces.dossiers' => 'ملفات للتصديق',
			'com.studio.aujourdhui.acces.dossiersDetail' => 'الملفات الجاهزة لاتخاذ قرار',
			'com.studio.aujourdhui.acces.classes' => 'الفصول',
			'com.studio.aujourdhui.acces.classesDetail' => 'الفصول ومواعيدها ومعلّموها',
			'com.studio.aujourdhui.acces.demandes' => 'طلبات بانتظار القرار',
			'com.studio.aujourdhui.acces.demandesDetail' => 'طلبات التغيير المنتظرة',
			'com.studio.brouillons.titre' => 'المسودات',
			'com.studio.brouillons.detail' => 'الرسائل التي بدأتها في قناة ولم تُرسل بعد. تبقى على هذا الجهاز طوال الجلسة، دون مزامنة.',
			'com.studio.brouillons.dansCanal' => ({required Object nom}) => 'مسودة في ${nom}',
			'com.studio.brouillons.canalInconnu' => 'مسودة في قناة',
			_ => null,
		} ?? switch (path) {
			'com.studio.brouillons.canalIndisponible' => 'مسودة في قناة لم تعد متاحة',
			'com.studio.brouillons.modifie' => ({required Object moment}) => 'عُدّلت في ${moment}',
			'com.studio.brouillons.reprendre' => ({required Object nom}) => 'متابعة المسودة في ${nom}',
			'com.studio.brouillons.videTitre' => 'لا توجد مسودات',
			'com.studio.brouillons.vide' => 'ستظهر هنا أي رسالة بدأتها في قناة ولم تُرسل بعد.',
			'com.studio.brouillons.tous' => ({required Object nombre}) => 'عرض كل المسودات (${nombre})',
			'com.studio.brouillons.restaure' => 'استُعيدت المسودة. يمكنك متابعة رسالتك.',
			'com.studio.sousTitre' => 'مساحة عمل الفريق',
			'com.studio.navigation.aujourdhui' => _root.com.socle.lexique.aujourdhui,
			'com.studio.navigation.brouillons' => 'المسودات',
			'com.studio.navigation.canaux' => 'القنوات',
			'com.studio.navigation.enregistres' => 'العناصر المحفوظة',
			'com.studio.choisirTitre' => 'اختر قناة',
			'com.studio.choisir' => 'اختر قناة من القائمة لقراءة النقاش والكتابة فيه.',
			'com.studio.aucunCanalTitre' => 'لا توجد قنوات حاليًا',
			'com.studio.aucunCanal' => 'ستظهر هنا القنوات المفتوحة لك.',
			'com.studio.sections.organisation' => 'التنظيم',
			'com.studio.sections.admissionsFamilles' => 'القبول والأسر',
			'com.studio.sections.pedagogieQualite' => 'التعليم والجودة',
			'com.studio.sections.planningRemplacements' => 'الجدولة والاستبدال',
			'com.studio.sections.finance' => 'المالية',
			'com.studio.sections.support' => 'الدعم',
			'com.studio.sections.produitTechnique' => 'المنتج والتقنية',
			'com.studio.sections.direction' => 'الإدارة العليا',
			'com.studio.visibilite.restreint' => 'محدودة',
			'com.studio.visibilite.prive' => 'خاصة',
			'com.studio.visibilite.visibleDetail' => 'مفتوحة لكل الفريق.',
			'com.studio.visibilite.restreintDetail' => 'مفتوحة لجزء من الفريق، وأنت منهم.',
			'com.studio.visibilite.priveDetail' => 'قناة خاصة، مفتوحة لأعضائها فقط. وأنت منهم.',
			'com.studio.canal.membresUn' => 'عضو واحد',
			'com.studio.canal.membres' => ({required Object nombre}) => '${nombre} أعضاء',
			'com.studio.canal.aide' => ({required Object nom}) => 'اكتب في ${nom}',
			'com.studio.canal.lectureSeule' => 'يمكنك قراءة هذه القناة. الكتابة فيها غير مفتوحة لك.',
			'com.studio.canal.aucunMessageTitre' => 'لا توجد رسائل حاليًا',
			'com.studio.canal.aucunMessage' => 'ستظهر رسائل هذه القناة هنا فور نشرها.',
			'com.studio.canal.indisponibleTitre' => 'القناة غير متاحة',
			'com.studio.canal.indisponible' => 'هذه القناة غير متاحة لك. اختر قناة أخرى من القائمة.',
			'com.studio.panneau.titre' => 'حول القناة',
			'com.studio.panneau.aPropos' => 'حول',
			'com.studio.panneau.section' => 'القسم',
			'com.studio.panneau.visibilite' => 'الظهور',
			'com.studio.panneau.epingles' => _root.com.socle.lexique.elementsEpingles,
			'com.studio.panneau.fichiers' => 'الملفات الأخيرة',
			'com.studio.panneau.liens' => 'روابط مفيدة',
			'com.studio.panneau.vous' => 'أنت',
			'com.studio.panneau.parametres' => 'إعدادات القناة',
			'com.studio.panneau.parametresDetail' => 'سيتاح تعديل الإعدادات مع خدمة الاستوديو.',
			'com.studio.panneau.ouvrir' => ({required Object titre}) => 'فتح ${titre}',
			'com.studio.panneau.lienExterne' => ({required Object hote}) => 'موقع خارجي: ${hote}',
			'com.studio.panneau.aucunPartageTitre' => 'لا شيء مشترك حاليًا',
			'com.studio.panneau.aucunPartage' => 'ستظهر هنا العناصر المثبتة والملفات والروابط الخاصة بهذه القناة.',
			'com.studio.enregistrer.enregistrer' => _root.com.socle.lexique.enregistrer,
			'com.studio.enregistrer.retirer' => 'إزالة',
			'com.studio.enregistrer.semantiqueEnregistrer' => ({required Object titre}) => 'حفظ ${titre}',
			'com.studio.enregistrer.semantiqueRetirer' => ({required Object titre}) => 'إزالة ${titre} من العناصر المحفوظة',
			'com.studio.enregistrer.ajoute' => ({required Object titre}) => 'أضيف إلى العناصر المحفوظة: ${titre}.',
			'com.studio.enregistrer.retire' => ({required Object titre}) => 'أزيل من العناصر المحفوظة: ${titre}.',
			'com.studio.enregistrer.nonConfirme' => 'لم يتأكد الحفظ بعد. أعد المحاولة بعد لحظة.',
			'com.studio.enregistres.detail' => 'القنوات والعناصر التي تحتفظ بها في متناولك. يُفتح كل منها في مكانه الأصلي.',
			'com.studio.enregistres.videTitre' => 'لا توجد عناصر محفوظة',
			'com.studio.enregistres.vide' => 'اضغط على حفظ في لوحة قناة لتجد هنا قناة أو عنصرًا.',
			'com.studio.enregistres.ouvrir' => ({required Object titre}) => 'فتح ${titre}',
			'com.studio.enregistres.sansDestination' => ({required Object type}) => '${type}‏، لم يعد يُفتح من هنا',
			'com.studio.enregistres.types.canal' => 'قناة',
			'com.studio.enregistres.types.publication' => 'منشور',
			'com.studio.enregistres.types.message' => 'رسالة',
			'com.studio.enregistres.types.element' => 'عنصر من الاستوديو',
			'com.studio.recherche.champ' => 'البحث في الاستوديو',
			'com.studio.recherche.aide' => 'قناة أو رسالة أو ملف',
			'com.studio.recherche.aucunTitre' => 'لا توجد نتائج',
			'com.studio.recherche.aucun' => ({required Object texte}) => 'لا شيء يطابق «⁨${texte}⁩» في قنواتك. جرّب كلمة أخرى.',
			'com.studio.recherche.aucunDansFiltre' => 'لا شيء من هذا النوع يطابق البحث. اختر الكل لرؤية النتائج الأخرى.',
			'com.studio.recherche.resultatUn' => 'نتيجة واحدة',
			'com.studio.recherche.resultats' => ({required Object nombre}) => '${nombre} نتائج',
			'com.studio.recherche.filtre' => 'نوع النتيجة',
			'com.studio.recherche.tout' => 'الكل',
			'com.studio.recherche.canaux' => 'القنوات',
			'com.studio.recherche.messages' => 'الرسائل',
			'com.studio.recherche.fichiers' => 'الملفات',
			'com.studio.recherche.dansCanal' => ({required Object canal}) => 'في ${canal}',
			'com.studio.recherche.messageDe' => ({required Object auteur, required Object canal}) => '${auteur}‏، في ${canal}',
			'com.studio.demo.focus' => 'قناة في وضع التركيز',
			'com.studio.demo.aujourdhuiVide' => 'اليوم دون نشاط',
			'com.studio.demo.horsDemo' => ({required Object module}) => 'في التطبيق، يفتح هذا السطر ${module}. يبقى العرض التجريبي على هذه الصفحة.',
			'com.studio.demo.choisir' => 'اختر حالة لتجربتها.',
			'com.studio.demo.normale' => 'الاستوديو وقنواته',
			'com.studio.demo.echec' => 'إرسال غير مؤكد',
			'com.studio.demo.horsLigne' => 'غير متصل',
			'com.studio.demo.canalPrive' => 'عنوان قناة خاصة غير مفتوحة لك',
			'com.studio.demo.sansCanaux' => 'لا توجد قناة مفتوحة',
			'com.studio.demo.vue' => ({required Object situation}) => 'الحالة: ${situation}',
			'com.studio.demo.f.nadia' => 'نادية',
			'com.studio.demo.f.fonctionDirection' => 'الإدارة',
			'com.studio.demo.f.mariam' => 'مريم',
			'com.studio.demo.f.fonctionCoordination' => 'التنسيق العام',
			'com.studio.demo.f.youssef' => 'يوسف',
			'com.studio.demo.f.fonctionProduit' => 'المنتج والتقنية',
			'com.studio.demo.f.amina' => 'أمينة',
			'com.studio.demo.f.fonctionPedagogie' => 'الشؤون التربوية',
			'com.studio.demo.f.samira' => 'سميرة',
			'com.studio.demo.f.fonctionAdmissions' => 'القبول',
			'com.studio.demo.f.ibrahim' => 'إبراهيم',
			'com.studio.demo.f.fonctionPlanning' => 'الجدولة',
			'com.studio.demo.f.pieceAudio' => 'صوت',
			'com.studio.demo.f.fichierPlanning' => 'جدول_الفصل_الثالث.pdf',
			'com.studio.demo.f.fichierModeration' => 'دليل_الإشراف.pdf',
			'com.studio.demo.f.fichierVocal' => 'رسالة_صوتية_يوسف.m4a',
			'com.studio.demo.f.fichierCompteRendu' => 'تقرير_الزيارات.pdf',
			'com.studio.demo.f.fichierBudget' => 'الميزانية_السرية.pdf',
			'com.studio.demo.f.canalOrganisation' => 'التنظيم العام',
			'com.studio.demo.f.canalOrganisationDetail' => 'تنسيق عمل الفريق كله',
			'com.studio.demo.f.canalAdmissions' => 'القبول',
			'com.studio.demo.f.canalAdmissionsDetail' => 'متابعة طلبات التسجيل',
			'com.studio.demo.f.canalQualite' => 'متابعة الجودة',
			'com.studio.demo.f.canalQualiteDetail' => 'ملاحظات زيارات المراقبة',
			'com.studio.demo.f.canalRemplacements' => 'البدلاء',
			'com.studio.demo.f.canalRemplacementsDetail' => 'غيابات الأسبوع والمعلمون البدلاء',
			'com.studio.demo.f.canalCloture' => 'إقفال الشهر',
			'com.studio.demo.f.canalClotureDetail' => 'التحضير للإقفال الشهري',
			'com.studio.demo.f.canalDirection' => 'الإدارة الاستراتيجية',
			'com.studio.demo.f.canalDirectionDetail' => 'توجهات الإدارة',
			'com.studio.demo.f.messagePlanning' => 'السلام عليكم جميعًا. إليكم جدول الفصل الدراسي القادم، أخبروني إن كان فيه ما لا يناسب.',
			'com.studio.demo.f.messageSupports' => 'أحدّث مواد المستوى 2 ونراجع الأمر معًا غدًا.',
			'com.studio.demo.f.messageMerci' => 'شكرًا للجميع على هذا الأسبوع.',
			'com.studio.demo.f.messageDossiers' => 'ثلاثة ملفات تنتظر قرارًا قبل يوم الجمعة. نادية، هل يمكنك الاطلاع على ملف أسرة كريم؟',
			'com.studio.demo.f.messageCompteRendu' => 'تقرير زيارات هذا الشهر جاهز.',
			'com.studio.demo.f.messageRemplacement' => 'يوم الثلاثاء، يتولى معلم بديل فصل النور. الجدول محدَّث.',
			'com.studio.demo.f.messageJustificatifs' => 'جُمعت مستندات شهر سبتمبر.',
			'com.studio.demo.f.messageBudget' => 'الميزانية السرية لهذا الفصل الدراسي.',
			'com.studio.demo.f.activiteBudget' => 'الميزانية السرية لهذا الفصل الدراسي',
			'com.studio.demo.f.partagePlanning' => 'جدول الفصل الدراسي',
			'com.studio.demo.f.partageModeration' => 'دليل الإشراف',
			'com.studio.demo.f.epinglePar' => ({required Object nom}) => 'ثبّته ${nom}',
			'com.studio.demo.f.partagePar' => ({required Object nom}) => 'شاركه ${nom}',
			'com.studio.demo.f.lienRemplacements' => 'بدلاء الأسبوع',
			'com.studio.demo.f.lienCharte' => 'ميثاق الفريق',
			'com.studio.demo.f.brouillon' => 'سميرة، سأطّلع على ملف أسرة كريم هذا المساء وأخبرك صباح الغد',
			'com.studio.demo.f.activitePaiement' => 'دفعة سبتمبر غير مؤكدة لأسرة حداد',
			'com.studio.demo.f.objetEcheancier' => 'جدول أقساط أسرة حداد',
			'com.studio.demo.f.activiteDossierKarim' => 'ملف أسرة كريم جاهز لاتخاذ قرار',
			'com.studio.demo.f.objetDossierKarim' => 'ملف أسرة كريم',
			'com.studio.demo.f.activiteMention' => 'أشارت إليك سميرة',
			'com.studio.demo.f.activiteReponse' => 'ردت أمينة على رسالتك',
			'com.studio.demo.f.activiteRemplacant' => 'اختيار المعلم البديل ليوم الثلاثاء لفصل النور',
			'com.studio.demo.f.objetRemplacement' => 'البديل ليوم الثلاثاء',
			'com.studio.demo.f.activiteOuverture' => 'المصادقة على فتح فصل صباح يوم السبت',
			'com.studio.demo.f.objetClasseSamedi' => 'فصل صباح يوم السبت',
			'com.studio.demo.f.activiteCloture' => 'إقفال شهر سبتمبر',
			'com.studio.demo.f.objetCloture' => 'إقفال سبتمبر',
			'com.studio.demo.f.activiteBilans' => 'تقييمات منتصف الفصل للمراجعة',
			'com.studio.demo.f.objetBilans' => 'تقييمات منتصف الفصل',
			'com.studio.demo.f.activiteMessages' => 'رسالتان جديدتان',
			'com.studio.demo.f.activiteAnnonce' => 'نُشر إعلان: الأكاديمية مغلقة يوم 1 نوفمبر',
			'com.studio.demo.f.objetFermeture' => 'الإغلاق يوم 1 نوفمبر',
			'com.studio.demo.f.activiteFichier' => ({required Object nom, required Object fichier}) => '${nom} شاركت ${fichier}',
			'com.studio.demo.f.activiteInscription' => 'وصل طلب تسجيل جديد',
			'com.studio.demo.f.objetDossierBenali' => 'ملف أسرة بن علي',
			'com.studio.titre' => _root.com.socle.lexique.studio,
			'com.studio.vide' => 'لا يوجد نشاط للمعالجة هنا.',
			'com.annonces.publieur.titre' => 'إعلان جديد',
			'com.annonces.publieur.etapes.contenu' => 'محتوى الإعلان',
			'com.annonces.publieur.etapes.audience' => 'مستلمو الإعلان',
			'com.annonces.publieur.etapes.programmation' => 'تاريخ النشر',
			'com.annonces.publieur.etapes.previsualisation' => 'معاينة الإعلان',
			'com.annonces.publieur.etapes.publication' => 'نشر الإعلان',
			'com.annonces.publieur.contexte.contenu' => 'اكتب ما يجب أن يعرفه المستلمون. الإعلان في اتجاه واحد: لا أحد يرد عليه.',
			'com.annonces.publieur.contexte.audience' => 'اختر من يستلم الإعلان. لا يُعرض إلا المستلمون الذين يمكنك النشر لهم.',
			'com.annonces.publieur.contexte.audienceFixee' => ({required Object cible}) => 'يُرسل هذا الإعلان إلى ${cible}. أنت تنشر لفصلك فقط.',
			'com.annonces.publieur.contexte.programmation' => 'اختر متى يُرسل الإعلان. الإعلان المجدول ينتظر تاريخه.',
			'com.annonces.publieur.contexte.previsualisation' => 'هذا هو الإعلان كما سيقرؤه المستلمون.',
			'com.annonces.publieur.contexte.publication' => 'راجع المستلمين والتاريخ، ثم انشر. لا يُنشر شيء قبل التأكيد.',
			'com.annonces.publieur.champTitre' => 'عنوان الإعلان',
			'com.annonces.publieur.champTexte' => 'نص الإعلان',
			'com.annonces.publieur.nature.classe' => 'تستلمه أسر هذا الفصل وطلابه فقط.',
			'com.annonces.publieur.nature.public' => 'يستلمه كل أفراد هذا الجمهور.',
			'com.annonces.publieur.nature.toutes' => 'تستلمه الأكاديمية كلها. خصصه لما يهم الجميع.',
			'com.annonces.publieur.quand.maintenant' => 'فور التأكيد',
			'com.annonces.publieur.quand.maintenantDetail' => 'يُرسل الإعلان فور تأكيد النشر.',
			'com.annonces.publieur.quand.creneau' => ({required Object date, required Object heure}) => 'يوم ${date} الساعة ${heure}',
			'com.annonces.publieur.quand.creneauDetail' => 'ينتظر الإعلان هذا التاريخ. ستجده في الإعلانات المجدولة.',
			'com.annonces.publieur.apercu.a' => ({required Object cible}) => 'إلى: ${cible}',
			'com.annonces.publieur.apercu.diffusionMaintenant' => 'النشر: فور التأكيد',
			'com.annonces.publieur.apercu.diffusionLe' => ({required Object date, required Object heure}) => 'النشر المقرر يوم ${date} الساعة ${heure}',
			'com.annonces.publieur.continuer' => 'متابعة',
			'com.annonces.publieur.publier' => 'نشر الإعلان',
			'com.annonces.publieur.programmer' => 'جدولة الإعلان',
			'com.annonces.publieur.reessayer' => 'إعادة محاولة النشر',
			'com.annonces.publieur.terminer' => 'إنهاء',
			'com.annonces.publieur.manqueContenu' => 'اكتب عنوانًا ونصًا للمتابعة.',
			'com.annonces.publieur.manqueAudience' => 'اختر المستلمين للمتابعة.',
			'com.annonces.publieur.enCours' => 'النشر جارٍ. انتظر التأكيد.',
			'com.annonces.publieur.publiee' => 'نُشر الإعلان. يستلمه المستلمون.',
			'com.annonces.publieur.planifiee' => ({required Object date, required Object heure}) => 'جُدول الإعلان ليوم ${date} الساعة ${heure}.',
			'com.annonces.publieur.nonConfirmee' => 'لم يُؤكَّد هذا الإعلان بعد. تحقّق من الاتصال ثم أعد المحاولة؛ لن يُرسل إلا مرة واحدة.',
			'com.annonces.publieur.horsLigne' => 'أنت غير متصل، ولم يُؤكَّد هذا الإعلان بعد. أعد المحاولة عند عودة الاتصال.',
			'com.annonces.publieur.indisponible' => 'نشر الإعلانات غير متاح بعد. عد لاحقًا.',
			'com.annonces.publieur.aucuneCibleTitre' => 'لا يوجد مستلم متاح',
			'com.annonces.publieur.aucuneCible' => 'لا يمكنك النشر لأي مستلم حاليًا. اطلب الإذن من الإدارة.',
			'com.annonces.publieur.classeRefuseeTitre' => 'النشر مقصور',
			'com.annonces.publieur.classeRefusee' => 'لا يمكنك نشر إعلان لهذا الفصل. اطلب الإذن من الإدارة.',
			'com.annonces.administration.nouvelle' => 'إعلان جديد',
			'com.annonces.administration.demo' => 'عرض تجريبي',
			'com.annonces.administration.demoDetail' => 'بيانات تجريبية: لا رقم حقيقي.',
			'com.annonces.administration.horsLigne' => 'أنت غير متصل. لا يمكن تحديث الإعلانات.',
			'com.annonces.administration.indicateurs.titre' => 'مؤشرات التواصل',
			'com.annonces.administration.indicateurs.publiees' => 'الإعلانات المنشورة',
			'com.annonces.administration.indicateurs.planifiees' => 'الإعلانات المجدولة',
			'com.annonces.administration.indicateurs.moderation' => 'محتويات قيد الإشراف',
			'com.annonces.administration.indicateurs.regles' => 'صلاحيات النشر',
			'com.annonces.administration.indicateurs.indisponible' => ({required Object libelle}) => '${libelle}: غير متاح بعد',
			'com.annonces.administration.indicateurs.echec' => ({required Object libelle}) => '${libelle}: لم يُحمَّل. تحقّق من الاتصال ثم أعد تحميل الصفحة.',
			'com.annonces.administration.indicateurs.reserve' => ({required Object libelle}) => '${libelle}: خاص بالمكلفين بالإشراف',
			'com.annonces.administration.publiees.titre' => 'الإعلانات المنشورة',
			'com.annonces.administration.publiees.vide' => 'لا توجد إعلانات منشورة في هذه الفترة.',
			'com.annonces.administration.publiees.pastille' => 'منشور',
			'com.annonces.administration.publiees.legende' => ({required Object cible, required Object date, required Object heure}) => '${cible} · يوم ${date} الساعة ${heure}',
			'com.annonces.administration.planifiees.titre' => 'الإعلانات المجدولة',
			'com.annonces.administration.planifiees.vide' => 'لا توجد إعلانات مجدولة.',
			'com.annonces.administration.planifiees.pastille' => 'مجدول',
			'com.annonces.administration.planifiees.legende' => ({required Object cible, required Object date, required Object heure}) => '${cible} · مقرر يوم ${date} الساعة ${heure}',
			'com.annonces.administration.matrice.titre' => 'صلاحيات نشر الإعلانات',
			'com.annonces.administration.matrice.detail' => 'قاعدة الأكاديمية، تُطبَّق على كل عملية نشر.',
			'com.annonces.administration.matrice.auteurs' => 'من ينشر',
			'com.annonces.administration.matrice.peutPublier' => 'يمكنه النشر',
			'com.annonces.administration.matrice.audiences' => 'المستلمون',
			'com.annonces.administration.matrice.validation' => 'يتطلب موافقة',
			'com.annonces.administration.matrice.oui' => 'نعم',
			'com.annonces.administration.matrice.non' => 'لا',
			'com.annonces.administration.matrice.aucune' => 'لا شيء',
			'com.annonces.administration.matrice.vide' => 'لم تُضبط أي صلاحية نشر.',
			'com.annonces.administration.moderation.titre' => 'قائمة الإشراف',
			'com.annonces.administration.moderation.legende' => ({required Object date, required Object heure}) => 'أُبلغ عنه يوم ${date} الساعة ${heure}',
			'com.annonces.administration.moderation.motif' => ({required Object motif}) => 'السبب: ${motif}',
			'com.annonces.administration.moderation.extraitTitre' => 'المحتوى المُبلغ عنه',
			'com.annonces.administration.moderation.extraitAbsent' => 'مقتطف هذا المحتوى غير متاح.',
			'com.annonces.administration.moderation.regle' => 'القاعدة المعنية',
			'com.annonces.administration.moderation.approuver' => 'الموافقة بعد الفحص',
			'com.annonces.administration.moderation.masquer' => 'إخفاء المحتوى',
			'com.annonces.administration.moderation.restaurer' => 'استعادة المحتوى',
			'com.annonces.administration.moderation.rejeter' => 'رفض البلاغ',
			'com.annonces.administration.moderation.contexte' => 'فتح السياق',
			'com.annonces.administration.moderation.masque' => 'مخفي',
			'com.annonces.administration.moderation.approuve' => 'تمت الموافقة',
			'com.annonces.administration.moderation.rejete' => 'رُفض البلاغ',
			'com.annonces.administration.moderation.restaure' => 'مستعاد',
			'com.annonces.administration.moderation.enregistree' => 'سُجل القرار.',
			'com.annonces.administration.moderation.nonConfirmee' => 'لم يُؤكَّد هذا القرار بعد. تحقق من الاتصال ثم أعد المحاولة.',
			'com.annonces.administration.moderation.horsLigne' => 'أنت غير متصل. لا يمكن تحديث قائمة الإشراف.',
			'com.annonces.administration.moderation.indisponible' => 'الإشراف غير متاح بعد. عد لاحقًا.',
			'com.annonces.administration.moderation.videTitre' => 'لا يوجد محتوى للفحص',
			'com.annonces.administration.moderation.vide' => 'تصل هنا بلاغات مجتمع المعلمين.',
			'com.annonces.administration.moderation.refuseTitre' => 'قائمة خاصة بالإشراف',
			'com.annonces.administration.moderation.refuse' => 'لا يرى هذه القائمة إلا المكلفون بالإشراف.',
			'com.annonces.administration.moderation.choisirTitre' => 'لا يوجد بلاغ مفتوح',
			'com.annonces.administration.moderation.choisir' => 'اختر بلاغًا من القائمة لفحصه.',
			'com.annonces.administration.moderation.sansAction' => 'لا يتاح لك أي إجراء إشراف على هذا المحتوى.',
			'com.annonces.administration.moderation.sansSanction' => 'لا تُطبق أي عقوبة على الحساب تلقائيًا.',
			'com.annonces.administration.moderation.politique' => 'سياسة منع الترويج',
			'com.annonces.administration.moderation.ouvrirSemantique' => ({required Object objet, required Object motif}) => 'فحص ${objet}‏، السبب ${motif}',
			'com.annonces.administration.moderation.regleMotif.publicite' => 'الإعلانات التجارية غير مسموح بها في مجتمع المعلّمين.',
			'com.annonces.administration.moderation.regleMotif.lienAffilie' => 'روابط التسويق بالعمولة غير مسموح بها في مجتمع المعلّمين.',
			'com.annonces.administration.moderation.regleMotif.vente' => 'بيع المنتجات أو الخدمات غير مسموح به في هذه المساحة.',
			'com.annonces.administration.moderation.regleMotif.sollicitation' => 'الاستدراج التجاري غير مسموح به في هذه المساحة.',
			'com.annonces.administration.moderation.regles.titre' => 'مشاركة تعليمية فقط',
			'com.annonces.administration.moderation.regles.corps' => 'مجتمع المعلّمين مخصّص للتبادل المهني بين المعلّمين.',
			'com.annonces.administration.moderation.regles.reglesTitre' => 'قواعد النشر',
			'com.annonces.administration.moderation.regles.pasPublicite' => 'لا إعلانات',
			'com.annonces.administration.moderation.regles.pasAffilie' => 'لا روابط تسويق بالعمولة',
			'com.annonces.administration.moderation.regles.pasVente' => 'لا بيع لمنتج أو خدمة',
			'com.annonces.administration.moderation.regles.pasSollicitation' => 'لا التماس تجاري',
			'com.annonces.administration.moderation.regles.pasDonnees' => 'لا بيانات شخصية لطالب أو عائلة',
			'com.annonces.demoPublication.lienAdministration' => 'إدارة التواصل (الإدارة)',
			'com.annonces.demoPublication.lienPublier' => 'نشر إعلان لفصل (المعلم)',
			'com.annonces.demoPublication.toutes' => 'الأكاديمية كلها',
			'com.annonces.demoPublication.familles' => 'الأسر',
			'com.annonces.demoPublication.enseignants' => 'المعلمون',
			'com.annonces.demoPublication.eleves' => 'الطلاب',
			'com.annonces.demoPublication.controleurs' => 'المراقبون',
			'com.annonces.demoPublication.direction' => 'الإدارة',
			'com.annonces.demoPublication.audiencesDirection' => 'الأكاديمية كلها، أو جمهور، أو فصل',
			'com.annonces.demoPublication.audiencesEnseignant' => 'فصله فقط',
			'com.annonces.demoPublication.vacancesTitre' => 'تقويم عطلة الشتاء',
			'com.annonces.demoPublication.vacancesTexte' => 'تتوقف الدروس من 21 ديسمبر إلى 5 يناير. تُستأنف الحصص يوم الاثنين 6 يناير في المواعيد المعتادة.',
			'com.annonces.demoPublication.reunionTitre' => 'اجتماع المعلمين يوم الخميس',
			'com.annonces.demoPublication.reunionTexte' => 'يبدأ الاجتماع التربوي يوم الخميس الساعة 18، عبر الاتصال المرئي. جدول الأعمال في الاستوديو.',
			'com.annonces.demoPublication.recitationTitre' => 'تلاوة نهاية الفصل الدراسي',
			'com.annonces.demoPublication.recitationTexte' => 'سيقدم فصل النور تلاوة نهاية الفصل الدراسي يوم السبت الساعة 10، عبر الاتصال المرئي.',
			'com.annonces.demoPublication.rentreeTitre' => 'استئناف الدروس بعد العطلة',
			'com.annonces.demoPublication.rentreeTexte' => 'تُستأنف الحصص يوم الاثنين 6 يناير في المواعيد المعتادة.',
			'com.annonces.demoPublication.signalementAffilie' => 'منشور «بطاقات تجويد للطباعة»',
			'com.annonces.demoPublication.extraitAffilie' => 'تجدون بطاقاتي عبر هذا الرابط الشريك، خصم 20 % برمزي.',
			'com.annonces.demoPublication.signalementVente' => 'منشور «دروس خصوصية متاحة»',
			'com.annonces.demoPublication.extraitVente' => 'أقدم دروسًا خصوصية مدفوعة في عطلة نهاية الأسبوع، راسلوني.',
			'com.annonces.demoPublication.signalementHorsSujet' => 'رد تحت «تنظيم مراجعة جماعية»',
			'com.annonces.section' => 'إعلانات الفصل',
			'com.annonces.annonce' => 'إعلان',
			'com.annonces.publier' => 'نشر إعلان',
			'com.annonces.videPublier' => 'لا توجد إعلانات لهذا الفصل. انشر أول إعلان للفصل كله.',
			'com.annonces.auteurDate' => ({required Object auteur, required Object date, required Object heure}) => '${auteur}‏، يوم ${date} الساعة ${heure}',
			'com.annonces.date' => ({required Object date, required Object heure}) => 'يوم ${date} الساعة ${heure}',
			'com.annonces.lire' => 'قراءة الإعلان كاملًا',
			'com.annonces.ouvrirClasse' => 'فتح الفصل',
			'com.annonces.ouvrirClasseSemantique' => ({required Object classe}) => 'فتح ${classe}',
			'com.annonces.marquerLue' => 'تحديد كمقروء',
			'com.annonces.lue' => 'مقروء',
			'com.annonces.carteSemantique' => ({required Object classe, required Object titre}) => 'إعلان ${classe}: ${titre}',
			'com.annonces.introuvableTitre' => 'هذا الإعلان لم يعد متاحًا',
			'com.annonces.introuvablePhrase' => 'ربما سُحب من الفصل. عد إلى إشعاراتك.',
			'com.annonces.demo.detail' => 'عرض تجريبي خارج الإنتاج: بيانات وهمية، ولا يُرسل شيء.',
			'com.annonces.demo.choisirRole' => 'اختر الدور المراد عرضه',
			'com.annonces.demo.roles.tuteur' => 'الأسرة',
			'com.annonces.demo.roles.enseignant' => 'المعلم',
			'com.annonces.demo.roles.adulte' => 'الطالب البالغ',
			'com.annonces.demo.roles.admin' => 'الإدارة',
			'com.annonces.demo.roles.controleur' => 'المراقب',
			'com.annonces.demo.classeNour' => 'فصل النور',
			'com.annonces.demo.classeFajr' => 'فصل الفجر',
			'com.annonces.demo.enseignante' => 'معلمة الفصل',
			'com.annonces.demo.f.adminStudioMention' => 'الاستوديو: نقاش في قناة البرامج يشير إليك',
			'com.annonces.demo.f.adminStudioReponse' => 'الاستوديو: رد جديد على رسالتك بشأن برنامج الربيع',
			'com.annonces.demo.f.adminStudioDecision' => 'الاستوديو: مطلوب قرار بشأن مادة الدرس 4',
			'com.annonces.demo.f.adminStudioAssigne' => 'الاستوديو: أُسندت إليك مراجعة مادة التجويد',
			'com.annonces.demo.f.adminStudioInterne' => 'إعلان داخلي لفريق الاستوديو: اجتماع الفريق يوم الخميس الساعة 18',
			'com.annonces.demo.f.adminStudioContexte' => 'الاستوديو: مادة جاهزة لفصل النور',
			'com.annonces.demo.f.annonceNourTitre' => 'تلاوة نهاية الفصل الدراسي أمام الأسر',
			'com.annonces.demo.f.annonceNourTexte' => 'أسرنا الكريمة، سيقدم فصل النور تلاوة نهاية الفصل الدراسي يوم السبت 14 ديسمبر الساعة 10، عبر الاتصال المرئي. سيتلو كل طالب السورة التي عمل عليها خلال هذا الفصل الدراسي. يرجى تجهيز اتصال مستقر ومكان هادئ. يمكن للطلاب الراغبين التدرب خلال حصة الأربعاء السابقة. يمكن للأسر الحضور بصمت مع كتم الميكروفون. سيُشارك تقرير بعد الحصة.',
			'com.annonces.demo.f.annonceFajrTitre' => 'مراجعة قبل تقييم يوم الخميس',
			'com.annonces.demo.f.annonceFajrTexte' => 'راجعوا الآيات العشر الأخيرة من سورة الملك قبل يوم الخميس.',
			'com.annonces.demo.f.tuteurUrgent' => 'حصة هذا المساء ملغاة',
			'com.annonces.demo.f.tuteurUrgentTexte' => 'المعلمة غائبة هذا المساء. أُجّلت الحصة إلى يوم الخميس في الوقت نفسه. لا شيء عليك فعله.',
			'com.annonces.demo.f.tuteurReponse' => 'رد منتظر: الموافقة على تلاوة ياسمين',
			'com.annonces.demo.f.tuteurReponseTexte' => 'تنتظر المعلمة موافقتك لتتلو ياسمين أمام الأسر. أجبها من فضاء الفصل.',
			'com.annonces.demo.f.tuteurMessage' => 'رسالة جديدة من معلمة فصل النور',
			'com.annonces.demo.f.tuteurDossier' => 'تم قبول ملف التسجيل الخاص بك',
			'com.annonces.demo.f.adulteSeance' => 'نُقلت حصتك يوم الثلاثاء إلى الساعة 19',
			'com.annonces.demo.f.adulteMessage' => 'رسالة جديدة من معلمتك',
			'com.annonces.demo.f.enseignantFamille' => 'رسالة من أسرة ياسمين، فصل النور',
			'com.annonces.demo.f.enseignantDirection' => 'إعلان من الإدارة: جدول عطلة الشتاء',
			'com.annonces.demo.f.enseignantDirectionTexte' => 'تتوقف الدروس من 21 ديسمبر إلى 5 يناير. تُستأنف الحصص يوم الاثنين 6 يناير في المواعيد المعتادة.',
			'com.annonces.demo.f.enseignantPlanning' => 'تغيّر جدولك للأسبوع القادم',
			'com.annonces.demo.f.enseignantMention' => 'منشور في مجتمع المعلمين يشير إليك',
			'com.annonces.demo.f.enseignantReponse' => 'رد جديد على منشورك',
			'com.annonces.demo.f.enseignantAdministration' => 'رسالة من الإدارة: وثائق مطلوبة',
			'com.annonces.demo.f.adminDossiers' => 'ثلاثة ملفات تسجيل في انتظار المعالجة',
			'com.annonces.demo.f.adminSignalement' => 'تم الإبلاغ عن منشور في مجتمع المعلمين',
			'com.annonces.demo.f.adminReponse' => 'رد أسرة بلال على رسالتك',
			'com.annonces.demo.f.adminPlanifiee' => 'إعلان مجدول يحتاج إلى مراجعة قبل النشر',
			'com.annonces.demo.f.adminOperationnel' => 'فصل النور: العدد مكتمل',
			'com.annonces.demo.f.controleurMission' => 'مهمة جديدة: زيارة فصل النور',
			'com.annonces.demo.f.controleurChangement' => 'نُقلت مهمتك يوم الخميس إلى الساعة 18',
			'com.annonces.demo.f.controleurReponse' => 'رد الإدارة على تقريرك',
			'com.annonces.titre' => 'الإعلانات',
			'choix.autre' => 'آخر',
			'choix.autreInvite' => 'حدّد',
			'choix.selectionMultiple' => 'يمكن اختيار أكثر من إجابة',
			'destructif.irreversible' => 'لا يمكن التراجع عن هذا الإجراء.',
			'reseau.horsLigne' => 'لا توجد شبكة. يبقى كل شيء متاحًا للاطلاع، وسينتظر الإرسال.',
			'admin.evaluations.manqueResultat' => 'اختر أولًا نتيجة التقييم.',
			'admin.programmes.publierSansNiveau' => 'أضف مستوى واحدًا على الأقل لتتمكن من نشر هذه النسخة.',
			'admin.finance.aValider' => 'للمصادقة',
			'comptable.nav.aujourdhui' => 'اليوم',
			'comptable.nav.paiements' => 'المدفوعات',
			'comptable.nav.tresorerie' => 'الخزينة',
			'comptable.nav.compte' => 'الحساب',
			'comptable.onglets.aEffectuer' => 'للتنفيذ',
			'comptable.onglets.contractuels' => 'المتعاقدون',
			'comptable.onglets.beneficiaires' => 'المستفيدون',
			'comptable.onglets.coffres' => 'الصناديق',
			'comptable.onglets.encaissements' => 'المقبوضات',
			'comptable.onglets.rapprochement' => 'المطابقة',
			'comptable.commun.montantMasque' => 'مبلغ مخفي',
			'comptable.commun.afficherMontants' => 'إظهار المبالغ',
			'comptable.commun.masquerMontants' => 'إخفاء المبالغ',
			'comptable.commun.montantsMasques' => 'المبالغ مخفية',
			'comptable.commun.montantsAffiches' => 'المبالغ ظاهرة',
			'comptable.commun.enPreparationTitre' => 'هذه الشاشة قيد الإعداد.',
			'comptable.commun.enPreparationPhrase' => 'لا يُعرض هنا أي رقم في الوقت الحالي. لا يمكن تنفيذ أي دفعة من هذه الشاشة.',
			'comptable.commun.reserveStrategique' => 'الاحتياطي الاستراتيجي',
			'comptable.commun.tresorerieLibre' => 'الخزينة الحرة',
			'comptable.commun.tresorerieDetenue' => 'الخزينة المحتفَظ بها',
			'comptable.commun.fondsProteges' => 'الأموال المحمية',
			'comptable.commun.enTransit' => 'قيد التحويل',
			'comptable.commun.tresorerieLibreDetail' => 'ما يبقى متاحًا فعلًا بعد الأموال المحمية والالتزامات والمبالغ قيد التحويل.',
			'comptable.commun.objectifFixe' => 'الهدف: مبلغ ثابت',
			'comptable.commun.objectifMois' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, one: 'الهدف الحالي: شهر واحد من المصاريف الأساسية', two: 'الهدف الحالي: شهران من المصاريف الأساسية', few: 'الهدف الحالي: ${n} أشهر من المصاريف الأساسية', many: 'الهدف الحالي: ${n} شهرًا من المصاريف الأساسية', other: 'الهدف الحالي: ${n} شهر من المصاريف الأساسية', ), 
			'comptable.commun.montantActuel' => 'المبلغ الحالي',
			'comptable.commun.manque' => 'المتبقي لبلوغ الهدف',
			'comptable.commun.atteint' => ({required Object pourcent}) => 'تحقق ${pourcent} %',
			'comptable.commun.modeCalcul' => 'طريقة الحساب',
			'comptable.commun.modeMontantFixe' => 'مبلغ مستهدف ثابت',
			'comptable.commun.modeCouvertureMois' => 'تغطية بعدد أشهر المصاريف الأساسية',
			'comptable.commun.derniereAllocation' => ({required Object date}) => 'آخر تخصيص: ${date}',
			'comptable.commun.prochaineAllocation' => ({required Object date}) => 'التخصيص القادم المقرر: ${date}',
			'comptable.commun.aucuneAllocation' => 'لا يوجد أي تخصيص مسجل',
			'comptable.commun.destination' => 'الوجهة',
			'comptable.commun.destinationMasquee' => ({required Object type, required Object suffixe}) => '${type} •••• ${suffixe}',
			'comptable.commun.destinationMasqueeLecteur' => ({required Object type, required Object suffixe}) => '${type}، الرقم مخفي، ينتهي بـ ${suffixe}',
			'comptable.commun.destinationAucune' => 'لا توجد وسيلة دفع',
			'comptable.commun.paysDevise' => ({required Object pays, required Object devise}) => '${pays} · ${devise}',
			'comptable.commun.verification' => 'التحقق',
			'comptable.commun.activiteInitiateurDate' => ({required Object initiateur, required Object date}) => '${initiateur} · ${date}',
			'comptable.commun.activiteTransition' => ({required Object avant, required Object apres}) => '${avant} ← ${apres}',
			'comptable.commun.activiteReference' => ({required Object reference}) => 'المرجع ${reference}',
			'comptable.commun.relancePreparee' => 'تذكير جاهز (عرض توضيحي)',
			'comptable.commun.prestataireDemonstration' => ({required Object nom}) => '${nom} (عرض توضيحي)',
			'comptable.commun.date' => ({required Object jour, required Object mois, required Object annee}) => '${jour} ${mois} ${annee}',
			'comptable.commun.aucuneValeur' => 'غير محدد',
			'comptable.coffres.fondsClientsEngages' => 'أموال العملاء الملتزَم بها',
			'comptable.coffres.paieADecaisser' => 'رواتب مستحقة الصرف',
			'comptable.coffres.chargesEssentielles' => 'المصاريف الأساسية',
			'comptable.coffres.taxesObligations' => 'الضرائب والالتزامات',
			'comptable.coffres.reserveStrategique' => 'الاحتياطي الاستراتيجي',
			'comptable.coffres.enTransit' => 'قيد التحويل',
			'comptable.coffres.tresorerieLibre' => 'الخزينة الحرة',
			'comptable.statuts.paiement.aCalculer' => 'قيد الحساب',
			'comptable.statuts.paiement.calcule' => 'محسوب',
			'comptable.statuts.paiement.aVerifier' => 'للتحقق',
			'comptable.statuts.paiement.infosManquantes' => 'معلومات الدفع ناقصة',
			'comptable.statuts.paiement.verificationRequise' => 'يلزم التحقق من الدفع',
			'comptable.statuts.paiement.pretAPayer' => 'جاهز للدفع',
			'comptable.statuts.paiement.validationRequise' => 'تلزم مصادقة إضافية',
			'comptable.statuts.paiement.soumis' => 'مُرسَل',
			'comptable.statuts.paiement.enTransit' => 'قيد التحويل',
			'comptable.statuts.paiement.reussi' => 'ناجح',
			'comptable.statuts.paiement.echoue' => 'فاشل',
			'comptable.statuts.paiement.aRelancer' => 'للتذكير',
			'comptable.statuts.paiement.annule' => 'ملغى',
			'comptable.statuts.paiement.retourne' => 'مُسترَد / مُعاد',
			'comptable.statuts.paiement.indisponible' => 'غير متاح',
			'comptable.statuts.encaissement.enAttente' => 'قيد الانتظار',
			'comptable.statuts.encaissement.confirme' => 'مؤكَّد',
			'comptable.statuts.encaissement.echoue' => 'فاشل',
			'comptable.statuts.encaissement.rembourse' => 'مُسترَد',
			'comptable.statuts.encaissement.partiellementRembourse' => 'مُسترَد جزئيًا',
			'comptable.statuts.encaissement.conteste' => 'متنازَع عليه',
			'comptable.statuts.encaissement.chargeback' => 'استرجاع بنكي',
			'comptable.statuts.encaissement.aRapprocher' => 'للمطابقة',
			'comptable.statuts.encaissement.rapproche' => 'مطابَق',
			'comptable.statuts.rapprochement.automatique' => 'تلقائي',
			'comptable.statuts.rapprochement.aVerifier' => 'للتحقق',
			'comptable.statuts.rapprochement.rapproche' => 'مطابَق',
			'comptable.statuts.rapprochement.conflit' => 'تعارض',
			'comptable.statuts.rapprochement.sansCorrespondance' => 'بلا مقابل',
			'comptable.statuts.rapprochement.doublonPotentiel' => 'تكرار محتمل',
			'comptable.statuts.profil.aucunMoyen' => 'لا توجد وسيلة',
			'comptable.statuts.profil.incomplet' => 'غير مكتمل',
			'comptable.statuts.profil.enVerification' => 'قيد التحقق',
			'comptable.statuts.profil.verifie' => 'تم التحقق',
			'comptable.statuts.profil.suspendu' => 'موقوف',
			'comptable.statuts.profil.actionRequise' => 'يلزم إجراء',
			'comptable.statuts.profil.invitationEnvoyee' => 'أُرسلت الدعوة',
			'comptable.statuts.capacite.prisEnCharge' => 'مدعوم',
			'comptable.statuts.capacite.nonPrisEnCharge' => 'غير مدعوم',
			'comptable.statuts.capacite.temporairementIndisponible' => 'غير متاح مؤقتًا',
			'comptable.statuts.capacite.verificationRequise' => 'يلزم التحقق',
			'comptable.statuts.capacite.soldePrestataireInsuffisant' => 'رصيد مزوّد الدفع غير كافٍ',
			'comptable.statuts.reserve.atteint' => 'تحقق الهدف',
			'comptable.statuts.reserve.sousObjectif' => 'دون الهدف',
			'comptable.statuts.reserve.depassement' => 'تجاوز الهدف',
			'comptable.statuts.reserve.regleInactive' => 'القاعدة غير مفعّلة',
			'comptable.statuts.reserve.alimentationPrevue' => 'تغذية مقررة',
			'comptable.statuts.reserve.mouvementSensible' => 'حركة حساسة',
			'comptable.statuts.obligation.brouillon' => 'مسودة',
			'comptable.statuts.obligation.aApprouver' => 'للاعتماد',
			'comptable.statuts.obligation.approuvee' => 'معتمَد',
			'comptable.statuts.obligation.refusee' => 'مرفوض',
			'comptable.statuts.obligation.payable' => 'قابل للدفع',
			'comptable.statuts.obligation.payee' => 'مدفوع',
			'comptable.statuts.obligation.annulee' => 'ملغى',
			'comptable.statuts.remboursement.demande' => 'مطلوب',
			'comptable.statuts.remboursement.approbationRequise' => 'يلزم الاعتماد',
			'comptable.statuts.remboursement.approuve' => 'معتمَد',
			'comptable.statuts.remboursement.execute' => 'منفَّذ',
			'comptable.statuts.remboursement.refuse' => 'مرفوض',
			'comptable.statuts.validation.enAttente' => 'طُلبت المصادقة',
			'comptable.statuts.validation.validee' => 'تمت المصادقة',
			'comptable.statuts.validation.refusee' => 'مرفوضة',
			'comptable.statuts.raison.autoPaiement' => 'يلزم أن يعالجه مسؤول آخر',
			'comptable.statuts.raison.validationRequise' => 'تلزم مصادقة إضافية',
			'comptable.statuts.raison.infosManquantes' => 'معلومات الدفع ناقصة',
			'comptable.statuts.raison.verificationRequise' => 'يلزم التحقق من الدفع',
			'comptable.statuts.raison.horsDelegation' => 'خارج التفويض',
			'comptable.statuts.raison.fournisseurIndisponible' => 'المزوّد غير متاح',
			'comptable.statuts.raison.fondsInsuffisants' => 'الأموال غير كافية',
			'comptable.statuts.raison.doublonPotentiel' => 'تكرار محتمل',
			'comptable.statuts.raison.nonApprouvee' => 'التزام غير معتمَد',
			'comptable.statuts.raison.capaciteAbsente' => 'القدرة غير متوفرة',
			'comptable.alertes.enseignantsAPayer' => 'معلمون للدفع',
			'comptable.alertes.contractuelsAEcheance' => 'متعاقدون حان موعد استحقاقهم',
			'comptable.alertes.infosManquantes' => 'معلومات الدفع ناقصة',
			'comptable.alertes.payoutEchoue' => 'فشل صرف دفعة',
			'comptable.alertes.paiementFamilleEchoue' => 'فشل دفع أسرة',
			'comptable.alertes.transactionNonRapprochee' => 'معاملة غير مطابَقة',
			'comptable.alertes.remboursementEnAttente' => 'استرداد قيد الانتظار',
			'comptable.alertes.reserveSousObjectif' => 'الاحتياطي الاستراتيجي دون الهدف',
			'comptable.alertes.soldePrestataireInsuffisant' => 'رصيد مزوّد الدفع غير كافٍ',
			'comptable.alertes.methodeModifieeRecemment' => 'وسيلة دفع عُدّلت مؤخرًا',
			'comptable.alertes.doublonPotentiel' => 'تكرار محتمل',
			'comptable.alertes.validationRequise' => 'تلزم مصادقة إضافية',
			'comptable.aujourdhui.attentionSousTitre' => 'ما ينتظر إجراءً منك، ثم المخاطر التي تجب مراقبتها.',
			'comptable.aujourdhui.elementCompteur' => ({required Object libelle, required Object n}) => '${libelle}: ${n}',
			'comptable.aujourdhui.elementDepuis' => ({required Object date}) => 'قيد الانتظار منذ ${date}',
			'comptable.aujourdhui.aTraiterVide' => 'لا شيء للمعالجة اليوم.',
			'comptable.aujourdhui.aTraiterVideDetail' => 'ستظهر هنا المدفوعات والتذكيرات والمطابقات المطلوبة.',
			'comptable.aujourdhui.alertesVide' => 'لا توجد تنبيهات حاليًا.',
			'comptable.aujourdhui.alertesResume' => ({required Object n}) => 'تنبيهات للمراقبة: ${n}',
			'comptable.aujourdhui.paiementsAEffectuer' => 'مدفوعات للتنفيذ',
			'comptable.aujourdhui.paiementsAEffectuerDetail' => 'تُراجَع كل دفعة في قائمتها قبل دفعها.',
			'comptable.aujourdhui.paiementsVide' => 'لا توجد مدفوعات للتنفيذ.',
			'comptable.aujourdhui.echeancesVide' => 'لا توجد مواعيد استحقاق قريبة.',
			'comptable.aujourdhui.encaissementsVide' => 'لا توجد مقبوضات حديثة.',
			'comptable.aujourdhui.activiteVide' => 'لا يوجد نشاط حديث.',
			_ => null,
		} ?? switch (path) {
			'comptable.aujourdhui.prestatairesVide' => 'لا يوجد مزوّد دفع مفعّل.',
			'comptable.aujourdhui.prestatairesVideDetail' => 'ستنطلق المدفوعات الصادرة عندما تفعّل الإدارة مزوّد دفع.',
			'comptable.aujourdhui.accesPaiements' => 'عرض المدفوعات للتنفيذ',
			'comptable.aujourdhui.accesContractuels' => 'إدارة التزامات المتعاقدين',
			'comptable.aujourdhui.accesEncaissements' => 'عرض المقبوضات',
			'comptable.aujourdhui.accesTresorerie' => 'عرض الخزينة والصناديق',
			'comptable.aujourdhui.accesAlimenter' => 'تغذية الاحتياطي الاستراتيجي',
			'comptable.aujourdhui.titre' => 'اليوم',
			'comptable.aujourdhui.sousTitre' => 'ماذا عليّ أن أفعل الآن؟',
			'comptable.aujourdhui.attention' => 'للمعالجة والتنبيهات',
			'comptable.aujourdhui.aTraiter' => 'للمعالجة اليوم',
			'comptable.aujourdhui.aTraiterHorsPaiements' => 'مهام أخرى',
			'comptable.aujourdhui.alertes' => 'التنبيهات',
			'comptable.aujourdhui.echeances' => 'مواعيد استحقاق قريبة',
			'comptable.aujourdhui.prestataires' => 'مزوّدو الدفع',
			'comptable.aujourdhui.activiteRecente' => 'النشاط الحديث',
			'comptable.aujourdhui.accesRapides' => 'وصول سريع',
			'comptable.aujourdhui.encaissementsRecents' => 'المقبوضات الحديثة',
			'comptable.aujourdhui.voirTout' => 'عرض الكل',
			'comptable.paiements.confirmation.titreUn' => 'تأكيد الدفعة',
			'comptable.paiements.confirmation.titreLot' => 'تأكيد الدفعة المجمّعة',
			'comptable.paiements.confirmation.titreValidation' => 'طلب مصادقة',
			'comptable.paiements.confirmation.payerMaintenant' => 'ادفع الآن',
			'comptable.paiements.confirmation.controleEchoueTitre' => 'توقف الفحص',
			'comptable.paiements.confirmation.controleEchoue' => 'لم يكتمل فحص التحديد. لم يُرسَل أي شيء. أعد تشغيل الفحص.',
			'comptable.paiements.confirmation.relancerControle' => 'إعادة تشغيل الفحص',
			'comptable.paiements.confirmation.montant' => 'المبلغ الدقيق',
			'comptable.paiements.confirmation.beneficiaire' => 'المستفيد',
			'comptable.paiements.confirmation.devise' => 'العملة',
			'comptable.paiements.confirmation.type' => 'النوع',
			'comptable.paiements.confirmation.periode' => 'الفترة / الموضوع',
			'comptable.paiements.confirmation.prestataire' => 'مزوّد الدفع المقرر',
			'comptable.paiements.confirmation.prestataireAucun' => 'لم يُرجعه المصدر',
			'comptable.paiements.confirmation.taux' => 'سعر الصرف',
			'comptable.paiements.confirmation.tauxDate' => ({required Object taux, required Object date}) => '${taux}، بتاريخ ${date}',
			'comptable.paiements.confirmation.frais' => 'رسوم مزوّد الدفع',
			'comptable.paiements.confirmation.change' => 'تكلفة الصرف',
			'comptable.paiements.confirmation.montantEnvoye' => 'إجمالي المُرسَل',
			'comptable.paiements.confirmation.montantRecu' => 'المبلغ المتوقع استلامه',
			'comptable.paiements.confirmation.controlesTitre' => 'الفحوص المجتازة',
			'comptable.paiements.confirmation.controlesPhrase' => 'المبلغ محسوب، ووسيلة الدفع متحقَّق منها، والتفويض والتكرارات مفحوصة من المصدر. لن تُرسَل إلا المدفوعات الجاهزة.',
			'comptable.paiements.confirmation.sensiblePhrase' => 'هذه الدفعة حساسة: يجب أن يصادق عليها شخص مخوَّل آخر. اطلب المصادقة، فهي لا تُرسَل قبلها.',
			'comptable.paiements.confirmation.prets' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, one: 'دفعة جاهزة واحدة', two: 'دفعتان جاهزتان', few: '${n} دفعات جاهزة', other: '${n} دفعة جاهزة', ), 
			'comptable.paiements.confirmation.exclus' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, one: 'دفعة مستبعدة واحدة', two: 'دفعتان مستبعدتان', few: '${n} دفعات مستبعدة', other: '${n} دفعة مستبعدة', ), 
			'comptable.paiements.confirmation.total' => 'إجمالي المدفوعات الجاهزة',
			'comptable.paiements.confirmation.beneficiairesCle' => 'المستفيدون',
			'comptable.paiements.confirmation.beneficiaires' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, one: 'مستفيد واحد', two: 'مستفيدان', few: '${n} مستفيدين', other: '${n} مستفيدًا', ), 
			'comptable.paiements.confirmation.devises' => 'العملات',
			'comptable.paiements.confirmation.prestataires' => 'مزوّدو الدفع',
			'comptable.paiements.confirmation.plafond' => 'التفويض المتبقي',
			'comptable.paiements.confirmation.exclusTitre' => 'مستبعدة من هذه الدفعة المجمّعة: لن تُرسَل',
			'comptable.paiements.confirmation.aucunPretTitre' => 'لا توجد دفعة جاهزة',
			'comptable.paiements.confirmation.aucunPret' => 'لن يُرسَل أي شيء. افتح كل دفعة مستبعدة لإزالة سببها، ثم أعد تشغيل الفحص.',
			'comptable.paiements.confirmation.erreursTitre' => 'أخطاء أرجعها الفحص',
			'comptable.paiements.confirmation.confirmerUn' => ({required Object montant}) => 'تأكيد دفع ${montant}',
			'comptable.paiements.confirmation.confirmerLot' => ({required num n, required Object montants}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, one: 'تأكيد الدفعة الجاهزة بمبلغ ${montants}', two: 'تأكيد الدفعتين الجاهزتين: ${montants}', few: 'تأكيد ${n} دفعات جاهزة: ${montants}', other: 'تأكيد ${n} دفعة جاهزة: ${montants}', ), 
			'comptable.paiements.confirmation.demanderValidation' => 'طلب المصادقة',
			'comptable.paiements.confirmation.annuler' => 'إلغاء',
			'comptable.paiements.confirmation.fermer' => 'إغلاق',
			'comptable.paiements.confirmation.soumisTitre' => 'أُرسلت إلى مزوّد الدفع',
			'comptable.paiements.confirmation.soumisPhrase' => 'الدفعة المُرسَلة لم تُستلَم بعد: حالتها تأتي من متابعة مزوّد الدفع. حدّث المتابعة لترى تقدمها.',
			'comptable.paiements.confirmation.actualiser' => 'تحديث المتابعة',
			'comptable.paiements.confirmation.suiviEchoue' => 'تعذرت قراءة المتابعة. تبقى الدفعة مُرسَلة: حدّث مرة أخرى بعد قليل.',
			'comptable.paiements.confirmation.referenceCle' => 'مرجع مزوّد الدفع',
			'comptable.paiements.confirmation.recalculeTitre' => 'أُعيد حساب المبلغ',
			'comptable.paiements.confirmation.recalculePhrase' => 'تغيّر حساب في المصدر منذ الفحص. لم يُرسَل أي شيء. أعد تشغيل الفحص لتأكيد المبلغ الجديد.',
			'comptable.paiements.confirmation.nouveauMontant' => ({required Object nom}) => 'المبلغ الجديد لـ ${nom}',
			'comptable.paiements.confirmation.refusTitre' => 'رفض المصدر الدفعة',
			'comptable.paiements.confirmation.refusDejaSoumis' => 'سبق إرسال هذه الدفعة: لن يُعاد إرسال أي شيء. تابعها من تبويب المدفوعات الجارية.',
			'comptable.paiements.confirmation.refusHorsDelegation' => 'يتجاوز المجموع تفويضك، لكل مستفيد أو لكل فترة. لم يُرسَل أي شيء. أعد تشغيل الفحص: ستُستبعد المدفوعات المعنية.',
			'comptable.paiements.confirmation.refusPerime' => 'انتهت صلاحية الفحص. لم يُرسَل أي شيء. أعد تشغيل الفحص قبل التأكيد.',
			'comptable.paiements.confirmation.refusFournisseur' => 'أصبح مزوّد الدفع غير متاح. لم يُرسَل أي شيء. أعد تشغيل الفحص بعد قليل.',
			'comptable.paiements.confirmation.inconnuTitre' => 'نتيجة غير معروفة',
			'comptable.paiements.confirmation.inconnuPhrase' => 'لم يصلنا الرد: ربما أُرسلت الدفعة. أعد المحاولة: يُعاد إرسال الطلب نفسه ولن يُنفَّذ إلا مرة واحدة.',
			'comptable.paiements.confirmation.reessayer' => 'إعادة المحاولة',
			'comptable.paiements.confirmation.validationDemandeeTitre' => 'طُلبت المصادقة',
			'comptable.paiements.confirmation.validationDemandeePhrase' => 'سيصادق شخص مخوَّل آخر على هذه الدفعة. لن تُرسَل قبل قراره.',
			'comptable.paiements.confirmation.validationEchouee' => 'لم يكتمل طلب المصادقة. أعد المحاولة: لن يُسجَّل إلا مرة واحدة.',
			'comptable.paiements.filtres.tous' => 'الكل',
			'comptable.paiements.filtres.enseignants' => 'المعلمون',
			'comptable.paiements.filtres.contractuels' => 'المتعاقدون',
			'comptable.paiements.filtres.statut' => 'الحالة',
			'comptable.paiements.filtres.tousStatuts' => 'كل الحالات',
			'comptable.paiements.filtres.prets' => 'جاهزة',
			'comptable.paiements.filtres.infos' => 'معلومات ناقصة',
			'comptable.paiements.filtres.verification' => 'التحقق',
			'comptable.paiements.filtres.validation' => 'المصادقة',
			'comptable.paiements.filtres.retard' => 'متأخرة',
			'comptable.paiements.filtres.classe' => 'الفصل',
			'comptable.paiements.filtres.toutesClasses' => 'كل الفصول',
			'comptable.paiements.filtres.periode' => 'الفترة',
			'comptable.paiements.filtres.toutesPeriodes' => 'كل الفترات',
			'comptable.paiements.filtres.effacer' => 'مسح عوامل التصفية',
			'comptable.paiements.colonnes.beneficiaire' => 'المستفيد',
			'comptable.paiements.colonnes.type' => 'النوع',
			'comptable.paiements.colonnes.periode' => 'الفترة / الموضوع',
			'comptable.paiements.colonnes.montant' => 'المبلغ',
			'comptable.paiements.colonnes.destination' => 'الوجهة',
			'comptable.paiements.colonnes.echeance' => 'الاستحقاق',
			'comptable.paiements.colonnes.statut' => 'الحالة',
			'comptable.paiements.colonnes.action' => 'الإجراء',
			'comptable.paiements.types.enseignant' => 'معلم',
			'comptable.paiements.types.contractuel' => 'متعاقد',
			'comptable.paiements.compteur' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, one: 'دفعة واحدة', two: 'دفعتان', few: '${n} دفعات', other: '${n} دفعة', ), 
			'comptable.paiements.actions.voir' => 'عرض',
			'comptable.paiements.actions.payer' => 'دفع',
			'comptable.paiements.actions.demanderValidation' => 'طلب المصادقة',
			'comptable.paiements.actions.relancer' => 'تذكير',
			'comptable.paiements.actions.signalerEcart' => 'الإبلاغ عن فرق',
			'comptable.paiements.actions.selectionner' => ({required Object nom}) => 'تحديد دفعة ${nom}',
			'comptable.paiements.actions.selectionnerPrets' => 'تحديد كل المدفوعات الجاهزة',
			'comptable.paiements.actions.payerSelection' => 'دفع المحدد',
			'comptable.paiements.actions.viderSelection' => 'إلغاء التحديد',
			'comptable.paiements.actions.voirProfil' => 'عرض ملف الدفع',
			'comptable.paiements.selection' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, one: 'دفعة واحدة محددة', two: 'دفعتان محددتان', few: '${n} دفعات محددة', other: '${n} دفعة محددة', ), 
			'comptable.paiements.selectionPhrase' => 'يُرجع الفحص الإجمالي والاستبعادات قبل أي إرسال.',
			'comptable.paiements.horsLigneCourt' => 'غير متصل: الدفع غير ممكن',
			'comptable.paiements.vide.message' => 'لا توجد مدفوعات للتنفيذ.',
			'comptable.paiements.vide.invitation' => 'تظهر الالتزامات هنا بمجرد حسابها في المصدر.',
			'comptable.paiements.vide.filtreMessage' => 'لا توجد دفعة تطابق عوامل التصفية هذه.',
			'comptable.paiements.vide.filtreInvitation' => 'امسح عوامل التصفية لرؤية كل المدفوعات مجددًا.',
			'comptable.paiements.horsLigne' => 'غير متصل: لا تُرسَل أي دفعة دون شبكة. أعد الاتصال لتدفع.',
			'comptable.paiements.detail.total' => 'الإجمالي المستحق',
			'comptable.paiements.detail.lignes' => 'تفاصيل الحساب',
			'comptable.paiements.detail.ligneTotal' => 'الإجمالي',
			'comptable.paiements.detail.source' => ({required Object source}) => 'المصدر: ${source}',
			'comptable.paiements.detail.auteur' => ({required Object auteur}) => 'أضافه ${auteur}',
			'comptable.paiements.detail.voirSource' => 'عرض المصدر',
			'comptable.paiements.detail.methode' => 'وسيلة الدفع',
			'comptable.paiements.detail.informations' => 'المعلومات',
			'comptable.paiements.detail.type' => 'النوع',
			'comptable.paiements.detail.periode' => 'الفترة / الموضوع',
			'comptable.paiements.detail.echeance' => 'الاستحقاق',
			'comptable.paiements.detail.prestataire' => 'مزوّد الدفع المقرر',
			'comptable.paiements.detail.preuve' => 'الإثبات',
			'comptable.paiements.detail.classes' => 'الفصول',
			'comptable.paiements.detail.version' => 'إصدار الحساب',
			'comptable.paiements.detail.historique' => 'السجل',
			'comptable.paiements.detail.historiqueVide' => 'لا توجد عملية مسجلة لهذه الدفعة.',
			'comptable.paiements.detail.encart' => 'لا يستطيع المحاسب تعديل المبلغ ولا بيانات الدفع الخاصة بالمستفيد.',
			'comptable.paiements.detail.alerteMethodeRecente' => ({required Object date}) => 'عُدّلت وسيلة الدفع في ${date}: تلزم مصادقة إضافية قبل أي دفع.',
			'comptable.paiements.detail.alerteLieeOperateur' => 'المستفيد مرتبط بالمنفِّذ: تلزم مصادقة إضافية قبل أي دفع.',
			'comptable.paiements.detail.alerteEchec' => 'فشل آخر إرسال لدى مزوّد الدفع. تحقق من وسيلة الدفع قبل محاولة جديدة.',
			'comptable.paiements.detail.alerteInfos' => 'ليست لدى المستفيد بعد وسيلة دفع مكتملة. ذكّره من ملف الدفع الخاص به.',
			'comptable.paiements.detail.alerteTitre' => 'ما يجب معرفته قبل الدفع',
			'comptable.paiements.detail.autoPaiementPhrase' => 'هذه الدفعة تخصك: سيعالجها شخص مخوَّل آخر. لا يمكن لأحد تنفيذ دفعته بنفسه.',
			'comptable.paiements.detail.introuvableTitre' => 'هذه الدفعة غير موجودة.',
			'comptable.paiements.detail.introuvablePhrase' => 'عد إلى قائمة المدفوعات للتنفيذ لاختيار دفعة أخرى.',
			'comptable.paiements.ecart.titre' => 'الإبلاغ عن فرق',
			'comptable.paiements.ecart.phrase' => 'اختر السطر وما الخطأ فيه. يتم التصحيح في المصدر، ثم يُعاد حساب المبلغ.',
			'comptable.paiements.ecart.ligne' => 'السطر المعني',
			'comptable.paiements.ecart.motif' => 'ما الخطأ',
			'comptable.paiements.ecart.motifs.montantLigne' => 'مبلغ هذا السطر غير مطابق',
			'comptable.paiements.ecart.motifs.ligneManquante' => 'سطر ناقص (حصة، استبدال، مكافأة)',
			'comptable.paiements.ecart.motifs.ligneEnTrop' => 'هذا السطر لا ينبغي أن يكون هنا',
			'comptable.paiements.ecart.motifs.sourceErronee' => 'المصدر المذكور غير صحيح',
			'comptable.paiements.ecart.envoyer' => 'إرسال البلاغ',
			'comptable.paiements.ecart.annuler' => 'إلغاء',
			'comptable.paiements.ecart.envoye' => ({required Object date}) => 'أُبلغ عن الفرق في ${date}. يبقى المبلغ كما في المصدر حتى إعادة الحساب.',
			'comptable.paiements.ecart.erreurEnvoi' => 'لم يكتمل البلاغ. أعد المحاولة: لن يُسجَّل إلا مرة واحدة.',
			'comptable.paiements.titre' => 'مدفوعات للتنفيذ',
			'comptable.paiements.sousTitre' => 'مبالغ محسوبة في المصدر: هنا نراجع وندفع، ولا نعدّل شيئًا.',
			'comptable.paiements.detailTitre' => 'تفاصيل الدفعة',
			'comptable.paiements.detailSousTitre' => 'لكل سطر مصدره. يُبلَّغ عن الفرق ولا يُصحَّح هنا.',
			'comptable.tresorerie.coffresTitre' => 'الصناديق',
			'comptable.tresorerie.coffresPhrase' => 'حيث يُخصَّص المال. المبلغ المحمي لا يُحسب أبدًا ضمن الحر.',
			'comptable.tresorerie.coffreProtege' => 'محمي',
			'comptable.tresorerie.coffreNonProtege' => 'غير محمي',
			'comptable.tresorerie.partDetenue' => ({required Object part}) => '${part} % من الخزينة المحتفَظ بها',
			'comptable.tresorerie.regleUsage' => ({required Object regle}) => 'قاعدة الاستخدام: ${regle}',
			'comptable.tresorerie.coffresVide' => 'لم يُرجَع أي صندوق بعد.',
			'comptable.tresorerie.coffresVidePhrase' => 'ستظهر الصناديق السبعة هنا بمجرد أن يُرجعها المصدر.',
			'comptable.tresorerie.descriptions.fondsClientsEngages' => 'أموال مقبوضة مرتبطة بخدمات لم تُستحق بعد.',
			'comptable.tresorerie.descriptions.paieADecaisser' => 'أجور محسوبة ومستحقة.',
			'comptable.tresorerie.descriptions.chargesEssentielles' => 'البنية التحتية والاشتراكات الضرورية والوظائف الثابتة.',
			'comptable.tresorerie.descriptions.taxesObligations' => 'مخصص للالتزامات الضريبية أو الاجتماعية أو التنظيمية.',
			'comptable.tresorerie.descriptions.reserveStrategique' => 'صندوق الاستمرارية والأمان.',
			'comptable.tresorerie.descriptions.enTransit' => 'أموال ملتزَم بها في عملية لم تُؤكَّد بعد.',
			'comptable.tresorerie.descriptions.tresorerieLibre' => 'ما يبقى متاحًا فعلًا بعد التخصيصات المحمية.',
			'comptable.tresorerie.politiqueTitre' => 'سياسة الاحتياطي الاستراتيجي',
			'comptable.tresorerie.politiquePhrase' => 'تحددها الإدارة. أنت تطبّقها ولا تعدّلها.',
			'comptable.tresorerie.alimentationAuto' => 'التغذية التلقائية',
			'comptable.tresorerie.regle.desactivee' => 'معطّلة',
			'comptable.tresorerie.regle.montantFixe' => 'مبلغ ثابت في كل موعد',
			'comptable.tresorerie.regle.pourcentage' => ({required Object pourcent}) => '${pourcent} % من كل مقبوض مُثبَّت',
			'comptable.tresorerie.regle.jusquAObjectif' => 'الإكمال حتى المبلغ المستهدف',
			'comptable.tresorerie.regle.proposee' => 'اقتراح يتطلب تأكيدك',
			'comptable.tresorerie.cadence' => 'الوتيرة',
			'comptable.tresorerie.cadences.clotureCycle' => 'عند كل إقفال دورة',
			'comptable.tresorerie.cadences.hebdomadaire' => 'كل أسبوع',
			'comptable.tresorerie.cadences.mensuelle' => 'كل شهر',
			'comptable.tresorerie.cadences.apresEncaissementConsolide' => 'بعد كل مقبوض مُثبَّت',
			'comptable.tresorerie.cadences.manuelle' => 'يدوية',
			'comptable.tresorerie.seuilAlerte' => ({required Object pourcent}) => 'تنبيه دون ${pourcent} % من المبلغ المستهدف',
			'comptable.tresorerie.retraitValidation' => 'كل سحب يتطلب مصادقة إضافية.',
			'comptable.tresorerie.retraitSansValidation' => 'لا تشترط السياسة مصادقة للسحب؛ ويبقى معامَلًا كحركة حساسة.',
			'comptable.tresorerie.version' => ({required Object version}) => 'الإصدار ${version}',
			'comptable.tresorerie.versionDepuis' => ({required Object version, required Object date}) => 'الإصدار ${version}، ساري المفعول منذ ${date}',
			'comptable.tresorerie.mouvementsTitre' => 'الحركات بين الصناديق',
			'comptable.tresorerie.mouvementsPhrase' => 'نحو الحماية: حسب تفويضك. الخروج من صندوق محمي: تلزم مصادقة إضافية.',
			'comptable.tresorerie.preparerMouvement' => 'إعداد حركة',
			'comptable.tresorerie.retirer' => 'السحب من الاحتياطي الاستراتيجي',
			'comptable.tresorerie.retraitBloque' => ({required Object raison}) => 'السحب من الاحتياطي الاستراتيجي: ${raison}.',
			'comptable.tresorerie.alimenterBloque' => ({required Object raison}) => 'تغذية الاحتياطي الاستراتيجي: ${raison}.',
			'comptable.tresorerie.aucunMouvement' => 'لا تسمح السياسة لحسابك بأي حركة بين الصناديق.',
			'comptable.tresorerie.mouvementsHorsLigne' => 'غير متصل: تُستأنف الحركات بين الصناديق مع عودة الشبكة.',
			'comptable.tresorerie.interdits' => 'أموال العملاء الملتزَم بها والضرائب والالتزامات لا تموّل أبدًا مصروفًا عاديًا؛ والتخصيص السابق لا يُعدَّل.',
			'comptable.tresorerie.previsionTitre' => 'التوقعات',
			'comptable.tresorerie.previsionPhrase' => 'الداخل والخارج المتوقع، حسب التاريخ.',
			'comptable.tresorerie.previsionVide' => 'لا يوجد داخل ولا خارج متوقع حاليًا.',
			'comptable.tresorerie.entree' => 'داخل',
			'comptable.tresorerie.sortie' => 'خارج',
			'comptable.tresorerie.historiqueTitre' => 'سجل التخصيصات',
			'comptable.tresorerie.historiquePhrase' => 'كل حركة مسجلة في السجل؛ ولا يُعدَّل فيه شيء.',
			'comptable.tresorerie.historiqueVide' => 'لا توجد حركة مسجلة بين الصناديق.',
			'comptable.tresorerie.transfert.titre' => 'حركة بين الصناديق',
			'comptable.tresorerie.transfert.choix' => 'حركة تسمح بها السياسة',
			'comptable.tresorerie.transfert.couple' => ({required Object origine, required Object destination}) => '${origine} ← ${destination}',
			'comptable.tresorerie.transfert.delegable' => 'نحو الحماية: تُنفَّذ حسب تفويضك.',
			'comptable.tresorerie.transfert.sensible' => 'تلزم مصادقة إضافية: يقرر شخص آخر، ولا يخرج شيء من الصندوق قبل ذلك.',
			'comptable.tresorerie.transfert.montant' => 'المبلغ',
			'comptable.tresorerie.transfert.montantAide' => ({required Object devise}) => 'بوحدات صحيحة، ${devise}.',
			'comptable.tresorerie.transfert.montantPropose' => 'المبلغ الذي تقترحه السياسة',
			'comptable.tresorerie.transfert.utiliserPropose' => 'استخدام المبلغ المقترح',
			'comptable.tresorerie.transfert.erreurMontant' => 'أدخل مبلغًا صحيحًا أكبر من صفر.',
			'comptable.tresorerie.transfert.verifier' => 'مراجعة الحركة',
			'comptable.tresorerie.transfert.recapPhrase' => 'راجع المبلغ الدقيق قبل الإرسال.',
			'comptable.tresorerie.transfert.de' => 'من',
			'comptable.tresorerie.transfert.vers' => 'إلى',
			'comptable.tresorerie.transfert.confirmer' => 'تأكيد الحركة',
			'comptable.tresorerie.transfert.demanderValidation' => 'طلب المصادقة',
			'comptable.tresorerie.transfert.modifier' => 'تعديل الحركة',
			'comptable.tresorerie.transfert.fermer' => 'إغلاق',
			'comptable.tresorerie.transfert.executeTitre' => 'نفّذ المصدر الحركة',
			'comptable.tresorerie.transfert.executePhrase' => 'سجّلها السجل. يُعاد قراءة الأرصدة المعروضة.',
			'comptable.tresorerie.transfert.reference' => ({required Object reference}) => 'المرجع: ${reference}',
			'comptable.tresorerie.transfert.validationTitre' => 'طُلبت المصادقة',
			'comptable.tresorerie.transfert.validationPhrase' => 'يجب أن يقرر شخص آخر. يبقى الصندوق المصدر دون تغيير حتى ذلك الحين.',
			'comptable.tresorerie.transfert.refusTitre' => 'رفض المصدر الحركة',
			'comptable.tresorerie.transfert.refusPhrase' => ({required Object raison}) => 'السبب: ${raison}. لم يُنقَل أي شيء.',
			'comptable.tresorerie.transfert.erreurEnvoiTitre' => 'لم يصل الرد',
			'comptable.tresorerie.transfert.erreurEnvoi' => 'لم يصل الرد. راجع السجل قبل إعادة المحاولة: لن تُحسب الحركة نفسها مرتين أبدًا.',
			'comptable.tresorerie.transfert.indisponible' => 'الحركات بين الصناديق غير مربوطة بالخادم بعد. لم يُنقَل أي شيء.',
			'comptable.tresorerie.transfert.aucunCouple' => 'لا تسمح السياسة بأي حركة لحسابك.',
			'comptable.tresorerie.titre' => 'الخزينة والصناديق',
			'comptable.tresorerie.sousTitre' => 'الخزينة الحرة هي الرقم الوحيد القابل للإنفاق.',
			'comptable.tresorerie.alimenter' => 'تغذية الاحتياطي الاستراتيجي',
			'comptable.encaissements.filtreTous' => 'الكل',
			'comptable.encaissements.filtreConfirmes' => 'مؤكَّدة',
			'comptable.encaissements.filtreEnAttente' => 'قيد الانتظار',
			'comptable.encaissements.filtreEchoues' => 'فاشلة',
			'comptable.encaissements.filtreRembourses' => 'مُسترَدة',
			'comptable.encaissements.filtreContestes' => 'متنازَع عليها',
			'comptable.encaissements.filtreARapprocher' => 'للمطابقة',
			'comptable.encaissements.recherche' => 'البحث عن أسرة أو مرجع',
			'comptable.encaissements.colDate' => 'التاريخ',
			'comptable.encaissements.colFamille' => 'الأسرة',
			'comptable.encaissements.colReference' => 'المرجع',
			'comptable.encaissements.colBrut' => 'الإجمالي',
			'comptable.encaissements.colFrais' => 'الرسوم',
			'comptable.encaissements.colNet' => 'الصافي',
			'comptable.encaissements.colMoyen' => 'الوسيلة',
			'comptable.encaissements.colEtat' => 'الحالة',
			'comptable.encaissements.profilsPour' => ({required Object prenoms}) => 'لـ ${prenoms}',
			'comptable.encaissements.moyenPrestataire' => ({required Object moyen, required Object prestataire}) => '${moyen} · ${prestataire}',
			'comptable.encaissements.videTitre' => 'لا توجد مقبوضات حاليًا.',
			'comptable.encaissements.videPhrase' => 'ستظهر هنا مدفوعات الأسر بمجرد أن يرسلها مزوّد الدفع.',
			'comptable.encaissements.videFiltreTitre' => 'لا يوجد مقبوض مطابق.',
			'comptable.encaissements.videFiltrePhrase' => 'اختر «الكل» أو امسح البحث لرؤية القائمة كاملة.',
			'comptable.encaissements.voirTous' => 'عرض كل المقبوضات',
			'comptable.encaissements.ouvrirDetailLecteur' => ({required Object famille}) => 'فتح تفاصيل مقبوض ${famille}',
			'comptable.encaissements.fermerDetail' => 'إغلاق التفاصيل',
			'comptable.encaissements.brut' => 'المبلغ الإجمالي',
			'comptable.encaissements.frais' => 'رسوم مزوّد الدفع',
			'comptable.encaissements.net' => 'الصافي المستلَم',
			'comptable.encaissements.fraisSource' => 'الرسوم والصرف كما أبلغ بها مزوّد الدفع، ولا يُعاد حسابها هنا أبدًا.',
			'comptable.encaissements.reference' => 'المرجع',
			'comptable.encaissements.prestataire' => 'مزوّد الدفع',
			'comptable.encaissements.moyen' => 'وسيلة الدفع',
			'comptable.encaissements.foyer' => 'الأسرة',
			'comptable.encaissements.date' => 'التاريخ',
			'comptable.encaissements.etat' => 'الحالة',
			'comptable.encaissements.devise' => 'العملة',
			'comptable.encaissements.affectation' => 'التوزيع حسب الملف',
			'comptable.encaissements.affectationAucune' => 'لم يُرجع المصدر أي توزيع لهذا المقبوض.',
			'comptable.encaissements.rapprochement' => 'المطابقة',
			'comptable.encaissements.rapprochementAucun' => 'لم تتم المطابقة بعد',
			'comptable.encaissements.ouvrirRapprochement' => 'فتح المطابقة',
			'comptable.encaissements.confirmeNote' => 'لا تظهر «مؤكَّد» إلا بعد تأكيد مزوّد الدفع.',
			'comptable.encaissements.enAttenteNote' => 'بانتظار تأكيد مزوّد الدفع: لم يُكتسب شيء بعد.',
			'comptable.encaissements.journal' => 'سجل المقبوض',
			'comptable.encaissements.journalVide' => 'لا توجد عملية مسجلة لهذا المقبوض.',
			'comptable.encaissements.rap.vueTransactions' => 'للمطابقة',
			'comptable.encaissements.rap.vueRemboursements' => 'الاستردادات',
			'comptable.encaissements.rap.natPaiementAttendu' => 'دفعة متوقعة',
			'comptable.encaissements.rap.natTransaction' => 'معاملة مزوّد الدفع',
			'comptable.encaissements.rap.natMensualite' => 'رصيد أو قسط شهري',
			'comptable.encaissements.rap.natFrais' => 'رسوم',
			'comptable.encaissements.rap.natRemboursement' => 'استرداد',
			'comptable.encaissements.rap.natPayout' => 'صرف دفعة',
			'comptable.encaissements.rap.natPreuve' => 'إثبات',
			'comptable.encaissements.rap.natureDate' => ({required Object nature, required Object date}) => '${nature} · ${date}',
			'comptable.encaissements.rap.choisirTitre' => 'اختر معاملة.',
			'comptable.encaissements.rap.choisirPhrase' => 'تُفتح هنا المطابقات المقترحة لها وحالتها وسجلها.',
			'comptable.encaissements.rap.videTitre' => 'لا شيء للمطابقة.',
			'comptable.encaissements.rap.videPhrase' => 'كل معاملة مستلَمة مرتبطة بالفعل بما كان ينتظرها.',
			'comptable.encaissements.rap.videFiltreTitre' => 'لا توجد معاملة بهذه الحالة.',
			'comptable.encaissements.rap.videFiltrePhrase' => 'اختر «الكل» لرؤية كل المعاملات.',
			'comptable.encaissements.rap.voirToutes' => 'عرض كل المعاملات',
			'comptable.encaissements.rap.ouvrirLecteur' => ({required Object libelle}) => 'فتح مطابقة ${libelle}',
			'comptable.encaissements.rap.candidats' => 'المطابقات المقترحة',
			'comptable.encaissements.rap.candidatsAucun' => 'لا يقترح المصدر أي مطابقة لهذه المعاملة.',
			'comptable.encaissements.rap.relieA' => ({required Object libelle}) => 'مرتبطة بـ: ${libelle}',
			'comptable.encaissements.rap.rapprocher' => 'مطابقة',
			'comptable.encaissements.rap.rapprocherLecteur' => ({required Object libelle}) => 'المطابقة مع ${libelle}',
			'comptable.encaissements.rap.doublonTitre' => 'تكرار محتمل',
			'comptable.encaissements.rap.doublonPhrase' => 'تشبه هذه المعاملة معاملة أخرى مستلَمة سابقًا. تحقق قبل المطابقة: لا يُقبل التكرار أبدًا بصمت.',
			'comptable.encaissements.rap.marquerDoublon' => 'وضع علامة تكرار',
			'comptable.encaissements.rap.resultat' => ({required Object etat}) => 'الحالة التي أرجعها المصدر: ${etat}',
			'comptable.encaissements.rap.erreurEnvoi' => 'لا نعلم إن كانت العملية قد سُجّلت. حدّث القائمة قبل إعادة المحاولة.',
			'comptable.encaissements.rap.actualiser' => 'تحديث',
			'comptable.encaissements.rap.journal' => 'سجل المعاملة',
			'comptable.encaissements.rap.journalVide' => 'لا توجد عملية مسجلة لهذه المعاملة.',
			'comptable.encaissements.rap.beneficiaire' => 'المستفيد',
			'comptable.encaissements.rap.motif' => 'السبب',
			'comptable.encaissements.rap.montant' => 'المبلغ',
			'comptable.encaissements.rap.source' => 'المصدر',
			'comptable.encaissements.rap.demandeLe' => ({required Object date}) => 'طُلب في ${date}',
			'comptable.encaissements.rap.approbationRequise' => 'تشترط السياسة الاعتماد',
			'comptable.encaissements.rap.approbationNon' => 'دون اعتماد حسب السياسة',
			'comptable.encaissements.rap.politiqueNote' => 'قواعد الاسترداد جزء من سياسة المالية. هنا نطبّقها ولا نعيد كتابتها.',
			'comptable.encaissements.rap.executer' => 'تنفيذ الاسترداد',
			'comptable.encaissements.rap.executerLecteur' => ({required Object beneficiaire}) => 'تنفيذ استرداد ${beneficiaire}',
			'comptable.encaissements.rap.executerTitre' => 'تنفيذ هذا الاسترداد؟',
			'comptable.encaissements.rap.executerPhrase' => 'المبلغ والشروط مصدرها سياسة المالية. سيؤكد مزوّد الدفع التنفيذ.',
			'comptable.encaissements.rap.remboursementsVideTitre' => 'لا يوجد استرداد ولا رصيد دائن جارٍ.',
			'comptable.encaissements.rap.journalRemboursement' => 'سجل الاسترداد',
			'comptable.encaissements.rap.journalRemboursementVide' => 'لا توجد عملية مسجلة لهذا الاسترداد.',
			'comptable.encaissements.rap.erreurEnvoiTitre' => 'عملية غير مؤكدة',
			'comptable.encaissements.rap.remboursementsVidePhrase' => 'ستظهر هنا طلبات الاسترداد مع سببها وحالتها.',
			'comptable.encaissements.titre' => 'المقبوضات',
			'comptable.encaissements.sousTitre' => 'لا تُؤكَّد الدفعة إلا بعد مزوّد الدفع.',
			'comptable.encaissements.detailTitre' => 'تفاصيل المقبوض',
			'comptable.encaissements.rapprochementTitre' => 'المطابقة',
			'comptable.encaissements.rapprochementSousTitre' => 'ربط كل معاملة بما كان ينتظرها.',
			'comptable.beneficiaires.intro' => 'ملف الدفع لكل معلم ولكل متعاقد. المستفيد وحده يُدخل بياناته أو يعدّلها: يمكنك تذكيره، أو طلب تحديث منه، أو إيقاف مدفوعاته.',
			'comptable.beneficiaires.filtreTous' => 'الكل',
			'comptable.beneficiaires.filtreInfos' => 'معلومات ناقصة',
			'comptable.beneficiaires.filtreVerification' => 'قيد التحقق',
			'comptable.beneficiaires.filtreSuspendus' => 'موقوفة',
			'comptable.beneficiaires.filtreInvitations' => 'دعوات مُرسَلة',
			'comptable.beneficiaires.colonneBeneficiaire' => 'المستفيد',
			'comptable.beneficiaires.colonneType' => 'النوع',
			'comptable.beneficiaires.colonneDestination' => 'الوجهة',
			'comptable.beneficiaires.colonneEtat' => 'حالة الملف',
			'comptable.beneficiaires.colonneEnAttente' => 'مدفوعات قيد الانتظار',
			'comptable.beneficiaires.typeEnseignant' => 'معلم',
			'comptable.beneficiaires.typeContractuel' => 'متعاقد',
			'comptable.beneficiaires.enAttente' => ({required Object n}) => '${n} قيد الانتظار',
			'comptable.beneficiaires.aucunEnAttente' => 'لا شيء',
			'comptable.beneficiaires.vide' => 'لا يوجد مستفيد حاليًا.',
			'comptable.beneficiaires.videDetail' => 'يظهر المعلمون والمتعاقدون هنا بمجرد وجود دفعة تخصهم.',
			'comptable.beneficiaires.videFiltre' => 'لا يوجد مستفيد بعامل التصفية هذا.',
			'comptable.beneficiaires.videFiltreDetail' => 'اختر «الكل» لرؤية القائمة كاملة.',
			'comptable.beneficiaires.profil.carteTitre' => ({required Object nom}) => 'ملف الدفع الخاص بـ ${nom}',
			'comptable.beneficiaires.profil.etat' => 'حالة الملف',
			'comptable.beneficiaires.profil.derniereModification' => 'آخر تعديل',
			'comptable.beneficiaires.profil.capacite' => 'قدرة الدفع في هذا المسار',
			'comptable.beneficiaires.profil.capaciteNonEvaluee' => 'لم تُقيَّم بعد',
			'comptable.beneficiaires.profil.enAttente' => 'مدفوعات تنتظر هذا الملف',
			'comptable.beneficiaires.profil.proprietaire' => ({required Object nom}) => 'وحده ${nom} يمكنه إدخال بيانات الدفع الخاصة به أو تعديلها. أنت ترى نسخة مخفية منها.',
			'comptable.beneficiaires.profil.historiqueTitre' => 'سجل المدفوعات',
			'comptable.beneficiaires.profil.historiqueVide' => 'لم تُصرف أي دفعة لهذا المستفيد حتى الآن.',
			'comptable.beneficiaires.profil.journalTitre' => 'سجل الملف',
			'comptable.beneficiaires.profil.journalVide' => 'لا يوجد أي تعديل مسجل على هذا الملف حتى الآن.',
			'comptable.beneficiaires.profil.actionsTitre' => 'ما العمل لهذا الملف',
			'comptable.beneficiaires.profil.relancer' => ({required Object nom}) => 'تذكير ${nom}',
			'comptable.beneficiaires.profil.relancerDetail' => 'يفتح محادثة «ملف الدفع» برسالة معدّة مسبقًا، في رسائل العمل.',
			'comptable.beneficiaires.profil.demanderMiseAJour' => ({required Object nom}) => 'طلب تحديث من ${nom}',
			'comptable.beneficiaires.profil.suspendre' => ({required Object nom}) => 'إيقاف مدفوعات ${nom}',
			'comptable.beneficiaires.profil.reprendre' => ({required Object nom}) => 'استئناف مدفوعات ${nom}',
			'comptable.beneficiaires.profil.externe' => ({required Object nom}) => 'ليس لدى ${nom} حساب Rewayah: تتيح له دعوة آمنة إدخال وسيلته بنفسه. أعد إرسالها من التزامه، في المتعاقدين.',
			'comptable.beneficiaires.profil.voirContractuels' => 'عرض التزامات المتعاقدين',
			'comptable.beneficiaires.profil.aucuneAction' => 'لا يوجد أي إجراء مفتوح على هذا الملف: إنه محدَّث.',
			'comptable.beneficiaires.profil.filTitre' => 'محادثة «ملف الدفع»',
			'comptable.beneficiaires.profil.relanceRefusee' => ({required Object nom}) => 'لا يمكن فتح محادثة «ملف الدفع» مع ${nom}: لا تسمح Rewayah بذلك لهذا المستفيد. اطلب تحديثًا بدلًا من ذلك، أو أبلغ الإدارة.',
			'comptable.beneficiaires.profil.messageModele' => 'يجب إكمال معلومات الدفع الخاصة بك قبل دفعتك القادمة. يمكنك إضافتها من مساحتك الشخصية.',
			'comptable.beneficiaires.profil.miseAJourDemandee' => ({required Object nom}) => 'سُجّل طلب التحديث لـ ${nom}.',
			'comptable.beneficiaires.profil.suspendus' => ({required Object nom}) => 'أُوقفت مدفوعات ${nom}: لن تُصرف أي دفعة ما لم تُستأنف.',
			'comptable.beneficiaires.profil.repris' => ({required Object nom}) => 'استُؤنفت مدفوعات ${nom}.',
			'comptable.beneficiaires.profil.erreurAction' => 'لم يكتمل الإجراء. تحقق من اتصالك، ثم أعد المحاولة.',
			'comptable.beneficiaires.profil.erreurIndisponible' => 'هذا الإجراء غير مربوط بعد بالخدمة التي تعالجه. أعد المحاولة لاحقًا.',
			'comptable.beneficiaires.profil.suspensionTitre' => ({required Object nom}) => 'إيقاف مدفوعات ${nom}؟',
			'comptable.beneficiaires.profil.suspensionContexte' => 'لن تُصرف أي دفعة لهذا المستفيد ما لم تستأنفها. لن تتغير بياناته. اختر السبب: سيُدوَّن في سجل الملف.',
			'comptable.beneficiaires.profil.motifVerifier' => 'بيانات تحتاج إلى تحقق',
			'comptable.beneficiaires.profil.motifVerifierDetail' => 'تبدو الوسيلة غير صحيحة أو تعذّر تأكيدها.',
			'comptable.beneficiaires.profil.motifAnomalie' => 'خلل مُبلَّغ عنه',
			'comptable.beneficiaires.profil.motifAnomalieDetail' => 'فشلت دفعة حديثة أو أُبلغ عن فرق.',
			'comptable.beneficiaires.profil.motifDemande' => 'طلب من المستفيد',
			'comptable.beneficiaires.profil.motifDemandeDetail' => 'طلب المستفيد عدم استلام أي دفعة حاليًا.',
			'comptable.beneficiaires.profil.motifRequis' => 'اختر سببًا للمتابعة.',
			'comptable.beneficiaires.titre' => 'المستفيدون',
			'comptable.beneficiaires.sousTitre' => 'البيانات مخفية: المستفيد وحده يعدّل بياناته.',
			'comptable.beneficiaires.profilTitre' => 'ملف الدفع',
			'comptable.beneficiaires.recevoir.rubrique' => 'المدفوعات',
			'comptable.beneficiaires.recevoir.ligneDetail' => 'وسائل الدفع الخاصة بك، تديرها أنت وحدك.',
			'comptable.beneficiaires.recevoir.noticeDetail' => 'أضف وسيلة دفع لتتمكن الأكاديمية من صرف دفعتك القادمة.',
			'comptable.beneficiaires.recevoir.phraseAucunMoyen' => 'ليست لديك أي وسيلة دفع بعد. أضف واحدة لاستلام دفعاتك.',
			'comptable.beneficiaires.recevoir.phraseIncomplet' => 'وسيلة الدفع الخاصة بك غير مكتملة. أكملها لاستلام دفعتك القادمة.',
			'comptable.beneficiaires.recevoir.phraseEnVerification' => 'وسيلتك الجديدة قيد التحقق. تُحدَّث حالتها هنا.',
			'comptable.beneficiaires.recevoir.phraseVerifie' => 'تم التحقق من وسيلة الدفع الخاصة بك. ستُرسَل إليها دفعاتك القادمة.',
			'comptable.beneficiaires.recevoir.phraseSuspendu' => 'دفعاتك موقوفة. تواصل مع الأكاديمية لمعرفة السبب.',
			'comptable.beneficiaires.recevoir.phraseActionRequise' => 'مطلوب تحديث وسيلة الدفع الخاصة بك. استبدلها لاستلام دفعتك القادمة.',
			'comptable.beneficiaires.recevoir.phraseInvitationEnvoyee' => 'أُرسلت إليك دعوة آمنة. أضف وسيلة الدفع الخاصة بك لإكمالها.',
			'comptable.beneficiaires.recevoir.suspenduTemporairement' => 'دفعاتك موقوفة ريثما يتم التحقق من وسيلتك الجديدة: هذه حماية من الاحتيال.',
			'comptable.beneficiaires.recevoir.mesMethodes' => 'وسائل الدفع الخاصة بي',
			'comptable.beneficiaires.recevoir.preferee' => 'الوسيلة المفضلة',
			'comptable.beneficiaires.recevoir.inactive' => 'وسيلة سابقة، محفوظة غير مفعّلة',
			'comptable.beneficiaires.recevoir.choisirPreferee' => ({required Object methode}) => 'جعل ${methode} وسيلتي المفضلة',
			'comptable.beneficiaires.recevoir.remplacer' => ({required Object methode}) => 'استبدال ${methode}',
			'comptable.beneficiaires.recevoir.supprimer' => ({required Object methode}) => 'حذف ${methode}',
			'comptable.beneficiaires.recevoir.supprimerQuestion' => ({required Object methode}) => 'حذف ${methode}؟',
			'comptable.beneficiaires.recevoir.supprimerConsequence' => 'لن تستلم بعد الآن أي دفعة على هذه الوسيلة. إن كانت الوحيدة، فستنتظر دفعتك القادمة وسيلة جديدة.',
			'comptable.beneficiaires.recevoir.ajouter' => 'إضافة وسيلة دفع',
			'comptable.beneficiaires.recevoir.ajoutTitre' => 'إضافة وسيلة دفع',
			'comptable.beneficiaires.recevoir.remplacementTitre' => ({required Object methode}) => 'استبدال ${methode}',
			'comptable.beneficiaires.recevoir.ajoutContexte' => 'اختر نوع الوسيلة. ستُدخل بعد ذلك بياناتك في مساحة آمنة: التطبيق لا يراها ولا يحتفظ بها.',
			'comptable.beneficiaires.recevoir.continuerSaisie' => 'المتابعة إلى الإدخال الآمن',
			'comptable.beneficiaires.recevoir.typeRequis' => 'اختر نوع وسيلة للمتابعة.',
			'comptable.beneficiaires.recevoir.aucunType' => 'لا يُقترح أي نوع وسيلة حاليًا. تواصل مع الأكاديمية لفتح نوع.',
			'comptable.beneficiaires.recevoir.verificationAnnoncee' => 'يُتحقَّق من كل تغيير قبل الدفعة القادمة.',
			'comptable.beneficiaires.recevoir.ajoutee' => 'أُضيفت الوسيلة: إنها قيد التحقق.',
			'comptable.beneficiaires.recevoir.remplacee' => 'سُجّلت الوسيلة الجديدة: إنها قيد التحقق.',
			'comptable.beneficiaires.recevoir.supprimee' => 'حُذفت الوسيلة.',
			'comptable.beneficiaires.recevoir.prefereeChoisie' => 'حُدّثت الوسيلة المفضلة.',
			'comptable.beneficiaires.recevoir.erreurAction' => 'لم يكتمل التغيير. تحقق من اتصالك، ثم أعد المحاولة.',
			'comptable.beneficiaires.recevoir.erreurIndisponible' => 'هذا التغيير غير مربوط بعد بخدمة الدفع. أعد المحاولة لاحقًا.',
			'comptable.beneficiaires.recevoir.journalTitre' => 'سجل تغييراتي',
			'comptable.beneficiaires.recevoir.journalVide' => 'لا يوجد أي تغيير مسجل حتى الآن.',
			'comptable.beneficiaires.recevoir.seulVous' => 'أنت وحدك يمكنك تعديل هذه المعلومات: لا المحاسبة ولا الإدارة تستطيع ذلك نيابة عنك.',
			'comptable.beneficiaires.recevoir.titre' => 'استلام مدفوعاتي',
			'comptable.beneficiaires.recevoir.sousTitre' => 'بيانات الدفع الخاصة بك، لا يعدّلها أحد سواك.',
			'comptable.beneficiaires.recevoir.notice' => 'معلومات دفع يجب إكمالها',
			'comptable.beneficiaires.recevoir.configurer' => 'إعداد مدفوعاتي',
			'comptable.contractuels.ongletObligations' => 'الالتزامات',
			'comptable.contractuels.ongletAApprouver' => 'للاعتماد',
			'comptable.contractuels.ongletAPayer' => 'للدفع',
			'comptable.contractuels.ongletHistorique' => 'السجل',
			'comptable.contractuels.ongletsLecteur' => 'عرض الالتزامات',
			'comptable.contractuels.colonneBeneficiaire' => 'المستفيد',
			'comptable.contractuels.colonneObjet' => 'الموضوع',
			'comptable.contractuels.colonneMontant' => 'المبلغ',
			'comptable.contractuels.colonneEcheance' => 'الاستحقاق',
			'comptable.contractuels.colonneStatut' => 'الحالة',
			'comptable.contractuels.typeRecurrente' => 'متكرر',
			'comptable.contractuels.typePonctuelle' => 'لمرة واحدة',
			'comptable.contractuels.echeanceLe' => ({required Object date}) => 'الاستحقاق: ${date}',
			'comptable.contractuels.payer' => 'دفع',
			'comptable.contractuels.payerLecteur' => ({required Object objet}) => 'دفع الالتزام ${objet}',
			'comptable.contractuels.approuver' => 'اعتماد',
			'comptable.contractuels.ouvrirLecteur' => ({required Object objet}) => 'فتح الالتزام ${objet}',
			'comptable.contractuels.creationBloquee' => ({required Object raison}) => 'الالتزام الجديد غير متاح: ${raison}.',
			'comptable.contractuels.videObligations' => 'لا يوجد التزام جارٍ',
			'comptable.contractuels.videObligationsDetail' => 'تظهر هنا الالتزامات المنشأة، مع استحقاقها وحالتها.',
			'comptable.contractuels.videAApprouver' => 'لا شيء للاعتماد',
			'comptable.contractuels.videAApprouverDetail' => 'تظهر هنا الالتزامات التي تنتظر الاعتماد.',
			'comptable.contractuels.videAPayer' => 'لا شيء للدفع',
			'comptable.contractuels.videAPayerDetail' => 'يظهر هنا الالتزام المعتمَد، جاهزًا للدفع.',
			'comptable.contractuels.videHistorique' => 'لا يوجد التزام منتهٍ',
			'comptable.contractuels.videHistoriqueDetail' => 'تظهر هنا الالتزامات المدفوعة أو المرفوضة أو الملغاة.',
			'comptable.contractuels.montantDefini' => 'مبلغ يُحدَّد عند الإنشاء، ويُثبَّت بعد الاعتماد.',
			'comptable.contractuels.montantFige' => 'مبلغ ثُبّت عند الاعتماد: لم يعد يُعدَّل.',
			'comptable.contractuels.montantTitre' => 'المبلغ',
			'comptable.contractuels.sectionLignes' => 'تفاصيل المبلغ',
			'comptable.contractuels.sectionInfos' => 'المعلومات',
			'comptable.contractuels.sectionHistorique' => 'سجل الالتزام',
			'comptable.contractuels.historiqueVide' => 'لا توجد عملية مسجلة لهذا الالتزام.',
			'comptable.contractuels.champBeneficiaire' => 'المستفيد',
			'comptable.contractuels.champType' => 'النوع',
			'comptable.contractuels.champEcheance' => 'الاستحقاق',
			'comptable.contractuels.champJustificatif' => 'المستند المؤيِّد',
			'comptable.contractuels.champCentreCout' => 'مركز التكلفة',
			'comptable.contractuels.champAuteur' => 'المُنشئ',
			'comptable.contractuels.champApprobateur' => 'المعتمِد',
			'comptable.contractuels.champProfilPaiement' => 'دفع المستفيد',
			'comptable.contractuels.champMotifRefus' => 'سبب الرفض',
			'comptable.contractuels.aucunJustificatif' => 'لا يوجد مستند مؤيِّد مرفق',
			'comptable.contractuels.nonRenseigne' => 'غير محدد',
			'comptable.contractuels.ligneSource' => ({required Object source}) => 'المصدر: ${source}',
			'comptable.contractuels.ligneAuteur' => ({required Object auteur}) => 'أضافه ${auteur}',
			'comptable.contractuels.ligneValidation' => ({required Object validation}) => 'المصادقة: ${validation}',
			'comptable.contractuels.payerAide' => 'يُفتح الدفع في تفاصيل الدفعة، بالمبلغ الدقيق.',
			'comptable.contractuels.approuverAide' => 'بعد الاعتماد، يُثبَّت المبلغ ويصبح الالتزام قابلًا للدفع.',
			'comptable.contractuels.renvoyerInvitation' => 'إعادة إرسال الدعوة',
			'comptable.contractuels.invitationAide' => 'هذا المستفيد الخارجي يُدخل وسيلة الدفع بنفسه، من دعوته الآمنة.',
			'comptable.contractuels.invitationRenvoyee' => 'أُعيد إرسال الدعوة',
			'comptable.contractuels.erreurApprobation' => 'لا نعلم إن كان الاعتماد قد سُجّل. حدّث الالتزام قبل إعادة المحاولة.',
			'comptable.contractuels.erreurInvitation' => 'لا نعلم إن كانت الدعوة قد أُعيد إرسالها. حدّث الالتزام قبل إعادة المحاولة.',
			'comptable.contractuels.formIntro' => 'المستفيد والاستحقاق ومركز التكلفة مقترحة: غيّرها عند الحاجة، ثم أدخل الموضوع والمبلغ.',
			'comptable.contractuels.beneficiaireExterne' => 'مستفيد خارجي جديد',
			'comptable.contractuels.beneficiaireExterneAide' => 'يتلقى دعوة آمنة ليُدخل وسيلة الدفع بنفسه.',
			'comptable.contractuels.champNomExterne' => 'اسم المستفيد الخارجي',
			'comptable.contractuels.changerEcheance' => 'تغيير الاستحقاق',
			'comptable.contractuels.deviseDe' => ({required Object devise}) => 'العملة: ${devise}',
			'comptable.contractuels.champObjet' => 'موضوع الالتزام',
			'comptable.contractuels.aideObjet' => 'مثلًا: الفاتورة رقم 024',
			'comptable.contractuels.champRefJustificatif' => 'مرجع المستند المؤيِّد (اختياري)',
			'comptable.contractuels.champMontantSaisi' => 'المبلغ',
			'comptable.contractuels.aideMontant' => 'يُدخل مرة واحدة: لا يُعدَّل بعد الاعتماد.',
			'comptable.contractuels.creer' => 'إنشاء الالتزام',
			'comptable.contractuels.horsLigneCreation' => 'أنت غير متصل. أعد الاتصال لإنشاء الالتزام.',
			'comptable.contractuels.erreurObjet' => 'أدخل موضوع الالتزام.',
			_ => null,
		} ?? switch (path) {
			'comptable.contractuels.erreurMontant' => 'أدخل مبلغًا أكبر من صفر، مثلًا 350 أو 350,50.',
			'comptable.contractuels.erreurNomExterne' => 'أدخل اسم المستفيد الخارجي.',
			'comptable.contractuels.erreurCreation' => 'لا نعلم إن كان الالتزام قد أُنشئ. حدّث القائمة قبل إعادة المحاولة.',
			'comptable.contractuels.creationIndisponible' => 'لا يستطيع حسابك إنشاء التزام.',
			'comptable.contractuels.retourListe' => 'العودة إلى المتعاقدين',
			'comptable.contractuels.titre' => 'المتعاقدون والالتزامات',
			'comptable.contractuels.sousTitre' => 'تُحدَّد المبالغ عند إنشاء الالتزام، وتُثبَّت بعد الاعتماد.',
			'comptable.contractuels.nouvelle' => 'التزام جديد',
			'comptable.contractuels.detailTitre' => 'الالتزام',
			'comptable.validation.sousTitre' => 'طلبات المحاسب التي تنتظر قرار شخص مخوَّل آخر. صاحب الطلب لا يصادق أبدًا على طلبه.',
			'comptable.validation.aDecider' => 'للبتّ',
			'comptable.validation.decidees' => 'بُتّ فيها مؤخرًا',
			'comptable.validation.videTitre' => 'لا شيء للمصادقة',
			'comptable.validation.videPhrase' => 'ستظهر هنا طلبات المحاسب القادمة.',
			'comptable.validation.natures.payoutSensible' => 'دفعة حساسة',
			'comptable.validation.natures.retraitReserve' => 'السحب من الاحتياطي الاستراتيجي',
			'comptable.validation.natures.obligationAApprouver' => 'التزام لمرة واحدة',
			'comptable.validation.natures.payoutDuComptable' => 'أجر المحاسب',
			'comptable.validation.natures.sortieCoffreProtege' => 'الخروج من صندوق محمي',
			'comptable.validation.demandePar' => ({required Object demandeur, required Object date}) => 'طلبه ${demandeur} في ${date}',
			'comptable.validation.valideePar' => ({required Object decideur, required Object date}) => 'صادق عليه ${decideur} في ${date}',
			'comptable.validation.refuseePar' => ({required Object decideur, required Object date}) => 'رفضه ${decideur} في ${date}',
			'comptable.validation.motif' => ({required Object motif}) => 'السبب: ${motif}',
			'comptable.validation.ouvrir' => ({required Object objet}) => 'عرض الطلب: ${objet}',
			'comptable.validation.votreDemandeTitre' => 'طلبك أنت',
			'comptable.validation.votreDemandePhrase' => 'سيبتّ فيه شخص مخوَّل آخر: لا تصادق أبدًا على طلب قدّمته.',
			'comptable.validation.detail.titre' => 'طلب مصادقة',
			'comptable.validation.detail.nature' => 'النوع',
			'comptable.validation.detail.objet' => 'الموضوع',
			'comptable.validation.detail.demandeur' => 'طلبه',
			'comptable.validation.detail.date' => 'تاريخ الطلب',
			'comptable.validation.detail.raison' => 'السبب',
			'comptable.validation.detail.montant' => 'المبلغ الدقيق',
			'comptable.validation.detail.etat' => 'الحالة',
			'comptable.validation.detail.historique' => 'السجل',
			'comptable.validation.detail.historiqueVide' => 'لا يوجد أي إدخال حتى الآن.',
			'comptable.validation.valider' => 'مصادقة',
			'comptable.validation.refuser' => 'رفض',
			'comptable.validation.annuler' => 'إلغاء',
			'comptable.validation.fermer' => 'إغلاق',
			'comptable.validation.confirmerRefus' => 'تأكيد الرفض',
			'comptable.validation.motifTitre' => 'سبب الرفض',
			'comptable.validation.motifPhrase' => 'سيقرأ المحاسب هذا السبب مع القرار. اختر واحدًا، أو حدّد سببك.',
			'comptable.validation.motifs.coordonnees' => 'بيانات المستفيد تحتاج إلى تحقق',
			'comptable.validation.motifs.montant' => 'المبلغ يحتاج إلى تحقق في المصدر',
			'comptable.validation.motifs.justificatif' => 'المستند المؤيِّد ناقص أو غير مقروء',
			'comptable.validation.motifs.reserve' => 'خارج سياسة الاحتياطي',
			'comptable.validation.motifs.reporter' => 'يؤجَّل إلى الدورة القادمة',
			'comptable.validation.motifs.autre' => 'آخر',
			'comptable.validation.motifAutreChamp' => 'حدّد السبب',
			'comptable.validation.erreurMotif' => 'اختر سببًا للرفض.',
			'comptable.validation.erreurMotifAutre' => 'حدّد السبب للرفض.',
			'comptable.validation.decisionValidee' => 'سُجّل قرارك: تمت المصادقة على الطلب.',
			'comptable.validation.decisionRefusee' => 'سُجّل قرارك: رُفض الطلب، مع سببه.',
			'comptable.validation.refusTitre' => 'لم يُسجَّل القرار',
			'comptable.validation.refusDemandeur' => 'أنت من قدّم هذا الطلب: يجب أن يبتّ فيه شخص مخوَّل آخر. لم يتغير شيء.',
			'comptable.validation.refusMotif' => 'الرفض يتطلب سببًا. اختر واحدًا، ثم أكّد.',
			'comptable.validation.refusDejaDecidee' => 'سبق البتّ في هذا الطلب. أعد قراءة القائمة.',
			'comptable.validation.inconnuTitre' => 'القرار غير مؤكد',
			'comptable.validation.inconnuPhrase' => 'لا نعلم إن كان قرارك قد سُجّل. أعد قراءة القائمة قبل أن تقرر من جديد.',
			'comptable.validation.relireListe' => 'إعادة قراءة القائمة',
			'comptable.validation.horsLigne' => 'غير متصل: أعد الاتصال لتقرر.',
			'comptable.validation.suiviEnAttente' => ({required Object date}) => 'طُلب في ${date}. سيقرر شخص مخوَّل آخر؛ لا يُرسَل شيء قبل قراره.',
			'comptable.validation.suiviValidee' => ({required Object decideur, required Object date}) => 'صادق عليه ${decideur} في ${date}.',
			'comptable.validation.suiviRefusee' => ({required Object decideur, required Object date, required Object motif}) => 'رفضه ${decideur} في ${date}. السبب: ${motif}',
			'comptable.validation.erreurSuivi' => 'تعذرت قراءة حالة طلب المصادقة. أعد المحاولة بعد قليل.',
			'comptable.validation.reessayer' => 'إعادة المحاولة',
			'comptable.direction.versionDepuis' => ({required Object version, required Object date}) => 'الإصدار ${version}، ساري المفعول منذ ${date}',
			'comptable.direction.versionSansDate' => ({required Object version}) => 'الإصدار ${version}',
			'comptable.direction.auteur' => ({required Object auteur}) => 'سجّله ${auteur}',
			'comptable.direction.enregistrer' => 'تسجيل إصدار جديد',
			'comptable.direction.aucuneModification' => 'لا يوجد تعديل للتسجيل.',
			'comptable.direction.corrigezChamps' => 'صحّح الحقول المشار إليها للتسجيل.',
			'comptable.direction.enregistree' => 'سُجّل الإصدار الجديد.',
			'comptable.direction.erreurEnregistrement' => 'لا نعلم إن كان هذا الإصدار قد سُجّل. أعد قراءة الإصدار الساري، ثم أعد المحاولة.',
			'comptable.direction.enregistrementIndisponible' => 'التسجيل غير متاح بعد. أعد المحاولة لاحقًا.',
			'comptable.direction.historique' => 'سجل الإصدارات',
			'comptable.direction.historiqueVide' => 'لا يوجد إصدار قبل هذا.',
			'comptable.direction.etatActuel' => 'الحالة الحالية للاحتياطي',
			'comptable.direction.suffixeMois' => 'أشهر',
			'comptable.direction.suffixeJours' => 'أيام',
			'comptable.direction.suffixePourcent' => '%',
			'comptable.direction.erreurNombre' => 'أدخل عددًا صحيحًا أكبر من صفر.',
			'comptable.direction.erreurPourcentage' => 'أدخل نسبة أكبر من صفر ولا تتجاوز 100، بمنزلة عشرية واحدة على الأكثر.',
			'comptable.direction.erreurMontant' => 'أدخل مبلغًا أكبر من صفر.',
			'comptable.direction.reservePanneau.intro' => 'أنت تحدد السياسة؛ والمحاسب يقرؤها وينفّذها. كل تسجيل يُنشئ إصدارًا جديدًا يُحفظ في السجل.',
			'comptable.direction.reservePanneau.objectifTitre' => 'هدف الاحتياطي',
			'comptable.direction.reservePanneau.objectifDetail' => 'ما يجب أن يبلغه الاحتياطي الاستراتيجي.',
			'comptable.direction.reservePanneau.modeFixe' => 'مبلغ ثابت',
			'comptable.direction.reservePanneau.modeFixeDetail' => 'مبلغ محدد تختاره أنت.',
			'comptable.direction.reservePanneau.modeMois' => 'تغطية بالأشهر',
			'comptable.direction.reservePanneau.modeMoisDetail' => 'عدد من أشهر المصاريف الأساسية.',
			'comptable.direction.reservePanneau.montantCible' => 'المبلغ المستهدف',
			'comptable.direction.reservePanneau.montantCibleDetail' => 'المبلغ الذي يجب أن يبلغه الاحتياطي الاستراتيجي.',
			'comptable.direction.reservePanneau.nombreMois' => 'عدد أشهر التغطية',
			'comptable.direction.reservePanneau.nombreMoisDetail' => 'كم شهرًا من المصاريف الأساسية يجب أن يغطي الاحتياطي.',
			'comptable.direction.reservePanneau.alimentationTitre' => 'التغذية التلقائية',
			'comptable.direction.reservePanneau.alimentationDetail' => 'كيف يمتلئ الاحتياطي دون تدخل من المحاسب.',
			'comptable.direction.reservePanneau.regle.desactivee' => 'معطّلة',
			'comptable.direction.reservePanneau.regle.desactiveeDetail' => 'لا توجد تغذية تلقائية.',
			'comptable.direction.reservePanneau.regle.montantFixe' => 'مبلغ ثابت',
			'comptable.direction.reservePanneau.regle.montantFixeDetail' => 'المبلغ نفسه في كل موعد.',
			'comptable.direction.reservePanneau.regle.pourcentage' => 'نسبة مئوية',
			'comptable.direction.reservePanneau.regle.pourcentageDetail' => 'حصة من المقبوض المُثبَّت.',
			'comptable.direction.reservePanneau.regle.jusquAObjectif' => 'حتى بلوغ الهدف',
			'comptable.direction.reservePanneau.regle.jusquAObjectifDetail' => 'إكمال ما ينقص لبلوغ الهدف.',
			'comptable.direction.reservePanneau.regle.proposee' => 'مقترحة',
			'comptable.direction.reservePanneau.regle.proposeeDetail' => 'اقتراح يؤكده المحاسب.',
			'comptable.direction.reservePanneau.montantAuto' => 'المبلغ المخصَّص',
			'comptable.direction.reservePanneau.montantAutoDetail' => 'المبلغ المخصَّص للاحتياطي في كل موعد.',
			'comptable.direction.reservePanneau.pourcentageAuto' => 'حصة المقبوض المُثبَّت',
			'comptable.direction.reservePanneau.pourcentageAutoDetail' => 'الحصة المخصَّصة للاحتياطي في كل موعد.',
			'comptable.direction.reservePanneau.cadenceTitre' => 'الوتيرة',
			'comptable.direction.reservePanneau.cadenceDetail' => 'متى تتم التغذية.',
			'comptable.direction.reservePanneau.cadence.clotureCycle' => 'عند كل إقفال دورة',
			'comptable.direction.reservePanneau.cadence.hebdomadaire' => 'كل أسبوع',
			'comptable.direction.reservePanneau.cadence.mensuelle' => 'كل شهر',
			'comptable.direction.reservePanneau.cadence.apresEncaissementConsolide' => 'بعد كل مقبوض مُثبَّت',
			'comptable.direction.reservePanneau.cadence.manuelle' => 'يدوية',
			'comptable.direction.reservePanneau.seuilTitre' => 'التنبيه',
			'comptable.direction.reservePanneau.seuil' => 'حد التنبيه',
			'comptable.direction.reservePanneau.seuilDetail' => 'دون هذه الحصة من الهدف، يُشار إلى الاحتياطي بأنه «دون الهدف». اتركه فارغًا لعدم تحديد أي حد.',
			'comptable.direction.reservePanneau.seuilIndice' => 'بلا حد',
			'comptable.direction.reservePanneau.retraitTitre' => 'السحب',
			'comptable.direction.reservePanneau.retraitSwitch' => 'السحب يتطلب مصادقة إضافية',
			'comptable.direction.reservePanneau.retraitSwitchDetail' => 'إخراج المال من الاحتياطي عملية حساسة: يصادق عليها شخص غير صاحب الطلب.',
			'comptable.direction.delegationPanneau.intro' => 'تحدد مرة واحدة ما يستطيع المحاسب تنفيذه وحده. وكل ما عدا ذلك يعود إليك.',
			'comptable.direction.delegationPanneau.pouvoirsTitre' => 'ما يستطيع المحاسب فعله وحده',
			'comptable.direction.delegationPanneau.paiementsStandards' => 'دفع المدفوعات العادية',
			'comptable.direction.delegationPanneau.paiementsStandardsDetail' => 'الدفعة بالمبلغ المحسوب، نحو وسيلة متحقَّق منها، تُرسَل دون مصادقة يومية.',
			'comptable.direction.delegationPanneau.remboursement' => 'تنفيذ استرداد عادي',
			'comptable.direction.delegationPanneau.remboursementDetail' => 'الاسترداد المطابق للقاعدة يُنفَّذ دون مصادقة.',
			'comptable.direction.delegationPanneau.alimentationReserve' => 'تغذية الاحتياطي الاستراتيجي',
			'comptable.direction.delegationPanneau.alimentationReserveDetail' => 'حركة نحو الاحتياطي، مطابقة لسياسته.',
			'comptable.direction.delegationPanneau.plafondsTitre' => 'الحدود القصوى',
			'comptable.direction.delegationPanneau.plafondsDetail' => 'بعد تجاوز الحد الأقصى، تتطلب الدفعة مصادقتك. اتركه فارغًا لعدم تحديد أي حد.',
			'comptable.direction.delegationPanneau.plafondTransaction' => 'الحد الأقصى لكل معاملة',
			'comptable.direction.delegationPanneau.plafondTransactionDetail' => 'أقصى مبلغ لدفعة واحدة.',
			'comptable.direction.delegationPanneau.plafondLot' => 'الحد الأقصى لكل دفعة مجمّعة',
			'comptable.direction.delegationPanneau.plafondLotDetail' => 'أقصى مبلغ لمجموعة مدفوعات.',
			'comptable.direction.delegationPanneau.plafondPeriode' => 'الحد الأقصى التراكمي لكل فترة',
			'comptable.direction.delegationPanneau.plafondPeriodeDetail' => 'أقصى إجمالي خلال الفترة؛ يمنع الالتفاف على الحد بالتجزئة.',
			'comptable.direction.delegationPanneau.plafondIndice' => 'بلا حد',
			'comptable.direction.delegationPanneau.validationsTitre' => 'متى تُشترط مصادقة ثانية',
			'comptable.direction.delegationPanneau.retraitReserve' => 'السحب من الاحتياطي الاستراتيجي',
			'comptable.direction.delegationPanneau.retraitReserveDetail' => 'ممنوع على المحاسب دون مصادقة.',
			'comptable.direction.delegationPanneau.premierPaiement' => 'أول دفعة لمستفيد',
			'comptable.direction.delegationPanneau.premierPaiementDetail' => 'أول دفعة لمستفيد تتطلب مصادقة ثانية.',
			'comptable.direction.delegationPanneau.coordonnees' => 'بيانات عُدّلت مؤخرًا',
			'comptable.direction.delegationPanneau.coordonneesDetail' => 'الدفعة نحو بيانات عُدّلت مؤخرًا تتطلب مصادقة ثانية.',
			'comptable.direction.delegationPanneau.joursRecents' => 'مدة التعديل الحديث',
			'comptable.direction.delegationPanneau.joursRecentsDetail' => 'خلال هذا العدد من الأيام بعد التعديل، تُعدّ البيانات حديثة.',
			'comptable.direction.delegationPanneau.toujoursTitre' => 'ممنوع دائمًا على المحاسب',
			'comptable.direction.delegationPanneau.toujoursDetail' => 'هذه القواعد الثلاث لا تُعدَّل.',
			'comptable.direction.delegationPanneau.autoPayout' => 'أن يدفع لنفسه',
			'comptable.direction.delegationPanneau.autoPayoutDetail' => 'دفعته الخاصة تمر دائمًا عبر شخص آخر.',
			'comptable.direction.delegationPanneau.montantManuel' => 'إدخال مبلغ يدويًا عند الدفع',
			'comptable.direction.delegationPanneau.montantManuelDetail' => 'مبلغ الدفعة هو دائمًا مبلغ الالتزام.',
			'comptable.direction.delegationPanneau.politiqueTarifaire' => 'تعديل الأسعار',
			'comptable.direction.delegationPanneau.politiqueTarifaireDetail' => 'سياسة الأسعار تبقى للإدارة.',
			'comptable.direction.titre' => 'الاحتياطي والتفويض',
			'comptable.direction.sousTitre' => 'سياسة الاحتياطي الاستراتيجي وما يستطيع المحاسب تنفيذه وحده.',
			'comptable.direction.reserve' => 'سياسة الاحتياطي الاستراتيجي',
			'comptable.direction.delegation' => 'التفويض المالي',
			'comptable.demo.titre' => 'عرض توضيحي للمحاسب',
			'comptable.demo.mention' => 'بيانات وهمية، لا دفع، لا إرسال.',
			'comptable.demo.intro' => 'اختر شاشة من شاشات المحاسب. المبالغ مخفية افتراضيًا؛ ونسخة «المبالغ ظاهرة» تكشفها طوال مدة الصفحة.',
			'comptable.demo.montantsMasques' => 'المبالغ مخفية',
			'comptable.demo.montantsAffiches' => 'المبالغ ظاهرة',
			'comptable.demo.groupeComptable' => 'واجهة المحاسب',
			'comptable.demo.groupeCompte' => 'الحساب والمستفيد',
			'comptable.demo.groupeDirection' => 'الإدارة',
			_ => null,
		};
	}
}
