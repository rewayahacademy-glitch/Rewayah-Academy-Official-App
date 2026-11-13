import { enTetesCors, json, refus } from "../_shared/clients.ts";
import { appelantR2 } from "../_shared/r2/client_appelant.ts";
import { cleDe, verifierCle } from "../_shared/r2/cles.ts";
import {
  detecterMimeReel,
  mimeAnnonceAutorise,
  mimeConnu,
  mimeVignetteAutorise,
  motifRefus,
  nomNeutre,
  reponseRefus,
  sha256Hex,
  TAILLE_VIGNETTE_MAX_OCTETS,
  TAILLES_UPLOAD_BIBLIOTHEQUE,
} from "../_shared/r2/bibliotheque_upload.ts";
import { stockageConfigure } from "../_shared/r2/domaines.ts";
import {
  NOM_SECRET_CONFIRMATION,
  reglageManquant,
  reglagesDepot,
} from "../_shared/r2/reglages_depot.ts";
import {
  journaliser,
  signerDepot,
  signerLecture,
} from "../_shared/r2/signature.ts";
import {
  DOMAINE_VIGNETTE,
  signatureConfirmationUpload,
} from "../_shared/r2/confirmation_hmac.ts";

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const SHA256 = /^[0-9a-f]{64}$/;

interface IntentionUpload {
  id: string;
  expire_le: string;
  resource_version_id: string;
  finalite: "support" | "preuve";
  mime: string;
  taille: number;
  sha256: string;
  cle_temporaire: string;
  cle_finale: string;
}

Deno.serve(async (requete: Request) => {
  if (requete.method === "OPTIONS") {
    return new Response("ok", { headers: enTetesCors });
  }
  if (requete.method !== "POST") return refus("methode non autorisee", 405);

  let compte: Awaited<ReturnType<typeof appelantR2>>;
  try {
    compte = await appelantR2(requete);
  } catch {
    // Une configuration absente n'est pas une session expiree : la personne
    // n'a pas a se reconnecter (DEPOT-NOM-LIBRE, I3).
    return refus("service mal regle", 503);
  }
  if (!compte) return refus("authentification requise", 401);

  let corps: Record<string, unknown>;
  try {
    const donnees: unknown = await requete.json();
    if (!donnees || typeof donnees !== "object" || Array.isArray(donnees)) {
      return refus("corps invalide");
    }
    corps = donnees as Record<string, unknown>;
  } catch {
    return refus("corps illisible");
  }
  if ("object_key" in corps || "cle_stockage" in corps || "bucket" in corps) {
    return refus("cle et seau resolus par le serveur");
  }

  const action = corps.action;
  if (action === "reglages") {
    // Les reglages de production du depot : LEQUEL manque, par son nom, jamais
    // sa valeur. Direction seulement : la base refuse tout autre compte.
    const { data, error } = await compte.sql.rpc("bibliotheque_depot_actif");
    if (error) return refus("reglages refuses", 403);
    return json(
      await reglagesDepot(requete.headers.get("Origin"), data === true),
    );
  }
  if (action === "demander") {
    return await demanderDepot(compte, corps);
  }
  if (action === "confirmer") {
    return await confirmerDepot(compte, corps);
  }
  if (action === "demander_vignette") {
    return await demanderVignette(compte, corps);
  }
  if (action === "confirmer_vignette") {
    return await confirmerVignette(compte, corps);
  }
  if (action === "annuler_vignette") {
    const id = typeof corps.upload_id === "string"
      ? corps.upload_id.trim()
      : "";
    if (!UUID.test(id)) return refus("intention invalide");
    const { data, error } = await compte.sql.rpc(
      "annuler_vignette_bibliotheque",
      { p_intention_id: id },
    );
    if (error) return refusBase(error);
    return json({ annule: data === true });
  }
  if (action === "annuler") {
    const id = typeof corps.upload_id === "string"
      ? corps.upload_id.trim()
      : "";
    if (!UUID.test(id)) return refus("intention invalide");
    const { data, error } = await compte.sql.rpc(
      "annuler_upload_bibliotheque",
      { p_intention_id: id },
    );
    if (error) return refusBase(error);
    return json({ annule: data === true });
  }
  return refus("action inconnue");
});

