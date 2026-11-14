// Les e-mails en arabe, ecrits a la main (arabe standard, ton ferme et
// bienveillant). Ils suivent le sens du francais (`modeles_fr.ts`) ; memes
// liens, memes boutons. Vocabulaire de `assets/i18n/ar.i18n.json` : الفصل
// (classe), المعلم (enseignant), الإدارة (la direction), الأسرة (foyer).
// Chiffres latins, comme dans l'application ; dates en `ar-u-nu-latn`.

import { APP } from './gabarit.ts'
import { causeConversionRefusee, nomClasse, type MotsConversionRefusee } from './outils.ts'
import { avec, avisDans, bonjour, dateLongue, type Fabrique, type LangueEcrite, libre, type Parole, montantLisible,
  precisions, type Precisions, phraseChangementHeure, type MotsChangementHeure} from './outils.ts'
import { quandSeance, codeCandidat } from './modeles_fr.ts'

const PAROLE: Parole = {
  salut: 'مرحبًا',
  fin: '،',
  salutSeul: 'مرحبًا،',
  note: 'تجد التفاصيل في التطبيق بعد تسجيل الدخول.',
  sujetLibre: 'رسالة من Rewayah Academy',
  locale: 'ar-u-nu-latn',
}
export const PRECISIONS_AR: Precisions = {
  locale: 'ar',
  a: 'الساعة',
  // Un nom en lettres latines dans une phrase arabe est isole (U+2068 ... U+2069) :
  // sans cela, l'ordre de lecture se brise autour des guillemets.
  classe: (n) => `الفصل: «\u2068${n}\u2069».`,
  eleves: (n, plusieurs) => plusieurs ? `الطلاب: \u2068${n}\u2069.` : `الطالب: \u2068${n}\u2069.`,
  premiere: (q) => `الحصة الأولى: ${q}.`,
}

const avis = avisDans(PAROLE)

const RAISON: Record<string, string> = {
  compte: 'وصلتك هذه الرسالة لأنها تخص حسابك في Rewayah Academy.',
  inscription: 'وصلتك هذه الرسالة لأنها تخص طلبًا قُدّم في Rewayah Academy.',
  classes: 'وصلتك هذه الرسالة لأنها تخص فصلًا تتابعه أو تُدرّس فيه.',
  facturation: 'وصلتك هذه الرسالة لأنها تخص فواتير أسرتك.',
  recrutement: 'وصلتك هذه الرسالة لأنك على اتصال بفريق التوظيف لدينا.',
  direction: 'وصلتك هذه الرسالة من إدارة Rewayah Academy.',
  nouvelles: 'وصلتك هذه الرسالة لأنك تتابع أخبار Rewayah Academy.',
}

const REFUS_ADMISSION: Record<string, string> = {
  refus_general: 'لا يمكننا متابعة طلبك في الوقت الحالي.',
  refus_niveau: 'لا يمكننا متابعة طلبك: المستوى المطلوب غير متاح بعد.',
  refus_besoins: 'لا يمكننا متابعة طلبك: فصولنا لا تلبي بعد ما تبحث عنه.',
  refus_sans_reponse: 'لا يمكننا متابعة طلبك: لم يصلنا رد على رسالتنا الأخيرة.',
}

export const MOTS_CHANGEMENT_HEURE_AR: MotsChangementHeure = {
  locale: 'ar',
  un: (date, jour, avant, apres, foyer) => `ابتداءً من ${date}، يتغيّر موعد ${foyer ? 'حصة الفصل' : 'حصتكم'} يوم ${jour} من الساعة ${avant} إلى الساعة ${apres}.`,
  plusieurs: (date, liste, foyer) => `ابتداءً من ${date}، يتغيّر توقيت ${foyer ? 'حصص الفصل' : 'حصصكم'}: ${liste}.`,
  ligne: (jour, avant, apres) => `يوم ${jour} من ${avant} إلى ${apres}`,
  unJour: (date, ja, avant, jb, apres, foyer) => `ابتداءً من ${date}، يتغيّر موعد ${foyer ? 'حصة الفصل' : 'حصتكم'} من يوم ${ja} الساعة ${avant} إلى يوم ${jb} الساعة ${apres}.`,
  ligneJour: (ja, avant, jb, apres) => `من يوم ${ja} الساعة ${avant} إلى يوم ${jb} الساعة ${apres}`,
  mecque: 'تبقى الحصة في الساعة نفسها بتوقيت مكة المكرمة؛ الذي يتغيّر هو توقيت مدينتكم.',
  separateur: '، ',
}

/// Avis a la direction : une classe que la tache de nuit refuse de convertir
/// (HORLOGE-ET-LIEU, I5). Cause fermee, jamais le texte SQL ni un identifiant.
export const MOTS_CONVERSION_REFUSEE_AR: MotsConversionRefusee = {
  sujet: 'تعذّر نقل فصل إلى توقيت مكة المكرمة',
  phrase: (classe, cause) => {
    const raison = { proche: 'يقترب تغيير الساعة (أقل من 28 يومًا)', demi_heure: 'أحد مواعيده لا يقع على ساعة كاملة بتوقيت مكة المكرمة', autre: 'فشل أحد التحقّقات، راجعوا الفصل' }[cause]
    return classe ? `تعذّر نقل الفصل ${classe} إلى توقيت مكة المكرمة: ${raison}. لم يتغيّر أي موعد، وستُعاد المحاولة هذه الليلة.` : 'تعذّر نقل فصل إلى توقيت مكة المكرمة. لم يتغيّر أي موعد، وستُعاد المحاولة هذه الليلة.'
  },
  bouton: 'عرض الجدول',
}

