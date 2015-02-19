
%1:wormIndex, 2:frameNumber, 3:x, 4:y,
%5:Area, 6:Perimeter,
%7:majorAxis, 8:minorAxis, 
%9:solidity, 10:eccentricity, 11:compactness, 12:orientation, 13:speed, 14:behaviour
        
load('results_partial.mat', 'allProps_partial')

X = sparse(allProps_partial(2,:), allProps_partial(1,:), allProps_partial(3,:));
Y = sparse(allProps_partial(2,:), allProps_partial(1,:), allProps_partial(4,:));
V = sparse(allProps_partial(2,:), allProps_partial(1,:), allProps_partial(13,:));
A = sparse(allProps_partial(2,:), allProps_partial(1,:), allProps_partial(5,:));
C = sparse(allProps_partial(2,:), allProps_partial(1,:), allProps_partial(11,:));
N = sum(spones(X),1);

%%
valid = find(N>900);
ii = 1108 %351;
figure,
subplot(2,2,1), hold on
plot(nonzeros(X(:,valid(ii))),nonzeros(Y(:,valid(ii))))
axis equal
subplot(2,2,2), hold on
plot(nonzeros(V(:,valid(ii))))
subplot(2,2,3), hold on
plot(nonzeros(A(:,valid(ii))))
subplot(2,2,4), hold on
plot(nonzeros(C(:,valid(ii))))


%%

medianVelocity = nan(1,size(V,1));
medianArea = nan(1,size(V,1));
for tt = 1:numel(medianVelocity)
    dd = nonzeros(V(tt,valid));
    if numel(dd>5)
        medianVelocity(tt) = median(nonzeros(V(tt,valid)));
        medianArea(tt) = median(nonzeros(A(tt,valid)));
    end
end
%%
tt = (1:size(V,1))/3600;
iniT = 1.5e4;

windowSize = 1000;
b = (1/windowSize)*ones(1,windowSize);
a = 1;

figure, hold on
plot(tt(iniT:end),medianVelocity(iniT:end));
plot(tt(iniT:end),filter(b,a,medianVelocity(iniT:end)), 'r');

figure, hold on
plot(tt(iniT:end),medianArea(iniT:end));
plot(tt(iniT:end),filter(b,a,medianArea(iniT:end)), 'r');
%%
iniT = 1e4;

figure, hold on
subplot(2,1,1), hold on
yy = filter(b,a,medianVelocity);
plot(tt(iniT:end), yy(iniT:end), 'b');
set(gca,'yscale', 'log')
subplot(2,1,2), hold on
yy = filter(b,a,medianArea);
plot(tt(iniT:end), yy(iniT:end), 'r');
set(gca,'yscale', 'log')


%}
%plot(X(:,N>900), Y(:,N>900),'.')

