#!/bin/bash

echo "This email was generated at: "$(date "+%H:%M:%S   %d/%m/%y") > email_to_send.txt
echo -e "\nThe current uptime is: "$(uptime -s) >> email_to_send.txt
echo -e "\nThe currently running python3 processes are:" >> email_to_send.txt
ps aux | grep python3 >> email_to_send.txt
echo -e "\nThe most recent property listing generated is: " >> email_to_send.txt
ls -lAtr /media/charlie/raspi_usb/ProjectHousing/data/zoopla/propertylistings | tail -1 >> email_to_send.txt
echo -e "\nThe most recently updated TimeLapse Propogation:" >> email_to_send.txt
ls -lAtr /media/charlie/raspi_usb/TimeLapse/pictures | tail -1 >> email_to_send.txt
echo -e "\nThe currently scheduled cronjobs are :" >>email_to_send.txt
crontab -l >> email_to_send.txt
mail -s "Daily Pi logfile update: "$(date "+%d/%m/%y") $1 < email_to_send.txt 
rm email_to_send.txt
