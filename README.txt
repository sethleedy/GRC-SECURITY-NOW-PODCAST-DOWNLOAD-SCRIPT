Seth Leedy's GRC Security Now Downloader
Options are as follows:
-ep		Specifies the episodes to download. You can specifiy 1 episode via just the number. Eg: -ep 25
		It also supports a range separated by a colon. Eg: -ep 1:25
		OR -ep 250:latest to grab all episodes from number 250 to whatever the latest is.
-latest		Download the latest episode. It will try to check for the latest whenever the script is run.
		If this is flagged, it will put the latest episode as the file to download.
-all		This will download all episodes from 1 to -latest
		Note: If no options are used to indicate what episode to download, the script will search the local directory for the latest episode and download the next one automatically.
 
Combine the above option(s) with one or more in the next section:
-ahq		Download High Quality Audio format.
-alq		Download Low Quality Audio format
-vhd		Download High Definition(HD) Quality Video format
-vhq		Download High Quality Video format
-vlq		Download Low Quality Video format
-eptxt		Download the text transcript of the episode
-eppdf		Download the pdf transcript of the episode
-ephtml		Download the html transcript of the episode
-epnotes	Download the show notes of the episode(Not all available)
------------------------------------------------------------------------------------
Search Mode:
-dandstxt	Download and Search, will download all text episodes and search insensitively for the text you enter here.
	OR
-stxt		Search insensitively the local directory .txt episodes for text you enter here.
------------------------------------------------------------------------------------
Create RSS Feed file for RSS News Readers:
-create-rss-audio	Will create a RSS feed file for RSS News Readers containing the Show's audio files.
-create-rss-video	Will create a RSS feed file for RSS News Readers containing the Show's video files.
-create-rss-text	Will create a RSS feed file for RSS News Readers containing the Show's Notes and Transcriptions.
-create-rss-feeds	Will create a RSS feed file for RSS News Readers containing all media files.
-rss-filename		Sets the path and filename of the rss feed file. If excluded, defaults to 'security_now.rss' in the current directory.
-rss-limit			Limits how much text is placed in the RSS feed file from each episode. Default none. Try -rss-limit 100
------------------------------------------------------------------------------------
Misc Options:
-d		Download the files into this specified directory. Eg: -d /home/user/Downloads/security_now
-ff		File Format. Allows you to specify the order of the elements that make up the filename.
			Choose from: <showname> <episodenumber> <episodename> <episodeyear> <date> <type> <raw>(same as the downloaded filename)
			The default is: -ff <raw>
			Presets:
				Ordered:	-ff ordered
					Which is: <number> <name> - <date>
				Kodi:		-ff kodi
					Which is: <showname> S<episodeyear>E<episodenumber> 
-p		Pretend mode. It will only spit out the headers and numbers. It will not download any files
			(except the webpage needed to find the latest episodes)
-q		Quite mode. Minimal on search and nothing but errors on episode downloads will be outputted to the screen.
-pd		Specify how many parallel downloads when downloading more than one. Eg: -pd 2
-u		Auto update the script from GitHub. Run this command alone, as it will not remember the other arguments, nor restart.
-skip-digital-cert-check
		Sometimes, if running through a proxy, wget will refuse to download from GRC. Try this to skip the digital certificate safety check.
-h		This help output.
