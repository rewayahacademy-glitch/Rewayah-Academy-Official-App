// PUSH-1 : les textes des notifications push, en francais et en arabe.
//
// Regle du garde-cap (le texte se lit sur un ecran verrouille) : jamais de nom
// de personne, jamais de montant, jamais de motif de signalement. Le detail se
// lit dans l'application, apres connexion. Vocabulaire : competence
// mots-rewayah (Classe, la direction, masculin generique, vouvoiement, pas de
// tiret long, aucun emoji, aucun code interne).
//
// Titre court (40 caracteres au plus), texte d'une phrase (120 au plus) qui dit
// le fait et le geste attendu.

export type Langue = 'fr' | 'ar'

export interface TextePush {
  titre: string
  texte: string
}

export const TITRE = 'Rewayah Academy'

const STAFF = new Set(['direction', 'comptable'])
const estStaff = (p: string | null) => p !== null && STAFF.has(p)
const estFamille = (p: string | null) => p === 'foyer' || p === 'soi'

type Choix = (portee: string | null) => string
type Ligne = { fr: string | Choix; ar: string | Choix }

/// Les textes au singulier, par evenement.
export const TEXTES: Record<string, Ligne> = {
  seance_annulee: {
    fr: 'Une séance est annulée : consultez le planning dans l\'application.',
    ar: 'أُلغيت حصة: اطّلعوا على الجدول في التطبيق.',
  },
  seance_deplacee: {
    fr: 'Une séance est déplacée : consultez la nouvelle date dans l\'application.',
    ar: 'نُقلت حصة إلى موعد جديد: اطّلعوا عليه في التطبيق.',
  },
  // Le code dit « enseignante » ; on ecrit toujours « enseignant absent ».
  enseignante_absente: {
    fr: (p) => estStaff(p)
      ? 'Un enseignant est absent : trouvez un remplaçant dans l\'application.'
      : 'L\'enseignant est absent pour une séance : suivez la suite dans l\'application.',
    ar: (p) => estStaff(p)
      ? 'معلم غائب: ابحثوا عن بديل في التطبيق.'
      : 'المعلم غائب عن حصة: تابعوا المستجدات في التطبيق.',
  },
  remplacement_propose: {
    fr: 'Un remplacement vous est proposé : répondez dans l\'application.',
    ar: 'عُرض عليكم تعويض حصة: أجيبوا في التطبيق.',
  },
  remplacement_pris: {
    fr: 'Le remplacement est attribué : consultez votre journée dans l\'application.',
    ar: 'أُسند التعويض: اطّلعوا على يومكم في التطبيق.',
  },
  remplacement_designe_admin: {
    fr: 'La direction vous a désigné pour un remplacement : consultez la séance dans l\'application.',
    ar: 'عيّنتكم الإدارة لتعويض حصة: اطّلعوا عليها في التطبيق.',
  },
  remplacement_pre_alerte: {
    fr: 'Un remplacement se prépare : dites si vous êtes disponible dans l\'application.',
    ar: 'يجري التحضير لتعويض حصة: أعلنوا استعدادكم في التطبيق.',
  },
  remplacement_avertissement: {
    fr: 'Vous n\'êtes pas encore dans la salle : rejoignez-la maintenant.',
    ar: 'لستم في القاعة بعد: انضموا إليها الآن.',
  },
  remplacement_inutile: {
    fr: 'Le remplacement n\'est plus nécessaire : merci de votre disponibilité.',
    ar: 'لم يعد التعويض ضروريًا: شكرًا لاستعدادكم.',
  },
  remplacement_personne_en_salle: {
    fr: 'Personne n\'est dans la salle d\'une classe : trouvez un remplaçant ou prévenez les familles.',
    ar: 'لا أحد في قاعة أحد الفصول: ابحثوا عن بديل أو أبلغوا الأسر.',
  },
  creneau_change: {
    fr: 'L\'horaire de la classe change : consultez le nouvel horaire dans l\'application.',
    ar: 'تغيّر موعد الفصل: اطّلعوا على الموعد الجديد في التطبيق.',
  },
  titulaire_en_retard: {
    fr: (p) => estStaff(p)
      ? 'Un enseignant n\'est pas entré dans sa salle : un remplaçant est recherché.'
      : 'L\'enseignant est en retard : restez dans la salle, un remplaçant est recherché.',
    ar: (p) => estStaff(p)
      ? 'معلم لم يدخل قاعته: يجري البحث عن بديل.'
      : 'المعلم متأخر: ابقوا في القاعة، يجري البحث عن بديل.',
  },
  seance_reportee: {
    fr: (p) => estStaff(p)
      ? 'Une séance est reportée : fixez la nouvelle date dans l\'application.'
      : 'Une séance est reportée : la nouvelle date sera donnée dans l\'application.',
    ar: (p) => estStaff(p)
      ? 'أُجّلت حصة: حدّدوا الموعد الجديد في التطبيق.'
      : 'أُجّلت حصة: سيُعلَن الموعد الجديد في التطبيق.',
  },
  classe_validee: {
    fr: 'Votre classe est prête : consultez-la dans l\'application.',
    ar: 'فصلكم جاهز: اطّلعوا عليه في التطبيق.',
  },
  classe_creee: {
    fr: 'Une nouvelle classe est créée : consultez-la dans l\'application.',
    ar: 'أُنشئ فصل جديد: اطّلعوا عليه في التطبيق.',
  },
  classe_changee: {
    fr: 'La classe a changé : consultez les détails dans l\'application.',
    ar: 'طرأ تغيير على الفصل: اطّلعوا على التفاصيل في التطبيق.',
  },
  classe_supprimee: {
    fr: 'La classe est fermée : la direction vous donne la suite dans l\'application.',
    ar: 'أُغلق الفصل: تُعلمكم الإدارة بما يلي في التطبيق.',
  },
  enseignant_affecte: {
    fr: (p) => p === 'soi'
      ? 'Une classe vous est confiée : consultez-la dans l\'application.'
      : 'Un enseignant est affecté à la classe : consultez la classe dans l\'application.',
    ar: (p) => p === 'soi'
      ? 'أُسند إليكم فصل: اطّلعوا عليه في التطبيق.'
      : 'عُيّن معلم للفصل: اطّلعوا على الفصل في التطبيق.',
  },
  enseignant_change: {
    fr: 'L\'enseignant de la classe change : consultez la classe dans l\'application.',
    ar: 'تغيّر معلم الفصل: اطّلعوا على الفصل في التطبيق.',
  },
  eleve_inscrit: {
    fr: (p) => estFamille(p)
      ? 'L\'inscription dans la classe est faite : consultez l\'horaire dans l\'application.'
      : estStaff(p)
      ? 'Un élève est inscrit dans une classe : consultez la classe dans l\'application.'
      : 'Un élève rejoint votre classe : consultez la liste dans l\'application.',
    ar: (p) => estFamille(p)
      ? 'تمّ التسجيل في الفصل: اطّلعوا على الموعد في التطبيق.'
      : estStaff(p)
      ? 'سُجّل طالب في فصل: اطّلعوا على الفصل في التطبيق.'
      : 'ينضم طالب إلى فصلكم: اطّلعوا على القائمة في التطبيق.',
  },
  eleve_retire: {
    fr: (p) => estFamille(p)
      ? 'Un élève du foyer quitte une classe : consultez le détail dans l\'application.'
      : estStaff(p)
      ? 'Un élève est retiré d\'une classe : consultez la classe dans l\'application.'
      : 'Un élève quitte votre classe : consultez la liste à jour dans l\'application.',
    ar: (p) => estFamille(p)
      ? 'غادر أحد طلاب الأسرة فصلًا: اطّلعوا على التفاصيل في التطبيق.'
      : estStaff(p)
      ? 'سُحب طالب من فصل: اطّلعوا على الفصل في التطبيق.'
      : 'يغادر طالب فصلكم: اطّلعوا على القائمة المحدّثة في التطبيق.',
  },
  demande_recue: {
    fr: (p) => estStaff(p)
      ? 'Une nouvelle demande d\'inscription est arrivée : examinez-la dans l\'application.'
      : 'Votre demande est bien reçue : suivez-la dans l\'application.',
    ar: (p) => estStaff(p)
      ? 'وصل طلب تسجيل جديد: ادرسوه في التطبيق.'
      : 'وصل طلبكم: تابعوه في التطبيق.',
  },
  demande_close: {
    fr: (p) => estStaff(p)
      ? 'Une demande est close : consultez-la dans l\'application.'
      : 'Votre demande est close : consultez la réponse dans l\'application.',
    ar: (p) => estStaff(p)
      ? 'أُغلق طلب: اطّلعوا عليه في التطبيق.'
      : 'أُغلق طلبكم: اطّلعوا على الرد في التطبيق.',
  },
  demande_presentation: {
    fr: 'Une demande de présentation est reçue : ouvrez-la dans l\'application.',
    ar: 'وصل طلب تقديم: افتحوه في التطبيق.',
  },
  controle_mission_attribuee: {
    fr: 'Une mission de contrôle vous est attribuée : ouvrez-la dans l\'application.',
    ar: 'أُسندت إليكم مهمة مراقبة: افتحوها في التطبيق.',
  },
  controle_mission_non_controlee: {
    fr: 'Une mission de contrôle n\'a pas été faite : consultez-la dans l\'application.',
    ar: 'بقيت مهمة مراقبة دون تحقق: اطّلعوا عليها في التطبيق.',
  },
  paiement_relance: {
    fr: 'Le paiement du mois arrive bientôt : réglez-le dans l\'application.',
    ar: 'يحين قريبًا موعد دفعة الشهر: سدّدوها في التطبيق.',
  },
  acces_suspendu_paiement: {
    fr: 'L\'accès à la classe est suspendu faute de paiement : réglez-le dans l\'application.',
    ar: 'أُوقف الوصول إلى الفصل لعدم وصول الدفعة: سدّدوها في التطبيق.',
  },
  acces_retabli_paiement: {
    fr: 'Le paiement est arrivé : l\'accès à la classe est rétabli.',
    ar: 'وصلت الدفعة: أُعيد الوصول إلى الفصل.',
  },
  paiement_recu: {
    fr: (p) => estStaff(p)
      ? 'Un paiement est arrivé : consultez-le dans l\'application.'
      : 'Votre paiement est arrivé : le solde est à jour dans l\'application.',
    ar: (p) => estStaff(p)
      ? 'وصلت دفعة: اطّلعوا عليها في التطبيق.'
      : 'وصلت دفعتكم: الرصيد محدَّث في التطبيق.',
  },
  remboursement_effectue: {
    fr: 'Un remboursement est effectué : le solde est à jour dans l\'application.',
    ar: 'تمّ استرداد مبلغ: الرصيد محدَّث في التطبيق.',
  },
  litige_ouvert: {
    fr: (p) => estStaff(p)
      ? 'Un paiement est contesté auprès de la banque : traitez la contestation dans l\'application.'
      : 'Un paiement est contesté auprès de la banque : consultez le détail dans l\'application.',
    ar: (p) => estStaff(p)
      ? 'دفعة معترَض عليها لدى البنك: عالجوا الاعتراض في التطبيق.'
      : 'دفعة معترَض عليها لدى البنك: اطّلعوا على التفاصيل في التطبيق.',
  },
  litige_clos: {
    fr: 'La contestation d\'un paiement est close : consultez l\'issue dans l\'application.',
    ar: 'أُغلق الاعتراض على دفعة: اطّلعوا على النتيجة في التطبيق.',
  },
  message_academie_eleve: {
    fr: 'La direction vous a écrit : lisez le message dans l\'application.',
    ar: 'كتبت إليكم الإدارة: اقرؤوا الرسالة في التطبيق.',
  },

  // Nouveaux evenements PUSH-1.
  admission_recue: {
    fr: 'Une nouvelle candidature est à examiner dans l\'application.',
    ar: 'طلب جديد بانتظار الدراسة في التطبيق.',
  },
  candidature_enseignant_a_examiner: {
    fr: 'Une candidature d\'enseignant est à examiner dans l\'application.',
    ar: 'طلب انضمام معلم بانتظار الدراسة في التطبيق.',
  },
  demande_horaire_recue: {
    fr: 'Une nouvelle demande d\'horaire est à examiner dans l\'application.',
    ar: 'طلب موعد جديد بانتظار الدراسة في التطبيق.',
  },
  creneau_personnalise_demande: {
    fr: 'Un horaire personnalisé est demandé : examinez la demande dans l\'application.',
    ar: 'طُلب موعد خاص: ادرسوا الطلب في التطبيق.',
  },
  piece_identite_deposee: {
    fr: 'Une pièce d\'identité est déposée : vérifiez-la dans l\'application.',
    ar: 'أُودعت وثيقة هوية: تحقّقوا منها في التطبيق.',
  },
  signalement_eleve_recu: {
    fr: 'Un signalement attend votre décision dans l\'application.',
    ar: 'بلاغ بانتظار قراركم في التطبيق.',
  },
  suppression_compte_demandee: {
    fr: 'Une suppression de compte est demandée : traitez la demande dans l\'application.',
    ar: 'طُلب حذف حساب: عالجوا الطلب في التطبيق.',
  },
  paiement_echoue: {
    fr: (p) => estStaff(p)
      ? 'Un paiement a échoué : consultez le détail dans l\'application.'
      : 'Votre paiement n\'a pas abouti : ouvrez l\'application et touchez Recharger.',
    ar: (p) => estStaff(p)
      ? 'تعذّر إتمام دفعة: اطّلعوا على التفاصيل في التطبيق.'
      : 'لم تكتمل دفعتكم: افتحوا التطبيق واضغطوا على «شحن».',
  },
  versement_coordonnees_a_valider: {
    fr: 'Des coordonnées de versement sont à valider dans l\'application.',
    ar: 'بيانات تحويل بانتظار المصادقة في التطبيق.',
  },
  versement_coordonnees_validees: {
    fr: 'Vos coordonnées de versement sont validées : vérifiez-les dans l\'application.',
    ar: 'صودق على بيانات التحويل الخاصة بكم: راجعوها في التطبيق.',
  },
  remboursement_demande: {
    fr: 'Un remboursement est demandé : traitez la demande dans l\'application.',
    ar: 'طُلب استرداد مبلغ: عالجوا الطلب في التطبيق.',
  },
  remboursement_echec: {
    fr: 'Un remboursement n\'a pas abouti : consultez le détail dans l\'application.',
    ar: 'تعذّر إتمام استرداد: اطّلعوا على التفاصيل في التطبيق.',
  },
  cahier_en_retard: {
    fr: (p) => estStaff(p)
      ? 'Un cahier de séance est en retard : consultez-le dans l\'application.'
      : 'Le cahier d\'une séance attend d\'être rempli : complétez-le dans l\'application.',
    ar: (p) => estStaff(p)
      ? 'دفتر حصة متأخر: اطّلعوا عليه في التطبيق.'
      : 'دفتر إحدى الحصص لم يُملأ بعد: أكملوه في التطبيق.',
  },
}

