#!/bin/bash

# Created: 2012-05-25
# Last Updated: 2019-02-22

# This script will have updates at https://github.com/sethleedy/GRC-SECURITY-NOW-PODCAST-DOWNLOAD-SCRIPT
# Script homepage @ http://techblog.sethleedy.name/?p=24172


# Initialization.
this_version=2.1
do_gh_update=false
gh_version=-1
curr_directory_name="${PWD##*/}"
#echo "curr_directory_name: $curr_directory_name" > test.txt
script_directory_path="$(pwd)"
#echo "script_directory_path: $script_directory_path" >> test.txt
script_name=$(echo $0 | cut -d "/" -f 2) # Removes the './' from the script name
#echo "script_name: $script_name" >> test.txt
script_location_and_name="$script_directory_path/$script_name"
#echo "script_location_and_name: $script_location_and_name" >> test.txt
find_latest_episode_url="http://www.grc.com/securitynow.htm"

#EPISODE_NAME_AUDIO_HQ_URL="http://media.grc.com/sn"
EPISODE_NAME_AUDIO_LQ_URL="http://media.grc.com/sn"
EPISODE_NAME_AUDIO_HQ_URL="http://cdn.twit.tv/audio/sn"

EPISODE_NAME_AUDIO_TEXT_URL="http://www.grc.com/sn"
EPISODE_NAME_AUDIO_PDF_URL="http://www.grc.com/sn"
EPISODE_NAME_AUDIO_HTML_URL="http://www.grc.com/sn"
EPISODE_NAME_AUDIO_SHOWNOTES_URL="http://www.grc.com/sn"
EPISODE_NAME_VIDEO_HD_URL="http://cdn.twit.tv/video/sn"
EPISODE_NAME_VIDEO_HQ_URL="http://cdn.twit.tv/video/sn"
EPISODE_NAME_VIDEO_LQ_URL="http://cdn.twit.tv/video/sn"
skip_wget_digital_check=""
wget_agent_name="GRCDownloader_v$this_version"

# Sizes in Kilo's
DISK_SPACE=1000
DISK_SPACE_MIN_FOR_ONE_AUDIO=55000 # 55 MB - Largest I saw on the listing @ GRC.COM
DISK_SPACE_MIN_FOR_ALL_AUDIO=3200000 # 3,200 MB or 3.2 GB as Noted on the GRC Newsgroup in 2012-05. This is EST default. Made it dynamic further down.
DISK_SPACE_MIN_FOR_ONE_HD_VIDEO=2000000
DISK_SPACE_MIN_FOR_ALL_HD_VIDEO=1000000000 # Est for 450 HD videos. This will not all be used, as not all videos were recorded in HD.
DISK_SPACE_MIN_FOR_ONE_VIDEO=600000 # 600 MB for HQ version
DISK_SPACE_MIN_FOR_ALL_VIDEO=20000000
DISK_SPACE_MIN_FOR_ONE_TEXT=35
DISK_SPACE_MIN_FOR_ALL_TEXT=12000
DISK_SPACE_MIN_FOR_ONE_PDF=67450
DISK_SPACE_MIN_FOR_ALL_PDF=23944750
DISK_SPACE_MIN_FOR_ONE_HTML=67450
DISK_SPACE_MIN_FOR_ALL_HTML=23944750

# Some defaults
EPISODE=1
EPISODE_TO=1
download_episode_number=false
download_latest=false
download_all=false
pretend_mode=false
par_downloads=false # Set this to true for multiple downloads at once by default. Otherwise use the argument "-pd 4"
par_downloads_count=4 # Set this to how many at once or use the argument "-pd 4"
new_download_home=""
quite_mode=false
cache_mode=false
declare -a pid
declare -a add_to_headers
declare -a check_program_exists_arr
download_audio_hq=false
download_audio_lq=false
download_video_hd=false
download_video_hq=false
download_video_lq=false
download_episode_text=false
download_episode_pdf=false
download_episode_html=false
download_episode_shownote=false
download_temp_txt_search_dir=".tmp_search_txt"
do_file_format=false
formatted_file_name=""
search_txt_local=false
search_txt_download=false
search_string=""
search_echo_override_mode=false
do_episode_downloading=false
create_rss_feeds=false
create_rss_audio=false
create_rss_video=false
create_rss_text=false
create_rss_mode=false
rss_filename=""
rss_feed_text_limit=""


# RSS Feed Variables
HTTPLINK=""
CHANNELFEEDTITLE="GRC Security Now RSS Feed"
CHANNELFEEDLINK="http://www.grc.com/securitynow.htm"
CHANNELFEEDCREATIONLINK="http://techblog.sethleedy.name/sn-feed.rss"
CHANNELFEEDDESC="Listing all episodes of {Audio|Video|Text|All Types}"
CHANNELIMAGE="https://www.grc.com/image/snonwhite.gif"

Dev_Coder_email="code@sethleedy.name"

# Send a "Ping" back to my server. This allows me to know that my script is being used out in the wild.
# The request will show up in my blog and I can parse it later for stats.
# Sends out this script version.
# Sends out the date/time ran.
function send_ping() {

	datetime=`date '+%Y-%m-%d-%R'`
	wget $skip_wget_digital_check -qb -O /dev/null -U "$wget_agent_name" "http://techblog.sethleedy.name/do_count.php?datetime=$datetime&agent_code=GRCDownloader_v$this_version" >/dev/null 2>&1

}

# Check for script updates from GitHub. Download if -u is passed
function check_and_update_script() {
	
	# First compare versions
	# Get latest version listed on GitHub
	check_url "https://raw.githubusercontent.com/sethleedy/GRC-SECURITY-NOW-PODCAST-DOWNLOAD-SCRIPT/master/GRC-Downloader.sh"
	if [ $? -eq 0 ]; then
		wget -U "$wget_agent_name" -q -O .update_check.txt "https://raw.githubusercontent.com/sethleedy/GRC-SECURITY-NOW-PODCAST-DOWNLOAD-SCRIPT/master/GRC-Downloader.sh"
		if [ $? -eq 0 ]; then
			gh_version=$(grep -i "this_version" .update_check.txt | head -n 1 | cut -d "=" -f 2)
			
			# Is this script out of date ? Do we want to update it ?
			# Will update if the "-u" is passed.
			# http://stackoverflow.com/questions/8654051/how-to-compare-two-floating-point-numbers-in-a-bash-script
			if (( $(echo "$this_version < $gh_version" | bc -l) )) && $do_gh_update ; then
				# Backup the current script just in case
				cp -f "$0" "$0.bak"
				cp -f .update_check.txt "$0"
				echo "Updated Script to $gh_version, by -u command"
				echo "Old script is now: $0.bak"
			#else
				#echo "$gh_version" # Echo out the version as a return of the function.
			fi
		else
			echo "Failed to download the update version file."
		fi
	else
		echo "-"
	fi	
	
}

# Helper Function to remove annoying CR's from text files that are encoded in DOS format. When I grab the strings from Security Now text files, it picks them up too. This will remove them.
function strip_text_cr() {

	echo "$1" | tr -d "\r"

}

# Do script shutdown
function do_script_shutdown() {

	rm -f securitynow.htm
	rm -f wget-log*
	rm -f .update_check.txt

	exit $1
}

# trap keyboard interrupt (control-c)
trap control_c SIGINT
function control_c() {

	echo " "
	echo "Stopping download(s) before exiting."

	# Kill all current wget downloads
	if [ -z "${pid+xxx}" ]; then # We may not have yet reached the point in the script where this was created.
		for r in "${pid[@]}" ; do
			kill $r >/dev/null 2>&1
		done
	fi

	# Kill the subsearch shell if running
	kill $subsearch_pid >/dev/null 2>&1

	echo "Script killed!"

	# Call script shutdown
	do_script_shutdown 1

	# Should not reach here..
	exit 1
}

# See if the URL is valid
function check_url() {

	wget $skip_wget_digital_check -U "$wget_agent_name" -q --spider "$1"
	returncode=$?

	if [ $returncode != 0 ]; then
		wget --no-check-certificate -U "$wget_agent_name" -q --spider "$1"
		returncode=$?
		if [ $returncode == 0 ]; then
			echo " "
			echo "==> -skip-digital-cert-check automatically ENABLED"
			skip_wget_digital_check=" --no-check-certificate "
		else
			#echo " "
			#echo "Check_URL() Error: $returncode"
			#echo "URL: $1"
			#echo "You may have to turn on -skip-digital-cert-check"
			return 1
		fi
	else
		return 0
	fi

}

# Check disk space.
function chk_disk_space() { # Pass a number in whole Kilo bytes.

	DISK_SPACE=$(df "`pwd`" | grep -iv "Filesystem" | awk '{print $4}')
	#echo "DISK SPACE: $DISK_SPACE Needed: $1"
	#exit

	if [ "$DISK_SPACE" -le "$1" ]; then
		echo " "
		echo "Minimum amount of disk space not available! Exiting."
		return 1
	else
		return 0
	fi

}

# Check if some programs are installed or not.
# Use the special array, check_program_exists_arr[0]="foo"
# Then pass it to this function as parameter $1.
# Function will remove any programs not found from the array, all remains are the found programs.
# Outside the function, choose a program from the array.
# Could order the input of the array as desired choices and use the last one in the array as choicest.
# echo "-${check_program_exists_arr[${#check_program_exists_arr[*]}]}-"
function check_program_exists_multi() {

	check_program_exists_arr=("${!1}")
	chi_num=0
    for chi in "${check_program_exists_arr[@]}"; do
        if ! $(which "$chi" >/dev/null); then
			#if ! $quite_mode ; then
			#	echo "Could not find: $chi"
			#fi
			unset check_program_exists_arr[$chi_num]
		fi
		chi_num=$chi_num+1
    done
}


