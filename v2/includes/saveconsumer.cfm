<!---take the string of data and convert to an array--->

<cfparam name="URL.first_name" default="">
<cfparam name="URL.last_name" default="">
<cfparam name="URL.gender" default="">
<cfparam name="URL.email" default="">
<cfparam name="URL.location" default="">
<cfparam name="URL.username" default="">


<cfset consumerData=StructNew()>
<cfset consumerData['first_name']="#URL.first_name#">
<cfset consumerData['last_name']="#URL.last_name#">
<cfset consumerData['gender']="#URL.gender#">
<cfset consumerData['birthday']="#URL.birthday#">
<cfset consumerData['email']="#URL.email#">
<cfset consumerData['location']="#URL.location#">
<cfset consumerData['id']="#URL.id#">
<cfset consumerData['username']="#URL.username#">	

<cfset fbPublisherCom = "FacebookPublisher">
<cfset read_dsn = "efn_readonly">
<cfset publicURL = "http://media.eshots.com">
<cfset access_token = URL.access_token>

<cfif IsDefined('URL.debug')>
	<html><body>
</cfif>

<cftry>

	<!--- Get the event location for the client licenses' Photo publisher --->
	<cfinvoke component="#fbPublisherCom#" method="getEventLocation" returnvariable="event_location_info">
		<cfinvokeargument name="client_license_id" value="#clientLicense#">
	</cfinvoke>

	<cfif IsDefined('URL.debug')>
		<cfdump var="Line: 38">
		<cfdump var="#event_location_info#" label="event_location_info">
	</cfif>

	<cfif IsDefined("consumerData.id")>
		<!--- First try to see if this FB ID has participated with this app --->
		<cfinvoke component="#fbPublisherCom#" method="CheckPrevEntry" returnvariable="consumerInfo">
			<cfinvokeargument name="facebook_ID" value="#consumerData['id']#">
			<cfinvokeargument name="client_license_id" value="#clientLicense#">
		</cfinvoke>

			<cfif IsDefined('URL.debug')>
		<cfdump var="Line: 50">
				<cfdump var="#consumerInfo#" label="consumerInfo">
			</cfif>

		<cfif consumerInfo.RecordCount >
			<!--- Returning Facebook ID --->
			<cfset eventToken = consumerInfo.event_token_id>
			<cfset consumerId = consumerInfo.consumer_id>
			<cfset footprintId = consumerInfo.footprint_Id>
		<cfelse>

			<!--- I can't find the facebook ID for this client license, has this event token been used? --->
			<cfquery name="qryCheckET" datasource="#read_dsn#">
				SELECT * 
				FROM Footprints 
				WHERE TRUE 
					AND event_token_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" maxlength="10" value="#eventToken#"> 
					AND r_elat_id = <cfqueryparam cfsqltype="CF_SQL_BIGINT" value="#relats.data#"> 
			</cfquery>

			<!--- No data RELAT footprint means that this event token has never been through the app --->
			<cfif NOT qryCheckET.RecordCount>
				<!--- Write a footprint for the facebook data --->
				<cfinvoke component="#setComponent#" method="insertFootprint" returnvariable="footprintId">
					<cfinvokeargument name="event_token_ID" value="#eventToken#">
					<cfinvokeargument name="r_elat_ID" value="#relats.data#">
					<cfinvokeargument name="client_license_ID" value="#clientLicense#">
					<cfinvokeargument name="sample_flag" value="#event_info.sample_flag#">
				</cfinvoke>

				<cfif IsDefined('URL.debug')>
		<cfdump var="Line: 81">
					<cfdump var="#footprintId#" label="footprintId">
				</cfif>
	
				<cfinvoke component="#fbPublisherCom#" method="GetConsumerID" returnvariable="qryConsumerID">
					<cfinvokeargument name="eventTokenID" value="#eventToken#">
					<cfinvokeargument name="clientLicenseID" value="#clientLicense#">
				</cfinvoke>
				<cfset consumerId = qryConsumerID.consumer_ID>

				<cfif IsDefined('URL.debug')>
		<cfdump var="Line: 92">
					<cfdump var="#qryConsumerID#" label="qryConsumerID">
				</cfif>
	
				<cfinvoke component="#fbPublisherCom#" method="saveConsumerData" >
					<cfinvokeargument name="consumerID" value="#consumerId#">
					<cfinvokeargument name="dataFootprint" value="#footprintId#">
					<cfinvokeargument name="consumerData" value="#consumerData#">
				</cfinvoke>

				<cfif IsDefined('URL.debug')>
		<cfdump var="Line: 103">
					<cfdump var="#saveConsumerData#" label="saveConsumerData">
				</cfif>

			<cfelse>

				<cfinvoke component="#fbPublisherCom#" method="GetConsumerID" returnvariable="qryParentConsumerID">
					<cfinvokeargument name="eventTokenID" value="#eventToken#">
					<cfinvokeargument name="clientLicenseID" value="#clientLicense#">
				</cfinvoke>
				<cfset parentConsumerID = qryParentConsumerID.consumer_ID>

				<cfif IsDefined('URL.debug')>
		<cfdump var="Line: 116">
					<cfdump var="#qryParentConsumerID#" label="qryParentConsumerID">
				</cfif>

				<!--- The event token has been used for this client license, thus we have to create a viral consumer --->
				<!--- New user, same link so create a viral consumer here --->
				<cfinvoke component="#fbPublisherCom#" method="createViralConsumer" returnvariable="eventToken" >
					<cfinvokeargument name="parentConsumerID" value="#parentConsumerID#">
				</cfinvoke>

				<cfif IsDefined('URL.debug')>
		<cfdump var="Line: 127">
					<cfdump var="#eventToken#" label="eventToken">
				</cfif>

				<cfinvoke component="#fbPublisherCom#" method="GetConsumerID" returnvariable="qryConsumerID">
					<cfinvokeargument name="eventTokenID" value="#eventToken#">
					<cfinvokeargument name="clientLicenseID" value="#clientLicense#">
				</cfinvoke>
				<cfset consumerId = qryConsumerID.consumer_ID>

				<cfif IsDefined('URL.debug')>
		<cfdump var="Line: 138">
					<cfdump var="#qryConsumerID#" label="qryConsumerID">
				</cfif>

				<cfinvoke component="#setComponent#" method="insertFootprint" returnvariable="footprintId">
					<cfinvokeargument name="event_token_ID" value="#eventToken#">
					<cfinvokeargument name="r_elat_ID" value="#relats.viral#">
					<cfinvokeargument name="client_license_ID" value="#clientLicense#">
					<cfinvokeargument name="sample_flag" value="#event_info.sample_flag#">
				</cfinvoke>

				<cfif IsDefined('URL.debug')>
		<cfdump var="Line: 150">
					<cfdump var="#footprintId#" label="footprintId">
				</cfif>

				<cfinvoke component="#setComponent#" method="insertFootprint" returnvariable="footprintId">
					<cfinvokeargument name="event_token_ID" value="#eventToken#">
					<cfinvokeargument name="r_elat_ID" value="#relats.retrieve#">
					<cfinvokeargument name="client_license_ID" value="#clientLicense#">
					<cfinvokeargument name="sample_flag" value="#event_info.sample_flag#">
				</cfinvoke>

				<cfif IsDefined('URL.debug')>
		<cfdump var="Line: 162">
					<cfdump var="#footprintId#" label="footprintId">
				</cfif>
				
				<cfinvoke component="#setComponent#" method="insertFootprint" returnvariable="footprintId">
					<cfinvokeargument name="event_token_ID" value="#eventToken#">
					<cfinvokeargument name="r_elat_ID" value="#relats.data#">
					<cfinvokeargument name="client_license_ID" value="#clientLicense#">
					<cfinvokeargument name="sample_flag" value="#event_info.sample_flag#">
				</cfinvoke>

				<cfif IsDefined('URL.debug')>
		<cfdump var="Line: 174">
					<cfdump var="#footprintId#" label="footprintId">
				</cfif>

				<cfinvoke component="#fbPublisherCom#" method="saveConsumerData" >
					<cfinvokeargument name="consumerID" value="#consumerId#">
					<cfinvokeargument name="dataFootprint" value="#footprintId#">
					<cfinvokeargument name="consumerData" value="#consumerData#">
				</cfinvoke>

				<cfif IsDefined('URL.debug')>
		<cfdump var="Line: 185">
					<cfdump var="#saveConsumerData#" label="saveConsumerData">
				</cfif>				
				
			</cfif>
		</cfif>
		<!--- Consumer data portion complete. --->


		<!--- Begin consumer album portion --->
		<cfinvoke component="#fbPublisherCom#" method="getAlbumID" returnvariable="albumID">
			<cfinvokeargument name="consumer_ID" value="#consumerId#">
			<cfinvokeargument name="client_license_id" value="#clientLicense#">
		</cfinvoke>

		<cfif IsDefined('URL.debug')>
		<cfdump var="Line: 202">
			<cfdump var="#consumerId#">
			<cfdump var="#clientLicense#">
			<cfdump var="#albumID#" label="albumID">
		</cfif>	

		<!--- If the album ID is not found in RCDEA --->
		<cfif albumID LTE 0>
			<cfset albumCreated = FALSE>
			<cfset attemptCount = 0>
			<cfloop condition="NOT albumCreated">
				<cfhttp method="POST" url="https://graph.facebook.com/me/albums" result="fbNewAlbumInfo">
					<cfhttpparam type="url" name="access_token" value="#access_token#" />
				 	<cfhttpparam type="url" name="name" value="#event_info.Brand_Name# Events" />
					<cfhttpparam type="header" name="mimetype" value="text/javascript" />
				</cfhttp>

				<cfif Find(fbNewAlbumInfo.Responseheader.Status_Code,"200")>
					<cfinvoke component="JSON" method="decode" data="#Trim(fbNewAlbumInfo.Filecontent)#" returnvariable="albumData" />

					<cfinvoke component="#setComponent#" method="insertConsumerAnswer" returnvariable="insertComplete">
						<cfinvokeargument name="consumer_ID" value="#consumerId#">
						<cfinvokeargument name="data_element_ID" value="#fb_album_de#">
						<cfinvokeargument name="footprint_ID" value="#footprintId#">
						<cfinvokeargument name="answer_text" value="#albumData.id#">
					</cfinvoke>

					<cfif IsDefined('URL.debug')>
						<cfdump var="Line: 228">
						<cfdump var="#insertComplete#" label="insertComplete">
					</cfif>	

					<cfset albumID = albumData.id>
					<cfset albumCreated = TRUE>
				<cfelse>
					<cfset attemptCount = attemptCount + 1>
					<cfif attemptCount GTE 3>
						<cfset albumCreated = TRUE>
					<cfelse>
						<cfset albumCreated = FALSE>
					</cfif>
				</cfif>
			</cfloop>
		</cfif>



		<!--- Begin consumer photo portion --->
		<cfinvoke component="#fbPublisherCom#" method="getFBphotoID" returnvariable="photoID">
			<cfinvokeargument name="event_photo_id" value="#event_info.event_photo_ID#">
			<cfinvokeargument name="event_token_id" value="#eventToken#">
			<cfinvokeargument name="r_elat_ID" value="#relats.share#">
		</cfinvoke>

		<cfif IsDefined('URL.debug')>
		<cfdump var="Line: 255">
			<cfdump var="#photoID#" label="photoID">
			<cfdump var="#eventToken#" label="eventToken">
			<cfdump var="#relats#" label="relats">
			<cfdump var="#event_info#" label="event_info">
		</cfif>	

		<!--- If the photo ID is not found in RCDEA --->
		<cfif photoID LTE 0>
			<cfinvoke component="#fbPublisherCom#" method="getWatermark" returnvariable="wmkInfo">
				<cfinvokeargument name="client_license_id" value="#clientLicense#">
			</cfinvoke>
			
			<cfif IsDefined('URL.debug')>
		<cfdump var="Line: 266">
				<cfdump var="#wmkInfo#" label="wmkInfo">
			</cfif>				
			
			<!--- 
			STEPS FOR SAVING PHOTO:
			 X Save photo back to original location
			 X Update the EP table and the R_EPPE tables' PE_ID
			 X Only Watermark if the current PE_ID is "blank.png"
			
			<cfdump var="#wmkInfo.watermark_file_name#">
			<cfdump var="#event_info.watermark_file_name#">
			--->

			<cfif IsDefined("wmkInfo.watermark_file_name") AND wmkInfo.watermark_file_name NEQ "" AND event_info.watermark_file_name EQ "blank.png">
				<!--- <cfdump var="#Replace(event_info.path, '/var/www/html/eshots', publicURL, 'ALL')#?w=#wmkInfo.watermark_file_name#&q=90"> --->
				<cfhttp method="get" 
						url="#Replace(event_info.path, '/var/www/html/eshots', publicURL, 'ALL')#?w=#wmkInfo.watermark_file_name#&q=90" 
						path="#GetDirectoryFromPath(event_info.path)#" file="#GetFileFromPath(event_info.path)#" >
		
				<cfinvoke component="#fbPublisherCom#" method="setWatermark" >
					<cfinvokeargument name="event_photo_ID" value="#event_info.event_photo_ID#">
					<cfinvokeargument name="photo_environment_ID" value="#wmkInfo.photo_environment_ID#">
				</cfinvoke>
				
				<cfif IsDefined('URL.debug')>
		<cfdump var="Line: 292">
					<cfdump var="#setWatermark#" label="setWatermark">
				</cfif>		
								
			<cfelse>
				<!--- <cfdump var="#Replace(event_info.path, '/var/www/html/eshots', publicURL, 'ALL')#?q=90"> --->
				<cfhttp method="get" 
						url="#Replace(event_info.path, '/var/www/html/eshots', publicURL, 'ALL')#?q=90" 
						path="#GetDirectoryFromPath(event_info.path)#" file="#GetFileFromPath(event_info.path)#" >
			</cfif>

			<cfset photoCreated = FALSE>
			<cfset attemptCount = 0>
			<cfloop condition="NOT photoCreated">
				<!--- Post the photo to the album --->
				<cfhttp method="POST" url="https://graph.facebook.com/#albumID#/photos" result="fbPhotoInfo">
					<cfhttpparam type="url" name="access_token" value="#access_token#" />
				 	<cfhttpparam type="file" name="source" file="#event_info.path#" />
					<cfhttpparam type="header" name="mimetype" value="text/javascript" />
				</cfhttp>

				<cfif Find(fbPhotoInfo.Responseheader.Status_Code,"200")>
					<cfinvoke component="JSON" method="decode" data="#Trim(fbPhotoInfo.Filecontent)#" returnvariable="photoData" />
					
					<cfif IsDefined('URL.debug')>
		<cfdump var="Line: 317">
						<cfdump var="#photoData#" label="photoData">
					</cfif>	
					
					<cfinvoke component="#setComponent#" method="insertFootprint" returnvariable="footprintId">
						<cfinvokeargument name="event_token_ID" value="#eventToken#">
						<cfinvokeargument name="r_elat_ID" value="#relats.share#">
						<cfinvokeargument name="client_license_ID" value="#clientLicense#">
						<cfinvokeargument name="sample_flag" value="#event_info.sample_flag#">
					</cfinvoke>

					<cfif IsDefined('URL.debug')>
		<cfdump var="Line: 3829">
						<cfdump var="#footprintId#" label="footprintId">
					</cfif>	
			
					<cfquery name="qryRFPinsert" datasource="#dsn#">
						INSERT INTO efn.R_Footprint_Photo (footprint_ID, event_photo_ID) VALUES (#footprintId#, #event_info.event_photo_ID#);
					</cfquery>
			
					<cfinvoke component="#setComponent#" method="insertConsumerAnswer" returnvariable="insertComplete">
						<cfinvokeargument name="consumer_ID" value="#consumerId#">
						<cfinvokeargument name="data_element_ID" value="#fb_photo_de#">
						<cfinvokeargument name="footprint_ID" value="#footprintId#">
						<cfinvokeargument name="answer_text" value="#photoData.id#">
					</cfinvoke>

					<cfif IsDefined('URL.debug')>
		<cfdump var="Line: 345">
						<cfdump var="#insertComplete#" label="insertComplete">
					</cfif>	

					<cfset albumID = albumData.id>
					<cfset photoCreated = TRUE>
				<cfelseif IsDefined("photoData.error.message") AND Find("120", photoData.error.message) >
					<!--- Post the photo to the account --->
					<cfhttp method="POST" url="https://graph.facebook.com/me/photos" result="fbPhotoInfo">
						<cfhttpparam type="url" name="access_token" value="#access_token#" />
					 	<cfhttpparam type="file" name="source" file="#event_info.path#" />
						<cfhttpparam type="header" name="mimetype" value="text/javascript" />
					</cfhttp>
					<cfinvoke component="JSON" method="decode" data="#Trim(fbPhotoInfo.Filecontent)#" returnvariable="photoData" />

					<cfinvoke component="#setComponent#" method="insertFootprint" returnvariable="footprintId">
						<cfinvokeargument name="event_token_ID" value="#eventToken#">
						<cfinvokeargument name="r_elat_ID" value="#relats.share#">
						<cfinvokeargument name="client_license_ID" value="#clientLicense#">
						<cfinvokeargument name="sample_flag" value="#event_info.sample_flag#">
					</cfinvoke>

					<cfif IsDefined('URL.debug')>
		<cfdump var="Line: 368">
						<cfdump var="#footprintId#" label="footprintId">
					</cfif>	
			
					<cfquery name="qryRFPinsert" datasource="#dsn#">
						INSERT INTO efn.R_Footprint_Photo (footprintId, event_photo_ID) VALUES (#footprintId#, #event_info.event_photo_ID#);
					</cfquery>
			
					<cfinvoke component="#setComponent#" method="insertConsumerAnswer" returnvariable="insertComplete">
						<cfinvokeargument name="consumer_ID" value="#consumerId#">
						<cfinvokeargument name="data_element_ID" value="#fb_photo_de#">
						<cfinvokeargument name="footprint_ID" value="#footprintId#">
						<cfinvokeargument name="answer_text" value="#photoData.id#">
					</cfinvoke>
					
					<cfif IsDefined('URL.debug')>
		<cfdump var="Line: 384">
						<cfdump var="#insertComplete#" label="insertComplete">
					</cfif>						
					
				<cfelse>
					<cfset attemptCount = attemptCount + 1>
					<cfif attemptCount GTE 3>
						<cfset photoCreated = TRUE>
					<cfelse>
						<cfset photoCreated = FALSE>
					</cfif>
				</cfif>
			</cfloop>
		</cfif>
		<!--- Done with any photo manipulation --->
	</cfif>
<cfcatch>
	<cfif NOT IsDefined('SERVER_LOCATION')>
		<cfset SERVER_LOCATION = 'Unknown Server'>
	</cfif>
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
</cfcatch>
</cftry>
<!--- Now get the like URL --->
<cfinvoke component="#fbPublisherCom#" method="getLikeURL" returnvariable="likeURL">
	<cfinvokeargument name="client_license_id" value="#clientLicense#">
</cfinvoke>





<cfset sttReturnInfo = StructNew()>
<cfif IsDefined('photoID') AND photoID GT 0>
	<cfset StructInsert(sttReturnInfo, 'phid', photoID)>
<cfelseif IsDefined('photoData.id') AND photoData.id GT 0>
	<cfset StructInsert(sttReturnInfo, 'phid', photoData.id)>
<cfelse>
	<cfset StructInsert(sttReturnInfo, 'phid', -1)>
</cfif>

<cfif IsDefined('likeURL')>
	<cfset StructInsert(sttReturnInfo, 'likeurl', likeURL)>
<cfelse>
	<cfset StructInsert(sttReturnInfo, 'likeurl', 'none')>
</cfif>
<cfset StructInsert(sttReturnInfo, 'cid', consumerId)>
<cfset StructInsert(sttReturnInfo, 'et', eventToken)>

<cfinvoke component="JSON" method="encode" data="#sttReturnInfo#" returnvariable="qs"/>

<cfif IsDefined('url.debug')>Boo9
	<cfif IsDefined('URL.debug')>
	<cfdump var="#sttReturnInfo#" label="sttReturnInfo">
	<cfdump var="#qs#" label="qs">
	</body></html></cfif>	
	<cfabort>
</cfif>

<cfoutput>#qs#</cfoutput><cfabort>