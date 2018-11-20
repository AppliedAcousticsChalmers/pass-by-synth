import("maths.lib");
import("basics.lib");
// import("filters.lib");
// import("delays.lib");
import("stdfaust.lib");

nSpeakers = 24;
d = 0.154;

freqs = (562.0, 708.0, 891.0, 1122.0, 1413.0, 1778.0, 2239.0, 2818.0, 3548.0);
freqs3Ob(k) = ba.take(k, (500.0, 630.0, 800.0, 1000.0, 1250.0, 1600.0, 2000.0, 2500.0, 3150.0, 4000.0));

airatt(f,r) = _ : (*(10^(-r*airattdb1m(f)/20.0))) : _
with{
  ht = 40.0;
  // Temperature in Celsius
  tempC = 24.0;
  // Temperature in Kelvin
  tempK = 273.15 + tempC;
  // Reference temperature
  t0 = 293.15;
  t01 = 273.16;

  // Reference ambient pressure
  pa = 101325.0;

  pr = 101325.0;

  c = -6.8346 * (t01 / tempK)^1.261 + 4.6151;

  // Molar conc.of water vapour( %)
  h = ht * pr / pa * 10.0 ^ c;

  // Relaxation freq of oxygen
  fro = (pa / pr) * (24.0 + 4.04 * 10.0 ^ 4.0 * h * (0.02 + h) / (0.391 + h));
  frn = (pa / pr) / sqrt(tempK / t0) * (9.0 + 280.0 * h * exp(-4.17 * ((tempK / t0)^(-1.0 / 3.0) - 1.0)));

  airattdb1m(f) = 8.686 * f^2.0 * (1.84 * 10.0^(-11.0) * (pr / pa) * sqrt(tempK / t0) + (tempK / t0)^(-2.5)*(0.01275 * exp(-2239.1 / tempK) * (fro + f^2.0/fro)^(-1.0) + 0.1068 * exp(-3352.0 / tempK) * (frn + f^2.0/frn)^(-1.0)));
};

y = nentry("y", 1, 1, 1000, 0.1);
x_offset = nentry("x_offset", 0, -1000, 1000, 0.1);
V = nentry("speed", 30, -120, 120, 1);
ampA = nentry("ampa", 1, 0, 1, 0.001);
ampB = nentry("ampb", 1, 0, 1, 0.001);
tmax = nentry("time", 15, 1, 60, 1);

// yref = 0.0;

trig = button("start"):ba.impulsify;
t = ba.countdown(SR * tmax, trig);

v = V*(10/36);
x = (tmax/2)*v + (d * ((nSpeakers - 1)/2)) + x_offset;

D(d,i,x,y) = (x - (i - 1) * d  - (v*t/SR) )^2 + y^2 * (1 - (v/343)^2): sqrt;

r = (x - (nSpeakers/2. - 1./2.) * d  - (v*t/SR) )^2 + y^2 * (1 - (v/343)^2): sqrt;

// xnew(d,i) = ma.fabs(x - (i - 1) * d  - (v*t/SR) );
// cosphi(d,i,y) = xnew(d,i)/((y^2 + xnew(d,i)^2)^0.5);
// directivity(d,i,y) = 10^((4*cosphi(d,i,y)-2.5)/20);


partialAir = _ : fi.filterbank(5,freqs) : par(i,10,((_:airatt(freqs3Ob(i+1), D(d,nSpeakers/2,x,y))))) :> _;

//amplitude
// Amp(d,i,x,y,sig1,sig2) = (t!=0)*(sig1, sig2*directivity(d,i,y) :> _)/(D(d,i,x,y)^1.5);
Amp(d,i,x,y,sig) = (t!=0)*(sig)/(D(d,i,x,y)^1.5);
OutA(d,1,x,y,sig) = Amp(d,1,x,y,sig);
OutA(d,i,x,y,sig) = OutA(d,i-1,x,y,sig), Amp(d,i,x,y,sig);


//delay
// R(d,i,x,y) = (t!=0)*de.fdelay1s( (((v*(x - (i - 1) * d - (v*t/SR))/343) + D(d,i,x,y)) / (343 * (1 - (v/343)^2) )) * SR);
R(d,i,x,y) = (t!=0)*de.fdelayltv(5, 65536, (((v*(x - (i - 1) * d - (v*t/SR))/343) + D(d,i,x,y)) / (343 * (1 - (v/343)^2) )) * SR);
OutR(d,1,x,y) = R(d,1,x,y);
OutR(d,i,x,y) = OutR(d,i-1,x,y), R(d,i,x,y);

// subwoofer
AmpSub(d,i,x,y,sig) = (t!=0)*(sig)/(D(d,i/2,x,y));

//composition
Out(d,n,x,y,sig) = OutA(d,n,x,y,sig) : OutR(d,n,x,y);
OutSub(d,n,x,y,sig) = AmpSub(d,n/2,x,y,sig) : R(d,n/2,x,y);

// inverse output order
Xo(expr) = expr <: par(i,n,ba.selector(n-i-1,n))
with {
n = outputs(expr);
};

process = _ : fi.lowpass(5,343/d/2) : partialAir : fi.filterbank(3, 100) : (Out(d,nSpeakers,x,y), OutSub(d,nSpeakers,x,y));
