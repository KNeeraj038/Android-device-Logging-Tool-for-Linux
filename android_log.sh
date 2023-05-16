

# Map of error codes and error messages
declare -A ERROR_MESSAGES=(
  [1]="adb is not installed. Please install the Android SDK."
  [2]="No Android devices found. Please connect a device."
  [3]="Invalid option provided. Usage: start_android_log.sh [-f <filename>]"
  [4]="Logcat buffer overflow. Please reduce logging level or increase buffer size."
  [5]="Failed to create log directory."
  [6]="Failed to create log file."
  [7]="Failed to read logcat output."
  [8]="Invalid device selection"
  [9]="No devices connected"
  [10]=" "
)

remove_whitespace() {
    input_string="$1"
    cleaned_string=$(echo "$input_string" | sed 's/ /-/g')
    echo "$cleaned_string"
}

# Set error code to 0 by default
error_code=0

# Check if adb is installed
if ! command -v adb &> /dev/null
then
    echo ${ERROR_MESSAGES[1]}
    error_code=1
fi

# Run adb devices command and store the output
adb_devices_output=$(adb devices)

# Extract the list of connected devices
connected_devices=$(echo "$adb_devices_output" | grep "device$" | awk '{print $1}')

# Check if there are connected devices
if [ -z "$connected_devices" ]; then
    echo ${ERROR_MESSAGES[2]}
    error_code=2
fi

# Check if there is more than one connected device
num_devices=$(echo "$connected_devices" | wc -l)
if [ "$num_devices" -gt 1 ]; then
    echo "Multiple devices connected. Please select a device:"

    # Print the list of connected devices with indices
    index=1
    while IFS= read -r device; do
        echo "$index) $device"
        ((index++))
    done <<< "$connected_devices"

    # Prompt the user for device selection
    read -rp "Enter the device number: " device_index

    # Validate the selected index
    if [[ "$device_index" =~ ^[0-9]+$ ]] && [ "$device_index" -ge 1 ] && [ "$device_index" -le "$num_devices" ]; then
        # Extract the selected device
        selected_device=$(echo "$connected_devices" | sed -n "${device_index}p")
        echo "Selected device: $selected_device"
    else
        echo ${ERROR_MESSAGES[8]}
        error_code=8
    fi
else
    # Only one device connected, directly assign it
    selected_device=$connected_devices
    echo "Connected device: $selected_device"
fi

# # Check if device is connected
# devices=$(adb devices | sed '1d' | awk '{print $1}')
# if [ -z "$devices" ]
# then
#     echo ${ERROR_MESSAGES[2]}
#     error_code=2
# fi

# Parse command line arguments
filename=""
manufacturer_name_pre=$(adb -s $selected_device shell getprop ro.product.manufacturer)
echo "Pre man: "$manufacturer_name_pre
manufacturer_name=$(remove_whitespace "$manufacturer_name_pre")
echo "Manufacturer name "$manufacturer_name
model_name_raw=$(adb -s $selected_device shell getprop ro.product.model)
model_number=$(remove_whitespace "$model_name_raw")
seperator="_"
foldername="$manufacturer_name$seperator$model_number"
while getopts ":f:" opt; do
  case $opt in
    f)
      filename=$OPTARG
      ;;
    \?)
      echo ${ERROR_MESSAGES[3]}
      error_code=3
      ;;
    :)
      echo ${ERROR_MESSAGES[3]}
      error_code=3
      ;;
  esac
done

echo "filename"$filename
echo "Folder name: "$foldername
echo "Log dump path: "$foldername$filename

# If no filename is specified, use the default filename "logcat"
if [ -z "$filename" ]; then
  filename="logcat"
fi

divider="_"
date=$(date +%Y%m%d_%H%M%S)
extension=".log"
filename=$filename$divider$date$extension
finalFolderName="/media/kneeraj/HDD/logs/"
full_file_path=$finalFolderName$foldername/$filename

echo $full_file_path

# # Create log file
# if ! touch "$full_file_path"; then
#   echo ${ERROR_MESSAGES[6]}
#   # exit 6
# fi

# Get logcat output and write to log file
if [ $error_code -eq 0 ]
then
    echo "Command used to take logs -- adb -s $selected_device logcat"
    adb -s $selected_device logcat > $full_file_path | glogg $full_file_path > /dev/null 2>&1
    # echo "No errors found."
else
    echo "Error: ${ERROR_MESSAGES[$error_code]}"
fi