async function demanderDepot(
  compte: NonNullable<Awaited<ReturnType<typeof appelantR2>>>,
  corps: Record<string, unknown>,
): Promise<Response> {
  if (!stockageConfigure("priveApplicatif")) {
    return refusReglage("stockage indisponible", reglageManquant(["priveApplicatif"]));
  }
  const supportId = typeof corps.support_id === "string"
    ? corps.support_id.trim()
    : "";
  const finalite = corps.finalite === "preuve"
    ? "preuve"
    : corps.finalite === "support"
    ? "support"
    : "";
  const fichier = corps.fichier && typeof corps.fichier === "object" &&
      !Array.isArray(corps.fichier)
    ? corps.fichier as Record<string, unknown>
    : {};
  const mime = typeof fichier.mime === "string"
    ? fichier.mime.trim().toLowerCase()
    : "";
  // Le nom du fichier du client est ignore : il n'entre ni dans la cle ni en
  // base. Un nom arabe ou accentue faisait refuser le depot (13/11/2026).
  const nom = nomNeutre(mime);
  const taille = Number(fichier.octets);
  const empreinte = typeof fichier.sha256 === "string"
    ? fichier.sha256.trim().toLowerCase()
    : "";
  if (!UUID.test(supportId) || !finalite || !SHA256.test(empreinte)) {
    return refus("demande invalide");
  }
  if (!Number.isSafeInteger(taille) || taille <= 0) {
    return refus("fichier vide");
  }
  if (nom === null || !mimeConnu(mime, finalite)) {
    return refus("fichier invalide ou format non autorise");
  }
  // Un type accepte mais trop lourd : « trop lourd », pas « type refuse ».
  if (!mimeAnnonceAutorise(mime, taille, finalite)) {
    return refus("fichier trop lourd", 413);
  }
  const { data, error } = await compte.sql.rpc("demander_upload_bibliotheque", {
    p_resource_id: supportId,
    p_finalite: finalite,
    p_nom_fichier: nom,
    p_mime: mime,
    p_taille: taille,
    p_sha256: empreinte,
  });
  if (error) return refusBase(error);
  if (!data || typeof data !== "object") return refus("depot impossible", 500);
  const intention = data as Record<string, unknown>;
  const id = String(intention.id ?? "");
  if (!UUID.test(id)) return refus("intention invalide", 503);
  const cle = cleDe("priveApplicatif", "libraryupload", id);
  if (intention.cle_temporaire !== cle) return refus("intention invalide", 503);
  try {
    const signee = await signerDepot(
      "priveApplicatif",
      verifierCle("priveApplicatif", cle),
      {
        typeMime: mime,
        tailleOctets: taille,
        typesAutorises: typesPour(finalite),
        tailleMaximaleOctets: limitePour(mime),
      },
    );
    journaliser({
      domaine: "priveApplicatif",
      operation: "depot",
      statut: "accorde",
      ressource: id,
    });
    return json({
      upload_id: id,
      expire_le_utc: intention.expire_le,
      url: signee.url,
      methode: "PUT",
      en_tetes_exiges: signee.enTetesExiges,
      expire_dans_secondes: signee.expireDansSecondes,
    });
  } catch (erreur) {
    journaliser({
      domaine: "priveApplicatif",
      operation: "depot",
      statut: "echec",
      ressource: id,
      classeErreur: (erreur as Error)?.name ?? "inconnue",
    });
    return refus("stockage indisponible", 503);
  }
}

