
<cfinclude template="serverCheck.cfm">
<cfif server_location EQ "Staging">
	<cfset APPLICATION.appID = "123842974364777">
	<cfset APPLICATION.apiKey = "8fe3aaa6f0a314e7cbbfe1ced5cd878c">
	<cfset APPLICATION.secret = "1c39087ac536765f9427a746e5067708">
	<cfset APPLICATION.appurl = "http://apps.facebook.com/media_publisher_dev/"> <!--- canvas url --->
	<cfset publicURL = "http://media.eshots.com">
<cfelse>
	<cfset APPLICATION.appID = "195330077169991">
	<cfset APPLICATION.apiKey = "02ab245ac7eb7aca85109f7e287ecd20">
	<cfset APPLICATION.secret = "b5dcc41909316388f0feec63f96fd2b0">
	<cfset APPLICATION.appurl = "http://apps.facebook.com/media_publisher/"> <!--- canvas url --->
	<cfset publicURL = "http://media.eshots.com">
</cfif>