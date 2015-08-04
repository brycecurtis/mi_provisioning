#!/bin/bash
# AUTHOR: Asher Johnson
# PURPOSE: Startup Docker Containers in proper environment order for the Issuer Server

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


# Startup Configuration Management Server
docker start MI_CONFIGURATIONMANAGER
counter=0
while [[ "`curl -sL localhost:9294/ConfigurationManager/ping`" != ping* && $counter < $numberoftries ]]
do
        sleep 5s
        (( counter++ ))
done
if [ $counter == $numberoftries ]; then
	errorHandler "Configuration_Management_Server" true
fi


# Startup DIGI Storage
docker start MI_DIGISTORAGE


# Startup Document Generator Server
docker start MI_DOCUMENTGENERATOR
counter=0
while [[ "`curl -sL localhost:9298/DocumentGenerator/api/ping`" != ping* && $counter < $numberoftries ]]
do
        sleep 5s
        (( counter++ ))
done
if [ $counter == $numberoftries ]; then
	errorHandler "Document_Generator_Server" true
fi


# Startup Branding Server
docker start MI_BRANDING
counter=0
while [[ "`curl -sL localhost:9296/branding/cmd/ping`" != ping* && $counter < $numberoftries ]]
do
        sleep 5s
        (( counter++ ))
done
if [ $counter == $numberoftries ]; then
	errorHandler "Branding_Server" true
fi


# Startup Queue Processing Manager
docker start MI_QPM

# Startup Issuer Acquisition Server
docker start MI_ISSUER


# Everything started successfully
logtime=`date "+%Y-%m-%d %H:%M:%S"`
echo "$logtime : Started containers successfully." >> $logfile

