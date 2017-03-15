'''''''''''''''''''''''''''''''''''''''''''''''''
''''''''''MacroTrans'''''''''' 	Version 1.0 - Last Revised 17 May 2015
'''''''''''''''''''''''''''''''''''''''''''''''''

setmaxerrs 0
'test data for Stock and Watson dataset
'wfcreate m 1960m1 2003m12
'import(resize) C:\<yourpath>\sims1.xls range=Sheet1 @freq M 1960M01 @smpl @all
'd date
'group macrotranstest * 
'macrotranstest.drop resid
'show macrotranstest

logmode +addin

%type = @getthistype
if %type = "NONE" then
	@uiprompt("No object found, please open a group object.")
	stop
endif
%freq = @pagefreq
if %freq<>"Q" then
	if %freq<>"M" then
		@uiprompt("This add-in is only designed for monthly or quarterly workfiles")
		stop
	endif	
endif
if %type <> "GROUP" then
	@uiprompt("This is not a group object.")
	stop
endif
%wfname = @wfname
if %wfname="" then
	@uiprompt("No workfile is open")
	stop
endif
if @ispanel = 1 then
	@uiprompt("The procedure is not designed for panel data")
	stop
endif
%inputgroup = _this.@name
if %inputgroup = "" then  'this can occur if the group is untitled.
	%inputgroup = "_this"
endif	

!sig = 1
!sigval=0.05
!maxdiffs=2

%nameofgroup=@getnextname("nameofgroup")
string {%nameofgroup} = "Please enter the name of your group here:"
%nameofsuffix=@getnextname("nameofsuffix")
string {%nameofsuffix} = "Name of Suffix on Output"
%upperboundonrate=@getnextname("upperboundonrate")	'all objects are created with the @getnextname command.
string {%upperboundonrate} = "Please enter the upper bound on the rate:"
%urootmenu=@getnextname("urootmenu")
string {%urootmenu} = "ADF KPSS"
%urootPrompt=@getnextname("urootPrompt")
string {%urootPrompt} = "Choose Unit Root Test"
%seasonalmenu=@getnextname("seasonalmenu")
string {%seasonalmenu} = "X12 X13"
%seasonalPrompt=@getnextname("seasonalPrompt")
string {%seasonalPrompt} = "Choose Seasonal Adjustment Technique"
!seasonalnumber= 2
!urootnumber= 2
!standardize=0
!groupout=0
!tableout=0
!standardize= @hasoption("standardize")
!groupout= @hasoption("groupout")
!tableout= @hasoption("tableout")
if @hasoption("suffix") then
else
	%suffix_out = "_t"
endif
if @len(@option(1)) then
	%temp = @equaloption("rate")
	if @len(%temp) then
		%rate_max = %temp
	endif
	%temp = @equaloption("suffix")
	if @len(%temp) then
		%suffix_out = %temp
	endif	
	!meanzerounitvariance= @hasoption("m")
	%temp = @equaloption("seas")
	STRING tempseas = %temp
	if tempseas="X12" then
		!seasonalnumber= 1
	endif
	if tempseas="X13" then
		!seasonalnumber= 2
	endif
	d tempseas
	
	%temp = @equaloption("unit")
	STRING tempuroot = %temp
	if tempuroot="adf" then
		!urootnumber= 1
	endif
	if tempuroot="kpss" then
		!urootnumber= 2
	endif
	d tempuroot
else
	%rate_max1=@getnextname("rate_max1")
	%rate_max = "50"
	!seasonalnumber=2
	!urootnumber=2
	%suffix_out = "_t"
	!result = @uidialog("Caption", "MacroTrans Menu", "Edit", %inputgroup, {%nameofgroup}, 21,"Edit", %rate_max, {%upperboundonrate},"Edit",%suffix_out, {%nameofsuffix} , 21,"Radio", !urootnumber, {%urootPrompt}, {%urootmenu}, "Radio", !seasonalnumber, {%seasonalPrompt}, {%seasonalmenu},"Check", !standardize, "Do you want to standardize?","Check", !tableout, "Output diagnostic table??","Check", !groupout, "Create a group with all output?")	
	if !result = -1 then
		delete {%nameofgroup} {%nameofsuffix} {%urootPrompt} {%urootmenu} {%seasonalPrompt} {%seasonalmenu} {%upperboundonrate}
		stop
	endif
endif
if @val(%rate_max) <=0 then ' we need a rate which is greater than zero
	@uiprompt("Error: The maximum rate must be greater than 0")
	delete {%nameofgroup} {%nameofsuffix} {%urootPrompt} {%urootmenu} {%seasonalPrompt} {%seasonalmenu} {%upperboundonrate}
	stop 
endif 

scalar testrate = @val(%rate_max)

if @isna(testrate) then
	@uiprompt("The rate boundary must be defined")
	delete {%nameofgroup} {%nameofsuffix} {%urootPrompt} {%urootmenu} {%seasonalPrompt} {%seasonalmenu} {%upperboundonrate}
	stop 
endif
%temporary = %inputgroup+%suffix_out
if @isobject(%temporary) then
	@uiprompt("Error: This name for group outputs already exists in your workfile")
	delete {%nameofgroup} {%nameofsuffix} {%rate_max} {%urootPrompt} {%urootmenu} {%seasonalPrompt} {%seasonalmenu} {%upperboundonrate}
	stop 
endif