async function confirmerDepot(
  compte: NonNullable<Awaited<ReturnType<typeof appelantR2>>>,
  corps: Record<string, unknown>,
): Promise<Response> {
  const id = typeof corps.upload_id === "string" ? corps.upload_id.trim() : "";
  if (!UUID.test(id)) return refus("intention invalide");
  let secretConfirmation: string;
  try {
    secretConfirmation = Deno.env.get("LIBRARY_UPLOAD_CONFIRMATION_HMAC_KEY") ?? "";
  } catch {
    return refus("confirmation indisponible", 503);
  }
  if (
    new TextEncoder().encode(secretConfirmation).byteLength < 32 ||
    secretConfirmation.trim() !== secretConfirmation
  ) {
    return refusReglage("confirmation indisponible", NOM_SECRET_CONFIRMATION);
  }
  const debut = Date.now();
  const { data, error } = await compte.sql.rpc("lire_upload_bibliotheque", {
    p_intention_id: id,
  });
  if (error) return refusBase(error);
  if (!data || typeof data !== "object") return refus("depot impossible", 500);
  const intention = data as IntentionUpload;
  const domaineTemp = "priveApplicatif" as const;
  const domaineFinal = intention.finalite === "support"
    ? "supports" as const
    : "priveApplicatif" as const;
  if (!stockageConfigure(domaineTemp) || !stockageConfigure(domaineFinal)) {
    return refusReglage(
      "stockage indisponible",
      reglageManquant([domaineTemp, domaineFinal]),
    );
  }
  try {
    const cleTemp = verifierCle(domaineTemp, intention.cle_temporaire);
    const lecture = await signerLecture(domaineTemp, cleTemp, {
      dureeSecondes: 60,
    });
    const objet = await fetch(lecture.url);
    if (!objet.ok) return refus("objet depose introuvable", 422);
    const octets = new Uint8Array(await objet.arrayBuffer());
    const mimeReel = detecterMimeReel(octets);
    const empreinte = await sha256Hex(octets);
    // Le contenu reel n'est pas du type annonce (un .pdf qui n'en est pas
    // un) : la phrase le dit, ce n'est pas un envoi abime.
    if (!mimeReel || mimeReel !== intention.mime) {
      journaliser({
        domaine: domaineTemp,
        operation: "depot",
        statut: "refuse",
        ressource: id,
        dureeMs: Date.now() - debut,
      });
      return refus("contenu different du type annonce", 422);
    }
    if (
      octets.byteLength !== intention.taille ||
      empreinte !== intention.sha256 ||
      !mimeAnnonceAutorise(mimeReel, octets.byteLength, intention.finalite)
    ) {
      journaliser({
        domaine: domaineTemp,
        operation: "depot",
        statut: "refuse",
        ressource: id,
        dureeMs: Date.now() - debut,
      });
      return refus("contenu depose invalide", 422);
    }
    const cleFinale = verifierCle(domaineFinal, intention.cle_finale);
    const types = typesPour(intention.finalite);
    const signee = await signerDepot(domaineFinal, cleFinale, {
      typeMime: mimeReel,
      tailleOctets: octets.byteLength,
      typesAutorises: types,
      tailleMaximaleOctets: limitePour(mimeReel),
    });
    const depose = await fetch(signee.url, {
      method: "PUT",
      headers: signee.enTetesExiges,
      body: octets,
    });
    if (!depose.ok) throw new Error("ecriture R2 refusee");
    const confirmationSignature = await signatureConfirmationUpload(
      secretConfirmation,
      id,
      empreinte,
      octets.byteLength,
    );
    const confirme = await compte.sql.rpc("confirmer_upload_bibliotheque", {
      p_intention_id: id,
      p_mime_reel: mimeReel,
      p_taille_reelle: octets.byteLength,
      p_sha256_reel: empreinte,
      p_confirmation_signature: confirmationSignature,
    });
    if (confirme.error) return refusConfirmation(confirme.error);
    journaliser({
      domaine: domaineFinal,
      operation: "depot",
      statut: "accorde",
      ressource: id,
      dureeMs: Date.now() - debut,
    });
    return json({
      phase: "pret",
      resource_version_id: intention.resource_version_id,
    });
  } catch (erreur) {
    journaliser({
      domaine: domaineTemp,
      operation: "depot",
      statut: "echec",
      ressource: id,
      classeErreur: (erreur as Error)?.name ?? "inconnue",
      dureeMs: Date.now() - debut,
    });
    return refus("stockage indisponible", 503);
  }
}

/** Le refus d'une confirmation par la base. Une signature que la base ne
 * reconnait pas n'est pas la faute de la personne : le secret de confirmation
 * n'est pas le meme des deux cotes. C'est un reglage du serveur, et la reponse
 * le dit (503 « confirmation mal reglee ») au lieu d'un refus (DEPOT-SIMPLE). */
function refusConfirmation(erreur: { message?: string }): Response {
  if ((erreur.message ?? "").includes("ConfirmationNonAutorisee")) {
    return refusReglage("confirmation mal reglee", NOM_SECRET_CONFIRMATION);
  }
  return refusBase(erreur);
}

/** Le refus d'un appel a la base : son motif vrai, pas un « 403 » pour tout
 * (compte sans droit, document plus modifiable, panne). Un compte sans droit
 * lit toujours un refus, jamais un reglage. */
function refusBase(erreur: { message?: string; code?: string }): Response {
  const [message, statut] = reponseRefus(motifRefus(erreur));
  return refus(message, statut);
}

