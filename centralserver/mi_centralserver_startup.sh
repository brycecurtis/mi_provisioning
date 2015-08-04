#!/bin/bash
# AUTHOR: Asher Johnson
# PURPOSE: Startup Docker Containers in proper environment order for the Central Server

logfile=/var/log/mi-startup.log
emailrecipient=johnsoca@us.ibm.com
numberoftries=30


sendEmail () {
    my_message="$1 Failed to Startup"

	nc 127.0.0.1 587 <<-EOF
	ehlo mail.script
	mail from:<startup_script@miserver>
	rcpt to:<$emailrecipient>
	data
	subject: $my_message
	$my_message
	.
	quit
	EOF
}


# Handles if a server does not startup
# $1 is the name of the server
# $2 is the boolean for if we should send an email or not on failure
errorHandler() {
	logtime=`date "+%Y-%m-%d %H:%M:%S"`
	echo "$logtime : Error starting $1" >> $logfile
	if [ $2 = true ]; then
		sendEmail $1
	fi
}





logtime=`date "+%Y-%m-%d %H:%M:%S"`
echo "$logtime : Starting containers..." >> $logfile



# Confirm Docker is started
counter=0
while [[ "`pgrep docker`" == "" && $counter != $numberoftries ]]
do
        sleep 5s
        (( counter++ ))
done
if [ $counter == $numberoftries ]; then
	errorHandler "Docker" false
fi


# Startup ETCD Container
docker start MI_ETCD
counter=0
while [[ "`curl -sL -w %{http_code} http://localhost:2379/v2/keys/ -XGET -o /dev/null`" != "200"  && $counter < $numberoftries ]]
do
        sleep 5s
        (( counter++ ))
done
if [ $counter == $numberoftries ]; then
	errorHandler "ETCD" false
fi


# Startup SMTP Server
docker start MI_SMTP
sleep 10s


# Startup Certificate Management Server
docker start MI_CMS
counter=0
while [[ "`curl -sL localhost:9292/cms/api/v1/cmd/ping`" != ping* && $counter < $numberoftries ]]
do
        sleep 5s
        (( counter++ ))
done
if [ $counter == $numberoftries ]; then
	errorHandler "Certificate_Management_Server" true
fi


# Startup Multipurpose Messaging Queue
docker start MI_MPMQ
counter=0
while [[ "`curl -sL localhost:9293/MPMQ/ping`" != ping* && $counter < $numberoftries ]]
do
        sleep 5s
        (( counter++ ))
done
if [ $counter == $numberoftries ]; then
	errorHandler "Multipurpose_Messaging_Queue" true
fi


# Startup APNS Server
docker start MI_APNS
counter=0
while [[ "`curl -sL localhost:9290/IBMAPNS/api/ping`" != ping* && $counter < $numberoftries ]]
do
        sleep 5s
        (( counter++ ))
done
if [ $counter == $numberoftries ]; then
	errorHandler "APNS_Server" true
fi


# Startup Account Management Server
docker start MI_AMS
counter=0
while [[ "`curl -sL localhost:9291/AccountManager/api/ping`" != ping* && $counter < $numberoftries ]]
do
        sleep 5s
        (( counter++ ))
done
if [ $counter == $numberoftries ]; then
	errorHandler "Account_Management_Server" true
fi


# Startup Go-To-Market Server
docker start MI_GTM
counter=0
while [[ "`curl -sL -w %{http_code} http://localhost:9280/ -XGET -o /dev/null`" != "200"  && $counter < $numberoftries ]]
do
        sleep 5s
        (( counter++ ))
done
if [ $counter == $numberoftries ]; then
	errorHandler "Go_To_Market_Server" false
fi

# Startup External Documentation Server
docker start MI_EXTERNALDOCSERVER
counter=0
while [[ "`curl -sL -w %{http_code} http://localhost:9282/ -XGET -o /dev/null`" != "200"  && $counter < $numberoftries ]]
do
        sleep 5s
        (( counter++ ))
done
if [ $counter == $numberoftries ]; then
	errorHandler "External_Documentation_Server" false
fi



# Everything started successfully
logtime=`date "+%Y-%m-%d %H:%M:%S"`
echo "$logtime : Started containers successfully." >> $logfile
