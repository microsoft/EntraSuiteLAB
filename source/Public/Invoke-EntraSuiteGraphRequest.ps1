function Invoke-EntraSuiteGraphRequest
{
    <#
    .SYNOPSIS
    Makes a request to Microsoft Graph API.

    .DESCRIPTION
    This function provides a standardized way to make requests to Microsoft Graph API
    within the EntraSuiteLAB module. It handles common tasks like error handling,
    logging, and response processing.

    .PARAMETER Method
    The HTTP method to use for the request (GET, POST, PATCH, PUT, DELETE).

    .PARAMETER Uri
    The Graph API endpoint URI to call, relative to the Graph API version.
    Do not include the base URL or API version - these are automatically included.
    Example: '/users' or '/groups'

    .PARAMETER Body
    The request body for POST, PATCH, and PUT requests, as a hashtable or custom object.
    Will be automatically converted to JSON.

    .PARAMETER Headers
    Additional HTTP headers to include in the request.

    .PARAMETER ApiVersion
    The Microsoft Graph API version to use. Defaults to 'v1.0'.

    .PARAMETER ContentType
    The content type of the request, defaults to 'application/json'.

    .PARAMETER ExpandProperty
    Property to automatically expand in the result.
    Useful when the response data is nested within a property like 'value'.

    .PARAMETER PageSize
    Number of results to return per page when using paging.

    .PARAMETER All
    Switch to automatically retrieve all pages of results.
    If not specified, only the first page is returned.

    .EXAMPLE
    Invoke-EntraSuiteGraphRequest -Method GET -Uri '/users' -All
    Retrieves all users from the tenant.

    .EXAMPLE
    Invoke-EntraSuiteGraphRequest -Method POST -Uri '/groups' -Body @{
        displayName = "Marketing Team"
        mailNickname = "marketing"
        mailEnabled = $false
        securityEnabled = $true
    }
    Creates a new security group.

    .EXAMPLE
    Invoke-EntraSuiteGraphRequest -Method GET -Uri "/users/$UserId/memberOf" -ApiVersion 'beta' -All
    Gets all groups a user belongs to, using the beta API version.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('GET', 'POST', 'PATCH', 'PUT', 'DELETE')]
        [string]
        $Method,

        [Parameter(Mandatory = $true)]
        [string]
        $Uri,

        [Parameter()]
        [object]
        $Body,

        [Parameter()]
        [hashtable]
        $Headers = @{},

        [Parameter()]
        [ValidateSet('v1.0', 'beta')]
        [string]
        $ApiVersion = 'beta',

        [Parameter()]
        [string]
        $ContentType = 'application/json',

        [Parameter()]
        [string]
        $ExpandProperty,

        [Parameter()]
        [int]
        $PageSize = 100,

        [Parameter()]
        [switch]
        $All
    )

    begin
    {
        Write-PSFMessage -Level Verbose -Message "Beginning $($MyInvocation.MyCommand) with Method: $Method, Uri: $Uri, ApiVersion: $ApiVersion"

        # Initialize result collection if using pagination
        $resultCollection = [System.Collections.Generic.List[PSObject]]::new()

        # Handle URI formatting
        if ($Uri.StartsWith('https://'))
        {
            Write-PSFMessage -Level Warning -Message "URI should be relative to Graph API. Full URLs are not recommended."
        }
        elseif ($Uri.StartsWith('/'))
        {
            $Uri = $Uri.TrimStart('/')
        }

        $fullUri = "https://graph.microsoft.com/$ApiVersion/$Uri"
        Write-PSFMessage -Level Debug -Message "Full URI: $fullUri"
    }

    process
    {
        try
        {
            if ($PSCmdlet.ShouldProcess($Uri, "Invoke Graph API with method $Method"))
            {
                # Handle body content
                if ($Body -and $Method -ne 'GET')
                {
                    Write-PSFMessage -Level Debug -Message "Request body: $($Body | ConvertTo-Json -Depth 5 -Compress)"

                    # Prepare parameters for Invoke-MgGraphRequest
                    $params = @{
                        Method      = $Method
                        Uri         = $fullUri
                        Headers     = $Headers
                        ContentType = $ContentType
                        Body        = $Body
                    }
                }
                else
                {
                    # GET request or no body specified
                    $params = @{
                        Method      = $Method
                        Uri         = $fullUri
                        Headers     = $Headers
                        ContentType = $ContentType
                    }

                    # Handle pagination for GET requests
                    if ($All -and $Method -eq 'GET')
                    {
                        Write-PSFMessage -Level Verbose -Message "Retrieving all pages of results"

                        # Add page size if specified
                        if ($PageSize -gt 0)
                        {
                            if ($fullUri.Contains('?'))
                            {
                                $fullUri += "&`$top=$PageSize"
                            }
                            else
                            {
                                $fullUri += "?`$top=$PageSize"
                            }
                            $params.Uri = $fullUri
                        }

                        # Initialize nextLink for pagination
                        $nextLink = $null

                        do
                        {
                            # If we have a nextLink, use it for the next request
                            if ($nextLink)
                            {
                                Write-PSFMessage -Level Debug -Message "Retrieving next page with URI: $nextLink"
                                $params.Uri = $nextLink
                            }

                            # Execute the request
                            $response = Invoke-MgGraphRequest @params

                            # Process the results
                            if ($ExpandProperty -and $response.$ExpandProperty)
                            {
                                $resultCollection.AddRange($response.$ExpandProperty)
                            }
                            elseif ($response.value)
                            {
                                $resultCollection.AddRange($response.value)
                            }
                            else
                            {
                                # If there's no value property, add the whole response
                                $resultCollection.Add($response)
                            }

                            # Get the next link if it exists
                            $nextLink = $response.'@odata.nextLink'

                        } while ($nextLink)

                        # Return the collected results
                        return $resultCollection
                    }
                    else
                    {
                        # Regular non-paginated request
                        $response = Invoke-MgGraphRequest @params

                        # Return appropriate property
                        if ($ExpandProperty -and $response.$ExpandProperty)
                        {
                            return $response.$ExpandProperty
                        }
                        elseif ($Method -eq 'GET' -and $response.value)
                        {
                            return $response.value
                        }
                        else
                        {
                            return $response
                        }
                    }
                }

                # Execute the request and capture response
                $response = Invoke-MgGraphRequest @params

                # Process the response based on the request type and structure
                if ($ExpandProperty -and $response.$ExpandProperty)
                {
                    return $response.$ExpandProperty
                }
                elseif ($Method -eq 'GET' -and $response.value)
                {
                    return $response.value
                }
                else
                {
                    return $response
                }
            }
        }
        catch
        {
            # Detailed error logging
            $statusCode = $_.Exception.Response.StatusCode.value__

            Write-PSFMessage -Level Error -Message "Graph API request failed with status code $statusCode" -ErrorRecord $_

            if ($_.ErrorDetails.Message)
            {
                try
                {
                    $errorContent = $_.ErrorDetails.Message | ConvertFrom-Json
                    Write-PSFMessage -Level Debug -Message "Error details: $($errorContent | ConvertTo-Json -Compress)"
                }
                catch
                {
                    Write-PSFMessage -Level Debug -Message "Error details: $($_.ErrorDetails.Message)"
                }
            }

            throw $_
        }
    }

    end
    {
        Write-PSFMessage -Level Verbose -Message "Ending $($MyInvocation.MyCommand)"
    }
}
