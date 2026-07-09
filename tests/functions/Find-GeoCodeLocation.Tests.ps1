# Load API keys from env.local when running locally.
# This runs at script scope (before any Pester blocks) so $env: variables are
# set before both BeforeDiscovery and BeforeAll execute.
# On GitHub Actions the same variable names are injected directly as env vars,
# so this block is a no-op there.
$_envLocalCandidates = @(
    (Join-Path $PSScriptRoot "..\..\env.local"),
    (Join-Path ($global:testroot) "..\env.local")
)
foreach ($_candidate in $_envLocalCandidates) {
    if (Test-Path $_candidate) {
        # Use [scriptblock]::Create to avoid the Windows file-association dialog
        # that .local triggers when dot-sourced directly.
        . ([scriptblock]::Create((Get-Content $_candidate -Raw)))
        break
    }
}

BeforeDiscovery {
    $googleKeyAvailable = -not [string]::IsNullOrEmpty($env:GOOGLE_MAPS_KEY)
    $azureKeyAvailable  = -not [string]::IsNullOrEmpty($env:AZURE_MAPS_KEY)
}

Describe "Find-GeoCodeLocation - Microsoft Netherlands (Schiphol)" {

    BeforeAll {
        $script:GoogleMapsKey = $env:GOOGLE_MAPS_KEY
        $script:AzureMapsKey  = $env:AZURE_MAPS_KEY

        $script:Query = "Evert van de Beekstraat 354, 1118 CZ Schiphol, Netherlands"

        # Each provider call is wrapped individually so a single bad key cannot
        # crash BeforeAll and silently fail every test in the block.
        # Errors are stored per-provider and re-thrown inside the It blocks so
        # Pester reports a meaningful message.
        $script:OsmError    = $null
        $script:GoogleError = $null
        $script:AzureError  = $null

        try {
            $script:OsmResult = Find-GeoCodeLocation -Query $script:Query -Provider OSM -Limit 1
        } catch {
            $script:OsmError = $_.ToString()
        }

        if (-not [string]::IsNullOrEmpty($script:GoogleMapsKey)) {
            try {
                $script:GoogleResult = Find-GeoCodeLocation -Query $script:Query -Provider Google -Apikey $script:GoogleMapsKey -Limit 1
            } catch {
                $script:GoogleError = $_.ToString()
            }
        }

        if (-not [string]::IsNullOrEmpty($script:AzureMapsKey)) {
            try {
                $script:AzureResult = Find-GeoCodeLocation -Query $script:Query -Provider Azure -Apikey $script:AzureMapsKey -Limit 1
            } catch {
                $script:AzureError = $_.ToString()
            }
        }
    }

    # -------------------------------------------------------------------------
    # OpenStreetMaps — no API key required
    # -------------------------------------------------------------------------
    Context "OpenStreetMaps (OSM) - No API key required" {

        It "Returns a result" {
            if ($script:OsmError) { throw "OSM geocoding failed: $($script:OsmError)" }
            $script:OsmResult | Should -Not -BeNullOrEmpty
        }

        It "Returns coordinates in the Schiphol area" {
            if ($script:OsmError) { throw "OSM geocoding failed: $($script:OsmError)" }
            [double]$lat = $script:OsmResult.Coordinates.Latitude
            [double]$lon = $script:OsmResult.Coordinates.Longitude
            $lat | Should -BeGreaterOrEqual 52.2 -Because "Schiphol latitude should be ~52.3"
            $lat | Should -BeLessOrEqual    52.4 -Because "Schiphol latitude should be ~52.3"
            $lon | Should -BeGreaterOrEqual 4.6  -Because "Schiphol longitude should be ~4.75"
            $lon | Should -BeLessOrEqual    4.9  -Because "Schiphol longitude should be ~4.75"
        }

        It "Returns 'Netherlands' as the country" {
            if ($script:OsmError) { throw "OSM geocoding failed: $($script:OsmError)" }
            $script:OsmResult.Address.Country | Should -BeLike "*Netherlands*" -Because "the address is in the Netherlands"
        }

        It "Returns a postal code in the 1118 area" {
            if ($script:OsmError) { throw "OSM geocoding failed: $($script:OsmError)" }
            $script:OsmResult.Address.'Postal Code' | Should -BeLike "1118*" -Because "Schiphol postal code starts with 1118"
        }

        It "Returns a valid bounding box" {
            if ($script:OsmError) { throw "OSM geocoding failed: $($script:OsmError)" }
            $script:OsmResult.Boundingbox.'South Latitude' | Should -Not -BeNullOrEmpty -Because "a bounding box must have all four sides"
            $script:OsmResult.Boundingbox.'North Latitude' | Should -Not -BeNullOrEmpty -Because "a bounding box must have all four sides"
            $script:OsmResult.Boundingbox.'West Longitude' | Should -Not -BeNullOrEmpty -Because "a bounding box must have all four sides"
            $script:OsmResult.Boundingbox.'East Longitude' | Should -Not -BeNullOrEmpty -Because "a bounding box must have all four sides"
        }
    }

    # -------------------------------------------------------------------------
    # Google Maps
    # -------------------------------------------------------------------------
    Context "Google Maps" {

        It "Returns a result" -Skip:(-not $googleKeyAvailable) {
            if ($script:GoogleError) { throw "Google Maps API call failed: $($script:GoogleError)" }
            $script:GoogleResult | Should -Not -BeNullOrEmpty
        }

        It "Returns coordinates in the Schiphol area" -Skip:(-not $googleKeyAvailable) {
            if ($script:GoogleError) { throw "Google Maps API call failed: $($script:GoogleError)" }
            [double]$lat = $script:GoogleResult.Coordinates.Latitude
            [double]$lon = $script:GoogleResult.Coordinates.Longitude
            $lat | Should -BeGreaterOrEqual 52.2 -Because "Schiphol latitude should be ~52.3"
            $lat | Should -BeLessOrEqual    52.4 -Because "Schiphol latitude should be ~52.3"
            $lon | Should -BeGreaterOrEqual 4.6  -Because "Schiphol longitude should be ~4.75"
            $lon | Should -BeLessOrEqual    4.9  -Because "Schiphol longitude should be ~4.75"
        }

        It "Returns 'Netherlands' as the country" -Skip:(-not $googleKeyAvailable) {
            if ($script:GoogleError) { throw "Google Maps API call failed: $($script:GoogleError)" }
            $script:GoogleResult.Address.Country | Should -BeLike "*Netherlands*" -Because "the address is in the Netherlands"
        }

        It "Returns a postal code in the 1118 area" -Skip:(-not $googleKeyAvailable) {
            if ($script:GoogleError) { throw "Google Maps API call failed: $($script:GoogleError)" }
            $script:GoogleResult.Address.'Postal Code' | Should -BeLike "1118*" -Because "Schiphol postal code starts with 1118"
        }

        It "Returns a valid bounding box" -Skip:(-not $googleKeyAvailable) {
            if ($script:GoogleError) { throw "Google Maps API call failed: $($script:GoogleError)" }
            $script:GoogleResult.Boundingbox.'South Latitude' | Should -Not -BeNullOrEmpty -Because "a bounding box must have all four sides"
            $script:GoogleResult.Boundingbox.'North Latitude' | Should -Not -BeNullOrEmpty -Because "a bounding box must have all four sides"
            $script:GoogleResult.Boundingbox.'West Longitude' | Should -Not -BeNullOrEmpty -Because "a bounding box must have all four sides"
            $script:GoogleResult.Boundingbox.'East Longitude' | Should -Not -BeNullOrEmpty -Because "a bounding box must have all four sides"
        }
    }

    # -------------------------------------------------------------------------
    # Azure Maps
    # Note: Azure Maps returns the country name localised to the result country
    # (e.g. "Nederland" instead of "Netherlands"), so the assertion accepts both.
    # -------------------------------------------------------------------------
    Context "Azure Maps" {

        It "Returns a result" -Skip:(-not $azureKeyAvailable) {
            if ($script:AzureError) { throw "Azure Maps API call failed: $($script:AzureError)" }
            $script:AzureResult | Should -Not -BeNullOrEmpty
        }

        It "Returns coordinates in the Schiphol area" -Skip:(-not $azureKeyAvailable) {
            if ($script:AzureError) { throw "Azure Maps API call failed: $($script:AzureError)" }
            [double]$lat = $script:AzureResult.Coordinates.Latitude
            [double]$lon = $script:AzureResult.Coordinates.Longitude
            $lat | Should -BeGreaterOrEqual 52.2 -Because "Schiphol latitude should be ~52.3"
            $lat | Should -BeLessOrEqual    52.4 -Because "Schiphol latitude should be ~52.3"
            $lon | Should -BeGreaterOrEqual 4.6  -Because "Schiphol longitude should be ~4.75"
            $lon | Should -BeLessOrEqual    4.9  -Because "Schiphol longitude should be ~4.75"
        }

        It "Returns 'Netherlands' (or 'Nederland') as the country" -Skip:(-not $azureKeyAvailable) {
            if ($script:AzureError) { throw "Azure Maps API call failed: $($script:AzureError)" }
            $script:AzureResult.Address.Country | Should -Match "Netherlands|Nederland" -Because "Azure Maps may return the localised Dutch name 'Nederland'"
        }

        It "Returns a postal code in the 1118 area" -Skip:(-not $azureKeyAvailable) {
            if ($script:AzureError) { throw "Azure Maps API call failed: $($script:AzureError)" }
            $script:AzureResult.Address.'Postal Code' | Should -BeLike "1118*" -Because "Schiphol postal code starts with 1118"
        }

        It "Returns a valid bounding box" -Skip:(-not $azureKeyAvailable) {
            if ($script:AzureError) { throw "Azure Maps API call failed: $($script:AzureError)" }
            $script:AzureResult.Boundingbox.'South Latitude' | Should -Not -BeNullOrEmpty -Because "a bounding box must have all four sides"
            $script:AzureResult.Boundingbox.'North Latitude' | Should -Not -BeNullOrEmpty -Because "a bounding box must have all four sides"
            $script:AzureResult.Boundingbox.'West Longitude' | Should -Not -BeNullOrEmpty -Because "a bounding box must have all four sides"
            $script:AzureResult.Boundingbox.'East Longitude' | Should -Not -BeNullOrEmpty -Because "a bounding box must have all four sides"
        }
    }
}