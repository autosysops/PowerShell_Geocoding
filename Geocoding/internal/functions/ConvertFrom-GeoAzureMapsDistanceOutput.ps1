function ConvertFrom-GeoAzureMapsDistanceOutput {
    <#
    .SYNOPSIS
        Convert route output from Azure Maps to uniform output format.

    .DESCRIPTION
        Convert route directions output from Azure Maps to the uniform distance
        output format used by Find-GeoCodeDistance.

    .PARAMETER Resource
        The raw response object returned by Find-GeoCodeDistanceAzureMaps.

    .EXAMPLE
        Convert the output

        PS> ConvertFrom-GeoAzureMapsDistanceOutput -Resource $output
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'The product is called like this.')]

    [CmdLetBinding()]
    [OutputType([Object])]

    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [Object] $Resource
    )

    Write-Debug "[AzureMaps] convert distance output"

    $summary   = $Resource.routes[0].summary
    $delaySecs = $summary.trafficDelayInSeconds

    $trafficDelay = if ($null -ne $delaySecs -and $delaySecs -gt 0) {
        [TimeSpan]::FromSeconds($delaySecs)
    }
    else {
        $null
    }

    return [PSCustomObject]@{
        "Distance"     = [PSCustomObject]@{
            "Meters" = $summary.lengthInMeters
        }
        "Duration"     = [TimeSpan]::FromSeconds($summary.travelTimeInSeconds)
        "TrafficDelay" = $trafficDelay
    }
}