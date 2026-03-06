function [fnorm,slip] = fp2fnorm(strike,dip,rake);

% function [fnorm,slip] = fp2fnorm(strike,dip,rake);
% subroutine FP2FNORM gets fault normal vector,fnorm, and slip 
% vector, slip, from (strike,dip,rake).
% Reference:  Aki and Richards, p. 115
% Uses (x,y,z) coordinate system with x=NORTH, y=EAST, z=DOWN
% This is converted to the COORDINATE SYSTEM required for matlab
% plotting routines where x=E, y=N, z=Up.

degrad=180./3.1415927;

phi = strike/degrad;
del = dip/degrad;
lam = rake/degrad;

% Uses (x,y,z) coordinate system with x=north, y=east, z=down
fnorm(:,1) = -sin(del).*sin(phi);
fnorm(:,2) =  sin(del).*cos(phi);
fnorm(:,3) = -cos(del);
slip(:,1)  =  cos(lam).*cos(phi)+cos(del).*sin(lam).*sin(phi);
slip(:,2)  =  cos(lam).*sin(phi)-cos(del).*sin(lam).*cos(phi);
slip(:,3)  = -sin(lam).*sin(del);

%if  [ (dip > 90) & (rake > 90) ] | [ (dip > 90) & (rake < 90) ],
%    slip = -slip
%end

% This is converted to the COORDINATE SYSTEM required for matlab
% plotting routines where x=E, y=N, z=Up.
fnorm = ned2enu(fnorm);
slip  = ned2enu(slip);
