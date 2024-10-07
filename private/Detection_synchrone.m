function [f_sp,sp,H,phi]=Detection_synchrone(sig,t,nstart,nbsp,fs,fosc,phiref,nb)


omega=2*pi*fosc;
sig=sig(nstart:end);

n = fs/fosc;
N = fix( n*fix(length(sig)/n) ); %permet de prendre juste un nombre pile de periodes pour la moyenne
t=(0:(length(sig)-1))./fs;

A=zeros(nb+1,1);
B=zeros(nb+1,1);
H=zeros(nb+1,1);
phi=zeros(nb+1,1);

A(1)=mean(sig(1:N));
B(1)=0;
H(1) = sqrt(A(1)*A(1)+B(1)*B(1));
phi(1) = (atan2(B(1),A(1)));

for ind=2:nb+1

    a1=sig.*cos(2*pi*(ind-1)*fosc.*t);
    b1=sig.*sin(2*pi*(ind-1)*fosc.*t);
    A(ind) = 2*mean(a1(1:N));
    B(ind) = -2*mean(b1(1:N));
   
    H(ind) = sqrt(A(ind)*A(ind)+B(ind)*B(ind));
    phi(ind) = (atan2(B(ind),A(ind)) - phiref(1)*(ind-1));

end

sp = 2.*fft(sig-mean(sig),nbsp)/(nbsp); 
f_sp = (0:nbsp-1)*(fs/nbsp);