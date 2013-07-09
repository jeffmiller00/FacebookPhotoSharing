<cfsetting enablecfoutputonly="true" requesttimeout="1200" showDebugOutput="true" /> <!--- 20 minute timeout & only output anything between cfoutput tags --->
<!--- SAMPLE URLS
http://staging.eshots.com/fb/publisher/qc4_post_script/qc4_ws.cfm?action=0&spid=1
http://staging.eshots.com/fb/publisher/qc4_post_script/qc4_ws.cfm?action=1&cid=19687371&fid=33704345
--->
<cfparam name="variables.DSN" type="string" default="efn" />
<cfparam name="variables.EMAIL_DE" type="numeric" default="4" />
<cfparam name="variables.FACEBOOK_ID_DE" type="numeric" default="10230" />
<cfparam name="variables.ACCESS_TOKEN_DE" type="numeric" default="10899" />

<cfparam name="variables.action" type="numeric" default="0" />
<cfparam name="variables.data" type="struct" default="#StructNew()#" />
<cfparam name="variables.data.social_post_id" type="numeric" default="0" />
<cfparam name="variables.data.event_token_id" type="string" default="" />
<cfparam name="variables.data.client_license_id" type="numeric" default="0" />
<cfparam name="variables.data.consumer_id" type="numeric" default="0" />
<cfparam name="variables.data.footprint_id" type="numeric" default="0" />

<cfif isDefined("URL.action")>
	<cfset variables.action = URL.action />
</cfif>
<cfif isDefined("URL.spid")>
	<cfset variables.data.social_post_id = URL.spid />
</cfif>
<cfif isDefined("URL.etid")>
	<cfset variables.data.event_token_id = URL.etid />
</cfif>
<cfif isDefined("URL.clid")>
	<cfset variables.data.client_license_id = URL.clid />
</cfif>
<cfif isDefined("URL.cid")>
	<cfset variables.data.consumer_id = URL.cid />
</cfif>
<cfif isDefined("URL.fid")>
	<cfset variables.data.footprint_id = URL.fid />
</cfif>



<cfswitch expression="#variables.action#" >

	<cfcase value="0" > <!--- update_sent_flag (Required: social post id) --->
		
		<cfquery name="qryUpdateSentFlag" datasource="#variables.DSN#">
			UPDATE Social_Posts 
			SET sent_flag = 1 
			WHERE social_post_ID = <cfqueryparam cfsqltype="cf_sql_bigint" value="#variables.data.social_post_id#">
		</cfquery>
		
		<cfoutput>1</cfoutput>
	</cfcase> 
		
	<cfcase value="1" > <!--- clear_fb_access_token (Required: event token id, client license id) --->
		
		<cfquery name="qryInsertEmptyAccessToken" datasource="#variables.DSN#">
			INSERT INTO R_Consumer_Data_Element_Answer (
				consumer_ID,
				data_element_ID,
				footprint_ID,
				create_DTM,
				answer_text
			) VALUES (
				<cfqueryparam cfsqltype="cf_sql_bigint" value="#variables.data.consumer_id#">,
				<cfqueryparam cfsqltype="cf_sql_bigint" value="#variables.ACCESS_TOKEN_DE#">,
				<cfqueryparam cfsqltype="cf_sql_bigint" value="#variables.data.footprint_id#">,
				<cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#">,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="">
			);
		</cfquery>
		
		<cfoutput>1</cfoutput>
	</cfcase>

	<cfdefaultcase >
		<cfoutput>0</cfoutput>
	</cfdefaultcase> <!--- This should do nothing --->

</cfswitch>