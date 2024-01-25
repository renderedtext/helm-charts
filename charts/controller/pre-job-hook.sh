# Install the Semaphore toolbox in the job
rm -rf ~/.toolbox

downloadPath="https://github.com/semaphoreci/toolbox/releases/latest/download/self-hosted-linux.tar"
if [ ! -z "${SEMAPHORE_TOOLBOX_VERSION}" ]; then
  downloadPath="https://github.com/semaphoreci/toolbox/releases/download/$SEMAPHORE_TOOLBOX_VERSION/self-hosted-linux.tar"
fi

echo "Downloading Semaphore toolbox from $downloadPath..."
curl -sL --retry 5 --connect-timeout 3 $downloadPath -o /tmp/toolbox.tar
tar -xvf /tmp/toolbox.tar
mv toolbox ~/.toolbox
if [ ! -d ~/.toolbox ]; then
  echo "Failed to download toolbox."
  return 1
fi

echo "Installing..."
bash ~/.toolbox/install-toolbox
if [ "$?" -ne "0" ]; then
  echo "Failed to install toolbox."
  rm -rf $SEMAPHORE_GIT_DIR
fi

source ~/.toolbox/toolbox
if [ "$?" -ne "0" ]; then
  echo "Failed to source toolbox."
  rm -rf $SEMAPHORE_GIT_DIR
fi

echo "Semaphore toolbox successfully installed."

# Create SSH configuration.
# This is required in order to avoid having to manually accept the GitHub SSH keys fingerprints on checkout.
# Ideally, we should populate ~/.ssh/known_hosts with the GitHub keys from api.github.com/meta.
mkdir -p ~/.ssh
echo 'Host github.com' | tee -a ~/.ssh/config
echo '  StrictHostKeyChecking no' | tee -a ~/.ssh/config
echo '  UserKnownHostsFile=/dev/null' | tee -a ~/.ssh/config
