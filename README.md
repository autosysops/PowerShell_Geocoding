# Geocoding

![example workflow](https://github.com/autosysops/PowerShell_Geocoding/actions/workflows/build.yml/badge.svg)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/Geocoding.svg)](https://www.powershellgallery.com/packages/Geocoding/)

PowerShell module to geocode locations and calculate route distances. It supports Open Street Maps, Azure Maps and Google Maps as providers.
More information about the creation of the module can be found in this [blogpost](https://www.autosysops.com/blog/building-a-new-powershell-module-from-scratch).

## Installation

You can install the module from the [PSGallery](https://www.powershellgallery.com/packages/Geocoding) by using the following command.

```PowerShell
Install-Module -Name Geocoding
```

Or if you are using PowerShell 7.4 or higher you can use

```PowerShell
Install-PSResource -Name Geocoding
```

## Usage

To use the module first import it.

```PowerShell
Import-Module -Name Geocoding
```

You will receive a message about telemetry being enabled. The module exposes two functions: `Find-GeoCodeLocation` and `Find-GeoCodeDistance`.

### Providers and API keys

Open Street Maps can be used without an API key. Google Maps and Azure Maps require an API key, which you can request via their respective portals. The `-Apikey` parameter appears automatically when a paid provider is selected.

|Provider|Require API Key|Requires Credit Card|
|-|-|-|
|Open Street Maps|No|No|
|Google Maps|[Yes](https://developers.google.com/maps/documentation/geocoding/get-api-key)|Yes|
|Azure Maps|[Yes](https://learn.microsoft.com/en-us/azure/azure-maps/azure-maps-authentication#shared-key-authentication)|No|

---

### Find-GeoCodeLocation

Geocode an address or reverse-geocode a coordinate pair.

```PowerShell
# Forward geocoding — address to coordinates (OSM, no key needed)
Find-GeoCodeLocation -Query "Evert van de Beekstraat 354, Schiphol" -Provider OSM -Limit 1

# Forward geocoding — using Google Maps
Find-GeoCodeLocation -Query "Evert van de Beekstraat 354, Schiphol" -Provider Google -Apikey "<KEY>"

# Reverse geocoding — coordinates to address
Find-GeoCodeLocation -Latitude 52.3037 -Longitude 4.7500 -Provider OSM -Limit 1
```

**Output fields:** `Coordinates` (Latitude, Longitude), `Address` (Street Address, Locality, Region, Postal Code, Country), `Boundingbox` (South/North Latitude, West/East Longitude).

**Provider support:**

|Feature|OSM|Google|Azure|
|-|-|-|-|
|Forward geocoding (query)|✓|✓|✓|
|Reverse geocoding (lat/lon)|✓|✓|✓|
|Language selection|✓|✓|–|
|Result limit|✓|–|✓|
|API key required|No|Yes|Yes|

---

### Find-GeoCodeDistance

Calculate the route distance and estimated travel time between two coordinate pairs.

```PowerShell
# Driving distance — OSM (no key needed)
Find-GeoCodeDistance -OriginLatitude 52.3037 -OriginLongitude 4.7500 `
                     -DestinationLatitude 53.5614 -DestinationLongitude 9.9152

# Driving distance with live traffic — Google Maps
Find-GeoCodeDistance -OriginLatitude 52.3037 -OriginLongitude 4.7500 `
                     -DestinationLatitude 53.5614 -DestinationLongitude 9.9152 `
                     -Provider Google -Apikey "<KEY>" -TrafficAware

# Driving distance with a departure time — Azure Maps
Find-GeoCodeDistance -OriginLatitude 52.3037 -OriginLongitude 4.7500 `
                     -DestinationLatitude 53.5614 -DestinationLongitude 9.9152 `
                     -Provider Azure -Apikey "<KEY>" -DepartureTime (Get-Date).AddHours(1)

# Public transit — Google Maps
Find-GeoCodeDistance -OriginLatitude 52.3037 -OriginLongitude 4.7500 `
                     -DestinationLatitude 53.5614 -DestinationLongitude 9.9152 `
                     -Provider Google -TravelMode Transit -Apikey "<KEY>"

# Using a self-hosted OSRM instance
Find-GeoCodeDistance -OriginLatitude 52.3037 -OriginLongitude 4.7500 `
                     -DestinationLatitude 53.5614 -DestinationLongitude 9.9152 `
                     -Provider OSM -OsrmServer "http://my-osrm.example.com"

# Straight-line distance (Haversine, no provider/API key needed)
Find-GeoCodeDistance -OriginLatitude 52.3037 -OriginLongitude 4.7500 `
                     -DestinationLatitude 53.5614 -DestinationLongitude 9.9152 `
                     -StraightLineDistance
```

**Output fields:** `Distance` (Meters or Miles), `Duration` (TimeSpan for route-based results), `TrafficDelay` (TimeSpan when traffic data is available).

> **Note on `-OsrmServer`:** this parameter only appears when `-Provider OSM` or `-Provider OpenStreetMaps` is explicitly set.
> **Note on `-DepartureTime`/`-ArrivalTime`:** these are mutually exclusive — PowerShell's parameter sets prevent both from being specified at the same time.
> **Note on `-StraightLineDistance`:** this uses its own parameter set and excludes `-Provider`, `-TravelMode`, `-DepartureTime` and `-ArrivalTime`.

**Provider support:**

|Feature|OSM|Google|Azure|
|-|-|-|-|
|Driving|✓|✓|✓|
|Walking|✓|✓|✓|
|Public transit|–|✓|–|
|Traffic-aware routing|–|✓|✓ (always on)|
|Departure time|–|✓|✓|
|Arrival time|–|✓ (transit only)|✓|
|Custom OSRM server|✓|–|–|
|Straight-line distance|✓ (local calc)|✓ (local calc)|✓ (local calc)|
|API key required|No|Yes|Yes|

---

## Telemetry Privacy

Telemetry never includes location PII such as query text, coordinates, latitude/longitude, or origin/destination values.

The module records feature usage metadata only, for example:

- `Find-GeoCodeDistance`: provider selection, travel mode, `TrafficAware`, `DepartureTime`/`ArrivalTime` usage, and whether `StraightLineDistance` was used.
- `Find-GeoCodeLocation`: provider selection, query vs reverse lookup mode, and whether `Limit` and `Language` were used.

You can disable telemetry by setting `GEOCODING_TELEMETRY_OPTIN` to `false` (or `0`/`no`) before importing the module.

---

## Credits

The module is using the [Telemetryhelper module](https://github.com/nyanhp/TelemetryHelper) to gather telemetry.
The module is made using the [PSModuleDevelopment module](https://github.com/PowershellFrameworkCollective/PSModuleDevelopment) to get a template for a module.
