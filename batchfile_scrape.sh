#!/bin/bash
/usr/local/stata15/stata  -b do '"/home/mlee/Documents/projects/scraper/code/batch_download_quota_monitoring.do"'


# This is a very simple shell script. It just runs a stata do file. The only reason it exists is because it makes my crontab life easy.  I think I could probably just put this line into my crontab though
