# Changelog

## 1.0.0 — 2026-11-11

- Power Query custom connector for the Eulerian Batch Reporting API (`flat_aggregate`), for Power BI Desktop and
  the Power BI service through an on-premises data gateway.
- API token authentication; endpoints restricted to the Eulerian platforms (`*.api.eulerian.com`,
  `*.api.eulerian.ca`, `*.api.gouv.eulerian.fr`).
- Navigation per website: Report function, kinds, metrics, dimensions (default level or a given level),
  segmentation levels.
- Reports: dimensions, 1 to 35 metrics with optional segmentation, filters, ordering, time breakdown
  (`dateScale`), optional segmentation level (`path`).
- 1 to 9 periods per report: with several periods, a `date_range` column (caption *Period*, 0 = first period) is
  added as the first column.
- Automatic pagination (`pageSize` and `maxRows` per period).
- Typed columns: whole number, decimal, percentage, date, date/time; field names or API labels as column names.
- Explicit error when a metric is requested both plain and segmented in the same report.
- Scheduled refresh support (`TestConnection`).
