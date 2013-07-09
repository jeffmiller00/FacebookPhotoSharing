<!---  <cfdump var="#FORM#">
<cfabort> <!---todo: does this belong here?--->

<cftry>

<cfinclude template="includes/config.cfm">

<cfset access_token = FORM.signed_request>
<!--- Get the event location for the client licenses' Photo publisher --->
<!---todo: determine how to get the client_license_id--->
<cfinvoke component="#fbPublisherCom#" method="getEventLocation" returnvariable="event_location_info">
	<!---todo: change session variable--->
	<cfinvokeargument name="client_license_id" value="#SESSION.client_license_id#">
</cfinvoke>

<!--- Request all the user's data ---><!---todo: this probably goes away--->
<!--- <cfhttp method="GET" url="https://graph.facebook.com/me" result="fbConsumerInfo">
	<cfhttpparam type="url" name="access_token" value="#access_token#" />
	<cfhttpparam type="header" name="mimetype" value="text/javascript" />
</cfhttp>
<cfinvoke component="includes/JSON" method="decode" data="#Trim(fbConsumerInfo.Filecontent)#" returnvariable="consumerData"/>
 --->


<!---take the string of data and convert to an array--->
<cfset consumerData=StructNew();>
<cfset consumerData['first_name']="">
<cfset consumerData['last_name']="">
<cfset consumerData['gender']="">
<cfset consumerData['birthday']="">
<cfset consumerData['email']="">
<cfset consumerData['location']="">
<cfset consumerData['id']="">
<cfset consumerData['username']="">
		
			

<cfif IsDefined("consumerData.id")>
	<!--- First try to see if this FB ID has participated with this app --->
	<cfinvoke component="#fbPublisherCom#" method="CheckPrevEntry" returnvariable="consumerInfo">
		<cfinvokeargument name="facebook_ID" value="#consumerData['id']#">
		<!---todo: change session variable--->
		<cfinvokeargument name="client_license_id" value="#SESSION.client_license_id#">
	</cfinvoke>
</cfif>

<cfif consumerInfo.RecordCount >
	<!--- Returning Facebook ID --->
	<!---todo: change session variables--->
	<cfset SESSION.event_token = consumerInfo.event_token_id>
	<cfset SESSION.consumer_id = consumerInfo.consumer_id>
