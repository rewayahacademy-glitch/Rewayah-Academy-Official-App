// COURRIELS-1 : vide la file des e-mails. Appelee chaque minute par pg_cron
// (migration 20261023120000), ou a la main par la direction apres un envoi
// manuel. Ouverte sans JWT (config.toml) : la porte est le secret partage
// `COURRIELS_ENVOI_SECRET`, en en-tete `x-courriels-secret`, compare en temps
// constant. La cle de service ne sert qu'aux deux RPC du travailleur.

import { clientService, json, refus } from '../_shared/clients.ts'
import { composer } from '../_shared/courriel/gabarit.ts'
import { rendre } from '../_shared/courriel/modeles.ts'
import { traduireContenu } from '../_shared/courriel/traduction.ts'
import { envoyer, lienUnClic } from '../_shared/courriel/transport.ts'

function egal(a: string, b: string): boolean {
  const x = new TextEncoder().encode(a)
  const y = new TextEncoder().encode(b)
  let d = x.length ^ y.length
  for (let i = 0; i < Math.max(x.length, y.length); i++) d |= (x[i] ?? 0) ^ (y[i] ?? 0)
  return d === 0
}

interface Ligne {
  id: string
  modele: string
  categorie: string
  a: string
  donnees: Record<string, unknown>
  de: string
  de_nom: string
  repondre_a: string
  essentielle: boolean
  langue?: string
  droite_a_gauche?: boolean
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') return refus('methode', 405)
  const secret = Deno.env.get('COURRIELS_ENVOI_SECRET')
  if (!secret || !egal(req.headers.get('x-courriels-secret') ?? '', secret)) return refus('acces refuse', 401)

  const db = clientService()
  const urlDesinscription = `${Deno.env.get('SUPABASE_URL')}/functions/v1/courriel-desinscription`
  const debut = Date.now()
  let envoyes = 0
  let echecs = 0

  // Des lots de 20 tant qu'il en reste, sans depasser 40 s (la fonction en a 150).
  while (Date.now() - debut < 40_000) {
    const { data, error } = await db.rpc('courriels_reserver', { p_lot: 20 })
    if (error) return refus(`reserver : ${error.message}`, 500)
    const lot = (data ?? []) as Ligne[]
    if (lot.length === 0) break

    for (const l of lot) {
      let ok = false
      let id: string | undefined
      let erreur: string | undefined
      try {
        // COURRIELS-2 : dans la langue du destinataire ; traduit du francais (ou de
        // la langue d'ecriture de la direction) quand elle n'est pas ecrite.
        const langue = l.langue ?? 'fr'
        const r = rendre({ modele: l.modele, categorie: l.categorie, donnees: l.donnees, essentielle: l.essentielle }, langue)
        const c = r.traduireDepuis
          ? { ...(await traduireContenu(r.contenu, r.traduireDepuis, langue)), droiteAGauche: l.droite_a_gauche === true }
          : r.contenu
        const { html, texte } = composer(c)
        const jeton = typeof l.donnees.jeton_desinscription === 'string' ? l.donnees.jeton_desinscription : null
        const envoi = await envoyer({
          de: l.de, deNom: l.de_nom, repondreA: l.repondre_a, a: l.a,
          sujet: c.sujet, html, texte, idMessage: l.id,
          desinscriptionUnClic: lienUnClic({
            lettre: c.lettre, essentielle: l.essentielle, jeton, base: urlDesinscription,
          }),
        })
        ;({ ok, id, erreur } = envoi)
      } catch (e) {
        erreur = String((e as Error).message ?? e)
      }
      ok ? envoyes++ : echecs++
      const { error: e2 } = await db.rpc('courriel_consigner', {
        p_id: l.id, p_ok: ok, p_fournisseur_id: id ?? null, p_erreur: erreur ?? null,
      })
      if (e2) console.error(`consigner ${l.id} : ${e2.message}`)
    }
  }
  return json({ envoyes, echecs })
})
