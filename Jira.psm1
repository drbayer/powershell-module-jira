<#	
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2015 v4.2.80
	 Created on:   	2/20/2015 2:49 PM
	 Created by:   	david.bayer
	 Organization: 	
	 Filename:     	Jira.psm1
	-------------------------------------------------------------------------
	 Module Name: Jira
	===========================================================================
#>

<#
	.SYNOPSIS
		Returns an array object of keys for Jira issues matching a JQL query
	
	.DESCRIPTION
		Returns a list of issue keys matching the specified JQL query.
	
    .PARAMETER URL
        URL for the Jira server.

	.PARAMETER JQL
		JQL query to search for Jira issues.  See Jira documentation for details of JQL query syntax.
	
	.PARAMETER Credential
		PowerShell Credential object containing credentials for Jira.
	
	.EXAMPLE
		PS C:\> Find-JiraIssues -JQL 'project = DevOps'
	
	.EXAMPLE
		PS C:\> Find-JiraIssues -JQL 'project = DevOps AND timespent > 0'
	
#>
function Find-JiraIssues {
	[CmdletBinding()]
	param
	(
        [Parameter(Mandatory = $true)][string]$URL,
		[Parameter(Mandatory = $true)][string]$JQL,
		[Parameter(Mandatory = $true)][PSCredential]$Credential = $(Get-Credential -Message "Enter Jira credentials:")
	)
	BEGIN {
		[regex]$operators = "[>|<|=|!]{1,2}"
		foreach ($group in $operators.Matches($JQL)) {
			$JQL = $JQL -replace "\s+$($group.Value)\s+",$group.Value
		}
		$JQL = $JQL -replace "\s+-\s+", "-"
		$JQL = $JQL -replace "\s+", "+"
		New-Variable -Name tickets -Value $null
	}
	
	PROCESS {
		$start = 0
		$queryuri = "$URL/rest/api/2/search?jql=$JQL&fields=key"
		
		Write-Debug $queryuri
		
		$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $Credential.UserName, $Credential.GetNetworkCredential().Password)))
		$header = @{ Authorization = ("Basic {0}" -f $auth) }
		
		do {
			$uri = "$queryuri&startAt=$start"
			$result = Invoke-RestMethod -Uri $uri -Method Get -Headers $header
			if ($result.issues.count -gt 0) {
				$tickets += $result.issues.key
			}
			$start += 50
		} until ($result.issues.count -eq 0)
	}
	
	END {
		$tickets
	}
}

<#
	.SYNOPSIS
		Retrieves worklogs for the specified Jira issue.
	
	.DESCRIPTION
		DEPRECATED: This function has been deprecated.  Get-JiraTicket has been updated
					to support an optional field list, making this function obsolete.

		Returns the issue summary, issue type, and worklogs for a given Jira issue.
    
    .PARAMETER URL
        URL for the Jira server.
	
	.PARAMETER JiraKey
		A key for a Jira issue.
	
	.EXAMPLE
				PS C:\> Get-JiraWorklogs -JiraKey 'DO-308'
	
#>
function Get-JiraWorklogs {
	[CmdletBinding()]
	param
	(
        [Parameter(Mandatory = $true)][string]$URL,
		[Parameter(Mandatory = $true)][ValidatePattern('\A[a-zA-Z]{1,8}-\d+\Z')][string]$JiraKey,
		[Parameter(Mandatory = $true)][PSCredential]$Credential = $(Get-Credential -Message "Enter Jira credentials:")
	)
	
	Write-Warning -Message "This function has been deprecated.  Use Get-JiraTicket -Fields instead."
	
	$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $Credential.UserName, $Credential.GetNetworkCredential().Password)))
	$header = @{ Authorization = ("Basic {0}" -f $auth) }
	$uri = "$URL/rest/api/2/issue/$($JiraKey)?fields=summary,issuetype,worklog,created,updated,labels"
	
	$ticket = Invoke-RestMethod -Method Get -Headers $header -Uri $uri
	
	$ticket
}


<#
	.SYNOPSIS
		Retrieves worklogs for the specified Jira issue.
	
	.DESCRIPTION
		Returns the full contents of a given Jira issue.
	
    .PARAMETER URL
        URL for the Jira server.
	
	.PARAMETER JiraKey
		A key for a Jira issue.

	.PARAMETER Fields
		Optional parameter limiting data returned to the specified fields.
	
	.EXAMPLE
		Returns the full set of data for Jira ticket DO-308

				PS C:\> Get-JiraTicket -JiraKey 'DO-308' -Credential $mycred

	.EXAMPLE
		Returns only the data for the issuetype and summary fields for Jira ticket DO-308

				PS C:\> Get-JiraTicket -JiraKey 'DO-308' -Credential $mycred -Fields issuetype,summary
#>

function Get-JiraTicket {
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)][string]$URL,
        [Parameter(Mandatory = $true)][ValidatePattern('\A[a-zA-Z]{1,8}-\d+\Z')][string]$JiraKey,
		[Parameter(Mandatory = $true)][PSCredential]$Credential = $(Get-Credential -Message "Enter Jira credentials:"),
		[Parameter(Mandatory = $false)][string[]]$Fields
	)
	
	$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $Credential.UserName, $Credential.GetNetworkCredential().Password)))
	$header = @{ Authorization = ("Basic {0}" -f $auth) }
	$uri = "$URL/rest/api/2/issue/$($JiraKey)"
	
	if ($Fields.Count -gt 0) {
		$uri = "$($uri)?fields=$($Fields -join ',')"
	}
	
	$ticket = Invoke-RestMethod -Method Get -Headers $header -Uri $uri
	
	$ticket
}

Export-ModuleMember Find-JiraIssues, Get-JiraWorklogs, Get-JiraTicket



