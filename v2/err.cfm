<cfmail to="#error.MailTo#" subject="FB Publisher Error" from="error@eshots.com" type="html">
<cfdump var="#cferror#">
<!--- <cfif isDefined('event_info')><cfdump var="#event_info#" label="event_info"></cfif>
<cfif isDefined('etclid')><cfdump var="#etclid#" label="etclid"></cfif>
<cfif isDefined('eventToken')><cfdump var="#eventToken#" label="eventToken"></cfif>
<cfif isDefined('clientLicense')><cfdump var="#clientLicense#" label="clientLicense"></cfif> --->
</cfmail>
<cfoutput>#cferror.message#</cfoutput>