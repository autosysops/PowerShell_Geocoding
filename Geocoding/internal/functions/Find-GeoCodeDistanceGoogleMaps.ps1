function Find-GeoCodeDistanceGoogleMaps {
    <#
    .SYNOPSIS
        Calculate the route distance between two coordinates using Google Maps.

    .DESCRIPTION
        Uses the Google Maps Distance Matrix API to retrieve route distance and
        duration between an origin and a destination.

    .PARAMETER OriginLatitude
        The latitude of the origin point.

    .PARAMETER OriginLongitude
        The longitude of the origin point.

    .PARAMETER DestinationLatitude
        The latitude of the destination point.

    .PARAMETER DestinationLongitude
        The longitude of the destination point.

    .PARAMETER ApiKey
        Google Maps API key.

    .PARAMETER TravelMode
        The travel mode. Accepts Driving, Walking or Transit. Defaults to Driving.

    .PARAMETER DepartureTime
        Optional departure time as a DateTime. For Driving mode this also enables
        traffic-aware routing.

    .PARAMETER ArrivalTime
        Optional arrival time as a DateTime. Only valid for Transit mode.

    .PARAMETER TrafficAware
        When set, requests real-time traffic data for Driving mode by setting the
        departure time to now if no explicit DepartureTime was provided.

    .EXAMPLE
        Calculate driving distance with traffic

        PS> Find-GeoCodeDistanceGoogleMaps -OriginLatitude 52.30 -OriginLongitude 4.75 -DestinationLatitude 53.56 -DestinationLongitude 9.92 -ApiKey "KEY" -TrafficAware
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
        [ValidateSet('Driving', 'Walking', 'Transit')]
        [String] $TravelMode = 'Driving',

        [Parameter(Mandatory = $false)]
        [DateTime] $DepartureTime,

        [Parameter(Mandatory = $false)]
        [DateTime] $ArrivalTime,

        [Parameter(Mandatory = $false)]
        [Switch] $TrafficAware
    )

    $mode = switch ($TravelMode) {
        'Driving' { 'driving' }
        'Walking' { 'walking' }
        'Transit' { 'transit' }
    }

    $uri = "https://maps.googleapis.com/maps/api/distancematrix/json?origins=$OriginLatitude,$OriginLongitude&destinations=$DestinationLatitude,$DestinationLongitude&mode=$mode&key=$ApiKey"

    if ($TravelMode -eq 'Driving' -and $TrafficAware -and -not $DepartureTime) {
        $uri += "&departure_time=now"
    }
    elseif ($DepartureTime) {
        $epoch = [System.DateTimeOffset]::new($DepartureTime).ToUnixTimeSeconds()
        $uri += "&departure_time=$epoch"
    }
    elseif ($ArrivalTime) {
        $epoch = [System.DateTimeOffset]::new($ArrivalTime).ToUnixTimeSeconds()
        $uri += "&arrival_time=$epoch"
    }

    Write-Debug "[GoogleMaps] Call uri: $uri"
    return Invoke-RestMethod -Uri $uri -Method GET
}