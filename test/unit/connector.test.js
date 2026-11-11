/**
 * Checks that run anywhere (no Windows, no Power BI): M syntax with Microsoft's parser, and static
 * consistency of the connector. Behaviour is tested by PQTest on Windows CI (test/pqtest/).
 */
import { readFileSync, readdirSync, existsSync } from "node:fs";
import { describe, expect, it } from "vitest";
import { DefaultSettings, TaskUtils } from "@microsoft/powerquery-parser";

const read = (rel) => readFileSync(new URL(`../../${rel}`, import.meta.url), "utf8");
const connector = read("src/EulerianMarketingPlatform.pq");
const resx = read("src/resources.resx");

async function parse(text) {
	const task = await TaskUtils.tryLexParse(DefaultSettings, text);
	return TaskUtils.isOk(task) ? null : task.error?.message ?? "parse error";
}

describe("M syntax", () => {
	it("connector section document parses", async () => expect(await parse(connector)).toBeNull());
	it("PQTest query file parses", async () => expect(await parse(read("test/pqtest/EulerianMarketingPlatform.query.pq"))).toBeNull());
	it("the parser does reject invalid M (sanity check)", async () => expect(await parse("section S; shared F = let a = 1 in ;")).not.toBeNull());
});

describe("connector consistency", () => {
	it("has exactly one data source function, published, with Key authentication and TestConnection", () => {
		expect(connector.match(/\[DataSource\.Kind\s*=/g)).toHaveLength(1);
		expect(connector).toMatch(/\[DataSource\.Kind = "EulerianMarketingPlatform", Publish = "EulerianMarketingPlatform\.Publish"\]\nshared EulerianMarketingPlatform\.Contents/);
		expect(connector).toMatch(/Authentication = \[\s*Key = \[/);
		expect(connector).toMatch(/TestConnection = \(dataSourcePath\) => \{"EulerianMarketingPlatform\.Contents", dataSourcePath\}/);
	});

	it("every Extension.LoadString key exists in resources.resx", () => {
		const keys = [...connector.matchAll(/Extension\.LoadString\("([^"]+)"\)/g)].map((m) => m[1]);
		expect(keys.length).toBeGreaterThan(0);
		for (const k of keys) expect(resx).toContain(`<data name="${k}"`);
	});

	it("every Extension.Contents file exists (all icon sizes)", () => {
		const files = [...connector.matchAll(/Extension\.Contents\("([^"]+)"\)/g)].map((m) => m[1]);
		expect(files).toHaveLength(8);
		for (const f of files) expect(existsSync(new URL(`../../src/${f}`, import.meta.url))).toBe(true);
	});

	it("allows the same Eulerian domains as the Tableau and Qlik connectors", () => {
		expect(connector).toContain('AllowedDomains = {"api.eulerian.com", "api.eulerian.ca", "api.gouv.eulerian.fr"};');
	});

	it("sends the documented synchronous mode and no patching logic", () => {
		expect(connector).toContain("async = false");
		for (const banned of ['"global"', "1970", "includeTotals", "date_range_index"]) expect(connector).not.toContain(banned);
	});

	it("accepts 1 to 9 periods and adds the date_range dimension first when there are several", () => {
		expect(connector).not.toContain("exactly one period");
		expect(connector).toContain('List.Count(dateRanges) >= 1 and List.Count(dateRanges) <= 9');
		expect(connector).toContain('PeriodField = "date_range";');
		// Prepended only with several periods and when the user did not request it already.
		expect(connector).toMatch(/List\.Count\(dateRanges\) > 1 and not List\.Contains\(List\.Transform\(dims, \(d\) => d\[field\]\), PeriodField\)\s*then \{\[name = "Period", field = PeriodField\]\} & dims/);
		expect(connector).toContain("dimensions = WithPeriodDimension(dims, dateRanges)");
		expect(connector).toContain("else if field = PeriodField then Int64.Type");
	});

	it("paginates per period: full page = periods x take, per-period start, totalRowCount over all periods", () => {
		expect(connector).toContain("periods = List.Count(ranges)");
		expect(connector).toContain("nextStart = start + take");
		expect(connector).toContain("more = got = periods * take and (total = null or nextStart * periods < total) and nextStart < maxRows");
		// No kind-specific pagination.
		expect(connector).not.toMatch(/kind = "rt#insummary"/);
	});

	it("refuses the same metric requested plain and segmented", () => {
		expect(connector).toContain('plainAndSegmented = List.Intersect({fieldsWhere(false), fieldsWhere(true)})');
		expect(connector).toContain('is requested both plain and segmented: request it in two separate reports');
	});

	it("contains no token", () => {
		for (const f of readdirSync(new URL("../../src/", import.meta.url)).filter((n) => n.endsWith(".pq"))) {
			expect(read(`src/${f}`)).not.toMatch(/Bearer [A-Za-z0-9]/);
		}
		expect(read("test/pqtest/EulerianMarketingPlatform.query.pq")).not.toMatch(/Bearer /);
	});

	it("version matches package.json", () => {
		const { version } = JSON.parse(read("package.json"));
		expect(connector).toContain(`[Version = "${version}"]`);
	});
});
