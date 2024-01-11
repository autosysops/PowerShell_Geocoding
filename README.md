# Geocoding

![example workflow](https://github.com/autosysops/PowerShell_Geocoding/actions/workflows/build.yml/badge.svg)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/Geocoding.svg)](https://www.powershellgallery.com/packages/Geocoding/)

Powershell module to find a geographical location based on a query or coordinates. It supports multiple providers being: Open Street Maps, Bing Maps and Google Maps.

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
Check out the Get-Help for more information on how to use it.

## Credits

The module is using the [Telemetryhelper module](https://github.com/nyanhp/TelemetryHelper) to gather telemetry.
The module is made using the [PSModuleDevelopment module](https://github.com/PowershellFrameworkCollective/PSModuleDevelopment) to get a template for a module.
