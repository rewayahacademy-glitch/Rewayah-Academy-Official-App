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
	@override late final _Traductions$commun$ar commun = _Traductions$commun$ar._(_root);
	@override late final _Traductions$etat$ar etat = _Traductions$etat$ar._(_root);
	@override late final _Traductions$classe$ar classe = _Traductions$classe$ar._(_root);
	@override late final _Traductions$salle$ar salle = _Traductions$salle$ar._(_root);
	@override late final _Traductions$eleve$ar eleve = _Traductions$eleve$ar._(_root);
	@override late final _Traductions$enseignant$ar enseignant = _Traductions$enseignant$ar._(_root);
	@override late final _Traductions$compte$ar compte = _Traductions$compte$ar._(_root);
	@override late final _Traductions$tc$ar tc = _Traductions$tc$ar._(_root);
	@override late final _Traductions$com$ar com = _Traductions$com$ar._(_root);
}

// Path: commun
class _Traductions$commun$ar extends Traductions$commun$fr {
	_Traductions$commun$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$commun$sections$ar sections = _Traductions$commun$sections$ar._(_root);
}

// Path: etat
class _Traductions$etat$ar extends Traductions$etat$fr {
	_Traductions$etat$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get enDirect => 'مباشر';
	@override String get seanceAnnulee => 'ملغاة';
	@override String annuleeValeur({required Object valeur}) => 'ملغاة : ${valeur}';
	@override String get motifNonCommunique => 'السبب غير متوفر';
	@override String get aucunRemplacantTrouve => 'لم يُعثر على بديل';
	@override String get seanceNonFacturee => 'الحصة غير مفوترة';
	@override String raisonEtSuite({required Object raison, required Object suite}) => '${raison} · ${suite}';
}

