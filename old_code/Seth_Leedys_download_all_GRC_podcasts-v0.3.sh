#!/bin/bash

# Version 0.3
# Created: 2012-05-25
# Last Updated: 2012-05-31

#This script will have updates on the http://techblog.sethleedy.name/ website.
# URL: http://techblog.sethleedy.name/?p=24172

# Initialization.
find_latest_episode_url="http://www.grc.com/securitynow.htm"
EPISODE_NAME_AUDIO_HQ_URL="http://media.grc.com/sn/"
EPISODE_NAME_AUDIO_LQ_URL="http://media.grc.com/sn/"
EPISODE_NAME_AUDIO_TEXT_URL="http://www.grc.com/sn/"
EPISODE_NAME_VIDEO_HQ_URL="http://twit.cachefly.net/video/sn/"
EPISODE_NAME_VIDEO_LQ_URL="http://twit.cachefly.net/video/sn/"

# Sizes in Kilo's
DISK_SPACE=1000
DISK_SPACE_MIN_FOR_ALL=3200000 # 3,200 MB or 3.2 GB as Noted on the GRC Newsgroup in 2012-05. We should make this dynamic
DISK_SPACE_MIN_FOR_ALL_VIDEO=20000000
DISK_SPACE_MIN_FOR_ONE=55000 # 55 MB - Largest I saw on the listing @ GRC.COM
DISK_SPACE_MIN_FOR_ONE_VIDEO=55000 # 55 MB - Largest I saw on the listing @ GRC.COM

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

# trap keyboard interrupt (control-c)
trap control_c SIGINT

function control_c() {

	echo " "
	echo "Stopping download(s) before exiting."

	if [ -z "${pid+xxx}" ]; then
		for r in ${pid[@]} ; do
			kill $r #1>/dev/null 2>&1
		done
	fi

	echo "Script killed!"
	exit 1
}

# See if the URL is valid
function check_url() {

	wget -q --spider "$1"

	if [ $? == 8 ]; then
		return 1
	else
		return 0
	fi

}

# Check disk space.
function chk_disk_space() { # Pass a number in whole bytes.

	DISK_SPACE=$(df -T `pwd` | grep -iv "Filesystem" | awk '{print $5}')
	#echo "DISK SPACE: $DISK_SPACE"
	#exit

	if [ "$DISK_SPACE" -le "$1" ]; then
		echo "Minimum amount of diskspace not available! Exiting."
		return 1
	fi

	return 0
}

function output_help() {

	echo " "
	echo " "
	echo "Options are as follows:"
	echo "-ep"
	echo "	Specifies the episodes to download. You can specifiy 1 episode via just the number. Eg: -ep 25"
	echo "It also supports a range separated by a colon. Eg: -ep 1:25"
	echo " "
	echo "	Note: If no options are used to indicate what episode to download, the script will search the local directoy for the latest episode and download the next one automatically."
	echo " "
	echo "-ahq"
	echo "	Download High Quality Audio format."
	echo " "
	echo "-alq"
	echo "	Download Low Quality Audio format"
	echo " "
	echo "-vhq"
	echo "	Download High Quality Video format"
	echo " "
	echo "-vlq"
	echo "	Download Low Quality Video format"
	echo " "
	echo "-eptxt"
	echo "	Download the text transcript of the episode"
	echo " "
	echo "-latest"
	echo "	Download the latest episode. It will try to check for the latest whenever the script is run."
	echo "If this is flagged, it will put the latest episode as the file to download."
	echo " "
	echo "-all"
	echo "	This will download all episode from 1 to -latest"
	echo " "
	echo "-p"
	echo "	Pretend mode. It will only spit out the headers and numbers. It will not download any files"
	echo "(except the webpage needed to find the latest episodes)"
	echo " "
	echo "-q"
	echo "	Quite mode. Nothing but errors will be outputted to the screen."
	echo " "
	echo "-pd"
	echo "	Specify how many parallel downloads when downloading more than one. Eg: -p 2"
	echo " "
	echo "-h"
	echo "	This help output."
	echo " "
	echo " "
	exit

}

