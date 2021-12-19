These two files allow us to count how many times the script is run in the wild.

The BASH script does a "ping" to my Tech Blog website and the results are visible @ http://techblog.sethleedy.name/?page_id=24223
This "ping" sends a custom useragent specifying the version number of the script.
The PHP code in do_count.php will increment the tally for that version, in a MySQL database.
The show_count.php simply displays the different versions tallies like below(2015/10/09):

Count of script executions:
Agent: GRCDownloader_v0.8, Count: 2 
Agent: GRCDownloader_v0.9, Count: 11 
Agent: GRCDownloader_v1.0, Count: 14 
Agent: GRCDownloader_v1.1, Count: 1 
Agent: GRCDownloader_v1.2, Count: 2 
Agent: GRCDownloader_v1.3, Count: 137 
Agent: GRCDownloader_v1.4, Count: 46 
Agent: GRCDownloader_v1.5, Count: 114 
Agent: GRCDownloader_v1.6, Count: 506 
Agent: GRCDownloader_v1.7, Count: 192
