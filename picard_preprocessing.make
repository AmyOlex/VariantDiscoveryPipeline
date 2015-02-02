SHELL=/bin/bash

#  Created by alolex on 2/2/15.
#
#  A makefile to run the picard preprocessing steps for TCGA bam files


BAMDIR=/home/alolex/data/isilon_tcga/BRCA/WXS
BAMFILES=$(BAMDIR)/analysis_ids.txt

all: $(BAMDIR) $(BAMFILES) picard_processed sorted dedup addgrps

$(BAMDIR): 
	if [ ! -d $@ ]; then echo "BAM Directory does not exist."; fi 

$(BAMFILES): 
	if [ ! -e $@ ]; then echo "List of BAM files to processes, $@, does not exist."; fi

### Creates the directory structure within the main BAM file folder.
picard_processed: $(BAMDIR)
	cd $(BAMDIR) ; \
	if [ ! -d $@ ] ; then mkdir $@ ; fi ; \
	cd $@ ; \
	if [ ! -d "1_sorted" ]; then mkdir "1_sorted"; echo "Created $@/1_sorted folder."; else echo "$@/1_sorted folder already exists."; fi; \
	if [ ! -d "2_dedup" ]; then mkdir "2_dedup"; echo "Created $@/2_dedup folder."; else echo "$@/2_dedup folder already exists."; fi; \
	if [ ! -d "3_addgrps" ]; then mkdir "3_addgrps"; echo "Created $@/3_addgrps folder."; else echo "$@/3_addgrps folder already exists."; fi; \
	cd ../ ;

### Runs PICARD Tools Sorting on BAM files
sorted: $(BAMFILES)
	cat $(BAMFILES) | while read dir bamfile ; \
	do \
	   if [ ! -d $(BAMDIR)"/"$$dir ] ; then echo $$dir" does not exist." ; \
	   else \
		echo "FOUND DIRECTORY ... Processing ... "$$dir ; \
		filebase=`basename $$bamfile .bam` ; \
		baifile=$$bamfile".bai" ; \
		input=$(BAMDIR)"/"$$dir"/"$$bamfile ; \
		output=$(BAMDIR)"/picard_processed/1_sorted/"$$filebase"."$@".bam" ; \
		if [ -e $$output ] ; then echo "Sorted File Exists, skipping ... "$$output ; \
		else \
		    cmd="java -Xmx8g -Djava.io.tmpdir=/home/alolex/tmp/scratch -jar /opt/picard-tools-1.115/SortSam.jar INPUT="$$input" OUTPUT="$$output" SORT_ORDER=coordinate VALIDATION_STRINGENCY=LENIENT TMP_DIR=/home/alolex/tmp/scratch" ; \
    		    echo "Executing PICARD Sorting for "$$bamfile" at "`date`" ... " ; \
		    eval $$cmd ; \
		    echo "Done PICARD Sorting at "`date` ; \
		fi ; \
	   fi ; \
	done

### Runs PICARD Tools Mark Duplicates on BAM files
dedup: $(BAMFILES) sorted
	cat $(BAMFILES) | while read dir bamfile ; \
	do \
	   filebase=`basename $$bamfile .bam` ; \
	   input=$(BAMDIR)"/"$$dir"/"$$bamfile"/picard_processed/1_sorted/"$$filebase".sorted.bam" ; \
	   output=$(BAMDIR)"/picard_processed/2_dedup/"$$filebase"."$@".bam" ; \
	   if [ -e $$output ] ; then echo "Marked Duplicates File Exists, skipping ... "$$output ; \
	   else \
		cmd="java -Xmx8g -Djava.io.tmpdir=/home/alolex/tmp/scratch -jar /opt/picard-tools-1.115/MarkDuplicates.jar INPUT="$$input" OUTPUT="$$output" METRICS_FILE=metrics VALIDATION_STRINGENCY=LENIENT TMP_DIR=/home/alolex/tmp/scratch" ; \
		echo "Executing PICARD Mark Duplicates for "$$bamfile" at "`date`" ... "$$cmd ; \
		eval $$cmd ; \
		echo "Done PICARD Mark Duplicates at "`date` ; \
	   fi ; \
	done

### Runs PICARD Tools Add and Remove Groups on BAM files
addgrps: $(BAMFILES) dedup
	cat $(BAMFILES) | while read dir bamfile ; \
	do \
	   filebase=`basename $$bamfile .bam` ; \
	   input=$(BAMDIR)"/"$$dir"/"$$bamfile"/picard_processed/2_dedup/"$$filebase".dedup.bam" ; \
	   output=$(BAMDIR)"/picard_processed/3_addgrps/"$$filebase"."$@".bam" ; \
	   if [ -e $$output ] ; then echo "Add and Replace Read Groups File Exists, skipping ... "$$output ; \
	   else \
		cmd1="java -Xmx8g -Djava.io.tmpdir=/home/alolex/tmp/scratch -jar /opt/picard-tools-1.115/AddOrReplaceReadGroups.jar INPUT="$$input" OUTPUT="$$output" VALIDATION_STRINGENCY=LENIENT RGID=group1 RGLB=lib1 RGPL=illumina RGPU=unit1 RGSM=sample1 TMP_DIR=/home/alolex/tmp/scratch" ; \
		cmd2="java -Xmx8g -Djava.io.tmpdir=/home/alolex/tmp/scratch -jar /opt/picard-tools-1.115/BuildBamIndex.jar INPUT="$$output" VALIDATION_STRINGENCY=LENIENT TMP_DIR=/home/alolex/tmp/scratch" ; \
		echo "Executing PICARD Add and Replace Read Groups for "$$bamfile" at "`date`" ... " ; \
		eval $$cmd1 ; \
		eval $$cmd2 ; \
		echo "Done PICARD Add and Replace Read Groups at "`date` ; \
	   fi ; \
	done
