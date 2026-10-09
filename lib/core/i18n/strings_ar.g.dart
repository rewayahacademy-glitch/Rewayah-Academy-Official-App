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
	@override late final _Traductions$nav$ar nav = _Traductions$nav$ar._(_root);
	@override late final _Traductions$accessibilite$ar accessibilite = _Traductions$accessibilite$ar._(_root);
	@override late final _Traductions$reseau$ar reseau = _Traductions$reseau$ar._(_root);
	@override late final _Traductions$vide$ar vide = _Traductions$vide$ar._(_root);
	@override late final _Traductions$notifications$ar notifications = _Traductions$notifications$ar._(_root);
	@override late final _Traductions$choix$ar choix = _Traductions$choix$ar._(_root);
	@override late final _Traductions$accuse$ar accuse = _Traductions$accuse$ar._(_root);
	@override late final _Traductions$aConstruire$ar aConstruire = _Traductions$aConstruire$ar._(_root);
	@override late final _Traductions$destructif$ar destructif = _Traductions$destructif$ar._(_root);
	@override late final _Traductions$avatar$ar avatar = _Traductions$avatar$ar._(_root);
	@override late final _Traductions$pin$ar pin = _Traductions$pin$ar._(_root);
	@override late final _Traductions$enfant$ar enfant = _Traductions$enfant$ar._(_root);
	@override late final _Traductions$reglagesEnfant$ar reglagesEnfant = _Traductions$reglagesEnfant$ar._(_root);
	@override late final _Traductions$galerie$ar galerie = _Traductions$galerie$ar._(_root);
}

// Path: commun
class _Traductions$commun$ar extends Traductions$commun$fr {
	_Traductions$commun$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$commun$sections$ar sections = _Traductions$commun$sections$ar._(_root);
	@override String get marque => 'Rewayah Academy';
	@override String get continuer => 'متابعة';
	@override String get retour => 'رجوع';
	@override String get valider => 'تأكيد';
	@override String get annuler => 'إلغاء';
	@override String get fermer => 'إغلاق';
	@override String get reessayer => 'إعادة المحاولة';
	@override String get chargement => 'جارٍ التحميل';
	@override late final _Traductions$commun$demonstration$ar demonstration = _Traductions$commun$demonstration$ar._(_root);
	@override late final _Traductions$commun$etape$ar etape = _Traductions$commun$etape$ar._(_root);
	@override late final _Traductions$commun$choix$ar choix = _Traductions$commun$choix$ar._(_root);
	@override late final _Traductions$commun$etats$ar etats = _Traductions$commun$etats$ar._(_root);
	@override late final _Traductions$commun$entete$ar entete = _Traductions$commun$entete$ar._(_root);
	@override late final _Traductions$commun$selecteurProfils$ar selecteurProfils = _Traductions$commun$selecteurProfils$ar._(_root);
	@override late final _Traductions$commun$theme$ar theme = _Traductions$commun$theme$ar._(_root);
	@override late final _Traductions$commun$demarrage$ar demarrage = _Traductions$commun$demarrage$ar._(_root);
	@override late final _Traductions$commun$dates$ar dates = _Traductions$commun$dates$ar._(_root);
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
	@override String get imminent => 'قريبًا جدًا';
	@override String get annule => 'ملغى';
	@override String get enAttente => 'قيد الانتظار';
	@override String get enRetard => 'متأخر';
	@override String get termine => 'منتهٍ';
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
	@override late final _Traductions$salle$preparation$ar preparation = _Traductions$salle$preparation$ar._(_root);
	@override String get bandeauPermanent => 'الدرس مسجَّل، وزيارة مراقبة ممكنة.';
	@override late final _Traductions$salle$seance$ar seance = _Traductions$salle$seance$ar._(_root);
	@override late final _Traductions$salle$fin$ar fin = _Traductions$salle$fin$ar._(_root);
	@override String get micro => 'الميكروفون';
	@override String get camera => 'الكاميرا';
	@override String get quitter => 'مغادرة';
	@override String get ouvrirCoran => 'فتح القرآن';
	@override String get confirmerSortie => 'مغادرة الدرس؟';
	@override String get expiree => 'لم تعد هذه القاعة متاحة. عد إلى صفحتك الرئيسية للانضمام إلى الدرس القادم.';
	@override String get ouverture => 'جارٍ فتح القاعة';
	@override String get verificationMateriel => 'جارٍ التحقق من الميكروفون';
	@override String get connexion => 'جارٍ الاتصال بالدرس';
	@override String get reconnexion => 'الاتصال غير مستقر، جارٍ إعادة الاتصال';
	@override String get reconnexionCourt => 'إعادة الاتصال';
	@override String get perdue => 'انقطع الاتصال بالدرس';
	@override String get seulEnseignant => 'لم يصل معلمك بعد';
	@override String get seulEnseignantDetail => 'ابقَ على هذه الشاشة. ستراه يظهر.';
	@override String get seulEleve => 'لم يصل طالبك بعد';
	@override String get seulEleveDetail => 'ابقَ على هذه الشاشة. ستراه يظهر.';
	@override String get seulObservation => 'لم يدخل أحد هذه القاعة بعد';
	@override String get seulObservationDetail => 'لم يبدأ الدرس، أو انتهى بالفعل.';
	@override String get refusAcces => 'هذا الدرس غير مفتوح لك الآن';
	@override String get refusAccesDetail => 'تُفتح القاعة قبل موعد الدرس بعشر دقائق، وتُغلق بعد نهايته بربع ساعة.';
	@override String get refusConfiguration => 'القاعة غير متاحة بعد';
	@override String get refusConfigurationDetail => 'المشكلة ليست في جهازك: خدمة مكالمات الفيديو غير موصولة. الفريق على علم بذلك.';
	@override String get refusReseau => 'لم تستجب القاعة';
	@override String get refusReseauDetail => 'تحقّق من اتصالك، ثم أعد المحاولة.';
	@override String get refusMateriel => 'لا يوجد ميكروفون صالح على هذا الجهاز';
	@override String get refusMaterielDetail => 'درس القرآن يكون بالصوت. اسمح بالوصول إلى الميكروفون، أو وصّل سماعة، ثم أعد المحاولة.';
	@override String get retourAccueil => 'العودة إلى صفحتي الرئيسية';
	@override String get ouvrirMicro => 'فتح الميكروفون';
	@override String get fermerMicro => 'إغلاق الميكروفون';
	@override String get ouvrirCamera => 'تشغيل الكاميرا';
	@override String get fermerCamera => 'إطفاء الكاميرا';
	@override String get quitterLeCours => 'مغادرة الدرس';
	@override String get consequenceSortie => 'يستمر الدرس دونك، ويُسجَّل خروجك في الحصة.';
	@override String get vousMeme => 'أنت';
	@override String get sansImage => 'دون صورة';
	@override String get lienMediocre => 'اتصال ضعيف';
	@override String get lienPerdu => 'انقطع الاتصال';
	@override String get videoSuspendue => 'توقفت الصورة إلى أن يعود الاتصال. الصوت مستمر.';
	@override String get roleEnseignant => 'المعلم';
	@override String get roleEleve => 'الطالب';
	@override String get roleTuteur => 'وليّ الأمر، متابِع';
	@override String get roleAdministration => 'إدارة Rewayah';
	@override String get observationMuette => 'أنت تحضر الدرس. لا أحد يسمعك.';
	@override String get observationMuetteTitre => 'أنت تحضر الدرس.';
	@override String get bandeauControle => 'زيارة مراقبة. لا أحد يراك أو يسمعك، ويُسجَّل مرورك في السجل.';
	@override String get bandeauControleTitre => 'زيارة مراقبة.';
	@override late final _Traductions$salle$visiteControle$ar visiteControle = _Traductions$salle$visiteControle$ar._(_root);
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
	@override late final _Traductions$enseignant$classes$ar classes = _Traductions$enseignant$classes$ar._(_root);
	@override late final _Traductions$enseignant$eleve$ar eleve = _Traductions$enseignant$eleve$ar._(_root);
	@override late final _Traductions$enseignant$signalement$ar signalement = _Traductions$enseignant$signalement$ar._(_root);
	@override late final _Traductions$enseignant$demo$ar demo = _Traductions$enseignant$demo$ar._(_root);
	@override late final _Traductions$enseignant$bienvenue$ar bienvenue = _Traductions$enseignant$bienvenue$ar._(_root);
	@override late final _Traductions$enseignant$photo$ar photo = _Traductions$enseignant$photo$ar._(_root);
	@override late final _Traductions$enseignant$salle$ar salle = _Traductions$enseignant$salle$ar._(_root);
	@override late final _Traductions$enseignant$cahier$ar cahier = _Traductions$enseignant$cahier$ar._(_root);
	@override late final _Traductions$enseignant$profil$ar profil = _Traductions$enseignant$profil$ar._(_root);
	@override late final _Traductions$enseignant$creneaux$ar creneaux = _Traductions$enseignant$creneaux$ar._(_root);
	@override late final _Traductions$enseignant$revue$ar revue = _Traductions$enseignant$revue$ar._(_root);
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
	@override late final _Traductions$tc$coran$ar coran = _Traductions$tc$coran$ar._(_root);
	@override late final _Traductions$tc$outils$ar outils = _Traductions$tc$outils$ar._(_root);
	@override late final _Traductions$tc$classe$ar classe = _Traductions$tc$classe$ar._(_root);
	@override late final _Traductions$tc$realtime$ar realtime = _Traductions$tc$realtime$ar._(_root);
	@override late final _Traductions$tc$observation$ar observation = _Traductions$tc$observation$ar._(_root);
	@override late final _Traductions$tc$parcours$ar parcours = _Traductions$tc$parcours$ar._(_root);
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
	@override String get replier => 'طي شريط التنقل';
	@override String get deplier => 'فتح شريط التنقل';
}

// Path: accessibilite
class _Traductions$accessibilite$ar extends Traductions$accessibilite$fr {
	_Traductions$accessibilite$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$accessibilite$demo$ar demo = _Traductions$accessibilite$demo$ar._(_root);
	@override late final _Traductions$accessibilite$accueil$ar accueil = _Traductions$accessibilite$accueil$ar._(_root);
	@override late final _Traductions$accessibilite$coran$ar coran = _Traductions$accessibilite$coran$ar._(_root);
	@override late final _Traductions$accessibilite$maClasse$ar maClasse = _Traductions$accessibilite$maClasse$ar._(_root);
	@override late final _Traductions$accessibilite$tutoiement$ar tutoiement = _Traductions$accessibilite$tutoiement$ar._(_root);
	@override late final _Traductions$accessibilite$apres$ar apres = _Traductions$accessibilite$apres$ar._(_root);
	@override late final _Traductions$accessibilite$monEspace$ar monEspace = _Traductions$accessibilite$monEspace$ar._(_root);
}

// Path: reseau
class _Traductions$reseau$ar extends Traductions$reseau$fr {
	_Traductions$reseau$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get horsLigne => 'لا شبكة. ما هو معروض يبقى قابلًا للاطلاع.';
	@override String get enAttenteEnvoi => 'سيُرسل بمجرد عودة الشبكة';
	@override String get retabli => 'عادت الشبكة';
	@override String get syncImpossible => 'تعذّرت المزامنة';
}

// Path: vide
class _Traductions$vide$ar extends Traductions$vide$fr {
	_Traductions$vide$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aucunCours => 'لا دروس اليوم';
	@override String get aucunCoursDetail => 'سيظهر درسك القادم هنا.';
	@override String get aucunCreneau => 'لا موعد متاح الآن';
	@override String get aucunRapport => 'لا دفتر متابعة حتى الآن';
	@override String get aucunAppareil => 'لا جهاز مقترن';
}

// Path: notifications
class _Traductions$notifications$ar extends Traductions$notifications$fr {
	_Traductions$notifications$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الإشعارات';
	@override String get indisponibleTitre => 'الإشعارات غير متاحة بعد';
	@override String get indisponiblePhrase => 'ستظهر هنا تذكيرات الحصص ورسائل الأكاديمية بمجرد فتحها.';
	@override String get videTitre => 'لا إشعارات';
	@override String get videPhrase => 'ستظهر هنا تذكيرات الحصص ورسائل الأكاديمية.';
	@override String ligne({required Object titre, required Object date, required Object heure}) => '⁨${titre}⁩، في ⁨${date}⁩ الساعة ⁨${heure}⁩';
}

// Path: choix
class _Traductions$choix$ar extends Traductions$choix$fr {
	_Traductions$choix$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get autre => 'أخرى';
	@override String get autreInvite => 'حدّد';
	@override String get selectionMultiple => 'يمكن اختيار عدة إجابات';
}

// Path: accuse
class _Traductions$accuse$ar extends Traductions$accuse$fr {
	_Traductions$accuse$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'ما يجب معرفته قبل البدء';
	@override String get compris => 'فهمت';
}

// Path: aConstruire
class _Traductions$aConstruire$ar extends Traductions$aConstruire$fr {
	_Traductions$aConstruire$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'شاشة قيد الإنشاء';
	@override String get detail => 'تأتي هذه الشاشة في المرحلة 3.';
}

// Path: destructif
class _Traductions$destructif$ar extends Traductions$destructif$fr {
	_Traductions$destructif$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get irreversible => 'لا يمكن التراجع عن هذا الإجراء.';
}

// Path: avatar
class _Traductions$avatar$ar extends Traductions$avatar$fr {
	_Traductions$avatar$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get sansPhoto => 'لا صورة بعد';
}

// Path: pin
class _Traductions$pin$ar extends Traductions$pin$fr {
	_Traductions$pin$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'أدخل رمزك';
	@override String get erreur => 'هذا الرمز غير مطابق';
	@override String get effacer => 'مسح';
}

// Path: enfant
class _Traductions$enfant$ar extends Traductions$enfant$fr {
	_Traductions$enfant$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'إضافة ملف طالب';
	@override String get aucun => 'لا ملف طالب في الأسرة';
	@override String get aucunDetail => 'أضف أولًا ملف طالب من «الأسرة».';
}

// Path: reglagesEnfant
class _Traductions$reglagesEnfant$ar extends Traductions$reglagesEnfant$fr {
	_Traductions$reglagesEnfant$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الإعدادات حسب ملف الطالب';
	@override String get intro => 'تُضبط صورة كل طالب وكاميرته وواجهته في بطاقته، من «الأسرة». أما الطلبات إلى الإدارة فتبقى هنا.';
	@override String get renvoi => 'الصورة والكاميرا والواجهة';
	@override String renvoiLegende({required Object prenom}) => 'في بطاقة ⁨${prenom}⁩';
}

// Path: galerie
class _Traductions$galerie$ar extends Traductions$galerie$fr {
	_Traductions$galerie$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'معرض المكونات';
	@override String get avertissement => 'منصة اختبار للتطوير. غير موجودة في إصدارات الإنتاج.';
	@override String get paires => 'أزواج الألوان';
	@override String get elevation => 'الارتفاع والزوايا';
	@override String get typographie => 'سلالم الخطوط';
	@override String get polices => 'الخطوط';
	@override String get composants => 'المكونات المشتركة';
	@override String get modeEnfant => 'وضع إمكانية الوصول';
	@override String get modeStandard => 'الوضع العادي';
}

// Path: commun.sections
class _Traductions$commun$sections$ar extends Traductions$commun$sections$fr {
	_Traductions$commun$sections$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get page => 'أقسام الصفحة';
}

// Path: commun.demonstration
class _Traductions$commun$demonstration$ar extends Traductions$commun$demonstration$fr {
	_Traductions$commun$demonstration$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get repere => 'عرض تجريبي';
	@override String get repereLu => 'وضع العرض التجريبي';
}

// Path: commun.etape
class _Traductions$commun$etape$ar extends Traductions$commun$etape$fr {
	_Traductions$commun$etape$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String sur({required Object n, required Object total}) => '⁨${n}⁩ من ⁨${total}⁩';
	@override String surLue({required Object n, required Object total}) => 'الخطوة ⁨${n}⁩ من ⁨${total}⁩';
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
	@override String get reessaisEpuises => 'ما زال لا رد. أعد المحاولة لاحقًا.';
	@override String get horsLigneDemarrage => 'يحتاج Rewayah إلى الإنترنت للتحقق من حسابك. أعد توصيل هذا الجهاز، ثم أعد المحاولة.';
	@override late final _Traductions$commun$etats$actions$ar actions = _Traductions$commun$etats$actions$ar._(_root);
}

// Path: commun.entete
class _Traductions$commun$entete$ar extends Traductions$commun$entete$fr {
	_Traductions$commun$entete$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get retour => 'رجوع';
	@override String get notifications => 'الإشعارات';
	@override String get notificationsUneNonLue => 'الإشعارات، واحد غير مقروء';
	@override String notificationsNonLues({required Object nombre}) => 'الإشعارات، ⁨${nombre}⁩ غير مقروءة';
}

// Path: commun.selecteurProfils
class _Traductions$commun$selecteurProfils$ar extends Traductions$commun$selecteurProfils$fr {
	_Traductions$commun$selecteurProfils$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String etiquette({required Object prenom, required Object etat}) => '⁨${prenom}⁩، ⁨${etat}⁩';
	@override String get ajouter => 'إضافة';
	@override String get ajouterSemantique => 'إضافة ملف طالب';
}

// Path: commun.theme
class _Traductions$commun$theme$ar extends Traductions$commun$theme$fr {
	_Traductions$commun$theme$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get groupe => 'المظهر';
	@override String get clair => 'المظهر الفاتح';
	@override String get sombre => 'المظهر الداكن';
}

// Path: commun.demarrage
class _Traductions$commun$demarrage$ar extends Traductions$commun$demarrage$fr {
	_Traductions$commun$demarrage$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get ouverture => 'جارٍ فتح Rewayah';
}

