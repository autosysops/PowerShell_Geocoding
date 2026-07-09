function ConvertFrom-GeoGoogleMapsDistanceOutput {
    <#
    .SYNOPSIS
        Convert distance output from Google Maps to uniform output format.

    .DESCRIPTION
        Convert distance matrix output from Google Maps to the uniform distance
        output format used by Find-GeoCodeDistance.

    .PARAMETER Resource
        The raw response object returned by Find-GeoCodeDistanceGoogleMaps.

    .EXAMPLE
        Convert the output

        PS> ConvertFrom-GeoGoogleMapsDistanceOutput -Resource $output
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'The product is called like this.')]

    [CmdLetBinding()]
    [OutputType([Object])]

    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [Object] $Resource
    )

    Write-Debug "[GoogleMaps] convert distance output"

    $element  = $Resource.rows[0].elements[0]
    $baseSecs = $element.duration.value

    if ($element.duration_in_traffic) {
        $totalSecs    = $element.duration_in_traffic.value
        # Clamp to zero — negative delay (faster with traffic) is reported as no delay.
        $delaySecs    = [Math]::Max(0, $totalSecs - $baseSecs)
        # Always return a TimeSpan when traffic data was returned, even for zero delay.
        # A null TrafficDelay means "no traffic data", a zero TimeSpan means "no extra delay".
        $trafficDelay = [TimeSpan]::FromSeconds($delaySecs)
    }
    else {
        $totalSecs    = $baseSecs
        $trafficDelay = $null
    }

    return [PSCustomObject]@{
        "Distance"     = [PSCustomObject]@{
            "Meters" = $element.distance.value
        }
        "Duration"     = [TimeSpan]::FromSeconds($totalSecs)
        "TrafficDelay" = $trafficDelay
    }
}