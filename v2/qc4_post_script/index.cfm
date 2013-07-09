<cfparam name="DSN" default="efn" />
<cfparam name="DSN_READONLY" default="efn_readonly" />
<cfparam name="DO_FACEBOOK_POST" default="true" />
<cfparam name="DO_TWITTER_POST" default="false" />
<cfparam name="EMAIL_DE" default="4" />
<cfparam name="FACEBOOK_ID_DE" default="10230" />
<cfparam name="ACCESS_TOKEN_DE" default="10899" />

<!--- 1) Get consumers that have record in Social_Posts as well as their latest email and latest access token --->
<cfquery name="qryConsumersToPost" datasource="#DSN_READONLY#">
	SELECT 		SP.social_post_ID,
				SP.consumer_ID,
				SP.footprint_ID,
				RCET.event_token_ID,
				CASE WHEN E.name = "default" THEN U.event_name ELSE E.name END AS "EventName",
				(SELECT answer_text
					FROM R_Consumer_Data_Element_Answer
					WHERE consumer_ID = SP.consumer_ID AND data_element_ID = "#EMAIL_DE#"
					ORDER BY create_DTM DESC, r_cdea_ID DESC
					LIMIT 1) AS Email,
				(SELECT answer_text
					FROM R_Consumer_Data_Element_Answer
					WHERE consumer_ID = SP.consumer_ID AND data_element_ID = "#FACEBOOK_ID_DE#"
					ORDER BY create_DTM DESC, r_cdea_ID DESC
					LIMIT 1) AS FacebookId,
				(SELECT answer_text
					FROM R_Consumer_Data_Element_Answer
					WHERE consumer_ID = SP.consumer_ID AND data_element_ID = "#ACCESS_TOKEN_DE#"
					ORDER BY create_DTM DESC, r_cdea_ID DESC
					LIMIT 1) AS AccessToken,
				CONCAT("http://media.eshots.com", EP.path) AS EventPhotoURL,
				SP.message,
				SP.image,
				SP.event_photo_ID,
				SP.question_ID,
				SP.social_network_ID
	FROM 		Social_Posts SP
	 JOIN 		R_Consumer_Event_Token RCET ON (SP.consumer_ID = RCET.consumer_ID)
	 LEFT JOIN 	Event_Photos EP ON (SP.event_photo_ID = EP.event_photo_ID)
	 LEFT JOIN	Upload_Footprints UF ON (SP.footprint_ID = UF.footprint_ID)
	 LEFT JOIN	Uploads U ON (UF.upload_ID = U.upload_ID)
	 LEFT JOIN	Events E ON (U.event_ID = E.event_ID)
	WHERE 		(SP.sent_flag IS NULL OR SP.sent_flag <> 1)
</cfquery>

<!--- DEBUGGING --->
<cfdump var="#qryConsumersToPost#" label="qryConsumersToPost">
<hr />


