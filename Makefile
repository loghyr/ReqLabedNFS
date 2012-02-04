# Copyright (C) The IETF Trust (2012)
#

YEAR=`date +%Y`
MONTH=`date +%B`
DAY=`date +%d`
PREVVERS=00
VERS=00
BASEDOC=draft-quigley-nfsv4-labreqs

autogen/%.xml : %.x
	@mkdir -p autogen
	@rm -f $@.tmp $@
	@cat $@.tmp | sed 's/^\%//' | sed 's/</\&lt;/g'| \
	awk ' \
		BEGIN	{ print "<figure>"; print" <artwork>"; } \
			{ print $0 ; } \
		END	{ print " </artwork>"; print"</figure>" ; } ' \
	| expand > $@
	@rm -f $@.tmp

all: html txt

#
# Build the stuff needed to ensure integrity of document.
common: testx html

txt: $(BASEDOC)-$(VERS).txt

html: $(BASEDOC)-$(VERS).html

nr: $(BASEDOC)-$(VERS).nr

xml: $(BASEDOC)-$(VERS).xml

clobber:
	$(RM) $(BASEDOC)-$(VERS).txt \
		$(BASEDOC)-$(VERS).html \
		$(BASEDOC)-$(VERS).nr
	export SPECVERS := $(VERS)
	export VERS := $(VERS)

clean:
	rm -f $(AUTOGEN)
	rm -rf autogen
	rm -f $(BASEDOC)-$(VERS).xml
	rm -rf draft-$(VERS)
	rm -f draft-$(VERS).tar.gz
	rm -rf testx.d
	rm -rf draft-tmp.xml

# Parallel All
pall: 
	$(MAKE) xml
	( $(MAKE) txt ; echo .txt done ) & \
	( $(MAKE) html ; echo .html done ) & \
	wait

$(BASEDOC)-$(VERS).txt: $(BASEDOC)-$(VERS).xml
	rm -f $@ draft-tmp.txt
	sh xml2rfc_wrapper.sh $(BASEDOC)-$(VERS).xml draft-tmp.txt
	mv draft-tmp.txt $@

$(BASEDOC)-$(VERS).html: $(BASEDOC)-$(VERS).xml
	rm -f $@ draft-tmp.html
	sh xml2rfc_wrapper.sh $(BASEDOC)-$(VERS).xml draft-tmp.html
	mv draft-tmp.html $@

$(BASEDOC)-$(VERS).nr: $(BASEDOC)-$(VERS).xml
	rm -f $@ draft-tmp.nr
	sh xml2rfc_wrapper.sh $(BASEDOC)-$(VERS).xml $@.tmp
	mv draft-tmp.nr $@

labreqs_front_autogen.xml: labreqs_front.xml Makefile
	sed -e s/DAYVAR/${DAY}/g -e s/MONTHVAR/${MONTH}/g -e s/YEARVAR/${YEAR}/g < labreqs_front.xml > labreqs_front_autogen.xml

labreqs_rfc_start_autogen.xml: labreqs_rfc_start.xml Makefile
	sed -e s/VERSIONVAR/${VERS}/g < labreqs_rfc_start.xml > labreqs_rfc_start_autogen.xml

AUTOGEN =	\
		labreqs_front_autogen.xml \
		labreqs_rfc_start_autogen.xml

START_PREGEN = labreqs_rfc_start.xml
START=	labreqs_rfc_start_autogen.xml
END=	labreqs_rfc_end.xml

FRONT_PREGEN = labreqs_front.xml

IDXMLSRC_BASE = \
	labreqs_middle_start.xml \
	labreqs_middle_introduction.xml \
	labreqs_middle_requirements.xml \
	labreqs_middle_usecases.xml \
	labreqs_iana_considerations.xml \
	labreqs_middle_end.xml \
	labreqs_back_front.xml \
	labreqs_back_references.xml \
	labreqs_back_acks.xml \
	labreqs_back_back.xml

IDCONTENTS = labreqs_front_autogen.xml $(IDXMLSRC_BASE)

IDXMLSRC = labreqs_front.xml $(IDXMLSRC_BASE)

draft-tmp.xml: $(START) Makefile $(END)
		rm -f $@ $@.tmp
		cp $(START) $@.tmp
		chmod +w $@.tmp
		for i in $(IDCONTENTS) ; do echo '<?rfc include="'$$i'"?>' >> $@.tmp ; done
		cat $(END) >> $@.tmp
		mv $@.tmp $@

$(BASEDOC)-$(VERS).xml: draft-tmp.xml $(IDCONTENTS) $(AUTOGEN)
		rm -f $@
		cp draft-tmp.xml $@

genhtml: Makefile gendraft html txt draft-$(VERS).tar
	./gendraft draft-$(PREVVERS) \
		$(BASEDOC)-$(PREVVERS).txt \
		draft-$(VERS) \
		$(BASEDOC)-$(VERS).txt \
		$(BASEDOC)-$(VERS).html \
		$(BASEDOC)-dot-x-04.txt \
		$(BASEDOC)-dot-x-05.txt \
		draft-$(VERS).tar.gz

testx: 
	rm -rf testx.d
	mkdir testx.d
	( cd testx.d ; \
		rpcgen -a labelednfs.x ; \
		$(MAKE) -f make* )

spellcheck: $(IDXMLSRC)
	for f in $(IDXMLSRC); do echo "Spell Check of $$f"; spell +dictionary.txt $$f; done

AUXFILES = \
	dictionary.txt \
	gendraft \
	Makefile \
	errortbl \
	rfcdiff \
	xml2rfc_wrapper.sh \
	xml2rfc

DRAFTFILES = \
	$(BASEDOC)-$(VERS).txt \
	$(BASEDOC)-$(VERS).html \
	$(BASEDOC)-$(VERS).xml

draft-$(VERS).tar: $(IDCONTENTS) $(START_PREGEN) $(FRONT_PREGEN) $(AUXFILES) $(DRAFTFILES)
	rm -f draft-$(VERS).tar.gz
	tar -cvf draft-$(VERS).tar \
		$(START_PREGEN) \
		$(END) \
		$(FRONT_PREGEN) \
		$(IDCONTENTS) \
		$(AUXFILES) \
		$(DRAFTFILES) \
		gzip draft-$(VERS).tar
