// Vérifie qu'aucune formule interdite n'apparaît dans le site :
// le nom du propriétaire (on écrit seulement « CEO de NEXUS International »)
// et les promesses de résultat.
import fs from "node:fs";
import path from "node:path";

const INTERDITS = [/moussa/i, /oumara/i, /zouzou/i, /saley/i, /saleh/i, /موسى/, /عمارة/, /croissance garantie/i, /rendement garanti/i, /sans risque/i];
const DOSSIERS = ["app", "components", "lib", "messages", "content", "public"];
const EXTENSIONS = /\.(ts|tsx|json|mdx|md|svg|txt)$/;

const fautes = [];
function parcourir(d) {
  for (const e of fs.readdirSync(d, { withFileTypes: true })) {
    const p = path.join(d, e.name);
    if (e.isDirectory()) parcourir(p);
    else if (EXTENSIONS.test(e.name)) {
      const texte = fs.readFileSync(p, "utf8");
      for (const r of INTERDITS) if (r.test(texte)) fautes.push(`${p} : ${r}`);
    }
  }
}
DOSSIERS.filter((d) => fs.existsSync(d)).forEach(parcourir);
if (fautes.length) {
  console.error("Formules interdites trouvées :\n" + fautes.join("\n"));
  process.exit(1);
}
console.log("Textes conformes.");
