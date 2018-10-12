/*want to get a copy of things published in the federal register?
http//www.federalregister.gov/developers/api/v1

This code uses the federal register api to download Federal register publications into a stata dataset. The actual publication is put into a strL in the dataset, along with
some other metadata. 
Right now, this pulls in anything that was published between Jan 1, 2006 and Dec 31, 2018 and contains the phrase "Atlantic Herring"

 */


version 15.1
#delimit;
pause on;

global my_wd "/home/mlee/Documents/projects/federal_register_scraper/"
cd "$my_wd";
local species "Atlantic%2BHerring";
local end_pub_date "2018-12-31";
local start_pub_date "2006-01-01";


local conditions "conditions%5Bterm%5D=`species'&conditions%5Bpublication_date%5D%5Bgte%5D=`start_pub_date'&conditions%5Bpublication_date%5D%5Blte%5D=`end_pub_date'";
local agencies "conditions%5Bagencies%5D%5B%5D=commerce-department&conditions%5Bagencies%5D%5B%5D=national-oceanic-and-atmospheric-administration";


local fieldlist "fields%5B%5D=page_length&fields%5B%5D=raw_text_url&fields%5B%5D=agency_names&fields%5B%5D=cfr_references&fields%5B%5D=citation&fields%5B%5D=docket_ids&fields%5B%5D=document_number&fields%5B%5D=regulation_id_numbers&fields%5B%5D=start_page&fields%5B%5D=title&order=newest&fields%5B%5D=type";

/* There is a max of 1000 entries per page from the API. So what we'll do is pull the first page. If there are 1000 observations, we'll pull the second page.  */
local numpages=1;


local obscount=1000;


while `obscount'==1000{ ;
	tempfile aquery;
	local querylist`"`querylist'"`aquery'" "'  ;
	clear;
	import delimited "https://www.federalregister.gov/api/v1/documents.csv?&per_page=1000&page=`numpages'&`fieldlist'&`conditions'&`agencies'";
	quietly save `aquery';
	qui count;
	local obscount=r(N);
	local ++numpages;
};
dsconcat `querylist';

/* */



/*I'm just keeping a few of them, because there are sooo many. 
keep if inlist(type,"Notice","Uncategorized Document");*/


keep if _n<=20;


/* THIS LINE downloads the "text versions" of your selected regulations into a stata variable*/
gen strL mydoc=fileread(raw_text_url);

/* Search inside that string
 Looks like there are no hyphens for line-breaks when words run over the end of a line.
*/

gen lenfest=strmatch(mydoc,"*Lenfest*");
replace lenfest=1 if strmatch(mydoc,"*lenfest*");

gen control_rule=strmatch(mydoc,"*control rule*")
replace control_rule=1 if strmatch(mydoc,"ABC rule*")
replace control_rule=1 if strmatch(mydoc,"ABC control*")

gen ecosystem=strmatch(mydoc,"*ecosystem concerns*")
replace ecosystem=1 if strmatch(mydoc,"*ecosystem considerations*")

gen forage= strmatch(mydoc,"*forage in the ecosystem*")
replace forage=1 if strmatch(mydoc,"*role of forage*")


/**********************************************************************************************************************************************/
/**********************************************************************************************************************************************/
/**************This code will write all of your files to txt documents with filename corresponding to the FR citation *************************/

/*start comment out 
quietly count;
local myobs =r(N);


egen citation2=sieve(citation), omit(" ");
gen myout=.;
quietly forvalues i=1/`myobs'{;
local savefilename=citation2[`i'];

replace myout=filewrite("`savefilename'.txt",mydoc[`i']);
};
end comment out */

/**************End of the code to write all of your files to txt documents with filename corresponding to the FR citation *************************/
/**********************************************************************************************************************************************/
/**********************************************************************************************************************************************/

