<cfheader name="P3P" value="CP='IDC DSP COR ADM DEVi TAIi PSA PSD IVAi IVDi CONi HIS OUR IND CNT'" />
<html> 
	<head> 
   		<title>Facebook Publisher</title>
   		<link rel="stylesheet" href="js/fancybox/jquery.fancybox-1.3.4.css" type="text/css" media="screen" />
   		<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.6.1/jquery.min.js" type="text/javascript"></script>
   		<script type="text/javascript" src="js/fancybox/fancybox/jquery.fancybox-1.3.4.pack.js"></script>
   		<style>
   			#error_msg { font-size:16px;font-weight:bold;color:#9a2e2e;text-align:center}
   		</style>
		<cfif server_location NEQ "Staging">
			<cfinclude template="includes/analytics.cfm">
		</cfif>   
	</head>
   <body>
   	
   	<div id="fb-root"></div>
   	
   	<script type="text/javascript">
   		// pop-up version
   	/*
   		window.fbAsyncInit = function() {
        FB.init({ appId: '123842974364777',
            status: true,
            cookie: true,
            xfbml: true,
            oauth: true});

			this.vars = {
				access_token: '',
				errorHandler: 'You have to login to facebook and give permission to our application in order to post your picture<br><a href="' + document.location.href + '">Please try again</a>'
			}
 		authenticate();
 		
 		function authenticate() {
 			
	 		FB.getLoginStatus(function(response) {
	 			if(response.authResponse) {
	 				// logged and known to app
	 				// store access token
	 				vars.access_token = response.authResponse.accessToken;
	 				doTheRedirect();
	 			} else {
	 				// not logged in or unknow to app
	 				// prompt user to authorize app
	 				FB.login(function(response) {
	 					if(response.authResponse) {
	 						// store access token
	 						vars.access_token = response.authResponse.accessToken
	 						doTheRedirect();
	 					} else {
	 						//errorHandler if user cancels facebook login
	 						$("#error_msg").html(vars.errorHandler);
	 					}
	 				}, {scope: 'email,read_stream,user_birthday,user_photos,publish_stream'});			
				}
			});
		}
		
		function doTheRedirect() {
			window.location = 'https://apps.facebook.com/media_publisher_dev/index2.cfm?access_token='+ vars.access_token;
		}
    };
    (function() {
        var e = document.createElement('script'); e.async = true;
        e.src = document.location.protocol
            + '//connect.facebook.net/en_US/all.js';
        document.getElementById('fb-root').appendChild(e);
    }());
    */
    
    // non-pop up version
    
    var appID = <cfoutput>'#APPLICATION.appID#'</cfoutput>;
     // checks the url if access token is already added
     if (window.location.hash.length == 0) {
     	var path = 'https://www.facebook.com/dialog/oauth?';
   		var queryParams = ['client_id=' + appID,
     	<cfoutput>'redirect_uri=#redirecturl#'</cfoutput>,
<!---  		<cfoutput>'redirect_uri=https://apps.facebook.com/media_publisher_dev/index2.cfm?etclid=#eventToken#_#clientLicense#'</cfoutput>, --->
     	'scope=email,read_stream,user_birthday,user_photos,publish_stream',
     	'response_type=token'];
   		var query = queryParams.join('&');
   		var url = path + query;
   		window.location = url;
    } else {
    	// if token is added to URL, we get the value
       	// not needed here since we redirect to index2.cfm    	
    }
    	
   	</script>
    <div id="error_msg"></div>
    <div id="image"></div>
   	</body>
</html>