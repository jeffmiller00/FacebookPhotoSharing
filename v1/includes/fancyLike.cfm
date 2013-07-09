<cfinclude template="config.cfm">

<cfset fbPublisherCom = "FacebookPublisher">

<cfinvoke component="#fbPublisherCom#" method="getLikeURL" returnvariable="likeURL">
	<cfinvokeargument name="client_license_id" value="#SESSION.client_license_id#">
</cfinvoke>
<cfset likeURL = URLEncodedFormat(REReplace(likeURL, '/$', ''))>

<html>
<head>
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
			width: 45px;
			height: 16px;
			top: auto;
			right: auto;
			bottom: auto;
			left: auto;
			margin-top: 0;
			margin-right: 0;
			margin-bottom: 0;
			margin-left: 4px;
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
		}
	</style>
</head>

<body>
	<div id="fb-root"></div>
	<cfoutput>
	<!--- Synch Loading... but async is below. --->
	<script src="http://connect.facebook.net/en_US/all.js##xfbml=1"></script>
	<fb:like-box href="#REReplace(likeURL, '/$', '')#" width="225" show_faces="false" stream="false" header="false"></fb:like-box>

	
<!--- 	<iframe src="http://www.facebook.com/plugins/likebox.php?href=#likeURL#&amp;width=221&amp;colorscheme=light&amp;show_faces=false&amp;border_color&amp;stream=false&amp;header=false&amp;height=62" scrolling="no" frameborder="0" style="border:none; overflow:hidden; width:300px; height:62px;" allowTransparency="true"></iframe> --->
	
	<div style="display: block; width: 300px">Like us on Facebook!
		<a href="javascript:;" onclick="$.fancybox.close();" class="fbbutton">Not Now</a>
	</div>
	
	<script>
	
	function recordLikeFootprint() {
		$.ajax({
			url: '#fbPublisherCom#',
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
			$.fancybox.close();
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

</body>
</html>