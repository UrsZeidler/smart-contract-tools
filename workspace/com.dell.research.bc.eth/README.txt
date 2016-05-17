To build the project you need to make a copy of etc/toolchains.xml and place it in
your ~/.m2 folder for Maven to find.  The file specifies the local installation
details for the java compiler to use when maven is building the system.  You'll need
to edit the copy you make to point to the correct java installation on the build
machine.