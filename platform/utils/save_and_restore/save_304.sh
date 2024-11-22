students_as=(3 4 5 6 13 14 15 16)

cd "$(dirname "$0")/../../../"
if ! [[ -d students_config ]]; then
  mkdir students_config
fi

cd students_config/

while true; do
  # Create a new directory with the current date and time
  timestamp=$(date "+%Y-%m-%d_%H-%M-%S")
  mkdir "$timestamp"

  for as in ${students_as[@]}; do
    echo "Saving config on AS: ${as}"

    # Run save_configs.sh script in the container
    docker exec -itw /root ${as}_ssh "./save_configs.sh" > /dev/null

    # Get the latest configuration file
    configName=$(docker exec -itw /root ${as}_ssh bash -c 'ls -1 configs_*.tar.gz | sort | tail -n 1' | sed -e 's/\r$//')
    
    # Check if configName is valid before proceeding
    if [[ -z "$configName" ]]; then
      echo "No configuration file found for AS: ${as}. Skipping..."
      continue
    fi

    # Rename the configuration file
    docker exec -itw /root ${as}_ssh bash -c "mv $configName configs-as-${as}.tar.gz"

    # Copy the renamed file to the timestamped directory
    docker cp ${as}_ssh:/root/configs-as-${as}.tar.gz "./$timestamp/configs-as-${as}.tar.gz"
  done

  # Wait for 1 hour before the next run
  echo "Waiting for the next run..."
  sleep 3600
done

