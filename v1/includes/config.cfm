<cfset dsn = "efn">

<cfparam name="server_location" default = "Production">
<cfinclude template="serverCheck.cfm">

<cfset setComponent = "com.eshots.dbaccess.SaveDataAccess">
<cfset fbPublisherCom = "includes/FacebookPublisher">


<cfif server_location EQ "Staging">
	<cfset APPLICATION.appID = "123842974364777">
	<cfset APPLICATION.apiKey = "8fe3aaa6f0a314e7cbbfe1ced5cd878c">
	<cfset APPLICATION.secret = "1c39087ac536765f9427a746e5067708">
	<cfset APPLICATION.appurl = "http://apps.facebook.com/media_publisher_dev/"> <!--- canvas url --->
	<cfset SESSION.redirecturl = APPLICATION.appurl & "home.cfm?PARAMS"> <!--- canvas callback url --->
	<cfset APPLICATION.requiredPermissions = "publish_stream,user_birthday,email,user_photos">
	<!--- Redirect to get authonticated and authrorized from facebook, in the redirect_uri you should write the url of your website where you want the user to be redirected after authroization --->
	<cfset SESSION.auth_url="http://www.facebook.com/dialog/oauth?client_id=#APPLICATION.appID#&redirect_uri=#SESSION.redirecturl#&scope=#APPLICATION.requiredPermissions#" />

	<cfset publicURL = "http://staging.eshots.com">
<cfelse>
	<cfset APPLICATION.appID = "195330077169991">
	<cfset APPLICATION.apiKey = "02ab245ac7eb7aca85109f7e287ecd20">
	<cfset APPLICATION.secret = "b5dcc41909316388f0feec63f96fd2b0">
	<cfset APPLICATION.appurl = "http://apps.facebook.com/media_publisher/"> <!--- canvas url --->
	<cfset SESSION.redirecturl = APPLICATION.appurl & "home.cfm?PARAMS"> <!--- canvas callback url --->
	<cfset APPLICATION.requiredPermissions = "publish_stream,user_birthday,email,user_photos">
	<!--- Redirect to get authonticated and authrorized from facebook, in the redirect_uri you should write the url of your website where you want the user to be redirected after authroization --->
	<cfset SESSION.auth_url="http://www.facebook.com/dialog/oauth?client_id=#APPLICATION.appID#&redirect_uri=#SESSION.redirecturl#&scope=#APPLICATION.requiredPermissions#" />

	<cfset publicURL = "http://media.eshots.com">
</cfif>


<cfset fb_id_de = 10230>
<cfset fb_album_de = 10232>
<cfset fb_photo_de = 10261>
<cfparam name="errorMsg" default="">


<cfif IsDefined("URL.id1") AND REFind("[a-zA-Z0-9]{5}", URL.id1) 
  AND IsDefined("URL.id2") AND REFind("[a-zA-Z0-9]{5}", URL.id2)
  AND IsDefined("URL.clid") AND REFind("[0-9]{5}", URL.clid)>
  	<cfset SESSION.event_token = URL.id1 & URL.id2>
  	<cfset SESSION.client_license_id = URL.clid>

	<cfset SESSION.auth_url = Replace(SESSION.auth_url,"PARAMS","event_token_clid="&SESSION.event_token&"_"&SESSION.client_license_id,"all")>

	<cfinvoke component="FacebookPublisher" method="getEvent" returnvariable="event_info">
		<cfinvokeargument name="event_token_id" value="#SESSION.event_token#">
		<cfinvokeargument name="client_license_id" value="#SESSION.client_license_id#">
	</cfinvoke>
	<cfif NOT event_info.RecordCount>
		<cfset errorMsg = "The URL you have entered is not valid.  Please verify the link in your email and be sure to click on or paste the full URL into your browser.<br /><br />
			For additional help, please contact <a href='mailto:customer_support@eshots.com'>customer_support@eshots.com</a>.">
	</cfif>

<cfelseif IsDefined("URL.event_token_clid") AND REFind("[a-zA-Z0-9]{10}\_[0-9]{5}", URL.event_token_clid) >

	<cfset SESSION.redirecturl = Replace(SESSION.redirecturl,"PARAMS","event_token_clid="&URL.event_token_clid,"all")>
	
  	<cfset SESSION.event_token = ListGetAt(URL.event_token_clid,1,"_")>
  	<cfset SESSION.client_license_id = ListGetAt(URL.event_token_clid,2,"_")>



<!--- This is to sniff the bookmarks link clicked
<cfelseif IsDefined("URL.ref") AND URL.ref = "bookmarks">

	<!--- Request all the user's data --->
	<cfhttp method="GET" url="https://graph.facebook.com/me" result="fbConsumerInfo">
		<cfhttpparam type="url" name="access_token" value="#access_token#" />
		<cfhttpparam type="header" name="mimetype" value="text/javascript" />
	</cfhttp>
	<cfinvoke component="includes/JSON" method="decode" data="#Trim(fbConsumerInfo.Filecontent)#" returnvariable="consumerData"/>
	
	<cfif IsDefined("consumerData.id")>
		<!--- First try to see if this FB ID has participated with this app --->
		<cfinvoke component="#fbPublisherCom#" method="CheckPrevEntry" returnvariable="consumerInfo">
			<cfinvokeargument name="facebook_ID" value="#consumerData['id']#">
			<cfinvokeargument name="client_license_id" value="#SESSION.client_license_id#">
		</cfinvoke>
	</cfif>
--->



<cfelse>
	<cfif server_location EQ "Staging">
		<cfset errorMsg = "You're missing URL variables.<br /><br />
			Public error message: The URL you have entered is not valid.  Please verify the link in your email and be sure to click on or paste the full URL into your browser.<br /><br />
			For additional help, please contact <a href='mailto:customer_support@eshots.com'>customer_support@eshots.com</a>.">
	<cfelse>
		<cfset errorMsg = "The URL you have entered is not valid.  Please verify the link in your email and be sure to click on or paste the full URL into your browser.<br /><br />
			For additional help, please contact <a href='mailto:customer_support@eshots.com'>customer_support@eshots.com</a>.">
	</cfif>
</cfif>


<cfif errorMsg EQ "">
	<cfinvoke component="FacebookPublisher" method="getEvent" returnvariable="event_info">
		<cfinvokeargument name="event_token_id" value="#SESSION.event_token#">
		<cfinvokeargument name="client_license_id" value="#SESSION.client_license_id#">
	</cfinvoke>
	<cfif IsDefined("event_info")>
		<cfset SESSION.event_info = event_info>
	</cfif>

	<cftry>
		<cfinvoke component="FacebookPublisher" method="SetupRELATs" returnvariable="SESSION.relats">
			<cfinvokeargument name="client_license_id" value="#SESSION.client_license_id#">
		</cfinvoke>


		<cfcatch type="any">
			<cfset errorMsg = "The URL you have entered is not valid.  Please verify the link in your email and be sure to click on or paste the full URL into your browser.<br /><br />
			For additional help, please contact <a href='mailto:customer_support@eshots.com'>customer_support@eshots.com</a>.">
			<cfdump var="#cfcatch.Message# | #cfcatch.Detail#">
		</cfcatch>
	</cftry>
</cfif>