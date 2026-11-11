// PQTest suite, run on Windows CI against the mock API (mock-server/, token "mock-token"):
//   PQTest.exe run-test -e dist\EulerianMarketingPlatform.mez -q test\pqtest\EulerianMarketingPlatform.query.pq -p
// Returns the table of facts, or raises Tests.Failed listing the failed facts.
let
    Endpoint = "http://127.0.0.1:8787",
    Source = EulerianMarketingPlatform.Contents(Endpoint),
    Site = Source{[Key = "demo-fr"]}[Data],
    Report = Site{[Key = "Report"]}[Data],

    Fact = (name as text, expected as any, actual as any) as record =>
        let
            result = try actual,
            value = if result[HasError] then "ERROR: " & result[Error][Message] else result[Value]
        in
            [Name = name, Passed = (try (value = expected) otherwise false), Expected = expected, Actual = value],

    // Passes when evaluating `expr` raises an error whose message contains `fragment`.
    FactError = (name as text, fragment as text, expr as function) as record =>
        let
            result = try expr(),
            message = if result[HasError] then result[Error][Message] & " " & Text.From(result[Error][Detail]?) else "no error"
        in
            [Name = name, Passed = result[HasError] and Text.Contains(message, fragment), Expected = "error containing: " & fragment, Actual = message],

    TypeOf = (t as table, column as text) as text => Table.Schema(t){[Name = column]}[TypeName],

    channels = Report("rt#insummary", {"media_key_po"}, {"visit", "realscartvalid"}, {"LAST_7_DAYS"}),
    // No path: the API uses the default level of rt#ope (mcWEBSITE[?].mcGLOBALOPE.mcOPE).
    campaigns = Report("rt#ope", {"publisher_name", "ope_name"}, {"click", "realscartvalid_visit"}, {"CURRENT_MONTH"}, [pageSize = 20]),
    // Same report over 2 periods: limit applies to each period, so pages hold up to 2 x 20 rows (4 pages).
    twoPeriods = Report("rt#ope", {"publisher_name", "ope_name"}, {"click", "realscartvalid_visit"}, {"CURRENT_MONTH", "LAST_MONTH"}, [pageSize = 20]),
    twoPeriodsLabelled = Report("rt#insummary", {"media_key_po"}, {"visit"}, {"CURRENT_MONTH", "LAST_MONTH"}, [columnNames = "label"]),
    daily = Report("rt#website", {"date_day", "website_name"}, {"visit"}, {[dateFrom = "2026-11-02", dateTo = "2026-11-08"]}, [dateScale = "D"]),
    segmented = Report("rt#ope", {"ope_name"}, {[field = "realscartvalidamount", name = "Revenue", segment = [by = "ordertype"]]}, {"CURRENT_MONTH"},
        [path = "mcWEBSITE[?].mcGLOBALOPE.mcOPE"]),
    labelled = Report("rt#insummary", {[field = "media_key_po", name = "Channel"]}, {[field = "visit", name = "Visits"]}, {"LAST_7_DAYS"}, [columnNames = "label"]),

    facts = {
        Fact("sites are listed", {"demo-fr", "demo-en"}, Source[Key]),
        Fact("kinds are rt# only", true, List.AllTrue(List.Transform(Site{[Key = "Kinds"]}[Data][kind], each Text.StartsWith(_, "rt#")))),
        Fact("metrics catalog", true, List.Contains(Site{[Key = "rt#insummary"]}[Data]{[Key = "Metrics"]}[Data][field], "visit")),
        Fact("dimensions of the default level (rt#insummary)", true, List.Contains(Site{[Key = "rt#insummary"]}[Data]{[Key = "Dimensions"]}[Data][field], "media_key_po")),
        Fact("dimensions of the default level (rt#website)", true, List.Contains(Site{[Key = "rt#website"]}[Data]{[Key = "Dimensions"]}[Data][field], "website_name")),
        Fact("dimensions of an explicit level", true, List.Contains(Site{[Key = "rt#website"]}[Data]{[Key = "DimensionsOfLevel"]}[Data]("mcWEBSITE[?].mcGLOBALOPE.mcOPE")[field], "ope_name")),

        Fact("channels: rows as returned (global included)", 10, Table.RowCount(channels)),
        Fact("channels: global row present", true, List.Contains(channels[media_key_po], "global")),
        Fact("channels: columns are API fields", {"media_key_po", "visit", "realscartvalid"}, Table.ColumnNames(channels)),
        Fact("channels: visit is Int64", "Int64.Type", TypeOf(channels, "visit")),

        Fact("rt#ope report without path works", {"publisher_name", "ope_name", "click", "realscartvalid_visit"}, Table.ColumnNames(campaigns)),
        Fact("campaigns: 77 rows over 4 pages of 20", 77, Table.RowCount(campaigns)),
        Fact("campaigns: no duplicate campaign", 77, List.Count(List.Distinct(campaigns[ope_name]))),
        Fact("campaigns: ratio typed as percentage", "Percentage.Type", TypeOf(campaigns, "realscartvalid_visit")),

        Fact("daily: one row per day", 7, Table.RowCount(daily)),
        Fact("daily: date_day typed as date", "Date.Type", TypeOf(daily, "date_day")),
        Fact("daily: first day", #date(2026, 11, 2), List.Min(daily[date_day])),

        Fact("segmented: both columns sharing a field id are kept", true, List.ContainsAll(Table.ColumnNames(segmented), {"realscartvalidamount_ordertype_0", "realscartvalidamount_ordertype_0__2"})),
        Fact("labels: columnNames=label", {"Channel", "Visits"}, Table.ColumnNames(labelled)),

        Fact("2 periods: Period column (date_range) added first", "date_range", List.First(Table.ColumnNames(twoPeriods))),
        Fact("2 periods: Period values 0 and 1", {0, 1}, List.Sort(List.Distinct(twoPeriods[date_range]))),
        Fact("2 periods: date_range is Int64", "Int64.Type", TypeOf(twoPeriods, "date_range")),
        Fact("2 periods: twice the single-period rows (2 x 77) over pages of 2 x 20", 154, Table.RowCount(twoPeriods)),
        Fact("2 periods: columnNames=label shows Period", "Period", List.First(Table.ColumnNames(twoPeriodsLabelled))),
        FactError("10 periods rejected", "1 to 9 periods", () => Report("rt#insummary", {"media_key_po"}, {"visit"}, List.Repeat({"TODAY"}, 10))),
        FactError("same metric plain and segmented rejected", "requested both plain and segmented: request it in two separate reports",
            () => Report("rt#ope", {"ope_name"}, {"realscartvalidamount", [field = "realscartvalidamount", segment = [by = "ordertype"]]}, {"CURRENT_MONTH"})),
        FactError("kind must start with rt#", "kind must start with rt#", () => Report("cj#bias-simple", {"x"}, {"y"}, {"TODAY"})),
        FactError("unknown field: API message surfaced", "not_a_field", () => Report("rt#insummary", {"not_a_field"}, {"visit"}, {"TODAY"}))
    },
    results = Table.FromRecords(facts),
    failed = Table.SelectRows(results, each not [Passed]),
    output = if Table.IsEmpty(failed) then results
        else error Error.Record("Tests.Failed", Text.Combine(List.Transform(Table.ToRecords(failed), each [Name] & " (expected " & Text.From([Expected]) & ", got " & Text.From([Actual]) & ")"), "; "))
in
    output
