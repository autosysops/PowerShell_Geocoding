function Find-GeoCodeDistanceAzureMaps {
    <#
    .SYNOPSIS
        Calculate the route distance between two coordinates using Azure Maps.

    .DESCRIPTION
        Uses the Azure Maps Route Directions API to retrieve route distance and
        duration between an origin and a destination. Azure Maps includes live
        traffic data by default for car routing.

    .PARAMETER OriginLatitude
        The latitude of the origin point.

    .PARAMETER OriginLongitude
        The longitude of the origin point.

    .PARAMETER DestinationLatitude
        The latitude of the destination point.

    .PARAMETER DestinationLongitude
        The longitude of the destination point.

    .PARAMETER ApiKey
        Azure Maps subscription key.

    .PARAMETER TravelMode
        The travel mode. Accepts Driving or Walking. Defaults to Driving.

    .PARAMETER DepartureTime
        Optional departure time as a DateTime for route planning.

    .PARAMETER ArrivalTime
        Optional desired arrival time as a DateTime. Only valid for Driving mode.

    .EXAMPLE
        Calculate driving distance

        PS> Find-GeoCodeDistanceAzureMaps -OriginLatitude 52.30 -OriginLongitude 4.75 -DestinationLatitude 53.56 -DestinationLongitude 9.92 -ApiKey "KEY"
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'The product is called like this.')]

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

        [Parameter(Mandatory = $true, Position = 5)]
        [String] $ApiKey,

        [Parameter(Mandatory = $false, Position = 6)]
        [ValidateSet('Driving', 'Walking')]
        [String] $TravelMode = 'Driving',

        [Parameter(Mandatory = $false)]
        [DateTime] $DepartureTime,

        [Parameter(Mandatory = $false)]
        [DateTime] $ArrivalTime
    )

    $mode = switch ($TravelMode) {
        'Driving' { 'car'        }
        'Walking' { 'pedestrian' }
    }

    $uri = "https://atlas.microsoft.com/route/directions/json?api-version=1.0&subscription-key=$ApiKey&query=$OriginLatitude,$OriginLongitude`:$DestinationLatitude,$DestinationLongitude&travelMode=$mode"

    if ($DepartureTime) {
        $formatted = $DepartureTime.ToString("yyyy-MM-ddTHH:mm:sszzz")
        $uri += "&departAt=$([System.Web.HttpUtility]::UrlEncode($formatted))"
    }
    if ($ArrivalTime) {
        $formatted = $ArrivalTime.ToString("yyyy-MM-ddTHH:mm:sszzz")
        $uri += "&arriveAt=$([System.Web.HttpUtility]::UrlEncode($formatted))"
    }

    Write-Debug "[AzureMaps] Call uri: $uri"
    return Invoke-RestMethod -Uri $uri -Method GET -RetryIntervalSec 1 -MaximumRetryCount 5
}