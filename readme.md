# AstraClient

AstraClient is the public client identity for this project.

Created/maintained by Mateuzkl.


## Build

### Windows

Install vcpkg:

```powershell
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg
.\bootstrap-vcpkg.bat
.\vcpkg.exe integrate install
```

Open the Visual Studio solution in `vc17`, select the desired backend and platform, then build the `AstraClient` project.

### Linux

```bash
sudo apt update
sudo apt install git curl build-essential cmake gcc g++ pkg-config autoconf libtool libglew-dev -y
git clone https://github.com/microsoft/vcpkg.git ~/vcpkg
~/vcpkg/bootstrap-vcpkg.sh
~/vcpkg/vcpkg install
mkdir build
cd build
cmake -DCMAKE_TOOLCHAIN_FILE=~/vcpkg/scripts/buildsystems/vcpkg.cmake ..
cmake --build . --config Release
```

## Troubleshooting

### vcpkg fails to build `angle` (git `error code: 128` / "dubious ownership")

If the build stops while installing the `angle` dependency with something like:

```
-- Fetching https://chromium.googlesource.com/chromium/src/third_party/zlib ...
CMake Error ... Command failed: "git.exe" fetch https://chromium.googlesource.com/... --depth 1 -n
EXEC : error code: 128
...
fatal: detected dubious ownership in repository at 'D:/vcpkg/downloads/git-tmp'
'D:/vcpkg/downloads/git-tmp' is owned by: (some other SID)
but the current user is: <you>
```

**Cause:** your vcpkg folder is owned by a different Windows account than the one
running the build, so Git refuses to operate inside it and the dependency fetch
fails. It is not a network problem and not a code problem.

**Fix** — tell Git to trust your vcpkg directory, then rebuild.

The simplest, **path-independent** fix (works no matter which drive vcpkg is on —
`C:`, `D:`, `E:`, …):

```powershell
git config --global --add safe.directory *
```

The `*` is a catch-all that covers every folder, so you don't even need to know
where vcpkg lives. If you'd rather scope it, replace the path with **your own
vcpkg location**. You can read the exact path straight from the error message —
the `'X:/vcpkg/downloads/git-tmp' is owned by ...` line tells you the drive/folder
(in the example above it's `D:`, but yours may be `C:/vcpkg`, `E:/dev/vcpkg`, etc.):

```powershell
# change C:/vcpkg to wherever YOUR vcpkg folder actually is
git config --global --add safe.directory C:/vcpkg
```

> Note: `angle` only builds for the **DirectX** backend and compiles from source
> (debug + release), which can take several minutes — that is normal, not a hang.

**Permanent alternative** — take ownership of the vcpkg folder (run PowerShell as
Administrator). Replace `C:\vcpkg` with your actual vcpkg path; afterwards you can
drop the `*` rule:

```powershell
# change C:\vcpkg to your own vcpkg path
takeown /F C:\vcpkg /R /D Y
icacls C:\vcpkg /grant "$($env:USERNAME):(OI)(CI)F" /T
git config --global --unset-all safe.directory
```

## Credits

See `CREDITS.md` for upstream and license-related credits.
