<html> 
	<head> 
   		<title>Get Access Token</title>
   		<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.6.1/jquery.min.js" type="text/javascript"></script>
   		<style>
   			#error_msg { font-size:16px;font-weight:bold;color:#9a2e2e;text-align:center}
   		</style>
   </head> 
   <body>
   	
   	<div id="fb-root"></div>
   	
   	<script type="text/javascript">
   	
   		window.fbAsyncInit = function() {
        FB.init({ appId: '123842974364777',
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
				errorHandler: 'There was a problem posting your picture!<br> Please contact <a href="mailto:support@eshots.com">support@eshots.com</a>',
				counter: 1
			}
 		
 		authenticate();
 		
 		function authenticate() {
 			
	 		FB.getLoginStatus(function(response) {
	 			if(response.authResponse) {
	 				// logged and known to app
	 				// store access token
	 				vars.access_token = response.authResponse.accessToken;
	 				sendUserInformation();
	 			} else {
	 				// not logged in or unknow to app
	 				// prompt user to authorize app
	 				FB.login(function(response) {
	 					alert('bin hier not logged');
	 					if(response.authResponse) {
	 						// store access token
	 						vars.access_token = response.authResponse.accessToken
	 						sendUserInformation();
	 					}
	 				}, {scope: 'email,read_stream,user_birthday,user_photos,publish_stream'});			
				}
			});
		}
		
		function sendUserInformation() {
		
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
				 // first AJAX request to store user data
				 $.ajax({
				 	url: 'service.cfm',
				 	type: 'GET',
				 	data: vars.items + 'action=saveconsumer',
				 	cache: false,
				 	dataType: 'json',
				 	success: function(data) {
				 		// save picture's path
				 		vars.photo_path = data.ui;
				 		// create album if no album id is returned
				 		if(data.alid == '') {
				 			// check if album name was returned
				 			if(data.an != '')
				 				createNewAlbum(data);
				 			else
				 				outputErrorMsg();
				 		} else {
				 			// publish picture if album exists
				 			$.('#image').append('<img src="' + data.iu +'">');
				 			return;
				 		}
				 	},
				 	error: function(request, status, error) {
				 		// onError try to reconnect 3x
				 		if(vars.counter <= 3) {
				 			sendUserInformation();
				 			vars.counter ++;
				 		} else {
				 			outputErrorMsg();
				 		}
				 	}
				 });
				} else {
					outputErrorMsg();
				}
			});
		}
		
		function createNewAlbum(data) {
			FB.api('/me/albums', 'post', {name: data.an}, function(response) {
				//alert(response.id);
				if(response && response.id) {
					// store album id
					vars.album_id = response.id;
					//alert(album_id);
					sendAlbumInformation();
				} else {
					outputErrorMsg();
				}
			});
		}
		
		function sendAlbumInformation() {
			vars.counter = 1;
			// second AJAX request if album was created and picture can be uploaded
			 $.ajax({
			 	url: 'service.cfm',
			 	type: 'GET',
			 	data: {alid: vars.album_id},
			 	cache: false,
			 	dataType: 'json',
			 	success: function(data) {
			 		if(data.pid !='') { 
			 		// publish picture
			 		// publish picture if album exists
		 			$.('#image').append('<img src="' + vars.photo_path +'">');
		 			return;
		 			} else {
		 				outputErrorMsg();
		 			}
			 	},
			 	error: function(request, status, error) {
			 		// onError try to reconnect 3x
			 		if(vars.counter <= 3) {
			 			sendAlbumInformation();
			 			vars.counter ++;
			 		} else {
			 			outputErrorMsg();
			 		}
			 	}
			 });
		}
		
		// error handler	
		function outputErrorMsg() {
			$('#error_msg').html(vars.errorHandler);
			return;
		}
    };
    (function() {
        var e = document.createElement('script'); e.async = true;
        e.src = document.location.protocol
            + '//connect.facebook.net/en_US/all.js';
        document.getElementById('fb-root').appendChild(e);
    }());
   		
   		
   	</script>
    <div id="error_msg"></div>
    <div id="image"></div>
   	</body>
</html>