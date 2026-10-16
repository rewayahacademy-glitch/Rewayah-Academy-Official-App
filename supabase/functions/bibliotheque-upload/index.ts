import { enTetesCors, json, refus } from "../_shared/clients.ts";
import { appelantR2 } from "../_shared/r2/client_appelant.ts";
import { cleDe, verifierCle } from "../_shared/r2/cles.ts";
import {
  detecterMimeReel,
  mimeAnnonceAutorise,
  sha256Hex,
  TAILLES_UPLOAD_BIBLIOTHEQUE,
} from "../_shared/r2/bibliotheque_upload.ts";
import { stockageConfigure } from "../_shared/r2/domaines.ts";
import {
  journaliser,
  signerDepot,
  signerLecture,
} from "../_shared/r2/signature.ts";
import { signatureConfirmationUpload } from "../_shared/r2/confirmation_hmac.ts";

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

  const compte = await appelantR2(requete).catch(() => null);
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
  if (action === "demander") {
    return await demanderDepot(compte, corps);
  }
  if (action === "confirmer") {
    return await confirmerDepot(compte, corps);
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
    if (error) return refus("annulation refusee", 403);
    return json({ annule: data === true });
  }
  return refus("action inconnue");
});

async function demanderDepot(
  compte: NonNullable<Awaited<ReturnType<typeof appelantR2>>>,
  corps: Record<string, unknown>,
): Promise<Response> {
  if (!stockageConfigure("priveApplicatif")) {
    return refus("stockage indisponible", 503);
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
  const nom = typeof fichier.nom === "string" ? fichier.nom.trim() : "";
  const mime = typeof fichier.mime === "string"
    ? fichier.mime.trim().toLowerCase()
    : "";
  const taille = Number(fichier.octets);
  const empreinte = typeof fichier.sha256 === "string"
    ? fichier.sha256.trim().toLowerCase()
    : "";
  if (
    !UUID.test(supportId) || !finalite ||
    !/^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$/.test(nom) ||
    !SHA256.test(empreinte) ||
    !mimeAnnonceAutorise(mime, taille, finalite)
  ) {
    return refus("fichier invalide ou format non autorise");
  }
  const { data, error } = await compte.sql.rpc("demander_upload_bibliotheque", {
    p_resource_id: supportId,
    p_finalite: finalite,
    p_nom_fichier: nom,
    p_mime: mime,
    p_taille: taille,
    p_sha256: empreinte,
  });
  if (error || !data || typeof data !== "object") {
    return refus("depot refuse", 403);
  }
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
    return refus("confirmation indisponible", 503);
  }
  const debut = Date.now();
  const { data, error } = await compte.sql.rpc("lire_upload_bibliotheque", {
    p_intention_id: id,
  });
  if (error || !data || typeof data !== "object") {
    return refus("intention refusee", 403);
  }
  const intention = data as IntentionUpload;
  const domaineTemp = "priveApplicatif" as const;
  const domaineFinal = intention.finalite === "support"
    ? "supports" as const
    : "priveApplicatif" as const;
  if (!stockageConfigure(domaineTemp) || !stockageConfigure(domaineFinal)) {
    return refus("stockage indisponible", 503);
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
    if (
      octets.byteLength !== intention.taille ||
      empreinte !== intention.sha256 ||
      mimeReel !== intention.mime || !mimeReel ||
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
    if (confirme.error) return refus("confirmation refusee", 403);
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
