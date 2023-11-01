#!/bin/bash

# This interactive script creates or deletes a user account on the local system.
# You will be prompted for the account name, public key and password.
# Should work on all recent Linux systems.

# Check if run as root
if [ $EUID -ne 0 ]; then
	echo This script has to be run as root. >&2
	exit 1
fi

# Functions to create and delete a user.

create_user () {
	# Create the user.
	useradd -c "${COMMENT}" -s /bin/bash -m ${USER_NAME}

	# Create a random 16 char password.
	PASSWORD=$(date +%s%N${RANDOM}${RANDOM} | sha256sum | head -c14)
	SPECIAL_CHARACTERS=$(echo '!@#$%^&*()_-+=' | fold -w2 | shuf | head -c2)
	RANDPASS="${PASSWORD}${SPECIAL_CHARACTERS}"

	# Set the password for the user.
	# Eg: echo "${USER_NAME}:${PASSWORD}" | chpasswd
	echo "${USER_NAME}:${RANDPASS}" | chpasswd

	# Force password change on first login.
	passwd -e ${USER_NAME}

	# Add the user SSH public key.
	mkdir /home/${USER_NAME}/.ssh
	echo "${PUBKEY}" > /home/${USER_NAME}/.ssh/authorized_keys

	# Fix permissions
	chown -R ${USER_NAME}: /home/${USER_NAME}/.ssh
	chmod 700 /home/${USER_NAME}/.ssh
	chmod 600 /home/${USER_NAME}/.ssh/authorized_keys
	
	# Add user as an admin?
	# Check if entry exists in sudoers
	USER_IN_SUDOERS=$(grep ${USER_NAME} /etc/sudoers)
	if [ -z "${USER_IN_SUDOERS}" ]; then
		if [ ${NEED_ADMIN} == "y" ]; then
			cat <<-EOF >> /etc/sudoers
			${USER_NAME}  ALL=(ALL)  ALL
			EOF
		fi
	else
		echo "User is present in the sudoers file. User may be an admin, run 'sudo visudo' to check."
	fi
	
	# Check return variable.
	if [ ${?} -eq 0 ]; then
		echo "User ${USER_NAME} created successfully."
	else
		echo "User creation failed"
	fi
}

delete_user () {
	# Delete the user.
	read -p 'Remove the users home directory? [y/n]: ' REMOVE_HOME
	REMOVE_HOME=${REMOVE_HOME:-n}
	if [ ${REMOVE_HOME} == "y" ]; then
		userdel -r ${USER_NAME}
	else
		userdel ${USER_NAME}
	fi
	# Make sure the user got deleted.
	if [[ "${?}" -ne 0 ]]
	then
	  echo "The account ${USER_NAME} was NOT deleted." >&2
	  exit 1
	fi

	# Check if entry exists in sudoers
	USER_IN_SUDOERS=$(grep ${USER_NAME} /etc/sudoers)
	if [ -z "${USER_IN_SUDOERS}" ]; then
		echo User is NOT in the sudoers file. All good.
	else
		echo "User is present in the sudoers file. Removing..."
		sed -i "/^${USER_NAME}/d" /etc/sudoers
	fi

	# Tell the user the account was deleted.
	echo "The user account ${USER_NAME} was deleted."
}

# Ask for the user name.
read -p 'Enter the username to create: ' USER_NAME

# Check if the user exists. If present, ask if you need it deleted.
GETUSER=$(getent passwd ${USER_NAME} | cut -d : -f 1)
# If the user is not present, the GETUSER variable will have a null value. Thus if it is not null...
if [ ! -z "${GETUSER}" ]; then
# If it is not null, the GETUSER variable will contain the username.
	if [ "${GETUSER}" == "${USER_NAME}" ]; then
		echo User ${USER_NAME} exists. >&2
		read -p 'Do you want to delete this user? [y/n]: ' DELUSER
		DELUSER=${DELUSER:-n}
		if [ ${DELUSER} == "y" ]; then
			# Call the function to delete the user.
			delete_user
			exit 0
		else
			echo Exiting...
			exit 1
		fi
	fi
fi

# Ask if user is an admin user or not.
read -p 'Should this user be an admin? [y/n]: ' NEED_ADMIN
NEED_ADMIN=${NEED_ADMIN:-n}

# Ask for the real name.
read -p 'Enter the name of the user (press enter to skip): ' COMMENT
COMMENT=${COMMENT:-NA}

# Ask for the public key.
read -p 'Enter the SSH public key: ' PUBKEY

# Call the function to create the user.
create_user

# Disable password authentication for ssh
# sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config

# Get Public IP
PUBLIC_IP=$(curl -fsSL https://www.icanhazip.com/)

# Display the password
echo ---------------------------------------------------------------------------
echo Login using this command: ssh -i 'PRIVATE_KEY_PATH' ${USER_NAME}@${PUBLIC_IP}
echo Your user name is: ${USER_NAME}
echo Your password is: ${RANDPASS}
echo ***Please change your password on first login***
echo ---------------------------------------------------------------------------

exit 0
