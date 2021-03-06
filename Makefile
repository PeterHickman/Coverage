INSTALL=install

INSTALL_COMMAND=${INSTALL} -c -m 755 -o root -g wheel

##
## Where to put the programs
##

PROGRAM_DIR=/usr/local/share/lua/5.1
PROGRAMS=$(shell ls -1 *.lua)
PROGRAM_FILES=${PROGRAMS:%=${PROGRAM_DIR}/%}

all: ${PROGRAM_FILES} 

${PROGRAM_DIR}/%: %
	${INSTALL_COMMAND} $? $@

dist: 
	mkdir coverage
	cp ${PROGRAM_FILES} coverage
	cp -r examples coverage
	cp README.txt coverage
	tar zcf coverage.tgz coverage
	rm -r coverage
