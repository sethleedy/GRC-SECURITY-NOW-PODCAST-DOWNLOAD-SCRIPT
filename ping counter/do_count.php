<?php

if (isset($_SERVER['HTTP_USER_AGENT'])) {
	echo "UA: " . $_SERVER['HTTP_USER_AGENT'] . "<br>";
}

//connection:
#$link = mysqli_connect("localhost","script_counter","script_counter_pass","MyScriptStats") or die("Error1 " . mysqli_error($link));
$link = new SQLite3("grc.db"); // This will create the file if it does not exist.

// Setup new DB?
// If the db is zero in size, like a newly created DB from above, create the schema.
clearstatcache(); // First make sure the cache is clear so we get a proper file size.
if (file_exists("GRC.db") && filesize("GRC.db") == 0) {
	// Insert the schema
	echo "Creating DB...";
	$link->exec('CREATE TABLE IF NOT EXISTS UserAgents_Count (INTEGER NOT NULL PRIMARY KEY, pingcount INTEGER NOT NULL, user_agent_string STRING NOT NULL)') or die('Create db failed');
} else {
	echo nl2br("Found DB!\n");
}

// Check agent code
if (isset($_REQUEST['agent_code'])) {
	//$user_agent_string=$link->real_escape_string($_REQUEST['agent_code']);
	$user_agent_string=$link->escapeString($_REQUEST['agent_code']);
} else {
	//$user_agent_string="Nothing passed. Setting to: " . $link->real_escape_string($_SERVER['HTTP_USER_AGENT']);
	$user_agent_string="Nothing passed. Setting to: " . $link->escapeString($_SERVER['HTTP_USER_AGENT']);
}
//echo nl2br("$user_agent_string\n");
//exit;
$last_ping_count=0;

//Does my User Agent exist already ?
$query_results = $link->query("SELECT pingcount FROM UserAgents_Count WHERE user_agent_string='" . $user_agent_string . "'") or die("Error in the DB User Agent Check..." . $link->lastErrorMsg());
$result=$query_results->fetchArray(SQLITE3_ASSOC);
//print_r($result);
$result=(object) $result; // Cast as an object for use below.
//print_r($result);

if (isset($result->pingcount)) {
	$last_ping_count=$result->pingcount;
	echo nl2br("Last Count: " . $last_ping_count . "\n");
}

// Exists ?
if (isset($result->pingcount)) {

	$last_ping_count++;
	echo nl2br("Updating to: " . $last_ping_count . "\n");

	//update
	//if ($stmt = $link->prepare("UPDATE UserAgents_Count SET pingcount=? WHERE user_agent_string='" . $user_agent_string . "'")) {
	if ($stmt = $link->prepare("UPDATE UserAgents_Count SET pingcount=:pingcount WHERE user_agent_string='" . $user_agent_string . "'")) {
		$stmt->bindValue(':pingcount', $last_ping_count);
		
		$stmt->execute();

	} else {
		echo nl2br("Errormessage: " . $link->lastErrorMsg());
	}

} else {
	//insert
	echo nl2br("Inserting\n");

	if ($stmt = $link->prepare("INSERT INTO UserAgents_Count (user_agent_string, pingcount) VALUES (?, ?)")) {
		$tmp1=$user_agent_string;
		$tmp2=$last_ping_count+1;
		//$stmt->bind_param('si', $tmp1, $tmp2);
		$stmt->bindValue(1, $tmp1, SQLITE3_TEXT);
		$stmt->bindValue(2, $tmp2, SQLITE3_TEXT);
		
		if ($result = $stmt->execute()){

		  echo nl2br("success\n");
		  
		} else {
		  echo nl2br("error\n");
		}

	} else {
		echo "Errormessage: " . mysqli_error($link);
	}
}

//mysqli_close($link);
$link->close();

?>
