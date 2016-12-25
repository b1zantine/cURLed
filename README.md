# cURLed
:shell: Splits a file into 50MB parts and downloads them through SSN proxy (which is hardcoded :P). You could still use the `--noproxy` argument to bypass the SSN proxy.

#### Install
Grab using `cURL` 
```sh
curl -o curled https://raw.githubusercontent.com/SudarAbisheck/cURLed/master/curled.sh\
&& chmod +x curled && sudo mv curled /usr/bin
```
or using `wget`
```sh
wget -O curled https://raw.githubusercontent.com/SudarAbisheck/cURLed/master/curled.sh\
&& chmod +x curled && sudo mv curled /usr/bin
```

#### Usage
```sh
curled [URL] [OPTION]
curled --help

Try `curled --help` for more options.
```

#### Options
```sh
--noproxy     -       Doesn't use SSN proxy
```
