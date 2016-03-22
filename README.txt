Jira Module for PowerShell

This is a PowerShell module for working with the Jira REST API.

To install, put Jira.psm1 and Jira.psd1 in folder
C:\Program Files\Common Files\Modules\Jira

Included cmdlets:

	Find-JiraIssues
		Returns a list of Jira ticket keys matching the specified JQL query.

		JQL syntax is not validated; anything that works in the Jira web portal
		should work here.

		As of 2/23/15, make sure comma-separated lists used for in/not in queries
		do not have spaces.  i.e. (one,two,three) is ok but (one, two, three) is not.

	Get-JiraWorklogs
		Returns the Jira issue type, issue summary, and work logs for a ticket.