const MODELES: Record<string, Fabrique> = {
  admission_acceptee: (d) => avis(d, 'قُبل طلبك', 'أهلا بك في أكاديمية الرواية',
    'قبلت الإدارة طلبك. مساحتك مفتوحة: ادخل إلى التطبيق لتجدها.',
    'الدخول إلى التطبيق', '/'),
  admission_refusee: (d) => avis(d, 'لا يمكننا متابعة طلبك', 'طلبك',
    REFUS_ADMISSION[String(d.modele ?? '')] ?? REFUS_ADMISSION.refus_general,
    'عرض طلبي', '/attente'),
  admission_precisions: (d) => {
    const c = avis(d, 'تنقصنا معلومة', 'تنقصنا معلومة',
      'لدراسة طلبك، تحتاج الإدارة إلى توضيح:',
      'عرض طلبي', '/attente')
    c.blocs.splice(2, 0, { type: 'texte', texte: String(d.precisions ?? '') })
    return c
  },
  // D2 (30/10/2026) : اقتراح، لم يعتمده المدير بعد.
  compte_enseignant_valide: (d) => avis(d, 'مرحبًا بك في الفريق', 'مرحبًا بك في الفريق',
    'ترحّب بك الإدارة في الفريق. ادخل إلى التطبيق: بقي أن تهيّئ بيانات التحويل وأوقات توفّرك وصورتك العامة. ستظهر فيه فصولك فور أن تُسند إليك الإدارة فصلًا. وعندما يحتاج فصل إلى مدرّس بديل يظهر العرض في التطبيق، فتفقّده باستمرار وأجب بسرعة.',
    'الدخول إلى التطبيق', '/'),
  // SALLE-1 (07/11/2026) : texte valide par le garde-cap le 07/11/2026.
  retenu_entretien: (d) => avis(d, 'اختير طلبك لمقابلة', 'لنتعارف',
    'قرأت الإدارة طلبك وتقترح عليك مقابلة بالفيديو للتعارف. اختر في التطبيق الموعد الذي يناسبك.',
    'عرض طلبي', '/attente'),
  coordonnees_versement_changees: (d) => avis(d, 'تغيّرت بيانات التحويل الخاصة بك', 'عُدّلت بيانات التحويل',
    'عُدّلت للتو من حسابك البيانات التي تُحوَّل إليها راتبك. ستُستعمل بعد أن تعتمدها الإدارة. إن لم تكن أنت من عدّلها فاكتب إلى الإدارة فورًا.',
    'عرض بياناتي', '/compte/paiements-recus'),
  coordonnees_versement_validees: (d) => avis(d, 'اعتُمدت بيانات التحويل الخاصة بك', 'اعتُمدت بيانات التحويل',
    'اعتمدت الإدارة بيانات التحويل الخاصة بك. سيُحوَّل إليه راتبك القادم. إن لم تتعرّف على هذه البيانات فاكتب إلى الإدارة فورًا.',
    'عرض بياناتي', '/compte/paiements-recus'),
  // SALLE-2-ENTRETIEN (07/11/2026) : مقابلة الترشح.
  entretien_reserve: (d) => {
    const quand = quandSeance(d, 'ar', 'الساعة')
    return avis(d, 'حُدّد موعد مقابلتك', 'حُدّد موعد مقابلتك',
      (quand ? `حُدّد موعد مقابلتك مع الإدارة يوم ${quand}.` : 'حُدّد موعد مقابلتك مع الإدارة. اليوم والساعة في التطبيق.')
        + ' عند حلول الموعد، انضمّ إليها من التطبيق.',
      'عرض موعد مقابلتي', '/attente/entretien')
  },
  entretien_rappel: (d) => {
    const quand = quandSeance(d, 'ar', 'الساعة')
    const bientot = d.sorte === 'quinze'
    return avis(d, bientot ? 'تبدأ مقابلتك بعد 15 دقيقة' : 'مقابلتك غدًا',
      bientot ? 'تبدأ مقابلتك قريبًا' : 'مقابلتك غدًا',
      (bientot ? 'تبدأ مقابلتك مع الإدارة بعد 15 دقيقة.' : `مقابلتك مع الإدارة غدًا${quand ? `، يوم ${quand}` : ''}.`)
        + ' انضمّ إليها من التطبيق، في مكان هادئ، والكاميرا والميكروفون جاهزان.',
      bientot ? 'الانضمام إلى المقابلة' : 'عرض موعد مقابلتي', '/attente/entretien')
  },
  entretien_rappel_direction: (d) => {
    const quand = quandSeance(d, 'ar', 'الساعة')
    return avis(d, 'تبدأ مقابلة بعد 15 دقيقة', 'تبدأ مقابلة بعد 15 دقيقة',
      `تُجري مقابلة تبدأ بعد 15 دقيقة${quand ? `، يوم ${quand}` : ''}. انضمّ إليها من بطاقة الترشح.`,
      'عرض الترشحات', '/admin/personnes/candidatures')
  },
  entretien_tenu: (d) => avis(d, 'شكرًا على هذه المقابلة', 'شكرًا على هذه المقابلة',
    'جرت مقابلتك. تدرس الإدارة ترشحك وتكتب إليك بالخطوة التالية في التطبيق.',
    'عرض ترشحي', '/attente/entretien'),
  entretien_a_replanifier: (d) => avis(d, 'اختر موعدًا آخر لمقابلتك', 'اختر موعدًا آخر',
    'لم تُعقد مقابلتك. اختر موعدًا آخر في التطبيق.',
    'اختيار موعد', '/attente/entretien'),
  admission_recue: (d) => avis(d, 'وصلنا طلبك', 'طلبك قيد الدراسة',
    'وصلنا طلبك. تقرأ الإدارة كل طلب قبل فتح أي حساب. ليس عليك إرسال أي شيء: سنكتب إليك على هذا العنوان فور رد الإدارة.',
    'عرض طلبي', '/attente'),
  demande_recue: (d) => avis(d, 'وصلنا طلبك', 'وصلنا طلبك',
    'وصلنا طلبك لحجز موعد. تدرسه الإدارة وترد عليك في التطبيق.',
    'متابعة طلبي', '/tuteur/demandes'),
  demande_presentation: (d) => avis(d, 'وصل طلب تعريفي', 'وصل طلب تعريفي',
    'وصل طلب تعريفي. هو في انتظارك في التطبيق.',
    'فتح الطلب', '/tuteur/demandes'),
  classe_validee: (d) => avis(d, 'فصلك جاهز', 'فصلك جاهز',
    'الفصل المطابق لطلبك جاهز. بقي أن يُعيَّن له معلمه، وسنُعلمك بذلك.',
    'عرض الفصل', '/tuteur/demandes'),
  // SUIVI-ATTENTE (12/11/2026) : courriel de l'enseignant a l'affectation.
  enseignant_affecte: (d) => {
    if (d.portee === 'classe') {
      const P = PRECISIONS_AR
      const n = Number(d.eleves_n)
      const tranche = d.public === 'adulte' ? 'بالغون' : d.public === 'enfant' ? 'أطفال' : ''
      const eleves = Number.isInteger(n) && n > 0 ? `عدد الطلاب: ${n}${tranche ? ` (${tranche})` : ''}.` : ''
      const q = quandSeance(d, P.locale, P.a)
      const detail = [typeof d.classe === 'string' && d.classe ? P.classe(d.classe) : '', eleves, q ? `أول حصة: ${q}.` : ''].filter(Boolean).join(' ')
      return avis(d, 'أُسند إليك فصل', 'أُسند إليك فصل',
        avec('أُسند إليك فصل.', detail)
          + ' عرّف بنفسك للأسر من التطبيق: رسالة جاهزة يمكنك تعديلها.',
        'أعرّف بنفسي', '/enseignant/classes')
    }
    return avis(d, 'عُيّن معلم للفصل', 'صار لفصلك معلم',
    'عُيّن معلم للفصل. تجد اسمه ومواعيده في التطبيق.',
    'عرض الفصل', '/tuteur/demandes')
  },
  // SUIVI-ATTENTE (12/11/2026) : « Tout est pret » (etape 5), a la famille ou a l'eleve
  // adulte, jamais a un enfant.
  tout_est_pret: (d) => {
    const P = PRECISIONS_AR
    if (d.portee === 'soi') {
      return avis(d, 'كل شيء جاهز لحصتك الأولى', 'كل شيء جاهز',
        avec('كل شيء جاهز: فصلك ومعلمك وموعدك مؤكَّدة.', precisions(d, P, { premiere: true }))
          + ' تابع التفاصيل في التطبيق.',
        'عرض المتابعة', '/eleve')
    }
    return avis(d, 'كل شيء جاهز للحصة الأولى', 'كل شيء جاهز',
      avec('كل شيء جاهز: الفصل والمعلم والموعد مؤكَّدة.', precisions(d, P, { premiere: true }))
        + ' تابع التفاصيل في التطبيق.',
      'عرض المتابعة', '/tuteur/demandes')
  },
  demande_close: (d) => avis(d, 'أُغلق طلبك', 'أُغلق طلبك',
    'أُغلق طلبك لحجز موعد. ردّ الإدارة في التطبيق.',
    'قراءة الرد', '/tuteur/demandes'),
  classe_changee: (d) => avis(d, 'تغيير الفصل، في الموعد نفسه', 'تغيير الفصل',
    'انتقل أحد طلاب أسرتك إلى فصل آخر في الموعد نفسه.',
    'عرض التفاصيل', '/tuteur/demandes'),
  // بطاقة 27/10/2026، السطر 15: الأحداث التسعة للفصول والحصص.
  // COURRIELS-UX (UX-026, FN-108) : la classe, l'enfant, la premiere seance et son fuseau.
  classe_creee: (d) => {
    if (d.portee === 'classe') {
      return avis(d, 'تم إنشاء فصل', 'تم إنشاء فصل',
        avec('تم إنشاء فصل للتو.', precisions(d, PRECISIONS_AR, { eleves: false, premiere: true })) + ' طلابه وموعده في التطبيق.',
        'عرض فصولي', '/enseignant/classes')
    }
    return avis(d, 'تم إنشاء فصلك', 'تم إنشاء فصلك',
      avec(d.portee === 'foyer' ? 'تم إنشاء فصل لأسرتك.' : 'تم إنشاء فصلك.', precisions(d, PRECISIONS_AR, { premiere: true })) + ' معلمه وموعده كاملًا في التطبيق.',
      'عرض الموعد', '/tuteur')
  },
  enseignant_change: (d) => avis(d, 'يتغيّر معلم الفصل', 'يتغيّر معلم الفصل',
    'يتولى معلم آخر الفصل في الموعد نفسه. اسمه في التطبيق.',
    'عرض الفصل', '/tuteur'),
  eleve_inscrit: (d) => {
    if (d.portee === 'foyer') {
      return avis(d, 'تسجيل في فصل', 'تسجيل في فصل',
        avec('ينضم أحد طلاب أسرتك إلى فصل.', precisions(d, PRECISIONS_AR, { premiere: true })) + ' معلمه وموعده كاملًا في التطبيق.',
        'عرض الفصل', '/tuteur')
    }
    if (d.portee === 'soi') {
      return avis(d, 'تنضم إلى فصل', 'تنضم إلى فصل',
        avec('تنضم إلى فصل.', precisions(d, PRECISIONS_AR, { premiere: true })) + ' معلمك وموعدك كاملًا في التطبيق.',
        'عرض فصلي', '/eleve')
    }
    return avis(d, 'ينضم طالب إلى فصلك', 'ينضم طالب إلى فصلك',
      avec('ينضم طالب إلى فصلك.', precisions(d, PRECISIONS_AR, { eleves: false })) + ' ملفه في التطبيق.',
      'عرض فصولي', '/enseignant/classes')
  },
  eleve_retire: (d) => avis(d, 'يغادر طالب فصلك', 'يغادر طالب فصلك',
    'يغادر طالب فصلك. القائمة المحدّثة في التطبيق.',
    'عرض فصولي', '/enseignant/classes'),
  creneau_change: (d) => {
    // I5 (13/11/2026) : l'avis de la direction n'est pas celui d'une famille.
    const cause = causeConversionRefusee(d)
    if (cause) {
      return avis(d, MOTS_CONVERSION_REFUSEE_AR.sujet, MOTS_CONVERSION_REFUSEE_AR.sujet,
        MOTS_CONVERSION_REFUSEE_AR.phrase(nomClasse(d), cause), MOTS_CONVERSION_REFUSEE_AR.bouton,
        '/admin/operations/planning')
    }
    const annonce = phraseChangementHeure(d, MOTS_CHANGEMENT_HEURE_AR)
    if (annonce) {
      return avis(d, 'يتغيّر موعد حصتكم', 'يتغيّر موعد حصتكم', annonce,
        'عرض جدولي', '/tuteur')
    }
    return avis(d, 'يتغيّر موعد الفصل', 'يتغيّر موعد الفصل',
      'يتغيّر موعد الفصل. الموعد الجديد في التطبيق.',
      'عرض الموعد الجديد', '/tuteur')
  },
  seance_annulee: (d) => {
    const quand = quandSeance(d, 'ar', 'الساعة')
    return avis(d, 'أُلغيت حصة', 'أُلغيت حصة',
      avec(quand ? `أُلغيت حصة ${quand}.` : 'أُلغيت إحدى حصص الفصل.', precisions(d, PRECISIONS_AR)),
      'عرض الجدول', '/tuteur')
  },
  seance_deplacee: (d) => {
    const quand = quandSeance(d, 'ar', 'الساعة')
    return avis(d, 'تم نقل حصة', 'تم نقل حصة',
      quand ? `تم نقل حصة إلى ${quand}.` : 'تم نقل إحدى حصص الفصل. الموعد الجديد في التطبيق.',
      'عرض الموعد الجديد', '/tuteur')
  },
  enseignante_absente: (d) => {
    const quand = quandSeance(d, 'ar', 'الساعة')
    return avis(d, 'المعلم غائب عن حصة', 'المعلم غائب عن حصة',
      (quand ? `المعلم غائب عن حصة ${quand}.` : 'المعلم غائب عن إحدى حصص الفصل.')
        + ' الإدارة تُبقيكم على اطلاع.',
      'عرض الجدول', '/tuteur')
  },
  // A3 (31/10/2026) : le titulaire n’est pas entré dans la salle.
  remplacement_avertissement: (d) => avis(d, 'لستم في القاعة بعد', 'لستم في القاعة بعد',
    (typeof d.minutes === 'string' ? `ادخلوا خلال ${d.minutes} دقائق` : 'ادخلوا بسرعة') + ': بعد هذه المدة، إذا تقدّم معلم لاستبدالكم، فستفقدون الوصول إلى حصة اليوم.',
    'عرض يومي', '/enseignant/journee'),
  remplacement_pre_alerte: (d) => avis(d, 'يجري التحضير لاستبدال', 'يجري التحضير لاستبدال',
    'أحد المعلمين لم يدخل قاعته بعد. أعلنوا استعدادكم في صفحة الاستبدالات.',
    'عرض الاستبدالات', '/enseignant/journee/remplacements'),
  remplacement_inutile: (d) => avis(d, 'لم يعد الاستبدال ضروريًا', 'لم يعد الاستبدال ضروريًا',
    'وصل معلم الفصل. شكرًا لاستعدادكم.',
    'عرض الاستبدالات', '/enseignant/journee/remplacements'),
  titulaire_en_retard: (d) => avis(d, 'المعلم الأصلي متأخر', 'المعلم الأصلي متأخر',
    d.portee === 'direction' ? 'معلم أصلي لم يدخل قاعته. يجري البحث عن بديل.' : 'تبحث الأكاديمية عن بديل: ابقوا في القاعة.',
    'فتح التطبيق', '/tuteur'),
  // A3-bis (02/11/2026).
  // SNT (03/11/2026).
  seance_reportee: (d) => {
    const quand = quandSeance(d, 'ar', 'الساعة')
    return avis(d, 'أُجّلت حصة', 'أُجّلت حصة',
      (quand ? `لم تُعقد حصة ${quand}: لقد أُجّلت.` : 'لم تُعقد إحدى حصص الفصل: لقد أُجّلت.')
        + ' سيُعلَن الموعد الجديد في التطبيق.',
      'عرض الجدول', '/tuteur')
  },
  seance_reportee_direction: (d) => {
    const quand = quandSeance(d, 'ar', 'الساعة')
    const classe = typeof d.classe === 'string' ? ` للفصل ${d.classe}` : ''
    const ens = typeof d.enseignant === 'string' ? ` معلم الفصل: ${d.enseignant}.` : ''
    const delai = typeof d.minutes === 'string' ? ` خلال ${d.minutes} دقيقة` : ''
    return avis(d, 'حصة مؤجلة: حدّدوا موعدًا جديدًا', 'حصة مؤجلة: حدّدوا موعدًا جديدًا',
      `لم يدخل أي معلم القاعة${classe}${quand ? `، حصة ${quand}` : ''}${delai}: أُجّلت الحصة.${ens} حدّدوا الموعد الجديد في الجدول.`,
      'عرض الجدول', '/admin/operations/planning')
  },
  remplacement_personne_en_salle: (d) => {
    const quand = quandSeance(d, 'ar', 'الساعة')
    const classe = typeof d.classe === 'string' ? ` للفصل ${d.classe}` : ''
    const ens = typeof d.enseignant === 'string' ? ` معلم الفصل: ${d.enseignant}.` : ''
    return avis(d, 'لا أحد في القاعة', 'لا أحد في القاعة',
      `لم يدخل المعلم ولا بديل القاعة${classe}${quand ? `، حصة ${quand}` : ''}.${ens} ابحثوا عن بديل أو أبلغوا الأسر.`,
      'عرض الجدول', '/admin/operations/planning')
  },
  remplacant_arrive: (d) => avis(d, 'بديل في الطريق', 'بديل في الطريق',
    'بديل في الطريق: ابقوا في القاعة.',
    'فتح التطبيق', '/tuteur'),
  classe_supprimee: (d) => avis(d, 'أُغلق الفصل', 'أُغلق الفصل',
    avec('أُغلق الفصل.', precisions(d, PRECISIONS_AR)) + ' تتواصل الإدارة معكم بشأن ما يلي.',
    'فتح التطبيق', '/tuteur'),
  remplacement_propose: (d) => avis(d, 'عُرض عليك تعويض', 'عُرض عليك تعويض',
    'عُرض عليك تعويض حصة. أجب في التطبيق حتى يكون الفصل مضمونًا.',
    'عرض التعويض', '/enseignant/journee/remplacements'),
  remplacement_pris: (d) => avis(d, 'أُسند التعويض', 'أُسند التعويض',
    'أُسند تعويض الحصة.',
    'عرض يومي', '/enseignant/journee/remplacements'),
  controle_mission_attribuee: (d) => avis(d, 'أُسندت إليك مهمة مراقبة', 'مهمة مراقبة جديدة',
    'أُسندت إليك مهمة مراقبة.', 'فتح المهمة', '/controleur'),
  controle_mission_non_controlee: (d) => avis(d, 'بقيت مهمة دون تحقق', 'مهمة دون تحقق',
    'بقيت مهمة مراقبة دون تحقق.', 'عرض السحوبات', '/admin/securite-audit/tirages'),
  paiement_relance: (d) => {
    const j = typeof d.jours_avant === 'number' ? d.jours_avant : null
    const quand = j === null ? 'قريبًا' : j === 0 ? 'اليوم' : j === 1 ? 'غدًا' : j === 2 ? 'بعد يومين' : `بعد ${j} أيام`
    return avis(d, `يحين موعد دفعة ${quand}`, 'يحين موعد دفعة',
      `يحين موعد دفعة هذا الشهر ${quand}. تُسدَّد في التطبيق، في قسم المدفوعات، حتى تستمر الحصص دون انقطاع.`,
      'تسديد الدفعة', '/tuteur/foyer/recharge')
  },
  acces_suspendu_paiement: (d) => avis(d, 'الوصول موقوف', 'الوصول موقوف',
    'لم تصل دفعة الشهر، لذلك أُوقف الوصول إلى الفصل. يعود فور وصول الدفعة.',
    'تسديد الدفعة', '/tuteur/foyer/recharge'),
  acces_retabli_paiement: (d) => avis(d, 'أُعيد الوصول', 'أُعيد الوصول',
    'وصلت الدفعة، وأُعيد الوصول إلى الفصل.', 'فتح التطبيق', '/tuteur/foyer/recharge'),
  paiement_recu: (d) => {
    const m = montantLisible(d, PAROLE.locale)
    return avis(d, 'وصلت الدفعة', 'وصلت الدفعة',
      m === null ? 'وصلت الدفعة. الرصيد محدَّث في التطبيق.'
        : `وصلت دفعة بقيمة ${m}. الرصيد محدَّث في التطبيق.`,
      'فتح التطبيق', '/tuteur/foyer/recharge')
  },
  // FN-115b (02/11/2026) : remboursement et contestation d'un paiement.
  remboursement_effectue: (d) => {
    const m = montantLisible(d, PAROLE.locale)
    return avis(d, 'تمّ استرداد مبلغ', 'تمّ استرداد مبلغ',
      m === null ? 'تمّ الاسترداد إلى وسيلة الدفع المستعملة. الرصيد محدَّث في التطبيق.'
        : `تمّ استرداد ${m} إلى وسيلة الدفع المستعملة. الرصيد محدَّث في التطبيق.`,
      'فتح التطبيق', '/tuteur/foyer/recharge')
  },
  litige_ouvert: (d) => {
    const m = montantLisible(d, PAROLE.locale)
    return avis(d, 'دفعة معترَض عليها لدى البنك', 'دفعة معترَض عليها',
      m === null ? 'دفعة معترَض عليها لدى البنك. طوال مدة الفحص، يُعلَّق دخول الطلاب المعنيين إلى الحصص والموارد. إذا كان ذلك خطأ، فاكتبوا لنا.'
        : `دفعة بقيمة ${m} معترَض عليها لدى البنك. طوال مدة الفحص، يُعلَّق دخول الطلاب المعنيين إلى الحصص والموارد. إذا كان ذلك خطأ، فاكتبوا لنا.`,
      'فتح التطبيق', '/tuteur/foyer/recharge')
  },
  litige_clos: (d) => {
    const f = montantLisible({ montant_mineur: d.frais_mineur, devise: d.devise }, PAROLE.locale)
    return avis(d, 'أُغلق الاعتراض', 'أُغلق الاعتراض',
      d.issue === 'gagne' ? 'حكم البنك لصالح الأكاديمية: أُعيدت الدفعة، ويعود الدخول متى دُفع الشهر من جديد.'
        : f === null ? 'حكم البنك لصالحكم: تُعامَل الدفعة كاسترداد كامل. وتُضاف رسوم الاعتراض إلى رصيد الأسرة.'
        : `حكم البنك لصالحكم: تُعامَل الدفعة كاسترداد كامل. وتُضاف رسوم الاعتراض (${f}) إلى رصيد الأسرة.`,
      'فتح التطبيق', '/tuteur/foyer/recharge')
  },
  invitation_foyer: (d) => {
    const qui = typeof d.invite_par === 'string' && d.invite_par.trim() ? d.invite_par.trim() : 'أحد أفراد أسرتك'
    const code = typeof d.code === 'string' && /^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$/.test(d.code) ? d.code : null
    const lien = `${APP}/#/connexion${code ? `?mode=creer&foyer=1&code=${code}` : ''}`
    const fin = dateLongue(d.expire_le, PAROLE.locale)
    return {
      sujet: `${qui} يدعوك إلى الانضمام إلى أسرته في Rewayah Academy`,
      apercu: `${qui} يدعوك إلى متابعة دروس الأسرة معه.`,
      titre: 'دُعيت إلى الانضمام إلى أسرة',
      blocs: [
        { type: 'texte', texte: PAROLE.salutSeul },
        { type: 'texte', texte: `${qui} يدعوك إلى الانضمام إلى أسرته في Rewayah Academy، لمتابعة دروس الأسرة معًا.` },
        ...(code
          ? [{ type: 'texte', texte: 'أنشئ حسابك بعنوان البريد الإلكتروني هذا، أو سجّل الدخول إن كان لديك حساب. رمز دعوتك:' } as const, { type: 'code', code } as const]
          : [{ type: 'texte', texte: 'سجّل الدخول بعنوان البريد الإلكتروني هذا: الدعوة في انتظارك في التطبيق.' } as const]),
        { type: 'bouton', libelle: 'فتح الدعوة', href: lien },
        ...(code ? [{ type: 'texte', texte: 'لا يصلح الرمز إلا مع هذا العنوان، ولمرة واحدة.' } as const] : []),
        { type: 'note', texte: (fin ? `الدعوة صالحة حتى ${fin}. ` : '') + 'إن كنت لا تعرف هذا الشخص، فتجاهل هذه الرسالة.' },
      ],
    }
  },
  // I1 (02/11/2026) : memes liens que le francais ; proposition, texte non
  // valide par le directeur.
  invitation_enseignant: (d) => {
    const code = typeof d.code === 'string' && /^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$/.test(d.code) ? d.code : null
    const fin = dateLongue(d.expire_le, PAROLE.locale)
    const lien = `${APP}/#/connexion?mode=creer&invitation=1${code ? `&code=${code}` : ''}`
    return {
      sujet: 'دعوتك للتدريس في Rewayah Academy',
      apercu: 'تدعوك الإدارة إلى إنشاء حسابك معلّمًا.',
      titre: 'دُعيت إلى التدريس في Rewayah Academy',
      blocs: [
        { type: 'texte', texte: bonjour(d, PAROLE) },
        { type: 'texte', texte: 'تدعوك إدارة Rewayah Academy إلى إنشاء حسابك معلّمًا.' },
        ...(code ? [{ type: 'texte', texte: 'رمز دعوتك:' } as const, { type: 'code', code } as const] : []),
        { type: 'bouton', libelle: 'إنشاء حسابي معلّمًا', href: lien },
        { type: 'texte', texte: 'أنشئ حسابك بعنوان البريد الإلكتروني هذا: لا يصلح الرمز إلا معه. إن لم يُفتح الزر، فافتح app.rewayahacademy.com، ثم المس «لدي رمز دعوة» وانسخ الرمز.' },
        { type: 'note', texte: (fin ? `الدعوة صالحة حتى ${fin} ولا تُستعمل إلا مرة واحدة. ` : 'الدعوة لا تُستعمل إلا مرة واحدة. ') + 'لا شيء يُدفع في أي مرحلة. إن لم تكن تنتظر هذه الدعوة، فتجاهل هذه الرسالة.' },
      ],
    }
  },
  invitation_famille_importee: (d) => ({
    sujet: 'مساحتك في Rewayah Academy في انتظارك',
    apercu: 'تسجيلك موجود في التطبيق: سجّل الدخول بعنوان البريد الإلكتروني هذا.',
    titre: 'تسجيلك موجود في التطبيق',
    blocs: [
      { type: 'texte', texte: bonjour(d, PAROLE) },
      { type: 'texte', texte: 'أنتم مسجّلون في Rewayah Academy. ما يلي يجري في التطبيق: سجّلت الإدارة أسرتكم فيه.' },
      { type: 'texte', texte: 'سجّل الدخول بعنوان البريد الإلكتروني هذا، وستجد أسرتك دون إعادة إدخال أي شيء.' },
      { type: 'bouton', libelle: 'فتح مساحتي', href: `${APP}/#/connexion` },
      { type: 'note', texte: 'لن نطلب منك كلمة مرور ولا دفعًا عبر رسالة. الرابط يؤدي إلى عنواننا الرسمي app.rewayahacademy.com. إن كنت لا تعرف Rewayah Academy، فتجاهل هذه الرسالة.' },
    ],
  }),
  lien_inscription: (d) => {
    const quand = dateLongue(d.date_reponse, PAROLE.locale)
    const nom = typeof d.formulaire === 'string' && d.formulaire.trim() ? ` «${d.formulaire.trim()}»` : ''
    const rappel = `${quand ? `في ${quand}، أجبت` : 'أجبت'} عن نموذجنا${nom}.`
    return {
      sujet: 'ترشحك إلى Rewayah Academy: أنشئ حسابك',
      apercu: rappel,
      titre: 'ترشحك يتواصل في التطبيق',
      blocs: [
        { type: 'texte', texte: bonjour(d, PAROLE) },
        { type: 'texte', texte: rappel },
        { type: 'texte', texte: 'كان هذا النموذج لتقديم ترشحك لتعليم القرآن في Rewayah Academy، في فصول صغيرة وعبر الفيديو.' },
        { type: 'texte', texte: 'صار الترشح الآن في تطبيق Rewayah Academy، وإجاباتك موجودة فيه. أنشئ حسابك بعنوان البريد الإلكتروني نفسه الذي في النموذج، وسيظهر ترشحك فيه من تلقاء نفسه.' },
        { type: 'bouton', libelle: 'إنشاء حسابي', href: `${APP}/#/connexion?mode=creer&candidature=1${codeCandidat(d)}` },
        { type: 'texte', texte: 'لا شيء يُدفع: التقدّم بالترشح وإنشاء الحساب مجانيان. لا يدفع أي مرشح في أي مرحلة، ولن تطلب الأكاديمية منك مالًا أبدًا.' },
        { type: 'note', texte: 'لن نطلب منك كلمة مرور ولا دفعًا عبر رسالة. الرابط يؤدي إلى عنواننا الرسمي app.rewayahacademy.com. إن لم تملأ هذا النموذج، فتجاهل هذه الرسالة.' },
      ],
    }
  },
  // Ecrit a la main, phrase par phrase depuis le francais valide par le
  // directeur le 24/10 (pilote, 25/10/2026 : la traduction automatique
  // inversait des sens). Vouvoiement de respect (أنتم) ; le nom en arabe,
  // « أكاديمية الرواية » (registre de marque M-27, confirme par le directeur le
  // 25/10) ; « تطبيق Rewayah » garde le nom du produit affiche.
  attente_candidat: () => {
    const sujet = 'ترشحكم للتدريس في أكاديمية الرواية: ما وصلنا إليه'
    const accroche = 'ملأتم نموذجنا لتدريس القرآن في أكاديمية الرواية. نشكركم على ثقتكم، ومن حقكم علينا أن نوافيكم بجواب واضح.'
    return {
      sujet,
      apercu: accroche,
      titre: sujet,
      // Lettre personnelle (pilote, 25/10/2026) : jamais « Promotions ».
      lettre: true,
      blocs: [
        { type: 'texte', texte: 'السلام عليكم ورحمة الله،' },
        { type: 'texte', texte: accroche },
        { type: 'texte', texte: 'لقد أجاب قرابة ستمئة منكم. نقرأ كل ترشح على حدة، ولا نفتح الفصول إلا مع معلمين التقينا بهم. وهذا يتطلب وقتًا، ونفضّل أن نأخذ وقتنا على أن نُسيء العمل.' },
        { type: 'texte', texte: 'هذا ما سيحدث:' },
        { type: 'texte', texte: '1. في غضون ثلاثة أسابيع، ستصلكم منا رسالة شخصية عبر البريد الإلكتروني، في كل الأحوال.\n' +
          '2. إن كان ملفكم يوافق احتياجاتنا الحالية، فستتضمن هذه الرسالة دعوة إلى إنشاء حسابكم في تطبيق Rewayah، ثم مقابلة عبر الفيديو مع الإدارة.\n' +
          '3. وإن لم يكن الأمر كذلك في الوقت الحالي، فسنخبركم بذلك أيضًا، وسنحتفظ بترشحكم للفصول التي سنفتحها لاحقًا، إلا إذا فضّلتم أن نحذفه.' },
        { type: 'texte', texte: 'لا شيء عليكم دفعه، لا اليوم ولا لاحقًا: التدريس في أكاديمية الرواية عمل تتقاضون عليه أجرًا، ولا يُطلب منكم فيه أي مبلغ، ولا أي رسوم تدريب.' },
        { type: 'texte', texte: 'لا شيء مطلوب منكم اليوم. ولا حاجة إلى مراسلتنا للسؤال عن مآل طلبكم: نحن من سيتواصل معكم، على هذا العنوان.' },
        { type: 'texte', texte: 'وإن لم تعودوا ترغبون في التدريس معنا، فتكفي نقرة على الرابط في أسفل هذه الرسالة، دون حاجة إلى أي تبرير.' },
        { type: 'texte', texte: 'جزاكم الله خيرًا على مبادرتكم.' },
        { type: 'texte', texte: 'الإدارة\nأكاديمية الرواية' },
      ],
    }
  },
  // INVITATIONS-PERSONNELLES (07/11/2026) : ecrit a la main, mot pour mot depuis
  // la proposition du garde-cap (COURRIEL_INVITATION_2026-11-15.md, PR 306),
  // jamais traduit. « لنتعارف » doit rester identique au nom de l'entretien a
  // l'ecran (lot de E) : l'ecran fait foi. La phrase « ردوا على هذه الرسالة »
  // attend la meme confirmation que le francais.
  invitation_candidat_importe: (d) => {
    const code = typeof d.code === 'string' && /^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$/.test(d.code) ? d.code : null
    const fin = dateLongue(d.expire_le, PAROLE.locale)
    const promesse = d.variante === 'A'
    const lien = `${APP}/#/connexion?mode=creer&invitation=1${code ? `&code=${code}` : ''}`
    const sujet = 'دعوتكم الشخصية للانضمام إلى أكاديمية الرواية'
    return {
      sujet,
      apercu: promesse
        ? 'كما وعدناكم، هذا رابطكم الشخصي لمتابعة ترشحكم في التطبيق.'
        : 'هذا رابطكم الشخصي لمتابعة ترشحكم في التطبيق.',
      titre: sujet,
      lettre: true,
      blocs: [
        { type: 'texte', texte: 'السلام عليكم ورحمة الله،' },
        { type: 'texte', texte: promesse
          ? 'في أواخر أكتوبر، وعدناكم برسالة شخصية. وها هي.'
          : 'شكرًا لكم على ملء نموذجنا لتدريس القرآن في أكاديمية الرواية.' },
        { type: 'texte', texte: 'ندعوكم إلى متابعة ترشحكم في تطبيق Rewayah. كل شيء يتم في مكان واحد، وعلى قدر وقتكم:' },
        { type: 'texte', texte: '1. أنشئوا حسابكم بالزر أدناه. إجاباتكم على النموذج تنتظركم فيه: لا حاجة إلى إعادة كتابة أي شيء.\n' +
          '2. أكملوا ترشحكم: اقرؤوا التزاماتنا واقبلوها، وأضيفوا صورتكم ووثيقة هويتكم.\n' +
          '3. ثم اختاروا في التطبيق موعد مقابلتنا عبر الفيديو، «لنتعارف».' },
        { type: 'bouton', libelle: 'متابعة ترشحي', href: lien },
        ...(code ? [{ type: 'texte', texte: 'رمزكم الشخصي:' } as const, { type: 'code', code } as const] : []),
        { type: 'texte', texte: 'أنشئوا حسابكم بهذا البريد الإلكتروني: الرمز لا يعمل إلا معه. إن لم يفتح الزر، فافتحوا app.rewayahacademy.com، واضغطوا على «لدي رمز دعوة»، وانسخوا الرمز.' },
        { type: 'texte', texte: 'لا شيء عليكم دفعه، في أي مرحلة: التدريس في أكاديمية الرواية عمل تتقاضون عليه أجرًا.' },
        { type: 'note', texte: (fin ? `هذه الدعوة صالحة حتى ${fin} ولا تُستعمل إلا مرة واحدة. ` : 'هذه الدعوة لا تُستعمل إلا مرة واحدة. ') +
          'وإن لم تعودوا ترغبون في التدريس معنا، فتكفي نقرة على الرابط في أسفل هذه الرسالة، دون حاجة إلى أي تبرير.' },
        { type: 'texte', texte: promesse ? 'جزاكم الله خيرًا على صبركم.' : 'جزاكم الله خيرًا على مبادرتكم.' },
        { type: 'texte', texte: 'الإدارة\nأكاديمية الرواية' },
      ],
    }
  },
  message_libre: (d) => libre(d, PAROLE.sujetLibre),
  nouvelles: (d) => libre(d, PAROLE.sujetLibre),
}

export const ARABE: LangueEcrite = {
  modeles: MODELES,
  raisons: RAISON,
  desinscription: 'إيقاف تلقي هذه الرسائل',
  droiteAGauche: true,
}
