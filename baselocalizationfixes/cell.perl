$/=">";
while(<>){
	if(/id="(\d+)"/){
		$id=$1;
		($name)=/<([A-Za-z]+)/;
		if($name=~/Cell$/){
			print "$lastid $id\n";
		}
		$lastid=$id;
	}
}