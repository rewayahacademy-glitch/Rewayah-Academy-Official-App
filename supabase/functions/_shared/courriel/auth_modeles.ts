// Les e-mails de Supabase Auth (lien de connexion, confirmation, invitation,
// changement d'adresse, nouveau mot de passe, reauthentification), composes
// avec le meme gabarit que la file (COURRIELS-1). Supabase les envoie lui-meme
// par le SMTP du projet (Workspace, support@) : on lui donne seulement le HTML.
// Les fichiers `supabase/templates/*.html` sont ecrits par
// `supabase/templates/generer.ts` ; `courriel_test.ts` verifie qu'ils sont a jour.
//
// Une langue par message : chaque fichier contient un `{{ if eq $l "en" }}` par
// langue ecrite (en, ar, es, pt) et le francais pour tout le reste. Supabase
// remplit `{{ .Data }}` avec le `user_metadata` du compte : l'application y
// inscrit `langue` (fr, en, ar, es, pt, ff…). Une langue non ecrite ici recoit
// le francais.
//
// ATTENTION, SUJETS : le sujet d'un e-mail Auth se regle dans
// `supabase/config.toml` (`[auth.email.template.*] subject`), en une seule
// chaine : il ne peut pas se ramifier par langue. Il reste donc en francais ;
// seul le corps est dans la langue du compte. Les sujets `sujet` ci-dessous
// ne servent qu'a la balise <title> du corps.

import { type Contenu, composer } from './gabarit.ts'

export const LANGUES_AUTH = ['en', 'ar', 'es', 'pt'] as const
export type LangueAuth = typeof LANGUES_AUTH[number]

const RAISON = 'Vous recevez cet e-mail parce qu’une demande a été faite avec cette adresse sur Rewayah Academy. Si ce n’est pas vous, ignorez-le : rien ne change sans ce lien.'
const RAISON_CODE = RAISON.replace('ce lien', 'ce code')

function lien(sujet: string, titre: string, phrase: string, bouton: string, note: string): Contenu {
  return {
    sujet, apercu: phrase, titre, raison: RAISON,
    blocs: [
      { type: 'texte', texte: 'Bonjour,' },
      { type: 'texte', texte: phrase },
      { type: 'bouton', libelle: bouton, href: '{{ .ConfirmationURL }}' },
      { type: 'note', texte: note },
      { type: 'lien', texte: 'Le bouton ne fonctionne pas ?', libelle: 'Ouvrir le lien', href: '{{ .ConfirmationURL }}' },
    ],
  }
}

export const MODELES_AUTH: Record<string, Contenu> = {
  magic_link: lien('Votre lien de connexion à Rewayah Academy', 'Votre lien de connexion',
    'Voici votre lien pour vous connecter à Rewayah Academy.', 'Me connecter',
    'Le lien est valable une heure et ne sert qu’une fois.'),
  confirmation: lien('Confirmez votre adresse e-mail', 'Confirmez votre adresse e-mail',
    'Pour terminer votre inscription à Rewayah Academy, confirmez votre adresse e-mail.', 'Confirmer mon adresse',
    'Le lien est valable une heure.'),
  invite: lien('Votre accès à Rewayah Academy', 'Votre accès est prêt',
    'La direction de Rewayah Academy a préparé votre accès. Ouvrez-le pour choisir comment vous connecter.',
    'Ouvrir mon accès', 'Le lien est valable une heure et ne sert qu’une fois.'),
  recovery: lien('Choisir un nouveau mot de passe', 'Choisir un nouveau mot de passe',
    'Une demande de nouveau mot de passe a été faite pour votre compte.', 'Choisir mon mot de passe',
    'Le lien est valable une heure. Votre mot de passe actuel reste valable tant que vous ne l’avez pas changé.'),
  email_change: lien('Confirmez votre nouvelle adresse e-mail', 'Confirmez votre nouvelle adresse',
    'Vous avez demandé à remplacer l’adresse de votre compte par {{ .NewEmail }}.', 'Confirmer le changement',
    'Tant que le changement n’est pas confirmé, votre adresse actuelle reste celle du compte.'),
  reauthentication: {
    sujet: 'Votre code de vérification', apercu: 'Le code à saisir pour confirmer votre action.',
    titre: 'Votre code de vérification', raison: RAISON_CODE,
    blocs: [
      { type: 'texte', texte: 'Bonjour,' },
      { type: 'texte', texte: 'Saisissez ce code dans l’application pour confirmer votre action :' },
      { type: 'code', code: '{{ .Token }}' },
      { type: 'note', texte: 'Le code est valable une heure. Ne le communiquez à personne : la direction ne vous le demandera jamais.' },
    ],
  },
}

