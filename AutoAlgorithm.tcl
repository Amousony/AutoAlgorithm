#-----------------------------------------------------------------------------
#                       This script was improved by Wang Wei
#   The calculation time of Lu Xinzheng model is modified, which is more accurate than before. 
#    In addition, the prompt information of whether the calculation is successful is added.
#               The function of specifying convergence conditions is added
#                       If there are bugs in this tcl script 
#                  Please emil to 2108521318021@stu.bucea.edu.cn 
#                                  Version:1.0
#
#-----------------------------define dynamic analysis------------------------
set TolerranceDynamic 1e-6 ; # recommand value by WangWei,just for reference！
set MaxNumberDynamic 10 ; # You can increase this parameter,in case not convergence
set printType 2 ; # An explanation is given below
set TmaxAnalysis 10 ; # You can assign calculation time,according to your own model
#test NormDispIncr $tol $iter <$pFlag> <$nType>
	#$pFlag
	#optional print flag, default is 0. valid options: 
	#0 print nothing 
	#1 print information on norms each time test() is invoked 
	#2 print information on norms and number of iterations at end of successful test 
	#4 at each step it will print the norms and also the <math>\Delta U</math> and <math>R(U)</math> vectors. 
	#5 if it fails to converge at end of $numIter it will print an error message BUT RETURN A SUCCESSFUL test 
	#$nType
	#optional type of norm, default is 2. (0 = max-norm, 1 = 1-norm, 2 = 2-norm, ...) 
constraints Transformation; 
numberer RCM;  
system SparseSYM ; 
#test EnergyIncr 1.0e-4 200; 
test NormDispIncr $TolerranceDynamic $MaxNumberDynamic $printType
#algorithm Newton 
algorithm ModifiedNewton
#algorithm NewtonLineSearch 0.75
integrator Newmark 0.5 0.25 
analysis Transient

set NInput 2000 ; #please define this parameter,steps of Seismic wave recording
set ndt 1 ; # If not converage,please turn down this parameter!

set DtAnalysis [expr $dtIn/$ndt] 
set Nsteps [expr $NInput*$ndt] 

puts "Trying First calculation "
set ok [analyze $Nsteps $DtAnalysis];
#if Nsteps is successed,ok return 0, other case return negative	

puts "Trying autoChange algorithm"	
if {$ok != 0} {      ;					
	set ok 0;
	set controlTime [getTime];
	while {$controlTime < $TmaxAnalysis && $ok == 0} {
		
		set ok [analyze 1 $DtAnalysis]
		if {$ok != 0} {
                  puts "try krylov and change test"
			test NormDispIncr   $TolerranceDynamic $MaxNumberDynamic $printType
			algorithm  KrylovNewton 
			set ok [analyze 1 $DtAnalysis]
			test NormDispIncr $TolerranceDynamic $MaxNumberDynamic $printType
			algorithm NewtonLineSearch 0.75
		}
		if {$ok != 0} {
                  puts "try relative"
			test RelativeNormDispIncr $TolerranceDynamic $MaxNumberDynamic $printType
			set ok [analyze 1 $DtAnalysis]
			test NormDispIncr 0.001 10 2
		}
		if {$ok != 0} {
                  puts "try relative and krylov"
			test NormDispIncr   $TolerranceDynamic $MaxNumberDynamic $printType
			algorithm  KrylovNewton 
			set ok [analyze 1 $DtAnalysis]
			test NormDispIncr $TolerranceDynamic $MaxNumberDynamic $printType
			algorithm NewtonLineSearch 0.75
		}
		if {$ok != 0} {
			puts "Trying Broyden .."
			algorithm Broyden 8
			set ok [analyze 1 $DtAnalysis]
			algorithm NewtonLineSearch 0.75
		}
		if {$ok != 0} {
			puts "Trying NewtonWithLineSearch .."
			algorithm NewtonLineSearch .8
			set ok [analyze 1 $DtAnalysis]
			algorithm NewtonLineSearch 0.75
		}
		set controlTime [getTime]
	}
};      # end if ok !0
set currentTime [getTime];
if {$ok != 0} {
	puts "Transient analysis compeleted FAILED.End Time: $currentTime "
} else {
	puts "Transient analysis completed Successfully.End Time : $currentTime "
}
puts "file name" ; # You can put your own model name there