// Path: classe
class _Traductions$classe$ar extends Traductions$classe$fr {
	_Traductions$classe$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$classe$entree$ar entree = _Traductions$classe$entree$ar._(_root);
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

// Path: tc
class _Traductions$tc$ar extends Traductions$tc$fr {
	_Traductions$tc$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tc$bibliotheque$ar bibliotheque = _Traductions$tc$bibliotheque$ar._(_root);
	@override late final _Traductions$tc$groupe$ar groupe = _Traductions$tc$groupe$ar._(_root);
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

// Path: commun.sections
class _Traductions$commun$sections$ar extends Traductions$commun$sections$fr {
	_Traductions$commun$sections$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get page => 'أقسام الصفحة';
}

// Path: classe.entree
class _Traductions$classe$entree$ar extends Traductions$classe$entree$fr {
	_Traductions$classe$entree$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String coursDans({required Object duree}) => 'الدرس بعد ${duree}';
	@override String get coursImminent => 'الدرس بعد أقل من دقيقة';
	@override String get rejoindre => 'انضمام';
	@override String rejoindreLecteur({required Object classe}) => 'الانضمام إلى حصة ${classe}';
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
	@override String get reessayer => 'إعادة المحاولة';
	@override String get chargementSeance => 'جارٍ تحميل الحصة القادمة.';
	@override String progressionValeur({required Object chapitre, required Object pourcentage}) => '${chapitre} · ${pourcentage} %';
	@override String dst({required Object avant, required Object apres}) => 'تغيير التوقيت: سينتقل الدرس من ${avant} إلى ${apres}.';
	@override late final _Traductions$classe$entree$annonce$ar annonce = _Traductions$classe$entree$annonce$ar._(_root);
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

// Path: tc.bibliotheque
class _Traductions$tc$bibliotheque$ar extends Traductions$tc$bibliotheque$fr {
	_Traductions$tc$bibliotheque$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tc$bibliotheque$sections$ar sections = _Traductions$tc$bibliotheque$sections$ar._(_root);
}

// Path: tc.groupe
class _Traductions$tc$groupe$ar extends Traductions$tc$groupe$fr {
	_Traductions$tc$groupe$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tc$groupe$enseignant$ar enseignant = _Traductions$tc$groupe$enseignant$ar._(_root);
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
	@override String get titre => _root.com.socle.lexique.communaute;
	@override String get vide => 'لا توجد منشورات في هذه الفئة.';
}

// Path: com.studio
class _Traductions$com$studio$ar extends Traductions$com$studio$fr {
	_Traductions$com$studio$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => _root.com.socle.lexique.studio;
	@override String get vide => 'لا يوجد نشاط للمعالجة هنا.';
}

// Path: com.annonces
class _Traductions$com$annonces$ar extends Traductions$com$annonces$fr {
	_Traductions$com$annonces$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الإعلانات';
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

// Path: tc.bibliotheque.sections
class _Traductions$tc$bibliotheque$sections$ar extends Traductions$tc$bibliotheque$sections$fr {
	_Traductions$tc$bibliotheque$sections$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get groupe => 'المواد المعروضة';
}

// Path: tc.groupe.enseignant
class _Traductions$tc$groupe$enseignant$ar extends Traductions$tc$groupe$enseignant$fr {
	_Traductions$tc$groupe$enseignant$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get sayyid => 'سيد';
	@override String get sayyida => 'سيدة';
}

// Path: com.socle.composants
class _Traductions$com$socle$composants$ar extends Traductions$com$socle$composants$fr {
	_Traductions$com$socle$composants$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
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
	@override String get fermer => 'إغلاق البحث';
	@override String get effacer => 'مسح البحث';
	@override String get aucunTitre => 'لم يتم العثور على أي محادثة';
	@override String aucun({required Object texte}) => 'لا توجد محادثة تطابق « ${texte} ». جرّب اسمًا آخر أو فصلًا آخر.';
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
	@override String avecFonction({required Object nom, required Object fonction}) => '${nom}، ${fonction}';
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
	@override String semantique({required Object noms, required Object objets}) => 'محادثة مع ${noms}، بخصوص ${objets}';
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
	@override String get autre => 'عنصر مرتبط';
}

// Path: com.messages.panneau
class _Traductions$com$messages$panneau$ar extends Traductions$com$messages$panneau$fr {
	_Traductions$com$messages$panneau$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get objets => 'العناصر المرتبطة';
	@override String get participants => 'المشاركون';
	@override String get fichiers => _root.com.socle.lexique.fichiersPartages;
	@override String ouvrir({required Object objet}) => 'فتح ${objet}';
	@override String get inaccessible => 'لم يعد بإمكانك الوصول إلى هذا العنصر. تبقى المحادثة قابلة للقراءة.';
	@override String get vous => 'أنت';
}

// Path: com.messages.fil
class _Traductions$com$messages$fil$ar extends Traductions$com$messages$fil$fr {
	_Traductions$com$messages$fil$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String auteurEtMoment({required Object auteur, required Object moment}) => '${auteur} · ${moment}';
	@override String get lectureSeule => 'يمكنك قراءة هذه المحادثة. الرد فيها غير متاح لك.';
	@override String pieceJointe({required Object nom}) => 'مرفق: ${nom}';
	@override String vocal({required Object duree}) => 'رسالة صوتية مدتها ${duree}';
	@override String get vocalSansDuree => 'رسالة صوتية';
	@override String horodatage({required Object date, required Object heure}) => '${date}، ${heure}';
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
	@override String libelleAuteur({required Object auteur, required Object duree}) => 'رسالة صوتية من ${auteur}، ${duree}';
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
	@override String get auteurEnseignante => 'الأستاذة مريم، معلمة';
	@override String get auteurParent => 'أحمد، ولي أمر آدم';
	@override String get messageRecu => 'السلام عليكم، هذه ملاحظاتي على تلاوة هذا الأسبوع.';
	@override String get horodatage => 'اليوم، 10:28';
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
	@override String get administrationTitre => 'الاتصالات';
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

/// The flat map containing all translations for locale <ar>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TraductionsAr {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'commun.sections.page' => 'أقسام الصفحة',
			'etat.enDirect' => 'مباشر',
			'etat.seanceAnnulee' => 'ملغاة',
			'etat.annuleeValeur' => ({required Object valeur}) => 'ملغاة : ${valeur}',
			'etat.motifNonCommunique' => 'السبب غير متوفر',
			'etat.aucunRemplacantTrouve' => 'لم يُعثر على بديل',
			'etat.seanceNonFacturee' => 'الحصة غير مفوترة',
			'etat.raisonEtSuite' => ({required Object raison, required Object suite}) => '${raison} · ${suite}',
			'classe.entree.coursDans' => ({required Object duree}) => 'الدرس بعد ${duree}',
			'classe.entree.coursImminent' => 'الدرس بعد أقل من دقيقة',
			'classe.entree.rejoindre' => 'انضمام',
			'classe.entree.rejoindreLecteur' => ({required Object classe}) => 'الانضمام إلى حصة ${classe}',
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
			'classe.entree.reessayer' => 'إعادة المحاولة',
			'classe.entree.chargementSeance' => 'جارٍ تحميل الحصة القادمة.',
			'classe.entree.progressionValeur' => ({required Object chapitre, required Object pourcentage}) => '${chapitre} · ${pourcentage} %',
			'classe.entree.dst' => ({required Object avant, required Object apres}) => 'تغيير التوقيت: سينتقل الدرس من ${avant} إلى ${apres}.',
			'classe.entree.annonce.aVenir' => 'حصة قادمة',
			'classe.entree.annonce.fenetreOuverte' => 'القاعة مفتوحة',
			'classe.entree.annonce.attente' => 'أنت في القاعة',
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
			'tc.bibliotheque.sections.groupe' => 'المواد المعروضة',
			'tc.groupe.enseignant.sayyid' => 'سيد',
			'tc.groupe.enseignant.sayyida' => 'سيدة',
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
			'com.socle.composants.etats.chargement' => 'جارٍ التحميل',
			'com.socle.composants.etats.videTitre' => 'لا شيء هنا حاليًا',
			'com.socle.composants.etats.erreurTitre' => 'تعذّر تحميل هذا المحتوى.',
			'com.socle.composants.etats.erreur' => 'تحقّق من اتصالك ثم أعد المحاولة.',
			'com.socle.composants.etats.reessayer' => 'إعادة المحاولة',
			'com.socle.composants.etats.horsLigne' => 'أنت غير متصل. لا يمكن تحديث الرسائل الجديدة.',
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
			'com.socle.navigation.provisoire.administrationTitre' => 'الاتصالات',
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
			'com.messages.recherche.fermer' => 'إغلاق البحث',
			'com.messages.recherche.effacer' => 'مسح البحث',
			'com.messages.recherche.aucunTitre' => 'لم يتم العثور على أي محادثة',
			'com.messages.recherche.aucun' => ({required Object texte}) => 'لا توجد محادثة تطابق « ${texte} ». جرّب اسمًا آخر أو فصلًا آخر.',
			'com.messages.recherche.resultatUn' => 'تم العثور على محادثة واحدة',
			'com.messages.recherche.resultats' => ({required Object nombre}) => 'تم العثور على ${nombre} محادثات',
			'com.messages.ligne.legende' => ({required Object objet, required Object apercu}) => '${objet} · ${apercu}',
			'com.messages.ligne.sansApercu' => 'لا توجد رسائل حاليًا',
			'com.messages.ligne.dateCourte' => ({required Object numero, required Object mois}) => '${numero} ${mois}',
			'com.messages.noms.avecFonction' => ({required Object nom, required Object fonction}) => '${nom}، ${fonction}',
			'com.messages.noms.deux' => ({required Object premier, required Object second}) => '${premier} و${second}',
			'com.messages.noms.plusieurs' => ({required Object premier, required Object nombre}) => '${premier} و${nombre} أشخاص آخرين',
			'com.messages.noms.surObjet' => ({required Object objet}) => 'محادثة بخصوص ${objet}',
			'com.messages.noms.sansObjet' => 'محادثة',
			'com.messages.entete.avecAttention' => ({required Object entete, required Object attention}) => '${entete}. ${attention}',
			'com.messages.entete.deuxObjets' => ({required Object premier, required Object second}) => '${premier} · ${second}',
			'com.messages.entete.semantique' => ({required Object noms, required Object objets}) => 'محادثة مع ${noms}، بخصوص ${objets}',
			'com.messages.entete.semantiqueSansNoms' => ({required Object objets}) => 'محادثة بخصوص ${objets}',
			'com.messages.types.classe' => 'الفصل',
			'com.messages.types.eleve' => 'الطالب',
			'com.messages.types.dossier' => 'الملف',
			'com.messages.types.mission' => 'مهمة المراقبة',
			'com.messages.types.remplacement' => 'الاستبدال',
			'com.messages.types.autre' => 'عنصر مرتبط',
			'com.messages.panneau.objets' => 'العناصر المرتبطة',
			'com.messages.panneau.participants' => 'المشاركون',
			'com.messages.panneau.fichiers' => _root.com.socle.lexique.fichiersPartages,
			'com.messages.panneau.ouvrir' => ({required Object objet}) => 'فتح ${objet}',
			'com.messages.panneau.inaccessible' => 'لم يعد بإمكانك الوصول إلى هذا العنصر. تبقى المحادثة قابلة للقراءة.',
			'com.messages.panneau.vous' => 'أنت',
			'com.messages.fil.auteurEtMoment' => ({required Object auteur, required Object moment}) => '${auteur} · ${moment}',
			'com.messages.fil.lectureSeule' => 'يمكنك قراءة هذه المحادثة. الرد فيها غير متاح لك.',
			'com.messages.fil.pieceJointe' => ({required Object nom}) => 'مرفق: ${nom}',
			'com.messages.fil.vocal' => ({required Object duree}) => 'رسالة صوتية مدتها ${duree}',
			'com.messages.fil.vocalSansDuree' => 'رسالة صوتية',
			'com.messages.fil.horodatage' => ({required Object date, required Object heure}) => '${date}، ${heure}',
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
			'com.vocal.lecteur.libelleAuteur' => ({required Object auteur, required Object duree}) => 'رسالة صوتية من ${auteur}، ${duree}',
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
			'com.vocal.demo.auteurEnseignante' => 'الأستاذة مريم، معلمة',
			'com.vocal.demo.auteurParent' => 'أحمد، ولي أمر آدم',
			'com.vocal.demo.messageRecu' => 'السلام عليكم، هذه ملاحظاتي على تلاوة هذا الأسبوع.',
			'com.vocal.demo.horodatage' => 'اليوم، 10:28',
			'com.vocal.titre' => 'رسالة صوتية',
			'com.communaute.titre' => _root.com.socle.lexique.communaute,
			'com.communaute.vide' => 'لا توجد منشورات في هذه الفئة.',
			'com.studio.titre' => _root.com.socle.lexique.studio,
			'com.studio.vide' => 'لا يوجد نشاط للمعالجة هنا.',
			'com.annonces.titre' => 'الإعلانات',
			_ => null,
		};
	}
}
