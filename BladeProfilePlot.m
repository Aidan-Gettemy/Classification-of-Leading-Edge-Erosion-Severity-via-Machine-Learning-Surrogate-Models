clc, close, clear;

% Specify to color by severity level
erosion_profile = [.01,.02,.1,.2,.5,1];

% switch 
s = 0; % if 0, use set color, if 1, use severity level
ls = 1; % if 0, do not see legend

f = figure;
f.Position = [50 50 1250 650];
plot_blade(erosion_profile,s,ls)
g = gca;g.FontSize = 14;g.FontName = 'Helvetica';
saveID = "Plots/"+"BladeRegionPlot.pdf";
ax = gcf;
exportgraphics(ax,saveID,'Resolution',300)
%%
x = linspace(0,1,30);
[X,Y] = meshgrid(x,x);
scatter(X,Y,'filled')



% ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *****

function status = plot_blade(erosion_profile,s,ls)

% List the location of the aerodynamic nodes
nodeLocs = (1/61.5)*[0, 2.8667, 5.6, 8.333, 11.75, ...
    15.85, 19.95, 24.05, 28.15, 32.25, 36.35, ...
    40.45, 44.55, 48.65, 52.75, 56.1667, 58.9, 61.633];
% List the chord lengths
nodeHeights = [3.542, 3.542,3.854,4.167,4.557,4.652,4.458,4.249,4.007,...
    3.748,3.502,3.256,3.010,...
    2.764,2.518,2.313,2.086,1.419];

% Plot the location of the nodes
hold on
for i = 1:numel(nodeLocs)
    plot([nodeLocs(i),nodeLocs(i)],[-.25*nodeHeights(i),.75*nodeHeights(i)],...
        'Color','k','LineWidth',3)
end

% Add text
if s == 0
    a = 17;
    x1 = xregion(nodeLocs(2),nodeLocs(4),FaceColor=[.7 .7 .7],EdgeColor='k');
    x1.FaceAlpha = .1;
    xtxt1 = text(nodeLocs(2)+.05,nodeHeights(2)*.9,'Cyl. 1','FontName','Ariel');
    set(xtxt1,'Rotation',90)
    set(xtxt1,'FontSize',a)
    x2 = xregion(nodeLocs(4),nodeLocs(5),FaceColor=[.8 .8 .8],EdgeColor='k');
    x2.FaceAlpha = .1;
    xtxt2 = text(nodeLocs(4)+.025,nodeHeights(4)*.9,'Cyl. 2','FontName','Ariel');
    set(xtxt2,'Rotation',90)
    set(xtxt2,'FontSize',a)
    
    x3 = xregion(nodeLocs(5),nodeLocs(6),FaceColor='r',EdgeColor='k');
    x3.FaceAlpha = .1;
    xtxt3 = text(nodeLocs(5)+.025,nodeHeights(5)*.9,'DU40','FontName','Ariel');
    set(xtxt3,'Rotation',90)
    set(xtxt3,'FontSize',a)

    x4 = xregion(nodeLocs(6),nodeLocs(8),FaceColor='g',EdgeColor='k');
    x4.FaceAlpha = .1;
    xtxt4 = text(nodeLocs(6)+.05,nodeHeights(6)*.9,'DU35','FontName','Ariel');
    set(xtxt4,'Rotation',90)
    set(xtxt4,'FontSize',a)

    x5 = xregion(nodeLocs(8),nodeLocs(9),FaceColor='b',EdgeColor='k');
    x5.FaceAlpha = .1;
    xtxt5 = text(nodeLocs(8)+.025,nodeHeights(8)*.9,'DU30','FontName','Ariel');
    set(xtxt5,'Rotation',90)
    set(xtxt5,'FontSize',a)

    x6 = xregion(nodeLocs(9),nodeLocs(11),FaceColor='cyan',EdgeColor='k');
    x6.FaceAlpha = .1;
    xtxt6 = text(nodeLocs(9)+.05,nodeHeights(9)*.9,'DU25','FontName','Ariel');
    set(xtxt6,'Rotation',90)
    set(xtxt6,'FontSize',a)

    x7 = xregion(nodeLocs(11),nodeLocs(13),FaceColor='magenta',EdgeColor='k');
    x7.FaceAlpha = .1;
    xtxt7 = text(nodeLocs(11)+.05,nodeHeights(11)*.9,'DU21','FontName','Ariel');
    set(xtxt7,'Rotation',90)
    set(xtxt7,'FontSize',a)

    x8 = xregion(nodeLocs(13),nodeLocs(18),FaceColor='y',EdgeColor='k');
    x8.FaceAlpha = .1;
    xtxt8 = text(nodeLocs(13)+.05,nodeHeights(13)*.9,'NACA 64','FontName','Ariel');
    set(xtxt8,'Rotation',90)
    set(xtxt8,'FontSize',a)