function output_help() {

	echo " "
	echo "Seth Leedy's GRC Security Now Downloader v$this_version"
	echo " "
	echo "Options are as follows:"
	echo "-ep		Specifies the episodes to download. You can specifiy 1 episode via just the number. Eg: -ep 25"
	echo "		It also supports a range separated by a colon. Eg: -ep 1:25"
	echo "		OR -ep 250:latest to grab all episodes from number 250 to whatever the latest is."
	echo "-latest		Download the latest episode. It will try to check for the latest whenever the script is run."
	echo "		If this is flagged, it will put the latest episode as the file to download."
	echo "-all		This will download all episodes from 1 to -latest"
	echo "		Note: If no options are used to indicate what episode to download, the script will search the local directory for the latest episode and download the next one automatically."
	echo " "

	echo "Combine the above option(s) with one or more in the next section:"
	echo "-ahq		Download High Quality Audio format."
	echo "-alq		Download Low Quality Audio format"
	echo "-vhd		Download High Definition(HD) Quality Video format"
	echo "-vhq		Download High Quality Video format"
	echo "-vlq		Download Low Quality Video format"
	echo "-eptxt		Download the text transcript of the episode"
	echo "-eppdf		Download the pdf transcript of the episode"
	echo "-ephtml		Download the html transcript of the episode"
	echo "-epnotes	Download the show notes of the episode(Early shows had none)"

	echo "------------------------------------------------------------------------------------"
	echo "Search Mode:"
	echo "-dandstxt	Download and Search, will download all text episodes and search insensitively for the text you enter here."
	echo "	OR"
	echo "-stxt		Search insensitively the local directory .txt episodes for text you enter here."
	echo "------------------------------------------------------------------------------------"
	echo "Create RSS Feed file for RSS News Readers:"
	echo "-create-rss-audio	Will create a RSS feed file for RSS News Readers containing the Show's audio files."
	echo "-create-rss-video	Will create a RSS feed file for RSS News Readers containing the Show's video files."
	echo "-create-rss-text	Will create a RSS feed file for RSS News Readers containing the Show's Notes and Transcriptions."
	echo "-create-rss-feeds	Will create a RSS feed file for RSS News Readers containing all media files."
	echo "-rss-filename		Sets the path and filename of the rss feed file. If excluded, defaults to 'security_now.rss' in the current directory."
	echo "-rss-limit		Limits how much text is placed in the RSS feed file from each episode. Default none. Try -rss-limit 100"
	echo "------------------------------------------------------------------------------------"
	echo "Misc Options:"

	echo "-d		Download the files into this specified directory. Eg: -d /home/user/Downloads/security_now"
	echo "-ff		File Format. Allows you to specify the order of the elements that make up the filename."
	echo "			Choose from: <showname> <episodenumber> <episodename> <episodeyear> <date> <type> <raw>(same as the downloaded filename)"
	echo "			The default is: -ff \"<raw>\""
	echo "			Presets:"
	echo "				Ordered:	-ff ordered"
	echo "					Which is: \"<number> <name> - <date>\""
	echo "				Kodi:		-ff kodi"
	echo "					Which is: \"<showname> S<episodeyear>E<episodenumber>\""
	echo "-p		Pretend mode. It will only spit out the headers and numbers. It will not download any files"
	echo "			(except the webpage needed to find the latest episodes)"
	echo "-q		Quite mode. Minimal on search and nothing but errors on episode downloads will be outputted to the screen."
	echo "-pd		Specify how many parallel downloads when downloading more than one. Eg: -pd 2"
	echo "-u		Auto update the script from GitHub. Run this command alone, as it will not remember the other arguments, nor restart."
	echo "-skip-digital-cert-check"
	echo "		Sometimes, if running through a proxy, wget will refuse to download from GRC. Try this to skip the digital certificate safety check."
	echo "-h		This help output."
	echo " "

	exit 0

}

function do_headers() {

	# Convert the passed array into something usable
	declare -a pass_arr=("${!1}") # Crazy syntax here !

	# Make a nice looking border the same length as my variable + 4 for the edge.
	var_size=$((21+${#latest_episode}+${#latest_episode_name}))
	#echo $var_size

	# Output title.
	echo " "
	echo "Seth Leedy's GRC Security Now Downloader v$this_version"
	echo "GitHub URL: https://github.com/sethleedy/GRC-SECURITY-NOW-PODCAST-DOWNLOAD-SCRIPT"
	echo "Home URL: http://techblog.sethleedy.name/?p=24172"
	echo " "
	str=$(printf "%${var_size}s"); echo ${str// /#}
	echo "# ""Latest Episode: $latest_episode $latest_episode_name"" #"
	str=$(printf "%${var_size}s"); echo ${str// /#}
	echo " "

	for e in "${pass_arr[@]}" ; do
		echo "$e"
	done

}

# Compress / UnCompress the cache based on available programs.
function do_cache() {

	# Create temp download area
	curr_directory_name_temp=$curr_directory_name # Get the current directory name in a temp var.
	if [ "$curr_directory_name_temp" != "$download_temp_txt_search_dir" ]; then # make sure we are not already inside the directory to search files
		if [ ! -d "$download_temp_txt_search_dir" ]; then # If it does not exists already
			mkdir $download_temp_txt_search_dir >/dev/null 2>&1 # Create the directory to hold all text epi to search for text within.
		fi
	fi

	# Test to see if the background process to fill the directory is still ongoing based on the marker file, if not there proceed with compression.
	# If it is there, exit the function. The foreground process, that created the background process, can compress later. Normally when the script is shutting down.
	if [ -f "$script_directory_path/$download_temp_txt_search_dir/._fill_cache_working_" ]; then
		return
	fi

	# A marker to know either the program is still working in the background, filling the cache, OR it crashed.
	touch "$script_directory_path/$download_temp_txt_search_dir/._do_cache_working_"

	# If compressed cache exists, uncompress it.
	# Check to see what program we can use to compress/uncompress the cache.
	check_program_exists_arr[0]="7z"
	check_program_exists_arr[1]="gzip"
	check_program_exists_arr[2]="zip"
	check_program_exists_arr[3]="bzip2"
	check_program_exists_arr[4]="p7zip" # Install p7zip-full. One package had p7zip, but not 7z. So it could only decompress.

	# Array will be empty if nothing is found.
	check_program_exists_multi check_program_exists_arr[@] # This will remove from the array any programs that are not detected.

	# Debug
	#echo "${check_program_exists_arr[0]}"
	#exit
	if [[ ${check_program_exists_arr[0]} != "" ]] ; then # Empty ?
		if ! $quite_mode ; then
			echo " "
			echo "Using compression program: ${check_program_exists_arr[0]}"
		fi

		# Use proper command/arguments for which program is available
		case "${check_program_exists_arr[0]}" in
		'gzip')
			if [ "$curr_directory_name_temp" != "$download_temp_txt_search_dir" ]; then
				cd "$download_temp_txt_search_dir"
				skip_cd=false
			else
				skip_cd=true
			fi
			if [[ "$1" == "uncompress" ]]; then
				if ! $quite_mode ; then
					echo "Uncompressing cache in foreground"
				fi
				gunzip -q *.gz &> /dev/null
				
			elif [[ "$1" == "compress" ]]; then
				if ! $quite_mode ; then
					echo "Compressing cache in background"
				fi
				gzip -9 *.txt > /dev/null 2>&1
				
			fi
			
			if ! $skip_cd; then
				cd ..
			fi
			;;
		'zip')
			if [ "$curr_directory_name_temp" != "$download_temp_txt_search_dir" ]; then
				cd "$download_temp_txt_search_dir"
				skip_cd=false
			else
				skip_cd=true
			fi
			if [[ "$1" == "uncompress" ]]; then
				if ! $quite_mode ; then
					echo "Uncompressing cache in foreground"
				fi
				unzip -qq -o cache.zip &> /dev/null
				rm -f cache.zip >/dev/null 2>&1
			elif [[ "$1" == "compress" ]]; then
				if ! $quite_mode ; then
					echo "Compressing cache in background"
				fi
				{ zip -9 -qq cache.zip *.txt > /dev/null; rm -f *.txt > /dev/null; } &
			fi
			
			if ! $skip_cd; then
				cd ..
			fi
			;;
		'bzip2')
			if [ "$curr_directory_name_temp" != "$download_temp_txt_search_dir" ]; then
				cd "$download_temp_txt_search_dir"
				skip_cd=false
			else
				skip_cd=true
			fi
			if [[ "$1" == "uncompress" ]]; then
				if ! $quite_mode ; then
					echo "Uncompressing cache in foreground"
				fi
				find *.bz2 -type f -exec bunzip2 -q {} ;
				
			elif [[ "$1" == "compress" ]]; then
				if ! $quite_mode ; then
					echo "Compressing cache in background"
				fi
				#bzip2 -sqf -9 *.txt >/dev/null 2>&1
				find *.txt -type f -exec bzip2 -q -sqf -9 {} ;
				
			fi
			
			if ! $skip_cd; then
				cd ..
			fi
			;;
		'7z')
			if [ "$curr_directory_name_temp" != "$download_temp_txt_search_dir" ]; then
				cd "$download_temp_txt_search_dir"
				skip_cd=false
			else
				skip_cd=true
			fi
			#echo "$curr_directory_name_temp"
			#echo "$download_temp_txt_search_dir"
			#exit
			if [[ "$1" == "uncompress" ]]; then
				if ! $quite_mode ; then
					echo "Uncompressing cache in foreground"
				fi
				7z e cache.7z > /dev/null
				rm -f cache.7z > /dev/null
			elif [[ "$1" == "compress" ]]; then
				if ! $quite_mode ; then
					echo "Compressing cache in background"
				fi

				# Run compression in background so there is no delay on the terminal
				# This may cause issues if the user reuses the script immediately. eg: deleting files at the same time as rechecking or downloading on the new script run.
				{ 7z a -mx=9 -bsp0 -bso0 cache.7z *.txt; rm -f *.txt > /dev/null; } &
			fi
			
			if ! $skip_cd; then
				cd ..
			fi
			;;
		'p7zip')
			if [ "$curr_directory_name_temp" != "$download_temp_txt_search_dir" ]; then
				cd "$download_temp_txt_search_dir"
				skip_cd=false
			else
				skip_cd=true
			fi
			#echo "$curr_directory_name_temp"
			#echo "$download_temp_txt_search_dir"
			#exit
			if [[ "$1" == "uncompress" ]]; then
				if ! $quite_mode ; then
					echo "Uncompressing cache in foreground"
				fi
				p7zip -d cache.7z &> /dev/null
				rm -f cache.7z &> /dev/null
			elif [[ "$1" == "compress" ]]; then
				if ! $quite_mode ; then
					echo "Compressing cache in background"
				fi

				# Run compression in background so there is no delay on the terminal
				# This may cause issues if the user reuses the script immediately. eg: deleting files at the same time as rechecking or downloading on the new script run.
				{ p7zip cache.7z *.txt > /dev/null; rm -f *.txt > /dev/null; } &
			fi
			
			if ! $skip_cd; then
				cd ..
			fi
			;;
		esac

	else
		echo "No compression program found. Install a compression program like 7z or bzip2 to compress the cached search files."
	fi

	# Remove Marker
	rm "$script_directory_path/$download_temp_txt_search_dir/._do_cache_working_"

}