/** Un 503 qui nomme le reglage en cause (son NOM, jamais sa valeur), pour que
 * la direction sache lequel poser sans le decouvrir par des echecs. */
function refusReglage(message: string, reglage: string | null): Response {
  return json(
    reglage === null ? { error: message } : { error: message, reglage },
    503,
  );
}

function typesPour(finalite: string): string[] {
  return finalite === "preuve"
    ? ["image/png", "image/jpeg", "image/webp", "application/pdf"]
    : [
      "image/png",
      "image/jpeg",
      "image/webp",
      "application/pdf",
      "audio/mpeg",
      "audio/mp4",
      "audio/ogg",
    ];
}

function limitePour(mime: string): number {
  if (mime.startsWith("image/")) return TAILLES_UPLOAD_BIBLIOTHEQUE.image;
  if (mime === "application/pdf") return TAILLES_UPLOAD_BIBLIOTHEQUE.pdf;
  return TAILLES_UPLOAD_BIBLIOTHEQUE.audio;
}

// ---------------------------------------------------------------------------
// BIBLIOTHEQUE-UNE : la vignette d'un document, deposee en deux temps comme son
// fichier. Meme chemin (intention en base, depot signe, confirmation par
// l'Edge avec une signature que la base reverifie), borne a une image de 2 Mio.
// Le nom de fichier du client n'entre jamais dans la cle : la base la fabrique.
// ---------------------------------------------------------------------------
async function demanderVignette(
  compte: NonNullable<Awaited<ReturnType<typeof appelantR2>>>,
  corps: Record<string, unknown>,
): Promise<Response> {
  if (!stockageConfigure("priveApplicatif")) {
    return refusReglage("stockage indisponible", reglageManquant(["priveApplicatif"]));
  }
  const documentId = typeof corps.support_id === "string"
    ? corps.support_id.trim()
    : "";
  const fichier = corps.fichier && typeof corps.fichier === "object" &&
      !Array.isArray(corps.fichier)
    ? corps.fichier as Record<string, unknown>
    : {};
  const mime = typeof fichier.mime === "string"
    ? fichier.mime.trim().toLowerCase()
    : "";
  const taille = Number(fichier.octets);
  const empreinte = typeof fichier.sha256 === "string"
    ? fichier.sha256.trim().toLowerCase()
    : "";
  if (!UUID.test(documentId) || !SHA256.test(empreinte)) {
    return refus("demande invalide");
  }
  if (!Number.isSafeInteger(taille) || taille <= 0) {
    return refus("fichier vide");
  }
  if (!mimeConnu(mime, "preuve") || mime === "application/pdf") {
    return refus("fichier invalide ou format non autorise");
  }
  if (!mimeVignetteAutorise(mime, taille)) {
    return refus("fichier trop lourd", 413);
  }
  const { data, error } = await compte.sql.rpc(
    "demander_vignette_bibliotheque",
    {
      p_resource_id: documentId,
      p_mime: mime,
      p_taille: taille,
      p_sha256: empreinte,
    },
  );
  if (error) return refusBase(error);
  if (!data || typeof data !== "object") return refus("depot impossible", 500);
  const intention = data as Record<string, unknown>;
  const id = String(intention.id ?? "");
  if (!UUID.test(id)) return refus("intention invalide", 503);
  const cle = cleDe("priveApplicatif", "libraryupload", id);
  if (intention.cle_temporaire !== cle) return refus("intention invalide", 503);
  try {
    const signee = await signerDepot(
      "priveApplicatif",
      verifierCle("priveApplicatif", cle),
      {
        typeMime: mime,
        tailleOctets: taille,
        typesAutorises: typesVignette(),
        tailleMaximaleOctets: TAILLE_VIGNETTE_MAX_OCTETS,
      },
    );
    journaliser({
      domaine: "priveApplicatif",
      operation: "depot",
      statut: "accorde",
      ressource: id,
    });
    return json({
      upload_id: id,
      expire_le_utc: intention.expire_le,
      url: signee.url,
      methode: "PUT",
      en_tetes_exiges: signee.enTetesExiges,
      expire_dans_secondes: signee.expireDansSecondes,
    });
  } catch (erreur) {
    journaliser({
      domaine: "priveApplicatif",
      operation: "depot",
      statut: "echec",
      ressource: id,
      classeErreur: (erreur as Error)?.name ?? "inconnue",
    });
    return refus("stockage indisponible", 503);
  }
}

