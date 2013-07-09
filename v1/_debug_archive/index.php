<?php 
$appID = "123842974364777";
$apiKey = "8fe3aaa6f0a314e7cbbfe1ced5cd878c";
$secret = "1c39087ac536765f9427a746e5067708";
$appurl = "http://apps.facebook.com/media_publisher_dev/";
$redirecturl = $appurl . "home.php?PARAMS";
$requiredPermissions = "publish_stream,user_birthday,email,user_photos";
$auth_url="http://www.facebook.com/dialog/oauth?client_id=".$appID."&redirect_uri=".$redirecturl."&scope=".$requiredPermissions;
$client_license_id = 11443;
$event_token = "FNDHJHYCDE";

$publicURL = "http://staging.eshots.com";
$finishedFilePath = "/var/www/html/eshots/fb/publisher/images/temp/";

$auth_url = str_replace("PARAMS", "event_token_clid=".$event_token."_".$client_license_id, $auth_url);

header( "location:" . $auth_url ) ;
?>