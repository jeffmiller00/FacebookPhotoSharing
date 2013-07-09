<cfinvoke component="#setComponent#" method="insertFootprint" returnvariable="footprint_id">
	<cfinvokeargument name="event_token_ID" value="#eventToken#">
	<cfinvokeargument name="r_elat_ID" value="#relats.like#">
	<cfinvokeargument name="client_license_ID" value="#clientLicense#">
	<cfinvokeargument name="sample_flag" value="#event_info.sample_flag#">
	<cfinvokeargument name="record_multiple" value="true">
</cfinvoke>