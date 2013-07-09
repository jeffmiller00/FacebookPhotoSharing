<cfcomponent extends="com.eshots.dbaccess.GetDataAccess" output="true">

	<cfset dsn = "efn">
	<cfset read_dsn = "efn_readonly">
	<cfset setComponent = "com.eshots.dbaccess.SaveDataAccess">
	<cfset retriveAT = 10>
	<cfset fbShareAT = 35>
	<cfset fbLikeAT = 54>
	<cfset fbDataAT = 61>
	<cfset fbDeauthAT = 62>
	<cfset fbViralAT = 11>

	<cfset fb_id_de = 10230>
	<cfset fb_album_de = 10232>
	<cfset fb_photo_de = 10261>

	<cffunction name="getEvent" access="public" output="false" returntype="Query">
		<cfargument name="event_token_id" type="string" required="true" />
		<cfargument name="client_license_id" type="numeric" required="true" />

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
			WHERE event_token_ID = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" maxlength="10" value="#event_token_id#">
			AND Events.client_license_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#client_license_id#">
			AND epe.photo_type_ID = 2
		</cfquery>

		<cfreturn getEventInfo />
	</cffunction>


	<cffunction name="getEventLocation" access="public" output="false" returntype="numeric">
		<cfargument name="client_license_id" type="numeric" required="true" />

			<cfquery name="getEventLocationInfo" datasource="#dsn#">
				SELECT el.event_location_id FROM Event_Locations el
				JOIN R_Event_Location_Activity_Type relat ON relat.event_location_ID = el.event_location_ID
				WHERE el.client_license_ID = <cfqueryparam cfsqltype="CF_SQL_BIGINT" value="#client_license_id#">
				AND relat.activity_type_ID = #fbDataAT#
				LIMIT 1;
			</cfquery>

		<cfif getEventLocationInfo.RecordCount >
			<cfreturn getEventLocationInfo.event_location_id />
		<cfelse>
			<cfreturn -1 />
		</cfif>
	</cffunction>


	<cffunction name="getWatermark" access="public" output="false" returntype="struct">
		<cfargument name="client_license_id" type="numeric" required="true" />

			<cfset wmkSet = StructNew()>

			<cfquery name="getWatermark" datasource="#dsn#">
				SELECT pe.photo_environment_ID, pe.watermark_file_name  
				FROM Photo_Environments pe
				JOIN R_ELAT_Photo_Environment ON R_ELAT_Photo_Environment.photo_environment_ID = pe.photo_environment_ID
				JOIN R_Event_Location_Activity_Type ON R_ELAT_Photo_Environment.r_elat_ID = R_Event_Location_Activity_Type.r_elat_ID
				LEFT JOIN Event_Locations el ON R_Event_Location_Activity_Type.event_location_ID = el.event_location_ID 
				WHERE el.client_license_ID = <cfqueryparam cfsqltype="CF_SQL_BIGINT" value="#client_license_id#">
					AND R_Event_Location_Activity_Type.activity_type_ID = 61 
					AND pe.watermark_file_name NOT LIKE "%blank.png%"
				ORDER BY pe.create_DTM
				LIMIT 1;
			</cfquery>

		<cfif getWatermark.RecordCount>
			<cfset wmkSet.photo_environment_ID = getWatermark.photo_environment_ID>
			<cfset wmkSet.watermark_file_name = getWatermark.watermark_file_name>
			<cfreturn wmkSet>
		<cfelse>
			<cfreturn "">
		</cfif>
	</cffunction>


	<cffunction name="setWatermark" access="public" output="false" returntype="void">
		<cfargument name="event_photo_ID" type="numeric" required="true" />
		<cfargument name="photo_environment_ID" type="numeric" required="true" />

		<cfquery name="updateEventPhotos" datasource="#dsn#">
			UPDATE Event_Photos SET photo_environment_id = #ARGUMENTS.photo_environment_ID# WHERE event_photo_ID = #ARGUMENTS.event_photo_ID#
		</cfquery>

		<cfquery name="updateEventPhotos" datasource="#dsn#">
			UPDATE R_Event_Photo_Photo_Environment SET photo_environment_id = #ARGUMENTS.photo_environment_ID# WHERE event_photo_ID = #ARGUMENTS.event_photo_ID#
		</cfquery>

		<cfreturn />
	</cffunction>


	<cffunction name="getLikeURL" access="public" output="false" returntype="string">
		<cfargument name="client_license_id" type="numeric" required="true" />

		<cfquery name="getLikeURL" datasource="#dsn#">
			SELECT url FROM Event_Locations 
			JOIN Websites ON Event_Locations.website_ID = Websites.website_ID 
			WHERE Event_Locations.client_license_ID = <cfqueryparam cfsqltype="CF_SQL_BIGINT" value="#client_license_id#">
			AND url LIKE "%facebook%"
			LIMIT 1;
		</cfquery>

		<cfif getLikeURL.RecordCount>
			<cfreturn getLikeURL.url>
		<cfelse>
			<cfreturn "">
		</cfif>
	</cffunction>


	<cffunction name="getGenderID" access="public" output="false" returntype="numeric">
		<cfargument name="gender_txt" type="string" required="true" />

		<cfset genderID = 0>
		<cfif gender_txt EQ "male">
			<cfset genderID = 103>
		<cfelseif gender_txt EQ "female">
			<cfset genderID = 104>
		</cfif>

		<cfreturn genderID>
	</cffunction>


	<cffunction name="getBirthdayAnswers" access="public" output="false" returntype="struct">
		<cfargument name="birthdate" type="string" required="true" />

		<cfscript>
		bdayStruct = StructNew();
