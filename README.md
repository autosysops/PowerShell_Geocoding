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
```

**Output fields:** `Distance` (Meters, Kilometers), `Duration` (Seconds, Minutes), `TrafficDelay` (Seconds, Minutes — populated when traffic data is available).

> **Note on `-OsrmServer`:** this parameter only appears when `-Provider OSM` or `-Provider OpenStreetMaps` is explicitly set.
> **Note on `-DepartureTime`/`-ArrivalTime`:** these are mutually exclusive — PowerShell's parameter sets prevent both from being specified at the same time.

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
|API key required|No|Yes|Yes|

---

## Credits

The module is using the [Telemetryhelper module](https://github.com/nyanhp/TelemetryHelper) to gather telemetry.
The module is made using the [PSModuleDevelopment module](https://github.com/PowershellFrameworkCollective/PSModuleDevelopment) to get a template for a module.
