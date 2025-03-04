function Find-GeoCodeLocationAzureMaps {
    <#
    .SYNOPSIS
        Find a geographical location based on a query or coordinates in Azure Maps.

    .DESCRIPTION
        Find a geographical location based on a query or coordinates in Azure Maps.

    .PARAMETER Query
        A textual query for the location, this is what you would normally enter in the search bar for the map service. Can't be used together with Lat/Long.

    .PARAMETER Latitude
        The latitude as a float. Can't be used together with Query.

    .PARAMETER Longitude
        The longitude as a float. Can't be used together with Query.

    .PARAMETER Apikey
        Apikey from Azure

    .PARAMETER Limit
        Limits the amount of results being returned.

    .EXAMPLE
        Find based on query

        PS> Find-GeoCodeLocationAzureMaps -Query "Microsoft Building 92, NE 36th St, Redmond, WA 98052, United States" -Apikey <YOUR API KEY>
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification='The product is called like this.')]

    [CmdLetBinding()]
    [OutputType([System.Object[]])]

    Param (
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'Query')]
        [String] $Query,

        [Alias("Lat")]
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'Lon/Lat')]
        [Single] $Latitude,

        [Alias("Lon")]
        [Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'Lon/Lat')]
        [Single] $Longitude,

        [Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'Query')]
        [Parameter(Mandatory = $true, Position = 3, ParameterSetName = 'Lon/Lat')]
        [String] $ApiKey,

        [Parameter(Mandatory = $false, Position = 3, ParameterSetName = 'Query')]
        [Parameter(Mandatory = $false, Position = 4, ParameterSetName = 'Lon/Lat')]
        [Int32] $Limit
    )

    switch($PsCmdlet.ParameterSetName) {
        "Query" {
            Write-Debug "Q"
            $uri = "https://atlas.microsoft.com/geocode?api-version=2025-01-01&query=$([System.Web.HttpUtility]::UrlEncode($Query))&subscription-key=$ApiKey"

            if($Limit) {
                $uri += "&top=$Limit"
            }
        }

        "Lon/Lat" {
            $uri = "https://atlas.microsoft.com/reverseGeocode?api-version=2025-01-01&coordinates=$($Latitude),$($Longitude)&subscription-key=$ApiKey"
        }
    }

    Write-Debug "[AzureMaps] Call uri: $uri"
    return Invoke-RestMethod -Uri $uri -Method GET -RetryIntervalSec 1 -MaximumRetryCount 5
}