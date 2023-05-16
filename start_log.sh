# if [ -z "$1" ]
# then
#     bash android_log.sh -f logcat
# else
#     echo $1
#     bash android_log.sh -f $1
# fi
if [ -z "$1" ]
then
    filename="logcat"
else
    filename="$1"
fi

bash android_log.sh "$filename"
