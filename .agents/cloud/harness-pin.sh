# The harness commit a container clones when the repository it runs in is not the harness.
# install-shared-contract.sh fetches exactly this commit and refuses any other, so a container
# loads a reviewed shared contract rather than whatever the remote's default branch says today.
# Bump it to a commit already on master; Test-ContractLoaderChain.ps1 and
# install-shared-contract.test.sh check that the commit exists in this repository's history.
HARNESS_REPO_URL='https://github.com/pyrgos-ai/doug-harness.git'
HARNESS_COMMIT='8c082364dd343ea47025fe6cfce3592c14c93be0'