<cfelse>

	<cfquery name="checkReEntry" datasource="#dsn#">
		SELECT * 
		FROM Footprints 
		WHERE TRUE 
			AND event_token_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" maxlength="10" value="#SESSION.event_token#"> <!---todo: change session variables--->
			AND r_elat_id = <cfqueryparam cfsqltype="CF_SQL_BIGINT" value="#SESSION.relats.data#"><!---todo: need to pull relats--->
			AND client_license_id = <cfqueryparam cfsqltype="CF_SQL_BIGINT" value="#SESSION.client_license_id#"> 
			AND sample_flag = <cfqueryparam cfsqltype="CF_SQL_TINYINT" value="#SESSION.event_info.sample_flag#">
	</cfquery>

	<!--- No data RELAT means that this event token has never been through the app --->
	<cfif NOT checkReEntry.RecordCount>
		<!--- Write a footprint for the facebook data --->
		<cfinvoke component="#setComponent#" method="insertFootprint" returnvariable="footprint_id">
			<cfinvokeargument name="event_token_ID" value="#SESSION.event_token#"><!---todo: change session variables--->
			<cfinvokeargument name="r_elat_ID" value="#SESSION.relats.data#">
			<cfinvokeargument name="client_license_ID" value="#SESSION.client_license_id#">
			<cfinvokeargument name="sample_flag" value="#SESSION.event_info.sample_flag#">
		</cfinvoke>
	
		<cfinvoke component="#fbPublisherCom#" method="GetConsumerID" returnvariable="qryConsumerID">
			<cfinvokeargument name="eventTokenID" value="#SESSION.event_token#"><!---todo: change session variables--->
			<cfinvokeargument name="clientLicenseID" value="#SESSION.client_license_id#">
		</cfinvoke>
		<cfset SESSION.consumer_id = qryConsumerID.consumer_ID>
	
		<cfinvoke component="#fbPublisherCom#" method="saveConsumerData" >
			<cfinvokeargument name="consumerID" value="#SESSION.consumer_id#"><!---todo: change session variables--->
			<cfinvokeargument name="dataFootprint" value="#footprint_id#">
			<cfinvokeargument name="consumerData" value="#consumerData#">
		</cfinvoke>

	<cfelse>
	
		<cfinvoke component="#fbPublisherCom#" method="GetConsumerID" returnvariable="qryConsumerID">
			<cfinvokeargument name="eventTokenID" value="#SESSION.event_token#"><!---todo: change session variables--->
			<cfinvokeargument name="clientLicenseID" value="#SESSION.client_license_id#">
		</cfinvoke>
		<cfset SESSION.consumer_id = qryConsumerID.consumer_ID>
	
		<!--- This is a returning consumer --->
		<cfinvoke component="#fbPublisherCom#" method="getFacebookID" returnvariable="FacebookID">
			<cfinvokeargument name="consumer_ID" value="#SESSION.consumer_id#"><!---todo: change session variables--->
			<cfinvokeargument name="client_license_id" value="#SESSION.client_license_id#">
		</cfinvoke>

		<cfif consumerData["id"] NEQ FacebookID>
			<!--- New user, same link so create a viral consumer here --->
			<cfinvoke component="#fbPublisherCom#" method="createViralConsumer" returnvariable="SESSION.event_token" ><!---todo: change session variables--->
				<cfinvokeargument name="parentConsumerID" value="#SESSION.consumer_id#">
			</cfinvoke>
			<cfinvoke component="#fbPublisherCom#" method="GetConsumerID" returnvariable="qryConsumerID">
				<cfinvokeargument name="eventTokenID" value="#SESSION.event_token#"><!---todo: change session variables--->
				<cfinvokeargument name="clientLicenseID" value="#SESSION.client_license_id#">
			</cfinvoke>
			<cfset SESSION.consumer_id = qryConsumerID.consumer_ID>

			<cfinvoke component="#setComponent#" method="insertFootprint" returnvariable="footprint_id">
				<cfinvokeargument name="event_token_ID" value="#SESSION.event_token#"><!---todo: change session variables--->
				<cfinvokeargument name="r_elat_ID" value="#SESSION.relats.viral#">
				<cfinvokeargument name="client_license_ID" value="#SESSION.client_license_id#">
				<cfinvokeargument name="sample_flag" value="#SESSION.event_info.sample_flag#">
			</cfinvoke>

			<cfinvoke component="#setComponent#" method="insertFootprint" returnvariable="footprint_id">
				<cfinvokeargument name="event_token_ID" value="#SESSION.event_token#"><!---todo: change session variables--->
				<cfinvokeargument name="r_elat_ID" value="#SESSION.relats.retrieve#">
				<cfinvokeargument name="client_license_ID" value="#SESSION.client_license_id#">
				<cfinvokeargument name="sample_flag" value="#SESSION.event_info.sample_flag#">
			</cfinvoke>

			<cfinvoke component="#setComponent#" method="insertFootprint" returnvariable="footprint_id">
				<cfinvokeargument name="event_token_ID" value="#SESSION.event_token#"><!---todo: change session variables--->
				<cfinvokeargument name="r_elat_ID" value="#SESSION.relats.data#">
				<cfinvokeargument name="client_license_ID" value="#SESSION.client_license_id#">
				<cfinvokeargument name="sample_flag" value="#SESSION.event_info.sample_flag#">
			</cfinvoke>

			<cfinvoke component="#fbPublisherCom#" method="saveConsumerData" >
				<cfinvokeargument name="consumerID" value="#SESSION.consumer_id#"><!---todo: change session variables--->
				<cfinvokeargument name="dataFootprint" value="#footprint_id#">
				<cfinvokeargument name="consumerData" value="#consumerData#">
			</cfinvoke>
		<cfelse>
			<cfinvoke component="#fbPublisherCom#" method="GetConsumerID" returnvariable="qryConsumerID">
				<cfinvokeargument name="eventTokenID" value="#SESSION.event_token#"><!---todo: change session variables--->
				<cfinvokeargument name="clientLicenseID" value="#SESSION.client_license_id#">
			</cfinvoke>
			<cfset SESSION.consumer_id = qryConsumerID.consumer_ID><!---todo: change session variables--->

			<cfset footprint_id = checkReEntry.footprint_id>
		</cfif>
	</cfif>
</cfif>


