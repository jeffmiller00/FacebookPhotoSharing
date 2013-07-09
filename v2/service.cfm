<cfset eventToken = listGetAt(URL.etclid,1,"_")>
<cfset clientLicense = listGetAt(URL.etclid,2,"_")>

<cfset dsn="efn">
<!--- <cfparam name="event_token" default="0">
<cfparam name="client_license_id" default="0"> --->

<cfinvoke component="#fbPublisherCom#" method="getEventLocation" returnvariable="event_location_info">
	<!---todo: change session variable--->
	<cfinvokeargument name="client_license_id" value="#clientLicense#">
</cfinvoke>

<cfinvoke component="includes/FacebookPublisher" method="SetupRELATs" returnvariable="relats">
	<cfinvokeargument name="client_license_id" value="#clientLicense#">
</cfinvoke>

<cfinvoke component="includes/FacebookPublisher" method="getEvent" returnvariable="event_info">
	<cfinvokeargument name="event_token_id" value="#eventToken#">
	<cfinvokeargument name="client_license_id" value="#clientLicense#">
</cfinvoke>
<!--- <cfdump var="#event_info#"> --->

<!---set the imageURL and photoID variables--->
<cfset photoID=event_info.event_photo_id>
<cfset imageURL=event_info.url>

<cfinvoke component="#setComponent#" method="insertFootprint" returnvariable="footprint_id">
	<cfinvokeargument name="event_token_ID" value="#eventToken#">
	<cfinvokeargument name="r_elat_ID" value="#relats.retrieve#">
	<cfinvokeargument name="client_license_ID" value="#clientLicense#">
	<cfinvokeargument name="sample_flag" value="#event_info.sample_flag#">
	<cfinvokeargument name="record_multiple" value="false">
</cfinvoke>

<!--- <cflocation url="#auth_url#"><!---why is this here?---> --->

<cfset action=#url.action#>
<cfswitch expression="#action#">
	<cfcase value="login">
		<cflocation url="#redirecturl#">
	</cfcase>	
	<cfcase value="saveconsumer">
		<cfinclude template="includes/saveconsumer.cfm">
	</cfcase>
	<cfcase value="savealbum">
		<cfinclude template="includes/savealbum.cfm">
	</cfcase>
	<cfcase value="savelike">
		<cfinclude template="includes/like.cfm">
	</cfcase>
	<cfdefaultcase>
		No Action Match: #action#
	</cfdefaultcase>
</cfswitch>
