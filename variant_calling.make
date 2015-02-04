SHELL=/bin/bash

#  Created by alolex on 2/2/15.
#
#  A makefile to run the variant calling steps for BAM files that have been preprocessed by PICARD.
#  The directory structure from the picard_preprocess.make file is required for this script to run correctly.
#  Specifically the picard_processed/3_addgrps folder must exist with processed bam files.


BAMDIR=/home/alolex/data/isilon_tcga/BRCA/WXS/picard_processed/3_addgrps
VCFDIR=/home/alolex/data/isilon_tcga/BRCA/WXS/platypus_vcf_files
BAMFILES=processed_bam_ids.txt

all: $(BAMDIR) $(BAMFILES) $(VCFDIR) platypus

test: $(BAMDIR) $(BAMFILES) $(VCFDIR)

bamdir: $(BAMDIR)

$(BAMDIR): 
	if [ ! -d $@ ]; then echo "BAM Directory, "$(BAMDIR)" does not exist."; else echo "BAM Directory, "$(BAMDIR)", Found! ..."; fi 

$(VCFDIR):
	if [ -d $@ ]; then echo "VCF Directory, "$(VCFDIR)", Found! ..."; \
	else \
	    echo "VCF Directory, "$(VCFDIR)" does not exist, creating ..."; \
	    mkdir $(VCFDIR) ; \
	fi

$(BAMFILES): $(BAMDIR) 
	if [ -e $@ ]; then echo "List of BAM files, "$@", Found! ..." ; \
	else \
	    echo "List of BAM files does not exist, creating "$(BAMFILES)" from files in "$(BAMDIR)" ... " ; \
	    touch $(BAMFILES) ; \
	    ls $(BAMDIR)/*.bam > $(BAMFILE) ; \
	fi

### Running Platypus Variant Calling
platypus: $(VCFDIR) $(BAMDIR) $(BAMFILES)
	cat $(BAMFILES) | while read bamfile ; \
	do \
	    filebase=`basename $$bamfile .addgrps.bam` ; \
	    input=$(BAMDIR)"/"$$filebase".addgrps.bam" ; \
	    output=$(VCFDIR)"/"$$filebase".platypusVariantCalls.vcf" ; \
	    logout=$(VCFDIR)"/"$$filebase".platypusVariantCalls.log" ; \
	    if [ ! -e $$output ] && [ ! -e $$output.gz ]; \
	    then \
		echo "Starting Platypus on `date` ... "$$filebase".bam" ; \
		cmd="python ~/bin/Platypus_0.7.9.1/Platypus.py callVariants --bamFiles="$$input" --refFile=/data/refGenomes/human/GRCh37-lite/GRCh37-lite.fa --output="$$output" --nCPU=6 --logFileName="$$logout ; \
		eval $$cmd ; \
		echo "Finished Platypus on `date` ... "$$filebase".bam" ; \
	    else \
		echo "Found Platypus Output, skipping ... "$$output ; \
	    fi \
	done
