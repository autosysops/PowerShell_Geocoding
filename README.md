# Geocoding

![example workflow](https://github.com/autosysops/PowerShell_Geocoding/actions/workflows/build.yml/badge.svg)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/Geocoding.svg)](https://www.powershellgallery.com/packages/Geocoding/)

Powershell module to find a geographical location based on a query or coordinates. It supports multiple providers being: Open Street Maps, Bing Maps and Google Maps.
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

You will receive a message about telemetry being enabled. After that you can use the command `Find-GeoCodeLocation` to use the module.

By default the module will use Open Street Maps as this doesn't require a API key. You can use the module with other provider too, but you do need to request the API key to be able to use it.

|Provider|Require API Key|Requires Credit Card validation|
|-|-|-|
|Open Street Maps|No|No|
|Google Maps|[Yes](https://developers.google.com/maps/documentation/geocoding/get-api-key)|Yes|
|Bing Maps|[Yes](https://learn.microsoft.com/en-us/bingmaps/getting-started/bing-maps-dev-center-help/getting-a-bing-maps-key)|No|
|Azure Maps|[Yes](https://learn.microsoft.com/en-us/azure/azure-maps/azure-maps-authentication#shared-key-authentication)|No|

Check out the Get-Help for more information on how to use the function.

## Credits

The module is using the [Telemetryhelper module](https://github.com/nyanhp/TelemetryHelper) to gather telemetry.
The module is made using the [PSModuleDevelopment module](https://github.com/PowershellFrameworkCollective/PSModuleDevelopment) to get a template for a module.
