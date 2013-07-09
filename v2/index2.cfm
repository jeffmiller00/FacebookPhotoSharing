<html xmlns:fb="http://www.facebook.com/2008/fbml" xmlns:og="http://opengraphprotocol.org/schema/">
	<head> 
   		<title>Facebook Publisher</title>
   		<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.6.1/jquery.min.js" type="text/javascript"></script>
   		<script type="text/javascript" src="js/fancybox/fancybox/jquery.fancybox-1.3.4.pack.js"></script>
		<cfif server_location NEQ "Staging">
			<cfinclude template="includes/analytics.cfm">
		</cfif> 
   		<link rel="stylesheet" href="js/fancybox/fancybox/jquery.fancybox-1.3.4.css" type="text/css" media="screen" />
   		<style>
   			#error_msg { font-size:16px;font-weight:bold;color:#9a2e2e;text-align:center}
   			.img_link { border:0px;}
   		</style>
		<style>
			.fbbutton {
				font-size: 11px;
				font-weight: 700;
				color: #666666;
				text-decoration: none;
				word-spacing: 0;
				line-height: 13px;
				text-align: center;
				vertical-align: top;
				background-color: #DDDDDD;
				background-image: none;
				opacity: 1;
				width: 40px;
				height: 16px;
				top: auto;
				right: auto;
				bottom: auto;
				left: auto;
				margin-top: 0;
				margin-right: 20;
				margin-bottom: 0;
				margin-left: 0px;
				padding-top: 2px;
				padding-right: 6px;
				padding-bottom: 2px;
				padding-left: 6px;
				border-top-width: 1px;
				border-right-width: 1px;
				border-bottom-width: 1px;
				border-left-width: 1px;
				border-top-color: #999999;
				border-right-color: #999999;
				border-bottom-color: #999999;
				border-left-color: #999999;
				border-top-style: solid;
				border-right-style: solid;
				border-bottom-style: solid;
				border-left-style: solid;
				position: static;
				display: inline-block;
				visibility: visible;
				z-index: auto;
				overflow-x: visible;
				overflow-y: visible;
				white-space: nowrap;
				clip: auto;
				float: right;
				clear: none;
				cursor: pointer;
				list-style-image: none;
				list-style-position: outside;
				list-style-type: none;
				marker-offset: auto;
				font-family: arial;
			}
			
			.fbbuttonlabel {
			
				font-family: arial;
			}
		</style>
  </head> 
   <body>
   	
   	<div id="fb-root"></div>
   	
   	<script type="text/javascript">
		
		window.fbAsyncInit = function() {
        FB.init({ appId: <cfoutput>'#APPLICATION.appID#'</cfoutput>,
            status: true,
            cookie: true,
            xfbml: true,
            oauth: true});

			this.vars = {
				access_token: '',
				album_id: '',
				items: '',
				user_id: '',
				photo_path: '',
				like_url: '',
				errorHandler: 'There was a problem posting your photo, please contact <a href="mailto:customer_support@eshots.com">customer_support@eshots.com</a>',
				counter: 1
			}
		
			FB.getLoginStatus(function(response) {
	 			if(response.authResponse) {
	 				// store access token
	 				vars.access_token = response.authResponse.accessToken;
					// get user info and send to server
					FB.api('/me', function(response) {
						if(response) {
							vars.user_id = response.id;
							$.each(response, function(key, val) {
								// create request string
								if(key == 'hometown' || key == 'location') {	
									vars.items += key + '=' + val.name + '&';
								} else {
									vars.items += key + '=' + val + '&';
								}
						 	});
						 	sendUserInformation(vars.items);
						 
						} else {
							outputErrorMsg();
						}
					});
				
				function sendUserInformation(items) {
				$.ajax({
				 	url: 'service.cfm',
				 	type: 'GET',
				 	data: items + 'access_token=' + vars.access_token +'&action=saveconsumer' + <cfoutput>'&EtClid=#EtClid#'</cfoutput>,
				 	cache: false,
				 	dataType: 'json',
				 	success: function(data) {
				 		// store values for like button (3000 = 3 seconds)
				 		displayPicture(data);
				 	},
				 	error: function(request, status, error) {
				 		// debug
				 		// alert(request.responseText.replace(/^\s\s*/, '').replace(/\s\s*$/, ''));
				 		// onError try to reconnect 3x
				 		if(vars.counter < 3) {
				 			sendUserInformation(items);
				 			vars.counter ++;
				 		} else {
				 			outputErrorMsg();
				 		}
				 	}
				 });
				}
				
				// register event for like button
				FB.Event.subscribe('edge.create',
				    function(response) {
				        // third ajax request to server when like button is pressed
				        $.ajax({
				        	url: 'service.cfm',
				        	data: {action: 'savelike', et: vars.event_token, cid: vars.consumer_id, <cfoutput>EtClid: '#EtClid#'</cfoutput>},
				        	type: 'GET',
				        	cache: false,
				        	dataType: 'html',
				        	success: function(data) {
				        		// close fancy box
				        		$.fancybox.close();
				        	},
				        	error: function(request) {
				        		// alert(request.responseText.replace(/^\s\s*/, '').replace(/\s\s*$/, ''));
				        		outputErrorMsg();
				        	}
				        });
				        
				        // close fancybox
				    }
				);
		
				
				// error handler	
				function outputErrorMsg() {
					$('#error_msg').html(vars.errorHandler);
					return;
				}
				
				// display picture and load like button
				function displayPicture(pdata) {
					// alert(pdata.phid+ ' '+vars.access_token);
					FB.api('/'+pdata.phid, function(response) {
					
										  
					  if(response) {
					  // 	alert(response.source);
					  	$("#image").html('<img src="' + response.source +'">');
					  	// load popup w/ like button
					
						$("#like_button").fancybox({
							// config
						});
						$("#like_button").click();
					  } else {
					  	outputErrorMsg();
					  }
					});
										//var html;
					//var url = 'https://graph.facebook.com/'+ pdata.phid + '?access_token=' + vars.access_token + '&callback=jsonp';
					
				}
			} else {
				// user not logged in
			}
		});
	};
	
	(function() {
        var e = document.createElement('script'); e.async = true;
        e.src = document.location.protocol
            + '//connect.facebook.net/en_US/all.js';
        document.getElementById('fb-root').appendChild(e);
    }());
		
   	</script>
   	<cfinclude template="includes/likeurl.cfm">
   	<a id="like_button" href="#inline"></a>
   	<div style="display: none;">
	   	<div id="inline">
	   		<div class="inline_content" id="in_content">
	   			<cfoutput><fb:like-box href="#likeurl#" width="300" show_faces="false" stream="false" header="true"></fb:like-box></cfoutput>
	   			
	   				<div style="display: block; width: 300px"><span class="fbbuttonlabel">Like us on Facebook!</span>
						<a href="javascript:;" onclick="$.fancybox.close();" class="fbbutton">Not Now</a>
					</div>
	   			
			</div>
		</div>
	</div>
    <div id="error_msg"></div>
    <div id="image"></div>
    <cfoutput><fb:like-box href="#likeurl#" width="640" show_faces="true" stream="false" header="false"></fb:like-box></cfoutput>
	</body>
</html>