<cfset setComponent = "com.eshots.dbaccess.SaveDataAccess">

<!--- 
We're Ignoring the first part of the string for now, which verifies the ping is from FB because CF 7 doesn't support HMAC SHA-256 
PS: It's not supported in our version of Java either...
 --->
<cfinvoke component="JSON" method="decode" data="#ToString( ToBinary( Trim ( ListGetAt(FORM.SIGNED_REQUEST,2,'.') ) & '=' ) )#" returnvariable="userInfo" />

<cfinvoke component="FacebookPublisher" method="GetCLIDfromFBID" returnvariable="qryClientLicenseIDs">
	<cfinvokeargument name="facebook_ID" value="#userInfo.user_id#">
</cfinvoke>

<cfset SESSION.facebook_id = userInfo.user_id>

<cfloop query="qryClientLicenseIDs">

	<cfset SESSION.client_license_id = qryClientLicenseIDs.client_license_id>

	<cfinvoke component="FacebookPublisher" method="SetupRELATs" returnvariable="SESSION.relats">
		<cfinvokeargument name="client_license_id" value="#SESSION.client_license_id#">
	</cfinvoke>

	<cfinvoke component="FacebookPublisher" method="CheckPrevEntry" returnvariable="SESSION.consumerInfo">
		<cfinvokeargument name="facebook_ID" value="#SESSION.facebook_id#">
		<cfinvokeargument name="client_license_id" value="#SESSION.client_license_id#">
	</cfinvoke>

	<cfinvoke component="#setComponent#" method="insertFootprint" returnvariable="footprint_id">
		<cfinvokeargument name="event_token_ID" value="#SESSION.consumerInfo.event_token_id#">
		<cfinvokeargument name="r_elat_ID" value="#SESSION.relats.deauth#">
		<cfinvokeargument name="client_license_ID" value="#SESSION.client_license_id#">
		<cfinvokeargument name="sample_flag" value="#SESSION.consumerInfo.sample_flag#">
	</cfinvoke>

	<cfset SESSION.deauth_footprint = footprint_id>

	<cfmail to="jmiller@eshots.com" from="deauth@eshots.com" subject="Media Publisher Deauthorized" type="HTML">
		Deauth Ping
		<hr />
		<cfif IsDefined("FORM")>
			<cfdump var="#FORM#">
		<cfelse>
			FORM undefined.<br />
		</cfif>
	
		<cfif IsDefined("application")>
			<cfdump var="#application#">
		<cfelse>
			application undefined.<br />
		</cfif>
		CGI Info
		<hr />
		<cfif IsDefined("CGI")>
			<cfdump var="#CGI#" expand="false">
		<cfelse>
			CGI undefined.<br />
		</cfif>
	</cfmail>

</cfloop>