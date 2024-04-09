//            TM1 TM2 7m
// Fits X max 560,  , 90
// Fits Y max 560,  , 90

// poligono en fits
x = newArray(17.2,19.5,21.5);
y = newArray(18.3,22.5,20.5);
x2 = newArray(round(x.length));
y2 = newArray(round(y.length));

// poligono en imagej
x3 = newArray(x[0]-1,x[1]-1,x[2]-1);                // ImageJ a mano (cantidad - 1)
y3 = newArray(90-(y[0]-1),90-(y[1]-1),90-(y[2]-1));          // ImageJ a mano (ANCHO PIX - (cantidad - 1)).

y_corr = 0;
x_corr = 0;
for (i=0; i<x.length; i++) {
    x2[i] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJX", x[i])) + x_corr;
    y2[i] = parseFloat(call("CONVERT_PIXELS_COORDINATES.fits2ImageJY", y[i])) - y_corr;
}

// makeSelection("polyline", x2, y2);

// // makeSelection("polygon", Xarray, Yarray);
// makeSelection("polygon", x2, y2);               // transformed
makeSelection("polygon", x3, y3);               // a mano

Array.show(x, y, x2, y2, x3, y3);