for !z = 1 to {%inputgroup}.@count
	!numberseries={%inputgroup}.@count
	%name = {%inputgroup}.@seriesname(!z)
	if @nas({%name})>0 then
		@uiprompt("Error: NA values not allowed in this routine")
		delete {%nameofgroup} {%nameofsuffix} {%urootPrompt} {%urootmenu} {%seasonalPrompt} {%seasonalmenu} {%upperboundonrate}
		stop
	endif
	statusline !z
next

if !groupout = 1 then
	%holdertab= %inputgroup+%suffix_out
	group {%holdertab}
endif
if 	!tableout= 1 then
	%tableoutput=@getnextname("macrotrans_table")
	table {%tableoutput}
endif

!percentseaserrors=0
!percentunit=0
!percentpercent=0	
!percentlogged=0
setmaxerrs 2
seterrcount 0
for !a = 1 to {%inputgroup}.@count
	!nopc=0
	!nonstat=0
	!logged=0
	!nonpositive=0
	!outraterange=0
	%temp={%inputgroup}.@seriesname(!a)
	%temporary = %temp+%suffix_out
	if @isobject(%temporary) then
		@uiprompt("Error: This name (suffix) for a series transformation outputs already exists in your workfile")
		delete {%nameofgroup} {%nameofsuffix} {%urootPrompt} {%urootmenu} {%seasonalPrompt} {%seasonalmenu} {%upperboundonrate}
		stop 
	endif
	if !seasonalnumber>0 then
		if !seasonalnumber=2 then
			%seastest="x13"
		endif
		if !seasonalnumber=1 then
			%seastest="x12"
		endif
		seterrcount 0
		{%temp}.{%seastest}
		if @errorcount>0 then
			!percentseaserrors=!percentseaserrors+1
			genr {%temporary}={%temp}
			else
			if !seasonalnumber=2 then
				rename {%temp}_d11 {%temporary}
			endif
			if !seasonalnumber=1 then
				rename {%temp}_sa {%temporary}
			endif
		endif
	else 
		genr {%temporary}={%temp}
	endif
	for !p=1 to @obs({%temporary})
		if {%temporary}(!p)<=0 then
			!nonpositive=1
		endif
		if {%temporary}(!p)>testrate then
			!outraterange=1
		endif
	next
	if !nonpositive<>1 then
		if !outraterange=1 then
			genr {%temporary}1=log({%temporary})
			d {%temporary}
			rename {%temporary}1 {%temporary}
			!percentlogged=!percentlogged+1
			!logged=1
		endif
	endif
	for !d = 1 to !maxdiffs
		!nonstat=0
		!nopc=0
		if !urootnumber=2 then
			freeze({%temporary}_table) {%temporary}.uroot(kpss)
			!lm = @val({%temporary}_table(7,5))	
			!crit = @val({%temporary}_table(8+!sig,5))
			d {%temporary}_table
			if !lm>!crit then
				if !d=1 then
					!percentunit=!percentunit+1
				endif
				!nonstat=1
			endif
		endif
		if !urootnumber=1 then
			freeze({%temporary}_table) {%temporary}.uroot(adf)
			if @val({%temporary}_table(7,5))>!sigval then
				if !d=1 then
					!percentunit=!percentunit+1
				endif
				!nonstat=1
			endif
			d {%temporary}_table
		endif
		if !nonstat=1 then
			if !logged=1 then
				genr {%temporary}1=d({%temporary})
				d {%temporary}
				rename {%temporary}1 {%temporary}
			else
				for !p=1 to @obs({%temporary})
					if {%temporary}(!p)=0 then
						!nopc=1
					endif
				next
				if !nopc = 1 then 
					genr {%temporary}1=d({%temporary})
					d {%temporary}
					rename {%temporary}1 {%temporary}
				else
					genr {%temporary}1=@pc({%temporary})
					if !d=1 then
						!percentpercent=!percentpercent+1
					endif
					d {%temporary}
					rename {%temporary}1 {%temporary}
				endif
			endif
		endif
		if !standardize=1 then
			genr {%temporary}1 = ({%temporary}-@mean({%temporary}))/@stdev({%temporary})
			d {%temporary}
			rename {%temporary}1 {%temporary}
		endif
	next
	if !groupout=1 then
		{%holdertab}.add {%temporary}
	endif
	!completed=(!a/{%inputgroup}.@count)*100
	statusline !completed % completed
next
delete {%nameofgroup} {%nameofsuffix} {%urootPrompt} {%urootmenu} {%seasonalPrompt} {%seasonalmenu} {%upperboundonrate} testrate
if 	!tableout= 1 then
	{%tableoutput}(1,1) = "A Table of Diagnostics for MacroTrans"
	{%tableoutput}(3,1) = "Total Number of Series"
	{%tableoutput}(4,1) = !numberseries
	{%tableoutput}(3,2) = "Percent seasonally adjusted"
	if !seasonalnumber>0 then
		{%tableoutput}(4,2) = ((!numberseries-!percentseaserrors)/!numberseries)*100
	else
		{%tableoutput}(4,2) = "NA"
	endif
	{%tableoutput}(3,3) = "Percent of series with at least one Unit Roots Found"
	{%tableoutput}(4,3) = (!percentunit/!numberseries)*100
	{%tableoutput}(3,4) = "Percent series percentages"
	{%tableoutput}(4,4) = (!percentpercent/!numberseries)*100
	{%tableoutput}(3,5) = "Percent series logged"
	{%tableoutput}(4,5) = (!percentlogged/!numberseries)*100
	show {%tableoutput}
endif

