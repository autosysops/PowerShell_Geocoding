# Create env variables
$Env:GEOCODING_TELEMETRY_OPTIN = (-not $Evn:POWERSHELL_TELEMETRY_OPTOUT) # use the invert of default powershell telemetry setting

# Set up the telemetry
Initialize-THTelemetry -ModuleName "Geocoding"
Set-THTelemetryConfiguration -ModuleName "Geocoding" -OptInVariableName "GEOCODING_TELEMETRY_OPTIN" -StripPersonallyIdentifiableInformation $true -Confirm:$false
Add-THAppInsightsConnectionString -ModuleName "Geocoding" -ConnectionString "InstrumentationKey=df9757a1-873b-41c6-b4a2-2b93d15c9fb1;IngestionEndpoint=https://westeurope-5.in.applicationinsights.azure.com/;LiveEndpoint=https://westeurope.livediagnostics.monitor.azure.com/"

# Create a message about the telemetry
Write-Information ("Telemetry for Geocoding module is $(if([string] $Env:GEOCODING_TELEMETRY_OPTIN -in ("no","false","0")){"NOT "})enabled. Change the behavior by setting the value of "+ '$Env:GEOCODING_TELEMETRY_OPTIN') -InformationAction Continue

# Resolve module version without requiring a full import to complete.
$moduleVersion = $null

try {
	$moduleManifestCandidates = @(
		(Join-Path $PSScriptRoot "Geocoding.psd1"),
		(Join-Path (Split-Path $PSScriptRoot -Parent) "Geocoding.psd1"),
		(Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "Geocoding.psd1")
	)
	$moduleManifestPath = $moduleManifestCandidates | Where-Object { Test-Path -Path $_ } | Select-Object -First 1

	if ($moduleManifestPath) {
		try {
			$moduleManifest = Import-PowerShellDataFile -Path $moduleManifestPath
			$moduleVersion = [string] $moduleManifest.ModuleVersion
		}
		catch {
			$moduleVersion = $null
		}
	}
}
catch {
	$moduleVersion = $null
}

# Send a metric for the installation of the module
$telemetryProperties = @{
	ModuleVersion = $moduleVersion
}

Send-THEvent -ModuleName "Geocoding" -EventName "Import Module Geocoding" -PropertiesHash $telemetryProperties