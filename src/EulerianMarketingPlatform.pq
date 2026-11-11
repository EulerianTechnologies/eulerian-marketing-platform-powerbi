// Eulerian Marketing Platform: Power Query custom connector (Power BI Desktop, gateway refresh).
// Batch Reporting API, flat_aggregate endpoint. See docs/ for installation and usage.
[Version = "1.0.0"]
section EulerianMarketingPlatform;

// ---------------------------------------------------------------------------------------------
// Public entry point
// ---------------------------------------------------------------------------------------------

// The ONLY data source function: its single required parameter (the endpoint) is the data source
// path, so one credential (API token) is stored per endpoint. Everything else is reached through the
// navigation table, so no other query creates a new data source path or credential prompt.
[DataSource.Kind = "EulerianMarketingPlatform", Publish = "EulerianMarketingPlatform.Publish"]
shared EulerianMarketingPlatform.Contents = Value.ReplaceType(ContentsImpl, ContentsType);

ContentsType = type function (
    endpoint as (type text meta [
        Documentation.FieldCaption = "API endpoint URL",
        Documentation.FieldDescription = "https://<grid>.api.eulerian.com, https://<grid>.api.eulerian.ca or https://<grid>.api.gouv.eulerian.fr",
        Documentation.SampleValues = {"https://mygrid.api.eulerian.com"}
    ])
) as table meta [
    Documentation.Name = "Eulerian Marketing Platform",
    Documentation.LongDescription = "Websites, kinds, metrics, dimensions and the Report function of the Eulerian Batch Reporting API."
];

