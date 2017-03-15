'''''''''''''''''''''''''''''''''''''''''''''''''
'''''A Quick Attempt at an LU Decomposition'''''' 	Version 1.0 - Last Revised 17 May 2015
'''''''''''''''''''''''''''''''''''''''''''''''''

!n=@rows(A)
matrix L = @identity(!n)
matrix P=  @identity(!n)
matrix U=A
for !k=1 to !n-1
	vector temp = @subextract(U,!k,!k,!n,!k)
	!pivot=@max(@abs(temp))
	for !j = 1 to @rows(temp)
		if @abs(temp(!j))=!pivot then
			!ind=!j+!k-1
		'	!j=!n+1
		endif
	next
	d temp
	vector temp_k = @subextract(U,!k,!k,!k,!n)
	vector temp_ind = @subextract(U,!ind,!k,!ind,!n)
	matplace(U,temp_k,!ind,!k)
	matplace(U,temp_ind,!k,!k)
	d temp_k temp_ind
	vector temp_k = @subextract(L,!k,1,!k,!k-1)
	vector temp_ind = @subextract(L,!ind,1,!ind,!k-1)
	matplace(L, temp_k,!ind,1)
	matplace(L, temp_ind,!k,1)
	d temp_k temp_ind
	vector temp_k = @rowextract(P,!k)
	vector temp_ind = @rowextract(P,!ind)
	matplace(P,temp_k,!ind,1)
	matplace(P,temp_ind,!k,1)
	d temp_k temp_ind
	for !j= !k+1 to !n
		L(!j,!k)=U(!j,!k)/U(!k,!k)
		matplace(U,@subextract(U,!j,!k,!j,!n)-L(!j,!k)*@subextract(U,!k,!k,!k,!n),!j,!k)
	next
next
