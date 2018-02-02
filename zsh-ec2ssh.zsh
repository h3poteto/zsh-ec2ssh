function _load_aws_profile() {
    local aws_profile=$1
    if [ -z "${aws_profile}" ]; then
        aws_profile=$AWS_DEFAULT_PROFILE
    fi
    echo $aws_profile
    return
}

function _load_aws_region() {
    local aws_region=$1
    if [ -z "${aws_region}" ]; then
        aws_region=$AWS_DEFAULT_REGION
    fi
    echo $aws_region
    return
}

function _load_user() {
    local user=$1
    if [ -z "${user}" ]; then
        user=$USER
    fi
    echo $user
    return
}

function _load_ssh_private_key_path() {
    local private_key_path=$1
    if [ -z "${private_key_path}" ]; then
        private_key_path="$HOME/.ssh/id_rsa"
    fi
    echo $private_key_path
    return
}

function zsh-ec2ssh() {
    local aws_profile_name=$1
    local aws_region=$2
    local ssh_user=$3
    local ssh_private_key_path=$4
    local ssh_proxy=$5
    local proxy_user=$6

    aws_profile_name=`_load_aws_profile $aws_profile_name`
    aws_region=`_load_aws_region $aws_region`
    ssh_user=`_load_user $ssh_user`
    ssh_private_key_path=`_load_ssh_private_key_path $ssh_private_key_path`

    if [ -z "${aws_profile_name}" ]; then
        echo "AWS profile name is required. Please call this function with aws profile name or set AWS_DEFAULT_REGION in evironment variables."
        return
    fi

    if [ -z "${aws_region}" ]; then
        echo "AWS region is required. Please call this function with aws region or set AWS_DEFAULT_REGION in environment variables."
        return
    fi

    if [ -z "${ssh_user}" ]; then
        echo "User is required. Please call this function with user or set USER in environment variables."
        return
    fi

    echo "Fetching ec2 host..."
    local selected_host=$(myaws ec2 ls --profile=${aws_profile_name} --region=${aws_region} --fields='InstanceId PublicIpAddress LaunchTime Tag:Name Tag:attached_asg' | sort -k4 | peco | cut -f2)
    if [ -n "${selected_host}" ]; then
        if [ -z "${ssh_proxy}" ]; then
            BUFFER="ssh ${ssh_user}@${selected_host} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${ssh_private_key_path}"
        else
            BUFFER="ssh -t ${proxy_user}@${ssh_proxy} ssh ${ssh_user}@${selected_host} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${ssh_private_key_path}"
        fi
        if zle; then
            zle accept-line
        else
            print -z "$BUFFER"
        fi
    fi
    if zle; then
        zle clear-screen
    fi
}
zle -N zsh-ec2ssh

function zsh-ec2ssh-with-proxy() {
    local aws_profile_name=$1
    local aws_region=$2
    local ssh_user=$3
    local ssh_proxy_profile=$4
    local proxy_user=$5
    local ssh_private_key_path=$6

    aws_profile_name=`_load_aws_profile $aws_profile_name`
    aws_region=`_load_aws_region $aws_region`
    ssh_user=`_load_user $ssh_user`
    ssh_proxy_profile=`_load_aws_profile $ssh_proxy_profile`
    proxy_user=`_load_user $proxy_user`
    ssh_private_key_path=`_load_ssh_private_key_path $ssh_private_key_path`

    if [ -z "${aws_profile_name}" -o -z "${ssh_proxy_profile}" ]; then
        echo "AWS profile name is required. Please call this function with aws profile name or set AWS_DEFAULT_REGION in evironment variables."
        return
    fi

    if [ -z "${aws_region}" ]; then
        echo "AWS region is required. Please call this function with aws region or set AWS_DEFAULT_REGION in environment variables."
        return
    fi

    if [ -z "${ssh_user}" -o -z "${proxy_user}" ]; then
        echo "User is required. Please call this function with user or set USER in environment variables."
        return
    fi

    echo "Fetching ec2 host..."
    local selected_proxy=$(myaws ec2 ls --profile=${ssh_proxy_profile} --region=${aws_region} --fields='InstanceId PublicIpAddress LaunchTime Tag:Name Tag:attached_asg' | sort -k4 | peco | cut -f2)
    if [ -n "${selected_proxy}" ]; then
        zsh-ec2ssh $aws_profile_name $aws_region $ssh_user $ssh_private_key_path $selected_proxy $proxy_user
    fi
    if zle; then
        zle clear-screen
    fi
}
zle -N zsh-ec2ssh-with-proxy
