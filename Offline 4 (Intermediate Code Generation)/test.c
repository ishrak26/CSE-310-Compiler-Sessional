int i, b[10], j;

int main(){
 
	int k,a[3],ll,m,n,o,p;

  p = !(m<=n);
  println(p);

  p = !m;
  println(p);

  p = !p;
  println(p);
 
	i = 1;
	println(i);
	j = 5 + 8;
	println(j);
	k = i + 2*j;
	println(k);

	m = k%9;
	println(m);
 
	n = m <= ll;
	println(n);
 
	o = i != j;
	println(o);
 
	p = n || o;
	println(p);

  p = !p;
  println(p);
 
	p = n && o;
	println(p);
	
	p++;
	println(p);
 
	k = -p;
	println(k);
 
  a[1] = 3;
  println(a[1]);

  a[4/2] = 4*7 - 2;
  println(a[2]);

  a[0] = a[1] + a[2];
  println(a[0]);
  
  b[0] = b[1] + b[2];
  println(b[0]);

  for (i = 0; i < 10; i++) {
    b[i] = i * 2;
    println(b[i]);
  }

  for (i = 0; i < 3; i++) {
    b[i] = a[i];
    println(b[i]);
  }

	return 0;
}

