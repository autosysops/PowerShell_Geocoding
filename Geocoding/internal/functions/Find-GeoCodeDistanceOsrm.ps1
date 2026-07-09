function Find-GeoCodeDistanceOsrm {
    <#
    .SYNOPSIS
        Calculate the route distance between two coordinates using OSRM.

    .DESCRIPTION
        Uses the Open Source Routing Machine (OSRM) HTTP API to retrieve route
        distance and duration between an origin and a destination.

    .PARAMETER OriginLatitude
        The latitude of the origin point.

    .PARAMETER OriginLongitude
        The longitude of the origin point.

    .PARAMETER DestinationLatitude
        The latitude of the destination point.

    .PARAMETER DestinationLongitude
        The longitude of the destination point.

    .PARAMETER TravelMode
        The travel mode. Accepts Driving or Walking. Defaults to Driving.

    .PARAMETER Server
        The base URL of the OSRM server. Defaults to the public demo server
        at http://router.project-osrm.org.

    .EXAMPLE
        Calculate driving distance

        PS> Find-GeoCodeDistanceOsrm -OriginLatitude 52.30 -OriginLongitude 4.75 -DestinationLatitude 53.56 -DestinationLongitude 9.92
    #>

    [CmdLetBinding()]
    [OutputType([Object])]

    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [Double] $OriginLatitude,

        [Parameter(Mandatory = $true, Position = 2)]
        [Double] $OriginLongitude,

        [Parameter(Mandatory = $true, Position = 3)]
        [Double] $DestinationLatitude,

        [Parameter(Mandatory = $true, Position = 4)]
        [Double] $DestinationLongitude,

        [Parameter(Mandatory = $false, Position = 5)]
        [ValidateSet('Driving', 'Walking')]
        [String] $TravelMode = 'Driving',

        [Parameter(Mandatory = $false, Position = 6)]
        [String] $Server = 'http://router.project-osrm.org'
    )

    $routeProfile = switch ($TravelMode) {
        'Driving' { 'driving' }
        'Walking' { 'foot'    }
    }

    $coordinates = "$OriginLongitude,$OriginLatitude;$DestinationLongitude,$DestinationLatitude"
    $uri = "$($Server.TrimEnd('/'))/route/v1/$routeProfile/$($coordinates)?overview=false"

    Write-Debug "[OSRM] Call uri: $uri"
    return Invoke-RestMethod -Uri $uri -Method GET -RetryIntervalSec 1 -MaximumRetryCount 3
}