// Path: commun.dates
class _Traductions$commun$dates$ar extends Traductions$commun$dates$fr {
	_Traductions$commun$dates$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
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
	@override String jourDate({required Object jour, required Object numero, required Object mois}) => '⁨${jour}⁩ ⁨${numero}⁩ ⁨${mois}⁩';
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

// Path: salle.preparation
class _Traductions$salle$preparation$ar extends Traductions$salle$preparation$fr {
	_Traductions$salle$preparation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الاستعداد لدخول الفصل';
	@override String get retour => 'العودة إلى الفصل';
	@override String get cameraCoupee => 'الكاميرا مطفأة';
	@override String get testerCamera => 'اختبار الكاميرا';
	@override String get testCameraFait => 'انتهى الاختبار المحلي. تبقى الكاميرا مطفأة عند الدخول.';
	@override String get equipement => 'أجهزتك';
	@override String get connexion => 'الاتصال';
	@override String get micro => 'الميكروفون';
	@override String get sortieAudio => 'مخرج الصوت';
	@override String get camera => 'الكاميرا';
	@override String get verification => 'جارٍ التحقق…';
	@override String get chargement => 'جارٍ التحقق من الأجهزة…';
	@override String get connexionPrete => 'الاتصال جاهز';
	@override String get connexionInstable => 'الاتصال غير مستقر';
	@override String get reseauFaible => 'الاتصال غير مستقر. الأولوية للصوت.';
	@override String get microPret => 'تم العثور على ميكروفون · الميكروفون مغلق عند الدخول';
	@override String get microAbsent => 'لم يُعثر على ميكروفون';
	@override String get microAbsentRaison => 'لم يُعثر على ميكروفون. وصّل ميكروفونًا أو فعّله لتتمكن من التدريس.';
	@override String get microBloque => 'الميكروفون محظور';
	@override String get permissionRefusee => 'الميكروفون محظور في إعدادات هذا الجهاز.';
	@override String get ouvrirReglages => 'فتح الإعدادات';
	@override String get reessayer => 'إعادة المحاولة';
	@override String get sortieSysteme => 'مخرج النظام';
	@override String get cameraPrete => 'تم العثور على كاميرا · الكاميرا مطفأة عند الدخول';
	@override String get cameraAbsente => 'الكاميرا غير متاحة. يمكنك الدخول دون كاميرا.';
	@override String get modifierPeripheriques => 'تغيير الأجهزة';
	@override String get contexte => 'سياق الحصة';
	@override String get classe => 'الفصل';
	@override String get debut => 'البداية';
	@override String get support => 'المادة المقررة';
	@override String get reprise => 'الاستئناف';
	@override String get eleves => 'الطلاب المنتظرون';
	@override String get entrer => 'دخول الفصل';
	@override String get terminee => 'انتهت هذه الحصة.';
	@override String get nonAssignee => 'هذه الحصة غير مسندة إليك.';
	@override String get retourJournee => 'العودة إلى يومي';
	@override late final _Traductions$salle$preparation$demo$ar demo = _Traductions$salle$preparation$demo$ar._(_root);
	@override late final _Traductions$salle$preparation$eleve$ar eleve = _Traductions$salle$preparation$eleve$ar._(_root);
}

// Path: salle.seance
class _Traductions$salle$seance$ar extends Traductions$salle$seance$fr {
	_Traductions$salle$seance$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'حصة مباشرة';
	@override String get titreGuidee => 'حصتي';
	@override String ligne({required Object debut, required Object fin}) => '⁨${debut}⁩ · ⁨${fin}⁩';
	@override String minutesRestantes({required Object minutes}) => 'بقيت ⁨${minutes}⁩ دقيقة';
	@override String get sePoursuit => 'الحصة مستمرة.';
	@override String get enLigne => 'متصل';
	@override String get reconnexion => 'إعادة الاتصال';
	@override String get coursEnregistreCourt => 'الدرس مسجَّل.';
	@override String get votreParentObserve => 'وليّ أمرك يتابع الحصة.';
	@override String get tonParentObserve => 'وليّ أمرك يتابع الحصة.';
	@override String tuteurDeObserve({required Object prenom}) => 'وليّ أمر ⁨${prenom}⁩ يتابع.';
	@override String get unParentObserve => 'وليّ أمر يتابع هذه الحصة';
	@override String leTuteurDeObserve({required Object prenom}) => 'وليّ أمر ⁨${prenom}⁩ يتابع الحصة.';
	@override String mentionEtNotice({required Object mention, required Object notice}) => '⁨${mention}⁩ ⁨${notice}⁩';
	@override String get retour => 'رجوع';
	@override String get notifications => 'الإشعارات';
	@override String get reglages => 'الإعدادات';
	@override String compteDe({required Object nom}) => 'حساب ⁨${nom}⁩';
	@override String get sortir => 'مغادرة الحصة';
	@override String get commandesAppel => 'أزرار المكالمة';
	@override String compteurEleves({required Object connectes, required Object inscrits}) => 'الطلاب ⁨${connectes}⁩/⁨${inscrits}⁩';
	@override String get parler => 'تحدّث';
	@override String get agrandir => 'تكبير';
	@override String get reduire => 'تصغير';
	@override String rienPartage({required Object nom}) => 'لم يشارك ⁨${nom}⁩ شيئًا بعد.';
	@override String videoDe({required Object nom}) => 'فيديو ⁨${nom}⁩';
	@override String page({required Object page, required Object pages}) => '⁨${page}⁩ / ⁨${pages}⁩';
	@override String pageSemantique({required Object page, required Object pages}) => 'الصفحة ⁨${page}⁩ من ⁨${pages}⁩';
	@override String get zoomLocal => 'تكبير محلي، لا يؤثر في الآخرين';
	@override String zoomValeur({required Object valeur}) => '⁨${valeur}⁩ %';
	@override String get zoomMoins => 'تقليل التكبير';
	@override String get zoomPlus => 'زيادة التكبير';
	@override String get quitterQuestion => 'مغادرة الحصة؟';
	@override String get quitterConsequence => 'يمكنك العودة ما دامت الحصة مفتوحة.';
	@override String get illustration => 'رسم توضيحي للمادة';
	@override String get quitterCahierConsequence => 'ستنتقل بعد ذلك إلى دفتر المتابعة.';
	@override String get quitterCahier => 'المغادرة وفتح دفتر المتابعة';
	@override String get rester => 'البقاء';
	@override String get supports => 'المواد';
	@override String get reseau => 'الشبكة';
	@override String get pagePrecedente => 'الصفحة السابقة';
	@override String get pageSuivante => 'الصفحة التالية';
	@override late final _Traductions$salle$seance$outils$ar outils = _Traductions$salle$seance$outils$ar._(_root);
	@override late final _Traductions$salle$seance$rail$ar rail = _Traductions$salle$seance$rail$ar._(_root);
	@override String get fermerPanneau => 'إغلاق اللوحة';
	@override late final _Traductions$salle$seance$panneauSupports$ar panneauSupports = _Traductions$salle$seance$panneauSupports$ar._(_root);
	@override String get eleves => 'الطلاب';
	@override String get rappeler => 'النداء بهدوء';
	@override String get faireReciter => 'طلب التلاوة';
	@override String get fileRecitation => 'دور التلاوة';
	@override String get aSuivre => 'التالي';
	@override String vousAppelle({required Object nom}) => '⁨${nom}⁩ يناديك';
	@override String get signalerBesoin => 'الإشارة إلى حاجة';
	@override String deplierFiche({required Object prenom}) => 'عرض بطاقة ⁨${prenom}⁩';
	@override String replierFiche({required Object prenom}) => 'إخفاء بطاقة ⁨${prenom}⁩';
	@override late final _Traductions$salle$seance$fiche$ar fiche = _Traductions$salle$seance$fiche$ar._(_root);
	@override String optionsPanneau({required Object titre}) => 'خيارات لوحة ⁨${titre}⁩';
	@override late final _Traductions$salle$seance$commandes$ar commandes = _Traductions$salle$seance$commandes$ar._(_root);
	@override late final _Traductions$salle$seance$bibliotheque$ar bibliotheque = _Traductions$salle$seance$bibliotheque$ar._(_root);
	@override late final _Traductions$salle$seance$surface$ar surface = _Traductions$salle$seance$surface$ar._(_root);
	@override late final _Traductions$salle$seance$capsule$ar capsule = _Traductions$salle$seance$capsule$ar._(_root);
	@override late final _Traductions$salle$seance$contexte$ar contexte = _Traductions$salle$seance$contexte$ar._(_root);
	@override late final _Traductions$salle$seance$demo$ar demo = _Traductions$salle$seance$demo$ar._(_root);
	@override late final _Traductions$salle$seance$statut$ar statut = _Traductions$salle$seance$statut$ar._(_root);
}

// Path: salle.fin
class _Traductions$salle$fin$ar extends Traductions$salle$fin$fr {
	_Traductions$salle$fin$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'انتهت الحصة';
	@override String get phrase => 'تجد عملك في فصلك.';
	@override String get retourClasse => 'العودة إلى الفصل';
	@override String get quitteTitre => 'غادرت الحصة.';
	@override String get quittePhrase => 'يمكنك العودة ما دامت مفتوحة.';
	@override String get accesRetireTitre => 'انتهى دخولك إلى هذه الحصة.';
	@override String get titreGuidee => 'انتهت الحصة.';
	@override String get retourAccueil => 'العودة إلى الصفحة الرئيسية';
	@override late final _Traductions$salle$fin$enseignant$ar enseignant = _Traductions$salle$fin$enseignant$ar._(_root);
}

// Path: salle.visiteControle
class _Traductions$salle$visiteControle$ar extends Traductions$salle$visiteControle$fr {
	_Traductions$salle$visiteControle$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'مراقبة Rewayah';
	@override String get sonRecu => 'الصوت الوارد مفتوح';
	@override String get sonCoupe => 'الصوت الوارد مكتوم';
	@override String get couperSon => 'كتم الصوت الوارد';
	@override String get retablirSon => 'إعادة الصوت الوارد';
	@override String get agrandir => 'تكبير المادة';
	@override String get reduire => 'تصغير المادة';
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
	@override String get lancer => 'بدء الدرس';
	@override String get preflight => 'التحقق قبل الدرس';
	@override String get titre => 'اليوم';
	@override String get prochainCours => 'الدرس القادم';
	@override String get coursEnCours => 'حصة مباشرة';
	@override String minuteurHeures({required Object heures, required Object minutes}) => 'بعد ⁨${heures}⁩ س ⁨${minutes}⁩ د';
	@override String minuteurMinutes({required Object minutes}) => 'بعد ⁨${minutes}⁩ دقيقة';
	@override String get minuteurImminent => 'يبدأ الآن';
	@override String jusqua({required Object heure}) => 'حتى ⁨${heure}⁩';
	@override String unAutreJour({required Object jour, required Object heure}) => '⁨${jour}⁩، الساعة ⁨${heure}⁩';
	@override String get lancementPlusTard => 'يُتاح البدء قبل موعد الدرس بعشر دقائق.';
	@override String get aucunCours => 'لا دروس قادمة';
	@override String get aucunCoursDetail => 'اقبل طالبًا في الانتظار: هذا ما يملأ يومك.';
	@override String get colonne => 'اليوم';
	@override String ligneCours({required Object prenom}) => 'درس مع ⁨${prenom}⁩';
	@override String get lignePause => 'استراحة';
	@override String plage({required Object debut, required Object fin}) => '⁨${debut}⁩ إلى ⁨${fin}⁩';
	@override String duree({required Object minutes}) => '⁨${minutes}⁩ دقيقة';
	@override String get rienAujourdhui => 'لا شيء مقرر اليوم';
	@override String rienAujourdhuiDetail({required Object jour, required Object heure}) => 'درسك القادم ⁨${jour}⁩ الساعة ⁨${heure}⁩.';
	@override String journeeTerminee({required Object nombre}) => '⁨${nombre}⁩ دروس قُدِّمت اليوم.';
	@override String get journeeTermineeUn => 'درس واحد قُدِّم اليوم.';
	@override String get voirCreneaux => 'عرض مواعيدي';
	@override String get erreur => 'تعذّرت قراءة اليوم كاملًا. أعد المحاولة بعد لحظة.';
	@override String get coursIndividuel => 'درس فردي';
	@override String effectif({required Object nombre}) => '⁨${nombre}⁩ طلاب';
	@override String get effectifUn => 'طالب واحد';
	@override String get preflightOk => 'الميكروفون جاهز';
	@override String get preflightBloque => 'متصفحك يحظر الميكروفون. اسمح به لبدء الدرس.';
	@override String get preflightSansMicro => 'لم يُعثر على ميكروفون. وصّل واحدًا لبدء الدرس.';
	@override String get preflightIndisponible => 'لم يكتمل التحقق من الأجهزة. أعد المحاولة قبل بدء الدرس.';
	@override String get lancerHorsLigne => 'دون شبكة، لا يمكن فتح القاعة. أعد الاتصال لبدء الدرس.';
	@override String get erreurPartielle => 'تعذّر تحميل أوقات الصلاة واستراحاتك (اتصال غير مستقر أو خدمة غير متاحة مؤقتًا). الحصص المعروضة محدَّثة: يمكنك بدؤها بشكل عادي.';
	@override String absenceDetectee({required Object eleve}) => 'لم يدخل ⁨${eleve}⁩ القاعة.';
	@override String coupureDetectee({required Object eleve}) => 'انقطع اتصال ⁨${eleve}⁩.';
	@override String coursAnnule({required Object heure}) => 'أُلغي درس الساعة ⁨${heure}⁩.';
	@override String get rapportsTitre => 'تقارير بانتظار الإيداع';
	@override String rapportLigne({required Object jour, required Object heure}) => 'درس ⁨${jour}⁩ الساعة ⁨${heure}⁩';
	@override String rapportAttente({required Object heures}) => 'للإيداع منذ ⁨${heures}⁩ س';
	@override String rapportRetard({required Object heures}) => 'متأخر ⁨${heures}⁩ س';
	@override String get enAttenteTitre => 'طلاب في الانتظار';
	@override String get enAttenteLibelle => 'طلاب في الانتظار في ساعاتك';
	@override String get enAttenteLibelleUn => 'طالب في الانتظار في ساعاتك';
	@override String get prochaineSeance => 'الحصة القادمة';
	@override String get maJournee => 'يومي';
	@override String get aTerminer => 'للإنهاء';
	@override String get aTerminerVide => 'كل دفاترك منتهية.';
	@override String get aTerminerErreur => 'تعذّرت قراءة الدفاتر المطلوب إنهاؤها. أعد المحاولة بعد لحظة.';
	@override String get aTerminerAide => 'دفتر المتابعة يساعد طلابك ويتيح لك تعديل الدرس القادم.';
	@override String get rappelCahier => 'دفاتر متابعة تنتظر الإنهاء';
	@override String cahierLigne({required Object classe}) => 'دفتر متابعة ⁨${classe}⁩';
	@override String cahierDetail({required Object jour, required Object numero, required Object mois, required Object heure}) => 'حصة ⁨${jour}⁩ ⁨${numero}⁩ ⁨${mois}⁩ الساعة ⁨${heure}⁩';
	@override String get alertesUtiles => 'تنبيهات مفيدة';
	@override String get alertesVide => 'لا تنبيهات مفيدة الآن.';
	@override String get alertesErreur => 'تعذّرت قراءة تنبيهات الحضور: لم يستجب الاتصال أو الخادم. أعد المحاولة بعد لحظة.';
	@override String get voirAutreAlerte => 'عرض التنبيه الآخر';
	@override String voirAutresAlertes({required Object nombre}) => 'عرض التنبيهات الأخرى (⁨${nombre}⁩)';
	@override String get remplacementsTitre => 'الاستخلافات المؤكَّدة';
	@override String get remplacementsVide => 'لا درس لزميل تتولاه الآن.';
	@override String voirTousRemplacements({required Object nombre}) => 'عرض الكل: الاستخلافات المؤكَّدة (⁨${nombre}⁩)';
	@override String get heure => 'الساعة';
	@override String get eleves => 'الطلاب';
	@override String get classe => 'الفصل';
	@override String classeNommee({required Object classe}) => 'الفصل ⁨${classe}⁩';
	@override String get preparerSeance => 'تحضير الحصة';
	@override String preparerSeanceLecteur({required Object classe}) => 'تحضير حصة ⁨${classe}⁩';
	@override String get voirClasse => 'عرض الفصل';
	@override String voirClasseLecteur({required Object classe}) => 'عرض الفصل ⁨${classe}⁩';
	@override String get aucuneSeance => 'لا حصص قادمة';
	@override String get aucuneSeanceDetail => 'ستظهر هنا حصصك القادمة.';
	@override String date({required Object jour, required Object numero, required Object mois}) => '⁨${jour}⁩ ⁨${numero}⁩ ⁨${mois}⁩';
	@override late final _Traductions$enseignant$journee$absence$ar absence = _Traductions$enseignant$journee$absence$ar._(_root);
	@override late final _Traductions$enseignant$journee$remplacement$ar remplacement = _Traductions$enseignant$journee$remplacement$ar._(_root);
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
	@override String creneauHebdo({required Object jour, required Object heure}) => '⁨${jour}⁩ الساعة ⁨${heure}⁩، كل أسبوع';
	@override String get aucunMembre => 'لا طالب في هذا الفصل';
	@override String get aucunMembreDetail => 'الإدارة تكوّن الفصول: هذا الفصل ليس فيه طالب بعد.';
	@override String get erreur => 'تعذّرت قراءة هذا الفصل. أعد المحاولة بعد لحظة.';
	@override String get introuvable => 'هذا الفصل ليس من فصولك';
	@override String get introuvableDetail => 'ربما أُغلق، أو هو لمعلم آخر.';
	@override String get revue => 'فتح مراجعة الفصل';
	@override String get ressourcesTitre => 'الموارد الأخيرة';
	@override String get progressionTitre => 'تقدم الفصل';
}

// Path: enseignant.classes
class _Traductions$enseignant$classes$ar extends Traductions$enseignant$classes$fr {
	_Traductions$enseignant$classes$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الفصول';
	@override String get vide => 'لا فصل مسند إليك';
	@override String get videDetail => 'ستظهر هنا الفصول المؤكَّدة.';
	@override String get erreur => 'تعذّرت قراءة فصولك. أعد المحاولة بعد لحظة.';
	@override String get chargement => 'جارٍ تحميل فصولك.';
	@override String niveau({required Object niveau}) => 'المستوى ⁨${niveau}⁩';
	@override String get eleveUn => 'طالب واحد';
	@override String eleves({required Object nombre}) => '⁨${nombre}⁩ طلاب';
	@override String prochaine({required Object jour, required Object heure}) => 'الحصة القادمة: ⁨${jour}⁩ الساعة ⁨${heure}⁩';
	@override String get sansProchaine => 'لا حصة مقررة';
	@override String get remplacement => 'استخلاف';
	@override String get rappelCahier => 'دفتر متابعة ينتظر التأكيد';
	@override String get cahierAValider => 'دفتر المتابعة بانتظار التأكيد';
}

// Path: enseignant.eleve
class _Traductions$enseignant$eleve$ar extends Traductions$enseignant$eleve$fr {
	_Traductions$enseignant$eleve$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String titre({required Object prenom}) => 'بطاقة ⁨${prenom}⁩';
	@override String get retour => 'الطلاب';
	@override String identifiant({required Object id}) => 'معرّف الأكاديمية: ⁨${id}⁩';
	@override String photo({required Object prenom}) => 'صورة ⁨${prenom}⁩';
	@override String get niveau => 'المستوى';
	@override String get objectif => 'الهدف';
	@override String get presence => 'الحضور الأخير';
	@override String get travail => 'العمل';
	@override String travailReprise({required Object page}) => 'الاستئناف من ⁨${page}⁩';
	@override String get derniereSeance => 'آخر حصة';
	@override String get nonRenseigne => 'غير محدد';
	@override String get signaler => 'الإشارة إلى حاجة';
	@override String get signalerAide => 'حاجة تُرفع إلى الأكاديمية، دون إعادة كتابة السياق.';
}

// Path: enseignant.signalement
class _Traductions$enseignant$signalement$ar extends Traductions$enseignant$signalement$fr {
	_Traductions$enseignant$signalement$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الإشارة إلى حاجة';
	@override String contexte({required Object prenom, required Object classe}) => 'لـ⁨${prenom}⁩ · ⁨${classe}⁩';
	@override String get categorieTitre => 'الفئة';
	@override late final _Traductions$enseignant$signalement$categories$ar categories = _Traductions$enseignant$signalement$categories$ar._(_root);
	@override String get details => 'تفاصيل داخلية';
	@override String get detailsAide => 'يقرؤها فريق الأكاديمية فقط.';
	@override String get resume => 'ملخص قابل للمشاركة';
	@override String get resumeAide => 'يمكن للأكاديمية مشاركته مع الأسرة.';
	@override String get notice => 'لا تُرسل التفاصيل الداخلية تلقائيًا إلى الأسرة.';
	@override String get choisirCategorie => 'اختر فئة للمتابعة.';
	@override String get detailsRequis => 'في «أخرى»، قل في كلمات قليلة بماذا يتعلق الأمر.';
	@override String get envoyer => 'إرسال الإشارة';
	@override String get demoSucces => 'عرض تجريبي: هذه الإشارة جاهزة، لكن لم يُرسل شيء.';
	@override String get demoSuccesDetail => 'في التطبيق الموصول، ستُرسل إلى فريق الأكاديمية.';
	@override String get fermer => 'إغلاق';
}

// Path: enseignant.demo
class _Traductions$enseignant$demo$ar extends Traductions$enseignant$demo$fr {
	_Traductions$enseignant$demo$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'عرض تجريبي للمعلم';
	@override String get mention => 'بيانات وهمية، لا إرسال.';
	@override String get intro => 'اختر شاشة من شاشات السيد إبراهيم.';
	@override String get ecrans => 'الشاشات';
	@override String get etats => 'الحالات';
	@override String get etatNominal => 'يوم عادي';
	@override String get etatVide => 'لا حصة';
	@override String get etatHorsLigne => 'غير متصل';
}

// Path: enseignant.bienvenue
class _Traductions$enseignant$bienvenue$ar extends Traductions$enseignant$bienvenue$fr {
	_Traductions$enseignant$bienvenue$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الخطوات الأولى';
	@override String salutation({required Object prenom}) => 'مرحبًا، ⁨${prenom}⁩.';
	@override String get salutationSansNom => 'مرحبًا.';
	@override String get dossierValide => 'تم اعتماد ملفك.';
	@override String get sousTitre => 'جهّز مساحتك قبل فصلك الأول.';
	@override String get aCompleter => 'للإكمال';
	@override String compteur({required Object fait, required Object total}) => '⁨${fait}⁩ من ⁨${total}⁩';
	@override String get prerequisPhoto => 'إضافة صورتي المهنية';
	@override String get prerequisLangues => 'التحقق من لغات تدريسي';
	@override String get prerequisFuseau => 'التحقق من منطقتي الزمنية';
	@override String get ctaPhoto => 'إضافة صورتي';
	@override String get ctaInformations => 'التحقق من معلوماتي';
	@override String get ctaJournee => 'عرض يومي';
	@override String get rappels => 'أمران لا ينبغي اكتشافهما في منتصف الطريق';
	@override String get declarer => 'التصريح بأوقات توفري';
	@override String get versJournee => 'الذهاب إلى يومي';
	@override String get horsLigne => 'دون شبكة، لا يمكن حفظ مواعيدك.';
	@override String get dossierIncomplet => 'لم يُعتمد ملفك بعد.';
	@override String get dossierIncompletDetail => 'بوابة الانتظار تخبرك بما بقي عليك تقديمه.';
	@override String get versAttente => 'عرض ملفي';
	@override String get erreur => 'تعذّرت قراءة ملفك الشخصي. أعد المحاولة بعد لحظة.';
}

// Path: enseignant.photo
class _Traductions$enseignant$photo$ar extends Traductions$enseignant$photo$fr {
	_Traductions$enseignant$photo$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الصورة المهنية';
	@override String get aide => 'صورتك إلزامية: الأسر لا تأتمن أطفالها لشخص مجهول على الإنترنت. تراها أسر طلابك.';
	@override String get obligatoireLecteur => 'الصورة إلزامية';
	@override String get voile => 'إن كنتِ ترتدين النقاب، يمكن أن تظهركِ صورة الملف منتقبة.';
	@override String get notice => 'لا تستخدم بطاقة هويتك.';
	@override String get choisir => 'اختيار صورة';
	@override String get utiliser => 'استخدام هذه الصورة';
	@override String get remplacer => 'استبدال الصورة';
	@override String get autre => 'اختيار صورة أخرى';
	@override String get changer => 'تغيير الصورة';
	@override String get alternatif => 'صورتك العامة';
	@override String get succes => 'حُفظت الصورة.';
	@override String get echec => 'تعذّر إرسال الصورة. لم يتغير شيء في الملف.';
	@override String get selectionEchec => 'تعذّر فتح الصورة. تحقّق من إذن الوصول إلى صور الجهاز، ثم أعد المحاولة.';
	@override String get horsLigne => 'أنت غير متصل. يمكن إرسال الصورة عند عودة الاتصال.';
}

// Path: enseignant.salle
class _Traductions$enseignant$salle$ar extends Traductions$enseignant$salle$fr {
	_Traductions$enseignant$salle$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String reference({required Object page, required Object total, required Object reference}) => 'المعروض: الصفحة ⁨${page}⁩ من ⁨${total}⁩ · ⁨${reference}⁩';
	@override String get rien => 'لا شيء معروض';
	@override String get rienInvitation => 'افتح القرآن لتعرض صفحة على فصلك.';
	@override String get attenteSalle => 'لست في القاعة بعد';
	@override String get attenteSalleDetail => 'تُفتح أوامر العرض بمجرد اتصال الدرس.';
	@override String get lienFaibleDetail => 'قد يصل تقليب الصفحة متأخرًا إلى فصلك';
	@override String get presentationConservee => 'الصفحة المعروضة محفوظة، وستُرسل عند عودة الاتصال';
	@override String get presentationSuspendue => 'العرض موقوف';
	@override String get precedente => 'عرض الصفحة السابقة';
	@override String get suivante => 'عرض الصفحة التالية';
	@override String get bibliotheque => 'اختيار سورة';
	@override String presenterSourate({required Object sourate}) => 'عرض بداية ⁨${sourate}⁩';
	@override String sourateDetail({required Object numero, required Object versets}) => 'السورة ⁨${numero}⁩ · ⁨${versets}⁩ آية';
	@override String get souratesIndisponibles => 'تعذّرت قراءة قائمة السور';
	@override String get souratesIndisponiblesDetail => 'لم يتغير ما يراه فصلك. أعد المحاولة.';
	@override String get pageIndisponible => 'تعذّرت قراءة هذه الصفحة';
	@override String get pageIndisponibleDetail => 'لم يصل النص إلى هنا. ما زال فصلك يرى الصفحة المعروضة.';
	@override String get corpusAbsent => 'نص القرآن غير مثبَّت';
	@override String get corpusAbsentDetail => 'لا شيء للعرض.';
	@override String get echecPresentation => 'تعذّر تحديد موضع هذه الآية في المصحف. لم يُرسل شيء إلى فصلك.';
	@override String get sansDroitPresentation => 'دخولك إلى هذه الحصة لا يسمح بعرض محتوى.';
}

// Path: enseignant.cahier
class _Traductions$enseignant$cahier$ar extends Traductions$enseignant$cahier$fr {
	_Traductions$enseignant$cahier$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'دفتر المتابعة';
	@override String get obligatoire => 'إلزامي';
	@override String get sousTitre => 'إلزامي بعد كل حصة';
	@override String get description => 'دوّن أين وصل كل طالب (السورة، الآية، القاعدة التي عُمل عليها). إن استخلفك معلم آخر، يستأنف تمامًا من حيث توقفت الحصة.';
	@override String duree({required Object minutes}) => '⁨${minutes}⁩ دقيقة من الدرس';
	@override String dureeEtInterruption({required Object minutes, required Object interruption}) => '⁨${minutes}⁩ دقيقة من الدرس، منها ⁨${interruption}⁩ دقيقة انقطاع';
	@override String get unEleve => 'طالب واحد';
	@override String eleves({required Object nombre}) => '⁨${nombre}⁩ طلاب';
	@override String get toutEstNominal => 'جرى كل شيء كما هو متوقع.';
	@override String get toutEstNominalDetail => 'أكّد، ويستمر يومك.';
	@override String get exceptions => 'للنظر';
	@override String get uneException => 'طالب واحد يحتاج إلى نظرة.';
	@override String plusieursExceptions({required Object nombre}) => '⁨${nombre}⁩ طلاب يحتاجون إلى نظرة.';
	@override String get nominaux => 'لا شيء يُذكر';
	@override String get curriculumFige => 'المستوى والمنهج من الأكاديمية: لا يُعدَّلان من دفتر المتابعة.';
	@override String get valider => 'تأكيد دفتر المتابعة';
	@override String get validerTout => 'كل شيء مطابق، تأكيد';
	@override String get validerSansConstat => 'الإيداع دون المعاينة';
	@override String get retourJournee => 'العودة إلى يومي';
	@override String get vide => 'تعذّر استنتاج المعاينة';
	@override String get videDetail => 'لم يُسجَّل حضور ولا حدث لهذه الحصة. يمكنك مع ذلك إيداع دفتر المتابعة.';
	@override String get erreur => 'تعذّرت قراءة المعاينة.';
	@override String get erreurDetail => 'أعد المحاولة، أو أودع دفتر المتابعة دون المعاينة.';
	@override String get echecEnvoi => 'لم يُؤكَّد الإرسال. تحقّق قبل إعادة المحاولة.';
	@override String get dejaDepose => 'دفتر متابعة هذه الحصة مودَع بالفعل.';
	@override String get dejaDeposeDetail => 'يُودَع دفتر المتابعة مرة واحدة، ولا يُحذف من هنا.';
	@override String get depose => 'حُفظ دفتر المتابعة';
	@override String get deposeDetail => 'استلمته الأكاديمية.';
	@override String get enFileTitre => 'بانتظار الإرسال';
	@override String get enFile => 'سيُرسل دفتر المتابعة عند عودة الاتصال.';
	@override String get enFileDetail => 'سيُرسل دفتر المتابعة عند عودة الاتصال.';
	@override String get enFileDetailHorsLigne => 'دون شبكة، يبقى دفتر المتابعة على هذا الجهاز ويُرسل بمجرد عودة الشبكة. يمكنك الانتقال إلى درسك التالي.';
	@override String ajusterPour({required Object eleve}) => 'تعديل · ⁨${eleve}⁩';
	@override String get ajusterValider => 'حفظ لهذا الطالب';
	@override String get exceptionConsignee => 'استثناء مُبلَغ عنه';
	@override String get pointPhonetique => 'ملاحظة في النطق';
	@override String get pointPhonetiqueDetail => 'زوج من الحروف، لا تقييم. اتركه فارغًا إن لم يكن هناك ما يُقال.';
	@override String get pointPhonetiqueNote => 'دُوِّنت ملاحظة النطق';
	@override String objectif({required Object eleve}) => 'هدف ⁨${eleve}⁩';
	@override String objectifDetail({required Object eleve}) => 'ما يجب أن يبلغه ⁨${eleve}⁩، في إطار منهج الأكاديمية.';
	@override String travailMaison({required Object eleve}) => 'واجب ⁨${eleve}⁩';
	@override String get travailMaisonDetail => 'عدّل الاقتراح، أو اتركه كما هو.';
	@override String get travailMaisonSaisi => 'دوّنت هذا الواجب بالفعل. عدّله أو اتركه كما هو.';
	@override String suite({required Object eleve}) => 'ما بعد ذلك لـ⁨${eleve}⁩';
	@override String get suiteContinuer => 'المتابعة';
	@override String get suiteRenforcer => 'التثبيت';
	@override String get suspendreNouveau => 'إيقاف الجديد';
	@override String devoirPrecedent({required Object devoir}) => 'الواجب السابق: ⁨${devoir}⁩';
	@override String devoirPlage({required Object sourate, required Object debut, required Object fin}) => 'مراجعة سورة ⁨${sourate}⁩، الآيات ⁨${debut}⁩ إلى ⁨${fin}⁩.';
	@override String get suspendreNouveauDetail => 'تستمر المراجعة، ولا يُضاف شيء جديد لهذا الطالب.';
	@override String position({required Object sourate, required Object verset}) => 'القراءة: سورة ⁨${sourate}⁩، الآية ⁨${verset}⁩';
	@override String get makhrajSinSad => 'السين / الصاد (س / ص)';
	@override String get makhrajTaTah => 'التاء / الطاء (ت / ط)';
	@override String get makhrajDhalZay => 'الذال / الزاي (ذ / ز)';
	@override String get makhrajHaHah => 'الهاء / الحاء (ه / ح)';
	@override String get exceptionTitre => 'الإبلاغ عن استثناء';
	@override String get exceptionCorriger => 'تصحيح الحضور';
	@override String get exceptionExcuser => 'تبرير الغياب';
	@override String get exceptionConfirmation => 'تأكيد الاستثناء';
	@override String get exceptionMotif => 'السبب';
	@override String get exceptionMotifRequis => 'السبب إلزامي.';
	@override String get exceptionEnCours => 'جارٍ الحفظ…';
	@override String get exceptionSucces => 'دُوِّن الاستثناء. سيُرسل مع دفتر المتابعة.';
	@override String get exceptionErreur => 'تعذّر تدوين الاستثناء.';
	@override String get exceptionHorsLigne => 'دون شبكة، لا يمكن تأكيد استثناء. أما دفتر المتابعة فيُرسل على كل حال.';
	@override String get aValider => 'للتأكيد';
	@override String statutPresents({required Object nombre}) => 'الحاضرون ⁨${nombre}⁩';
	@override String statutAbsents({required Object nombre}) => 'الغائبون ⁨${nombre}⁩';
	@override String statutEnRetard({required Object nombre}) => 'المتأخرون ⁨${nombre}⁩';
	@override String get performance => 'الأداء';
	@override String get faiblesses => 'نقاط الضعف';
	@override String get niveauARevoir => 'للمراجعة';
	@override String get niveauEnProgres => 'في تقدم';
	@override String get niveauAcquis => 'مكتسَب';
	@override String get niveauMaitrise => 'متقَن';
	@override String get faiblesseMakharij => 'المخارج';
	@override String get faiblesseMadd => 'المد';
	@override String get faiblesseGhunna => 'الغنة';
	@override String get faiblesseWaqf => 'الوقف';
	@override String get faiblesseFluidite => 'الطلاقة';
	@override String get faiblesseMemorisation => 'الحفظ';
	@override String get niveauARevoirDetail => 'يُعاد الدرس في الحصة القادمة.';
	@override String get niveauEnProgresDetail => 'الطالب يتقدم، وبقيت بعض الأخطاء.';
	@override String get niveauAcquisDetail => 'الدرس محفوظ، بأخطاء قليلة.';
	@override String get niveauMaitriseDetail => 'الدرس محفوظ دون خطأ، ويمكن للطالب أن يتقدم.';
	@override String get faiblesseMakharijDetail => 'نطق الحروف.';
	@override String get faiblesseMaddDetail => 'المدود.';
	@override String get faiblesseGhunnaDetail => 'الصوت الأنفي.';
	@override String get faiblesseWaqfDetail => 'مواضع الوقف.';
	@override String get faiblesseFluiditeDetail => 'القراءة دون تردد.';
	@override String get faiblesseMemorisationDetail => 'التلاوة من الحفظ.';
	@override String get reprise => 'أين توقف الفصل';
	@override String get repriseDetail => 'هذا موضع الاستئناف للمعلم البديل.';
	@override String repriseProposee({required Object sourate, required Object verset}) => 'سورة ⁨${sourate}⁩، الآية ⁨${verset}⁩';
	@override String get repriseRequise => 'حدّد أين توقف الفصل: سيستأنف البديل من هنا.';
	@override String get integrite => 'ما تكتبه هنا أمانة. قد لا يتحقق منه الناس، لكن الله يرى كل شيء.';
	@override String get corriger => 'تصحيح دفتر المتابعة';
	@override String corrigeLe({required Object date}) => 'صُحِّح في ⁨${date}⁩';
}

// Path: enseignant.profil
class _Traductions$enseignant$profil$ar extends Traductions$enseignant$profil$fr {
	_Traductions$enseignant$profil$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الملف الشخصي';
	@override String get compteValide => 'حساب معلم موثَّق';
	@override String get intro => 'ما تعرفه الأكاديمية عنك، وما يمكنك تغييره فيه.';
	@override String get identite => 'الهوية المهنية';
	@override String get pays => 'البلد';
	@override String get langues => 'اللغات';
	@override String get fuseau => 'المنطقة الزمنية لدروسي';
	@override String get fuseauDetail => 'هي التي تحدد توقيت مواعيدك، لا توقيت هذا الجهاز.';
	@override String get plafond => 'الحد الأسبوعي';
	@override String plafondValeur({required Object nombre}) => '⁨${nombre}⁩ ساعة في الأسبوع';
	@override String get plafondDetail => 'تحدده الأكاديمية.';
	@override String get nonRenseigne => 'غير محدد';
	@override String get statutSection => 'حالة الحساب';
	@override String get statutValideDetail => 'يمكنك التدريس والتصريح بساعاتك.';
	@override String get statutEnAttente => 'الملف قيد التحقق';
	@override String get statutEnAttenteDetail => 'تتحقق الأكاديمية من وثائقك. لا شيء آخر عليك فعله.';
	@override String get statutProvisoire => 'دخول مؤقت';
	@override String get statutProvisoireDetail => 'أنت تدرّس بالفعل. يبقى ملفك للإكمال، دون انقطاع تلقائي.';
	@override String get statutSuspendu => 'الحساب موقوف';
	@override String get statutSuspenduDetail => 'يمكنك التواصل مع الأكاديمية لمعرفة الخطوات المطلوبة.';
	@override String get statutInconnu => 'الحالة غير متاحة';
	@override String get statutInconnuDetail => 'تعذّرت قراءة حالتك.';
	@override String get statutDivergent => 'تغيّرت هذه الحالة للتو. أعد فتح التطبيق ليتبعها دخولك.';
	@override String get verification => 'التحقق من الملف';
	@override String get verificationEnAttente => 'قيد الانتظار';
	@override String get verificationValidee => 'معتمَد';
	@override String get verificationRefusee => 'يحتاج إلى مراجعة';
	@override String get contratSection => 'العقد والإقرارات';
	@override String get contratEnseignant => 'عقد المعلم';
	@override String get contratConditions => 'شروط الاستخدام';
	@override String get contratAccuse => 'التسجيل الصوتي وزيارة المراقبة';
	@override String contratDetail({required Object version, required Object date}) => 'الإصدار ⁨${version}⁩، مقبول في ⁨${date}⁩';
	@override String get contratAucun => 'لا عقد مسجَّل';
	@override String get contratAucunDetail => 'لم يمر ملفك بالتوقيع بعد.';
	@override String get contratErreur => 'تعذّرت قراءة عقودك.';
	@override String get contratLectureSeule => 'هذه الوثائق للقراءة فقط.';
	@override String get personnel => 'إعداداتي';
	@override String get deconnexionQuestion => 'تسجيل الخروج من هذا الجهاز؟';
	@override String get deconnexionConfirmer => 'تسجيل خروجي الآن';
	@override String get deconnexionConsequence => 'يبقى يومك ومواعيدك ودفاترك محفوظة. ستحتاج إلى رابط دخول جديد للعودة.';
	@override String get erreur => 'تعذّرت قراءة ملفك الشخصي. أعد المحاولة بعد لحظة.';
	@override String get vide => 'لا ملف معلم';
	@override String get videDetail => 'ليس لهذا الحساب ملف معلم. الأكاديمية وحدها يمكنها إنشاؤه.';
	@override String get horsLigne => 'لا شبكة: لا يمكن تعديل شيء هنا الآن.';
	@override String get modifierPays => 'تعديل البلد';
	@override String get modifierLangues => 'تعديل اللغات';
	@override String get languesIndice => 'افصل بين اللغات بفاصلة';
	@override String get enregistrer => 'حفظ';
	@override String get enregistre => 'حُفظ التعديل';
	@override String get editionErreur => 'لم يتم التعديل. أعد المحاولة بعد لحظة.';
}

// Path: enseignant.creneaux
class _Traductions$enseignant$creneaux$ar extends Traductions$enseignant$creneaux$fr {
	_Traductions$enseignant$creneaux$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String heureLibelle({required Object jour, required Object heure}) => '⁨${jour}⁩ الساعة ⁨${heure}⁩';
	@override String get aucuneHeure => 'لم تقترح أي ساعة. دون موعد، لا يمكن أن يُقترح عليك أي فصل.';
	@override String heureEnregistree({required Object heure}) => 'حُفظت ⁨${heure}⁩';
	@override String heureRetiree({required Object heure}) => 'أُزيلت ⁨${heure}⁩';
	@override String retraitEngage({required Object heure}) => 'أُزيلت ⁨${heure}⁩. الحصة المسندة في هذه الساعة مستمرة: اطلب إعادة إسناد لإيقافها.';
	@override String get grilleErreur => 'تعذّرت قراءة ساعاتك';
	@override String get grilleErreurDetail => 'الساعات التي حددتها لم تضِع.';
	@override String get horsLigneGrille => 'دون شبكة، تبقى ساعاتك قابلة للعرض لكن لا يمكن تعديلها.';
	@override String heureEngagee({required Object heures}) => 'لديك فصل بالفعل في ⁨${heures}⁩. إزالة هذه الساعة لا تنهي الحصة: يلزم إعادة إسناد.';
	@override String heuresEngagees({required Object heures}) => 'لديك فصل بالفعل في ⁨${heures}⁩. إزالة هذه الساعات لا تنهي الحصص: يلزم إعادة إسناد.';
	@override String get feedErreur => 'تعذّرت قراءة الأسر المنتظرة';
	@override String get feedErreurDetail => 'لم يضِع شيء: لم يُؤخذ أحد، وساعاتك باقية.';
	@override String get horsLignePrise => 'دون شبكة، لا يمكنك قبول طالب. تبقى الطلبات أدناه قابلة للعرض.';
	@override String get horsLigneDemande => 'دون شبكة، لن يُرسل هذا الطلب. أعد المحاولة عند عودة الاتصال.';
	@override String get refusDejaPris => 'قبِل معلم آخر هذا الطالب للتو. القائمة أدناه محدَّثة.';
	@override String get refusDejaSuivi => 'لهذا الطالب معلم بالفعل. القائمة أدناه محدَّثة.';
	@override String get refusCreneauRetire => 'لم تعد هذه الأسرة تقترح هذا الموعد. القائمة أدناه محدَّثة.';
	@override String get refusHorsMesHeures => 'لم يعد هذا الموعد ضمن ساعاتك. أعد إضافته في «ساعاتي» لتتمكن من قبوله.';
	@override String get refusPlafond => 'بلغت الحد الأقصى لطلابك. اطلب زيادة لتتابع طالبًا آخر.';
	@override String get mesDisponibilites => 'أوقات توفري';
	@override String get ajouterCreneau => 'إضافة موعد';
	@override String heure({required Object heure}) => 'الساعة ⁨${heure}⁩';
	@override String get classesDisponibles => 'الفصول المتاحة';
	@override String get etatDisponible => 'متاح';
	@override String get etatEnAttente => 'بانتظار الاعتماد';
	@override String get etatLimite => 'بلغت الحد الأقصى للعبء';
	@override String get limiteDetail => 'عبؤك الحالي لا يسمح بحجز فصل إضافي.';
	@override String get aucuneClasse => 'لا فصل متوافق الآن';
	@override String get aucuneClasseDetail => 'عدّل أوقات توفرك إن تغيّر جدولك.';
	@override String get reserver => 'حجز هذا الفصل';
	@override String get demandeTransmise => 'أُرسل طلبك.';
	@override String get demandeTransmiseDetail => 'سيظهر في فصولك بعد التأكيد.';
	@override String get confirmerTitre => 'تأكيد هذا الفصل؟';
	@override String get confirmer => 'تأكيد هذا الفصل';
	@override String get revenir => 'رجوع';
	@override String get cleNiveau => 'المستوى';
	@override String get cleLangue => 'اللغة';
	@override String get cleRecurrence => 'التكرار';
	@override String get cleFuseau => 'المنطقة الزمنية المرجعية';
	@override String get cleHeureLocale => 'التوقيت المحلي';
	@override String get cleDuree => 'المدة';
	@override String duree({required Object minutes}) => '⁨${minutes}⁩ دقيقة';
}

// Path: enseignant.revue
class _Traductions$enseignant$revue$ar extends Traductions$enseignant$revue$fr {
	_Traductions$enseignant$revue$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'مراجعة الفصل';
	@override String titreClasse({required Object classe}) => 'مراجعة الفصل ⁨${classe}⁩';
	@override String get aucuneAnomalie => 'لا شيء يتطلب انتباهك.';
	@override String get erreur => 'تعذّرت قراءة المراجعة.';
	@override String get erreurDetail => 'ربما ليس هذا الفصل فصلك، أو فشلت القراءة.';
	@override String get pasDeDecision => 'أنت تُبلغ، والأكاديمية تقرر: النقل وإعادة التوجيه لا يُقرَّران من هنا.';
	@override String get typeGate => 'مرحلة قادمة';
	@override String get typeCorridor => 'طالب خارج المسار المتوقع';
	@override String get typeTransfert => 'اقتراح نقل';
	@override String get typeReorientation => 'اقتراح إعادة توجيه';
}

// Path: tc.bibliotheque
class _Traductions$tc$bibliotheque$ar extends Traductions$tc$bibliotheque$fr {
	_Traductions$tc$bibliotheque$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tc$bibliotheque$sections$ar sections = _Traductions$tc$bibliotheque$sections$ar._(_root);
	@override String get titre => 'المكتبة';
	@override String get rechercheIndication => 'العنوان أو المستوى أو السورة أو الصفحة';
	@override String get rechercheLibelle => 'البحث عن مادة';
	@override String get effacerRecherche => 'عرض الكل';
	@override late final _Traductions$tc$bibliotheque$filtre$ar filtre = _Traductions$tc$bibliotheque$filtre$ar._(_root);
	@override late final _Traductions$tc$bibliotheque$vide$ar vide = _Traductions$tc$bibliotheque$vide$ar._(_root);
	@override late final _Traductions$tc$bibliotheque$aucunResultat$ar aucunResultat = _Traductions$tc$bibliotheque$aucunResultat$ar._(_root);
	@override late final _Traductions$tc$bibliotheque$indisponible$ar indisponible = _Traductions$tc$bibliotheque$indisponible$ar._(_root);
	@override late final _Traductions$tc$bibliotheque$introuvable$ar introuvable = _Traductions$tc$bibliotheque$introuvable$ar._(_root);
	@override late final _Traductions$tc$bibliotheque$offline$ar offline = _Traductions$tc$bibliotheque$offline$ar._(_root);
	@override late final _Traductions$tc$bibliotheque$type$ar type = _Traductions$tc$bibliotheque$type$ar._(_root);
	@override late final _Traductions$tc$bibliotheque$detail$ar detail = _Traductions$tc$bibliotheque$detail$ar._(_root);
	@override late final _Traductions$tc$bibliotheque$action$ar action = _Traductions$tc$bibliotheque$action$ar._(_root);
	@override late final _Traductions$tc$bibliotheque$message$ar message = _Traductions$tc$bibliotheque$message$ar._(_root);
	@override late final _Traductions$tc$bibliotheque$classe$ar classe = _Traductions$tc$bibliotheque$classe$ar._(_root);
}

// Path: tc.groupe
class _Traductions$tc$groupe$ar extends Traductions$tc$groupe$fr {
	_Traductions$tc$groupe$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tc$groupe$enseignant$ar enseignant = _Traductions$tc$groupe$enseignant$ar._(_root);
	@override late final _Traductions$tc$groupe$mesGroupes$ar mesGroupes = _Traductions$tc$groupe$mesGroupes$ar._(_root);
	@override late final _Traductions$tc$groupe$commun$ar commun = _Traductions$tc$groupe$commun$ar._(_root);
	@override late final _Traductions$tc$groupe$carte$ar carte = _Traductions$tc$groupe$carte$ar._(_root);
	@override late final _Traductions$tc$groupe$cours$ar cours = _Traductions$tc$groupe$cours$ar._(_root);
	@override late final _Traductions$tc$groupe$temps$ar temps = _Traductions$tc$groupe$temps$ar._(_root);
	@override late final _Traductions$tc$groupe$duree$ar duree = _Traductions$tc$groupe$duree$ar._(_root);
	@override late final _Traductions$tc$groupe$horloges$ar horloges = _Traductions$tc$groupe$horloges$ar._(_root);
	@override late final _Traductions$tc$groupe$dst$ar dst = _Traductions$tc$groupe$dst$ar._(_root);
	@override late final _Traductions$tc$groupe$session$ar session = _Traductions$tc$groupe$session$ar._(_root);
	@override late final _Traductions$tc$groupe$espace$ar espace = _Traductions$tc$groupe$espace$ar._(_root);
	@override late final _Traductions$tc$groupe$emplacement$ar emplacement = _Traductions$tc$groupe$emplacement$ar._(_root);
}

// Path: tc.coran
class _Traductions$tc$coran$ar extends Traductions$tc$coran$fr {
	_Traductions$tc$coran$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tc$coran$modes$ar modes = _Traductions$tc$coran$modes$ar._(_root);
	@override late final _Traductions$tc$coran$mushaf$ar mushaf = _Traductions$tc$coran$mushaf$ar._(_root);
	@override late final _Traductions$tc$coran$fidelite$ar fidelite = _Traductions$tc$coran$fidelite$ar._(_root);
	@override late final _Traductions$tc$coran$zoom$ar zoom = _Traductions$tc$coran$zoom$ar._(_root);
	@override late final _Traductions$tc$coran$navigation$ar navigation = _Traductions$tc$coran$navigation$ar._(_root);
	@override late final _Traductions$tc$coran$reprise$ar reprise = _Traductions$tc$coran$reprise$ar._(_root);
	@override late final _Traductions$tc$coran$focus$ar focus = _Traductions$tc$coran$focus$ar._(_root);
}

// Path: tc.outils
class _Traductions$tc$outils$ar extends Traductions$tc$outils$fr {
	_Traductions$tc$outils$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tc$outils$dock$ar dock = _Traductions$tc$outils$dock$ar._(_root);
	@override late final _Traductions$tc$outils$intention$ar intention = _Traductions$tc$outils$intention$ar._(_root);
	@override late final _Traductions$tc$outils$trait$ar trait = _Traductions$tc$outils$trait$ar._(_root);
	@override late final _Traductions$tc$outils$portee$ar portee = _Traductions$tc$outils$portee$ar._(_root);
	@override late final _Traductions$tc$outils$marquer$ar marquer = _Traductions$tc$outils$marquer$ar._(_root);
	@override late final _Traductions$tc$outils$revision$ar revision = _Traductions$tc$outils$revision$ar._(_root);
	@override late final _Traductions$tc$outils$masquer$ar masquer = _Traductions$tc$outils$masquer$ar._(_root);
	@override late final _Traductions$tc$outils$focus$ar focus = _Traductions$tc$outils$focus$ar._(_root);
	@override late final _Traductions$tc$outils$annotation$ar annotation = _Traductions$tc$outils$annotation$ar._(_root);
}

// Path: tc.classe
class _Traductions$tc$classe$ar extends Traductions$tc$classe$fr {
	_Traductions$tc$classe$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tc$classe$entete$ar entete = _Traductions$tc$classe$entete$ar._(_root);
	@override late final _Traductions$tc$classe$roster$ar roster = _Traductions$tc$classe$roster$ar._(_root);
	@override late final _Traductions$tc$classe$etat$ar etat = _Traductions$tc$classe$etat$ar._(_root);
	@override late final _Traductions$tc$classe$fiche$ar fiche = _Traductions$tc$classe$fiche$ar._(_root);
	@override late final _Traductions$tc$classe$action$ar action = _Traductions$tc$classe$action$ar._(_root);
	@override late final _Traductions$tc$classe$rappel$ar rappel = _Traductions$tc$classe$rappel$ar._(_root);
	@override late final _Traductions$tc$classe$recitation$ar recitation = _Traductions$tc$classe$recitation$ar._(_root);
	@override late final _Traductions$tc$classe$support$ar support = _Traductions$tc$classe$support$ar._(_root);
	@override late final _Traductions$tc$classe$commandes$ar commandes = _Traductions$tc$classe$commandes$ar._(_root);
	@override late final _Traductions$tc$classe$scene$ar scene = _Traductions$tc$classe$scene$ar._(_root);
	@override late final _Traductions$tc$classe$reseau$ar reseau = _Traductions$tc$classe$reseau$ar._(_root);
	@override late final _Traductions$tc$classe$attente$ar attente = _Traductions$tc$classe$attente$ar._(_root);
	@override late final _Traductions$tc$classe$lien$ar lien = _Traductions$tc$classe$lien$ar._(_root);
	@override late final _Traductions$tc$classe$barre$ar barre = _Traductions$tc$classe$barre$ar._(_root);
	@override late final _Traductions$tc$classe$prevol$ar prevol = _Traductions$tc$classe$prevol$ar._(_root);
	@override late final _Traductions$tc$classe$observation$ar observation = _Traductions$tc$classe$observation$ar._(_root);
}

// Path: tc.realtime
class _Traductions$tc$realtime$ar extends Traductions$tc$realtime$fr {
	_Traductions$tc$realtime$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tc$realtime$transport$ar transport = _Traductions$tc$realtime$transport$ar._(_root);
	@override late final _Traductions$tc$realtime$etat$ar etat = _Traductions$tc$realtime$etat$ar._(_root);
}

// Path: tc.observation
class _Traductions$tc$observation$ar extends Traductions$tc$observation$fr {
	_Traductions$tc$observation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tc$observation$entree$ar entree = _Traductions$tc$observation$entree$ar._(_root);
	@override late final _Traductions$tc$observation$explication$ar explication = _Traductions$tc$observation$explication$ar._(_root);
	@override late final _Traductions$tc$observation$disponibilite$ar disponibilite = _Traductions$tc$observation$disponibilite$ar._(_root);
	@override late final _Traductions$tc$observation$connexion$ar connexion = _Traductions$tc$observation$connexion$ar._(_root);
	@override late final _Traductions$tc$observation$duree$ar duree = _Traductions$tc$observation$duree$ar._(_root);
	@override late final _Traductions$tc$observation$refus$ar refus = _Traductions$tc$observation$refus$ar._(_root);
	@override late final _Traductions$tc$observation$visite$ar visite = _Traductions$tc$observation$visite$ar._(_root);
	@override late final _Traductions$tc$observation$fin$ar fin = _Traductions$tc$observation$fin$ar._(_root);
	@override late final _Traductions$tc$observation$resultat$ar resultat = _Traductions$tc$observation$resultat$ar._(_root);
	@override late final _Traductions$tc$observation$annonce$ar annonce = _Traductions$tc$observation$annonce$ar._(_root);
	@override late final _Traductions$tc$observation$reglages$ar reglages = _Traductions$tc$observation$reglages$ar._(_root);
}

// Path: tc.parcours
class _Traductions$tc$parcours$ar extends Traductions$tc$parcours$fr {
	_Traductions$tc$parcours$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tc$parcours$avant$ar avant = _Traductions$tc$parcours$avant$ar._(_root);
	@override late final _Traductions$tc$parcours$intention$ar intention = _Traductions$tc$parcours$intention$ar._(_root);
	@override late final _Traductions$tc$parcours$plage$ar plage = _Traductions$tc$parcours$plage$ar._(_root);
	@override late final _Traductions$tc$parcours$feedback$ar feedback = _Traductions$tc$parcours$feedback$ar._(_root);
	@override late final _Traductions$tc$parcours$signalement$ar signalement = _Traductions$tc$parcours$signalement$ar._(_root);
	@override late final _Traductions$tc$parcours$postCours$ar postCours = _Traductions$tc$parcours$postCours$ar._(_root);
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
	@override String get disponibilites => 'أوقات التوفر';
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
	@override String get creneaux => 'أوقات التوفر';
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
	@override String get configuration => 'الإعدادات العامة';
	@override String get securite => 'الأمان والتدقيق';
	@override String get direction => 'الإدارة';
	@override String get recherche => 'البحث';
	@override String get rechercheIndication => 'البحث عن شاشة';
	@override String get notificationsTitre => 'الإشعارات';
	@override String get menu => 'القائمة';
}

// Path: accessibilite.demo
class _Traductions$accessibilite$demo$ar extends Traductions$accessibilite$demo$fr {
	_Traductions$accessibilite$demo$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'عرض تجريبي لوضع إمكانية الوصول';
	@override String get mention => 'بيانات وهمية، لا إرسال.';
	@override String get intro => 'اختر طالبًا ولحظة من الحصة.';
	@override String get eleveMineure => 'مريم، طالبة قاصر';
	@override String get eleveAdulte => 'إدريس، طالب بالغ';
	@override String get etatAvant => 'قبل الحصة';
	@override String get etatFenetre => 'قبيل الحصة، الدخول مفتوح';
	@override String get etatPendant => 'أثناء الحصة';
	@override String get etatApres => 'بعد الحصة';
}

// Path: accessibilite.accueil
class _Traductions$accessibilite$accueil$ar extends Traductions$accessibilite$accueil$fr {
	_Traductions$accessibilite$accueil$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String salutation({required Object prenom}) => 'السلام عليكم، ⁨${prenom}⁩.';
	@override String get prochaineSeance => 'الحصة القادمة';
	@override String avec({required Object nomme}) => 'مع ⁨${nomme}⁩';
	@override String get voirMaClasse => 'عرض فصلي';
	@override String get lireCoran => 'قراءة القرآن';
	@override String get lireCoranDetail => 'فتح المصحف';
	@override String get aide => 'تحتاج إلى مساعدة؟';
	@override String get erreurTitre => 'لم تُحمَّل الحصة القادمة';
	@override String get erreurPhrase => 'تعذّرت قراءة الحصة والعمل المطلوب، غالبًا بسبب الاتصال. يكفي أن تعيد المحاولة بعد لحظة.';
	@override String get indisponibleTitre => 'الحصة القادمة لا تظهر هنا بعد';
	@override String get indisponiblePhrase => 'الصفحة الرئيسية لا تستقبل حصة الفصل بعد. تجدها في «فصلي».';
	@override String get videTitre => 'لا فصل بعد';
	@override String get videPhrase => 'لم يُسند أي فصل بعد. يُختار الفصل مع الأكاديمية. وإلى ذلك الحين، يبقى القرآن والمساعدة متاحين أدناه.';
}

// Path: accessibilite.coran
class _Traductions$accessibilite$coran$ar extends Traductions$accessibilite$coran$fr {
	_Traductions$accessibilite$coran$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get ouvrir => 'فتح القرآن';
	@override String get reprendre => 'المتابعة من آخر صفحة';
	@override String get reprendreVous => 'المتابعة من آخر صفحة';
	@override String reprendreDetail({required Object page}) => 'كنت في الصفحة ⁨${page}⁩.';
	@override String reprendreDetailVous({required Object page}) => 'كنت في الصفحة ⁨${page}⁩.';
	@override String get repriseRecherche => 'جارٍ البحث عن آخر صفحة…';
	@override String get repriseRechercheVous => 'جارٍ البحث عن آخر صفحة…';
	@override String get repriseErreur => 'تعذّر العثور على آخر صفحة، غالبًا بسبب الاتصال. افتح القرآن واختر صفحتك في القارئ. إعدادات القراءة تبقى محفوظة.';
	@override String get repriseErreurVous => 'تعذّر العثور على آخر صفحة، غالبًا بسبب الاتصال. افتح القرآن واختر صفحتك في القارئ. إعدادات القراءة تبقى محفوظة.';
	@override String get lectureGrande => 'يُفتح القرآن في قراءة مكبَّرة، آية آية.';
	@override String get retour => 'العودة إلى مدخل القرآن';
	@override String get demoSansTexte => 'نص القرآن غير محمَّل في العرض التجريبي';
	@override String get demoSansTexteDetail => 'ليس هذا عطلًا: العرض التجريبي لا يحتوي على النص. لا شيء عليك فعله. في التطبيق، يُفتح القرآن هنا على صفحتك، وتبقى إعدادات القراءة محفوظة.';
	@override String get demoSansTexteDetailVous => 'ليس هذا عطلًا: العرض التجريبي لا يحتوي على النص. لا شيء عليك فعله. في التطبيق، يُفتح القرآن هنا على صفحتك، وتبقى إعدادات القراءة محفوظة.';
}

// Path: accessibilite.maClasse
class _Traductions$accessibilite$maClasse$ar extends Traductions$accessibilite$maClasse$fr {
	_Traductions$accessibilite$maClasse$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'فصلي';
	@override String get suivi => 'متابعتي';
	@override String get suiviDetail => 'الحصص الماضية والحضور';
}

// Path: accessibilite.tutoiement
class _Traductions$accessibilite$tutoiement$ar extends Traductions$accessibilite$tutoiement$fr {
	_Traductions$accessibilite$tutoiement$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get tonHeure => 'توقيتك';
	@override String get attenteDetail => 'وقت الانتظار هذا لا يُحتسب في حضورك.';
	@override String attente({required Object duree}) => 'أنت في القاعة. تبدأ الحصة بعد ⁨${duree}⁩.';
	@override String get attenteImminent => 'أنت في القاعة. تبدأ الحصة بعد أقل من دقيقة.';
	@override String get annonceAttente => 'أنت في القاعة';
	@override String get horsLigne => 'أنت غير متصل. تحتاج الحصة إلى اتصال.';
	@override String get finPhrase => 'تجد عملك في فصلك.';
}

// Path: accessibilite.apres
class _Traductions$accessibilite$apres$ar extends Traductions$accessibilite$apres$fr {
	_Traductions$accessibilite$apres$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get revoirSupport => 'مراجعة مادة الدرس';
	@override String get revoirSupportDetail => 'تبقى المادة في فصلك.';
	@override String get revoirSupportDetailVous => 'تبقى المادة في فصلك.';
}

// Path: accessibilite.monEspace
class _Traductions$accessibilite$monEspace$ar extends Traductions$accessibilite$monEspace$fr {
	_Traductions$accessibilite$monEspace$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'مساحتي';
	@override String get mode => 'وضع إمكانية الوصول';
	@override String get modeDetail => 'واجهة مبسطة ومكيَّفة لتعلم أكثر طمأنينة.';
	@override String get modeActif => 'مفعَّل';
	@override String get presentationStandard => 'العرض العادي';
	@override String get demanderDetail => 'اطلب من وليّ أمرك الانتقال إلى العرض العادي.';
	@override String get demandeEnCours => 'جارٍ إرسال طلبك.';
	@override String get demandeEnvoyee => 'أُرسل طلبك إلى وليّ أمرك.';
	@override String get demandeNonConfirmee => 'لم يُؤكَّد الإرسال، غالبًا بسبب الاتصال. تحقّق من اتصالك، ثم المس السطر لإعادة المحاولة. لم يتغير شيء في الأثناء: يبقى العرض كما هو.';
}

// Path: commun.etats.chargementProlonge
class _Traductions$commun$etats$chargementProlonge$ar extends Traductions$commun$etats$chargementProlonge$fr {
	_Traductions$commun$etats$chargementProlonge$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الاتصال يستغرق وقتًا أطول من المتوقع';
	@override String get phrase => 'يمكنك الانتظار قليلًا أو إعادة المحاولة.';
}

// Path: commun.etats.horsLigne
class _Traductions$commun$etats$horsLigne$ar extends Traductions$commun$etats$horsLigne$fr {
	_Traductions$commun$etats$horsLigne$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'أنت غير متصل';
	@override String get phrase => 'تحقّق من اتصالك. ما هو معروض يبقى قابلًا للاطلاع.';
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
	@override String get phrase => 'ربما الرابط ناقص، أو لم تعد الصفحة موجودة.';
}

// Path: commun.etats.accesRefuse
class _Traductions$commun$etats$accesRefuse$ar extends Traductions$commun$etats$accesRefuse$fr {
	_Traductions$commun$etats$accesRefuse$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'ليس لديك إذن بالوصول إلى هذه الصفحة';
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
	@override String get phrase => 'بقيت خطوة قبل فتح هذه المساحة.';
}

// Path: commun.etats.aucunResultat
class _Traductions$commun$etats$aucunResultat$ar extends Traductions$commun$etats$aucunResultat$fr {
	_Traductions$commun$etats$aucunResultat$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'لا نتائج';
	@override String get phrase => 'لا شيء مطابق الآن.';
}

// Path: commun.etats.permissionRefusee
class _Traductions$commun$etats$permissionRefusee$ar extends Traductions$commun$etats$permissionRefusee$fr {
	_Traductions$commun$etats$permissionRefusee$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الإذن مرفوض';
	@override String get phrase => 'دون هذا الإذن، لا يمكن فتح هذه الوظيفة. يمكنك تغييره في إعدادات جهازك.';
}

// Path: commun.etats.ressourceExpiree
class _Traductions$commun$etats$ressourceExpiree$ar extends Traductions$commun$etats$ressourceExpiree$fr {
	_Traductions$commun$etats$ressourceExpiree$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'هذا المحتوى لم يعد متاحًا';
	@override String get phrase => 'سُحب، أو انتهى الوصول إليه.';
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

// Path: salle.preparation.demo
class _Traductions$salle$preparation$demo$ar extends Traductions$salle$preparation$demo$fr {
	_Traductions$salle$preparation$demo$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get section => 'استعداد المعلم';
	@override String get pret => 'جاهز';
	@override String get reseauFaible => 'شبكة ضعيفة';
	@override String get microAbsent => 'لا يوجد ميكروفون';
	@override String get permissionRefusee => 'الإذن مرفوض';
}

// Path: salle.preparation.eleve
class _Traductions$salle$preparation$eleve$ar extends Traductions$salle$preparation$eleve$fr {
	_Traductions$salle$preparation$eleve$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get verification => 'نتحقق من جهازك…';
	@override String get pret => 'كل شيء جاهز';
	@override String get audio => 'الصوت';
	@override String get acces => 'الدخول إلى الفصل';
	@override String get accesOk => 'يمكنك الدخول';
	@override String get accesAttente => 'في انتظار الاتصال';
	@override String get microCoupe => 'ستدخل والميكروفون مغلق.';
	@override String get microInaccessible => 'لا يمكن الوصول إلى الميكروفون';
	@override String get microInaccessibleDetail => 'لن يسمعك أحد في الفصل ما دام الوصول إلى الميكروفون محظورًا.';
	@override String get autoriserMicro => 'السماح بالميكروفون';
	@override late final _Traductions$salle$preparation$eleve$guidee$ar guidee = _Traductions$salle$preparation$eleve$guidee$ar._(_root);
	@override late final _Traductions$salle$preparation$eleve$demo$ar demo = _Traductions$salle$preparation$eleve$demo$ar._(_root);
}

// Path: salle.seance.outils
class _Traductions$salle$seance$outils$ar extends Traductions$salle$seance$outils$fr {
	_Traductions$salle$seance$outils$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'أدوات التدريس';
	@override String get pointeur => 'المؤشر';
	@override String get marquer => 'تعليم';
	@override String get masquer => 'إخفاء';
	@override String get annoter => 'كتابة ملاحظات';
}

// Path: salle.seance.rail
class _Traductions$salle$seance$rail$ar extends Traductions$salle$seance$rail$fr {
	_Traductions$salle$seance$rail$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get navigation => 'التنقل';
	@override String get marque => 'Rewayah';
	@override String get sousMarque => 'Academy';
	@override String get journee => 'اليوم';
	@override String get classes => 'الفصول';
	@override String get ressources => 'الموارد';
	@override String get profil => 'الملف الشخصي';
}

// Path: salle.seance.panneauSupports
class _Traductions$salle$seance$panneauSupports$ar extends Traductions$salle$seance$panneauSupports$fr {
	_Traductions$salle$seance$panneauSupports$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get reprendre => 'استئناف';
	@override String get recents => 'الأحدث';
	@override String get ressourcesClasse => 'موارد الفصل';
	@override String get voirTout => 'عرض الكل';
	@override String get ouvrir => 'فتح';
	@override String ouvrirSupport({required Object titre}) => 'فتح ⁨${titre}⁩';
	@override String get voirBibliotheque => 'عرض المكتبة كاملة';
}

// Path: salle.seance.fiche
class _Traductions$salle$seance$fiche$ar extends Traductions$salle$seance$fiche$fr {
	_Traductions$salle$seance$fiche$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aucuneSeanceSemaine => 'لا حصص هذا الأسبوع';
	@override String get uneSeanceSemaine => 'حصة واحدة هذا الأسبوع';
	@override String seancesSemaine({required Object nombre}) => '⁨${nombre}⁩ حصص هذا الأسبوع';
}

// Path: salle.seance.commandes
class _Traductions$salle$seance$commandes$ar extends Traductions$salle$seance$commandes$fr {
	_Traductions$salle$seance$commandes$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get declencheur => 'الأوامر';
	@override String get declencheurSemantique => 'فتح أوامر المادة والسبورة';
	@override String get titre => 'الأوامر';
	@override String get reduire => 'تصغير';
	@override String get reduireSemantique => 'تصغير الأوامر';
	@override String get ongletSupport => 'المادة';
	@override String get ongletOutils => 'الأدوات';
	@override String get bibliotheque => 'المكتبة';
	@override String get affichageSupport => 'المادة';
	@override String get affichageAvecNotes => 'مع الملاحظات';
	@override String get affichageTableau => 'السبورة';
	@override String get lecture => 'القراءة';
	@override String get ajuster => 'ملاءمة الشاشة';
	@override String get affichage => 'العرض';
	@override String get focus => 'التركيز';
	@override String get focusSemantique => 'التركيز، تكبير المحتوى وتصغير اللوحات';
	@override String get quitterFocus => 'الخروج من التركيز';
}

// Path: salle.seance.bibliotheque
class _Traductions$salle$seance$bibliotheque$ar extends Traductions$salle$seance$bibliotheque$fr {
	_Traductions$salle$seance$bibliotheque$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get intro => 'المادة التي تختارها تُفتح لك وحدك. يبقى الفصل على المادة الحالية حتى «عرض».';
	@override String get apercu => 'معاينة خاصة';
	@override String get apercuClasse => 'ما زال الطلاب يرون المادة الحالية.';
	@override String get presenter => 'عرض';
	@override String get revenir => 'العودة إلى المواد';
	@override String get ouverture => 'جارٍ فتح المادة…';
	@override String get echec => 'تعذّر فتح هذه المادة.';
	@override String get echecDetail => 'تعذّر تحميل الملف. يبقى الفصل على المادة الحالية. أعد المحاولة، أو عد إلى المواد لاختيار مادة أخرى.';
}

// Path: salle.seance.surface
class _Traductions$salle$seance$surface$ar extends Traductions$salle$seance$surface$fr {
	_Traductions$salle$seance$surface$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aucunSupport => 'اختر مادة أو اكتب على السبورة.';
	@override String page({required Object titre, required Object page, required Object pages}) => '⁨${titre}⁩، الصفحة ⁨${page}⁩ من ⁨${pages}⁩';
	@override String get supportMasque => 'السبورة، المادة مخفية';
}

// Path: salle.seance.capsule
class _Traductions$salle$seance$capsule$ar extends Traductions$salle$seance$capsule$fr {
	_Traductions$salle$seance$capsule$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String avatar({required Object nom}) => 'عرض معلومات ⁨${nom}⁩';
	@override String get controlePossible => 'المراقبة ممكنة. عرض المعلومات';
	@override String get controleActif => 'المراقبة جارية. عرض المعلومات';
	@override String get enregistrementActif => 'التسجيل جارٍ';
}

// Path: salle.seance.contexte
class _Traductions$salle$seance$contexte$ar extends Traductions$salle$seance$contexte$fr {
	_Traductions$salle$seance$contexte$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'معلومات الحصة';
	@override String get reseau => 'الشبكة';
	@override String get detailReseau => 'تفاصيل الشبكة';
	@override String get enregistrementActif => 'التسجيل جارٍ';
	@override String get controle => 'المراقبة';
	@override String get controlePossible => 'المراقبة ممكنة';
	@override String get controleActif => 'المراقبة جارية';
	@override String get controlePossibleDetail => 'قد تجري زيارة مراقبة. هذا لا يعني أن أحدًا يتابع الآن.';
	@override String get controleActifDetail => 'تجري زيارة مراقبة الآن.';
	@override String get reduire => 'تصغير';
	@override String get reduireParticipants => 'تصغير المشاركين';
	@override String get reduireInformations => 'تصغير المعلومات';
}

// Path: salle.seance.demo
class _Traductions$salle$seance$demo$ar extends Traductions$salle$seance$demo$fr {
	_Traductions$salle$seance$demo$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'قاعة العرض التجريبي';
	@override String get intro => 'بيانات وهمية، دون خادم. اختر دورًا وحالة.';
	@override late final _Traductions$salle$seance$demo$groupes$ar groupes = _Traductions$salle$seance$demo$groupes$ar._(_root);
	@override late final _Traductions$salle$seance$demo$roles$ar roles = _Traductions$salle$seance$demo$roles$ar._(_root);
	@override late final _Traductions$salle$seance$demo$etats$ar etats = _Traductions$salle$seance$demo$etats$ar._(_root);
	@override late final _Traductions$salle$seance$demo$tb$ar tb = _Traductions$salle$seance$demo$tb$ar._(_root);
}

// Path: salle.seance.statut
class _Traductions$salle$seance$statut$ar extends Traductions$salle$seance$statut$fr {
	_Traductions$salle$seance$statut$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get connecte => 'متصل';
	@override String get pasEncoreConnecte => 'لم يتصل بعد';
	@override String get connexionInterrompue => 'انقطع الاتصال';
}

// Path: salle.fin.enseignant
class _Traductions$salle$fin$enseignant$ar extends Traductions$salle$fin$enseignant$fr {
	_Traductions$salle$fin$enseignant$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get terminee => 'منتهية';
	@override String get phrase => 'دفتر المتابعة جاهز بمعلومات الحصة.';
	@override String get recapitulatif => 'ملخص الحصة';
	@override String get fin => 'النهاية';
	@override String connectes({required Object n}) => '⁨${n}⁩ طلاب متصلون';
	@override String unConnecte({required Object n}) => '⁨${n}⁩ طالب متصل';
	@override String inscrits({required Object n}) => 'من ⁨${n}⁩ مسجَّلين';
	@override String unInscrit({required Object n}) => 'من ⁨${n}⁩ مسجَّل';
	@override String get cahierSeance => 'دفتر المتابعة';
	@override String get cahierACompleter => 'دفتر المتابعة بانتظار الإكمال';
	@override String get ouvrirCahier => 'فتح دفتر المتابعة';
	@override String get revenirJournee => 'العودة إلى يومي';
	@override String get erreurCahier => 'تعذّر فتح دفتر المتابعة الآن. أعد المحاولة بعد لحظة.';
}

// Path: enseignant.journee.absence
class _Traductions$enseignant$journee$absence$ar extends Traductions$enseignant$journee$absence$fr {
	_Traductions$enseignant$journee$absence$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get ouvrir => 'الإبلاغ عن غيابي في هذه الحصة';
	@override String get ouvrirContexte => 'سيُبحث عن بديل لطلابك.';
	@override String get titre => 'لن تستطيع تولي هذه الحصة؟';
	@override String get cleDate => 'التاريخ';
	@override String get notice => 'يبقى إسنادك إلى الفصل كما هو.';
	@override String get declarer => 'التصريح بغيابي';
	@override String get echec => 'لم يكتمل الطلب. أعد المحاولة بعد لحظة.';
	@override late final _Traductions$enseignant$journee$absence$etats$ar etats = _Traductions$enseignant$journee$absence$etats$ar._(_root);
}

// Path: enseignant.journee.remplacement
class _Traductions$enseignant$journee$remplacement$ar extends Traductions$enseignant$journee$remplacement$fr {
	_Traductions$enseignant$journee$remplacement$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'تولي هذا الاستخلاف؟';
	@override String get assurer => 'تولي هذا الاستخلاف';
	@override String get pasCetteFois => 'ليس هذه المرة';
}

// Path: enseignant.signalement.categories
class _Traductions$enseignant$signalement$categories$ar extends Traductions$enseignant$signalement$categories$fr {
	_Traductions$enseignant$signalement$categories$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get pedagogique => 'مشكلة تعليمية';
	@override String get presence => 'الحضور';
	@override String get technique => 'تقنية';
	@override String get changement => 'تغيير';
	@override String get autre => 'أخرى';
}

// Path: tc.bibliotheque.sections
class _Traductions$tc$bibliotheque$sections$ar extends Traductions$tc$bibliotheque$sections$fr {
	_Traductions$tc$bibliotheque$sections$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get groupe => 'المواد المعروضة';
	@override String get continuer => 'متابعة';
	@override String get pourCeGroupe => 'لهذا الفصل';
	@override String get recents => 'الأحدث';
	@override String get tousLesSupports => 'كل المواد';
	@override String get resultats => 'النتائج';
}

// Path: tc.bibliotheque.filtre
class _Traductions$tc$bibliotheque$filtre$ar extends Traductions$tc$bibliotheque$filtre$fr {
	_Traductions$tc$bibliotheque$filtre$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get type => 'النوع';
	@override String get disponibilite => 'التوفر';
}

// Path: tc.bibliotheque.vide
class _Traductions$tc$bibliotheque$vide$ar extends Traductions$tc$bibliotheque$vide$fr {
	_Traductions$tc$bibliotheque$vide$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get message => 'لا مادة منشورة حتى الآن';
	@override String get invitation => 'سيضع معلموك هنا مواد دروسك.';
}

// Path: tc.bibliotheque.aucunResultat
class _Traductions$tc$bibliotheque$aucunResultat$ar extends Traductions$tc$bibliotheque$aucunResultat$fr {
	_Traductions$tc$bibliotheque$aucunResultat$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get message => 'لا مادة مطابقة';
	@override String get invitation => 'جرّب كلمة أخرى، أو خفّف عوامل التصفية.';
}

// Path: tc.bibliotheque.indisponible
class _Traductions$tc$bibliotheque$indisponible$ar extends Traductions$tc$bibliotheque$indisponible$fr {
	_Traductions$tc$bibliotheque$indisponible$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get message => 'المكتبة غير متاحة مؤقتًا';
	@override String get action => 'إعادة المحاولة';
}

// Path: tc.bibliotheque.introuvable
class _Traductions$tc$bibliotheque$introuvable$ar extends Traductions$tc$bibliotheque$introuvable$fr {
	_Traductions$tc$bibliotheque$introuvable$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get message => 'هذه المادة غير مفتوحة لك';
	@override String get invitation => 'ربما سُحبت، أو هي مخصصة لفصل آخر. يمكن لمعلمك أن يعيد فتحها لك.';
}

// Path: tc.bibliotheque.offline
class _Traductions$tc$bibliotheque$offline$ar extends Traductions$tc$bibliotheque$offline$fr {
	_Traductions$tc$bibliotheque$offline$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aTelecharger => 'للتنزيل';
	@override String get enCours => 'جارٍ التنزيل';
	@override String get enCache => 'في الذاكرة المؤقتة';
	@override String get telecharge => 'تم التنزيل';
	@override String get indisponible => 'غير متاحة دون اتصال';
}

// Path: tc.bibliotheque.type
class _Traductions$tc$bibliotheque$type$ar extends Traductions$tc$bibliotheque$type$fr {
	_Traductions$tc$bibliotheque$type$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get quran => 'القرآن';
	@override String get texteStructure => 'نص';
	@override String get pdf => 'PDF';
	@override String get image => 'صورة';
	@override String get lecon => 'درس';
}

// Path: tc.bibliotheque.detail
class _Traductions$tc$bibliotheque$detail$ar extends Traductions$tc$bibliotheque$detail$fr {
	_Traductions$tc$bibliotheque$detail$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'المادة';
	@override String get capacites => 'ما تتيحه هذه المادة';
	@override String get niveaux => 'المستويات';
	@override String get sansVersion => 'لا نسخة منشورة: لا شيء للفتح الآن.';
	@override String get apercuIndisponible => 'معاينة هذا التنسيق غير متاحة بعد في التطبيق. يمكنك حفظ نسخة منه.';
	@override String get renduCoran => 'يُفتح القرآن في القارئ المخصص له.';
}

// Path: tc.bibliotheque.action
class _Traductions$tc$bibliotheque$action$ar extends Traductions$tc$bibliotheque$action$fr {
	_Traductions$tc$bibliotheque$action$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get telecharger => 'إتاحتها دون اتصال';
	@override String get liberer => 'تحرير المساحة';
	@override String get enregistrerCopie => 'حفظ نسخة';
}

// Path: tc.bibliotheque.message
class _Traductions$tc$bibliotheque$message$ar extends Traductions$tc$bibliotheque$message$fr {
	_Traductions$tc$bibliotheque$message$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get copieEnregistree => 'حُفظت النسخة';
	@override String get copieImpossible => 'هذه النسخة غير متاحة الآن';
	@override String get telechargementImpossible => 'هذه المادة غير متاحة دون اتصال بعد';
	@override String get horsLigneNonTelecharge => 'تتاح بعد تنزيلها أو عند عودة الاتصال';
	@override String get aucunTelechargement => 'لا ملف للتنزيل في هذه النسخة.';
}

// Path: tc.bibliotheque.classe
class _Traductions$tc$bibliotheque$classe$ar extends Traductions$tc$bibliotheque$classe$fr {
	_Traductions$tc$bibliotheque$classe$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'اختيار مادة';
	@override String get sousTitre => 'المادة المختارة تحل محل المعروضة. يستمر الدرس.';
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

// Path: tc.groupe.mesGroupes
class _Traductions$tc$groupe$mesGroupes$ar extends Traductions$tc$groupe$mesGroupes$fr {
	_Traductions$tc$groupe$mesGroupes$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'فصولي';
	@override String get aucun => 'لا فصل حتى الآن';
	@override String get aucunDetail => 'ستضعك الأكاديمية في فصل حين يتوفر موعد يناسبك.';
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
	@override String ouvrir({required Object libelle}) => 'فتح الفصل ⁨${libelle}⁩';
	@override String capacite({required Object membres, required Object seuil}) => '⁨${membres}⁩ / ⁨${seuil}⁩';
	@override String capacitePhrase({required Object membres, required Object seuil}) => '⁨${membres}⁩ طلاب من ⁨${seuil}⁩ مقاعد';
	@override String get complet => 'مكتمل';
	@override String get prochainCours => 'الدرس القادم';
	@override String get aucuneSeance => 'لا حصة مقررة';
	@override String get aucuneSeanceDetail => 'لم يُحدَّد جدول هذا الفصل بعد.';
	@override String duree({required Object valeur}) => 'المدة ⁨${valeur}⁩';
	@override String get dureeLibelle => 'المدة';
	@override String get rejoindre => 'انضمام';
}

// Path: tc.groupe.cours
class _Traductions$tc$groupe$cours$ar extends Traductions$tc$groupe$cours$fr {
	_Traductions$tc$groupe$cours$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String coursEtNiveau({required Object cours, required Object niveau}) => '⁨${cours}⁩ · ⁨${niveau}⁩';
}

// Path: tc.groupe.temps
class _Traductions$tc$groupe$temps$ar extends Traductions$tc$groupe$temps$fr {
	_Traductions$tc$groupe$temps$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String dansMinutes({required Object minutes}) => 'الدرس بعد ⁨${minutes}⁩ دقيقة';
	@override String dansHeures({required Object heures, required Object minutes}) => 'الدرس بعد ⁨${heures}⁩ س ⁨${minutes}⁩ د';
	@override String get imminent => 'الدرس وشيك';
	@override String salleOuverte({required Object reste}) => 'القاعة مفتوحة · ⁨${reste}⁩';
	@override String get salleOuverteCourt => 'القاعة مفتوحة';
	@override String get attente => 'أنت في القاعة. لم يبدأ الدرس بعد.';
	@override String get attenteDetail => 'وقت الانتظار هذا لا يُحتسب في حضورك.';
	@override String get enSalle => 'في القاعة';
	@override String resteMinutes({required Object minutes}) => 'بقيت ⁨${minutes}⁩ دقيقة';
	@override String resteHeures({required Object heures, required Object minutes}) => 'بقي ⁨${heures}⁩ س ⁨${minutes}⁩ د';
	@override String enCours({required Object reste}) => 'حصة مباشرة · ⁨${reste}⁩';
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
	@override String minutes({required Object minutes}) => '⁨${minutes}⁩ د';
	@override String heures({required Object heures}) => '⁨${heures}⁩ س';
	@override String heuresMinutes({required Object heures, required Object minutes}) => '⁨${heures}⁩ س ⁨${minutes}⁩ د';
}

// Path: tc.groupe.horloges
class _Traductions$tc$groupe$horloges$ar extends Traductions$tc$groupe$horloges$fr {
	_Traductions$tc$groupe$horloges$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get votreHeure => 'توقيتك';
	@override String chezEnseignant({required Object nomme}) => 'عند ⁨${nomme}⁩';
	@override String get heureGroupe => 'توقيت الفصل';
	@override String heureEtVille({required Object heure, required Object ville}) => '⁨${heure}⁩ ⁨${ville}⁩';
}

// Path: tc.groupe.dst
class _Traductions$tc$groupe$dst$ar extends Traductions$tc$groupe$dst$fr {
	_Traductions$tc$groupe$dst$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get j30 => 'تغيير التوقيت بعد شهر';
	@override String get j7 => 'تغيير التوقيت الأسبوع القادم';
	@override String get j1 => 'تغيير التوقيت غدًا';
	@override String detail({required Object avant, required Object apres}) => 'سينتقل درسك من ⁨${avant}⁩ إلى ⁨${apres}⁩.';
}

// Path: tc.groupe.session
class _Traductions$tc$groupe$session$ar extends Traductions$tc$groupe$session$fr {
	_Traductions$tc$groupe$session$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get conseilAppareil => 'يُنصح بجهاز لوحي أو حاسوب للدرس. الهاتف مدعوم أيضًا.';
}

// Path: tc.groupe.espace
class _Traductions$tc$groupe$espace$ar extends Traductions$tc$groupe$espace$fr {
	_Traductions$tc$groupe$espace$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get retour => 'فصولي';
	@override String get avantProchainCours => 'قبل الدرس القادم';
	@override String get aucuneAction => 'لا شيء للتحضير الآن';
	@override String get bibliotheque => 'المكتبة';
	@override String get bibliothequeVoirTout => 'عرض الكل';
	@override String get progression => 'التقدم';
	@override String get roster => 'طلاب الفصل';
	@override String get reprendreLeCours => 'استئناف الدرس';
	@override String get introuvable => 'هذا الفصل غير مفتوح لك';
	@override String get introuvableDetail => 'ربما أُغلق، أو يخص ملفًا آخر.';
}

// Path: tc.groupe.emplacement
class _Traductions$tc$groupe$emplacement$ar extends Traductions$tc$groupe$emplacement$fr {
	_Traductions$tc$groupe$emplacement$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get nonBranche => 'قريبًا';
	@override String get nonBrancheDetail => 'سيُربط هذا المحتوى بهذه المساحة قريبًا.';
}

// Path: tc.coran.modes
class _Traductions$tc$coran$modes$ar extends Traductions$tc$coran$modes$fr {
	_Traductions$tc$coran$modes$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get mushaf => 'صفحة المصحف';
	@override String get verset => 'قراءة مكبَّرة';
	@override String get focus => 'التركيز';
	@override String get choisir => 'طريقة القراءة';
}

// Path: tc.coran.mushaf
class _Traductions$tc$coran$mushaf$ar extends Traductions$tc$coran$mushaf$fr {
	_Traductions$tc$coran$mushaf$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get coteDroite => 'الصفحة اليمنى';
	@override String get coteGauche => 'الصفحة اليسرى';
	@override String ouverture({required Object droite, required Object gauche}) => 'الصفحتان المفتوحتان ⁨${droite}⁩ و⁨${gauche}⁩';
}

// Path: tc.coran.fidelite
class _Traductions$tc$coran$fidelite$ar extends Traductions$tc$coran$fidelite$fr {
	_Traductions$tc$coran$fidelite$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get approchee => 'تنسيق تقريبي';
	@override String get approcheeDetail => 'آيات هذه الصفحة هي بالضبط آيات صفحة مصحف المدينة. أما توزيعها على الأسطر فهو توزيع هذه الشاشة: لم يُستورد بعد تقسيم الأسطر في الطبعة.';
	@override String get fidele => 'تنسيق الطبعة';
}

// Path: tc.coran.zoom
class _Traductions$tc$coran$zoom$ar extends Traductions$tc$coran$zoom$fr {
	_Traductions$tc$coran$zoom$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get bride => 'التكبير محدود بالعرض: بعده ستنقسم كلمة.';
	@override String valeur({required Object pourcent}) => '⁨${pourcent}⁩ %';
	@override String get renvoiLectureAgrandie => 'لتكبير النص، انتقل إلى القراءة المكبَّرة: صفحة المصحف تحافظ على هيئتها.';
}

// Path: tc.coran.navigation
class _Traductions$tc$coran$navigation$ar extends Traductions$tc$coran$navigation$fr {
	_Traductions$tc$coran$navigation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الانتقال إلى';
	@override String get ouvrir => 'الانتقال إلى صفحة';
	@override String get champ => 'صفحة أو سورة أو جزء أو مرجع';
	@override String get indice => 'مثلًا 18، الكهف، الجزء 15، 2:255';
	@override String get limite => 'يشمل البحث أرقام الصفحات والمراجع وأسماء السور. البحث في نص القرآن غير متاح بعد.';
	@override String get aucunResultat => 'لم يُعثر على مرجع';
	@override String get aucunResultatDetail => 'جرّب رقم صفحة، أو اسم سورة، أو مرجعًا مثل 2:255.';
	@override String pageNumero({required Object page}) => 'الصفحة ⁨${page}⁩';
}

// Path: tc.coran.reprise
class _Traductions$tc$coran$reprise$ar extends Traductions$tc$coran$reprise$fr {
	_Traductions$tc$coran$reprise$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get groupe => 'استئناف الدرس';
	@override String groupeDetail({required Object page}) => 'كان الفصل في الصفحة ⁨${page}⁩';
}

// Path: tc.coran.focus
class _Traductions$tc$coran$focus$ar extends Traductions$tc$coran$focus$fr {
	_Traductions$tc$coran$focus$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aucunePlage => 'لا مقطع مُبرَز';
	@override String get aucunePlageDetail => 'يتبع التركيز المقطع الذي يحدده المعلم. خارج الفصل، يتوسط الصفحة المفتوحة.';
	@override String get quitter => 'الخروج من التركيز';
}

// Path: tc.outils.dock
class _Traductions$tc$outils$dock$ar extends Traductions$tc$outils$dock$fr {
	_Traductions$tc$outils$dock$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الأدوات';
	@override String get deplacer => 'نقل الأدوات';
	@override late final _Traductions$tc$outils$dock$position$ar position = _Traductions$tc$outils$dock$position$ar._(_root);
	@override String get bibliotheque => 'المكتبة';
	@override String get focus => 'التركيز';
	@override String get marquer => 'تعليم';
	@override String get masquer => 'إخفاء';
	@override String get stylet => 'القلم';
	@override String get pointeur => 'المؤشر';
	@override String get revision => 'المراجعة';
}

// Path: tc.outils.intention
class _Traductions$tc$outils$intention$ar extends Traductions$tc$outils$intention$fr {
	_Traductions$tc$outils$intention$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aApprendre => 'للحفظ';
	@override String get aRevoir => 'للمراجعة';
	@override String get aRenforcer => 'للتثبيت';
	@override String get aEntretenir => 'للتعاهد';
	@override String get pourEvaluation => 'للتقييم';
}

// Path: tc.outils.trait
class _Traductions$tc$outils$trait$ar extends Traductions$tc$outils$trait$fr {
	_Traductions$tc$outils$trait$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get stylet => 'القلم';
	@override String get surligneur => 'تظليل';
	@override String get gomme => 'الممحاة';
	@override String get annuler => 'تراجع';
	@override String get plus => 'المزيد';
	@override String get ardoise => 'لوح الملاحظات، اختياري: يبقى الدرس مقروءًا دونه';
	@override String get effacerDernier => 'مسح آخر خط لي';
}

// Path: tc.outils.portee
class _Traductions$tc$outils$portee$ar extends Traductions$tc$outils$portee$fr {
	_Traductions$tc$outils$portee$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get temporaire => 'وقت الشرح';
	@override String get seance => 'حتى نهاية الدرس';
	@override String get enregistree => 'حفظ';
	@override String get aide => 'إلى متى نحتفظ بهذه الملاحظات؟';
}

// Path: tc.outils.marquer
class _Traductions$tc$outils$marquer$ar extends Traductions$tc$outils$marquer$fr {
	_Traductions$tc$outils$marquer$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'تعليم هذا المقطع';
	@override String get aide => 'اختر ما يحتاجه هذا المقطع.';
	@override String get retirer => 'إزالة العلامة';
}

// Path: tc.outils.revision
class _Traductions$tc$outils$revision$ar extends Traductions$tc$outils$revision$fr {
	_Traductions$tc$outils$revision$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'للتحضير';
	@override String get aide => 'يصبح المقطع المحدد عملًا للتحضير.';
	@override String get groupeEntier => 'الفصل كله';
	@override String get consigne => 'تعليمة قصيرة (اختياري)';
	@override String get creer => 'تكليف بالعمل';
	@override String get posee => 'تم التكليف بعمل للتحضير';
}

// Path: tc.outils.masquer
class _Traductions$tc$outils$masquer$ar extends Traductions$tc$outils$masquer$fr {
	_Traductions$tc$outils$masquer$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get reveler => 'إظهار';
	@override String get refermer => 'إخفاء من جديد';
	@override String get tout => 'إظهار الكل';
}

// Path: tc.outils.focus
class _Traductions$tc$outils$focus$ar extends Traductions$tc$outils$focus$fr {
	_Traductions$tc$outils$focus$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get quitter => 'الخروج من التركيز';
}

// Path: tc.outils.annotation
class _Traductions$tc$outils$annotation$ar extends Traductions$tc$outils$annotation$fr {
	_Traductions$tc$outils$annotation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get ancrageDegrade => 'لا مرجع نصيًا لهذا المقطع: ستتبع الملاحظة الصفحة لا الكلمات.';
	@override String get horsPage => 'الملاحظات مخفية: مقطعها ليس على الشاشة.';
	@override String get aucuneSelection => 'حدّد مقطعًا أولًا.';
}

// Path: tc.classe.entete
class _Traductions$tc$classe$entete$ar extends Traductions$tc$classe$entete$fr {
	_Traductions$tc$classe$entete$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tc$classe$entete$titreEnseignant$ar titreEnseignant = _Traductions$tc$classe$entete$titreEnseignant$ar._(_root);
	@override String resteMinutes({required Object minutes}) => 'بقيت ⁨${minutes}⁩ دقيقة';
	@override String resteHeuresMinutes({required Object heures, required Object minutes}) => 'بقي ⁨${heures}⁩ س ⁨${minutes}⁩ د';
	@override String get coursEnCours => 'الحصة ما زالت مباشرة';
	@override String get photoManquante => 'صورة المعلم غير موجودة';
}

// Path: tc.classe.roster
class _Traductions$tc$classe$roster$ar extends Traductions$tc$classe$roster$fr {
	_Traductions$tc$classe$roster$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الطلاب';
	@override String compteur({required Object presents, required Object attendus}) => 'الطلاب: ⁨${presents}⁩ حاضرون من ⁨${attendus}⁩ منتظَرين';
	@override String get indisponible => 'قائمة الطلاب غير متاحة';
	@override String get indisponibleDetail => 'تعذّرت قراءة حالات طلابك. يستمر الدرس.';
	@override String get vide => 'لا طالب مسجَّل';
	@override String get videDetail => 'لا طالب مسجَّل في هذه الحصة.';
	@override String ouvrirFiche({required Object prenom}) => 'فتح بطاقة ⁨${prenom}⁩';
	@override String places({required Object inscrits, required Object plafond}) => '⁨${inscrits}⁩ / ⁨${plafond}⁩ مقاعد';
}

// Path: tc.classe.etat
class _Traductions$tc$classe$etat$ar extends Traductions$tc$classe$etat$fr {
	_Traductions$tc$classe$etat$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get inconnu => 'حالة غير معروفة';
	@override String get attendu => 'منتظَر';
	@override String get enConnexion => 'جارٍ الاتصال';
	@override String get present => 'حاضر';
	@override String get enRetard => 'متأخر';
	@override String get deconnecte => 'غير متصل';
	@override String get enReconnexion => 'جارٍ إعادة الاتصال';
	@override String get sorti => 'خرج';
	@override String get absent => 'غائب';
}

// Path: tc.classe.fiche
class _Traductions$tc$classe$fiche$ar extends Traductions$tc$classe$fiche$fr {
	_Traductions$tc$classe$fiche$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get niveau => 'المستوى';
	@override String get objectif => 'الهدف الحالي';
	@override String get derniereSeance => 'آخر حصة';
	@override String page({required Object page}) => 'الصفحة ⁨${page}⁩';
	@override String travailEnCours({required Object nombre}) => '⁨${nombre}⁩ عنصر';
	@override String get aReprendre => 'للاستئناف';
	@override String get presenceRecente => 'الحضور الأخير';
	@override String assiduite({required Object presences, required Object total}) => '⁨${presences}⁩ / ⁨${total}⁩ دروس';
	@override String get travailActuel => 'العمل الحالي';
	@override String get interfaceGuidee => 'وضع إمكانية الوصول';
	@override String get sansPedagogie => 'المتابعة التعليمية غير متاحة';
	@override String get sansPedagogieDetail => 'المسار والأهداف والعمل الجاري غير مفتوحة للمعلم بعد.';
}

// Path: tc.classe.action
class _Traductions$tc$classe$action$ar extends Traductions$tc$classe$action$fr {
	_Traductions$tc$classe$action$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get rappel => 'نداء هادئ';
	@override String get reciter => 'اختيار للتلاوة';
	@override String get noter => 'تدوين ملاحظة';
	@override String get signaler => 'الإشارة إلى حاجة';
	@override String get contexte => 'فتح السياق';
}

// Path: tc.classe.rappel
class _Traductions$tc$classe$rappel$ar extends Traductions$tc$classe$rappel$fr {
	_Traductions$tc$classe$rappel$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get recu => 'المعلم يناديك';
	@override String get echec => 'تعذّر إرسال النداء';
	@override String get echecDroit => 'دخولك إلى هذه الحصة لا يسمح بنداء طالب';
	@override String cooldown({required Object secondes}) => 'تم النداء. مجددًا بعد ⁨${secondes}⁩ ث';
}

// Path: tc.classe.recitation
class _Traductions$tc$classe$recitation$ar extends Traductions$tc$classe$recitation$fr {
	_Traductions$tc$classe$recitation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'التلاوة';
	@override String actif({required Object prenom}) => '⁨${prenom}⁩ يتلو';
	@override String get pastille => 'يتلو';
	@override String get suivants => 'بعد ذلك';
	@override String get personne => 'لا أحد يتلو';
	@override String get arreter => 'إيقاف التلاوة';
}

// Path: tc.classe.support
class _Traductions$tc$classe$support$ar extends Traductions$tc$classe$support$fr {
	_Traductions$tc$classe$support$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get aucun => 'لا مادة معروضة';
	@override String get aucunDetail => 'افتح المكتبة لعرض مادة على الفصل.';
	@override String get bibliotheque => 'المكتبة';
	@override String get bibliothequeAbsente => 'المكتبة غير موصولة';
	@override String get bibliothequeAbsenteDetail => 'سيتاح اختيار المادة بمجرد دمج الفهرس.';
}

// Path: tc.classe.commandes
class _Traductions$tc$classe$commandes$ar extends Traductions$tc$classe$commandes$fr {
	_Traductions$tc$classe$commandes$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get micro => 'فتح الميكروفون';
	@override String get microFermer => 'إغلاق الميكروفون';
	@override String get camera => 'فتح الكاميرا';
	@override String get cameraFermer => 'إغلاق الكاميرا';
	@override String get microCoupe => 'الميكروفون مغلق';
	@override String get quitter => 'مغادرة';
	@override String get quitterQuestion => 'مغادرة الدرس؟';
	@override String get quitterConsequence => 'سيُسجَّل خروجك. يمكنك العودة ما دامت الحصة مفتوحة.';
	@override String get fermerBibliotheque => 'إغلاق المكتبة';
}

// Path: tc.classe.scene
class _Traductions$tc$classe$scene$ar extends Traductions$tc$classe$scene$fr {
	_Traductions$tc$classe$scene$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get vide => 'أنت وحدك في القاعة الآن';
	@override String get sansImage => 'دون صورة';
}

// Path: tc.classe.reseau
class _Traductions$tc$classe$reseau$ar extends Traductions$tc$classe$reseau$fr {
	_Traductions$tc$classe$reseau$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get bon => 'الشبكة جيدة';
	@override String get mediocre => 'الشبكة غير مستقرة';
	@override String get perdu => 'انقطعت الشبكة';
}

// Path: tc.classe.attente
class _Traductions$tc$classe$attente$ar extends Traductions$tc$classe$attente$fr {
	_Traductions$tc$classe$attente$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get materiel => 'جارٍ التحقق من الميكروفون';
	@override String get ouverture => 'جارٍ فتح الدرس';
	@override String get connexion => 'جارٍ الاتصال بالدرس';
	@override String get refus => 'الدرس غير متاح الآن';
}

// Path: tc.classe.lien
class _Traductions$tc$classe$lien$ar extends Traductions$tc$classe$lien$fr {
	_Traductions$tc$classe$lien$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get instable => 'الاتصال غير مستقر';
	@override String get reconnexion => 'جارٍ إعادة الاتصال';
	@override String get retabli => 'عاد الاتصال';
	@override String get echec => 'انقطع الاتصال';
	@override String get retourDeSuspension => 'أوقف النظام الدرس مؤقتًا. جارٍ التحقق من الاتصال.';
}

// Path: tc.classe.barre
class _Traductions$tc$classe$barre$ar extends Traductions$tc$classe$barre$fr {
	_Traductions$tc$classe$barre$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'حصة مباشرة';
	@override String revenir({required Object groupe}) => 'العودة إلى درس ⁨${groupe}⁩';
}

// Path: tc.classe.prevol
class _Traductions$tc$classe$prevol$ar extends Traductions$tc$classe$prevol$fr {
	_Traductions$tc$classe$prevol$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'قبل فتح الدرس';
	@override String get microOk => 'تم العثور على ميكروفون';
	@override String get microAbsent => 'لا ميكروفون صالح';
	@override String get cameraOk => 'تم العثور على كاميرا';
	@override String get cameraAbsente => 'لا كاميرا. يبقى الدرس ممكنًا.';
	@override String get permissionRefusee => 'رُفض الوصول إلى الميكروفون. اسمح به لفتح الدرس.';
	@override String get reessayer => 'التحقق من جديد';
}

// Path: tc.classe.observation
class _Traductions$tc$classe$observation$ar extends Traductions$tc$classe$observation$fr {
	_Traductions$tc$classe$observation$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String restant({required Object secondes}) => 'بقيت ⁨${secondes}⁩ ث';
}

// Path: tc.realtime.transport
class _Traductions$tc$realtime$transport$ar extends Traductions$tc$realtime$transport$fr {
	_Traductions$tc$realtime$transport$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get partage_indisponible => 'مشاركة المادة غير متاحة على هذا الخادم. يستمر الدرس، لكن الأجهزة الأخرى لن تتبع الصفحة.';
}

// Path: tc.realtime.etat
class _Traductions$tc$realtime$etat$ar extends Traductions$tc$realtime$etat$fr {
	_Traductions$tc$realtime$etat$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get restauration_impossible => 'تعذّر استرجاع المادة الجارية. اطلب من المعلم أن يعرضها من جديد.';
}

// Path: tc.observation.entree
class _Traductions$tc$observation$entree$ar extends Traductions$tc$observation$entree$fr {
	_Traductions$tc$observation$entree$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'متابعة الحصة';
	@override String get tuteurIntro => 'يمكنك مشاهدة درس طفلك لوقت قصير. يبقى الميكروفون والكاميرا مغلقين.';
	@override String get adminIntro => 'اختر طريقتك قبل الدخول. لن تتغير بعد ذلك.';
	@override String get controleurIntro => 'تدخل في متابعة غير مرئية. لا ميكروفون ولا كاميرا.';
	@override String get entrer => 'دخول';
	@override String get modeDiscret => 'المتابعة بهدوء';
	@override String get modeDiscretDetail => 'غير مرئي للمشاركين. دون ميكروفون ولا كاميرا، ودون إعلان.';
	@override String get modeVisible => 'الانضمام إلى الفصل';
	@override String get modeVisibleDetail => 'مرئي للجميع باسم إدارة Rewayah. الميكروفون والكاميرا مسموحان، ويُعلَن عن الدخول.';
	@override String get nomInstitutionnel => 'إدارة Rewayah';
	@override String get visiteJournalisee => 'زيارة مسجَّلة في السجل: الهوية، والحصة، والدخول، والخروج، والمدة.';
	@override String get roleSansObservation => 'حسابك لا يتابع الحصص.';
	@override String get retourClasse => 'العودة إلى الفصل';
}

// Path: tc.observation.explication
class _Traductions$tc$observation$explication$ar extends Traductions$tc$observation$explication$fr {
	_Traductions$tc$observation$explication$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'لمحة عن تعلّمه';
	@override String regleUne({required Object n, required Object duree}) => '⁨${n}⁩ زيارة مدتها ⁨${duree}⁩';
	@override String regle({required Object n, required Object duree}) => '⁨${n}⁩ زيارات مدة كل منها ⁨${duree}⁩';
	@override String get regleDetail => 'لكل حصة ولكل وليّ أمر، حتى لو كان عدة من أطفالك في الفصل.';
	@override String get ecoute => 'استمع إلى المعلم والطلاب';
	@override String get ecouteDetail => 'تسمع المعلم والطلاب الذين يتكلمون، ومنهم طفلك.';
	@override String get sansMedia => 'دون ميكروفون ولا كاميرا';
	@override String get sansMediaDetail => 'يبقى الميكروفون والكاميرا معطَّلين حتى لا يُقاطَع الفصل.';
	@override String get revenir => 'إن كان طالب آخر يتلو في زيارتك الأولى، يمكنك العودة لاحقًا للاستماع إلى طفلك.';
	@override String get ecourtee => 'الزيارة التي تُغادَر قبل نهايتها تُحتسب زيارة كاملة: الوقت غير المستخدم لا يُرحَّل.';
	@override String get sansIntervenir => 'حفاظًا على التركيز، تتابع دون أن تتدخل.';
	@override String get informes => 'طفلك ومعلمه على علم.';
	@override String get observer => 'المتابعة الآن';
	@override String get pasMaintenant => 'ليس الآن';
	@override String restanteUne({required Object restantes, required Object max}) => '⁨${restantes}⁩/⁨${max}⁩ زيارة متبقية لهذه الحصة';
	@override String restantes({required Object restantes, required Object max}) => '⁨${restantes}⁩/⁨${max}⁩ زيارات متبقية لهذه الحصة';
	@override String get aucuneRestante => 'لا زيارة متبقية لهذه الحصة';
}

// Path: tc.observation.disponibilite
class _Traductions$tc$observation$disponibilite$ar extends Traductions$tc$observation$disponibilite$fr {
	_Traductions$tc$observation$disponibilite$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get visitesEpuiseesTitre => 'لا زيارة متبقية لهذه الحصة';
	@override String get visitesEpuisees => 'استخدمت زياراتك. يمكنك متابعة الحصة القادمة.';
	@override String get tempsEpuiseTitre => 'انتهى وقت المتابعة';
	@override String get tempsEpuise => 'استُخدم وقت متابعتك لهذه الحصة. يمكنك متابعة الحصة القادمة.';
	@override String get seanceNonCommenceeTitre => 'لم تبدأ الحصة بعد';
	@override String get seanceNonCommencee => 'تُفتح المتابعة أثناء الحصة.';
	@override String get seanceTermineeTitre => 'انتهت الحصة';
	@override String get seanceTerminee => 'يمكنك متابعة الحصة القادمة.';
	@override String get seanceNonTenueTitre => 'هذه الحصة لا تُعقد';
	@override String get seanceNonTenue => 'أُلغيت أو أُجّلت أو لم تُعقد.';
	@override String get horsFenetreTitre => 'الحصة غير مفتوحة الآن';
	@override String get horsFenetre => 'المتابعة ممكنة أثناء الحصة فقط.';
	@override String get desactiveeTitre => 'المتابعة مغلقة لهذا الفصل';
	@override String get desactivee => 'أغلقت الإدارة متابعة هذا الفصل.';
	@override String get lienAbsentTitre => 'لا أحد من أطفالك في هذه الحصة';
	@override String get lienAbsent => 'المتابعة مخصصة لأولياء أمور طلاب الحصة.';
	@override String get enfantAbsentTitre => 'طفلك ليس في الحصة';
	@override String get enfantAbsent => 'تُفتح المتابعة حين يكون طفلك حاضرًا.';
	@override String get presenceTitre => 'جارٍ التحقق من الحضور';
	@override String get presence => 'تُفتح المتابعة بمجرد تأكيد حضور طفلك.';
	@override String get visiteOuverteTitre => 'زيارة مفتوحة بالفعل';
	@override String get visiteOuverte => 'إحدى زياراتك ما زالت مفتوحة لهذه الحصة، على هذا الجهاز أو على غيره. وهي تُحتسب من زياراتك.';
	@override String get fermeeTitre => 'المتابعة غير مفتوحة بعد';
	@override String get fermee => 'متابعة أولياء الأمور للحصص غير مفتوحة بعد. ستُقترح هنا بمجرد فتحها.';
	@override String get reseauTitre => 'تعذّر التحقق';
	@override String get reseau => 'تعذّر التحقق من توفر المتابعة. لم تبدأ أي زيارة.';
	@override String get capaciteTitre => 'المتابعة غير متاحة';
	@override String get capacite => 'المتابعة غير متاحة الآن.';
}

// Path: tc.observation.connexion
class _Traductions$tc$observation$connexion$ar extends Traductions$tc$observation$connexion$fr {
	_Traductions$tc$observation$connexion$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الاتصال والتحقق';
	@override String get phrase => 'يجري التحقق من زياراتك المتبقية. تبدأ الزيارة بمجرد قبول الدخول، بما في ذلك اتصال الفيديو.';
	@override String get enCours => 'جارٍ الاتصال والتحقق';
	@override String get prolongee => 'ابقَ على هذه الصفحة: التحقق مستمر.';
	@override String get impossibleTitre => 'تعذّر الاتصال';
	@override String get impossible => 'لم يتم الدخول إلى الحصة. تحقّق من اتصالك ثم أعد المحاولة: سيُعاد التحقق من زياراتك المتبقية.';
}

// Path: tc.observation.duree
class _Traductions$tc$observation$duree$ar extends Traductions$tc$observation$duree$fr {
	_Traductions$tc$observation$duree$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String secondeUne({required Object n}) => '⁨${n}⁩ ثانية';
	@override String secondes({required Object n}) => '⁨${n}⁩ ثوانٍ';
	@override String minuteUne({required Object n}) => '⁨${n}⁩ دقيقة';
	@override String minutes({required Object n}) => '⁨${n}⁩ دقائق';
	@override String minutesSecondes({required Object m, required Object s}) => '⁨${m}⁩ د ⁨${s}⁩ ث';
}

// Path: tc.observation.refus
class _Traductions$tc$observation$refus$ar extends Traductions$tc$observation$refus$fr {
	_Traductions$tc$observation$refus$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get politiqueDesactivee => 'المتابعة معطَّلة لهذا الفصل.';
	@override String get quotaVisites => 'استخدمت زياراتك لهذه الحصة بالفعل.';
	@override String get tempsEpuise => 'نفد وقت متابعتك لهذه الحصة.';
	@override String get lienTuteur => 'لست مرتبطًا بأي طالب في هذه الحصة.';
	@override String get seanceNonActive => 'الحصة ليست جارية.';
	@override String get horsFenetre => 'القاعة غير مفتوحة في هذا الوقت.';
	@override String get indisponible => 'المتابعة غير متاحة الآن.';
	@override String get capaciteAbsente => 'المتابعة غير مفعَّلة بعد في هذا التثبيت.';
}

// Path: tc.observation.visite
class _Traductions$tc$observation$visite$ar extends Traductions$tc$observation$visite$fr {
	_Traductions$tc$observation$visite$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'المتابعة جارية';
	@override String get quitter => 'مغادرة';
	@override String get supportIndisponible => 'تظهر هنا المادة التي يشاركها المعلم.';
	@override String get enseignant => 'المعلم';
	@override String get monEnfant => 'طفلك';
	@override String get budgetIncertain => 'الوقت المتبقي غير مؤكَّد من الخادم.';
	@override String get videoIndisponible => 'تعذّر فتح فيديو الحصة. يستمر احتساب وقت متابعتك.';
	@override String get sortieNonConfirmee => 'تعذّر تأكيد نهاية زيارتك. سيغلقها الخادم.';
	@override String get restantes => 'متبقية';
	@override String decompteLu({required Object duree}) => 'الوقت المتبقي: ⁨${duree}⁩';
	@override String get enDirect => 'مباشر';
	@override String get connexion => 'الاتصال';
	@override String get reconnexion => 'إعادة الاتصال';
	@override String get videoCoupee => 'الفيديو غير متاح';
	@override String get reconnexionDetail => 'انقطع الاتصال، جارٍ إعادة الاتصال. يستمر احتساب وقت متابعتك.';
	@override String get sonRecu => 'الصوت واصل';
	@override String get sonInterrompu => 'الصوت منقطع';
	@override String get agrandir => 'تكبير';
	@override String get reduire => 'تصغير';
	@override String get cameraFermee => 'الكاميرا مغلقة';
	@override String get pasEncoreLa => 'ليس في القاعة بعد';
	@override String parle({required Object nom}) => '⁨${nom}⁩ يتكلم';
	@override String get quitterQuestion => 'مغادرة الزيارة؟';
	@override String quitterConsequence({required Object duree}) => 'بقي لك ⁨${duree}⁩. الزيارة التي تُغادَر قبل نهايتها تُحتسب زيارة كاملة: الوقت غير المستخدم لا يُرحَّل.';
	@override String get quitterConsequenceSansTemps => 'الزيارة التي تُغادَر قبل نهايتها تُحتسب زيارة كاملة: الوقت غير المستخدم لا يُرحَّل.';
	@override String get quitterConfirmer => 'مغادرة الزيارة';
}

// Path: tc.observation.fin
class _Traductions$tc$observation$fin$ar extends Traductions$tc$observation$fin$fr {
	_Traductions$tc$observation$fin$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get sortieVolontaire => 'غادرت المتابعة.';
	@override String get quotaAtteint => 'انتهى وقت متابعتك.';
	@override String get seanceTerminee => 'انتهت الحصة.';
	@override String get revocationServeur => 'قُطعت متابعتك.';
	@override String get deconnexion => 'انقطع الاتصال.';
}

// Path: tc.observation.resultat
class _Traductions$tc$observation$resultat$ar extends Traductions$tc$observation$resultat$fr {
	_Traductions$tc$observation$resultat$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get premiereTerminee => 'انتهت زيارتك الأولى';
	@override String get derniereTerminee => 'انتهت زيارتك الأخيرة';
	@override String get terminee => 'انتهت زيارتك';
	@override String get dureeAtteinte => 'بلغت الزيارة مدتها';
	@override String get interrompue => 'قُطعت المتابعة';
	@override String continuePour({required Object prenom}) => 'تستمر الحصة لـ⁨${prenom}⁩.';
	@override String get continueSansPrenom => 'تستمر الحصة.';
	@override String resteUne({required Object duree}) => 'بقيت لك زيارة واحدة مدتها ⁨${duree}⁩. عد لاحقًا للاستماع إليه.';
	@override String restent({required Object n, required Object duree}) => 'بقيت لك ⁨${n}⁩ زيارات مدة كل منها ⁨${duree}⁩. عد لاحقًا للاستماع إليه.';
	@override String get resteUneSansDuree => 'بقيت لك زيارة واحدة. عد لاحقًا للاستماع إليه.';
	@override String restentSansDuree({required Object n}) => 'بقيت لك ⁨${n}⁩ زيارات. عد لاحقًا للاستماع إليه.';
	@override String get aucune => 'استخدمت زياراتك لهذه الحصة. يمكنك متابعة الحصة القادمة.';
	@override String get prochaineSeance => 'يمكنك متابعة الحصة القادمة.';
	@override String get verification => 'جارٍ التحقق من زياراتك المتبقية';
	@override String get inconnues => 'تعذّر التحقق من زياراتك المتبقية. سيُعاد التحقق منها في الفصل.';
	@override String get voirObservations => 'عرض متابعاتي';
}

// Path: tc.observation.annonce
class _Traductions$tc$observation$annonce$ar extends Traductions$tc$observation$annonce$fr {
	_Traductions$tc$observation$annonce$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String tuteurObserve({required Object prenomEnfant}) => 'وليّ أمر ⁨${prenomEnfant}⁩ يتابع';
	@override String restant({required Object secondes}) => '⁨${secondes}⁩ ث';
	@override String get enfantIndicateur => 'وليّ أمرك يشاهد الدرس';
	@override String tuteursObservent({required Object nombre}) => '⁨${nombre}⁩ من أولياء الأمور يتابعون';
}

// Path: tc.observation.reglages
class _Traductions$tc$observation$reglages$ar extends Traductions$tc$observation$reglages$fr {
	_Traductions$tc$observation$reglages$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'متابعة أولياء الأمور';
	@override String get intro => 'يمكن لوليّ الأمر مشاهدة درس طفله لوقت قصير، دون ميكروفون ولا كاميرا. يحدد هذا الإعداد ما ينطبق على هذا الفصل.';
	@override String get heriter => 'اتباع إعداد الأكاديمية';
	@override String get personnaliser => 'تخصيص لهذا الفصل';
	@override String get desactiver => 'تعطيل لهذا الفصل';
	@override String get maxVisites => 'الزيارات لكل حصة';
	@override String get tempsTotal => 'الوقت الكلي لكل حصة';
	@override String get plafondVisite => 'أقصى مدة للزيارة';
	@override String get diminuer => 'إنقاص';
	@override String get augmenter => 'زيادة';
	@override String get enregistrer => 'حفظ';
	@override String get invalideVisites => 'زيارة واحدة على الأقل لكل حصة.';
	@override String get invalideTemps => 'ثلاثون ثانية على الأقل لكل حصة.';
	@override String valeurHeritee({required Object valeur}) => 'الأكاديمية: ⁨${valeur}⁩';
	@override String uniteVisiteUne({required Object n}) => '⁨${n}⁩ زيارة';
	@override String uniteVisites({required Object n}) => '⁨${n}⁩ زيارات';
	@override String uniteSecondes({required Object n}) => '⁨${n}⁩ ث';
	@override String versionPolitique({required Object version}) => 'الإصدار ⁨${version}⁩';
}

// Path: tc.parcours.avant
class _Traductions$tc$parcours$avant$ar extends Traductions$tc$parcours$avant$fr {
	_Traductions$tc$parcours$avant$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'قبل الدرس القادم';
	@override String get rien => 'لا شيء للتحضير للدرس القادم.';
	@override String get rienDetail => 'سيقترح معلمك العمل في نهاية الحصة القادمة.';
	@override String get nonBranche => 'العمل المطلوب تحضيره غير مربوط بهذه المساحة بعد.';
	@override String get nonBrancheDetail => 'هذا لا يعني أنه لا شيء للتحضير: هذه الشاشة لا تعرف قراءته بعد.';
	@override String get reprendre => 'استئناف الدرس';
	@override String reprendreDepuis({required Object position}) => 'استئناف الدرس من ⁨${position}⁩';
}

// Path: tc.parcours.intention
class _Traductions$tc$parcours$intention$ar extends Traductions$tc$parcours$intention$fr {
	_Traductions$tc$parcours$intention$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get apprendre => 'للحفظ';
	@override String get revoir => 'للمراجعة';
	@override String get renforcer => 'للتثبيت';
	@override String get entretenir => 'للتعاهد';
	@override String get evaluation => 'للتقييم';
}

// Path: tc.parcours.plage
class _Traductions$tc$parcours$plage$ar extends Traductions$tc$parcours$plage$fr {
	_Traductions$tc$parcours$plage$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String versets({required Object sourate, required Object premier, required Object dernier}) => 'سورة ⁨${sourate}⁩، الآيات ⁨${premier}⁩ إلى ⁨${dernier}⁩';
	@override String versetUnique({required Object sourate, required Object premier}) => 'سورة ⁨${sourate}⁩، الآية ⁨${premier}⁩';
	@override String versetsCroisee({required Object sourateDebut, required Object versetDebut, required Object sourateFin, required Object versetFin}) => 'سورة ⁨${sourateDebut}⁩، الآية ⁨${versetDebut}⁩ إلى سورة ⁨${sourateFin}⁩، الآية ⁨${versetFin}⁩';
	@override String pages({required Object premiere, required Object derniere}) => 'الصفحات ⁨${premiere}⁩ إلى ⁨${derniere}⁩';
	@override String pageUnique({required Object premiere}) => 'الصفحة ⁨${premiere}⁩';
	@override String section({required Object section}) => 'القسم ⁨${section}⁩';
	@override String get ressource => 'المادة كلها';
}

// Path: tc.parcours.feedback
class _Traductions$tc$parcours$feedback$ar extends Traductions$tc$parcours$feedback$fr {
	_Traductions$tc$parcours$feedback$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override late final _Traductions$tc$parcours$feedback$cours$ar cours = _Traductions$tc$parcours$feedback$cours$ar._(_root);
	@override late final _Traductions$tc$parcours$feedback$comprehension$ar comprehension = _Traductions$tc$parcours$feedback$comprehension$ar._(_root);
	@override late final _Traductions$tc$parcours$feedback$rythme$ar rythme = _Traductions$tc$parcours$feedback$rythme$ar._(_root);
	@override late final _Traductions$tc$parcours$feedback$technique$ar technique = _Traductions$tc$parcours$feedback$technique$ar._(_root);
	@override late final _Traductions$tc$parcours$feedback$confiance$ar confiance = _Traductions$tc$parcours$feedback$confiance$ar._(_root);
	@override String get merci => 'شكرًا.';
	@override late final _Traductions$tc$parcours$feedback$tendance$ar tendance = _Traductions$tc$parcours$feedback$tendance$ar._(_root);
}

// Path: tc.parcours.signalement
class _Traductions$tc$parcours$signalement$ar extends Traductions$tc$parcours$signalement$fr {
	_Traductions$tc$parcours$signalement$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'الإشارة إلى حاجة';
	@override String get categorie => 'بماذا يتعلق الأمر؟';
	@override late final _Traductions$tc$parcours$signalement$categorieValeur$ar categorieValeur = _Traductions$tc$parcours$signalement$categorieValeur$ar._(_root);
	@override String get interne => 'ملاحظة داخلية';
	@override String get interneAide => 'تقرؤها الإدارة وحدها. لا تُرسل أبدًا تلقائيًا إلى الأسرة.';
	@override String get famille => 'رسالة إلى الأسرة';
	@override String get familleAide => 'اختيارية. الإدارة وحدها تقرر إرسالها بنقرة واحدة.';
	@override String contexte({required Object eleve}) => 'الطالب ⁨${eleve}⁩. الحصة والفصل واسمك مرفقة بالفعل.';
	@override String get envoyer => 'إرسال الإشارة';
	@override String get envoye => 'أُرسلت الإشارة إلى الإدارة.';
	@override String get interneRequis => 'اكتب على الأقل ما يجب أن تعرفه الإدارة.';
	@override String get echec => 'تعذّر إرسال الإشارة. أعد المحاولة.';
}

// Path: tc.parcours.postCours
class _Traductions$tc$parcours$postCours$ar extends Traductions$tc$parcours$postCours$fr {
	_Traductions$tc$parcours$postCours$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'بعد الدرس';
	@override String duree({required Object minutes}) => 'المدة الفعلية ⁨${minutes}⁩ دقيقة';
	@override String get exceptions => 'للتأكيد';
	@override String get toutEstNominal => 'لا شيء يتطلب انتباهك.';
	@override String get reprise => 'الاستئناف المقترح';
	@override String get repriseInconnue => 'لا موضع استئناف معروف لهذه الحصة.';
	@override String get travail => 'العمل المقترح';
	@override String get travailAucun => 'لا عمل مقترح حتى الآن.';
	@override String get valider => 'تأكيد';
	@override String get enFile => 'تم الحفظ. سيُرسل بمجرد عودة الشبكة.';
	@override String get envoye => 'أُغلق الدرس.';
}

// Path: salle.preparation.eleve.guidee
class _Traductions$salle$preparation$eleve$guidee$ar extends Traductions$salle$preparation$eleve$guidee$fr {
	_Traductions$salle$preparation$eleve$guidee$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get verification => 'جارٍ تحضير الحصة…';
	@override String get pret => 'كل شيء جاهز.';
	@override String get microCoupe => 'سيكون الميكروفون مغلقًا عند الدخول.';
	@override String get microQuestion => 'الميكروفون محظور. هل نسمح به؟';
	@override String get microBloque => 'الميكروفون محظور.';
	@override String get horsLigne => 'الاتصال لا يعمل الآن.';
}

// Path: salle.preparation.eleve.demo
class _Traductions$salle$preparation$eleve$demo$ar extends Traductions$salle$preparation$eleve$demo$fr {
	_Traductions$salle$preparation$eleve$demo$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get section => 'استعداد الطالب';
	@override String get sectionGuidee => 'استعداد الطالب، وضع إمكانية الوصول';
	@override String get verification => 'التحقق جارٍ';
	@override String get pret => 'جاهز';
	@override String get microBloque => 'الميكروفون محظور';
	@override String get horsLigne => 'غير متصل';
}

// Path: salle.seance.demo.groupes
class _Traductions$salle$seance$demo$groupes$ar extends Traductions$salle$seance$demo$groupes$fr {
	_Traductions$salle$seance$demo$groupes$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get seance => 'مجرى الحصة';
	@override String get secours => 'حالات الطوارئ';
	@override String get tableau => 'المواد والسبورة';
}

// Path: salle.seance.demo.roles
class _Traductions$salle$seance$demo$roles$ar extends Traductions$salle$seance$demo$roles$fr {
	_Traductions$salle$seance$demo$roles$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get eleve => 'طالب عادي';
	@override String get guidee => 'وضع إمكانية الوصول';
	@override String get enseignant => 'المعلم';
}

// Path: salle.seance.demo.etats
class _Traductions$salle$seance$demo$etats$ar extends Traductions$salle$seance$demo$etats$fr {
	_Traductions$salle$seance$demo$etats$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get repos => 'سكون';
	@override String get visite => 'زيارة';
	@override String get rienPartage => 'لا شيء مُشارَك';
	@override String get appel => 'النداء بهدوء';
	@override String get eleves => 'لوحة الطلاب';
	@override String get supports => 'لوحة المواد';
	@override String get fin => 'نهاية الحصة';
	@override String get reseauFaible => 'شبكة ضعيفة';
	@override String get reconnexion => 'إعادة الاتصال';
	@override String get retablie => 'عاد الاتصال';
	@override String get echec => 'تعذّرت إعادة الاتصال';
	@override String get horsLigne => 'غير متصل';
	@override String get microBloque => 'الميكروفون محظور';
	@override String get cameraInterdite => 'الكاميرا ممنوعة';
	@override String get prolongee => 'حصة ممدَّدة';
	@override String get accesRetire => 'سُحب الدخول';
}

// Path: salle.seance.demo.tb
class _Traductions$salle$seance$demo$tb$ar extends Traductions$salle$seance$demo$tb$fr {
	_Traductions$salle$seance$demo$tb$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get sal00 => 'SAL-00 القاعة والأشخاص';
	@override String get ped01 => 'PED-01 سبورة حرة، دون مادة';
	@override String get ped02 => 'PED-02 المادة وحدها';
	@override String get ped03 => 'PED-03 المادة مع الملاحظات';
	@override String get ped04 => 'PED-04 السبورة، المادة مخفية';
	@override String get ui01 => 'UI-01 عرض مضغوط';
	@override String get ui02 => 'UI-02 قاعة موسَّعة';
	@override String get ui03 => 'UI-03 تركيز محلي';
	@override String get vis01 => 'VIS-01 شريط الفيديو ظاهر';
	@override String get ctx01 => 'CTX-01 سياق الحصة';
	@override String get ctx02 => 'CTX-02 معلومات المراقبة';
	@override String get cmd01 => 'CMD-01 الأوامر';
	@override String get cmd02 => 'CMD-02 اللون والسُّمك';
	@override String get cmd03 => 'CMD-03 الكتابة جارية';
	@override String get lib01 => 'LIB-01 المكتبة';
	@override String get lib02 => 'LIB-02 معاينة خاصة';
	@override String get lib03 => 'LIB-03 فتح المادة';
	@override String get lib04 => 'LIB-04 بحث دون نتيجة';
	@override String get per01 => 'PER-01 المشاركون والأذونات';
	@override String get dlg01 => 'DLG-01 مسح ملاحظات الصفحة';
	@override String get err01 => 'ERR-01 انقطعت المزامنة';
	@override String get err02 => 'ERR-02 استعادة السبورة';
	@override String get err03 => 'ERR-03 فشل الحفظ';
	@override String get end01 => 'END-01 مغادرة الحصة';
	@override String get supportArrive => 'المادة في الطريق';
	@override String get ressourceIndisponible => 'المورد غير متاح';
	@override String get autorisationEcrire => 'إذن بالكتابة';
	@override String get droitRetire => 'سُحب الإذن';
	@override String get effacementTableau => 'مسح ملاحظات السبورة';
}

// Path: enseignant.journee.absence.etats
class _Traductions$enseignant$journee$absence$etats$ar extends Traductions$enseignant$journee$absence$etats$fr {
	_Traductions$enseignant$journee$absence$etats$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get enregistree => 'سُجِّل الغياب';
	@override String get recherche => 'جارٍ البحث عن بديل';
	@override String get remplacantConfirme => 'البديل مؤكَّد';
	@override String get aucunRemplacant => 'لا بديل مؤكَّد';
	@override String get seanceAnnulee => 'أُلغيت الحصة';
	@override String get demandeAnnulee => 'أُلغي الطلب';
}

// Path: tc.outils.dock.position
class _Traductions$tc$outils$dock$position$ar extends Traductions$tc$outils$dock$position$fr {
	_Traductions$tc$outils$dock$position$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get bas => 'في الأسفل';
	@override String get gauche => 'على اليسار';
	@override String get droite => 'على اليمين';
}

// Path: tc.classe.entete.titreEnseignant
class _Traductions$tc$classe$entete$titreEnseignant$ar extends Traductions$tc$classe$entete$titreEnseignant$fr {
	_Traductions$tc$classe$entete$titreEnseignant$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get sayyid => 'سيد';
	@override String get sayyida => 'سيدة';
}

// Path: tc.parcours.feedback.cours
class _Traductions$tc$parcours$feedback$cours$ar extends Traductions$tc$parcours$feedback$cours$fr {
	_Traductions$tc$parcours$feedback$cours$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get intitule => 'كيف كان الدرس اليوم؟';
	@override String get difficile => 'صعب';
	@override String get bien => 'جيد';
	@override String get tresBien => 'جيد جدًا';
}

// Path: tc.parcours.feedback.comprehension
class _Traductions$tc$parcours$feedback$comprehension$ar extends Traductions$tc$parcours$feedback$comprehension$fr {
	_Traductions$tc$parcours$feedback$comprehension$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get intitule => 'هل فهمت ما تم العمل عليه؟';
	@override String get difficile => 'ليس تمامًا';
	@override String get bien => 'نعم تقريبًا';
	@override String get tresBien => 'تمامًا';
}

// Path: tc.parcours.feedback.rythme
class _Traductions$tc$parcours$feedback$rythme$ar extends Traductions$tc$parcours$feedback$rythme$fr {
	_Traductions$tc$parcours$feedback$rythme$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get intitule => 'هل ناسبك إيقاع الدرس؟';
	@override String get difficile => 'سريع جدًا';
	@override String get bien => 'مناسب';
	@override String get tresBien => 'مريح جدًا';
}

// Path: tc.parcours.feedback.technique
class _Traductions$tc$parcours$feedback$technique$ar extends Traductions$tc$parcours$feedback$technique$fr {
	_Traductions$tc$parcours$feedback$technique$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get intitule => 'هل كان الصوت والصورة مريحين؟';
	@override String get difficile => 'مزعجان';
	@override String get bien => 'مقبولان';
	@override String get tresBien => 'جيدان جدًا';
}

// Path: tc.parcours.feedback.confiance
class _Traductions$tc$parcours$feedback$confiance$ar extends Traductions$tc$parcours$feedback$confiance$fr {
	_Traductions$tc$parcours$feedback$confiance$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get intitule => 'هل تشعر أنك مستعد للدرس القادم؟';
	@override String get difficile => 'ليس بعد';
	@override String get bien => 'تقريبًا';
	@override String get tresBien => 'تمامًا';
}

// Path: tc.parcours.feedback.tendance
class _Traductions$tc$parcours$feedback$tendance$ar extends Traductions$tc$parcours$feedback$tendance$fr {
	_Traductions$tc$parcours$feedback$tendance$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get titre => 'آراء الطلاب';
	@override String get sousSeuil => 'لا تكفي الآراء بعد لاستخلاص اتجاه.';
	@override String get anonyme => 'الآراء مجهولة الهوية ومجمَّعة. لا تكفي وحدها أبدًا لاتخاذ قرار.';
}

// Path: tc.parcours.signalement.categorieValeur
class _Traductions$tc$parcours$signalement$categorieValeur$ar extends Traductions$tc$parcours$signalement$categorieValeur$fr {
	_Traductions$tc$parcours$signalement$categorieValeur$ar._(TraductionsAr root) : this._root = root, super.internal(root);

