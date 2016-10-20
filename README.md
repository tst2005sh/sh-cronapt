
This script is a `cron-apt`-like shell script.

Comparison
==========

What is similar ?
-----------------

 * I want the script check if some updates are available
 * I want the script download the package (to be ready to install)
 * I want the script send me an email

What is different ?
-------------------

 * I want a verbose email content about available updates
 * I don't want receive an email when there is nothing to do
 * I want summary information in the subject

The problem
===========

A verbose configuration of `cron-apt` means receiving email each day.
`cron-apt` does not provide info in the subject.

My solution
===========

Summary legend

 * `~` means *change* : upgraded package
 * `+` means *new* : newly installed package
 * `-` means *remove* : removed package

Sample
------

```sh
MAILTO=root /path/to/bin/cronapt.sh
```

Will send an email like
```
Subject: CRON-APT: available updates [~1/+0/-0]

Inst linux-libc-dev [3.16.36-1+deb8u1] (3.16.36-1+deb8u2 Debian-Security:8/stable [amd64])
Conf linux-libc-dev (3.16.36-1+deb8u2 Debian-Security:8/stable [amd64])
```

License
=======

My code is under MIT License
