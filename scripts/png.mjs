// Minimal PNG encoder and ZIP writer (Node built-ins only), shared by make-icons and build-mez.
import { deflateRawSync, deflateSync } from "node:zlib";

const CRC_TABLE = Array.from({ length: 256 }, (_, n) => {
	let c = n;
	for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
	return c >>> 0;
});
export function crc32(buf) {
	let c = 0xffffffff;
	for (const b of buf) c = CRC_TABLE[(c ^ b) & 0xff] ^ (c >>> 8);
	return (c ^ 0xffffffff) >>> 0;
}

/** RGBA pixels (Uint8Array, size*size*4) -> PNG buffer. */
export function encodePng(size, rgba) {
	const chunk = (type, data) => {
		const len = Buffer.alloc(4);
		len.writeUInt32BE(data.length);
		const td = Buffer.concat([Buffer.from(type), data]);
		const crc = Buffer.alloc(4);
		crc.writeUInt32BE(crc32(td));
		return Buffer.concat([len, td, crc]);
	};
	const ihdr = Buffer.alloc(13);
	ihdr.writeUInt32BE(size, 0);
	ihdr.writeUInt32BE(size, 4);
	ihdr.set([8, 6, 0, 0, 0], 8); // 8-bit RGBA
	const raw = Buffer.alloc(size * (size * 4 + 1));
	for (let y = 0; y < size; y++) {
		raw[y * (size * 4 + 1)] = 0; // filter: none
		Buffer.from(rgba.buffer, y * size * 4, size * 4).copy(raw, y * (size * 4 + 1) + 1);
	}
	return Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk("IHDR", ihdr), chunk("IDAT", deflateSync(raw)), chunk("IEND", Buffer.alloc(0))]);
}

/** [{ name, data }] -> ZIP buffer (deflate), with a fixed timestamp for reproducible builds. */
export function zip(entries) {
	const local = [];
	const central = [];
	let offset = 0;
	const DOS_TIME = 0;
	const DOS_DATE = ((2026 - 1980) << 9) | (1 << 5) | 1;
	for (const { name, data } of entries) {
		const nameBuf = Buffer.from(name, "utf8");
		const comp = deflateRawSync(data);
		const crc = crc32(data);
		const h = Buffer.alloc(30);
		h.writeUInt32LE(0x04034b50, 0);
		h.writeUInt16LE(20, 4);
		h.writeUInt16LE(0x0800, 6); // UTF-8 names
		h.writeUInt16LE(8, 8); // deflate
		h.writeUInt16LE(DOS_TIME, 10);
		h.writeUInt16LE(DOS_DATE, 12);
		h.writeUInt32LE(crc, 14);
		h.writeUInt32LE(comp.length, 18);
		h.writeUInt32LE(data.length, 22);
		h.writeUInt16LE(nameBuf.length, 26);
		local.push(h, nameBuf, comp);
		const c = Buffer.alloc(46);
		c.writeUInt32LE(0x02014b50, 0);
		c.writeUInt16LE(20, 4);
		c.writeUInt16LE(20, 6);
		c.writeUInt16LE(0x0800, 8);
		c.writeUInt16LE(8, 10);
		c.writeUInt16LE(DOS_TIME, 12);
		c.writeUInt16LE(DOS_DATE, 14);
		c.writeUInt32LE(crc, 16);
		c.writeUInt32LE(comp.length, 20);
		c.writeUInt32LE(data.length, 24);
		c.writeUInt16LE(nameBuf.length, 28);
		c.writeUInt32LE(offset, 42);
		central.push(c, nameBuf);
		offset += h.length + nameBuf.length + comp.length;
	}
	const cd = Buffer.concat(central);
	const end = Buffer.alloc(22);
	end.writeUInt32LE(0x06054b50, 0);
	end.writeUInt16LE(entries.length, 8);
	end.writeUInt16LE(entries.length, 10);
	end.writeUInt32LE(cd.length, 12);
	end.writeUInt32LE(offset, 16);
	return Buffer.concat([...local, cd, end]);
}