export const GENERIQUE: Record<Langue, string> = {
  fr: 'Une nouvelle notification vous attend dans l\'application.',
  ar: 'إشعار جديد بانتظاركم في التطبيق.',
}

// ---------------------------------------------------------------------------
// Pluriel

/// Les formes d'un nom compte en arabe : deux (duel), 3 a 10 (pluriel),
/// 11 a 99 (singulier a l'accusatif), centaines rondes (singulier au genitif).
interface FormesAr {
  deux: string
  pluriel: (n: number) => string
  accusatif: (n: number) => string
  genitif: (n: number) => string
}

export function nombreAr(n: number, f: FormesAr): string {
  if (n === 2) return f.deux
  const r = n % 100
  if (r >= 3 && r <= 10) return f.pluriel(n)
  if (r >= 11 && r <= 99) return f.accusatif(n)
  // 100, 101, 102, 200... : le nom compte suit au genitif singulier.
  return f.genitif(n)
}

interface Pluriel {
  fr: (n: number, p: string | null) => string
  ar: (n: number, p: string | null) => string
}

const CANDIDATURES: Pluriel = {
  fr: (n) => `${n} nouvelles candidatures à examiner`,
  ar: (n) => nombreAr(n, {
    deux: 'طلبان جديدان بانتظار الدراسة',
    pluriel: (k) => `${k} طلبات جديدة بانتظار الدراسة`,
    accusatif: (k) => `${k} طلبًا جديدًا بانتظار الدراسة`,
    genitif: (k) => `${k} طلب جديد بانتظار الدراسة`,
  }),
}

