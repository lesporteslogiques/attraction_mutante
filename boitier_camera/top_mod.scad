// Boitier PS Eye modifié (partie : top)
// 28 fev 2022 / https://lesporteslogiques.net/wiki/openatelier/projet/attraction_mutante_qiff
// OpenSCAD 2019.05 @ kirin / Debian Stretch 9.5

difference() {
    translate ([0, 0, -18.65]) import("top.stl");
    union() {
        color([1, 0, 0]) translate([28.5, 19, -10]) cylinder( h=20, r=3, center=false, $fn=36);
        color([1, 0, 0]) translate([10.5, 19, -10]) cylinder( h=20, r=3, center=false, $fn=36);
        color([1, 0, 0]) translate([-10.5, 19, -10]) cylinder( h=20, r=3, center=false, $fn=36);
        color([1, 0, 0]) translate([-28.5, 19, -10]) cylinder( h=20, r=3, center=false, $fn=36);
    }
}

difference() {
    color([1, 0, 0]) translate([-40.5, 0, -2.66]) cylinder( h=2.66, r=10, center=false, $fn=36);
    color([0, 1, 0]) translate([-45.5, 0, -10]) cylinder( h=20, r=1.5, center=false, $fn=36);
}

difference() {
    color([1, 0, 0]) translate([40.5, 0, -2.66]) cylinder( h=2.66, r=10, center=false, $fn=36);
    color([0, 1, 0]) translate([45.5, 0, -10]) cylinder( h=20, r=1.5, center=false, $fn=36);
}