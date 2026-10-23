// L'envoi lui-meme (COURRIELS-1). Deux transports, choisis par le secret
// `COURRIEL_TRANSPORT` :
//
// - `smtp` (par defaut) : Google Workspace, ou vivent deja les alias
//   (support@, contact@, invoices@, recrutement@). `smtp.gmail.com`, port 465
//   (les fonctions Edge refusent 25 et 587). Secrets : `SMTP_UTILISATEUR`
//   (le compte Workspace), `SMTP_MOT_DE_PASSE` (mot de passe d'application).
//   Chaque alias doit figurer dans « Envoyer des e-mails en tant que » de ce
//   compte, sinon Gmail reecrit l'expediteur.
// - `resend` : API HTTP, secret `RESEND_API_KEY` ; le domaine doit y etre
//   verifie (DKIM sur un sous-domaine, voir docs/current/COURRIELS.md).
//
// `COURRIEL_TRANSPORT=journal` n'envoie rien et ecrit l'en-tete dans les
// journaux : pour la recette sur staging.

import nodemailer from 'npm:nodemailer@6.9.16'

export interface Envoi {
  de: string
  deNom: string
  repondreA: string
  a: string
  sujet: string
  html: string
  texte: string
  /// URL HTTPS de desinscription en un clic (RFC 8058), categories non essentielles.
  desinscriptionUnClic?: string
  /// Identifiant stable : Gmail regroupe sans doublon un message renvoye.
  idMessage: string
}

export interface Resultat {
  ok: boolean
  id?: string
  erreur?: string
}

function entetes(e: Envoi): Record<string, string> {
  const h: Record<string, string> = { 'X-Entity-Ref-ID': e.idMessage }
  if (e.desinscriptionUnClic) {
    h['List-Unsubscribe'] = `<${e.desinscriptionUnClic}>`
    h['List-Unsubscribe-Post'] = 'List-Unsubscribe=One-Click'
  }
  return h
}

let smtp: ReturnType<typeof nodemailer.createTransport> | null = null

async function parSmtp(e: Envoi): Promise<Resultat> {
  const user = Deno.env.get('SMTP_UTILISATEUR')
  const pass = Deno.env.get('SMTP_MOT_DE_PASSE')
  if (!user || !pass) return { ok: false, erreur: 'configuration absente : SMTP_UTILISATEUR ou SMTP_MOT_DE_PASSE' }
  smtp ??= nodemailer.createTransport({
    host: Deno.env.get('SMTP_HOTE') ?? 'smtp.gmail.com',
    port: Number(Deno.env.get('SMTP_PORT') ?? '465'),
    secure: true,
    auth: { user, pass },
    pool: true,
    maxConnections: 2,
  })
  try {
    const r = await smtp.sendMail({
      from: { name: e.deNom, address: e.de },
      replyTo: e.repondreA,
      to: e.a,
      subject: e.sujet,
      html: e.html,
      text: e.texte,
      messageId: `<${e.idMessage}@rewayahacademy.com>`,
      headers: entetes(e),
    })
    return { ok: true, id: r.messageId }
  } catch (err) {
    return { ok: false, erreur: String((err as Error).message ?? err).slice(0, 300) }
  }
}

async function parResend(e: Envoi): Promise<Resultat> {
  const cle = Deno.env.get('RESEND_API_KEY')
  if (!cle) return { ok: false, erreur: 'configuration absente : RESEND_API_KEY' }
  const r = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { Authorization: `Bearer ${cle}`, 'Content-Type': 'application/json', 'Idempotency-Key': e.idMessage },
    body: JSON.stringify({
      from: `${e.deNom} <${e.de}>`,
      reply_to: e.repondreA,
      to: [e.a],
      subject: e.sujet,
      html: e.html,
      text: e.texte,
      headers: entetes(e),
    }),
  })
  const corps = await r.json().catch(() => ({}))
  return r.ok ? { ok: true, id: corps.id } : { ok: false, erreur: `resend ${r.status} ${JSON.stringify(corps).slice(0, 250)}` }
}

export function envoyer(e: Envoi): Promise<Resultat> {
  const t = Deno.env.get('COURRIEL_TRANSPORT') ?? 'smtp'
  if (t === 'resend') return parResend(e)
  if (t === 'journal') {
    console.log(JSON.stringify({ courriel: e.idMessage, de: e.de, a: e.a.replace(/^(.).*@/, '$1***@'), sujet: e.sujet }))
    return Promise.resolve({ ok: true, id: `journal-${e.idMessage}` })
  }
  return parSmtp(e)
}
