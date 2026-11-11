// Generates the connector icons src/EulerianMarketingPlatform<size>.png: a blue rounded square with a white "E".
import { writeFileSync } from "node:fs";
import { encodePng } from "./png.mjs";

const SIZES = [16, 20, 24, 32, 40, 48, 64, 80];
const BLUE = [11, 92, 173, 255];
const WHITE = [255, 255, 255, 255];

for (const size of SIZES) {
	const px = new Uint8Array(size * size * 4);
	const r = Math.max(2, Math.round(size * 0.18)); // corner radius
	const set = (x, y, c) => px.set(c, (y * size + x) * 4);
	for (let y = 0; y < size; y++) {
		for (let x = 0; x < size; x++) {
			const cx = Math.min(Math.max(x, r), size - 1 - r);
			const cy = Math.min(Math.max(y, r), size - 1 - r);
			if ((x - cx) ** 2 + (y - cy) ** 2 <= r * r) set(x, y, BLUE);
		}
	}
	// "E": vertical bar + three horizontal bars.
	const u = size / 16;
	const fill = (x0, y0, w, h) => {
		for (let y = Math.round(y0 * u); y < Math.round((y0 + h) * u); y++) for (let x = Math.round(x0 * u); x < Math.round((x0 + w) * u); x++) set(x, y, WHITE);
	};
	fill(4, 3, 2.5, 10);
	fill(4, 3, 8, 2);
	fill(4, 7, 6.5, 2);
	fill(4, 11, 8, 2);
	writeFileSync(new URL(`../src/EulerianMarketingPlatform${size}.png`, import.meta.url), encodePng(size, px));
}
console.log(`icons: ${SIZES.join(", ")} px`);
