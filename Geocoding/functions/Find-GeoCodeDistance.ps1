function Find-GeoCodeDistance {
    <#
    .SYNOPSIS
        Calculate the route distance and travel time between two coordinates.

    .DESCRIPTION
        Calculates the driving or walking route distance and estimated travel
        time between an origin and a destination using latitude/longitude
        coordinates. Supports Open Street Maps (via OSRM), Google Maps and
        Azure Maps.

        Open Street Maps can be used without an API key. Google Maps and Azure
        Maps require an API key (-Apikey), which only appears as a parameter
        when a paid provider is selected.

        Transit mode is only available for Google Maps; providing it for any
        other provider raises an error. The ValidateSet for -TravelMode always
        shows all three options to keep the parameter discoverable, and the
        provider restriction is enforced at runtime.

        -TrafficAware only appears as a parameter when -Provider Google or
        -Provider Azure is selected, since those are the only providers that
        support live traffic data.

        -OsrmServer only appears when -Provider OSM or -Provider OpenStreetMaps
        is explicitly selected.

        -DepartureTime and -ArrivalTime are mutually exclusive parameter sets.
        Arrival time is only supported by Google Maps.

        Use -Unit to choose between Metric (meters, default) and Imperial (miles).
        Duration is returned as a TimeSpan, giving access to .TotalSeconds,
        .TotalMinutes, .TotalHours, .Hours, .Minutes, .Seconds and so on.
        TrafficDelay is also a TimeSpan when traffic data is available.

    .PARAMETER OriginLatitude
        The latitude of the origin point as a decimal number (e.g. 52.3037).

    .PARAMETER OriginLongitude
        The longitude of the origin point as a decimal number (e.g. 4.7500).

    .PARAMETER DestinationLatitude
        The latitude of the destination point as a decimal number.

    .PARAMETER DestinationLongitude
        The longitude of the destination point as a decimal number.

    .PARAMETER Provider
        The routing service to use. Accepts OpenStreetMaps, OSM, GoogleMaps,
        Google, AzureMaps or Azure. Defaults to OSM. The availability of
        Apikey, OsrmServer and TrafficAware all depend on the selected provider.

    .PARAMETER TravelMode
        The travel mode: Driving (default), Walking or Transit. Transit is only
        valid for Google Maps and raises an error for any other provider.

    .PARAMETER Unit
        Distance unit for the output. Accepts Metric (returns Distance.Meters,
        the default) or Imperial (returns Distance.Miles).

    .PARAMETER DepartureTime
        Optional departure time as a DateTime. Cannot be combined with
        -ArrivalTime. Not supported by Open Street Maps. For Google Maps Driving
        mode, providing a departure time also enables traffic-aware results.

    .PARAMETER ArrivalTime
        Optional desired arrival time as a DateTime. Cannot be combined with
        -DepartureTime. Only supported by Google Maps Transit mode.

    .PARAMETER Apikey
        API key for the selected provider. Only available (and required) when
        -Provider Google, GoogleMaps, Azure or AzureMaps is selected.

    .PARAMETER TrafficAware
        Requests real-time traffic data. Only available when -Provider Google or
        -Provider Azure is selected (this is a dynamic parameter). Only valid
        for Driving mode. For Google Maps this sets the departure time to now if
        no explicit -DepartureTime was provided. Azure Maps always includes live
        traffic for car routing regardless of this switch.

    .PARAMETER OsrmServer
        Base URL of the OSRM server. Only available when -Provider OSM or
        -Provider OpenStreetMaps is explicitly selected. Defaults to the public
        demo server at http://router.project-osrm.org.

    .EXAMPLE
        Calculate driving distance using Open Street Maps (no API key needed)

        PS> Find-GeoCodeDistance -OriginLatitude 52.3037 -OriginLongitude 4.7500 -DestinationLatitude 53.5614 -DestinationLongitude 9.9152

        Distance     : @{Meters=470426}
        Duration     : 05:05:48
        TrafficDelay :

    .EXAMPLE
        Calculate driving distance with live traffic using Google Maps

        PS> Find-GeoCodeDistance -OriginLatitude 52.3037 -OriginLongitude 4.7500 -DestinationLatitude 53.5614 -DestinationLongitude 9.9152 -Provider Google -Apikey "<KEY>" -TrafficAware

    .EXAMPLE
        Calculate distance in miles using Open Street Maps

        PS> Find-GeoCodeDistance -OriginLatitude 52.3037 -OriginLongitude 4.7500 -DestinationLatitude 53.5614 -DestinationLongitude 9.9152 -Unit Imperial

        Distance     : @{Miles=292.28}
        Duration     : 05:05:48
        TrafficDelay :

    .EXAMPLE
        Calculate transit distance using Google Maps with a target arrival time

        PS> Find-GeoCodeDistance -OriginLatitude 52.3037 -OriginLongitude 4.7500 -DestinationLatitude 53.5614 -DestinationLongitude 9.9152 -Provider Google -TravelMode Transit -ArrivalTime (Get-Date).AddHours(3) -Apikey "<KEY>"
    #>

    [CmdLetBinding(DefaultParameterSetName = 'Default')]
    [OutputType([System.Object[]])]

    Param (
        # Base parameters — no ParameterSetName so they work in all parameter sets.
        [Parameter(Mandatory = $true)]
        [Double] $OriginLatitude,

        [Parameter(Mandatory = $true)]
        [Double] $OriginLongitude,

        [Parameter(Mandatory = $true)]
        [Double] $DestinationLatitude,

        [Parameter(Mandatory = $true)]
        [Double] $DestinationLongitude,

        [Parameter(Mandatory = $false)]
        [ValidateSet('OpenStreetMaps', 'OSM', 'GoogleMaps', 'Google', 'AzureMaps', 'Azure')]
        [String] $Provider = 'OSM',

        # TravelMode is a static parameter so that help and tab-completion always
        # work. Transit is validated against the provider in Process{}.
        [Parameter(Mandatory = $false)]
        [ValidateSet('Driving', 'Walking', 'Transit')]
        [String] $TravelMode = 'Driving',

        [Parameter(Mandatory = $false)]
        [ValidateSet('Metric', 'Imperial')]
        [String] $Unit = 'Metric',

        # DepartureTime and ArrivalTime are in separate parameter sets so
        # PowerShell itself prevents both from being specified simultaneously.
        [Parameter(Mandatory = $false, ParameterSetName = 'WithDepartureTime')]
        [DateTime] $DepartureTime,

        [Parameter(Mandatory = $false, ParameterSetName = 'WithArrivalTime')]
        [DateTime] $ArrivalTime
    )

    DynamicParam {
        $dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        # -Apikey: required for Google Maps and Azure Maps.
        if ($Provider -in 'GoogleMaps', 'Google', 'AzureMaps', 'Azure') {
            $akAttr = New-Object System.Management.Automation.ParameterAttribute
            $akAttr.Mandatory = $true
            $akCol  = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $akCol.Add($akAttr)
            $akParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Apikey', [string], $akCol)
            $dictionary.Add('Apikey', $akParam)
        }

        # -TrafficAware: only available for providers that support traffic data.
        if ($Provider -in 'GoogleMaps', 'Google', 'AzureMaps', 'Azure') {
            $taAttr = New-Object System.Management.Automation.ParameterAttribute
            $taAttr.Mandatory = $false
            $taCol  = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $taCol.Add($taAttr)
            $taParam = New-Object System.Management.Automation.RuntimeDefinedParameter('TrafficAware', [switch], $taCol)
            $dictionary.Add('TrafficAware', $taParam)
        }

        # -OsrmServer: only available when OSM provider is explicitly selected.
        if ($Provider -in 'OSM', 'OpenStreetMaps') {
            $osAttr = New-Object System.Management.Automation.ParameterAttribute
            $osAttr.Mandatory = $false
            $osCol  = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $osCol.Add($osAttr)
            $osParam = New-Object System.Management.Automation.RuntimeDefinedParameter('OsrmServer', [string], $osCol)
            $dictionary.Add('OsrmServer', $osParam)
        }

        return $dictionary
    }

    Process {
        # Resolve dynamic-parameter values with their defaults.
        $trafficAware = [bool]$PSBoundParameters['TrafficAware']
        $osrmServer   = if ($PSBoundParameters.ContainsKey('OsrmServer')) { $PSBoundParameters['OsrmServer'] } else { 'http://router.project-osrm.org' }

        # Validate logical constraints.
        if ($TravelMode -eq 'Transit' -and $Provider -notin 'GoogleMaps', 'Google') {
            throw "Transit mode is only supported by Google Maps."
        }
        if ($trafficAware -and $TravelMode -ne 'Driving') {
            throw "TrafficAware is only supported for Driving mode."
        }
        if (($PSBoundParameters.ContainsKey('DepartureTime') -or $PSBoundParameters.ContainsKey('ArrivalTime')) -and $Provider -in 'OpenStreetMaps', 'OSM') {
            throw "DepartureTime and ArrivalTime are not supported by Open Street Maps."
        }
        if ($PSBoundParameters.ContainsKey('ArrivalTime') -and $Provider -notin 'GoogleMaps', 'Google') {
            throw "ArrivalTime is only supported by Google Maps."
        }

        # Invoke the appropriate provider and get the normalised result.
        $result = switch ($Provider) {
            { $_ -in 'OpenStreetMaps', 'OSM' } {
                Write-Debug "[OpenStreetMaps] start distance processing"
                Send-THEvent -ModuleName "Geocoding" -EventName "Find-GeoCodeDistance" -PropertiesHash @{ Provider = "OSM" }

                $splat = @{
                    OriginLatitude       = $OriginLatitude
                    OriginLongitude      = $OriginLongitude
                    DestinationLatitude  = $DestinationLatitude
                    DestinationLongitude = $DestinationLongitude
                    TravelMode           = $TravelMode
                    Server               = $osrmServer
                }
                ConvertFrom-GeoOsrmDistanceOutput -Resource (Find-GeoCodeDistanceOsrm @splat)
            }

            { $_ -in 'GoogleMaps', 'Google' } {
                Write-Debug "[GoogleMaps] start distance processing"
                Send-THEvent -ModuleName "Geocoding" -EventName "Find-GeoCodeDistance" -PropertiesHash @{ Provider = "Google" }

                $splat = @{
                    OriginLatitude       = $OriginLatitude
                    OriginLongitude      = $OriginLongitude
                    DestinationLatitude  = $DestinationLatitude
                    DestinationLongitude = $DestinationLongitude
                    ApiKey               = $PSBoundParameters['Apikey']
                    TravelMode           = $TravelMode
                    TrafficAware         = $trafficAware
                }
                if ($PSBoundParameters.ContainsKey('DepartureTime')) { $splat['DepartureTime'] = $DepartureTime }
                if ($PSBoundParameters.ContainsKey('ArrivalTime'))   { $splat['ArrivalTime']   = $ArrivalTime   }
                ConvertFrom-GeoGoogleMapsDistanceOutput -Resource (Find-GeoCodeDistanceGoogleMaps @splat)
            }

            { $_ -in 'AzureMaps', 'Azure' } {
                Write-Debug "[AzureMaps] start distance processing"
                Send-THEvent -ModuleName "Geocoding" -EventName "Find-GeoCodeDistance" -PropertiesHash @{ Provider = "Azure" }

                $splat = @{
                    OriginLatitude       = $OriginLatitude
                    OriginLongitude      = $OriginLongitude
                    DestinationLatitude  = $DestinationLatitude
                    DestinationLongitude = $DestinationLongitude
                    ApiKey               = $PSBoundParameters['Apikey']
                    TravelMode           = $TravelMode
                }
                if ($PSBoundParameters.ContainsKey('DepartureTime')) { $splat['DepartureTime'] = $DepartureTime }
                if ($PSBoundParameters.ContainsKey('ArrivalTime'))   { $splat['ArrivalTime']   = $ArrivalTime   }
                ConvertFrom-GeoAzureMapsDistanceOutput -Resource (Find-GeoCodeDistanceAzureMaps @splat)
            }
        }

        # Build the output object. TrafficDelay is only included when the provider
        # returned actual traffic data — a null value means no traffic data was
        # available (or requested), so the property is omitted entirely to keep
        # the output clean.
        $distanceObj = if ($Unit -eq 'Imperial') {
            [PSCustomObject]@{ "Miles" = [Math]::Round($result.Distance.Meters / 1609.344, 2) }
        }
        else {
            $result.Distance
        }

        if ($null -ne $result.TrafficDelay) {
            return [PSCustomObject]@{
                "Distance"     = $distanceObj
                "Duration"     = $result.Duration
                "TrafficDelay" = $result.TrafficDelay
            }
        }

        return [PSCustomObject]@{
            "Distance" = $distanceObj
            "Duration" = $result.Duration
        }
    }
}