# Gemeinschaft Build Environment

At the moment the GS5 repository of Amooma is private access only.
You will need to provide valid credentials during the build phase to get access and build GS5 successfully.

However feedback to the current development of GBE is always welcome.

**IMPORTANT: Please notice the FAQ below for frequently asked questions!
Neither Amooma nor I will answer to any questions that are already answered below in the widest sense.**


### Building Gemeinschaft 5

Gemeinschaft is build with Debian Live.
You may run the Gemeinschaft Build Environment installer as followed (just copy&paste exactly this line):

`curl -sL -o .i -w "URL=\"%{url_effective}\" bash .i \$@" get-gbe.profhost.eu | bash`

Run `./gemeinschaft.sh help` to see a complete list of available options.

*Note: You will need to have at least 4GB free space available.*



## FAQ

### When will I be able to build my own ISO of Gemeinschaft 5?
Probably not too soon as the main repository of GS5 is private only for the moment. From what I know there is no exact target date set yet to open it.


### How can I get access to the private Git of Gemeinschaft 5?
There is no formal way to get access. If you are part of the development staff you should have access already.
For all the others I have to say sorry, it's highly likely you won't get an account and need to wait until the Git repository is publicly available (if ever though).

**Please refrain from requests to get access to the Git.**


### Will there be a download of the generated ISO file available?
Yes. Amooma as the sponsoring developer of Gemeinschaft 5 has stated they are planning to offer a regular daily or weekly download of the generated ISO file of Gemeinschaft 5. However there is no target date set yet.


### How can I build from one of the other branches beside *master*?
First of all the other branches are considered to be *unstable* and are only for preview purposes. They might even be broken somehow and not working as expected.
If you want a working version **use the master branch instead**.

You may install from the development branches by adjusting the install command as followed:
`curl -sL -o .i -w "URL=\"%{url_effective}\" bash .i \$@" get-gbe.profhost.eu | bash -s <BRANCH>`


### How can I support the development of GBE?
If you have deep knowledge about unattended installation of Linux and Open Source software, you may check the install scripts for robustness.
Main scripts can be found in config.v2/chroot_local-hooks, others in config.v2/chroot_local-includes.

Information about installed packages beside the basic Debian system are defined in config.v2/chroot_local-packageslists and separated for which component of Gemeinschaft they are needed. It might be that some of them are included in more than one file which is intended to be more correct with the separation.

The TODO file will also give you an idea of what I was thinking of at the moment.

The Gemeinschaft Build Environment is based on GDFDL which can be found here: http://gdfdl.profhost.eu/.
GDFDL was originally written for Gemeinschaft first and is now available as a separate/generic upstream project.


### Mailing List
A mailing list about Gemeinschaft 5 is available here:
http://groups.google.com/group/gs5-users

It is mainly German but most of the participants should also be willing to answer in English.


### Personal Contact
In case you would like to get in touch with me,
you may reach me via Twitter: http://twitter.com/Loredo