async function confirmerVignette(
  compte: NonNullable<Awaited<ReturnType<typeof appelantR2>>>,
  corps: Record<string, unknown>,
): Promise<Response> {
  const id = typeof corps.upload_id === "string" ? corps.upload_id.trim() : "";
  if (!UUID.test(id)) return refus("intention invalide");
  let secretConfirmation: string;
  try {
    secretConfirmation = Deno.env.get("LIBRARY_UPLOAD_CONFIRMATION_HMAC_KEY") ?? "";
  } catch {
    return refus("confirmation indisponible", 503);
  }
  if (
    new TextEncoder().encode(secretConfirmation).byteLength < 32 ||
    secretConfirmation.trim() !== secretConfirmation
  ) {
    return refusReglage("confirmation indisponible", NOM_SECRET_CONFIRMATION);
  }
  const debut = Date.now();
  const { data, error } = await compte.sql.rpc("lire_vignette_bibliotheque", {
    p_intention_id: id,
  });
  if (error) return refusBase(error);
  if (!data || typeof data !== "object") return refus("depot impossible", 500);
  const intention = data as Record<string, unknown>;
  if (
    !stockageConfigure("priveApplicatif") || !stockageConfigure("supports")
  ) {
    return refusReglage(
      "stockage indisponible",
      reglageManquant(["priveApplicatif", "supports"]),
    );
  }
  try {
    const cleTemp = verifierCle(
      "priveApplicatif",
      String(intention.cle_temporaire ?? ""),
    );
    const lecture = await signerLecture("priveApplicatif", cleTemp, {
      dureeSecondes: 60,
    });
    const objet = await fetch(lecture.url);
    if (!objet.ok) return refus("objet depose introuvable", 422);
    const octets = new Uint8Array(await objet.arrayBuffer());
    const mimeReel = detecterMimeReel(octets);
    const empreinte = await sha256Hex(octets);
    if (!mimeReel || mimeReel !== intention.mime) {
      journaliser({
        domaine: "priveApplicatif",
        operation: "depot",
        statut: "refuse",
        ressource: id,
        dureeMs: Date.now() - debut,
      });
      return refus("contenu different du type annonce", 422);
    }
    if (
      octets.byteLength !== Number(intention.taille) ||
      empreinte !== intention.sha256 ||
      !mimeVignetteAutorise(mimeReel, octets.byteLength)
    ) {
      journaliser({
        domaine: "priveApplicatif",
        operation: "depot",
        statut: "refuse",
        ressource: id,
        dureeMs: Date.now() - debut,
      });
      return refus("contenu depose invalide", 422);
    }
    const cleFinale = verifierCle("supports", String(intention.cle_finale ?? ""));
    const signee = await signerDepot("supports", cleFinale, {
      typeMime: mimeReel,
      tailleOctets: octets.byteLength,
      typesAutorises: typesVignette(),
      tailleMaximaleOctets: TAILLE_VIGNETTE_MAX_OCTETS,
    });
    const depose = await fetch(signee.url, {
      method: "PUT",
      headers: signee.enTetesExiges,
      body: octets,
    });
    if (!depose.ok) throw new Error("ecriture R2 refusee");
    const confirmationSignature = await signatureConfirmationUpload(
      secretConfirmation,
      id,
      empreinte,
      octets.byteLength,
      DOMAINE_VIGNETTE,
    );
    const confirme = await compte.sql.rpc("confirmer_vignette_bibliotheque", {
      p_intention_id: id,
      p_mime_reel: mimeReel,
      p_taille_reelle: octets.byteLength,
      p_sha256_reel: empreinte,
      p_confirmation_signature: confirmationSignature,
    });
    if (confirme.error) return refusConfirmation(confirme.error);
    journaliser({
      domaine: "supports",
      operation: "depot",
      statut: "accorde",
      ressource: id,
      dureeMs: Date.now() - debut,
    });
    return json({ phase: "pret", resource_id: intention.resource_id });
  } catch (erreur) {
    journaliser({
      domaine: "priveApplicatif",
      operation: "depot",
      statut: "echec",
      ressource: id,
      classeErreur: (erreur as Error)?.name ?? "inconnue",
      dureeMs: Date.now() - debut,
    });
    return refus("stockage indisponible", 503);
  }
}

function typesVignette(): string[] {
  return ["image/png", "image/jpeg", "image/webp"];
}
