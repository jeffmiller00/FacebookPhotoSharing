<cfsilent>
 
<cfapplication name="Facebook Publisher v3.0.1" applicationtimeout="#CreateTimeSpan( 0, 0, 60, 0 )#" sessionmanagement="true" />

<cfinclude template="includes/config.cfm" >

<!--- Set custom global error handling pages for this application.--->
<cferror type="exception"
    template="err.cfm"
    mailto="jdaleo@eshots.com">

<cferror type="validation"
    template="err.cfm"
    mailto="jdaleo@eshots.com">

<cferror type="request"
    template="err.cfm"
    mailto="jdaleo@eshots.com">

</cfsilent>