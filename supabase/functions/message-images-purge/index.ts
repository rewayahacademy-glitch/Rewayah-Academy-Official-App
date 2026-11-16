// IMAGES-MESSAGERIE (16/11/2026) : l'expiration a 90 jours des images de la
// messagerie. Appelee UNE FOIS PAR JOUR, la nuit, par pg_cron (tache
// `message-images-purge`, migration 20261129100200), sans jeton Supabase : la porte
// est le secret partage COURRIELS_ENVOI_SECRET (le meme que push-envoi et
// courriels-envoi, aucun secret nouveau), en-tete `x-courriels-secret`, compare en
// temps constant. Sans ce secret cote fonction, tout est refuse.
//
// Par lots de 200 : lit les images dues (RPC `message_images_purge_lire`), retire
// leurs deux objets R2, puis marque les lignes « supprimee » (RPC
// `message_images_purge_marquer`). La ligne reste en base. Aucune ligne n'est
// effacee. Toute la logique est dans `_shared/r2/message_image.ts`, testee sans reseau.

import { clientService, json, refus } from '../_shared/clients.ts'
import { porteOuverte } from '../_shared/coupure_observation.ts'
import { stockageConfigure } from '../_shared/r2/domaines.ts'
import { journaliser, supprimerObjet } from '../_shared/r2/signature.ts'
import { purger } from '../_shared/r2/message_image.ts'

const DOMAINE = 'pieceJointeMessage' as const

Deno.serve(async (requete: Request) => {
  if (requete.method !== 'POST') return refus('methode', 405)
  if (!porteOuverte(requete.headers.get('x-courriels-secret'), Deno.env.get('COURRIELS_ENVOI_SECRET'))) {
    return refus('acces refuse', 401)
  }
  if (!stockageConfigure(DOMAINE)) return refus('stockage indisponible', 503)

  const base = clientService()
  try {
    const bilan = await purger({
      lire: async (lot) => {
        const { data, error } = await base.rpc('message_images_purge_lire', { p_lot: lot })
        if (error) throw new Error('lecture du lot impossible')
        return data
      },
      supprimer: (cle) => supprimerObjet(DOMAINE, cle),
      marquer: async (ids) => {
        const { error } = await base.rpc('message_images_purge_marquer', { p_ids: ids })
        if (error) throw new Error('marquage impossible')
      },
    })
    journaliser({ domaine: DOMAINE, operation: 'suppression', statut: 'accorde', ressource: `${bilan.retirees}` })
    return json(bilan)
  } catch (erreur) {
    journaliser({
      domaine: DOMAINE,
      operation: 'suppression',
      statut: 'echec',
      ressource: 'lot',
      classeErreur: (erreur as Error)?.name ?? 'inconnue',
    })
    return refus('purge impossible', 500)
  }
})