const PIECES: Pluriel = {
  fr: (n) => `${n} pièces d'identité à vérifier`,
  ar: (n) => nombreAr(n, {
    deux: 'وثيقتا هوية بانتظار التحقق',
    pluriel: (k) => `${k} وثائق هوية بانتظار التحقق`,
    accusatif: (k) => `${k} وثيقة هوية بانتظار التحقق`,
    genitif: (k) => `${k} وثيقة هوية بانتظار التحقق`,
  }),
}

const SIGNALEMENTS: Pluriel = {
  fr: (n) => `${n} signalements attendent votre décision`,
  ar: (n) => nombreAr(n, {
    deux: 'بلاغان بانتظار قراركم',
    pluriel: (k) => `${k} بلاغات بانتظار قراركم`,
    accusatif: (k) => `${k} بلاغًا بانتظار قراركم`,
    genitif: (k) => `${k} بلاغ بانتظار قراركم`,
  }),
}

const PAIEMENTS_ECHOUES: Pluriel = {
  fr: (n) => `${n} paiements ont échoué : consultez le détail dans l'application`,
  ar: (n) => nombreAr(n, {
    deux: 'تعذّر إتمام دفعتين: اطّلعوا على التفاصيل في التطبيق',
    pluriel: (k) => `تعذّر إتمام ${k} دفعات: اطّلعوا على التفاصيل في التطبيق`,
    accusatif: (k) => `تعذّر إتمام ${k} دفعةً: اطّلعوا على التفاصيل في التطبيق`,
    genitif: (k) => `تعذّر إتمام ${k} دفعة: اطّلعوا على التفاصيل في التطبيق`,
  }),
}