function do_headers() {

	#clear
	# Output title.
	echo "Seth Leedy's GRC Security Now Downloader v0.3"
	echo "Home URL: http://techblog.sethleedy.name/?p=24172"
	echo "	Based off of the scripts by: Thomas@devtactix.com"
	echo "	URL: http://techblog.sethleedy.name/?p=23980"
	echo " "

	echo "Latest Episode is: $latest_episode"
	echo "Latest Episode name is: $latest_episode_name"
	echo " "
	echo "$1"

}

# Find the latest episode.
check_url "$find_latest_episode_url"
if [ $? -eq 0 ]; then
	if [ -e securitynow.htm ]; then
		rm -f securitynow.htm
	fi

	wget -q -O securitynow.htm "$find_latest_episode_url"

	if [ $? -eq 0 ]; then
		if [ -e securitynow.htm ]; then
			latest_episode=$(grep -i '<font size=1>Episode&nbsp;#' securitynow.htm | head -n 1 | cut -d "#" -f 2 | cut -d " " -f 1)
			# Voodoo Code
			latest_episode_name=$(grep -i '<font size=1>Episode&nbsp;#' securitynow.htm | head -n 1 | sed -n '/<b>/,/<\/b>/p'  | sed -e '1s/.*<b>//' -e '$s/<\/b>.*//')

			# Try and make a guesstimate about the amout of space needed for all episodes.
			# Overwrites the defaults
			let DISK_SPACE_MIN_FOR_ALL2=$DISK_SPACE_MIN_FOR_ONE*$latest_episode
			let DISK_SPACE_MIN_FOR_ALL_VIDEO2=$DISK_SPACE_MIN_FOR_ONE_VIDEO*$latest_episode
			DISK_SPACE_MIN_FOR_ALL=$DISK_SPACE_MIN_FOR_ALL2
			DISK_SPACE_MIN_FOR_ALL_VIDEO=$DISK_SPACE_MIN_FOR_ALL_VIDEO2
			#echo $DISK_SPACE_MIN_FOR_ALL_VIDEO

			rm -f securitynow.htm
		fi
	fi
else
	echo "Could not retrieve Episode Listing from URL: $find_latest_episode_url"
	exit 1
fi

# Check arguments
if [ $# -eq 0 ]; then
	output_help
fi

arg_index=1
until [ -z "$1" ]; do
	#echo "$1"

	if [ "$1" == "-h" ]; then
		output_help
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
		if chk_disk_space $DISK_SPACE_MIN_FOR_ONE ]; then
			download_audio_hq=true
		else
			echo "Not enough storage space for downloading."
			download_audio_hq=false
			exit 3
		fi
	fi
	if [ "$1" == "-alq" ]; then
		if chk_disk_space $DISK_SPACE_MIN_FOR_ONE ]; then
			download_audio_lq=true
		else
			echo "Not enough storage space for downloading."
			download_audio_lq=false
			exit 4
		fi
	fi
	if [ "$1" == "-eptxt" ]; then
		if chk_disk_space 150 ]; then # Hard coded for small text or html files.
			download_episode_text=true
		else
			echo "Not enough storage space for downloading."
			download_episode_text=false
			exit 5
		fi
	fi
	if [ "$1" == "-vhq" ]; then
		if chk_disk_space $DISK_SPACE_MIN_FOR_ONE_VIDEO ]; then
			download_video_hq=true
		else
			echo "Not enough storage space for downloading."
			download_video_hq=false
			exit 6
		fi
	fi
	if [ "$1" == "-vlq" ]; then
		if chk_disk_space $DISK_SPACE_MIN_FOR_ONE_VIDEO ]; then
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
			chk_temp=$(chk_disk_space $DISK_SPACE_MIN_FOR_ONE)
		fi
		if [[ $download_video_hq || $download_video_lq ]]; then
			chk_temp=$(chk_disk_space $DISK_SPACE_MIN_FOR_ONE_VIDEO)
		fi

		if $chk_temp; then
			EPISODE=$latest_episode
			EPISODE_TO=$latest_episode
			download_latest=true
		else
			download_latest=false
		fi
	fi
	if [ "$1" == "-all" ]; then
		chk_temp=$(chk_disk_space $DISK_SPACE_MIN_FOR_ALL_VIDEO)
		#echo $chk_temp

		if [ $download_video_hq ] || [ $download_video_lq ]; then
			if [ $download_video_hq ] && $chk_temp; then
				download_all=true
			elif [ $download_video_lq ] && $chk_temp; then
				download_all=true
			else
				echo "Not enough storage space for downloading."
				echo "MIN FOR ALL VIDEO: $DISK_SPACE_MIN_FOR_ALL_VIDEO"
				download_all=false
				exit 8
			fi
		fi
		if [ $download_audio_hq ] || [ $download_audio_lq ]; then
			if [ $download_audio_hq ] && $chk_temp; then
				download_all=true
			elif [ $download_audio_lq ] && $chk_temp; then
				download_all=true
			else
				echo "Not enough storage space for downloading."
				echo "MIN FOR ALL AUDIO: $DISK_SPACE_MIN_FOR_ALL"
				download_all=false
				exit 9
			fi
		fi

		if [ $download_all ]; then
			EPISODE_TO=$latest_episode
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

	shift
