"use client";

import { useActionState } from "react";
import { connexion } from "./actions";

export function Connexion() {
  const [etat, action, enCours] = useActionState(connexion, undefined);
  return (
    <form action={action} className="carte mx-auto mt-24 max-w-sm p-8">
      <h1 className="text-xl font-semibold">Espace d&apos;administration</h1>
      <p className="mt-1 text-sm text-gris">Desk Algérie-Niger</p>
      <label htmlFor="mdp" className="mt-6 mb-1.5 block font-semibold">
        Mot de passe
      </label>
      <input id="mdp" name="motDePasse" type="password" required autoComplete="current-password" className="champ" />
      {etat?.erreur && <p className="mt-2 text-sm font-semibold text-erreur">{etat.erreur}</p>}
      <button type="submit" disabled={enCours} className="bouton bouton-principal mt-5 w-full">
        {enCours ? "Vérification" : "Se connecter"}
      </button>
    </form>
  );
}