/// Les mots d'une langue pour les six messages Auth.
interface TextesAuth {
  salut: string
  /// La question avant le lien de secours, et le mot du lien.
  copie: string
  ouvrir: string
  raison: string
  raisonCode: string
  droiteAGauche?: boolean
  /// [sujet, titre, phrase, bouton, note] pour les cinq messages a lien.
  magic_link: [string, string, string, string, string]
  confirmation: [string, string, string, string, string]
  invite: [string, string, string, string, string]
  recovery: [string, string, string, string, string]
  email_change: [string, string, string, string, string]
  /// [sujet, apercu, phrase, note]
  reauthentication: [string, string, string, string]
}

function jeu(langue: LangueAuth, t: TextesAuth): Record<string, Contenu> {
  const base = { langue, droiteAGauche: t.droiteAGauche ?? false }
  const lien = ([sujet, titre, phrase, bouton, note]: [string, string, string, string, string]): Contenu => ({
    ...base, sujet, apercu: phrase, titre, raison: t.raison,
    blocs: [
      { type: 'texte', texte: t.salut },
      { type: 'texte', texte: phrase },
      { type: 'bouton', libelle: bouton, href: '{{ .ConfirmationURL }}' },
      { type: 'note', texte: note },
      { type: 'lien', texte: t.copie, libelle: t.ouvrir, href: '{{ .ConfirmationURL }}' },
    ],
  })
  const [rs, ra, rp, rn] = t.reauthentication
  return {
    magic_link: lien(t.magic_link),
    confirmation: lien(t.confirmation),
    invite: lien(t.invite),
    recovery: lien(t.recovery),
    email_change: lien(t.email_change),
    reauthentication: {
      ...base, sujet: rs, apercu: ra, titre: rs, raison: t.raisonCode,
      blocs: [
        { type: 'texte', texte: t.salut },
        { type: 'texte', texte: rp },
        { type: 'code', code: '{{ .Token }}' },
        { type: 'note', texte: rn },
      ],
    },
  }
}