/* 		We do not care about answer ids for MONTH, DAY, YEAR as of now...
		StructInsert(bdayStruct,"314", ListGetAt(birthdate, 1, "/"));
		StructInsert(bdayStruct,"315", ListGetAt(birthdate, 2, "/"));
		StructInsert(bdayStruct,"316", ListGetAt(birthdate, 3, "/"));
*/
		</cfscript>

		<cfset dteBday = CreateDate(ListGetAt(birthdate, 3, "/"), ListGetAt(birthdate, 1, "/"),  ListGetAt(birthdate, 2, "/"))>
		<cfset consumerAge = DateDiff("yyyy", dteBday, now())>
		<cfif consumerAge GT 64>
			<cfset StructInsert(bdayStruct,"59", "111")>
		<cfelseif consumerAge GT 54>
			<cfset StructInsert(bdayStruct,"59", "110")>
		<cfelseif consumerAge GT 44>
			<cfset StructInsert(bdayStruct,"59", "109")>
		<cfelseif consumerAge GT 34>
			<cfset StructInsert(bdayStruct,"59", "108")>
		<cfelseif consumerAge GT 24>
			<cfset StructInsert(bdayStruct,"59", "107")>
		<cfelseif consumerAge GT 20>
			<cfset StructInsert(bdayStruct,"59", "992")>
		<cfelseif consumerAge GT 17>
			<cfset StructInsert(bdayStruct,"59", "2211")>
		<cfelseif consumerAge GT 15>
			<cfset StructInsert(bdayStruct,"59", "196")>
		<cfelse>
			<cfset StructInsert(bdayStruct,"59", "3338")>
		</cfif>

		<cfreturn bdayStruct>
	</cffunction>


	<cffunction name="saveConsumerData" access="public" output="true" returntype="void">
		<cfargument name="consumerID" type="numeric" required="true" />
		<cfargument name="dataFootprint" type="numeric" required="true" />
		<cfargument name="consumerData" type="struct" required="true" />


		<cfinvoke component="#setComponent#" method="insertConsumerAnswer" returnvariable="insertComplete">
			<cfinvokeargument name="consumer_ID" value="#ARGUMENTS.consumerID#">
			<cfinvokeargument name="data_element_ID" value="35">
			<cfinvokeargument name="footprint_ID" value="#ARGUMENTS.dataFootprint#">
			<cfinvokeargument name="answer_id" value="194">
		</cfinvoke>
		<cfloop collection="#consumerData#" item="fbDE">
			<cfswitch expression="#Trim(fbDE)#">
				<cfcase value="first_name">
					<cfinvoke component="#setComponent#" method="insertConsumerAnswer" returnvariable="insertComplete">
						<cfinvokeargument name="consumer_ID" value="#ARGUMENTS.consumerID#">
						<cfinvokeargument name="data_element_ID" value="6">
						<cfinvokeargument name="footprint_ID" value="#ARGUMENTS.dataFootprint#">
						<cfinvokeargument name="answer_text" value="#Trim(consumerData[fbDE])#">
					</cfinvoke>
				</cfcase>
				<cfcase value="last_name">
					<cfinvoke component="#setComponent#" method="insertConsumerAnswer" returnvariable="insertComplete">
						<cfinvokeargument name="consumer_ID" value="#ARGUMENTS.consumerID#">
						<cfinvokeargument name="data_element_ID" value="7">
						<cfinvokeargument name="footprint_ID" value="#ARGUMENTS.dataFootprint#">
						<cfinvokeargument name="answer_text" value="#Trim(consumerData[fbDE])#">
					</cfinvoke>
				</cfcase>
				<cfcase value="gender">
					<cfinvoke method="getGenderID" returnvariable="genderID">
						<cfinvokeargument name="gender_txt" value="#consumerData[fbDE]#">
					</cfinvoke>
		
					<cfif genderID GT 0>
						<cfinvoke component="#setComponent#" method="insertConsumerAnswer" returnvariable="insertComplete">
							<cfinvokeargument name="consumer_ID" value="#ARGUMENTS.consumerID#">
							<cfinvokeargument name="data_element_ID" value="2">
							<cfinvokeargument name="footprint_ID" value="#ARGUMENTS.dataFootprint#">
							<cfinvokeargument name="answer_id" value="#genderID#">
						</cfinvoke>
					</cfif>
				</cfcase>
				<cfcase value="birthday">
					<cfinvoke component="#setComponent#" method="insertConsumerAnswer" returnvariable="insertComplete">
						<cfinvokeargument name="consumer_ID" value="#ARGUMENTS.consumerID#">
						<cfinvokeargument name="data_element_ID" value="178">
						<cfinvokeargument name="footprint_ID" value="#ARGUMENTS.dataFootprint#">
						<cfinvokeargument name="answer_text" value="#Trim(consumerData[fbDE])#">
					</cfinvoke>
		
					<cfinvoke method="getBirthdayAnswers" returnvariable="bdayStruct">
						<cfinvokeargument name="birthdate" value="#consumerData[fbDE]#">
					</cfinvoke>
		
					<!--- This is in a loop because if we store MM/DD/YYYY as answer IDs in the future --->
					<cfloop collection="#bdayStruct#" item="deID">
						<cfinvoke component="#setComponent#" method="insertConsumerAnswer" returnvariable="insertComplete">
							<cfinvokeargument name="consumer_ID" value="#ARGUMENTS.consumerID#">
							<cfinvokeargument name="data_element_ID" value="#deID#">
							<cfinvokeargument name="footprint_ID" value="#ARGUMENTS.dataFootprint#">
							<cfinvokeargument name="answer_id" value="#bdayStruct[deID]#">
						</cfinvoke>
					</cfloop>
				</cfcase>
				<cfcase value="email">
					<cfinvoke component="#setComponent#" method="insertConsumerAnswer" returnvariable="insertComplete">
						<cfinvokeargument name="consumer_ID" value="#ARGUMENTS.consumerID#">
						<cfinvokeargument name="data_element_ID" value="4">
						<cfinvokeargument name="footprint_ID" value="#ARGUMENTS.dataFootprint#">
						<cfinvokeargument name="answer_text" value="#Trim(Replace(consumerData[fbDE],'\u0040','@','all'))#">
					</cfinvoke>
				</cfcase>
