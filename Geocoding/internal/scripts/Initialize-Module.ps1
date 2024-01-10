# Create env variables
$Env:GEOCODING_TELEMETRY_OPTIN = (-not $Evn:POWERSHELL_TELEMETRY_OPTOUT) # use the invert of default powershell telemetry setting

# Set up the telemetry
Initialize-THTelemetry -ModuleName "Geocoding"
Set-THTelemetryConfiguration -ModuleName "Geocoding" -OptInVariableName "GEOCODING_TELEMETRY_OPTIN" -StripPersonallyIdentifiableInformation $true -Confirm:$false
Add-THAppInsightsConnectionString -ModuleName "Geocoding" -ConnectionString "InstrumentationKey=df9757a1-873b-41c6-b4a2-2b93d15c9fb1;IngestionEndpoint=https://westeurope-5.in.applicationinsights.azure.com/;LiveEndpoint=https://westeurope.livediagnostics.monitor.azure.com/"

# Create a message about the telemetry
Write-Information ("Telemetry for Geocoding module is $(if([string] $Env:GEOCODING_TELEMETRY_OPTIN -in ("no","false","0")){"NOT "})enabled. Change the behavior by setting the value of "+ '$Env:GEOCODING_TELEMETRY_OPTIN') -InformationAction Continue

# Send a metric for the installation of the module
Send-THEvent -ModuleName "Geocoding" -EventName "Import Module Geocoding"