# Scans the directory to find the highest number in the CACHE list of downloaded epi text files.
function do_find_last_local_episode_cache() {
	
	# This will naturaly sort the epi filenames by the numbers within them, then extract the final number
	# ls -v | tail -n1 | cut -d "-" -f 2 | cut -d "." -f 1
	declare last_local_number
	last_local_number=$(ls -v .tmp_search_txt | tail -n1 | cut -d "-" -f 2 | cut -d "." -f 1)

	if [ "$last_local_number" == "" ]; then
		last_local_number=0
	fi

	echo $last_local_number
}

# Scans the directory to find the highest number in the list of downloaded files.
function do_find_last_local_episode() { # You can pass file types to search for instead of all files. "mp4"
	
	# This will naturaly sort the epi filenames by the numbers within them, then extract the final number
	# ls -v | tail -n1 | cut -d "-" -f 2 | cut -d "." -f 1
	
	if [ "$1" != "" ]; then
		echo $(ls -v *.$1 | tail -n1 | cut -d "-" -f 2 | cut -d "." -f 1)
	else
		echo $(ls -v | tail -n1 | cut -d "-" -f 2 | cut -d "." -f 1)
	fi
}

function do_find_latest_episode() {
	# Find the latest episode.
	check_url "$find_latest_episode_url"
	if [ $? -eq 0 ]; then
		if [ -e securitynow.htm ]; then
			rm -f securitynow.htm
		fi

		wget $skip_wget_digital_check -U "$wget_agent_name" -q -O securitynow.htm "$find_latest_episode_url"

		if [ $? -eq 0 ]; then
			if [ -e securitynow.htm ]; then
				
				# This is the variable to use in the rest of the code
				latest_episode=$(grep -i '<font size=1>Episode&nbsp;#' securitynow.htm | head -n 1 | cut -d "#" -f 2 | cut -d " " -f 1)
				# This is the variable to use in the rest of the code
				latest_episode_name=$(grep -i '<font size=1>Episode&nbsp;#' securitynow.htm | head -n 1 | sed -n '/<b>/,/<\/b>/p'  | sed -e '1s/.*<b>//' -e '$s/<\/b>.*//')

				# Try and make a guesstimate about the amout of space needed for all episodes.
				# Overwrites the defaults
				let DISK_SPACE_MIN_FOR_ALL_AUDIO2=$DISK_SPACE_MIN_FOR_ONE_AUDIO*$latest_episode
				let DISK_SPACE_MIN_FOR_ALL_VIDEO2=$DISK_SPACE_MIN_FOR_ONE_VIDEO*$latest_episode
				let DISK_SPACE_MIN_FOR_ALL_HD_VIDEO2=$DISK_SPACE_MIN_FOR_ONE_HD_VIDEO*$latest_episode
				let DISK_SPACE_MIN_FOR_ALL_TEXT2=$DISK_SPACE_MIN_FOR_ONE_TEXT*$latest_episode
				let DISK_SPACE_MIN_FOR_ALL_PDF2=$DISK_SPACE_MIN_FOR_ONE_PDF*$latest_episode
				let DISK_SPACE_MIN_FOR_ALL_HTML2=$DISK_SPACE_MIN_FOR_ONE_HTML*$latest_episode
				DISK_SPACE_MIN_FOR_ALL_AUDIO=$DISK_SPACE_MIN_FOR_ALL_AUDIO2
				DISK_SPACE_MIN_FOR_ALL_HD_VIDEO=$DISK_SPACE_MIN_FOR_ALL_HD_VIDEO2
				DISK_SPACE_MIN_FOR_ALL_VIDEO=$DISK_SPACE_MIN_FOR_ALL_VIDEO2
				DISK_SPACE_MIN_FOR_ALL_TEXT=$DISK_SPACE_MIN_FOR_ALL_TEXT2
				DISK_SPACE_MIN_FOR_ALL_PDF=$DISK_SPACE_MIN_FOR_ALL_PDF2
				DISK_SPACE_MIN_FOR_ALL_HTML=$DISK_SPACE_MIN_FOR_ALL_HTML2
				#echo $DISK_SPACE_MIN_FOR_ALL_VIDEO

				rm -f securitynow.htm
			fi
		fi
	else
		echo "Could not retrieve Episode Listing from URL: $find_latest_episode_url"
		exit 1
	fi
}

