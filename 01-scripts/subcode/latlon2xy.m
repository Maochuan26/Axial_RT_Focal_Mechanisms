function [x,y] = latlon2xy(dlat,dlon,lat0lon0rot)
% Calculates lat & long from cartesian coordinates assuming spherical earth
% Hardwired for Axial Seamount with origin at AXCC1 unless 3rd argument 
% provided with reference lat, lon and rotation 
% rotation is defined as anticlockwise degrees to get from lat/lon to x/y
%
% Usage 
%   [x,y] = latlon2xy(dlat,dlon,lat0lon0rot)

if nargin<3
  dlato = 45.9547;
  dlono = -130.0089;
  rota = -20;
else
  dlato = lat0lon0rot(1);
  dlono = lat0lon0rot(2);
  rota = -lat0lon0rot(3);
end
xltkm = 111.19;
xlnkm = xltkm*cosd(dlato);

%Remove origin and scale to kilometers
dlat = (dlat-dlato) * xltkm;
dlon = (dlon-dlono) * xlnkm;

% Rotate
snr=sind(rota);
csr=cosd(rota);
y=csr*dlat+snr*dlon;
x=csr*dlon-snr*dlat;