1.

Note: This script assumes that both dcraw and identify (from ImageMagick) are installed and available in your system's PATH. If not, you may need to provide the full paths to the executables in the script.

```shell
sudo apt-get install dcraw
```

2.

```shell
chmod +x checkCR2.sh
```

3.

`.zshrc`

```shell
export PATH="$PATH:/media/user/d/WWW/checkCR2"
```

4.

```shell
source ~/.zshrc
```
