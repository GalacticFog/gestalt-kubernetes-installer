# target_kube_context='minikube'

# Generate a configuration if not already present
# if [ ! -f config.yaml ]; then
    minikube_host=$(minikube ip)
    exit_on_error "Could not get minikube IP address, aborting"

    cat > config.yaml <<EOF
GESTALT_URL:                 http://$minikube_host:31112  # (Gestalt Login URL)
KONG_URL:                    http://$minikube_host:31113  # (Endpoint for API Gateway)
EOF

# fi

# echo "Please review your settings (`pwd`/config.yaml):"
echo "The following Minikube specific settings will be used:"
echo
cat ./config.yaml | sed 's/^/    /g' | sed 's/#//g'

# do_prompt_to_continue "Are the settings correct?  If not, please modify `pwd`/pre-check.sh and re-start the installation."