<!--- 2) Loop over consumer list for each post --->
<cfloop query="qryConsumersToPost">
	<cfset socialPostId = qryConsumersToPost.social_post_ID />
	<cfset consumerId = qryConsumersToPost.consumer_ID />
	<cfset consumerFootprintId = qryConsumersToPost.footprint_ID />
	<cfset consumerEventTokenId = qryConsumersToPost.event_token_ID />
	<cfset consumerEventName = qryConsumersToPost.EventName />
	<cfset consumerEmail = qryConsumersToPost.Email />
	<cfset consumerFacebookId = qryConsumersToPost.FacebookId />
	<cfset consumerAccessToken = qryConsumersToPost.AccessToken />
	
	<!--- DEBUGGING 
		<strong style="color:blue;">SOCIAL POST ID:</strong> <cfdump var="#socialPostId#"><br/>
		<strong style="color:blue;">CONSUMER ID:</strong> <cfdump var="#consumerId#"><br/>
		<strong style="color:blue;">EVENT TOKEN:</strong> <cfdump var="#consumerEventTokenId#"><br/>
		<strong style="color:blue;">EVENT NAME:</strong> <cfdump var="#consumerEventName#"><br/>
		<strong style="color:blue;">FACEBOOK ID:</strong> <cfdump var="#consumerFacebookId#"><br/>
		<strong style="color:blue;">ACCESS TOKEN:</strong> <cfdump var="#consumerAccessToken#"><br/>
		<strong style="color:blue;">EMAIL:</strong> <cfdump var="#consumerEmail#"><br/>
		<br/>
	--->
	
	<!--- 3) If the record is tied to a consumer that has an access token, post --->
	<cfif LEN(consumerAccessToken) >

		<!--- 3a) Post the message and/or image to Facebook --->
		<cfset event_photo_url = qryConsumersToPost.EventPhotoURL />
		<cfset message = qryConsumersToPost.message />
		<cfset image = qryConsumersToPost.image />
		<cfset event_photo_ID = qryConsumersToPost.event_photo_ID />
		<cfset question_ID = qryConsumersToPost.question_ID />
		<cfset social_network_ID = qryConsumersToPost.social_network_ID />
		
		<!--- DEBUGGING 
			<strong style="color:blue;">MESSAGE:</strong> <cfdump var="#message#"><br/>
			<strong style="color:blue;">IMAGE:</strong> <cfdump var="#image#"><br/>
			<strong style="color:blue;">EVENT PHOTO ID:</strong> <cfdump var="#event_photo_ID#"><br/>
			<strong style="color:blue;">EVENT PHOTO URL:</strong> <cfdump var="#event_photo_url#"><br/>
			<strong style="color:blue;">QUESTION ID:</strong> <cfdump var="#question_ID#"><br/>
			<strong style="color:blue;">SOCIAL NETWORK ID:</strong> <cfdump var="#social_network_ID#"><br/>
		--->
		
		<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.6.1/jquery.min.js" type="text/javascript"></script>
	   	<script type="text/javascript">
			var social_post_id = <cfif LEN(socialPostId)><cfoutput>"#socialPostId#"</cfoutput><cfelse>null</cfif>;
			var consumer_id = <cfif LEN(consumerId)><cfoutput>"#consumerId#"</cfoutput><cfelse>null</cfif>;
			var footprint_id = <cfif LEN(consumerFootprintId)><cfoutput>"#consumerFootprintId#"</cfoutput><cfelse>null</cfif>;
			var social_network_id = <cfif LEN(social_network_ID)><cfoutput>"#social_network_ID#"</cfoutput><cfelse>null</cfif>;
			var doFacebookPost = <cfoutput>"#DO_FACEBOOK_POST#"</cfoutput>;
			var doTwitterPost = <cfoutput>"#DO_TWITTER_POST#"</cfoutput>;
			
			/* ********* FACEBOOK POSTING ********* 
				FACEBOOK GRAPH API INFO
			facebook user id:	1544870917
			access token:		AAABwonBZBtGkBAN0po2lPQrxGkOhZBZAL0JBTDS1eloGM38qKiMBDroZCoWqA6yVhGjCfp0IJ39oZCroosMoJFkhB9507ZBDB3omtw45Nsm0qLtLCpqx5a
			https://graph.facebook.com/YOUR_USER_ID/feed
				access_token=YOUR_ACCESS_TOKEN
				&message=YOUR_MESSAGE
				&picture=YOUR_PICTURE_URL
				&link=YOUR_LINK
				&name=YOUR_LINK_NAME
				&caption=YOUR_CAPTION
			*/
			if (social_network_id == 1 && doFacebookPost) {
				var fb_failedConsumerIds = [];  // Consumer IDs that failed and should receive the email
				
				// Facebook : Load local data from CF Query
				var fb_user_id = <cfif LEN(consumerFacebookId)><cfoutput>"#consumerFacebookId#"</cfoutput><cfelse>null</cfif>;
				var fb_access_token = <cfif LEN(consumerAccessToken)><cfoutput>"#consumerAccessToken#"</cfoutput><cfelse>null</cfif>;
				var fb_message = <cfif LEN(message)><cfoutput>"#message#"</cfoutput><cfelse>null</cfif>;
				var fb_link_name = <cfif LEN(consumerEventName)><cfoutput>"#consumerEventName#"</cfoutput><cfelse>" "</cfif>;;
				var fb_picture = <cfif LEN(image)><cfoutput>"#image#"</cfoutput><cfelse>null</cfif>;
				if (fb_picture == null) { fb_picture = <cfif LEN(event_photo_url)><cfoutput>"#event_photo_url#"</cfoutput><cfelse>null</cfif>; }
				var fb_link = <cfif LEN(image)><cfoutput>"#image#"</cfoutput><cfelse>null</cfif>;
				if (fb_link == null) { fb_link = <cfif LEN(event_photo_url)><cfoutput>"#event_photo_url#"</cfoutput><cfelse>null</cfif>; }
				var fb_source = null;
				var fb_caption = null;
				var fb_description = null;
				
				// Facebook : Build data object based on present variables
				var fb_data = {};
				if (fb_access_token != null) { fb_data["access_token"] = fb_access_token; }
				if (fb_message != null) { fb_data["message"] = fb_message; }
				if (fb_picture != null) { fb_data["picture"] = fb_picture; }
				if (fb_link_name != null) { fb_data["name"] = fb_link_name; }
				if (fb_link != null) { fb_data["link"] = fb_link; }
				if (fb_source != null) { fb_data["source"] = fb_source; }
				if (fb_caption != null) { fb_data["caption"] = fb_caption; }
				if (fb_description != null) { fb_data["description"] = fb_description; }
				//console.log("FACEBOOK DATA: " + JSON.stringify(fb_data));
				
				// Do posting
				$.ajax({
					url: "https://graph.facebook.com/" + fb_user_id + "/feed",
					data: fb_data,
					type: "POST",
					cache: false,
					dataType: "html",
					success: function(data) {
						<!--- 3b) If post was successful, update sent flag --->			
						var urlVars = "?action=0&spid=" + <cfoutput>"#socialPostId#"</cfoutput>;
						$.ajax({
						 	url: "qc4_ws.cfm" + urlVars,
						 	type: "GET",
						 	data: {},
						 	cache: false,
						 	dataType: "json",
						 	success: function(data) {
						 		//alert(true);
						 		console.log("SOCIAL POST SENT: " + social_post_id);
						 	},
						 	error: function(request, status, error) {
						 		// alert(request.responseText.replace(/^\s\s*/, '').replace(/\s\s*$/, ''));
						 	}
						});
					},
					error: function(request) {
						//alert(request.responseText.replace(/^\s\s*/, '').replace(/\s\s*$/, ''));
						//alert("BAD");
						
						<!--- 3c) If post was unsuccesful, insert a blank access code in RCDEA for that consumer --->
						var urlVars = "?action=1&cid=" + <cfoutput>"#consumerId#"</cfoutput> + "&fid=" + <cfoutput>"#consumerFootprintId#"</cfoutput>;
						$.ajax({
						 	url: "qc4_ws.cfm" + urlVars,
						 	type: "GET",
						 	data: {},
						 	cache: false,
						 	dataType: "json",
						 	success: function(data) {
						 		//alert(true);
						 		console.log("ACCESS TOKEN EMPTIED");
						 	},
						 	error: function(request, status, error) {
						 		// alert(request.responseText.replace(/^\s\s*/, '').replace(/\s\s*$/, ''));
						 	}
						});
					}
				});
			}	
		</script>
	</cfif>
</cfloop>