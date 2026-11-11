# Installation

## 1. Get the connector

Download `EulerianMarketingPlatform.mez` from the
[GitHub releases](https://github.com/EulerianTechnologies/eulerian-marketing-platform-powerbi/releases),
or build it (`npm run build`).

## 2. Power BI Desktop

1. Copy the file to `Documents\Power BI Desktop\Custom Connectors` (create the folder if needed).
2. The connector is not signed: *File > Options and settings > Options > Security > Data Extensions* >
   **(Not Recommended) Allow any extension to load without validation or warning**.
3. Restart Power BI Desktop. *Get Data > Online Services > Eulerian Marketing Platform (Beta)*.

## 3. Power BI service (scheduled refresh)

Custom connectors refresh through an **on-premises data gateway (standard mode)**:

1. On the gateway machine, copy the `.mez` into the folder set in the gateway app, under *Connectors*
   (by default `C:\Windows\ServiceProfiles\PBIEgwService\Documents\Power BI Desktop\Custom Connectors`), and enable
   *Load custom data connectors from folder*. Restart the gateway.
2. Power BI service > *Settings > Manage connections and gateways > New*: connection type
   **Eulerian Marketing Platform**, the same endpoint URL as in Desktop, authentication *Key* = API token.
3. Publish the report, then map the dataset to that gateway connection (*Dataset settings > Gateway connection*).

The connector implements `TestConnection`, so the gateway can test and refresh the data source.

## 4. Network

Power BI Desktop and the gateway must reach the Eulerian API over HTTPS/443:
`*.api.eulerian.com`, `*.api.eulerian.ca` or `*.api.gouv.eulerian.fr`. Any other endpoint is rejected before
the token is sent.

## 5. API token

Create a token in the Eulerian interface, with read access to the websites to report on. Power BI stores it as the
credential of the endpoint (*File > Options > Data source settings* to edit or clear it).
