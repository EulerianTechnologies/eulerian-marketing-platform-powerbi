# Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Connector missing from *Get Data* | file not in `Documents\Power BI Desktop\Custom Connectors`, or extension security | see [INSTALL.md](INSTALL.md) §2 |
| `[TOKEN_INVALID] token is invalid` | wrong or revoked token | *File > Options > Data source settings* → edit the credential |
| `The endpoint must be https://<grid>.api.eulerian.com…` | endpoint outside the Eulerian platforms, or `http://` | use your grid URL |
| `dateRanges must hold 1 to 9 periods` | no period, or more than 9 | at most 9 periods per report; split into several queries and append them |
| `metric "…" is requested both plain and segmented: request it in two separate reports` | same metric requested plain and segmented in one report | request it in two separate reports |
| Unexpected `date_range` column | several periods: the period index (0 = first entry of `dateRanges`) | expected; see [USER-GUIDE.md](USER-GUIDE.md) *Comparing periods* |
| `dimension: field=… is not available for leaf=…` | dimension not available at this level | use *Dimensions of a level* for that path |
| `check: orderBy must be an array` | `orderBy` given as a record | `orderBy = {[field = "visit", direction = "DESC"]}` |
| Totals doubled on `rt#insummary` | the `global` row holds the total of all channels | `Table.SelectRows(t, each [media_key_po] <> "global")` |
| Refresh fails in the service | no gateway, or connector not loaded on the gateway | [INSTALL.md](INSTALL.md) §3 |
| Timeouts | very large report (synchronous mode) | filters, shorter period, smaller `maxRows` |

Report issues with the error message and the M of the query. **Never include the token.**
