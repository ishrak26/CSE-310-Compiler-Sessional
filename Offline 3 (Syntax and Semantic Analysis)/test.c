int x,y,z; 
float ab;

void foo();
int var(int a, int b);

int var(int a, int b){
	a = a + y * 2;
	return a+b;
}

void foo(){
	x=2;
	y=x-5;
}

int main(){
	int c,i,a[2],j ; float d;
	c = 4;
	d = 9.5;
	j = 9;
	
	{
		a[0]=1;
		a[1]=var(c,j);
	}
	i= a[0]+a[1];
	
	
	
	printf(c);
	
	
	
	j= 2*3+(5%3 < 4 && 8) || 2 ;
	d=var(1,2*3)+3.5*2;
	return 0;
}