<!--- 				<cfcase value="location">
					<cfinvoke component="#setComponent#" method="insertConsumerAnswer" returnvariable="insertComplete">
						<cfinvokeargument name="consumer_ID" value="#ARGUMENTS.consumerID#">
						<cfinvokeargument name="data_element_ID" value="9">
						<cfinvokeargument name="footprint_ID" value="#ARGUMENTS.dataFootprint#">
						<cfinvokeargument name="answer_text" value="#Trim(ListGetAt(consumerData[fbDE].name, 1, ','))#">
					</cfinvoke>
					<cfinvoke component="#setComponent#" method="insertConsumerAnswer" returnvariable="insertComplete">
						<cfinvokeargument name="consumer_ID" value="#ARGUMENTS.consumerID#">
						<cfinvokeargument name="data_element_ID" value="10">
						<cfinvokeargument name="footprint_ID" value="#ARGUMENTS.dataFootprint#">
						<cfinvokeargument name="answer_text" value="#Trim(ListGetAt(consumerData[fbDE].name, 2, ','))#">
					</cfinvoke>
				</cfcase> --->
				<cfcase value="id">
					<!--- Facebook ID: 10230 --->
					<cfinvoke component="#setComponent#" method="insertConsumerAnswer" returnvariable="insertComplete">
						<cfinvokeargument name="consumer_ID" value="#ARGUMENTS.consumerID#">
						<cfinvokeargument name="data_element_ID" value="#fb_id_de#">
						<cfinvokeargument name="footprint_ID" value="#ARGUMENTS.dataFootprint#">
						<cfinvokeargument name="answer_text" value="#Trim(consumerData[fbDE])#">
					</cfinvoke>
				</cfcase>
				<cfcase value="username">
					<!--- Facebook Username: 10231 --->
					<cfinvoke component="#setComponent#" method="insertConsumerAnswer" returnvariable="insertComplete">
						<cfinvokeargument name="consumer_ID" value="#ARGUMENTS.consumerID#">
						<cfinvokeargument name="data_element_ID" value="10231">
						<cfinvokeargument name="footprint_ID" value="#ARGUMENTS.dataFootprint#">
						<cfinvokeargument name="answer_text" value="#Trim(consumerData[fbDE])#">
					</cfinvoke>
				</cfcase>
			</cfswitch>
		</cfloop>
		
	</cffunction>


	<cffunction name="SetupRELATs" access="public" output="false" returntype="struct">
		<cfargument name="client_license_id" type="numeric" required="true" />

		<cfset relatSet = StructNew()>

		<cfinvoke method="getEventLocation" returnvariable="event_location_id">
			<cfinvokeargument name="client_license_id" value="#client_license_id#">
		</cfinvoke>

		<cfif event_location_id GT 0>

			<cfinvoke method="GetRELATbyELAT" returnvariable="returnRELAT">
				<cfinvokeargument name="eventLocationID" value="#event_location_id#">
				<cfinvokeargument name="activityTypeID" value="#fbDataAT#">
			</cfinvoke>
			<cfset relatSet.data = returnRELAT.r_elat_id >
			<!--- This lookup won't fail if an event location exists --->
			
			<cfinvoke method="GetRELATbyELAT" returnvariable="returnRELAT">
				<cfinvokeargument name="eventLocationID" value="#event_location_id#">
				<cfinvokeargument name="activityTypeID" value="#retriveAT#">
			</cfinvoke>
			<cfset relatSet.retrieve = returnRELAT.r_elat_id >
			<cfif relatSet.retrieve LT 0>
				<cfinvoke component="#setComponent#" method="insertRELAT" returnvariable="relatSet.retrieve">
					<cfinvokeargument name="eventLocationID" value="#event_location_id#">
					<cfinvokeargument name="activityTypeID" value="#retriveAT#">
				</cfinvoke>
			</cfif>

			<cfinvoke method="GetRELATbyELAT" returnvariable="returnRELAT">
				<cfinvokeargument name="eventLocationID" value="#event_location_id#">
				<cfinvokeargument name="activityTypeID" value="#fbLikeAT#">
			</cfinvoke>
			<cfset relatSet.like = returnRELAT.r_elat_id >
			<cfif relatSet.like LT 0>
				<cfinvoke component="#setComponent#" method="insertRELAT" returnvariable="relatSet.like">
					<cfinvokeargument name="eventLocationID" value="#event_location_id#">
					<cfinvokeargument name="activityTypeID" value="#fbLikeAT#">
				</cfinvoke>
			</cfif>
	
			<cfinvoke method="GetRELATbyELAT" returnvariable="returnRELAT">
				<cfinvokeargument name="eventLocationID" value="#event_location_id#">
				<cfinvokeargument name="activityTypeID" value="#fbShareAT#">
			</cfinvoke>
			<cfset relatSet.share = returnRELAT.r_elat_id >
			<cfif relatSet.share LT 0>
				<cfinvoke component="#setComponent#" method="insertRELAT" returnvariable="relatSet.share">
					<cfinvokeargument name="eventLocationID" value="#event_location_id#">
					<cfinvokeargument name="activityTypeID" value="#fbShareAT#">
				</cfinvoke>
			</cfif>

			<cfinvoke method="GetRELATbyELAT" returnvariable="returnRELAT">
				<cfinvokeargument name="eventLocationID" value="#event_location_id#">
				<cfinvokeargument name="activityTypeID" value="#fbDeauthAT#">
			</cfinvoke>
			<cfset relatSet.deauth = returnRELAT.r_elat_id >
			<cfif relatSet.deauth LT 0>
				<cfinvoke component="#setComponent#" method="insertRELAT" returnvariable="relatSet.deauth">
					<cfinvokeargument name="eventLocationID" value="#event_location_id#">
					<cfinvokeargument name="activityTypeID" value="#fbDeauthAT#">
				</cfinvoke>
			</cfif>

			<cfinvoke method="GetRELATbyELAT" returnvariable="returnRELAT">
				<cfinvokeargument name="eventLocationID" value="#event_location_id#">
				<cfinvokeargument name="activityTypeID" value="#fbViralAT#">
			</cfinvoke>
			<cfset relatSet.viral = returnRELAT.r_elat_id >
			<cfif relatSet.viral LTE 0>
				<cfinvoke component="#setComponent#" method="insertRELAT" returnvariable="relatSet.viral">
					<cfinvokeargument name="eventLocationID" value="#event_location_id#">
					<cfinvokeargument name="activityTypeID" value="#fbViralAT#">
				</cfinvoke>
			</cfif>
		<cfelse>
			<cfthrow errorCode="1"
				type="Event Setup" 
				message="Event Location Could Not Be Found" 
				detail="There was no event location with the 'Facebook Data Capture' activity for this Client License." />
		</cfif>

		<cfreturn relatSet />
	</cffunction>


	<cffunction name="getFacebookID" access="public" output="false" returntype="numeric">
		<cfargument name="consumer_ID" type="numeric" required="true" />

		<cfquery name="qryFbID" datasource="#dsn#">
			SELECT answer_text FROM R_Consumer_Data_Element_Answer
			WHERE consumer_ID = <cfqueryparam cfsqltype="CF_SQL_BIGINT" value="#consumer_ID#">
			AND data_element_id = #fb_id_de#
			LIMIT 1;
		</cfquery>

		<cfif qryFbID.RecordCount>
			<cfreturn qryFbID.answer_text>
		<cfelse>
			<cfreturn "-1">
		</cfif>
	</cffunction>


	<cffunction name="getAlbumID" access="public" output="false" returntype="numeric">
		<cfargument name="consumer_ID" type="numeric" required="true" />
		<cfargument name="client_license_id" type="numeric" required="true" />

		<cfparam name="returnAlbumID" default="-1">

		<cfquery name="qryAlbumID" datasource="#dsn#">
			SELECT answer_text FROM R_Consumer_Data_Element_Answer
			WHERE consumer_ID = <cfqueryparam cfsqltype="CF_SQL_BIGINT" value="#consumer_ID#">
			AND data_element_id = #fb_album_de#
			ORDER BY create_dtm DESC
			LIMIT 1;
		</cfquery>

		<cfif qryAlbumID.RecordCount>
			<cfset returnAlbumID = qryAlbumID.answer_text>
