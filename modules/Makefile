# modules
DHTTPCLIENT=https://github.com/Bystroushaak/DHTTPClient.git
DHTMLPARSER=https://github.com/Bystroushaak/DHTMLParser.git
DFAKEMAILER=https://github.com/Bystroushaak/DFakeMailer.git
UTF_TOOLS  =https://github.com/Bystroushaak/utf_tools.git
CONF_PARSER=https://github.com/Bystroushaak/ConfParser.git

DC     = dmd
DFLAGS = -c -O -release

SRCS = $(wildcard *.d)
OBJS = $(SRCS:.d=.o)

all: download $(OBJS)

%.o: %.d
	$(DC) $(DFLAGS) $? -of$@

.PHONY: all
.PHONY: download
.PHONY: clean
.PHONY: distclean

download:
	@# check if git is installed
	@if [ `type git > /dev/null 2>&1 && echo 0 || echo 1` -eq 1 ]; then \
		echo; \
		echo "You have to install git (http://git-scm.com/) first!"; \
		echo; \
		exit 1; \
	fi
	
	@if [ `ls *.d | wc -l` -eq 0 ]; then \
		echo "Downloading modules:"; \
		git clone $(DHTTPCLIENT); \
		git clone $(DHTMLPARSER); \
		git clone $(DFAKEMAILER); \
		(cd DFakeMailer; git checkout nslookup; cd ..); \
		git clone $(UTF_TOOLS); \
		git clone $(CONF_PARSER); \
		mv */*.d ./; \
		rm -fr */; \
		echo; \
		echo "Modules downloaded"; \
		echo; \
		exit 0; \
	else\
		echo "Nothing to download!"; \
		exit 0; \
	fi

clean:
	-rm *.o

distclean: clean
	-rm *.d