export const MODELES_AUTH_LANGUES: Record<LangueAuth, Record<string, Contenu>> = {
  en: jeu('en', {
    salut: 'Hello,',
    copie: 'The button does not work?',
    ouvrir: 'Open the link',
    raison: 'You are receiving this e-mail because a request was made with this address on Rewayah Academy. If it was not you, ignore it: nothing changes without this link.',
    raisonCode: 'You are receiving this e-mail because a request was made with this address on Rewayah Academy. If it was not you, ignore it: nothing changes without this code.',
    magic_link: ['Your sign-in link for Rewayah Academy', 'Your sign-in link',
      'Here is your link to sign in to Rewayah Academy.', 'Sign in', 'The link is valid for one hour and can only be used once.'],
    confirmation: ['Confirm your e-mail address', 'Confirm your e-mail address',
      'To finish your registration with Rewayah Academy, confirm your e-mail address.', 'Confirm my address',
      'The link is valid for one hour.'],
    invite: ['Your access to Rewayah Academy', 'Your access is ready',
      'The management of Rewayah Academy has prepared your access. Open it to choose how you sign in.',
      'Open my access', 'The link is valid for one hour and can only be used once.'],
    recovery: ['Choose a new password', 'Choose a new password',
      'A request for a new password was made for your account.', 'Choose my password',
      'The link is valid for one hour. Your current password stays valid until you change it.'],
    email_change: ['Confirm your new e-mail address', 'Confirm your new address',
      'You asked to replace your account’s address with {{ .NewEmail }}.', 'Confirm the change',
      'Until the change is confirmed, your current address remains the account’s address.'],
    reauthentication: ['Your verification code', 'The code to enter to confirm your action.',
      'Enter this code in the app to confirm your action:',
      'The code is valid for one hour. Do not share it with anyone: the management will never ask you for it.'],
  }),
  ar: jeu('ar', {
    salut: 'مرحبًا،',
    copie: 'لا يعمل الزر؟',
    ouvrir: 'افتح الرابط',
    raison: 'وصلتك هذه الرسالة لأن طلبًا قُدّم بهذا العنوان في Rewayah Academy. إن لم تكن أنت، فتجاهلها: لا يتغير شيء دون هذا الرابط.',
    raisonCode: 'وصلتك هذه الرسالة لأن طلبًا قُدّم بهذا العنوان في Rewayah Academy. إن لم تكن أنت، فتجاهلها: لا يتغير شيء دون هذا الرمز.',
    droiteAGauche: true,
    magic_link: ['رابط تسجيل دخولك إلى Rewayah Academy', 'رابط تسجيل الدخول',
      'هذا هو رابطك لتسجيل الدخول إلى Rewayah Academy.', 'تسجيل الدخول', 'الرابط صالح لمدة ساعة ولا يُستعمل إلا مرة واحدة.'],
    confirmation: ['أكّد عنوان بريدك الإلكتروني', 'أكّد عنوان بريدك الإلكتروني',
      'لإتمام تسجيلك في Rewayah Academy، أكّد عنوان بريدك الإلكتروني.', 'تأكيد عنواني', 'الرابط صالح لمدة ساعة.'],
    invite: ['دخولك إلى Rewayah Academy', 'دخولك جاهز',
      'أعدّت إدارة Rewayah Academy دخولك. افتحه لتختار طريقة تسجيل الدخول.', 'فتح دخولي',
      'الرابط صالح لمدة ساعة ولا يُستعمل إلا مرة واحدة.'],
    recovery: ['اختيار كلمة مرور جديدة', 'اختيار كلمة مرور جديدة',
      'قُدّم طلب لكلمة مرور جديدة لحسابك.', 'اختيار كلمة المرور',
      'الرابط صالح لمدة ساعة. تبقى كلمة مرورك الحالية سارية ما لم تغيّرها.'],
    email_change: ['أكّد عنوان بريدك الإلكتروني الجديد', 'أكّد عنوانك الجديد',
      'طلبت استبدال عنوان حسابك بـ {{ .NewEmail }}.', 'تأكيد التغيير',
      'ما دام التغيير غير مؤكَّد، يبقى عنوانك الحالي هو عنوان الحساب.'],
    reauthentication: ['رمز التحقق الخاص بك', 'الرمز الذي تُدخله لتأكيد إجراءك.',
      'أدخل هذا الرمز في التطبيق لتأكيد إجراءك:',
      'الرمز صالح لمدة ساعة. لا تعطه لأحد: لن تطلبه منك الإدارة أبدًا.'],
  }),
  es: jeu('es', {
    salut: 'Hola,',
    copie: '¿No funciona el botón?',
    ouvrir: 'Abrir el enlace',
    raison: 'Recibe este correo electrónico porque se ha hecho una solicitud con esta dirección en Rewayah Academy. Si no ha sido usted, ignórelo: nada cambia sin este enlace.',
    raisonCode: 'Recibe este correo electrónico porque se ha hecho una solicitud con esta dirección en Rewayah Academy. Si no ha sido usted, ignórelo: nada cambia sin este código.',
    magic_link: ['Su enlace de acceso a Rewayah Academy', 'Su enlace de acceso',
      'Este es su enlace para iniciar sesión en Rewayah Academy.', 'Iniciar sesión',
      'El enlace es válido durante una hora y solo sirve una vez.'],
    confirmation: ['Confirme su dirección de correo electrónico', 'Confirme su dirección de correo electrónico',
      'Para terminar su registro en Rewayah Academy, confirme su dirección de correo electrónico.',
      'Confirmar mi dirección', 'El enlace es válido durante una hora.'],
    invite: ['Su acceso a Rewayah Academy', 'Su acceso está listo',
      'La dirección de Rewayah Academy ha preparado su acceso. Ábralo para elegir cómo iniciar sesión.',
      'Abrir mi acceso', 'El enlace es válido durante una hora y solo sirve una vez.'],
    recovery: ['Elija una nueva contraseña', 'Elija una nueva contraseña',
      'Se ha solicitado una nueva contraseña para su cuenta.', 'Elegir mi contraseña',
      'El enlace es válido durante una hora. Su contraseña actual sigue siendo válida mientras no la cambie.'],
    email_change: ['Confirme su nueva dirección de correo electrónico', 'Confirme su nueva dirección',
      'Ha solicitado sustituir la dirección de su cuenta por {{ .NewEmail }}.', 'Confirmar el cambio',
      'Mientras no se confirme el cambio, su dirección actual sigue siendo la de la cuenta.'],
    reauthentication: ['Su código de verificación', 'El código que debe introducir para confirmar su acción.',
      'Introduzca este código en la aplicación para confirmar su acción:',
      'El código es válido durante una hora. No se lo comunique a nadie: la dirección nunca se lo pedirá.'],
  }),
  pt: jeu('pt', {
    salut: 'Olá,',
    copie: 'O botão não funciona?',
    ouvrir: 'Abrir a ligação',
    raison: 'Recebe este e-mail porque foi feito um pedido com este endereço na Rewayah Academy. Se não foi você, ignore-o: nada muda sem esta ligação.',
    raisonCode: 'Recebe este e-mail porque foi feito um pedido com este endereço na Rewayah Academy. Se não foi você, ignore-o: nada muda sem este código.',
    magic_link: ['A sua ligação de acesso à Rewayah Academy', 'A sua ligação de acesso',
      'Aqui está a sua ligação para iniciar sessão na Rewayah Academy.', 'Iniciar sessão',
      'A ligação é válida durante uma hora e só pode ser usada uma vez.'],
    confirmation: ['Confirme o seu endereço de e-mail', 'Confirme o seu endereço de e-mail',
      'Para concluir o seu registo na Rewayah Academy, confirme o seu endereço de e-mail.',
      'Confirmar o meu endereço', 'A ligação é válida durante uma hora.'],
    invite: ['O seu acesso à Rewayah Academy', 'O seu acesso está pronto',
      'A direção da Rewayah Academy preparou o seu acesso. Abra-o para escolher como iniciar sessão.',
      'Abrir o meu acesso', 'A ligação é válida durante uma hora e só pode ser usada uma vez.'],
    recovery: ['Escolha uma nova palavra-passe', 'Escolha uma nova palavra-passe',
      'Foi feito um pedido de nova palavra-passe para a sua conta.', 'Escolher a minha palavra-passe',
      'A ligação é válida durante uma hora. A sua palavra-passe atual continua válida enquanto não a alterar.'],
    email_change: ['Confirme o seu novo endereço de e-mail', 'Confirme o seu novo endereço',
      'Pediu para substituir o endereço da sua conta por {{ .NewEmail }}.', 'Confirmar a alteração',
      'Enquanto a alteração não for confirmada, o seu endereço atual continua a ser o da conta.'],
    reauthentication: ['O seu código de verificação', 'O código a introduzir para confirmar a sua ação.',
      'Introduza este código na aplicação para confirmar a sua ação:',
      'O código é válido durante uma hora. Não o partilhe com ninguém: a direção nunca lho pedirá.'],
  }),
}

/// Le HTML d'un message Auth dans une langue (le francais si `langue` est absente).
export function htmlAuthDans(nom: string, langue?: LangueAuth): string {
  const c = langue ? MODELES_AUTH_LANGUES[langue][nom] : MODELES_AUTH[nom]
  return composer(c).html
}

/// Le fichier Supabase d'un message : une branche Go-template par langue
/// ecrite, le francais en repli. `$l` vaut "" quand le compte n'a pas de langue.
export function htmlAuth(nom: string): string {
  const branches = LANGUES_AUTH.map((l, i) =>
    `{{ ${i === 0 ? 'if' : 'else if'} eq $l "${l}" }}${htmlAuthDans(nom, l)}`).join('')
  return `{{ $l := "" }}{{ if .Data }}{{ $l = printf "%v" .Data.langue }}{{ end }}${branches}{{ else }}${htmlAuthDans(nom)}{{ end }}`
}
