set -eo pipefail

# Install the Semaphore toolbox in the job
rm -rf ~/.toolbox
downloadPath="https://github.com/semaphoreci/toolbox/releases/download/v1.19.40/self-hosted-linux.tar"
echo "Installing Semaphore toolbox from $downloadPath..."
curl -sL --retry 5 --connect-timeout 3 $downloadPath -o /tmp/toolbox.tar
tar -xvf /tmp/toolbox.tar
mv toolbox ~/.toolbox
bash ~/.toolbox/install-toolbox
source ~/.toolbox/toolbox
echo "Semaphore toolbox successfully installed."

# Create SSH configuration.
# This is required in order to avoid having to manually accept the GitHub SSH keys fingerprints on checkout.
# Ideally, we should populate ~/.ssh/known_hosts with the GitHub keys from api.github.com/meta.
mkdir -p ~/.ssh
echo 'Host github.com' | tee -a ~/.ssh/config
echo '  StrictHostKeyChecking no' | tee -a ~/.ssh/config
echo '  UserKnownHostsFile=/dev/null' | tee -a ~/.ssh/config
