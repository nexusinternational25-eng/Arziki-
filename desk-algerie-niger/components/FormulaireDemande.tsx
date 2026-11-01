"use client";

// Formulaire de demande : validation dans le navigateur (Zod), puis envoi à /api/demande
// qui revalide tout côté serveur. Le message « reçue » ne s'affiche que si le serveur
// confirme ; sinon, le visiteur voit l'e-mail et le WhatsApp à contacter directement.

import { useEffect, useId, useState } from "react";
import { useForm, useWatch } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { useLocale, useTranslations } from "next-intl";
import { Link } from "@/i18n/navigation";
import type { Langue } from "@/i18n/routing";
import { BUDGETS, schemaDemande, type Demande } from "@/lib/formulaire";
import { CONTACT, SECTEURS, SERVICES } from "@/lib/contenu";
import { IconeWhatsApp } from "./IconeWhatsApp";

type Props = {
  profil?: "algerie" | "niger" | "autre";
  service?: string;
  secteur?: string;
  source: string;
};

const CLE_TURNSTILE = process.env.NEXT_PUBLIC_TURNSTILE_SITE_KEY;

export function FormulaireDemande({ profil, service, secteur, source }: Props) {
  const t = useTranslations("formulaire");
  const tw = useTranslations("whatsapp");
  const langue = useLocale() as Langue;
  const id = useId();
  const [etat, setEtat] = useState<"saisie" | "envoi" | "succes" | "echec" | "trop">("saisie");

  const paysParDefaut = profil === "algerie" ? "DZ" : profil === "niger" ? "NE" : "DZ";

  const {
    register,
    handleSubmit,
    control,
    setValue,
    reset,
    formState: { errors },
  } = useForm<Demande>({
    resolver: zodResolver(schemaDemande),
    mode: "onTouched",
    defaultValues: {
      nom: "",
      entreprise: "",
      fonction: "",
      pays: paysParDefaut,
      profil: profil ?? "algerie",
      service: service ?? "",
      secteur: secteur ?? "",
      budget: "",
      email: "",
      telephone: "",
      message: "",
      languePreferee: langue,
      consentement: false,
      siteWeb: "",
      source,
    },
  });

  const pays = useWatch({ control, name: "pays" });
  const budget = useWatch({ control, name: "budget" });

  // Si le pays change, la fourchette choisie peut ne plus correspondre à la devise.
  useEffect(() => {
    const valides = ["", "inconnu", ...BUDGETS[pays].map((b) => b.code)];
    if (budget && !valides.includes(budget)) setValue("budget", "");
  }, [pays, budget, setValue]);

  // Chargement de Cloudflare Turnstile seulement si la clé publique est fournie.
  useEffect(() => {
    if (!CLE_TURNSTILE || document.getElementById("turnstile-script")) return;
    const s = document.createElement("script");
    s.id = "turnstile-script";
    s.src = "https://challenges.cloudflare.com/turnstile/v0/api.js";
    s.async = true;
    document.head.appendChild(s);
  }, []);

  async function envoyer(d: Demande, evenement?: React.BaseSyntheticEvent) {
    setEtat("envoi");
    const formulaire = evenement?.target as HTMLFormElement | undefined;
    const jeton = formulaire ? new FormData(formulaire).get("cf-turnstile-response") : null;
    try {
      const rep = await fetch("/api/demande", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ ...d, langueSite: langue, turnstile: jeton }),
      });
      const json = (await rep.json().catch(() => ({}))) as { ok?: boolean; raison?: string };
      if (rep.ok && json.ok === true) {
        setEtat("succes");
        reset();
        document.getElementById(`${id}-haut`)?.scrollIntoView({ block: "start" });
      } else {
        setEtat(json.raison === "trop" ? "trop" : "echec");
      }
    } catch {
      setEtat("echec");
    }
  }

  const erreur = (champ: keyof Demande) => {
    const code = errors[champ]?.message;
    return code ? t(`erreurs.${code}` as "erreurs.nom") : null;
  };

  if (etat === "succes") {
    return (
      <div id={`${id}-haut`} role="status" className="carte scroll-mt-24 border-vert/40 bg-vert-pale p-6 sm:p-8">
        <h2 className="text-xl text-vert">{t("succesTitre")}</h2>
        <p className="mt-2">{t("succesTexte")}</p>
        <button type="button" onClick={() => setEtat("saisie")} className="bouton bouton-secondaire mt-5">
          {t("succesAutre")}
        </button>
      </div>
    );
  }

  const aria = (champ: keyof Demande) => ({
    id: `${id}-${champ}`,
    "aria-invalid": errors[champ] ? true : undefined,
    "aria-describedby": errors[champ] ? `${id}-${champ}-erreur` : undefined,
  });

  return (
    <form id={`${id}-haut`} onSubmit={handleSubmit(envoyer)} noValidate className="carte relative scroll-mt-24 p-5 sm:p-8">
      {(etat === "echec" || etat === "trop") && (
        <div role="alert" className="mb-6 rounded-lg border border-erreur/40 bg-erreur-pale p-4">
          <p className="font-semibold text-erreur">{t("echecTitre")}</p>
          <p className="mt-1">{etat === "trop" ? t("erreurs.trop") : t("echecTexte")}</p>
          <ul className="mt-2 space-y-1">
            <li>
              <a className="lien" href={`mailto:${CONTACT.email}`} dir="ltr">
                {CONTACT.email}
              </a>
            </li>
            <li>
              <a
                className="lien"
                href={`https://wa.me/${CONTACT.whatsappLien}?text=${encodeURIComponent(tw("message"))}`}
                target="_blank"
                rel="noopener"
                dir="ltr"
              >
                WhatsApp {CONTACT.whatsappAffiche}
              </a>
            </li>
          </ul>
        </div>
      )}

      <div className="grid gap-5 sm:grid-cols-2">
        <div className="sm:col-span-2">
          <Etiquette id={id} obligatoire={t("obligatoire")} pour="nom" requis>{t("nom")}</Etiquette>
          <input className="champ" autoComplete="name" {...aria("nom")} {...register("nom")} />
          <MessageErreur id={id} champ="nom" message={erreur("nom")} />
        </div>

        <div>
          <Etiquette id={id} obligatoire={t("obligatoire")} pour="entreprise">{t("entreprise")}</Etiquette>
          <input className="champ" autoComplete="organization" {...aria("entreprise")} {...register("entreprise")} />
        </div>
        <div>
          <Etiquette id={id} obligatoire={t("obligatoire")} pour="fonction">{t("fonction")}</Etiquette>
          <input className="champ" autoComplete="organization-title" {...aria("fonction")} {...register("fonction")} />
        </div>

        <div>
          <Etiquette id={id} obligatoire={t("obligatoire")} pour="pays" requis>{t("pays")}</Etiquette>
          <select className="champ" {...aria("pays")} {...register("pays")}>
            <option value="DZ">{t("paysDZ")}</option>
            <option value="NE">{t("paysNE")}</option>
            <option value="autre">{t("paysAutre")}</option>
          </select>
        </div>
        <div>
          <Etiquette id={id} obligatoire={t("obligatoire")} pour="profil" requis>{t("profil")}</Etiquette>
          <select className="champ" {...aria("profil")} {...register("profil")}>
            <option value="algerie">{t("profilAlgerie")}</option>
            <option value="niger">{t("profilNiger")}</option>
            <option value="autre">{t("profilAutre")}</option>
          </select>
        </div>

        <div>
          <Etiquette id={id} obligatoire={t("obligatoire")} pour="service">{t("service")}</Etiquette>
          <select className="champ" {...aria("service")} {...register("service")}>
            <option value="">{t("choisir")}</option>
            {SERVICES.map((s) => (
              <option key={s.slug} value={s.slug}>
                {s.titre[langue]}
              </option>
            ))}
          </select>
        </div>
        <div>
          <Etiquette id={id} obligatoire={t("obligatoire")} pour="secteur">{t("secteur")}</Etiquette>
          <select className="champ" {...aria("secteur")} {...register("secteur")}>
            <option value="">{t("choisir")}</option>
            {SECTEURS.map((s) => (
              <option key={s.code} value={s.code}>
                {s.titre[langue]}
              </option>
            ))}
            <option value="autre">{t("secteurAutre")}</option>
          </select>
        </div>

        <div className="sm:col-span-2">
          <Etiquette id={id} obligatoire={t("obligatoire")} pour="budget">{t("budget")}</Etiquette>
          <select className="champ" {...aria("budget")} {...register("budget")}>
            <option value="">{t("choisir")}</option>
            {BUDGETS[pays].map((b) => (
              <option key={b.code} value={b.code}>
                {b[langue]}
              </option>
            ))}
            <option value="inconnu">{t("budgetInconnu")}</option>
          </select>
        </div>

        <p className="text-sm text-gris sm:col-span-2">{t("contactAide")}</p>
        <div>
          <Etiquette id={id} obligatoire={t("obligatoire")} pour="email">{t("email")}</Etiquette>
          <input className="champ" type="email" dir="ltr" autoComplete="email" inputMode="email" {...aria("email")} {...register("email")} />
          <MessageErreur id={id} champ="email" message={erreur("email")} />
        </div>
        <div>
          <Etiquette id={id} obligatoire={t("obligatoire")} pour="telephone">{t("telephone")}</Etiquette>
          <input className="champ" type="tel" dir="ltr" autoComplete="tel" inputMode="tel" {...aria("telephone")} {...register("telephone")} />
          {errors.telephone ? (
            <MessageErreur id={id} champ="telephone" message={erreur("telephone")} />
          ) : (
            <p className="mt-1.5 text-sm text-gris">{t("telephoneAide")}</p>
          )}
        </div>

        <div className="sm:col-span-2">
          <Etiquette id={id} obligatoire={t("obligatoire")} pour="message">{t("message")}</Etiquette>
          <textarea className="champ min-h-36" rows={5} {...aria("message")} {...register("message")} />
          {errors.message ? (
            <MessageErreur id={id} champ="message" message={erreur("message")} />
          ) : (
            <p className="mt-1.5 text-sm text-gris">{t("messageAide")}</p>
          )}
        </div>

        <fieldset className="sm:col-span-2">
          <legend className="mb-1.5 font-semibold">{t("langue")}</legend>
          <div className="flex flex-wrap gap-3">
            {(["ar", "fr"] as const).map((l) => (
              <label key={l} className="inline-flex min-h-11 cursor-pointer items-center gap-2 rounded-lg border border-ligne px-4 has-[:checked]:border-ocre has-[:checked]:bg-surface-2">
                <input type="radio" value={l} className="size-4 accent-[var(--c-ocre-fort)]" {...register("languePreferee")} />
                {l === "ar" ? t("langueAr") : t("langueFr")}
              </label>
            ))}
          </div>
        </fieldset>

        {/* Piège à robots : invisible pour les humains et pour les lecteurs d'écran. */}
        <div aria-hidden="true" className="absolute -start-[9999px] h-0 w-0 overflow-hidden">
          <label>
            Site web
            <input tabIndex={-1} autoComplete="off" {...register("siteWeb")} />
          </label>
        </div>

        <div className="sm:col-span-2">
          <label className="flex cursor-pointer items-start gap-3">
            <input
              type="checkbox"
              className="mt-1 size-5 shrink-0 accent-[var(--c-ocre-fort)]"
              {...aria("consentement")}
              {...register("consentement")}
            />
            <span>
              {t("consentement")}{" "}
              <Link href="/confidentialite" className="lien" target="_blank">
                {t("voirPolitique")}
              </Link>
            </span>
          </label>
          <MessageErreur id={id} champ="consentement" message={erreur("consentement")} />
        </div>

        {CLE_TURNSTILE && (
          <div className="sm:col-span-2">
            <div className="cf-turnstile" data-sitekey={CLE_TURNSTILE} data-language={langue} />
          </div>
        )}

        <div className="flex flex-wrap items-center gap-4 sm:col-span-2">
          <button type="submit" disabled={etat === "envoi"} className="bouton bouton-principal min-w-56 disabled:opacity-70">
            {etat === "envoi" ? t("envoiEnCours") : t("envoyer")}
          </button>
          <a
            href={`https://wa.me/${CONTACT.whatsappLien}?text=${encodeURIComponent(tw("message"))}`}
            target="_blank"
            rel="noopener"
            className="inline-flex items-center gap-2 font-semibold text-vert"
          >
            <IconeWhatsApp className="size-5" />
            {tw("bouton")}
          </a>
        </div>
      </div>
    </form>
  );
}

function Etiquette({
  id,
  pour,
  children,
  requis,
  obligatoire,
}: {
  id: string;
  pour: string;
  children: React.ReactNode;
  requis?: boolean;
  obligatoire: string;
}) {
  return (
    <label htmlFor={`${id}-${pour}`} className="mb-1.5 block font-semibold">
      {children}
      {requis && (
        <>
          <span aria-hidden="true" className="text-ocre-fort"> *</span>
          <span className="sr-only"> ({obligatoire})</span>
        </>
      )}
    </label>
  );
}

function MessageErreur({ id, champ, message }: { id: string; champ: string; message: string | null }) {
  return message ? (
    <p id={`${id}-${champ}-erreur`} className="mt-1.5 text-sm font-semibold text-erreur">
      {message}
    </p>
  ) : null;
}
