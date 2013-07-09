<!--- SERVER INFORMATION --->
<cfset server_location = "">
<cfset inet_address = CreateObject("java", "java.net.InetAddress")>
<cfset host_ip = inet_address.getLocalHost().getHostAddress()>

<cfswitch expression="#host_ip#">
	<cfcase value='216.218.248.12'>
		<cfset server_location = "California Server">
	</cfcase>
	<cfcase value='172.16.27.166'>
		<cfset server_location = "Web 1">
	</cfcase>	
	<cfcase value='172.16.27.167'>
		<cfset server_location = "Web 2">
	</cfcase>
	<cfcase value='172.16.27.170'>
		<cfset server_location = "Staging">
	</cfcase>		
	<cfcase value='172.16.27.168'>
		<cfset server_location = "Media 1">
	</cfcase>	
	<cfcase value='172.16.27.169'>
		<cfset server_location = "Media 2">
	</cfcase>
	<cfcase value='127.0.0.1'>
		<cfset server_location = "Local Host">
	</cfcase>	
	<cfdefaultcase>
		<cfset server_location = "Unknown Server Address">
	</cfdefaultcase>	
</cfswitch>