<cfinvoke component="#fbPublisherCom#" method="getAlbumID" returnvariable="albumID">
	<cfinvokeargument name="consumer_ID" value="#SESSION.consumer_id#">
	<cfinvokeargument name="client_license_id" value="#SESSION.client_license_id#">
</cfinvoke>

<!--- If the album ID is not found in RCDEA --->
<cfif albumID LTE 0>
	<cfhttp method="POST" url="https://graph.facebook.com/me/albums" result="fbNewAlbumInfo">
		<cfhttpparam type="url" name="access_token" value="#access_token#" />
	 	<cfhttpparam type="url" name="name" value="#SESSION.event_info.Brand_Name# Events" /><!---todo: change session variables--->
		<cfhttpparam type="header" name="mimetype" value="text/javascript" />
	</cfhttp>

	<cfif Find(fbNewAlbumInfo.Responseheader.Status_Code,"200")>
		<cfinvoke component="includes/JSON" method="decode" data="#Trim(fbNewAlbumInfo.Filecontent)#" returnvariable="albumData" />
	
		<cfinvoke component="#setComponent#" method="insertConsumerAnswer" returnvariable="insertComplete">
			<cfinvokeargument name="consumer_ID" value="#SESSION.consumer_id#"><!---todo: change session variables--->
			<cfinvokeargument name="data_element_ID" value="#fb_album_de#">
			<cfinvokeargument name="footprint_ID" value="#footprint_id#">
			<cfinvokeargument name="answer_text" value="#albumData.id#">
		</cfinvoke>
	
		<cfset albumID = albumData.id>
	</cfif>
</cfif>



<cfinvoke component="#fbPublisherCom#" method="getFBphotoID" returnvariable="photoID">
	<cfinvokeargument name="event_photo_id" value="#SESSION.event_info.event_photo_ID#"><!---todo: change session variables--->
	<cfinvokeargument name="event_token_id" value="#SESSION.event_token#"><!---todo: change session variables--->
	<cfinvokeargument name="r_elat_ID" value="#SESSION.relats.share#"><!---todo: change session variables--->
</cfinvoke>

<!--- If the photo ID is not found in RCDEA --->
<cfif photoID LTE 0>

	<cfinvoke component="#fbPublisherCom#" method="getWatermark" returnvariable="wmkInfo">
		<cfinvokeargument name="client_license_id" value="#SESSION.client_license_id#"><!---todo: change session variables--->
	</cfinvoke>



<!--- 
STEPS FOR SAVING PHOTO:
 X Save photo back to original location
 X Update the EP table and the R_EPPE tables' PE_ID
 X Only Watermark if the current PE_ID is "blank.png"

<cfdump var="#wmkInfo.watermark_file_name#">
<cfdump var="#SESSION.event_info.watermark_file_name#">
--->

	<cfif IsDefined("wmkInfo.watermark_file_name") AND wmkInfo.watermark_file_name NEQ "" AND SESSION.event_info.watermark_file_name EQ "blank.png"><!---todo: change session variables--->

<!--- <cfdump var="#Replace(SESSION.event_info.path, '/var/www/html/eshots', publicURL, 'ALL')#?w=#wmkInfo.watermark_file_name#&q=90"> --->

		<cfhttp method="get" 
				url="#Replace(SESSION.event_info.path, '/var/www/html/eshots', publicURL, 'ALL')#?w=#wmkInfo.watermark_file_name#&q=90" 
				path="#GetDirectoryFromPath(SESSION.event_info.path)#" file="#GetFileFromPath(SESSION.event_info.path)#" ><!---todo: change session variables--->

		<cfinvoke component="#fbPublisherCom#" method="setWatermark" >
			<cfinvokeargument name="event_photo_ID" value="#SESSION.event_info.event_photo_ID#"><!---todo: change session variables--->
			<cfinvokeargument name="photo_environment_ID" value="#wmkInfo.photo_environment_ID#">
		</cfinvoke>

	<cfelse>