end

% Construct the aerodynamic nodes for each region 

% For showing the regions
setcol = ['r','g','b','c','m','y'];
setshape = ["h","o","diamond","^","pentagram","square"];

% Fill in the first region 
cmp = colormap("parula");
% Region start and stop 
rstart = [5,7,9,11,13,15];
rend   = [6,8,10,12,14,17];
for j = 1:6
    for i = rstart(j):rend(j)
        reg = [nodeLocs(1,i:i+1)';flip(nodeLocs(1,i:i+1)',1)];
        inBetween = [.75*nodeHeights(1,i:i+1)';flip(-.25*nodeHeights(1,i:i+1)',1)];
        
        [dotsX,dotsY] = meshgrid(min(reg):.025:max(reg),min(inBetween):.25:max(inBetween));
        [in,on] = inpolygon(dotsX,dotsY,reg,inBetween);
        inX = dotsX(in|on);
        inY = dotsY(in|on);
        hold on
        
        if s == 0
            c = setcol(j);
        else
            c = cmp(round(erosion_profile(j)*256), :);
            colorbar
        end
        
        fill(reg,inBetween,c,'FaceAlpha',0.5)
        shp = setshape(j);
        scatter(inX,inY,30,'MarkerFaceColor',c,"Marker",shp,"MarkerEdgeColor",'k','LineWidth',1);
    end
end

% Add the sensor locations
%sens = [6,8,10,12,14,17];
sens = 17;
scatter(nodeLocs(sens),-.125*nodeHeights(sens),300,...
    'red','filled','square','MarkerEdgeColor','k','LineWidth',1.5)

% Plot the cylinder airfoils in grey
for i = 1:4
        reg = [nodeLocs(1,i:i+1)';flip(nodeLocs(1,i:i+1)',1)];
        inBetween = [.75*nodeHeights(1,i:i+1)';flip(-.25*nodeHeights(1,i:i+1)',1)];
        
    
        fill(reg,inBetween,[.7 .7 .7],'FaceAlpha',.5)
end
xlim([0,1.02])
ylim([-2 4+ls*4])
ax = gca;
ax.FontSize = 10;
ax.FontWeight = 'bold';
if ls == 1
    if s == 0
        lgd = legend('','','','','','','','','','','','','','','','','',...
            '',...
            '','','','','','','','',...
            '','Region 1','','','','Region 2','',...
            '','','Region 3','','','','Region 4','','','','Region 5','','','','Region 6','','','','',...
            'Aerodynamic Sensor','','','','');
    else
        lgd = legend('','','','','','','','','','','','','','','','','',...
            '',...
            '','Region 1','','','','Region 2','',...
            '','','Region 3','','','','Region 4','','','','Region 5','','','','Region 6','','','','',...
            'Aerodynamic Sensor','','','','');
    end
    lgd.FontSize = 14;lgd.FontName = 'Helvetica';
    lgd.NumColumns = 1;lgd.FontWeight = "normal";
    lgd.Location = "northeast";
    lgd.NumColumns = 2;
    
end
xlabel('r/R [percentage of total length]','FontSize',14,'FontWeight','normal','FontName','Helvetica')
ylabel('Blade Chord [m]','FontSize',14,'FontWeight','normal','FontName','Helvetica')
g = gca();
g.FontSize = 14;
%g.FontName = 'Ariel';
%title('Blade Erosion Regions','FontSize',20,'FontWeight','bold')

status = "Plotting complete";
end