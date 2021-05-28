// function prototypes:
int gcd (int, int);
void average(unsigned long);
void conv_nano(double);

// global variables:
const double p = 13.0;
const double q = 11.0;
double result = 0.0;
int count = 0;

// integer function to calculate the GCD:
int gcd(int a, int b) 
{
   int t;
   
   while(1) 
   {
      t= a%b;
      if(t==0)
        return b;
      
      a = b;
      b = t;
   }
}


// double function to calculate the average:
void average(unsigned long time_val)
{
  // we shall run this for 1000 
  if (count < 1000)
    {
      result += time_val;
      count++;
    }

  else
    result /= 1000;     
}

// convert to nanoseconds:
void conv_nano(double val)
{
  result = val * 1000;
}


// setup function:
void setup() 
{
  Serial.begin(9600);                 // set the baud rate (general for COMM port)
}

// main loop for the algorithm:
void loop() 
{
  // clear the values at the beginnging for averaging:
  unsigned long time_base = 0;
  unsigned long time_end = 0;
  unsigned long total_time = 0;

  
  // gather the initial timer data:
  time_base = micros();

  // local variables:
  double n = p * q;                   //calculate n
  double track;
  double phi = (p-1) * (q-1);         //calculate phi
  
  //public key
  //e stands for encrypt
  double e=7;
   
  //for checking that 1 < e < phi(n) and gcd(e, phi(n)) = 1; i.e., e and phi(n)
  while(e < phi) 
  {
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

  time_end = micros();                // gather the ending timer data

  total_time = time_end - time_base;  // total time taken to run the algorithm

  average(total_time);

  // ensure reset of values:
  time_end = 0; time_base = 0;
  total_time = 0;

  if (count >= 1000)
    {
      conv_nano(result);
      Serial.print("Average Execution Time (For 1000 Executions): ");
      Serial.print(result);
      Serial.print(" ns");
      while (1) {};
    }
}