<!--- <cfdump var="#Replace(SESSION.event_info.path, '/var/www/html/eshots', publicURL, 'ALL')#?q=90"> --->

		<cfhttp method="get" 
				url="#Replace(SESSION.event_info.path, '/var/www/html/eshots', publicURL, 'ALL')#?q=90" 
				path="#GetDirectoryFromPath(SESSION.event_info.path)#" file="#GetFileFromPath(SESSION.event_info.path)#" >
	</cfif>


	<!--- Post the photo to the album --->
	<cfhttp method="POST" url="https://graph.facebook.com/#albumID#/photos" result="fbPhotoInfo">
		<cfhttpparam type="url" name="access_token" value="#access_token#" />
	 	<cfhttpparam type="file" name="source" file="#SESSION.event_info.path#" /><!---todo: change session variables--->
		<cfhttpparam type="header" name="mimetype" value="text/javascript" />
	</cfhttp>
	<cfinvoke component="includes/JSON" method="decode" data="#Trim(fbPhotoInfo.Filecontent)#" returnvariable="photoData" />


	<cfif IsDefined("photoData.error.message") AND Find("120", photoData.error.message) >
		<!--- Post the photo to the account --->
		<cfhttp method="POST" url="https://graph.facebook.com/me/photos" result="fbPhotoInfo">
			<cfhttpparam type="url" name="access_token" value="#access_token#" />
		 	<cfhttpparam type="file" name="source" file="#SESSION.event_info.path#" /><!---todo: change session variables--->
			<cfhttpparam type="header" name="mimetype" value="text/javascript" />
		</cfhttp>
		<cfinvoke component="includes/JSON" method="decode" data="#Trim(fbPhotoInfo.Filecontent)#" returnvariable="photoData" />
	</cfif>


	<cfif Find("200",fbPhotoInfo.Responseheader.Status_Code)>
	
		<cfhttp method="GET" url="https://graph.facebook.com/#photoData.id#" result="fbPhotoInfo">
			<cfhttpparam type="url" name="access_token" value="#access_token#" />
			<cfhttpparam type="header" name="mimetype" value="text/javascript" />
		</cfhttp>
		<cfinvoke component="includes/JSON" method="decode" data="#Trim(fbPhotoInfo.Filecontent)#" returnvariable="photoData" />

		<cfinvoke component="#setComponent#" method="insertFootprint" returnvariable="footprint_id">
			<cfinvokeargument name="event_token_ID" value="#SESSION.event_token#"><!---todo: change session variables--->
			<cfinvokeargument name="r_elat_ID" value="#SESSION.relats.share#"><!---todo: change session variables--->
			<cfinvokeargument name="client_license_ID" value="#SESSION.client_license_id#"><!---todo: change session variables--->
			<cfinvokeargument name="sample_flag" value="#SESSION.event_info.sample_flag#"><!---todo: change session variables--->
		</cfinvoke>

		<cfquery name="qryRFPinsert" datasource="#dsn#">
			INSERT INTO efn.R_Footprint_Photo (footprint_ID, event_photo_ID) VALUES (#footprint_id#, #SESSION.event_info.event_photo_ID#);<!---todo: change session variables--->
		</cfquery>

		<cfinvoke component="#setComponent#" method="insertConsumerAnswer" returnvariable="insertComplete">
			<cfinvokeargument name="consumer_ID" value="#SESSION.consumer_id#"><!---todo: change session variables--->
			<cfinvokeargument name="data_element_ID" value="#fb_photo_de#">
			<cfinvokeargument name="footprint_ID" value="#footprint_id#">
			<cfinvokeargument name="answer_text" value="#photoData.id#">
		</cfinvoke>
	</cfif>

<cfelse>

	<cfhttp method="GET" url="https://graph.facebook.com/#photoID#" result="fbPhotoInfo">
		<cfhttpparam type="url" name="access_token" value="#access_token#" />
		<cfhttpparam type="header" name="mimetype" value="text/javascript" />
	</cfhttp>
	<cfinvoke component="includes/JSON" method="decode" data="#Trim(fbPhotoInfo.Filecontent)#" returnvariable="photoData" />

</cfif>



<!DOCTYPE html>
<html lang="en">
	<head>
		<title>eshots Facebook Publisher</title>
		<link href="http://eshots.com/fb/publisher/css/base.css" />
		
		<style>
			body {
				color: #3b5998;
				font-family: "lucida grande",tahoma,verdana,arial,sans-serif;
			}
			
			img {
				display: inline-block;
			}
			
			#clientCopy {
				padding-bottom: 50px;
				border-bottom: 1px solid #3b5998; 
			}
			
			#likeContainer {
				width: 640px; 
				border: 2px solid #3b5998;
				margin-bottom: 25px;
			}
		</style>

		<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.5.1/jquery.min.js"></script>
		<script>!window.jQuery && document.write(unescape('%3Cscript src="js/libs/jquery-1.5.1.min.js"%3E%3C/script%3E'))</script>
		
		<script type="text/javascript" src="includes/fancybox/jquery.fancybox-1.3.4.pack.js"></script>
		
		<link rel="stylesheet" href="includes/fancybox/jquery.fancybox-1.3.4.css" type="text/css" media="screen" />

		<cfif server_location NEQ "Staging">
			<cfinclude template="includes/analytics.cfm">
		</cfif>

		<script>
			jQuery(document).ready(function() {

				$("#fancyLikeContainer").fancybox({
					'overlayOpacity'	: 0.8,
					'overlayColor'		: '#fff',
					'showCloseButton'	: false
				});
				$("#fancyLikeContainer").trigger('click');
			});
		</script>
	</head>
	
	<body>

		<cfoutput>

		<cfinvoke component="#fbPublisherCom#" method="getLikeURL" returnvariable="likeURL">
			<cfinvokeargument name="client_license_id" value="#SESSION.client_license_id#"><!---todo: change session variables--->
		</cfinvoke>

		<div id="likeContainer"><cfinclude template="includes/like.cfm"></div>

		<cfif IsDefined("photoData.link")>
			<a href="#photoData.link#" target="_top"><img src="#photoData.images[1].source#" /></a>

			<br /><br />
			<p id="clientCopy">
			<cfif event_info.description NEQ "">
				#event_info.description#
			<cfelse>
				Click the photo above to comment on your photo and tag your friends!
			</cfif>
			</p>
			<cfif server_location EQ "Staging">
				<a id="fancyLikeContainer" href="http://staging.eshots.com/fb/publisher/includes/fancyLike.cfm" style="display:none">&nbsp;</a>
			<cfelse>
				<a id="fancyLikeContainer" href="http://eshots.com/fb/publisher/includes/fancyLike.cfm" style="display:none">&nbsp;</a>
			</cfif>

		<cfelse>
			<cfmail to="errors@eshots.com, jmiller@eshots.com" from="error@eshots.com" subject="Media Publisher Error (#server_location#)" type="HTML">
				Error Posting to Facebook, from #CGI.CF_TEMPLATE_PATH#
				<hr />
				Response from Facebook: <br />
				<cfif IsDefined("fbPhotoInfo.Filecontent")>
					<cfdump var="#fbPhotoInfo.Filecontent#">
				<cfelse>
					fbPhotoInfo.Filecontent undefined.<br />
				</cfif>
				<br /><br />
				Translated as:  <br />
				<cfif IsDefined("photoData")>
					<cfdump var="#photoData#">
				<cfelse>
					photoData undefined.<br />
				</cfif>
				<br /><br />
				Application Info:  <br />
				<cfif IsDefined("APPLICATION")>
					<cfdump var="#APPLICATION#">
				<cfelse>
					application undefined.<br />
				</cfif>
				Consumer Info:  <br />
				<cfif IsDefined("SESSION")><!---todo: change session variables--->
					<cfdump var="#SESSION#">
				<cfelse>
					SESSION undefined.<br /><!---todo: change session variables--->
				</cfif>
			</cfmail>
			<br /><br />
			<p id="clientCopy">
				There was an error posting your photo.  For additional help, please contact <a href="mailto:customer_support@eshots.com" style="color: ##3b5998;">customer_support@eshots.com</a>.
			</p>
		</cfif>




		</cfoutput>
