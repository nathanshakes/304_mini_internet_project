students_as=(3 4 5 6 7 8 9 10 11 12 17 18 19 20 21 22 23 24 25 26 31 32 33 34 35 36 37 38 39 40 45 46 47 48 49 50 51 52 53 54 59 60 61 62 63 64 65 66 67 68 73 74 75 76 77 78 79 80 81 82)

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
    if [[ $? -ne 0 ]]; then
      echo "Error running save_configs.sh for AS: ${as}. Skipping..."
      continue
    fi

    # Get the latest configuration file
    configName=$(docker exec -itw /root ${as}_ssh bash -c 'ls -1 configs_*.tar.gz | sort | tail -n 1' | tr -d '\r')
    if [[ -z "$configName" ]]; then
      echo "No configuration file found for AS: ${as}. Skipping..."
      continue
    fi

    # Extract the base name by removing .tar.gz
    baseName="${configName%.tar.gz}"

    # Rename the configuration file
    docker exec -itw /root ${as}_ssh bash -c "cp $configName configs-as-${as}.tar.gz"
    if [[ $? -ne 0 ]]; then
      echo "Error renaming $configName for AS: ${as}. Skipping..."
      continue
    fi

    # Copy the renamed file to the timestamped directory
    docker cp ${as}_ssh:/root/configs-as-${as}.tar.gz "./$timestamp/configs-as-${as}.tar.gz"
    if [[ $? -eq 0 ]]; then
      # Successfully copied, now clean up in the container
      docker exec -itw /root ${as}_ssh bash -c "rm -f configs-as-${as}.tar.gz $configName"
      docker exec -itw /root ${as}_ssh bash -c "rm -rf $baseName"
      echo "Successfully processed and cleaned up AS: ${as}."
    else
      echo "Failed to copy configs-as-${as}.tar.gz to host for AS: ${as}. Leaving files in container for manual review."
    fi
  done

  # Wait for 1 hour before the next run
  echo "Waiting for the next run..."
  sleep 3600
done
