// sacas coords de un pixel

x = 18;
y = 18;

ra = call("CONVERT_PIXELS_COORDINATES.fits2CoordXString",x,y, "ICRS");
dec = call("CONVERT_PIXELS_COORDINATES.fits2CoordYString",x,y, "ICRS");

print("RA = " + ra + ", DEC = ", dec);

ra2 = '16:32:23.95118';
dec2 = '-24:28:50.67470';

x2 = call("CONVERT_PIXELS_COORDINATES.coordString2FitsX",ra2,dec2, "ICRS");
y2 = call("CONVERT_PIXELS_COORDINATES.coordString2FitsY",ra2,dec2, "ICRS");

print("x2 = " + x2 + ", y2 = ", y2);

// subo un poquitin DEC y bajo RA (arriba a derecha)

ra3 = '16:32:23.93';
dec3 = '-24:28:50.37';

x3 = call("CONVERT_PIXELS_COORDINATES.coordString2FitsX",ra3,dec3, "ICRS");
y3 = call("CONVERT_PIXELS_COORDINATES.coordString2FitsY",ra3,dec3, "ICRS");

print("x3 = " + x3 + ", y3 = ", y3);
pointX = parseFloat(x)-1;
pointY = 90-(parseFloat(y)-1);
makeSelection("point", newArray(pointX, 18, 18), newArray(pointY, 0, 17));




// //
// x = 1;
// y = 1;

// x2 = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", x));    // This redirects to the one at the bottom
// y2 = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", y));
// print("new")
// print(x2 + ", " + y2);

// x3 = parseFloat(call("TRANSFORM_COORDINATES.getXFITS2ImageJ", x));
// y3 = parseFloat(call("TRANSFORM_COORDINATES.getYFITS2ImageJ", y));

// print(x3 + ", " + y3);