// Navigation: one folder per website, holding the Report function, the kinds and a per-kind catalog.
ContentsImpl = (endpoint as text) as table =>
    let
        origin = ApiOrigin(endpoint),
        sites = ListSites(origin),
        rows = List.Transform(
            Table.ToRecords(sites),
            (s) => {s[name], s[name], SiteNavigation(origin, s[name]), "Folder", "Folder", false}
        ),
        nav = #table({"Name", "Key", "Data", "ItemKind", "ItemName", "IsLeaf"}, rows)
    in
        Table.ToNavigationTable(nav, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf");

SiteNavigation = (origin as text, site as text) as table =>
    let
        kinds = ListKinds(origin, site),
        kindFolders = List.Transform(
            Table.ToRecords(kinds),
            (k) => {k[name] & " (" & k[kind] & ")", k[kind], KindNavigation(origin, site, k[kind]), "Folder", "Folder", false}
        ),
        rows = {
            {"Report", "Report", Value.ReplaceType((kind, dimensions, metrics, dateRanges, optional options) =>
                RunReport(origin, site, kind, dimensions, metrics, dateRanges, options), ReportType), "Function", "Function", true},
            {"Kinds", "Kinds", kinds, "Table", "Table", true}
        } & kindFolders,
        nav = #table({"Name", "Key", "Data", "ItemKind", "ItemName", "IsLeaf"}, rows)
    in
        Table.ToNavigationTable(nav, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf");

KindNavigation = (origin as text, site as text, kind as text) as table =>
    let
        nav = #table(
            {"Name", "Key", "Data", "ItemKind", "ItemName", "IsLeaf"},
            {
                {"Metrics", "Metrics", ListMetrics(origin, site, kind), "Table", "Table", true},
                {"Dimensions (default level)", "Dimensions", ListDimensionsAt(origin, site, ResolveDefaultPath(origin, site, kind)), "Table", "Table", true},
                {"Dimensions of a level", "DimensionsOfLevel", Value.ReplaceType((path as text) => ListDimensionsAt(origin, site, path),
                    type function (path as (type text meta [Documentation.FieldCaption = "Segmentation level (path)"])) as table), "Function", "Function", true},
                {"Segmentation levels", "Segmentations", ListSegmentations(origin, site, kind), "Table", "Table", true}
            }
        )
    in
        Table.ToNavigationTable(nav, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf");

ReportType = type function (
    kind as (type text meta [
        Documentation.FieldCaption = "Kind",
        Documentation.FieldDescription = "Data source, e.g. rt#insummary (see the Kinds table)",
        Documentation.SampleValues = {"rt#insummary"}
    ]),
    dimensions as (type list meta [
        Documentation.FieldCaption = "Dimensions",
        Documentation.FieldDescription = "List of dimension fields, e.g. {""media_key_po""} or {[field=""ope_name"", name=""Campaign""]}"
    ]),
    metrics as (type list meta [
        Documentation.FieldCaption = "Metrics",
        Documentation.FieldDescription = "1 to 35 metric fields, e.g. {""visit"", [field=""realscartvalidamount"", segment=[by=""ordertype""]]}"
    ]),
    dateRanges as (type list meta [
        Documentation.FieldCaption = "Period",
        Documentation.FieldDescription = "1 to 9 periods: {""CURRENT_MONTH""}, {""CURRENT_MONTH"", ""LAST_MONTH""} or {[dateFrom=""2026-10-01"", dateTo=""2026-10-07""]}. With several periods a date_range column (caption Period, 0 = first period) is added."
    ]),
    optional options as (type nullable record meta [
        Documentation.FieldCaption = "Options",
        Documentation.FieldDescription = "path, dateScale (H/D/W/M), language, pageSize and maxRows (per period), columnNames (""field""/""label""), filters, orderBy..."
    ])
) as table meta [
    Documentation.Name = "Eulerian report",
    Documentation.LongDescription = "Runs a Batch Reporting flat_aggregate query and returns the rows exactly as the API sends them."
];

// ---------------------------------------------------------------------------------------------
// Data source definition
// ---------------------------------------------------------------------------------------------

EulerianMarketingPlatform = [
    // Enables gateway / Power BI service refresh: re-run Contents on the stored endpoint.
    TestConnection = (dataSourcePath) => {"EulerianMarketingPlatform.Contents", dataSourcePath},
    Authentication = [
        Key = [
            KeyLabel = Extension.LoadString("KeyLabel"),
            Label = Extension.LoadString("AuthenticationLabel")
        ]
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

EulerianMarketingPlatform.Publish = [
    Beta = true,
    Category = "Online Services",
    ButtonText = {Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp")},
    LearnMoreUrl = "https://github.com/EulerianTechnologies/eulerian-marketing-platform-powerbi",
    SourceImage = EulerianMarketingPlatform.Icons,
    SourceTypeImage = EulerianMarketingPlatform.Icons
];

EulerianMarketingPlatform.Icons = [
    Icon16 = {
        Extension.Contents("EulerianMarketingPlatform16.png"),
        Extension.Contents("EulerianMarketingPlatform20.png"),
        Extension.Contents("EulerianMarketingPlatform24.png"),
        Extension.Contents("EulerianMarketingPlatform32.png")
    },
    Icon32 = {
        Extension.Contents("EulerianMarketingPlatform32.png"),
        Extension.Contents("EulerianMarketingPlatform40.png"),
        Extension.Contents("EulerianMarketingPlatform48.png"),
        Extension.Contents("EulerianMarketingPlatform64.png")
    }
];

// ---------------------------------------------------------------------------------------------
// Endpoint validation (the token must never be sent outside the Eulerian platforms)
// ---------------------------------------------------------------------------------------------

AllowedDomains = {"api.eulerian.com", "api.eulerian.ca", "api.gouv.eulerian.fr"};

// "https://grid.api.eulerian.com/ea/v2/" or "grid.api.eulerian.com" -> "https://grid.api.eulerian.com".
// http://localhost / 127.0.0.1 are accepted for the mock API used by the tests.
ApiOrigin = (endpoint as text) as text =>
    let
        trimmed = Text.TrimEnd(Text.Trim(endpoint), "/"),
        withScheme = if Text.Contains(trimmed, "://") then trimmed else "https://" & trimmed,
        parts = try Uri.Parts(withScheme) otherwise null,
        host = if parts = null then "" else Text.Lower(parts[Host]),
        scheme = if parts = null then "" else Text.Lower(parts[Scheme]),
        isLocal = host = "localhost" or host = "127.0.0.1",
        // <grid>.<domain>: exactly one label (letters, digits, dashes) before an allowed domain.
        gridOf = (d as text) => if Text.EndsWith(host, "." & d) then Text.BeforeDelimiter(host, "." & d, {0, RelativePosition.FromEnd}) else null,
        isAllowed = List.AnyTrue(List.Transform(AllowedDomains, (d) =>
            let g = gridOf(d) in g <> null and g <> "" and not Text.Contains(g, ".")
                and Text.Remove(g, {"a".."z", "0".."9", "-"}) = "")),
        port = if parts = null or parts[Port] = 80 or parts[Port] = 443 then "" else ":" & Text.From(parts[Port])
    in
        if isLocal and (scheme = "http" or scheme = "https") then scheme & "://" & host & port
        else if isAllowed and scheme = "https" then "https://" & host
        else error Error.Record("Eulerian.InvalidEndpoint",
            "The endpoint must be https://<grid>.api.eulerian.com, https://<grid>.api.eulerian.ca or https://<grid>.api.gouv.eulerian.fr",
            endpoint);

// ---------------------------------------------------------------------------------------------
// HTTP
// ---------------------------------------------------------------------------------------------

// Errors are returned with HTTP 200 and {"error": true, "error_msg": ...}: the body is always checked.
CallApi = (origin as text, relativePath as text, optional query as nullable record, optional body as any) as record =>
    let
        headers = [
            Authorization = "Bearer " & Extension.CurrentCredential()[Key],
            #"Content-Type" = "application/json",
            Accept = "application/json"
        ],
        options = [
            RelativePath = relativePath,
            Headers = headers,
            ManualStatusHandling = {400, 401, 403, 404, 429, 500, 502, 503, 504},
            Timeout = #duration(0, 0, 10, 0)
        ]
            & (if query = null then [] else [Query = query])
            & (if body = null then [] else [Content = Json.FromValue(body)]),
        response = Web.Contents(origin, options),
        status = Value.Metadata(response)[Response.Status],
        json = if status = 200 then Json.Document(response) else null,
        checked =
            if status <> 200 then
                error Error.Record("Eulerian.HttpError", "HTTP " & Text.From(status) & " on " & relativePath, [Status = status])
            else if json = null or not (json is record) then
                error Error.Record("Eulerian.ApiError", "Empty or non-JSON response from the Eulerian API")
            else if Record.FieldOrDefault(json, "error", false) = true then
                error Error.Record(
                    "Eulerian.ApiError",
                    (if Record.FieldOrDefault(json, "error_code", null) <> null then "[" & json[error_code] & "] " else "")
                        & Record.FieldOrDefault(json, "error_msg", "Unknown Eulerian API error"),
                    [Code = Record.FieldOrDefault(json, "error_code", null)])
            else json
    in
        checked;

BatchPath = (site as text, action as text) as text =>
    "ea/v2/ea/" & Uri.EscapeDataString(site) & "/report/batch/" & action & ".json";

// Standard envelope { data: { fields: [{name}], rows: [[...]] } } -> table.
ListToTable = (json as record) as table =>
    let
        data = Record.FieldOrDefault(json, "data", []),
        fields = Record.FieldOrDefault(data, "fields", null),
        names = if fields = null then error Error.Record("Eulerian.ApiError", "Unexpected API response: missing data.fields") else List.Transform(fields, each _[name]),
        rows = Record.FieldOrDefault(data, "rows", {}),
        padded = List.Transform(rows, (r) => List.FirstN(r & List.Repeat({null}, List.Count(names)), List.Count(names)))
    in
        Table.FromRows(padded, names);

// ---------------------------------------------------------------------------------------------
// Discovery
// ---------------------------------------------------------------------------------------------

ListSites = (origin as text) as table =>
    let
        t = ListToTable(CallApi(origin, "ea/v2/er/account/getallowedwebsite.json"))
    in
        Table.RenameColumns(Table.SelectColumns(t, {"website_name", "website_id", "website_tzone"}),
            {{"website_name", "name"}, {"website_id", "id"}, {"website_tzone", "timezone"}});

// Only real-time aggregate kinds (rt#); cj#, mta#, hq# use other endpoints.
ListKinds = (origin as text, site as text) as table =>
    let
        t = ListToTable(CallApi(origin, BatchPath(site, "kinds")))
    in
        Table.SelectRows(t, each Text.StartsWith(Text.From([kind]), "rt#"));

ListMetrics = (origin as text, site as text, kind as text) as table =>
    ListToTable(CallApi(origin, BatchPath(site, "metrics"), [kind = kind]));

ListDimensionsAt = (origin as text, site as text, path as text) as table =>
    ListToTable(CallApi(origin, BatchPath(site, "dimensions"), [path = path]));

// Segmentation levels flattened: path, text, parent path (null for first level).
ListSegmentations = (origin as text, site as text, kind as text) as table =>
    let
        t = ListToTable(CallApi(origin, BatchPath(site, "segmentations"), [kind = kind])),
        rows = List.Combine(List.Transform(Table.ToRecords(t), (r) =>
            {{r[path], r[text], null}}
            & List.Transform(if r[segmentations] = null then {} else r[segmentations], (c) => {c[path], c[text], r[path]})))
    in
        #table(type table [path = text, text = text, parent = nullable text], rows);

// Default path of a kind: a dryRun query returns the path resolved by the engine.
ResolveDefaultPath = (origin as text, site as text, kind as text) as text =>
    let
        body = [
            async = false,
            dryRun = true,
            reports = {[kind = kind, dateRanges = {[range = "YESTERDAY"]}, dimensions = {[name = "d", field = "date_day"]}, metrics = {[name = "m", field = "visit"]}]},
            output = [flat = true]
        ],
        json = CallApi(origin, BatchPath(site, "flat_aggregate"), null, body)
    in
        json[data][request][reports]{0}[path];

// ---------------------------------------------------------------------------------------------
// Report
// ---------------------------------------------------------------------------------------------

AsFieldRecord = (f as any, isMetric as logical) as record =>
    let
        r = if f is text then [field = f] else if f is record then f else error Error.Record("Eulerian.InvalidQuery", "dimensions/metrics items must be text or records", f),
        base = [name = Record.FieldOrDefault(r, "name", r[field]), field = r[field]],
        seg = Record.FieldOrDefault(r, "segment", null)
    in
        if isMetric and seg <> null then base & [segment = seg] else base;

AsDateRange = (d as any) as record =>
    if d is text then [range = Text.Upper(d)]
    else if d is record and Record.HasFields(d, "dateFrom") then [dateFormat = "YYYY-MM-DD"] & d
    else if d is record then d
    else error Error.Record("Eulerian.InvalidQuery", "dateRanges items must be text presets or records", d);

ValidateReport = (kind as text, dimensions as list, metrics as list, dateRanges as list) as logical =>
    let
        // A metric field cannot be requested both plain and segmented in the same report: such reports are
        // refused. The same field segmented by two different segmentations is fine: only the plain/segmented
        // combination is checked.
        mets = List.Transform(metrics, (m) => AsFieldRecord(m, true)),
        // AsFieldRecord keeps the segment field only when a non-null segment was given.
        fieldsWhere = (segmented as logical) as list =>
            List.Distinct(List.Transform(List.Select(mets, (m) => Record.HasFields(m, "segment") = segmented), (m) => m[field])),
        plainAndSegmented = List.Intersect({fieldsWhere(false), fieldsWhere(true)}),
        problems = List.RemoveNulls({
            if Text.StartsWith(kind, "rt#") then null else "kind must start with rt#",
            if List.Count(dimensions) > 0 then null else "at least one dimension is required",
            if List.Count(metrics) > 0 then null else "at least one metric is required",
            if List.Count(metrics) <= 35 then null else "at most 35 metrics are allowed",
            // The API accepts up to 9 dateRanges per report.
            if List.Count(dateRanges) >= 1 and List.Count(dateRanges) <= 9 then null else "dateRanges must hold 1 to 9 periods"
        }) & List.Transform(plainAndSegmented, (f) =>
            "metric """ & Text.From(f) & """ is requested both plain and segmented: request it in two separate reports")
    in
        if List.IsEmpty(problems) then true else error Error.Record("Eulerian.InvalidQuery", Text.Combine(problems, "; "));

// Report options copied verbatim into the API report object.
PassThroughOptions = {"dimensionFilterClauses", "metricFilterClauses", "segmentFilterClauses", "segments", "dateScalePer", "overwriteNameByAlias", "customLabels"};

// Dimension holding the 0-based index of the dateRanges entry of each row.
PeriodField = "date_range";

// With several periods the rows must say which period they belong to: the date_range dimension is added
// first, unless the user already requested it. With one period nothing is added (it can still be requested).
WithPeriodDimension = (dims as list, dateRanges as list) as list =>
    if List.Count(dateRanges) > 1 and not List.Contains(List.Transform(dims, (d) => d[field]), PeriodField)
    then {[name = "Period", field = PeriodField]} & dims
    else dims;

BuildBody = (kind as text, dims as list, mets as list, dateRanges as list, opts as record, start as number, maxEntries as number) as record =>
    let
        orderBy = Record.FieldOrDefault(opts, "orderBy", null),
        report =
            [
                kind = kind,
                language = Record.FieldOrDefault(opts, "language", "en"),
                dateRanges = dateRanges,
                dimensions = WithPeriodDimension(dims, dateRanges),
                metrics = mets,
                // Must be an array; a stable order is required for pagination.
                orderBy = if orderBy = null then {[field = mets{0}[field], direction = "DESC"]} else orderBy,
                // Applies to each period: start and maxEntries are per period.
                limit = [start = start, maxEntries = maxEntries]
            ]
            & (if Record.FieldOrDefault(opts, "path", null) = null then [] else [path = opts[path]])
            & (if Record.FieldOrDefault(opts, "dateScale", null) = null then [] else [dateScale = opts[dateScale], dateRangeSplitPerScale = true])
            & Record.SelectFields(opts, List.Intersect({Record.FieldNames(opts), PassThroughOptions}))
    in
        // Synchronous mode, documented in the how-to (section 11 "async: false").
        [async = false, reports = {report}, output = [flat = true]];

// Unique column ids. The API can give two different segment values the same field id: both columns are
// kept, the second gets __2 (values unchanged).
UniqueNames = (names as list) as list =>
    List.Accumulate(names, {}, (acc, n) =>
        let count = List.Count(List.Select(acc, (a) => a = n or Text.StartsWith(a, n & "__"))) in
            acc & {if count = 0 then n else n & "__" & Text.From(count + 1)});

ColumnType = (col as record) as type =>
    let
        field = col[field],
        t = Text.Lower(Record.FieldOrDefault(col, "dataType", Record.FieldOrDefault(col, "affinity", if col[type] = "metric" then "float" else "string")))
    in
        if field = "date_day" then type nullable date
        // Period index (0 = first dateRanges entry), declared int by the API.
        else if field = PeriodField then Int64.Type
        else if field = "date_iso8601" or field = "date_hour" then type nullable datetime
        else if t = "int" then Int64.Type
        else if t = "pct" then Percentage.Type
        else if t = "float" or t = "number" then type nullable number
        else type nullable text;

// Text -> typed value. date_iso8601 = "YYYY-MM-DD HH:MM:SS.mmm", date_hour = "YYYY-MM-DDTHH".
ConvertValue = (v as any, t as type) as any =>
    if v = null or v = "" then null
    else if Type.Is(t, type nullable date) then try Date.FromText(Text.Start(Text.From(v), 10), [Format = "yyyy-MM-dd"]) otherwise null
    else if Type.Is(t, type nullable datetime) then
        let s = Text.Replace(Text.From(v), "T", " "), full = Text.Start(s & ":00:00", 19) in
            try DateTime.FromText(full, [Format = "yyyy-MM-dd HH:mm:ss"]) otherwise null
    else if Type.Is(t, type nullable number) then try Number.From(v) otherwise null
    else Text.From(v);

// One page of the flat_aggregate content -> typed table. Rows are kept exactly as returned.
PageToTable = (content as record) as table =>
    let
        header = content[columnHeader],
        ids = UniqueNames(List.Transform(header, each _[field])),
        types = List.Transform(header, ColumnType),
        converted = List.Transform(content[data], (r) => List.Transform(List.Positions(header), (i) => ConvertValue(r{i}, types{i}))),
        // Values are already converted: this only declares the column types (Int64, Percentage, Date...).
        untyped = Table.FromRows(converted, ids)
    in
        Table.TransformColumnTypes(untyped, List.Zip({ids, types}));

// All pages. Standard pagination: the next page is requested only after a full page, until
// totalRowCount or maxRows is reached.
// With n periods `limit` applies to each period: a request {start, maxEntries = take} returns up to
// n x take rows (every period lists the same entities), `start` is a per-period offset, and totalRowCount
// counts the rows of all periods (n x the per-period count). So a page is full when got = n x take, the next
// per-period start is start + take, and the per-period total is total / n (compared as nextStart x n < total
// to stay in integers). maxRows caps the rows per period. With n = 1, n x take = take.
// rt#insummary returns all its rows whatever `limit`: the first page is then not "full" (or reaches
// totalRowCount) and pagination stops, without special-casing the kind.
FetchAll = (origin as text, site as text, kind as text, dims as list, mets as list, ranges as list, opts as record) as table =>
    let
        pageSize = Record.FieldOrDefault(opts, "pageSize", 1000),
        maxRows = Record.FieldOrDefault(opts, "maxRows", 100000),
        periods = List.Count(ranges),
        fetch = (start) =>
            let
                take = List.Min({pageSize, maxRows - start}),
                content = CallApi(origin, BatchPath(site, "flat_aggregate"), null, BuildBody(kind, dims, mets, ranges, opts, start, take))[data][content],
                got = List.Count(content[data]),
                total = Record.FieldOrDefault(content, "totalRowCount", null),
                nextStart = start + take
            in
                [content = content, next = nextStart,
                 more = got = periods * take and (total = null or nextStart * periods < total) and nextStart < maxRows],
        pages = List.Generate(
            () => fetch(0),
            (p) => p <> null,
            (p) => if p[more] then fetch(p[next]) else null,
            (p) => PageToTable(p[content]))
    in
        Table.Combine(pages);

RunReport = (origin as text, site as text, kind as text, dimensions as list, metrics as list, dateRanges as list, optional options as nullable record) as table =>
    let
        opts = if options = null then [] else options,
        valid = ValidateReport(kind, dimensions, metrics, dateRanges),
        dims = List.Transform(dimensions, (d) => AsFieldRecord(d, false)),
        mets = List.Transform(metrics, (m) => AsFieldRecord(m, true)),
        ranges = List.Transform(dateRanges, AsDateRange),
        combined = FetchAll(origin, site, kind, dims, mets, ranges, opts),
        // Optional friendly column names (API labels of the first page).
        labelled =
            if Record.FieldOrDefault(opts, "columnNames", "field") = "label" then
                let
                    header = CallApi(origin, BatchPath(site, "flat_aggregate"), null, BuildBody(kind, dims, mets, ranges, opts, 0, 1))[data][content][columnHeader],
                    ids = UniqueNames(List.Transform(header, each _[field])),
                    labels = UniqueNames(List.Transform(header, each _[name]))
                in
                    Table.RenameColumns(combined, List.Zip({ids, labels}), MissingField.Ignore)
            else combined
    in
        if valid then labelled else error "unreachable";

// ---------------------------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------------------------

Table.ToNavigationTable = (
    table as table,
    keyColumns as list,
    nameColumn as text,
    dataColumn as text,
    itemKindColumn as text,
    itemNameColumn as text,
    isLeafColumn as text
) as table =>
    let
        tableType = Value.Type(table),
        newTableType = Type.AddTableKey(tableType, keyColumns, true) meta [
            NavigationTable.NameColumn = nameColumn,
            NavigationTable.DataColumn = dataColumn,
            NavigationTable.ItemKindColumn = itemKindColumn,
            Preview.DelayColumn = itemNameColumn,
            NavigationTable.IsLeafColumn = isLeafColumn
        ],
        navigationTable = Value.ReplaceType(table, newTableType)
    in
        navigationTable;
