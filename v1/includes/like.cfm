<div id="fb-root"></div>
<cfoutput>
<!--- Synch Loading... but async is below. --->
<script src="http://connect.facebook.net/en_US/all.js##xfbml=1"></script>
<fb:like-box href="#REReplace(likeURL, '/$', '')#" width="640" show_faces="false" stream="false" header="false"></fb:like-box>

<script>

function recordLikeFootprint() {
	$.ajax({
		url: 'includes/FacebookPublisher.cfc',
		data: {  "method": "insertFootprint"
				,"event_token_ID" : "#SESSION.event_token#"
				,"r_elat_ID": "#SESSION.relats.like#"
				,"client_license_ID": "#SESSION.client_license_id#"
				,"sample_flag": "#SESSION.event_info.sample_flag#"
		},
		dataType: "json",
		type: 'POST'
	});
}

window.fbAsyncInit = function() {
	FB.init({appId: '#APPLICATION.appID#', status: true, cookie: true, xfbml: true});
	FB.Event.subscribe('edge.create', function(href, widget) {
		//alert('You just liked '+href);
		recordLikeFootprint();
	});
};
<!--- Async loading...
(function() {
 var e = document.createElement('script');
 e.type = 'text/javascript';
 e.src = document.location.protocol + '//connect.facebook.net/en_US/all.js';
 e.async = true;
 document.getElementById('fb-root').appendChild(e);
 }());
--->
</cfoutput>
</script>