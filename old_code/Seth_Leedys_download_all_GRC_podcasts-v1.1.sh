#!/bin/bash

# Created: 2012-05-25
# Last Updated: 2014-01-01

#This script will have updates on the http://techblog.sethleedy.name/ website.
# URL: http://techblog.sethleedy.name/?p=24172

# Initialization.
this_version="1.1"

find_latest_episode_url="http://www.grc.com/securitynow.htm"
EPISODE_NAME_AUDIO_HQ_URL="http://media.grc.com/sn/"
EPISODE_NAME_AUDIO_LQ_URL="http://media.grc.com/sn/"
EPISODE_NAME_AUDIO_TEXT_URL="http://www.grc.com/sn/"
EPISODE_NAME_AUDIO_PDF_URL="http://www.grc.com/sn/"
EPISODE_NAME_AUDIO_HTML_URL="http://www.grc.com/sn/"
EPISODE_NAME_AUDIO_SHOWNOTES_URL="http://www.grc.com/sn/"
EPISODE_NAME_VIDEO_HQ_URL="http://twit.cachefly.net/video/sn/"
#http://dts.podtrac.com/redirect.mp4/twit.cachefly.net/video/sn/sn0435/sn0435_h264m_864x480_500.mp4
EPISODE_NAME_VIDEO_LQ_URL="http://twit.cachefly.net/video/sn/"
#http://dts.podtrac.com/redirect.mp4/twit.cachefly.net/video/sn/sn0435/sn0435_h264b_640x368_256.mp4
skip_wget_digital_check=""

# Sizes in Kilo's
DISK_SPACE=1000
DISK_SPACE_MIN_FOR_ONE_AUDIO=55000 # 55 MB - Largest I saw on the listing @ GRC.COM
DISK_SPACE_MIN_FOR_ALL_AUDIO=3200000 # 3,200 MB or 3.2 GB as Noted on the GRC Newsgroup in 2012-05. This is EST default. Made it dynamic further down.
DISK_SPACE_MIN_FOR_ONE_VIDEO=600000 # 600 MB
DISK_SPACE_MIN_FOR_ALL_VIDEO=20000000
DISK_SPACE_MIN_FOR_ONE_TEXT=35500
DISK_SPACE_MIN_FOR_ALL_TEXT=12602500
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
par_downloads=false
par_downloads_count=1
quite_mode=false
declare -a pid
declare -a add_to_headers
declare -a check_program_exists_arr
download_audio_hq=false
download_audio_lq=false
download_video_hq=false
download_video_lq=false
download_episode_text=false
download_episode_pdf=false
download_episode_html=false
download_episode_shownote=false
download_temp_txt_search_dir=".tmp_search_txt"
search_txt_local=false
search_txt_download=false
search_string=""
search_echo_override_mode=false

# Terminal variables
ceol=`tput el`


# Send a "Ping" back to my server. This allows me to know that my script is being used out in the wild.
# The request will show up in my blog and I can parse it later for stats.
# Sends out this script version.
# Sends out the date/time ran.
function send_ping() {

	datetime=`date '+%Y-%m-%d-%R'`
	wget $skip_wget_digital_check -qb -O /dev/null -U "GRCDownloader_v$this_version" "http://techblog.sethleedy.name/do_count.php?datetime=$datetime&agent_code=GRCDownloader_v$this_version" 1>/dev/null 2>&1

}

# Do script shutdown
function do_script_shutdown() {

	rm -f securitynow.htm
	rm -f wget-log*

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
			kill $r 1>/dev/null 2>&1
		done
	fi

	# Kill the subsearch shell if running
	kill $subsearch_pid 1>/dev/null 2>&1

	echo "Script killed!"

	# Call script shutdown
	do_script_shutdown 1

	# Should not reach here..
	exit 1
}

# See if the URL is valid
function check_url() {

	wget $skip_wget_digital_check -q --spider "$1"
	returncode=$?

	if [ $returncode != 0 ]; then
		wget --no-check-certificate -q --spider "$1"
		returncode=$?
		if [ $returncode == 0 ]; then
			echo " "
			echo "==> -skip-digital-cert-check automatically ENABLED"
			skip_wget_digital_check=" --no-check-certificate "
		else
			echo " "
			echo "Check_URL() Error: $returncode"
			echo "URL: $1"
			echo "You may have to turn on -skip-digital-cert-check"
			return 1
		fi
	else
		return 0
	fi

}

