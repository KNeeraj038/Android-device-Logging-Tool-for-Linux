if [ -z "$1" ]
then
    bash android_log.sh -f logcat
else
    bash android_log.sh -f $1
fi
