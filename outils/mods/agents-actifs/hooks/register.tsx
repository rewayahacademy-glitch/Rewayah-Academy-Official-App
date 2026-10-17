import { atom, read, update } from 'claude-code'
import type { Register } from 'claude-code'

import type { SuiviAgent } from '../types'

const PANNEAU = 'agents-actifs'
const LARGEUR_BARRE = 20
const ROUE = ['|', '/', '-', '\\']

const vide = (id: string, titre: string, type: string, debut: number): SuiviAgent => ({
  id,
  titre,
  type,
  debut,
  etat: 'en cours',
  etapes: 0,
  outils: 0,
  derniereAction: 'démarrage',
  tokensEntree: 0,
  tokensSortie: 0,
})

const agents = atom({ plugin: 'agents-actifs', key: 'agents' } as const, [] as SuiviAgent[])
const principal = atom(
  { plugin: 'agents-actifs', key: 'principal' } as const,
  vide('principal', 'Session principale', 'principal', 0),
)
const battement = atom({ plugin: 'agents-actifs', key: 'battement' } as const, 0)

const milliers = (n: number) => (n >= 1_000_000 ? `${(n / 1_000_000).toFixed(1)} M` : n >= 1000 ? `${Math.round(n / 1000)} k` : `${n}`)

const duree = (ms: number) => {
  const s = Math.max(0, Math.round(ms / 1000))
  const m = Math.floor(s / 60)
  return m >= 60 ? `${Math.floor(m / 60)} h ${m % 60} min` : m > 0 ? `${m} min ${s % 60} s` : `${s} s`
}

// L'avancement réel d'une tâche n'est pas connu du moteur : la barre montre
// l'activité (étapes du modèle) rapportée à l'agent le plus actif, et une
// tête qui avance tant que l'agent tourne.
const barre = (agent: SuiviAgent, max: number, tic: number) => {
  const plein = agent.etat === 'en cours'
    ? Math.max(1, Math.round((agent.etapes / Math.max(1, max)) * (LARGEUR_BARRE - 1)))
    : LARGEUR_BARRE
  const corps = '='.repeat(Math.min(plein, LARGEUR_BARRE))
  const tete = agent.etat === 'en cours' ? ROUE[tic % ROUE.length] : ''
  return `[${(corps + tete).padEnd(LARGEUR_BARRE + 1, ' ').slice(0, LARGEUR_BARRE + 1)}]`
}

const majAgent = (liste: SuiviAgent[], id: string, fn: (a: SuiviAgent) => SuiviAgent) =>
  liste.map(a => (a.id === id ? fn(a) : a))

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({ name: 'agents', description: 'Ouvrir le panneau des agents actifs' })
    const maintenant = await $.clock.now()
    await update($, principal, p => (p.debut ? p : { ...p, debut: maintenant }))
    $.clock.every(1000, () => {
      void update($, battement, n => n + 1)
    })
    void $.ui.open({ id: PANNEAU, title: 'Agents actifs' })
    return next(e)
  })

  on('command.run', { command: 'agents' }, async $ => {
    await $.ui.open({ id: PANNEAU, title: 'Agents actifs' })
    return { text: 'Panneau des agents ouvert.' }
  })

  on('agent.spawn', async ($, e, next) => {
    const r = await next(e)
    if (r && 'agentId' in r && r.agentId) {
      const debut = await $.clock.now()
      const nouveau = vide(r.agentId, e.description || 'Agent', e.subagentType, debut)
      await update($, agents, liste => [...liste.filter(a => a.id !== nouveau.id), nouveau].slice(-50))
    }
    return r
  })

  on('turn.step', async function* ($, e, next) {
    const r = yield* next(e)
    const u = r?.usage
    const entree = u ? u.input_tokens + (u.cache_read_input_tokens ?? 0) + (u.cache_creation_input_tokens ?? 0) : 0
    const sortie = u ? u.output_tokens : 0
    const outils = r?.toolUses?.length ?? 0
    const action = outils > 0 ? r.toolUses.map(t => t.name).join(', ') : 'réflexion'
    const maj = (a: SuiviAgent): SuiviAgent => ({
      ...a,
      etat: 'en cours',
      etapes: a.etapes + 1,
      outils: a.outils + outils,
      derniereAction: action,
      tokensEntree: a.tokensEntree + entree,
      tokensSortie: a.tokensSortie + sortie,
    })
    if (e.agentId) await update($, agents, liste => majAgent(liste, e.agentId as string, maj))
    else await update($, principal, maj)
    return r
  })

  on('turn.complete', async ($, e, next) => {
    const r = await next(e)
    if (e.agentId) {
      const fin = await $.clock.now()
      await update($, agents, liste =>
        majAgent(liste, e.agentId as string, a => ({ ...a, etat: 'terminé', fin, derniereAction: 'terminé' })),
      )
    }
    return r
  })

  on('ui.render', { component: 'Pane', requestId: PANNEAU }, async ($, e) => {
    const { Box, Text } = $.ui.resolve(e)
    const tic = await read($, battement)
    const liste = await read($, agents)
    const p = await read($, principal)
    const maintenant = await $.clock.now()

    // Le moteur sait seul si un agent a échoué ou été arrêté.
    let etats: Record<string, string> = {}
    try {
      for (const info of await $.agent.list()) etats[info.id] = info.status
    } catch {
      etats = {}
    }
    const vus = liste.map(a => {
      const s = etats[a.id]
      if (s === 'failed') return { ...a, etat: 'échec' as const }
      if (s === 'killed') return { ...a, etat: 'arrêté' as const }
      if (s === 'completed' && a.etat === 'en cours') return { ...a, etat: 'terminé' as const }
      return a
    })
    const actifs = vus.filter(a => a.etat === 'en cours')
    const finis = vus.filter(a => a.etat !== 'en cours').slice(-8)
    const max = Math.max(1, ...vus.map(a => a.etapes))
    const totalEntree = p.tokensEntree + vus.reduce((s, a) => s + a.tokensEntree, 0)
    const totalSortie = p.tokensSortie + vus.reduce((s, a) => s + a.tokensSortie, 0)

    const ligne = (a: SuiviAgent) => (
      <Box flexDirection="column" marginBottom={1}>
        <Text bold={a.etat === 'en cours'} dimColor={a.etat !== 'en cours'}>
          {a.titre} <Text dimColor>({a.type})</Text>
        </Text>
        <Text color={a.etat === 'échec' ? 'red' : a.etat === 'en cours' ? 'cyan' : 'green'}>
          {barre(a, max, tic)} {a.etat} · {duree((a.fin ?? maintenant) - a.debut)}
        </Text>
        <Text dimColor>
          {a.etapes} étapes · {a.outils} outils · {milliers(a.tokensEntree)} lus · {milliers(a.tokensSortie)} écrits · {a.derniereAction}
        </Text>
      </Box>
    )

    return (
      <Box flexDirection="column">
        <Text bold>
          {actifs.length} agent{actifs.length > 1 ? 's' : ''} actif{actifs.length > 1 ? 's' : ''} · {milliers(totalEntree)} tokens lus · {milliers(totalSortie)} écrits
        </Text>
        <Text dimColor>
          Session principale : {p.etapes} étapes · {milliers(p.tokensEntree)} lus · {milliers(p.tokensSortie)} écrits
        </Text>
        <Text> </Text>
        {actifs.length === 0 && <Text dimColor>Aucun agent ne tourne en ce moment.</Text>}
        {actifs.map(ligne)}
        {finis.length > 0 && <Text dimColor>Terminés récemment</Text>}
        {finis.map(ligne)}
      </Box>
    )
  })
}
