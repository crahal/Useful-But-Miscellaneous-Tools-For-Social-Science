''This is a file to replicate the first half (SEM part) of Dubin (1998) in JoHE

'0	2.8	5.64	3.45	3.43	3.76	1.53	3.14	5.67	4.42
'2.8	0	7.7	6.11	2.06	6.01	4.32	0.55	8.45	2.32
'5.64	7.7	0	5.82	9	7.26	4.61	7.71	4.14	7.82
'3.45	6.11	5.82	0	5.93	1.52	2.33	6.52	3.33	7.86
'3.43	2.06	9	5.93	0	5.31	4.84	2.55	8.84	4.26
'3.76	6.01	7.26	1.52	5.31	0	3.2	6.5	4.76	8.05
'1.53	4.32	4.61	2.33	4.84	3.2	0	4.62	4.14	5.72
'3.14	0.55	7.71	6.52	2.55	6.5	4.62	0	8.72	1.77
'5.67	8.45	4.14	3.33	8.84	4.76	4.14	8.72	0	9.61
'4.42	2.32	7.82	7.86	4.26	8.05	5.72	1.77	9.61	0



%cd = Change your CD here
'Set up the distance matrix
wfcreate(wf=durbinreplication) u 1
matrix(10,10) distance
distance.read {%cd}\durbindistance.txt
!lamda1 = 0.33
!lamda2 = 0.67
for !l = 1 to 2
   for !p = 1 to 3
      matrix(@rows(distance),@columns(distance)) w_{!p}_{!l}
      for !a = 1 to @rows(w_{!p}_{!l})
         for !b = !a to @rows(w_{!p}_{!l})
            if !a<>!b then
               w_{!p}_{!l}(!a,!b)=1/distance(!a,!b)^(!p)
               w_{!p}_{!l}(!b,!a)=w_{!p}_{!l}(!a,!b)
            endif
         next
      next
      for !a = 1 to @rows(w_{!p}_{!l})
         !temp = @csum(@transpose((w_{!p}_{!l})))(!a)
         for !b = 1 to @rows(w_{!p}_{!l})
            if !a<>!b then
               w_{!p}_{!l}(!a,!b)=w_{!p}_{!l}(!a,!b)/!temp
            endif
         next
      next
      matrix V_{!p}_{!l}   = @inverse(@identity(10)-(!lamda{!l}*w_{!p}_{!l}))*@inverse(@identity(10)-(!lamda{!l}*(@transpose(w_{!p}_{!l}))))
      matrix(@rows(V_{!p}_{!l}),@columns(V_{!p}_{!l})) C_{!p}_{!l}
      for !a = 1 to @rows(C_{!p}_{!l})
         for !b = !a to @rows(C_{!p}_{!l})
            C_{!p}_{!l}(!a,!b)=V_{!p}_{!l}(!a,!b)/@sqrt(V_{!p}_{!l}(!a,!a)*V_{!p}_{!l}(!b,!b))
         next
      next
      matrix(((@rows(C_{!p}_{!l})-1)*@rows(C_{!p}_{!l}))/2,2) output_matrix_{!p}_{!l}
      !c = 0
      for !a = 1 to @rows(C_{!p}_{!l})
         for !b = !a to @rows(C_{!p}_{!l})
            if !a<>!b then
               !c = !c+1
               output_matrix_{!p}_{!l}(!c,2)=C_{!p}_{!l}(!a,!b)
               output_matrix_{!p}_{!l}(!c,1)=distance(!a,!b)
            endif
         next
      next
      freeze(output_graph_{!p}_{!l}) output_matrix_{!p}_{!l}.scat
      show output_graph_{!p}_{!l}
   next
next
