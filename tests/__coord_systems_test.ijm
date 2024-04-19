x = 18;
y = 18;

// CoordString
print("CoordString");
systems = newArray("ICRS", "J2000", "B1950", "Gal", "E2000", "H2000");
for (i=0; i<systems.length; i++) {
    print(systems[i]);
    ra = call("CONVERT_PIXELS_COORDINATES.fits2CoordXString",x,y, systems[i], "");
    dec = call("CONVERT_PIXELS_COORDINATES.fits2CoordYString",x,y, systems[i], "");
    print("RA = " + ra + ", DEC = ", dec);
    x2 = call("CONVERT_PIXELS_COORDINATES.coordString2FitsX",ra,dec, systems[i]);
    y2 = call("CONVERT_PIXELS_COORDINATES.coordString2FitsY",ra,dec, systems[i]);
    print("x2 = " + x2 + ", y2 = ", y2);
}

// CoordString
print(" ");
print("coords");
systems = newArray("ICRS", "J2000", "B1950", "Gal", "E2000", "H2000");
for (i=0; i<systems.length; i++) {
    print(systems[i]);
    ra = call("CONVERT_PIXELS_COORDINATES.fits2CoordX",x,y, systems[i]);
    dec = call("CONVERT_PIXELS_COORDINATES.fits2CoordY",x,y, systems[i]);
    print("RA = " + ra + ", DEC = ", dec);
    x2 = call("CONVERT_PIXELS_COORDINATES.coord2FitsX",ra,dec, systems[i]);
    y2 = call("CONVERT_PIXELS_COORDINATES.coord2FitsY",ra,dec, systems[i]);
    print("x2 = " + x2 + ", y2 = ", y2);
}

x3 = call("CONVERT_PIXELS_COORDINATES.coord2FitsX",330.26846,-2.5390723, systems[5]);   //redondea a 4 decimales
y3 = call("CONVERT_PIXELS_COORDINATES.coord2FitsY",330.26846,-2.5390723, systems[5]);
print("Manual H2000 with floats x3 = " + x3 + ", y3 = ", y3);
x4 = call("CONVERT_PIXELS_COORDINATES.coord2FitsX","330.26846","-2.5390723", systems[5]);
y4 = call("CONVERT_PIXELS_COORDINATES.coord2FitsY","330.26846","-2.5390723", systems[5]);
print("Manual H2000 with strings x4 = " + x4 + ", y4 = ", y4);

// para Gal, E2000, H2000 usar coord2Fits y fits2Coord, porque los de coordstring dan los grados tambien pero con un decimal menos