# Gemeinschaft Build Environment

This is the Build Environment used to create the appliance ISO file for Gemeinschaft 5.
It provides an easy installation and a live environment to start your test right away.

Participation in the development especially of the system integration is very welcome. Just use the pull function to send your patches or open an issue report for suggestions and bugs.

**IMPORTANT: Please notice the FAQ below for frequently asked questions!
Neither AMOOMA nor I will answer to any questions that are already answered below in the widest sense.**


### Building Gemeinschaft 5

Gemeinschaft is build with Debian Live.
You may run the Gemeinschaft Build Environment installer as followed (just copy&paste exactly this line):

`curl -sL -o .i -w "URL=\"%{url_effective}\" bash .i \$@" get-gbe.profhost.eu | bash`

Run `./gemeinschaft.sh help` to see a complete list of available options.

*Note: You will need to have at least 4GB free space available.*



## FAQ

### Where can I download a ready to run ISO file? Or do I have to run my own build?
No, building your own image is optional and mostly useful if you would like to check out new functionality from the development branch.
Please visit the website of AMOOMA for available ISO files: http://amooma.de/gemeinschaft/gs5


### How can I build from one of the other branches beside *master*?
First of all the other branches are considered to be *unstable* and are only for preview purposes. They might even be broken somehow and not working as expected.
If you want a working version **use the master branch instead** or download a ready to run ISO file.

You may install from the development branches by adjusting the install command as followed:
`curl -sL -o .i -w "URL=\"%{url_effective}\" bash .i \$@" get-gbe.profhost.eu | bash -s <BRANCH>`

where `<BRANCH>` stands for the actual branch of GBE on Github.


### How can I support the development of GBE?
If you have deep knowledge about unattended installation of Linux and Open Source software, you may check the install scripts for robustness.
Main scripts can be found in config.v2/chroot_local-hooks, others in config.v2/chroot_local-includes.

Information about installed packages beside the basic Debian system are defined in config.v2/chroot_local-packageslists and separated for which component of Gemeinschaft they are needed. It might be that some of them are included in more than one file which is intended to be more correct with the separation.

The Gemeinschaft Build Environment is based on GDFDL which can be found here: http://gdfdl.profhost.eu/.
GDFDL was originally written for Gemeinschaft first and is now available as a separate/generic upstream project.


### Mailing List
A mailing list about Gemeinschaft 5 is available here:
http://groups.google.com/group/gs5-users

It is mainly German but most of the participants should also be willing to answer in English.


### Personal Contact
In case you would like to get in touch with me,
you may reach me via Twitter: http://twitter.com/Loredo
