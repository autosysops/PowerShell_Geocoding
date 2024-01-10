function Find-GeoCodeLocationBingMaps {
    <#
    .SYNOPSIS
        Find a geographical location based on a query or coordinates in Bing Maps.

    .DESCRIPTION
        Find a geographical location based on a query or coordinates in Bing Maps.

    .PARAMETER Query
        A textual query for the location, this is what you would normally enter in the search bar for the map service. Can't be used together with Lat/Long.

    .PARAMETER Latitude
        The latitude as a float. Can't be used together with Query.

    .PARAMETER Longitude
        The longitude as a float. Can't be used together with Query.

    .PARAMETER Apikey
        Apikey from Bing

    .PARAMETER Limit
        Limits the amount of results being returned.

    .EXAMPLE
        Find based on query

        PS> Find-GeoCodeLocationBingMaps -Query "Microsoft Building 92, NE 36th St, Redmond, WA 98052, United States" -Apikey <YOUR API KEY>
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification='The product is called like this.')]

    [CmdLetBinding()]
    [OutputType([Array])]

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
            $uri = "http://dev.virtualearth.net/REST/v1/Locations/$([System.Web.HttpUtility]::UrlEncode($Query))?o=json&key=$ApiKey"

            if($Limit) {
                $uri += "&maxResults=$Limit"
            }
        }

        "Lon/Lat" {
            $uri = "http://dev.virtualearth.net/REST/v1/Locations/$($Latitude),$($Longitude)?o=json&key=$ApiKey"
        }
    }

    Write-Debug "[BingMaps] Call uri: $uri"
    return Invoke-RestMethod -Uri $uri -Method GET -RetryIntervalSec 1 -MaximumRetryCount 5
}