const GENERIQUE_PLURIEL: Pluriel = {
  fr: (n) => `${n} nouvelles notifications vous attendent dans l'application`,
  ar: (n) => nombreAr(n, {
    deux: 'إشعاران جديدان بانتظاركم في التطبيق',
    pluriel: (k) => `${k} إشعارات جديدة بانتظاركم في التطبيق`,
    accusatif: (k) => `${k} إشعارًا جديدًا بانتظاركم في التطبيق`,
    genitif: (k) => `${k} إشعار جديد بانتظاركم في التطبيق`,
  }),
}

/// Le pluriel par evenement ; les autres evenements regroupes prennent le
/// pluriel generique.
export const PLURIELS: Record<string, Pluriel> = {
  admission_recue: CANDIDATURES,
  candidature_enseignant_a_examiner: CANDIDATURES,
  demande_horaire_recue: CANDIDATURES,
  piece_identite_deposee: PIECES,
  signalement_eleve_recu: SIGNALEMENTS,
}

function lireChoix(c: string | Choix, portee: string | null): string {
  return typeof c === 'string' ? c : c(portee)
}

/// Le titre et le texte d'un push. Toute langue autre que l'arabe tombe en
/// francais. `nombre` > 1 avec une etiquette : texte au pluriel avec le nombre.
export function texteDuPush(
  evenement: string,
  portee: string | null,
  langue: string | null,
  nombre: number,
  tag: string | null = null,
): TextePush {
  const l: Langue = langue === 'ar' ? 'ar' : 'fr'
  const n = Number.isFinite(nombre) ? Math.floor(nombre) : 1
  if (n > 1 && tag) {
    let pl = PLURIELS[evenement]
    if (!pl && evenement === 'paiement_echoue' && estStaff(portee)) pl = PAIEMENTS_ECHOUES
    pl ??= GENERIQUE_PLURIEL
    return { titre: TITRE, texte: `${pl[l](n, portee)}.` }
  }
  const ligne = TEXTES[evenement]
  return { titre: TITRE, texte: ligne ? lireChoix(ligne[l], portee) : GENERIQUE[l] }
}
