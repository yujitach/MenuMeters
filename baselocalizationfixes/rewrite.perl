open(IN,"en.map");
while(<IN>){
	chomp;
	($view,$cell)=split " ";
	$viewToCell{$view}=$cell;
}
close(IN);
open(IN,"ja.map");
while(<IN>){
	chomp;
	($view,$cell)=split " ";
	$cellToView{$cell}=$view;
}
close(IN);
while(<>){
	if(/"(\d+).title/){
		$cell=$1;
		if(exists $cellToView{$cell}){
			$newcell=$viewToCell{$cellToView{$cell}};
			s/"\d+.title/"$newcell.title/;
		}
	}
	if(/ObjectID = "(\d+)"/){
		$cell=$1;
		if(exists $cellToView{$cell}){
			$newcell=$viewToCell{$cellToView{$cell}};
			s/ObjectID = "\d+"/ObjectID = "$newcell"/;
		}
	}
	print;
}