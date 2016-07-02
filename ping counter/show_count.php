<?php

//conection:
// mysqli_connect("serverAddress", "username", "password", "database");
$link = mysqli_connect("localhost","script_counter_user","script_counter_pass","MyScriptStats") or die("Error1 " . mysqli_error($link));

// Check after MySQLi connection
if (isset($_REQUEST['agent_code'])) {
	$user_agent_string=$link->real_escape_string($_REQUEST['agent_code']);
} else {
	echo "Nothing passed. Please set the string 'agent_code'.";
	exit;
}
//echo $user_agent_string . "<br>";
//exit;

//consultation:
if (strpos($user_agent_string,'%') !== false) {
	$WHERE_code=" like ";
} else {
	$WHERE_code="=";
}
	$query = "select user_agent_string,pingcount from UserAgents_Count where user_agent_string" . $WHERE_code . "'" . $user_agent_string . "'";

//execute the query.
$result = $link->query($query) or die("Error in the consult.." . mysqli_error($link));

//display information:
echo "<ul>";
while($row = mysqli_fetch_array($result)) {
  echo "<li>Agent: " . $row["user_agent_string"] . ", Count: " . $row["pingcount"] . " </li>";
}
echo "</ul>";

?>