# Check disk space.
function chk_disk_space() { # Pass a number in whole Kilo bytes.

	DISK_SPACE=$(df -T "`pwd`" | grep -iv "Filesystem" | awk '{print $5}')
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
	echo "	It also supports a range separated by a colon. Eg: -ep 1:25"
	echo " "
	echo "	Note: If no options are used to indicate what episode to download, the script will search the local directoy for the latest episode and download the next one automatically."
	echo " "
	echo "-ahq		Download High Quality Audio format."
	echo "-alq		Download Low Quality Audio format"
	echo "-vhq		Download High Quality Video format"
	echo "-vlq		Download Low Quality Video format"
	echo "-eptxt		Download the text transcript of the episode"
	echo "-eppdf		Download the pdf transcript of the episode"
	echo "-ephtml		Download the html transcript of the episode"
	echo "-epnotes	Download the show notes of the episode(Not all available)"
	echo "-latest		Download the latest episode. It will try to check for the latest whenever the script is run."
	echo "	If this is flagged, it will put the latest episode as the file to download."
	echo " "
	echo "Search Mode:"
	echo "-dandstxt	Download and Search, will download all text episodes and search insensitively for the text you enter here."
	echo "	OR"
	echo "-stxt		Search insensitively the local directory .txt episodes for text you enter here."
	echo " "
	echo "-all		This will download all episodes from 1 to -latest"
	echo "-p		Pretend mode. It will only spit out the headers and numbers. It will not download any files"
	echo "	(except the webpage needed to find the latest episodes)"
	echo " "
	echo "-q		Quite mode. Minimal on search and nothing but errors on episode downloads will be outputted to the screen."
	echo "-pd		Specify how many parallel downloads when downloading more than one. Eg: -pd 2"
	echo "-skip-digital-cert-check	Sometimes, if running through a proxy, wget will refuse to download from GRC. Try this to skip the digital certificate safety check."
	echo "-h		This help output."
	echo " "

	exit 0

}

function do_headers() {

	# Convert the passed array into something usable
	declare -a pass_arr=("${!1}") # Crazy syntax here !

	# Output title.
	echo " "
	echo "Seth Leedy's GRC Security Now Downloader v$this_version"
	echo "Home URL: http://techblog.sethleedy.name/?p=24172"
	echo "	Based off of the scripts by: Thomas@devtactix.com"
	echo "	URL: http://techblog.sethleedy.name/?p=23980"
	echo " "

	echo "Latest Episode is: $latest_episode"
	echo "Latest Episode name is: $latest_episode_name"
	echo " "
	for e in "${pass_arr[@]}" ; do
		echo "$e"
	done

}