	final TraductionsAr _root; // ignore: unused_field

	// Translations
	@override String get pedagogique => 'تعليمي';
	@override String get presence => 'الحضور';
	@override String get technique => 'تقني';
	@override String get changement => 'تغيير';
	@override String get autre => 'آخر';
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
			'commun.marque' => 'Rewayah Academy',
			'commun.continuer' => 'متابعة',
			'commun.retour' => 'رجوع',
			'commun.valider' => 'تأكيد',
			'commun.annuler' => 'إلغاء',
			'commun.fermer' => 'إغلاق',
			'commun.reessayer' => 'إعادة المحاولة',
			'commun.chargement' => 'جارٍ التحميل',
			'commun.demonstration.repere' => 'عرض تجريبي',
			'commun.demonstration.repereLu' => 'وضع العرض التجريبي',
			'commun.etape.sur' => ({required Object n, required Object total}) => '⁨${n}⁩ من ⁨${total}⁩',
			'commun.etape.surLue' => ({required Object n, required Object total}) => 'الخطوة ⁨${n}⁩ من ⁨${total}⁩',
			'commun.choix.indisponible' => 'غير متاح',
			'commun.etats.chargementProlonge.titre' => 'الاتصال يستغرق وقتًا أطول من المتوقع',
			'commun.etats.chargementProlonge.phrase' => 'يمكنك الانتظار قليلًا أو إعادة المحاولة.',
			'commun.etats.horsLigne.titre' => 'أنت غير متصل',
			'commun.etats.horsLigne.phrase' => 'تحقّق من اتصالك. ما هو معروض يبقى قابلًا للاطلاع.',
			'commun.etats.reconnexion.titre' => 'جارٍ إعادة الاتصال',
			'commun.etats.reconnexion.phrase' => 'محاولة اتصال جديدة جارية.',
			'commun.etats.echecServeur.titre' => 'تعذّر تحميل هذه المعلومات',
			'commun.etats.echecServeur.phrase' => 'لم يكتمل التحميل. أعد المحاولة بعد لحظة.',
			'commun.etats.introuvable.titre' => 'هذه الصفحة غير موجودة',
			'commun.etats.introuvable.phrase' => 'ربما الرابط ناقص، أو لم تعد الصفحة موجودة.',
			'commun.etats.accesRefuse.titre' => 'ليس لديك إذن بالوصول إلى هذه الصفحة',
			'commun.etats.accesRefuse.phrase' => 'هذا المحتوى غير مفتوح لحسابك.',
			'commun.etats.sessionExpiree.titre' => 'انتهت جلستك',
			'commun.etats.sessionExpiree.phrase' => 'سجّل الدخول من جديد للمتابعة.',
			'commun.etats.dossierEnAttente.titre' => 'ملفك قيد الانتظار',
			'commun.etats.dossierEnAttente.phrase' => 'بقيت خطوة قبل فتح هذه المساحة.',
			'commun.etats.aucunResultat.titre' => 'لا نتائج',
			'commun.etats.aucunResultat.phrase' => 'لا شيء مطابق الآن.',
			'commun.etats.permissionRefusee.titre' => 'الإذن مرفوض',
			'commun.etats.permissionRefusee.phrase' => 'دون هذا الإذن، لا يمكن فتح هذه الوظيفة. يمكنك تغييره في إعدادات جهازك.',
			'commun.etats.ressourceExpiree.titre' => 'هذا المحتوى لم يعد متاحًا',
			'commun.etats.ressourceExpiree.phrase' => 'سُحب، أو انتهى الوصول إليه.',
			'commun.etats.indisponible.titre' => 'غير متاح بعد',
			'commun.etats.indisponible.phrase' => 'هذه الوظيفة غير مفتوحة بعد.',
			'commun.etats.reessaisEpuises' => 'ما زال لا رد. أعد المحاولة لاحقًا.',
			'commun.etats.horsLigneDemarrage' => 'يحتاج Rewayah إلى الإنترنت للتحقق من حسابك. أعد توصيل هذا الجهاز، ثم أعد المحاولة.',
			'commun.etats.actions.reessayer' => 'إعادة المحاولة',
			'commun.etats.actions.retourAccueil' => 'العودة إلى الرئيسية',
			'commun.etats.actions.seConnecter' => 'تسجيل الدخول',
			'commun.etats.actions.seReconnecter' => 'تسجيل الدخول من جديد',
			'commun.etats.actions.voirDossier' => 'عرض ملفي',
			'commun.etats.actions.reinitialiserFiltres' => 'إعادة ضبط عوامل التصفية',
			'commun.etats.actions.revenir' => 'الرجوع',
			'commun.entete.retour' => 'رجوع',
			'commun.entete.notifications' => 'الإشعارات',
			'commun.entete.notificationsUneNonLue' => 'الإشعارات، واحد غير مقروء',
			'commun.entete.notificationsNonLues' => ({required Object nombre}) => 'الإشعارات، ⁨${nombre}⁩ غير مقروءة',
			'commun.selecteurProfils.etiquette' => ({required Object prenom, required Object etat}) => '⁨${prenom}⁩، ⁨${etat}⁩',
			'commun.selecteurProfils.ajouter' => 'إضافة',
			'commun.selecteurProfils.ajouterSemantique' => 'إضافة ملف طالب',
			'commun.theme.groupe' => 'المظهر',
			'commun.theme.clair' => 'المظهر الفاتح',
			'commun.theme.sombre' => 'المظهر الداكن',
			'commun.demarrage.ouverture' => 'جارٍ فتح Rewayah',
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
			'commun.dates.jourDate' => ({required Object jour, required Object numero, required Object mois}) => '⁨${jour}⁩ ⁨${numero}⁩ ⁨${mois}⁩',
			'etat.enDirect' => 'مباشر',
			'etat.seanceAnnulee' => 'ملغاة',
			'etat.annuleeValeur' => ({required Object valeur}) => 'ملغاة : ${valeur}',
			'etat.motifNonCommunique' => 'السبب غير متوفر',
			'etat.aucunRemplacantTrouve' => 'لم يُعثر على بديل',
			'etat.seanceNonFacturee' => 'الحصة غير مفوترة',
			'etat.raisonEtSuite' => ({required Object raison, required Object suite}) => '${raison} · ${suite}',
			'etat.imminent' => 'قريبًا جدًا',
			'etat.annule' => 'ملغى',
			'etat.enAttente' => 'قيد الانتظار',
			'etat.enRetard' => 'متأخر',
			'etat.termine' => 'منتهٍ',
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
			'salle.preparation.titre' => 'الاستعداد لدخول الفصل',
			'salle.preparation.retour' => 'العودة إلى الفصل',
			'salle.preparation.cameraCoupee' => 'الكاميرا مطفأة',
			'salle.preparation.testerCamera' => 'اختبار الكاميرا',
			'salle.preparation.testCameraFait' => 'انتهى الاختبار المحلي. تبقى الكاميرا مطفأة عند الدخول.',
			'salle.preparation.equipement' => 'أجهزتك',
			'salle.preparation.connexion' => 'الاتصال',
			'salle.preparation.micro' => 'الميكروفون',
			'salle.preparation.sortieAudio' => 'مخرج الصوت',
			'salle.preparation.camera' => 'الكاميرا',
			'salle.preparation.verification' => 'جارٍ التحقق…',
			'salle.preparation.chargement' => 'جارٍ التحقق من الأجهزة…',
			'salle.preparation.connexionPrete' => 'الاتصال جاهز',
			'salle.preparation.connexionInstable' => 'الاتصال غير مستقر',
			'salle.preparation.reseauFaible' => 'الاتصال غير مستقر. الأولوية للصوت.',
			'salle.preparation.microPret' => 'تم العثور على ميكروفون · الميكروفون مغلق عند الدخول',
			'salle.preparation.microAbsent' => 'لم يُعثر على ميكروفون',
			'salle.preparation.microAbsentRaison' => 'لم يُعثر على ميكروفون. وصّل ميكروفونًا أو فعّله لتتمكن من التدريس.',
			'salle.preparation.microBloque' => 'الميكروفون محظور',
			'salle.preparation.permissionRefusee' => 'الميكروفون محظور في إعدادات هذا الجهاز.',
			'salle.preparation.ouvrirReglages' => 'فتح الإعدادات',
			'salle.preparation.reessayer' => 'إعادة المحاولة',
			'salle.preparation.sortieSysteme' => 'مخرج النظام',
			'salle.preparation.cameraPrete' => 'تم العثور على كاميرا · الكاميرا مطفأة عند الدخول',
			'salle.preparation.cameraAbsente' => 'الكاميرا غير متاحة. يمكنك الدخول دون كاميرا.',
			'salle.preparation.modifierPeripheriques' => 'تغيير الأجهزة',
			'salle.preparation.contexte' => 'سياق الحصة',
			'salle.preparation.classe' => 'الفصل',
			'salle.preparation.debut' => 'البداية',
			'salle.preparation.support' => 'المادة المقررة',
			'salle.preparation.reprise' => 'الاستئناف',
			'salle.preparation.eleves' => 'الطلاب المنتظرون',
			'salle.preparation.entrer' => 'دخول الفصل',
			'salle.preparation.terminee' => 'انتهت هذه الحصة.',
			'salle.preparation.nonAssignee' => 'هذه الحصة غير مسندة إليك.',
			'salle.preparation.retourJournee' => 'العودة إلى يومي',
			'salle.preparation.demo.section' => 'استعداد المعلم',
			'salle.preparation.demo.pret' => 'جاهز',
			'salle.preparation.demo.reseauFaible' => 'شبكة ضعيفة',
			'salle.preparation.demo.microAbsent' => 'لا يوجد ميكروفون',
			'salle.preparation.demo.permissionRefusee' => 'الإذن مرفوض',
			'salle.preparation.eleve.verification' => 'نتحقق من جهازك…',
			'salle.preparation.eleve.pret' => 'كل شيء جاهز',
			'salle.preparation.eleve.audio' => 'الصوت',
			'salle.preparation.eleve.acces' => 'الدخول إلى الفصل',
			'salle.preparation.eleve.accesOk' => 'يمكنك الدخول',
			'salle.preparation.eleve.accesAttente' => 'في انتظار الاتصال',
			'salle.preparation.eleve.microCoupe' => 'ستدخل والميكروفون مغلق.',
			'salle.preparation.eleve.microInaccessible' => 'لا يمكن الوصول إلى الميكروفون',
			'salle.preparation.eleve.microInaccessibleDetail' => 'لن يسمعك أحد في الفصل ما دام الوصول إلى الميكروفون محظورًا.',
			'salle.preparation.eleve.autoriserMicro' => 'السماح بالميكروفون',
			'salle.preparation.eleve.guidee.verification' => 'جارٍ تحضير الحصة…',
			'salle.preparation.eleve.guidee.pret' => 'كل شيء جاهز.',
			'salle.preparation.eleve.guidee.microCoupe' => 'سيكون الميكروفون مغلقًا عند الدخول.',
			'salle.preparation.eleve.guidee.microQuestion' => 'الميكروفون محظور. هل نسمح به؟',
			'salle.preparation.eleve.guidee.microBloque' => 'الميكروفون محظور.',
			'salle.preparation.eleve.guidee.horsLigne' => 'الاتصال لا يعمل الآن.',
			'salle.preparation.eleve.demo.section' => 'استعداد الطالب',
			'salle.preparation.eleve.demo.sectionGuidee' => 'استعداد الطالب، وضع إمكانية الوصول',
			'salle.preparation.eleve.demo.verification' => 'التحقق جارٍ',
			'salle.preparation.eleve.demo.pret' => 'جاهز',
			'salle.preparation.eleve.demo.microBloque' => 'الميكروفون محظور',
			'salle.preparation.eleve.demo.horsLigne' => 'غير متصل',
			'salle.bandeauPermanent' => 'الدرس مسجَّل، وزيارة مراقبة ممكنة.',
			'salle.seance.titre' => 'حصة مباشرة',
			'salle.seance.titreGuidee' => 'حصتي',
			'salle.seance.ligne' => ({required Object debut, required Object fin}) => '⁨${debut}⁩ · ⁨${fin}⁩',
			'salle.seance.minutesRestantes' => ({required Object minutes}) => 'بقيت ⁨${minutes}⁩ دقيقة',
			'salle.seance.sePoursuit' => 'الحصة مستمرة.',
			'salle.seance.enLigne' => 'متصل',
			'salle.seance.reconnexion' => 'إعادة الاتصال',
			'salle.seance.coursEnregistreCourt' => 'الدرس مسجَّل.',
			'salle.seance.votreParentObserve' => 'وليّ أمرك يتابع الحصة.',
			'salle.seance.tonParentObserve' => 'وليّ أمرك يتابع الحصة.',
			'salle.seance.tuteurDeObserve' => ({required Object prenom}) => 'وليّ أمر ⁨${prenom}⁩ يتابع.',
			'salle.seance.unParentObserve' => 'وليّ أمر يتابع هذه الحصة',
			'salle.seance.leTuteurDeObserve' => ({required Object prenom}) => 'وليّ أمر ⁨${prenom}⁩ يتابع الحصة.',
			'salle.seance.mentionEtNotice' => ({required Object mention, required Object notice}) => '⁨${mention}⁩ ⁨${notice}⁩',
			'salle.seance.retour' => 'رجوع',
			'salle.seance.notifications' => 'الإشعارات',
			'salle.seance.reglages' => 'الإعدادات',
			'salle.seance.compteDe' => ({required Object nom}) => 'حساب ⁨${nom}⁩',
			'salle.seance.sortir' => 'مغادرة الحصة',
			'salle.seance.commandesAppel' => 'أزرار المكالمة',
			'salle.seance.compteurEleves' => ({required Object connectes, required Object inscrits}) => 'الطلاب ⁨${connectes}⁩/⁨${inscrits}⁩',
			'salle.seance.parler' => 'تحدّث',
			'salle.seance.agrandir' => 'تكبير',
			'salle.seance.reduire' => 'تصغير',
			'salle.seance.rienPartage' => ({required Object nom}) => 'لم يشارك ⁨${nom}⁩ شيئًا بعد.',
			'salle.seance.videoDe' => ({required Object nom}) => 'فيديو ⁨${nom}⁩',
			'salle.seance.page' => ({required Object page, required Object pages}) => '⁨${page}⁩ / ⁨${pages}⁩',
			'salle.seance.pageSemantique' => ({required Object page, required Object pages}) => 'الصفحة ⁨${page}⁩ من ⁨${pages}⁩',
			'salle.seance.zoomLocal' => 'تكبير محلي، لا يؤثر في الآخرين',
			'salle.seance.zoomValeur' => ({required Object valeur}) => '⁨${valeur}⁩ %',
			'salle.seance.zoomMoins' => 'تقليل التكبير',
			'salle.seance.zoomPlus' => 'زيادة التكبير',
			'salle.seance.quitterQuestion' => 'مغادرة الحصة؟',
			'salle.seance.quitterConsequence' => 'يمكنك العودة ما دامت الحصة مفتوحة.',
			'salle.seance.illustration' => 'رسم توضيحي للمادة',
			'salle.seance.quitterCahierConsequence' => 'ستنتقل بعد ذلك إلى دفتر المتابعة.',
			'salle.seance.quitterCahier' => 'المغادرة وفتح دفتر المتابعة',
			'salle.seance.rester' => 'البقاء',
			'salle.seance.supports' => 'المواد',
			'salle.seance.reseau' => 'الشبكة',
			'salle.seance.pagePrecedente' => 'الصفحة السابقة',
			'salle.seance.pageSuivante' => 'الصفحة التالية',
			'salle.seance.outils.titre' => 'أدوات التدريس',
			'salle.seance.outils.pointeur' => 'المؤشر',
			'salle.seance.outils.marquer' => 'تعليم',
			'salle.seance.outils.masquer' => 'إخفاء',
			'salle.seance.outils.annoter' => 'كتابة ملاحظات',
			'salle.seance.rail.navigation' => 'التنقل',
			'salle.seance.rail.marque' => 'Rewayah',
			'salle.seance.rail.sousMarque' => 'Academy',
			'salle.seance.rail.journee' => 'اليوم',
			'salle.seance.rail.classes' => 'الفصول',
			'salle.seance.rail.ressources' => 'الموارد',
			'salle.seance.rail.profil' => 'الملف الشخصي',
			'salle.seance.fermerPanneau' => 'إغلاق اللوحة',
			'salle.seance.panneauSupports.reprendre' => 'استئناف',
			'salle.seance.panneauSupports.recents' => 'الأحدث',
			'salle.seance.panneauSupports.ressourcesClasse' => 'موارد الفصل',
			'salle.seance.panneauSupports.voirTout' => 'عرض الكل',
			'salle.seance.panneauSupports.ouvrir' => 'فتح',
			'salle.seance.panneauSupports.ouvrirSupport' => ({required Object titre}) => 'فتح ⁨${titre}⁩',
			'salle.seance.panneauSupports.voirBibliotheque' => 'عرض المكتبة كاملة',
			'salle.seance.eleves' => 'الطلاب',
			'salle.seance.rappeler' => 'النداء بهدوء',
			'salle.seance.faireReciter' => 'طلب التلاوة',
			'salle.seance.fileRecitation' => 'دور التلاوة',
			'salle.seance.aSuivre' => 'التالي',
			'salle.seance.vousAppelle' => ({required Object nom}) => '⁨${nom}⁩ يناديك',
			'salle.seance.signalerBesoin' => 'الإشارة إلى حاجة',
			'salle.seance.deplierFiche' => ({required Object prenom}) => 'عرض بطاقة ⁨${prenom}⁩',
			'salle.seance.replierFiche' => ({required Object prenom}) => 'إخفاء بطاقة ⁨${prenom}⁩',
			'salle.seance.fiche.aucuneSeanceSemaine' => 'لا حصص هذا الأسبوع',
			'salle.seance.fiche.uneSeanceSemaine' => 'حصة واحدة هذا الأسبوع',
			'salle.seance.fiche.seancesSemaine' => ({required Object nombre}) => '⁨${nombre}⁩ حصص هذا الأسبوع',
			'salle.seance.optionsPanneau' => ({required Object titre}) => 'خيارات لوحة ⁨${titre}⁩',
			'salle.seance.commandes.declencheur' => 'الأوامر',
			'salle.seance.commandes.declencheurSemantique' => 'فتح أوامر المادة والسبورة',
			'salle.seance.commandes.titre' => 'الأوامر',
			'salle.seance.commandes.reduire' => 'تصغير',
			'salle.seance.commandes.reduireSemantique' => 'تصغير الأوامر',
			'salle.seance.commandes.ongletSupport' => 'المادة',
			'salle.seance.commandes.ongletOutils' => 'الأدوات',
			'salle.seance.commandes.bibliotheque' => 'المكتبة',
			'salle.seance.commandes.affichageSupport' => 'المادة',
			'salle.seance.commandes.affichageAvecNotes' => 'مع الملاحظات',
			'salle.seance.commandes.affichageTableau' => 'السبورة',
			'salle.seance.commandes.lecture' => 'القراءة',
			'salle.seance.commandes.ajuster' => 'ملاءمة الشاشة',
			'salle.seance.commandes.affichage' => 'العرض',
			'salle.seance.commandes.focus' => 'التركيز',
			'salle.seance.commandes.focusSemantique' => 'التركيز، تكبير المحتوى وتصغير اللوحات',
			'salle.seance.commandes.quitterFocus' => 'الخروج من التركيز',
			'salle.seance.bibliotheque.intro' => 'المادة التي تختارها تُفتح لك وحدك. يبقى الفصل على المادة الحالية حتى «عرض».',
			'salle.seance.bibliotheque.apercu' => 'معاينة خاصة',
			'salle.seance.bibliotheque.apercuClasse' => 'ما زال الطلاب يرون المادة الحالية.',
			'salle.seance.bibliotheque.presenter' => 'عرض',
			'salle.seance.bibliotheque.revenir' => 'العودة إلى المواد',
			'salle.seance.bibliotheque.ouverture' => 'جارٍ فتح المادة…',
			'salle.seance.bibliotheque.echec' => 'تعذّر فتح هذه المادة.',
			'salle.seance.bibliotheque.echecDetail' => 'تعذّر تحميل الملف. يبقى الفصل على المادة الحالية. أعد المحاولة، أو عد إلى المواد لاختيار مادة أخرى.',
			'salle.seance.surface.aucunSupport' => 'اختر مادة أو اكتب على السبورة.',
			'salle.seance.surface.page' => ({required Object titre, required Object page, required Object pages}) => '⁨${titre}⁩، الصفحة ⁨${page}⁩ من ⁨${pages}⁩',
			'salle.seance.surface.supportMasque' => 'السبورة، المادة مخفية',
			'salle.seance.capsule.avatar' => ({required Object nom}) => 'عرض معلومات ⁨${nom}⁩',
			'salle.seance.capsule.controlePossible' => 'المراقبة ممكنة. عرض المعلومات',
			'salle.seance.capsule.controleActif' => 'المراقبة جارية. عرض المعلومات',
			'salle.seance.capsule.enregistrementActif' => 'التسجيل جارٍ',
			'salle.seance.contexte.titre' => 'معلومات الحصة',
			'salle.seance.contexte.reseau' => 'الشبكة',
			'salle.seance.contexte.detailReseau' => 'تفاصيل الشبكة',
			'salle.seance.contexte.enregistrementActif' => 'التسجيل جارٍ',
			'salle.seance.contexte.controle' => 'المراقبة',
			'salle.seance.contexte.controlePossible' => 'المراقبة ممكنة',
			'salle.seance.contexte.controleActif' => 'المراقبة جارية',
			'salle.seance.contexte.controlePossibleDetail' => 'قد تجري زيارة مراقبة. هذا لا يعني أن أحدًا يتابع الآن.',
			'salle.seance.contexte.controleActifDetail' => 'تجري زيارة مراقبة الآن.',
			'salle.seance.contexte.reduire' => 'تصغير',
			'salle.seance.contexte.reduireParticipants' => 'تصغير المشاركين',
			'salle.seance.contexte.reduireInformations' => 'تصغير المعلومات',
			'salle.seance.demo.titre' => 'قاعة العرض التجريبي',
			'salle.seance.demo.intro' => 'بيانات وهمية، دون خادم. اختر دورًا وحالة.',
			'salle.seance.demo.groupes.seance' => 'مجرى الحصة',
			'salle.seance.demo.groupes.secours' => 'حالات الطوارئ',
			'salle.seance.demo.groupes.tableau' => 'المواد والسبورة',
			'salle.seance.demo.roles.eleve' => 'طالب عادي',
			'salle.seance.demo.roles.guidee' => 'وضع إمكانية الوصول',
			'salle.seance.demo.roles.enseignant' => 'المعلم',
			'salle.seance.demo.etats.repos' => 'سكون',
			'salle.seance.demo.etats.visite' => 'زيارة',
			'salle.seance.demo.etats.rienPartage' => 'لا شيء مُشارَك',
			'salle.seance.demo.etats.appel' => 'النداء بهدوء',
			'salle.seance.demo.etats.eleves' => 'لوحة الطلاب',
			'salle.seance.demo.etats.supports' => 'لوحة المواد',
			'salle.seance.demo.etats.fin' => 'نهاية الحصة',
			'salle.seance.demo.etats.reseauFaible' => 'شبكة ضعيفة',
			'salle.seance.demo.etats.reconnexion' => 'إعادة الاتصال',
			'salle.seance.demo.etats.retablie' => 'عاد الاتصال',
			'salle.seance.demo.etats.echec' => 'تعذّرت إعادة الاتصال',
			'salle.seance.demo.etats.horsLigne' => 'غير متصل',
			'salle.seance.demo.etats.microBloque' => 'الميكروفون محظور',
			'salle.seance.demo.etats.cameraInterdite' => 'الكاميرا ممنوعة',
			'salle.seance.demo.etats.prolongee' => 'حصة ممدَّدة',
			'salle.seance.demo.etats.accesRetire' => 'سُحب الدخول',
			'salle.seance.demo.tb.sal00' => 'SAL-00 القاعة والأشخاص',
			'salle.seance.demo.tb.ped01' => 'PED-01 سبورة حرة، دون مادة',
			'salle.seance.demo.tb.ped02' => 'PED-02 المادة وحدها',
			'salle.seance.demo.tb.ped03' => 'PED-03 المادة مع الملاحظات',
			'salle.seance.demo.tb.ped04' => 'PED-04 السبورة، المادة مخفية',
			'salle.seance.demo.tb.ui01' => 'UI-01 عرض مضغوط',
			'salle.seance.demo.tb.ui02' => 'UI-02 قاعة موسَّعة',
			'salle.seance.demo.tb.ui03' => 'UI-03 تركيز محلي',
			'salle.seance.demo.tb.vis01' => 'VIS-01 شريط الفيديو ظاهر',
			'salle.seance.demo.tb.ctx01' => 'CTX-01 سياق الحصة',
			'salle.seance.demo.tb.ctx02' => 'CTX-02 معلومات المراقبة',
			'salle.seance.demo.tb.cmd01' => 'CMD-01 الأوامر',
			'salle.seance.demo.tb.cmd02' => 'CMD-02 اللون والسُّمك',
			'salle.seance.demo.tb.cmd03' => 'CMD-03 الكتابة جارية',
			'salle.seance.demo.tb.lib01' => 'LIB-01 المكتبة',
			'salle.seance.demo.tb.lib02' => 'LIB-02 معاينة خاصة',
			'salle.seance.demo.tb.lib03' => 'LIB-03 فتح المادة',
			'salle.seance.demo.tb.lib04' => 'LIB-04 بحث دون نتيجة',
			'salle.seance.demo.tb.per01' => 'PER-01 المشاركون والأذونات',
			'salle.seance.demo.tb.dlg01' => 'DLG-01 مسح ملاحظات الصفحة',
			'salle.seance.demo.tb.err01' => 'ERR-01 انقطعت المزامنة',
			'salle.seance.demo.tb.err02' => 'ERR-02 استعادة السبورة',
			'salle.seance.demo.tb.err03' => 'ERR-03 فشل الحفظ',
			'salle.seance.demo.tb.end01' => 'END-01 مغادرة الحصة',
			'salle.seance.demo.tb.supportArrive' => 'المادة في الطريق',
			'salle.seance.demo.tb.ressourceIndisponible' => 'المورد غير متاح',
			'salle.seance.demo.tb.autorisationEcrire' => 'إذن بالكتابة',
			'salle.seance.demo.tb.droitRetire' => 'سُحب الإذن',
			'salle.seance.demo.tb.effacementTableau' => 'مسح ملاحظات السبورة',
			'salle.seance.statut.connecte' => 'متصل',
			'salle.seance.statut.pasEncoreConnecte' => 'لم يتصل بعد',
			'salle.seance.statut.connexionInterrompue' => 'انقطع الاتصال',
			'salle.fin.titre' => 'انتهت الحصة',
			'salle.fin.phrase' => 'تجد عملك في فصلك.',
			'salle.fin.retourClasse' => 'العودة إلى الفصل',
			'salle.fin.quitteTitre' => 'غادرت الحصة.',
			'salle.fin.quittePhrase' => 'يمكنك العودة ما دامت مفتوحة.',
			'salle.fin.accesRetireTitre' => 'انتهى دخولك إلى هذه الحصة.',
			'salle.fin.titreGuidee' => 'انتهت الحصة.',
			'salle.fin.retourAccueil' => 'العودة إلى الصفحة الرئيسية',
			'salle.fin.enseignant.terminee' => 'منتهية',
			'salle.fin.enseignant.phrase' => 'دفتر المتابعة جاهز بمعلومات الحصة.',
			'salle.fin.enseignant.recapitulatif' => 'ملخص الحصة',
			'salle.fin.enseignant.fin' => 'النهاية',
			'salle.fin.enseignant.connectes' => ({required Object n}) => '⁨${n}⁩ طلاب متصلون',
			'salle.fin.enseignant.unConnecte' => ({required Object n}) => '⁨${n}⁩ طالب متصل',
			'salle.fin.enseignant.inscrits' => ({required Object n}) => 'من ⁨${n}⁩ مسجَّلين',
			'salle.fin.enseignant.unInscrit' => ({required Object n}) => 'من ⁨${n}⁩ مسجَّل',
			'salle.fin.enseignant.cahierSeance' => 'دفتر المتابعة',
			'salle.fin.enseignant.cahierACompleter' => 'دفتر المتابعة بانتظار الإكمال',
			'salle.fin.enseignant.ouvrirCahier' => 'فتح دفتر المتابعة',
			'salle.fin.enseignant.revenirJournee' => 'العودة إلى يومي',
			'salle.fin.enseignant.erreurCahier' => 'تعذّر فتح دفتر المتابعة الآن. أعد المحاولة بعد لحظة.',
			'salle.micro' => 'الميكروفون',
			'salle.camera' => 'الكاميرا',
			'salle.quitter' => 'مغادرة',
			'salle.ouvrirCoran' => 'فتح القرآن',
			'salle.confirmerSortie' => 'مغادرة الدرس؟',
			'salle.expiree' => 'لم تعد هذه القاعة متاحة. عد إلى صفحتك الرئيسية للانضمام إلى الدرس القادم.',
			'salle.ouverture' => 'جارٍ فتح القاعة',
			'salle.verificationMateriel' => 'جارٍ التحقق من الميكروفون',
			'salle.connexion' => 'جارٍ الاتصال بالدرس',
			'salle.reconnexion' => 'الاتصال غير مستقر، جارٍ إعادة الاتصال',
			'salle.reconnexionCourt' => 'إعادة الاتصال',
			'salle.perdue' => 'انقطع الاتصال بالدرس',
			'salle.seulEnseignant' => 'لم يصل معلمك بعد',
			'salle.seulEnseignantDetail' => 'ابقَ على هذه الشاشة. ستراه يظهر.',
			'salle.seulEleve' => 'لم يصل طالبك بعد',
			'salle.seulEleveDetail' => 'ابقَ على هذه الشاشة. ستراه يظهر.',
			'salle.seulObservation' => 'لم يدخل أحد هذه القاعة بعد',
			'salle.seulObservationDetail' => 'لم يبدأ الدرس، أو انتهى بالفعل.',
			'salle.refusAcces' => 'هذا الدرس غير مفتوح لك الآن',
			'salle.refusAccesDetail' => 'تُفتح القاعة قبل موعد الدرس بعشر دقائق، وتُغلق بعد نهايته بربع ساعة.',
			'salle.refusConfiguration' => 'القاعة غير متاحة بعد',
			'salle.refusConfigurationDetail' => 'المشكلة ليست في جهازك: خدمة مكالمات الفيديو غير موصولة. الفريق على علم بذلك.',
			'salle.refusReseau' => 'لم تستجب القاعة',
			'salle.refusReseauDetail' => 'تحقّق من اتصالك، ثم أعد المحاولة.',
			'salle.refusMateriel' => 'لا يوجد ميكروفون صالح على هذا الجهاز',
			'salle.refusMaterielDetail' => 'درس القرآن يكون بالصوت. اسمح بالوصول إلى الميكروفون، أو وصّل سماعة، ثم أعد المحاولة.',
			'salle.retourAccueil' => 'العودة إلى صفحتي الرئيسية',
			'salle.ouvrirMicro' => 'فتح الميكروفون',
			'salle.fermerMicro' => 'إغلاق الميكروفون',
			'salle.ouvrirCamera' => 'تشغيل الكاميرا',
			'salle.fermerCamera' => 'إطفاء الكاميرا',
			'salle.quitterLeCours' => 'مغادرة الدرس',
			'salle.consequenceSortie' => 'يستمر الدرس دونك، ويُسجَّل خروجك في الحصة.',
			'salle.vousMeme' => 'أنت',
			'salle.sansImage' => 'دون صورة',
			'salle.lienMediocre' => 'اتصال ضعيف',
			'salle.lienPerdu' => 'انقطع الاتصال',
			'salle.videoSuspendue' => 'توقفت الصورة إلى أن يعود الاتصال. الصوت مستمر.',
			'salle.roleEnseignant' => 'المعلم',
			'salle.roleEleve' => 'الطالب',
			'salle.roleTuteur' => 'وليّ الأمر، متابِع',
			'salle.roleAdministration' => 'إدارة Rewayah',
			'salle.observationMuette' => 'أنت تحضر الدرس. لا أحد يسمعك.',
			'salle.observationMuetteTitre' => 'أنت تحضر الدرس.',
			'salle.bandeauControle' => 'زيارة مراقبة. لا أحد يراك أو يسمعك، ويُسجَّل مرورك في السجل.',
			'salle.bandeauControleTitre' => 'زيارة مراقبة.',
			'salle.visiteControle.titre' => 'مراقبة Rewayah',
			'salle.visiteControle.sonRecu' => 'الصوت الوارد مفتوح',
			'salle.visiteControle.sonCoupe' => 'الصوت الوارد مكتوم',
			'salle.visiteControle.couperSon' => 'كتم الصوت الوارد',
			'salle.visiteControle.retablirSon' => 'إعادة الصوت الوارد',
			'salle.visiteControle.agrandir' => 'تكبير المادة',
			'salle.visiteControle.reduire' => 'تصغير المادة',
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
			'enseignant.journee.lancer' => 'بدء الدرس',
			'enseignant.journee.preflight' => 'التحقق قبل الدرس',
			'enseignant.journee.titre' => 'اليوم',
			'enseignant.journee.prochainCours' => 'الدرس القادم',
			'enseignant.journee.coursEnCours' => 'حصة مباشرة',
			'enseignant.journee.minuteurHeures' => ({required Object heures, required Object minutes}) => 'بعد ⁨${heures}⁩ س ⁨${minutes}⁩ د',
			'enseignant.journee.minuteurMinutes' => ({required Object minutes}) => 'بعد ⁨${minutes}⁩ دقيقة',
			'enseignant.journee.minuteurImminent' => 'يبدأ الآن',
			'enseignant.journee.jusqua' => ({required Object heure}) => 'حتى ⁨${heure}⁩',
			'enseignant.journee.unAutreJour' => ({required Object jour, required Object heure}) => '⁨${jour}⁩، الساعة ⁨${heure}⁩',
			'enseignant.journee.lancementPlusTard' => 'يُتاح البدء قبل موعد الدرس بعشر دقائق.',
			'enseignant.journee.aucunCours' => 'لا دروس قادمة',
			'enseignant.journee.aucunCoursDetail' => 'اقبل طالبًا في الانتظار: هذا ما يملأ يومك.',
			'enseignant.journee.colonne' => 'اليوم',
			'enseignant.journee.ligneCours' => ({required Object prenom}) => 'درس مع ⁨${prenom}⁩',
			'enseignant.journee.lignePause' => 'استراحة',
			'enseignant.journee.plage' => ({required Object debut, required Object fin}) => '⁨${debut}⁩ إلى ⁨${fin}⁩',
			'enseignant.journee.duree' => ({required Object minutes}) => '⁨${minutes}⁩ دقيقة',
			'enseignant.journee.rienAujourdhui' => 'لا شيء مقرر اليوم',
			'enseignant.journee.rienAujourdhuiDetail' => ({required Object jour, required Object heure}) => 'درسك القادم ⁨${jour}⁩ الساعة ⁨${heure}⁩.',
			'enseignant.journee.journeeTerminee' => ({required Object nombre}) => '⁨${nombre}⁩ دروس قُدِّمت اليوم.',
			'enseignant.journee.journeeTermineeUn' => 'درس واحد قُدِّم اليوم.',
			'enseignant.journee.voirCreneaux' => 'عرض مواعيدي',
			'enseignant.journee.erreur' => 'تعذّرت قراءة اليوم كاملًا. أعد المحاولة بعد لحظة.',
			'enseignant.journee.coursIndividuel' => 'درس فردي',
			'enseignant.journee.effectif' => ({required Object nombre}) => '⁨${nombre}⁩ طلاب',
			'enseignant.journee.effectifUn' => 'طالب واحد',
			'enseignant.journee.preflightOk' => 'الميكروفون جاهز',
			'enseignant.journee.preflightBloque' => 'متصفحك يحظر الميكروفون. اسمح به لبدء الدرس.',
			'enseignant.journee.preflightSansMicro' => 'لم يُعثر على ميكروفون. وصّل واحدًا لبدء الدرس.',
			'enseignant.journee.preflightIndisponible' => 'لم يكتمل التحقق من الأجهزة. أعد المحاولة قبل بدء الدرس.',
			'enseignant.journee.lancerHorsLigne' => 'دون شبكة، لا يمكن فتح القاعة. أعد الاتصال لبدء الدرس.',
			'enseignant.journee.erreurPartielle' => 'تعذّر تحميل أوقات الصلاة واستراحاتك (اتصال غير مستقر أو خدمة غير متاحة مؤقتًا). الحصص المعروضة محدَّثة: يمكنك بدؤها بشكل عادي.',
			'enseignant.journee.absenceDetectee' => ({required Object eleve}) => 'لم يدخل ⁨${eleve}⁩ القاعة.',
			'enseignant.journee.coupureDetectee' => ({required Object eleve}) => 'انقطع اتصال ⁨${eleve}⁩.',
			'enseignant.journee.coursAnnule' => ({required Object heure}) => 'أُلغي درس الساعة ⁨${heure}⁩.',
			'enseignant.journee.rapportsTitre' => 'تقارير بانتظار الإيداع',
			'enseignant.journee.rapportLigne' => ({required Object jour, required Object heure}) => 'درس ⁨${jour}⁩ الساعة ⁨${heure}⁩',
			'enseignant.journee.rapportAttente' => ({required Object heures}) => 'للإيداع منذ ⁨${heures}⁩ س',
			_ => null,
		} ?? switch (path) {
			'enseignant.journee.rapportRetard' => ({required Object heures}) => 'متأخر ⁨${heures}⁩ س',
			'enseignant.journee.enAttenteTitre' => 'طلاب في الانتظار',
			'enseignant.journee.enAttenteLibelle' => 'طلاب في الانتظار في ساعاتك',
			'enseignant.journee.enAttenteLibelleUn' => 'طالب في الانتظار في ساعاتك',
			'enseignant.journee.prochaineSeance' => 'الحصة القادمة',
			'enseignant.journee.maJournee' => 'يومي',
			'enseignant.journee.aTerminer' => 'للإنهاء',
			'enseignant.journee.aTerminerVide' => 'كل دفاترك منتهية.',
			'enseignant.journee.aTerminerErreur' => 'تعذّرت قراءة الدفاتر المطلوب إنهاؤها. أعد المحاولة بعد لحظة.',
			'enseignant.journee.aTerminerAide' => 'دفتر المتابعة يساعد طلابك ويتيح لك تعديل الدرس القادم.',
			'enseignant.journee.rappelCahier' => 'دفاتر متابعة تنتظر الإنهاء',
			'enseignant.journee.cahierLigne' => ({required Object classe}) => 'دفتر متابعة ⁨${classe}⁩',
			'enseignant.journee.cahierDetail' => ({required Object jour, required Object numero, required Object mois, required Object heure}) => 'حصة ⁨${jour}⁩ ⁨${numero}⁩ ⁨${mois}⁩ الساعة ⁨${heure}⁩',
			'enseignant.journee.alertesUtiles' => 'تنبيهات مفيدة',
			'enseignant.journee.alertesVide' => 'لا تنبيهات مفيدة الآن.',
			'enseignant.journee.alertesErreur' => 'تعذّرت قراءة تنبيهات الحضور: لم يستجب الاتصال أو الخادم. أعد المحاولة بعد لحظة.',
			'enseignant.journee.voirAutreAlerte' => 'عرض التنبيه الآخر',
			'enseignant.journee.voirAutresAlertes' => ({required Object nombre}) => 'عرض التنبيهات الأخرى (⁨${nombre}⁩)',
			'enseignant.journee.remplacementsTitre' => 'الاستخلافات المؤكَّدة',
			'enseignant.journee.remplacementsVide' => 'لا درس لزميل تتولاه الآن.',
			'enseignant.journee.voirTousRemplacements' => ({required Object nombre}) => 'عرض الكل: الاستخلافات المؤكَّدة (⁨${nombre}⁩)',
			'enseignant.journee.heure' => 'الساعة',
			'enseignant.journee.eleves' => 'الطلاب',
			'enseignant.journee.classe' => 'الفصل',
			'enseignant.journee.classeNommee' => ({required Object classe}) => 'الفصل ⁨${classe}⁩',
			'enseignant.journee.preparerSeance' => 'تحضير الحصة',
			'enseignant.journee.preparerSeanceLecteur' => ({required Object classe}) => 'تحضير حصة ⁨${classe}⁩',
			'enseignant.journee.voirClasse' => 'عرض الفصل',
			'enseignant.journee.voirClasseLecteur' => ({required Object classe}) => 'عرض الفصل ⁨${classe}⁩',
			'enseignant.journee.aucuneSeance' => 'لا حصص قادمة',
			'enseignant.journee.aucuneSeanceDetail' => 'ستظهر هنا حصصك القادمة.',
			'enseignant.journee.date' => ({required Object jour, required Object numero, required Object mois}) => '⁨${jour}⁩ ⁨${numero}⁩ ⁨${mois}⁩',
			'enseignant.journee.absence.ouvrir' => 'الإبلاغ عن غيابي في هذه الحصة',
			'enseignant.journee.absence.ouvrirContexte' => 'سيُبحث عن بديل لطلابك.',
			'enseignant.journee.absence.titre' => 'لن تستطيع تولي هذه الحصة؟',
			'enseignant.journee.absence.cleDate' => 'التاريخ',
			'enseignant.journee.absence.notice' => 'يبقى إسنادك إلى الفصل كما هو.',
			'enseignant.journee.absence.declarer' => 'التصريح بغيابي',
			'enseignant.journee.absence.echec' => 'لم يكتمل الطلب. أعد المحاولة بعد لحظة.',
			'enseignant.journee.absence.etats.enregistree' => 'سُجِّل الغياب',
			'enseignant.journee.absence.etats.recherche' => 'جارٍ البحث عن بديل',
			'enseignant.journee.absence.etats.remplacantConfirme' => 'البديل مؤكَّد',
			'enseignant.journee.absence.etats.aucunRemplacant' => 'لا بديل مؤكَّد',
			'enseignant.journee.absence.etats.seanceAnnulee' => 'أُلغيت الحصة',
			'enseignant.journee.absence.etats.demandeAnnulee' => 'أُلغي الطلب',
			'enseignant.journee.remplacement.titre' => 'تولي هذا الاستخلاف؟',
			'enseignant.journee.remplacement.assurer' => 'تولي هذا الاستخلاف',
			'enseignant.journee.remplacement.pasCetteFois' => 'ليس هذه المرة',
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
			'enseignant.ficheGroupe.creneauHebdo' => ({required Object jour, required Object heure}) => '⁨${jour}⁩ الساعة ⁨${heure}⁩، كل أسبوع',
			'enseignant.ficheGroupe.aucunMembre' => 'لا طالب في هذا الفصل',
			'enseignant.ficheGroupe.aucunMembreDetail' => 'الإدارة تكوّن الفصول: هذا الفصل ليس فيه طالب بعد.',
			'enseignant.ficheGroupe.erreur' => 'تعذّرت قراءة هذا الفصل. أعد المحاولة بعد لحظة.',
			'enseignant.ficheGroupe.introuvable' => 'هذا الفصل ليس من فصولك',
			'enseignant.ficheGroupe.introuvableDetail' => 'ربما أُغلق، أو هو لمعلم آخر.',
			'enseignant.ficheGroupe.revue' => 'فتح مراجعة الفصل',
			'enseignant.ficheGroupe.ressourcesTitre' => 'الموارد الأخيرة',
			'enseignant.ficheGroupe.progressionTitre' => 'تقدم الفصل',
			'enseignant.classes.titre' => 'الفصول',
			'enseignant.classes.vide' => 'لا فصل مسند إليك',
			'enseignant.classes.videDetail' => 'ستظهر هنا الفصول المؤكَّدة.',
			'enseignant.classes.erreur' => 'تعذّرت قراءة فصولك. أعد المحاولة بعد لحظة.',
			'enseignant.classes.chargement' => 'جارٍ تحميل فصولك.',
			'enseignant.classes.niveau' => ({required Object niveau}) => 'المستوى ⁨${niveau}⁩',
			'enseignant.classes.eleveUn' => 'طالب واحد',
			'enseignant.classes.eleves' => ({required Object nombre}) => '⁨${nombre}⁩ طلاب',
			'enseignant.classes.prochaine' => ({required Object jour, required Object heure}) => 'الحصة القادمة: ⁨${jour}⁩ الساعة ⁨${heure}⁩',
			'enseignant.classes.sansProchaine' => 'لا حصة مقررة',
			'enseignant.classes.remplacement' => 'استخلاف',
			'enseignant.classes.rappelCahier' => 'دفتر متابعة ينتظر التأكيد',
			'enseignant.classes.cahierAValider' => 'دفتر المتابعة بانتظار التأكيد',
			'enseignant.eleve.titre' => ({required Object prenom}) => 'بطاقة ⁨${prenom}⁩',
			'enseignant.eleve.retour' => 'الطلاب',
			'enseignant.eleve.identifiant' => ({required Object id}) => 'معرّف الأكاديمية: ⁨${id}⁩',
			'enseignant.eleve.photo' => ({required Object prenom}) => 'صورة ⁨${prenom}⁩',
			'enseignant.eleve.niveau' => 'المستوى',
			'enseignant.eleve.objectif' => 'الهدف',
			'enseignant.eleve.presence' => 'الحضور الأخير',
			'enseignant.eleve.travail' => 'العمل',
			'enseignant.eleve.travailReprise' => ({required Object page}) => 'الاستئناف من ⁨${page}⁩',
			'enseignant.eleve.derniereSeance' => 'آخر حصة',
			'enseignant.eleve.nonRenseigne' => 'غير محدد',
			'enseignant.eleve.signaler' => 'الإشارة إلى حاجة',
			'enseignant.eleve.signalerAide' => 'حاجة تُرفع إلى الأكاديمية، دون إعادة كتابة السياق.',
			'enseignant.signalement.titre' => 'الإشارة إلى حاجة',
			'enseignant.signalement.contexte' => ({required Object prenom, required Object classe}) => 'لـ⁨${prenom}⁩ · ⁨${classe}⁩',
			'enseignant.signalement.categorieTitre' => 'الفئة',
			'enseignant.signalement.categories.pedagogique' => 'مشكلة تعليمية',
			'enseignant.signalement.categories.presence' => 'الحضور',
			'enseignant.signalement.categories.technique' => 'تقنية',
			'enseignant.signalement.categories.changement' => 'تغيير',
			'enseignant.signalement.categories.autre' => 'أخرى',
			'enseignant.signalement.details' => 'تفاصيل داخلية',
			'enseignant.signalement.detailsAide' => 'يقرؤها فريق الأكاديمية فقط.',
			'enseignant.signalement.resume' => 'ملخص قابل للمشاركة',
			'enseignant.signalement.resumeAide' => 'يمكن للأكاديمية مشاركته مع الأسرة.',
			'enseignant.signalement.notice' => 'لا تُرسل التفاصيل الداخلية تلقائيًا إلى الأسرة.',
			'enseignant.signalement.choisirCategorie' => 'اختر فئة للمتابعة.',
			'enseignant.signalement.detailsRequis' => 'في «أخرى»، قل في كلمات قليلة بماذا يتعلق الأمر.',
			'enseignant.signalement.envoyer' => 'إرسال الإشارة',
			'enseignant.signalement.demoSucces' => 'عرض تجريبي: هذه الإشارة جاهزة، لكن لم يُرسل شيء.',
			'enseignant.signalement.demoSuccesDetail' => 'في التطبيق الموصول، ستُرسل إلى فريق الأكاديمية.',
			'enseignant.signalement.fermer' => 'إغلاق',
			'enseignant.demo.titre' => 'عرض تجريبي للمعلم',
			'enseignant.demo.mention' => 'بيانات وهمية، لا إرسال.',
			'enseignant.demo.intro' => 'اختر شاشة من شاشات السيد إبراهيم.',
			'enseignant.demo.ecrans' => 'الشاشات',
			'enseignant.demo.etats' => 'الحالات',
			'enseignant.demo.etatNominal' => 'يوم عادي',
			'enseignant.demo.etatVide' => 'لا حصة',
			'enseignant.demo.etatHorsLigne' => 'غير متصل',
			'enseignant.bienvenue.titre' => 'الخطوات الأولى',
			'enseignant.bienvenue.salutation' => ({required Object prenom}) => 'مرحبًا، ⁨${prenom}⁩.',
			'enseignant.bienvenue.salutationSansNom' => 'مرحبًا.',
			'enseignant.bienvenue.dossierValide' => 'تم اعتماد ملفك.',
			'enseignant.bienvenue.sousTitre' => 'جهّز مساحتك قبل فصلك الأول.',
			'enseignant.bienvenue.aCompleter' => 'للإكمال',
			'enseignant.bienvenue.compteur' => ({required Object fait, required Object total}) => '⁨${fait}⁩ من ⁨${total}⁩',
			'enseignant.bienvenue.prerequisPhoto' => 'إضافة صورتي المهنية',
			'enseignant.bienvenue.prerequisLangues' => 'التحقق من لغات تدريسي',
			'enseignant.bienvenue.prerequisFuseau' => 'التحقق من منطقتي الزمنية',
			'enseignant.bienvenue.ctaPhoto' => 'إضافة صورتي',
			'enseignant.bienvenue.ctaInformations' => 'التحقق من معلوماتي',
			'enseignant.bienvenue.ctaJournee' => 'عرض يومي',
			'enseignant.bienvenue.rappels' => 'أمران لا ينبغي اكتشافهما في منتصف الطريق',
			'enseignant.bienvenue.declarer' => 'التصريح بأوقات توفري',
			'enseignant.bienvenue.versJournee' => 'الذهاب إلى يومي',
			'enseignant.bienvenue.horsLigne' => 'دون شبكة، لا يمكن حفظ مواعيدك.',
			'enseignant.bienvenue.dossierIncomplet' => 'لم يُعتمد ملفك بعد.',
			'enseignant.bienvenue.dossierIncompletDetail' => 'بوابة الانتظار تخبرك بما بقي عليك تقديمه.',
			'enseignant.bienvenue.versAttente' => 'عرض ملفي',
			'enseignant.bienvenue.erreur' => 'تعذّرت قراءة ملفك الشخصي. أعد المحاولة بعد لحظة.',
			'enseignant.photo.titre' => 'الصورة المهنية',
			'enseignant.photo.aide' => 'صورتك إلزامية: الأسر لا تأتمن أطفالها لشخص مجهول على الإنترنت. تراها أسر طلابك.',
			'enseignant.photo.obligatoireLecteur' => 'الصورة إلزامية',
			'enseignant.photo.voile' => 'إن كنتِ ترتدين النقاب، يمكن أن تظهركِ صورة الملف منتقبة.',
			'enseignant.photo.notice' => 'لا تستخدم بطاقة هويتك.',
			'enseignant.photo.choisir' => 'اختيار صورة',
			'enseignant.photo.utiliser' => 'استخدام هذه الصورة',
			'enseignant.photo.remplacer' => 'استبدال الصورة',
			'enseignant.photo.autre' => 'اختيار صورة أخرى',
			'enseignant.photo.changer' => 'تغيير الصورة',
			'enseignant.photo.alternatif' => 'صورتك العامة',
			'enseignant.photo.succes' => 'حُفظت الصورة.',
			'enseignant.photo.echec' => 'تعذّر إرسال الصورة. لم يتغير شيء في الملف.',
			'enseignant.photo.selectionEchec' => 'تعذّر فتح الصورة. تحقّق من إذن الوصول إلى صور الجهاز، ثم أعد المحاولة.',
			'enseignant.photo.horsLigne' => 'أنت غير متصل. يمكن إرسال الصورة عند عودة الاتصال.',
			'enseignant.salle.reference' => ({required Object page, required Object total, required Object reference}) => 'المعروض: الصفحة ⁨${page}⁩ من ⁨${total}⁩ · ⁨${reference}⁩',
			'enseignant.salle.rien' => 'لا شيء معروض',
			'enseignant.salle.rienInvitation' => 'افتح القرآن لتعرض صفحة على فصلك.',
			'enseignant.salle.attenteSalle' => 'لست في القاعة بعد',
			'enseignant.salle.attenteSalleDetail' => 'تُفتح أوامر العرض بمجرد اتصال الدرس.',
			'enseignant.salle.lienFaibleDetail' => 'قد يصل تقليب الصفحة متأخرًا إلى فصلك',
			'enseignant.salle.presentationConservee' => 'الصفحة المعروضة محفوظة، وستُرسل عند عودة الاتصال',
			'enseignant.salle.presentationSuspendue' => 'العرض موقوف',
			'enseignant.salle.precedente' => 'عرض الصفحة السابقة',
			'enseignant.salle.suivante' => 'عرض الصفحة التالية',
			'enseignant.salle.bibliotheque' => 'اختيار سورة',
			'enseignant.salle.presenterSourate' => ({required Object sourate}) => 'عرض بداية ⁨${sourate}⁩',
			'enseignant.salle.sourateDetail' => ({required Object numero, required Object versets}) => 'السورة ⁨${numero}⁩ · ⁨${versets}⁩ آية',
			'enseignant.salle.souratesIndisponibles' => 'تعذّرت قراءة قائمة السور',
			'enseignant.salle.souratesIndisponiblesDetail' => 'لم يتغير ما يراه فصلك. أعد المحاولة.',
			'enseignant.salle.pageIndisponible' => 'تعذّرت قراءة هذه الصفحة',
			'enseignant.salle.pageIndisponibleDetail' => 'لم يصل النص إلى هنا. ما زال فصلك يرى الصفحة المعروضة.',
			'enseignant.salle.corpusAbsent' => 'نص القرآن غير مثبَّت',
			'enseignant.salle.corpusAbsentDetail' => 'لا شيء للعرض.',
			'enseignant.salle.echecPresentation' => 'تعذّر تحديد موضع هذه الآية في المصحف. لم يُرسل شيء إلى فصلك.',
			'enseignant.salle.sansDroitPresentation' => 'دخولك إلى هذه الحصة لا يسمح بعرض محتوى.',
			'enseignant.cahier.titre' => 'دفتر المتابعة',
			'enseignant.cahier.obligatoire' => 'إلزامي',
			'enseignant.cahier.sousTitre' => 'إلزامي بعد كل حصة',
			'enseignant.cahier.description' => 'دوّن أين وصل كل طالب (السورة، الآية، القاعدة التي عُمل عليها). إن استخلفك معلم آخر، يستأنف تمامًا من حيث توقفت الحصة.',
			'enseignant.cahier.duree' => ({required Object minutes}) => '⁨${minutes}⁩ دقيقة من الدرس',
			'enseignant.cahier.dureeEtInterruption' => ({required Object minutes, required Object interruption}) => '⁨${minutes}⁩ دقيقة من الدرس، منها ⁨${interruption}⁩ دقيقة انقطاع',
			'enseignant.cahier.unEleve' => 'طالب واحد',
			'enseignant.cahier.eleves' => ({required Object nombre}) => '⁨${nombre}⁩ طلاب',
			'enseignant.cahier.toutEstNominal' => 'جرى كل شيء كما هو متوقع.',
			'enseignant.cahier.toutEstNominalDetail' => 'أكّد، ويستمر يومك.',
			'enseignant.cahier.exceptions' => 'للنظر',
			'enseignant.cahier.uneException' => 'طالب واحد يحتاج إلى نظرة.',
			'enseignant.cahier.plusieursExceptions' => ({required Object nombre}) => '⁨${nombre}⁩ طلاب يحتاجون إلى نظرة.',
			'enseignant.cahier.nominaux' => 'لا شيء يُذكر',
			'enseignant.cahier.curriculumFige' => 'المستوى والمنهج من الأكاديمية: لا يُعدَّلان من دفتر المتابعة.',
			'enseignant.cahier.valider' => 'تأكيد دفتر المتابعة',
			'enseignant.cahier.validerTout' => 'كل شيء مطابق، تأكيد',
			'enseignant.cahier.validerSansConstat' => 'الإيداع دون المعاينة',
			'enseignant.cahier.retourJournee' => 'العودة إلى يومي',
			'enseignant.cahier.vide' => 'تعذّر استنتاج المعاينة',
			'enseignant.cahier.videDetail' => 'لم يُسجَّل حضور ولا حدث لهذه الحصة. يمكنك مع ذلك إيداع دفتر المتابعة.',
			'enseignant.cahier.erreur' => 'تعذّرت قراءة المعاينة.',
			'enseignant.cahier.erreurDetail' => 'أعد المحاولة، أو أودع دفتر المتابعة دون المعاينة.',
			'enseignant.cahier.echecEnvoi' => 'لم يُؤكَّد الإرسال. تحقّق قبل إعادة المحاولة.',
			'enseignant.cahier.dejaDepose' => 'دفتر متابعة هذه الحصة مودَع بالفعل.',
			'enseignant.cahier.dejaDeposeDetail' => 'يُودَع دفتر المتابعة مرة واحدة، ولا يُحذف من هنا.',
			'enseignant.cahier.depose' => 'حُفظ دفتر المتابعة',
			'enseignant.cahier.deposeDetail' => 'استلمته الأكاديمية.',
			'enseignant.cahier.enFileTitre' => 'بانتظار الإرسال',
			'enseignant.cahier.enFile' => 'سيُرسل دفتر المتابعة عند عودة الاتصال.',
			'enseignant.cahier.enFileDetail' => 'سيُرسل دفتر المتابعة عند عودة الاتصال.',
			'enseignant.cahier.enFileDetailHorsLigne' => 'دون شبكة، يبقى دفتر المتابعة على هذا الجهاز ويُرسل بمجرد عودة الشبكة. يمكنك الانتقال إلى درسك التالي.',
			'enseignant.cahier.ajusterPour' => ({required Object eleve}) => 'تعديل · ⁨${eleve}⁩',
			'enseignant.cahier.ajusterValider' => 'حفظ لهذا الطالب',
			'enseignant.cahier.exceptionConsignee' => 'استثناء مُبلَغ عنه',
			'enseignant.cahier.pointPhonetique' => 'ملاحظة في النطق',
			'enseignant.cahier.pointPhonetiqueDetail' => 'زوج من الحروف، لا تقييم. اتركه فارغًا إن لم يكن هناك ما يُقال.',
			'enseignant.cahier.pointPhonetiqueNote' => 'دُوِّنت ملاحظة النطق',
			'enseignant.cahier.objectif' => ({required Object eleve}) => 'هدف ⁨${eleve}⁩',
			'enseignant.cahier.objectifDetail' => ({required Object eleve}) => 'ما يجب أن يبلغه ⁨${eleve}⁩، في إطار منهج الأكاديمية.',
			'enseignant.cahier.travailMaison' => ({required Object eleve}) => 'واجب ⁨${eleve}⁩',
			'enseignant.cahier.travailMaisonDetail' => 'عدّل الاقتراح، أو اتركه كما هو.',
			'enseignant.cahier.travailMaisonSaisi' => 'دوّنت هذا الواجب بالفعل. عدّله أو اتركه كما هو.',
			'enseignant.cahier.suite' => ({required Object eleve}) => 'ما بعد ذلك لـ⁨${eleve}⁩',
			'enseignant.cahier.suiteContinuer' => 'المتابعة',
			'enseignant.cahier.suiteRenforcer' => 'التثبيت',
			'enseignant.cahier.suspendreNouveau' => 'إيقاف الجديد',
			'enseignant.cahier.devoirPrecedent' => ({required Object devoir}) => 'الواجب السابق: ⁨${devoir}⁩',
			'enseignant.cahier.devoirPlage' => ({required Object sourate, required Object debut, required Object fin}) => 'مراجعة سورة ⁨${sourate}⁩، الآيات ⁨${debut}⁩ إلى ⁨${fin}⁩.',
			'enseignant.cahier.suspendreNouveauDetail' => 'تستمر المراجعة، ولا يُضاف شيء جديد لهذا الطالب.',
			'enseignant.cahier.position' => ({required Object sourate, required Object verset}) => 'القراءة: سورة ⁨${sourate}⁩، الآية ⁨${verset}⁩',
			'enseignant.cahier.makhrajSinSad' => 'السين / الصاد (س / ص)',
			'enseignant.cahier.makhrajTaTah' => 'التاء / الطاء (ت / ط)',
			'enseignant.cahier.makhrajDhalZay' => 'الذال / الزاي (ذ / ز)',
			'enseignant.cahier.makhrajHaHah' => 'الهاء / الحاء (ه / ح)',
			'enseignant.cahier.exceptionTitre' => 'الإبلاغ عن استثناء',
			'enseignant.cahier.exceptionCorriger' => 'تصحيح الحضور',
			'enseignant.cahier.exceptionExcuser' => 'تبرير الغياب',
			'enseignant.cahier.exceptionConfirmation' => 'تأكيد الاستثناء',
			'enseignant.cahier.exceptionMotif' => 'السبب',
			'enseignant.cahier.exceptionMotifRequis' => 'السبب إلزامي.',
			'enseignant.cahier.exceptionEnCours' => 'جارٍ الحفظ…',
			'enseignant.cahier.exceptionSucces' => 'دُوِّن الاستثناء. سيُرسل مع دفتر المتابعة.',
			'enseignant.cahier.exceptionErreur' => 'تعذّر تدوين الاستثناء.',
			'enseignant.cahier.exceptionHorsLigne' => 'دون شبكة، لا يمكن تأكيد استثناء. أما دفتر المتابعة فيُرسل على كل حال.',
			'enseignant.cahier.aValider' => 'للتأكيد',
			'enseignant.cahier.statutPresents' => ({required Object nombre}) => 'الحاضرون ⁨${nombre}⁩',
			'enseignant.cahier.statutAbsents' => ({required Object nombre}) => 'الغائبون ⁨${nombre}⁩',
			'enseignant.cahier.statutEnRetard' => ({required Object nombre}) => 'المتأخرون ⁨${nombre}⁩',
			'enseignant.cahier.performance' => 'الأداء',
			'enseignant.cahier.faiblesses' => 'نقاط الضعف',
			'enseignant.cahier.niveauARevoir' => 'للمراجعة',
			'enseignant.cahier.niveauEnProgres' => 'في تقدم',
			'enseignant.cahier.niveauAcquis' => 'مكتسَب',
			'enseignant.cahier.niveauMaitrise' => 'متقَن',
			'enseignant.cahier.faiblesseMakharij' => 'المخارج',
			'enseignant.cahier.faiblesseMadd' => 'المد',
			'enseignant.cahier.faiblesseGhunna' => 'الغنة',
			'enseignant.cahier.faiblesseWaqf' => 'الوقف',
			'enseignant.cahier.faiblesseFluidite' => 'الطلاقة',
			'enseignant.cahier.faiblesseMemorisation' => 'الحفظ',
			'enseignant.cahier.niveauARevoirDetail' => 'يُعاد الدرس في الحصة القادمة.',
			'enseignant.cahier.niveauEnProgresDetail' => 'الطالب يتقدم، وبقيت بعض الأخطاء.',
			'enseignant.cahier.niveauAcquisDetail' => 'الدرس محفوظ، بأخطاء قليلة.',
			'enseignant.cahier.niveauMaitriseDetail' => 'الدرس محفوظ دون خطأ، ويمكن للطالب أن يتقدم.',
			'enseignant.cahier.faiblesseMakharijDetail' => 'نطق الحروف.',
			'enseignant.cahier.faiblesseMaddDetail' => 'المدود.',
			'enseignant.cahier.faiblesseGhunnaDetail' => 'الصوت الأنفي.',
			'enseignant.cahier.faiblesseWaqfDetail' => 'مواضع الوقف.',
			'enseignant.cahier.faiblesseFluiditeDetail' => 'القراءة دون تردد.',
			'enseignant.cahier.faiblesseMemorisationDetail' => 'التلاوة من الحفظ.',
			'enseignant.cahier.reprise' => 'أين توقف الفصل',
			'enseignant.cahier.repriseDetail' => 'هذا موضع الاستئناف للمعلم البديل.',
			'enseignant.cahier.repriseProposee' => ({required Object sourate, required Object verset}) => 'سورة ⁨${sourate}⁩، الآية ⁨${verset}⁩',
			'enseignant.cahier.repriseRequise' => 'حدّد أين توقف الفصل: سيستأنف البديل من هنا.',
			'enseignant.cahier.integrite' => 'ما تكتبه هنا أمانة. قد لا يتحقق منه الناس، لكن الله يرى كل شيء.',
			'enseignant.cahier.corriger' => 'تصحيح دفتر المتابعة',
			'enseignant.cahier.corrigeLe' => ({required Object date}) => 'صُحِّح في ⁨${date}⁩',
			'enseignant.profil.titre' => 'الملف الشخصي',
			'enseignant.profil.compteValide' => 'حساب معلم موثَّق',
			'enseignant.profil.intro' => 'ما تعرفه الأكاديمية عنك، وما يمكنك تغييره فيه.',
			'enseignant.profil.identite' => 'الهوية المهنية',
			'enseignant.profil.pays' => 'البلد',
			'enseignant.profil.langues' => 'اللغات',
			'enseignant.profil.fuseau' => 'المنطقة الزمنية لدروسي',
			'enseignant.profil.fuseauDetail' => 'هي التي تحدد توقيت مواعيدك، لا توقيت هذا الجهاز.',
			'enseignant.profil.plafond' => 'الحد الأسبوعي',
			'enseignant.profil.plafondValeur' => ({required Object nombre}) => '⁨${nombre}⁩ ساعة في الأسبوع',
			'enseignant.profil.plafondDetail' => 'تحدده الأكاديمية.',
			'enseignant.profil.nonRenseigne' => 'غير محدد',
			'enseignant.profil.statutSection' => 'حالة الحساب',
			'enseignant.profil.statutValideDetail' => 'يمكنك التدريس والتصريح بساعاتك.',
			'enseignant.profil.statutEnAttente' => 'الملف قيد التحقق',
			'enseignant.profil.statutEnAttenteDetail' => 'تتحقق الأكاديمية من وثائقك. لا شيء آخر عليك فعله.',
			'enseignant.profil.statutProvisoire' => 'دخول مؤقت',
			'enseignant.profil.statutProvisoireDetail' => 'أنت تدرّس بالفعل. يبقى ملفك للإكمال، دون انقطاع تلقائي.',
			'enseignant.profil.statutSuspendu' => 'الحساب موقوف',
			'enseignant.profil.statutSuspenduDetail' => 'يمكنك التواصل مع الأكاديمية لمعرفة الخطوات المطلوبة.',
			'enseignant.profil.statutInconnu' => 'الحالة غير متاحة',
			'enseignant.profil.statutInconnuDetail' => 'تعذّرت قراءة حالتك.',
			'enseignant.profil.statutDivergent' => 'تغيّرت هذه الحالة للتو. أعد فتح التطبيق ليتبعها دخولك.',
			'enseignant.profil.verification' => 'التحقق من الملف',
			'enseignant.profil.verificationEnAttente' => 'قيد الانتظار',
			'enseignant.profil.verificationValidee' => 'معتمَد',
			'enseignant.profil.verificationRefusee' => 'يحتاج إلى مراجعة',
			'enseignant.profil.contratSection' => 'العقد والإقرارات',
			'enseignant.profil.contratEnseignant' => 'عقد المعلم',
			'enseignant.profil.contratConditions' => 'شروط الاستخدام',
			'enseignant.profil.contratAccuse' => 'التسجيل الصوتي وزيارة المراقبة',
			'enseignant.profil.contratDetail' => ({required Object version, required Object date}) => 'الإصدار ⁨${version}⁩، مقبول في ⁨${date}⁩',
			'enseignant.profil.contratAucun' => 'لا عقد مسجَّل',
			'enseignant.profil.contratAucunDetail' => 'لم يمر ملفك بالتوقيع بعد.',
			'enseignant.profil.contratErreur' => 'تعذّرت قراءة عقودك.',
			'enseignant.profil.contratLectureSeule' => 'هذه الوثائق للقراءة فقط.',
			'enseignant.profil.personnel' => 'إعداداتي',
			'enseignant.profil.deconnexionQuestion' => 'تسجيل الخروج من هذا الجهاز؟',
			'enseignant.profil.deconnexionConfirmer' => 'تسجيل خروجي الآن',
			'enseignant.profil.deconnexionConsequence' => 'يبقى يومك ومواعيدك ودفاترك محفوظة. ستحتاج إلى رابط دخول جديد للعودة.',
			'enseignant.profil.erreur' => 'تعذّرت قراءة ملفك الشخصي. أعد المحاولة بعد لحظة.',
			'enseignant.profil.vide' => 'لا ملف معلم',
			'enseignant.profil.videDetail' => 'ليس لهذا الحساب ملف معلم. الأكاديمية وحدها يمكنها إنشاؤه.',
			'enseignant.profil.horsLigne' => 'لا شبكة: لا يمكن تعديل شيء هنا الآن.',
			'enseignant.profil.modifierPays' => 'تعديل البلد',
			'enseignant.profil.modifierLangues' => 'تعديل اللغات',
			'enseignant.profil.languesIndice' => 'افصل بين اللغات بفاصلة',
			'enseignant.profil.enregistrer' => 'حفظ',
			'enseignant.profil.enregistre' => 'حُفظ التعديل',
			'enseignant.profil.editionErreur' => 'لم يتم التعديل. أعد المحاولة بعد لحظة.',
			'enseignant.creneaux.heureLibelle' => ({required Object jour, required Object heure}) => '⁨${jour}⁩ الساعة ⁨${heure}⁩',
			'enseignant.creneaux.aucuneHeure' => 'لم تقترح أي ساعة. دون موعد، لا يمكن أن يُقترح عليك أي فصل.',
			'enseignant.creneaux.heureEnregistree' => ({required Object heure}) => 'حُفظت ⁨${heure}⁩',
			'enseignant.creneaux.heureRetiree' => ({required Object heure}) => 'أُزيلت ⁨${heure}⁩',
			'enseignant.creneaux.retraitEngage' => ({required Object heure}) => 'أُزيلت ⁨${heure}⁩. الحصة المسندة في هذه الساعة مستمرة: اطلب إعادة إسناد لإيقافها.',
			'enseignant.creneaux.grilleErreur' => 'تعذّرت قراءة ساعاتك',
			'enseignant.creneaux.grilleErreurDetail' => 'الساعات التي حددتها لم تضِع.',
			'enseignant.creneaux.horsLigneGrille' => 'دون شبكة، تبقى ساعاتك قابلة للعرض لكن لا يمكن تعديلها.',
			'enseignant.creneaux.heureEngagee' => ({required Object heures}) => 'لديك فصل بالفعل في ⁨${heures}⁩. إزالة هذه الساعة لا تنهي الحصة: يلزم إعادة إسناد.',
			'enseignant.creneaux.heuresEngagees' => ({required Object heures}) => 'لديك فصل بالفعل في ⁨${heures}⁩. إزالة هذه الساعات لا تنهي الحصص: يلزم إعادة إسناد.',
			'enseignant.creneaux.feedErreur' => 'تعذّرت قراءة الأسر المنتظرة',
			'enseignant.creneaux.feedErreurDetail' => 'لم يضِع شيء: لم يُؤخذ أحد، وساعاتك باقية.',
			'enseignant.creneaux.horsLignePrise' => 'دون شبكة، لا يمكنك قبول طالب. تبقى الطلبات أدناه قابلة للعرض.',
			'enseignant.creneaux.horsLigneDemande' => 'دون شبكة، لن يُرسل هذا الطلب. أعد المحاولة عند عودة الاتصال.',
			'enseignant.creneaux.refusDejaPris' => 'قبِل معلم آخر هذا الطالب للتو. القائمة أدناه محدَّثة.',
			'enseignant.creneaux.refusDejaSuivi' => 'لهذا الطالب معلم بالفعل. القائمة أدناه محدَّثة.',
			'enseignant.creneaux.refusCreneauRetire' => 'لم تعد هذه الأسرة تقترح هذا الموعد. القائمة أدناه محدَّثة.',
			'enseignant.creneaux.refusHorsMesHeures' => 'لم يعد هذا الموعد ضمن ساعاتك. أعد إضافته في «ساعاتي» لتتمكن من قبوله.',
			'enseignant.creneaux.refusPlafond' => 'بلغت الحد الأقصى لطلابك. اطلب زيادة لتتابع طالبًا آخر.',
			'enseignant.creneaux.mesDisponibilites' => 'أوقات توفري',
			'enseignant.creneaux.ajouterCreneau' => 'إضافة موعد',
			'enseignant.creneaux.heure' => ({required Object heure}) => 'الساعة ⁨${heure}⁩',
			'enseignant.creneaux.classesDisponibles' => 'الفصول المتاحة',
			'enseignant.creneaux.etatDisponible' => 'متاح',
			'enseignant.creneaux.etatEnAttente' => 'بانتظار الاعتماد',
			'enseignant.creneaux.etatLimite' => 'بلغت الحد الأقصى للعبء',
			'enseignant.creneaux.limiteDetail' => 'عبؤك الحالي لا يسمح بحجز فصل إضافي.',
			'enseignant.creneaux.aucuneClasse' => 'لا فصل متوافق الآن',
			'enseignant.creneaux.aucuneClasseDetail' => 'عدّل أوقات توفرك إن تغيّر جدولك.',
			'enseignant.creneaux.reserver' => 'حجز هذا الفصل',
			'enseignant.creneaux.demandeTransmise' => 'أُرسل طلبك.',
			'enseignant.creneaux.demandeTransmiseDetail' => 'سيظهر في فصولك بعد التأكيد.',
			'enseignant.creneaux.confirmerTitre' => 'تأكيد هذا الفصل؟',
			'enseignant.creneaux.confirmer' => 'تأكيد هذا الفصل',
			'enseignant.creneaux.revenir' => 'رجوع',
			'enseignant.creneaux.cleNiveau' => 'المستوى',
			'enseignant.creneaux.cleLangue' => 'اللغة',
			'enseignant.creneaux.cleRecurrence' => 'التكرار',
			'enseignant.creneaux.cleFuseau' => 'المنطقة الزمنية المرجعية',
			'enseignant.creneaux.cleHeureLocale' => 'التوقيت المحلي',
			'enseignant.creneaux.cleDuree' => 'المدة',
			'enseignant.creneaux.duree' => ({required Object minutes}) => '⁨${minutes}⁩ دقيقة',
			'enseignant.revue.titre' => 'مراجعة الفصل',
			'enseignant.revue.titreClasse' => ({required Object classe}) => 'مراجعة الفصل ⁨${classe}⁩',
			'enseignant.revue.aucuneAnomalie' => 'لا شيء يتطلب انتباهك.',
			'enseignant.revue.erreur' => 'تعذّرت قراءة المراجعة.',
			'enseignant.revue.erreurDetail' => 'ربما ليس هذا الفصل فصلك، أو فشلت القراءة.',
			'enseignant.revue.pasDeDecision' => 'أنت تُبلغ، والأكاديمية تقرر: النقل وإعادة التوجيه لا يُقرَّران من هنا.',
			'enseignant.revue.typeGate' => 'مرحلة قادمة',
			'enseignant.revue.typeCorridor' => 'طالب خارج المسار المتوقع',
			'enseignant.revue.typeTransfert' => 'اقتراح نقل',
			'enseignant.revue.typeReorientation' => 'اقتراح إعادة توجيه',
			'compte.themeContexte' => 'اختر مظهر التطبيق. يتم التغيير فورًا ويبقى على هذا الجهاز، ويمكنك تعديله في أي وقت.',
			'compte.themeSysteme' => 'النظام',
			'compte.themeSystemeDetail' => 'يتبع إعداد جهازك',
			'compte.themeClair' => 'فاتح',
			'compte.themeClairDetail' => 'خلفية فاتحة مهما كان إعداد جهازك',
			'compte.themeSombre' => 'داكن',
			'compte.themeSombreDetail' => 'خلفية داكنة مهما كان إعداد جهازك',
			'tc.bibliotheque.sections.groupe' => 'المواد المعروضة',
			'tc.bibliotheque.sections.continuer' => 'متابعة',
			'tc.bibliotheque.sections.pourCeGroupe' => 'لهذا الفصل',
			'tc.bibliotheque.sections.recents' => 'الأحدث',
			'tc.bibliotheque.sections.tousLesSupports' => 'كل المواد',
			'tc.bibliotheque.sections.resultats' => 'النتائج',
			'tc.bibliotheque.titre' => 'المكتبة',
			'tc.bibliotheque.rechercheIndication' => 'العنوان أو المستوى أو السورة أو الصفحة',
			'tc.bibliotheque.rechercheLibelle' => 'البحث عن مادة',
			'tc.bibliotheque.effacerRecherche' => 'عرض الكل',
			'tc.bibliotheque.filtre.type' => 'النوع',
			'tc.bibliotheque.filtre.disponibilite' => 'التوفر',
			'tc.bibliotheque.vide.message' => 'لا مادة منشورة حتى الآن',
			'tc.bibliotheque.vide.invitation' => 'سيضع معلموك هنا مواد دروسك.',
			'tc.bibliotheque.aucunResultat.message' => 'لا مادة مطابقة',
			'tc.bibliotheque.aucunResultat.invitation' => 'جرّب كلمة أخرى، أو خفّف عوامل التصفية.',
			'tc.bibliotheque.indisponible.message' => 'المكتبة غير متاحة مؤقتًا',
			'tc.bibliotheque.indisponible.action' => 'إعادة المحاولة',
			'tc.bibliotheque.introuvable.message' => 'هذه المادة غير مفتوحة لك',
			'tc.bibliotheque.introuvable.invitation' => 'ربما سُحبت، أو هي مخصصة لفصل آخر. يمكن لمعلمك أن يعيد فتحها لك.',
			'tc.bibliotheque.offline.aTelecharger' => 'للتنزيل',
			'tc.bibliotheque.offline.enCours' => 'جارٍ التنزيل',
			'tc.bibliotheque.offline.enCache' => 'في الذاكرة المؤقتة',
			'tc.bibliotheque.offline.telecharge' => 'تم التنزيل',
			'tc.bibliotheque.offline.indisponible' => 'غير متاحة دون اتصال',
			'tc.bibliotheque.type.quran' => 'القرآن',
			'tc.bibliotheque.type.texteStructure' => 'نص',
			'tc.bibliotheque.type.pdf' => 'PDF',
			'tc.bibliotheque.type.image' => 'صورة',
			'tc.bibliotheque.type.lecon' => 'درس',
			'tc.bibliotheque.detail.titre' => 'المادة',
			'tc.bibliotheque.detail.capacites' => 'ما تتيحه هذه المادة',
			'tc.bibliotheque.detail.niveaux' => 'المستويات',
			'tc.bibliotheque.detail.sansVersion' => 'لا نسخة منشورة: لا شيء للفتح الآن.',
			'tc.bibliotheque.detail.apercuIndisponible' => 'معاينة هذا التنسيق غير متاحة بعد في التطبيق. يمكنك حفظ نسخة منه.',
			'tc.bibliotheque.detail.renduCoran' => 'يُفتح القرآن في القارئ المخصص له.',
			'tc.bibliotheque.action.telecharger' => 'إتاحتها دون اتصال',
			'tc.bibliotheque.action.liberer' => 'تحرير المساحة',
			'tc.bibliotheque.action.enregistrerCopie' => 'حفظ نسخة',
			'tc.bibliotheque.message.copieEnregistree' => 'حُفظت النسخة',
			'tc.bibliotheque.message.copieImpossible' => 'هذه النسخة غير متاحة الآن',
			'tc.bibliotheque.message.telechargementImpossible' => 'هذه المادة غير متاحة دون اتصال بعد',
			'tc.bibliotheque.message.horsLigneNonTelecharge' => 'تتاح بعد تنزيلها أو عند عودة الاتصال',
			'tc.bibliotheque.message.aucunTelechargement' => 'لا ملف للتنزيل في هذه النسخة.',
			'tc.bibliotheque.classe.titre' => 'اختيار مادة',
			'tc.bibliotheque.classe.sousTitre' => 'المادة المختارة تحل محل المعروضة. يستمر الدرس.',
			'tc.groupe.enseignant.sayyid' => 'سيد',
			'tc.groupe.enseignant.sayyida' => 'سيدة',
			'tc.groupe.enseignant.photoManquante' => 'الصورة مطلوبة',
			'tc.groupe.enseignant.photoManquanteDetail' => 'لم تُسجَّل صورة المعلم بعد.',
			'tc.groupe.mesGroupes.titre' => 'فصولي',
			'tc.groupe.mesGroupes.aucun' => 'لا فصل حتى الآن',
			'tc.groupe.mesGroupes.aucunDetail' => 'ستضعك الأكاديمية في فصل حين يتوفر موعد يناسبك.',
			'tc.groupe.commun.erreur' => 'تعذّرت قراءة فصولك',
			'tc.groupe.commun.reessayer' => 'إعادة المحاولة',
			'tc.groupe.carte.ouvrir' => ({required Object libelle}) => 'فتح الفصل ⁨${libelle}⁩',
			'tc.groupe.carte.capacite' => ({required Object membres, required Object seuil}) => '⁨${membres}⁩ / ⁨${seuil}⁩',
			'tc.groupe.carte.capacitePhrase' => ({required Object membres, required Object seuil}) => '⁨${membres}⁩ طلاب من ⁨${seuil}⁩ مقاعد',
			'tc.groupe.carte.complet' => 'مكتمل',
			'tc.groupe.carte.prochainCours' => 'الدرس القادم',
			'tc.groupe.carte.aucuneSeance' => 'لا حصة مقررة',
			'tc.groupe.carte.aucuneSeanceDetail' => 'لم يُحدَّد جدول هذا الفصل بعد.',
			'tc.groupe.carte.duree' => ({required Object valeur}) => 'المدة ⁨${valeur}⁩',
			'tc.groupe.carte.dureeLibelle' => 'المدة',
			'tc.groupe.carte.rejoindre' => 'انضمام',
			'tc.groupe.cours.coursEtNiveau' => ({required Object cours, required Object niveau}) => '⁨${cours}⁩ · ⁨${niveau}⁩',
			'tc.groupe.temps.dansMinutes' => ({required Object minutes}) => 'الدرس بعد ⁨${minutes}⁩ دقيقة',
			'tc.groupe.temps.dansHeures' => ({required Object heures, required Object minutes}) => 'الدرس بعد ⁨${heures}⁩ س ⁨${minutes}⁩ د',
			'tc.groupe.temps.imminent' => 'الدرس وشيك',
			'tc.groupe.temps.salleOuverte' => ({required Object reste}) => 'القاعة مفتوحة · ⁨${reste}⁩',
			'tc.groupe.temps.salleOuverteCourt' => 'القاعة مفتوحة',
			'tc.groupe.temps.attente' => 'أنت في القاعة. لم يبدأ الدرس بعد.',
			'tc.groupe.temps.attenteDetail' => 'وقت الانتظار هذا لا يُحتسب في حضورك.',
			'tc.groupe.temps.enSalle' => 'في القاعة',
			'tc.groupe.temps.resteMinutes' => ({required Object minutes}) => 'بقيت ⁨${minutes}⁩ دقيقة',
			'tc.groupe.temps.resteHeures' => ({required Object heures, required Object minutes}) => 'بقي ⁨${heures}⁩ س ⁨${minutes}⁩ د',
			'tc.groupe.temps.enCours' => ({required Object reste}) => 'حصة مباشرة · ⁨${reste}⁩',
			'tc.groupe.temps.enDirect' => 'مباشر',
			'tc.groupe.temps.prolongee' => 'الحصة ما زالت مباشرة',
			'tc.groupe.temps.depassement' => 'تجاوز الوقت',
			'tc.groupe.temps.terminee' => 'انتهى الدرس',
			'tc.groupe.duree.minutes' => ({required Object minutes}) => '⁨${minutes}⁩ د',
			'tc.groupe.duree.heures' => ({required Object heures}) => '⁨${heures}⁩ س',
			'tc.groupe.duree.heuresMinutes' => ({required Object heures, required Object minutes}) => '⁨${heures}⁩ س ⁨${minutes}⁩ د',
			'tc.groupe.horloges.votreHeure' => 'توقيتك',
			'tc.groupe.horloges.chezEnseignant' => ({required Object nomme}) => 'عند ⁨${nomme}⁩',
			'tc.groupe.horloges.heureGroupe' => 'توقيت الفصل',
			'tc.groupe.horloges.heureEtVille' => ({required Object heure, required Object ville}) => '⁨${heure}⁩ ⁨${ville}⁩',
			'tc.groupe.dst.j30' => 'تغيير التوقيت بعد شهر',
			'tc.groupe.dst.j7' => 'تغيير التوقيت الأسبوع القادم',
			'tc.groupe.dst.j1' => 'تغيير التوقيت غدًا',
			'tc.groupe.dst.detail' => ({required Object avant, required Object apres}) => 'سينتقل درسك من ⁨${avant}⁩ إلى ⁨${apres}⁩.',
			'tc.groupe.session.conseilAppareil' => 'يُنصح بجهاز لوحي أو حاسوب للدرس. الهاتف مدعوم أيضًا.',
			'tc.groupe.espace.retour' => 'فصولي',
			'tc.groupe.espace.avantProchainCours' => 'قبل الدرس القادم',
			'tc.groupe.espace.aucuneAction' => 'لا شيء للتحضير الآن',
			'tc.groupe.espace.bibliotheque' => 'المكتبة',
			'tc.groupe.espace.bibliothequeVoirTout' => 'عرض الكل',
			'tc.groupe.espace.progression' => 'التقدم',
			'tc.groupe.espace.roster' => 'طلاب الفصل',
			'tc.groupe.espace.reprendreLeCours' => 'استئناف الدرس',
			'tc.groupe.espace.introuvable' => 'هذا الفصل غير مفتوح لك',
			'tc.groupe.espace.introuvableDetail' => 'ربما أُغلق، أو يخص ملفًا آخر.',
			'tc.groupe.emplacement.nonBranche' => 'قريبًا',
			'tc.groupe.emplacement.nonBrancheDetail' => 'سيُربط هذا المحتوى بهذه المساحة قريبًا.',
			'tc.coran.modes.mushaf' => 'صفحة المصحف',
			'tc.coran.modes.verset' => 'قراءة مكبَّرة',
			'tc.coran.modes.focus' => 'التركيز',
			'tc.coran.modes.choisir' => 'طريقة القراءة',
			'tc.coran.mushaf.coteDroite' => 'الصفحة اليمنى',
			'tc.coran.mushaf.coteGauche' => 'الصفحة اليسرى',
			'tc.coran.mushaf.ouverture' => ({required Object droite, required Object gauche}) => 'الصفحتان المفتوحتان ⁨${droite}⁩ و⁨${gauche}⁩',
			'tc.coran.fidelite.approchee' => 'تنسيق تقريبي',
			'tc.coran.fidelite.approcheeDetail' => 'آيات هذه الصفحة هي بالضبط آيات صفحة مصحف المدينة. أما توزيعها على الأسطر فهو توزيع هذه الشاشة: لم يُستورد بعد تقسيم الأسطر في الطبعة.',
			'tc.coran.fidelite.fidele' => 'تنسيق الطبعة',
			'tc.coran.zoom.bride' => 'التكبير محدود بالعرض: بعده ستنقسم كلمة.',
			'tc.coran.zoom.valeur' => ({required Object pourcent}) => '⁨${pourcent}⁩ %',
			'tc.coran.zoom.renvoiLectureAgrandie' => 'لتكبير النص، انتقل إلى القراءة المكبَّرة: صفحة المصحف تحافظ على هيئتها.',
			'tc.coran.navigation.titre' => 'الانتقال إلى',
			'tc.coran.navigation.ouvrir' => 'الانتقال إلى صفحة',
			'tc.coran.navigation.champ' => 'صفحة أو سورة أو جزء أو مرجع',
			'tc.coran.navigation.indice' => 'مثلًا 18، الكهف، الجزء 15، 2:255',
			'tc.coran.navigation.limite' => 'يشمل البحث أرقام الصفحات والمراجع وأسماء السور. البحث في نص القرآن غير متاح بعد.',
			'tc.coran.navigation.aucunResultat' => 'لم يُعثر على مرجع',
			'tc.coran.navigation.aucunResultatDetail' => 'جرّب رقم صفحة، أو اسم سورة، أو مرجعًا مثل 2:255.',
			'tc.coran.navigation.pageNumero' => ({required Object page}) => 'الصفحة ⁨${page}⁩',
			'tc.coran.reprise.groupe' => 'استئناف الدرس',
			'tc.coran.reprise.groupeDetail' => ({required Object page}) => 'كان الفصل في الصفحة ⁨${page}⁩',
			_ => null,
		} ?? switch (path) {
			'tc.coran.focus.aucunePlage' => 'لا مقطع مُبرَز',
			'tc.coran.focus.aucunePlageDetail' => 'يتبع التركيز المقطع الذي يحدده المعلم. خارج الفصل، يتوسط الصفحة المفتوحة.',
			'tc.coran.focus.quitter' => 'الخروج من التركيز',
			'tc.outils.dock.titre' => 'الأدوات',
			'tc.outils.dock.deplacer' => 'نقل الأدوات',
			'tc.outils.dock.position.bas' => 'في الأسفل',
			'tc.outils.dock.position.gauche' => 'على اليسار',
			'tc.outils.dock.position.droite' => 'على اليمين',
			'tc.outils.dock.bibliotheque' => 'المكتبة',
			'tc.outils.dock.focus' => 'التركيز',
			'tc.outils.dock.marquer' => 'تعليم',
			'tc.outils.dock.masquer' => 'إخفاء',
			'tc.outils.dock.stylet' => 'القلم',
			'tc.outils.dock.pointeur' => 'المؤشر',
			'tc.outils.dock.revision' => 'المراجعة',
			'tc.outils.intention.aApprendre' => 'للحفظ',
			'tc.outils.intention.aRevoir' => 'للمراجعة',
			'tc.outils.intention.aRenforcer' => 'للتثبيت',
			'tc.outils.intention.aEntretenir' => 'للتعاهد',
			'tc.outils.intention.pourEvaluation' => 'للتقييم',
			'tc.outils.trait.stylet' => 'القلم',
			'tc.outils.trait.surligneur' => 'تظليل',
			'tc.outils.trait.gomme' => 'الممحاة',
			'tc.outils.trait.annuler' => 'تراجع',
			'tc.outils.trait.plus' => 'المزيد',
			'tc.outils.trait.ardoise' => 'لوح الملاحظات، اختياري: يبقى الدرس مقروءًا دونه',
			'tc.outils.trait.effacerDernier' => 'مسح آخر خط لي',
			'tc.outils.portee.temporaire' => 'وقت الشرح',
			'tc.outils.portee.seance' => 'حتى نهاية الدرس',
			'tc.outils.portee.enregistree' => 'حفظ',
			'tc.outils.portee.aide' => 'إلى متى نحتفظ بهذه الملاحظات؟',
			'tc.outils.marquer.titre' => 'تعليم هذا المقطع',
			'tc.outils.marquer.aide' => 'اختر ما يحتاجه هذا المقطع.',
			'tc.outils.marquer.retirer' => 'إزالة العلامة',
			'tc.outils.revision.titre' => 'للتحضير',
			'tc.outils.revision.aide' => 'يصبح المقطع المحدد عملًا للتحضير.',
			'tc.outils.revision.groupeEntier' => 'الفصل كله',
			'tc.outils.revision.consigne' => 'تعليمة قصيرة (اختياري)',
			'tc.outils.revision.creer' => 'تكليف بالعمل',
			'tc.outils.revision.posee' => 'تم التكليف بعمل للتحضير',
			'tc.outils.masquer.reveler' => 'إظهار',
			'tc.outils.masquer.refermer' => 'إخفاء من جديد',
			'tc.outils.masquer.tout' => 'إظهار الكل',
			'tc.outils.focus.quitter' => 'الخروج من التركيز',
			'tc.outils.annotation.ancrageDegrade' => 'لا مرجع نصيًا لهذا المقطع: ستتبع الملاحظة الصفحة لا الكلمات.',
			'tc.outils.annotation.horsPage' => 'الملاحظات مخفية: مقطعها ليس على الشاشة.',
			'tc.outils.annotation.aucuneSelection' => 'حدّد مقطعًا أولًا.',
			'tc.classe.entete.titreEnseignant.sayyid' => 'سيد',
			'tc.classe.entete.titreEnseignant.sayyida' => 'سيدة',
			'tc.classe.entete.resteMinutes' => ({required Object minutes}) => 'بقيت ⁨${minutes}⁩ دقيقة',
			'tc.classe.entete.resteHeuresMinutes' => ({required Object heures, required Object minutes}) => 'بقي ⁨${heures}⁩ س ⁨${minutes}⁩ د',
			'tc.classe.entete.coursEnCours' => 'الحصة ما زالت مباشرة',
			'tc.classe.entete.photoManquante' => 'صورة المعلم غير موجودة',
			'tc.classe.roster.titre' => 'الطلاب',
			'tc.classe.roster.compteur' => ({required Object presents, required Object attendus}) => 'الطلاب: ⁨${presents}⁩ حاضرون من ⁨${attendus}⁩ منتظَرين',
			'tc.classe.roster.indisponible' => 'قائمة الطلاب غير متاحة',
			'tc.classe.roster.indisponibleDetail' => 'تعذّرت قراءة حالات طلابك. يستمر الدرس.',
			'tc.classe.roster.vide' => 'لا طالب مسجَّل',
			'tc.classe.roster.videDetail' => 'لا طالب مسجَّل في هذه الحصة.',
			'tc.classe.roster.ouvrirFiche' => ({required Object prenom}) => 'فتح بطاقة ⁨${prenom}⁩',
			'tc.classe.roster.places' => ({required Object inscrits, required Object plafond}) => '⁨${inscrits}⁩ / ⁨${plafond}⁩ مقاعد',
			'tc.classe.etat.inconnu' => 'حالة غير معروفة',
			'tc.classe.etat.attendu' => 'منتظَر',
			'tc.classe.etat.enConnexion' => 'جارٍ الاتصال',
			'tc.classe.etat.present' => 'حاضر',
			'tc.classe.etat.enRetard' => 'متأخر',
			'tc.classe.etat.deconnecte' => 'غير متصل',
			'tc.classe.etat.enReconnexion' => 'جارٍ إعادة الاتصال',
			'tc.classe.etat.sorti' => 'خرج',
			'tc.classe.etat.absent' => 'غائب',
			'tc.classe.fiche.niveau' => 'المستوى',
			'tc.classe.fiche.objectif' => 'الهدف الحالي',
			'tc.classe.fiche.derniereSeance' => 'آخر حصة',
			'tc.classe.fiche.page' => ({required Object page}) => 'الصفحة ⁨${page}⁩',
			'tc.classe.fiche.travailEnCours' => ({required Object nombre}) => '⁨${nombre}⁩ عنصر',
			'tc.classe.fiche.aReprendre' => 'للاستئناف',
			'tc.classe.fiche.presenceRecente' => 'الحضور الأخير',
			'tc.classe.fiche.assiduite' => ({required Object presences, required Object total}) => '⁨${presences}⁩ / ⁨${total}⁩ دروس',
			'tc.classe.fiche.travailActuel' => 'العمل الحالي',
			'tc.classe.fiche.interfaceGuidee' => 'وضع إمكانية الوصول',
			'tc.classe.fiche.sansPedagogie' => 'المتابعة التعليمية غير متاحة',
			'tc.classe.fiche.sansPedagogieDetail' => 'المسار والأهداف والعمل الجاري غير مفتوحة للمعلم بعد.',
			'tc.classe.action.rappel' => 'نداء هادئ',
			'tc.classe.action.reciter' => 'اختيار للتلاوة',
			'tc.classe.action.noter' => 'تدوين ملاحظة',
			'tc.classe.action.signaler' => 'الإشارة إلى حاجة',
			'tc.classe.action.contexte' => 'فتح السياق',
			'tc.classe.rappel.recu' => 'المعلم يناديك',
			'tc.classe.rappel.echec' => 'تعذّر إرسال النداء',
			'tc.classe.rappel.echecDroit' => 'دخولك إلى هذه الحصة لا يسمح بنداء طالب',
			'tc.classe.rappel.cooldown' => ({required Object secondes}) => 'تم النداء. مجددًا بعد ⁨${secondes}⁩ ث',
			'tc.classe.recitation.titre' => 'التلاوة',
			'tc.classe.recitation.actif' => ({required Object prenom}) => '⁨${prenom}⁩ يتلو',
			'tc.classe.recitation.pastille' => 'يتلو',
			'tc.classe.recitation.suivants' => 'بعد ذلك',
			'tc.classe.recitation.personne' => 'لا أحد يتلو',
			'tc.classe.recitation.arreter' => 'إيقاف التلاوة',
			'tc.classe.support.aucun' => 'لا مادة معروضة',
			'tc.classe.support.aucunDetail' => 'افتح المكتبة لعرض مادة على الفصل.',
			'tc.classe.support.bibliotheque' => 'المكتبة',
			'tc.classe.support.bibliothequeAbsente' => 'المكتبة غير موصولة',
			'tc.classe.support.bibliothequeAbsenteDetail' => 'سيتاح اختيار المادة بمجرد دمج الفهرس.',
			'tc.classe.commandes.micro' => 'فتح الميكروفون',
			'tc.classe.commandes.microFermer' => 'إغلاق الميكروفون',
			'tc.classe.commandes.camera' => 'فتح الكاميرا',
			'tc.classe.commandes.cameraFermer' => 'إغلاق الكاميرا',
			'tc.classe.commandes.microCoupe' => 'الميكروفون مغلق',
			'tc.classe.commandes.quitter' => 'مغادرة',
			'tc.classe.commandes.quitterQuestion' => 'مغادرة الدرس؟',
			'tc.classe.commandes.quitterConsequence' => 'سيُسجَّل خروجك. يمكنك العودة ما دامت الحصة مفتوحة.',
			'tc.classe.commandes.fermerBibliotheque' => 'إغلاق المكتبة',
			'tc.classe.scene.vide' => 'أنت وحدك في القاعة الآن',
			'tc.classe.scene.sansImage' => 'دون صورة',
			'tc.classe.reseau.bon' => 'الشبكة جيدة',
			'tc.classe.reseau.mediocre' => 'الشبكة غير مستقرة',
			'tc.classe.reseau.perdu' => 'انقطعت الشبكة',
			'tc.classe.attente.materiel' => 'جارٍ التحقق من الميكروفون',
			'tc.classe.attente.ouverture' => 'جارٍ فتح الدرس',
			'tc.classe.attente.connexion' => 'جارٍ الاتصال بالدرس',
			'tc.classe.attente.refus' => 'الدرس غير متاح الآن',
			'tc.classe.lien.instable' => 'الاتصال غير مستقر',
			'tc.classe.lien.reconnexion' => 'جارٍ إعادة الاتصال',
			'tc.classe.lien.retabli' => 'عاد الاتصال',
			'tc.classe.lien.echec' => 'انقطع الاتصال',
			'tc.classe.lien.retourDeSuspension' => 'أوقف النظام الدرس مؤقتًا. جارٍ التحقق من الاتصال.',
			'tc.classe.barre.titre' => 'حصة مباشرة',
			'tc.classe.barre.revenir' => ({required Object groupe}) => 'العودة إلى درس ⁨${groupe}⁩',
			'tc.classe.prevol.titre' => 'قبل فتح الدرس',
			'tc.classe.prevol.microOk' => 'تم العثور على ميكروفون',
			'tc.classe.prevol.microAbsent' => 'لا ميكروفون صالح',
			'tc.classe.prevol.cameraOk' => 'تم العثور على كاميرا',
			'tc.classe.prevol.cameraAbsente' => 'لا كاميرا. يبقى الدرس ممكنًا.',
			'tc.classe.prevol.permissionRefusee' => 'رُفض الوصول إلى الميكروفون. اسمح به لفتح الدرس.',
			'tc.classe.prevol.reessayer' => 'التحقق من جديد',
			'tc.classe.observation.restant' => ({required Object secondes}) => 'بقيت ⁨${secondes}⁩ ث',
			'tc.realtime.transport.partage_indisponible' => 'مشاركة المادة غير متاحة على هذا الخادم. يستمر الدرس، لكن الأجهزة الأخرى لن تتبع الصفحة.',
			'tc.realtime.etat.restauration_impossible' => 'تعذّر استرجاع المادة الجارية. اطلب من المعلم أن يعرضها من جديد.',
			'tc.observation.entree.titre' => 'متابعة الحصة',
			'tc.observation.entree.tuteurIntro' => 'يمكنك مشاهدة درس طفلك لوقت قصير. يبقى الميكروفون والكاميرا مغلقين.',
			'tc.observation.entree.adminIntro' => 'اختر طريقتك قبل الدخول. لن تتغير بعد ذلك.',
			'tc.observation.entree.controleurIntro' => 'تدخل في متابعة غير مرئية. لا ميكروفون ولا كاميرا.',
			'tc.observation.entree.entrer' => 'دخول',
			'tc.observation.entree.modeDiscret' => 'المتابعة بهدوء',
			'tc.observation.entree.modeDiscretDetail' => 'غير مرئي للمشاركين. دون ميكروفون ولا كاميرا، ودون إعلان.',
			'tc.observation.entree.modeVisible' => 'الانضمام إلى الفصل',
			'tc.observation.entree.modeVisibleDetail' => 'مرئي للجميع باسم إدارة Rewayah. الميكروفون والكاميرا مسموحان، ويُعلَن عن الدخول.',
			'tc.observation.entree.nomInstitutionnel' => 'إدارة Rewayah',
			'tc.observation.entree.visiteJournalisee' => 'زيارة مسجَّلة في السجل: الهوية، والحصة، والدخول، والخروج، والمدة.',
			'tc.observation.entree.roleSansObservation' => 'حسابك لا يتابع الحصص.',
			'tc.observation.entree.retourClasse' => 'العودة إلى الفصل',
			'tc.observation.explication.titre' => 'لمحة عن تعلّمه',
			'tc.observation.explication.regleUne' => ({required Object n, required Object duree}) => '⁨${n}⁩ زيارة مدتها ⁨${duree}⁩',
			'tc.observation.explication.regle' => ({required Object n, required Object duree}) => '⁨${n}⁩ زيارات مدة كل منها ⁨${duree}⁩',
			'tc.observation.explication.regleDetail' => 'لكل حصة ولكل وليّ أمر، حتى لو كان عدة من أطفالك في الفصل.',
			'tc.observation.explication.ecoute' => 'استمع إلى المعلم والطلاب',
			'tc.observation.explication.ecouteDetail' => 'تسمع المعلم والطلاب الذين يتكلمون، ومنهم طفلك.',
			'tc.observation.explication.sansMedia' => 'دون ميكروفون ولا كاميرا',
			'tc.observation.explication.sansMediaDetail' => 'يبقى الميكروفون والكاميرا معطَّلين حتى لا يُقاطَع الفصل.',
			'tc.observation.explication.revenir' => 'إن كان طالب آخر يتلو في زيارتك الأولى، يمكنك العودة لاحقًا للاستماع إلى طفلك.',
			'tc.observation.explication.ecourtee' => 'الزيارة التي تُغادَر قبل نهايتها تُحتسب زيارة كاملة: الوقت غير المستخدم لا يُرحَّل.',
			'tc.observation.explication.sansIntervenir' => 'حفاظًا على التركيز، تتابع دون أن تتدخل.',
			'tc.observation.explication.informes' => 'طفلك ومعلمه على علم.',
			'tc.observation.explication.observer' => 'المتابعة الآن',
			'tc.observation.explication.pasMaintenant' => 'ليس الآن',
			'tc.observation.explication.restanteUne' => ({required Object restantes, required Object max}) => '⁨${restantes}⁩/⁨${max}⁩ زيارة متبقية لهذه الحصة',
			'tc.observation.explication.restantes' => ({required Object restantes, required Object max}) => '⁨${restantes}⁩/⁨${max}⁩ زيارات متبقية لهذه الحصة',
			'tc.observation.explication.aucuneRestante' => 'لا زيارة متبقية لهذه الحصة',
			'tc.observation.disponibilite.visitesEpuiseesTitre' => 'لا زيارة متبقية لهذه الحصة',
			'tc.observation.disponibilite.visitesEpuisees' => 'استخدمت زياراتك. يمكنك متابعة الحصة القادمة.',
			'tc.observation.disponibilite.tempsEpuiseTitre' => 'انتهى وقت المتابعة',
			'tc.observation.disponibilite.tempsEpuise' => 'استُخدم وقت متابعتك لهذه الحصة. يمكنك متابعة الحصة القادمة.',
			'tc.observation.disponibilite.seanceNonCommenceeTitre' => 'لم تبدأ الحصة بعد',
			'tc.observation.disponibilite.seanceNonCommencee' => 'تُفتح المتابعة أثناء الحصة.',
			'tc.observation.disponibilite.seanceTermineeTitre' => 'انتهت الحصة',
			'tc.observation.disponibilite.seanceTerminee' => 'يمكنك متابعة الحصة القادمة.',
			'tc.observation.disponibilite.seanceNonTenueTitre' => 'هذه الحصة لا تُعقد',
			'tc.observation.disponibilite.seanceNonTenue' => 'أُلغيت أو أُجّلت أو لم تُعقد.',
			'tc.observation.disponibilite.horsFenetreTitre' => 'الحصة غير مفتوحة الآن',
			'tc.observation.disponibilite.horsFenetre' => 'المتابعة ممكنة أثناء الحصة فقط.',
			'tc.observation.disponibilite.desactiveeTitre' => 'المتابعة مغلقة لهذا الفصل',
			'tc.observation.disponibilite.desactivee' => 'أغلقت الإدارة متابعة هذا الفصل.',
			'tc.observation.disponibilite.lienAbsentTitre' => 'لا أحد من أطفالك في هذه الحصة',
			'tc.observation.disponibilite.lienAbsent' => 'المتابعة مخصصة لأولياء أمور طلاب الحصة.',
			'tc.observation.disponibilite.enfantAbsentTitre' => 'طفلك ليس في الحصة',
			'tc.observation.disponibilite.enfantAbsent' => 'تُفتح المتابعة حين يكون طفلك حاضرًا.',
			'tc.observation.disponibilite.presenceTitre' => 'جارٍ التحقق من الحضور',
			'tc.observation.disponibilite.presence' => 'تُفتح المتابعة بمجرد تأكيد حضور طفلك.',
			'tc.observation.disponibilite.visiteOuverteTitre' => 'زيارة مفتوحة بالفعل',
			'tc.observation.disponibilite.visiteOuverte' => 'إحدى زياراتك ما زالت مفتوحة لهذه الحصة، على هذا الجهاز أو على غيره. وهي تُحتسب من زياراتك.',
			'tc.observation.disponibilite.fermeeTitre' => 'المتابعة غير مفتوحة بعد',
			'tc.observation.disponibilite.fermee' => 'متابعة أولياء الأمور للحصص غير مفتوحة بعد. ستُقترح هنا بمجرد فتحها.',
			'tc.observation.disponibilite.reseauTitre' => 'تعذّر التحقق',
			'tc.observation.disponibilite.reseau' => 'تعذّر التحقق من توفر المتابعة. لم تبدأ أي زيارة.',
			'tc.observation.disponibilite.capaciteTitre' => 'المتابعة غير متاحة',
			'tc.observation.disponibilite.capacite' => 'المتابعة غير متاحة الآن.',
			'tc.observation.connexion.titre' => 'الاتصال والتحقق',
			'tc.observation.connexion.phrase' => 'يجري التحقق من زياراتك المتبقية. تبدأ الزيارة بمجرد قبول الدخول، بما في ذلك اتصال الفيديو.',
			'tc.observation.connexion.enCours' => 'جارٍ الاتصال والتحقق',
			'tc.observation.connexion.prolongee' => 'ابقَ على هذه الصفحة: التحقق مستمر.',
			'tc.observation.connexion.impossibleTitre' => 'تعذّر الاتصال',
			'tc.observation.connexion.impossible' => 'لم يتم الدخول إلى الحصة. تحقّق من اتصالك ثم أعد المحاولة: سيُعاد التحقق من زياراتك المتبقية.',
			'tc.observation.duree.secondeUne' => ({required Object n}) => '⁨${n}⁩ ثانية',
			'tc.observation.duree.secondes' => ({required Object n}) => '⁨${n}⁩ ثوانٍ',
			'tc.observation.duree.minuteUne' => ({required Object n}) => '⁨${n}⁩ دقيقة',
			'tc.observation.duree.minutes' => ({required Object n}) => '⁨${n}⁩ دقائق',
			'tc.observation.duree.minutesSecondes' => ({required Object m, required Object s}) => '⁨${m}⁩ د ⁨${s}⁩ ث',
			'tc.observation.refus.politiqueDesactivee' => 'المتابعة معطَّلة لهذا الفصل.',
			'tc.observation.refus.quotaVisites' => 'استخدمت زياراتك لهذه الحصة بالفعل.',
			'tc.observation.refus.tempsEpuise' => 'نفد وقت متابعتك لهذه الحصة.',
			'tc.observation.refus.lienTuteur' => 'لست مرتبطًا بأي طالب في هذه الحصة.',
			'tc.observation.refus.seanceNonActive' => 'الحصة ليست جارية.',
			'tc.observation.refus.horsFenetre' => 'القاعة غير مفتوحة في هذا الوقت.',
			'tc.observation.refus.indisponible' => 'المتابعة غير متاحة الآن.',
			'tc.observation.refus.capaciteAbsente' => 'المتابعة غير مفعَّلة بعد في هذا التثبيت.',
			'tc.observation.visite.titre' => 'المتابعة جارية',
			'tc.observation.visite.quitter' => 'مغادرة',
			'tc.observation.visite.supportIndisponible' => 'تظهر هنا المادة التي يشاركها المعلم.',
			'tc.observation.visite.enseignant' => 'المعلم',
			'tc.observation.visite.monEnfant' => 'طفلك',
			'tc.observation.visite.budgetIncertain' => 'الوقت المتبقي غير مؤكَّد من الخادم.',
			'tc.observation.visite.videoIndisponible' => 'تعذّر فتح فيديو الحصة. يستمر احتساب وقت متابعتك.',
			'tc.observation.visite.sortieNonConfirmee' => 'تعذّر تأكيد نهاية زيارتك. سيغلقها الخادم.',
			'tc.observation.visite.restantes' => 'متبقية',
			'tc.observation.visite.decompteLu' => ({required Object duree}) => 'الوقت المتبقي: ⁨${duree}⁩',
			'tc.observation.visite.enDirect' => 'مباشر',
			'tc.observation.visite.connexion' => 'الاتصال',
			'tc.observation.visite.reconnexion' => 'إعادة الاتصال',
			'tc.observation.visite.videoCoupee' => 'الفيديو غير متاح',
			'tc.observation.visite.reconnexionDetail' => 'انقطع الاتصال، جارٍ إعادة الاتصال. يستمر احتساب وقت متابعتك.',
			'tc.observation.visite.sonRecu' => 'الصوت واصل',
			'tc.observation.visite.sonInterrompu' => 'الصوت منقطع',
			'tc.observation.visite.agrandir' => 'تكبير',
			'tc.observation.visite.reduire' => 'تصغير',
			'tc.observation.visite.cameraFermee' => 'الكاميرا مغلقة',
			'tc.observation.visite.pasEncoreLa' => 'ليس في القاعة بعد',
			'tc.observation.visite.parle' => ({required Object nom}) => '⁨${nom}⁩ يتكلم',
			'tc.observation.visite.quitterQuestion' => 'مغادرة الزيارة؟',
			'tc.observation.visite.quitterConsequence' => ({required Object duree}) => 'بقي لك ⁨${duree}⁩. الزيارة التي تُغادَر قبل نهايتها تُحتسب زيارة كاملة: الوقت غير المستخدم لا يُرحَّل.',
			'tc.observation.visite.quitterConsequenceSansTemps' => 'الزيارة التي تُغادَر قبل نهايتها تُحتسب زيارة كاملة: الوقت غير المستخدم لا يُرحَّل.',
			'tc.observation.visite.quitterConfirmer' => 'مغادرة الزيارة',
			'tc.observation.fin.sortieVolontaire' => 'غادرت المتابعة.',
			'tc.observation.fin.quotaAtteint' => 'انتهى وقت متابعتك.',
			'tc.observation.fin.seanceTerminee' => 'انتهت الحصة.',
			'tc.observation.fin.revocationServeur' => 'قُطعت متابعتك.',
			'tc.observation.fin.deconnexion' => 'انقطع الاتصال.',
			'tc.observation.resultat.premiereTerminee' => 'انتهت زيارتك الأولى',
			'tc.observation.resultat.derniereTerminee' => 'انتهت زيارتك الأخيرة',
			'tc.observation.resultat.terminee' => 'انتهت زيارتك',
			'tc.observation.resultat.dureeAtteinte' => 'بلغت الزيارة مدتها',
			'tc.observation.resultat.interrompue' => 'قُطعت المتابعة',
			'tc.observation.resultat.continuePour' => ({required Object prenom}) => 'تستمر الحصة لـ⁨${prenom}⁩.',
			'tc.observation.resultat.continueSansPrenom' => 'تستمر الحصة.',
			'tc.observation.resultat.resteUne' => ({required Object duree}) => 'بقيت لك زيارة واحدة مدتها ⁨${duree}⁩. عد لاحقًا للاستماع إليه.',
			'tc.observation.resultat.restent' => ({required Object n, required Object duree}) => 'بقيت لك ⁨${n}⁩ زيارات مدة كل منها ⁨${duree}⁩. عد لاحقًا للاستماع إليه.',
			'tc.observation.resultat.resteUneSansDuree' => 'بقيت لك زيارة واحدة. عد لاحقًا للاستماع إليه.',
			'tc.observation.resultat.restentSansDuree' => ({required Object n}) => 'بقيت لك ⁨${n}⁩ زيارات. عد لاحقًا للاستماع إليه.',
			'tc.observation.resultat.aucune' => 'استخدمت زياراتك لهذه الحصة. يمكنك متابعة الحصة القادمة.',
			'tc.observation.resultat.prochaineSeance' => 'يمكنك متابعة الحصة القادمة.',
			'tc.observation.resultat.verification' => 'جارٍ التحقق من زياراتك المتبقية',
			'tc.observation.resultat.inconnues' => 'تعذّر التحقق من زياراتك المتبقية. سيُعاد التحقق منها في الفصل.',
			'tc.observation.resultat.voirObservations' => 'عرض متابعاتي',
			'tc.observation.annonce.tuteurObserve' => ({required Object prenomEnfant}) => 'وليّ أمر ⁨${prenomEnfant}⁩ يتابع',
			'tc.observation.annonce.restant' => ({required Object secondes}) => '⁨${secondes}⁩ ث',
			'tc.observation.annonce.enfantIndicateur' => 'وليّ أمرك يشاهد الدرس',
			'tc.observation.annonce.tuteursObservent' => ({required Object nombre}) => '⁨${nombre}⁩ من أولياء الأمور يتابعون',
			'tc.observation.reglages.titre' => 'متابعة أولياء الأمور',
			'tc.observation.reglages.intro' => 'يمكن لوليّ الأمر مشاهدة درس طفله لوقت قصير، دون ميكروفون ولا كاميرا. يحدد هذا الإعداد ما ينطبق على هذا الفصل.',
			'tc.observation.reglages.heriter' => 'اتباع إعداد الأكاديمية',
			'tc.observation.reglages.personnaliser' => 'تخصيص لهذا الفصل',
			'tc.observation.reglages.desactiver' => 'تعطيل لهذا الفصل',
			'tc.observation.reglages.maxVisites' => 'الزيارات لكل حصة',
			'tc.observation.reglages.tempsTotal' => 'الوقت الكلي لكل حصة',
			'tc.observation.reglages.plafondVisite' => 'أقصى مدة للزيارة',
			'tc.observation.reglages.diminuer' => 'إنقاص',
			'tc.observation.reglages.augmenter' => 'زيادة',
			'tc.observation.reglages.enregistrer' => 'حفظ',
			'tc.observation.reglages.invalideVisites' => 'زيارة واحدة على الأقل لكل حصة.',
			'tc.observation.reglages.invalideTemps' => 'ثلاثون ثانية على الأقل لكل حصة.',
			'tc.observation.reglages.valeurHeritee' => ({required Object valeur}) => 'الأكاديمية: ⁨${valeur}⁩',
			'tc.observation.reglages.uniteVisiteUne' => ({required Object n}) => '⁨${n}⁩ زيارة',
			'tc.observation.reglages.uniteVisites' => ({required Object n}) => '⁨${n}⁩ زيارات',
			'tc.observation.reglages.uniteSecondes' => ({required Object n}) => '⁨${n}⁩ ث',
			'tc.observation.reglages.versionPolitique' => ({required Object version}) => 'الإصدار ⁨${version}⁩',
			'tc.parcours.avant.titre' => 'قبل الدرس القادم',
			'tc.parcours.avant.rien' => 'لا شيء للتحضير للدرس القادم.',
			'tc.parcours.avant.rienDetail' => 'سيقترح معلمك العمل في نهاية الحصة القادمة.',
			'tc.parcours.avant.nonBranche' => 'العمل المطلوب تحضيره غير مربوط بهذه المساحة بعد.',
			'tc.parcours.avant.nonBrancheDetail' => 'هذا لا يعني أنه لا شيء للتحضير: هذه الشاشة لا تعرف قراءته بعد.',
			'tc.parcours.avant.reprendre' => 'استئناف الدرس',
			'tc.parcours.avant.reprendreDepuis' => ({required Object position}) => 'استئناف الدرس من ⁨${position}⁩',
			'tc.parcours.intention.apprendre' => 'للحفظ',
			'tc.parcours.intention.revoir' => 'للمراجعة',
			'tc.parcours.intention.renforcer' => 'للتثبيت',
			'tc.parcours.intention.entretenir' => 'للتعاهد',
			'tc.parcours.intention.evaluation' => 'للتقييم',
			'tc.parcours.plage.versets' => ({required Object sourate, required Object premier, required Object dernier}) => 'سورة ⁨${sourate}⁩، الآيات ⁨${premier}⁩ إلى ⁨${dernier}⁩',
			'tc.parcours.plage.versetUnique' => ({required Object sourate, required Object premier}) => 'سورة ⁨${sourate}⁩، الآية ⁨${premier}⁩',
			'tc.parcours.plage.versetsCroisee' => ({required Object sourateDebut, required Object versetDebut, required Object sourateFin, required Object versetFin}) => 'سورة ⁨${sourateDebut}⁩، الآية ⁨${versetDebut}⁩ إلى سورة ⁨${sourateFin}⁩، الآية ⁨${versetFin}⁩',
			'tc.parcours.plage.pages' => ({required Object premiere, required Object derniere}) => 'الصفحات ⁨${premiere}⁩ إلى ⁨${derniere}⁩',
			'tc.parcours.plage.pageUnique' => ({required Object premiere}) => 'الصفحة ⁨${premiere}⁩',
			'tc.parcours.plage.section' => ({required Object section}) => 'القسم ⁨${section}⁩',
			'tc.parcours.plage.ressource' => 'المادة كلها',
			'tc.parcours.feedback.cours.intitule' => 'كيف كان الدرس اليوم؟',
			'tc.parcours.feedback.cours.difficile' => 'صعب',
			'tc.parcours.feedback.cours.bien' => 'جيد',
			'tc.parcours.feedback.cours.tresBien' => 'جيد جدًا',
			'tc.parcours.feedback.comprehension.intitule' => 'هل فهمت ما تم العمل عليه؟',
			'tc.parcours.feedback.comprehension.difficile' => 'ليس تمامًا',
			'tc.parcours.feedback.comprehension.bien' => 'نعم تقريبًا',
			'tc.parcours.feedback.comprehension.tresBien' => 'تمامًا',
			'tc.parcours.feedback.rythme.intitule' => 'هل ناسبك إيقاع الدرس؟',
			'tc.parcours.feedback.rythme.difficile' => 'سريع جدًا',
			'tc.parcours.feedback.rythme.bien' => 'مناسب',
			'tc.parcours.feedback.rythme.tresBien' => 'مريح جدًا',
			'tc.parcours.feedback.technique.intitule' => 'هل كان الصوت والصورة مريحين؟',
			'tc.parcours.feedback.technique.difficile' => 'مزعجان',
			'tc.parcours.feedback.technique.bien' => 'مقبولان',
			'tc.parcours.feedback.technique.tresBien' => 'جيدان جدًا',
			'tc.parcours.feedback.confiance.intitule' => 'هل تشعر أنك مستعد للدرس القادم؟',
			'tc.parcours.feedback.confiance.difficile' => 'ليس بعد',
			'tc.parcours.feedback.confiance.bien' => 'تقريبًا',
			'tc.parcours.feedback.confiance.tresBien' => 'تمامًا',
			'tc.parcours.feedback.merci' => 'شكرًا.',
			'tc.parcours.feedback.tendance.titre' => 'آراء الطلاب',
			'tc.parcours.feedback.tendance.sousSeuil' => 'لا تكفي الآراء بعد لاستخلاص اتجاه.',
			'tc.parcours.feedback.tendance.anonyme' => 'الآراء مجهولة الهوية ومجمَّعة. لا تكفي وحدها أبدًا لاتخاذ قرار.',
			'tc.parcours.signalement.titre' => 'الإشارة إلى حاجة',
			'tc.parcours.signalement.categorie' => 'بماذا يتعلق الأمر؟',
			'tc.parcours.signalement.categorieValeur.pedagogique' => 'تعليمي',
			'tc.parcours.signalement.categorieValeur.presence' => 'الحضور',
			'tc.parcours.signalement.categorieValeur.technique' => 'تقني',
			'tc.parcours.signalement.categorieValeur.changement' => 'تغيير',
			'tc.parcours.signalement.categorieValeur.autre' => 'آخر',
			'tc.parcours.signalement.interne' => 'ملاحظة داخلية',
			'tc.parcours.signalement.interneAide' => 'تقرؤها الإدارة وحدها. لا تُرسل أبدًا تلقائيًا إلى الأسرة.',
			'tc.parcours.signalement.famille' => 'رسالة إلى الأسرة',
			'tc.parcours.signalement.familleAide' => 'اختيارية. الإدارة وحدها تقرر إرسالها بنقرة واحدة.',
			'tc.parcours.signalement.contexte' => ({required Object eleve}) => 'الطالب ⁨${eleve}⁩. الحصة والفصل واسمك مرفقة بالفعل.',
			'tc.parcours.signalement.envoyer' => 'إرسال الإشارة',
			'tc.parcours.signalement.envoye' => 'أُرسلت الإشارة إلى الإدارة.',
			'tc.parcours.signalement.interneRequis' => 'اكتب على الأقل ما يجب أن تعرفه الإدارة.',
			'tc.parcours.signalement.echec' => 'تعذّر إرسال الإشارة. أعد المحاولة.',
			'tc.parcours.postCours.titre' => 'بعد الدرس',
			'tc.parcours.postCours.duree' => ({required Object minutes}) => 'المدة الفعلية ⁨${minutes}⁩ دقيقة',
			'tc.parcours.postCours.exceptions' => 'للتأكيد',
			'tc.parcours.postCours.toutEstNominal' => 'لا شيء يتطلب انتباهك.',
			'tc.parcours.postCours.reprise' => 'الاستئناف المقترح',
			'tc.parcours.postCours.repriseInconnue' => 'لا موضع استئناف معروف لهذه الحصة.',
			'tc.parcours.postCours.travail' => 'العمل المقترح',
			'tc.parcours.postCours.travailAucun' => 'لا عمل مقترح حتى الآن.',
			'tc.parcours.postCours.valider' => 'تأكيد',
			'tc.parcours.postCours.enFile' => 'تم الحفظ. سيُرسل بمجرد عودة الشبكة.',
			'tc.parcours.postCours.envoye' => 'أُغلق الدرس.',
			'nav.eleve.accueil' => 'الرئيسية',
			'nav.eleve.maClasse' => 'فصلي',
			'nav.eleve.coran' => 'القرآن',
			'nav.eleve.monEspace' => 'مساحتي',
			'nav.eleve.suivi' => 'المتابعة',
			'nav.eleve.compte' => 'الحساب',
			'nav.tuteur.accueil' => 'الرئيسية',
			'nav.tuteur.foyer' => 'الأسرة',
			'nav.tuteur.disponibilites' => 'أوقات التوفر',
			'nav.tuteur.reglages' => 'الإعدادات',
			'nav.tuteur.suivi' => 'المتابعة',
			'nav.tuteur.historique' => 'السجل',
			'nav.tuteur.compte' => 'الحساب',
			'nav.enseignant.journee' => 'اليوم',
			'nav.enseignant.classes' => 'الفصول',
			'nav.enseignant.creneaux' => 'أوقات التوفر',
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
			'nav.admin.configuration' => 'الإعدادات العامة',
			'nav.admin.securite' => 'الأمان والتدقيق',
			'nav.admin.direction' => 'الإدارة',
			'nav.admin.recherche' => 'البحث',
			'nav.admin.rechercheIndication' => 'البحث عن شاشة',
			'nav.admin.notificationsTitre' => 'الإشعارات',
			'nav.admin.menu' => 'القائمة',
			'nav.compte' => 'حسابي',
			'nav.principale' => 'التنقل الرئيسي',
			'nav.motSymbole' => 'Rewayah',
			'nav.replier' => 'طي شريط التنقل',
			'nav.deplier' => 'فتح شريط التنقل',
			'accessibilite.demo.titre' => 'عرض تجريبي لوضع إمكانية الوصول',
			'accessibilite.demo.mention' => 'بيانات وهمية، لا إرسال.',
			'accessibilite.demo.intro' => 'اختر طالبًا ولحظة من الحصة.',
			'accessibilite.demo.eleveMineure' => 'مريم، طالبة قاصر',
			'accessibilite.demo.eleveAdulte' => 'إدريس، طالب بالغ',
			'accessibilite.demo.etatAvant' => 'قبل الحصة',
			'accessibilite.demo.etatFenetre' => 'قبيل الحصة، الدخول مفتوح',
			'accessibilite.demo.etatPendant' => 'أثناء الحصة',
			'accessibilite.demo.etatApres' => 'بعد الحصة',
			'accessibilite.accueil.salutation' => ({required Object prenom}) => 'السلام عليكم، ⁨${prenom}⁩.',
			'accessibilite.accueil.prochaineSeance' => 'الحصة القادمة',
			'accessibilite.accueil.avec' => ({required Object nomme}) => 'مع ⁨${nomme}⁩',
			'accessibilite.accueil.voirMaClasse' => 'عرض فصلي',
			'accessibilite.accueil.lireCoran' => 'قراءة القرآن',
			'accessibilite.accueil.lireCoranDetail' => 'فتح المصحف',
			'accessibilite.accueil.aide' => 'تحتاج إلى مساعدة؟',
			'accessibilite.accueil.erreurTitre' => 'لم تُحمَّل الحصة القادمة',
			'accessibilite.accueil.erreurPhrase' => 'تعذّرت قراءة الحصة والعمل المطلوب، غالبًا بسبب الاتصال. يكفي أن تعيد المحاولة بعد لحظة.',
			'accessibilite.accueil.indisponibleTitre' => 'الحصة القادمة لا تظهر هنا بعد',
			'accessibilite.accueil.indisponiblePhrase' => 'الصفحة الرئيسية لا تستقبل حصة الفصل بعد. تجدها في «فصلي».',
			'accessibilite.accueil.videTitre' => 'لا فصل بعد',
			'accessibilite.accueil.videPhrase' => 'لم يُسند أي فصل بعد. يُختار الفصل مع الأكاديمية. وإلى ذلك الحين، يبقى القرآن والمساعدة متاحين أدناه.',
			'accessibilite.coran.ouvrir' => 'فتح القرآن',
			'accessibilite.coran.reprendre' => 'المتابعة من آخر صفحة',
			'accessibilite.coran.reprendreVous' => 'المتابعة من آخر صفحة',
			'accessibilite.coran.reprendreDetail' => ({required Object page}) => 'كنت في الصفحة ⁨${page}⁩.',
			'accessibilite.coran.reprendreDetailVous' => ({required Object page}) => 'كنت في الصفحة ⁨${page}⁩.',
			'accessibilite.coran.repriseRecherche' => 'جارٍ البحث عن آخر صفحة…',
			'accessibilite.coran.repriseRechercheVous' => 'جارٍ البحث عن آخر صفحة…',
			'accessibilite.coran.repriseErreur' => 'تعذّر العثور على آخر صفحة، غالبًا بسبب الاتصال. افتح القرآن واختر صفحتك في القارئ. إعدادات القراءة تبقى محفوظة.',
			'accessibilite.coran.repriseErreurVous' => 'تعذّر العثور على آخر صفحة، غالبًا بسبب الاتصال. افتح القرآن واختر صفحتك في القارئ. إعدادات القراءة تبقى محفوظة.',
			'accessibilite.coran.lectureGrande' => 'يُفتح القرآن في قراءة مكبَّرة، آية آية.',
			'accessibilite.coran.retour' => 'العودة إلى مدخل القرآن',
			'accessibilite.coran.demoSansTexte' => 'نص القرآن غير محمَّل في العرض التجريبي',
			'accessibilite.coran.demoSansTexteDetail' => 'ليس هذا عطلًا: العرض التجريبي لا يحتوي على النص. لا شيء عليك فعله. في التطبيق، يُفتح القرآن هنا على صفحتك، وتبقى إعدادات القراءة محفوظة.',
			'accessibilite.coran.demoSansTexteDetailVous' => 'ليس هذا عطلًا: العرض التجريبي لا يحتوي على النص. لا شيء عليك فعله. في التطبيق، يُفتح القرآن هنا على صفحتك، وتبقى إعدادات القراءة محفوظة.',
			'accessibilite.maClasse.titre' => 'فصلي',
			'accessibilite.maClasse.suivi' => 'متابعتي',
			'accessibilite.maClasse.suiviDetail' => 'الحصص الماضية والحضور',
			'accessibilite.tutoiement.tonHeure' => 'توقيتك',
			'accessibilite.tutoiement.attenteDetail' => 'وقت الانتظار هذا لا يُحتسب في حضورك.',
			'accessibilite.tutoiement.attente' => ({required Object duree}) => 'أنت في القاعة. تبدأ الحصة بعد ⁨${duree}⁩.',
			'accessibilite.tutoiement.attenteImminent' => 'أنت في القاعة. تبدأ الحصة بعد أقل من دقيقة.',
			'accessibilite.tutoiement.annonceAttente' => 'أنت في القاعة',
			'accessibilite.tutoiement.horsLigne' => 'أنت غير متصل. تحتاج الحصة إلى اتصال.',
			'accessibilite.tutoiement.finPhrase' => 'تجد عملك في فصلك.',
			'accessibilite.apres.revoirSupport' => 'مراجعة مادة الدرس',
			'accessibilite.apres.revoirSupportDetail' => 'تبقى المادة في فصلك.',
			'accessibilite.apres.revoirSupportDetailVous' => 'تبقى المادة في فصلك.',
			'accessibilite.monEspace.titre' => 'مساحتي',
			'accessibilite.monEspace.mode' => 'وضع إمكانية الوصول',
			'accessibilite.monEspace.modeDetail' => 'واجهة مبسطة ومكيَّفة لتعلم أكثر طمأنينة.',
			'accessibilite.monEspace.modeActif' => 'مفعَّل',
			'accessibilite.monEspace.presentationStandard' => 'العرض العادي',
			'accessibilite.monEspace.demanderDetail' => 'اطلب من وليّ أمرك الانتقال إلى العرض العادي.',
			'accessibilite.monEspace.demandeEnCours' => 'جارٍ إرسال طلبك.',
			'accessibilite.monEspace.demandeEnvoyee' => 'أُرسل طلبك إلى وليّ أمرك.',
			'accessibilite.monEspace.demandeNonConfirmee' => 'لم يُؤكَّد الإرسال، غالبًا بسبب الاتصال. تحقّق من اتصالك، ثم المس السطر لإعادة المحاولة. لم يتغير شيء في الأثناء: يبقى العرض كما هو.',
			'reseau.horsLigne' => 'لا شبكة. ما هو معروض يبقى قابلًا للاطلاع.',
			'reseau.enAttenteEnvoi' => 'سيُرسل بمجرد عودة الشبكة',
			'reseau.retabli' => 'عادت الشبكة',
			'reseau.syncImpossible' => 'تعذّرت المزامنة',
			'vide.aucunCours' => 'لا دروس اليوم',
			'vide.aucunCoursDetail' => 'سيظهر درسك القادم هنا.',
			'vide.aucunCreneau' => 'لا موعد متاح الآن',
			'vide.aucunRapport' => 'لا دفتر متابعة حتى الآن',
			'vide.aucunAppareil' => 'لا جهاز مقترن',
			'notifications.titre' => 'الإشعارات',
			'notifications.indisponibleTitre' => 'الإشعارات غير متاحة بعد',
			'notifications.indisponiblePhrase' => 'ستظهر هنا تذكيرات الحصص ورسائل الأكاديمية بمجرد فتحها.',
			'notifications.videTitre' => 'لا إشعارات',
			'notifications.videPhrase' => 'ستظهر هنا تذكيرات الحصص ورسائل الأكاديمية.',
			'notifications.ligne' => ({required Object titre, required Object date, required Object heure}) => '⁨${titre}⁩، في ⁨${date}⁩ الساعة ⁨${heure}⁩',
			'choix.autre' => 'أخرى',
			'choix.autreInvite' => 'حدّد',
			'choix.selectionMultiple' => 'يمكن اختيار عدة إجابات',
			'accuse.titre' => 'ما يجب معرفته قبل البدء',
			'accuse.compris' => 'فهمت',
			'aConstruire.titre' => 'شاشة قيد الإنشاء',
			'aConstruire.detail' => 'تأتي هذه الشاشة في المرحلة 3.',
			'destructif.irreversible' => 'لا يمكن التراجع عن هذا الإجراء.',
			'avatar.sansPhoto' => 'لا صورة بعد',
			'pin.titre' => 'أدخل رمزك',
			'pin.erreur' => 'هذا الرمز غير مطابق',
			'pin.effacer' => 'مسح',
			'enfant.titre' => 'إضافة ملف طالب',
			'enfant.aucun' => 'لا ملف طالب في الأسرة',
			'enfant.aucunDetail' => 'أضف أولًا ملف طالب من «الأسرة».',
			'reglagesEnfant.titre' => 'الإعدادات حسب ملف الطالب',
			'reglagesEnfant.intro' => 'تُضبط صورة كل طالب وكاميرته وواجهته في بطاقته، من «الأسرة». أما الطلبات إلى الإدارة فتبقى هنا.',
			'reglagesEnfant.renvoi' => 'الصورة والكاميرا والواجهة',
			'reglagesEnfant.renvoiLegende' => ({required Object prenom}) => 'في بطاقة ⁨${prenom}⁩',
			'galerie.titre' => 'معرض المكونات',
			'galerie.avertissement' => 'منصة اختبار للتطوير. غير موجودة في إصدارات الإنتاج.',
			'galerie.paires' => 'أزواج الألوان',
			'galerie.elevation' => 'الارتفاع والزوايا',
			'galerie.typographie' => 'سلالم الخطوط',
			'galerie.polices' => 'الخطوط',
			'galerie.composants' => 'المكونات المشتركة',
			'galerie.modeEnfant' => 'وضع إمكانية الوصول',
			'galerie.modeStandard' => 'الوضع العادي',
			_ => null,
		};
	}
}
