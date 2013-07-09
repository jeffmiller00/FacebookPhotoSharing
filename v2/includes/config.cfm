<!--- Global Variables --->
<cfset setComponent = "com.eshots.dbaccess.SaveDataAccess">
<cfset fbPublisherCom = "includes/FacebookPublisher">
<cfset dsn = "efn">
<cfset read_dsn = "efn_readonly">

<cfset fb_id_de = 10230>
<cfset fb_album_de = 10232>
<cfset fb_photo_de = 10261>

<cfparam name="server_location" default = "Production">
<cfinclude template="serverCheck.cfm">

<!--- TODO: REMOVE --->
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

<cfset APPLICATION.requiredPermissions = "publish_stream,user_birthday,email,user_photos">
<cfparam name="errorMsg" default="">

<!--- Check URL Variables --->
<cfif IsDefined('URL.etclid') AND ListLen(URL.etclid,"_") EQ 2>
	<cfset eventToken = ListGetAt(URL.etclid,1,"_")>
	<cfset clientLicense = ListGetAt(URL.etclid,2,"_")>
<cfelseif IsDefined('URL.id1') AND IsDefined('URL.id2') AND IsDefined('URL.clid')
	AND REFind("[a-zA-Z0-9]{5}", URL.id1) AND REFind("[a-zA-Z0-9]{5}", URL.id2)	AND REFind("[0-9]{5}", URL.clid)>
	<cfset eventToken = URL.id1 & URL.id2>
	<cfset clientLicense = URL.clid>
<cfelse>
	<cfset errorMsg = "The URL you have entered is not valid.  Please verify the link in your email and be sure to click on or paste the full URL into your browser.<br /><br />
		For additional help, please contact <a href='mailto:customer_support@eshots.com'>customer_support@eshots.com</a>.">
</cfif>

<!--- Set Additional Variable --->
<cfif errorMsg EQ "">
	<!--- Redirect to get authonticated and authrorized from facebook, in the redirect_uri you should write the url of your website where you want the user to be redirected after authroization --->
	<cfset redirecturl = APPLICATION.appurl & "index2.cfm?etclid=#eventToken#_#clientLicense#"> <!--- canvas callback url --->
	<cfset auth_url="http://www.facebook.com/dialog/oauth?client_id=#APPLICATION.appID#&redirect_uri=#redirecturl#&scope=#APPLICATION.requiredPermissions#" />
	<cfset APPLICATION.requiredPermissions = "publish_stream,user_birthday,email,user_photos">
</cfif>

<!--- Check for a link from FB --->
<cfif IsDefined('URL.fb_source') AND URL.fb_source EQ 'canvas_bkmk_top'>
	<cfset errorMsg = "Thank you for your participation!">
</cfif>

<!--- Check for Facebook error --->
<cfif errorMsg EQ "">
	<cfif IsDefined('URL.error_reason') AND URL.error_reason EQ 'user_denied'>
		<cfset errorMsg = "Please accept the application permissions to view this photo.<br /><br />
			For additional help, please contact <a href='mailto:customer_support@eshots.com'>customer_support@eshots.com</a>.">
	</cfif>
</cfif>

<!--- Check for a Photo --->
<cfif errorMsg EQ "">
	<cfinvoke component="FacebookPublisher" method="getEvent" returnvariable="event_info">
		<cfinvokeargument name="event_token_id" value="#eventToken#">
		<cfinvokeargument name="client_license_id" value="#clientLicense#">
	</cfinvoke>
	
	<cfif NOT event_info.RecordCount>
		<cfset errorMsg = "The URL you have entered is not valid.  Please verify the link in your email and be sure to click on or paste the full URL into your browser.<br /><br />
			For additional help, please contact <a href='mailto:customer_support@eshots.com'>customer_support@eshots.com</a>.">
	</cfif>
</cfif>

<!--- Check RELATS --->
<cfif errorMsg EQ "">
	<cfinvoke component="FacebookPublisher" method="SetupRELATs" returnvariable="relats">
		<cfinvokeargument name="client_license_id" value="#clientLicense#">
	</cfinvoke>

	<cfif NOT IsDefined('relats.viral') AND NOT IsDefined('relats.deauth') AND NOT IsDefined('relats.share')
		  AND NOT IsDefined('relats.like') AND NOT IsDefined('relats.retrieve')>
		<cfset errorMsg = "The URL you have entered is not valid.  Please verify the link in your email and be sure to click on or paste the full URL into your browser.<br /><br />
			For additional help, please contact <a href='mailto:customer_support@eshots.com'>customer_support@eshots.com</a>.">
	</cfif>	
</cfif>

<!--- Set auth_url --->
<cfif errorMsg EQ "">
	<cfset auth_url = Replace(auth_url,"PARAMS","event_token_clid="&eventToken&"_"&clientLicense,"all")>
</cfif>

<!--- 

<!--- This is to sniff the bookmarks link clicked  --->
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
			<cfinvokeargument name="client_license_id" value="#client_license_id#">
		</cfinvoke>
	</cfif>
--->

<cfif errorMsg NEQ "">

<!DOCTYPE html>
<html lang="en">
	<cfoutput>
	<head>
		<title>eshots Facebook Publisher</title>
		<link rel="stylesheet" type="text/css" href="css/base.css" />

		<cfif server_location NEQ "Staging">
			<cfinclude template="analytics.cfm">
		</cfif>
	</head>
	

	<body>
		<div id="container">
		<div id="stage">
			<p>#errorMsg#</p>

<!--- Previous version - this is what the "landing page" used to be.
			<cfif errorMsg NEQ "">
				<p>#errorMsg#</p>
			<cfelse>
				<div id="photo2fb">
					<div id="consumerImg"></div>
					<img src="images/rightarrow.gif" />
					<img src="images/f_logo.jpg" />
					<h1>Post Photo to Facebook</h1>
				</div>
	
				<p id="clientCopy">
				<cfif event_info.description NEQ "">
					#event_info.description#
				<cfelse>
					Thank you for your participation!  To view and post your photo to Facebook, please click on "Post Photo to Facebook" above.
				</cfif>
				</p>

				<!--- TODO: Center Like Button --->
				<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.5.1/jquery.min.js"></script>
				<script>!window.jQuery && document.write(unescape('%3Cscript src="js/libs/jquery-1.5.1.min.js"%3E%3C/script%3E'))</script>

				<div id="likeContainer">
				<script src="http://connect.facebook.net/en_US/all.js##xfbml=1"></script><fb:like-box href="#REReplace(likeURL, '/$', '')#" width="250" show_faces="false" stream="false" header="false"></fb:like-box>
				<cfinclude template="includes/like.cfm"></div>
			</div>
			</div>

			<script>		
				$("##photo2fb").click(function () { 
					var #toScript(SESSION.auth_url, "js_auth_url")#;
					//alert(js_auth_url);
					top.location.href=js_auth_url;
				});
			</script>
		</cfif>
--->
		</div>
		</div>
	</body>
	</cfoutput>
</html>

<cfabort>

</cfif>

<!--- Boo7!
<cfdump var="#eventToken#" label="eventToken">
<cfdump var="#clientLicense#" label="clientLicense">

<cfabort> --->
