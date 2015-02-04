SHELL=/bin/bash

#  Created by alolex on 2/2/15.
#
#  A makefile to run the variant calling steps for BAM files that have been preprocessed by PICARD.
#  The directory structure from the picard_preprocess.make file is required for this script to run correctly.
#  Specifically the picard_processed/3_addgrps folder must exist with processed bam files.


VCFDIR=/home/alolex/data/isilon_tcga/BRCA/WXS/platypus_vcf_files
VCFFILES=vcf_files_to_merge_cohort30.txt
FORMATTEDVCF=formatted_vcf_files
MERGEDFILE=cohort30.bcfmerge.vcf
PLINKDIR=plink_cohort30
PHENOFILE=patient_alt_phenotype.txt
RECODE=patient_recode.txt
EXT=platypusVariantCalls.vcf

all: $(VCFDIR) vcfzip $(RECODE) vcfrename vcfindex $(VCFFILES) $(PLINKDIR) vcfmerge vcffilter vcftoplink $(PHENOFILE) runplink

checkfiles: $(VCFDIR) $(RECODE) $(PLINKDIR) $(PHENOFILE)

$(VCFDIR):
	if [ ! -d $@ ]; then echo "VCF Directory, "$(VCFDIR)", does not exist! ..."; fi \

### Finds all files that have not been zipped and zips them.
vcfzip: $(VCFDIR)
	numfiles=$(shell ls $(VCFDIR) | grep -F ".platypus.VariantCalls.vcf"$ | wc -l); \
	if [ $$numfiles != 0 ] ; \
	then \
	    tozip=$(shell ls $(VCFDIR)/*.platypusVariantCalls.vcf) ; \
	    for f in $$tozip; \
	    do \
	        bgzip $$f ; \
	    done ; \
	else \
	    echo "No VCF files to zip." ; \
	fi

### Looks for the recode file
$(RECODE):
	if [ ! -e $@ ]; then echo "Recode file "$@" does not exist!" ; fi ;

### Formats vcf files for plink analysis by adding sample names
vcfrename: $(VCFDIR) $(RECODE) vcfzip
	torename=`ls $(VCFDIR)/*.platypusVariantCalls.vcf.gz` ; \
	for f in $$torename ; \
	do \
	    filebase=`basename $$f .platypusVariantCalls.vcf.gz` ; \
	    touch sample.rename ; \
	    echo "`grep $$filebase $(RECODE) | cut -f 4`" > sample.rename ; \
	    bgzip sample.rename ; \
	    ~/bin/bcftools/bcftools reheader -s sample.rename.gz $$f > $$f.tmp ; \
	    mv $$f.tmp $$f ; \
	    rm sample.rename.gz ; \
	done \

### Indexes the formatted vcf files after they have had samples renamed.
vcfindex: vcfrename
	toindex=`ls $(VCFDIR)*.platypusVariantCalls.vcf.gz` ; \
	for f in $$toindex ; \
	do \
	    if [ -e $$f ]; \
	    then \
		rm $$f ; \
	    fi ; \
	    tabix -p vcf $$f ; \
	done

### Creates the list of vcf files to merge, but they have to be zipped, samples renamed and indexed first.
$(VCFFILES): vcfzip vcfrename vcfindex
	if [ -e $@ ]; then rm $@ ; fi ; \
	touch $(VCFFILES) ; \
	ls $(VCFDIR)/*.platypusVariantCalls.vcf.gz > $(VCFFILES) ;

$(PLINKDIR):
	if [ ! -d $@ ]; then mkdir $@; fi

vcfmerge: $(VCFFILES) $(PLINKDIR)
	~/bin/bcftools/bcftools merge -o $(PLINKDIR)/$(MERGEFILE) -O v `cat $(VCFFILES)`

vcffilter: vcfmerge
	infile=$(PLINKDIR)/$(MERGEFILE) ; \
	~/bin/vcftools_0.1.12b/bin/vcftools --vcf $$infile --out $$infile.SNPS.mainChrs --remove-indels --recode --chr 1 --chr 2 --chr 3 --chr 4 --chr 5 --chr 6 --chr 7 --chr 8 --chr 9 --chr 10 --chr 11 --chr 12 --chr 13 --chr 14 --chr 15 --chr 16 --chr 17 --chr 18 --chr 19 --chr 20 --chr 21 --chr 22 --chr X --chr Y 

vcftoplink: vcffilter
	infile=$(PLINKDIR)/$(MERGEFILE).SNPS.mainChrs ; \
	/home/alolex/bin/vcftools_0.1.12b/bin/vcftools --vcf $$infile.recode.vcf --plink --out $$infile.recode

$(PHENOFILE):
	if [ ! -e $@ ]; then echo "Phenotype file, "$@", does not exist!" ; fi \

runplink: vcftoplink $(PHENOFILE)
	infile=$(PLINKDIR)/$(MERGEFILE).SNPS.mainChrs.recode ; \
	plink --file $$infile --noweb --pheno $(PHENOFILE) --geno 0.1 --filter-cases --recodeA --max-maf 0.05 --out $$infile.tumor_rare --nonfounders ; \
	plink --file $$infile --noweb --pheno $(PHENOFILE) --geno 0.1 --filter-cases --recodeA --maf 0.05 --out $$infile.tumor_common --nonfounders ; \
	plink --file $$infile --noweb --pheno $(PHENOFILE) --geno 0.1 --filter-controls --recodeA --max-maf 0.05 --out $$infile.normal_rare --nonfounders ; \
	plink --file $$infile --noweb --pheno $(PHENOFILE) --geno 0.1 --filter-controls --recodeA --maf 0.05 --out $$infile.normal_common --nonfounders ;

