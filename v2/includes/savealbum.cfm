<cfset albumID=url.alid>

<cfset fbPublisherCom = "FacebookPublisher">

<cfquery name="getEventInfo" datasource="#dsn#">
	SELECT event_token_id, ep.event_photo_ID, CONCAT('/var/www/html/eshots',ep.path) AS path, 
	ep.path url, pe.watermark_file_name, Events.name, Events.description, ep.sample_flag, 
	Brands.name AS Brand_Name
	FROM Footprints f
	JOIN R_Footprint_Photo rfp ON rfp.footprint_ID = f.footprint_ID
	JOIN Event_Photos ep ON rfp.event_photo_ID = ep.event_photo_ID 
	JOIN Event_Photos_Extended epe ON epe.event_photo_ID = ep.event_photo_ID
	JOIN Photo_Environments pe ON ep.photo_environment_ID = pe.photo_environment_ID
	JOIN Event_Days ed ON f.event_day_ID = ed.event_day_ID 
	JOIN Events ON ed.event_ID = Events.event_ID 
	JOIN R_Event_Location_Activity_Type relat ON f.r_elat_ID = relat.r_elat_ID AND relat.activity_type_id IN (1,53)
	JOIN Event_Locations ON relat.event_location_ID = Event_Locations.event_location_ID 
	JOIN Brands ON Event_Locations.brand_ID = Brands.brand_ID
	WHERE event_token_ID = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" maxlength="10" value="#eventToken#">
		AND Events.client_license_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#clientLicense#">
		AND epe.photo_type_ID = 2
</cfquery>

<cfset photoID=getEventInfo.event_photo_id>
<cfset imageURL=getEventInfo.url>

<!---get the consumerid--->
<cfquery name="qryCID" datasource="#dsn#">
	SELECT consumer_ID
	from R_Consumer_Event_Token
	where event_token_id="#eventToken#"
</cfquery>
<cfif qryCID.recordcount>
	<cfset consumer_ID=qryCID.consumer_ID>
<cfelse>
	<cfset consumer_id=0>
</cfif>

<!---check for the albumID existing in RCDEA.  If it's not there, write it--->
<cfinvoke component="#fbPublisherCom#" method="getAlbumID" returnvariable="albumID">
	<cfinvokeargument name="consumer_ID" value="#consumer_ID#">
	<cfinvokeargument name="client_license_id"  value="#clientLicense#">
</cfinvoke>

<!--- If the album ID is not found in RCDEA --->
<!--- 
<cfif albumID LTE 0>
 	<cfhttp method="POST" url="https://graph.facebook.com/me/albums" result="fbNewAlbumInfo">
		<cfhttpparam type="url" name="access_token" value="#access_token#" />
	 	<cfhttpparam type="url" name="name" value="#event_info.Brand_Name# Events" /><!---todo: change session variables--->
		<cfhttpparam type="header" name="mimetype" value="text/javascript" />
	</cfhttp>

 	<cfif Find(fbNewAlbumInfo.Responseheader.Status_Code,"200")>
		<cfinvoke component="JSON" method="decode" data="#Trim(fbNewAlbumInfo.Filecontent)#" returnvariable="albumData" />

		<cfinvoke component="#setComponent#" method="insertConsumerAnswer" returnvariable="insertComplete">
			<cfinvokeargument name="consumer_ID" value="#consumer_id#">
			<cfinvokeargument name="data_element_ID" value="#fb_album_de#">
			<cfinvokeargument name="footprint_ID" value="#footprint_id#">
			<cfinvokeargument name="answer_text" value="#albumID#">
		</cfinvoke>
	
		<cfset albumID = albumData.id>
	</cfif>
</cfif>
 --->

<cfinvoke component="#setComponent#" method="insertConsumerAnswer" returnvariable="insertComplete">
	<cfinvokeargument name="consumer_ID" value="#consumer_id#">
	<cfinvokeargument name="data_element_ID" value="#fb_album_de#">
	<cfinvokeargument name="footprint_ID" value="#footprint_id#">
	<cfinvokeargument name="answer_text" value="#albumID#">
</cfinvoke>


<!---check for the facebook photo id--->
<cfinvoke component="#fbPublisherCom#" method="getFBphotoID" returnvariable="photoID">
	<cfinvokeargument name="event_photo_id" value="#event_info.event_photo_ID#">
	<cfinvokeargument name="event_token_id" value="#eventToken#">
	<cfinvokeargument name="r_elat_ID" value="#relats.share#">
</cfinvoke>

<!--- If the photo ID is not found in RCDEA --->
<cfif photoID LTE 0>
	<cfinvoke component="#fbPublisherCom#" method="getWatermark" returnvariable="wmkInfo">
		<cfinvokeargument name="client_license_id" value="#clientLicense#"><!---todo: change session variables--->
	</cfinvoke>



<!--- 
STEPS FOR SAVING PHOTO:
 X Save photo back to original location
 X Update the EP table and the R_EPPE tables' PE_ID
 X Only Watermark if the current PE_ID is "blank.png"