# Compress / UnCompress the cache based on available programs.
function do_cache() {

		# Create temp download area
		mkdir $download_temp_txt_search_dir >/dev/null 2>&1 # in case it already exists.

		# If compressed cache exists, uncompress it.
		# Check to see what program we can use to compress/uncompress the cache.
		check_program_exists_arr[0]="foo"
		check_program_exists_arr[1]="gzip"
		check_program_exists_arr[2]="zip"
		check_program_exists_arr[3]="bzip2"
		check_program_exists_arr[4]="7z"
		check_program_exists_multi check_program_exists_arr[@]

		if [[ ${check_program_exists_arr[${#check_program_exists_arr[*]}]} != "" ]] ; then
			if ! $quite_mode ; then
				echo "Using compression program: ${check_program_exists_arr[${#check_program_exists_arr[*]}]}"
			fi

			# Use proper commands for which program is available
			case "${check_program_exists_arr[${#check_program_exists_arr[*]}]}" in
			'gzip')
				cd $download_temp_txt_search_dir/
				if [[ "$1" == "uncompress" ]]; then
					if ! $quite_mode ; then
						echo "Uncompressing cache"
					fi
					gunzip *.txt 1>/dev/null 2>&1
				elif [[ "$1" == "compress" ]]; then
					if ! $quite_mode ; then
						echo "Compressing cache"
					fi
					cmd="gzip *.txt 1>/dev/null 2>&1"
					$cmd &
				fi
				cd ..
				;;
			'zip')
				cd $download_temp_txt_search_dir/
				if [[ "$1" == "uncompress" ]]; then
					if ! $quite_mode ; then
						echo "Uncompressing cache"
					fi
					unzip -qq -o cache.zip 1>/dev/null 2>&1
					rm cache.zip >/dev/null
				elif [[ "$1" == "compress" ]]; then
					if ! $quite_mode ; then
						echo "Compressing cache"
					fi
					cmd="zip -9 -qq cache.zip *.txt 1>/dev/null 2>&1; rm *.txt >/dev/null"
					$cmd &
				fi
				cd ..
				;;
			'bzip2')
				cd $download_temp_txt_search_dir/
				if [[ "$1" == "uncompress" ]]; then
					if ! $quite_mode ; then
						echo "Uncompressing cache"
					fi
					bunzip2 -qf *.bz2 1>/dev/null 2>&1
				elif [[ "$1" == "compress" ]]; then
					if ! $quite_mode ; then
						echo "Compressing cache"
					fi
					cmd="bzip2 -qf -9 *.txt 1>/dev/null 2>&1"
					$cmd &
				fi
				cd ..
				;;
			'7z')
				cd $download_temp_txt_search_dir/
				if [[ "$1" == "uncompress" ]]; then
					if ! $quite_mode ; then
						echo "Uncompressing cache"
					fi
					7z e cache.7z 1>/dev/null 2>&1
					rm cache.7z >/dev/null
				elif [[ "$1" == "compress" ]]; then
					if ! $quite_mode ; then
						echo "Compressing cache"
					fi

					# Run compression in background so there is no delay on the terminal
					# This may cause issues if the user reuses the script immediately. eg: deleting files at the same time as rechecking or downloading on the new script run.
					cmd="7z a -mx=9  cache.7z *.txt 1>/dev/null 2>&1; rm *.txt >/dev/null"
					$cmd &
				fi
				cd ..
			   ;;
			esac

		else
			echo "No compression program found. Install a compression program like 7z or bzip2 to compress the cached search files."
		fi

}

function do_find_latest_episode() {
	# Find the latest episode.
	check_url "$find_latest_episode_url"
	if [ $? -eq 0 ]; then
		if [ -e securitynow.htm ]; then
			rm -f securitynow.htm
		fi

		wget $skip_wget_digital_check -q -O securitynow.htm "$find_latest_episode_url"

		if [ $? -eq 0 ]; then
			if [ -e securitynow.htm ]; then
				latest_episode=$(grep -i '<font size=1>Episode&nbsp;#' securitynow.htm | head -n 1 | cut -d "#" -f 2 | cut -d " " -f 1)
				# Voodoo Code
				latest_episode_name=$(grep -i '<font size=1>Episode&nbsp;#' securitynow.htm | head -n 1 | sed -n '/<b>/,/<\/b>/p'  | sed -e '1s/.*<b>//' -e '$s/<\/b>.*//')

				# Try and make a guesstimate about the amout of space needed for all episodes.
				# Overwrites the defaults
				let DISK_SPACE_MIN_FOR_ALL_AUDIO2=$DISK_SPACE_MIN_FOR_ONE_AUDIO*$latest_episode
				let DISK_SPACE_MIN_FOR_ALL_VIDEO2=$DISK_SPACE_MIN_FOR_ONE_VIDEO*$latest_episode
				let DISK_SPACE_MIN_FOR_ALL_TEXT2=$DISK_SPACE_MIN_FOR_ONE_TEXT*$latest_episode
				let DISK_SPACE_MIN_FOR_ALL_PDF2=$DISK_SPACE_MIN_FOR_ONE_PDF*$latest_episode
				let DISK_SPACE_MIN_FOR_ALL_HTML2=$DISK_SPACE_MIN_FOR_ONE_HTML*$latest_episode
				DISK_SPACE_MIN_FOR_ALL_AUDIO=$DISK_SPACE_MIN_FOR_ALL_AUDIO2
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
	slot_downloads=$(($par_downloads_count))
	#echo "Slot download: $slot_downloads"
	c=$EPISODE
	#for (( c=$EPISODE; $c<=$EPISODE_TO; c=$(($c+$slot_downloads)) )); do
	while [[ $c -le $EPISODE_TO ]]; do

		# Convert the interger to leading zeros for proper filename.
		EPISODE_Cur=$( printf "%03d\n" $(( 10#$c)) )

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

				EPISODE_Cur=$( printf "%03d\n" $(( 10#$d)) )
				EPISODE_NAME_AUDIO_HQ="${EPISODE_NAME_AUDIO_HQ_URL}sn-${EPISODE_Cur}.mp3"

				if ! $quite_mode ; then
					echo "Downloading HQ audio episode ${EPISODE_Cur}..."
				fi

				tpid=`wget $skip_wget_digital_check -N -c -qb "$EPISODE_NAME_AUDIO_HQ"`
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
					echo "Over Number: $EPISODE_TO"
					break
				fi

				EPISODE_Cur=$( printf "%03d\n" $(( 10#$d)) ) # Audio is 3 0s long. Fix this after episode 999.
				EPISODE_NAME_AUDIO_LQ="${EPISODE_NAME_AUDIO_LQ_URL}sn-${EPISODE_Cur}-lq.mp3"

				if ! $quite_mode ; then
					echo "Downloading LQ audio episode ${EPISODE_Cur}..."
				fi

				tpid=`wget $skip_wget_digital_check -N -c -qb "$EPISODE_NAME_AUDIO_LQ"`
				ttpid=(`echo $tpid | cut -d " " -f 5 | cut -d "." -f 1`)
				pid[$d]=$ttpid

				#echo "PID: ${pid[$d]}"
			done
			#echo "D2=$d"
		fi
		if  $download_episode_text ; then
			for (( d=$c; d<$(($c+$slot_downloads)); d++ )); do

				# If the difference is less, then we can't download more.
				epi_no_zero="$(echo $EPISODE_TO | sed 's/0*//')"
				#echo "D: $d"
				#echo "epi: $epi_no_zero"
				if [ $d -gt $epi_no_zero ]; then
					#echo "Over Number: $EPISODE_TO"
					break
				fi

				EPISODE_Cur=$( printf "%03d\n" $(( 10#$d)) ) # Audio is three 0s long. Fix this after episode 999.
				EPISODE_NAME_AUDIO_TEXT="${EPISODE_NAME_AUDIO_TEXT_URL}sn-${EPISODE_Cur}.txt"

				if ! $quite_mode || ( $search_echo_override_mode && ! $quite_mode ) ; then
					if $search_echo_override_mode ; then
						echo -ne "\r${ceol}Checking or Downloading: text episode ${EPISODE_Cur}      "
					else
						echo -ne "\r${ceol}Downloading: text episode ${EPISODE_Cur}      "
					fi

				fi

				tpid=`wget $skip_wget_digital_check -N -c -qb "$EPISODE_NAME_AUDIO_TEXT"`
				ttpid=(`echo $tpid | cut -d " " -f 5 | cut -d "." -f 1`)
				pid[$d]=$ttpid

				#echo "PID: ${pid[$d]}"
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

				EPISODE_Cur=$( printf "%03d\n" $(( 10#$d)) ) # Audio is 3 0s long. Fix this after episode 999.
				EPISODE_NAME_AUDIO_PDF="${EPISODE_NAME_AUDIO_PDF_URL}sn-${EPISODE_Cur}.pdf"

				if ! $quite_mode ; then
					echo "Downloading episode text ${EPISODE_Cur}..."
				fi

				tpid=`wget $skip_wget_digital_check -N -c -qb "$EPISODE_NAME_AUDIO_PDF"`
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

				EPISODE_Cur=$( printf "%03d\n" $(( 10#$d)) ) # Audio is 3 0s long. Fix this after episode 999.
				EPISODE_NAME_AUDIO_HTML="${EPISODE_NAME_AUDIO_HTML_URL}sn-${EPISODE_Cur}.htm"

				if ! $quite_mode ; then
					echo "Downloading episode text ${EPISODE_Cur}..."
				fi

				tpid=`wget $skip_wget_digital_check -N -c -qb "$EPISODE_NAME_AUDIO_HTML"`
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

				EPISODE_Cur=$( printf "%03d\n" $(( 10#$d)) ) # Audio is 3 0s long. Fix this after episode 999.
				EPISODE_NAME_AUDIO_SHOWNOTES="${EPISODE_NAME_AUDIO_SHOWNOTES_URL}sn-${EPISODE_Cur}-notes.pdf"

				if ! $quite_mode ; then
					echo "Downloading episode show notes ${EPISODE_Cur}..."
				fi

				tpid=`wget $skip_wget_digital_check -N -c -qb "$EPISODE_NAME_AUDIO_SHOWNOTES"`
				ttpid=(`echo $tpid | cut -d " " -f 5 | cut -d "." -f 1`)
				pid[$d]=$ttpid

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

				EPISODE_Cur=$( printf "%04d\n" $(( 10#$d)) ) # Video is 4 0s long
				EPISODE_NAME_VIDEO_HQ="${EPISODE_NAME_VIDEO_HQ_URL}sn${EPISODE_Cur}/sn${EPISODE_Cur}_h264m_864x480_500.mp4"
				#echo $EPISODE_NAME_VIDEO_HQ

				check_url "$EPISODE_NAME_VIDEO_HQ"
				if [ $? -eq 0 ]; then
					if ! $quite_mode ; then
						echo "Downloading HQ video episode ${EPISODE_Cur}..."
					fi

					tpid=`wget $skip_wget_digital_check -N -c -qb "$EPISODE_NAME_VIDEO_HQ"`
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

				EPISODE_Cur=$( printf "%04d\n" $(( 10#$d)) ) # Video is 4 0s long
				EPISODE_NAME_VIDEO_LQ="${EPISODE_NAME_VIDEO_LQ_URL}sn${EPISODE_Cur}/sn${EPISODE_Cur}_h264b_640x368_256.mp4"
				echo $EPISODE_NAME_VIDEO_LQ

				check_url "$EPISODE_NAME_VIDEO_LQ"
				if [ $? -eq 0 ]; then
					if ! $quite_mode ; then
						echo "Downloading HQ video episode ${EPISODE_Cur}..."
					fi

					tpid=`wget $skip_wget_digital_check -N -c -qb "$EPISODE_NAME_VIDEO_LQ"`
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
		echo "Done downloading."
	fi



}

# Searching for text in episodes.
function do_searching() {

	# Download all text transcripts and search them.
	if $search_txt_download ; then

		# call uncompress/compress function for cache.
		do_cache "uncompress"

		# Download all the files to search
		#I need to insert a way to narrow down what episodes need downloaded. Instead of rechecking every time. Takes to long that way. wget is set to only download if the server side is newer ( -N ). Still takes a while.
		if ! $quite_mode ; then
			echo "Downloading files"
		fi
		cd $download_temp_txt_search_dir/
		(../$0 -all -eptxt -q -s_override -pd 20) & # Put it into the background so we can use the spinner. Need to capture PID and kill it if we kill this script.
		subsearch_pid=$!
		spinner $subsearch_pid # Run the spinner to show that the script is not stuck
		cd ..

		# Search all the files and put results into a temp file
		grep -w -l -s -i "$search_string" "$download_temp_txt_search_dir/"*.txt *.txt > .found

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

		# call uncompress/compress function for cache.
		do_cache "compress"

	fi

	# Search existing text transcripts
	if $search_txt_local ; then

		# call uncompress/compress function for cache.
		do_cache "uncompress"

		grep -w -l -s -i "$search_string" "$download_temp_txt_search_dir/"*.txt *.txt > .found

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

		# call uncompress/compress function for cache.
		do_cache "compress"
	fi
}

function spinner() {
    local pid=$1
    local delay=0.4
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Check arguments
if [ $# -eq 0 ]; then
	output_help
fi

arg_index=1
until [ -z "$1" ]; do
	#echo "$1"

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

		#echo "ahq: $download_audio_hq, alq: $download_audio_lq, vhq: $download_video_hq, vlq: $download_video_lq"

		if [[ $download_audio_hq || $download_audio_lq ]]; then
			chk_temp=$(chk_disk_space $DISK_SPACE_MIN_FOR_ONE_AUDIO)
		fi
		if [[ $download_video_hq || $download_video_lq ]]; then
			chk_temp=$(chk_disk_space $DISK_SPACE_MIN_FOR_ONE_VIDEO)
		fi

		if $chk_temp; then
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

		chk_temp=$(chk_disk_space $DISK_SPACE_MIN_FOR_ALL_VIDEO)
		if [ $download_audio_hq ] || [ $download_audio_lq ]; then
			if [ $download_audio_hq ] && $chk_temp; then
				download_all=true
			elif [ $download_audio_lq ] && $chk_temp; then
				download_all=true
			else
				echo "Not enough storage space for downloading."
				echo "MIN FOR ALL AUDIO: $DISK_SPACE_MIN_FOR_ALL_AUDIO"
				download_all=false
				exit 9
			fi
		fi

		chk_temp=$(chk_disk_space $DISK_SPACE_MIN_FOR_ALL_PDF) # Doing the PDF since it is normally the largest.
		if [ $download_episode_text ] || [ $download_episode_pdf ] || [ $download_episode_html ]; then
			if [ $download_episode_text ] && $chk_temp; then
				download_all=true
			elif [ $download_episode_pdf ] && $chk_temp; then
				download_all=true
			elif [ $download_episode_html ] && $chk_temp; then
				download_all=true
			else
				echo "Not enough storage space for downloading."
				echo "MIN FOR ALL TEXT $DISK_SPACE_MIN_FOR_ALL_PDF"
				download_all=false
				exit 10
			fi
		fi

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

	shift
done

if [ $download_all ]; then
	do_find_latest_episode

	EPISODE_TO=$latest_episode
fi

if [ $download_latest ]; then
	do_find_latest_episode

	EPISODE=$latest_episode
	EPISODE_TO=$latest_episode
fi


# No sense downloading the latest epi file if just displaying help -h
if [ "$1" == "-h" ]; then
	output_help
fi

if ! $search_txt_local && ! $search_txt_download ; then
	if ! $download_audio_hq && ! $download_audio_lq && ! $download_video_hq && ! $download_video_lq && ! $download_episode_text && ! $download_episode_pdf && ! $download_episode_html && ! $download_episode_shownote; then
		add_to_headers+=("What was I to download ? Please specify any/all of:")
		add_to_headers+=("-ahq  -alq  -vhq  -vlq  -eptxt  -eppdf  -ephtml -epnotes")
		add_to_headers+=(" ")

	fi
fi

# Set episodes
if $download_episode_number ; then
	dummy_fill_var=true
	#if ! $quite_mode ; then
	#	add_to_headers+=("Episode input: ${EPISODE} to ${EPISODE_TO}")
	#fi

elif ! $download_latest && ! $download_all && ! $download_episode_number && ! $search_txt_local && ! $search_txt_download ; then

	EPISODE_found=false

	if $download_audio_hq || $download_audio_lq ; then
		count=`ls -1 *.mp3 2>/dev/null | wc -l`
		if [ $count != 0 ]; then
			# Got the episode number WITH zeros
			EPISODE_capt=$(ls -1 *.mp3 | tail -n 1 | grep -io "^sn-..." | grep -o "...$")
			# Strip the Zeros
			#Needed because bash sees leading zeros as somthing else. "Numerical values starting with a zero (0) are interpreted as numbers in octal notation by the C language. As the only digits allowed in octal are {0..7}, an 8 or a 9 will cause the evaluation to fail."
			declare -i epi_no_zero="$(echo $EPISODE_capt | sed 's/0*//')"
			# Do the math to increase the count AND Bring it back to the leading 0 format so that the filename is correct, using BASE#NUMBER.
			EPISODE=$( printf "%03d\n" $(( 10#$epi_no_zero + 1 )) ) # Does it to 3 zero format. Will need changed after episode # 999

			if ! $quite_mode ; then
				add_to_headers+=("Audio episode input missing, guesstimating latest as: ${EPISODE}")
			fi
			EPISODE_found=true
		fi

	fi
	if [[ $download_video_hq || $download_video_lq ]]; then # What is the video extension ?
		count=`ls -1 *.mp4 2>/dev/null | wc -l`
		if [ $count != 0 ]; then
			EPISODE_capt=$(ls -1 *.mp4 | tail -n 1 | grep -io "^sn...." | grep -o "....$")
			# Strip the Zeros
			#Needed because bash sees leading zeros as somthing else. "Numerical values starting with a zero (0) are interpreted as numbers in octal notation by the C language. As the only digits allowed in octal are {0..7}, an 8 or a 9 will cause the evaluation to fail."
			declare -i epi_no_zero="$(echo $EPISODE_capt | sed 's/0*//')"
			# Do the math to increase the count AND Bring it back to the leading 0 format so that the filename is correct, using BASE#NUMBER.
			EPISODE=$( printf "%03d\n" $(( 10#$epi_no_zero + 1 )) )

			if ! $quite_mode ; then
				add_to_headers+=("Video episode input missing, guesstimating latest as: ${EPISODE}")
			fi
			EPISODE_found=true
		fi

	fi
	if ! $EPISODE_found ; then

		echo "No Episodes found to start with. Can't find the next one to download."
		echo "You in the correct directory ?"
		echo " "
		exit 1
	fi

	EPISODE_TO=$EPISODE

fi

# Show some details if quite mode is off
if ! $quite_mode ; then
	do_headers add_to_headers[@]
fi

#echo "ahq: $download_audio_hq, alq: $download_audio_lq, vhq: $download_video_hq, vlq: $download_video_lq, p: $pretend_mode, all: $download_all, latest: $download_latest, download_episode_number: $download_episode_number"
if ! $quite_mode && ! $search_txt_local && ! $search_txt_download ; then
	echo "Downloading episodes $EPISODE to $EPISODE_TO"
	echo " "
fi

# Before working,
# Send Ping
send_ping


# Do some downloading!
if ! ($search_txt_local || $search_txt_download) ; then
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


do_script_shutdown 0

exit 0