<!--- This may no longer be necessary.
		<cfelse>
			<cfquery name="qryEmailAddr" datasource="#read_dsn#">
				SELECT answer_text AS "email" FROM R_Consumer_Data_Element_Answer
				WHERE consumer_ID = <cfqueryparam cfsqltype="CF_SQL_BIGINT" value="#arguments.consumer_ID#">
				AND data_element_id = 4
				LIMIT 1;
			</cfquery>
			<cfquery name="qryFBid" datasource="#read_dsn#">
				SELECT answer_text AS "fb_id" FROM R_Consumer_Data_Element_Answer
				WHERE consumer_ID = <cfqueryparam cfsqltype="CF_SQL_BIGINT" value="#arguments.consumer_ID#">
				AND data_element_id = #fb_id_de#
				LIMIT 1;
			</cfquery>

			<cfif qryEmailAddr.RecordCount>
				<cfquery name="qryAlbumID" datasource="#read_dsn#">
					SELECT albumID.answer_text  
					FROM R_Consumer_Data_Element_Answer email 
						JOIN Footprints ON email.footprint_ID = Footprints.footprint_ID 
						JOIN R_Event_Location_Activity_Type ON Footprints.r_elat_ID = R_Event_Location_Activity_Type.r_elat_ID 
						JOIN Event_Locations ON R_Event_Location_Activity_Type.event_location_ID = Event_Locations.event_location_ID
						JOIN R_Consumer_Data_Element_Answer albumID ON albumID.consumer_id = email.consumer_id AND albumID.data_element_id = #fb_album_de#
						JOIN R_Consumer_Data_Element_Answer facebookID ON facebookID.consumer_id = email.consumer_ID AND facebookID.data_element_id = #fb_id_de# 
					WHERE email.data_element_ID = 4 
						AND (email.answer_text = "#qryEmailAddr.email#" OR facebookID.answer_text = "#qryFBid.fb_id#")
						AND Event_Locations.client_license_ID = <cfqueryparam cfsqltype="CF_SQL_BIGINT" value="#arguments.client_license_id#">
					ORDER BY albumID.create_DTM DESC 
					LIMIT 1
				</cfquery>
	
				<cfif qryAlbumID.RecordCount>
					<cfset returnAlbumID = qryAlbumID.answer_text>
				</cfif>
			</cfif>
