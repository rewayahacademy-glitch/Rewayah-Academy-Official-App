// Les e-mails en arabe, ecrits a la main (arabe standard, ton ferme et
// bienveillant). Ils suivent le sens du francais (`modeles_fr.ts`) ; memes
// liens, memes boutons. Vocabulaire de `assets/i18n/ar.i18n.json` : الفصل
// (classe), المعلم (enseignant), الإدارة (la direction), الأسرة (foyer).
// Chiffres latins, comme dans l'application ; dates en `ar-u-nu-latn`.

import { APP } from './gabarit.ts'
import { avisDans, bonjour, dateLongue, type Fabrique, type LangueEcrite, libre, type Parole } from './outils.ts'

const PAROLE: Parole = {
  salut: 'مرحبًا',
  fin: '،',
  salutSeul: 'مرحبًا،',
  note: 'تجد التفاصيل في التطبيق بعد تسجيل الدخول.',
  sujetLibre: 'رسالة من Rewayah Academy',
  locale: 'ar-u-nu-latn',
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

const MODELES: Record<string, Fabrique> = {
  demande_recue: (d) => avis(d, 'وصلنا طلبك', 'وصلنا طلبك',
    'وصلنا طلبك لحجز موعد. تدرسه الإدارة وتردّ عليك في التطبيق.',
    'متابعة طلبي', '/tuteur/demandes'),
  demande_presentation: (d) => avis(d, 'وصل طلب تعريفي', 'وصل طلب تعريفي',
    'وصل طلب تعريفي. هو في انتظارك في التطبيق.',
    'فتح الطلب', '/tuteur/demandes'),
  classe_validee: (d) => avis(d, 'فصلك جاهز', 'فصلك جاهز',
    'الفصل المطابق لطلبك جاهز. بقي أن يُعيَّن له معلمه، وسنُعلمك بذلك.',
    'عرض الفصل', '/tuteur/demandes'),
  enseignant_affecte: (d) => avis(d, 'عُيّن معلم للفصل', 'صار لفصلك معلم',
    'عُيّن معلم للفصل. تجد اسمه ومواعيده في التطبيق.',
    'عرض الفصل', '/tuteur/demandes'),
  demande_close: (d) => avis(d, 'أُغلق طلبك', 'أُغلق طلبك',
    'أُغلق طلبك لحجز موعد. ردّ الإدارة في التطبيق.',
    'قراءة الرد', '/tuteur/demandes'),
  classe_changee: (d) => avis(d, 'تغيير الفصل، في الموعد نفسه', 'تغيير الفصل',
    'انتقل أحد طلاب أسرتك إلى فصل آخر في الموعد نفسه.',
    'عرض التفاصيل', '/tuteur/demandes'),
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
  invitation_foyer: (d) => {
    const qui = typeof d.invite_par === 'string' && d.invite_par.trim() ? d.invite_par.trim() : 'أحد أفراد أسرتك'
    const fin = dateLongue(d.expire_le, PAROLE.locale)
    return {
      sujet: `${qui} يدعوك إلى الانضمام إلى أسرته في Rewayah Academy`,
      apercu: `${qui} يدعوك إلى متابعة دروس الأسرة معه.`,
      titre: 'دُعيت إلى الانضمام إلى أسرة',
      blocs: [
        { type: 'texte', texte: PAROLE.salutSeul },
        { type: 'texte', texte: `${qui} يدعوك إلى الانضمام إلى أسرته في Rewayah Academy، لمتابعة دروس الأسرة معًا.` },
        { type: 'texte', texte: 'سجّل الدخول بعنوان البريد الإلكتروني هذا: الدعوة في انتظارك في التطبيق.' },
        { type: 'bouton', libelle: 'فتح الدعوة', href: `${APP}/connexion` },
        { type: 'note', texte: (fin ? `الدعوة صالحة حتى ${fin}. ` : '') + 'إن كنت لا تعرف هذا الشخص، فتجاهل هذه الرسالة.' },
      ],
    }
  },
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
        { type: 'bouton', libelle: 'إنشاء حسابي', href: `${APP}/inscription` },
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
  message_libre: (d) => libre(d, PAROLE.sujetLibre),
  nouvelles: (d) => libre(d, PAROLE.sujetLibre),
}

export const ARABE: LangueEcrite = {
  modeles: MODELES,
  raisons: RAISON,
  desinscription: 'إيقاف تلقي هذه الرسائل',
  droiteAGauche: true,
}
