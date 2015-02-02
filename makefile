SHELL=/bin/bash

#  Created by alolex on 2/2/15.
#
#  A makefile to run the picard preprocessing steps for TCGA bam files


BAMDIR=/home/alolex/data/isilon_tcga/BRCA/WXS
#BAMDIR="./test"
BAMFILES=$(BAMDIR)/analysis_ids.txt
semi=;


all: $(BAMDIR) picard_processed

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
	$(shell cat $(BAMFILES) | while read dir bamfile $$semi \
	do \
	   if [ ! -d $$dir ] $$semi then echo "$$dir does not exist." $$semi \
	   else \
		echo "FOUND DIRECTORY ... Processing ... $$dir" $$semi \
		filebase=`basename $$bamfile .bam` $$semi \
		baifile=`echo $$bamfile.bai` $$semi \		
		input=`echo $(BAMDIR)$$dir/$$bamfile` $$semi \
		output=`echo $(BAMDIR)/picard_processed/1_sorted/$$filebase.$@.bam` $$semi \
		if [ -e $$output ]; then echo "File Exists, skipping ... $$output" $$semi \
		else \
		    cmd=`echo "java -Xmx8g -Djava.io.tmpdir=/home/alolex/tmp/scratch -jar /opt/picard-tools-1.115/SortSam.jar INPUT=$$input OUTPUT=$$output SORT_ORDER=coordinate VALIDATION_STRINGENCY=LENIENT TMP_DIR=/home/alolex/tmp/scratch"` $$semi \
    		    echo "Executing PICARD Sorting at `date` ... $$cmd" $$semi \
		    #eval $$cmd $$semi \
		    echo $$cmd $$semi \
		    echo "Done PICARD Sorting at `date` " $$semi \
		fi $$semi \
	
	   fi $$semi \
	done )	