--->
		</cfif>

		<cfreturn returnAlbumID>
	</cffunction>


	<cffunction name="getFBphotoID" access="public" output="false" returntype="numeric">
		<cfargument name="event_photo_id" type="numeric" required="true" />
		<cfargument name="event_token_id" type="string" required="true" />
		<cfargument name="r_elat_ID" type="numeric" required="true" />

		<cfquery name="qryPhotoID" datasource="#dsn#">
			SELECT fb_photo.answer_text  
			FROM R_Consumer_Data_Element_Answer fb_photo
			JOIN Footprints f_share ON fb_photo.footprint_ID = f_share.footprint_ID 
				AND f_share.r_elat_id = <cfqueryparam cfsqltype="CF_SQL_BIGINT" value="#Arguments.r_elat_ID#">
			JOIN R_Footprint_Photo ON R_Footprint_Photo.footprint_ID = f_share.footprint_ID
			WHERE fb_photo.data_element_ID = #fb_photo_de# 
			AND f_share.event_token_ID = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#Arguments.event_token_id#">
			AND R_Footprint_Photo.event_photo_id = <cfqueryparam cfsqltype="CF_SQL_BIGINT" value="#Arguments.event_photo_id#"> 
			LIMIT 1
		</cfquery>

		<cfif qryPhotoID.RecordCount>
			<cfreturn qryPhotoID.answer_text>
		<cfelse>
			<cfreturn "-1">
		</cfif>
	</cffunction>


	<cffunction name="insertFootprint" access="remote" output="false" returntype="numeric">
		<cfargument name="event_token_ID" type="string" required="true" />
		<cfargument name="r_elat_ID" type="numeric" required="true" />
		<cfargument name="client_license_ID" type="numeric" required="true" />
		<cfargument name="sample_flag" type="numeric" required="true" />
		<cfargument name="record_multiple" type="boolean" required="false" default="true" />

		<cfinvoke component="#setComponent#" method="insertFootprint" returnvariable="footprint_id">
			<cfinvokeargument name="event_token_ID" value="#arguments.event_token_ID#">
			<cfinvokeargument name="r_elat_ID" value="#arguments.r_elat_ID#">
			<cfinvokeargument name="client_license_ID" value="#arguments.client_license_id#">
			<cfinvokeargument name="sample_flag" value="#arguments.sample_flag#">
			<cfinvokeargument name="record_multiple" value="#arguments.record_multiple#">
		</cfinvoke>

		<cfif footprint_id GT 0>
			<cfreturn footprint_id>
		<cfelse>
			<cfreturn "-1">
		</cfif>
	</cffunction>


	<cffunction name="createViralConsumer" access="public" output="true" returntype="string">
		<cfargument name="parentConsumerID" type="numeric" required="true" />

		<cfinclude template='/udf/CreateEventToken.cfm'>

		<cfquery name="insConsumerID" datasource="#dsn#">
			INSERT INTO efn.Consumers (referred_ID, create_DTM) 
			VALUES (#arguments.parentConsumerID#, NOW());
		</cfquery>
		<cfquery name="qryConsumerID_insert" datasource="#dsn#">
			SELECT LAST_INSERT_ID() id
		</cfquery> 

		<cfset newConsID = qryConsumerID_insert.id>
		<cfset newEventToken = CreateEventToken(newConsID, "K") />

		<cfquery name="insRCET" datasource="#dsn#" result="res">
			INSERT INTO efn.R_Consumer_Event_Token (consumer_ID, event_token_ID, create_DTM) 
			VALUES (#newConsID#, '#newEventToken#', NOW());
		</cfquery>

		<cfreturn newEventToken>

	</cffunction>


	<cffunction name="CheckPrevEntry" access="public" output="false" returntype="Query">
		<cfargument name="facebook_ID" type="numeric" required="true" />
		<cfargument name="client_license_id" type="numeric" required="false" />

		<cfquery name="qryFbID" datasource="#dsn#">
			SELECT Footprints.event_token_ID, fbID.consumer_ID, fbID.footprint_id, Footprints.sample_flag
			FROM R_Consumer_Data_Element_Answer fbID
			JOIN Footprints ON fbID.footprint_ID = Footprints.footprint_ID 
			JOIN R_Event_Location_Activity_Type ON Footprints.r_elat_ID = R_Event_Location_Activity_Type.r_elat_ID 
			JOIN Event_Locations ON R_Event_Location_Activity_Type.event_location_ID = Event_Locations.event_location_ID 
			WHERE fbID.data_element_ID = #fb_id_de# 
			AND fbID.answer_text = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" Maxlength="255" value="#ARGUMENTS.facebook_ID#">
			<cfif ARGUMENTS.client_license_id GT 0>
			AND Event_Locations.client_license_ID = <cfqueryparam cfsqltype="CF_SQL_BIGINT" value="#ARGUMENTS.client_license_id#">
			</cfif>
			ORDER BY fbID.create_DTM DESC 
			LIMIT 1;
		</cfquery>

		<cfreturn qryFbID>

	</cffunction>


	<cffunction name="GetCLIDfromFBID" access="public" output="false" returntype="Query">
		<cfargument name="facebook_ID" type="numeric" required="true" />

		<cfquery name="qryFbID" datasource="#dsn#">
			SELECT Footprints.event_token_ID, fbID.consumer_ID, Event_Locations.client_license_id 
			FROM R_Consumer_Data_Element_Answer fbID
			JOIN Footprints ON fbID.footprint_ID = Footprints.footprint_ID 
			JOIN R_Event_Location_Activity_Type ON Footprints.r_elat_ID = R_Event_Location_Activity_Type.r_elat_ID 
			JOIN Event_Locations ON R_Event_Location_Activity_Type.event_location_ID = Event_Locations.event_location_ID 
			WHERE fbID.data_element_ID = #fb_id_de# 
			AND fbID.answer_text = "#Arguments.facebook_ID#" 
			ORDER BY fbID.create_DTM DESC;
		</cfquery>

		<cfreturn qryFbID>

	</cffunction>

</cfcomponent> 