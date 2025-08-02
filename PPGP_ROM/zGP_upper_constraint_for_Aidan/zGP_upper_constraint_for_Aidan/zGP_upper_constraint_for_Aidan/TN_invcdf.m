aqsclear all
close all

x=linspace(-12,8,500);
mu=-1;
sig=2.5;

z=(x-mu)/(sqrt(2)*sig);



%%%%%%%%%%%%%% %this chunk is all you need, no while loop
yatzero=1/2*(1+erf(-mu/(sqrt(2)*sig)));
Y=yatzero*rand;
samp=sqrt(2)*sig*erfinv(2*Y-1)+mu 
%%%%%%%%%%%%%%

figure(1)
plot(x,1/2*(1+erf(z)))
hold on
plot(0,yatzero,'*')

%here's a histogram to confirm that this looks reasonable
Y=yatzero*rand(10000,1);

samp=sqrt(2)*sig*erfinv(2*Y-1)+mu;

figure(2)
histogram(samp)