<!--- 
		<div id="results"></div>

        <div id="fb-root"></div>
		<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.5.1/jquery.min.js"></script>
		<script>!window.jQuery && document.write(unescape('%3Cscript src="js/libs/jquery-1.4.2.min.js"%3E%3C/script%3E'))</script>
		<script src="http://connect.facebook.net/en_US/all.js#xfbml=1"></script>
        <script>

			<cfoutput>var #toScript(APPLICATION.appID, "js_appID")#;</cfoutput>
            window.fbAsyncInit = function() {
                FB.init({appId: js_appID, status: true, cookie: true, xfbml: true});
            };
            (function() {
                var e = document.createElement('script');
                e.type = 'text/javascript';
                e.src = document.location.protocol +
                    '//connect.facebook.net/en_US/all.js';
                e.async = true;
                document.getElementById('fb-root').appendChild(e);
            }());


			$(document).ready(function() {
				alert("Stop 1");

				FB.getLoginStatus(function(response) {
					if (response.session) {
						var messageTxt= "Caption from JS";
						var sourceURL = "@http://media.eshots.com/photos/11374/108121/c437095e-d1e0-4841-b166-a383ae76357a/7c994daf-4ba2-4965-a9e6-cedf80f3a0f5.JPG";

						alert("logged in and connected user, someone you know");

						FB.api('/me/photos', 'post', { source: sourceURL, message: messageTxt }, function(response) {
						  if (!response || response.error) {
						    alert('Error occured' + response.error.message);
						  } else {
						    alert('Post ID: ' + response.id);
						  }
						});

					} else {
						alert("no user session available, someone you dont know");
					}
				});

//				FB.getLoginStatus(function(response) {
//					alert("Stop 2");
//					if (response.session) {
//						alert("Stop 3");

//						FB.api('/me/photos', 'post', { source: sourceURL, message=messageTxt }, function(response) {
//						  if (!response || response.error) {
//						    alert('Error occured');
//						  } else {
//						    alert('Post ID: ' + response.id);
//						  }
//						});
//					
//					}
//				});
//				streamPublish("Jeff", "http://google.com", "http://staging.eshots.com/photos/11374/108118/64e11709-6855-4f7a-83c8-a65d3fe61a45/18cc50b1-c1f8-4b99-aa1a-c42d1a8e81c6.JPG?w=CheggWm2.png", "Caption", "Description", "Message");

			});


            //stream publish method
            function streamPublish(name, link, pictureURL, caption, description, message){
                FB.ui(
                {
                    method: 'stream.publish',
				     name: name,
				     link: link,
				     picture: pictureURL,
				     caption: caption,
				     description: description,
				     message: message
				},
				   function(response) {
				     if (response && response.post_id) {
				       alert('Post was published.');
				     } else {
				       alert('Post was not published.');
				     }
				   });
 
            }
            function showStream(){
                FB.api('/me', function(response) {
                    //console.log(response.id);
                    streamPublish('Event Photo Name Here', 'http://wwww.insert link here.com', 'http://www.picture url here.jpg', 'Caption Here', 'Description Here', 'Message Here');
                });
            }
 
            function like(){
                alert("sweet");
            }
        </script>
 --->
    </body>
