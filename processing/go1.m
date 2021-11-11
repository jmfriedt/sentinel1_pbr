fs=30e6;
f = fopen ('1.bin','rb');  
%f = fopen ('2.bin','rb'); 
count=1e5;                                 % check if a signal has been acquired
res=[];
for k=1:100000
  k
  t = fread (f, [2, count], 'int8');
  v = t(1,:) + t(2,:)*i;
  [r, c] = size (v);
  v = reshape (v, c, r);
  solmax(k)=mean(abs(v));
  % if ((k>6175)&&(k<6260)) res=[res;v];end  % only save IW3 data
  % if ((k>5400)&&(k<5600)) res=[res;v];end  % only save IW3 data
  if ((k>5400)&&(k<6260)) res=[res;v];end  % only save IW3 data
end
fclose (f);
% plot([3e6:10:6.5e6]/(fs/10),abs(v(3e6:100:6.5e6)))
plot(solmax)
xlabel('time (s)')
ylabel('|I+jQ|')