done

# Set episodes
if $download_episode_number ; then
	if ! $quite_mode ; then
		echo "Episode input: ${EPISODE} to ${EPISODE_TO}"
	fi

elif ! $download_latest  &&  ! $download_all && ! $download_episode_number ; then

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
				add_to_headers+="Audio episode input missing, guesstimating latest as: ${EPISODE}"
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
				add_to_headers+="Video episode input missing, guesstimating latest as: ${EPISODE}"
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
	do_headers "$add_to_headers"
fi

#echo "ahq: $download_audio_hq, alq: $download_audio_lq, vhq: $download_video_hq, vlq: $download_video_lq, p: $pretend_mode, all: $download_all, latest: $download_latest, download_episode_number: $download_episode_number"
if ! $quite_mode ; then
	echo "Downloading episodes $EPISODE to $EPISODE_TO"
	echo " "
fi

if ! $pretend_mode ; then
	# Setup Loop here to download a range of episodes.
	#loop from EPISODE to EPISODE_TO
	for (( c=$EPISODE; c<=$EPISODE_TO; c=$((c+$par_downloads_count)) )); do

		# Convert the interger to leading zeros for proper filename.
		EPISODE_Cur=$( printf "%03d\n" $(( 10#$c)) )

		# Set episode filename and download.
		EPISODE_NAME_AUDIO_TEXT="${EPISODE_NAME_AUDIO_TEXT_URL}sn-${EPISODE_Cur}.txt"
		EPISODE_NAME_VIDEO_HQ="${EPISODE_NAME_VIDEO_HQ_URL}" # Needs filled in with the video URL filename when found.
		EPISODE_NAME_VIDEO_LQ="${EPISODE_NAME_VIDEO_LQ_URL}"

		if [ $download_audio_hq ]; then
			for (( d=$c; d <= $((c+par_downloads_count-1)); d++ )); do

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

				tpid=`wget -qb "$EPISODE_NAME_AUDIO_HQ"`
				ttpid=(`echo $tpid | cut -d " " -f 5 | cut -d "." -f 1`)
				pid[$d]=$ttpid

				#echo "PID: ${pid[$d]}"
			done
		fi
		if [ $download_audio_lq ]; then
			for (( d=$c; d <= $((c+par_downloads_count-1)); d++ )); do

				# If the difference is less, then we can't download more.
				epi_no_zero="$(echo $EPISODE_TO | sed 's/0*//')"
				#echo "D: $d"
				#echo "epi: $epi_no_zero"
				if [ $d -gt $epi_no_zero ]; then
					#echo "Over Number: $EPISODE_TO"
					break
				fi

				EPISODE_Cur=$( printf "%03d\n" $(( 10#$d)) ) # Audio is 3 0s long. Fix this after episode 999.
				EPISODE_NAME_AUDIO_LQ="${EPISODE_NAME_AUDIO_LQ_URL}sn-${EPISODE_Cur}-lq.mp3"

				if ! $quite_mode ; then
					echo "Downloading LQ audio episode ${EPISODE_Cur}..."
				fi

				tpid=`wget -qb "$EPISODE_NAME_AUDIO_LQ"`
				ttpid=(`echo $tpid | cut -d " " -f 5 | cut -d "." -f 1`)
				pid[$d]=$ttpid

				#echo "PID: ${pid[$d]}"
			done
		fi
		if [ $download_episode_text ]; then
			for (( d=$c; d <= $((c+par_downloads_count-1)); d++ )); do

				# If the difference is less, then we can't download more.
				epi_no_zero="$(echo $EPISODE_TO | sed 's/0*//')"
				#echo "D: $d"
				#echo "epi: $epi_no_zero"
				if [ $d -gt $epi_no_zero ]; then
					#echo "Over Number: $EPISODE_TO"
					break
				fi

				EPISODE_Cur=$( printf "%03d\n" $(( 10#$d)) ) # Audio is 3 0s long. Fix this after episode 999.
				EPISODE_NAME_AUDIO_TEXT="${EPISODE_NAME_AUDIO_TEXT_URL}sn-${EPISODE_Cur}.txt"

				if ! $quite_mode ; then
					echo "Downloading episode text ${EPISODE_Cur}..."
				fi

				tpid=`wget -qb "$EPISODE_NAME_AUDIO_TEXT"`
				ttpid=(`echo $tpid | cut -d " " -f 5 | cut -d "." -f 1`)
				pid[$d]=$ttpid

				#echo "PID: ${pid[$d]}"
			done
		fi
		if [ $download_video_hq ]; then
			for (( d=$c; d <= $((c+par_downloads_count-1)); d++ )); do

				# If the difference is less, then we can't download more.
				epi_no_zero="$(echo $EPISODE_TO | sed 's/0*//')"
				#echo "D: $d"
				#echo "epi: $epi_no_zero"
				if [ $d -gt $epi_no_zero ]; then
					#echo "Over Number: $EPISODE_TO"
					break
				fi

				EPISODE_Cur=$( printf "%04d\n" $(( 10#$d)) ) # Video is 4 0s long
				EPISODE_NAME_VIDEO_HQ="${EPISODE_NAME_VIDEO_HQ_URL}sn${EPISODE_Cur}/sn${EPISODE_Cur}_h264b_864x480_500.mp4"

				check_url "$EPISODE_NAME_VIDEO_HQ"
				if [ $? -eq 0 ]; then
					if ! $quite_mode ; then
						echo "Downloading HQ video episode ${EPISODE_Cur}..."
					fi

					tpid=`wget -qb "$EPISODE_NAME_VIDEO_HQ"`
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
		if [ $download_video_lq ]; then
			for (( d=$c; d <= $((c+par_downloads_count-1)); d++ )); do

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

				check_url "$EPISODE_NAME_VIDEO_LQ"
				if [ $? -eq 0 ]; then
					if ! $quite_mode ; then
						echo "Downloading HQ video episode ${EPISODE_Cur}..."
					fi

					tpid=`wget -qb "$EPISODE_NAME_VIDEO_LQ"`
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

		# Loop with a sleep inside until the current wget downloads are done.
		# Then Loop around again to do the next -pd amount.
		for r in ${pid[@]} ; do
			#echo "PS: ${pid[$r]}"
			#echo "R: $r"
			ps -p $r 1>/dev/null 2>&1
			while [ $? == 0 ]; do
				sleep 3
				ps -p $r 1>/dev/null 2>&1
			done
		done

	done

	if ! $quite_mode ; then
		echo "Done downloading."
	fi

else
	if ! $quite_mode ; then
		echo "Pretend mode was enabled. Nothing Downloaded."
	fi

fi


exit 0