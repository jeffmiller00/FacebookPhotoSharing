<!--- <cfset tmpclid = listGetAt("#url.etclid#",2,"_")> --->
<cfinvoke component="FacebookPublisher" method="getLikeURL" returnvariable="likeURL">
	<cfinvokeargument name="client_license_id" value="#clientLicense#">
</cfinvoke>
