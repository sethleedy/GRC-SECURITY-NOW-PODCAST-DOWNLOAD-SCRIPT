<?php

//conection:
//$link = mysqli_connect("localhost","script_counter","script_counter_pass","MyScriptStats") or die("Error1 " . mysqli_error($link));
$link = new SQLite3("grc.db"); // This will create the file if it does not exist.

clearstatcache(); // First make sure the cache is clear so we get a proper file size.

// Check agent code
if (isset($_REQUEST['agent_code'])) {
	//$user_agent_string=$link->real_escape_string($_REQUEST['agent_code']);
	$user_agent_string=$link->escapeString($_REQUEST['agent_code']);
} else {
	//$user_agent_string="Nothing passed. Setting to: " . $link->real_escape_string($_SERVER['HTTP_USER_AGENT']);
	$user_agent_string="Nothing passed. Setting to: " . $link->escapeString($_SERVER['HTTP_USER_AGENT']);
}
//echo $user_agent_string . "<br>";
//exit;

//consultation:

// If looking for all records, check for an * on the agent_code,
// else do a normal search for %like or =
if ($user_agent_string == "*") {
	$query = "SELECT user_agent_string,pingcount FROM UserAgents_Count";
} else {
	if (strpos($user_agent_string,'%') !== false) {
		$WHERE_code=" like ";
	} else {
		$WHERE_code="=";
	}
		$query = "SELECT user_agent_string,pingcount FROM UserAgents_Count WHERE user_agent_string" . $WHERE_code . "'" . $user_agent_string . "'";
}

//execute the query.
$result = $link->query($query) or die("Error in the DB User Agent Check..." . $link->lastErrorMsg());

//display information:
$row=[];
echo "<ul>";
while($row = $result->fetchArray()) {
  echo "<li>Agent: " . $row["user_agent_string"] . ", Count: " . $row["pingcount"] . " </li>";
}
echo "</ul>";

?>
