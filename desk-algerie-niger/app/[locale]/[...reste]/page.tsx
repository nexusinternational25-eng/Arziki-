import { notFound } from "next/navigation";

// Toute adresse inconnue sous /ar ou /fr affiche la page 404 dans la bonne langue.
export default function Reste() {
  notFound();
}
