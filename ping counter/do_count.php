<?php

echo "UA: " . $_SERVER['HTTP_USER_AGENT'] . "<br>";

//connection:
// mysqli_connect("serverAddress", "username", "password", "database");
$link = mysqli_connect("localhost","script_counter_user","script_counter_pass","MyScriptStats") or die("Error1 " . mysqli_error($link));

// Check after MySQLi connection
if (isset($_REQUEST['agent_code'])) {
	$user_agent_string=$link->real_escape_string($_REQUEST['agent_code']);
} else {
	$user_agent_string="Nothing passed. Setting to: " . $link->real_escape_string($_SERVER['HTTP_USER_AGENT']);
}
//echo $user_agent_string . "<br>";
//exit;
$last_ping_count=0;

//Does my User Agent exist already ?
$query = $link->query("SELECT pingcount FROM UserAgents_Count WHERE user_agent_string='" . $user_agent_string . "'") or die("Error in the consult.." . mysqli_error($link));
$result=$query->fetch_object();
if (isset($result->pingcount)) {
	$last_ping_count=$result->pingcount;
	echo "Last Count: " . $last_ping_count . "<br>";
}


// Exists ?
if (isset($result->pingcount)) {

	$last_ping_count++;
	echo "Updating to: " . $last_ping_count . "<br>";

	//update
	if ($stmt = $link->prepare("UPDATE UserAgents_Count SET pingcount=? WHERE user_agent_string='" . $user_agent_string . "'")) {
		$stmt->bind_param('i', $last_ping_count);
		//$stmt->bindParam(':value', $value);

		$stmt->execute();
		$stmt->free_result();

	} else {
		echo "Errormessage: " . mysqli_error($link);
	}

} else {
	//insert
	echo "Inserting" . "<br>";

	if ($stmt = $link->prepare("INSERT INTO UserAgents_Count (user_agent_string, pingcount) VALUES (?, ?)")) {
		$tmp1=$user_agent_string;
		$tmp2=$last_ping_count+1;
		$stmt->bind_param('si', $tmp1, $tmp2);
		//$stmt->bindParam(':value', $value);

		if ($result = $stmt->execute()){

		  echo "success" . "<br>";
		  $stmt->free_result();

		} else {
		  echo "error" . "<br>";
		}

	} else {
		echo "Errormessage: " . mysqli_error($link);
	}
}

mysqli_close($link);
?>
