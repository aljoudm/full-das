function cam = twin3d_camera(name, target)
%   cam = twin3d_camera('overview', elevationDeg)       elevation optional (the angle is chosen from the three trial views; default 40)
% TWIN3D_CAMERA  FIXED camera angles of the 3D digital twin (saved in code so that every figure of the report uses the same view).
%
%   cam = twin3d_camera('overview')                 whole boundary, oblique view from the south-south-west (as in the DAS-map figure)
%   cam = twin3d_camera('zoom', targetXYZ)          close view of one stretch (target in display km: x east, y north, z = elevation x vertical exaggeration)
%   cam.az  compass bearing of the camera seen from the target (200 = camera south-south-west, looking north-north-east); cam.el elevation above the horizon [deg];
%   cam.dist distance camera-target [km]; cam.fov view angle [deg]; cam.target; cam.VE vertical exaggeration (display only).
cam.VE = 2.5;
switch name
    case 'overview', cam.az = 210;   cam.el = 35;   cam.dist = 92;   cam.fov = 22;   cam.target = [];   cam.pan = [3 0];   if nargin > 1 && ~isempty(target), cam.el = target; end      % camera south-south-west (bearing 210), looking north-north-east: north stays roughly up, slight oblique rotation (cinematic)
    case 'zoom',     cam.az = 210;   cam.el = 35;   cam.dist = 13;   cam.fov = 22;   cam.target = target;
    otherwise, error('twin3d_camera:name', 'Unknown camera %s', name);
end
end
