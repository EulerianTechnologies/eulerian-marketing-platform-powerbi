// Packages the connector: dist/EulerianMarketingPlatform.mez (a ZIP of the .pq, resources and icons).
import { mkdirSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { zip } from "./png.mjs";

const src = new URL("../src/", import.meta.url);
const files = readdirSync(src)
	.filter((f) => (f.endsWith(".pq") && !f.endsWith(".query.pq")) || f.endsWith(".resx") || f.endsWith(".png"))
	.sort();
const entries = files.map((name) => ({ name, data: readFileSync(new URL(name, src)) }));
mkdirSync(new URL("../dist/", import.meta.url), { recursive: true });
const out = new URL("../dist/EulerianMarketingPlatform.mez", import.meta.url);
writeFileSync(out, zip(entries));
console.log(`dist/EulerianMarketingPlatform.mez: ${files.join(", ")}`);
