// Boitier PS Eye modifié (partie : bottom)
// 28 fev 2022 / https://lesporteslogiques.net/wiki/openatelier/projet/attraction_mutante_qiff
// OpenSCAD 2019.05 @ kirin / Debian Stretch 9.5

difference() {
    translate([0, 25, 0])import("bottom.stl");
    #color([1, 0, 0]) translate([-6, -16, -1]) cube([12, 15.9, 18]);
    #color([1, 0, 0]) translate([14.5, -12, 5.8]) cube([6.3, 18, 12]);
}