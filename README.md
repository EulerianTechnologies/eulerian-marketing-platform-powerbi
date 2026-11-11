# Eulerian Marketing Platform — Power BI connector

Power Query **custom connector** (`.mez`) for the Eulerian Marketing Platform
[Batch Reporting API](https://doc.api.eulerian.com). It works in Power BI Desktop, and in the Power BI service
through an on-premises data gateway. No server to host.

## Features

- *Get Data > Eulerian Marketing Platform*: endpoint URL + API token (stored by Power BI as the credential).
- Navigator: one folder per website, with the **Report** function, the **Kinds** table and a catalog per kind
  (**Metrics**, **Dimensions**, **Segmentation levels**). Field names come from the API discovery endpoints.
- **Report**: dimensions, metrics (with `segment.by`), 1 to 9 periods (a `date_range` *Period* column is added when
  there are several), time breakdown, filters, automatic pagination, typed columns (`Int64`, decimal,
  `Percentage`, `Date`, `DateTime`).
- Rows are loaded exactly as the API returns them.
- Scheduled refresh in the Power BI service through a gateway.

## Requirements

- Power BI Desktop, and an on-premises data gateway (standard mode) for refresh in the Power BI service.
- An Eulerian API token with read access to the websites to report on.
- An Eulerian endpoint: `https://<grid>.api.eulerian.com`, `https://<grid>.api.eulerian.ca` or
  `https://<grid>.api.gouv.eulerian.fr`.

## Documentation

| | |
|---|---|
| Install (Desktop, gateway) | [docs/INSTALL.md](docs/INSTALL.md) |
| Use | [docs/USER-GUIDE.md](docs/USER-GUIDE.md) |
| Troubleshooting | [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) |

## Build from source

Requires Node.js 20 or later.

```bash
npm ci
npm test          # tests
npm run build     # -> dist/EulerianMarketingPlatform.mez
```

## License

MIT © Eulerian Technologies
