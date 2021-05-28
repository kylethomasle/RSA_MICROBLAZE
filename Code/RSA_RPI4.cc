#include<iostream>
#include<math.h>
#include <algorithm>
#include <chrono>
#include <vector>
using namespace std;
using namespace std::chrono;
// find gcd
int gcd(int a, int b) {
   int t;
   while(1) {
      t= a%b;
      if(t==0)
      return b;
      a = b;
      b= t;
   }
}
int main() {
	int time = 0;	
	for(int z=1; z<=1000; z++){
   //2 random prime numbers
   double p = 13;
   double q = 11;
   double n=p*q;//calculate n
   double track;
   double phi= (p-1)*(q-1);//calculate phi
   //public key
   //e stands for encrypt
   double e=7;
   // Get starting timepoint
   auto start = high_resolution_clock::now();
   //for checking that 1 < e < phi(n) and gcd(e, phi(n)) = 1; i.e., e and phi(n$
   while(e<phi) {
      track = gcd(e,phi);
      if(track==1)
         break;
      else
         e++;
   }
   //private key
   //d stands for decrypt
   //choosing d such that it satisfies d*e = 1 mod phi
   double d1=1/e;
   double d=fmod(d1,phi);
   double message = 9;
   double c = pow(message,e); //encrypt the message
   double m = pow(c,d);
   c=fmod(c,n);
   m=fmod(m,n);
   // Get ending timepoint
   auto stop = high_resolution_clock::now();
   // Get duration. Substart timepoints to
   // get durarion. To cast it to proper unit
   // use duration cast method
   auto duration = duration_cast<nanoseconds>(stop - start);
   //UNCOMMENT BELOW TO PRINT EACH RUN TIME
   //cout << "Time taken by function"<< z << ": "
        //<< duration.count() << " nanoseconds" << endl;
		if(z>1){
			time = time+duration.count();
		}
	}
	   cout << "Time taken by averaging 1000 runs: "
        << (time/1000) << " nanoseconds" << endl;
   //cout<<"Original Message = "<<message;
   //cout<<"\n"<<"p = "<<p;
   //cout<<"\n"<<"q = "<<q;
   //cout<<"\n"<<"n = pq = "<<n;
   //cout<<"\n"<<"phi = "<<phi;
   //cout<<"\n"<<"e = "<<e;
   //cout<<"\n"<<"d = "<<d;
   //cout<<"\n"<<"Encrypted message = "<<c;
   //cout<<"\n"<<"Decrypted message = "<<m;
   return 0;
}
