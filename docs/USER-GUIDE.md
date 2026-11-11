# User guide

## Connecting

*Get Data > Eulerian Marketing Platform (Beta)* → **API endpoint URL** (e.g. `https://mygrid.api.eulerian.com`)
→ **API token**. The navigator then shows:

```
Eulerian Marketing Platform
└─ demo-fr                       one folder per website the token can read
   ├─ Report                     function: runs a report (see below)
   ├─ Kinds                      rt# data sources of this site
   └─ acquisition & performance (rt#insummary)
      ├─ Metrics                 field, name, affinity
      ├─ Dimensions (default level)
      ├─ Dimensions of a level   function: path -> dimensions
      └─ Segmentation levels     path, text, parent
```

Field names used in reports must come from these tables.

## Running a report

Select **Report** in the navigator and fill the parameters, or write M in the Advanced Editor:

```m
let
    Source = EulerianMarketingPlatform.Contents("https://mygrid.api.eulerian.com"),
    Report = Source{[Key = "demo-fr"]}[Data]{[Key = "Report"]}[Data],
    Channels = Report(
        "rt#insummary",
        {[field = "media_key_po", name = "Channel"]},
        {"visit", "realscartvalid", "realscartvalidamount", "realscartvalid_visit"},
        {"CURRENT_MONTH"}
    )
in
    Channels
```

| Parameter | Format |
|---|---|
| `kind` | `"rt#insummary"`, `"rt#ope"`… (see *Kinds*) |
| `dimensions` | list of field names or records `[field = "...", name = "..."]` |
| `metrics` | 1 to 35 field names or records, with optional `segment = [by = "ordertype"]` |
| `dateRanges` | 1 to 9 periods: `{"LAST_7_DAYS"}` (preset), `{[dateFrom = "2026-10-01", dateTo = "2026-10-07"]}` (inclusive), or several, e.g. `{"CURRENT_MONTH", "LAST_MONTH"}` (see *Comparing periods*) |
| `options` (optional record) | see below |

| Option | Meaning |
|---|---|
| `path` | optional segmentation level (from *Segmentation levels*); without it the kind's default level is used |
| `dateScale` | `"H"`, `"D"`, `"W"`, `"M"` time breakdown (hour < 3 days, day < 90 days, week < 55 weeks, month < 15 months) |
| `language` | `"en"` (default), `"fr"`, `"es"` |
| `pageSize` | rows per period per API call (default 1000) |
| `maxRows` | row cap per period (default 100000) |
| `columnNames` | `"field"` (default, stable) or `"label"` (API captions) |
| `dimensionFilterClauses`, `metricFilterClauses`, `segmentFilterClauses`, `segments`, `orderBy`, `dateScalePer`, `overwriteNameByAlias`, `customLabels` | passed to the API as documented |

```m
Campaigns = Report(
    "rt#ope",
    {"publisher_name", "ope_name"},
    {"click", "cost", "realscartvalidamount"},
    {"LAST_30_DAYS"},
    [
        segmentFilterClauses = {[field = "device", operator = "IN", value = "Phone"]}
    ]
)
```

## Comparing periods

Give up to 9 periods in `dateRanges`. With more than one, the connector adds the `date_range` dimension as the first
column (caption **Period**, shown with `columnNames = "label"`): the 0-based index of the period in `dateRanges`
(`0` = first period, `1` = second…), typed whole number. Each period lists the same rows.

```m
Comparison = Report("rt#insummary", {"media_key_po"}, {"visit"}, {"CURRENT_MONTH", "LAST_MONTH"})
// date_range | media_key_po | visit   (date_range 0 = CURRENT_MONTH, 1 = LAST_MONTH)
```

With one period no column is added. To place the period column elsewhere, request `date_range` yourself in
`dimensions`; it is then not added a second time.

## Resulting table

Rows exactly as the API returns them. Column names are the API fields (or labels with `columnNames = "label"`).

| API type | Power Query type |
|---|---|
| `string` | text |
| `int` (including `date_range`) | `Int64.Type` |
| `float` | decimal number |
| `pct` | `Percentage.Type` (0..1) |
| `date_day` | date |
| `date_iso8601`, `date_hour` | date/time |

> **Ratios**: averaging daily conversion rates does not give the period's rate. Load the components and create a
> measure: `DIVIDE(SUM(t[realscartvalid]), SUM(t[visit]))`.

## Good to know

- **`rt#insummary` includes a `global` row** holding the total of all channels. Exclude it in your query before
  summing channels: `Table.SelectRows(Channels, each [media_key_po] <> "global")`.
- A metric cannot be requested both plain and segmented in the same report: use two reports. Such a report is
  refused with `metric "<field>" is requested both plain and segmented: request it in two separate reports`.
  The same metric segmented by two different segmentations is fine.
- When the API returns two segment columns with the same field id, the second one is named `<field>__2`.
- Only `rt#` kinds are supported; `cj#` and `mta#` reports are not available through this connector.
