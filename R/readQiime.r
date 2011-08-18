######################################################################################
#' Import function to read output from the QIIME pipeline.
#'
#' QIIME produces several files that can be analyzed in the phyloseq-package, 
#' including especially an OTU file that typically contains both OTU-abundance
#' and taxonomic identity information. The map-file is also an important input
#' to QIIME that can also indicate sample covariates, converted naturally to the 
#' sampleMap component data type in phyloseq-package.  
#' 
#' Add reference to the QIIME pipeline.
#'
#' @param otufilename A character string indicating the file location of the OTU file.
#' The combined OTU abundance and taxonomic identification file,
#' tab-delimited, as produced by QIIME under default output settings.
#'  Default value is \code{NULL}. 
#' 
#' @param mapfilename The QIIME map file required for processing pyrosequencing tags
#' in QIIME as well as some of the post-clustering analysis. This is a required
#' input file for running QIIME. Its strict formatting specification should be
#' followed for correct parsing by this function.
#'  Default value is \code{NULL}. 
#'
#' @param treefilename A phylogenetic tree in nexus format. For the QIIME pipeline
#'  this is typically a tree of the representative 16S rRNA sequences from each OTU
#'  cluster, with the number of leaves/tips equal to the number of taxa/species/OTUs.
#'  Default value is \code{NULL}. 
#'
#' @param biotaxonomy A character vector indicating the name of each taxonomic level
#'  in the taxonomy-portion of the otu-file, which may not specify these levels 
#'  explicitly.
#'  Default value is \code{NULL}. 
#'
#' @return The class of the object returned by \code{readQiime} depends upon which 
#' filenames are provided. The most comprehensive class is chosen automatically,
#' based on the input files listed as arguments. \code{readQiime()} will return 
#' nothing.
#'
#' @seealso phyloseq_merge phyloseq read.table read.nexus readNexus
#'
#' @importFrom ape read.nexus
#' @export
#' @examples #
readQiime = function(otufilename=NULL, mapfilename=NULL,
	treefilename=NULL, biotaxonomy=NULL){

	# initialize the argument-list for phyloseq. Start empty.
	argumentlist <- list()
		
	if( is.null(biotaxonomy) ){
	 	biotaxonomy=c("Root", "Domain", "Phylum", "Class", "Order",
		 	"Family", "Genus", "Species", "Strain")
	 }

	if( !is.null(mapfilename) ){	
		# Process mapfile. Name rows as samples.
		QiimeMap <- read.table(file=mapfilename, header=TRUE,
			sep="\t", comment.char="")
		rownames(QiimeMap) <- as.character(QiimeMap[,1])
		QiimeMap <- sampleMap(QiimeMap)
		argumentlist <- c(argumentlist, list(QiimeMap))
	}

	if( !is.null(otufilename) ){
		##########################################
		# Process otu table. "otuID" convention
		# specific to Qiime. Might need to be abstracted.
		##########################################
		# first read the table. Skip line 1, avoid comment character "#"
		otutab <- read.table(file=otufilename, header=TRUE,
			sep="\t", comment.char="", skip=1)
		# name the rows by otuID
		rownames(otutab) <- paste("otuID", as.character(otutab[,1]), sep="_")
		# remove the otuID column
		otutab <- otutab[, 2:ncol(otutab)]
	
		##########################################
		# Process/separate the lineage information
		##########################################
		splitaxa <- strsplit(as.character(otutab[,"Consensus.Lineage"]),";")
		taxtab   <- matrix(NA, nrow(otutab), length(biotaxonomy))
		colnames(taxtab) <- biotaxonomy
		# If present, place the taxonomy labels in matrix
		# starting on the left column (root)
		for( i in 1:nrow(otutab) ){
			taxtab[i, 1:length(splitaxa[[i]])] <- splitaxa[[i]]
		}
		rownames(taxtab) <- rownames(otutab)
		taxtab <- taxTab( as.matrix(taxtab) )
		
		# Remove taxonomy column from otutab
		otutab = otutab[, which(colnames(otutab)!="Consensus.Lineage")]
		# convert to matrix of integers, and then otuTable object
		otutab = otuTable( as.matrix(otutab), speciesAreRows=TRUE )
		
		# the otuTable element must be named "object" for phyloseq() method.
		argumentlist <- c(argumentlist, list(object=otutab), list(taxtab) )
	}

	if( !is.null(treefilename) ){
		tree         <- read.nexus(treefilename)
		argumentlist <- c(argumentlist, list(tree) )
	}

	do.call("phyloseq", argumentlist)
}
######################################################################################