</html>


<cfcatch>
			<cfmail to="errors@eshots.com, jmiller@eshots.com" from="error@eshots.com" subject="Media Publisher Error (#server_location#)" type="HTML">
				Error with the eshots Media Publisher Application, from #CGI.CF_TEMPLATE_PATH#
				<hr />
				<cfif IsDefined('URL')>
					<cfdump var="#URL#">
					<hr />
				</cfif>
				<cfif IsDefined('consumerData')>
					<cfdump var="#consumerData#">
					<hr />
				</cfif>
				Application Info:  <br />
				<cfif IsDefined("APPLICATION")>
					<cfdump var="#APPLICATION#">
				<cfelse>
					application undefined.<br />
				</cfif>
					<hr />
				Consumer Info:  <br />
				<cfif IsDefined("SESSION")>
					<cfdump var="#SESSION#">
				<cfelse>
					SESSION undefined.<br />
				</cfif>
				<cfdump var="#cfcatch#">
			</cfmail>

			<!DOCTYPE html>
			<html lang="en">
				<head>
					<title>eshots Facebook Publisher</title>
					<link href="http://eshots.com/fb/publisher/css/base.css" />
					
					<style>
						body {
							color: #3b5998;
							font-family: "lucida grande",tahoma,verdana,arial,sans-serif;
						}
						
						img {
							display: inline-block;
						}
						
						#clientCopy {
							padding-bottom: 50px;
							border-bottom: 1px solid #3b5998; 
						}
						
						#likeContainer {
							width: 640px; 
							border: 2px solid #3b5998;
							margin-bottom: 25px;
						}
					</style>
			
					<cfinclude template="includes/analytics.cfm">
				</head>
				
				<body>
						<br /><br />
						<p id="clientCopy">
							There was an error posting your photo.  For additional help, please contact <a href="mailto:customer_support@eshots.com" style="color: ##3b5998;">customer_support@eshots.com</a>.
						</p>
			    </body>
			</html>
</cfcatch>
</cftry> --->