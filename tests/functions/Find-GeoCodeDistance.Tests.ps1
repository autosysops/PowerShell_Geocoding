# Load API keys from env.local when running locally.
$_envLocalCandidates = @(
    (Join-Path $PSScriptRoot "..\..\env.local"),
    (Join-Path ($global:testroot) "..\env.local")
)
foreach ($_candidate in $_envLocalCandidates) {
    if (Test-Path $_candidate) {
        . ([scriptblock]::Create((Get-Content $_candidate -Raw)))
        break
    }
}

BeforeDiscovery {
    $googleKeyAvailable = -not [string]::IsNullOrEmpty($env:GOOGLE_MAPS_KEY)
    $azureKeyAvailable  = -not [string]::IsNullOrEmpty($env:AZURE_MAPS_KEY)
}

Describe "Find-GeoCodeDistance - Microsoft Schiphol to Microsoft Hamburg" {

    BeforeAll {
        $script:GoogleMapsKey = $env:GOOGLE_MAPS_KEY
        $script:AzureMapsKey  = $env:AZURE_MAPS_KEY

        # Microsoft Netherlands (Schiphol)
        $script:OriginLat = 52.3037309
        $script:OriginLon = 4.7500218

        # Microsoft Deutschland (Hamburg, Gasstrasse 6A)
        $script:DestLat = 53.5614357
        $script:DestLon = 9.9152147

        # Expected driving distance range (metres)
        $script:MinDistanceM = 440000
        $script:MaxDistanceM = 520000

        # ── OSM ───────────────────────────────────────────────────────────────
        $script:OsmDrivingError = $null
        $script:OsmWalkingError = $null
        try {
            $script:OsmDrivingResult = Find-GeoCodeDistance -OriginLatitude $script:OriginLat -OriginLongitude $script:OriginLon -DestinationLatitude $script:DestLat -DestinationLongitude $script:DestLon -Provider OSM
        } catch { $script:OsmDrivingError = $_.ToString() }

        try {
            $script:OsmWalkingResult = Find-GeoCodeDistance -OriginLatitude $script:OriginLat -OriginLongitude $script:OriginLon -DestinationLatitude $script:DestLat -DestinationLongitude $script:DestLon -Provider OSM -TravelMode Walking
        } catch { $script:OsmWalkingError = $_.ToString() }

        $script:OsmImperialError = $null
        try {
            $script:OsmImperialResult = Find-GeoCodeDistance -OriginLatitude $script:OriginLat -OriginLongitude $script:OriginLon -DestinationLatitude $script:DestLat -DestinationLongitude $script:DestLon -Provider OSM -Unit Imperial
        } catch { $script:OsmImperialError = $_.ToString() }

        # ── Google ─────────────────────────────────────────────────────────────
        $script:GoogleDrivingError = $null
        $script:GoogleTrafficError = $null
        $script:GoogleTransitError = $null
        if (-not [string]::IsNullOrEmpty($script:GoogleMapsKey)) {
            try {
                $script:GoogleDrivingResult = Find-GeoCodeDistance -OriginLatitude $script:OriginLat -OriginLongitude $script:OriginLon -DestinationLatitude $script:DestLat -DestinationLongitude $script:DestLon -Provider Google -Apikey $script:GoogleMapsKey
            } catch { $script:GoogleDrivingError = $_.ToString() }

            try {
                $script:GoogleTrafficResult = Find-GeoCodeDistance -OriginLatitude $script:OriginLat -OriginLongitude $script:OriginLon -DestinationLatitude $script:DestLat -DestinationLongitude $script:DestLon -Provider Google -Apikey $script:GoogleMapsKey -TrafficAware
            } catch { $script:GoogleTrafficError = $_.ToString() }

            try {
                $script:GoogleTransitResult = Find-GeoCodeDistance -OriginLatitude $script:OriginLat -OriginLongitude $script:OriginLon -DestinationLatitude $script:DestLat -DestinationLongitude $script:DestLon -Provider Google -Apikey $script:GoogleMapsKey -TravelMode Transit
            } catch { $script:GoogleTransitError = $_.ToString() }
        }

        # ── Azure ──────────────────────────────────────────────────────────────
        $script:AzureDrivingError = $null
        $script:AzureWalkingError = $null
        if (-not [string]::IsNullOrEmpty($script:AzureMapsKey)) {
            try {
                $script:AzureDrivingResult = Find-GeoCodeDistance -OriginLatitude $script:OriginLat -OriginLongitude $script:OriginLon -DestinationLatitude $script:DestLat -DestinationLongitude $script:DestLon -Provider Azure -Apikey $script:AzureMapsKey
            } catch { $script:AzureDrivingError = $_.ToString() }

            try {
                $script:AzureWalkingResult = Find-GeoCodeDistance -OriginLatitude $script:OriginLat -OriginLongitude $script:OriginLon -DestinationLatitude $script:DestLat -DestinationLongitude $script:DestLon -Provider Azure -Apikey $script:AzureMapsKey -TravelMode Walking
            } catch { $script:AzureWalkingError = $_.ToString() }
        }
    }

    # ─────────────────────────────────────────────────────────────────────────
    # Parameter validation
    # ─────────────────────────────────────────────────────────────────────────
    Context "Parameter validation" {

        It "Throws when DepartureTime and ArrivalTime are both set" {
            # Parameter sets prevent both from being specified simultaneously.
            { Find-GeoCodeDistance -OriginLatitude 52.30 -OriginLongitude 4.75 -DestinationLatitude 53.56 -DestinationLongitude 9.92 -DepartureTime (Get-Date) -ArrivalTime (Get-Date).AddHours(1) } |
                Should -Throw -Because "only one time constraint is allowed"
        }

        It "Does not accept Transit as TravelMode for OSM" {
            # ValidateSet on TravelMode excludes Transit for OSM.
            { Find-GeoCodeDistance -OriginLatitude 52.30 -OriginLongitude 4.75 -DestinationLatitude 53.56 -DestinationLongitude 9.92 -Provider OSM -TravelMode Transit } |
                Should -Throw -Because "OSM does not support transit routing"
        }

        It "Does not expose TrafficAware parameter for OSM" {
            # TrafficAware is a dynamic param that only exists for Google/Azure.
            { Find-GeoCodeDistance -OriginLatitude 52.30 -OriginLongitude 4.75 -DestinationLatitude 53.56 -DestinationLongitude 9.92 -Provider OSM -TrafficAware } |
                Should -Throw -Because "OSM does not support traffic-aware routing"
        }

        It "Throws when TrafficAware is used with Walking mode" -Skip:(-not $googleKeyAvailable) {
            { Find-GeoCodeDistance -OriginLatitude 52.30 -OriginLongitude 4.75 -DestinationLatitude 53.56 -DestinationLongitude 9.92 -Provider Google -Apikey $script:GoogleMapsKey -TravelMode Walking -TrafficAware } |
                Should -Throw "*TrafficAware is only supported for Driving mode*" -Because "traffic data is irrelevant for walking"
        }

        It "Throws when ArrivalTime is used with OSM" {
            { Find-GeoCodeDistance -OriginLatitude 52.30 -OriginLongitude 4.75 -DestinationLatitude 53.56 -DestinationLongitude 9.92 -Provider OSM -ArrivalTime (Get-Date).AddHours(2) } |
                Should -Throw "*DepartureTime and ArrivalTime are not supported by Open Street Maps*" -Because "OSRM is a static routing service"
        }
    }

    # ─────────────────────────────────────────────────────────────────────────
    # OSM — no API key required
    # ─────────────────────────────────────────────────────────────────────────
    Context "OSM - Driving (Metric)" {

        It "Returns a result" {
            if ($script:OsmDrivingError) { throw "OSM driving failed: $($script:OsmDrivingError)" }
            $script:OsmDrivingResult | Should -Not -BeNullOrEmpty
        }

        It "Returns Distance.Meters in the expected range" {
            if ($script:OsmDrivingError) { throw "OSM driving failed: $($script:OsmDrivingError)" }
            $script:OsmDrivingResult.Distance.Meters | Should -BeGreaterOrEqual $script:MinDistanceM -Because "Schiphol to Hamburg is ~470 km"
            $script:OsmDrivingResult.Distance.Meters | Should -BeLessOrEqual    $script:MaxDistanceM -Because "Schiphol to Hamburg is ~470 km"
        }

        It "Does not return Distance.Miles for Metric unit" {
            if ($script:OsmDrivingError) { throw "OSM driving failed: $($script:OsmDrivingError)" }
            $script:OsmDrivingResult.Distance.Miles | Should -BeNullOrEmpty -Because "Metric mode returns Meters, not Miles"
        }

        It "Returns Duration as a TimeSpan" {
            if ($script:OsmDrivingError) { throw "OSM driving failed: $($script:OsmDrivingError)" }
            $script:OsmDrivingResult.Duration | Should -BeOfType [TimeSpan] -Because "Duration should be a TimeSpan for easy time arithmetic"
        }

        It "Returns a positive total duration" {
            if ($script:OsmDrivingError) { throw "OSM driving failed: $($script:OsmDrivingError)" }
            $script:OsmDrivingResult.Duration.TotalSeconds | Should -BeGreaterThan 0 -Because "any route takes time"
        }

        It "Returns no traffic delay" {
            if ($script:OsmDrivingError) { throw "OSM driving failed: $($script:OsmDrivingError)" }
            $script:OsmDrivingResult.TrafficDelay | Should -BeNullOrEmpty -Because "OSRM does not provide traffic data"
        }
    }

    Context "OSM - Driving (Imperial)" {

        It "Returns Distance.Miles instead of Meters" {
            if ($script:OsmImperialError) { throw "OSM imperial failed: $($script:OsmImperialError)" }
            $script:OsmImperialResult.Distance.Miles | Should -BeGreaterThan 0 -Because "Imperial mode returns Miles"
            $script:OsmImperialResult.Distance.Meters | Should -BeNullOrEmpty -Because "Imperial mode should not include Meters"
        }

        It "Returns a plausible mileage (270-325 miles)" {
            if ($script:OsmImperialError) { throw "OSM imperial failed: $($script:OsmImperialError)" }
            $script:OsmImperialResult.Distance.Miles | Should -BeGreaterOrEqual 270 -Because "Schiphol to Hamburg is ~292 miles"
            $script:OsmImperialResult.Distance.Miles | Should -BeLessOrEqual    325 -Because "Schiphol to Hamburg is ~292 miles"
        }

        It "Returns Duration as a TimeSpan for Imperial too" {
            if ($script:OsmImperialError) { throw "OSM imperial failed: $($script:OsmImperialError)" }
            $script:OsmImperialResult.Duration | Should -BeOfType [TimeSpan]
        }
    }

    Context "OSM - Walking" {

        It "Returns a result" {
            if ($script:OsmWalkingError) { throw "OSM walking failed: $($script:OsmWalkingError)" }
            $script:OsmWalkingResult | Should -Not -BeNullOrEmpty
        }

        It "Returns a positive distance" {
            if ($script:OsmWalkingError) { throw "OSM walking failed: $($script:OsmWalkingError)" }
            $script:OsmWalkingResult.Distance.Meters | Should -BeGreaterThan 0 -Because "any route has a non-zero distance"
        }

        It "Returns no traffic delay" {
            if ($script:OsmWalkingError) { throw "OSM walking failed: $($script:OsmWalkingError)" }
            $script:OsmWalkingResult.TrafficDelay | Should -BeNullOrEmpty -Because "OSRM does not provide traffic data"
        }
    }

    # ─────────────────────────────────────────────────────────────────────────
    # Google Maps
    # ─────────────────────────────────────────────────────────────────────────
    Context "Google Maps - Driving" {

        It "Returns a result" -Skip:(-not $googleKeyAvailable) {
            if ($script:GoogleDrivingError) { throw "Google driving failed: $($script:GoogleDrivingError)" }
            $script:GoogleDrivingResult | Should -Not -BeNullOrEmpty
        }

        It "Returns Distance.Meters in the expected range" -Skip:(-not $googleKeyAvailable) {
            if ($script:GoogleDrivingError) { throw "Google driving failed: $($script:GoogleDrivingError)" }
            $script:GoogleDrivingResult.Distance.Meters | Should -BeGreaterOrEqual $script:MinDistanceM -Because "Schiphol to Hamburg is ~470 km"
            $script:GoogleDrivingResult.Distance.Meters | Should -BeLessOrEqual    $script:MaxDistanceM -Because "Schiphol to Hamburg is ~470 km"
        }

        It "Returns Duration as a TimeSpan" -Skip:(-not $googleKeyAvailable) {
            if ($script:GoogleDrivingError) { throw "Google driving failed: $($script:GoogleDrivingError)" }
            $script:GoogleDrivingResult.Duration | Should -BeOfType [TimeSpan]
        }

        It "Returns no traffic delay when TrafficAware is not set" -Skip:(-not $googleKeyAvailable) {
            if ($script:GoogleDrivingError) { throw "Google driving failed: $($script:GoogleDrivingError)" }
            $script:GoogleDrivingResult.TrafficDelay | Should -BeNullOrEmpty -Because "traffic data requires TrafficAware or DepartureTime"
        }
    }

    Context "Google Maps - Driving with TrafficAware" {

        It "Returns a result" -Skip:(-not $googleKeyAvailable) {
            if ($script:GoogleTrafficError) { throw "Google traffic failed: $($script:GoogleTrafficError)" }
            $script:GoogleTrafficResult | Should -Not -BeNullOrEmpty
        }

        It "Returns TrafficDelay as a TimeSpan" -Skip:(-not $googleKeyAvailable) {
            if ($script:GoogleTrafficError) { throw "Google traffic failed: $($script:GoogleTrafficError)" }
            $script:GoogleTrafficResult.TrafficDelay | Should -BeOfType [TimeSpan] -Because "TrafficAware should populate a TimeSpan TrafficDelay"
        }

        It "Returns Distance.Meters in the expected range" -Skip:(-not $googleKeyAvailable) {
            if ($script:GoogleTrafficError) { throw "Google traffic failed: $($script:GoogleTrafficError)" }
            $script:GoogleTrafficResult.Distance.Meters | Should -BeGreaterOrEqual $script:MinDistanceM -Because "Schiphol to Hamburg is ~470 km"
            $script:GoogleTrafficResult.Distance.Meters | Should -BeLessOrEqual    $script:MaxDistanceM -Because "Schiphol to Hamburg is ~470 km"
        }
    }

    Context "Google Maps - Transit" {

        It "Returns a result" -Skip:(-not $googleKeyAvailable) {
            if ($script:GoogleTransitError) { throw "Google transit failed: $($script:GoogleTransitError)" }
            $script:GoogleTransitResult | Should -Not -BeNullOrEmpty
        }

        It "Returns a positive distance" -Skip:(-not $googleKeyAvailable) {
            if ($script:GoogleTransitError) { throw "Google transit failed: $($script:GoogleTransitError)" }
            $script:GoogleTransitResult.Distance.Meters | Should -BeGreaterThan 0 -Because "any transit route has a non-zero distance"
        }

        It "Returns Duration as a TimeSpan" -Skip:(-not $googleKeyAvailable) {
            if ($script:GoogleTransitError) { throw "Google transit failed: $($script:GoogleTransitError)" }
            $script:GoogleTransitResult.Duration | Should -BeOfType [TimeSpan]
        }
    }

    # ─────────────────────────────────────────────────────────────────────────
    # Azure Maps
    # ─────────────────────────────────────────────────────────────────────────
    Context "Azure Maps - Driving" {

        It "Returns a result" -Skip:(-not $azureKeyAvailable) {
            if ($script:AzureDrivingError) { throw "Azure driving failed: $($script:AzureDrivingError)" }
            $script:AzureDrivingResult | Should -Not -BeNullOrEmpty
        }

        It "Returns Distance.Meters in the expected range" -Skip:(-not $azureKeyAvailable) {
            if ($script:AzureDrivingError) { throw "Azure driving failed: $($script:AzureDrivingError)" }
            $script:AzureDrivingResult.Distance.Meters | Should -BeGreaterOrEqual $script:MinDistanceM -Because "Schiphol to Hamburg is ~470 km"
            $script:AzureDrivingResult.Distance.Meters | Should -BeLessOrEqual    $script:MaxDistanceM -Because "Schiphol to Hamburg is ~470 km"
        }

        It "Returns Duration as a TimeSpan" -Skip:(-not $azureKeyAvailable) {
            if ($script:AzureDrivingError) { throw "Azure driving failed: $($script:AzureDrivingError)" }
            $script:AzureDrivingResult.Duration | Should -BeOfType [TimeSpan] -Because "Duration should be a TimeSpan"
            $script:AzureDrivingResult.Duration.TotalSeconds | Should -BeGreaterThan 0 -Because "any route takes time"
        }
    }

    Context "Azure Maps - Walking" {

        It "Returns a result" -Skip:(-not $azureKeyAvailable) {
            if ($script:AzureWalkingError) { throw "Azure walking failed: $($script:AzureWalkingError)" }
            $script:AzureWalkingResult | Should -Not -BeNullOrEmpty
        }

        It "Returns a positive distance" -Skip:(-not $azureKeyAvailable) {
            if ($script:AzureWalkingError) { throw "Azure walking failed: $($script:AzureWalkingError)" }
            $script:AzureWalkingResult.Distance.Meters | Should -BeGreaterThan 0 -Because "any route has a non-zero distance"
        }
    }
}