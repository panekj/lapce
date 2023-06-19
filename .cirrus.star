load(
    "github.com/cirrus-modules/helpers",
    "task",
    "container",
    "windows_container",
    "macos_instance",
    "script",
    "always",
    "artifacts",
    "cache",
)

def main(ctx):
    return [
        task(
            name="Ubuntu 22.04",
            instance=container(image="ubuntu:22.04", cpu=8.0, memory=16384),
            env={},
            instructions=[
                cache("cargo-git", "${HOME}/.cargo/git"),
                cache("cargo-registry", "${HOME}/.cargo/registry"),
                script("Update APT index", "apt-get -y update"),
                script("Install make", "apt-get -y install make curl git"),
                script("Set release directory", "echo RELEASE_DIR=$(make release-dir) >> $CIRRUS_ENV"),
                script("Install Ubuntu dependencies", "make ubuntu-dependencies"),
                script("Install rustup", "make rustup"),
                script("Add rustup to PATH", "echo PATH=\"$HOME/.cargo/bin:$PATH\" >> $CIRRUS_ENV"),
                script("Build executable", "make gz"),
                script("Build Debian package", "make deb"),
                always(artifacts("Upload DEB", "./${RELEASE_DIR}/linux/lapce.deb")),
                always(artifacts("Upload executable tarball", "./${RELEASE_DIR}/linux/Lapce-linux.tar.gz")),
                always(artifacts("Upload vendor tarball", "./${RELEASE_DIR}/linux/vendor-*.tar.gz")),
            ]
        ),
        task(
            name="Ubuntu 22.04",
            instance=arm_container(image="ubuntu:22.04", cpu=8.0, memory=16384),
            env={},
            instructions=[
                cache("cargo-git", "${HOME}/.cargo/git"),
                cache("cargo-registry", "${HOME}/.cargo/registry"),
                script("Update APT index", "apt-get -y update"),
                script("Install make", "apt-get -y install make curl git"),
                script("Set release directory", "echo RELEASE_DIR=$(make release-dir) >> $CIRRUS_ENV"),
                script("Install Ubuntu dependencies", "make ubuntu-dependencies"),
                script("Install rustup", "make rustup"),
                script("Add rustup to PATH", "echo PATH=\"$HOME/.cargo/bin:$PATH\" >> $CIRRUS_ENV"),
                script("Build executable", "make gz"),
                script("Build Debian package", "make deb"),
                always(artifacts("Upload DEB", "./${RELEASE_DIR}/linux/lapce.deb")),
                always(artifacts("Upload executable tarball", "./${RELEASE_DIR}/linux/Lapce-linux-arm64.tar.gz")),
            ]
        ),
        task(
            name="Windows",
            instance=windows_container(image="cirrusci/windowsservercore:2019"),
            env={
                "CIRRUS_SHELL": "powershell"
            },
            instructions=[
                cache("cargo-git", "${env:USERPROFILE}/.cargo/git"),
                cache("cargo-registry", "${env:USERPROFILE}/.cargo/registry"),
                script("Install make", "choco install make"),
                script("Set release directory", "echo RELEASE_DIR=$(make release-dir) >> $CIRRUS_ENV"),
                script("Install Windows dependencies", "make windows-dependencies"),
                script("Install rustup", "make rustup"),
                script("Add rustup to PATH", "echo PATH=\"${env:USERPROFILE}/.cargo/bin:${env:PATH}\" >> $env:CIRRUS_ENV"),
                script("Build", "make binary"),
                always(artifacts("Upload lapce-proxy", "./${RELEASE_DIR}/windows/lapce-proxy-*.gz")),
                always(artifacts("Upload executables", "./${RELEASE_DIR}/windows/Lapce-windows-*")),
            ]
        ),
        task(
            name="macOS Ventura",
            instance=macos_instance(image="ghcr.io/cirruslabs/macos-ventura-base:latest"),
            env={
                "DMG_NAME": "Lapce-macos.dmg",
            },
            instructions=[
                cache("cargo-git", "${HOME}/.cargo/git"),
                cache("cargo-registry", "${HOME}/.cargo/registry"),
                script("Set release directory", "echo RELEASE_DIR=$(make release-dir) >> $CIRRUS_ENV"),
                script("Install rustup", "make rustup"),
                script("Add rustup to PATH", "echo PATH=\"$HOME/.cargo/bin:$PATH\" >> $CIRRUS_ENV"),
                script("Add x86_64 target", "rustup target add x86_64-apple-darwin"),
                script("Build", "make dmg-universal"),
                script("Build proxy (aarch64)", "make CARGO_BUILD_TARGET=aarch64-apple-darwin TARGET=lapce-proxy gz"),
                script("Build proxy (x86_64)", "make CARGO_BUILD_TARGET=x86_64-apple-darwin TARGET=lapce-proxy gz"),
                always(artifacts("Upload lapce-proxy", "./${RELEASE_DIR}/macos/lapce-proxy-darwin-*.gz")),
                always(artifacts("Upload DMG", "./${RELEASE_DIR}/macos/*.dmg")),
            ],
        ),
    ]