<cfdump var="#wmkInfo.watermark_file_name#">
<cfdump var="#event_info.watermark_file_name#">
--->

	<cfif IsDefined("wmkInfo.watermark_file_name") AND wmkInfo.watermark_file_name NEQ "" AND event_info.watermark_file_name EQ "blank.png"><!---todo: change session variables--->
<!--- <cfdump var="#Replace(event_info.path, '/var/www/html/eshots', publicURL, 'ALL')#?w=#wmkInfo.watermark_file_name#&q=90"> --->

		<cfhttp method="get" 
				url="#Replace(event_info.path, '/var/www/html/eshots', publicURL, 'ALL')#?w=#wmkInfo.watermark_file_name#&q=90" 
				path="#GetDirectoryFromPath(event_info.path)#" file="#GetFileFromPath(event_info.path)#" ><!---todo: change session variables--->

		<cfinvoke component="#fbPublisherCom#" method="setWatermark" >
			<cfinvokeargument name="event_photo_ID" value="#event_info.event_photo_ID#"><!---todo: change session variables--->
			<cfinvokeargument name="photo_environment_ID" value="#wmkInfo.photo_environment_ID#">
		</cfinvoke>

	<cfelse>
<!--- <cfdump var="#Replace(event_info.path, '/var/www/html/eshots', publicURL, 'ALL')#?q=90"> --->

		<cfhttp method="get" 
				url="#Replace(event_info.path, '/var/www/html/eshots', publicURL, 'ALL')#?q=90" 
				path="#GetDirectoryFromPath(event_info.path)#" file="#GetFileFromPath(event_info.path)#" >
	</cfif>


 	<!--- Post the photo to the album --->
	<cfhttp method="POST" url="https://graph.facebook.com/#albumID#/photos" result="fbPhotoInfo">
		<cfhttpparam type="url" name="access_token" value="#access_token#" />
	 	<cfhttpparam type="file" name="source" file="#event_info.path#" />
		<cfhttpparam type="header" name="mimetype" value="text/javascript" />
	</cfhttp>
	<cfinvoke component="json" method="decode" data="#Trim(fbPhotoInfo.Filecontent)#" returnvariable="photoData" />


	<cfif IsDefined("photoData.error.message") AND Find("120", photoData.error.message) >
		<!--- Post the photo to the account --->
		<cfhttp method="POST" url="https://graph.facebook.com/me/photos" result="fbPhotoInfo">
			<cfhttpparam type="url" name="access_token" value="#access_token#" />
		 	<cfhttpparam type="file" name="source" file="#event_info.path#" />
			<cfhttpparam type="header" name="mimetype" value="text/javascript" />
		</cfhttp>
		<cfinvoke component="json" method="decode" data="#Trim(fbPhotoInfo.Filecontent)#" returnvariable="photoData" />
	</cfif>


	<cfif Find("200",fbPhotoInfo.Responseheader.Status_Code)>
	
		<cfhttp method="GET" url="https://graph.facebook.com/#photoData.id#" result="fbPhotoInfo">
			<cfhttpparam type="url" name="access_token" value="#access_token#" />
			<cfhttpparam type="header" name="mimetype" value="text/javascript" />
		</cfhttp>
		<cfinvoke component="json" method="decode" data="#Trim(fbPhotoInfo.Filecontent)#" returnvariable="photoData" />

		<cfinvoke component="#setComponent#" method="insertFootprint" returnvariable="footprint_id">
			<cfinvokeargument name="event_token_ID" value="#eventToken#">
			<cfinvokeargument name="r_elat_ID" value="#relats.share#">
			<cfinvokeargument name="client_license_ID" value="#clientLicense#">
			<cfinvokeargument name="sample_flag" value="#event_info.sample_flag#">
		</cfinvoke>

		<cfquery name="qryRFPinsert" datasource="#dsn#">
			INSERT INTO efn.R_Footprint_Photo (footprint_ID, event_photo_ID) VALUES (#footprint_id#, #event_info.event_photo_ID#);
		</cfquery>

		<cfinvoke component="#setComponent#" method="insertConsumerAnswer" returnvariable="insertComplete">
			<cfinvokeargument name="consumer_ID" value="#consumer_id#">
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
	<cfinvoke component="json" method="decode" data="#Trim(fbPhotoInfo.Filecontent)#" returnvariable="photoData" />

</cfif>

<cfset albumName="#event_info.brand_name# Events">

<!--- <cfset qs="phid=#photoData.id#&alid=#albumid#&iu=#imageURL#&ct=#ct#&am=#albumName#"> --->
<cfset sttReturnInfo = StructNew()>
<cfset StructInsert(sttReturnInfo, 'phid', photoData.id)>
<cfset StructInsert(sttReturnInfo, 'alid', albumid)>
<cfset StructInsert(sttReturnInfo, 'iu', imageURL)>
<cfset StructInsert(sttReturnInfo, 'an', albumName)>

<cfinvoke component="json" method="encode" data="#sttReturnInfo#" returnvariable="qs"/>
<cfoutput>#qs#</cfoutput><cfabort>