function cam = twin3d_camera(name, target)
% TWIN3D_CAMERA  FIXED camera angles of the 3D digital twin (saved in code so that every figure of the report uses the same view).
%
%   cam = twin3d_camera('overview')                 whole boundary, oblique view from the south-south-west (as in the DAS-map figure)
%   cam = twin3d_camera('zoom', targetXYZ)          close view of one stretch (target in display km: x east, y north, z = elevation x vertical exaggeration)
%   cam.az  compass bearing of the camera seen from the target (200 = camera south-south-west, looking north-north-east); cam.el elevation above the horizon [deg];
%   cam.dist distance camera-target [km]; cam.fov view angle [deg]; cam.target; cam.VE vertical exaggeration (display only).
cam.VE = 2;
switch name
    case 'overview', cam.az = 200;   cam.el = 42;   cam.dist = 96;   cam.fov = 22;   cam.target = [1.5 -1.0 0.8];
    case 'zoom',     cam.az = 200;   cam.el = 33;   cam.dist = 13;   cam.fov = 22;   cam.target = target;
    otherwise, error('twin3d_camera:name', 'Unknown camera %s', name);
end
end