# IF downloading files, this is the function that does it.
function do_downloading() {

	# Setup Loop here to download a range of episodes.
	#loop from EPISODE to EPISODE_TO
	slot_downloads=$par_downloads_count

	#echo "Slot download: $slot_downloads"
	c=$EPISODE
	#for (( c=$EPISODE; $c<=$EPISODE_TO; c=$(($c+$slot_downloads)) )); do
	while [[ $c -le $EPISODE_TO ]]; do

		# Convert the interger to leading zeros for proper filename.
		#EPISODE_Cur=$( printf "%.4d" $d )
		EPISODE_Cur=$(padLeadingZeros 4 $(stripLeadingZeros "$d"))
		declare dash_o

		if  $download_audio_hq ; then
			for (( d=$c; d<$(($c+$slot_downloads)); d++ )); do

				# If the difference is less, then we can't download more.
				epi_no_zero="$(echo $EPISODE_TO | sed 's/0*//')"
				#echo "D: $d"
				#echo "epi: $epi_no_zero"
				if [ $d -gt $epi_no_zero ]; then
					#echo "Over Number: $EPISODE_TO"
					break
				fi

				#EPISODE_Cur=$( printf "%03d\n" $(( 10#$d)) )
				EPISODE_Cur=$(padLeadingZeros 3 $(stripLeadingZeros "$d"))
				#EPISODE_NAME_AUDIO_HQ="${EPISODE_NAME_AUDIO_HQ_URL}/sn-${EPISODE_Cur}.mp3"
				EPISODE_NAME_AUDIO_HQ="${EPISODE_NAME_AUDIO_HQ_URL}/sn${EPISODE_Cur}/sn${EPISODE_Cur}.mp3"

				if ! $quite_mode ; then
					echo -e "${homeclr}Downloading:\tHQ audio episode ${EPISODE_Cur}..."
				fi

				tpid=`wget $skip_wget_digital_check $new_download_home -U "$wget_agent_name" -N -c -qb "$EPISODE_NAME_AUDIO_HQ"`
				#tpid=`wget $skip_wget_digital_check -U "$wget_agent_name" -N -c "$EPISODE_NAME_AUDIO_HQ"` # Debugging
				ttpid=(`echo $tpid | cut -d " " -f 5 | cut -d "." -f 1`)
				pid[$d]=$ttpid

				#echo "PID: ${pid[$d]}"
			done
		fi
		if  $download_audio_lq ; then
			for (( d=$c; d<$(($c+$slot_downloads)); d++ )); do # Does not like variable $d within here on the second expression in the loop. Have to use $c.
				# If the difference is less, then we can't download more.
				epi_no_zero="$(echo $EPISODE_TO | sed 's/0*//')"
				#echo "D: $d"
				#echo "epi: $epi_no_zero"
				if [ $d -gt $epi_no_zero ]; then
					#echo "Over Number: $EPISODE_TO"
					break
				fi

				EPISODE_Cur=$(padLeadingZeros 3 $(stripLeadingZeros "$d")) # Audio is 3 0s long. Fix this after episode 999.
				EPISODE_NAME_AUDIO_LQ="${EPISODE_NAME_AUDIO_LQ_URL}/sn-${EPISODE_Cur}-lq.mp3"

				if ! $quite_mode ; then
					echo -e "${homeclr}Downloading:\tLQ audio episode ${EPISODE_Cur}..."
				fi

				tpid=`wget $skip_wget_digital_check $new_download_home -U "$wget_agent_name" -N -c -qb "$EPISODE_NAME_AUDIO_LQ"`
				ttpid=(`echo $tpid | cut -d " " -f 5 | cut -d "." -f 1`)
				pid[$d]=$ttpid

				#echo "PID: ${pid[$d]}"
			done
			#echo "D2=$d"
		fi
		if  $download_episode_text ; then
			for (( d = $c; d < $(($c + $slot_downloads)); d++ )); do

				# If the difference is less, then we can't download more.
				epi_no_zero="$(echo $EPISODE_TO | sed 's/0*//')"
				#echo "D: $d"
				#echo "epi: $epi_no_zero"
				if [ $d -gt $epi_no_zero ]; then
					#echo "Over Number: $EPISODE_TO"
					break
				fi

				EPISODE_Cur=$(padLeadingZeros 3 $(stripLeadingZeros "$d")) # Audio is three 0s long. Fix this after episode 999.
				EPISODE_NAME_AUDIO_TEXT="${EPISODE_NAME_AUDIO_TEXT_URL}/sn-${EPISODE_Cur}.txt"

				if ! $quite_mode || ( $search_echo_override_mode && ! $quite_mode ) ; then
					if $search_echo_override_mode ; then
						echo -e "${homeclr}Checking or Downloading:\ttext episode ${EPISODE_Cur}"
					else
						echo -e "${homeclr}Downloading:\ttext episode ${EPISODE_Cur}"
					fi
				fi

				# Contruct the filename format for the -ff argument.
				if $do_file_format ; then
					construct_the_filename_format
					
					formatted_file_name="$formatted_file_name.txt"
					#declare dash_o
					dash_o="-O "
				fi

				tpid=`wget $skip_wget_digital_check $new_download_home $dash_o"$formatted_file_name" -U "$wget_agent_name" -N -c -qb "$EPISODE_NAME_AUDIO_TEXT"`
				ttpid=(`echo $tpid | cut -d " " -f 5 | cut -d "." -f 1`)
				pid[$d]=$ttpid

				#echo "$formatted_file_name"
			done
		fi
		if  $download_episode_pdf ; then
			for (( d=$c; d<$(($c+$slot_downloads)); d++ )); do

				# If the difference is less, then we can't download more.
				epi_no_zero="$(echo $EPISODE_TO | sed 's/0*//')"
				#echo "D: $d"
				#echo "epi: $epi_no_zero"
				if [ $d -gt $epi_no_zero ]; then
					#echo "Over Number: $EPISODE_TO"
					break
				fi

				EPISODE_Cur=$(padLeadingZeros 3 $(stripLeadingZeros "$d")) # Audio is 3 0s long. Fix this after episode 999.
				EPISODE_NAME_AUDIO_PDF="${EPISODE_NAME_AUDIO_PDF_URL}/sn-${EPISODE_Cur}.pdf"

				if ! $quite_mode ; then
					echo -e "${homeclr}Downloading:\tepisode text ${EPISODE_Cur}..."
				fi

				tpid=`wget $skip_wget_digital_check $new_download_home -U "$wget_agent_name" -N -c -qb "$EPISODE_NAME_AUDIO_PDF"`
				ttpid=(`echo $tpid | cut -d " " -f 5 | cut -d "." -f 1`)
				pid[$d]=$ttpid

				#echo "PID: ${pid[$d]}"
			done
		fi
		if  $download_episode_html ; then
			for (( d=$c; d<$(($c+$slot_downloads)); d++ )); do

				# If the difference is less, then we can't download more.
				epi_no_zero="$(echo $EPISODE_TO | sed 's/0*//')"
				#echo "D: $d"
				#echo "epi: $epi_no_zero"
				if [ $d -gt $epi_no_zero ]; then
					#echo "Over Number: $EPISODE_TO"
					break
				fi

				EPISODE_Cur=$(padLeadingZeros 3 $(stripLeadingZeros "$d")) # Audio is 3 0s long. Fix this after episode 999.
				EPISODE_NAME_AUDIO_HTML="${EPISODE_NAME_AUDIO_HTML_URL}/sn-${EPISODE_Cur}.htm"

				if ! $quite_mode ; then
					echo -e "${homeclr}Downloading:\tepisode text ${EPISODE_Cur}..."
				fi

				tpid=`wget $skip_wget_digital_check $new_download_home -U "$wget_agent_name" -N -c -qb "$EPISODE_NAME_AUDIO_HTML"`
				ttpid=(`echo $tpid | cut -d " " -f 5 | cut -d "." -f 1`)
				pid[$d]=$ttpid

				#echo "PID: ${pid[$d]}"
			done
		fi
		if  $download_episode_shownote ; then
			for (( d=$c; d<$(($c+$slot_downloads)); d++ )); do

				# If the difference is less, then we can't download more.
				epi_no_zero="$(echo $EPISODE_TO | sed 's/0*//')"
				#echo "D: $d"
				#echo "epi: $epi_no_zero"
				if [ $d -gt $epi_no_zero ]; then
					#echo "Over Number: $EPISODE_TO"
					break
				fi

				EPISODE_Cur=$(padLeadingZeros 3 $(stripLeadingZeros "$d")) # Audio is 3 0s long. Fix this after episode 999.
				EPISODE_NAME_AUDIO_SHOWNOTES="${EPISODE_NAME_AUDIO_SHOWNOTES_URL}/sn-${EPISODE_Cur}-notes.pdf"

				if ! $quite_mode ; then
					echo -e "${homeclr}Downloading:\tepisode show notes ${EPISODE_Cur}..."
				fi

				tpid=`wget $skip_wget_digital_check $new_download_home -U "$wget_agent_name" -N -c -qb "$EPISODE_NAME_AUDIO_SHOWNOTES"`
				ttpid=(`echo $tpid | cut -d " " -f 5 | cut -d "." -f 1`)
				pid[$d]=$ttpid

				#echo "PID: ${pid[$d]}"
			done
		fi
		if $download_video_hd ; then
			for (( d=$c; d<$(($c+$slot_downloads)); d++ )); do

				# If the difference is less, then we can't download more.
				epi_no_zero="$(echo $EPISODE_TO | sed 's/0*//')"
				#echo "D: $d"
				#echo "epi: $epi_no_zero"
				if [ $d -gt $epi_no_zero ]; then
					#echo "Over Number: $EPISODE_TO"
					break
				fi

				EPISODE_Cur=$(padLeadingZeros 4 $(stripLeadingZeros "$d")) # Video is 4 0s long
				EPISODE_NAME_VIDEO_HD="${EPISODE_NAME_VIDEO_HD_URL}/sn${EPISODE_Cur}/sn${EPISODE_Cur}_h264m_1280x720_1872.mp4"
				EPISODE_NAME_VIDEO_HD_b="${EPISODE_NAME_VIDEO_HD_URL}/sn${EPISODE_Cur}/sn${EPISODE_Cur}_h264b_1280x720_1872.mp4"
				#echo $EPISODE_NAME_VIDEO_HQ

				check_url "$EPISODE_NAME_VIDEO_HD"
				if [ $? -ne 0 ]; then
					check_url "$EPISODE_NAME_VIDEO_HD_b"
					EPISODE_NAME_VIDEO_HD="$EPISODE_NAME_VIDEO_HD_b"
				fi
				if [ $? -eq 0 ]; then
					if ! $quite_mode ; then
						echo -e "${homeclr}Downloading:\tHD video episode ${EPISODE_Cur}..."
					fi

					tpid=`wget $skip_wget_digital_check $new_download_home -U "$wget_agent_name" -N -c -qb "$EPISODE_NAME_VIDEO_HD"`
					ttpid=(`echo $tpid | cut -d " " -f 5 | cut -d "." -f 1`)
					pid[$d]=$ttpid
				else
					if ! $quite_mode ; then
						echo "HD video episode ${EPISODE_Cur} not found..."
					fi
				fi

				#echo "PID: ${pid[$d]}"
			done
		fi
		if $download_video_hq ; then
			for (( d=$c; d<$(($c+$slot_downloads)); d++ )); do

				# If the difference is less, then we can't download more.
				epi_no_zero="$(echo $EPISODE_TO | sed 's/0*//')"
				#echo "D: $d"
				#echo "epi: $epi_no_zero"
				if [ $d -gt $epi_no_zero ]; then
					#echo "Over Number: $EPISODE_TO"
					break
				fi

				EPISODE_Cur=$(padLeadingZeros 4 $(stripLeadingZeros "$d")) # Video is 4 0s long
				EPISODE_NAME_VIDEO_HQ="${EPISODE_NAME_VIDEO_HQ_URL}/sn${EPISODE_Cur}/sn${EPISODE_Cur}_h264m_864x480_500.mp4"
				EPISODE_NAME_VIDEO_HQ_b="${EPISODE_NAME_VIDEO_HQ_URL}/sn${EPISODE_Cur}/sn${EPISODE_Cur}_h264b_864x480_500.mp4"
				#echo $EPISODE_NAME_VIDEO_HQ

				check_url "$EPISODE_NAME_VIDEO_HQ"
				if [ $? -ne 0 ]; then
					check_url "$EPISODE_NAME_VIDEO_HQ_b"
					EPISODE_NAME_VIDEO_HQ="$EPISODE_NAME_VIDEO_HQ_b"
				fi
				if [ $? -eq 0 ]; then
					if ! $quite_mode ; then
						echo -e "${homeclr}Downloading:\tHQ video episode ${EPISODE_Cur}..."
					fi

					tpid=`wget $skip_wget_digital_check $new_download_home -U "$wget_agent_name" -N -c -qb "$EPISODE_NAME_VIDEO_HQ"`
					ttpid=(`echo $tpid | cut -d " " -f 5 | cut -d "." -f 1`)
					pid[$d]=$ttpid
				else
					if ! $quite_mode ; then
						echo "HQ video episode ${EPISODE_Cur} not found..."
					fi
				fi

				#echo "PID: ${pid[$d]}"
			done
		fi
		if $download_video_lq; then
			for (( d=$c; d<$(($c+$slot_downloads)); d++ )); do

				# If the difference is less, then we can't download more.
				epi_no_zero="$(echo $EPISODE_TO | sed 's/0*//')"
				#echo "D: $d"
				#echo "epi: $epi_no_zero"
				if [ $d -gt $epi_no_zero ]; then
					#echo "Over Number: $EPISODE_TO"
					break
				fi

				EPISODE_Cur=$(padLeadingZeros 4 $(stripLeadingZeros "$d")) # Video is 4 0s long
				EPISODE_NAME_VIDEO_LQ="${EPISODE_NAME_VIDEO_LQ_URL}/sn${EPISODE_Cur}/sn${EPISODE_Cur}_h264b_640x368_256.mp4"
				EPISODE_NAME_VIDEO_LQ_m="${EPISODE_NAME_VIDEO_LQ_URL}/sn${EPISODE_Cur}/sn${EPISODE_Cur}_h264m_640x368_256.mp4"
				#echo $EPISODE_NAME_VIDEO_LQ

				check_url "$EPISODE_NAME_VIDEO_LQ"
				if [ $? -ne 0 ]; then
					check_url "$EPISODE_NAME_VIDEO_LQ_m"
					EPISODE_NAME_VIDEO_LQ="$EPISODE_NAME_VIDEO_LQ_m"
				fi
				if [ $? -eq 0 ]; then
					if ! $quite_mode ; then
						echo -e "${homeclr}Downloading:\tLQ video episode ${EPISODE_Cur}..."
					fi

					tpid=`wget $skip_wget_digital_check $new_download_home -U "$wget_agent_name" -N -c -qb "$EPISODE_NAME_VIDEO_LQ"`
					ttpid=(`echo $tpid | cut -d " " -f 5 | cut -d "." -f 1`)
					pid[$d]=$ttpid
				else
					if ! $quite_mode ; then
						echo "LQ video episode ${EPISODE_Cur} not found..."
					fi
				fi

				#echo "PID: ${pid[$d]}"
			done
		fi


		# Loop with a sleep inside until a wget download is done.
		# Then Loop around c again to do another wget download..
		# We should be maintaining a -pd amount of downloads.
		if [ ${#pid[@]} -gt 0 ] ; then # If we are downloading and nothing is reachable, this array is blank. So skip and break.
			pid2=("${pid[@]}") # Copy the array so the unset operation does not mess with the for loop ordering.
			while true; do

				# Check all wget download PIDs to see if they are still going.
				for m in "${!pid[@]}";do
					if ! $(ps -p ${pid[$m]} >/dev/null 2>&1); then
						#echo "UnSetting PID: ${pid[$m]}"
						unset pid[$m] # Remove the old process from the array
					fi
				done

				#If the above loop has noticed finished downloads, then break from this one so we can download more.
				if [ ${#pid2[@]} -ne ${#pid[@]} ]; then
					break # from this sleep loop so another download -pd batch can startup. Danger here is the tiny time in between can allow another download to finish and it may not be accounted for. Can we pause a PID ? kill -STOP pid; kill -CONT pid
				fi

				# If nothing has finished downloading, loop again for continuous checking.
				sleep 5 # Check every few seconds to see if a download finished.
			done
		fi

		# Compare the difference between the array going in and coming out. This will show the empty slots that can be filled for downloads.
		# Then change the download slots to match.
		slot_downloads=$((${#pid2[@]}-${#pid[@]}))
		c=$d
		#echo "Slot download: $slot_downloads"

	done

	if ! $quite_mode ; then
		echo " "
		echo "Done downloading."
		
		# Debug
		#echo "-> $formatted_file_name"
	fi



}

function spinner() {
    local pid=$1
    local delay=0.4
    local spinstr='|/-\'
    
    while [ $(ps a | grep $pid | grep -v grep | wc -l) != 0 ]; do
        local temp=${spinstr#?}
        printf "$2 [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        
        sleep $delay
        printf "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b"
    done
    printf "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b"
}

spinner_step_tempspin=""
spinner_step_spinstr='|/-\'
function spinner_step() {
    local delay=0.5
    
	spinner_step_tempspin=${spinner_step_spinstr#?}
    printf "$1 [%c]  " "$spinner_step_spinstr"
	spinner_step_spinstr=$spinner_step_tempspin${spinner_step_spinstr%"$spinner_step_tempspin"}
	
    sleep $delay
    printf "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b"

}

#Simply wait on a process to finish based on its pid
function wait_on_pid() {
	while [ $(ps $1 | grep $1 | wc -l) ]; do
        sleep .5
    done

}

# Fill up the cache files from last downloaded +1 to latest.
function fill_cache() {
	
	# A marker to know either the program is still working in the background, filling the cache, OR it crashed.
	touch "$script_directory_path/$download_temp_txt_search_dir/._fill_cache_working_"
	
	# Find the last epi number that was downloaded
	last_local_cache_epi=$(do_find_last_local_episode_cache)
	echo "Cache: $last_local_cache_epi | Latest: $latest_episode"
	let "last_local_cache_epi += 1" # Next one to download	
	
	if [ $last_local_cache_epi -lt $latest_episode ]; then
		
		# Run another instance of this script in the background so we can run a foreground spinner to indicate it's "working".
		#echo "script_location_and_name: $script_location_and_name"
		#exit
		$script_location_and_name -ep $last_local_cache_epi:latest -eptxt -q -s_override -pd $par_downloads_count -cache_mode -d "$script_directory_path/$download_temp_txt_search_dir" & # Put it into the background so we can use the spinner. Need to capture PID and kill it if we kill this script.
		# Capture running pid for killing if need be.
		subsearch_pid=$!
		if ! $quite_mode; then
			echo "Waiting on PID $subsearch_pid: $(ps $subsearch_pid | grep -i GRC | cut -d ":" -f 2- | cut -d " " -f 3-)"
		fi
		
		if ! $quite_mode; then # Needed to allow me to download all the cache file without searching within them. Used in the RSS Feed creation.
			spinner $subsearch_pid "Filling Cache: " # Run the spinner to show that the script is not stuck
		else
			wait_on_pid $subsearch_pid # Simply wait without output
		fi

	fi
	
	# Remove Marker
	rm "$script_directory_path/$download_temp_txt_search_dir/._fill_cache_working_"
}

# Searching for text in episodes.
function do_searching() {

	# Download all text transcripts and search them.
	if $search_txt_download ; then

		# Download all the files to search
		#I need to insert a way to narrow down what episodes need downloaded. Instead of rechecking every time. Takes to long that way. wget is set to only download if the server side is newer ( -N ). Still takes a while.
		if ! $quite_mode ; then
			echo "Downloading files"
		fi
		
		# Fill the cache up for searching in
		fill_cache
		
		# Search all the files and put results into a temp file
		grep -w -l -s -i "$search_string" "$download_temp_txt_search_dir/*.txt" > .found

		# Copy the files with the content we searched for into the special directory so it can be reviewed later
		echo "Readying results"
		mkdir "results_of_$search_string" >/dev/null 2>&1
		cd "results_of_$search_string"
		for f in $( cat ../.found ); do
			cp -p "../$f" . >/dev/null 2>&1
		done
		cd ..

		# Display the first result just for show.
		if ! $quite_mode ; then
			echo " "
			echo "First Result:"
			first_file=$(ls "results_of_$search_string" | cut -f 1 -d " " | head -n 1)
			grep --color=auto -w -n -i "$search_string" "results_of_$search_string/$first_file"

			# Inform user where to find the results.
			echo " "
			echo "Your search results are in $(pwd)/results_of_$search_string"
			echo "Remove the directory when your are finished."
			echo " "
		fi

	fi

	# Search existing text transcripts
	if $search_txt_local ; then

		grep -w -l -s -i "$search_string" "$download_temp_txt_search_dir/*.txt" > .found

		# Copy the files with the content we searched for into the special directory so it can be reviewed later
		echo "Readying results"
		mkdir "results_of_$search_string" >/dev/null 2>&1
		cd "results_of_$search_string"
		for f in $( cat ../.found ); do
			cp -p "../$f" . >/dev/null 2>&1
		done
		cd ..

		if ! $quite_mode ; then
			# Display the first result just for show.
			echo "First Result:"
			first_file=$(ls "results_of_$search_string" | cut -f 1 -d " " | head -n 1)
			grep --color=auto -w -n -i "$search_string" "results_of_$search_string/$first_file"


			# Inform user where to find the results.
			echo " "
			echo "Your search results are in $(pwd)/results_of_$search_string"
			echo "Remove the directory when your are finished."
			echo " "
		fi

	fi
}

# html_encode STRING -- encode STRING for HTML presentation
# html_encode        -- encode STDIN  for HTML presentation
#
# converts '&' => &amp;  '>' => &gt;  '<' => &lt;
function html_encode() {

  ( [[ $# -gt 0 ]] && echo -n "$*" || cat ) | sed -e "s/\&/\&amp;/g ; s/[<]/\&lt;/g  ; s/[>]/\&gt;/g"

}

# Remove leading and trailing whitespaces
function trim_str() {

	#echo "$1" | sed -e "s/[[:space:]]\+/ /g"
	echo "$1" | sed 's/^[ \t]*//;s/[ \t]*$//'

}

# Replace every substring with a provided string, within a whole string.
function replace_str() {
# $1 = whole string
# $2 = find string
# $3 = replacement string
	declare wholestr
	wholestr="$1"

	#   ${parameter/pattern/string}
	#firstString="I love Suzi and Marry"
	#secondString="Sara"
	#echo "${firstString/Suzi/$secondString}"    # prints 'I love Sara and Marry'
	echo "${wholestr//$2/$3}" # First slash is a single for a single replacement in the whole string. A double slash replaces every intance.

}

# Next two are helping me alter the filenames.
# First remove any leading zeros. 
# Then add whatever amount I want.
stripLeadingZeros() {
	#  $1 is the variable to strip

	local passed_number

	passed_number=$( [[ "$1" =~ ^0*(.*)$ ]] && echo "${BASH_REMATCH[1]}")

	echo "$passed_number"

}

padLeadingZeros() {
	#  $1 = How many
	#  $2 is the variable to pad

	local return_var

	return_var=$( printf "%0$1d" $2 )

	echo "$return_var"
}

# Convert URL from a GRC to CDN
#Please send url before converting to HTML Entities.
function convert_grc_url_to_cdn() { # $1 = URL $2 = TYPE -> ahq,vhd,vhq,vlq,txt
#echo "$1 $2"

	# Need to know if this is a MP3(HQ Audio) or Video URL
		# Convert from http://media.GRC.com/sn/SN-457.mp3
		# to {Get from twit Feeds}

	# take number off the end of the url
	passed_number=$(echo "$1" | cut -d "/" -f 5 | cut -d "-" -f2 | cut -d "." -f 1)
	# Format a plain number without leading zeros.
	passed_number_whole=$(stripLeadingZeros "$passed_number")

	# Format it for 4 digits
	EPISODE_Cur=$(padLeadingZeros 4 "$passed_number_whole")
	#echo "$EPISODE_Cur"

	# Format it for 3 digits
	EPISODE_text_Cur=$(padLeadingZeros 3 "$passed_number_whole")
	#echo "$EPISODE_text_Cur"

	# Complete the URL
	case "$2" in
		ahq)
			EPISODE_NAME_AUDIO_HQ="${EPISODE_NAME_AUDIO_HQ_URL}/sn${EPISODE_Cur}/sn${EPISODE_Cur}.mp3"
			echo "$EPISODE_NAME_AUDIO_HQ"
			;;
		vhd)
			EPISODE_NAME_VIDEO_HD="${EPISODE_NAME_VIDEO_HD_URL}/sn${EPISODE_Cur}/sn${EPISODE_Cur}_h264m_1280x720_1872.mp4"
			echo "$EPISODE_NAME_VIDEO_HD"
			;;
		vhq)
			EPISODE_NAME_VIDEO_HQ="${EPISODE_NAME_VIDEO_HQ_URL}/sn${EPISODE_Cur}/sn${EPISODE_Cur}_h264m_864x480_500.mp4"
			echo "$EPISODE_NAME_VIDEO_HQ"
			;;
		vlq)
			EPISODE_NAME_VIDEO_LQ="${EPISODE_NAME_VIDEO_LQ_URL}/sn${EPISODE_Cur}/sn${EPISODE_Cur}_h264b_640x368_256.mp4"
			echo "$EPISODE_NAME_VIDEO_LQ"
			;;
		txt)
			EPISODE_NAME_AUDIO_TEXT="${EPISODE_NAME_AUDIO_TEXT_URL}/sn-${EPISODE_text_Cur}.txt"
			echo "$EPISODE_NAME_AUDIO_TEXT"
			;;
	esac

}

# Create a RSS Feed file for websites and RSS News Readers
function rss_header() {
	### RSS HEADER
		echo "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>
	<rss version=\"2.0\">
	<channel>
		<title>$CHANNELFEEDTITLE</title>
		<pubDate>$(date)</pubDate>
		<ttl>10080</ttl>
		<webMaster>$Dev_Coder_email</webMaster>
		<link>$CHANNELFEEDLINK</link>
		<description>$CHANNELFEEDDESC</description>
		<image>
			<url>$CHANNELIMAGE</url>
			<title>$CHANNELFEEDTITLE</title>
			<link>$CHANNELFEEDCREATIONLINK</link>
		</image>
	"
}

function rss_body() { # Pass args of 1=Title of Episode, 2=LINK to CDN or GRC, 3=Security Now Text, 4=Publication Date in SN Text, 5=Category. Eg: GRC/Audio or GRC/Video or GRC/Text
#RSS BODY

# Link tag should be CDN URL when ever we can, GRC if not. So far, I think only the Low Quality audio needs to be a GRC link.
	echo "
	<item>
		<title>$1</title>
		<link>$2</link>
		<description>
		$3
		</description>
		<pubDate>$4</pubDate>
		<category>$5</category>
	</item>

"

}

function rss_footer() {
### RSS FOOTER
	echo "</channel></rss>"
}

# Helper function to grab show title
function grab_item_title() {
	#echo "TITLE"
		gtemp=$(grep --text -i "title:" $1 | cut -d ":" -f 2 || false)

		# Strip carriage returns
		gtemp=$(strip_text_cr "$gtemp")
		# Convert some chars to HTML entitys for XML in the file.
		gtemp=$(html_encode "$gtemp")
		# Trim white spaces
		gtemp=$(trim_str "$gtemp")

		echo "$gtemp"
}

# Helper function to grab show link
function grab_item_link() {

		# Grab the URL
		# URL format changed at some point. Newer files have "SOURCE:".
		gtemp=$(grep --text "SOURCE FILE:" $1 | cut -d ":" -f 2-3)

		if [[ "$gtemp" == "" ]]; then
			#echo "2-2"
			gtemp=$(grep --text "SOURCE:" $1 | cut -d ":" -f 2-3)
			#echo "$gtemp"
			#exit
		fi
		
		# Strip carriage returns
		gtemp=$(strip_text_cr "$gtemp")
		#echo "$gtemp"

		# Convert to CDN URL
		#echo "2-4"
		gtemp=$(convert_grc_url_to_cdn "$gtemp" "$2")

		# Convert some chars to HTML entitys for XML in the file.
		gtemp=$(html_encode "$gtemp")

		# Trim white spaces
		#echo "2-5"
		gtemp=$(trim_str "$gtemp")

		echo "$gtemp"
}

# Helper function to grab show DESCRIPTION
function grab_item_description() {
		gtemp=$(grep --text -i "DESCRIPTION:" $1 | cut -d ":" -f 2)

		# Strip carriage returns
		gtemp=$(strip_text_cr "$gtemp")
		# Convert some chars to HTML entitys for XML in the file.
		gtemp=$(html_encode "$gtemp")
		# Trim white spaces
		gtemp=$(trim_str "$gtemp")

		echo "$gtemp"
}

# Helper function to grab show publication date
function grab_item_pubdate() {
		gtemp=$(grep --text -i "date:" $1 | cut -d ":" -f 2 || false)

		# Strip carriage returns
		gtemp=$(strip_text_cr "$gtemp")
		# Trim white spaces
		gtemp=$(trim_str "$gtemp")

		echo "$gtemp"
}

# Compile all the pieces together here for creating a RSS Feed file.
function do_rss_feed() {

	# We need to strip CR code from windows formated text files.
	# Checking for TR and sed command, exit if we can not find it. Redo code for alternatives later?
	check_program_exists_arr[0]="tr"
	check_program_exists_arr[1]="sed"
	check_program_exists_multi check_program_exists_arr[@]

	# Exist?
	if [[ ${check_program_exists_arr[${#check_program_exists_arr[*]}-1]} == "" ]] ; then
		# Does not exist, exit script
		echo " "
		echo "RSS Feed script canceled: needs the tr and sed commands to strip CR's from windows formated text files and do some conversions for XML.."
		echo " "
		exit
	fi

	# We need to first download ALL the Security Now text files to find all the show TITLES,DATES,DESCRIPTIONS,CONTENT,etc
	# From the files, we can create a RSS Feed file.
	# Remember to swap out the GRC url'ss for CDN's. If this provider changes, comment out the function and it will work with GRCs URL's(if hosted there), Steve Gibson told me to not use them !!.

	# This will setup all the text data we need to parse into a RSS feed file.
	#echo "Filling Cache"
	#fill_cache	# Get the cache downloaded!

	# Create the header
	rss_header_txt=$(rss_header)
	write_to_rss_file "$rss_header_txt" true
	
	# Create the ITEMs in the Feed.
	# Loop from 001 to -latest show number
	#for show_num in $(eval echo "$download_temp_txt_search_dir/sn-{001..$latest_episode}.txt"); # This was starting at number 9 of the 1-### episodes. Weird.
	EPISODE_padded=$(padLeadingZeros 3 "$EPISODE")
	EPISODE_TO_padded=$(padLeadingZeros 3 "$EPISODE_TO")
	for show_num in $(eval echo "$download_temp_txt_search_dir/sn-{$EPISODE_padded..$EPISODE_TO_padded}.txt"); # Loops around the selected or defaulted episode numbers
	do
		#echo "Numbers: $show_num";
		
		if [ -f $show_num ]; then
		
			# Show that we are processing the data
			spinner_step "Crunching Epi: $show_num "
		
			# Show Epi number that is being worked on
			#echo "Epi: $show_num"
			#printf "\r%-${COLUMNS}s" "Epi: $show_num"
			#echo -ne "\033[2K Epi: $show_num"

			# Which items are we getting ? Audio, Video, Text, All ?
			# Audio HQ
			if $create_rss_audio || $create_rss_feeds; then

				# Pull Audio information
				rss_item_title="HQ Audio: "$(grab_item_title "$show_num")
				# Swap link for CDN
				rss_item_link=$(grab_item_link "$show_num" "ahq")

				rss_item_description=$(grab_item_description "$show_num")
				rss_item_date=$(grab_item_pubdate "$show_num")
				rss_item_category="GRC/Audio"

				# Loop around this one to create the needed RSS items.
				rss_body_txt=$(rss_body "$rss_item_title" "$rss_item_link" "$rss_item_description" "$rss_item_date" "$rss_item_category")
				# Append write to file
				write_to_rss_file "$rss_body_txt"
			fi
			# Video HD
			if $create_rss_video || $create_rss_feeds; then

				# Pull HD Video information
				rss_item_title="HD Video: "$(grab_item_title "$show_num")
				# Swap link for CDN
				rss_item_link=$(grab_item_link "$show_num" "vhd")
				rss_item_description=$(grab_item_description "$show_num")
				rss_item_date=$(grab_item_pubdate "$show_num")
				rss_item_category="GRC/Video"

				# Loop around this one to create the needed RSS items.
				rss_body_txt=$(rss_body "$rss_item_title" "$rss_item_link" "$rss_item_description" "$rss_item_date" "$rss_item_category")
				# Append write to file
				write_to_rss_file "$rss_body_txt"

			# Video HQ
				# Pull HD Video information
				rss_item_title="HQ Video: "$(grab_item_title "$show_num")
				# Swap link for CDN
				rss_item_link=$(grab_item_link "$show_num" "vhq")
				rss_item_description=$(grab_item_description "$show_num")
				rss_item_date=$(grab_item_pubdate "$show_num")
				rss_item_category="GRC/Video"

				# Loop around this one to create the needed RSS items.
				rss_body_txt=$(rss_body "$rss_item_title" "$rss_item_link" "$rss_item_description" "$rss_item_date" "$rss_item_category")
				# Append write to file
				write_to_rss_file "$rss_body_txt"

			# Video LQ
				# Pull HD Video information
				rss_item_title="LQ Video: "$(grab_item_title "$show_num")
				# Swap link for CDN
				rss_item_link=$(grab_item_link "$show_num" "vlq")
				rss_item_description=$(grab_item_description "$show_num")
				rss_item_date=$(grab_item_pubdate "$show_num")
				rss_item_category="GRC/Video"

				# Loop around this one to create the needed RSS items.
				rss_body_txt=$(rss_body "$rss_item_title" "$rss_item_link" "$rss_item_description" "$rss_item_date" "$rss_item_category")
				# Append write to file
				write_to_rss_file "$rss_body_txt"
			fi
			# Text -> Transcriptions and ?Show Notes?(PDF to TEXT convertor needed. In future ?)
			if $create_rss_text || $create_rss_feeds; then

				# Pull Text information
				rss_item_title="Transcription: "$(grab_item_title "$show_num")
				rss_item_link=$(grab_item_link "$show_num" "txt")
				#echo "1] $rss_item_title"
				#echo "2] $rss_item_link"
					
					# Grab all the text or just to the limit rss_feed_text_limit
					if [ "$rss_feed_text_limit" != "" ]; then
						rss_item_description=$(head -n $rss_feed_text_limit "$show_num")
					else
						rss_item_description=$(cat "$show_num")
					fi
					# Strip carriage returns
					rss_item_description=$(strip_text_cr "$rss_item_description")
					# Convert some chars to HTML entitys for XML in the file.
					rss_item_description=$(html_encode "$rss_item_description")
					# Trim white spaces
					#rss_item_description="<![CDATA["$(trim_str "$rss_item_description")"]]>"
					rss_item_description=$(trim_str "$rss_item_description")
					# Change New Lines into <br/>
					rss_item_description=$(echo "$rss_item_description" | sed 's=$=<br/>=')
					
				rss_item_date=$(grab_item_pubdate "$show_num")
				rss_item_category="GRC/Text"

				## Maybe append to the file instead of using of the memory.
				# Loop around this one to create the needed RSS items.
				#echo "Adding to body"
				rss_body_txt=$(rss_body "$rss_item_title" "$rss_item_link" "$rss_item_description" "$rss_item_date" "$rss_item_category")
				# Append write to file
				write_to_rss_file "$rss_body_txt"
			fi

		#else
		#	echo "Skipping Show: $show_num"
		fi
	done
	#echo "End Loop"
	# End Loop

	# Create the footer
	rss_footer_txt="$(rss_footer)"
	# Append write to file
	write_to_rss_file "$rss_footer_txt"

	# Combine it all and echo it out for capture
	#rss_feed_txt="$rss_header_txt \n $rss_body_txt \n $rss_footer_txt"

}

function write_to_rss_file() {
#  $1 is the data to write.
#  $2 optional argument - clear file before write

	if [ "$rss_filename" == "" ]; then
		rss_filename="security_now.rss"
	fi

	# Clear the file if told so by $2
	# Echo the entire RSS Feed text into a file
	if [ "$2" != "" ]; then
		#echo "Clearing"
		echo "" > "$rss_filename"
	fi

	echo -e "$1" >> "$rss_filename"

}

# This will contruct the Filename Format as required by the argument -ff.
# Used just before downloading the file so we have all the variables ready.
function construct_the_filename_format() {

	# Replace <tags> tags within $format_arguments, with variable data.
		# <showname> <episodenumber> <episodename> <episodeyear> <date> <type> <raw>(same as the downloaded filename)
	# Use function replace_str()
		# $1 = whole string
		# $2 = find string
		# $3 = replacement string
	format_arguments_str=$(replace_str "$format_arguments" "<showname>" "GRC's Security Now")
	format_arguments_str=$(replace_str "$format_arguments_str" "<episodenumber>" "$EPISODE_Cur")
	
	# Cut out the Episode Name
	EPISODE_Name_replace=$(grab_item_title "$download_temp_txt_search_dir/sn-$EPISODE_Cur.txt")
	format_arguments_str=$(replace_str "$format_arguments_str" "<episodename>" "$EPISODE_Name_replace")
	EPISODE_Year_replace=$(grab_item_pubdate "$download_temp_txt_search_dir/sn-$EPISODE_Cur.txt")
	
	# Cut out the Year
	EPISODE_Year_replace=$(echo "$EPISODE_Year_replace" | cut -d "," -f 2)
	EPISODE_Year_replace=$(trim_str "$EPISODE_Year_replace")
	format_arguments_str=$(replace_str "$format_arguments_str" "<episodeyear>" "$EPISODE_Year_replace")

	format_arguments_str=$(replace_str "$format_arguments_str" "<date>" "$EPISODE_Cur")
	format_arguments_str=$(replace_str "$format_arguments_str" "<type>" "$EPISODE_Cur")
	format_arguments_str=$(replace_str "$format_arguments_str" "<raw>" "$EPISODE_Cur")
	format_arguments_str=$(trim_str "$format_arguments_str")
	#format_arguments_str=$(replace_str "$format_arguments_str" " " "\ ")

	formatted_file_name="$new_download_home_dir$format_arguments_str"
}

# Lets Start
#clear

# Check arguments
if [ $# -eq 0 ]; then
	output_help
fi

arg_index=1
until [ -z "$1" ]; do
	#echo "$1"

	# No sense downloading the latest epi file if just displaying help -h
	if [ "$1" == "-h" ]; then
		output_help
	fi

	if [ "$1" == "-u" ]; then
		do_gh_update=true
		break
	fi
	if [ "$1" == "-ep" ]; then
		download_episode_number=true

		shift
		EPISODE_tmp="$1"
		EPISODE=`echo $EPISODE_tmp | cut -d ":" -f 1`
		EPISODE_TO=`echo $EPISODE_tmp | cut -d ":" -f 2`

		#echo "MIN: $EPISODE"
		#echo "MAX: $EPISODE_TO"
	fi
	if [ "$1" == "-ahq" ]; then
		if chk_disk_space $DISK_SPACE_MIN_FOR_ONE_AUDIO; then
			download_audio_hq=true
		else
			echo "Not enough storage space for downloading."
			download_audio_hq=false
			exit 3
		fi
	fi
	if [ "$1" == "-alq" ]; then
		if chk_disk_space $DISK_SPACE_MIN_FOR_ONE_AUDIO; then
			download_audio_lq=true
		else
			echo "Not enough storage space for downloading."
			download_audio_lq=false
			exit 4
		fi
	fi
	if [ "$1" == "-eptxt" ]; then
		if chk_disk_space $DISK_SPACE_MIN_FOR_ONE_TEXT; then # Hard coded for small text or html files.
			download_episode_text=true
		else
			echo "Not enough storage space for downloading."
			download_episode_text=false
			exit 5
		fi
	fi
	if [ "$1" == "-eppdf" ]; then
		if chk_disk_space $DISK_SPACE_MIN_FOR_ONE_PDF; then # Hard coded for small text or html files.
			download_episode_pdf=true
		else
			echo "Not enough storage space for downloading."
			download_episode_pdf=false
			exit 5
		fi
	fi
	if [ "$1" == "-ephtml" ]; then
		if chk_disk_space $DISK_SPACE_MIN_FOR_ONE_HTML; then # Hard coded for small text or html files.
			download_episode_html=true
		else
			echo "Not enough storage space for downloading."
			download_episode_html=false
			exit 5
		fi
	fi
	if [ "$1" == "-epnotes" ]; then
		if chk_disk_space $DISK_SPACE_MIN_FOR_ONE_TEXT; then # Hard coded for small text or html files.
			download_episode_shownote=true
		else
			echo "Not enough storage space for downloading."
			download_episode_shownote=false
			exit 5
		fi
	fi

	if [ "$1" == "-vhd" ]; then
		if chk_disk_space $DISK_SPACE_MIN_FOR_ONE_HD_VIDEO; then
			download_video_hd=true
		else
			echo "VHD Minimum: $DISK_SPACE_MIN_FOR_ONE_HD_VIDEO; Not enough storage space for downloading."
			download_video_hd=false
			exit 55
		fi
	fi
	if [ "$1" == "-vhq" ]; then
		if chk_disk_space $DISK_SPACE_MIN_FOR_ONE_VIDEO; then
			download_video_hq=true
		else
			echo "VHQ Minimum: $DISK_SPACE_MIN_FOR_ONE_VIDEO; Not enough storage space for downloading."
			download_video_hq=false
			exit 6
		fi
	fi
	if [ "$1" == "-vlq" ]; then
		if chk_disk_space $DISK_SPACE_MIN_FOR_ONE_VIDEO; then
			download_video_lq=true
		else
			echo "Not enough storage space for downloading."
			download_video_lq=false
			exit 7
		fi
	fi
	if [ "$1" == "-latest" ]; then

		#echo "ahq: $download_audio_hq, alq: $download_audio_lq, vhd: $download_video_hd, vhq: $download_video_hq, vlq: $download_video_lq"

		if [[ $download_audio_hq || $download_audio_lq ]]; then
			chk_disk_space $DISK_SPACE_MIN_FOR_ONE_AUDIO
			chk_temp=$?
		fi
		if [[ $download_video_hq || $download_video_lq ]]; then
			chk_disk_space $DISK_SPACE_MIN_FOR_ONE_VIDEO
			chk_temp=$?
		fi
		if [[ $download_video_hd ]]; then
			chk_disk_space $DISK_SPACE_MIN_FOR_ONE_HD_VIDEO
			chk_temp=$?
		fi

		if [[ $chk_temp ]]; then
			download_latest=true
		else
			#echo "Download_Latest set to FALSE"
			download_latest=false
		fi
	fi
	if [ "$1" == "-all" ]; then

		if $download_video_hq || $download_video_lq ; then
			if $download_video_hq && (chk_disk_space $DISK_SPACE_MIN_FOR_ALL_VIDEO) ; then
				download_all=true
			elif $download_video_lq && (chk_disk_space $DISK_SPACE_MIN_FOR_ALL_VIDEO) ; then
				download_all=true
			else
				echo "Not enough storage space for downloading."
				echo "MIN FOR ALL VIDEO: $DISK_SPACE_MIN_FOR_ALL_VIDEO"
				download_all=false
				exit 8
			fi
		fi

		chk_disk_space $DISK_SPACE_MIN_FOR_ALL_VIDEO
		chk_temp=$?
		if [ $download_audio_hq ] || [ $download_audio_lq ]; then
			if [ $download_audio_hq ] && [ $chk_temp ]; then
				download_all=true
			elif [ $download_audio_lq ] && [ $chk_temp ]; then
				download_all=true
			else
				echo "Not enough storage space for downloading."
				echo "MIN FOR ALL AUDIO: $DISK_SPACE_MIN_FOR_ALL_AUDIO"
				download_all=false
				exit 9
			fi
		fi

		chk_disk_space $DISK_SPACE_MIN_FOR_ALL_PDF # Doing the PDF since it is normally the largest.
		chk_temp=$?
		if [ $download_episode_text ] || [ $download_episode_pdf ] || [ $download_episode_html ]; then
			if [ $download_episode_text ] && [ $chk_temp ]; then
				download_all=true
			elif [ $download_episode_pdf ] && [ $chk_temp ]; then
				download_all=true
			elif [ $download_episode_html ] && [ $chk_temp ]; then
				download_all=true
			else
				echo "Not enough storage space for downloading."
				echo "MIN FOR ALL TEXT $DISK_SPACE_MIN_FOR_ALL_PDF"
				download_all=false
				exit 10
			fi
		fi

	fi

	if [ "$1" == "-d" ]; then
		shift

		# Make sure there is a slash on the end of the string
		case "$1" in
		*/)
			new_download_home_dir="$1" # Has a slash on the end already.
			;;
		*)
			new_download_home_dir="$1/" # Does not have a slash. Adds one.
			;;
		esac
		
		new_download_home="-P $new_download_home_dir"
		
	fi
	if [ "$1" == "-ff" ]; then
		shift
		do_file_format=true
		
		# Grab the argument after the -ff.
		format_arguments="$1"

		# Rest handled in function construct_the_filename_format()
		# called just before the downloading of a file.
	fi

	if [ "$1" == "-p" ]; then
		pretend_mode=true
	fi
	if [ "$1" == "-pd" ]; then
		par_downloads=true

		shift
		par_downloads_count="$1"
	fi
	if [ "$1" == "-q" ]; then
		quite_mode=true
	fi

	if [ "$1" == "-skip-digital-cert-check" ]; then
		echo " "
		echo "==> --no-check-certificate ENABLED"
		echo " "
		skip_wget_digital_check=" --no-check-certificate "
	fi

	# This will only be used on recursive use when doing a text search
	# Allows some echo output even when all other output is -q
	if [ "$1" == "-s_override" ]; then
		search_echo_override_mode=true
	fi

	# When we are filling the Cache, like on first run, we need to know if the script is doing the cache or it is a normal run.
	# We are doing a subshell to fill the cache by calling the script again with some arguments.
	# If cache_mode is true, skip filling the cache function because we are already doing that.
	if [ "$1" == "-cache_mode" ]; then
		cache_mode=true
	fi

	if [ "$1" == "-dandstxt" ]; then
		search_txt_download=true

		shift
		search_string="$1"
		#echo "Set Search"

	fi
	if [ "$1" == "-stxt" ]; then
		search_txt_local=true

		shift
		search_string="$1"

	fi

	if [ "$1" == "-create-rss-audio" ]; then
		create_rss_audio=true
		create_rss_mode=true
	fi
	if [ "$1" == "-create-rss-video" ]; then
		create_rss_video=true
		create_rss_mode=true
	fi
	if [ "$1" == "-create-rss-text" ]; then
		create_rss_text=true
		create_rss_mode=true
	fi
	if [ "$1" == "-create-rss-feeds" ]; then
		create_rss_feeds=true
		create_rss_mode=true
	fi
	if [ "$1" == "-rss-filename" ]; then
		shift
		rss_filename="$1"
	fi
	if [ "$1" == "-rss-limit" ]; then
		shift
		rss_feed_text_limit="$1"
	fi

	shift
done


# Terminal variables
if ! $quite_mode; then # This was needed since in Crontab, tput could not access the $TERM variable. Keep -q on the command in crontab.
 	# This will go back UP a line, then clear the line. This is so the next echo will always be on the same line, instead of scrolling.
	homeclr=$(tput cuu1;tput el)
fi

#echo "ahq: $download_audio_hq, alq: $download_audio_lq, vhq: $download_video_hd, vhq: $download_video_hq, vlq: $download_video_lq, p: $pretend_mode, all: $download_all, latest: $download_latest, download_episode_number: $download_episode_number, Episode: start:$EPISODE to:$EPISODE_TO"

# See and set flag if we are downloading a episode
if ( $download_episode_number || $download_latest || $download_all ) && ( $download_audio_hq || $download_audio_lq || $download_video_hd || $download_video_hq || $download_video_lq || $download_episode_text || $download_episode_pdf || $download_episode_html || $download_episode_shownote ); then
	do_episode_downloading=true
else
	do_episode_downloading=false
fi

# Find the latest so we can output the result
do_find_latest_episode

# Do again?
# IF downloading all, then set the variables.
if $download_all ; then
	
	EPISODE_TO=$latest_episode
fi
# IF downloading latest, then set the variables.
if $download_latest ; then
	
	EPISODE=$latest_episode
	EPISODE_TO=$latest_episode
fi
# IF downloading from a set episode number to LATEST , -ep 250:latest
if [ "$EPISODE_TO" == "latest" ]; then
	EPISODE_TO=$latest_episode
fi

#echo "ahq: $download_audio_hq, alq: $download_audio_lq, vhq: $download_video_hq, vlq: $download_video_lq, p: $pretend_mode, all: $download_all, latest: $download_latest, download_episode_number: $download_episode_number, Episode: start:$EPISODE to:$EPISODE_TO"

#if ! $search_txt_local && ! $search_txt_download ; then
	#if ! $do_episode_downloading; then
		#add_to_headers+=("What was I to download ? Please specify any/all of:")
		#add_to_headers+=("-ep  -all  -latest")
		#add_to_headers+=("-ahq  -alq  -vhd  -vhq  -vlq  -eptxt  -eppdf  -ephtml -epnotes")
		#add_to_headers+=(" ")

	#fi
#fi

# Set episodes
if $download_episode_number ; then
	dummy_fill_var=true
	#if ! $quite_mode ; then
	#	add_to_headers+=("Episode input: ${EPISODE} to ${EPISODE_TO}")
	#fi

#elif ! $download_latest && ! $download_all && ! $download_episode_number && $do_episode_downloading ; then
elif ! $download_latest && ! $download_episode_number && $do_episode_downloading ; then

	EPISODE_found=false

	if $download_audio_lq ; then
		count=`ls -1 *.mp3 2>/dev/null | wc -l`
		if [ $count != 0 ]; then
			# Got the episode number WITH zeros
			EPISODE_capt=$(ls -1 *.mp3 | grep -io "^sn..." | grep -o "...$" | sort -n | tail -n 1)
			# Strip the Zeros
			#Needed because bash sees leading zeros as somthing else. "Numerical values starting with a zero (0) are interpreted as numbers in octal notation by the C language. As the only digits allowed in octal are {0..7}, an 8 or a 9 will cause the evaluation to fail."
			declare -i epi_no_zero="$(echo $EPISODE_capt | sed 's/-*//')"
			# Do the math to increase the count AND Bring it back to the leading 0 format so that the filename is correct.
			epi_no_zero=$epi_no_zero+1
			EPISODE=$(padLeadingZeros 3 $epi_no_zero) # lq audio does it to 3 zero format. hq audio does it in 4, without the dash too. What will it be like after episode 999 ?
			#EPISODE=$( printf "%.3d" $epi_no_zero ) # lq audio does it to 3 zero format. hq audio does it in 4, without the dash too. What will it be like after episode 999 ?

			if ! $quite_mode ; then
				add_to_headers+=("Audio episode input missing, guesstimating latest as: ${epi_no_zero}")
			fi
			EPISODE_found=true
		fi

	fi
	if $download_audio_hq ; then
		count=`ls -1 *.mp3 2>/dev/null | wc -l`
		if [ $count != 0 ]; then
			# Got the episode number WITH zeros
			EPISODE_capt=$(ls -1 *.mp3 | grep -io "^sn...." | grep -o "....$" | sort -n | tail -n 1)
			# Strip the Zeros
			#Needed because bash sees leading zeros as somthing else. "Numerical values starting with a zero (0) are interpreted as numbers in octal notation by the C language. As the only digits allowed in octal are {0..7}, an 8 or a 9 will cause the evaluation to fail."
			declare -i epi_no_zero="$(echo $EPISODE_capt | sed 's/0*//')"
			# Do the math to increase the count AND Bring it back to the leading 0 format so that the filename is correct.
			epi_no_zero=$epi_no_zero+1
			EPISODE=$(padLeadingZeros 4 $epi_no_zero) # lq audio does it to 3 zero format. hq audio does it in 4, without the dash too. What will it be like after episode 999 ?
			#EPISODE=$( printf "%.4d" $epi_no_zero ) # lq audio does it to 3 zero format. hq audio does it in 4, without the dash too. What will it be like after episode 999 ?

			if ! $quite_mode ; then
				add_to_headers+=("Audio episode input missing, guesstimating latest as: ${epi_no_zero}")
			fi
			EPISODE_found=true
		fi

	fi
	if ( $download_video_hd || $download_video_hq || $download_video_lq ); then # What is the video extension ?
		count=`ls -1 *.mp4 2>/dev/null | wc -l`
		if [ $count != 0 ]; then
			EPISODE_capt=$(ls -1 *.mp4 | tail -n 1 | grep -io "^sn...." | grep -o "....$")
			# Strip the Zeros
			#Needed because bash sees leading zeros as somthing else. "Numerical values starting with a zero (0) are interpreted as numbers in octal notation by the C language. As the only digits allowed in octal are {0..7}, an 8 or a 9 will cause the evaluation to fail."
			#declare -i epi_no_zero="$(echo $EPISODE_capt | sed 's/0*//')"
			declare -i epi_no_zero="$(stripLeadingZeros $EPISODE_capt)"

			# Do the math to increase the count AND Bring it back to the leading 0 format so that the filename is correct, using BASE#NUMBER.
			#EPISODE=$( printf "%03d\n" $(( 10#$epi_no_zero + 1 )) )
			epi_no_zero=$epi_no_zero+1
			EPISODE=$(padLeadingZeros 4 $epi_no_zero)

			if ! $quite_mode ; then
				add_to_headers+=("Video episode input missing, guesstimating latest as: ${epi_no_zero}")
			fi
			EPISODE_found=true
		fi

	fi
	if ! $EPISODE_found ; then

		add_to_headers+=( "No Episodes found to start with. Can not find the next one to download.")
		add_to_headers+=( "You in the correct directory ?")
		add_to_headers+=( " ")
		exit 1
	fi

	EPISODE_TO=$EPISODE

fi

# Slight delay in startup due to downloading of files. Show something to indicate it is working
spinner_step

# Check to see if we are updating the script. Grab the new version from GitHub and display it if newer.
check_and_update_script
# http://stackoverflow.com/questions/14222250/floating-point-arithmetic-in-unix-shell-script
if (( $(echo "$this_version < $gh_version" | bc -l) )) ; then
	add_to_headers+="Script update available, version: $gh_version"
	add_to_headers+=" "
fi

# Slight delay in startup due to downloading of files. Show something to indicate it is working
spinner_step

# Show some details if quite mode is off
if ! $quite_mode ; then
	clear
	do_headers add_to_headers[@]
fi

# We need to first download ALL the Security Now text files to find all the show TITLES,DATES,DESCRIPTIONS,CONTENT,etc
# From the files, we can create a RSS Feed file.
# Remember to swap out the GRC url'ss for CDN's. If this provider changes, comment out the function and it will work with GRCs URL's(if hosted there), Steve Gibson told me to not use them !!.

# Nearly ready to do some work

# We don't want to run this again as part of the background process to fill_cache()
if ! $cache_mode; then
	# Before doing so, uncompress the cache ONCE, instead of on each call; downloading, search, RSS feed
	# Faster this way
	# call uncompress/compress function for cache reading, but not for filling the cache..
	do_cache "uncompress"

	# This will setup all the text data we need to parse into a RSS feed file.
	# We should only do this if not in Cache Mode already! Otherwise it recurses by calling itself over and over.
	echo "Checking/Filling Cache, required for formatted filenames, RSS feeds, and Searching Episodes Texts."
	spinner_step
	fill_cache	# Get the cache downloaded!

	#echo "ahq: $download_audio_hq, alq: $download_audio_lq, vhq: $download_video_hq, vlq: $download_video_lq, p: $pretend_mode, all: $download_all, latest: $download_latest, download_episode_number: $download_episode_number"
	if ! $quite_mode && ! $search_txt_local && ! $search_txt_download && ! $create_rss_mode; then
		#echo "Downloading episodes $(echo $EPISODE | sed 's/0*//' | sed 's/-*//') to $(echo $EPISODE_TO | sed 's/0*//' | sed 's/-*//')"
		echo "Downloading episodes: $(stripLeadingZeros $EPISODE) to $(stripLeadingZeros $EPISODE_TO)"
		echo " "
	fi

	# Before working, Send Ping
	send_ping

fi # End cache_mode

# Do some episode downloading!
#if ! ($search_txt_local || $search_txt_download) ; then
if $do_episode_downloading ; then
	if ! $pretend_mode ; then

		do_downloading

	else
		if ! $quite_mode ; then
			echo "Pretend mode was enabled. Nothing Downloaded."
		fi

	fi
fi

# After all the downloads, see if we are doing some searching
if $search_txt_local || $search_txt_download ; then
	if ! $pretend_mode ; then

		echo "Starting Search..."
		do_searching

	else
		echo "Not Searching"
		if ! $quite_mode ; then
			echo "Pretend mode was enabled. Nothing Downloaded."
		fi

	fi
fi

# After all the searching, see if we are creating RSS Feeds file
if $create_rss_feeds || $create_rss_audio || $create_rss_video || $create_rss_text ; then
	if ! $pretend_mode ; then

		echo "Creating RSS Feed file..."
		
		# Run another instance of this script in the background so we can run a foreground spinner to indicate it's "working".
		#do_rss_feed & 	# Put it into the background so we can use the spinner. Need to capture PID and kill it if we kill this script.
		do_rss_feed
		
		# Capture running pid for killing if need be.
		#subsearch_pid=$! # capture of PID
		#echo "Spinner PID: $subsearch_pid"
		
		#if ! $pretend_mode ; then # Needed to allow me to download all the cache file without searching within them. Used in the RSS Feed creation.
		#	spinner $subsearch_pid # Run the spinner to show that the script is not stuck
		#fi

	else
		echo "Not Creating RSS Feed file"
		if ! $quite_mode ; then
			echo "Pretend mode was enabled. Nothing Created."
		fi

	fi
fi


# call uncompress/compress function for cache.
# This is too save space and preserve the text from rogue changes. It will remove all .txt files after compression.
if ! $cache_mode; then
	if ! $search_echo_override_mode ; then # This is for the cache download. We don't want to compress it after downloading it. See fill_cache function
		do_cache "compress"
	fi
fi

do_script_shutdown 0

exit 0
