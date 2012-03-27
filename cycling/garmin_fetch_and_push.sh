#!/bin/bash
#
# Jan Pieter Waagmeester <jieter@jieter.nl>
#
# Fetch the track from any Garmin gps device supported by gpsbabel and
# push the .gpx to garmin connect.
#
# Depends on (at least): curl, gpsbabel
# 
# Garmin connect part ripped from
# http://www.braiden.org/svn/trunk/projects/garmin-dev/uploadruns


# Garmin connect username & password.
USER="<username>"
PASSWORD="<password>"

# create a temporary file
# delegate to "tempfile" command if it exists
function tempfile {
	if [ -x /bin/tempfile ] ; then
		/bin/tempfile
	else 
		echo "/tmp/$1"
	fi
}

# login in to garmin saving cookies
# to file pointed to by $COOKIES
function login {
	  if [ -z "$USER" -o -z "$PASSWORD" ] ; then
		return 1
	  fi

	  # 1) load sign page, and store any intial sesison cookies provided
	  # 2) post the login data
	  # 3) call the username json service to see if login succeeded

	  curl \
		--silent \
		--location \
		--cookie "$COOKIES" \
		--cookie-jar "$COOKIES" \
		--output /dev/null \
		"http://connect.garmin.com/signin" ;\
	  curl \
		--silent \
		--location \
		--cookie "$COOKIES" \
		--cookie-jar "$COOKIES" \
		--data "login=login&login%3AloginUsernameField=$USER&login%3Apassword=$PASSWORD&login%3AsignInButton=Sign+In&javax.faces.ViewState=j_id1" \
		--output /dev/null \
		"https://connect.garmin.com/signin" ;\
	  curl \
		--silent \
		--location \
		--cookie "$COOKIES" \
		--cookie-jar "$COOKIES" \
		--output - \
		"http://connect.garmin.com/user/username" |\
	grep -i "$USER"
	if [ $? == 0 ] ; then
		return 0
	else
		return 1
	fi
}
# send the specified tcx file to garmin
# assumes we're already logged in
function sendgpx {
	GPX=$1
	response=`curl \
		-\# \
		--location \
		--cookie "$COOKIES" \
		--cookie-jar "$COOKIES" \
		--form "responseContentType=text%2Fhtml" \
		--form "data=@$GPX" \
		--output - \
		"http://connect.garmin.com/proxy/upload-service-1.1/json/upload/.tcx" `

	#dirty but it works.
	id=`echo "$response" | grep "internalId" | cut -d ":" -f 2 |tr -d ' ,'`
	echo "New activity url: http://connect.garmin.com/activity/"$id

	# TODO: read response and change name
	# https://github.com/chmouel/python-garmin-upload/blob/master/UploadGarmin.py
}

# login cookies are saved here
COOKIES=`tempfile garmin-cookies.txt`


today=`date "+%Y-%m-%d"`

filename="tracks/$today-track.gpx"

if [ -f $filename ]; then
	echo 'File for today already there, skip fetching'
else
	gpsbabel  -t -i garmin -f usb: -o gpx,gpxver=1.1 -F $filename
	echo "Wrote .gpx 1.1 file to $filename"
	#todo use date from gpx...
fi

if login; then
	echo 'Login succesfull...'
	if sendgpx $filename; then
		echo 'send successfully'
	else
		echo 'failed to upload to garmin connect'
	fi
else
	echo 'Unable to login'
	echo "Make sure you specified user name an password."
	echo "USER=$USER PASSWORD=$PASSWORD $0"
fi

rm -f $COOKIES

#echo "Wrote .gpx 1.1 file to $filename"


