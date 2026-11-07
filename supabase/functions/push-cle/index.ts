// PUSH-1 : rend { cle: VAPID_PUBLIC_KEY } a l'application connectee, pour
// l'abonnement Web Push. JWT verifie par la plateforme. Sans cle : 503.

import { repondreCle } from '../_shared/push/cle.ts'

Deno.serve((req) => repondreCle(req, (nom) => Deno.env.get(nom)))
